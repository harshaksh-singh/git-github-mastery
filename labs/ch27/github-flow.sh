#!/usr/bin/env bash
# Chapter 27, section 27.9: one release and one hotfix under GitHub Flow. One long-lived branch,
# releases are tags on main, and a hotfix is one more short branch merged into main.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch27 github-flow
fx_ready_to_release

snip 01-release
note 'Two pull requests are merged. main is deployable, so the release is a tag on main:'
run 'git log --oneline --graph --decorate'
run 'git tag -a v1.4.0 -m "promptgate 1.4.0"'

fx_batch_feature main

snip 02-main-moves-on
note 'After the release, pull request #43 lands. main is ahead of what customers run:'
run 'git log --oneline --decorate v1.4.0..main'

snip 03-hotfix
note 'Production reports that suspended tenants (limit 0) are not blocked.'
run 'git switch -c hotfix/suspended-tenant main'
limits_fixed
run 'git diff'
run 'git commit -q -am "Fix limit 0 being treated as unlimited"'
run 'git switch -q main'
run 'git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant'
run 'git branch -d hotfix/suspended-tenant'
run 'git tag -a v1.4.1 -m "promptgate 1.4.1"'

snip 04-graph
run 'git log --oneline --graph --decorate'

snip 05-what-ships
note 'What does a customer get when moving from v1.4.0 to v1.4.1?'
run 'git log --oneline --no-merges v1.4.0..v1.4.1'
run 'git diff --stat v1.4.0 v1.4.1'
run 'git branch --list'
lab_end
