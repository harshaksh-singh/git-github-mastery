# Chapter 11: Reset, Revert, Restore

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch11/`.

## 11.1 Why this matters

Three questions a CTO can ask in the hour after something went wrong:

1. "A bad configuration change is on `main` and three people have already pulled it. What exactly do we run, and what must nobody run?"
2. "An engineer ran `git reset --hard` and says two days of work are gone. Which part can you bring back, which part can you not, and why?"
3. "We reverted the merge of the reranker branch last week. Today the fixed branch was merged again and half of the feature is missing in production. How is that possible?"

All three are undo questions, and undo is where Git costs its users the most time. On 1 October 2026 the highest-voted question under Stack Overflow's `git` tag was "How do I undo the most recent local commits in Git?" (score 27,242), and six more undo questions were in the top 25 ([Stack Overflow](https://stackoverflow.com/questions/tagged/git?tab=Votes)). A study of 80,370 Stack Overflow questions found that the five commands whose questions draw the most views are `git revert`, `git reflog`, `git stash`, `git clean` and `git reset` ([preprint](https://cs.nju.edu.cn/changxu/1_publications/22/TOSEM22.pdf)).

The cause is that Git has no single undo. It has five commands (`restore`, `reset`, `revert`, `clean`, `stash`), and each is defined by the places it writes to. The short answers to the three questions:

1. Add a new commit with `git revert`, and never rewrite a branch that other people already have (sections 11.2 and 11.8).
2. The committed part comes back through the reflog, the staged part survives as a blob without a name, and the part that was never staged is gone, because Git never stored it (section 11.5).
3. Reverting a merge undoes its content and leaves its place in the commit graph, so a later merge of the same branch skips everything the first merge brought (section 11.9).

## 11.2 The map: four places and one deciding question

**The four places.** Every undo command writes to one or more of these, and to nothing else:

| Place | What it holds |
|---|---|
| Working tree (Chapter 4) | The files on disk, including edits that exist nowhere else |
| Index (Chapter 5) | The proposed next commit: one blob ID per tracked path |
| Current branch ref (Chapter 7) | One commit ID under `refs/heads/`; HEAD normally points at this ref |
| History (Chapters 6 and 12) | The commits reachable from that ref. After a push, other repositories hold them too |

**Picture.** One file with a different version in each place, and the direction in which each command copies content:

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

Git's manual draws the same lines: `git restore` "does not update your branch", `git reset` is about "updating your branch, moving the tip", and `git revert` is about "making a new commit that reverts the changes made by other commits" ([git(1)](https://git-scm.com/docs/git), section "Reset, restore and revert").

**The deciding question: is this history private or shared?** A commit is *shared* when a ref that other people can fetch reaches it. Everything else is *private*: it exists only in your repository.

- Private history may be **rewritten**. `git reset`, `git commit --amend` and `git rebase` replace commits with new ones or drop them from the branch. Nobody else can notice, because nobody else has the old commits.
- Shared history is corrected by **adding** commits. `git revert` records the inverse change on top, and everyone's next pull brings it in like any other commit.

The reason is mechanical, not etiquette. A branch in a teammate's clone is a ref that holds a commit ID. If you move your branch backwards, their ref still names the commits you removed. The server rejects your plain push as a non-fast-forward (Lab 8.2). If you force the push, the next teammate who pushes from a clone that still has those commits puts them straight back, or merges them with your replacements (Chapter 9, Rebase, and Chapter 12, Remote Operations).

Before any undo that touches commits, check which side of the line you are on:

```bash
git fetch                              # refresh what you know about the server
git status -sb                         # "ahead 2": two commits the upstream lacks
git log --oneline @{u}..               # the commits that are still private
git branch -r --contains <commit>      # remote-tracking branches that contain <commit>
```

The last two commands read remote-tracking branches, which record the state of the last fetch. Without the `git fetch` in front, they answer for an older moment.

> **GitHub, not Git.** A new ruleset on GitHub has "Block force pushes" enabled by default, and classic branch protection rules disable force pushes by default ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#block-force-pushes)). On a protected `main`, rewriting is normally not even available, and a revert commit is the only route.

## 11.3 `git restore`: copy a stored version over files or index entries

**In one sentence.** `git restore` copies a stored version of the named paths into the working tree, into the index, or into both, and moves no ref.

**Analogy.** A photocopier with two output trays: you pick the original and the tray, and whatever lay in the tray is replaced. The analogy breaks at the replaced sheet. You do not get it back.

**Precisely.** Chapter 4 (The Working Tree) introduced the command. Two choices define every form of it ([git-restore](https://git-scm.com/docs/git-restore)): the destination (the working tree by default, the index with `--staged`, both with `--staged --worktree`) and the source (`--source=<tree>`; without it, the index when only the working tree is written, and HEAD as soon as `--staged` is given). Every form that writes the working tree is 🔴. `--staged` alone is 🟡.

**Inside `.git`.** A restore rewrites files, or blob IDs in index entries. No object is created, no ref moves, and no reflog entry is written: there is no record to go back to.

**See it.** One file, `eval.yaml`, with a different threshold in each place: 0.70 in HEAD, 0.80 staged, 0.90 on disk. Every command below starts from a fresh copy of this state.

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

Plain `git restore` copies the index over the file. The edit to 0.90 is destroyed and the staged 0.80 stays:

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

`--staged` copies HEAD over the index entry and leaves the file alone. This is "unstage":

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

`git reset -- <path>` is the older spelling of the same operation. The result is identical, and reset adds a status line:

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

In both transcripts the staged version, 0.80, is no longer in the index, and it is not on disk either, because the file had moved on to 0.90. A version that existed only in the index is now a blob that nothing names (section 11.5 shows how to find one).

With `--source` the content comes from a commit. Without `--staged`, only the file is written, so the index still holds 0.80 and the status stays `MM`:

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

Add `--staged --worktree` and both places receive the old version. The last command proves that HEAD did not move: this is an old version of one file placed on top of the current commit, ready to be committed as a new change.

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

The remaining form, `git restore --staged --worktree <path>`, sets both places to HEAD's version. Older scripts write `git checkout -- <path>` for `git restore <path>`, `git reset HEAD <path>` for `git restore --staged <path>`, and `git checkout <commit> -- <path>` for the last transcript, index included (`labs/run ch11/restore-variants` shows this one).

**Restoring part of a file.** `git restore -p` walks through the differences hunk by hunk and asks about each one. Here `score.py` has two unstaged changes, a debug line and a real fix. Answering `y` to the first hunk and `n` to the second discards only the debug line. The demo pipes the two answers in, so each prompt is followed directly by the next output:

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

`-p` also combines with `--staged` and with `--source`.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git restore --staged <path>`, `git reset -- <path>` | unchanged | entries for `<path>` copied from HEAD | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git restore --staged --worktree <path>` | `<path>` overwritten from HEAD | copied from HEAD | unchanged | unchanged | unchanged | unchanged | unchanged |

The rows for `git restore <path>` and the two `--source` forms are in the state table of Chapter 4, section 4.7.

The same section answers the five questions for the 🔴 forms. In short: they destroy unstaged edits in the named paths without asking, the preview is `git diff -- <path>` (or `git diff <commit> -- <path>`), and nothing brings back content that was never staged.

**In production.** An evaluation regressed after someone tuned `prompts/system.txt` three commits ago, and those commits also contain good changes. `git restore --source=<good commit> prompts/system.txt` followed by an ordinary commit puts one file back and leaves history intact. It is safe on shared branches, because it only adds a commit (Lab 8.7, card 4).

## 11.4 `git reset`: move the branch, then choose how far the change spreads

**In one sentence.** 🟡 `git reset <commit>` makes the current branch point at `<commit>`, and its mode decides whether the index (`--mixed`, the default) and the working tree (`--hard`) are rewritten to match.

**Analogy.** A bookmark in a lab notebook. `--soft` moves the bookmark back. `--mixed` also clears the page you had drafted for the next entry. `--hard` also clears the desk. The analogy breaks in a useful way: no page is torn out. The entries after the bookmark stay in the notebook, and Git discards unmarked pages only after weeks (section 11.5).

**Precisely.** With a commit argument and no path, reset does up to three things ([git-reset](https://git-scm.com/docs/git-reset)):

1. It writes the current commit ID to `ORIG_HEAD` and makes the branch that HEAD points at name `<commit>`. `--soft` does only this.
2. It rewrites the index to match `<commit>`. `--mixed` does this as well.
3. It rewrites the tracked files in the working tree to match `<commit>`. Only `--hard` does this.

`<commit>` defaults to HEAD. So `git reset` alone unstages everything, and `git reset --hard` alone discards every uncommitted change to tracked files. On a detached HEAD there is no branch to move, and HEAD itself is rewritten.

**See it.** The starting state is the one from section 11.3: 0.70 in HEAD (commit `9d940ca`), 0.80 in the index, 0.90 on disk. Each mode runs in its own copy.

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

The log lost a commit and HEAD now holds 0.60. The index and the file are untouched. The status is still `MM`, but it is now measured against the older commit: `git commit` at this point would record 0.80 directly on top of `d44696e`.

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

The index now equals the new HEAD, and Git reports what is left as unstaged. The file still says 0.90.

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

| `eval.yaml` in | HEAD | Index | Working tree | `git status -s` |
|---|---|---|---|---|
| before | 0.70 | 0.80 | 0.90 | `MM` |
| after `git reset --soft HEAD~1` | 0.60 | 0.80 | 0.90 | `MM` |
| after `git reset --mixed HEAD~1` | 0.60 | 0.60 | 0.90 | ` M` |
| after `git reset --hard HEAD~1` | 0.60 | 0.60 | 0.60 | clean |

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

The file `HEAD` still says `ref: refs/heads/main`. What changed is the content of `refs/heads/main`. `ORIG_HEAD` holds the previous ID, and both reflogs gained the line `reset: moving to HEAD~1`. No object was deleted: commit `9d940ca` is still in the object database.

**Picture.**

```text
before                                    after git reset HEAD~1 (any mode)

