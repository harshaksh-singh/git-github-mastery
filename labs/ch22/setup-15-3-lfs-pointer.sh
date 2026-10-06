#!/usr/bin/env bash
# Hands-on setup for Lab 15.3: the transcriber repository with two new binary files in the working
# tree, in $GIT_MASTERY_LABS/hands-on/m15-3.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
sandbox_begin hands-on m15-3
fx_transcriber_new_model
handson_ready transcriber
