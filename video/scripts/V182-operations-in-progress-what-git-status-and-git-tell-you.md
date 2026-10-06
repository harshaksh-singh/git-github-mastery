# V182: Operations in progress: what git status and .git tell you

- **Part.** 9, Production debugging and incident response
- **Module.** 35
- **Planned minutes.** 22
- **Prerequisites.** V062, V071, V181
- **Textbook sections.** [Chapter 29](../../textbook/ch29-production-troubleshooting.md), section 29.6
- **Demo scripts.** `labs/ch29/ops-in-progress.sh` (snippets `01-clean` to `14-ways-out`)

## HOOK

**[ON SCREEN]** "Git is broken. It will not let me switch branches."

A colleague's laptop is handed to you with that sentence. Nothing is broken. An earlier `git pull`, which fetches from the server and then merges, stopped at a conflict three weeks ago and was left. A conflict is a place where Git can't decide between two changes. Since then the repository has been in the middle of a merge, through reboots and a holiday, and every refusal Git printed was a correct statement about that state. Keep the laptop's sentence in mind. Later you'll watch Git print the refusal behind it.

The diagnosis is one `git status`, or one listing of the `.git` directory, where Git keeps the repository. The decision that follows isn't automatic, and that is where people do damage: continue, abort, or anchor and then abort are three different outcomes for the work that was done inside the operation.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In video 180 the root cause was an unfinished rebase, and you read it from a directory. Today you generalize: five operations can stop half-way, merge, rebase, cherry-pick, revert and bisect, and each leaves a signature.

A merge joins two lines of history. A rebase copies commits onto a new base. A cherry-pick copies one commit's change onto the current branch. A revert adds a commit that undoes an earlier one. And a bisect searches the history for the commit that changed something.

You've seen each of them individually: the sequencer in video 62, bisect in video 71. This video puts them side by side so that you can take over a repository that somebody else left in the middle of something and say within seconds which operation it is, where it started, and what remains.

The format is a quiz. For each operation I show you the listing of `.git` first. You name the operation. Then we look at what `git status` says about it.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Tell from `.git` alone whether a merge, a rebase, a cherry-pick, a revert or a bisect is in progress.
2. Say for each which refs and files exist and where HEAD is.
3. Name the ways out of each operation and what each leaves behind.
4. Explain what commands refuse to run in each state and why.
5. Take over a repository that somebody else left in the middle of something.

## CONCEPT

**In one sentence.** Merge, rebase, cherry-pick, revert and bisect can stop half-way, and each leaves named files in `.git` that say which operation it is, where it started, and what remains.

**Precisely.** Git has no process that "is" a rebase. An operation in progress is nothing but files: a pseudoref such as `MERGE_HEAD` that holds a commit ID, and for multi-step operations a directory with a todo list. `git status` reads those files and prints its first lines from them.

Three consequences follow, and each one matters in an incident.

A stopped operation survives a reboot and can be weeks old.

Deleting the files by hand ends the operation without undoing it.

And you can diagnose a repository you were handed by listing `.git`.

**The signatures.**

Merge: `MERGE_HEAD` is the commit being merged in. It becomes the second parent. `MERGE_MSG` is the prepared message. `ORIG_HEAD` is the tip before the merge. `AUTO_MERGE` is a tree with the conflict markers as Git wrote them. HEAD, Git's note of where you are, is still attached to the branch.

Rebase: a directory, `rebase-merge`, or `rebase-apply` for the older apply backend, with the same role. HEAD is a raw commit ID. `REBASE_HEAD` is the commit whose replay stopped. Inside the directory, `head-name` is the branch that will be moved at the end, `orig-head` its tip at the start, `onto` the new base, `msgnum` and `end` the position, and `git-rebase-todo` the remaining picks.

