#!/usr/bin/env bash
# Adding a submodule: the refusal of the file transport, then the three things "git submodule add"
# creates (a gitlink in the index, .gitmodules, a repository under .git/modules).
# Chapter 23, sections 23.2 to 23.4.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-add
fx_textsplit
fx_docqa
cd doc-qa

snip 01-blocked
run 'git remote -v'
run_rc 'git submodule add ../textsplit.git vendor/textsplit'

snip 02-add
run 'git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit'
run 'git status'

snip 03-gitmodules
run 'cat .gitmodules'
run 'git config list --local | grep ^submodule'

snip 04-gitlink
run 'git ls-files --stage'
run 'git -C vendor/textsplit log --oneline --decorate -1'

snip 05-modules-dir
run 'cat vendor/textsplit/.git'
run 'ls .git/modules/vendor/textsplit'
run 'git -C vendor/textsplit rev-parse --git-dir'
run 'git -C vendor/textsplit config get core.worktree'

snip 06-diff
run 'git diff --cached -- vendor/textsplit'

snip 07-commit
run 'git commit -m "Vendor textsplit as a submodule"'
run 'git ls-tree HEAD'
run 'git ls-tree HEAD vendor/'
run 'git submodule status'

snip 08-not-our-object
note 'The tree entry names a commit, but the commit object is not in this repository:'
run_rc 'git cat-file -t HEAD:vendor/textsplit'
note 'It lives in the object database of the submodule:'
run 'git -C vendor/textsplit cat-file -t HEAD'
run 'git -C vendor/textsplit rev-parse HEAD'
lab_end
