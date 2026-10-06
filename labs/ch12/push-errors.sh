#!/usr/bin/env bash
# Pushes that fail before any ref is compared: a source name that matches nothing,
# a detached HEAD, a remote name that does not exist. Chapter 12, section 12.7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 push-errors

# Hidden setup: your clone, with one local commit on a new branch.
make_server
new_clone you
enter you
hidden 'git switch -c hotfix/timeout'
commit_file app/settings.py 'TIMEOUT_SECONDS = 30\n' 'Set request timeout'

snip 01-src-refspec
run 'git branch'
run_rc 'git push origin master'
run_rc 'git push origin hotfix'

snip 02-unborn
note 'A new repository with a remote but no commit yet:'
run 'git init -q ../../scratch'
run 'git -C ../../scratch remote add origin ../server/support-bot.git'
run_rc 'git -C ../../scratch push -u origin main'

snip 03-detached
run 'git switch --detach'
run_rc 'git push'
run 'git push origin HEAD:refs/heads/hotfix/timeout'
run 'git switch -'

snip 04-no-such-remote
run_rc 'git push orign hotfix/timeout'
run 'git remote'

lab_end
