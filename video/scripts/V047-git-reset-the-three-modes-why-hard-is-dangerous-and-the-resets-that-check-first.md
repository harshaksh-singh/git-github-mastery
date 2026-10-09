# V047: git reset: the three modes, why --hard is dangerous, and the resets that check first

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 8, Undoing changes
- **Planned minutes:** 28
- **Prerequisites:** V046
- **Textbook sections:** [Chapter 11](../../textbook/ch11-reset-revert-restore.md), sections 11.4, 11.5, 11.6 and 11.7
- **Demo scripts:** `labs/ch11/reset-modes.sh`, `labs/ch11/orig-head-slot.sh`, `labs/ch11/reset-hard-preview.sh`, `labs/ch11/reset-hard-proofs.sh`, `labs/ch11/reset-keep-merge.sh`, `labs/ch11/amend-is-soft-reset.sh`

## HOOK

**[ON SCREEN]** "An engineer ran `git reset --hard` and says two days of work are gone."

The CTO asks: "Which part can you bring back, which part can you not, and why?"

**[ANIMATION]** cards: question=Two_days_of_work,_three_kinds_of_thing cards=committed:comes_back_through_the_reflog|staged:survives_as_a_blob_without_a_name|never_staged:gone,_Git_never_stored_it numbered=on marks=1:ok,2:ok,3:bad id=three at_1=44 at_2=62 at_3=80

**[ANIMATION]** step: three.3

That question has an exact answer, and it has three parts, because "two days of work" is three different kinds of thing to Git. The committed part comes back through the reflog, Git's local list of where each ref has been. The staged part survives as a blob, an object that holds the bytes of one file, without a name. And the part that was never staged is gone, because Git never stored it.

Today you prove each of those three sentences in a terminal. Count them off as we go. And then you learn the reset that would have refused to do the damage.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. `git reset` is the command most people mean when they say "undo", and the one most people fear. Both reactions come from not knowing what it writes.

The plan. First the three modes, `--soft`, `--mixed` and `--hard`, on one file that has a different version in each of the three trees, so that you can see how far each mode spreads. The three trees are your files on disk, the index, which is the proposed next commit, and HEAD, the commit you're on. Then what happens inside `.git`, including `ORIG_HEAD`, a safety net with a hole in it.

Then section 11.5: four kinds of work, one hard reset, and what is left of each. Then the two modes that check before they overwrite, `--keep` and `--merge`. And last, `git commit --amend`, which turns out to be a soft reset followed by a commit.

All of it applies to private history only. That was the deciding question of the last video.

## LEARNING OBJECTIVES

**[ON SCREEN]** The five objectives.

After this video you can:

- Predict the working tree, the index and the branch after `--soft`, `--mixed` and `--hard`.
- Sort work into committed, staged and never staged, and say what a hard reset leaves recoverable for each.
- Preview a hard reset and set a way back before running it.
- Choose `--keep` over `--hard`, and explain what `--merge` protects.
- Describe `git commit --amend` as a soft reset followed by a commit.

## CONCEPT

**[ANIMATION]** graph: 4d17008-d44696e-9d940ca main; HEAD=main => 4d17008-d44696e main; 9d940ca ORIG_HEAD; HEAD=main; reflog:9d940ca title=A_reset_moves_the_branch id=move

**[ANIMATION]** step: state-1

In one sentence: `git reset <commit>` 🟡 CAUTION makes the current branch point at `<commit>`, and its mode decides whether the index, with `--mixed`, the default, and the working tree, with `--hard`, are rewritten to match.

Precisely. With a commit argument and no path, reset does up to three things.

**[ON SCREEN]** The three steps.

**[ANIMATION]** trees: state=2,2,2 history=off steps=setup,reset-soft,reset-mixed,reset-hard id=steps title=What_a_reset_writes at_reset_soft=35

**[ANIMATION]** step: reset-soft

One: it writes the current commit ID to `ORIG_HEAD` and makes the branch that HEAD points at name `<commit>`. `--soft` does only this.

**[ANIMATION]** step: reset-mixed

Two: it rewrites the index to match `<commit>`. `--mixed` does this as well.

**[ANIMATION]** step: reset-hard

Three: it rewrites the tracked files in the working tree to match `<commit>`. Only `--hard` does this.

`<commit>` defaults to HEAD. So `git reset` alone unstages everything, and `git reset --hard` alone discards every uncommitted change to tracked files. On a detached HEAD, where HEAD holds a commit ID instead of a branch name, there's no branch to move, and HEAD itself is rewritten.

