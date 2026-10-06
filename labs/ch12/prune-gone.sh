#!/usr/bin/env bash
# Stale remote-tracking refs, git fetch --prune, branches whose upstream is "gone",
# the directory/file ref conflict that blocks a fetch, and the branch that comes back
# from the dead. Chapter 12, section 12.11.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 prune-gone

# Hidden setup. Asha has local branches for two feature branches and has seen a branch
# called "release". Then you merge feature/reranker and delete it on the server, and the
# team replaces the branch "release" by "release/1.0".
make_server
new_clone you
enter you
hidden 'git switch -c feature/reranker'
commit_file app/reranker.py 'def rerank(docs):\n    return docs\n' 'Add reranker stub'
hidden 'git push -u origin feature/reranker'
hidden 'git switch -c feature/eval-harness main'
commit_file eval/run_eval.py 'print("eval")\n' 'Add eval harness entry point'
hidden 'git push -u origin feature/eval-harness'
hidden 'git push origin main:refs/heads/release'
hidden 'git switch main'
new_clone asha
enter asha
hidden 'git switch feature/reranker'
hidden 'git switch feature/eval-harness'
hidden 'git switch main'
enter you
hidden 'git merge --no-ff -m "Merge branch feature/reranker" feature/reranker'
hidden 'git push'
hidden 'git push origin --delete feature/reranker'
hidden 'git push origin --delete release'
hidden 'git push origin main:refs/heads/release/1.0'
enter asha

snip 01-stale
run 'git branch -r'
run 'git ls-remote --branches origin'

snip 02-remote-show
run 'git remote show origin'

snip 03-fetch-blocked
run_rc 'git fetch'

snip 04-prune
run 'git remote prune --dry-run origin'
run 'git fetch --prune'
run 'git branch -r'

snip 05-gone
run 'git branch -vv'
run 'git for-each-ref --format="%(refname:short) %(upstream:track)" refs/heads'

snip 06-zombie
run 'git switch feature/reranker'
run_rc 'git pull'
run 'git push'
run 'git ls-remote --branches origin'

snip 07-cleanup
run 'git push origin --delete feature/reranker'
run 'git switch main'
run 'git pull --ff-only'
run 'git branch -d feature/reranker'

snip 08-fetch-prune-config
run 'git config set fetch.prune true'
as you
hidden 'git -C ../../you/support-bot push origin --delete feature/eval-harness'
as asha
note 'You have deleted feature/eval-harness on the server in the meantime.'
run 'git fetch'
run 'git branch -vv'

lab_end
