#!/usr/bin/env bash
# Exercise 22.5 (Module 22), model solution: a release whose tag was created by the platform,
# on a commit that does not contain the fix the release notes promise. The hands-on twin is
# setup-x22-5-release-drift.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x22-release-drift
scenario_x22_release

snip 01-evidence
run 'git fetch'
run 'git for-each-ref --format="%(refname:short) %(objecttype) %(*objecttype)" refs/tags'
run 'git log --oneline --decorate -5 origin/main'

snip 02-what-the-tag-names
run 'git cat-file -t v0.8.0'
run 'git cat-file -t v0.9.0'
run 'git log --oneline v0.9.0..origin/main'
FIX=$(git log --format=%h --grep='Reject an overlap' origin/main)
run "git tag --contains $FIX"
run_rc 'git grep -n "overlap must be smaller" v0.9.0 -- chunker/split.py'

snip 03-describe
run 'git describe origin/main'
run 'git describe --tags origin/main'
run 'git describe v0.9.0'

snip 04-correct
note 'A published tag does not move. A new annotated tag names the commit that has the fix.'
run "git tag -a v0.9.1 -m 'chunker 0.9.1: reject an overlap that is not smaller than the size' $FIX"
run 'git push origin v0.9.1'
run 'git ls-remote --tags origin'
run "git describe $FIX"
run 'git describe origin/main'

lab_end
