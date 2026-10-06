# Chapter 14A: History investigation

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch14a/`.

## 14A.1 Why this matters

Four questions a CTO can ask on a Tuesday morning:

1. "The nightly evaluation scored 0.800 last Wednesday and 0.400 today, on the same model checkpoint. Is it the model, the data or our own harness? Which commit, who wrote it, why, and is it in the release that went out on Friday?"
2. "The warning that our log parser alerts on has stopped appearing. Who removed it, and what was the reasoning?"
3. "`git blame` says one person wrote most of the file last Friday. That cannot be right. Where is the real history?"
4. "A reviewer says the pull request deletes a setting that the pull request never touched. What were they looking at?"

None of these is answered by scrolling through `git log`. Each is a query, and Git answers three kinds:

- **Queries over the graph.** Which commits are in this set? Ranges, `--first-parent`, `--ancestry-path`, `git bisect`.
- **Queries over pairs of snapshots.** What differs between these two trees? `git diff`, and every option that prints a patch.
- **Queries over content.** Where did this line come from, when did this string appear or vanish? `git blame`, the pickaxe (`-S`, `-G`), `git log -L`, `git grep`.

One fact carries the whole chapter. **History stores snapshots and parent links, nothing else** ([Chapter 2](ch02-mental-model.md)). Diffs, renames, "who wrote this line" and "which commit broke it" are not recorded anywhere. Git computes them when you ask, with heuristics that have thresholds and blind spots. An investigator has to know which answers are facts read from objects and which are inferences.

The project is `scorekit`, a small library that scores model answers against reference answers. Its history was prepared for this chapter by `labs/ch14a/fixtures/scorekit.sh`: nine days, three authors, three renames, one formatter commit, one deleted file, a merge, a squash merge, an unmerged branch, and two regressions. The symptom first:

<!-- snippet: ch14a/history-tour/01-symptom -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl
rows=10 exact_match=0.400 token_f1=0.444 rouge_l=0.489
[exit status: 1]
$ git describe
v0.2.0-5-ge376e5b
```
<!-- /snippet -->

The runner exits with status 1 because `exact_match` is below the pass mark. `git describe` places the current commit five commits after the tag `v0.2.0`. This is the whole history:

<!-- snippet: ch14a/history-tour/02-graph -->
```text
$ git log --graph --oneline --decorate --all
* e376e5b (HEAD -> main) Mention the nightly run in the README
* 2652768 Add a separate pass mark for the nightly set
| * a10f9a1 (feat/report) Write a report when --report <path> is given
| * f37a7d8 Mention the nightly run in the README
| * a8e8550 Add per-row report writer
|/  
* ca7e2b7 Fail fast on an empty reference
* d9d075d Remove the experimental BLEU scorer
* ec4fad7 Simplify token overlap in token_f1
* c0c9a30 (tag: v0.2.0) Add nightly evaluation set
* 7823232 Add ROUGE-L metric
| * 2f2883f (feat/rouge-l) Report ROUGE-L in the runner
| * 80ee55f Add ROUGE-L F-measure
| * 1cbe38a Add longest-common-subsequence helper
|/  
* 9c8df98 Reformat sources: four-space indent, double quotes
* d926d3c Speed up normalize with a precompiled pattern
* be9ad1b Fix crash when --limit is not given
* 074d492 Send warnings to stderr
* 8dc82cb Add --limit option to the runner
* 72134f3 Document the runner's exit status
*   8657273 Merge branch 'feat/text-utils'
|\  
| * c0d33a5 Add a tokens helper and use it in the metrics
| * dd70d9e Move normalize into scorekit/text.py
* | 389337a Raise the pass mark to 0.75
* | 4da82b5 Document the metrics
* | b4b066b Skip rows with an empty reference
|/  
* 8e2cac1 Strip punctuation before comparing
* 682bc71 (tag: v0.1.0) Add config module with the pass mark
* 18bb23e Rename the scorer module to metrics
* d38a5aa Move sources into the scorekit package
* d369eac Add experimental BLEU scorer
* 633e3e6 Add evaluation runner and smoke set
* bb5eb57 Add token-level F1 scorer
* b250238 Add exact-match scorer
* 5015359 Add project skeleton
```
<!-- /snippet -->

Somewhere between `v0.1.0`, which the team knows scored correctly, and `main` there are twenty commits. The rest of the chapter builds the tools to interrogate them, and section 14A.19 puts the tools in order.

| The question | The tool | Section |
|---|---|---|
| What differs between two snapshots? | `git diff A B`, `A...B` | 14A.2 to 14A.6 |
| Which commits are in this set? | revisions and ranges, `git log` | 14A.7 to 14A.9 |
| What happened to this file, across renames? | `git log --follow`, `--diff-filter` | 14A.10, 14A.13 |
| When did this string appear or disappear? | `git log -S`, `-G` | 14A.11 |
| How did these lines evolve? | `git log -L` | 14A.12 |
| Which commit last changed each line? | `git blame` | 14A.16 to 14A.18 |
| Which commit changed the behavior? | `git bisect` | 14A.20 to 14A.22 |
| Where is this text now, or at that commit? | `git grep` | 14A.23 |

## 14A.2 `git diff` compares two snapshots: `A B`, `A..B`, `A...B`

**In one sentence.** 🟢 `git diff` compares exactly two snapshots, and every form of the command differs only in which two it picks.

**Analogy.** A diff is the comparison of two photographs. It is not the film between them: whatever happened in between, and in which order, is invisible. The analogy breaks at one form. `A...B` chooses its first photograph by consulting the commit graph, so the same two branch names can give a different diff next week, after one of them has moved or been merged.

**Precisely.** [Chapter 5](ch05-index.md), section 5.4, covered the three everyday forms: `git diff` (index against working tree), `git diff --cached` (HEAD against index) and `git diff HEAD` (HEAD against working tree). The general forms take commits, or anything that resolves to a tree:

| Form | Left side | Right side | Reads the graph? |
|---|---|---|---|
| `git diff A B` | tree of A | tree of B | no |
| `git diff A..B` | tree of A | tree of B | no: a synonym of `A B` |
| `git diff A...B` | tree of the merge base of A and B | tree of B | yes, to find the merge base |
| `git diff --merge-base A B` | the same as `A...B` | | yes |
| `git diff A^!` | tree of A's parent | tree of A | one step (section 14A.8) |
| `git diff <rev>:<path> <rev>:<path>` | one blob or tree | another blob or tree | no |

