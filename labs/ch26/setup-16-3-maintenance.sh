#!/usr/bin/env bash
# Lab 16.3 setup: the monorepo "orbit" as 507 loose objects, never maintained.
#
#   bash labs/ch26/setup-16-3-maintenance.sh
#
# builds the repository in $GIT_MASTERY_LABS/hands-on/m16-3/orbit (default root:
# ~/git-mastery-labs). The lab replay sources this file with LAB_REPLAY=1, so it builds exactly
# the same repository, with the same object IDs, in its own sandbox.
# Automatic maintenance is switched off in the repository (maintenance.auto=false), so that no
# background process changes the object database while you are looking at it.
if [ -z "${LAB_REPLAY:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/../lib/lab-env.sh"
  sandbox_begin hands-on m16-3
fi
. "$LAB_LIB/../ch24/fixture-orbit.bash"
orbit_build || exit 1
quiet 'git -C orbit config set maintenance.auto false'
if [ -z "${LAB_REPLAY:-}" ]; then
  printf 'Lab 16.3 sandbox ready. Open a lab shell there:\n  labs/shell m16-3\n  cd orbit\n'
fi
