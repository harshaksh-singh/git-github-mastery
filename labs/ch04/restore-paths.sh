#!/usr/bin/env bash
# "git restore <path>": where the content comes from (the index by default, a commit with
# --source), which trees it overwrites, and what can and cannot be recovered afterwards.
# Chapter 4, section 4.7.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 restore-paths

git init -q support-bot
cd support-bot || exit 1
mkdir -p src config
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'model: small-v1\ntop_k: 3\n' > config/settings.yaml
quiet 'git add . && git commit -m "Add service skeleton"'
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
quiet 'git commit -am "Raise top_k to 5"'

snip 01-from-index
note 'Stage one change, then make a second change that is not staged.'
run "echo 'max_tokens: 512' >> config/settings.yaml"
run 'git add config/settings.yaml'
run "echo 'debug: true' >> config/settings.yaml"
run 'git status --short'
note 'Default source is the index: the unstaged line goes, the staged line stays.'
run 'git restore config/settings.yaml'
run 'cat config/settings.yaml'
run 'git status --short'

snip 02-from-head
note 'With --source, the content comes from a commit. Only the working tree is written.'
run 'git restore --source=HEAD config/settings.yaml'
run 'cat config/settings.yaml'
run 'git status --short'
note 'Add --staged to write the index as well. Now all three trees agree.'
run 'git restore --source=HEAD --staged --worktree config/settings.yaml'
run 'git status --short'

snip 03-deleted-file
run 'rm src/app.py'
run 'git status --short'
run 'git restore src/app.py'
run 'cat src/app.py'

snip 04-older-commit
run 'git log --oneline'
run 'git restore --source=HEAD~1 config/settings.yaml'
run 'cat config/settings.yaml'
run 'git status --short'
run 'git diff'
run 'git restore config/settings.yaml'

snip 05-checkout-equivalent
note 'The older spelling. With a commit named, "git checkout" writes the index too.'
run 'git checkout HEAD~1 -- config/settings.yaml'
run 'git status --short'
run 'git checkout HEAD -- config/settings.yaml'
run 'git status --short'

snip 06-what-survives
note 'The staged line from the first step was written into the object database by "git add".'
run 'git fsck'
run 'git cat-file -p $(git fsck | cut -d" " -f3)'
note 'The line "debug: true" was never added. No object holds it. It is gone.'

lab_end
