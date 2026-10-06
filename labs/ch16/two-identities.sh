#!/usr/bin/env bash
# Chapter 16, section 16.11: two GitHub identities on one machine. The directory a repository
# lives in selects, through includeIf, the commit identity and a URL rewrite; the rewrite
# selects an ssh host alias; the alias selects the key. Nothing connects: "ssh -G" prints the
# configuration ssh would use, and a stand-in prints what Git would run.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch16 two-identities
sandbox_home
write_ssh_config
make_ssh_standin
make_repo "$HOME/personal/notes-app" git@github.com:lab-user/notes-app.git
make_repo "$HOME/work/billing-api" git@github.com:acme-pay/billing-api.git
cd "$HOME" || exit 1
as config

snip 01-global
run 'git config set --global user.name "Lab User"'
run 'git config set --global user.email lab-user@personal.example'
run "git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'"
run "printf '[user]\n\temail = lab.user@acme-pay.example\n[url \"git@github-work:\"]\n\tinsteadOf = git@github.com:\n' > ~/.gitconfig-work"
run 'cat ~/.gitconfig-work'

snip 02-personal
run 'cd ~/personal/notes-app'
run 'git config get user.email'
run 'git config get remote.origin.url'
run 'git remote get-url origin'
run 'GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1'

snip 03-work
run 'cd ~/work/billing-api'
run 'git config get --show-origin user.email'
run 'git config get remote.origin.url'
run 'git remote get-url origin'
run 'GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1'

snip 04-ssh-side
run "ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|identityfile|identitiesonly) '"
run "ssh -T -F ~/.ssh/config -G github-work | grep -E '^(hostname|user|identityfile|identitiesonly) '"

snip 05-commit-identity
run "printf 'Runbook: rotate the payment gateway key every 90 days.\n' > RUNBOOK.md"
run 'git add RUNBOOK.md && git commit -q -m "Add key rotation runbook"'
run "git log -1 --format='%an <%ae>  %s'"
run 'cd ~/personal/notes-app'
run "printf 'Ideas for the weekend.\n' > IDEAS.md"
run 'git add IDEAS.md && git commit -q -m "Add ideas file"'
run "git log -1 --format='%an <%ae>  %s'"

lab_end
