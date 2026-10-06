#!/usr/bin/env bash
# labs/ch14a/fixtures/scorekit.sh
# The prepared history for Chapter 14A (History investigation), the Module 11 labs and their hands-on
# setup scripts. Source it after lab-env.sh:
#     . "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
# It lives in a subdirectory because tools/build-demos.sh and labs/verify-all.sh run only the scripts
# directly inside labs/ch14a/.
#
# The project is "scorekit", a small library that scores model answers against reference answers and
# has a runner for a smoke set and a nightly set:
#     python3 -B -m scorekit.runner data/smoke.jsonl
#
# fx_scorekit builds the repository in the current directory (the sandbox) and leaves you inside it,
# on main. Replays and hands-on setups call it the same way, so every commit has the same ID everywhere.
#
# The history spans nine days. First-parent history of main, oldest first:
#
#   Mon 7 Sep   1 you    Add project skeleton
#               2 you    Add exact-match scorer                       scorer.py
#               3 asha   Add token-level F1 scorer
#               4 you    Add evaluation runner and smoke set          run_eval.py, data/smoke.jsonl
#               5 ravi   Add experimental BLEU scorer                 bleu.py
#   Tue 8 Sep   6 you    Move sources into the scorekit package       three renames
#               7 asha   Rename the scorer module to metrics          scorekit/scorer.py -> scorekit/metrics.py
#               8 you    Add config module with the pass mark         tag v0.1.0 (annotated)
#   Wed 9 Sep   9 ravi   Strip punctuation before comparing
#                          feat/text-utils (asha):  t1 Move normalize into scorekit/text.py
#                                                   t2 Add a tokens helper and use it in the metrics
#              10 you    Skip rows with an empty reference
#              11 you    Document the metrics
#              12 you    Raise the pass mark to 0.75
#              13 you    Merge branch 'feat/text-utils'               (--no-ff; the branch is deleted)
#   Thu 10 Sep 14 you    Document the runner's exit status
#              15 you    Add --limit option to the runner             the runner now crashes without --limit
#              16 ravi   Send warnings to stderr                      (still crashing)
#              17 you    Fix crash when --limit is not given
#              18 ravi   Speed up normalize with a precompiled pattern    REGRESSION 1: lowercasing is lost
#   Fri 11 Sep 19 asha   Reformat sources: four-space indent, double quotes
#              20 you    Add ROUGE-L metric                           squash of feat/rouge-l (asha, asha, ravi)
#              21 asha   Add nightly evaluation set                   tag v0.2.0 (annotated)
#   Mon 14 Sep 22 asha   Simplify token overlap in token_f1           REGRESSION 2: repeated tokens count once
#              23 ravi   Remove the experimental BLEU scorer          deletes scorekit/bleu.py
#              24 asha   Fail fast on an empty reference
#   Tue 15 Sep            feat/report (ravi): r1 Add per-row report writer
#                                             r2 Mention the nightly run in the README
#                                             r3 Write a report when --report <path> is given
#              25 you    Add a separate pass mark for the nightly set
#              26 you    Mention the nightly run in the README        cherry-pick of r2 (author ravi)
#
# Smoke-set scores along main: exact_match is 0.700 up to v0.1.0, 0.800 from commit 9, and 0.400 from
# commit 18 on. Commits 15 and 16 cannot be scored: the runner stops with KeyError: '--limit'.
#
# Branches left behind: main, feat/rouge-l (squash-merged, so not an ancestor of main), feat/report
# (diverged from main, not merged). Tags: v0.1.0, v0.2.0.

sk_put() { mkdir -p "$(dirname "$1")" && cat > "$1"; }

# sk_commit <subject> [<body>]: stage everything and commit, one minute after the previous step.
sk_commit() {
  tick
  git add -A > /dev/null 2>&1 || return 1
  if [ -n "${2:-}" ]; then
    git commit -q -m "$1" -m "$2" > /dev/null 2>&1
  else
    git commit -q -m "$1" > /dev/null 2>&1
  fi
}

