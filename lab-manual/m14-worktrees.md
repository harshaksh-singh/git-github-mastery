# Module 14 lab: Worktrees

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the replay script `labs/ch25/lab-14-1-hotfix-worktree.sh`. Read [Chapter 25: Worktrees](../textbook/ch25-worktrees.md) first. The other labs of Module 14 (hooks, filters, rerere, stash) are in [m14-hooks-rerere-attributes.md](m14-hooks-rerere-attributes.md). The general rules for labs are in the [lab manual README](README.md).

## How to run this lab

```bash
bash labs/ch25/setup-14-1-hotfix-worktree.sh     # build the starting state (run again to start over)
labs/shell m14-1                                 # open the isolated lab shell in that sandbox
cd rag-api
labs/run ch25/lab-14-1-hotfix-worktree           # optional, from the course root: replay the whole lab
```

The project is `rag-api`, a retrieval-augmented question-answering service, with a shared repository in `../remotes/rag-api.git`. Commits that exist when you enter the sandbox have the IDs printed here, because the setup script uses the fixed lab clock; commits that you create get other IDs. Lines such as `[exit status: 128]` are printed by the replay; by hand, run `echo $?` after a command. When `git rebase --continue` opens your editor on a commit message, save and close.

## Lab 14.1: A hotfix in a second worktree while a rebase is in progress

### Objective

Fix a production bug on a branch of its own, in a second working tree, while the first working tree stays in the middle of a conflicted rebase. Then clean up the wrong way, see what that leaves behind, repair it, and finish the rebase.

### Prerequisites

Chapter 25, sections 25.2 to 25.6. From [Chapter 9](../textbook/ch09-rebase.md): what a stopped rebase looks like and how `--continue` works.

### Setup

```bash
bash labs/ch25/setup-14-1-hotfix-worktree.sh
labs/shell m14-1
cd rag-api
```

You were rebasing `feature/rerank` onto `main`. The rebase stopped at a conflict in `app/retriever.py`. At that moment someone reports that the API accepts an empty question, and `scripts/check.sh`, which stands in for the test suite, fails on `main`.

### Commands

Look at where you are, and try the two things people try first:

```bash
git status
git worktree list
git switch main
git stash
```

Before you go on, write down: after you create a second worktree for the hotfix, which of these will the two worktrees share, and which will each have for itself? HEAD, the index, the branch `main`, the directory `.git/rebase-merge`, the object database.

Create the worktree with a new branch that starts at `main`, and look at how it is linked:

```bash
git worktree add -b hotfix/empty-question ../rag-api-hotfix main
git worktree list
cat ../rag-api-hotfix/.git
```

Make the fix there. In `app/api.py`, insert these two lines as the first lines of the function `ask` (indented by four and eight spaces):

```text
    if not question or not question.strip():
        raise ValueError("question must not be empty")
```

```bash
cd ../rag-api-hotfix
git status --short --branch
sh scripts/check.sh
# edit app/api.py as described
git diff
sh scripts/check.sh
git commit -am "Reject empty questions"
git push -u origin hotfix/empty-question
```

Go back and confirm that the first worktree has not moved:

```bash
cd ../rag-api
git status --short
git log --oneline --decorate -1 hotfix/empty-question
git rev-parse --git-path rebase-merge
git -C ../rag-api-hotfix rev-parse --git-path rebase-merge
```

### Expected output

<!-- snippet: ch25/lab-14-1-hotfix-worktree/01-start -->
```text
$ git status
interactive rebase in progress; onto 323e8f1
Last commands done (2 commands done):
   pick 6dd09ed # Add keyword-overlap reranker
   pick 6c9c90c # Rerank retrieved passages
Next command to do (1 remaining command):
   pick 110124a # Document reranking
  (use "git rebase --edit-todo" to view and edit)
You are currently rebasing branch 'feature/rerank' on '323e8f1'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   app/retriever.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git worktree list
$LAB/ch25/lab-14-1-hotfix-worktree/rag-api 337498d (detached HEAD)
```
<!-- /snippet -->

