#!/usr/bin/env bash
# Moving the pointer: update --remote, what status and diff say, committing the new gitlink, and what
# a teammate sees after pulling (a stale submodule that looks like their own change, and how a
# "commit -a" then silently moves the pointer back). Chapter 23, sections 23.6 and 23.7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-update
fx_docqa_submodule
fx_ravi_clone
fx_textsplit_release
cd doc-qa

snip 01-remote
run 'git submodule status'
run 'git -c protocol.file.allow=always submodule update --remote'
run 'git submodule status'

snip 02-status-diff
run 'git status'
run 'git diff'
run 'git diff --submodule=log'

snip 03-commit-pointer
run 'git add vendor/textsplit'
run 'git commit -m "Update textsplit to 0.2.0"'
run 'git push origin main'

snip 04-teammate-pull
run 'cd ../ravi-doc-qa'
as ravi
run 'git pull'
run 'git status'

snip 05-teammate-stale
run 'git submodule status'
run 'git diff --submodule=log'

snip 06-accidental-rollback
note 'Ravi does not look closely. He edits a file and commits everything that is modified:'
quiet "sed -i.bak 's/size=400/size=600/' ingest.py && rm ingest.py.bak"
run 'git commit -am "Use larger chunks"'
run 'git show --stat --format="%h %an: %s"'
run 'git ls-tree HEAD vendor/'

snip 07-repair
note 'Not pushed yet, so repair the commit: put the submodule on the commit that main records'
note 'upstream, stage it, amend.'
run 'git -C vendor/textsplit checkout --quiet $(git rev-parse origin/main:vendor/textsplit)'
run 'git add vendor/textsplit'
run 'git commit --amend --no-edit'
run 'git show --stat --format="%h %an: %s"'
run 'git submodule status'
as you
lab_end
