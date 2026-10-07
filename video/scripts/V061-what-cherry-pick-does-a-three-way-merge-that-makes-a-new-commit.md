# V061: What cherry-pick does: a three-way merge that makes a new commit

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 10, Cherry-pick and ranges
- **Planned minutes:** 24
- **Prerequisites:** V031, V052
- **Textbook sections:** [Chapter 10](../../textbook/ch10-cherry-pick.md), sections 10.2, 10.3, 10.4 and 10.5 (hook from section 10.1)
- **Demo scripts:** `labs/ch10/pick-three-way.sh`, `labs/ch10/pick-dirty.sh`, `labs/ch10/pick-options.sh`, `labs/ch10/pick-merge.sh`

## HOOK

**[ON SCREEN]** "The fix for the empty-prompt crash was merged to `main` last week. Customers on 1.4 still crash. Is the fix in the 1.4 branch or not, and how do you prove it either way?"

That's a CTO's question about a maintenance release. Someone on the team says "I cherry-picked it, it's there." Someone else runs `git branch --contains` with the ID of the fix, and the release branch is not in the list.

Both statements can be true at the same time. To see how, you need to know one thing about cherry-pick that the name hides: nothing is picked up and carried over. A change is recomputed, and a new commit is written. Git keeps no link between the two. Keep both statements in mind. They come back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video starts the module on cherry-pick. You have, in fact, been using it for eight videos: every step of a rebase is a cherry-pick. Today you look at the operation on its own.

The textbook's statement of the central fact: a cherry-pick does not move or reuse a commit. It recomputes the change that a commit made and records that change as a new commit, with a new ID, on the branch you are on. Git stores no link between the original and the copy. A commit, remember, is one saved snapshot of the project, and a branch is a name that points at one commit.

So there are two things to learn. How the change is recomputed: as a three-way merge, which combines two versions against a common base, and with a base you might not expect. And what the new commit shares with the original: less than you would think.

Then the options. `-x` writes the missing link into the message. Then `-e`, `-n`, and `-m`, without which a merge commit can't be picked. And last, the order in which several commits or a range are applied.

The project is `gateway`, a small service that forwards prompts to a model API. `main` is the development line, and `release/1.4` is the maintenance line that customers run.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The five objectives.

After this video you can:

- Name the base, ours and theirs of a cherry-pick.
- Explain why the copy has a new ID, and which fields it shares with the original.
- Use `-x`, `-e`, `-n` and, for a merge commit, `-m`.
- Pick several commits and a range, and state the order in which they are applied.
- Explain why "cherry-pick applies a patch" is imprecise.

## CONCEPT

In one sentence: `git cherry-pick <commit>` 🟡 CAUTION takes the difference between a commit and its parent, merges that difference into your current branch with a three-way merge, and commits the result.

**[ANIMATION]** graph: 93787ec-6db3c0c-ca6dd48-f98ffd3-0cca736 main; 93787ec-3056255 release/1.4; HEAD=release/1.4; role:ca6dd48:P; role:f98ffd3:C; title:A_cherry-pick_onto_release/1.4 => + drop:P,C; role:ca6dd48:base_P; role:3056255:ours; role:f98ffd3:theirs_C; name:roles => + 3056255-3c81466 release/1.4; say:The_new_commit_has_one_parent,_and_no_link_to_C; name:picked dy=180 dx=310 id=pick

**[ANIMATION]** step: state-1

Precisely. A cherry-pick is a three-way merge with an unusual choice of base. Call the picked commit C and its parent P. On screen, C is `f98ffd3` on `main`, P is `ca6dd48`, one step before it, and HEAD, where you are, is `release/1.4`.

**[ON SCREEN]** base: P, the parent of the picked commit · ours: HEAD · theirs: C, the picked commit

**[ANIMATION]** step: picked

The merge computes "what changed from P to C" and "what changed from P to HEAD" and combines the two. Whatever else exists on C's branch plays no part.

