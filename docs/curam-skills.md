# curam — Skills & System Prompt Design (references + decisions)

How curam handles system prompts and skills, and the external references that
shaped it. Kept here so the design has a provenance trail (see docs/curam.md).

## curam's approach (short version)

- System prompt: `[agent] system_prompt` override (curam.toml) or the built-in
  default. Always md-derived.
- Skills: `<workdir>/skills/*.md`, frontmatter = `name` + `description`. ONLY
  name+description enter the context (the "catalog"). The full body loads on
  demand via the `use_skill` tool. (Progressive disclosure.)
- Evals: `<workdir>/evals/*.md`. **Never read into context** — a skill with no
  matching eval warns at startup, but the eval file itself is never sent to a
  model.
- Startup lint (operator-facing, stderr — never model-facing): oversized
  description / body, missing frontmatter, no-matching-eval.
- Metrics: journal `skill_used` events (name, description chars, body lines,
  cumulative uses) → surfaced in `ui.py --sli`.

## Why minimal matters — the references

### pi (the harness we're learning from)

- **System prompt files**: `.pi/SYSTEM.md` (project) or `~/.pi/agent/SYSTEM.md`
  (global) **replace** the default; `APPEND_SYSTEM.md` **appends**.
  <https://pi.dev/docs/latest/usage>
- **Skills**: pi implements the Agent Skills standard — a `SKILL.md` with
  `name` + `description` frontmatter; the model sees the *advertised* skills
  and loads full bodies on demand. <https://pi.dev/docs/latest/skills>
- Takeaway: replace-vs-append is a clean primitive; skills are advertised by
  name+description, not full text. curam mirrors both.

### Claude Code's system prompt (why "keep it short" is real)

- Claude Code's framework ships **515 embedded prompts** (v2.1.252) — a large
  fixed overhead on every request. <https://github.com/Piebald-AI/claude-code-system-prompts>
- Industry analysis: Claude Code sends thousands of tokens of unused machinery
  (skills catalogue, feature instructions, tool defs) on **every turn**, and
  users strip it back for cost and behavior.
  <https://www.reddit.com/r/ClaudeCode/comments/1slfnoq/dont_use_claude_codes_default_system_prompt/>
  (blocked for direct fetch; captured via search + aihero.dev analysis)
  <https://www.aihero.dev/how-to-kill-the-bloat-in-claude-codes-system-prompt>
- Anthropic's own lessons: prompt caching makes the *stable prefix* (system
  prompt + tool defs) cached, so **its size has a fixed per-turn cost**, and
  keeping that prefix small & stable matters a lot.
  <https://claude.com/blog/lessons-from-building-claude-code-prompt-caching-is-everything>
- Anthropic's platform docs maintain structured release notes for each
  system prompt variant (Opus/Sonnet/…, with token counts), which is the
  authoritative trail for what changed over time:
  <https://platform.claude.com/docs/en/release-notes/system-prompts/overview>

## Design rules this yields for curam

1. **Prompts/skills are always .md files.** No inline strings that pretend to
   be prompt config.
2. **Only the description enters context.** The full skill body is NOT in the
   system prompt — that's the whole point (progressive disclosure, minimal
   prefix).
3. **Short is enforced with a lint, not a hope.** Warnings at startup for
   description > 240ch or body > 200 lines. Keeps the catalog cheap.
4. **Skills without evals are unproven.** Warned at startup. (An unevaluated
   skill is cargo-culting prompt-engineering.)
5. **Evals never enter context.** They're operator signals, not model input.
   (Split directories is the hard boundary.)
6. **Metrics are journaled.** `skill_used` with description size + body size +
   usage count, surfaced in SLI. If a skill is never used, you see it.

## Future (Rust-phase)

- Parameterized skills / resource bundling (the full Agent Skills standard).
- Skill *versioning* + per-skill eval coverage gates.
- Possibly a `/skills` TUI pane listing skills, sizes, usage counts.
