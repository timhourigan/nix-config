"""PII / secret sanitizer — scrub sensitive material before it reaches an LLM.

Three tiers (`[pii] level` in curam.toml):

  off           — no scrubbing (e.g. local-only models, throwaway dirs)
  deterministic — regex masking, in-process, stdlib-only. Default when on.
  local_llm     — optional tier 2: entity redaction via a local judge model
                  (same seam as classify.py). Falls back to deterministic on
                  any error. Not yet wired — documented, not built.

The rule that matters (also in docs/curam.md): the JOURNAL keeps the raw
result (audit completeness — a zero-trust trail can't redact), but anything
that crosses the provider boundary — the main model's context and the
classifier judge's input — is scrubbed first. So secrets never enter the
model context and never leave the machine, while the audit stays intact.

Patterns live in code (like policy.py) on purpose: exact, testable,
reviewable. Config only toggles level / placeholders / internal domains.
"""

import re

DEFAULT_PLACEHOLDER = "{REDACTED}"

# ordered (kind, compiled regex); first-match-wins per span
_PATTERNS = [
    ("openrouter", re.compile(r"sk-or-[A-Za-z0-9_-]{16,}")),
    ("openai", re.compile(r"\bsk-[A-Za-z0-9]{16,}")),
    ("aws", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("github_pat", re.compile(r"\bghp_[A-Za-z0-9]{20,}\b")),
    ("github_fine_grained", re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}\b")),
    ("slack", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b")),
    ("google", re.compile(r"\bAIza[0-9A-Za-z_-]{30,}\b")),
    (
        "jwt",
        re.compile(
            r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"
        ),
    ),
    ("email", re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")),
    (
        "private_key",
        re.compile(
            r"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----",
            re.DOTALL,
        ),
    ),
    ("generic_sk", re.compile(r"\bsk-[A-Za-z0-9_-]{16,}\b")),
    (
        "key_value",
        re.compile(
            r"\b(?:token|secret|api[_-]?key)\s*[=:]\s*['\"]?[A-Za-z0-9_\-./+=]{12,}",
            re.IGNORECASE,
        ),
    ),
]


def _mask(placeholder: str, kind: str):
    """Build a re.sub replacement that labels the masked span by kind."""

    def _repl(_m):
        return f"{placeholder}:{kind}"

    return _repl


class Sanitizer:
    """Deterministic secret scrubber. `scrub(text)` returns text with any
    matched secret replaced by a labeled placeholder."""

    def __init__(self, cfg: dict):
        p = cfg.get("pii") or {}
        self.level = (p.get("level") or "deterministic").lower()
        self.placeholder = p.get("placeholder") or DEFAULT_PLACEHOLDER
        self.internal_domains = [str(d) for d in (p.get("internal_domains") or []) if d]
        self.stats = {"spans_masked": 0}

    @property
    def enabled(self) -> bool:
        return self.level in ("deterministic", "local_llm")

    def scrub(self, text: str) -> str:
        """Mask secrets in `text`. No-op when disabled. Pure function."""
        if not self.enabled or not text:
            return text
        out = text
        masked = 0
        for kind, pat in _PATTERNS:
            out, n = pat.subn(_mask(self.placeholder, kind), out)
            masked += n
        for dom in self.internal_domains:
            pat = re.compile(r"[\w.-]*" + re.escape(dom) + r"[\w.-]*")
            out, n = pat.subn(_mask(self.placeholder, "domain"), out)
            masked += n
        self.stats["spans_masked"] += masked
        return out


if __name__ == "__main__":
    s = Sanitizer({"pii": {"level": "deterministic"}})
    assert s.enabled
    out = s.scrub("key sk-or-abcdefghijklmnop123456 used here; mail a@b.com")
    assert "sk-or-abcdefghijklmnop123456" not in out
    assert "a@b.com" not in out
    assert "{REDACTED}:openrouter" in out and "{REDACTED}:email" in out
    assert s.scrub("plain text, no secrets") == "plain text, no secrets"
    # private key block masked wholesale
    pk = "-----BEGIN RSA PRIVATE KEY-----\nABC==\n-----END RSA PRIVATE KEY-----"
    assert "{REDACTED}:private_key" in s.scrub(pk)
    # disabled is a no-op
    s_off = Sanitizer({"pii": {"level": "off"}})
    assert (
        s_off.scrub("key sk-or-abcdefghijklmnop123456")
        == "key sk-or-abcdefghijklmnop123456"
    )
    print("sanitize self-check OK")
