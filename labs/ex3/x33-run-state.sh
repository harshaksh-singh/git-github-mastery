#!/usr/bin/env bash
# Exercise 33.4 (Module 33): three evaluation runs "at the same commit". What Git can say
# about the state each one ran from, with four commands.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x33-run-state
hidden 'git init ragbench'
cd ragbench || exit 1
printf 'top_k: 5\ntemperature: 0.0\n' | put configs/eval.yaml
printf 'def score(hits, k):\n    return sum(hits[:k]) / k\n' | put src/ragbench/metrics.py
commit_all 'Add evaluation config and metric'
tick; git tag -a v0.1.0 -m 'ragbench 0.1.0' > /dev/null 2>&1 || exit 1
printf 'runs/\n' | put .gitignore
commit_all 'Ignore run output'
STATE='git rev-parse --short HEAD && git describe --always --dirty --tags && git status --porcelain=v1 && git diff HEAD --stat'

snip 01-run-a
note 'Run A'
run "$STATE"

snip 02-run-b
note 'Run B: someone tries top_k 8 without committing.'
hidden "printf 'top_k: 8\ntemperature: 0.0\n' > configs/eval.yaml"
run "$STATE"
run 'mkdir -p runs/b && git diff HEAD --binary > runs/b/uncommitted.patch'
hidden 'git restore configs/eval.yaml'

snip 03-run-c
note 'Run C: a new module is on the import path, not yet added.'
hidden "printf 'def score(hits, k):\n    return max(hits[:k])\n' > src/ragbench/metrics_v2.py"
run "$STATE"

snip 04-reproduce-b
hidden 'rm src/ragbench/metrics_v2.py'
note 'Reproducing run B from its record: the commit, then the saved patch.'
run 'git status --porcelain=v1'
run 'git apply --check runs/b/uncommitted.patch && git apply runs/b/uncommitted.patch'
run 'git diff HEAD --stat'

lab_end
