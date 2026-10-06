#!/usr/bin/env bash
# Chapter 6, section 6.10: how Git itself reads a commit message. The title is everything up
# to the first blank line, and lines that start with "#" are removed when the message goes
# through the editor.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 message

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def f1(pred, gold):\n    return 0.0  # placeholder until the tokenizer lands\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add F1 metric"'

snip 01-title
printf 'def tokenize(text):\n    return text.split()\n' > evalkit/tokenizer.py
quiet 'git add evalkit/tokenizer.py'
printf 'Add whitespace tokenizer\nF1 and ROUGE need the same token boundaries.\n' > msg.txt
run 'cat msg.txt'
run 'git commit -q -F msg.txt'
run 'git log --oneline -1'
run "git log -1 --format='subject=[%s]%nbody=[%b]'"

snip 02-comment-lines
printf 'def f1(pred, gold):\n    if not gold.split():\n        return 0.0\n    return 0.0  # placeholder until the tokenizer lands\n' > evalkit/metrics.py
quiet 'git add evalkit/metrics.py'
printf 'Handle empty references in F1\n\n#212 reported a ZeroDivisionError when the gold answer is empty.\nReturn 0.0 instead.\n' > msg.txt
run 'cat msg.txt'
run 'git commit -q -F msg.txt --edit'
run 'git log -1 --format=%B'
run 'git commit -q --amend -F msg.txt'
run 'git log -1 --format=%B'

lab_end
