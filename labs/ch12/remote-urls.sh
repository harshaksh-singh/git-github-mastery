#!/usr/bin/env bash
# Fetch URL versus push URL, several push URLs, URL rewriting with insteadOf,
# remote groups, and what rename and remove do. Chapter 12, section 12.10.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 remote-urls

# Hidden setup: your clone has origin (the server) and a second bare repository to use as a backup.
make_server
new_clone you
hidden "git clone --bare '$LAB_DIR/server/support-bot.git' '$LAB_DIR/backup/support-bot.git'"
enter you
commit_file app/settings.py 'TIMEOUT_SECONDS = 30\n' 'Set request timeout'

snip 01-push-url
run 'git remote add upstream ../../server/support-bot.git'
run 'git remote set-url --push upstream DISABLED'
run 'git remote -v'
run 'git config get --all --show-names --regexp "^remote\.upstream\."'
run_rc 'git push upstream main'

snip 02-two-push-urls
run 'git remote set-url --add --push origin ../../server/support-bot.git'
run 'git remote set-url --add --push origin ../../backup/support-bot.git'
run 'git remote -v'
run 'git push origin main'

snip 03-instead-of
run 'git config set url.../../server/.insteadOf https://git.example.com/acme/'
run 'git remote add company https://git.example.com/acme/support-bot.git'
run 'git config get remote.company.url'
run 'git remote get-url company'
run 'git ls-remote company main'

snip 04-remote-group
run 'git remote add backup ../../backup/support-bot.git'
run 'git config set remotes.offsite "company backup"'
run 'git fetch offsite'
run 'git push --dry-run offsite main'

snip 05-rename
run 'git branch -u company/main'
run 'git remote rename company canonical'
run 'git branch -r'
run 'git config get --all --show-names --regexp "^(remote\.canonical|branch\.main)\."'

snip 06-remove
run 'git remote remove canonical'
run 'git branch -r'
run 'git branch -vv'
run_rc 'git remote remove canonical'

lab_end