# sk_clock <day> <minutes>: set the lab clock to <day> days and <minutes> minutes after its start
# (Monday 7 September 2026, 10:00 +05:30). The next commit is made one minute later. Days must only
# go forward. The whole history stays in the past, as the header of labs/lib/lab-env.sh requires.
sk_clock() { _lab_clock=$((LAB_EPOCH_BASE + $1 * 86400 + $2 * 60)); }

# sk_sed <sed program> <file>: edit a file in place, portably.
sk_sed() { sed -e "$1" "$2" > "$2.sk-new" && mv "$2.sk-new" "$2"; }

# sk_reformat <file>: what a formatter does. Doubles the indentation and turns single quotes into double quotes.
sk_reformat() {
  awk '{ match($0, /^ */); printf "%*s%s\n", RLENGTH * 2, "", substr($0, RLENGTH + 1) }' "$1" |
    sed -e "s/'/\"/g" > "$1.sk-new" && mv "$1.sk-new" "$1"
}

sk_handson_ready() {
  printf 'Lab sandbox ready: %s\n' "$LAB_DIR"
  printf 'Open the lab shell there and enter the repository:\n'
  printf '    labs/shell %s\n' "$LAB_DEMO"
  printf '    cd %s\n' "$1"
  return 0
}

# ---------------------------------------------------------------- file versions
_sk_smoke() {
  sk_put data/smoke.jsonl <<'EOF'
{"id": 1, "prediction": "Paris", "reference": "paris"}
{"id": 2, "prediction": "4", "reference": "4"}
{"id": 3, "prediction": "The Pacific Ocean.", "reference": "the pacific ocean"}
{"id": 4, "prediction": "blue  whale", "reference": "blue whale"}
{"id": 5, "prediction": "Mount Everest", "reference": "mount everest"}
{"id": 6, "prediction": "1969", "reference": "1969"}
{"id": 7, "prediction": "new york new york", "reference": "new york new york city"}
{"id": 8, "prediction": "H2O", "reference": "h2o"}
{"id": 9, "prediction": "seven", "reference": "7"}
{"id": 10, "prediction": "oxygen", "reference": "oxygen"}
EOF
}

_sk_runner_first() {       # run_eval.py as first written (commit 4)
  sk_put run_eval.py <<'EOF'
import json
import sys

from scorer import exact_match, token_f1

PASS_MARK = 0.7


def main(path):
  rows = [json.loads(line) for line in open(path)]
  em = sum(exact_match(r['prediction'], r['reference']) for r in rows) / len(rows)
  f1 = sum(token_f1(r['prediction'], r['reference']) for r in rows) / len(rows)
  print('rows=%d exact_match=%.3f token_f1=%.3f' % (len(rows), em, f1))
  return 0 if em >= PASS_MARK else 1


if __name__ == '__main__':
  sys.exit(main(sys.argv[1]))
EOF
}

_sk_runner_load() {        # scorekit/runner.py with the load() function (commit 10)
  sk_put scorekit/runner.py <<'EOF'
import json
import sys

from scorekit.config import PASS_MARK
from scorekit.metrics import exact_match, token_f1


def load(path):
  rows = []
  for line in open(path):
    row = json.loads(line)
    if not row['reference'].strip():
      print('skipped empty reference')
      continue
    rows.append(row)
  return rows


def main(path):
  rows = load(path)
  em = sum(exact_match(r['prediction'], r['reference']) for r in rows) / len(rows)
  f1 = sum(token_f1(r['prediction'], r['reference']) for r in rows) / len(rows)
  print('rows=%d exact_match=%.3f token_f1=%.3f' % (len(rows), em, f1))
  return 0 if em >= PASS_MARK else 1


if __name__ == '__main__':
  sys.exit(main(sys.argv[1]))
EOF
}

