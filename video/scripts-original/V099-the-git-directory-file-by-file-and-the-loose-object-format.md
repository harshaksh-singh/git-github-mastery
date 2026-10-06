# V099: The .git directory file by file, and the loose object format

- **Part.** 4, Git internals
- **Module.** 16, Object database internals; and Module 17, Refs and index internals
- **Planned minutes.** 22
- **Prerequisites.** V003, V008
- **Textbook sections.** [Chapter 3](../../textbook/ch03-git-internals.md), sections 3.1 to 3.3
- **Demo scripts.** `labs/ch03/gitdir-tour.sh`, `labs/ch03/loose-object.sh`

## HOOK

**[ON SCREEN]** Four questions on an ordinary day:

1. "A laptop lost power during a commit, and Git now says `fatal: index file corrupt`. What did we lose: the history, the work in progress, or nothing?"
2. "The release script stamps builds by reading `.git/refs/heads/main`. On the new build image that file does not exist. Is the repository damaged?"
3. "`git fsck` reports a dangling commit on the build server. Is data at risk? Should somebody run a cleanup?"
4. "We keep four hundred versions of a 16 MB evaluation set in one repository. Are we storing 6 GB?"

None of these can be answered with the commands of the earlier parts alone. They are questions about how Git stores things.

The short answers, which this part of the course will earn one by one. The index is rebuilt with one command, and only content that was staged and never committed needs a second look. The ref is in `packed-refs` or in a reftable, and the script should have asked Git. "Dangling" describes where `git fsck` started looking, not what will be deleted, and the cleanup is the risky part. And probably not: a pack stores versions that differ in a few lines as deltas, while every snapshot stays complete.

## INTRODUCTION

This video opens Part 4, Git internals. Since the first part of the course you have had a model: four object types, names that point at them, a staging area. In this part you open each box.

Say this once for the part: the replays use the fixed lab clock, so the commit IDs on screen equal the IDs in the book and the ones you will get when you replay.

Today, two things. The `.git` directory, file by file: what `git init` creates, what the first commit adds, and which of those files Git can rebuild and which it cannot. And the smallest unit of storage: one loose object, down to its bytes. You will recompute an object ID with a tool that knows nothing about Git.

Two habits come out of this chapter, and both begin today. Read repository state through plumbing commands, because the files underneath exist in more than one format. And before you delete or repair anything under `.git`, decide whether it is primary or derived data.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- name every entry of a fresh `.git` directory and say what reads or writes it;
- say which files of `.git` can be deleted without breaking the repository;
- describe the bytes of a loose object: header, content, compression;
- compute a blob's object ID by hand and explain why the compression level does not matter;
- find the file that holds a given object.

## CONCEPT

**The `.git` directory.** In one sentence: the `.git` directory is the repository: an object database, names for objects, a log of how those names moved, one staging file, and settings. The files next to it are a working tree that Git can rebuild from it.

Precisely. A repository is either a `.git` directory at the top of a working tree, or a bare directory without one. A `.git` that is a plain file containing `gitdir:` and a path points at a repository stored elsewhere, which is how linked worktrees and submodules work; you saw both in the last part. The official data model names four kinds of data inside: objects, references, the index and reflogs. Everything else is configuration or the state of an operation in progress. Ask Git where the directory is with `git rev-parse --git-dir`; never assume `./.git`.

**Primary or derived.** "Primary" means that Git cannot recreate the file from anything else. Objects, loose or packed, are primary. Refs, `HEAD`, `config`, hooks, `info/exclude` and reflogs are primary. The lookup tables beside a pack, the `.idx` and `.rev` files, are derived from the pack. The index is derived, except for what is staged. `COMMIT_EDITMSG` is scratch. `description` is unused by Git itself.

That column answers the objective "which files can be deleted". Derived data is rebuilt. Primary data is restored from another copy. And three kinds of primary data are never cloned or pushed: hooks, `info/exclude`, and reflogs.

**The loose object.** In one sentence: a loose object is one compressed file whose content is a short header, a NUL byte and the data, and whose file name is the hash of exactly those bytes.

Precisely, in the manual's three sentences. The object is the prefix, type, space, size, NUL, followed by the data, where the type is `blob`, `tree`, `commit` or `tag` and the size is the length of the data in decimal. Prefix and data together are compressed with zlib and stored. And "the object ID of the object is the SHA-1 or SHA-256 (as appropriate) hash of the uncompressed data".

