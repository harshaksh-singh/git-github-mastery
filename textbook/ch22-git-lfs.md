# Chapter 22: Git LFS

> **Baseline.** Git 2.55.0 and git-lfs 3.7.1 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch22/`.

## 22.1 Why this matters

Questions that reach a CTO's desk in an AI/ML team:

1. "The push to GitHub was rejected because of a model file. I deleted the file and committed. It is still rejected. Why?"
2. "The clone takes twenty minutes and the repository holds four hundred lines of Python."
3. "The training job in CI crashed while loading the weights: the file is 132 bytes and starts with the word `version`."
4. "Our storage bill for this repository keeps growing, and nobody has added a model in months."

The first two are Git doing what it was designed to do with content it was not designed for. The third is Git LFS working as designed on a machine that does not have it. The fourth is how GitHub accounts for LFS. To answer any of them you need to know what LFS stores where.

Git LFS (Large File Storage) is not part of Git. It is a separate program, `git-lfs`, that plugs into Git through two mechanisms you already know from [Chapter 14C](ch14c-stash-rerere-attributes-hooks.md): a clean and smudge filter selected by `.gitattributes`, and hooks. This chapter does not repeat how filters and attributes work; it shows what this particular filter does.

The project is `transcriber`, a speech-to-text service: a little code and one acoustic model file, `models/acoustic.onnx`. The lab uses stand-in files of 1.2 to 1.3 MB so that the demos run in a second; real models are a thousand times larger and behave the same.

**What was run, and what was not.** The remote in this chapter is a bare repository reached through a file path, which git-lfs 3.7.1 supports with a built-in transfer adapter. Tracking, pushing, cloning, fetching, pruning and migrating are therefore real transcripts; four demos are marked volatile, for reasons given where they appear. Anything that needs an LFS server could not be run: the HTTP API, authentication, file locking, and all GitHub limits and billing. Those parts are described from the documentation and labelled.

## 22.2 Why LFS exists

**In one sentence.** Git keeps every version of every file forever and gives every clone all of them, which is right for source code and ruinous for large binaries that change.

**See it.** Three versions of the model were committed as ordinary files:

<!-- snippet: ch22/why-lfs/01-three-versions -->
```text
$ git log --oneline
8b13104 Retrain acoustic model with accents (v3)
1ddbfc0 Resample input to 16 kHz
65c2188 Retrain acoustic model on noisy audio (v2)
f9e56b8 Add acoustic model v1
c66100a Add transcription entry point
$ wc -c models/acoustic.onnx
 1300000 models/acoustic.onnx
# Every blob that any commit reaches, with its size in bytes:
$ git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep blob
blob 68 README.md
blob 1300000 models/acoustic.onnx
blob 14 models/vocab.txt
blob 231 transcribe.py
blob 1250000 models/acoustic.onnx
blob 198 transcribe.py
blob 1200000 models/acoustic.onnx
```
<!-- /snippet -->

The working tree has one model of 1.3 MB. The repository has three blobs, one per version, each stored whole. [Chapter 3](ch03-git-internals.md) showed that packfiles store similar objects as deltas; that helps when versions share long runs of bytes. Retrained weights, compressed archives, images and audio share almost nothing from one version to the next, so each version costs its full size, and zlib cannot shrink data that is already dense.

<!-- snippet: ch22/why-lfs/02-clone-gets-all -->
```text
$ git push origin main
To $LAB/ch22/why-lfs/remotes/transcriber.git
   c66100a..8b13104  main -> main
$ cd ..
$ git clone remotes/transcriber.git ravi-transcriber
Cloning into 'ravi-transcriber'...
done.
$ cd ravi-transcriber
# One model file in the working tree, three in the repository:
$ ls models
acoustic.onnx
vocab.txt
$ git cat-file --batch-all-objects --batch-check="%(objecttype) %(objectsize)" | grep -c -E "blob [0-9]{7}"
3
```
<!-- /snippet -->

A teammate's clone downloads all three, to check out one. The cost grows with the number of versions, and it is paid again by every clone and every CI job.

<!-- snippet: ch22/why-lfs/03-delete-does-not-help -->
```text
$ git rm --quiet models/acoustic.onnx
$ git commit -m "Remove the model from the repository"
[main 09c8ef8] Remove the model from the repository
 1 file changed, 0 insertions(+), 0 deletions(-)
 delete mode 100644 models/acoustic.onnx
