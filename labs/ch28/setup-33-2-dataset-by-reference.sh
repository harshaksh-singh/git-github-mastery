#!/usr/bin/env bash
# Hands-on setup for Lab 33.2: the docqa repository with its tooling committed and the ticket
# data set on disk, ignored and not yet versioned. Running it again rebuilds the sandbox.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m33-2
fx_lab_33_2
require_ref "$LAB_DIR/docqa" refs/heads/main

printf 'Lab 33.2 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m33-2\n'
printf 'First command of the lab:  cd docqa\n'
