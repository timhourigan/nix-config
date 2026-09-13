"""Agent loop — messages → provider → tools → repeat.

The heart of curam. Runs a user task to completion (or the iteration cap),
journaling every step. Policy + ask layer gate the tool exec; budget gates
the spend; classifier (classify.py) is the stage-2 watch on tool input.

The event stream IS the product (see docs/curam.md): every user_message,
tool_call, tool_result, ask_human, human_answer, cost is a journal row.

Realtime visibility: with show_thinking/show_commands on (default, and
toggleable via /verbose / /quiet), the model's interim text and each tool
call + result print as they happen, with a \r spinner while blocked on the
provider or a running command — so nothing looks hung.
"""

import json
import re
import sys
import threading
import time
from collections.abc import Callable
from pathlib import Path

import tomllib

import ask
import classify
import policy
import sanitize
import skills as skillsmod
import tools as toolmod
from budget import Budget
from journal import Journal
from provider import Provider, ProviderError

SYSTEM_PROMPT = """You are curam, a coding agent working inside the project
directory. You can read, write, edit files, and run shell commands.

Rules:
1. Prefer doing over asking. Work autonomously toward the task.
2. Use ask_human ONLY for genuinely human judgment: design forks, ambiguous
   or conflicting requirements, irreversible changes, choices about intent or
   cost, or after 3 failed attempts at the same thing. Never ask for routine
   details.
3. Commands run in the workdir. Prefer safe, targeted commands. If a command
   seems destructive (rm, dd, chmod, git push, ...), the harness will prompt
   the human for approval itself — do not be surprised by that.
4. Report progress in short messages between tool calls.
5. Never claim a tool result you did not receive. If a tool errors, read the
   error and retry with a fix.
6. If the user greets you or makes small talk with NO actionable task, reply
   in one or two sentences and do NOT call any tools.
"""

MAX_ITERATIONS = 25
STUCK_THRESHOLD = 3  # consecutive identical tool calls → ask

# tiny deterministic guard (not the model) so a bare "hello" never burns a
# provider round-trip or triggers tools — the POC proves this behaviorally
_GREETING_RE = re.compile(
    r"^(?:hi|hello|hey|yo|howdy|hola|sup|good (?:morning|afternoon|evening)|"
    r"what'?s up|how are (?:you|things))(?:\s+there)?[!?.\s]*$",
    re.IGNORECASE,
)


class _Spinner:
    """Tiny \\r-based progress indicator; no-op unless stdout is a tty."""

    FRAMES = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

    def __init__(self, label: str, enabled: bool):
        self.label = label
        self.enabled = enabled and sys.stdout.isatty()
        self._stop = False
        self._thread: threading.Thread | None = None

    def __enter__(self):
        if self.enabled:
            self._thread = threading.Thread(target=self._run, daemon=True)
            self._thread.start()
        return self

    def _run(self):
        t0 = time.monotonic()
        i = 0
        while not self._stop:
            print(
                f"\r\x1b[33m{self.FRAMES[i % len(self.FRAMES)]}\x1b[0m "
                f"{self.label} {time.monotonic() - t0:5.1f}s",
                end="",
                flush=True,
            )
            i += 1
            time.sleep(0.1)
        print("\r\x1b[2K", end="", flush=True)

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._stop = True
        if self._thread:
            self._thread.join(timeout=0.5)


