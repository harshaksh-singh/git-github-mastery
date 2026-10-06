#!/usr/bin/env bash
# A dirty submodule: what the superproject's status and diff report, why "commit -a" cannot record
# it, foreach, and how to get back to the recorded state. Chapter 23, section 23.9.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-dirty
fx_docqa_submodule
cd doc-qa

snip 01-dirty
quiet "printf '# debug: print every chunk\n' >> vendor/textsplit/splitter.py"
quiet "printf 'try size=300\n' > vendor/textsplit/notes.txt"
run 'git status'
run 'git submodule status'

snip 02-diff
run 'git diff'
run 'git diff --submodule=diff'

snip 03-commit-a
run_rc 'git commit -am "Save my work"'

snip 04-foreach
run 'git submodule foreach "git status --short"'
run 'git status --short'
run 'git status --short --ignore-submodules=untracked'
run 'git status --short --ignore-submodules=dirty'

snip 05-discard
note 'update does nothing: the checked-out commit already is the recorded one.'
run 'git submodule update'
run 'git status --short'
note '--force checks the files out again, which discards the edit to the tracked file:'
run 'git submodule update --force'
run 'git status --short'
run 'git -C vendor/textsplit clean -n'
run 'git -C vendor/textsplit clean -f'
run 'git status --short'
lab_end