Cherry-pick: `CHERRY_PICK_HEAD` is the commit being applied. HEAD stays on the branch. A `sequencer` directory exists when several commits were requested: `head` is where the branch was before the first pick, and `todo` lists the current pick first and then those not yet applied. A cherry-pick of a single commit has no `sequencer` directory.

Revert: `REVERT_HEAD` is the commit being undone. The rest is the same machinery as cherry-pick with the roles of base and "theirs" exchanged.

Bisect: `BISECT_START` is the branch to return to, `BISECT_LOG` the replayable record, `BISECT_TERMS` the two words in use, and the marks are refs under `refs/bisect/`. HEAD is detached on the commit under test. A bisect has no conflict and a clean working tree, which is why it's the operation most often forgotten.

Two files aren't signatures. `ORIG_HEAD` and `FETCH_HEAD` are records of past commands, not of an operation in progress.

**The exits.** Each operation has up to three kinds of exit. Continue. Leave and restore the starting point. Or leave and keep the current state.

Every "leave and restore" command resets the index, which is the proposed next commit, and the working tree, the files you edit, for tracked files. So uncommitted edits made during the operation are lost. Section 29.6 marks them all 🟡. The chapter's command safety table, section 29.14, is stricter about one of them, and this video follows the table: `git merge --abort` is 🔴 DANGEROUS, because it destroys every resolution made so far and edits staged during the merge, and the manual warns that uncommitted changes present when the merge started can't always be reconstructed. `git rebase --abort`, `git cherry-pick --abort`, `git revert --abort` and `git bisect reset` are 🟡 CAUTION.

**When not to reach for an exit.** The decision isn't automatic. Continue, if the operation was intended and the resolution is known. Abort, if nothing done inside it matters. Anchor and then abort, as in video 180, if commits were made inside it. To anchor is to give those commits a branch name. Ask what was intended before choosing.

## MENTAL MODEL

A picture helps. The textbook's analogy is a surgeon's instrument count: the list on the wall says what is still inside the patient. You don't close until the count is right, and anyone who walks into the room can read the list.

The analogy breaks because Git's list is also the undo record. The same files that describe the operation are what `--abort` reads to restore the starting point. Delete the list by hand, and you haven't finished the operation or undone it. You've made it impossible to do either with Git's help.

So hold two questions for any repository you're handed. First: which state files exist? That names the operation. Second: is HEAD a branch name or a raw commit ID? That tells you where new commits would go.

## DIAGRAM

Quick quiz before the table. Two of the five operations detach HEAD, so that a new commit lands on no branch. Which two? A, merge and rebase. B, rebase and bisect. C, cherry-pick and revert. Your answer?

**[PAUSE]**

**[DIAGRAM]** A new table, built row by row during the demo: one row per operation, with the file or directory that proves it, where HEAD is, and the exits. It is the textbook's table of section 29.6.

| Operation | First lines of `git status` | State in `.git` | HEAD | Continue | Leave and restore | Leave and keep the current state |
|---|---|---|---|---|---|---|
| Merge | "You have unmerged paths" or "All conflicts fixed but you are still merging" | `MERGE_HEAD`, `MERGE_MODE`, `MERGE_MSG`, `AUTO_MERGE` | on the branch | `git commit` or `git merge --continue` | `git merge --abort` | `git merge --quit` |
| Rebase | "interactive rebase in progress; onto ..." or "rebase in progress" | `rebase-merge/` or `rebase-apply/`, `REBASE_HEAD` | detached | `git rebase --continue` | `git rebase --abort` | `git rebase --quit` |
| Cherry-pick | "You are currently cherry-picking commit ..." | `CHERRY_PICK_HEAD`; `sequencer/` for several commits | on the branch | `git cherry-pick --continue` | `git cherry-pick --abort` | `git cherry-pick --quit` |
| Revert | "You are currently reverting commit ..." | `REVERT_HEAD`; `sequencer/` for several commits | on the branch | `git revert --continue` | `git revert --abort` | `git revert --quit` |
| Bisect | "You are currently bisecting, started from branch ..." | `BISECT_LOG`, `BISECT_START`, `BISECT_TERMS`, `refs/bisect/*` | detached | `git bisect good` or `bad` | `git bisect reset` | `git bisect reset HEAD` |

