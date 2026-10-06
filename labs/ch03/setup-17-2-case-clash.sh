#!/usr/bin/env bash
# Lab 17.2 setup for the failure scenario: a server with two branches whose names differ only
# in case, and a clone that is about to fetch updates to both.
#
#   bash labs/ch03/setup-17-2-case-clash.sh
#
# builds, under $GIT_MASTERY_LABS/hands-on/m17-2 (default root: ~/git-mastery-labs):
#   server.git   a bare repository with the branches main, Hotfix and hotfix
#   teammate     the clone that pushed them (it stands in for a colleague on Linux)
#   laptop       your clone, in the default "files" ref format, one fetch behind
# server.git and teammate use the reftable format: that is what lets a Mac, whose filesystem
# does not distinguish Hotfix from hotfix, hold both names at all.
# The lab replay sources this file with LAB_REPLAY=1.
if [ -z "${LAB_REPLAY:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/../lib/lab-env.sh"
  sandbox_begin hands-on m17-2
fi

quiet 'git init --bare --ref-format=reftable server.git'
quiet 'git init --ref-format=reftable teammate'
cd teammate || exit 1
as asha
quiet "printf 'retry_limit = 3\n' > config.toml && git add config.toml && git commit -m 'Add service configuration'"
quiet 'git remote add origin ../server.git'
quiet 'git push origin main'
quiet "git switch -c Hotfix && printf 'retry_limit = 4\n' > config.toml && git commit -am 'Hotfix: allow four retries'"
quiet "git switch -c hotfix main && printf 'timeout_s = 10\n' >> config.toml && git commit -am 'hotfix: add a ten second timeout'"
quiet 'git push origin Hotfix hotfix'
as you
cd .. || exit 1

# Your clone, made while each of the two branches had one commit.
quiet 'git clone server.git laptop'

# The teammate then adds one commit to each branch and pushes again.
cd teammate || exit 1
as asha
quiet "printf 'timeout_s = 15\n' >> config.toml && git commit -am 'hotfix: raise the timeout to fifteen seconds'"
quiet "git switch Hotfix && printf 'backoff_ms = 200\n' >> config.toml && git commit -am 'Hotfix: add backoff'"
quiet 'git push origin Hotfix hotfix'
as you
cd .. || exit 1

if [ -z "${LAB_REPLAY:-}" ]; then
  printf 'Lab 17.2 sandbox ready. Open a lab shell there:\n  labs/shell m17-2\n'
fi
