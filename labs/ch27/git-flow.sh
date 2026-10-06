#!/usr/bin/env bash
# Chapter 27, section 27.5: a Git Flow history. Two long-lived branches (main and develop),
# feature branches into develop, a release branch, and a hotfix branch that is merged twice.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch27 git-flow
fx_base
hidden 'git branch develop main'
fx_two_features develop

snip 01-release-branch
note 'Features were merged into develop, not main. A release branch stabilizes them:'
run 'git switch -c release/1.4.0 develop'
run "printf '1.4.0\n' > VERSION"
run 'git commit -q -am "Bump version to 1.4.0"'
run 'git switch -q main'
run 'git merge --no-ff -m "Release 1.4.0" release/1.4.0'
run 'git tag -a v1.4.0 -m "promptgate 1.4.0"'
note 'The release branch is merged back so that develop has the version bump too:'
run 'git switch -q develop'
run 'git merge --no-ff -m "Merge release/1.4.0 back into develop" release/1.4.0'
run 'git branch -d release/1.4.0'

fx_batch_feature develop

snip 02-hotfix
note 'A hotfix starts from main (what production runs), not from develop:'
run 'git switch -c hotfix/1.4.1 main'
limits_fixed
quiet "printf '1.4.1\n' > VERSION"
run 'git commit -q -am "Fix limit 0 being treated as unlimited"'
run 'git switch -q main'
run 'git merge --no-ff -m "Hotfix 1.4.1" hotfix/1.4.1'
run 'git tag -a v1.4.1 -m "promptgate 1.4.1"'
run 'git switch -q develop'
run 'git merge --no-ff -m "Merge hotfix/1.4.1 into develop" hotfix/1.4.1'
run 'git branch -d hotfix/1.4.1'

snip 03-graph
run 'git log --oneline --graph --decorate --all'

snip 04-what-ships
run 'git log --oneline --no-merges v1.4.0..v1.4.1'
run 'git log --oneline --first-parent main'
run 'git rev-list --count --merges v1.3.0..develop'
run 'git branch --contains v1.4.1^2'
lab_end
