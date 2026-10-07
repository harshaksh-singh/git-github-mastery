# V066: Reading a diff: summaries, filters, computed renames, whitespace and algorithms

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 11, History investigation
- **Planned minutes:** 22
- **Prerequisites:** V013, V064
- **Textbook sections:** [Chapter 14A](../../textbook/ch14a-history-investigation.md), sections 14A.3, 14A.4, 14A.5 and 14A.6
- **Demo scripts:** `labs/ch14a/diff-summaries.sh`, `labs/ch14a/diff-renames.sh`, `labs/ch14a/diff-words-whitespace.sh`, `labs/ch14a/diff-algorithms.sh`, `labs/ch14a/diff-check.sh`

## HOOK

**[ON SCREEN]** `5 files changed, 40 insertions(+), 40 deletions(-)`

"The nightly evaluation scored 0.800 last Wednesday and 0.400 today, on the same model checkpoint. Is it the model, the data or our own harness?"

You start where everyone starts: what changed between the last good release and now. The diff, the list of lines removed and added between two snapshots, runs to hundreds of lines. One commit alone touches 40 lines in five files. It's a formatter run. Somewhere in or around it there may be one line that matters.

If you read that diff top to bottom, you'll be tired before you reach it, and you may not recognise it when you do. There is a way to read a large diff from the outside in, and to make Git remove the noise before your eyes have to. Keep those 40 lines in mind. We'll shrink them.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video opens the module on history investigation. The textbook's central fact for the whole module: history stores snapshots and parent links, nothing else. A commit is one saved snapshot of the project, and it names the commit it was built on. Diffs, renames, "who wrote this line" and "which commit broke it" are not recorded anywhere. Git computes them when you ask, with heuristics that have thresholds and blind spots. An investigator has to know which answers are facts read from objects and which are inferences.

Today that principle is applied to the most basic tool, the diff. Four things. Summaries and filters, which answer "what changed" before "how". Renames and copies, which are computed and can be missed. Whitespace and word-level views, which read through reformatting. And diff algorithms, which decide how one and the same change is displayed. At the end comes `--check`, a small guard that belongs before every commit.

Every command today is 🟢 SAFE. Nothing is written. The project is `scorekit`.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The five objectives.

After this video you can:

- Summarize a diff by files, by status and by counts, and filter it by kind of change.
- Explain a rename score and change the detection threshold.
- Separate real changes from whitespace and reformatting noise.
- Compare two diff algorithms on the same change.
- Find whitespace errors and leftover conflict markers before committing.

## CONCEPT

**[ANIMATION]** gates: packet=a_large_diff gates=--stat:done:-:where_the_bulk_is|--name-status:done:-:one_letter_per_path|--diff-filter:done:-:select_by_letter|pathspec:done:-:narrow_to_some_paths|the_patch:done:-:read_it_last title=From_the_outside_in id=outside

**Summaries and filters.** A patch between two releases can run to thousands of lines. Start with a summary and descend from there. All of these options work with `git diff`, `git show` and `git log` alike, because the three share one diff machinery.

**[ANIMATION]** cards: cards=--stat:one_line_per_file,_with_a_histogram|--shortstat:only_the_total|--numstat:unscaled,_tab-separated:_for_scripts|--name-only:the_paths|--name-status:one_letter_per_path question=Five_summaries_of_one_diff id=summ

**[ANIMATION]** step: 5

`--stat` draws one line per file with a scaled histogram. `--shortstat` keeps only the total. `--numstat` prints the same numbers unscaled and tab-separated, the form for scripts. `--name-only` lists paths. `--name-status` adds one letter per path.

**[ON SCREEN]** The status letters.

```text
Letter   Meaning                      Letter   Meaning
------   --------------------------   ------   ------------------------------------------
A        added                        R<nn>    renamed, with a similarity index
D        deleted                      C<nn>    copied, with a similarity index
M        content or mode modified     T        type changed (file, symlink, submodule)
U        unmerged
```

`--diff-filter` selects by those letters. An uppercase letter includes, a lowercase letter excludes.

