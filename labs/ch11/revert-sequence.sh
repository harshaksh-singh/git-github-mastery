#!/usr/bin/env bash
# Chapter 11, section 11.8: a range revert that stops halfway. The first revert of the range
# is already committed when the second one conflicts. The demo shows the sequencer state in
# .git, then the three ways out from the identical stopped state: --abort (back to the commit
# before the whole sequence), --quit (keep what was done, forget the rest, conflict left in
# place) and --skip (drop the conflicting step, finish the sequence).
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 revert-sequence

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'timeout_s: 30\nretries: 2\ncache: on\n' > serve.yaml && git add serve.yaml && git commit -m 'Add serving config'"
quiet "printf 'timeout_s: 5\nretries: 2\ncache: on\n' > serve.yaml && git commit -am 'Cut timeout to 5s'"
quiet "printf 'timeout_s: 5\nretries: 2\ncache: off\n' > serve.yaml && git commit -am 'Disable cache'"
quiet "printf 'recall@10: 0.71\n' > metrics.txt && git add metrics.txt && git commit -m 'Record baseline metrics'"
quiet "printf 'timeout_s: 8\nretries: 2\ncache: off\n' > serve.yaml && git commit -am 'Tune timeout to 8s'"

snip 01-stops-halfway
run 'git log --oneline'
run_rc 'git revert --no-edit HEAD~4..HEAD~2'

snip 02-sequencer-state
run 'git log --oneline -2'
run 'git status'
run 'ls .git/sequencer'
run 'cat .git/sequencer/todo'
run 'git rev-parse --short REVERT_HEAD'
run 'git log --oneline -1 $(cat .git/sequencer/head)'

# Two more copies of the repository in exactly this stopped state.
cd "$LAB_DIR" || exit 1
for m in quit skip; do
  cp -R ranker "ranker-$m"
  git -C "ranker-$m" status > /dev/null 2>&1
done
cd "$LAB_DIR/ranker" || exit 1

snip 03-abort
run 'git revert --abort'
run 'git log --oneline -2'
run 'git status -s'
run 'git reflog -2'
run_rc 'test -d .git/sequencer'

cd "$LAB_DIR/ranker-quit" || exit 1
snip 04-quit
run 'git revert --quit'
run 'git log --oneline -2'
run 'git status -s'
run_rc 'test -d .git/sequencer'
run_rc 'git rev-parse --verify --short REVERT_HEAD'

cd "$LAB_DIR/ranker-skip" || exit 1
snip 05-skip
run 'git revert --skip'
run 'git log --oneline -2'
run 'git status -s'
run 'cat serve.yaml'

lab_end
