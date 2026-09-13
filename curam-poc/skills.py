"""Skills — markdown skill files with progressive disclosure.

Convention (docs/curam.md): every `*.md` in <workdir>/skills/ is a skill.
The frontmatter carries `name` + `description` (SHORT — that's all that's
advertised to the model, per the Agent Skills standard). The body is loaded
only when the model calls `use_skill`. Evals live in <workdir>/evals/ and
are never read into context — a skill with no matching eval warns at startup.

This is deliberately lean: no installer, no runner, no dependency. The full
Agent-Skills-style system (params, resource bundling) is Rust-phase.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

_FRONT = re.compile(r"\A---\s*\n(.*?)\n---\s*\n?", re.DOTALL)


@dataclass
class Skill:
    name: str
    description: str
    path: Path
    body: str = ""
    description_chars: int = 0
    body_lines: int = 0
    uses: int = 0
    has_eval: bool = False

    # the short advertisement injected into the system prompt (name + desc)
    def advertise(self) -> str:
        return f"- {self.name}: {self.description}".strip()

    def record_use(self):
        self.uses += 1


def _parse_frontmatter(text: str) -> tuple[dict, str]:
    """Return (frontmatter_dict, body). Empty dict + full text if no frontmatter."""
    m = _FRONT.match(text)
    if not m:
        return {}, text
    fm: dict = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            fm[k.strip()] = v.strip().strip('"').strip("'")
    return fm, text[m.end() :]


@dataclass
class LintResult:
    warnings: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)


def load_skills(skills_dir: Path) -> list[Skill]:
    """Load + parse all skill .md files (name + description + body)."""
    if not skills_dir.is_dir():
        return []
    skills: list[Skill] = []
    for f in sorted(skills_dir.glob("*.md")):
        try:
            raw = f.read_text(errors="replace")
        except OSError:
            continue
        fm, body = _parse_frontmatter(raw)
        name = fm.get("name") or f.stem
        skills.append(
            Skill(
                name=name,
                description=fm.get("description", ""),
                path=f,
                body=body.strip(),
                description_chars=len(fm.get("description", "")),
                body_lines=len(body.splitlines()),
            )
        )
    return skills


def lint_skills(
    skills: list[Skill],
    evals_dir: Path,
    max_desc_chars: int = 240,
    max_body_lines: int = 200,
) -> LintResult:
    """Warn at startup: parse issues, oversized desc/body, missing evals."""
    res = LintResult()
    eval_names = (
        {p.stem for p in evals_dir.glob("*.md")} if evals_dir.is_dir() else set()
    )
    for s in skills:
        if not s.description:
            res.errors.append(
                f"skill '{s.name}': empty description (frontmatter required)"
            )
        if s.description_chars > max_desc_chars:
            res.warnings.append(
                f"skill '{s.name}': description {s.description_chars}ch > {max_desc_chars} "
                f"(only the description enters context — keep it short)"
            )
        if s.body_lines > max_body_lines:
            res.warnings.append(
                f"skill '{s.name}': body {s.body_lines} lines > {max_body_lines} "
                f"(loaded on demand, but keep lean)"
            )
        if s.name not in eval_names:
            res.warnings.append(
                f"skill '{s.name}': no matching eval (expected {evals_dir}/{s.name}.md) "
                f"— untested skills are unproven"
            )
    return res


def find_skill(skills: list[Skill], name: str) -> Skill | None:
    for s in skills:
        if s.name == name:
            return s
    return None


def catalog_block(skills: list[Skill]) -> str:
    """The ONLY thing about skills that enters the system prompt: name + desc."""
    if not skills:
        return ""
    lines = ["\nAvailable skills (call use_skill '<name>' to load the full one):"]
    lines += [f"  {s.advertise()}" for s in skills]
    lines.append("")
    return "\n".join(lines)


if __name__ == "__main__":
    import tempfile
    from pathlib import Path

    with tempfile.TemporaryDirectory() as td:
        d = Path(td)
        sk = d / "skills"
        ev = d / "evals"
        sk.mkdir()
        ev.mkdir()
        good = sk / "git-workflow.md"
        good.write_text(
            "---\nname: git-workflow\ndescription: Always commit + tag after a task.\n---\n"
            "Full git workflow instructions...\n"
        )
        evgood = ev / "git-workflow.md"
        evgood.write_text("eval: git workflow covered by eval_tasks/git_workflow\n")
        bad = sk / "big.md"
        bad.write_text(
            "---\nname: big\ndescription: " + "x" * 300 + "\n---\n" + "line\n" * 250
        )
        # no matching eval
        skills = load_skills(sk)
        assert len(skills) == 2
        catalog = catalog_block(skills)
        # progressive disclosure: description in catalog, body NOT
        assert "Always commit + tag" in catalog
        assert "Full git workflow instructions" not in catalog
        res = lint_skills(skills, ev, max_desc_chars=240, max_body_lines=200)
        w = "\n".join(res.warnings + res.errors)
        assert "git-workflow" not in w or "no matching eval" not in w.replace(
            "description", ""
        )  # has eval
        assert len(res.warnings) >= 1  # big() blows both limits
        # use tracking
        gw = find_skill(skills, "git-workflow")
        assert gw is not None
        if gw:
            gw.record_use()
            gw.record_use()
            assert gw.uses == 2
        print("skills self-check OK")
