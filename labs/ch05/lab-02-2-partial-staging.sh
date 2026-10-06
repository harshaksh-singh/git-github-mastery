#!/usr/bin/env bash
# Replay of Lab 2.2: partial staging. One file holds a bug fix, a policy change and a debug
# line; the lab turns them into two commits and throws the debug line away.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/keys.inc"
. "$LAB_SCRIPT_DIR/m02-setups.inc"
lab_begin ch05 lab-02-2-partial-staging
m02_2_setup || exit 1
cd support-bot || exit 1

snip 01-start
run 'git status --short'
run 'git diff'

snip 02-first-pass
note 'Answers: n (threshold), s (split), y (the fix), n (debug line).'
run_keys 'n s y n' 'git add -p src/evaluate.py'

snip 03-check-before-commit
run 'git status --short'
run 'git diff --cached'

snip 04-first-commit
run 'git commit -m "Compare answers without case or surrounding space"'
run 'git diff --stat'

snip 05-second-pass
note 'Answers: y (threshold), n (debug line).'
run_keys 'y n' 'git add -p src/evaluate.py'
run 'git commit -m "Raise the pass threshold to 0.8"'

snip 06-discard-the-rest
run 'git diff'
run 'git restore src/evaluate.py'
run 'git status --short'
run 'git log --oneline'

snip 07-failure-setup
note 'Failure scenario. Two new edits: a docstring worth committing and a debug line that is not.'
sed -e '1s/.*/"""Offline evaluation for the support bot (exact-match accuracy)."""/' \
    -e 's/^    score = accuracy(cases, predictions)$/&\
    print("DEBUG score:", score)/' src/evaluate.py > evaluate.tmp && mv evaluate.tmp src/evaluate.py
run 'git diff'

snip 08-failure
note 'Stage only the docstring (answers: y, n) ...'
run_keys 'y n' 'git add -p src/evaluate.py'
note '... and then commit with -a, which stages every tracked change again.'
run 'git commit -a -m "Name the metric in the module docstring"'
run 'git show --stat --format=%s HEAD'
run 'git grep -n DEBUG HEAD'

snip 09-recovery
note 'The commit is local. Move the branch back one commit; the working tree keeps both edits.'
run 'git reset HEAD~1'
run 'git status --short'
run_keys 'y n' 'git add -p src/evaluate.py'
run 'git diff --cached --stat'
run 'git commit -m "Name the metric in the module docstring"'
run 'git restore src/evaluate.py'

snip 10-verification
run 'git status --short'
run 'git show --stat --format=%s HEAD'
run_rc 'git grep -n DEBUG HEAD'
run 'git log --oneline'

lab_end
