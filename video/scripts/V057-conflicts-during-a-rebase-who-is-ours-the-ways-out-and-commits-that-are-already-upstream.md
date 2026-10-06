# V057: Conflicts during a rebase: who is "ours", the ways out, and commits that are already upstream

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 9, Rebase
- **Planned minutes:** 26
- **Prerequisites:** V033, V056
- **Textbook sections:** [Chapter 9](../../textbook/ch09-rebase.md), sections 9.11 and 9.12
- **Demo scripts:** `labs/ch09/rebase-conflict.sh`, `labs/ch09/conflict-inspect.sh`, `labs/ch09/conflict-traps.sh`, `labs/ch09/conflict-exits.sh`, `labs/ch09/upstream-picked.sh`, `labs/ch09/upstream-squashed.sh`

## HOOK

**[ON SCREEN]** "A developer says the rebase finished without an error and one of his commits is not in the branch any more. Is that possible?"

That was the fourth of the CTO's questions at the start of this module, and the answer was "yes".

Here's how it happens. A rebase copies your commits, your saved snapshots, onto a new starting point, and this one stops at a conflict: Git can't decide a file's content. The developer wants his own version of the file. He types the option that says "ours", because the change is his. He stages the file, continues, and Git prints "Successfully rebased". No error, no warning. His commit is gone from the branch.

He did nothing careless. He trusted a word. Today you'll learn what that word means during a rebase, and why Git stayed silent. Keep that silence in mind. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A rebase replays your commits one at a time, and each replay is a three-way merge: two versions combined against their common base. So each replay can conflict. The merge module showed how to read a conflict: markers in the file, and three stages in the index, the file that holds your proposed next commit.

What changes in a rebase is who is who. The two sides are swapped compared with a merge, and almost half of the developers asked in one poll didn't know it. So you're in good company. That swap is the first half of today.

The second half is the mirror image. Sometimes a commit disappears from a rebased branch on purpose, because the new base already contains its change. Git notices that in two different ways, and you can predict both. When you can tell the intended disappearance from the accidental one, you can trust a rebase again.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The five objectives.

After this video you can:

- Name the base, ours and theirs of each step of a rebase, and explain why the sides appear swapped.
- Inspect the commit being applied and resolve its conflict.
- Describe two ways a rebase conflict loses work without any error.
- Choose between `--continue`, `--skip`, `--abort` and `--quit`.
- Predict which commits a rebase drops because the upstream already has the change.

## CONCEPT

**[ANIMATION]** graph: 8afc6bd-439e4c6 main; 8afc6bd-5ee19f0-569e6c9-ad106e3 feat/rerank; HEAD=feat/rerank; title:A_rebase,_stopped_at_its_second_commit => 439e4c6-1c9f69a; 439e4c6 main; 8afc6bd-5ee19f0-569e6c9-ad106e3 feat/rerank; 569e6c9 REBASE_HEAD; HEAD=1c9f69a => + role:1c9f69a:ours; role:569e6c9:theirs; role:5ee19f0:base; name:roles id=who

**[ANIMATION]** step: state-1

In one sentence: during a rebase, "ours" is the new base plus the copies made so far, and "theirs" is your own commit, the one being replayed: the opposite of what the words suggest.

**[ANIMATION]** step: roles

Precisely. Each replay is a three-way merge into HEAD, Git's name for where you are. Stage 2, "ours", is HEAD: the upstream commit plus what has been replayed. Stage 3, "theirs", is `REBASE_HEAD`, your commit. Stage 1 is the parent of your commit. The local manual says it in one line: "the sides are swapped".

Why? Recall the four steps of a rebase. Step 2 detached HEAD at the upstream, the tip of `main`. From then on, HEAD is the upstream's history growing by your copies. On screen, one copy is made, and the rebase has stopped at your second commit. "Ours" always means HEAD. It never meant "mine".

**[ON SCREEN]** The comparison table of section 9.11.

```text
                                               git merge main, run on your branch     git rebase main, run on your branch
---------------------------------------------  -------------------------------------  ----------------------------------------
<<<<<<< HEAD, stage 2, --ours, -X ours         your branch                            main plus your commits replayed so far
>>>>>>>, stage 3, --theirs, -X theirs          main                                   your commit being replayed
Stage 1, the base                              the merge base of the two branches     the parent of your commit
How often it can stop                          once                                   once per replayed commit
```

