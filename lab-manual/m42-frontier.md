# Module 42 labs: The frontier

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch14d/`. Read [Chapter 14D: The Frontier](../textbook/ch14d-frontier.md) first.

## How to run these labs

```bash
bash labs/ch14d/setup-42-1-sha256-reftable.sh    # build the starting state (run again to start over)
labs/shell m42-1                                 # open the isolated lab shell in that sandbox
labs/run ch14d/lab-42-1-sha256-reftable          # optional: replay the whole lab and print its transcript
```

- Commits that exist when you enter a sandbox have the IDs printed here. Commits you create have other IDs, with one exception that Lab 42.1 explains: `git fast-import` copies the recorded dates, so a converted history has the same IDs in your sandbox as in the book.
- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?`.
- `git history` and `git repo` are experimental commands of Git 2.54 and 2.52. If your Git is older, `git history -h` fails and Lab 42.2 cannot be done.

| Lab | Topic | Sandbox | Replay |
|---|---|---|---|
| 42.1 | SHA-256 and reftable repositories | `m42-1` | `ch14d/lab-42-1-sha256-reftable` |
| 42.2 | `git history reword` | `m42-2` | `ch14d/lab-42-2-history-reword` |
| 42.3 | A format-patch and am round trip | `m42-3` | `ch14d/lab-42-3-format-patch-am` |

Answers to the questions are in [solutions/m42-lab-answers.md](../solutions/m42-lab-answers.md). Write your own first.

## Lab 42.1: SHA-256 and reftable repositories

### Objective

Create a repository with the formats that Git 3.0 plans as defaults, convert an existing history to SHA-256, and migrate an existing repository to reftable. Then watch a script that reads `.git` directly fail in two different ways, and replace it with one that asks Git.

### Prerequisites

- Chapter 14D, sections 14D.3 to 14D.5.
- Chapter 3 (Git Internals), sections 3.13 and 3.14.

### Setup

```bash
bash labs/ch14d/setup-42-1-sha256-reftable.sh
labs/shell m42-1
cd inference
```

The script builds `inference`, a repository of today (SHA-1, refs in files) with two branches and a tag, and `scripts/release-id.sh` with a corrected version `scripts/release-id.v2.sh`.

### Commands

Step 1. Today's repository, and a release script from 2019 that works in it.

```bash
git repo info --all
git log --oneline --graph --all
cat ../scripts/release-id.sh
sh ../scripts/release-id.sh
```

Step 2. A repository in both new formats. Look at what is different in `.git` before you make a commit.

```bash
cd ..
git init --object-format=sha256 --ref-format=reftable future
cd future
git repo info --all
ls .git
cat .git/HEAD
printf 'def predict(batch):\n    return model(batch)\n' > serve.py && git add serve.py
git commit -q -m "Add inference service"
git log --format="%H %s"
git refs list
```

Step 3. Try to bring the old history into the new repository, then convert it the only way that works.

```bash
cd ..
git -C future fetch -q ../inference main
git init -q --object-format=sha256 inference-sha256
git -C inference fast-export --all | git -C inference-sha256 fast-import --quiet
git -C inference log --oneline --all
git -C inference-sha256 log --oneline --all
git -C inference-sha256 repo info object.format references.format
```

Step 4. Change the ref format of the old repository in place.

```bash
cd inference
git for-each-ref
git refs migrate --ref-format=reftable
git repo info references.format
git for-each-ref
```

### Expected output

