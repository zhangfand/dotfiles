---
name: dotfiles-discover-untracked
description: Find config in $HOME that the dotfiles repo does not track yet, and adopt what is worth keeping through a PR. Use when the user asks what is not tracked in dotfiles, to audit or scan dotfiles, or whether anything was forgotten. Reports first and changes nothing until the user picks.
---

# Discover untracked dotfiles

Goal end-state: the user has seen every untracked config file next to the ones dotfiles already manages, sorted into TRACK, SKIP and ASK, and the items they picked are in a PR against the dotfiles repo.

## Find candidates

`chezmoi unmanaged` lists what chezmoi does not manage. Look inside the directories that already hold managed files (`chezmoi managed` lists them), plus siblings of a managed dotfile at the top of `$HOME` (`~/.zsh*` next to `~/.zshrc`). Walking all of `$HOME` is noise.

## Classify

- **TRACK**: something the user wrote or chose, such as a theme, a keymap, a snippet, an alias file, a hook script, or a tool's settings file.
- **SKIP**: state, caches, logs, history, downloaded plugins, and anything matching the repo's `.gitignore`.
- **ASK**: anything that may be specific to one machine, or that you cannot place.

The repo is public, so anything holding a credential is SKIP whatever else it is.

## Report

Group the candidates by directory, one line each with a short reason. Then ask which TRACK and ASK items to adopt.

## Adopt

For each picked item, run `chezmoi add <path>`, then follow the dotfiles repo's CLAUDE.md to check and open the PR.
