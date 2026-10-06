#!/usr/bin/env bash
# Lab 18.3 setup: the monorepo "orbit", packed, as the connected site of a bundle round trip.
#
#   bash labs/ch26/setup-18-3-bundles.sh
#
# builds $GIT_MASTERY_LABS/hands-on/m18-3/orbit. The lab replay sources this file with
# LAB_REPLAY=1. Automatic maintenance is switched off in the repository.
if [ -z "${LAB_REPLAY:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/../lib/lab-env.sh"
  sandbox_begin hands-on m18-3
fi
. "$LAB_LIB/../ch24/fixture-orbit.bash"
orbit_build || exit 1
orbit_pack || exit 1
quiet 'git -C orbit config set maintenance.auto false'
if [ -z "${LAB_REPLAY:-}" ]; then
  printf 'Lab 18.3 sandbox ready. Open a lab shell there:\n  labs/shell m18-3\n'
fi
