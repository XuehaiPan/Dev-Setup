import os
from collections import deque

from ranger.api.commands import Command


class yank_content(Command):
    """:yank_content <file>

    Copies the content of the file into both the primary X selection and the
    clipboard.
    """

    def execute(self) -> None:
        from ranger.container.file import File
        from ranger.ext.get_executables import get_executables

        clipboard_managers = {
            "xclip": [
                ["xclip", "-selection", "primary"],
                ["xclip", "-selection", "clipboard"],
            ],
            "xsel": [
                ["xsel", "--primary"],
                ["xsel", "--clipboard"],
            ],
            "wl-copy": [
                ["wl-copy"],
            ],
            "pbcopy": [
                ["pbcopy"],
            ],
        }
        ordered_managers = ["pbcopy", "wl-copy", "xclip", "xsel"]
        executables = get_executables()
        for manager in ordered_managers:
            if manager in executables:
                clipboard_commands = clipboard_managers[manager]
                break
        else:
            self.fm.notify("Could not find a clipboard manager in the PATH.", bad=True)
            return

        arg = self.rest(1)
        if arg:
            if not os.path.isfile(arg):
                self.fm.notify(f"'{arg}' is not a file.", bad=True)
                return
            file = File(arg)
        else:
            file = self.fm.thisfile
            if not file.is_file:
                self.fm.notify(f"'{file.relative_path}' is not a file.", bad=True)
                return

        if not file.is_binary():
            for command in clipboard_commands:
                with open(file.path, encoding="utf-8") as fd:
                    self.fm.execute_command(command, universal_newlines=True, stdin=fd)
            self.fm.notify(f"The content of '{file.relative_path}' is copied to the clipboard.")
        else:
            self.fm.notify(f"'{file.relative_path}' is not a text file.")


class fzf_select(Command):
    """:fzf_select

    Find a file or directory using fzf.
    With a prefix argument to select only directories.

    See: https://github.com/junegunn/fzf
    """

    def execute(self) -> None:
        import subprocess

        from ranger.ext.get_executables import get_executables

        if "fzf" not in get_executables():
            self.fm.notify("Could not find fzf in the PATH.", bad=True)
            return

        fd = None
        if "fdfind" in get_executables():
            fd = "fdfind"
        elif "fd" in get_executables():
            fd = "fd"

        if fd is not None:
            hidden = "--hidden" if self.fm.settings.show_hidden else ""
            exclude = (
                "--no-ignore-vcs --exclude '.git' --exclude '*.py[co]' --exclude '__pycache__'"
            )
            only_directories = "--type directory" if self.quantifier else ""
            fzf_default_command = (
                f"{fd} --follow {hidden} {exclude} {only_directories} --color=always"
            )
        else:
            hidden = "-false" if self.fm.settings.show_hidden else r"-path '*/\.*' -prune"
            exclude = r"\( -name '\.git' -o -iname '\.*py[co]' -o -fstype 'dev' -o -fstype 'proc' \) -prune"
            only_directories = "-type d" if self.quantifier else ""
            fzf_default_command = f"find -L . -mindepth 1 {hidden} -o {exclude} -o {only_directories} -print | cut -c3-"

        env = os.environ.copy()
        env["FZF_DEFAULT_COMMAND"] = fzf_default_command
        env["FZF_DEFAULT_OPTS"] = r'--height=40% --layout=reverse --ansi --preview="{}"'.format(
            """
            (
                batcat --color=always {} ||
                bat --color=always {} ||
                cat {} ||
                tree -ahpCL 3 -I '.git' -I '*.py[co]' -I '__pycache__' {}
            ) 2>/dev/null | head -n 100
            """,
        )

        fzf = self.fm.execute_command(
            "fzf --no-multi",
            env=env,
            universal_newlines=True,
            stdout=subprocess.PIPE,
        )
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            selected = os.path.abspath(stdout.strip())
            if os.path.isdir(selected):
                self.fm.cd(selected)
            else:
                self.fm.select_file(selected)


class fd_search(Command):
    """:fd_search [-d<depth>] <query>

    Executes "fd -d<depth> <query>" in the current directory and focuses the
    first match. <depth> defaults to 1, i.e. only the contents of the current
    directory.

    See https://github.com/sharkdp/fd
    """

    SEARCH_RESULTS = deque()

    def execute(self) -> None:
        import re
        import subprocess

        from ranger.ext.get_executables import get_executables

        self.SEARCH_RESULTS.clear()

        if "fdfind" in get_executables():
            fd = "fdfind"
        elif "fd" in get_executables():
            fd = "fd"
        else:
            self.fm.notify("Couldn't find fd in the PATH.", bad=True)
            return

        if self.arg(1):
            if self.arg(1)[:2] == "-d":
                depth = self.arg(1)
                target = self.rest(2)
            else:
                depth = "-d1"
                target = self.rest(1)
        else:
            self.fm.notify(":fd_search needs a query.", bad=True)
            return

        hidden = "--hidden" if self.fm.settings.show_hidden else ""
        exclude = "--no-ignore-vcs --exclude '.git' --exclude '*.py[co]' --exclude '__pycache__'"
        command = f"{fd} --follow {depth} {hidden} {exclude} --print0 {target}"
        fd = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, _ = fd.communicate()

        if fd.returncode == 0:
            results = filter(None, stdout.split("\0"))
            if not self.fm.settings.show_hidden and self.fm.settings.hidden_filter:
                hidden_filter = re.compile(self.fm.settings.hidden_filter)
                results = filter(
                    lambda res: not hidden_filter.search(os.path.basename(res)),
                    results,
                )
            results = (os.path.abspath(os.path.join(self.fm.thisdir.path, res)) for res in results)
            self.SEARCH_RESULTS.extend(sorted(results, key=str.lower))
            if len(self.SEARCH_RESULTS) > 0:
                self.fm.notify(
                    "Found {} result{}.".format(
                        len(self.SEARCH_RESULTS),
                        ("s" if len(self.SEARCH_RESULTS) > 1 else ""),
                    ),
                )
                self.fm.select_file(self.SEARCH_RESULTS[0])
            else:
                self.fm.notify("No results found.")


class fd_next(Command):
    """:fd_next

    Selects the next match from the last :fd_search.
    """

    def execute(self) -> None:
        if len(fd_search.SEARCH_RESULTS) > 1:
            fd_search.SEARCH_RESULTS.rotate(-1)  # rotate left
            self.fm.select_file(fd_search.SEARCH_RESULTS[0])
        elif len(fd_search.SEARCH_RESULTS) == 1:
            self.fm.select_file(fd_search.SEARCH_RESULTS[0])


class fd_prev(Command):
    """:fd_prev

    Selects the next match from the last :fd_search.
    """

    def execute(self) -> None:
        if len(fd_search.SEARCH_RESULTS) > 1:
            fd_search.SEARCH_RESULTS.rotate(1)  # rotate right
            self.fm.select_file(fd_search.SEARCH_RESULTS[0])
        elif len(fd_search.SEARCH_RESULTS) == 1:
            self.fm.select_file(fd_search.SEARCH_RESULTS[0])
