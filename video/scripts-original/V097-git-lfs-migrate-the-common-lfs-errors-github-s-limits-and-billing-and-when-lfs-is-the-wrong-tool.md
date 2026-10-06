# V097: git lfs migrate, the common LFS errors, GitHub's limits and billing, and when LFS is the wrong tool

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 15, Submodules, subtrees, Git LFS; and Module 33, AI/ML workflows
- **Planned minutes.** 26
- **Prerequisites.** V052, V096
- **Textbook sections.** [Chapter 22](../../textbook/ch22-git-lfs.md), sections 22.9 to 22.14
- **Demo scripts.** `labs/ch22/lfs-migrate.sh`, `labs/ch22/lfs-error-not-pointer.sh`, `labs/ch22/lfs-error-tracked-late.sh`, `labs/ch22/lfs-error-missing-object-volatile.sh`, `labs/ch22/lfs-migrate-export-volatile.sh`, and the snippets `06-failure` and `07-diagnose` of `labs/ch22/lab-15-4-lfs-migrate.sh`

## HOOK

**[ON SCREEN]** "The push to GitHub was rejected because of a model file. I deleted the file and committed. It is still rejected. Why?" And: "Our storage bill for this repository keeps growing, and nobody has added a model in months."

You can answer the first question now: the blob is in a commit being pushed, and deleting the file added a commit without removing one. The engineer's next attempt is `git lfs track`, and a new commit. Still rejected, for the same reason.

The tool that does help is a history rewrite. And the same tool, with one extra flag that promises to "catch everything", leaves a branch that is five commits ahead of the server and one behind it, sharing not a single commit with what the team has.

The second question has an answer that surprises people who think in Git terms: on the hosting side, storage does not shrink when history does.

## INTRODUCTION

This is the last video on LFS, and it has four parts. `git lfs migrate`, for files that are already in history. Three errors that you will meet, each recognised from its message. GitHub's file limits and how it bills for LFS, stated from its documentation. And the judgement call: when LFS is the wrong tool and what the textbook names instead.

Everything about rewriting history from the rebase module applies here: new commit IDs, and the difference between published and unpublished commits. Two of the replays are volatile and will be marked on screen.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- say what `git lfs migrate import` does to commit IDs, the working tree and the size of `.git`;
- plan a migration of a shared repository as a history rewrite;
- diagnose three LFS errors from their messages: a missing object, a file that should have been a pointer, a file tracked too late;
- state GitHub's file limits and the LFS billing model as the cited section gives them;
- decide when LFS is the wrong tool and name the alternative the section gives.

## CONCEPT

**`git lfs migrate`** has three modes.

`info` reads history and reports sizes by file extension. It changes nothing. 🟢 SAFE.

`import` is a history rewrite. 🟡 CAUTION for the default scope: it replaces matching blobs by pointers in every commit in scope, adds the `.gitattributes` line, and gives every rewritten commit and all of its descendants a new ID.

`export` is the reverse rewrite: pointers become ordinary blobs again in the commits in scope.

**Scope is the dangerous option.** By default all three modes look only at the current branch, and only at commits that are on no remote. That default is the safe one: nothing that anyone else has is rewritten. Name further branches as arguments to include their unpushed commits. `--everything` means every commit reachable from every local and remote ref, including commits that are already on the remote. 🔴 DANGEROUS when followed by a forced push: it rewrites published history.

Two things about the state `import` leaves surprise people. First, the working tree file is a pointer afterwards, even with the filter installed; the command's own help says this is normal and names the remedy, `git lfs checkout`. Second, the repository did not get smaller. The old commits are off the branch and still in the reflog, so the old blobs are still in the object database until the reflog entries expire and a garbage collection runs. And the bytes have not left your disk either: they are in `.git/lfs/objects` now, once per version.

When the large files are already on the remote, a rewrite of published history is what you need, and it is an operation with a plan, not a command. Everyone stops pushing. One person rewrites and pushes with `--force-with-lease`. Everyone else re-clones or resets. Old clones that push again bring the blobs back.

There is also `git lfs migrate import --no-rewrite`, which converts files in one new commit without touching earlier ones. It has the limit you would expect: the old blobs stay in history, so it does not help with a push that is rejected for a large file.

**Three errors, one family.** In each, a path that `.gitattributes` assigns to LFS, the blob in Git, and the object in the LFS store do not agree.

The file was committed before the pattern was tracked: the blob is the raw file.

A commit was made on a machine without the filter: the blob is the raw file again, reached from the other side.