$ git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
blob 1300000 models/acoustic.onnx
blob 1250000 models/acoustic.onnx
blob 1200000 models/acoustic.onnx
```
<!-- /snippet -->

Deleting the file adds a commit. The three blobs are still reachable from the earlier commits, which is the answer to question 1: a hosting platform that rejects a large blob rejects it because it is in a commit being pushed, not because it is in the latest tree. Only a history rewrite removes it (section 22.9, and [Chapter 13](ch13-recovery.md) for rewrites in general).

LFS changes one thing: Git stores a small text file in place of the binary, and the binary goes to a separate store that is downloaded per version, on demand.

## 22.3 The pointer file and the two filters

**In one sentence.** For a path that is tracked by LFS, the blob in Git is a three-line pointer containing the SHA-256 and the size of the real content, and the real content lives in an LFS object store, locally under `.git/lfs/objects` and remotely beside the Git repository.

**Analogy.** A coat check. You hand over the coat and carry a numbered ticket; the ticket goes wherever you go, and the coat stays in the cloakroom until someone presents the ticket. Git history carries tickets. The analogy breaks in two places: the number on the ticket is computed from the coat itself, so the same content always gets the same ticket, and a ticket can be copied to a place that has no cloakroom attendant, where it is only a piece of paper.

**Precisely.** Two filter commands do the exchange ([specification](https://github.com/git-lfs/git-lfs/blob/main/docs/spec.md)):

- **clean**, run by `git add`: reads the file content, computes its SHA-256, stores the content in `.git/lfs/objects/<first two hex digits>/<next two>/<full hash>`, and hands Git the pointer text. Git hashes and stores the pointer as a blob.
- **smudge**, run by checkout: reads the pointer from the blob, finds the object in the local store, downloads it from the remote if it is not there, and writes the real content into the working tree.

The pointer format is fixed by the specification: UTF-8 text, one `key value` pair per line, `version` first and the other keys in alphabetical order, less than 1024 bytes in total. The required keys are `version`, `oid` (with the hash method as prefix) and `size`.

**Set it up.** `git lfs install` normally writes the filter definition into your global configuration and installs hooks in the current repository. In this book it is always run with 🟢 `--local`, which writes the definition into the repository's own `.git/config` and nothing anywhere else:

<!-- snippet: ch22/lfs-pointer/01-install -->
```text
$ git lfs version
git-lfs/3.7.1 (GitHub; darwin arm64; go 1.25.3)
$ git lfs install --local
Updated Git hooks.
Git LFS initialized.
$ git config list --local | grep -e ^filter -e ^lfs | sort
filter.lfs.clean=git-lfs clean -- %f
filter.lfs.process=git-lfs filter-process
filter.lfs.required=true
filter.lfs.smudge=git-lfs smudge -- %f
lfs.repositoryformatversion=0
$ ls .git/hooks | grep -v sample
post-checkout
post-commit
post-merge
pre-push
```
<!-- /snippet -->

`filter.lfs.required=true` is the setting [Chapter 14C](ch14c-stash-rerere-attributes-hooks.md) described for filters whose stored form is unusable by itself: if the filter fails, the Git command fails. `filter.lfs.process` is the long-running variant that handles all files of one command in a single process. The four hooks are covered in section 22.5. (The lines are sorted for the transcript; git-lfs writes the four `filter` keys in an order that changes from run to run.)

The filter definition says how to convert. `.gitattributes` says which paths get converted. 🟢 `git lfs track` writes that line:

<!-- snippet: ch22/lfs-pointer/02-track -->
```text
$ git lfs track "*.onnx"
Tracking "*.onnx"
$ cat .gitattributes
*.onnx filter=lfs diff=lfs merge=lfs -text
$ git lfs track
Listing tracked patterns
    *.onnx (.gitattributes)
Listing excluded patterns
$ git check-attr filter diff merge text -- models/acoustic.onnx
models/acoustic.onnx: filter: lfs
models/acoustic.onnx: diff: lfs
models/acoustic.onnx: merge: lfs
models/acoustic.onnx: text: unset
$ git check-attr filter -- models/vocab.txt
models/vocab.txt: filter: unspecified
```
<!-- /snippet -->

**See it.** Add a model of 1,200,000 bytes and commit it together with `.gitattributes`:

<!-- snippet: ch22/lfs-pointer/03-commit -->
```text
$ wc -c models/acoustic.onnx
 1200000 models/acoustic.onnx
$ shasum -a 256 models/acoustic.onnx
02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de  models/acoustic.onnx
$ git add .gitattributes models/acoustic.onnx
$ git commit -m "Add acoustic model v1, tracked with Git LFS"
[main 26caf87] Add acoustic model v1, tracked with Git LFS
 2 files changed, 4 insertions(+)
 create mode 100644 .gitattributes
 create mode 100644 models/acoustic.onnx
```
<!-- /snippet -->
<!-- snippet: ch22/lfs-pointer/04-pointer -->
```text
# What Git stored for the path:
$ git cat-file -p HEAD:models/acoustic.onnx
version https://git-lfs.github.com/spec/v1
oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
size 1200000
$ git cat-file -s HEAD:models/acoustic.onnx
132
# What is in the working tree:
$ wc -c models/acoustic.onnx
 1200000 models/acoustic.onnx
```
<!-- /snippet -->

The blob that Git stored is 132 bytes of text. Its `oid` is the SHA-256 that `shasum` printed for the file, and its `size` is the file's size. The working tree still has the real file: the clean filter changes what goes into the repository, not what is on your disk.

**Inside `.git`.**

<!-- snippet: ch22/lfs-pointer/05-local-store -->
```text
$ find .git/lfs/objects -type f
.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
$ git lfs ls-files
0269885262 * models/acoustic.onnx
$ git lfs ls-files --long --size
02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de * models/acoustic.onnx (1.2 MB)
$ git lfs pointer --file=models/acoustic.onnx
Git LFS pointer for models/acoustic.onnx

