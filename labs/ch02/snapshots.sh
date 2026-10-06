#!/usr/bin/env bash
# Chapter 2, section "Snapshots, not diffs": a commit that changes one of three files
# creates one new blob and reuses the other two. The commit object holds no diff.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 snapshots

quiet 'git init scorer'
cd scorer || exit 1
printf 'def exact_match(pred, gold):\n    return pred.strip() == gold.strip()\n' > metrics.py
printf 'You grade answers. Reply with PASS or FAIL.\n' > judge_prompt.txt
printf 'model: small-v2\ntemperature: 0.0\n' > config.yaml

snip 01-first-commit
run 'ls'
run 'git add .'
run 'git commit -m "Add scorer: metrics, judge prompt, config"'
run 'git ls-tree HEAD'

snip 02-second-commit
run "printf 'model: small-v2\ntemperature: 0.2\n' > config.yaml"
run 'git commit -am "Raise judge temperature to 0.2"'
run 'git ls-tree HEAD~1'
run 'git ls-tree HEAD'

snip 03-all-objects
run 'git cat-file --batch-all-objects --batch-check'

snip 04-no-diff-inside
run 'git cat-file -p HEAD'

snip 05-diff-on-demand
run 'git show HEAD'

lab_end
