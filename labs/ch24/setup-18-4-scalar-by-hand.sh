#!/usr/bin/env bash
# Lab 18.4 setup: a bare repository that plays the server, for a clone built the way
# "scalar clone" builds one.
#
#   bash labs/ch24/setup-18-4-scalar-by-hand.sh
#
# builds $GIT_MASTERY_LABS/hands-on/m18-4/server/orbit.git (and the repository ./orbit it was
# made from). The lab replay sources this file with LAB_REPLAY=1.
if [ -z "${LAB_REPLAY:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/../lib/lab-env.sh"
  sandbox_begin hands-on m18-4
fi
. "$LAB_LIB/../ch24/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1
if [ -z "${LAB_REPLAY:-}" ]; then
  printf 'Lab 18.4 sandbox ready. Open a lab shell there:\n  labs/shell m18-4\n'
fi
