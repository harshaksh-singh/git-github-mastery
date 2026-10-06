#!/usr/bin/env bash
# Chapter 14A, section 14A.23: git grep searches tracked content: the working tree, the index, or
# any revision, without checking it out.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a grep
fx_scorekit || exit 1

snip 01-basic
run 'git grep -n PASS_MARK'
run 'git grep -c tokens'
run 'git grep -l normalize -- scorekit'

snip 02-function
run 'git grep -n -p "overlap == 0"'
run 'git grep -W "set(pred)"'

snip 03-revision
run 'git grep -n "lower()" v0.1.0'
run_rc 'git grep -n "lower()" main'
run 'git grep -n -i bleu v0.2.0 -- docs'

snip 04-boolean
run "git grep -n -e 'def ' --and -e reference"
run "git grep -l -e normalize --and --not -e import"

snip 05-untracked
quiet "printf 'PASS_MARK = 0.5  # local experiment\n' > scratch.py"
run 'git grep -n "local experiment"'
run 'git grep -n --untracked "local experiment"'

snip 06-many-revisions
run "git grep -n 'PASS_MARK = ' v0.1.0 v0.2.0 main -- scorekit/config.py"
lab_end
