# V010: Three trees, two views of a commit, and the wrong mental models

- **Part.** 1: Foundations
- **Module.** 1
- **Planned minutes.** 20
- **Prerequisites.** V009
- **Textbook sections.** [Chapter 2: The Mental Model](../../textbook/ch02-mental-model.md), sections 2.9 to 2.15
- **Demo scripts.** `labs/ch02/three-trees.sh`, `labs/ch02/two-views.sh`, `labs/ch02/what-travels.sh`

## HOOK

**[ON SCREEN]** Two commit IDs: `cf6a5b3` on `main`, `e460212` on `release/1.0`.

The same fix is on `main` as `cf6a5b3` and on the release branch as `e460212`. Your CTO asks: is that one fix, or two different things?

If a commit is a diff, they are the same thing and should have the same ID. They do not. If a commit is a snapshot, they are different things. But they have the same message, the same author date, and they change the same line.

**[PAUSE]**

Both halves are true, and you need to know which half each command uses. In this video you put the model together, and then you use it to take apart four wrong models that most confusion about Git comes from.

## INTRODUCTION

This is the last video of the object model. It has three parts.

First, the three trees: a preview of the next block of the course, in which a file exists in three states at the same time. Second, the two views of a commit: snapshot and change. Third, the map of what lives where: your laptop, the server, and a colleague's clone, with one rule for what can cross between repositories at all.

Along the way we refute four wrong models with a transcript each: Git stores diffs, a branch is a copy, a commit belongs to a branch, and GitHub is Git.

## LEARNING OBJECTIVES

After this video you can:

1. Name the three trees, and say which command compares which pair.
2. Explain how a commit can be read as a snapshot and as a change without contradiction.
3. Refute four common wrong models of Git with a transcript each.
4. Say which parts of a repository travel to the server on a push, and which never do.

## CONCEPT

**The three trees.** In one sentence: a file can exist in three states at the same time, in the commit that HEAD names, in the index and in the working tree, and `git status` reports the differences between them.

Precisely. "Tree" here means a complete set of files, not a tree object. The commit that HEAD names is the last snapshot. The index is the proposed next snapshot: every tracked path with the ID of a blob. The working tree is the files on disk. `git add` copies content from the working tree into the index, and `git commit` turns the index into tree objects and a commit.

Two commands compare neighbouring pairs. `git diff --cached` compares HEAD with the index. `git diff` compares the index with the working tree. Neither shows the whole distance from HEAD to the working tree; `git diff HEAD` does.

**Two views of a commit.** "A commit is a diff" is wrong as a statement about storage, and right as a way to read history. You need both views, and you need to know which one a command uses.

**[ON SCREEN]** The two-row table of section 2.10.

The snapshot view: the tree that the commit records. It is used by checkout, by builds, by `git ls-tree`, by `git diff A B`, and by merge, which works on three snapshots.

The change view: the difference between the commit's tree and its parent's, computed on demand. It is used by `git show`, by `git log -p`, by cherry-pick, by rebase and by revert.

Take cherry-pick as the test case. The manual describes it in the change view: it applies the change that a commit introduces and records a new commit. The implementation is a three-way merge whose base is the parent of the picked commit, so it works on three snapshots. Rebase repeats this for a series of commits; revert applies the inverse change. The result is always a new commit with a new ID. `git cherry-pick` carries the label 🟡 CAUTION: it adds one commit to the current branch, which moves it, and updates the index and the working tree.

**The wrong models.** The textbook's table has eleven rows; here are the four this video proves, each with its reality.

Wrong: a commit stores a diff. Reality: a commit records a full snapshot, the ID of the top-level tree, with its parents, author, committer and message; diffs are computed on demand. You saw the proof in V007.

Wrong: a branch is a copy of the code, with a parent branch. Reality: a branch is a ref that names one commit, and Git has no notion of a parent branch. You saw the proof in V009: creating a branch added no object.