The pointer was pushed and the object was not: the blob is a correct pointer to content that the remote does not have. The textbook points out the family resemblance to the unpushed submodule commit: a reference was published without the thing it refers to.

**GitHub.** Limits and billing are platform behavior. Hold that for the on-screen segment, where every number is read from the textbook's quotation of the documentation.

**When not to use LFS.** LFS fits a modest number of mid-sized binary files that change rarely and must be versioned together with the code: reference checkpoints for tests, small fixtures, images and design assets. The table of section 22.13 lists five situations in which it is the wrong tool; you will read it at the end of the demonstration.

## MENTAL MODEL

Use the coat check for the three errors.

Tracked too late, or committed without the filter: somebody walked past the ticket desk and hung the coat itself on the ticket rail. The rail was built for tickets. Everyone who comes later finds a coat where a ticket should be.

Pointer pushed, object not: a ticket was sent to the other building, and the coat it names never left yours. Whoever presents the ticket there is told that no such coat exists.

For `migrate import`, picture reprinting the history books so that every page that used to have a coat stapled to it now has a ticket, with the coats moved to the cloakroom. Reprinted pages have new page numbers, and so does every page after them. The old print run is still in your storeroom until you clear it out. The analogy breaks on purpose at the hosting side: clearing your storeroom does not empty the host's cloakroom.

## DIAGRAM

**[DIAGRAM]** A history before and after `migrate import` with the default scope, with the IDs of the transcript. Mark every commit whose ID changed.

```text
  BEFORE                                                    AFTER  git lfs migrate import --include="*.onnx"
  c66100a  Add transcription entry point   (on origin/main)  c66100a   unchanged: already on the remote, out of scope
  f9e56b8  Add acoustic model v1           blob 1.2 MB       b1b921b   NEW ID   pointer 132 bytes  + .gitattributes
  65c2188  Retrain ... noisy audio (v2)    blob 1.25 MB      53cb32a   NEW ID   pointer 132 bytes
  1ddbfc0  Resample input to 16 kHz        no model change   654d53c   NEW ID   changed only because its parent changed
  8b13104  Retrain ... accents (v3)        blob 1.3 MB       d1e8e7d   NEW ID   pointer 132 bytes

  the old commits f9e56b8 ... 8b13104 are still in the reflog, and their blobs are still in .git/objects
```

The commit that was already on the remote kept its ID. The four above it are new commits with the old messages, authors and dates. Look at the fourth row: that commit did not touch the model, and its ID changed anyway, because a commit ID is a hash that includes the parent.

**[ON SCREEN]** The root-cause box of section 22.9, shown when the demonstration reaches `--everything`.

```text
Observed behavior : After migrate import --everything, main is "ahead 5, behind 1" of origin/main and
                    the log shows the first commit twice, as e6c7da2 and as c66100a.
Git state         : origin/main still names c66100a. Local main descends from e6c7da2, a rewritten
                    copy of it. The two histories share no commit.
Mechanism         : --everything put the pushed root commit in scope. The .gitattributes line was
                    added in the first commit in scope, which changed its tree and therefore its ID,
                    and the ID of every descendant.
Root cause        : A history rewrite that included published commits.
Why Git does this : A commit ID is a hash of the commit's content, parents included (Chapter 6).
                    A different first commit cannot have the same descendants.
Correct fix       : Not pushed yet: return both branches to their previous positions from their
                    reflogs and migrate with the branch named instead (Lab 15.4).
Prevention        : Run migrate info with the same scope options first and read the commit count.
                    Use --everything only for a planned rewrite of published history.
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch22/lfs-migrate`. Three versions of the model were committed as ordinary files, and four commits are not pushed.

```bash
git status --short --branch
git lfs migrate info
```

<!-- snippet: ch22/lfs-migrate/01-info -->
```text
$ git status --short --branch
## main...origin/main [ahead 4]
$ git lfs migrate info
Fetching remote refs: ..., done.
Sorting commits: ..., done.
Examining commits: 100% (4/4), done.
*.onnx	3.8 MB	3/3 files	100%
*.py  	429 B 	2/2 files	100%
*.md  	68 B  	1/1 file 	100%
*.txt 	14 B  	1/1 file 	100%
$ git lfs migrate info --above=1mb
Fetching remote refs: ..., done.
Sorting commits: ..., done.
Examining commits: 100% (4/4), done.
*.onnx	3.8 MB	3/3 files	100%
```
<!-- /snippet -->

Note the scope it chose by itself: "Examining commits: 100% (4/4)". `main` is four commits ahead of `origin/main`, so four commits were examined. 3.8 megabytes of `.onnx` in three files.

