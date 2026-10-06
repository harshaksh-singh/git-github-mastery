#!/usr/bin/env bash
# Chapter 1, section "What can go wrong": four first-day failures and what Git prints.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch01 pitfalls

snip 01-unconfigured-init
note 'With no configuration at all, Git 2.55 still names the first branch master.'
run 'GIT_CONFIG_GLOBAL=/dev/null git init plain'
run 'cat plain/.git/HEAD'
run 'git -C plain branch -m main'
run 'cat plain/.git/HEAD'

snip 02-not-a-repository
run 'mkdir notes && cd notes'
run_rc 'git status'
run 'cd ..'

snip 03-nothing-staged
quiet 'git init rag-eval'
cd rag-eval || exit 1
quiet "echo '# rag-eval' > README.md && git add README.md && git commit -m 'Add README'"
run "echo 'Evaluation harness.' >> README.md"
run_rc 'git commit -m "Describe the project"'

snip 04-embedded-repository
quiet 'git restore README.md'
quiet 'mkdir vendor && git init vendor/tokenizer'
quiet "cd vendor/tokenizer && echo 'lowercase' > rules.txt && git add rules.txt && git commit -m 'Add rules' && cd ../.."
run 'git status --short'
run 'git add .'
run 'git ls-files --stage'

snip 05-embedded-undo
note 'The command from the hint is refused. Unstaging with git restore works.'
run_rc 'git rm --cached vendor/tokenizer'
run 'git restore --staged vendor/tokenizer'
run 'git status --short'

lab_end
