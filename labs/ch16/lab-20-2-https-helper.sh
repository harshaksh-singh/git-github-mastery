#!/usr/bin/env bash
# Lab 20.2 replay, Part A (local rehearsal): the credential helper protocol with a toy helper.
# Configure it, watch get, store and erase, find out with GIT_TRACE which helper answered.
# Failure scenario: two helpers, and the first one answers for the wrong account.
# Lab manual: lab-manual/m20-authentication-ssh.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 lab-20-2-https-helper
scenario_20_2

snip 01-enter
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" PATH="$HOME/lab-bin:$PATH"'
run 'export GIT_TERMINAL_PROMPT=0'
run 'cd ~/work/billing-api'
run 'git remote -v'

snip 02-no-helper
run_rc 'git config get --show-origin --all credential.helper'
run_rc "printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill"

snip 03-configure
run 'git config set --global credential.helper labstore'
run_rc "printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill"
run 'cat ~/helper.log'

snip 04-approve-fill
run "printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=$FAKE_TOKEN\n\n' | git credential approve"
run "printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill"

snip 05-trace
run "printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o 'trace: run_command.*'"

snip 06-checkpoint
run 'cat ~/helper.log'

snip 07-failure
note 'A second helper holds the work account. It is configured after the first one.'
run "printf 'username=work-user\npassword=$FAKE_TOKEN\n' > ~/.workstore-credentials"
run 'git config set --global --append credential.helper workstore'
run "printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill"
run "printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o \"trace: run_command: '.*\""

snip 08-recovery
run "git config set --global --append credential.https://github.com.helper ''"
run 'git config set --global --append credential.https://github.com.helper workstore'
run "printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill"
run "printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o \"trace: run_command: '.*\""

snip 09-verification
run 'git config get --show-scope --all credential.helper'
run 'git config get --show-scope --all credential.https://github.com.helper'
run "printf 'protocol=https\nhost=github.com\nusername=work-user\npassword=$FAKE_TOKEN\n\n' | git credential reject"
run_rc 'cat ~/.workstore-credentials'
run 'cat ~/.labstore-credentials'

lab_end
