#!/usr/bin/env bash
# Chapter 3, section 3.7: the bytes of a packfile and of its index.
# Uses the repository of Lab 16.2 after "git gc": header and trailer of the .pack file, then the
# .idx file decoded with git show-index.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 pack-anatomy
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-16-2-delta-history.sh" || exit 1
quiet 'git gc'

snip 01-pack-file
run 'ls .git/objects/pack'
note 'The first twelve bytes of the pack: signature, version, number of objects (0x19 is 25).'
run 'head -c 12 .git/objects/pack/pack-*.pack | xxd'
note 'The last twenty bytes: a checksum of everything before them. It is also the name of the file.'
run 'tail -c 20 .git/objects/pack/pack-*.pack | xxd -p'

snip 02-pack-index
note 'The index starts with a magic number and its own version:'
run 'head -c 8 .git/objects/pack/pack-*.idx | xxd'
note 'Its entries, decoded: offset in the pack, object ID, CRC32. They are sorted by object ID:'
run 'git show-index < .git/objects/pack/pack-*.idx | head -4'
note 'Sorted by offset instead, the same entries give the order of the objects inside the pack:'
run 'git show-index < .git/objects/pack/pack-*.idx | sort -n | head -4'
note 'The index ends with the checksum of its pack, then a checksum of itself:'
run 'tail -c 40 .git/objects/pack/pack-*.idx | xxd -p -c 20'

lab_end
