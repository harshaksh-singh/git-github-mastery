#!/usr/bin/env bash
# Model solution of exercise 17.9 (Level 4): three damaged files in .git (HEAD, a stale
# index.lock, a truncated config). Objects, refs and reflogs are intact, so nothing is lost.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m17-ingestd
ex_load m17-ingestd
cd you || exit 1

snip 01-symptom
run_rc 'git status'

snip 01-first-look
run 'ls -A .git | sort'
run 'wc -c < .git/HEAD'

snip 02-head
run "tail -3 .git/logs/HEAD | cut -f2"
run 'find .git/refs/heads -type f | sort'
run "printf 'ref: refs/heads/feature/batching\n' > .git/HEAD"
run 'git status -sb'
run 'git log --oneline -3'

snip 03-lock
run_rc 'git reset'
run 'wc -c < .git/index.lock'
note 'No git process is running (ps shows none), so the lock is stale.'
run 'rm .git/index.lock'
run 'git reset'

snip 04-config
run 'git branch -vv'
run 'cat .git/config'
run_rc 'git fetch'

snip 05-rebuild-config
run 'git remote set-url origin ../server.git'
run "git config set remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'"
run 'git fetch'
run 'git branch -r'
run 'git branch -u origin/main main'
run 'git branch -u origin/feature/batching feature/batching'

snip 06-verify
run 'git branch -vv'
run 'git status -sb'
run 'git config list --local | sed -n "/^remote/,\$p"'
run_rc 'git fsck'
run 'cd ..'
show_check
ex_done