B. Point at the HEAD column when the table is complete: two operations detach HEAD, rebase and bisect. Those are the two in which a commit made "on the branch" isn't on the branch.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch29/ops-in-progress`. The script builds the same small repository six times, an output guard for an LLM service, and stops a different operation in five of them. Everything until the last two steps is 🟢 SAFE.

**The reference: a repository at rest.**

```bash
cd clean
git log --graph --oneline --all
git status
ls .git
cat .git/HEAD
```

<!-- snippet: ch29/ops-in-progress/01-clean -->
```text
$ cd clean
$ git log --graph --oneline --all
* 9f0e328 Add README
* 19b52fd Raise guard threshold to 0.65
| * 6f503d0 Lower max_tokens to 128
| * 7c39cc7 Add blocklist
| * 5c28c34 Raise guard threshold to 0.80
|/  
* e432e9d Count tokens, not characters
* b039fd7 Add output guard
$ git status
On branch main
nothing to commit, working tree clean
$ ls .git
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
objects
refs
$ cat .git/HEAD
ref: refs/heads/main
```
<!-- /snippet -->

Memorize this listing. `.git/HEAD` contains `ref: refs/heads/main`. Any file in capitals that isn't in this listing is a sign of activity.

Try it now. Thirty seconds. In the lab shell, or in any repository you have, run `ls .git`, which only reads. Is there a name in capitals that this listing lacks? Say it out loud.

**[PAUSE]**

If you found `ORIG_HEAD` or `FETCH_HEAD`, those two are records of past commands. Any other new name is worth holding on to, because the next five listings tell you what it means.

**Repository two. Files first.** Look at the listing and name the operation before I show the status.

```bash
ls .git
cat .git/MERGE_HEAD
cat .git/MERGE_MSG
cat .git/ORIG_HEAD
git ls-files -u
```

<!-- snippet: ch29/ops-in-progress/03-merge-files -->
```text
$ ls .git
AUTO_MERGE
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
MERGE_HEAD
MERGE_MODE
MERGE_MSG
objects
ORIG_HEAD
refs
$ cat .git/MERGE_HEAD
a469d78723e151187e6d8cefe905e898fa0e1495
$ cat .git/MERGE_MODE
$ cat .git/MERGE_MSG
Merge branch 'feature/strict-guard'

# Conflicts:
#	guard.yaml
$ cat .git/ORIG_HEAD
3e2ce98834b9eccea6b02a664d0dfc63c75e0e4b
$ git ls-files -u
100644 248eaf478810ec8dbbcac312051603ba86b05f30 1	guard.yaml
100644 ea5b34d7cbddccfdf80d8ac18aa35c90353b7249 2	guard.yaml
100644 07eef246dd9ec18304b69ded66e99c7edf039bf0 3	guard.yaml
```
<!-- /snippet -->

Which operation is it? Say it out loud.

**[PAUSE]**

`MERGE_HEAD`. A merge. The message file names the branch being merged and lists the conflict. `git ls-files -u` shows three stages for `guard.yaml`: base, ours, theirs. Now the status.

<!-- snippet: ch29/ops-in-progress/02-merge-status -->
```text
$ cd ../merging
$ git status
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Changes to be committed:
	new file:   blocklist.py

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml
```
<!-- /snippet -->

`git status` doesn't print the word "merging". It says "You have unmerged paths" and offers `git merge --abort`. After the last conflict is staged, the text becomes "All conflicts fixed but you are still merging". The first line says "On branch main": HEAD is attached.

**Repository three.** Name it from the files. Predict what `.git/HEAD` contains.

