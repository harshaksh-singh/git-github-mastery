#!/usr/bin/env bash
# Chapter 7, section 7.7: detached HEAD. What it is, how to see it, what happens to commits
# made in it, the warning when you leave, how to keep the commits, and the other operations
# that detach HEAD (remote-tracking branches, bisect, rebase).
# The remote is a bare repository on disk; no network is used.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 detached-head

quiet 'git init --bare origin.git'
quiet 'git clone origin.git evalkit'
cd evalkit || exit 1
mkdir -p evalkit configs
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'judge_model: judge-v1\nthreshold: 0.5\n' > configs/eval.yaml
quiet 'git add . && git commit -m "Add README and eval config"'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
quiet 'git tag v0.1.0'
printf 'def run_batch(examples, metric):\n    return [metric(e.pred, e.gold) for e in examples]\n' > evalkit/runner.py
quiet 'git add . && git commit -m "Add batch runner"'
quiet 'git push -u origin main'

snip 01-enter
run 'git checkout v0.1.0'
run 'cat .git/HEAD'
run 'git status'
run 'git branch'

snip 02-no-current-branch
run_rc 'git symbolic-ref HEAD'
run 'git branch --show-current'
run 'git rev-parse --abbrev-ref HEAD'

snip 03-commit
run "printf 'judge_model: judge-v1\nthreshold: 0.8\n' > configs/eval.yaml"
run 'git commit -am "Experiment: stricter judge threshold"'
run "printf 'judge_model: judge-v1\nthreshold: 0.9\n' > configs/eval.yaml"
run 'git commit -am "Experiment: threshold 0.9"'
run 'git status'
run 'git log --oneline --graph --all'

snip 04-leave
tip=$(git rev-parse --short HEAD)
run 'git switch main'
run 'git log --oneline --graph --all'

snip 05-keep
run "git branch experiment/judge-threshold $tip"
run 'git log --oneline --graph --all'

snip 06-remote-and-bisect
run 'git switch --detach origin/main'
run 'git status'
run 'git switch -q main'
run 'git bisect start HEAD HEAD~2'
run 'git status'
run 'git bisect reset'

snip 07-rebase
run_todo '1s/^pick/edit/' 'git rebase -i HEAD~1'
run 'git branch'
run 'cat .git/HEAD'
run 'git rebase --abort'
run 'git status'

lab_end
