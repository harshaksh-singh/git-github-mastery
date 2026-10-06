#!/usr/bin/env bash
# Replay of Lab 2.4: unstage the same two files with "git restore --staged", "git reset" and
# "git rm --cached", compare the index after each, then repeat in a repository with no commits.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/m02-setups.inc"
lab_begin ch05 lab-02-4-unstage-three-ways
m02_4_setup || exit 1
cd support-bot || exit 1

snip 01-start
run 'git log --oneline'
run 'git ls-files --stage'
note 'One helper puts the repository into the same staged state before each experiment.'
run "stage_both() { echo 'TOP_K = 8' > src/retriever.py; echo 'SYSTEM = \"support\"' > src/prompts.py; git add src; }"
run 'stage_both'
run 'git status --short'
run 'git ls-files --stage'

snip 02-restore-staged
note 'Experiment A'
run 'git restore --staged src/retriever.py src/prompts.py'
run 'git status --short'
run 'git ls-files --stage'

snip 03-reset
note 'Experiment B'
run 'stage_both'
run 'git reset src/retriever.py src/prompts.py'
run 'git status --short'
run 'git ls-files --stage'

snip 04-rm-cached
note 'Experiment C'
run 'stage_both'
run 'git rm --cached src/retriever.py src/prompts.py'
run 'git status --short'
run 'git ls-files --stage'
note 'Put the entry for the tracked file back before moving on.'
run 'git restore --staged src/retriever.py'
run 'git status --short'

snip 05-no-commits-yet
note 'Experiment D: the same three commands in a repository that has no commit.'
run 'git init -q ../fresh && cd ../fresh'
run "echo 'TOP_K = 5' > retriever.py && git add retriever.py"
run_rc 'git restore --staged retriever.py'
run_rc 'git reset retriever.py'
run 'git add retriever.py'
run_rc 'git rm --cached retriever.py'
run 'git status --short'
run 'cd ../support-bot'

snip 06-failure
note 'Failure scenario. You want to commit the new prompts file and keep the TOP_K edit for later.'
run 'git add src'
run 'git status --short'
note 'The wrong unstage command for a file that HEAD has:'
run 'git rm --cached src/retriever.py'
run 'git commit -m "Add system prompt"'
run 'git ls-files'
run 'git status --short'

snip 07-recovery
note 'Copy the entry back into the index from the commit before the mistake. The working tree is not touched.'
run 'git restore --source=HEAD~1 --staged src/retriever.py'
run 'git status --short'
run 'git commit -m "Restore src/retriever.py, removed from the index by mistake"'

snip 08-verification
run 'git ls-files'
run 'git log --oneline --name-status'
note 'The file in HEAD is byte-for-byte what it was before the mistake: this prints nothing.'
run 'git diff HEAD~2 HEAD -- src/retriever.py'
note 'The edit you wanted to keep for later is still waiting, unstaged.'
run 'git status --short'

lab_end
