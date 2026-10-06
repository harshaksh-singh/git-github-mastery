#!/usr/bin/env bash
# Hands-on setup for Lab 2.2 (partial staging).
# Creates a repository whose working tree holds three unrelated edits to one file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/m02-setups.inc"
sandbox_begin hands-on m02-2
m02_2_setup || exit 1
printf 'Lab 2.2 is ready in %s\n' "$LAB_DIR/support-bot"
printf 'Next:  labs/shell m02-2   and then:  cd support-bot\n'
