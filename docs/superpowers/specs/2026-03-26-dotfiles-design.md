# Dotfiles Design Spec

## Goal

Back up and sync personal config files using GNU Stow so they can be restored or used on another machine. The repo will be public, so secrets are excluded.

## Tool

GNU Stow — creates symlinks from `$HOME` to files in the repo. Each "package" is a top-level directory mirroring the path relative to `$HOME`.

## Packages

| Package    | Source files                                  |
|------------|-----------------------------------------------|
| zsh        | `.zshrc`, `.zshenv`, `.zprofile`              |
| git        | `.gitconfig`, `.editorconfig`                 |
| nvim       | `.config/nvim/` (entire tree)                 |
| zed        | `.config/zed/` (settings, keymap, etc.)       |
| ghostty    | `.config/ghostty/`                            |
| starship   | `.config/starship.toml`                       |
| gh         | `.config/gh/` (excluding `hosts.yml`)         |
| claude     | `.claude/CLAUDE.md`, `.claude/settings.json`  |

## Repo Structure

```
dotfiles/
├── zsh/
│   ├── .zshrc
│   ├── .zshenv
│   └── .zprofile
├── git/
│   ├── .gitconfig
│   └── .editorconfig
├── nvim/
│   └── .config/nvim/
│       └── (entire nvim config tree)
├── zed/
│   └── .config/zed/
│       └── (settings, keymap, etc.)
├── ghostty/
│   └── .config/ghostty/
│       └── config
├── starship/
│   └── .config/starship.toml
├── gh/
│   └── .config/gh/
│       └── config.yml
├── claude/
│   └── .claude/
│       ├── CLAUDE.md
│       └── settings.json
├── install.sh
├── .gitignore
└── README.md
```

## Install Script (`install.sh`)

A bash script that stows all packages:

```bash
#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

packages=(zsh git nvim zed ghostty starship gh claude)

for pkg in "${packages[@]}"; do
    echo "Stowing $pkg..."
    stow -v --target="$HOME" "$pkg"
done
```

- Idempotent — safe to run multiple times.
- Stow errors (rather than overwrites) if a target file exists and is not already a symlink, preventing accidental data loss.
- To uninstall a single package: `stow -D <pkg>`.

## .gitignore

Excludes secrets and generated state:

```
# Secrets
**/*.secret
**/*credentials*
**/*token*

# Claude runtime state
claude/.claude/history.jsonl
claude/.claude/sessions/
claude/.claude/projects/
claude/.claude/plugins/
claude/.claude/debug/
claude/.claude/cache/
claude/.claude/backups/
claude/.claude/file-history/
claude/.claude/session-env/
claude/.claude/shell-snapshots/
claude/.claude/paste-cache/
claude/.claude/plans/
claude/.claude/downloads/
claude/.claude/chrome/
claude/.claude/mcp-needs-auth-cache.json

# gh auth tokens
gh/.config/gh/hosts.yml
```

## Setup on a New Machine

1. `brew install stow`
2. `git clone <repo-url> ~/src/dotfiles`
3. `cd ~/src/dotfiles && ./install.sh`

## Sensitive Files (excluded from repo)

- `~/.ssh/config` — hostnames/IPs
- `~/.npmrc` — auth tokens
- `~/.config/gcloud/` — credentials
- `~/.config/gh/hosts.yml` — auth tokens
- `~/.claude/` runtime state (sessions, history, plugins, etc.)
