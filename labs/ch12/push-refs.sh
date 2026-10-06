#!/usr/bin/env bash
# What else git push can do to the server's refs: delete a branch, publish tags,
# update several refs atomically. Chapter 12, section 12.7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 push-refs

# Hidden setup: you have published feature/eval-harness; release/0.1 exists on the server.
make_server
new_clone you
new_clone asha
enter you
hidden 'git switch -c release/0.1'
hidden 'git push -u origin release/0.1'
hidden 'git switch -c feature/eval-harness main'
commit_file eval/run_eval.py 'print("eval")\n' 'Add eval harness entry point'
hidden 'git push -u origin feature/eval-harness'
hidden 'git switch main'

snip 01-delete-branch
run 'git push origin --delete feature/eval-harness'
run 'git branch -vv'
run 'git ls-remote --branches origin'

snip 02-tags-are-not-pushed
run 'git tag -a v0.2.0 -m "Release 0.2.0"'
run 'git tag nightly'
run 'git push'
run 'git ls-remote --tags origin'

snip 03-push-tags
run 'git push origin v0.2.0'
commit_file CHANGELOG.md '## 0.2.1\n\n- Fix retrieval timeout\n' 'Add changelog for 0.2.1'
run 'git tag -a v0.2.1 -m "Release 0.2.1"'
run 'git push --follow-tags'
run 'git ls-remote --tags origin'

snip 04-tag-update-rejected
run 'git tag -f -a v0.2.0 -m "Release 0.2.0, retagged"'
run_rc 'git push origin v0.2.0'

# Asha publishes a commit on main, so that your main can no longer be pushed as it is.
enter asha
hidden 'git pull'
commit_file config.yaml 'model: small-v1\ntop_k: 8\n' 'Raise top_k to 8'
hidden 'git push'
enter you
commit_file app/settings.py 'TIMEOUT_SECONDS = 30\n' 'Set request timeout'
hidden 'git switch release/0.1'
commit_file VERSION '0.1.1\n' 'Bump version to 0.1.1'
hidden 'git switch main'

snip 05-atomic
note 'main is behind the server (Asha pushed); release/0.1 is one commit ahead.'
run 'git config set advice.pushUpdateRejected false'
run_rc 'git push --atomic origin main release/0.1'
run 'git ls-remote --branches origin'

snip 06-not-atomic
run_rc 'git push origin main release/0.1'
run 'git ls-remote --branches origin'

lab_end
