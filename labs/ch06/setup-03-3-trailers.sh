#!/usr/bin/env bash
# Hands-on setup for Lab 3.3 (trailers).
# Creates $GIT_MASTERY_LABS/hands-on/m03-3/evalkit with one commit and a new, untracked
# file evalkit/judge.py that the lab commits. Running the script again resets the lab.
. "$(dirname "$0")/../lib/lab-env.sh"
sandbox_begin hands-on m03-3

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'import time\n\n\ndef call_judge(client, prompt, attempts=5):\n    for i in range(attempts):\n        r = client.post(prompt)\n        if r.status != 429:\n            return r\n        time.sleep(2 ** i)\n    raise RuntimeError("judge rate limit")\n' > evalkit/judge.py

printf 'Lab 3.3 is ready: %s\n' "$LAB_DIR/evalkit"
printf 'Open the lab shell:  labs/shell m03-3\n'
printf 'Then:                cd evalkit\n'
