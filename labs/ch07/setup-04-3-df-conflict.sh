#!/usr/bin/env bash
# Hands-on setup for Lab 4.3 (the "feature" versus "feature/x" conflict).
# Creates under $GIT_MASTERY_LABS/hands-on/m04-3:
#   origin.git      a bare repository that plays the server (no network is used)
#   evalkit         your clone, with a local branch named "feature" and a stale origin/feature
#   asha-evalkit    Asha's clone; she has deleted "feature" on the server and pushed "feature/login"
# Running the script again resets the lab.
. "$(dirname "$0")/../lib/lab-env.sh"
sandbox_begin hands-on m04-3

quiet 'git init --bare origin.git'
quiet 'git clone origin.git evalkit'
cd evalkit || exit 1
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
quiet 'git push -u origin main'
quiet 'git branch feature'
quiet 'git push origin feature'
quiet 'git clone ../origin.git ../asha-evalkit'
as asha
quiet 'git -C ../asha-evalkit push origin --delete feature'
quiet 'git -C ../asha-evalkit switch -c feature/login'
printf 'def login(user):\n    raise NotImplementedError\n' > ../asha-evalkit/login.py
quiet 'git -C ../asha-evalkit add . && git -C ../asha-evalkit commit -m "Start login flow"'
quiet 'git -C ../asha-evalkit push origin feature/login'
as you

printf 'Lab 4.3 is ready: %s\n' "$LAB_DIR/evalkit"
printf 'Open the lab shell:  labs/shell m04-3\n'
printf 'Then:                cd evalkit\n'
