# V096: Git LFS day to day: status, pushing, cloning without the client, and the local store

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 15, Submodules, subtrees, Git LFS
- **Planned minutes.** 24
- **Prerequisites.** V041, V095
- **Textbook sections.** [Chapter 22](../../textbook/ch22-git-lfs.md), sections 22.5 to 22.8
- **Demo scripts.** `labs/ch22/lfs-push-volatile.sh`, `labs/ch22/lfs-clone.sh`, `labs/ch22/lfs-prune.sh`, `labs/ch22/lfs-lock.sh`

## HOOK

**[ON SCREEN]** "The training job in CI crashed while loading the weights: the file is 132 bytes and starts with the word `version`."

The job cloned the repository. The clone succeeded. `git status` in the job's checkout is clean. The model file is where the code expects it, with the right name. And the loader fails with a parse error on the first bytes of the file.

Open the file and you can read it: three lines of text. A version URL, a line that begins `oid sha256:`, and a size. It is a ticket for a coat, on a machine with no cloakroom attendant.

Nothing is wrong from Git's point of view. That is what makes this failure slow to diagnose the first time, and a ten-second diagnosis every time after.

## INTRODUCTION

In the last video you saw the two stores on one machine: Git objects with a small pointer blob, and the LFS store with the real bytes. Today the two stores travel, and they travel separately. Git objects by Git. LFS objects by the LFS client.

You will watch a push put content into a remote's LFS store; a clone on a machine without the client; the repair; downloads on demand and how to skip them; and the local store, which grows with every version until you prune it, with one warning about what the reflog does not protect.

Say this on screen now, before the first replay: the push demonstration is a volatile script. Its transcript is not compared byte for byte with a fresh run, for a reason you will see.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- read `git lfs status` and say what a push will upload;
- say where LFS objects go on push and how the endpoint is derived;
- recognize a clone made without the client by the size of its files, and repair it;
- fetch on demand and skip the smudge filter for speed;
- explain how `git lfs prune` decides what to delete and when that is unsafe.

## CONCEPT

**Day to day.** `git status` reports a modified LFS file as usual: Git ran the clean filter on the working tree file, got a different pointer, and compared it with the index. `git diff` shows the change between the two pointers, which tells a reviewer that the file changed and by how much it grew, and nothing about its content. 🟢 SAFE: `git lfs status` adds the LFS view: which objects a push would upload, and for changed files whether the index and working tree hold LFS content.

**The hooks.** `git lfs install` wrote four hooks. `pre-push` is the important one: `git lfs pre-push` uploads the LFS objects referenced by the commits about to be pushed, before Git sends the commits. The other three exist for file locking. Two consequences of the upload living in a hook, both of which you can predict from the hooks videos: `git push --no-verify` skips it, and a repository whose `core.hooksPath` points elsewhere does not run it unless the LFS hook was installed there.

**Where the objects go.** The LFS client derives its server from the Git remote. For an HTTPS or SSH remote it appends `/info/lfs` to the repository URL and talks to an HTTP API there; `lfs.url`, or a committed `.lfsconfig` file, can point it elsewhere. For the lab's path remote it resolves a `file://` endpoint and uses a built-in standalone file adapter, which copies objects into an `lfs/objects` directory inside the bare repository.

**Cloning without the client.** `.gitattributes` names a filter called `lfs`. On a machine where no such filter is defined, an undefined filter is a no-op. The clone succeeds, `git status` is clean, and the file in the working tree is the pointer. The textbook quotes GitHub's documentation on collaborators without the client: they "will only fetch the pointer files, and won't have access to any of the actual data".

**The repair, in two halves.** 🟢 SAFE: `git lfs fetch` downloads the objects that the current commit needs into the local store. 🟢 SAFE: `git lfs checkout` replaces pointer files in the working tree with content from the local store, and never overwrites a modified file, so nothing is lost and no ref moves. `git lfs pull` is the two together.

