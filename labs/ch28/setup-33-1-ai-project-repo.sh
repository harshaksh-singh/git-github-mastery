#!/usr/bin/env bash
# Hands-on setup for Lab 33.1: an empty sandbox with the project files as a kit (plain files,
# no repository) and an empty data store. Running it again rebuilds the sandbox.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m33-1
fx_kit
[ -f "$LAB_DIR/kit/tools/nbstrip.py" ] || { echo 'setup: kit is incomplete' >&2; exit 1; }

printf 'Lab 33.1 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m33-1\n'
printf 'First command of the lab:  git init -q docqa && cd docqa\n'
