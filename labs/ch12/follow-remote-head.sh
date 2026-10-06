#!/usr/bin/env bash
# remote.<name>.followRemoteHEAD: let git fetch tell you, or follow, when the default
# branch of the server changes. Chapter 12, section 12.3.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 follow-remote-head

# Hidden setup: after you cloned, the team made trunk the default branch of the server.
make_server
new_clone you
new_clone asha
enter asha
hidden 'git push origin main:refs/heads/trunk'
hidden "git -C '$LAB_DIR/server/support-bot.git' symbolic-ref HEAD refs/heads/trunk"
enter you
hidden 'git fetch'

snip 01-warn
run 'git rev-parse --abbrev-ref origin/HEAD'
run 'git config set remote.origin.followRemoteHEAD warn'
run 'git fetch'
run 'git rev-parse --abbrev-ref origin/HEAD'

snip 02-silence
note 'The value suggested by the hint above, then the value described in the manual:'
run 'git config set remote.origin.followRemoteHEAD warn-if-not-branch-trunk'
run 'git fetch 2>&1 | tail -1'
run 'git config set remote.origin.followRemoteHEAD warn-if-not-trunk'
run 'git fetch'

snip 03-always
run 'git config set remote.origin.followRemoteHEAD always'
run 'git fetch'
run 'git rev-parse --abbrev-ref origin/HEAD'

lab_end
