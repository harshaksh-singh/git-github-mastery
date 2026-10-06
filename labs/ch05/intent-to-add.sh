#!/usr/bin/env bash
# "git add -N": record that a path will be added, without adding its content.
# Chapter 5, section 5.6.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 intent-to-add

git init -q support-bot
cd support-bot || exit 1
mkdir -p src
printf 'def answer(question):\n    return "ok"\n' > src/app.py
quiet 'git add . && git commit -m "Add service skeleton"'
printf 'SYSTEM = "You are a support assistant."\nMAX_TURNS = 6\n' > src/prompts.py

snip 01-untracked-is-invisible-to-diff
run 'git status --short'
run 'git diff'
note 'A new file does not appear in "git diff": there is no index entry to compare it with.'

snip 02-add-n
run 'git add -N src/prompts.py'
run 'git status'
run 'git ls-files --stage'

snip 03-now-diff-sees-it
run 'git diff'
run 'git diff --cached'
note 'Nothing is staged: the entry is a placeholder, and "git commit" has nothing to record.'
run_rc 'git commit -m "Add prompts"'

snip 04-index-version
note 'The intent-to-add flag lives in an extended flags field, which needs index version 3.'
run 'git update-index --show-index-version'
run 'git add src/prompts.py'
run 'git ls-files --stage'
run 'git update-index --show-index-version'

lab_end
