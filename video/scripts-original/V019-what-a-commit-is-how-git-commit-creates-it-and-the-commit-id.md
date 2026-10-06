# V019: What a commit is, how git commit creates it, and the commit ID

- **Part.** 1: Foundations
- **Module.** 3
- **Planned minutes.** 24
- **Prerequisites.** V008, V015
- **Textbook sections.** [Chapter 6: Commits](../../textbook/ch06-commits.md), sections 6.1 to 6.4 (with the reading commands of section 6.12)
- **Demo scripts.** `labs/ch06/commit-anatomy.sh`, `labs/ch06/inside-git.sh`, `labs/ch06/commit-id.sh`

## HOOK

**[ON SCREEN]** "Security reviewed commit X on Friday. Monday's build was made from commit Y. The diff between X and Y is empty. Did we deploy reviewed code or not?"

Your CTO asks: "Security reviewed commit X on Friday. Monday's build was made from commit Y. The diff between X and Y is empty. Did we deploy reviewed code or not?"

Two IDs. An empty diff between them. Both facts are true at the same time, and neither is a bug.

**[PAUSE]**

A commit ID is the hash of the whole commit object, and that object contains the moment the commit was created. An amend, a rebase or a cherry-pick writes a new object with the same content and a different ID. To answer the CTO you need to know exactly what is in a commit object, what `git commit` writes, and what the ID is computed from.

## INTRODUCTION

You have met commits twice: as one of four object types in V008, and as the thing the index turns into in V015. The next three videos are about the commit itself.

Hold on to one idea through all three: a commit is a small text object that never changes after it is written. Every command that seems to change one, amend, rebase, cherry-pick, sign, writes another object and moves a ref.

Today: the fields of a commit, the six steps of `git commit`, the files it touches under `.git`, and the commit ID computed by hand.

## LEARNING OBJECTIVES

After this video you can:

1. Read every field of a commit object.
2. List what `git commit` writes under `.git`, and what it leaves untouched.
3. Compute why a change to any field gives another commit ID.
4. State what a commit ID guarantees, and what it does not.

## CONCEPT

**What a commit is.** In one sentence: a commit is an immutable object that names one complete snapshot of the project, the commit or commits it was built on, who wrote the change and when, who created the commit and when, and a message.

The manual lists five required fields.

**[ON SCREEN]** The field table of section 6.2.

`tree`: the tree object of the top-level directory, the full snapshot. Exactly one.

`parent`: a commit this one was built on. None for a root commit, one for an ordinary commit, two or more for a merge.

`author`: name, email, time and time-zone offset of the person who wrote the change. One.

`committer`: the same for the person who created this commit object. One.

The message: free text after one empty line.

Optional headers can follow the committer line: `encoding`, and `gpgsig`, a signature. A commit holds no diff, no branch name and no file names.

Inside `.git`: one object per commit in the object database. Nothing else describes a commit. There is no table of commits and no per-branch list. A branch reaches its commits by following `parent` IDs from its tip.

**How `git commit` creates a commit.** In one sentence: `git commit` turns the index into tree objects, wraps the top tree in a new commit object whose parent is the current HEAD commit, and moves the current branch to that object. It is 🟢 SAFE.

Six steps, in the order in which their results depend on each other.

One, content: the index is the proposed snapshot.

Two, checks and message: the `pre-commit` hook runs before the message is obtained, and the `commit-msg` hook can reject the message. `--no-verify` skips both.

Three, trees: Git builds one tree per directory from the index entries. A tree that the object database already holds keeps its ID, and nothing new is stored. `git write-tree` performs this step alone.

Four, parent: the commit that HEAD resolves to becomes the parent. A first commit has none; a merge in progress adds the commits in `MERGE_HEAD`.

Five, the commit object: tree ID, parent IDs, author, committer and message are written as one object. Its hash is the commit ID.

Six, refs: the ref that HEAD names is set to the new ID, and the reflogs of HEAD and of the branch each gain a line.

**[ON SCREEN]** The state table of section 6.3: working tree unchanged; index entries unchanged, file rewritten; HEAD unchanged, resolves to the new commit; current branch ref set to the new commit; new tree and commit objects, one line in each reflog, `COMMIT_EDITMSG`; remote and GitHub unchanged. Second row: in detached HEAD, HEAD itself is set to the new commit ID, and no branch moves.