The manual is blunt about the dots: "diff is about comparing two endpoints, not ranges, and the range notations (`<commit>..<commit>` and `<commit>...<commit>`) do not mean a range as defined in the 'SPECIFYING RANGES' section in gitrevisions(7)" ([git-diff](https://git-scm.com/docs/git-diff)). For `git log` the same dots select sets of commits (section 14A.8). The two meanings are among the most common misreadings of Git ([Phase 0 report, section 12](../reports/Git%20and%20GitHub%20mastery%20research.md)).

**Inside `.git`.** Nothing is written. Git reads two tree objects and walks them in parallel. Where both sides name the same subtree ID it does not descend, so the cost follows the size of the change, not the size of the repository.

**See it.** `main` and `feat/report` have diverged. The branch has three commits of its own, `main` has two, and the merge base is `ca7e2b7`:

<!-- snippet: ch14a/diff-endpoints/01-graph -->
```text
$ git log --graph --oneline --decorate -6 main feat/report
* e376e5b (HEAD -> main) Mention the nightly run in the README
* 2652768 Add a separate pass mark for the nightly set
| * a10f9a1 (feat/report) Write a report when --report <path> is given
| * f37a7d8 Mention the nightly run in the README
| * a8e8550 Add per-row report writer
|/  
* ca7e2b7 Fail fast on an empty reference
$ git merge-base main feat/report
ca7e2b7fcc44f8d5a494107b68440c3d4ec23b55
```
<!-- /snippet -->

Two endpoints, with and without the two dots:

<!-- snippet: ch14a/diff-endpoints/02-two-endpoints -->
```text
$ git diff --stat main feat/report
 scorekit/config.py | 1 -
 scorekit/report.py | 7 +++++++
 scorekit/runner.py | 3 +++
 3 files changed, 10 insertions(+), 1 deletion(-)
$ git diff --stat main..feat/report
 scorekit/config.py | 1 -
 scorekit/report.py | 7 +++++++
 scorekit/runner.py | 3 +++
 3 files changed, 10 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

Three dots, and the same comparison spelled out with `git merge-base`:

<!-- snippet: ch14a/diff-endpoints/03-three-dots -->
```text
$ git diff --stat main...feat/report
 README.md          | 2 ++
 scorekit/report.py | 7 +++++++
 scorekit/runner.py | 3 +++
 3 files changed, 12 insertions(+)
$ git diff --stat $(git merge-base main feat/report) feat/report
 README.md          | 2 ++
 scorekit/report.py | 7 +++++++
 scorekit/runner.py | 3 +++
 3 files changed, 12 insertions(+)
```
<!-- /snippet -->

The two results disagree about two files. Each disagreement is worth reading.

<!-- snippet: ch14a/diff-endpoints/04-config -->
```text
# Two endpoints: the line that main added after the fork shows up as a deletion.
$ git diff main feat/report -- scorekit/config.py
diff --git a/scorekit/config.py b/scorekit/config.py
index 12c95c2..5efef40 100644
--- a/scorekit/config.py
+++ b/scorekit/config.py
@@ -1,3 +1,2 @@
 # Thresholds used by the runner.
 PASS_MARK = 0.75
-NIGHTLY_PASS_MARK = 0.6
# Three dots: the branch never touched the file.
$ git diff main...feat/report -- scorekit/config.py
```
<!-- /snippet -->

`feat/report` never touched `scorekit/config.py`. `main` added a line after the fork. Going from the tree of `main` to the tree of the branch, that line is absent, so the two-endpoint diff prints it as a deletion. This is question 4 of section 14A.1: the reviewer compared tips and read `main`'s own progress, reversed, as part of the feature.

<!-- snippet: ch14a/diff-endpoints/05-readme -->
```text
# The README paragraph was cherry-picked to main. Both tips have it, the merge base does not.
$ git diff --stat main feat/report -- README.md
$ git diff main...feat/report -- README.md
diff --git a/README.md b/README.md
index bfae817..08f9933 100644
--- a/README.md
+++ b/README.md
@@ -5,3 +5,5 @@ Scores model answers against reference answers.
     python3 -m scorekit.runner data/smoke.jsonl
 
 The runner prints one score line and exits with status 1 when exact_match is below the pass mark.
+
+The nightly job runs the same command on data/nightly.jsonl.
```
<!-- /snippet -->

The README paragraph is the opposite case. It was written on the branch and then cherry-picked to `main` ([Chapter 10](ch10-cherry-pick.md)). Both tips contain it, so the tips do not differ. The merge base does not contain it, so the three-dot diff shows it as a change of the branch, although `main` already has it.

**Picture.**

```text
                    a8e8550---f37a7d8---a10f9a1   feat/report
                   /
  ...---ca7e2b7---2652768---e376e5b               main   (HEAD -> main)
        (merge base)

  git diff main feat/report      compares  e376e5b  with  a10f9a1   (two tips)
  git diff main...feat/report    compares  ca7e2b7  with  a10f9a1   (merge base and right tip)
  git diff feat/report...main    compares  ca7e2b7  with  e376e5b   (merge base and the other tip)
```

**In production.** Review a branch with three dots: "what does this branch introduce", independent of what the target did meanwhile. Use two endpoints for "how do these two trees differ right now", for example a release tag against the deployed commit. Lab 10.4 has you predict both.

> **GitHub, not Git.** The "Files changed" tab of a pull request shows a three-dot diff, from the merge base to the head of the pull request branch ([GitHub Docs: three-dot and two-dot comparisons](https://docs.github.com/en/pull-requests/reference/branches#three-dot-and-two-dot-git-diff-comparisons)). That is why a pull request whose branch is behind its base does not show the base's newer commits as deletions, and why a change that reached the base by another route, as the README paragraph did, still appears in it until the branch is merged with or rebased onto the base.

```text
Observed behavior : "git diff main feature" shows a setting being deleted that the feature never touched
Git state         : main gained commits after the branch forked; the feature's tip does not contain them
Mechanism         : A B (and A..B) compare the trees of the two tips, in the direction A to B
Root cause        : what main added after the fork is absent from the feature's tree, so it prints as "-"
Why Git does this : diff takes two endpoints; it does not look at ancestry unless asked (three dots)
Correct fix       : git diff main...feature, or git diff --merge-base main feature
Prevention        : three dots for review; in scripts the explicit --merge-base spelling
```

One more form is useful in forensics: the operands may be trees or blobs, addressed as `<rev>:<path>`. No checkout is needed to compare a directory, or one file, between two releases:

<!-- snippet: ch14a/diff-endpoints/07-trees-and-blobs -->
```text
$ git diff --stat v0.1.0:scorekit main:scorekit
 __init__.py |  2 +-
 bleu.py     | 15 ---------------
 config.py   |  3 ++-
 metrics.py  | 24 ++++++++++--------------
 rouge.py    | 23 +++++++++++++++++++++++
 runner.py   | 31 +++++++++++++++++++++++--------
 text.py     | 12 ++++++++++++
 7 files changed, 71 insertions(+), 39 deletions(-)
$ git diff v0.1.0:scorekit/config.py main:scorekit/config.py
diff --git a/scorekit/config.py b/scorekit/config.py
index c22ffa6..12c95c2 100644
--- a/scorekit/config.py
+++ b/scorekit/config.py
@@ -1,2 +1,3 @@
 # Thresholds used by the runner.
-PASS_MARK = 0.7
+PASS_MARK = 0.75
+NIGHTLY_PASS_MARK = 0.6
```
<!-- /snippet -->

## 14A.3 Summaries and filters: `--stat`, `--name-only`, `--name-status`, `--diff-filter`

A patch between two releases can run to thousands of lines. Start with a summary and descend from there. All of these options work with `git diff`, `git show` and `git log` alike, because the three share one diff machinery.

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

`--stat` draws one line per file with a scaled histogram of added and removed lines. `--shortstat` keeps only the total. `--numstat` prints the same numbers unscaled and tab-separated, the form for scripts: added, removed, path.

`--name-only` lists paths. `--name-status` adds one letter per path:

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

| Letter | Meaning | Letter | Meaning |
|---|---|---|---|
| `A` | added | `R<nn>` | renamed, with a similarity index (section 14A.4) |
| `D` | deleted | `C<nn>` | copied, with a similarity index |
| `M` | content or mode modified | `T` | type changed (file, symlink, submodule) |
| `U` | unmerged | | |

`--diff-filter` selects by those letters. An uppercase letter includes, a lowercase letter excludes:

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

`--diff-filter=D` with `git log` is the standard way to find when a file was deleted (section 14A.13). A pathspec after `--` narrows any of these, including the exclusion form:

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

## 14A.4 Renames and copies are computed: `-M` and `-C`

**In one sentence.** A commit does not say "this file was renamed"; `git diff` notices that a path disappeared, another appeared, and their contents are similar enough.

**Precisely.** Rename detection is a pass over the list of changed paths ([gitdiffcore](https://git-scm.com/docs/gitdiffcore)). A deleted path and an added path with the same blob ID are an exact rename. For the remaining pairs Git computes a similarity index, and a pair at or above the threshold becomes a rename. The threshold is 50% by default; `-M<n>` changes it (`-M90%`), and `--no-renames` switches the pass off. For the porcelain commands the pass is on by default (`diff.renames`, default `true`). `-C` also looks for copies, with the sources limited to files that the same commit modified; `--find-copies-harder`, or `-C` given twice, considers every file of the older tree and costs accordingly.

**See it.** Between commit `d369eac` and `v0.1.0` the sources moved into a package, one module was renamed a second time, and two files were edited on the way:

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

`R100` is an exact rename: two commits moved `scorer.py` twice and never changed it, and the diff of the endpoints sees one rename. `R090` and `R082` are renames with edits. Without the pass, the same comparison is a list of unrelated deletions and additions:

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

The threshold decides. At 90% the runner, whose similarity is 82%, is no longer a rename:

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

In a patch, a detected rename is printed as extended header lines, and only the changed lines follow:

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

Copies need the harder search when the source file was not modified by the same commit. Here Asha seeded the nightly data set from the smoke set:

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

`-C` alone finds nothing, because `data/smoke.jsonl` itself did not change in that commit. `--find-copies-harder` finds the copy with a similarity of 71% and reduces fourteen added lines to the four that are new.

**The limit.** Similarity is a heuristic over content. Rename a file and rewrite half of it in the same commit, and the link is gone:

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

`git status` prints a deletion and an addition, because it uses the default threshold and this pair is 43% similar. A lower threshold still finds it, but nobody reading the log later will think to pass `-M40%`. Everything that relies on rename detection inherits this limit: `git log --follow` (section 14A.10), `git blame` (section 14A.18) and the rename handling of `git merge` ([Chapter 8](ch08-merge.md)).

**In production.** Rename in one commit, edit in the next. A commit that only moves files shows `R100` everywhere, reviews in seconds, and keeps every history tool working. Lab 11.1 breaks this rule on purpose and repairs it. Two more limits matter on large changes: the inexact comparison is quadratic in the number of unpaired files and is skipped above `diff.renameLimit` candidates (1000 by default according to the local manual), and a directory move with hundreds of edited files can therefore degrade to deletions and additions.

## 14A.5 Reading through noise: `-w` and `--word-diff`

Two kinds of change bury the lines you are looking for: whitespace, and small edits inside long lines.

Commit `9c8df98` ran a formatter over the sources. Its patch touches 40 lines. With `-w` (`--ignore-all-space`), lines that differ only in whitespace are treated as equal:

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

Two files drop out entirely: their only change was the indentation. Eleven lines remain, and `-w` shows what they are:

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

The formatter also replaced single quotes with double quotes. That is not whitespace, so `-w` cannot hide it. Remember this split: it returns in section 14A.17, where `git blame -w` sees through the indentation and needs a different option for the quotes.

| Option | Ignores |
|---|---|
| `--ignore-space-at-eol` | whitespace changes at the end of a line |
| `-b`, `--ignore-space-change` | changes in the amount of whitespace |
| `-w`, `--ignore-all-space` | all whitespace, including whitespace where the other side has none |
| `--ignore-blank-lines` | changes whose lines are all blank |
| `-I<regex>` | changes whose lines all match the expression |

For prose, configuration strings and long lines, a line-based diff says "this line changed" and leaves the comparison to your eyes:

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

`--word-diff` compares words and marks them in place, removed text as `[-...-]` and added text as `{+...+}`:

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

Words are runs of non-whitespace by default; `--word-diff-regex=<regex>` defines them differently, for example to split on punctuation. `--color-words` is the same comparison shown with colors only, for the terminal. The output of `--word-diff` is for reading, not for `git apply`.

## 14A.6 Diff algorithms, and `--check`

**In one sentence.** For two given files there are many correct diffs, and the algorithm decides which one you read.

**Precisely.** A diff is a set of deletions and insertions that turns one file into the other. Git has four algorithms ([git-diff](https://git-scm.com/docs/git-diff)): `myers`, the default, "the basic greedy diff algorithm"; `minimal`, which spends extra time to produce the smallest diff; `patience`; and `histogram`, which "extends the patience algorithm to support low-occurrence common elements". The last two anchor on lines that occur rarely, which tends to keep moved blocks together. Choose with `--diff-algorithm=<name>` (or `--minimal`, `--patience`, `--histogram`) and make the choice permanent with `diff.algorithm`.

**See it.** One file, two similar functions, and an edit that swaps them:

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

Myers found the shortest edit: six lines out, six lines in. It is correct, and it tells a false story, that someone edited both functions line by line. Histogram tells what happened:

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

The line counts differ as well:

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

**In production.** Three consequences. First, "lines changed" is a property of the algorithm, not of the commit, so two tools can report different numbers for the same pull request. Second, a patch is still valid under any algorithm: all of them transform the same old file into the same new file. Third, the algorithm changes what `git blame` and `git log -L` attribute (both run diffs internally; `git blame` accepts `--diff-algorithm`). Many teams set `diff.algorithm=histogram`; the `ort` merge strategy already uses histogram internally ([merge strategies](https://github.com/git/git/blob/v2.56.0/Documentation/merge-strategies.adoc)).

`--check` is not about reading diffs at all. It inspects the lines a diff adds and reports whitespace errors and leftover conflict markers, with an exit status a script can test:

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

By default, trailing whitespace and a space before a tab in the indentation count as errors; `core.whitespace` adjusts the rules. As with every `git diff` form, which changes are inspected depends on the operands:

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

After `git add -A` the unstaged diff is empty, so the first command finds nothing. `git diff --cached --check` inspects what the next commit would record. That is the form for a pre-commit hook ([Chapter 14C](ch14c-stash-rerere-attributes-hooks.md)), and with two commits as operands it is the form for continuous integration.

## 14A.7 Naming one commit: revision selection

Every investigation command takes revisions as arguments. [Chapter 3](ch03-git-internals.md), section 3.6, showed how `git rev-parse` turns a name into an object ID, and [Chapter 7](ch07-branches.md) introduced `@{-1}` and `@{upstream}`. This section is the working set for forensics, from [gitrevisions](https://git-scm.com/docs/gitrevisions).

| Form | Names | Read from |
|---|---|---|
| `<rev>~<n>` | the n-th ancestor, following first parents only | the graph |
| `<rev>^`, `<rev>^<n>` | the first parent, the n-th parent | the graph |
| `<ref>@{<n>}` | the value that ref had n updates ago | your reflog |
| `<ref>@{<date>}` | the value that ref had at that time in this repository | your reflog |
| `@{u}`, `<branch>@{upstream}` | the remote-tracking branch the branch is set to follow | configuration |
| `:/<text>` | the youngest commit, reachable from any ref, whose message matches the regular expression | all refs |
| `<rev>^{/<text>}` | the youngest such commit reachable from `<rev>` | the graph |
| `<rev>^{}`, `^{commit}`, `^{tree}` | the object after peeling tags; the commit; its tree | objects |
| `<rev>:<path>` | the blob or tree at that path in that revision | objects |
| `:<path>`, `:<n>:<path>` | the index entry for the path, at stage 0 or stage n | the index |

Three of these deserve a transcript. First, `^<n>` chooses among the parents of one commit, and `~<n>` walks n generations back along first parents; the difference shows on merges. `8657273` is the merge of `feat/text-utils`:

<!-- snippet: ch14a/revisions/01b-merge-parents -->
```text
# 8657273 is the merge of feat/text-utils. ^1 and ^2 choose a parent; ~1 always follows the first parent.
$ git rev-parse 8657273^1 8657273~1 8657273^2 8657273^2~1
389337aa37f6f099b27867f23fdf426b5c0307bd
389337aa37f6f099b27867f23fdf426b5c0307bd
c0d33a57b14ce8f345d5cf625ec8500fd30d85a5
dd70d9e494fe1312ef1f62b858ada29744f9edbe
$ git show -s --format='%h %s' 8657273^1 8657273^2 8657273^2~1
389337a Raise the pass mark to 0.75
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
```
<!-- /snippet -->

`^1` and `~1` are the same commit, the first parent, which is the branch that was merged into. `^2` is the tip of the branch that was merged in, and `^2~1` walks one step back on that side.

Second, the reflog forms read your local reflog and nothing else:

<!-- snippet: ch14a/revisions/02-reflog -->
```text
$ git show -s --format='%h %s' 'HEAD@{1}' 'main@{2}'
e376e5b Mention the nightly run in the README
2652768 Add a separate pass mark for the nightly set
$ git show -s --format='%h %cd %s' --date=format:'%a %H:%M' 'main@{yesterday}'
d9d075d Mon 12:31 Remove the experimental BLEU scorer
```
<!-- /snippet -->

`main@{yesterday}` does not mean "the commit made yesterday". It means "what `main` pointed at in this clone 24 hours ago", here a commit from Monday 12:31, because the lab clock stands at Tuesday shortly before 13:00. On a teammate's machine, or in a fresh clone whose reflog starts today, the same expression gives a different answer or a warning. Use reflog forms to investigate your own repository ([Chapter 13](ch13-recovery.md)); use dates with `git log --since` to investigate the project.

Third, searching by message:

<!-- snippet: ch14a/revisions/04-search -->
```text
$ git show -s --format='%h %s' ':/Reformat sources'
9c8df98 Reformat sources: four-space indent, double quotes
$ git show -s --format='%h %s' 'v0.2.0^{/pass mark}'
389337a Raise the pass mark to 0.75
$ git show -s --format='%h %s' ':/nightly run'
e376e5b Mention the nightly run in the README
```
<!-- /snippet -->

`:/nightly run` matches two commits in this repository, the original on `feat/report` and its copy on `main`. The rule "youngest, from any ref" picked the copy. `<rev>^{/<text>}` restricts the search to the ancestors of one revision and is the form to use in scripts.

An annotated tag is an object of its own, so the tag name and the commit it marks have different IDs. `^{}` peels:

<!-- snippet: ch14a/revisions/05-peel -->
```text
$ git cat-file -t v0.1.0
tag
$ git rev-parse v0.1.0 v0.1.0^{} v0.1.0^{commit} v0.1.0^{tree}
2b135670afee8cdfbb883de84523a5c97a25d914
682bc717015f0ab43b873d1df1ac9da0ba01c393
682bc717015f0ab43b873d1df1ac9da0ba01c393
2d7515ae10f361f36e63b9496cd27f732f656c01
$ git rev-parse v0.1.0^0
682bc717015f0ab43b873d1df1ac9da0ba01c393
```
<!-- /snippet -->

Commands that need a commit peel for you. You need the suffix when you compare IDs, as in "is the tag still on the commit we deployed". Paths select inside a revision:

<!-- snippet: ch14a/revisions/06-paths -->
```text
$ git rev-parse main:scorekit/config.py v0.1.0:scorekit/config.py :scorekit/config.py
12c95c24c2ec9a14f3b6770dc3cf21994a1fd054
c22ffa6cffb75db7b502a54f0e0d158689414374
12c95c24c2ec9a14f3b6770dc3cf21994a1fd054
$ git show v0.1.0:scorekit/config.py
# Thresholds used by the runner.
PASS_MARK = 0.7
$ git cat-file -t main:scorekit
tree
```
<!-- /snippet -->

`@{u}` resolves through the upstream configuration ([Chapter 12](ch12-remote-operations.md)); `@{u}..` is then "my commits that the remote-tracking branch does not have":

<!-- snippet: ch14a/revisions/03-upstream -->
```text
$ git rev-parse --abbrev-ref @{u}
origin/main
$ git show -s --format='%h %s' @{u}
e376e5b Mention the nightly run in the README
$ git log --oneline @{u}..
fd9fa62 Start the 0.3 cycle
```
<!-- /snippet -->

## 14A.8 Naming sets of commits: ranges

**In one sentence.** A range is a set of commits defined by reachability: everything you can reach from the included tips, minus everything you can reach from the excluded ones.

**Analogy.** Colour every commit reachable from B green, then colour every commit reachable from A red, red winning. `A..B` is what stays green. The picture breaks if you think of "between": a range is not an interval on a line, and with merges in the graph the green set can contain commits made long before A.

**Precisely.** For history-walking commands, one revision means "this commit and all its ancestors", and several revisions mean the union. A leading `^` excludes a commit and its ancestors. The dotted forms are shorthands ([gitrevisions](https://git-scm.com/docs/gitrevisions)):

| Form | Selects for `git log` and `git rev-list` | What `git diff` does with the same text |
|---|---|---|
| `B` | B and every ancestor of B | compares the working tree with B |
| `^A B`, `B --not A`, `A..B` | reachable from B and not from A | compares the trees of A and B |
| `A...B` | reachable from A or B, not from both | compares the merge base with B |
| `A^!` | A alone: A minus all its parents | compares A's parent with A |
| `A^@` | all parents of A, and their ancestors | (used as `git diff A A^@` for a merge) |
| `A^-` | `A^1..A`: A and, if A is a merge, everything the merge brought in | compares A's first parent with A |
| `--all`, `--branches`, `--tags`, `--remotes` | every ref of that kind as a starting tip | not applicable |

An omitted side means HEAD: `origin/main..` is `origin/main..HEAD`.

**Inside `.git`.** Nothing changes. Git walks parent pointers from the tips, marks what is reachable from the excluded side, and stops descending where both colours meet. On a large repository the commit-graph file makes this walk fast ([Chapter 26](ch26-performance.md)).

**See it.** Three spellings of one set, and its mirror image:

<!-- snippet: ch14a/ranges/01-two-dots -->
```text
$ git log --oneline main..feat/report
a10f9a1 Write a report when --report <path> is given
f37a7d8 Mention the nightly run in the README
a8e8550 Add per-row report writer
$ git log --oneline ^main feat/report
a10f9a1 Write a report when --report <path> is given
f37a7d8 Mention the nightly run in the README
a8e8550 Add per-row report writer
$ git log --oneline feat/report --not main
a10f9a1 Write a report when --report <path> is given
f37a7d8 Mention the nightly run in the README
a8e8550 Add per-row report writer
```
<!-- /snippet -->

<!-- snippet: ch14a/ranges/02-other-way -->
```text
$ git log --oneline feat/report..main
e376e5b Mention the nightly run in the README
2652768 Add a separate pass mark for the nightly set
```
<!-- /snippet -->

The symmetric difference is the union of the two. `--left-right` says which side each commit is on, and `--boundary` adds the commit where the walk stopped, marked `o`:

<!-- snippet: ch14a/ranges/03-three-dots -->
```text
$ git log --oneline main...feat/report
e376e5b Mention the nightly run in the README
2652768 Add a separate pass mark for the nightly set
a10f9a1 Write a report when --report <path> is given
f37a7d8 Mention the nightly run in the README
a8e8550 Add per-row report writer
$ git log --oneline --left-right main...feat/report
< e376e5b Mention the nightly run in the README
< 2652768 Add a separate pass mark for the nightly set
> a10f9a1 Write a report when --report <path> is given
> f37a7d8 Mention the nightly run in the README
> a8e8550 Add per-row report writer
$ git log --oneline --graph --boundary main...feat/report
* e376e5b Mention the nightly run in the README
* 2652768 Add a separate pass mark for the nightly set
| * a10f9a1 Write a report when --report <path> is given
| * f37a7d8 Mention the nightly run in the README
| * a8e8550 Add per-row report writer
|/  
o ca7e2b7 Fail fast on an empty reference
```
<!-- /snippet -->

The parent shorthands, on the merge commit:

<!-- snippet: ch14a/ranges/05-parents -->
```text
$ git rev-parse 8657273^@
389337aa37f6f099b27867f23fdf426b5c0307bd
c0d33a57b14ce8f345d5cf625ec8500fd30d85a5
$ git log --oneline 8657273^!
8657273 Merge branch 'feat/text-utils'
$ git log --oneline 8657273^-
8657273 Merge branch 'feat/text-utils'
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
$ git log --oneline 8657273^1..8657273
8657273 Merge branch 'feat/text-utils'
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
```
<!-- /snippet -->

`8657273^-` is the answer to "what did this merge bring in": the merge itself and the two commits of the side branch. For an ordinary commit, `A^!` gives `git diff` the pair that `git show` uses:

<!-- snippet: ch14a/ranges/06-one-commit-diff -->
```text
$ git diff --stat ec4fad7^!
 scorekit/metrics.py | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)
$ git diff --stat ec4fad7~1 ec4fad7
 scorekit/metrics.py | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)
```
<!-- /snippet -->

**Picture.** The same graph, three questions:

```text
                    a8e8550---f37a7d8---a10f9a1   feat/report
                   /
  ...---ca7e2b7---2652768---e376e5b               main

  main..feat/report    = { a8e8550, f37a7d8, a10f9a1 }                    what the branch has that main lacks
  feat/report..main    = { 2652768, e376e5b }                             what main has that the branch lacks
  main...feat/report   = { 2652768, e376e5b, a8e8550, f37a7d8, a10f9a1 }  both of the above
  git diff main..feat/report    compares the trees of e376e5b and a10f9a1
  git diff main...feat/report   compares the trees of ca7e2b7 and a10f9a1