**[ON SCREEN]** 🟡 CAUTION: `git lfs migrate import`, default scope. It rewrites unpushed commits; the working tree is left with pointers. Preview: `migrate info` with the same options. Recovery: the branch reflog.

```bash
git log --oneline
git lfs install --local
git lfs migrate import --include="*.onnx"
git log --oneline
```

Predict how many of the five commit IDs change.

<!-- snippet: ch22/lfs-migrate/02-import -->
```text
$ git log --oneline
8b13104 Retrain acoustic model with accents (v3)
1ddbfc0 Resample input to 16 kHz
65c2188 Retrain acoustic model on noisy audio (v2)
f9e56b8 Add acoustic model v1
c66100a Add transcription entry point
$ git lfs install --local
Updated Git hooks.
Git LFS initialized.
$ git lfs migrate import --include="*.onnx"
Fetching remote refs: ..., done.
Sorting commits: ..., done.
Rewriting commits: 100% (4/4), done.
Updating refs: ..., done.
Checkout: ..., done.
$ git log --oneline
d1e8e7d Retrain acoustic model with accents (v3)
654d53c Resample input to 16 kHz
53cb32a Retrain acoustic model on noisy audio (v2)
b1b921b Add acoustic model v1
c66100a Add transcription entry point
```
<!-- /snippet -->

Four. `c66100a`, which was already on the remote, kept its ID.

```bash
git show --stat --format="%h %s" HEAD~3
cat .gitattributes
```

<!-- snippet: ch22/lfs-migrate/03-what-changed -->
```text
$ git show --stat --format="%h %s" HEAD~3
b1b921b Add acoustic model v1

 .gitattributes       | 1 +
 models/acoustic.onnx | 3 +++
 2 files changed, 4 insertions(+)
$ cat .gitattributes
*.onnx filter=lfs diff=lfs merge=lfs -text
$ git rev-list --objects main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
blob 132 models/acoustic.onnx
blob 132 models/acoustic.onnx
blob 132 models/acoustic.onnx
$ git lfs migrate info
Fetching remote refs: ..., done.
Sorting commits: ..., done.
Examining commits: 100% (4/4), done.
*.py           	429 B 	2/2 files	100%
*.md           	68 B  	1/1 file 	100%
*.gitattributes	43 B  	1/1 file 	100%
*.txt          	14 B  	1/1 file 	100%

LFS Objects    	3.8 MB	3/3 files	100%
```
<!-- /snippet -->

The rewritten first model commit, `b1b921b`, adds `.gitattributes` and a three-line file where the model was. The rest of the snippet shows three pointer blobs of 132 bytes where the branch reached three large blobs.

Now the first surprise. Predict the size of the model file in the working tree.

```bash
wc -c models/acoustic.onnx
git lfs ls-files
git lfs checkout
wc -c models/acoustic.onnx
```

<!-- snippet: ch22/lfs-migrate/04-working-tree -->
```text
$ wc -c models/acoustic.onnx
     132 models/acoustic.onnx
$ git lfs ls-files
ca75f5b31e - models/acoustic.onnx
$ git lfs checkout
Checking out LFS objects: 100% (1/1), 1.3 MB | 0 B/s, done.
$ wc -c models/acoustic.onnx
 1300000 models/acoustic.onnx
$ git lfs ls-files
ca75f5b31e * models/acoustic.onnx
$ git status --short --branch
## main...origin/main [ahead 4]
```
<!-- /snippet -->

132 bytes, a minus in the listing. After `git lfs checkout`, the real 1,300,000 bytes. The second surprise: the repository did not get smaller.

**[ON SCREEN]** 🔴 DANGEROUS: `git reflog expire --expire=now --all` followed by `git gc --prune=now`. You know the five answers from the recovery module. Here they remove the only way back to the pre-migration commits. Run them when you have verified the result, not before. The transcript uses the two cut-offs that do not depend on a clock.

```bash
git reflog -2
git cat-file --batch-all-objects --batch-check="%(objecttype) %(objectsize)" | grep -c -E "blob [0-9]{7}"
git reflog expire --expire=now --all
git gc --quiet --prune=now
```

