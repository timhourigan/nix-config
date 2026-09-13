"""Budget — session cost accounting from real `usage` fields.

Prices live in curam.yaml (USD per 1M tokens, per model). The provider feeds
usage back after every completion; we convert to $ and journal it. If a
provider omits usage, we can't report cost — that's logged as a `cost_unknown`
event so the SLO "reported cost within ±10%" is measurable (i.e. we know when
we're blind).
"""

import tomllib


class Budget:
    def __init__(self, cfg: dict, journal):
        self.cfg = cfg
        self.journal = journal
        b = cfg["budget"]
        try:
            self.cap_usd = float(b.get("cap_usd") or 0)
        except (TypeError, ValueError):
            self.cap_usd = 0.0  # malformed cap → no cap; never crash the loop
        raw_prices = b.get("price_per_mtok") or {}
        try:
            self.prices = {str(k): float(v) for k, v in raw_prices.items()}
        except (TypeError, ValueError):
            self.prices = {}  # malformed price map → all models free
        self.spent_usd = 0.0
        self.prompt_tokens = 0
        self.completion_tokens = 0
        self.unknown_usage = 0

    def price_per_mtok(self, model: str) -> float:
        return self.prices.get(model, 0.0)  # unknown model = free (local default)

    def charge(self, model: str, usage: dict) -> float:
        """Record a completion's token usage; returns cost in USD for the call."""
        pt = usage.get("prompt_tokens")
        ct = usage.get("completion_tokens")
        if pt is None or ct is None:
            self.unknown_usage += 1
            self.journal.log("cost_unknown", {"model": model, "usage": usage})
            return 0.0
        cost = self.price_per_mtok(model) * (pt + ct) / 1_000_000
        self.spent_usd += cost
        self.prompt_tokens += pt
        self.completion_tokens += ct
        self.journal.log(
            "cost",
            {
                "model": model,
                "prompt_tokens": pt,
                "completion_tokens": ct,
                "cost_usd": round(cost, 6),
                "session_total_usd": round(self.spent_usd, 6),
            },
        )
        return cost

    @property
    def over_budget(self) -> bool:
        return self.cap_usd > 0 and self.spent_usd >= self.cap_usd

    def summary(self) -> dict:
        return {
            "spent_usd": round(self.spent_usd, 6),
            "cap_usd": self.cap_usd,
            "prompt_tokens": self.prompt_tokens,
            "completion_tokens": self.completion_tokens,
            "unknown_usage_calls": self.unknown_usage,
        }


if __name__ == "__main__":
    import tempfile
    from pathlib import Path

    from journal import Journal

    with tempfile.TemporaryDirectory() as td:
        j = Journal(Path(td) / "j.db")
        cfg = tomllib.loads(
            'budget = { cap_usd = 1.0, price_per_mtok = { "gpt-4o" = 2.5 } }'
        )
        b = Budget(cfg, j)
        # 1M tokens at $2.5/M = $2.50 — over the $1 cap in one call
        b.charge("gpt-4o", {"prompt_tokens": 500_000, "completion_tokens": 500_000})
        assert b.spent_usd == 2.5
        assert b.over_budget
        # unknown model = free
        b2 = Budget(cfg, j)
        b2.charge("local-model", {"prompt_tokens": 100, "completion_tokens": 100})
        assert b2.spent_usd == 0.0
        # missing usage is tracked, not silent
        b3 = Budget(cfg, j)
        b3.charge("gpt-4o", {})
        assert b3.unknown_usage == 1
        assert j.events("cost") and j.events("cost_unknown")
        print("budget self-check OK")
