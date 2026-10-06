#!/usr/bin/env bash
# Lab 25.2 replay, Part A (offline rehearsal): the jq filters that the lab then passes to
# "gh api --jq". The input is api-examples/pulls-sample.json, a practice document written
# for this course with field names checked against the REST reference. It is not output
# from GitHub (see api-examples/README.md). Failure scenario: a filter written for an
# object, applied to an array. Uses /usr/bin/jq, which macOS ships.
# Lab manual: lab-manual/m25-github-cli-api.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 lab-25-2-api-queries
mkdir -p "$LAB_DIR/api-examples"
cp "$LAB_SCRIPT_DIR/api-examples/pulls-sample.json" "$LAB_DIR/api-examples/"

snip 01-shape
run 'cd api-examples'
run "jq 'type, length' pulls-sample.json"
run "jq '.[0] | keys' pulls-sample.json | tr -d ' \n'; echo"

snip 02-fields
run "jq -r '.[].title' pulls-sample.json"
run "jq -r '.[] | \"#\\(.number)  \\(.user.login)  \\(.head.ref) -> \\(.base.ref)\"' pulls-sample.json"

snip 03-select
run "jq -r '.[] | select(.draft | not) | select(.base.ref == \"main\") | .number' pulls-sample.json"
run "jq -c '[.[] | select(.user.login == \"asha-rao\") | .number]' pulls-sample.json"

snip 04-checkpoint
run "jq -c 'group_by(.base.ref) | map({base: .[0].base.ref, open: length})' pulls-sample.json"

snip 05-failure
run_rc "jq '.title' pulls-sample.json"

snip 06-recovery
run "jq '.[0].title' pulls-sample.json"
run "jq -c 'map(.title)' pulls-sample.json"

snip 07-verification
run "jq -r '.[] | select(.base.ref != \"main\") | \"#\\(.number) targets \\(.base.ref)\"' pulls-sample.json"

lab_end
