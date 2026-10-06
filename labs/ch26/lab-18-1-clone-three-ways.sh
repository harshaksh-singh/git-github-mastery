#!/usr/bin/env bash
# Lab 18.1 replay: clone one repository three ways (full, shallow, blobless), compare what
# arrived, ask each clone the same three questions, and repair the shallow one.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 lab-18-1-clone-three-ways
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-18-1-clones.sh" || exit 1

snip 01-clone
run 'git clone "file://$PWD/server/orbit.git" full'
run 'git clone --depth 1 "file://$PWD/server/orbit.git" shallow'
run 'git clone --filter=blob:none "file://$PWD/server/orbit.git" blobless'

snip 02-objects
run 'for c in full shallow blobless; do echo "== $c"; git -C $c cat-file --batch-all-objects --batch-check="%(objecttype)" 2>/dev/null | sort | uniq -c; done'

snip 03-refs-and-config
run 'for c in full shallow blobless; do echo "== $c: $(git -C $c for-each-ref | wc -l) refs, fetch refspec $(git -C $c config get remote.origin.fetch)"; done'
run_rc 'cat shallow/.git/shallow'
run 'git -C blobless config get --all --show-names --regexp "^remote\.origin\.(promisor|partialclonefilter)$"'
run "git -C blobless rev-list --objects --all --missing=print | grep -c '^?'"

snip 04-questions
note 'Question 1: how many commits changed services/ranker?'
run 'for c in full shallow blobless; do echo "$c: $(git -C $c log --oneline -- services/ranker | wc -l)"; done'
note 'Question 2: which commit last changed line 3 of the gateway routes?'
run 'for c in full shallow blobless; do echo "$c: $(git -C $c blame -s -L 3,3 services/gateway/routes.py)"; done'
note 'Question 3: what is the latest gateway release before this commit?'
run "for c in full shallow blobless; do echo \"\$c: \$(git -C \$c describe --match 'gateway/v*' 2>&1)\"; done"

snip 05-cost-of-asking
note 'The blobless clone answered question 2 by downloading. Count its packs now:'
run 'ls blobless/.git/objects/pack/*.pack | wc -l'
run "git -C blobless rev-list --objects --all --missing=print | grep -c '^?'"

snip 06-failure
note 'Failure scenario: a release script runs in the shallow clone.'
run 'cd shallow'
run_rc "git describe --match 'gateway/v*'"
run_rc 'git log --oneline gateway/v1.1.0..HEAD -- services/gateway'
run 'git fetch -q --depth 1 origin feature/rerank-cache:refs/remotes/origin/feature/rerank-cache'
run_rc 'git diff --name-only HEAD...origin/feature/rerank-cache'

snip 07-recovery
run 'git fetch --unshallow'
run 'git rev-parse --is-shallow-repository'
note 'The clone still follows one branch only. Widen the refspec and fetch again:'
run "git remote set-branches origin '*'"
run 'git fetch'
run 'git config get remote.origin.fetch'

snip 08-verification
run "git describe --match 'gateway/v*'"
run 'git log --oneline gateway/v1.1.0..HEAD -- services/gateway'
run 'git diff --name-only HEAD...origin/feature/rerank-cache'
run 'git rev-list --count --all'
run_rc 'git fsck'

lab_end
