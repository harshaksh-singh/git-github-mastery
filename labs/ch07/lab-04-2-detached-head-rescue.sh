#!/usr/bin/env bash
# Lab 4.2 replay: detach HEAD at a tag, commit twice, switch away, then find the commits in
# the reflog and give them a branch. The failure scenario reuses "HEAD@{1}" blindly after more
# HEAD movements; the recovery searches the reflog by message instead of by position.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 lab-04-2-detached-head-rescue

# --- same steps as setup-04-2-detached-head-rescue.sh
quiet 'git init evalkit'
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
# --- end of setup

snip 01-detach
run 'git switch --detach v0.1.0'
run 'git status'
run 'cat .git/HEAD'

snip 02-commit
run "printf 'judge_model: judge-v1\nthreshold: 0.8\n' > configs/eval.yaml"
run 'git commit -am "Experiment: stricter judge threshold"'
run "printf 'judge_model: judge-v1\nthreshold: 0.9\n' > configs/eval.yaml"
run 'git commit -am "Experiment: threshold 0.9"'

snip 03-leave
run 'git switch main'

snip 04-find
run 'git log --oneline --all'
run 'git reflog'

snip 05-rescue
run "git branch rescue/judge-threshold 'HEAD@{1}'"
run 'git log --oneline --graph --all'

snip 06-failure
run 'git branch -D rescue/judge-threshold'
run 'git switch --detach v0.1.0'
run 'git switch main'
run "git branch rescue/judge-threshold 'HEAD@{1}'"
run 'git log --oneline -1 rescue/judge-threshold'

snip 07-recovery
run "git log -g --grep-reflog='commit: Experiment' --format='%h %gd %gs'"
tip=$(git log -g --grep-reflog='commit: Experiment: threshold 0.9' --format='%h' -1)
run "git branch -f rescue/judge-threshold $tip"
run 'git log --oneline main..rescue/judge-threshold'

snip 08-verify
run "git branch --contains $tip"
run 'git log --oneline --graph --all'
run 'git fsck --no-reflogs'

lab_end