The ways out of a stop:

```text
Command                          Effect
-------------------------------  ---------------------------------------------------------------------------
git rebase --continue            Commit the staged resolution as the copy and go on
git rebase --skip                Make no copy of this commit and go on
git rebase --abort               Put branch, index and working tree back as they were before the rebase
git rebase --quit                Forget the rebase and leave HEAD, index and working tree as they are now
git rebase --show-current-patch  Show the commit being replayed; the same as git show REBASE_HEAD
```

The textbook labels the first four 🟡 CAUTION and the last 🟢 SAFE. Remember from video 53 that `--abort` also discards resolution work in progress.

**[ANIMATION]** graph: 8afc6bd-3b687c6-b0d0bef-b0f4913 main; 3b687c6-2c4fb0f-3667d58-cb69662 feat/ingest; HEAD=feat/ingest; title:One_change,_two_commits => + same:3667d58; same:b0f4913; say:The_same_patch_ID => 8afc6bd-3b687c6-b0d0bef-b0f4913 main; b0f4913-b0b024d-a329fe1 feat/ingest; 3b687c6-2c4fb0f-3667d58-cb69662; HEAD=feat/ingest; reflog:2c4fb0f,3667d58,cb69662; same:3667d58; same:b0f4913; title:Two_commits_replayed,_one_skipped; say:warning:_skipped_previously_applied_commit_3667d58 id=picked

**[ANIMATION]** step: state-1

Now section 9.12. In one sentence: a rebase leaves out commits whose change the new base already contains, and it notices in two different ways: before replaying, by patch ID, and after replaying, by an empty result. A patch ID is a hash of a change's diff: same change, same patch ID, whatever the commit ID.

**[ANIMATION]** step: picked.state-2

The first mechanism compares patch IDs before the list is written. A commit with an equivalent upstream never gets a `pick` line. On screen that's `3667d58`, the same change as `b0f4913` on `main`. The second mechanism is governed by `--empty`. A replay that changes nothing is dropped by default. `keep` records an empty commit. `stop` pauses so that you decide. With `-i` the default is `stop`.

**[ANIMATION]** end

And here's why Git was silent in the opening story. A replay with an empty result normally means the change is already upstream, which is the common and harmless case. Git can't tell that case from "the developer resolved the conflict by throwing his side away".

## MENTAL MODEL

**[ON SCREEN]** "'Ours' is a position, not a person. It is whatever HEAD is."

The textbook's analogy: a rebase checks out the other side's latest commit and then merges your commits into it, one at a time. In each of those merges the house belongs to the other side, and your commit is the visitor.

**[ANIMATION]** step: who.roles

**[ANIMATION]** say: "Ours" is a position: whatever HEAD is

The analogy is almost literal. It breaks only if you think of "ours" as a person. It's a position: whatever HEAD is.

**[ANIMATION]** end

A practical rule follows, and it doesn't need the words at all. Read the label after the closing marker. In a rebase conflict, the lower half is labelled with the ID and subject of a commit. That commit is yours. The upper half says `HEAD`. That's where you're being replayed onto.

## DIAGRAM

**[ANIMATION]** graph: [git merge main] 8afc6bd-5ee19f0-569e6c9-ad106e3 feat/rerank; 8afc6bd-439e4c6 main; HEAD=feat/rerank; role:ad106e3:ours; role:439e4c6:theirs; role:8afc6bd:base; sub:ad106e3:TOP__K_=_20; sub:439e4c6:TOP__K_=_8; sub:8afc6bd:TOP__K_=_5 || [git rebase main, step 2] 8afc6bd-439e4c6-1c9f69a; 439e4c6 main; 8afc6bd-5ee19f0-569e6c9 REBASE_HEAD; HEAD=1c9f69a; role:1c9f69a:ours; role:569e6c9:theirs; role:5ee19f0:base; sub:1c9f69a:TOP__K_=_8; sub:569e6c9:TOP__K_=_20; sub:5ee19f0:TOP__K_=_5 title=Same_two_values,_opposite_positions id=twice

**[DIAGRAM]** New diagram: the same conflict drawn twice. Left as a merge, right as one step of a rebase. Write "ours" and "theirs" on the commits, and the value of `TOP_K` under each.

