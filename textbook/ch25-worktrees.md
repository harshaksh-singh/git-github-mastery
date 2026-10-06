# Chapter 25: Worktrees

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch25/`.

## 25.1 Why this matters

Three situations, each of which ends with someone asking you what to do:

1. "Production rejects nothing when the question is empty and the retriever falls over. I need a fix in ten minutes." You are in the middle of a rebase that has stopped at a conflict. `git switch main` is refused and `git stash` fails.
2. "Can you look at Asha's pull request now? She is blocked." Your working tree holds two hours of half-finished edits and a warm build cache.
3. "We want four coding agents working on four tasks in this repository at the same time. Do we need four clones?"

The usual answers are a second clone, or a stash and a branch switch. A second clone costs a full copy of the object database and has to be fetched and kept in sync separately. A stash and a switch disturb the one working tree you have, and during a conflicted rebase they are not available at all. Git's own answer is a **linked worktree**: one more working tree, with its own HEAD and its own index, attached to the repository you already have.

The project in this chapter is `rag-api`, a retrieval-augmented question-answering service. `main` is the release line and `feature/rerank` is your topic branch. Chapter 7 created one worktree from a tag to show a detached HEAD; this chapter covers the mechanism, the commands, and the ways it goes wrong.

## 25.2 What a linked worktree is

**In one sentence.** 🟢 `git worktree add <path> <branch>` creates a second directory of checked-out files that belongs to the same repository: the same objects and the same refs, with a HEAD and an index of its own.

**Analogy.** One library, several desks. Every desk has its own open book and its own bookmark (the checked-out files, HEAD, the index). The shelves (objects) and the catalogue (refs) are shared, so a book that one desk adds to the shelves is on the shelves for all of them. The analogy breaks at one rule that libraries do not have: Git allows a given branch to be open at one desk only (section 25.4).

**Precisely.** The manual distinguishes the **main worktree**, the one created by `git init` or `git clone`, from **linked worktrees** created by `git worktree add`. A repository has one main worktree, unless it is bare, and any number of linked ones. The word "worktree" means the working tree together with its per-worktree metadata ([git-worktree](https://git-scm.com/docs/git-worktree)).

**Inside `.git`.** Two things are created. In the new directory there is a `.git` file, not a directory, that contains one line pointing back into the repository. In the repository there is a private directory `.git/worktrees/<id>/` that holds what belongs to this worktree alone: `HEAD`, `index`, `logs/HEAD`, `ORIG_HEAD` and the other root refs, plus two small files, `gitdir` (where the working tree is) and `commondir` (where the shared part is, relative to this directory).

**See it.** You are on `main`; `feature/rerank` exists and is not checked out anywhere:

<!-- snippet: ch25/worktree-basics/01-add -->
```text
$ git log --graph --oneline --decorate --all
* 323e8f1 (HEAD -> main, origin/main) Document deployment
* 0a09820 Retrieve eight passages and drop short ones
| * 110124a (feature/rerank) Document reranking
| * 6c9c90c Rerank retrieved passages
| * 6dd09ed Add keyword-overlap reranker
|/  
* 168d50a (tag: v1.3.0) Add check script
* 6f8ad00 Add question endpoint and retriever
$ git worktree add ../rag-api-rerank feature/rerank
Preparing worktree (checking out 'feature/rerank')
HEAD is now at 110124a Document reranking
$ git worktree list
$LAB/ch25/worktree-basics/rag-api        323e8f1 [main]
$LAB/ch25/worktree-basics/rag-api-rerank 110124a [feature/rerank]
```
<!-- /snippet -->

`Preparing worktree (checking out 'feature/rerank')` is an ordinary checkout into another directory. No objects were copied. `git worktree list` prints one line per worktree: path, the commit its HEAD resolves to, and the branch in brackets. The main worktree is always first.

<!-- snippet: ch25/worktree-basics/02-link-files -->
```text
# The linked worktree has a .git FILE, not a directory:
$ cat ../rag-api-rerank/.git
gitdir: $LAB/ch25/worktree-basics/rag-api/.git/worktrees/rag-api-rerank
# It points at a private directory inside the one repository:
$ ls .git/worktrees/rag-api-rerank
commondir
gitdir
HEAD
index
logs
ORIG_HEAD
refs
$ cat .git/worktrees/rag-api-rerank/HEAD
ref: refs/heads/feature/rerank
$ cat .git/worktrees/rag-api-rerank/gitdir
$LAB/ch25/worktree-basics/rag-api-rerank/.git
$ cat .git/worktrees/rag-api-rerank/commondir
../..
```
<!-- /snippet -->

Read the three small files as a pair of pointers. The `.git` file in the working tree says where this worktree's private Git directory is. `gitdir` inside that directory points back at the working tree, which is how `git worktree list` and `git worktree prune` find out whether the working tree still exists. `commondir` contains `../..`: two levels up from `.git/worktrees/rag-api-rerank` is `.git`, the shared part.

**Picture.**

```text
  rag-api/                        (main worktree)          rag-api-rerank/        (linked worktree)
  +----------------------------+                           +---------------------------+
  | app/ docs/ scripts/ ...    |                           | app/ docs/ scripts/ ...   |
  | .git/            DIRECTORY |                           | .git                 FILE |
  |   HEAD   -> refs/heads/main|                           |   gitdir: .../rag-api/    |
  |   index                    |                           |     .git/worktrees/       |
  |   objects/  refs/  config  | <---- shared by both      |     rag-api-rerank        |
  |   hooks/    packed-refs    |                           +-------------+-------------+
  |   worktrees/               |                                         |
  |     rag-api-rerank/        | <---------------------------------------+
  |       HEAD  -> refs/heads/feature/rerank
  |       index   logs/HEAD   ORIG_HEAD
  |       gitdir      (path of the linked working tree's .git file)
  |       commondir   (../..)
  +----------------------------+
```

**In production.** A model-evaluation job runs for forty minutes against the files of a release tag. With one working tree nobody can touch the repository until it finishes. With `git worktree add --detach ../rag-api-v1.3.0 v1.3.0` the job gets a directory of its own, and you keep working.

## 25.3 What is shared and what is not

Inside a linked worktree Git works with two directories. `$GIT_DIR` is the private one; `$GIT_COMMON_DIR` is the repository's `.git`. Every path under "the Git directory" belongs to one of the two, and `git rev-parse --git-path` tells you which:

<!-- snippet: ch25/worktree-basics/03-git-path -->
```text
$ cd ../rag-api-rerank
$ git rev-parse --git-dir
$LAB/ch25/worktree-basics/rag-api/.git/worktrees/rag-api-rerank
$ git rev-parse --git-common-dir
$LAB/ch25/worktree-basics/rag-api/.git
# Per worktree:
$ git rev-parse --git-path HEAD --git-path index --git-path logs/HEAD --git-path ORIG_HEAD
$LAB/ch25/worktree-basics/rag-api/.git/worktrees/rag-api-rerank/HEAD
$LAB/ch25/worktree-basics/rag-api/.git/worktrees/rag-api-rerank/index
$LAB/ch25/worktree-basics/rag-api/.git/worktrees/rag-api-rerank/logs/HEAD
$LAB/ch25/worktree-basics/rag-api/.git/worktrees/rag-api-rerank/ORIG_HEAD
# Shared:
$ git rev-parse --git-path objects --git-path refs/heads/main --git-path config --git-path hooks
$LAB/ch25/worktree-basics/rag-api/.git/objects
$LAB/ch25/worktree-basics/rag-api/.git/refs/heads/main
$LAB/ch25/worktree-basics/rag-api/.git/config
$LAB/ch25/worktree-basics/rag-api/.git/hooks
```
<!-- /snippet -->

| Per worktree | Shared by all worktrees |
|---|---|
| The working tree files | The object database (`objects/`) |
| `HEAD`, and therefore "the current branch" | All refs under `refs/`: branches, tags, remote-tracking branches, `refs/stash` |
| The index (staging area) | `packed-refs` |
| `logs/HEAD` (the HEAD reflog) | Reflogs of branches |
| `ORIG_HEAD`, `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `FETCH_HEAD` and the other root refs | `config` (unless `extensions.worktreeConfig` is on, section 25.7) |
| The state of an operation in progress: `rebase-merge/`, `MERGE_MSG`, the sequencer | `hooks/`, `info/exclude` |
| `refs/bisect/*`, `refs/worktree/*`, `refs/rewritten/*` | Remotes and their URLs |

The manual's rule is short: refs that start with `refs/` are shared, with the three exceptions in the last row of the left column, and root refs such as HEAD are per worktree. The manual also warns not to guess: "do not make any assumption about whether a path belongs to `$GIT_DIR` or `$GIT_COMMON_DIR`"; ask `git rev-parse --git-path`.

Two consequences can be seen at once. First, a commit made in one worktree exists in the other the moment it is created, because the commit object and the branch ref are shared:

<!-- snippet: ch25/worktree-basics/04-shared-objects -->
```text
$ git commit -am "Document tie-breaking"
[feature/rerank ab93222] Document tie-breaking
 1 file changed, 2 insertions(+)
$ cd ../rag-api
# No fetch, no push: the branch ref and the new objects are already here.
$ git log --oneline -2 feature/rerank
ab93222 Document tie-breaking
110124a Document reranking
$ git branch -v
+ feature/rerank ab93222 Document tie-breaking
* main           323e8f1 Document deployment
```
<!-- /snippet -->

In `git branch -v` the `*` marks the branch checked out here and the `+` marks a branch checked out in another worktree. Second, staging is private. A file staged in the main worktree does not appear in the status of the linked one:

<!-- snippet: ch25/worktree-basics/05-separate-state -->
```text
$ git add docs/deploy.md
$ git status --short --branch
## main...origin/main
M  docs/deploy.md
$ git -C ../rag-api-rerank status --short --branch
## feature/rerank
```
<!-- /snippet -->

Because root refs are per worktree, the name `HEAD` means something different in each directory. To name another worktree's HEAD, prefix it: `main-worktree/HEAD` for the main one and `worktrees/<id>/HEAD` for a linked one, where `<id>` is the name of the directory under `.git/worktrees/`:

<!-- snippet: ch25/worktree-basics/06-other-heads -->
```text
# From any worktree you can name the HEAD of another one:
$ git log -1 --format="%h %s" main-worktree/HEAD
323e8f1 Document deployment
$ git log -1 --format="%h %s" worktrees/rag-api-rerank/HEAD
ab93222 Document tie-breaking
$ git -C ../rag-api-rerank log -1 --format="%h %s" main-worktree/HEAD
323e8f1 Document deployment
```
<!-- /snippet -->

State table for `git worktree add ../rag-api-rerank feature/rerank`, run in the main worktree:

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged here; a new working tree is written at the given path | unchanged here; a new index is written in `.git/worktrees/<id>/` | unchanged here; the new worktree gets its own `HEAD` | unchanged | `.git/worktrees/<id>/` created; with `-b`, a new branch ref; no objects copied | unchanged | unchanged |

## 25.4 One branch, one worktree

**In one sentence.** A branch can be checked out in at most one worktree, and Git refuses every command that would break this.

**See it.** `main` is checked out in the main worktree and `feature/rerank` in the linked one:

<!-- snippet: ch25/worktree-one-branch/01-refused -->
```text
$ git worktree add ../rag-api-second main
Preparing worktree (checking out 'main')
fatal: 'main' is already used by worktree at '$LAB/ch25/worktree-one-branch/rag-api'
[exit status: 128]
$ cd ../rag-api-rerank
$ git switch main
fatal: 'main' is already used by worktree at '$LAB/ch25/worktree-one-branch/rag-api'
[exit status: 128]
$ cd ../rag-api
```
<!-- /snippet -->

The same rule protects a checked-out branch from being deleted or moved from elsewhere:

<!-- snippet: ch25/worktree-one-branch/02-branch-protection -->
```text
$ git branch -D feature/rerank
error: cannot delete branch 'feature/rerank' used by worktree at '$LAB/ch25/worktree-one-branch/rag-api-rerank'
[exit status: 1]
$ git branch -f feature/rerank main
fatal: cannot force update the branch 'feature/rerank' used by worktree at '$LAB/ch25/worktree-one-branch/rag-api-rerank'
[exit status: 128]
```
<!-- /snippet -->

**Why.** A branch is one ref. A worktree that has the branch checked out assumes that its index and its files correspond to the commit the ref names. If two worktrees shared the ref, a commit in one would move the ref under the other, whose index and files would stay where they were. `--force` lets you build exactly that situation, so you can see it once in a sandbox:

<!-- snippet: ch25/worktree-one-branch/04-forced -->
```text
# What the rule prevents. Force a second checkout of main:
$ git worktree add --force ../rag-api-dup main
Preparing worktree (checking out 'main')
HEAD is now at 323e8f1 Document deployment
$ git commit -am "Point the README at the deployment notes"
[main 7e00138] Point the README at the deployment notes
 1 file changed, 2 insertions(+)
# Nobody touched the other worktree, and yet:
$ git -C ../rag-api-dup status
On branch main
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   README.md
```
<!-- /snippet -->

Nobody touched `rag-api-dup`, and its status reports a staged modification. The diff shows which one:

<!-- snippet: ch25/worktree-one-branch/05-forced-explained -->
```text
$ git -C ../rag-api-dup diff --cached
diff --git a/README.md b/README.md
index e038a61..a2cce02 100644
--- a/README.md
+++ b/README.md
@@ -1,5 +1,3 @@
 # rag-api
 
 Retrieval-augmented question answering.
-
-See docs/deploy.md for releases.
```
<!-- /snippet -->

```text
Observed behavior : A worktree that nobody edited shows "Changes to be committed"; the staged diff
                    removes the lines that the latest commit added.
Git state         : Both worktrees have HEAD -> refs/heads/main. The ref was advanced by a commit made
                    in the other worktree. This worktree's index and files still match the old commit.
Mechanism         : git status compares HEAD with the index. HEAD now resolves to the new commit; the
                    index describes the old tree. The difference, read from HEAD to index, is the
                    inverse of the new commit.
Root cause        : One ref, two indexes. Only the worktree that makes a commit updates its own index.
Why Git does this : The index is per worktree by design; Git has no mechanism that updates the index
                    and files of another worktree when a ref moves.
Correct fix       : In the stale worktree, if it has no work of its own: git reset --hard.
                    If it has: commit there would revert the other commit, so stash first, reset, pop.
Prevention        : Do not use --force with git worktree add. Use --detach or a new branch.
```

<!-- snippet: ch25/worktree-one-branch/06-forced-repair -->
```text
# The branch moved under that worktree; its index and files are one commit behind.
# It had no work of its own, so bring it up to date:
$ git -C ../rag-api-dup reset --hard
HEAD is now at 7e00138 Point the README at the deployment notes
$ git -C ../rag-api-dup status --short --branch
## main...origin/main [ahead 1]
```
<!-- /snippet -->

`git commit` in the stale worktree before the reset would have recorded the old tree on top of the new commit: a silent revert of a colleague's, or your own, work. That is the failure the rule exists to prevent.

When you need the files of a branch that is checked out elsewhere, and you do not intend to commit to it, detach:

<!-- snippet: ch25/worktree-one-branch/03-detached -->
```text
$ git worktree add --detach ../rag-api-readonly main
Preparing worktree (detached HEAD 323e8f1)
HEAD is now at 323e8f1 Document deployment
$ git worktree list
$LAB/ch25/worktree-one-branch/rag-api          323e8f1 [main]
$LAB/ch25/worktree-one-branch/rag-api-readonly 323e8f1 (detached HEAD)
$LAB/ch25/worktree-one-branch/rag-api-rerank   110124a [feature/rerank]
```
<!-- /snippet -->

A detached worktree holds a commit, not a branch, so any number of them can sit on the same commit.

Two things count as "checked out" that are easy to miss. A branch that is in the middle of a rebase or a bisect in some worktree is in use by that worktree, although `git worktree list` shows that worktree as `(detached HEAD)` (section 25.5 shows the refusal). And `git rebase --update-refs` skips branches that are checked out in a worktree: the manual states that such branches "are not updated in this way" ([Chapter 9](ch09-rebase.md)).

## 25.5 Use cases

### A hotfix while a rebase is stopped

You started `git rebase main` on `feature/rerank` and it stopped at a conflict. Then the incident arrives:

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

Both escape routes are closed. `git switch` refuses during a rebase, and Git's own message names the two alternatives: give up the rebase state, or add a worktree. `git stash` cannot write a tree from an index that has unmerged entries. Aborting the rebase would work and would throw away the conflict resolutions you have already done. The worktree costs nothing:

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

`-b hotfix/empty-question` creates the branch at `main` and checks it out in the new directory. `git worktree list` shows the main worktree as `(detached HEAD)`: that is the rebase, which works on a detached HEAD until it finishes ([Chapter 9](ch09-rebase.md)).

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

The fix was written, checked, committed and pushed from the second directory. Then the directory is removed and you are back where you were:

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

The rebase state lives in `.git/rebase-merge/`, which is per worktree, so nothing that happened next door could disturb it. The hotfix branch is an ordinary shared ref: it is still there after its worktree is gone, with its upstream configured. Lab 14.1 walks through this case by hand, including the cleanup mistake that people make afterwards.

### Reviewing a pull request

You have uncommitted work on `feature/rerank`. A teammate's branch arrives on the remote:

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

A detached worktree at the remote-tracking branch gives you the files to read, run and test, without creating a local branch that you would have to delete later, and your own modification is untouched throughout. If you intend to push commits to the branch, name it instead. When no local branch of that name exists and exactly one remote has one, `git worktree add` creates a tracking branch, the same convenience that `git switch` offers:

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

> **GitHub, not Git.** A pull request from a fork has no branch in your remote. GitHub publishes its head as the ref `refs/pull/<number>/head`, which you can fetch with `git fetch origin pull/<number>/head` and then check out from `FETCH_HEAD` in a detached worktree ([checking out pull requests locally](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/checking-out-pull-requests-locally)). The Phase 0 report records that GitHub CLI releases after the 2.88.1 installed here added `gh pr checkout --worktree`; it was not run for this book.

### Parallel work, by people or by AI agents

Each task gets a branch and a directory:

```bash
git worktree add -b agent/retry-policy   ../wt/retry-policy   main
git worktree add -b agent/citation-tests ../wt/citation-tests main
git worktree add -b agent/latency-budget ../wt/latency-budget main
git worktree list
```

Compared with separate clones, the worktrees share one object database, so there is no second copy of history and nothing to fetch between them: a branch committed in one directory can be diffed, merged or cherry-picked from any other immediately. The one-branch rule gives each agent exclusive ownership of its branch for free. What you have to supply yourself:

- **Dependencies and build output.** Ignored files are not part of any commit, so a new worktree has no virtual environment, no `node_modules`, no `.env` (section 25.7). Each worktree needs its own setup step.
- **Ports, caches and local databases** are outside Git's view. Two worktrees that start the same service collide exactly as two clones would.
- **Shared state inside `.git`.** Stashes, configuration and hooks are common to all worktrees (section 25.7). An agent that runs `git stash pop` may pop another agent's stash. Tell agents to commit to their branch and never to stash.
- **Integration is still a merge.** Parallel branches that touch the same lines conflict when they meet, however they were produced.
- **Cleanup.** `git worktree remove` for each directory and `git branch -d` for each merged branch, or the list grows without bound.

## 25.6 The life of a worktree: add, list, remove, lock, move, prune, repair

`git worktree add` has three common forms:

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

With only a path, Git creates a branch named after the last path component, here `spike-cache`, starting at HEAD. That default surprises people who meant "give me a copy of what I have": they get a new branch they did not ask for. `--orphan` starts a worktree on a new branch with no history and an empty index, and `--no-checkout` creates the worktree without writing files, for example to set up a sparse checkout first.

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

Use `--porcelain` (with `-z` if paths may contain newlines) in scripts; the manual promises that this format stays stable.

🟡 `git worktree remove` deletes the working tree directory and its entry under `.git/worktrees/`. It refuses when the tree has modified or untracked files. 🔴 `--force` overrides the refusal and deletes those files; nothing in Git can bring back files that were never added.

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

Removing a worktree does not delete its branch. The commits are safe in the shared repository; the branch stays until you delete it.

`git worktree lock` protects a worktree from `prune`, `move` and `remove`. Its purpose in the manual is a working tree on a removable disk or a network share that is not always mounted; it serves equally to mark a directory where a long job is running:

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
<!-- snippet: ch25/worktree-lifecycle/05-move -->
```text
$ git worktree move ../rag-api-v1.3.0 ../bench-1.3.0
$ git worktree list
$LAB/ch25/worktree-lifecycle/rag-api     323e8f1 [main]
$LAB/ch25/worktree-lifecycle/bench-1.3.0 168d50a (detached HEAD)
$LAB/ch25/worktree-lifecycle/rag-api-fix 168d50a [fix/top-k]
```
<!-- /snippet -->

`git worktree move` relocates a linked worktree and updates both pointers. It cannot move the main worktree, nor a worktree that contains submodules.

**Deleted by hand.** If someone removes the directory with `rm -rf`, the entry under `.git/worktrees/` remains, and with it the claim on the branch:

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

`prunable` in the listing and "gitdir file points to non-existent location" say the same thing: the admin entry points at a working tree that is gone. 🟡 `git worktree prune` removes such entries; `--dry-run --verbose` shows first what it would remove. Git also prunes stale entries by itself: `git gc` calls `git worktree prune --expire 3.months.ago` (the default of `gc.worktreePruneExpire`), and the automatic maintenance of Git 2.54 and later includes a worktree-prune task ([Chapter 26](ch26-performance.md)).

**Moved by hand.** If the directory was moved with `mv`, one of the two pointers is stale. `git worktree repair` rewrites them:

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

The name in the repair message, `worktrees/rag-api-v1.3.0`, is the worktree's ID: the directory name it was created with. The ID does not change when the working tree moves, which matters when you write `worktrees/<id>/HEAD`.

Moving or renaming the main worktree breaks the other direction: every linked worktree's `.git` file now points at a path that no longer exists.

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

Run `git worktree repair` in the main worktree and it fixes the `.git` file of every linked worktree it knows. If both ends have moved, run it in the main worktree with the new paths of the linked ones as arguments.

## 25.7 Pitfalls

**Ignored files do not come along.** A worktree is a checkout of a commit. What is not in the commit is not in the new directory:

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

**Stashes are shared.** `refs/stash` is under `refs/`, so there is one stash list for the whole repository:

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

A `git stash pop` in the main worktree would apply an entry that was made on another branch in another directory. In a repository with several worktrees, prefer a commit on the branch to a stash.

**Configuration and hooks are shared.** `git config set` without a scope writes `.git/config`, which every worktree reads:

<!-- snippet: ch25/worktree-shared-pitfalls/03-config-shared -->
```text
$ git -C ../rag-api-rerank config set user.email rerank-bot@example.com
$ git config get user.email
rerank-bot@example.com
$ git config list --show-origin --local | grep user.email
file:.git/config	user.email=rerank-bot@example.com
```
<!-- /snippet -->

Per-worktree configuration needs an extension that has to be switched on first. With it, `git config set --worktree` writes `config.worktree` in the private directory:

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

The manual notes that older Git versions refuse to work in a repository that has `extensions.worktreeConfig` set, and that `core.bare` and `core.worktree`, if present, must then be moved to the main worktree's `config.worktree`. Hooks live in the shared `hooks/` directory: a `pre-commit` hook runs for commits in every worktree, with the worktree's directory as its working directory.

**Garbage collection respects other worktrees.** A commit that is reachable only from the detached HEAD of another worktree is not unreachable. `git gc` takes the HEAD of every worktree into account:

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

That protection lasts as long as the worktree's admin entry does. After `git worktree remove` or `prune`, a commit that was made on a detached HEAD there is held by nothing, because the worktree's HEAD reflog went with the entry. Put work on a branch before you remove a detached worktree.

**From the manual's BUGS section.** "Multiple checkout in general is still experimental, and the support for submodules is incomplete. It is NOT recommended to make multiple checkouts of a superproject." In practice: a linked worktree of a repository with submodules starts with empty submodule directories and needs its own `git submodule update --init`; once a submodule is checked out in it, `git worktree move` refuses ("working trees containing submodules cannot be moved or removed") and `git worktree remove` refuses with the same message until you pass `--force`, as the manual says. The empty directory and the two refusals were run for this chapter; no transcript is printed ([Chapter 23](ch23-submodules.md)).

**Other limits worth knowing.** `git refs migrate`, which converts a repository between the files and reftable ref formats, cannot migrate a repository that has worktrees ([Chapter 3](ch03-git-internals.md)). Editors, language servers and file watchers treat each worktree as a separate project and index it separately. Disk use is the checked-out files per worktree, not the history.

## 25.8 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| `fatal: '<branch>' is already used by worktree at '<path>'` | `git worktree list`: the branch is checked out, or being rebased or bisected, there | Work in that worktree; or `--detach`; or a new branch with `-b` | One branch per task |
| `error: cannot delete branch '<b>' used by worktree at '<path>'`, and the path no longer exists | `git worktree list` shows `prunable` | `git worktree prune`, then delete the branch | `git worktree remove`, never `rm -rf` |
| `fatal: not a git repository` inside a linked worktree | The main worktree was moved or renamed; `cat .git` shows the old path | `git worktree repair` in the main worktree | Decide the directory layout before adding worktrees; or relative links (section 25.11) |
| A listing shows `prunable` for a worktree that exists | It was moved with `mv` | `git worktree repair <new path>` | `git worktree move` |
| Staged changes in a worktree nobody edited | Two worktrees on one branch (`--force`); section 25.4 | `git reset --hard` in the stale one, after saving any real work | Never force a second checkout of a branch |
| "It works in the other directory": imports fail, tests cannot find the environment | `git status --ignored` in the main worktree lists what the new one lacks | Create the environment in the new worktree | A setup script per worktree |
| A stash from another task appears in `git stash list` | `refs/stash` is shared | `git stash show -p stash@{n}` before applying; apply in the right worktree | Commit work in progress to its branch |
| A setting made "for this worktree" changed all of them | `git config list --show-origin` shows `.git/config` | `extensions.worktreeConfig` and `--worktree` | Know the scope before writing |
| `git worktree remove` refuses | Modified or untracked files, a lock, or submodules | Commit or clean; `unlock`; `--force` only after looking | Keep worktrees clean; lock with a reason |
| Commits made in a detached worktree cannot be found after it was removed | The worktree's HEAD reflog was deleted with it | `git fsck --lost-found` in the main worktree, before the next pruning ([Chapter 13](ch13-recovery.md)) | Create a branch before removing |

## 25.9 When not to use it, and dangerous edge cases

Do not reach for a worktree:

- **For a two-minute look at another branch** when your working tree is clean. `git switch` is enough.
- **To get isolation.** Worktrees share refs, stashes, configuration and hooks. For an untrusted experiment, a destructive history rewrite you want to rehearse, or a different set of remotes and credentials, use a separate clone.
- **For a superproject with submodules**, unless you have tested your exact workflow; the manual advises against it.
- **As a substitute for branches.** A worktree is where a branch is checked out. Ten worktrees on ten stale branches are ten stale branches.

Edge cases:

- 🔴 `git worktree remove --force` deletes untracked and modified files in that worktree. Preview with `git -C <path> status --short --ignored`.
- 🔴 `git worktree add --force <path> <branch>` for a branch that is checked out elsewhere creates the two-index situation of section 25.4.
- **A linked worktree placed inside the main working tree** shows up there as an untracked directory and is visible to `git clean -d`. Put worktrees beside the repository, not inside it.
- **Deleting the main worktree's directory deletes the repository**, and with it the history of every linked worktree. Linked worktrees are not backups.
- **A bare repository can have linked worktrees and no main one.** Some teams keep a bare clone and add every branch as a worktree next to it. That layout works; note that a bare clone made with `git clone --bare` has no remote-tracking branches configured, which changes how `fetch` behaves ([Chapter 12](ch12-remote-operations.md)).

## 25.10 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git worktree list`, `git rev-parse --git-path`, `git rev-parse --git-common-dir` | 🟢 SAFE | Nothing | not needed | not needed |
| `git worktree add <path> <branch>`, `--detach`, `-b` | 🟢 SAFE | A new directory, an entry in `.git/worktrees/`, with `-b` a new branch | `git worktree list`; `git branch --list <name>` | `git worktree remove`; `git branch -d` |
| `git worktree add --force` (branch already checked out) | 🔴 DANGEROUS | Two indexes on one ref | none; do not use | `git reset --hard` in the stale worktree after saving its work |
| `git worktree lock`, `unlock` | 🟢 SAFE | A `locked` file in the entry | `git worktree list --verbose` | the opposite command |
| `git worktree move` | 🟡 CAUTION | The directory and both pointers | `git worktree list` | move it back |
| `git worktree remove` | 🟡 CAUTION | Deletes a clean working tree and its entry, including its HEAD reflog | `git -C <path> status --short`; `git -C <path> log --oneline -3` | `git worktree add` again; detached commits via `git fsck --lost-found` |
| `git worktree remove --force` | 🔴 DANGEROUS | As above, and deletes uncommitted and untracked files | `git -C <path> status --short --ignored` | none for files that were never committed |
| `git worktree prune` | 🟡 CAUTION | Deletes entries whose working tree is missing, including their HEAD reflogs | `git worktree prune --dry-run --verbose` | `git worktree add` again; a moved tree: `repair` before pruning |
| `git worktree repair` | 🟢 SAFE | Rewrites the two pointer files | `git worktree list` | run it again with the right paths |

## 25.11 Version notes

> **Version note.** Older behavior: worktrees are linked with absolute paths, so moving the repository or mounting it at another path (a container, a network share) breaks the links until `git worktree repair`. Current behavior: the same by default; `git worktree add --relative-paths`, or `worktree.useRelativePaths=true`, writes relative links. Since: Git 2.48 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.48.0.adoc)). Recommended: leave the default unless the repository and its worktrees are moved together; relative links set a repository extension that older Git versions refuse to read.

