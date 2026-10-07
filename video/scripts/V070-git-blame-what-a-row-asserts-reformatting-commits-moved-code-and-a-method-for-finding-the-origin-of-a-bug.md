# V070: git blame: what a row asserts, reformatting commits, moved code, and a method for finding the origin of a bug

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 11, History investigation
- **Planned minutes.** 26
- **Prerequisites.** V069
- **Textbook sections.** [Chapter 14A](../../textbook/ch14a-history-investigation.md), sections 14A.16 to 14A.19
- **Demo scripts.** `labs/ch14a/blame-basics.sh`, `labs/ch14a/blame-reformat.sh`, `labs/ch14a/blame-moves.sh`, `labs/ch14a/find-origin.sh`

## HOOK

**[ON SCREEN]** "`git blame` says one person wrote most of the file last Friday. That cannot be right. Where is the real history?"

It isn't right, and Git didn't lie. `git blame` labels every line of a file with the commit that last changed it. A commit is one saved snapshot of the project, with its author. On Friday someone ran a formatter, a tool that tidies the layout of code. Every line whose indentation or quotes changed now carries that commit and that name. The person who wrote the logic, the person who introduced the bug, and the reason for either are one step further back, and plain blame doesn't take that step.

There's a second way blame misleads, and it's worse. The line that caused the regression in `scorekit` was deleted. Blame annotates lines that exist. It has no row for a line that is gone. Keep that Friday formatter in mind. By the end you'll look straight through it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the previous video you searched history for content: a string, a function, a deleted file. Today you look at the tool most engineers reach for first, and you learn to state exactly what it claims. Then you put all the tools of this module in order: a method that takes you from a symptom to the commit, to a confirmation, and to the list of releases that contain it.

One note on the method. The curriculum summary for this video calls it a seven-step method. The textbook's table in section 14A.19 has nine steps, and the textbook is the authority, so you'll see nine.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- state precisely what one row of `git blame` asserts;
- look through a reformatting commit with `-w`, `--ignore-rev` and an ignore-revs file;
- follow moved and copied code with `-M` and `-C`;
- explain what blame shows after a squash merge;
- apply the method from symptom to blast radius.

## CONCEPT

In one sentence: 🟢 SAFE, `git blame` annotates every line of a file, as it is in one revision, with the commit that last changed that line. A revision is any commit you can name.

**[ANIMATION]** blame: file=scorekit/text.py lines=d926d3c5:import_re|dd70d9e4:|9c8df982:​__PUNCTUATION_=_re.compile(r"[^\w\s]")|dd70d9e4:|dd70d9e4:|dd70d9e4:def_normalize(text):|9c8df982:____text_=_​__PUNCTUATION.sub("",_text)|9c8df982:____return_"_".join(text.split())|c0d33a57: after=d926d3c5,dd70d9e4,d926d3c5,dd70d9e4,dd70d9e4,dd70d9e4,d926d3c5,dd70d9e4,c0d33a57 say_after=With_the_formatter_commit_9c8df98_ignored id=text

**[ANIMATION]** step: blame

Precisely. Blame starts from the file in the given revision. That's HEAD by default, the commit you're on, or the working tree file, the one on your disk, if it has uncommitted changes, which are attributed to "Not Committed Yet". It compares the file with the same file in the parent commit, the commit this one was built on. Lines that the diff shows as unchanged are passed to the parent. Lines that it shows as added stay with the commit. The parent is then treated the same way, until every line has an owner. The manual adds two sentences you should be able to quote: "The origin of lines is automatically followed across whole-file renames", and "the report does not tell you anything about lines which have been deleted or replaced".

Inside `.git`, nothing is written. The work is one diff per commit that touched the file, so blame on an old, busy file in a large repository takes noticeable time.

So what does a row assert? Try it now, on paper, for thirty seconds: write one sentence that starts "this commit is". Then say your answer.

**[PAUSE]**

**[ANIMATION]** say: A_row:_the_last_commit_whose_diff_against_its_parent_shows_this_line_as_added

Here's the exact version. This commit is the last one whose diff against its parent shows this line as added. Nothing about who designed the logic. Nothing about why. Nothing about what stood here before.

