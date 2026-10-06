#!/usr/bin/env bash
# Model solution of exercise 18.9 (Level 4): a clone that is shallow, single-branch and tagless
# at once. Each symptom is read from the clone's own files, then the clone is completed in place.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m18-searchstack
ex_load m18-searchstack
cd build || exit 1

snip 01-symptoms
run_rc 'git switch release/0.2'
run_rc 'git describe'
run 'git log --oneline'
run 'git fetch; echo "exit status: $?"'

snip 02-evidence
run 'git config list --local | grep -e ^remote -e ^branch'
run 'git rev-parse --is-shallow-repository'
run 'cat .git/shallow'
run 'git branch -r'
run 'git ls-remote origin'

snip 03-branches
run 'git remote set-branches origin "*"'
run 'git config get --all remote.origin.fetch'
run 'git fetch'
run 'git branch -r'

snip 04-history
run 'git rev-list --count --all'
run 'git fetch --unshallow'
run 'git rev-parse --is-shallow-repository'
run 'git rev-list --count --all'
run 'git tag'

snip 05-tags
run 'git config unset remote.origin.tagOpt'
run 'git fetch'
run 'git tag'

snip 06-verify
run 'git describe'
run 'git -C ../server.git describe main'
run 'git switch release/0.2'
run 'git describe'
run 'git switch -q main'
run 'git config list --local | grep -e ^remote'
run 'cd ..'
show_check
ex_done
