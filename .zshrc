export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

fpath+=("$(brew --prefix)/share/zsh/site-functions")

autoload -U promptinit; promptinit

zstyle ':prompt:pure:prompt:*' color cyan
zstyle :prompt:pure:git:stash show yes
zstyle :prompt:pure:path color cyan

prompt pure
unalias glo 2>/dev/null

export LANG=en_US.UTF-8

eval $(thefuck --alias)

export DEFAULT_USER=$USER

# To load .nvmrc if present
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
# --------

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"

# ---- keep PATH unique; ensure ~/tools/bin is first
typeset -U path PATH
path=($HOME/tools/bin $path)

## Go bin
export PATH="$HOME/go/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[ -s "$NVM_DIR/nvm.sh" ] && load-nvmrc  # apply .nvmrc for the starting dir; the chpwd hook covers the rest

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

for fragment in "$HOME"/.config/dotfiles/*.zsh(N); do
  source "$fragment"
done
unset fragment
