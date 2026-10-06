#!/usr/bin/env bash
# Hands-on setup for Lab 15.4: three model versions committed as ordinary blobs on main and a second
# unpushed branch with a fourth binary, in $GIT_MASTERY_LABS/hands-on/m15-4.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
sandbox_begin hands-on m15-4
fx_transcriber_plain_branch
handson_ready transcriber
