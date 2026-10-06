#!/usr/bin/env bash
# Lab 6.7 replay: a conflict that the default style cannot explain, aborted and retried with zdiff3.
# The failure scenario loses an uncommitted edit through "git add -A" followed by "git merge --abort".
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
. "$(dirname "$0")/fixtures/m06.sh"
lab_begin ch08 lab-06-7-abort-retry-zdiff3

quiet 'm06_7_fixture'

snip 01-merge
run 'git log --oneline --graph --all'
run_rc 'git merge feature/unsure-verdict'
run 'git status --short'
run 'cat evalkit/judge.py'

snip 02-abort
run 'git merge --abort'
run 'git status --short --branch'
run "ls .git | grep -E 'MERGE|ORIG_HEAD'"
run 'git rev-parse HEAD ORIG_HEAD'
run 'git reflog -1'

snip 03-retry
run 'git config set merge.conflictStyle zdiff3'
run 'git config get --show-origin merge.conflictStyle'
run_rc 'git merge feature/unsure-verdict'
run 'cat evalkit/judge.py'

snip 04-intent
run 'git ls-files -u'
note 'stage 1 to stage 2: what OUR side did to the common ancestor'
run 'git diff -U0 :1:evalkit/judge.py :2:evalkit/judge.py'
note 'stage 1 to stage 3: what THEIR side did to it'
run 'git diff -U0 :1:evalkit/judge.py :3:evalkit/judge.py'

snip 05-resolve
note 'In your editor: keep their UNSURE branch and our "return None". Delete the markers and the base section.'
quiet "ek_replace_conflict evalkit/judge.py '    if text.startswith(\"UNSURE\"):\\n        return 0.5\\n    return None'"
run 'cat evalkit/judge.py'
run 'git add evalkit/judge.py'
run_rc 'git diff --cached --check'
run 'git merge --continue'

snip 06-checkpoint
run 'git log --oneline --graph -5'
run 'git show --remerge-diff --format="%h %s" HEAD'

# ---- Failure scenario: an uncommitted edit, the "git add -A" reflex, and an abort.
snip 07-failure
run 'echo "Think step by step before you answer." >> prompts/judge.txt'
run 'git status --short'
run_rc 'git merge feature/short-errors'
note 'In your editor: keep our three lines, delete the rest of the conflict block. Then the reflex:'
quiet "ek_replace_conflict evalkit/judge.py '    if text.startswith(\"UNSURE\"):\\n        return 0.5\\n    return None'"
run 'git add -A'
run 'git status --short'
note 'Ravi tells you the branch is not ready. You abort.'
run 'git merge --abort'
run 'git status --short --branch'
run 'tail -1 prompts/judge.txt'

snip 08-recovery
run 'git stash list'
run 'git fsck | grep commit'
WIP=$(git fsck 2>/dev/null | awk '$2 == "commit" { print $3 }')
WIP=$(git rev-parse --short "$WIP")
run "git show -s --format='%h %s' $WIP"
run "git diff --stat $WIP^1 $WIP"
run "git restore --source=$WIP -- prompts/judge.txt"
run 'git status --short'
run 'tail -1 prompts/judge.txt'

snip 09-verification
note 'The same reflex, this time with the edit protected by --autostash:'
run_rc 'git merge --autostash feature/short-errors'
quiet "ek_replace_conflict evalkit/judge.py '    if text.startswith(\"UNSURE\"):\\n        return 0.5\\n    return None'"
run 'git add -A'
run 'git status --short'
run 'git merge --abort'
run 'git status --short'
run 'tail -1 prompts/judge.txt'

lab_end
