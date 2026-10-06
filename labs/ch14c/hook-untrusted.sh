#!/usr/bin/env bash
# Chapter 14C, section 14C.12: hook security. A repository that arrives as an archive brings its
# hooks and its configuration along, and both run commands. A clone of the same repository
# brings neither.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c hook-untrusted

# Somebody else prepared this repository. The two commands only print a line; a real attacker
# would run anything your account may run.
quiet 'git init research-code'
quiet "printf 'print(\"reproduce table 2\")\n' > research-code/reproduce.py && git -C research-code add . && git -C research-code commit -m 'Add reproduction script'"
quiet "git -C research-code config set core.fsmonitor 'echo \"  >> a command from the archive ran (core.fsmonitor)\" >&2; false'"
quiet "printf '#!/bin/sh\necho \"  >> a command from the archive ran (post-checkout hook)\"\n' > research-code/.git/hooks/post-checkout && chmod +x research-code/.git/hooks/post-checkout"
quiet 'tar -cf research-code.tar research-code && rm -rf research-code'

snip 01-archive
note 'You download research-code.tar, unpack it and look around:'
run 'tar -xf research-code.tar'
run 'cd research-code'
run 'git status -s'
run 'git switch -c look-around'

snip 02-what-ran
run 'git config list --local --show-origin | grep fsmonitor'
run 'ls .git/hooks | grep -v sample'

snip 03-clone
note 'A clone copies objects and refs. It copies neither .git/config nor .git/hooks:'
run 'cd ..'
run 'git clone -q --no-local research-code safe-copy'
run 'cd safe-copy'
run 'git status -s'
run 'git switch -c inspect'
run_rc 'git config get core.fsmonitor'
run 'ls .git/hooks | grep -v sample'

lab_end
