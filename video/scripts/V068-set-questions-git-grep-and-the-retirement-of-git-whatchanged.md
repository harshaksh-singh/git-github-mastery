# V068: Set questions, git grep, and the retirement of git whatchanged

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 11, History investigation
- **Planned minutes.** 20
- **Prerequisites.** V063, V067
- **Textbook sections.** [Chapter 14A](../../textbook/ch14a-history-investigation.md), sections 14A.14, 14A.23 and 14A.24
- **Demo scripts.** `labs/ch14a/log-sets.sh`, `labs/ch14a/grep.sh`, `labs/ch14a/whatchanged.sh`

## HOOK

**[ON SCREEN]** "Which commit, who wrote it, why, and is it in the release that went out on Friday?"

That's the last clause of the CTO's question from the previous video, and it's a different kind of question. You've found a commit, one saved snapshot of the project. Now you're asked about sets. Which releases contain it? Which open branches contain it? Through which merge did it reach `main`? And if somebody amended it away yesterday, does Git still have the original?

None of these is answered by reading one commit. Each is a question about membership in a set of commits, and Git answers it from the graph. Hold on to that last question. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you placed every `git log` option in one of four stages: walk, filter, order, print. Today you use that model for three set questions, then you add a tool for a different kind of query, `git grep`, which searches content and not the graph, the commits and their parent links. You finish with a command that old tutorials still teach and that Git 2.55 refuses to run.

You're still in `scorekit`. Keep its graph in mind: a `main` branch, a merged side branch `feat/text-utils`, and an unmerged branch `feat/report` that shares one change with `main`. A branch is a movable name for one commit, and a merge joins two lines of work.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- show what each of two branches has that the other lacks, with copies paired;
- find the merge that brought a commit into a branch with `--ancestry-path`;
- search commits that only the reflog still reaches;
- search tracked content now and in older revisions with `git grep`;
- replace `git whatchanged` in an old script.

## CONCEPT

There are three set questions in section 14A.14.

**[ANIMATION]** graph: ...older-ca7e2b7-2652768-e376e5b main; ^ca7e2b7-a8e8550-f37a7d8-a10f9a1 feat/report; HEAD=main; title:Two_tips_in_scorekit => + range:2652768,e376e5b,a8e8550,f37a7d8,a10f9a1:main...feat/report; left:2652768,e376e5b; right:a8e8550,f37a7d8,a10f9a1; cmd:git_log_--left-right_main...feat/report; say:Reachable_from_either_tip,_not_from_both; name:sides => + same:e376e5b,f37a7d8; say:Two_commits,_two_IDs,_one_patch; name:pairs => + drop:e376e5b,f37a7d8; cmd:git_log_--left-right_--cherry-pick_main...feat/report; say:With_--cherry-pick_the_pair_leaves_the_listing; name:dropped id=tips

**[ANIMATION]** step: state-1

**Which side has what.** You already counted divergence with `--left-right --count`, and you met patch IDs and `--cherry-mark` in the videos on cherry-pick, which copies one commit's change as a new commit. On screen, the two tips.

**[ANIMATION]** step: sides

The three-dot range `main...feat/report` is the commits reachable from either tip and not from both. Reachable means found by following parent links. `--left-right` marks each one with the side it belongs to. `--cherry-pick` then drops the commits that have an equivalent on the other side, equivalent meaning the same patch ID, a hash of the change itself. What remains is the work that differs.

**[ANIMATION]** graph: 8e2cac1-b4b066b-4da82b5-389337a-8657273-...7-c0c9a30 v0.2.0; ^8e2cac1-dd70d9e-c0d33a5-8657273; HEAD=none; title:How_did_dd70d9e_reach_the_release? => + range:c0d33a5,b4b066b,4da82b5,389337a,8657273,...7,c0c9a30:dd70d9e..v0.2.0; cmd:git_log_dd70d9e..v0.2.0; say:Everything_the_release_has_that_dd70d9e_lacks:_thirteen_commits; name:plain => + range:c0d33a5,8657273,...7,c0c9a30:--ancestry-path; dim:b4b066b,4da82b5,389337a; cmd:git_log_--ancestry-path_dd70d9e..v0.2.0; say:Only_the_descendants_of_dd70d9e_stay; name:path => + mark:oldest_merge:8657273; say:The_oldest_merge_on_the_path:_8657273; name:merge id=path

**[ANIMATION]** step: plain

**Through which commits did a change arrive.** A plain range `X..release` means "everything the release has that X does not have". That includes commits that have nothing to do with X, because they were made in parallel.

**[ANIMATION]** step: path

`--ancestry-path` keeps only the commits of the range that are descendants of the excluded commit. That's the chain along which the change travelled. The oldest merge on that chain is the merge that first carried the change onto another line.

