#!/usr/bin/env bash
# Chapter 7, section 7.14 (what can go wrong): two commits made on main that belong on a
# feature branch, and never pushed. Because branches are refs, the repair is two ref writes:
# give the commits a new name, then point main back at origin/main. No commit is copied and
# neither the index nor the working tree is touched, so even the uncommitted edit survives.
# The remote is a bare repository on disk; no network is used.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 wrong-branch

quiet 'git init --bare origin.git'
quiet 'git clone origin.git evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def call_judge(client, prompt):\n    return client.post(prompt)\n' > evalkit/judge.py
quiet 'git add . && git commit -m "Add judge client"'
quiet 'git push -u origin main'
printf 'CACHE = {}\n' > evalkit/cache.py
quiet 'git add . && git commit -m "Cache judge responses in memory"'
printf 'CACHE = {}\n\n\ndef cached(key, fn):\n    if key not in CACHE:\n        CACHE[key] = fn()\n    return CACHE[key]\n' > evalkit/cache.py
quiet 'git commit -am "Add cached() helper"'
printf '\nJudge responses are cached per run.\n' >> README.md

snip 01-symptom
run 'git status -sb'
run 'git log --oneline --decorate'

snip 02-two-ref-writes
run 'git switch -c feature/judge-cache'
run 'git branch -f main origin/main'
run 'git log --oneline --decorate'
run 'git status -sb'

snip 03-what-moved
run 'git reflog show main -2'
run 'git reflog -1'
run 'git branch -vv'

lab_end
