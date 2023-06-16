## Settings and Extensions for VS Code

This directory contains my VS Code settings and extensions.

### Settings

Compare with your VS Code settings:

- macOS:

```bash
code --diff "${HOME}/Library/Application Support/Code/User/settings.json" settings.json
```

- Linux:

```bash
code --diff "${HOME}/.config/Code/User/settings.json" settings.json
```

- Windows:

```powershell
code --diff "$Env:APPDATA\Code\User\settings.json" settings.json
```

- WSL on Windows:

```bash
APPDATA="$(wslpath "$(wslvar APPDATA)")"
code --diff "${APPDATA}/Code/User/settings.json" settings.json
```

### Extensions

You can install all these extensions by running:

- Use Bash / Zsh:

```bash
cat extensions.list | xargs -L 1 code --install-extension
```

- Use PowerShell:

```powershell
Get-Content extensions.list | %{ code --install-extension $_ }
```
