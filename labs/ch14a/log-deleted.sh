#!/usr/bin/env bash
# Chapter 14A, section 14A.13: finding a file that no longer exists, reading why it went, and
# getting its last content back. Also: a file that exists only on another branch.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a log-deleted
fx_scorekit || exit 1
sk_ids

snip 01-deletions
run 'git log --diff-filter=D --name-status --format="%h %ad %an: %s" --date=short'

snip 02-path-history
run 'git log --oneline -- scorekit/bleu.py'
run "git log --oneline -- '*bleu*'"

snip 03-why
run "git show --stat $ID_DELETE"

snip 04-content
run "git show $ID_DELETE~1:scorekit/bleu.py"

snip 05-wrong-commit
run_rc "git show $ID_DELETE:scorekit/bleu.py"

snip 06-restore
run "git restore --source=$ID_DELETE~1 -- scorekit/bleu.py"
run 'git status --short'

snip 07-other-branch
run 'git log --oneline -- scorekit/report.py'
run 'git log --oneline --all -- scorekit/report.py'
run 'git branch --contains $(git log --all --format=%h -1 -- scorekit/report.py)'
lab_end
