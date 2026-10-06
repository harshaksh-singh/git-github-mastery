#!/usr/bin/env bash
# Chapter 14C, section 14C.3: the MERGE_RR.lock failure and its recovery, on demand. In real use
# the lock is held for a moment by "git rerere gc", which automatic maintenance starts in the
# background after a commit. Here an "exec" line of the rebase creates the lock file after each
# replayed commit, so that the failure appears every time and in the same place.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14c rerere-lock
_fx_14_5_repo ranker
cd ranker || exit 1
quiet 'git config set rerere.enabled true'

snip 01-locked
note 'Stand-in for the background task: after each replayed commit, hold the lock that rerere needs.'
run_rc "git -c advice.mergeConflict=false rebase -x 'touch .git/MERGE_RR.lock' main"
run "printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml && git add retrieval.yaml"
run_rc 'git -c advice.mergeConflict=false rebase --continue'

snip 02-recover
run 'git status -s'
note 'The real background task removes its lock when it ends. Remove the stand-in by hand:'
run 'rm .git/MERGE_RR.lock'
note 'rerere never saw this conflict. Run it yourself:'
run 'git rerere status'
run 'git rerere'
run 'git rerere status'

quiet 'git rebase --abort'
lab_end