<!-- snippet: ch25/lab-14-1-hotfix-worktree/02-blocked -->
```text
$ git switch main
fatal: cannot switch branch while rebasing
Consider "git rebase --quit" or "git worktree add".
[exit status: 128]
$ git stash
error: could not write index
app/retriever.py: needs merge
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch25/lab-14-1-hotfix-worktree/03-add -->
```text
$ git worktree add -b hotfix/empty-question ../rag-api-hotfix main
Preparing worktree (new branch 'hotfix/empty-question')
HEAD is now at 323e8f1 Document deployment
$ git worktree list
$LAB/ch25/lab-14-1-hotfix-worktree/rag-api        337498d (detached HEAD)
$LAB/ch25/lab-14-1-hotfix-worktree/rag-api-hotfix 323e8f1 [hotfix/empty-question]
$ cat ../rag-api-hotfix/.git
gitdir: $LAB/ch25/lab-14-1-hotfix-worktree/rag-api/.git/worktrees/rag-api-hotfix
```
<!-- /snippet -->

<!-- snippet: ch25/lab-14-1-hotfix-worktree/04-fix -->
```text
$ cd ../rag-api-hotfix
$ git status --short --branch
## hotfix/empty-question
$ sh scripts/check.sh
checks failed: app/api.py accepts an empty question
# Edit app/api.py: add the two lines shown by the diff.
$ git diff
diff --git a/app/api.py b/app/api.py
index 1e6749d..452ddaf 100644
--- a/app/api.py
+++ b/app/api.py
@@ -2,5 +2,7 @@ from app.retriever import retrieve
 
 
 def ask(index, question):
+    if not question or not question.strip():
+        raise ValueError("question must not be empty")
     passages = retrieve(index, question)
     return {"question": question, "passages": passages}
$ sh scripts/check.sh
checks passed
$ git commit -am "Reject empty questions"
[hotfix/empty-question 63fb99e] Reject empty questions
 1 file changed, 2 insertions(+)
$ git push -u origin hotfix/empty-question
To $LAB/ch25/lab-14-1-hotfix-worktree/remotes/rag-api.git
 * [new branch]      hotfix/empty-question -> hotfix/empty-question
branch 'hotfix/empty-question' set up to track 'origin/hotfix/empty-question'.
```
<!-- /snippet -->

<!-- snippet: ch25/lab-14-1-hotfix-worktree/05-first-tree-untouched -->
```text
$ cd ../rag-api
$ git status --short
UU app/retriever.py
$ git log --oneline --decorate -1 hotfix/empty-question
63fb99e (origin/hotfix/empty-question, hotfix/empty-question) Reject empty questions
$ git rev-parse --git-path rebase-merge
.git/rebase-merge
$ git -C ../rag-api-hotfix rev-parse --git-path rebase-merge
$LAB/ch25/lab-14-1-hotfix-worktree/rag-api/.git/worktrees/rag-api-hotfix/rebase-merge
```
<!-- /snippet -->

### What happened internally

`git worktree add` created the directory `../rag-api-hotfix` with a `.git` file, and the directory `.git/worktrees/rag-api-hotfix/` in the repository with a HEAD, an index and a reflog for the new worktree. `-b` created the ref `refs/heads/hotfix/empty-question` at the commit of `main`. No objects were copied. Your commit in the second directory wrote one commit, one tree for `app/`, one root tree and one blob into the shared object database and advanced the shared branch ref, which is why the first worktree can show the commit at once. The rebase state is the directory `rebase-merge`, and the last two commands show that this path resolves to a different place in each worktree: the stopped rebase belongs to the first worktree alone. `git worktree list` shows that worktree as `(detached HEAD)` because a rebase works on a detached HEAD until it finishes; the branch `feature/rerank` is nevertheless in use by it.

### Checkpoint

`git worktree list` prints two lines. `git status --short` in `rag-api` still prints `UU app/retriever.py`. `sh scripts/check.sh` passes in `rag-api-hotfix`. `git log -1 hotfix/empty-question`, run in `rag-api`, shows your commit, and it is on the remote.

### Failure scenario

The hotfix is pushed, so you tidy up. Do it the way people do it when they think of a worktree as a folder:

```bash
rm -rf ../rag-api-hotfix
git worktree list
git branch -d hotfix/empty-question
git worktree add ../rag-api-hotfix-2 hotfix/empty-question
```

<!-- snippet: ch25/lab-14-1-hotfix-worktree/06-failure -->
```text
# The hotfix is pushed. Tidy up the wrong way:
$ rm -rf ../rag-api-hotfix
$ git worktree list
$LAB/ch25/lab-14-1-hotfix-worktree/rag-api        337498d (detached HEAD)
$LAB/ch25/lab-14-1-hotfix-worktree/rag-api-hotfix 63fb99e [hotfix/empty-question] prunable
$ git branch -d hotfix/empty-question
error: cannot delete branch 'hotfix/empty-question' used by worktree at '$LAB/ch25/lab-14-1-hotfix-worktree/rag-api-hotfix'
[exit status: 1]
$ git worktree add ../rag-api-hotfix-2 hotfix/empty-question
Preparing worktree (checking out 'hotfix/empty-question')
fatal: 'hotfix/empty-question' is already used by worktree at '$LAB/ch25/lab-14-1-hotfix-worktree/rag-api-hotfix'
[exit status: 128]
```
<!-- /snippet -->

The directory is gone and Git still considers the branch checked out there. The listing says `prunable`. You cannot delete the branch, and you cannot check it out anywhere else. The cause is the entry `.git/worktrees/rag-api-hotfix/`: its `HEAD` file still says `ref: refs/heads/hotfix/empty-question`, and nothing told Git that the working tree it describes no longer exists.

### Recovery

Preview what `git worktree prune` would remove, then let it:

```bash
git worktree prune --dry-run --verbose
git worktree prune --verbose
git worktree list
git branch -d hotfix/empty-question
```

<!-- snippet: ch25/lab-14-1-hotfix-worktree/07-recovery -->
```text
$ git worktree prune --dry-run --verbose
Removing worktrees/rag-api-hotfix: gitdir file points to non-existent location
$ git worktree prune --verbose
Removing worktrees/rag-api-hotfix: gitdir file points to non-existent location
$ git worktree list
$LAB/ch25/lab-14-1-hotfix-worktree/rag-api 337498d (detached HEAD)
$ git branch -d hotfix/empty-question
warning: deleting branch 'hotfix/empty-question' that has been merged to
         'refs/remotes/origin/hotfix/empty-question', but not yet merged to HEAD