- `git worktree` has been part of Git since 2.5. It is not labelled experimental, and its manual still carries the BUGS note quoted in section 25.7 ([git-worktree](https://github.com/git/git/blob/v2.56.0/Documentation/git-worktree.adoc)).
- Since Git 2.54 the default automatic maintenance removes worktree entries that cannot be located any more; before that, `git gc --auto` did so through `gc.worktreePruneExpire` ([maintenance configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/maintenance.adoc)).
- Git 2.56 adds an `includeIf` condition on the worktree location, so that a configuration file can be included for some worktrees only (not run here; [release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc)).

> **Outdated advice.** "Clone the repository a second time when you need two branches at once." It still works, and it is the right choice when you need isolation. For parallel work on one project it costs a second object database and a second set of remotes to keep current, which is what worktrees were added to avoid.

## 25.12 Practice

- Lab 14.1 in the [Module 14 worktree lab](../lab-manual/m14-worktrees.md): a hotfix in a second worktree while a rebase is stopped in the first, a cleanup that goes wrong, and the repair.
- Replay any transcript with `labs/run ch25/<demo>`, for example `labs/run ch25/worktree-lifecycle`.
- Two drills in the sandbox of `ch25/worktree-basics`: predict, then check with `git rev-parse --git-path`, whether `MERGE_HEAD`, `refs/tags/v1.3.0`, `info/exclude` and `refs/bisect/bad` are per worktree or shared; and start a `git bisect` in the linked worktree, then show from the main worktree that its HEAD did not move.

## 25.13 Interview questions

1. What exactly does `git worktree add` create on disk, in the new directory and in the repository?
2. Which parts of a repository are shared between worktrees and which are per worktree? How do you find out for a path you are unsure about?
3. Why does Git refuse to check out one branch in two worktrees? Describe what would go wrong, in terms of refs and indexes.
4. `git branch -d` says a branch is used by a worktree at a path that does not exist. What happened, and what are the two commands that diagnose and fix it?
5. A rebase has stopped at a conflict and an urgent fix is needed on `main`. Compare three options: abort the rebase, a second clone, a worktree.
6. A teammate ran `git stash pop` and got changes they had never seen. The repository has four worktrees. Explain.
7. Is a commit that exists only on the detached HEAD of a linked worktree safe from `git gc`? When does that stop being true?
8. Your team wants several AI coding agents to work in one repository at once. What do worktrees give you, and what do they not give you?
9. After moving a project directory to another disk, every linked worktree reports "not a git repository". What broke, how do you repair it, and how could it have been avoided?
10. When is a separate clone the better tool?

## 25.14 Sources

**Primary sources**

- [git-worktree](https://git-scm.com/docs/git-worktree): commands, the REFS, CONFIGURATION FILE, DETAILS and BUGS sections. The local copy (`git help -m worktree`) is the Git 2.55.0 text that the transcripts were checked against. Source of the current manual: [git-worktree.adoc](https://github.com/git/git/blob/v2.56.0/Documentation/git-worktree.adoc).
- `gc.worktreePruneExpire`, `extensions.worktreeConfig`, `worktree.guessRemote`, `worktree.useRelativePaths`, `checkout.defaultRemote`: `git help -m config`.
- [git-rebase](https://github.com/git/git/blob/v2.56.0/Documentation/git-rebase.adoc) for `--update-refs` and branches checked out in a worktree; [git-refs](https://github.com/git/git/blob/v2.55.0/Documentation/git-refs.adoc) for the migration limitation.
- Release notes: [2.48.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.48.0.adoc), [2.56.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).

**Secondary sources**

- The Phase 0 report of this course, section 1 (the table of newer commands and the maintenance defaults) and section 13.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- Scott Chacon, ["So You Think You Know Git Part 2 - DevWorld 2024"](https://www.youtube.com/watch?v=Md44rcw13k4) (23 min, 2024): worktrees among other topics. Current.
- Edward Thomson, ["You Don't Know Git"](https://www.youtube.com/watch?v=DZI0Zl-1JqQ), NDC London 2025 (1 h 02 min): reflog, rerere, worktrees, rebase variants. Current.
- glich.stream, ["Chad level git: advanced concepts (2025)"](https://www.youtube.com/watch?v=cYD3krz5L2g) (1 h 14 min): hands-on, includes worktrees and Git LFS. Current.

**Further reading**

- [gitrepository-layout](https://git-scm.com/docs/gitrepository-layout) for the `worktrees/` directory and the `commondir` and `gitdir` files.
