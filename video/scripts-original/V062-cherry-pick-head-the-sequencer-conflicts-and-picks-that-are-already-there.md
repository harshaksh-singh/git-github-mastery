# V062: CHERRY_PICK_HEAD, the sequencer, conflicts, and picks that are already there

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 10, Cherry-pick and ranges
- **Planned minutes:** 24
- **Prerequisites:** V033, V061
- **Textbook sections:** [Chapter 10](../../textbook/ch10-cherry-pick.md), sections 10.6, 10.7 and 10.8
- **Demo scripts:** `labs/ch10/pick-sequence.sh`, `labs/ch10/pick-conflict.sh`, `labs/ch10/pick-finish.sh`, `labs/ch10/pick-empty.sh`

## HOOK

**[ON SCREEN]** `You are currently cherry-picking commit ebcee16.`

A release script backports three fixes in one command. It runs in CI at two in the morning. The second fix conflicts. The script does not check the exit status. It goes on to tag and build.

In the morning the release branch has one of the three fixes on it, a conflict in the index, and a tag on a commit that nobody intended. An engineer opens the workspace and has to answer a simple question before touching anything: where exactly did this stop, and what has already happened to the branch?

The answer is different from the one you learned for a stopped rebase, and the difference is what makes this state dangerous.

## INTRODUCTION

In the last video every cherry-pick finished in one step. Today they stop.

A cherry-pick can stop for two reasons. A conflict, which you know how to read. Or an empty result, because the change is already on your branch.

You will look at four things. The state of a stopped pick: one root ref, and for a range, a sequencer directory. The four exits, and where the branch is after each. A conflict in detail, including a base that shows lines your branch never had. And the `--empty` option.

Throughout, keep the stopped rebase from V053 in mind. The comparison between the two is today's interview question, and one fact in it surprises people: during a stopped range pick, HEAD is on the branch, and the branch has already moved.

## LEARNING OBJECTIVES

**[ON SCREEN]** The five objectives.

After this video you can:

- Read the state of a stopped cherry-pick from `git status` and `.git`.
- Choose between `--continue`, `--skip`, `--abort` and `--quit`, and say where the branch is after each.
- Explain where stage 1 of a cherry-pick conflict comes from.
- Handle a pick that became empty with `--empty`.
- Compare a stopped range pick with a stopped rebase.

## CONCEPT

**The state.** In one sentence: a stopped cherry-pick is described by one root ref, `CHERRY_PICK_HEAD`, and, when more than one commit was requested, by a directory `.git/sequencer/` that holds the rest of the plan.

`CHERRY_PICK_HEAD` is the commit that could not be applied. In `.git/sequencer/`, the file `todo` holds that commit and everything after it, and `head` is where HEAD was before the first pick. A cherry-pick of a single commit creates no sequencer directory at all; `CHERRY_PICK_HEAD` and the prepared message are its whole state.

Now the difference from a rebase. HEAD is not detached. The picks that have already succeeded are on the branch. The branch has moved.

Think about why. A rebase builds a replacement history off to the side and switches the branch over at the end. A cherry-pick adds commits to the branch you are on, one at a time. There is no "at the end".

**The four exits.**

**[ON SCREEN]** The table of section 10.6.

```text
Command                      Effect
---------------------------  ------------------------------------------------------------------------------
git cherry-pick --continue   Commit the staged resolution as the copy, then go on with the list
git cherry-pick --skip       Make no copy of this commit, then go on
git cherry-pick --abort      Return the branch, the index and the working tree to the state before the
                             first pick
git cherry-pick --quit       Forget the sequence; leave everything as it is now
```

The textbook labels `--skip`, `--abort` and `--quit` 🟡 CAUTION. `--abort` goes back to `sequencer/head`, so picks that had succeeded are undone as well, and resolution work is lost.

