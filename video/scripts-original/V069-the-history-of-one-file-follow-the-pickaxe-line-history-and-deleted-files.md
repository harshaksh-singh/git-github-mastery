# V069: The history of one file: --follow, the pickaxe, line history, and deleted files

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 11, History investigation
- **Planned minutes.** 28
- **Prerequisites.** V067
- **Textbook sections.** [Chapter 14A](../../textbook/ch14a-history-investigation.md), sections 14A.10 to 14A.13
- **Demo scripts.** `labs/ch14a/log-follow.sh`, `labs/ch14a/log-pickaxe.sh`, `labs/ch14a/log-line-history.sh`, `labs/ch14a/log-deleted.sh`

## HOOK

**[ON SCREEN]** "The warning that our log parser alerts on has stopped appearing. Who removed it, and what was the reasoning?"

That is the second of the four questions that open Chapter 14A. Look at what you are given. Not a commit. Not a file name you can be sure of, because the file may have been renamed. Not a line number, because the line is gone. You have a string that used to be in the code and is not there now.

You cannot open what is missing, you cannot blame it, and you cannot grep for it in the working tree. The history still has it. This video gives you four ways to ask the history about content: follow a file through its renames, search for the commit where a string appeared or vanished, trace a function line by line, and bring back a file that was deleted.

## INTRODUCTION

In the previous two videos your queries were about commits as members of sets. Today the query is about content inside the commits. All four tools are still `git log`; they are stage-one and stage-two options from the model you already have.

Hold on to the fact that carries the chapter. History stores snapshots and parent links, nothing else. Git records no renames and no "this line came from there". Every answer you get today is computed by comparing snapshots, with heuristics that have thresholds and blind spots. For each tool, I will tell you what it computes, so that you know when its answer is a fact and when it is an inference.

The repository is `scorekit` again. One detail matters today: the file `scorekit/metrics.py` began life as `scorer.py` at the top level and was renamed twice.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- follow one file across a rename and state the limits of `--follow`;
- choose between `-S` and `-G`, and construct a commit that only one of them reports;
- trace the history of a function or a line range with `git log -L`;
- find the commit that deleted a file and restore the file from its parent;
- find a file that exists only on another branch.

## CONCEPT

**Following a file.** `git log -- <path>` matches a path, not a file. When the file had another name, the history stops at the commit that gave it the current name. `--follow` runs rename detection at each step and continues under the old name.

Its limits are all consequences of how rename detection works. First, one path only: the manual says `--follow` "works only for a single file". Second, the heuristic can miss: a rename combined with a rewrite below the similarity threshold ends the trail. Third, it is not `git log` with full history semantics. The manual says of the `log.follow` setting that it "does not work well on non-linear history". The release notes of Git 2.56 record an improvement for histories in which the tracked path is renamed differently in several lines of history; that version was not run here. If you know the old names, plain path limiting takes several paths and needs no heuristic.

**The pickaxe.** In one sentence: `-S` with a string finds commits that changed how many times that string occurs in a file; `-G` with a regular expression finds commits whose patch has an added or removed line matching the pattern.

Precisely, both are stage-two filters. The documentation says that `-S` "detects filepairs whose preimage and postimage have different number of occurrences of the specified block of text. By definition, it will not detect in-file moves." And `-G` "detects filepairs whose textual diff has an added or a deleted line that matches the given regular expression." The argument of `-S` is a literal string unless you give `--pickaxe-regex`. The argument of `-G` is always a regular expression.

When to use which: `-S` for "when was this introduced, when was it removed". `-G` for "which commits touched lines that mention this". `-S` is cheap; `-G` costs more, because every candidate is diffed.

**Line history.** `git log -L` follows a range of lines backwards and prints, for each commit that touched those lines, the part of its patch that concerns them. The range is start, end, colon, file; or colon, function name, colon, file for a whole function. How the range is found matters. A number is a line number in the starting revision, HEAD unless you name another, not in your working tree. The function name is a regular expression matched against the lines that Git considers function headers, the same lines it prints after the `@@` in hunk headers; the range runs to the next such line. For languages where the default guess is poor, a `diff` attribute selects a language-specific pattern. You meet that attribute in the attributes video.

**A deleted file.** A file that is not in the working tree cannot be opened, blamed or grepped. Its history is still there. You find the deleting commit with `--diff-filter=D`. The content lives in the parent of the deleting commit, not in the deleting commit itself.

## MENTAL MODEL

The textbook gives the pickaxe an analogy from a warehouse.

`-S` is an inventory count. It compares the number of items before and after and reports a difference. `-G` is a goods-movement ledger. It reports every delivery and every removal, including the day one crate left and an identical crate arrived.

So if the pass mark changes from 0.7 to 0.75, the name `PASS_MARK` is on the shelf once before and once after. The inventory count sees nothing. The ledger sees a line removed and a line added.