**[ANIMATION]** step: move.state-2

Inside `.git`: the file `HEAD` doesn't change. It still says `ref: refs/heads/main`. What changes is the content of that ref. `ORIG_HEAD` holds the previous ID. Both reflogs gain a line. And no object is deleted.

**[ANIMATION]** end

Now why `--hard` is 🔴. `--soft` and `--mixed` never write a file. `--hard` overwrites files, and what that costs depends on one question for each piece of work: did Git ever store it as an object? Git writes a blob when content is staged or committed. An edit that was only saved in the editor was never stored.

Quick quiz. You stage a file, and a hard reset takes it away. Where is its content? A, in the reflog. B, in the object database, without a name. C, nowhere. Your answer?

**[PAUSE]**

B. Staging wrote the blob, and a reset deletes no object. The demo finds it.

**[ANIMATION]** ladder: rungs=only_in_the_reflog:kept_30_days_(gc.reflogExpireUnreachable)|unreachable_object:removed_by_gc_once_older_than_two_weeks_(gc.pruneExpire) title=How_long_the_recoverable_kinds_last at_1=30 at_2=58

How long do the recoverable kinds last? The textbook states the defaults from the manual. A reflog entry for a commit that its branch no longer reaches is kept for 30 days, `gc.reflogExpireUnreachable`. And garbage collection removes unreachable objects, the ones nothing reaches any more, once they're older than two weeks, `gc.pruneExpire`. The lab configuration overrides the reflog expiry, as video 1 explained.

**[ANIMATION]** end

The alternatives. `git reset --keep <commit>` 🟡 moves the branch like `--hard`, carries your uncommitted changes across, and refuses to run when it would have to overwrite one of them. `git reset --merge <commit>` 🔴 does the same for unstaged changes and throws staged changes away. It exists for backing out of a merge, where whatever is staged is merge output and should go.

And `git commit --amend` 🟡 replaces the last commit with a new commit that has the same parent and is built from the current index. Git's manual calls it "a rough equivalent" of `git reset --soft HEAD^`, some changes, and `git commit -c ORIG_HEAD`.

## MENTAL MODEL

**[ON SCREEN]** "Move the bookmark. Then: clear the draft page? Clear the desk?"

A picture helps. The textbook's analogy: a bookmark in a lab notebook. `--soft` moves the bookmark back. `--mixed` also clears the page you had drafted for the next entry. `--hard` also clears the desk.

**[ANIMATION]** trees: names=The_desk,The_draft_page,The_bookmark subs=working_tree,index,the_branch versions=the_entry_before,the_latest_entry state=2,2,2 file=entry history=off cmd=off steps=setup,reset-soft,reset-mixed,reset-hard title=A_bookmark_in_a_lab_notebook say_setup=No_page_is_torn_out:_the_entries_after_the_bookmark_stay_in_the_notebook say_reset_soft=--soft_moves_the_bookmark_back say_reset_mixed=--mixed_also_clears_the_draft_page say_reset_hard=--hard_also_clears_the_desk at_reset_soft=14 at_reset_mixed=26 at_reset_hard=36 id=desk

**[ANIMATION]** step: desk.setup

The analogy breaks in a useful way: no page is torn out. The entries after the bookmark stay in the notebook, and Git discards unmarked pages only after weeks.

**[ANIMATION]** step: desk.reset-hard

So two things to hold. First, reset always starts by moving the bookmark, and the mode only decides how far the change spreads. Second, the notebook is safe and the desk isn't. What was written into the notebook, committed or even only staged, can be found again. What was only lying on the desk can't.

## DIAGRAM

**[ANIMATION]** graph: 4d17008-d44696e-9d940ca main; HEAD=main => 4d17008-d44696e main; 9d940ca ORIG_HEAD HEAD@{1} main@{1}; HEAD=main; reflog:9d940ca title=Before_and_after_git_reset_HEAD~1

**[DIAGRAM]** Left: three commits with `main` on the last. Right: move the `main` label one commit back, and leave the last commit hanging with its three remaining names.

```text
before                                    after git reset HEAD~1 (any mode)

4d17008---d44696e---9d940ca               4d17008---d44696e            main  (HEAD -> main)
                    main (HEAD -> main)                    \
                                                            9d940ca    no branch: ORIG_HEAD, HEAD@{1}, main@{1}
```

**[ANIMATION]** step: state-1

Now with real commits. Before: three in a row, with `main` on the last, `9d940ca`.

**[ANIMATION]** step: state-2

