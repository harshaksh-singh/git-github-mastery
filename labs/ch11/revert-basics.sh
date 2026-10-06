#!/usr/bin/env bash
# Chapter 11, section 11.8: "git revert" creates a new commit that applies the inverse change.
# One commit, a range, "-n" for a single combined commit, a conflict read through the three
# index stages, and the two refusals you meet most often.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 revert-basics

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'timeout_s: 30\nretries: 2\ncache: on\n' > serve.yaml && git add serve.yaml && git commit -m 'Add serving config'"
quiet "printf 'timeout_s: 5\nretries: 2\ncache: on\n' > serve.yaml && git commit -am 'Cut timeout to 5s'"
quiet "printf 'timeout_s: 5\nretries: 2\ncache: off\n' > serve.yaml && git commit -am 'Disable cache'"
quiet "printf 'recall@10: 0.71\n' > metrics.txt && git add metrics.txt && git commit -m 'Record baseline metrics'"
timeout_commit=$(git rev-parse --short HEAD~2)
cache_commit=$(git rev-parse --short HEAD~1)

cd "$LAB_DIR" || exit 1
for m in dirty range nocommit conflict; do
  cp -R ranker "ranker-$m"
  git -C "ranker-$m" status > /dev/null 2>&1
done
cd "$LAB_DIR/ranker" || exit 1

snip 01-revert
run 'git log --oneline'
run "git revert --no-edit $cache_commit"
run 'git log --oneline'
run 'cat serve.yaml'

snip 02-the-new-commit
run 'git show HEAD'

snip 03-inside-git
run 'git cat-file -p HEAD'
run 'git reflog -1'

snip 04-already-reverted
run_rc "git revert --no-edit $cache_commit"

snip 05-m-is-not-a-message
run_rc 'git revert -m "Cache must stay on" HEAD~1'

cd "$LAB_DIR/ranker-dirty" || exit 1
snip 06-dirty-tree
note 'An unstaged change in a file that the revert does not touch: allowed.'
run "printf 'recall@10: 0.74\n' > metrics.txt"
run "git revert --no-edit $cache_commit"
run 'git status -s'
note 'The same change, staged: refused, because the index must match HEAD.'
run 'git add metrics.txt'
run_rc "git revert --no-edit $timeout_commit"

cd "$LAB_DIR/ranker-range" || exit 1
snip 07-range
run 'git revert --no-edit HEAD~3..HEAD~1'
run 'git log --oneline'
run 'cat serve.yaml'

cd "$LAB_DIR/ranker-nocommit" || exit 1
snip 08-no-commit
run 'git revert -n HEAD~3..HEAD~1'
run 'git status -s'
run 'git commit -m "Revert timeout and cache changes from the latency experiment"'
run 'git log --oneline -3'

cd "$LAB_DIR/ranker-conflict" || exit 1
quiet "printf 'timeout_s: 8\nretries: 2\ncache: off\n' > serve.yaml && git commit -am 'Tune timeout to 8s'"

snip 09-conflict
run 'git log --oneline'
run_rc "git revert --no-edit $timeout_commit"

snip 10-conflict-state
run 'git status -s'
run 'cat serve.yaml'
run 'git ls-files -s serve.yaml'
run "git rev-parse $timeout_commit:serve.yaml HEAD:serve.yaml $timeout_commit~1:serve.yaml"
run 'git rev-parse --short REVERT_HEAD'

snip 11-resolve
run "printf 'timeout_s: 30\nretries: 2\ncache: off\n' > serve.yaml"
run 'git add serve.yaml'
run 'git revert --continue'
run 'git log --oneline -2'

lab_end
