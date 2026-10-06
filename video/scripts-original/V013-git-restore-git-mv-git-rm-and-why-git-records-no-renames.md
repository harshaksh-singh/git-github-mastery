# V013: git restore, git mv, git rm, and why Git records no renames

- **Part.** 1: Foundations
- **Module.** 2
- **Planned minutes.** 22
- **Prerequisites.** V012
- **Textbook sections.** [Chapter 4: The Working Tree](../../textbook/ch04-working-tree.md), sections 4.7 to 4.9
- **Demo scripts.** `labs/ch04/restore-paths.sh`, `labs/ch04/mv-rm-renames.sh`

## HOOK

**[ON SCREEN]** `git restore .`

An engineer has spent an afternoon on a failed experiment. Twenty files are changed, the tests are red, and in frustration they type `git restore .` at the top of the repository.

Nineteen of those changes were worthless. One was the fix for a bug they had found on the way. It is gone. No commit holds it, no reflog recorded the event, and Git has no undo for it.

**[PAUSE]**

`git restore .` at the top level of a repository is the working-tree half of `git reset --hard`. The usual trigger is frustration, and the usual loss is the one useful change among twenty useless ones. In this video you learn exactly where `git restore` takes its content from, what it overwrites, and the one case in which something survives.

## INTRODUCTION

Three commands that change the working tree, and one fact about what Git does not store.

`git restore` overwrites files with a stored version. `git mv` and `git rm` move and remove files and tell the index in the same step. And then a question that sounds like trivia and is not: does Git record that a file was renamed? It does not. You will prove that by opening a commit, and you will see where the word "rename" in Git's output comes from.

## LEARNING OBJECTIVES

After this video you can:

1. Say where `git restore <path>` takes its content from, and what it overwrites without a way back.
2. Restore a path from HEAD or from an older commit.
3. Show that `git mv` equals a manual move plus staging.
4. Prove that a commit contains no rename record, and explain the similarity score.

## CONCEPT

**`git restore`, in one sentence.** `git restore <path>` overwrites files in the working tree with a stored version: the version in the index by default, the version in a commit with `--source`.

It is 🔴 DANGEROUS, so the five questions come before anything else.

**[ON SCREEN]** The five questions, answered one at a time.

What it changes: files in the working tree, and index entries with `--staged`.

What it can destroy: every unstaged change in the named paths, without confirmation.

How to preview: `git diff -- <path>` shows exactly what a restore from the index will discard. `git diff <commit> -- <path>` shows it for `--source=<commit>`.

How to recover: not through Git, unless the content was staged or committed at some point. Editor history and backups are outside Git.

When it is appropriate: after you have read the diff and decided that the changes are worthless. When in doubt, commit to a throwaway branch or stash instead: both keep the content.

**Two choices define a restore.** Where the content comes from: without `--source`, the index; or HEAD, if `--staged` is given. With `--source=<tree>`, that commit or tree. And where it is written: the working tree by default; the index with `--staged`; both when `--staged` and `--worktree` are given together.

The command needs at least one pathspec. And the default mode is "no overlay": a tracked path that does not exist in the source is removed, so that the destination matches the source exactly. That has a sharp edge. `git restore --source=HEAD~5 src/` removes every tracked file under `src/` that did not exist five commits ago, together with any unstaged changes in them. Name files, not directories, when you take content from an old commit.

**Inside `.git`.** Restoring the working tree from the index reads the blob that the index entry names, and writes it to disk. No object is created and no ref moves, so no reflog records the event. The content that was overwritten is not saved anywhere.

**What survives.** One exception is worth knowing. Anything that was ever staged went into the object database when `git add` ran. `git fsck` can find it as a dangling blob. Dangling objects are removed by garbage collection after a grace period, two weeks by default, so this is a rescue route, not a storage plan.

**`git mv` and `git rm`.** In one sentence: they do in one step what you can do in two: change the working tree with `mv` or `rm`, then tell the index.

`git mv <source> <destination>` is 🟢 SAFE: it renames the file on disk and renames its index entry. `git rm <path>` is 🟡 CAUTION: it deletes the file on disk and removes its index entry, and it refuses when the file's content is not safely stored in HEAD. With `-f` it overrides that check, and is 🔴 DANGEROUS for that reason. `--cached` removes only the index entry. Neither command creates a commit: the index is updated, and the change must still be committed.

Two behaviors that the textbook's authors found while writing the demos. `git rm` deletes a directory when it removes the last file in it. And `git mv` does not create a missing destination directory.

**No renames.** In one sentence: a commit stores a snapshot of paths and contents, so there is no place in it where "this file used to be called that" could be written. A rename is a conclusion that Git draws later, by comparing two snapshots.

