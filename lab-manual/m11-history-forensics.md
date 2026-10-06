# Module 11 labs: History investigation and forensics

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" below is real output from a replay script in `labs/ch14a/`.

These seven labs belong to [Chapter 14A, History investigation](../textbook/ch14a-history-investigation.md). The general rules for labs are in the [lab manual README](README.md).

## How the labs of this module work

All seven labs investigate the same prepared repository, `scorekit`, a small library that scores model answers against reference answers. Its history is built by `labs/ch14a/fixtures/scorekit.sh`: nine days, three authors, renames, a formatter commit, a deleted file, a merge, a squash merge and two regressions. Section 14A.1 of the chapter shows the full graph.

```bash
bash labs/ch14a/setup-11-1-line-across-rename.sh   # builds the repository for Lab 11.1
labs/shell m11-1                                   # opens the isolated lab shell in that sandbox
cd scorekit                                        # the setup script prints this line for you
```

```bash
labs/run ch14a/lab-11-1-line-across-rename         # replays the whole lab and prints the transcript
```

Each lab has its own setup script and its own sandbox, so you can break one without affecting the next. The setup scripts pin the clock, so the prepared commits have exactly the IDs printed here. Commits that you create get other IDs. The labs run the project with `python3 -B`; the `-B` keeps Python from writing cache files into the working tree.

Three facts about the repository that the labs rely on:

- `v0.1.0` is a release that the team knows to be correct. `v0.2.0` and `main` are not.
- `python3 -B -m scorekit.runner data/smoke.jsonl` prints one score line and exits with status 1 when `exact_match` is below the pass mark.
- Two commits in the middle of the history cannot run the runner without `--limit`: it stops with `KeyError: '--limit'`.

## Lab 11.1: Trace a line across a rename

### Objective

Find the commit that first wrote one line of `scorekit/runner.py`, through a formatter commit and a file rename. Then lose a file's history on purpose by renaming and rewriting it in one commit, and get it back.

### Prerequisites

Chapter 14A, sections 14A.4, 14A.10, 14A.16 and 14A.17.

### Setup

```bash
bash labs/ch14a/setup-11-1-line-across-rename.sh
labs/shell m11-1
cd scorekit
```

You are on `main`. The line under investigation computes the exact-match average: it starts with `em = sum(`.

### Commands

Before each command, write down what you expect: which commit, whose name.

```bash
git blame -s -L '/em = sum/,+1' scorekit/runner.py
git blame -s -w -L '/em = sum/,+1' scorekit/runner.py
git show -s --format='%h %an: %s' 9c8df98
git blame -s --ignore-rev 9c8df98 -L '/em = sum/,+1' scorekit/runner.py
```

The last output has a column that the first two did not have. Now the file as a whole:

```bash
git log --oneline -- scorekit/runner.py
git log --oneline --follow -- scorekit/runner.py
git log --follow --diff-filter=AR --name-status --format='%h %an: %s' -- scorekit/runner.py
git log -s --format='%h %ad %an: %s' --date=short -L '/em = sum/,+1:scorekit/runner.py'
```

### Expected output

<!-- snippet: ch14a/lab-11-1-line-across-rename/01-blame -->
```text
$ git blame -s -L '/em = sum/,+1' scorekit/runner.py
9c8df982 24)     em = sum(exact_match(r["prediction"], r["reference"]) for r in rows) / len(rows)
$ git blame -s -w -L '/em = sum/,+1' scorekit/runner.py
9c8df982 24)     em = sum(exact_match(r["prediction"], r["reference"]) for r in rows) / len(rows)
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-1-line-across-rename/02-ignore-rev -->
```text
$ git show -s --format='%h %an: %s' 9c8df98
9c8df98 Asha Rao: Reformat sources: four-space indent, double quotes
$ git blame -s --ignore-rev 9c8df98 -L '/em = sum/,+1' scorekit/runner.py
633e3e60 run_eval.py 24)     em = sum(exact_match(r["prediction"], r["reference"]) for r in rows) / len(rows)
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-1-line-across-rename/03-log-path -->
```text
$ git log --oneline -- scorekit/runner.py
ca7e2b7 Fail fast on an empty reference
7823232 Add ROUGE-L metric
9c8df98 Reformat sources: four-space indent, double quotes
be9ad1b Fix crash when --limit is not given
074d492 Send warnings to stderr
8dc82cb Add --limit option to the runner
b4b066b Skip rows with an empty reference
682bc71 Add config module with the pass mark
18bb23e Rename the scorer module to metrics
d38a5aa Move sources into the scorekit package
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-1-line-across-rename/04-log-follow -->
```text
$ git log --oneline --follow -- scorekit/runner.py
ca7e2b7 Fail fast on an empty reference
7823232 Add ROUGE-L metric
9c8df98 Reformat sources: four-space indent, double quotes
be9ad1b Fix crash when --limit is not given
074d492 Send warnings to stderr
8dc82cb Add --limit option to the runner
b4b066b Skip rows with an empty reference
682bc71 Add config module with the pass mark
18bb23e Rename the scorer module to metrics
d38a5aa Move sources into the scorekit package
633e3e6 Add evaluation runner and smoke set
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-1-line-across-rename/05-the-rename -->
```text
$ git log --follow --diff-filter=AR --name-status --format='%h %an: %s' -- scorekit/runner.py
d38a5aa Lab User: Move sources into the scorekit package

R089	run_eval.py	scorekit/runner.py
633e3e6 Lab User: Add evaluation runner and smoke set

A	run_eval.py
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-1-line-across-rename/06-line-history -->
```text
$ git log -s --format='%h %ad %an: %s' --date=short -L '/em = sum/,+1:scorekit/runner.py'
9c8df98 2026-09-11 Asha Rao: Reformat sources: four-space indent, double quotes
be9ad1b 2026-09-10 Lab User: Fix crash when --limit is not given
8dc82cb 2026-09-10 Lab User: Add --limit option to the runner
b4b066b 2026-09-09 Lab User: Skip rows with an empty reference
633e3e6 2026-09-07 Lab User: Add evaluation runner and smoke set
```
<!-- /snippet -->

### What happened internally

Plain blame stopped at the formatter commit `9c8df98`, the last commit whose diff shows the line as changed. `-w` did not help: the formatter changed the quotes on this line, not only its indentation. `--ignore-rev` removed that commit from consideration, and blame passed the line to the commit before it and onwards, until it reached `633e3e6`. On the way it crossed a rename: blame follows whole-file renames by itself and prints the name the file had in the blamed commit, `run_eval.py`.

`git log -- scorekit/runner.py` matches the path, so it ends at `d38a5aa`, the commit in which a file of that name first appears. `--follow` ran rename detection there, found `run_eval.py` with 89% similarity, and continued under the old name. `git log -L` tracked the one line and did the same on its own. None of this is stored; each command recomputed it from the snapshots.

### Checkpoint

You can name the commit that first wrote the line (`633e3e6`, when the file was `run_eval.py`), and you can say why the first two blame commands and the first log command each stopped where they did.

### Failure scenario

A refactoring on a new branch gives the module a new name and most of a new body in one commit. The rewritten file is prepared for you next to the repository:

```bash
git switch --quiet -c refactor/cli
git mv scorekit/runner.py scorekit/cli.py
cp ../cli-rewrite.py scorekit/cli.py
git add -A && git commit -q -m "Rewrite the runner as scorekit.cli"
git show --stat --format="%h %s" HEAD
git log --oneline --follow -- scorekit/cli.py
git blame -s -L '/^def load/,+3' scorekit/cli.py
git show --name-status --format="%h %s" -M30% HEAD
```

<!-- snippet: ch14a/lab-11-1-line-across-rename/07-failure -->
```text
# A refactoring on a new branch: the module gets a new name and most of a new body, in ONE commit.
$ git switch --quiet -c refactor/cli
$ git mv scorekit/runner.py scorekit/cli.py
$ cp ../cli-rewrite.py scorekit/cli.py
$ git add -A && git commit -q -m "Rewrite the runner as scorekit.cli"
$ git show --stat --format="%h %s" HEAD
8d33662 Rewrite the runner as scorekit.cli

 scorekit/cli.py    | 47 +++++++++++++++++++++++++++++++++++++++++++++++
 scorekit/runner.py | 32 --------------------------------
 2 files changed, 47 insertions(+), 32 deletions(-)
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-1-line-across-rename/08-trail-lost -->
```text
$ git log --oneline --follow -- scorekit/cli.py
8d33662 Rewrite the runner as scorekit.cli
$ git blame -s -L '/^def load/,+3' scorekit/cli.py
8d33662c 12) def load(path):
8d33662c 13)     rows = []
8d33662c 14)     for line in open(path):
$ git show --name-status --format="%h %s" -M30% HEAD
8d33662 Rewrite the runner as scorekit.cli

R033	scorekit/runner.py	scorekit/cli.py
```
<!-- /snippet -->

The commit is shown as one deleted and one added file. `--follow` finds one commit. Blame attributes the `load` function to you, today, although those three lines are older than the rewrite. The last command shows why: the two files are 33% similar, below the default threshold of 50%, so every tool that uses the default treats the file as new.

### Recovery

Make the same change as two commits: the rename alone, then the rewrite. The old branch keeps the result while you rebuild it, so nothing can be lost.

```bash
git switch --quiet -c refactor/cli-split refactor/cli~1
git mv scorekit/runner.py scorekit/cli.py
git commit -q -m "Rename the runner module to cli"
git restore --source=refactor/cli -- scorekit/cli.py
git commit -q -am "Rewrite the command-line entry point with argparse"
```

<!-- snippet: ch14a/lab-11-1-line-across-rename/09-recovery -->
```text
# Same end result, two commits: first the rename alone, then the rewrite.
$ git switch --quiet -c refactor/cli-split refactor/cli~1
$ git mv scorekit/runner.py scorekit/cli.py
$ git commit -q -m "Rename the runner module to cli"
$ git restore --source=refactor/cli -- scorekit/cli.py
$ git commit -q -am "Rewrite the command-line entry point with argparse"
```
<!-- /snippet -->