**[ANIMATION]** walk: columns=operation,base,ours,theirs rows=revert:the_commit:HEAD:its_parent|cherry-pick:the_parent:HEAD:the_commit marks=1.2:hl,1.4:hl,2.2:hl,2.4:hl mono=off title=Same_machinery,_inputs_swapped

Compare with the revert from the undo module, the commit that undoes another commit. There the base was the commit itself and theirs was its parent. A cherry-pick is the mirror image: base is the parent, theirs is the commit. Same machinery, inputs swapped.

**[ANIMATION]** walk: columns=what,works_with,if_the_context_differs rows=a_patch:a_diff_with_a_few_lines_of_context:fails|a_cherry-pick:three_complete_versions_of_each_file:can_still_merge marks=1.3:bad,2.3:ok mono=off title=Why_"it_applies_a_patch"_is_imprecise

Why is "it applies a patch" imprecise? A patch is a change written out as a diff. It carries a few lines of context and fails when they don't match. The merge works with three complete versions of each file. You'll see a change that is refused as a patch and succeeds as a cherry-pick.

**[ANIMATION]** stores: boxes=objects:.git/objects|*refs_and_logs:.git rows=1:A:one_new_commit|1:A:new_trees_and_blobs,_where_content_is_new|2:B:the_current_branch:_one_commit_ahead|3:B:HEAD_reflog:_"cherry-pick:_..."|4:B:ORIG__HEAD:_not_written@dim|5:B:CHERRY__PICK__HEAD:_only_while_stopped@ref title=What_a_cherry-pick_writes

Inside `.git`: one new commit object, with new tree and blob objects where content is new. The current branch ref advances by one commit, and the HEAD reflog, the local list of where HEAD has been, gets an entry that starts with `cherry-pick:`. `ORIG_HEAD` is not written. While a pick is stopped, the root ref `CHERRY_PICK_HEAD` names the commit being picked. That's the next video.

**[ANIMATION]** objects: cards=commit:f98ffd3:tree_1f6a01c+parent_ca6dd48+author_Asha_Rao_1788755700+committer_Asha_Rao_1788755700+Reject_empty_prompts_...,commit:3c81466:tree_1a4fb13+parent_3056255+author_Asha_Rao_1788755700+committer_Lab_User_1788756120+Reject_empty_prompts_... title=The_original_and_the_copy id=fields

**The new commit.** It shares the author, the author date and the message with the original, and nothing else. A different tree, a different parent and a different committer line, the line for whoever created this commit object, give a different hash. And no field points from the copy to the original.

**The options.**

`-x` records where the change came from: it appends the line "(cherry picked from commit", the full ID, to the message. That line is the only link between copy and original that travels with the history. The manual's advice is to use it between publicly visible branches and not for commits from a private branch, whose IDs mean nothing to anyone else.

`-e` opens the editor on the message.

`-n` 🟡 applies the change without committing.

`-m <parent-number>` is required for a merge commit, because "the difference between a commit and its parent" is ambiguous when there are two parents.

Others in brief, from the textbook: `-s` adds a `Signed-off-by` trailer, `-S` signs the new commit, `-X` passes an option to the merge machinery, and `--ff` fast-forwards instead of copying when HEAD already is the parent of the picked commit.

**[ANIMATION]** graph: *0-A-*1-B; HEAD=none; range:*1,B:A..B; say:A..B:_reachable_from_B_and_not_from_A => + range:A,*1,B:A^..B; say:A^..B_includes_A id=range

**Several commits and ranges.** Given several commits, cherry-pick copies them one after the other. Given a range, it copies the commits of the range from oldest to newest. Commits that you list are applied in the order you list them. A range `A..B` means "reachable from B and not from A", so A itself is not included. Write `A^..B` to include it.

**[ANIMATION]** end

When not to cherry-pick? When a merge would do. A pick creates a second commit for the same change, and the module's third video is about what that costs.