**Conflicts.** In one sentence: in a cherry-pick conflict, "ours" is your branch, "theirs" is the picked commit, and the base is the picked commit's parent: a version of the file that your branch may never have contained.

Two things in that sentence. First, the sides are not swapped here as they are in a rebase: HEAD is your branch. Second, the base. It is not the merge base of the two branches. It is the parent of the picked commit, and that parent may already contain changes from its own branch that you have never had.

With the base in view, a conflict reads as an instruction: the change to carry over is the difference between base and theirs. Apply that difference to your version.

**Empty picks.** In one sentence: when the picked change is already present on your branch, the merge result equals HEAD, there is nothing to commit, and `--empty` decides what happens next.

```text
Option                       A pick that turns out empty is
---------------------------  ----------------------------------------------------
--empty=stop (default)       paused, for you to decide
--empty=drop                 left out, with a one-line notice
--empty=keep                 committed as an empty commit
--keep-redundant-commits     the older name of --empty=keep; deprecated
```

The textbook's version note: older behavior, the only control was `--keep-redundant-commits`; current behavior, since Git 2.45, `--empty=(drop|keep|stop)`. Recommended: `--empty=drop` in scripts that backport lists of commits, so that a commit which is already present does not halt an unattended job.

## MENTAL MODEL

**[ON SCREEN]** "Rebase builds beside the branch. Cherry-pick builds on the branch."

Picture two ways of laying a new stretch of track.

A rebase lays the whole new stretch next to the old line, and when the last sleeper is down, it throws one switch. Until then trains still run on the old line. If work stops halfway, the old line is untouched.

A cherry-pick of a range extends the line you are standing on, sleeper by sleeper. If work stops halfway, the line is longer than it was, and a train can already run onto the new part.

Where the picture breaks: the half-built rebase track is hard to find, since only a detached HEAD reaches it, while the half-extended cherry-pick line is in plain sight on the branch. That makes the cherry-pick state easier to see and easier to ship by accident. A tag, a build or a push at that moment takes the partial result.

## DIAGRAM

**[DIAGRAM]** New diagram. Left: a stopped range pick. Right: the stopped rebase of V053. Draw the branch label on each and circle it.

