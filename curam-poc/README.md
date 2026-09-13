# curam POC — prove the risky bits, throw it away

Throwaway Python proof-of-concept for the curam design (see
`../docs/curam.md` + `../docs/curam-slos.md`). The three questions it
answers:

1. Can an LLM do real work through these tools **with a shell**? (fluency)
2. Can we tell **when to ask the human**, calibrated so asks are rare and
   outcome-changing?
3. Does the two-stage classifier catch the ugly stuff in practice?

Not production. No sandbox — that's phase 2 on purpose.

## Files

| File | Role |
| --- | --- |
| `ui.py` | CLI: REPL, one-shot task, `--sli`, `--jsonl` |
| `agent.py` | the loop: messages → provider → tools → repeat |
| `tools.py` | read / write / edit / shell (raw, no cage) |
| `policy.py` | stage-1 deterministic gate (allow/ask/deny) |
| `classify.py` | stage-2 tiny LLM judge (via the same provider) |
| `sanitize.py` | PII scrub — secrets never cross the provider boundary |
| `ask.py` | human judgment + approval prompts |
| `journal.py` | SQLite WAL journal — the audit trail |
| `budget.py` | cost accounting from provider `usage` |
| `provider.py` | one OpenAI-compatible client (urllib) |
| `eval_corpus.py` | offline eval — 8 scenarios, PASS/FAIL + SLI tally |
| `skills.py` | skill loading/progressive-disclosure, lint, metrics |
| `curam.toml` | per-project config (TOML, stdlib `tomllib`) |

Each file ends with a `python3 <file>.py` self-check. All stdlib, no deps.

## Run

Requires an OpenAI-compatible endpoint. `curam.toml` mirrors the pi setup
(see `~/.pi/agent/models.json`): local **ollama** (default, free) and cloud
**openrouter** (billed, needs `OPENROUTER_API_KEY`). Swap with one line:

```toml
default_provider = "ollama"        # or: "openrouter"
# [providers.*] — base_url, model, api_key_env, context_window,
#                 reasoning_effort (pi's thinking level)
```

```bash
python3 ui.py                    # interactive coloured REPL
python3 ui.py "add a README to this dir"
python3 ui.py --sli              # journal summary (the SLO SQL surface)
python3 ui.py --jsonl out.jsonl  # export audit trail
python3 eval_corpus.py           # offline eval — 8 scenarios
```

### The coloured REPL (not a full TUI — by design)

The interactive REPL is a plain-text loop: ANSI-colour output (thinking dim,
tool calls cyan, results white, blocked/errors red), a status line pinned to
the terminal bottom (provider, model, reasoning, ctx fill, cost, budget), and
**native terminal scrollback** — the whole conversation stays browsable. A
full TUI (ratatui — the Rust crate) is deferred to the Rust rewrite; the POC
boundary is colour + a pinned status + no duplication, not more.

A bare greeting ("hello", "hi", …) **short-circuits**: the agent replies
without calling the provider or any tool, and the reply is journaled. (The
"hello did a whole task" foot-gun is gone — it's a deterministic guard in
agent.run_task, not a prompt promise.)

### Realtime view & toggles

While a task runs you see, live:

- the model's interim text (thinking), in dim grey
- each tool call (`▶ write {...}`) and its result, with a spinner + elapsed
  seconds while blocked on the model or a running command — so nothing
  looks hung

Toggled at runtime from the REPL:

```text
/verbose   # thinking + commands ON
/quiet     # thinking + commands OFF
```

Defaults come from `[ui] show_thinking / show_commands` in `curam.toml`;
`ui.py --quiet` turns them off for one-shot runs. The spinner is
terminal-only (no-op when piped), so scripted runs stay clean.

## Skills & system prompt

Prompts and skills are always markdown files (see `../docs/curam-skills.md`
for the full design + references):

- `<workdir>/skills/*.md` = a skill (frontmatter `name` + `description`).
  **Only name + description** enter the model's context — the body loads on
demand via the `use_skill` tool (progressive disclosure).
- `<workdir>/evals/*.md` = evals; **never** read into context (operator
  signals only). A skill with no matching eval warns at startup.
- Startup lint (stderr, operator-facing): oversized description/body,
  missing frontmatter, unevaluated skills.
- Skill metrics: `skill_used` journal events (desc chars, body lines, uses)
  visible in `ui.py --sli`.

```bash
mkdir -p work/skills work/evals
cat > work/skills/git-workflow.md <<'EOF'
---
name: git-workflow
description: Always commit + tag after a task.
---
Full git workflow: init branch, Conventional Commits, tag, verify clean.
EOF
```

## The ask doctrine (see docs/curam-slos.md)

Ask the human when a wrong guessed decision is costly or out of scope: design
forks, ambiguity, irreversible changes, intent/cost calls, stuck loops. Do
*not* ask for routine edits. The design neutralizes approval-fatigue by
making the ask about judgment, not permission.

## The web of checks

```bash
for f in journal policy tools budget provider classify sanitize agent ask; do
python3 $f.py
done
python3 eval_corpus.py   # the whole loop, 8 scenarios, offline
```

## PII / secret sanitizer

`[pii]` in curam.toml. Secrets are masked before they reach any LLM (main
model + judge); the journal keeps the RAW result for audit. Tiers:
`off` · `deterministic` (built, default) · `local_llm` (later). The
`scenario_pii_scrub` eval proves the invariant: planted secret in the
journal, scrubbed in the model context.

## Known gaps (deliberate — see docs/curam.md "Deferred")

- **Streaming** — chat is request/response; the spinner masks it, but a
`stream: true` SSE path is the real fix for the "hang" feel. Add when the
loop is proven.
- **No sandbox** — shell runs as the user in `workdir`; bwrap cage is phase 2.
- **Cancellation** — Ctrl-C during a long model call is not cleanly handled.
- **Cloud prices are placeholders** — set real OpenRouter prices or N8 (cost
within ±10%) is unmmeasurable.
- **Classifier is off** — flip `[classifier] enabled = true` once the judge
model is pulled; then measure its catch-rate (N4/N5).
- **Sanitizer tier 2** — `local_llm` entity redaction (falls back to
deterministic) isn't wired yet.
