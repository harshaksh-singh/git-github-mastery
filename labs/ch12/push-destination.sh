#!/usr/bin/env bash
# Where does an argument-less "git push" go? The three settings that choose the remote
# (branch.<name>.pushRemote, remote.pushDefault, branch.<name>.remote) and the one that
# chooses the branch name (push.default), tried one after the other.
# Chapter 12, section 12.10.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 push-destination

# Hidden setup: the shared repository, your fork of it, and your clone with both remotes.
# feature/streaming was created from upstream/main and has one local commit.
make_server
cd "$LAB_DIR" || exit 1
hidden 'git clone --bare server/support-bot.git forks/you/support-bot.git'
hidden 'git clone forks/you/support-bot.git you/support-bot'
cd "$LAB_DIR/you/support-bot" || exit 1
hidden 'git remote set-url origin ../../forks/you/support-bot.git'
hidden 'git remote add upstream ../../server/support-bot.git'
hidden 'git fetch upstream'
hidden 'git switch -c feature/streaming upstream/main'
commit_file app/stream.py 'def stream(answer):\n    yield answer\n' 'Add streaming responses'

snip 01-push-default-remote
run 'git branch -vv'
run 'git config set remote.pushDefault origin'
run 'git push --dry-run'
run_rc 'git rev-parse --abbrev-ref @{push}'

snip 02-current
run 'git config set push.default current'
run 'git push'
run 'git rev-parse --abbrev-ref @{upstream} @{push}'
run "git for-each-ref --format='%(refname:short): pull from %(upstream:short), push to %(push:short)' refs/heads"

snip 03-per-branch
run 'git config set branch.feature/streaming.pushRemote upstream'
run 'git push --dry-run'
run 'git config unset branch.feature/streaming.pushRemote'
run 'git push --dry-run'

lab_end