_sk_runner_limit() {       # scorekit/runner.py with a --limit option that is mandatory by mistake (commit 15)
  sk_put scorekit/runner.py <<'EOF'
import json
import sys

from scorekit.config import PASS_MARK
from scorekit.metrics import exact_match, token_f1


def load(path):
  rows = []
  for line in open(path):
    row = json.loads(line)
    if not row['reference'].strip():
      print('skipped empty reference')
      continue
    rows.append(row)
  return rows


def main(argv):
  path = argv[1]
  options = dict(zip(argv[2::2], argv[3::2]))
  limit = int(options['--limit'])
  rows = load(path)[:limit]
  em = sum(exact_match(r['prediction'], r['reference']) for r in rows) / len(rows)
  f1 = sum(token_f1(r['prediction'], r['reference']) for r in rows) / len(rows)
  print('rows=%d exact_match=%.3f token_f1=%.3f' % (len(rows), em, f1))
  return 0 if em >= PASS_MARK else 1


if __name__ == '__main__':
  sys.exit(main(sys.argv))
EOF
}

_sk_text() {               # scorekit/text.py; $1 = moved | tokens | regex
  case "$1" in
    moved|tokens)
      sk_put scorekit/text.py <<'EOF'
import string

_PUNCTUATION = str.maketrans('', '', string.punctuation)


def normalize(text):
  text = text.lower().translate(_PUNCTUATION)
  return ' '.join(text.split())
EOF
      ;;
    regex)
      sk_put scorekit/text.py <<'EOF'
import re

_PUNCTUATION = re.compile(r'[^\w\s]')


def normalize(text):
  text = _PUNCTUATION.sub('', text)
  return ' '.join(text.split())
EOF
      ;;
  esac
  if [ "$1" != moved ]; then
    cat >> scorekit/text.py <<'EOF'


def tokens(text):
  return normalize(text).split()
EOF
  fi
}

_sk_rouge() {              # scorekit/rouge.py; $1 = lcs | full
  sk_put scorekit/rouge.py <<'EOF'
def _lcs(a, b):
    table = [[0] * (len(b) + 1) for _ in range(len(a) + 1)]
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            if x == y:
                table[i + 1][j + 1] = table[i][j] + 1
            else:
                table[i + 1][j + 1] = max(table[i][j + 1], table[i + 1][j])
    return table[len(a)][len(b)]
EOF
  if [ "$1" = full ]; then
    { printf 'from scorekit.text import tokens\n\n\n'; cat scorekit/rouge.py; } > scorekit/rouge.py.sk-new &&
      mv scorekit/rouge.py.sk-new scorekit/rouge.py
    cat >> scorekit/rouge.py <<'EOF'


def rouge_l(prediction, reference):
    pred = tokens(prediction)
    ref = tokens(reference)
    lcs = _lcs(pred, ref)
    if lcs == 0:
        return 0.0
    precision = lcs / len(pred)
    recall = lcs / len(ref)
    return 2 * precision * recall / (precision + recall)
EOF
  fi
}

