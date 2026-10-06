#!/usr/bin/env bash
# Chapter 24, section 24.4: cone-mode sparse-checkout. init --cone, set, add, list, disable, and
# what each of them changes inside .git.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch24 sparse-cone
. "$LAB_SCRIPT_DIR/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1
quiet 'git clone "file://$PWD/server/orbit.git" dev'
cd dev || exit 1

snip 01-full
run 'ls'
run 'git ls-files | wc -l'
run 'git ls-files | cut -d/ -f1-2 | sort | uniq -c'

snip 02-init
run 'git sparse-checkout init --cone'
run 'ls -A'
run 'git status'
run_rc 'git sparse-checkout list'

snip 03-inside
note 'The definition is a file of patterns, and the switches live in a per-worktree config file:'
run 'cat .git/info/sparse-checkout'
run 'cat .git/config.worktree'
run 'git config get extensions.worktreeConfig'

snip 04-set
run 'git sparse-checkout set services/ranker libs/tokenizer'
run 'git sparse-checkout list'
run "find . -path ./.git -prune -o -type f -print | sort"
run 'git status | sed -n 4p'

snip 05-patterns
run 'cat .git/info/sparse-checkout'
note 'Every tracked file is still in the index. Those outside the cone carry the skip-worktree bit (S):'
run 'git ls-files | wc -l'
run 'git ls-files -t | cut -c1 | sort | uniq -c'
run 'git ls-files -t services'

snip 06-add
run 'git sparse-checkout add docs/runbooks'
run 'git sparse-checkout list'
note 'The parent directory arrives with its own files, but not with its other subdirectories:'
run 'ls docs docs/runbooks'
run 'git status | sed -n 4p'

snip 07-disable
run 'git sparse-checkout disable'
run 'ls'
run 'git ls-files -t | cut -c1 | sort | uniq -c'
run 'git status | sed -n 1,4p'
note 'The switch is off. The old definition stays on disk, unused:'
run 'cat .git/config.worktree'
run 'wc -l < .git/info/sparse-checkout'

lab_end
