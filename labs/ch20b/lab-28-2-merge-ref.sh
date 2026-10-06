#!/usr/bin/env bash
# Replay of Lab 28.2: the branch passes its checks, the pull request run fails, because the run
# tests the merge of the branch into the current base.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch20b lab-28-2-merge-ref
make_warehouse
scenario_merge_ref

snip 01-local
run 'git status --short --branch'
run 'python3 tests/check_rules.py'
run 'python3 tests/check_bulk.py'

snip 02-graph
run 'git log --oneline --graph --format="%h %an: %s" main feature/bulk-reorder -4'
run 'git merge-base main feature/bulk-reorder'

snip 03-merge-commit
note 'Build what the pull request run checks out: the merge of the branch into main, detached.'
run 'git merge-tree --write-tree main feature/bulk-reorder'
run 'git switch --quiet --detach main'
run 'git merge --quiet --no-ff -m "Merge feature/bulk-reorder into main (test merge)" feature/bulk-reorder'
run 'git status --short --branch'
run 'python3 tests/check_rules.py'
run_rc 'python3 tests/check_bulk.py'

snip 04-failure
note 'Re-checking the branch alone reproduces nothing, however often it is repeated:'
run 'git switch --quiet feature/bulk-reorder'
run_rc 'python3 tests/check_bulk.py'

snip 05-recovery
note 'Bring the base into the branch, then fix the call that the base change broke.'
run 'git merge --quiet -m "Merge main into feature/bulk-reorder" main'
run_rc 'python3 tests/check_bulk.py'
run "sed -i.bak 's/needs_reorder(stock, daily, lead_days)/needs_reorder(stock, daily, lead_days, 0)/' src/warehouse/bulk.py && rm src/warehouse/bulk.py.bak"
run_rc 'python3 tests/check_bulk.py'
run 'git commit -q -am "Pass the safety stock to needs_reorder"'
run 'git log --oneline --graph -4'

snip 06-verify
run 'git switch --quiet --detach main'
run 'git merge --quiet --no-ff -m "Test merge" feature/bulk-reorder'
run_rc 'python3 tests/check_rules.py && python3 tests/check_bulk.py'
run 'git switch --quiet feature/bulk-reorder'
run 'git status --short --branch'
lab_end