**[ANIMATION]** hash: differs=byte steps=one,different left=run__eval.py right=scorekit/runner.py lines=import_json,import_sys,PASS__MARK_=_0.7 alt=from_scorekit.config_import_PASS__MARK ids=9f41591,d846906 fn=hash title=The_facts:_two_paths,_two_blobs at_different=30 diff=Different_content,_different_blob_IDs._"Renamed"_is_an_inference

**Renames and copies.** In one sentence: a commit does not say "this file was renamed". `git diff` notices that a path disappeared, another appeared, and their contents are similar enough. On screen, one stored file: `run_eval.py`, with the ID of its content, its blob ID.

**[ANIMATION]** step: different

Precisely. Rename detection is a pass over the list of changed paths. A deleted path and an added path with the same blob ID are an exact rename. For the remaining pairs Git computes a similarity index, and a pair at or above the threshold becomes a rename. On screen the two blob IDs differ, so this pair needs the similarity index. The threshold is 50 percent by default. `-M<n>` changes it, and `--no-renames` switches the pass off. For the porcelain commands the pass is on by default. `-C` also looks for copies, with the sources limited to files that the same commit modified. `--find-copies-harder`, or `-C` given twice, considers every file of the older tree and costs accordingly.

**[ANIMATION]** decide: nodes=q1:A_deleted_path_and_an_added_path:_the_same_blob_ID?|a:an_exact_rename:_R100|q2:Similarity_index_at_or_above_the_threshold?|b:a_rename_with_a_score|c:a_deletion_and_an_addition edges=q1>a:yes|q1>q2:no|q2>b:yes|q2>c:no title=Rename_detection_is_computed id=rename

The limit: similarity is a heuristic over content. Rename a file and rewrite half of it in the same commit, and the link is gone. Everything that relies on rename detection inherits this limit: `git log --follow`, `git blame`, and the rename handling of `git merge`, which you met in the merge module as a `modify/delete` conflict that nobody intended.

**Noise.** Two kinds of change bury the lines you are looking for: whitespace, and small edits inside long lines. `-w` treats lines that differ only in whitespace as equal. `--word-diff` compares words and marks them in place.

**[ON SCREEN]** The whitespace options.

```text
Option                         Ignores
-----------------------------  ------------------------------------------------------------------
--ignore-space-at-eol          whitespace changes at the end of a line
-b, --ignore-space-change      changes in the amount of whitespace
-w, --ignore-all-space         all whitespace, including whitespace where the other side has none
--ignore-blank-lines           changes whose lines are all blank
-I<regex>                      changes whose lines all match the expression
```

**Algorithms.** In one sentence: for two given files there are many correct diffs, and the algorithm decides which one you read.

Git has four. `myers`, the default, which the manual calls "the basic greedy diff algorithm". `minimal`, which spends extra time to produce the smallest diff. `patience`. And `histogram`, which "extends the patience algorithm to support low-occurrence common elements". The last two anchor on lines that occur rarely, which tends to keep moved blocks together. Choose with `--diff-algorithm=<name>` and make the choice permanent with `diff.algorithm`.

**`--check`** is not about reading diffs at all. It inspects the lines a diff adds and reports whitespace errors and leftover conflict markers, with an exit status a script can test.

## MENTAL MODEL

**[ON SCREEN]** "Facts are read from objects. Everything else in a diff is an inference."

Sort what a diff tells you into two piles.

**[ANIMATION]** step: different

Facts: this path exists in the left tree and not in the right. These two blobs have different IDs. These are read from objects, and no option changes them.

Inferences: "this file was renamed". "These six lines were edited" as opposed to "this block moved". "42 lines changed". Each of those depends on a threshold or an algorithm, and a different setting gives a different, equally valid answer.

**[ANIMATION]** end

Think of a map drawn from two aerial photographs taken a year apart. The photographs are facts. "This building was moved" is the cartographer's inference from "a building vanished here, a similar one appeared there". Usually right. Wrong when the building was also half rebuilt.

Where does the picture break? A cartographer can go and ask. Git can't: there's nothing recorded to ask. So when an inference matters to your investigation, change the setting and see whether the answer changes.

## DIAGRAM

**[DIAGRAM]** New diagram. One moved-and-edited file, shown three ways, side by side.

