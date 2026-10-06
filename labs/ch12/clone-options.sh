#!/usr/bin/env bash
# What --origin, --branch, --bare and --mirror change in the result of git clone.
# Chapter 12, section 12.3.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 clone-options

# Hidden setup: a server with main, a release branch, a feature branch and a tag.
make_server
new_clone asha
enter asha
hidden 'git tag -a v0.1.0 -m "First internal release"'
hidden 'git push origin v0.1.0'
hidden 'git switch -c release/0.1'
hidden 'git push -u origin release/0.1'
hidden 'git switch -c feature/reranker main'
commit_file app/reranker.py 'def rerank(docs):\n    return docs\n' 'Add reranker stub'
hidden 'git push -u origin feature/reranker'
cd "$LAB_DIR" || exit 1
as you

snip 01-origin-branch
run 'git clone --origin company --branch release/0.1 server/support-bot.git by-name'
run 'git -C by-name config get --all --show-names --regexp "^(remote|branch)\."'
run 'git -C by-name branch -a -vv'

snip 02-bare
run 'git clone --bare server/support-bot.git copy.git'
run 'git -C copy.git config get --all --show-names --regexp "^(core\.bare|remote)"'
run 'git -C copy.git show-ref --abbrev'

snip 03-mirror
run 'git clone --mirror server/support-bot.git mirror.git'
run 'git -C mirror.git config get --all --show-names --regexp "^(core\.bare|remote)"'
run 'git -C mirror.git show-ref --abbrev'

snip 04-tag
run 'git clone --branch v0.1.0 server/support-bot.git at-tag 2>&1 | head -4'
run 'git -C at-tag status'

snip 05-single-branch
run 'git clone --single-branch server/support-bot.git narrow'
run 'git -C narrow config get --all remote.origin.fetch'
run 'git -C narrow branch -r'

lab_end
