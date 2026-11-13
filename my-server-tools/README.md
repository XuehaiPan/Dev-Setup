# Server Tools

Standalone Bash scripts for setting up Debian and Ubuntu servers, managing local accounts and shared storage, and provisioning GPU nodes. The account tools also work on Debian and Ubuntu derivatives. NVIDIA setup requires native Ubuntu with systemd.

From the Dev-Setup repository root, run `cd my-server-tools` before using the examples. Every command accepts `-h` or `--help` without `sudo`.

| Command                                                              | Purpose                                                                                             |
| -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [`bootstrap-server`](#bootstrap-a-fresh-server)                      | Configure the host admin account and build the template for new users.                              |
| [`add-user`](#add-user)                                              | Create a local account, its home, and its data directory.                                           |
| [`delete-user`](#delete-user)                                        | Remove a local account, its home, and its data.                                                     |
| [`update-user-template`](#refresh-the-template)                      | Update the software that new accounts inherit.                                                      |
| [`setup-nvidia-toolkits`](#set-up-the-nvidia-driver-on-a-gpu-server) | Install the host driver, Fabric Manager on NVSwitch nodes, and NVIDIA Container Toolkit for Docker. |
| [`foreach-user-run`](#foreach-user-run)                              | Run a command in each local user’s home.                                                            |
| [`warn-user`](#warn-user)                                            | Send a message to one user’s logged-in terminals.                                                   |
| [`drop-caches`](#drop-caches)                                        | Flush pending writes and drop kernel filesystem caches.                                             |

For disk usage, package upgrades, and cache cleanup across accounts, see [Routine maintenance](#routine-maintenance).

## Bootstrap a fresh server

Create `/data` or mount your data disk there. Allow space for a temporary copy of the user template. Run the bootstrap from your regular admin account to configure its home and build `/etc/skel` for new users.

```bash
sudo bin/bootstrap-server
```

- **Admin account.** From a root shell, use `bin/bootstrap-server --user YOUR_LOGIN` with the exact name of an existing local admin. On a minimal host you can copy the standalone script to the node. It installs `sudo` if needed and checks the account’s access. With standard input redirected, the admin needs passwordless sudo for the setup commands.
- **Package mirrors.** Use `--set-mirrors` for CERNET mirrors or `--no-set-mirrors` to keep the existing sources on both the host and the template. If you omit both flags, the bootstrap prompts once in a terminal. Pressing Enter or running unattended keeps the existing sources.
- **Template customization.** Pass `--edit` to open a shell as `server-admin` in the build container. Type `exit` when ready to publish the template.

### What the bootstrap changes

1. It installs APT prerequisites, clones Dev-Setup under `/tmp`, and runs it as the host admin. The host and container use the same revision, per-user Homebrew, and noninteractive setup. [Dev-Setup repository](https://github.com/XuehaiPan/Dev-Setup)
2. It installs Docker with `--no-autostart` if the CLI is missing or a systemd host lacks `docker.service`. On systemd hosts it starts the local service for the build. The Docker CLI honors the selected context, `DOCKER_CONTEXT`, and `DOCKER_HOST`. To check which daemon a sudo invocation reaches, use `sudo docker context show` and `sudo docker info`. [Docker installer](https://get.docker.com/)
3. In a container matching the host’s distribution, release, and Debian package architecture, it runs Dev-Setup as `server-admin` with passwordless sudo. It copies selected profiles, settings, and tools to `/etc/skel` as `root:root`, preserving relative symlinks and hard links. For the host admin and the template account, it sets `DEFAULT_USER="root"` in Zsh. If `/usr/bin/vim.basic` is available, it creates `~/.selected_editor` for accounts missing that file.
4. It removes the temporary checkout and container. On systemd hosts it restores the previous Docker and containerd service, socket, and boot settings, including masks. Newly installed units are stopped and disabled.

Rerunning the bootstrap reconfigures the host admin and rebuilds the template. It removes obsolete files inside the directories it copies and preserves unrelated top-level entries in `/etc/skel`. For routine updates between account creations, use [Refresh the template](#refresh-the-template).

## User management

### `add-user`

After bootstrapping, use `add-user` to create a local account from `/etc/skel`.

```bash
sudo bin/add-user alice
```

Alice gets Zsh, a locked password, a private home at `/home/alice` (mode `0700`), and a personal data directory at `/data/alice`. The script replaces `server-admin` with `alice` in copied text files and creates each link below if its name is free in the new home.

| Home link       | Destination            |
| --------------- | ---------------------- |
| `~/data`        | `/data/alice`          |
| `~/Projects`    | `/data/alice/Projects` |
| `~/shared-data` | `/data/shared-data`    |

**Shared storage.** An existing `/data/shared-data` may be a directory or a symlink to a directory. Its contents and permissions are preserved. A regular file, a symlink to a file, or a dangling symlink stops account creation. If the path is missing, the script creates the shared directory as `root:root` with mode `0777` after `useradd` succeeds.

**SSH access.** Append Alice’s public key to `/home/alice/.ssh/authorized_keys`, or to the location configured by `AuthorizedKeysFile` on the host. The script creates the default key file if needed and sets `.ssh` to mode `0700` and `authorized_keys` to `0600`.

If `/home/alice` or `/data/alice` already exists, inspect it and move it aside before retrying. If `useradd` registers the login and then fails, the script keeps the reserved data directory and identifies the home to inspect. To create the optional `server-admin` account on the host, use `sudo bin/add-user server-admin`.

### `delete-user`

**Deletion is permanent.** The command removes the local account and its recorded home using `deluser --remove-home` with the host’s `deluser` configuration. It then checks the local account database again and removes `/data/USERNAME` once the exact login is gone.

```bash
sudo bin/delete-user alice
```

Unmount any volume at or beneath `/data/USERNAME` first. If the script finds one, it prints the mount point and stops before deleting the account. It also refuses to delete `server-admin`, the reserved name `shared-data`, or any account with UID 0.

## Refresh the template

Run `update-user-template` between account creations. New accounts inherit the refreshed software.

```bash
sudo bin/update-user-template
```

The updater first recovers any interrupted Miniconda update from its saved copy. It then fast-forwards Git checkouts with a configured upstream under `.linuxbrew`, `.oh-my-zsh`, `.fzf`, and `.vim` in `/etc/skel`. It refreshes the fzf executable by running `.fzf/install --bin` as `nobody`.

If `/etc/skel/Miniconda3` exists, allow room in `/tmp` for a working copy and a rollback copy. The updater mounts a temporary home privately at `/home/server-admin`, the path where the template’s Conda installation was built. It runs Conda as the host’s `server-admin` account if available, otherwise as `nobody`. It updates the base and named environments, cleans the package cache, and copies the result back to `/etc/skel/Miniconda3`.

The updater reads `.condarc` and `.conda/tos` from the template. If either is missing and the host has a `server-admin` account, it looks in `/home/server-admin` for that item. Recovery after an interruption requires the rollback copy to survive. Compiled packages with an embedded prefix can still refer to `/home/server-admin/Miniconda3` after a new user’s text files have been personalized.

## Set up the NVIDIA driver on a GPU server

Run `setup-nvidia-toolkits` on a native Ubuntu host running systemd. It can provision a fresh node before `nvidia-smi` is available. Choose the command for the driver you want.

```bash
# Use the default LTS selection.
sudo bin/setup-nvidia-toolkits

# Choose a Production branch and the server driver family.
sudo bin/setup-nvidia-toolkits --production-branch --server

# Choose a specific driver package.
sudo bin/setup-nvidia-toolkits --package=nvidia-driver-580-server-open

# Upgrade the installed driver within its current branch, family, and kernel flavor.
sudo bin/setup-nvidia-toolkits --upgrade
```

**Automatic selection.** The installer uses `jq` to read branch types and release dates from NVIDIA’s JSON feed. From a branch’s first release, it allows one year for Production and three years for LTS. It selects the newest eligible branch APT offers for the chosen driver family and kernel flavor. Use `--server` for the server family and `--open` or `--proprietary` to select the kernel flavor. [NVIDIA release feed](https://docs.nvidia.com/datacenter/tesla/drivers/releases.json)

**Explicit selection.** Use `--package` to choose an available driver package, including one from an older or unlisted branch. This skips the release-feed lookup. You are responsible for that package’s compatibility. APT resolves the patch version. A normal run keeps the installed version if the selected package is already present. Use `--upgrade` to request an update. If APT cannot resolve the selection, correct the sources or choose another package.

**Unattended runs.** Pass `--yes` when running without a terminal. This authorizes the installer to stop GPU services and terminate processes using the GPUs.

**NVSwitch nodes.** The installer detects a switch through its driver binding or management port. It requests `nvidia-fabricmanager-<branch>` by name, lets APT resolve the version, and holds the installed package. It starts Fabric Manager and enables it at boot. If APT offers only the unversioned `nvidia-fabricmanager`, setup stops. Install the NVLink Subnet Manager (`nvlsm`) manually before setup if the node requires it.

After setup, list the GPUs and their driver versions. On NVSwitch nodes, the service check should print `active`.

```bash
nvidia-smi --query-gpu=name,driver_version --format=csv
systemctl is-active nvidia-fabricmanager.service  # NVSwitch nodes only
```

### Docker GPU access

The installer sets up Docker Engine if needed. For `nvidia-container-toolkit`, it uses NVIDIA’s trusted stable APT index. If that index is missing, it writes the repository list to `/etc/apt/sources.list.d/nvidia-container-toolkit.list` with `signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg`. On hosts with a custom APT sources directory, enable the stable repository where APT reads it.

On a new toolkit installation, setup registers the NVIDIA runtime in `/etc/docker/daemon.json`. If Docker was already running, setup checks registration through `/var/run/docker.sock`. Rerun setup if registration fails or is interrupted. Setup restores Docker’s previous service state.

An already-running daemon may need a restart to recognize `--gpus all`. When workloads allow, restart it with `sudo systemctl restart docker`. Once Docker is active, list the GPUs from inside a container.

```bash
sudo docker run --rm --runtime=nvidia --gpus all ubuntu:latest nvidia-smi -L
```

## Other commands

### `foreach-user-run`

Run a command as each local user whose recorded home is an existing directory at `/home/USERNAME`. Each command runs in `/bin/bash`, regardless of the user’s login shell. Bash sources `~/.bash_profile` and changes to the user’s home before evaluating the command.

Pass the command as one nonblank string. Single quotes let the target user’s Bash expand variables and globs, so this example prints each user’s home directory. If the command string starts with a dash, put `--` before it.

```bash
sudo bin/foreach-user-run 'echo "${HOME}"'
```

By default, `foreach-user-run` stops at the first failure. With `--keep-going`, it finishes the remaining accounts and lists each failed account with its exit code. In both modes, it returns the first nonzero exit code, or zero if all commands succeed.

To compare dotfiles with the template interactively, run Vim from a terminal. Quit Vim to move to the next account.

```bash
sudo bin/foreach-user-run 'vim -c "DirDiff ~/.dotfiles /etc/skel/.dotfiles"'
```

To print a unified diff of each account’s top-level dotfiles against the template, use `colordiff` with `--keep-going`. This lets the comparison continue when `colordiff` reports differences with a nonzero exit code.

```bash
sudo bin/foreach-user-run --keep-going 'colordiff -uEB ~/.dotfiles /etc/skel/.dotfiles'
```

### `warn-user`

Pass the exact login name and a message. Each terminal where that user is logged in displays the message 30 times, followed by the system uptime.

```bash
sudo bin/warn-user alice "Please save your work."
```

### `drop-caches`

Flush pending writes with `sync` and drop the system-wide filesystem caches by setting `vm.drop_caches=3`.

```bash
sudo bin/drop-caches
```

## Routine maintenance

List `/data` and its immediate subdirectories by size, largest first. The `-x` flag keeps the scan on the same filesystem.

```bash
sudo du -xh --max-depth=1 -- /data | sort -hr
```

Update Homebrew and list outdated packages for each account.

```bash
sudo bin/foreach-user-run --keep-going 'brew update && brew outdated --greedy'
```

Install the same Homebrew packages for each account. Cleanup runs even if the update or install fails, and the subshell passes a failure back to `foreach-user-run`.

```bash
sudo bin/foreach-user-run '(
    result=0
    brew update && brew install gh uv codex claude-code@latest || result="$?"
    brew cleanup --scrub --prune=all || exit "$?"
    exit "${result}"
)'
```

Refresh each account with the upgrade helpers from its Dev-Setup Bash profile. This also clears Homebrew downloads and the pre-commit, pip, and uv caches. Running `uv cache clean` after both `uvx` commands clears the tools they cached.

```bash
sudo bin/foreach-user-run '{
    upgrade_homebrew
    brew cleanup --scrub --prune=all
    uvx pre-commit clean
    uvx pip cache purge
    uv cache clean
    upgrade_ohmyzsh
    upgrade_fzf
    upgrade_vim
}'
```

Preview the space each account could reclaim from cached Conda archives. Replace `--dry-run` with `--yes` to remove them.

```bash
sudo bin/foreach-user-run '"${HOME}/Miniconda3/bin/conda" clean --tarballs --dry-run'
```