```bash
ls .git
cat .git/HEAD
cat .git/REBASE_HEAD
cat .git/rebase-merge/head-name
cat .git/rebase-merge/onto
cat .git/rebase-merge/orig-head
cat .git/rebase-merge/msgnum .git/rebase-merge/end
cat .git/rebase-merge/git-rebase-todo
```

<!-- snippet: ch29/ops-in-progress/05-rebase-files -->
```text
$ ls .git
AUTO_MERGE
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
MERGE_MSG
objects
ORIG_HEAD
REBASE_HEAD
rebase-merge
refs
$ cat .git/HEAD
65032d66238b96ad4cde8f0540fa079fdc81db17
$ cat .git/REBASE_HEAD
93eab48d915310771a87dde80923ef6b9dac5f19
$ cat .git/rebase-merge/head-name
refs/heads/feature/strict-guard
$ cat .git/rebase-merge/onto
65032d66238b96ad4cde8f0540fa079fdc81db17
$ cat .git/rebase-merge/orig-head
7aaefa26c2cece48f6e468ddf7c5487f381121ca
$ cat .git/rebase-merge/msgnum .git/rebase-merge/end
1
3
$ cat .git/rebase-merge/git-rebase-todo
pick bbb4ee363e9d43a807c1ef1409e1f503f0904373 # Add blocklist
pick 7aaefa26c2cece48f6e468ddf7c5487f381121ca # Lower max_tokens to 128
```
<!-- /snippet -->

The directory `rebase-merge`: a rebase. HEAD is a raw commit ID, and it equals `onto`. Position 1 of 3. Two picks remain in the todo file. And `head-name` tells you which branch will move when it ends.

<!-- snippet: ch29/ops-in-progress/04-rebase-status -->
```text
$ cd ../rebasing
$ git status
interactive rebase in progress; onto 65032d6
Last command done (1 command done):
   pick 93eab48 # Raise guard threshold to 0.80
Next commands to do (2 remaining commands):
   pick bbb4ee3 # Add blocklist
   pick 7aaefa2 # Lower max_tokens to 128
  (use "git rebase --edit-todo" to view and edit)
You are currently rebasing branch 'feature/strict-guard' on '65032d6'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

The status prints all of that in words, with the three exits: continue, skip, abort.

**Repository four.**

```bash
ls .git
cat .git/CHERRY_PICK_HEAD
ls .git/sequencer
cat .git/sequencer/head
cat .git/sequencer/todo
```

<!-- snippet: ch29/ops-in-progress/07-pick-files -->
```text
$ ls .git
AUTO_MERGE
CHERRY_PICK_HEAD
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
MERGE_MSG
objects
refs
sequencer
$ cat .git/CHERRY_PICK_HEAD
a19fbd43d80f8f8214d7c1ba1bcd2b486660a821
$ ls .git/sequencer
abort-safety
head
todo
$ cat .git/sequencer/head
a2ba40c745eeaae544b12a748b049ae496e1a449
$ cat .git/sequencer/todo
pick a19fbd4 Raise guard threshold to 0.80
pick f559020 Add blocklist
pick c036209 Lower max_tokens to 128
```
<!-- /snippet -->

`CHERRY_PICK_HEAD` and a `sequencer` directory: a cherry-pick of several commits. The todo lists the current pick first, then the two not yet applied.

<!-- snippet: ch29/ops-in-progress/06-pick-status -->
```text
$ cd ../picking
$ git status
On branch main
You are currently cherry-picking commit a19fbd4.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

"On branch main", and "You are currently cherry-picking commit `a19fbd4`".

**Repository five.** This listing differs from the previous one in one name.

```bash
ls .git
cat .git/REVERT_HEAD
cat .git/MERGE_MSG
```

