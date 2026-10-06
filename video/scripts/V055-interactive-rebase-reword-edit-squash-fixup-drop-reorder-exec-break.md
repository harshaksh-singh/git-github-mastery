# V055: Interactive rebase: reword, edit, squash, fixup, drop, reorder, exec, break

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 9, Rebase
- **Planned minutes:** 28
- **Prerequisites:** V054
- **Textbook sections:** [Chapter 9](../../textbook/ch09-rebase.md), section 9.6
- **Demo scripts:** `labs/ch09/interactive-basics.sh`, `labs/ch09/squash-message.sh`, `labs/ch09/interactive-edit.sh`, `labs/ch09/interactive-exec.sh`, `labs/ch09/interactive-exec-lines.sh`, `labs/ch09/interactive-break.sh`

## HOOK

**[ON SCREEN]** A commit list: `fix test`, `Add token-level F1 metirc`, `debug print`, `add test`, `wip`, `Add exact_match metric`.

This is your branch after a day of real work. Six commits. One is called "wip". One is a debug print. One has a typo in its subject. A test and the fix for that test are three commits apart. Nothing to be ashamed of: every working branch looks like this.

Next month a regression shows up in the F1 metric. Someone runs `git bisect`, the binary search over commits, across this history. Bisect lands on "wip", which doesn't build. It lands on "debug print", which changes nothing that matters. And when they finally find the commit, they want to revert it, and it contains two unrelated decisions.

A tidy history isn't about beauty. It's about whether those two tools work. Keep this list of six in mind. In the demo it becomes three commits, one decision each.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A rebase copies commits onto a base and then moves the branch. In the last three videos, it ran a list of instructions that you never saw. Interactive rebase shows you the list before executing it, and lets you edit it.

**[ANIMATION]** todo: todo=pick:d33e9b2:Add_exact__match_metric|pick:a1056e1:wip|pick:cdb5f2f:add_test|pick:25dc48e:debug_print|pick:031999d:Add_token-level_F1_metirc|pick:8313de0:fix_test title=The_list_is_a_program:_top_to_bottom,_oldest_first id=list6

That's the only new idea today, and everything else follows from it. The list is a program. One instruction per line, executed from top to bottom. You may edit, reorder, extend or shorten it.

You'll use eight instructions. Five rearrange history: `reword`, `fixup`, `squash`, `drop`, and moving a line. One stops inside history so that you can change or split a commit: `edit`. One runs a command after a commit and stops if it fails: `exec`. And one stops and does nothing: `break`.

**[ANIMATION]** end

One note on the transcripts, said once for the whole module. An interactive rebase opens an editor. In these replays a small script plays the person at the keyboard. It prints the list as Git opened it, applies the edit, and prints the list as saved. Those two blocks stand for what you would see and do in your own editor.

## LEARNING OBJECTIVES

**[ON SCREEN]** The five objectives.

After this video you can:

- Read and edit a todo list and predict the resulting history.
- Reword, squash, fix up, drop and reorder commits.
- Stop at a commit with `edit` and split it into two.
- Run a test after every commit with `exec`, and recover when it fails.
- Explain why `ORIG_HEAD` may not point at the pre-rebase tip afterwards.

## CONCEPT

In one sentence: `git rebase -i <base>` 🟡 CAUTION shows you the to-do list before executing it, and the list is a program: one instruction per line, executed from top to bottom, that you may edit, reorder, extend or shorten.

`<base>` is the last commit you want to keep as it is. `git rebase -i main` offers every commit of the branch. `git rebase -i HEAD~3` offers the last three.

**[ON SCREEN]** The instruction table of section 9.6.

