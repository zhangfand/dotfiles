#!/usr/bin/env python3
"""PreToolUse hook: put the repo's code-comment rulebook in context before an edit.

Fires on Edit/Write/MultiEdit. Injects `docs/authoring/comments.md` (found by
walking up from the file being edited) as additionalContext, once per session,
and only for source files. Repos without that doc are unaffected, so the hook is
safe to register globally in ~/.claude/settings.json.

Never blocks: any unexpected condition exits 0 with no output, letting the edit
proceed. It also never emits permissionDecision — doing so would auto-approve
every edit as a side effect of injecting context.
"""

import json
import os
import pathlib
import sys
import tempfile

DOC_RELPATH = pathlib.PurePath("docs", "authoring", "comments.md")

# Source extensions only. Editing prose, config, or data carries no comment
# rules, and injecting there would burn the once-per-session budget.
CODE_SUFFIXES = {
    ".ts", ".tsx", ".mts", ".cts",
    ".js", ".jsx", ".mjs", ".cjs",
    ".py", ".go", ".rs", ".rb", ".java", ".kt", ".swift",
    ".c", ".h", ".cc", ".cpp", ".hpp",
    ".sh", ".bash", ".zsh", ".sql",
    ".css", ".scss", ".vue", ".svelte",
}

HEADER = (
    "Before writing this edit, apply the code-comment rulebook below. It is the "
    "repo's standard for every comment you add, keep, or delete in this session.\n\n"
    "--- docs/authoring/comments.md ---\n"
)


def find_doc(start: pathlib.Path) -> pathlib.Path | None:
    """Nearest ancestor of `start` containing the rulebook, or None."""
    for parent in [start, *start.parents]:
        candidate = parent / DOC_RELPATH
        if candidate.is_file():
            return candidate
    return None


def main() -> int:
    payload = json.load(sys.stdin)
    file_path = payload.get("tool_input", {}).get("file_path")
    if not file_path:
        return 0
    target = pathlib.Path(file_path)
    if target.suffix.lower() not in CODE_SUFFIXES:
        return 0

    doc = find_doc(target.parent)
    if doc is None:
        project_dir = os.environ.get("CLAUDE_PROJECT_DIR")
        if not project_dir:
            return 0
        doc = pathlib.Path(project_dir) / DOC_RELPATH
        if not doc.is_file():
            return 0

    # One injection per session. Re-sending on every edit costs context and
    # trains the model to skim past it.
    session_id = payload.get("session_id", "unknown")
    marker = pathlib.Path(tempfile.gettempdir()) / f"claude-comments-rulebook-{session_id}"
    if marker.exists():
        return 0
    marker.touch()

    json.dump(
        {
            "suppressOutput": True,
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "additionalContext": HEADER + doc.read_text(encoding="utf-8"),
            },
        },
        sys.stdout,
    )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
