#!/usr/bin/env bash
# Model solution of exercise 11.10 (Level 4): is the fix in the release? Set questions on a
# release branch, then a traceable backport and a new patch tag.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m11-vecindex
ex_load m11-vecindex
cd vecindex || exit 1

snip 01-observe
run 'git log --graph --oneline --all'
run 'git tag -l --format="%(refname:short) %(objecttype) %(*objectname:short) %(contents:subject)"'

snip 02-two-commits
run "git log --all --format='%h %an %s' --grep='Clamp top_k'"
fix=$(sid 'Clamp top_k to the index size' main)
part=$(sid 'Clamp top_k to the index size' release/2.3)
run "git branch -a --contains $fix"
run "git tag --contains $fix"
run "git tag --contains $part"

snip 03-cherry
run 'git cherry -v release/2.3 main'
run 'git log --oneline --cherry-mark --left-right release/2.3...main'

snip 04-compare
run "git show --format='%h %an: %s' --stat $part"
run "git show --format='%h %an: %s' --stat $fix"
run "git range-diff $fix^! $part^!"

snip 05-release-state
run 'git diff --stat v2.3.1 main -- vecindex/search.py'
run 'git diff release/2.3 main -- vecindex/search.py'

snip 06-backport
run "git tag answer/fix $fix"
run 'git switch release/2.3'
run 'git cherry-pick -x answer/fix'
run 'git show --stat --format="%h %s%n%n%b" HEAD'

snip 07-verify
run 'git diff --stat main release/2.3 -- vecindex/search.py'
run 'git cherry -v release/2.3 main'
run "git tag -a v2.3.2 -m 'vecindex 2.3.2: clamp top_k in search and in batch search'"
run 'git describe release/2.3'
run 'git log --oneline v2.3.0..v2.3.2'
run 'git switch main'
run 'cd ..'
show_check
ex_done
