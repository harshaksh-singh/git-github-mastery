#!/usr/bin/env bash
# Chapter 6, section 6.5: which of the two dates Git uses where. "git log" prints the author
# date by default, while --since and --until select by committer date. A commit that was
# written in August and cherry-picked in September therefore shows an August date in a
# listing of "everything since 1 September". Dates of the older commits are pinned explicitly;
# all of them are earlier than the lab clock.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 date-filters

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add .'
quiet "GIT_AUTHOR_DATE='2026-08-10T11:00:00+05:30' GIT_COMMITTER_DATE='2026-08-10T11:00:00+05:30' git commit -m 'Add exact-match metric'"
quiet 'git switch -c asha/bleu'
as asha
printf 'def bleu(pred, gold, max_n=4):\n    raise NotImplementedError\n' > evalkit/bleu.py
quiet 'git add .'
quiet "GIT_AUTHOR_DATE='2026-08-24T15:20:00+05:30' GIT_COMMITTER_DATE='2026-08-24T15:20:00+05:30' git commit -m 'Add BLEU metric skeleton'"
as you
quiet 'git switch main'
quiet 'git cherry-pick asha/bleu'

snip 01-which-date-is-shown
run 'git log -1'
run "git log --format='%h  authored %as  committed %cs  %an: %s'"

snip 02-which-date-is-filtered
run 'git log --oneline --since=2026-09-01'
run 'git log --oneline --until=2026-09-01'
run "git log --since=2026-09-01 --format='%h  Date: %ad' --date=short"

lab_end