```text
  git merge main  (on feat/rerank)                 git rebase main  (on feat/rerank), step 2

        569e6c9 ... ad106e3   feat/rerank                       1c9f69a          HEAD (detached)
       /             (HEAD)   OURS    TOP_K = 20               /                 OURS    TOP_K = 8
  8afc6bd                                              8afc6bd---439e4c6   main
       \                                                      \
        439e4c6   main        THEIRS  TOP_K = 8                5ee19f0---569e6c9  REBASE_HEAD
                                                                                  THEIRS  TOP_K = 20
  base: merge base 8afc6bd    TOP_K = 5                base: parent of 569e6c9    TOP_K = 5

  Same two values. Opposite positions.
```

The same conflict, drawn twice. On the left, as a merge: ours is your branch, with 20, and theirs is `main`, with 8. On the right, as step two of the rebase: ours is HEAD, with 8, and theirs is your commit, with 20. The base says 5 both times.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch09/rebase-conflict`. The stopped rebase of V053 again: `main` set `TOP_K` to 8, your commit sets it to 20.

**Part 1: who is who.**

<!-- snippet: ch09/rebase-conflict/01-markers -->
```text
# The rebase of section 9.4 has stopped at the same commit again.
$ cat app/retriever.py
<<<<<<< HEAD
TOP_K = 8
=======
TOP_K = 20
>>>>>>> 569e6c9 (Fetch 20 candidates for the reranker)

def retrieve(query):
    return rerank(search(query, TOP_K))
```
<!-- /snippet -->

Upper half, labelled `HEAD`: 8. Lower half, labelled `569e6c9 (Fetch 20 candidates for the reranker)`: 20. Quick quiz, two options. Which half is your work: the upper, or the lower? Say it out loud.

**[PAUSE]**

<!-- snippet: ch09/rebase-conflict/02-stages -->
```text
$ git ls-files -u
100644 35e331a734226399bf019e7226f303fcb01eeabb 1	app/retriever.py
100644 ef8c46811d15d96c680eb865313544b9f5680026 2	app/retriever.py
100644 e67ee8b37c4aa0f84cbd0a310f0a7cc7f7c02f00 3	app/retriever.py
$ git show :1:app/retriever.py | head -1
TOP_K = 5
$ git show :2:app/retriever.py | head -1
TOP_K = 8
$ git show :3:app/retriever.py | head -1
TOP_K = 20
```
<!-- /snippet -->

The lower half is yours. Now the index: stage 1 says 5, stage 2 says 8, stage 3 says 20.

<!-- snippet: ch09/rebase-conflict/03-who-is-who -->
```text
# Stage 2, "ours", is HEAD: the upstream commits plus what has been replayed so far.
$ git log --oneline -2 HEAD
1c9f69a Add reranker skeleton
439e4c6 Raise TOP_K to 8 after recall regression
# Stage 3, "theirs", is the commit being replayed: your own work.
$ git log --oneline -1 REBASE_HEAD
569e6c9 Fetch 20 candidates for the reranker
```
<!-- /snippet -->

Stage 2, "ours", is HEAD: the upstream commit `439e4c6` plus the one copy made so far. Stage 3, "theirs", is `REBASE_HEAD`: your commit. Now integrate the same two branches with a merge, from the same branch. Predict which value is in the upper half. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/rebase-conflict/04-as-a-merge -->
```text
# The same two branches integrated with a merge instead (run from feat/rerank):
$ git merge main
Auto-merging app/retriever.py
CONFLICT (content): Merge conflict in app/retriever.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ cat app/retriever.py
<<<<<<< HEAD
TOP_K = 20
=======
TOP_K = 8
>>>>>>> main

def retrieve(query):
    return rerank(search(query, TOP_K))
$ git show :2:app/retriever.py | head -1
TOP_K = 20
$ git show :3:app/retriever.py | head -1
TOP_K = 8
$ git merge --abort
```
<!-- /snippet -->

20 on top, 8 below.

**[ANIMATION]** step: twice.state-1

Same two values, opposite positions. The demo aborts the merge and goes back to the stopped rebase.

**Part 2: inspect and resolve.** `labs/run ch09/conflict-inspect` shows what you can ask before you decide.

<!-- snippet: ch09/conflict-inspect/01-show-current-patch -->
```text
$ git rebase --show-current-patch
commit 569e6c983316561062d42644d649129e50eeda5d
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:04:00 2026 +0530

    Fetch 20 candidates for the reranker

