#!/usr/bin/env bash
# A binary file changed on both sides: no markers, the path stays unmerged. Chapter 8, section 8.11.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 conflict-binary

quiet 'ek_base'
# A stand-in for a small binary artifact (a PNG signature followed by a few bytes).
quiet 'mkdir reports && printf "\211PNG\r\n\032\n\000\000\000\001baseline" > reports/confusion.png'
quiet 'ek_commit "Add the confusion-matrix plot"'
quiet 'git switch -c feature/new-palette'
as asha
quiet 'printf "\211PNG\r\n\032\n\000\000\000\002colour-blind-safe" > reports/confusion.png'
quiet 'ek_commit "Regenerate the plot with a colour-blind-safe palette"'
as you
quiet 'git switch main'
quiet 'printf "\211PNG\r\n\032\n\000\000\000\003judge-v2-results" > reports/confusion.png'
quiet 'ek_commit "Regenerate the plot for judge-large-v2"'

snip 01-merge
run_rc 'git merge feature/new-palette'
run 'git status --short'
run 'git ls-files -u'
run 'git diff'

snip 02-which-version
note 'The working tree file is our version (stage 2), byte for byte:'
run 'git hash-object reports/confusion.png'

snip 03-resolve
note 'Decision: regenerate later; for now take their file.'
run 'git restore --theirs reports/confusion.png'
run 'git hash-object reports/confusion.png'
run 'git status --short'
run 'git add reports/confusion.png'
run 'git status --short'
run 'git merge --continue'

lab_end
