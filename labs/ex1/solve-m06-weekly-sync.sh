#!/usr/bin/env bash
# Replay of Exercise 6.10 (Level 5, the weekly sync that conflicts more every week): diagnosis and
# repair as real transcripts for solutions/exercises-m06-m10.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m06-weekly-sync
exercise_load m06-weekly-sync

snip 01-reproduce
run 'cd you'
run 'git status -sb'
run_rc 'git merge --squash develop'
run 'git diff'
run 'git reset --merge'
run 'git status --short'

snip 02-graph
run 'git log --graph --oneline --all'
run 'git log --oneline main..develop'
run 'git show -s --format="%h %s" "$(git merge-base main develop)"'

snip 03-hypotheses
note 'Hypothesis "the hotfix": which files did the only direct commit on main touch?'
run 'git log --oneline --no-merges --stat --author=Ravi main'
note 'Hypothesis "the syncs left no ancestry": how many parents do the sync commits have?'
run 'git log --format="%h parents: %p | %s" --grep=Sync main'

snip 04-find-synced
note 'Which develop commit does main already contain? Compare each one with main.'
run 'for c in $(git rev-list develop); do printf "%s  " "$(git log -1 --format="%h %s" $c)"; git diff --shortstat $c main | grep . || echo " identical"; done'
synced=$(git log --format=%h -1 --grep='Add a default output length' develop)
run "git diff --stat $synced main"

snip 05-record
run "git merge -s ours -m 'Record that main contains develop up to $synced (squash syncs of weeks 36 and 37)' $synced"
run 'git diff --stat HEAD~1 HEAD'
run 'git show -s --format="%h %s" "$(git merge-base main develop)"'
run 'git log --oneline main..develop'

snip 06-sync
run 'git merge -m "Sync develop into main (week 38)" develop'
run 'git log --graph --oneline -8'
run 'git diff --stat develop main'
run 'cat sampler/config.py'

snip 07-publish
run 'git push origin main'
run 'git log --oneline main..develop'
run 'git merge-base --is-ancestor develop main && echo "develop is contained in main"'

snip 08-check
run 'cd ..'
show_check
exercise_done
