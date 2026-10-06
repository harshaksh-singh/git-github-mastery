# V022: A branch is a ref, HEAD is a symbolic ref, and what a commit does to the current branch

- **Part.** 1: Foundations
- **Module.** 4
- **Planned minutes.** 22
- **Prerequisites.** V009, V019
- **Textbook sections.** [Chapter 7: Branches](../../textbook/ch07-branches.md), sections 7.1 to 7.4
- **Demo scripts.** `labs/ch07/branch-is-a-ref.sh`, `labs/ch07/head-symref.sh`, `labs/ch07/commit-moves-branch.sh`

## HOOK

**[ON SCREEN]** "We have 340 branches on the server. Which ones can be deleted without losing anything?"

Your CTO asks: "We have 340 branches on the server. Which ones can be deleted without losing anything?"

To answer, you have to know what would be deleted. If a branch is a copy of the code, deleting one deletes code. If a branch is the set of commits that branched off, deleting one deletes commits.

**[PAUSE]**

It is neither. The polls in the course's research report found that 58 percent of practising developers think of a branch as the commits that branched off, and 15 percent as a pointer. The second group is right, in a way that decides outcomes. A branch is one line of text: a name and the ID of one commit. Everything in the next five videos follows from that fact.

## INTRODUCTION

This block of five videos is about refs: branches, HEAD, tags, and the relations between them. The textbook opens the chapter with three CTO questions: the 340 branches; a contractor whose two days of work vanished after she checked out a tag; and every laptop failing with `cannot lock ref` since this morning. All three are questions about refs, and none has a Git command as its answer.

Today we establish the three facts under all of it. A branch is a ref. HEAD is a symbolic ref. And a commit writes one ref: the one that HEAD names.

## LEARNING OBJECTIVES

After this video you can:

1. Define a branch in one sentence without "copy", and prove the sentence from `.git`.
2. Create, read and delete a branch with plumbing, and compare with porcelain.
3. Describe the three contents of `.git/HEAD`: on a branch, detached, unborn.
4. Trace the two ref writes of one commit.

## CONCEPT

**A branch is a ref.** In one sentence: a branch is a ref, a name under `refs/heads/` that holds the ID of one commit, the tip; the branch's history is whatever that commit reaches through its parents.

Precisely, from the glossary: a branch head is "a named reference to the commit at the tip of a branch", stored "in a file in $GIT_DIR/refs/heads/ directory, except when using packed refs". The ref holds nothing but the ID. There is no list of the branch's commits, no record of where it started, no owner, no creation date. `git log feature` is a walk that starts at the ID in the ref and follows `parent` lines.

**Inside `.git`.** With the files backend, which Git 2.55 uses by default, a loose branch is the file `.git/refs/heads/<name>`, containing the ID and a newline. Packed refs move the same information into lines of `.git/packed-refs`. The reftable backend keeps refs in a binary store. The reflog of a branch lives in `.git/logs/refs/heads/<name>`.

That is why plumbing is the reliable reader. A script that reads `.git/refs/heads/main` breaks on the first packed repository, and on every reftable repository.

**Creating a branch by plumbing.** `git update-ref` writes a ref. It is 🟡 CAUTION. It makes two checks that porcelain also relies on: the object must exist, and a ref under `refs/heads/` must name a commit. Writing the file by hand bypasses both checks, the locking and the reflog; the textbook labels hand-written ref files 🔴 DANGEROUS. `git update-ref -d` deletes a ref together with its reflog, with no merge check, and is 🔴 DANGEROUS: what it can destroy is the only name of those commits; the preview is `git rev-parse` on the ref, writing the ID down; the recovery is to recreate the ref from that ID; and it is appropriate for refs you created yourself, as in today's demo.

**HEAD is a symbolic ref.** In one sentence: HEAD is the ref that says where you are: normally a symbolic ref that names the current branch, and in detached state a direct reference to a commit.

A symbolic ref is, in the manual's words, "a regular file that stores a string that begins with ref: refs/". When HEAD contains `ref: refs/heads/main`, every command that needs "the current commit" resolves HEAD to `refs/heads/main`, and then to the ID in that ref. HEAD is per worktree.

So `.git/HEAD` has three possible contents. On a branch: the name of a ref that exists. Detached: a commit ID. Unborn: the name of a ref that does not exist yet, as in a new repository before the first commit.

