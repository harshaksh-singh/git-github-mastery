#!/usr/bin/env bash
# Lab 37.4, failure scenario and recovery, as far as plain Git can show it: a depth-1 clone
# that has the tag refs still cannot describe HEAD, because the commits between HEAD and the
# tag are missing. An approximation of the runner with plain Git, not a run of the action.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-37-4-ci-passes-locally
incident_load 07-ci-passes-locally

snip 01-failure
note 'A clone of depth 1, and then the tags, also at depth 1:'
run 'git clone --quiet --depth 1 --no-tags "file://$PWD/server.git" runner-checkout'
run 'cd runner-checkout'
run "git fetch --quiet --depth 1 origin 'refs/tags/*:refs/tags/*'"
run 'git tag --list'
run 'git rev-list --count HEAD'
run_rc 'bash scripts/version.sh'

snip 02-recovery
run 'git fetch --quiet --unshallow'
run 'git rev-list --count HEAD'
run_rc 'bash scripts/version.sh'
run 'cd ..'
quiet 'rm -rf runner-checkout'
lab_end
