#!/usr/bin/env bash
# What a teammate gets: a plain clone leaves the submodule directory empty; init and update fill
# it and leave HEAD detached; clone --recurse-submodules does all of it. Also the mechanism behind
# "transport 'file' not allowed". Chapter 23, sections 23.4 and 23.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-clone
fx_docqa_submodule

snip 01-plain-clone
run 'git clone remotes/doc-qa.git ravi-doc-qa'
run 'cd ravi-doc-qa'
run 'ls -A vendor/textsplit'
run 'git status'
run 'git submodule status'

snip 02-init
run_rc 'git config get submodule.vendor/textsplit.url'
run 'git submodule init'
run 'git config list --local | grep ^submodule'

snip 03-update
run 'git -c protocol.file.allow=always submodule update'
run 'ls -A vendor/textsplit'
run 'git submodule status'

snip 04-detached
run 'git -C vendor/textsplit status'
run 'git -C vendor/textsplit branch --all'

snip 05-recursive-refused
run 'cd ..'
run_rc 'git clone --recurse-submodules remotes/doc-qa.git asha-doc-qa'

snip 06-policy
note 'The clone of the superproject worked; only the clone that Git started by itself was refused.'
run 'git -C asha-doc-qa submodule status'
note 'The default policy for the file transport is "user". This variable is how Git marks'
note 'a transfer that the user did not type:'
run_rc 'GIT_PROTOCOL_FROM_USER=0 git clone remotes/textsplit.git probe'
quiet 'rm -rf asha-doc-qa probe'

snip 07-recursive
run 'git -c protocol.file.allow=always clone --recurse-submodules remotes/doc-qa.git asha-doc-qa'
run 'git -C asha-doc-qa submodule status'
lab_end
