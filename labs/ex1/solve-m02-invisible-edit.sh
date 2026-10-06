#!/usr/bin/env bash
# Replay of Exercise 2.9 (Level 4, "Git does not see my edits"): diagnosis and repair as real
# transcripts for solutions/exercises-m01-m05.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m02-invisible-edit
exercise_load m02-invisible-edit
as asha

snip 01-symptom
run 'cd annotator'
run 'git status'
run 'git diff'
run 'cat configs/eval.yaml'
run 'git show HEAD:configs/eval.yaml'

snip 02-evidence
note 'Not ignored: the paths are tracked, and no ignore rule matches them.'
run 'git ls-files configs annotator'
run_rc 'git check-ignore -v configs/eval.yaml annotator/agreement.py'
note 'The index is asked about its per-entry bits.'
run 'git ls-files -v'

snip 03-repair
run 'git update-index --no-skip-worktree configs/eval.yaml'
run 'git update-index --no-assume-unchanged annotator/agreement.py'
run 'git ls-files -v'
run 'git status --short'
run 'git diff'

snip 04-commit
run 'git add configs/eval.yaml annotator/agreement.py'
run 'git commit -m "Raise agreement threshold to 0.90 and guard empty votes"'
run 'git status --short'
run 'git diff HEAD --stat -- configs/local.yaml'
run 'cat configs/local.yaml'

snip 05-check
run 'cd ..'
show_check
exercise_done
