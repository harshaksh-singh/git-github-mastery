#!/usr/bin/env bash
# Gate 1, hands-on variant A (tokmeter): the model diagnosis and repair as real transcripts for
# answer-keys/gate-1-fundamentals.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g1-a
gate_load gate-1-fundamentals/variant-a
as config                      # in the lab shell the identity comes from the repository's configuration

snip 01-observe
run 'cd tokmeter'
run 'git status -sb'
run 'git log --oneline'

snip 02-three-trees
note 'rates.yaml in the last commit, in the index, in the working tree'
run 'git show HEAD:rates.yaml'
run 'git show :rates.yaml'
run 'cat rates.yaml'
run 'git diff --cached --stat'
run 'git diff --stat'

snip 03-amend
run 'git add rates.yaml'
run 'git commit --amend --no-edit'
run "git log -2 --format='%h %an | %s'"
run 'git show HEAD:rates.yaml'

snip 04-ignored-but-tracked
run 'git check-ignore -v reports/last-run.json'
run 'git check-ignore -v --no-index reports/last-run.json'
run 'git ls-files -s reports'
run 'git log --oneline --diff-filter=A -- reports/last-run.json .gitignore'

snip 05-untrack
run 'git rm --cached reports/last-run.json'
run 'git status -sb'
run 'git commit -m "Stop tracking the generated report"'
run 'cat reports/last-run.json'
run 'git check-ignore -v reports/last-run.json'

snip 06-hidden-untracked
run_rc 'git check-ignore -v tokmeter/cache.py'
run 'git status -sb --untracked-files=all'
run 'git config get --show-scope --show-origin status.showUntrackedFiles'

snip 07-fix-setting
run 'git config unset status.showUntrackedFiles'
run 'git status -sb'
run 'git add tokmeter/cache.py'
run 'git commit -m "Add a cache for token counts"'
run 'git status -sb'
run 'git log --oneline'
run 'cd ..'
show_check
gate_done