```text
Instruction          Short   Effect
-------------------  ------  --------------------------------------------------------------------------
pick <commit>        p       Replay the commit as it is
reword <commit>      r       Replay it, then open the editor on its message
edit <commit>        e       Replay it, then stop so that you can amend or split it
squash <commit>      s       Meld it into the commit on the line above; the editor opens on both messages
fixup <commit>       f       Meld it into the commit above and keep that commit's message.
                             fixup -C keeps this commit's message instead; -c also opens the editor
drop <commit>        d       Leave the commit out
exec <command>       x       Run a shell command; a non-zero exit status stops the rebase
break                b       Stop here
label, reset, merge  l, t, m Rebuild a branch structure (section 9.10)
update-ref <ref>     u       Move another branch to this point when the rebase finishes (section 9.9)
a line moved                 The commit is replayed at its new position
a line deleted               The same as drop, without a word
```

Read the last row twice. A deleted line is a dropped commit, and Git doesn't ask.

**[ANIMATION]** flow: actors=git_rebase_-i,your_editor msgs=1>2:the_todo_list_(git-rebase-todo)|2>1:the_list_as_you_saved_it|1>1:runs_it,_top_to_bottom title=The_one_difference:_you_see_the_list_first at_1=55 at_2=68 at_3=80 id=handed

**[ANIMATION]** step: handed.3

Inside `.git`: nothing new. It's the machinery from two videos ago: the state directory, the detached HEAD, the branch that moves only at the end. The one difference: the instruction file is handed to your editor before execution starts. The editor is `sequence.editor` or `GIT_SEQUENCE_EDITOR` if set, otherwise your normal commit message editor.

**[ANIMATION]** graph: 8afc6bd-c1adfe1-0527727-4394181 feat/metrics; 8afc6bd main; HEAD=feat/metrics => 4394181 feat/metrics; 8afc6bd main; HEAD=0527727 => c1adfe1-47852a1-6501387; 4394181 feat/metrics; 8afc6bd main; 0527727 ORIG_HEAD; HEAD=6501387 => 6501387-d0c6470 feat/metrics; 8afc6bd main; 0527727 ORIG_HEAD; 4394181 feat/metrics@{1}; HEAD=feat/metrics; reflog:0527727,4394181 title=Stopped_at_an_edit,_then_split id=split

**[ANIMATION]** step: split.state-2

Because it's the same machinery, the same fact holds: while the rebase is stopped, at an `edit`, at a failed `exec`, at a `break`, you're on a detached HEAD and the branch hasn't moved. On screen, a rebase has stopped at an `edit` on the middle commit: HEAD is there, and the branch label isn't. Commits you make during a stop are made on that detached HEAD.

**[ANIMATION]** step: split.state-4

And one consequence for undo. Commands you run during a stop can overwrite `ORIG_HEAD`. `git reset` writes it. So after an interactive rebase with a split, `ORIG_HEAD` may not name the tip from before the rebase. The reflog of the branch does.

**[ANIMATION]** end

When not to use it: on a branch other people have based work on. All of this is rewriting.

## MENTAL MODEL

**[ON SCREEN]** "An edit decision list."

A picture helps. The textbook's analogy: an edit decision list in film editing. A list of takes with an instruction for each: keep, cut, join with the previous one, retitle. The footage isn't altered. A new reel is assembled from it.

**[ANIMATION]** todo: todo=pick:A:oldest|pick:B:|pick:C:newest edit=pick:A:oldest|fixup:C:newest|pick:B: title=A_list_of_takes,_with_an_instruction_for_each id=abc

**[ANIMATION]** step: abc.list

**[ANIMATION]** say: Move_a_commit_in_front_of_the_one_it_builds_on,_and_the_replay_stops

Where it breaks: commits depend on each other. Move a take and the film still plays. Move a commit in front of the commit it builds on and the replay stops with a conflict.

**[ANIMATION]** say: Top_of_the_list_is_the_bottom_of_the_log._squash_and_fixup_act_on_the_line_above.

Two reading habits follow. First, the list runs oldest first, the opposite of `git log`. Top of the list is the bottom of the log. Second, `squash` and `fixup` act on the line above. So to combine two commits that aren't neighbours, you first move one line, and then change its verb.

