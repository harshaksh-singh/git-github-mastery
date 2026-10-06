#!/usr/bin/env bash
# Lab 8.1 replay: the reset prediction table. Five copies of one repository, one reset mode
# each, then ORIG_HEAD, a double hard reset as the failure, and recovery through the reflog.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
lab_begin ch11 lab-08-1-reset-prediction
fx_08_1

snip 01-start
run 'cd promptlab'
run 'git log --oneline'
run 'git show HEAD:prompt.txt'
run 'git show :prompt.txt'
run 'cat prompt.txt'
run 'git status -s'

snip 02-soft
run 'cd ../promptlab-soft'
run 'git reset --soft HEAD~1'
run 'git log --oneline'
run 'git show HEAD:prompt.txt'
run 'git show :prompt.txt'
run 'cat prompt.txt'
run 'git status -s'

snip 03-mixed
run 'cd ../promptlab-mixed'
run 'git reset --mixed HEAD~1'
run 'git show HEAD:prompt.txt'
run 'git show :prompt.txt'
run 'cat prompt.txt'
run 'git status -s'

snip 04-hard
run 'cd ../promptlab-hard'
run 'git reset --hard HEAD~1'
run 'git show HEAD:prompt.txt'
run 'git show :prompt.txt'
run 'cat prompt.txt'
run 'git status -s'

snip 05-keep
run 'cd ../promptlab-keep'
run_rc 'git reset --keep HEAD~1'
run 'git log --oneline -1'
run 'git status -s'

snip 06-merge
run 'cd ../promptlab-merge'
run_rc 'git reset --merge HEAD~1'
run 'git log --oneline -1'
run 'git status -s'

snip 07-orig-head
run 'cd ../promptlab-soft'
run 'git rev-parse --short ORIG_HEAD'
run 'git reflog -2'
run 'git reset --soft ORIG_HEAD'
run 'git log --oneline -1'
run 'git status -s'

snip 08-failure
run 'cd ../promptlab-hard'
run 'git reset --hard HEAD~1'
run 'git log --oneline'
run 'git reset --hard ORIG_HEAD'
run 'git log --oneline'

snip 09-recovery
run 'git reflog'
run 'git reset --hard HEAD@{3}'
run 'git log --oneline'

snip 10-staged-version
run 'git fsck --lost-found'
run 'git cat-file -p 7f9b38a'
run "printf 'v5: only in the working tree\n' | git hash-object --stdin"
run_rc 'git cat-file -t 1732b24d8b7877d2e96d0fa80ca928851d408b10'

snip 11-verification
run 'git log --oneline'
run 'git status -s'
run 'git show HEAD:prompt.txt'

lab_end