class Agent:
    def __init__(
        self,
        cfg: dict,
        journal: Journal,
        provider: Provider,
        budget: Budget,
        workdir: Path,
        interactive: bool = True,
        show_thinking: bool = True,
        show_commands: bool = True,
        auto_grant: bool = False,
        ask_hook: Callable[[str, dict], str | bool] | None = None,
        on_event: Callable[[str, dict], None] | None = None,
    ):
        self.cfg = cfg
        self.journal = journal
        self.provider = provider
        self.budget = budget
        self.workdir = workdir
        self.interactive = interactive
        self.show_thinking = bool(show_thinking)
        self.show_commands = bool(show_commands)
        self.auto_grant = bool(auto_grant)  # eval only: auto-answer all asks
        # TUI seams: when set, realtime output and asks are routed to the
        # caller (the single-window terminal UI) instead of stdout/input
        self.ask_hook: Callable[[str, dict], str | bool] | None = ask_hook
        self.on_event: Callable[[str, dict], None] | None = on_event

        # skills: load once, advertise name+desc, load bodies on demand
        self.skills_dir = Path(str(cfg.get("workdir") or ".")) / str(
            (cfg.get("agent") or {}).get("skills_dir") or "skills"
        )
        self.evals_dir = Path(str(cfg.get("workdir") or ".")) / "evals"
        self.skills = skillsmod.load_skills(self.skills_dir)
        self._lint_skills(cfg)
        self.messages: list[dict] = [
            {"role": "system", "content": self._build_system_prompt(cfg)}
        ]
        c = cfg.get("classifier") or {}
        self.clf_on = bool(c.get("enabled")) and bool(c.get("model"))
        self.clf = classify.Classifier(cfg) if self.clf_on else None
        self.sanitizer = sanitize.Sanitizer(cfg)  # scrubs provider-boundary text
        self.last_error: str | None = None  # set when the loop bails (provider, budget)

    # -- skills -----------------------------------------------------------

    def _lint_skills(self, cfg: dict):
        """Startup lint: warn on oversized/unevaluated skills to stderr (not the
        model's context). This is operator-facing, never model-facing."""
        a = cfg.get("agent") or {}
        try:
            max_desc = int(a.get("skills_max_description_chars", 240))
        except (TypeError, ValueError):
            max_desc = 240
        try:
            max_lines = int(a.get("skills_max_body_lines", 200))
        except (TypeError, ValueError):
            max_lines = 200
        res = skillsmod.lint_skills(
            self.skills,
            self.evals_dir,
            max_desc_chars=max_desc,
            max_body_lines=max_lines,
        )
        import sys as _sys

        for w in res.warnings:
            print(f"[curam] skill warning: {w}", file=_sys.stderr)
        for e in res.errors:
            print(f"[curam] skill error: {e}", file=_sys.stderr)
        self.skill_warnings = res.warnings
        self.skill_errors = res.errors

    def use_skill(self, name: str) -> dict:
        """Load a skill's full body into context (and track usage)."""
        sk = skillsmod.find_skill(self.skills, name)
        if sk is None:
            return {"ok": False, "error": f"unknown skill: {name}"}
        sk.record_use()
        self.journal.log(
            "skill_used",
            {
                "name": sk.name,
                "desc_chars": sk.description_chars,
                "body_lines": sk.body_lines,
                "uses": sk.uses,
            },
        )
        # inject the full body as a user-role instruction so it's in context
        self.messages.append(
            {"role": "user", "content": f"[skill:{sk.name}]\n{sk.body}"}
        )
        return {"ok": True, "name": sk.name, "body": sk.body}

    # -- system prompt + skills -------------------------------------------

    def _build_system_prompt(self, cfg: dict) -> str:
        """Effective system prompt: [agent] system_prompt override if set,
        else the built-in default. Then ONLY the skills CATALOG (name + desc)
        is appended — progressive disclosure. Full skill bodies load on demand
        via use_skill, never here."""
        agent_cfg = cfg.get("agent") or {}
        override = (agent_cfg.get("system_prompt") or "").strip()
        base = override if override else SYSTEM_PROMPT
        return base + skillsmod.catalog_block(self.skills)

    # -- output + ask seams ----------------------------------------------

    def _emit(self, kind: str, payload: dict):
        """Route realtime output. With `on_event` set (the TUI), the callback
        owns rendering. Otherwise fall back to the plain-stdout style used by
        the one-shot / scripted paths."""
        if self.on_event is not None:
            self.on_event(kind, payload)
            return
        text = payload.get("text") or payload.get("line") or ""
        if kind == "thinking" and self.show_thinking:
            print(f"\n\x1b[90m{text}\x1b[0m", flush=True)
        elif kind == "tool" and self.show_commands:
            print(f"\n\x1b[36m{text}\x1b[0m", flush=True)
        elif kind == "result" and self.show_commands:
            print(f"\n\x1b[37m{text}\x1b[0m", flush=True)
        elif kind == "blocked" and self.show_commands or kind == "error":
            print(f"\n\x1b[31m{text}\x1b[0m", flush=True)

    def _ask(self, kind: str, **kw) -> str | bool:
        """Human-in-the-loop seam. With `ask_hook` set (the TUI), the callback
        owns the prompt. Otherwise fall back to ask.py's interactive path."""
        if self.ask_hook is not None:
            return self.ask_hook(kind, kw)
        if kind == "judgment":
            return ask.ask_judgment(
                self.journal, kw["question"], kw.get("options"), answer=kw.get("answer")
            )
        if kind == "approval":
            return ask.ask_approval(
                self.journal, kw["command"], kw["reason"], grant=kw.get("grant")
            )
        return ask.ask_stuck(self.journal, kw["attempts"], answer=kw.get("answer"))

    # -- the loop ---------------------------------------------------------

    def run_task(self, task: str) -> str | None:
        self.journal.log("user_message", {"text": task})
        self.messages.append({"role": "user", "content": task})
        # bare greeting → answer immediately, no provider round-trip, no tools
        if _GREETING_RE.match(task.strip()):
            reply = (
                "Hey! I'm curam, your coding agent in this project. "
                'Give me a task (e.g. "add a README to this dir") and I\'ll get on it.'
            )
            self.messages.append({"role": "assistant", "content": reply})
            self.journal.log("model_message", {"text": reply})
            return reply
        last_tool: tuple[str, dict] | None = None
        identical_streak = 0

        for _ in range(MAX_ITERATIONS):
            if self.budget.over_budget:
                msg = f"Budget exhausted (${self.budget.spent_usd:.4f} / ${self.budget.cap_usd}). Halting."
                self.journal.log("budget_hit", {"msg": msg})
                return msg
            with _Spinner(f"thinking ({self.provider.model})", self.show_thinking):
                try:
                    resp = self.provider.chat(self.messages, toolmod.TOOL_SCHEMAS)
                except ProviderError as e:
                    self.journal.log("error", {"error": str(e)})
                    self.messages.append(
                        {"role": "user", "content": f"[system: provider error — {e}]"}
                    )
                    msg = (
                        f"❌ provider unreachable: {e}\n"
                        f"   base_url: {self.provider.base_url}\n"
                        f"   start your LLM (e.g. `ollama serve`) or check curam.toml "
                        f"default_provider, then retry."
                    )
                    self.last_error = msg
                    if self.show_thinking:
                        print(f"\n\x1b[31m{msg}\x1b[0m", flush=True)
                    return None

            usage = resp.get("usage") or {}
            cost = self.budget.charge(self.provider.model, usage)
            self.journal.log(
                "model_response", {"model": self.provider.model, "cost": cost}
            )

            content = resp.get("content")
            tool_calls = resp.get("tool_calls")
            if not tool_calls:
                # final answer — the UI prints it; do NOT echo here or the
                # user sees it twice (once grey, once in the prompt result)
                final = content or ""
                self.messages.append({"role": "assistant", "content": final})
                self.journal.log("model_message", {"text": final})
                return final

            # interim thinking only — there are tool calls after it, so it's
            # a glimpse while working, not the answer
            if content and self.show_thinking:
                print(f"\n\x1b[90m{content.strip()}\x1b[0m", flush=True)

            # tool round
            for tc in tool_calls:
                fn = tc.get("function") or {}
                name: str = str(fn.get("name") or "")
                raw_args = fn.get("arguments") or "{}"
                args: dict = {}
                if isinstance(raw_args, str):
                    try:
                        parsed_args = json.loads(raw_args)
                        args = parsed_args if isinstance(parsed_args, dict) else {}
                    except json.JSONDecodeError:
                        args = {}
                elif isinstance(raw_args, dict):
                    args = raw_args

                if self.show_commands:
                    print(
                        f"\n\x1b[36m▶ {name} {json.dumps(args, ensure_ascii=False)[:120]}\x1b[0m",
                        flush=True,
                    )
                self.journal.log("tool_call", {"name": name, "args": args})

                # stage-2 classifier watch on tool input (scrubbed first so
                # secrets never reach the judge model)
                if self.clf and name == "shell":
                    cmd = self.sanitizer.scrub(args.get("command", ""))
                    verdict = self.clf.judge_command(cmd)
                    if verdict["verdict"] != "benign":
                        self.journal.log(
                            "classifier_flag", {"verdict": verdict, "tool": name}
                        )

                if name == "shell" and self.show_commands:
                    with _Spinner("running", True):
                        result = self._execute_tool(name, args)
                else:
                    result = self._execute_tool(name, args)
                self.journal.log("tool_result", {"name": name, "result": result})

                if self.show_commands:
                    if result.get("denied"):
                        print(
                            f"\x1b[31m⛔ blocked: {result.get('reason', 'denied')}\x1b[0m",
                            flush=True,
                        )
                    else:
                        print(
                            f"\x1b[37m{json.dumps(result, ensure_ascii=False)[:200]}\x1b[0m",
                            flush=True,
                        )

                # stuck detection — N consecutive identical calls → ask human
                if last_tool == (name, args):
                    identical_streak += 1
                else:
                    identical_streak = 1
                last_tool = (name, args)
                if identical_streak >= STUCK_THRESHOLD and self.interactive:
                    nudge = ask.ask_stuck(
                        self.journal,
                        [{"name": name, "args": args}] * identical_streak,
                        answer="1" if self.auto_grant else None,
                    )
                    result["_nudge"] = nudge

                self.messages.append(
                    {
                        "role": "tool",
                        "tool_call_id": tc.get("id", "call_0"),
                        # journal keeps the raw result; the model context is
                        # scrubbed so secrets never enter it
                        "content": self.sanitizer.scrub(
                            json.dumps(result, ensure_ascii=False)[:4000]
                        ),
                    }
                )
            self.messages.append(
                {
                    "role": "assistant",
                    "content": resp.get("content") or "[continued tool use]",
                }
            )

        msg = f"Stopped after {MAX_ITERATIONS} iterations (cap)."
        self.journal.log("error", {"msg": msg})
        return msg

    # -- tool execution with policy + ask gate ----------------------------

    def _execute_tool(self, name: str, args: dict) -> dict:
        if name == "use_skill":
            return self.use_skill(str(args.get("name") or ""))

        if name == "ask_human":
            answer = None
            if not self.interactive and not self.auto_grant:
                answer = "(non-interactive: no human)"
            elif self.auto_grant:
                answer = "1"
            ans = ask.ask_judgment(
                self.journal,
                args.get("question", "?"),
                args.get("options"),
                answer=answer,
            )
            return {"ok": True, "answer": ans}

        if name == "shell":
            decision = policy.check(args.get("command", ""), self.cfg)
            if decision["action"] == "deny":
                self.journal.log(
                    "tool_denied",
                    {"command": args["command"], "reason": decision["reason"]},
                )
                return {"ok": False, "denied": True, "reason": decision["reason"]}
            if decision["action"] == "ask":
                if not self.interactive and not self.auto_grant:
                    self.journal.log(
                        "tool_denied",
                        {
                            "command": args["command"],
                            "reason": "non-interactive auto-deny",
                        },
                    )
                    return {
                        "ok": False,
                        "denied": True,
                        "reason": f"{decision['reason']} (non-interactive)",
                    }
                granted = ask.ask_approval(
                    self.journal,
                    args["command"],
                    decision["reason"],
                    grant=self.auto_grant or None,
                )
                if not granted:
                    return {"ok": False, "denied": True, "reason": "human denied"}

        return toolmod.run(self.workdir, name, args)