**[ON SCREEN]** The table "What blame does not tell you" from section 14A.16.

You want to know who wrote this logic. Blame gives who last changed the line, possibly a formatter or a rename of a variable. You want to know who removed the line that used to be here. Blame gives nothing, and you use `git log -S` or `git log -L`. You want to know why. Blame gives an ID, and `git show` gives the message and the whole commit. You want to know whom to ask about code that arrived in a squash merge. Blame gives the person who ran the merge, and you read the trailers, the key and value lines that end a commit message, or the pull request, GitHub's proposal to merge the branch. You want to know whether the line is the bug. Blame gives nothing, because the defect may be a line that is missing or one in another file, and that's what `git bisect` is for: a binary search over commits, in the next video.

Three refinements deal with the three ways the last change can be uninteresting.

**[ANIMATION]** step: text.after

A reformatting commit. `-w` ignores whitespace when blame compares a commit with its parent. `--ignore-rev` goes further: it removes one commit from consideration, "as if the change never happened", and blames its lines "on the previous commit that changed that line or nearby lines". A file of full object IDs, read with `--ignore-revs-file` or named by `blame.ignoreRevsFile`, makes that permanent for a repository.

**[ANIMATION]** walk: columns=option,where_blame_looks_for_the_origin_of_a_line rows=-M:other_places_of_the_same_file|-C:files_modified_in_the_same_commit|-C_-C:every_file_of_the_parent,_for_commits_that_create_the_blamed_file|-C_-C_-C:every_file_of_the_parent,_in_every_commit title=Moved_code:_each_rung_costs_more id=moves

Moved code. `-M` looks for the origin of a line in other places of the same file. `-C` looks in files modified in the same commit. A second `-C` also looks in every file of the parent, for commits that create the blamed file. A third looks in every file of the parent, in every commit. Each rung costs more. And there are minimums: 20 alphanumeric characters for `-M`, 40 for `-C`.

**[ANIMATION]** graph: ...older-9c8df98-7823232-...newer; 9c8df98-1cbe38a-80ee55f-2f2883f feat/rouge-l; HEAD=none; note:7823232:squash:_one_commit,_one_author; title:A_squash_merge; say:Nothing_links_the_two_in_the_graph id=squash dx=250

A squash merge. It records the content of a branch as one new commit. Blame on the target branch then knows one commit and one author.

**[ANIMATION]** step: text.after

**[ANIMATION]** say: The_attribution_of_an_ignored_line_is_a_guess

When not to rely on the ignore list: its attribution is a guess. Git maps an ignored line to the line of the parent that looks like its origin, and for a line that the ignored commit really introduced there is no origin. And list only commits that change no behavior: formatter runs, mass renames of a symbol, license header updates. Listing a commit that also changed logic hides that logic from blame.

## MENTAL MODEL

**[ANIMATION]** say: Last_edited_by:_reliable_about_the_last_edit,_silent_about_everything_else

Now a picture to keep. The textbook's analogy: a "last edited by" column beside a document. The column is reliable about the last edit and silent about everything else: the edit before it, the paragraph that used to stand here, and whether the last editor wrote the sentence or only fixed its spacing.

**[ANIMATION]** say: Which_old_line_is_this_line?_A_diff_decides

The analogy breaks on the word "line". A document editor knows which sentence you touched. Git doesn't. It decides which old line corresponds to which new line by running a diff, so the attribution depends on how the diff aligned them.

**[ANIMATION]** say: A_pointer_into_history,_never_a_verdict_about_a_person

The working rule that follows: treat a blame row as a pointer into history, never as a verdict about a person. The next command after `git blame` is `git show` with that ID.

## DIAGRAM

