#!/usr/bin/env bash
# Lab 10.1 replay: backport a fix from main to the maintenance branch with -x and verify it. The
# failure scenario backports a follow-up commit that applies cleanly and breaks the branch, because
# it depends on code that only main has.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 lab-10-1-backport-fix
fx_gateway_backport

snip 01-start
run 'git log --graph --decorate --all --format="%h %an: %s%d"'
run 'sh scripts/smoke.sh'

snip 02-inspect-fix
run 'git show --stat --format="%h %an: %s" main~1'

snip 03-backport
run 'git switch release/1.4'
run 'git cherry-pick -x main~1'

snip 04-result
run 'git log -1 --format=fuller'
run 'sh scripts/smoke.sh'

snip 05-failure
note 'The follow-up commit on main looks harmless, so it is backported too:'
run 'git show --format="%h %s" main'
run 'git cherry-pick -x main'

snip 06-diagnose
run 'sh scripts/smoke.sh'
run 'git log --oneline -1 -S"def log_event" main'
run 'git branch --contains $(git log --format=%h -1 -S"def log_event" main)'

snip 07-recovery
note 'The bad backport has not been pushed, so it can be removed. HEAD@{1} is where HEAD was before it.'
run 'git reflog -2'
run 'git reset --hard HEAD@{1}'

snip 08-verification
run 'sh scripts/smoke.sh'
run 'git log --oneline --decorate -3'
run 'git log --format="%h %s%n  %b" -1'
lab_end
