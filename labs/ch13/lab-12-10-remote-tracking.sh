#!/usr/bin/env bash
# Lab 12.10 replay: remote-tracking refs that cannot be trusted (one written by hand, one an
# empty file after a crash). The server is asked directly, the broken ref is removed, and a
# fetch rebuilds the truth. Failure: the index file is corrupted. Recovery: move it away and
# let "git reset" rebuild it from HEAD; the working tree is not touched.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-10-remote-tracking
fx_12_10

snip 01-symptom
run 'cd docsearch'
run 'git status -sb'
run_rc 'git push'

snip 02-ask-the-server
run 'git ls-remote origin'
run "git for-each-ref --format='%(objectname) %(refname)' refs/remotes/origin"

snip 03-fetch-fails
run_rc 'git fetch'
run_rc 'git fsck'

snip 04-evidence
run 'wc -c < .git/refs/remotes/origin/feature/hybrid-search'
run 'git reflog show origin/main'
run "git log -g --date=iso --format='%gd | %gn | %gs' origin/main"

snip 05-repair
run_rc 'git update-ref -d refs/remotes/origin/feature/hybrid-search'
run 'rm .git/refs/remotes/origin/feature/hybrid-search'
run 'git fetch'
run 'git status -sb'

snip 06-verification
run 'git ls-remote origin'
run "git for-each-ref --format='%(objectname) %(refname)' refs/remotes/origin"
run 'git fsck'
run 'git log --oneline --graph main origin/main'

snip 07-failure
run "printf 'def parse(q):\n    return PHRASE.findall(q.lower().strip())\n' > query.py"
run 'git add query.py'
run "printf 'def cached(q):\n    return CACHE.get(q.strip())\n' > cache.py"
run 'git status -s'
note 'Simulate a damaged index file: overwrite its first four bytes.'
run "printf 'XXXX' | dd of=.git/index bs=1 conv=notrunc 2>/dev/null"
run_rc 'git status'
run_rc 'git log --oneline -1'

snip 08-recovery
run 'mv .git/index .git/index.corrupt'
run 'git status -s'
run 'git reset'
run 'git status -s'

snip 09-after
run 'cat query.py'
run 'git fsck'
run 'git add query.py'
run 'git status -s'
run 'rm .git/index.corrupt'

lab_end