**What a commit does.** In one sentence: a commit writes the new commit's ID into the ref that HEAD names, and nothing else moves. `.git/HEAD` keeps its text. Other branches stay where they are. Two reflogs gain a line each: the branch's and HEAD's. Those are the two ref writes to trace.

**[ON SCREEN]** The state table of section 7.4: `git commit` on `feature/retry-backoff`: working tree and index unchanged; HEAD unchanged; current branch ref moves to the new commit; `main` unchanged; new objects; one line in each of two reflogs.

**When this matters.** Because a branch is a name for a commit, "the branch" has a different value in every repository that holds a copy of it: your clone, each colleague's clone, the server. `main` on the server and `main` in your clone are two refs that happen to share a name. A statement such as "the fix is on `main`" is only meaningful with a repository attached.

## MENTAL MODEL

The textbook's analogy: a bookmark in a book that is still being written. The bookmark marks one page. The chapters before that page are "the story so far", but they are the book's pages, not the bookmark's. Moving the bookmark changes nothing in the book, and two bookmarks can sit on the same page.

The analogy breaks at the edge: pages after a bookmark exist too, unless nothing points at them, and then Git may eventually throw them away.

Add HEAD to the picture: a slip of paper on your desk that says which bookmark you are using. When you write a new page, you move that bookmark forward. The slip on the desk still says the same thing.

## DIAGRAM

**[DIAGRAM]** The diagram of section 7.2.

```text
  .git/refs/heads/main                   -----> 7aecf06 "Add batch runner"
  .git/refs/heads/feature/retry-backoff  -----> 7aecf06            |
  .git/refs/heads/hotfix/judge-timeout   -----> 69d8252 "Add exact-match metric"
                                                                   |
                                                  6eab4a9 "Add README"
```

Three refs, three small files, one history. Two of the refs name the same commit. Creating the second and third branch wrote no commit, no tree and no blob.

**[DIAGRAM]** The diagram of section 7.4.

```text
  before:                                   after:
                 feature/retry-backoff                        feature/retry-backoff
                 main   (HEAD -> ...)                                 |
                   |                                                  v
  6eab4a9---23b0907                         6eab4a9---23b0907---f5192c8
                                                         ^
                                                         main
```

Before: two branch labels on one commit, HEAD attached to the feature label. After: one new commit; the feature label moved to it; `main` stayed.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch07/branch-is-a-ref.sh`.

```bash
labs/run ch07/branch-is-a-ref
```

Create a branch with porcelain. `git branch <name>` 🟢 SAFE: it adds a ref.

<!-- snippet: ch07/branch-is-a-ref/01-porcelain -->
```text
$ git log --oneline
7aecf06 Add batch runner
69d8252 Add exact-match metric
6eab4a9 Add README
$ git branch feature/retry-backoff
$ git branch -v
  feature/retry-backoff 7aecf06 Add batch runner
* main                  7aecf06 Add batch runner
```
<!-- /snippet -->

Predict what is in the file `.git/refs/heads/feature/retry-backoff`.

<!-- snippet: ch07/branch-is-a-ref/02-what-was-written -->
```text
$ cat .git/refs/heads/feature/retry-backoff
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f
$ git rev-parse feature/retry-backoff
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f
$ git for-each-ref refs/heads
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f commit	refs/heads/feature/retry-backoff
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f commit	refs/heads/main
$ git reflog show feature/retry-backoff
7aecf06 feature/retry-backoff@{0}: branch: Created from main
```
<!-- /snippet -->

The full ID of `7aecf06`, and nothing else. `git for-each-ref` is the plumbing listing: for every ref, the ID, the type of object it names, and the full ref name. Both branches name the same commit. The branch also received a reflog, whose first line records how it was created. That is the proof for the one-sentence definition: two commands, `cat` and `git rev-parse`, print the same forty digits.

Now plumbing. `git update-ref` 🟡 CAUTION.

<!-- snippet: ch07/branch-is-a-ref/03-plumbing -->
```text
$ git update-ref refs/heads/hotfix/judge-timeout HEAD~1
$ git branch -v
  feature/retry-backoff 7aecf06 Add batch runner
  hotfix/judge-timeout  69d8252 Add exact-match metric
