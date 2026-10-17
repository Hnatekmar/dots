
set -o vi

export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/node/bin:$HOME/.local/go/bin:$HOME/go/bin:$PATH"

ZSH_THEME="3den"

plugins=(
    direnv
    git
    kubectl
    ssh-agent
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Check archlinux plugin commands here
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux

# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos

# fastfetch. Will be disabled if above colorscript was chosen to install
#fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc

# Set-up icons for files/directories in terminal using lsd
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# Colorize kubectl output via kubecolor
alias kubectl='kubecolor'

export EDITOR=nvim

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)
eval "$(zoxide init zsh)"
export PATH="$HOME/.local/bin:$HOME/.local/node/bin:$HOME/.bun/bin:$HOME/.npm-global/bin:$PATH"
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

fpath=(~/.zsh/completions $fpath)
autoload -U compinit && compinit