Nothing in a commit says which branch it is on. It goes wherever HEAD pointed when you ran the command.

**The commit ID.** In one sentence: a commit ID is the hash of the commit object, so one ID names the snapshot, the metadata and, through the parent IDs, the whole history behind the commit.

Precisely: Git hashes the bytes `commit`, a space, the size, one NUL byte, and the object content. With the default object format the hash is SHA-1 and the ID has 40 hexadecimal digits; a SHA-256 repository has 64.

Two properties follow. Same bytes, same ID, on any machine. The replays in this course pin the identity and the clock, which is the only reason your IDs can equal the printed ones. And any change, new ID. The `parent` line contains the parent's ID, so an ID depends on every ancestor. Nobody can alter an old commit without changing the ID of every commit after it.

**What the ID does not guarantee.** It says nothing about who really wrote the commit. Author and committer are assertions: `--author`, the configuration and the environment accept any text. Only a verified signature is evidence of who created a commit. And an ID names the commit, and nothing outside it: a run started from a working tree with uncommitted edits executed code that no commit ID describes.

**Abbreviated IDs.** Any unique prefix of at least four characters names an object. Git prints abbreviations whose length it computes from the size of the repository, seven characters in these sandboxes. A prefix that is unique today can become ambiguous later, so deploy records and model cards should store the full ID.

## MENTAL MODEL

The textbook's analogy: an entry in a ledger whose page numbers are computed from what is written on the page. Each entry points at a full inventory sheet, cites the page number of the entry before it, and names who did the work and who entered it. Change one character, and the page number changes.

Now apply it to the hook. Somebody rewrote the entry on Monday: same inventory sheet, same previous page, a new time of entry. The page number changed. The inventory did not.

The analogy breaks at the binding. A ledger is one sequence, while an entry in Git may cite two earlier entries, which is a merge, or none, which is a root.

## DIAGRAM

**[DIAGRAM]** The diagram of section 6.2. Draw the ref, then the commit box, then the tree, then the blob and the subtree.

```text
  refs/heads/main
        |
        v
  commit 51d62b3                       tree 0fbd18c                   blob 4793849
 +--------------------------+         +---------------------+        +------------------+
 | tree      0fbd18c -------|-------> | blob  README.md ----|------> | # evalkit ...    |
 | (no parent)              |         | tree  evalkit ------|---+    +------------------+
 | author    Lab User, time |         +---------------------+   |
 | committer Lab User, time |                                   |     tree bd12437
 |                          |                                   |    +------------------+
 | Add exact-match metric   |                                   +--> | blob metrics.py  |
 +--------------------------+                                        +------------------+
```

The ref points at the commit. The commit box lists its fields: one tree, no parent, an author with a time, a committer with a time, and the message. The tree arrow leads to the snapshot.

**[DIAGRAM]** The root-cause box of section 6.4, one line at a time, after the commit-ID demo.

```text
Observed behavior : the deployed commit is not the reviewed commit, yet git diff between the two is empty
Git state         : two commit objects with the same tree and the same parent; the branch points at the newer one
Mechanism         : an amend, a rebase or a cherry-pick wrote a new commit object with a new committer line
Root cause        : the commit ID is the hash of the commit object, and the committer time is part of that object
Why Git does this : an ID that covers every byte lets any two repositories agree on history by comparing IDs alone
Correct fix       : prove equal content with git rev-parse X^{tree} Y^{tree}; then move the branch back to X or re-approve Y
Prevention        : do not rewrite a commit after review or deployment; gate deploys on the approved ID, not on a branch name
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch06/commit-anatomy.sh`.

```bash
labs/run ch06/commit-anatomy
```

A new repository, `evalkit`, and its first commit. `git commit` 🟢 SAFE.

<!-- snippet: ch06/commit-anatomy/01-root-commit -->
```text
$ git init evalkit
Initialized empty Git repository in $LAB/ch06/commit-anatomy/evalkit/.git/
$ cd evalkit
$ git add README.md evalkit/metrics.py
$ git commit -m "Add exact-match metric"
[main (root-commit) 51d62b3] Add exact-match metric
 2 files changed, 5 insertions(+)
 create mode 100644 README.md
 create mode 100644 evalkit/metrics.py
```
<!-- /snippet -->

