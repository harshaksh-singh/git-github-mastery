#!/usr/bin/env bash
# Hands-on setup for Lab 33.3: the docqa repository after the history has moved on, with two
# recorded runs in ../tracker. Running it again rebuilds the sandbox.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m33-3
fx_lab_33_3
require_ref "$LAB_DIR/docqa" refs/tags/v0.1.0
[ -f "$LAB_DIR/tracker/tuned/uncommitted.patch" ] || { echo 'setup: tracker is incomplete' >&2; exit 1; }

printf 'Lab 33.3 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m33-3\n'
printf 'First command of the lab:  cd docqa\n'
