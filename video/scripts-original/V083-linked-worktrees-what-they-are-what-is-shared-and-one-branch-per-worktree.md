# V083: Linked worktrees: what they are, what is shared, and one branch per worktree

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 14, Worktrees, attributes, hooks, stash internals, rerere
- **Planned minutes.** 20
- **Prerequisites.** V023
- **Textbook sections.** [Chapter 25](../../textbook/ch25-worktrees.md), sections 25.1 to 25.4
- **Demo scripts.** `labs/ch25/worktree-basics.sh`, `labs/ch25/worktree-one-branch.sh`

## HOOK

**[ON SCREEN]** "We want four coding agents working on four tasks in this repository at the same time. Do we need four clones?"

That question reaches you from a team lead. Two more arrive the same week. "Production falls over on an empty question; I need a fix in ten minutes", while you are in the middle of a rebase that has stopped at a conflict, where `git switch main` is refused and `git stash` fails. And "can you look at Asha's pull request now, she is blocked", while your working tree holds two hours of half-finished edits and a warm build cache.

The usual answers are a second clone, or a stash and a branch switch. A second clone costs a full copy of the object database and has to be fetched and kept in sync separately. A stash and a switch disturb the one working tree you have, and during a conflicted rebase they are not available at all.

Git's own answer is a linked worktree: one more working tree, with its own HEAD and its own index, attached to the repository you already have.

## INTRODUCTION

You used a worktree twice already without studying it: once to show a detached HEAD on a tag, and once to test a suspect commit and its parent side by side. Today you learn the mechanism. What is created on disk, what is shared, what is private, and the one rule that keeps the whole arrangement safe. The next video is about using it.

The project is `rag-api`, a retrieval-augmented question-answering service. `main` is the release line and `feature/rerank` is your topic branch.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- say what `git worktree add` creates in the new directory and in the repository;
- list what worktrees share and what each has for itself;
- find the real location of a per-worktree file with `git rev-parse --git-path`;
- explain why Git refuses to check out one branch in two worktrees, and what forcing it breaks.

## CONCEPT

In one sentence: 🟢 SAFE, `git worktree add <path> <branch>` creates a second directory of checked-out files that belongs to the same repository: the same objects and the same refs, with a HEAD and an index of its own.

Precisely. The manual distinguishes the main worktree, the one created by `git init` or `git clone`, from linked worktrees created by `git worktree add`. A repository has one main worktree, unless it is bare, and any number of linked ones. The word "worktree" means the working tree together with its per-worktree metadata.

Inside `.git`, two things are created. In the new directory there is a `.git` file, not a directory, that contains one line pointing back into the repository. In the repository there is a private directory, `.git/worktrees/<id>/`, that holds what belongs to this worktree alone: `HEAD`, `index`, `logs/HEAD`, `ORIG_HEAD` and the other root refs, plus two small files. `gitdir` says where the working tree is. `commondir` says where the shared part is, relative to this directory.

So inside a linked worktree Git works with two directories. `$GIT_DIR` is the private one. `$GIT_COMMON_DIR` is the repository's `.git`. Every path under "the Git directory" belongs to one of the two.

**[ON SCREEN]** The table of section 25.3.

