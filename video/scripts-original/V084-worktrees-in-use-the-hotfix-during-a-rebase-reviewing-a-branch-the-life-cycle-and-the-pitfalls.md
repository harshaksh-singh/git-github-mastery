# V084: Worktrees in use: the hotfix during a rebase, reviewing a branch, the life cycle, and the pitfalls

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 14, Worktrees, attributes, hooks, stash internals, rerere
- **Planned minutes.** 24
- **Prerequisites.** V053, V083
- **Textbook sections.** [Chapter 25](../../textbook/ch25-worktrees.md), sections 25.5 to 25.10
- **Demo scripts.** `labs/ch25/worktree-hotfix.sh`, `labs/ch25/worktree-review.sh`, `labs/ch25/worktree-lifecycle.sh`, `labs/ch25/worktree-shared-pitfalls.sh`

## HOOK

**[ON SCREEN]** `fatal: cannot switch branch while rebasing`

"Production rejects nothing when the question is empty and the retriever falls over. I need a fix in ten minutes."

You are in the middle of a rebase. It stopped at a conflict, and you have already resolved two earlier ones by hand. You type `git switch main`. Refused. You type `git stash`. It fails, because an index with unmerged entries cannot be written as a tree.

Three options are left. Abort the rebase and throw away the resolutions you have done. Clone the repository a second time and wait for the download. Or read the second line of Git's own error message, which says: Consider "git rebase --quit" or "git worktree add".

## INTRODUCTION

Last time you learned what a linked worktree is on disk and why one branch can be checked out in only one of them. Today you use it: for the hotfix in the hook, for reviewing a colleague's branch, and for parallel work by people or agents. Then the life cycle, seven verbs: add, list, remove, lock, move, prune, repair. And the surprises that come from the word "shared".

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- make an urgent fix in a second worktree while a rebase is stopped in the first;
- review a colleague's branch without disturbing your own work;
- add, list, remove, lock, move, prune and repair worktrees;
- explain three surprises that come from sharing: the stash, the configuration, ignored files;
- decide when a separate clone is the better tool.

## CONCEPT

**Why a worktree solves the hotfix.** The state of a rebase lives in `.git/rebase-merge/`, and that is per worktree. Nothing that happens in another worktree can disturb it. The hotfix branch, on the other hand, is an ordinary shared ref: it is still there after its worktree is gone.

**Reviewing.** A detached worktree at a remote-tracking branch gives you the files to read, run and test, without creating a local branch that you would have to delete later. If you intend to push commits to the branch, name it instead: when no local branch of that name exists and exactly one remote has one, `git worktree add` creates a tracking branch, the same convenience that `git switch` offers.

**Parallel work.** Each task gets a branch and a directory. Compared with separate clones, the worktrees share one object database, so a branch committed in one directory can be diffed, merged or cherry-picked from any other immediately. The one-branch rule gives each person or agent exclusive ownership of its branch. What you supply yourself: dependencies and build output for each worktree; separate ports, caches and local databases; an instruction never to stash; integration, which is still a merge; and cleanup.

**The life cycle.** `git worktree add` has three common forms. A path only: Git creates a new branch named after the last path component, starting at HEAD. That default surprises people who meant "give me a copy of what I have". With `-b`, an explicit new branch and a starting point. With `--detach`, no branch at all.

🟡 CAUTION: `git worktree remove` deletes the working tree directory and its entry under `.git/worktrees/`, including its HEAD reflog. It refuses when the tree has modified or untracked files. Removing a worktree does not delete its branch.

`git worktree lock` protects a worktree from prune, move and remove. `git worktree move` relocates a linked worktree and updates both pointers; it cannot move the main worktree, nor a worktree that contains submodules.

If someone removes the directory with `rm -rf`, the entry remains, and with it the claim on the branch. 🟡 CAUTION: `git worktree prune` removes such entries. If the directory was moved with `mv`, one of the two pointers is stale, and `git worktree repair`, which is 🟢 SAFE, rewrites them.