version https://git-lfs.github.com/spec/v1
oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
size 1200000
```
<!-- /snippet -->

The content is in `.git/lfs/objects/`, in a file named by its own SHA-256. It is not a Git object: `git cat-file`, `git fsck`, `git gc` and `git push` know nothing about it. `git lfs ls-files` lists the LFS-tracked paths of the current commit; the `*` means the working tree file holds the real content, and a `-` would mean it holds a pointer. `git lfs pointer --file` computes the pointer for a file without storing anything, which is a quick way to check what a file's pointer should be.

**Picture.**

```text
   working tree                 index and commits (Git objects)          LFS store
  +---------------------+       +-------------------------------+       +---------------------------+
  | models/acoustic.onnx|       | blob 1097a4b  (132 bytes)     |       | .git/lfs/objects/02/69/   |
  | 1,200,000 bytes     | clean | version https://git-lfs...    | oid   |   0269885262...e8de       |
  |                     | ----> | oid sha256:0269885262...      | ----> |   1,200,000 bytes         |
  |                     | <---- | size 1200000                  | <---- |                           |
  +---------------------+ smudge+-------------------------------+       +---------------------------+
                                   travels with git push / fetch          travels with git lfs
                                                                          (pre-push hook, smudge, pull)
```

**In production.** A repository holds an evaluation harness and three reference checkpoints of a few hundred megabytes that change twice a year. With LFS, a clone downloads the code and the pointers at once and each checkpoint only when a checkout needs it, and a CI job that does not need the checkpoints can skip them (section 22.7).

State table for `git add` and `git commit` of an LFS-tracked file:

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged (real content) | entry for the path names a pointer blob | new commit on `git commit` | advanced on `git commit` | pointer blob in `.git/objects`; real content in `.git/lfs/objects` | unchanged until pushed | unchanged until pushed |

## 22.4 The `.gitattributes` line, and what tracking does not do

```text
*.onnx filter=lfs diff=lfs merge=lfs -text
```

| Attribute | Effect |
|---|---|
| `filter=lfs` | Run the `lfs` clean and smudge filter for matching paths. This is the attribute that matters. |
| `diff=lfs` | Use a diff driver named `lfs`. `git lfs install` defines none, so `git diff` shows the difference between pointers (section 22.5). |
| `merge=lfs` | Use a merge driver named `lfs`. None is defined either, so Git merges the pointers as text. When two branches each commit a new version, the merge stops with conflict markers around the `oid` and `size` lines of the pointer; `git checkout --theirs <path>` or `--ours`, then `git add`, picks one version (run for this chapter, no transcript printed). |
| `-text` | Never apply line-ending conversion ([Chapter 14C](ch14c-stash-rerere-attributes-hooks.md), section 14C.5). |

Rules that follow from this being an ordinary attributes file:

- **Commit `.gitattributes`.** It is the only part of the setup that travels with the repository. The filter definition is local configuration and the hooks are local files; a clone gets neither ([Chapter 14C](ch14c-stash-rerere-attributes-hooks.md), section 14C.4).
- **Patterns follow gitignore syntax.** Quote them in the shell (`"*.onnx"`), or the shell expands the pattern to the files that exist today and `git lfs track` records those names.
- **Tracking applies from the next `git add`.** `git lfs track` edits a text file. It does not convert a file that is already in the index or in history; section 22.10 shows the symptom, and section 22.9 the conversion.

## 22.5 Day to day: status, diff, and the hooks

A new version of the model, not yet staged:

<!-- snippet: ch22/lfs-pointer/06-new-version -->
```text
$ git status --short
 M models/acoustic.onnx
$ git diff
diff --git a/models/acoustic.onnx b/models/acoustic.onnx
index 1097a4b..366f6ac 100644
--- a/models/acoustic.onnx
+++ b/models/acoustic.onnx
@@ -1,3 +1,3 @@
 version https://git-lfs.github.com/spec/v1
-oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
-size 1200000
+oid sha256:f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65
+size 1250000
$ git lfs status
On branch main
Objects to be pushed to origin/main:

	models/acoustic.onnx (02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de)

Objects to be committed:


Objects not staged for commit:

	models/acoustic.onnx (LFS: 0269885 -> File: f8719e1)
