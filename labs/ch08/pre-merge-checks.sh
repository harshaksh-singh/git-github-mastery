#!/usr/bin/env bash
# What git merge refuses to do, and two things it does not refuse. Chapter 8, sections 8.19 and 8.20.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 pre-merge-checks

quiet 'ek_creative_judge'

snip 01-staged-change
note 'A staged change in a file the merge does not even touch:'
run 'echo "# scoring helpers" >> evalkit/metrics.py'
run 'git add evalkit/metrics.py'
run_rc 'git merge feature/creative-judge'
quiet 'git restore --staged --worktree evalkit/metrics.py'

snip 02-leftover-markers
run_rc 'git merge feature/creative-judge'
note 'Nothing was edited. git add accepts the file anyway:'
run 'git add config/eval.yaml'
run 'git status --short'
run_rc 'git diff --cached --check'

snip 03-merge-in-progress
run_rc 'git merge feature/creative-judge'
run_rc 'git commit -m "Resolve config" config/eval.yaml'
quiet 'git merge --abort'

snip 04-untracked-file
quiet 'git switch -q feature/creative-judge && printf "Calibration notes\n" > NOTES.md && ek_commit "Add calibration notes" && git switch -q main'
note 'The branch adds NOTES.md. You have an untracked file with the same name:'
run 'echo "my scratch notes" > NOTES.md'
run_rc 'git merge feature/creative-judge'
quiet 'rm NOTES.md'

snip 05-unrelated-histories
quiet 'git switch -q --orphan imported/prompt-library && printf "A library of judge prompts.\n" > README.md && ek_commit "Import the prompt library" && git switch -q main'
run_rc 'git merge-base main imported/prompt-library'
run_rc 'git merge imported/prompt-library'

snip 06-annotated-tag
quiet 'git switch -q -c release/0.1 main && printf "# evalkit\n" > README.md && ek_commit "Add a README" && git tag -a v0.1 -m "First tagged release" && git switch -q main'
note 'v0.1 is an annotated tag, one commit ahead of main, stored as refs/tags/v0.1:'
run 'git cat-file -t v0.1'
run 'git merge v0.1'

lab_end
