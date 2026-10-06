#!/usr/bin/env bash
# Chapter 14A, section 14A.18: where blame follows code and where it loses it: whole-file renames,
# code moved between files (-C), copies (-C -C), moves inside a file (-M), and squash merges.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a blame-moves
fx_scorekit || exit 1
sk_ids

snip 01-rename
run 'git blame -s -w scorekit/metrics.py'

snip 02-moved-between-files
note "$ID_MOVE moved normalize() from scorekit/metrics.py into the new file scorekit/text.py."
run "git blame -s $ID_MOVE -- scorekit/text.py"
run "git blame -s -C $ID_MOVE -- scorekit/text.py"

snip 03-threshold
note "Today only two short lines of that move are left unchanged. -C wants 40 alphanumeric characters."
run "git blame -s -C --ignore-rev $ID_REFORMAT -L 6,8 scorekit/text.py"
run "git blame -s -C5 --ignore-rev $ID_REFORMAT -L 6,8 scorekit/text.py"

snip 04-copy
run 'git blame -s -L 9,12 data/nightly.jsonl'
run 'git blame -s -C -L 9,12 data/nightly.jsonl'
run 'git blame -s -C -C -L 9,12 data/nightly.jsonl'

snip 05-squash
run 'git blame -L 15,18 scorekit/rouge.py'
run 'git blame -L 15,18 feat/rouge-l -- scorekit/rouge.py'

snip 06-squash-who
run "git log -1 --format='%h %an: %s%n%(trailers:key=Co-authored-by)' $ID_SQUASH"
run 'git branch --no-merged main'

snip 07-move-within-file
tick
cat > scorekit/text.py <<'PY'
import re

_PUNCTUATION = re.compile(r"[^\w\s]")


def tokens(text):
    return normalize(text).split()


def normalize(text):
    text = _PUNCTUATION.sub("", text)
    return " ".join(text.split())
PY
quiet 'git commit -am "Put tokens above normalize"'
note 'A new commit moves tokens() above normalize() and changes nothing else.'
run 'git blame -s scorekit/text.py'
run 'git blame -s -M scorekit/text.py'

snip 08-first-parent
run 'git blame -s --first-parent -L 10,12 scorekit/text.py'
lab_end