* main                  7aecf06 Add batch runner
$ git update-ref refs/heads/typo 1234567890123456789012345678901234567890
fatal: update_ref failed for ref 'refs/heads/typo': trying to write ref 'refs/heads/typo' with nonexistent object 1234567890123456789012345678901234567890
[exit status: 128]
$ git update-ref refs/heads/not-a-commit 'HEAD^{tree}'
fatal: update_ref failed for ref 'refs/heads/not-a-commit': trying to write non-commit object 416a81e352e688b7791f11f2e8159ea3be84dd9c to branch 'refs/heads/not-a-commit'
[exit status: 128]
```
<!-- /snippet -->

A third branch, created without `git branch`. And the two checks: an ID that names no object is refused, and so is an object that is not a commit.

<!-- snippet: ch07/branch-is-a-ref/04-by-hand -->
```text
$ git rev-parse HEAD~2 > .git/refs/heads/by-hand
$ git branch -v
  by-hand               6eab4a9 Add README
  feature/retry-backoff 7aecf06 Add batch runner
  hotfix/judge-timeout  69d8252 Add exact-match metric
* main                  7aecf06 Add batch runner
$ git reflog show by-hand
$ git update-ref -d refs/heads/by-hand
$ git branch --list by-hand
```
<!-- /snippet -->

Writing the file by hand works, and is the thing not to do: `git branch -v` reads the hand-written file like any other, but `git reflog show by-hand` is empty. No Git command wrote this ref, so nothing logged it. `git update-ref -d` 🔴 DANGEROUS deletes it; the five questions were answered a moment ago, and this ref is one the script created itself.

Now the reason to read refs with plumbing and never by path. Predict what `cat .git/refs/heads/main` prints after `git pack-refs --all`.

**[PAUSE]**

<!-- snippet: ch07/branch-is-a-ref/05-packed -->
```text
$ git pack-refs --all
$ cat .git/refs/heads/main
cat: .git/refs/heads/main: No such file or directory
[exit status: 1]
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f refs/heads/feature/retry-backoff
69d82526af97115a79ad14d198c1ba24c22d5fb9 refs/heads/hotfix/judge-timeout
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f refs/heads/main
$ git rev-parse main
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f
```
<!-- /snippet -->

The loose file is gone, and the ref lives in `packed-refs`. `git rev-parse main` does not care: the branch still resolves.

**[TERMINAL]** Caption bar: `labs/ch07/head-symref.sh`.

```bash
labs/run ch07/head-symref
```

<!-- snippet: ch07/head-symref/01-read -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ git symbolic-ref HEAD
refs/heads/main
$ git symbolic-ref --short HEAD
main
$ git branch --show-current
main
$ git rev-parse --abbrev-ref HEAD
main
$ git rev-parse HEAD
69d82526af97115a79ad14d198c1ba24c22d5fb9
```
<!-- /snippet -->

Four ways to read HEAD, from raw to friendly.

<!-- snippet: ch07/head-symref/02-unborn -->
```text
$ git init -q ../scratch
$ cat ../scratch/.git/HEAD
ref: refs/heads/main
$ git -C ../scratch rev-parse --verify HEAD
fatal: Needed a single revision
[exit status: 128]
$ git -C ../scratch branch
$ git -C ../scratch status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
$ git -C ../scratch branch feature
fatal: not a valid object name: 'main'
[exit status: 128]
```
<!-- /snippet -->

A new repository: HEAD points at `refs/heads/main`, but no such ref exists until the first commit writes it. `git rev-parse --verify HEAD` fails, `git branch` lists nothing, and `git branch feature` fails, because there is no commit to point the new branch at.

Now move HEAD alone, with `git symbolic-ref HEAD <ref>` 🟡 CAUTION. It rewrites one file. Predict what `git status` reports.

<!-- snippet: ch07/head-symref/03-head-only -->
```text
$ git symbolic-ref HEAD refs/heads/feature/retry-backoff
$ git status
On branch feature/retry-backoff
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	deleted:    evalkit/retry.py

$ git symbolic-ref HEAD refs/heads/main
$ git status --short
```
<!-- /snippet -->

The index and the working tree still hold the content of `main`, so `git status` reports the difference between the commit HEAD now names and the index as a staged deletion. Switching back makes the report disappear. A branch switch is this ref change plus an update of the index and the working tree. That is the next video.

**[TERMINAL]** Caption bar: `labs/ch07/commit-moves-branch.sh`.

```bash
labs/run ch07/commit-moves-branch
```

<!-- snippet: ch07/commit-moves-branch/01-before -->
```text
$ git switch -c feature/retry-backoff
Switched to a new branch 'feature/retry-backoff'
$ cat .git/HEAD
ref: refs/heads/feature/retry-backoff
$ git for-each-ref --format='%(objectname:short) %(refname)' refs/heads
23b0907 refs/heads/feature/retry-backoff
23b0907 refs/heads/main
```
<!-- /snippet -->