🔴 `git restore --source` overwrites the working tree file. That is intended here: the file was committed one step earlier.

### Verification

```bash
git diff --stat refactor/cli refactor/cli-split
git log --oneline --follow -- scorekit/cli.py
git blame -s -L '/^def load/,+3' scorekit/cli.py
git branch -D refactor/cli
```

<!-- snippet: ch14a/lab-11-1-line-across-rename/10-verification -->
```text
$ git diff --stat refactor/cli refactor/cli-split
$ git log --oneline --follow -- scorekit/cli.py
fd77a3b Rewrite the command-line entry point with argparse
b6977fe Rename the runner module to cli
ca7e2b7 Fail fast on an empty reference
7823232 Add ROUGE-L metric
9c8df98 Reformat sources: four-space indent, double quotes
be9ad1b Fix crash when --limit is not given
074d492 Send warnings to stderr
8dc82cb Add --limit option to the runner
b4b066b Skip rows with an empty reference
682bc71 Add config module with the pass mark
18bb23e Rename the scorer module to metrics
d38a5aa Move sources into the scorekit package
633e3e6 Add evaluation runner and smoke set
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-1-line-across-rename/11-verification-blame -->
```text
$ git blame -s -L '/^def load/,+3' scorekit/cli.py
b4b066b4 scorekit/runner.py 12) def load(path):
9c8df982 scorekit/runner.py 13)     rows = []
9c8df982 scorekit/runner.py 14)     for line in open(path):
$ git branch -D refactor/cli
Deleted branch refactor/cli (was 8d33662).
```
<!-- /snippet -->

The empty diff proves that the two branches end in the same tree. The history of the split branch reaches back to `633e3e6`, and blame gives the surviving lines back to their commits. Your two new commit IDs differ from the ones printed.

### Questions

1. Why did `git blame -w` attribute the line to the same commit as plain blame, although the formatter commit is mostly whitespace?
2. In the output of `git blame --ignore-rev`, where does the name `run_eval.py` come from, given that no commit records a rename?
3. `git log -- scorekit/runner.py` lists `d38a5aa` as its oldest commit, `--follow` lists `633e3e6`. State what each command matches.
4. In the failure scenario, the new file still contains the `load` function unchanged. Why was the rename not detected anyway, and which option would have detected it?
5. The recovery produced the same final tree in two commits. What is different for a reviewer, for `git blame`, and for a later `git bisect`?
6. A teammate proposes to set `log.follow=true` globally "so that history never stops at renames". What does that setting do, and name two of its limits.

## Lab 11.2: Find when a string was removed, with `-S` and then with `-G`

### Objective

Find the commit that removed a log message, and the reason, with `git log -S`. Use `-G` to see the edits that `-S` does not report. Then get a wrong answer from an over-specific search string and correct it.

### Prerequisites

Chapter 14A, sections 14A.11 and 14A.12.

### Setup

```bash
bash labs/ch14a/setup-11-2-pickaxe-removed-string.sh
labs/shell m11-2
cd scorekit
```

The nightly job's log used to contain lines reading `skipped empty reference`. The team's log parser alerts on them. Since Monday there are none, and nobody remembers a decision to remove the message.

### Commands

```bash
git grep -n "skipped empty reference"
git log --format='%h %ad %<(10)%an %s' --date=short -S'skipped empty reference'
```

Two commits. Decide which one added the string and which one removed it, then read the removal:

```bash
git show ca7e2b7
```

Now ask which commits touched a line that contains the string, and predict how many more there are:

```bash
git log --format='%h %ad %<(10)%an %s' --date=short -G'skipped empty reference'
git log -p --format='commit %h %s' -G'skipped empty reference' -- scorekit/runner.py | grep -E '^commit|^[-+].*skipped'
git log -s --format='%h %s' -L '/skipped empty reference/,+1:scorekit/runner.py' ca7e2b7~1
```

### Expected output

<!-- snippet: ch14a/lab-11-2-pickaxe-removed-string/01-gone -->
```text
$ git grep -n "skipped empty reference"
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-2-pickaxe-removed-string/02-S -->
```text
$ git log --format='%h %ad %<(10)%an %s' --date=short -S'skipped empty reference'
ca7e2b7 2026-09-14 Asha Rao   Fail fast on an empty reference
b4b066b 2026-09-09 Lab User   Skip rows with an empty reference
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-2-pickaxe-removed-string/03-removal -->
```text
$ git show ca7e2b7
commit ca7e2b7fcc44f8d5a494107b68440c3d4ec23b55
Author: Asha Rao <asha@example.com>
Date:   Mon Sep 14 14:51:00 2026 +0530

    Fail fast on an empty reference
    
    A silent skip changed the denominator of every average. An empty reference is a data bug:
    stop the run and name the row.

diff --git a/scorekit/runner.py b/scorekit/runner.py
index e5512ca..9a2f84d 100644
--- a/scorekit/runner.py
+++ b/scorekit/runner.py
@@ -11,8 +11,7 @@ def load(path):
     for line in open(path):
         row = json.loads(line)
         if not row["reference"].strip():
-            print("skipped empty reference", file=sys.stderr)
-            continue
+            raise ValueError("empty reference in row %d" % row["id"])
         rows.append(row)
     return rows
 
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-2-pickaxe-removed-string/04-G -->
```text
$ git log --format='%h %ad %<(10)%an %s' --date=short -G'skipped empty reference'
ca7e2b7 2026-09-14 Asha Rao   Fail fast on an empty reference
9c8df98 2026-09-11 Asha Rao   Reformat sources: four-space indent, double quotes
074d492 2026-09-10 Ravi Menon Send warnings to stderr
b4b066b 2026-09-09 Lab User   Skip rows with an empty reference
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-2-pickaxe-removed-string/05-what-G-saw -->
```text
$ git log -p --format='commit %h %s' -G'skipped empty reference' -- scorekit/runner.py | grep -E '^commit|^[-+].*skipped'
commit ca7e2b7 Fail fast on an empty reference
-            print("skipped empty reference", file=sys.stderr)
commit 9c8df98 Reformat sources: four-space indent, double quotes
-      print('skipped empty reference', file=sys.stderr)
+            print("skipped empty reference", file=sys.stderr)
commit 074d492 Send warnings to stderr
-      print('skipped empty reference')
+      print('skipped empty reference', file=sys.stderr)
commit b4b066b Skip rows with an empty reference
+      print('skipped empty reference')
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-2-pickaxe-removed-string/06-line-history -->
```text
# The same story as line history, starting from the last commit that still had the line (ca7e2b7~1):
$ git log -s --format='%h %s' -L '/skipped empty reference/,+1:scorekit/runner.py' ca7e2b7~1
9c8df98 Reformat sources: four-space indent, double quotes
074d492 Send warnings to stderr
b4b066b Skip rows with an empty reference
```
<!-- /snippet -->

### What happened internally

For every commit on the walk, Git compared the commit's tree with its parent's. `-S` counted the occurrences of the string in each changed file before and after, and kept the commits where the count differs: 0 to 1 in `b4b066b`, 1 to 0 in `ca7e2b7`. `-G` produced the patch of each changed file and kept the commits in which an added or removed line matches. That includes the two commits in between, which rewrote the line and left the string in it: one added `file=sys.stderr`, the other was the formatter changing quotes.

The last command is the same story told by `git log -L`, started from `ca7e2b7~1`, the last commit in which the line exists. A range for `-L` must exist in the starting revision, so it cannot start from `main`.

### Checkpoint

You can answer the incident question with evidence: Asha removed the message on 14 September in `ca7e2b7`, deliberately, and the commit message gives the reason. You can also say which commit moved the message from standard output to standard error, which the log parser's owner will want to know.

### Failure scenario

A colleague copies the whole statement from an old version of the log-parsing documentation and searches for that:

```bash
git log --format='%h %ad %<(10)%an %s' --date=short -S"print('skipped empty reference')"
git show --format='%h %an: %s' 074d492
```

<!-- snippet: ch14a/lab-11-2-pickaxe-removed-string/07-failure -->
```text
# A colleague copies the whole statement from an old log-parsing script and searches for that:
$ git log --format='%h %ad %<(10)%an %s' --date=short -S"print('skipped empty reference')"
074d492 2026-09-10 Ravi Menon Send warnings to stderr
b4b066b 2026-09-09 Lab User   Skip rows with an empty reference
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-2-pickaxe-removed-string/08-diagnose -->
```text
$ git show --format='%h %an: %s' 074d492
074d492 Ravi Menon: Send warnings to stderr

diff --git a/scorekit/runner.py b/scorekit/runner.py
index f671284..d75e2c2 100644
--- a/scorekit/runner.py
+++ b/scorekit/runner.py
@@ -10,7 +10,7 @@ def load(path):
   for line in open(path):
     row = json.loads(line)
     if not row['reference'].strip():
-      print('skipped empty reference')
+      print('skipped empty reference', file=sys.stderr)
       continue
     rows.append(row)
   return rows
```
<!-- /snippet -->

The search reports `074d492` as the newest commit that changed the count, and the colleague tells the team that Ravi removed the warning on 10 September. The patch shows otherwise: the message is still there. The search string ended in `')`, and Ravi's edit put `, file=sys.stderr` between the quote and the parenthesis. The long string disappeared; the message did not.

### Recovery

Count the short, stable string on both sides of the suspected commit, then search for that:

```bash
git grep -c 'skipped empty reference' 074d492~1 074d492 -- scorekit/runner.py
git log --oneline -S'skipped empty reference'
```

<!-- snippet: ch14a/lab-11-2-pickaxe-removed-string/09-recovery -->
```text
$ git grep -c 'skipped empty reference' 074d492~1 074d492 -- scorekit/runner.py
074d492~1:scorekit/runner.py:1
074d492:scorekit/runner.py:1
$ git log --oneline -S'skipped empty reference'
ca7e2b7 Fail fast on an empty reference
b4b066b Skip rows with an empty reference
```
<!-- /snippet -->

