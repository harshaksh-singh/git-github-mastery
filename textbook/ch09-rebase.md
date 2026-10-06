# Chapter 9: Rebase

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch09/`.

## 9.1 Why this matters

Four questions a CTO can ask after a week in which someone rebased:

1. "Asha pushed a commit to the feature branch on Tuesday. On Wednesday it was gone from GitHub, and after her next pull it was gone from her laptop as well. Nobody deleted anything. Where is it?"
2. "The pull request had three commits before the review and three commits after it, with the same titles. The reviewer approved the first version. What exactly is different in the second one?"
3. "Why does the history of the ingest branch contain every commit twice?"
4. "A developer says the rebase finished without an error and one of his commits is not in the branch any more. Is that possible?"

All four have precise answers, and all four answers start from one fact: **a rebase does not move or change commits. It writes new commits and then moves a ref.** The old commits are still in the object database. Other clones still have them. The server still has them until someone pushes over them. Every surprise in this chapter is a consequence of two histories existing side by side for a while: the one you rewrote and the one everybody else still holds.

The answers are in sections 9.17, 9.14, 9.15 and 9.11, in that order. The fourth one is "yes".

A note on reading the transcripts. An interactive rebase opens an editor. In this book a small script plays the person at the keyboard: it prints the list as Git opened it, applies the edit, and prints the list as saved. Those two blocks stand for what you would see and do in your own editor.

## 9.2 What a rebase is

**In one sentence.** 🟡 `git rebase <upstream>` takes the commits that your branch has and `<upstream>` does not have, creates a copy of each one on top of `<upstream>`, in order, and then points your branch at the last copy.

**Analogy.** You wrote three amendments to version 4 of a contract. Meanwhile the other party issued version 6. Rebasing is redoing your three amendments, one after the other, against version 6, so that the file reads as if you had started from version 6. The analogy breaks in two places. First, the three amendments you wrote against version 4 are not shredded: they stay in the drawer (the object database), reachable through the reflog. Second, nobody retypes anything: each amendment is carried over by a three-way merge that Git computes, and that merge can stop and ask you to decide.

**Precisely.** The manual describes `git rebase <upstream>` as four steps ([git-rebase](https://git-scm.com/docs/git-rebase)):

1. Make the list of commits to replay: everything reachable from the current branch and not from `<upstream>`, the same set that `git log <upstream>..HEAD` prints, minus commits whose change is already in `<upstream>` (section 9.12) and minus merge commits (section 9.10).
2. Detach HEAD at `<upstream>`.
3. Replay the commits one by one, oldest first. Each replay is the cherry-pick operation of [Chapter 10](ch10-cherry-pick.md): a three-way merge whose base is the parent of the original commit, whose "ours" side is HEAD, and whose "theirs" side is the original commit. The result is committed with the original author, author date and message, and with you, now, as committer.
4. Move the branch ref to the last new commit and attach HEAD to the branch again.

Two words in that description deserve attention. "Reachable": Git has no notion of a parent branch ([Chapter 7](ch07-branches.md)), so the set of commits is computed from the graph, not from where you believe the branch started. "Copy": a commit object is never modified ([Chapter 3](ch03-git-internals.md)); the copies are new objects with new commit IDs (section 9.3).

**Inside `.git`.** New commit objects, and new tree objects wherever the combined content differs from anything stored before; blobs are reused when file content is unchanged. One branch ref is rewritten, once, at the end. HEAD is detached while the rebase runs. `ORIG_HEAD` records the old tip. The reflogs of HEAD and of the branch record every step. Section 9.4 walks through all of it.

**See it.** The project in this chapter is `ragkit`, a small retrieval-augmented answering service. `feat/rerank` was cut from the first commit of `main`; since then `main` gained two commits:

<!-- snippet: ch09/rebase-basic/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 82f1fbb (HEAD -> main) Upgrade model to small-v2
* 589d18b Add README
| * bd62876 (feat/rerank) Enable reranking in config
| * af65a92 Call reranker from retriever
| * 5ee19f0 Add reranker skeleton
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/rebase-basic/02-rebase -->
```text
$ git switch feat/rerank
Switched to branch 'feat/rerank'
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
```
<!-- /snippet -->

`Rebasing (1/3)` is a progress line; in a terminal the three lines overwrite each other. The last line names the one ref that moved.

<!-- snippet: ch09/rebase-basic/03-after -->
```text
$ git log --oneline --graph --decorate --all
* 976a161 (HEAD -> feat/rerank) Enable reranking in config
* ade2990 Call reranker from retriever
* 742ab58 Add reranker skeleton
* 82f1fbb (main) Upgrade model to small-v2
* 589d18b Add README
* 8afc6bd Add retriever and model config
$ git log --oneline main..ORIG_HEAD
bd62876 Enable reranking in config
af65a92 Call reranker from retriever
5ee19f0 Add reranker skeleton
```
<!-- /snippet -->

The branch now holds `742ab58`, `ade2990` and `976a161`, on top of `82f1fbb`. The second command shows that the three original commits still exist: `ORIG_HEAD` points at the old tip `bd62876`.

Now do the same rebase by hand with the operations that the manual names: detach, cherry-pick the range, move the branch.

<!-- snippet: ch09/rebase-by-hand/01-detach-and-replay -->
```text
$ git switch --detach main
HEAD is now at 82f1fbb Upgrade model to small-v2
$ git cherry-pick main..feat/rerank
[detached HEAD 0dea106] Add reranker skeleton
 Date: Mon Sep 7 10:03:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 app/rerank.py
[detached HEAD 20d0897] Call reranker from retriever
 Date: Mon Sep 7 10:04:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
Auto-merging config/model.yaml
[detached HEAD 4caa98e] Enable reranking in config
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

<!-- snippet: ch09/rebase-by-hand/03-move-the-branch -->
```text
$ git switch -C feat/rerank
Switched to and reset branch 'feat/rerank'
$ git log --oneline --graph --decorate --all
* 4caa98e (HEAD -> feat/rerank) Enable reranking in config
* 20d0897 Call reranker from retriever
* 0dea106 Add reranker skeleton
* 82f1fbb (main) Upgrade model to small-v2
* 589d18b Add README
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

`git switch -C <branch>` (`git checkout -B` in the manual and in older scripts) creates the branch at HEAD or, if it exists, resets it to HEAD. That is the whole trick of step 4. Until that command ran, `feat/rerank` still pointed at the old commits and the three new commits belonged to no branch.

**Picture.**

```text
Before

            5ee19f0---af65a92---bd62876                    feat/rerank
           /
  8afc6bd---589d18b---82f1fbb                              main

After "git rebase main", run on feat/rerank

            5ee19f0---af65a92---bd62876                    no branch: ORIG_HEAD, feat/rerank@{1}
           /
  8afc6bd---589d18b---82f1fbb                              main
                             \
                              742ab58---ade2990---976a161  feat/rerank   (HEAD -> feat/rerank)
```

**In production.** The everyday uses are bringing a feature branch up to date before review, so that reviewer and CI see your change on top of today's `main`, and tidying your own commits before anyone else reads them (section 9.6). Both are safe on a branch that only you use. Both become a team incident on a branch that others have based work on (section 9.15), and the difference between the two cases is the most important judgment in this chapter.

## 9.3 Why every rebased commit has a new ID

**In one sentence.** A commit ID is a hash of the commit object, the commit object names its parent and its tree, and a replayed commit has a different parent and usually a different tree, so it cannot have the same ID.

**Precisely.** Look at the first commit of the branch before and after the rebase of section 9.2:

<!-- snippet: ch09/rebase-basic/04-objects -->
```text
# The first commit of the branch, before the rebase (reachable through ORIG_HEAD) ...
$ git cat-file -p ORIG_HEAD~2
tree bff5bbd64dc61559cfed48b794c4ac66aa8fd087
parent 8afc6bd28c2572af09f1b6c37d733535230e526f
author Lab User <you@example.com> 1788755580 +0530
committer Lab User <you@example.com> 1788755580 +0530

Add reranker skeleton
# ... and its replacement after the rebase.
$ git cat-file -p HEAD~2
tree 8cc3ecec7607fe1db26fe237762047f282c08338
parent 82f1fbb78c09021e2e673bf06e3c77fc58f14a50
author Lab User <you@example.com> 1788755580 +0530
committer Lab User <you@example.com> 1788756000 +0530

Add reranker skeleton
```
<!-- /snippet -->

Compare the two objects field by field.

| Field | Before | After | Why |
|---|---|---|---|
| `tree` | `bff5bbd…` | `8cc3ece…` | The new snapshot also contains the README and the model upgrade from `main` |
| `parent` | `8afc6bd…` | `82f1fbb…` | That is the point of the operation |
| `author` | Lab User, `1788755580` | identical | Rebase keeps who wrote the change and when |
| `committer` | Lab User, `1788755580` | Lab User, `1788756000` | The committer is whoever created this object, at the time it was created |
| message | identical | identical | Unless you reword it |

Three of the five inputs to the hash changed. A copy would get a new ID even with the same parent and tree, because the committer date moves; that is why Git does not copy commits that would come out identical. It fast-forwards over them unless you pass `--no-ff`. And because each commit names its parent by ID, a new ID for one commit forces a new ID for every commit after it. IDs change from the first rewritten commit onward, never before it.

What did not change is the change itself. A patch ID is a hash of a commit's diff with line numbers ignored ([git-patch-id](https://git-scm.com/docs/git-patch-id)):

<!-- snippet: ch09/rebase-basic/05-patch-id -->
```text
$ git show ORIG_HEAD~2 | git patch-id --stable
cf1c4fb899863a713cf682e6a8101ba01f834cb4 5ee19f03aa988c15717abc4b6c14104fc8d23a97
$ git show HEAD~2 | git patch-id --stable
cf1c4fb899863a713cf682e6a8101ba01f834cb4 742ab5805e0a3077be749e44fb92159e284ee0ad
```
<!-- /snippet -->

Same patch ID in the first column, different commit IDs in the second. Git uses this equivalence to recognise "the same change under another ID" in sections 9.12 and 9.15 and in Chapter 10.

The hand-made rebase of section 9.2 makes the same point from the other side:

<!-- snippet: ch09/rebase-by-hand/04-compare-with-rebase -->
```text
# Keep the hand-made result under a tag, put the branch back, and let "git rebase" do the job.
$ git tag by-hand
$ git reset --hard "feat/rerank@{1}"
HEAD is now at bd62876 Enable reranking in config
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
$ git log --format="%h tree %t  %s" main..by-hand
4caa98e tree 273096f  Enable reranking in config
20d0897 tree 9b070ab  Call reranker from retriever
0dea106 tree 8cc3ece  Add reranker skeleton
$ git log --format="%h tree %t  %s" main..feat/rerank
a4cc3fb tree 273096f  Enable reranking in config
a9cc881 tree 9b070ab  Call reranker from retriever
2efc812 tree 8cc3ece  Add reranker skeleton
```
<!-- /snippet -->

Commit for commit, the trees are identical: `git rebase` and three hand-typed cherry-picks built the same snapshots. The commit IDs differ only because the real rebase ran a few lab minutes later, so its committer dates differ. Now look at the IDs that `git rebase main feat/rerank` prints in section 9.5: `0dea106`, `20d0897`, `4caa98e`, the IDs of the hand-made commits. That demo runs in another sandbox, with another command, at the same lab minute, and so produces byte-identical commit objects. A commit ID does not record which command made the commit. It is a function of content: tree, parents, author, committer, dates, message.

**In production.** Anything that stored an old commit ID now refers to a commit that is no longer on your branch: a review comment anchored to a commit, a CI status, a deployment record, the commit ID that a training job wrote into its run metadata. Before you rebase, ask what has already recorded these IDs. Tags do not follow a rebase (section 9.9 shows one that stayed behind). And signatures are part of the commit object ([Chapter 14B](ch14b-config-tags-signing.md)): a replayed commit is a new object, signed only if you sign it now, with `-S` or `commit.gpgSign`.

> **GitHub, not Git.** The "Rebase and merge" button performs this operation on GitHub's servers. The commits that land on the base branch always have new commit IDs and an updated committer, and they are unsigned, because GitHub cannot sign on your behalf ([merge methods](https://docs.github.com/en/pull-requests/reference/pull-request-merges), [signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification#signature-verification-for-rebase-and-merge)). Described from the documentation; [Chapter 17](ch17-pull-requests.md) covers the three merge buttons.

## 9.4 What rebase does internally

**In one sentence.** A rebase is a small interpreter: it writes a list of instructions into a state directory inside `.git`, executes them one at a time on a detached HEAD, and touches the branch ref only when the list is empty.

**See it.** The way to see the machinery is to make it stop in the middle. In this repository the second commit of `feat/rerank` changes a line that `main` has also changed:

<!-- snippet: ch09/rebase-internals/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 439e4c6 (main) Raise TOP_K to 8 after recall regression
| * ad106e3 (HEAD -> feat/rerank) Enable reranking in config
| * 569e6c9 Fetch 20 candidates for the reranker
| * 5ee19f0 Add reranker skeleton
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/rebase-internals/02-stop -->
```text
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Auto-merging app/retriever.py
CONFLICT (content): Merge conflict in app/retriever.py
error: could not apply 569e6c9... Fetch 20 candidates for the reranker
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 569e6c9... # Fetch 20 candidates for the reranker
[exit status: 1]
```
<!-- /snippet -->

The first commit was replayed. The second one stopped with a conflict, and the command exited with status 1. Section 9.11 deals with the conflict. Here, look at the state Git is in.

<!-- snippet: ch09/rebase-internals/03-head -->
```text
$ cat .git/HEAD
1c9f69a02aeeb08430a5015ba7af214c9b96d0a0
$ git branch
* (no branch, rebasing feat/rerank)
  feat/rerank
  main
$ git log --oneline --decorate -3
1c9f69a (HEAD) Add reranker skeleton
439e4c6 (main) Raise TOP_K to 8 after recall regression
8afc6bd Add retriever and model config
```
<!-- /snippet -->

`.git/HEAD` holds a raw commit ID, not `ref: refs/heads/...`: HEAD is detached ([Chapter 7](ch07-branches.md)). It sits on `1c9f69a`, the copy of "Add reranker skeleton", which sits on the tip of `main`. `git branch` describes the situation as `(no branch, rebasing feat/rerank)`.

<!-- snippet: ch09/rebase-internals/04-state-dir -->
```text
$ ls .git/rebase-merge
author-script
done
drop_redundant_commits
end
git-rebase-todo
git-rebase-todo.backup
head-name
interactive
message
msgnum
no-reschedule-failed-exec
onto
orig-head
patch
rewritten-list
stopped-sha
```
<!-- /snippet -->

<!-- snippet: ch09/rebase-internals/05-state-files -->
```text
$ cat .git/rebase-merge/head-name
refs/heads/feat/rerank
$ cat .git/rebase-merge/orig-head
ad106e3ecc6f4d2e14376112d9580c6892a12093
$ cat .git/rebase-merge/onto
439e4c6ba104e7816d32d16fd3bd9548e536b33f
$ cat .git/rebase-merge/done
pick 5ee19f03aa988c15717abc4b6c14104fc8d23a97 # Add reranker skeleton
pick 569e6c983316561062d42644d649129e50eeda5d # Fetch 20 candidates for the reranker
$ cat .git/rebase-merge/git-rebase-todo
pick ad106e3ecc6f4d2e14376112d9580c6892a12093 # Enable reranking in config
$ cat .git/rebase-merge/msgnum .git/rebase-merge/end
2
3
$ cat .git/rebase-merge/author-script
GIT_AUTHOR_NAME='Lab User'
GIT_AUTHOR_EMAIL='you@example.com'
GIT_AUTHOR_DATE='@1788755640 +0530'
```
<!-- /snippet -->

What the files mean:

```text
head-name          the ref that will be moved at the end: refs/heads/feat/rerank
orig-head          where that ref pointed when the rebase started
onto               the commit that the copies are built on
git-rebase-todo    the instructions not yet executed, one per line: Git calls this the todo list
done               the instructions already executed
msgnum, end        the position: instruction 2 of 3
author-script      author name, email and date of the commit being replayed, reused for its copy
message            the commit message that will be reused when you continue
stopped-sha        the commit at which the rebase stopped
rewritten-list     "old ID, new ID" for each commit copied so far; input for the post-rewrite hook
interactive        marker of the merge backend (see the note on "git status" below)
```

In running text this book writes "to-do list" for the instruction list; Git spells it as one word, as the file name shows.

<!-- snippet: ch09/rebase-internals/06-special-refs -->
```text
$ git rev-parse --short ORIG_HEAD
ad106e3
$ git rev-parse --short REBASE_HEAD
569e6c9
$ git rev-parse --short feat/rerank
ad106e3
$ git rev-parse --short HEAD
1c9f69a
```
<!-- /snippet -->

Four names, three commits. `ORIG_HEAD` is the tip of the branch before the rebase began. `REBASE_HEAD` is the commit that is being replayed right now; it exists only while a rebase is stopped. HEAD is the last copy made. And `feat/rerank` still equals `ORIG_HEAD`: **the branch has not moved.**

> **Version note.** Older behavior: the glossary called every such file, `ORIG_HEAD` and `REBASE_HEAD` included, a pseudoref, and most tutorials still do. Current behavior: "pseudoref" means only `FETCH_HEAD` and `MERGE_HEAD`; the others are ordinary refs that live at the root of the ref namespace. Since: Git 2.46 ([glossary](https://github.com/git/git/blob/v2.56.0/Documentation/glossary-content.adoc)). Recommended: say "root ref", and read them with `git rev-parse`, not with `cat`.

<!-- snippet: ch09/rebase-internals/07-status -->
```text
$ git status
interactive rebase in progress; onto 439e4c6
Last commands done (2 commands done):
   pick 5ee19f0 # Add reranker skeleton
   pick 569e6c9 # Fetch 20 candidates for the reranker