## MENTAL MODEL

**[ON SCREEN]** "Not 'paste their paragraph'. 'Make their change in my copy.'"

The textbook's analogy: a colleague edited another copy of a document with change tracking on. You don't paste their paragraph over yours. You ask what they changed, compared with what they started from, and make that change in your copy, which has drifted in the meantime.

It breaks at judgment. A person notices when the change refers to a definition that exists only in the other copy. Git does not: the change applies, and your document is now wrong. That's the second of the CTO's questions in this chapter, "the backport applied without a single conflict, and the build broke anyway". A backport is a fix copied from the development line to a maintenance line. And this is the semantic conflict from the merge module in a new costume.

**[ANIMATION]** step: pick.picked

The textbook also gives you a rule for which model of a commit to use when. "A commit is a diff" is the right model for predicting what a cherry-pick does. "A commit is a snapshot with parents" is the right model for understanding what it leaves behind. On screen is what it leaves behind: two commits, and no line between them.

## DIAGRAM

**[DIAGRAM]** Draw `main` with its four commits and mark P and C. Draw the release branch with its one commit, marked "ours". Then add the new commit on the release branch, with one parent, and write the formula for its tree.

```text
            6db3c0c---ca6dd48---f98ffd3---0cca736      main
           /             P         C
  93787ec
           \
            3056255---3c81466                          release/1.4 (HEAD)
             ours      new commit: tree = merge(base P; ours 3056255; theirs C), one parent
```

No line connects `f98ffd3` and `3c81466`. That missing line is the subject of the opening question.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch10/pick-three-way`.

**Step 1: before.** Asha fixed a crash on `main`. The release branch has one commit of its own.

<!-- snippet: ch10/pick-three-way/01-before -->
```text
$ git log --graph --decorate --all --format="%h %an: %s%d"
* 3056255 Lab User: Allow three retries on the 1.4 line (HEAD -> release/1.4)
| * 0cca736 Lab User: Document the streaming client (main)
| * f98ffd3 Asha Rao: Reject empty prompts before calling the model
| * ca6dd48 Lab User: Add streaming client
| * 6db3c0c Lab User: Start 1.5 development
|/  
* 93787ec Lab User: Add model client
```
<!-- /snippet -->

The fix is `f98ffd3`, by Asha Rao. Its parent is `ca6dd48`. The release branch is at `3056255`, "Allow three retries on the 1.4 line".

<!-- snippet: ch10/pick-three-way/02-the-change -->
```text
$ git show --format="%h %s" main~1
f98ffd3 Reject empty prompts before calling the model

diff --git a/src/client.py b/src/client.py
index bf888b0..d2b1af9 100644
--- a/src/client.py
+++ b/src/client.py
@@ -2,4 +2,6 @@ TIMEOUT_S = 30
 MAX_RETRIES = 2
 
 def call_model(prompt):
+    if not prompt.strip():
+        raise ValueError("empty prompt")
     return post("/v1/generate", prompt, timeout=TIMEOUT_S)
