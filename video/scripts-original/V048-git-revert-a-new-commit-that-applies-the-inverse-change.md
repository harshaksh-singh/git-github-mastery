# V048: git revert: a new commit that applies the inverse change

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 8, Undoing changes
- **Planned minutes:** 20
- **Prerequisites:** V010, V047
- **Textbook sections:** [Chapter 11](../../textbook/ch11-reset-revert-restore.md), section 11.8
- **Demo scripts:** `labs/ch11/revert-basics.sh`, `labs/ch11/revert-sequence.sh`

## HOOK

**[ON SCREEN]** "A bad configuration change is on `main` and three people have already pulled it."

A change that raised a batch size was merged, deployed by CI, and now exhausts memory on the feature workers. Three teammates have pulled it. The CTO wants to know what exactly you run, and what nobody must run.

Nobody must run a reset followed by a forced push. The last two videos explained why: three clones still name that commit. What you run is one command that needs no force, takes the same route as any other commit, and reaches every clone as a normal update. And when you understand what that command computes, you can also explain the day it stops with a conflict.

## INTRODUCTION

This is the undo for shared history. In the map from two videos ago, the deciding question was private or shared, and the answer "shared" led to one rule: correct by adding. `git revert` is that rule as a command.

Today: what a revert is, as a three-way merge with unusual inputs; what it writes inside `.git`; three refusals that surprise people; how to revert a range and how to pack several reverts into one commit; why a revert of an old commit can conflict, with the three index stages as proof; and what to do when a sequence of reverts stops halfway.

Reverting a merge commit is a topic of its own and is the next video.

## LEARNING OBJECTIVES

**[ON SCREEN]** The four objectives.

After this video you can:

- Describe a revert as a three-way merge and name its base, ours and theirs.
- Revert one commit, a range, and several commits as one.
- Explain why reverting an old commit can conflict.
- Leave a stopped revert sequence in a known state.

## CONCEPT

In one sentence: `git revert <commit>` 🟡 CAUTION adds a commit whose change is the opposite of what `<commit>` changed, and removes nothing.

Why does it exist? Because a branch that other people have can only move forward without hurting them. A revert moves it forward.

Precisely. A revert is a three-way merge, the same machinery as in the merge module, with unusual inputs. The base is the commit being reverted. "Ours" is HEAD. "Theirs" is the parent of the reverted commit.

**[ON SCREEN]** base = the commit being reverted · ours = HEAD · theirs = its parent

Think it through with the rule table from the merge module. Between base and theirs, the difference is the reverted commit's change, read backwards. Between base and ours, the difference is everything that has happened since. The merge applies the backwards change to the current files, wherever the lines it touches are still as that commit left them.

Three consequences follow. Any commit in the history can be reverted, not only the last. A revert can conflict. And the result is an ordinary commit on top of HEAD, so the branch only moves forward.

Inside `.git`: one new commit, with the previous HEAD commit as its only parent and a generated message. The reflog line starts with `revert:`. `ORIG_HEAD` is not written. While a revert is stopped at a conflict, `REVERT_HEAD` names the commit being reverted and `.git/sequencer/` holds the steps still to do.

**[ON SCREEN]** The state table of section 11.8.

```text
Command                  Working tree              Index                  HEAD                 Current branch ref    Other refs and files in .git      Remote / GitHub
-----------------------  ------------------------  ---------------------  -------------------  --------------------  --------------------------------  -------------------
git revert <commit>      files touched by the      updated to the tree    file unchanged;      advanced by one       new tree and commit;              unchanged until
                         inverse change rewritten  of the new commit      resolves to the      commit                reflog line "revert:"             you push
                                                                          new commit
git revert -n <commit>   inverse change applied    inverse change staged  unchanged            unchanged             REVERT_HEAD and MERGE_MSG         unchanged
                                                                                                                     until you commit
```

When not to use it? On private history where you would rather the mistake never appeared; there a reset or an amend is cleaner. And be aware of what a revert is not: it reverses one commit, not everything since.

## MENTAL MODEL

**[ON SCREEN]** "A reversing entry in a ledger."

