#!/usr/bin/env bash
# Chapter 6, section 6.5: author versus committer, the two timestamps, and time zones.
# Shows the three everyday ways the two identities come apart: cherry-pick, --author, and amend.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 author-committer

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'

# Asha writes a commit on her own branch.
quiet 'git switch -c asha/bleu'
as asha
printf 'def bleu(pred, gold, max_n=4):\n    raise NotImplementedError\n' > evalkit/bleu.py
quiet 'git add . && git commit -m "Add BLEU metric skeleton"'
as you
quiet 'git switch main'

snip 01-cherry-pick
run 'git log -1 --format=fuller asha/bleu'
run 'git cherry-pick asha/bleu'
run 'git log -1 --format=fuller'

snip 02-author-option
printf 'def rouge_l(pred, gold):\n    raise NotImplementedError\n' > evalkit/rouge.py
note 'Ravi mailed you evalkit/rouge.py from San Francisco. You commit it under his name and his date.'
run 'git add evalkit/rouge.py'
run "git commit --author='Ravi Menon <ravi@example.com>' --date='2026-09-03T09:30:00-07:00' -m 'Add ROUGE-L metric skeleton'"
run 'git cat-file -p HEAD'

snip 03-dates
run "git log -1 --format='author:    %ad%ncommitter: %cd'"
run "git log -1 --format='author:    %ad%ncommitter: %cd' --date=iso-local"
run "git log -1 --format='author:    %ad%ncommitter: %cd' --date=unix"

snip 04-who
run "git log --format='%h  author: %an  committer: %cn  %s'"
run 'git shortlog -sn HEAD'
run 'git shortlog -sn --committer HEAD'
run 'git log --oneline --author=Asha'
run 'git log --oneline --committer=Asha'

snip 05-amend
quiet 'git reset --hard HEAD~1'
note 'HEAD is the cherry-picked commit again: author Asha, committer you.'
run 'git commit --amend --no-edit'
run 'git log -1 --format=fuller'
run 'git commit --amend --no-edit --reset-author'
run 'git log -1 --format=fuller'

lab_end
