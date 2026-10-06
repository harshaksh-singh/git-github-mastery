#!/usr/bin/env bash
# Chapter 9, section 9.17: what a plain "git push --force" destroys. Asha's pushed commit disappears
# from the server, the bare server repository has no reflog to bring it back, and Asha's next
# "git pull --rebase" removes it from her own branch as well.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 force-damage
fx_shared_branch asha-pushed

snip 01-server-before
run 'git -C ../server.git log --oneline feat/ingest'

snip 02-force
run 'git rebase main'
run 'git push --force'

snip 03-server-after
run 'git -C ../server.git log --oneline feat/ingest'
run 'git -C ../server.git reflog show feat/ingest'

snip 04-asha-pulls
run 'cd ../asha'
run 'git log --oneline --decorate -1'
run 'git pull --rebase'
run 'git log --oneline --graph --decorate'

snip 05-why
run 'git reflog show origin/feat/ingest'
run 'git merge-base --fork-point origin/feat/ingest feat/ingest@{1}'

snip 06-asha-recovers
run 'git reflog show feat/ingest -2'
run 'git cherry-pick feat/ingest@{1}'
run 'git push'
run 'git log --oneline --graph --decorate'
lab_end
