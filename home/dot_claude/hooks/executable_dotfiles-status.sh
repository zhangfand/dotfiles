#!/bin/sh
# SessionStart hook. Tells the agent when this machine's dotfiles differ from
# GitHub, so the change can go up as a PR. Prints nothing when they match.
command -v chezmoi >/dev/null 2>&1 || exit 0
repo=$(chezmoi git -- rev-parse --show-toplevel 2>/dev/null) || exit 0

uncommitted=$(git -C "$repo" status --porcelain 2>/dev/null)
unpushed=$(git -C "$repo" log --oneline '@{upstream}..' 2>/dev/null)
drifted=$(chezmoi status 2>/dev/null)
[ -z "$uncommitted$unpushed$drifted" ] && exit 0

echo "This machine's dotfiles (chezmoi clone at $repo) differ from GitHub."
[ -n "$uncommitted" ] && printf 'Uncommitted in the clone:\n%s\n' "$uncommitted"
[ -n "$unpushed" ] && printf 'Commits not pushed:\n%s\n' "$unpushed"
[ -n "$drifted" ] && printf 'Files in $HOME that differ from the clone (chezmoi status):\n%s\n' "$drifted"
echo "Tell the person in one line, and offer to open a PR. The repo's CLAUDE.md says how."