The file sits under `objects/`, in a directory named after the first two hexadecimal digits of the ID.

🟢 SAFE: `git hash-object <file>` computes the ID that the file's content has as a blob, and writes the object with `-w`. It hashes what `git add` would store: if a clean filter or a line-ending conversion applies to the path, that is the converted content. `--no-filters` hashes the file as it is.

Inside `.git`, `git hash-object -w` creates one new file under `objects/`, read-only. Nothing else: no index entry, no ref, no reflog line.

Why does the compression level not matter? Because the ID is the hash of the uncompressed bytes. The compression is a storage detail and is not part of the identity.

When not to work at this level: in scripts that need a branch's value or a file's content. The loose form is one of several storage forms. Use plumbing, `git rev-parse`, `git for-each-ref`, `git cat-file`, `git ls-files`, and let Git find the bytes.

## MENTAL MODEL

The textbook has two analogies, one for each half.

For the directory: a records office. The vault holds sealed documents filed under a number computed from their content: objects. A card index says which document is current for each project: refs. A visitors' book records every change to a card: reflogs. One tray on the clerk's desk holds the draft of the next filing: the index. The analogy breaks in one place that matters. A sealed document can never be amended, not even by the office. Every "change" files a new document and moves a card.

For the object: a sealed envelope filed under a number that is computed from what is inside it. Two envelopes with the same content get the same number, so the office keeps one. An envelope whose content differs by one character gets an unrelated number. This analogy breaks at correction: a real archive can fix a filing mistake by relabelling, and here the label cannot be changed without changing the content.

## DIAGRAM

**[DIAGRAM]** First the map of section 3.2: the four kinds of data and where each lives in a new repository.

```text
 .git/
   objects/                 1. OBJECTS   blobs, trees, commits, tags
     08/ffd041...               loose: one compressed file per object     section 3.3
     pack/                      packed: many per file, plus an index      section 3.7
   refs/   packed-refs      2. REFS      names for object IDs             section 3.9
   HEAD, ORIG_HEAD, ...                  the current branch; root refs    section 3.10
   logs/                    3. REFLOGS   how each name moved, when, why   section 3.11
   index                    4. INDEX     the proposed next commit         section 3.12
   config  info/  hooks/  description    settings and local policy
```

Four numbered lines. Everything else in the directory is settings or the state of an operation in progress. The rest of this part takes these lines one at a time.

**[DIAGRAM]** Then the picture of section 3.3: the bytes of one loose object, labelled. Draw the file on the left, then the three fields on the right, then the two arrows down.

```text
  config.toml, 16 bytes              the object, 24 bytes before compression
 +-------------------+              +---------+----+-------------------+
 | retry_limit = 3\n |   ------->   | blob 16 | \0 | retry_limit = 3\n |
 +-------------------+              +---------+----+-------------------+
                                      |                         |
                                      | SHA-1 of these bytes    | zlib
                                      v                         v
                        f784b58423ef67be5af8...    .git/objects/f7/84b58423ef67be5af8...
                        the object ID              the file, named after the ID
```

Sixteen bytes of content. A header of seven characters, "blob 16", and one NUL byte: twenty-four bytes. Two things are computed from those twenty-four bytes, independently: the hash, which is the ID, and the compressed stream, which is the file. The left arrow never looks at the output of the right one.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch03/gitdir-tour`. What `git init` creates, before anything is recorded.

**[ON SCREEN]** 🟢 SAFE: `git init` creates a `.git` directory and changes no existing file.

```bash
git init inference-service
cd inference-service
find .git -not -name '*.sample' | sort
```

Predict: in a repository with no commit, is there an index? A ref? An object?

<!-- snippet: ch03/gitdir-tour/01-init -->
```text
$ git init inference-service
Initialized empty Git repository in $LAB/ch03/gitdir-tour/inference-service/.git/
$ cd inference-service
# Everything Git knows about this repository, minus the 14 sample hooks:
$ find .git -not -name '*.sample' | sort
.git
.git/config
.git/description
.git/HEAD
.git/hooks
.git/info
.git/info/exclude
.git/objects
.git/objects/info
.git/objects/pack
.git/refs
.git/refs/heads
.git/refs/tags
```
<!-- /snippet -->

No object, no ref, no index. The listing leaves out the fourteen sample hooks. `refs/heads` is an empty directory, and yet the repository already has a current branch.

```bash
cat .git/HEAD
cat .git/config
cat .git/description
cat .git/info/exclude
```

<!-- snippet: ch03/gitdir-tour/02-init-contents -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ cat .git/config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
$ cat .git/description
Unnamed repository; edit this file 'description' to name the repository.
$ cat .git/info/exclude
# git ls-files --others --exclude-from=.git/info/exclude
# Lines that start with '#' are comments.
# For a project mostly in C, the following would be a good set of
# exclude patterns (uncomment them if you want to use them):
# *.[oa]
# *~
$ ls .git/hooks | wc -l
      14
```
<!-- /snippet -->

