#!/usr/bin/env bash
# Chapter 27, section 27.10: what happens when both fix directions are used in one repository.
# A fix is made on main and cherry-picked down; a later fix is made on the release branch and
# merged upward. The upward merge brings the picked copy along and conflicts beside it.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch27 mixed-directions
fx_diverged
limits_fixed
hidden 'git commit -am "Fix limit 0 being treated as unlimited"'
hidden 'git switch release/1.4'
hidden 'git cherry-pick -x main'

snip 01-second-fix-on-release
note 'The first fix went main -> release/1.4 by cherry-pick. The second is made on the release branch:'
run 'sed -i.bak "s/return used < limit/return max(used, 0) < limit/" gateway/limits.py && rm gateway/limits.py.bak'
run 'git commit -q -am "Clamp negative usage counters"'
run 'git log --oneline --graph --all -5'

snip 02-merge-upward-conflicts
note '...and somebody carries it to main by merging the release branch upward:'
run 'git switch -q main'
run_rc 'git merge release/1.4'
run 'git diff'
run 'git merge --abort'
lab_end
