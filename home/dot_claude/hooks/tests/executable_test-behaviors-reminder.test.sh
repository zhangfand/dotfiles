#!/usr/bin/env bash
# Tests for test-behaviors-reminder.sh: the directive should only be injected
# when the previous assistant turn modified code.
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/test-behaviors-reminder.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

# --- fixture builders ---------------------------------------------------------

user_prompt() { # $1=text
  jq -nc --arg t "$1" '{type:"user", message:{role:"user", content:$t}}'
}

tool_result() { # $1=tool_use_id
  jq -nc --arg id "$1" '{type:"user", message:{role:"user", content:[{type:"tool_result", tool_use_id:$id, content:"ok"}]}}'
}

assistant_with_tools() { # $@=tool names
  local arr='[]'
  for name in "$@"; do
    arr=$(jq -c --arg n "$name" '. + [{type:"tool_use", id:("u_" + $n), name:$n, input:{}}]' <<<"$arr")
  done
  jq -nc --argjson c "$arr" '{type:"assistant", message:{role:"assistant", content:$c}}'
}

# --- runner -------------------------------------------------------------------

# Run the hook with a transcript file and check whether the directive is emitted.
# $1=fixture path  $2="inject"|"skip"  $3=description
run_case() {
  local transcript="$1" expect="$2" desc="$3"
  local input out
  input=$(jq -nc --arg p "$transcript" '{transcript_path:$p, prompt:"hi"}')
  out=$(printf '%s' "$input" | bash "$HOOK")
  local got="skip"
  if [[ -n "$out" ]] && jq -e '.hookSpecificOutput.additionalContext | test("TESTING & COVERAGE DIRECTIVE")' <<<"$out" >/dev/null 2>&1; then
    got="inject"
  fi
  if [[ "$got" == "$expect" ]]; then
    printf '  ok   %s\n' "$desc"
    PASS=$((PASS+1))
  else
    printf '  FAIL %s (expected %s, got %s)\n  out=%s\n' "$desc" "$expect" "$got" "$out"
    FAIL=$((FAIL+1))
  fi
}

# --- scenarios ----------------------------------------------------------------

# 1) Edit in last turn → inject
f="$TMP/edit-last.jsonl"
{ user_prompt "first"; assistant_with_tools Read; user_prompt "second"; assistant_with_tools Edit; tool_result u_Edit; user_prompt "current"; } > "$f"
run_case "$f" inject "Edit in previous turn"

# 2) Write → inject
f="$TMP/write-last.jsonl"
{ user_prompt "first"; assistant_with_tools Write; user_prompt "current"; } > "$f"
run_case "$f" inject "Write in previous turn"

# 3) MultiEdit → inject
f="$TMP/multiedit-last.jsonl"
{ user_prompt "first"; assistant_with_tools Bash MultiEdit; user_prompt "current"; } > "$f"
run_case "$f" inject "MultiEdit in previous turn"

# 4) NotebookEdit → inject
f="$TMP/notebook-last.jsonl"
{ user_prompt "first"; assistant_with_tools NotebookEdit; user_prompt "current"; } > "$f"
run_case "$f" inject "NotebookEdit in previous turn"

# 5) Read-only previous turn → skip
f="$TMP/read-only.jsonl"
{ user_prompt "first"; assistant_with_tools Read Bash Grep; user_prompt "current"; } > "$f"
run_case "$f" skip "Read-only previous turn"

# 6) First prompt of session (no prior turn) → skip
f="$TMP/first-prompt.jsonl"
{ user_prompt "current"; } > "$f"
run_case "$f" skip "First prompt of session"

# 7) Empty transcript → skip
f="$TMP/empty.jsonl"
: > "$f"
run_case "$f" skip "Empty transcript"

# 8) Missing transcript file → skip (default safe)
run_case "$TMP/does-not-exist.jsonl" skip "Missing transcript file"

# 9) transcript_path absent in input → skip
NO_PATH_INPUT='{"prompt":"hi"}'
out=$(printf '%s' "$NO_PATH_INPUT" | bash "$HOOK")
if [[ -z "$out" ]]; then
  printf '  ok   transcript_path field absent\n'
  PASS=$((PASS+1))
else
  printf '  FAIL transcript_path field absent (got %s)\n' "$out"
  FAIL=$((FAIL+1))
fi

# 10) Transcript ends mid-turn (no current user prompt yet), last turn edited → inject
f="$TMP/midturn-edit.jsonl"
{ user_prompt "first"; assistant_with_tools Read; user_prompt "second"; assistant_with_tools Edit; } > "$f"
run_case "$f" inject "Mid-turn transcript with Edit (no trailing prompt)"

# 11) Transcript ends mid-turn, last turn read-only → skip
f="$TMP/midturn-readonly.jsonl"
{ user_prompt "first"; assistant_with_tools Edit; user_prompt "second"; assistant_with_tools Read Bash; } > "$f"
run_case "$f" skip "Mid-turn transcript with read-only (no trailing prompt)"

# 12) Older turn edited, but the most recent (previous) turn was read-only → skip
f="$TMP/older-edit-not-last.jsonl"
{ user_prompt "first"; assistant_with_tools Edit; user_prompt "second"; assistant_with_tools Read; user_prompt "current"; } > "$f"
run_case "$f" skip "Edit in older turn but not the previous one"

# 13) Previous turn split across multiple assistant entries with tool_results between → inject
f="$TMP/split-turn.jsonl"
{
  user_prompt "first"
  assistant_with_tools Bash
  tool_result u_Bash
  assistant_with_tools Read
  tool_result u_Read
  assistant_with_tools Edit
  tool_result u_Edit
  user_prompt "current"
} > "$f"
run_case "$f" inject "Edit in split assistant turn (tool_results interleaved)"

# --- summary ------------------------------------------------------------------

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