```
<!-- /snippet -->

Two added lines. Look at the context of the hunk, the block of changed lines with its surroundings: it includes the line `MAX_RETRIES = 2`. On `release/1.4` that line says 3. Try the change as a plain patch.

<!-- snippet: ch10/pick-three-way/03-as-a-patch -->
```text
# On release/1.4 the line MAX_RETRIES = 2 reads MAX_RETRIES = 3. Try the change as a plain patch:
$ git format-patch -1 --stdout main~1 | git apply --check
error: patch failed: src/client.py:2
error: src/client.py: patch does not apply
[exit status: 1]
```
<!-- /snippet -->

"Patch does not apply." The context doesn't match.

**Step 2: predict the pick.** `git merge-tree`, from the merge module, performs a merge without touching the working tree and prints the ID of the resulting tree. Give it the parent of the picked commit as the base.

<!-- snippet: ch10/pick-three-way/04-predict -->
```text
# A three-way merge with the parent of the picked commit as the base:
$ git merge-tree --write-tree --merge-base=main~2 HEAD main~1
1a4fb1358dcd46f1552e678a514c54c49e146e42
```
<!-- /snippet -->

A tree ID beginning `1a4fb13`. Now your prediction. Base, ours, theirs for the `MAX_RETRIES` line: 2, 3, 2. Which row of the three-way table is that, and what will the result say? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch10/pick-three-way/05-pick -->
```text
$ git cherry-pick main~1
Auto-merging src/client.py
[release/1.4 3c81466] Reject empty prompts before calling the model
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
$ git rev-parse HEAD^{tree}
1a4fb1358dcd46f1552e678a514c54c49e146e42
$ cat src/client.py
TIMEOUT_S = 30
MAX_RETRIES = 3

def call_model(prompt):
    if not prompt.strip():
        raise ValueError("empty prompt")
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
```
<!-- /snippet -->

"Only ours changed it": the result keeps 3. The cherry-pick succeeded where the patch failed, and `git rev-parse HEAD^{tree}` prints the same tree ID that the three-way merge predicted.

**[ANIMATION]** walk: columns=in_src/client.py,base_(P),ours_(HEAD),theirs_(C),result rows=MAX__RETRIES:2:3:2:3|the_two_new_lines:-:-:added:added marks=1.3:hl,1.5:ok,2.4:hl,2.5:ok last=result title=Each_side's_change_relative_to_the_base

The file keeps the release's `MAX_RETRIES = 3` and gains the two new lines: each side's change relative to the base, combined.

**[ANIMATION]** end

Note the line "Author: Asha Rao" in the output. Git prints it because the author differs from the committer, you.

**Step 3: the two objects.**

<!-- snippet: ch10/pick-three-way/06-objects -->
```text
# The original commit on main ...
$ git cat-file -p main~1
tree 1f6a01cb332c8e3fe47c6a154f79b3cbb046ee11
parent ca6dd4819cdc3b57d478ca0a5ebc7b9c3c8c3e6c
author Asha Rao <asha@example.com> 1788755700 +0530
committer Asha Rao <asha@example.com> 1788755700 +0530

Reject empty prompts before calling the model
# ... and the commit that the cherry-pick created.
$ git cat-file -p HEAD
tree 1a4fb1358dcd46f1552e678a514c54c49e146e42
parent 3056255676479f09f344885216ba2f1c8ac61aa1
author Asha Rao <asha@example.com> 1788755700 +0530
committer Lab User <you@example.com> 1788756120 +0530

Reject empty prompts before calling the model
```
<!-- /snippet -->

**[ON SCREEN]** The field table of section 10.3.

```text
Field       Original f98ffd3            Copy 3c81466
---------   -------------------------   ------------------------------------------------------------
tree        1f6a01c...                  1a4fb13...: the release's files plus the change
parent      ca6dd48... on main          3056255... on release/1.4
author      Asha Rao, 1788755700        identical
committer   Asha Rao, 1788755700        Lab User, 1788756120: whoever ran the cherry-pick, when it ran
message     identical                   identical
```

Read the two objects once more and look for a field that points from the copy to the original. There is none.

<!-- snippet: ch10/pick-three-way/07-after -->
```text
$ git log --graph --decorate --all --format="%h %an: %s%d"
* 3c81466 Asha Rao: Reject empty prompts before calling the model (HEAD -> release/1.4)
* 3056255 Lab User: Allow three retries on the 1.4 line
| * 0cca736 Lab User: Document the streaming client (main)
| * f98ffd3 Asha Rao: Reject empty prompts before calling the model
| * ca6dd48 Lab User: Add streaming client
| * 6db3c0c Lab User: Start 1.5 development
|/  
* 93787ec Lab User: Add model client
$ git reflog -1
3c81466 HEAD@{0}: cherry-pick: Reject empty prompts before calling the model
```
<!-- /snippet -->

The reflog entry starts with `cherry-pick:`.

**[ANIMATION]** step: pick.picked

And in the graph: two commits with the same author and subject, on two branches, unrelated. So both statements from the opening are true. The fix is there, and `--contains` can't see it.

**Step 4: what it demands of your working tree.** `labs/run ch10/pick-dirty`. The manual says the working tree must be clean. Git 2.55 is more precise than that. Three cases. An unstaged edit in a file the pick doesn't touch. An unstaged edit in the file it changes. And a staged change in an untouched file. Try it now, on paper. Thirty seconds: for each, write "goes through" or "refused".

**[PAUSE]**

<!-- snippet: ch10/pick-dirty/01-unrelated-edit -->
```text
# An uncommitted edit in VERSION. The picked commit changes only src/client.py.
$ git status --short
 M VERSION
