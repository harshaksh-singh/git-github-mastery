#!/usr/bin/env bash
# The fast-forward rule of git push and its two rejection messages, "fetch first" and
# "non-fast-forward"; then integrate and push. Chapter 12, section 12.7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 push-rejections

# Hidden setup: Asha has published a commit that you have not fetched; you have one local commit.
make_server
new_clone you
new_clone asha
enter asha
commit_file config.yaml 'model: small-v1\ntop_k: 8\n' 'Raise top_k to 8'
hidden 'git push'
enter you
commit_file requirements-dev.txt 'pytest\n' 'Add dev requirements'

snip 01-fetch-first
run 'git status -sb'
run_rc 'git push'
run 'git status -sb'

snip 02-non-fast-forward
run 'git fetch'
run 'git status -sb'
run_rc 'git push'

snip 03-wire
note 'The client side of the conversation during the rejected push:'
run "GIT_TRACE_PACKET=1 git push 2>&1 | sed -n 's/.*packet: *\\(push[<>]\\)/\\1/p' | fold -s -w 76"

snip 04-integrate-and-push
run 'git rebase origin/main'
run 'git push --dry-run'
run 'git push'
run 'git status -sb'
run 'git reflog show origin/main'

lab_end
