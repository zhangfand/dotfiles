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
