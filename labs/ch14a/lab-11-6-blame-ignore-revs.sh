#!/usr/bin/env bash
# Lab 11.6 replay: blame through a formatter commit. -w, then --ignore-rev, then a committed
# .git-blame-ignore-revs with blame.ignoreRevsFile. The failure scenario breaks git blame on every
# commit that does not contain the file; the recovery makes the setting optional.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a lab-11-6-blame-ignore-revs
fx_scorekit || exit 1
sk_ids

snip 01-plain
run 'git blame --date=short -L :main scorekit/runner.py'

snip 02-who-is-that
run "git show --stat --format='%h %an, %ad: %s' --date=short $ID_REFORMAT"

snip 03-w
run 'git blame --date=short -w -L :main scorekit/runner.py'

snip 04-ignore-rev
run "git blame --date=short --ignore-rev $ID_REFORMAT -L :main scorekit/runner.py"

snip 05-file
run "printf '# Formatter run: four-space indent, double quotes (Asha, 11 Sep 2026)\n' > .git-blame-ignore-revs"
run "git rev-parse $ID_REFORMAT >> .git-blame-ignore-revs"
run 'cat .git-blame-ignore-revs'
run 'git config set blame.ignoreRevsFile .git-blame-ignore-revs'
run 'git config set blame.markIgnoredLines true'

snip 06-blame-configured
run 'git blame --date=short -L :main scorekit/runner.py'

snip 07-commit
run 'git add .git-blame-ignore-revs'
run 'git commit -q -m "List the formatter commit for git blame"'
run 'git config list --local | grep blame'

snip 08-failure
note 'Next week: look at how a function read in the release. v0.2.0 was tagged before the file existed.'
run 'git switch --quiet --detach v0.2.0'
run_rc 'git blame -s -L 6,8 scorekit/text.py'
run 'ls -a | grep blame'

snip 09-failure-short-id
run 'git switch --quiet main'
note 'A second mistake, made by a teammate who adds another commit to the list by its short ID:'
run "git log -1 --format=%h -- docs >> .git-blame-ignore-revs"
run 'tail -n 2 .git-blame-ignore-revs'
run_rc 'git blame -s -L 6,8 scorekit/text.py'

snip 10-recovery
run 'git restore .git-blame-ignore-revs'
run "git config set blame.ignoreRevsFile ':(optional).git-blame-ignore-revs'"
run 'git blame -s -L 6,8 scorekit/text.py'
run 'git switch --quiet --detach v0.2.0'
run 'git blame -s -L 6,8 scorekit/text.py'
run 'git switch --quiet main'

snip 11-verification
run 'git blame -s -L 6,8 scorekit/text.py'
run 'git config get blame.ignoreRevsFile'
run 'git status --short --branch'
lab_end
