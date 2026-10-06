#!/usr/bin/env bash
# Chapter 11, section 11.4: the three everyday reset modes (--soft, --mixed, --hard),
# each run from the identical starting state, with HEAD, the index and the working tree
# shown before and after. Also shows what a reset writes inside .git, and ORIG_HEAD.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 reset-modes

# One file, five versions: three committed, one staged, one only in the working tree.
quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'threshold: 0.50\n' > eval.yaml && git add eval.yaml && git commit -m 'Add eval config'"
quiet "printf 'threshold: 0.60\n' > eval.yaml && git commit -am 'Raise threshold to 0.60'"
quiet "printf 'threshold: 0.70\n' > eval.yaml && git commit -am 'Raise threshold to 0.70'"
quiet "printf 'threshold: 0.80\n' > eval.yaml && git add eval.yaml"
quiet "printf 'threshold: 0.90\n' > eval.yaml"

# Three more copies of the repository in exactly this state, one per reset mode.
# "git status" in each copy refreshes the cached stat data that cp invalidated.
cd "$LAB_DIR" || exit 1
for m in mixed hard inside; do
  cp -R ranker "ranker-$m"
  git -C "ranker-$m" status > /dev/null 2>&1
done
cd "$LAB_DIR/ranker" || exit 1

snip 01-before
run 'git log --oneline'
run 'git show HEAD:eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

snip 02-soft
run 'git reset --soft HEAD~1'
run 'git log --oneline'
run 'git show HEAD:eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

cd "$LAB_DIR/ranker-mixed" || exit 1
snip 03-mixed
run 'git reset --mixed HEAD~1'
run 'git log --oneline'
run 'git show HEAD:eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

cd "$LAB_DIR/ranker-hard" || exit 1
snip 04-hard
run 'git reset --hard HEAD~1'
run 'git log --oneline'
run 'git show HEAD:eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

cd "$LAB_DIR/ranker-inside" || exit 1
snip 05-inside-git
run 'cat .git/HEAD'
run 'cat .git/refs/heads/main'
run 'git reset --soft HEAD~1'
run 'cat .git/HEAD'
run 'cat .git/refs/heads/main'
run 'cat .git/ORIG_HEAD'
run 'git reflog -2'
run 'git reflog show -2 main'

snip 06-orig-head
run 'git reset --soft ORIG_HEAD'
run 'git log --oneline -1'
run 'git status -s'
run 'git rev-parse --short ORIG_HEAD'

lab_end
