#!/usr/bin/env bash
# Exercise 26.5 (Module 26): the two documented shell templates of a run step, applied to
# three small scripts. "bash -e {0}" is the implicit default on Linux and macOS runners;
# "bash --noprofile --norc -eo pipefail {0}" is what "shell: bash" gives.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x26-shell
hidden 'git init repo'
cd repo || exit 1
split_v1; commit_all 'Add fixed-size splitter'
printf 'false | tee test-log.txt\necho "tests finished"\n' > ../a.sh
printf 'VERSION=$(git describe 2>/dev/null)\necho "version is [$VERSION]"\n' > ../b.sh
printf 'export VERSION=$(git describe 2>/dev/null)\necho "version is [$VERSION]"\n' > ../c.sh

snip 01-scripts
run 'cat ../a.sh'
run 'cat ../b.sh'
run 'cat ../c.sh'
run_rc 'git describe'

snip 02-answers
for s in a b c; do
  run_rc "bash -e ../$s.sh"
  run_rc "bash --noprofile --norc -eo pipefail ../$s.sh"
done

lab_end
