#!/usr/bin/env bash
# Replay of the local part of Lab 27.1: what identifies the commit an image is built from.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch20b lab-27-1-image-identity
make_warehouse

snip 01-identity
run 'git rev-parse HEAD'
run 'git status --porcelain'
run 'git tag --points-at HEAD'
run "git describe --tags --match 'v*'"

snip 02-failure
note 'A build from a working tree that differs from the commit it claims to be:'
run "printf '\n# local tweak\n' >> src/warehouse/rules.py"
run 'git status --short'
run "git describe --tags --match 'v*' --dirty"

snip 03-recovery
run 'git restore src/warehouse/rules.py'
run "git describe --tags --match 'v*' --dirty"
note 'A release: tag the commit, and the name becomes the tag itself.'
run 'git tag -a v1.2.0 -m "Release 1.2.0"'
run 'git tag --points-at HEAD'
run "git describe --tags --match 'v*' --dirty"
lab_end
