#!/usr/bin/env bash
# Lab 38.3, failure scenario and recovery: at step 9 a teammate has pushed since your fetch.
# The explicit lease refuses; a bare --force overwrites her commit; her clone brings it back.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-38-3-lease
incident_load 05-rebased-shared-branch
# Steps 1 to 8 of the solution, without transcript.
cd you || exit 1
quiet 'git fetch'
old=$(git rev-parse --short 'feature/online-serving@{3}')
new=$(git rev-parse --short 'origin/feature/online-serving@{1}')
mine=$(git rev-parse --short 'feature/online-serving@{1}')
examined=$(git rev-parse --short origin/feature/online-serving)
quiet "git reset --keep $mine && git rebase --onto $new $old"
cd "$LAB_DIR" || exit 1

snip 01-lease-refuses
note 'Meanwhile Asha updates her clone, commits and pushes:'
run 'cd asha'
run 'git pull -q --ff-only'
quiet "printf 'def warm_metrics(n):\n    metrics.gauge(\"store.warmed\", n)\n' > store/warm_metrics.py && git add store/warm_metrics.py"
as asha
run "git commit -q -m 'Report how many entries were warmed'"
run 'git push -q'
as you
note 'Step 9 in your clone, with the ID you examined:'
run 'cd ../you'
run_rc "git push --force-with-lease=feature/online-serving:$examined origin feature/online-serving"

snip 02-failure
note 'The tempting move: the lease is "in the way".'
run 'git push --force origin feature/online-serving'
run 'git log --oneline origin/main..origin/feature/online-serving'

snip 03-recovery
note "Her commit is no longer on the server. Her clone has it, and the standard instruction finds it:"
run 'cd ../asha'
run 'git fetch'
run 'git cherry -v origin/feature/online-serving feature/online-serving'
run 'git branch rescue/mine'
run 'git reset --keep origin/feature/online-serving'
as asha
run 'git cherry-pick rescue/mine'
run 'git push'
as you
run 'git log --oneline origin/main..origin/feature/online-serving'
run 'git branch -D rescue/mine'
lab_end