The textbook's analogy: a reversing entry in a ledger. A posted entry is never erased. A second entry with the opposite sign is posted, and both stay visible.

It breaks in two places. A ledger reversal always nets to zero, while a revert is computed against the files as they are now, so later changes to the same lines produce a conflict. And a revert reverses one commit, not everything since.

The first break is the important one. A revert is not "go back to how it was before that commit". It is "apply the opposite of that commit's change to today's files". If today's files have moved on in the same lines, Git has two candidates and no way to choose.

## DIAGRAM

**[DIAGRAM]** Left: four commits, `main` on the last. Right: the same four, untouched, plus one new commit. Then the caption about the tree.

```text
before                                      after git revert d51208b

6cde22d--a49e359--d51208b--73572b2          6cde22d--a49e359--d51208b--73572b2--124de33
                           main (HEAD)                                          main (HEAD)

                                            tree of 124de33 = tree of 73572b2 with the change of d51208b undone
```

Nothing on the left was removed or replaced. `d51208b` is still in the history, and so is the commit after it. The branch is one commit longer.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch11/revert-basics`. A serving configuration. `d51208b` disabled a cache. One more commit has been made since.

**Step 1: revert a commit that is not the last.**

```bash
git revert --no-edit d51208b
```

Predict the log afterwards: how many lines, and is `d51208b` among them? And predict the timeout line in `serve.yaml`.

**[PAUSE]**

<!-- snippet: ch11/revert-basics/01-revert -->
```text
$ git log --oneline
73572b2 Record baseline metrics
d51208b Disable cache
a49e359 Cut timeout to 5s
6cde22d Add serving config
$ git revert --no-edit d51208b
[main 124de33] Revert "Disable cache"
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline
124de33 Revert "Disable cache"
73572b2 Record baseline metrics
d51208b Disable cache
a49e359 Cut timeout to 5s
6cde22d Add serving config
$ cat serve.yaml
timeout_s: 5
retries: 2
cache: on
```
<!-- /snippet -->

The log grew by one commit, `124de33`, and `d51208b` is still in it. The cache is on again, and the timeout change of `a49e359` is untouched: 5 seconds.

**Step 2: inside `.git`.**

<!-- snippet: ch11/revert-basics/03-inside-git -->
```text
$ git cat-file -p HEAD
tree e9938f9d1028c2cd21aaeb07fcf0d0660529e062
parent 73572b26215e527178ad8d299a39fbe669e07869
author Lab User <you@example.com> 1788755880 +0530
committer Lab User <you@example.com> 1788755880 +0530

Revert "Disable cache"

This reverts commit d51208bb375a31b82829c887ecdfe818c7fcde5f.
$ git reflog -1
124de33 HEAD@{0}: revert: Revert "Disable cache"
```
<!-- /snippet -->

One parent, the previous HEAD. A generated message: "This reverts commit", followed by the full ID. The reflog line starts with `revert:`.

**Step 3: three refusals.** First, revert the same commit again.

<!-- snippet: ch11/revert-basics/04-already-reverted -->
```text
$ git revert --no-edit d51208b
On branch main
nothing to commit, working tree clean
[exit status: 1]
```
<!-- /snippet -->

Nothing to commit, exit status 1. Second, a habit carried over from `git commit`. Predict what `-m "some text"` does on `git revert`.

**[PAUSE]**

<!-- snippet: ch11/revert-basics/05-m-is-not-a-message -->
```text
$ git revert -m "Cache must stay on" HEAD~1
error: option `mainline' expects a number greater than zero
[exit status: 129]
```
<!-- /snippet -->

"Option `mainline` expects a number greater than zero." On `git revert`, `-m` is not a message but the parent number for reverting a merge, which is the next video. The reason for a revert goes into the editor, which `git revert` opens when it runs in a terminal.

Third, the index must match HEAD.