<!-- snippet: ch14d/lab-42-1-sha256-reftable/01-today -->
```text
$ cd inference
$ git repo info --all
layout.bare=false
layout.shallow=false
object.format=sha1
references.format=files
$ git log --oneline --graph --all
* c284765 Pad batches to a fixed length
* 53a79b6 Raise batch size to 16
* 3e283dd Add inference service
$ cat ../scripts/release-id.sh
#!/bin/sh
# Print the commit that a release is built from: the tip of main. (Written in 2019.)
id=$(cat .git/refs/heads/main) || exit 1
if ! echo "$id" | grep -Eq '^[0-9a-f]{40}$'; then
  echo "release-id: not a commit ID: $id" >&2
  exit 1
fi
echo "$id"
$ sh ../scripts/release-id.sh
53a79b6a9382bec33a6eef3d133390d21760ed78
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-1-sha256-reftable/02-future -->
```text
$ cd ..
$ git init --object-format=sha256 --ref-format=reftable future
Initialized empty Git repository in $LAB/ch14d/lab-42-1-sha256-reftable/future/.git/
$ cd future
$ git repo info --all
layout.bare=false
layout.shallow=false
object.format=sha256
references.format=reftable
$ ls .git
config
description
HEAD
hooks
info
objects
refs
reftable
$ cat .git/HEAD
ref: refs/heads/.invalid
$ printf 'def predict(batch):\n    return model(batch)\n' > serve.py && git add serve.py
$ git commit -q -m "Add inference service"
$ git log --format="%H %s"
6d0637831bf2a3c8930ac8f5fd161b98a63ed74471242e1f7974994c83b975df Add inference service
$ git refs list
6d0637831bf2a3c8930ac8f5fd161b98a63ed74471242e1f7974994c83b975df commit	refs/heads/main
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-1-sha256-reftable/03-convert -->
```text
# Object formats cannot be mixed, so history moves as a stream and every object gets a new name:
$ cd ..
$ git -C future fetch -q ../inference main
fatal: mismatched algorithms: client sha256; server sha1
[exit status: 128]
$ git init -q --object-format=sha256 inference-sha256
$ git -C inference fast-export --all | git -C inference-sha256 fast-import --quiet
$ git -C inference log --oneline --all
c284765 Pad batches to a fixed length
53a79b6 Raise batch size to 16
3e283dd Add inference service
$ git -C inference-sha256 log --oneline --all
4fea7f1 Pad batches to a fixed length
587a0ea Raise batch size to 16
6daacca Add inference service
$ git -C inference-sha256 repo info object.format references.format
object.format=sha256
references.format=files
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-1-sha256-reftable/04-migrate -->
```text
# The ref format of an existing repository can be changed in place:
$ cd inference
$ git for-each-ref
c28476567742db22d0af945e617907ddec7c325d commit	refs/heads/feature/batching
53a79b6a9382bec33a6eef3d133390d21760ed78 commit	refs/heads/main
2c5a6d507719d6d960f0d6a892995d8d612279c5 tag	refs/tags/v0.1.0
$ git refs migrate --ref-format=reftable
$ git repo info references.format
references.format=reftable
$ git for-each-ref
c28476567742db22d0af945e617907ddec7c325d commit	refs/heads/feature/batching
53a79b6a9382bec33a6eef3d133390d21760ed78 commit	refs/heads/main
2c5a6d507719d6d960f0d6a892995d8d612279c5 tag	refs/tags/v0.1.0
```
<!-- /snippet -->

### What happened internally

- `git init` with the two options wrote `extensions.objectformat = sha256` and `extensions.refstorage = reftable` and set `repositoryformatversion = 1`. In a reftable repository `.git/HEAD` is a stub with the content `ref: refs/heads/.invalid`; the real HEAD is a record in `.git/reftable/`. Object IDs have 64 hexadecimal digits.
- The fetch failed during the first exchange of the protocol: client and server announced different hash algorithms. No object can be copied, because every tree and commit refers to others by ID, and the IDs of the two formats are unrelated.
- `git fast-export` wrote the history as a text stream: file contents, commit metadata and marks instead of IDs. `git fast-import` rebuilt every object in the receiving repository and hashed it with SHA-256. Author and committer dates were copied, so the result is the same on every run; the subjects match and no ID does.
- `git refs migrate` rewrote the ref storage and nothing else: `git for-each-ref` prints the same refs with the same values before and after. The object format did not change.

### Checkpoint

- `git -C ../inference-sha256 log --oneline --all` shows three commits whose subjects match those of `inference`.
- `git repo info references.format`, run in `inference`, prints `references.format=reftable`.

### Failure scenario

The release script has not changed. Run it in the migrated repository and in the converted one.

```bash
sh ../scripts/release-id.sh
cd ../inference-sha256
sh ../scripts/release-id.sh
```

<!-- snippet: ch14d/lab-42-1-sha256-reftable/05-failure -->
```text
# The release script has not changed. Two repositories, two different failures:
$ sh ../scripts/release-id.sh
cat: .git/refs/heads/main: Not a directory
[exit status: 1]
$ cd ../inference-sha256
$ sh ../scripts/release-id.sh
release-id: not a commit ID: 587a0ea1903116442c9bc9d9014567a4bfdde436c0268f95ddbfb247362f5639
[exit status: 1]
```
<!-- /snippet -->

Two failures with two root causes. In `inference` the file `.git/refs/heads/main` does not exist any more: with reftable, `.git/refs/heads` is a plain file that exists only so that older tools recognize the directory as a repository, hence `Not a directory`. In `inference-sha256` the ref is a file and the script read it, and then its own check rejected a correct commit ID for having 64 digits.

### Recovery

Replace both assumptions with one question to Git.

```bash
cat ../scripts/release-id.v2.sh
sh ../scripts/release-id.v2.sh
cd ../inference
sh ../scripts/release-id.v2.sh
cd ../future
sh ../scripts/release-id.v2.sh
```

<!-- snippet: ch14d/lab-42-1-sha256-reftable/06-recovery -->
```text
$ cat ../scripts/release-id.v2.sh
#!/bin/sh
# Print the commit that a release is built from: the tip of main.
# Ask Git. It knows where refs are stored and how long an object ID is.
id=$(git rev-parse --verify --quiet 'refs/heads/main^{commit}') || {
  echo "release-id: this repository has no branch main" >&2
  exit 1
}
echo "$id"
$ sh ../scripts/release-id.v2.sh
587a0ea1903116442c9bc9d9014567a4bfdde436c0268f95ddbfb247362f5639
[exit status: 0]
$ cd ../inference
$ sh ../scripts/release-id.v2.sh
53a79b6a9382bec33a6eef3d133390d21760ed78
[exit status: 0]
$ cd ../future
$ sh ../scripts/release-id.v2.sh
6d0637831bf2a3c8930ac8f5fd161b98a63ed74471242e1f7974994c83b975df
[exit status: 0]
```
<!-- /snippet -->

`git rev-parse --verify --quiet 'refs/heads/main^{commit}'` resolves the ref through whatever backend the repository uses, checks that it is a commit, and prints an ID of whatever length the repository uses. (In `future` your ID differs from the book's.)

### Verification

```bash
cd ..
for r in inference inference-sha256 future; do echo "$r: $(git -C $r rev-parse --show-object-format --show-ref-format | tr "\n" " ")"; done
git -C inference refs verify
git -C inference refs migrate --ref-format=files
git -C inference repo info references.format
```

<!-- snippet: ch14d/lab-42-1-sha256-reftable/07-verification -->
```text
$ cd ..
$ for r in inference inference-sha256 future; do echo "$r: $(git -C $r rev-parse --show-object-format --show-ref-format | tr "\n" " ")"; done
inference: sha1 reftable 
inference-sha256: sha256 files 
future: sha256 reftable 
$ git -C inference refs verify
$ git -C inference refs migrate --ref-format=files
$ git -C inference repo info references.format
references.format=files
```
<!-- /snippet -->

Three repositories, three combinations, one script that works in all of them. The ref format went back to `files` with one command. The object format cannot go back: `inference-sha256` is a different history.

> **GitHub, not Git.** GitHub had no publicly available support for SHA-256 repositories on 1 October 2026 (Chapter 14D, section 14D.5). The error for pushing a SHA-256 repository to a SHA-1 host was not reproduced for this course.

### Questions

1. Which lines of `.git/config` make a repository SHA-256 and reftable, and why does `repositoryformatversion` change with them?
2. Why can `git fetch` not transfer objects between the two formats, when `fast-export` and `fast-import` can?
3. After the conversion, name three things outside the repository that still refer to the old commit IDs.
4. The release script failed with `Not a directory` in one repository and with `not a commit ID` in the other. Give the root cause of each and the one change that fixes both.
5. `git refs migrate` could be undone and the object format could not. Why?
6. Your team's repositories are on GitHub. Which of the four 3.0 settings would you roll out today, and which would you hold back?

## Lab 42.2: `git history reword`

### Objective

Fix a typo in the message of an unpushed commit with the experimental `git history reword`, and see which refs it moves. Then aim the same command at a commit that is already pushed, and put two branches back from their reflogs.

### Prerequisites

- Chapter 14D, section 14D.6.
- Chapter 9 (Rebase), sections 9.15 and 9.16; Chapter 13 (Recovery) for reflogs.

### Setup

```bash
bash labs/ch14d/setup-42-2-history-reword.sh
labs/shell m42-2
cd evalkit
```

The script builds `server.git` and your clone `evalkit`. Two commits are pushed. Two more are local, and the first of them says `Add recall metirc`. A local branch `topic/judge` adds one commit on top of `main`.

`git history reword` opens your editor with the old message. Change it, save and close. In the replay a script plays the editor.

### Commands

Step 1. The starting point.

```bash
git log --oneline --graph --all
git status -sb
```

Step 2. Ask what would move. In the editor, change the subject to `Add recall metric`.

```bash
git history reword --dry-run HEAD~1
git log --oneline -2
```

Step 3. Do it, with the same edit.

```bash
git history reword HEAD~1
git log --oneline --graph --all
git status -sb
```

Step 4. What moved, and what stayed.

```bash
git reflog show -2 main
git reflog show -2 topic/judge
git range-diff origin/main 'main@{1}' main
git log -1 --format='%an %ad | %cn %cd' 'main@{1}~1'
git log -1 --format='%an %ad | %cn %cd' main~1
```

### Expected output

<!-- snippet: ch14d/lab-42-2-history-reword/01-start -->
```text
$ cd evalkit
$ git log --oneline --graph --all
* 5564480 Add judge prompt
* 3bcb117 Add README
* 7189e39 Add recall metirc
* 25eaae6 Add F1
* fff1c3a Add exact-match metric
$ git status -sb
## main...origin/main [ahead 2]
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-2-history-reword/02-dry-run -->
```text
$ git history reword --dry-run HEAD~1
update refs/heads/main aa9b2d591e0349f675accb2822343a3514c4e943 3bcb11789474125abea47e4b2afb7d03605e13a8
update refs/heads/topic/judge fd984f181c54987d7edb4e0aeafe14968e8859d7 556448033cb8b3a1d691e516d59133445a269e21
$ git log --oneline -2
3bcb117 Add README
7189e39 Add recall metirc
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-2-history-reword/03-reword -->
```text
$ git history reword HEAD~1
$ git log --oneline --graph --all
* e28604b Add judge prompt
* ec17d2d Add README
* 0269650 Add recall metric
* 25eaae6 Add F1
* fff1c3a Add exact-match metric
$ git status -sb
## main...origin/main [ahead 2]
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-2-history-reword/04-what-moved -->
```text
$ git reflog show -2 main
ec17d2d main@{0}: reword: updating HEAD~1
3bcb117 main@{1}: commit: Add README
$ git reflog show -2 topic/judge
e28604b topic/judge@{0}: reword: updating HEAD~1
5564480 topic/judge@{1}: commit: Add judge prompt
# Old and new version of the range, commit by commit:
$ git range-diff origin/main 'main@{1}' main
1:  7189e39 ! 1:  0269650 Add recall metirc
    @@ Metadata
     Author: Lab User <you@example.com>
     
      ## Commit message ##
    -    Add recall metirc
    +    Add recall metric
     
      ## recall.py (new) ##
     @@
2:  3bcb117 = 2:  ec17d2d Add README
# Author and committer of the reworded commit, before and after:
$ git log -1 --format='%an %ad | %cn %cd' 'main@{1}~1'
Lab User Mon Sep 7 10:07:00 2026 +0530 | Lab User Mon Sep 7 10:07:00 2026 +0530
$ git log -1 --format='%an %ad | %cn %cd' main~1
Lab User Mon Sep 7 10:07:00 2026 +0530 | Lab User Mon Sep 7 10:17:00 2026 +0530
```
<!-- /snippet -->