One occurrence before and one after: `074d492` did not remove the message.

### Verification

```bash
git grep -c 'skipped empty reference' ca7e2b7~1 -- scorekit/runner.py
git grep -c 'skipped empty reference' ca7e2b7 -- scorekit/runner.py
```

<!-- snippet: ch14a/lab-11-2-pickaxe-removed-string/10-verification -->
```text
$ git grep -c 'skipped empty reference' ca7e2b7~1 -- scorekit/runner.py
ca7e2b7~1:scorekit/runner.py:1
$ git grep -c 'skipped empty reference' ca7e2b7 -- scorekit/runner.py
[exit status: 1]
```
<!-- /snippet -->

One occurrence in the parent, none in `ca7e2b7` (`git grep` exits with status 1 when it finds nothing). That is the removal.

### Questions

1. State precisely what `-S'skipped empty reference'` tests for each commit. Why does it report two commits and not four?
2. `-G` reported the formatter commit. Is that a false positive? Explain what `-G` matched there.
3. In the failure scenario the search was more specific and the answer was worse. Formulate a rule for choosing the string to give to `-S`.
4. Neither search used `--all`. Under which circumstances would the removal not have been found, and what would you add?
5. The string was removed on purpose. Which part of the output tells you that, and what would you do next if the commit message had been "cleanup"?
6. How would you find the commit that removed the message if the line had been moved to another file in the same commit that reworded it?

## Lab 11.3: Find a deleted file

### Objective

Find a file that no longer exists in the working tree, the commit that deleted it and the stated reason, read its last content, and bring it back on a branch.

### Prerequisites

Chapter 14A, sections 14A.3 and 14A.13. Chapter 11, `git restore --source`.

### Setup

```bash
bash labs/ch14a/setup-11-3-deleted-file.sh
labs/shell m11-3
cd scorekit
```

A teammate wants to try a brevity penalty and remembers that the project once had a BLEU scorer. It is not in the tree.

### Commands

```bash
git ls-files | grep -i bleu
git grep -n -i bleu
git log --diff-filter=D --name-status --format='%h %ad %an: %s' --date=short
git log --format='%h %ad %<(10)%an %s' --date=short -- '*bleu*'
```

Predict before you run the next block: in which commit can the content of the file be read?

```bash
git show --stat d9d075d
git show d9d075d~1:scorekit/bleu.py
```

Bring it back on a branch of its own:

```bash
git switch --quiet -c experiment/bleu
git restore --source=d9d075d~1 -- scorekit/bleu.py
git status --short
python3 -B -c 'from scorekit.bleu import bleu1; print(round(bleu1("the cat", "the cat sat"), 3))'
git add scorekit/bleu.py && git commit -q -m 'Bring back the BLEU scorer for the brevity experiment'
git log --oneline -3 -- scorekit/bleu.py
```

### Expected output

<!-- snippet: ch14a/lab-11-3-deleted-file/01-gone -->
```text
$ git ls-files | grep -i bleu
[exit status: 1]
$ git grep -n -i bleu
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-3-deleted-file/02-deletions -->
```text
$ git log --diff-filter=D --name-status --format='%h %ad %an: %s' --date=short
d9d075d 2026-09-14 Ravi Menon: Remove the experimental BLEU scorer

D	scorekit/bleu.py
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-3-deleted-file/03-path-history -->
```text
$ git log --format='%h %ad %<(10)%an %s' --date=short -- '*bleu*'
d9d075d 2026-09-14 Ravi Menon Remove the experimental BLEU scorer
9c8df98 2026-09-11 Asha Rao   Reformat sources: four-space indent, double quotes
c0d33a5 2026-09-09 Asha Rao   Add a tokens helper and use it in the metrics
dd70d9e 2026-09-09 Asha Rao   Move normalize into scorekit/text.py
18bb23e 2026-09-08 Asha Rao   Rename the scorer module to metrics
d38a5aa 2026-09-08 Lab User   Move sources into the scorekit package
d369eac 2026-09-07 Ravi Menon Add experimental BLEU scorer
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-3-deleted-file/04-why -->
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

<!-- snippet: ch14a/lab-11-3-deleted-file/05-last-content -->
```text
$ git show d9d075d~1:scorekit/bleu.py
import math
from collections import Counter

from scorekit.text import tokens


def bleu1(prediction, reference):
    pred = tokens(prediction)
    ref = tokens(reference)
    if not pred:
        return 0.0
    overlap = sum((Counter(pred) & Counter(ref)).values())
    precision = overlap / len(pred)
    brevity = 1.0 if len(pred) >= len(ref) else math.exp(1 - len(ref) / len(pred))
    return brevity * precision
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-3-deleted-file/06-restore -->
```text
$ git switch --quiet -c experiment/bleu
$ git restore --source=d9d075d~1 -- scorekit/bleu.py
$ git status --short
?? scorekit/bleu.py
$ python3 -B -c 'from scorekit.bleu import bleu1; print(round(bleu1("the cat", "the cat sat"), 3))'
0.607
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-3-deleted-file/07-commit -->
```text
$ git add scorekit/bleu.py && git commit -q -m 'Bring back the BLEU scorer for the brevity experiment'
$ git log --oneline -3 -- scorekit/bleu.py
af0d310 Bring back the BLEU scorer for the brevity experiment
d9d075d Remove the experimental BLEU scorer
9c8df98 Reformat sources: four-space indent, double quotes
```
<!-- /snippet -->

### What happened internally

`--diff-filter=D` kept the commits whose diff against their parent contains a deletion; there is one. The pathspec `'*bleu*'` matched every path with that fragment in any directory, so the log also reached the time when the file was `bleu.py` at the top level, without rename detection. The deleting commit's tree has no entry for the file; its parent's tree has one, pointing at a blob that still exists in the object database. `git show <commit>~1:<path>` printed that blob. `git restore --source` wrote it into the working tree and did not touch the index, which is why `git status` shows the file as untracked. Your commit then added a new tree entry pointing at the same blob: no content was copied.

### Checkpoint

You know who deleted the file, when and why, without asking anyone, and `experiment/bleu` contains it again with a commit that says what it is for. `main` is unchanged.

### Failure scenario

On `main`, a colleague tries the same with the ID of the deleting commit itself, and then looks for the file's history without the `--`:

```bash
git switch --quiet main
git restore --source=d9d075d -- scorekit/bleu.py
git show d9d075d:scorekit/bleu.py
git log --oneline scorekit/bleu.py
```

<!-- snippet: ch14a/lab-11-3-deleted-file/08-failure -->
```text
# On another machine a colleague tries the same with the ID of the deleting commit itself:
$ git switch --quiet main
$ git restore --source=d9d075d -- scorekit/bleu.py
error: pathspec 'scorekit/bleu.py' did not match any file(s) known to git
[exit status: 1]
$ git show d9d075d:scorekit/bleu.py
fatal: path 'scorekit/bleu.py' does not exist in 'd9d075d'
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-3-deleted-file/09-failure-no-dashes -->
```text
$ git log --oneline scorekit/bleu.py
fatal: ambiguous argument 'scorekit/bleu.py': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
```
<!-- /snippet -->

Three errors, one cause each. The deleting commit is the first commit that does not have the file, so there is nothing to restore from it or show in it. And without `--`, Git has to guess whether `scorekit/bleu.py` is a revision or a path; no such revision exists and no such file exists in the working tree, so it refuses to guess.

### Recovery

```bash
git log --oneline -1 -- scorekit/bleu.py
git cat-file -e d9d075d~1:scorekit/bleu.py && echo 'the parent has the file'
git restore --source=d9d075d~1 -- scorekit/bleu.py
git status --short
```

<!-- snippet: ch14a/lab-11-3-deleted-file/10-recovery -->
```text
$ git log --oneline -1 -- scorekit/bleu.py
d9d075d Remove the experimental BLEU scorer
$ git cat-file -e d9d075d~1:scorekit/bleu.py && echo 'the parent has the file'
the parent has the file
$ git restore --source=d9d075d~1 -- scorekit/bleu.py
$ git status --short
?? scorekit/bleu.py
```
<!-- /snippet -->

The newest commit that touched the path is the deletion; one step before it the file exists. `git cat-file -e` tests for an object without printing it.

### Verification

```bash
git hash-object scorekit/bleu.py
git rev-parse d9d075d~1:scorekit/bleu.py experiment/bleu:scorekit/bleu.py
rm scorekit/bleu.py && git status --short --branch
```

<!-- snippet: ch14a/lab-11-3-deleted-file/11-verification -->
```text
$ git hash-object scorekit/bleu.py
fe719d46a15c7bb07ccc0a431c3535e8bbce8729
$ git rev-parse d9d075d~1:scorekit/bleu.py experiment/bleu:scorekit/bleu.py
fe719d46a15c7bb07ccc0a431c3535e8bbce8729
fe719d46a15c7bb07ccc0a431c3535e8bbce8729
$ rm scorekit/bleu.py && git status --short --branch
## main
```
<!-- /snippet -->

The restored file hashes to the same blob ID as the file in the parent of the deletion and the file on the experiment branch. The last command removes the untracked copy and leaves `main` clean.

### Questions

1. Why does the content of a deleted file have to be read from `<commit>~1` and not from `<commit>`?
2. After `git restore --source=d9d075d~1 -- scorekit/bleu.py` the file is untracked. Which of the three trees did the command write to, and how would you have written to two of them at once?
3. `git log -- scorekit/bleu.py` and `git log -- '*bleu*'` differ by one commit. Which one, and why?
4. `git revert d9d075d` would also bring the file back. What else would it change, and when would you prefer it?
5. The deleting commit also changed `docs/metrics.md`. Write one command that lists every path deleted between `v0.1.0` and `main`, without walking the commits in between, and say what it cannot tell you that the log command can.
6. The three blob IDs in the verification are equal. What does that tell you about how much new data the commit on `experiment/bleu` added to the object database?

