#!/usr/bin/env bash
# Lab 29.2 replay: remove two controls from a copy of the secure workflow, watch the audit
# questions catch it, and restore the file.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch21a lab-29-2-controls
. "$LAB_SCRIPT_DIR/fixture.bash"
wf_repo

snip 01-baseline
run 'git status --short'
run "grep -c 'uses:' .github/workflows/12-secure.yml"
run_rc "grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |\$)'"
run "grep -c 'persist-credentials: false' .github/workflows/12-secure.yml"

snip 02-break
note 'A "cleanup" that many reviewers would approve: readable version tags, less boilerplate.'
run "sed -i.bak -e 's/@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1/@v7/' -e '/persist-credentials: false/d' .github/workflows/12-secure.yml"
run 'rm .github/workflows/12-secure.yml.bak'
run 'git diff --stat'

snip 03-detect
run_rc "grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |\$)'"
run_rc "grep -c 'persist-credentials: false' .github/workflows/12-secure.yml"

snip 04-recover
run 'git restore .github/workflows/12-secure.yml'
run 'git status --short'
run_rc "grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |\$)'"
run "grep -c 'persist-credentials: false' .github/workflows/12-secure.yml"

lab_end
