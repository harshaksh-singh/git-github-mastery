#!/usr/bin/env bash
# Lab 3.2 replay: an amend that changes nothing except the committer date still produces a new
# commit ID. Pinning the date makes the ID reproducible, and restoring the original date
# reproduces the original ID.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 lab-03-2-committer-date

# --- same steps as setup-03-2-committer-date.sh
quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf '\n\ndef f1(pred, gold):\n    return 0.0  # placeholder until the tokenizer lands\n' >> evalkit/metrics.py
quiet 'git commit -am "Add F1 metric"'
# --- end of setup

snip 01-before
run 'git cat-file -p HEAD'
run 'git rev-parse HEAD'
run 'orig=$(git log -1 --format=%cd --date=raw); echo "$orig"'

snip 02-amend-nothing
run 'git commit --amend --no-edit'
run 'git rev-parse HEAD'

snip 03-one-line-differs
run "diff <(git cat-file -p 'HEAD@{1}') <(git cat-file -p HEAD)"
run "git rev-parse 'HEAD@{1}^{tree}' 'HEAD^{tree}'"
run "git diff --stat 'HEAD@{1}' HEAD"

snip 04-pinned
run "GIT_COMMITTER_DATE='2026-09-07T12:00:00+05:30' git commit --amend --no-edit"
run 'git rev-parse HEAD'
run "GIT_COMMITTER_DATE='2026-09-07T12:00:00+05:30' git commit --amend --no-edit"
run 'git rev-parse HEAD'

snip 05-original-id
run 'GIT_COMMITTER_DATE="@$orig" git commit --amend --no-edit'
run 'git rev-parse HEAD'

snip 06-failure
run 'deployed=$(git rev-parse HEAD); echo "$deployed"'
run 'git commit --amend --no-edit'
run 'git merge-base --is-ancestor "$deployed" HEAD; echo "exit status: $?"'
run 'git branch --contains "$deployed"'
run 'git diff --quiet "$deployed" HEAD; echo "exit status: $?"'

snip 07-recovery
run 'git reset --soft "$deployed"'
run 'git rev-parse HEAD'
run 'git merge-base --is-ancestor "$deployed" HEAD; echo "exit status: $?"'
run 'git status --short'

snip 08-verify
run 'git log --oneline'
run 'git reflog'
run 'git fsck --no-reflogs'

lab_end
