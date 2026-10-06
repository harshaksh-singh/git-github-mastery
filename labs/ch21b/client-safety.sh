#!/usr/bin/env bash
# Chapter 21B, sections 21B.2 to 21B.4: what a clone copies and what it does not, why an
# unpacked copy of someone else's .git is different, and the three client guards
# safe.directory, safe.bareRepository and protocol.file.allow.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch21b client-safety

# A repository prepared by someone else: one commit, one hook, one alias that runs a shell command.
quiet 'git init vendor-tool'
cd vendor-tool || exit 1
printf 'def main():\n    print("tool")\n' > tool.py
quiet "git add -A && git commit -m 'Add tool'"
printf '#!/bin/sh\necho "post-checkout hook ran as $(basename "$PWD")" >> "$(git rev-parse --git-dir)/hook-ran.log"\n' > .git/hooks/post-checkout
chmod +x .git/hooks/post-checkout
quiet "git config set alias.st '!echo alias from the repository config ran'"
cd "$LAB_DIR" || exit 1

snip 01-what-the-author-has
run 'cat vendor-tool/.git/hooks/post-checkout'
run 'git -C vendor-tool config get alias.st'

snip 02-clone-copies-neither
run 'git clone -q --no-local vendor-tool cloned'
run "ls cloned/.git/hooks | grep -v '\.sample\$' | wc -l"
run_rc 'git -C cloned config get alias.st'
run 'git -C cloned switch -q -c try'
run 'ls cloned/.git | grep hook-ran || echo "no hook ran"'

snip 03-unpacked-copy-runs-both
note 'The same repository received as an archive: every file under .git arrives as written.'
run 'cp -R vendor-tool unpacked'
run 'cd unpacked'
run 'git st'
run 'git switch -q -c try'
run 'cat .git/hook-ran.log'
run 'cd ..'

snip 04-dubious-ownership
note 'GIT_TEST_ASSUME_DIFFERENT_OWNER=1 makes Git treat the repository as owned by another user.'
run_rc 'GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C unpacked status -sb'

snip 05-safe-directory
run 'git config set --global --append safe.directory "$PWD/unpacked"'
run_rc 'GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C unpacked status -sb'
note 'The setting is honoured only in protected configuration. In the repository itself it is ignored:'
run 'git config unset --global safe.directory'
run "git -C unpacked config set safe.directory '*'"
run 'GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C unpacked status -sb 2>&1 | head -1'

snip 06-bare-repository
quiet 'git clone --bare vendor-tool embedded.git'
run 'git -C embedded.git log --oneline'
run 'git config set --global safe.bareRepository explicit'
run_rc 'git -C embedded.git log --oneline'
run 'git --git-dir=embedded.git log --oneline'
run 'git config unset --global safe.bareRepository'

snip 07-file-protocol
quiet 'git init app'
quiet "git -C app commit --allow-empty -m 'Start app'"
run 'cd app'
run_rc 'git submodule add ../vendor-tool vendor/tool'
run_rc 'git config get protocol.file.allow'
run 'git -c protocol.file.allow=always submodule add -q ../vendor-tool vendor/tool'
run 'git submodule status | cut -c1-9,42-'
lab_end
