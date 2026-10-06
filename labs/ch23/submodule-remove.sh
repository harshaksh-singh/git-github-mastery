#!/usr/bin/env bash
# Removing a submodule: deinit (local only), git rm (a commit), what both leave behind in .git, and
# why adding it back under the same name is refused until the leftovers are gone.
# Chapter 23, section 23.11.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-remove
fx_docqa_submodule
cd doc-qa

snip 01-deinit
run 'git submodule deinit vendor/textsplit'
run 'git submodule status'
run 'ls -A vendor/textsplit'
run 'git status --short'
run 'git config list --local | grep ^submodule'
run 'ls .git/modules/vendor'

snip 02-reinit
run 'git -c protocol.file.allow=always submodule update --init'

snip 03-rm
run 'git rm vendor/textsplit'
run 'git status'
run 'git diff --cached'

snip 04-commit
run 'git commit -m "Stop vendoring textsplit"'
run 'ls -A'

snip 05-leftovers
run 'git config list --local | grep ^submodule'
run 'ls .git/modules/vendor'

snip 06-readd-refused
run_rc 'git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit'

snip 07-complete-removal
run 'rm -rf .git/modules/vendor/textsplit'
run 'git config remove-section submodule.vendor/textsplit'
run 'git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit'
run 'git status --short'

snip 08-old-commits
quiet 'git reset --hard'
quiet 'rm -rf vendor .git/modules/vendor && git config remove-section submodule.vendor/textsplit'
note 'History still records the submodule. Checking out an old commit brings back the gitlink'
note 'and .gitmodules, and the directory is empty until you update:'
run 'git switch --detach HEAD~1'
run 'git submodule status'
lab_end