After `git reset HEAD~1`, in any mode, `main` is one commit back. `9d940ca` has no branch, but three names remain: `ORIG_HEAD`, and entry one in both reflogs.

**[ANIMATION]** walk: columns=eval.yaml_in,HEAD,Index,Working_tree,git_status_-s rows=before:0.70:0.80:0.90:MM|after_git_reset_--soft_HEAD~1:?:?:?:?|after_git_reset_--mixed_HEAD~1:?:?:?:?|after_git_reset_--hard_HEAD~1:?:?:?:? title=The_prediction_table

**[DIAGRAM]** Then the prediction table, filled in row by row during the demo.

```text
eval.yaml in                        HEAD    Index   Working tree   git status -s
----------------------------------  ------  ------  -------------  -------------
before                              0.70    0.80    0.90           MM
after git reset --soft HEAD~1       0.60    0.80    0.90           MM
after git reset --mixed HEAD~1      0.60    0.60    0.90            M
after git reset --hard HEAD~1       0.60    0.60    0.60           clean
```

And here's the table you'll fill in during the demo. The first row is the starting state. The other three rows are yours to predict.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch11/reset-modes`. The starting state is the one from the last video: 0.70 in HEAD, 0.80 in the index, 0.90 on disk. Each mode runs in its own copy.

<!-- snippet: ch11/reset-modes/01-before -->
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

That's the starting state: 0.70 in HEAD, 0.80 in the index, 0.90 on disk.

**[ANIMATION]** trees: file=eval.yaml chips=0.90,0.80,0.70 ref=main commits=9d940ca steps=setup title=Before_the_reset:_one_file,_three_versions

**The three modes.** For each, predict the three values and the status letters before the output. First `--soft`. Say them out loud. I'll wait.

```bash
git reset --soft HEAD~1
```

**[PAUSE]**

<!-- snippet: ch11/reset-modes/02-soft -->
```text
$ git reset --soft HEAD~1
$ git log --oneline
d44696e Raise threshold to 0.60
4d17008 Add eval config
$ git show HEAD:eval.yaml
threshold: 0.60
$ git show :eval.yaml
threshold: 0.80
$ cat eval.yaml
threshold: 0.90
$ git status -s
MM eval.yaml
```
<!-- /snippet -->

The log lost a commit, and HEAD now holds 0.60. The index and the file are untouched. The status is still `MM`, but it's now measured against the older commit: `git commit` at this point would record 0.80 directly on top of `d44696e`. Next, `--mixed`. Predict the row.

**[PAUSE]**

<!-- snippet: ch11/reset-modes/03-mixed -->
```text
$ git reset --mixed HEAD~1
Unstaged changes after reset:
M	eval.yaml
$ git log --oneline
d44696e Raise threshold to 0.60
4d17008 Add eval config
$ git show HEAD:eval.yaml
threshold: 0.60
$ git show :eval.yaml
threshold: 0.60
$ cat eval.yaml
threshold: 0.90
$ git status -s
 M eval.yaml
```
<!-- /snippet -->

The index now equals the new HEAD, and Git reports what is left as unstaged. The file still says 0.90. And now `--hard`. Predict.

**[PAUSE]**

<!-- snippet: ch11/reset-modes/04-hard -->
```text
$ git reset --hard HEAD~1
HEAD is now at d44696e Raise threshold to 0.60
$ git log --oneline
d44696e Raise threshold to 0.60
4d17008 Add eval config
$ git show HEAD:eval.yaml
threshold: 0.60
$ git show :eval.yaml
threshold: 0.60
$ cat eval.yaml
threshold: 0.60
$ git status -s
```
<!-- /snippet -->

All three places hold 0.60. The staged 0.80 and the unstaged 0.90 are gone from every place you can name.

**Inside `.git`.**

<!-- snippet: ch11/reset-modes/05-inside-git -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ cat .git/refs/heads/main
9d940caa6545e66b9555bf56a26ea9242b19e402
$ git reset --soft HEAD~1
$ cat .git/HEAD
ref: refs/heads/main
$ cat .git/refs/heads/main
d44696eb333776b2089f9627a30f31733c0df8be
$ cat .git/ORIG_HEAD
9d940caa6545e66b9555bf56a26ea9242b19e402
$ git reflog -2
d44696e HEAD@{0}: reset: moving to HEAD~1
9d940ca HEAD@{1}: commit: Raise threshold to 0.70
$ git reflog show -2 main
d44696e main@{0}: reset: moving to HEAD~1
9d940ca main@{1}: commit: Raise threshold to 0.70
```
<!-- /snippet -->

