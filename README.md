# dotfiles

Machine setup for macOS and Linux, managed with [chezmoi](https://www.chezmoi.io/).

## New machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply zhangfand
```

This installs chezmoi, clones this repo to `~/.local/share/chezmoi`, links the files into `$HOME`, and starts an hourly update (launchd on macOS, a systemd user timer on Linux). On macOS it also runs `brew bundle` when Homebrew is installed.

## Machine set up with the old stow layout

1. Commit and push anything uncommitted in the old clone.
2. Stow may have linked a whole directory, such as `~/.claude`, into the old clone, so runtime state (history, sessions, plugins) lives there. For each such link, replace it with a real directory holding the same contents: `cp -a "$(readlink -f ~/.claude)" ~/.claude.new && rm ~/.claude && mv ~/.claude.new ~/.claude`.
3. Run the install command above. chezmoi replaces the remaining stow links with its own.
4. Remove the old clone.

## Changing something

Ask an agent. The rules it follows are in [CLAUDE.md](CLAUDE.md).
