"""Ask layer — the human-in-the-loop judging.

Two kinds of asks:
  * judgment  — design forks, ambiguity, intent, stuck loops. The model asks
                via the `ask_human` tool because the decision needs a human.
  * approval  — policy flagged a command (destructive / system-level / secret
                touching). Hard gate: command cannot run without consent.

In the POC, both are blocking `input()` prompts on the same terminal (the
REPL/UI). In the product, approval could come via the Matrix bridge etc. —
the journal events are the seam, exactly as designed.
"""

import time

from journal import Journal


def _prompt(
    question: str, options: list[str] | None = None, answer: str | None = None
) -> str:
    """Interactively ask. `answer` non-None = non-interactive / auto-granted
    path (eval): returns it without prompting (no hang in scripts)."""
    if answer is not None:
        return answer
    print(f"\n\x1b[33m[curam:ask]\x1b[0m {question}")
    if options:
        for i, opt in enumerate(options, 1):
            print(f"  \x1b[36m{i}\x1b[0m {opt}")
        while True:
            raw = input(f"  choice [1-{len(options)}] or free text: ").strip()
            try:
                n = int(raw)
            except ValueError:
                if raw:  # free text
                    return raw
                return "(no reply)"
            if 1 <= n <= len(options):
                return options[n - 1]
            return raw  # out-of-range digit counts as free text (original behavior)
    return input("  reply: ").strip() or "(no reply)"


def ask_judgment(
    journal: Journal,
    question: str,
    options: list[str] | None = None,
    answer: str | None = None,
) -> str:
    journal.log(
        "ask_human", {"kind": "judgment", "question": question, "options": options}
    )
    answer = _prompt(question, options, answer=answer)
    journal.log(
        "human_answer", {"kind": "judgment", "answer": answer, "ts": time.time()}
    )
    return answer


def ask_approval(
    journal: Journal, command: str, reason: str, grant: bool | None = None
) -> bool:
    """Hard approval gate for policy-flagged commands. Returns True if allowed.
    `grant` non-None = non-interactive / auto-granted path (eval): returns it
    without prompting."""
    journal.log(
        "approval_requested",
        {"command": command, "reason": reason, "ts": time.time()},
    )
    if grant is not None:
        granted = bool(grant)
    else:
        reply = _prompt(
            f"Run command? {reason}\n    $ {command}", ["allow once", "deny"]
        )
        granted = reply == "allow once" or reply == "1"
    journal.log(
        "approval_granted" if granted else "tool_denied",
        {"command": command, "reason": reason},
    )
    return granted


def ask_stuck(journal: Journal, attempts: list[dict], answer: str | None = None) -> str:
    """The model is looping on the same tool call — ask the human for a nudge."""
    journal.log("ask_human", {"kind": "stuck", "attempts": attempts})
    answer = _prompt(
        "I've tried the same thing 3+ times. How should I proceed?",
        [
            "show me the failing output and I'll decide",
            "change approach yourself",
            "stop and summarize",
        ],
        answer=answer,
    )
    journal.log("human_answer", {"kind": "stuck", "answer": answer})
    return answer


if __name__ == "__main__":
    import tempfile
    from pathlib import Path

    # Only journal-writing is exercised (no interactive prompt in self-check)
    with tempfile.TemporaryDirectory() as td:
        j = Journal(Path(td) / "j.db")
        j.log("ask_human", {"kind": "test"})
        assert j.events("ask_human")[0]["payload"]["kind"] == "test"
        print("ask self-check OK")
