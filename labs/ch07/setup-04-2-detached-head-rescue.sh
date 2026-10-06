#!/usr/bin/env bash
# Hands-on setup for Lab 4.2 (detached HEAD rescue).
# Creates $GIT_MASTERY_LABS/hands-on/m04-2/evalkit with three commits on main and the
# lightweight tag v0.1.0 on the second commit. Running the script again resets the lab.
. "$(dirname "$0")/../lib/lab-env.sh"
sandbox_begin hands-on m04-2

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

printf 'Lab 4.2 is ready: %s\n' "$LAB_DIR/evalkit"
printf 'Open the lab shell:  labs/shell m04-2\n'
printf 'Then:                cd evalkit\n'