```

**In production.** `git log --oneline origin/main..HEAD` before a push is "what am I about to publish". `git log --oneline HEAD..origin/main` after a fetch is "what will a merge bring me". An empty `A..B` means B is an ancestor of A, which is the test `git merge-base --is-ancestor` performs:

<!-- snippet: ch14a/ranges/07-empty-range -->
```text
$ git log --oneline main..v0.2.0
$ git merge-base --is-ancestor v0.2.0 main && echo "v0.2.0 is an ancestor of main"
v0.2.0 is an ancestor of main
```
<!-- /snippet -->

And one query lists all unmerged work in a repository:

<!-- snippet: ch14a/ranges/04-several -->
```text
# Everything that is on some branch and not yet in main, in one query:
$ git log --oneline --branches --not main
a10f9a1 Write a report when --report <path> is given
f37a7d8 Mention the nightly run in the README
a8e8550 Add per-row report writer
2f2883f Report ROUGE-L in the runner
80ee55f Add ROUGE-L F-measure
1cbe38a Add longest-common-subsequence helper
$ git rev-list --count v0.1.0..main
20
```
<!-- /snippet -->

`feat/rouge-l` appears here although its content is on `main`: it was squash-merged, and a squash creates a new commit that has no parent link to the branch (section 14A.18). The graph knows ancestry, not content.

## 14A.9 `git log` is a graph query

**In one sentence.** 🟢 `git log` walks the graph from the tips you name, filters the commits it meets, and prints each survivor in the format you choose.

**Analogy.** A database query: `FROM` is the set of commits (section 14A.8), `WHERE` is the filter, `ORDER BY` is the ordering, `SELECT` is the output format. The analogy breaks in two places. There is no index on authors or messages, so every filter is a scan of the walked commits. And the default order is by commit date, newest first; only `--topo-order`, which `--graph` implies, guarantees that no parent is printed before all of its children.

**Precisely.** Think in four stages, and place every option in one of them.

| Stage | Question | Options |
|---|---|---|
| 1. Walk | Which commits are visited? | revisions and ranges, `--all`, `--branches`, `--reflog`, `--first-parent`, `--ancestry-path` |
| 2. Filter | Which visited commits are shown? | `--author`, `--committer`, `--grep`, `--since`, `--until`, `--merges`, `--no-merges`, `-S`, `-G`, `-- <path>`, `--diff-filter`, `-<n>` |
| 3. Order | In which sequence? | `--date-order`, `--topo-order`, `--author-date-order`, `--reverse` |
| 4. Print | What is printed per commit? | `--oneline`, `--format`, `--graph`, `--decorate`, `--stat`, `-p`, `--name-status` |

`--graph --oneline --decorate --all`, the command from section 14A.1, is one option from each of stages 1, 3 and 4: walk from every ref, order topologically and draw the edges, print one line with ref names.

**See it: the walk.** Part of the history has a side branch:

<!-- snippet: ch14a/log-graph/01-graph-range -->
```text
$ git log --graph --oneline 8e2cac1~1..8657273
*   8657273 Merge branch 'feat/text-utils'
|\  
| * c0d33a5 Add a tokens helper and use it in the metrics
| * dd70d9e Move normalize into scorekit/text.py
* | 389337a Raise the pass mark to 0.75
* | 4da82b5 Document the metrics
* | b4b066b Skip rows with an empty reference
|/  
* 8e2cac1 Strip punctuation before comparing
```
<!-- /snippet -->

`--first-parent` follows only the first parent of every merge. On a branch that receives work through merges it shows the sequence of things that landed, and hides the commits inside each landed branch:

<!-- snippet: ch14a/log-graph/02-first-parent -->
```text
$ git log --oneline --first-parent 8e2cac1~1..8657273
8657273 Merge branch 'feat/text-utils'
389337a Raise the pass mark to 0.75
4da82b5 Document the metrics
b4b066b Skip rows with an empty reference
8e2cac1 Strip punctuation before comparing
```
<!-- /snippet -->

`--merges` and `--no-merges` filter by parent count. `git rev-list --count` returns the size of a set without printing it:

<!-- snippet: ch14a/log-graph/03-merges -->
```text
$ git log --oneline --merges
8657273 Merge branch 'feat/text-utils'
$ git rev-list --count v0.1.0..main
20
$ git rev-list --count --first-parent v0.1.0..main
18
$ git rev-list --count --no-merges v0.1.0..main
19
```
<!-- /snippet -->

Twenty commits since `v0.1.0`; eighteen on the first-parent line, because two arrived through the merge. Keep the number twenty: section 14A.20 turns it into the cost of a bisection. For an overview of a repository you do not know, `--simplify-by-decoration` keeps only the commits that a branch or tag points at:

<!-- snippet: ch14a/log-graph/04-decoration -->
```text
$ git log --graph --oneline --decorate --simplify-by-decoration --all
* e376e5b (HEAD -> main) Mention the nightly run in the README
| * a10f9a1 (feat/report) Write a report when --report <path> is given
|/  
* c0c9a30 (tag: v0.2.0) Add nightly evaluation set
| * 2f2883f (feat/rouge-l) Report ROUGE-L in the runner
|/  
* 682bc71 (tag: v0.1.0) Add config module with the pass mark
* 5015359 Add project skeleton
```
<!-- /snippet -->

**See it: the filters.** By person:

<!-- snippet: ch14a/log-filters/01-author -->
```text
$ git log --oneline --author=Ravi
e376e5b Mention the nightly run in the README
d9d075d Remove the experimental BLEU scorer
d926d3c Speed up normalize with a precompiled pattern
074d492 Send warnings to stderr
8e2cac1 Strip punctuation before comparing
d369eac Add experimental BLEU scorer
$ git log --format='%h %an (committed by %cn) %s' --author=Ravi --committer='Lab User'
e376e5b Ravi Menon (committed by Lab User) Mention the nightly run in the README
```
<!-- /snippet -->

`--author` and `--committer` are regular expressions matched against "Name <email>". The second command finds a commit written by one person and committed by another: the cherry-pick. By message:

<!-- snippet: ch14a/log-filters/02-grep -->
```text
$ git log --oneline --grep=crash
be9ad1b Fix crash when --limit is not given
$ git log --oneline -i --grep=rouge
d9d075d Remove the experimental BLEU scorer
7823232 Add ROUGE-L metric
$ git log --oneline -i --grep=rouge --all
d9d075d Remove the experimental BLEU scorer
7823232 Add ROUGE-L metric
2f2883f Report ROUGE-L in the runner
80ee55f Add ROUGE-L F-measure
$ git log --oneline --grep=limit --grep=crash
be9ad1b Fix crash when --limit is not given
8dc82cb Add --limit option to the runner
$ git log --oneline --grep=limit --grep=crash --all-match
be9ad1b Fix crash when --limit is not given
```
<!-- /snippet -->

Without `--all` the walk starts at HEAD, so commits that exist only on other branches are not searched. Several `--grep` options are alternatives unless `--all-match` is given. And `--grep` searches messages, not content: the BLEU removal is found only because its message mentions ROUGE-L.

By date:

<!-- snippet: ch14a/log-filters/03-dates -->
```text
$ git log --oneline --since='2026-09-10 00:00' --until='2026-09-11 00:00'
d926d3c Speed up normalize with a precompiled pattern
be9ad1b Fix crash when --limit is not given
074d492 Send warnings to stderr
8dc82cb Add --limit option to the runner
72134f3 Document the runner's exit status
$ git log --oneline --since='2 days ago'
e376e5b Mention the nightly run in the README
2652768 Add a separate pass mark for the nightly set
ca7e2b7 Fail fast on an empty reference
d9d075d Remove the experimental BLEU scorer
ec4fad7 Simplify token overlap in token_f1
```
<!-- /snippet -->

Dates have two traps. The first: `--since` and `--until` test the committer date, the time the commit object was created, not the author date ([Chapter 6](ch06-commits.md), section 6.5):

<!-- snippet: ch14a/log-filters/04-committer-date -->
```text
# --since and --until test the committer date. The newest commit was authored at 10:46 and committed at 12:41:
$ git log --format='%h authored %ad, committed %cd' --date=format:'%a %H:%M' --since='2026-09-15 12:30'
e376e5b authored Tue 10:46, committed Tue 12:41
```
<!-- /snippet -->

The second trap produces wrong answers silently:

<!-- snippet: ch14a/log-filters/03b-time-of-day -->
```text
# A date without a time takes the current time of day. The lab clock reads 12:51.
$ git log --oneline --since=2026-09-10 --until=2026-09-11
9c8df98 Reformat sources: four-space indent, double quotes
d926d3c Speed up normalize with a precompiled pattern
```
<!-- /snippet -->

```text
Observed behavior : --since=2026-09-10 --until=2026-09-11 omits four commits made on the morning of the 10th
                    and includes one made on the morning of the 11th
Git state         : nothing unusual; the commits exist and carry those dates
Mechanism         : Git's date parser took the time of day, which the argument left out, from the clock
Root cause        : "2026-09-10" was read as "10 September at the present time of day", here 12:51
Why Git does this : the same parser serves "yesterday" and "2 days ago", which are meant relative to now;
                    the manual notes only that "today" means the last midnight
Correct fix       : write the time: --since='2026-09-10 00:00' --until='2026-09-11 00:00'
Prevention        : in scripts and incident notes always give a full timestamp, and state the time zone
```

This behavior was observed on Git 2.55.0, in the transcript above; the manual page of `git log` does not describe it. A third property: `--since` stops the walk at the first commit that is too old. In a history whose commit dates are not in order, for example after an import or with a wrong clock, an old-looking commit can hide newer ones behind it; `--since-as-filter` visits the whole range instead.

By path, and with content:

<!-- snippet: ch14a/log-filters/05-paths -->
```text
$ git log --oneline -- scorekit/config.py
2652768 Add a separate pass mark for the nightly set
389337a Raise the pass mark to 0.75
682bc71 Add config module with the pass mark
$ git log --oneline v0.2.0..main -- docs scorekit/metrics.py
d9d075d Remove the experimental BLEU scorer
ec4fad7 Simplify token overlap in token_f1
```
<!-- /snippet -->

`git log -- <path>` shows the commits whose version of the path differs from their parent's. With merges in the history, the default mode also prunes side branches that did not contribute to the final content, so a change that was made and later undone on a branch may not appear; `--full-history` disables that pruning. `--stat` and `-p` add the summary or the patch to each commit and, combined with a path, show only that path's part:

<!-- snippet: ch14a/log-filters/06-stat-patch -->
```text
$ git log --stat --format='%h %s' -2 -- scorekit/config.py
2652768 Add a separate pass mark for the nightly set

 scorekit/config.py | 1 +
 1 file changed, 1 insertion(+)
389337a Raise the pass mark to 0.75

 scorekit/config.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log -p --format='%h %s' -1 -- scorekit/config.py
2652768 Add a separate pass mark for the nightly set

diff --git a/scorekit/config.py b/scorekit/config.py
index 5efef40..12c95c2 100644
--- a/scorekit/config.py
+++ b/scorekit/config.py
@@ -1,2 +1,3 @@
 # Thresholds used by the runner.
 PASS_MARK = 0.75
+NIGHTLY_PASS_MARK = 0.6
```
<!-- /snippet -->

**In production.** State the stage when you explain a query. "`git log --author=asha -5`" is "walk from HEAD, keep Asha's commits, print the first five that pass". The limit counts after the filter and before `--reverse`, so `--reverse -1` prints the newest commit, not the oldest; `git rev-list --max-parents=0 HEAD` names the root commits.

## 14A.10 The history of one file: `--follow` and its limits

`git log -- <path>` matches a path, not a file. When the file had another name, the history stops at the commit that gave it the current name:

<!-- snippet: ch14a/log-follow/01-without -->
```text
$ git log --oneline -- scorekit/metrics.py
ec4fad7 Simplify token overlap in token_f1
9c8df98 Reformat sources: four-space indent, double quotes
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
8e2cac1 Strip punctuation before comparing
18bb23e Rename the scorer module to metrics
```
<!-- /snippet -->

`--follow` runs rename detection at each step and continues under the old name:

<!-- snippet: ch14a/log-follow/02-follow -->
```text
$ git log --oneline --follow -- scorekit/metrics.py
ec4fad7 Simplify token overlap in token_f1
9c8df98 Reformat sources: four-space indent, double quotes
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
8e2cac1 Strip punctuation before comparing
18bb23e Rename the scorer module to metrics
d38a5aa Move sources into the scorekit package
bb5eb57 Add token-level F1 scorer
b250238 Add exact-match scorer
```
<!-- /snippet -->

Three more commits appear: the move into the package and the two commits from the time the file was `scorer.py`. Combined with `--diff-filter` and `--name-status`, `--follow` prints the chain of names:

<!-- snippet: ch14a/log-follow/03-names -->
```text
$ git log --follow --diff-filter=AR --name-status --format='%h %s' -- scorekit/metrics.py
18bb23e Rename the scorer module to metrics

R100	scorekit/scorer.py	scorekit/metrics.py
d38a5aa Move sources into the scorekit package

R100	scorer.py	scorekit/scorer.py
b250238 Add exact-match scorer

A	scorer.py
```
<!-- /snippet -->

The limits, all consequences of section 14A.4:

- **One path only.** `--follow` "works only for a single file" ([git-log](https://git-scm.com/docs/git-log)):

<!-- snippet: ch14a/log-follow/05-one-path -->
```text
$ git log --oneline --follow -- scorekit/metrics.py scorekit/text.py
fatal: --follow requires exactly one pathspec
[exit status: 128]
```
<!-- /snippet -->

- **The heuristic can miss.** A rename combined with a rewrite below the similarity threshold ends the trail (Lab 11.1).
- **It is not `git log` with full history semantics.** The manual says of `log.follow` that it "does not work well on non-linear history". The release notes of Git 2.56 record an improvement for histories "in which the path being tracked gets renamed differently in multiple history lines" ([RelNotes 2.56.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc)); that version was not run here.

If you know the old names, plain path limiting takes several paths and needs no heuristic:

<!-- snippet: ch14a/log-follow/04-old-names -->
```text
# Without --follow, the old names can be given as extra paths, if you know them:
$ git log --oneline -- scorekit/metrics.py scorekit/scorer.py scorer.py
ec4fad7 Simplify token overlap in token_f1
9c8df98 Reformat sources: four-space indent, double quotes
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
8e2cac1 Strip punctuation before comparing
18bb23e Rename the scorer module to metrics
d38a5aa Move sources into the scorekit package
bb5eb57 Add token-level F1 scorer
b250238 Add exact-match scorer
```
<!-- /snippet -->

## 14A.11 The pickaxe: `-S` versus `-G`

**In one sentence.** `-S<string>` finds commits that changed how many times a string occurs in a file; `-G<regex>` finds commits whose patch has an added or removed line matching a pattern.

**Analogy.** `-S` is an inventory count: it compares the number of items before and after and reports a difference. `-G` is a goods-movement ledger: it reports every delivery and removal, including the day one crate left and an identical crate arrived. The analogy breaks at files: both options look at one file at a time, so a string that moves from one file to another is reported by `-S` as well.

**Precisely.** Both are filters of stage 2 and are documented in [gitdiffcore](https://git-scm.com/docs/gitdiffcore). `-S` "detects filepairs whose preimage and postimage have different number of occurrences of the specified block of text. By definition, it will not detect in-file moves." `-G` "detects filepairs whose textual diff has an added or a deleted line that matches the given regular expression." The argument of `-S` is a literal string unless `--pickaxe-regex` is given. The argument of `-G` is always a regular expression.

**See it.** The history of the pass mark, asked both ways:

<!-- snippet: ch14a/log-pickaxe/01-S -->
```text
$ git log --oneline -S'PASS_MARK'
2652768 Add a separate pass mark for the nightly set
682bc71 Add config module with the pass mark
633e3e6 Add evaluation runner and smoke set
```
<!-- /snippet -->

<!-- snippet: ch14a/log-pickaxe/02-G -->
```text
$ git log --oneline -G'PASS_MARK'
2652768 Add a separate pass mark for the nightly set
9c8df98 Reformat sources: four-space indent, double quotes
389337a Raise the pass mark to 0.75
682bc71 Add config module with the pass mark
633e3e6 Add evaluation runner and smoke set
```
<!-- /snippet -->

`-G` reports two commits that `-S` does not. The first is the one a person asking "who changed the pass mark" wants most:

<!-- snippet: ch14a/log-pickaxe/03-why -->
```text
$ git show --format='%h %s' 389337a
389337a Raise the pass mark to 0.75

diff --git a/scorekit/config.py b/scorekit/config.py
index c22ffa6..5efef40 100644
--- a/scorekit/config.py
+++ b/scorekit/config.py
@@ -1,2 +1,2 @@
 # Thresholds used by the runner.
-PASS_MARK = 0.7
+PASS_MARK = 0.75
$ git grep -c PASS_MARK 389337a~1 389337a
389337a~1:scorekit/config.py:1
389337a~1:scorekit/runner.py:2
389337a:scorekit/config.py:1
389337a:scorekit/runner.py:2
```
<!-- /snippet -->

The value changed and the name stayed. One occurrence before, one after: for `-S` nothing happened. The line was removed and added: for `-G` it matches twice. The second extra commit is the formatter, which re-indented a line that mentions `PASS_MARK`. That is the noise `-G` brings.

| | `-S<string>` | `-G<regex>` |
|---|---|---|
| Argument | literal (regex with `--pickaxe-regex`) | regular expression |
| Reports a commit when | the number of occurrences in a file changes | an added or removed line matches |
| A line containing the string is edited, string stays | not reported | reported |
| The string moves inside one file | not reported | reported |
| Typical question | "when was this introduced, when was it removed?" | "which commits touched lines that mention this?" |
| Cost | cheap | higher: every candidate is diffed |

The regression of this chapter is a removal, so `-S` is the right tool. The call `.lower()` no longer exists in the sources:

<!-- snippet: ch14a/log-pickaxe/05-lower -->
```text
$ git log --format='%h %ad %<(10)%an %s' --date=short -S'.lower()'
d926d3c 2026-09-10 Ravi Menon Speed up normalize with a precompiled pattern
dd70d9e 2026-09-09 Asha Rao   Move normalize into scorekit/text.py
b250238 2026-09-07 Lab User   Add exact-match scorer
$ git log --format='%h %ad %<(10)%an %s' --date=short -G'\.lower\(\)'
d926d3c 2026-09-10 Ravi Menon Speed up normalize with a precompiled pattern
dd70d9e 2026-09-09 Asha Rao   Move normalize into scorekit/text.py
8e2cac1 2026-09-09 Ravi Menon Strip punctuation before comparing
b250238 2026-09-07 Lab User   Add exact-match scorer
```
<!-- /snippet -->

Three commits changed the count: the one that introduced the call, the one that moved the function to another file (one file lost an occurrence, another gained one), and `d926d3c`, where it disappeared for good. `-G` adds a fourth, which edited the line and kept the call. Add `-p` to read the evidence in the same command:

<!-- snippet: ch14a/log-pickaxe/07-with-patch -->
```text
$ git log -p --format='%h %s' -S'.lower()' -1
d926d3c Speed up normalize with a precompiled pattern

diff --git a/scorekit/text.py b/scorekit/text.py
index 48081af..3075545 100644
--- a/scorekit/text.py
+++ b/scorekit/text.py
@@ -1,10 +1,10 @@
-import string
+import re
 
-_PUNCTUATION = str.maketrans('', '', string.punctuation)
+_PUNCTUATION = re.compile(r'[^\w\s]')
 
 
 def normalize(text):
-  text = text.lower().translate(_PUNCTUATION)
+  text = _PUNCTUATION.sub('', text)
   return ' '.join(text.split())
 
 
```
<!-- /snippet -->

By default the patch shows only the files that matched; `--pickaxe-all` shows the whole commit.

**Picture.**

```text
  occurrences of ".lower()" per commit along main
  b250238   0 -> 1    reported by -S and -G     (added)
  8e2cac1   1 -> 1    reported by -G only       (line edited, call kept)
  dd70d9e   1 -> 1    reported by both          (metrics.py 1 -> 0, text.py 0 -> 1: counted per file)
  d926d3c   1 -> 0    reported by -S and -G     (removed)
```

**In production.** Search for the shortest string that is specific. A whole statement copied from an old file stops matching as soon as anyone edits its tail, and `-S` then reports that edit as the removal (Lab 11.2). The pickaxe searches only the commits of stage 1:

<!-- snippet: ch14a/log-pickaxe/08-scope -->
```text
$ git log --oneline -S'write_report'
$ git log --oneline --all -S'write_report'
a10f9a1 Write a report when --report <path> is given
a8e8550 Add per-row report writer
```
<!-- /snippet -->

Use `--all` when the code may live on another branch, and `--reflog` when it may have been rebased away (section 14A.14).

## 14A.12 Line history: `git log -L`

`git log -L` follows a range of lines backwards and prints, for each commit that touched those lines, the part of its patch that concerns them. The range is `<start>,<end>:<file>`, or `:<funcname>:<file>` for a whole function:

<!-- snippet: ch14a/log-line-history/01-function-commits -->
```text
$ git log --oneline -s -L :token_f1:scorekit/metrics.py
ec4fad7 Simplify token overlap in token_f1
9c8df98 Reformat sources: four-space indent, double quotes
c0d33a5 Add a tokens helper and use it in the metrics
bb5eb57 Add token-level F1 scorer
```
<!-- /snippet -->

`-s` suppresses the patches and leaves the list. Compare it with the nine commits of `git log --follow` on the same file in section 14A.10: four of them touched this function. The oldest one predates both renames, which `-L` followed on its own. One line works the same way:

<!-- snippet: ch14a/log-line-history/03-one-line -->
```text
$ git log --format='%h %an: %s' -L 2,2:scorekit/config.py
389337a Lab User: Raise the pass mark to 0.75

diff --git a/scorekit/config.py b/scorekit/config.py
index c22ffa6..5efef40 100644
--- a/scorekit/config.py
+++ b/scorekit/config.py
@@ -2,1 +2,1 @@
-PASS_MARK = 0.7
+PASS_MARK = 0.75
682bc71 Lab User: Add config module with the pass mark