4d17008---d44696e---9d940ca               4d17008---d44696e            main  (HEAD -> main)
                    main (HEAD -> main)                    \
                                                            9d940ca    no branch: ORIG_HEAD, HEAD@{1}, main@{1}
```

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git reset --soft <commit>` | unchanged | unchanged | file unchanged; resolves to `<commit>` | set to `<commit>` | `ORIG_HEAD` written; one reflog line each for HEAD and the branch | unchanged | unchanged |
| `git reset [--mixed] <commit>` | unchanged | rewritten to match `<commit>` | as above | set to `<commit>` | as above | unchanged | unchanged |
| `git reset --hard <commit>` | tracked files rewritten to match `<commit>`; uncommitted changes destroyed | rewritten to match `<commit>` | as above | set to `<commit>` | as above | unchanged | unchanged |

**`ORIG_HEAD`.** `ORIG_HEAD` holds one commit ID. The manual says it is created by commands that move HEAD "in a drastic way" (`git am`, `git merge`, `git rebase`, `git reset`), to record where HEAD was before ([gitrevisions](https://git-scm.com/docs/gitrevisions)). Resetting to it undoes the reset:

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

The undo was itself a reset, so it overwrote `ORIG_HEAD`, which now names `d44696e`. `ORIG_HEAD` is one slot, not a history, and more commands write it than the manual lists. Here a merge is followed by a stash:

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

After the merge, `ORIG_HEAD` named `5522f41`, the commit to go back to. `git stash push` ends with an internal reset to HEAD, every reset writes `ORIG_HEAD`, and so it now names the merge commit itself: `git reset --hard ORIG_HEAD` would leave the merge in place. The rule is to use `ORIG_HEAD` only as the very next command. After anything else, read the reflog, which has the whole sequence:

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

**In production.** Three commits named "wip", "wip 2" and "fix typo" before a review: `git reset --soft @{u}` moves the branch back to what is pushed and leaves the combined change staged for one clean commit (Lab 8.7, card 1). A commit that mixes a refactoring with a behavior change: `git reset HEAD~1` leaves both in the working tree, unstaged, ready to be split with `git add -p` (Chapter 5).

## 11.5 Why `git reset --hard` is 🔴

`--soft` and `--mixed` never write a file. `--hard` overwrites files, and what that costs depends on one question for each piece of work: **did Git ever store it as an object?** The demo puts four kinds of work into one repository:

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

There is the committed change `e574174`; `sweep.yaml`, staged and never committed; the edit to `metrics.txt`, never staged; and `notes.txt`, untracked.

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

**Committed work: the reflog has it.** The reset moved a ref and deleted no object, and the reflog recorded the move:

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

**Staged work: an object without a name.** `git add` wrote the content of `sweep.yaml` into the object database as a blob. The hard reset removed the index entry, the only thing that referred to it. `git fsck --lost-found` lists objects that nothing refers to and writes a copy of each under `.git/lost-found/`:

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

The content is back, the file name is not: a blob stores content only, and the name lived in the index entry. After a reset with ten staged files you get ten anonymous blobs and identify them by reading them. (On Git 2.55 `--lost-found` does not count reflog entries as references: run one step earlier, it would have listed commit `e574174` too.)

**Never-staged work: nothing to find.** `git hash-object --stdin` computes the ID that a piece of content would have. For the staged file the object exists. For the unstaged edit it does not:

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

**Untracked files: untouched, with one exception.** `notes.txt` survived because a reset touches only paths that are in the index or in the target commit. The exception is an untracked file whose path the target commit tracks. Here `sweep.yaml` was removed from tracking one commit ago, and the copy on disk holds two days of tuning:

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

`--keep` refused. `--hard` overwrote the file without a word. The manual admits it in one clause: `--hard` "may overwrite untracked files".

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

How long the first two kinds survive is set by two defaults ([git-config](https://git-scm.com/docs/git-config)). A reflog entry for a commit that its branch no longer reaches is kept for 30 days (`gc.reflogExpireUnreachable`), and garbage collection removes unreachable objects once they are older than two weeks (`gc.pruneExpire`). Chapter 13 (Recovery) covers the reflog and `git fsck` in full.

For this 🔴 command:

- **What it changes:** the branch ref, the index, and every tracked file that differs from the target commit.
- **What it can destroy:** every uncommitted change to tracked files, and untracked files that are in the target's way.
- **How to preview:** three read-only commands.

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

- **How to recover:** commits through the reflog or `ORIG_HEAD`, staged content through `git fsck --lost-found`, nothing else at all.
- **When it is appropriate:** when `git status` is clean, or after you have read `git diff HEAD` and want none of it. Otherwise turn the work into objects first, with two commands:

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

The stash entry holds the uncommitted work and the branch holds the commits. Delete both once you are sure.

## 11.6 `--keep` and `--merge`: resets that check before they overwrite

**In one sentence.** 🟡 `git reset --keep <commit>` moves the branch like `--hard`, carries your uncommitted changes across, and refuses to run when it would have to overwrite one of them; 🔴 `git reset --merge <commit>` does the same for unstaged changes and throws staged changes away.

**Precisely.** Both modes update the files that differ between HEAD and `<commit>`, and they differ in what happens to your local changes ([git-reset](https://git-scm.com/docs/git-reset)).

- `--keep` leaves local changes in all other files alone. The index is reset, so a staged change comes out unstaged. If a file that must be rewritten has local changes, the reset aborts and nothing moves.
- `--merge` keeps unstaged changes and discards staged ones, from the index and from the file. It exists for backing out of a merge, where whatever is staged is merge output and should go.

**See it.** One commit to drop (it changed `rank.py`), a staged change in `serve.yaml` (batch size 32 to 64) and an unstaged change in `metrics.txt` (0.71 to 0.74):

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

After `--merge` the unstaged edit to `metrics.txt` is still there, and the staged `batch_size: 64` is gone: the file says 32 again. `--hard` from the same state loses both (`labs/run ch11/reset-keep-merge`).

When the local change is in a file that the dropped commit also changed, `--keep` stops:

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

The branch did not move. The message speaks of a merge because `--keep` carries local changes across the move the way a branch switch does (the Git 1.7.1 release notes introduce the option with that comparison).

| Situation | `--keep` | `--merge` | `--hard` |
|---|---|---|---|
| Staged change in a file the reset does not rewrite | kept, becomes unstaged | discarded | discarded |
| Unstaged change in such a file | kept | kept | discarded |
| Unstaged change in a file the reset must rewrite | refuses | refuses | discarded |
| Staged change in a file the reset must rewrite | refuses | discarded | discarded |
| Untracked file at a path the target commit tracks | refuses | refuses | overwritten |

The rule that follows: to drop commits, type `--keep`, not `--hard`. On a clean tree the two do the same thing. On a dirty tree `--keep` carries your work across or stops and says why.

`--merge` earns its 🔴 through staged work only: preview with `git diff --cached`. Its proper uses are `git reset --merge ORIG_HEAD`, which undoes a completed merge and keeps unrelated edits (section 11.13), and `git reset --merge` without a commit, which clears a conflicted index (section 11.11).

In the state table of section 11.4, both modes read like `--hard` in every column except Working tree, where the table above applies.

## 11.7 `git commit --amend`: a soft reset plus a new commit

**In one sentence.** 🟡 `git commit --amend` replaces the last commit with a new commit that has the same parent and is built from the current index.

**Precisely.** Git's manual calls it "a rough equivalent" of `git reset --soft HEAD^`, some changes, and `git commit -c ORIG_HEAD` ([git-commit](https://git-scm.com/docs/git-commit)). Chapter 6 (Commits) dissects the commit object that results. Here the equivalence is run both ways from one starting state: a line that was forgotten in the last commit.

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

Both routes end with a commit whose parent is `9a98a06` and whose tree is `b35836e`. The two commit IDs differ only because the committer timestamps differ. An amend is therefore a rewrite of exactly one commit, and the rule of section 11.2 applies: private history only. Chapter 6 shows the diverged branch that results from amending a pushed commit.

One difference matters when you want the old commit back. `--amend` does not write `ORIG_HEAD`. The previous commit is one step back in the reflog:

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

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git commit --amend` | unchanged | unchanged; it becomes the tree of the new commit | file unchanged; resolves to the new commit | set to the new commit | new commit object; reflog line `commit (amend)`; `ORIG_HEAD` not written | unchanged | unchanged |

## 11.8 `git revert`: a new commit that applies the inverse change

**In one sentence.** 🟡 `git revert <commit>` adds a commit whose change is the opposite of what `<commit>` changed, and removes nothing.

**Analogy.** A reversing entry in a ledger. A posted entry is never erased. A second entry with the opposite sign is posted, and both stay visible. The analogy breaks in two places. A ledger reversal always nets to zero, while a revert is computed against the files as they are now, so later changes to the same lines produce a conflict. And a revert reverses one commit, not everything since.

**Precisely.** A revert is a three-way merge (Chapter 8, Merge) with unusual inputs: the base is the commit being reverted, "ours" is HEAD, and "theirs" is the parent of the reverted commit ([How git cherry-pick and revert use 3-way merge](https://jvns.ca/blog/2023/11/10/how-cherry-pick-and-revert-work/)). Chapter 10 (Cherry-pick) shows the mirror image. Three consequences follow. Any commit in the history can be reverted, not only the last. A revert can conflict. And the result is an ordinary commit on top of HEAD, so the branch only moves forward.

**See it.** `d51208b` disabled a cache. One more commit has been made since.

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

The log grew by one commit, and `d51208b` is still in it. The cache is on again, and the timeout change of `a49e359` is untouched.

**Inside `.git`.**

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

One new commit, with the previous HEAD commit as its only parent and a generated message. The reflog line starts with `revert:`. `ORIG_HEAD` is not written. While a revert is stopped at a conflict, `REVERT_HEAD` names the commit being reverted and `.git/sequencer/` holds the steps still to do.

**Three refusals.** Reverting the same commit again finds nothing to commit:

<!-- snippet: ch11/revert-basics/04-already-reverted -->
```text
$ git revert --no-edit d51208b
On branch main
nothing to commit, working tree clean
[exit status: 1]
```
<!-- /snippet -->

On `git revert`, `-m` is not a message but the parent number for reverting a merge (section 11.9). The reason for a revert goes into the editor, which `git revert` opens when it runs in a terminal:

<!-- snippet: ch11/revert-basics/05-m-is-not-a-message -->
```text
$ git revert -m "Cache must stay on" HEAD~1
error: option `mainline' expects a number greater than zero
[exit status: 129]
```
<!-- /snippet -->

And the index must match HEAD. The manual asks for a clean working tree; Git 2.55 accepts unstaged edits in files that the revert does not touch:

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

**Several commits.** A range `A..B` excludes `A` and is reverted newest first, one revert commit per original:

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

With `-n` (`--no-commit`) the inverse changes go into the index and the working tree and nothing is committed, so one commit of your own can carry them all:

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

**Conflicts.** `a49e359` changed the timeout from 30 to 5. A later commit changed it from 5 to 8. The revert wants to turn 5 back into 30, and the line no longer says 5:

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

The three index stages prove the "Precisely" paragraph. Stage 1, the base, is the file as it is in `a49e359`, the commit being reverted. Stage 2 is HEAD's version. Stage 3 is the file in the parent of `a49e359`. Git cannot know whether 8 or 30 is right today. You decide, stage the result and continue:

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

**A range that stops halfway.** When the second revert of a range conflicts, the first is already committed. Here `git revert --no-edit HEAD~4..HEAD~2` has stopped at its second step:

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

| Exit | Result |
|---|---|
| `git revert --continue` | After you resolve and `git add`: commits this step and runs the remaining ones |
| `git revert --skip` | Drops this step, keeps the reverts already made, runs the remaining ones |
| `git revert --abort` | Returns the branch to the commit recorded in `.git/sequencer/head`; revert commits already made leave the branch |
| `git revert --quit` | Forgets the sequence; keeps the reverts already made and leaves the conflict in the index and in the files |

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

`labs/run ch11/revert-sequence` shows `--quit` and `--skip` from the same stopped state.

**Picture.**

```text
before                                      after git revert d51208b

6cde22d--a49e359--d51208b--73572b2          6cde22d--a49e359--d51208b--73572b2--124de33
                           main (HEAD)                                          main (HEAD)

                                            tree of 124de33 = tree of 73572b2 with the change of d51208b undone
```

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git revert <commit>` | files touched by the inverse change rewritten | updated to the tree of the new commit | file unchanged; resolves to the new commit | advanced by one commit | new tree and commit; reflog line `revert:` | unchanged until you push | unchanged until you push |
| `git revert -n <commit>` | inverse change applied | inverse change staged | unchanged | unchanged | `REVERT_HEAD` and `MERGE_MSG` until you commit | unchanged | unchanged |

**In production.** A change that raised a batch size was merged, deployed by CI, and exhausts memory on the feature workers. Three teammates have pulled it. `git revert <commit>` followed by `git push` needs no force, takes the same route as any other commit (a pull request, if `main` requires one), and reaches every clone as a normal update. The Git FAQ names this as the usual way ([gitfaq](https://git-scm.com/docs/gitfaq)), and the revert manual strongly recommends that the message explain why. Lab 8.2 runs the incident, including the teammate's side.

## 11.9 Reverting a merge, and the re-merge problem

**In one sentence.** `git revert -m 1 <merge>` undoes the content that a merge brought into the branch, and leaves the merge itself in the commit graph, which changes what every later merge of the same branch does.

**Precisely.** A merge commit has two parents, so "the change it made" has two meanings. `-m <parent-number>` (`--mainline`) chooses: the inverse is computed relative to that parent. On a branch that receives feature branches, the first parent is the branch's own previous tip (Chapter 8, Merge), so `-m 1` takes out what the merge brought in.

**See it.**

<!-- snippet: ch11/revert-merge/01-merge -->
```text
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 rank.py   | 2 ++
 rerank.py | 2 ++
 2 files changed, 4 insertions(+)
 create mode 100644 rerank.py
$ git log --oneline --graph
*   27bb9f5 Merge branch 'feature/reranker'
|\  
| * c3762df Call the reranker from the ranker
| * 719cc13 Add cross-encoder reranker
* | 31a221c Record baseline metrics
|/  
* fbb8230 Add BM25 ranker and serving config
$ ls
metrics.txt
rank.py
rerank.py
serve.yaml
```
<!-- /snippet -->

<!-- snippet: ch11/revert-merge/02-revert-needs-m -->
```text
$ git revert --no-edit HEAD
error: commit 27bb9f5a47a08961498a25b25288c07070ab2576 is a merge but no -m option was given.
fatal: revert failed
[exit status: 128]
$ git show -s --format="%h has parents: %p" HEAD
27bb9f5 has parents: 31a221c c3762df
$ git revert --no-edit -m 1 HEAD
[main 7e5a38e] Revert "Merge branch 'feature/reranker'"
 Date: Mon Sep 7 10:14:00 2026 +0530
 2 files changed, 4 deletions(-)
 delete mode 100644 rerank.py
$ ls
metrics.txt
rank.py
serve.yaml
```
<!-- /snippet -->

`rerank.py` is gone from `main`, and so is the import line in `rank.py`. The generated message records which parent was treated as the mainline:

<!-- snippet: ch11/revert-merge/03-revert-message -->
```text
$ git show -s --format=%B HEAD
Revert "Merge branch 'feature/reranker'"

This reverts commit 27bb9f5a47a08961498a25b25288c07070ab2576, reversing
changes made to 31a221c51824ee599e5d3059dd928398b65a63e6.

$ git log --oneline --graph -3
* 7e5a38e Revert "Merge branch 'feature/reranker'"
*   27bb9f5 Merge branch 'feature/reranker'
|\  
| * c3762df Call the reranker from the ranker
```
<!-- /snippet -->

The revert commit `7e5a38e` is an ordinary commit on top of the merge. It changed content. It did not change the graph, and no commit can: `27bb9f5` is still an ancestor of `main`, and through its second parent so are both commits of the feature branch. Git's how-to on this situation says the same: a revert undoes the data a merge brought, and none of its effect on history ([revert-a-faulty-merge](https://github.com/git/git/blob/v2.56.0/Documentation/howto/revert-a-faulty-merge.adoc)).

**The problem.** Try to merge the branch again:

<!-- snippet: ch11/revert-merge/04-remerge-brings-nothing -->
```text
$ git merge feature/reranker
Already up to date.
$ git merge-base main feature/reranker
c3762df49c6a0dd31105d001abb9e995132ca99e
$ git rev-parse feature/reranker
c3762df49c6a0dd31105d001abb9e995132ca99e
```
<!-- /snippet -->

The merge base of `main` and the branch is the branch tip: for Git the branch is already merged. The dangerous variant looks like a success. The team fixes the bug with one more commit on the branch and merges:

<!-- snippet: ch11/revert-merge/05-remerge-brings-only-the-fix -->
```text
$ git log --oneline main..feature/reranker
6b4e788 Cap reranker candidates at 50
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 serve.yaml | 1 +
 1 file changed, 1 insertion(+)
$ ls
metrics.txt
rank.py
serve.yaml
$ cat serve.yaml
timeout_s: 30
rerank_top_k: 50
$ cat rank.py
def score(q, d):
    return bm25(q, d)
```
<!-- /snippet -->

No conflict, no warning. `main` received the fix for a feature it does not contain: there is no `rerank.py` and no import.

```text
Observed behavior : After a merge was reverted, merging the fixed branch brings only the new commit.
Git state         : merge-base(main, feature/reranker) is c3762df, the old tip of the branch.
Mechanism         : A merge combines what each side changed since the merge base. The first merge
                    made the old branch commits ancestors of main, so only the commit after c3762df
                    counts as the branch's change. On main's side the revert is a change since the
                    base (it deletes the feature), nothing opposes it, and it stays.
Root cause        : The revert removed the content of the merge and left the merge in the graph.
Why Git does this : Merge reads the graph, not intentions. The manual says that reverting a merge
                    "declares that you will never want the tree changes brought in by the merge".
Correct fix       : Revert the revert and then merge, or recreate the branch as new commits.
Prevention        : Write the re-merge procedure into the message of the revert commit. Where you
                    can, revert the one faulty commit and keep the merge.
```

**Way out 1: revert the revert, then merge.**

<!-- snippet: ch11/revert-merge/06-revert-the-revert -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at 7e5a38e Revert "Merge branch 'feature/reranker'"
$ git revert --no-edit 7e5a38e
[main 4b3560c] Reapply "Merge branch 'feature/reranker'"
 Date: Mon Sep 7 10:30:00 2026 +0530
 2 files changed, 4 insertions(+)
 create mode 100644 rerank.py
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 serve.yaml | 1 +
 1 file changed, 1 insertion(+)
$ ls
metrics.txt
rank.py
rerank.py
serve.yaml
```
<!-- /snippet -->

The first command takes the half-working merge away again. `4b3560c` reverts the revert and brings the content of the first merge back; Git 2.55 names such a commit `Reapply "..."`. The merge then adds the fix:

<!-- snippet: ch11/revert-merge/07-final-graph -->
```text
$ git log --oneline --graph
*   018849f Merge branch 'feature/reranker'
|\  
| * 6b4e788 Cap reranker candidates at 50
* | 4b3560c Reapply "Merge branch 'feature/reranker'"
* | 7e5a38e Revert "Merge branch 'feature/reranker'"
* | 27bb9f5 Merge branch 'feature/reranker'
|\| 
| * c3762df Call the reranker from the ranker
| * 719cc13 Add cross-encoder reranker
* | 31a221c Record baseline metrics
|/  
* fbb8230 Add BM25 ranker and serving config
$ cat rank.py
from rerank import rerank

def score(q, d):
    return bm25(q, d)
```
<!-- /snippet -->

**Picture.** The same history:

```text
          719cc13---c3762df-------------------------------6b4e788      feature/reranker
         /                 \                                     \
fbb8230---31a221c-----------27bb9f5----7e5a38e----4b3560c---------018849f   main (HEAD)
                            merge      revert     revert of the   second
                                       -m 1       revert          merge
```

**Way out 2: recreate the branch.** New commits are not ancestors of `main`, so an ordinary merge brings all of them. A plain `git rebase main` does not create them. It replays only what `main` lacks:

<!-- snippet: ch11/revert-merge-rebuild/01-plain-rebase-leaves-the-work-out -->
```text
$ git log --oneline --graph --all
* 52be493 Cap reranker candidates at 50
| * 9a2eb67 Revert "Merge branch 'feature/reranker'"
| *   27bb9f5 Merge branch 'feature/reranker'
| |\  
| |/  
|/|   
* | c3762df Call the reranker from the ranker
* | 719cc13 Add cross-encoder reranker
| * 31a221c Record baseline metrics
|/  
* fbb8230 Add BM25 ranker and serving config
$ git rebase main feature/reranker
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/reranker.
$ git log --oneline main..feature/reranker
2b155de Cap reranker candidates at 50
$ ls
metrics.txt
rank.py
serve.yaml
```
<!-- /snippet -->

One commit was replayed, on top of the revert, and the feature is still missing. What works is `git rebase --no-ff` from the commit where the branch started, an option the manual documents for exactly this case ([git-rebase](https://git-scm.com/docs/git-rebase)):

<!-- snippet: ch11/revert-merge-rebuild/02-recreate-the-branch -->
```text
# Where the branch started: the merge base of the two parents of the reverted merge.
$ git merge-base 27bb9f5^1 27bb9f5^2
fbb82301684fb07a59ac805d60f313294b62d3d5
$ git rebase --no-ff fbb8230 feature/reranker
Current branch feature/reranker is up to date, rebase forced.
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feature/reranker.
$ git log --oneline --graph --all
* 910d8d3 Cap reranker candidates at 50
* e9aea46 Call the reranker from the ranker
* b981ce8 Add cross-encoder reranker
| * 9a2eb67 Revert "Merge branch 'feature/reranker'"
| *   27bb9f5 Merge branch 'feature/reranker'
| |\  
| | * c3762df Call the reranker from the ranker
| | * 719cc13 Add cross-encoder reranker
| |/  
|/|   
| * 31a221c Record baseline metrics
|/  
* fbb8230 Add BM25 ranker and serving config
```
<!-- /snippet -->

The three commits have new IDs and hang off `fbb8230` beside the old ones. `git merge feature/reranker` now brings `rerank.py`, the import and the fix (`labs/run ch11/revert-merge-rebuild`). The price is a rewritten feature branch (Chapter 9, Rebase).

**Squash merges do not have the problem.** If the branch went in as one ordinary commit (`git merge --squash`), there is no second parent, the branch commits never became ancestors of `main`, and the merge base stays where the branch started. After a plain revert of that commit, a later merge brings the whole branch:

<!-- snippet: ch11/revert-squash-remerge/02-remerge-brings-everything -->
```text
$ git log --oneline -1 $(git merge-base main feature/reranker)
fbb8230 Add BM25 ranker and serving config
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 rank.py    | 2 ++
 rerank.py  | 2 ++
 serve.yaml | 1 +
 3 files changed, 5 insertions(+)
 create mode 100644 rerank.py
$ ls
metrics.txt
rank.py
rerank.py
serve.yaml
$ git log --oneline --graph
*   18eb394 Merge branch 'feature/reranker'
|\  
| * 5eedafc Cap reranker candidates at 50
| * c3762df Call the reranker from the ranker
| * 719cc13 Add cross-encoder reranker
* | f3affb6 Revert "Add cross-encoder reranker (squashed)"
* | e195948 Add cross-encoder reranker (squashed)
* | 31a221c Record baseline metrics
|/  
* fbb8230 Add BM25 ranker and serving config
```
<!-- /snippet -->

> **GitHub, not Git.** The **Revert** button on a merged pull request "creates a new pull request that reverts the original merge commit" ([Reverting a pull request](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/reverting-a-pull-request)), and `gh pr revert <number>` does the same from the command line ([manual](https://cli.github.com/manual/gh_pr_revert)). This is described from the documentation, not run here. The page says nothing about a later re-merge. By the mechanics above, a pull request that was merged with a merge commit and then reverted needs one of the two ways out before its branch is merged again.

**In production.** Reverting a merge has a second cost: for `git bisect` the revert is one large commit that undoes many small ones, and so is the later revert of the revert. The how-to therefore advises finding and reverting the single faulty commit, or fixing forward, and reverting a whole merge only when the merge as such was the mistake. The state table of section 11.8 applies to `git revert -m 1` unchanged.

## 11.10 `git clean`: the undo that has no undo

`git restore` and `git reset --hard` leave untracked files alone (section 11.5). The command that removes them is 🔴 `git clean`, the only undo whose effect no reflog, no `git fsck` and no stash can reverse, because an untracked file was never an object. Chapter 4 (The Working Tree), section 4.14, explains every option. What matters for undo is shown here in a repository with untracked files, ignored files, a nested repository and one tracked edit:

<!-- snippet: ch11/clean/01-status -->
```text
$ git status -s --ignored
 M serve.yaml
?? debug_dump.json
?? scratch/
?? vendor/
!! .env
!! __pycache__/
!! train.log
```
<!-- /snippet -->

<!-- snippet: ch11/clean/03-dry-runs -->
```text
$ git clean -n
Would remove debug_dump.json
$ git clean -n -d
Would remove debug_dump.json
Would remove scratch/
Would skip repository vendor/tokenizers
$ git clean -n -d -X
Would remove .env
Would remove __pycache__/
Would remove train.log
$ git clean -n -d -x
Would remove .env
Would remove __pycache__/
Would remove debug_dump.json
Would remove scratch/
Would remove train.log
Would skip repository vendor/tokenizers
$ git clean -n -d -e scratch/
Would remove debug_dump.json
Would skip repository vendor/tokenizers
```
<!-- /snippet -->

Read the five dry runs as a blast radius that widens and narrows. Plain `-n` lists untracked files in the current directory. `-d` adds untracked directories. `-X` lists only ignored paths, which include `.env`. `-x` lists both kinds. `-e` protects a pattern. The nested repository `vendor/tokenizers` is never on the removal list, and the tracked edit to `serve.yaml` is not clean's business at all.

<!-- snippet: ch11/clean/04-clean -->
```text
$ git clean -f -d
Removing debug_dump.json
Removing scratch/
Skipping repository vendor/tokenizers
$ git status -s --ignored
 M serve.yaml
?? vendor/
!! .env
!! __pycache__/
!! train.log
```
<!-- /snippet -->

<!-- snippet: ch11/clean/05-gone-for-good -->
```text
$ printf '{"query": "q1", "scores": [0.9, 0.4]}\n' | git hash-object --stdin
d702a51f40a7856802f55fc97f9a9c06a50bcad4
$ git cat-file -t d702a51f40a7856802f55fc97f9a9c06a50bcad4
fatal: git cat-file: could not get object info
[exit status: 128]
$ git fsck
```
<!-- /snippet -->

The ID that the deleted file's content would have names no object, and `git fsck` has nothing to report.

- **What it changes:** the working tree only. It deletes untracked paths, and ignored ones too with `-x` or `-X`.
- **What it can destroy:** anything Git does not track: notebooks, results, `.env` files, datasets, checkpoints.
- **How to preview:** the same command with `-n` in place of `-f`. Git insists on one of them: without `-f`, `-n` or `-i` it refuses to run (`clean.requireForce`).
- **How to recover:** not through Git.
- **When it is appropriate:** after you have read the dry run line by line. When in doubt, `git stash push -u` clears the same untracked files and keeps them as objects (section 11.11).

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git clean -f [-d] [-x or -X]` | the listed untracked or ignored paths deleted | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |

## 11.11 Stash: uncommitted work parked as commits

**In one sentence.** 🟡 `git stash push` records the index and the working tree as commits that only `refs/stash` reaches, then resets both to HEAD, so that the work can be brought back later, on this commit or on another.

**Analogy.** A labelled tray. You slide the half-built work off the bench onto a tray, and the bench is clear for the urgent job. The analogy breaks in two places. The tray remembers which commit the work was based on, and putting it back onto a changed bench is a merge, which can conflict. And trays never leave your workshop: a stash is not pushed, not fetched, and not shown by `git log`.

**Precisely.** A stash entry is a commit whose tree is the state of your tracked files. Its first parent is the commit that was HEAD and its second parent records the index ([git-stash](https://git-scm.com/docs/git-stash)). With `-u`, a third parent holds the untracked files (Lab 8.6 reads one). `refs/stash` points at the newest entry, and older entries live in the reflog of that ref, hence the names `stash@{1}`, `stash@{2}`. `git stash apply` merges the entry's changes into the current files. `git stash pop` is `apply` followed by `drop`, and the drop happens only if the apply succeeded. Chapter 14C (Stash internals, rerere, attributes, hooks) opens the objects.

**Inside `.git`.** New commit objects, the ref `refs/stash` and its reflog `logs/refs/stash`. HEAD and the branch do not move. `ORIG_HEAD` is overwritten (section 11.4).

**Picture.**

```text
          .-----W      refs/stash -> W      W: the tracked files as they were on disk
         /     /                            I: the index as it was
   -----H-----I        main (HEAD -> main) stays at H; files and index are reset to H
```

**See it.** The starting state has one staged change, one unstaged change and one untracked file:

<!-- snippet: ch11/stash-basics/01-push -->
```text
$ git status -s
M  rank.py
 M serve.yaml
?? plan.md
$ git stash push -m "wip: blend dense scores"
Saved working directory and index state On main: wip: blend dense scores
$ git status -s
?? plan.md
$ git stash list
stash@{0}: On main: wip: blend dense scores
```
<!-- /snippet -->

The tracked changes are gone from the files. The untracked `plan.md` stayed: a plain stash takes tracked files only. `git stash show` summarizes an entry, and `-p` prints its full difference from the commit it was made on:

<!-- snippet: ch11/stash-basics/02-show -->
```text
$ git stash show
 rank.py    | 2 +-
 serve.yaml | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git stash show -p
diff --git a/rank.py b/rank.py
index 4b0bb9d..b29d4bd 100644
--- a/rank.py
+++ b/rank.py
@@ -1,2 +1,2 @@
 def score(q, d):
-    return bm25(q, d)
+    return 0.7 * bm25(q, d) + 0.3 * dense(q, d)
diff --git a/serve.yaml b/serve.yaml
index 946ab07..40933f2 100644
--- a/serve.yaml
+++ b/serve.yaml
@@ -1,2 +1,2 @@
-timeout_s: 30
+timeout_s: 10
 retries: 2
```
<!-- /snippet -->

**`apply` versus `pop`, and `--index`.**

<!-- snippet: ch11/stash-basics/03-apply -->
```text
$ git stash apply -q
$ git status -s
 M rank.py
 M serve.yaml
?? plan.md
$ git stash list
stash@{0}: On main: wip: blend dense scores
```
<!-- /snippet -->

After `apply` the entry is still in the list. `rank.py` was staged when it was stashed and came back unstaged. Only `--index` restores the split:

<!-- snippet: ch11/stash-basics/04-pop-index -->
```text
$ git stash pop --index
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   rank.py

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   serve.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	plan.md

Dropped refs/stash@{0} (3041fc614ff2d5678e22fcce3440c08ea4709d63)
$ git status -s
M  rank.py
 M serve.yaml
?? plan.md
$ git stash list
```
<!-- /snippet -->

`pop` dropped the entry and printed the ID of the commit it let go of. That line matters later.

**What goes into an entry.**

| Command | Goes into the entry | Left in your files and index |
|---|---|---|
| `git stash push` | staged and unstaged changes to tracked files | untracked files |
| `git stash push -u` | the same, plus untracked files (not ignored ones) | nothing: `git status` is clean |
| `git stash push --staged` | only what is staged | unstaged changes, untracked files |
| `git stash push --keep-index` | staged and unstaged changes, as without the option | the staged changes, still staged |
| `git stash push -- <path>` | changes to `<path>` only | everything else |

The two that are confused most often:

<!-- snippet: ch11/stash-basics/06-staged-only -->
```text
$ git status -s
M  rank.py
 M serve.yaml
?? plan.md
$ git stash push --staged -m "ranker change only"
Saved working directory and index state On main: ranker change only
$ git status -s
 M serve.yaml
?? plan.md
$ git stash show
 rank.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch11/stash-basics/07-keep-index -->
```text
$ git status -s
M  rank.py
 M serve.yaml
?? plan.md
$ git stash push --keep-index -m "everything; index left in place"
Saved working directory and index state On main: everything; index left in place
$ git status -s
M  rank.py
?? plan.md
$ git stash show
 rank.py    | 2 +-
 serve.yaml | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

`--staged` stashes the index and nothing else. `--keep-index` stashes everything and also leaves the staged part in place, so you can test exactly what you are about to commit. `labs/run ch11/stash-basics` shows `-u` and the pathspec form.

**A pop that conflicts.** Work is stashed, a hotfix changes the same line, and the stash comes back:

<!-- snippet: ch11/stash-conflict/01-stash-then-hotfix -->
```text
$ git status -s
 M serve.yaml
$ git stash push -m "wip: try a 10s timeout"
Saved working directory and index state On main: wip: try a 10s timeout
$ printf 'timeout_s: 20\nretries: 2\ncache: on\n' > serve.yaml
$ git commit -am "Hotfix: lower timeout to 20s"
[main 00eed5e] Hotfix: lower timeout to 20s
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch11/stash-conflict/02-pop-conflict -->
```text
$ git stash pop
Auto-merging serve.yaml
CONFLICT (content): Merge conflict in serve.yaml
On branch main
Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   serve.yaml

no changes added to commit (use "git add" and/or "git commit -a")
The stash entry is kept in case you need it again.
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch11/stash-conflict/03-conflict-state -->
```text
$ git status -s
UU serve.yaml
$ cat serve.yaml
<<<<<<< Updated upstream
timeout_s: 20
=======
timeout_s: 10
>>>>>>> Stashed changes
retries: 2
cache: on
$ git stash list
stash@{0}: On main: wip: try a 10s timeout
```
<!-- /snippet -->

It is an ordinary conflict (Chapter 8, Merge) with its own labels: `Updated upstream` is the file as it is now, `Stashed changes` is the entry. The last line of the pop is the important one: the entry was kept. There are two ways on. Resolve the file, clear the conflict state with `git restore --staged` or `git add`, and drop the entry yourself:

<!-- snippet: ch11/stash-conflict/04-resolve-and-drop -->
```text
$ printf 'timeout_s: 10\nretries: 2\ncache: on\n' > serve.yaml
$ git restore --staged serve.yaml
$ git status -s
 M serve.yaml
$ git stash list
stash@{0}: On main: wip: try a 10s timeout
$ git stash drop
Dropped refs/stash@{0} (c94265dd6415b63fc30a245db496836c128b5b90)
$ git stash list
```
<!-- /snippet -->

Or back out with `git reset --merge` and use `git stash branch`. It creates a branch at the commit the entry was made on, applies the entry there, where it cannot conflict, and drops it:

<!-- snippet: ch11/stash-conflict/05-back-out-and-branch -->
```text
$ git reset --merge
$ git status -s
$ git stash branch try-10s-timeout
Switched to a new branch 'try-10s-timeout'
On branch try-10s-timeout
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   serve.yaml

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (c94265dd6415b63fc30a245db496836c128b5b90)
$ git log --oneline --decorate --all
00eed5e (main) Hotfix: lower timeout to 20s
6cde22d (HEAD -> try-10s-timeout) Add serving config
$ git stash list
```
<!-- /snippet -->

**A dropped entry.** 🔴 `git stash drop` and `git stash clear` delete the only ref to work that was never committed. The objects stay for a while, and with the ID that `drop` printed the entry can be put back:

<!-- snippet: ch11/stash-conflict/06-dropped-entry-by-id -->
```text
$ git stash show c94265d
 serve.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git stash store -m 'recovered: try a 10s timeout' c94265d
$ git stash list
stash@{0}: recovered: try a 10s timeout
```
<!-- /snippet -->

Without the ID, the stash manual's `git fsck --unreachable` recipe lists candidates (Lab 8.6). Preview any drop with `git stash show -p stash@{n}`, and drop an entry only when its content is committed elsewhere or you want none of it.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git stash push` | tracked files reset to HEAD; with `-u` untracked files removed | reset to HEAD (kept with `--keep-index`) | unchanged | unchanged | stash commits created; `refs/stash` and its reflog updated; `ORIG_HEAD` overwritten | unchanged | unchanged |
| `git stash apply`, `git stash pop` | entry's changes merged in; conflict markers possible | unchanged, or restored with `--index`; unmerged entries on conflict | unchanged | unchanged | `pop` removes the entry after a clean apply | unchanged | unchanged |
| `git stash drop`, `git stash clear` | unchanged | unchanged | unchanged | unchanged | entries removed from `refs/stash` and its reflog | unchanged | unchanged |

**In production.** An incident interrupts a refactoring: `git stash push -u -m "wip: per-tenant limits"`, fix, commit, `git stash pop`. Always give `-m`: without it entries are listed as `WIP on <branch>` plus the subject of the base commit, and five of those look alike. For work that must outlive the day, a commit on a branch is the better container: it shows in `git log`, can be pushed, and no single command drops it.

## 11.12 One table and one decision tree

"HEAD" is the commit that HEAD resolves to, "Branch" is the ref of the current branch, and "History" is the set of commits reachable from that branch.

| Command | HEAD | Branch | Index | Working tree | History |
|---|---|---|---|---|---|
| `git reset --soft <commit>` | moves to `<commit>` | set to `<commit>` | unchanged | unchanged | commits after `<commit>` leave the branch; the reflog keeps them |
| `git reset --mixed <commit>` (the default) | moves to `<commit>` | set to `<commit>` | matches `<commit>` | unchanged | as above |
| `git reset --hard <commit>` | moves to `<commit>` | set to `<commit>` | matches `<commit>` | matches `<commit>`; uncommitted changes destroyed | as above |
| `git reset --keep <commit>` | moves to `<commit>` | set to `<commit>` | matches `<commit>` | local changes carried across; refuses if they overlap | as above |
| `git reset --merge <commit>` | moves to `<commit>` | set to `<commit>` | matches `<commit>` | unstaged changes carried across, staged ones discarded | as above |
| `git reset -- <path>` | unchanged | unchanged | `<path>` from HEAD | unchanged | unchanged |
| `git restore <path>` | unchanged | unchanged | unchanged | `<path>` from the index | unchanged |
| `git restore --staged <path>` | unchanged | unchanged | `<path>` from HEAD | unchanged | unchanged |
| `git restore --source=<commit> <path>` | unchanged | unchanged | unchanged | `<path>` from `<commit>` | unchanged |
| `git restore --staged --worktree <path>` | unchanged | unchanged | `<path>` from HEAD | `<path>` from HEAD | unchanged |
| `git commit --amend` | moves to a new commit | set to the new commit | unchanged | unchanged | the last commit is replaced by a new one with the same parent |
| `git revert <commit>` | moves to a new commit | advanced by one commit | matches the new commit | inverse change applied | one commit added, none removed |

Read the Branch column first. "Set to" means the branch can lose commits: private history only. "Advanced" and "unchanged" are safe on a branch that other people have.

**The decision tree.**

```text
What do you want to undo?
|
+-- Changes that are not committed
|     |
|     +-- staged, and the edit should stay ......... git restore --staged <path>
|     +-- an unstaged edit, to be discarded ........ git diff <path>, then git restore <path>     (no way back)
|     +-- some hunks of a file ..................... git restore -p <path>                        (no way back)
|     +-- everything, possibly wanted later ........ git stash push -u -m "<why>"
|     +-- untracked files .......................... git clean -n [-d], then the same with -f     (no way back)
|
+-- Commits
      |
      +-- Can anyone else already have them?   git fetch; git branch -r --contains <commit>
            |
            +-- NO: private history, rewriting is allowed
            |     +-- last commit: content or message ...... git commit --amend
            |     +-- last commits: keep the changes ....... git reset --soft <commit>   (staged)
            |     |                                          git reset <commit>          (unstaged)
            |     +-- last commits: drop the changes ....... git reset --keep <commit>   (--hard only on a clean tree)
            |     +-- a merge made a moment ago ............ git reset --merge ORIG_HEAD
            |     +-- a commit further back ................ git rebase -i               (Chapter 9, Rebase)
            |
            +-- YES: shared history, add commits
                  +-- one commit ........................... git revert <commit>
                  +-- several commits ...................... git revert -n <A>..<B>, then git commit
                  +-- a merge .............................. git revert -m 1 <merge>, and plan the re-merge (11.9)
                  +-- one file back to an old version ...... git restore --source=<commit> <path>, then git commit
```

## 11.13 Worked scenarios

Seven situations, handled with the tree of section 11.12 in one clone whose `origin` is a bare repository on disk, so "pushed" is a real state. The demo ran scenario 3 before scenario 2, which is why scenario 2's log shows the commits of scenario 3.

**1. Undo the last commit, which is not pushed.** `ahead 1`, and no remote-tracking branch contains the commit: private history. `--soft` takes the commit off the branch and leaves its change staged.

<!-- snippet: ch11/scenarios/s1-undo-last-unpushed-commit -->
```text
$ git status -sb
## main...origin/main [ahead 1]
$ git branch -r --contains HEAD
$ git reset --soft HEAD~1
$ git status -sb
## main...origin/main
M  rank.py
$ git log --oneline -1
fc2e2d8 Record baseline metrics
```
<!-- /snippet -->

Use `git reset HEAD~1` to get the change back unstaged, and `git reset --keep HEAD~1` to drop it.

**2. A bad commit is on `main` and pushed.** `origin/main` contains `c6f2cfd`: shared history. Revert and push.

<!-- snippet: ch11/scenarios/s2-pushed-bad-commit -->
```text
$ git log --oneline
377247a Ignore local .env files
90e7514 Retry BM25 scoring with backoff
fc2e2d8 Record baseline metrics
c6f2cfd Disable retries
91788a6 Add BM25 ranker and serving config
$ git branch -r --contains c6f2cfd
  origin/main
$ git revert --no-edit c6f2cfd
[main 20cf7b0] Revert "Disable retries"
 Date: Mon Sep 7 10:27:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status -sb
## main...origin/main [ahead 1]
$ git push
To $LAB/ch11/scenarios/server.git
   377247a..20cf7b0  main -> main
```
<!-- /snippet -->

**3. Remove a file from the last commit, which is not pushed.** A `.env` file went in with `git add .`. `git rm --cached` removes the index entry and keeps the file, and `--amend` replaces the commit.

<!-- snippet: ch11/scenarios/s3-remove-file-from-last-commit -->
```text
$ git show --stat --format="%h %s" HEAD
ccecf13 Retry BM25 scoring with backoff

 .env    | 1 +
 rank.py | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git rm --cached .env
rm '.env'
$ git commit --amend --no-edit
[main 90e7514] Retry BM25 scoring with backoff
 Date: Mon Sep 7 10:17:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --stat --format="%h %s" HEAD
90e7514 Retry BM25 scoring with backoff

 rank.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status -s
?? .env
```
<!-- /snippet -->

The file is now untracked, so add it to `.gitignore` next (Chapter 4). The old commit `ccecf13` still contains the file and stays in your reflog, which is harmless for a commit that never left your machine. If a commit with a real secret was ever pushed, amending is not the fix: rotate the secret (Chapter 21, Security).

**4. Unstage.** The index entry goes back to HEAD's version and the file keeps the edit.

<!-- snippet: ch11/scenarios/s4-unstage -->
```text
$ git status -s
M  rank.py
 M serve.yaml
?? probe_output.txt
$ git restore --staged rank.py
$ git status -s
 M rank.py
 M serve.yaml
?? probe_output.txt
```
<!-- /snippet -->

**5. Discard local changes.** Tracked files: read `git diff`, then `git restore`. Untracked files: `git clean -n`, then `-f`. Neither step can be taken back. When in doubt, `git stash push -u` does the same job and keeps the content.

<!-- snippet: ch11/scenarios/s5-discard-local-changes -->
```text
$ git restore rank.py serve.yaml
$ git status -s
?? probe_output.txt
$ git clean -n
Would remove probe_output.txt
$ git clean -f
Removing probe_output.txt
$ git status -s
```
<!-- /snippet -->

**6. Undo a merge that is not pushed, with an unrelated edit in progress.** `git reset --merge ORIG_HEAD` puts the branch back on the commit before the merge and keeps the edit to `metrics.txt`. If anything has overwritten `ORIG_HEAD` since the merge, take the commit from the reflog.

<!-- snippet: ch11/scenarios/s6-undo-unpushed-merge -->
```text
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 rerank.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 rerank.py
$ git status -sb
## main...origin/main [ahead 2]
 M metrics.txt
$ git reset --merge ORIG_HEAD
$ git status -sb
## main...origin/main
 M metrics.txt
$ git log --oneline -1
20cf7b0 Revert "Disable retries"
```
<!-- /snippet -->

**7. Undo a merge that is pushed.** `origin/main` contains the merge: shared history. `git revert -m 1`, push, and write the re-merge plan of section 11.9 into the ticket.

<!-- snippet: ch11/scenarios/s7-undo-pushed-merge -->
```text
$ git log --oneline --graph -4
*   5777a43 Merge branch 'feature/reranker'
|\  
| * ecf26a5 Add cross-encoder reranker
* | 20cf7b0 Revert "Disable retries"
* | 377247a Ignore local .env files
$ git branch -r --contains HEAD
  origin/main
$ git revert --no-edit -m 1 HEAD
[main 0dd3130] Revert "Merge branch 'feature/reranker'"
 Date: Mon Sep 7 10:50:00 2026 +0530
 1 file changed, 2 deletions(-)
 delete mode 100644 rerank.py
$ git push
To $LAB/ch11/scenarios/server.git
   5777a43..0dd3130  main -> main
$ ls
metrics.txt
rank.py
serve.yaml
```
<!-- /snippet -->

## 11.14 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| Edits are gone after `git reset --hard` or `git restore` | `git reflog` lists commits only; `git fsck --lost-found` lists blobs for content that was once staged | `git cat-file -p <blob>` for staged content; nothing for the rest | `git status` first; `git stash push -u`; `--keep`, not `--hard` |
| `git reset --hard ORIG_HEAD` lands on the wrong commit | `git log -1 ORIG_HEAD`: a later reset, merge, rebase or stash rewrote the slot | Reset to the right reflog entry | Use `ORIG_HEAD` only as the very next command |
| `git push` is rejected as non-fast-forward after a reset or an amend | `git status -sb` shows `behind`: the commits you removed were already pushed | Save new work, `git reset --hard @{u}`, then `git revert` | `git branch -r --contains <commit>` before rewriting |
| A branch that was merged again lacks most of its changes | `git log --oneline main..<branch>` lists only the newest commits, and `main` has a `Revert "Merge ..."` commit | Revert the revert and merge again, or recreate the branch (section 11.9) | Put the re-merge procedure into the revert message |
| `git revert` stops with a conflict | `git status`; `git ls-files -s <path>` shows three stages | Resolve, `git add`, `git revert --continue`; or `--abort` | Revert early, before other commits build on the bad one |
| `git restore --source=<commit> .` deleted files | `git status` shows ` D`: tracked paths that the source lacks were removed | `git restore .` returns the index versions; unstaged edits stay lost (Lab 8.4) | Name the paths you mean |
| `git stash pop` reports a conflict and the entry is still listed | `git status` shows `UU` | Resolve and `git stash drop`, or `git reset --merge` and `git stash branch <name>` | Pop soon; keep stashes small |
| A pop was refused or failed, yet files from the entry are there | The entry was made with `-u`: on Git 2.55 a refused pop still writes its untracked files, and the next pop fails on them (transcript in Lab 8.6) | Compare with `git diff 'stash@{0}'` and `git show 'stash@{0}^3:<path>'`, then `git stash drop` | Clear local edits before popping |
| A stash entry was dropped by mistake | `drop` and `pop` print the ID | `git stash store -m "<message>" <id>`; without the ID, the `git fsck --unreachable` recipe of the stash manual | `git stash show -p` before `drop` |

## 11.15 When not to use it, and dangerous edge cases

**Do not rewrite what others have** (section 11.2).

> **Outdated advice.** Several widely viewed tutorials teach "`git reset --hard <old commit>`, then `git push -f`" as the way to undo pushed commits, including on the main branch ([example](https://www.youtube.com/watch?v=GTFaLDXag08&t=4115s)). The first step destroys your uncommitted work and the second destroys other people's commits on the server. On shared history the undo is `git revert`.

**No command in this chapter removes a secret.** A revert leaves it in history in plain sight. A reset or an amend leaves it in your reflog and, once pushed, on the server and in every clone and fork. The remedy is to rotate the secret (Chapter 21, Security).

**A revert does not win a merge.** If the same change exists on two branches and you revert it on one, merging the two keeps the change: one side changed the lines since the merge base, the other shows no net change, and Git takes the change. The Git FAQ has an entry on this ([gitfaq](https://git-scm.com/docs/gitfaq)), and Chapter 8 (Merge) demonstrates it (`labs/run ch08/revert-one-side`). After a revert on a release branch, check `main` separately.

**Do not revert a revert blindly.** It is right when the branch was fixed by adding commits. If the branch was rebuilt as new commits, a revert of the revert conflicts with them wherever they differ from the old ones, as the how-to warns: merge the rebuilt branch directly (section 11.9).

**`git restore .` at the top of a repository** is the working-tree half of `git reset --hard`, without `ORIG_HEAD` and without a reflog entry. With `--source` it also deletes tracked files that the source lacks.

**A stash is not a backup.** It lives in one repository, no push sends it, and one command drops it. Old entries also rot: the further the branch moves on, the likelier the pop conflicts.

## 11.16 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git restore --staged <path>`, `git reset -- <path>` | 🟡 | Index entries | `git diff --cached -- <path>` | `git add <path>`; `git fsck --lost-found` for a staged version that differed from the file |
| `git restore <path>`, `git restore -p <path>` | 🔴 | Files, from the index | `git diff -- <path>` | None for content that was never staged |
| `git restore --source=<commit> [--staged] [--worktree] <path>` | 🔴 | Files (and index) from a commit; deletes tracked paths the commit lacks | `git diff <commit> -- <path>` | None for unstaged edits |
| `git reset --soft <commit>` | 🟡 | Branch ref | `git log --oneline <commit>..HEAD` | The same mode with `ORIG_HEAD`, or the reflog |
| `git reset [--mixed] <commit>` | 🟡 | Branch ref and index | as above, and `git diff --cached` | as above |
| `git reset --keep <commit>` | 🟡 | Branch ref, index, files that differ between the two commits | as for `--soft` | as above |
| `git reset --merge <commit>` | 🔴 | As `--keep`; discards staged changes | `git diff --cached` | Commits: reflog. Staged content: `git fsck --lost-found` |
| `git reset --hard <commit>` | 🔴 | Branch ref, index, every tracked file | `git status -s`, `git diff HEAD --stat`, `git log --oneline <commit>..HEAD` | Commits: reflog. Staged content: `git fsck --lost-found`. Unstaged: none |
| `git commit --amend` | 🟡 | Replaces the last commit | `git diff --cached` | `git reset --soft HEAD@{1}` |
| `git revert <commit>`, `git revert -m 1 <merge>` | 🟡 | Adds one commit: the branch moves, index and files are updated, nothing is removed. After `-m 1`, a later merge of the same branch brings back nothing until the revert is reverted | `git show <commit>` | Revert the revert; before pushing, `git reset --keep HEAD~1` |
| `git revert -n <commit>` | 🟡 | Index and files | `git show <commit>` | `git revert --abort` |
| `git clean -n` | 🟢 | Nothing | it is the preview | not needed |
| `git clean -f [-d] [-x or -X]` | 🔴 | Deletes untracked (with `-x` or `-X`, ignored) files | the same options with `-n` | None through Git |
| `git stash push [-u]` | 🟡 | Saves index and files, then resets them to HEAD | `git status -s` | `git stash pop --index` |
| `git stash apply`, `git stash pop`, `git stash branch <name>` | 🟡 | Merges an entry into the files | `git stash show -p` | The entry is kept after a conflict; `git reset --merge` backs out |
| `git stash drop`, `git stash clear` | 🔴 | Removes one entry, or all | `git stash show -p stash@{n}` | `git stash store <id>` while the objects exist |

## 11.17 Version notes

> **Version note.** Older behavior: `git checkout -- <path>` and `git checkout <commit> -- <path>` restored files, and `git reset HEAD <path>` unstaged. Current behavior: `git restore` does these jobs, and the old forms still work. Since: introduced in Git 2.23 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.23.0.adoc)), no longer labelled experimental from Git 2.51 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc)). Recommended: write `restore`, read `checkout`.

> **Version note.** Older behavior: `git stash save "<message>"`. Current behavior: `git stash push -m "<message>"`, which also takes a pathspec; `save` is deprecated and still runs. Since: `push` in Git 2.13, deprecation in Git 2.16 ([git-stash](https://github.com/git/git/blob/v2.56.0/Documentation/git-stash.adoc)); `--staged` in Git 2.35 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.35.0.adoc)). Recommended: `git stash push -m`.

> **Version note.** Older behavior: a different default subject for a revert of a revert (not run here). Current behavior: `Reapply "<subject>"`, as in section 11.9. Since: Git 2.43, whose release notes say this default message "has been tweaked" ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.43.0.adoc)). Recommended: reword such subjects by hand, as the revert manual asks.

> **Unverified.** Two behaviors in this chapter were observed on Git 2.55.0 and are not stated in the manuals: `git fsck --lost-found` does not count reflog entries as references (section 11.5), and a refused `git stash pop` still writes the untracked files of the entry (section 11.14). Other versions were not tested. GitHub's page on reverting a pull request does not say how the Revert button treats squash-merged or rebase-merged pull requests.

## 11.18 Practice

- Labs 8.1 to 8.7 in the [Module 8 lab manual](../lab-manual/m08-undo.md): the reset prediction table, a revert of a pushed commit, a reverted merge and its re-merge, the restore variants, a safe clean, a stash with a pop conflict, and six scenario cards.
- Replay any transcript with `labs/run ch11/<demo>`. The sandbox stays in place, so you can continue by hand in it.
- Four drills, each in a sandbox left by a replay:
  1. In `ch11/reset-modes/ranker-hard`, find out which of the two lost versions, 0.80 and 0.90, still exists, and explain the difference.
  2. In `ch11/revert-basics/ranker-conflict`, predict whether `git revert d51208b` conflicts, then run it.
  3. In `ch11/revert-merge/ranker`, run `git switch -c scratch 27bb9f5` and `git revert -m 2 HEAD`. Explain which file disappeared and why.
  4. In `ch11/stash-basics/ranker`, bring the remaining entry back with `git stash branch`, and explain why that form cannot conflict.

## 11.19 Interview questions

1. A colleague asks for "the undo command". Name the five commands of this chapter and say which of working tree, index, branch ref and history each one writes.
2. HEAD, the index and the working tree hold three different versions of one file. What does each hold after `git reset --soft HEAD~1`, after `--mixed` and after `--hard`, and what does `git status -s` print?
3. An engineer ran `git reset --hard HEAD~3` in a dirty tree. What can you recover, with which commands and for how long, and what is gone? Why is that part gone?
4. What is `ORIG_HEAD`, which commands write it, and why is the reflog the more reliable tool?
5. When do you choose `git reset --keep` over `--hard`? What does `--merge` do to staged changes, and why was it designed that way?
6. Describe `git revert` as a three-way merge: what are base, ours and theirs? Use the answer to explain why reverting an old commit can conflict.
7. A bad commit is on `main` and the team has pulled it. Compare "revert and push" with "reset and force-push": what does each do to the server, to the teammates' clones and to CI?
8. You reverted a merge with `-m 1` last week. Today the fixed branch was merged again and the feature is incomplete. Explain the mechanism with the merge base and give two correct procedures. What would `-m 2` have undone, and why does a squash merge not show the problem?
9. Compare `git clean -fdx` with `git reset --hard`: which files does each destroy, and for which of them does Git still hold an object?
10. What is inside a stash entry and where is it stored? What happens when `git stash pop` conflicts? Give three reasons not to use the stash for long-term storage.

## 11.20 Sources

**Primary sources**

- [git-reset](https://git-scm.com/docs/git-reset) (with the tables in its "Discussion" section), [git-revert](https://git-scm.com/docs/git-revert), [git-restore](https://git-scm.com/docs/git-restore), [git-clean](https://git-scm.com/docs/git-clean), [git-stash](https://git-scm.com/docs/git-stash), [git-commit](https://git-scm.com/docs/git-commit), [git-rebase](https://git-scm.com/docs/git-rebase), [git-fsck](https://git-scm.com/docs/git-fsck), [git-config](https://git-scm.com/docs/git-config), [gitrevisions](https://git-scm.com/docs/gitrevisions) and [git(1)](https://git-scm.com/docs/git). The transcripts were checked against the local Git 2.55.0 copies (`git help -m <command>`).
- [How to revert a faulty merge](https://github.com/git/git/blob/v2.56.0/Documentation/howto/revert-a-faulty-merge.adoc), the how-to that the revert manual points to.
- [gitfaq](https://git-scm.com/docs/gitfaq), the entries on undoing a change that is already in the main branch and on a change reverted on one of two branches.
- Release notes [2.23.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.23.0.adoc), [2.35.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.35.0.adoc), [2.43.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.43.0.adoc), [2.51.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc), and 1.7.1 as shipped with Git 2.55.0 (directory `RelNotes` under the path that `git --html-path` prints).
- GitHub Docs: [Reverting a pull request](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/reverting-a-pull-request) and [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#block-force-pushes); GitHub CLI manual, [gh pr revert](https://cli.github.com/manual/gh_pr_revert).

**Secondary sources**

- Julia Evans, [How git cherry-pick and revert use 3-way merge](https://jvns.ca/blog/2023/11/10/how-cherry-pick-and-revert-work/).
- Pro Git, [Reset Demystified](https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified). Caveat: it contrasts `reset` with `git checkout` and does not mention `git restore`.
- Pro Git, [Undoing Things](https://git-scm.com/book/en/v2/Git-Basics-Undoing-Things) (old and new spellings side by side) and [Stashing and Cleaning](https://git-scm.com/book/en/v2/Git-Tools-Stashing-and-Cleaning). Caveat: the stash chapter mostly uses bare `git stash` and does not cover `--staged`.
- The Phase 0 report of this course, sections 4, 12 and 13, for the Stack Overflow figures and the retention defaults.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- [How to Undo Mistakes With Git Using the Command Line](https://www.youtube.com/watch?v=lX9hsdsAeTk), Tobias Günther for freeCodeCamp, 55 minutes, 24 November 2020: `git restore` including `-p`, amend, revert, reset, reflog recovery from 24:02. Caveat: `master` naming.
- [Revert and Reset Commits Like a Pro](https://www.youtube.com/watch?v=qF8CHHnWqXE), ProCodrr episode 6, Hindi, 56 minutes, March 2023: reset versus revert, with reflog recovery of a hard-reset commit. Caveat: `master`.

**Further reading**

- [Oh Shit, Git!?!](https://ohshitgit.com/), a short scenario list. Caveat: it uses the `checkout` and `reset` spellings.
