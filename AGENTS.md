# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A GNU Stow-based dotfiles repo. Each top-level directory is a "stow package" that mirrors `$HOME` structure. Running `stow <pkg>` symlinks the package's files into `$HOME`.

## Commands

```bash
# Install all packages (idempotent)
./install.sh

# Stow/unstow a single package
stow -v --target="$HOME" <package>
stow -D --target="$HOME" <package>
```

## Packages

`brew`, `claude`, `gh`, `ghostty`, `git`, `hammerspoon`, `nvim`, `starship`, `zed`, `zsh`

The canonical list is the `packages` array in `install.sh`.

## Architecture

- Each package directory's internal structure mirrors `$HOME`. For example, `nvim/.config/nvim/init.lua` symlinks to `~/.config/nvim/init.lua`.
- Secrets and runtime state are excluded via `.gitignore` glob patterns (`**/*.secret`, `**/*credentials*`, `**/*token*`).
- When adding a new package: create a directory mirroring the `$HOME` path, add it to the `packages` array in `install.sh`, update `.gitignore` to exclude any generated state or secrets, and update the table in `README.md`.

## Neovim Config

Lua-based config using `lazy.nvim` plugin manager. Entry point is `nvim/.config/nvim/init.lua` which loads modules from `lua/`:
- `options.lua` — vim options
- `keybindings.lua` — key mappings (leader is space)
- `z.lua` — personal utilities
- `plugins/` — lazy.nvim plugin specs (LSP, Telescope, Treesitter, completion, which-key)

## Hammerspoon Config

Entry point is `hammerspoon/.hammerspoon/init.lua`. Window management via yabai integration in `yabai.lua`.
