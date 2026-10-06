#!/usr/bin/env bash
# Gate 1, hands-on variant B (shardmap): the model diagnosis and repair as real transcripts for
# answer-keys/gate-1-fundamentals.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g1-b
gate_load gate-1-fundamentals/variant-b
as config

snip 01-observe
run 'cd shardmap'
run 'git status -sb'
run 'git log --oneline'
run 'git show --stat --format=%s HEAD'

snip 02-ambiguous
run 'git log --oneline main'
run 'git rev-parse main refs/heads/main HEAD'
run 'git for-each-ref'
run 'cat .git/main'
run 'git reflog -3'

snip 03-fix-name
run_rc 'git update-ref -d main'
note 'Deletion accepts only names under refs/ and names in capitals. The stray ref is one file.'
run 'rm .git/main'
run 'git rev-parse main refs/heads/main'
run 'git status -sb'

snip 04-deleted-file
run 'git ls-files -s shardmap'
run 'git ls-tree -r --name-only HEAD~1 shardmap'
run 'git restore --staged --source=HEAD~1 shardmap/hashing.py'
run 'git status -sb'
run 'git commit --amend --no-edit'
run 'git show --stat --format=%s HEAD'
run 'git status -sb'
run 'git diff --stat'

snip 05-mode
run 'git config get --show-scope --show-origin core.fileMode'
run 'git ls-files -s scripts'
run 'git -c core.fileMode=true status -sb'
run 'git -c core.fileMode=true diff scripts'

snip 06-fix-mode
run 'git config unset core.fileMode'
run 'git add scripts/rebalance.sh'
run 'git commit -m "Make the rebalance script executable"'
run 'git ls-tree HEAD scripts/'
run 'git status -sb'
run 'git log --oneline'
run 'cd ..'
show_check
gate_done