Next command to do (1 remaining command):
   pick ad106e3 # Enable reranking in config
  (use "git rebase --edit-todo" to view and edit)
You are currently rebasing branch 'feat/rerank' on '439e4c6'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   app/retriever.py

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

`git status` reads the state directory back to you: what was done, what remains, and the three ways out.

> **Root cause.** "interactive rebase in progress" appears although no `-i` was typed. The default backend of `git rebase` is the machinery that once served only interactive rebases; it always writes the marker file `interactive`, and `git status` reports what it finds.

**Picture.** The repository while the rebase is stopped:

```text
                     1c9f69a                    HEAD (detached): copy of 5ee19f0
                    /
  8afc6bd---439e4c6                             main
         \
          5ee19f0---569e6c9---ad106e3           feat/rerank, ORIG_HEAD
                    ^
                    REBASE_HEAD: the commit being replayed
```

Now leave the way you came:

<!-- snippet: ch09/rebase-internals/08-abort -->
```text
$ git rebase --abort
$ git status
On branch feat/rerank
nothing to commit, working tree clean
$ git reflog -3
ad106e3 HEAD@{0}: rebase (abort): returning to refs/heads/feat/rerank
1c9f69a HEAD@{1}: rebase (pick): Add reranker skeleton
439e4c6 HEAD@{2}: rebase (start): checkout main
```
<!-- /snippet -->

`--abort` only had to attach HEAD to the branch again and restore the index and working tree from it. The copy `1c9f69a` is now reachable from nothing except the reflog.

When a rebase runs to the end, the two reflogs record it differently. This is the trail of the rebase in section 9.2:

<!-- snippet: ch09/rebase-basic/06-reflog -->
```text
$ git reflog -6
976a161 HEAD@{0}: rebase (finish): returning to refs/heads/feat/rerank
976a161 HEAD@{1}: rebase (pick): Enable reranking in config
ade2990 HEAD@{2}: rebase (pick): Call reranker from retriever
742ab58 HEAD@{3}: rebase (pick): Add reranker skeleton
82f1fbb HEAD@{4}: rebase (start): checkout main
bd62876 HEAD@{5}: checkout: moving from main to feat/rerank
$ git reflog show feat/rerank
976a161 feat/rerank@{0}: rebase (finish): refs/heads/feat/rerank onto 82f1fbb78c09021e2e673bf06e3c77fc58f14a50
bd62876 feat/rerank@{1}: commit: Enable reranking in config
af65a92 feat/rerank@{2}: commit: Call reranker from retriever
5ee19f0 feat/rerank@{3}: commit: Add reranker skeleton
8afc6bd feat/rerank@{4}: branch: Created from HEAD
```
<!-- /snippet -->

The HEAD reflog has one line per step: `rebase (start)` is the detach, each `rebase (pick)` is one copy, `rebase (finish)` is the return to the branch. The branch reflog has one line for the whole rebase, and the line below it is the old tip. `feat/rerank@{1}` therefore means "this branch before its last rebase", and that is the most reliable undo handle you have (section 9.16).

**State table.** One row per phase.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git rebase <upstream>`, runs to the end | Becomes the snapshot of the last copy | Same snapshot | Detached during the run, attached to the branch again at the end | Moved once, at the end, to the last copy | `ORIG_HEAD` set to the old tip; new commit and tree objects; one reflog entry per step for HEAD, one for the branch; state directory created and removed | unchanged | unchanged |
| The same, stopped at a conflict | Conflict markers in the conflicted files; everything else at the state of HEAD plus the cleanly merged changes | Stages 1, 2 and 3 for conflicted paths | Detached at the last copy | unchanged: still the old tip | State directory `.git/rebase-merge/`; `REBASE_HEAD`; `ORIG_HEAD` | unchanged | unchanged |
| `git rebase --continue` | unchanged by the commit itself, then updated by the following steps | Committed as the copy, then updated | Advances to the new copy and onward | Moved if the list becomes empty | Next instructions executed | unchanged | unchanged |
| `git rebase --skip` | Reset to HEAD: the conflicted merge is discarded | Reset to HEAD | Stays, then advances with the following steps | Moved if the list becomes empty | The stopped commit gets no copy | unchanged | unchanged |
| `git rebase --abort` | Reset to the old tip: resolution work in progress is lost | Reset to the old tip | Attached to the branch again | unchanged | State directory and `REBASE_HEAD` removed; `ORIG_HEAD` stays | unchanged | unchanged |
| `git rebase --quit` | unchanged | unchanged | Stays detached where it is | unchanged | State directory removed; an autostash moves to the stash list | unchanged | unchanged |

**The other backend.** Until Git 2.26 the default implementation turned each commit into a patch and applied the patches, the way `git format-patch` and `git am` do. It is still there:

<!-- snippet: ch09/apply-backend/01-apply-stops -->
```text
$ git rebase --apply main
First, rewinding head to replay your work on top of it...
Applying: Add reranker skeleton
Applying: Fetch 20 candidates for the reranker
Using index info to reconstruct a base tree...
M	app/retriever.py
Falling back to patching base and 3-way merge...
Auto-merging app/retriever.py
CONFLICT (content): Merge conflict in app/retriever.py
error: Failed to merge in the changes.
hint: Use 'git am --show-current-patch=diff' to see the failed patch
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Patch failed at 0002 Fetch 20 candidates for the reranker
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch09/apply-backend/02-state -->
```text
$ ls .git | grep rebase
rebase-apply
$ ls .git/rebase-apply | head -5
0001
0002
0003
abort-safety
apply-opt
$ git status | head -2
rebase in progress; onto 439e4c6
You are currently rebasing branch 'feat/rerank' on '439e4c6'.
$ head -5 app/retriever.py
<<<<<<< HEAD
TOP_K = 8
=======
TOP_K = 20
>>>>>>> Fetch 20 candidates for the reranker
```
<!-- /snippet -->