`HEAD` says `ref: refs/heads/main` before and after. The ref file changed from the ID starting `9d940ca` to the one starting `d44696e`. `ORIG_HEAD` holds the previous ID, and both reflogs gained the line `reset: moving to HEAD~1`. Commit `9d940ca` is still in the object database.

**`ORIG_HEAD`.** Resetting to it undoes the reset.

<!-- snippet: ch11/reset-modes/06-orig-head -->
```text
$ git reset --soft ORIG_HEAD
$ git log --oneline -1
9d940ca Raise threshold to 0.70
$ git status -s
MM eval.yaml
$ git rev-parse --short ORIG_HEAD
d44696e
```
<!-- /snippet -->

But look at the last line. The undo was itself a reset, so it overwrote `ORIG_HEAD`, which now names `d44696e`.

**[ANIMATION]** graph: 4d17008-d44696e-9d940ca; d44696e main; 9d940ca ORIG_HEAD; HEAD=main; reflog:9d940ca; cmd:git_reset_--soft_HEAD~1 => 4d17008-d44696e-9d940ca main; d44696e ORIG_HEAD; HEAD=main; cmd:git_reset_--soft_ORIG__HEAD; say:ORIG__HEAD_is_one_slot,_not_a_history id=slot

**[ANIMATION]** step: slot.state-2

`ORIG_HEAD` is one slot, not a history. And more commands write it than the manual lists. `labs/run ch11/orig-head-slot`: a merge followed by a stash, the command that parks uncommitted work. Predict what `ORIG_HEAD` names after the stash.

**[PAUSE]**

<!-- snippet: ch11/orig-head-slot/01-merge-then-stash -->
```text
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 rerank.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 rerank.py
$ git log --oneline -1 ORIG_HEAD
5522f41 Add serving config
$ git stash push -m "wip: new recall numbers"
Saved working directory and index state On main: wip: new recall numbers
$ git log --oneline -1 ORIG_HEAD
26ec8ae Merge branch 'feature/reranker'
```
<!-- /snippet -->

After the merge, `ORIG_HEAD` named `5522f41`, the commit to go back to. But `git stash push` ends with an internal reset to HEAD, and every reset writes `ORIG_HEAD`. So it now names the merge commit itself, `26ec8ae`. `git reset --hard ORIG_HEAD` would leave the merge in place. The rule: use `ORIG_HEAD` only as the very next command. After anything else, read the reflog, which has the whole sequence.

<!-- snippet: ch11/orig-head-slot/02-reflog-has-it -->
```text
$ git reflog -3
26ec8ae HEAD@{0}: reset: moving to HEAD
26ec8ae HEAD@{1}: merge feature/reranker: Merge made by the 'ort' strategy.
5522f41 HEAD@{2}: commit: Add serving config
$ git reset --hard HEAD@{2}
HEAD is now at 5522f41 Add serving config
$ git log --oneline
5522f41 Add serving config
9c3779d Add BM25 ranker and baseline metrics
$ git stash pop -q
$ git status -s
 M metrics.txt
```
<!-- /snippet -->

**Why `--hard` is 🔴.** `git reset --hard` 🔴 DANGEROUS. The five answers before it runs.

What it changes: the branch ref, the index, and every tracked file that differs from the target commit.

What it can destroy: every uncommitted change to tracked files, and untracked files that are in the target's way. Untracked means the file has no entry in the index and isn't ignored.

How to preview: three read-only commands. `labs/run ch11/reset-hard-preview`.

<!-- snippet: ch11/reset-hard-preview/01-preview -->
```text
# Commits that will leave the branch (they stay in the reflog):
$ git log --oneline HEAD~2..HEAD
e574174 Blend dense scores into ranker
67b1722 Record baseline metrics
# Uncommitted work (a hard reset destroys the first two lines and keeps the third):
$ git status -s
 M metrics.txt
A  sweep.yaml
?? notes.txt
# Tracked content that differs from the last commit:
$ git diff HEAD --stat
 metrics.txt | 2 +-
 sweep.yaml  | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

First, the commits that will leave the branch. Second, the uncommitted work, by kind. Third, the tracked content that differs from the last commit.

How to recover: commits through the reflog or `ORIG_HEAD`, staged content through `git fsck --lost-found`, nothing else at all. `git fsck` is the checker that lists what nothing reaches.

When it's appropriate: when `git status` is clean, or after you've read `git diff HEAD` and want none of it. Otherwise turn the work into objects first, with two commands.

<!-- snippet: ch11/reset-hard-preview/02-safety-net -->
```text
$ git stash push -u -m "before reset to HEAD~2"
Saved working directory and index state On main: before reset to HEAD~2
$ git branch backup/before-reset
$ git status -s
$ git reset --hard HEAD~2
HEAD is now at 9a98a06 Add BM25 ranker
$ git log --oneline
9a98a06 Add BM25 ranker
```
<!-- /snippet -->

<!-- snippet: ch11/reset-hard-preview/03-nothing-was-lost -->
```text
$ git log --oneline backup/before-reset
e574174 Blend dense scores into ranker
67b1722 Record baseline metrics
9a98a06 Add BM25 ranker
$ git stash list
stash@{0}: On main: before reset to HEAD~2
$ git stash show --include-untracked
 metrics.txt | 2 +-
 notes.txt   | 1 +
 sweep.yaml  | 1 +
 3 files changed, 3 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

