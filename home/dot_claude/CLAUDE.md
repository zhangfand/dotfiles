# General Guidelines

- Use the latest stable version of the language unless specified otherwise.
- Separate diagnostic output from user-facing output:
  - **Diagnostic output** (for developers): use logging frameworks at appropriate levels (`debug`, `info`, `warn`, `error`). Write to stderr or log files.
  - **User-facing output**: use stdout, UI elements, or API responses. Keep messages clear, actionable, and free of internal details.
- When manually testing a binary during development, run with log level set to WARN or above. Only increase to DEBUG or INFO when more information is needed to diagnose an issue.
- When testing integration with external systems outside our control, consider implementing tools to create fixture data, and test code using the fixture data.
- Never expose internal IDs or raw database values to the frontend. Normalize all data at the API boundary — use human-readable strings instead of numeric codes, resolve internal IDs to display names, etc.
- When writing implementation plans, verify that specified libraries and tools are compatible with the project's runtime and package manager before including them.
- When spawning subprocesses, use `env_clear()` (or equivalent) and pass only explicitly needed env vars. Never inherit the full parent environment — it leaks secrets, git state, and other context that makes behavior non-reproducible across environments.
- When designing systems, explicitly enumerate non-happy-path states for each component — don't wait to discover them in production. For each, ask: "does this violate a system invariant, or is it a state that can legitimately occur?" Invariant violations are bugs (fail loudly). Legitimate states get a designed handler (self-heal, ignore, or degrade). If you can't tell which it is, that's a sign the invariants aren't defined clearly enough.

# Machine setup

- When changing this machine's setup (shell, git, editor, Claude Code or other tool config in `$HOME`), change it in the dotfiles repo at `$(chezmoi source-path)/..` and follow that repo's AGENTS.md. An edit made only in `$HOME` stays on this machine.

# Scope & Simplicity

**Prefer the simplest technical approach that delivers the goal — the 20% of effort that captures 80% of the value.** Don't reach for the most general, most extensible, most "complete" design when a narrow, direct one solves the actual problem in front of you. Indicators you've overshot: speculative abstractions for a second caller that doesn't exist yet, config knobs nobody asked for, new layers that exist only to be "future-proof", handlers for edge cases the spec never mentioned. If the simpler version is wrong, the user will tell you what's missing — and you'll add it then, with a concrete reason. Default to under-building.

**Before adding new code, ask whether existing code can be refactored or repurposed to do the job.** New files, new modules, new abstractions, new dependencies all carry ongoing cost — they expand the surface area of the codebase and create more for future readers (including you) to hold in their head. A small refactor to an existing function, a parameter added to an existing entry point, or a new caller of an existing helper is almost always preferable to standing up a parallel path. When proposing changes, lead with "can this live in `<existing thing>`?" before "let's add a new `<thing>`". Only justify net-new code when reuse genuinely doesn't fit — say so explicitly and explain why.

**Don't grow interface surface area by reflex — and especially not via optional fields.** Each new parameter, flag, or config knob is a control gate: future callers have to decide what to pass, future readers have to learn what it does, and every untested combination is a latent bug. Default to *not* adding the knob; let the caller specify the behavior directly, or pick a single sensible behavior and commit to it. If a new control truly must exist, default to making it **required** — explicit at every callsite — unless you can name a concrete reason it should be optional (e.g. a real backward-compatibility constraint with external consumers). "Optional makes tests / the common case shorter" is not a sufficient reason — optional fields with default values hide whether callers thought about the choice. When you're about to change an interface, zoom out first: list everything the module / class / function already exposes, and ask whether the new capability can be expressed by **generalizing an existing entry point** instead of adding another one. Adding a new method when an existing one could absorb the case (with a slightly broader type, a richer return value, or a more general parameter) is usually the wrong trade. Caveat on "generalize": this means coherently widening the input space of an entry point that's already doing the same kind of work. If you'd have to branch inside the function on the input variant and run substantively different logic per branch, that's not generalization — it's two entry points wearing one signature, and two separate functions are clearer.

# Comments

If the repo has its own comments rulebook, follow it instead of this section (rome-internal: `docs/authoring/comments.md`).

