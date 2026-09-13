# curam — SLOs & SLIs

How to read this:

- **SLI** = the measurable. **SLO** = target + window.
- Every SLI must be computable from the session journal (SQLite) with one
  query. If it can't be, it isn't an SLI yet — it's a wish. The journal is
  the instrument; that's the point of making it the DB from day one.
- Two tiers: **Go/No-Go** (decides whether we keep building) and **Watch**
  (calibrate, no gate).
- Security gets **invariants**, not SLOs, wherever the architecture can
  enforce the property instead of us hoping for it.

## 0. Invariants (structural, not measured — enforced by construction)

| Invariant | Means |
| --- | --- |
| Single exec path | every command executes through the exec gate; no second path exists |
| Destructive ⇒ approval | irreversible/destructive commands *cannot* execute without a recorded human approval event in the journal |
| Journal completeness | every `tool_call` has a matching `tool_result` or terminal `error`; every event is written — 100%, structural |
| Resumability | any session can be reconstructed from the journal alone (crash → restart) |
| **No secrets cross the provider boundary** | anything sent to any LLM (main model or judge) is scrubbed by the sanitizer; the journal keeps the RAW result, the wire gets the masked one — structural (eval scenario_pii_scrub asserts it) |
| **Failures are never silent** | provider-down / budget-halt / iteration-cap all emit a loud, actionable message (no path returns None or an error without one) — structural; eval scenario_provider_down asserts it |

These get SLOs only on their **mechanism availability** below, not their
outcome (you can't meaningfully SLO "zero escapes").

## 1. North-Star SLOs (Go/No-Go)

| # | Domain | SLI | SLO | Window | Notes |
| --- | --- | --- | --- | --- | --- |
| N1 | Efficacy | Task completion rate — fixed scripted task set, no caretaker | **≥ 0.67** | ≥ 30 tasks | fixed + versioned corpus, not self-selected work |
| N2 | Judgment | Ask rate — asks per completed task | **band [1, 5]**, not a floor | per task | too low = silent guessing, too high = fatigue; the band IS the target |
| N3 | Judgment | Ask quality — % of human answers that change the agent's subsequent behavior | **≥ 0.80** | ≥ 30 asks | outcome-changing = plan/command/decision differs post-answer |
| N4 | Security | Planted-injection catch rate (two-stage classifier) | **≥ 0.80** | red-team corpus, ≥ 100 cases | versioned corpus with benign + adversarial cases |
| N5 | Security | False-positive rate on benign traffic | **< 0.05** | same corpus | benign = normal dev traffic |
| N6 | Security | Destructive false-negative | **= 0** on planted set, and structurally: destructive path requires approval (invariant) | corpus | the invariant makes the number near-tautological |
| N7 | Security | Classifier hot-path overhead | **≤ 300 ms** p95 | per tool call | stage-1 deterministic must be ~0; stage-2 only on uncertain remainder |
| N8 | Cost | Reported cost vs actual | **within ±10 %** | per session | price map + usage fields; mismatch = config bug |
| N9 | Cost | Budget adherence | **100 %** of sessions respect the cap | per session | enforced by the harness, not reported after the fact |
| N10 | Trust | Journal write completeness | **100 %** | per session | structural; SLO guards the mechanism |

## 2. Watch SLIs (no gate — calibrate, don't gate)

| SLI | Definition | Initial watch band |
| --- | --- | --- |
| Loop-stall rate | % of tool calls that repeat the immediately-prior call, ≥ 3 consecutive | ≤ 5 % |
| Silent-miss rate | "should have asked, didn't" — measured by trap tasks + sampled review, not self-report | 0 on trap tasks; ≤ 3/100 on sampled review |
| Ask decision time | human time-to-answer, median | ≤ 60 s |
| Time-to-first-response | task → first model output | ≤ 2 s local / ≤ 15 s cloud (p95) |
| Context bloat | tokens per completed task, median | watch trend, no gate |
| Local/cloud split | % tokens served local vs cloud | report, no gate |
| Classifier cost | $ per 1k classified calls | report, no gate |
| Tool failure rate | % tool calls exiting non-zero that don't self-recover | watch trend |
| Sanitizer misses (planted secrets) | # of eval-planted secrets found in the model context that should've been masked | 0 on the eval corpus |

## 3. Error budgets (per 100 completed tasks, or per week)

| Budget | Means the SLO is burning down; respond |
| --- | --- |
| ≤ 3 silent misses on high-cost decisions | judgment layer degrading; tune ask triggers |
| ≤ 5 approval-fatigue events (destructive approved in < 5 s) | humans rubber-stamping; redesign ask UX or reduce frequency |
| > 1 session with missing journal events | mechanism fault; treat as invariant breach, stop + fix |

## 4. Anti-SLOs (what NOT to optimize)

- **Never** "zero asks." The band is the goal; a floor of zero would be gamed
  by never consulting the human.
- Completion measured on **fixed scripted tasks only** — self-selected work
  inflates the number and you'd be rewarding the agent for dodging hard tasks.
- **Never** raw "tokens per task" in isolation — it punishes the agent for
  actually testing. Cost accuracy (N8) is the real metric; token count is a
  diagnostic.
- Binary completion for scripted tasks — **no partial-credit inflation**.

## 5. Measurement protocol

- Each SLI = one SQL view over the journal (`docs/curam-slos.sql`), runnable
  by a `curam sli` command. If a view can't express it, it leaves the table.
- **Task corpus is versioned and committed** — benign, adversarial (injection,
  destructive), and *trap* tasks whose correct completion *requires* a human
  decision. Traps are how silent-miss rate is measured; without them it's
  unmeasurable self-report.
- Sample-and-audit: a random ~10 % of completed tasks get human review for
  missed judgment calls. Feeds the silent-miss band.
- SLOs are calibration anchors, not career targets. Re-baseline from data
  after the first ~20 real sessions, then renegotiate quarterly.

## 6. When we're done

Go/No-Go SLOs met on the fixed corpus **and** on ≥ 5 real (non-scripted)
sessions → the POC earned the Rust rewrite. Missed → we have the numbers to
say *what* failed and why, which was the entire reason to measure.