### What happened internally

- The dry run created the rewritten commits as objects and printed two lines in the input format of `git update-ref --stdin`: `update <ref> <new value> <old value>`. No ref moved, as `git log` confirmed.
- The real run created a commit with the new message and the same tree, author and parent as the old one, then a new copy of every descendant commit, and moved both local branches that contain the old commit: `main`, which is checked out, and `topic/judge`, which is not. Each got a reflog entry `reword: updating HEAD~1`.
- The working tree and the index were not touched. `origin/main` did not move, and `main` is still two commits ahead of it, because the rewritten commits were never pushed.
- `git range-diff` pairs old and new commits. The first pair differs in the message only; the second is `=`: same patch, new ID, because its parent changed.
- The author and the author date of the reworded commit are unchanged. The committer date is the time of the reword. The manual says that all other details of the commit remain unchanged; on Git 2.55.0 the committer date does not.

### Checkpoint

- `git log --oneline -3 topic/judge` shows `Add recall metric`, without the typo, below `Add README` and `Add judge prompt`.
- `git status -sb` prints `## main...origin/main [ahead 2]`.

### Failure scenario

The second commit, `Add F1`, could say more. It is already on the server. Reword it anyway (new subject: `Add F1 metric`), and then try to push.

```bash
git branch -r --contains HEAD~2
git history reword HEAD~2
git status -sb
git log --oneline --graph --all
git -c advice.pushUpdateRejected=false push origin main
```

