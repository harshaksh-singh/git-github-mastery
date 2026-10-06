#!/usr/bin/env bash
# Chapter 7, section 7.13: stale branches and how to find them. By date of the last commit,
# by merge status, by a deleted upstream ("gone"), and the squash-merge case that --merged
# cannot see. Ends with the Git 2.56 option that this Git 2.55 does not have.
# The remote is a bare repository on disk; no network is used. Commit dates are pinned
# explicitly so that the branches have realistic ages.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 stale-branches

# commit_on <ISO date> <message>: commit what is staged, with both dates pinned.
commit_on() { quiet "GIT_AUTHOR_DATE='$1' GIT_COMMITTER_DATE='$1' git commit -m '$2'"; }

quiet 'git init --bare origin.git'
quiet 'git clone origin.git evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add .'; commit_on '2026-01-12T10:00:00+05:30' 'Add README'
printf 'def exact_match(pred, gold):\n    return float(pred == gold)\n' > evalkit/metrics.py
quiet 'git add .'; commit_on '2026-01-13T11:30:00+05:30' 'Add exact-match metric'
quiet 'git push -u origin main'

# Asha pushes a spike in March and never returns to it.
quiet 'git clone ../origin.git ../asha-evalkit'
as asha
quiet 'git -C ../asha-evalkit switch -c spike/judge-cache'
printf 'CACHE = {}\n' > ../asha-evalkit/evalkit/cache.py
quiet 'git -C ../asha-evalkit add .'
quiet "GIT_AUTHOR_DATE='2026-03-12T16:45:00+05:30' GIT_COMMITTER_DATE='2026-03-12T16:45:00+05:30' git -C ../asha-evalkit commit -m 'Spike: cache judge responses'"
quiet 'git -C ../asha-evalkit push origin spike/judge-cache'
as you
quiet 'git fetch'

# Your ROUGE branch: two commits in June, squash-merged into main in July.
quiet 'git switch -c feature/rouge'
printf 'def rouge_l(pred, gold):\n    raise NotImplementedError\n' > evalkit/rouge.py
quiet 'git add .'; commit_on '2026-06-29T15:00:00+05:30' 'Add ROUGE-L metric'
printf 'def rouge_l(pred, gold):\n    return 0.0\n' > evalkit/rouge.py
quiet 'git add .'; commit_on '2026-06-30T12:10:00+05:30' 'ROUGE-L: return a float'
quiet 'git push -u origin feature/rouge'
quiet 'git switch main'
quiet 'git merge --squash feature/rouge'; commit_on '2026-07-02T09:20:00+05:30' 'Add ROUGE-L metric (#12)'
quiet 'git push'

# A local experiment from August that was never pushed.
quiet 'git switch -c wip/prompt-tuning'
printf 'You are a strict grader.\n' > judge_prompt.txt
quiet 'git add .'; commit_on '2026-08-20T18:05:00+05:30' 'WIP: stricter judge prompt'
quiet 'git switch main'

# A fix from the end of August, merged with a merge commit on 1 September. Every pinned date
# in this script is earlier than the lab clock (7 September 2026), so the pinned commits and
# the commits that take their date from the lab clock form one consistent timeline.
quiet 'git switch -c fix/empty-gold'
printf 'def exact_match(pred, gold):\n    if not gold:\n        return 0.0\n    return float(pred == gold)\n' > evalkit/metrics.py
quiet 'git add .'; commit_on '2026-08-31T10:40:00+05:30' 'Exact match: handle empty gold answer'
quiet 'git push -u origin fix/empty-gold'
quiet 'git switch main'
quiet "GIT_AUTHOR_DATE='2026-09-01T14:00:00+05:30' GIT_COMMITTER_DATE='2026-09-01T14:00:00+05:30' git merge --no-ff fix/empty-gold"
printf 'name: ci\n' > ci.yaml
quiet 'git add . && git commit -m "Add CI workflow"'
quiet 'git push'

snip 01-by-date
run "git for-each-ref --sort=committerdate --format='%(committerdate:short) %(authorname) | %(refname:short)' refs/heads"
run "git for-each-ref --sort=committerdate --exclude=refs/remotes/origin/HEAD --format='%(committerdate:short) %(authorname) | %(refname:short)' refs/remotes/origin"
run "git for-each-ref --sort=committerdate --format='%(committerdate:short) %(refname:short)' refs/remotes/origin | awk '\$1 < \"2026-07-01\"'"

snip 02-merged
run 'git branch --merged main'
run 'git branch --no-merged main'
run 'git branch -r --no-merged origin/main'

snip 03-gone
as asha
quiet 'git -C ../asha-evalkit push origin --delete feature/rouge fix/empty-gold'
as you
note 'The two merged branches have been deleted on the server.'
run 'git fetch --prune'
run 'git branch -vv'
run "git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads"

snip 04-squash-merged
run 'git branch -d fix/empty-gold'
run_rc 'git branch -d feature/rouge'
run 'git merge-tree --write-tree main feature/rouge'
run "git rev-parse 'main^{tree}'"
run 'git branch -D feature/rouge'

snip 05-git-2-56
run "git branch --delete-merged 'origin/*' 2>&1 | head -n 1"

lab_end