The Git User's Manual says it directly: Git "does not attempt to record file renames explicitly, though it can identify cases where the existence of the same file data at changing paths suggests a rename".

When a diff is computed, a deleted path and an added path with similar content are reported as a rename, with a similarity score. `R100` means 100% similar. The default threshold is 50%.

**Why this matters.** Three habits follow from detection being a heuristic. Rename in one commit and edit in the next when the edit is large: a rename combined with a rewrite can fall below the threshold, and then `git log --follow`, `git blame` and the rename handling in merges all treat it as an unrelated new file. Expect very large moves to look like delete plus add: the exhaustive part of detection is skipped when the number of candidate files exceeds `diff.renameLimit`, whose default the 2.55 manual gives as 1000. And do not look for a "rename" flag to audit: there is none in the data.

## MENTAL MODEL

For `git restore`, the textbook's analogy is "revert to saved" in an editor, where "saved" means "last staged". It breaks twice. There is no undo afterwards. And "saved" is the index, not the last commit, which surprises people who have staged something and forgotten.

For renames, think of two photographs of a room taken a day apart. In the first, a chair stands by the window. In the second, an identical chair stands by the door and there is none by the window. You say "someone moved the chair". Nothing in either photograph says so. It is your inference from comparing them, and if the chair had also been repainted you might have said "someone removed one chair and brought another". The rename is the reader's inference.

## DIAGRAM

**[DIAGRAM]** Two trees side by side, built from the demo: the tree before the rename and the tree after.

```text
   tree of the parent commit                tree of the rename commit
  +--------------------------+             +--------------------------+
  | src/app.py               |             | src/app.py               |
  | src/retriever.py  -------+----+   +----+-------  src/search.py    |
  +--------------------------+    |   |    +--------------------------+
                                  v   v
                             one blob, one ID

            the rename is the reader's inference
```

On the left, the old tree lists `src/retriever.py`. On the right, the new tree lists `src/search.py`. Both entries point at one blob. Neither tree mentions the other name. When Git compares the two trees, it sees a path that disappeared and a path that appeared with the same content, and it reports a rename.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch04/restore-paths.sh`.

```bash
labs/run ch04/restore-paths
```

One staged line, then one unstaged line in the same file. Status will say `MM`. The five questions for `git restore` 🔴 DANGEROUS have been answered; the preview is `git diff`. Predict: after `git restore config/settings.yaml`, which of the two lines is still in the file?

**[PAUSE]**

<!-- snippet: ch04/restore-paths/01-from-index -->
```text
# Stage one change, then make a second change that is not staged.
$ echo 'max_tokens: 512' >> config/settings.yaml
$ git add config/settings.yaml
$ echo 'debug: true' >> config/settings.yaml
$ git status --short
MM config/settings.yaml
# Default source is the index: the unstaged line goes, the staged line stays.
$ git restore config/settings.yaml
$ cat config/settings.yaml
model: small-v1
top_k: 5
max_tokens: 512
$ git status --short
M  config/settings.yaml
```
<!-- /snippet -->

The file now equals the index, not HEAD. The staged `max_tokens` line survived, and `debug: true` is gone.

<!-- snippet: ch04/restore-paths/02-from-head -->
```text
# With --source, the content comes from a commit. Only the working tree is written.
$ git restore --source=HEAD config/settings.yaml
$ cat config/settings.yaml
model: small-v1
top_k: 5
$ git status --short
MM config/settings.yaml
# Add --staged to write the index as well. Now all three trees agree.
$ git restore --source=HEAD --staged --worktree config/settings.yaml
$ git status --short
```
<!-- /snippet -->

With `--source`, the content comes from a commit and, without `--staged`, only the working tree is written. After the first command the status is `MM`: the index still holds the staged line, and the working tree now lacks it, so both comparisons differ. `--staged --worktree` writes both places, and the path is clean.

<!-- snippet: ch04/restore-paths/03-deleted-file -->
```text
$ rm src/app.py
$ git status --short
 D src/app.py
$ git restore src/app.py
$ cat src/app.py
def answer(question):
    return "ok"
```
<!-- /snippet -->

A deleted tracked file comes back the same way.

<!-- snippet: ch04/restore-paths/04-older-commit -->
```text
$ git log --oneline
3139437 Raise top_k to 5
aab6b8e Add service skeleton
$ git restore --source=HEAD~1 config/settings.yaml
$ cat config/settings.yaml
model: small-v1
top_k: 3
$ git status --short
 M config/settings.yaml
$ git diff
diff --git a/config/settings.yaml b/config/settings.yaml
index 4da99e3..9b521fd 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1,2 +1,2 @@
 model: small-v1