On a machine where the filter is configured before the clone, none of these commands is needed: the smudge filter downloads each object as the checkout writes each file, and again on any later checkout that needs a version not yet in the local store.

**Skipping.** With the environment variable `GIT_LFS_SKIP_SMUDGE` set to 1, the smudge filter passes pointers through untouched. `git lfs install --skip-smudge` makes this the permanent behavior of a configuration, and `git lfs pull --include`, or the settings `lfs.fetchinclude` and `lfs.fetchexclude`, fetch a subset.

**The local store.** Every version you have added or checked out stays in `.git/lfs/objects`. `git gc` does not touch it. 🟡 CAUTION: `git lfs prune` deletes local objects that the current checkout does not need, that are not "recent", and that have been pushed. `--dry-run --verbose` previews. `--verify-remote` asks the remote whether it really has each object before deleting the local copy.

"Recent" is defined by settings such as `lfs.fetchrecentrefsdays`, 7 days, plus `lfs.pruneoffsetdays`, 3 days, measured against the real clock. The lab's commits are dated 7 September 2026, so in the replay they are never recent; in a repository with fresh commits, `prune` keeps more than the transcript suggests.

And the warning. The help text of `git lfs prune` states: "The reflog is not considered, only commits. Therefore LFS objects that are only referenced by orphaned commits are always deleted." A model version that only an abandoned commit refers to is not protected by Git's reflog safety net.

## MENTAL MODEL

Keep the coat check. Today there are two buildings, your laptop and the server, and each has a ticket desk and a cloakroom.

Tickets move between the ticket desks whenever Git pushes or fetches. Coats move between the cloakrooms only when the LFS client carries them. On a push, the client carries the coats first and Git sends the tickets after. On a checkout, the smudge filter reads a ticket and fetches that one coat if the local cloakroom does not have it.

A machine without the client has a ticket desk and no cloakroom staff. It receives every ticket and no coat, and nothing complains.

The analogy needs one correction for pruning. A cloakroom clears out coats that are also stored at the other building and that nobody is wearing. It does not look at your old ticket stubs in the wastepaper basket: commits that only the reflog remembers do not count as "someone needs this".

## DIAGRAM

**[DIAGRAM]** Laptop and server, each with two stores, and a separate arrow for each kind of transfer.

```text
   LAPTOP                                                         SERVER  (bare repository)
  +-------------------------------------------+                  +-------------------------------------------+
  | Git objects  (.git/objects)               |   git push       | Git objects                               |
  |   commits, trees, pointer blob (132 bytes)| ---------------> |   commits, trees, pointer blob (132 bytes)|
  |                                           | <--------------- |                                           |
  |                                           |   git fetch      |                                           |
  +-------------------------------------------+                  +-------------------------------------------+
  | LFS store  (.git/lfs/objects)             |  git lfs pre-push| LFS store  (lfs/objects beside the         |
  |   one file per version, named by SHA-256  | ---------------> |   repository; a separate service on a host)|
  |                                           | <--------------- |   one file per version                    |
  |                                           |  smudge filter,  |                                           |
  |                                           |  git lfs fetch   |                                           |
  +-------------------------------------------+                  +-------------------------------------------+

   a machine WITHOUT the LFS client uses only the top pair of arrows: it receives pointers and no content
```

The top pair of arrows is Git. The bottom pair is the LFS client: the `pre-push` hook on the way up, the smudge filter or `git lfs fetch` on the way down. The last line of the diagram is the hook of this video.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch22/lfs-push-volatile`.

**[ON SCREEN]** "Volatile script." The textbook marks this demo volatile for one line: with git-lfs 3.7.1 and a file remote, the progress meter printed nothing in about one push out of ten in the authors' runs, although the upload happened each time. Your output for that line may differ.

```bash
git remote get-url origin
git lfs env | grep -e ^Endpoint -e Transfers
```

<!-- snippet: ch22/lfs-push-volatile/01-endpoint -->
```text
$ git remote get-url origin
$LAB/ch22/lfs-push-volatile/remotes/transcriber.git
$ git lfs env | grep -e ^Endpoint -e Transfers
Endpoint=file://$LAB/ch22/lfs-push-volatile/remotes/transcriber.git (auth=none)
ConcurrentTransfers=8
TusTransfers=false
BasicTransfersOnly=false
DownloadTransfers=basic,lfs-standalone-file,ssh
UploadTransfers=basic,lfs-standalone-file,ssh
```
<!-- /snippet -->

The endpoint is derived from the remote: here a `file://` URL, with the transfer adapter `lfs-standalone-file` in the list. For an HTTPS or SSH remote it would be the repository URL with `/info/lfs` appended.