The stash entry holds the uncommitted work, and the branch holds the commits.

Now without the safety net. `labs/run ch11/reset-hard-proofs`. Four kinds of work in one repository.

<!-- snippet: ch11/reset-hard-proofs/01-three-kinds-of-work -->
```text
$ git log --oneline
e574174 Blend dense scores into ranker
67b1722 Record baseline metrics
9a98a06 Add BM25 ranker
$ printf 'alpha: [0.5, 0.7, 0.9]\n' > sweep.yaml
$ git add sweep.yaml
$ printf 'recall@10: 0.78\n' > metrics.txt
$ printf 'try alpha=0.9 next\n' > notes.txt
$ git status -s
 M metrics.txt
A  sweep.yaml
?? notes.txt
```
<!-- /snippet -->

The committed change `e574174`. `sweep.yaml`, staged and never committed. The edit to `metrics.txt`, never staged. And `notes.txt`, untracked. Try it now, thirty seconds, on paper: write those four in a column. Next to each, predict what is left after `git reset --hard HEAD~1`, and where.

**[PAUSE]**

<!-- snippet: ch11/reset-hard-proofs/02-reset-hard -->
```text
$ git reset --hard HEAD~1
HEAD is now at 67b1722 Record baseline metrics
$ git log --oneline
67b1722 Record baseline metrics
9a98a06 Add BM25 ranker
$ git status -s
?? notes.txt
$ ls
metrics.txt
notes.txt
rank.py
$ cat metrics.txt
recall@10: 0.71
```
<!-- /snippet -->

The branch is back at `67b1722`, `metrics.txt` says 0.71 again, and `sweep.yaml` is no longer on disk. Only `notes.txt` was left alone.

Kind one, committed work: the reflog has it. That's the CTO's first sentence.

<!-- snippet: ch11/reset-hard-proofs/03-committed-work -->
```text
$ git reflog -2
67b1722 HEAD@{0}: reset: moving to HEAD~1
e574174 HEAD@{1}: commit: Blend dense scores into ranker
$ git reset --hard HEAD@{1}
HEAD is now at e574174 Blend dense scores into ranker
$ git log --oneline
e574174 Blend dense scores into ranker
67b1722 Record baseline metrics
9a98a06 Add BM25 ranker
$ git status -s
?? notes.txt
```
<!-- /snippet -->

Kind two, staged work: an object without a name. `git add` wrote the content as a blob. The hard reset removed the index entry, the only thing that referred to it.

<!-- snippet: ch11/reset-hard-proofs/04-staged-work -->
```text
$ git fsck --lost-found
dangling blob acc57c7b481e66cf03ec96980cc21fadcadc8a5b
$ git cat-file -p acc57c7
alpha: [0.5, 0.7, 0.9]
$ ls .git/lost-found/other
acc57c7b481e66cf03ec96980cc21fadcadc8a5b
$ git cat-file -p acc57c7 > sweep.yaml
$ git status -s
?? notes.txt
?? sweep.yaml
```
<!-- /snippet -->

A dangling blob, `acc57c7`, and `git cat-file -p` prints the sweep configuration. Dangling means nothing refers to it. The content is back. The file name isn't. A blob stores content only, and the name lived in the index entry. After a reset with ten staged files, you get ten anonymous blobs, and you identify them by reading them. That's the second sentence, and the quiz.

Kind three, never-staged work: nothing to find. `git hash-object --stdin` computes the ID that a piece of content would have.