## Lab 11.4: A manual bisect

### Objective

Find the commit that introduced a regression by binary search, giving each verdict by hand. Then give one wrong verdict, see where bisect ends up, and repair the session with `git bisect log` and `git bisect replay`.

### Prerequisites

Chapter 14A, sections 14A.20 and 14A.22. Chapter 7, section 7.7 (detached HEAD).

### Setup

```bash
bash labs/ch14a/setup-11-4-manual-bisect.sh
labs/shell m11-4
cd scorekit
```

This is the second regression of the repository, independent of the one the chapter investigates. For the answers "new york new york" and "new york new york city", `token_f1` returned 0.889 in `v0.1.0`. On `main` it returns 0.444. Do not look at the source yet.

### Commands

Define the test once. It prints the value; you decide.

```bash
check() { python3 -B -c 'from scorekit.metrics import token_f1; print(round(token_f1("new york new york", "new york new york city"), 3))'; }
check
git switch --quiet --detach v0.1.0 && check && git switch --quiet main
```

Before you start: there are twenty commits between `v0.1.0` and `main`. Write down how many tests you expect to need.

```bash
git bisect start
git bisect bad main
git bisect good v0.1.0
```

Then repeat: run `check`, and answer `git bisect good` for 0.889 or `git bisect bad` for 0.444, until Git names a commit. Finish with:

```bash
git show --format="%h %an %ad%n%n    %s%n%n    %b" --date=short refs/bisect/bad
git bisect log
git bisect reset
```

### Expected output

