# Chapter 10: Cherry-pick

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch10/`.

## 10.1 Why this matters

Three questions a CTO can ask about a maintenance release:

1. "The fix for the empty-prompt crash was merged to `main` last week. Customers on 1.4 still crash. Is the fix in the 1.4 branch or not, and how do you prove it either way?"
2. "The backport applied without a single conflict, and the 1.4 build broke anyway. How is that possible?"
3. "When we merged the release branch back into `main`, the log showed the same commit title twice. Did something go wrong?"

The answers come from one fact. **A cherry-pick does not move or reuse a commit. It recomputes the change that a commit made and records that change as a new commit, with a new ID, on the branch you are on.** Git stores no link between the original and the copy. You can ask Git whether two commits make the same change, and you can write the link into the message yourself, but ancestry, the thing `git branch --contains` and `git merge` rely on, knows nothing about it.

The project in this chapter is `gateway`, a small service that forwards prompts to a model API. `main` is the development line; `release/1.4` is the maintenance line that customers run.

## 10.2 What cherry-pick does

**In one sentence.** 🟡 `git cherry-pick <commit>` takes the difference between a commit and its parent, merges that difference into your current branch with a three-way merge, and commits the result.

**Analogy.** A colleague edited another copy of a document with change tracking on. You do not paste their paragraph over yours; you ask what they changed, compared with what they started from, and make that change in your copy, which has drifted in the meantime. The analogy breaks at judgment. A person notices when the change refers to a definition that exists only in the other copy. Git does not: the change applies, and your document is now wrong (Lab 10.1).

**Precisely.** A cherry-pick is a three-way merge ([Chapter 8](ch08-merge.md), section 8.4) with an unusual choice of base. Call the picked commit C and its parent P:

- base: P, the parent of the picked commit
- ours: HEAD, the branch you are on
- theirs: C, the picked commit

The merge computes "what changed from P to C" and "what changed from P to HEAD" and combines the two. Whatever else exists on C's branch plays no part. This is more than applying a patch. A patch carries a few lines of context and fails when they do not match; the merge works with three complete versions of each file.

**Inside `.git`.** One new commit object, with new tree and blob objects where content is new. The current branch ref advances by one commit, and the HEAD reflog gets an entry that starts with `cherry-pick:`. `ORIG_HEAD` is not written. While a pick is stopped, the root ref `CHERRY_PICK_HEAD` names the commit being picked (section 10.6).

**See it.** Asha fixed a crash on `main`. The release branch has one commit of its own:

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

The hunk's context includes the line `MAX_RETRIES = 2`. On `release/1.4` that line says 3. As a patch, the change is refused:

<!-- snippet: ch10/pick-three-way/03-as-a-patch -->
```text
# On release/1.4 the line MAX_RETRIES = 2 reads MAX_RETRIES = 3. Try the change as a plain patch:
$ git format-patch -1 --stdout main~1 | git apply --check
error: patch failed: src/client.py:2
error: src/client.py: patch does not apply
[exit status: 1]
```
<!-- /snippet -->

Now predict the cherry-pick. `git merge-tree` (Chapter 8, section 8.17) performs a merge without touching the working tree and prints the ID of the resulting tree; give it the parent of the picked commit as the base:

<!-- snippet: ch10/pick-three-way/04-predict -->
```text
# A three-way merge with the parent of the picked commit as the base:
$ git merge-tree --write-tree --merge-base=main~2 HEAD main~1
1a4fb1358dcd46f1552e678a514c54c49e146e42
```
<!-- /snippet -->

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

The cherry-pick succeeded where the patch failed, and the tree of the new commit is `1a4fb13…`, the tree that the three-way merge predicted. The result keeps the release's `MAX_RETRIES = 3` and gains the two new lines: each side's change relative to the base, combined.

**Picture.**

```text
            6db3c0c---ca6dd48---f98ffd3---0cca736      main
           /             P         C
  93787ec
           \
            3056255---3c81466                          release/1.4 (HEAD)
             ours      new commit: tree = merge(base P; ours 3056255; theirs C), one parent
```

**State table.**

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git cherry-pick <commit>`, clean | Gains the change | Same | Stays on the branch | Advances to the new commit | New objects; one HEAD reflog entry and one branch reflog entry | unchanged | unchanged |
| The same, stopped at a conflict | Conflict markers in conflicted files | Stages 1, 2, 3 for those paths | unchanged | unchanged | `CHERRY_PICK_HEAD`, `MERGE_MSG`; for a sequence also `.git/sequencer/` | unchanged | unchanged |

**What it demands of your working tree.** The manual says the working tree must be clean. Git 2.55 is more precise than that:

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

An unstaged edit in a file the pick does not write is left alone. An unstaged edit in a file it must write, or any staged change, stops the command before it does anything, and nothing is lost in either refusal.

**In production.** The standard case is a fix that has to exist on more than one line of development: on `main` and on the release branch that customers run (section 10.9). The other everyday case is a commit made on the wrong branch: pick it onto the right one, then remove it from the wrong one ([Chapter 11](ch11-reset-revert-restore.md)).

## 10.3 The new commit and its new ID

**In one sentence.** The commit that a cherry-pick creates shares the author, the author date and the message with the original, and nothing else.

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

| Field | Original `f98ffd3` | Copy `3c81466` |
|---|---|---|
| `tree` | `1f6a01c…` | `1a4fb13…`: the release's files plus the change |
| `parent` | `ca6dd48…` on `main` | `3056255…` on `release/1.4` |
| `author` | Asha Rao, `1788755700` | identical |
| `committer` | Asha Rao, `1788755700` | Lab User, `1788756120`: whoever ran the cherry-pick, when it ran |
| message | identical | identical |

A different tree, a different parent and a different committer line give a different hash ([Chapter 6](ch06-commits.md)). Read the two objects once more and look for a field that points from the copy to the original. There is none.

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

