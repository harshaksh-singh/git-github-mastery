#!/usr/bin/env bash
# Gate 9, hands-on variant B (cart-svc): the model diagnosis and repair as real transcripts for
# answer-keys/gate-9-production-debugging.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g9-b
gate_load gate-9-production-debugging/variant-b
as config

snip 01-observe
note 'PHASE 1: read-only'
run 'cd you'
run 'git status -sb'
run 'git fetch'
run 'git ls-remote origin'

snip 02-the-search-by-title
run "git log --all --format='%h %s' --grep 'Clamp negative'"
fix=$(git rev-parse origin/release/3.0)
port=$(git rev-parse origin/port/clamp-quantities)
run "git branch -r --contains ${fix:0:7}"
run "git branch -r --contains ${port:0:7}"
run "git tag --contains ${fix:0:7}"
run "git tag --contains ${port:0:7}"

snip 03-ancestry
run_rc "git merge-base --is-ancestor ${fix:0:7} v3.1.0"
run_rc "git merge-base --is-ancestor ${port:0:7} v3.1.0"
run 'git cherry -v v3.1.0 origin/release/3.0'
run 'git show v3.1.0:cart/pricing.py | head -2'
run 'git show v3.0.1:cart/total.py | head -2'

snip 04-the-other-hypothesis
run 'git log --oneline v3.0.1..v3.1.0'
run 'git diff --stat v3.0.1 v3.1.0'
run 'git log --oneline main..oncall/revert-pricing-lib'

snip 05-release
note 'PHASE 2: preserve. Nothing is rewritten; the new refs are the record.'
note 'PHASE 3: change'
run 'git switch -c release/3.1 v3.1.0'
run "git cherry-pick -x ${fix:0:7}"
run 'git show --stat --format=%B HEAD'
run 'git diff --stat v3.1.0 HEAD'
run 'git tag -a v3.1.1 -m "cart-svc 3.1.1: clamp negative quantities"'
run 'git push origin release/3.1 v3.1.1'

snip 06-main
run 'git switch main'
run "git cherry-pick -x ${fix:0:7}"
run 'git push origin main'

snip 07-verify
run 'git show v3.1.1:cart/pricing.py | head -2'
run 'git show origin/main:cart/pricing.py | head -2'
run "git log --format='%h %s' --grep 'cherry picked from commit ${fix:0:12}' v3.1.1 origin/main"
note 'The original commit never becomes an ancestor, and the patch test does not see the copy:'
note 'on this branch the file has another name. The -x line is the record.'
run_rc "git merge-base --is-ancestor ${fix:0:7} v3.1.1"
run 'git cherry -v v3.1.1 origin/release/3.0'
run 'git describe release/3.1'
run 'git status -sb'
run 'cd ..'
show_check
gate_done
