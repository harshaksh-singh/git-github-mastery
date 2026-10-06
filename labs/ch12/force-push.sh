#!/usr/bin/env bash
# Force pushing: when --force-with-lease protects a teammate's commit, how a background
# fetch defeats it, what --force-if-includes and an explicit expected value add, and what
# the teammate sees afterwards. Chapter 12, section 12.8.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 force-push

# Hidden setup: you published feature/prompt-cache with two commits. Asha checked the
# branch out and committed a test on top of it, but has not pushed yet.
make_server
new_clone you
enter you
hidden 'git switch -c feature/prompt-cache'
commit_file app/cache.py 'CACHE = {}\n' 'Add prompt cache'
commit_file app/cache.py 'CACHE = {}\nTTL_SECONDS = 300\n' 'wip: ttl'
hidden 'git push -u origin feature/prompt-cache'
new_clone asha
enter asha
hidden 'git switch feature/prompt-cache'
commit_file tests/test_cache.py 'def test_cache_starts_empty():\n    assert True\n' 'Add cache test'
enter you

snip 01-rewrite
run 'git log --oneline --decorate -3'
run 'git branch backup/prompt-cache'
run 'git reset --soft HEAD~2'
run 'git commit -q -m "Add prompt cache with TTL"'
run 'git log --oneline --graph --decorate --all -4'
run 'git status -sb'

# Asha publishes her commit on top of the old history.
as asha
snip 02-lease-holds
note 'Asha, in her clone: git push   (her test commit lands on top of "wip: ttl")'
hidden 'git -C ../../asha/support-bot push'
as you
run_rc 'git push --force-with-lease'
run 'git rev-parse --short origin/feature/prompt-cache'
run 'git ls-remote origin feature/prompt-cache'

snip 03-background-fetch
note 'What an editor or a scheduled job does behind your back:'
run 'git fetch'
run 'git status -sb'

snip 04-guards
run_rc 'git push --force-with-lease --force-if-includes'
run_rc 'git push --force-with-lease=feature/prompt-cache:backup/prompt-cache'

snip 05-lease-defeated
run_rc 'git push --force-with-lease'
run 'git ls-remote origin feature/prompt-cache'

snip 06-what-is-left
run 'git reflog show origin/feature/prompt-cache'
run_rc 'ls ../../server/support-bot.git/logs'
run 'git -C ../../server/support-bot.git fsck --unreachable --no-reflogs | grep commit'

as asha
snip 07-teammate-fetch
run 'cd ../../asha/support-bot'
run 'git status -sb'
run 'git fetch'
run 'git status -sb'
run 'git log --oneline --graph --decorate --all -5'

snip 08-pull-rebase-drops
run 'git reflog show origin/feature/prompt-cache'
run 'git merge-base --fork-point origin/feature/prompt-cache'
run 'git pull --rebase'
run 'git log --oneline --decorate -3'

snip 09-recover
run 'git reflog -4'
run 'git cherry-pick HEAD@{2}'
run 'git push'
run 'git log --oneline --decorate -3'

lab_end