<!-- snippet: ch11/reset-hard-proofs/05-never-staged-work -->
```text
# The staged file: its content was hashed by "git add", so the object exists.
$ printf 'alpha: [0.5, 0.7, 0.9]\n' | git hash-object --stdin
acc57c7b481e66cf03ec96980cc21fadcadc8a5b
$ git cat-file -t acc57c7b481e66cf03ec96980cc21fadcadc8a5b
blob
# The never-staged edit: this is the ID it would have had. No such object was ever written.
$ printf 'recall@10: 0.78\n' | git hash-object --stdin
b812359d6f71b2a9857c24b3c631b8ea58213fcd
$ git cat-file -t b812359d6f71b2a9857c24b3c631b8ea58213fcd
fatal: git cat-file: could not get object info
[exit status: 128]
```
<!-- /snippet -->

For the staged content the object exists: type `blob`. For the never-staged edit, Git computes the ID it would have had, and `git cat-file` fails: no such object was ever written. That's the third sentence, proved.

**[ON SCREEN]** The root-cause box of section 11.5.

```text
Observed behavior : After "git reset --hard", an edit is gone. Neither the reflog nor fsck shows it.
Git state         : HEAD, index and working tree agree. No blob with the lost content exists.
Mechanism         : Git writes a blob when content is staged or committed. An edit that was only
                    saved in the editor was never stored.
Root cause        : The lost version existed only in the working tree, and --hard overwrote the file.
Why Git does this : The working tree is the one place without history, and --hard is defined as
                    "make it match the commit".
Correct fix       : None inside Git. Editor history, a backup, or retyping.
Prevention        : Commit or stash before a hard reset, or use "git reset --keep" (section 11.6).
```

Here's that loss as a root-cause box. The lost version existed only in the working tree, and the hard reset overwrote the file. There's no fix inside Git, so the prevention is the last line: commit or stash first, or use keep.

**[ANIMATION]** end

Kind four, untracked files: untouched, with one exception. An untracked file whose path the target commit tracks.

<!-- snippet: ch11/reset-hard-proofs/06-untracked-overwritten -->
```text
$ git log --oneline
9a6d9e0 Stop tracking sweep config
533927f Add sweep config
5e23be0 Add BM25 ranker
$ git status -s
?? sweep.yaml
$ cat sweep.yaml
alpha: 0.9   # two days of tuning
$ git reset --keep HEAD~1
error: Untracked working tree file 'sweep.yaml' would be overwritten by merge.
fatal: Could not reset index file to revision 'HEAD~1'.
[exit status: 128]
$ git reset --hard HEAD~1
HEAD is now at 533927f Add sweep config
$ cat sweep.yaml
alpha: 0.7
```
<!-- /snippet -->

`--keep` refused. `--hard` overwrote the file without a word: two days of tuning replaced by `alpha: 0.7`. The manual admits it in one clause: `--hard` "may overwrite untracked files". And there it is: `--keep`, the reset that would have refused.

**`--keep` and `--merge`.** `labs/run ch11/reset-keep-merge`. One commit to drop, a staged change in `serve.yaml`, an unstaged change in `metrics.txt`.

<!-- snippet: ch11/reset-keep-merge/01-state -->
```text
$ git log --oneline
92831a4 Blend dense scores into ranker
c6fd923 Add ranker, serving config and baseline metrics
$ git status -s
 M metrics.txt
M  serve.yaml
```
<!-- /snippet -->

<!-- snippet: ch11/reset-keep-merge/02-keep -->
```text
$ git reset --keep HEAD~1
$ git log --oneline
c6fd923 Add ranker, serving config and baseline metrics
$ git status -s
 M metrics.txt
 M serve.yaml
$ cat serve.yaml metrics.txt
batch_size: 64
recall@10: 0.74
```
<!-- /snippet -->

Both edits survived `--keep`, and both are now unstaged.

<!-- snippet: ch11/reset-keep-merge/03-merge -->
```text
$ git reset --merge HEAD~1
$ git log --oneline
c6fd923 Add ranker, serving config and baseline metrics
$ git status -s
 M metrics.txt
$ cat serve.yaml metrics.txt
batch_size: 32
recall@10: 0.74
```
<!-- /snippet -->

After `--merge`, the unstaged edit to `metrics.txt` is still there, and the staged batch size of 64 is gone: the file says 32 again. `--merge` earns its 🔴 through staged work only. Preview with `git diff --cached`.

<!-- snippet: ch11/reset-keep-merge/04-hard -->
```text
$ git reset --hard HEAD~1
HEAD is now at c6fd923 Add ranker, serving config and baseline metrics
$ git status -s
$ cat serve.yaml metrics.txt
batch_size: 32
recall@10: 0.71
```
<!-- /snippet -->

