#!/usr/bin/env bash
# Chapter 16, section 16.4: which helper answers, and for which URL. The helper list and its
# reset by an empty value, a helper scoped to one host, a fixed username per host, and
# credential.useHttpPath. Two toy helpers play "the machine-wide helper" and "the GitHub one".
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 credential-scope
sandbox_home
make_helper labstore
make_helper workstore
printf 'username=personal-user\npassword=%s\n' "$FAKE_TOKEN" > "$HOME/.labstore-credentials"
printf 'username=work-user\npassword=%s\n' "$FAKE_TOKEN" > "$HOME/.workstore-credentials"

snip 01-list
run 'git config set --global credential.helper labstore'
run 'git config set --global --append credential.helper workstore'
run 'git config get --all credential.helper'
run "printf 'protocol=https\nhost=github.com\n\n' | git credential fill"
run 'cat ~/helper.log'

snip 02-per-host
hidden 'rm ~/helper.log'
note 'An empty value resets the list; what follows it replaces every helper configured before.'
run "git config set --global --append credential.https://github.com.helper ''"
run 'git config set --global --append credential.https://github.com.helper workstore'
run 'cat ~/.gitconfig'
run "printf 'protocol=https\nhost=github.com\n\n' | git credential fill"
run "printf 'protocol=https\nhost=gitlab.example\n\n' | git credential fill"
run 'cat ~/helper.log'

snip 03-one-command
hidden 'rm ~/helper.log'
note 'The same reset for a single command: no stored credential is read, changed or erased.'
run "printf 'protocol=https\nhost=github.com\n\n' | git -c credential.helper= -c credential.https://github.com.helper= -c credential.helper='!f() { test \"\$1\" = get && printf \"username=nobody\\npassword=wrong\\n\"; }; f' credential fill"
run_rc 'cat ~/helper.log'

snip 04-username-and-path
run 'git config set --global credential.https://github.com.username work-user'
run 'git config set --global credential.https://github.com.useHttpPath true'
run "printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill"
run 'cat ~/helper.log'

lab_end
