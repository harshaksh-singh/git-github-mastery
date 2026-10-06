#!/usr/bin/env bash
# What "git add" leaves behind: unstaging removes the index entry, not the blob that the add
# wrote. The blob stays in this repository as an unreachable object and is not sent by a push.
# Chapter 5, section 5.3.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 add-leaves-a-blob

git init -q support-bot
cd support-bot || exit 1
mkdir -p src
printf 'def answer(question):\n    return "ok"\n' > src/app.py
quiet 'git add . && git commit -m "Add service skeleton"'
git init -q --bare ../central.git

snip 01-add-then-unstage
run "echo 'LLM_API_KEY=lab-secret-0001' > .env"
note 'The slip: everything is added, including the environment file.'
run 'git add .'
run 'git status --short'
run 'git restore --staged .env'
run 'git status --short'

snip 02-the-blob-is-still-there
blob=$(git hash-object .env)
short=$(git rev-parse --short "$blob")
note 'The index entry is gone. The object that "git add" wrote is not.'
run 'git fsck'
run "git cat-file -p $short"

snip 03-a-push-does-not-send-it
note 'A push sends the objects that the pushed commits need. Nothing refers to this blob.'
run 'git push -q ../central.git main'
run 'git -C ../central.git rev-parse main'
run_rc "git -C ../central.git cat-file -t $short"
run "git cat-file -t $short"

lab_end
