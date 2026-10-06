#!/usr/bin/env bash
# Replay of the local part of Lab 27.2: the same commit gives the same bytes, and a digest
# detects any change to them.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch20b lab-27-2-artifact-digest
make_warehouse

snip 01-same-bytes
run 'git archive --format=tar --prefix=warehouse-api/ HEAD | shasum -a 256'
run 'git archive --format=tar --prefix=warehouse-api/ HEAD | shasum -a 256'
run 'git archive --format=tar --prefix=warehouse-api/ v1.1.0 | shasum -a 256'

snip 02-failure
run 'git archive --format=tar --prefix=warehouse-api/ -o ../build.tar HEAD'
run '(cd .. && shasum -a 256 build.tar > build.tar.sha256)'
note 'Something between the build job and the deploy job changes one byte:'
run "printf 'x' >> ../build.tar"
run_rc '(cd .. && shasum -a 256 -c build.tar.sha256)'

snip 03-recovery
note 'Do not repair the file. Produce it again from the commit and compare.'
run 'git archive --format=tar --prefix=warehouse-api/ -o ../build.tar HEAD'
run_rc '(cd .. && shasum -a 256 -c build.tar.sha256)'
lab_end
