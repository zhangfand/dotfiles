# General Guidelines

- Use the latest stable version of the language unless specified otherwise.
- Use structured logging (e.g., JSON-formatted log entries with consistent fields like `timestamp`, `level`, `message`, `context`). Do not use print statements or unstructured string concatenation for logs.
- Separate diagnostic output from user-facing output:
  - **Diagnostic output** (for developers): use logging frameworks at appropriate levels (`debug`, `info`, `warn`, `error`). Write to stderr or log files.
  - **User-facing output**: use stdout, UI elements, or API responses. Keep messages clear, actionable, and free of internal details.
- When manually testing a binary during development, run with log level set to WARN or above. Only increase to DEBUG or INFO when more information is needed to diagnose an issue.
- When testing integration with external systems outside our control, consider implementing tools to create fixture data, and test code using the fixture data.
- Set up end-to-end testing (e.g. Playwright) before building any user-facing frontend, and take screenshots after each change to verify visually.
- Never expose internal IDs or raw database values to the frontend. Normalize all data at the API boundary — use human-readable strings instead of numeric codes, resolve internal IDs to display names, etc.
- When writing implementation plans, verify that specified libraries and tools are compatible with the project's runtime and package manager before including them.
- When spawning subprocesses, use `env_clear()` (or equivalent) and pass only explicitly needed env vars. Never inherit the full parent environment — it leaks secrets, git state, and other context that makes behavior non-reproducible across environments.
- Never swallow errors silently. If an operation can fail, propagate the error to the caller. If there is a specific business reason to handle an error gracefully (e.g., fallback behavior, degraded mode), document the reason inline and emit telemetry (warning log or metric counter) so the error remains observable even when it's expected.
- Never modify database state directly (raw SQL, REPL, etc.) during development or testing — always go through the application's CLI or API. Direct writes bypass validation and event sourcing, causing inconsistent state. If the tooling doesn't support what you need, that's a signal to add the missing command. Exception: deliberately simulating inconsistency scenarios in tests.
- When designing systems, explicitly enumerate non-happy-path states for each component — don't wait to discover them in production. For each, ask: "does this violate a system invariant, or is it a state that can legitimately occur?" Invariant violations are bugs (fail loudly). Legitimate states get a designed handler (self-heal, ignore, or degrade). If you can't tell which it is, that's a sign the invariants aren't defined clearly enough.

# Response Style

- Lead with the headline answer or recommendation. Skip preamble.
- Default to high-level. Do not enumerate exhaustive options, large tables, or multi-section breakdowns unless asked.
- One paragraph beats five bullets that say the same thing.
- Cite file paths or `file:line` only when the user is about to act on them — not as decoration.
- For brainstorm requests, list options one line each, not a paragraph each.
- Offer to expand on specific parts rather than dumping everything upfront. The user can always ask for depth.

## Design summaries: pyramid structure, observable-behavior framing
When summarizing a design or implementation, structure the response as three short sections:

Gist — the observable contract. What holds after success? What holds after failure? Frame in terms of what the user would see, run, or hit, not internal structure.
Shape — the key abstractions and the concrete operations that produce the contract. Name the operations the user would care about existing (build, dependency install, migration, validation, commit, etc.) even when staying high-level. Omitting them hides whether you considered them.
Worth a closer look — the one or two design decisions that aren't obvious: asymmetries, non-rollback steps, linearization points, places where the success path and observable state can diverge. This is where mechanics earn their place — mention atomic-rename, staging dirs, or stage ordering only when they're the answer to "how is that observable property guaranteed?" or when the choice itself is the interesting part.

Don't enumerate pipelines stage by stage. Don't draw ASCII state machines unless the state space is genuinely the design. Don't pad with tables where most rows say the same thing. Trust the reader to know standard patterns (atomic rename, content-addressed caching, supervision trees) by name; spend tokens on what's specific to this design.
Length target: roughly three paragraphs. If a section wants to grow past that, it's probably mechanics leaking into shape — push them down to "closer look" or cut them.

# Debugging

- When debugging, run the failing command or test yourself and analyze the output directly. Do not ask the user to reproduce the issue and relay symptoms back to you.

# Git

- Use semantic commit messages (e.g., `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).

# Pull Requests

Default PR description template, in this order:

1. `## What this PR does` — open with the *problem* (what was missing, broken, or accreted), not with what changed. Narrative paragraph(s), then optionally a numbered "this PR ships:" list of 3–5 high-level shifts. Not a bulleted "summary of changes".
2. `## Architecture` — ASCII diagram of the data/control flow, followed by a short list of load-bearing concepts surfaced as code with concrete identifiers (function names, flags, fields).
3. `## How to use it (dev)` — real shell commands, real env vars, real URLs. Use a table when there's a matrix of paths to exercise.
4. `## Where to look` — annotated file pointers, one line each: backticked path, then a short description of what's inside.
5. Optional domain section — `## Prod contract`, `## Channel coverage`, etc. — anything capturing a contract or matrix specific to the change.
6. `## Test plan` — checklist with `[x]` for verified, `[ ]` for remaining (often manual steps).
7. `## Not in this PR` — bulleted explicit deferrals; each item names the deferred thing and a one-clause reason or pointer.

Tone:
- Concrete identifiers beat hand-waving. "`enqueueSessionTask` drains any active stream and emits `done`" beats "manages stream lifecycle".
- Tables when there's a matrix (channels, env vars, paths).
- Terse. No throat-clearing.

End the body with a trailing line: `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

Canonical example: PR #51 of `amantru/rome-internal` (`gh pr view 51 --repo amantru/rome-internal --json title,body`). Mirror its shape.

# Project Scaffolding

- When scaffolding a new project, always set up pre-commit hooks (linting, formatting, tests) and CI in the first commit. Never defer quality gates to a later task.

# Testing

- Every user-facing behavior must have a test that verifies the observable property, not just that the code runs. If the output is "sorted by date", the test must assert ordering. If the output is "filtered to pending", the test must assert no non-pending items appear.
- TDD applies to all code, not just planned tasks. Ad-hoc features, bug fixes, and CLI commands follow the same discipline: write a failing test first.
- When adding a feature interactively, write the test before claiming it works. "I verified manually" is not sufficient.

# Python

- Use `uv` to manage virtual environments and packages. Use `uv init`, `uv add`, `uv run`. Do not use pip, poetry, or conda.

# TypeScript / JavaScript

- Use `bun` as the package manager and runtime. Use `bun install`, `bun add`, `bun run`, `bun test`. Do not use npm, yarn, or pnpm.
