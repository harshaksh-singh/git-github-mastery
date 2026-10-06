#!/usr/bin/env bash
# One content conflict from start to finish: working tree, index stages, files in .git, resolution.
# Chapter 8, sections 8.8 and 8.10.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 conflict-anatomy

quiet 'ek_creative_judge'

snip 01-merge
run 'git log --oneline --graph --all'
run_rc 'git merge feature/creative-judge'

snip 02-status
run 'git status'

snip 03-markers
run 'cat config/eval.yaml'

snip 04-stages
run 'git ls-files -s'
run 'git ls-files -u'

snip 05-read-stages
run 'git show :1:config/eval.yaml'
note 'What our side did to the base, and what their side did:'
run 'git diff -U0 :1:config/eval.yaml :2:config/eval.yaml'
run 'git diff -U0 :1:config/eval.yaml :3:config/eval.yaml'

snip 06-gitdir
run "ls .git | grep -E 'MERGE|ORIG_HEAD'"
run 'cat .git/MERGE_HEAD'
run 'git rev-parse feature/creative-judge'
run 'git rev-parse HEAD ORIG_HEAD'
run 'cat .git/MERGE_MSG'
run 'git cat-file -t AUTO_MERGE'

snip 07-diff
run 'git diff'

snip 08-log-merge
run 'git log --oneline --left-right main...feature/creative-judge'
run 'git log --oneline --left-right --merge'

snip 09-blocked
run_rc 'git commit -m "Merge feature/creative-judge"'
run_rc 'git switch feature/creative-judge'

snip 10-resolve
note 'In your editor: delete the three marker lines and the 0.7 line. Keep temperature 0.0.'
quiet "ek_resolve_dropping '^temperature: 0.7' config/eval.yaml"
run 'cat config/eval.yaml'
run 'git diff AUTO_MERGE'

snip 11-add
run 'git add config/eval.yaml'
run 'git ls-files -s'
run 'git status'

snip 12-continue
MSG="Merge branch 'feature/creative-judge'

Keep temperature 0.0: reproducible scores are a release requirement.
The new seed and the rationale line in the judge prompt are taken as they are."
run_msg "$MSG" 'git merge --continue'
run 'git log --oneline --graph'
run "ls .git | grep -E 'MERGE|ORIG_HEAD'"

snip 13-result
run 'git show --stat --format=medium HEAD'

lab_end