```
<!-- /snippet -->

`git status` reports a modified file as usual: Git ran the clean filter on the working tree file, got a different pointer, and compared it with the index. `git diff` shows the change between the two pointers, which tells a reviewer that the file changed and by how much it grew, and nothing about its content. 🟢 `git lfs status` adds the LFS view: which objects a push would upload, and for changed files whether the index and working tree hold LFS content.

`git lfs install` wrote four hooks. Each is two lines:

<!-- snippet: ch22/lfs-pointer/07-hook -->
```text
$ cat .git/hooks/pre-push
#!/bin/sh
command -v git-lfs >/dev/null 2>&1 || { printf >&2 "\n%s\n\n" "This repository is configured for Git LFS but 'git-lfs' was not found on your path. If you no longer wish to use Git LFS, remove this hook by deleting the 'pre-push' file in the hooks directory (set by 'core.hookspath'; usually '.git/hooks')."; exit 2; }
git lfs pre-push "$@"
$ cat .git/hooks/post-checkout
#!/bin/sh
command -v git-lfs >/dev/null 2>&1 || { printf >&2 "\n%s\n\n" "This repository is configured for Git LFS but 'git-lfs' was not found on your path. If you no longer wish to use Git LFS, remove this hook by deleting the 'post-checkout' file in the hooks directory (set by 'core.hookspath'; usually '.git/hooks')."; exit 2; }
git lfs post-checkout "$@"
```
<!-- /snippet -->

`pre-push` is the important one: `git lfs pre-push` uploads the LFS objects referenced by the commits about to be pushed, before Git sends the commits. The other three exist for file locking. The first line of each hook is the source of a message people meet on machines without the client: "This repository is configured for Git LFS but 'git-lfs' was not found on your path."

Two consequences of the upload living in a hook ([Chapter 14C](ch14c-stash-rerere-attributes-hooks.md), section 14C.11): `git push --no-verify` skips it, and a repository whose `core.hooksPath` points elsewhere does not run it unless the LFS hook was installed there.

## 22.6 Pushing, and where the objects go

The LFS client derives its server from the Git remote. For an HTTPS or SSH remote it appends `/info/lfs` to the repository URL and talks to an HTTP API there ([server discovery](https://github.com/git-lfs/git-lfs/blob/main/docs/api/server-discovery.md)); `lfs.url`, or a committed `.lfsconfig` file, can point it elsewhere. For the lab's path remote it resolves a `file://` endpoint and uses its built-in `lfs-standalone-file` adapter, which copies objects into an `lfs/objects` directory inside the bare repository:

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

The line `Uploading LFS objects` is printed by the pre-push hook, before Git's own output. This demo is marked volatile for that line alone: with git-lfs 3.7.1 and a file remote the progress meter printed nothing in about one push out of ten in our runs, although the upload happened each time. The `0 B` is also an artifact of the file adapter, which does not report bytes.

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

The remote now has two stores, like your clone: Git objects with a 132-byte blob for the path, and an LFS directory with one full file per version. On GitHub the second store is a separate storage service with its own quota (section 22.11).

State table for `git push` in a repository with the LFS hook:

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged | unchanged | unchanged | unchanged | remote-tracking branch updated | LFS objects uploaded first, then commits with pointer blobs | Each uploaded object counts against the repository owner's LFS storage |

**What a file remote cannot do.** File locking (`git lfs lock`, and `git lfs track --lockable`, which makes files read-only until locked) is a server feature:

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

Locking exists because binary files cannot be merged: two people who edit the same model or design file in parallel produce a conflict that only one of them can win. It was not run for this book.

## 22.7 Cloning: what arrives without the client, and with it

The lab's configuration has no LFS filter, which makes it behave like a laptop, a container or a CI runner where `git lfs install` was never run:

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

The clone succeeds, `git status` is clean, and the model file is the pointer: 132 bytes of text. Nothing is wrong from Git's point of view. `.gitattributes` names a filter called `lfs`, no such filter is defined in this configuration, and an undefined filter is a no-op. This is question 3 of section 22.1. GitHub's documentation says the same about collaborators without the client: they "will only fetch the pointer files, and won't have access to any of the actual data" ([collaboration with Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/collaboration-with-git-large-file-storage)).

> **Root cause.** A program that crashes on a file beginning with `version https://git-lfs.github.com/spec/v1` is reading an LFS pointer. The first diagnostic is `head -c 200 <file>`; the second is `git lfs ls-files`, where a `-` marks a path whose working tree file is still a pointer.

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

`git lfs pull` downloaded the object into the local store and then declined to touch the working tree, because the repository has no LFS filter configured. After `git lfs install --local` the pieces can be run one at a time. 🟢 `git lfs fetch` downloads the objects that the current commit needs; 🟢 `git lfs checkout` replaces pointer files in the working tree with content from the local store, and never overwrites a modified file, so nothing is lost and no ref moves. `git lfs pull` is the two together.

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

On a machine where the filter is configured before the clone, which is what a global `git lfs install` arranges, none of these commands is needed: the smudge filter downloads each object as the checkout writes each file. The same happens on any later checkout that needs a version that is not in the local store yet:

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

**`GIT_LFS_SKIP_SMUDGE`.** With the environment variable set to `1`, the smudge filter passes pointers through untouched. That is how to clone or switch quickly when you do not need the large files, and how a CI job avoids downloading them:

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

`git status` is clean with a pointer in the working tree: the clean filter recognises a pointer and passes it through unchanged, so the file matches the index. `git lfs install --skip-smudge` makes this the permanent behavior of a configuration, and `git lfs pull --include "<paths>"` (or `lfs.fetchinclude` and `lfs.fetchexclude`) fetches a subset.

