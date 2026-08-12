#!/usr/bin/env bash
# Symlinks the generic dotfiles-base config into place on a new machine.
# Always run this first — personal/work dotfiles repos append to files
# this script creates.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/lib/install-common.sh"

link "$REPO_DIR/.zshrc" "$HOME/.zshrc"
link "$REPO_DIR/.tmux.conf" "$HOME/.tmux.conf"

mkdir -p "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh/config.d"

touch "$HOME/.ssh/config"
if ! grep -q 'Include ~/.ssh/config.d/\*.conf' "$HOME/.ssh/config"; then
  printf '\nInclude ~/.ssh/config.d/*.conf\n' >> "$HOME/.ssh/config"
  echo "appended Include line to ~/.ssh/config"
fi

# Domain repos find this repo — and lib/install-common.sh — through base.env.
# Rewritten every run, so moving the clone is picked up on reinstall.
mkdir -p "$HOME/.config/dotfiles"
printf 'DOTFILES_BASE=%s\n' "$REPO_DIR" > "$HOME/.config/dotfiles/base.env"
echo "wrote ~/.config/dotfiles/base.env -> $REPO_DIR"

# Global git excludes. git reads ~/.config/git/ignore by default; an explicit
# core.excludesFile would shadow this silently, so doctor.sh checks for one.
mkdir -p "$HOME/.config/git"
link "$REPO_DIR/gitignore-global" "$HOME/.config/git/ignore"

if [ ! -f "$HOME/.gitconfig" ]; then
  touch "$HOME/.gitconfig"
  echo "created empty ~/.gitconfig — set your identity: git config --global user.name/user.email"
fi

echo "Done. Restart your shell (or: exec zsh)."
