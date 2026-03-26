# Dotfiles Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up a GNU Stow-based dotfiles repo that symlinks shell, editor, terminal, and CLI configs from `~/src/dotfiles` to their expected locations in `$HOME`.

**Architecture:** Each tool's config lives in its own "package" directory mirroring the home directory structure. `stow <pkg>` creates symlinks. An `install.sh` script stows all packages. Secrets are `.gitignore`d for a public repo.

**Tech Stack:** GNU Stow, Bash, Git

---

### Task 1: Initialize repo with .gitignore and install.sh

**Files:**
- Create: `.gitignore`
- Create: `install.sh`

- [ ] **Step 1: Create .gitignore**

```gitignore
# Secrets
**/*.secret
**/*credentials*
**/*token*

# OS
.DS_Store

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

# Zed generated state
zed/.config/zed/.tmp*
zed/.config/zed/conversations/
zed/.config/zed/embeddings/
zed/.config/zed/prompts/
zed/.config/zed/settings_backup.json

# Ghostty backup files
ghostty/.config/ghostty/*.bak

# Nvim plugin lock (changes frequently, machine-specific)
nvim/.config/nvim/lazy-lock.json
```

- [ ] **Step 2: Create install.sh**

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

echo "Done. All packages stowed."
```

- [ ] **Step 3: Make install.sh executable and commit**

```bash
chmod +x install.sh
git add .gitignore install.sh
git commit -m "Add .gitignore and install.sh"
```

---

### Task 2: Add zsh package

**Files:**
- Create: `zsh/.zshrc` (copy from `~/.zshrc`)
- Create: `zsh/.zshenv` (copy from `~/.zshenv`)
- Create: `zsh/.zprofile` (copy from `~/.zprofile`)

- [ ] **Step 1: Create package directory and copy files**

```bash
mkdir -p zsh
cp ~/.zshrc zsh/.zshrc
cp ~/.zshenv zsh/.zshenv
cp ~/.zprofile zsh/.zprofile
```

- [ ] **Step 2: Review copied files for secrets**

Read each file. Remove or redact any tokens, passwords, or private hostnames. These are shell configs so typically safe, but verify.

- [ ] **Step 3: Replace originals with symlinks**

```bash
rm ~/.zshrc ~/.zshenv ~/.zprofile
cd ~/src/dotfiles && stow -v --target="$HOME" zsh
```

- [ ] **Step 4: Verify symlinks work**

```bash
ls -la ~/.zshrc ~/.zshenv ~/.zprofile
# Each should show -> /Users/zhangfan/src/dotfiles/zsh/.<filename>
source ~/.zshrc
# Should load without errors
```

- [ ] **Step 5: Commit**

```bash
git add zsh/
git commit -m "Add zsh package"
```

---

### Task 3: Add git package

**Files:**
- Create: `git/.gitconfig` (copy from `~/.gitconfig`)
- Create: `git/.editorconfig` (copy from `~/.editorconfig`)

- [ ] **Step 1: Create package directory and copy files**

```bash
mkdir -p git
cp ~/.gitconfig git/.gitconfig
cp ~/.editorconfig git/.editorconfig
```

- [ ] **Step 2: Review for secrets**

Check `.gitconfig` for any tokens (e.g., GitHub credential helpers storing plaintext tokens). Remove if found.

- [ ] **Step 3: Replace originals with symlinks**

```bash
rm ~/.gitconfig ~/.editorconfig
cd ~/src/dotfiles && stow -v --target="$HOME" git
```

- [ ] **Step 4: Verify**

```bash
ls -la ~/.gitconfig ~/.editorconfig
git config --list
# Should show your normal git config
```

- [ ] **Step 5: Commit**

```bash
git add git/
git commit -m "Add git package"
```

---

### Task 4: Add nvim package

**Files:**
- Create: `nvim/.config/nvim/init.lua` (copy from `~/.config/nvim/init.lua`)
- Create: `nvim/.config/nvim/.stylua.toml` (copy from `~/.config/nvim/.stylua.toml`)
- Create: `nvim/.config/nvim/lua/` (copy entire tree from `~/.config/nvim/lua/`)

Note: `lazy-lock.json` is excluded via `.gitignore` — it's machine-specific and changes frequently.

- [ ] **Step 1: Create package directory and copy files**

```bash
mkdir -p nvim/.config/nvim
cp ~/.config/nvim/init.lua nvim/.config/nvim/init.lua
cp ~/.config/nvim/.stylua.toml nvim/.config/nvim/.stylua.toml
cp -R ~/.config/nvim/lua nvim/.config/nvim/lua
```

- [ ] **Step 2: Review for secrets**

Skim `init.lua` and plugin configs for hardcoded API keys or tokens.

- [ ] **Step 3: Replace originals with symlinks**

```bash
rm -rf ~/.config/nvim
cd ~/src/dotfiles && stow -v --target="$HOME" nvim
```

- [ ] **Step 4: Verify**

```bash
ls -la ~/.config/nvim
# Should be a symlink -> /Users/zhangfan/src/dotfiles/nvim/.config/nvim
nvim --version
# Open nvim briefly to confirm plugins load
```

- [ ] **Step 5: Commit**

```bash
git add nvim/
git commit -m "Add nvim package"
```

---

### Task 5: Add zed package

**Files:**
- Create: `zed/.config/zed/settings.json` (copy from `~/.config/zed/settings.json`)

Note: Only tracking `settings.json`. The `.tmp*`, `conversations/`, `embeddings/`, `prompts/`, and `settings_backup.json` are excluded via `.gitignore` as generated state. The `themes/` directory is empty.

- [ ] **Step 1: Create package directory and copy settings**

```bash
mkdir -p zed/.config/zed
cp ~/.config/zed/settings.json zed/.config/zed/settings.json
```

- [ ] **Step 2: Review for secrets**

Check `settings.json` for any API keys or tokens (e.g., copilot tokens, AI provider keys).

- [ ] **Step 3: Remove original and stow**

Stow will create a symlink for the `settings.json` file. Since we're not tracking the whole directory, we need to be specific:

```bash
rm ~/.config/zed/settings.json
cd ~/src/dotfiles && stow -v --target="$HOME" zed
```

- [ ] **Step 4: Verify**

```bash
ls -la ~/.config/zed/settings.json
# Should show symlink -> /Users/zhangfan/src/dotfiles/zed/.config/zed/settings.json
```

- [ ] **Step 5: Commit**

```bash
git add zed/
git commit -m "Add zed package"
```

---

### Task 6: Add ghostty package

**Files:**
- Create: `ghostty/.config/ghostty/config` (copy from `~/.config/ghostty/config`)

Note: `.bak` files excluded via `.gitignore`.

- [ ] **Step 1: Create package directory and copy config**

```bash
mkdir -p ghostty/.config/ghostty
cp ~/.config/ghostty/config ghostty/.config/ghostty/config
```

- [ ] **Step 2: Review for secrets**

Ghostty config is typically just appearance/keybinding settings. Verify no secrets.

- [ ] **Step 3: Replace original with symlink**

```bash
rm ~/.config/ghostty/config
cd ~/src/dotfiles && stow -v --target="$HOME" ghostty
```

- [ ] **Step 4: Verify**

```bash
ls -la ~/.config/ghostty/config
# Should show symlink
```

- [ ] **Step 5: Commit**

```bash
git add ghostty/
git commit -m "Add ghostty package"
```

---

### Task 7: Add starship package

**Files:**
- Create: `starship/.config/starship.toml` (copy from `~/.config/starship.toml`)

- [ ] **Step 1: Create package directory and copy config**

```bash
mkdir -p starship/.config
cp ~/.config/starship.toml starship/.config/starship.toml
```

- [ ] **Step 2: Replace original with symlink**

```bash
rm ~/.config/starship.toml
cd ~/src/dotfiles && stow -v --target="$HOME" starship
```

- [ ] **Step 3: Verify**

```bash
ls -la ~/.config/starship.toml
# Should show symlink
starship prompt
# Should render without errors
```

- [ ] **Step 4: Commit**

```bash
git add starship/
git commit -m "Add starship package"
```

---

### Task 8: Add gh package

**Files:**
- Create: `gh/.config/gh/config.yml` (copy from `~/.config/gh/config.yml`)

Note: `hosts.yml` contains auth tokens and is excluded via `.gitignore`.

- [ ] **Step 1: Create package directory and copy config**

```bash
mkdir -p gh/.config/gh
cp ~/.config/gh/config.yml gh/.config/gh/config.yml
```

- [ ] **Step 2: Review for secrets**

`config.yml` should only have preferences (editor, protocol, etc.). Verify no tokens — those live in `hosts.yml` which is gitignored.

- [ ] **Step 3: Replace original with symlink**

```bash
rm ~/.config/gh/config.yml
cd ~/src/dotfiles && stow -v --target="$HOME" gh
```

- [ ] **Step 4: Verify**

```bash
ls -la ~/.config/gh/config.yml
# Should show symlink
gh auth status
# Should still be authenticated (hosts.yml untouched)
```

- [ ] **Step 5: Commit**

```bash
git add gh/
git commit -m "Add gh package"
```

---

### Task 9: Add claude package

**Files:**
- Create: `claude/.claude/CLAUDE.md` (copy from `~/.claude/CLAUDE.md`)
- Create: `claude/.claude/settings.json` (copy from `~/.claude/settings.json`)

Note: All runtime state (history, sessions, plugins, projects, etc.) is excluded via `.gitignore`.

- [ ] **Step 1: Create package directory and copy files**

```bash
mkdir -p claude/.claude
cp ~/.claude/CLAUDE.md claude/.claude/CLAUDE.md
cp ~/.claude/settings.json claude/.claude/settings.json
```

- [ ] **Step 2: Review for secrets**

Check `settings.json` for any API keys or tokens. `CLAUDE.md` is user instructions — typically safe.

- [ ] **Step 3: Replace originals with symlinks**

```bash
rm ~/.claude/CLAUDE.md ~/.claude/settings.json
cd ~/src/dotfiles && stow -v --target="$HOME" claude
```

- [ ] **Step 4: Verify**

```bash
ls -la ~/.claude/CLAUDE.md ~/.claude/settings.json
# Both should show symlinks
```

- [ ] **Step 5: Commit**

```bash
git add claude/
git commit -m "Add claude package"
```

---

### Task 10: Add README and final verification

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create README.md**

```markdown
# dotfiles

