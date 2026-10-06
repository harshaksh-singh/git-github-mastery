#!/usr/bin/env bash
# Chapter 14A, section 14A.5: reading a diff that is mostly noise. -w hides whitespace-only changes
# in the reformatting commit; --word-diff shows a prose edit word by word.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a diff-words-whitespace
fx_scorekit || exit 1
sk_ids

snip 01-reformat-stat
run "git show --stat --format='%h %an: %s' $ID_REFORMAT"
run "git show --stat --format='%h %an: %s' -w $ID_REFORMAT"

snip 02-reformat-w
run "git show --format='%h %s' -w $ID_REFORMAT -- scorekit/text.py"

snip 03-line-diff
quiet "sed -e 's/harmonic mean of token precision and recall/harmonic mean of token-level precision and recall/' -e 's/Normalization lowercases the text, strips/Normalization strips/' docs/metrics.md > docs/metrics.md.new && mv docs/metrics.md.new docs/metrics.md"
run 'git diff -- docs/metrics.md'

snip 04-word-diff
run 'git diff --word-diff -- docs/metrics.md'
lab_end