Try it now, thirty seconds, on paper. The list says pick A, pick B, pick C, and you want C melded into A. Write the list you would save, and say it out loud.

**[PAUSE]**

**[ANIMATION]** step: abc.edit

Pick A, fixup C, pick B: one line moved, one verb changed. The verb goes on the commit that's melded away.

## DIAGRAM

**[DIAGRAM]** New diagram: the todo list on the left, the resulting graph on the right. Redraw the right side for each operation as it is demonstrated.

```text
  todo list (top = oldest)                 resulting history (left = oldest)

  pick   A  Add exact_match metric         A---B---C---D---E---F        as picked: unchanged
  pick   B  wip
  pick   C  add test                       fixup B:      AB'--C'--D'--E'--F'       B melted into A, A's message kept
  pick   D  debug print
  pick   E  Add ... F1 metirc              move F up     A---B---C---F'--D'--E'    F replayed after C
  pick   F  fix test                       below C:

                                           squash F      A---B---CF'--D'--E'       one commit, editor on both messages
                                           (under C):

                                           drop D:       A---B---C---E'--F'        D left out

                                           reword E:     A---B---C---D---E'--F'    only E and what follows are new

  Every commit from the first changed line onward gets a new ID (marked ').
  Commits above the first changed line are not copied: Git fast-forwards over them.
```

This is the map for the demo. Left: the todo list, oldest at the top. Right: the history each edit produces. A prime marks a new ID, and every commit from the first changed line onward gets one.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch09/interactive-basics`.

<!-- snippet: ch09/interactive-basics/01-messy -->
```text
$ git log --oneline --decorate
8313de0 (HEAD -> feat/metrics) fix test
031999d Add token-level F1 metirc
25dc48e debug print
cdb5f2f add test
a1056e1 wip
d33e9b2 Add exact_match metric
061c92d (main) Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

That's the branch from the hook. First, the list exactly as Git writes it. Using `cat` as the editor prints the file and saves it unchanged, so this rebase does nothing.

