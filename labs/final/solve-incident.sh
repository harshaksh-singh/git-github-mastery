#!/usr/bin/env bash
# Final test, lab "incident" (tokenbudget): the model diagnosis and repair as real transcripts
# for answer-keys/final-test-answers.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin final solve-incident
final_load incident

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'git log --oneline --graph --all --decorate'

snip 02-evidence
note "Ravi's search finds the commit. On which refs is it?"
run 'git log --all --oneline --grep="exactly reaches the budget"'
fix=$(git log --all --format=%h --grep='exactly reaches the budget')
run "git branch -a --contains $fix"
run "git tag --contains $fix"
run_rc "git merge-base --is-ancestor $fix v1.5.0"
note 'Was anything reverted on main? And is the change there under another commit ID?'
run 'git log --oneline --grep=Revert v1.5.0'
run 'git cherry -v main origin/release/1.4'
run 'git show v1.5.0:budget.py | head -2'
run 'git show v1.4.1:budget.py | head -2'

snip 03-repair
run "git cherry-pick -x $fix"
run 'git show --stat --format=%B HEAD'
run 'git tag -a v1.5.1 -m "Release 1.5.1: budget fix from 1.4.1"'
run 'git push origin main v1.5.1'

snip 04-verify
run 'git cherry -v main origin/release/1.4'
run 'git describe main'
run "git for-each-ref --format='%(refname:short) %(objecttype) %(*objectname:short)' refs/tags"
run 'cd ..'
show_check
final_done
