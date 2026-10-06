#!/usr/bin/env bash
# Reverting a merge undoes its content, not its ancestry: the next merge of the same branch brings
# only the commits made after the first merge. A preview of Chapter 11. Chapter 8, section 8.18.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 revert-merge-preview

quiet 'ek_base'
quiet 'git switch -c feature/rationale'
as asha
quiet 'printf "Explain your verdict in one sentence.\n" >> prompts/judge.txt && ek_commit "Ask the judge for a rationale"'
quiet 'printf "Quote the evidence you used.\n" >> prompts/judge.txt && ek_commit "Ask the judge to quote evidence"'
as you
quiet 'git switch main'
quiet 'ek_set temperature 0.0 && ek_commit "Use temperature 0 for reproducible evals"'
quiet 'git merge feature/rationale'

snip 01-revert
run 'git log --oneline --graph'
run_rc 'git revert --no-edit HEAD'
run 'git revert --no-edit -m 1 HEAD'
run 'cat prompts/judge.txt'

# Asha adds one more commit to her branch; the branch is merged again.
quiet 'git switch feature/rationale'
as asha
quiet 'ek_set timeout_s 60 && ek_commit "Give the judge 60 seconds for longer answers"'
as you
quiet 'git switch main'

snip 02-remerge
run 'git log --oneline main..feature/rationale'
run 'git merge feature/rationale'
note 'The timeout arrived. The two prompt lines of the first merge did not come back:'
run 'grep timeout_s config/eval.yaml'
run 'cat prompts/judge.txt'
run 'git branch --merged'

lab_end