`(root-commit)` in the summary line says that this commit has no parent. Now the object itself.

<!-- snippet: ch06/commit-anatomy/02-object -->
```text
$ git cat-file -t HEAD
commit
$ git cat-file -p HEAD
tree 0fbd18cca19ea00c195639456eecd36debe578ab
author Lab User <you@example.com> 1788755700 +0530
committer Lab User <you@example.com> 1788755700 +0530

Add exact-match metric
$ git cat-file -p 'HEAD^{tree}'
100644 blob 4793849f9215e303b89dd4fb1ab163499fb69815	README.md
040000 tree bd12437744ea02734adf3138606ecfb4509b509f	evalkit
```
<!-- /snippet -->

`git cat-file -p` prints the object as stored. Read every field. The `tree` line names the snapshot, and `HEAD^{tree}` asks for that tree. There is no `parent` line. `author` and `committer` end with a time in seconds since 1 January 1970 UTC and an offset from UTC. One empty line separates headers and message.

Now a second commit, watched from the plumbing side. The script stages an edit and runs `git write-tree` before committing. Predict two things: which ID will appear on the new commit's `tree` line, and which on its `parent` line.

**[PAUSE]**

<!-- snippet: ch06/commit-anatomy/03-step-by-step -->
```text
# evalkit/metrics.py has been edited: it now also defines f1().
$ git add evalkit/metrics.py
$ git write-tree
27d56e4ea4080b5719bf97b9985f6f543eda349d
$ git rev-parse HEAD
51d62b3de231309f8aba10baba050cf2220fcc61
$ git commit -m "Add F1 metric"
[main 0d77920] Add F1 metric
 1 file changed, 9 insertions(+)
$ git cat-file -p HEAD
tree 27d56e4ea4080b5719bf97b9985f6f543eda349d
parent 51d62b3de231309f8aba10baba050cf2220fcc61
author Lab User <you@example.com> 1788756120 +0530
committer Lab User <you@example.com> 1788756120 +0530

Add F1 metric
```
<!-- /snippet -->

`git write-tree` printed `27d56e4`, and the new commit's `tree` line carries the same ID: the commit recorded the index. `git rev-parse HEAD` printed `51d62b3`, which is now the `parent` line.

<!-- snippet: ch06/commit-anatomy/04-what-moved -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ git rev-parse main
0d77920ea1ff22bc46fcaf5051fd6e5d86078a54
$ git reflog
0d77920 HEAD@{0}: commit: Add F1 metric
51d62b3 HEAD@{1}: commit (initial): Add exact-match metric
$ git reflog show main
0d77920 main@{0}: commit: Add F1 metric
51d62b3 main@{1}: commit (initial): Add exact-match metric
```
<!-- /snippet -->

`.git/HEAD` still holds the same text. The commit moved the branch, and HEAD follows only because it names the branch. Both reflogs gained an entry.

<!-- snippet: ch06/commit-anatomy/05-show-fuller -->
```text
$ git show --format=fuller --stat HEAD
commit 0d77920ea1ff22bc46fcaf5051fd6e5d86078a54
Author:     Lab User <you@example.com>
AuthorDate: Mon Sep 7 10:12:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:12:00 2026 +0530

    Add F1 metric

 evalkit/metrics.py | 9 +++++++++
 1 file changed, 9 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch06/commit-anatomy/06-show-raw -->
```text
$ git show --format=raw --no-patch HEAD
commit 0d77920ea1ff22bc46fcaf5051fd6e5d86078a54
tree 27d56e4ea4080b5719bf97b9985f6f543eda349d
parent 51d62b3de231309f8aba10baba050cf2220fcc61
author Lab User <you@example.com> 1788756120 +0530
committer Lab User <you@example.com> 1788756120 +0530

    Add F1 metric
```
<!-- /snippet -->

Two reading commands. `--format=fuller` shows both identities and both dates. `--format=raw --no-patch` shows the same headers as the stored object, with the ID in front and the message indented.

**[TERMINAL]** Caption bar: `labs/ch06/inside-git.sh`.

```bash
labs/run ch06/inside-git
```

A second sandbox with a similar edit. This time the script compares the object database before and after each command. Predict: which objects does `git add` write, and which does `git commit` write?

