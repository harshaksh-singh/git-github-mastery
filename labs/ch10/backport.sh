#!/usr/bin/env bash
# Chapter 10, section 10.9: the backport workflow. The fix lands on main first and is copied to the
# maintenance branch with -x, which records where it came from. Then: how to find out afterwards which
# branches contain the fix, by commit ID and by the recorded line.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 backport
fx_gateway_fix
FIX=$(git rev-parse --short main~1)

snip 01-pick-x
run 'git log --oneline -3 main'
run "git cherry-pick -x $FIX"
run 'git log -1 --format=fuller'

snip 02-audit-by-id
note 'Which branches contain the fix? Asking by commit ID finds only the original.'
run "git branch --contains $FIX"

snip 03-audit-by-trailer
run "git log --all --oneline --grep='cherry picked from commit $FIX'"
run "git branch --contains \$(git log --all --format=%h --grep='cherry picked from commit $FIX')"

snip 04-audit-by-patch
run 'git cherry -v release/1.4 main'
lab_end