$ git cherry-pick main~1
Auto-merging src/client.py
[release/1.4 62a5848] Reject empty prompts before calling the model
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
$ git status --short
 M VERSION
```
<!-- /snippet -->

Case one goes through: an unstaged edit in a file the pick does not write is left alone.

<!-- snippet: ch10/pick-dirty/02-edit-in-the-way -->
```text
# Now the uncommitted edit is in the file that the picked commit changes.
$ git status --short
 M src/client.py
$ git cherry-pick main~1
error: Your local changes to the following files would be overwritten by merge:
	src/client.py
Please commit your changes or stash them before you merge.
Aborting
fatal: cherry-pick failed
[exit status: 128]
$ git status --short
 M src/client.py
```
<!-- /snippet -->

Case two is refused: an unstaged edit in a file it must write stops the command.

<!-- snippet: ch10/pick-dirty/03-staged-change -->
```text
# A staged change, in a file the picked commit does not touch.
$ git add VERSION
$ git cherry-pick main~1
error: your local changes would be overwritten by cherry-pick.
hint: commit your changes or stash them to proceed.
fatal: cherry-pick failed
[exit status: 128]
$ git status --short
M  VERSION
```
<!-- /snippet -->

Case three is refused too: any staged change stops it, even in a file the pick doesn't touch.

**[ANIMATION]** walk: columns=uncommitted_change,where,the_pick rows=unstaged:a_file_the_pick_does_not_write:goes_through|unstaged:the_file_it_changes:refused|staged:any_file:refused marks=1.3:ok,2.3:bad,3.3:bad mono=off title=What_a_pick_demands_of_your_working_tree

Most people miss that one. In both refusals the command stops before it does anything, and nothing is lost.

**Step 5: `-e` and `-x`.** `labs/run ch10/pick-options`. In this replay a scripted editor shows the message as Git opened it and as it was saved.

<!-- snippet: ch10/pick-options/01-edit -->
```text
$ git cherry-pick -e -x main~1
Auto-merging src/client.py
--- message as Git opened it (comment lines removed) ---
Reject empty prompts before calling the model

(cherry picked from commit f98ffd3d15c63376ff2fe882f990e11ff6722de6)
--- message as saved ---
Reject empty prompts before calling the model

Backported to 1.4 because customers on 1.4.0 hit the error path.

(cherry picked from commit f98ffd3d15c63376ff2fe882f990e11ff6722de6)
[release/1.4 26424e6] Reject empty prompts before calling the model
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
$ git log -1 --format=%B
Reject empty prompts before calling the model

Backported to 1.4 because customers on 1.4.0 hit the error path.

