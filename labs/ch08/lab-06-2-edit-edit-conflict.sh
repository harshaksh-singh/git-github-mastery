#!/usr/bin/env bash
# Lab 6.2 replay: an edit-against-edit conflict, resolved by reading the three index stages.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
. "$(dirname "$0")/fixtures/m06.sh"
lab_begin ch08 lab-06-2-edit-edit-conflict

quiet 'm06_2_fixture'

snip 01-merge
run 'git log --oneline --graph --all'
run_rc 'git merge feature/case-insensitive'
run 'git status --short'

snip 02-stages
run 'git ls-files -u'
run 'head -9 evalkit/metrics.py'

snip 03-intent
note 'stage 1 to stage 2: what OUR side did to the common ancestor'
run 'git diff -U0 :1:evalkit/metrics.py :2:evalkit/metrics.py'
note 'stage 1 to stage 3: what THEIR side did to it'
run 'git diff -U0 :1:evalkit/metrics.py :3:evalkit/metrics.py'
run 'git log --oneline --left-right --merge'

snip 04-resolve
note 'In your editor: replace the whole conflict block by one line that does both.'
quiet "ek_resolve_dropping 'return float' evalkit/metrics.py"
quiet "sed -e 's/^def exact_match(pred, gold):\$/&\\
    return float(pred.strip().lower() == gold.strip().lower())/' evalkit/metrics.py > m && mv m evalkit/metrics.py"
run 'head -2 evalkit/metrics.py'
run 'git diff'

snip 05-conclude
run 'git add evalkit/metrics.py'
run 'git ls-files -s evalkit/metrics.py'
run_rc 'git diff --cached --check'
run 'git merge --continue'

snip 06-checkpoint
run 'git log --oneline --graph -5'
run 'git show --format="%h %s" HEAD'

# ---- Failure scenario: the conflicted file is staged with the markers still in it.
snip 07-failure
run_rc 'git merge feature/judge-wording'
run 'cat prompts/judge.txt'
note 'Reflex: "git add marks it as resolved". Nothing was edited.'
run 'git add prompts/judge.txt'
run 'git status --short'
run_rc 'git diff --cached --check'

snip 08-recovery
run 'git restore --merge prompts/judge.txt'
run 'git status --short'
note 'In your editor: one line that keeps both intents, and no marker lines.'
quiet "ek_resolve_dropping '^Answer with' prompts/judge.txt && printf 'Answer with exactly one word: PASS, FAIL or UNSURE.\n' >> prompts/judge.txt"
run 'cat prompts/judge.txt'
run 'git add prompts/judge.txt'
run_rc 'git diff --cached --check'
run 'git merge --continue'

snip 09-verification
run_rc "git grep -n -E '^(<<<<<<<|=======|>>>>>>>)'"
run 'git log --oneline --graph -4'
run 'git status --short --branch'

lab_end