```text
  the facts (two trees):          left tree: run_eval.py           right tree: scorekit/runner.py
                                  blob 9f41591                     blob d846906

  1. --no-renames                 2. default (-M, threshold 50%)        3. --word-diff on a changed line
  -----------------------------   ----------------------------------    -------------------------------------
  D   run_eval.py                 R082  run_eval.py                     harmonic mean of
  A   scorekit/runner.py                -> scorekit/runner.py           [-token-]{+token-level+}
                                                                        precision and recall.
  a deletion and an addition:     one rename, similarity 82%:           the changed words inside one line,
  every line shown as new         only the changed lines shown          marked in place

  -M90%:  82% < 90%  ->  back to view 1.        A rewrite below 50%  ->  view 1 by default.
```

One moved and edited file, three ways. Without rename detection: a deletion and an addition. By default: one rename, 82 percent similar. With word diff: the changed words, marked in place. Same two trees every time.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch14a/diff-summaries`. Two releases of `scorekit`.

**Part 1: from the outside in.**

<!-- snippet: ch14a/diff-summaries/01-stat -->
```text
$ git diff --stat v0.1.0 v0.2.0
 README.md            |  2 ++
 data/nightly.jsonl   | 14 ++++++++++++++
 docs/metrics.md      |  8 ++++++++
 scorekit/__init__.py |  2 +-
 scorekit/bleu.py     | 18 +++++++++---------
 scorekit/config.py   |  2 +-
 scorekit/metrics.py  | 22 ++++++++++------------
 scorekit/rouge.py    | 23 +++++++++++++++++++++++
 scorekit/runner.py   | 32 ++++++++++++++++++++++++--------
 scorekit/text.py     | 12 ++++++++++++
 10 files changed, 104 insertions(+), 31 deletions(-)
$ git diff --shortstat v0.1.0 v0.2.0
 10 files changed, 104 insertions(+), 31 deletions(-)
```
<!-- /snippet -->

Ten files, 104 insertions, 31 deletions. One line per file, with a histogram. You now know where the bulk is before you have read a single changed line.

<!-- snippet: ch14a/diff-summaries/02-names -->
```text
$ git diff --name-only v0.1.0 v0.2.0
README.md
data/nightly.jsonl
docs/metrics.md
scorekit/__init__.py
scorekit/bleu.py
scorekit/config.py
scorekit/metrics.py
scorekit/rouge.py
scorekit/runner.py
scorekit/text.py
$ git diff --name-status v0.1.0 main
M	README.md
A	data/nightly.jsonl
A	docs/metrics.md
M	scorekit/__init__.py
D	scorekit/bleu.py
M	scorekit/config.py
M	scorekit/metrics.py
A	scorekit/rouge.py
M	scorekit/runner.py
A	scorekit/text.py
```
<!-- /snippet -->

`--name-status`: `A` for added, `M` for modified, and one `D`: `scorekit/bleu.py` was deleted between `v0.1.0` and `main`.

<!-- snippet: ch14a/diff-summaries/03-numstat -->
```text
$ git diff --numstat v0.1.0 main
4	0	README.md
14	0	data/nightly.jsonl
7	0	docs/metrics.md
1	1	scorekit/__init__.py
0	15	scorekit/bleu.py
2	1	scorekit/config.py
10	14	scorekit/metrics.py
23	0	scorekit/rouge.py
23	8	scorekit/runner.py
12	0	scorekit/text.py
$ git diff --dirstat v0.1.0 main
  18.0% data/
   6.2% docs/
  72.3% scorekit/
