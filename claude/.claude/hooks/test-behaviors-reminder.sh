#!/usr/bin/env bash
# UserPromptSubmit hook: inject a directive reminding the model to test
# behaviors implied by the user's request, prefer scenario docs as the
# source of truth, and end the turn with an honest test-coverage report.
#
# To avoid noise on every interaction, the directive is only injected when
# the previous assistant turn actually modified code (Edit/Write/MultiEdit/
# NotebookEdit). Pure exploration / Q&A / read-only turns pass through
# silently.
set -euo pipefail

INPUT=$(cat)
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // ""')

# Returns 0 (inject) iff the most recent assistant turn used a code-modifying
# tool. Real user prompts have a string `.message.content`; tool-result user
# entries have an array, so we use that to find the turn boundaries.
should_inject() {
  [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]] || return 1
  local result
  result=$(jq -s '
    def code_tools: ["Edit","Write","MultiEdit","NotebookEdit"];
    def is_user_prompt: .type == "user" and (.message.content | type) == "string";
    [range(0; length) as $i | select(.[$i] | is_user_prompt) | $i] as $idxs
    | ($idxs | length) as $n
    | (if (length > 0 and (.[-1] | is_user_prompt))
         then if $n < 2 then null
              else { start: ($idxs[-2] + 1), end: $idxs[-1] }
              end
         else if $n < 1 then { start: 0, end: length }
              else { start: ($idxs[-1] + 1), end: length }
              end
       end) as $window
    | if $window == null then false
      else .[$window.start:$window.end]
        | [.[] | select(.type == "assistant") | .message.content[]?
                 | select(.type == "tool_use") | .name]
        | any(. as $name | code_tools | index($name))
      end
  ' "$TRANSCRIPT" 2>/dev/null) || return 1
  [[ "$result" == "true" ]]
}

if ! should_inject; then
  exit 0
fi

read -r -d '' DIRECTIVE <<'EOF' || true
TESTING & COVERAGE DIRECTIVE

If this turn implements a behavior, feature, or bug fix, you MUST verify it with tests before reporting completion. "I ran it manually" is not sufficient.

1. Source scenarios from docs first. Look in scenarios/, docs/scenarios/, tests/scenarios/, spec/, or files matching *scenarios*.md / *behavior*.md / *.feature. If present, treat them as the canonical list of behaviors to cover and map your tests to them by name.

2. If no scenario docs exist, derive scenarios from the user's request before writing code. Enumerate them as a short list (happy path + each named edge case implied by the ask) so the user can correct the framing early.

3. Write tests that assert OBSERVABLE properties — not just that the code runs. If the spec says "sorted by date", assert ordering. If it says "only pending items", assert non-pending items are absent.

4. End the turn with a "Test Coverage Report" section containing exactly these three parts:
   - Behaviors tested: bullet list, one line per scenario, naming the property verified (not just "tested function X").
   - Test doubles used: each mock/stub/fake/in-memory replacement, what real component it replaced, and a justification for the swap (e.g., "external API — would require live credentials", "system clock — needed determinism", "network egress — flaky in CI"). If a test double bypasses something the test should ideally exercise (e.g., mocked DB instead of the real migration path), call it out as a coverage gap, not just a tradeoff.
   - Real coverage assessment: one sentence on what these tests actually prove vs. what they don't, so the user can judge whether more integration-level coverage is needed.

Skip this directive only if the turn is pure exploration, a question, a no-behavior-change refactor, or pure documentation. When skipping, do not mention this directive in your reply.
EOF

jq -nc --arg ctx "$DIRECTIVE" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'