**[ON SCREEN]** 🟡 CAUTION: `git push`. In a repository with the LFS hook, LFS objects are uploaded first, then the commits with pointer blobs. Predict what `git lfs status` lists under "to be pushed".

```bash
git lfs status
git push origin main
```

<!-- snippet: ch22/lfs-push-volatile/02-push -->
```text
$ git lfs status
On branch main
Objects to be pushed to origin/main:

	models/acoustic.onnx (f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65)

Objects to be committed:


Objects not staged for commit:


$ git push origin main
Uploading LFS objects: 100% (1/1), 0 B | 0 B/s, done.
To $LAB/ch22/lfs-push-volatile/remotes/transcriber.git
   1690072..98ef746  main -> main
```
<!-- /snippet -->

The line "Uploading LFS objects" is printed by the `pre-push` hook, before Git's own output. The "0 B" is an artifact of the file adapter, which does not report bytes.

```bash
git -C ../remotes/transcriber.git cat-file -s main:models/acoustic.onnx
find ../remotes/transcriber.git/lfs/objects -type f | sort
```

<!-- snippet: ch22/lfs-push-volatile/03-remote-store -->
```text
# The remote Git repository received a pointer blob:
$ git -C ../remotes/transcriber.git cat-file -s main:models/acoustic.onnx
132
# The bytes are in the LFS store beside it, one file per version, named by SHA-256:
$ find ../remotes/transcriber.git/lfs/objects -type f | sort
../remotes/transcriber.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
../remotes/transcriber.git/lfs/objects/f8/71/f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
```
<!-- /snippet -->

The remote now has two stores, like your clone. Git objects, with a 132-byte blob for the path. And an LFS directory with one full file per version, named by SHA-256.

**[ON SCREEN]** Lower third: **GitHub**. On GitHub the second store is a separate storage service with its own quota; each uploaded object counts against the repository owner's LFS storage. That is described from the documentation and is the subject of the next video.

One thing a file remote cannot do. Replay `labs/run ch22/lfs-lock`.

```bash
git lfs lock models/acoustic.onnx
```

<!-- snippet: ch22/lfs-lock/01-lock-needs-a-server -->
```text
$ git lfs lock models/acoustic.onnx

hint: The remote resolves to a file:// URL, which can only work with a
hint: standalone transfer agent.  See section "Using a Custom Transfer Type
hint: without the API server" in custom-transfers.md for details.
Locking models/acoustic.onnx failed: missing protocol: "file://$LAB/ch22/lfs-lock/remotes/transcriber.git"
[exit status: 2]
```
<!-- /snippet -->

Locking is a server feature and was not run for the book. It exists because binary files cannot be merged: two people who edit the same model in parallel produce a conflict that only one of them can win.

**[TERMINAL]** Replay `labs/run ch22/lfs-clone`. The lab's configuration has no LFS filter, which makes it behave like a laptop, a container or a CI runner where `git lfs install` was never run.

**[PAUSE]** Predict three things about this clone: whether it succeeds, what `git status` says, and how many bytes the model file has.

```bash
git config get filter.lfs.smudge
git clone remotes/transcriber.git ravi-transcriber
cd ravi-transcriber
cat models/acoustic.onnx
git status --short --branch
```

