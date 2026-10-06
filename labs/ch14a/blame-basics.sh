#!/usr/bin/env bash
# Chapter 14A, section 14A.16: what git blame prints, how to limit it to lines or a function, how to
# blame an older revision, and what the output cannot tell you.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a blame-basics
fx_scorekit || exit 1
sk_ids

snip 01-file
run 'git blame scorekit/text.py'

snip 02-lines
run 'git blame -s -L 6,8 scorekit/text.py'
run 'git blame -s -L :normalize scorekit/text.py'
run "git blame --date=short -L '/^def load/,+3' scorekit/runner.py"

snip 03-porcelain
run 'git blame --line-porcelain -L 7,7 scorekit/text.py'

snip 04-older-revision
run 'git blame -s v0.1.0 -- scorekit/metrics.py'

snip 05-boundary
run 'git blame -s v0.1.0..main -- scorekit/config.py'

snip 06-not-shown
note 'The line that lowercased the text is gone. Blame annotates lines that exist; it has no row for it.'
run "git blame -s $ID_R1~1 -L 7,7 -- scorekit/text.py"
run 'git blame -s -L 7,7 scorekit/text.py'
lab_end