<!-- snippet: ch09/interactive-basics/02-list -->
```text
# Using "cat" as the editor prints the todo list exactly as Git wrote it and saves it unchanged.
$ GIT_SEQUENCE_EDITOR=cat git rebase -i main
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test

# Rebase 061c92d..8313de0 onto 061c92d (6 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
#                    commit's log message, unless -C is used, in which case
#                    keep only this commit's message; -c is same as -C but
#                    opens the editor
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
# l, label <label> = label current HEAD with a name
# t, reset <label> = reset HEAD to a label
# m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
#         create a merge commit using the original merge commit's
#         message (or the oneline, if no original merge commit was
#         specified); use -c <commit> to reword the commit message
# u, update-ref <ref> = track a placeholder for the <ref> to be updated
#                       to this position in the new commits. The <ref> is
#                       updated at the end of the rebase
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

Six `pick` lines, oldest first. Below them, the comment block, which is the complete reference. You never need to look the verbs up anywhere else. And in it, one line in capitals: "If you remove a line here THAT COMMIT WILL BE LOST."

Now six rebases, each with one edit, so that each instruction can be seen alone. In practice you make all edits in one pass, and that is Lab 9.1.

**[ANIMATION]** graph: 061c92d-d33e9b2-a1056e1-cdb5f2f-25dc48e-031999d-8313de0 feat/metrics; 061c92d main; HEAD=feat/metrics => 25dc48e-a2fd360-fcea3ea feat/metrics; 061c92d main; HEAD=feat/metrics; reflog:031999d,8313de0 title=reword:_which_commits_get_a_new_ID? id=reword

**[ANIMATION]** step: reword.state-1

**`reword`**, on the commit with the typo in its subject. Predict: how many of the six commits get a new ID? Say the number out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/interactive-basics/03-reword -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
--- todo list as saved ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
reword 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
Rebasing (5/6)
[detached HEAD a2fd360] Add token-level F1 metric
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 4 insertions(+)
 create mode 100644 eval/f1.py
Rebasing (6/6)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline
fcea3ea fix test
a2fd360 Add token-level F1 metric
25dc48e debug print
cdb5f2f add test
a1056e1 wip
d33e9b2 Add exact_match metric
061c92d Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

Two. Progress starts at "5 of 6". Lines 1 to 4 were unchanged, so Git fast-forwarded over them, and the first four commits kept their IDs.

**[ANIMATION]** step: reword.state-2

Only the reworded commit and the one after it are new objects: `a2fd360` and `fcea3ea`.

**[ANIMATION]** graph: 061c92d-d33e9b2-a1056e1-cdb5f2f-25dc48e-a2fd360-fcea3ea feat/metrics; 061c92d main; HEAD=feat/metrics => 061c92d-753f401-babe12d-0d58a02-3838789-92f52c5 feat/metrics; 061c92d main; HEAD=feat/metrics; reflog:d33e9b2,a1056e1,cdb5f2f,25dc48e,a2fd360,fcea3ea title=fixup:_which_commits_get_a_new_ID? id=fixup

**[ANIMATION]** step: fixup.state-1

**`fixup`**, to fold "wip" into the commit above it. Predict again.

**[PAUSE]**

<!-- snippet: ch09/interactive-basics/04-fixup -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick a2fd360 # Add token-level F1 metric
pick fcea3ea # fix test
--- todo list as saved ---
pick d33e9b2 # Add exact_match metric
fixup a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick a2fd360 # Add token-level F1 metric
pick fcea3ea # fix test
Rebasing (2/6)
Rebasing (3/6)
Rebasing (4/6)
Rebasing (5/6)
Rebasing (6/6)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline
92f52c5 fix test
3838789 Add token-level F1 metric
0d58a02 debug print
babe12d add test
753f401 Add exact_match metric
061c92d Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

Six commits became five, and all five have new IDs: the first because "wip" was melded into it, the others because their parent changed.

**[ANIMATION]** step: fixup.state-2

On the graph: five new commits, and the six old ones left behind.

**[ANIMATION]** end

**Reordering**, to bring "fix test" directly behind "add test".

<!-- snippet: ch09/interactive-basics/05-reorder -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 753f401 # Add exact_match metric
pick babe12d # add test
pick 0d58a02 # debug print
pick 3838789 # Add token-level F1 metric
pick 92f52c5 # fix test
--- todo list as saved ---
pick 753f401 # Add exact_match metric
pick babe12d # add test
pick 92f52c5 # fix test
pick 0d58a02 # debug print
pick 3838789 # Add token-level F1 metric
Rebasing (3/5)
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline
8f81a9f Add token-level F1 metric
9013484 debug print
1537b45 fix test
babe12d add test
753f401 Add exact_match metric
061c92d Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

One line moved up two places. No verb changed.

**`squash`**, now that the two test commits are neighbours. The editor opens on the combined message, and the scripted editor types a better one.

<!-- snippet: ch09/interactive-basics/06-squash -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 753f401 # Add exact_match metric
pick babe12d # add test
pick 1537b45 # fix test
pick 9013484 # debug print
pick 8f81a9f # Add token-level F1 metric
--- todo list as saved ---
pick 753f401 # Add exact_match metric
pick babe12d # add test
squash 1537b45 # fix test
pick 9013484 # debug print
pick 8f81a9f # Add token-level F1 metric
Rebasing (3/5)
[detached HEAD 62a8273] Test exact_match, including surrounding whitespace
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 5 insertions(+)
 create mode 100644 tests/test_metrics.py
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline
45ad5b3 Add token-level F1 metric
fe1bccf debug print
62a8273 Test exact_match, including surrounding whitespace
753f401 Add exact_match metric
061c92d Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

What does the editor show at that moment? `labs/run ch09/squash-message`, on a cleaner branch, with `cat` standing in for the message editor.

<!-- snippet: ch09/squash-message/01-squash-buffer -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 143e55a # Add exact_match metric
pick 375df0b # Test exact_match
pick a25e84c # Add token-level F1 metric
--- todo list as saved ---
pick 143e55a # Add exact_match metric
squash 375df0b # Test exact_match
pick a25e84c # Add token-level F1 metric
Rebasing (2/3)
# This is a combination of 2 commits.
# This is the 1st commit message:

Add exact_match metric

# This is the commit message #2:

Test exact_match

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Mon Sep 7 10:03:00 2026 +0530
#
# interactive rebase in progress; onto 8afc6bd
# Last commands done (2 commands done):
#    pick 143e55a # Add exact_match metric
#    squash 375df0b # Test exact_match
# Next command to do (1 remaining command):
#    pick a25e84c # Add token-level F1 metric
# You are currently rebasing branch 'feat/metrics' on '8afc6bd'.
#
# Changes to be committed:
#	new file:   eval/metrics.py
#	new file:   tests/test_metrics.py
#
[detached HEAD 5a2e35c] Add exact_match metric
 Date: Mon Sep 7 10:03:00 2026 +0530
 2 files changed, 6 insertions(+)
 create mode 100644 eval/metrics.py
 create mode 100644 tests/test_metrics.py
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

Both messages, each under a comment line: "This is the 1st commit message", "This is the commit message #2". Lines that start with `#` are removed when you save, so saving this buffer unchanged gives a message made of both texts. `fixup` skips this step and keeps the first message.