diff --git a/app/retriever.py b/app/retriever.py
index 35e331a..e67ee8b 100644
--- a/app/retriever.py
+++ b/app/retriever.py
@@ -1,4 +1,4 @@
-TOP_K = 5
+TOP_K = 20
 
 def retrieve(query):
-    return search(query, TOP_K)
+    return rerank(search(query, TOP_K))
```
<!-- /snippet -->

`git rebase --show-current-patch` prints the commit being replayed: what it intended, against its own parent. From 5 to 20, and a call to the reranker. That's the intent you have to preserve.

To resolve, put the content you want into the file, stage it, and continue. Taking your own version whole is `--theirs` here. `git restore --theirs` 🔴 DANGEROUS, as in the merge module. It overwrites the working tree file with the whole of stage 3. Your hand edits to that file are lost. The preview is `git diff --theirs`. And it's appropriate when the whole file from that side is the decision.

<!-- snippet: ch09/rebase-conflict/05-resolve -->
```text
# Back in the stopped rebase. Take the version of the commit being replayed (stage 3):
$ git restore --theirs app/retriever.py
$ cat app/retriever.py
TOP_K = 20

def retrieve(query):
    return rerank(search(query, TOP_K))
$ git add app/retriever.py
$ git status --short
M  app/retriever.py
```
<!-- /snippet -->

Look at the status before continuing: `M`, staged. There's something to commit. Remember this check.

<!-- snippet: ch09/rebase-conflict/06-continue -->
```text
$ git rebase --continue
[detached HEAD 6dc07b7] Fetch 20 candidates for the reranker
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
$ git log --oneline --graph --decorate --all
* a4749c1 (HEAD -> feat/rerank) Enable reranking in config
* 6dc07b7 Fetch 20 candidates for the reranker
* b7e0843 Add reranker skeleton
* 439e4c6 (main) Raise TOP_K to 8 after recall regression
* 8afc6bd Add retriever and model config
$ git reflog -5
a4749c1 HEAD@{0}: rebase (finish): returning to refs/heads/feat/rerank
a4749c1 HEAD@{1}: rebase (pick): Enable reranking in config
6dc07b7 HEAD@{2}: rebase (continue): Fetch 20 candidates for the reranker
b7e0843 HEAD@{3}: rebase (pick): Add reranker skeleton
439e4c6 HEAD@{4}: rebase (start): checkout main
```
<!-- /snippet -->

`--continue` commits the index as the copy of the stopped commit and runs the remaining instructions. The reflog, Git's local record of where HEAD has been, says `rebase (continue)` for that step. Three commits on the branch, on top of `main`.

If you know in advance which side should win every conflicting hunk, each block of changed lines, say so, and the rebase doesn't stop.

<!-- snippet: ch09/rebase-conflict/07-strategy-option -->
```text
# The same rebase, telling the merge machinery in advance to prefer "theirs" in conflicting hunks:
$ git rebase -X theirs main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
$ head -1 app/retriever.py
TOP_K = 20
```
<!-- /snippet -->

`-X theirs` favours your commits. `-X ours` would favour `main` and discard your side of every conflicting hunk without a message.

**Part 3: the other exits.** `labs/run ch09/conflict-exits`.

<!-- snippet: ch09/conflict-exits/01-skip -->
```text
$ git rebase --skip
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
$ git log --oneline --decorate main..HEAD
c4f824e (HEAD -> feat/rerank) Enable reranking in config
0c83908 Add reranker skeleton
$ cat app/retriever.py
TOP_K = 8

def retrieve(query):
    return search(query, TOP_K)
```
<!-- /snippet -->

`--skip` gives a branch without the commit, and with the value from `main`: two commits, `TOP_K = 8`, no call to the reranker.

<!-- snippet: ch09/conflict-exits/02-quit -->
```text
$ git rebase --quit
$ git status
HEAD detached from refs/heads/feat/rerank
Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   app/retriever.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git log --oneline --graph --decorate --all
* c92ee53 (HEAD) Add reranker skeleton
* 439e4c6 (main) Raise TOP_K to 8 after recall regression
| * ad106e3 (feat/rerank) Enable reranking in config
| * 569e6c9 Fetch 20 candidates for the reranker
| * 5ee19f0 Add reranker skeleton
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

