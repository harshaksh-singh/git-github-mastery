#!/usr/bin/env bash
# Lab 18.2 setup: a bare repository that plays the server, to be cloned and narrowed.
#
#   bash labs/ch24/setup-18-2-sparse.sh
#
# builds $GIT_MASTERY_LABS/hands-on/m18-2/server/orbit.git (and the repository ./orbit it was
# made from). The lab replay sources this file with LAB_REPLAY=1.
if [ -z "${LAB_REPLAY:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/../lib/lab-env.sh"
  sandbox_begin hands-on m18-2
fi
. "$LAB_LIB/../ch24/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1
if [ -z "${LAB_REPLAY:-}" ]; then
  printf 'Lab 18.2 sandbox ready. Open a lab shell there:\n  labs/shell m18-2\n'
fi
