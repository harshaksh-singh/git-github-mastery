#!/usr/bin/env bash
# Lab 6.4 replay: one branch edits a script, the other deletes it and replaces it by a make target.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
. "$(dirname "$0")/fixtures/m06.sh"
lab_begin ch08 lab-06-4-modify-delete

quiet 'm06_4_fixture'

snip 01-merge
run 'git log --oneline --graph --all'
run_rc 'git merge cleanup/remove-legacy'
run 'git status --short'

snip 02-stages
run 'git ls-files -u'
run_rc 'git show :3:scripts/legacy_eval.sh'
note 'What our side changed in the file that their side deleted:'
run 'git diff -U0 :1:scripts/legacy_eval.sh :2:scripts/legacy_eval.sh'

snip 03-why-deleted
run 'git log --oneline --left-right --merge'
run 'git show --stat --format="%h %an: %s" cleanup/remove-legacy'
run 'cat Makefile'

snip 04-resolve
note 'Decision: the script stays deleted, and our --seed 7 moves to the make target.'
run 'git rm scripts/legacy_eval.sh'
quiet "printf 'eval:\n\tpython -m evalkit run --config config/eval.yaml --seed 7\n' > Makefile"
run 'cat Makefile'
run 'git add Makefile'
run 'git status --short'
MSG="Merge branch 'cleanup/remove-legacy'

scripts/legacy_eval.sh stays deleted. The --seed 7 flag that main had added
to it is carried over to the eval target in the Makefile."
run_msg "$MSG" 'git merge --continue'

snip 05-checkpoint
run 'git ls-files'
run 'git show --remerge-diff --format="%h %s" HEAD'

# ---- Failure scenario: "git add" as a reflex keeps the deleted script alive.
snip 06-failure
run 'git switch -q -c try/blind-add main^1'
run_rc 'git merge cleanup/remove-legacy'
run 'git add scripts/legacy_eval.sh'
run 'git merge --continue'
run 'git ls-files Makefile scripts'
run 'grep -n evalkit Makefile scripts/legacy_eval.sh'

snip 07-recovery
note 'This merge is treated as already shared, so the repair is a new commit.'
run 'git rm -q scripts/legacy_eval.sh'
quiet "printf 'eval:\n\tpython -m evalkit run --config config/eval.yaml --seed 7\n' > Makefile"
run 'git diff --stat'
run 'git commit -q -a -m "Remove the legacy script again and carry --seed 7 to the make target"'

snip 08-verification
note 'Two different histories, one identical tree:'
run 'git rev-parse main^{tree} try/blind-add^{tree}'
run 'git diff --stat main try/blind-add'
run 'git log --oneline --graph -3 try/blind-add'
run 'git switch -q main'

lab_end