**The pitfalls of sharing.** Ignored files do not come along: a worktree is a checkout of a commit. Stashes are shared: `refs/stash` is under `refs/`. Configuration and hooks are shared: `git config set` without a scope writes `.git/config`, which every worktree reads; per-worktree configuration needs an extension that has to be switched on first.

**When not to use a worktree.** Section 25.9 lists four cases. For a two-minute look at another branch when your working tree is clean: `git switch` is enough. To get isolation: worktrees share refs, stashes, configuration and hooks, so for an untrusted experiment, a destructive history rewrite you want to rehearse, or a different set of remotes and credentials, use a separate clone. For a superproject with submodules, unless you have tested your exact workflow: the manual advises against it. And as a substitute for branches: ten worktrees on ten stale branches are ten stale branches.

## MENTAL MODEL

Keep the library with several desks. Today's additions are about the furniture.

A desk can be added and taken away without touching the shelves. Taking a desk away does not un-shelve the books written at it, as long as they were catalogued under a branch. But notes that lay on the desk and were never shelved, the untracked and modified files, go with the desk if you insist.

The library keeps a register of its desks. If a desk is carried out of the building without telling the librarian, the register still lists it and still reserves its branch. That is "prunable".

And three things sit at the front counter, not at any desk: the stash drawer, the house rules, and the hooks. Every desk uses the same ones. The analogy breaks if you take it to mean that the desks are independent copies; they are not, and deleting the main worktree's directory deletes the repository for all of them.

## DIAGRAM

**[DIAGRAM]** One repository box with three worktree boxes around it. Shared items inside the repository box, per-worktree items inside each worktree box.

```text
                       +------------------------------------------------+
                       |  the repository  (.git of the main worktree)   |
                       |  objects/       all refs under refs/           |
                       |  refs/stash     branch reflogs                 |
                       |  config         hooks/      info/exclude       |
                       |  remotes and their URLs                        |
                       +-----+--------------------+---------------+-----+
                             |                    |               |
        +--------------------+---+   +------------+-----------+   +---+----------------------+
        | rag-api   (main)       |   | rag-api-hotfix (linked)|   | rag-api-review (linked)  |
        | files                  |   | files                  |   | files                    |
        | HEAD: rebase, detached |   | HEAD: hotfix/...       |   | HEAD: detached           |
        | index (with conflicts) |   | index                  |   | index                    |
        | rebase-merge/          |   | logs/HEAD              |   | logs/HEAD                |
        | ignored files: .venv   |   | no .venv               |   | no .venv                 |
        +------------------------+   +------------------------+   +--------------------------+
```

Point at `rebase-merge/` in the left box: that is why the hotfix cannot disturb the rebase. Point at `refs/stash` and `config` in the top box: that is where two of today's surprises come from. Point at the `.venv` lines: that is the third.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch25/worktree-hotfix`. The rebase has stopped at a conflict.

```bash
git status --short --branch
git branch
git switch main
git stash
```

<!-- snippet: ch25/worktree-hotfix/01-stuck -->
```text
$ git status --short --branch
## HEAD (no branch)
UU app/retriever.py
$ git branch
* (no branch, rebasing feature/rerank)
  feature/rerank
  main
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

Both escape routes are closed, and the refusal of `git switch` names the alternative. 🟢 SAFE: `git worktree add -b` creates a directory, an entry and a new branch.

```bash
git worktree add -b hotfix/empty-question ../rag-api-hotfix main
git worktree list
```

<!-- snippet: ch25/worktree-hotfix/02-add -->
```text
$ git worktree add -b hotfix/empty-question ../rag-api-hotfix main
Preparing worktree (new branch 'hotfix/empty-question')
HEAD is now at 323e8f1 Document deployment
$ git worktree list
$LAB/ch25/worktree-hotfix/rag-api        337498d (detached HEAD)
$LAB/ch25/worktree-hotfix/rag-api-hotfix 323e8f1 [hotfix/empty-question]
```
<!-- /snippet -->

`-b` creates the branch at `main` and checks it out in the new directory. The list shows the main worktree as "(detached HEAD)": that is the rebase, which works on a detached HEAD until it finishes.

<!-- snippet: ch25/worktree-hotfix/03-fix -->
```text
$ cd ../rag-api-hotfix
$ sh scripts/check.sh
checks failed: app/api.py accepts an empty question
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
[hotfix/empty-question dd34256] Reject empty questions
 1 file changed, 2 insertions(+)
