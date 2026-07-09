#!/usr/bin/env bash
# Symlinks the generic dotfiles-base config into place on a new machine.
# Always run this first — personal/work dotfiles repos append to files
# this script creates.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok: $dest already linked"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local backup="${dest}.bak-$(date +%Y%m%d%H%M%S)"
    echo "backing up existing $dest -> $backup"
    mv "$dest" "$backup"
  fi
  ln -s "$src" "$dest"
  echo "linked $dest -> $src"
}

link "$REPO_DIR/.zshrc" "$HOME/.zshrc"
link "$REPO_DIR/.tmux.conf" "$HOME/.tmux.conf"

mkdir -p "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh/config.d"

touch "$HOME/.ssh/config"
if ! grep -q 'Include ~/.ssh/config.d/\*.conf' "$HOME/.ssh/config"; then
  printf '\nInclude ~/.ssh/config.d/*.conf\n' >> "$HOME/.ssh/config"
  echo "appended Include line to ~/.ssh/config"
fi

if [ ! -f "$HOME/.gitconfig" ]; then
  touch "$HOME/.gitconfig"
  echo "created empty ~/.gitconfig — set your identity: git config --global user.name/user.email"
fi

echo "Done. Restart your shell (or: exec zsh)."
