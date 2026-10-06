#!/usr/bin/env bash
# Chapter 7, section 7.5: git branch. Listing (-v, -vv, -r, -a), --merged and --no-merged,
# --contains, -d versus -D and the upstream rule behind -d, -m, and -f.
# The remote is a bare repository on disk; no network is used.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 branch-commands

quiet 'git init --bare origin.git'
quiet 'git clone origin.git evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
quiet 'git push -u origin main'

quiet 'git switch -c feature/f1'
printf '\n\ndef f1(pred, gold):\n    return 0.0  # placeholder until the tokenizer lands\n' >> evalkit/metrics.py
quiet 'git commit -am "Add F1 metric"'
quiet 'git push -u origin feature/f1'
printf '\n\ndef f1_safe(pred, gold):\n    return f1(pred, gold) if gold.split() else 0.0\n' >> evalkit/metrics.py
quiet 'git commit -am "F1: handle empty reference"'

quiet 'git switch -c fix/typo-readme main'
printf '# evalkit\n\nA small evaluation harness for LLM outputs.\n' > README.md
quiet 'git commit -am "Fix grammar in README"'
quiet 'git push -u origin fix/typo-readme'

quiet 'git switch -c spike/judge-cache main'
printf 'CACHE = {}\n' > evalkit/cache.py
quiet 'git add . && git commit -m "Spike: cache judge responses"'

quiet 'git switch main'
quiet 'git merge --ff-only feature/f1'
quiet 'git switch -c docs/metrics'
printf '\n## Metrics\n\nexact_match, f1\n' >> README.md
quiet 'git commit -am "Document the metrics"'
quiet 'git switch main'
quiet 'git merge --no-ff docs/metrics'

snip 01-list
run 'git branch'
run 'git branch -v'
run 'git branch -vv'

snip 02-remotes
run 'git branch -r'
run 'git branch -a'

snip 03-merged
run 'git log --oneline --graph --all'
run 'git branch --merged'
run 'git branch --no-merged'
run 'git branch --contains origin/feature/f1'

snip 04-delete
run 'git branch -d docs/metrics'
run_rc 'git branch -d spike/judge-cache'
spike=$(git rev-parse --short spike/judge-cache)
run 'git branch -D spike/judge-cache'
run_rc 'git reflog show spike/judge-cache'
run "git branch spike/judge-cache $spike"
run 'git reflog show spike/judge-cache'

snip 05-upstream-rule
run 'git branch -d fix/typo-readme'
run_rc 'git branch -d feature/f1'

snip 06-rename
run 'git branch -m feature/f1 feature/f1-metric'
run 'git branch -vv'
run 'git config get branch.feature/f1-metric.merge'
run 'git reflog show feature/f1-metric'

snip 07-force
run 'git branch release/0.2 main'
run_rc 'git branch release/0.2 main~1'
run 'git branch -f release/0.2 main~1'
run 'git reflog show release/0.2'
run_rc 'git branch -f main main~1'

lab_end