# ---------------------------------------------------------------- the history
fx_scorekit() {
  git init -q scorekit && cd scorekit || return 1

  # ---- Monday 7 September
  sk_clock 0 0
  sk_put README.md <<'EOF'
# scorekit

Scores model answers against reference answers.
EOF
  sk_put .gitignore <<'EOF'
__pycache__/
EOF
  sk_commit "Add project skeleton"

  sk_put scorer.py <<'EOF'
def normalize(text):
  return ' '.join(text.lower().split())


def exact_match(prediction, reference):
  return normalize(prediction) == normalize(reference)
EOF
  sk_commit "Add exact-match scorer"

  as asha
  sk_clock 0 95
  sk_put scorer.py <<'EOF'
from collections import Counter


def normalize(text):
  return ' '.join(text.lower().split())


def exact_match(prediction, reference):
  return normalize(prediction) == normalize(reference)


def token_f1(prediction, reference):
  pred = normalize(prediction).split()
  ref = normalize(reference).split()
  overlap = sum((Counter(pred) & Counter(ref)).values())
  if overlap == 0:
    return 0.0
  precision = overlap / len(pred)
  recall = overlap / len(ref)
  return 2 * precision * recall / (precision + recall)
EOF
  sk_commit "Add token-level F1 scorer"

  as you
  sk_clock 0 240
  _sk_runner_first
  _sk_smoke
  sk_commit "Add evaluation runner and smoke set"

  as ravi
  sk_clock 0 385
  sk_put bleu.py <<'EOF'
import math
from collections import Counter

from scorer import normalize


def bleu1(prediction, reference):
  pred = normalize(prediction).split()
  ref = normalize(reference).split()
  if not pred:
    return 0.0
  overlap = sum((Counter(pred) & Counter(ref)).values())
  precision = overlap / len(pred)
  brevity = 1.0 if len(pred) >= len(ref) else math.exp(1 - len(ref) / len(pred))
  return brevity * precision
EOF
  sk_commit "Add experimental BLEU scorer"

  # ---- Tuesday 8 September
  as you
  sk_clock 1 20
  mkdir scorekit
  git mv scorer.py scorekit/scorer.py
  git mv bleu.py scorekit/bleu.py
  git mv run_eval.py scorekit/runner.py
  sk_sed 's/^from scorer import/from scorekit.scorer import/' scorekit/bleu.py
  sk_sed 's/^from scorer import/from scorekit.scorer import/' scorekit/runner.py
  sk_put scorekit/__init__.py <<'EOF'
__version__ = '0.1.0'
EOF
  sk_put README.md <<'EOF'
# scorekit

Scores model answers against reference answers.

    python3 -m scorekit.runner data/smoke.jsonl
EOF
  sk_commit "Move sources into the scorekit package"

  as asha
  sk_clock 1 150
  git mv scorekit/scorer.py scorekit/metrics.py
  sk_sed 's/^from scorekit.scorer import/from scorekit.metrics import/' scorekit/bleu.py
  sk_sed 's/^from scorekit.scorer import/from scorekit.metrics import/' scorekit/runner.py
  sk_commit "Rename the scorer module to metrics" \
    "The module holds every metric, not one scorer. No code changes besides the imports."

  as you
  sk_clock 1 300
  sk_put scorekit/config.py <<'EOF'
# Thresholds used by the runner.
PASS_MARK = 0.7
EOF
  sk_sed '/^PASS_MARK = 0.7$/{N;d;}' scorekit/runner.py
  sk_sed 's/^from scorekit.metrics import exact_match, token_f1$/from scorekit.config import PASS_MARK\
&/' scorekit/runner.py
  sk_commit "Add config module with the pass mark"
  tick
  git tag -a -m "First internal release" v0.1.0

  # ---- Wednesday 9 September
  as ravi
  sk_clock 2 10
  sk_put scorekit/metrics.py <<'EOF'
import string
from collections import Counter

_PUNCTUATION = str.maketrans('', '', string.punctuation)


def normalize(text):
  text = text.lower().translate(_PUNCTUATION)
  return ' '.join(text.split())


def exact_match(prediction, reference):
  return normalize(prediction) == normalize(reference)


def token_f1(prediction, reference):
  pred = normalize(prediction).split()
  ref = normalize(reference).split()
  overlap = sum((Counter(pred) & Counter(ref)).values())
  if overlap == 0:
    return 0.0
  precision = overlap / len(pred)
  recall = overlap / len(ref)
  return 2 * precision * recall / (precision + recall)
EOF
  sk_commit "Strip punctuation before comparing" \
    "\"The Pacific Ocean.\" and \"the pacific ocean\" are the same answer."

  as asha
  git switch -q -c feat/text-utils
  sk_clock 2 60
  _sk_text moved
  sk_put scorekit/metrics.py <<'EOF'
from collections import Counter

from scorekit.text import normalize


def exact_match(prediction, reference):
  return normalize(prediction) == normalize(reference)


def token_f1(prediction, reference):
  pred = normalize(prediction).split()
  ref = normalize(reference).split()
  overlap = sum((Counter(pred) & Counter(ref)).values())
  if overlap == 0:
    return 0.0
  precision = overlap / len(pred)
  recall = overlap / len(ref)
  return 2 * precision * recall / (precision + recall)
EOF
  sk_sed 's/^from scorekit.metrics import normalize$/from scorekit.text import normalize/' scorekit/bleu.py
  sk_commit "Move normalize into scorekit/text.py"
  sk_clock 2 200
  _sk_text tokens
  sk_sed 's/^from scorekit.text import normalize$/from scorekit.text import normalize, tokens/' scorekit/metrics.py
  sk_sed 's/normalize(\(prediction\))\.split()/tokens(\1)/' scorekit/metrics.py
  sk_sed 's/normalize(\(reference\))\.split()/tokens(\1)/' scorekit/metrics.py
  sk_sed 's/^from scorekit.text import normalize$/from scorekit.text import tokens/' scorekit/bleu.py
  sk_sed 's/normalize(\(prediction\))\.split()/tokens(\1)/' scorekit/bleu.py
  sk_sed 's/normalize(\(reference\))\.split()/tokens(\1)/' scorekit/bleu.py
  sk_commit "Add a tokens helper and use it in the metrics"

  as you
  git switch -q main
  sk_clock 2 215
  _sk_runner_load
  sk_commit "Skip rows with an empty reference" \
    "A row without a reference cannot be scored. Print a notice and leave it out of the averages."
  sk_put docs/metrics.md <<'EOF'
# Metrics

- exact_match: 1 when prediction and reference are equal after normalization, else 0.
- token_f1: harmonic mean of token precision and recall.
- bleu1: unigram precision with a brevity penalty (experimental).

Normalization lowercases the text, strips punctuation and collapses whitespace.
EOF
  sk_commit "Document the metrics"
  sk_clock 2 320
  sk_sed 's/^PASS_MARK = 0.7$/PASS_MARK = 0.75/' scorekit/config.py
  sk_commit "Raise the pass mark to 0.75" \
    "With punctuation stripped the smoke set scores 0.800, so 0.7 no longer catches a one-row drop."
  sk_clock 2 400
  tick
  git merge -q --no-ff -m "Merge branch 'feat/text-utils'" feat/text-utils > /dev/null 2>&1 || return 1
  git branch -q -d feat/text-utils > /dev/null 2>&1

  # ---- Thursday 10 September
  sk_clock 3 5
  printf '\nThe runner prints one score line and exits with status 1 when exact_match is below the pass mark.\n' >> README.md
  sk_commit "Document the runner's exit status"
  sk_clock 3 40
  _sk_runner_limit
  sk_commit "Add --limit option to the runner" \
    "python3 -m scorekit.runner data/nightly.jsonl --limit 100 scores the first 100 rows."
  as ravi
  sk_clock 3 95
  sk_sed "s/print('skipped empty reference')/print('skipped empty reference', file=sys.stderr)/" scorekit/runner.py
  sk_commit "Send warnings to stderr" \
    "The score line on stdout is parsed by the nightly job."
  as you
  sk_clock 3 150
  sk_sed "s/^  limit = int(options\['--limit'\])\$/  limit = int(options['--limit']) if '--limit' in options else None/" scorekit/runner.py
  sk_commit "Fix crash when --limit is not given" \
    "Without the option the runner stopped with KeyError: '--limit'."
  as ravi
  sk_clock 3 215
  _sk_text regex
  sk_commit "Speed up normalize with a precompiled pattern" \
    "str.translate built a table lookup per call. One compiled pattern is faster on the nightly set."

  # ---- Friday 11 September
  as asha
  sk_clock 4 15
  for f in scorekit/__init__.py scorekit/bleu.py scorekit/metrics.py scorekit/runner.py scorekit/text.py; do
    sk_reformat "$f"
  done
  sk_commit "Reformat sources: four-space indent, double quotes" \
    "Formatter only. No behavior change."

  git switch -q -c feat/rouge-l
  sk_clock 4 70
  _sk_rouge lcs
  sk_commit "Add longest-common-subsequence helper"
  sk_clock 4 130
  _sk_rouge full
  sk_sed 's/^- bleu1:/- rouge_l: F-measure of the longest common subsequence of tokens.\
&/' docs/metrics.md
  sk_commit "Add ROUGE-L F-measure"
  as ravi
  sk_clock 4 190
  sk_sed 's/^from scorekit.metrics import exact_match, token_f1$/&\
from scorekit.rouge import rouge_l/' scorekit/runner.py
  sk_sed 's/^    print("rows=%d exact_match=%.3f token_f1=%.3f" % (len(rows), em, f1))$/    rl = sum(rouge_l(r["prediction"], r["reference"]) for r in rows) \/ len(rows)\
    print("rows=%d exact_match=%.3f token_f1=%.3f rouge_l=%.3f" % (len(rows), em, f1, rl))/' scorekit/runner.py
  sk_commit "Report ROUGE-L in the runner"

  as you
  git switch -q main
  sk_clock 4 300
  tick
  git merge -q --squash feat/rouge-l > /dev/null 2>&1 || return 1
  git commit -q -m "Add ROUGE-L metric" -m "Squashed from feat/rouge-l (three commits)." \
    -m "Co-authored-by: Asha Rao <asha@example.com>
Co-authored-by: Ravi Menon <ravi@example.com>" > /dev/null 2>&1 || return 1

  as asha
  sk_clock 4 380
  cp data/smoke.jsonl data/nightly.jsonl
  cat >> data/nightly.jsonl <<'EOF'
{"id": 11, "prediction": "Canberra", "reference": "canberra"}
{"id": 12, "prediction": "the speed of light", "reference": "speed of light"}
{"id": 13, "prediction": "Au", "reference": "au"}
{"id": 14, "prediction": "ha ha ha", "reference": "ha ha"}
EOF
  sk_commit "Add nightly evaluation set" \
    "Seeded from the smoke set, plus four rows."
  as you
  tick
  git tag -a -m "Second internal release" v0.2.0

  # ---- Monday 14 September
  as asha
  sk_clock 7 30
  sk_sed '/^from collections import Counter$/{N;d;}' scorekit/metrics.py
  sk_sed 's/^    overlap = sum((Counter(pred) & Counter(ref)).values())$/    overlap = len(set(pred) \& set(ref))/' scorekit/metrics.py
  sk_commit "Simplify token overlap in token_f1" \
    "A set intersection says the same thing without the Counter import."

  as ravi
  sk_clock 7 150
  git rm -q scorekit/bleu.py
  sk_sed '/^- bleu1:/d' docs/metrics.md
  sk_commit "Remove the experimental BLEU scorer" \
    "Nothing imports it, and for one reference its unigram precision duplicates token_f1.
ROUGE-L covers the use case it was added for."

  as asha
  sk_clock 7 290
  sk_sed '/^            print("skipped empty reference", file=sys.stderr)$/{N;s/.*/            raise ValueError("empty reference in row %d" % row["id"])/;}' scorekit/runner.py
  sk_commit "Fail fast on an empty reference" \
    "A silent skip changed the denominator of every average. An empty reference is a data bug:
stop the run and name the row."

  # ---- Tuesday 15 September
  as ravi
  git switch -q -c feat/report
  sk_clock 8 20
  sk_put scorekit/report.py <<'EOF'
import json


def write_report(rows, path):
    with open(path, "w") as out:
        for row in rows:
            out.write(json.dumps(row) + "\n")
EOF
  sk_commit "Add per-row report writer"
  sk_clock 8 45
  printf '\nThe nightly job runs the same command on data/nightly.jsonl.\n' >> README.md
  sk_commit "Mention the nightly run in the README"
  sk_clock 8 100
  sk_sed 's/^from scorekit.metrics import exact_match, token_f1$/&\
from scorekit.report import write_report/' scorekit/runner.py
  sk_sed 's/^    return 0 if em >= PASS_MARK else 1$/    if "--report" in options:\
        write_report(rows, options["--report"])\
&/' scorekit/runner.py
  sk_commit "Write a report when --report <path> is given"

  as you
  git switch -q main
  sk_clock 8 130
  printf 'NIGHTLY_PASS_MARK = 0.6\n' >> scorekit/config.py
  sk_commit "Add a separate pass mark for the nightly set"
  sk_clock 8 160
  tick
  git cherry-pick feat/report~1 > /dev/null 2>&1 || return 1
}