Personal config files managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package  | What it manages                    |
|----------|------------------------------------|
| zsh      | `.zshrc`, `.zshenv`, `.zprofile`   |
| git      | `.gitconfig`, `.editorconfig`      |
| nvim     | Neovim config                      |
| zed      | Zed editor settings                |
| ghostty  | Ghostty terminal config            |
| starship | Starship prompt config             |
| gh       | GitHub CLI config                  |
| claude   | Claude Code settings               |

## Install

```bash
brew install stow
git clone <repo-url> ~/src/dotfiles
cd ~/src/dotfiles
./install.sh
```

## Usage

Stow a single package:

```bash
stow -v --target="$HOME" <package>
```

Unstow a package:

```bash
stow -D --target="$HOME" <package>
```
```

- [ ] **Step 2: Run full verification**

```bash
# Verify all symlinks are in place
for f in ~/.zshrc ~/.zshenv ~/.zprofile ~/.gitconfig ~/.editorconfig \
         ~/.config/nvim ~/.config/zed/settings.json ~/.config/ghostty/config \
         ~/.config/starship.toml ~/.config/gh/config.yml \
         ~/.claude/CLAUDE.md ~/.claude/settings.json; do
    if [ -L "$f" ]; then
        echo "OK: $f -> $(readlink "$f")"
    else
        echo "MISSING: $f is not a symlink"
    fi
done
```

All should show `OK` with paths pointing into `~/src/dotfiles/`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Add README"
```
