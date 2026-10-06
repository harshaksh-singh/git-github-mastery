#!/usr/bin/env bash
# Hands-on setup for Lab 7.1: a bare server and two clones, watching every ref.
# This lab builds everything by hand, so the starting state is an empty sandbox.
# Running the script again throws the sandbox away and gives you a fresh, empty one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m07-1
# sandbox_begin writes a per-sandbox Git configuration under home/. The lab shell uses its
# own configuration, so the directory is removed to leave the sandbox empty for "ls".
rm -rf "$LAB_DIR/home"
[ -z "$(ls -A "$LAB_DIR")" ] || { printf 'fixture: sandbox %s is not empty\n' "$LAB_DIR" >&2; exit 1; }

printf 'Lab 7.1 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m07-1\n'
printf 'First command of the lab:  git init --bare server/support-bot.git\n'