$ git push -u origin hotfix/empty-question
To $LAB/ch25/worktree-hotfix/remotes/rag-api.git
 * [new branch]      hotfix/empty-question -> hotfix/empty-question
branch 'hotfix/empty-question' set up to track 'origin/hotfix/empty-question'.
```
<!-- /snippet -->

The fix is written, checked, committed and pushed from the second directory. Now go back. Predict what `git status` shows in the first directory.

```bash
cd ../rag-api
git worktree remove ../rag-api-hotfix
git worktree list
git status --short
git branch -vv
```

<!-- snippet: ch25/worktree-hotfix/04-back -->
```text
$ cd ../rag-api
$ git worktree remove ../rag-api-hotfix
$ git worktree list
$LAB/ch25/worktree-hotfix/rag-api 337498d (detached HEAD)
# The rebase is exactly where you left it, and the hotfix branch is in the shared refs:
$ git status --short
UU app/retriever.py
$ git branch -vv
* (no branch, rebasing feature/rerank) 337498d Add keyword-overlap reranker
  feature/rerank                       110124a Document reranking
  hotfix/empty-question                dd34256 [origin/hotfix/empty-question] Reject empty questions
  main                                 323e8f1 [origin/main] Document deployment
```
<!-- /snippet -->

The rebase is exactly where you left it, `UU app/retriever.py`, and the hotfix branch is in the shared refs with its upstream configured.

**[TERMINAL]** Replay `labs/run ch25/worktree-review`. You have uncommitted work on `feature/rerank`, and a teammate's branch arrives.

```bash
git status --short --branch
git fetch origin
```

<!-- snippet: ch25/worktree-review/01-fetch -->
```text
$ git status --short --branch
## feature/rerank
 M app/rerank.py
$ git fetch origin
From $LAB/ch25/worktree-review/remotes/rag-api
 * [new branch]      feature/citations -> origin/feature/citations
```
<!-- /snippet -->

```bash
git worktree add --detach ../rag-api-review origin/feature/citations
cd ../rag-api-review
git log --oneline main..HEAD
git diff --stat main...HEAD
```

<!-- snippet: ch25/worktree-review/02-detached-review -->
```text
$ git worktree add --detach ../rag-api-review origin/feature/citations
Preparing worktree (detached HEAD 00daaec)
HEAD is now at 00daaec Number the passages so answers can cite them
$ cd ../rag-api-review
$ git log --oneline main..HEAD
00daaec Number the passages so answers can cite them
$ git diff --stat main...HEAD
 app/api.py | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
$ cd ../rag-api
$ git worktree remove ../rag-api-review
$ git status --short --branch
## feature/rerank
 M app/rerank.py
