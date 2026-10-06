#!/usr/bin/env bash
# Chapter 21A, section 21A.16: five read-only questions asked of workflows/12-secure.yml with grep.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch21a workflow-audit
. "$LAB_SCRIPT_DIR/fixture.bash"
wf_repo
cd .github/workflows || exit 1

snip 01-trigger-permissions
note 'Question 1: which events start it? Question 2: what may the token do?'
run "grep -n -A4 '^on:' 12-secure.yml"
run "grep -n -A2 'permissions:' 12-secure.yml"

snip 02-uses
note 'Question 3: whose code runs, and is every reference a full commit ID?'
run "grep -n 'uses:' 12-secure.yml"
note 'References that are not 40 hexadecimal characters (no output means none):'
run_rc "grep -n 'uses:' 12-secure.yml | grep -vE '@[0-9a-f]{40}( |\$)'"

snip 03-expressions
note 'Question 4: where does an expression appear, and is any of them inside a script?'
run "grep -n '\${{' 12-secure.yml"

snip 04-secrets
note 'Question 5: which stored secrets does it read? (no output means none)'
run_rc "grep -n 'secrets\\.' 12-secure.yml"
run "grep -n -B1 -A1 'id-token' 12-secure.yml"

lab_end
