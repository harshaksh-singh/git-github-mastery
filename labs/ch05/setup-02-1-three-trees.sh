#!/usr/bin/env bash
# Hands-on setup for Lab 2.1 (the three-trees prediction table).
# Creates the starting repository in the hands-on sandbox and prints where to go.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/m02-setups.inc"
sandbox_begin hands-on m02-1
m02_1_setup || exit 1
printf 'Lab 2.1 is ready in %s\n' "$LAB_DIR/support-bot"
printf 'Next:  labs/shell m02-1   and then:  cd support-bot\n'
