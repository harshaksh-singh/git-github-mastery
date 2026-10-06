#!/usr/bin/env bash
# Chapter 7, section 7.4: what a commit does to the current branch. HEAD keeps naming the same
# branch; the branch ref moves to the new commit; other branches stay; two reflogs grow.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 commit-moves-branch

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def call_judge(client, prompt):\n    return client.post(prompt)\n' > evalkit/judge.py
quiet 'git add . && git commit -m "Add judge client"'

snip 01-before
run 'git switch -c feature/retry-backoff'
run 'cat .git/HEAD'
run "git for-each-ref --format='%(objectname:short) %(refname)' refs/heads"

snip 02-commit
printf 'import time\n\n\ndef call_judge(client, prompt, attempts=5):\n    for i in range(attempts):\n        r = client.post(prompt)\n        if r.status != 429:\n            return r\n        time.sleep(2 ** i)\n    raise RuntimeError("judge rate limit")\n' > evalkit/judge.py
note 'evalkit/judge.py has been edited: call_judge() now retries on HTTP 429.'
run 'git commit -am "Retry judge calls on HTTP 429"'

snip 03-after
run 'cat .git/HEAD'
run "git for-each-ref --format='%(objectname:short) %(refname)' refs/heads"
run 'git reflog show feature/retry-backoff'
run 'git reflog -2'
run 'git log --oneline --graph --all'

lab_end
