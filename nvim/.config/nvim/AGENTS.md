# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Structure

All config lives under `nvim/.config/nvim/` (stow target: `~/.config/nvim/`).

- `init.lua` — bootstraps lazy.nvim, loads `options`, `keybindings`, `z`, then calls `require('lazy').setup('plugins', ...)`
- `lua/options.lua` — vim options
- `lua/keybindings.lua` — global keymaps (leader = space, localleader = space)
- `lua/z.lua` — custom `:Z <query>` command wrapping zoxide for directory jumping
- `lua/plugins/` — each file returns a lazy.nvim plugin spec table; lazy auto-discovers all files here

## Plugin Architecture

Plugins use lazy.nvim's spec format. Each file in `lua/plugins/` is auto-loaded. Key plugins:

- **LSP** (`plugins/lsp.lua`): nvim-lspconfig + mason (auto-installs servers). Active servers: `gopls`, `pyright`, `rust_analyzer`, `lua_ls`. lua_ls workspace includes Hammerspoon annotations so `hs.*` globals don't produce diagnostics.
- **Completion** (`plugins/cmp.lua`): nvim-cmp with LSP source via cmp-nvim-lsp
- **Telescope** (`plugins/telescope.lua`): fuzzy finder with fzf-native; keymaps under `<leader>f`
- **Treesitter** (`plugins/treesitter.lua`): syntax/parsing
- **which-key** (`plugins/which_key.lua`): key hint UI

## Key Keymaps

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Git files |
| `<leader>fs` | Grep string |
| `<leader>fd` | Search diagnostics |
| `<leader>ss` | Save + source current lua file |
| `gd` / `gr` / `gI` | LSP goto definition/references/implementation |
| `<leader>rn` | LSP rename |
| `<leader>ca` | LSP code action |
| `K` / `<C-k>` | LSP hover / signature help |
| `[d` / `]d` | Prev/next diagnostic |

A `:Format` buffer-local command is registered by the LSP on_attach for each LSP-enabled buffer.

## Adding a New LSP Server

1. Add the server name to the `servers` table in `plugins/lsp.lua` with any settings
2. Add it to `ensure_installed` in mason-lspconfig opts
3. Mason will auto-install it on next Neovim start
