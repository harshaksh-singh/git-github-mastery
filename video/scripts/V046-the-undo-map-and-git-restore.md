# V046: The undo map and git restore

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 8, Undoing changes
- **Planned minutes:** 20
- **Prerequisites:** V017, V045
- **Textbook sections:** [Chapter 11](../../textbook/ch11-reset-revert-restore.md), sections 11.2 and 11.3 (hook from section 11.1)
- **Demo scripts:** `labs/ch11/restore-variants.sh`

## HOOK

**[ON SCREEN]** "A bad configuration change is on `main` and three people have already pulled it. What exactly do we run, and what must nobody run?"

That's a CTO's question in the hour after something went wrong, and it has two halves. Most engineers can answer the first half. The second half, what must nobody run, is where the damage comes from. Hold on to that second half.

Undo is where Git costs its users the most time. The textbook records that on the first of October 2026, the highest-voted question under Stack Overflow's `git` tag was "How do I undo the most recent local commits in Git?", and six more undo questions were in the top 25. The cause isn't that undo is hard. It's that Git has no single undo.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair: this is Part 3, and the module on undoing changes. The commit IDs in these recordings equal the IDs in the book, because replays use the fixed clock.

**[ANIMATION]** cards: question=Git_has_no_single_undo cards=restore|reset|revert|clean|stash at_1=14 at_2=18 at_3=22 at_4=26 at_5=30

Git has five commands for undoing work: `restore`, `reset`, `revert`, `clean` and `stash`. Each is defined by the places it writes to. So before any command, this video gives you the map: four places, and one question that decides between two families of undo.

**[ANIMATION]** end

Then you take the first command, `git restore`, which you met in the working-tree chapter. Today you see every form of it, against one file that has a different version in each place. That way the direction of every copy is visible.

Everything on screen is Git, with one callout to GitHub.

## LEARNING OBJECTIVES

**[ON SCREEN]** The four objectives.

After this video you can:

- Name the four places an undo can act on, and the one question that decides between rewriting and adding.
- Say for each form of `git restore` where the content comes from and where it goes.
- Restore a path from an older commit into the index, the working tree, or both.
- State which forms of `git restore` destroy work that no object holds.

## CONCEPT

**The four places.** Every undo command writes to one or more of these, and to nothing else.

**[ON SCREEN]** The table of section 11.2.

```text
Place                 What it holds
--------------------  ------------------------------------------------------------------
Working tree          The files on disk, including edits that exist nowhere else
Index                 The proposed next commit: one blob ID per tracked path
Current branch ref    One commit ID under refs/heads/; HEAD normally points at this ref
History               The commits reachable from that ref. After a push, other
                      repositories hold them too
```

Read the rows with me: your files on disk, the proposed next commit, the one commit ID your branch name holds, and the commits reachable from it.

Git's own manual draws the same lines between the three main commands. `git restore` "does not update your branch". `git reset` is about "updating your branch, moving the tip". `git revert` is about "making a new commit that reverts the changes made by other commits".

**[ANIMATION]** graph: A-B-C-D main; A-B origin/main; HEAD=main => + range:A,B:shared; range2:C,D:private; name:shared => + A-B-C-D-R main; note:R:the_inverse_change; cmd:git_revert; say:Shared_history_is_corrected_by_adding_a_commit; name:revert => + say:On_a_shared_main,_nobody_rewrites._You_add.; name:add id=line captions=room

**[ANIMATION]** step: shared

**The deciding question: is this history private or shared?** A commit, one saved snapshot of the project, is shared when a ref that other people can fetch reaches it. Everything else is private: it exists only in your repository. On screen, the label `origin/main` is your record of the server's branch. A and B are shared. C and D are private.

**[ANIMATION]** say: Private_history_may_be_rewritten:_nobody_else_has_C_and_D

Private history may be rewritten. `git reset`, `git commit --amend` and `git rebase` replace commits with new ones, or drop them from the branch. Nobody else can notice, because nobody else has the old commits.

**[ANIMATION]** step: revert

Shared history is corrected by adding commits. `git revert` records the inverse change on top, and everyone's next pull brings it in like any other commit.

