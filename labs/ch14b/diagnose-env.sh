#!/usr/bin/env bash
# Chapter 14B, section 14B.7: GIT_* environment variables for diagnosis. GIT_TRACE and
# GIT_TRACE_SETUP on local commands, and GIT_SSH_COMMAND with a stand-in for ssh so that
# no connection is attempted. Trace lines begin with a wall-clock time and a source
# position; the commands cut that prefix off so that the transcript is reproducible.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b diagnose-env
sandbox_home
make_gateway "$HOME/work/inference-gateway"
hidden "git config set --global alias.st 'status -sb'"
# A stand-in for ssh: prints its arguments on standard error and fails. Nothing connects.
mkdir -p "$HOME/lab-bin"
printf '#!/bin/sh\necho "ssh was asked to run:" "$@" >&2\nexit 255\n' > "$HOME/lab-bin/ssh"
chmod +x "$HOME/lab-bin/ssh"

snip 01-trace
run "GIT_TRACE=1 git st 2>&1 | grep -E -o '(trace: (exec|alias expansion|built-in)|##).*'"

snip 02-trace-setup
run 'cd gateway'
run "GIT_TRACE_SETUP=1 git st 2>&1 | grep -o 'setup: .*' | grep -v chdir"
run 'cd ..'

snip 03-trace-to-file
run 'GIT_TRACE=$HOME/git-trace.log git st'
run "sed -e 's/^[^ ]* [^ ]* *//' ~/git-trace.log | grep -E 'alias|built-in'"

snip 04-ssh-command
note '~/lab-bin/ssh is a stand-in that prints its arguments and exits. No connection is made.'
run 'git remote add origin git@git.corp.example:platform/inference-gateway.git'
run_rc "GIT_SSH_COMMAND='~/lab-bin/ssh -i ~/.ssh/id_ed25519_work -o IdentitiesOnly=yes' git fetch origin"

snip 05-ssh-config
run "git config set core.sshCommand '~/lab-bin/ssh -i ~/.ssh/id_ed25519_work'"
run_rc 'git ls-remote origin'
run_rc "GIT_SSH_COMMAND='~/lab-bin/ssh -v' git ls-remote origin"

lab_end