`--quit` removes the state directory, the rebase's own folder inside dot git, and nothing else. The branch is untouched, HEAD is detached on the half-built history, and the index still holds the conflict.

<!-- snippet: ch09/conflict-exits/03-after-quit -->
```text
$ git switch feat/rerank
error: you need to resolve your current index first
app/retriever.py: needs merge
[exit status: 1]
$ git reset --hard
HEAD is now at c92ee53 Add reranker skeleton
$ git switch feat/rerank
Warning: you are leaving 1 commit behind, not connected to
any of your branches:

  c92ee53 Add reranker skeleton

If you want to keep it by creating a new branch, this may be a good time
to do so with:

 git branch <new-branch-name> c92ee53

Switched to branch 'feat/rerank'
```
<!-- /snippet -->

Getting back to the branch from there takes a `git reset --hard` 🔴 to clear the conflict, on a state you have decided to discard, and Git warns that you're leaving a commit behind. Use `--quit` only when you want to keep that state and take over by hand.

Two refusals, from `conflict-inspect`:

<!-- snippet: ch09/conflict-inspect/03-continue-too-early -->
```text
$ git rebase --continue
app/retriever.py: needs merge
You must edit all merge conflicts and then
mark them as resolved using git add
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch09/conflict-inspect/04-second-rebase -->
```text
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

The first: nothing is staged yet. The second: a rebase is already running. Take the first suggestion of that message, never the `rm -fr`, unless `git status` has told you there's nothing to keep.

**Part 4: two traps.** `labs/run ch09/conflict-traps`. The first is the opening story. Stopped at the same commit, you want your version, so you type `--ours`. Watch the status line.

<!-- snippet: ch09/conflict-traps/01-ours-trap -->
```text
# The rebase is stopped at "Fetch 20 candidates for the reranker". You want your version, so you type:
$ git restore --ours app/retriever.py
$ git add app/retriever.py
$ git status --short
$ git rebase --continue
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
```
<!-- /snippet -->

`git status --short` printed nothing. Then "Successfully rebased". Predict the log. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/conflict-traps/02-ours-result -->
```text
$ git log --oneline --decorate main..HEAD
7c7ac13 (HEAD -> feat/rerank) Enable reranking in config
0c83908 Add reranker skeleton
$ git range-diff main ORIG_HEAD HEAD
1:  5ee19f0 = 1:  0c83908 Add reranker skeleton
2:  569e6c9 < -:  ------- Fetch 20 candidates for the reranker
3:  ad106e3 = 2:  7c7ac13 Enable reranking in config
```
<!-- /snippet -->

Two commits. "Fetch 20 candidates for the reranker" is not there.

**[ANIMATION]** graph: 8afc6bd-439e4c6 main; 439e4c6-0c83908-7c7ac13 feat/rerank; 8afc6bd-5ee19f0-569e6c9-ad106e3 ORIG_HEAD; HEAD=feat/rerank; reflog:5ee19f0,569e6c9,ad106e3; same:5ee19f0; same:0c83908; left:569e6c9; same:ad106e3; same:7c7ac13; note:569e6c9:no_counterpart title=An_empty_step,_dropped_without_a_message id=lost

`git range-diff`, which the next video explains, shows it in one line: commit 2 of the old branch has no counterpart. Almost everyone falls into this once, because the word invites it.

**[ON SCREEN]** The root-cause box of section 9.11.

```text
Observed behavior : The rebase finishes normally, and "Fetch 20 candidates for the reranker"
                    is not in the branch.
Git state         : At the stop, stage 2 ("ours") was main's version of the file. After restore
                    and add, the index equals HEAD: "git status --short" printed nothing.
Mechanism         : --continue found nothing to commit for this instruction. A commit that has
                    become empty is dropped (the default, --empty=drop), and the next
                    instruction runs. No message.
Root cause        : "ours" was read as "my change". In a rebase it is the side you are
                    rebasing onto.
Why Git does this : A replay with an empty result normally means the change is already
                    upstream, which is the common and harmless case (section 9.12).
Correct fix       : git reset --hard ORIG_HEAD, rebase again, take --theirs or edit by hand.
Prevention        : Read "git status" before --continue. Run "git range-diff" after every
                    rebase that stopped.
```

That's the silence from the opening: an empty step, dropped by default.

The second trap is a habit from ordinary work. This time the resolution is right, but the next command is not.

