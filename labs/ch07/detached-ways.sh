#!/usr/bin/env bash
# Chapter 7, section 7.7: more ways HEAD becomes detached, beyond the ones in detached-head.sh.
# A commit named by ID or by a relative name, a clone made with --branch <tag> (the shape of
# many deploy and CI scripts), and a linked worktree created from a tag.
# The remote is a bare repository on disk; no network is used.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 detached-ways

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
quiet 'git push -u origin main --tags'

snip 01-by-commit
first=$(git rev-parse --short HEAD~2)
run 'git switch --detach HEAD~1'
run 'git status'
run "git -c advice.detachedHead=false checkout $first"
run 'git status'
run 'git switch main'

snip 02-clone-at-a-tag
note 'A deploy script that clones one release. The detached-HEAD advice is switched off to keep the transcript short.'
run 'git -c advice.detachedHead=false clone -q --branch v0.1.0 ../origin.git ../deploy'
run 'cat ../deploy/.git/HEAD'
run 'git -C ../deploy status'
run 'git -C ../deploy branch -a'

snip 03-worktree-from-a-tag
run 'git worktree add ../evalkit-v0.1.0 v0.1.0'
run 'git -C ../evalkit-v0.1.0 status'
run 'git branch'
run 'git worktree remove ../evalkit-v0.1.0'

lab_end
