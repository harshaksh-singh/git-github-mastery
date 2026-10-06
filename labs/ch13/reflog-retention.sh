#!/usr/bin/env bash
# Chapter 13, section 13.4: which reflog entries expire first, and the three exceptions.
# Expiry is shown only with clock-independent cut-offs ("now"); the lab configuration sets the
# time-based defaults to "never".
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 reflog-retention
fx_searchsvc
cd searchsvc || exit 1
quiet "git commit --amend -m 'Raise top_k from 5 to 10'"
quiet "printf 'debug: true\n' >> retriever.yaml && git commit -am 'Temporary debug flag'"
quiet 'git reset --hard HEAD~1'

snip 01-which-entries
run 'git reflog show main'
note 'Which entries does the 30-day rule apply to? Ask with a cut-off of "now" and --dry-run:'
run 'git reflog expire --dry-run --verbose --expire-unreachable=now refs/heads/main'
note 'It was a dry run. All six entries are still there:'
run 'git reflog show main | grep -c main@'

snip 02-after-expiry
run 'git reflog expire --expire-unreachable=now refs/heads/main'
run 'git reflog show main'
run 'git log --oneline -1 main'
run 'git reflog -3'

snip 03-delete-and-drop
note 'delete removes one entry, drop removes the whole log of a ref. Neither touches the ref.'
run "git reflog delete 'HEAD@{1}'"
run 'git reflog -3'
run 'git reflog drop refs/heads/main'
run_rc 'git reflog exists refs/heads/main'
run 'git log --oneline -1 main'

snip 04-stash
run "printf 'top_k: 20\n' > retriever.yaml"
run 'git stash push -q -m "try top_k 20"'
run "printf 'top_k: 50\n' > retriever.yaml"
run 'git stash push -q -m "try top_k 50"'
run 'git stash list'
run 'git reflog show refs/stash'

snip 05-stash-after-expire
run 'git reflog expire --expire=now --all'
run 'git stash list'
run 'git log --oneline -1 refs/stash'
run 'git fsck'

snip 06-stash-rescue
run 'git stash pop'
run 'git stash list'
run "git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'"

cd "$LAB_DIR" || exit 1
quiet 'git -C searchsvc restore retriever.yaml'
quiet 'git init --bare server.git'
quiet 'git -C searchsvc remote add origin ../server.git'

snip 07-bare
run 'git -C searchsvc push -q origin main'
run 'git -C server.git reflog list'
run_rc 'git -C server.git config get core.logAllRefUpdates'
run 'git -C searchsvc config get core.logAllRefUpdates'

snip 08-bare-with-reflog
note 'Whoever runs a bare repository can switch reflogs on:'
run 'git -C server.git config set core.logAllRefUpdates true'
run 'git -C searchsvc commit -q --amend -m "Raise top_k to ten"'
run 'git -C searchsvc push -q --force origin main'
run 'git -C server.git reflog show main'
run "git -C server.git log --oneline -1 'main@{1}'"

lab_end