```
<!-- /snippet -->

A detached worktree at `00daaec`. You read, run and test there; your own modification is untouched throughout. And if you intend to push commits to the branch:

```bash
git worktree add ../rag-api-citations feature/citations
git -C ../rag-api-citations status --short --branch
```

<!-- snippet: ch25/worktree-review/03-with-a-branch -->
```text
# If you intend to push commits to the branch, name it. No local branch feature/citations
# exists; exactly one remote has one, so Git creates a tracking branch:
$ git worktree add ../rag-api-citations feature/citations
Preparing worktree (new branch 'feature/citations')
branch 'feature/citations' set up to track 'origin/feature/citations'.
HEAD is now at 00daaec Number the passages so answers can cite them
$ git -C ../rag-api-citations status --short --branch
## feature/citations...origin/feature/citations
$ git worktree list
$LAB/ch25/worktree-review/rag-api           110124a [feature/rerank]
$LAB/ch25/worktree-review/rag-api-citations 00daaec [feature/citations]
```
<!-- /snippet -->

"new branch 'feature/citations'" and "set up to track".

**[ON SCREEN]** Lower third: **GitHub**. A pull request from a fork has no branch in your remote. According to GitHub's documentation, it publishes the head as the ref `refs/pull/<number>/head`, which you can fetch and then check out from `FETCH_HEAD` in a detached worktree. The textbook records that GitHub CLI releases after the 2.88.1 installed for this course added `gh pr checkout --worktree`; it was not run for the book.

**[TERMINAL]** Replay `labs/run ch25/worktree-lifecycle`.

<!-- snippet: ch25/worktree-lifecycle/01-add-forms -->
```text
# Path only: a new branch named after the last path component.
$ git worktree add ../spike-cache
Preparing worktree (new branch 'spike-cache')
HEAD is now at 323e8f1 Document deployment
# An explicit new branch and a starting point.
$ git worktree add -b fix/top-k ../rag-api-fix v1.3.0
Preparing worktree (new branch 'fix/top-k')
HEAD is now at 168d50a Add check script
# No branch at all.
$ git worktree add --detach ../rag-api-v1.3.0 v1.3.0
Preparing worktree (detached HEAD 168d50a)
HEAD is now at 168d50a Add check script
```
<!-- /snippet -->

Look at the first form: a path only, and Git says "new branch 'spike-cache'". You did not ask for a branch.

```bash
git worktree list
git worktree list --porcelain | head -8
```

<!-- snippet: ch25/worktree-lifecycle/02-list -->
```text
$ git worktree list
$LAB/ch25/worktree-lifecycle/rag-api        323e8f1 [main]
$LAB/ch25/worktree-lifecycle/rag-api-fix    168d50a [fix/top-k]
$LAB/ch25/worktree-lifecycle/rag-api-v1.3.0 168d50a (detached HEAD)
$LAB/ch25/worktree-lifecycle/spike-cache    323e8f1 [spike-cache]
$ git worktree list --porcelain | head -8
worktree $LAB/ch25/worktree-lifecycle/rag-api
HEAD 323e8f143a79eac653c3f09a2981e88ef090051d
branch refs/heads/main

worktree $LAB/ch25/worktree-lifecycle/rag-api-fix
HEAD 168d50a8eb883a9cddffbd6a29347766e81da70e
branch refs/heads/fix/top-k
```
<!-- /snippet -->

Use `--porcelain` in scripts; the manual promises that this format stays stable.

**[ON SCREEN]** 🔴 DANGEROUS: `git worktree remove --force`. What it changes: it deletes the working tree and its entry. What it can destroy: uncommitted and untracked files in that worktree. Preview: `git -C <path> status --short --ignored`. Recovery: none for files that were never committed. Appropriate: after you have looked, for a directory whose leftovers you do not need.

```bash
git worktree remove ../spike-cache
git worktree remove --force ../spike-cache
git branch --list "spike*"
git branch -d spike-cache
```

<!-- snippet: ch25/worktree-lifecycle/03-remove -->
```text
$ git worktree remove ../spike-cache
fatal: '../spike-cache' contains modified or untracked files, use --force to delete it
[exit status: 128]
$ git worktree remove --force ../spike-cache
# The worktree is gone. Its branch is not:
$ git branch --list "spike*"
  spike-cache
$ git branch -d spike-cache
Deleted branch spike-cache (was 323e8f1).
```
<!-- /snippet -->

The plain form refused. After the forced removal the worktree is gone and its branch is not; the branch is deleted separately.

```bash
git worktree lock --reason "benchmark of 1.3.0 running until Friday" ../rag-api-v1.3.0
git worktree list --verbose
git worktree remove ../rag-api-v1.3.0
```

<!-- snippet: ch25/worktree-lifecycle/04-lock -->
```text
$ git worktree lock --reason "benchmark of 1.3.0 running until Friday" ../rag-api-v1.3.0
$ git worktree list --verbose
$LAB/ch25/worktree-lifecycle/rag-api        323e8f1 [main]
$LAB/ch25/worktree-lifecycle/rag-api-fix    168d50a [fix/top-k]
$LAB/ch25/worktree-lifecycle/rag-api-v1.3.0 168d50a (detached HEAD)
	locked: benchmark of 1.3.0 running until Friday