**`drop`**, for the debugging commit.

<!-- snippet: ch09/interactive-basics/07-drop -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 753f401 # Add exact_match metric
pick 62a8273 # Test exact_match, including surrounding whitespace
pick fe1bccf # debug print
pick 45ad5b3 # Add token-level F1 metric
--- todo list as saved ---
pick 753f401 # Add exact_match metric
pick 62a8273 # Test exact_match, including surrounding whitespace
drop fe1bccf # debug print
pick 45ad5b3 # Add token-level F1 metric
Rebasing (4/4)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline --decorate
d1d1482 (HEAD -> feat/metrics) Add token-level F1 metric
62a8273 Test exact_match, including surrounding whitespace
753f401 Add exact_match metric
061c92d (main) Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/interactive-basics/08-result -->
```text
$ git show --stat --format="%h %s" HEAD~2 HEAD~1 HEAD
753f401 Add exact_match metric

 eval/metrics.py | 2 ++
 1 file changed, 2 insertions(+)
62a8273 Test exact_match, including surrounding whitespace

 tests/test_metrics.py | 5 +++++
 1 file changed, 5 insertions(+)
d1d1482 Add token-level F1 metric

 eval/f1.py | 4 ++++
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

Three commits, one decision each: a metric, its test, a second metric. Each stat shows one file. That's the list of six from the start of the video, ready for bisect and for revert.

**`edit`: stop inside the history.** `labs/run ch09/interactive-edit`. One commit of this branch mixes a new metric with a configuration change.

<!-- snippet: ch09/interactive-edit/01-before -->
```text
$ git log --oneline --decorate
4394181 (HEAD -> feat/metrics) Test both metrics
0527727 Add F1 metric and raise max_tokens
c1adfe1 Add exact_match metric
8afc6bd (main) Add retriever and model config
$ git show --stat --format="%h %s" HEAD~1
0527727 Add F1 metric and raise max_tokens

 config/model.yaml | 2 +-
 eval/f1.py        | 4 ++++
 2 files changed, 5 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch09/interactive-edit/02-edit-stops -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick c1adfe1 # Add exact_match metric
