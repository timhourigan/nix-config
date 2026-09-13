"""curam CLI — coloured REPL + one-shot task + SLO summary.

A plain-text REPL with ANSI colours and a status line pinned to the
terminal's bottom row via cursor addressing. Native terminal scrollback is
preserved (the whole conversation stays browsable), wrapping is the
terminal's own (no mid-token breaks), and the final answer prints exactly
once. A real TUI is deferred to the Rust rewrite (ratatui).

Run:
  python3 ui.py                  # interactive coloured REPL
  python3 ui.py "task text"      # one-shot task (plain text)
  python3 ui.py --sli            # journal summary (the SLO SQL surface)
  python3 ui.py --jsonl out      # export journal to JSONL
"""

import argparse
import os
from pathlib import Path

import agent as agentmod
from agent import Agent
from budget import Budget
from journal import Journal
from provider import Provider

APP_DIR = Path.home() / ".local" / "share" / "curam"

# (kind -> ANSI fg) — matches the agent's own emit fallback
_COLORS = {
    "thinking": "\x1b[90m",
    "tool": "\x1b[36m",
    "result": "\x1b[37m",
    "blocked": "\x1b[31m",
    "error": "\x1b[31m",
    "ask": "\x1b[33m",
}
_RESET = "\x1b[0m"


def _status_text(
    provider: Provider, budget: Budget, ctx_tokens: int, ctx_cap: int
) -> str:
    fill = f"{ctx_tokens / ctx_cap * 100:5.1f}%" if ctx_cap else "? ctx"
    bits = [
        f"curam \x1b[36m{provider.name}\x1b[0m \x1b[36m{provider.model}\x1b[0m ctx={fill}",
        f"cost=\x1b[33m${budget.spent_usd:.4f}\x1b[0m"
        + (f"/${budget.cap_usd}" if budget.cap_usd else ""),
    ]
    if provider.reasoning_effort:
        bits.append(f"reasoning={provider.reasoning_effort}")
    bits.append(f"\x1b[35m{budget.completion_tokens}\x1b[0m out-tok")
    return "  ".join(bits)


def _context_fill(messages: list[dict]) -> int:
    # crude heuristic (chars/4) — the point is *showing* the seam, not
    # perfect accounting; count ALL roles incl. system + tool results
    total = sum(
        len(str(m.get("content") or "")) for m in messages if isinstance(m, dict)
    )
    return total // 4


def _show_flags(cfg: dict, quiet: bool) -> tuple[bool, bool]:
    ui = cfg.get("ui") or {}
    show_t = not quiet and bool(ui.get("show_thinking", True))
    show_c = not quiet and bool(ui.get("show_commands", True))
    return show_t, show_c


