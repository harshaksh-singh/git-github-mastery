#!/usr/bin/env bash
# Lab 6.3 replay: a rename on one branch, an edit of the old path on the other.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
. "$(dirname "$0")/fixtures/m06.sh"
lab_begin ch08 lab-06-3-rename-edit

quiet 'm06_3_fixture'

snip 01-before
run 'git log --oneline --graph --all'
run 'git diff --name-status main...refactor/scoring-module'
run 'git diff --name-status refactor/scoring-module...main'

snip 02-merge
run 'git merge refactor/scoring-module'
run 'git ls-files evalkit'
run 'head -2 evalkit/scoring.py'

snip 03-internals
note 'The merge commit records a tree, not a rename:'
run 'git ls-tree -r --abbrev=7 HEAD evalkit'
run 'git log --oneline -- evalkit/scoring.py'
run 'git log --oneline --follow -- evalkit/scoring.py'

# ---- Failure scenario: the same move, but the file was rewritten on the way.
snip 04-failure
run 'git switch -q -c try/score-objects main^1'
run_rc 'git merge refactor/score-objects'
run 'git status --short'

snip 05-diagnosis
run 'git diff --summary try/score-objects...refactor/score-objects'
run 'git diff --summary --find-renames=30% try/score-objects...refactor/score-objects'

snip 06-recovery
run 'git merge --abort'
run_rc 'git merge -X find-renames=30% refactor/score-objects'
run 'git status --short'
run "grep -n -A4 '<<<<<<<' evalkit/scoring.py"

snip 07-resolve
note 'In your editor: one line that returns a Score AND strips whitespace.'
quiet "ek_replace_conflict evalkit/scoring.py '    return Score(\"exact_match\", float(pred.strip() == gold.strip()))'"
run "sed -n '11,12p' evalkit/scoring.py"
run 'git add evalkit/scoring.py'
run 'git merge --continue'

snip 08-verification
run 'git ls-files evalkit'
run 'git grep -n "strip()" -- evalkit'
run 'git log --oneline --graph -3'
run 'git switch -q main'

lab_end