Different words ("rewinding head", "Patch failed at 0002"), a different state directory (`.git/rebase-apply`, with one numbered patch file per commit), "rebase in progress" without the word interactive, and a conflict label that carries only the subject of your commit, not its ID. You will meet these in old answers and old scripts. The manual lists what the apply backend does worse: it works from patch context and can apply a hunk in the wrong place without reporting a conflict, it cannot detect directory renames, and it drops empty commits ([git-rebase, "Behavioral differences"](https://github.com/git/git/blob/v2.56.0/Documentation/git-rebase.adoc)). Leave `rebase.backend` alone.

**In production.** "Is a rebase in progress here?" The first line of `git status` answers it, and so does `ls .git | grep rebase`. If the answer is yes, nothing is lost: the branch ref has not moved, and `git rebase --abort` returns to it. Do not delete the state directory by hand; that leaves HEAD detached on a half-built history, which is what `--quit` does on purpose.

## 9.5 Choosing what moves and where it lands

**In one sentence.** Every form of the command answers three questions: which branch is rewritten, which commits are replayed, and on which commit the copies are built.

**Precisely.**

```bash
git rebase [--onto <newbase>] [<upstream> [<branch>]]
```

- `<branch>` is the branch that gets rewritten. Default: the current branch. If you name it, Git switches to it as part of the command.
- `<upstream>` is only a boundary. The commits replayed are `<upstream>..<branch>`: reachable from the branch, not reachable from `<upstream>`.
- `<newbase>` is where the copies are built. Default: `<upstream>`.

| Form | Commits replayed | Built on |
|---|---|---|
| `git rebase main` | `main..HEAD` | `main` |
| `git rebase main feat/x` | `main..feat/x`, after switching to `feat/x` | `main` |
| `git rebase` | from the configured upstream branch, using the fork point (section 9.15) | that upstream |
| `git rebase --onto N U` | `U..HEAD` | `N` |
| `git rebase --keep-base main` | `main..HEAD` | the merge base of `main` and HEAD |
| `git rebase --root` | every commit reachable from HEAD | nothing: the root commit is recreated |
| `git rebase -i HEAD~3` | the last three commits | `HEAD~3`, where they already are |

The two-argument form, started from `main`:

<!-- snippet: ch09/rebase-forms/01-two-arguments -->
```text
$ git status --short --branch
## main
$ git rebase main feat/rerank
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
$ git status --short --branch
## feat/rerank
$ git reflog -5
4caa98e HEAD@{0}: rebase (finish): returning to refs/heads/feat/rerank
4caa98e HEAD@{1}: rebase (pick): Enable reranking in config
20d0897 HEAD@{2}: rebase (pick): Call reranker from retriever
0dea106 HEAD@{3}: rebase (pick): Add reranker skeleton
82f1fbb HEAD@{4}: rebase (start): checkout main
```
<!-- /snippet -->

You end up on `feat/rerank`. Git does not check out the old tip of `feat/rerank` on the way: it detaches at `main`, makes the copies, and attaches HEAD to the branch at the end, which is what the five reflog lines show. Without any argument, the branch needs a configured upstream:

<!-- snippet: ch09/rebase-forms/02-no-upstream -->
```text
$ git rebase
There is no tracking information for the current branch.
Please specify which branch you want to rebase against.
See git-rebase(1) for details.

    git rebase '<branch>'

If you wish to set tracking information for this branch you can do so with:

    git branch --set-upstream-to=<remote>/<branch> feat/rerank

[exit status: 1]
```
<!-- /snippet -->

**`--onto`: three worked cases.** With `--onto`, the boundary and the destination are different commits.

```text
git rebase --onto N U B          replay U..B on top of N

Before                                After

  o---o---N                             o---o---N---x'--y'--z'   B
       \                                     \
        o---U---x---y---z   B                 o---U
```

*Case 1: a branch stacked on a branch that was squash-merged.* `feat/ingest-cleaner` was built on `feat/ingest-loader`. The loader work has since landed on `main` as one squashed commit, with a small change made during review:

<!-- snippet: ch09/onto-stacked/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 2b2840e (main) Add document loader (#41)
* 9ba5170 Add README
| * 05dc4ce (HEAD -> feat/ingest-cleaner) Collapse repeated whitespace
| * 3c47896 Add text cleaner
| * 7fea52c (feat/ingest-loader) Close files after loading
| * 531d3da Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/onto-stacked/02-which-commits -->
```text
# What a plain "git rebase main" would replay:
$ git log --oneline main..feat/ingest-cleaner
05dc4ce Collapse repeated whitespace
3c47896 Add text cleaner
7fea52c Close files after loading
531d3da Add document loader
# What belongs to this branch alone:
$ git log --oneline feat/ingest-loader..feat/ingest-cleaner
05dc4ce Collapse repeated whitespace
3c47896 Add text cleaner
```
<!-- /snippet -->

<!-- snippet: ch09/onto-stacked/03-plain-rebase-conflicts -->
```text
$ git rebase main
Rebasing (1/4)
Auto-merging ingest/loader.py
CONFLICT (add/add): Merge conflict in ingest/loader.py
error: could not apply 531d3da... Add document loader
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 531d3da... # Add document loader
[exit status: 1]
$ git rebase --abort
```
<!-- /snippet -->

```text
Observed behavior : "git rebase main" stops at once with a conflict in ingest/loader.py,
                    a file your branch never touched.
Git state         : main..feat/ingest-cleaner contains four commits: your two, and the two
                    loader commits below them.
Mechanism         : Rebase replays everything not reachable from main. The loader commits are
                    not reachable from main: main has their content in another commit (the
                    squash), not the commits themselves.
Root cause        : Git has no record that your branch "belongs on top of" another branch.
                    It knows reachability only.
Why Git does this : A branch is a ref to a commit. "My commits" is something only you can
                    define, by naming a boundary.
Correct fix       : git rebase --onto main feat/ingest-loader feat/ingest-cleaner
Prevention        : For a stacked branch, name the boundary whenever the branch below it
                    lands in another form.
```

<!-- snippet: ch09/onto-stacked/04-onto -->
```text
$ git rebase --onto main feat/ingest-loader feat/ingest-cleaner
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest-cleaner.
$ git log --oneline --graph --decorate --all
* f35e612 (HEAD -> feat/ingest-cleaner) Collapse repeated whitespace
* 085d42e Add text cleaner
* 2b2840e (main) Add document loader (#41)
* 9ba5170 Add README
| * 7fea52c (feat/ingest-loader) Close files after loading
| * 531d3da Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

> **GitHub, not Git.** "Squash and merge" puts one new commit on the base branch; the commits of the head branch do not become ancestors of it. GitHub's documentation warns that continuing to work on a head branch after it was squash-merged makes later pull requests list the squashed commits again and repeat conflicts ([about merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github)). Case 1 is the Git-side remedy.

*Case 2: sideways, onto an older line.* `fix/timeout` was cut from `main`, which already carries work for 2.0. The fix has to ship from `release/1.4`:

<!-- snippet: ch09/onto-sideways/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 91476e2 (HEAD -> fix/timeout) Return no documents when search times out
* 1c42ebc Add a timeout to search calls
* c49bad6 (main) Switch default model to large-v3 for 2.0
* 16dfe8e Start 2.0: add async search client
* 8afc6bd (release/1.4) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/onto-sideways/02-onto -->
```text
$ git rebase --onto release/1.4 main fix/timeout
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/fix/timeout.
$ git log --oneline --graph --decorate --all
* 594044f (HEAD -> fix/timeout) Return no documents when search times out
* 58c909f Add a timeout to search calls
| * c49bad6 (main) Switch default model to large-v3 for 2.0
| * 16dfe8e Start 2.0: add async search client
|/  
* 8afc6bd (release/1.4) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/onto-sideways/03-check -->
```text
$ git diff --stat release/1.4 fix/timeout
 app/retriever.py | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)
$ ls app
retriever.py
```
<!-- /snippet -->

`main` served only as the boundary: "my commits are the ones after `main`". The check confirms that one file differs from the release and that the 2.0 client did not come along.

*Case 3: cutting commits out of the middle.* Two experiment commits sit in the middle of `feat/rerank`:

<!-- snippet: ch09/onto-cut/01-before -->
```text
$ git log --oneline --decorate
6ab8f55 (HEAD -> feat/rerank) Enable reranking in config
45f4f23 Call reranker from retriever
e30ba74 Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/onto-cut/02-onto -->
```text
# Keep everything up to feat/rerank~4, drop ~3 and ~2, replay ~1 and the tip.
$ git rebase --onto feat/rerank~4 feat/rerank~2 feat/rerank
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/rerank.
$ git log --oneline --decorate
31e8a4d (HEAD -> feat/rerank) Enable reranking in config
a15178d Call reranker from retriever
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/onto-cut/03-check -->
```text
$ git diff --stat ORIG_HEAD HEAD
 app/cross_encoder.py | 7 -------
 1 file changed, 7 deletions(-)
```
<!-- /snippet -->

The copies are built on `feat/rerank~4`, and the boundary `feat/rerank~2` excludes everything up to and including the second experiment. The diff against `ORIG_HEAD` shows exactly one file gone. The same result comes from `drop` in an interactive rebase (section 9.6); this form is the one you can script.

**`--root`.** Without a boundary, the root commit itself is in the range, so even the first commit can be reworded:

<!-- snippet: ch09/rebase-root/02-root -->
```text
$ git rebase -i --root
--- todo list as Git opened it (comment lines removed) ---
pick 8afc6bd # Add retriever and model config
pick 589d18b # Add README
pick 82f1fbb # Upgrade model to small-v2
--- todo list as saved ---
reword 8afc6bd # Add retriever and model config
pick 589d18b # Add README
pick 82f1fbb # Upgrade model to small-v2
Rebasing (1/3)
[detached HEAD 580b0da] Add retriever and default model configuration
 Date: Mon Sep 7 10:02:00 2026 +0530
 2 files changed, 7 insertions(+)
 create mode 100644 app/retriever.py
 create mode 100644 config/model.yaml
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/main.
```
<!-- /snippet -->

<!-- snippet: ch09/rebase-root/03-after -->
```text
$ git log --oneline --decorate
6cdce43 (HEAD -> main) Upgrade model to small-v2
ffe456d Add README
580b0da Add retriever and default model configuration
$ git log --oneline ORIG_HEAD
82f1fbb Upgrade model to small-v2
589d18b Add README
8afc6bd Add retriever and model config
$ git merge-base HEAD ORIG_HEAD
[exit status: 1]
```
<!-- /snippet -->

Every commit has a new ID, and `git merge-base` exits with status 1: the new history and the old one have no commit in common. On a repository that others have cloned, that is a rewrite of the whole project, with every consequence of section 9.15 multiplied by the number of clones.

**`--keep-base`.** Tidy a branch without catching up. The copies are built on the merge base the branch already has:

<!-- snippet: ch09/keep-base/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 9ba5170 (main) Add README
| * 028ba01 (HEAD -> feat/metrics) fixup! Add exact_match metric
| * a25e84c Add token-level F1 metric
| * 375df0b Test exact_match
| * 143e55a Add exact_match metric
|/  
* 8afc6bd Add retriever and model config
$ git merge-base main feat/metrics
8afc6bd28c2572af09f1b6c37d733535230e526f
```
<!-- /snippet -->

<!-- snippet: ch09/keep-base/02-keep-base -->
```text
$ git rebase --autosquash --keep-base main
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

<!-- snippet: ch09/keep-base/03-after -->
```text
$ git log --oneline --graph --decorate --all
* e4d27a0 (HEAD -> feat/metrics) Add token-level F1 metric
* 2b30819 Test exact_match
* fa4c85b Add exact_match metric
| * 9ba5170 (main) Add README
|/  
* 8afc6bd Add retriever and model config
$ git merge-base main feat/metrics
8afc6bd28c2572af09f1b6c37d733535230e526f
```
<!-- /snippet -->

The `fixup!` commit was folded into its target (section 9.7), and the branch still forks from `8afc6bd` although `main` has moved on. The progress counter starts at 2 because instruction 1, a pick whose parent is already the base, needed no new commit: Git fast-forwards over instructions that would recreate what exists.

**In production.** Reviewers of a force-pushed branch want to know what changed in your commits. If one push both tidies and catches up, that answer is mixed with a week of upstream changes. Tidy with `--keep-base` and push; catch up with a plain rebase and push again. Each push then has one explanation.

## 9.6 Interactive rebase

**In one sentence.** `git rebase -i <base>` shows you the to-do list before executing it, and the list is a program: one instruction per line, executed from top to bottom, that you may edit, reorder, extend or shorten.

**Analogy.** An edit decision list in film editing: a list of takes with an instruction for each (keep, cut, join with the previous one, retitle). The footage is not altered; a new reel is assembled from it. The analogy breaks where commits depend on each other: move a take and the film still plays, move a commit in front of the commit it builds on and the replay stops with a conflict.

**Precisely.** The instructions, as listed by Git itself in the transcript below:

| Instruction | Short | Effect |
|---|---|---|
| `pick <commit>` | `p` | Replay the commit as it is |
| `reword <commit>` | `r` | Replay it, then open the editor on its message |
| `edit <commit>` | `e` | Replay it, then stop so that you can amend or split it |
| `squash <commit>` | `s` | Meld it into the commit on the line above; the editor opens on both messages |
| `fixup <commit>` | `f` | Meld it into the commit above and keep that commit's message. `fixup -C` keeps this commit's message instead; `-c` also opens the editor |
| `drop <commit>` | `d` | Leave the commit out |
| `exec <command>` | `x` | Run a shell command; a non-zero exit status stops the rebase |
| `break` | `b` | Stop here |
| `label`, `reset`, `merge` | `l`, `t`, `m` | Rebuild a branch structure (section 9.10) |
| `update-ref <ref>` | `u` | Move another branch to this point when the rebase finishes (section 9.9) |
| a line moved | | The commit is replayed at its new position |
| a line deleted | | The same as `drop`, without a word |

`<base>` is the last commit you want to keep as it is: `git rebase -i main` offers every commit of the branch, `git rebase -i HEAD~3` the last three.

**Inside `.git`.** Nothing new. It is the machinery of section 9.4, with one difference: the instruction file is handed to your editor before execution starts. The editor is `sequence.editor` or `GIT_SEQUENCE_EDITOR` if set, otherwise your normal commit message editor.

**See it.** A branch as it looks after a day of real work:

<!-- snippet: ch09/interactive-basics/01-messy -->
```text
$ git log --oneline --decorate
8313de0 (HEAD -> feat/metrics) fix test
031999d Add token-level F1 metirc
25dc48e debug print
cdb5f2f add test
a1056e1 wip
d33e9b2 Add exact_match metric
061c92d (main) Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

First, the list exactly as Git writes it. Using `cat` as the editor prints the file and saves it unchanged, so this rebase does nothing:

<!-- snippet: ch09/interactive-basics/02-list -->
```text
# Using "cat" as the editor prints the todo list exactly as Git wrote it and saves it unchanged.
$ GIT_SEQUENCE_EDITOR=cat git rebase -i main
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test

# Rebase 061c92d..8313de0 onto 061c92d (6 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
#                    commit's log message, unless -C is used, in which case
#                    keep only this commit's message; -c is same as -C but
#                    opens the editor
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
# l, label <label> = label current HEAD with a name
# t, reset <label> = reset HEAD to a label
# m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
#         create a merge commit using the original merge commit's
#         message (or the oneline, if no original merge commit was
#         specified); use -c <commit> to reword the commit message
# u, update-ref <ref> = track a placeholder for the <ref> to be updated
#                       to this position in the new commits. The <ref> is
#                       updated at the end of the rebase
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

The list runs oldest first, the opposite of `git log`. The comment block is the complete reference. Now six rebases, each with one edit, so that each instruction can be seen alone. In practice you make all edits in one pass (Lab 9.1).

`reword`, on the commit with the typo in its subject:

<!-- snippet: ch09/interactive-basics/03-reword -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
--- todo list as saved ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
reword 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
Rebasing (5/6)
[detached HEAD a2fd360] Add token-level F1 metric
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 4 insertions(+)
 create mode 100644 eval/f1.py
Rebasing (6/6)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline
fcea3ea fix test
a2fd360 Add token-level F1 metric
25dc48e debug print
cdb5f2f add test
a1056e1 wip
d33e9b2 Add exact_match metric
061c92d Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

Progress starts at `(5/6)`. Lines 1 to 4 were unchanged, so Git fast-forwarded over them, and the first four commits kept their IDs. Only the reworded commit and the one after it are new objects (`a2fd360`, `fcea3ea`).

`fixup`, to fold "wip" into the commit above it:

<!-- snippet: ch09/interactive-basics/04-fixup -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick a2fd360 # Add token-level F1 metric
pick fcea3ea # fix test
--- todo list as saved ---
pick d33e9b2 # Add exact_match metric
fixup a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick a2fd360 # Add token-level F1 metric
pick fcea3ea # fix test
Rebasing (2/6)
Rebasing (3/6)
Rebasing (4/6)
Rebasing (5/6)
Rebasing (6/6)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline
92f52c5 fix test
3838789 Add token-level F1 metric
0d58a02 debug print
babe12d add test
753f401 Add exact_match metric
061c92d Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

Six commits became five, and all five have new IDs: the first because "wip" was melded into it, the others because their parent changed.

Reordering, to bring "fix test" directly behind "add test":

<!-- snippet: ch09/interactive-basics/05-reorder -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 753f401 # Add exact_match metric
pick babe12d # add test
pick 0d58a02 # debug print
pick 3838789 # Add token-level F1 metric
pick 92f52c5 # fix test
--- todo list as saved ---
pick 753f401 # Add exact_match metric
pick babe12d # add test
pick 92f52c5 # fix test
pick 0d58a02 # debug print
pick 3838789 # Add token-level F1 metric
Rebasing (3/5)
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline
8f81a9f Add token-level F1 metric
9013484 debug print
1537b45 fix test
babe12d add test
753f401 Add exact_match metric
061c92d Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

`squash`, now that the two test commits are neighbours. The editor opens on the combined message, and the scripted editor types a better one:

<!-- snippet: ch09/interactive-basics/06-squash -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 753f401 # Add exact_match metric
pick babe12d # add test
pick 1537b45 # fix test
pick 9013484 # debug print
pick 8f81a9f # Add token-level F1 metric
--- todo list as saved ---
pick 753f401 # Add exact_match metric
pick babe12d # add test
squash 1537b45 # fix test
pick 9013484 # debug print
pick 8f81a9f # Add token-level F1 metric
Rebasing (3/5)
[detached HEAD 62a8273] Test exact_match, including surrounding whitespace
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 5 insertions(+)
 create mode 100644 tests/test_metrics.py
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline
45ad5b3 Add token-level F1 metric
fe1bccf debug print
62a8273 Test exact_match, including surrounding whitespace
753f401 Add exact_match metric
061c92d Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

What does the editor show at that moment? On a cleaner branch, with `cat` standing in for the message editor:

<!-- snippet: ch09/squash-message/01-squash-buffer -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 143e55a # Add exact_match metric
pick 375df0b # Test exact_match
pick a25e84c # Add token-level F1 metric
--- todo list as saved ---
pick 143e55a # Add exact_match metric
squash 375df0b # Test exact_match
pick a25e84c # Add token-level F1 metric
Rebasing (2/3)
# This is a combination of 2 commits.
# This is the 1st commit message:

Add exact_match metric

# This is the commit message #2:

Test exact_match

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Mon Sep 7 10:03:00 2026 +0530
#
# interactive rebase in progress; onto 8afc6bd
# Last commands done (2 commands done):
#    pick 143e55a # Add exact_match metric
#    squash 375df0b # Test exact_match
# Next command to do (1 remaining command):
#    pick a25e84c # Add token-level F1 metric
# You are currently rebasing branch 'feat/metrics' on '8afc6bd'.
#
# Changes to be committed:
#	new file:   eval/metrics.py
#	new file:   tests/test_metrics.py
#
[detached HEAD 5a2e35c] Add exact_match metric
 Date: Mon Sep 7 10:03:00 2026 +0530
 2 files changed, 6 insertions(+)
 create mode 100644 eval/metrics.py
 create mode 100644 tests/test_metrics.py
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

Both messages, each under a comment line. Lines that start with `#` are removed when you save, so saving this buffer unchanged gives a message made of both texts. `fixup` skips this step and keeps the first message.

`drop`, for the debugging commit:

<!-- snippet: ch09/interactive-basics/07-drop -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 753f401 # Add exact_match metric
pick 62a8273 # Test exact_match, including surrounding whitespace
pick fe1bccf # debug print
pick 45ad5b3 # Add token-level F1 metric
--- todo list as saved ---
pick 753f401 # Add exact_match metric
pick 62a8273 # Test exact_match, including surrounding whitespace
drop fe1bccf # debug print
pick 45ad5b3 # Add token-level F1 metric
Rebasing (4/4)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline --decorate
d1d1482 (HEAD -> feat/metrics) Add token-level F1 metric
62a8273 Test exact_match, including surrounding whitespace
753f401 Add exact_match metric
061c92d (main) Add lint script
8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/interactive-basics/08-result -->
```text
$ git show --stat --format="%h %s" HEAD~2 HEAD~1 HEAD
753f401 Add exact_match metric

 eval/metrics.py | 2 ++
 1 file changed, 2 insertions(+)
62a8273 Test exact_match, including surrounding whitespace

 tests/test_metrics.py | 5 +++++
 1 file changed, 5 insertions(+)
d1d1482 Add token-level F1 metric

 eval/f1.py | 4 ++++
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

**`edit`: stop inside the history.** One commit of this branch mixes a new metric with a configuration change:

<!-- snippet: ch09/interactive-edit/01-before -->
```text
$ git log --oneline --decorate
4394181 (HEAD -> feat/metrics) Test both metrics
0527727 Add F1 metric and raise max_tokens
c1adfe1 Add exact_match metric
8afc6bd (main) Add retriever and model config
$ git show --stat --format="%h %s" HEAD~1
0527727 Add F1 metric and raise max_tokens

 config/model.yaml | 2 +-
 eval/f1.py        | 4 ++++
 2 files changed, 5 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch09/interactive-edit/02-edit-stops -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick c1adfe1 # Add exact_match metric
pick 0527727 # Add F1 metric and raise max_tokens
pick 4394181 # Test both metrics
--- todo list as saved ---
pick c1adfe1 # Add exact_match metric
edit 0527727 # Add F1 metric and raise max_tokens
pick 4394181 # Test both metrics
Rebasing (2/3)
Stopped at 0527727...  # Add F1 metric and raise max_tokens
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
```
<!-- /snippet -->

The rebase has replayed that commit and stopped. You are on a detached HEAD with the commit as the tip. To split it, take the commit back while keeping its changes in the working tree, and commit them in two portions:

<!-- snippet: ch09/interactive-edit/03-split -->
```text
$ git reset HEAD^
Unstaged changes after reset:
M	config/model.yaml
$ git status --short
 M config/model.yaml
?? eval/f1.py
$ git add eval/f1.py
$ git commit -m "Add token-level F1 metric"
[detached HEAD 47852a1] Add token-level F1 metric
 1 file changed, 4 insertions(+)
 create mode 100644 eval/f1.py
$ git commit -a -m "Raise max_tokens to 1024 for long answers"
[detached HEAD 6501387] Raise max_tokens to 1024 for long answers
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch09/interactive-edit/04-continue -->
```text
$ git rebase --continue
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline --decorate
d0c6470 (HEAD -> feat/metrics) Test both metrics
6501387 Raise max_tokens to 1024 for long answers
47852a1 Add token-level F1 metric
c1adfe1 Add exact_match metric
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

`git reset HEAD^` is a mixed reset ([Chapter 11](ch11-reset-revert-restore.md)): HEAD and the index go back one commit, the files stay. (`HEAD~1` names the same commit and is the safer spelling in shells that treat `^` as a pattern character.) It has a side effect that matters after the rebase:

<!-- snippet: ch09/interactive-edit/05-orig-head-moved -->
```text
# ORIG_HEAD no longer names the tip from before the rebase: "git reset" overwrote it.
$ git rev-parse --short ORIG_HEAD
0527727
$ git diff --stat ORIG_HEAD HEAD
 tests/test_metrics.py | 8 ++++++++
 1 file changed, 8 insertions(+)
# The reflog of the branch still has the old tip. The two trees are identical, so this prints nothing:
$ git diff --stat feat/metrics@{1} feat/metrics
$ git reflog show feat/metrics -2
d0c6470 feat/metrics@{0}: rebase (finish): refs/heads/feat/metrics onto 8afc6bd28c2572af09f1b6c37d733535230e526f
4394181 feat/metrics@{1}: commit: Test both metrics
```
<!-- /snippet -->

`git reset` writes `ORIG_HEAD` too, so `ORIG_HEAD` no longer names the tip from before the rebase. The reflog of the branch does.

**`exec`: test every commit.** A rewritten history is a series of snapshots that nobody has run. `--exec` adds an `exec` line after every commit:

<!-- snippet: ch09/interactive-exec/02-exec-stops -->
```text
$ git rebase --exec "sh scripts/check.sh" main
Rebasing (2/6)
Executing: sh scripts/check.sh
check passed
Rebasing (3/6)
Rebasing (4/6)
Executing: sh scripts/check.sh
eval/f1.py:3:    print("DEBUG", p, g)
check failed: remove the debug print
warning: execution failed: sh scripts/check.sh
You can fix the problem, and then run

  git rebase --continue


[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch09/interactive-exec/03-where -->
```text
$ git log --oneline --decorate -2
67c1620 (HEAD) Add token-level F1 metric
625fdb8 Add exact_match metric
$ cat .git/rebase-merge/git-rebase-todo
pick f73498cc94810e2909007a8eed1a685eeedc687d # Test both metrics
exec sh scripts/check.sh
```
<!-- /snippet -->

The check passed after the first commit and failed after the second. The rebase stopped there, with the failing commit as HEAD and the rest of the list waiting. Repair the commit and continue:

<!-- snippet: ch09/interactive-exec/04-fix-and-continue -->
```text
# In an editor: delete the DEBUG line from eval/f1.py. Then:
$ git diff --stat
 eval/f1.py | 1 -
 1 file changed, 1 deletion(-)
$ git commit -a --amend --no-edit
[detached HEAD 674e131] Add token-level F1 metric
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 4 insertions(+)
 create mode 100644 eval/f1.py
$ git rebase --continue
Rebasing (5/6)
Rebasing (6/6)
Executing: sh scripts/check.sh
check passed
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

`exec` is an ordinary line. With `-i --exec` you see the generated lines and may remove some. Here only the last one is kept:

<!-- snippet: ch09/interactive-exec-lines/01-exec-lines -->
```text
$ git rebase -i --exec "sh scripts/check.sh" main
--- todo list as Git opened it (comment lines removed) ---
pick 625fdb8 # Add exact_match metric
exec sh scripts/check.sh
pick 67c1620 # Add token-level F1 metric
exec sh scripts/check.sh
pick f73498c # Test both metrics
exec sh scripts/check.sh
--- todo list as saved ---
pick 625fdb8 # Add exact_match metric
pick 67c1620 # Add token-level F1 metric
pick f73498c # Test both metrics
exec sh scripts/check.sh
Rebasing (4/4)
Executing: sh scripts/check.sh
eval/f1.py:3:    print("DEBUG", p, g)
check failed: remove the debug print
warning: execution failed: sh scripts/check.sh
You can fix the problem, and then run

  git rebase --continue
```
<!-- /snippet -->

The check now fails at the tip. You learn that the branch is broken, not which commit broke it. That is the argument for one `exec` per commit.

**`break` and changing the plan.** `break` stops the rebase without touching a commit, so that you can look around:

<!-- snippet: ch09/interactive-break/01-break -->
```text
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
--- todo list as saved ---
pick d33e9b2 # Add exact_match metric
pick a1056e1 # wip
pick cdb5f2f # add test
break
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
Rebasing (4/7)
Stopped at cdb5f2f (add test)
```
<!-- /snippet -->

While any rebase is stopped, you can reopen the remaining instructions in the editor:

```bash
git rebase --edit-todo
```

<!-- snippet: ch09/interactive-break/03-edit-list -->
```text
$ git rebase --edit-todo
--- todo list as Git opened it (comment lines removed) ---
pick 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
--- todo list as saved ---
drop 25dc48e # debug print
pick 031999d # Add token-level F1 metirc
pick 8313de0 # fix test
```
<!-- /snippet -->

<!-- snippet: ch09/interactive-break/04-continue -->
```text
$ git rebase --continue
Rebasing (5/7)
Rebasing (6/7)
Rebasing (7/7)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline --decorate
2d1d481 (HEAD -> feat/metrics) fix test
c7c12a0 Add token-level F1 metirc
cdb5f2f add test
a1056e1 wip
d33e9b2 Add exact_match metric
061c92d (main) Add lint script
8afc6bd Add retriever and model config
$ sh scripts/check.sh
check passed
```
<!-- /snippet -->

Only the instructions not yet executed are offered. What is done is done; to change that, abort and start again.

**In production.** The purpose of a tidy history is not beauty. `git bisect` ([Chapter 14A](ch14a-history-investigation.md)) can find a regression only if every commit builds, and a revert removes one decision only if a commit contains one decision. A branch cleaned up with `git rebase -i --exec "<your test command>" main` has been proved commit by commit. The one line to remember from the comment block is the one in capitals: a deleted line is a lost commit, and Git does not ask. `rebase.missingCommitsCheck` turns that silence into a warning or an error (Lab 9.1).

## 9.7 Fixup commits and `--autosquash`

**In one sentence.** A fixup commit is a correction recorded now, as a commit of its own, whose subject line names the earlier commit it belongs to; `--autosquash` reads those subjects and arranges the to-do list for you.

**Precisely.** 🟢 `git commit` creates them with three kinds of subject ([git-commit](https://git-scm.com/docs/git-commit)):

| Created with | Subject of the new commit | Becomes in the list | Effect on the target |
|---|---|---|---|
| `git commit --fixup=<commit>` | `fixup! <target subject>` | `fixup` | Content corrected, message kept |
| `git commit --squash=<commit>` | `squash! <target subject>` | `squash` | Content corrected, editor opens on both messages |
| `git commit --fixup=amend:<commit>` | `amend! <target subject>` | `fixup -C` | Content corrected, message replaced |
| `git commit --fixup=reword:<commit>` | `amend! <target subject>` | `fixup -C` | Message replaced, content untouched |

**See it.** Three review comments on a three-commit branch, each answered with a commit addressed to the commit it concerns:

<!-- snippet: ch09/autosquash/02-fixup-commit -->
```text
# Review comment 1: exact_match must ignore surrounding whitespace. That belongs in the first commit.
$ git diff
diff --git a/eval/metrics.py b/eval/metrics.py
index a82fda1..652e0e2 100644
--- a/eval/metrics.py
+++ b/eval/metrics.py
@@ -1,2 +1,2 @@
 def exact_match(pred, gold):
-    return pred == gold
+    return pred.strip() == gold.strip()
$ git commit -a --fixup=HEAD~2
[feat/metrics 2c37c8c] fixup! Add exact_match metric
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch09/autosquash/03-squash-commit -->
```text
# Review comment 2: cover disjoint answers in the F1 test. That belongs in the last commit, with a note.
$ git commit -a --squash=HEAD~1 -m "Also covers the zero-overlap case."
[feat/metrics 02094a9] squash! Add token-level F1 metric
 1 file changed, 3 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch09/autosquash/04-amend-commit -->
```text
# Review comment 3: the message of "Test exact_match" should say what is tested. Only the message changes.
$ git commit --fixup=reword:HEAD~3
[feat/metrics eaf99b7] amend! Test exact_match
```
<!-- /snippet -->

<!-- snippet: ch09/autosquash/05-log -->
```text
$ git log --oneline --decorate
eaf99b7 (HEAD -> feat/metrics) amend! Test exact_match
02094a9 squash! Add token-level F1 metric
2c37c8c fixup! Add exact_match metric
a25e84c Add token-level F1 metric
375df0b Test exact_match
143e55a Add exact_match metric
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/autosquash/06-autosquash -->
```text
$ git rebase -i --autosquash main
--- todo list as Git opened it (comment lines removed) ---
pick 143e55a # Add exact_match metric
fixup 2c37c8c # fixup! Add exact_match metric
pick 375df0b # Test exact_match
fixup -C eaf99b7 # amend! Test exact_match # empty
pick a25e84c # Add token-level F1 metric
squash 02094a9 # squash! Add token-level F1 metric
--- todo list as saved ---
pick 143e55a # Add exact_match metric
fixup 2c37c8c # fixup! Add exact_match metric
pick 375df0b # Test exact_match
fixup -C eaf99b7 # amend! Test exact_match # empty
pick a25e84c # Add token-level F1 metric
squash 02094a9 # squash! Add token-level F1 metric
Rebasing (2/6)
Rebasing (3/6)
Rebasing (4/6)
Rebasing (5/6)
Rebasing (6/6)
[detached HEAD 7f88f67] Add token-level F1 metric
 Date: Mon Sep 7 10:05:00 2026 +0530
 2 files changed, 11 insertions(+)
 create mode 100644 eval/f1.py
Successfully rebased and updated refs/heads/feat/metrics.
```
<!-- /snippet -->

The list arrives already arranged: every correction sits directly below its target with the right instruction, and `# empty` marks the commit that carries only a message. The editor opens once, for the `squash`.

<!-- snippet: ch09/autosquash/07-after -->
```text
$ git log --oneline --decorate
7f88f67 (HEAD -> feat/metrics) Add token-level F1 metric
8c07d2a Test exact_match on identical strings
6b055fc Add exact_match metric
8afc6bd (main) Add retriever and model config
$ git log -1 --format=%B
Add token-level F1 metric

Tested on identical and on disjoint answers.

$ git diff --stat ORIG_HEAD HEAD
```
<!-- /snippet -->

Three commits again, with the corrected messages. The last command prints nothing: the tree at the tip is identical before and after. Autosquash changes how the history is cut into commits, not what the branch contains. Without `-i` the list is not shown at all:

<!-- snippet: ch09/autosquash/08-non-interactive -->
```text
# One more fix, this time without opening the todo list at all.
$ git commit -a --fixup=HEAD
[feat/metrics 06c9467] fixup! Add token-level F1 metric
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git rebase --autosquash main
Rebasing (4/4)
Successfully rebased and updated refs/heads/feat/metrics.
$ git log --oneline --decorate
dc93e0c (HEAD -> feat/metrics) Add token-level F1 metric
8c07d2a Test exact_match on identical strings
6b055fc Add exact_match metric
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

One trap in the configuration. `rebase.autoSquash` exists so that you need not type the option:

<!-- snippet: ch09/autosquash-config/01-config-and-plain-rebase -->
```text
$ git config set rebase.autoSquash true
$ git log --oneline --decorate
028ba01 (HEAD -> feat/metrics) fixup! Add exact_match metric
a25e84c Add token-level F1 metric
375df0b Test exact_match
143e55a Add exact_match metric
8afc6bd (main) Add retriever and model config
$ git rebase main
Current branch feat/metrics is up to date.
$ git log --oneline --decorate -1
028ba01 (HEAD -> feat/metrics) fixup! Add exact_match metric
```
<!-- /snippet -->

> **Root cause.** The setting applies to interactive rebases only; the manual says "by default for interactive mode". A plain `git rebase main` on a branch that is already on top of `main` has nothing to do, reports "up to date", and leaves the `fixup!` commit in place. Type `--autosquash`, or use `-i`.

**In production.** During a review, answer each comment with a fixup commit and push normally: the reviewer sees every response as a small diff, and nothing is force-pushed meanwhile. Before the merge, one `git rebase -i --autosquash` and one force push fold everything. A CI job that fails while a subject starts with `fixup!`, `squash!` or `amend!` keeps unfolded corrections out of `main`; the check in Lab 9.3 is one line of `git log --grep`.

## 9.8 `--autostash`

**In one sentence.** A rebase refuses to start while tracked files have uncommitted changes; `--autostash` puts those changes into a stash commit, rebases, and applies the stash to the result.

**See it.**

<!-- snippet: ch09/autostash/01-dirty -->
```text
# An uncommitted experiment in the working tree:
$ git status --short
 M app/rerank.py
$ git rebase main
error: cannot rebase: You have unstaged changes.
error: Please commit or stash them.
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch09/autostash/02-autostash -->
```text
$ git rebase --autostash main
Created autostash: 855c10e
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Applied autostash.
Successfully rebased and updated refs/heads/feat/rerank.
$ git status --short
 M app/rerank.py
$ git stash list
```
<!-- /snippet -->

The edit is back in the working tree and the stash list is empty: an autostash is a stash commit ([Chapter 14C](ch14c-stash-rerere-attributes-hooks.md)) that is never put on the list. So where is your change while a rebase is stopped at a conflict?

<!-- snippet: ch09/autostash-stopped/02-where-is-it -->
```text
$ git status --short
UU app/retriever.py
$ git stash list
$ cat .git/rebase-merge/autostash
a73072956efd7f13df50384c97d52782d1dc32af
$ git stash show -p $(cat .git/rebase-merge/autostash)
diff --git a/config/model.yaml b/config/model.yaml
index 2d94ebc..d0061c7 100644
--- a/config/model.yaml
+++ b/config/model.yaml
@@ -2,3 +2,4 @@ model: small-v1
 temperature: 0.2
 max_tokens: 512
 rerank: true
+top_p: 0.9
```
<!-- /snippet -->

In no file of the working tree, and not on the stash list. Its ID is in the state directory. The two ways out treat it differently:

<!-- snippet: ch09/autostash-stopped/03-abort -->
```text
$ git rebase --abort
Applied autostash.
$ git status --short
 M config/model.yaml
```
<!-- /snippet -->

<!-- snippet: ch09/autostash-stopped/04-quit -->
```text
# The same stop again. This time the rebase is left with --quit.
$ git rebase --quit
Autostash exists; creating a new stash entry.
Your changes are safe in the stash.
You can run "git stash pop" or "git stash drop" at any time.
$ git stash list
stash@{0}: autostash
$ git status --short
UU app/retriever.py
```
<!-- /snippet -->

The last step can itself conflict, when the rebase brought in a change to the lines you had edited:

<!-- snippet: ch09/autostash/03-conflict-setup -->
```text
# main gained a commit that rewrites the README sentence. You have an uncommitted edit to the same sentence.
$ git status --short
 M README.md
$ git rebase --autostash main
Created autostash: 946f166
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Your local changes are stashed, however applying them
resulted in conflicts.  You can either resolve the conflicts
and then discard the stash with "git stash drop", or, if you
do not want to resolve them now, run "git reset --hard" and
apply the local changes later by running "git stash pop".
Successfully rebased and updated refs/heads/feat/rerank.
```
<!-- /snippet -->

<!-- snippet: ch09/autostash/04-conflict-state -->
```text
$ git status --short
UU README.md
$ git stash list
stash@{0}: autostash
$ cat README.md
# ragkit

<<<<<<< Updated upstream
Retrieval-augmented answering service with reranking.
=======
Retrieval-augmented answering service (internal).
>>>>>>> Stashed changes
$ git log --oneline --decorate -2
20835dd (HEAD -> feat/rerank) Enable reranking in config
c994617 Call reranker from retriever
```
<!-- /snippet -->

Read the last line of the rebase output first: the rebase succeeded and the branch has moved. What conflicted is the stash application afterwards. Git kept the stash on the list, and the markers are labelled `Updated upstream` (the rebased branch) and `Stashed changes` (your edit). Resolve the file, then `git stash drop`.

**In production.** `rebase.autoStash=true` makes this the default, and `git pull --rebase --autostash` does the same for pulls. The cost is that uncommitted work travels through a mechanism you do not see. If the change matters, commit it as work in progress before you rebase; a commit is in the reflog, an edit in the working tree is not.

## 9.9 Stacked branches and `--update-refs`

**In one sentence.** `--update-refs` makes a rebase move every local branch that points at one of the replayed commits, not only the branch you are on.

**Precisely.** For each such branch, Git adds a line `update-ref refs/heads/<name>` to the list, directly after the commit the branch points at, and sets the branch when the list is finished.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git rebase --update-refs <upstream>` | As a plain rebase | As a plain rebase | As a plain rebase | As a plain rebase | Every local branch that pointed into the range is set to the corresponding copy, with the reflog message "rewritten during rebase". Not moved: branches checked out in another worktree, tags, remote-tracking branches | unchanged | unchanged |

**See it.** Three branches, each built on the one below: a stack, the shape behind "stacked pull requests".

<!-- snippet: ch09/update-refs/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 9cfa98f (main) Add README
| * e86ad55 (HEAD -> feat/ingest-chunker) Make chunk size configurable
| * f3f4739 Add chunker
| * b10b821 (feat/ingest-cleaner) Add text cleaner
| * 7fea52c (feat/ingest-loader) Close files after loading
| * 531d3da Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

A plain rebase of the top branch:

<!-- snippet: ch09/update-refs/02-without -->
```text
$ git rebase main
Rebasing (1/5)
Rebasing (2/5)
Rebasing (3/5)
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/feat/ingest-chunker.
$ git log --oneline --graph --decorate --all
* a30ab1a (HEAD -> feat/ingest-chunker) Make chunk size configurable
* 59e5878 Add chunker
* 477c93c Add text cleaner
* 8b13775 Close files after loading
* 8e64e59 Add document loader
* 9cfa98f (main) Add README
| * b10b821 (feat/ingest-cleaner) Add text cleaner
| * 7fea52c (feat/ingest-loader) Close files after loading
| * 531d3da Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Only `feat/ingest-chunker` moved. The two lower branches still point at the old commits, and the top branch now contains private copies of their work. With the option, after going back to the start:

<!-- snippet: ch09/update-refs/04-with -->
```text
$ git rebase -i --update-refs main
--- todo list as Git opened it (comment lines removed) ---
pick 531d3da # Add document loader
pick 7fea52c # Close files after loading
update-ref refs/heads/feat/ingest-loader
pick b10b821 # Add text cleaner
update-ref refs/heads/feat/ingest-cleaner
pick f3f4739 # Add chunker
pick e86ad55 # Make chunk size configurable
--- todo list as saved ---
pick 531d3da # Add document loader
pick 7fea52c # Close files after loading
update-ref refs/heads/feat/ingest-loader
pick b10b821 # Add text cleaner
update-ref refs/heads/feat/ingest-cleaner
pick f3f4739 # Add chunker
pick e86ad55 # Make chunk size configurable
Rebasing (1/7)
Rebasing (2/7)
Rebasing (3/7)
Rebasing (4/7)
Rebasing (5/7)
Rebasing (6/7)
Rebasing (7/7)
Successfully rebased and updated refs/heads/feat/ingest-chunker.
Updated the following refs with --update-refs:
	refs/heads/feat/ingest-cleaner
	refs/heads/feat/ingest-loader
```
<!-- /snippet -->

<!-- snippet: ch09/update-refs/05-after -->
```text
$ git log --oneline --graph --decorate --all
* 4b52940 (HEAD -> feat/ingest-chunker) Make chunk size configurable
* c439cc8 Add chunker
* 06c29f9 (feat/ingest-cleaner) Add text cleaner
* 1599a67 (feat/ingest-loader) Close files after loading
* eed2aa8 Add document loader
* 9cfa98f (main) Add README
* 8afc6bd Add retriever and model config
$ git reflog show feat/ingest-loader -2
1599a67 feat/ingest-loader@{0}: rewritten during rebase
7fea52c feat/ingest-loader@{1}: commit: Close files after loading
```
<!-- /snippet -->

**Picture.**

```text
Before                                          After "git rebase --update-refs main" on the top branch

  A---R                 main                      A---R                               main
   \                                                   \
    L1--L2              feat/ingest-loader              L1'--L2'                      feat/ingest-loader
          \                                                    \
           C1           feat/ingest-cleaner                     C1'                   feat/ingest-cleaner
             \                                                     \
              K1--K2    feat/ingest-chunker                         K1'--K2'          feat/ingest-chunker (HEAD)
```

The option moves every branch in the range, including one you did not think of as part of the stack:

<!-- snippet: ch09/update-refs/06-backup-trap -->
```text
# A "backup" branch that points into the range is a branch like any other:
$ git branch backup/chunker
$ git tag before-rebase
$ git rebase --update-refs main
Rebasing (1/8)
Rebasing (2/8)
Rebasing (3/8)
Rebasing (4/8)
Rebasing (5/8)
Rebasing (6/8)
Rebasing (7/8)
Rebasing (8/8)
Successfully rebased and updated refs/heads/feat/ingest-chunker.
Updated the following refs with --update-refs:
	refs/heads/backup/chunker
	refs/heads/feat/ingest-cleaner
	refs/heads/feat/ingest-loader
$ git log --oneline --decorate -1 backup/chunker
2925218 (HEAD -> feat/ingest-chunker, backup/chunker) Make chunk size configurable
$ git log --oneline --decorate -1 before-rebase
4b52940 (tag: before-rebase) Make chunk size configurable
```
<!-- /snippet -->

> **Root cause.** A "backup" made with `git branch` is a branch that points into the rebased range, so `--update-refs` moved it along with the others, and it no longer backs anything up. The tag stayed. Before a risky rebase, mark the old tip with a tag, or write down the ID, or rely on the reflog.

The undo is also per branch. 🔴 `git reset --hard ORIG_HEAD` (section 9.16) restores the branch you are on; each of the others has to be put back from its own reflog (Lab 9.7). Publishing is per branch as well, in one command, where every ref gets its own lease (section 9.17):

<!-- snippet: ch09/update-refs-push/03-push-the-stack -->
```text
$ git push --force-with-lease --force-if-includes origin feat/ingest-loader feat/ingest-cleaner feat/ingest-chunker
To ../server.git
 + 31e0e7e...82bd9b8 feat/ingest-chunker -> feat/ingest-chunker (forced update)
 + b10b821...3616f79 feat/ingest-cleaner -> feat/ingest-cleaner (forced update)
 + 7fea52c...129c95a feat/ingest-loader -> feat/ingest-loader (forced update)
```
<!-- /snippet -->

**In production.** A large change reviewed as a chain of small pull requests lives or dies by this option: every review fix in the lowest branch has to ripple upward. `git config set rebase.updateRefs true` makes it the default.

## 9.10 Branches that contain merges: `--rebase-merges`

**In one sentence.** By default a rebase leaves merge commits out and lays all other commits out in one line; `--rebase-merges` rebuilds the branch structure, merge commits included.

**See it.** `feat/ingest` contains a merge of a side branch:

<!-- snippet: ch09/rebase-merges/01-before -->
```text
$ git log --oneline --graph --decorate --all
* 9cfa98f (main) Add README
| * 75c9283 (HEAD -> feat/ingest) Wire loader, cleaner and chunker together
| *   7537190 Merge branch 'feat/ingest-cleaner' into feat/ingest
| |\  
| | * dc5df93 (feat/ingest-cleaner) Add text cleaner
| * | 9a23ecd Add chunker
| |/  
| * 1279adf Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/rebase-merges/02-flattened -->
```text
$ git rebase main
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate feat/ingest
* c623381 (HEAD -> feat/ingest) Wire loader, cleaner and chunker together
* f4b3cef Add text cleaner
* 043ec63 Add chunker
* a10544a Add document loader
* 9cfa98f (main) Add README
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Four commits in a line; the merge commit is gone. Whatever existed only in the merge commit, such as a conflict resolution or a fix made while merging, is not replayed, so the conflict it resolved comes back at one of the single commits. With `-r`, after going back:

<!-- snippet: ch09/rebase-merges/04-rebase-merges -->
```text
$ git rebase -i --rebase-merges main
--- todo list as Git opened it (comment lines removed) ---
label onto
reset onto
pick 1279adf # Add document loader
label branch-point
pick dc5df93 # Add text cleaner
label feat-ingest-cleaner
reset branch-point # Add document loader
pick 9a23ecd # Add chunker
merge -C 7537190 feat-ingest-cleaner # Merge branch 'feat/ingest-cleaner' into feat/ingest
pick 75c9283 # Wire loader, cleaner and chunker together
--- todo list as saved ---
label onto
reset onto
pick 1279adf # Add document loader
label branch-point
pick dc5df93 # Add text cleaner
label feat-ingest-cleaner
reset branch-point # Add document loader
pick 9a23ecd # Add chunker
merge -C 7537190 feat-ingest-cleaner # Merge branch 'feat/ingest-cleaner' into feat/ingest
pick 75c9283 # Wire loader, cleaner and chunker together
Rebasing (1/10)
Rebasing (2/10)
Rebasing (3/10)
Rebasing (4/10)
Rebasing (5/10)
Rebasing (6/10)
Rebasing (7/10)
Rebasing (8/10)
Rebasing (9/10)
Rebasing (10/10)
Successfully rebased and updated refs/heads/feat/ingest.
```
<!-- /snippet -->

The list has become a small graph program. `label onto` names the new base. `reset onto` moves HEAD there. After the first pick, `label branch-point` remembers where the side branch forks. The side commit is picked and labelled. `reset branch-point` goes back, the mainline commit is picked, and `merge -C 7537190 feat-ingest-cleaner` makes a new merge with the message of the old one. Labels are temporary refs under `refs/rewritten/`, deleted when the rebase ends.

<!-- snippet: ch09/rebase-merges/05-after -->
```text
$ git log --oneline --graph --decorate --all
* a52bef6 (HEAD -> feat/ingest) Wire loader, cleaner and chunker together
*   5fff212 Merge branch 'feat/ingest-cleaner' into feat/ingest
|\  
| * 3452235 Add text cleaner
* | 7187f81 Add chunker
|/  
* 8cf8070 Add document loader
* 9cfa98f (main) Add README
| * dc5df93 (feat/ingest-cleaner) Add text cleaner
| * 1279adf Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

Two details. The branch `feat/ingest-cleaner` still points at the old commit `dc5df93`: `-r` rebuilds commits, it does not move other branches; add `--update-refs` for that. And the new merge is a fresh merge: the manual states that conflict resolutions and manual amendments in the original merge commits have to be redone by hand. Recorded resolutions (rerere, Chapter 14C) reduce that work.

<!-- snippet: ch09/rebase-merges/06-preserve-merges -->
```text
$ git rebase --preserve-merges main
fatal: --preserve-merges was replaced by --rebase-merges
Note: Your `pull.rebase` configuration may also be set to 'preserve',
which is no longer supported; use 'merges' instead
[exit status: 128]
```
<!-- /snippet -->

> **Outdated advice.** `git rebase -p` or `--preserve-merges`, and `pull.rebase=preserve`, appear in older tutorials. The option was deprecated in Git 2.22 and removed in 2.34; Git 2.55 answers with the fatal message above. Use `--rebase-merges` and `pull.rebase=merges` ([git-rebase](https://github.com/git/git/blob/v2.56.0/Documentation/git-rebase.adoc)).

**In production.** When a branch contains merges, first ask whether it should be rebased at all. A long-lived integration branch that others pull from should not. On your own topic branch into which you merged `main` twice, the plain, flattening rebase is usually what you want.

## 9.11 Conflicts during a rebase: who is "ours"

**In one sentence.** During a rebase, "ours" is the new base plus the copies made so far, and "theirs" is your own commit, the one being replayed: the opposite of what the words suggest.

**Analogy.** A rebase checks out the other side's latest commit and then merges your commits into it, one at a time. In each of those merges the house belongs to the other side and your commit is the visitor. The analogy is almost literal; it breaks only if you think of "ours" as a person. It is a position: whatever HEAD is.

**Precisely.** Each replay is a three-way merge into HEAD ([Chapter 8](ch08-merge.md), section 8.8, explains the stages). Stage 2, "ours", is HEAD: the upstream commit plus what has been replayed. Stage 3, "theirs", is `REBASE_HEAD`, your commit. Stage 1 is the parent of your commit. The local manual says it in one line: "the sides are swapped".

**See it.** The stopped rebase of section 9.4 again:

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

The upper half of the markers, labelled `HEAD`, is the value from `main`. The lower half, labelled with the ID and subject of your commit, is your value. Now integrate the same two branches with a merge, from the same branch:

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

Same two values, opposite positions.

| | `git merge main`, run on your branch | `git rebase main`, run on your branch |
|---|---|---|
| `<<<<<<< HEAD`, stage 2, `--ours`, `-X ours` | your branch | `main` plus your commits replayed so far |
| `>>>>>>>`, stage 3, `--theirs`, `-X theirs` | `main` | your commit being replayed |
| Stage 1, the base | the merge base of the two branches | the parent of your commit |
| How often it can stop | once | once per replayed commit |

To resolve, put the content you want into the file, stage it, and continue. Taking your own version whole is `--theirs` here (`git checkout --theirs -- <path>` in older scripts):

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

`--continue` commits the index as the copy of the stopped commit, opening your editor on its message first (the scripted editor accepts it), and runs the remaining instructions. The first copy is `b7e0843` here and was `1c9f69a` above: the demo restarted the rebase after the merge experiment, a few lab minutes later, and a later committer date gives another ID. If you know in advance which side should win every conflicting hunk, say so and the rebase does not stop:

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

**The ways out of a stop.**

| Command | Effect |
|---|---|
| 🟡 `git rebase --continue` | Commit the staged resolution as the copy and go on |
| 🟡 `git rebase --skip` | Make no copy of this commit and go on |
| 🟡 `git rebase --abort` | Put branch, index and working tree back as they were before the rebase |
| 🟡 `git rebase --quit` | Forget the rebase and leave HEAD, index and working tree as they are now |
| 🟢 `git rebase --show-current-patch` | Show the commit being replayed; the same as `git show REBASE_HEAD` |

`--abort` was shown in section 9.4. `--skip` gives a branch without the commit, and with the value from `main`:

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

`--quit` removes the state directory and nothing else:

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

The branch is untouched, HEAD is detached on the half-built history, and the index still holds the conflict. Use it when you want to keep that state and take over by hand. And if you try to move on before the conflict is resolved, or start a second rebase:

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

Take the first suggestion of that message, never the `rm -fr`, unless `git status` has told you there is nothing to keep.

**Two traps.** The first one is the swap itself:

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

The second trap is a habit from ordinary work:

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

**In production.** In Julia Evans's 2024 polls, 48% of 1,511 respondents did not know that the two sides swap between merge and rebase, and 61% of about 1,480 had seen a production bug caused by a bad conflict resolution; both samples are self-selected ([poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/)). Assume the confusion exists on your team. A branch of twelve commits that all touch the lines `main` changed can stop twelve times. Reduce the number of replays first (squash with `--keep-base`), or record resolutions with rerere (Chapter 14C), or integrate with one merge.

## 9.12 Commits that are already upstream

**In one sentence.** A rebase leaves out commits whose change the new base already contains, and it notices in two different ways: before replaying, by patch ID, and after replaying, by an empty result.

**See it.** First case: `main` received the middle commit of your branch through a cherry-pick.

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

`git cherry` marks with `-` each of your commits that has an equivalent upstream and with `+` each that has none. `git log --cherry-mark` puts `=` on both members of the pair. Both compare patch IDs (section 9.3), and the rebase runs the same comparison before it writes the list:

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

Second case: your first two commits reached `main` as one squashed commit. No single commit upstream has the diff of either of yours, so the comparison finds nothing:

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

Both commits were replayed, both changed nothing, because their content is already there, and both were dropped as empty. That is the second mechanism, governed by `--empty`: `drop` is the default, `keep` records an empty commit, `stop` pauses so that you decide. With `-i` the default is `stop`. `--reapply-cherry-picks` switches the first mechanism off; the commit is then replayed and caught by the second:

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

**Where it stops working.** "Already upstream" means the same diff, or a replay with an empty result. If the upstream version differs from yours, for instance because a reviewer's change went into the squash, neither mechanism applies and the replay conflicts. That was case 1 of section 9.5, and the answer there was to name the boundary with `--onto`.

**In production.** After a pull request is merged with "Squash and merge", a plain `git rebase main` on the follow-up branch does the right thing exactly when the squash equals the sum of your commits. Check with `git cherry -v main` first: for lines marked `+` that you believe are merged, expect an empty replay or a conflict.

## 9.13 `git pull --rebase`

**In one sentence.** 🟡 `git pull --rebase` is `git fetch` followed by a rebase of your unpushed commits onto the fetched upstream branch.

**See it.** You committed on `main`; Asha pushed to `main` in the meantime:

<!-- snippet: ch09/pull-rebase/01-diverged -->
```text
$ git fetch
From ../server
   8afc6bd..eb7188f  main       -> origin/main
$ git status --short --branch
## main...origin/main [ahead 1, behind 1]
$ git log --oneline --graph --decorate --all
* 139c7e6 (HEAD -> main) Raise max_tokens to 1024 for long answers
| * eb7188f (origin/main, origin/HEAD) Add README
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

A plain `git pull` refuses here until you choose how to reconcile ([Chapter 12](ch12-remote-operations.md), section 12.6). Choosing rebase:

<!-- snippet: ch09/pull-rebase/03-pull-rebase -->
```text
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git log --oneline --graph --decorate --all
* ad181ff (HEAD -> main) Raise max_tokens to 1024 for long answers
* eb7188f (origin/main, origin/HEAD) Add README
* 8afc6bd Add retriever and model config
$ git reflog -4
ad181ff HEAD@{0}: pull --rebase (finish): returning to refs/heads/main
ad181ff HEAD@{1}: pull --rebase (pick): Raise max_tokens to 1024 for long answers
eb7188f HEAD@{2}: pull --rebase (start): checkout eb7188fc630b934cc36f4a355cc5e9c51f2540aa
139c7e6 HEAD@{3}: commit: Raise max_tokens to 1024 for long answers
```
<!-- /snippet -->

<!-- snippet: ch09/pull-rebase/04-push -->
```text
$ git push
To ../server.git
   eb7188f..ad181ff  main -> main
```
<!-- /snippet -->

Your commit `139c7e6` was replayed as `ad181ff` on top of Asha's, the reflog labels the steps `pull --rebase`, and the push is a fast-forward for the server.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git pull --rebase` | Upstream tip plus your replayed commits | Same | Detached during the rebase, then back on the branch | Upstream tip plus copies of your unpushed commits | Remote-tracking branches and `FETCH_HEAD` updated by the fetch; `ORIG_HEAD`; reflogs | Read, not changed | unchanged |

This is history rewriting, and it is harmless here for one reason: the only commits rewritten are ones that exist nowhere but in your clone. `pull.rebase=true` makes it the default (section 9.19). When the upstream branch itself was rewritten, `git pull --rebase` consults the reflog of the remote-tracking branch to avoid replaying commits that upstream discarded. Sections 9.15 and 9.17 show that logic doing good and doing harm.

## 9.14 Reviewing a rebase with `git range-diff`

**In one sentence.** 🟢 `git range-diff` compares two versions of a series of commits: it pairs each old commit with its new counterpart and shows how the two patches differ.

**Precisely.** The most convenient spelling is `git range-diff <base> <old tip> <new tip>` ([git-range-diff](https://git-scm.com/docs/git-range-diff)). Commits are paired by similarity of their patches, not by position or ID. Between the two columns stands `=` (same patch), `!` (patch changed), `<` (only in the old series) or `>` (only in the new one). For a `!` pair Git prints a diff of the two diffs: the outer marker says whether a line belongs to the old (`-`) or the new (`+`) patch, the inner marker is the patch's own.

**See it.** A rebase with one conflict, resolved with a value that neither side had:

<!-- snippet: ch09/range-diff/01-rebase -->
```text
$ git log --oneline --decorate main..feat/rerank
1388956 (HEAD -> feat/rerank) Enable reranking in config
bad8965 Fetch 20 candidates and filter weak matches
5ee19f0 Add reranker skeleton
# git rebase main stopped with a conflict in app/retriever.py: main says TOP_K = 8, your commit says 20.
# You settle on 12 in the editor, then:
$ git add app/retriever.py
$ git rebase --continue
[detached HEAD 54541c3] Fetch 20 candidates and filter weak matches
 2 files changed, 6 insertions(+), 3 deletions(-)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/rerank.
```
<!-- /snippet -->

<!-- snippet: ch09/range-diff/02-range-diff -->
```text
$ git range-diff main ORIG_HEAD HEAD
1:  5ee19f0 = 1:  1c9f69a Add reranker skeleton
2:  bad8965 ! 2:  54541c3 Fetch 20 candidates and filter weak matches
    @@ app/rerank.py
     
      ## app/retriever.py ##
     @@
    --TOP_K = 5
    -+TOP_K = 20
    +-TOP_K = 8
    ++TOP_K = 12
      
      def retrieve(query):
     -    return search(query, TOP_K)
3:  1388956 = 3:  2468748 Enable reranking in config
```
<!-- /snippet -->

Commits 1 and 3 are unchanged as patches. Commit 2 is not. Read the four marked lines in pairs: the old patch turned `TOP_K = 5` into `20`; the new patch turns `8` into `12`. Same title, different change. This is the answer to the second question of section 9.1, and it is invisible in a list of commit titles.

<!-- snippet: ch09/range-diff/03-other-spellings -->
```text
$ git range-diff main feat/rerank@{1} feat/rerank | head -3
1:  5ee19f0 = 1:  1c9f69a Add reranker skeleton
2:  bad8965 ! 2:  54541c3 Fetch 20 candidates and filter weak matches
    @@ app/rerank.py
$ git range-diff ORIG_HEAD...HEAD | head -4
-:  ------- > 1:  439e4c6 Raise TOP_K to 8 after recall regression
1:  5ee19f0 = 2:  1c9f69a Add reranker skeleton
2:  bad8965 ! 3:  54541c3 Fetch 20 candidates and filter weak matches
    @@ app/rerank.py
```
<!-- /snippet -->

The reflog form needs no `ORIG_HEAD`. The three-dot form has no base, so the commit that came from `main` is reported as new. Why not compare the two tips directly?

<!-- snippet: ch09/range-diff/04-tree-diff -->
```text
$ git diff ORIG_HEAD HEAD
diff --git a/app/retriever.py b/app/retriever.py
index e67ee8b..4321be2 100644
--- a/app/retriever.py
+++ b/app/retriever.py
@@ -1,4 +1,4 @@
-TOP_K = 20
+TOP_K = 12
 
 def retrieve(query):
     return rerank(search(query, TOP_K))
```
<!-- /snippet -->

That is a comparison of two snapshots. Here it happens to show the resolution; on a real branch it also contains everything that arrived from upstream. Range-diff compares the commits themselves.

The reviewer does not need your `ORIG_HEAD`. After a fetch, the previous tip is in the reflog of the reviewer's own remote-tracking branch:

<!-- snippet: ch09/range-diff-review/01-fetch -->
```text
# In the reviewer clone. The author has rebased feat/ingest onto main and force-pushed it.
$ git fetch
From ../server
   8afc6bd..589d18b  main        -> origin/main
 + dc5df93...321b338 feat/ingest -> origin/feat/ingest  (forced update)
# The remote-tracking branch before and after that fetch:
$ git rev-parse "origin/feat/ingest@{1}" origin/feat/ingest
dc5df9356273e7c0c2807ce808c378782ea2525a
321b33811c66cc02a14c52dbe5b64ecdbd9c506d
```
<!-- /snippet -->

<!-- snippet: ch09/range-diff-review/02-range-diff -->
```text
$ git range-diff origin/main "origin/feat/ingest@{1}" origin/feat/ingest
1:  1279adf = 1:  5859371 Add document loader
2:  dc5df93 = 2:  321b338 Add text cleaner
```
<!-- /snippet -->

Two `=` lines: nothing changed except the base, and the earlier review still stands.

**A limit to know.** The pairing is a heuristic. Run the tool on the clean rebase of section 9.2, in which nothing was edited:

<!-- snippet: ch09/range-diff-context/01-unpaired -->
```text
# The clean rebase of section 9.2. Nothing was edited, and yet:
$ git range-diff main ORIG_HEAD HEAD
1:  5ee19f0 = 1:  742ab58 Add reranker skeleton
2:  af65a92 = 2:  ade2990 Call reranker from retriever
3:  bd62876 < -:  ------- Enable reranking in config
-:  ------- > 3:  976a161 Enable reranking in config
```
<!-- /snippet -->

The third commit is reported as removed and added. Its patch is one added line with three lines of context, and one of those context lines changed underneath it: `main` had moved the model from `small-v1` to `small-v2`. For so small a patch that is too large a difference, and range-diff declines to pair the two. Raise the tolerance and the pair appears, with the context line as its only difference:

<!-- snippet: ch09/range-diff-context/02-paired -->
```text
$ git range-diff --creation-factor=90 main ORIG_HEAD HEAD
1:  5ee19f0 = 1:  742ab58 Add reranker skeleton
2:  af65a92 = 2:  ade2990 Call reranker from retriever
3:  bd62876 ! 3:  976a161 Enable reranking in config
    @@ Commit message
     
      ## config/model.yaml ##
     @@
    - model: small-v1
    + model: small-v2
      temperature: 0.2
      max_tokens: 512
     +rerank: true
```
<!-- /snippet -->

`<` and `>` under one subject are a prompt to look closer. A lost commit has `<` and no partner.

**In production.** Run it after every rebase that stopped, before you push, and paste the output into the pull request when you force-push a branch under review. The format is for people; the manual warns that it may change, so do not parse it.

## 9.15 Rebasing a branch that other people use

**In one sentence.** If you rebase a branch that someone else has built on and publish the result, their clone holds the old commits, the server holds the new ones, and Git sees two separate lines of history that happen to make the same changes.

**Analogy.** You reprint chapters 1 and 2 of a shared manuscript with corrections and replace the copies in the office. Your co-author is at home with chapter 3 stapled to the old chapters 1 and 2. If she staples the new print on as well, the manuscript contains chapters 1 and 2 twice. The analogy breaks at one point: a person would recognise the duplicate text, and Git, which identifies commits by ID, does not, unless you ask it to compare patches.

**See it.** A bare repository plays the server; `you/` and `asha/` are two clones. You pushed two commits to `feat/ingest`. Asha fetched them and committed "Add chunker" on top, not yet pushed. Now you rebase onto the new `main` and publish:

<!-- snippet: ch09/shared-rebase/01-you-rebase -->
```text
$ git log --oneline --graph --decorate --all
* 589d18b (origin/main, main) Add README
| * dc5df93 (HEAD -> feat/ingest, origin/feat/ingest) Add text cleaner
| * 1279adf Add document loader
|/  
* 8afc6bd Add retriever and model config
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest.
```
<!-- /snippet -->

<!-- snippet: ch09/shared-rebase/02-you-push -->
```text
$ git push
To ../server.git
 ! [rejected]        feat/ingest -> feat/ingest (non-fast-forward)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease --force-if-includes
To ../server.git
 + dc5df93...8aca274 feat/ingest -> feat/ingest (forced update)
```
<!-- /snippet -->

The plain push is rejected because the server's tip is not an ancestor of yours. The hint recommends `git pull`. After a rebase of your own that advice is wrong: a pull would bring the old commits back, merged next to your copies or, with `--rebase`, in place of them. The second command replaces the server's branch; `+` and the three dots mean a forced, non-fast-forward update. In Asha's clone:

<!-- snippet: ch09/shared-rebase/03-asha-before -->
```text
$ cd ../asha
$ git log --oneline --graph --decorate --all
* c60bc13 (HEAD -> feat/ingest) Add chunker
* dc5df93 (origin/feat/ingest) Add text cleaner
* 1279adf Add document loader
* 8afc6bd (origin/main, origin/HEAD, main) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/shared-rebase/04-asha-fetch -->
```text
$ git fetch
From ../server
 + dc5df93...8aca274 feat/ingest -> origin/feat/ingest  (forced update)
   8afc6bd..589d18b  main        -> origin/main
$ git status
On branch feat/ingest
Your branch and 'origin/feat/ingest' have diverged,
and have 3 and 3 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
```
<!-- /snippet -->

"3 and 3 different commits": her side has the two old commits and her own, the other side has the README commit and the two copies. She does what the status line suggests, with a merge:

<!-- snippet: ch09/shared-rebase/05-asha-merges -->
```text
$ git pull --no-rebase
Merge made by the 'ort' strategy.
 README.md | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 README.md
$ git log --oneline --graph --decorate
*   f0c9542 (HEAD -> feat/ingest) Merge branch 'feat/ingest' of ../server into feat/ingest
|\  
| * 8aca274 (origin/feat/ingest) Add text cleaner
| * 0fbfd81 Add document loader
| * 589d18b (origin/main, origin/HEAD) Add README
* | c60bc13 Add chunker
* | dc5df93 Add text cleaner
* | 1279adf Add document loader
|/  
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/shared-rebase/06-duplicates -->
```text
$ git log --oneline --left-right --cherry-mark ORIG_HEAD...origin/feat/ingest
= 8aca274 Add text cleaner
= 0fbfd81 Add document loader
> 589d18b Add README
< c60bc13 Add chunker
= dc5df93 Add text cleaner
= 1279adf Add document loader
$ git diff --stat ORIG_HEAD HEAD
 README.md | 3 +++
 1 file changed, 3 insertions(+)
```
<!-- /snippet -->

"Add document loader" and "Add text cleaner" are now in the history twice. `--cherry-mark` shows the pairs with `=`. The diff shows that the merge changed one file: the content is not duplicated, the history is.

> **Root cause.** Git identifies a commit by its ID. Your copies have new IDs, so for Git they are different commits from the originals, and a merge keeps the commits of both sides. This is the third question of section 9.1.

**Picture.**

```text
L = Add document loader   C = Add text cleaner   K = Add chunker   R = Add README   ' = copy made by your rebase

      you/                       server.git                    asha/
 +------------------+       +------------------+       +---------------------------------+
 | feat/ingest      | push  | feat/ingest      | fetch | origin/feat/ingest   A-R-L'-C'  |
 |   A-R-L'-C'      | ----> |   A-R-L'-C'      | ----> | feat/ingest          A-L-C-K    |
 | reflog: A-L-C    | forced| (L and C gone)   |       | after her merge: both lines     |
 +------------------+       +------------------+       +---------------------------------+
```

**The repair, on her side.** Go back to before the merge, then replay only her own commit onto the new upstream:

<!-- snippet: ch09/shared-rebase/07-repair -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at c60bc13 Add chunker
$ git merge-base --fork-point origin/feat/ingest feat/ingest
dc5df9356273e7c0c2807ce808c378782ea2525a
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate
* fbce73d (HEAD -> feat/ingest) Add chunker
* 8aca274 (origin/feat/ingest) Add text cleaner
* 0fbfd81 Add document loader
* 589d18b (origin/main, origin/HEAD) Add README
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

`git merge-base --fork-point` looks into the reflog of `origin/feat/ingest`, finds that her branch left that remote-tracking branch when its tip was `dc5df93`, and so identifies "Add chunker" as the only commit that is hers. `git pull --rebase` uses the same logic. The explicit form, `git rebase --onto origin/feat/ingest dc5df93`, is in Lab 9.6.

**Why it is more than noise.** Every later reader of the history meets each change twice. Worse, if Asha pushes her merge, the commits you removed are back on the server. When the purpose of the rewrite was to remove something, a credential or a large file ([Chapter 21B](ch21b-repository-security-incident-response.md)), one stale clone that merges and pushes undoes the cleanup.

**The rule, and its working form.** Pro Git states it as: "Do not rebase commits that exist outside your repository and that people may have based work on" ([Rebasing](https://git-scm.com/book/en/v2/Git-Branching-Rebasing)). The working form is a question to ask before you rebase anything you have pushed: who else has commits on top of this? Nobody, as on the branch of your own pull request: rebase, and publish as section 9.17 describes. Somebody: agree on it first and send them the repair command, or do not rebase; merge instead.

> **GitHub, not Git.** A new ruleset has "Block force pushes" enabled by default, and classic branch protection rules disable force pushes by default ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#block-force-pushes), [about protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)). Use that for `main` and for release branches, and leave topic branches open to their owners. Described from the documentation; [Chapter 18](ch18-branch-protection.md) has the details.

## 9.16 Recovering from a bad rebase

**In one sentence.** A rebase destroys nothing: the old tip is named by `ORIG_HEAD` until another command overwrites that ref, and by the reflog of the branch for weeks.

**Precisely.** Three handles, from the most short-lived to the most durable:

| Handle | Usable | Caveat |
|---|---|---|
| `git rebase --abort` | While the rebase is in progress | Discards resolution work done so far |
| `ORIG_HEAD` | Directly after the rebase | Rewritten by the next `git reset`, `git merge`, `git rebase` or `git am` ([gitrevisions](https://git-scm.com/docs/gitrevisions)) |
| `<branch>@{n}`, the reflog of the branch | Until the entry expires | One entry per rebase, so count in the listing; a deleted branch has no reflog |

**See it.** An interactive rebase in which the wrong two lines were deleted:

<!-- snippet: ch09/recover/01-bad-rebase -->
```text
$ git log --oneline --decorate
6ab8f55 (HEAD -> feat/rerank) Enable reranking in config
45f4f23 Call reranker from retriever
e30ba74 Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
# The plan was to drop the two experiment commits. The wrong lines were deleted from the todo list.
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick 5ee19f0 # Add reranker skeleton
pick 195f8d0 # Experiment: cross-encoder scoring
pick e30ba74 # Experiment: cache cross-encoder scores
pick 45f4f23 # Call reranker from retriever
pick 6ab8f55 # Enable reranking in config
--- todo list as saved ---
pick 5ee19f0 # Add reranker skeleton
pick 195f8d0 # Experiment: cross-encoder scoring
pick e30ba74 # Experiment: cache cross-encoder scores
Successfully rebased and updated refs/heads/feat/rerank.
$ git log --oneline --decorate
e30ba74 (HEAD -> feat/rerank) Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

Two commits are gone and Git said nothing. Noticed at once, the undo is one command:

<!-- snippet: ch09/recover/02-orig-head -->
```text
$ git rev-parse --short ORIG_HEAD
6ab8f55
$ git reset --hard ORIG_HEAD
HEAD is now at 6ab8f55 Enable reranking in config
$ git log --oneline --decorate
6ab8f55 (HEAD -> feat/rerank) Enable reranking in config
45f4f23 Call reranker from retriever
e30ba74 Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

🔴 `git reset --hard <commit>` moves the current branch to that commit and overwrites the index and the working tree with it. It destroys uncommitted changes to tracked files. Preview with `git status` (it should be clean, as it is after a finished rebase) and `git diff ORIG_HEAD HEAD`. What it moves away from stays recoverable: the rebased tip is now `<branch>@{1}`. It is the appropriate tool here; [Chapter 11](ch11-reset-revert-restore.md), section 11.5, covers it in full.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git reset --hard ORIG_HEAD` | Overwritten with the old tip | Same | Stays on the branch | Moved back to the old tip | `ORIG_HEAD` rewritten to the tip before this reset; reflog entries | unchanged | unchanged |

Now the same mistake, not noticed, followed by a reset for another reason:

<!-- snippet: ch09/recover/03-orig-head-overwritten -->
```text
# The same bad rebase again. This time you do not notice, and remove one more commit with a reset:
$ git reset --hard HEAD~1
HEAD is now at 195f8d0 Experiment: cross-encoder scoring
$ git log --oneline --decorate
195f8d0 (HEAD -> feat/rerank) Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
$ git rev-parse --short ORIG_HEAD
e30ba74
```
<!-- /snippet -->

`ORIG_HEAD` is `e30ba74`: the tip before the reset, which is the damaged branch. The reflog of the branch has the whole story:

<!-- snippet: ch09/recover/04-reflog -->
```text
$ git reflog show feat/rerank
195f8d0 feat/rerank@{0}: reset: moving to HEAD~1
e30ba74 feat/rerank@{1}: rebase (finish): refs/heads/feat/rerank onto 8afc6bd28c2572af09f1b6c37d733535230e526f
6ab8f55 feat/rerank@{2}: reset: moving to ORIG_HEAD
e30ba74 feat/rerank@{3}: rebase (finish): refs/heads/feat/rerank onto 8afc6bd28c2572af09f1b6c37d733535230e526f
6ab8f55 feat/rerank@{4}: commit: Enable reranking in config
45f4f23 feat/rerank@{5}: commit: Call reranker from retriever
e30ba74 feat/rerank@{6}: commit: Experiment: cache cross-encoder scores
195f8d0 feat/rerank@{7}: commit: Experiment: cross-encoder scoring
5ee19f0 feat/rerank@{8}: commit: Add reranker skeleton
8afc6bd feat/rerank@{9}: branch: Created from HEAD
```
<!-- /snippet -->

Read it from the top: a reset, the second bad rebase, the reset to `ORIG_HEAD`, the first bad rebase, and below that the five original commits. The last good state is `feat/rerank@{2}`.

<!-- snippet: ch09/recover/05-rescue -->
```text
$ git branch rescue/rerank feat/rerank@{2}
$ git log --oneline rescue/rerank
6ab8f55 Enable reranking in config
45f4f23 Call reranker from retriever
e30ba74 Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd Add retriever and model config
$ git reset --hard rescue/rerank
HEAD is now at 6ab8f55 Enable reranking in config
$ git log --oneline --decorate
6ab8f55 (HEAD -> feat/rerank, rescue/rerank) Enable reranking in config
45f4f23 Call reranker from retriever
e30ba74 Experiment: cache cross-encoder scores
195f8d0 Experiment: cross-encoder scoring
5ee19f0 Add reranker skeleton
8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

The rescue branch comes first for a reason. It is a ref, so the commits stay reachable whatever you type next, and you can inspect them before moving the real branch.

**In production.** By default a reflog entry whose commit is no longer reachable from the branch tip, which is what a rebase leaves behind, expires after 30 days, and the unreachable objects are pruned after a further two weeks ([gc configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/gc.adoc)); [Chapter 13](ch13-recovery.md) has the details. Recovery is local: if you had already force-pushed the damaged branch, restore it here first and publish it again as described next.

## 9.17 Publishing a rebased branch

**In one sentence.** After a rebase the server's branch is not an ancestor of yours, so a normal push is refused; you have to overwrite the server's ref, and the only choice is which conditions you attach to the overwrite.

**Analogy.** A compare-and-swap. A plain force is an unconditional write. A lease is "set the ref to X only if it still is Y". The analogy breaks at Y: you do not type the expected value. Git reads it from your remote-tracking branch, and anything that fetches can change that behind your back.

**Precisely.** Every forced push is 🔴: it replaces history on a remote. The forms differ in what must be true first ([git-push](https://git-scm.com/docs/git-push); [Chapter 12](ch12-remote-operations.md), section 12.8, treats them in depth):

| Command | The server's ref is overwritten if |
|---|---|
| `git push --force` | always |
| `git push --force-with-lease` | it equals your `origin/<branch>` |
| `git push --force-with-lease --force-if-includes` | as above, and the tip of `origin/<branch>` is reachable from a reflog entry of your local branch: your branch has contained it at some point |
| `git push --force-with-lease=<branch>:<expected ID>` | it equals the ID you wrote |

**See it.** The shared branch of section 9.15, but this time Asha pushed "Add chunker" after your last fetch:

<!-- snippet: ch09/force-push/01-rebase -->
```text
# Asha pushed "Add chunker" to feat/ingest after your last fetch. You do not know that yet.
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate --all
* 321b338 (HEAD -> feat/ingest) Add text cleaner
* 5859371 Add document loader
* 589d18b (origin/main, main) Add README
| * dc5df93 (origin/feat/ingest) Add text cleaner
| * 1279adf Add document loader
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/force-push/02-plain-push -->
```text
$ git push
To ../server.git
 ! [rejected]        feat/ingest -> feat/ingest (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch09/force-push/03-lease -->
```text
$ git push --force-with-lease
To ../server.git
 ! [rejected]        feat/ingest -> feat/ingest (stale info)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

`stale info`: the server has a commit that your `origin/feat/ingest` does not know. The lease did its job. Now the failure mode that the manual itself warns about:

<!-- snippet: ch09/force-push/04-background-fetch -->
```text
# Something fetches for you: an editor, a status prompt, or you out of habit.
$ git fetch
From ../server
   dc5df93..c60bc13  feat/ingest -> origin/feat/ingest
# The lease now compares against the freshly fetched value. A dry run shows it would overwrite:
$ git push --force-with-lease --dry-run
To ../server.git
 + c60bc13...321b338 feat/ingest -> feat/ingest (forced update)
```
<!-- /snippet -->

The fetch moved `origin/feat/ingest` to Asha's commit. The server and your remote-tracking branch agree again, the lease is satisfied, and the dry run shows that the push would replace `c60bc13`, a commit you have never looked at. The second check catches it:

<!-- snippet: ch09/force-push/05-if-includes -->
```text
$ git push --force-with-lease --force-if-includes
To ../server.git
 ! [rejected]        feat/ingest -> feat/ingest (remote ref updated since checkout)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout. If you want to integrate the
hint: remote changes, use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

`c60bc13` is in no reflog entry of your branch, so your rewrite cannot have been based on it. The fix is to rebase what is there:

<!-- snippet: ch09/force-push/06-integrate -->
```text
# Rebase what is really on the server, then publish with both checks.
$ git reset --hard origin/feat/ingest
HEAD is now at c60bc13 Add chunker
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feat/ingest.
$ git push --force-with-lease --force-if-includes
To ../server.git
 + c60bc13...e3f3ba1 feat/ingest -> feat/ingest (forced update)
```
<!-- /snippet -->

The explicit form does not depend on the remote-tracking branch at all. You state the commit you rebased from:

<!-- snippet: ch09/force-lease-explicit/02-fetch-then-push -->
```text
# Asha pushed in the meantime, and something fetched for you. The explicit lease still refuses:
$ git fetch
From ../server
   dc5df93..c60bc13  feat/ingest -> origin/feat/ingest
$ git push --force-with-lease=feat/ingest:dc5df9356273e7c0c2807ce808c378782ea2525a
To ../server.git
 ! [rejected]        feat/ingest -> feat/ingest (stale info)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

**Why plain `--force` is the worst of them.** The same situation. The server's branch first, then the careless push:

<!-- snippet: ch09/force-damage/01-server-before -->
```text
$ git -C ../server.git log --oneline feat/ingest
c60bc13 Add chunker
dc5df93 Add text cleaner
1279adf Add document loader
8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/force-damage/02-force -->
```text
$ git rebase main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feat/ingest.
$ git push --force
To ../server.git
 + c60bc13...8aca274 feat/ingest -> feat/ingest (forced update)
```
<!-- /snippet -->

<!-- snippet: ch09/force-damage/03-server-after -->
```text
$ git -C ../server.git log --oneline feat/ingest
8aca274 Add text cleaner
0fbfd81 Add document loader
589d18b Add README
8afc6bd Add retriever and model config
$ git -C ../server.git reflog show feat/ingest
```
<!-- /snippet -->

Asha's commit is gone from the server's branch, and the last command prints nothing: a bare repository keeps no reflog by default, so the server cannot tell you what the branch used to be. Then Asha pulls:

<!-- snippet: ch09/force-damage/04-asha-pulls -->
```text
$ cd ../asha
$ git log --oneline --decorate -1
c60bc13 (HEAD -> feat/ingest, origin/feat/ingest) Add chunker
$ git pull --rebase
From ../server
 + c60bc13...8aca274 feat/ingest -> origin/feat/ingest  (forced update)
   8afc6bd..589d18b  main        -> origin/main
Successfully rebased and updated refs/heads/feat/ingest.
$ git log --oneline --graph --decorate
* 8aca274 (HEAD -> feat/ingest, origin/feat/ingest) Add text cleaner
* 0fbfd81 Add document loader
* 589d18b (origin/main, origin/HEAD) Add README
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/force-damage/05-why -->
```text
$ git reflog show origin/feat/ingest
8aca274 refs/remotes/origin/feat/ingest@{0}: pull --rebase: forced-update
c60bc13 refs/remotes/origin/feat/ingest@{1}: update by push
$ git merge-base --fork-point origin/feat/ingest feat/ingest@{1}
c60bc13f871297055fb1d2e19bd6a39f7a4f1f62
```
<!-- /snippet -->

```text
Observed behavior : "git pull --rebase" reports success, and "Add chunker", a commit Asha had
                    pushed, is no longer in her branch. (The first question of section 9.1.)
Git state         : The reflog of her origin/feat/ingest holds c60bc13 ("update by push")
                    below the forced update.
Mechanism         : pull --rebase replays the commits after the fork point. The fork point is
                    the newest commit of her branch that was once the tip of
                    origin/feat/ingest: c60bc13, her own commit. Nothing comes after it, so
                    nothing is replayed, and her branch is set to the new upstream.
Root cause        : By pushing, she made the commit part of upstream. Upstream no longer has
                    it, and Git reads that as "upstream discarded this commit". Your force
                    push is what discarded it.
Why Git does this : It is the logic that repaired her history in section 9.15: do not replay
                    what upstream dropped.
Correct fix       : The commit is in the reflog of her branch:
                    git cherry-pick feat/ingest@{1}, then push.
Prevention        : No plain --force on a branch that anyone else pushes to. The lease with
                    --force-if-includes refused in exactly this situation.
```

<!-- snippet: ch09/force-damage/06-asha-recovers -->
```text
$ git reflog show feat/ingest -2
8aca274 feat/ingest@{0}: pull --rebase (finish): refs/heads/feat/ingest onto 8aca274dbad90b9d7b5ad3a578f59a5283073474
c60bc13 feat/ingest@{1}: commit: Add chunker
$ git cherry-pick feat/ingest@{1}
[feat/ingest 82659ee] Add chunker
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 ingest/chunker.py
$ git push
To ../server.git
   8aca274..82659ee  feat/ingest -> feat/ingest
$ git log --oneline --graph --decorate
* 82659ee (HEAD -> feat/ingest, origin/feat/ingest) Add chunker
* 8aca274 Add text cleaner
* 0fbfd81 Add document loader
* 589d18b (origin/main, origin/HEAD) Add README
* 8afc6bd (main) Add retriever and model config
```
<!-- /snippet -->

The account that this book owes for a 🔴 command: a forced push changes the server's ref, for every ref the push covers. It can destroy commits that exist only on the server and in other people's clones. Preview with `git fetch` followed by `git log --oneline HEAD..origin/<branch>`, which lists what you are about to remove, or with `--dry-run`. Recovery depends on a clone that still has the commits; GitHub's own instruments are summarised in Chapter 13. Appropriate use of plain `--force` and of the bare lease: none. The two guarded forms cost the same keystrokes, and with them everything removed from the server is something your clone has, so your own reflog can restore it.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| Forced push, accepted | unchanged | unchanged | unchanged | unchanged | `origin/<branch>` set to the pushed commit | Branch ref replaced; the old commits are no longer on the branch | Pull requests for the branch follow it; where the rules dismiss stale approvals, an approval is dismissed when the diff changes (described from the [documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-a-pull-request-before-merging)) |
| Forced push, rejected | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |

**In production.** `git config set --global push.useForceIfIncludes true` adds the second check to every lease, and an alias ([Chapter 14B](ch14b-config-tags-signing.md)) shortens the rest. Editors and prompts that fetch in the background are the usual way the bare lease is defeated; the manual's own example is a scheduled `git fetch`.

## 9.18 Rebase or merge

Both integrate the same work. Do it twice, once each way, and compare:

<!-- snippet: ch09/merge-vs-rebase/01-merge -->
```text
$ git switch -c demo/merged main
Switched to a new branch 'demo/merged'
$ git merge feat/rerank
Auto-merging config/model.yaml
Merge made by the 'ort' strategy.
 app/rerank.py     | 2 ++
 app/retriever.py  | 2 +-
 config/model.yaml | 1 +
 3 files changed, 4 insertions(+), 1 deletion(-)
 create mode 100644 app/rerank.py
$ git log --oneline --graph --decorate demo/merged
*   9d34396 (HEAD -> demo/merged) Merge branch 'feat/rerank' into demo/merged
|\  
| * bd62876 (feat/rerank) Enable reranking in config
| * af65a92 Call reranker from retriever
| * 5ee19f0 Add reranker skeleton
* | 82f1fbb (main) Upgrade model to small-v2
* | 589d18b Add README
|/  
* 8afc6bd Add retriever and model config
```
<!-- /snippet -->

<!-- snippet: ch09/merge-vs-rebase/03-same-content -->
```text
$ git rev-parse "demo/merged^{tree}" "demo/rebased^{tree}"
273096fac387738589eb6596acff61b6fb3cf487
273096fac387738589eb6596acff61b6fb3cf487
$ git diff --stat demo/merged demo/rebased
```
<!-- /snippet -->

`demo/rebased` is the same branch rebased onto `main`. The two results have the same tree, to the byte. What differs is everything else:

<!-- snippet: ch09/merge-vs-rebase/04-snapshots -->
```text
# Commit, tree and subject of everything that is new relative to main, for each result:
$ git log --format="%h tree %t  %s" main..demo/merged
9d34396 tree 273096f  Merge branch 'feat/rerank' into demo/merged
bd62876 tree 96ba5b8  Enable reranking in config
af65a92 tree ece63c5  Call reranker from retriever
5ee19f0 tree bff5bbd  Add reranker skeleton
$ git log --format="%h tree %t  %s" main..demo/rebased
668e89e tree 273096f  Enable reranking in config
60fc46f tree 9b070ab  Call reranker from retriever
bbbc3e4 tree 8cc3ece  Add reranker skeleton
```
<!-- /snippet -->

<!-- snippet: ch09/merge-vs-rebase/05-first-parent -->
```text
$ git log --oneline --first-parent main..demo/merged
9d34396 Merge branch 'feat/rerank' into demo/merged
$ git log --oneline --first-parent main..demo/rebased
668e89e Enable reranking in config
60fc46f Call reranker from retriever
bbbc3e4 Add reranker skeleton
```
<!-- /snippet -->

The merge added one new snapshot, the merge commit, and kept your three commits with the trees you built and tested. The rebase produced three new commits; two of their trees (`8cc3ece`, `9b070ab`) are combinations of your early commits with `main` that nobody has ever run. Read along first parents, the merged history says "one feature landed" and the rebased one lists three changes.

| Question | Merge | Rebase |
|---|---|---|
| Commit IDs of the branch | Kept | New |
| Shape of history | Fork and join are recorded | One line |
| New snapshots that nobody ran | One: the merge result | One per replayed commit |
| Conflicts | Resolved once, recorded in the merge commit | Resolved per commit, up to once for each |
| Record of what was integrated, and when | The merge commit; `--first-parent` reads as a list of integrations | None |
| Undoing the whole integration | One revert with `-m 1` (Chapter 11) | One revert per commit, or of the range |
| On a branch that others use | Safe: it only adds commits | Needs a forced push and everybody's cooperation |
| Reading and bisecting | More paths to walk | Simpler, provided every commit builds |

Neither column wins. Three questions decide a given case. Is the branch shared? Then merge. What does the target branch require? A "Require linear history" rule on GitHub blocks merge commits, which leaves squash or rebase ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)). Must every intermediate commit work? Then a rebase needs `--exec`, or a squash. Many teams combine the two: rebase in private, and let the pull request's merge method ([Chapter 17](ch17-pull-requests.md)) decide what lands on `main`.

## 9.19 Configuration

| Setting | Default | Effect |
|---|---|---|
| `rebase.autoSquash` | false | `--autosquash` for interactive rebases (section 9.7) |
| `rebase.autoStash` | false | `--autostash` for every rebase |
| `rebase.updateRefs` | false | `--update-refs` for every rebase |
| `rebase.missingCommitsCheck` | `ignore` | `warn` or `error` when a line was deleted from the list |
| `pull.rebase` | unset | `git pull` rebases; `true`, `merges` or `interactive` |
| `push.useForceIfIncludes` | false | Adds `--force-if-includes` to every lease |
| `merge.conflictStyle` | `merge` | `zdiff3` also shows the base in rebase conflicts (Chapter 8) |
| `rerere.enabled` | off unless `.git/rr-cache` exists | Records conflict resolutions and replays them (Chapter 14C) |

```bash
git config set --global rebase.autoSquash true
git config set --global rebase.autoStash true
git config set --global rebase.updateRefs true
```

The `set` and `get` subcommands need Git 2.46 or later; on older versions write `git config --global rebase.autoSquash true`. Inside `labs/shell`, `--global` writes to the isolated lab configuration. The manual lists further keys: `rebase.backend`, `rebase.forkPoint`, `rebase.rebaseMerges`, `rebase.abbreviateCommands`, `rebase.instructionFormat`, `rebase.rescheduleFailedExec` and `sequence.editor`.

## 9.20 `git replay` and `git history`

Two experimental commands do parts of this chapter's work without its machinery. [Chapter 14D](ch14d-frontier.md) covers them.

`git replay` replays a range onto a new base without touching the working tree or the index, so it also works in a bare repository:

<!-- snippet: ch09/replay-pointer/01-replay -->
```text
$ git status --short --branch
## main
$ git replay --onto=main main..feat/rerank
[exit status: 0]
$ git log --oneline --graph --decorate --all
* 4caa98e (feat/rerank) Enable reranking in config
* 20d0897 Call reranker from retriever
* 0dea106 Add reranker skeleton
* 82f1fbb (HEAD -> main) Upgrade model to small-v2
* 589d18b Add README
* 8afc6bd Add retriever and model config
$ git reflog show feat/rerank -2
4caa98e feat/rerank@{0}: replay --onto 82f1fbb78c09021e2e673bf06e3c77fc58f14a50
bd62876 feat/rerank@{1}: commit: Enable reranking in config
```
<!-- /snippet -->

`feat/rerank` was rebased while `main` stayed checked out, and no state directory was involved. The copies are `0dea106`, `20d0897` and `4caa98e`: the third command in this chapter to produce those byte-identical commits (section 9.3). The price of having no working tree is that it cannot stop for a conflict:

<!-- snippet: ch09/replay-conflict/01-conflict -->
```text
$ git replay --onto=main main..feat/rerank
[exit status: 1]
$ git log --oneline --decorate -1 feat/rerank
ad106e3 (feat/rerank) Enable reranking in config
$ git status --short --branch
## main
```
<!-- /snippet -->

Exit status 1, no output, and the branch is where it was. The command was introduced in Git 2.44 as a server-side tool and updates refs itself since 2.53; its `--linearize` option was added in Git 2.56 (not run here) ([git-replay](https://github.com/git/git/blob/v2.56.0/Documentation/git-replay.adoc)).

`git history`, new in Git 2.54, offers single-purpose rewrites: `git history reword <commit>`, `git history split <commit>` and, since 2.55, `git history fixup <commit>`; `drop` was added in Git 2.56 (not run here). It moves every descendant branch by default, runs no hooks, does not work on histories that contain merges, and refuses operations that would conflict ([git-history](https://github.com/git/git/blob/v2.56.0/Documentation/git-history.adoc)). Both manual pages carry the word EXPERIMENTAL in their first line.

## 9.21 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A commit is missing after a rebase that stopped at a conflict | `git range-diff <base> <branch>@{1} <branch>` shows it with `<` and no partner | `git reset --hard <branch>@{1}`, rebase again, resolve with the stage you mean | Know the swap (9.11); range-diff before every push |
| A commit is missing after an interactive rebase without conflicts | Same command; a line was deleted from the list | Same reset, then redo | `rebase.missingCommitsCheck=error`; write `drop` |
| The resolution of a conflict ended up in the wrong commit | `git show --stat` of the previous commit lists the conflicted file | Reset and redo | After a conflict: `git add`, `git rebase --continue`, never `--amend` |
| A conflict in a file your branch never changed | `git log --oneline <upstream>..HEAD` lists commits that are not yours | `git rebase --abort`, then `--onto` with the right boundary | Name the boundary for stacked branches (9.5) |
| The same conflict at one commit after another | Several commits touch the lines upstream changed | Abort; squash first, enable rerere, or merge | Short-lived branches |
| Lower branches of a stack still point at old commits | `git log --graph --all` shows copies above the originals | Put the top branch back from its reflog, redo with `--update-refs` | `rebase.updateRefs=true` |
| `ORIG_HEAD` is not the tip from before the rebase | A `git reset` ran since, possibly inside an `edit` stop | Use the branch reflog | Prefer `<branch>@{1}` |
| "already a rebase-merge directory" | A rebase is in progress; `git status` says where | `--continue` or `--abort` it | Read the prompt or `git status` before starting |
| HEAD is detached after leaving a rebase | `--quit` was used, or the state directory was deleted | `git reset --hard` if the index is unmerged, then `git switch <branch>` | Leave with `--abort` |
| Tests fail on a middle commit after the rebase | Replayed commits are snapshots nobody ran | `git rebase --exec "<tests>"`, amend at each stop | Always `--exec` in a cleanup rebase |
| The lease is rejected | Someone pushed; `git fetch`, then `git log HEAD..origin/<branch>` | Rebase what is on the server (9.17) | Ask before rebasing a branch others push to |
| A teammate has every commit twice | `git log --oneline --left-right --cherry-mark <old>...<new>` shows `=` pairs | The repair of section 9.15 | Announce rebases; send the command |
| A teammate's pushed commit disappeared | The server ref was replaced; the commit is in their branch reflog | Cherry-pick it from the reflog, push | No plain `--force`; block force pushes on shared branches |

## 9.22 When not to use it, and dangerous edge cases

Do not rebase:

- **A branch that others have based work on.** `main`, release branches, a feature branch that two people push to. The cost lands on them (section 9.15).
- **Commits whose IDs are already recorded where they must stay valid.** A released tag, a deployment record, a model card, a submodule pointer in another repository ([Chapter 23](ch23-submodules.md)).
- **A long branch that conflicts with upstream at many commits.** One merge is one resolution.

Edge cases that have hurt people:

- **`-X ours` during a rebase discards your side** of every conflicting hunk, because of the swap. `-s ours` is worse: it empties every one of your commits, which the manual says "makes little sense".
- **`--root` on a published repository**, and any rebase that crosses a tag others use: the tag keeps pointing at the old commit, and the new history no longer contains it.
- **An instruction list is a script.** `exec` lines run shell commands in your working tree with your privileges. Read a list you did not write.
- **Hooks are not a control here.** `pre-rebase` can refuse a rebase and `--no-verify` skips it; the manual describes which other hooks run during a rebase as an accident of implementation. Enforce nothing through them.
- **Worktrees.** `--update-refs` does not move a branch that is checked out in another worktree ([Chapter 25](ch25-worktrees.md)), so a stack can end up half moved.
- **Deleting the branch to start over** deletes its reflog, which is the most durable undo handle of section 9.16.

## 9.23 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git range-diff`, `git cherry`, `git log --cherry-mark`, `git rebase --show-current-patch` | 🟢 SAFE | Nothing | not needed | not needed |
| `git commit --fixup=<commit>`, `--squash=<commit>` | 🟢 SAFE | Adds a commit | `git diff --cached` | Fold it in, or drop it |
| `git rebase <upstream>`, `--onto`, `-i`, `--autosquash`, `--keep-base`, `--rebase-merges` | 🟡 CAUTION | New commits; the branch ref, at the end | `git log --oneline <upstream>..HEAD` lists what will be replayed | `git reset --hard <branch>@{1}` |
| `git rebase --update-refs` | 🟡 CAUTION | Also every local branch inside the range | With `-i`, the `update-ref` lines | Each branch from its own reflog |
| `git rebase --root` | 🟡 CAUTION | Every commit of the branch | `git log --oneline` | Reflog; for a published repository there is no clean recovery |
| `git rebase --continue` | 🟡 CAUTION | Commits the index as the copy, runs on | `git status`, `git diff --cached` | Reflog, after the rebase |
| `git rebase --skip` | 🟡 CAUTION | Omits the stopped commit | `git rebase --show-current-patch` | The original is in the old history; redo |
| `git rebase --abort` | 🟡 CAUTION | Index and working tree back to the old tip | `git status` | None for resolution work in progress |
| `git rebase --quit` | 🟡 CAUTION | Removes the state directory; HEAD stays detached | `git status` | `git switch <branch>` |
| Reopening the list while stopped (9.6) | 🟢 SAFE | The remaining instructions | It shows them | Abort the rebase |
| `git pull --rebase` | 🟡 CAUTION | Fetches; rewrites your unpushed commits | `git fetch`, then `git log --oneline @{u}..HEAD` | `git reset --hard <branch>@{1}` |
| `git reset --hard ORIG_HEAD` | 🔴 DANGEROUS | Branch, index and working tree | `git status`, `git diff ORIG_HEAD HEAD` | Reflog for commits; none for uncommitted changes |
| `git push --force-with-lease --force-if-includes`, or the lease with an explicit ID | 🔴 DANGEROUS | The server's ref, if it still is what you rebased from | Add `--dry-run` | The old tip is in your own reflogs |
| `git push --force-with-lease` alone | 🔴 DANGEROUS | The server's ref; the check passes wrongly after a background fetch | `--dry-run`; `git log HEAD..origin/<branch>` | Only from a clone that has the commits |
| `git push --force` | 🔴 DANGEROUS | The server's ref, unconditionally | Same | Same |

## 9.24 Version notes

> **Version note.** Older behavior: `git rebase` turned commits into patches and applied them (the apply backend). Current behavior: the merge backend replays with the merge machinery; `--apply` selects the old one. Since: Git 2.26 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.26.0.adoc)). Recommended: the default.

> **Version note.** Older behavior: `--autosquash` worked only together with `-i`. Current behavior: it also works without `-i`; `rebase.autoSquash` still applies to interactive rebases only. Since: Git 2.44 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.44.0.adoc)). Recommended: type the option in scripts.

> **Version note.** Older behavior: a rebase moved one branch, and stacks were repaired by hand with `--onto`. Current behavior: `--update-refs` moves every local branch in the range. Since: Git 2.38 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.38.0.adoc)). Recommended: `rebase.updateRefs=true` if you work with stacks.

> **Version note.** Older behavior: `git push --force` was the only way to publish a rewrite. Current behavior: `--force-with-lease` and `--force-if-includes`. Since: Git 1.8.5 and Git 2.30 ([git-push](https://github.com/git/git/blob/v2.56.0/Documentation/git-push.adoc)). Recommended: both together, or the explicit lease; the manual still calls the lease forms without an explicit value experimental.

| Feature | Since | Note |
|---|---|---|
| `--rebase-merges` | Git 2.18 | `--preserve-merges` deprecated in 2.22, removed in 2.34 |
| `git range-diff` | Git 2.19 | `--diff-merges` since 2.48 |
| `git pull` stops on diverged branches | Git 2.33.1 and 2.34 | Chapter 12 |
| `git config set`, `get`, `list` | Git 2.46 | The older option forms still work |
| `git rebase --trailer` | Git 2.54 | Appends a trailer to every rebased commit |
| `git replay` | Git 2.44; updates refs itself since 2.53 | `--linearize` was added in Git 2.56 (not run here) |
| `git history` | Git 2.54; `fixup` since 2.55 | `drop` was added in Git 2.56 (not run here) |

Sources for the table: the release-note links in section 1 of the Phase 0 report.

Older installations matter for scripts: Ubuntu 24.04 LTS ships Git 2.43.0 ([Launchpad](https://launchpad.net/ubuntu/+source/git)), where `git config set` does not exist and `--autosquash` needs `-i`.

> **Unverified.** The releases that introduced `rebase.rebaseMerges`, `rebase.missingCommitsCheck`, `--keep-base`, the `--empty` option of rebase, and the `amend!` commits with `fixup -C` were not found in the sources available for this chapter. All of them were run on Git 2.55.0 and are shown above.

## 9.25 Practice

- Labs 9.1 to 9.7 in the [Module 9 lab manual](../lab-manual/m09-rebase.md): clean up a messy branch; transplant with `--onto`; autosquash fixups; a conflict and who is "ours"; break a branch and recover it; a shared branch and a teammate's duplicated history; `--update-refs` on a stack.
- Replay any transcript with `labs/run ch09/<demo>`, for example `labs/run ch09/force-push`. The sandbox stays in place, so you can continue by hand.
- Three drills in sandboxes left by replays:
  1. In `ch09/range-diff-context`, find the smallest `--creation-factor` at which the third commit is paired.
  2. In `ch09/onto-cut`, run `git reset --hard ORIG_HEAD`, remove the two commits with `drop` instead, and compare the trees with `git diff 31e8a4d HEAD`.
  3. In `ch09/force-damage`, in Asha's clone, find the ID of her original "Add chunker" commit in two ways that do not use `feat/ingest@{1}`.

## 9.26 Interview questions

1. A rebase "moves" a branch onto `main`. Describe what happens to objects, refs and HEAD, step by step, and name what has not changed when the command returns.
2. Why does every rebased commit have a new ID even when its diff is identical? Which fields of the commit object changed, and which did not?
3. A rebase is stopped at a conflict. Where do the branch ref, HEAD, `ORIG_HEAD` and `REBASE_HEAD` point? What does that imply for `--abort`?
4. During a rebase, what do `--ours` and `--theirs` refer to, and why? Give one concrete way this loses work without any error message.
5. `git rebase main` on a feature branch conflicts in a file the branch never touched. Give two different root causes and the command that fixes each.
6. You force-pushed a rebased branch. A teammate now has every commit twice. Explain how that happened, how they repair it, and what you would have done differently.
7. Compare `--force`, `--force-with-lease`, and `--force-with-lease --force-if-includes`. Describe a sequence of events in which the second overwrites a colleague's commit and the third refuses.
8. A colleague's pushed commit vanished from their own branch after `git pull --rebase`. Nobody ran a destructive command on their machine. Explain the mechanism and recover the commit.
9. The reviewer approved three commits; after your rebase there are still three with the same titles. How do you show what changed, and how does the reviewer do it without access to your clone?
10. `ORIG_HEAD` does not point where you expected after a rebase. Why, and what do you use instead?
11. When would you choose a merge over a rebase for the same integration, and when the reverse? Argue both sides for a team that bisects often.
12. What do `--update-refs` and `--rebase-merges` each add to a plain rebase, and what does each still leave for you to do?

## 9.27 Sources

**Primary sources**

- [git-rebase](https://git-scm.com/docs/git-rebase), including its sections "Behavioral differences", "Recovering from upstream rebase" and "Rebasing merges"; [git-range-diff](https://git-scm.com/docs/git-range-diff); [git-push](https://git-scm.com/docs/git-push); [git-pull](https://git-scm.com/docs/git-pull); [git-commit](https://git-scm.com/docs/git-commit) for `--fixup` and `--squash`; [git-cherry](https://git-scm.com/docs/git-cherry); [git-patch-id](https://git-scm.com/docs/git-patch-id); [gitrevisions](https://git-scm.com/docs/gitrevisions) for `ORIG_HEAD` and `REBASE_HEAD`; [gitglossary](https://git-scm.com/docs/gitglossary); [githooks](https://git-scm.com/docs/githooks). The local copies (`git help -m <command>`) are the Git 2.55.0 text that the transcripts were checked against.
- [git-replay](https://git-scm.com/docs/git-replay) and [git-history](https://git-scm.com/docs/git-history); the pages on git-scm.com describe 2.56.
- Release notes: [2.26.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.26.0.adoc), [2.34.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.34.0.adoc), [2.38.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.38.0.adoc), [2.44.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.44.0.adoc), [2.46.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc), [2.54.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc).
- GitHub Docs: [about merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github), [pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges), [available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).

**Secondary sources**

- Pro Git, [Rebasing](https://git-scm.com/book/en/v2/Git-Branching-Rebasing) and [Rewriting History](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History). Caveats: `master` throughout, and `git checkout` in the first; neither mentions `--update-refs`, `--force-with-lease` or `git range-diff`; the second still demonstrates `git filter-branch`, with a warning.
- Julia Evans, [git rebase: what can go wrong?](https://jvns.ca/blog/2023/11/06/rebasing-what-can-go-wrong-/), [Confusing git terminology](https://jvns.ca/blog/2023/11/01/confusing-git-terminology/) and [Some Git poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/). The polls are self-selected samples.
- [git rebase in depth](https://git-rebase.io/), a sandbox walkthrough. Its author and year could not be confirmed from the page, and it does not cover `exec`.
- The Phase 0 report of this course, sections 1, 4, 12 and 13.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- Philomatics, ["git rebase - Why, When & How to fix conflicts"](https://www.youtube.com/watch?v=DkWDHzmMvyg), 10 minutes, June 2024. Current; short and opinionated.
- Tobias Günther for freeCodeCamp, ["Advanced Git Tutorial"](https://www.youtube.com/watch?v=qsTthZi23VE), 34 minutes, November 2021. Interactive rebase and cherry-pick; mixes `master` and `main` and uses some `checkout`.
- Scott Chacon, ["So You Think You Know Git Part 2"](https://www.youtube.com/watch?v=Md44rcw13k4), 23 minutes, March 2024. Fixup commits and `--update-refs` for stacked branches.
- Colt Steele, ["Git Rebase Vs. Merge"](https://www.youtube.com/watch?v=7Mh259hfxJg), 20 minutes, March 2021. Uses `git switch`; `master` naming.

**Further reading**

- [Chapter 10](ch10-cherry-pick.md) for the single replay that a rebase repeats; [Chapter 12](ch12-remote-operations.md) for push and pull; [Chapter 13](ch13-recovery.md) for reflogs and retention; [Chapter 14C](ch14c-stash-rerere-attributes-hooks.md) for rerere.
