"""SQLite WAL journal — the source of truth for audit + cost.

Every event is a row in `events` (JSON payload + timestamp + session_id).
Budget/cost rollups are SQL views over it, per the SLO doc: *every SLI is one
query* — this schema is what makes that possible.

Stdlib-only (sqlite3 ships with Python). WAL mode + synchronous=NORMAL for a
crash-safe journal. JSONL export (`export_jsonl`) for human reading.
"""

import json
import sqlite3
import time
import uuid
from pathlib import Path

_SCHEMA = """
CREATE TABLE IF NOT EXISTS events (
    seq        INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT    NOT NULL,
    ts         REAL    NOT NULL,
    etype      TEXT    NOT NULL,   -- tool_call / tool_result / ask_human / ...
    payload    TEXT    NOT NULL    -- JSON
);
CREATE INDEX IF NOT EXISTS idx_events_session ON events(session_id, seq);
CREATE INDEX IF NOT EXISTS idx_events_type    ON events(etype);
"""


class Journal:
    def __init__(self, path: str | Path, session_id: str | None = None):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.session_id = session_id or uuid.uuid4().hex[:12]
        # check_same_thread=False: the TUI runs the agent loop in a worker
        # thread while the journal lives in the main thread; single-writer
        # (one agent at a time) + sqlite WAL makes this safe.
        self.db = sqlite3.connect(str(self.path), check_same_thread=False)
        # pi-lens-ignore: python-sql-injection (canned pragma, no user input)
        self.db.execute("PRAGMA journal_mode=WAL")
        # pi-lens-ignore: python-sql-injection (canned pragma, no user input)
        self.db.execute("PRAGMA synchronous=NORMAL")
        self.db.executescript(_SCHEMA)
        self.db.commit()

    def log(self, etype: str, payload: dict) -> int:
        row = (self.session_id, time.time(), etype, json.dumps(payload))
        # pi-lens-ignore: python-sql-injection (INSERT is fully parameterized)
        cur = self.db.execute(
            "INSERT INTO events(session_id, ts, etype, payload) VALUES (?,?,?,?)", row
        )
        self.db.commit()
        rowid = cur.lastrowid
        return rowid if rowid is not None else 0

    def events(self, etype: str | None = None) -> list[dict]:
        # single literal query; etype is bound as a parameter, never interpolated
        sql = "SELECT seq, session_id, ts, etype, payload FROM events WHERE (? IS NULL OR etype=?) ORDER BY seq"
        # pi-lens-ignore: python-sql-injection (all queries parameterized; heur misses bound tuple)
        rows = self.db.execute(sql, (etype, etype)).fetchall()
        return [
            {
                "seq": r[0],
                "session_id": r[1],
                "ts": r[2],
                "etype": r[3],
                "payload": self._parse_payload(r[4]),
            }
            for r in rows
        ]

    @staticmethod
    def _parse_payload(raw: str) -> dict:
        try:
            return json.loads(raw)
        except (json.JSONDecodeError, TypeError):
            return {"_corrupt": raw[:256]}  # tolerate a bad row; never crash the loop

    def export_jsonl(self, path: str | Path | None = None) -> str:
        out = [
            json.dumps(
                {"seq": e["seq"], "ts": e["ts"], "etype": e["etype"], **e["payload"]}
            )
            for e in self.events()
        ]
        text = "\n".join(out) + "\n"
        if path:
            Path(path).write_text(text)
        return text

    def close(self):
        self.db.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()


if __name__ == "__main__":
    import tempfile

    with tempfile.TemporaryDirectory() as td:
        j = Journal(Path(td) / "j.db", session_id="test")
        id1 = j.log("user_message", {"text": "hi"})
        j.log("tool_call", {"name": "read", "args": {"path": "a.py"}})
        j.log("tool_result", {"ok": True})
        assert j.events()[0]["etype"] == "user_message"
        assert len(j.events("tool_call")) == 1
        assert id1 > 0
        # journal is durable + resumable: reopen and rebuild from rows
        j.close()
        j2 = Journal(Path(td) / "j.db", session_id="test")
        assert len(j2.events()) == 3
        assert "user_message" in j2.export_jsonl()
        j2.close()
        print("journal self-check OK")