def run_repl(
    cfg: dict, journal: Journal, provider: Provider, budget: Budget, workdir: Path
):
    show_t, show_c = _show_flags(cfg, False)
    a = Agent(
        cfg,
        journal,
        provider,
        budget,
        workdir,
        interactive=True,
        show_thinking=show_t,
        show_commands=show_c,
    )
    ctx_cap = provider.context_window or 8_000

    def status_line() -> str:
        return _status_text(provider, budget, _context_fill(a.messages), ctx_cap)

    def print_status():
        # a normal line between turns (scrolls up with history; native
        # scrollback is the point). NO cursor-pinning: the pin trick fights
        # mid-stream scrolling and garbles the input line — that HUD is
        # Rust/TUI-phase.
        print(f"\x1b[2K{status_line()}")

    print(status_line())
    print("type a task, or /exit · /sli · /jsonl <path> · /verbose · /quiet")

    while True:
        try:
            line = input("\x1b[32mcuram>\x1b[0m ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if not line:
            continue
        if line in {"/exit", "/quit", "/q"}:
            break
        if line == "/sli":
            print(sli_summary(journal))
            print_status()
            continue
        if line == "/verbose":
            a.show_thinking = True
            a.show_commands = True
            print("realtime view ON (thinking + commands)")
            print_status()
            continue
        if line == "/quiet":
            a.show_thinking = False
            a.show_commands = False
            print("realtime view OFF")
            print_status()
            continue
        if line.startswith("/jsonl"):
            parts = line.split()
            target = parts[1] if len(parts) > 1 else "session.jsonl"
            journal.export_jsonl(target)
            print(f"journal exported → {target}")
            print_status()
            continue
        # run the task; the agent streams interim output; then print the
        # final answer + the status line as NORMAL lines
        print()
        done = a.run_task(line)
        if done:
            print(done if len(done) <= 400 else done[:400] + "…")
        print_status()


def sli_summary(journal: Journal) -> str:
    """The SLO surface: counts per event type + cost rollup, straight from SQL."""
    evs = journal.events()
    kinds: dict[str, int] = {}
    cost = 0.0
    for e in evs:
        kinds[e["etype"]] = kinds.get(e["etype"], 0) + 1
        if e["etype"] == "cost":
            raw = e["payload"].get("cost_usd") or 0
            try:
                cost += float(raw)
            except (TypeError, ValueError):
                cost += 0.0  # malformed cost row; never crash the summary
    asks = kinds.get("ask_human", 0)
    approvals = kinds.get("approval_requested", 0)
    granted = kinds.get("approval_granted", 0)
    denied = kinds.get("tool_denied", 0)
    calls = kinds.get("tool_call", 0)
    results = kinds.get("tool_result", 0)
    pending = calls - results - denied
    # skill metrics: how many times each skill was actually loaded (journaled
    # as skill_used events) + the description-size we exposed to the model
    skill_uses = kinds.get("skill_used", 0)
    skill_rows = []
    for e in evs:
        if e["etype"] == "skill_used":
            p = e["payload"]
            skill_rows.append(
                f"    {p.get('name')}: x{p.get('uses', 0)} "
                f"(desc {p.get('desc_chars', '?')}ch, body {p.get('body_lines', '?')} lines)"
            )
    lines = [
        f"-- sli ({journal.session_id})",
        f"  events:         {len(evs)}",
        f"  tool_calls:     {calls}   results: {results}   denied: {denied}   pending: {max(pending, 0)}",
        f"  asks:           {asks}   approvals: {approvals} (granted {granted})",
        f"  cost:           ${cost:.4f}",
        f"  skills used:    {skill_uses} total calls",
    ]
    lines += skill_rows
    lines.append(f"  by type:        {kinds}")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="curam POC")
    ap.add_argument("--config", default=str(Path(__file__).parent / "curam.toml"))
    ap.add_argument("--db", default=None)
    ap.add_argument("--sli", action="store_true", help="print journal summary and exit")
    ap.add_argument(
        "--jsonl", metavar="PATH", default=None, help="export journal and exit"
    )
    ap.add_argument(
        "--quiet", action="store_true", help="no realtime thinking/commands"
    )
    ap.add_argument("task", nargs="*", help="one-shot task text (omit for REPL)")
    args = ap.parse_args()

    cfg = agentmod.load_config(args.config)
    db_path = Path(
        os.path.expanduser(args.db or cfg.get("journal") or str(APP_DIR / "curam.db"))
    )
    journal = Journal(db_path)
    workdir = Path(os.path.expanduser(cfg.get("workdir") or ".")).resolve()
    workdir.mkdir(parents=True, exist_ok=True)

    if args.sli:
        print(sli_summary(journal))
        return
    if args.jsonl:
        journal.export_jsonl(args.jsonl)
        print(f"journal exported → {args.jsonl}")
        return

    provider = Provider(cfg)
    budget = Budget(cfg, journal)
    show_t, show_c = _show_flags(cfg, args.quiet)

    if args.task:
        a = Agent(
            cfg,
            journal,
            provider,
            budget,
            workdir,
            interactive=True,
            show_thinking=show_t,
            show_commands=show_c,
        )
        done = a.run_task(" ".join(args.task))
        if done:
            print(done)
        print(sli_summary(journal))
        return

    run_repl(cfg, journal, provider, budget, workdir)
    journal.close()


if __name__ == "__main__":
    main()
