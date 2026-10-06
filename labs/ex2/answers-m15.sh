#!/usr/bin/env bash
# Model answers for exercises 15.1 to 15.8 (Module 15: submodules, subtrees, Git LFS) as real
# transcripts on the practice repositories built by exercises/gen/m15-evalboard-practice/generate.sh.
# Git LFS is installed with --local inside sandbox repositories only.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 answers-m15
ex_load m15-evalboard-practice

cd ex-15-1/evalboard || exit 1
snip 15-1-add
run_rc 'git submodule add ../metrickit.git vendor/metrickit'
run 'git -c protocol.file.allow=always submodule add ../metrickit.git vendor/metrickit'
run 'git status -s'
run 'cat .gitmodules'
snip 15-1-inspect
run "git commit -q -m 'Add metrickit as a submodule'"
run 'git ls-tree HEAD vendor/'
run 'git submodule status'
run 'cat vendor/metrickit/.git'
run 'git -C vendor/metrickit log --oneline -1'
cd "$LAB_DIR" || exit 1

cd ex-15-2/evalboard || exit 1
snip 15-2-track
run 'wc -c weights/encoder.bin'
run 'git lfs install --local'
run 'git lfs track "*.bin"'
run 'cat .gitattributes'
run "git add .gitattributes weights && git commit -q -m 'Add encoder weights with Git LFS'"
snip 15-2-pointer
run 'git cat-file -p HEAD:weights/encoder.bin'
run 'git cat-file -s HEAD:weights/encoder.bin'
run 'wc -c weights/encoder.bin'
run 'git lfs ls-files'
run 'find .git/lfs/objects -type f'
cd "$LAB_DIR" || exit 1

cd ex-15-3/evalboard || exit 1
snip 15-3-subtree
run 'git subtree add --prefix=vendor/metrickit ../remotes/metrickit.git main --squash'
run 'git log --graph --oneline'
run 'git ls-tree HEAD vendor/'
run 'ls -A vendor/metrickit'
snip 15-3-message
run 'git log -1 --format=%B HEAD^2'
cd "$LAB_DIR" || exit 1

cd ex-15-4/fresh || exit 1
snip 15-4-status
run 'git submodule status'
run 'ls -A vendor/metrickit | wc -l'
run 'git -c protocol.file.allow=always submodule update --init'
run 'git submodule status'
run 'git -C vendor/metrickit status -sb'
snip 15-4-moved
run 'git -C vendor/metrickit checkout -q v0.1.0'
run 'git submodule status'
run 'git status -s'
run 'git diff --submodule=log'
cd "$LAB_DIR" || exit 1

cd ex-15-5/evalboard || exit 1
snip 15-5-commands
run 'git subtree add -q --prefix=vendor/metrickit ../remotes/metrickit.git v0.1.0 --squash'
run "echo '# sorted by name' >> board.py && git commit -q -am 'Sort runs by name'"
run 'git subtree pull -q --prefix=vendor/metrickit ../remotes/metrickit.git v0.2.0 --squash'
snip 15-5-graph
run 'git log --graph --oneline'
cd "$LAB_DIR" || exit 1

cd ex-15-6/evalboard || exit 1
snip 15-6-late
run 'git lfs install --local'
run 'git lfs track "*.bin"'
run "git add .gitattributes && git commit -q -m 'Track weights with Git LFS'"
run 'git lfs ls-files'
run 'git cat-file -s HEAD:weights/encoder.bin'
run 'git status -s'
snip 15-6-renormalize
run 'git add --renormalize .'
run 'git status -s'
run "git commit -q -m 'Convert the encoder weights to an LFS pointer'"
run 'git lfs ls-files'
run 'git cat-file -s HEAD:weights/encoder.bin'
run 'git cat-file -s HEAD~2:weights/encoder.bin'
cd "$LAB_DIR" || exit 1

cd ex-15-7/ci || exit 1
snip 15-7-symptom
run "python3 -B -c 'import board' 2>&1 | tail -1"
run 'ls -A vendor/metrickit | wc -l'
run 'git submodule status'
run 'git ls-tree HEAD vendor/'
snip 15-7-fix
run_rc 'git submodule update --init'
run 'git -c protocol.file.allow=always submodule update --init'
run 'git submodule status'
run "python3 -B -c 'import board; print(\"import ok\")'"
cd "$LAB_DIR" || exit 1

cd ex-15-8/newclone || exit 1
snip 15-8-symptom
run "python3 -B -c 'import load; load.load()' 2>&1 | tail -1"
run 'wc -c weights/encoder.bin'
run 'cat weights/encoder.bin'
run 'git status -sb'
snip 15-8-diagnose
run 'git lfs ls-files'
run_rc 'git config get filter.lfs.smudge'
run 'cat .gitattributes'
snip 15-8-fix
run 'git lfs install --local'
run 'git lfs pull'
run 'wc -c weights/encoder.bin'
run 'git lfs ls-files'
run 'git status -sb'
lab_end
