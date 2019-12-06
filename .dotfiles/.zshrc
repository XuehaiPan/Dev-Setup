# Source common configrations
source "$HOME/.dotfiles/.zshrc-common"

# Setup colorls
source $(dirname $(gem which colorls))/tab_complete.sh
alias lc='colorls --sd --gs'
alias ls='lc'
alias lsa='ls -A'
alias l='ls -la'
alias ll='ls -l'
alias la='ls -lA'