<!-- snippet: ch29/ops-in-progress/09-revert-files -->
```text
$ ls .git
AUTO_MERGE
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
MERGE_MSG
objects
refs
REVERT_HEAD
$ cat .git/REVERT_HEAD
e3f95f738e757958ffb420c74a4472a591051e58
$ cat .git/MERGE_MSG
Revert "Raise guard threshold to 0.80"

This reverts commit e3f95f738e757958ffb420c74a4472a591051e58.

# Conflicts:
#	guard.yaml
```
<!-- /snippet -->

`REVERT_HEAD`: a revert, of one commit, so no `sequencer` directory. The prepared message already says which commit is being reverted.

<!-- snippet: ch29/ops-in-progress/08-revert-status -->
```text
$ cd ../reverting
$ git status
On branch feature/strict-guard
You are currently reverting commit e3f95f7.
  (fix conflicts and run "git revert --continue")
  (use "git revert --skip" to skip this patch)
  (use "git revert --abort" to cancel the revert operation)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

**Repository six.** No conflict files here. Predict the state of the working tree.

```bash
ls .git
cat .git/HEAD
cat .git/BISECT_START
cat .git/BISECT_TERMS
cat .git/BISECT_LOG
git for-each-ref refs/bisect
```

<!-- snippet: ch29/ops-in-progress/11-bisect-files -->
```text
$ ls .git
BISECT_ANCESTORS_OK
BISECT_EXPECTED_REV
BISECT_LOG
BISECT_NAMES
BISECT_START
BISECT_TERMS
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
objects
refs
$ cat .git/HEAD
71a6bc165b04d0be0ad6f1c8310d5d37693a39f9
$ cat .git/BISECT_START
feature/strict-guard
$ cat .git/BISECT_TERMS
bad
good
$ cat .git/BISECT_LOG
# bad: [6ed2fda3394fb715dd93eb1690d7cd51e05deac7] Lower max_tokens to 128
# good: [307506a4f8bc8b31589e49db034dd1b16728206f] Add output guard
git bisect start 'HEAD' 'main~3'
# good: [3164fc1d8b8dbf03fed13bfa4deccd261c8fd254] Raise guard threshold to 0.80
git bisect good 3164fc1d8b8dbf03fed13bfa4deccd261c8fd254
$ git for-each-ref refs/bisect
6ed2fda3394fb715dd93eb1690d7cd51e05deac7 commit	refs/bisect/bad
307506a4f8bc8b31589e49db034dd1b16728206f commit	refs/bisect/good-307506a4f8bc8b31589e49db034dd1b16728206f
3164fc1d8b8dbf03fed13bfa4deccd261c8fd254 commit	refs/bisect/good-3164fc1d8b8dbf03fed13bfa4deccd261c8fd254
```
<!-- /snippet -->

Six files that begin with `BISECT`. HEAD is a raw commit ID. `BISECT_START` names the branch to go back to. The log is a replayable record, and the marks are refs under `refs/bisect/`: one bad, two good.

<!-- snippet: ch29/ops-in-progress/10-bisect-status -->
```text
$ cd ../bisecting
$ git status
HEAD detached at 71a6bc1
You are currently bisecting, started from branch 'feature/strict-guard'.
  (use "git bisect reset" to get back to the original branch)

