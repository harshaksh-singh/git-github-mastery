#!/usr/bin/env bash
# Chapter 13, section 13.3: what the reflog records. The HEAD reflog against the reflog of a
# branch, the selector forms (@{n}, @{time}, @{-n}), "git log -g" with reflog placeholders,
# and the two lines on disk behind one entry.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 reflog-anatomy
fx_searchsvc
cd searchsvc || exit 1

snip 01-make-history
run 'git switch -c feature/rerank'
run "printf 'def rerank(q, docs):\n    return sorted(docs)\n' > rerank.py"
run 'git add rerank.py'
run 'git commit -q -m "Add reranker"'
run 'git commit -q --amend -m "Add cross-encoder reranker"'
run 'git switch main'
run 'git merge -q feature/rerank'
run 'git reset -q --hard HEAD~1'

snip 02-head-reflog
run 'git reflog'

snip 03-branch-reflogs
run 'git reflog show main'
run 'git reflog show feature/rerank'
run 'git reflog list'

snip 04-selectors
note 'Position: the n-th previous value of HEAD, of a branch, of the current branch.'
run "git rev-parse --short 'HEAD@{1}'"
run "git rev-parse --short 'main@{2}'"
run "git rev-parse --short '@{1}'"
note 'The n-th branch checked out before the current one.'
run "git rev-parse --abbrev-ref '@{-1}'"
note 'A selector is a revision like any other.'
run "git diff --stat 'main@{1}' main"

snip 05-time
run 'git reflog --date=iso -4'
run "git rev-parse --short 'main@{2026-09-07 10:10:30}'"
run "git rev-parse --short 'HEAD@{5.minutes.ago}'"
run "git rev-parse --short 'main@{2.days.ago}'"

snip 06-log-g
run "git log -g --format='%h %gd %gs' -4"
run "git log -g --date=relative --format='%h %gd | %gn | %s' -3 main"
run "git log -g --format='%h %gd %gs' --grep-reflog='^commit'"

snip 07-on-disk
run 'tail -2 .git/logs/HEAD'
run 'tail -1 .git/logs/refs/heads/main'
run 'cat .git/refs/heads/main'

lab_end