The analogy breaks at files. Both options look at one file at a time. A string that moves from one file to another is reported by `-S` as well, because one file lost an occurrence and another gained one.

**[PAUSE]** Before the demonstration, decide: your question is "who removed the call". Count, or ledger?

## DIAGRAM

**[DIAGRAM]** The picture from section 14A.11: the string `.lower()` along `main`, one row per commit. Build it row by row and, for each row, ask which option reports it before you reveal the right-hand column.

```text
  occurrences of ".lower()" per commit along main
  b250238   0 -> 1    reported by -S and -G     (added)
  8e2cac1   1 -> 1    reported by -G only       (line edited, call kept)
  dd70d9e   1 -> 1    reported by both          (metrics.py 1 -> 0, text.py 0 -> 1: counted per file)
  d926d3c   1 -> 0    reported by -S and -G     (removed)
```

Row one: the call is added. Both report it. Row two: the line is edited and the call stays. The count is unchanged, so only `-G` reports it. Row three is the one people get wrong. The total across the repository is one before and one after. But the count is per file: `metrics.py` goes from one to zero and `text.py` from zero to one. Both options report it. Row four: the call is removed for good.

**[ON SCREEN]** The comparison table from section 14A.11, shown as the summary of the diagram.

| | `-S<string>` | `-G<regex>` |
|---|---|---|
| Argument | literal (regex with `--pickaxe-regex`) | regular expression |
| Reports a commit when | the number of occurrences in a file changes | an added or removed line matches |
| A line containing the string is edited, string stays | not reported | reported |
| The string moves inside one file | not reported | reported |
| Typical question | "when was this introduced, when was it removed?" | "which commits touched lines that mention this?" |
| Cost | cheap | higher: every candidate is diffed |

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14a/log-follow`. All commands in this video up to the last one are 🟢 SAFE: they read.

```bash
git log --oneline -- scorekit/metrics.py
```

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

Six commits, and the oldest is "Rename the scorer module to metrics". The history of the path ends where the path got its name. Predict: how many more commits will `--follow` show?

```bash
git log --oneline --follow -- scorekit/metrics.py
```

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

Three more: the move into the package, and the two commits from the time the file was `scorer.py`. Now ask for the chain of names. `--diff-filter=AR` keeps additions and renames.

```bash
git log --follow --diff-filter=AR --name-status --format='%h %s' -- scorekit/metrics.py
```

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

Read it from the bottom: added as `scorer.py` in `b250238`, moved to `scorekit/scorer.py` in `d38a5aa`, renamed to `scorekit/metrics.py` in `18bb23e`. The `R100` is a similarity score of 100 percent, computed, not stored.

Now the first limit.

```bash
git log --oneline --follow -- scorekit/metrics.py scorekit/text.py
```

<!-- snippet: ch14a/log-follow/05-one-path -->
```text
$ git log --oneline --follow -- scorekit/metrics.py scorekit/text.py
fatal: --follow requires exactly one pathspec
[exit status: 128]
```
<!-- /snippet -->

Exactly one pathspec. And the alternative that needs no heuristic, when you know the names:

```bash
git log --oneline -- scorekit/metrics.py scorekit/scorer.py scorer.py
```

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

The same nine commits.

**[TERMINAL]** Replay `labs/run ch14a/log-pickaxe`. The history of the pass mark, asked both ways. Predict how many commits each prints.

```bash
git log --oneline -S'PASS_MARK'
```

<!-- snippet: ch14a/log-pickaxe/01-S -->
```text
$ git log --oneline -S'PASS_MARK'
2652768 Add a separate pass mark for the nightly set
682bc71 Add config module with the pass mark
633e3e6 Add evaluation runner and smoke set
```
<!-- /snippet -->

```bash
git log --oneline -G'PASS_MARK'
```

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

Three against five. `-G` reports two commits that `-S` does not, and the first of them, `389337a`, is the one a person asking "who changed the pass mark" wants most. Here is why `-S` missed it.

```bash
git show --format='%h %s' 389337a
git grep -c PASS_MARK 389337a~1 389337a
```

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

The value changed and the name stayed. Point at the counts from `git grep -c`: one in `config.py` before, one after. For `-S` nothing happened. The line was removed and added: for `-G` it matches twice. The second extra commit, `9c8df98`, is the formatter, which re-indented a line that mentions `PASS_MARK`. That is the noise `-G` brings.

Now the regression of this chapter. It is a removal, so `-S` is the right tool. The call `.lower()` no longer exists in the sources.

```bash
git log --format='%h %ad %<(10)%an %s' --date=short -S'.lower()'
git log --format='%h %ad %<(10)%an %s' --date=short -G'\.lower\(\)'
```

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

This is the diagram, as output. Three commits changed the count: the one that introduced the call, the one that moved the function to another file, and `d926d3c`, where it disappeared for good. `-G` adds a fourth, `8e2cac1`, which edited the line and kept the call. Add `-p` to read the evidence in the same command.

```bash
git log -p --format='%h %s' -S'.lower()' -1
```

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

"Speed up normalize with a precompiled pattern", by Ravi Menon on the tenth. The patch shows only the files that matched; `--pickaxe-all` shows the whole commit. Do not conclude anything about the person yet. You have a commit to read, and the method for reading it is the next video.

One more property: the pickaxe searches only the commits of stage one.

```bash
git log --oneline -S'write_report'
git log --oneline --all -S'write_report'
```

<!-- snippet: ch14a/log-pickaxe/08-scope -->
```text
$ git log --oneline -S'write_report'
$ git log --oneline --all -S'write_report'
a10f9a1 Write a report when --report <path> is given
a8e8550 Add per-row report writer
```
<!-- /snippet -->

Nothing from HEAD; two commits with `--all`. Use `--all` when the code may live on another branch, and `--reflog` when it may have been rebased away.

**[TERMINAL]** Replay `labs/run ch14a/log-line-history`. One function, by name.

```bash
git log --oneline -s -L :token_f1:scorekit/metrics.py
```

<!-- snippet: ch14a/log-line-history/01-function-commits -->
```text
$ git log --oneline -s -L :token_f1:scorekit/metrics.py
ec4fad7 Simplify token overlap in token_f1
9c8df98 Reformat sources: four-space indent, double quotes
c0d33a5 Add a tokens helper and use it in the metrics
bb5eb57 Add token-level F1 scorer
```
<!-- /snippet -->

`-s` suppresses the patches and leaves the list. Nine commits touched the file; four touched this function. The oldest, `bb5eb57`, predates both renames, which `-L` followed on its own.

One line works the same way.

```bash
git log --format='%h %an: %s' -L 2,2:scorekit/config.py
```

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

Line 2 of `config.py`: the pass mark, with the hunk of each commit that changed it. And the function at the centre of the regression, limited to its two most recent changes.

```bash
git log --format='%h %an: %s' -L :normalize:scorekit/text.py -2
```

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

Read from the bottom. Ravi's commit replaced the line that lowercased the text; the formatter then changed quotes and indentation. `-L` shows deleted lines, which `git blame` cannot. The errors are explicit, and worth seeing once.

```bash
git log --oneline -L 40,45:scorekit/config.py
git log --oneline -L :no_such_function:scorekit/text.py
git log --oneline -L 2,2:scorekit/config.py -- scorekit/config.py
```

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

A range beyond the end of the file, a function name that matches no header, and `-L` combined with a pathspec, which is not allowed.

**[TERMINAL]** Replay `labs/run ch14a/log-deleted`. A file is gone. Ask for the commits that deleted something.

```bash
git log --diff-filter=D --name-status --format="%h %ad %an: %s" --date=short
```

<!-- snippet: ch14a/log-deleted/01-deletions -->
```text
$ git log --diff-filter=D --name-status --format="%h %ad %an: %s" --date=short
d9d075d 2026-09-14 Ravi Menon: Remove the experimental BLEU scorer

