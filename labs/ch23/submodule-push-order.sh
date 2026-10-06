#!/usr/bin/env bash
# The classic failure: the superproject is pushed with a gitlink to a library commit that exists
# only on your machine. What the teammate sees, how to diagnose it, the fix, and the guard
# (push --recurse-submodules=check / on-demand). Chapter 23, section 23.8.
#
# Volatile: when the fetch of the missing commit fails, two processes report it (git upload-pack,
# which serves the path remote on this machine, and the fetching client). Their two "not our ref"
# lines can appear in either order, so labs/verify-all.sh only checks that this demo runs.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-push-order --volatile
fx_docqa_submodule
fx_ravi_clone
cd doc-qa

snip 01-local-library-commit
run 'cd vendor/textsplit'
run 'git switch main'
quiet 'lib_add_line_splitter'
run 'git commit -am "Add line splitter"'
run 'cd ../..'
run 'git status --short'
run 'git commit -am "Use the line splitter from textsplit"'

snip 02-guard
run_rc 'git push --recurse-submodules=check origin main'

snip 03-mistake
note 'Without the guard, the push of the superproject succeeds:'
run 'git push origin main'

snip 04-teammate
run 'cd ../ravi-doc-qa'
as ravi
run_rc 'git pull'

snip 05-diagnose
run 'git status --short --branch'
run 'git ls-tree origin/main vendor/'
run 'git ls-remote ../remotes/textsplit.git'
snip_end
want=$(git rev-parse --short origin/main:vendor/textsplit)
snip 05b-not-here
run_rc "git -C vendor/textsplit cat-file -t $want"
run "git -C ../doc-qa/vendor/textsplit branch --all --contains $want"
as you

snip 06-fix
run 'cd ../doc-qa'
run 'git -C vendor/textsplit push origin main'
run 'cd ../ravi-doc-qa'
as ravi
run 'git pull'
run 'git -c protocol.file.allow=always submodule update'
run 'git submodule status'
as you

snip 07-on-demand
run 'cd ../doc-qa'
quiet "printf '\n\ndef split_sentences(text):\n    return [s.strip() for s in text.split(\".\") if s.strip()]\n' >> vendor/textsplit/splitter.py"
run 'git -C vendor/textsplit commit -am "Add sentence splitter"'
run 'git commit -am "Use the sentence splitter from textsplit"'
run 'git push --recurse-submodules=on-demand origin main'

snip 08-config
run 'git config set push.recurseSubmodules check'
run 'git config get push.recurseSubmodules'
lab_end