<!-- snippet: ch22/lfs-migrate/05-old-objects -->
```text
# The old commits are no longer on any branch, but the reflog still holds them:
$ git reflog -2
d1e8e7d HEAD@{0}: 
8b13104 HEAD@{1}: commit: Retrain acoustic model with accents (v3)
$ git cat-file --batch-all-objects --batch-check="%(objecttype) %(objectsize)" | grep -c -E "blob [0-9]{7}"
3
$ git reflog expire --expire=now --all
$ git gc --quiet --prune=now
$ git cat-file --batch-all-objects --batch-check="%(objecttype) %(objectsize)" | grep -c -E "blob [0-9]{7}"
0
$ find .git/lfs/objects -type f | sort
.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
.git/lfs/objects/ca/75/ca75f5b31e55e3e1e51533c80135181b6d1ea30a82a2c1ab28ddd120c1a8a4f2
.git/lfs/objects/f8/71/f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
```
<!-- /snippet -->

Before the expiry, the reflog still names `8b13104`, the old tip, and three blobs of seven-digit size are still in the object database. After it, they are gone from Git's store.

**[TERMINAL]** From `labs/run ch22/lab-15-4-lfs-migrate`: the failure with `--everything`. A second local branch was missed by the first import.

```bash
git rev-list --objects origin/main..experiment/quantized | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
git lfs migrate import --include="*.onnx" --everything
```

<!-- snippet: ch22/lab-15-4-lfs-migrate/06-failure -->
```text
# The other branch was not part of the migration:
$ git rev-list --objects origin/main..experiment/quantized | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
blob 600000 models/acoustic-int8.onnx
blob 1250000 models/acoustic.onnx
blob 1200000 models/acoustic.onnx
# A flag that promises to catch everything looks like the answer:
$ git lfs migrate import --include="*.onnx" --everything
Sorting commits: ..., done.
Rewriting commits: 100% (8/8), done.
Updating refs: ..., done.
Checkout: ..., done.
$ git status --short --branch
## main...origin/main [ahead 5, behind 1]
```
<!-- /snippet -->

A flag that promises to catch everything looks like the answer.

```bash
git log --graph --oneline --decorate --all
```

<!-- snippet: ch22/lab-15-4-lfs-migrate/07-diagnose -->
```text
$ git log --graph --oneline --decorate --all
* f074e3b (experiment/quantized) Add 8-bit quantized acoustic model
| * ca28864 (HEAD -> main) Retrain acoustic model with accents (v3)
| * 106939f Resample input to 16 kHz
|/  
* c96fc1c Retrain acoustic model on noisy audio (v2)
* 8a8e13b Add acoustic model v1
* e6c7da2 Add transcription entry point
* c66100a (origin/main, origin/HEAD) Add transcription entry point
$ git show --stat --format="%h %s" $(git rev-list --max-parents=0 main)
e6c7da2 Add transcription entry point

 .gitattributes   |  1 +
 README.md        |  3 +++
 models/vocab.txt |  4 ++++
 transcribe.py    | 12 ++++++++++++
 4 files changed, 20 insertions(+)
```
<!-- /snippet -->

Read the graph from the bottom: the root commit is now `e6c7da2`, a rewritten copy of the pushed root. The local branches no longer share a commit with `origin/main`. That is the root-cause box on screen. Not pushed yet, so the fix is in the branch reflogs; the lab walks through it.

**[TERMINAL]** The reverse rewrite. Replay `labs/run ch22/lfs-migrate-export-volatile`.

**[ON SCREEN]** "Volatile script." Export ends by pruning the local LFS store, and when the prune removes several objects, git-lfs 3.7.1 prints the name of one of them, not always the same one.

<!-- snippet: ch22/lfs-migrate-export-volatile/01-before -->
```text
$ git log --oneline
d1e8e7d Retrain acoustic model with accents (v3)
654d53c Resample input to 16 kHz
53cb32a Retrain acoustic model on noisy audio (v2)
b1b921b Add acoustic model v1
c66100a Add transcription entry point
$ git lfs ls-files
ca75f5b31e * models/acoustic.onnx
```
<!-- /snippet -->

```bash
git lfs migrate export --include="*.onnx"
```

<!-- snippet: ch22/lfs-migrate-export-volatile/02-export -->
```text
$ git lfs migrate export --include="*.onnx"
Fetching remote refs: ..., done.
Sorting commits: ..., done.
Rewriting commits: 100% (4/4), done.
Updating refs: ..., done.
Checkout: ..., done.
3 local objects, 0 retained, done.

ca75f5b31e55e3e1e51533c80135181b6d1ea30a82a2c1ab28ddd120c1a8a4f2 (1.3 MB), done.
Deleting objects: 100% (3/3), done.
```
<!-- /snippet -->