```
<!-- /snippet -->

`--numstat` gives the form for scripts: added, removed, path.

<!-- snippet: ch14a/diff-summaries/04-filter -->
```text
$ git diff --name-status --diff-filter=A v0.1.0 main
A	data/nightly.jsonl
A	docs/metrics.md
A	scorekit/rouge.py
A	scorekit/text.py
$ git diff --name-status --diff-filter=D v0.1.0 main
D	scorekit/bleu.py
# Lowercase letters exclude: everything except additions and deletions.
$ git diff --name-status --diff-filter=ad v0.1.0 main
M	README.md
M	scorekit/__init__.py
M	scorekit/config.py
M	scorekit/metrics.py
M	scorekit/runner.py
```
<!-- /snippet -->

`--diff-filter=A` lists only additions, `=D` only deletions, and lowercase `ad` excludes both and leaves the modifications. `--diff-filter=D` with `git log` is the standard way to find when a file was deleted. A later video uses it.

<!-- snippet: ch14a/diff-summaries/05-pathspec -->
```text
$ git diff --stat v0.1.0 main -- '*.py' ':(exclude)scorekit/runner.py'
 scorekit/__init__.py |  2 +-
 scorekit/bleu.py     | 15 ---------------
 scorekit/config.py   |  3 ++-
 scorekit/metrics.py  | 24 ++++++++++--------------
 scorekit/rouge.py    | 23 +++++++++++++++++++++++
 scorekit/text.py     | 12 ++++++++++++
 6 files changed, 48 insertions(+), 31 deletions(-)
```
<!-- /snippet -->

A pathspec, a pattern that limits a command to some paths, after the double dash narrows any of these, including the exclusion form.

**Part 2: renames are computed.** `labs/run ch14a/diff-renames`. Between commit `d369eac` and `v0.1.0` the sources moved into a package, one module was renamed a second time, and two files were edited on the way.

<!-- snippet: ch14a/diff-renames/01-default -->
```text
$ git diff --name-status d369eac v0.1.0
M	README.md
A	scorekit/__init__.py
R090	bleu.py	scorekit/bleu.py
A	scorekit/config.py
R100	scorer.py	scorekit/metrics.py
R082	run_eval.py	scorekit/runner.py
```
<!-- /snippet -->

`R100` is an exact rename: two commits moved `scorer.py` twice and never changed it, and the diff of the endpoints sees one rename. `R090` and `R082` are renames with edits. Predict the same comparison with `--no-renames`. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch14a/diff-renames/02-no-renames -->
```text
$ git diff --name-status --no-renames d369eac v0.1.0
M	README.md
D	bleu.py
D	run_eval.py
A	scorekit/__init__.py
A	scorekit/bleu.py
A	scorekit/config.py
A	scorekit/metrics.py
A	scorekit/runner.py
D	scorer.py
```
<!-- /snippet -->

A list of unrelated deletions and additions. Same two trees, same facts, different inference. The threshold decides.

<!-- snippet: ch14a/diff-renames/03-threshold -->
```text
$ git diff --name-status -M90% d369eac v0.1.0
M	README.md
D	run_eval.py
A	scorekit/__init__.py
R090	bleu.py	scorekit/bleu.py
A	scorekit/config.py
R100	scorer.py	scorekit/metrics.py
A	scorekit/runner.py
$ git diff --name-status -M d369eac v0.1.0 -- run_eval.py scorekit/runner.py
R082	run_eval.py	scorekit/runner.py
```
<!-- /snippet -->

At 90 percent the runner, whose similarity is 82 percent, is no longer a rename: it's a `D` and an `A`.

<!-- snippet: ch14a/diff-renames/04-patch -->
```text
$ git diff d369eac v0.1.0 -- run_eval.py scorekit/runner.py
diff --git a/run_eval.py b/scorekit/runner.py
similarity index 82%
rename from run_eval.py
rename to scorekit/runner.py
index 9f41591..d846906 100644
--- a/run_eval.py
+++ b/scorekit/runner.py
@@ -1,9 +1,8 @@
 import json
 import sys
 
-from scorer import exact_match, token_f1
-
-PASS_MARK = 0.7
+from scorekit.config import PASS_MARK
+from scorekit.metrics import exact_match, token_f1
 
 
 def main(path):
```
<!-- /snippet -->

In a patch, a detected rename is printed as extended header lines, "similarity index 82%", "rename from", "rename to", and only the changed lines follow.

<!-- snippet: ch14a/diff-renames/05-stat -->
```text
$ git diff --stat d369eac v0.1.0
 README.md                         | 2 ++
 scorekit/__init__.py              | 1 +
 bleu.py => scorekit/bleu.py       | 2 +-
 scorekit/config.py                | 2 ++
 scorer.py => scorekit/metrics.py  | 0
 run_eval.py => scorekit/runner.py | 5 ++---
 6 files changed, 8 insertions(+), 4 deletions(-)
