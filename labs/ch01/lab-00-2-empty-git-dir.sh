#!/usr/bin/env bash
# Lab 0.2: read every file in an empty .git directory, then find out by experiment which
# parts of it Git cannot live without.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch01 lab-00-2-empty-git-dir

snip 01-init
run 'git init tour'
run 'cd tour'
run 'find .git -type d | sort'
run 'find .git -type f | sort'

snip 02-read
run 'cat .git/HEAD'
run 'cat .git/config'
run 'cat .git/description'
run 'cat .git/info/exclude'
run 'head -n 8 .git/hooks/pre-commit.sample'

snip 03-ask-git
run 'git status'
run 'git symbolic-ref HEAD'
run 'git rev-parse --git-dir --show-toplevel'
run 'git count-objects -v'
run_rc 'git log'

snip 04-optional-files
note 'Failure scenario, part 1: delete what came from the template.'
run 'rm -r .git/hooks .git/info .git/description'
run_rc 'git status'

snip 05-config
note 'Part 2: set the configuration file aside, look, and put it back.'
run 'mv .git/config ../config.saved'
run_rc 'git status'
run_rc 'git config list --local'
run 'mv ../config.saved .git/config'

snip 06-refs-objects
note 'Part 3: set refs/ aside and put it back; then the same with objects/.'
run 'mv .git/refs ../refs.saved'
run_rc 'git status'
run 'mv ../refs.saved .git/refs'
run 'mv .git/objects ../objects.saved'
run_rc 'git status'
run 'mv ../objects.saved .git/objects'

snip 07-break-head
note 'Part 4: take HEAD away, and leave it away.'
run 'mv .git/HEAD ../HEAD.saved'
run_rc 'git status'
run_rc 'git symbolic-ref HEAD refs/heads/main'

snip 08-recover
note 'Recovery: HEAD is a one-line text file. Write it back, then let git init restore the template files.'
run "printf 'ref: refs/heads/main\n' > .git/HEAD"
run_rc 'git status'
run 'git init'

snip 09-verify
run 'find .git -type d | sort'
run 'git symbolic-ref HEAD'
run_rc 'cmp .git/HEAD ../HEAD.saved'
run_rc 'git fsck'

lab_end
