#!/usr/bin/env bash
# Predicting a `paths` filter with plain Git. The documentation says path filters are evaluated
# on a three-dot diff for pull requests and a two-dot diff for pushes; these are those diffs.
# Chapter 20A, section 20A.4, and Lab 26.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch20a path-filter
scenario_pull_request
cd "$LAB_DIR/you/inventory-api" || exit 1
hidden 'git fetch origin'

snip 01-pull-request
note 'Pull request: base main, head feature/reorder-report. Three dots: what the branch changed.'
run 'git diff --name-only origin/main...feature/reorder-report'
note 'Does any changed path match java-service/** ?'
run_rc 'git diff --quiet origin/main...feature/reorder-report -- "java-service/**"'
note 'Exit status 0 means no difference under that path: the Java workflow would not start.'

snip 02-two-dots-would-mislead
note 'Two dots compare the two tips, so the change made on main shows up as if it were yours:'
run 'git diff --name-only origin/main..feature/reorder-report'

snip 03-push
note 'Push: the diff from the old tip of the branch to the new one.'
run 'git switch --quiet feature/reorder-report'
run 'before=$(git rev-parse HEAD)'
hidden "sed -i.bak 's/0.1.0/0.2.0/' java-service/pom.xml && rm java-service/pom.xml.bak"
run 'git commit --quiet -am "Bump java-service to 0.2.0"'
run 'git diff --name-only $before..HEAD'
run_rc 'git diff --quiet $before..HEAD -- "java-service/**"'
note 'Exit status 1: a path under java-service/ changed, so the Java workflow would start.'
lab_end
