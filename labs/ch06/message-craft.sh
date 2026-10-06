#!/usr/bin/env bash
# Chapter 6, section 6.10: commit message craft, with the reasons. A message written as title,
# blank line, body that explains why, trailers; and the places where Git itself reuses the
# title: the "reference" format for citing a commit, one-line logs, shortlog, branch listings,
# reflog entries, and the Subject line and file name that git format-patch derives from it.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 message-craft

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'import time\n\n\ndef call_judge(client, prompt, attempts=5):\n    for i in range(attempts):\n        r = client.post(prompt)\n        if r.status != 429:\n            return r\n        time.sleep(2 ** i)\n    raise RuntimeError("judge rate limit")\n' > evalkit/judge.py
quiet 'git add evalkit/judge.py'
cat > ../msg.txt <<'MSG'
Retry judge calls on HTTP 429

Nightly evaluation runs failed about once a week with "judge rate
limit": the judge endpoint rejects bursts, and one rejected call
aborted the whole run after the generation step had already used
its GPU hours.

Retry up to five times with exponential backoff (1, 2, 4, 8, 16 s).
Other HTTP errors still fail at once, because retrying them would
hide real bugs.

Refs: EVAL-212
MSG

snip 01-message
run 'cat ../msg.txt'
run 'git commit -q -F ../msg.txt'
run 'git show -s --format=reference HEAD'

# A second commit by a colleague, with the kind of title the section argues against.
as asha
printf 'def tokenize(text):\n    return text.split()\n' > evalkit/tokenizer.py
quiet 'git add . && git commit -m "fix stuff"'
as you

snip 02-where-the-title-is-used
run 'git log --oneline'
run 'git shortlog HEAD'
run 'git branch -v'
run 'git reflog -2'

snip 03-format-patch
run 'git format-patch -1 --stdout HEAD~1 | head -n 6'
run 'git format-patch -1 -o ../outbox HEAD~1'

lab_end
