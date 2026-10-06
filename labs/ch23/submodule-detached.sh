#!/usr/bin/env bash
# Work done inside a submodule on the detached HEAD that "submodule update" leaves, then lost from
# view by the next update; the reflog rescue; and the way to avoid it. Chapter 23, section 23.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-detached
fx_docqa_submodule
fx_ravi_clone
fx_textsplit_release
cd doc-qa
quiet "git $FILE_OK submodule update --remote"
commit_all 'Update textsplit to 0.2.0'
quiet 'git push origin main'
cd ../ravi-doc-qa
as ravi

snip 01-commit-on-detached
run 'cd vendor/textsplit'
run 'git status --short --branch'
quiet 'lib_add_line_splitter'
run 'git commit -am "Add line splitter"'
run 'git log --oneline --decorate -2'
run 'cd ../..'
snip_end
lost=$(git -C vendor/textsplit rev-parse --short HEAD)

snip 02-update-moves-head
run 'git pull'
run 'git submodule update'
run 'git -C vendor/textsplit log --oneline --decorate -2'
note 'Which branch, local or remote-tracking, contains the commit Ravi made? None:'
run "git -C vendor/textsplit branch --all --contains $lost"

snip 03-rescue
note 'No branch ever pointed at the commit. The submodule has a reflog of its own:'
run 'git -C vendor/textsplit reflog -3'
run "git -C vendor/textsplit branch line-splitter 'HEAD@{1}'"
run 'git -C vendor/textsplit log --oneline --decorate -1 line-splitter'

snip 04-work-on-a-branch
note 'The way to work in a submodule: get on a branch first.'
run 'git -C vendor/textsplit switch line-splitter'
run 'git -C vendor/textsplit status --short --branch'
run 'git status --short'
run 'git submodule status'
as you
lab_end