<!-- snippet: ch14a/lab-11-4-manual-bisect/01-test -->
```text
$ check() { python3 -B -c 'from scorekit.metrics import token_f1; print(round(token_f1("new york new york", "new york new york city"), 3))'; }
$ check
0.444
$ git switch --quiet --detach v0.1.0 && check && git switch --quiet main
0.889
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-4-manual-bisect/02-start -->
```text
$ git bisect start
status: waiting for both 'good' and 'bad' commits
$ git bisect bad main
status: waiting for 'good' commit(s), 'bad' commit known
$ git bisect good v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-4-manual-bisect/03-step-1 -->
```text
$ check
0.889
$ git bisect good
Bisecting: 4 revisions left to test after this (roughly 2 steps)
[c0c9a304c3598a2f53abb36a10d5abe10e723be4] Add nightly evaluation set
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-4-manual-bisect/04-step-2 -->
```text
$ check
0.889
$ git bisect good
Bisecting: 2 revisions left to test after this (roughly 1 step)
[d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-4-manual-bisect/05-step-3 -->
```text
$ check
0.444
$ git bisect bad
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[ec4fad75a7e73526c6694c2559094bbe05e00980] Simplify token overlap in token_f1
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-4-manual-bisect/06-step-4 -->
```text
$ check
0.444
$ git bisect bad
ec4fad75a7e73526c6694c2559094bbe05e00980 is the first 'bad' commit
commit ec4fad75a7e73526c6694c2559094bbe05e00980
Author: Asha Rao <asha@example.com>
Date:   Mon Sep 14 10:31:00 2026 +0530

    Simplify token overlap in token_f1
    
    A set intersection says the same thing without the Counter import.

 scorekit/metrics.py | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-4-manual-bisect/07-result -->
```text
$ git show --format="%h %an %ad%n%n    %s%n%n    %b" --date=short refs/bisect/bad
ec4fad7 Asha Rao 2026-09-14

    Simplify token overlap in token_f1

    A set intersection says the same thing without the Counter import.


diff --git a/scorekit/metrics.py b/scorekit/metrics.py
index cd9f708..d830107 100644
--- a/scorekit/metrics.py
+++ b/scorekit/metrics.py
@@ -1,5 +1,3 @@
-from collections import Counter
-
 from scorekit.text import normalize, tokens
 
 
@@ -10,7 +8,7 @@ def exact_match(prediction, reference):
 def token_f1(prediction, reference):
     pred = tokens(prediction)
     ref = tokens(reference)
-    overlap = sum((Counter(pred) & Counter(ref)).values())
+    overlap = len(set(pred) & set(ref))
     if overlap == 0:
         return 0.0
     precision = overlap / len(pred)
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-4-manual-bisect/08-log -->
```text
$ git bisect log
git bisect start
# status: waiting for both 'good' and 'bad' commits
# bad: [e376e5b709142415a87d49ca10af71977aaeabdc] Mention the nightly run in the README
git bisect bad e376e5b709142415a87d49ca10af71977aaeabdc
# status: waiting for 'good' commit(s), 'bad' commit known
# good: [682bc717015f0ab43b873d1df1ac9da0ba01c393] Add config module with the pass mark
git bisect good 682bc717015f0ab43b873d1df1ac9da0ba01c393
# good: [074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
git bisect good 074d49249bcd54bc33537fe26519dd38e3c3ba85
# good: [c0c9a304c3598a2f53abb36a10d5abe10e723be4] Add nightly evaluation set
git bisect good c0c9a304c3598a2f53abb36a10d5abe10e723be4
# bad: [d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
git bisect bad d9d075d63dcc94ce04c8e404e06b5cc3173180c2
# bad: [ec4fad75a7e73526c6694c2559094bbe05e00980] Simplify token overlap in token_f1
git bisect bad ec4fad75a7e73526c6694c2559094bbe05e00980
# first 'bad' commit: [ec4fad75a7e73526c6694c2559094bbe05e00980] Simplify token overlap in token_f1
$ git bisect reset
Previous HEAD position was ec4fad7 Simplify token overlap in token_f1
Switched to branch 'main'
```
<!-- /snippet -->

### What happened internally

`git bisect start` and the two endpoint commands wrote `BISECT_START`, `BISECT_LOG` and `BISECT_TERMS` into `.git`, and the refs `refs/bisect/bad` and `refs/bisect/good-<id>`. Git then computed the candidates, `v0.1.0..main`, chose the commit that splits them most evenly and checked it out with HEAD detached. Each verdict added one ref and one line to `BISECT_LOG`, shrank the candidate set to one half, and checked out the next midpoint. After four verdicts one candidate was left. `git bisect reset` checked out `main` again and deleted the refs and files.

The first commit you tested, `074d492`, is one of the two in which the runner crashes. Your test does not use the runner, so the commit could be judged. Whether a commit is testable depends on the test, not on the commit.

The culprit replaced a multiset intersection with a set intersection. For answers without repeated words the two agree, which is why nobody noticed.

### Checkpoint

Four tests for twenty candidates, and the result is `ec4fad7` "Simplify token overlap in token_f1". After the reset, `git status` shows `main` and a clean tree.

### Failure scenario

Start again and give one wrong verdict: at the second step the value is 0.889, and you answer `bad`.

```bash
git bisect start main v0.1.0
check
git bisect good
check
git bisect bad
```

Continue with correct verdicts until Git names a commit, then look at it:

```bash
git show --stat --format="%h %s" refs/bisect/bad
git grep -c token_f1 refs/bisect/bad -- data
```

<!-- snippet: ch14a/lab-11-4-manual-bisect/09-failure -->
```text
# A second attempt. At the second step the output is read carelessly and the commit is marked bad:
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
$ check
0.889
$ git bisect good
Bisecting: 4 revisions left to test after this (roughly 2 steps)
[c0c9a304c3598a2f53abb36a10d5abe10e723be4] Add nightly evaluation set
$ check
0.889
$ git bisect bad
Bisecting: 2 revisions left to test after this (roughly 1 step)
[d926d3c5a77b586297eb25335c33fed4aee6f053] Speed up normalize with a precompiled pattern
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-4-manual-bisect/10-failure-result -->
```text
$ check
0.889
$ git bisect good
Bisecting: 0 revisions left to test after this (roughly 1 step)
[78232321c82cb23d6fb732e4c8ee614c6f005919] Add ROUGE-L metric
$ check
0.889
$ git bisect good
c0c9a304c3598a2f53abb36a10d5abe10e723be4 is the first 'bad' commit
commit c0c9a304c3598a2f53abb36a10d5abe10e723be4
Author: Asha Rao <asha@example.com>
Date:   Fri Sep 11 16:21:00 2026 +0530

    Add nightly evaluation set
    
    Seeded from the smoke set, plus four rows.

 data/nightly.jsonl | 14 ++++++++++++++
 1 file changed, 14 insertions(+)
 create mode 100644 data/nightly.jsonl
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-4-manual-bisect/11-diagnose -->
```text
# The commit that Git names adds a data file. It cannot change what token_f1 returns for two strings.
$ git show --stat --format="%h %s" refs/bisect/bad
c0c9a30 Add nightly evaluation set

 data/nightly.jsonl | 14 ++++++++++++++
 1 file changed, 14 insertions(+)
$ git grep -c token_f1 refs/bisect/bad -- data
```
<!-- /snippet -->

Bisect did what it was told. Every later test said "good", so the search narrowed onto the commit you had called bad, and Git reported it as the first bad commit with full confidence. The commit adds a data file. It cannot change the result of a function call on two strings; `git grep -c` finds no mention of the function under `data` and exits with status 1. An implausible culprit means a wrong verdict somewhere.

### Recovery

Do not start over. Save the log, cut it after the last verdict you trust, and replay it:

```bash
git bisect log > ../bisect.log
grep -n "^git bisect" ../bisect.log
sed -n '1,/^git bisect good/p' ../bisect.log > ../bisect-fixed.log
cat ../bisect-fixed.log
git bisect reset
git bisect replay ../bisect-fixed.log
```

<!-- snippet: ch14a/lab-11-4-manual-bisect/12-recovery -->
```text
$ git bisect log > ../bisect.log
$ grep -n "^git bisect" ../bisect.log
3:git bisect start 'main' 'v0.1.0'
5:git bisect good 074d49249bcd54bc33537fe26519dd38e3c3ba85
7:git bisect bad c0c9a304c3598a2f53abb36a10d5abe10e723be4
9:git bisect good d926d3c5a77b586297eb25335c33fed4aee6f053
11:git bisect good 78232321c82cb23d6fb732e4c8ee614c6f005919
# Keep the start line and the first, correct mark. Delete everything from the wrong mark on.
$ sed -n '1,/^git bisect good/p' ../bisect.log > ../bisect-fixed.log
$ cat ../bisect-fixed.log
# bad: [e376e5b709142415a87d49ca10af71977aaeabdc] Mention the nightly run in the README
# good: [682bc717015f0ab43b873d1df1ac9da0ba01c393] Add config module with the pass mark
git bisect start 'main' 'v0.1.0'
# good: [074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
git bisect good 074d49249bcd54bc33537fe26519dd38e3c3ba85
```
<!-- /snippet -->

The `sed` command keeps everything up to and including the first `git bisect good` line. With an editor you would delete the wrong line and all lines after it. Replay puts you back at the second step; continue with correct verdicts:

<!-- snippet: ch14a/lab-11-4-manual-bisect/13-replay -->
```text
$ git bisect reset
Previous HEAD position was 7823232 Add ROUGE-L metric
Switched to branch 'main'
$ git bisect replay ../bisect-fixed.log
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
Bisecting: 4 revisions left to test after this (roughly 2 steps)
[c0c9a304c3598a2f53abb36a10d5abe10e723be4] Add nightly evaluation set
$ check
0.889
$ git bisect good
Bisecting: 2 revisions left to test after this (roughly 1 step)
[d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-4-manual-bisect/14-finish -->
```text
$ check
0.444
$ git bisect bad
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[ec4fad75a7e73526c6694c2559094bbe05e00980] Simplify token overlap in token_f1
$ check
0.444
$ git bisect bad
ec4fad75a7e73526c6694c2559094bbe05e00980 is the first 'bad' commit
commit ec4fad75a7e73526c6694c2559094bbe05e00980
Author: Asha Rao <asha@example.com>
Date:   Mon Sep 14 10:31:00 2026 +0530

    Simplify token overlap in token_f1
    
    A set intersection says the same thing without the Counter import.

 scorekit/metrics.py | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)
```
<!-- /snippet -->

### Verification

A bisect result is a claim. Test the commit and its parent directly:

```bash
git bisect reset
git status --short --branch
git switch --quiet --detach ec4fad7~1 && check
git switch --quiet --detach ec4fad7 && check
git switch --quiet main
```

<!-- snippet: ch14a/lab-11-4-manual-bisect/15-verification -->
```text
$ git bisect reset
Previous HEAD position was ec4fad7 Simplify token overlap in token_f1
Switched to branch 'main'
$ git status --short --branch
## main
$ git switch --quiet --detach ec4fad7~1 && check
0.889
$ git switch --quiet --detach ec4fad7 && check
0.444
$ git switch --quiet main
```
<!-- /snippet -->

### Questions

1. Git printed "9 revisions left to test after this (roughly 3 steps)" for twenty candidates. Explain the 9.
2. During the bisection, what was HEAD, and what happened to the branch `main`? Where would a commit made in the middle of the session have ended up?
3. The first commit Git offered crashes when the runner is started, yet you could give a verdict. Why, and what would you have typed if your test had been the runner?
4. After the wrong verdict, Git still reported a "first bad commit". Which assumption of bisect makes it unable to notice the contradiction?
5. Why is `git bisect replay` with an edited log better than starting again, for a search with fourteen steps and a ten-minute test?
6. The culprit's message says that a set intersection "says the same thing". Write the smallest pair of inputs that shows it does not, and say what test you would add with the fix.

## Lab 11.5: An automated `git bisect run`

### Objective

Let `git bisect run` do the search of Lab 11.4 with a one-line test, then find the chapter's exact-match regression with a script that follows the exit-code protocol. Then use a careless test and get a precise, wrong answer.

### Prerequisites

Chapter 14A, section 14A.21. Lab 11.4.

### Setup

```bash
bash labs/ch14a/setup-11-5-bisect-run.sh
labs/shell m11-5
cd scorekit
```

The test scripts go into the directory above the repository, so that no checkout can change or remove them.

### Commands

First the regression you already know. Write the test:

```bash
cat > ../check-f1.sh <<'EOF'
#!/bin/sh
# good (0) when token_f1 counts repeated tokens, bad (1) when it does not
python3 -B -c '
import sys
from scorekit.metrics import token_f1
sys.exit(0 if token_f1("new york new york", "new york new york city") > 0.8 else 1)'
EOF
chmod +x ../check-f1.sh
../check-f1.sh; echo "exit status: $?"
git bisect start main v0.1.0
git bisect run ../check-f1.sh
git bisect reset
```

Now the other regression: `exact_match` on the smoke set was 0.800 and is 0.400. The runner's output is the evidence, and the runner does not work in every commit. Before you write the script, decide what it must answer for a commit in which the runner crashes.

```bash
python3 -B -m scorekit.runner data/smoke.jsonl; echo "exit status: $?"
cat > ../check-em.sh <<'EOF'
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
chmod +x ../check-em.sh
git rev-list --count v0.1.0..main
git bisect start main v0.1.0
git bisect run ../check-em.sh
git bisect log | grep -v "^#"
git bisect reset
```

### Expected output

<!-- snippet: ch14a/lab-11-5-bisect-run/01-f1-script -->
```text
$ cat ../check-f1.sh
#!/bin/sh
# good (0) when token_f1 counts repeated tokens, bad (1) when it does not
python3 -B -c '
import sys
from scorekit.metrics import token_f1
sys.exit(0 if token_f1("new york new york", "new york new york city") > 0.8 else 1)'
$ ../check-f1.sh; echo "exit status: $?"
exit status: 1
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-5-bisect-run/02-f1-run -->
```text
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
$ git bisect run ../check-f1.sh
running '../check-f1.sh'
Bisecting: 4 revisions left to test after this (roughly 2 steps)
[c0c9a304c3598a2f53abb36a10d5abe10e723be4] Add nightly evaluation set
running '../check-f1.sh'
Bisecting: 2 revisions left to test after this (roughly 1 step)
[d9d075d63dcc94ce04c8e404e06b5cc3173180c2] Remove the experimental BLEU scorer
running '../check-f1.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[ec4fad75a7e73526c6694c2559094bbe05e00980] Simplify token overlap in token_f1
running '../check-f1.sh'
ec4fad75a7e73526c6694c2559094bbe05e00980 is the first 'bad' commit
commit ec4fad75a7e73526c6694c2559094bbe05e00980
Author: Asha Rao <asha@example.com>
Date:   Mon Sep 14 10:31:00 2026 +0530

    Simplify token overlap in token_f1
    
    A set intersection says the same thing without the Counter import.

 scorekit/metrics.py | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)
bisect found first 'bad' commit
$ git bisect reset
Previous HEAD position was ec4fad7 Simplify token overlap in token_f1
Switched to branch 'main'
```
<!-- /snippet -->

The same commit as by hand, with the same four tests.

<!-- snippet: ch14a/lab-11-5-bisect-run/03-em-script -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl; echo "exit status: $?"
rows=10 exact_match=0.400 token_f1=0.444 rouge_l=0.489
exit status: 1
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
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-5-bisect-run/04-em-run -->
```text
$ git rev-list --count v0.1.0..main
20
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

<!-- snippet: ch14a/lab-11-5-bisect-run/05-em-log -->
```text
$ git bisect log | grep -v "^#"
git bisect start 'main' 'v0.1.0'
git bisect skip 074d49249bcd54bc33537fe26519dd38e3c3ba85
git bisect bad d9d075d63dcc94ce04c8e404e06b5cc3173180c2
git bisect good 72134f33df03602df3b2fa85f5b7dfb0aa08c190
git bisect bad 9c8df98229e009115b3044edb1181d11075ecbbb
git bisect good be9ad1b4894348317c1e7ccb8276b8ad4760fb89
git bisect bad d926d3c5a77b586297eb25335c33fed4aee6f053
$ git bisect reset
Previous HEAD position was d926d3c Speed up normalize with a precompiled pattern
Switched to branch 'main'
```
<!-- /snippet -->

### What happened internally

`git bisect run` is the loop you performed by hand in Lab 11.4: run the command in the checked-out commit, translate its exit status into `good`, `bad` or `skip`, let bisect pick the next commit, repeat. Status 0 is good, 1 to 127 is bad, except 125, which is skip. The log of the second run shows one `git bisect skip`: at `074d492` the runner printed no score line, the script exited with 125, and Git chose a different commit instead of drawing a conclusion.

### Checkpoint

Two regressions, two culprits: `ec4fad7` for `token_f1` and `d926d3c` for `exact_match`. You can explain each of the three exit codes of `check-em.sh`.

### Failure scenario

A shortcut suggests itself: the runner already exits with status 1 when the score is below the pass mark. Use the runner as the test.

```bash
cat > ../naive.sh <<'EOF'
#!/bin/sh
python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null
EOF
chmod +x ../naive.sh
git bisect start main v0.1.0
git bisect run ../naive.sh
```

<!-- snippet: ch14a/lab-11-5-bisect-run/06-failure -->
```text
# The shortcut: the runner already exits with 1 when the score is too low. Use it as the test.
$ cat ../naive.sh
#!/bin/sh
python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
$ git bisect run ../naive.sh
running '../naive.sh'
Bisecting: 5 revisions left to test after this (roughly 2 steps)
[389337aa37f6f099b27867f23fdf426b5c0307bd] Raise the pass mark to 0.75
running '../naive.sh'
rows=10 exact_match=0.800 token_f1=0.889
Bisecting: 2 revisions left to test after this (roughly 2 steps)
[86572733d0839c4d7b2fa9cfee3d79de23b487ec] Merge branch 'feat/text-utils'
running '../naive.sh'
rows=10 exact_match=0.800 token_f1=0.889
Bisecting: 0 revisions left to test after this (roughly 1 step)
[8dc82cb2ce1f427dc306bce35c21a41f2e796b8d] Add --limit option to the runner
running '../naive.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[72134f33df03602df3b2fa85f5b7dfb0aa08c190] Document the runner's exit status
running '../naive.sh'
rows=10 exact_match=0.800 token_f1=0.889
8dc82cb2ce1f427dc306bce35c21a41f2e796b8d is the first 'bad' commit
commit 8dc82cb2ce1f427dc306bce35c21a41f2e796b8d
Author: Lab User <you@example.com>
Date:   Thu Sep 10 10:41:00 2026 +0530

    Add --limit option to the runner
    
    python3 -m scorekit.runner data/nightly.jsonl --limit 100 scores the first 100 rows.

 scorekit/runner.py | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)
bisect found first 'bad' commit
```
<!-- /snippet -->

A different answer: `8dc82cb` "Add --limit option to the runner". It is reproducible, it comes with a commit ID, and it is wrong. Find out why before you reset:

```bash
git bisect log | grep -v "^#"
git show --stat --format="%h %s" refs/bisect/bad
git worktree add --detach --quiet ../probe 074d492
(cd ../probe && python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1)
(cd ../probe && ../naive.sh; echo "exit status of naive.sh: $?")
git worktree remove ../probe
```

<!-- snippet: ch14a/lab-11-5-bisect-run/07-diagnose -->
```text
$ git bisect log | grep -v "^#"
git bisect start 'main' 'v0.1.0'
git bisect bad 074d49249bcd54bc33537fe26519dd38e3c3ba85
git bisect good 389337aa37f6f099b27867f23fdf426b5c0307bd
git bisect good 86572733d0839c4d7b2fa9cfee3d79de23b487ec
git bisect bad 8dc82cb2ce1f427dc306bce35c21a41f2e796b8d
git bisect good 72134f33df03602df3b2fa85f5b7dfb0aa08c190
$ git show --stat --format="%h %s" refs/bisect/bad
8dc82cb Add --limit option to the runner

 scorekit/runner.py | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)
# The first verdict was 'bad', for 074d492. Ask that commit the question the script asked:
$ git worktree add --detach --quiet ../probe 074d492
$ (cd ../probe && python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1)
KeyError: '--limit'
$ (cd ../probe && ../naive.sh; echo "exit status of naive.sh: $?")
exit status of naive.sh: 1
$ git worktree remove ../probe
```
<!-- /snippet -->

The first verdict of the run was `bad` for `074d492`. In that commit the runner does not print a low score; it crashes, and a crash also exits with status 1. The script answered a different question ("does the runner exit with 0?") from the one you meant ("is the score right?"). From that verdict on, bisect searched for the first commit in which the runner does not exit with 0, and found it: the commit that introduced the crash.

### Recovery

```bash
git bisect reset
git bisect start main v0.1.0
git bisect run ../check-em.sh | tail -n 12
```

<!-- snippet: ch14a/lab-11-5-bisect-run/08-recovery -->
```text
$ git bisect reset
Previous HEAD position was 72134f3 Document the runner's exit status
Switched to branch 'main'
$ git bisect start main v0.1.0
Bisecting: 9 revisions left to test after this (roughly 3 steps)
[074d49249bcd54bc33537fe26519dd38e3c3ba85] Send warnings to stderr
$ git bisect run ../check-em.sh | tail -n 12
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

### Verification

```bash
git bisect log | grep -c "^git bisect skip"
git bisect reset
git status --short --branch
git for-each-ref refs/bisect | wc -l
```

<!-- snippet: ch14a/lab-11-5-bisect-run/09-verification -->
```text
$ git bisect log | grep -c "^git bisect skip"
1
$ git bisect reset
Previous HEAD position was d926d3c Speed up normalize with a precompiled pattern
Switched to branch 'main'
$ git status --short --branch
## main
$ git for-each-ref refs/bisect | wc -l
       0
```
<!-- /snippet -->

One skip in the log, `main` checked out, no bisect refs left.

### Questions

1. Which exit statuses does `git bisect run` treat as good, bad, skip and abort? Why is 125 the skip code, according to the manual?
2. Why do the test scripts live outside the repository? Describe what would go wrong with a script committed last week.
3. In the failure scenario, bisect found a real "first bad commit" for the test it was given. State that test in words, and state the test you meant.
4. `check-em.sh` treats "no score line" as untestable. Name a situation in which that choice hides the regression you are looking for.
5. The evaluation behind this test is deterministic. What would you change in the script for a metric with run-to-run noise of about 0.02?
6. Both runs started with `git bisect start main v0.1.0`. How many candidates is that, and how many would there be if you added `-- scorekit/text.py` to the start command? What do you risk by adding it?

## Lab 11.6: Blame through a reformatting commit with an ignore-revs file

### Objective

Make `git blame` useful again after a formatter commit: with `-w`, with `--ignore-rev`, and permanently with a committed ignore list and `blame.ignoreRevsFile`. Then break blame for older commits with that same setting, and repair it.

### Prerequisites

Chapter 14A, sections 14A.5, 14A.16 and 14A.17.

### Setup

```bash
bash labs/ch14a/setup-11-6-blame-ignore-revs.sh
labs/shell m11-6
cd scorekit
```

### Commands

```bash
git blame --date=short -L :main scorekit/runner.py
git show --stat --format='%h %an, %ad: %s' --date=short 9c8df98
```

Predict which lines `-w` will give back to their earlier commits and which it will not. Section 14A.5 has what you need.

```bash
git blame --date=short -w -L :main scorekit/runner.py
git blame --date=short --ignore-rev 9c8df98 -L :main scorekit/runner.py
```

Make it permanent:

```bash
printf '# Formatter run: four-space indent, double quotes (Asha, 11 Sep 2026)\n' > .git-blame-ignore-revs
git rev-parse 9c8df98 >> .git-blame-ignore-revs
cat .git-blame-ignore-revs
git config set blame.ignoreRevsFile .git-blame-ignore-revs
git config set blame.markIgnoredLines true
git blame --date=short -L :main scorekit/runner.py
git add .git-blame-ignore-revs
git commit -q -m "List the formatter commit for git blame"
git config list --local | grep blame
```

### Expected output

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/01-plain -->
```text
$ git blame --date=short -L :main scorekit/runner.py
8dc82cb2 scorekit/runner.py (Lab User 2026-09-10 19) def main(argv):
9c8df982 scorekit/runner.py (Asha Rao 2026-09-11 20)     path = argv[1]
9c8df982 scorekit/runner.py (Asha Rao 2026-09-11 21)     options = dict(zip(argv[2::2], argv[3::2]))
9c8df982 scorekit/runner.py (Asha Rao 2026-09-11 22)     limit = int(options["--limit"]) if "--limit" in options else None
9c8df982 scorekit/runner.py (Asha Rao 2026-09-11 23)     rows = load(path)[:limit]
9c8df982 scorekit/runner.py (Asha Rao 2026-09-11 24)     em = sum(exact_match(r["prediction"], r["reference"]) for r in rows) / len(rows)
9c8df982 scorekit/runner.py (Asha Rao 2026-09-11 25)     f1 = sum(token_f1(r["prediction"], r["reference"]) for r in rows) / len(rows)
78232321 scorekit/runner.py (Lab User 2026-09-11 26)     rl = sum(rouge_l(r["prediction"], r["reference"]) for r in rows) / len(rows)
78232321 scorekit/runner.py (Lab User 2026-09-11 27)     print("rows=%d exact_match=%.3f token_f1=%.3f rouge_l=%.3f" % (len(rows), em, f1, rl))
9c8df982 scorekit/runner.py (Asha Rao 2026-09-11 28)     return 0 if em >= PASS_MARK else 1
633e3e60 run_eval.py        (Lab User 2026-09-07 29) 
633e3e60 run_eval.py        (Lab User 2026-09-07 30) 
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/02-who-is-that -->
```text
$ git show --stat --format='%h %an, %ad: %s' --date=short 9c8df98
9c8df98 Asha Rao, 2026-09-11: Reformat sources: four-space indent, double quotes

 scorekit/__init__.py |  2 +-
 scorekit/bleu.py     | 16 ++++++++--------
 scorekit/metrics.py  | 18 +++++++++---------
 scorekit/runner.py   | 36 ++++++++++++++++++------------------
 scorekit/text.py     |  8 ++++----
 5 files changed, 40 insertions(+), 40 deletions(-)
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/03-w -->
```text
$ git blame --date=short -w -L :main scorekit/runner.py
8dc82cb2 scorekit/runner.py (Lab User 2026-09-10 19) def main(argv):
8dc82cb2 scorekit/runner.py (Lab User 2026-09-10 20)     path = argv[1]
8dc82cb2 scorekit/runner.py (Lab User 2026-09-10 21)     options = dict(zip(argv[2::2], argv[3::2]))
9c8df982 scorekit/runner.py (Asha Rao 2026-09-11 22)     limit = int(options["--limit"]) if "--limit" in options else None
8dc82cb2 scorekit/runner.py (Lab User 2026-09-10 23)     rows = load(path)[:limit]
9c8df982 scorekit/runner.py (Asha Rao 2026-09-11 24)     em = sum(exact_match(r["prediction"], r["reference"]) for r in rows) / len(rows)
9c8df982 scorekit/runner.py (Asha Rao 2026-09-11 25)     f1 = sum(token_f1(r["prediction"], r["reference"]) for r in rows) / len(rows)
78232321 scorekit/runner.py (Lab User 2026-09-11 26)     rl = sum(rouge_l(r["prediction"], r["reference"]) for r in rows) / len(rows)
78232321 scorekit/runner.py (Lab User 2026-09-11 27)     print("rows=%d exact_match=%.3f token_f1=%.3f rouge_l=%.3f" % (len(rows), em, f1, rl))
633e3e60 run_eval.py        (Lab User 2026-09-07 28)     return 0 if em >= PASS_MARK else 1
633e3e60 run_eval.py        (Lab User 2026-09-07 29) 
633e3e60 run_eval.py        (Lab User 2026-09-07 30) 
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/04-ignore-rev -->
```text
$ git blame --date=short --ignore-rev 9c8df98 -L :main scorekit/runner.py
8dc82cb2 scorekit/runner.py (Lab User 2026-09-10 19) def main(argv):
8dc82cb2 scorekit/runner.py (Lab User 2026-09-10 20)     path = argv[1]
8dc82cb2 scorekit/runner.py (Lab User 2026-09-10 21)     options = dict(zip(argv[2::2], argv[3::2]))
be9ad1b4 scorekit/runner.py (Lab User 2026-09-10 22)     limit = int(options["--limit"]) if "--limit" in options else None
8dc82cb2 scorekit/runner.py (Lab User 2026-09-10 23)     rows = load(path)[:limit]
633e3e60 run_eval.py        (Lab User 2026-09-07 24)     em = sum(exact_match(r["prediction"], r["reference"]) for r in rows) / len(rows)
633e3e60 run_eval.py        (Lab User 2026-09-07 25)     f1 = sum(token_f1(r["prediction"], r["reference"]) for r in rows) / len(rows)
78232321 scorekit/runner.py (Lab User 2026-09-11 26)     rl = sum(rouge_l(r["prediction"], r["reference"]) for r in rows) / len(rows)
78232321 scorekit/runner.py (Lab User 2026-09-11 27)     print("rows=%d exact_match=%.3f token_f1=%.3f rouge_l=%.3f" % (len(rows), em, f1, rl))
633e3e60 run_eval.py        (Lab User 2026-09-07 28)     return 0 if em >= PASS_MARK else 1
633e3e60 run_eval.py        (Lab User 2026-09-07 29) 
633e3e60 run_eval.py        (Lab User 2026-09-07 30) 
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/05-file -->
```text
$ printf '# Formatter run: four-space indent, double quotes (Asha, 11 Sep 2026)\n' > .git-blame-ignore-revs
$ git rev-parse 9c8df98 >> .git-blame-ignore-revs
$ cat .git-blame-ignore-revs
# Formatter run: four-space indent, double quotes (Asha, 11 Sep 2026)
9c8df98229e009115b3044edb1181d11075ecbbb
$ git config set blame.ignoreRevsFile .git-blame-ignore-revs
$ git config set blame.markIgnoredLines true
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/06-blame-configured -->
```text
$ git blame --date=short -L :main scorekit/runner.py
8dc82cb2 scorekit/runner.py (Lab User 2026-09-10 19) def main(argv):
?8dc82cb scorekit/runner.py (Lab User 2026-09-10 20)     path = argv[1]
?8dc82cb scorekit/runner.py (Lab User 2026-09-10 21)     options = dict(zip(argv[2::2], argv[3::2]))
?be9ad1b scorekit/runner.py (Lab User 2026-09-10 22)     limit = int(options["--limit"]) if "--limit" in options else None
?8dc82cb scorekit/runner.py (Lab User 2026-09-10 23)     rows = load(path)[:limit]
?633e3e6 run_eval.py        (Lab User 2026-09-07 24)     em = sum(exact_match(r["prediction"], r["reference"]) for r in rows) / len(rows)
?633e3e6 run_eval.py        (Lab User 2026-09-07 25)     f1 = sum(token_f1(r["prediction"], r["reference"]) for r in rows) / len(rows)
78232321 scorekit/runner.py (Lab User 2026-09-11 26)     rl = sum(rouge_l(r["prediction"], r["reference"]) for r in rows) / len(rows)
78232321 scorekit/runner.py (Lab User 2026-09-11 27)     print("rows=%d exact_match=%.3f token_f1=%.3f rouge_l=%.3f" % (len(rows), em, f1, rl))
?633e3e6 run_eval.py        (Lab User 2026-09-07 28)     return 0 if em >= PASS_MARK else 1
633e3e60 run_eval.py        (Lab User 2026-09-07 29) 
633e3e60 run_eval.py        (Lab User 2026-09-07 30) 
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/07-commit -->
```text
$ git add .git-blame-ignore-revs
$ git commit -q -m "List the formatter commit for git blame"
$ git config list --local | grep blame
blame.ignorerevsfile=.git-blame-ignore-revs
blame.markignoredlines=true
```
<!-- /snippet -->

### What happened internally

Blame walks from the newest commit backwards and, at each commit, diffs the file against its parent. Lines the diff reports as changed stay with the commit. With `-w` that diff ignores whitespace, so lines 20, 21, 23 and 28, which the formatter only re-indented, passed through to their earlier commits. Lines 22, 24 and 25 contain quotes that the formatter changed, so they stayed. With `--ignore-rev`, blame skips the commit: it maps each of its lines to the corresponding line of the parent and continues from there. Lines 24 and 25 went all the way back to `run_eval.py`.

The ignore list is an ordinary tracked file. Git gives the name no special meaning; `blame.ignoreRevsFile`, stored in `.git/config` of this clone only, tells blame to read it. The `?` in front of an ID marks an attribution that was reached through an ignored commit.

### Checkpoint

With no extra options, `git blame` shows the real origin of every line of `main()`, and seven of them carry a `?`. The ignore list is committed; the configuration is local.

### Failure scenario

Next week you want to see who wrote a function as it was in the release. `v0.2.0` was tagged before the ignore list existed:

```bash
git switch --quiet --detach v0.2.0
git blame -s -L 6,8 scorekit/text.py
ls -a | grep blame
```

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/08-failure -->
```text
# Next week: look at how a function read in the release. v0.2.0 was tagged before the file existed.
$ git switch --quiet --detach v0.2.0
$ git blame -s -L 6,8 scorekit/text.py
fatal: could not open object name list: .git-blame-ignore-revs
[exit status: 128]
$ ls -a | grep blame
```
<!-- /snippet -->

Blame does not run at all. The configured file is not in this commit's working tree, and Git treats a named file that cannot be opened as an error. The same happens on every branch that forked before the list was added, and in a bisection across that point. A second failure waits on `main`, when a teammate adds another formatter commit by its short ID:

```bash
git switch --quiet main
git log -1 --format=%h -- docs >> .git-blame-ignore-revs
tail -n 2 .git-blame-ignore-revs
git blame -s -L 6,8 scorekit/text.py
```

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/09-failure-short-id -->
```text
$ git switch --quiet main
# A second mistake, made by a teammate who adds another commit to the list by its short ID:
$ git log -1 --format=%h -- docs >> .git-blame-ignore-revs
$ tail -n 2 .git-blame-ignore-revs
9c8df98229e009115b3044edb1181d11075ecbbb
d9d075d
$ git blame -s -L 6,8 scorekit/text.py
fatal: invalid object name: d9d075d
[exit status: 128]
```
<!-- /snippet -->

The file needs full object IDs.

### Recovery

Discard the bad line, and mark the setting as optional:

```bash
git restore .git-blame-ignore-revs
git config set blame.ignoreRevsFile ':(optional).git-blame-ignore-revs'
git blame -s -L 6,8 scorekit/text.py
git switch --quiet --detach v0.2.0
git blame -s -L 6,8 scorekit/text.py
git switch --quiet main
```

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/10-recovery -->
```text
$ git restore .git-blame-ignore-revs
$ git config set blame.ignoreRevsFile ':(optional).git-blame-ignore-revs'
$ git blame -s -L 6,8 scorekit/text.py
dd70d9e4 6) def normalize(text):
?d926d3c 7)     text = _PUNCTUATION.sub("", text)
?dd70d9e 8)     return " ".join(text.split())
$ git switch --quiet --detach v0.2.0
$ git blame -s -L 6,8 scorekit/text.py
dd70d9e4 6) def normalize(text):
9c8df982 7)     text = _PUNCTUATION.sub("", text)
9c8df982 8)     return " ".join(text.split())
$ git switch --quiet main
```
<!-- /snippet -->

🔴 `git restore <path>` discards the uncommitted change to that file, which is the intention here. With the `:(optional)` prefix, a missing file is treated as if the setting were absent: at `v0.2.0` blame runs and ignores nothing.

### Verification

```bash
git blame -s -L 6,8 scorekit/text.py
git config get blame.ignoreRevsFile
git status --short --branch
```

<!-- snippet: ch14a/lab-11-6-blame-ignore-revs/11-verification -->
```text
$ git blame -s -L 6,8 scorekit/text.py
dd70d9e4 6) def normalize(text):
?d926d3c 7)     text = _PUNCTUATION.sub("", text)
?dd70d9e 8)     return " ".join(text.split())
$ git config get blame.ignoreRevsFile
:(optional).git-blame-ignore-revs
$ git status --short --branch
## main
```
<!-- /snippet -->

### Questions

1. Which lines of `main()` did `-w` give back to earlier commits, which not, and what distinguishes the two groups?
2. What does `--ignore-rev` do with a line that the ignored commit added and that has no counterpart in the parent? Which setting makes such lines visible?
3. The ignore list is committed, the configuration key is not. What follows for a teammate who clones the repository tomorrow? What follows for GitHub's blame view, according to its documentation?
4. Explain the failure at `v0.2.0` in terms of where the file is looked up, and explain what `:(optional)` changes.
5. Someone squashes and force-pushes the branch that contains the formatter commit before it is merged. What happens to the entry in the ignore list?
6. A commit reformats a file and also fixes a bug in it. Should it go on the list? What would blame show for the bug fix afterwards?

## Lab 11.7: Line history with `git log -L`

### Objective

Read the history of one function and of one line with `git log -L`, across a rename. Then trace the wrong line by taking a line number from a file with uncommitted edits, and learn the form that does not have this problem.

### Prerequisites

Chapter 14A, sections 14A.12 and 14A.16. Lab 11.4 (the culprit you found there appears again).

### Setup

```bash
bash labs/ch14a/setup-11-7-line-history.sh
labs/shell m11-7
cd scorekit
```

### Commands

The function, as a list of commits and then with patches:

```bash
git log -s --format='%h %ad %<(10)%an %s' --date=short -L :token_f1:scorekit/metrics.py
git log --format='%h %an: %s' -L :token_f1:scorekit/metrics.py -1
git log --format='%h %an: %s' -L :token_f1:scorekit/metrics.py | grep -E '^[0-9a-f]{7} |^diff --git'
```

The file has had three names. Predict what the `diff --git` line of the oldest commit will say. Then one line, by number, and two ranges given by regular expressions:

```bash
grep -n "overlap = " scorekit/metrics.py
git log -s --format='%h %ad %an: %s' --date=short -L 11,11:scorekit/metrics.py
git log -s --format='%h %s' -L '/^def load/,/return rows/:scorekit/runner.py'
git log -s --format='%h %s' -L :exact_match:scorekit/metrics.py -L :normalize:scorekit/text.py
```

### Expected output

<!-- snippet: ch14a/lab-11-7-line-history/01-function-list -->
```text
$ git log -s --format='%h %ad %<(10)%an %s' --date=short -L :token_f1:scorekit/metrics.py
ec4fad7 2026-09-14 Asha Rao   Simplify token overlap in token_f1
9c8df98 2026-09-11 Asha Rao   Reformat sources: four-space indent, double quotes
c0d33a5 2026-09-09 Asha Rao   Add a tokens helper and use it in the metrics
bb5eb57 2026-09-07 Asha Rao   Add token-level F1 scorer
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-7-line-history/02-newest -->
```text
$ git log --format='%h %an: %s' -L :token_f1:scorekit/metrics.py -1
ec4fad7 Asha Rao: Simplify token overlap in token_f1

diff --git a/scorekit/metrics.py b/scorekit/metrics.py
index cd9f708..d830107 100644
--- a/scorekit/metrics.py
+++ b/scorekit/metrics.py
@@ -10,9 +8,9 @@
 def token_f1(prediction, reference):
     pred = tokens(prediction)
     ref = tokens(reference)
-    overlap = sum((Counter(pred) & Counter(ref)).values())
+    overlap = len(set(pred) & set(ref))
     if overlap == 0:
         return 0.0
     precision = overlap / len(pred)
     recall = overlap / len(ref)
     return 2 * precision * recall / (precision + recall)
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-7-line-history/03-file-names -->
```text
# The same log, reduced to the commit lines and the file names in each patch:
$ git log --format='%h %an: %s' -L :token_f1:scorekit/metrics.py | grep -E '^[0-9a-f]{7} |^diff --git'
ec4fad7 Asha Rao: Simplify token overlap in token_f1
diff --git a/scorekit/metrics.py b/scorekit/metrics.py
9c8df98 Asha Rao: Reformat sources: four-space indent, double quotes
diff --git a/scorekit/metrics.py b/scorekit/metrics.py
c0d33a5 Asha Rao: Add a tokens helper and use it in the metrics
diff --git a/scorekit/metrics.py b/scorekit/metrics.py
bb5eb57 Asha Rao: Add token-level F1 scorer
diff --git a/scorer.py b/scorer.py
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-7-line-history/04-one-line -->
```text
$ grep -n "overlap = " scorekit/metrics.py
11:    overlap = len(set(pred) & set(ref))
$ git log -s --format='%h %ad %an: %s' --date=short -L 11,11:scorekit/metrics.py
ec4fad7 2026-09-14 Asha Rao: Simplify token overlap in token_f1
9c8df98 2026-09-11 Asha Rao: Reformat sources: four-space indent, double quotes
c0d33a5 2026-09-09 Asha Rao: Add a tokens helper and use it in the metrics
bb5eb57 2026-09-07 Asha Rao: Add token-level F1 scorer
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-7-line-history/05-regex-range -->
```text
$ git log -s --format='%h %s' -L '/^def load/,/return rows/:scorekit/runner.py'
ca7e2b7 Fail fast on an empty reference
9c8df98 Reformat sources: four-space indent, double quotes
074d492 Send warnings to stderr
b4b066b Skip rows with an empty reference
```
<!-- /snippet -->

<!-- snippet: ch14a/lab-11-7-line-history/06-two-ranges -->
```text
$ git log -s --format='%h %s' -L :exact_match:scorekit/metrics.py -L :normalize:scorekit/text.py
9c8df98 Reformat sources: four-space indent, double quotes
d926d3c Speed up normalize with a precompiled pattern
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
bb5eb57 Add token-level F1 scorer
b250238 Add exact-match scorer
```
<!-- /snippet -->

### What happened internally

`-L :token_f1:scorekit/metrics.py` located the range in the starting revision, HEAD: from the line that Git recognizes as the function header matching `token_f1` to the line before the next function header. Walking backwards, Git diffed each commit against its parent and kept the commits whose diff intersects the range, adjusting the range as lines above it came and went. When the path disappeared from a parent, rename detection found the file under its old name, and the walk continued in `scorekit/scorer.py` and then `scorer.py`, as the `diff --git` line of the oldest commit shows.

Four of the nine commits in the file's history touched this function. The newest is `ec4fad7`, the culprit of Lab 11.4. Bisect found it from the behavior; line history finds it from the text. Two `-L` options in one command produce the union: the commits that touched either range.

### Checkpoint

You can list the four commits that shaped `token_f1` and say what each did, and you know under which name the file existed when the function was written.

### Failure scenario

You are in the middle of an edit: three comment lines at the top of `metrics.py`, not committed. Your editor shows the `overlap` line as line 14, and you ask for its history:

```bash
printf '# Scoring functions.\n# Arguments: prediction, reference.\n# Results lie between 0 and 1.\n' | cat - scorekit/metrics.py > ../metrics.tmp && mv ../metrics.tmp scorekit/metrics.py
sed -n 1,4p scorekit/metrics.py
grep -n "overlap = " scorekit/metrics.py
git log -s --format='%h %s' -L 14,14:scorekit/metrics.py
```

<!-- snippet: ch14a/lab-11-7-line-history/07-failure -->
```text
# You are in the middle of an edit: three comment lines at the top of metrics.py, not committed.
$ printf '# Scoring functions.\n# Arguments: prediction, reference.\n# Results lie between 0 and 1.\n' | cat - scorekit/metrics.py > ../metrics.tmp && mv ../metrics.tmp scorekit/metrics.py
$ sed -n 1,4p scorekit/metrics.py
# Scoring functions.
# Arguments: prediction, reference.
# Results lie between 0 and 1.
from scorekit.text import normalize, tokens
$ grep -n "overlap = " scorekit/metrics.py
14:    overlap = len(set(pred) & set(ref))
$ git log -s --format='%h %s' -L 14,14:scorekit/metrics.py
9c8df98 Reformat sources: four-space indent, double quotes
c0d33a5 Add a tokens helper and use it in the metrics
bb5eb57 Add token-level F1 scorer
```
<!-- /snippet -->

Three commits, and `ec4fad7` is not among them. The conclusion "nobody has changed this line since the formatter" would be wrong. Look at what was traced:

```bash
git show HEAD:scorekit/metrics.py | sed -n 14p
git blame -s -L 14,14 scorekit/metrics.py
git status --short
```

<!-- snippet: ch14a/lab-11-7-line-history/08-diagnose -->
```text
$ git show HEAD:scorekit/metrics.py | sed -n 14p
    precision = overlap / len(pred)
