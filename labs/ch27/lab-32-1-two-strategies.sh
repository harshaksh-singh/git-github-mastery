#!/usr/bin/env bash
# Lab 32.1 replay: one release and one hotfix under two strategies, then a comparison of the
# two histories, a fix that is forgotten on main, and its repair.
# Lab manual: lab-manual/m32-branching-release-strategy.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch27 lab-32-1-two-strategies
fx_lab_32_1
FIX='sed -i.bak "s/LIMITS.get(tenant) or LIMITS\[\"default\"\]/LIMITS.get(tenant, LIMITS[\"default\"])/" gateway/limits.py && rm gateway/limits.py.bak'

snip 01-start
run 'cd github-flow/promptgate'
run 'git log --oneline --graph --decorate --all'

snip 02-flow-release
run 'git tag -a v1.4.0 -m "promptgate 1.4.0"'
run 'git merge --no-ff -m "Merge pull request #43 from feature/batch-api" feature/batch-api'
run 'git branch -d feature/batch-api'

snip 03-flow-hotfix
run 'git switch -c hotfix/suspended-tenant'
run "$FIX"
run 'git diff --stat'
run 'git commit -q -am "Fix limit 0 being treated as unlimited"'
run 'git switch -q main'
run 'git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant'
run 'git branch -d hotfix/suspended-tenant'
run 'git tag -a v1.4.1 -m "promptgate 1.4.1"'

snip 04-flow-result
run 'git log --oneline --graph --decorate -6'
run 'git log --oneline --no-merges v1.4.0..v1.4.1'

snip 05-rb-release
run 'cd ../../release-branch/promptgate'
run 'git branch release/1.4 main'
run 'git tag -a v1.4.0 -m "promptgate 1.4.0" release/1.4'
run 'git merge --no-ff -m "Merge pull request #43 from feature/batch-api" feature/batch-api'
run 'git branch -d feature/batch-api'

snip 06-rb-hotfix
run 'git switch -c hotfix/suspended-tenant'
run "$FIX"
run 'git commit -q -am "Fix limit 0 being treated as unlimited"'
run 'git switch -q main'
run 'git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant'
run 'git switch -q release/1.4'
run 'git cherry-pick -x hotfix/suspended-tenant'
run 'git tag -a v1.4.1 -m "promptgate 1.4.1"'
run 'git branch -D hotfix/suspended-tenant'

snip 07-rb-result
run 'git log --oneline --graph --decorate --all -8'
run 'git log --oneline --no-merges v1.4.0..v1.4.1'

snip 08-compare
note 'The same question asked of both repositories: what changed between the two releases?'
run 'git -C ../../github-flow/promptgate diff --stat v1.4.0 v1.4.1'
run 'git diff --stat v1.4.0 v1.4.1'
note 'And: which long-lived refs does each strategy leave behind?'
run 'git -C ../../github-flow/promptgate for-each-ref --format="%(refname:short)" refs/heads'
run 'git for-each-ref --format="%(refname:short)" refs/heads'

snip 09-failure
note 'Failure scenario: a second fix is committed straight to the release branch.'
run 'sed -i.bak "s/return used < limit/return max(used, 0) < limit/" gateway/limits.py && rm gateway/limits.py.bak'
run 'git commit -q -am "Clamp negative usage counters"'
run 'git tag -a v1.4.2 -m "promptgate 1.4.2"'
note 'Nobody ports it. Later, release 1.5 is cut from main:'
run 'git switch -q main'
run 'git branch release/1.5 main && git tag -a v1.5.0 -m "promptgate 1.5.0" release/1.5'
run 'git grep -c "max(used, 0)" v1.4.2 v1.5.0 -- gateway/limits.py'

snip 10-detect
run 'git log --oneline --cherry-pick --right-only --no-merges main...release/1.4'

snip 11-recover
note 'Recovery: port the fix forward to main, then to the release branch that shipped without it.'
run 'git cherry-pick -x release/1.4'
run 'git switch -q release/1.5'
run 'git cherry-pick -x main'
run 'git tag -a v1.5.1 -m "promptgate 1.5.1"'

snip 12-verify
run 'git log --oneline --cherry-pick --right-only --no-merges main...release/1.4'
run 'git log --oneline --cherry-pick --right-only --no-merges main...release/1.5'
run 'git grep -c "max(used, 0)" v1.5.0 v1.5.1 main -- gateway/limits.py'
run 'git tag --list "v1.*" --format="%(refname:short) %(*objectname:short)"'
lab_end