Wrong: a commit belongs to a branch. Reality: "the commits on a branch" is the set reachable from the commit the branch names; one commit can be reachable from many refs or from none. You saw both in V009.

Wrong: GitHub is Git; in particular, a pull request is a Git feature. Reality: it is a GitHub object. Today's last demo shows what a clone carries and what it does not.

The textbook adds a number so that you do not think these are beginner errors. In a poll of 2,466 mostly professional developers, 50% think of a commit as a diff and 42% as a snapshot; the textbook notes that this is a self-selected sample. Each group holds half of the model. And in the same polls, only 10% of respondents were fully confident that they understood HEAD.

**What travels.** One rule: a push or a fetch transfers objects and updates refs; nothing else in `.git` leaves your machine. Not the index, not the reflogs, not `.git/config`, not the working tree.

## MENTAL MODEL

Hold three pictures, one for each part.

Three boxes in a row: HEAD, index, working tree. Two comparisons between neighbours. `git status` is those two comparisons, summarized.

One commit, two readings. As a photograph, it is what a build contains. As a difference from its parent, it is what a cherry-pick carries over. The photograph is stored; the difference is computed.

Two repositories and a wire. Only objects and refs cross the wire.

Where does this break? The third picture shows only the Git layer of the server. GitHub has two more layers that no wire to your clone carries at all: the platform's database, and GitHub Actions. And the first picture is a preview: the index has more in it than one blob per path, and the next block of videos opens it.

## DIAGRAM

**[DIAGRAM]** The diagram of section 2.9.

```text
  HEAD (last commit)          Index (next commit)         Working tree (files on disk)
 +---------------------+     +---------------------+     +-----------------------+
 | rules.txt  bfb2990  |     | rules.txt  298e6b4  |     | rules.txt             |
 |   lowercase         |     |   lowercase         |     |   lowercase           |
 |                     |     |   strip accents     |     |   strip accents       |
 |                     |     |                     |     |   collapse whitespace |
 +---------------------+     +---------------------+     +-----------------------+
            |<-- git diff --cached -->|     |<--------- git diff --------->|
            "Changes to be committed"       "Changes not staged for commit"
```

Three boxes, one file, three versions: one line, two lines, three lines. Under the boxes, the two comparisons, each with the heading that `git status` gives it. A commit made now would record the middle version: the index, not the file on disk. That is the mechanism behind the worked example of V006.

**[DIAGRAM]** The diagram of section 2.10.

```text
              92b1ad4---cf6a5b3     main          workers: 4, retries: 3
             /
 68dcb3b----+
             \
              e460212               release/1.0   workers: 2, retries: 3     (HEAD -> release/1.0)

 change of cf6a5b3 = change of e460212 = "retries: 1 becomes 3"; their snapshots differ
```

**[DIAGRAM]** The diagram of section 2.12. Draw your clone, then the Git layer of GitHub, then the wire, then the two lower boxes.

```text
 Your clone                                              GitHub
+--------------------------------------------+        +-----------------------------------------------+
| working tree   the files you edit          |        | Git layer: a bare repository                  |
| .git/index     the next snapshot           |  push  |   objects   commits, trees, blobs, tags       |
| .git/objects   commits, trees, blobs, tags | -----> |   refs      refs/heads/*, refs/tags/*, and    |
| .git/refs      branches, tags,             | <----- |             refs/pull/* written by GitHub     |
|                remote-tracking branches    |  fetch |   no working tree, no index, not your reflogs |
| .git/HEAD      the current branch          |        +-----------------------------------------------+
| .git/logs      reflogs                     |        | Platform layer: GitHub's database             |
| .git/config    local settings              |        |   accounts, permissions, pull requests,       |
+--------------------------------------------+        |   reviews, issues, rulesets, releases         |
   only objects and refs cross the wire               +-----------------------------------------------+
                                                      | GitHub Actions                                |
                                                      |   workflow runs, logs, artifacts, secrets     |
                                                      +-----------------------------------------------+
```

