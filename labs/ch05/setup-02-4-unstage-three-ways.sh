#!/usr/bin/env bash
# Hands-on setup for Lab 2.4 (unstage three ways and compare the results).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/m02-setups.inc"
sandbox_begin hands-on m02-4
m02_4_setup || exit 1
printf 'Lab 2.4 is ready in %s\n' "$LAB_DIR/support-bot"
printf 'Next:  labs/shell m02-4   and then:  cd support-bot\n'
