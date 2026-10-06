#!/usr/bin/env bash
# Hands-on setup for the local part of Lab 27.4: builds the warehouse-api repository in a fresh
# sandbox. Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m27-4
make_warehouse
scenario_deployed
printf 'Lab 27.4 (local part) is ready in %s\n' "$LAB_DIR/warehouse-api"
printf 'Open the lab shell there:  labs/shell m27-4\n'
printf 'First commands of the lab: cd warehouse-api && git for-each-ref refs/deployed\n'