D	scorekit/bleu.py
```
<!-- /snippet -->

One deletion: `scorekit/bleu.py`, in `d9d075d`. If you remember only part of the name, use a pathspec with a wildcard.

```bash
git log --oneline -- scorekit/bleu.py
git log --oneline -- '*bleu*'
```

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

The first command shows the history under the last name, with the deletion on top. The second also reaches `d369eac`, the commit that created the file as `bleu.py` at the top level. The two dashes are required: without them Git must decide whether the word is a revision or a path, and for a file that no longer exists it gives up with "ambiguous argument". The deleting commit says why.

```bash
git show --stat d9d075d
```

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

A reason in the message: nothing imports it, and ROUGE-L covers the use case. Now predict: does this print the file?

```bash
git show d9d075d:scorekit/bleu.py
```

<!-- snippet: ch14a/log-deleted/05-wrong-commit -->
```text
$ git show d9d075d:scorekit/bleu.py
fatal: path 'scorekit/bleu.py' does not exist in 'd9d075d'
[exit status: 128]
```
<!-- /snippet -->

No. The path does not exist in the deleting commit; that is what deleting means. The content is in its parent.

**[ON SCREEN]** 🔴 DANGEROUS: `git restore --source=<commit>~1 -- <path>`.

This is the first state-changing command of the video, and it carries the label that Chapter 11 gives it. Answer the five questions before running it. What it changes: it writes the file into the working tree. What it can destroy: it overwrites an existing file of that name without asking, and uncommitted content in the working tree is in no object. How to preview: `git show <commit>~1:<path>` prints the content, and `git status` tells you whether a file of that name exists. How to recover: an overwritten uncommitted file cannot be recovered from Git. When it is appropriate: when no such file exists, or when you have decided to replace it. Here none exists.

```bash
git restore --source=d9d075d~1 -- scorekit/bleu.py
git status --short
```

<!-- snippet: ch14a/log-deleted/06-restore -->
```text
$ git restore --source=d9d075d~1 -- scorekit/bleu.py
$ git status --short
?? scorekit/bleu.py
```
<!-- /snippet -->

The file comes back untracked. Git has not undone the deletion; you have a copy of old content to add or to discard.

A file can also be "missing" because it was never on this branch.

```bash
git log --oneline -- scorekit/report.py
git log --oneline --all -- scorekit/report.py
git branch --contains $(git log --all --format=%h -1 -- scorekit/report.py)
```

<!-- snippet: ch14a/log-deleted/07-other-branch -->
```text
$ git log --oneline -- scorekit/report.py
$ git log --oneline --all -- scorekit/report.py
a8e8550 Add per-row report writer
$ git branch --contains $(git log --all --format=%h -1 -- scorekit/report.py)
  feat/report
