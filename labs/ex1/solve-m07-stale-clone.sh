#!/usr/bin/env bash
# Replay of Exercise 7.9 (Level 4, a clone that has not talked to the server for a week):
# diagnosis and repair as real transcripts for solutions/exercises-m06-m10.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m07-stale-clone
exercise_load m07-stale-clone

snip 01-symptoms
run 'cd you'
run 'git status -sb'
run_rc 'git push'
run 'git branch -vv'

snip 02-server
note 'What the clone believes, and what the server says when asked.'
run 'git for-each-ref --format="%(objectname:short) %(refname)" refs/remotes'
run 'git ls-remote --heads origin | cut -c1-7,41-'

snip 03-fetch
run 'git fetch --prune'
run 'git status -sb'
run 'git branch -vv'
run 'git log --graph --oneline main origin/main'

snip 04-main
run 'git rebase origin/main'
run 'git log --graph --oneline main'
run 'git push'

snip 05-tokenizer
run 'git switch -q feature/tokenizer'
run_rc 'git push'
run 'git log --oneline origin/feature/tokenizer..feature/tokenizer'
run 'git branch --set-upstream-to=origin/feature/tokenizer'
run 'git status -sb'
run 'git push'

snip 06-gone
run 'git switch -q main'
run "git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads"
run 'git branch -d feature/lru'
run 'git branch -vv'

snip 07-check
run 'cd ..'
show_check
exercise_done
