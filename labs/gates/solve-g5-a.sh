#!/usr/bin/env bash
# Gate 5, hands-on variant A (corpus-sync): the model diagnosis and repair as real transcripts
# for answer-keys/gate-5-internals.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g5-a
gate_load gate-5-internals/variant-a
as config
blob=$(cat .gate/blob)

snip 01-observe
run 'cd ravi'
run_rc 'git log --oneline'
run 'git status -sb 2>&1 | tail -2'
run 'ls .git/objects/pack'
run "git count-objects -v 2>&1 | grep -E '^(warning|count|in-pack|packs|garbage):'"

snip 02-pack-index
note 'A pack without its .idx: the objects are there and Git cannot find them. The index is derived data.'
run 'git index-pack .git/objects/pack/pack-*.pack'
run 'ls .git/objects/pack'
run 'git log --oneline'
run "git count-objects -v 2>&1 | grep -E '^(warning|count|in-pack|packs|garbage):'"

snip 03-lock
run_rc 'git add README.md'
note 'Before removing a lock: make sure no Git process is working in this repository (pgrep -fl git).'
run 'rm .git/index.lock'
run 'git status -sb'

snip 04-fsck
run_rc 'git fsck --no-dangling'
run 'git ls-files -s sync/manifest.py'

snip 05-rebuild-object
note 'The blob named by the index entry is an empty file. The content is in the working tree.'
run 'git hash-object sync/manifest.py'
run 'git hash-object -w sync/manifest.py'
run_rc 'git cat-file -t :sync/manifest.py'
note 'An object file that exists is not rewritten. Remove the empty file, then write the object.'
run "rm -f .git/objects/${blob:0:2}/${blob:2}"
run 'git hash-object -w sync/manifest.py'
run 'git cat-file -t :sync/manifest.py'
run_rc 'git fsck --no-dangling'

snip 06-shallow
run 'git rev-parse --is-shallow-repository'
run 'cat .git/shallow'
run 'git log --oneline'
run_rc 'git describe'
run 'git fetch --unshallow'
run 'git log --oneline'
run 'git describe'

snip 07-verify
run 'git status -sb'
run_rc 'git fsck --no-dangling'
run 'cd ..'
show_check
gate_done
