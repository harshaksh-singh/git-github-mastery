#!/usr/bin/env bash
# Chapter 3, section 3.7: packfiles, pack indexes and delta compression.
# Uses the repository of Lab 16.2: six versions of a 200-line file.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 packfiles
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-16-2-delta-history.sh" || exit 1

snip 01-loose
run 'git log --oneline'
run 'wc -l eval/cases.jsonl'
run 'git count-objects -v'

snip 02-gc
run 'git gc'
run 'git count-objects -v'
run 'find .git/objects -type f | sort'

snip 03-verify-pack
run 'git verify-pack -v .git/objects/pack/pack-*.idx'

snip 04-snapshots-intact
note 'Logical size, size on disk, and delta base of each version of the file, newest first:'
run "git log --format='%H:eval/cases.jsonl' | git cat-file --batch-check='%(objectname) %(objectsize) %(objectsize:disk) %(deltabase)'"
note 'The oldest version sits at the end of a five-step chain and still reads back whole:'
run 'git cat-file -p 0928d48c | wc -l'
run 'git cat-file -p 0928d48c | sed -n 30p'
run 'git cat-file -p HEAD:eval/cases.jsonl | sed -n 30p'

snip 05-loose-again
run "printf 'threshold = 0.85\\n' > eval/config.toml"
run 'git commit -q -am "Raise pass threshold"'
run 'git count-objects -v'

lab_end