`HEAD` names `refs/heads/main`, a ref that does not exist yet: an "unborn" branch, which is legal. The first commit creates the ref. In `config`, `repositoryformatversion = 0` says that no extension is in use. `ignorecase` was probed from this Mac's filesystem, and `precomposeunicode` is set on macOS. `description` is read by the gitweb interface and by one sample hook; no Git command needs it.

Now the first commit.

```bash
git add config.toml src/server.py
git commit -m "Add inference service skeleton"
find .git -type f -not -name '*.sample' | sort
```

Predict how many objects two files in two directories produce.

<!-- snippet: ch03/gitdir-tour/03-first-commit -->
```text
$ git add config.toml src/server.py
$ git commit -m "Add inference service skeleton"
[main (root-commit) 08ffd04] Add inference service skeleton
 2 files changed, 4 insertions(+)
 create mode 100644 config.toml
 create mode 100644 src/server.py
# What the first commit added to .git:
$ find .git -type f -not -name '*.sample' | sort
.git/COMMIT_EDITMSG
.git/config
.git/description
.git/HEAD
.git/index
.git/info/exclude
.git/logs/HEAD
.git/logs/refs/heads/main
.git/objects/08/ffd041265ea03746a748c35f7d35df9a8e6900
.git/objects/36/35c8470ebd3d3e70fb74c4705d011de687e7f9
.git/objects/81/e5c25d60a924e6afc7e8f121dd6e78fded11fc
.git/objects/bc/cfc53fe1c451c013ac9e612812cfd3543c029a
.git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073
.git/refs/heads/main
```
<!-- /snippet -->

Two files in the working tree became five objects: two blobs, the tree for `src`, the top-level tree, and the commit. Three things appeared besides the objects: the index, the ref `refs/heads/main`, and two reflog files. And `COMMIT_EDITMSG`.

```bash
cat .git/refs/heads/main
cat .git/COMMIT_EDITMSG
cat .git/logs/HEAD
git count-objects
```

<!-- snippet: ch03/gitdir-tour/04-new-files -->
```text
$ cat .git/refs/heads/main
08ffd041265ea03746a748c35f7d35df9a8e6900
$ cat .git/COMMIT_EDITMSG
Add inference service skeleton
$ cat .git/logs/HEAD
0000000000000000000000000000000000000000 08ffd041265ea03746a748c35f7d35df9a8e6900 Lab User <you@example.com> 1788756240 +0530	commit (initial): Add inference service skeleton
$ git count-objects
5 objects, 20 kilobytes
```
<!-- /snippet -->

The whole branch is one line of 41 bytes: forty hexadecimal digits and a newline. It holds `08ffd04`, the commit you made a moment ago. The reflog line reads: old value, all zeros because the ref did not exist; new value; who; when; and why. `git count-objects` confirms five.

**[ON SCREEN]** The inventory table of section 3.2, with the last column highlighted: primary or derived. Read the rows for `objects`, `index`, `logs` and the pack `.idx` files aloud. This column is your triage sheet in an incident.

**[TERMINAL]** Replay `labs/run ch03/loose-object`. One file, one object.

```bash
git init inference-service
cd inference-service
printf 'retry_limit = 3\n' > config.toml
git hash-object config.toml
find .git/objects -type f
git hash-object -w config.toml
find .git/objects -type f
```

