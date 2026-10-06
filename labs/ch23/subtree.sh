#!/usr/bin/env bash
# The same dependency as a subtree: add --squash, what is (and is not) recorded, a teammate's plain
# clone, pull, a local change to the vendored files, split and push. Chapter 23, section 23.13.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 subtree
fx_docqa_subtree_start
cd doc-qa

snip 01-add
run 'git subtree add --prefix=vendor/textsplit ../remotes/textsplit.git main --squash'
run 'git log --graph --format="%h %an: %s"'

snip 02-what-it-is
run 'git ls-tree HEAD vendor/'
run 'git ls-files vendor'
run 'git log -1 --format=%B HEAD^2'
run 'git status --short'
run 'ls -A'

snip 03-teammate
run 'git push origin main'
run 'cd ..'
run 'git clone remotes/doc-qa.git ravi-doc-qa'
run 'ls ravi-doc-qa/vendor/textsplit'
run 'cd doc-qa'
snip_end
fx_textsplit_release
cd doc-qa

snip 04-pull
note 'Asha has published textsplit 0.2.0.'
run 'git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main --squash'
run 'git log --graph --format="%h %an: %s"'

snip 05-pull-message
run 'git log -1 --format=%B HEAD^2'

snip 06-local-change
note 'A change of your own that touches the library and the application in one commit:'
quiet '(cd vendor/textsplit && lib_add_paragraph_splitter)'
quiet "printf '\n\ndef paragraphs(path):\n    return split_paragraphs(load(path))\n' >> ingest.py"
run 'git commit -am "Split documents by paragraph"'
run 'git show --stat --format="%h %s"'

snip 07-split
run 'git subtree split --quiet --prefix=vendor/textsplit -b textsplit-export'
run 'git log --graph --format="%h %an: %s" textsplit-export'
run 'git ls-tree --name-only textsplit-export'
run 'git show --stat --format="%h %s" textsplit-export'

snip 08-push
run 'git subtree push --quiet --prefix=vendor/textsplit ../remotes/textsplit.git docqa/paragraphs'
run 'git ls-remote --heads ../remotes/textsplit.git'
lab_end