-top_k: 5
+top_k: 3
$ git restore config/settings.yaml
```
<!-- /snippet -->

Any commit can be the source.

<!-- snippet: ch04/restore-paths/05-checkout-equivalent -->
```text
# The older spelling. With a commit named, "git checkout" writes the index too.
$ git checkout HEAD~1 -- config/settings.yaml
$ git status --short
M  config/settings.yaml
$ git checkout HEAD -- config/settings.yaml
$ git status --short
```
<!-- /snippet -->

The older spelling, shown once. There is one difference that matters: `git checkout <commit> -- <path>` writes the index as well as the working tree, which is the `M` in the first column here, where `git restore --source=<commit> <path>` wrote only the working tree.

Now the rescue route. The line that was staged in the first step and then discarded: where is it?

<!-- snippet: ch04/restore-paths/06-what-survives -->
```text
# The staged line from the first step was written into the object database by "git add".
$ git fsck
dangling blob e4eb0e6d146a5b1eb62d3a52301f262836a0a224
$ git cat-file -p $(git fsck | cut -d" " -f3)
model: small-v1
top_k: 5
max_tokens: 512
# The line "debug: true" was never added. No object holds it. It is gone.
```
<!-- /snippet -->

`git fsck` reports a dangling blob, `e4eb0e6`: an object that no ref, commit or index entry points to. It is the staged version from the first step. The unstaged `debug: true` line was never added, so nothing holds it.

**[TERMINAL]** Caption bar: `labs/ch04/mv-rm-renames.sh`.

```bash
labs/run ch04/mv-rm-renames
```

The index before and after a `git mv` 🟢 SAFE.

<!-- snippet: ch04/mv-rm-renames/01-git-mv -->
```text
$ git ls-files --stage src
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 9d77f9cf9e4a6e1da622b599a95cd3afc3ee77c1 0	src/retriever.py
$ git mv src/retriever.py src/search.py
$ git status --short
R  src/retriever.py -> src/search.py
$ git ls-files --stage src
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 9d77f9cf9e4a6e1da622b599a95cd3afc3ee77c1 0	src/search.py
# Same blob ID, new path. The tree that this index would produce:
$ git write-tree
566379be59e0cde72aa450cfea467a891457268c
```
<!-- /snippet -->

The entry kept its blob ID and changed its path. `git write-tree` prints the ID of the tree that this index describes. Remember that ID. The script now undoes everything and performs the rename with shell commands. Predict the tree ID.

<!-- snippet: ch04/mv-rm-renames/02-same-as-manual -->
```text
# Undo, then do the same rename with plain shell commands.
$ git restore --staged --worktree --source=HEAD .
$ git status --short
$ mv src/retriever.py src/search.py
$ git status --short
 D src/retriever.py
?? src/search.py
$ git add -A src
$ git status --short
R  src/retriever.py -> src/search.py
$ git write-tree
566379be59e0cde72aa450cfea467a891457268c
```
<!-- /snippet -->

The tree ID is identical, beginning `566379b` both times. That is the proof that `git mv` adds nothing that `mv` plus `git add -A` does not.

Now commit the rename and open the commit. If Git recorded renames, the record would be here.

<!-- snippet: ch04/mv-rm-renames/03-commit-has-no-rename -->
```text
$ git commit -m "Rename retriever module to search"
[main a7a3aae] Rename retriever module to search
 1 file changed, 0 insertions(+), 0 deletions(-)
 rename src/{retriever.py => search.py} (100%)
$ git cat-file -p HEAD
tree 566379be59e0cde72aa450cfea467a891457268c
parent f518810d6545244f37e647a360377229b00b306e
author Lab User <you@example.com> 1788756300 +0530
committer Lab User <you@example.com> 1788756300 +0530