```
<!-- /snippet -->

And `--stat` shows a rename in one line, with the old and the new name.

Copies need the harder search when the source file was not modified by the same commit. Here Asha seeded the nightly data set from the smoke set.

<!-- snippet: ch14a/diff-renames/06-copies -->
```text
$ git show --stat --format='%h %s' c0c9a30
c0c9a30 Add nightly evaluation set

 data/nightly.jsonl | 14 ++++++++++++++
 1 file changed, 14 insertions(+)
$ git show --stat --format='%h %s' -C c0c9a30
c0c9a30 Add nightly evaluation set

 data/nightly.jsonl | 14 ++++++++++++++
 1 file changed, 14 insertions(+)
$ git show --stat --format='%h %s' --find-copies-harder c0c9a30
c0c9a30 Add nightly evaluation set

 data/{smoke.jsonl => nightly.jsonl} | 4 ++++
 1 file changed, 4 insertions(+)
$ git show --name-status --format='%h %s' --find-copies-harder c0c9a30
c0c9a30 Add nightly evaluation set

C071	data/smoke.jsonl	data/nightly.jsonl
```
<!-- /snippet -->

`-C` alone finds nothing, because `data/smoke.jsonl` itself did not change in that commit. `--find-copies-harder` finds the copy with a similarity of 71 percent and reduces fourteen added lines to the four that are new.

Now the limit. A file renamed and half rewritten in one step. Predict what `git status` shows. I'll wait.

**[PAUSE]**

<!-- snippet: ch14a/diff-renames/07-rewrite -->
```text
# docs/metrics.md was renamed to docs/scoring.md and half of its text rewritten, in one step.
$ git status --short
D  docs/metrics.md
A  docs/scoring.md
$ git diff --cached --name-status -M40%
R043	docs/metrics.md	docs/scoring.md
```
<!-- /snippet -->

A deletion and an addition, because status uses the default threshold and this pair is 43 percent similar. A lower threshold still finds it, but nobody reading the log later will think to pass `-M40%`. Moving and tidying in one commit feels natural. Almost everyone does it once.

**Part 3: reading through noise.** `labs/run ch14a/diff-words-whitespace`. Commit `9c8df98` ran a formatter over the sources. That's the commit from the opening.

<!-- snippet: ch14a/diff-words-whitespace/01-reformat-stat -->
```text
$ git show --stat --format='%h %an: %s' 9c8df98
9c8df98 Asha Rao: Reformat sources: four-space indent, double quotes

 scorekit/__init__.py |  2 +-
 scorekit/bleu.py     | 16 ++++++++--------
 scorekit/metrics.py  | 18 +++++++++---------
 scorekit/runner.py   | 36 ++++++++++++++++++------------------
 scorekit/text.py     |  8 ++++----
 5 files changed, 40 insertions(+), 40 deletions(-)
$ git show --stat --format='%h %an: %s' -w 9c8df98
9c8df98 Asha Rao: Reformat sources: four-space indent, double quotes

 scorekit/__init__.py |  2 +-
 scorekit/runner.py   | 14 +++++++-------
 scorekit/text.py     |  6 +++---
 3 files changed, 11 insertions(+), 11 deletions(-)
```
<!-- /snippet -->

Without `-w`: five files, 40 lines. With `-w`: three files, 11 lines.

**[ANIMATION]** bars: bars=plain:40|with_-w:11 unit=lines title=Commit_9c8df98,_lines_in_the_stat id=shrink

The 40 lines from the opening have shrunk. Two files drop out entirely: their only change was the indentation. What are the eleven lines that remain?

<!-- snippet: ch14a/diff-words-whitespace/02-reformat-w -->
```text
$ git show --format='%h %s' -w 9c8df98 -- scorekit/text.py
9c8df98 Reformat sources: four-space indent, double quotes

diff --git a/scorekit/text.py b/scorekit/text.py
index 3075545..d404d86 100644
--- a/scorekit/text.py
+++ b/scorekit/text.py
@@ -1,11 +1,11 @@
 import re
 
