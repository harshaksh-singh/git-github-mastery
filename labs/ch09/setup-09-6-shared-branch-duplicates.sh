#!/usr/bin/env bash
# Hands-on setup for Lab 9.6: a bare server and two clones (you/ and asha/), as in the replay,
# in $GIT_MASTERY_LABS/hands-on/m09-6.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
sandbox_begin hands-on m09-6
fx_shared_branch
handson_ready you
