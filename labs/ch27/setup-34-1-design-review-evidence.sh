#!/usr/bin/env bash
# Hands-on setup for Lab 34.1: builds "riskscore", the repository of the company in the Level 8
# design review, in a sandbox of its own. Running it again rebuilds the sandbox.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m34-1
fx_lab_34_1
require_ref "$LAB_DIR/riskscore" refs/heads/release/2.0
require_ref "$LAB_DIR/riskscore" refs/tags/v2.1.0

printf 'Lab 34.1 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m34-1\n'
printf 'First command of the lab:  cd riskscore\n'
