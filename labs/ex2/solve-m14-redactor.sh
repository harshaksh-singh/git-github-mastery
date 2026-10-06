#!/usr/bin/env bash
# Model solution of exercise 14.9 (Level 4): commits made on the detached HEAD of a linked
# worktree that was removed. No reflog is left; git fsck finds them.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m14-redactor
ex_load m14-redactor
cd redactor || exit 1

snip 01-observe
run 'git status -sb'
run 'git worktree list'
run 'git log --oneline --all --graph'
run 'git reflog -4'
run 'ls .git/worktrees 2>/dev/null | wc -l'

snip 02-fsck
run 'git fsck --lost-found'
c=$(ls .git/lost-found/commit)
run "git log --oneline --graph ${c:0:7}"
run "git show --stat --format='%h %an %ad%n%s' ${c:0:7}"

snip 03-anchor
run "git branch hotfix/pii-patterns ${c:0:7}"
run 'git log --oneline --decorate v2.1.0..hotfix/pii-patterns'
run 'git describe hotfix/pii-patterns'
run 'git fsck'

snip 04-the-third-pattern
run 'git fsck --unreachable --no-reflogs'
run 'git show hotfix/pii-patterns:redactor/patterns.py'
run 'git status -sb'
run 'cd ..'
show_check
ex_done
