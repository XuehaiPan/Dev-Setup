# Source common configrations
source "$HOME/.dotfiles/.zshrc-common"

# Use powerlevel10k purepower theme
source "$ZSH_CUSTOM/themes/powerlevel10k/config/p10k-lean.zsh"
POWERLEVEL9K_MODE="compatible"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs virtualenv anaconda pyenv time)
POWERLEVEL9K_TRANSIENT_PROMPT="same-dir"
p10k reload
