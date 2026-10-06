#!/usr/bin/env bash
# Replay of the local steps of Lab 26.5: predict from Git alone whether a workflow with
# `paths: java-service/**` starts for a pull request.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch20a lab-26-5-path-filter
scenario_base
cd "$LAB_DIR/you/inventory-api" || exit 1

snip 01-docs-only
run 'git switch -c docs/java-readme'
run 'echo "The Java module lives in java-service/." >> README.md'
run 'git commit --quiet -am "Mention the Java module"'
run 'git diff --name-only origin/main...HEAD'
run_rc 'git diff --quiet origin/main...HEAD -- "java-service/**" ".github/workflows/05-java-tests.yml"'
note 'Status 0: nothing under the filtered paths changed. The workflow does not start.'

snip 02-java-change
run "sed -i.bak 's/0.1.0/0.1.1/' java-service/pom.xml && rm java-service/pom.xml.bak"
run 'git commit --quiet -am "Bump java-service to 0.1.1"'
run 'git diff --name-only origin/main...HEAD'
run_rc 'git diff --quiet origin/main...HEAD -- "java-service/**" ".github/workflows/05-java-tests.yml"'
note 'Status 1: a filtered path changed somewhere in the pull request. The workflow starts.'
lab_end
