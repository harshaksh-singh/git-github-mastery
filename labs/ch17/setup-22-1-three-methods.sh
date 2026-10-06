#!/usr/bin/env bash
# Hands-on setup for Lab 22.1: three copies of one repository with the same open pull request.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m22-1
scenario_three_methods
for m in merge squash rebase; do
  require_ref "$LAB_DIR/$m/server.git" refs/heads/feature/priority-routing
  require_ref "$LAB_DIR/$m/you" refs/heads/feature/priority-routing
done

printf 'Lab 22.1 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m22-1\n'
printf 'First command of the lab:  ls\n'