<!-- snippet: ch11/revert-basics/06-dirty-tree -->
```text
# An unstaged change in a file that the revert does not touch: allowed.
$ printf 'recall@10: 0.74\n' > metrics.txt
$ git revert --no-edit d51208b
[main 029666f] Revert "Disable cache"
 Date: Mon Sep 7 10:17:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status -s
 M metrics.txt
# The same change, staged: refused, because the index must match HEAD.
$ git add metrics.txt
$ git revert --no-edit a49e359
error: your local changes would be overwritten by revert.
hint: commit your changes or stash them to proceed.
fatal: revert failed
[exit status: 128]
```
<!-- /snippet -->

The manual asks for a clean working tree; Git 2.55 accepts unstaged edits in files that the revert does not touch. The same change, staged, is refused.

**Step 4: several commits.** A range `A..B` excludes `A` and is reverted newest first, one revert commit per original.

<!-- snippet: ch11/revert-basics/07-range -->
```text
$ git revert --no-edit HEAD~3..HEAD~1
[main 0978d3a] Revert "Disable cache"
 Date: Mon Sep 7 10:21:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
[main 209e7c2] Revert "Cut timeout to 5s"
 Date: Mon Sep 7 10:21:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline
209e7c2 Revert "Cut timeout to 5s"
0978d3a Revert "Disable cache"
73572b2 Record baseline metrics
d51208b Disable cache
a49e359 Cut timeout to 5s
6cde22d Add serving config
$ cat serve.yaml
timeout_s: 30
retries: 2
cache: on
```
<!-- /snippet -->

Two revert commits, the cache one first because it is the newer original. Timeout 30 again, cache on.

With `-n`, long form `--no-commit`, the inverse changes go into the index and the working tree and nothing is committed, so one commit of your own can carry them all.

<!-- snippet: ch11/revert-basics/08-no-commit -->
```text
$ git revert -n HEAD~3..HEAD~1
$ git status -s
M  serve.yaml
$ git commit -m "Revert timeout and cache changes from the latency experiment"
[main 716dfe1] Revert timeout and cache changes from the latency experiment
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git log --oneline -3
716dfe1 Revert timeout and cache changes from the latency experiment
73572b2 Record baseline metrics
d51208b Disable cache
```
<!-- /snippet -->

One commit, with a message that says what the two reverts have in common.

**Step 5: a conflict.** `a49e359` changed the timeout from 30 to 5. A later commit changed it from 5 to 8. You revert `a49e359`. Before the output: name base, ours and theirs, with the timeout value in each.

**[PAUSE]**

<!-- snippet: ch11/revert-basics/09-conflict -->
```text
$ git log --oneline
fe1b93a Tune timeout to 8s
73572b2 Record baseline metrics
d51208b Disable cache
a49e359 Cut timeout to 5s
6cde22d Add serving config
$ git revert --no-edit a49e359
Auto-merging serve.yaml
CONFLICT (content): Merge conflict in serve.yaml
error: could not revert a49e359... Cut timeout to 5s
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git revert --continue".
hint: You can instead skip this commit with "git revert --skip".
hint: To abort and get back to the state before "git revert",
hint: run "git revert --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
```
<!-- /snippet -->

Base 5, ours 8, theirs 30. Both sides changed the line relative to the base: a conflict. The revert wants to turn 5 back into 30, and the line no longer says 5.

<!-- snippet: ch11/revert-basics/10-conflict-state -->
```text
$ git status -s
UU serve.yaml
$ cat serve.yaml
<<<<<<< HEAD
timeout_s: 8
=======
timeout_s: 30
>>>>>>> parent of a49e359 (Cut timeout to 5s)
retries: 2
cache: off
$ git ls-files -s serve.yaml
100644 41e864ea1714917500825ad4d31512bfcf3210f4 1	serve.yaml
100644 a9bab3597b4e820f98072a889124e79c2228134e 2	serve.yaml
100644 6c8d072bcfd31ba25469b03c0024d6f4a5098848 3	serve.yaml
$ git rev-parse a49e359:serve.yaml HEAD:serve.yaml a49e359~1:serve.yaml
41e864ea1714917500825ad4d31512bfcf3210f4
a9bab3597b4e820f98072a889124e79c2228134e
6c8d072bcfd31ba25469b03c0024d6f4a5098848
$ git rev-parse --short REVERT_HEAD
a49e359
```
<!-- /snippet -->