Two branches on the same commit, `23b0907`, and HEAD names the new one. Predict the three values after one commit: the text of `.git/HEAD`, and the IDs in the two branch refs.

<!-- snippet: ch07/commit-moves-branch/02-commit -->
```text
# evalkit/judge.py has been edited: call_judge() now retries on HTTP 429.
$ git commit -am "Retry judge calls on HTTP 429"
[feature/retry-backoff f5192c8] Retry judge calls on HTTP 429
 1 file changed, 10 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

<!-- snippet: ch07/commit-moves-branch/03-after -->
```text
$ cat .git/HEAD
ref: refs/heads/feature/retry-backoff
$ git for-each-ref --format='%(objectname:short) %(refname)' refs/heads
f5192c8 refs/heads/feature/retry-backoff
23b0907 refs/heads/main
$ git reflog show feature/retry-backoff
f5192c8 feature/retry-backoff@{0}: commit: Retry judge calls on HTTP 429
23b0907 feature/retry-backoff@{1}: branch: Created from HEAD
$ git reflog -2
f5192c8 HEAD@{0}: commit: Retry judge calls on HTTP 429
23b0907 HEAD@{1}: checkout: moving from main to feature/retry-backoff
$ git log --oneline --graph --all
* f5192c8 Retry judge calls on HTTP 429
* 23b0907 Add judge client
* 6eab4a9 Add README
```
<!-- /snippet -->

`.git/HEAD` is unchanged. `feature/retry-backoff` moved to `f5192c8`; `main` stayed on `23b0907`. The branch reflog gained a `commit:` line, and the HEAD reflog shows the switch and the commit.

## COMMON MISTAKES

1. **Describing a branch as a copy or as a set of commits.** Root cause: the ref holds one commit ID and nothing else; the history is reached through parent links.
2. **Reading `.git/refs/heads/<name>` in a script.** Root cause: refs may be packed or stored in reftable; use `git rev-parse` or `git for-each-ref`.
3. **Writing a ref file by hand.** Root cause: it skips validation, locking and the reflog; use `git update-ref`.
4. **`git branch feature` fails in a new repository.** Root cause: the current branch is unborn, so there is no commit to point the new branch at.
5. **Saying "the fix is on `main`" without naming a repository.** Root cause: `main` is a different ref with possibly a different value in every clone and on the server.

## PRODUCTION EXAMPLE

"I committed to the wrong branch" is, as the textbook puts it, a ref problem and not a content problem. The commit object is correct; only the name that moved is wrong. An engineer on an evaluation team makes two commits on `main` that belong on a feature branch. Nothing has to be copied. The repair is two ref writes: create a branch at the current commit, and move `main` back. V026 runs that repair.

And for the CTO's 340 branches: deleting a branch deletes a name. Whether anything is lost depends on whether another name still reaches those commits. That is a reachability question, and V026 answers it with three tests.

## PRACTICE EXERCISE

Do Lab 4.1, "Refs by hand", in [`lab-manual/m04-refs-branches-head.md`](../../lab-manual/m04-refs-branches-head.md).

Before each plumbing command, predict which file under `.git` will change, and whether a reflog line will be written. Before the failure scenario, predict what `git log --all` will say about a broken ref.

## INTERVIEW QUESTION

Q93: "What exactly is a branch? Define it in one sentence that mentions neither "copy" nor "line of development", and prove the definition with two commands."

Answer aloud. A strong answer gives the sentence without hesitation, says what the ref does not contain, and chooses two commands whose outputs can be compared on the spot. Add why you would not prove it by reading a file under `.git/refs`.

## RECAP

You should now be able to say: a branch is a ref under `refs/heads/` that holds the ID of one commit, and its history is what that commit reaches. Creating a branch writes one small ref and copies nothing. Refs can be loose files, packed, or in reftable, so I read them with plumbing. HEAD is a symbolic ref that names the current branch; it can also hold a commit ID, or name a branch that is not born yet. A commit writes the new ID into the ref that HEAD names, appends to two reflogs, and leaves HEAD's text alone.

## HOMEWORK

- Read sections 7.1 to 7.4 of [Chapter 7](../../textbook/ch07-branches.md).
- Do Exercise 4.1, Level 1, "a branch, and the file behind each step", and Exercise 4.2, Level 1, "HEAD follows you", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
- Challenge: Exercise 4.6, Level 2, "from which branch was it created?", in the same file.
