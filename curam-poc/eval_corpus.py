"""Eval — run the full agent loop over a scenario corpus, offline.

Covers the behavior the POC is proving (see docs/curam-slos.md):
  * happy path (write → read → shell) + journal completeness
  * shell failure → recovery
  * destructive command → policy deny (never executes)
  * approval → granted and executes
  * ask_human → judgment given, agent continues
  * budget cap → halts before exhausting
  * provider down → degrades to journaled error, no crash

Each scenario boots a scripted fake OpenAI server, runs `Agent.run_task`, and
asserts on the journal + real filesystem side effects. Prints PASS/FAIL and an
SLI-style tally. Fully offline — no model, no network.

Run:  python3 eval_corpus.py
"""

import contextlib
import json
import socket
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import agent as agentmod
from agent import Agent
from budget import Budget
from journal import Journal
from provider import Provider

SCRIPT = Path(__file__).parent


def make_handler(script: list, final: str):
    """A fresh handler class per scenario (each carries its own script)."""

    class Handler(BaseHTTPRequestHandler):
        n = 0

        def do_POST(self):
            Handler.n += 1
            n = Handler.n
            usage = {"prompt_tokens": 100 + n, "completion_tokens": 20 + n}
            if n <= len(script):
                name, args = script[n - 1]
                msg = {
                    "role": "assistant",
                    "content": None,
                    "tool_calls": [
                        {
                            "id": f"c{n}",
                            "type": "function",
                            "function": {"name": name, "arguments": json.dumps(args)},
                        }
                    ],
                }
            else:
                msg = {"role": "assistant", "content": final}
            data = json.dumps({"choices": [{"message": msg}], "usage": usage}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def log_message(self, format, *args):  # noqa: A002
            pass

    return Handler


class Server:
    def __init__(self, handler):
        self._http = HTTPServer(("127.0.0.1", 0), handler)
        self.port = self._http.server_address[1]
        self._thread = threading.Thread(target=self._http.serve_forever, daemon=True)

    def __enter__(self):
        self._thread.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._http.shutdown()


def dead_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def base_cfg(port: int | None) -> dict:
    cfg = agentmod.load_config(SCRIPT / "curam.toml")
    cfg["default_provider"] = "fake"
    cfg.setdefault("providers", {})["fake"] = {
        "base_url": f"http://127.0.0.1:{port or dead_port()}/v1",
        "model": "fake-model",
        "context_window": 100000,
    }
    cfg["budget"]["cap_usd"] = 1e9
    cfg["budget"]["price_per_mtok"]["fake-model"] = 2.5
    cfg["classifier"]["enabled"] = False
    return cfg


def run_one(script: list, final: str, *, auto_grant=False, cap=None) -> dict:
    srv = Server(make_handler(script, final))  # binds port in __init__
    cfg = base_cfg(srv.port)
    if cap is not None:
        cfg["budget"]["cap_usd"] = cap
    td = tempfile.TemporaryDirectory()
    with srv:
        ctx = {
            "workdir": Path(td.name),  # kept alive until main() cleans up
            "journal": Journal(Path(td.name) / "j.db"),
            "budget": None,
        }
        budget = Budget(cfg, ctx["journal"])
        ctx["budget"] = budget
        provider = Provider(cfg)
        agent = Agent(
            cfg,
            ctx["journal"],
            provider,
            budget,
            ctx["workdir"],
            interactive=False,
            show_thinking=False,
            show_commands=False,
            auto_grant=auto_grant,
        )
        result = agent.run_task("eval task")
        ctx["result"] = result
        ctx["cfg"] = cfg
        ctx["agent"] = agent
        ctx["_cleanup"] = td.cleanup  # main() runs it after assertions
        return ctx


def counts(ctx: dict) -> dict:
    kinds = {}
    for e in ctx["journal"].events():
        kinds[e["etype"]] = kinds.get(e["etype"], 0) + 1
    return kinds


def ok(name: str, cond: bool, detail: str = "") -> bool:
    tag = "PASS" if cond else "FAIL"
    print(f"  [{tag}] {name}" + (f" — {detail}" if detail and not cond else ""))
    return cond


def scenario_happy():
    print("scenario: happy path (write → read → shell)")
    ctx = run_one(
        [
            ("write", {"path": "hi.txt", "content": "hi"}),
            ("read", {"path": "hi.txt"}),
            ("shell", {"command": "cat hi.txt", "timeout": 5}),
        ],
        "all done",
    )
    k = counts(ctx)
    good = True
    good &= ok("file written", (ctx["workdir"] / "hi.txt").read_text() == "hi")
    good &= ok(
        "journal complete (calls == results)",
        k.get("tool_call", 0) == k.get("tool_result", 0),
    )
    for want in ("user_message", "model_response", "tool_call", "tool_result", "cost"):
        good &= ok(f"event {want} present", k.get(want, 0) > 0)
    good &= ok("final delivered", "done" in (ctx["result"] or ""))
    return good


def scenario_failure_recovery():
    print("scenario: shell failure → recovery")
    ctx = run_one(
        [
            ("shell", {"command": "exit 7", "timeout": 5}),
            ("shell", {"command": "echo recovered", "timeout": 5}),
        ],
        "recovered",
    )
    results = [
        e["payload"]["result"]
        for e in ctx["journal"].events("tool_result")
        if e["payload"]["name"] == "shell"
    ]
    good = True
    good &= ok("first shell exited 7", len(results) > 0 and results[0]["exit"] == 7)
    good &= ok("second shell succeeded", len(results) > 1 and results[1]["exit"] == 0)
    good &= ok(
        "recovered echoed", len(results) > 1 and "recovered" in results[1]["stdout"]
    )
    return good


def scenario_deny():
    print("scenario: destructive rm → policy denies")
    ctx = run_one(
        [
            ("write", {"path": "evil-dir/secret.txt", "content": "x"}),
            ("shell", {"command": "rm -rf evil-dir", "timeout": 5}),
        ],
        "done",
    )
    k = counts(ctx)
    good = True
    good &= ok("rm denied in journal", k.get("tool_denied", 0) >= 1)
    good &= ok(
        "target NOT deleted", (ctx["workdir"] / "evil-dir" / "secret.txt").exists()
    )
    good &= ok(
        "journal still complete", k.get("tool_call", 0) == k.get("tool_result", 0)
    )
    return good


def scenario_approval_granted():
    print("scenario: approval granted → executes")
    ctx = run_one(
        [
            ("write", {"path": "rm-me.txt", "content": "x"}),
            ("shell", {"command": "rm rm-me.txt", "timeout": 5}),
        ],
        "done",
        auto_grant=True,
    )
    k = counts(ctx)
    good = True
    good &= ok(
        "approval requested + granted",
        k.get("approval_requested", 0) >= 1 and k.get("approval_granted", 0) >= 1,
    )
    good &= ok("rm executed", not (ctx["workdir"] / "rm-me.txt").exists())
    return good


def scenario_ask_human():
    print("scenario: ask_human → judgment → continues")
    ctx = run_one(
        [
            ("ask_human", {"question": "which layout?", "options": ["a", "b"]}),
            ("write", {"path": "chosen.txt", "content": "a"}),
        ],
        "done",
        auto_grant=True,
    )
    k = counts(ctx)
    good = True
    good &= ok("ask_human journaled", k.get("ask_human", 0) >= 1)
    good &= ok("human_answer journaled", k.get("human_answer", 0) >= 1)
    answers = [e["payload"]["answer"] for e in ctx["journal"].events("human_answer")]
    good &= ok("judgment returned to model", any(x == "1" for x in answers))
    good &= ok(
        "agent continued after answer",
        (ctx["workdir"] / "chosen.txt").read_text() == "a",
    )
    return good


def scenario_budget_halt():
    print("scenario: budget cap → halts")
    ctx = run_one(
        [
            ("write", {"path": "a.txt", "content": "1"}),
            ("write", {"path": "b.txt", "content": "2"}),
            ("write", {"path": "c.txt", "content": "3"}),
        ],
        "done",
        cap=1e-6,  # tiny: first model response blows the budget
    )
    k = counts(ctx)
    good = True
    good &= ok("budget_hit journaled", k.get("budget_hit", 0) == 1)
    good &= ok("stopped before script exhausted", k.get("tool_call", 0) < 3)
    good &= ok("halting message returned", "Budget exhausted" in (ctx["result"] or ""))
    return good


def scenario_provider_down():
    print("scenario: provider down → degrades, no crash")
    cfg = base_cfg(None)
    cfg["providers"]["fake"]["base_url"] = f"http://127.0.0.1:{dead_port()}/v1"
    with tempfile.TemporaryDirectory() as td:
        j = Journal(Path(td) / "j.db")
        b = Budget(cfg, j)
        a = Agent(
            cfg,
            j,
            Provider(cfg),
            b,
            Path(td),
            interactive=False,
            show_thinking=False,
            show_commands=False,
        )
        result = a.run_task("any task")
        kinds = {e["etype"] for e in j.events()}
    good = True
    good &= ok("returns None (no crash)", result is None)
    good &= ok("error journaled", "error" in kinds)
    good &= ok("user_message journaled", "user_message" in kinds)
    good &= ok(
        "actionable error surfaced",
        bool(a.last_error)
        and "provider unreachable" in a.last_error
        and "base_url" in a.last_error,
    )
    return good


def scenario_pii_scrub():
    print("scenario: secrets scrubbed before they reach the model")
    # eval trigger material, assembled at runtime so secret-scanning static
    # checks (gitleaks) don't mistake it for a real leaked key
    SECRET = "sk-or-eval-secret-" + "abcdefghijklmnop123456"
    EMAIL = "itsover@" + "example.com"
    ctx = run_one(
        [
            ("write", {"path": "conf.txt", "content": f"key={SECRET} owner={EMAIL}"}),
            ("shell", {"command": "cat conf.txt", "timeout": 5}),
        ],
        "done",
    )
    # 1. the raw secret IS in the journal (audit completeness)
    journal_text = json.dumps(ctx["journal"].events())
    good = True
    good &= ok("journal keeps raw secret (audit)", SECRET in journal_text)
    # 2. the model context (what the provider would see) is scrubbed
    model_text = json.dumps(ctx["agent"].messages)
    good &= ok("secret NOT in model context", SECRET not in model_text)
    good &= ok("email NOT in model context", EMAIL not in model_text)
    good &= ok("redaction placeholder present", "{REDACTED}" in model_text)
    return good


SCENARIOS = [
    scenario_happy,
    scenario_failure_recovery,
    scenario_deny,
    scenario_approval_granted,
    scenario_ask_human,
    scenario_budget_halt,
    scenario_provider_down,
    scenario_pii_scrub,
]


def main():
    print(f"curam eval — {len(SCENARIOS)} scenarios, fully offline\n")
    results = []
    cleanups = []
    for fn in SCENARIOS:
        try:
            ctx = fn()
            if isinstance(ctx, dict):
                ok_ = ctx.get("_ok", True)
                detail = ctx.get("_detail", "")
                cleanups.append(ctx.get("_cleanup"))
            else:
                ok_, detail = ctx, ""
            results.append((fn.__name__, ok_, detail))
        except Exception as e:  # noqa: BLE001  (an eval crash is a failure)
            results.append((fn.__name__, False, f"{type(e).__name__}: {e}"))
        print()

    for cleanup in reversed(cleanups):
        if cleanup:
            with contextlib.suppress(OSError):
                cleanup()

    passed = [r for r in results if r[1]]
    print(f"passed {len(passed)}/{len(results)}")
    for name, ok_, detail in results:
        print(
            f"  {'PASS' if ok_ else 'FAIL'}  {name}"
            + (f"  ({detail})" if detail else "")
        )
    return 0 if len(passed) == len(results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
