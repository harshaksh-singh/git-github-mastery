#!/usr/bin/env bash
# Chapter 15, section 15.16: jq filters rehearsed offline. "gh api --jq" takes the same
# filter language. The input is api-examples/pulls-sample.json, a practice document written
# for this course with field names checked against the REST reference. It is not output
# from GitHub (see api-examples/README.md). Uses /usr/bin/jq, which macOS ships.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 jq-rehearsal
cp "$LAB_SCRIPT_DIR/api-examples/pulls-sample.json" "$LAB_DIR/pulls-sample.json"

snip 01-one-field
run "jq '.[].title' pulls-sample.json"
run "jq -r '.[].title' pulls-sample.json"

snip 02-several-fields
run "jq -r '.[] | \"#\\(.number)  \\(.user.login)  \\(.head.ref) -> \\(.base.ref)\"' pulls-sample.json"

snip 03-select
run "jq -r '.[] | select(.draft | not) | select(.base.ref == \"main\") | .number' pulls-sample.json"
run "jq '[.[] | select(.user.login == \"asha-rao\")] | length' pulls-sample.json"

snip 04-reshape
run "jq -c '.[] | {number, draft, base: .base.ref}' pulls-sample.json"

lab_end
