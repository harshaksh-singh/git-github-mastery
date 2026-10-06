#!/usr/bin/env bash
# Chapter 27, section 27.10: the two opposite conventions for the direction of a fix.
# (a) fix on the oldest branch that needs it and merge upward (the Git project's rule);
# (b) fix on main first and cherry-pick to the release branch (trunk-based practice);
# (c) what each convention does when somebody forgets a step.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch27 fix-direction
fx_diverged
cd "$LAB_DIR" || exit 1
hidden 'cp -R promptgate merge-up'
hidden 'cp -R promptgate pick-down'
hidden 'mv promptgate forgotten'

snip 01-start
run 'cd merge-up'
run 'git log --oneline --graph --decorate --all -5'

snip 02-merge-upward
note 'Convention A: commit the fix on the oldest branch that needs it...'
run 'git switch -q release/1.4'
limits_fixed
run 'git commit -q -am "Fix limit 0 being treated as unlimited"'
run 'git tag -a v1.4.1 -m "promptgate 1.4.1"'
note '...then merge that branch upward into main:'
run 'git switch -q main'
run 'git merge -m "Merge branch release/1.4 into main" release/1.4'
run 'git log --oneline --graph --decorate --all -6'

snip 03-one-commit
note 'One commit, one ID, contained in both lines:'
run 'git branch --contains v1.4.1'
run 'git log --oneline main..release/1.4'
note 'Empty: everything on the release branch is in main. That is an invariant you can test:'
run_rc 'git merge-base --is-ancestor release/1.4 main'

snip 04-pick-down
run 'cd ../pick-down'
note 'Convention B: commit the fix on main first...'
limits_fixed
run 'git commit -q -am "Fix limit 0 being treated as unlimited"'
run 'git switch -q release/1.4'
note '...then copy it down to the release branch:'
run 'git cherry-pick -x main'
run 'git tag -a v1.4.1 -m "promptgate 1.4.1"'
run 'git log --oneline --graph --decorate --all -6'

snip 05-two-commits
note 'Two commits, two IDs. The release branch is never merged into main:'
run_rc 'git merge-base --is-ancestor release/1.4 main'
note 'The check that replaces the ancestry test compares patches, not IDs:'
run 'git log --oneline --cherry-pick --right-only --no-merges main...release/1.4'
note 'Empty: every change on the release branch has an equivalent on main.'

snip 06-forgotten
run 'cd ../forgotten'
note 'The failure both conventions exist to prevent: a fix made only on the release branch.'
run 'git switch -q release/1.4'
limits_fixed
run 'git commit -q -am "Fix limit 0 being treated as unlimited"'
run 'git tag -a v1.4.1 -m "promptgate 1.4.1"'
note 'Weeks later release 1.5 is cut from main:'
run 'git switch -q main'
run 'git tag -a v1.5.0 -m "promptgate 1.5.0"'
run 'git show v1.5.0:gateway/limits.py | grep "limit ="'
run 'git show v1.4.1:gateway/limits.py | grep "limit ="'

snip 07-detect
note 'v1.5.0 ships the bug that v1.4.1 fixed. Either check finds it before the tag:'
run_rc 'git merge-base --is-ancestor release/1.4 main'
run 'git log --oneline --cherry-pick --right-only --no-merges main...release/1.4'
lab_end