<!-- snippet: ch09/conflict-traps/03-amend-trap -->
```text
# Stopped at the same commit. This time the resolution is right, but the next command is not:
$ git restore --theirs app/retriever.py
$ git add app/retriever.py
$ git commit --amend --no-edit
[detached HEAD 1e6f47e] Add reranker skeleton
 Date: Mon Sep 7 10:03:00 2026 +0530
 2 files changed, 4 insertions(+), 2 deletions(-)
 create mode 100644 app/rerank.py
$ git rebase --continue
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
```
<!-- /snippet -->

<!-- snippet: ch09/conflict-traps/04-amend-result -->
```text
$ git log --oneline --decorate main..HEAD
036744c (HEAD -> feat/rerank) Enable reranking in config
1e6f47e Add reranker skeleton
$ git show --stat --format="%h %s" HEAD~1
1e6f47e Add reranker skeleton

 app/rerank.py    | 2 ++
 app/retriever.py | 4 ++--
 2 files changed, 4 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

At a conflict stop, HEAD is the previous copy. `git commit --amend` therefore folded the resolution into "Add reranker skeleton", which now changes two files, and the stopped commit, left with nothing, was dropped. After a conflict the sequence is `git add`, then `git rebase --continue`. `--amend` belongs to an `edit` stop, where Git itself suggests it.

**Part 5: commits that are already upstream.** `labs/run ch09/upstream-picked`. `main` received the middle commit of your branch through a cherry-pick, which copies one commit's change onto another branch as a new commit.

<!-- snippet: ch09/upstream-picked/01-before -->
```text
$ git log --oneline --graph --decorate --all
* b0f4913 (main) Retry flaky downloads three times
* b0d0bef Add README
| * cb69662 (HEAD -> feat/ingest) Add chunker
| * 3667d58 Retry flaky downloads three times
| * 2c4fb0f Add document loader
|/  
* 3b687c6 Add ingest settings
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

"Retry flaky downloads three times" exists twice: `3667d58` on your branch, `b0f4913` on `main`. Try it now, on paper. Thirty seconds: draw `feat/ingest` after `git rebase main`. How many commits of yours are on it?

**[PAUSE]**

<!-- snippet: ch09/upstream-picked/02-predict -->
```text
$ git cherry -v main feat/ingest
+ 2c4fb0f9d67529c6c5e0593806e7b7e3ae166e1b Add document loader
- 3667d58e78b9db6022247e4772f7514a2eb4cd8f Retry flaky downloads three times
+ cb696620666fc31778e69cac508a0e92db27af29 Add chunker
$ git log --oneline --left-right --cherry-mark main...feat/ingest
= b0f4913 Retry flaky downloads three times
< b0d0bef Add README
> cb69662 Add chunker
= 3667d58 Retry flaky downloads three times
> 2c4fb0f Add document loader
```
<!-- /snippet -->

`git cherry` marks with a minus each of your commits that has an equivalent upstream and with a plus each that has none. `git log --cherry-mark` puts an equals sign on both members of the pair. Both compare patch IDs, and the rebase runs the same comparison before it writes the list.

