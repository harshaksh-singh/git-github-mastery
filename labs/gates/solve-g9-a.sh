#!/usr/bin/env bash
# Gate 9, hands-on variant A (storefront-api): the model diagnosis and repair as real
# transcripts for answer-keys/gate-9-production-debugging.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g9-a
gate_load gate-9-production-debugging/variant-a
as config

snip 01-observe
note 'PHASE 1: read-only'
run 'cd you'
run 'git status -sb'
run 'git fetch'
run 'git ls-remote origin'

snip 02-what-is-on-the-branch
run "git log --graph --format='%h %an: %s' v2.2.1..origin/release/2.2"
run 'git diff --stat v2.2.1 origin/release/2.2'

snip 03-how-it-got-there
run "git log --first-parent --format='%h %an: %s (parents: %p)' v2.2.1..origin/release/2.2"
m=$(git log --merges --format=%H -1 origin/release/2.2)
f=$(git log --format=%H --grep='Fix currency rounding' -1 origin/main)
run "git show -s --format='%s%n  parents: %p' ${m:0:7}"
run "git log -1 --format='%h %s' ${m:0:7}^1"
run "git log -1 --format='%h %s' ${m:0:7}^2"
run "git branch -r --contains ${f:0:7}"
run "git log --oneline ${m:0:7}^1..${m:0:7}^2"

snip 04-preserve
note 'PHASE 2: preserve'
run 'git switch release/2.2'
run 'git merge --ff-only origin/release/2.2'
run 'git branch rescue/release-2.2-before-repair'
note 'Rehearse: what would undoing the merge leave?'
run "git diff --stat ${m:0:7}^1 ${m:0:7}"

snip 05-revert
note 'PHASE 3: change'
run "git revert -m 1 --no-edit ${m:0:7}"
run 'git diff --stat v2.2.1 HEAD'
run "git cherry-pick -x ${f:0:7}"
run 'git log -1 --format=%B'

snip 06-verify
run 'git diff --stat v2.2.1 HEAD'
run "git log --format='%h %an: %s' origin/release/2.2..HEAD"
run 'git ls-tree -r --name-only HEAD'
run 'git push origin release/2.2'
run 'git status -sb'

snip 07-the-trap
note 'Weeks from now: release/2.2 merged into main would carry the revert with it.'
run 'git ls-tree -r --name-only origin/main'
note 'The tree that a merge of release/2.2 into main would produce:'
run 'git ls-tree -r --name-only "$(git merge-tree --write-tree origin/main release/2.2)"'
run 'git branch -D rescue/release-2.2-before-repair'
run 'cd ..'
show_check
gate_done