$ git worktree remove ../rag-api-v1.3.0
fatal: cannot remove a locked working tree, lock reason: benchmark of 1.3.0 running until Friday
use 'remove -f -f' to override or unlock first
[exit status: 128]
$ cat .git/worktrees/rag-api-v1.3.0/locked
benchmark of 1.3.0 running until Friday
$ git worktree unlock ../rag-api-v1.3.0
```
<!-- /snippet -->

A lock with a reason, and the refusal quotes the reason. 🟡 CAUTION: `git worktree move`.

<!-- snippet: ch25/worktree-lifecycle/05-move -->
```text
$ git worktree move ../rag-api-v1.3.0 ../bench-1.3.0
$ git worktree list
$LAB/ch25/worktree-lifecycle/rag-api     323e8f1 [main]
$LAB/ch25/worktree-lifecycle/bench-1.3.0 168d50a (detached HEAD)
$LAB/ch25/worktree-lifecycle/rag-api-fix 168d50a [fix/top-k]
```
<!-- /snippet -->

Now the directory deleted by hand. Predict: can you delete its branch afterwards?

```bash
rm -rf ../rag-api-fix
git worktree list
git branch -d fix/top-k
git worktree prune --dry-run --verbose
```

<!-- snippet: ch25/worktree-lifecycle/06-deleted-by-hand -->
```text
$ rm -rf ../rag-api-fix
$ git worktree list
$LAB/ch25/worktree-lifecycle/rag-api     323e8f1 [main]
$LAB/ch25/worktree-lifecycle/bench-1.3.0 168d50a (detached HEAD)
$LAB/ch25/worktree-lifecycle/rag-api-fix 168d50a [fix/top-k] prunable
$ git branch -d fix/top-k
error: cannot delete branch 'fix/top-k' used by worktree at '$LAB/ch25/worktree-lifecycle/rag-api-fix'
[exit status: 1]
$ git worktree prune --dry-run --verbose
Removing worktrees/rag-api-fix: gitdir file points to non-existent location
$ git worktree prune --verbose
Removing worktrees/rag-api-fix: gitdir file points to non-existent location
$ git branch -d fix/top-k
Deleted branch fix/top-k (was 168d50a).
```
<!-- /snippet -->

No. "prunable" in the listing, and the branch is still "used by worktree at" a path that no longer exists. The dry run says why: the gitdir file points to a non-existent location. `git worktree prune` removes such entries. Git also prunes stale entries by itself: `git gc` uses a default expiry of three months, and the automatic maintenance of Git 2.54 and later includes a worktree-prune task.

Moved by hand:

```bash
mv ../bench-1.3.0 ../bench-old-release
git worktree list
git worktree repair ../bench-old-release
git worktree list
```

<!-- snippet: ch25/worktree-lifecycle/07-moved-by-hand -->
```text
$ mv ../bench-1.3.0 ../bench-old-release
$ git worktree list
$LAB/ch25/worktree-lifecycle/rag-api     323e8f1 [main]
$LAB/ch25/worktree-lifecycle/bench-1.3.0 168d50a (detached HEAD) prunable
$ git worktree repair ../bench-old-release
repair: gitdir incorrect: $LAB/ch25/worktree-lifecycle/rag-api/.git/worktrees/rag-api-v1.3.0/gitdir
$ git worktree list
$LAB/ch25/worktree-lifecycle/rag-api           323e8f1 [main]
$LAB/ch25/worktree-lifecycle/bench-old-release 168d50a (detached HEAD)
```
<!-- /snippet -->

The repair message names `worktrees/rag-api-v1.3.0`: the worktree's ID, the directory name it was created with. The ID does not change when the working tree moves.

And the main worktree itself renamed:

<!-- snippet: ch25/worktree-lifecycle/08-main-moved -->
```text
# Now the main worktree itself is renamed. The linked one loses its way home:
$ cd .. && mv rag-api rag-api-main && cd rag-api-main
$ git -C ../bench-old-release status --short --branch
fatal: not a git repository: (null)
[exit status: 128]
$ git worktree repair
repair: .git file broken: $LAB/ch25/worktree-lifecycle/bench-old-release
$ git -C ../bench-old-release status --short --branch
## HEAD (no branch)
```
<!-- /snippet -->

"not a git repository" in the linked worktree, until `git worktree repair` runs in the main one.

**[TERMINAL]** Replay `labs/run ch25/worktree-shared-pitfalls`. Three surprises.

<!-- snippet: ch25/worktree-shared-pitfalls/01-ignored-files -->
```text
# The virtual environment is ignored, so it is not in any commit:
$ git status --short --ignored
!! .venv/
$ ls -A
.git
.gitignore
.venv
app
docs
README.md
scripts
$ ls -A ../rag-api-rerank
.git
.gitignore
app
docs
README.md
scripts
```
<!-- /snippet -->

The virtual environment is ignored, so it is in no commit, so it is not in the new worktree.

```bash
git stash push -m "rerank: cache idea"
cd ../rag-api
git stash list
git rev-parse --git-path refs/stash
```

Predict: the stash was made in the other directory. Is it listed here?

<!-- snippet: ch25/worktree-shared-pitfalls/02-stash-shared -->
```text
$ cd ../rag-api-rerank
$ git stash push -m "rerank: cache idea"
Saved working directory and index state On feature/rerank: rerank: cache idea
$ cd ../rag-api
# refs/stash lives under refs/, and refs/ is shared:
$ git stash list
stash@{0}: On feature/rerank: rerank: cache idea
$ git rev-parse --git-path refs/stash
.git/refs/stash
```
<!-- /snippet -->

Yes. One stash list for the whole repository. A `git stash pop` here would apply an entry that was made on another branch in another directory.

```bash
git -C ../rag-api-rerank config set user.email rerank-bot@example.com
git config get user.email
git config list --show-origin --local | grep user.email
```

<!-- snippet: ch25/worktree-shared-pitfalls/03-config-shared -->
```text
$ git -C ../rag-api-rerank config set user.email rerank-bot@example.com
$ git config get user.email
rerank-bot@example.com
$ git config list --show-origin --local | grep user.email
file:.git/config	user.email=rerank-bot@example.com
```
<!-- /snippet -->

A setting made "for that worktree" changed all of them. Per-worktree configuration needs the extension.

<!-- snippet: ch25/worktree-shared-pitfalls/04-config-per-worktree -->
```text
$ git -C ../rag-api-rerank config set --worktree user.email rerank-bot@example.com
fatal: --worktree cannot be used with multiple working trees unless the config
extension worktreeConfig is enabled. Please read "CONFIGURATION FILE"
section in "git help worktree" for details
[exit status: 128]
$ git config set extensions.worktreeConfig true
$ git -C ../rag-api-rerank config set --worktree user.email rerank-bot@example.com
$ git -C ../rag-api-rerank config get user.email
rerank-bot@example.com
$ git config get user.email
you@example.com
$ git -C ../rag-api-rerank rev-parse --git-path config.worktree
$LAB/ch25/worktree-shared-pitfalls/rag-api/.git/worktrees/rag-api-rerank/config.worktree
```
<!-- /snippet -->

`--worktree` is refused until `extensions.worktreeConfig` is true. The manual notes that older Git versions refuse to work in a repository that has this extension set.

One reassurance: garbage collection respects other worktrees.

<!-- snippet: ch25/worktree-shared-pitfalls/05-gc-keeps-other-worktrees -->
```text
$ cd ../rag-api-try
$ git commit -m "Try twelve passages"
[detached HEAD 69669bf] Try twelve passages
 1 file changed, 1 insertion(+)
 create mode 100644 app/settings.py
