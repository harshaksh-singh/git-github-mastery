#!/usr/bin/env bash
# refs/remotes/origin/HEAD: a local symbolic ref that remembers the server's default
# branch as of clone time, and how it goes stale. Chapter 12, section 12.3.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 origin-head

make_server
new_clone you
new_clone asha
enter you

snip 01-symref
run 'cat .git/refs/remotes/origin/HEAD'
run 'git rev-parse --abbrev-ref origin/HEAD'
run 'git log --oneline -1 origin'

# The team renames the default branch on the server from main to trunk.
enter asha
hidden 'git push origin main:refs/heads/trunk'
hidden "git -C '$LAB_DIR/server/support-bot.git' symbolic-ref HEAD refs/heads/trunk"
enter you

snip 02-stale
note 'The server default branch is now trunk (its HEAD was repointed).'
run 'git ls-remote --symref origin HEAD'
run 'git fetch'
run 'git rev-parse --abbrev-ref origin/HEAD'
run 'git remote set-head origin --auto'
run 'git rev-parse --abbrev-ref origin/HEAD'

# Later the old branch main is deleted on the server. Asha has not updated origin/HEAD.
enter you
hidden 'git push origin --delete main'
as asha

snip 03-dangling
run 'cd ../../asha/support-bot'
run 'git fetch --prune'
run_rc 'git rev-parse --verify origin/HEAD'
run 'git remote set-head origin --auto'
run 'git branch -r'

snip 04-created-by-fetch
run 'git remote set-head origin --delete'
run 'git branch -r'
run 'git fetch --dry-run'
run 'git branch -r'

lab_end
