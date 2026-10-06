#!/usr/bin/env bash
# Chapter 11, section 11.6: "git reset --keep" and "--merge" compared with "--hard".
# The same starting state (one staged change, one unstaged change, both in files the dropped
# commit did not touch) is reset three ways. A last scenario shows --keep refusing to run.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 reset-keep-merge

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && printf 'batch_size: 32\n' > serve.yaml && printf 'recall@10: 0.71\n' > metrics.txt && git add . && git commit -m 'Add ranker, serving config and baseline metrics'"
quiet "printf 'def score(q, d):\n    return 0.7 * bm25(q, d) + 0.3 * dense(q, d)\n' > rank.py && git commit -am 'Blend dense scores into ranker'"
quiet "printf 'batch_size: 64\n' > serve.yaml && git add serve.yaml"
quiet "printf 'recall@10: 0.74\n' > metrics.txt"

cd "$LAB_DIR" || exit 1
for m in merge hard; do
  cp -R ranker "ranker-$m"
  git -C "ranker-$m" status > /dev/null 2>&1
done
cd "$LAB_DIR/ranker" || exit 1

snip 01-state
run 'git log --oneline'
run 'git status -s'

snip 02-keep
run 'git reset --keep HEAD~1'
run 'git log --oneline'
run 'git status -s'
run 'cat serve.yaml metrics.txt'

cd "$LAB_DIR/ranker-merge" || exit 1
snip 03-merge
run 'git reset --merge HEAD~1'
run 'git log --oneline'
run 'git status -s'
run 'cat serve.yaml metrics.txt'

cd "$LAB_DIR/ranker-hard" || exit 1
snip 04-hard
run 'git reset --hard HEAD~1'
run 'git status -s'
run 'cat serve.yaml metrics.txt'

# --keep refuses when the local change is in a file that the dropped commit also changed.
cd "$LAB_DIR/ranker" || exit 1
quiet 'git reset --hard ORIG_HEAD'
quiet "printf 'def score(q, d):\n    return 0.5 * bm25(q, d) + 0.5 * dense(q, d)\n' > rank.py"

snip 05-keep-refuses
run 'git log --oneline'
run 'git status -s'
run_rc 'git reset --keep HEAD~1'
run 'git log --oneline -1'
run 'git status -s'

lab_end
