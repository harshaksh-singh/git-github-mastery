#!/usr/bin/env bash
# Chapter 27, section 27.9: the same release and the same hotfix with a release branch.
# The release is cut from main, main moves on, the fix lands on main first and is
# cherry-picked to the release branch (the "fix on main first" convention).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch27 release-branch
fx_ready_to_release

snip 01-cut
note 'The same two pull requests are merged. The release gets a branch of its own:'
run 'git switch -c release/1.4 main'
run 'git tag -a v1.4.0 -m "promptgate 1.4.0"'
run 'git switch -q main'

fx_batch_feature main

snip 02-main-moves-on
run 'git log --oneline --decorate release/1.4..main'

snip 03-fix-on-main
note 'The fix is made and reviewed on main first:'
run 'git switch -c hotfix/suspended-tenant main'
limits_fixed
run 'git commit -q -am "Fix limit 0 being treated as unlimited"'
run 'git switch -q main'
run 'git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant'
run 'git branch -d hotfix/suspended-tenant'

fix=$(git rev-parse --short 'HEAD^2')
snip 04-backport
note 'Then the one commit is copied to the release branch and released from there:'
run 'git switch -q release/1.4'
run "git cherry-pick -x $fix"
run 'git tag -a v1.4.1 -m "promptgate 1.4.1"'
run 'git log -1 --format=%B'

snip 05-graph
run 'git log --oneline --graph --decorate --all'

snip 06-what-ships
note 'What does a customer get when moving from v1.4.0 to v1.4.1?'
run 'git log --oneline --no-merges v1.4.0..v1.4.1'
run 'git diff --stat v1.4.0 v1.4.1'

snip 07-where-is-the-fix
note 'The fix now exists as two commits with different IDs:'
run "git branch --contains $fix"
run 'git branch --contains v1.4.1'
note 'Git can still pair them, because they introduce the same change (the same patch ID):'
run 'git log --oneline --cherry-mark --left-right --no-merges main...release/1.4'
run 'git cherry -v main release/1.4'
lab_end
