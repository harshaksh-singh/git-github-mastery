#!/usr/bin/env bash
# Refspecs as the only thing that decides which refs move: a narrowed clone, the meaning
# of the leading +, extra namespaces such as pull request refs, negative refspecs,
# and push refspecs. Chapter 12, section 12.12.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 refspec-surgery

# Hidden setup: a server with main, release/0.1, a bot branch, and one ref outside
# refs/heads that imitates the ref a hosting platform keeps for pull request 7.
make_server
new_clone asha
enter asha
hidden 'git push origin main:refs/heads/release/0.1'
hidden 'git push origin main:refs/heads/dependabot/pip/requests-2.33'
hidden 'git switch -c feature/reranker'
commit_file app/reranker.py 'def rerank(docs):\n    return docs\n' 'Add reranker stub'
hidden 'git push origin HEAD:refs/pull/7/head'
hidden 'git switch main'
cd "$LAB_DIR" || exit 1
as you
mkdir -p "$LAB_DIR/you"

snip 01-narrow-clone
run 'git clone --single-branch server/support-bot.git you/support-bot'
run 'cd you/support-bot'
hidden 'git remote set-url origin ../../server/support-bot.git'
run 'git config get --all remote.origin.fetch'
run 'git branch -r'
run_rc 'git switch release/0.1'

snip 02-widen
run 'git remote set-branches --add origin release/0.1'
run 'git config get --all remote.origin.fetch'
run 'git fetch'
run 'git remote set-branches origin "*"'
run 'git config get --all remote.origin.fetch'
run 'git fetch'

# Asha publishes a commit on release/0.1; you fetch it; then she amends it and force-pushes.
enter asha
hidden 'git switch release/0.1'
commit_file VERSION '0.1.0\n' 'Add VERSION file'
hidden 'git push'
enter you
hidden 'git fetch'
enter asha
hidden 'git commit --amend -m "Add VERSION file for release 0.1"'
hidden 'git push --force'
enter you

snip 03-plus
note 'Asha has rewritten the tip of release/0.1 on the server. Your refspec, without its +:'
run 'git config set remote.origin.fetch "refs/heads/*:refs/remotes/origin/*"'
run_rc 'git fetch'
run 'git config set remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"'
run 'git fetch'

snip 04-negative
run 'git config set --append remote.origin.fetch "^refs/heads/dependabot/*"'
run 'git branch -r -d origin/dependabot/pip/requests-2.33'
run 'git fetch'
run 'git branch -r'

snip 05-pull-request-refs
run 'git ls-remote origin "refs/pull/*"'
run 'git fetch origin pull/7/head:pr-7'
run 'git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"'
run 'git fetch'
run 'git config get --all remote.origin.fetch'

snip 06-push-refspecs
commit_file docs/runbook.md '# Runbook\n' 'Start the runbook'
commit_file docs/oncall.md '# On call\n' 'Add on-call notes'
note 'Two commits made on main: "Start the runbook", then "Add on-call notes".'
run 'git push origin HEAD~1:main'
run 'git push origin HEAD:refs/heads/review/oncall-notes'
run 'git push origin :review/oncall-notes'
run 'git status -sb'

lab_end