`--hard` from the same state loses both. And when the local change is in a file that the dropped commit also changed:

<!-- snippet: ch11/reset-keep-merge/05-keep-refuses -->
```text
$ git log --oneline
92831a4 Blend dense scores into ranker
c6fd923 Add ranker, serving config and baseline metrics
$ git status -s
 M rank.py
$ git reset --keep HEAD~1
error: Entry 'rank.py' not uptodate. Cannot merge.
fatal: Could not reset index file to revision 'HEAD~1'.
[exit status: 128]
$ git log --oneline -1
92831a4 Blend dense scores into ranker
$ git status -s
 M rank.py
```
<!-- /snippet -->

`--keep` stops, and the branch didn't move.

**[ON SCREEN]** The comparison table of section 11.6.

```text
Situation                                              --keep                   --merge      --hard
-----------------------------------------------------  -----------------------  -----------  -----------
Staged change in a file the reset does not rewrite     kept, becomes unstaged   discarded    discarded
Unstaged change in such a file                         kept                     kept         discarded
Unstaged change in a file the reset must rewrite       refuses                  refuses      discarded
Staged change in a file the reset must rewrite         refuses                  discarded    discarded
Untracked file at a path the target commit tracks      refuses                  refuses      overwritten
```

The rule that follows: to drop commits, type `--keep`, not `--hard`. On a clean tree the two do the same thing. On a dirty tree, `--keep` carries your work across, or stops and says why.

**Amend.** `labs/run ch11/amend-is-soft-reset`. A line was forgotten in the last commit.

<!-- snippet: ch11/amend-is-soft-reset/01-amend -->
```text
$ git log --oneline
d59fe4c Add serving config
9a98a06 Add BM25 ranker
$ git status -s
 M serve.yaml
$ git add serve.yaml
$ git commit --amend --no-edit
[main ab64793] Add serving config
 Date: Mon Sep 7 10:04:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 serve.yaml
$ git log --oneline
ab64793 Add serving config
9a98a06 Add BM25 ranker
$ git reflog -2
ab64793 HEAD@{0}: commit (amend): Add serving config
d59fe4c HEAD@{1}: commit: Add serving config
$ git show -s --format="%h  parent %p  tree %t" HEAD HEAD@{1}
ab64793  parent 9a98a06  tree b35836e
d59fe4c  parent 9a98a06  tree 7e9e572
```
<!-- /snippet -->

The reflog says `commit (amend)`. Old commit `d59fe4c`, new commit `ab64793`, same parent `9a98a06`, different tree.

**[ANIMATION]** graph: 9a98a06-d59fe4c main; HEAD=main; tree:d59fe4c:7e9e572 => 9a98a06-ab64793 main; 9a98a06-d59fe4c HEAD@{1}; HEAD=main; reflog:d59fe4c; tree:d59fe4c:7e9e572; tree:ab64793:b35836e title=An_amend_replaces_one_commit

**[ANIMATION]** step: state-2

As a graph: two commits on one parent. `main` names the new one, and no branch names the old one. Now the same thing by hand.

<!-- snippet: ch11/amend-is-soft-reset/02-by-hand -->
```text
$ git add serve.yaml
$ git reset --soft HEAD~1
$ git status -s
A  serve.yaml
$ git commit -q -C ORIG_HEAD
$ git log --oneline
732ac95 Add serving config
9a98a06 Add BM25 ranker
$ git show -s --format="%h  parent %p  tree %t" HEAD ORIG_HEAD
732ac95  parent 9a98a06  tree b35836e
d59fe4c  parent 9a98a06  tree 7e9e572
```
<!-- /snippet -->

Both routes end with a commit whose parent is `9a98a06` and whose tree is `b35836e`. The two commit IDs differ only because the committer timestamps differ. An amend is therefore a rewrite of exactly one commit: private history only.

One difference matters when you want the old commit back.

<!-- snippet: ch11/amend-is-soft-reset/03-undo-the-amend -->
```text
$ git rev-parse --verify --short ORIG_HEAD
fatal: Needed a single revision
[exit status: 128]
$ git reset --soft HEAD@{1}
$ git log --oneline
d59fe4c Add serving config
9a98a06 Add BM25 ranker
$ git status -s
M  serve.yaml
$ git reflog -3
d59fe4c HEAD@{0}: reset: moving to HEAD@{1}
ab64793 HEAD@{1}: commit (amend): Add serving config
d59fe4c HEAD@{2}: commit: Add serving config
```
<!-- /snippet -->