-_PUNCTUATION = re.compile(r'[^\w\s]')
+_PUNCTUATION = re.compile(r"[^\w\s]")
 
 
 def normalize(text):
-  text = _PUNCTUATION.sub('', text)
-  return ' '.join(text.split())
+    text = _PUNCTUATION.sub("", text)
+    return " ".join(text.split())
 
 
 def tokens(text):
```
<!-- /snippet -->

The formatter also replaced single quotes with double quotes. That is not whitespace, so `-w` cannot hide it.

**[ANIMATION]** walk: columns=the_formatter_changed,under_-w rows=the_indentation:hidden|single_quotes_to_double_quotes:still_shown marks=1.2:ok,2.2:bad mono=off title=What_-w_can_and_cannot_hide id=split

Remember this split: it returns in the blame videos, where `git blame -w` sees through the indentation and needs a different option for the quotes.

**[ANIMATION]** end

For prose, configuration strings and long lines, a line-based diff says "this line changed" and leaves the comparison to your eyes.

<!-- snippet: ch14a/diff-words-whitespace/03-line-diff -->
```text
$ git diff -- docs/metrics.md
diff --git a/docs/metrics.md b/docs/metrics.md
index 7b59436..9bd401e 100644
--- a/docs/metrics.md
+++ b/docs/metrics.md
@@ -1,7 +1,7 @@
 # Metrics
 
 - exact_match: 1 when prediction and reference are equal after normalization, else 0.
-- token_f1: harmonic mean of token precision and recall.
+- token_f1: harmonic mean of token-level precision and recall.
 - rouge_l: F-measure of the longest common subsequence of tokens.
 
-Normalization lowercases the text, strips punctuation and collapses whitespace.
+Normalization strips punctuation and collapses whitespace.
```
<!-- /snippet -->

Two long lines removed, two long lines added. Try it now. Thirty seconds: find the difference in the last pair, without help.

**[PAUSE]**

<!-- snippet: ch14a/diff-words-whitespace/04-word-diff -->
```text
$ git diff --word-diff -- docs/metrics.md
diff --git a/docs/metrics.md b/docs/metrics.md
index 7b59436..9bd401e 100644
--- a/docs/metrics.md
+++ b/docs/metrics.md
@@ -1,7 +1,7 @@
# Metrics

- exact_match: 1 when prediction and reference are equal after normalization, else 0.
- token_f1: harmonic mean of [-token-]{+token-level+} precision and recall.
- rouge_l: F-measure of the longest common subsequence of tokens.

Normalization[-lowercases the text,-] strips punctuation and collapses whitespace.
```
<!-- /snippet -->

`--word-diff` marks removed text in square brackets with minus signs and added text in braces with plus signs. "token" became "token-level". And in the last line, three words were removed: "lowercases the text,". In the line-based diff that removal was hard to see. Here it's marked.

The output of `--word-diff` is for reading, not for `git apply`.

**Part 4: algorithms.** `labs/run ch14a/diff-algorithms`. One file, two similar functions, and an edit that swaps them. Nothing else changed.

<!-- snippet: ch14a/diff-algorithms/01-myers -->
```text
# The two functions of scorekit/overlap.py were swapped. Nothing else changed.
$ git diff --diff-algorithm=myers
diff --git a/scorekit/overlap.py b/scorekit/overlap.py
index 1394725..49c341c 100644
--- a/scorekit/overlap.py
+++ b/scorekit/overlap.py
@@ -1,12 +1,12 @@
-def token_precision(pred, ref):
+def token_recall(pred, ref):
     overlap = len(set(pred) & set(ref))
-    if not pred:
+    if not ref:
         return 0.0
-    return overlap / len(pred)
+    return overlap / len(ref)
 
 
-def token_recall(pred, ref):
+def token_precision(pred, ref):
     overlap = len(set(pred) & set(ref))
-    if not ref:
+    if not pred:
         return 0.0
