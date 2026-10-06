#!/usr/bin/env bash
# What a merge commit is, how its parents are ordered, and what first-parent history means.
# Chapter 8, section 8.13.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 merge-commit-anatomy

quiet 'ek_base'
quiet 'git switch -c feature/rationale'
as asha
quiet 'printf "Explain your verdict in one sentence.\n" >> prompts/judge.txt && ek_commit "Ask the judge for a rationale"'
quiet 'printf "Quote the evidence you used.\n" >> prompts/judge.txt && ek_commit "Ask the judge to quote evidence"'
as you
quiet 'git switch main'
quiet 'ek_set temperature 0.0 && ek_commit "Use temperature 0 for reproducible evals"'
quiet 'git merge feature/rationale'
quiet 'ek_set batch_size 32 && ek_commit "Raise batch size to 32"'
M=$(git rev-parse --short main~1)

snip 01-object
run 'git log --oneline --graph'
run "git cat-file -p $M"

snip 02-parents
run "git rev-parse --short $M^1"
run "git rev-parse --short $M^2"
note 'The commits that came in through the merge: reachable from parent 2, not from parent 1.'
run "git log --oneline $M^1..$M^2"
note 'The same range plus the merge itself, with the ^- shorthand:'
run "git log --oneline $M^-"

snip 03-first-parent
run 'git log --oneline --first-parent'
run 'git log --oneline --merges'
run 'git log --oneline --no-merges'

snip 04-diff-per-parent
note 'What main gained from the merge:'
run "git diff --stat $M^1 $M"
note 'What the feature branch would have gained from it:'
run "git diff --stat $M^2 $M"

# ---- The first-parent flip: merge main INTO the feature branch, then fast-forward main to it.
quiet 'git switch -c feature/httpx main'
as ravi
quiet 'printf "httpx>=0.27\n" > requirements.txt && ek_commit "Add httpx for the judge client"'
as you
quiet 'git switch main'
quiet 'ek_set retries 3 && ek_commit "Retry the judge three times"'

snip 05-flip
run 'git log --oneline --first-parent -3 main'
run 'git switch -q feature/httpx'
run 'git merge main'
run 'git switch -q main'
run 'git merge feature/httpx'
run 'git log --oneline --graph -4'
run 'git log --oneline --first-parent -3 main'

lab_end