diff --git a/scorekit/config.py b/scorekit/config.py
new file mode 100644
index 0000000..c22ffa6
--- /dev/null
+++ b/scorekit/config.py
@@ -0,0 +2,1 @@
+PASS_MARK = 0.7
```
<!-- /snippet -->

And this is the function at the centre of the regression, limited to its two most recent changes:

<!-- snippet: ch14a/log-line-history/04-function-patch -->
```text
$ git log --format='%h %an: %s' -L :normalize:scorekit/text.py -2
9c8df98 Asha Rao: Reformat sources: four-space indent, double quotes

diff --git a/scorekit/text.py b/scorekit/text.py
index 3075545..d404d86 100644
--- a/scorekit/text.py
+++ b/scorekit/text.py
@@ -6,5 +6,5 @@
 def normalize(text):
-  text = _PUNCTUATION.sub('', text)
-  return ' '.join(text.split())
+    text = _PUNCTUATION.sub("", text)
+    return " ".join(text.split())
 
 
d926d3c Ravi Menon: Speed up normalize with a precompiled pattern

diff --git a/scorekit/text.py b/scorekit/text.py
index 48081af..3075545 100644
--- a/scorekit/text.py
+++ b/scorekit/text.py
@@ -6,5 +6,5 @@
 def normalize(text):
-  text = text.lower().translate(_PUNCTUATION)
+  text = _PUNCTUATION.sub('', text)
   return ' '.join(text.split())
 
 
```
<!-- /snippet -->

Read from the bottom: Ravi's commit replaced the line that lowercased the text; the formatter then changed quotes and indentation. `-L` shows deleted lines, which `git blame` cannot (section 14A.16).

How the range is found matters. A number is a line number in the starting revision, HEAD unless you name another, not in your working tree. `:<funcname>` is a regular expression matched against the lines that Git considers function headers, the same lines it prints after `@@` in hunk headers; the range runs to the next such line. For languages where the default guess is poor, a `diff` attribute selects a language-specific pattern ([Chapter 14C](ch14c-stash-rerere-attributes-hooks.md)). The errors are explicit:

<!-- snippet: ch14a/log-line-history/05-errors -->
```text
$ git log --oneline -L 40,45:scorekit/config.py
fatal: file scorekit/config.py has only 3 lines
[exit status: 128]
$ git log --oneline -L :no_such_function:scorekit/text.py
fatal: -L parameter 'no_such_function' starting at line 1: no match
[exit status: 128]
$ git log --oneline -L 2,2:scorekit/config.py -- scorekit/config.py
fatal: -L<range>:<file> cannot be used with pathspec
[exit status: 128]
```
<!-- /snippet -->

## 14A.13 Finding a deleted file, and a file on another branch

A file that is not in the working tree cannot be opened, blamed or grepped. Its history is still there. Ask for the commits that deleted something:

<!-- snippet: ch14a/log-deleted/01-deletions -->
```text
$ git log --diff-filter=D --name-status --format="%h %ad %an: %s" --date=short
d9d075d 2026-09-14 Ravi Menon: Remove the experimental BLEU scorer

D	scorekit/bleu.py
```
<!-- /snippet -->

If you remember part of the name, a pathspec with a wildcard finds every commit that touched a matching path, under any directory it lived in:

<!-- snippet: ch14a/log-deleted/02-path-history -->
```text
$ git log --oneline -- scorekit/bleu.py
d9d075d Remove the experimental BLEU scorer
9c8df98 Reformat sources: four-space indent, double quotes
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
18bb23e Rename the scorer module to metrics
d38a5aa Move sources into the scorekit package
$ git log --oneline -- '*bleu*'
d9d075d Remove the experimental BLEU scorer
9c8df98 Reformat sources: four-space indent, double quotes
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
18bb23e Rename the scorer module to metrics
d38a5aa Move sources into the scorekit package
d369eac Add experimental BLEU scorer
```
<!-- /snippet -->

The first command shows the history under the last name, with the deletion on top. The second also reaches the commit that created the file as `bleu.py` at the top level. The `--` is required: without it Git must decide whether the word is a revision or a path, and for a file that no longer exists it gives up with "ambiguous argument". The deleting commit says why:

<!-- snippet: ch14a/log-deleted/03-why -->
```text
$ git show --stat d9d075d
commit d9d075d63dcc94ce04c8e404e06b5cc3173180c2
Author: Ravi Menon <ravi@example.com>
Date:   Mon Sep 14 12:31:00 2026 +0530

    Remove the experimental BLEU scorer
    
    Nothing imports it, and for one reference its unigram precision duplicates token_f1.
    ROUGE-L covers the use case it was added for.

 docs/metrics.md  |  1 -
 scorekit/bleu.py | 15 ---------------
 2 files changed, 16 deletions(-)
```
<!-- /snippet -->

The content lives in the parent of the deleting commit, not in the deleting commit itself:

<!-- snippet: ch14a/log-deleted/05-wrong-commit -->
```text
$ git show d9d075d:scorekit/bleu.py
fatal: path 'scorekit/bleu.py' does not exist in 'd9d075d'
[exit status: 128]
```
<!-- /snippet -->

`git show <commit>~1:<path>` prints it, and 🔴 `git restore --source=<commit>~1 -- <path>` writes it into the working tree. The label is the one [Chapter 11](ch11-reset-revert-restore.md) gives the command: it overwrites an existing file of that name without asking. Here none exists:

<!-- snippet: ch14a/log-deleted/06-restore -->
```text
$ git restore --source=d9d075d~1 -- scorekit/bleu.py
$ git status --short
?? scorekit/bleu.py
```
<!-- /snippet -->

The file comes back untracked. Git has not undone the deletion; you have a copy of old content to add or to discard. Lab 11.3 walks through the whole sequence.

A file can also be "missing" because it was never on this branch:

<!-- snippet: ch14a/log-deleted/07-other-branch -->
```text
$ git log --oneline -- scorekit/report.py
$ git log --oneline --all -- scorekit/report.py
a8e8550 Add per-row report writer
$ git branch --contains $(git log --all --format=%h -1 -- scorekit/report.py)
  feat/report
```
<!-- /snippet -->

`--all -- <path>` searches the history of every ref for the path. `git branch --contains <commit>`, with `-a` to include remote-tracking branches, then says where that commit lives.

## 14A.14 Set questions: `--left-right`, `--cherry-pick`, `--ancestry-path`, `--reflog`

**Which side has what.** [Chapter 7](ch07-branches.md) counted divergence with `--left-right --count`, and [Chapter 10](ch10-cherry-pick.md) explained patch IDs and `--cherry-mark`. For reading, `--cherry-pick` drops the commits that have an equivalent on the other side:

<!-- snippet: ch14a/log-sets/01-left-right -->
```text
$ git log --oneline --left-right main...feat/report
< e376e5b Mention the nightly run in the README
< 2652768 Add a separate pass mark for the nightly set
> a10f9a1 Write a report when --report <path> is given
> f37a7d8 Mention the nightly run in the README
> a8e8550 Add per-row report writer
$ git log --oneline --left-right --cherry-pick main...feat/report
< 2652768 Add a separate pass mark for the nightly set
> a10f9a1 Write a report when --report <path> is given
> a8e8550 Add per-row report writer
```
<!-- /snippet -->

The README commit exists on both sides as two commits with the same patch. With `--cherry-pick` both disappear, and what remains is the work that differs.

**Through which commits did a change arrive.** `dd70d9e` was made on a side branch. `dd70d9e..v0.2.0` is "everything the release has that this commit does not have", which includes commits that have nothing to do with it:

<!-- snippet: ch14a/log-sets/02-plain-range -->
```text
# dd70d9e moved normalize() into its own module, on a side branch. Everything v0.2.0 has that dd70d9e lacks:
$ git log --oneline dd70d9e..v0.2.0
c0c9a30 Add nightly evaluation set
7823232 Add ROUGE-L metric
9c8df98 Reformat sources: four-space indent, double quotes
d926d3c Speed up normalize with a precompiled pattern
be9ad1b Fix crash when --limit is not given
074d492 Send warnings to stderr
8dc82cb Add --limit option to the runner
72134f3 Document the runner's exit status
8657273 Merge branch 'feat/text-utils'
389337a Raise the pass mark to 0.75
4da82b5 Document the metrics
b4b066b Skip rows with an empty reference
c0d33a5 Add a tokens helper and use it in the metrics
```
<!-- /snippet -->

`--ancestry-path` keeps only the commits of the range that are descendants of the excluded commit, the chain along which the change travelled:

<!-- snippet: ch14a/log-sets/03-ancestry-path -->
```text
# Only the commits that are descendants of dd70d9e as well: the path the change travelled.
$ git log --oneline --ancestry-path dd70d9e..v0.2.0
c0c9a30 Add nightly evaluation set
7823232 Add ROUGE-L metric
9c8df98 Reformat sources: four-space indent, double quotes
d926d3c Speed up normalize with a precompiled pattern
be9ad1b Fix crash when --limit is not given
074d492 Send warnings to stderr
8dc82cb Add --limit option to the runner
72134f3 Document the runner's exit status
8657273 Merge branch 'feat/text-utils'
c0d33a5 Add a tokens helper and use it in the metrics
```
<!-- /snippet -->

Three commits of `main` that were made in parallel are gone. The oldest merge on that path is the merge that first carried the change onto another line:

<!-- snippet: ch14a/log-sets/04-which-merge -->
```text
$ git log --oneline --merges --ancestry-path dd70d9e..main | tail -n 1
8657273 Merge branch 'feat/text-utils'
```
<!-- /snippet -->

In a repository where every change lands through a merge commit, this is "which pull request brought this commit in". With several levels of merges, the oldest merge on the path may be a merge into another topic branch; then intersect with `--first-parent` of the target branch.

**What only the reflogs know.** After an amend or a rebase, the old commits are reachable from no branch. `--all` does not find them; `--reflog` adds every commit mentioned in any reflog as a starting tip:

<!-- snippet: ch14a/log-sets/05-reflog -->
```text
$ git log --oneline --all --grep='nightly run'
f37a7d8 Mention the nightly run in the README
$ git log --oneline --reflog --grep='nightly run'
e376e5b Mention the nightly run in the README
f37a7d8 Mention the nightly run in the README
$ git log --oneline -g -2
87f090b HEAD@{0}: commit (amend): Describe the nightly job in the README
e376e5b HEAD@{1}: cherry-pick: Mention the nightly run in the README
```
<!-- /snippet -->

The commit that the amend replaced, `e376e5b`, is found only by the second search. `--reflog` is a stage 1 option: it widens the walk, and any filter, including the pickaxe, then applies to the wider set. `-g` (`--walk-reflogs`) is different: it lists reflog entries in order, which [Chapter 13](ch13-recovery.md) uses for recovery.

## 14A.15 Output: pretty formats and `git shortlog`

[Chapter 6](ch06-commits.md), section 6.12, introduced `--format`. For investigations, a fixed one-line format with a short date and the author answers most questions at a glance:

<!-- snippet: ch14a/log-formats/01-format -->
```text
$ git log -4 --format='%h %ad %<(10,trunc)%an %s' --date=short
e376e5b 2026-09-15 Ravi Menon Mention the nightly run in the README
2652768 2026-09-15 Lab User   Add a separate pass mark for the nightly set
ca7e2b7 2026-09-14 Asha Rao   Fail fast on an empty reference
d9d075d 2026-09-14 Ravi Menon Remove the experimental BLEU scorer
$ git log -3 --format='%h %ar%x09%s'
e376e5b 2 hours ago	Mention the nightly run in the README
2652768 32 minutes ago	Add a separate pass mark for the nightly set
ca7e2b7 22 hours ago	Fail fast on an empty reference
```
<!-- /snippet -->

| Placeholder | Prints | Placeholder | Prints |
|---|---|---|---|
| `%h`, `%H` | abbreviated, full commit ID | `%s`, `%b` | subject, body |
| `%an`, `%ae` | author name, email | `%cn`, `%ce` | committer name, email |
| `%ad`, `%cd` | author date, committer date (shaped by `--date=`) | `%ar`, `%cr` | the same, relative |
| `%d` | ref names, as `--decorate` | `%p` | abbreviated parent IDs |
| `%<(N)`, `%<(N,trunc)` | pad, or pad and truncate, the next placeholder to N columns | `%(trailers:...)` | trailers of the message |

Relative dates such as "2 hours ago" are computed from the clock at the moment you run the command; paste absolute dates into a report. Trailers ([Chapter 6](ch06-commits.md), section 6.9) carry attribution that the author field cannot, such as the people behind a squash merge:

<!-- snippet: ch14a/log-formats/03-trailers -->
```text
$ git log -1 --format='%h %s%n  author: %an%n  with:   %(trailers:key=Co-authored-by,valueonly,separator=%x2C )' 7823232
7823232 Add ROUGE-L metric
  author: Lab User
  with:   Asha Rao <asha@example.com>, Ravi Menon <ravi@example.com>
```
<!-- /snippet -->

`git shortlog` groups a set of commits by person. With `-s` it counts, with `-n` it sorts by count:

<!-- snippet: ch14a/log-formats/04-shortlog -->
```text
$ git shortlog -sn HEAD
    14	Lab User
     8	Asha Rao
     6	Ravi Menon
$ git shortlog -sn --no-merges --group=author --group=trailer:co-authored-by HEAD
    13	Lab User
     9	Asha Rao
     7	Ravi Menon
```
<!-- /snippet -->

The second form adds a second grouping key, the `Co-authored-by` trailer, so Asha and Ravi are credited for the squashed commit as well. Without `-s`, shortlog is a draft of release notes:

<!-- snippet: ch14a/log-formats/05-shortlog-release -->
```text
$ git shortlog --no-merges v0.1.0..v0.2.0
Asha Rao (4):
      Move normalize into scorekit/text.py
      Add a tokens helper and use it in the metrics
      Reformat sources: four-space indent, double quotes
      Add nightly evaluation set

Lab User (7):
      Skip rows with an empty reference
      Document the metrics
      Raise the pass mark to 0.75
      Document the runner's exit status
      Add --limit option to the runner
      Fix crash when --limit is not given
      Add ROUGE-L metric

Ravi Menon (3):
      Strip punctuation before comparing
      Send warnings to stderr
      Speed up normalize with a precompiled pattern
```
<!-- /snippet -->

Commit counts measure commits. They say nothing about the size or the value of the work, and a squash-merge workflow moves the counts to whoever presses the merge button.

> **Root cause.** `git shortlog` with no revision prints nothing when its standard input is not a terminal, as in a script, a hook or a CI job: in that situation it reads a log from standard input instead of walking from HEAD ([git-shortlog](https://git-scm.com/docs/git-shortlog)). Always pass the revision.

<!-- snippet: ch14a/log-formats/06-shortlog-stdin -->
```text
# Without a revision, and with standard input that is not a terminal, shortlog reads a log from standard input:
$ git shortlog -sn < /dev/null
$ git log v0.2.0..main | git shortlog -sn
     2	Asha Rao
     2	Ravi Menon
     1	Lab User
```
<!-- /snippet -->

## 14A.16 `git blame`: what it tells you and what it does not

**In one sentence.** 🟢 `git blame` annotates every line of a file, as it is in one revision, with the commit that last changed that line.

**Analogy.** A "last edited by" column beside a document. The column is reliable about the last edit and silent about everything else: the edit before it, the paragraph that used to stand here, and whether the last editor wrote the sentence or only fixed its spacing. The analogy also breaks on "line": Git decides which old line corresponds to which new line by running a diff, so the attribution depends on how the diff aligned them.

**Precisely.** Blame starts from the file in the given revision (HEAD by default; the working tree file if it has uncommitted changes, which are attributed to "Not Committed Yet") and compares it with the same file in the parent commit. Lines that the diff shows as unchanged are passed to the parent; lines that it shows as added stay with the commit. The parent is then treated the same way, until every line has an owner. "The origin of lines is automatically followed across whole-file renames", and "the report does not tell you anything about lines which have been deleted or replaced" ([git-blame](https://git-scm.com/docs/git-blame)).

**Inside `.git`.** Nothing is written. The work is one diff per commit that touched the file, so blame on an old, busy file in a large repository takes noticeable time.

**See it.**

<!-- snippet: ch14a/blame-basics/01-file -->
```text
$ git blame scorekit/text.py
d926d3c5 (Ravi Menon 2026-09-10 13:36:00 +0530  1) import re
dd70d9e4 (Asha Rao   2026-09-09 11:01:00 +0530  2) 
9c8df982 (Asha Rao   2026-09-11 10:16:00 +0530  3) _PUNCTUATION = re.compile(r"[^\w\s]")
dd70d9e4 (Asha Rao   2026-09-09 11:01:00 +0530  4) 
dd70d9e4 (Asha Rao   2026-09-09 11:01:00 +0530  5) 
dd70d9e4 (Asha Rao   2026-09-09 11:01:00 +0530  6) def normalize(text):
9c8df982 (Asha Rao   2026-09-11 10:16:00 +0530  7)     text = _PUNCTUATION.sub("", text)
9c8df982 (Asha Rao   2026-09-11 10:16:00 +0530  8)     return " ".join(text.split())
c0d33a57 (Asha Rao   2026-09-09 13:21:00 +0530  9) 
c0d33a57 (Asha Rao   2026-09-09 13:21:00 +0530 10) 
c0d33a57 (Asha Rao   2026-09-09 13:21:00 +0530 11) def tokens(text):
9c8df982 (Asha Rao   2026-09-11 10:16:00 +0530 12)     return normalize(text).split()
```
<!-- /snippet -->

Each row: the abbreviated commit ID, the author and author date of that commit, the line number in this revision, and the line. `-s` drops author and date, `-e` shows the email, `--date=short` shortens the date. `-L` limits the output, with the same range syntax as `git log -L`:

<!-- snippet: ch14a/blame-basics/02-lines -->
```text
$ git blame -s -L 6,8 scorekit/text.py
dd70d9e4 6) def normalize(text):
9c8df982 7)     text = _PUNCTUATION.sub("", text)
9c8df982 8)     return " ".join(text.split())
$ git blame -s -L :normalize scorekit/text.py
dd70d9e4  6) def normalize(text):
9c8df982  7)     text = _PUNCTUATION.sub("", text)
9c8df982  8)     return " ".join(text.split())
c0d33a57  9) 
c0d33a57 10) 
$ git blame --date=short -L '/^def load/,+3' scorekit/runner.py
b4b066b4 (Lab User 2026-09-09  9) def load(path):
9c8df982 (Asha Rao 2026-09-11 10)     rows = []
9c8df982 (Asha Rao 2026-09-11 11)     for line in open(path):
```
<!-- /snippet -->

A revision before the path asks about an older state of the file. The extra column appears whenever a line comes from a commit in which the file had another name:

<!-- snippet: ch14a/blame-basics/04-older-revision -->
```text
$ git blame -s v0.1.0 -- scorekit/metrics.py
bb5eb57c scorer.py  1) from collections import Counter
bb5eb57c scorer.py  2) 
bb5eb57c scorer.py  3) 
b2502383 scorer.py  4) def normalize(text):
b2502383 scorer.py  5)   return ' '.join(text.lower().split())
b2502383 scorer.py  6) 
b2502383 scorer.py  7) 
b2502383 scorer.py  8) def exact_match(prediction, reference):
b2502383 scorer.py  9)   return normalize(prediction) == normalize(reference)
bb5eb57c scorer.py 10) 
bb5eb57c scorer.py 11) 
bb5eb57c scorer.py 12) def token_f1(prediction, reference):
bb5eb57c scorer.py 13)   pred = normalize(prediction).split()
bb5eb57c scorer.py 14)   ref = normalize(reference).split()
bb5eb57c scorer.py 15)   overlap = sum((Counter(pred) & Counter(ref)).values())
bb5eb57c scorer.py 16)   if overlap == 0:
bb5eb57c scorer.py 17)     return 0.0
bb5eb57c scorer.py 18)   precision = overlap / len(pred)
bb5eb57c scorer.py 19)   recall = overlap / len(ref)
bb5eb57c scorer.py 20)   return 2 * precision * recall / (precision + recall)
```
<!-- /snippet -->

With a range, blame stops at the excluded commit. Lines older than that are attributed to the boundary and marked with a caret:

<!-- snippet: ch14a/blame-basics/05-boundary -->
```text
$ git blame -s v0.1.0..main -- scorekit/config.py
^682bc71 1) # Thresholds used by the runner.
389337aa 2) PASS_MARK = 0.75
26527689 3) NIGHTLY_PASS_MARK = 0.6
```
<!-- /snippet -->

For scripts, `--porcelain` and `--line-porcelain` print full IDs and one header per attribution, including the commit before the blamed one (`previous`), the key to stepping further back:

<!-- snippet: ch14a/blame-basics/03-porcelain -->
```text
$ git blame --line-porcelain -L 7,7 scorekit/text.py
9c8df98229e009115b3044edb1181d11075ecbbb 7 7 1
author Asha Rao
author-mail <asha@example.com>
author-time 1789101960
author-tz +0530
committer Asha Rao
committer-mail <asha@example.com>
committer-time 1789101960
committer-tz +0530
summary Reformat sources: four-space indent, double quotes
previous d926d3c5a77b586297eb25335c33fed4aee6f053 scorekit/text.py
filename scorekit/text.py
	    text = _PUNCTUATION.sub("", text)
