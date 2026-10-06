#!/usr/bin/env bash
# Lab 7.7 replay: read and edit refspecs. Widen a single-branch clone, exclude a
# namespace, map pull-request refs, push with explicit refspecs; then break a clone with
# a mirror-style refspec and repair it. Lab manual: lab-manual/m07-remotes.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 lab-07-7-refspec-surgery
scenario_07_7

snip 01-narrow
run 'cd you/support-bot'
run 'git config get --all remote.origin.fetch'
run 'git branch -r'
run 'git ls-remote origin'
run_rc 'git switch release/0.1'

snip 02-one-more-branch
run 'git remote set-branches --add origin release/0.1'
run 'git config get --all remote.origin.fetch'
run 'git fetch'
run 'git switch release/0.1'

snip 03-all-branches
run 'git remote set-branches origin "*"'
run 'git config get --all remote.origin.fetch'
run 'git fetch'

snip 04-exclude-a-namespace
run 'git config set --append remote.origin.fetch "^refs/heads/dependabot/*"'
run 'git branch -r -d origin/dependabot/pip/requests-2.33'
run 'git fetch'
run 'git branch -r'

snip 05-pull-request-refs
run 'git fetch origin refs/pull/7/head'
run 'git log --oneline -1 FETCH_HEAD'
run 'git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"'
run 'git fetch'
run 'git config get --all remote.origin.fetch'

snip 06-push-refspecs
run "printf '0.1.1\n' > VERSION"
run 'git commit -am "Bump version to 0.1.1"'
run 'git push --dry-run origin HEAD:refs/heads/review/version-bump'
run 'git push origin release/0.1:refs/heads/review/version-bump'
run 'git push origin :review/version-bump'

snip 07-checkpoint
run 'git branch -vv'
run 'git show-ref --abbrev'

snip 08-failure
run 'git config get --all remote.origin.fetch > ../refspecs.saved'
run 'git config set --all remote.origin.fetch "+refs/heads/*:refs/heads/*"'
run_rc 'git fetch'
run 'git switch --detach'
run 'git fetch'
run 'git branch -vv'

snip 09-recovery
run 'git reflog show release/0.1'
run 'git branch -f release/0.1 release/0.1@{1}'
run 'git branch -D dependabot/pip/requests-2.33'
run 'git remote set-branches origin "*"'
run 'git config set --append remote.origin.fetch "^refs/heads/dependabot/*"'
run 'git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"'
run 'git switch release/0.1'

snip 10-verification
run 'git config get --all remote.origin.fetch'
run 'cat ../refspecs.saved'
run 'git fetch'
run 'git branch -vv'
run 'git push'

lab_end
