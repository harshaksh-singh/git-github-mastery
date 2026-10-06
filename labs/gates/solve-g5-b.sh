#!/usr/bin/env bash
# Gate 5, hands-on variant B (shardlog): the model diagnosis and repair as real transcripts
# for answer-keys/gate-5-internals.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g5-b
gate_load gate-5-internals/variant-b
as config

snip 01-observe
run 'cd asha'
run_rc 'git log --oneline -1'
run 'cat .git/HEAD'
run 'wc -c < .git/refs/heads/main | tr -d " "'
run 'grep -c refs/heads/main .git/packed-refs'
run "tail -2 .git/logs/refs/heads/main | cut -d' ' -f1,2 | cut -c1-90"
run "tail -2 .git/logs/refs/heads/main | cut -f2"

snip 02-ref
id=$(tail -1 .git/logs/refs/heads/main | cut -d' ' -f2)
run "git cat-file -t ${id:0:7}"
run_rc "git update-ref refs/heads/main ${id:0:7}"
note 'A broken ref cannot be locked for an update. Remove the empty file, then write the ref.'
run 'rm .git/refs/heads/main'
run "git update-ref -m 'repair: empty ref file' refs/heads/main $id"
run 'git log --oneline -2'

snip 03-index
run_rc 'git status -sb'
run 'wc -c < .git/index | tr -d " "'
note 'The index is rebuilt from HEAD. The working tree is not touched by a mixed reset.'
run 'rm .git/index'
run 'git reset'
run 'git status -sb'
run 'git diff --stat'

snip 04-partial
run 'git config get --all --show-origin remote.origin.url'
run 'git config get remote.origin.promisor'
run 'git config get remote.origin.partialclonefilter'
run "git rev-list --objects --missing=print v1.0.0 | grep -c '^?'"
run_rc 'git show v1.0.0:shardlog/schema.py'

snip 05-remote
run 'git remote set-url origin ../server.git'
run 'git ls-remote origin'
run 'git show v1.0.0:shardlog/schema.py'
run "git rev-list --objects --missing=print v1.0.0 | grep -c '^?'"
run 'GIT_NO_LAZY_FETCH=1 git show v1.0.0:shardlog/schema.py'

snip 06-verify
run 'git fetch'
run 'git status -sb'
run_rc 'git fsck --no-dangling'
run 'cd ..'
show_check
gate_done