```
<!-- /snippet -->

`--all -- <path>` searches the history of every ref for the path. `git branch --contains`, with `-a` to include remote-tracking branches, then says where that commit lives: `feat/report`.

## COMMON MISTAKES

1. **"The file has only six commits of history."** Root cause: `git log -- <path>` matches a path, and the file had other names before; without `--follow` or the old names the history stops at the rename.
2. **Using `-S` to find who changed a value.** Root cause: the name occurs once before and once after, so the occurrence count did not change; `-G` matches the changed line.
3. **Searching for a whole statement copied from an old file.** Root cause: the string stops matching as soon as anyone edits its tail, and `-S` then reports that edit as the removal. Search for the shortest string that is specific.
4. **`git show <deleting-commit>:<path>` fails.** Root cause: the file is absent from the snapshot of the commit that deleted it; the content is in the parent.
5. **Giving `-L` a line number from the editor.** Root cause: the number is a line in the starting revision, HEAD by default, not in a working tree with uncommitted edits.

## PRODUCTION EXAMPLE

An LLM application team has an alert that counts a warning string in the service logs. The alert has been silent for a week, and the on-call engineer wants to know whether the condition stopped occurring or the warning stopped being printed.

She searches the history for the warning text with `-S`, across all branches, with a short specific fragment and not the whole message. The newest commit in the result is the one where the count dropped to zero. She reads its patch in the same command with `-p`, and the message explains that warnings were consolidated under a new wording. The alert was matching a string that no longer exists. The fix is in the alert rule, and the incident note cites the commit. It took one query, because the question was a transition and she asked a tool that searches transitions.

## PRACTICE EXERCISE

Do Lab 11.2, "Find when a string was removed, with `-S` and then with `-G`", in [`lab-manual/m11-history-forensics.md`](../../lab-manual/m11-history-forensics.md).

Before each of the two searches, predict how many commits it will report and which commit will be the newest. The lab's failure scenario has you search with a string that is too long; predict what `-S` will report as "the removal" before you run it.

The challenge is Lab 11.7, "Line history with `git log -L`", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q400: "Explain `-S` and `-G` to a colleague, with one commit that the first misses and the second reports, and one case where `-G` is noise."

Pause and answer aloud.

A strong answer defines each option by what it computes, a change in the number of occurrences per file against a match on added or removed lines, and does not describe them as "a string search and a regex search". It gives a concrete commit for the gap, and can say why the count did not change in it. It names a realistic source of noise and what it costs the investigator. It adds the scope rule, that both search only the walked commits, and it finishes with the choice: which of the two fits "introduced or removed", and which fits "touched".

## RECAP

You should now be able to say:

- `git log -- <path>` follows a path; `--follow` follows one file through renames by a heuristic that can miss.
- `-S` reports a change in the number of occurrences in a file; `-G` reports any added or removed line that matches.
- `git log -L` gives the history of a function or a line range, including lines that were deleted.
- A deleted file is found with `--diff-filter=D` and its content is in the parent of the deleting commit.
- A search from HEAD does not see other branches; `--all` and `--reflog` widen the walk.

## HOMEWORK

Read sections 14A.10 to 14A.13 of [Chapter 14A](../../textbook/ch14a-history-investigation.md). Do Lab 11.1, "Trace a line across a rename", and Lab 11.3, "Find a deleted file", in [`lab-manual/m11-history-forensics.md`](../../lab-manual/m11-history-forensics.md). Then do Exercise 11.2, Level 1, "The pickaxe, twice", and Exercise 11.5, Level 2, "A file that is gone", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).
