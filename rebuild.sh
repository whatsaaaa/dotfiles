#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOST="whatsaaaa-mac"

ln -sfn "$DIR" "$HOME/.dotfiles"

if ! command -v nix >/dev/null 2>&1; then
  echo "Nix isn't installed (or this shell hasn't loaded it). Install Nix first." >&2
  exit 1
fi

# Create/update the lock file as the user, not root
nix flake lock "$DIR"

# First-run: move installer-written shell rc files out of nix-darwin's way
for f in /etc/zshrc /etc/bashrc; do
  if [ -f "$f" ] && [ ! -L "$f" ]; then
    sudo mv "$f" "$f.before-nix-darwin"
  fi
done

REBUILD=/run/current-system/sw/bin/darwin-rebuild
if [ -x "$REBUILD" ]; then
  exec sudo "$REBUILD" switch --flake "$DIR#$HOST"
else
  exec sudo nix run nix-darwin -- switch --flake "$DIR#$HOST"
fi
