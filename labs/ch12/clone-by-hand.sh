#!/usr/bin/env bash
# git clone taken apart: the same result built with init, remote add, fetch and switch.
# Chapter 12, section 12.3.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 clone-by-hand

# Hidden setup: a server with main, one feature branch and one annotated tag.
make_server
new_clone asha
enter asha
hidden 'git switch -c feature/reranker'
commit_file app/reranker.py 'def rerank(docs):\n    return docs\n' 'Add reranker stub'
hidden 'git push -u origin feature/reranker'
hidden 'git switch main'
hidden 'git tag -a v0.1.0 -m "First internal release"'
hidden 'git push origin v0.1.0'
cd "$LAB_DIR" || exit 1
as you

snip 01-init-remote
run 'git init by-hand'
run 'cd by-hand'
run 'git remote add origin ../server/support-bot.git'
run 'git config get --all --show-names --regexp "^remote\."'

snip 02-fetch
run 'git fetch origin'
run 'git show-ref --abbrev'
run 'git symbolic-ref refs/remotes/origin/HEAD'
run 'git status'

snip 03-switch
run 'git switch main'
run 'git config get --all --show-names --regexp "^branch\."'
run 'git branch -vv'
run 'ls'

lab_end