```text
  stopped range pick (cherry-pick main~3..main)         stopped rebase (git rebase main), from V053

  93787ec---e0c8403      release/1.4 (HEAD)                        X'            HEAD (detached)
              ^                                                   /
              copy of the first commit:                 A--------M               main
              ALREADY on the branch                      \
                                                          X--------Y--------Z    feat/rerank
  CHERRY_PICK_HEAD = ebcee16  (could not be applied)               ^             (branch NOT moved)
  .git/sequencer/todo: ebcee16, c3a7a9f                            REBASE_HEAD
  .git/sequencer/head: 93787ec                          (X', Y, Z: letters stand for the commits of V053)
    (where --abort returns)                             .git/rebase-merge/orig-head: Z

  HEAD: on the branch                                   HEAD: detached
  branch: advanced over finished picks                  branch: still the old tip
```

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch10/pick-sequence`. The release branch is behind four commits on `main`. Take the last three.

**Part 1: a range that stops.**

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

```bash
git cherry-pick main~3..main
```

`git cherry-pick` 🟡 CAUTION. Which commits are in that range, and in which order will they be applied?

**[PAUSE]**

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

Three commits, oldest first. `main~3`, "Move to the v2 generate endpoint", is the excluded boundary. The first of the three was copied. The second conflicts, because it edits a line that the excluded commit had changed, and the sequence stopped there with exit status 1.

Now the question from the hook. Where is HEAD, and where is the branch?

**[PAUSE]**

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

`HEAD -> release/1.4`, at `e0c8403`: the copy of the first commit. HEAD is not detached and the branch has already moved. `CHERRY_PICK_HEAD` is `ebcee16`. The sequencer's `todo` holds it and the commit after it; `head` holds `93787ec`, where HEAD was before the first pick.

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

`git status` names the commit it is stuck on and lists three of the exits.

**Part 2: the four exits.** Each from the same stopped state. Predict the top of the log after each.

<!-- snippet: ch10/pick-sequence/05-abort -->
```text
$ git cherry-pick --abort
$ git log --oneline --decorate -2
93787ec (HEAD -> release/1.4) Add model client
$ git status --short --branch
## release/1.4
```
<!-- /snippet -->

`--abort`: back at `93787ec`. The pick that had succeeded is undone as well.

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

`--skip`: the conflicting commit is dropped and the rest is applied. Two commits on the branch instead of three, and no trace of the one in between unless someone looks.

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

`--quit` only deletes the bookkeeping. The completed copy stays on the branch, and the conflict stays in the index and the working tree: `UU`. And `--continue` afterwards says "no cherry-pick or revert in progress". This is the state the two-in-the-morning script would leave if it had tried to tidy up with the wrong exit.

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

`--continue`, after a real resolution: the stopped commit is committed with Asha as author, and the last one follows.

**Part 3: a conflict in detail.** `labs/run ch10/pick-conflict`. One commit this time, with `-x`, and with the conflict style set to `diff3` so that the markers show the base as well.

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

Three versions of one line. Yours, under `HEAD`, calls `/v1/generate`. The picked commit, at the bottom, calls `/v2/generate` with a `retries` argument. The base in the middle, labelled "parent of ebcee16", calls `/v2/generate` without it.

Stop on the base. Your branch has never contained a line with `/v2/`. Where does it come from?

**[PAUSE]**

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

The merge base of the two branches has the v1 line. But stage 1 is the parent of the picked commit, `main~2`, which already has v2. That is the unusual base of a cherry-pick, visible in a file.

With the base in view, the conflict reads as an instruction. The difference between base and theirs is: add `retries=MAX_RETRIES`. Apply that to your line, which still says `/v1/`.

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

Author Asha Rao, committer Lab User, and the "cherry picked from commit" line in the message. The diff of the copy changes one thing, the argument, as the original did. Taking "theirs" whole would also have switched the release to the v2 endpoint: an unrelated change from `main`, smuggled in through a conflict resolution.

**Part 4: how to finish.** `labs/run ch10/pick-finish`. Git has prepared the commit message before you resolve anything.

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

`.git/MERGE_MSG` holds the subject, the `-x` line, and a comment block listing the conflicts. Three ways to commit. Predict the message each one produces.

**[PAUSE]**

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

`--continue` commits with that message and removes the comment lines.

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

`git commit --no-edit` skips the editor and with it the cleanup that strips comment lines, so `# Conflicts:` becomes part of the message.

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

`-m` replaces the prepared message, and the line that `-x` wrote is gone. The author is preserved in all three, because `CHERRY_PICK_HEAD` still existed. The rule: finish a cherry-pick with `--continue`.

One disagreement between documentation and behavior, which the textbook records. The local manual says of `-x` that the line is added "only for cherry picks without conflicts". The transcripts show Git 2.55.0 writing it into the prepared message of a conflicted pick, and `--continue` keeping it. The run wins.

**Part 5: empty picks.** `labs/run ch10/pick-empty`. The fix is already on `release/1.4`. Someone picks it a second time.

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

"The previous cherry-pick is now empty", exit status 1. The default is to stop and ask. `git cherry-pick --skip` moves on; the suggested `git commit --allow-empty` would record a commit without changes.

<!-- snippet: ch10/pick-empty/02-skip -->
```text
$ git cherry-pick --skip
$ git log --oneline --decorate -2
4f88542 (HEAD -> release/1.4) Reject empty prompts before calling the model
3056255 Allow three retries on the 1.4 line
```
<!-- /snippet -->

The decision can be made in advance.

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

`--empty=drop`: one line of notice, "patch contents already upstream", and no new commit.

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

`--empty=keep`: a commit with no stat lines.

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