**[ANIMATION]** graph: ...older-ca7e2b7-2652768-e376e5b main; ^ca7e2b7-a8e8550-f37a7d8-a10f9a1 feat/report; HEAD=main; title:What_only_the_reflogs_know => ...older-ca7e2b7-2652768-87f090b main; 2652768-e376e5b HEAD@{1}; ^ca7e2b7-a8e8550-f37a7d8-a10f9a1 feat/report; HEAD=main; reflog:e376e5b; cmd:git_commit_--amend; say:The_amend_replaces_e376e5b._No_branch_reaches_it_now; name:amended => + range:...older,ca7e2b7,2652768,87f090b,a8e8550,f37a7d8,a10f9a1:--all; cmd:git_log_--all; say:--all_walks_from_the_refs; name:refs => + range:...older,ca7e2b7,2652768,87f090b,a8e8550,f37a7d8,a10f9a1,e376e5b:--reflog; cmd:git_log_--reflog; say:--reflog_adds_every_commit_a_reflog_mentions_as_a_tip; name:reflog id=amend dx=250

**[ANIMATION]** step: amended

**What only the reflogs know.** After an amend or a rebase, both of which replace commits by new ones, the old commits are reachable from no branch. On screen, `main` moves to the amended commit, and the old one, `e376e5b`, turns dashed.

**[ANIMATION]** step: refs

`--all` doesn't find them. A reflog is a local list of the values a branch or HEAD has had.

**[ANIMATION]** step: reflog

`--reflog` adds every commit mentioned in any reflog as a starting tip. It's a stage-one option: it widens the walk, and any filter, including the pickaxe, then applies to the wider set. Don't confuse it with `-g`, the short form of `--walk-reflogs`, which lists reflog entries in order. You'll use `-g` in the recovery module.

**[ANIMATION]** end

Then a second tool. 🟢 SAFE, `git grep` searches the content that Git tracks. Compared with a recursive `grep`, it skips `.git`, ignored build output and untracked files by default, and it can search any revision, any commit you can name, without checking it out.

**[ANIMATION]** graph: ...older-*1-...more-*2-...newer-*3 main; *1 tag:v0.1.0; *2 tag:v0.2.0; HEAD=main; mark:0.7:*1; mark:0.75:*2,*3; say:git_grep_searches_states:_PASS__MARK_at_each_commit_you_name; title:States_and_transitions => + mark:changed_here?:...more; say:The_pickaxe_searches_transitions:_which_commit_changed_it?; name:transition id=states dx=230

When do you use which? The textbook draws the line exactly. `git grep` searches states: where is this text at commit X. `git log -S` and `-G`, the pickaxe, search transitions: which commit changed it. To learn when a string came and went, ask the pickaxe. Looping `git grep` over every revision reads every tree.

**[ANIMATION]** end

When not to trust these answers: `--cherry-pick` pairs commits by patch ID, so a copy that was edited during a conflict isn't paired. And in a history with several levels of merges, the oldest merge on the ancestry path may be a merge into another topic branch. Then you intersect with `--first-parent` of the target branch.

## MENTAL MODEL

Think of two overlapping circles. The left circle is everything reachable from `main`. The right circle is everything reachable from `feat/report`. The three-dot range is the two crescents, without the overlap. `--left-right` labels the crescents. `--cherry-pick` removes pairs that sit in opposite crescents and carry the same change.

Try it now, on paper. Thirty seconds: draw the two circles, and mark where a commit cherry-picked to both branches belongs. Then say your answer.

**[PAUSE]**

**[ANIMATION]** step: tips.pairs

Where the picture breaks: the circles suggest that a commit copied to both branches is in the overlap. Most people draw it there. It's not. A cherry-pick makes a new commit with a new ID. The two copies sit in different crescents, and only the patch ID connects them. That's a computed relationship, not a recorded one.

**[ANIMATION]** step: path.path

For `--ancestry-path`, change the picture. A range is a region of the graph. The ancestry path is the subset of that region that lies downstream of one commit: you keep a commit only if you can walk from it back to the commit you started with.

## DIAGRAM

**[ANIMATION]** step: tips.dropped

**[DIAGRAM]** Two pictures. First the diverged branches, with the commit IDs of the transcript.

```text
                    a8e8550---f37a7d8---a10f9a1     feat/report
                   /   >         =         >
  ...---ca7e2b7---+
                   \   <         =
                    2652768---e376e5b               main   (HEAD)

   <  only on the left side (main)        =  same patch on both sides
   >  only on the right side (feat/report)
```

Read the marks. `2652768` carries a left angle: only `main` has it. `a8e8550` and `a10f9a1` carry a right angle. The equals sign was on `f37a7d8` and `e376e5b`: two commits, two IDs, one patch. With `--cherry-pick`, those two disappear from the listing.