<!-- snippet: ch22/lfs-migrate-export-volatile/03-after -->
```text
$ git log --oneline
082366e Retrain acoustic model with accents (v3)
a021a3b Resample input to 16 kHz
0b68d28 Retrain acoustic model on noisy audio (v2)
6ecc8cc Add acoustic model v1
c66100a Add transcription entry point
$ cat .gitattributes
*.onnx filter=lfs diff=lfs merge=lfs -text
*.onnx !text !filter !merge !diff
$ git lfs ls-files
$ git rev-list --objects main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
blob 1300000 models/acoustic.onnx
blob 1250000 models/acoustic.onnx
blob 1200000 models/acoustic.onnx
$ find .git/lfs/objects -type f | wc -l
       0
```
<!-- /snippet -->

New commit IDs again, above the same unchanged `c66100a`. Export does not delete the tracking line; it appends a line that switches the attributes off for the pattern.

**[TERMINAL]** Now the errors. Replay `labs/run ch22/lfs-error-tracked-late`. A recording is committed first and the pattern tracked afterwards.

<!-- snippet: ch22/lfs-error-tracked-late/01-added-first -->
```text
$ git add samples/hello.wav
$ git commit -m "Add a sample recording"
[main e6d55e2] Add a sample recording
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 samples/hello.wav
$ git lfs track "*.wav"
Tracking "*.wav"
$ git add .gitattributes
$ git commit -m "Track WAV files with Git LFS"
[main 6a6a9f2] Track WAV files with Git LFS
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

```bash
git lfs ls-files
git cat-file -s HEAD:samples/hello.wav
git status --short
git lfs fsck --pointers
```

Predict what `git status` says about a file nobody edited.

<!-- snippet: ch22/lfs-error-tracked-late/02-symptom -->
```text
$ git lfs ls-files
0269885262 * models/acoustic.onnx
$ git cat-file -s HEAD:samples/hello.wav
48000
$ git status --short
 M samples/hello.wav
$ git lfs fsck --pointers
pointer: unexpectedGitObject: "samples/hello.wav" (treeish 6a6a9f24bfc3f0cbac37c4bce72464747916d954) should have been a pointer but was not
[exit status: 1]
```
<!-- /snippet -->

Three symptoms of one cause. `git lfs ls-files` does not list the recording. The blob in HEAD is 48,000 bytes, the raw file. And `git status` reports the file as modified: the attributes now say "clean this path", the clean filter turns the working tree file into a pointer, and the pointer differs from the raw blob in the index. `git lfs fsck --pointers` names the problem: "should have been a pointer but was not".

The forward fix. 🟡 CAUTION: `git add --renormalize` runs the path through the filter again and stages the result.

```bash
git add --renormalize samples/hello.wav
git diff --cached --stat
git commit -m "Store the sample recording in Git LFS"
```

<!-- snippet: ch22/lfs-error-tracked-late/03-fix-forward -->
```text
# Nothing was pushed with the plain blob as its only form, and a new commit is acceptable:
$ git add --renormalize samples/hello.wav
$ git diff --cached --stat
 samples/hello.wav | Bin 48000 -> 130 bytes
 1 file changed, 0 insertions(+), 0 deletions(-)
$ git commit -m "Store the sample recording in Git LFS"
[main 365b8a5] Store the sample recording in Git LFS
 1 file changed, 0 insertions(+), 0 deletions(-)
$ git lfs ls-files
0269885262 * models/acoustic.onnx
8a2b8ee542 * samples/hello.wav
$ git status --short
```
<!-- /snippet -->

"Bin 48000 -> 130 bytes."

```bash
git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep wav
```

<!-- snippet: ch22/lfs-error-tracked-late/04-history-still-has-it -->
```text
$ git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep wav
blob 130 samples/hello.wav
blob 48000 samples/hello.wav
```
<!-- /snippet -->

The raw blob is still in the earlier commit. For a 48 kilobyte file that is acceptable. For a file that a host would reject, use `git lfs migrate import` on the unpushed commits instead.

**[TERMINAL]** Replay `labs/run ch22/lfs-error-not-pointer`. A CI job without the filter regenerates the model and commits.

```bash
git config get filter.lfs.clean
cat .gitattributes
git commit -am "Retrain acoustic model on noisy audio (v2)"
```

<!-- snippet: ch22/lfs-error-not-pointer/01-commit-without-filter -->
```text
$ cd ci-transcriber
$ git config get filter.lfs.clean
[exit status: 1]
$ cat .gitattributes
*.onnx filter=lfs diff=lfs merge=lfs -text
$ git commit -am "Retrain acoustic model on noisy audio (v2)"
[main 28ed764] Retrain acoustic model on noisy audio (v2)
 1 file changed, 0 insertions(+), 0 deletions(-)
