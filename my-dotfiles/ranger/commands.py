# This is a sample commands.py.  You can add your own commands here.
#
# Please refer to commands_full.py for all the default commands and a complete
# documentation.  Do NOT add them all here, or you may end up with defunct
# commands when upgrading ranger.

# A simple command for demonstration purposes follows.
# -----------------------------------------------------------------------------

from __future__ import (absolute_import, division, print_function)

# You can import any python module as needed.
import os
from collections import deque

# You always need to import ranger.api.commands here to get the Command class:
from ranger.api.commands import Command


FD_DEQUE = deque()


class fzf_select(Command):
    """
    :fzf_select
    Find a file using fzf.
    With a prefix argument select only directories.

    See: https://github.com/junegunn/fzf
    """

    def execute(self):
        import subprocess
        from ranger.ext.get_executables import get_executables

        if 'fd' in get_executables():
            command = 'fd'
        elif 'fdfind' in get_executables():
            command = 'fdfind'
        else:
            self.fm.notify('Could not find fd in the PATH.', bad=True)
            return
        command += ' --follow --no-ignore-vcs --color=always'
        if self.fm.settings.show_hidden:
            command += ' --hidden'
        if self.quantifier:
            # match only directories
            command += ' --type directory'
        command += " --exclude '.git' --exclude '*.pyc' --exclude '.*pyo' --exclude '__pycache__'"
        if 'fzf' not in get_executables():
            self.fm.notify('Could not find fzf in the PATH.', bad=True)
            return

        command += ''' | fzf --no-multi --height=40% --layout=reverse --ansi --preview="(
            batcat --color=always {} ||
            bat --color=always {} ||
            cat {} ||
            tree -ahpCL 3 -I '.git' -I '*.pyc' -I '.*pyo' -I '__pycache__' {}
        ) 2>/dev/null | head -100"'''
        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip('\n'))
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)


class fd_search(Command):
    """
    :fd_search [-d<depth>] <query>
    Executes "fd -d<depth> <query>" in the current directory and focuses the
    first match. <depth> defaults to 1, i.e. only the contents of the current
    directory.
    """

    def execute(self):
        import re
        import subprocess
        from ranger.ext.get_executables import get_executables

        global FD_DEQUE
        FD_DEQUE.clear()

        if 'fd' in get_executables():
            command = 'fd'
        elif 'fdfind' in get_executables():
            command = 'fdfind'
        else:
            self.fm.notify("Couldn't find fd in the PATH.", bad=True)
            return

        if self.arg(1):
            if self.arg(1)[:2] == '-d':
                depth = self.arg(1)
                target = self.rest(2)
            else:
                depth = '-d1'
                target = self.rest(1)
        else:
            self.fm.notify(":fd_search needs a query.", bad=True)
            return
        command += ' ' + depth + " --follow --no-ignore-vcs --exclude '.git'"
        if self.fm.settings.show_hidden:
            command += ' --hidden'
        command += ' ' + target
        fd = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        (search_results, _) = fd.communicate()

        search_results = filter(None, search_results.split('\n'))
        if self.fm.settings.hidden_filter:
            hidden_filter = re.compile(self.fm.settings.hidden_filter)
            search_results = filter(lambda res: hidden_filter.search(os.path.basename(res)) is None, search_results)
        search_results = set(map(lambda res: os.path.realpath(os.path.join(self.fm.thisdir.path, res)), search_results))
        FD_DEQUE = deque(sorted(search_results, key=str.lower))
        if len(FD_DEQUE) > 0:
            self.fm.select_file(FD_DEQUE[0])


class fd_next(Command):
    """
    :fd_next
    Selects the next match from the last :fd_search.
    """

    def execute(self):
        if len(FD_DEQUE) > 1:
            FD_DEQUE.rotate(-1)  # rotate left
            self.fm.select_file(FD_DEQUE[0])
        elif len(FD_DEQUE) == 1:
            self.fm.select_file(FD_DEQUE[0])


class fd_prev(Command):
    """
    :fd_prev
    Selects the next match from the last :fd_search.
    """

    def execute(self):
        if len(FD_DEQUE) > 1:
            FD_DEQUE.rotate(1)  # rotate right
            self.fm.select_file(FD_DEQUE[0])
        elif len(FD_DEQUE) == 1:
            self.fm.select_file(FD_DEQUE[0])