<!-- snippet: ch22/lfs-clone/01-clone-without-client -->
```text
# The lab configuration has no LFS filter, like a machine where git-lfs was never set up:
$ git config get filter.lfs.smudge
[exit status: 1]
$ git clone remotes/transcriber.git ravi-transcriber
Cloning into 'ravi-transcriber'...
done.
$ cd ravi-transcriber
$ cat models/acoustic.onnx
version https://git-lfs.github.com/spec/v1
oid sha256:f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
size 1250000
$ git status --short --branch
## main...origin/main
```
<!-- /snippet -->

The clone succeeds. The model file is the pointer: three lines of text, 132 bytes, where the model should be. `git status` is clean.

**[ON SCREEN]** "Root cause", as the textbook states it: a program that crashes on a file beginning with `version https://git-lfs.github.com/spec/v1` is reading an LFS pointer. The first diagnostic is `head -c 200` on the file. The second is `git lfs ls-files`, where a minus sign marks a path whose working tree file is still a pointer.

```bash
git lfs ls-files
git lfs pull
find .git/lfs -type f
```

<!-- snippet: ch22/lfs-clone/02-what-is-missing -->
```text
$ git lfs ls-files
f8719e1ac8 - models/acoustic.onnx
$ git lfs pull
Skipping object checkout, Git LFS is not installed for this repository.
Consider installing it with 'git lfs install'.
$ find .git/lfs -type f
.git/lfs/objects/f8/71/f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
```
<!-- /snippet -->

A minus sign. And look at what `git lfs pull` did: it downloaded the object into the local store, and then declined to touch the working tree, "Git LFS is not installed for this repository". Now the repair, one piece at a time.

```bash
git lfs install --local
git lfs fetch
find .git/lfs/objects -type f
wc -c models/acoustic.onnx
git lfs checkout
wc -c models/acoustic.onnx
git lfs ls-files
```

<!-- snippet: ch22/lfs-clone/03-install-fetch-checkout -->
```text
$ git lfs install --local
Updated Git hooks.
Git LFS initialized.
$ git lfs fetch
Fetching reference refs/heads/main
$ find .git/lfs/objects -type f
.git/lfs/objects/f8/71/f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
$ wc -c models/acoustic.onnx
     132 models/acoustic.onnx
$ git lfs checkout
Checking out LFS objects: 100% (1/1), 1.3 MB | 0 B/s, done.
$ wc -c models/acoustic.onnx
 1250000 models/acoustic.onnx
$ git lfs ls-files
f8719e1ac8 * models/acoustic.onnx
$ git status --short
```
<!-- /snippet -->

After `fetch`, the object is in the store and the file is still 132 bytes. After `checkout`, the file has its real size and the marker is an asterisk.

With the filter configured, a checkout that needs another version downloads it.

```bash
git switch --detach HEAD~1
git lfs ls-files --size
find .git/lfs/objects -type f | sort
git switch -
```

<!-- snippet: ch22/lfs-clone/04-smudge-on-demand -->
```text
# With the filter configured, a checkout that needs another version downloads it:
$ git switch --detach HEAD~1
HEAD is now at 1690072 Add acoustic model v1
$ git lfs ls-files --size
0269885262 * models/acoustic.onnx (1.2 MB)
$ find .git/lfs/objects -type f | sort
.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
.git/lfs/objects/f8/71/f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
$ git switch -
Previous HEAD position was 1690072 Add acoustic model v1
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```
<!-- /snippet -->

The older version, `0269885262`, arrived in the local store at the moment the checkout needed it. Now skip it on purpose.

```bash
GIT_LFS_SKIP_SMUDGE=1 git switch --detach HEAD~1
cat models/acoustic.onnx
git lfs ls-files
git status --short
```

