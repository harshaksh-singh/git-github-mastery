#!/usr/bin/env bash
# Chapter 6, section 6.9: trailers. They are plain lines at the end of the message that
# follow a "Key: value" convention. git commit --trailer and -s write them,
# git interpret-trailers and the %(trailers) placeholder read them.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 trailers

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'import time\n\n\ndef call_judge(client, prompt, attempts=5):\n    for i in range(attempts):\n        r = client.post(prompt)\n        if r.status != 429:\n            return r\n        time.sleep(2 ** i)\n    raise RuntimeError("judge rate limit")\n' > evalkit/judge.py

snip 01-write
run 'git add evalkit/judge.py'
run "git commit -s -m 'Retry judge calls on HTTP 429' \\
    -m 'The judge endpoint rate-limits bursts. Retry with exponential backoff, at most five attempts.' \\
    --trailer 'Co-authored-by: Asha Rao <asha@example.com>' --trailer 'Refs: EVAL-212'"
run 'git cat-file -p HEAD'

snip 02-read
run 'git log -1 --format=%B | git interpret-trailers --parse'
run "git log -1 --format='%(trailers:key=Refs,valueonly)'"
run "git log --oneline --grep='^Refs: EVAL-212'"
run 'git shortlog -sn --group=author --group=trailer:co-authored-by HEAD'

snip 03-rules
note 'A trailer block is the last paragraph, and it must look like trailers.'
run "printf 'Fix tokenizer\n\nRefs: EVAL-300\n' | git interpret-trailers --parse"
run "printf 'Fix tokenizer\nRefs: EVAL-300\n' | git interpret-trailers --parse"
run "printf 'Fix tokenizer\n\nSee the design note.\nRefs: EVAL-300\n' | git interpret-trailers --parse"
run "printf 'Fix tokenizer\n\nSee the design note.\nRefs: EVAL-300\n' | git -c trailer.ticket.key=Refs interpret-trailers --parse"
run "printf 'Fix tokenizer\n\nRefs: EVAL-300\n\nThanks to the platform team.\n' | git interpret-trailers --parse"

lab_end