nothing to commit, working tree clean
```
<!-- /snippet -->

"HEAD detached", "You are currently bisecting", and "nothing to commit, working tree clean". Nothing looks wrong, and a commit made now would be on no branch.

**One question for six repositories.**

```bash
for d in clean merging rebasing picking reverting bisecting; do echo "== $d"; ls ../$d/.git | grep -E "_HEAD$|rebase-|sequencer|BISECT_LOG"; done
```

<!-- snippet: ch29/ops-in-progress/12-one-question -->
```text
# One read-only question for any repository: which state files exist?
$ for d in clean merging rebasing picking reverting bisecting; do echo "== $d"; ls ../$d/.git | grep -E "_HEAD$|rebase-|sequencer|BISECT_LOG"; done
== clean
== merging
MERGE_HEAD
ORIG_HEAD
== rebasing
ORIG_HEAD
REBASE_HEAD
rebase-merge
== picking
CHERRY_PICK_HEAD
sequencer
== reverting
REVERT_HEAD
== bisecting
BISECT_LOG
```
<!-- /snippet -->

One read-only line, and each repository names its own state. Note `ORIG_HEAD` in two of them: a record of a past command, not a signature.

**What Git refuses while an operation is open.** These refusals are often the reported symptom. Predict the message for a `git switch` during the merge. Say it out loud.

**[PAUSE]**

```bash
cd ../merging
git switch feature/strict-guard
git cherry-pick feature/strict-guard~1
git merge feature/strict-guard
cd ../rebasing
git rebase main
```

<!-- snippet: ch29/ops-in-progress/13-refusals -->
```text
$ cd ../merging
$ git switch feature/strict-guard
fatal: cannot switch branch while merging
Consider "git merge --quit" or "git worktree add".
[exit status: 128]
$ git cherry-pick feature/strict-guard~1
error: Cherry-picking is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: cherry-pick failed
[exit status: 128]
$ git merge feature/strict-guard
error: Merging is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
[exit status: 128]
$ cd ../rebasing
$ git rebase main
fatal: It seems that there is already a rebase-merge directory, and
I wonder if you are in the middle of another rebase.  If that is the
case, please try
	git rebase (--continue | --abort | --skip)
If that is not the case, please
	rm -fr ".git/rebase-merge"
and run me again.  I am stopping in case you still have something
valuable there.

