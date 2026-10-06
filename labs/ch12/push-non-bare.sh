#!/usr/bin/env bash
# Pushing into a repository that has a working tree: why Git refuses to update the
# checked-out branch, and what receive.denyCurrentBranch=updateInstead does.
# Chapter 12, section 12.9.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 push-non-bare

# Hidden setup: a "staging box" that is an ordinary clone with main checked out.
make_server
new_clone you
hidden "git clone '$LAB_DIR/server/support-bot.git' '$LAB_DIR/staging-box'"
enter you
commit_file app/settings.py 'TIMEOUT_SECONDS = 30\n' 'Set request timeout'

snip 01-refused
run 'git remote add staging ../../staging-box'
run_rc 'git push staging main'

snip 02-other-branch
run 'git push staging main:refs/heads/incoming/timeout'
run 'git -C ../../staging-box branch -vv'

snip 03-update-instead
run 'git -C ../../staging-box config set receive.denyCurrentBranch updateInstead'
run 'git push staging main'
run 'git -C ../../staging-box log --oneline -1'
run 'ls ../../staging-box/app'

snip 04-dirty-target
commit_file app/settings.py 'TIMEOUT_SECONDS = 45\n' 'Raise request timeout'
run "printf 'hotfix typed directly on the box\n' >> ../../staging-box/README.md"
run_rc 'git push staging main'

lab_end