-    return overlap / len(ref)
+    return overlap / len(pred)
```
<!-- /snippet -->

Myers found the shortest edit: six lines out, six lines in. It is correct, and it tells a false story, that someone edited both functions line by line.

<!-- snippet: ch14a/diff-algorithms/02-histogram -->
```text
$ git diff --diff-algorithm=histogram
diff --git a/scorekit/overlap.py b/scorekit/overlap.py
index 1394725..49c341c 100644
--- a/scorekit/overlap.py
+++ b/scorekit/overlap.py
@@ -1,12 +1,12 @@
-def token_precision(pred, ref):
-    overlap = len(set(pred) & set(ref))
-    if not pred:
-        return 0.0
-    return overlap / len(pred)
-
-
 def token_recall(pred, ref):
     overlap = len(set(pred) & set(ref))
     if not ref:
         return 0.0
     return overlap / len(ref)
+
+
+def token_precision(pred, ref):
+    overlap = len(set(pred) & set(ref))
+    if not pred:
+        return 0.0
+    return overlap / len(pred)
```
<!-- /snippet -->

Histogram tells what happened: one function removed from the top and added at the bottom, unchanged.

<!-- snippet: ch14a/diff-algorithms/03-counts -->
```text
$ git diff --shortstat --diff-algorithm=myers
 1 file changed, 6 insertions(+), 6 deletions(-)
$ git diff --shortstat --diff-algorithm=histogram
 1 file changed, 7 insertions(+), 7 deletions(-)
$ git diff --shortstat --patience
 1 file changed, 7 insertions(+), 7 deletions(-)
```
<!-- /snippet -->

And the line counts differ: 6 and 6 under Myers, 7 and 7 under histogram and patience. Same two files.

<!-- snippet: ch14a/diff-algorithms/04-config -->
```text
$ git config set diff.algorithm histogram
$ git diff --shortstat
 1 file changed, 7 insertions(+), 7 deletions(-)