- A comment states only what the code cannot: the contract a caller relies on, the why behind a non-obvious choice or a deviation from common practice, and non-trivial concurrency design (lock order, what a lock guards, why an unsynchronized access is safe).
- Inside functions, comments are exceptions. Never restate the code or explain standard patterns (`// loop through items`).
- Comments describe the code as it is now, for a reader who never saw a previous version: no diff narration ("removed X", "used to be Z"), no ticket/PR provenance ("added for issue #1234") — git history owns the past.
- At module level, link the canonical doc instead of restating it.

# Testing

**Default to black-box behavioral tests.** Drive the code through its public surface (HTTP endpoint, CLI invocation, exported function, message sent in over a channel) and assert on what an external observer would see — response body, exit code, DB row, emitted event, file on disk. Avoid tests that import internal helpers, monkeypatch private state, or assert call counts on mocks. Three reasons this matters:

1. **Forces you to name the external semantics.** Writing a black-box test makes you state, in code, what the feature is *supposed to do* from the outside. Gaps in your understanding surface immediately — before the implementation locks in the wrong contract.
2. **Covers the actual user surface.** White-box tests verify code that happens to exist; black-box tests verify behavior the user depends on. The latter survives refactors and catches regressions the former can't see.
3. **Surfaces production-code smells.** If a black-box test is hard to write — too many collaborators to wire up, too many global singletons, no seam for fixture data, no way to observe the result — that's a signal the production code is poorly organized. Treat the friction as feedback and refactor for testability, not as license to drop down into white-box mocking. The right refactor here almost always means making existing dependencies *explicit* — DI, required constructor/function parameters, returning values instead of mutating hidden state — not adding a new abstraction layer (interface, factory, adapter) on top. If you find yourself reaching for a new layer "to make it testable", stop: the simplicity rules above still apply, and that layer is usually a sign you haven't found the real seam yet.

**BDD is the preferred mode for new behavior — specify the behavior, then implement.** Before writing code, state the behavior as a concrete scenario from the outside: *given* some starting state, *when* the user does X, *then* the observable result is Y. Capture that scenario as a black-box test and watch it fail for the right reason before implementing. This applies to ad-hoc work too, not just planned tasks.

The unit of work is **a behavior the user can name**, not a function or class. This has two consequences:

- **Name tests after the behavior they pin down, never after the code they happen to exercise.** `returns 404 when the order is already shipped` is a behavior; `test_handleRequest` is an implementation detail wearing a test's clothes. If you can't name the test without referencing an internal method, you haven't found the behavior yet.
- **Assert on the observable outcome, not the steps taken to reach it.** Check the response, the persisted row, the emitted event — not which collaborators were called, in what order, how many times. A test that breaks when you refactor *without changing behavior* is testing the wrong thing; delete or rewrite it.

If you can't phrase the scenario before coding, that gap is the most important thing to close — don't paper over it by writing the implementation first and a test that merely re-states whatever the code happened to do.

When black-box isn't feasible (genuinely pure logic with no external surface, or an external system that truly can't be faked), say so explicitly and explain why before reaching for mocks.

# Validation & Contracts

**A validator must accept exactly what every downstream consumer can faithfully handle — no more.** Checking that input is well-formed is not the bar; the bar is whether the layers behind the validator can actually represent and act on it correctly. If a downstream step silently coerces, truncates, or misinterprets a well-formed input (e.g. it ignores a field, falls back to a default, or maps the value to something subtly different), the validator must reject that input — or the consumer must be extended first. Three failure modes to check every time you write or change a validator: (1) **validate field *combinations*, not fields independently** — each field can be individually legal while the pair is impossible or unsupported; (2) **validate *before* persisting or acting, never after** — don't write state and then validate, because a late throw leaves corrupt state behind that the next read trips over; (3) **when the same rule must hold at more than one entry point** (an action, an HTTP route, a confirm/preview path), extract one shared validator and call it from all of them — a subset reimplemented per path is how some callers stay permissive after you "fixed" it. State the rejection cases as a BDD table first: for each class the consumer can't faithfully handle, a black-box test that the validator rejects it (this is the natural rejection-table companion to the behavioral tests above).