(cherry picked from commit f98ffd3d15c63376ff2fe882f990e11ff6722de6)
```
<!-- /snippet -->

With `-x`, the line "(cherry picked from commit f98ffd3..." is already in the buffer when the editor opens. The scripted editor added one paragraph, the reason for the backport, and kept the rest, as you would. Delete the last line in the editor and the link is gone.

**Step 6: `-n`.** Quick quiz, two options. Who is the author of the resulting commit? Option one: Asha, as before. Option two: you. Say it out loud.

**[PAUSE]**

<!-- snippet: ch10/pick-options/02-no-commit -->
```text
$ git cherry-pick -n main~1
Auto-merging src/client.py
$ git status --short
M  src/client.py
$ git rev-parse --verify --quiet CHERRY_PICK_HEAD
[exit status: 1]
```
<!-- /snippet -->

The change is staged, and `CHERRY_PICK_HEAD` does not exist: as far as Git's state is concerned, no cherry-pick is in progress.

<!-- snippet: ch10/pick-options/03-no-commit-author -->
```text
$ git commit -m "Reject empty prompts (1.4 variant)"
[release/1.4 0a6f5fa] Reject empty prompts (1.4 variant)
 1 file changed, 2 insertions(+)
$ git log -1 --format="author %an, committer %cn"
author Lab User, committer Lab User
$ git log -1 --format="author %an, committer %cn" main~1
author Asha Rao, committer Asha Rao
```
<!-- /snippet -->

Option two. Author: Lab User. Not Asha. The original message is still on offer, because Git leaves it in `.git/MERGE_MSG` and a `git commit` without `-m` proposes it. The authorship is not. Use `-n` to combine several picks into one commit or to adapt a change before committing it, and restore the credit yourself: `git commit -C <original>` reuses the original's message and authorship.

**Step 7: a merge commit.** `labs/run ch10/pick-merge`.

<!-- snippet: ch10/pick-merge/01-before -->
```text
$ git log --oneline --graph --decorate --all
*   598b598 (main) Merge branch 'feat/limits'
|\  
| * 308a7ab (feat/limits) Allow short bursts above the rate limit
| * ad79f94 Add a per-minute rate limit
* | ad39bb6 Add README
|/  
* 6db3c0c Start 1.5 development
* 93787ec (HEAD -> release/1.4) Add model client
```
<!-- /snippet -->

<!-- snippet: ch10/pick-merge/02-refused -->
```text
$ git cherry-pick main
error: commit 598b5987e817298dd14cfa3d7bb7d31c2ff315a4 is a merge but no -m option was given.
fatal: cherry-pick failed
[exit status: 128]
```
<!-- /snippet -->

"Is a merge but no -m option was given." The same refusal as for reverting a merge, for the same reason.

<!-- snippet: ch10/pick-merge/03-mainline -->
```text
$ git cherry-pick -m 1 -x main
[release/1.4 ba59152] Merge branch 'feat/limits'
 Date: Mon Sep 7 10:07:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 src/limits.py
$ git show --stat --format="%h %s%n%b" HEAD
ba59152 Merge branch 'feat/limits'
(cherry picked from commit 598b5987e817298dd14cfa3d7bb7d31c2ff315a4)


 src/limits.py | 2 ++
 1 file changed, 2 insertions(+)