[exit status: 128]
```
<!-- /snippet -->

"Cannot switch branch while merging": the sentence from the hook, and there's the refusal behind the laptop's "Git is broken". Each refusal protects the unfinished state. Read the last message with care. It proposes `rm -fr ".git/rebase-merge"`. That deletes the record of where the branch was and what remains to be replayed. It's appropriate only when you have confirmed that no rebase is wanted and have anchored HEAD first. `git rebase --quit` does the same with Git's own bookkeeping.

**The ways out.** First the one with the red label. 🔴 DANGEROUS: `git merge --abort`. The five answers. What it changes: it ends the merge and resets the index and the working tree to HEAD. What it can destroy: every resolution made so far and edits staged during the merge. And uncommitted changes that were present when the merge started can't always be reconstructed. Preview: `git status` and `git diff --cached --stat`. Recovery: staged content through `git fsck --lost-found`. For unstaged resolution edits, none. When appropriate: when the merge was a mistake and the preserve step is done.

🟡 CAUTION for the other four: `git rebase --abort`, `git cherry-pick --abort`, `git revert --abort` and `git bisect reset` end the operation and reset the index and the working tree to the starting commit. Commits made inside a rebase leave the branch. Preview with `git status`, `git diff` and `git log <branch>..HEAD`. All five are run here because these sandboxes hold nothing that was done inside the operation.

```bash
cd ../merging && git merge --abort && git status -sb && ls .git | grep -c MERGE
cd ../rebasing && git rebase --abort && git status -sb
cd ../picking && git cherry-pick --abort && git status -sb
cd ../reverting && git revert --abort && git status -sb
cd ../bisecting && git bisect reset && git status -sb
```

<!-- snippet: ch29/ops-in-progress/14-ways-out -->
```text
$ cd ../merging && git merge --abort && git status -sb && ls .git | grep -c MERGE
## main
0
$ cd ../rebasing && git rebase --abort && git status -sb
## feature/strict-guard
$ cd ../picking && git cherry-pick --abort && git status -sb
## main
$ cd ../reverting && git revert --abort && git status -sb
## feature/strict-guard
$ cd ../bisecting && git bisect reset && git status -sb
Previous HEAD position was 71a6bc1 Add blocklist
Switched to branch 'feature/strict-guard'
## feature/strict-guard
```
<!-- /snippet -->

Each repository is back on a branch, and the count of `MERGE` files is zero. The rebase returned to `feature/strict-guard`, the branch that `head-name` named. The bisect returned to the branch in `BISECT_START`.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Concluding that "Git is broken" from a refusal.** Root cause: the refusal is a correct statement about state files that an earlier, forgotten command left behind.
2. **Committing during a rebase or a bisect and expecting the branch to have the commit.** Root cause: HEAD is detached in both operations, so the new commit extends HEAD and no branch.
3. **Deleting the state files by hand.** Root cause: the files are both the description of the operation and its undo record, so removing them ends the operation without undoing it.
4. **Aborting without looking for work done inside the operation.** Root cause: every "leave and restore" exit resets the index and the working tree, and commits made on a detached HEAD lose their anchor.
5. **Treating `ORIG_HEAD` as a sign of an open operation.** Root cause: it records where a past command started, and stays after the command has finished.

## PRODUCTION EXAMPLE

Now, out of the lab. A data engineer goes on leave and hands her laptop's project directory to a colleague with one line: the pipeline repository won't let her switch to the release branch. The colleague doesn't run a single command that changes anything for the first minutes.

He lists `.git`: `BISECT_LOG` and its companions. `git status` confirms it: bisecting, started from a feature branch, working tree clean. He reads `BISECT_LOG` and sees that she was two steps from the answer when she stopped. The reflog, Git's local record of where HEAD has been, shows one commit made after the bisect began, on the detached HEAD. That commit is the one thing in this repository that an exit could lose.

He gives it a branch name first. Then he messages her with a precise question, not "can I reset it?", but: "you were bisecting from this branch; I have saved the commit you made on top; do you want the bisect finished, or may I end it?" She had forgotten the bisect entirely. He ends it with `git bisect reset`, checks the first line of `git status`, and switches to the release branch.

## PRACTICE EXERCISE

Your turn. Do Lab 35.2, "Five operations in progress, read from `.git` alone", in [`lab-manual/m35-diagnosis-method.md`](../../lab-manual/m35-diagnosis-method.md).

The rule of the lab is in its title: for each case, name the operation from the listing of `.git` before you run `git status`. Then predict, in writing, where HEAD is, which branch will be affected by each exit, and what each exit would discard. Only then leave the operation. The lab's questions are answered in a separate file. Attempt them first.

The challenge is Exercise 6.9, Level 4, "a merge that somebody else left half done", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q397: "Without running `git status`, how do you tell from the `.git` directory whether a merge, a rebase, a cherry-pick, a revert or a bisect is in progress? Name the files."

**[PAUSE]**

Answer aloud, without the table in front of you. A strong answer goes through the five operations in a fixed order and gives each its proving file or directory, including the two forms a rebase can take and the condition under which a cherry-pick or revert has a second directory. It adds where HEAD is in each case, because that's what an interviewer asks next. It names the files that look like signatures and aren't. And it closes the loop: what `git status` does with the same files, and why deleting them isn't an exit.

## RECAP

Let's land this.

- An operation in progress is nothing but files in `.git`; `git status` prints its first lines from them.
- `MERGE_HEAD`, `rebase-merge/` or `rebase-apply/`, `CHERRY_PICK_HEAD`, `REVERT_HEAD` and `BISECT_LOG` are the five signatures; `ORIG_HEAD` and `FETCH_HEAD` are not.
- HEAD is detached during a rebase and a bisect, and attached during a merge, a cherry-pick and a revert.
- Every operation has a continue exit, a restore exit and a keep exit; the restore exits discard uncommitted edits.
- Before choosing an exit, find out what was intended and anchor anything that was committed inside the operation.

## HOMEWORK

Read section 29.6. Then copy the table of this video by hand, from memory, and check it against the section. The next video is about the second phase of the method: preserving evidence before you act, and what GitHub records that Git doesn't.

You can now take a repository that somebody left in the middle of something, and name the operation from its files before you touch it. Practise that in the lab, files first. Until then, look at the state first and type second. See you in the next one.