<!-- snippet: ch06/inside-git/01-add-writes-the-blob -->
```text
# evalkit/metrics.py has been edited: it now also defines f1().
$ objects() { git cat-file --batch-all-objects --batch-check | sort; }
$ objects > ../objects-before-add.txt
$ git add evalkit/metrics.py
$ objects | comm -13 ../objects-before-add.txt -
5ca6473ff5c0d818666928cda8551455b0794cd2 blob 154
```
<!-- /snippet -->

`git add` wrote the blob: the content is in the object database before any commit exists.

<!-- snippet: ch06/inside-git/02-commit-writes-trees-and-commit -->
```text
$ objects > ../objects-before-commit.txt
$ files() { find .git -type f -exec shasum {} + | sort; }
$ files > ../files-before-commit.txt
$ git commit -q -m "Add F1 metric"
$ objects | comm -13 ../objects-before-commit.txt -
1ed5d56b9ea6962262eb6c2e5634e45c7543b391 tree 38
29b018434273c541b9fce4dfc1e29fb92a358447 tree 71
529480e39c5092c92c130d091ce54617310747b7 commit 214
```
<!-- /snippet -->

The commit wrote three objects: a tree for `evalkit/`, a tree for the top level, and the commit. It wrote no blob, and the new top-level tree points at the `README.md` blob that the first commit already uses.

Now every file under `.git` that is new or changed by the commit. Predict whether `.git/HEAD` is in the list.

<!-- snippet: ch06/inside-git/03-files-touched -->
```text
# Every file under .git that is new, or whose content differs from the snapshot taken before the commit:
$ files | comm -13 ../files-before-commit.txt - | awk '{print $2}' | sort
.git/COMMIT_EDITMSG
.git/index
.git/logs/HEAD
.git/logs/refs/heads/main
.git/objects/1e/d5d56b9ea6962262eb6c2e5634e45c7543b391
.git/objects/29/b018434273c541b9fce4dfc1e29fb92a358447
.git/objects/52/9480e39c5092c92c130d091ce54617310747b7
.git/refs/heads/main
$ cat .git/COMMIT_EDITMSG
Add F1 metric
$ cat .git/HEAD
ref: refs/heads/main
```
<!-- /snippet -->

Eight files: three objects, the branch ref, two reflogs, the index, with the same entries and refreshed bookkeeping, and `COMMIT_EDITMSG` with the last message. `.git/HEAD` is not in the list.

**[TERMINAL]** Caption bar: `labs/ch06/commit-id.sh`.

```bash
labs/run ch06/commit-id
```

Compute an ID by hand, then let Git confirm it.

<!-- snippet: ch06/commit-id/01-hash-by-hand -->
```text
$ git rev-parse HEAD
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
$ git cat-file -s HEAD
214
$ (printf 'commit %s\0' "$(git cat-file -s HEAD)"; git cat-file commit HEAD) | shasum
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29  -
$ git cat-file commit HEAD | git hash-object -t commit --stdin
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
```
<!-- /snippet -->

Three lines print the same ID, `1f9c5d8`: `git rev-parse HEAD`; then `shasum` over the word `commit`, the size, a NUL byte and the content; then `git hash-object -t commit --stdin`, which hashes the text the way `git commit` does. There is no secret ingredient.

<!-- snippet: ch06/commit-id/02-same-inputs -->
```text
$ git cat-file -p HEAD
tree 29b018434273c541b9fce4dfc1e29fb92a358447
parent d4c9fabe9326ab4edbe04ed3a6f5f0b001bf6d86
author Lab User <you@example.com> 1788755640 +0530
committer Lab User <you@example.com> 1788755640 +0530

Add F1 metric
$ mk() { GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$2" git commit-tree -p "$3" -m "$4" "$5"; }
$ T='@1788755640 +0530'
$ mk "$T" "$T" HEAD~1 'Add F1 metric' 'HEAD^{tree}'
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
```
<!-- /snippet -->

Rebuild the same commit from its parts with `git commit-tree` 🟢 SAFE, which adds one commit object and moves no ref. Identical inputs gave `1f9c5d8` again.

Now change one input at a time. Before each line, say whether the ID will change.

**[PAUSE]**