Rename retriever module to search
$ git ls-tree -r HEAD
100644 blob 4dddde5373611e10f9ec6bc328a25ae216552487	docs/old-notes.md
100644 blob 3e9f19511d48a09c7080a74f7f78b97f62e2d153	docs/runbook.md
100644 blob 63df51b788f2464137e0f30355056e42a320f705	src/app.py
100644 blob 9d77f9cf9e4a6e1da622b599a95cd3afc3ee77c1	src/search.py
```
<!-- /snippet -->

The summary line says `rename`, with 100%. But the commit object has a tree, a parent, two identities and a message, and the tree lists paths. No field mentions a rename.

<!-- snippet: ch04/mv-rm-renames/04-detected-on-demand -->
```text
# The rename is computed when two snapshots are compared.
$ git diff --name-status HEAD~1 HEAD
R100	src/retriever.py	src/search.py
$ git diff --name-status --no-renames HEAD~1 HEAD
D	src/retriever.py
A	src/search.py
```
<!-- /snippet -->

The word comes from the comparison. `R100` means "a deleted path and an added path whose contents are 100% similar". Turn detection off with `--no-renames`, and the same two commits show a deletion and an addition.

<!-- snippet: ch04/mv-rm-renames/05-rename-and-edit -->
```text
# Rename and edit in one commit: similarity drops below 100.
$ git diff --name-status HEAD~1 HEAD
R096	src/search.py	src/vector_search.py
$ git diff --name-status -M98% HEAD~1 HEAD
D	src/search.py
A	src/vector_search.py
```
<!-- /snippet -->

Rename and edit in one commit: the similarity drops to 96. Raise the threshold to 98%, and the rename is no longer reported. Whether you see a rename depends on a threshold.

<!-- snippet: ch04/mv-rm-renames/06-follow -->
```text
$ git log --oneline -- src/vector_search.py
8ae9ce9 Rename search module and raise TOP_K
$ git log --oneline --follow -- src/vector_search.py
8ae9ce9 Rename search module and raise TOP_K
a7a3aae Rename retriever module to search
f518810 Add service skeleton
```
<!-- /snippet -->

History that follows a file depends on the same detection. Without `--follow`, the log of `src/vector_search.py` starts at the commit where that path first appears. With it, Git detects the two renames and continues. `--follow` works for a single file only.

<!-- snippet: ch04/mv-rm-renames/07-git-rm -->
```text
$ git rm docs/old-notes.md
rm 'docs/old-notes.md'
$ git status --short
D  docs/old-notes.md
$ ls docs
runbook.md
# git rm refuses to delete content that exists nowhere else.
$ echo 'Escalation contacts.' >> docs/runbook.md
$ git rm docs/runbook.md
error: the following file has local modifications:
    docs/runbook.md
(use --cached to keep the file, or -f to force removal)
[exit status: 1]
$ git rm --cached docs/runbook.md
rm 'docs/runbook.md'
$ git status --short
D  docs/old-notes.md
D  docs/runbook.md
?? docs/
```
<!-- /snippet -->

And `git rm` 🟡 CAUTION, with the safety check that plain `rm` lacks. The first removal went through, because the file matched HEAD, so the content is recoverable. The second was refused, because the file had a modification that exists nowhere else.

## COMMON MISTAKES

1. **Edits disappear after `git restore <path>`.** Root cause: the working tree was overwritten from the index, and content that was never staged is in no object.
2. **Expecting `git restore <path>` to return the last committed version.** Root cause: without `--source` the content comes from the index, which may hold something you staged and forgot.
3. **`git restore --source=<old commit> <directory>` deletes files.** Root cause: restore runs in no-overlay mode, so tracked paths that the source lacks are removed.
4. **The history of a file stops at a rename.** Root cause: the rename commit also rewrote the file, and the similarity fell below the threshold; rename and edit in separate commits.
5. **Using `git rm --cached` to unstage a change.** Root cause: it removes the index entry, and the next commit deletes the path for everyone else; it is the tool to stop tracking a file.

## PRODUCTION EXAMPLE

A retrieval team moves a module to a new package and, in the same commit, rewrites most of it. Months later someone runs `git blame` on the new file to find out why a threshold has its value, and every line points at the move commit. `git log --follow` stops there too. Nothing is lost: the old commits exist. But the tools that connect the two names depend on similarity, and the similarity fell below the threshold. The team's rule after that is the textbook's: a commit that renames, then a commit that edits.

And for restores, the habit from the textbook: when the changes are mixed, use `git restore -p` to discard hunk by hunk. A stash or a throwaway commit costs seconds and keeps everything.

## PRACTICE EXERCISE

Do Exercise 2.6, Level 2, "a move and an edit, as two commits", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Before each commit, predict what `git diff --name-status` between the commit and its parent will print, including the similarity score where you expect a rename.

## INTERVIEW QUESTION

Q47: "Prove to me that Git does not store renames. Then explain what `R087` in a diff means and name two features that depend on it."

Answer aloud. The word "prove" is the test: a strong answer names the commands that open a commit and its tree and says what you would find and not find, then shows the same pair of commits reported two ways. For the second half, explain the letter and the number separately, and connect the number to a threshold.

## RECAP

You should now be able to say: `git restore <path>` overwrites the working-tree file from the index, or from a commit with `--source`, and unstaged content it overwrites is in no object. I preview it with `git diff`. Content that was staged at some point may survive as a dangling blob. `git mv` is a move plus staging, and gives the same tree. `git rm` refuses to delete content that HEAD does not hold. A commit contains no rename record; a rename is detected when two snapshots are compared, from the similarity of content, and `--follow`, blame and merges depend on that detection.

## HOMEWORK

- Read sections 4.7 to 4.9 of [Chapter 4](../../textbook/ch04-working-tree.md).
- Challenge: Exercise 2.7, Level 3, "git restore . did not throw everything away", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