**Every surface that advertises behavior is a contract — update all of them in the same diff that changes the behavior.** Public types (`.d.ts`), SDK signatures, doc/spec claims, agent/LLM prompts, and code examples are all contracts a caller will read and trust. When you change what the code actually accepts or does, the matching change to every such surface ships in the *same commit* — not a follow-up. Concretely: making a field required means no published type may still say it's optional; a doc claim ("embedded surfaces inherit the host theme") must be backed by code in this diff or be downgraded to explicitly aspirational; an agent prompt must not instruct the user toward a control or capability that isn't present in this diff. The failure mode this prevents is a caller who reads the contract, complies with it exactly, compiles clean, and then breaks at runtime — the worst kind of bug to diagnose because the code and its stated contract disagree.

# Response Style

- Cite file paths or `file:line` only when the user is about to act on them — not as decoration.
- For brainstorm requests, list options one line each, not a paragraph each.
- Skip the philosophy, meta-analysis, and unsolicited evaluations. Address my problem directly and concisely. Provide a concrete, actionable answer to the exact question asked without any conversational padding, qualifications, or tangential inquiries into intent.

## Default to high-level; details on request

By default — including when discussing technical problems — convey the high-level idea in concise terms. State the conclusion, the trade-off, or the shape of the approach; don't unpack the implementation. Skip code walk-throughs, file/line tours, step-by-step mechanics, and exhaustive option dumps unless they're the answer to the actual question. Surface those technical details only when the user explicitly asks for a deep dive (e.g. "go deeper", "show me the code", "walk me through it", "how exactly"). When in doubt, give the headline and offer to go deeper rather than front-loading the detail.

## Write every response under the repo writing rules

Apply the rules in rome-internal's `docs/authoring/WRITING.md` to all prose, in that repo and outside it. The load-bearing ones:

- Use the industry-standard term when one exists. A coined term earns admission only with a one-line separation from its nearest industry near-miss.
- One name per thing, one meaning per word.
- Use the plain word over the fancy synonym: *start* not *initiate*, *use* not *leverage*, *make sure* not *ensure*, *get* not *obtain*, *also* not *furthermore*.
- Cut marketing adjectives: *seamless*, *robust*, *powerful*, *effortless*.
- Active voice, a real verb for the action, no stacked auxiliaries.
- Split any descriptive sentence over 25 words. No contractions. No semicolons.
- State the condition before the command: "If the token is expired, refresh it."
- No preamble, no summary, no closing remarks. Start with the content and stop when the content ends.
- Write steps as a numbered list in the imperative mood, one action per item.
- If a concept has a canonical home, link to it instead of re-explaining it.

# Memory Hub (Mirror)

Mirror is a local memory hub running on `http://127.0.0.1:7878`, exposed to Claude Code as MCP tools `mcp__starshard__*` (configured in `~/.claude/mcp.json` as the `starshard` server) and CLI `starshard`. It is the durable, agent-shared store for memories.

**Capture is automatic — do not manually call `create_memory` for auto-memory.** When you write or edit an auto-memory file under `~/.claude/projects/.../memory/*.md` via the normal auto-memory rules (see the "auto memory" section), a PostToolUse hook (`~/.claude/hooks/mirror-import.py` → `starshard import --source <path>`) ingests that single file into Mirror. The mapping of auto-memory `type:` frontmatter to Mirror records lives in `starshard`'s `cmd_import` — never re-encode it in your own MCP calls. If a memory will also land as a local file, let the hook do it.

You may still call the Mirror MCP tools directly for memories that have **no corresponding local file** (e.g. one-off captures from a tool result you want to remember without producing an auto-memory).

**Retrieval — search Mirror when the user references past context.** A SessionStart hook injects a compact briefing automatically, so standing instructions / pending tasks / preferences are already loaded. *Beyond* that, when the user mentions any prior work, person, project, or decision that you don't already have in-context, call `mcp__starshard__search_memories` before answering — do not silently fall back to "I don't have that context." If the search returns nothing, say so explicitly so the user can decide whether to re-explain or expect a memory to exist.

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

For stacked PR workflow (child PRs based on other open PRs, restack discipline, metadata conventions), see `~/.claude/docs/stacked-prs.md`.