<!-- snippet: ch03/loose-object/01-write -->
```text
$ git init inference-service
Initialized empty Git repository in $LAB/ch03/loose-object/inference-service/.git/
$ cd inference-service
$ printf 'retry_limit = 3\n' > config.toml
# Compute the ID only. Nothing is stored yet:
$ git hash-object config.toml
f784b58423ef67be5af8d1cfdfd9bea5eaa26bae
$ find .git/objects -type f
# Now store it (-w). One file appears, named after the ID:
$ git hash-object -w config.toml
f784b58423ef67be5af8d1cfdfd9bea5eaa26bae
$ find .git/objects -type f
.git/objects/f7/84b58423ef67be5af8d1cfdfd9bea5eaa26bae
```
<!-- /snippet -->

Without `-w`, an ID is printed and nothing is stored: the first `find` prints nothing. With `-w`, one file appears. Look at its path: the directory `f7`, the first two digits of the ID, and a file name made of the remaining thirty-eight.

The object file is not the working tree file. Decompress it.

**[PAUSE]** The content is sixteen bytes. Predict the bytes that come before it.

```bash
python3 -c "import sys, zlib; print(zlib.decompress(open(sys.argv[1], 'rb').read()))" .git/objects/f7/84b58423ef67be5af8d1cfdfd9bea5eaa26bae
wc -c < config.toml
printf 'blob 16\0retry_limit = 3\n' | shasum
```

<!-- snippet: ch03/loose-object/02-inflate -->
```text
# The file is a zlib stream. Inflate it:
$ python3 -c "import sys, zlib; print(zlib.decompress(open(sys.argv[1], 'rb').read()))" .git/objects/f7/84b58423ef67be5af8d1cfdfd9bea5eaa26bae
b'blob 16\x00retry_limit = 3\n'
$ wc -c < config.toml
      16
# Hash the same bytes yourself: header, NUL, content.
$ printf 'blob 16\0retry_limit = 3\n' | shasum
f784b58423ef67be5af8d1cfdfd9bea5eaa26bae  -
```
<!-- /snippet -->

Read the header bytes aloud: b, l, o, b; a space; one, six; then `\x00`, the NUL byte; then the content, ending in a newline. `wc -c` confirms sixteen.

And the last command. `shasum` knows nothing about Git. You hand it the same twenty-four bytes with `printf`, and it prints the same forty digits: `f784b584` and the rest. That is all an object ID is. Notice also what was not involved in that computation: zlib. The ID was computed from bytes that were never compressed.

```bash
git cat-file -t f784b584
git cat-file -s f784b584
git cat-file -p f784b584
mkdir -p deploy && cp config.toml deploy/production.toml
git hash-object deploy/production.toml
printf 'retry_limit = 3\n' | git hash-object --stdin
printf 'retry_limit = 4\n' | git hash-object --stdin
```

<!-- snippet: ch03/loose-object/03-read-back -->
```text
$ git cat-file -t f784b584
blob
$ git cat-file -s f784b584
16
$ git cat-file -p f784b584
retry_limit = 3
# The ID depends on content only: another name, another directory, same ID.
$ mkdir -p deploy && cp config.toml deploy/production.toml
$ git hash-object deploy/production.toml
f784b58423ef67be5af8d1cfdfd9bea5eaa26bae
$ printf 'retry_limit = 3\n' | git hash-object --stdin
f784b58423ef67be5af8d1cfdfd9bea5eaa26bae
# One changed byte gives an unrelated ID:
$ printf 'retry_limit = 4\n' | git hash-object --stdin
eb1ea65a46ac10abf5e01a4af8d6a219f5182835
```
<!-- /snippet -->

`-t` prints the type, `-s` the size of the data without the header, `-p` the content. Then three experiments. Another name in another directory: the same ID. The same bytes from standard input, with no file at all: the same ID. One changed byte, a 4 for a 3: an ID that has nothing in common with the old one. The ID depends on nothing except the content. Not the file name, not the directory, not the time, not the author, not the repository.

