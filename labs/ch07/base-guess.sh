#!/usr/bin/env bash
# Chapter 7, section 7.9: the nearest thing Git has to "which branch was this branch made from"
# is a guess. The %(is-base:<commit>) field of git for-each-ref (Git 2.47 and later) marks the
# ref whose first-parent history shares the most with the given commit. The answer depends on
# which refs exist at the moment you ask, because nothing was recorded when the branch was made.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 base-guess

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
quiet 'git switch -c feature/rouge-stemming feature/rouge'
printf 'def stem(token):\n    return token.rstrip("s")\n' > evalkit/stem.py
quiet 'git add . && git commit -m "ROUGE-L: stem tokens"'

snip 01-guess
run 'git log --oneline --decorate'
run "git for-each-ref --format='%(refname:short) %(is-base:feature/rouge-stemming)' refs/heads/main refs/heads/feature/rouge"
run 'git branch -D feature/rouge'
run "git for-each-ref --format='%(refname:short) %(is-base:feature/rouge-stemming)' refs/heads/main"

lab_end
