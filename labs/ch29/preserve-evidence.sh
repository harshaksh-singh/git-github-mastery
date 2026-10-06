#!/usr/bin/env bash
# Chapter 29, section 29.7: preserving evidence before acting. The repository of worked case 1
# (a stopped rebase with commits on the detached HEAD), plus one staged and one unstaged edit.
# Four layers: the recorded output, a backup ref, a copy of the repository, a bundle. Then the
# proof: the state is destroyed on purpose and each layer is asked what it still holds.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch29 preserve-evidence
fx_case_rebase
cd scoring-api || exit 1
quiet "printf 'workers: 8\nlatency_budget_ms: 150\ntimeout_s: 30\n' > config/service.yaml && git add config/service.yaml"
quiet "printf '\nBudget violations are logged by app/audit.py.\n' >> README.md"
tip=$(git rev-parse --short HEAD)

snip 01-record
run 'mkdir ../evidence'
run '{ git status; git branch -vv; git log --graph --decorate --oneline --all; git reflog; } > ../evidence/state.txt 2>&1'
run 'git diff > ../evidence/unstaged.patch'
run 'git diff --cached > ../evidence/staged.patch'
run 'git status --short'
run 'grep -c "" ../evidence/state.txt ../evidence/unstaged.patch ../evidence/staged.patch'

snip 02-backup-ref
run 'git branch rescue/latency-wip HEAD'
run 'git update-ref refs/backup/latency-budget feature/latency-budget'
run 'git for-each-ref refs/heads/rescue refs/backup'

snip 03-copy
run 'cp -Rp . ../evidence/scoring-api-copy'
run 'git -C ../evidence/scoring-api-copy status | head -4'
run 'git -C ../evidence/scoring-api-copy status --short'
run 'git -C ../evidence/scoring-api-copy reflog -3'

snip 04-bundle
run 'git bundle create ../evidence/scoring-api.bundle --all'
run 'git bundle verify ../evidence/scoring-api.bundle'

snip 05-destroy
note 'The worst afternoon: the rebase is aborted, the anchors are deleted, the reflogs are'
note 'emptied and the unreachable objects are pruned. Do not run this on a repository you need.'
run 'git rebase --abort'
run 'git branch -D rescue/latency-wip'
run 'git update-ref -d refs/backup/latency-budget'
run 'git reflog expire --expire=now --all'
run 'git gc --quiet --prune=now'
run_rc "git cat-file -t $tip"
run 'git status --short'

snip 06-from-bundle
run "git fetch ../evidence/scoring-api.bundle 'refs/heads/rescue/*:refs/heads/rescue/*'"
run 'git log --oneline -3 rescue/latency-wip'
run 'git reflog show rescue/latency-wip'

snip 07-from-copy
run 'cd ../evidence/scoring-api-copy'
run 'git status --short'
run 'git reflog -3'
run 'cat .git/rebase-merge/head-name'
run 'git diff --cached --stat'

lab_end