**[ANIMATION]** graph: 8e2cac1-dd70d9e-...6-d926d3c-9c8df98; HEAD=none; note:9c8df98:formatter:_quotes_changed; note:d926d3c:.lower()_gone; note:dd70d9e:function_moved_into_text.py; note:8e2cac1:older_line,_metrics.py; title:Who_wrote_line_7_of_scorekit/text.py? => + mark:plain_blame:9c8df98; cmd:git_blame_-L_7,7_scorekit/text.py; say:Plain_blame_stops_at_the_formatter; name:plain => + mark:--ignore-rev:d926d3c; cmd:git_blame_--ignore-rev_9c8df98_-L_7,7_scorekit/text.py; say:With_the_formatter_ignored:_Ravi's_commit,_where_the_line_was_replaced; name:ignore => + mark:d926d3c~1:dd70d9e; cmd:git_blame_d926d3c~1_-L_7,7_--_scorekit/text.py; say:Blame_the_parent:_an_older_line_7,_and_Asha's_move; name:parent => + mark:-C:8e2cac1; cmd:git_blame_-C_dd70d9e; say:With_-C,_blame_crosses_into_metrics.py,_where_Ravi_wrote_the_older_line; name:copy dx=300 id=line7

**[ANIMATION]** step: state-1

**[DIAGRAM]** The picture from section 14A.16. One line of `scorekit/text.py`, and where each way of asking stops. Build it from the top, one row at a time.

```text
  line 7 on main:   text = _PUNCTUATION.sub("", text)

  9c8df98  formatter: quotes changed             <- plain blame stops here
  d926d3c  Ravi: line replaced, .lower() gone    <- blame --ignore-rev 9c8df98 stops here
  dd70d9e  Asha: function moved into text.py     <- blame d926d3c~1 stops here (the older line 7)
  8e2cac1  Ravi: older line written, metrics.py  <- blame -C dd70d9e reaches this
```

One line, line 7 of `scorekit/text.py`, and four commits of its history.

**[ANIMATION]** step: plain

Plain blame stops at the newest commit, the formatter.

**[ANIMATION]** step: ignore

With `--ignore-rev` for the formatter, it stops at `d926d3c`, where the line was replaced and the lowercasing disappeared.

**[ANIMATION]** step: parent

If you blame the parent of that commit, you're asking about an older line 7, and you stop at the commit that moved the function into the file.

**[ANIMATION]** step: copy

With `-C` at that commit, blame crosses into the file the function came from.

