#!/usr/bin/env bash
# Lab 16.1 replay: watch loose objects become a pack.
# Three commits to a tokenizer vocabulary, git gc, new loose objects beside the pack,
# then the failure scenario (a missing pack index) and its recovery with git index-pack.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 lab-16-1-loose-to-pack

snip 01-history
run 'git init tokenizer-vocab'
run 'cd tokenizer-vocab'
run "seq -f 'token_%04g' 1 400 > vocab.txt"
run 'git add vocab.txt'
run 'git commit --quiet -m "Add vocabulary of 400 tokens"'
run "echo 'token_0401' >> vocab.txt"
run 'git commit --quiet -am "Add token 401"'
run "echo 'token_0402' >> vocab.txt"
run 'git commit --quiet -am "Add token 402"'
run 'git log --oneline'

snip 02-loose
run 'git count-objects -v'
run 'find .git/objects -type f | sort'

snip 03-gc
run 'git gc'
run 'git count-objects -v'
run 'find .git/objects -type f | sort'
run 'cat .git/packed-refs'

snip 04-content-unchanged
note 'Every snapshot is still complete. The first version of the file has its 400 lines:'
run 'git cat-file -p HEAD~2:vocab.txt | wc -l'
run 'git cat-file -s HEAD~2:vocab.txt'
note 'Inside the pack, two of the three versions are stored as deltas:'
run 'git verify-pack -v .git/objects/pack/pack-*.idx | grep blob'

snip 05-loose-again
run "echo 'token_0403' >> vocab.txt"
run 'git commit --quiet -am "Add token 403"'
run 'git count-objects -v'
run 'git gc'
run 'git count-objects -v'

snip 06-failure
note 'Failure scenario: the pack index disappears.'
run 'mv .git/objects/pack/pack-*.idx ../saved.idx'
run_rc 'git status'
note 'The ref still resolves. The object it names cannot be found:'
run 'git rev-parse HEAD'
run_rc 'git cat-file -t HEAD'
run 'git count-objects -v'

snip 07-recovery
note 'The index of a pack is derived data. Rebuild it from the pack itself:'
run 'git index-pack .git/objects/pack/pack-*.pack'
run 'ls .git/objects/pack'
run 'cmp .git/objects/pack/pack-*.idx ../saved.idx && echo "identical to the index we removed"'
run_rc 'git status --short'

snip 08-verification
run_rc 'git fsck'
run 'git count-objects -v'
run 'git log --oneline'

lab_end
