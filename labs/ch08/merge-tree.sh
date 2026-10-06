#!/usr/bin/env bash
# git merge-tree: a merge computed without an index or a working tree, in a bare repository.
# Chapter 8, section 8.17.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 merge-tree

quiet 'ek_creative_judge'
as asha
quiet 'git switch -c docs/readme main~1'
quiet 'printf "# evalkit\n\nEvaluation harness for LLM outputs.\n" > README.md && ek_commit "Add a README"'
as you
quiet 'git switch main'
quiet 'cd "$LAB_DIR"'

snip 01-bare
run 'git clone -q --bare evalkit server.git'
run 'cd server.git'
run 'git rev-parse --is-bare-repository'
run 'git log --oneline --graph --all'
run_rc 'git merge docs/readme'

snip 02-clean
run_rc 'git merge-tree --write-tree main docs/readme'
run 'tree=$(git merge-tree --write-tree main docs/readme)'
run 'git ls-tree -r --abbrev=7 $tree'

snip 03-commit
run "commit=\$(git commit-tree \$tree -p main -p docs/readme -m \"Merge branch 'docs/readme'\")"
run 'git update-ref refs/heads/main $commit'
run 'git log --oneline --graph -4 main'

snip 04-conflict
run_rc 'git merge-tree --write-tree main feature/creative-judge'

snip 05-conflict-tree
run 'tree=$(git merge-tree --write-tree main feature/creative-judge | head -1)'
run 'git show $tree:config/eval.yaml | head -6'

snip 06-quiet
note 'A yes/no answer for a "can this be merged?" indicator:'
run_rc 'git merge-tree --quiet main feature/creative-judge'
run_rc 'git merge-tree --write-tree --name-only --no-messages main feature/creative-judge'

lab_end
