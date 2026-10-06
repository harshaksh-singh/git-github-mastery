#!/usr/bin/env bash
# Lab 16.4 setup: the monorepo "orbit", packed once, without a commit-graph.
#
#   bash labs/ch26/setup-16-4-commit-graph.sh
#
# builds the repository in $GIT_MASTERY_LABS/hands-on/m16-4/orbit. The lab replay sources this
# file with LAB_REPLAY=1 and builds the same repository in its own sandbox.
# Automatic maintenance is switched off in the repository, so that the commit-graph exists only
# when you write it.
if [ -z "${LAB_REPLAY:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/../lib/lab-env.sh"
  sandbox_begin hands-on m16-4
fi
. "$LAB_LIB/../ch24/fixture-orbit.bash"
orbit_build || exit 1
quiet 'git -C orbit config set maintenance.auto false'
quiet 'git -C orbit -c pack.threads=1 repack -a -d -q && git -C orbit pack-refs --all'
if [ -z "${LAB_REPLAY:-}" ]; then
  printf 'Lab 16.4 sandbox ready. Open a lab shell there:\n  labs/shell m16-4\n  cd orbit\n'
fi
