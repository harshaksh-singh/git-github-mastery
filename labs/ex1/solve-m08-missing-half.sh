#!/usr/bin/env bash
# Replay of Exercise 8.10 (Level 5, a feature merged twice and half missing): diagnosis and
# repair as real transcripts for solutions/exercises-m06-m10.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m08-missing-half
exercise_load m08-missing-half

snip 01-observe
run 'cd you'
run 'git ls-tree -r --name-only main'
run 'git ls-tree -r --name-only origin/feature/batch-eval'
run 'git branch -r --merged origin/main'

snip 02-graph
run 'git log --graph --oneline main'

snip 03-who-deleted
note 'Which commit on the first-parent line of main deleted the file?'
run 'git log --first-parent --diff-filter=D --format="%h %an: %s" --name-status main -- runner'
r=$(git log --first-parent --diff-filter=D --format=%h -1 main -- runner)
m1=$(git log --merges --format=%h --grep='#41' main)
run "git show --stat --format=fuller $r"

snip 04-prove
note 'A revert of a merge applies the inverse of the diff from the first parent of the merge.'
run "git diff --stat $m1^1 $m1"
run "git diff --stat $r^ $r"
note 'After it, runner/ is exactly what it was before pull request #41 was merged:'
run_rc "git diff --quiet $m1^1 $r -- runner"

snip 05-why-clean
m2=$(git log --merges --format=%h --grep='#47' main)
run "git show -s --format='%h merged %p' $m2"
run "git log --oneline $m2^1..$m2^2"
run "git merge-base $m2^1 $m2^2 | cut -c1-7"
run 'git merge origin/feature/batch-eval'

snip 06-repair
run "git revert --no-edit $r"
run 'git ls-tree -r --name-only main'
run 'git diff --stat origin/feature/batch-eval main'

snip 07-publish
run 'git push'
run 'git log --graph --oneline -4'

snip 08-check
run 'cd ..'
show_check
exercise_done
