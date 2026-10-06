#!/usr/bin/env bash
# Lab 7.5 replay: upstream configuration and a triangular workflow. You fork the shared
# repository (a second bare repository), fetch from "upstream" and push to "origin".
# Lab manual: lab-manual/m07-remotes.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 lab-07-5-upstream-triangular
scenario_07_5

snip 01-fork-and-clone
run 'git clone --bare server/support-bot.git forks/you/support-bot.git'
run 'git clone forks/you/support-bot.git you/support-bot'
run 'cd you/support-bot'
run 'git remote set-url origin ../../forks/you/support-bot.git'
run 'git remote add upstream ../../server/support-bot.git'
run 'git fetch upstream'
run 'git remote -v'

snip 02-refs
run 'git show-ref --abbrev'
run 'git branch -vv'

snip 03-configure
run 'git config set remote.pushDefault origin'
run 'git config set push.default current'
run 'git switch -c feature/streaming upstream/main'
run "mkdir -p app && printf 'def stream(answer):\n    yield answer\n' > app/stream.py"
run 'git add app/stream.py'
run 'git commit -m "Add streaming responses"'

snip 04-push-goes-to-fork
run 'git push'
run 'git rev-parse --abbrev-ref @{upstream} @{push}'
run 'git branch -vv'

snip 05-three-repositories
note 'The shared repository, then your fork:'
run 'git ls-remote --branches upstream'
run 'git ls-remote --branches origin'

as ravi
snip 06-upstream-moves
run 'cd ../../ravi/support-bot'
run "printf 'model: small-v1\ntop_k: 8\n' > config.yaml"
run 'git commit -am "Raise top_k to 8"'
run 'git push'
as you
run 'cd ../../you/support-bot'

snip 07-two-comparisons
run 'git config set status.compareBranches "@{upstream} @{push}"'
run 'git fetch upstream'
run 'git status'

snip 08-rebase-and-republish
run 'git pull --rebase'
run_rc 'git push'
run 'git push --force-with-lease'
run 'git status'

snip 09-sync-fork-main
run 'git switch main'
run 'git merge --ff-only upstream/main'
run 'git push'
run 'git log --oneline --graph --decorate --all -4'

snip 10-failure
run 'git switch feature/streaming'
run 'git push upstream feature/streaming'
run 'git ls-remote --branches upstream'

snip 11-recovery
run 'git push upstream --delete feature/streaming'
run 'git remote set-url --push upstream DISABLED'
run 'git remote -v'
run_rc 'git push upstream feature/streaming'

snip 12-verification
run 'git ls-remote --branches upstream'
run 'git ls-remote --branches origin'
run 'git fetch upstream'
run 'git config get --all --show-names --regexp "^(remote|push|branch\.feature)"'

lab_end
