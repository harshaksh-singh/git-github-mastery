#!/usr/bin/env bash
# What a remote is: a name, a URL and refspecs in .git/config; the refs on each side;
# what a bare repository contains. Chapter 12, section 12.2.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 remote-anatomy

# Hidden setup: the server already has history, a feature branch and a release tag from Asha.
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

snip 01-clone
run 'git clone server/support-bot.git you/support-bot'
run 'cd you/support-bot'
run 'cat .git/config'

snip 02-refs
run 'git remote -v'
note 'Refs in your clone:'
run 'git show-ref --abbrev'
note 'Refs in the server repository:'
run 'git -C ../../server/support-bot.git show-ref --abbrev'

snip 03-branches
run 'git branch -a -vv'
run 'git log --oneline --graph --decorate --all'

snip 04-bare
run 'ls -F ../../server/support-bot.git'
run 'git -C ../../server/support-bot.git config get core.bare'
run_rc 'git -C ../../server/support-bot.git status'

snip 05-relative-url
run 'git remote set-url origin ../../server/support-bot.git'
run 'git remote -v'
run 'git config get --all --show-names --regexp "^(remote|branch)\."'

lab_end
