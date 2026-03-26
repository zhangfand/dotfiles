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

# Git

- Use semantic commit messages (e.g., `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).

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
