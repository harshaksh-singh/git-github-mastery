#!/usr/bin/env bash
# Lab 15.2 replay: the same dependency as a subtree. Add with --squash, a teammate's plain clone,
# an update; the failure scenario forgets --squash on the pull; recovery; contributing back with split.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 lab-15-2-subtree
fx_docqa_subtree_start
fx_textsplit_release_prepared
cd doc-qa

snip 01-add
run 'git subtree add --prefix=vendor/textsplit ../remotes/textsplit.git main --squash'
run 'git log --graph --format="%h %an: %s"'

snip 02-inspect
run 'git ls-tree HEAD vendor/'
run 'git ls-files vendor'
run 'git log -1 --format=%B HEAD^2'
run 'ls -A'

snip 03-teammate
run 'git push origin main'
run 'git clone ../remotes/doc-qa.git ../ravi-doc-qa'
run 'ls ../ravi-doc-qa/vendor/textsplit'
run 'git -C ../ravi-doc-qa status --short --branch'

snip 04-upstream-release
note 'Play Asha: publish textsplit 0.2.0.'
run 'git -C ../asha-textsplit push origin main --tags'

snip 05-failure
note 'Update the vendored copy, and forget --squash:'
run_rc 'git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main'
run 'git status --short --branch'

snip 06-recovery
run 'git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main --squash'
run 'git log --graph --format="%h %an: %s"'

snip 07-verification
run 'git diff --stat HEAD^1 HEAD'
run 'grep -n "overlap must" vendor/textsplit/splitter.py'
run 'git log -1 --format=%B HEAD^2'

snip 08-contribute-back
note 'Edit vendor/textsplit/splitter.py: add split_paragraphs. Then:'
quiet '(cd vendor/textsplit && lib_add_paragraph_splitter)'
run 'git commit -am "Add paragraph splitter to the vendored textsplit"'
run 'git subtree split --quiet --prefix=vendor/textsplit -b textsplit-export'
run 'git log --graph --format="%h %an: %s" textsplit-export'
run 'git push ../remotes/textsplit.git textsplit-export:refs/heads/docqa/paragraphs'
lab_end
