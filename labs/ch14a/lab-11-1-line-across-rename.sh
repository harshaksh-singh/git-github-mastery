#!/usr/bin/env bash
# Lab 11.1 replay: trace one line of scorekit/runner.py back to the commit that wrote it, through a
# reformatting commit and a rename. The failure scenario renames and rewrites a file in one commit
# and loses the trail; the recovery splits that commit in two.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a lab-11-1-line-across-rename
fx_scorekit || exit 1
sk_ids
sk_cli_rewrite ../cli-rewrite.py

snip 01-blame
run "git blame -s -L '/em = sum/,+1' scorekit/runner.py"
run "git blame -s -w -L '/em = sum/,+1' scorekit/runner.py"

snip 02-ignore-rev
run "git show -s --format='%h %an: %s' $ID_REFORMAT"
run "git blame -s --ignore-rev $ID_REFORMAT -L '/em = sum/,+1' scorekit/runner.py"

snip 03-log-path
run 'git log --oneline -- scorekit/runner.py'

snip 04-log-follow
run 'git log --oneline --follow -- scorekit/runner.py'

snip 05-the-rename
run "git log --follow --diff-filter=AR --name-status --format='%h %an: %s' -- scorekit/runner.py"

snip 06-line-history
run "git log -s --format='%h %ad %an: %s' --date=short -L '/em = sum/,+1:scorekit/runner.py'"

snip 07-failure
note 'A refactoring on a new branch: the module gets a new name and most of a new body, in ONE commit.'
run 'git switch --quiet -c refactor/cli'
run 'git mv scorekit/runner.py scorekit/cli.py'
run 'cp ../cli-rewrite.py scorekit/cli.py'
run 'git add -A && git commit -q -m "Rewrite the runner as scorekit.cli"'
run 'git show --stat --format="%h %s" HEAD'

snip 08-trail-lost
run 'git log --oneline --follow -- scorekit/cli.py'
run "git blame -s -L '/^def load/,+3' scorekit/cli.py"
run 'git show --name-status --format="%h %s" -M30% HEAD'

snip 09-recovery
note 'Same end result, two commits: first the rename alone, then the rewrite.'
run 'git switch --quiet -c refactor/cli-split refactor/cli~1'
run 'git mv scorekit/runner.py scorekit/cli.py'
run 'git commit -q -m "Rename the runner module to cli"'
run 'git restore --source=refactor/cli -- scorekit/cli.py'
run 'git commit -q -am "Rewrite the command-line entry point with argparse"'

snip 10-verification
run 'git diff --stat refactor/cli refactor/cli-split'
run 'git log --oneline --follow -- scorekit/cli.py'

snip 11-verification-blame
run "git blame -s -L '/^def load/,+3' scorekit/cli.py"
run 'git branch -D refactor/cli'
lab_end