**[ON SCREEN]** Lower third: **GitHub**. The two lower boxes exist only in GitHub's systems. A pull request, for example, is a database record plus read-only refs under `refs/pull/` that GitHub maintains on the server, as described in GitHub's documentation. A clone copies none of it, and deleting your clone loses none of it.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch02/three-trees.sh`.

```bash
labs/run ch02/three-trees
```

One file is committed, then changed and staged, then changed again. Predict how many versions of `rules.txt` exist at once, and where each is.

<!-- snippet: ch02/three-trees/01-three-versions -->
```text
$ printf 'lowercase\nstrip accents\n' > rules.txt
$ git add rules.txt
$ printf 'lowercase\nstrip accents\ncollapse whitespace\n' > rules.txt
$ git show HEAD:rules.txt
lowercase
$ git show :rules.txt
lowercase
strip accents
$ cat rules.txt
lowercase
strip accents
collapse whitespace
```
<!-- /snippet -->

`git show HEAD:rules.txt` prints the committed version. `git show :rules.txt`, with a colon and no commit, prints the version in the index. `cat` prints the file on disk. Three versions exist at once.

<!-- snippet: ch02/three-trees/02-status -->
```text
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   rules.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   rules.txt
```
<!-- /snippet -->

The file is listed twice, once for each comparison.

<!-- snippet: ch02/three-trees/03-two-diffs -->
```text
$ git diff --cached
diff --git a/rules.txt b/rules.txt
index bfb2990..298e6b4 100644
--- a/rules.txt
+++ b/rules.txt
@@ -1 +1,2 @@
 lowercase
+strip accents
$ git diff
diff --git a/rules.txt b/rules.txt
index 298e6b4..969b4fa 100644
--- a/rules.txt
+++ b/rules.txt
@@ -1,2 +1,3 @@
 lowercase
 strip accents
+collapse whitespace
```
<!-- /snippet -->

`git diff --cached`: HEAD against the index, one added line. `git diff`: index against working tree, another added line. Read the `index` lines of the two diffs: `bfb2990..298e6b4`, then `298e6b4..969b4fa`. The blob in the middle is the same. It is the index.

**[TERMINAL]** Caption bar: `labs/ch02/two-views.sh`.

```bash
labs/run ch02/two-views
```

`main` is two commits ahead of `release/1.0`.

<!-- snippet: ch02/two-views/01-before -->
```text
$ git log --graph --decorate --oneline --all
* cf6a5b3 (HEAD -> main) Retry failed calls three times
* 92b1ad4 Run four workers
* 68dcb3b (release/1.0) Add client and server settings
$ git show --stat --format="%h %s" main
cf6a5b3 Retry failed calls three times

 client.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

The last commit on `main`, `cf6a5b3`, changes one line in `client.yaml`. The commit before it, "Run four workers", is not wanted on the release branch. `git cherry-pick` 🟡 CAUTION copies the last commit onto the release branch. Predict: will the new commit have the same ID as the original?

<!-- snippet: ch02/two-views/02-cherry-pick -->
```text
$ git switch release/1.0
Switched to branch 'release/1.0'
$ git cherry-pick main
[release/1.0 e460212] Retry failed calls three times
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --graph --decorate --oneline --all
* e460212 (HEAD -> release/1.0) Retry failed calls three times
| * cf6a5b3 (main) Retry failed calls three times
| * 92b1ad4 Run four workers
|/  
* 68dcb3b Add client and server settings
```
<!-- /snippet -->

A new commit, `e460212`, with the same message. The `Date:` line is the author date, which a cherry-pick takes over from the original.

Now the question that separates the two views. Predict: is the snapshot of `release/1.0` now equal to the snapshot of `main`?

**[PAUSE]**

<!-- snippet: ch02/two-views/03-snapshots-differ -->
```text
$ git ls-tree main
100644 blob efc3dd6049f31961d7de37bf366cbe5552aee146	client.yaml
100644 blob d333cab4da5c3a4c1f455a8626c14aa1a1647aca	server.yaml
$ git ls-tree release/1.0
100644 blob efc3dd6049f31961d7de37bf366cbe5552aee146	client.yaml
100644 blob c44fe52484fbfa487bfb4b29c7b91e44fd76022e	server.yaml
```
<!-- /snippet -->

