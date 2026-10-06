#!/usr/bin/env bash
# Gate 7 (Actions), hands-on: the Git evidence for case 2 of both variants, and the local
# reproduction for the answer key. Plain Git imitates what GitHub does; nothing is run on GitHub.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g7-evidence

# ---- Variant A, case 2: "it passes on my laptop, on the same commit"
quiet 'git init --bare server.git'
quiet 'git clone server.git you && git -C you remote set-url origin ../server.git'
cd you || exit 1
printf 'MAX_BATCH = 64\n' > limits.py
printf '#!/bin/sh\n# The check that CI runs: every batch the batcher produces must fit the limit.\nmax=$(sed -n "s/^MAX_BATCH = //p" limits.py)\nsize=$(sed -n "s/^BATCH = //p" batcher.py 2>/dev/null || echo 0)\nif [ "${size:-0}" -le "$max" ]; then echo "check: ok (batch ${size:-0}, limit $max)"; else echo "check: FAILED (batch $size exceeds limit $max)"; exit 1; fi\n' > check.sh
quiet 'git add . && git commit -m "Add batch limit and its check"'
quiet 'git push -u origin main'
quiet 'git switch -c feature/bigger-batches'
printf 'BATCH = 48\n' > batcher.py
quiet 'git add . && git commit -m "Batch 48 requests at a time"'
quiet 'git push -u origin feature/bigger-batches'
as asha
quiet 'git switch main'
printf 'MAX_BATCH = 32\n' > limits.py
quiet 'git commit -am "Lower the batch limit after the latency incident"'
quiet 'git push origin main'
quiet 'git reset --hard HEAD~1'      # your laptop has not fetched Asha's commit
as you
quiet 'git switch feature/bigger-batches'

snip a2-laptop
run 'git status -sb'
run 'git log --oneline -2'
run 'sh check.sh'
snip a2-reproduce
run 'git fetch origin'
run 'git log --oneline --graph --all'
note 'What the runner tested: the result of merging the head into the base.'
run 'git switch -q --detach origin/main'
run 'git merge -q --no-ff -m "Merge feature/bigger-batches into main" feature/bigger-batches'
run_rc 'sh check.sh'
run 'git switch -q feature/bigger-batches'
cd "$LAB_DIR"

# ---- Variant B, case 2: "it passes on every Mac"
quiet 'git init prompt-svc'
cd prompt-svc || exit 1
mkdir -p prompts
printf 'You are a careful assistant.\n' > prompts/System.txt
printf 'def system_prompt():\n    with open("prompts/system.txt") as f:\n        return f.read()\n\nprint(len(system_prompt()))\n' > app.py
quiet 'git add . && git commit -m "Add system prompt and app"'
snip b2-evidence
run 'git ls-files'
run 'grep -n open app.py'
run "git log --name-status --format='%h %s' -1"
lab_end
