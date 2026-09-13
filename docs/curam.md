# curam — Coding Agent Harness (Rust)

Goal: a zero-trust coding harness written in Rust. "curam" = care. Take care
in all things related to this.

## Vision (held, not built)

- Agent loop driven by an **append-only event log** (`session.evlog`, JSONL).
  The log is the interface. Everything else — TUI, telemetry (OTel/Arize),
  Matrix phone bridge, resume, audit trail, background supervisor workers —
  is a *reader* of that stream. Nothing writes back.
- **Default-deny execution.** Agent can provably only run what was explicitly
  allowed.
- **Sandbox for the harness itself**, not just for bash. Per-project profiles
  bound what curam can see.
- **Sovereignty & cost control**: provider layer is one OpenAI-compatible
  client → LiteLLM (local), vLLM, Ollama, cloud APIs all from a config file.
- **BMAD fit**: evals, costing, tracing as events, not bolted-on features.
- pi-extensions compatibility: a later, optional shim — embed `deno_core`,
  reimplement pi's host surface, run ext JS under curam's permissions. Or
  define curam's own extension ABI and skip pi entirely.

## Decision Log

### POC-first — Python, prove the risky bits (decided, supersedes below)

Before any Rust, build a throwaway Python POC that answers the three questions
the whole design stands on:

1. Can an LLM do real work through this toolset **with a shell**? (fluency)
2. Can we tell **when to ask the human**, calibrated so asking is rare and
   valuable (judgment, not permission)?
3. Does a lightweight two-stage classifier catch the ugly stuff in practice?

POC is throwaway by intention — the event/session data model (below) is the
only thing we deliberately shape to survive the rewrite.

### Phase split — shell deferred (original decision, superseded for POC)

**Original:** V1 had no shell, only the typed `run` tool. The POC **reverses
the timing**: shell is IN from day one of the POC with **no security around
it** (raw subprocess, project workdir only). Two reasons: (a) the fluency
question — can the model actually drive git/build/test loops through typed
calls — is the core risk and needs the cheapest possible answer, which is a
free-text shell; (b) the lightweight classifier (see POC) is our interim
watchdog, and we measure how it performs before engineering the real cage
(bwrap). The typed `run`-only exec path remains the *Rust* target; the
decision was about the POC.

**V1: NO shell access. Period.** The only exec path is a typed `run` tool
(model emits `{ program, args[], stdin, cwd, env }`), policy-checked as a
parsed argument array, then `execve`. No free-text shell is executed.

Rationale (from shell research):

- Safety lives at the exec layer, not the shell language. Any shell running
  as the user has full host privileges; a "safe shell" doesn't exist.
- LLMs are *dangerously fluent* in bash — their failure modes (eval, `$(...)`,
  glob/quoting injection, `curl | sh`) are exactly the shapes a policy engine
  must treat as adversarial. Typed `run` erases that whole class: no parser,
  no injection surface, commands arrive as arg arrays the policy can match.
- Niche/modern shells (nushell) have a real model-fluency cliff: models write
  bash-isms that fail or evaluate literally. Defer.
- The guarantee we can actually make: "the harness provably cannot run what
  wasn't allowed — because the only exec path is this one function."

**Later phase (post-proving-out), in priority order:**

1. `bash` as an opt-in, per-project tool, only inside the full cage:
   `bwrap` (net off, read-only root + writable workdir), and/or
   `systemd-run --user --scope` (`PrivateNetwork`, `ProtectSystem`) on Fedora.
   The cage is the process boundary; the shell is incidental.
2. Only if a real need appears: **nushell** as a *structured-output* shell
   (typed results back, fewer tokens) with a dialect preamble in the system
   prompt — not because it's "safer" (it isn't), because it's cheaper to
   consume.
3. WASM sandboxing (`wasmtime`) as an extension tier, sharing the same
   capability model.

### Credential reuse — pi's auth store (decided)

curam reads API keys from **env var first**, then falls back to **pi's own
credential store** (`~/.pi/agent/auth.json`, same file pi reads). This is a
principle: *reuse the machine's existing trust rather than duplicate it* —
pi's keys, git credential helpers, ssh-agent are all precedent. The POC
reads `auth.json` directly (`provider._key_from_pi_auth`); the Rust rewrite
should prefer the OS keychain/secret manager (or `pass`) with the same
fallback order.

Caveat made explicit: any local process can read that file today; the
phase-2 sandbox (per-project workdir + bwrap cage) is what bounds which
curam-spawned processes inherit that trust. Documented, not solved.

### PII / secret sanitization before LLMs (decided)

Secrets must not cross the **provider boundary**: nothing sensitive reaches
any LLM call (main model *or* classifier judge). This is an *optional*
step, tiered from cheapest to heaviest ([pii] in curam.toml):

1. **off** — no scrubbing (local-only models, throwaway dirs).
2. **deterministic** (built, default) — regex masking in-process, stdlib.
   Patterns live in `sanitize.py` (like policy rules): API keys (sk-or,
   sk-, AKIA, ghp_, xox, AIza, JWT), emails, private-key blocks, and
   config-listed internal domains. Fast, exact, testable.