Four marks, four different answers to "who wrote line 7", and every one of them is correct for the question that was asked.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14a/blame-basics`.

```bash
git blame scorekit/text.py
```

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

Read one row out loud: the abbreviated commit ID, the author and author date of that commit, the line number in this revision, and the line. `-s` drops author and date, and `-L` limits the output with the same range syntax as `git log -L`.

```bash
git blame -s -L 6,8 scorekit/text.py
git blame -s -L :normalize scorekit/text.py
```

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

A revision before the path asks about an older state of the file.

```bash
git blame -s v0.1.0 -- scorekit/metrics.py
```

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

Point at the extra column, `scorer.py`. It appears whenever a line comes from a commit in which the file had another name. A whole-file rename doesn't disturb blame.

For scripts there is a porcelain format.

```bash
git blame --line-porcelain -L 7,7 scorekit/text.py
```

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

Full IDs and one header per attribution. Find the field named `previous`: the commit before the blamed one. That's the key to stepping further back.

Now the limit that matters for our regression. Predict: line 7 used to lowercase the text. What does blame say about that line today? Say it out loud. I'll wait.

**[PAUSE]**

```bash
git blame -s d926d3c~1 -L 7,7 -- scorekit/text.py
git blame -s -L 7,7 scorekit/text.py
```

<!-- snippet: ch14a/blame-basics/06-not-shown -->
```text
# The line that lowercased the text is gone. Blame annotates lines that exist; it has no row for it.
$ git blame -s d926d3c~1 -L 7,7 -- scorekit/text.py
dd70d9e4 7)   text = text.lower().translate(_PUNCTUATION)
$ git blame -s -L 7,7 scorekit/text.py
9c8df982 7)     text = _PUNCTUATION.sub("", text)
```
<!-- /snippet -->

Before `d926d3c`, line 7 contained `.lower()`. Today a different line 7 exists, and blame reports on that one. There's no row for the line that is gone. That's the second trap from the opening.

**[TERMINAL]** Replay `labs/run ch14a/blame-reformat`. The loader function of the runner. Asha's commit of 11 September is the formatter run.

```bash
git blame --date=short -L '/^def load/,+7' scorekit/runner.py
```

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

Five of seven lines carry `9c8df982`. Quick quiz, three options. With `-w`, do all five fall through to an older commit, four of them, or none? Say it out loud.

**[PAUSE]**

```bash
git blame --date=short -w -L '/^def load/,+7' scorekit/runner.py
```

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

Four. The lines that were only re-indented fall through to `b4b066b4`. Line 13 stays with the formatter, because there it also changed the quotes. Whitespace wasn't the only change.

```bash
git blame --date=short --ignore-rev 9c8df98 -L '/^def load/,+7' scorekit/runner.py
```

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

Now line 13 goes back too. That's the Friday formatter from the opening, looked through. Typing the option every time doesn't scale, so the IDs go into a file: one full object ID per line, with comments after a hash sign.

```bash
cat .git-blame-ignore-revs
git blame -s --ignore-revs-file .git-blame-ignore-revs scorekit/text.py
```

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

**[ON SCREEN]** 🟡 CAUTION: `git config set blame.ignoreRevsFile`. It writes one key into `.git/config`; working tree, index, HEAD and all refs are unchanged. The `git config set` form needs Git 2.46 or later.

```bash
git config set blame.ignoreRevsFile .git-blame-ignore-revs
git config set blame.markIgnoredLines true
git blame -s scorekit/text.py
```

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

Point at the question mark on line 3. `blame.markIgnoredLines` flags every line whose attribution passed through an ignored commit. Keep that mark: the attribution of an ignored line is a guess.

**[ON SCREEN]** Lower third: **GitHub**. The file name is a convention, not a Git default. Git reads no ignore file unless the option or the configuration key names one. According to GitHub's documentation, its blame view does look for a file with exactly the name `.git-blame-ignore-revs` in the root directory of the repository and hides the listed revisions. Using that name serves both. The configuration key is local, so every clone has to set it.

Two failures are common enough to show. Almost everyone meets the first one.

```bash
cat ../short-ids.txt
git blame -s --ignore-revs-file ../short-ids.txt -L 6,8 scorekit/text.py
```

<!-- snippet: ch14a/blame-reformat/06-short-id -->
```text
$ cat ../short-ids.txt
9c8df98
$ git blame -s --ignore-revs-file ../short-ids.txt -L 6,8 scorekit/text.py
fatal: invalid object name: 9c8df98
[exit status: 128]
```
<!-- /snippet -->

The file must contain full IDs. And once the key is set, the file must exist in every commit you visit.

```bash
git switch --detach --quiet v0.2.0
git blame -s -L 6,8 scorekit/text.py
git blame -s --ignore-revs-file "" -L 6,8 scorekit/text.py
```

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

The tag, a fixed name for an older commit, predates the file, and blame fails. An empty `--ignore-revs-file` clears the list of revisions. It doesn't stop Git from opening the configured file. The manual documents a prefix for path-valued settings, `:(optional)`: the variable is treated as if it doesn't exist when the named path doesn't exist.

```bash
git config set blame.ignoreRevsFile ':(optional).git-blame-ignore-revs'
git blame -s -L 6,8 scorekit/text.py
git switch --quiet main
git blame -s -L 6,8 scorekit/text.py
```

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

At `v0.2.0` blame runs and nothing is ignored. Back on `main` the list applies again.

**[TERMINAL]** Replay `labs/run ch14a/blame-moves`. Commit `dd70d9e` cut `normalize()` out of `metrics.py` and pasted it into a new file. To plain blame, a new file is new lines.

```bash
git blame -s dd70d9e -- scorekit/text.py
```

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

Every line belongs to the commit that moved it. Now today's file, with `-C`, and a prediction: `-C` wants 40 alphanumeric characters. Are there 40 left unchanged?

```bash
git blame -s -C --ignore-rev 9c8df98 -L 6,8 scorekit/text.py
git blame -s -C5 --ignore-rev 9c8df98 -L 6,8 scorekit/text.py
```

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

No. After later edits only short fragments of the moved block survive, and the default threshold rejects them. With a lower one, given as `-C5`, line 6 goes back to `b2502383` in `scorer.py`. That's why moved code is sometimes not recognized.

The squash merge.

```bash
git blame -L 15,18 scorekit/rouge.py
git blame -L 15,18 feat/rouge-l -- scorekit/rouge.py
```

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

On `main`, the person who squashed "wrote" the function. The branch, while it still exists, has the real history. Nothing links the two in the graph.

```bash
git log -1 --format='%h %an: %s%n%(trailers:key=Co-authored-by)' 7823232
git branch --no-merged main
```

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

After the branch is deleted, the `Co-authored-by` trailers and the pull request are the only record of who wrote which part. That's a real cost of squash-merge workflows, to be weighed against the linear history they give. The opposite question, "which merge put this line on `main`", is answered by `--first-parent`: blame then stops at merges.

```bash
git blame -s --first-parent -L 10,12 scorekit/text.py
```

<!-- snippet: ch14a/blame-moves/08-first-parent -->
```text
$ git blame -s --first-parent -L 10,12 scorekit/text.py
86572733 10) def normalize(text):
9c8df982 11)     text = _PUNCTUATION.sub("", text)
9c8df982 12)     return " ".join(text.split())
```
<!-- /snippet -->

**[TERMINAL]** Replay `labs/run ch14a/find-origin`. Now the method.

**[ON SCREEN]** The nine-step table of section 14A.19: pin the symptom, fix two endpoints, locate, read the lines' history, look for what is gone, search by behavior, confirm, measure the spread, choose the fix.

Steps 3 to 5 are fast and need an idea of where the fault is. Step 6, bisect, is slower and needs no idea at all, only the test. Step 7 isn't optional: every tool before it produces a suspect, not a proof.

The symptom, and the code that produces the behavior.

```bash
python3 -B -m scorekit.runner data/smoke.jsonl
git grep -n "exact_match" -- docs
git grep -n -W "def exact_match"
```

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

The documentation says "equal after normalization". That points at `normalize()`.

```bash
git grep -n "def normalize"
git blame --date=short -L :normalize scorekit/text.py
```

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

Both body lines are owned by the formatter commit. Look through it.

```bash
git blame --date=short --ignore-rev 9c8df98 -L :normalize scorekit/text.py
```

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

One line was last changed for a real reason, by `d926d3c`, the day before the formatter ran. Read that commit.

```bash
git show d926d3c
```

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

The message promises speed and no change of behavior. The patch replaces the lowercasing call with a pattern substitution, and `.lower()` is gone, while the documentation still says that normalization lowercases the text. The pickaxe confirms that this is where the call left the code base.

```bash
git log --format='%h %ad %<(10)%an %s' --date=short -S'.lower()'
```

<!-- snippet: ch14a/find-origin/05-confirm -->
```text
$ git log --format='%h %ad %<(10)%an %s' --date=short -S'.lower()'
d926d3c 2026-09-10 Ravi Menon Speed up normalize with a precompiled pattern
dd70d9e 2026-09-09 Asha Rao   Move normalize into scorekit/text.py
b250238 2026-09-07 Lab User   Add exact-match scorer
```
<!-- /snippet -->

Step 7. Test on both sides of the suspect, in two temporary worktrees, extra working directories of the same repository, so that the main working tree isn't touched. `git worktree add` is 🟢 SAFE, and worktrees have their own videos later in this part. Predict the two results.

```bash
git worktree add --detach --quiet ../before d926d3c~1
git worktree add --detach --quiet ../after d926d3c
(cd ../before && python3 -B -c 'from scorekit.metrics import exact_match; print(exact_match("Paris", "paris"))')
(cd ../after && python3 -B -c 'from scorekit.metrics import exact_match; print(exact_match("Paris", "paris"))')
git worktree remove ../before && git worktree remove ../after
```

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

True before, False after. That's the proof. Step 8, the spread.

```bash
git tag --contains d926d3c
git branch --all --contains d926d3c
git describe --contains d926d3c
git log --oneline d926d3c..main -- scorekit/text.py
```

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

**[ANIMATION]** step: line7.copy

**[ANIMATION]** say: d926d3c_dropped_the_lowercasing._Release_v0.2.0_contains_it

The answer for the CTO: the harness regressed, not the model. Commit `d926d3c`, on Thursday 10 September, dropped lowercasing from normalization while optimizing it. Release `v0.2.0` contains the commit, and so does every branch cut since. The fix is one line, plus a test with a capitalized answer. Notice how that sentence is phrased: it names a commit and a mechanism, not a culprit.

**[ANIMATION]** end

## COMMON MISTAKES

Five mistakes to watch for.

1. **Reading a blame row as authorship of the logic.** Root cause: a row names the last commit whose diff shows the line as added, which may be a formatter, a rename of a variable or a squash.
2. **Looking in blame for who removed something.** Root cause: blame annotates lines that exist in the blamed revision; a deleted line has no row.
3. **Short IDs in the ignore-revs file.** Root cause: the file is a list of full object IDs, and Git rejects an abbreviation as an invalid object name.
4. **Blame fails on an old commit after `blame.ignoreRevsFile` is set.** Root cause: the configured file must exist in the checked-out state; the `:(optional)` prefix makes the setting tolerate its absence.
5. **Listing a commit before it reached the shared branch.** Root cause: rebasing or squashing the listed commit changes its ID and silently empties the entry.

## PRODUCTION EXAMPLE

Now, out of the lab. A backend team adopts a formatter across a Java and Python monorepo. The formatter commit touches most files. From that day, the blame view names one engineer on almost every line, and code review comments begin with "you wrote this".

**[ANIMATION]** step: text.after

**[ANIMATION]** say: In_scorekit:_the_same_file_with_the_formatter_commit_on_the_ignore_list

The team does three things, in this order. They wait until the formatter commit is on `main`, so its ID is final. They commit a file named `.git-blame-ignore-revs` in the root, with the full ID and a comment that says what the commit was. And they add the configuration key to the onboarding script with the `:(optional)` prefix, because engineers bisect across commits that predate the file. They also turn on the mark for ignored lines, so that nobody mistakes a guessed attribution for a fact.

**[ANIMATION]** end

## PRACTICE EXERCISE

Your turn. Do Lab 11.6, "Blame through a reformatting commit with an ignore-revs file", in [`lab-manual/m11-history-forensics.md`](../../lab-manual/m11-history-forensics.md).

Before you run blame with the ignore list, predict for each line of the function which commit it will be attributed to, and which lines will carry a question mark. Then make the lab's failure happen on purpose and predict the error text before you read it.

The challenge is Exercise 11.3, Level 1, "Blame, and one step further back", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q395: "What exactly does a row of `git blame` assert? Give three situations in which the named author did not write the logic on that line."

Pause and answer out loud.

**[PAUSE]**

A strong answer opens with a definition that is narrow and exact: one revision, one line as it stands, the last commit that changed it, decided by a diff. It then gives three situations that are different in kind, not three formatter stories, and for each one names the tool or option that recovers the real origin. It mentions what blame can't show at all. And it ends with the practice that follows from the definition: what you run next, and how you speak about the result.

## RECAP

Let's land this. You should now be able to say:

- A blame row names the last commit that changed a line as it stands in one revision; it is a pointer to a commit to read.
- `-w` and `--ignore-rev` look through reformatting; an ignore-revs file holds full IDs, and its attributions are guesses worth marking.
- `-M` and `-C` follow moved and copied code at increasing cost and with minimum sizes.
- After a squash merge, blame on the target branch knows one commit and one author.
- Every investigative tool produces a suspect; the test at the suspect and at its parent is the proof.

## HOMEWORK

Read sections 14A.16 to 14A.19 of [Chapter 14A](../../textbook/ch14a-history-investigation.md).

**[ANIMATION]** step: line7.copy

Today you learned to read a blame row as a pointer and not a verdict, and you walked from a symptom to a proven commit. Try the ignore-revs lab before the next video. Next time: `git bisect`, binary search over commits. Until then, look at the state first and type second. See you in the next one.