def load_config(path: str | Path = "curam.toml") -> dict:
    p = Path(path)
    try:
        with open(p, "rb") as f:
            cfg = tomllib.load(f)
    except FileNotFoundError:
        raise FileNotFoundError(
            f"config not found: {p} — run from curam-poc/ or pass --config"
        ) from None
    cfg.setdefault("workdir", ".")
    cfg.setdefault("policy", {"rules": {}})
    if "rules" not in cfg["policy"]:
        cfg["policy"]["rules"] = {}
    cfg.setdefault("ui", {})
    if "providers" not in cfg and "provider" not in cfg:
        cfg["provider"] = {}
    return cfg


if __name__ == "__main__":
    # structural smoke test without a live provider: config + wiring shape
    import tempfile

    sample = (
        load_config(Path(__file__).parent / "curam.toml")
        if Path("curam.toml").exists()
        else {
            "default_provider": "ollama",
            "providers": {
                "ollama": {"base_url": "http://localhost:11434/v1", "model": "test"}
            },
            "budget": {"cap_usd": 0},
            "policy": {"rules": {}},
            "classifier": {"enabled": False},
            "ui": {},
        }
    )
    assert "budget" in sample and (
        "providers" in sample or "provider" in sample  # new shape or legacy
    )
    assert len(toolmod.TOOL_SCHEMAS) == 6  # read/write/edit/shell/ask_human/use_skill
    # round-trip config through the parser
    with tempfile.TemporaryDirectory() as td:
        j = Journal(Path(td) / "j.db")
        b = Budget(sample, j)
        a = Agent(sample, j, None, b, Path(td), interactive=False)  # type: ignore[arg-type]
        assert not a.clf_on  # classifier off by default
        assert a.cfg.get("ui") is not None
        denied = a._execute_tool("shell", {"command": "rm -rf /x"})
        assert not denied["ok"] and denied.get("denied")
        ok = a._execute_tool("write", {"path": "x.txt", "content": "1"})
        assert ok["ok"] and (Path(td) / "x.txt").read_text() == "1"
        # non-interactive ask_human answers without prompting (no hang)
        js = a._execute_tool("ask_human", {"question": "q?"})
        assert js.get("ok") and "non-interactive" in js["answer"]
        print("agent wiring self-check OK")
