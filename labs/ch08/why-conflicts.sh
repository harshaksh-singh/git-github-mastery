#!/usr/bin/env bash
# Exactly when a three-way file merge conflicts, shown with git merge-file on three plain files.
# Chapter 8, section 8.7.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch08 why-conflicts

quiet 'printf "model: judge-large-v2\ntemperature: 0.2\nmax_tokens: 512\nbatch_size: 16\ntimeout_s: 30\n" > base.yaml'

snip 01-different-regions
run 'cat base.yaml'
run "sed 's/temperature: 0.2/temperature: 0.0/' base.yaml > ours.yaml"
run "sed 's/timeout_s: 30/timeout_s: 60/' base.yaml > theirs.yaml"
run_rc 'git merge-file -p ours.yaml base.yaml theirs.yaml'

snip 02-same-line
run "sed 's/temperature: 0.2/temperature: 0.7/' base.yaml > theirs.yaml"
run_rc 'git merge-file -p ours.yaml base.yaml theirs.yaml'

snip 03-same-change
run "sed 's/temperature: 0.2/temperature: 0.0/' base.yaml > theirs.yaml"
run_rc 'git merge-file -p ours.yaml base.yaml theirs.yaml'

snip 04-adjacent-lines
note 'ours changes line 2, theirs changes line 3: no unchanged line between them.'
run "sed 's/max_tokens: 512/max_tokens: 1024/' base.yaml > theirs.yaml"
run_rc 'git merge-file -p ours.yaml base.yaml theirs.yaml'

snip 05-one-line-apart
note 'ours changes line 2, theirs changes line 4: line 3 is unchanged on both sides.'
run "sed 's/batch_size: 16/batch_size: 32/' base.yaml > theirs.yaml"
run_rc 'git merge-file -p ours.yaml base.yaml theirs.yaml'

lab_end