<!-- snippet: ch14d/lab-42-2-history-reword/05-failure -->
```text
# The same command, aimed at a commit that origin already has:
$ git branch -r --contains HEAD~2
  origin/main
$ git history reword HEAD~2
$ git status -sb
## main...origin/main [ahead 3, behind 1]
$ git log --oneline --graph --all
* d384bea Add judge prompt
* 0648c29 Add README
* c1567a6 Add recall metric
* 0792188 Add F1 metric
| * 25eaae6 Add F1
|/  
* fff1c3a Add exact-match metric
$ git -c advice.pushUpdateRejected=false push origin main
To $LAB/ch14d/lab-42-2-history-reword/server.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '$LAB/ch14d/lab-42-2-history-reword/server.git'
[exit status: 1]
```
<!-- /snippet -->

The first command answered the question you should have asked: `origin/main` contains that commit. The reword replaced it and everything above it on two branches. `main` is now three ahead and one behind, the graph shows the old `Add F1` on a line of its own, and the push is rejected. The only way to publish this would be a force push that rewrites `main` for everyone, for the sake of two words.

### Recovery

`git history` has no undo of its own. Each branch it moved has the previous tip in its reflog, so the undo is one step per branch.

```bash
git reflog show -3 main
git reset --hard 'main@{1}'
git branch -f topic/judge 'topic/judge@{1}'
git status -sb
```