pick 0527727 # Add F1 metric and raise max_tokens
pick 4394181 # Test both metrics
--- todo list as saved ---
pick c1adfe1 # Add exact_match metric
edit 0527727 # Add F1 metric and raise max_tokens
pick 4394181 # Test both metrics
Rebasing (2/3)
Stopped at 0527727...  # Add F1 metric and raise max_tokens
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
```
<!-- /snippet -->

"Stopped at 0527727." The rebase has replayed that commit and stopped. You're on a detached HEAD with the commit as the tip. To split it, take the commit back while keeping its changes in the working tree, and commit them in two portions.

<!-- snippet: ch09/interactive-edit/03-split -->
```text
$ git reset HEAD^
Unstaged changes after reset:
M	config/model.yaml
$ git status --short
 M config/model.yaml
?? eval/f1.py
$ git add eval/f1.py
$ git commit -m "Add token-level F1 metric"
[detached HEAD 47852a1] Add token-level F1 metric
 1 file changed, 4 insertions(+)
 create mode 100644 eval/f1.py
$ git commit -a -m "Raise max_tokens to 1024 for long answers"
[detached HEAD 6501387] Raise max_tokens to 1024 for long answers
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

`git reset HEAD^` 🟡 is a mixed reset: HEAD and the index go back one commit, the files stay. `HEAD~1` names the same commit and is the safer spelling in shells that treat `^` as a pattern character. Then two commits: `47852a1` for the metric, `6501387` for the configuration.

<!-- snippet: ch09/interactive-edit/04-continue -->
```text
$ git rebase --continue
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline --decorate
d0c6470 (HEAD -> feat/metrics) Test both metrics
6501387 Raise max_tokens to 1024 for long answers
47852a1 Add token-level F1 metric
c1adfe1 Add exact_match metric
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

Four commits where there were three. Now the side effect. Predict what `ORIG_HEAD` names.

**[PAUSE]**

<!-- snippet: ch09/interactive-edit/05-orig-head-moved -->
```text
# ORIG_HEAD no longer names the tip from before the rebase: "git reset" overwrote it.
$ git rev-parse --short ORIG_HEAD
0527727
$ git diff --stat ORIG_HEAD HEAD
 tests/test_metrics.py | 8 ++++++++
 1 file changed, 8 insertions(+)
# The reflog of the branch still has the old tip. The two trees are identical, so this prints nothing:
$ git diff --stat feat/metrics@{1} feat/metrics
$ git reflog show feat/metrics -2
d0c6470 feat/metrics@{0}: rebase (finish): refs/heads/feat/metrics onto 8afc6bd28c2572af09f1b6c37d733535230e526f
4394181 feat/metrics@{1}: commit: Test both metrics
```
<!-- /snippet -->

`0527727`: the mixed commit, not the tip from before the rebase. `git reset` writes `ORIG_HEAD` too. The reflog of the branch still has the old tip, `feat/metrics@{1}`, and the diff between it and the new tip prints nothing: the two trees are identical. That empty diff is the proof that a split changed history and not content.

**`exec`: test every commit.** `labs/run ch09/interactive-exec`. A rewritten history is a series of snapshots that nobody has run. `--exec` adds an `exec` line after every commit.

<!-- snippet: ch09/interactive-exec/02-exec-stops -->
```text
$ git rebase --exec "sh scripts/check.sh" main
Rebasing (2/6)
Executing: sh scripts/check.sh
check passed
Rebasing (3/6)
Rebasing (4/6)
Executing: sh scripts/check.sh
eval/f1.py:3:    print("DEBUG", p, g)
check failed: remove the debug print
warning: execution failed: sh scripts/check.sh
You can fix the problem, and then run

  git rebase --continue


