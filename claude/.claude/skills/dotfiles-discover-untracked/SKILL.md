---
name: dotfiles-discover-untracked
description: Audit `~/src/dotfiles` for files in $HOME that the matching stow package mirrors but hasn't yet adopted. Walks each package's mirrored $HOME subtree, classifies untracked entries as TRACK (worth committing), SKIP (state/cache/secret), or ASK (ambiguous), and offers to move TRACK items into the package and re-stow. Use this skill whenever the user says things like "discover untracked", "audit dotfiles", "find untracked dotfiles", "what's not tracked in dotfiles", "scan dotfiles for new files", "anything I forgot to track", or any variant asking which files in their stowed config dirs haven't been adopted into the repo yet. Do not trigger for plain `git status` questions outside this dotfiles-audit context.
---

# Audit dotfiles for untracked content

`~/src/dotfiles` is a GNU Stow repo. Each package mirrors a subtree of `$HOME` — e.g. `ghostty/.config/ghostty/` mirrors `~/.config/ghostty/`. After stowing, those $HOME dirs contain a mix of:

- **Symlinks back into the repo** — tracked.
- **Real files/dirs** — either (a) something the user authored that *should* be moved into the package, or (b) runtime state the package shouldn't track.

This skill finds the latter and classifies them, then offers a path to adopt or ignore. It's read-only by default — never move files until the user confirms the TRACK list.

## Why this matters

Dotfiles drift. The user tweaks a theme, adds a snippet, installs a tool that drops a config — and these accrete in $HOME without ever making it into the stow package. Without periodic auditing, the repo stops being the source of truth and a fresh-machine install ends up incomplete. This skill makes the drift visible.

## Process

### 1. Read the package list from the source of truth

```bash
grep -E '^packages=' /Users/zhangfan/src/dotfiles/install.sh
```

The `packages=(…)` array is canonical. Don't hardcode it inline — the user adds packages over time. If the parse fails, ask the user before proceeding.

### 2. Walk each package's mirrored $HOME tree

A package `<pkg>` lives at `<repo>/<pkg>/` and its internal directory structure encodes the $HOME-relative paths it owns. The audit walk:

For each top-level entry inside `<repo>/<pkg>/`, identify the matching path in `$HOME` and classify the $HOME entry:

- **$HOME entry is a symlink resolving into `<repo>/<pkg>/`** — fully tracked at this level. Done with this branch.
- **$HOME entry is a real directory** (because the package stows individual children of it, like `~/.config/ghostty` containing both a symlinked `config` and a real subdir) — recurse. For each child of the $HOME dir, apply the same rule.
- **$HOME entry exists but isn't tracked** — candidate.
- **$HOME entry doesn't exist** — irrelevant; the user removed something the package still has.

To detect "symlink resolves into the repo", read the link target and check whether its absolute path lives under `<repo>/<pkg>/`. macOS `readlink` doesn't take `-f`, so use `readlink "$path"` and resolve manually, or `python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$path"`.

**Special case — packages that mirror $HOME root** (`zsh`, `git`): the package's top-level entries are individual dotfiles at $HOME root (`.zshrc`, `.gitconfig`). Walking all of $HOME would be absurd, so for these packages restrict the audit to *adjacent* dotfiles — siblings that look domain-relevant. For `zsh`, that's `~/.zsh*`, `~/.zprofile`, `~/.zshenv`. For `git`, that's `~/.git*` (excluding `.gitignore_global` if not used). When in doubt, ask the user which siblings to include.

### 3. Classify each candidate

| Bucket | What goes here |
|--------|----------------|
| **TRACK** | Files the user authored or curated. Themes, custom keybindings, snippet files, neovim user modules under `lua/`, custom shell functions/aliases, hook scripts, lockfiles that aid reproducibility (`lazy-lock.json`). |
| **SKIP** | Runtime state, caches, logs, downloaded plugins/packages, history files, session/auth tokens, anything matching the repo's existing `.gitignore` globs (`**/*.secret`, `**/*credentials*`, `**/*token*`). |
| **ASK** | Anything ambiguous — looks user-authored but might be machine-specific, or unfamiliar enough you can't tell. |

