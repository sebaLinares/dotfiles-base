#!/usr/bin/env bash
# Checks the seams between dotfiles-base and its domain repos — the failures
# that stay invisible on a machine which already works, and only surface on
# the next one. Exits nonzero if anything is wrong.
#
# Not installed and not hooked into anything: run it when something feels off.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAGMENT_DIR="$HOME/.config/dotfiles"
SSH_DIR="$HOME/.ssh/config.d"

fails=0
fail() { printf 'FAIL  %s\n' "$*"; fails=$((fails + 1)); }
ok()   { printf 'ok    %s\n' "$*"; }

# --- 1. every installed symlink resolves ------------------------------------
for dir in "$FRAGMENT_DIR" "$SSH_DIR"; do
  [ -d "$dir" ] || continue
  for l in "$dir"/*; do
    [ -L "$l" ] || continue
    if [ -e "$l" ]; then
      ok "symlink resolves: ${l/#$HOME/\~}"
    else
      fail "dangling symlink: ${l/#$HOME/\~} -> $(readlink "$l")"
    fi
  done
done

for l in "$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/git/ignore"; do
  if [ ! -L "$l" ]; then
    fail "not a symlink (base should own it): ${l/#$HOME/\~}"
  elif [ "$(readlink "$l")" != "$REPO_DIR/$(basename "$l")" ] &&
       [ "$(readlink "$l")" != "$REPO_DIR/gitignore-global" ]; then
    fail "${l/#$HOME/\~} points outside this base clone -> $(readlink "$l")"
  else
    ok "base owns ${l/#$HOME/\~}"
  fi
done

# --- 2. base.env is present and accurate ------------------------------------
if [ ! -f "$FRAGMENT_DIR/base.env" ]; then
  fail "missing ~/.config/dotfiles/base.env — run base's install.sh"
else
  recorded="$(sed -n 's/^DOTFILES_BASE=//p' "$FRAGMENT_DIR/base.env")"
  if [ "$recorded" != "$REPO_DIR" ]; then
    fail "base.env points at $recorded, but this clone is $REPO_DIR"
  elif [ ! -f "$recorded/lib/install-common.sh" ]; then
    fail "base.env target has no lib/install-common.sh — domain installs will fail"
  else
    ok "base.env -> $recorded"
  fi
fi

# --- 3. collect the domain repos behind the fragments -----------------------
repos=()
if [ -d "$FRAGMENT_DIR" ]; then
  for frag in "$FRAGMENT_DIR"/*.zsh; do
    [ -e "$frag" ] || continue
    target="$(cd "$(dirname "$(readlink "$frag" || echo "$frag")")" 2>/dev/null && pwd)" || continue
    repos+=("$target")
  done
fi
[ ${#repos[@]} -gt 0 ] && ok "domain repos: ${repos[*]/#$HOME/\~}"

# --- 4. alias names defined in more than one repo ---------------------------
# Lexical fragment load order decides the winner silently, so a collision
# means one repo is quietly overriding the other.
pairs="$(
  for repo in "${repos[@]:-}"; do
    [ -d "$repo" ] || continue
    grep -rhoE '^alias [A-Za-z0-9_.-]+' "$repo" --exclude-dir=.git 2>/dev/null |
      awk -v r="$(basename "$repo")" '{print $2"\t"r}'
  done | sort -u
)"
collisions="$(printf '%s\n' "$pairs" | cut -f1 | grep -v '^$' | uniq -d)"
if [ -n "$collisions" ]; then
  while read -r name; do
    owners="$(printf '%s\n' "$pairs" | awk -F'\t' -v n="$name" '$1==n {print $2}' | paste -sd, -)"
    fail "alias '$name' defined in: $owners"
  done <<< "$collisions"
else
  ok "no alias collisions across domain repos"
fi

# --- 5. aliases pointing at files inside the repos that no longer exist ------
# Only files (by extension) are checked; directory aliases legitimately point
# at project checkouts that vary per machine.
for repo in "${repos[@]:-}" "$REPO_DIR"; do
  [ -d "$repo" ] || continue
  while read -r ref; do
    [ -n "$ref" ] || continue
    expanded="${ref/#\~/$HOME}"
    expanded="${expanded/#\$HOME/$HOME}"
    [ -e "$expanded" ] || fail "alias target missing: $ref (in $(basename "$repo"))"
  done < <(grep -rhE '^alias [A-Za-z0-9_.-]+=' "$repo" --exclude-dir=.git 2>/dev/null |
             grep -oE '(~|\$HOME)/[A-Za-z0-9_./-]+' |
             grep -E '\.(sh|zsh|json|conf)$' | sort -u)
done

# --- 6. core.excludesFile must stay unset -----------------------------------
# Setting it shadows ~/.config/git/ignore, which is where base installs the
# global excludes. An explicit value is also an absolute path that silently
# points at nothing on the next machine.
excludes="$(git config --global core.excludesFile 2>/dev/null || true)"
if [ -n "$excludes" ]; then
  fail "core.excludesFile is set to $excludes — it shadows ~/.config/git/ignore; unset it: git config --global --unset core.excludesFile"
else
  ok "core.excludesFile unset (git uses ~/.config/git/ignore)"
fi

echo
if [ "$fails" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$fails check(s) failed."
  exit 1
fi
