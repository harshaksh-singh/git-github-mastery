#!/usr/bin/env bash
# Exercise 31.5 (Module 31), model solution: the assessment step of a leak response, with
# built-in commands only. The secret is a dummy that no scanner pattern matches.
# The hands-on twin is setup-x31-5-exposure.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x31-exposure
scenario_x31_exposure

snip 01-tip-is-clean
run_rc 'git grep -n DUMMY-KEY'
run 'git log --oneline -3'

snip 02-entered-and-left
run 'git fetch -q'
run "git log --all -SDUMMY-KEY --format='%h %an %ad %s' --date=iso-strict --name-status"

snip 03-snapshots
run "git grep -l DUMMY-KEY \$(git rev-list --all) | cut -c1-7,41-"
run 'git rev-list --all | wc -l'

snip 04-refs
FIRST=$(git log --all -SDUMMY-KEY --diff-filter=A --format=%h -- config/settings.env)
run "git branch -a --contains $FIRST"
run "git tag --contains $FIRST"

snip 05-not-in-any-file
run "git log --all --grep=DUMMY-KEY --format='%h %d %s'"
run 'git log --all -SDUMMY-KEY --oneline -- config/storage.yaml'

lab_end
