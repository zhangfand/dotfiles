#!/usr/bin/env bash
# Stop hook: once per session, block the first stop and remind the model to
# verify it tested the implemented behaviors and presented a Test Coverage
# Report. After the first block, subsequent stops in the same session pass
# through unimpeded so the reminder doesn't loop.
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

STATE_DIR="${TMPDIR:-/tmp}/claude-coverage-stop-hook"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/$SESSION_ID"

# Already reminded this session — allow stop.
if [[ -f "$STATE_FILE" ]]; then
  exit 0
fi
touch "$STATE_FILE"

read -r -d '' REASON <<'EOF' || true
COVERAGE CHECKPOINT (one-time per session)

Before this session stops: if any turn in this session implemented a behavior, feature, or bug fix, ensure your most recent reply presents a "Test Coverage Report" with all three parts:
  - Behaviors tested: one bullet per scenario, naming the observable property verified.
  - Test doubles used: each mock/stub/fake/in-memory replacement, what real component it replaced, and why the swap was necessary. Flag any that hide real coverage gaps (e.g., mocked DB instead of the real migration path).
  - Real coverage assessment: one sentence on what the tests actually prove vs. what they don't.

If you already presented the report, OR this session was purely exploration / questions / a no-behavior-change refactor / pure docs: reply with one short line acknowledging that ("coverage report already presented" or "no implementation this session") and stop again. This hook fires only once per session, so the next stop will go through.

If you skipped the report on an implementation turn: produce it now and then stop.
EOF

jq -nc --arg reason "$REASON" '{decision: "block", reason: $reason}'
