#!/usr/bin/env bash
# Replay of the local part of Lab 28.1: the repository state behind three of the six broken
# workflows, shown with plain Git.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch20b lab-28-1-broken-workflows
make_warehouse
scenario_branches

snip 01-shallow
note 'Workflow 1. The job sees a clone like this one:'
run 'git clone --quiet --depth 1 --no-tags "file://$PWD" ../runner'
run 'git -C ../runner rev-list --count HEAD'
run 'git -C ../runner tag --list'
run_rc "git -C ../runner describe --tags --match 'v*'"
run "git describe --tags --match 'v*'"

snip 02-paths
note 'Workflow 2. For a pull request, a path filter is evaluated on the three-dot diff:'
run 'git diff --name-only main...docs/rollback-steps'
run 'git diff --name-only main...feature/safety-stock'

snip 03-refs
note 'Workflow 5. Each of these refs gets pushes; a concurrency group should tell them apart:'
run 'git for-each-ref --format="%(refname)" refs/heads'

snip 04-cache-key
note 'Workflow 6. A key built from the lock file changes exactly when the lock file does:'
run 'git rev-parse main:uv.lock feature/safety-stock:uv.lock'
run 'git diff --stat main feature/safety-stock -- uv.lock'

snip 05-failure
note 'A tempting repair of workflow 1 that hides the fault instead of fixing it:'
run "git -C ../runner describe --tags --match 'v*' --always"

snip 06-recovery
run 'git -C ../runner fetch --quiet --unshallow --tags'
run "git -C ../runner describe --tags --match 'v*'"
lab_end
