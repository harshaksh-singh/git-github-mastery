#!/usr/bin/env bash
# Chapter 7, section 7.9: Git has no parent-branch concept. A branch created "from" another
# branch records nothing about it except a line in a local reflog; commits do not record the
# branch they were made on; and the base of a comparison is always something you choose.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 no-parent-branch

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
quiet 'git switch -c feature/rouge'
printf 'def rouge_l(pred, gold):\n    raise NotImplementedError\n' > evalkit/rouge.py
quiet 'git add . && git commit -m "Add ROUGE-L metric"'
printf 'def lcs(a, b):\n    return 0\n\n\ndef rouge_l(pred, gold):\n    return lcs(pred.split(), gold.split())\n' > evalkit/rouge.py
quiet 'git commit -am "ROUGE-L: tokenize on whitespace"'

snip 01-created-from
run 'git switch -c feature/rouge-stemming feature/rouge'
run 'cat .git/refs/heads/feature/rouge-stemming'
run 'git cat-file -p HEAD'
run 'git config list --local'
run 'git reflog show feature/rouge-stemming'

snip 02-which-branch
printf 'def stem(token):\n    return token.rstrip("s")\n' > evalkit/stem.py
quiet 'git add . && git commit -m "ROUGE-L: stem tokens"'
run 'git log --oneline --graph --all'
run 'git branch --contains feature/rouge'
run 'git branch --contains main'

snip 03-you-choose-the-base
run 'git log --oneline main..feature/rouge-stemming'
run 'git log --oneline feature/rouge..feature/rouge-stemming'
run 'git branch -D feature/rouge'
run 'git log --oneline main..feature/rouge-stemming'

lab_end
