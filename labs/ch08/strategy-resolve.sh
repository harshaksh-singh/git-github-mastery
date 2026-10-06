#!/usr/bin/env bash
# The legacy "resolve" strategy on the criss-cross history of section 8.5: an internal error and an
# unmerged path with no conflict markers in the file. Chapter 8, section 8.20.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 strategy-resolve

# The same criss-cross as in merge-base.sh: main and release/1.0 each merged the other, and each
# merge kept its own temperature.
quiet 'ek_base crisscross'
quiet 'git branch release/1.0'
quiet 'ek_set temperature 0.0 && ek_commit "Use temperature 0 for reproducible evals"'
quiet 'git switch release/1.0'
as asha
quiet 'ek_set temperature 0.7 && ek_commit "Raise temperature for the 1.0 judge"'
quiet 'git merge main; git checkout --ours config/eval.yaml; ek_commit "Merge main into release/1.0, keep temperature 0.7"'
as you
quiet 'git switch main'
quiet 'git merge release/1.0~1; git checkout --ours config/eval.yaml; ek_commit "Merge release/1.0 into main, keep temperature 0.0"'

snip 01-resolve
run 'git merge-base --all main release/1.0'
run_rc 'git merge -s resolve release/1.0'
run 'git status --short'
run 'git ls-files -u'
note 'The path is unmerged, and the file contains no conflict marker:'
run 'grep -n -e "<<<<<<<" -e temperature -e ">>>>>>>" config/eval.yaml'
run 'git merge --abort'

snip 02-exec-path
note 'The strategies that exist as separate programs (ort is built into git merge itself):'
run 'ls "$(git --exec-path)" | grep -E "^git-merge-(octopus|ours|recursive|resolve|subtree)$"'
run 'head -6 "$(git --exec-path)/git-merge-resolve"'

lab_end
