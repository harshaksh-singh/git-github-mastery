#!/usr/bin/env bash
# What travels between the two repositories during a fetch and a push: the client half
# of the conversation, taken from GIT_TRACE_PACKET. Chapter 12, section 12.13.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 transport-trace

# Hidden setup: Asha has published one commit that you have not fetched.
make_server
new_clone you
new_clone asha
enter asha
commit_file config.yaml 'model: small-v1\ntop_k: 8\n' 'Raise top_k to 8'
hidden 'git push'
enter you

snip 01-fetch
run "GIT_TRACE_PACKET=1 git fetch 2>&1 | sed -n 's/.*packet: *\\(fetch[<>]\\)/\\1/p'"

snip 02-push
commit_file requirements-dev.txt 'pytest\n' 'Add dev requirements'
hidden 'git rebase origin/main'
note 'One local commit, already rebased onto the fetched origin/main:'
run "GIT_TRACE_PACKET=1 git push 2>&1 | sed -n 's/.*packet: *\\(push[<>]\\)/\\1/p' | cut -c1-110"

snip 03-programs
note 'Which program does Git start for the other side of the conversation?'
run "GIT_TRACE=1 git fetch 2>&1 | sed -n 's/.*trace: run_command: //p' | head -1"
run "GIT_TRACE=1 git push 2>&1 | sed -n 's/.*trace: run_command: //p' | head -1"

lab_end
