#!/usr/bin/env bash
# Hands-on setup for Lab 24.3, local part: an empty sandbox for the three commits whose
# verification state you will predict. $GIT_MASTERY_LABS/hands-on/m24-3.
. "$(dirname "$0")/../lib/lab-env.sh"
sandbox_begin hands-on m24-3
quiet 'git init signing-states'
printf 'Lab 24.3 (local part) is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m24-3     then:  cd signing-states\n'
