#!/usr/bin/env bash
# Chapter 14A, section 14A.7: the ways to name one commit, tree or blob (gitrevisions), each resolved
# for real. A bare repository stands in for the server so that @{u} has something to name.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a revisions
fx_scorekit || exit 1
sk_ids
quiet 'git clone --bare . ../origin.git && git remote add origin ../origin.git && git fetch origin && git branch --set-upstream-to=origin/main main'
quiet "git commit --allow-empty -m 'Start the 0.3 cycle'"

snip 01-ancestors
run "git show -s --format='%h %s' HEAD HEAD~1 HEAD~2 HEAD^"

snip 01b-merge-parents
note "$ID_MERGE is the merge of feat/text-utils. ^1 and ^2 choose a parent; ~1 always follows the first parent."
run "git rev-parse $ID_MERGE^1 $ID_MERGE~1 $ID_MERGE^2 $ID_MERGE^2~1"
run "git show -s --format='%h %s' $ID_MERGE^1 $ID_MERGE^2 $ID_MERGE^2~1"

snip 02-reflog
run "git show -s --format='%h %s' 'HEAD@{1}' 'main@{2}'"
run "git show -s --format='%h %cd %s' --date=format:'%a %H:%M' 'main@{yesterday}'"

snip 03-upstream
run 'git rev-parse --abbrev-ref @{u}'
run "git show -s --format='%h %s' @{u}"
run 'git log --oneline @{u}..'

snip 04-search
run "git show -s --format='%h %s' ':/Reformat sources'"
run "git show -s --format='%h %s' 'v0.2.0^{/pass mark}'"
run "git show -s --format='%h %s' ':/nightly run'"

snip 05-peel
run 'git cat-file -t v0.1.0'
run 'git rev-parse v0.1.0 v0.1.0^{} v0.1.0^{commit} v0.1.0^{tree}'
run 'git rev-parse v0.1.0^0'

snip 06-paths
run 'git rev-parse main:scorekit/config.py v0.1.0:scorekit/config.py :scorekit/config.py'
run 'git show v0.1.0:scorekit/config.py'
run 'git cat-file -t main:scorekit'

snip 07-not-a-commit
run_rc 'git rev-parse --verify --quiet v0.1.0:run_eval.py'
run_rc 'git log --oneline -1 v0.3.0'
lab_end
