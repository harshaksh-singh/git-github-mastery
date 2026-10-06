#!/usr/bin/env bash
# -X ours, -X theirs, -s ours, the missing -s theirs, the recursive synonym, and a whitespace option.
# Chapter 8, section 8.6.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 strategy-options

quiet 'ek_creative_judge'

snip 01-what-differs
note 'ours changed temperature; theirs changed temperature AND seed, and added a prompt line.'
run 'git diff --stat main...feature/creative-judge'
run 'grep -n -e temperature -e seed config/eval.yaml'

snip 02-x-ours
run 'git merge -X ours feature/creative-judge'
run 'grep -n -e temperature -e seed config/eval.yaml'
run 'tail -1 prompts/judge.txt'
quiet 'git reset --hard ORIG_HEAD'

snip 03-x-theirs
run 'git merge -X theirs feature/creative-judge'
run 'grep -n -e temperature -e seed config/eval.yaml'
quiet 'git reset --hard ORIG_HEAD'

snip 04-s-ours
run 'git merge -s ours feature/creative-judge'
run 'grep -n -e temperature -e seed config/eval.yaml'
run 'tail -1 prompts/judge.txt'
note 'The tree of the merge commit is the tree of its first parent:'
run 'git rev-parse HEAD^{tree} HEAD^1^{tree}'
note 'Yet the history says the branch is merged:'
run 'git branch --merged'
quiet 'git reset --hard ORIG_HEAD'

snip 05-no-s-theirs
run_rc 'git merge -s theirs feature/creative-judge'

snip 06-recursive
run 'git merge -s recursive -X ours feature/creative-judge'
quiet 'git reset --hard ORIG_HEAD'

# ---- whitespace: a formatter re-indents the YAML list on one branch, a rename happens on the other
quiet 'cd "$LAB_DIR" && git init -q whitespace && cd whitespace && mkdir config'
quiet 'printf "model: judge-large-v2\nmetrics:\n  - exact_match\n  - f1\nseed: 7\n" > config/eval.yaml && ek_commit "Add eval config"'
quiet 'git switch -c chore/yaml-format'
as ravi
quiet 'printf "model: judge-large-v2\nmetrics:\n    - exact_match\n    - f1\nseed: 7\n" > config/eval.yaml && ek_commit "Reformat YAML lists with four-space indentation"'
as you
quiet 'git switch main'
quiet 'printf "model: judge-large-v2\nmetrics:\n  - exact_match\n  - token_f1\nseed: 7\n" > config/eval.yaml && ek_commit "Rename the f1 metric to token_f1"'

snip 07-whitespace-conflict
run_rc 'git merge chore/yaml-format'
run 'cat config/eval.yaml'
run 'git merge --abort'

snip 08-ignore-space-change
run 'git merge -X ignore-space-change chore/yaml-format'
run 'cat config/eval.yaml'

lab_end
