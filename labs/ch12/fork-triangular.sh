#!/usr/bin/env bash
# Two remotes and a triangular workflow: fetch from the shared repository (upstream),
# push to your own fork (origin). A fork is simulated as a second bare repository.
# Chapter 12, section 12.10.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 fork-triangular

# Hidden setup: the shared repository, and Ravi as its maintainer with his own clone.
make_server
new_clone ravi
cd "$LAB_DIR" || exit 1

snip 01-fork-and-clone
note 'The Fork button, in plain Git: a server-side clone.'
run 'git clone --bare server/support-bot.git forks/you/support-bot.git'
run 'git clone forks/you/support-bot.git you/support-bot'
run 'cd you/support-bot'
hidden 'git remote set-url origin ../../forks/you/support-bot.git'
run 'git remote add upstream ../../server/support-bot.git'
run 'git fetch upstream'
run 'git remote -v'

snip 02-refs
run 'git show-ref --abbrev'

snip 03-triangular-config
run 'git config set remote.pushDefault origin'
run 'git config set push.default current'
run 'git switch -c feature/streaming upstream/main'
commit_file app/stream.py 'def stream(answer):\n    yield answer\n' 'Add streaming responses'
note 'One commit made here: "Add streaming responses".'
run 'git push'
run 'git rev-parse --abbrev-ref @{upstream} @{push}'
run 'git config get --all --show-names --regexp "^(remote\.pushdefault|push\.default|branch\.feature)"'

# The shared repository moves on: Ravi publishes a commit on main.
enter ravi
commit_file config.yaml 'model: small-v1\ntop_k: 8\n' 'Raise top_k to 8'
hidden 'git push'
enter you

snip 04-two-comparisons
run 'git config set status.compareBranches "@{upstream} @{push}"'
run 'git fetch upstream'
run 'git status'

snip 05-rebase-and-republish
run 'git pull --rebase'
run 'git status -sb'
run_rc 'git push'
run 'git push --force-with-lease'

snip 06-sync-fork-main
run 'git switch main'
run 'git merge --ff-only upstream/main'
run 'git push'
run 'git log --oneline --graph --decorate --all -4'

lab_end
