#!/usr/bin/env bash
# What a job triggered by `pull_request` checks out: the test merge commit under
# refs/pull/N/merge, shallow, with a detached HEAD. The tests pass on the head commit and fail
# on the merge. Chapter 20A, section 20A.8. The server side imitates documented behavior with
# plain Git (Chapter 17, section 17.2); nothing here ran on GitHub.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch20a merge-ref
scenario_pull_request
server_open_pr 7 feature/reorder-report
cd "$LAB_DIR" || exit 1
HUB="file://$LAB_DIR/hub/inventory-api.git"

snip 01-your-branch
note 'Your clone, on the pull request branch. The tests pass.'
run 'cd you/inventory-api'
run 'git switch feature/reorder-report'
run 'git log --oneline -2'
run 'PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1'
run 'cd ../..'

snip 02-server-refs
note 'The repository on the platform after pull request 7 was opened:'
run 'git ls-remote "$HUB"'

snip 03-runner-checkout
note 'The runner: fetch one commit, the one refs/pull/7/merge names, and detach HEAD on it.'
run 'git init --quiet runner && cd runner'
run 'git remote add origin "$HUB"'
run 'git fetch --no-tags --depth=1 origin +refs/pull/7/merge:refs/remotes/pull/7/merge'
run 'git checkout --detach refs/remotes/pull/7/merge'

snip 04-what-is-checked-out
run 'git status --short --branch'
run 'git log -1 --format="GITHUB_SHA would be %H%n%an: %s"'
run 'git rev-list --count HEAD'
run 'git branch --show-current'
run 'grep LOW_STOCK_THRESHOLD src/inventory_api/stock.py'
run 'ls src/inventory_api'

snip 05-tests-on-the-merge
note 'The merged code is what CI tests. main changed the threshold; the new test assumed 5.'
run_rc 'PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null'
run 'PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1'

snip 06-not-in-your-clone
note 'Back in your clone: the commit CI tested is not there, and your branch is unchanged.'
run 'cd ../you/inventory-api'
run 'merge=$(git ls-remote "$HUB" refs/pull/7/merge | cut -f1)'
run_rc 'git cat-file -t $merge'
note 'Reproduce what CI tested: merge the current base into a throwaway copy of your branch.'
run 'git fetch --quiet origin'
run 'git switch --quiet --detach feature/reorder-report'
run 'git merge --quiet --no-edit origin/main'
run 'git rev-parse HEAD^{tree}'
run 'git -C ../../runner rev-parse HEAD^{tree}'
run 'PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1'
run 'git switch --quiet feature/reorder-report'
lab_end