```
<!-- /snippet -->

**What blame does not tell you.**

| You want to know | Blame gives | Use instead |
|---|---|---|
| Who wrote this logic | who last changed the line, possibly a formatter or a rename of a variable | `--ignore-rev` (14A.17), `git log -L` (14A.12) |
| Who removed the line that used to be here | nothing: there is no row for a line that no longer exists | `git log -S` (14A.11), `git log -L` |
| Why it was changed | an ID | `git show <id>`: the message and the whole commit |
| Who to ask about code that arrived in a squash merge | the person who ran the merge | the trailers of the commit, or the pull request (14A.18) |
| Whether the line is the bug | nothing: the defect may be a line that is missing, or one in another file | `git bisect` (14A.20) |

The regression of this chapter shows the second row. Before commit `d926d3c`, line 7 lowercased the text. Today a different line 7 exists, and blame reports on that one:

<!-- snippet: ch14a/blame-basics/06-not-shown -->
```text
# The line that lowercased the text is gone. Blame annotates lines that exist; it has no row for it.
$ git blame -s d926d3c~1 -L 7,7 -- scorekit/text.py
dd70d9e4 7)   text = text.lower().translate(_PUNCTUATION)
$ git blame -s -L 7,7 scorekit/text.py
9c8df982 7)     text = _PUNCTUATION.sub("", text)
```
<!-- /snippet -->

**Picture.** One line of `scorekit/text.py`, and where each way of asking stops (sections 14A.17 and 14A.18 supply the options):

```text
  line 7 on main:   text = _PUNCTUATION.sub("", text)

  9c8df98  formatter: quotes changed             <- plain blame stops here
  d926d3c  Ravi: line replaced, .lower() gone    <- blame --ignore-rev 9c8df98 stops here
  dd70d9e  Asha: function moved into text.py     <- blame d926d3c~1 stops here (the older line 7)
  8e2cac1  Ravi: older line written, metrics.py  <- blame -C dd70d9e reaches this
```

**In production.** Treat a blame row as a pointer into history, never as a verdict about a person. The next command after `git blame` is `git show <id>`. Blame an old revision when the current one is uninformative: `git blame <id>~1 -- <path>` steps behind any commit, and the `previous` field of the porcelain format supplies the argument.

## 14A.17 Blame through a reformatting commit: `-w`, `--ignore-rev`, `--ignore-revs-file`

One formatter run makes blame nearly useless for a whole file. This is the loader function of the runner; Asha's commit of 11 September is the formatter run:

<!-- snippet: ch14a/blame-reformat/01-plain -->
```text
$ git blame --date=short -L '/^def load/,+7' scorekit/runner.py
b4b066b4 (Lab User 2026-09-09  9) def load(path):
9c8df982 (Asha Rao 2026-09-11 10)     rows = []
9c8df982 (Asha Rao 2026-09-11 11)     for line in open(path):
9c8df982 (Asha Rao 2026-09-11 12)         row = json.loads(line)
9c8df982 (Asha Rao 2026-09-11 13)         if not row["reference"].strip():
ca7e2b7f (Asha Rao 2026-09-14 14)             raise ValueError("empty reference in row %d" % row["id"])
9c8df982 (Asha Rao 2026-09-11 15)         rows.append(row)
```
<!-- /snippet -->

`-w` ignores whitespace when blame compares a commit with its parent. Lines that the formatter only re-indented fall through to their real origin:

<!-- snippet: ch14a/blame-reformat/02-w -->
```text
$ git blame --date=short -w -L '/^def load/,+7' scorekit/runner.py
b4b066b4 (Lab User 2026-09-09  9) def load(path):
b4b066b4 (Lab User 2026-09-09 10)     rows = []
b4b066b4 (Lab User 2026-09-09 11)     for line in open(path):
b4b066b4 (Lab User 2026-09-09 12)         row = json.loads(line)
9c8df982 (Asha Rao 2026-09-11 13)         if not row["reference"].strip():
ca7e2b7f (Asha Rao 2026-09-14 14)             raise ValueError("empty reference in row %d" % row["id"])
b4b066b4 (Lab User 2026-09-09 15)         rows.append(row)
```
<!-- /snippet -->

Line 13 stays with the formatter, because there it also changed the quotes (section 14A.5). `--ignore-rev <rev>` goes further: it removes one commit from consideration, "as if the change never happened", and blames its lines "on the previous commit that changed that line or nearby lines":

<!-- snippet: ch14a/blame-reformat/03-ignore-rev -->
```text
$ git blame --date=short --ignore-rev 9c8df98 -L '/^def load/,+7' scorekit/runner.py
b4b066b4 (Lab User 2026-09-09  9) def load(path):
b4b066b4 (Lab User 2026-09-09 10)     rows = []
b4b066b4 (Lab User 2026-09-09 11)     for line in open(path):
b4b066b4 (Lab User 2026-09-09 12)         row = json.loads(line)
b4b066b4 (Lab User 2026-09-09 13)         if not row["reference"].strip():
ca7e2b7f (Asha Rao 2026-09-14 14)             raise ValueError("empty reference in row %d" % row["id"])
b4b066b4 (Lab User 2026-09-09 15)         rows.append(row)
```
<!-- /snippet -->

Typing the option every time does not scale. A file lists the commits to ignore, one full object ID per line, with `#` comments; `--ignore-revs-file` reads it:

<!-- snippet: ch14a/blame-reformat/04-file -->
```text
$ cat .git-blame-ignore-revs
# Formatter run: four-space indent, double quotes
9c8df98229e009115b3044edb1181d11075ecbbb
$ git blame -s --ignore-revs-file .git-blame-ignore-revs scorekit/text.py
d926d3c5  1) import re
dd70d9e4  2) 
d926d3c5  3) _PUNCTUATION = re.compile(r"[^\w\s]")
dd70d9e4  4) 
dd70d9e4  5) 
dd70d9e4  6) def normalize(text):
d926d3c5  7)     text = _PUNCTUATION.sub("", text)
dd70d9e4  8)     return " ".join(text.split())
c0d33a57  9) 
c0d33a57 10) 
c0d33a57 11) def tokens(text):
c0d33a57 12)     return normalize(text).split()
```
<!-- /snippet -->

🟡 `git config set blame.ignoreRevsFile` makes it the default for this repository, and `blame.markIgnoredLines` flags every line whose attribution passed through an ignored commit with a `?`:

<!-- snippet: ch14a/blame-reformat/05-config -->
```text
$ git config set blame.ignoreRevsFile .git-blame-ignore-revs
$ git config set blame.markIgnoredLines true
$ git blame -s scorekit/text.py
d926d3c5  1) import re
dd70d9e4  2) 
?d926d3c  3) _PUNCTUATION = re.compile(r"[^\w\s]")
dd70d9e4  4) 
dd70d9e4  5) 
dd70d9e4  6) def normalize(text):
?d926d3c  7)     text = _PUNCTUATION.sub("", text)
?dd70d9e  8)     return " ".join(text.split())
c0d33a57  9) 
c0d33a57 10) 
c0d33a57 11) def tokens(text):
?c0d33a5 12)     return normalize(text).split()
```
<!-- /snippet -->

The mark is worth having. The attribution of an ignored line is a guess: Git maps it to the line of the parent that looks like its origin, and for a line that the ignored commit really introduced there is no origin (`blame.markUnblamableLines` marks those with `*`).

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git blame` with any of these options | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git config set blame.ignoreRevsFile <path>` | unchanged | unchanged | unchanged | unchanged | one key in `.git/config` | unchanged | unchanged |
| committing `.git-blame-ignore-revs` | a tracked file | as for any commit | as for any commit | moves | new objects | after a push: the file | the blame view starts to use it |

> **GitHub, not Git.** The file name is a convention, not a Git default: Git reads no ignore file unless the option or the configuration key names one. GitHub's blame view does look for a file with exactly the name `.git-blame-ignore-revs` in the root directory of the repository and hides the listed revisions ([GitHub Docs: ignore commits in the blame view](https://docs.github.com/en/repositories/working-with-files/using-files/viewing-and-understanding-files#ignore-commits-in-the-blame-view)). Using that name serves both. The configuration key is local: every clone has to set it, which is one line in a setup script.

Two failures are common enough to show. The file must contain full IDs:

<!-- snippet: ch14a/blame-reformat/06-short-id -->
```text
$ cat ../short-ids.txt
9c8df98
$ git blame -s --ignore-revs-file ../short-ids.txt -L 6,8 scorekit/text.py
fatal: invalid object name: 9c8df98
[exit status: 128]
```
<!-- /snippet -->

And once the key is set, the file must exist in every commit you visit. Check out a commit that predates the file, and blame fails:

<!-- snippet: ch14a/blame-reformat/07-missing-file -->
```text
# The list is committed on main. An older commit does not have the file:
$ git switch --detach --quiet v0.2.0
$ git blame -s -L 6,8 scorekit/text.py
fatal: could not open object name list: .git-blame-ignore-revs
[exit status: 128]
$ git blame -s --ignore-revs-file "" -L 6,8 scorekit/text.py
fatal: could not open object name list: .git-blame-ignore-revs
[exit status: 128]
```
<!-- /snippet -->