$ git cat-file -s HEAD:models/acoustic.onnx
1250000
$ git push origin main
To $LAB/ch22/lfs-error-not-pointer/remotes/transcriber.git
   1690072..28ed764  main -> main
```
<!-- /snippet -->

No filter, and the attribute line is there. The full 1,250,000 bytes went into Git as a blob. Asha, who has the filter, pulls.

<!-- snippet: ch22/lfs-error-not-pointer/02-symptom -->
```text
$ cd ../asha-transcriber
$ git pull
From $LAB/ch22/lfs-error-not-pointer/remotes/transcriber
   1690072..28ed764  main       -> origin/main
Updating 1690072..28ed764
Fast-forward
 models/acoustic.onnx | Bin 132 -> 1250000 bytes
 1 file changed, 0 insertions(+), 0 deletions(-)
Encountered 1 file that should have been a pointer, but wasn't:
	models/acoustic.onnx
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   models/acoustic.onnx

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

"Bin 132 -> 1250000 bytes" in the pull's summary is the first sign.

```bash
git lfs ls-files
git lfs fsck --pointers
git diff --stat
```

<!-- snippet: ch22/lfs-error-not-pointer/03-diagnose -->
```text
$ git lfs ls-files
$ git lfs fsck --pointers
pointer: unexpectedGitObject: "models/acoustic.onnx" (treeish 28ed7643fddd4cc06c6c7309d7426f7d09f86d64) should have been a pointer but was not
[exit status: 1]
$ git diff --stat
 models/acoustic.onnx | Bin 1250000 -> 132 bytes
 1 file changed, 0 insertions(+), 0 deletions(-)
```
<!-- /snippet -->

The same diagnosis as before, and the file is modified the moment it is checked out. The same fix, and the same limit: the large blob stays in the history that was pushed.

```bash
git add --renormalize models/acoustic.onnx
git commit -m "Store acoustic model v2 as an LFS pointer"
git lfs ls-files --size
git status --short
```

<!-- snippet: ch22/lfs-error-not-pointer/04-fix -->
```text
$ git add --renormalize models/acoustic.onnx
$ git commit -m "Store acoustic model v2 as an LFS pointer"
[main 6bbd888] Store acoustic model v2 as an LFS pointer
 1 file changed, 0 insertions(+), 0 deletions(-)
$ git lfs ls-files --size
f8719e1ac8 * models/acoustic.onnx (1.3 MB)
$ git status --short
```
<!-- /snippet -->

Prevention is a server-side or CI check, because the failing machine is by definition one where the local setup is missing: a job that runs `git lfs fsck --pointers` and fails on a non-zero exit status.

**[TERMINAL]** Replay `labs/run ch22/lfs-error-missing-object-volatile`.

**[ON SCREEN]** "Volatile script." The log file name in one message contains the wall-clock time.

Here the hook was skipped with `--no-verify`. The pointer is in the remote's Git history; the object exists only in the author's local store. A teammate with a correctly installed client pulls.

```bash
git lfs pull
git lfs ls-files
```

<!-- snippet: ch22/lfs-error-missing-object-volatile/01-pull-fails -->
```text
$ git lfs pull
error transferring "f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65": [0] remote missing object f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
Failed to fetch some objects from 'file://$LAB/ch22/lfs-error-missing-object-volatile/remotes/transcriber.git'
[exit status: 2]
$ git lfs ls-files
f8719e1ac8 - models/acoustic.onnx
```
<!-- /snippet -->

"remote missing object", exit status 2, and a minus in the listing. The same failure through the smudge filter:

<!-- snippet: ch22/lfs-error-missing-object-volatile/02-smudge-fails -->
```text
# The same failure through the smudge filter, when a checkout needs the file:
$ rm models/acoustic.onnx
$ git restore models/acoustic.onnx
Downloading models/acoustic.onnx (1.3 MB)
Error downloading object: models/acoustic.onnx (f8719e1): Smudge error: Error downloading models/acoustic.onnx (f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65): error transferring "f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65": [0] remote missing object f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65

Errors logged to '$LAB/ch22/lfs-error-missing-object-volatile/asha-transcriber/.git/lfs/logs/20261002T103300.970995.log'.
Use `git lfs logs last` to view the log.
error: external filter 'git-lfs filter-process' failed
fatal: models/acoustic.onnx: smudge filter lfs failed
[exit status: 128]
$ git status --short
 D models/acoustic.onnx
```
<!-- /snippet -->

"Smudge error". Because the filter is `required`, a failing smudge fails the checkout: the file is absent, not silently wrong.