<!-- snippet: ch09/upstream-picked/03-rebase -->
```text
$ git rebase main
warning: skipped previously applied commit 3667d58
hint: use --reapply-cherry-picks to include skipped commits
hint: Disable this message with "git config set advice.skippedCherryPicks false"
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate --all
* a329fe1 (HEAD -> feat/ingest) Add chunker
* b0b024d Add document loader
* b0f4913 (main) Retry flaky downloads three times
* b0d0bef Add README
* 3b687c6 Add ingest settings
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

"Skipped previously applied commit 3667d58", and only two commits are replayed.

**[ANIMATION]** step: picked.state-3

Check your drawing: two, not three. This disappearance is announced, and it was predictable.

**[ANIMATION]** end

Second case. `labs/run ch09/upstream-squashed`. Your first two commits reached `main` as one squashed commit, two commits combined into one new one.

<!-- snippet: ch09/upstream-squashed/01-before -->
```text
$ git log --oneline --graph --decorate --all
* dd84d96 (main) Add document loader with download retries (#52)
* b0d0bef Add README
| * cb69662 (HEAD -> feat/ingest) Add chunker
| * 3667d58 Retry flaky downloads three times
| * 2c4fb0f Add document loader
|/  
* 3b687c6 Add ingest settings
* 8afc6bd Add retriever and model config
$ git cherry -v main feat/ingest
+ 2c4fb0f9d67529c6c5e0593806e7b7e3ae166e1b Add document loader
+ 3667d58e78b9db6022247e4772f7514a2eb4cd8f Retry flaky downloads three times
+ cb696620666fc31778e69cac508a0e92db27af29 Add chunker
```
<!-- /snippet -->

`git cherry` marks all three with a plus: no single commit upstream has the diff of either of yours. So the first mechanism finds nothing. Predict what the rebase does with the first two. I'll wait.

**[PAUSE]**

<!-- snippet: ch09/upstream-squashed/02-rebase -->
```text
$ git rebase main
Rebasing (1/3)
dropping 2c4fb0f9d67529c6c5e0593806e7b7e3ae166e1b Add document loader -- patch contents already upstream
Rebasing (2/3)
dropping 3667d58e78b9db6022247e4772f7514a2eb4cd8f Retry flaky downloads three times -- patch contents already upstream
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate --all
* a499222 (HEAD -> feat/ingest) Add chunker
* dd84d96 (main) Add document loader with download retries (#52)
* b0d0bef Add README
* 3b687c6 Add ingest settings
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Both were replayed, both changed nothing, because their content is already there, and both were dropped as empty: "patch contents already upstream". That's the second mechanism.

<!-- snippet: ch09/upstream-squashed/03-interactive-stops -->
```text
# With -i the default is --empty=stop: the rebase pauses at each commit that became empty.
$ git rebase -i main
Rebasing (1/3)
The previous cherry-pick is now empty, possibly due to conflict resolution.
If you wish to commit it anyway, use:

    git commit --allow-empty

Otherwise, please use 'git rebase --skip'
interactive rebase in progress; onto dd84d96
Last command done (1 command done):
   pick 2c4fb0f # Add document loader
Next commands to do (2 remaining commands):
   pick 3667d58 # Retry flaky downloads three times
   pick cb69662 # Add chunker
  (use "git rebase --edit-todo" to view and edit)
You are currently rebasing branch 'feat/ingest' on 'dd84d96'.
  (all conflicts fixed: run "git rebase --continue")

nothing to commit, working tree clean
Could not apply 2c4fb0f... # Add document loader
[exit status: 1]
$ git rebase --abort
```
<!-- /snippet -->

With `-i` the default is `--empty=stop`: the rebase pauses at each commit that became empty and lets you decide.

`--reapply-cherry-picks` switches the first mechanism off. The commit is then replayed and caught by the second.

<!-- snippet: ch09/upstream-picked/04-reapply -->
```text
$ git rebase --reapply-cherry-picks main
Rebasing (1/3)
Rebasing (2/3)
dropping 3667d58e78b9db6022247e4772f7514a2eb4cd8f Retry flaky downloads three times -- patch contents already upstream
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --decorate main..HEAD
fb8c073 (HEAD -> feat/ingest) Add chunker
b58e077 Add document loader
```
<!-- /snippet -->

**[ANIMATION]** walk: columns=noticed,when,Git_says rows=by_patch_ID:before_replaying:skipped_previously_applied_commit|as_an_empty_result:after_replaying:patch_contents_already_upstream|not_at_all:the_upstream_version_differs:the_replay_conflicts marks=3.3:bad mono=off title=Already_upstream:_two_mechanisms id=mech

Where it stops working: "already upstream" means the same diff, or a replay with an empty result. If the upstream version differs from yours, for instance because a reviewer's change went into the squash, neither mechanism applies and the replay conflicts. That was the stacked branch of video 54, and the answer there was to name the boundary with `--onto`.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Taking `--ours` in a rebase to keep your own change.** Root cause: "ours" is HEAD, the side you are rebasing onto; the index then equals HEAD, the replay is empty, and an empty commit is dropped without a message.
2. **Running `git commit --amend` after resolving a rebase conflict.** Root cause: at a conflict stop HEAD is the previous copy, so the amend folds the resolution into that commit and leaves the stopped commit empty.
3. **Running `--continue` without reading `git status`.** Root cause: a clean status after `git add` means there is nothing to commit for this step, which is the sign of the first mistake.
4. **Following the `rm -fr .git/rebase-merge` suggestion.** Root cause: it removes the state of a rebase that may still hold something valuable; `--continue`, `--abort` or `--skip` are the exits.
5. **Assuming `git cherry` predicts every drop after a squash merge.** Root cause: the patch-ID comparison needs an upstream commit with the same diff; a squash is caught only later, as an empty replay, and not at all if the squash differs from your commits.

## PRODUCTION EXAMPLE

**[ANIMATION]** bars: bars=did_not_know_the_swap:48|saw_a_production_bug:61 unit=% max=100 title=Two_self-selected_polls,_2024 at_2=50

Now, out of the lab. The textbook cites two figures from Julia Evans's 2024 polls, with their caveat. 48 percent of 1,511 respondents did not know that the two sides swap between merge and rebase. And 61 percent of about 1,480 had seen a production bug caused by a bad conflict resolution. Both samples are self-selected. Its conclusion is the useful part: assume the confusion exists on your team.

**[ANIMATION]** end

A second cost is specific to rebase. A branch of twelve commits that all touch the lines `main` changed can stop twelve times. Each stop is a chance for one of today's traps. The textbook gives three ways to reduce the exposure. Reduce the number of replays first, by squashing with `--keep-base`. Or record resolutions with rerere, which Chapter 14C covers. Or integrate with one merge.

**[ANIMATION]** step: mech.3

And for follow-up branches after a squash merge: a plain `git rebase main` does the right thing exactly when the squash equals the sum of your commits. Check with `git cherry -v main` first. For lines marked with a plus that you believe are merged, expect an empty replay or a conflict.

## PRACTICE EXERCISE

Your turn. Do Lab 9.4, "A conflict in a rebase, and who is "ours"", in [`lab-manual/m09-rebase.md`](../../lab-manual/m09-rebase.md).

When the rebase stops, before you touch the file, write down:

- The content of stage 1, stage 2 and stage 3, and for each, which commit it comes from.
- Which of `--ours` and `--theirs` would give you your own version.
- What `git status --short` will print after a correct resolution and `git add`, and what it would print after the wrong one.

Then resolve, and check your third prediction before you continue.

The challenge is Exercise 9.8, Level 3, "the same conflict at every commit", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q148: "During a rebase, what do `--ours` and `--theirs` refer to, and why? Give one concrete way this loses work without any error message."

**[PAUSE]**

Answer out loud first. A strong answer derives the meaning of the two words from where HEAD is during a rebase, so that the swap is a consequence and not a rule to memorize. For the second half it tells the sequence command by command, and names the exact point at which the work is lost and the mechanism that makes Git silent. It ends with the two checks that would have caught it, one before continuing and one after the rebase.

## RECAP

**[ANIMATION]** step: who.roles

Let's land this. You should now be able to say, in your own words:

Each step of a rebase is a three-way merge into HEAD. The base is the parent of my commit, "ours" is the upstream plus the copies so far, and "theirs" is my commit being replayed. So `--theirs` is my version, and `--ours` followed by `--continue` drops my commit silently, because the replay became empty.

**[ANIMATION]** graph: [--continue] 8afc6bd-439e4c6-b7e0843-6dc07b7-a4749c1 feat/rerank; 439e4c6 main; HEAD=feat/rerank || [--skip] 8afc6bd-439e4c6-0c83908-c4f824e feat/rerank; 439e4c6 main; HEAD=feat/rerank || [--quit] 8afc6bd-439e4c6-c92ee53; 439e4c6 main; 8afc6bd-5ee19f0-569e6c9-ad106e3 feat/rerank; HEAD=c92ee53 title=Three_exits,_three_results layout=rows dx=150 id=exits

After a conflict the sequence is `git add` and `git rebase --continue`, never `--amend`. `--skip` leaves the commit out, `--abort` returns to the start, and `--quit` leaves a detached, half-built state.

**[ANIMATION]** replay: picked

A rebase also drops commits on purpose: by patch ID before replaying, which `git cherry` predicts, and as empty results after replaying.

## HOMEWORK

Read sections 9.11 and 9.12 of [Chapter 9](../../textbook/ch09-rebase.md).

Today you learned to read a rebase conflict by position, not by the word, and to tell a planned disappearance from an accident. Practise Lab 9.4 before the next video. Next time: `git pull --rebase`, and reviewing a rebase with `git range-diff`. Until then, look at the state first and type second. See you in the next one.
