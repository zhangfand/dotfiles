# dotfiles

zhangfan's machine setup for macOS and Linux, managed with [chezmoi](https://www.chezmoi.io/). Agents make every change, and zhangfan reads them as PRs. `home/` is the chezmoi source directory (set by `.chezmoiroot`) and mirrors `$HOME`. Each machine keeps its clone at `~/.local/share/chezmoi`, and `~/.local/bin/dotfiles-update` pulls `main` into it every hour. A merged PR reaches every machine within the hour.

## Playbook

- When changing any file, open a PR against `main` and leave the merge to zhangfan. Every merged change reaches every machine within the hour.
- Before pushing, run `scripts/check`. It installs the repo into an empty `$HOME` and fails on a shell error, broken JSON, or a secret.
- When adding a file from `$HOME`, run `chezmoi add <path>` so it gets the source name, then check that the file holds no secret.
- When a setting differs between macOS and Linux, branch inside the file where its language can (`[[ -d /opt/homebrew ]]` in zsh). Use a chezmoi template (`.tmpl`) only where it cannot, or an entry in `home/.chezmoiignore` for a file one OS does not need.
- When a SessionStart hook reports this machine's dotfiles differ from GitHub, commit the change on a branch in the clone, open a PR, then `git checkout main`. The updater skips a clone that is off `main` or has edits.
- When asked which files in `$HOME` are not tracked yet, use the `dotfiles-discover-untracked` skill.

## Traps

**Source names are not target names.** `home/dot_zshrc` is `~/.zshrc`, and `executable_`, `private_` and `.tmpl` change how a file is written. Find a target's source with `chezmoi source-path <target>`, never by guessing.

**Only plain files are links.** Templates, executables and private files are copies in `$HOME`, so an edit to the copy is lost on the next apply. Edit the source in `home/` and run `chezmoi apply`. `chezmoi status` lists copies that differ.

**The repo is public.** A token in `settings.json`, an env block, or a shell export goes public on push. `scripts/check` runs gitleaks when it is installed, and CI always runs it.

**A broken shell file breaks every machine within the hour.** `scripts/check` starts an interactive zsh in the empty `$HOME`, so a command that a fresh machine lacks has to be guarded with `(( $+commands[tool] ))`.
