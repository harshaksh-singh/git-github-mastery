#!/usr/bin/env bash
# "git restore --staged", "git reset <path>" and "git rm --cached" compared on the two
# cases that matter: a path that HEAD has, and a path that HEAD does not have.
# Chapter 5, section 5.9.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 unstage-three-ways

git init -q support-bot
cd support-bot || exit 1
mkdir -p src
printf 'TOP_K = 5\n' > src/retriever.py
quiet 'git add . && git commit -m "Add retriever"'

snip 01-setup
note 'A tracked file with a staged modification, and a new file that has only been added.'
run "echo 'TOP_K = 8' > src/retriever.py"
run "echo 'SYSTEM = \"You are a support assistant.\"' > src/prompts.py"
run 'git add src/retriever.py src/prompts.py'
run 'git status --short'
run 'git ls-files --stage'

snip 02-restore-staged
note 'restore --staged copies the entry from HEAD. A path HEAD lacks loses its entry.'
run 'git restore --staged src/retriever.py src/prompts.py'
run 'git status --short'
run 'git ls-files --stage'

snip 03-reset-path
quiet 'git add src/retriever.py src/prompts.py'
note 'reset <path> does the same to the index, and reports what is left unstaged.'
run 'git reset src/retriever.py src/prompts.py'
run 'git status --short'
run 'git ls-files --stage'

snip 04-rm-cached
quiet 'git add src/retriever.py src/prompts.py'
note 'rm --cached removes the entry, whatever HEAD has.'
run 'git rm --cached src/retriever.py src/prompts.py'
run 'git status --short'
run 'git ls-files --stage'
note 'For the tracked file that is a staged deletion: the next commit would remove it from the project.'

snip 05-rm-cached-guard
quiet 'git restore --staged src/retriever.py && git add src/retriever.py'
note 'Index, HEAD and working tree now hold three different versions of one file.'
run "echo 'TOP_K = 12' > src/retriever.py"
run_rc 'git rm --cached src/retriever.py'

snip 06-unborn-branch
note 'A repository with no commit yet has no HEAD to copy from.'
run 'cd ..'
run 'git init -q fresh && cd fresh'
run "echo 'TOP_K = 5' > retriever.py"
run 'git add retriever.py'
run 'git status'
run_rc 'git restore --staged retriever.py'
run_rc 'git reset retriever.py'
run 'git status --short'

lab_end