Default classifications:

| Path pattern | Default |
|---|---|
| `*.bak`, `*.swp`, `*.tmp`, `*~` | SKIP |
| `**/*.secret`, `**/*credentials*`, `**/*token*` | SKIP (gitignored) |
| `~/.zsh_history`, `~/.bash_history`, `~/.lesshst`, `~/.viminfo` | SKIP |
| `~/.config/nvim/lazy-lock.json` | TRACK (lockfile aids reproducibility) |
| `~/.local/share/nvim/`, `~/.cache/nvim/` | SKIP (state) |
| `~/.hammerspoon/Spoons/` | SKIP (already gitignored at repo level) |
| `~/.claude/projects/`, `~/.claude/todos/`, `~/.claude/statsig/` | SKIP (per-session state) |
| `~/.claude/hooks/`, `~/.claude/settings.json`, `~/.claude/CLAUDE.md` | TRACK |
| Plugin install dirs (anything that looks like a package manager dropped it) | SKIP |
| Themes, snippets, custom modules, user-authored scripts | TRACK |

The table is a starting point, not a rulebook. When you can't confidently place something, put it in ASK rather than guessing.

### 4. Present the report

Group by package, then by bucket. One line per item with a short rationale. Skip packages with zero candidates. Keep the whole report skimmable — no walls of text.

```
## ghostty
TRACK
- ~/.config/ghostty/themes/Forest Dusk          custom theme (user-authored palette)
SKIP
- ~/.config/ghostty/config.bak                  editor backup; matches *.bak
ASK
- ~/.config/ghostty/local.conf                  looks user-authored but may be machine-specific
```

After the report, offer three actions:

1. **Adopt TRACK items** — list them; let the user say "all" or pick a subset.
2. **Extend `.gitignore`** — if any SKIP pattern recurs across packages and isn't already covered, suggest the glob.
3. **Resolve ASK items** — talk through each one.

Wait for the user's decision. Do not move files unilaterally.

### 5. The move + re-stow flow

For each confirmed TRACK item at `$HOME/<rel>`:

```bash
mkdir -p /Users/zhangfan/src/dotfiles/<pkg>/<dirname-of-rel>
mv "$HOME/<rel>" "/Users/zhangfan/src/dotfiles/<pkg>/<rel>"
stow -v --target="$HOME" -d /Users/zhangfan/src/dotfiles <pkg>
```

This matches the pattern in `install.sh`. Stow's behavior:

- If `$HOME/<rel>`'s parent dir is itself a symlink to the package's matching dir, the file is now at the right path and the symlink already covers it — no further action.
- If the parent dir is a real $HOME dir (the package stows individual children), stow will create a per-file symlink inside it.
- If stow reports a conflict, investigate before forcing — usually it means the parent dir is split between real-dir and symlink-dir state and you need to think about restructuring.

Verify each move:

```bash
ls -la "$HOME/<rel>"            # should be a symlink into the repo
git -C /Users/zhangfan/src/dotfiles status   # new file shows as untracked-in-repo
```

### 6. Don't commit automatically

Show `git status` and let the user decide on the commit. The user's commit-message style is captured in their global CLAUDE.md (semantic prefixes: `feat:`, `fix:`, `chore:`, etc.); follow it if asked to commit.

## Constraints to respect

- **Read-only by default.** Mutate only after explicit confirmation of the TRACK list.
- **One package at a time when mutating.** Stow conflicts are easier to diagnose mid-flow than at the end.
- **Honor the existing `.gitignore`.** Read it first; if a candidate matches a glob already in it, that's an automatic SKIP — note the match in the rationale rather than rediscovering it.
- **Don't surface noise from `~/.DS_Store`, `.directory`, `__pycache__`, etc.** — these are universal SKIP and don't need a line in the report unless the user explicitly asks for everything.
