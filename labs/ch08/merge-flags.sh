#!/usr/bin/env bash
# --no-ff, --no-commit, --ff-only, --squash and merge.ff: what each one leaves behind.
# Chapter 8, section 8.12.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 merge-flags

quiet 'ek_base'
quiet 'git switch -c feature/rationale'
as asha
quiet 'printf "Explain your verdict in one sentence.\n" >> prompts/judge.txt && ek_commit "Ask the judge for a rationale"'
quiet 'printf "Quote the evidence you used.\n" >> prompts/judge.txt && ek_commit "Ask the judge to quote evidence"'
as you
quiet 'git switch main'

snip 01-no-ff
note 'main is an ancestor of feature/rationale, so a plain merge would fast-forward.'
run 'git merge --no-ff feature/rationale'
run 'git log --oneline --graph'
quiet 'git reset --hard ORIG_HEAD'

snip 02-no-commit-fast-forwards
run 'git merge --no-commit feature/rationale'
run 'git log --oneline --graph'
quiet 'git reset --hard ORIG_HEAD'

snip 03-no-commit
run 'git merge --no-ff --no-commit feature/rationale'
run 'git status'
run "ls .git | grep -E 'MERGE|ORIG_HEAD'"
run 'cat .git/MERGE_MODE; echo'
run 'git log --oneline -1'
run 'git merge --abort'

# From here on the branches have diverged.
quiet 'ek_set temperature 0.0 && ek_commit "Use temperature 0 for reproducible evals"'

snip 04-ff-only
run 'git log --oneline --graph --all'
run_rc 'git merge --ff-only feature/rationale'
run 'git status --short --branch'

snip 05-squash
run 'git merge --squash feature/rationale'
run 'git status'
run "ls .git | grep -E 'MERGE|ORIG_HEAD|SQUASH'"
run 'head -3 .git/SQUASH_MSG'

snip 06-squash-commit
run 'git commit -q -m "Ask the judge for a rationale and for evidence"'
run 'git log --oneline --graph --all'
run 'git show -s --format="%h parents: %p" HEAD'
run 'git branch --no-merged'
run_rc 'git branch -d feature/rationale'

# Asha keeps working on the same branch after it was squashed into main.
quiet 'git switch feature/rationale'
as asha
quiet "sed -e 's/in one sentence/in two sentences/' prompts/judge.txt > j && mv j prompts/judge.txt"
quiet 'ek_commit "Allow a two-sentence rationale"'
as you
quiet 'git switch main'

snip 07-squash-then-reuse
note 'The squash commit recorded no second parent, so the merge base has not moved:'
run 'git log --oneline -1 $(git merge-base main feature/rationale)'
run_rc 'git merge --squash feature/rationale'
run 'cat prompts/judge.txt'
quiet 'git reset --merge'

snip 08-merge-ff-config
quiet 'git switch -c docs/readme && printf "# evalkit\n" > README.md && ek_commit "Add a README" && git switch main'
note 'docs/readme is one commit ahead of main. merge.ff=false behaves like --no-ff:'
run 'git -c merge.ff=false merge docs/readme'
note 'merge.ff=only behaves like --ff-only:'
run_rc 'git -c merge.ff=only -c advice.diverging=false merge feature/rationale'

lab_end