**[ANIMATION]** remotes: [your clone] A-B-C main; HEAD=none || [the server] A-B-C main; HEAD=none || [a teammate's clone] A-B-C main; HEAD=none => + B main; reflog:C; cmd:git_reset; say:You_move_your_branch_backwards; name:backwards || || => + rejected:B; cmd:git_push; say:Rejected:_your_new_tip_is_not_a_descendant_of_the_server's; name:rejects || || => [your clone] A-B-C; B main; reflog:C; HEAD=none; cmd:!git_push_--force; say:A_forced_push_moves_the_server's_branch_back; name:force || + B main; ghost:C || => + say:The_next_push_from_a_clone_that_still_has_C_puts_it_straight_back; cmd:git_push; name:puts-them || || + mark:still_here:C title=Why_shared_history_is_not_rewritten

**[ANIMATION]** step: puts-them

The textbook insists that the reason is mechanical, not etiquette. A branch in a teammate's clone is a ref that holds a commit ID. If you move your branch backwards, their ref still names the commits you removed. The server rejects your plain push as a non-fast-forward, because your new tip isn't a descendant of its old one. If you force the push, the next teammate who pushes from a clone that still has those commits puts them straight back, or merges them with your replacements.

**[ANIMATION]** step: line.add

So, the CTO's second half: on a shared `main`, nobody rewrites. You add.

So before any undo that touches commits, check which side of the line you're on.

**[ON SCREEN]** The four commands.

```bash
git fetch                              # refresh what you know about the server
git status -sb                         # "ahead 2": two commits the upstream lacks
git log --oneline @{u}..               # the commits that are still private
git branch -r --contains <commit>      # remote-tracking branches that contain <commit>
```

The last two read remote-tracking branches, which record the state of the last fetch. Without the `git fetch` in front, they answer for an older moment. The last module showed why.

**[ANIMATION]** trees: file=eval.yaml versions=0.70,0.80,0.90 state=3,2,1 ref=main commits=9d940ca id=strip steps=setup,unstage title=git_restore:_a_source_and_a_destination say_setup=One_file,_a_different_version_in_each_place

**[ANIMATION]** step: setup

**`git restore`.** In one sentence: it copies a stored version of the named paths into the working tree, into the index, or into both, and moves no ref.

**[ANIMATION]** say: The_destination:_working_tree,_index,_or_both._The_source:_index,_HEAD,_or_--source

Two choices define every form of it. The destination: the working tree by default, the index with `--staged`, both with `--staged --worktree`. And the source, which you can name with `--source=<tree>`. Without it, the source is the index when only the working tree is written, and HEAD, your current commit, as soon as `--staged` is given.

**[ANIMATION]** say: A_restore_creates_no_object,_moves_no_ref_and_writes_no_reflog_entry

Inside `.git`: a restore rewrites files, or blob IDs in index entries. A blob is the object that holds the bytes of one file. No object is created, no ref moves, and no reflog entry is written. The reflog is the local list of the values a ref has had, so there's no record to go back to.

**[ANIMATION]** end

That last sentence gives the risk labels. Every form that writes the working tree is 🔴 DANGEROUS. `--staged` alone is 🟡 CAUTION.

Quick quiz. You staged a change by mistake, and you want it out of the index with your edits untouched. A, plain `git restore`. B, `git restore --staged`. Your answer?

**[PAUSE]**

**[ANIMATION]** step: strip.unstage

B. With `--staged` alone, the destination is the index. A overwrites your file instead.

## MENTAL MODEL

**[ON SCREEN]** "Pick the original. Pick the tray."

A picture helps. The textbook's analogy for `git restore` is a photocopier with two output trays. You pick the original and the tray, and whatever lay in the tray is replaced.

It breaks at the replaced sheet. You don't get it back. A photocopier leaves the old sheet on the floor. `git restore` leaves nothing, unless that content had been staged or committed at some point, and so exists as an object.

**[ANIMATION]** cards: question=Two_questions,_in_this_order cards=Private_or_shared?:chooses_between_rewriting_and_adding|Which_of_the_four_places_must_change?:chooses_the_command numbered=on at_1=30 at_2=62

For the whole module, hold this second model. Ask two questions, in this order. One: is the thing I want to undo private or shared? That chooses between rewriting and adding. Two: which of the four places must change? That chooses the command.

## DIAGRAM

**[DIAGRAM]** Three boxes side by side. Fill in the three versions first: 0.90, 0.80, 0.70. Then draw one arrow per `git restore` form, each from its source to its destination. Last, the two lines for reset and revert, as a preview.

```text
    WORKING TREE              INDEX                  HEAD -> main
    files on disk             proposed commit        last commit
   +--------------+         +--------------+        +--------------+
   | eval.yaml    |         | eval.yaml    |        | eval.yaml    |
   | 0.90         |         | 0.80         |        | 0.70         |
   +--------------+         +--------------+        +--------------+
          ^                     |      ^                    |
          +---- git restore ----+      +-- git restore -----+
                                           --staged
          ^                                                 |
          +------------ git restore --source=HEAD ----------+

   git reset <commit>    moves the ref "main"; --mixed also rewrites the index,
                         --hard also rewrites the working tree
   git revert <commit>   adds one commit after the current one; nothing is removed
```

Every arrow of `git restore` points left: from a stored version toward your files. No arrow touches the label `main`.

**[ANIMATION]** trees: file=eval.yaml versions=0.70,0.80,0.90 ref=main commits=9d940ca steps=setup,edit,add,edit2,restore cmd_add=off title=One_file,_three_values say_setup=Start:_0.70_in_all_three_places say_edit=An_edit:_0.80,_on_disk_only say_add=Staged:_the_index_holds_0.80 say_edit2=A_second_edit:_0.90,_on_disk_only

Watch the first arrow move. Start with 0.70 in all three places.

**[ANIMATION]** step: add

You edit the file to 0.80, and add it to the index.

**[ANIMATION]** step: restore

You edit again, to 0.90, and run plain `git restore`. The index is copied over the file, and 0.90 is gone for good.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch11/restore-variants`. One file, `eval.yaml`, with a different threshold in each place. Every command below starts from a fresh copy of this state.

<!-- snippet: ch11/restore-variants/01-before -->
```text
$ git log --oneline
9d940ca Raise threshold to 0.70
d44696e Raise threshold to 0.60
4d17008 Add eval config
$ git show HEAD:eval.yaml
threshold: 0.70
$ git show :eval.yaml
threshold: 0.80
$ cat eval.yaml
threshold: 0.90
$ git status -s
MM eval.yaml
```
<!-- /snippet -->

0.70 in HEAD, 0.80 staged, 0.90 on disk, and status `MM`. Two commits further back, the value was 0.50.

Try it now, thirty seconds, on paper: draw those three boxes with today's values in them. That's a three-tree strip. Before each variant, fill in a new one: which value will each place hold afterwards?

**[PAUSE]**

**Variant 1: plain restore.** Because this is the first 🔴 command of the module, the five answers. What it changes: the named files in the working tree. What it can destroy: unstaged edits in the named paths, without asking. Preview: `git diff -- <path>`. Recovery: nothing brings back content that was never staged. Appropriate: when you have looked at that diff and want to discard it. Predict the three values, out loud. I'll wait.

```bash
git restore eval.yaml
```

**[PAUSE]**

<!-- snippet: ch11/restore-variants/02-worktree -->
```text
$ git restore eval.yaml
$ git show :eval.yaml
threshold: 0.80
$ cat eval.yaml
threshold: 0.80
$ git status -s
M  eval.yaml
```
<!-- /snippet -->

The index was copied over the file. The edit to 0.90 is destroyed, and the staged 0.80 stays. Status: `M` in the first column only.

**Variant 2: `--staged`.** 🟡 CAUTION. Predict the strip.

```bash
git restore --staged eval.yaml
```

**[PAUSE]**

<!-- snippet: ch11/restore-variants/03-staged -->
```text
$ git restore --staged eval.yaml
$ git show :eval.yaml
threshold: 0.70
$ cat eval.yaml
threshold: 0.90
$ git status -s
 M eval.yaml
```
<!-- /snippet -->

HEAD was copied over the index entry, and the file was left alone. This is "unstage". Index 0.70, file 0.90.

`git reset -- <path>` is the older spelling of the same operation.

<!-- snippet: ch11/restore-variants/03b-reset-path -->
```text
$ git reset -- eval.yaml
Unstaged changes after reset:
M	eval.yaml
$ git show :eval.yaml
threshold: 0.70
$ cat eval.yaml
threshold: 0.90
$ git status -s
 M eval.yaml
```
<!-- /snippet -->

Identical result, and reset adds a status line.

**[ANIMATION]** step: strip.unstage

**[ANIMATION]** say: 0.80_existed_only_in_the_index:_now_a_blob_that_nothing_names

Now ask: where is 0.80? It's no longer in the index, and it's not on disk, because the file had moved on to 0.90. A version that existed only in the index is now a blob that nothing names. The next video shows how to find one.

**Variant 3: both, from HEAD.**

<!-- snippet: ch11/restore-variants/04-staged-worktree -->
```text
$ git restore --staged --worktree eval.yaml
$ git show :eval.yaml
threshold: 0.70
$ cat eval.yaml
threshold: 0.70
$ git status -s
```
<!-- /snippet -->

Both places are set to HEAD's version, and the status is empty.

**Variant 4: `--source`.** The content comes from a commit, here `HEAD~2`, two commits back. Predict the three values and the status. Say them out loud.

```bash
git restore --source=HEAD~2 eval.yaml
```

**[PAUSE]**

<!-- snippet: ch11/restore-variants/05-source -->
```text
$ git restore --source=HEAD~2 eval.yaml
$ git show :eval.yaml
threshold: 0.80
$ cat eval.yaml
threshold: 0.50
$ git status -s
MM eval.yaml
```
<!-- /snippet -->

Without `--staged`, only the file is written: 0.50 on disk, the index still holds 0.80, and the status stays `MM`.

**Variant 5: `--source` with both destinations.**

<!-- snippet: ch11/restore-variants/06-source-staged-worktree -->
```text
$ git restore --source=HEAD~2 --staged --worktree eval.yaml
$ git show :eval.yaml
threshold: 0.50
$ cat eval.yaml
threshold: 0.50
$ git status -s
M  eval.yaml
$ git log --oneline -1
9d940ca Raise threshold to 0.70
```
<!-- /snippet -->

Both places receive the old version. And the last command proves that HEAD didn't move: it's still `9d940ca`. This is an old version of one file, placed on top of the current commit, ready to be committed as a new change.

**The older spelling.** You'll read it in scripts.

<!-- snippet: ch11/restore-variants/07-checkout-equivalent -->
```text
$ git checkout HEAD~2 -- eval.yaml
$ git show :eval.yaml
threshold: 0.50
$ cat eval.yaml
threshold: 0.50
$ git status -s
M  eval.yaml
```
<!-- /snippet -->

`git checkout <commit> -- <path>` does what the last variant did, index included. Likewise, older scripts write `git checkout -- <path>` for `git restore <path>`, and `git reset HEAD <path>` for `git restore --staged <path>`.

**Part of a file.** `git restore -p` walks through the differences hunk by hunk, and asks about each one. A hunk is one block of changed lines. Here `score.py` has two unstaged changes, a debug line and a real fix. The demo pipes the answers `y` and `n` in, so each prompt is followed directly by the next output.

<!-- snippet: ch11/restore-variants/08-patch -->
```text
$ printf 'y\nn\n' | git restore -p score.py
diff --git a/score.py b/score.py
index 9f65fd2..564c708 100644
--- a/score.py
+++ b/score.py
@@ -2,6 +2,7 @@ import json
 
 
 def load(path):
+    print("DEBUG loading", path)
     with open(path) as f:
         return [json.loads(line) for line in f]
 
(1/2) Discard this hunk from worktree [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? @@ -16,7 +17,7 @@ def exact_match(pred, gold):
 
 def accuracy(rows):
     hits = sum(exact_match(r["pred"], r["gold"]) for r in rows)
-    return hits / len(rows)
+    return hits / max(len(rows), 1)
 
 
 if __name__ == "__main__":
(2/2) Discard this hunk from worktree [y,n,q,a,d,K,J,g,/,e,p,P,?]? 
```
<!-- /snippet -->

<!-- snippet: ch11/restore-variants/09-patch-result -->
```text
$ git diff
diff --git a/score.py b/score.py
index 9f65fd2..7c6b98d 100644
--- a/score.py
+++ b/score.py
@@ -16,7 +16,7 @@ def exact_match(pred, gold):
 
 def accuracy(rows):
     hits = sum(exact_match(r["pred"], r["gold"]) for r in rows)
-    return hits / len(rows)
+    return hits / max(len(rows), 1)
 
 
 if __name__ == "__main__":
```
<!-- /snippet -->

Only the fix is left in the diff. The debug line was discarded. `-p` also combines with `--staged` and with `--source`.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Rewriting a shared branch to remove a bad commit.** Root cause: teammates' refs still name the removed commits, so a plain push is rejected and a forced one is undone or merged by the next person who pushes.
2. **Checking "is it pushed?" without fetching first.** Root cause: `@{u}` and `git branch -r --contains` read remote-tracking branches, which record the last fetch.
3. **Running `git restore <path>` to "unstage".** Root cause: without `--staged` the destination is the working tree and the source is the index, so the unstaged edits are destroyed and the staged version stays.
4. **Expecting `git restore --source=<commit> <path>` to leave a clean, staged change.** Root cause: without `--staged` only the file is written; the index keeps what it had.
5. **Looking in the reflog for the state before a restore.** Root cause: a restore moves no ref and writes no reflog entry.

## PRODUCTION EXAMPLE

**[ANIMATION]** graph: ?good-?tuned-*1-*2 main; HEAD=main; note:?tuned:prompts/system.txt_changed => + ?good-?tuned-*1-*2-?new main; note:?new:one_file_back,_history_intact; cmd:git_restore_--source=<good_commit>_prompts/system.txt

**[ANIMATION]** step: state-1

Now, out of the lab. An evaluation regressed after someone tuned `prompts/system.txt` three commits ago, and those commits also contain good changes. Reverting the commits would throw the good changes out too.

**[ANIMATION]** step: state-2

`git restore --source=<good commit> prompts/system.txt`, followed by an ordinary commit, puts one file back and leaves history intact. It's safe on shared branches, because it only adds a commit. That's the map applied. The history is shared, so you add. The place that must change is one path, so you restore it from a source.

**[ON SCREEN]** Layer label: GitHub.

And the platform side of the deciding question. According to GitHub's documentation, a new ruleset, GitHub's named list of branch rules, has "Block force pushes" enabled by default, and classic branch protection rules disable force pushes by default. On a protected `main`, rewriting is normally not even available, and a revert commit is the only route.

## PRACTICE EXERCISE

Your turn. Do Lab 8.4, "Restore variants", in [`lab-manual/m08-undo.md`](../../lab-manual/m08-undo.md).

Before each command of the lab, draw the three-tree strip, and write the value you expect in each box afterwards, plus the two status letters. Compare with the output only after you've written all three values.

One more prediction for the lab's failure scenario: which of the versions you destroy could still exist as an object, and which couldn't?

The challenge is Exercise 8.7, Level 3, "the commit that came back", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q170: "A colleague asks for "the undo command". Name the five commands that Git offers for undoing work, and say which of working tree, index, branch ref and history each one writes."

**[PAUSE]**

Answer out loud first. A strong answer refuses the premise politely in one sentence, and then builds a grid: five commands down, four places across. It fills the grid from the definitions, not from typical use. Then it adds the one question that has to be asked before choosing a row, and says which commands are on which side of it. If you can draw that grid in under two minutes, you own this module's map.

## RECAP

**[ANIMATION]** step: line.add

Let's land this. You should now be able to say:

An undo acts on four places: the working tree, the index, the current branch ref, and history. Private history may be rewritten. Shared history is corrected by adding a commit, and I fetch before I decide which it is. `git restore` copies a stored version over files or index entries, and never moves a ref. `--staged` reads HEAD and writes the index, the default reads the index and writes the working tree, and `--source` changes what is read. Every form that writes the working tree can destroy edits that no object holds.

## HOMEWORK

Read sections 11.1 to 11.3 of [Chapter 11](../../textbook/ch11-reset-revert-restore.md).

You now have the map: four places, one question, and every form of `git restore`. Practise it with a paper strip. Next time: `git reset`, the three modes, and why hard is dangerous. Until then, look at the state first and type second. See you in the next one.