| Per worktree | Shared by all worktrees |
|---|---|
| The working tree files | The object database (`objects/`) |
| `HEAD`, and therefore "the current branch" | All refs under `refs/`: branches, tags, remote-tracking branches, `refs/stash` |
| The index (staging area) | `packed-refs` |
| `logs/HEAD` (the HEAD reflog) | Reflogs of branches |
| `ORIG_HEAD`, `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `FETCH_HEAD` and the other root refs | `config` (unless `extensions.worktreeConfig` is on, section 25.7) |
| The state of an operation in progress: `rebase-merge/`, `MERGE_MSG`, the sequencer | `hooks/`, `info/exclude` |
| `refs/bisect/*`, `refs/worktree/*`, `refs/rewritten/*` | Remotes and their URLs |

The manual's rule is short: refs that start with `refs/` are shared, with the three exceptions in the last row of the left column, and root refs such as HEAD are per worktree. It also warns not to guess. Ask `git rev-parse --git-path`.

Now the rule. In one sentence: a branch can be checked out in at most one worktree, and Git refuses every command that would break this.

Why? A branch is one ref. A worktree that has the branch checked out assumes that its index and its files correspond to the commit the ref names. If two worktrees shared the ref, a commit in one would move the ref under the other, whose index and files would stay where they were.

When you need the files of a branch that is checked out elsewhere, and you do not intend to commit to it, detach. A detached worktree holds a commit, not a branch, so any number of them can sit on the same commit.

Two things count as "checked out" that are often missed. A branch that is in the middle of a rebase or a bisect in some worktree is in use by that worktree, although `git worktree list` shows that worktree as detached. And `git rebase --update-refs` skips branches that are checked out in a worktree.

## MENTAL MODEL

The textbook's analogy: one library, several desks. Every desk has its own open book and its own bookmark: the checked-out files, HEAD, the index. The shelves, which are the objects, and the catalogue, which is the refs, are shared. A book that one desk adds to the shelves is on the shelves for all of them.

The analogy breaks at one rule that libraries do not have: Git allows a given branch to be open at one desk only.

Hold on to the two halves when you predict behavior. Anything that is an object or a ref under `refs/` is visible from every desk immediately, with no fetch and no push. Anything that is "where I am" or "what I have staged" belongs to one desk.

## DIAGRAM

**[DIAGRAM]** The picture of section 25.2. Draw the main worktree's box first, then the linked directory with its `.git` file, then the two pointers.

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

Read the three small files as a pair of pointers. The `.git` file in the linked working tree says where this worktree's private Git directory is. `gitdir` inside that directory points back at the working tree; that is how `git worktree list` and `git worktree prune` find out whether the working tree still exists. `commondir` contains two dots, slash, two dots: two levels up from the private directory is `.git`, the shared part.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch25/worktree-basics`. You are on `main`; `feature/rerank` exists and is not checked out anywhere.

```bash
git log --graph --oneline --decorate --all
git worktree add ../rag-api-rerank feature/rerank
git worktree list
```

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

"Preparing worktree (checking out 'feature/rerank')" is an ordinary checkout into another directory. No objects were copied. `git worktree list` prints one line per worktree: path, the commit its HEAD resolves to, and the branch in brackets. The main worktree is always first.

Predict: in the new directory, is `.git` a directory?

```bash
cat ../rag-api-rerank/.git
ls .git/worktrees/rag-api-rerank
```

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

A file, one line, beginning with `gitdir:`. And inside the repository, the private directory with `HEAD`, `index`, `logs`, `ORIG_HEAD`, `gitdir` and `commondir`. That is the diagram.

Now ask Git where things are, from inside the linked worktree.

```bash
git rev-parse --git-dir
git rev-parse --git-common-dir
git rev-parse --git-path HEAD --git-path index --git-path logs/HEAD --git-path ORIG_HEAD
```

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

The Git directory is the private one under `worktrees`. The common directory is the repository's `.git`. `HEAD`, `index`, `logs/HEAD` and `ORIG_HEAD` resolve into the private directory; the rest of the snippet shows the shared paths resolving into the common one. In a script, never build such a path by hand.

First consequence. Commit in the linked worktree, then look from the main one. Predict: do you need a fetch?

```bash
git commit -am "Document tie-breaking"
cd ../rag-api
git log --oneline -2 feature/rerank
git branch -v
```

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

No fetch, no push: the branch ref and the new objects are already here, because they are shared. In `git branch -v` the asterisk marks the branch checked out here and the plus sign marks a branch checked out in another worktree.

Second consequence: staging is private.

```bash
git add docs/deploy.md
git status --short --branch
git -C ../rag-api-rerank status --short --branch
```

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

A file staged in the main worktree does not appear in the status of the linked one. Two indexes.

And because root refs are per worktree, the name HEAD means something different in each directory. To name another worktree's HEAD, prefix it.

```bash
git log -1 --format="%h %s" main-worktree/HEAD
git log -1 --format="%h %s" worktrees/rag-api-rerank/HEAD
git -C ../rag-api-rerank log -1 --format="%h %s" main-worktree/HEAD
```

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

**[ON SCREEN]** The state table for `git worktree add ../rag-api-rerank feature/rerank`, run in the main worktree.

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged here; a new working tree is written at the given path | unchanged here; a new index is written in `.git/worktrees/<id>/` | unchanged here; the new worktree gets its own `HEAD` | unchanged | `.git/worktrees/<id>/` created; with `-b`, a new branch ref; no objects copied | unchanged | unchanged |

**[TERMINAL]** Replay `labs/run ch25/worktree-one-branch`. `main` is checked out in the main worktree and `feature/rerank` in the linked one. Try to break the rule.

```bash
git worktree add ../rag-api-second main
cd ../rag-api-rerank
git switch main
```

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

"'main' is already used by worktree at" and the path. Both ways are refused. The same rule protects a checked-out branch from being deleted or moved from elsewhere.

```bash
git branch -D feature/rerank
git branch -f feature/rerank main
```

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

The supported way to get the same files without the branch:

```bash
git worktree add --detach ../rag-api-readonly main
git worktree list
```

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

Two worktrees on commit `323e8f1`, one on the branch and one detached.

Now see once, in a sandbox, what the rule prevents. `--force` lets you build exactly that situation.

**[PAUSE]** You force a second checkout of `main`, then commit in the first worktree. Nobody touches the second. Predict what `git status` reports there.

```bash
git worktree add --force ../rag-api-dup main
git commit -am "Point the README at the deployment notes"
git -C ../rag-api-dup status
```

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

"Changes to be committed", in a directory nobody edited. Which changes?

```bash
git -C ../rag-api-dup diff --cached
```

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

The staged diff removes the lines that the latest commit added.

**[ON SCREEN]** The root-cause box of section 25.4.

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

A `git commit` in the stale worktree at this point would record the old tree on top of the new commit: a silent revert of a colleague's work, or your own. That is the failure the rule exists to prevent.

The repair. 🔴 DANGEROUS: `git reset --hard` overwrites the index and the working tree and destroys uncommitted changes to tracked files. Preview with `git status`. It is appropriate here because this worktree had no work of its own.

```bash
git -C ../rag-api-dup reset --hard
git -C ../rag-api-dup status --short --branch
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

## COMMON MISTAKES

1. **Expecting to fetch or push between two worktrees.** Root cause: objects and all refs under `refs/` are shared; a commit made in one exists in the other at once.
2. **Building a path such as `.git/index` by hand in a script that runs in a linked worktree.** Root cause: there `.git` is a file and the index lives under `.git/worktrees/<id>/`; `git rev-parse --git-path` gives the real location.
3. **`git worktree add --force` to get a second checkout of a branch.** Root cause: one ref and two indexes; a commit in one worktree leaves the other's index describing the old tree.
4. **Committing in the stale worktree.** Root cause: the index still holds the old tree, so the commit records the inverse of the commit that moved the branch.
5. **"The branch is not checked out anywhere, why can I not delete it?"** Root cause: a branch in the middle of a rebase or bisect in some worktree is in use by that worktree, although the list shows it as detached.

## PRODUCTION EXAMPLE

A model-evaluation job runs for forty minutes against the files of a release tag. With one working tree nobody can touch the repository until it finishes. With `git worktree add --detach ../rag-api-v1.3.0 v1.3.0` the job gets a directory of its own, and you keep working.

The same shape answers the team lead's question about four agents. Four linked worktrees, each on its own new branch, share one object database. Each agent has its own files, its own HEAD and its own index, and the one-branch rule guarantees that no two of them can move the same branch under each other. What they do share, and must be told about, is the subject of the next video.

## PRACTICE EXERCISE

Do Exercise 14.1, Level 1, "A second working tree for a hotfix", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Before you create the worktree, write down which files and directories will exist in the new directory and under `.git/worktrees` afterwards. After you commit in the new worktree, predict what `git branch -v` shows in the first one, including the markers, before you run it.

The challenge is Exercise 14.9, Level 4, "Two fixes in a worktree that no longer exists", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q95: "What exactly does `git worktree add` create on disk, in the new directory and in the repository?"

Pause and answer aloud.

A strong answer has two lists and keeps them apart: what appears in the new directory, including the nature of its `.git`, and what appears inside the repository, by file name. It explains the two small pointer files and what uses them. It says explicitly what is not created or copied. And it connects the layout to behavior: which state is therefore private, which is shared, and how you ask Git for the real path of a file instead of assuming it.

## RECAP

You should now be able to say:

- A linked worktree is a second working tree with its own HEAD, index and HEAD reflog, on the same objects and refs.
- Its `.git` is a file that points at `.git/worktrees/<id>/` in the repository.
- Refs under `refs/` are shared, with three exceptions; root refs such as HEAD are per worktree; `git rev-parse --git-path` tells me which is which.
- A branch can be checked out in one worktree only, because one ref with two indexes produces a silent revert.
- For the files of a branch that is in use elsewhere, I add a detached worktree or a new branch, never `--force`.

## HOMEWORK

Read sections 25.1 to 25.4 of [Chapter 25](../../textbook/ch25-worktrees.md).
