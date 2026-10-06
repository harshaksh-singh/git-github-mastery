#!/usr/bin/env bash
# A preview of Chapter 8: during a conflict the index holds up to three entries for one
# path, in stages 1, 2 and 3, and "git add" collapses them into one. Chapter 5, section 5.13.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 conflict-stages

git init -q support-bot
cd support-bot || exit 1
mkdir -p config
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
quiet 'git add . && git commit -m "Add settings"'
git switch -q -c tune-retrieval
printf 'model: small-v1\ntop_k: 8\n' > config/settings.yaml
quiet 'git commit -am "Raise top_k to 8"'
git switch -q main
printf 'model: small-v1\ntop_k: 3\n' > config/settings.yaml
quiet 'git commit -am "Lower top_k to 3"'

snip 01-before
note 'Normal state: one entry per path, at stage 0.'
run 'git ls-files --stage'

snip 02-conflict
run_rc 'git merge tune-retrieval'
run 'git status --short'
run 'git ls-files --stage'

snip 03-read-the-stages
note 'Stage 1: the merge base. Stage 2: the current branch. Stage 3: the branch being merged.'
run 'git show :1:config/settings.yaml'
run 'git show :2:config/settings.yaml'
run 'git show :3:config/settings.yaml'
run 'cat config/settings.yaml'

snip 04-resolve
note 'Resolve: write the content you want, then "git add" replaces the three entries with one.'
run "printf 'model: small-v1\ntop_k: 8\n' > config/settings.yaml"
run 'git add config/settings.yaml'
run 'git ls-files --stage'
run 'git status --short'
run 'git commit -m "Merge tune-retrieval: keep top_k at 8"'

lab_end