[exit status: 1]
```
<!-- /snippet -->

The check passed after the first commit and failed after the second: it found a debug print. Exit status 1. Quick quiz. Where is the branch now? A, on the failing commit. B, still on its old tip. Your answer?

**[PAUSE]**

<!-- snippet: ch09/interactive-exec/03-where -->
```text
$ git log --oneline --decorate -2
67c1620 (HEAD) Add token-level F1 metric
625fdb8 Add exact_match metric
$ cat .git/rebase-merge/git-rebase-todo
pick f73498cc94810e2909007a8eed1a685eeedc687d # Test both metrics
exec sh scripts/check.sh
```
<!-- /snippet -->

B. HEAD is detached on the failing commit, `67c1620`. The todo file has the rest of the list waiting: one pick and one exec. The branch hasn't moved. Repair the commit and continue.

<!-- snippet: ch09/interactive-exec/04-fix-and-continue -->
```text
# In an editor: delete the DEBUG line from eval/f1.py. Then:
$ git diff --stat
 eval/f1.py | 1 -
 1 file changed, 1 deletion(-)
$ git commit -a --amend --no-edit
[detached HEAD 674e131] Add token-level F1 metric
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 4 insertions(+)
 create mode 100644 eval/f1.py
$ git rebase --continue
Rebasing (5/6)
Rebasing (6/6)
Executing: sh scripts/check.sh
check passed
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

`git commit --amend` 🟡 replaces the failing commit on the detached HEAD, `--continue` runs the rest, and the check passes at the end.

`exec` is an ordinary line. With `-i --exec` you see the generated lines and may remove some. `labs/run ch09/interactive-exec-lines`. Here only the last one is kept.

<!-- snippet: ch09/interactive-exec-lines/01-exec-lines -->
```text
$ git rebase -i --exec "sh scripts/check.sh" main
--- todo list as Git opened it (comment lines removed) ---
pick 625fdb8 # Add exact_match metric
exec sh scripts/check.sh
pick 67c1620 # Add token-level F1 metric
exec sh scripts/check.sh
pick f73498c # Test both metrics
exec sh scripts/check.sh
--- todo list as saved ---
pick 625fdb8 # Add exact_match metric
pick 67c1620 # Add token-level F1 metric
pick f73498c # Test both metrics
exec sh scripts/check.sh
Rebasing (4/4)
Executing: sh scripts/check.sh
eval/f1.py:3:    print("DEBUG", p, g)
check failed: remove the debug print
warning: execution failed: sh scripts/check.sh
You can fix the problem, and then run

  git rebase --continue
```
<!-- /snippet -->

The check now fails at the tip. You learn that the branch is broken, not which commit broke it. That's the argument for one `exec` per commit.

**`break` and changing the plan.** `labs/run ch09/interactive-break`. `break` stops the rebase without touching a commit, so that you can look around.

