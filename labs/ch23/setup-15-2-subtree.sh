#!/usr/bin/env bash
# Hands-on setup for Lab 15.2: the library and the service without any dependency between them, and
# Asha's unpublished 0.2.0, in $GIT_MASTERY_LABS/hands-on/m15-2.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
sandbox_begin hands-on m15-2
fx_docqa_subtree_start
fx_textsplit_release_prepared
handson_ready doc-qa