An empty `--ignore-revs-file ""` clears the list of revisions; it does not stop Git from opening the configured file. The local manual documents a prefix for path-valued settings: with `:(optional)`, "the configuration variable is treated as if it does not exist, if the named path does not exist" ([git-config](https://git-scm.com/docs/git-config)):

<!-- snippet: ch14a/blame-reformat/08-optional -->
```text
$ git config set blame.ignoreRevsFile ':(optional).git-blame-ignore-revs'
$ git blame -s -L 6,8 scorekit/text.py
dd70d9e4 6) def normalize(text):
9c8df982 7)     text = _PUNCTUATION.sub("", text)
9c8df982 8)     return " ".join(text.split())
$ git switch --quiet main
$ git blame -s -L 6,8 scorekit/text.py
dd70d9e4 6) def normalize(text):
?d926d3c 7)     text = _PUNCTUATION.sub("", text)
?dd70d9e 8)     return " ".join(text.split())
```
<!-- /snippet -->

At `v0.2.0` blame runs and nothing is ignored; back on `main` the list applies again.

**In production.** List only commits that change no behavior: formatter runs, mass renames of a symbol, license header updates. Listing a commit that also changed logic hides that logic from blame. Rebasing or squashing the listed commit changes its ID and silently empties the entry, so add the ID after the commit has reached the shared branch.

## 14A.18 Blame and moved code: renames, `-M`, `-C`, and squash merges

A rename of the whole file does not disturb blame. `scorekit/metrics.py` was `scorer.py` when most of its lines were written, and blame says so in a column of its own:

<!-- snippet: ch14a/blame-moves/01-rename -->
```text
$ git blame -s -w scorekit/metrics.py
c0d33a57 scorekit/metrics.py  1) from scorekit.text import normalize, tokens
b2502383 scorer.py            2) 
b2502383 scorer.py            3) 
b2502383 scorer.py            4) def exact_match(prediction, reference):
b2502383 scorer.py            5)     return normalize(prediction) == normalize(reference)
bb5eb57c scorer.py            6) 
bb5eb57c scorer.py            7) 
bb5eb57c scorer.py            8) def token_f1(prediction, reference):
c0d33a57 scorekit/metrics.py  9)     pred = tokens(prediction)
c0d33a57 scorekit/metrics.py 10)     ref = tokens(reference)
ec4fad75 scorekit/metrics.py 11)     overlap = len(set(pred) & set(ref))
bb5eb57c scorer.py           12)     if overlap == 0:
bb5eb57c scorer.py           13)         return 0.0
bb5eb57c scorer.py           14)     precision = overlap / len(pred)
bb5eb57c scorer.py           15)     recall = overlap / len(ref)
bb5eb57c scorer.py           16)     return 2 * precision * recall / (precision + recall)
```
<!-- /snippet -->

Code that moves between files is different. Commit `dd70d9e` cut `normalize()` out of `metrics.py` and pasted it into a new file. To plain blame, a new file is new lines:

<!-- snippet: ch14a/blame-moves/02-moved-between-files -->
```text
# dd70d9e moved normalize() from scorekit/metrics.py into the new file scorekit/text.py.
$ git blame -s dd70d9e -- scorekit/text.py
dd70d9e4 1) import string
dd70d9e4 2) 
dd70d9e4 3) _PUNCTUATION = str.maketrans('', '', string.punctuation)
dd70d9e4 4) 
dd70d9e4 5) 
dd70d9e4 6) def normalize(text):
dd70d9e4 7)   text = text.lower().translate(_PUNCTUATION)
dd70d9e4 8)   return ' '.join(text.split())
$ git blame -s -C dd70d9e -- scorekit/text.py
dd70d9e4 scorekit/text.py    1) import string
bb5eb57c scorer.py           2) 
8e2cac1a scorekit/metrics.py 3) _PUNCTUATION = str.maketrans('', '', string.punctuation)
8e2cac1a scorekit/metrics.py 4) 
bb5eb57c scorer.py           5) 
b2502383 scorer.py           6) def normalize(text):
8e2cac1a scorekit/metrics.py 7)   text = text.lower().translate(_PUNCTUATION)
8e2cac1a scorekit/metrics.py 8)   return ' '.join(text.split())
```
<!-- /snippet -->

With `-C`, blame also searches the other files that the commit modified for the origin of the lines, and attributes them to the commits that wrote them there. The options form a ladder of cost:

| Option | Additionally looks for the origin of a line in | Minimum match |
|---|---|---|
| `-M` | other places of the same file: lines moved or copied within it | 20 alphanumeric characters |
| `-C` | files modified in the same commit | 40 alphanumeric characters |
| `-C -C` | also every file of the parent, for commits that create the blamed file | 40 |
| `-C -C -C` | every file of the parent, in every commit | 40 |

The minimum is why moved code is sometimes not recognized. After later edits, only short fragments of the moved block survive in today's file, and the default threshold rejects them; a lower one, given as `-C<num>`, accepts one:

<!-- snippet: ch14a/blame-moves/03-threshold -->
```text
# Today only two short lines of that move are left unchanged. -C wants 40 alphanumeric characters.
$ git blame -s -C --ignore-rev 9c8df98 -L 6,8 scorekit/text.py
dd70d9e4 6) def normalize(text):
d926d3c5 7)     text = _PUNCTUATION.sub("", text)
dd70d9e4 8)     return " ".join(text.split())
$ git blame -s -C5 --ignore-rev 9c8df98 -L 6,8 scorekit/text.py
b2502383 scorer.py        6) def normalize(text):
d926d3c5 scorekit/text.py 7)     text = _PUNCTUATION.sub("", text)
dd70d9e4 scorekit/text.py 8)     return " ".join(text.split())
```
<!-- /snippet -->

A copy from a file that the commit did not modify needs the second `-C`:

<!-- snippet: ch14a/blame-moves/04-copy -->
```text
$ git blame -s -L 9,12 data/nightly.jsonl
c0c9a304  9) {"id": 9, "prediction": "seven", "reference": "7"}
c0c9a304 10) {"id": 10, "prediction": "oxygen", "reference": "oxygen"}
c0c9a304 11) {"id": 11, "prediction": "Canberra", "reference": "canberra"}
c0c9a304 12) {"id": 12, "prediction": "the speed of light", "reference": "speed of light"}
$ git blame -s -C -L 9,12 data/nightly.jsonl
c0c9a304  9) {"id": 9, "prediction": "seven", "reference": "7"}
c0c9a304 10) {"id": 10, "prediction": "oxygen", "reference": "oxygen"}
c0c9a304 11) {"id": 11, "prediction": "Canberra", "reference": "canberra"}
c0c9a304 12) {"id": 12, "prediction": "the speed of light", "reference": "speed of light"}
$ git blame -s -C -C -L 9,12 data/nightly.jsonl
633e3e60 data/smoke.jsonl    9) {"id": 9, "prediction": "seven", "reference": "7"}
633e3e60 data/smoke.jsonl   10) {"id": 10, "prediction": "oxygen", "reference": "oxygen"}
c0c9a304 data/nightly.jsonl 11) {"id": 11, "prediction": "Canberra", "reference": "canberra"}
c0c9a304 data/nightly.jsonl 12) {"id": 12, "prediction": "the speed of light", "reference": "speed of light"}
```
<!-- /snippet -->

`-M` handles a block that changes position inside a file. A new commit puts `tokens()` above `normalize()`:

<!-- snippet: ch14a/blame-moves/07-move-within-file -->
```text
# A new commit moves tokens() above normalize() and changes nothing else.
$ git blame -s scorekit/text.py
d926d3c5  1) import re
dd70d9e4  2) 
9c8df982  3) _PUNCTUATION = re.compile(r"[^\w\s]")
dd70d9e4  4) 
dd70d9e4  5) 
fad07941  6) def tokens(text):
fad07941  7)     return normalize(text).split()
fad07941  8) 
fad07941  9) 
dd70d9e4 10) def normalize(text):
9c8df982 11)     text = _PUNCTUATION.sub("", text)
9c8df982 12)     return " ".join(text.split())
$ git blame -s -M scorekit/text.py
d926d3c5  1) import re
dd70d9e4  2) 
9c8df982  3) _PUNCTUATION = re.compile(r"[^\w\s]")
dd70d9e4  4) 
dd70d9e4  5) 
c0d33a57  6) def tokens(text):
9c8df982  7)     return normalize(text).split()
fad07941  8) 
fad07941  9) 
dd70d9e4 10) def normalize(text):
9c8df982 11)     text = _PUNCTUATION.sub("", text)
9c8df982 12)     return " ".join(text.split())
```
<!-- /snippet -->

Without `-M`, the lines that moved up are blamed on the commit that moved them. With it, lines 6 and 7 go back to their earlier commits; the two blank lines are too short to qualify.

**Squash merges.** A squash merge records the content of a branch as one new commit ([Chapter 8](ch08-merge.md)). Blame on the target branch then knows one commit and one author:

<!-- snippet: ch14a/blame-moves/05-squash -->
```text
$ git blame -L 15,18 scorekit/rouge.py
78232321 (Lab User 2026-09-11 15:01:00 +0530 15) def rouge_l(prediction, reference):
78232321 (Lab User 2026-09-11 15:01:00 +0530 16)     pred = tokens(prediction)
78232321 (Lab User 2026-09-11 15:01:00 +0530 17)     ref = tokens(reference)
78232321 (Lab User 2026-09-11 15:01:00 +0530 18)     lcs = _lcs(pred, ref)
$ git blame -L 15,18 feat/rouge-l -- scorekit/rouge.py
80ee55fe (Asha Rao 2026-09-11 12:11:00 +0530 15) def rouge_l(prediction, reference):
80ee55fe (Asha Rao 2026-09-11 12:11:00 +0530 16)     pred = tokens(prediction)
80ee55fe (Asha Rao 2026-09-11 12:11:00 +0530 17)     ref = tokens(reference)
80ee55fe (Asha Rao 2026-09-11 12:11:00 +0530 18)     lcs = _lcs(pred, ref)
```
<!-- /snippet -->

On `main`, the person who squashed "wrote" the function. The branch, while it still exists, has the real history. Nothing links the two in the graph:

<!-- snippet: ch14a/blame-moves/06-squash-who -->
```text
$ git log -1 --format='%h %an: %s%n%(trailers:key=Co-authored-by)' 7823232
7823232 Lab User: Add ROUGE-L metric
Co-authored-by: Asha Rao <asha@example.com>
Co-authored-by: Ravi Menon <ravi@example.com>

$ git branch --no-merged main
  feat/report
  feat/rouge-l
```
<!-- /snippet -->

`git branch --no-merged main` lists `feat/rouge-l` as unmerged for the same reason. After the branch is deleted, the `Co-authored-by` trailers and the pull request are the only record of who wrote which part. That is a real cost of squash-merge workflows, to be weighed against the linear history they give ([Chapter 17](ch17-pull-requests.md)).

The opposite question, "which merge put this line on `main`", is `--first-parent`: blame then stops at merges instead of descending into the merged branch.

<!-- snippet: ch14a/blame-moves/08-first-parent -->
```text
$ git blame -s --first-parent -L 10,12 scorekit/text.py
86572733 10) def normalize(text):
9c8df982 11)     text = _PUNCTUATION.sub("", text)
9c8df982 12)     return " ".join(text.split())
```
<!-- /snippet -->

## 14A.19 A method for finding the origin of a bug

The tools are now in place. This is the order to use them in, as an instance of the root-cause framework of [Chapter 1](ch01-fundamentals.md).

| Step | Do | With |
|---|---|---|
| 1. Pin the symptom | Reduce it to one command with a yes-or-no outcome | the smallest input that shows the problem |
| 2. Fix two endpoints | One commit known good, one known bad | tags, deploy records, `git describe` |
| 3. Locate | Find the code that produces the behavior | `git grep` |
| 4. Read the lines' history | Last change per line; through formatters and moves | `git blame -w -C --ignore-rev`, `git log -L` |
| 5. Look for what is gone | A removed call, check or string | `git log -S`, `-G` |
| 6. Search by behavior | When steps 3 to 5 give no suspect or several | `git bisect` |
| 7. Confirm | The suspect shows the symptom, its parent does not | a test at both commits |
| 8. Measure the spread | Which releases and branches contain the commit | `git tag --contains`, `git branch -a --contains` |
| 9. Choose the fix | Revert or fix forward; add the test from step 1 | [Chapter 11](ch11-reset-revert-restore.md) |

Steps 3 to 5 are fast and need an idea of where the fault is. Step 6 is slower and needs no idea at all, only the test. Do not skip step 7: every tool before it produces a suspect, not a proof.

**Worked on regression 1.** The symptom is the score line of section 14A.1. The documentation says what `exact_match` should do, and `git grep` finds the code:

<!-- snippet: ch14a/find-origin/01-symptom -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl
rows=10 exact_match=0.400 token_f1=0.444 rouge_l=0.489
[exit status: 1]
$ git grep -n "exact_match" -- docs
docs/metrics.md:3:- exact_match: 1 when prediction and reference are equal after normalization, else 0.
$ git grep -n -W "def exact_match"
scorekit/metrics.py:4:def exact_match(prediction, reference):
scorekit/metrics.py-5-    return normalize(prediction) == normalize(reference)
```
<!-- /snippet -->

"Equal after normalization" points at `normalize()`:

<!-- snippet: ch14a/find-origin/02-locate -->
```text
$ git grep -n "def normalize"
scorekit/text.py:6:def normalize(text):
$ git blame --date=short -L :normalize scorekit/text.py
dd70d9e4 (Asha Rao 2026-09-09  6) def normalize(text):
9c8df982 (Asha Rao 2026-09-11  7)     text = _PUNCTUATION.sub("", text)
9c8df982 (Asha Rao 2026-09-11  8)     return " ".join(text.split())
c0d33a57 (Asha Rao 2026-09-09  9) 
c0d33a57 (Asha Rao 2026-09-09 10) 
```
<!-- /snippet -->

Both body lines are owned by the formatter commit. Look through it:

<!-- snippet: ch14a/find-origin/03-through-the-formatter -->
```text
$ git blame --date=short --ignore-rev 9c8df98 -L :normalize scorekit/text.py
dd70d9e4 (Asha Rao   2026-09-09  6) def normalize(text):
d926d3c5 (Ravi Menon 2026-09-10  7)     text = _PUNCTUATION.sub("", text)
dd70d9e4 (Asha Rao   2026-09-09  8)     return " ".join(text.split())
c0d33a57 (Asha Rao   2026-09-09  9) 
c0d33a57 (Asha Rao   2026-09-09 10) 
```
<!-- /snippet -->

One line was last changed for a real reason, by `d926d3c`, the day before the formatter ran. Read that commit:

<!-- snippet: ch14a/find-origin/04-read -->
```text
$ git show d926d3c
commit d926d3c5a77b586297eb25335c33fed4aee6f053
Author: Ravi Menon <ravi@example.com>
Date:   Thu Sep 10 13:36:00 2026 +0530

    Speed up normalize with a precompiled pattern
    
    str.translate built a table lookup per call. One compiled pattern is faster on the nightly set.

diff --git a/scorekit/text.py b/scorekit/text.py
index 48081af..3075545 100644
--- a/scorekit/text.py
+++ b/scorekit/text.py
@@ -1,10 +1,10 @@
-import string
+import re
 
-_PUNCTUATION = str.maketrans('', '', string.punctuation)
+_PUNCTUATION = re.compile(r'[^\w\s]')
 
 
 def normalize(text):
-  text = text.lower().translate(_PUNCTUATION)
+  text = _PUNCTUATION.sub('', text)
   return ' '.join(text.split())
 
 
```
<!-- /snippet -->

The message promises speed and no change of behavior. The patch replaces `text.lower().translate(...)` with a pattern substitution, and `.lower()` is gone. `docs/metrics.md` still says "Normalization lowercases the text". The pickaxe confirms that this commit is where the call left the code base (step 5):

<!-- snippet: ch14a/find-origin/05-confirm -->
```text
$ git log --format='%h %ad %<(10)%an %s' --date=short -S'.lower()'
d926d3c 2026-09-10 Ravi Menon Speed up normalize with a precompiled pattern
dd70d9e 2026-09-09 Asha Rao   Move normalize into scorekit/text.py
b250238 2026-09-07 Lab User   Add exact-match scorer
```
<!-- /snippet -->

Step 7, on both sides of the suspect, in two temporary worktrees (🟢 `git worktree add`, [Chapter 25](ch25-worktrees.md)) so that the main working tree is not touched:

<!-- snippet: ch14a/find-origin/06-test-both-sides -->
```text
# One call that separates right from wrong, at the suspect and at its parent, without touching the working tree:
$ git worktree add --detach --quiet ../before d926d3c~1
$ git worktree add --detach --quiet ../after d926d3c
$ (cd ../before && python3 -B -c 'from scorekit.metrics import exact_match; print(exact_match("Paris", "paris"))')
True
$ (cd ../after && python3 -B -c 'from scorekit.metrics import exact_match; print(exact_match("Paris", "paris"))')
False
$ git worktree remove ../before && git worktree remove ../after
```
<!-- /snippet -->

Step 8:

<!-- snippet: ch14a/find-origin/07-blast-radius -->
```text
$ git tag --contains d926d3c
v0.2.0
$ git branch --all --contains d926d3c
  feat/report
  feat/rouge-l
* main
$ git describe --contains d926d3c
v0.2.0~3
$ git log --oneline d926d3c..main -- scorekit/text.py
9c8df98 Reformat sources: four-space indent, double quotes
```
<!-- /snippet -->

The answer for the CTO: the harness regressed, not the model. Commit `d926d3c` by Ravi on Thursday 10 September dropped lowercasing from normalization while optimizing it. Release `v0.2.0` contains the commit, and so does every branch cut since. Nothing after it has touched the function except the formatter. The fix is one line, plus a test with a capitalized answer.

This case was kind: the faulty line still existed and blame pointed near it. When the fault is in a file nobody suspects, the method arrives at step 6.

## 14A.20 `git bisect`: binary search over commits

**In one sentence.** 🟡 `git bisect` finds the commit that changed a property by checking out a commit in the middle of the suspects, asking you for a verdict, and halving the suspects until one is left.

**Analogy.** Looking up a word in a printed dictionary: open in the middle, see whether your word comes before or after, repeat with that half. The analogy breaks in two places. History is a graph, not a list, so "the middle" has to be computed. And a dictionary is sorted by construction, while "good before, bad after" is an assumption about your project that bisect cannot verify.

**Precisely.** You give one commit that has the property ("bad" or "new") and at least one ancestor that lacks it ("good" or "old"). The candidates are the commits reachable from the bad one and not from any good one, the range of section 14A.8. Git assumes there is a single first bad commit: "all its descendants are 'bad' and all the other commits are 'good'". It tests the candidate X that maximizes min(ancestors of X among the candidates, N minus that number), the commit that splits the candidates most evenly ([Fighting regressions with git bisect](https://git-scm.com/docs/git-bisect-lk2009)). A "bad" verdict keeps X and its ancestors; a "good" verdict removes them.

**The arithmetic.** Every verdict halves the candidates, so k verdicts can separate 2^k candidates, and N candidates need about log2(N) verdicts.

| Candidates | Verdicts needed, about | A linear search, worst case |
|---|---|---|
| 20 | 4 or 5 | 20 |
| 1,000 | 10 | 1,000 |
| 1,000,000 | 20 | 1,000,000 |

Doubling the history adds one test. This is why "it worked in the last release" is enough of a starting point, however long ago that was.

**See it.** `v0.1.0` scored the smoke set correctly, `main` does not, and there are twenty candidates:

<!-- snippet: ch14a/bisect-manual/01-start -->
```text
$ git rev-list --count v0.1.0..main
20
$ git bisect start
status: waiting for both 'good' and 'bad' commits
$ git bisect bad main
status: waiting for 'good' commit(s), 'bad' commit known
$ git bisect good v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
```
<!-- /snippet -->

Git checked out `074d492`. That commit and its ancestors account for ten of the twenty candidates, so either verdict leaves ten suspects, one of which already has a verdict: "9 revisions left to test after this". The step count is an estimate computed from the number of candidates ([bisect.c](https://github.com/git/git/blob/v2.55.0/bisect.c)). HEAD is now detached:

<!-- snippet: ch14a/bisect-manual/02-status -->
```text
$ git status
HEAD detached at 074d492
You are currently bisecting, started from branch 'main'.
  (use "git bisect reset" to get back to the original branch)

nothing to commit, working tree clean
```
<!-- /snippet -->

Run the test. At this commit it gives neither answer:

<!-- snippet: ch14a/bisect-manual/03-untestable -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
KeyError: '--limit'
$ git bisect skip
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
```
<!-- /snippet -->

The runner crashes for a reason that has nothing to do with scoring. Calling this "bad" would be a false statement about the property under investigation, and section 14A.21 shows what a false statement costs. `git bisect skip` says "no verdict", and Git picks another commit. From here the test answers:

<!-- snippet: ch14a/bisect-manual/04-bad -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
rows=10 exact_match=0.400 token_f1=0.444 rouge_l=0.489
$ git bisect bad
Bisecting: 8 revisions left to test after this (roughly 3 steps)
[72134f33df03602df3b2fa85f5b7dfb0aa08c190] Document the runner's exit status
```
<!-- /snippet -->

<!-- snippet: ch14a/bisect-manual/05-good -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
rows=10 exact_match=0.800 token_f1=0.889
$ git bisect good
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[9c8df98229e009115b3044edb1181d11075ecbbb] Reformat sources: four-space indent, double quotes
```
<!-- /snippet -->

<!-- snippet: ch14a/bisect-manual/06-narrowing -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
rows=10 exact_match=0.400 token_f1=0.489
$ git bisect bad
Bisecting: 2 revisions left to test after this (roughly 1 step)
[be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
rows=10 exact_match=0.800 token_f1=0.889
$ git bisect good
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
```
<!-- /snippet -->

<!-- snippet: ch14a/bisect-manual/07-found -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1
rows=10 exact_match=0.400 token_f1=0.489
$ git bisect bad
d926d3c5a77b586297eb25335c33fed4aee6f053 is the first 'bad' commit
commit d926d3c5a77b586297eb25335c33fed4aee6f053
Author: Ravi Menon <ravi@example.com>
Date:   Thu Sep 10 13:36:00 2026 +0530

    Speed up normalize with a precompiled pattern
    
    str.translate built a table lookup per call. One compiled pattern is faster on the nightly set.

 scorekit/text.py | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```
<!-- /snippet -->

Five verdicts and one skip, and the same commit that blame and the pickaxe named. Bisect got there without knowing which file to look at.

**Inside `.git`.** A bisection is state, kept until you end it:

<!-- snippet: ch14a/bisect-manual/08-state -->
```text
$ git for-each-ref --format="%(objectname:short) %(refname)" refs/bisect
d926d3c refs/bisect/bad
682bc71 refs/bisect/good-682bc717015f0ab43b873d1df1ac9da0ba01c393
72134f3 refs/bisect/good-72134f33df03602df3b2fa85f5b7dfb0aa08c190
be9ad1b refs/bisect/good-be9ad1b4894348317c1e7ccb8276b8ad4760fb89
074d492 refs/bisect/skip-074d49249bcd54bc33537fe26519dd38e3c3ba85
$ ls .git | grep BISECT
BISECT_ANCESTORS_OK
BISECT_EXPECTED_REV
BISECT_LOG
BISECT_NAMES
BISECT_START
BISECT_TERMS
$ cat .git/BISECT_START .git/BISECT_TERMS
main
bad
good
$ git rev-parse --abbrev-ref HEAD
HEAD
```
<!-- /snippet -->

Every verdict is a ref under `refs/bisect/`. `BISECT_START` holds where to return to, `BISECT_TERMS` the two words in use, `BISECT_LOG` the session so far. `git bisect log` prints that file, as commands that would reproduce the session:

<!-- snippet: ch14a/bisect-manual/09-log -->
```text
$ git bisect log
git bisect start
# status: waiting for both 'good' and 'bad' commits
# bad: [e376e5b709142415a87d49ca10af71977aaeabdc] Mention the nightly run in the README
git bisect bad e376e5b709142415a87d49ca10af71977aaeabdc
# status: waiting for 'good' commit(s), 'bad' commit known
# good: [682bc717015f0ab43b873d1df1ac9da0ba01c393] Add config module with the pass mark
git bisect good 682bc717015f0ab43b873d1df1ac9da0ba01c393
# skip: [074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
git bisect skip 074d49249bcd54bc33537fe26519dd38e3c3ba85
# bad: [d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
git bisect bad d9d075d63dcc94ce04c8e404e06b5cc3173180c2
# good: [72134f33df03602df3b2fa85f5b7dfb0aa08c190] Document the runner's exit status
git bisect good 72134f33df03602df3b2fa85f5b7dfb0aa08c190
# bad: [9c8df98229e009115b3044edb1181d11075ecbbb] Reformat sources: four-space indent, double quotes
git bisect bad 9c8df98229e009115b3044edb1181d11075ecbbb
# good: [be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
git bisect good be9ad1b4894348317c1e7ccb8276b8ad4760fb89
# bad: [d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
git bisect bad d926d3c5a77b586297eb25335c33fed4aee6f053
# first 'bad' commit: [d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
```
<!-- /snippet -->

`git bisect reset` returns to the starting branch and deletes all of it:

<!-- snippet: ch14a/bisect-manual/10-reset -->
```text
$ git bisect reset
Previous HEAD position was d926d3c Speed up normalize with a precompiled pattern
Switched to branch 'main'
$ git status --short --branch
## main
$ git for-each-ref refs/bisect | wc -l
       0
```
<!-- /snippet -->

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git bisect start [<bad> <good>...]` | once both ends are known: files of the chosen commit | matches that commit | detached at that commit | unchanged | `BISECT_START`, `BISECT_LOG`, `BISECT_TERMS` and others; `refs/bisect/bad`, `refs/bisect/good-<id>`; one HEAD reflog entry per checkout | unchanged | unchanged |
| `git bisect good`, `bad`, `skip` | files of the next commit | matches it | detached at the next commit | unchanged | one more ref under `refs/bisect/`; `BISECT_LOG` grows | unchanged | unchanged |
| `git bisect reset` | files of the starting branch | matches it | attached to the starting branch again | unchanged | every `BISECT_*` file and `refs/bisect/*` ref removed | unchanged | unchanged |
| `git bisect start --no-checkout` | unchanged | unchanged | unchanged | unchanged | as above, and the ref `BISECT_HEAD` names the commit to test | unchanged | unchanged |

**Picture.** The candidates in the order of the first-parent line, with the verdicts of this session (the two commits of the side branch are omitted):

```text
  v0.1.0   8e2cac1 ... 8657273  72134f3  8dc82cb  074d492  be9ad1b  d926d3c  9c8df98 ... d9d075d ... main
   good                          good(3)           skip(1)  good(5)  BAD(6)   bad(4)      bad(2)     bad
                                                                     ^ first bad commit
```

**In production.** Bisect needs commits that can be tested one by one. A history of small commits that each build ([Chapter 6](ch06-commits.md), section 6.10) gives an answer you can read in a minute; a history of large squashes gives an answer that is a 2,000-line diff. Start a bisection from a clean working tree: Git refuses to check out the next commit over uncommitted changes to files it has to replace.

<!-- snippet: ch14a/bisect-run/07-dirty-tree -->
```text
# An uncommitted edit in scorekit/config.py, a file that differs between the commits to visit:
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
error: Your local changes to the following files would be overwritten by checkout:
	scorekit/config.py
Please commit your changes or stash them before you switch branches.
Aborting
[exit status: 1]
$ git bisect reset
```
<!-- /snippet -->

## 14A.21 `git bisect run` and the exit-code protocol

Answering by hand is error-prone and does not scale past a handful of steps. `git bisect run <cmd>` runs a command at every step and takes the verdict from its exit status ([git-bisect](https://git-scm.com/docs/git-bisect)):

| Exit status | Meaning |
|---|---|
| 0 | good (old) |
| 1 to 127, except 125 | bad (new) |
| 125 | this commit cannot be tested: skip it |
| anything else, such as 128 and above | abort the bisection |

The script for regression 1 has three outcomes, because the question has three answers:

<!-- snippet: ch14a/bisect-run/01-script -->
```text
$ cat ../check-em.sh
#!/bin/sh
# Exit 0 if this commit scores the smoke set correctly, 1 if it does not,
# 125 if the runner cannot produce a score line at all (untestable: skip).
out=$(python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null)
case "$out" in
  *exact_match=0.800*) exit 0 ;;
  *exact_match=*)      exit 1 ;;
  *)                   exit 125 ;;
esac
$ ../check-em.sh; echo "exit status on main: $?"
exit status on main: 1
```
<!-- /snippet -->

It lives one directory above the repository. The manual advises keeping the test outside the repository "to prevent interactions between the bisect, make and test processes and the scripts"; a tracked script would be replaced by each commit's own version of it, or be absent in older commits. The whole search is now two commands:

<!-- snippet: ch14a/bisect-run/02-run -->
```text
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
$ git bisect run ../check-em.sh
running '../check-em.sh'
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
running '../check-em.sh'
Bisecting: 8 revisions left to test after this (roughly 3 steps)
[72134f33df03602df3b2fa85f5b7dfb0aa08c190] Document the runner's exit status
running '../check-em.sh'
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[9c8df98229e009115b3044edb1181d11075ecbbb] Reformat sources: four-space indent, double quotes
running '../check-em.sh'
Bisecting: 2 revisions left to test after this (roughly 1 step)
[be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
running '../check-em.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
running '../check-em.sh'
d926d3c5a77b586297eb25335c33fed4aee6f053 is the first 'bad' commit
commit d926d3c5a77b586297eb25335c33fed4aee6f053
Author: Ravi Menon <ravi@example.com>
Date:   Thu Sep 10 13:36:00 2026 +0530

    Speed up normalize with a precompiled pattern
    
    str.translate built a table lookup per call. One compiled pattern is faster on the nightly set.

 scorekit/text.py | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
bisect found first 'bad' commit
```
<!-- /snippet -->

The log shows that the script's 125 was recorded as a skip:

<!-- snippet: ch14a/bisect-run/03-log -->
```text
$ git bisect log
# bad: [e376e5b709142415a87d49ca10af71977aaeabdc] Mention the nightly run in the README
# good: [682bc717015f0ab43b873d1df1ac9da0ba01c393] Add config module with the pass mark
git bisect start 'main' 'v0.1.0'
# skip: [074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
git bisect skip 074d49249bcd54bc33537fe26519dd38e3c3ba85
# bad: [d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
git bisect bad d9d075d63dcc94ce04c8e404e06b5cc3173180c2
# good: [72134f33df03602df3b2fa85f5b7dfb0aa08c190] Document the runner's exit status
git bisect good 72134f33df03602df3b2fa85f5b7dfb0aa08c190
# bad: [9c8df98229e009115b3044edb1181d11075ecbbb] Reformat sources: four-space indent, double quotes
git bisect bad 9c8df98229e009115b3044edb1181d11075ecbbb
# good: [be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
git bisect good be9ad1b4894348317c1e7ccb8276b8ad4760fb89
# bad: [d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
git bisect bad d926d3c5a77b586297eb25335c33fed4aee6f053
# first 'bad' commit: [d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
$ git bisect reset
Previous HEAD position was d926d3c Speed up normalize with a precompiled pattern
Switched to branch 'main'
```
<!-- /snippet -->

**Why 125 matters.** Suppose the test were the runner's own exit status: 0 when the score passes, 1 when it does not. A crash also exits with 1. The first commit tested would be marked bad, Git would search among its ancestors, where the score is fine, and it would report the commit that introduced the crash as the first bad commit. The answer would be precise, reproducible and wrong. Lab 11.5 runs exactly this. A test for bisect must distinguish "has the property", "does not have it" and "cannot tell".

Exit codes outside the protocol stop the run instead of producing a verdict:

<!-- snippet: ch14a/bisect-run/05-bad-exit-code -->
```text
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
$ git bisect run sh -c 'exit 200'
running 'sh' '-c' 'exit 200'
error: bisect run failed: exit code 200 from 'sh' '-c' 'exit 200' is < 0 or >= 128
[exit status: 56]
$ git bisect reset
Previous HEAD position was 074d492 Send warnings to stderr
Switched to branch 'main'
```
<!-- /snippet -->

A mistyped path is caught in a way worth knowing. Shells return 127 for "command not found", which the protocol would read as "bad". Git 2.55 does not take 126 or 127 at face value on the first step: it runs the command on the known good commit as well, and stops when it gets the same code there.

<!-- snippet: ch14a/bisect-run/06-missing-script -->
```text
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
$ git bisect run ./check-em.sh
running './check-em.sh'
'./check-em.sh': ./check-em.sh: No such file or directory
[682bc717015f0ab43b873d1df1ac9da0ba01c393] Add config module with the pass mark
running './check-em.sh'
'./check-em.sh': ./check-em.sh: No such file or directory
error: bogus exit code 127 for 'good' revision
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
[exit status: 1]
$ git bisect reset
Previous HEAD position was 074d492 Send warnings to stderr
Switched to branch 'main'
```
<!-- /snippet -->

**In production.** For AI/ML work the test is often slow or noisy: an evaluation run, a benchmark, a training smoke test. Three rules follow. Make the test as small as the symptom allows; one input that separates good from bad beats the full suite. Make it deterministic: fix seeds, pin the data, and compare against a threshold with a margin; a flaky test gives bisect false verdicts, and it will converge on an innocent commit without complaint. And rebuild whatever is derived from the sources at every step: installed packages, compiled extensions, caches. A commit is only its tracked files; the environment around them is your responsibility.

## 14A.22 Custom terms, replay, `--first-parent`, and the pitfalls

**Terms.** "Good" and "bad" are awkward when you are looking for an improvement. `old` and `new` are built-in alternatives, and `--term-old` and `--term-new` let you choose words. Here the question is which commit fixed the crash:

<!-- snippet: ch14a/bisect-terms/01-terms -->
```text
# Since which commit does the runner work again without --limit? 8dc82cb is known to crash.
$ git bisect start --term-old broken --term-new fixed
status: waiting for both 'broken' and 'fixed' commits
$ git bisect fixed main
status: waiting for 'broken' commit(s), 'fixed' commit known
$ git bisect broken 8dc82cb
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[78232321c82cb23d6fb732e4c8ee614c6f005919] Add ROUGE-L metric
$ git bisect terms
Your current terms are 'broken' for the old state
and 'fixed' for the new state.
```
<!-- /snippet -->

The subcommands are now named after your words. For `git bisect run` the mapping stays positional: exit status 0 means the old state, whatever it is called.

<!-- snippet: ch14a/bisect-terms/02-run -->
```text
# For bisect run, exit status 0 means the OLD state. grep exits 0 when it finds the crash.
$ git bisect run sh -c 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | grep -q KeyError'
running 'sh' '-c' 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | grep -q KeyError'
Bisecting: 2 revisions left to test after this (roughly 1 step)
[be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
running 'sh' '-c' 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | grep -q KeyError'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
running 'sh' '-c' 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | grep -q KeyError'
be9ad1b4894348317c1e7ccb8276b8ad4760fb89 is the first 'fixed' commit
commit be9ad1b4894348317c1e7ccb8276b8ad4760fb89
Author: Lab User <you@example.com>
Date:   Thu Sep 10 12:31:00 2026 +0530

    Fix crash when --limit is not given
    
    Without the option the runner stopped with KeyError: '--limit'.

 scorekit/runner.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first 'fixed' commit
```
<!-- /snippet -->

Within one session the vocabulary is fixed:

<!-- snippet: ch14a/bisect-terms/05-good-bad-mixed -->
```text
$ git bisect start --term-old broken --term-new fixed
status: waiting for both 'broken' and 'fixed' commits
$ git bisect bad main 2>&1 | head -n 2
error: Invalid command: you're currently in a fixed/broken bisect
fatal: unknown command: 'bad'
$ git bisect reset
Already on 'main'
```
<!-- /snippet -->

**Log and replay.** `git bisect log` output is replayable. Save it, and a session can be repeated, handed to a colleague, or repaired:

<!-- snippet: ch14a/bisect-terms/04-replay -->
```text
$ git bisect replay ../bisect.log
status: waiting for both 'broken' and 'fixed' commits
be9ad1b4894348317c1e7ccb8276b8ad4760fb89 is the first 'fixed' commit
commit be9ad1b4894348317c1e7ccb8276b8ad4760fb89
Author: Lab User <you@example.com>
Date:   Thu Sep 10 12:31:00 2026 +0530

    Fix crash when --limit is not given
    
    Without the option the runner stopped with KeyError: '--limit'.

 scorekit/runner.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git bisect reset
Already on 'main'
```
<!-- /snippet -->

If you gave a wrong verdict, save the log, delete the wrong line and everything after it, run `git bisect reset`, and replay the edited file. You continue from the last correct verdict instead of starting over (Lab 11.4).

**More controls.**

| Form | Effect |
|---|---|
| `git bisect start <bad> <good> -- <path>...` | considers only commits that touch the paths; fewer steps when you know the area |
| `git bisect start --first-parent ...` | follows only first parents; a regression that arrived through a merge is attributed to the merge commit |
| `git bisect start --no-checkout ...` | does not touch the working tree; sets `BISECT_HEAD` for tests that read objects directly |
| `git bisect skip <rev>` or `<range>` | marks commits untestable in advance |
| `git bisect visualize` (`view`) | shows the remaining candidates: in `gitk` if a graphical session is detected, otherwise with `git log`, and it accepts log options such as `--oneline` |
| `git bisect reset <commit>` | ends the session and checks out that commit instead of the starting branch |

`--first-parent` changes the candidate set, and with it the path of the search:

<!-- snippet: ch14a/bisect-terms/06-first-parent -->
```text
$ git rev-list --count v0.1.0..main
20
$ git rev-list --count --first-parent v0.1.0..main
18
$ git bisect start --first-parent main v0.1.0
Bisecting: 8 revisions left to test after this (roughly 3 steps)
[be9ad1b4894348317c1e7ccb8276b8ad4760fb89] Fix crash when --limit is not given
$ git bisect reset
Previous HEAD position was be9ad1b Fix crash when --limit is not given
Switched to branch 'main'
```
<!-- /snippet -->

Use it when the commits inside merged branches are not required to work on their own.

**Pitfalls.**

- **The property is not monotonic.** A bug that was introduced, fixed and introduced again has more than one first bad commit. Bisect finds one transition and cannot tell you there are others. If the result looks implausible, test the reported commit and its parent yourself.
- **Good and bad are swapped, or unrelated.** Git checks that every good commit is an ancestor of the bad one:

<!-- snippet: ch14a/bisect-terms/07-wrong-way-round -->
```text
$ git bisect start v0.1.0 main
Some 'good' revs are not ancestors of the 'bad' rev.
git bisect cannot work properly in this case.
Maybe you mistook 'good' and 'bad' revs?
[exit status: 1]
$ git bisect reset
```
<!-- /snippet -->

- **Skipped commits next to the culprit.** If the first bad commit is adjacent to skipped ones, Git cannot decide between them and ends with a list of candidates instead of one commit. The manual states it: "if you skip a commit adjacent to the one you are looking for, Git will be unable to tell exactly which of those commits was the first bad one."
- **The culprit is a merge.** Both parents are good and the merge is bad: the fault is in the combination, a merge that was textually clean and semantically wrong ([Chapter 8](ch08-merge.md)).
- **The cause is not in the repository.** A dependency that floated to a new version, a changed data file outside Git, a different machine. Bisect then reports whatever commit the noise happened to select, or every commit is bad. Check that the good commit is still good today, in today's environment, before you start.
- **A shallow clone.** Bisect can only visit commits that exist locally. In a clone made with `--depth`, as CI checkouts often are ([Chapter 20A](ch20a-actions-fundamentals.md)), the good commit may not be present at all.
- **Forgetting to reset.** Until `git bisect reset`, HEAD is detached. Commits made in that state belong to no branch ([Chapter 7](ch07-branches.md), section 7.7).

> **Version note.** Older behavior: a finished bisection leaves you on the last tested commit until you run `git bisect reset`. Current behavior on Git 2.55: unchanged, as shown above. Since: Git 2.56 teaches `git bisect` an option `--reset-when-found[=<where>]`, which runs the reset automatically, to the original state or to the culprit ([RelNotes 2.56.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc)); not run here, and its exact usage was not checked against the 2.56 manual. Recommended: on 2.55, end every `git bisect run` in a script with an explicit `git bisect reset`.

## 14A.23 `git grep`

🟢 `git grep` searches the content that Git tracks. Compared with a recursive `grep` it skips `.git`, ignored build output and untracked files by default, and it can search any revision without checking it out.

<!-- snippet: ch14a/grep/01-basic -->
```text
$ git grep -n PASS_MARK
scorekit/config.py:2:PASS_MARK = 0.75
scorekit/config.py:3:NIGHTLY_PASS_MARK = 0.6
scorekit/runner.py:4:from scorekit.config import PASS_MARK
scorekit/runner.py:28:    return 0 if em >= PASS_MARK else 1
$ git grep -c tokens
docs/metrics.md:1
scorekit/metrics.py:3
scorekit/rouge.py:3
scorekit/text.py:1
$ git grep -l normalize -- scorekit
scorekit/metrics.py
scorekit/text.py
```
<!-- /snippet -->

`-n` adds line numbers, `-c` counts matches per file, `-l` lists file names only. `-p` shows the function a match belongs to, and `-W` prints that whole function:

<!-- snippet: ch14a/grep/02-function -->
```text
$ git grep -n -p "overlap == 0"
scorekit/metrics.py=8=def token_f1(prediction, reference):
scorekit/metrics.py:12:    if overlap == 0:
$ git grep -W "set(pred)"
scorekit/metrics.py=def token_f1(prediction, reference):
scorekit/metrics.py-    pred = tokens(prediction)
scorekit/metrics.py-    ref = tokens(reference)
scorekit/metrics.py:    overlap = len(set(pred) & set(ref))
scorekit/metrics.py-    if overlap == 0:
scorekit/metrics.py-        return 0.0
scorekit/metrics.py-    precision = overlap / len(pred)
scorekit/metrics.py-    recall = overlap / len(ref)
scorekit/metrics.py-    return 2 * precision * recall / (precision + recall)
```
<!-- /snippet -->

A revision before the pathspec searches that tree. The exit status is 1 when nothing matches, which makes `git grep -q` usable as a test:

<!-- snippet: ch14a/grep/03-revision -->
```text
$ git grep -n "lower()" v0.1.0
v0.1.0:scorekit/metrics.py:5:  return ' '.join(text.lower().split())
$ git grep -n "lower()" main
[exit status: 1]
$ git grep -n -i bleu v0.2.0 -- docs
v0.2.0:docs/metrics.md:6:- bleu1: unigram precision with a brevity penalty (experimental).
```
<!-- /snippet -->

Several revisions give a quick history of one line, with each hit prefixed by its revision:

<!-- snippet: ch14a/grep/06-many-revisions -->
```text
$ git grep -n 'PASS_MARK = ' v0.1.0 v0.2.0 main -- scorekit/config.py
v0.1.0:scorekit/config.py:2:PASS_MARK = 0.7
v0.2.0:scorekit/config.py:2:PASS_MARK = 0.75
main:scorekit/config.py:2:PASS_MARK = 0.75
main:scorekit/config.py:3:NIGHTLY_PASS_MARK = 0.6
```
<!-- /snippet -->

| What is searched | Option |
|---|---|
| tracked files, as they are in the working tree | default |
| tracked files, as they are in the index | `--cached` |
| a commit or tree | `<rev>` before `--` |
| tracked and untracked files | `--untracked` |
| files in a directory that is not a repository | `--no-index` |

Patterns are basic regular expressions unless you pass `-E` (extended), `-P` (Perl-compatible) or `-F` (fixed string); `-i` ignores case and `-w` matches whole words. `-e <p1> --and -e <p2>` requires both patterns on one line, and `--not` negates one.

The division of labour with the pickaxe: `git grep` searches states, "where is this text at commit X"; `git log -S` and `-G` search transitions, "which commit changed it". To learn when a string came and went, ask the pickaxe; looping `git grep` over every revision reads every tree.

## 14A.24 `git whatchanged` is deprecated

Older tutorials show `git whatchanged` for "the log with the files each commit touched". On Git 2.55 it refuses to run:

<!-- snippet: ch14a/whatchanged/01-refuses -->
```text
$ git whatchanged -2
'git whatchanged' is nominated for removal.

hint: You can replace 'git whatchanged <opts>' with:
hint:	git log <opts> --raw --no-merges
hint: Or make an alias:
hint:	git config set --global alias.whatchanged 'log --raw --no-merges'

If you still use this command, here's what you can do:

- read https://git-scm.com/docs/BreakingChanges.html
- check if anyone has discussed this on the mailing
  list and if they came up with something that can
  help you: https://lore.kernel.org/git/?q=git%20whatchanged
- send an email to <git@vger.kernel.org> to let us
  know that you still use this command and were unable
  to determine a suitable replacement

fatal: refusing to run without --i-still-use-this
[exit status: 128]
```
<!-- /snippet -->

The replacement it names prints the same thing:

<!-- snippet: ch14a/whatchanged/02-replacement -->
```text
$ git log --raw --no-merges --oneline -2
e376e5b Mention the nightly run in the README
:100644 100644 bfae817 08f9933 M	README.md
2652768 Add a separate pass mark for the nightly set
:100644 100644 5efef40 12c95c2 M	scorekit/config.py
$ git whatchanged --i-still-use-this --oneline -2
e376e5b Mention the nightly run in the README
:100644 100644 bfae817 08f9933 M	README.md
2652768 Add a separate pass mark for the nightly set
:100644 100644 5efef40 12c95c2 M	scorekit/config.py
```
<!-- /snippet -->

Each raw line is: old mode, new mode, old blob ID, new blob ID, status letter, path. In practice `git log --name-status` or `git log --stat` reads better.

> **Outdated advice.** "Use `git whatchanged` to see what each commit changed." The command is "merely `git log` with different defaults", carries a deprecation warning in its manual page since Git 2.51, and is scheduled for removal in Git 3.0 ([git-whatchanged](https://github.com/git/git/blob/v2.56.0/Documentation/git-whatchanged.adoc), [BreakingChanges](https://github.com/git/git/blob/v2.56.0/Documentation/BreakingChanges.adoc)). Write `git log --raw --no-merges`, and do not add `--i-still-use-this` to scripts.

Going the other way, Git 2.52 added `git last-modified`, which reports the commit that last touched each path. Its manual page marks it experimental, so its interface may change ([git-last-modified](https://github.com/git/git/blob/v2.56.0/Documentation/git-last-modified.adoc)):

<!-- snippet: ch14a/whatchanged/03-last-modified -->
```text
# A newer plumbing command answers "which commit last touched each path". It is marked experimental.
$ git last-modified -r -- scorekit
26527689cd0ae7dc79b9627c6bea60ade2590465	scorekit/config.py
ca7e2b7fcc44f8d5a494107b68440c3d4ec23b55	scorekit/runner.py
ec4fad75a7e73526c6694c2559094bbe05e00980	scorekit/metrics.py
78232321c82cb23d6fb732e4c8ee614c6f005919	scorekit/rouge.py
9c8df98229e009115b3044edb1181d11075ecbbb	scorekit/text.py
9c8df98229e009115b3044edb1181d11075ecbbb	scorekit/__init__.py
```
<!-- /snippet -->

## 14A.25 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A review diff shows deletions of things the branch never touched | Two endpoints were compared and the target moved on: `git merge-base A B` is not A | `git diff A...B` | Three dots, or `--merge-base`, for review (14A.2) |
| `git log -- <path>` ends at a rename | Path limiting matches names | `--follow`, or list the old names | Rename and edit in separate commits (14A.4) |
| `--follow` ends early although the file is older | Rename plus rewrite below 50% similarity: `git show --stat -M30% <commit>` | Read on under the old path | As above |
| `-S` names a commit that only edited the line | The search string was longer than the stable part | Shorter string; check with `git show` and `-G` | Read the patch before naming a commit (14A.11) |
| `-S` or `--grep` finds nothing, the code exists on a branch | The walk started at HEAD | `--all`, or `--reflog` | State the walk in the query |
| `--since=<date>` returns a strange subset | Date without a time; or committer dates out of order | Full timestamp; `--since-as-filter` | 14A.9 |
| Blame shows one author and one date for most lines | A formatter or squash commit: `git show --stat <id>` | `-w`, `--ignore-rev`, or blame the branch | `.git-blame-ignore-revs` plus `blame.ignoreRevsFile` |
| `fatal: could not open object name list` on every blame | `blame.ignoreRevsFile` names a file this commit lacks | `:(optional)` prefix, or `git config unset blame.ignoreRevsFile` | Set the key with the prefix from the start |
| `fatal: invalid object name` from blame | A short ID in the ignore file | Replace with `git rev-parse <id>` output | Append IDs with `git rev-parse` |
| `git log -L` traces the wrong line | Line number taken from a modified working file | A `/regex/` or `:funcname` range | Content anchors, not numbers (Lab 11.7) |
| Bisect names a commit that cannot be the cause | A wrong verdict, a flaky test, or a crash counted as bad: read `git bisect log` | Edit the log, `reset`, `replay`; exit 125 for untestable commits | A three-way test script (14A.21) |
| Bisect ends with "only skipped commits left" | The culprit is next to untestable commits | Test those by hand, with the build fix applied temporarily | Keep every commit buildable |

## 14A.26 When not to use it, and dangerous edge cases

**When another tool is the right one.**

- Do not bisect what you can read. If the pickaxe or blame names one commit, and a test at that commit and its parent confirms it, you are done.
- Do not bisect before you have checked that the known-good commit is still good in today's environment.
- Do not use blame to decide who is responsible, or `git shortlog` counts to measure people.
- Do not use `git diff A B` to judge what a branch introduces, and do not use `A...B` to check whether two trees are equal.

**Edge cases.**

- **Everything in this chapter that mentions renames is a heuristic.** Two investigators with different thresholds, or different Git versions, can see different rename pairs for the same commits. Quote the options you used.
- **`:/<text>` is unstable.** It returns the youngest match across all refs, so a new commit or a fetched branch can change what a saved command resolves to. In scripts use `<rev>^{/<text>}`, or better, an ID.
- **Shallow and partial clones.** In a shallow clone, log, blame and bisect stop at the boundary. In a blobless partial clone, blame and `-S` fetch old blobs on demand and can be slow ([Chapter 26](ch26-performance.md)).
- **Author and dates are claims.** Every name and date that these tools print was supplied by whoever created the commit ([Chapter 6](ch06-commits.md)). For questions of accountability, look at signatures ([Chapter 14B](ch14b-config-tags-signing.md)) and at server-side records.
- **Bisect checks out old code and you run it.** `git bisect run` executes whatever the old commits contain: build scripts, test harnesses, hooks of the build system. On an untrusted repository that is arbitrary code execution; do it in a sandbox.

## 14A.27 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git diff`, `git log`, `git show`, `git blame`, `git grep`, `git shortlog`, `git describe`, `git rev-parse`, `git rev-list`, `git last-modified` | 🟢 SAFE | Nothing | not needed | not needed |
| `git config set blame.ignoreRevsFile <path>`, `diff.algorithm`, `blame.markIgnoredLines` | 🟡 CAUTION | One key in `.git/config`, a file that keeps no history; it changes what later commands print | `git config get <key>` | `git config unset <key>` |
| `git bisect start`, `good`, `bad`, `skip`, `run`, `replay` | 🟡 CAUTION | Detaches HEAD and checks out other commits; writes `refs/bisect/*` and `BISECT_*` | `git status` must be clean; `git rev-list --count <good>..<bad>` | `git bisect reset` |
| `git bisect reset` | 🟡 CAUTION | Checks out the starting branch; deletes the bisect state | `git bisect log > file` to keep the session | `git bisect replay file` |
| `git bisect start --no-checkout` | 🟢 SAFE | Bisect state and `BISECT_HEAD` only | not needed | `git bisect reset` |
| `git worktree add --detach <dir> <commit>` | 🟢 SAFE | A new directory and administrative files under `.git/worktrees` | not needed | `git worktree remove <dir>` |
| `git restore --source=<commit> -- <path>` | 🔴 DANGEROUS | Overwrites the working tree file | `git status --short -- <path>`; `git diff <commit> -- <path>` | None for uncommitted edits to that file |

For the 🔴 row: it sets working tree files to their content in the named commit and destroys uncommitted edits in them; preview with the two commands in the table; Git cannot recover content that was never staged or committed; it is appropriate for bringing back a deleted file, as in section 14A.13, where no file of that name exists.

## 14A.28 Version notes

> **Version note.** Older behavior: `git whatchanged` ran without complaint. Current behavior: on Git 2.55 it stops with "refusing to run without --i-still-use-this". Since: the deprecation warning has been in the manual since Git 2.51; removal is planned for Git 3.0 ([BreakingChanges](https://github.com/git/git/blob/v2.56.0/Documentation/BreakingChanges.adoc)). Recommended: `git log --raw --no-merges`.

- The `--reset-when-found[=<where>]` option of `git bisect` and the improved `git log --follow` on non-linear history are Git 2.56 changes ([RelNotes 2.56.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc)); not run here. The same release notes mention that blame output reserves a column for the `^`, `?` and `*` marks only when they are shown, so the blame transcripts of this chapter may be aligned differently on 2.56.
- `git blame --diff-algorithm` exists since Git 2.53 ([RelNotes 2.53.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.53.0.adoc)).
- `git last-modified` exists since Git 2.52 and is experimental ([RelNotes 2.52.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.52.0.adoc)). Apple's Git 2.50.1 at `/usr/bin/git` does not have it ([Phase 0 report, section 1](../reports/Git%20and%20GitHub%20mastery%20research.md)).
- `git config set`, `get` and `unset`, used in this chapter, need Git 2.46 or later.

> **Unverified.** Three behaviors shown in this chapter rest on runs of Git 2.55.0, and the releases that introduced them were not looked up: `--since=<date>` taking the current time of day for a date without a time (not in the manual); `git bisect run` re-testing the good commit after an exit status of 126 or 127 (not in the manual); and the `:(optional)` prefix for path-valued configuration (in the 2.55 manual).

## 14A.29 Practice

- Lab 10.4 in [m10-range-notation.md](../lab-manual/m10-range-notation.md): predict two-dot and three-dot output for `git log` and for `git diff`.
- Labs 11.1 to 11.7 in the [Module 11 lab manual](../lab-manual/m11-history-forensics.md): a line across a rename; a removed string with `-S` and `-G`; a deleted file; a manual bisect; `git bisect run`; blame through a formatter commit; line history with `-L`.
- Replay any transcript with `labs/run ch14a/<demo>`, for example `labs/run ch14a/bisect-manual`. The sandbox stays in place for your own queries.
- Three drills in the sandbox of `ch14a/history-tour`. Find the commit that introduced the word "experimental" into `docs/metrics.md`; every commit by Asha that touched `scorekit/text.py`; and the number of commits between `v0.1.0` and `v0.2.0` that are not on the first-parent line.

## 14A.30 Interview questions

1. `git diff main..feature` and `git log main..feature` use the same two dots. What does each do, and which diff form matches the log form?
2. A pull request shows a change that the base branch already contains. Explain how that can happen and how to make it disappear without closing the pull request.
3. Git stores no renames. Name three commands whose output depends on rename detection, and describe a commit that defeats it.
4. Explain `-S` and `-G` to a colleague, with one commit that the first misses and the second reports, and one case where `-G` is noise.
5. What exactly does a row of `git blame` assert? Give three situations in which the named author did not write the logic on that line.
6. Your team introduces a formatter. What do you commit, what does each developer configure, and what breaks if someone checks out a commit from before the formatter?
7. A regression appeared somewhere in 4,000 commits. How many tests does a bisection need, what does it assume about the history, and how do you check that assumption when the result looks wrong?
8. Design the test script for `git bisect run` for a nightly evaluation whose score has run-to-run noise and whose build is broken in some commits. Which exit codes do you use, and why?
9. Bisect reports a merge commit as the first bad commit, and both parents are good. What does that tell you, and what do you look at next?
10. `git log --since=2026-09-10` omitted commits from the morning of that day. Explain the cause and state how you would write the query in an incident report.
11. After a squash merge, how do you find out who wrote a given function and why? What would you change in the team's process to make that question cheaper?
12. You found the commit that introduced a bug. Which commands tell you which releases and which open branches contain it?

## 14A.31 Sources

**Primary sources**

- [git-diff](https://git-scm.com/docs/git-diff), [gitrevisions](https://git-scm.com/docs/gitrevisions), [git-log](https://git-scm.com/docs/git-log), [gitdiffcore](https://git-scm.com/docs/gitdiffcore), [git-blame](https://git-scm.com/docs/git-blame), [git-bisect](https://git-scm.com/docs/git-bisect), [git-grep](https://git-scm.com/docs/git-grep), [git-shortlog](https://git-scm.com/docs/git-shortlog), [git-describe](https://git-scm.com/docs/git-describe), [git-config](https://git-scm.com/docs/git-config). The local copies (`git help -m <command>`) are the Git 2.55.0 text that every option in this chapter was checked against.
- Christian Couder, [Fighting regressions with git bisect](https://git-scm.com/docs/git-bisect-lk2009), distributed with Git: the bisection and skip algorithms. The step estimate is in [bisect.c at v2.55.0](https://github.com/git/git/blob/v2.55.0/bisect.c).
- Release notes: [2.51.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc), [2.52.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.52.0.adoc), [2.53.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.53.0.adoc), [2.56.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc); [BreakingChanges](https://github.com/git/git/blob/v2.56.0/Documentation/BreakingChanges.adoc); [git-whatchanged](https://github.com/git/git/blob/v2.56.0/Documentation/git-whatchanged.adoc); [git-last-modified](https://github.com/git/git/blob/v2.56.0/Documentation/git-last-modified.adoc); [merge strategies](https://github.com/git/git/blob/v2.56.0/Documentation/merge-strategies.adoc).
- GitHub Docs, described and not run here: [three-dot and two-dot comparisons](https://docs.github.com/en/pull-requests/reference/branches#three-dot-and-two-dot-git-diff-comparisons); [ignore commits in the blame view](https://docs.github.com/en/repositories/working-with-files/using-files/viewing-and-understanding-files#ignore-commits-in-the-blame-view).

**Secondary sources**

- The Phase 0 report of this course, sections 1, 4 and 12: the deprecation table, and the two meanings of the dots among commonly misunderstood topics.
- Julia Evans, [Confusing git terminology](https://jvns.ca/blog/2023/11/01/confusing-git-terminology/), cited by the report for several of those misunderstandings.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- Tekin Süleyman, ["RubyConf 2018 - Branch in Time"](https://www.youtube.com/watch?v=8OOTVxKDwe0), 27 minutes, December 2018. Why history quality matters, told through `git blame`, `git log -S`, interactive rebase and `--force-with-lease`. Nothing in it depends on a Git version.
- ThePrimeagen for Boot.dev, ["Git and GitHub - Full Course"](https://www.youtube.com/watch?v=rH3zE7VlIMs), November 2024; the bisect chapter starts at 3:54:53. Current; digressive commentary style.
- glich.stream, ["Chad level git: advanced concepts (2025)"](https://www.youtube.com/watch?v=cYD3krz5L2g), 1 hour 14 minutes, January 2025. Includes bisect, hands-on.

**Further reading**

- Pro Git, part "Git Tools": [Revision Selection](https://git-scm.com/book/en/v2/Git-Tools-Revision-Selection), [Searching](https://git-scm.com/book/en/v2/Git-Tools-Searching) and [Debugging with Git](https://git-scm.com/book/en/v2/Git-Tools-Debugging-with-Git).
- [Chapter 5](ch05-index.md) for the three everyday diffs; [Chapter 7](ch07-branches.md) for counting divergence; [Chapter 8](ch08-merge.md) for `--remerge-diff`; [Chapter 9](ch09-rebase.md) for `git range-diff`; [Chapter 10](ch10-cherry-pick.md) for patch IDs; [Chapter 13](ch13-recovery.md) for the reflog as a recovery tool.
