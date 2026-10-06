#!/usr/bin/env bash
# Chapter 16, section 16.6: why a token never goes into a remote URL. The URL is stored in
# plain text, printed by everyday commands, and read by Git as a credential. Then the
# setting that makes Git refuse such URLs. The token is fake and nothing is contacted.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 token-in-url
sandbox_home
make_repo "$HOME/work/billing-api" https://github.com/acme-pay/billing-api.git

snip 01-stored
note 'What an old tutorial tells you to do. The token here is fake.'
run "git remote set-url origin https://lab-user:$FAKE_TOKEN@github.com/acme-pay/billing-api.git"
run 'git remote -v'
run 'grep url .git/config'
run 'git config list --show-scope | grep url'

snip 02-git-reads-it
run "printf 'url=%s\n\n' \"\$(git remote get-url origin)\" | git credential fill"

snip 03-refuse
run 'git config set --global transfer.credentialsInUrl die'
run_rc 'git fetch origin'
run_rc 'git push origin main'

snip 04-repair
note 'With "die" in force, even the command that would repair the URL refuses to read it:'
run_rc 'git remote set-url origin https://github.com/acme-pay/billing-api.git'
run 'git config set remote.origin.url https://github.com/acme-pay/billing-api.git'
run 'git remote -v'
note 'The URL is clean. The token is still compromised: it sat in a file and on a screen. Revoke it.'

lab_end
