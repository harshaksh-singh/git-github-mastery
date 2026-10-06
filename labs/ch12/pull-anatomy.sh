#!/usr/bin/env bash
# git pull is git fetch plus one integration step. Fast-forward, the fatal error on
# diverged branches, and the three ways to answer it. Chapter 12, section 12.6.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 pull-anatomy

# Hidden setup: you and Asha clone; Asha publishes one commit.
make_server
new_clone you
new_clone asha
enter asha
commit_file app/retriever.py 'def retrieve(query, top_k):\n    return search(query)[:top_k]\n' 'Implement retrieval'
hidden 'git push'
enter you

snip 01-fast-forward
run 'git pull'
run 'git reflog -1'
run 'git reflog show origin/main -1'

# Now both sides commit: Asha publishes, you commit locally without fetching.
enter asha
commit_file config.yaml 'model: small-v1\ntop_k: 8\n' 'Raise top_k to 8'
hidden 'git push'
enter you
commit_file requirements-dev.txt 'pytest\n' 'Add dev requirements'

snip 02-diverged
note 'Asha has pushed "Raise top_k to 8"; you have committed "Add dev requirements".'
run 'git status -sb'
run_rc 'git pull'

snip 03-after-fatal
run 'git status -sb'
run 'git log --oneline --graph --decorate --all -4'

snip 04-ff-only
run_rc 'git pull --ff-only'

snip 05-merge
run 'git pull --no-rebase'
run 'git log --oneline --graph --decorate -5'
run 'git reflog -2'

snip 06-back-to-diverged
run 'git reset --hard ORIG_HEAD'
run 'git status -sb'

snip 07-rebase
run 'git pull --rebase'
run 'git log --oneline --graph --decorate -4'
run 'git reflog -4'

snip 08-config
run 'git config set pull.rebase true'
run 'git config set pull.ff only'
run 'git config get --all --show-names --regexp "^pull\."'

lab_end
