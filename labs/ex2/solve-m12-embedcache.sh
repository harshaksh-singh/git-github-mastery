#!/usr/bin/env bash
# Model solution of exercise 12.10 (Level 4): commits made inside an aborted rebase, found in the
# HEAD reflog, anchored, and the rebase finished by hand.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m12-embedcache
ex_load m12-embedcache
cd asha || exit 1

snip 01-observe
run 'git status -sb'
run 'git stash list'
run 'git log --oneline main..HEAD'
run 'git reflog show feature/lru-cache'

snip 02-head-reflog
run 'git reflog -6'

snip 03-anchor
run "git branch rescue 'HEAD@{1}'"
run 'git log --oneline main..rescue'
run 'git show --stat --format="%h %s" rescue'
run 'git show rescue:embedcache/key.py'

snip 04-replay
run_rc 'git rebase --onto rescue feature/lru-cache~2 feature/lru-cache'
run 'git status -sb'
run 'git diff'

snip 05-resolve
put() { mkdir -p "$(dirname "$1")" && cat > "$1"; }
put embedcache/key.py <<'F'
from embedcache.digest import digest

KEY_VERSION = "v2"


def key(model, text):
    return KEY_VERSION + ":" + model.lower() + ":" + digest(text)
F
note 'edit embedcache/key.py: keep the version prefix and the lower-cased model name'
run 'cat embedcache/key.py'
run 'git add embedcache/key.py'
run 'git rebase --continue'

snip 06-verify
run 'git log --graph --oneline --all'
run 'python3 -B -m unittest tests/test_key.py 2>&1 | tail -1'
run "git range-diff 'feature/lru-cache@{1}~2..feature/lru-cache@{1}' rescue..HEAD"
run 'git branch -D rescue'
run 'git status -sb'
run 'cd ..'
show_check
ex_done