# sk_ids: capture the abbreviated IDs of the commits that the demos talk about, so that no script
# hardcodes an ID. Call it inside the repository, after fx_scorekit.
sk_ids() {
  ID_PKG=$(git rev-parse --short 'main^{/^Move sources into the scorekit package}')       # commit 6
  ID_PRE_PKG=$(git rev-parse --short "$ID_PKG~1")                                          # commit 5
  ID_PUNCT=$(git rev-parse --short 'main^{/^Strip punctuation}')                           # commit 9
  ID_MOVE=$(git rev-parse --short 'main^{/^Move normalize into}')                          # t1
  ID_TOKENS=$(git rev-parse --short 'main^{/^Add a tokens helper}')                        # t2
  ID_RAISE=$(git rev-parse --short 'main^{/^Raise the pass mark}')                         # commit 12
  ID_MERGE=$(git rev-parse --short 'main^{/^Merge branch}')                                # commit 13
  ID_LIMIT=$(git rev-parse --short 'main^{/^Add --limit option}')                          # commit 15
  ID_FIX=$(git rev-parse --short 'main^{/^Fix crash}')                                     # commit 17
  ID_R1=$(git rev-parse --short 'main^{/^Speed up normalize}')                             # commit 18
  ID_REFORMAT=$(git rev-parse --short 'main^{/^Reformat sources}')                         # commit 19
  ID_SQUASH=$(git rev-parse --short 'main^{/^Add ROUGE-L metric}')                         # commit 20
  ID_NIGHTLY=$(git rev-parse --short 'main^{/^Add nightly evaluation set}')                # commit 21
  ID_R2=$(git rev-parse --short 'main^{/^Simplify token overlap}')                         # commit 22
  ID_DELETE=$(git rev-parse --short 'main^{/^Remove the experimental BLEU}')               # commit 23
}