```bash
git cat-file -p HEAD:models/acoustic.onnx
find ../remotes/transcriber.git/lfs/objects -type f | sort
```

<!-- snippet: ch22/lfs-error-missing-object-volatile/03-diagnose -->
```text
$ git cat-file -p HEAD:models/acoustic.onnx
version https://git-lfs.github.com/spec/v1
oid sha256:f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
size 1250000
$ find ../remotes/transcriber.git/lfs/objects -type f | sort
../remotes/transcriber.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
```
<!-- /snippet -->

The pointer names `f8719e1`. The remote's store has one file, and it is not that one. Whoever still has the object uploads it. Predict whether a plain `git lfs push origin main` does it.

```bash
git lfs push origin main
find ../remotes/transcriber.git/lfs/objects -type f | wc -l
git lfs push --all origin main
```

<!-- snippet: ch22/lfs-error-missing-object-volatile/04-fix -->
```text
# Whoever still has the object uploads it:
$ cd ../transcriber
# A plain "git lfs push origin main" sends nothing: the commit is already on origin/main,
# so the client assumes its objects are too. --all sends every object the branch references.
$ git lfs push origin main
$ find ../remotes/transcriber.git/lfs/objects -type f | wc -l
       1
$ git lfs push --all origin main
Uploading LFS objects: 100% (2/2), 0 B | 0 B/s, done.
$ find ../remotes/transcriber.git/lfs/objects -type f | wc -l
       2
$ cd ../asha-transcriber
$ git lfs pull
$ git lfs ls-files
f8719e1ac8 * models/acoustic.onnx
$ git status --short
```
<!-- /snippet -->

No. The client skips objects of commits that the remote-tracking branch already contains. `git lfs push --all origin main` sends every object the branch references. If nobody has the object any more, the pointer is permanently dangling, and the only repair is a new commit with a file that exists.

**[ON SCREEN]** Lower third: **GitHub**. Everything in this segment is platform behavior, quoted in the textbook from GitHub's documentation as read on 2 October 2026. None of it can be reproduced in the lab, and limits and prices change: the linked pages in section 22.11 are the reference.

Without LFS, the section quotes: a warning from Git for a file larger than 50 MiB; "GitHub blocks files larger than 100 MiB"; a file added through the browser "can be no larger than 25 MiB"; and repositories should "remain small, ideally less than 1 GB, and less than 5 GB is strongly recommended". It adds a cap of 2 GB for a single push. The block applies to any commit in the push that contains such a blob.

With LFS, the maximum size of one LFS file depends on the plan: 2 GB on GitHub Free and Pro, 4 GB on Team, 5 GB on Enterprise Cloud.

**[ON SCREEN]** The billing table of section 22.11.

| Fact | Consequence |
|---|---|
| Included per month: 10 GiB of storage and 10 GiB of bandwidth on Free and Pro; 250 GiB of each on Team and Enterprise Cloud | Beyond that, usage is metered and billed |
| "Previously, Git LFS billing used pre-paid data packs. These have been removed and replaced with metered billing." | Advice to "buy a data pack" is out of date |
| Every pushed version is stored in full: "If you make a 1 byte change and push the file again, you'll use another 500 MB of storage" | Storage grows with the number of versions, not with the size of the latest one |
| Downloads use bandwidth; uploads do not. Downloads by GitHub Actions count | A CI matrix that pulls the same model in every job multiplies bandwidth |
| "Bandwidth and storage usage always count against the repository owner's account"; pushes to forks count "against the parent repository's bandwidth and storage quotas" | The owner pays for what contributors and forks do |
| When the quota is used up and no payment method is on file, clones "will only retrieve the pointer files" and you "will not be able to push new files back up" | An exhausted quota looks exactly like a machine without the client |
| After removing files from LFS, "the Git LFS objects still exist on the remote storage and will continue to count toward your Git LFS storage quota"; to remove them, "delete and recreate the repository", or contact Support | Storage does not shrink when history does |

The last row is the answer to the storage-bill question.

**[ON SCREEN]** "Unverified." Per-GiB prices for metered LFS usage are not stated on the billing page that was read, and the research report behind the course records a conflict between GitHub's pricing page and its billing documentation about data packs. The textbook gives no prices, and neither does this video.

**[ON SCREEN]** The table of section 22.13: when LFS is the wrong tool.

