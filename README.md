# OS-Setup

Bash scripts for setting up a freshly new installed OS automatically.

## Usage

Open Terminal and run

```bash
bash setup_${OS_name}.sh
```

change the user profiles in `.gitconfig` after the script is done.

If using Linux, modify the default host name in function `send_to_mac` and `recieve_from_mac` in file `.dotfiles/utilities.sh`.