The snapshots differ. Both contain the new `client.yaml`, blob `efc3dd6`. But `server.yaml` is `d333cab` on `main` and `c44fe52` on the release branch, which never received the commit "Run four workers". Had cherry-pick copied the snapshot, the release would now run four workers.

<!-- snippet: ch02/two-views/04-change-is-the-same -->
```text
$ git show --stat --format="%h %s" release/1.0
e460212 Retry failed calls three times

 client.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show main | git patch-id --stable
22602bf345cdd3c410ce2340ba3477e68e08f9a2 cf6a5b3ed8609aa40fd89ecc364a90e59d07d6fb
$ git show release/1.0 | git patch-id --stable
22602bf345cdd3c410ce2340ba3477e68e08f9a2 e4602121961240cdf7e21b59834c799639f5c253
```
<!-- /snippet -->

And the change is the same. `git patch-id` reduces a diff to an ID that ignores line numbers and whitespace, and both commits give the same first column, beginning `22602bf`. Same change, different snapshot, different parent, different commit ID. That is the answer to the CTO's question.

**[TERMINAL]** Caption bar: `labs/ch02/what-travels.sh`.

```bash
labs/run ch02/what-travels
```

A bare repository on disk plays the Git layer of the server. Your clone has one commit, a second branch `wip/unicode`, a staged change, and an alias `st` in its `.git/config`. `git push` is 🟡 CAUTION.

<!-- snippet: ch02/what-travels/01-laptop -->
```text
# Your clone: one commit, a second branch, one staged change, one alias in .git/config.
$ git st
## main
M  rules.txt
$ git push -u origin main
To ../hub.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
$ git for-each-ref
c0c5420b9f771c668129cf6f5a885ab951d15263 commit	refs/heads/main
c0c5420b9f771c668129cf6f5a885ab951d15263 commit	refs/heads/wip/unicode
c0c5420b9f771c668129cf6f5a885ab951d15263 commit	refs/remotes/origin/main
$ git cat-file --batch-all-objects --batch-check
298e6b4d3fbad90aacecaf555620943c308cd90a blob 24
3a19f43c4181bfd7a3b52b74fbb1b1079e9c2bac tree 37
bfb2990471be330c8cdd6365bd10b4d3fac0ddbc blob 10
c0c5420b9f771c668129cf6f5a885ab951d15263 commit 171
```
<!-- /snippet -->

Four objects exist locally: the commit, its tree, the committed blob, and the blob of the staged change, `298e6b4`. Predict what the server has: how many objects, how many refs, and which files.

**[PAUSE]**

<!-- snippet: ch02/what-travels/02-server -->
```text
$ cd ../hub.git
$ find . -type f -not -path './hooks/*' | sort
./config
./description
./HEAD
./info/exclude
./objects/3a/19f43c4181bfd7a3b52b74fbb1b1079e9c2bac
./objects/bf/b2990471be330c8cdd6365bd10b4d3fac0ddbc
./objects/c0/c5420b9f771c668129cf6f5a885ab951d15263
./refs/heads/main
$ git for-each-ref
c0c5420b9f771c668129cf6f5a885ab951d15263 commit	refs/heads/main
$ git cat-file --batch-all-objects --batch-check
3a19f43c4181bfd7a3b52b74fbb1b1079e9c2bac tree 37
bfb2990471be330c8cdd6365bd10b4d3fac0ddbc blob 10
c0c5420b9f771c668129cf6f5a885ab951d15263 commit 171
$ git status
fatal: this operation must be run in a work tree
[exit status: 128]
```
<!-- /snippet -->

The server received three objects and one ref. The staged blob is absent, because no pushed commit refers to it. The branch `wip/unicode` is absent, because it was not pushed. There is no index, no `logs/` directory and no working tree, so `git status` cannot run.