3. **local_llm** (later, optional) — entity redaction via a local judge
   model (same seam as `classify.py`), falling back to deterministic.
4. **other options** — detect-secrets / gitleaks rule sets, Presidio,
   secret managers; not wired, documented for when deterministic isn't
   enough.

The rule that matters: **the journal keeps the RAW result** (audit
completeness — a zero-trust trail can't redact; see SLO/sanitize doc); only
what crosses the provider boundary is scrubbed. So secrets never enter the
model's context and never leave the machine, while the audit stays intact.

### Provider-down UX & general UX principles (decided)

"It looks hung" was the #1 confusable. The POC now treats *never appearing
dead* as a first-class requirement:

- **Spinner + elapsed seconds** on every blocking wait (model call, long
  command) — `⠋ thinking 12.3s`.
- **Thinking + command echo** in realtime (dim grey text / `▶ cmd`), with
  `/verbose` · `/quiet` toggles (REPL) and `--quiet` (scripts).
- **Loud, actionable failures**: provider down prints a red
  `❌ provider unreachable: <err>` + `base_url` + *the fix* ("start your
  LLM, check curam.toml default_provider"); budget-halt and iteration-cap
  are similarly explicit. Nothing fails silently.
- **Live status banner** — provider, model, reasoning level, context
  fill, session cost, budget remaining — refreshed per turn.
- **Gaps**: streaming (`stream: true` SSE) is the real fix for perceived
  latency; Ctrl-C cancellation is not yet clean; a block-debug (what is
  this model doing?) view is future.

**TUI status (decided after one attempt): the full TUI is RUST-phase.** We
built a stdlib-curses single-window UI in the POC and it was worse, not
better: it traded away colour, native terminal scrollback, and the
terminal's own line-wrapping for a pinned status — losing the conversation
and hurting readability of real answers. Reverted to a plain-text coloured
REPL with a status line pinned to the terminal bottom via cursor-addressing
(colour, native scrollback, single answer print) and the `agent.on_event` /
`ask_hook` seams retained (those stay — they are the Rust-TUI boundary). A
proper TUI (ratatui) ships with the Rust rewrite; the POC UI is explicitly
NOT a TUI project.

### System prompts & skills (decided, built)

The POC agent now supports per-project steering — the mechanism we'll use to
attack the edge cases the eval surfaced (greenfield stalls, incomplete git
workflow, trap behavior):

- **System prompt**: `[agent] system_prompt` in curam.toml (replaces built-in)
  OR the built-in default. Skills and evals are md files, never inline strings.
- **Skills**: every `*.md` in `<workdir>/skills/` is a skill with frontmatter
  `name` + `description`. **Only name + description enter the system prompt**
  (progressive disclosure, like the Agent Skills standard); the full body
  loads on demand via the `use_skill` tool.
- **Evals**: `<workdir>/evals/*.md` — never read into context (operator
  signals only). A skill with no matching eval warns at startup.
- **Startup lint**: warns on oversized description (>240ch) / body (>200
  lines), missing frontmatter, no-matching-eval. Operator-facing (stderr),
  never model-facing.
- **Metrics**: `skill_used` journal events (name, desc chars, body lines,
  cumulative uses) surfaced in `--sli`. Usage frequency + size are visible.
- **References** (why): pi's SYSTEM.md/APPEND_SYSTEM.md + Agent Skills
  progressive disclosure; Claude Code's 515-prompt bloat + prompt-cache
  prefix cost. Full provenance in `docs/curam-skills.md`.

### Network firewall — allow/deny hostnames & repos (REQUIRED, deferred to Rust)

The live eval's injection_trap was a genuine repo-as-adversary hit: the model
read an injected instruction, ran `bash setup.sh` from the repo, and
exfiltrated the marker. **The harness's trust boundary must not be the
model's judgment** — it must be enforced network-egress + exec policy.

Required (not optional) for production:

- **Egress firewall on the agent's processes** (bwrap landlock / netns in
  phase 2): a known hostname list — allow/deny — so an agent that follows a
  poisoned repo instruction simply *cannot* reach its C2.
- **The list is open-source and software-dev/supply-chain first-class**: git
  hosts, package registries (pypi, npm, crates.io, maven, Go, rubygems),
  build/CI endpoints, container registries, artifact hosts. Not a general
  web allowlist — it encodes *what a coding agent legitimately needs*.
- **Exec policy ties in**: running an arbitrary script that was just read
  from the repo (bash setup.sh) is ask/deny, never allow.
- The injection failure exploded the "the harness can't rely on the model
  to resist" point — this section records why the fix is structural, not
  prompt-level.

Note: POC measured the failure precisely (that was its job); the fix ships
with the Rust sandbox. Open question: curate upstream vs fork-diff — see
Open Questions.

### Deferred / cut from original notes

- eBPF/aya kernel-level audit: real cost, duplicated job. curam writes the
  evlog (append-only, fsync'd); trust is placed in processes curam spawns.
  Revisit only if the threat model demands kernel evidence.
- "Mathematical guarantees": phrase as "provably default-deny" instead.
- Full TUI and phone bridge in v1: they are event-stream readers; the log is
  the product.

## V1 (Rust) Shape

- Crates: `tokio`, `serde`/`serde_json`, one HTTP client (`reqwest` or
  `ureq`), one CLI args crate (`clap` or `rigel`). That's the whole dep list.
- Provider layer = one trait, one implementation (OpenAI-compatible HTTP).
- Event schema: `user_message`, `model_message`, `tool_call`, `tool_result`,
  `ask_human`, `human_answer`, `approval_requested`, `approval_granted`,
  `tool_denied`, `cost`, `error`.

## POC (Phase 0) — Python, ordered by risk

```
curam-poc/                # throwaway, flat on purpose
  curam.toml              # providers, price map, budget, ask-policy (TOML)
  agent.py                # loop: messages → provider → tools → repeat
  tools.py                # read / write / edit / shell (raw, no cage)
  policy.py               # stage-1: parse args → allow / ask / deny
  classify.py             # stage-2: tiny local LLM judge (via Ollama)
  sanitize.py             # PII scrub: secrets never cross provider boundary
  journal.py              # SQLite WAL journal (audit, cost, queries)
  budget.py               # token/cost/context accounting from usage fields
  ask.py                  # human ask orchestration (judgment + approvals)
  eval_corpus.py          # offline eval: 8 loop scenarios, PASS/FAIL + SLI
  ui.py                   # CLI/REPL: realtime thinking/commands, spinner,
                          #   /verbose · /quiet toggles, live cost header
```

Build order (each step end-to-end, measurable):

1. **Agent + shell** — raw subprocess, no policy. Prove: do real tasks
   (small migration, bugfix in a real repo) finish? What breaks without a
   sandbox?
2. **Ask layer** — ask on judgment, then approvals. Calibration goal:
   asking is rare, and when it happens the human's answer changes the
   outcome. Cheap permission-asks are a failure sign (approval fatigue).
3. **Two-stage classifier** — stage 1 deterministic arg-array policy at the
   exec gate (not ML); stage 2 tiny local LLM judge on the uncertain
   fraction (prompt-injection, credential-ish, destructive intent). Measure
   latency, cost, miss rate on the POC's own history.
4. **SQLite journal + budget** — `journal_mode=WAL`, every event
   transactional; cost/context math from real `usage` responses; JSONL
   export for humans.
5. **Realtime visibility** — thinking + tool calls print as they happen
   with a spinner (no more "is this hung?"), `/verbose` + `/quiet` toggles,
   `--quiet` for scripts. Textual TUI remains a later increment.
6. **Offline eval** — `eval_corpus.py` runs the whole loop over 8 scenarios
   (happy path, shell failure → recovery, policy deny, approval grant,
   ask_human judgment, budget halt, provider down, PII scrub) and tallies
   PASS/FAIL against the SLOs. The PII scenario proves the invariant: raw
   secret in the journal, scrubbed in the model context.

### Ask-the-human rubric (judgment, not just permission)

Ask when the cost of a wrong guessed decision is high or the answer is
outside the agent's scope:

- major design forks / architecture choices
- ambiguous or conflicting requirements
- cross-repo or cross-boundary changes
- destructive operations (irreversible, data loss)
- choosing between equivalent-looking paths (taste, business intent)
- stuck after N failed attempts (e.g. 3)
- anything implying intent, cost, or a commitment the model can't see

Do NOT ask for: routine edits, retries, "which flag" details. The agent
works; the human judges. Calibrate by measuring how often a human answer
actually changed the plan.

### Local datastore — SQLite (decided)

SQLite embedded, WAL journal mode. One file, no server, crash-safe
(`synchronous=NORMAL`), real SQL for audit queries and cost rollups. The
JSONL export stays for reading; SQLite is the source of truth for queries.
This also supersedes the worry from the critique: the log becomes the db on
purpose, from day one, instead of rotting into one at phase 4.

### POC exit criteria

- Agent finishes a scripted real-task set ≥ 2/3 without a caretaker.
- Ask-rate is calibrated (rare + outcome-changing).
- Classifier catches ≥ 80% of planted injection/destructive cases with
  < 5% false positives on benign traffic, and < 300ms added on the hot path.

## Open Questions

- curam.toml + per-project workdir/evlog init flow ("curam init").
- Approval UX in v1 (inline prompt? event + blocking wait? — the ask layer
  already supports non-interactive answers, the seam for the phone bridge).
- Token/context accounting: trust `usage` fields, or count locally?
- Where the evlog reader surface stabilizes first (OTel export, resume).
- Streaming: the spinner masks request/response latency; an SSE `stream:
  true` path is the real fix for the "hang" feel (see README gaps).
- `local_llm` sanitizer tier: when deterministic isn't enough, wire entity
  redaction via the judge model seam.
- Key management for Rust v1: OS keychain vs `pass` vs the pi-auth fallback.
- Firewall list sourcing: curate upstream as OSS vs fork + maintain locally
  (the allow/deny hostname list; software-dev-first, supply-chain-aware).
