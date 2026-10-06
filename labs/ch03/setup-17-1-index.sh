#!/usr/bin/env bash
# Lab 17.1 setup: a small service repository with two branches that change the same line.
#
#   bash labs/ch03/setup-17-1-index.sh
#
# builds $GIT_MASTERY_LABS/hands-on/m17-1/inference-service (default root: ~/git-mastery-labs).
# The lab replays source this file with LAB_REPLAY=1 to build the same repository, with the
# same object IDs, inside their own sandbox.
if [ -z "${LAB_REPLAY:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/../lib/lab-env.sh"
  sandbox_begin hands-on m17-1
fi

quiet 'git init inference-service'
cd inference-service || exit 1
quiet 'mkdir -p src'
quiet "printf 'retry_limit = 3\ntimeout_s = 30\n' > config.toml"
quiet "printf '#!/bin/sh\nexec python3 -m src.server \"\$@\"\n' > run.sh && chmod +x run.sh"
quiet "printf 'def predict(text):\n    return len(text)\n' > src/server.py"
quiet 'git add . && git commit -m "Add inference service skeleton"'

quiet 'git switch -c feature/timeouts'
as asha
quiet "printf 'retry_limit = 3\ntimeout_s = 60\n' > config.toml && git commit -am 'Double the timeout'"
as you
quiet 'git switch main'
quiet "printf 'retry_limit = 3\ntimeout_s = 45\n' > config.toml && git commit -am 'Raise timeout to 45 seconds'"

if [ -z "${LAB_REPLAY:-}" ]; then
  printf 'Lab 17.1 sandbox ready. Open a lab shell there:\n  labs/shell m17-1\n  cd inference-service\n'
fi
