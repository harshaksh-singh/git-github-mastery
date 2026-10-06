#!/usr/bin/env bash
# Exercise 6.10 (Level 5): the weekly sync that conflicts more every week.
# Builds server.git and the clones you/ and asha/ of the project "sampler-service", with the
# branches main and develop. Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m06-weekly-sync
ex_begin m06-weekly-sync

cfg() { printf '%s\n' "$@" > sampler/config.py; }
ex_server
ex_clone asha
cd asha || exit 1
as asha
mkdir -p sampler
cfg 'TEMPERATURE = 0.7' 'MAX_RETRIES = 2'
printf 'import random\n\n\ndef sample(logits, temperature):\n    scaled = [x / temperature for x in logits]\n    return scaled.index(max(scaled))\n\n\ndef greedy(logits):\n    return logits.index(max(logits))\n' > sampler/sample.py
_c 'Add sampler'
quiet 'git push -u origin main'
quiet 'git switch -c develop'
quiet 'git push -u origin develop'

# Week 36 on develop.
cfg 'TEMPERATURE = 0.8' 'MAX_RETRIES = 2'
_c 'Raise the default temperature to 0.8'
cfg 'TEMPERATURE = 0.8' 'TOP_P = 0.95' 'MAX_RETRIES = 2'
_c 'Add nucleus sampling threshold'
quiet 'git push'
# Friday, week 36: the first sync. Clean.
quiet 'git switch main'
quiet 'git merge --squash develop'
quiet 'git commit -m "Sync develop into main (week 36)"'
quiet 'git push'

# A hotfix that goes to main directly.
as ravi
quiet 'git switch -c hotfix/clamp-temperature main'
printf 'import random\n\n\ndef sample(logits, temperature):\n    temperature = min(max(temperature, 0.01), 2.0)\n    scaled = [x / temperature for x in logits]\n    return scaled.index(max(scaled))\n\n\ndef greedy(logits):\n    return logits.index(max(logits))\n' > sampler/sample.py
_c 'Clamp the temperature to the range the model accepts'
quiet 'git switch main && git merge --ff-only hotfix/clamp-temperature && git branch -d hotfix/clamp-temperature && git push'
as asha

# Week 37 on develop.
quiet 'git switch develop'
cfg 'TEMPERATURE = 0.9' 'TOP_P = 0.95' 'MAX_RETRIES = 2'
_c 'Raise the default temperature to 0.9'
cfg 'TEMPERATURE = 0.9' 'TOP_P = 0.95' 'MAX_RETRIES = 2' 'MAX_TOKENS = 512'
_c 'Add a default output length'
quiet 'git push'
# Friday, week 37: the second sync. One conflict, resolved by taking develop's file.
quiet 'git switch main'
quiet 'git merge --squash develop'
quiet 'git show develop:sampler/config.py > sampler/config.py && git add sampler/config.py'
quiet 'git commit -m "Sync develop into main (week 37)"'
quiet 'git push'

# Week 38 on develop.
quiet 'git switch develop'
cfg 'TEMPERATURE = 0.9' 'TOP_P = 0.9' 'MAX_RETRIES = 2' 'MAX_TOKENS = 512'
_c 'Lower the nucleus threshold to 0.9'
cfg 'TEMPERATURE = 0.9' 'TOP_P = 0.9' 'MAX_RETRIES = 2' 'MAX_TOKENS = 512' 'SEED = 0'
printf 'import random\n\n\ndef sample(logits, temperature):\n    scaled = [x / temperature for x in logits]\n    return scaled.index(max(scaled))\n\n\ndef greedy(logits):\n    return logits.index(max(logits))\n\n\ndef seeded(seed):\n    return random.Random(seed)\n' > sampler/sample.py
_c 'Add a seeded random generator for reproducible runs'
quiet 'git push'
quiet 'git switch main'

cd "$LAB_DIR" || exit 1
as you
ex_clone you
quiet 'git -C you branch develop origin/develop'
ex_note server_main "$(git -C server.git rev-parse refs/heads/main)"
ex_note server_develop "$(git -C server.git rev-parse refs/heads/develop)"

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