Deleted branch hotfix/empty-question (was 63fb99e).
```
<!-- /snippet -->

`git branch -d` now succeeds, with a warning: the branch is merged into its upstream `origin/hotfix/empty-question` and not into HEAD. That is acceptable here because the commit is on the remote. The command you should have used instead of `rm -rf` is `git worktree remove ../rag-api-hotfix`, which deletes the directory and the entry together and refuses if the tree has uncommitted work.

### Verification

Finish the rebase. Replace the conflicted file with the resolution (the settings from `main`, the reranking from the feature), stage it and continue:

```bash
cat > app/retriever.py <<'PY'
from app.rerank import rerank

TOP_K = 8


def retrieve(index, query):
    hits = index.search(query, limit=TOP_K)
    hits = [h for h in hits if len(h.text) > 20]
    return [h.text for h in rerank(query, hits)]
PY
git add app/retriever.py
git rebase --continue
git worktree list
git status --short --branch
git log --graph --oneline --decorate --all
ls .git/worktrees
```

<!-- snippet: ch25/lab-14-1-hotfix-worktree/08-finish-rebase -->
```text
# Back to the conflict. Edit app/retriever.py: keep TOP_K = 8 and the length filter from main,
# and the reranking from the feature. Then:
$ git add app/retriever.py
$ git rebase --continue
[detached HEAD cb5a1b2] Rerank retrieved passages
 1 file changed, 4 insertions(+), 1 deletion(-)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feature/rerank.
```
<!-- /snippet -->

<!-- snippet: ch25/lab-14-1-hotfix-worktree/09-verification -->
```text
$ git worktree list
$LAB/ch25/lab-14-1-hotfix-worktree/rag-api 4bc976b [feature/rerank]
$ git status --short --branch
## feature/rerank
$ git log --graph --oneline --decorate --all
* 4bc976b (HEAD -> feature/rerank) Document reranking
* cb5a1b2 Rerank retrieved passages
* 337498d Add keyword-overlap reranker
| * 63fb99e (origin/hotfix/empty-question) Reject empty questions
|/  
* 323e8f1 (origin/main, main) Document deployment
* 0a09820 Retrieve eight passages and drop short ones
* 168d50a (tag: v1.3.0) Add check script
* 6f8ad00 Add question endpoint and retriever
$ ls .git/worktrees 2>&1
ls: .git/worktrees: No such file or directory
```
<!-- /snippet -->

One worktree, on `feature/rerank`, with three rebased commits on top of `main`; the hotfix commit on `origin/hotfix/empty-question`; no `.git/worktrees` directory left. The rebased commits have the IDs shown here only in the replay; yours differ because the committer date is the time at which you continued.

### Questions

1. Compare your prediction with what you saw. Which of the five items are shared and which are per worktree? Name the command that settles such a question for any path.
2. `git worktree list` showed the first worktree as `(detached HEAD)`. Why? And why would `git worktree add ../x feature/rerank` have been refused at that moment?
3. After `rm -rf`, why did `git branch -d` still say the branch was "used by worktree"? Which file held that claim?
4. Suppose that, instead of committing on a branch, you had made the hotfix commit in a worktree created with `--detach`, pushed nothing, and then removed the worktree. Where would the commit be, and how would you look for it?
5. The hotfix is on `origin/hotfix/empty-question`, and `main` does not contain it yet. Your rebased `feature/rerank` does not contain it either. What happens to the fix when both are merged into `main`, and what would you do if `feature/rerank` needed the fix now?
6. Name two things that the second worktree did **not** have although the first one did (think of ignored files), and one thing that both shared and that could surprise you (think of `git stash`).