`--amend` doesn't write `ORIG_HEAD`. The previous commit is one step back in the reflog, `HEAD@{1}`.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Typing `--hard` to drop a commit while the tree is dirty.** Root cause: `--hard` is defined as "make the working tree match the commit", and the working tree is the one place without history.
2. **Running `git reset --hard ORIG_HEAD` some commands after the operation you want to undo.** Root cause: `ORIG_HEAD` is one slot that every reset writes, including the internal reset at the end of `git stash push`.
3. **Assuming untracked files are always safe from a hard reset.** Root cause: an untracked file at a path the target commit tracks is in the target's way and is overwritten.
4. **Expecting `git fsck --lost-found` to return files with their names.** Root cause: a blob stores content only; the name lived in the index entry that the reset removed.
5. **Amending a commit that has been pushed.** Root cause: an amend creates a new commit with the same parent, which is a rewrite of one commit and diverges from what others have.

## PRODUCTION EXAMPLE

Now, out of the lab. Two example uses, for a team that ships a retrieval service, both on private history.

**[ANIMATION]** graph: *0-*1-*2-*3 main; *0 origin/main; HEAD=main; note:*1:wip; note:*2:wip_2; note:*3:fix_typo => + *0 main; reflog:*1,*2,*3; cmd:git_reset_--soft_@{u}; say:The_combined_change_stays_staged,_ready_for_one_clean_commit

**[ANIMATION]** step: state-2

Three commits named "wip", "wip 2" and "fix typo" before a review. `git reset --soft @{u}` moves the branch back to what is pushed, and leaves the combined change staged for one clean commit.

**[ANIMATION]** end

A commit that mixes a refactoring with a behavior change. `git reset HEAD~1`, the mixed default, leaves both in the working tree, unstaged, ready to be split with `git add -p`.

And the team rule that comes out of section 11.6: in runbooks and in muscle memory, the command for dropping commits is `git reset --keep`. The day somebody has two days of tuning in an untracked file, that one word is the difference between an error message and an incident.

## PRACTICE EXERCISE

Your turn. Do Lab 8.1, "The reset prediction table", in [`lab-manual/m08-undo.md`](../../lab-manual/m08-undo.md).

The lab gives you a state and asks you to fill in a table before you run anything: for each of `--soft`, `--mixed`, `--hard`, `--keep` and `--merge`, the content of HEAD, the index and the working tree, and the output of `git status -s`. Fill in the whole table first. Then run the commands and mark every cell you got wrong.

For the failure scenario, predict which of your pieces of work will be recoverable, and by which command.

The challenge is Exercise 8.8, Level 3, "what a hard reset took and what it left", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q171: "HEAD, the index and the working tree hold three different versions of one file. What does each hold after `git reset --soft HEAD~1`, after `--mixed` and after `--hard`, and what does `git status -s` print?"

**[PAUSE]**

Answer out loud, and draw the table as you speak.

**[PAUSE]**

**[ANIMATION]** replay: steps

A strong answer derives each row from the three steps of a reset, so that the table is the consequence of a rule and not a list. It gets the status letters right, including the row where the letters stay the same but mean something else. A follow-up will ask what became of the versions that no place holds any more. Be ready to say, for each one, whether an object exists.

## RECAP

**[ANIMATION]** step: move.state-2

Let's land this. You should now be able to say:

A reset moves the current branch and writes `ORIG_HEAD`. `--mixed` also rewrites the index, and `--hard` also rewrites tracked files.

**[ANIMATION]** step: three.marks

Commits left behind are in the reflog, staged content survives as unnamed blobs that `git fsck --lost-found` lists, and edits that were never staged have no object and are gone.

**[ANIMATION]** step: steps.reset-hard

Before a hard reset I preview with `git log`, `git status -s` and `git diff HEAD`, and I stash and branch if anything should survive. To drop commits I type `--keep`, which carries my changes across or refuses. `git commit --amend` is a soft reset plus a new commit, and it doesn't write `ORIG_HEAD`.

## HOMEWORK

Read sections 11.4 to 11.7 of [Chapter 11](../../textbook/ch11-reset-revert-restore.md).

Do Exercise 8.4, Level 2, "`reset --keep`, twice", and Exercise 8.6, Level 2, "after a hard reset", both in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

You can now answer the CTO in three exact sentences, and you have a safer word to type: keep. Fill in the lab's table before you run anything. Next time: `git revert`, a new commit that applies the inverse change. Until then, look at the state first and type second. See you in the next one.
