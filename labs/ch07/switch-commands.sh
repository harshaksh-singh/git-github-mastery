#!/usr/bin/env bash
# Chapter 7, section 7.6: git switch (-c, -C, -, --detach, --orphan), the git checkout
# equivalents, and what happens to uncommitted changes when you switch.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 switch-commands

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
quiet 'git switch -c feature/threshold'
printf 'judge_model: judge-v1\nthreshold: 0.8\n' > configs/eval.yaml
quiet 'git commit -am "Raise judge threshold to 0.8"'
quiet 'git switch main'

snip 01-create
run 'git switch -c feature/retry'
run_rc 'git switch -c feature/retry'
run 'git switch main'
run 'git switch -C feature/retry main~1'
run 'git reflog show feature/retry'

snip 02-previous
run 'git switch main'
run 'git switch -'
run 'git switch -'
run "git rev-parse --abbrev-ref '@{-1}'"

snip 03-detach
run_rc 'git switch v0.1.0'
run 'git switch --detach v0.1.0'
run 'git switch -'

snip 04-checkout-equivalents
run 'git checkout -b feature/cache'
run 'git checkout main'
run 'git checkout -B feature/cache main~1'
run 'git checkout -'
run 'git checkout --detach'
run 'git checkout main'

snip 05-orphan
run 'git switch --orphan gh-pages'
run 'cat .git/HEAD'
run 'git status --short'
run 'ls -A'
run 'git switch main'
run 'git branch --list gh-pages'
run 'git checkout --orphan docs-site'
run 'git status --short'
run 'git switch main'

snip 06-local-changes
run "printf '\nRun the tests with: python -m pytest\n' >> README.md"
run 'git switch feature/threshold'
run 'git switch main'
run "printf 'judge_model: judge-v2\nthreshold: 0.5\n' > configs/eval.yaml"
run_rc 'git switch feature/threshold'
run 'git status --short'

lab_end
