#!/usr/bin/env bash
# An octopus merge: one commit with more than two parents, and why it refuses conflicts.
# Chapter 8, section 8.14.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 octopus

quiet 'ek_base'
quiet 'printf "# evalkit\n" > README.md && printf "pyyaml>=6.0\n" > requirements.txt && ek_commit "Add README and requirements"'
as asha
quiet 'git switch -c topic/prompt main && printf "Explain your verdict in one sentence.\n" >> prompts/judge.txt && ek_commit "Ask the judge for a rationale"'
as ravi
quiet 'git switch -c topic/deps main && printf "httpx>=0.27\n" >> requirements.txt && ek_commit "Add httpx for the judge client"'
quiet 'git switch -c topic/docs main && printf "\nRun: python -m evalkit\n" >> README.md && ek_commit "Document how to run"'
as asha
quiet 'git switch -c topic/temperature main && ek_set temperature 0.7 && ek_commit "Raise temperature for judge diversity"'
as you
quiet 'git switch main'
quiet 'ek_set temperature 0.0 && ek_commit "Use temperature 0 for reproducible evals"'

snip 01-merge
run 'git merge topic/prompt topic/deps topic/docs'

snip 02-commit
run 'git log --oneline --graph'
run 'git cat-file -p HEAD'
run 'git reflog -1'

quiet 'git reset --hard ORIG_HEAD'

snip 03-conflict
note 'topic/temperature changes the same line as main.'
run_rc 'git merge topic/prompt topic/temperature topic/docs'
run 'git status --short --branch'
run "ls .git | grep -E 'MERGE|ORIG_HEAD'"

lab_end
