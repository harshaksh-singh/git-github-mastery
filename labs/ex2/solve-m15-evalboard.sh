#!/usr/bin/env bash
# Model solution of exercise 15.9 (Level 4): a submodule pointer that a teammate moved backwards
# with "git commit -a", already pushed. The fix is a new commit that moves it forward again.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m15-evalboard
ex_load m15-evalboard
cd you || exit 1

snip 01-observe
run 'git status -sb'
run 'git submodule status'
run 'git diff --submodule=log'

snip 02-two-machines
run 'git ls-tree HEAD vendor/'
run 'git -C vendor/metrickit describe HEAD'
run "git -C vendor/metrickit describe \$(git rev-parse HEAD:vendor/metrickit)"
run "python3 -B -c 'import board; print(\"import ok\")'"

snip 03-history-of-the-pointer
run "git log --format='%h %an: %s' -- vendor/metrickit"
bad=$(git log --format=%h -1 -- vendor/metrickit)
run "git show --stat --format='%h %an: %s' $bad"
run "git show --submodule=log --format= $bad -- vendor/metrickit"

snip 04-fix
run "git tag answer/rollback $bad"
run 'git add vendor/metrickit'
run 'git status -s'
run "git commit -q -m 'Use metrickit 0.2.0 again' -m 'Commit $bad moved the submodule pointer back to 0.1.0 by accident. The dashboard needs rouge_l, which 0.2.0 added.'"
run 'git ls-tree HEAD vendor/'
run 'git push'

snip 05-verify
run 'git submodule status'
run 'git status -sb'
run 'git -c protocol.file.allow=always clone -q --recurse-submodules ../remotes/evalboard.git ../verify'
run "(cd ../verify && python3 -B -c 'import board; print(\"import ok\")')"
run 'rm -rf ../verify'

snip 06-prevent
run 'git config set submodule.recurse true'
run 'cd ..'
show_check
ex_done
