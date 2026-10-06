#!/usr/bin/env bash
# Lab 15.1 replay: a submodule that breaks for a teammate. The working path pushes the library
# commit together with the superproject. The failure scenario pushes only the superproject; the
# teammate's pull then fails; diagnosis, fix, and the guard.
#
# Volatile: the failing fetch is reported by two processes (git upload-pack serving the path remote,
# and the client). Their "not our ref" lines can appear in either order.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 lab-15-1-submodule-breaks --volatile
fx_docqa_submodule
fx_ravi_clone
cd doc-qa

snip 01-start
run 'cat .gitmodules'
run 'git ls-tree HEAD vendor/'
run 'git submodule status'
run 'git -C vendor/textsplit status --short --branch'

snip 02-library-change
run 'cd vendor/textsplit'
run 'git switch main'
note 'Edit splitter.py: add the function split_lines. Then:'
quiet 'lib_add_line_splitter'
run 'git commit -am "Add line splitter"'
run 'cd ../..'

snip 03-pointer
run 'git status --short'
run 'git diff --submodule=log'
run 'git commit -am "Use the line splitter from textsplit"'

snip 04-push-both
run 'git push --recurse-submodules=on-demand origin main'

snip 05-teammate-ok
run 'cd ../ravi-doc-qa'
as ravi
run 'git pull'
run 'git submodule update'
run 'git submodule status'
as you

snip 06-failure
run 'cd ../doc-qa'
note 'A second library change. Edit vendor/textsplit/splitter.py: add split_paragraphs. Then:'
quiet '(cd vendor/textsplit && lib_add_paragraph_splitter)'
run 'git -C vendor/textsplit commit -am "Add paragraph splitter"'
run 'git commit -am "Use the paragraph splitter from textsplit"'
note 'The mistake: only the superproject is pushed.'
run 'git push origin main'

snip 07-teammate-broken
run 'cd ../ravi-doc-qa'
as ravi
run_rc 'git pull'
run 'git status --short --branch'

snip 08-diagnose
run 'git ls-tree origin/main vendor/'
run 'git ls-remote --heads ../remotes/textsplit.git'
snip_end
want=$(git rev-parse --short origin/main:vendor/textsplit)
snip 09-diagnose-where
run_rc "git -C vendor/textsplit cat-file -t $want"
run "git -C ../doc-qa/vendor/textsplit branch --all --contains $want"
as you

snip 10-recovery
run 'cd ../doc-qa'
run 'git -C vendor/textsplit push origin main'
run 'cd ../ravi-doc-qa'
as ravi
run 'git pull'
run 'git -c protocol.file.allow=always submodule update'
as you

snip 11-prevention
run 'cd ../doc-qa'
run 'git config set push.recurseSubmodules check'
quiet "printf '\n# next: sentence splitter\n' >> vendor/textsplit/splitter.py"
run 'git -C vendor/textsplit commit -am "Note the next splitter"'
run 'git commit -am "Record the newest textsplit"'
run_rc 'git push origin main'

snip 12-verification
run 'git push --recurse-submodules=on-demand origin main'
run 'cd ../ravi-doc-qa'
as ravi
run 'git pull'
run 'git submodule update'
run 'git submodule status'
run 'git status --short --branch'
as you
lab_end
