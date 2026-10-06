#!/usr/bin/env bash
# Chapter 7, section 7.11: a lightweight tag is a ref under refs/tags that holds a commit ID
# and does not move. First pass only; annotated and signed tags are in chapter 14B.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 lightweight-tags

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'

snip 01-a-ref
run 'git tag v0.1.0'
run 'cat .git/refs/tags/v0.1.0'
run 'git cat-file -t v0.1.0'
run 'git for-each-ref'

snip 02-does-not-move
printf 'def run_batch(examples, metric):\n    return [metric(e.pred, e.gold) for e in examples]\n' > evalkit/runner.py
quiet 'git add . && git commit -m "Add batch runner"'
run 'git log --oneline --decorate'

snip 03-annotated-contrast
run 'git tag -a v0.2.0 -m "Release 0.2.0"'
run 'git cat-file -t v0.2.0'
run "git rev-parse v0.2.0 'v0.2.0^{commit}' HEAD"

snip 04-no-reflog
run 'ls .git/logs/refs'
run_rc 'git tag v0.1.0 HEAD'
run 'git tag -f v0.1.0 HEAD'
run 'git tag -d v0.1.0'

snip 05-ambiguous
run 'git branch v0.2.0 HEAD~1'
run "git log -1 --format='%h %s' v0.2.0"
run "git log -1 --format='%h %s' heads/v0.2.0"
run 'git branch -D v0.2.0'

lab_end