<!-- snippet: ch22/lfs-clone/05-skip-smudge -->
```text
$ GIT_LFS_SKIP_SMUDGE=1 git switch --detach HEAD~1
HEAD is now at 1690072 Add acoustic model v1
$ cat models/acoustic.onnx
version https://git-lfs.github.com/spec/v1
oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
size 1200000
$ git lfs ls-files
0269885262 - models/acoustic.onnx
$ git status --short
# git lfs pull replaces the pointers of the current commit with content:
$ git lfs pull
$ git lfs ls-files
0269885262 * models/acoustic.onnx
$ git switch -
Previous HEAD position was 1690072 Add acoustic model v1
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```
<!-- /snippet -->

A pointer in the working tree, a minus in the listing, and a clean status: the clean filter recognises a pointer and passes it through unchanged, so the file matches the index. This is how a job that does not need the large files avoids downloading them.

**[ON SCREEN]** Lower third: **GitHub Actions**. Not run for the book. The textbook states that `actions/checkout` downloads LFS files only when its `lfs` input is `true`, and that the default is `false`. A job with the default therefore sees pointers. A job with `lfs: true` downloads objects, which GitHub's billing page counts as bandwidth; the textbook quotes it: "If GitHub Actions downloads a 500 MB file that is tracked with Git LFS, it will use 500 MB of the repository owner's bandwidth".

**[TERMINAL]** Replay `labs/run ch22/lfs-prune`. The local store.

```bash
git lfs ls-files --all --size
find .git/lfs/objects -type f | sort
```

<!-- snippet: ch22/lfs-prune/01-store -->
```text
$ git lfs ls-files --all --size
f8719e1ac8 * models/acoustic.onnx (1.3 MB)
0269885262 - models/acoustic.onnx (1.2 MB)
$ find .git/lfs/objects -type f | sort
.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
.git/lfs/objects/f8/71/f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
```
<!-- /snippet -->

Two versions in the store; one is checked out.

**[ON SCREEN]** 🟡 CAUTION: `git lfs prune`. Preview with `--dry-run --verbose`; use `--verify-remote` to have the remote confirm each object before the local copy is deleted.

```bash
git lfs prune --dry-run --verbose
git lfs prune --verify-remote
find .git/lfs/objects -type f | sort
```

<!-- snippet: ch22/lfs-prune/02-prune -->
```text
$ git lfs prune --dry-run --verbose
2 local objects, 1 retained, done.

 * 02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de (1.2 MB), done.
$ git lfs prune --verify-remote
2 local objects, 1 retained, 1 verified with remote, done.
Deleting objects: 100% (1/1), done.
$ find .git/lfs/objects -type f | sort
.git/lfs/objects/f8/71/f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
```
<!-- /snippet -->

Two local objects, one retained, one verified with the remote and deleted. A pruned object is not lost as long as the remote has it.

```bash
git lfs fetch --all
find .git/lfs/objects -type f | sort
git lfs fsck
```

<!-- snippet: ch22/lfs-prune/03-fetch-again -->
```text
# The pruned version is still on the remote. Anything that needs it downloads it again:
$ git lfs fetch --all
2 objects found, done.
Fetching all references...
$ find .git/lfs/objects -type f | sort
.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
.git/lfs/objects/f8/71/f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
$ git lfs fsck
Git LFS fsck OK
```
<!-- /snippet -->

`git lfs fetch --all` downloads every object referenced by any commit, which is what a backup or a migration to another host needs. `git lfs fsck` verifies that the files in the local store match their hashes.

Now two more versions, committed and not pushed. Predict what `prune` deletes.

<!-- snippet: ch22/lfs-prune/04-unpushed-is-kept -->
```text
# Two more versions, committed and not pushed. v3 is no longer checked out:
$ git status --short --branch
## main...origin/main [ahead 2]
$ find .git/lfs/objects -type f | sort
.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
.git/lfs/objects/ca/75/ca75f5b31e55e3e1e51533c80135181b6d1ea30a82a2c1ab28ddd120c1a8a4f2
.git/lfs/objects/eb/60/eb606cc995d11405ec792073ee6b8668916a61d453a17686d3178c86ffa022bd
.git/lfs/objects/f8/71/f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
$ git lfs prune
4 local objects, 2 retained, done.
Deleting objects: 100% (2/2), done.
$ find .git/lfs/objects -type f | sort
.git/lfs/objects/ca/75/ca75f5b31e55e3e1e51533c80135181b6d1ea30a82a2c1ab28ddd120c1a8a4f2
.git/lfs/objects/eb/60/eb606cc995d11405ec792073ee6b8668916a61d453a17686d3178c86ffa022bd
```
<!-- /snippet -->