```
<!-- /snippet -->

`diff.algorithm` makes the choice permanent.

**Part 5: `--check`.** `labs/run ch14a/diff-check`. A line with two trailing spaces in `config.py`, a forgotten conflict marker in `docs/metrics.md`.

<!-- snippet: ch14a/diff-check/01-check -->
```text
# A line with two trailing spaces in config.py, a forgotten conflict marker in docs/metrics.md.
$ git diff --check
docs/metrics.md:8: leftover conflict marker
scorekit/config.py:4: trailing whitespace.
+SMOKE_LIMIT = 10  
[exit status: 2]
```
<!-- /snippet -->

Both reported, with file and line, and exit status 2. Now you run `git add -A`, which stages everything, and check again. Quick quiz, two options. Option one: the same two reports. Option two: nothing at all. Say it out loud.

**[PAUSE]**

<!-- snippet: ch14a/diff-check/02-staged -->
```text
$ git add -A
$ git diff --check
[exit status: 0]
$ git diff --cached --check
docs/metrics.md:8: leftover conflict marker
scorekit/config.py:4: trailing whitespace.
+SMOKE_LIMIT = 10  
[exit status: 2]
```
<!-- /snippet -->

Option two. After `git add -A` the unstaged diff is empty, so the first command finds nothing: exit status 0.

**[ANIMATION]** trees: file=docs/metrics.md versions=as_committed,with_a_leftover_marker state=2,2,1 steps=setup history=off title=Which_two_does_--check_compare? say_setup=git_diff:_working_tree_against_index._--cached:_index_against_HEAD cmd_setup=git_diff_--cached_--check id=check

`git diff --cached --check` inspects what the next commit would record. As with every form of `git diff`, which changes are inspected depends on the operands.

<!-- snippet: ch14a/diff-check/03-range -->
```text
# The same test for commits that already exist: did the last release introduce any?
$ git diff --check v0.1.0 v0.2.0
[exit status: 0]
```
<!-- /snippet -->

With two commits as operands it's the form for continuous integration, the automated checks on each change.

## COMMON MISTAKES

Six mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Reading a large diff top to bottom.** Root cause: a patch is ordered by path, not by importance; `--stat`, `--name-status` and `--diff-filter` show where to look first.
2. **Treating "renamed" as a recorded fact.** Root cause: Git stores no renames; the letter `R` is an inference from similarity at or above a threshold, 50% by default.
3. **Moving a file and rewriting it in the same commit.** Root cause: similarity falls below the threshold, and every tool that relies on rename detection then sees a deletion and an addition.
4. **Assuming `-w` hides everything a formatter did.** Root cause: `-w` ignores whitespace only; quote changes and line re-wrapping are content.
5. **Comparing "lines changed" from two tools.** Root cause: the count is a property of the diff algorithm, not of the commit.
6. **Running `git diff --check` after `git add -A` and seeing a clean result.** Root cause: the unstaged diff is empty; `--cached` inspects what will be committed.

## PRODUCTION EXAMPLE

Now, out of the lab. Three rules that a model-evaluation team can take from this part of the textbook.

**[ANIMATION]** step: rename.level-3

Rename in one commit, edit in the next. A commit that only moves files shows `R100` everywhere, reviews in seconds, and keeps every history tool working. The textbook adds two limits that matter on large changes: the inexact comparison is quadratic in the number of unpaired files and is skipped above `diff.renameLimit` candidates, 1000 by default according to the local manual, so a directory move with hundreds of edited files can degrade to deletions and additions.

**[ANIMATION]** walk: columns=algorithm,the_swap_reads_as,lines rows=myers:both_functions_edited_line_by_line:6_and_6|histogram:one_function_removed_at_the_top,_added_at_the_bottom:7_and_7 mono=off title=One_change,_two_correct_diffs id=algo

Set `diff.algorithm=histogram`. Many teams do, and the `ort` merge strategy already uses histogram internally. Remember the three consequences the textbook lists. "Lines changed" is a property of the algorithm. A patch is still valid under any algorithm, because all of them transform the same old file into the same new file. And the algorithm changes what `git blame` and `git log -L` attribute, since both run diffs internally.

**[ANIMATION]** step: check.setup

And `git diff --cached --check` in a pre-commit hook, a script Git runs before each commit, with the two-commit form in CI. It's the same check that the merge module recommended before concluding a merge: leftover conflict markers are caught before they become a syntax error on `main`.

## PRACTICE EXERCISE

Your turn. Do Exercise 11.1, Level 1, "Four questions for the log", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Predict before each command:

- Which summary option answers the question most directly: files, statuses, or counts?
- For any path you expect to see as renamed: exact or with edits? What would the same comparison show with `--no-renames`?
- For a reformatting commit: how many files do you expect to drop out of the stat under `-w`, and what kind of change will remain?

The challenge is Exercise 11.7, Level 3, ""I only moved it"", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q399: "Git stores no renames. Name three commands whose output depends on rename detection, and describe a commit that defeats it."

**[PAUSE]**

Answer out loud first. A strong answer starts by saying what Git does store and how a rename is inferred from it, with the threshold. It names three commands from different areas, so that the examiner sees you know the heuristic is shared: one that compares, one that follows history, one that integrates. The commit that defeats it should be described precisely enough that someone could make it, with a number for the similarity. Finish with the practice that avoids the problem.

## RECAP

Let's land this. You should now be able to say, in your own words:

**[ANIMATION]** replay: outside

I read a large diff from the outside in: `--stat` and `--name-status` first, `--diff-filter` and a pathspec to narrow, the patch last.

**[ANIMATION]** step: different

Git stores no renames. `R` and `C` are computed from similarity with a 50 percent default threshold, so a move plus a rewrite in one commit appears as a deletion and an addition.

**[ANIMATION]** step: algo.2

`-w` removes whitespace-only changes, and `--word-diff` shows what changed inside a line. The same change can be displayed differently by `myers` and `histogram`, with different line counts, and both are correct. `git diff --cached --check` finds whitespace errors and leftover conflict markers in what I am about to commit.

## HOMEWORK

Read sections 14A.3 to 14A.6 of [Chapter 14A](../../textbook/ch14a-history-investigation.md).

Today you learned to read a diff from the outside in, and to tell its facts from its inferences. Try `--stat` and `-w` on a change of your own before the next video. Next time: `git log` is a graph query, with selection, filters, graph shape and output formats. Until then, look at the state first and type second. See you in the next one.
