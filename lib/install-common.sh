# Shared install helpers, owned by dotfiles-base.
# Sourced, never executed. Domain repos locate this file through
# ~/.config/dotfiles/base.env, written by base's install.sh.

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
