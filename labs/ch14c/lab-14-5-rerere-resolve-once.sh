#!/usr/bin/env bash
# Lab 14.5 replay: a rebase that stops twice is resolved once, aborted, and run again; rerere
# replays the first resolution. Failure: with rerere.autoUpdate a wrong recorded resolution is
# staged and committed without a question. Recovery: undo the rebase, forget the resolution,
# bring the conflict back and record the right one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14c lab-14-5-rerere-resolve-once
fx_14_5

snip 01-start
run 'cd ranker'
run 'git log --oneline --graph --all'
run 'git config set rerere.enabled true'

snip 02-first-stop
run_rc 'git -c advice.mergeConflict=false rebase main'
run 'ls .git/rr-cache'
run 'git rerere status'

snip 03-resolve-first
run "printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml"
run 'git add retrieval.yaml'
run_rc 'git -c advice.mergeConflict=false rebase --continue'

snip 04-abort
note 'The second conflict needs a decision from the scoring owner. Stop for today:'
run 'git rebase --abort'
run 'git status -sb'
run 'git log --oneline -1'
run 'for d in .git/rr-cache/*; do echo "$d:"; ls "$d"; done'

snip 05-second-rebase
note 'Next morning main has one more commit, and you rebase again:'
quiet 'git switch main'
quiet "printf 'bge-small: 384 dimensions\n' > MODELS.md && git add MODELS.md && git commit -m 'Document the embedding model'"
quiet 'git switch feature/hybrid'
run_rc 'git -c advice.mergeConflict=false rebase main'
run 'cat retrieval.yaml'
run 'git status -s'

snip 06-finish
run 'git add retrieval.yaml'
run_rc 'git -c advice.mergeConflict=false rebase --continue'
run "printf 'def score(q, d):\n    return 0.7 * bm25(q, d) / max_bm25 + 0.3 * dense(q, d)\n' > scoring.py"
run 'git add scoring.py'
run 'git rebase --continue'
run 'git log --oneline --graph --all'

snip 07-failure
run 'cd ../ranker-wrong'
run 'git config get rerere.autoUpdate'
run 'for f in .git/rr-cache/*/postimage; do cat "$f"; echo; done'
run_rc 'git -c advice.mergeConflict=false rebase main'
run_rc 'git -c advice.mergeConflict=false rebase --continue'
run 'git rebase --continue'

snip 08-detect
note 'Your own lines, before and after the rebase:'
run "git diff 'feature/hybrid@{1}' feature/hybrid -- retrieval.yaml"

snip 09-recovery-undo
run "git reset --hard 'feature/hybrid@{1}'"
run_rc 'git -c advice.mergeConflict=false rebase main'
run 'git rerere forget retrieval.yaml'
run 'git restore --merge retrieval.yaml'
run 'cat retrieval.yaml'

snip 10-recovery-record
run "printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml"
run 'git add retrieval.yaml'
run_rc 'git -c advice.mergeConflict=false rebase --continue'
run 'git rebase --continue'

snip 11-verification
run 'git show HEAD~2:retrieval.yaml'
run "git diff 'feature/hybrid@{1}' feature/hybrid -- retrieval.yaml"
run 'grep -l "top_k: 50" .git/rr-cache/*/postimage | wc -l'
run 'git log --oneline --graph --all'

lab_end
