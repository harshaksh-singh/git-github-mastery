#!/usr/bin/env bash
# The Git data behind a pull request, imitated with a bare repository: a read-only ref
# refs/pull/1/head for the head commit and a test merge commit under refs/pull/1/merge.
# The commands on the "server" are plain Git chosen to reproduce the documented behavior;
# GitHub does not publish the commands it runs. Chapter 17, section 17.2.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 pr-refs
scenario_pr
hidden 'git fetch'
cd "$LAB_DIR" || exit 1

snip 01-server-opens-pr
note 'On the server. Opening pull request 1 for feature/priority-routing, as Git data:'
run 'cd server/ticket-router.git'
run 'git update-ref refs/pull/1/head refs/heads/feature/priority-routing'
note 'Clients may read refs/pull/ but not write it:'
run 'git config set receive.hideRefs refs/pull'
run 'git for-each-ref --format="%(objectname:short) %(refname)"'

snip 02-client-sees
run 'cd ../../asha/ticket-router'
run 'git ls-remote origin'
note 'A clone fetches refs/heads/* only, so the pull request ref is not in Asha'"'"'s clone:'
run 'git config get --all remote.origin.fetch'
run 'git fetch'
run 'git for-each-ref --format="%(refname)" refs/remotes refs/pull'

as asha
snip 03-fetch-head
run 'git fetch origin pull/1/head:pr-1'
run 'git log --oneline -3 pr-1'
run 'git rev-parse pr-1 origin/feature/priority-routing'

snip 04-read-only
run_rc 'git push origin pr-1:refs/pull/1/head'
run_rc 'git push origin main:refs/pull/9/head'

snip 05-test-merge
note 'On the server. A merge without a working tree (Chapter 8, section 8.17):'
run 'cd ../../server/ticket-router.git'
run_rc 'git merge-tree --write-tree main refs/pull/1/head'
run 'tree=$(git merge-tree --write-tree main refs/pull/1/head)'
run 'merge=$(git commit-tree $tree -p main -p refs/pull/1/head -m "Merge refs/pull/1/head into main")'
run 'git update-ref refs/pull/1/merge $merge'
run 'git log --oneline --graph -5 refs/pull/1/merge'
run 'git for-each-ref --format="%(objectname:short) %(refname)" refs/heads refs/pull'

snip 06-neither-branch-moved
note 'The test merge commit is on neither branch:'
run 'git branch --contains refs/pull/1/merge'
run 'git show -s --format="%h parents: %p" refs/pull/1/merge'
run 'git rev-parse main refs/pull/1/head'

snip 07-ci-checks-out-merge
note 'What a CI job sees when it checks out the merge ref:'
run 'cd ../../ravi/ticket-router'
run 'git fetch origin refs/pull/1/merge'
run 'git switch --detach FETCH_HEAD'
run 'git log --oneline -1'
run 'cat config/routing.yaml'
run 'grep -c escalations router/classify.py'

# Main moves again: Asha publishes a commit. The stored test merge still has the old base.
enter asha
printf '# ticket-router\n\nSends each support ticket to the queue that can answer it.\n\nRun the tests with pytest.\n' | put README.md
commit_all 'Describe how to run the tests'
hidden 'git push origin main'
cd "$LAB_DIR/server/ticket-router.git" || exit 1

snip 08-stale-merge-ref
note 'On the server, after one more commit landed on main:'
run 'git rev-parse --short main'
run 'git show -s --format="%h parents: %p" refs/pull/1/merge'
note 'The merge ref is a stored commit. It is as fresh as its first parent.'
run_rc 'git merge-base --is-ancestor main refs/pull/1/merge'

# A second pull request that conflicts with main.
enter ravi
hidden 'git switch -q main'
hidden 'git pull --ff-only'
hidden 'git switch -c fix/threshold'
printf 'model: router-small-v1\nconfidence_threshold: 0.65\nfallback_queue: general\n' | put config/routing.yaml
commit_all 'Lower the confidence threshold to 0.65'
hidden 'git push -u origin fix/threshold'
enter asha
printf 'model: router-small-v1\nconfidence_threshold: 0.8\nfallback_queue: general\n' | put config/routing.yaml
commit_all 'Raise the confidence threshold to 0.8'
hidden 'git push origin main'
cd "$LAB_DIR/server/ticket-router.git" || exit 1
git update-ref refs/pull/2/head refs/heads/fix/threshold

snip 09-conflict-no-merge-ref
note 'Pull request 2 changes a line that main has changed since. On the server:'
run_rc 'git merge-tree --write-tree --name-only main refs/pull/2/head'
note 'No clean tree, so no test merge commit and no refs/pull/2/merge:'
run 'git for-each-ref --format="%(refname)" refs/pull'

snip 10-head-outlives-branch
note 'The head branch is deleted. The pull request ref still names the commits:'
run 'git update-ref -d refs/heads/feature/priority-routing'
run 'git for-each-ref --format="%(objectname:short) %(refname)" refs/heads refs/pull'
run 'cd ../../ravi/ticket-router'
run 'git fetch --prune'
run 'git fetch origin pull/1/head'
run 'git log --oneline -1 FETCH_HEAD'

lab_end
