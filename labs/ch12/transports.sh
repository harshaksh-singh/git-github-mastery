#!/usr/bin/env bash
# How Git reads a remote URL, and a transport that needs no connection at all: a bundle
# file. Chapter 12, section 12.13.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 transports

# Hidden setup: the server and your clone, with one local commit on a branch.
make_server
new_clone you
enter you
hidden 'git switch -c feature/eval-harness'
commit_file eval/run_eval.py 'print("eval")\n' 'Add eval harness entry point'
hidden 'git switch main'

snip 01-url-forms
note 'One scheme per URL, in the order given:'
run 'git url-parse -c scheme https://github.com/acme/support-bot.git git@github.com:acme/support-bot.git ssh://git@github.com/acme/support-bot.git file:///srv/git/support-bot.git'
run 'git url-parse -c host git@github.com:acme/support-bot.git'
run 'git url-parse -c path git@github.com:acme/support-bot.git'
run_rc 'git url-parse -c scheme ../../server/support-bot.git'

snip 02-bundle-create
run 'git bundle create ../../support-bot.bundle HEAD --branches'
run 'git bundle verify ../../support-bot.bundle'

snip 03-bundle-clone
run 'cd ../..'
run 'git clone support-bot.bundle airgap/support-bot'
run 'git -C airgap/support-bot branch -a'
run 'git -C airgap/support-bot remote -v'

lab_end
