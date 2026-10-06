#!/usr/bin/env bash
# Lab 16.2 replay: read a pack listing and find a delta chain.
# The repository comes from setup-16-2-delta-history.sh, so the object IDs printed here are the
# ones the learner sees in the hands-on sandbox.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 lab-16-2-delta-chain
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-16-2-delta-history.sh" || exit 1

snip 01-pack
run 'git log --oneline'
run 'git gc'
run 'ls .git/objects/pack'

snip 02-listing
run 'git verify-pack -v .git/objects/pack/pack-*.idx'

snip 03-chain
note 'Deltified objects have seven columns. Print depth, object and base, shallowest first:'
run "git verify-pack -v .git/objects/pack/pack-*.idx | awk 'NF == 7 {print \$6, \$1, \$7}' | sort -n"
note 'The base of the whole chain is the one object that is stored whole:'
run "git verify-pack -v .git/objects/pack/pack-*.idx | grep a4e58256 | head -1"

snip 04-which-version
note 'Which version of the file is which object? Newest commit first:'
run "git log --format='%h %s' -- eval/cases.jsonl | while read commit subject; do echo \"\$(git rev-parse --short=8 \$commit:eval/cases.jsonl) \$commit \$subject\"; done"

snip 05-logical-size
note 'Size of the object as Git presents it, and size of what is stored for it:'
run "git log --format='%H:eval/cases.jsonl' | git cat-file --batch-check='%(objectname) %(objectsize) %(objectsize:disk) %(deltabase)'"
run 'git cat-file -p 0928d48c | wc -c'

snip 06-failure
note 'Failure scenario: one damaged byte inside the base object of the chain.'
run 'chmod u+w .git/objects/pack/pack-*.pack'
run "python3 -c \"import sys; f = open(sys.argv[1], 'r+b'); f.seek(1000); b = f.read(1); f.seek(1000); f.write(bytes([b[0] ^ 255])); f.close()\" .git/objects/pack/pack-*.pack"
run_rc 'git verify-pack .git/objects/pack/pack-*.idx'
note 'Every version of the file depends on that base, so every version is unreadable:'
run 'git cat-file -p 0928d48c > /dev/null'
run 'git fsck 2>&1 | grep -c "cannot unpack"'
note 'Commits and trees are other objects in the pack. They still read, and status notices nothing:'
run 'git log --oneline -2'
run_rc 'git status --short'

snip 07-recovery
note 'Never repair your only copy. Keep the damaged repository as it is, next to the one you work on:'
run 'cp -R .git ../eval-harness-damaged.git'
note 'The damaged object is the newest version of the file, and the working tree still holds those bytes:'
run 'git hash-object eval/cases.jsonl'
note 'Git does not write an object that it believes it has. Nothing loose appears:'
run 'git hash-object -w eval/cases.jsonl'
run 'git count-objects'
note 'So take the pack out of the object database, write the object, and put the pack back:'
run 'mkdir ../quarantine'
run 'mv .git/objects/pack/pack-* ../quarantine/'
run 'git hash-object -w eval/cases.jsonl'
run 'git count-objects'
run 'mv ../quarantine/pack-* .git/objects/pack/'
note 'Reads now fall back to the loose copy of the base, with a complaint about the packed one:'
run 'git cat-file -p 0928d48c | wc -l'
note 'Now let maintenance rewrite the pack from what is readable:'
run_rc 'git gc'

snip 08-verification
run_rc 'git verify-pack .git/objects/pack/pack-*.idx'
run_rc 'git fsck'
run 'git count-objects -v'
run 'ls .git/objects/pack'
run 'git cat-file -p 0928d48c | wc -l'

lab_end
