#!/usr/bin/env bash
# Lab 37.3, failure scenario and recovery: the mistaken merge is reverted instead of removed.
# The diff shrinks, the commit list does not, and a later merge of develop brings nothing.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-37-3-pr-500-changes
incident_load 06-pr-500-changes

snip 01-failure
run 'cd ravi'
m=$(git log --merges --format=%h main..feature/snippet-highlight)
note 'The tempting move: no forced push needed.'
run "git revert --no-edit -m 1 $m | head -3"
run 'git push'
note 'The pull request afterwards:'
run 'git diff --shortstat main...feature/snippet-highlight'
run 'git rev-list --count main..feature/snippet-highlight'

snip 02-consequence
note 'Later: the pull request is merged into main, and then develop is released into main.'
run 'git switch -q --detach main'
run "git merge -q --no-ff -m 'Merge pull request: snippet highlighting' feature/snippet-highlight"
run "git merge -m 'Release develop' origin/develop"
run 'ls tests'
run 'git switch -q feature/snippet-highlight'
run 'cd ..'
show_check

snip 03-recovery
run 'cd ravi'
note 'Rebuild the branch from the commits that are really its own:'
run "git rebase --onto $m^1 $m"
run 'git log --oneline main..feature/snippet-highlight'
run 'git push --force-with-lease --force-if-includes'
run 'cd ..'
show_check
incident_done
