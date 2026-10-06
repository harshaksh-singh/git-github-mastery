#!/usr/bin/env bash
# Lab 17.3 setup: a repository in which a merge, a cherry-pick, a revert and a rebase can all be
# stopped half-way, plus a bare repository to fetch from.
#
#   bash labs/ch03/setup-17-3-special-refs.sh
#
# builds, under $GIT_MASTERY_LABS/hands-on/m17-3 (default root: ~/git-mastery-labs):
#   server.git          a bare repository that holds the first commit of main
#   inference-service   your repository: main is two commits ahead of the server, and
#                       feature/timeouts changes the same line as main does
# The lab replay sources this file with LAB_REPLAY=1.
if [ -z "${LAB_REPLAY:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/../lib/lab-env.sh"
  sandbox_begin hands-on m17-3
fi

quiet 'git init --bare server.git'
quiet 'git init inference-service'
cd inference-service || exit 1
quiet "printf 'retry_limit = 3\ntimeout_s = 30\n' > config.toml && git add config.toml && git commit -m 'Add service configuration'"
quiet 'git remote add origin ../server.git'
quiet 'git push -u origin main'

quiet 'git switch -c feature/timeouts'
as asha
quiet "printf 'retry_limit = 3\ntimeout_s = 60\n' > config.toml && git commit -am 'Double the timeout'"
as you
quiet 'git switch main'
quiet "printf 'retry_limit = 3\ntimeout_s = 45\n' > config.toml && git commit -am 'Raise timeout to 45 seconds'"
quiet "printf 'log_level = \"info\"\n' > logging.toml && git add logging.toml && git commit -m 'Add logging configuration'"

if [ -z "${LAB_REPLAY:-}" ]; then
  printf 'Lab 17.3 sandbox ready. Open a lab shell there:\n  labs/shell m17-3\n  cd inference-service\n'
fi
