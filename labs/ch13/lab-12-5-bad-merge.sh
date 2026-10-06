#!/usr/bin/env bash
# Lab 12.5 replay: the wrong branch is merged into main, and the merge is a fast-forward, so
# there is no merge commit to remove. Recovery: ORIG_HEAD, then the merge that was intended.
# Failure: the tutorial recipe "git reset --hard HEAD~1" removes one of three commits and
# overwrites ORIG_HEAD. Recovery: read the reflog of main and go below the merge entry.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-5-bad-merge
fx_12_5

snip 01-start
run 'cd promptstore'
run 'git log --oneline --graph --all'

snip 02-disaster
note 'The branch you meant to merge is feature/citations.'
run 'git merge exp/few-shot'
run 'git log --oneline'
run 'cat system.txt'

snip 03-evidence
run 'git reflog -2'
run 'git log --oneline -1 ORIG_HEAD'
run 'git log --oneline ORIG_HEAD..HEAD'

snip 04-recover
run 'git reset --keep ORIG_HEAD'
run 'git log --oneline'
run 'git merge feature/citations'

snip 05-verification
run 'git log --oneline --graph --all'
run 'cat system.txt'
run 'git branch --contains exp/few-shot'

snip 06-failure
run 'cd ../promptstore-incident'
run 'git log --oneline'
note 'The recipe from a tutorial: "undo the merge" by dropping one commit.'
run 'git reset --hard HEAD~1'
run 'git log --oneline'
note 'Still two experiment commits. The other recipe:'
run 'git reset --hard ORIG_HEAD'
run 'git log --oneline'

snip 07-recovery-read
run 'git reflog show main'

snip 08-recovery
run "git log -g --format='%gd %gs' main | grep -A1 'merge exp/few-shot'"
run "git reset --keep 'main@{3}'"
run 'git log --oneline'
run 'git merge feature/citations'

snip 09-after
run 'git log --oneline --graph --all'
run 'cat system.txt'

lab_end