<!-- snippet: ch02/what-travels/03-clone -->
```text
$ cd ..
$ git clone -q hub.git colleague
$ cd colleague
$ git for-each-ref
c0c5420b9f771c668129cf6f5a885ab951d15263 commit	refs/heads/main
c0c5420b9f771c668129cf6f5a885ab951d15263 commit	refs/remotes/origin/HEAD
c0c5420b9f771c668129cf6f5a885ab951d15263 commit	refs/remotes/origin/main
$ git reflog
c0c5420 HEAD@{0}: clone: from $LAB/ch02/what-travels/hub.git
$ git st
git: 'st' is not a git command. See 'git --help'.

The most similar commands are
	status
	reset
	stage
	stash
[exit status: 1]
```
<!-- /snippet -->

A colleague's clone. `git clone` is 🟢 SAFE. It has the server's branch as the remote-tracking branch `refs/remotes/origin/main`, and Git created a local `main` from it. The reflog begins with the clone. And the alias is unknown. Your reflogs and your `.git/config` stayed with you.

## COMMON MISTAKES

1. **Expecting a cherry-picked commit to have the original's ID.** Root cause: the commit ID is computed from the tree and the parent as well; the same change on another parent is another snapshot and another commit.
2. **Reading only `git diff` and missing what is staged.** Root cause: it compares the index with the working tree; `git diff --cached` compares HEAD with the index, and `git diff HEAD` covers the whole distance.
3. **Counting on the reflog to recover something on the server or in another clone.** Root cause: reflogs are local and are not shared with remotes; bare repositories keep none by default.
4. **Believing that a staged secret never left a trace because it was never committed.** Root cause: `git add` stores content at once; the blob is an object in `.git/objects` until garbage collection removes it.
5. **Treating `origin/main` as the branch on the server.** Root cause: a remote-tracking branch records the last-known state of the remote branch, as of the last fetch.

## PRODUCTION EXAMPLE

An inference team maintains a release branch that must not receive a capacity change made on `main`. A fix to the client's retry count lands on `main` after that capacity change. The team cherry-picks the fix. The change view tells them what the cherry-pick will carry over: one line in `client.yaml`. The snapshot view tells them what the release build will contain afterwards: the retry fix, and still two workers. An engineer who holds only the diff model cannot explain why the two commits have different IDs; one who holds only the snapshot model fears that the release now contains everything `main` has.

And the sentence from the textbook for incident channels: "It is on GitHub" translates to: which objects were pushed, and which ref on the server points at them? "GitHub shows X" raises the question whether X is Git data that any clone would show, or a platform record.

## PRACTICE EXERCISE

Do Exercise 1.1, Level 1, "one commit, three object types", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Before you open any object, write down how many objects of each type the one commit will have created, and which of them hold the file names.

## INTERVIEW QUESTION

Q21: "Which parts of `.git` reach the server when you push, and which never do? What does GitHub hold that no clone contains?"

Answer aloud. A strong answer states the rule for what crosses between repositories in one sentence, then goes through `.git` entry by entry and sorts each one. For the second half it names the layers on the GitHub side and gives examples from each, and it mentions the refs that GitHub itself writes on the server.

## RECAP

You should now be able to say: a file can be in three states at once, in HEAD's commit, in the index and in the working tree; `git diff --cached` compares the first pair and `git diff` the second. A commit is stored as a snapshot and can be read as a change against its parent; checkout, builds and merge use the snapshot, and show, cherry-pick, rebase and revert use the change. A cherry-pick makes a new commit with the same change and a different snapshot. A push or a fetch transfers objects and updates refs, and nothing else in `.git` leaves my machine. Pull requests, reviews and workflow runs are GitHub records that no clone contains.

## HOMEWORK

- Read sections 2.9 to 2.15 of [Chapter 2](../../textbook/ch02-mental-model.md), and do the Practice section 2.17.
- Challenge: Exercise 1.5, Level 2, "add twice, commit once", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