Two commits with the same author and subject, on two branches, unrelated in the graph. The mental model "a commit is a diff" is the right one for predicting what a cherry-pick does; the model "a commit is a snapshot with parents" ([Chapter 2](ch02-mental-model.md)) is the right one for understanding what it leaves behind.

## 10.4 Options: `-x`, `-e`, `-n`, and `-m` for merges

**`-x` records where the change came from.** It appends the line `(cherry picked from commit <full ID>)` to the message. That line is the only link between copy and original that travels with the history; section 10.9 builds the backport workflow on it. The manual's advice is to use it between publicly visible branches and not for commits from a private branch, whose IDs mean nothing to anyone else.

**`-e` opens the editor on the message.** With `-x`, the line is already in the buffer:

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

The scripted editor added one paragraph and kept the rest, as you would. Delete the last line in the editor and the link is gone.

**🟡 `-n` applies the change without committing.**

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

The change is staged, and `CHERRY_PICK_HEAD` does not exist: as far as Git's state is concerned, no cherry-pick is in progress. The original message is still on offer, because Git leaves it in `.git/MERGE_MSG` and a `git commit` without `-m` proposes it. The authorship is not: the commit above has you as its author, not Asha. Use `-n` to combine several picks into one commit or to adapt a change before committing it, and restore the credit yourself: `git commit -C <original>` reuses the original's message and authorship.

**`-m <parent-number>` is required for a merge commit.** "The difference between a commit and its parent" is ambiguous when there are two parents:

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

`-m 1` says: take parent 1 as the base. The change relative to the first parent is everything the merged branch brought in, so the two commits of `feat/limits` arrive as one. Look at the last graph: the new commit is titled "Merge branch 'feat/limits'" and has a single parent. It is not a merge. For Git the commits of `feat/limits` are still unmerged here: `git branch --no-merged` lists the branch, and a real merge later would add those commits to the history next to this copy.

Other options in brief: `-s` adds a `Signed-off-by` trailer, `-S` signs the new commit, `-X <option>` passes an option to the merge machinery, and `--ff` fast-forwards instead of copying when HEAD already is the parent of the picked commit.

## 10.5 Several commits and ranges

**In one sentence.** Given several commits, cherry-pick copies them one after the other; given a range, it copies the commits of the range from oldest to newest.