$ cd ../rag-api
# That commit is on no branch. Only the HEAD of the other worktree holds it.
$ git branch --contains worktrees/rag-api-try/HEAD
$ git gc --quiet --prune=now
$ git cat-file -t worktrees/rag-api-try/HEAD
commit
```
<!-- /snippet -->

A commit held only by the detached HEAD of another worktree survives `git gc --prune=now`. That protection lasts as long as the worktree's entry does. After `remove` or `prune`, a commit made on a detached HEAD there is held by nothing, because the worktree's HEAD reflog went with the entry. Put work on a branch before you remove a detached worktree.

## COMMON MISTAKES

1. **Deleting a worktree directory with `rm -rf`.** Root cause: the entry under `.git/worktrees/` remains and keeps its claim on the branch until `git worktree prune`.
2. **`git worktree add ../name` to "copy what I have".** Root cause: with only a path, Git creates a new branch named after the last path component.
3. **`git stash pop` in a repository with several worktrees.** Root cause: `refs/stash` is under `refs/` and therefore shared; the newest entry may belong to another task.
4. **Setting configuration "for this worktree" with a plain `git config set`.** Root cause: it writes `.git/config`, which every worktree reads; per-worktree settings need `extensions.worktreeConfig` and `--worktree`.
5. **Removing a detached worktree that holds commits.** Root cause: the commits were named only by that worktree's HEAD and HEAD reflog, and both are deleted with the entry.

## PRODUCTION EXAMPLE

A team runs three coding agents on one service repository. Each task gets a worktree and a branch with a prefix. The setup script that creates a worktree also creates a virtual environment in it and assigns a port, because ignored files, ports and caches are outside what Git shares or separates.

The agents' instructions contain one Git rule from section 25.5: commit to your branch, and never stash, because an agent that runs `git stash pop` may pop another agent's stash. Integration is an ordinary merge, and two branches that touched the same lines conflict as they always would. A cleanup job runs `git worktree remove` for each finished directory and `git branch -d` for each merged branch, and nobody deletes directories by hand.

For one task the team uses a separate clone on purpose: rehearsing a history rewrite. Worktrees share refs, and a rehearsal that rewrites refs is not something to share.

## PRACTICE EXERCISE

Do Lab 14.1, "A hotfix in a second worktree while a rebase is in progress", in [`lab-manual/m14-worktrees.md`](../../lab-manual/m14-worktrees.md).

Before you add the worktree, predict what `git worktree list` will show for the first directory while the rebase is stopped. Before you return, predict the output of `git status --short` there. The lab's failure scenario is the cleanup mistake people make afterwards; predict which command will refuse, and with which message.

The challenge is Exercise 14.9, Level 4, "Two fixes in a worktree that no longer exists", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q114: "A rebase has stopped at a conflict and an urgent fix is needed on `main`. Compare three options: abort the rebase, a second clone, a worktree."

Pause and answer aloud.

A strong answer first explains why the two everyday reflexes are unavailable in this state. It then compares the three options on the same criteria: what is lost, what it costs in time and disk, what has to be kept in sync afterwards, and what is shared. It explains why the rebase survives next to a worktree, in terms of where its state is stored. It does not present the worktree as free of trade-offs: it names what the worktree shares that a clone does not, and gives a situation in which the clone is the right choice.

## RECAP

You should now be able to say:

- A stopped rebase stays intact while I fix something in another worktree, because the rebase state is per worktree and the new branch is a shared ref.
- For review I add a detached worktree at the remote-tracking branch, or name the branch if I will push to it.
- I remove worktrees with `git worktree remove`, clean up after manual deletion with `prune`, and after manual moves with `repair`.
- Ignored files are not in a new worktree; the stash list, the configuration and the hooks are shared by all of them.
- When I need isolation, I use a separate clone.

## HOMEWORK

Read sections 25.5 to 25.10 of [Chapter 25](../../textbook/ch25-worktrees.md) and do the Practice section, 25.12.
