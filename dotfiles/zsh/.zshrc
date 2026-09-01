# Variables
export EDITOR="nvim"
export VISUAL="$EDITOR"
export BROWSER="brave"
export PATH="$HOME/.local/bin:$PATH"

# Autocompletado nativo de Zsh
fpath=("${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions" $fpath)
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Prompt con Git
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:*' formats ' %B%s-[%F{magenta}%f %F{yellow}%b%f]-'

function dir_icon {
  if [[ "$PWD" == "$HOME" ]]; then
    printf '󰋜'
  else
    printf '󰉋'
  fi
}

setopt PROMPT_SUBST
PS1='%B%F{blue}󰣇%f%b %B%F{magenta}%n%f%b %B%F{cyan}$(dir_icon)%f%b %B%F{red}%~%f%b${vcs_info_msg_0_} %(?.%B%F{green}.%F{red})❯❯%f%b '

# Historial
HISTFILE="$HOME/.zhistory"
HISTSIZE=5000
SAVEHIST=5000
setopt appendhistory sharehistory hist_ignore_all_dups

# Plugins instalados por pacman
for plugin in \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  [[ -r "$plugin" ]] && source "$plugin"
done
unset plugin

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Aliases
alias ls='eza --icons=always --color=always -a'
alias ll='eza --icons=always --color=always -la'
alias cat='bat'
alias ff='fastfetch'
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# Node Version Manager. El instalador usa esta misma ubicación.
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# Herramientas opcionales ya usadas en la máquina original.
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT/bin" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
  command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"
fi

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export BUN_INSTALL="$HOME/.bun"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"

# Ajustes privados o propios de cada máquina.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

command -v fastfetch >/dev/null 2>&1 && fastfetch