The two pushed versions were deleted. The two unpushed ones stayed, including the one that is not checked out. `prune` refuses to delete what exists only on your machine, as long as a commit on a ref refers to it. Remember the exception from the help text: the reflog is not considered.

## COMMON MISTAKES

1. **Debugging the model loader when the file is 132 bytes.** Root cause: the checkout ran without an LFS filter, so the working tree holds the pointer; `head -c 200` and `git lfs ls-files` show it at once.
2. **`git push --no-verify` in an LFS repository.** Root cause: the upload of LFS objects is done by the `pre-push` hook, which that option skips; the pointers go and the content stays behind.
3. **Expecting `git lfs pull` to fix a clone that has no filter configured.** Root cause: it downloads into the local store and declines to touch the working tree until `git lfs install` has run for that repository.
4. **Treating `git gc` as cleanup for model versions.** Root cause: the LFS store is not part of the object database; only `git lfs prune` removes from it.
5. **Pruning after a reset or an amend and expecting the reflog to save the old model version.** Root cause: `git lfs prune` considers commits on refs only; objects referenced solely by orphaned commits are always deleted.

## PRODUCTION EXAMPLE

A speech team's CI has two kinds of job. The lint and unit-test jobs do not load the acoustic model; they run with the default checkout and see pointers, which costs no LFS bandwidth. The evaluation job loads the model; its checkout asks for LFS content.

One week the evaluation job fails with a parse error in the model loader. The engineer on call runs two commands in the job's workspace before reading any Python: the first two hundred bytes of the model file, and `git lfs ls-files`. The file starts with the word "version" and the listing shows a minus sign. Somebody had copied the lint job's checkout step into the evaluation job. The fix is one line in the workflow. The team then adds a guard to the evaluation script itself: it refuses to start if the model file begins with the LFS version line, and says why.

## PRACTICE EXERCISE

Do Exercise 15.8, Level 3, "A model file of 131 bytes", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Before you run a diagnostic, write down what you expect each of these to print in the broken checkout: the first bytes of the file, `git status`, `git lfs ls-files`, and `git config get filter.lfs.smudge`. Then repair it in two separate steps and predict the file size after each.

The challenge is Exercise 15.9, Level 4, "It works on your machine", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q360: "A CI job fails because a model file is 132 bytes. Give the root cause, two diagnostics, and the fix for GitHub Actions."

Pause and answer aloud.

A strong answer names what the 132 bytes are and explains, from how filters behave when undefined, why the clone succeeded and nothing warned anyone. The two diagnostics are cheap, read-only, and each says what output confirms the cause. The fix names the layer it belongs to, GitHub Actions and not Git, and the specific input of the checkout step, and it mentions the cost that the fix introduces and how jobs that do not need the content avoid it. A complete answer also proposes a guard so that the next occurrence fails with a clear message.

## RECAP

You should now be able to say:

- `git lfs status` shows what a push will upload; the upload is done by the `pre-push` hook before Git sends the commits.
- The LFS endpoint is derived from the Git remote, and the remote has two stores as my clone does.
- A checkout without the LFS filter holds pointer files, and Git reports nothing wrong; `git lfs ls-files` marks them with a minus.
- `git lfs fetch` fills the local store and `git lfs checkout` replaces pointers; `GIT_LFS_SKIP_SMUDGE=1` skips downloads.
- `git lfs prune` deletes pushed, non-recent objects that the checkout does not need, and it does not consider the reflog.

## HOMEWORK

Read sections 22.5 to 22.8 of [Chapter 22](../../textbook/ch22-git-lfs.md).
