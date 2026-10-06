#!/usr/bin/env bash
# Replay of the local steps of Lab 26.6: the Git facts from which docker/metadata-action derives
# image tags (branch name, short commit ID, version tag), and the tag push that starts the workflow.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch20a lab-26-6-image-tags
scenario_base
cd "$LAB_DIR/you/inventory-api" || exit 1

snip 01-inputs
run 'git branch --show-current'
run 'git rev-parse --short=7 HEAD'
run 'git tag -a v0.2.0 -m "inventory-api 0.2.0"'
run 'git push origin v0.2.0'
run 'git ls-remote --tags origin'
run 'git for-each-ref --format="%(refname) %(objecttype)" refs/tags'
lab_end
