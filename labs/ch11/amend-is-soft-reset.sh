#!/usr/bin/env bash
# Chapter 11, section 11.7: "git commit --amend" seen through the reset model. The same
# forgotten line is added to the last commit twice, from the identical starting state: once
# with --amend, once with "git reset --soft HEAD~1" followed by a new commit. Both give a new
# commit with the old parent and the same tree. The amend is then undone through the reflog,
# because --amend, unlike reset, does not write ORIG_HEAD. Chapter 6 has the anatomy of amend.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 amend-is-soft-reset

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && git add rank.py && git commit -m 'Add BM25 ranker'"
quiet "printf 'timeout_s: 30\n' > serve.yaml && git add serve.yaml && git commit -m 'Add serving config'"
# The line that should have been in that commit.
quiet "printf 'timeout_s: 30\nretries: 2\n' > serve.yaml"

cd "$LAB_DIR" || exit 1
cp -R ranker ranker-by-hand
git -C ranker-by-hand status > /dev/null 2>&1
cd "$LAB_DIR/ranker" || exit 1

snip 01-amend
run 'git log --oneline'
run 'git status -s'
run 'git add serve.yaml'
run 'git commit --amend --no-edit'
run 'git log --oneline'
run 'git reflog -2'
run 'git show -s --format="%h  parent %p  tree %t" HEAD HEAD@{1}'

cd "$LAB_DIR/ranker-by-hand" || exit 1
snip 02-by-hand
run 'git add serve.yaml'
run 'git reset --soft HEAD~1'
run 'git status -s'
run 'git commit -q -C ORIG_HEAD'
run 'git log --oneline'
run 'git show -s --format="%h  parent %p  tree %t" HEAD ORIG_HEAD'

cd "$LAB_DIR/ranker" || exit 1
snip 03-undo-the-amend
run_rc 'git rev-parse --verify --short ORIG_HEAD'
run 'git reset --soft HEAD@{1}'
run 'git log --oneline'
run 'git status -s'
run 'git reflog -3'

lab_end
