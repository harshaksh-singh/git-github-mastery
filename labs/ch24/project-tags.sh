#!/usr/bin/env bash
# Chapter 24, section 24.11: releases in a monorepo. Tags are repository-wide, so each project
# gets a prefix, and every question about "the last release" has to name the project.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch24 project-tags
. "$LAB_SCRIPT_DIR/fixture-orbit.bash"
orbit_build || exit 1
cd orbit || exit 1

snip 01-tags
run "git for-each-ref --format='%(refname:short) %(objecttype) -> %(*objectname:short) %(*subject)' refs/tags"
run "git tag -l 'gateway/*'"

snip 02-describe
note 'Without a pattern, describe answers with the nearest tag of any project:'
run 'git describe main'
note 'With a pattern it answers for one project:'
run "git describe --match 'gateway/v*' main"
run "git describe --match 'ranker/v*' main"

snip 03-changelog
note 'The range between two gateway releases contains everybody else too:'
run 'git log --oneline gateway/v1.0.0..gateway/v1.1.0 | wc -l'
note 'Limit it to the paths that go into the gateway:'
run 'git log --oneline gateway/v1.0.0..gateway/v1.1.0 -- services/gateway libs/schemas'
note 'Has anything that the gateway ships changed since its last release?'
run "git log --oneline gateway/v1.1.0..main -- services/gateway libs/schemas"
run_rc 'git diff --quiet gateway/v1.1.0 main -- services/gateway libs/schemas'
run_rc 'git diff --quiet ranker/v0.9.0 gateway/v1.0.0 -- libs/schemas'

lab_end
