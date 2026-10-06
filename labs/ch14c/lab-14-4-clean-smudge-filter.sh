#!/usr/bin/env bash
# Lab 14.4 replay: a clean and smudge filter pair that keeps large files out of the repository
# and stores a pointer instead. Failure: a teammate's clone knows the attribute but not the
# driver, so she sees pointers and then commits real content. Recovery: renormalize, and
# configure the driver in her clone.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14c lab-14-4-clean-smudge-filter
fx_14_4

snip 01-scripts
run 'cd modelhub'
run 'cat tools/ptr-clean'
run 'cat tools/ptr-smudge'

snip 02-configure
run "printf 'weights/*.bin filter=ptr -text\n' > .gitattributes"
run 'git config set filter.ptr.clean tools/ptr-clean'
run "git config set filter.ptr.smudge 'tools/ptr-smudge %f'"
run 'git config set filter.ptr.required true'
run 'git check-attr filter text -- weights/encoder.bin'

snip 03-clean
run "printf 'layer0: 0.12 0.98 0.33\nlayer1: 0.44 0.10 0.71\n' > weights/encoder.bin"
run 'git add .'
run 'git ls-files -s weights/encoder.bin'
note 'The blob in the index is the pointer. The file on disk is untouched:'
run 'git cat-file -p :weights/encoder.bin'
run 'cat weights/encoder.bin'
run 'ls ../ptr-store'
run 'git commit -q -m "Add encoder weights" && git push -q'

snip 04-diff
run "printf 'layer0: 0.15 0.97 0.31\nlayer1: 0.44 0.10 0.71\n' > weights/encoder.bin"
run 'git diff'
run 'git commit -q -am "Retrain encoder" && git push -q'

snip 05-smudge
note 'Going back one commit runs the smudge filter, which fetches the old bytes from the store:'
run 'git switch -q --detach HEAD~1'
run 'cat weights/encoder.bin'
run 'git switch -q main'
run 'cat weights/encoder.bin'

snip 06-failure
as asha
note 'Asha clones. Her clone has the attribute and the scripts, but no filter.ptr.* configuration:'
run 'cd ..'
run 'git clone -q server.git modelhub-asha'
run 'cd modelhub-asha'
run 'git check-attr filter -- weights/encoder.bin'
run_rc 'git config get filter.ptr.clean'
run 'cat weights/encoder.bin'
note 'She retrains, writes real weights over the pointer, commits and pushes:'
run "printf 'layer0: 0.21 0.90 0.35\nlayer1: 0.40 0.12 0.70\n' > weights/encoder.bin"
run 'git commit -q -am "Retrain encoder on the new split" && git push -q'
run 'git cat-file -p HEAD:weights/encoder.bin'

snip 07-symptom
as you
run 'cd ../modelhub'
run 'git pull -q'
run 'git status -s'
run 'git diff'

snip 08-recovery-you
run 'git add --renormalize .'
run 'git status -s'
run 'git commit -q -m "Store the retrained encoder as a pointer again"'
run 'git push -q'
run 'git cat-file -p HEAD:weights/encoder.bin'
run 'git status -s'

snip 09-recovery-asha
as asha
run 'cd ../modelhub-asha'
run 'git config set filter.ptr.clean tools/ptr-clean'
run "git config set filter.ptr.smudge 'tools/ptr-smudge %f'"
run 'git config set filter.ptr.required true'
note 'With the driver defined, her real weights now count as a change against the raw blob in her index:'
run 'git status -s'
run_rc 'git pull -q'
note 'Renormalizing stages the pointer, which is exactly what the incoming commit holds:'
run 'git add --renormalize .'
run_rc 'git pull -q'
run 'git status -s'
run 'git cat-file -p HEAD:weights/encoder.bin'
run 'cat weights/encoder.bin'

snip 10-verification
as you
run 'cd ../modelhub'
run "git log --format='%h %s' -- weights/encoder.bin"
run 'for c in $(git rev-list HEAD -- weights/encoder.bin); do git cat-file -p $c:weights/encoder.bin | head -n 1; done'
run 'ls ../ptr-store'

lab_end
