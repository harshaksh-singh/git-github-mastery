#!/usr/bin/env bash
# Exercise 25.3 (Module 25): jq filters rehearsed offline. "gh api --jq" takes the same filter
# language. The inputs are practice documents written for this course (files/README.md says
# so); they are not output from GitHub. Uses /usr/bin/jq, which macOS ships.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex3 x25-jq
cp "$LAB_SCRIPT_DIR/files/pulls-pages.json" "$LAB_SCRIPT_DIR/files/rulesets-list.json" "$LAB_DIR/" || exit 1

snip 01-shape
run "jq 'length' pulls-pages.json"
run "jq 'map(length)' pulls-pages.json"
run "jq -c '.[0][0]' pulls-pages.json"

snip 02-a-count
run "jq 'add | length' pulls-pages.json"
snip 03-b-ready-for-main
run "jq -r 'add | .[] | select(.draft | not) | select(.base.ref == \"main\") | \"#\\(.number) \\(.title)\"' pulls-pages.json"
snip 04-c-per-base
run "jq -c 'add | group_by(.base.ref) | map({base: .[0].base.ref, count: length})' pulls-pages.json"
snip 05-d-oldest
run "jq -r 'add | sort_by(.created_at) | .[0] | \"\\(.number) \\(.created_at)\"' pulls-pages.json"
snip 06-e-humans
run "jq -r 'add | map(select(.user.login | endswith(\"[bot]\") | not)) | map(.user.login) | unique | .[]' pulls-pages.json"
snip 07-f-inactive-rulesets
run "jq -r '.[] | select(.enforcement != \"active\") | \"\\(.id) \\(.name) \\(.enforcement)\"' rulesets-list.json"
snip 08-wrong-without-add
run_rc "jq -r '.[] | .number' pulls-pages.json"

lab_end
