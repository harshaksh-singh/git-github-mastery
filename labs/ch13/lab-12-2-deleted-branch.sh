#!/usr/bin/env bash
# Lab 12.2 replay: "git branch -D" on an unmerged branch, recovered from the ID that Git
# printed and, without that line, from the HEAD reflog. Failure: a teammate's branch that was
# only ever a remote-tracking ref here is pruned; no reflog names it. Recovery: git fsck.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-2-deleted-branch
fx_12_2
tip=$(git -C reranker rev-parse --short feature/cross-encoder)

snip 01-start
run 'cd reranker'
run 'git log --oneline --graph --all'
run 'git reflog show feature/cross-encoder'

snip 02-disaster
run_rc 'git branch -d feature/cross-encoder'
run 'git branch -D feature/cross-encoder'
run 'git branch'
run 'git log --oneline --graph --all'

snip 03-evidence
run_rc 'git reflog show feature/cross-encoder'
run 'git reflog -6'

snip 04-recover
run "git branch feature/cross-encoder $tip"
run 'git log --oneline main..feature/cross-encoder'
run 'git reflog show feature/cross-encoder'

snip 05-from-the-reflog
note 'Without the "Deleted branch" line: the last entry that left the branch is in the HEAD reflog.'
run "git log -g --format='%h %gd %gs' --grep-reflog='moving from feature/cross-encoder'"
note 'That entry records where HEAD went. The entry below it records where the branch was.'
run "git log --oneline -1 'HEAD@{2}'"

snip 06-failure
run 'git branch -r'
run 'git log --oneline -2 origin/exp/hard-negatives'
run 'git fetch --prune'
run 'git branch -r'
run_rc "git reflog show origin/exp/hard-negatives"
run 'git reflog | grep -c negatives'

snip 07-recovery-find
run 'git fsck'
run 'git fsck --lost-found'
run "git log --format='%h %an, %ad%n        %s' --date=short \$(cat .git/lost-found/commit/*) --not --all"

snip 08-recovery-anchor
run 'git branch exp/hard-negatives $(cat .git/lost-found/commit/*)'
run 'git log --oneline main..exp/hard-negatives'
run 'git push -u origin exp/hard-negatives'

snip 09-verification
run 'git fsck'
run 'git branch -a'
run 'git ls-remote origin'

lab_end
