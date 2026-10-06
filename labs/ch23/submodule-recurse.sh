#!/usr/bin/env bash
# Keeping the submodule in step automatically: "git submodule update" after a pull, then
# submodule.recurse=true so that pull, switch and checkout do it. Chapter 23, section 23.7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-recurse
fx_docqa_submodule
fx_ravi_clone
fx_textsplit_release
cd doc-qa
quiet "git $FILE_OK submodule update --remote"
commit_all 'Update textsplit to 0.2.0'
quiet 'git push origin main'
cd ../ravi-doc-qa
as ravi

snip 01-two-steps
run 'git pull'
run 'git submodule status'
run 'git submodule update'
run 'git submodule status'
run 'git status --short --branch'

snip 02-switch-without
note 'An older commit of doc-qa records the older library commit. Without recursion:'
run 'git switch --detach HEAD~1'
run 'git submodule status'
run 'git switch -'
run 'git status --short'

snip 03-recurse
run 'git config set submodule.recurse true'
run 'git switch --detach HEAD~1'
run 'git submodule status'
run 'git switch -'
run 'git submodule status'
run 'git config get submodule.recurse'
as you
lab_end
