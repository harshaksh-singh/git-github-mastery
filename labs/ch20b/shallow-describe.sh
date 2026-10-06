#!/usr/bin/env bash
# Chapter 20B, section 20B.11: why a tag-derived version works on the laptop and fails in a job.
# A shallow, tagless clone stands in for what actions/checkout fetches by default.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch20b shallow-describe
make_warehouse

snip 01-laptop
note 'Your clone: full history, all tags.'
run 'git log --oneline --decorate'
run "git describe --tags --match 'v*'"

snip 02-runner
note 'A clone with one commit and no tags, which is what the checkout action fetches by default:'
run 'cd ..'
run 'git clone --quiet --depth 1 --no-tags "file://$PWD/warehouse-api" runner'
run 'cd runner'
run 'git log --oneline --decorate'
run 'git tag --list'
run 'git rev-parse --is-shallow-repository'
run_rc "git describe --tags --match 'v*'"

snip 03-tags-without-history
note 'Fetching the tags alone, still at depth 1, brings the tag objects but not the path to them:'
run 'git fetch --quiet --depth 1 origin "refs/tags/*:refs/tags/*"'
run 'git tag --list'
run_rc "git describe --tags --match 'v*'"
run 'git rev-list --count HEAD'

snip 04-full-history
note 'With the whole history the tag is reachable from HEAD again:'
run 'git fetch --quiet --unshallow --tags'
run 'git rev-parse --is-shallow-repository'
run 'git rev-list --count HEAD'
run "git describe --tags --match 'v*'"
lab_end