**[ON SCREEN]** The state table for `git hash-object -w <file>`.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git hash-object -w <file>` | unchanged | unchanged | unchanged | unchanged | one new file under `objects/`, unless the object already exists; without `-w`, nothing | unchanged | unchanged |

One more distinction. An object in the database is not a tracked file. Predict what `git status` says about `config.toml`, whose blob you stored a moment ago.

```bash
git status --short
git ls-files --stage
git add config.toml
git ls-files --stage
find .git/objects -type f
```

<!-- snippet: ch03/loose-object/04-status -->
```text
# An object in the database is not a tracked file. The index is still empty:
$ git status --short
?? config.toml
?? deploy/
$ git ls-files --stage
$ git add config.toml
$ git ls-files --stage
100644 f784b58423ef67be5af8d1cfdfd9bea5eaa26bae 0	config.toml
$ find .git/objects -type f
.git/objects/f7/84b58423ef67be5af8d1cfdfd9bea5eaa26bae
```
<!-- /snippet -->

Untracked. Tracking is a matter of the index, and the index is still empty. `git add` then created the index entry and wrote no second object: the blob it needed was already there, under the name it would have computed.

## COMMON MISTAKES

1. **A script that reads `.git/refs/heads/main`.** Root cause: a ref can be stored as a loose file, in `packed-refs`, or in a reftable; only plumbing such as `git rev-parse` reads all forms.
2. **Assuming the repository is at `./.git`.** Root cause: in a linked worktree or a submodule, `.git` is a file that points elsewhere; `git rev-parse --git-dir` gives the location.
3. **Deleting something under `.git` without asking "primary or derived?".** Root cause: an index or a pack index can be rebuilt; an object or a reflog cannot.
4. **Hashing the file's bytes alone and getting a different ID.** Root cause: the ID is the hash of header, NUL and content, not of the content by itself.
5. **Believing that storing an object makes a file tracked.** Root cause: tracking is an index entry; `git hash-object -w` writes one object file and nothing else.

## PRODUCTION EXAMPLE

A release pipeline for an inference service stamps each build with the commit of `main` by reading the file `.git/refs/heads/main`. After the build image is updated, the stamp step fails: no such file. The on-call engineer's first thought is corruption.

A colleague who knows the layout runs one plumbing command, `git rev-parse` on the branch name, and gets the commit ID at once. The repository is healthy. The ref is stored in another form on that image; the loose file was never a contract. The script is changed to ask Git, and the review comment quotes the first habit of the chapter.

The same week a container image for a different service is found to include `.git`. The team's security note uses the other lesson from section 3.2: the directory is the whole history. An image, a CI cache or a backup that includes `.git` includes every version of every file, also the credentials file that was "deleted" two years ago.

Content addressing pays the team back in three ways, as the textbook lists them. Deduplication: the same lock file on forty branches is one object. Integrity: an ID is a checksum, so a copy of an object from any clone or backup is known to be the right bytes if its ID matches. Idempotence: recording the same content twice changes nothing. You relied on the second property in every recovery of the last part.

## PRACTICE EXERCISE

Do Exercise 16.1, Level 1, "An object ID by hand", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

Before you run `git hash-object`, write down the exact bytes you will hash: the type word, the size in decimal, where the NUL goes, and whether your content ends in a newline. Predict the path of the object file from the ID. Work in `labs/shell`; the object ID of a given content is the same on every machine, although commit IDs there differ from the book.

The challenge is Exercise 17.9, Level 4, "Not a git repository", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q68: "Compute the object ID of a blob by hand. Which bytes are hashed, and why does the compression level not matter?"

Pause and answer aloud, with a concrete small file.

A strong answer writes out the byte sequence for a specific content, field by field, including the two bytes people forget: the separator after the size and the trailing newline of the content if there is one. It names a tool outside Git that reproduces the ID. It explains the order of operations in storage, hashing and compression as two independent computations on the same input, and concludes about the compression level from that. It may add what else the ID does not depend on, and one consequence that matters in production.

## RECAP

You should now be able to say:

- `.git` holds four kinds of data, objects, refs, reflogs and the index, plus settings and the state of operations in progress.
- A fresh repository has `HEAD` naming an unborn branch and no object, ref or index; the first commit adds objects, the index, a ref and two reflogs.
- Before I delete or repair anything under `.git` I ask whether it is primary or derived, and I read state through plumbing.
- A loose object is zlib-compressed "type, space, size, NUL, content", stored under `objects/` in a directory named by the first two digits of its ID.
- The object ID is the hash of the uncompressed bytes, so it depends only on type, size and content, and not on compression, file name or time.

## HOMEWORK

Read sections 3.1 to 3.3 of [Chapter 3](../../textbook/ch03-git-internals.md). Repeat Lab 0.2, "Read every file in an empty `.git`", in [`lab-manual/m00-lab-setup.md`](../../lab-manual/m00-lab-setup.md), and name every file from memory.