<!-- snippet: ch09/interactive-break/01-break -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
--- todo list as saved ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
break
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
Rebasing (4/7)
Stopped at cdb5f2f (add test)
```
<!-- /snippet -->

While any rebase is stopped, you can reopen the remaining instructions in the editor with `git rebase --edit-todo`.

<!-- snippet: ch09/interactive-break/03-edit-list -->
```text
$ git rebase --edit-todo
--- todo list as Git opened it (comment lines removed) ---
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
--- todo list as saved ---
drop 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
```
<!-- /snippet -->

Only the instructions not yet executed are offered: three lines, not seven. What is done is done. To change that, abort and start again.

<!-- snippet: ch09/interactive-break/04-continue -->
```text
$ git rebase --continue
Rebasing (5/7)
Rebasing (6/7)
Rebasing (7/7)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline --decorate
2d1d481 (HEAD -> feat/metrics) fix test
c7c12a0 Add token-level F1 metirc
cdb5f2f add test
a1056e1 wip
d33e9b2 Add exact_match metric
061c92d (main) Add lint script
8afc6bd Add retriever and model config
$ sh scripts/check.sh
check passed
```
<!-- /snippet -->

The first three commits kept their IDs, the debug commit is gone, and the check passes.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Deleting a line to "skip it for now".** Root cause: a deleted line is the same as `drop`, without a word; `rebase.missingCommitsCheck` can turn that silence into a warning or an error.
2. **Putting `squash` on the wrong line.** Root cause: `squash` and `fixup` meld a commit into the line above, and the list runs oldest first, the opposite of `git log`.
3. **Expecting commits made during a stop to be on the branch.** Root cause: HEAD is detached during the whole run and the branch ref moves only when the list is empty.
4. **Running `git reset --hard ORIG_HEAD` to undo an interactive rebase that included a split.** Root cause: the `git reset` used for the split overwrote `ORIG_HEAD`; the branch's reflog entry `@{1}` is the old tip.
5. **Keeping one `exec` at the end "to save time".** Root cause: a failure at the tip says the branch is broken, not which commit broke it, and bisect needs every commit to build.

## PRODUCTION EXAMPLE

**[ANIMATION]** gates: packet=the_todo_list gates=pick:done|exec:pass|pick:done|exec:pass|pick:done|exec:pass result=proved_commit_by_commit title=One_exec_per_commit id=proved

Now, out of the lab. An evaluation team has a rule for pull requests that change metrics code: before the first review, the author runs `git rebase -i --exec "<the test command>" main`.

The reason is the hook of this video, stated by the textbook: the purpose of a tidy history isn't beauty. `git bisect` can find a regression only if every commit builds, and a revert removes one decision only if a commit contains one decision. A branch cleaned up with one `exec` per commit has been proved commit by commit.

**[ANIMATION]** end

The rule costs the author a few minutes. It has paid for itself the first time a score regression had to be bisected across forty commits and every one of them ran.

The team also sets `rebase.missingCommitsCheck`, after one engineer lost a commit by deleting a line. The one line to remember from the comment block is the one in capitals.

## PRACTICE EXERCISE

Your turn. Do Lab 9.1, "Clean up a messy branch", in [`lab-manual/m09-rebase.md`](../../lab-manual/m09-rebase.md).

Before you open the editor:

- Write the todo list you intend to save, line by line, oldest first.
- Write the `git log --oneline` you expect afterwards.
- Mark which commits you expect to keep their IDs.

Then do it in one pass. If the result differs from your prediction, find the old tip in the branch's reflog, go back, and predict again.

The challenge is Exercise 9.7, Level 3, "a rebase that stopped at an `exec` line", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q403: "During a rebase, when does the branch ref move, and what follows from that for commits made while the rebase is stopped?"

**[PAUSE]**

Answer out loud first. A strong answer gives the moment precisely, and says where HEAD is in the meantime. Then it draws consequences, at least three: for a commit made during a stop, for what `--abort` returns to, and for which names still reach the old tip afterwards. If you mention a command that can be run during a stop and that changes one of those names, you have shown that you have done this by hand.

## RECAP

**[ANIMATION]** step: list6.list

Let's land this. You should now be able to say:

An interactive rebase hands me the todo list before running it, and the list runs top to bottom, oldest first.

**[ANIMATION]** step: abc.edit

`reword` changes a message, `fixup` and `squash` meld a commit into the line above, a moved line replays the commit at its new position, and `drop` or a deleted line leaves it out.

**[ANIMATION]** step: split.state-4

`edit` stops after a commit so that I can amend it or split it with a mixed reset and several commits.

**[ANIMATION]** step: proved.result

`exec` runs a command after a commit and stops on a non-zero status, and `break` stops without doing anything.

**[ANIMATION]** step: split.state-4

During every stop HEAD is detached and the branch hasn't moved, and after a split I take the old tip from the branch's reflog, not from `ORIG_HEAD`.

## HOMEWORK

Read section 9.6 of [Chapter 9](../../textbook/ch09-rebase.md).

Repeat Lab 9.1, "Clean up a messy branch", in [`lab-manual/m09-rebase.md`](../../lab-manual/m09-rebase.md) until the result takes one pass.

You turned six messy commits into three clean ones today, and proved each one with a test. Practise it in the lab until one pass is enough. Next time: fixup commits, autosquash, autostash, stacked branches and rebase-merges. Until then, look at the state first and type second. See you in the next one.