| Situation | Why LFS is wrong | Use instead |
|---|---|---|
| Files larger than the plan's per-file cap (2 to 5 GB on GitHub) | The upload is refused | Object storage or a model registry; keep the URI and a checksum in Git |
| Training data and model weights that change with every run | Each version is stored whole and billed; nothing is ever freed | DVC, which keeps small metafiles in Git and the data in a remote you control; or a model registry, with the Git commit recorded beside each model version |
| Data that must be deletable (personal data, licensed data) | Removing a file from LFS on GitHub does not delete the object | Storage with retention and deletion controls |
| Models and datasets published for others | Consumers need the client, and your bandwidth pays for their downloads | The Hugging Face Hub, pinning the `revision` you download; or GitHub Releases for binaries that accompany a tag |
| Contributors or CI that cannot be relied on to have the client | Pointer files in place of content, silently | Any of the above; or a download step with a checksum |

The textbook notes that the versions, licences and stewardship of these tools changed during 2025 and 2026, and that the AI/ML workflows chapter gives the current facts with their sources.

## COMMON MISTAKES

1. **`git lfs track` and a new commit to fix a rejected push.** Root cause: the large blob is still in an earlier commit of the push; only `migrate import` on those commits replaces it.
2. **`migrate import --everything` to "catch the other branch".** Root cause: it puts published commits in scope, and the first rewritten commit changes the ID of every descendant, so local history no longer shares a commit with the remote.
3. **Expecting `.git` to shrink right after a migration.** Root cause: the old commits are still in the reflog and their blobs in the object database until expiry and a collection.
4. **`git lfs push origin main` to repair a missing object.** Root cause: the client skips objects of commits that the remote-tracking branch already has; `--all` sends everything the branch references.
5. **Deleting files from LFS to reduce the GitHub bill.** Root cause: according to GitHub's documentation the objects still exist on the remote storage and keep counting until the repository is deleted and recreated or Support purges them.

## PRODUCTION EXAMPLE

A speech team discovers that eleven model versions were committed as ordinary files over a year, and all of them are on the server. A new hire's first clone takes twenty minutes.

The lead treats it as a planned rewrite of published history. She runs `migrate info` with the scope she intends to use and reads the commit count aloud in the planning meeting. She stores a verified bundle of the old state. On the agreed day everyone stops pushing; she runs the import, checks the result in a fresh clone, and pushes with a lease. Everyone else re-clones, because an old clone that pushes again brings the blobs back. A CI job that runs `git lfs fsck --pointers` goes in the same week.

Then the team reads the table of section 22.13 and makes a second decision. The reference checkpoints for tests stay in LFS: a handful of files that change twice a year. The weights produced by every training run move out of Git altogether, to a store the team controls, with the Git commit recorded beside each model version. The bill had been growing because every run stored a whole new file that nothing would ever free.

## PRACTICE EXERCISE

Do Lab 15.4, "Migrate an already-committed large file", in [`lab-manual/m15-submodules-subtrees-lfs.md`](../../lab-manual/m15-submodules-subtrees-lfs.md).

Before the import, run `migrate info` and predict from its commit count which commit IDs will change and which will not. Predict the size of the working tree file right after the import, and the number of large blobs still in `.git/objects`. In the failure scenario, predict what `git status --short --branch` prints after `--everything`.

The challenge is Exercise 15.9, Level 4, "It works on your machine", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q368: "What does `git lfs migrate import` do to commit IDs, to the working tree, and to the size of `.git`? What is the default scope, and what does `--everything` add?"

Pause and answer aloud.

A strong answer treats the command as a history rewrite from its first sentence and derives the three effects from that. For commit IDs it says which change and why descendants change too. For the working tree and for the size of `.git` it gives the two facts that surprise people, each with its remedy and with a warning about when to apply the second remedy. It states the default scope precisely and explains why that default is safe. And it describes `--everything` by what it puts in scope and what that does to the relationship with the remote, ending with the preview that would have shown it.

## RECAP

You should now be able to say:

- `git lfs migrate import` rewrites the commits in scope into pointer commits with new IDs; by default the scope is the unpushed commits of the current branch.
- After an import the working tree holds a pointer until `git lfs checkout`, and `.git` shrinks only after the reflog expires and a collection runs.
- A raw blob on an LFS path is found by `git lfs fsck --pointers` and fixed forward with `git add --renormalize`; a pointer without its object is fixed by `git lfs push --all` from whoever has it.
- GitHub blocks large files by commit, stores every pushed LFS version in full, bills the repository owner, and does not free LFS storage when history is rewritten; I state the numbers from the documentation and no prices.
- LFS suits a few mid-sized binaries that change rarely; for per-run weights, deletable data and published models the textbook names other stores.

## HOMEWORK

Read sections 22.9 to 22.14 of [Chapter 22](../../textbook/ch22-git-lfs.md) and do the Practice section, 22.16.