# sk_check_script <path>: the test used by "git bisect run" for regression 1. It lives outside the
# repository, so no checkout can change or remove it.
sk_check_script() {
  cat > "$1" <<'EOF'
#!/bin/sh
# Exit 0 if this commit scores the smoke set correctly, 1 if it does not,
# 125 if the runner cannot produce a score line at all (untestable: skip).
out=$(python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null)
case "$out" in
  *exact_match=0.800*) exit 0 ;;
  *exact_match=*)      exit 1 ;;
  *)                   exit 125 ;;
esac
EOF
  chmod +x "$1"
}

# sk_cli_rewrite <path>: write the rewritten command-line module of Lab 11.1 to <path>. The lab keeps
# it next to the repository and copies it over scorekit/cli.py.
sk_cli_rewrite() {
  sk_put "$1" <<'EOF'
import argparse
import json
import sys

from scorekit.config import PASS_MARK
from scorekit.metrics import exact_match, token_f1
from scorekit.rouge import rouge_l

METRICS = {"exact_match": exact_match, "token_f1": token_f1, "rouge_l": rouge_l}


def load(path):
    rows = []
    for line in open(path):
        row = json.loads(line)
        if not row["reference"].strip():
            raise ValueError("empty reference in row %d" % row["id"])
        rows.append(row)
    return rows


def score(rows):
    totals = dict.fromkeys(METRICS, 0.0)
    for row in rows:
        for name, metric in METRICS.items():
            totals[name] += metric(row["prediction"], row["reference"])
    return {name: total / len(rows) for name, total in totals.items()}


def parse_args(argv):
    parser = argparse.ArgumentParser(prog="scorekit")
    parser.add_argument("path", help="JSON Lines file with prediction and reference")
    parser.add_argument("--limit", type=int, default=None, help="score only the first N rows")
    return parser.parse_args(argv)


def main(argv):
    args = parse_args(argv[1:])
    rows = load(args.path)[: args.limit]
    scores = score(rows)
    fields = " ".join("%s=%.3f" % item for item in scores.items())
    print("rows=%d %s" % (len(rows), fields))
    return 0 if scores["exact_match"] >= PASS_MARK else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
EOF
}
