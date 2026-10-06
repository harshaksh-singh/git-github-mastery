#!/usr/bin/env bash
# A --bare clone is a snapshot, a --mirror clone can follow its source: what "git fetch"
# does in each after the source repository has moved. Chapter 12, section 12.3.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 mirror-refresh

# Hidden setup: two copies of the server are made, one with --bare and one with --mirror.
# Afterwards Asha publishes a commit on main and a new branch release/1.0.
make_server
new_clone asha
cd "$LAB_DIR" || exit 1
hidden "git clone --bare server/support-bot.git backup/copy.git"
hidden "git clone --mirror server/support-bot.git backup/mirror.git"
git -C backup/copy.git remote set-url origin ../../server/support-bot.git || exit 1
git -C backup/mirror.git remote set-url origin ../../server/support-bot.git || exit 1
enter asha
commit_file config.yaml 'model: small-v1\ntop_k: 8\n' 'Raise top_k to 8'
hidden 'git push'
hidden 'git push origin main:refs/heads/release/1.0'
cd "$LAB_DIR/backup" || exit 1
as you

snip 01-bare-does-not-follow
note 'The server has moved: one new commit on main and a new branch release/1.0.'
run 'git ls-remote --branches ../server/support-bot.git'
run 'git -C copy.git fetch'
run 'git -C copy.git show-ref --abbrev'
run 'git -C copy.git config get --all remote.origin.fetch || echo "(no fetch refspec configured)"'

snip 02-mirror-follows
run 'git -C mirror.git fetch'
run 'git -C mirror.git show-ref --abbrev'

# Asha deletes the release branch on the server again.
enter asha
hidden 'git push origin --delete release/1.0'
cd "$LAB_DIR/backup" || exit 1
as you

snip 03-mirror-prunes
note 'release/1.0 has been deleted on the server.'
run 'git -C mirror.git remote update --prune'
run 'git -C mirror.git show-ref --abbrev'

lab_end
