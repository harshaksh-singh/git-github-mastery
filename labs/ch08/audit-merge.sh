#!/usr/bin/env bash
# Auditing merges: what git log -p, git show (combined diff) and --remerge-diff each reveal.
# Chapter 8, section 8.16.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 audit-merge

# Merge 1: a real conflict, resolved in favour of our temperature (the merge of section 8.8).
quiet 'ek_creative_judge'
quiet 'git merge feature/creative-judge'
quiet "ek_resolve_dropping '^temperature: 0.7' config/eval.yaml"
quiet "git add config/eval.yaml && tick && git commit -q -m \"Merge branch 'feature/creative-judge'\""

# Merge 2: no conflict at all, but the person merging slipped in an unrelated change.
as ravi
quiet 'git switch -c topic/docs && printf "# evalkit\n" > README.md && ek_commit "Add a README"'
as you
quiet 'git switch main'
quiet 'printf "pyyaml>=6.0\n" > requirements.txt && ek_commit "Add requirements"'
quiet 'git merge --no-commit topic/docs'
quiet "ek_set retries 0 && git add config/eval.yaml && tick && git commit -q -m \"Merge branch 'topic/docs'\""

# Merge 3: an honest clean merge.
as asha
quiet 'git switch -c topic/max-tokens main~1 && ek_set max_tokens 1024 && ek_commit "Allow 1024 output tokens"'
as you
quiet 'git switch main'
quiet 'git merge topic/max-tokens'

M1=$(git rev-parse --short main~3)
M2=$(git rev-parse --short main~1)

snip 01-log-p-is-blind
run 'git log --oneline --first-parent -5'
note 'By default git log shows no diff for a merge commit, with -p or with --stat:'
run "git log -1 -p --format='%h %s' $M2"
run "git log -1 --stat --format='%h %s' $M2"

snip 02-show-combined
note 'git show uses the dense combined format (--cc) for merges.'
run "git show --format='%h %s' $M1"
run "git show --format='%h %s' $M2"

snip 03-remerge-diff
run "git log --merges --remerge-diff --format='== %h %s'"

snip 04-first-parent
note 'Everything a merge brought to main, as one ordinary diff against its first parent:'
run "git show --first-parent --format='%h %s' $M2"

lab_end
