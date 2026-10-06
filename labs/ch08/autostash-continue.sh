#!/usr/bin/env bash
# git merge --autostash from start to finish: where the stash is kept and who applies it.
# Chapter 8, section 8.19.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 autostash-continue

quiet 'ek_creative_judge'

snip 01-stopped
note 'An uncommitted edit in a file that the merge also changes (on another line):'
run "sed -e 's/strict grader/strict but fair grader/' prompts/judge.txt > j && mv j prompts/judge.txt"
run 'git status --short'
run_rc 'git merge --autostash feature/creative-judge'
run 'git status --short'
note 'The hint says "git stash pop". The stash list is empty:'
run 'git stash list'
run_rc 'git stash pop'
run 'git log -1 --format="%h %s" MERGE_AUTOSTASH'

snip 02-concluded
note 'Resolve the conflict as in section 8.10, then conclude the merge:'
quiet "ek_resolve_dropping '^temperature: 0.7' config/eval.yaml"
run 'git add config/eval.yaml'
run 'git merge --continue'
run 'git status --short'
run 'cat prompts/judge.txt'
run 'git stash list'

lab_end