The old name still works and gives the same result. `--allow-empty`, by the way, is a different option: it concerns commits that were empty to begin with.

## COMMON MISTAKES

**[ON SCREEN]** Each mistake with its root cause.

1. **Assuming the branch is untouched while a range pick is stopped.** Root cause: unlike a rebase, a cherry-pick commits on the branch as it goes; finished picks are already on it and HEAD is attached.
2. **Using `--quit` to get out of a stopped pick.** Root cause: it removes only the bookkeeping; the completed copies stay and the conflict stays in the index.
3. **Resolving a pick conflict by taking "theirs" whole.** Root cause: theirs is the full file from the other line, which may carry unrelated changes that the picked commit's parent already had.
4. **Finishing a pick with `git commit -m`.** Root cause: `-m` replaces the prepared message, including the line that `-x` wrote.
5. **Scripts that cherry-pick lists of commits without checking the exit status.** Root cause: a conflict or an empty pick stops the sequence with a non-zero status and a partly advanced branch.

## PRODUCTION EXAMPLE

Back to the script from the hook. The textbook's guidance is two sentences: a sequence that stops in a CI job or a release script leaves a branch that is partly advanced. A script that cherry-picks must check the exit status and decide: `--abort` to return to a known state, never a blind retry.

For the release tooling of a model-serving team, that becomes three lines of policy. One: every `git cherry-pick` in a script is followed by a check of its exit status. Two: on failure the script runs `git cherry-pick --abort` and stops, and a person takes over with `git status`, which names the commit it was stuck on. Three: lists of backports are run with `--empty=drop`, so that a fix that is already present does not halt an unattended job.

And for the person who takes over a half-finished backport by hand: read `CHERRY_PICK_HEAD`, read `.git/sequencer/todo` and `head`, and write down where the branch was before the first pick. Then choose an exit knowingly.

## PRACTICE EXERCISE

Do Lab 10.2, "A cherry-pick conflict", in [`lab-manual/m10-cherry-pick-ranges.md`](../../lab-manual/m10-cherry-pick-ranges.md).

When the pick stops, before you edit the file, write down:

- Stage 1, stage 2 and stage 3 of the conflicted line, and for each, the commit it comes from. Is stage 1 the merge base of the two branches?
- The difference between stage 1 and stage 3 in one phrase. That is the change you have to carry over.
- What the file would contain if you took stage 3 whole, and what unrelated change that would bring.

Then resolve, and finish with the right command.

The challenge is Exercise 10.9, Level 4, "a backport that stopped at its second commit", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q153: "Compare the state after a stopped cherry-pick of a range with the state after a stopped rebase. Where is HEAD, and what has happened to the branch?"

Answer aloud first. A strong answer is a comparison in parallel: for each of the two, where HEAD is, where the branch ref is, which ref names the commit being applied, and where the rest of the plan is stored. It then explains the difference from what each operation is building, so that it is a consequence and not a fact to memorize. It ends with what the difference means for the exits and for automation: what "abort" has to undo in each case, and what a script risks if it carries on.

## RECAP

You should now be able to say:

A stopped cherry-pick has `CHERRY_PICK_HEAD` for the commit being applied and, for a range, `.git/sequencer/` with the remaining picks and the starting commit. HEAD stays on the branch, and picks that already succeeded are on it. `--continue` commits and goes on, `--skip` leaves the commit out, `--abort` returns to the state before the first pick, and `--quit` leaves a partly advanced branch with the conflict in place. In a conflict, ours is my branch, theirs is the picked commit, and the base is the picked commit's parent, which may show lines my branch never had. A pick whose change is already present becomes empty, and `--empty` decides whether to stop, drop or keep it.

## HOMEWORK

Read sections 10.6 to 10.8 of [Chapter 10](../../textbook/ch10-cherry-pick.md).

Do Exercise 10.7, Level 3, ""The previous cherry-pick is now empty"", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).
