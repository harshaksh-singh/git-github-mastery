#!/usr/bin/env bash
# Lab 11.3 replay: a file that existed last week is gone. Find the commit that deleted it and the
# reason, read its last content, and bring it back on an experiment branch. The failure scenario asks
# the deleting commit for the file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a lab-11-3-deleted-file
fx_scorekit || exit 1

snip 01-gone
run_rc 'git ls-files | grep -i bleu'
run 'git grep -n -i bleu'

snip 02-deletions
run "git log --diff-filter=D --name-status --format='%h %ad %an: %s' --date=short"

snip 03-path-history
run "git log --format='%h %ad %<(10)%an %s' --date=short -- '*bleu*'"

snip 04-why
deleted=$(git log --diff-filter=D --format=%h -1 -- scorekit/bleu.py)
run "git show --stat $deleted"

snip 05-last-content
run "git show $deleted~1:scorekit/bleu.py"

snip 06-restore
run 'git switch --quiet -c experiment/bleu'
run "git restore --source=$deleted~1 -- scorekit/bleu.py"
run 'git status --short'
run "python3 -B -c 'from scorekit.bleu import bleu1; print(round(bleu1(\"the cat\", \"the cat sat\"), 3))'"

snip 07-commit
run "git add scorekit/bleu.py && git commit -q -m 'Bring back the BLEU scorer for the brevity experiment'"
run 'git log --oneline -3 -- scorekit/bleu.py'

snip 08-failure
note 'On another machine a colleague tries the same with the ID of the deleting commit itself:'
run 'git switch --quiet main'
run_rc "git restore --source=$deleted -- scorekit/bleu.py"
run_rc "git show $deleted:scorekit/bleu.py"

snip 09-failure-no-dashes
run_rc 'git log --oneline scorekit/bleu.py'

snip 10-recovery
run 'git log --oneline -1 -- scorekit/bleu.py'
run "git cat-file -e $deleted~1:scorekit/bleu.py && echo 'the parent has the file'"
run "git restore --source=$deleted~1 -- scorekit/bleu.py"
run 'git status --short'

snip 11-verification
run 'git hash-object scorekit/bleu.py'
run "git rev-parse $deleted~1:scorekit/bleu.py experiment/bleu:scorekit/bleu.py"
run 'rm scorekit/bleu.py && git status --short --branch'
lab_end