**[ANIMATION]** step: path.merge

**[DIAGRAM]** Second picture: the ancestry path from a commit on a side branch.

```text
          dd70d9e===c0d33a5
         /                 \\
  8e2cac1---b4b066b---4da82b5---389337a---8657273===72134f3===...===c0c9a30   (tag: v0.2.0)

   ===  on the ancestry path of dd70d9e       ---  in dd70d9e..v0.2.0, but not a descendant of dd70d9e
```

The shaded band is the path. `b4b066b`, `4da82b5` and `389337a` are in the plain range, because the release has them and `dd70d9e` doesn't. They aren't descendants of `dd70d9e`, so `--ancestry-path` drops them. The first merge on the band is `8657273`.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14a/log-sets`.

```bash
git log --oneline --left-right main...feat/report
git log --oneline --left-right --cherry-pick main...feat/report
```

Predict: five commits in the first listing. How many survive in the second? Say it out loud.

**[PAUSE]**

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

Three. The README commit exists on both sides as two commits with the same patch: `e376e5b` on the left, `f37a7d8` on the right. With `--cherry-pick` both disappear.

Now the second question. `dd70d9e` moved `normalize` into its own module, on a side branch. Is it in the release, and how did it get there?

```bash
git log --oneline dd70d9e..v0.2.0
```

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

Thirteen commits. Point at `389337a`, `4da82b5` and `b4b066b`: they were made on `main` in parallel and have nothing to do with the change. Predict which lines the next command removes.

```bash
git log --oneline --ancestry-path dd70d9e..v0.2.0
```

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

Those three are gone. Every commit that remains has `dd70d9e` in its ancestry. Now ask for the merges on that path and take the oldest.

```bash
git log --oneline --merges --ancestry-path dd70d9e..main | tail -n 1
```

<!-- snippet: ch14a/log-sets/04-which-merge -->
```text
$ git log --oneline --merges --ancestry-path dd70d9e..main | tail -n 1
8657273 Merge branch 'feat/text-utils'
```
<!-- /snippet -->

`8657273`, "Merge branch 'feat/text-utils'". In a repository where every change lands through a merge commit, this is "which pull request brought this commit in". A pull request is GitHub's proposal to merge a branch.

The third question. The script has amended the newest commit on `main`. Quick quiz: does a search with `--all` still find the commit that the amend replaced, yes or no? Say it out loud.

**[PAUSE]**

```bash
git log --oneline --all --grep='nightly run'
git log --oneline --reflog --grep='nightly run'
git log --oneline -g -2
```

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

No. `--all` finds only `f37a7d8`, the copy on `feat/report`. `--reflog` also finds `e376e5b`, the commit that the amend replaced. The third command shows why: the reflog of HEAD still records it at `HEAD@{1}`, below the amend at `87f090b`. No branch reaches it. The reflog does. So yes, Git still has the original.

**[TERMINAL]** Replay `labs/run ch14a/grep`. A different kind of query: content.

```bash
git grep -n PASS_MARK
git grep -c tokens
git grep -l normalize -- scorekit
```

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

`-n` adds line numbers, `-c` counts matches per file, `-l` lists file names only. No `.git`, no build output, no untracked files.

```bash
git grep -n -p "overlap == 0"
git grep -W "set(pred)"
```

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

`-p` shows the function a match belongs to: the line with the equals signs is the function header. `-W` prints that whole function. For a reviewer, this is the fastest way to see a match in context.

Now search a revision without checking it out. Predict the exit status of the second command.

```bash
git grep -n "lower()" v0.1.0
git grep -n "lower()" main
git grep -n -i bleu v0.2.0 -- docs
```

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

A revision before the pathspec, the path pattern, searches that tree, and each hit is prefixed with the revision. The exit status is 1 when nothing matches, which makes `git grep -q` usable as a test.

```bash
git grep -n 'PASS_MARK = ' v0.1.0 v0.2.0 main -- scorekit/config.py
```

<!-- snippet: ch14a/grep/06-many-revisions -->
```text
$ git grep -n 'PASS_MARK = ' v0.1.0 v0.2.0 main -- scorekit/config.py
v0.1.0:scorekit/config.py:2:PASS_MARK = 0.7
v0.2.0:scorekit/config.py:2:PASS_MARK = 0.75
main:scorekit/config.py:2:PASS_MARK = 0.75
main:scorekit/config.py:3:NIGHTLY_PASS_MARK = 0.6
```
<!-- /snippet -->

Several revisions give a quick history of one line: 0.7 at `v0.1.0`, 0.75 at `v0.2.0`. This tells you the states. It doesn't tell you which commit made the change. That's the pickaxe, in the next video.

**[ON SCREEN]** The table "What is searched" from section 14A.23: the working tree by default, the index with `--cached`, a commit or tree with a revision, tracked and untracked files with `--untracked`, and a directory that is not a repository with `--no-index`.

**[TERMINAL]** Replay `labs/run ch14a/whatchanged`. You inherit a script that calls `git whatchanged`.

```bash
git whatchanged -2
```

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

Exit status 128. Read the first line and the last: the command is nominated for removal, and it refuses to run without `--i-still-use-this`. The hint names the replacement.

```bash
git log --raw --no-merges --oneline -2
git whatchanged --i-still-use-this --oneline -2
```

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

The same output. Each raw line is old mode, new mode, old blob ID, new blob ID, status letter, path. A blob is one file's bytes. In practice `git log --name-status` or `git log --stat` reads better.

The textbook's sources say the command is "merely `git log` with different defaults", that its manual page carries a deprecation warning since Git 2.51, and that it's scheduled for removal in Git 3.0. Write `git log --raw --no-merges`, and don't add `--i-still-use-this` to scripts.

Going the other way, Git 2.52 added `git last-modified`, which reports the commit that last touched each path.

```bash
git last-modified -r -- scorekit
```

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

Its manual page marks it experimental, so its interface may change. Don't build a pipeline on it yet.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Reading `X..release` as "how X got into the release".** Root cause: a two-dot range is a set difference, so it includes parallel commits that are not descendants of X; `--ancestry-path` is the restriction you wanted.
2. **Concluding that an amended or rebased commit is gone because `--all` does not list it.** Root cause: `--all` starts from refs, and the old commit is reachable only from a reflog; `--reflog` widens the walk.
3. **Expecting `--cherry-pick` to pair every backport.** Root cause: the pairing is by patch ID, which is computed from the change; a copy whose change differs is a different patch.
4. **Looping `git grep` over every revision to find when a string changed.** Root cause: `git grep` searches states and reads every tree; the pickaxe searches transitions.
5. **Keeping `git whatchanged` alive with `--i-still-use-this`.** Root cause: the option silences a removal notice; it does not change the fact that the command is scheduled for removal.

## PRODUCTION EXAMPLE

Now, out of the lab. A retrieval team ships a model-serving library with release tags, fixed names for commits. A bug report names a commit that changed tokenization. The on-call engineer has to answer one question for the customer note: which releases contain that commit, and through which merge did it land?

**[ANIMATION]** step: path.merge

**[ANIMATION]** say: In_scorekit,_the_same_query_named_8657273

She runs the ancestry-path query from the commit to `main`, restricted to merges, and takes the oldest. That names the merge, and therefore the pull request. Then she checks an older maintenance branch with a left-right listing and `--cherry-pick`, because fixes are backported there by cherry-pick and the IDs differ. The note says which query produced each statement. Nobody had to remember what was merged when.

**[ANIMATION]** end

## PRACTICE EXERCISE

Your turn. Do Exercise 11.4, Level 2, command prediction, "Ranges on a diverged branch", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

It's a prediction exercise, so the rule is strict: for each command write down the number of lines and the markers you expect before you run it. Draw the two crescents first. Then run the commands in `labs/shell` and explain every difference between your prediction and the output.

The challenge is Exercise 11.8, Level 3, "Git lost my commit", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q401: "You found the commit that introduced a bug. Which commands tell you which releases and which open branches contain it?"

Pause and answer out loud.

**[PAUSE]**

A strong answer treats this as a reachability question and says so in the first sentence. It separates tags from branches, and local branches from remote-tracking ones. It says what the answer misses: a copy of the commit made by cherry-pick has another ID, so containment by ID isn't the whole story, and it names the patch-ID tool that covers the gap. It can also say how the commit travelled, using the ancestry path and the oldest merge on it, and what to do when the merges are nested.

## RECAP

Let's land this. You should now be able to say:

- A three-dot range with `--left-right` shows what each side has alone; `--cherry-pick` removes pairs with the same patch.
- `--ancestry-path` reduces a range to the descendants of the excluded commit, and the oldest merge on that path is where the change first landed.
- `--reflog` widens the walk to commits that no ref reaches; `-g` lists reflog entries.
- `git grep` searches states, at any revision; the pickaxe searches transitions.
- `git whatchanged` refuses to run on Git 2.55; its replacement is `git log --raw --no-merges`.

## HOMEWORK

Read sections 14A.14, 14A.23 and 14A.24 of [Chapter 14A](../../textbook/ch14a-history-investigation.md).

**[ANIMATION]** step: amend.reflog

Today you asked Git about sets of commits, and you found a commit that no branch reaches. Draw the two crescents on paper before the next video. Next time: the history of one file. Until then, look at the state first and type second. See you in the next one.