> **GitHub Actions, not Git.** `actions/checkout` downloads LFS files only when its `lfs` input is `true`; the default is `false` ([action.yml](https://github.com/actions/checkout/blob/v7.0.1/action.yml)). A job with the default therefore sees pointers, and a job with `lfs: true` downloads objects, which GitHub's billing page counts as bandwidth: "If GitHub Actions downloads a 500 MB file that is tracked with Git LFS, it will use 500 MB of the repository owner's bandwidth" ([Git LFS billing](https://docs.github.com/en/billing/concepts/product-billing/git-lfs)). Not run for this book.

## 22.8 The local store: `ls-files`, `prune`, `fetch --all`, `fsck`

Every version you have added or checked out stays in `.git/lfs/objects`. `git gc` does not touch it.

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

🟡 `git lfs prune` deletes local objects that the current checkout does not need, that are not "recent", and that have been pushed. `--dry-run --verbose` previews; `--verify-remote` asks the remote whether it really has each object before deleting the local copy:

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

"Recent" is defined by settings such as `lfs.fetchrecentrefsdays` (7 days) plus `lfs.pruneoffsetdays` (3 days), measured against the real clock. The lab's commits are dated 7 September 2026, so by the time you run this they are never recent; in a repository with fresh commits, `prune` keeps more than this transcript suggests.

A pruned object is not lost as long as the remote has it. 🟢 `git lfs fetch --all` downloads every object referenced by any commit, which is what a backup or a migration to another host needs, and `git lfs fsck` verifies that the files in the local store match their hashes:

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

`prune` refuses to delete what exists only on your machine. Two more versions, committed and not pushed:

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

The two pushed versions were deleted; the two unpushed ones stayed, including the one that is not checked out. The help text states one exception that matters after a reset or an amend: "The reflog is not considered, only commits. Therefore LFS objects that are only referenced by orphaned commits are always deleted." A model version that only an abandoned commit refers to is not protected by Git's reflog safety net.

## 22.9 `git lfs migrate`: files that are already in history

`git lfs track` works for files you have not added yet. For files that are already committed there is `git lfs migrate`, with three modes.

**`info`** reads history and reports sizes by file extension. It changes nothing:

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

Note the scope it chose by itself: "Examining commits: 100% (4/4)". By default all three modes look only at the current branch and only at commits that are on no remote. `main` is four commits ahead of `origin/main`, so four commits were examined.

**`import`** is 🟡 a history rewrite: it replaces matching blobs by pointers in every commit in scope, adds the `.gitattributes` line, and gives every rewritten commit and all of its descendants a new ID.

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

The commit that was already on the remote, `c66100a`, kept its ID. The four above it are new commits with the old messages, authors and dates:

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

The branch now reaches three pointer blobs of 132 bytes where it reached three blobs of 1.2 to 1.3 MB, and `migrate info` reports the 3.8 MB as LFS objects.

Two things about the state it leaves surprise people. First, the working tree file is a pointer afterwards, even with the filter installed. The command's own help says this is normal and names the remedy, `git lfs checkout`:

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

Second, the repository did not get smaller. The old commits are off the branch and still in the reflog, so the old blobs are still in the object database until the reflog entries expire and a garbage collection runs ([Chapter 13](ch13-recovery.md)). Here the expiry is forced, with the two cut-offs that do not depend on a clock:

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

🔴 `git reflog expire --expire=now --all` followed by `git gc --prune=now` removes the only way back to the pre-migration commits. Run them when you have verified the result, not before. The bytes have not left your disk either: they are in `.git/lfs/objects` now, once per version.

**Scope is the dangerous option.** The default scope, unpushed commits of the current branch, is the safe one: nothing that anyone else has is rewritten. Name further branches as arguments to include their unpushed commits. `--everything` means every commit reachable from every local and remote ref, including commits that are already on the remote. In Lab 15.4 a second local branch was missed by the first import, and `--everything` looked like the fix:

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

When the large files are already on the remote, a rewrite of published history is what you need, and it is an operation with a plan, not a command: everyone stops pushing, one person rewrites and pushes with `--force-with-lease`, everyone else re-clones or resets ([Chapter 9](ch09-rebase.md) for the push, [Chapter 21B](ch21b-repository-security-incident-response.md) for the general procedure). Old clones that push again bring the blobs back.

**`export`** is the reverse rewrite: pointers become ordinary blobs again in the commits in scope. It needs at least one `--include` pattern.

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

Export does not delete the tracking line; it appends a line that switches the attributes off for the pattern. It ends by pruning the local LFS store, and that is why this demo is volatile: when the prune removes several objects, git-lfs 3.7.1 prints the name of one of them, and not always the same one.

`git lfs migrate import --no-rewrite <files>` converts files in one new commit without touching earlier ones. It is equivalent to the `git add --renormalize` fix of the next section and has the same limit: the old blobs stay in history, so it does not help with a push that is rejected for a large file. (Run for this chapter without a transcript: it refuses a working tree that is not clean unless `--yes` is given.)

## 22.10 Common errors and their root causes

**The file was committed before the pattern was tracked.**

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

Three symptoms of one cause. `git lfs ls-files` does not list the recording. The blob in HEAD is 48,000 bytes, the raw file. And `git status` reports the file as modified although nobody edited it: the attributes now say "clean this path", the clean filter turns the working tree file into a pointer, and the pointer differs from the raw blob in the index. `git lfs fsck --pointers` names the problem. The forward fix is 🟢 `git add --renormalize`, which runs the path through the filter again and stages the result:

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
<!-- snippet: ch22/lfs-error-tracked-late/04-history-still-has-it -->
```text
$ git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep wav
blob 130 samples/hello.wav
blob 48000 samples/hello.wav
```
<!-- /snippet -->

The raw blob is still in the earlier commit. For a 48 KB file that is acceptable. For a file that a host would reject, use `git lfs migrate import` on the unpushed commits instead (Lab 15.3 does).

**A commit made without the filter.** On a machine with no LFS filter, such as a CI job that regenerates a file or a colleague's fresh laptop, `git add` stores whatever is in the working tree:

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

The full 1,250,000 bytes went into Git as a blob, on a path that `.gitattributes` assigns to LFS. Everyone who does have the filter gets a warning on their next pull and a file that is modified the moment it is checked out:

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

The mechanism is the same as in the first error, reached from the other side. The fix is the same too, and so is its limit: the large blob stays in the history that was pushed.

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

**The pointer was pushed and the object was not.** Here the hook was skipped with `--no-verify`; an interrupted upload or a hooks directory without the LFS hook gives the same state. The pointer is in the remote's Git history; the object exists only in the author's `.git/lfs/objects`. A teammate with a correctly installed client pulls:

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

Because the filter is `required`, a failing smudge fails the checkout: the file is absent, not silently wrong. (This demo is volatile because the log file name in the message contains the wall-clock time.) The structure is the one of the unpushed submodule commit in [Chapter 23](ch23-submodules.md), section 23.8: a reference was published without the thing it refers to.

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

A plain `git lfs push origin main` uploads nothing, because the client skips objects of commits that the remote-tracking branch already contains. `git lfs push --all origin main` sends every object the branch references. If nobody has the object any more, the pointer is permanently dangling, and the only repair is a new commit with a file that exists.

## 22.11 GitHub: file limits and metered LFS billing

> **GitHub, not Git.** Everything in this section is platform behavior, quoted from GitHub's documentation as read on 2 October 2026. None of it can be reproduced in the lab.

**Without LFS.** "If you attempt to add or update a file that is larger than 50 MiB, you will receive a warning from Git", and "GitHub blocks files larger than 100 MiB". A file added through the browser "can be no larger than 25 MiB". Repositories should "remain small, ideally less than 1 GB, and less than 5 GB is strongly recommended" ([about large files](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)). The Phase 0 report adds a cap of 2 GB for a single push ([repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits)). The block applies to any commit in the push that contains such a blob, which is why deleting the file in a later commit does not help (section 22.2).

**With LFS.** The maximum size of one LFS file depends on the plan: 2 GB on GitHub Free and Pro, 4 GB on Team, 5 GB on Enterprise Cloud. LFS "cannot be used with GitHub Pages sites" and "cannot be used with template repositories" ([about Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage)).

**Billing** ([Git LFS billing](https://docs.github.com/en/billing/concepts/product-billing/git-lfs)):

| Fact | Consequence |
|---|---|
| Included per month: 10 GiB of storage and 10 GiB of bandwidth on Free and Pro; 250 GiB of each on Team and Enterprise Cloud | Beyond that, usage is metered and billed |
| "Previously, Git LFS billing used pre-paid data packs. These have been removed and replaced with metered billing." | Advice to "buy a data pack" is out of date |
| Every pushed version is stored in full: "If you make a 1 byte change and push the file again, you'll use another 500 MB of storage" | Storage grows with the number of versions, not with the size of the latest one |
| Downloads use bandwidth; uploads do not. Downloads by GitHub Actions count | A CI matrix that pulls the same model in every job multiplies bandwidth |
| "Bandwidth and storage usage always count against the repository owner's account"; pushes to forks count "against the parent repository's bandwidth and storage quotas" | The owner pays for what contributors and forks do |
| When the quota is used up and no payment method is on file, clones "will only retrieve the pointer files" and you "will not be able to push new files back up" | An exhausted quota looks exactly like a machine without the client |
| After removing files from LFS, "the Git LFS objects still exist on the remote storage and will continue to count toward your Git LFS storage quota"; to remove them, "delete and recreate the repository", or contact Support ([removing files](https://docs.github.com/en/repositories/working-with-files/managing-large-files/removing-files-from-git-large-file-storage)) | Question 4 of section 22.1: storage does not shrink when history does |

> **Unverified.** Per-GiB prices for metered LFS usage are not stated on the billing page that was read, and the Phase 0 report records a conflict between GitHub's pricing page and its billing documentation about data packs. This book gives no prices.

In a pull request, GitHub "does not render some Git LFS objects"; reviewers see the pointer ([collaboration with Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/collaboration-with-git-large-file-storage)).

## 22.12 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A program fails to parse a file that is about 130 bytes and starts with `version https://git-lfs...` | `git lfs ls-files` shows `-`; `git config get filter.lfs.smudge` prints nothing | `git lfs install` (in this book: `--local`), then `git lfs pull` | Install the client in images and CI; in Actions, `lfs: true` on checkout |
| `git lfs ls-files` does not list a file that should be in LFS; `git status` shows it modified right after checkout; or the warning "Encountered N file(s) that should have been a pointer, but wasn't" | `git lfs fsck --pointers`; `git cat-file -s HEAD:<path>` is the full size | `git add --renormalize <path>` and commit; or `migrate import` if unpushed | Track before adding; a CI job running `git lfs fsck --pointers` |
| `Smudge error`, "remote missing object", `smudge filter lfs failed` | Compare the `oid` in `git cat-file -p HEAD:<path>` with the remote's object store | Whoever has the object: `git lfs push --all <remote> <branch>` | Never `--no-verify` in LFS repositories; keep the pre-push hook when adopting a hook manager |
| "This repository is configured for Git LFS but 'git-lfs' was not found on your path" | The hooks exist, the program is not installed | Install git-lfs; or delete the hooks if LFS is no longer used | Provision the client with the toolchain |
| A push is still rejected for a large file after `git lfs track` and a new commit | `git rev-list --objects <remote>/<branch>..<branch>` piped to `git cat-file --batch-check` still lists the big blob | `git lfs migrate import` on the unpushed commits | `migrate info` before the first push of new binary types |
| After `migrate import`, the branch is "ahead N, behind M" | `--everything` rewrote published commits (22.9) | Restore from the branch reflogs; migrate with named branches | Read the commit count that `migrate info` prints for the same scope |
| Merge conflict markers inside a pointer file | Two branches changed the same LFS file | `git checkout --ours` or `--theirs <path>`, `git add` | Locking on a server that supports it; one owner per binary |
| LFS storage on GitHub grows although files were deleted | Objects stay until the repository is deleted or Support purges them | See 22.11 | Decide what belongs in LFS before pushing it |

## 22.13 When not to use it, and what to use instead

LFS fits a modest number of mid-sized binary files that change rarely and must be versioned together with the code: reference checkpoints for tests, small fixtures, images and design assets. The Phase 0 report's assessment of where it is the wrong tool, with the alternatives it lists:

| Situation | Why LFS is wrong | Use instead |
|---|---|---|
| Files larger than the plan's per-file cap (2 to 5 GB on GitHub) | The upload is refused | Object storage or a model registry; keep the URI and a checksum in Git |
| Training data and model weights that change with every run | Each version is stored whole and billed; nothing is ever freed | DVC, which keeps small metafiles in Git and the data in a remote you control; or a model registry, with the Git commit recorded beside each model version |
| Data that must be deletable (personal data, licensed data) | Removing a file from LFS on GitHub does not delete the object | Storage with retention and deletion controls |
| Models and datasets published for others | Consumers need the client, and your bandwidth pays for their downloads | The Hugging Face Hub, pinning the `revision` you download; or GitHub Releases for binaries that accompany a tag |
| Contributors or CI that cannot be relied on to have the client | Pointer files in place of content, silently | Any of the above; or a download step with a checksum |

The versions, licences and stewardship of these tools changed during 2025 and 2026; [Chapter 28](ch28-ai-ml-workflows.md) gives the current facts with their sources.

Dangerous edge cases:

- 🔴 **Rewriting published history with `migrate import --everything`**, or any `migrate` followed by a forced push, changes commit IDs for everyone (22.9).
- **`git lfs prune` ignores the reflog.** An LFS object referenced only by a commit you reset away from can be deleted locally although `git reflog` still shows the commit (22.8).

## 22.14 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git lfs ls-files`, `status`, `env`, `fsck`, `pointer --file`, `migrate info`, `track` (no argument) | 🟢 SAFE | Nothing (`fsck` moves corrupt local objects aside) | not needed | not needed |
| `git lfs install --local` | 🟢 SAFE | `filter.lfs.*` in `.git/config`; four hooks in the hooks directory. Without `--local` the filter keys go into your **global** configuration (🟡) | `git config list --show-origin` | `git lfs uninstall --local` |
| `git lfs track "<pattern>"`, `untrack` | 🟢 SAFE | A line in `.gitattributes` | `git lfs track --dry-run` | Edit the file |
| `git lfs fetch`, `fetch --all`, `pull`, `checkout` | 🟢 SAFE | `fetch` downloads into `.git/lfs/objects`; `checkout` and `pull` replace pointer files in the working tree and never overwrite modified files | `git lfs fetch --dry-run`; `git lfs ls-files` | `git lfs prune` for the downloads |
| `git lfs push`, and `git push` with the hook | 🟡 CAUTION | Uploads objects; on GitHub they are billed and cannot be deleted by you | `git lfs push --dry-run <remote> <ref>`; `git lfs status` | None on GitHub short of deleting the repository (22.11) |
| `git lfs prune` | 🟡 CAUTION | Deletes local LFS objects that are pushed and not needed | `--dry-run --verbose`; `--verify-remote` | `git lfs fetch`, if the remote has them |
| `git lfs migrate import`, `export` (default scope or named branches) | 🟡 CAUTION | Rewrites unpushed commits; working tree left with pointers after import | `migrate info` with the same options | Branch reflogs: `git reset --hard <branch>@{1}` |
| `git lfs migrate import --everything`, then a forced push | 🔴 DANGEROUS | Rewrites published history; destroys nothing locally, breaks every other clone | `migrate info --everything`; rehearse in a fresh clone | Before the push: reflogs. After: the old history from another clone |
| `git reflog expire --expire=now --all` and `git gc --prune=now` | 🔴 DANGEROUS | Deletes unreachable commits and the reflog that led to them | `git reflog`; `git fsck --unreachable` | None |

## 22.15 Version notes

> **Version note.** Older behavior: GitHub sold prepaid LFS "data packs". Current behavior: metered billing with an included monthly quota per plan. Since: the billing documentation says the packs "have been removed"; the Phase 0 report dates the change to the enhanced billing platform of February and March 2025 ([changelog](https://github.blog/changelog/2025-02-25-enhanced-billing-platform-is-now-available-for-personal-accounts/)). Recommended: budget by stored versions and by downloads, including CI.

- The client used here is git-lfs 3.7.1 (17 October 2025). The newest release is 3.8.0 (28 August 2026), which adds zstd-compressed object downloads and requires macOS 13 or later ([releases](https://github.com/git-lfs/git-lfs/releases)); the report records no security content in it.
- The help text of git-lfs 3.7.1 states that with Git 2.42.0 or later, `git lfs pull` and `git lfs checkout` act only on files that are in the index and match an LFS filter attribute, which matters in sparse or partial clones.

> **Outdated advice.** "Use `git lfs clone`, it is faster than `git clone`." The installed client prints a warning when the command is run: "`git lfs clone` is deprecated and will not be updated with new flags from `git clone`", and adds that `git clone` "has been updated in upstream Git to have comparable speeds". Use `git clone`.

> **Unverified.** The git-lfs release that introduced the built-in `lfs-standalone-file` adapter is not stated in the documentation that was read. It works in 3.7.1, as the transcripts show.

## 22.16 Practice

- Lab 15.3 (inspect an LFS pointer) and Lab 15.4 (migrate an already-committed large file) in the [Module 15 lab manual](../lab-manual/m15-submodules-subtrees-lfs.md).
- Replay any transcript with `labs/run ch22/<demo>`, for example `labs/run ch22/lfs-clone`.
- A drill: in the sandbox of `ch22/lfs-pointer`, compute by hand what the pointer of `models/vocab.txt` would be if you tracked `*.txt` (`shasum -a 256`, `wc -c`), then check with `git lfs pointer --file`.

## 22.17 Interview questions

1. Why does deleting a large file in a new commit not make a rejected push succeed?
2. What does Git store for an LFS-tracked path, what does LFS store, and where is each on your machine and on the remote?
3. Which two Git mechanisms does LFS use, and which parts of the setup travel with a clone?
4. A CI job fails because a model file is 132 bytes. Give the root cause, two diagnostics, and the fix for GitHub Actions.
5. `git status` shows a tracked binary as modified immediately after a fresh checkout. Explain the mechanism and the two possible histories that lead to it.
6. A teammate gets "Smudge error ... remote missing object". What happened, who can fix it, and with which command? Why does a plain `git lfs push` not do it?
7. What does `git lfs migrate import` do to commit IDs, to the working tree, and to the size of `.git`? What is the default scope, and what does `--everything` add?
8. Your LFS bill grows although nobody adds models. Name three mechanisms that can cause it.
9. When is LFS the wrong tool for model weights, and what would you use?
10. How does `git lfs prune` decide what it may delete, and in which case does Git's reflog not protect you?

## 22.18 Sources

**Primary sources**

- Git LFS: the [specification](https://github.com/git-lfs/git-lfs/blob/main/docs/spec.md), [server discovery](https://github.com/git-lfs/git-lfs/blob/main/docs/api/server-discovery.md) and [custom transfers](https://github.com/git-lfs/git-lfs/blob/main/docs/custom-transfers.md) in the project's repository, read on 2 October 2026; the help texts of the installed client 3.7.1 (`git lfs <command> --help`), which the transcripts were checked against; [releases](https://github.com/git-lfs/git-lfs/releases).
- GitHub Docs, read on 2 October 2026: [About large files on GitHub](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github), [About Git Large File Storage](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage), [Git LFS billing](https://docs.github.com/en/billing/concepts/product-billing/git-lfs), [Collaboration with Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/collaboration-with-git-large-file-storage), [Removing files from Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/removing-files-from-git-large-file-storage), [Repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits).
- [gitattributes](https://git-scm.com/docs/gitattributes) for filter drivers; `actions/checkout` [action.yml](https://github.com/actions/checkout/blob/v7.0.1/action.yml) at v7.0.1.

**Secondary sources**

- The Phase 0 report of this course: section 2 (the large-files paragraph), section 13 ("Scale, submodules and large files") and section 15 ("Data and model versioning"), with the research notes on AI/ML workflows.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- glich.stream, ["Chad level git: advanced concepts (2025)"](https://www.youtube.com/watch?v=cYD3krz5L2g) (1 h 14 min): hands-on, includes Git LFS. Current.
- Vikash Das, ["MLOps: Day 4 - Data Versioning using DVC"](https://www.youtube.com/watch?v=PPrPuxqWc7E) (1 h 25 min, 2024, Hindi): why Git alone does not suit data, and DVC beside Git. Mostly current; DVC CLI versions not checked.

**Further reading**

- [Chapter 28](ch28-ai-ml-workflows.md) for data and model versioning beyond LFS; [Chapter 26](ch26-performance.md) for partial clone, which is Git's own way of not downloading every blob.