$ git blame -s -L 14,14 scorekit/metrics.py
ec4fad75 14)     overlap = len(set(pred) & set(ref))
$ git status --short
 M scorekit/metrics.py
```
<!-- /snippet -->

`git log -L` takes line numbers from the committed file in the starting revision. There, line 14 is the `precision` line. `git blame` without a revision reads the working tree file, so the same number means a different line to it. Two commands, one number, two lines.

### Recovery

Anchor the range on content. A regular expression is searched in the starting revision and finds the line wherever it is:

```bash
git log -s --format='%h %s' -L '/overlap = /,+1:scorekit/metrics.py'
```

<!-- snippet: ch14a/lab-11-7-line-history/09-recovery -->
```text
# Anchor the range on content instead of a line number. This works with or without local edits.
$ git log -s --format='%h %s' -L '/overlap = /,+1:scorekit/metrics.py'
ec4fad7 Simplify token overlap in token_f1
9c8df98 Reformat sources: four-space indent, double quotes
c0d33a5 Add a tokens helper and use it in the metrics
bb5eb57 Add token-level F1 scorer
```
<!-- /snippet -->

### Verification

With the edit set aside, the committed line number gives the same four commits:

```bash
git stash push --quiet -m "comment block for metrics.py"
git log -s --format='%h %s' -L 11,11:scorekit/metrics.py
git stash pop --quiet && git status --short
```

<!-- snippet: ch14a/lab-11-7-line-history/10-verification -->
```text
$ git stash push --quiet -m "comment block for metrics.py"
$ git log -s --format='%h %s' -L 11,11:scorekit/metrics.py
ec4fad7 Simplify token overlap in token_f1
9c8df98 Reformat sources: four-space indent, double quotes
c0d33a5 Add a tokens helper and use it in the metrics
bb5eb57 Add token-level F1 scorer
$ git stash pop --quiet && git status --short
 M scorekit/metrics.py
```
<!-- /snippet -->

Your edit is back in the working tree, uncommitted, as before.

### Questions

1. How does Git decide where the function `token_f1` ends? What would you do for a language in which its guess is poor?
2. The oldest patch is against `scorer.py`. Which mechanism took `git log -L` across the two renames, and what would have stopped it?
3. `-L 14,14` and `git blame -L 14,14` disagreed about which line is line 14. State which file each command reads.
4. Compare `git log -L` with `git blame` and with `git log -S` for the question "who removed the Counter-based overlap". Which of the three can answer it, and how?
5. Why can `git log -L` not be combined with a pathspec after `--`, and how do you restrict it to one file?
6. You need the history of a function that was deleted last month. `-L :name:file` on `main` fails with "no match". What do you pass instead?
