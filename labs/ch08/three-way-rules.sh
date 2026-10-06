#!/usr/bin/env bash
# The three-way rule table, path by path: base, ours, theirs, result. Chapter 8, section 8.4.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 three-way-rules

quiet 'ek_base'
quiet 'mkdir scripts && printf "#!/bin/sh\npython -m evalkit --config config/eval.yaml\n" > scripts/legacy_eval.sh'
quiet 'printf "# evalkit\n\nEvaluation harness for LLM outputs.\n" > README.md && printf "pyyaml>=6.0\n" > requirements.txt'
quiet 'ek_commit "Add README, requirements and the legacy eval script"'
quiet 'git tag base'

# theirs: the feature branch
quiet 'git switch -c feature/rouge'
as asha
quiet 'printf "httpx>=0.27\n" >> requirements.txt && ek_commit "Add httpx for the judge client"'
quiet 'ek_set timeout_s 60 && ek_commit "Raise timeout to 60 seconds"'
quiet 'printf "Explain your verdict in one sentence.\n" >> prompts/judge.txt && ek_commit "Ask the judge for a rationale"'
quiet 'git rm -q scripts/legacy_eval.sh && ek_commit "Remove the legacy eval script"'
quiet 'printf "def rouge_l(pred, gold):\n    raise NotImplementedError\n" > evalkit/rouge.py && ek_commit "Add ROUGE-L stub"'

# ours: main
as you
quiet 'git switch main'
quiet 'printf "\nRun: python -m evalkit\n" >> README.md && ek_commit "Document how to run"'
quiet 'ek_set temperature 0.0 && ek_commit "Use temperature 0 for reproducible evals"'
quiet 'printf "Explain your verdict in one sentence.\n" >> prompts/judge.txt && ek_commit "Ask the judge to explain its verdict"'

snip 01-three-inputs
run 'git merge-base main feature/rouge'
note 'base (the merge base, tagged "base" by the demo):'
run 'git ls-tree -r --abbrev=7 base'
note 'ours (main):'
run 'git ls-tree -r --abbrev=7 main'
note 'theirs (feature/rouge):'
run 'git ls-tree -r --abbrev=7 feature/rouge'

snip 02-merge
run 'git merge feature/rouge'

snip 03-result
note 'result (the tree of the merge commit):'
run 'git ls-tree -r --abbrev=7 HEAD'

snip 04-content-merge
note 'What ours changed since the base (HEAD^1 is the first parent of the merge):'
run 'git diff -U0 base HEAD^1 -- config/eval.yaml'
note 'What theirs changed since the base (HEAD^2 is the second parent):'
run 'git diff -U0 base HEAD^2 -- config/eval.yaml'
note 'The merged file carries both changes:'
run 'git diff -U0 base HEAD -- config/eval.yaml'

lab_end
