#!/usr/bin/env bash
# Hands-on setup for the Git half of Lab 23.2: a repository whose main branch has two CODEOWNERS
# files, and your branch that changes four paths, one of them the CODEOWNERS file.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m23-2
scenario_codeowners
require_ref "$LAB_DIR/you/ticket-router" refs/heads/docs/escalation-runbook

printf 'Lab 23.2 (Git half) is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m23-2\n'
printf 'First command of the lab:  cd you/ticket-router\n'
