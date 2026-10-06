#!/usr/bin/env bash
# Chapter 6, section 6.3: what "git add" and "git commit" write inside .git. The blob is written
# by "git add"; "git commit" writes the trees and the commit object, moves the branch ref,
# appends to two reflogs, rewrites the index and COMMIT_EDITMSG, and does not touch .git/HEAD.
# The file comparison uses checksums of every file under .git, not timestamps, so the result
# does not depend on the file system or on the clock.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 inside-git

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf '\n\ndef f1(pred, gold):\n    return 0.0  # placeholder until the tokenizer lands\n' >> evalkit/metrics.py

snip 01-add-writes-the-blob
note 'evalkit/metrics.py has been edited: it now also defines f1().'
run 'objects() { git cat-file --batch-all-objects --batch-check | sort; }'
run 'objects > ../objects-before-add.txt'
run 'git add evalkit/metrics.py'
run 'objects | comm -13 ../objects-before-add.txt -'

snip 02-commit-writes-trees-and-commit
run 'objects > ../objects-before-commit.txt'
run "files() { find .git -type f -exec shasum {} + | sort; }"
run 'files > ../files-before-commit.txt'
run 'git commit -q -m "Add F1 metric"'
run 'objects | comm -13 ../objects-before-commit.txt -'

snip 03-files-touched
note 'Every file under .git that is new, or whose content differs from the snapshot taken before the commit:'
run "files | comm -13 ../files-before-commit.txt - | awk '{print \$2}' | sort"
run 'cat .git/COMMIT_EDITMSG'
run 'cat .git/HEAD'

lab_end
