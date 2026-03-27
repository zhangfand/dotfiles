#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

packages=(zsh git nvim zed ghostty starship gh claude hammerspoon brew)

for pkg in "${packages[@]}"; do
    echo "Stowing $pkg..."
    stow -v --target="$HOME" "$pkg"
done

echo "Done. All packages stowed."