$ git log --oneline --graph --decorate release/1.4
* ba59152 (HEAD -> release/1.4) Merge branch 'feat/limits'
* 93787ec Add model client
```
<!-- /snippet -->

`-m 1` says: take parent 1 as the base. The change relative to the first parent is everything the merged branch brought in, so the two commits of `feat/limits` arrive as one.

**[ANIMATION]** graph: 93787ec-6db3c0c-ad39bb6-598b598 main; 6db3c0c-ad79f94-308a7ab feat/limits; 308a7ab-598b598; 93787ec release/1.4; HEAD=release/1.4 => + ^93787ec-ba59152 release/1.4; note:ba59152:one_parent:_not_a_merge; name:single title=Picking_a_merge_commit_with_-m_1 id=m1

**[ANIMATION]** step: single

Now look at the graph. The new commit is titled "Merge branch 'feat/limits'" and has a single parent. It's not a merge. For Git the commits of `feat/limits` are still unmerged here: `git branch --no-merged` lists the branch, and a real merge later would add those commits to the history next to this copy.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Proving a backport with `git branch --contains <original ID>`.** Root cause: the copy is a new commit with a new ID and no link to the original; ancestry knows nothing about it.
2. **Picking without `-x` between public branches.** Root cause: no field of the commit object points to the original, so the message line is the only link that travels with the history.
3. **Using `-n` and committing with `-m`.** Root cause: with `-n` no cherry-pick is in progress, so the commit gets you as author; `git commit -C <original>` restores message and authorship.
4. **Believing that `-m 1` on a merge commit merges the branch.** Root cause: the result has one parent, so the branch's commits are still unmerged and a later real merge adds them next to the copy.
5. **Expecting `A..B` to include A.** Root cause: the range is "reachable from B and not from A"; `A^..B` includes it.

## PRODUCTION EXAMPLE

Now, out of the lab. The standard case, from the textbook: a fix that has to exist on more than one line of development, on `main` and on the release branch that customers run. An inference gateway is exactly such a product. Customers pin a version, and `main` has moved on to the next API.

The second everyday case is a commit made on the wrong branch: pick it onto the right one, then remove it from the wrong one, with the tools of the undo module.

**[ANIMATION]** step: pick.picked

**[ANIMATION]** say: A clean pick is a new snapshot that nobody has run

And the warning that goes with both. A clean cherry-pick is a new snapshot that nobody has run. The fix on `main` may call a helper that was introduced two commits earlier on `main` and does not exist on the release line. The pick applies. The release is broken. Git has compared text in three versions of the files the commit touched, and nothing else. Run the release branch's tests after every pick, as you would after any merge.

## PRACTICE EXERCISE

Your turn. Do Exercise 10.1, Level 1, "one commit, copied to another branch", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Predict in writing before the pick:

- The three inputs: which commit is the base, which is ours, which is theirs.
- For a line that differs between the two branches near the change: its value in base, ours and theirs, and in the result.
- Of the five fields of the new commit object, which will equal the original's?

After the pick, check the third prediction with `git cat-file -p` on both commits.

The challenge is Exercise 10.8, Level 3, "a clean pick that does not work", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q144: "Why does cherry-pick create a new commit?"

**[PAUSE]**

Answer out loud first. It's a short question, and a strong answer is not short. It starts from what a commit ID is computed from and goes through the fields, saying which are bound to differ on another branch. It explains how the content of the new commit is computed, with the three inputs named. And it draws the consequence that matters in practice: what Git can and cannot tell you afterwards about the relationship between the two commits, and what you can do at the moment of the pick to leave a trace.

## RECAP

**[ANIMATION]** replay: pick

Let's land this. You should now be able to say, in your own words:

A cherry-pick is a three-way merge with the picked commit's parent as base, HEAD as ours and the picked commit as theirs. It works on whole files, which is why it succeeds where a patch's context would not match. The result is a new commit that keeps the author, author date and message and has a new tree, parent and committer, so its ID is new and no field links it to the original.

**[ANIMATION]** replay: range

`-x` writes that link into the message. `-n` stages without committing and loses the authorship. `-m` chooses the base parent for a merge commit, and the result is still a single-parent commit. A range is applied oldest first and excludes its left end.

## HOMEWORK

Read sections 10.1 to 10.5 of [Chapter 10](../../textbook/ch10-cherry-pick.md).

Do Exercise 10.3, Level 1, "two commits picked as one", and Exercise 10.5, Level 2, "which commits does a range pick?", both in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Today you took cherry-pick apart: three inputs, one new commit, and no link unless you write one. Do Exercise 10.1 before the next video, and write your three inputs down first. Next time: `CHERRY_PICK_HEAD`, the sequencer, conflicts, and picks that are already there. Until then, look at the state first and type second. See you in the next one.
