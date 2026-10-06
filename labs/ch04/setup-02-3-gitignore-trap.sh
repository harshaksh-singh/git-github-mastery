#!/usr/bin/env bash
# Hands-on setup for Lab 2.3 (the .gitignore trap and its fix).
# Creates a project directory with files and no repository yet.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/m02-setups.inc"
sandbox_begin hands-on m02-3
m02_3_setup || exit 1
printf 'Lab 2.3 is ready in %s\n' "$LAB_DIR/support-bot"
printf 'Next:  labs/shell m02-3   and then:  cd support-bot\n'
