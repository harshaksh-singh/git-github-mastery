#!/usr/bin/env bash
# Chapter 14A, section 14A.17: a formatter commit owns most lines of a file. -w sees through
# indentation, --ignore-rev through the whole commit, and an ignore-revs file makes that permanent.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a blame-reformat
fx_scorekit || exit 1
sk_ids

snip 01-plain
run "git blame --date=short -L '/^def load/,+7' scorekit/runner.py"

snip 02-w
run "git blame --date=short -w -L '/^def load/,+7' scorekit/runner.py"

snip 03-ignore-rev
run "git blame --date=short --ignore-rev $ID_REFORMAT -L '/^def load/,+7' scorekit/runner.py"

snip 04-file
quiet "{ printf '# Formatter run: four-space indent, double quotes\n'; git rev-parse $ID_REFORMAT; } > .git-blame-ignore-revs"
run 'cat .git-blame-ignore-revs'
run 'git blame -s --ignore-revs-file .git-blame-ignore-revs scorekit/text.py'

snip 05-config
run 'git config set blame.ignoreRevsFile .git-blame-ignore-revs'
run 'git config set blame.markIgnoredLines true'
run 'git blame -s scorekit/text.py'

snip 06-short-id
quiet "printf '%s\n' $ID_REFORMAT > ../short-ids.txt"
run 'cat ../short-ids.txt'
run_rc 'git blame -s --ignore-revs-file ../short-ids.txt -L 6,8 scorekit/text.py'

snip 07-missing-file
quiet 'git add .git-blame-ignore-revs && git commit -m "List the formatter commit for git blame"'
note 'The list is committed on main. An older commit does not have the file:'
run 'git switch --detach --quiet v0.2.0'
run_rc 'git blame -s -L 6,8 scorekit/text.py'
run_rc 'git blame -s --ignore-revs-file "" -L 6,8 scorekit/text.py'

snip 08-optional
run "git config set blame.ignoreRevsFile ':(optional).git-blame-ignore-revs'"
run 'git blame -s -L 6,8 scorekit/text.py'
run 'git switch --quiet main'
run 'git blame -s -L 6,8 scorekit/text.py'
lab_end
