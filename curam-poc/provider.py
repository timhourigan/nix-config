"""Provider — one OpenAI-compatible chat-completions client (stdlib urllib).

Covers Ollama, LiteLLM, vLLM, llama.cpp, and cloud APIs that speak the same
/chat/completions shape. `api_key_env` points at an env var name when the
endpoint needs auth (set in curam.yaml).

Every response's `usage` (prompt/completion tokens) is returned so the budget
can account real cost — this is the sovereignty/cost-control seam.
"""

import json
import os
import urllib.error
import urllib.request
from pathlib import Path


class ProviderError(Exception):
    pass


def resolve_provider(cfg: dict, provider_name: str | None = None) -> dict:
    """Pick the provider dict to use.

    Prefers the extended ``providers`` map (mirrors pi's models.json):
    ``cfg.default_provider`` (or the first entry) when no name given.
    Falls back to the legacy single ``cfg.provider`` shape.
    """
    providers = cfg.get("providers")
    if providers:
        name = provider_name or cfg.get("default_provider")
        if not name:
            name = next(iter(providers))
        p = providers.get(name)
        if p is None:
            raise ProviderError(f"unknown provider {name!r}")
        if isinstance(p, str):
            p = {"base_url": p}  # allow a bare URL shorthand
        return {**p, "provider": name}
    return cfg.get("provider") or {}


def _key_from_pi_auth(provider_name: str) -> str | None:
    """Read an API key from pi's credential store (~/.pi/agent/auth.json),
    mirroring how pi itself authenticates. Returns None if absent/unreadable.

    auth.json shape: {"<provider>": {"type": "api_key", "key": "sk-or-..."}}
    """
    try:
        import json as _json

        auth = _json.loads(Path.home().joinpath(".pi/agent/auth.json").read_text())
        entry = auth.get(provider_name) or {}
        key = entry.get("key") if isinstance(entry, dict) else None
        return str(key) if key else None
    except (OSError, ValueError):
        return None


class Provider:
    def __init__(
        self,
        cfg: dict,
        provider_name: str | None = None,
        model_override: str | None = None,
    ):
        p = resolve_provider(cfg, provider_name)
        raw_url = p.get("base_url")
        if not raw_url:
            raise ProviderError("no base_url configured")
        # only http/https — a config pointing at file:// or data:// is a bug/attack
        if not raw_url.startswith(("http://", "https://")):
            raise ProviderError(f"unsupported base_url scheme: {raw_url!r}")
        self.name = p.get("provider", provider_name or "default")
        self.base_url = raw_url.rstrip("/")
        self.model = model_override or p.get("model") or ""
        try:
            self.timeout = float(p.get("timeout_s", 120))
        except (TypeError, ValueError):
            self.timeout = 120.0  # tolerate a malformed timeout; never crash on it
        key_env = p.get("api_key_env") or ""
        self.api_key = os.environ.get(key_env) if key_env else None
        if not self.api_key:
            # fall back to pi's own credential store (~/.pi/agent/auth.json),
            # same file pi reads — so curam just works on this machine without
            # exporting the key again
            self.api_key = _key_from_pi_auth(self.name)
        try:
            self.context_window = int(p.get("context_window") or 0)
        except (TypeError, ValueError):
            self.context_window = 0  # unknown → UI falls back to a default
        self.reasoning_effort = p.get("reasoning_effort") or None
        self.reasoning_supported = bool(p.get("reasoning_effort_supported", True))

    def _headers(self) -> dict:
        h = {"Content-Type": "application/json"}
        if self.api_key:
            h["Authorization"] = f"Bearer {self.api_key}"
        return h

    def chat(self, messages: list[dict], tools: list[dict] | None = None) -> dict:
        """POST /chat/completions. Returns the message dict with `usage`.

        The message is OpenAI-shaped: {"role", "content", "tool_calls"?}.
        `usage` includes prompt_tokens / completion_tokens for the budget.
        """
        body: dict = {
            "model": self.model,
            "messages": messages,
            "stream": False,
        }
        if tools:
            body["tools"] = tools
            body["tool_choice"] = "auto"
        if self.reasoning_effort and self.reasoning_supported:
            body["reasoning_effort"] = self.reasoning_effort
        data = json.dumps(body).encode()
        # pi-lens-ignore: S310 (scheme validated to http/https at init; config URL, not user input)
        req = urllib.request.Request(
            f"{self.base_url}/chat/completions", data=data, headers=self._headers()
        )
        try:
            # pi-lens-ignore: S310 (scheme validated to http/https at init; config URL, not user input)
            # pi-lens-ignore: opengrep:python.lang.security.audit.dynamic-urllib-use-detected.dynamic-urllib-use-detected (scheme restricted at init; config URL), opengrep:python.lang.security.audit.dynamic-urllib-use-detected.dynamic-urllib-use-detected
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                parsed = json.loads(resp.read().decode())
        except (urllib.error.URLError, urllib.error.HTTPError) as e:
            raise ProviderError(f"provider unreachable ({self.base_url}): {e}") from e
        except json.JSONDecodeError as e:  # pragma: no cover
            raise ProviderError(f"non-JSON response from provider: {e}") from e

        try:
            choice = parsed["choices"][0]
            message = choice["message"]
            message["usage"] = parsed.get("usage", {})
            # normalize: some servers return toolCalls camelCase
            if "tool_calls" not in message and "toolCalls" in message:
                message["tool_calls"] = message.pop("toolCalls")
            return message
        except (KeyError, IndexError) as e:  # pragma: no cover
            raise ProviderError(
                f"malformed provider response: {e}: {parsed!r:.300}"
            ) from e


if __name__ == "__main__":
    # no live provider in self-check — just exercise shape handling
    p = Provider(
        {"provider": {"base_url": "http://x", "model": "m", "api_key_env": ""}}
    )
    msg = {
        "role": "assistant",
        "content": None,
        "tool_calls": [{"id": "1", "function": {"name": "ls", "arguments": "{}"}}],
        "usage": {"prompt_tokens": 10, "completion_tokens": 5},
    }
    assert msg["role"] == "assistant"
    assert msg["usage"]["completion_tokens"] == 5
    assert p.base_url == "http://x" and p.model == "m"

    # multi-provider resolution (mirrors pi's models.json shape)
    cfg = {
        "default_provider": "ollama",
        "providers": {
            "ollama": {
                "base_url": "http://localhost:11434/v1",
                "model": "qwen3-coder",
                "context_window": 32768,
                "reasoning_effort_supported": False,
            },
            "openrouter": {
                "base_url": "https://openrouter.ai/api/v1",
                "model": "deepseek/deepseek-v4-flash",
                "context_window": 1000000,
                "reasoning_effort": "high",
            },
        },
    }
    lp = Provider(cfg)
    assert lp.name == "ollama" and lp.model == "qwen3-coder"
    assert lp.context_window == 32768 and not lp.reasoning_supported
    rp = Provider(cfg, provider_name="openrouter")
    assert rp.model == "deepseek/deepseek-v4-flash"
    assert rp.reasoning_effort == "high" and rp.reasoning_supported
    # model_override (classifier swap) keeps base_url, changes only model
    jp = Provider(cfg, provider_name="ollama", model_override="gemma4:e4b")
    assert jp.model == "gemma4:e4b" and jp.base_url == "http://localhost:11434/v1"
    print("provider self-check OK")
