#!/usr/bin/env bash
# A change made on both branches and reverted on one of them comes back with the merge.
# Chapter 8, section 8.15.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 revert-one-side

quiet 'ek_base'
quiet 'git switch -c feature/long-answers'
as asha
quiet 'ek_set max_tokens 2048 && ek_commit "Allow long answers: max_tokens 2048"'
quiet 'printf "Answer in full sentences.\n" >> prompts/judge.txt && ek_commit "Ask for full sentences"'
as you
quiet 'git switch main'
# The same change is cherry-picked to main as a quick fix, then reverted when latency doubles.
quiet 'tick; git cherry-pick feature/long-answers~1'
quiet 'tick; git revert --no-edit HEAD'

snip 01-history
run 'git log --oneline --graph --all'
run 'grep max_tokens config/eval.yaml'

snip 02-merge
run 'git merge feature/long-answers'
run 'grep max_tokens config/eval.yaml'

snip 03-three-inputs
note 'base, ours, theirs, result:'
run 'git show $(git merge-base HEAD^1 HEAD^2):config/eval.yaml | grep max_tokens'
run 'git show HEAD^1:config/eval.yaml | grep max_tokens'
run 'git show HEAD^2:config/eval.yaml | grep max_tokens'
run 'git show HEAD:config/eval.yaml | grep max_tokens'

lab_end