<!-- snippet: ch06/commit-id/03-one-field-changes -->
```text
# Each call changes exactly one input of the call above.
$ mk "$T" "$T" HEAD~1 'Add F1 metric.' 'HEAD^{tree}'                 # message: one more character
f22660f55b1a794df68ae4053dcaa8248a3d8636
$ mk '@1788755641 +0530' "$T" HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # author date: one second later
6ace11eacd33eda2b2c22c2f05b3a30a0f94ac63
$ mk "$T" '@1788755641 +0530' HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # committer date: one second later
8d3a6660cc08d014e4d3eb108aa22364504ecb86
$ mk '@1788755640 +0000' "$T" HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # author time zone: same instant, other offset
1a5c7c949d901b1455717b67cb1fad6b9e7e0c49
$ mk "$T" "$T" HEAD 'Add F1 metric' 'HEAD^{tree}'                    # parent: HEAD instead of HEAD~1
5be2270d868fdb4922293b1051405f2c660f5756
$ mk "$T" "$T" HEAD~1 'Add F1 metric' 'HEAD~1^{tree}'                # tree: the previous snapshot
097a2da44a07874ffc33633728cb207e29e89358
$ GIT_AUTHOR_EMAIL=You@example.com mk "$T" "$T" HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # author email: capital Y
b96c648475d2e36d3c55883a81e1473b2868e4fd
```
<!-- /snippet -->

Seven changes, seven new IDs. One more character in the message. One second on the author date. One second on the committer date is enough. The same instant with another offset is a different commit, because the offset is part of the text. So is a capital letter in an email address.

**[DIAGRAM]** Show the root-cause box. That is the answer to the CTO: prove equal content by comparing the two tree IDs; then either move the branch back to the reviewed commit, or have the new one approved.

## COMMON MISTAKES

1. **Saying "I only fixed the message, the code is the same commit".** Root cause: the message is part of the commit object, and the ID is the hash of that object; it is the same tree and a different commit.
2. **Concluding from two different IDs that the code differs.** Root cause: the ID covers metadata too; compare `X^{tree}` and `Y^{tree}` to compare content.
3. **Expecting `.git/HEAD` to change on a commit.** Root cause: the commit sets the ref that HEAD names; HEAD itself still holds the branch name.
4. **Committing on the wrong branch, or on none.** Root cause: nothing in a commit says which branch it is on; it goes wherever HEAD pointed, so check `git status` before you commit, not after.
5. **Storing abbreviated IDs in deploy records.** Root cause: a prefix that is unique today can become ambiguous later.

## PRODUCTION EXAMPLE

An evaluation run is tracked with the commit ID of the code. The textbook's warning: a commit ID in a deploy record or an evaluation report identifies the code exactly, and nothing outside the commit. A run started from a working tree with uncommitted edits executed code that no commit ID describes, and trackers may not notice: the textbook cites MLflow's classic run context, which records the commit and does not inspect uncommitted changes. The remedy it gives: record `git rev-parse HEAD` together with `git status --porcelain`, or refuse a tracked run when that output is not empty.

And for deployments, the prevention line of the root-cause box: gate deploys on the approved ID, not on a branch name.

## PRACTICE EXERCISE

Do Exercise 3.1, Level 1, "read a commit field by field", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Before you print the object, write down the fields you expect, in order, and for each one say whether it would differ if the same change were committed one minute later.

## INTERVIEW QUESTION

Q8: "What exactly does `git commit` write inside `.git`, and what does it leave untouched?"

Answer aloud. A strong answer lists objects, refs and other files separately, says which objects are not written because they already exist, and names the file that people expect to change and that does not. Mention the case in which the list is different because no branch is current.

## RECAP

You should now be able to say: a commit object has a tree, zero or more parents, an author, a committer and a message, and holds no diff, no branch name and no file names. `git commit` writes trees from the index, writes the commit with HEAD's commit as parent, moves the current branch and appends to two reflogs; it does not touch `.git/HEAD` or the working tree. The commit ID is a hash over all of the object, parents included, so it fixes the whole history behind it, and any change to any field gives another ID. It guarantees content and history; it does not prove who wrote the commit.

## HOMEWORK

- Read sections 6.1 to 6.4 of [Chapter 6](../../textbook/ch06-commits.md).
- Do Lab 3.2, "Change only the committer date and watch the ID change", in [`lab-manual/m03-commits.md`](../../lab-manual/m03-commits.md).
- Challenge: Exercise 3.7, Level 3, "one ahead, one behind, and nobody else pushed", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
