#!/usr/bin/env bash
# Replay of the Git side of Lab 26.2: a branch with a lint error is pushed, which is what a
# pull request for it would contain. ruff and uv are not run here (they are not part of the lab
# environment); the GitHub steps cannot be replayed.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch20a lab-26-2-lint-branch
scenario_base
cd "$LAB_DIR/you/inventory-api" || exit 1

snip 01-branch
run 'git switch -c break/unused-import'
run "sed -i.bak 's/^LOW_STOCK_THRESHOLD/import os\\
\\
LOW_STOCK_THRESHOLD/' src/inventory_api/stock.py && rm src/inventory_api/stock.py.bak"
run 'git diff'
run 'git commit --quiet -am "Add an unused import on purpose"'
run 'git push --quiet -u origin break/unused-import'
note 'What the pull request would list and show:'
run 'git log --oneline origin/main..HEAD'
run 'git diff --stat origin/main...HEAD'
lab_end