Read the marker labels: `HEAD` above, and below, "parent of a49e359". Then the proof. `git ls-files -s` prints three stages, and the `git rev-parse` below it prints the blob IDs of the file in three commits, in the same order: in `a49e359` itself, in HEAD, and in the parent of `a49e359`. They match line for line. Stage 1, the base, is the commit being reverted. Stage 3 is its parent. And `REVERT_HEAD` names `a49e359`.

Git cannot know whether 8 or 30 is right today. You decide, stage the result and continue.

<!-- snippet: ch11/revert-basics/11-resolve -->
```text
$ printf 'timeout_s: 30\nretries: 2\ncache: off\n' > serve.yaml
$ git add serve.yaml
$ git revert --continue
[main 4761b40] Revert "Cut timeout to 5s"
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline -2
4761b40 Revert "Cut timeout to 5s"
fe1b93a Tune timeout to 8s
```
<!-- /snippet -->

**Step 6: a range that stops halfway.** `labs/run ch11/revert-sequence`. A two-step range; the second revert conflicts.

<!-- snippet: ch11/revert-sequence/01-stops-halfway -->
```text
$ git log --oneline
f6c769e Tune timeout to 8s
73572b2 Record baseline metrics
d51208b Disable cache
a49e359 Cut timeout to 5s
6cde22d Add serving config
$ git revert --no-edit HEAD~4..HEAD~2
Auto-merging serve.yaml
[main 407f639] Revert "Disable cache"
 Date: Mon Sep 7 10:09:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
Auto-merging serve.yaml
CONFLICT (content): Merge conflict in serve.yaml
error: could not revert a49e359... Cut timeout to 5s
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git revert --continue".
hint: You can instead skip this commit with "git revert --skip".
hint: To abort and get back to the state before "git revert",
hint: run "git revert --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch11/revert-sequence/02-sequencer-state -->
```text
$ git log --oneline -2
407f639 Revert "Disable cache"
f6c769e Tune timeout to 8s
$ git status
On branch main
You are currently reverting commit a49e359.
  (fix conflicts and run "git revert --continue")
  (use "git revert --skip" to skip this patch)
  (use "git revert --abort" to cancel the revert operation)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   serve.yaml

no changes added to commit (use "git add" and/or "git commit -a")
$ ls .git/sequencer
abort-safety
head
opts
todo
$ cat .git/sequencer/todo
revert a49e359 Cut timeout to 5s
$ git rev-parse --short REVERT_HEAD
a49e359
$ git log --oneline -1 $(cat .git/sequencer/head)
f6c769e Tune timeout to 8s
```
<!-- /snippet -->

When the second revert of a range conflicts, the first is already committed: the log shows `407f639`, a revert, on top. `git status` says "You are currently reverting commit a49e359". `.git/sequencer/` has four files: `todo` holds the steps still to do, and `head` holds the commit where the sequence started, `f6c769e`.

**[ON SCREEN]** The table of exits.

```text
Exit                     Result
-----------------------  ---------------------------------------------------------------------------
git revert --continue    After you resolve and git add: commits this step and runs the remaining ones
git revert --skip        Drops this step, keeps the reverts already made, runs the remaining ones
git revert --abort       Returns the branch to the commit recorded in .git/sequencer/head; revert
                         commits already made leave the branch
git revert --quit        Forgets the sequence; keeps the reverts already made and leaves the conflict
                         in the index and in the files
