#!/usr/bin/env bash
# Hands-on setup for the local part of Lab 28.1: builds the warehouse-api repository in a fresh
# sandbox. Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m28-1
make_warehouse
scenario_branches
printf 'Lab 28.1 (local part) is ready in %s\n' "$LAB_DIR/warehouse-api"
printf 'Open the lab shell there:  labs/shell m28-1\n'
printf 'First commands of the lab: cd warehouse-api && git log --oneline --decorate\n'