**Precisely.** Commits that you list are applied in the order you list them. A range `A..B` means "reachable from B and not from A" ([gitrevisions](https://git-scm.com/docs/gitrevisions)), so A itself is not included; write `A^..B` to include it. The range notations are the subject of Lab 10.4 and [Chapter 14A](ch14a-history-investigation.md).

**See it.** The release branch is one commit behind four commits on `main`. Take the last three:

<!-- snippet: ch10/pick-sequence/01-before -->
```text
$ git log --oneline --graph --decorate --all
* c3a7a9f (main) Apply the timeout to streaming calls
* ebcee16 Retry failed generate calls
* 08f4771 Add streaming client
* 1a6b393 Move to the v2 generate endpoint
* 6db3c0c Start 1.5 development
* 93787ec (HEAD -> release/1.4) Add model client
```
<!-- /snippet -->

<!-- snippet: ch10/pick-sequence/02-range-stops -->
```text
$ git cherry-pick main~3..main
[release/1.4 e0c8403] Add streaming client
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 src/stream.py
Auto-merging src/client.py
CONFLICT (content): Merge conflict in src/client.py
error: could not apply ebcee16... Retry failed generate calls
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
```
<!-- /snippet -->

`main~3..main` is three commits; `main~3`, "Move to the v2 generate endpoint", is the excluded boundary. The first of the three was copied. The second conflicts, because it edits a line that the excluded commit had changed, and the sequence stopped there with exit status 1.

## 10.6 `CHERRY_PICK_HEAD`, the sequencer, and the four ways out

**In one sentence.** A stopped cherry-pick is described by one root ref, `CHERRY_PICK_HEAD`, and, when more than one commit was requested, by a directory `.git/sequencer/` that holds the rest of the plan.

**See it.** The state after the stop of section 10.5:

<!-- snippet: ch10/pick-sequence/03-state -->
```text
$ git log --oneline --decorate -2
e0c8403 (HEAD -> release/1.4) Add streaming client
93787ec Add model client
$ git rev-parse --short CHERRY_PICK_HEAD
ebcee16
$ ls .git/sequencer
abort-safety
head
todo
$ cat .git/sequencer/todo
pick ebcee16 Retry failed generate calls
pick c3a7a9f Apply the timeout to streaming calls
$ cat .git/sequencer/head
93787ec2cb8ce6539803c9712b5335894e6c0f8a
```
<!-- /snippet -->

`CHERRY_PICK_HEAD` is the commit that could not be applied. The instruction file in `.git/sequencer/`, the third name in the listing, holds it and everything after it; `sequencer/head` is where HEAD was before the first pick. Note what is different from a rebase (Chapter 9, section 9.4): HEAD is not detached. The branch has already moved to `e0c8403`, the copy of the first commit. A cherry-pick of a single commit creates no sequencer directory at all; `CHERRY_PICK_HEAD` and the prepared message are its whole state.

<!-- snippet: ch10/pick-sequence/04-status -->
```text
$ git status
On branch release/1.4
You are currently cherry-picking commit ebcee16.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   src/client.py

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

| Command | Effect |
|---|---|
| `git cherry-pick --continue` | Commit the staged resolution as the copy, then go on with the list |
| 🟡 `git cherry-pick --skip` | Make no copy of this commit, then go on |
| 🟡 `git cherry-pick --abort` | Return the branch, the index and the working tree to the state before the first pick |
| 🟡 `git cherry-pick --quit` | Forget the sequence; leave everything as it is now |

`--abort` goes back to `sequencer/head`, so the pick that had succeeded is undone as well:

<!-- snippet: ch10/pick-sequence/05-abort -->
```text
$ git cherry-pick --abort
$ git log --oneline --decorate -2
93787ec (HEAD -> release/1.4) Add model client
$ git status --short --branch
## release/1.4
```
<!-- /snippet -->

`--skip` drops the conflicting commit and applies the rest:

<!-- snippet: ch10/pick-sequence/06-skip -->
```text
$ git cherry-pick --skip
[release/1.4 9ad6c66] Apply the timeout to streaming calls
 Date: Mon Sep 7 10:07:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --decorate -3
9ad6c66 (HEAD -> release/1.4) Apply the timeout to streaming calls
b97b1c7 Add streaming client
93787ec Add model client
```
<!-- /snippet -->

`--quit` only deletes the bookkeeping. The completed copy stays on the branch, and the conflict stays in the index and the working tree:

<!-- snippet: ch10/pick-sequence/07-quit -->
```text
$ git cherry-pick --quit
$ git status --short --branch
## release/1.4
UU src/client.py
$ git log --oneline --decorate -2
99912f6 (HEAD -> release/1.4) Add streaming client
93787ec Add model client
$ git cherry-pick --continue
error: no cherry-pick or revert in progress
fatal: cherry-pick failed
[exit status: 128]
```
<!-- /snippet -->

And `--continue`, after a real resolution:

<!-- snippet: ch10/pick-sequence/08-continue -->
```text
# Resolve in an editor: keep the v1 endpoint and add the retries argument. Then:
$ git add src/client.py
$ git cherry-pick --continue
[release/1.4 27a23eb] Retry failed generate calls
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
[release/1.4 dd535d1] Apply the timeout to streaming calls
 Date: Mon Sep 7 10:07:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --decorate -4
dd535d1 (HEAD -> release/1.4) Apply the timeout to streaming calls
27a23eb Retry failed generate calls
19e9ae9 Add streaming client
93787ec Add model client
```
<!-- /snippet -->

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git cherry-pick --abort` | Back to the state before the sequence; resolution work is lost | Same | Stays on the branch | Moved back to `sequencer/head` | `CHERRY_PICK_HEAD` and `.git/sequencer/` removed | unchanged | unchanged |
| `git cherry-pick --quit` | unchanged | unchanged | unchanged | unchanged: completed picks stay | `CHERRY_PICK_HEAD` and `.git/sequencer/` removed | unchanged | unchanged |

**In production.** A sequence that stops in a CI job or a release script leaves a branch that is partly advanced. A script that cherry-picks must check the exit status and decide: `--abort` to return to a known state, never a blind retry. `git status` names the commit it is stuck on.

## 10.7 Conflicts

**In one sentence.** In a cherry-pick conflict, "ours" is your branch, "theirs" is the picked commit, and the base is the picked commit's parent: a version of the file that your branch may never have contained.

**See it.** One commit this time, with the conflict style set to `diff3` so that the markers show the base as well ([Chapter 8](ch08-merge.md), section 8.9):

<!-- snippet: ch10/pick-conflict/01-conflict -->
```text
$ git config get merge.conflictStyle
diff3
$ git cherry-pick -x main~1
Auto-merging src/client.py
CONFLICT (content): Merge conflict in src/client.py
error: could not apply ebcee16... Retry failed generate calls
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch10/pick-conflict/02-markers -->
```text
$ cat src/client.py
TIMEOUT_S = 30
MAX_RETRIES = 2

def call_model(prompt):
<<<<<<< HEAD
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
||||||| parent of ebcee16 (Retry failed generate calls)
    return post("/v2/generate", prompt, timeout=TIMEOUT_S)
=======
    return post("/v2/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
>>>>>>> ebcee16 (Retry failed generate calls)
```
<!-- /snippet -->

<!-- snippet: ch10/pick-conflict/03-stages -->
```text
$ git ls-files -u
100644 c1997a3b3072639101b24a264539d1ea68338ebd 1	src/client.py
100644 bf888b0fe23f1bba1fac2339cf6673748d3e3c5a 2	src/client.py
100644 e4a1d5abcb7ec04dfc8d525dc56542b6520af8d0 3	src/client.py
$ git show :1:src/client.py | tail -1
    return post("/v2/generate", prompt, timeout=TIMEOUT_S)
$ git show :2:src/client.py | tail -1
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
$ git show :3:src/client.py | tail -1
    return post("/v2/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
```
<!-- /snippet -->

Three versions of one line. Yours calls `/v1/generate`. The picked commit calls `/v2/generate` with a `retries` argument. The base, labelled `parent of ebcee16`, calls `/v2/generate` without it. That base is not the merge base of the two branches:

<!-- snippet: ch10/pick-conflict/04-where-stage-1-comes-from -->
```text
# The merge base of the two branches has the v1 line ...
$ git show $(git merge-base HEAD main~1):src/client.py | tail -1
    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
# ... but stage 1 is the parent of the picked commit, which already has v2.
$ git show main~2:src/client.py | tail -1
    return post("/v2/generate", prompt, timeout=TIMEOUT_S)
```
<!-- /snippet -->

With the base in view, the conflict reads as an instruction. The change to carry over is the difference between base and theirs: add `retries=MAX_RETRIES`. Apply that to your line, which still says `/v1/`:

<!-- snippet: ch10/pick-conflict/05-resolve -->
```text
# Resolve in an editor: the release keeps the v1 endpoint and gains the retries argument.
$ git add src/client.py
$ git cherry-pick --continue
[release/1.4 1805e42] Retry failed generate calls
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch10/pick-conflict/06-result -->
```text
$ git log -1 --format=fuller
commit 1805e42b7d53fbd067b2e155af6150dcea1e88a6
Author:     Asha Rao <asha@example.com>
AuthorDate: Mon Sep 7 10:06:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:18:00 2026 +0530

    Retry failed generate calls
    
    (cherry picked from commit ebcee168893f1604f1fcaa96b382049f9d46fd23)
$ git show --format= HEAD
diff --git a/src/client.py b/src/client.py
index bf888b0..32a510e 100644
--- a/src/client.py
+++ b/src/client.py
@@ -2,4 +2,4 @@ TIMEOUT_S = 30
 MAX_RETRIES = 2
 
 def call_model(prompt):
-    return post("/v1/generate", prompt, timeout=TIMEOUT_S)
+    return post("/v1/generate", prompt, timeout=TIMEOUT_S, retries=MAX_RETRIES)
```
<!-- /snippet -->

The copy changes one thing, the argument, as the original did. Taking "theirs" whole would also have switched the release to the v2 endpoint: an unrelated change from `main`, smuggled in through a conflict resolution (Lab 10.2). The sides are not swapped here as they are in a rebase: HEAD is your branch.

**How to finish.** Git has prepared the commit message before you resolve anything:

<!-- snippet: ch10/pick-finish/01-prepared-message -->
```text
# git cherry-pick -x main~1 has stopped with a conflict. Git has already prepared the message:
$ cat .git/MERGE_MSG
Retry failed generate calls

(cherry picked from commit ebcee168893f1604f1fcaa96b382049f9d46fd23)

# Conflicts:
#	src/client.py
$ git rev-parse --short CHERRY_PICK_HEAD
ebcee16
```
<!-- /snippet -->

`git cherry-pick --continue` commits with that message and removes the comment lines:

<!-- snippet: ch10/pick-finish/02-continue -->
```text
# The conflict is resolved and staged. First way: --continue.
$ git cherry-pick --continue
[release/1.4 3926e9d] Retry failed generate calls
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log -1 --format="author %an, committer %cn%n%n%B"
author Asha Rao, committer Lab User

Retry failed generate calls

(cherry picked from commit ebcee168893f1604f1fcaa96b382049f9d46fd23)
```
<!-- /snippet -->

A plain `git commit` also completes the pick, and the author is preserved either way because `CHERRY_PICK_HEAD` still exists. But the message suffers:

<!-- snippet: ch10/pick-finish/03-commit-no-edit -->
```text
# The same stop, resolved the same way. Second way: git commit --no-edit.
$ git commit --no-edit
[release/1.4 1682e80] Retry failed generate calls
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log -1 --format="author %an, committer %cn%n%n%B"
author Asha Rao, committer Lab User

Retry failed generate calls

(cherry picked from commit ebcee168893f1604f1fcaa96b382049f9d46fd23)

# Conflicts:
#	src/client.py
```
<!-- /snippet -->

<!-- snippet: ch10/pick-finish/04-commit-m -->
```text
# Third way: git commit with a message of your own.
$ git commit -m "Retry failed generate calls (1.4)"
[release/1.4 b5f3d00] Retry failed generate calls (1.4)
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log -1 --format="author %an, committer %cn%n%n%B"
author Asha Rao, committer Lab User

Retry failed generate calls (1.4)

$ git rev-parse --verify --quiet CHERRY_PICK_HEAD
[exit status: 1]
```
<!-- /snippet -->

`--no-edit` skips the editor and with it the cleanup that strips comment lines, so `# Conflicts:` becomes part of the message. `-m` replaces the prepared message, and the line that `-x` wrote is gone. Finish a cherry-pick with `--continue`.

One disagreement between documentation and behavior belongs here. The local manual says of `-x` that the line is added "only for cherry picks without conflicts". The transcripts above show Git 2.55.0 writing it into the prepared message of a conflicted pick, and `--continue` keeping it.

## 10.8 Changes that are already there: `--empty`

**In one sentence.** When the picked change is already present on your branch, the merge result equals HEAD, there is nothing to commit, and `--empty` decides what happens next.

<!-- snippet: ch10/pick-empty/01-stop -->
```text
# The fix is already on release/1.4. Someone picks it a second time.
$ git cherry-pick -x main~1
Auto-merging src/client.py
The previous cherry-pick is now empty, possibly due to conflict resolution.
If you wish to commit it anyway, use:

    git commit --allow-empty

Otherwise, please use 'git cherry-pick --skip'
On branch release/1.4
You are currently cherry-picking commit f98ffd3.
  (all conflicts fixed: run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

nothing to commit, working tree clean
[exit status: 1]
```
<!-- /snippet -->

The default is to stop and ask. `git cherry-pick --skip` moves on; the suggested `git commit --allow-empty` would record a commit without changes. The decision can be made in advance:

<!-- snippet: ch10/pick-empty/03-drop -->
```text
$ git cherry-pick --empty=drop main~1
Auto-merging src/client.py
dropping f98ffd3d15c63376ff2fe882f990e11ff6722de6 Reject empty prompts before calling the model -- patch contents already upstream
$ git log --oneline --decorate -2
4f88542 (HEAD -> release/1.4) Reject empty prompts before calling the model
3056255 Allow three retries on the 1.4 line
```
<!-- /snippet -->

<!-- snippet: ch10/pick-empty/04-keep -->
```text
$ git cherry-pick --empty=keep main~1
Auto-merging src/client.py
[release/1.4 a11cd35] Reject empty prompts before calling the model
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:05:00 2026 +0530
$ git show --stat --format="%h %s" HEAD
a11cd35 Reject empty prompts before calling the model
```
<!-- /snippet -->

| Option | A pick that turns out empty is |
|---|---|
| `--empty=stop` (default) | paused, for you to decide |
| `--empty=drop` | left out, with a one-line notice |
| `--empty=keep` | committed as an empty commit |
| `--keep-redundant-commits` | the older name of `--empty=keep`; deprecated |

The old name still works:

<!-- snippet: ch10/pick-empty/05-old-name -->
```text
$ git cherry-pick --keep-redundant-commits main~1
Auto-merging src/client.py
[release/1.4 6c698c5] Reject empty prompts before calling the model
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:05:00 2026 +0530
$ git log --oneline --decorate -3
6c698c5 (HEAD -> release/1.4) Reject empty prompts before calling the model
4f88542 Reject empty prompts before calling the model
3056255 Allow three retries on the 1.4 line
```
<!-- /snippet -->

`--allow-empty` is a different option: it concerns commits that were empty to begin with.

> **Version note.** Older behavior: the only control was `--keep-redundant-commits`. Current behavior: `--empty=(drop|keep|stop)`, with the old option kept as a deprecated synonym. Since: Git 2.45 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.45.0.adoc)). Recommended: `--empty=drop` in scripts that backport lists of commits, so that a commit which is already present does not halt an unattended job.

## 10.9 The backport workflow

**In one sentence.** A backport is a fix that lands on the development line first and is then copied to a maintenance line with `git cherry-pick -x`, so that the copy says where it came from.

**See it.**

<!-- snippet: ch10/backport/01-pick-x -->
```text
$ git log --oneline -3 main
0cca736 Document the streaming client
f98ffd3 Reject empty prompts before calling the model
ca6dd48 Add streaming client
$ git cherry-pick -x f98ffd3
Auto-merging src/client.py
[release/1.4 c308105] Reject empty prompts before calling the model
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
$ git log -1 --format=fuller
commit c3081051fe3d7125255eac2894828854bc2682ad
Author:     Asha Rao <asha@example.com>
AuthorDate: Mon Sep 7 10:05:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:09:00 2026 +0530

    Reject empty prompts before calling the model
    
    (cherry picked from commit f98ffd3d15c63376ff2fe882f990e11ff6722de6)
```
<!-- /snippet -->

`--format=fuller` shows both identities. Asha wrote the change at 10:05; you committed this copy at 10:09. The last line of the message is the link to the original.

Now the first question of section 10.1: is the fix in the 1.4 branch? Ask by commit ID and the answer is misleading:

<!-- snippet: ch10/backport/02-audit-by-id -->
```text
# Which branches contain the fix? Asking by commit ID finds only the original.
$ git branch --contains f98ffd3
  main
```
<!-- /snippet -->

`--contains` follows ancestry, and the original commit is not an ancestor of the release branch; its copy is. Ask for the recorded line instead:

<!-- snippet: ch10/backport/03-audit-by-trailer -->
```text
$ git log --all --oneline --grep='cherry picked from commit f98ffd3'
c308105 Reject empty prompts before calling the model
$ git branch --contains $(git log --all --format=%h --grep='cherry picked from commit f98ffd3')
* release/1.4
```
<!-- /snippet -->

That is a proof: a commit on `release/1.4` states that it is a copy of `f98ffd3`. A third way is to ask whether an equivalent change exists, by patch ID (section 10.10):

<!-- snippet: ch10/backport/04-audit-by-patch -->
```text
$ git cherry -v release/1.4 main
+ 6db3c0c6eace6d80b965fbca258fd96d13ad0e76 Start 1.5 development
+ ca6dd4819cdc3b57d478ca0a5ebc7b9c3c8c3e6c Add streaming client
+ f98ffd3d15c63376ff2fe882f990e11ff6722de6 Reject empty prompts before calling the model
+ 0cca736b9a1a5fe9a95303513732a6c623631f05 Document the streaming client
```
<!-- /snippet -->

`+` in front of the fix means "no equivalent on the release", and here that is wrong. The release differs from `main` in a line inside the hunk's context (`MAX_RETRIES = 3`), so the diff of the copy is not textually the diff of the original, and their patch IDs differ. A context line was enough. Patch comparison finds exact copies only; the `-x` line survives adaptation.

**The procedure.**

1. Merge the fix into `main` through the normal review.
2. `git switch release/1.4`, then `git cherry-pick -x <commit>`.
3. Build and test on the release branch. "Applied cleanly" says that the text merged, not that the code works there (Lab 10.1).
4. Publish the release branch the way your team publishes it: a push, or a pull request whose base is the release branch.

**Which direction?** Two conventions are in use, and a senior engineer should be able to name both. The Git project commits a fix on the oldest supported branch that needs it and merges upward, so that newer branches contain older ones and cherry-picks are the exception ([gitworkflows](https://git-scm.com/docs/gitworkflows)). Trunk-based practice fixes on the main line first and cherry-picks to the release branch, on the argument that a fix made on the release branch can be forgotten on `main` and come back as a regression ([branch for release](https://trunkbaseddevelopment.com/branch-for-release/), [Microsoft Release Flow](https://learn.microsoft.com/en-us/devops/develop/how-microsoft-develops-devops)). This chapter demonstrates the second; the mechanics are the same in both.

**In production.** For an ML service the maintenance line is often the version that a customer's evaluation was signed off against. A backport changes that line. Record it where the sign-off lives: the `-x` line gives the auditor the original commit, and the original commit leads to the review and the tests.

## 10.10 Duplicate commits and how to find them

**In one sentence.** After a cherry-pick the same change exists under two commit IDs, and `git cherry` and `git log --cherry-mark` find such pairs by comparing patch IDs.

**Precisely.** A patch ID is a hash of a commit's diff with line numbers ignored ([git-patch-id](https://git-scm.com/docs/git-patch-id)). `git cherry <upstream> <head>` lists the commits of `<head>` that are not in `<upstream>` and marks each with `-` if `<upstream>` contains a commit with the same patch ID, otherwise with `+`. `git log --left-right --cherry-mark A...B` walks both sides of the symmetric difference and marks such pairs with `=`.

**See it.** A release branch whose own commit lies outside the context of the fix, so that the copy is exact:

<!-- snippet: ch10/duplicates/01-graph -->
```text
$ git log --oneline --graph --decorate --all
* c84bed2 (HEAD -> release/1.4) Reject empty prompts before calling the model
* f395bc9 Raise the timeout to 60 seconds on the 1.4 line
| * 0cca736 (main) Document the streaming client
| * f98ffd3 Reject empty prompts before calling the model
| * ca6dd48 Add streaming client
| * 6db3c0c Start 1.5 development
|/  
* 93787ec Add model client
```
<!-- /snippet -->

<!-- snippet: ch10/duplicates/02-cherry -->
```text
$ git cherry -v release/1.4 main
+ 6db3c0c6eace6d80b965fbca258fd96d13ad0e76 Start 1.5 development
+ ca6dd4819cdc3b57d478ca0a5ebc7b9c3c8c3e6c Add streaming client
- f98ffd3d15c63376ff2fe882f990e11ff6722de6 Reject empty prompts before calling the model
+ 0cca736b9a1a5fe9a95303513732a6c623631f05 Document the streaming client
$ git cherry -v main release/1.4
+ f395bc9ef18134d47129560a98d5bc6c5d2b32ef Raise the timeout to 60 seconds on the 1.4 line
- c84bed2a3af7e44ee969c4b890987cfa6e76769e Reject empty prompts before calling the model
```
<!-- /snippet -->

<!-- snippet: ch10/duplicates/03-cherry-mark -->
```text
$ git log --oneline --left-right --cherry-mark release/1.4...main
= c84bed2 Reject empty prompts before calling the model
< f395bc9 Raise the timeout to 60 seconds on the 1.4 line
> 0cca736 Document the streaming client
= f98ffd3 Reject empty prompts before calling the model
> ca6dd48 Add streaming client
> 6db3c0c Start 1.5 development
```
<!-- /snippet -->

<!-- snippet: ch10/duplicates/04-cherry-pick -->
```text
$ git log --oneline --left-right --cherry-pick release/1.4...main
< f395bc9 Raise the timeout to 60 seconds on the 1.4 line
> 0cca736 Document the streaming client
> ca6dd48 Add streaming client
> 6db3c0c Start 1.5 development
```
<!-- /snippet -->

`<` is a commit only on the left side (the release), `>` only on the right (`main`), `=` a commit whose change also exists on the other side. `--cherry-pick` leaves the pairs out, which gives the real difference between the two lines. For "what is on `main` that the release still lacks", add `--right-only`. The evidence underneath:

<!-- snippet: ch10/duplicates/05-patch-id -->
```text
$ git show main~1 | git patch-id --stable
25663a50190a2730649d2f06cd81f82ff10a1575 f98ffd3d15c63376ff2fe882f990e11ff6722de6
$ git show release/1.4 | git patch-id --stable
25663a50190a2730649d2f06cd81f82ff10a1575 c84bed2a3af7e44ee969c4b890987cfa6e76769e
```
<!-- /snippet -->

**What happens when the two lines meet again.** Merge the release branch back into `main`:

<!-- snippet: ch10/duplicates/06-merge -->
```text
$ git switch main
Switched to branch 'main'
$ git merge -m "Merge branch release/1.4 into main" release/1.4
Auto-merging src/client.py
Merge made by the 'ort' strategy.
 src/client.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --decorate -7
*   cf36074 (HEAD -> main) Merge branch release/1.4 into main
|\  
| * c84bed2 (release/1.4) Reject empty prompts before calling the model
| * f395bc9 Raise the timeout to 60 seconds on the 1.4 line
* | 0cca736 Document the streaming client
* | f98ffd3 Reject empty prompts before calling the model
* | ca6dd48 Add streaming client
* | 6db3c0c Start 1.5 development
|/  
```
<!-- /snippet -->

<!-- snippet: ch10/duplicates/07-twice-in-history -->
```text
$ git log --oneline --grep="Reject empty prompts"
c84bed2 Reject empty prompts before calling the model
f98ffd3 Reject empty prompts before calling the model
```
<!-- /snippet -->

The merge is clean: both sides made the identical change, and identical changes do not conflict (Chapter 8, section 8.4). The history now holds the change twice, once per ID. That answers the third question of section 10.1: nothing went wrong. It becomes a problem when a copy was adapted. Then the two sides changed the same lines differently, and the merge either conflicts or, with unlucky context, combines them in a way nobody reviewed.

**In production.** Anything that counts commits double-counts duplicates: a changelog generated from `git log`, a "commits since last release" metric. Generate such lists with `--cherry-pick`, and remember its limit from section 10.9: an adapted backport is invisible to patch comparison. Lab 10.3 works through that case.

## 10.11 Revert, the inverse operation

**In one sentence.** 🟡 `git revert <commit>` is the same three-way merge with base and "theirs" exchanged: the base is the commit itself and "theirs" is its parent, so the change is applied backwards.

| | base | ours | theirs | Result |
|---|---|---|---|---|
| `git cherry-pick C` | parent of C | HEAD | C | HEAD plus the change of C |
| `git revert C` | C | HEAD | parent of C | HEAD minus the change of C |

**See it.** Predict the tree with `git merge-tree`, then revert:

<!-- snippet: ch10/revert-inverse/01-before -->
```text
$ git log --oneline --decorate -3
4f88542 (HEAD -> release/1.4) Reject empty prompts before calling the model
3056255 Allow three retries on the 1.4 line
93787ec Add model client
$ git rev-parse HEAD~1^{tree}
c0427e5100e84ffed7a94307938f8c547a0919d6
```
<!-- /snippet -->

<!-- snippet: ch10/revert-inverse/02-predict -->
```text
# Base: the commit to undo (HEAD). Ours: HEAD. Theirs: the parent of the commit to undo.
$ git merge-tree --write-tree --merge-base=HEAD HEAD HEAD~1
c0427e5100e84ffed7a94307938f8c547a0919d6
```
<!-- /snippet -->

<!-- snippet: ch10/revert-inverse/03-revert -->
```text
$ git revert --no-edit HEAD
[release/1.4 57c5a52] Revert "Reject empty prompts before calling the model"
 Date: Mon Sep 7 10:12:00 2026 +0530
 1 file changed, 2 deletions(-)
$ git rev-parse HEAD^{tree}
c0427e5100e84ffed7a94307938f8c547a0919d6
$ git log -1 --format=%B
Revert "Reject empty prompts before calling the model"

This reverts commit 4f885421c38859bdc722fa1961433160eca5ab6a.
```
<!-- /snippet -->

The predicted tree, the tree of the revert commit and the tree of the commit before the backport are one and the same, `c0427e5…`. A revert is a new commit like any other. It uses the same sequencer, with `REVERT_HEAD` in place of `CHERRY_PICK_HEAD` and the same four ways out, and it needs `-m` for a merge commit for the same reason. [Chapter 11](ch11-reset-revert-restore.md), sections 11.8 and 11.9, covers it in full, including what reverting a merge does to later merges.

## 10.12 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| "is a merge but no -m option was given" | The picked commit has two parents | `-m 1` if you want what the merge brought in; consider merging instead | Pick the commits of the branch, not the merge |
| "The previous cherry-pick is now empty" | The change is already on this branch | `git cherry-pick --skip` | `--empty=drop` in scripts; check with `git cherry` first |
| "your local changes would be overwritten" | A staged change, or an edit in a file the pick writes | Commit or stash, then pick | Start from a clean `git status` |
| A conflict in lines the fix did not seem to touch | Stage 1 is the parent of the picked commit, not your branch's past: `git show :1:<path>` | Apply the difference between stage 1 and stage 3 to your version | `merge.conflictStyle=zdiff3` |
| The backport applied cleanly and the build fails | The commit uses something added by an earlier commit you did not pick: `git log -S'<name>' main` finds it | Remove the pick; pick the prerequisite as well, or adapt the fix | Test on the target branch before pushing |
| The backport contains changes the original did not | A conflict was resolved by taking "theirs" whole: compare `git show` of both commits | Redo the pick, resolve by hand | Read the three stages (10.7) |
| The message contains `# Conflicts:` | Finished with `git commit --no-edit` | `git commit --amend` | Finish with `git cherry-pick --continue` |
| The `(cherry picked from ...)` line is missing | `-x` was not used, the line was deleted in the editor, or the pick was finished with `git commit -m` | `git commit --amend` and add the line | `-x` always for backports |
| The author is you, not the original author | `-n` followed by a plain commit | `git commit --amend -C <original>` restores author and message | Avoid `-n` for single backports |
| "The fix is not in the release", says `--contains` | Ancestry does not know about copies | Search for the `-x` line; `git cherry -v` | Teach the team section 10.9 |
| `git cherry` shows `+` for a commit that was backported | The copy was adapted, or its context differs | Search for the `-x` line | Do not rely on patch IDs alone |
| A branch is half advanced after an interrupted sequence | `git status`; `git reflog -5` | `git cherry-pick --abort`, or `git reset --hard <ID before the sequence>` | Check exit status in scripts |

## 10.13 When not to use it, and dangerous edge cases

Do not cherry-pick:

- **When you want everything a branch has.** Merge it. The local workflow manual puts the difference in one sentence: "merging works at the branch level, while cherry-picking works at the commit level", and a merge commit is a promise that everything from its parents is included ([gitworkflows](https://git-scm.com/docs/gitworkflows)). A cherry-pick promises nothing about the commits around it.
- **To move your own unpublished commits to another base.** That is a rebase with `--onto` (Chapter 9, section 9.5), which copies the commits and moves the branch in one operation.
- **As the routine way to keep two long-lived branches in step.** Duplicates accumulate, every later merge between the two has to reconcile them, and "what does A have that B lacks" stops being answerable from the graph.
- **A commit that depends on commits you are not taking.** It will apply, and it will not work.
- **A long range across lines that have diverged.** Every commit in it can conflict, each against a base your branch never had.

Edge cases:

- **`-m` on a merge** produces a single-parent commit that looks like a merge in the log (section 10.4).
- **`-n`** discards authorship and the in-progress state: `git status` no longer says that a cherry-pick is under way.
- **`-x` pointing at a private commit.** If the original lives only in your clone, or its branch is later rebased, the recorded ID refers to a commit nobody can find.
- **Signatures.** The copy is a new object. It is not signed by the original author; it is signed by you if you sign, and otherwise not at all ([Chapter 14B](ch14b-config-tags-signing.md)).
- **Review.** A backport shows the original author's name on code that was merged, and possibly edited, by someone else on another branch. Review it as new code.

## 10.14 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git cherry`, `git log --cherry-mark`, `git patch-id`, `git merge-tree --write-tree` | 🟢 SAFE | Nothing in refs, index or working tree (`merge-tree` writes objects) | not needed | not needed |
| `git cherry-pick <commit>`, with or without `-x`, `-e`, `-m` | 🟡 CAUTION | Adds commits to the current branch, which moves it, and updates index and working tree, as `git merge` does; refuses to overwrite local changes | `git show <commit>`; `git merge-tree --write-tree --merge-base=<commit>^ HEAD <commit>` | `git reset --hard <ID before>` from the reflog; `git revert` if already pushed |
| `git cherry-pick -n <commit>` | 🟡 CAUTION | Index and working tree; no commit, no in-progress state | `git show <commit>` | `git restore --staged --worktree <paths>` |
| `git cherry-pick --continue` | 🟡 CAUTION | Commits the staged resolution, which moves the branch, and goes on | `git diff --cached` | As for a pick |
| `git cherry-pick --skip` | 🟡 CAUTION | Discards the stopped pick, goes on | `git status` | Pick that commit again |
| `git cherry-pick --abort` | 🟡 CAUTION | Branch, index and working tree back to the state before the sequence | `git status` | Completed copies are in the reflog; resolution work is gone |
| `git cherry-pick --quit` | 🟡 CAUTION | Removes the sequencer state only | `git status` | Nothing to recover |
| `git revert <commit>` | 🟡 CAUTION | Adds a commit that undoes the change: the branch moves, index and working tree are updated; nothing is removed | `git show <commit>` | Revert the revert |

`git reset --hard`, named twice above as a recovery, is 🔴: it overwrites uncommitted changes in tracked files (Chapter 11).

## 10.15 Version notes

> **Version note.** Older behavior: tutorials call `CHERRY_PICK_HEAD` and `REVERT_HEAD` pseudorefs. Current behavior: the glossary reserves "pseudoref" for `FETCH_HEAD` and `MERGE_HEAD`; the others are root refs. Since: Git 2.46 ([glossary](https://github.com/git/git/blob/v2.56.0/Documentation/glossary-content.adoc)). Recommended: read them with `git rev-parse`.

- `--empty=(drop|keep|stop)` exists since Git 2.45 and soft-deprecates `--keep-redundant-commits` (section 10.8).
- That `git cherry-pick --no-commit` does not set `CHERRY_PICK_HEAD` is the behavior of Git 2.55, shown in section 10.4; the release notes of Git 2.56 record that the documentation was clarified on this point ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc)).
- `-r` is accepted and does nothing. The manual explains that `-x` used to be the default and `-r` switched it off.
- The experimental `git replay --advance=<branch>` cherry-picks a range onto a branch without a working tree ([Chapter 14D](ch14d-frontier.md)).

> **Unverified.** The release that introduced `--merge-base` for `git merge-tree`, and the release in which `-x` began to be recorded for conflicted picks (the manual still says it is not), were not found in the sources available for this chapter. Both behaviors were run on Git 2.55.0 and are shown above.

## 10.16 Practice

- Labs 10.1 to 10.3 in the [Module 10 lab manual](../lab-manual/m10-cherry-pick-ranges.md): backport a fix with `-x`; a cherry-pick conflict; detect duplicates with `git cherry`. Lab 10.4, on range notation, is in [its own file](../lab-manual/m10-range-notation.md).
- Replay any transcript with `labs/run ch10/<demo>`, for example `labs/run ch10/pick-conflict`.
- Two drills: in the sandbox of `ch10/pick-three-way`, predict the tree of `git cherry-pick main` with `git merge-tree` before you run it; in `ch10/duplicates`, where the replay has already merged the release into `main`, list what `main` had before that merge and the release lacked, with one `git log` command (the old tip is `main~1`).

## 10.17 Interview questions

1. "Cherry-pick applies a patch." What is imprecise about that sentence, and when does the difference show?
2. Name the base, "ours" and "theirs" of a cherry-pick. How does a revert differ?
3. Which fields does the copy share with the original commit, and which not? What follows for `git branch --contains`?
4. A fix was backported with `-x`. Give three ways to establish that the release branch contains it, and say which of them can give a wrong answer and why.
5. A backport applied without conflict and broke the release build. Explain the mechanism and how you would have caught it.
6. In a cherry-pick conflict, stage 1 shows a line that never existed on your branch. Where does it come from, and how do you use it to resolve correctly?
7. Compare the state after a stopped cherry-pick of a range with the state after a stopped rebase. Where is HEAD, and what has happened to the branch?
8. What does `git cherry-pick -m 1 <merge>` create, and why is it not equivalent to merging the branch?
9. Two long-lived branches exchange fixes by cherry-pick in both directions. What problems accumulate, and what would you change?
10. When do you fix on the oldest branch and merge upward, and when on `main` with a backport? Argue both.

## 10.18 Sources

**Primary sources**

- [git-cherry-pick](https://git-scm.com/docs/git-cherry-pick), [git-cherry](https://git-scm.com/docs/git-cherry), [git-patch-id](https://git-scm.com/docs/git-patch-id), [git-revert](https://git-scm.com/docs/git-revert), [gitrevisions](https://git-scm.com/docs/gitrevisions), [gitworkflows](https://git-scm.com/docs/gitworkflows), [git-commit](https://git-scm.com/docs/git-commit). The local copies (`git help -m <command>`) are the Git 2.55.0 text that the transcripts were checked against; the `--cherry-mark`, `--cherry-pick` and `--left-right` options are described in `git help -m log`.
- Release notes: [2.45.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.45.0.adoc), [2.46.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc), [2.56.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).

**Secondary sources**

- Julia Evans, [How git cherry-pick and revert use 3-way merge](https://jvns.ca/blog/2023/11/10/how-cherry-pick-and-revert-work/), the clearest short account of the base used by each.
- Derrick Stolee, [Commits are snapshots, not diffs](https://github.blog/open-source/git/commits-are-snapshots-not-diffs/) (GitHub Blog, 2020), on how cherry-pick and rebase replay changes although commits store snapshots.
- [Branch for release](https://trunkbaseddevelopment.com/branch-for-release/) on trunkbaseddevelopment.com and Microsoft's [Release Flow](https://learn.microsoft.com/en-us/devops/develop/how-microsoft-develops-devops), for the "fix on the main line, then cherry-pick" convention.
- The Phase 0 report of this course, sections 1, 4, 12 and 13.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- Tobias Günther for freeCodeCamp, ["Advanced Git Tutorial"](https://www.youtube.com/watch?v=qsTthZi23VE), 34 minutes, November 2021. Includes cherry-picking; mixes `master` and `main`.
- ProCodrr, [episode 9 on cherry-pick](https://www.youtube.com/watch?v=XmrpeP_s7p8), 8 minutes, March 2023, in Hindi. Mostly current; `master` naming.

**Further reading**

- [Chapter 9](ch09-rebase.md), where the same replay runs once per commit; [Chapter 11](ch11-reset-revert-restore.md) for revert; [Chapter 14A](ch14a-history-investigation.md) for range notation and `git log` as a query language.
