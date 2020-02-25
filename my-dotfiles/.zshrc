# Source common configrations
source "$HOME/.dotfiles/.zshrc-common"

# Setup colorls
source "$(dirname "$(gem which colorls)")"/tab_complete.sh
alias ls='colorls --sd --gs'