```

Predict the top of the log after `--abort`.

**[PAUSE]**

<!-- snippet: ch11/revert-sequence/03-abort -->
```text
$ git revert --abort
$ git log --oneline -2
f6c769e Tune timeout to 8s
73572b2 Record baseline metrics
$ git status -s
$ git reflog -2
f6c769e HEAD@{0}: reset: moving to f6c769e91225728dcb887fa30d34b1c1278764e5
407f639 HEAD@{1}: revert: Revert "Disable cache"
$ test -d .git/sequencer
[exit status: 1]
```
<!-- /snippet -->

Back at `f6c769e`. The revert commit that had already been made left the branch; it is still in the reflog, one line down. The abort is recorded as a reset, and the sequencer directory is gone.

From the same stopped state, `--quit`:

<!-- snippet: ch11/revert-sequence/04-quit -->
```text
$ git revert --quit
$ git log --oneline -2
407f639 Revert "Disable cache"
f6c769e Tune timeout to 8s
$ git status -s
UU serve.yaml
$ test -d .git/sequencer
[exit status: 1]
$ git rev-parse --verify --short REVERT_HEAD
fatal: Needed a single revision
[exit status: 128]
```
<!-- /snippet -->

And `--skip`:

<!-- snippet: ch11/revert-sequence/05-skip -->
```text
$ git revert --skip
$ git log --oneline -2
407f639 Revert "Disable cache"
f6c769e Tune timeout to 8s
$ git status -s
$ cat serve.yaml
timeout_s: 8
retries: 2
cache: on
```
<!-- /snippet -->

Compare each with its row of the table: what stayed on the branch, and whether a conflict is still in the index.

## COMMON MISTAKES

**[ON SCREEN]** Each mistake with its root cause.

1. **Expecting a revert of an old commit to restore the file "as it was".** Root cause: a revert merges the inverse change into today's files, with the reverted commit as base, so later edits to the same lines conflict.
2. **Typing `git revert -m "reason" <commit>`.** Root cause: on `git revert`, `-m` is the mainline parent number for reverting a merge, not a message.
3. **Thinking a range revert is atomic.** Root cause: a range produces one revert commit per original, newest first, so a stop at step two leaves step one committed.
4. **Using `--quit` to back out of a stopped sequence.** Root cause: `--quit` forgets the sequence but keeps the reverts already made and leaves the conflict in the index and the files; `--abort` is the one that returns the branch.
5. **Reverting with staged changes.** Root cause: the index must match HEAD before a revert starts.

## PRODUCTION EXAMPLE

Back to the batch size. The change was merged, deployed by CI, and exhausts memory on the feature workers. Three teammates have pulled it.

`git revert <commit>` followed by `git push` needs no force, takes the same route as any other commit, a pull request if `main` requires one, and reaches every clone as a normal update. The textbook notes that the Git FAQ names this as the usual way, and that the revert manual strongly recommends that the message explain why.

That last point is where teams save themselves a second incident. A generated message says which commit was reverted. It does not say that the workers ran out of memory at batch size 64, or under which conditions the change could come back. Six weeks later someone will want to raise the batch size again. The revert commit is where they will look.

Lab 8.2 runs this incident, including the teammate's side.

## PRACTICE EXERCISE

Do Lab 8.2, "Revert a pushed commit", in [`lab-manual/m08-undo.md`](../../lab-manual/m08-undo.md).

Predict before you type:

- Which commands tell you that the bad commit is shared, and what must you run before trusting them?
- After the revert, how many commits does `git log` show, and what does `git status -sb` say about your upstream?
- Will the push need force? What will the teammate's next pull print: a fast-forward, a merge, or a conflict?

The challenge is Exercise 8.5, Level 2, "revert a range", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q180: "Describe `git revert` as a three-way merge: what are base, ours and theirs? Use the answer to explain why reverting an old commit can conflict."

Answer aloud first. A strong answer names the three inputs without hesitation and says why that choice of base produces the inverse change. For the second half it constructs a concrete case with three values of one line, places each value in base, ours and theirs, and reads the conflict off the three-way rule. If you can also say what the conflict markers will be labelled and which index stage holds which version, you have shown that the model is operational and not recited.

## RECAP

You should now be able to say:

`git revert` adds a commit that applies the opposite of one commit's change, and removes nothing, so it is the undo for history that other people have. It is a three-way merge with the reverted commit as base, HEAD as ours and the reverted commit's parent as theirs. It conflicts when later commits changed the same lines. A range is reverted newest first, one commit per original, and `-n` lets me combine them into one. A stopped sequence has four exits: continue, skip, abort and quit, and only abort returns the branch to where the sequence started.

## HOMEWORK

Read section 11.8 of [Chapter 11](../../textbook/ch11-reset-revert-restore.md).

Do Exercise 8.2, Level 1, "revert a commit that is not the last one", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).
