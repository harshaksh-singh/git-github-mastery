#!/usr/bin/env bash
# Chapter 6, sections 6.2 and 6.3: what a commit object contains, and what "git commit" does
# step by step: the index becomes a tree, the tree and the metadata become a commit object,
# the current branch ref moves, and two reflogs gain an entry.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 commit-anatomy

snip 01-root-commit
run 'git init evalkit'
run 'cd evalkit'
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
run 'git add README.md evalkit/metrics.py'
run 'git commit -m "Add exact-match metric"'

snip 02-object
run 'git cat-file -t HEAD'
run 'git cat-file -p HEAD'
run "git cat-file -p 'HEAD^{tree}'"

snip 03-step-by-step
cat >> evalkit/metrics.py <<'PY'


def f1(pred, gold):
    p, g = pred.split(), gold.split()
    common = len(set(p) & set(g))
    if common == 0:
        return 0.0
    precision, recall = common / len(p), common / len(g)
    return 2 * precision * recall / (precision + recall)
PY
note 'evalkit/metrics.py has been edited: it now also defines f1().'
run 'git add evalkit/metrics.py'
run 'git write-tree'
run 'git rev-parse HEAD'
run 'git commit -m "Add F1 metric"'
run 'git cat-file -p HEAD'

snip 04-what-moved
run 'cat .git/HEAD'
run 'git rev-parse main'
run 'git reflog'
run 'git reflog show main'

snip 05-show-fuller
run 'git show --format=fuller --stat HEAD'

snip 06-show-raw
run 'git show --format=raw --no-patch HEAD'

lab_end
