#!/usr/bin/env bash
# Two diagnoses from first principles: "the commit exists locally but not on the server",
# and a clone whose remote-tracking refs can no longer be trusted. Chapter 12, section 12.14.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 diagnose

# Hidden setup: you made a hotfix commit on a new local branch and then "pushed"
# with a command that names a different branch.
make_server
new_clone you
enter you
hidden 'git switch -c hotfix/timeout'
commit_file app/settings.py 'TIMEOUT_SECONDS = 30\n' 'Set request timeout'

snip 01-the-push-that-pushed-nothing
run 'git log --oneline -1'
run 'git push origin main'

snip 02-where-is-the-commit
run 'git branch -a --contains HEAD'
run 'git status -sb'
run 'git log --oneline --branches --not --remotes'

snip 03-ask-the-server
run 'git rev-parse HEAD'
run 'git ls-remote origin'

snip 04-fix
run 'git push -u origin hotfix/timeout'
run 'git branch -a --contains HEAD'
run 'git log --oneline --branches --not --remotes'

snip 05-ambiguous-name
run 'git switch main'
run 'git branch origin/main HEAD~1'
run 'git rev-parse --short origin/main'
run 'git branch -a'
run 'git branch -D origin/main'

snip 06-rebuild-remote-tracking
run 'git remote set-head origin --delete'
run "git for-each-ref --format='delete %(refname)' refs/remotes/origin | git update-ref --stdin"
run 'git branch -r'
run 'git status -sb'
run 'git fetch'
run 'git status -sb'

lab_end