<!-- snippet: ch14d/lab-42-2-history-reword/06-recovery -->
```text
$ git reflog show -3 main
0648c29 main@{0}: reword: updating HEAD~2
ec17d2d main@{1}: reword: updating HEAD~1
3bcb117 main@{2}: commit: Add README
$ git reset --hard 'main@{1}'
HEAD is now at ec17d2d Add README
$ git branch -f topic/judge 'topic/judge@{1}'
$ git status -sb
## main...origin/main [ahead 2]
```
<!-- /snippet -->

🔴 `git reset --hard` is appropriate here because the working tree is clean (`git status -s` prints nothing) and the commit you leave stays in the reflog. `git branch -f` moves a branch that is not checked out. `main@{1}` is the state after the first, wanted reword: the typo fix is kept.

### Verification

```bash
git log --oneline --graph --all
git push origin main
git status -sb
```

<!-- snippet: ch14d/lab-42-2-history-reword/07-verification -->
```text
$ git log --oneline --graph --all
* e28604b Add judge prompt
* ec17d2d Add README
* 0269650 Add recall metric
* 25eaae6 Add F1
* fff1c3a Add exact-match metric
$ git push origin main
To $LAB/ch14d/lab-42-2-history-reword/server.git
   25eaae6..ec17d2d  main -> main
[exit status: 0]
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

One line of history again, the fast-forward push is accepted, and `main` equals `origin/main`.

### Questions

1. `git history reword HEAD~1` moved `topic/judge` although you were on `main`. Which option would have left it alone, and what would the graph have looked like then?
2. Why did every commit above the reworded one get a new ID although their content did not change?
3. What did the dry run write into the repository, and what did it not write?
4. Before the failure scenario, which command told you that the commit was published? Write the general rule it stands for.
5. In the recovery, why was `main@{1}` the right target and not `main@{2}` or `ORIG_HEAD`?
6. A teammate has a `commit-msg` hook that enforces a subject format. Does `git history reword` respect it? How do you know?

## Lab 42.3: A format-patch and am round trip

### Objective

Send a branch as patch files and apply it in a repository that cannot fetch from yours, as the maintainer of a mailing-list project would. Compare what arrives with what was sent. Then apply the series to a branch that has moved, watch `git am` stop, and finish with a three-way merge.

### Prerequisites

- Chapter 14D, section 14D.11.
- Chapter 8 (Merge) for conflict resolution; Chapter 6 (Commits) for author and committer.

### Setup

```bash
bash labs/ch14d/setup-42-3-format-patch-am.sh
labs/shell m42-3
cd fork
```

The script builds `upstream`, the maintainer's repository (Ravi Menon is configured as its identity, so commits you make there are his), and `fork`, your clone, with the branch `fix/casefold` and two commits.

### Commands

Step 1. Turn the branch into patch files.

```bash
git log --oneline origin/main..fix/casefold
git format-patch -o ../outbox origin/main
```

Step 2. Read what you are about to send.

```bash
sed -n '1,8p' ../outbox/0001-tok-casefold-the-input-before-splitting.patch
git apply --stat ../outbox/*.patch
```

Step 3. Change roles. In the maintainer's repository, check that the first patch would apply, then apply the series on a review branch.

```bash
cd ../upstream
git apply --check ../outbox/0001-tok-casefold-the-input-before-splitting.patch
git switch -q -c review/casefold
git am ../outbox/*.patch
git log --format='%h author: %an, committer: %cn | %s'
```

Step 4. Compare the result with the original branch.

```bash
git rev-parse 'review/casefold^{tree}'
git -C ../fork rev-parse 'fix/casefold^{tree}'
git rev-parse --short review/casefold
git -C ../fork rev-parse --short fix/casefold
```

### Expected output

<!-- snippet: ch14d/lab-42-3-format-patch-am/01-format-patch -->
```text
$ cd fork
$ git log --oneline origin/main..fix/casefold
92eba7f README: document the casefolding
41a7b91 tok: casefold the input before splitting
$ git format-patch -o ../outbox origin/main
../outbox/0001-tok-casefold-the-input-before-splitting.patch
../outbox/0002-README-document-the-casefolding.patch
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-3-format-patch-am/02-read -->
```text
$ sed -n '1,8p' ../outbox/0001-tok-casefold-the-input-before-splitting.patch
From 41a7b91d3ea89ca2dd95e80c5a999b4db206795d Mon Sep 17 00:00:00 2001
From: Lab User <you@example.com>
Date: Mon, 7 Sep 2026 10:07:00 +0530
Subject: [PATCH 1/2] tok: casefold the input before splitting

---
 tok.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git apply --stat ../outbox/*.patch
 tok.py |    2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
 README.md |    2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-3-format-patch-am/03-am -->
```text
$ cd ../upstream
$ git apply --check ../outbox/0001-tok-casefold-the-input-before-splitting.patch
[exit status: 0]
$ git switch -q -c review/casefold
$ git am ../outbox/*.patch
Applying: tok: casefold the input before splitting
Applying: README: document the casefolding
$ git log --format='%h author: %an, committer: %cn | %s'
25c29be author: Lab User, committer: Ravi Menon | README: document the casefolding
6c00e59 author: Lab User, committer: Ravi Menon | tok: casefold the input before splitting
9ba24bc author: Ravi Menon, committer: Ravi Menon | Add whitespace tokenizer
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-3-format-patch-am/04-compare -->
```text
$ git rev-parse 'review/casefold^{tree}'
f5e5887e65c78cdcb402af517b9d66e542afa85d
$ git -C ../fork rev-parse 'fix/casefold^{tree}'
f5e5887e65c78cdcb402af517b9d66e542afa85d
$ git rev-parse --short review/casefold
25c29be
$ git -C ../fork rev-parse --short fix/casefold
92eba7f
```
<!-- /snippet -->

### What happened internally

- `git format-patch origin/main` wrote one file per commit in `origin/main..HEAD`. Each file is an e-mail: the header lines carry the author, the author date and the subject, the body carries the message, and the diff follows a line of three dashes.
- `git apply --check` tested the diff against the working tree without changing anything. `git apply --stat` only read the files.
- `git am` did three things per file: it split the file into message and patch, applied the patch to the index and the working tree, and created a commit with the author and date from the header and with the person who ran it as committer.
- The trees of the two branch tips are identical, so the content arrived intact. The commit IDs differ, because the committer and the committer date are part of a commit.
- Nothing was fetched or pushed. The two repositories never exchanged an object.

### Checkpoint

- In `upstream`, `git log --oneline review/casefold` shows three commits, the top two with your subjects.
- `git log -1 --format='%an / %cn' review/casefold` prints `Lab User / Ravi Menon`.

### Failure scenario

Before the series reaches `main`, the maintainer commits a change of his own to the line that your first patch changes. Then he applies your series to `main`.

```bash
git switch -q main
printf 'def tokenize(text):\n    return text.strip().split()\n' > tok.py
git commit -q -am "tok: strip the input"
git am ../outbox/*.patch
git status
git am --show-current-patch=diff | tail -n 9
```

<!-- snippet: ch14d/lab-42-3-format-patch-am/05-failure -->
```text
# Before the series is applied to main, the maintainer commits a change to the same line:
$ git switch -q main
$ printf 'def tokenize(text):\n    return text.strip().split()\n' > tok.py
$ git commit -q -am "tok: strip the input"
$ git -c advice.mergeConflict=false am ../outbox/*.patch
error: patch failed: tok.py:1
error: tok.py: patch does not apply
hint: Use 'git am --show-current-patch=diff' to see the failed patch
Applying: tok: casefold the input before splitting
Patch failed at 0001 tok: casefold the input before splitting
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-3-format-patch-am/06-state -->
```text
$ git status
On branch main
You are in the middle of an am session.
  (fix conflicts and then run "git am --continue")
  (use "git am --skip" to skip this patch)
  (use "git am --abort" to restore the original branch)

nothing to commit, working tree clean
$ git am --show-current-patch=diff | tail -n 9
--- a/tok.py
+++ b/tok.py
@@ -1,2 +1,2 @@
 def tokenize(text):
-    return text.split()
+    return text.casefold().split()
-- 
2.55.0
```
<!-- /snippet -->

`git am` stopped at the first patch: the line it wants to replace is not there any more. The state is unlike a merge conflict. The working tree is clean, there are no conflict markers, and `git status` reports an "am session". The patch is kept in `.git/rebase-apply`, and `--show-current-patch` prints it.

### Recovery

Back out, and apply again with `-3`. With that option, when a patch does not apply, Git uses the blob IDs on the patch's `index` line to find the version the patch was made against, and performs a three-way merge.

```bash
git am --abort
git status -sb
git am -3 ../outbox/*.patch
cat tok.py
```

<!-- snippet: ch14d/lab-42-3-format-patch-am/07-recovery -->
```text
$ git am --abort
$ git status -sb
## main
$ git -c advice.mergeConflict=false am -3 ../outbox/*.patch
Applying: tok: casefold the input before splitting
Using index info to reconstruct a base tree...
M	tok.py
Falling back to patching base and 3-way merge...
Auto-merging tok.py
CONFLICT (content): Merge conflict in tok.py
error: Failed to merge in the changes.
hint: Use 'git am --show-current-patch=diff' to see the failed patch
Patch failed at 0001 tok: casefold the input before splitting
[exit status: 128]
$ cat tok.py
def tokenize(text):
<<<<<<< HEAD
    return text.strip().split()
=======
    return text.casefold().split()
>>>>>>> tok: casefold the input before splitting
```
<!-- /snippet -->

Now it is an ordinary conflict with markers, and the labels say which side is which: `HEAD` is the maintainer's line, the other side is named after your patch. Keep both intentions, mark the file as resolved, and let `git am` go on.

```bash
printf 'def tokenize(text):\n    return text.strip().casefold().split()\n' > tok.py
git add tok.py
git am --continue
```

<!-- snippet: ch14d/lab-42-3-format-patch-am/08-continue -->
```text
$ printf 'def tokenize(text):\n    return text.strip().casefold().split()\n' > tok.py
$ git add tok.py
$ git am --continue
Applying: tok: casefold the input before splitting
Applying: README: document the casefolding
```
<!-- /snippet -->

The first patch was committed with the resolved content, and the second applied without help.

### Verification

```bash
git log --format='%h author: %an, committer: %cn | %s' -3
cat tok.py
git status -sb
```

<!-- snippet: ch14d/lab-42-3-format-patch-am/09-verification -->
```text
$ git log --format='%h author: %an, committer: %cn | %s' -3
e660218 author: Lab User, committer: Ravi Menon | README: document the casefolding
92561c2 author: Lab User, committer: Ravi Menon | tok: casefold the input before splitting
fbe57ec author: Ravi Menon, committer: Ravi Menon | tok: strip the input
$ cat tok.py
def tokenize(text):
    return text.strip().casefold().split()
$ git status -sb
## main
```
<!-- /snippet -->

Both of your commits are on `main` of the maintainer's repository with you as author, the file has both changes, and no am session is left.

### Questions

1. Which lines of a patch file become which fields of the commit that `git am` creates? What happens to `[PATCH 1/2]` and to the diffstat?
2. After step 3 the trees were equal and the commit IDs were not. Which fields of the commit differ?
3. Why did the first `git am` leave no conflict markers, and what did `-3` need in order to produce them? When would `-3` fail as well?
4. Compare `git am --abort`, `--skip` and `--continue`. What would `--skip` have done in the failure scenario?
5. When would you use `git apply` and not `git am`?
6. Your team works with pull requests. Name two situations in which this workflow is still the right tool.
