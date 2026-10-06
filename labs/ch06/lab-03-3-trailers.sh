#!/usr/bin/env bash
# Lab 3.3 replay: write trailers with git commit --trailer and -s, read them back with
# git interpret-trailers and %(trailers), define a key alias, then write a trailer Git does
# not recognise and repair the message.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 lab-03-3-trailers

# --- same steps as setup-03-3-trailers.sh
quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'import time\n\n\ndef call_judge(client, prompt, attempts=5):\n    for i in range(attempts):\n        r = client.post(prompt)\n        if r.status != 429:\n            return r\n        time.sleep(2 ** i)\n    raise RuntimeError("judge rate limit")\n' > evalkit/judge.py
# --- end of setup

snip 01-commit
run 'git add evalkit/judge.py'
run "git commit -s -m 'Retry judge calls on HTTP 429' \\
    -m 'The judge endpoint rate-limits bursts. Retry with exponential backoff.' \\
    --trailer 'Co-authored-by: Asha Rao <asha@example.com>' --trailer 'Refs: EVAL-212'"
run 'git log -1 --format=%B'

snip 02-read
run 'git log -1 --format=%B | git interpret-trailers --parse'
run "git log -1 --format='%(trailers:key=Co-authored-by,valueonly)'"

snip 03-alias
run 'git config set trailer.ticket.key Refs'
run "printf '\nJudge calls are retried on HTTP 429.\n' >> README.md"
run "git commit -q -am 'Mention the retry policy in the README' --trailer 'ticket=EVAL-230'"
run 'git log -1 --format=%B'

snip 04-report
run "git log --format='%h | %(trailers:key=Refs,valueonly,separator=%x2C) | %s'"
run 'git shortlog -sn --group=trailer:refs HEAD'

snip 05-failure
run "printf '\nBackoff: 1, 2, 4, 8, 16 seconds.\n' >> README.md"
run "git commit -q -am 'Document the backoff schedule

Refs: EVAL-240

Thanks to the platform team for the numbers.'"
run 'git log -1 --format=%B | git interpret-trailers --parse'
run "git log --format='%h | %(trailers:key=Refs,valueonly,separator=%x2C) | %s'"

snip 06-recovery
run "printf 'Document the backoff schedule\n\nThanks to the platform team for the numbers.\n' > ../msg.txt"
run "git interpret-trailers --in-place --trailer 'Refs: EVAL-240' ../msg.txt"
run 'cat ../msg.txt'
run 'git commit -q --amend -F ../msg.txt'

snip 07-verify
run 'git log -1 --format=%B | git interpret-trailers --parse'
run "git log --format='%h | %(trailers:key=Refs,valueonly,separator=%x2C) | %s'"
run 'git status --short'

lab_end
