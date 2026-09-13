"""Tools available to the model: read / write / edit / shell.

POC stance: no sandbox. `shell` runs as the user in the configured workdir.
The plan says exactly this — prove fluency first, put the cage in phase 2.
Only hard rule: workdir is the cwd, and commands time out after N seconds.
"""

import subprocess
from pathlib import Path

# JSON schema for each tool, sent to the provider.
TOOL_SCHEMAS = [
    {
        "type": "function",
        "function": {
            "name": "read",
            "description": "Read a file within the workdir.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "relative path"}
                },
                "required": ["path"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "write",
            "description": "Write a file within the workdir (overwrites).",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string"},
                    "content": {"type": "string"},
                },
                "required": ["path", "content"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "edit",
            "description": "Replace the first occurrence of old_text with new_text in a file.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string"},
                    "old_text": {"type": "string"},
                    "new_text": {"type": "string"},
                },
                "required": ["path", "old_text", "new_text"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "shell",
            "description": "Run a shell command in the workdir. Returns exit code, stdout, stderr.",
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {"type": "string"},
                    "timeout": {
                        "type": "integer",
                        "description": "seconds, default 60",
                    },
                },
                "required": ["command"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "ask_human",
            "description": (
                "Ask the human for judgment (design fork, ambiguity, "
                "irreversible change, or when stuck). Use sparingly — "
                "for decisions only a human can make."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "question": {"type": "string"},
                    "options": {"type": "array", "items": {"type": "string"}},
                },
                "required": ["question"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "use_skill",
            "description": (
                "Load a skill's full instructions into context. Call this "
                "with a skill name from the system prompt's Available skills "
                "list when that skill applies to the current task."
            ),
            "parameters": {
                "type": "object",
                "properties": {"name": {"type": "string"}},
                "required": ["name"],
            },
        },
    },
]

MAX_READ_CHARS = 60_000
MAX_OUTPUT_CHARS = 8_000


def _resolve(workdir: Path, path: str) -> Path:
    return (workdir / path).resolve()


def tool_read(workdir: Path, args: dict) -> dict:
    p = _resolve(workdir, args["path"])
    try:
        text = p.read_text(errors="replace")
        truncated = len(text) > MAX_READ_CHARS
        return {
            "ok": True,
            "path": str(p),
            "content": text[:MAX_READ_CHARS],
            "truncated": truncated,
        }
    except OSError as e:
        return {"ok": False, "error": str(e)}


def tool_write(workdir: Path, args: dict) -> dict:
    p = _resolve(workdir, args["path"])
    try:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(args["content"])
        return {"ok": True, "path": str(p), "bytes": len(args["content"])}
    except OSError as e:
        return {"ok": False, "error": str(e)}


def tool_edit(workdir: Path, args: dict) -> dict:
    p = _resolve(workdir, args["path"])
    try:
        text = p.read_text(errors="replace")
    except OSError as e:
        return {"ok": False, "error": str(e)}
    old, new = args["old_text"], args["new_text"]
    if old not in text:
        return {"ok": False, "error": "old_text not found in file"}
    p.write_text(text.replace(old, new, 1))
    return {"ok": True, "path": str(p), "replaced": text.count(old)}


def _as_str(s: str | bytes | None) -> str:
    if s is None:
        return ""
    if isinstance(s, bytes):
        return s.decode(errors="replace")
    return s


def _trim(s: str | bytes | None, limit: int = MAX_OUTPUT_CHARS) -> str:
    t = _as_str(s)
    return (
        t
        if len(t) <= limit
        else t[:limit] + f"\n... (truncated {len(t) - limit} chars)"
    )


def tool_shell(workdir: Path, args: dict, timeout_default: int = 60) -> dict:
    cmd = args["command"]
    try:
        timeout = int(args.get("timeout") or timeout_default)
    except (TypeError, ValueError):
        timeout = timeout_default
    try:
        # pi-lens-ignore: python-command-injection (POC: raw shell is the point; sandbox is phase 2)
        # pi-lens-ignore: S602 (POC: no-sandbox is the explicit stance; bwrap cage later)
        # pi-lens-ignore: opengrep:python.lang.security.audit.subprocess-shell-true.subprocess-shell-true (POC no-sandbox; bwrap later)
        proc = subprocess.run(
            cmd,
            shell=True,
            cwd=str(workdir),
            capture_output=True,
            text=True,
            timeout=timeout,
            errors="replace",
        )
        return {
            "ok": True,
            "exit": proc.returncode,
            "stdout": _trim(proc.stdout),
            "stderr": _trim(proc.stderr),
        }
    except subprocess.TimeoutExpired as e:
        # stdout/stderr may be bytes when text=True races the timeout; decode
        return {
            "ok": False,
            "error": f"timed out after {timeout}s",
            "stdout": _trim(e.stdout),
            "stderr": _trim(e.stderr),
        }
    except OSError as e:
        return {"ok": False, "error": str(e)}


TOOLS = {
    "read": tool_read,
    "write": tool_write,
    "edit": tool_edit,
    "shell": tool_shell,
}


def run(workdir: Path, name: str, args: dict, timeout_default: int = 60) -> dict:
    fn = TOOLS.get(name)
    if fn is None:
        return {"ok": False, "error": f"unknown tool: {name}"}
    if name == "shell":
        return fn(workdir, args, timeout_default)
    return fn(workdir, args)


if __name__ == "__main__":
    import tempfile

    with tempfile.TemporaryDirectory() as td:
        wd = Path(td)
        assert tool_write(wd, {"path": "a/b.txt", "content": "hello"})["ok"]
        r = tool_read(wd, {"path": "a/b.txt"})
        assert r["content"] == "hello"
        assert tool_edit(
            wd, {"path": "a/b.txt", "old_text": "hello", "new_text": "bye"}
        )["ok"]
        assert tool_read(wd, {"path": "a/b.txt"})["content"] == "bye"
        # edit on missing text reports failure, does not crash
        assert not tool_edit(
            wd, {"path": "a/b.txt", "old_text": "zzz", "new_text": "x"}
        )["ok"]
        s = tool_shell(wd, {"command": "printf hi"})
        assert s["exit"] == 0 and s["stdout"].strip() == "hi"
        bad = tool_shell(wd, {"command": "exit 3"})
        assert bad["exit"] == 3
        assert not run(wd, "nope", {})["ok"]
        print("tools self-check OK")
