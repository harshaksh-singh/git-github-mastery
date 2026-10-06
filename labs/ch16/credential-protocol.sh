#!/usr/bin/env bash
# Chapter 16, section 16.3: how Git asks for a credential. No helper and no terminal; a
# stand-in for the person at the keyboard (GIT_ASKPASS); then a toy helper that shows the
# three operations get, store and erase. "git credential fill|approve|reject" is the
# documented front door to the same code that fetch and push use, so no server is needed.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 credential-protocol
sandbox_home
make_helper labstore
make_askpass

snip 01-no-helper
run_rc 'git config get --show-origin --all credential.helper'
run_rc "printf 'protocol=https\nhost=github.com\n\n' | git credential fill"

snip 02-askpass
note '~/lab-bin/askpass stands in for you at the keyboard: it prints the prompt and answers.'
run "printf 'protocol=https\nhost=github.com\n\n' | GIT_ASKPASS=~/lab-bin/askpass git credential fill"

snip 03-helper-source
run 'cat ~/lab-bin/git-credential-labstore'

snip 04-configure
run 'git config set --global credential.helper labstore'
run 'git config get --show-scope --all credential.helper'
run_rc "printf 'protocol=https\nhost=github.com\n\n' | git credential fill"
run 'cat ~/helper.log'

snip 05-approve
note 'What Git does after a server accepted a credential that you typed:'
run "printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=$FAKE_TOKEN\n\n' | git credential approve"
run 'cat ~/.labstore-credentials'

snip 06-fill
run "printf 'protocol=https\nhost=github.com\n\n' | git credential fill"
run "printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill"

snip 07-trace
run "printf 'protocol=https\nhost=github.com\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o 'trace: run_command.*'"

snip 08-reject
note 'What Git does after a server answered 401 to a credential it had sent:'
run "printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=$FAKE_TOKEN\n\n' | git credential reject"
run_rc 'cat ~/.labstore-credentials'
run_rc "printf 'protocol=https\nhost=github.com\n\n' | git credential fill"

snip 09-log
run 'cat ~/helper.log'

lab_end
