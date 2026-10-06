#!/usr/bin/env bash
# The merge base: one in ordinary histories, two in a criss-cross. Chapter 8, sections 8.2 and 8.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 merge-base

# ---- Part 1: an ordinary fork. Two commits on the feature branch, one on main.
quiet 'ek_base'
quiet 'git switch -c feature/rationale'
as asha
quiet 'printf "Explain your verdict in one sentence.\n" >> prompts/judge.txt && ek_commit "Ask the judge for a rationale"'
quiet 'printf "Quote the evidence you used.\n" >> prompts/judge.txt && ek_commit "Ask the judge to quote evidence"'
as you
quiet 'git switch main'
quiet 'ek_set temperature 0.0 && ek_commit "Use temperature 0 for reproducible evals"'

snip 01-merge-base
run 'git log --oneline --graph --all'
run 'git merge-base main feature/rationale'
run 'git rev-list --left-right --count main...feature/rationale'
run 'git log --oneline --left-right main...feature/rationale'

snip 02-three-dot-diff
note 'Three dots in git diff: from the merge base to the right-hand side.'
run 'git diff --stat main...feature/rationale'
note 'Two dots (or a space): the two tips compared directly.'
run 'git diff --stat main..feature/rationale'

# ---- Part 2: a criss-cross. main and release/1.0 each merged the other, and each merge
# resolved the same conflict in favour of its own side.
quiet 'cd "$LAB_DIR" && ek_base crisscross'
quiet 'git branch release/1.0'
quiet 'ek_set temperature 0.0 && ek_commit "Use temperature 0 for reproducible evals"'
quiet 'git switch release/1.0'
as asha
quiet 'ek_set temperature 0.7 && ek_commit "Raise temperature for the 1.0 judge"'
# Asha merges main into release/1.0 and keeps her 0.7.
quiet 'git merge main; git checkout --ours config/eval.yaml; ek_commit "Merge main into release/1.0, keep temperature 0.7"'
as you
quiet 'git switch main'
# At the same time you merge the release branch (as it was before her merge) into main and keep 0.0.
quiet 'git merge release/1.0~1; git checkout --ours config/eval.yaml; ek_commit "Merge release/1.0 into main, keep temperature 0.0"'

snip 03-crisscross
run 'git log --oneline --graph --all'
run 'git merge-base main release/1.0'
run 'git merge-base --all main release/1.0'

snip 04-three-answers
note 'Merge with only the first candidate as the base:'
run 'tree=$(git merge-tree --write-tree --merge-base=release/1.0~1 main release/1.0)'
run 'git show $tree:config/eval.yaml | grep temperature'
note 'Merge with only the second candidate as the base:'
run 'tree=$(git merge-tree --write-tree --merge-base=main~1 main release/1.0)'
run 'git show $tree:config/eval.yaml | grep temperature'

snip 05-virtual-base
run_rc 'git merge release/1.0'
run 'git ls-files -u'
run 'git show :1:config/eval.yaml'

snip 06-diff3-nested
run 'git merge --abort'
run_rc 'git -c merge.conflictStyle=diff3 merge release/1.0'
run 'cat config/eval.yaml'
quiet 'git merge --abort'

lab_end
