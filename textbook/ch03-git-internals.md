# Chapter 3: Git Internals

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch03/`.

## 3.1 Why this matters

Four questions a CTO can ask on an ordinary day:

1. "A laptop lost power during a commit, and Git now says `fatal: index file corrupt`. What did we lose: the history, the work in progress, or nothing?"
2. "The release script stamps builds by reading `.git/refs/heads/main`. On the new build image that file does not exist. Is the repository damaged?"
3. "`git fsck` reports a dangling commit on the build server. Is data at risk? Should somebody run a cleanup?"
4. "We keep four hundred versions of a 16 MB evaluation set in one repository. Are we storing 6 GB?"

None of these can be answered with the commands of the other chapters alone. They are questions about how Git stores things. [Chapter 2](ch02-mental-model.md) gave you the model: four object types, names that point at them, a staging area. This chapter opens each box: you will recompute an object ID with `shasum`, read a tree, a commit and a tag in raw form, watch loose objects become a pack with a delta chain, list what is reachable and what is not, read one ref in three storage forms, and decode the header of the index with `xxd`.

The answers, in order. The index is rebuilt with one command, and only content that was staged and never committed needs a second look (section 3.12). The ref is in `packed-refs` or in a reftable, and the script should have asked Git (sections 3.9 and 3.13). "Dangling" describes where `git fsck` started looking, not what will be deleted, and the cleanup is the risky part (section 3.8). And probably not: a pack stores versions that differ in a few lines as deltas while every snapshot stays complete (section 3.7); files that change in every byte are another matter (Chapter 22: Git LFS).

Two habits come out of this chapter. Read repository state through plumbing (`git rev-parse`, `git for-each-ref`, `git cat-file`, `git ls-files`), because the files underneath exist in more than one format. And before you delete or repair anything under `.git`, decide whether it is primary or derived data: an index or a pack index can be rebuilt, an object or a reflog cannot.

## 3.2 The `.git` directory, file by file

**In one sentence.** The `.git` directory is the repository: an object database, names for objects, a log of how those names moved, one staging file, and settings; the files next to it are a working tree that Git can rebuild from it.

**Analogy.** A records office. The vault holds sealed documents filed under a number computed from their content (objects). A card index says which document is current for each project (refs). A visitors' book records every change to a card (reflogs). One tray on the clerk's desk holds the draft of the next filing (the index). The analogy breaks in one place that matters: a sealed document can never be amended, not even by the office. Every "change" files a new document and moves a card.

**Precisely.** A repository is either a `.git` directory at the top of a working tree or a bare directory such as `server.git` without one; a `.git` that is a plain file containing `gitdir: <path>` points at a repository stored elsewhere, which is how linked worktrees and submodules work ([gitrepository-layout](https://git-scm.com/docs/gitrepository-layout)). The official data model names four kinds of data inside: objects, references, the index and reflogs ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)); everything else is configuration or the state of an operation in progress. Ask Git where the directory is with `git rev-parse --git-dir`; never assume `./.git`.

**See it.** What `git init` creates, before anything is recorded:

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

No object, no ref, no index. `refs/heads` is an empty directory, and yet the repository already has a current branch:

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

`HEAD` names `refs/heads/main`, a ref that does not exist yet: an "unborn" branch, which is legal, and the first commit creates the ref. `repositoryformatversion = 0` says that no extension is in use (sections 3.13 and 3.14 show version 1). `ignorecase` was probed from this Mac's filesystem, and `precomposeunicode` is set on macOS. `description` is read by the gitweb interface and by one sample hook; no Git command needs it. The fourteen hooks are samples that do nothing until renamed.

The first commit fills in the rest:

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

Two files in the working tree became five objects: two blobs, the tree for `src`, the top-level tree, and the commit. Three things appeared besides the objects: the index, the ref `refs/heads/main`, and two reflog files.

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

The whole branch is one line of 41 bytes: forty hexadecimal digits and a newline. The reflog line reads: old value (all zeros, because the ref did not exist), new value, who, when, and why.

**Picture.** The four kinds of data and where each lives in a new repository:

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

The complete inventory, for a repository in the default format. "Primary" means that Git cannot recreate the file from anything else.

| Path | What it holds | Written by | Primary or derived |
|---|---|---|---|
| `HEAD` | `ref: refs/heads/<branch>`, or a commit ID when detached | `git init`, `git switch`, `git checkout` | primary |
| `config` | repository-level settings, remotes, upstream branches | `git init`, `git config set`, `git remote` | primary |
| `description` | one line for gitweb | the template | unused by Git |
| `hooks/` | scripts that Git runs at fixed points; samples end in `.sample` | you (Chapter 14C) | primary, never cloned |
| `info/exclude` | ignore patterns for this clone only | you ([Chapter 4](ch04-working-tree.md)) | primary, never cloned |
| `objects/<2 hex>/<38 hex>` | loose objects | any command that records content | primary |
| `objects/pack/pack-*.pack` | packed objects | `git gc`, `git repack`, `git fetch`, `git clone` | primary |
| `objects/pack/pack-*.idx`, `*.rev` | lookup tables for one pack | the same commands | derived from the pack |
| `objects/info/` | `packs` (a list for dumb transports), `commit-graph`, `alternates` | `git gc`; `alternates` by `git clone --shared` | derived, except `alternates` |
| `refs/heads/`, `refs/tags/`, `refs/remotes/`, `refs/stash` | loose refs, one file each | every command that moves a ref | primary |
| `packed-refs` | many refs in one text file | `git pack-refs`, `git gc`, `git clone` | primary |
| `logs/HEAD`, `logs/refs/...` | reflogs | every ref update | primary, never cloned or pushed |
| `index` | the staging area | `git add`, `git commit`, `git switch`, `git merge`, `git status` | derived, except for what is staged |
| `COMMIT_EDITMSG` | the message of the commit in progress or of the last one | `git commit` | scratch |
| `ORIG_HEAD`, `FETCH_HEAD`, `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`, `REBASE_HEAD`, `AUTO_MERGE`, `MERGE_MSG`, `MERGE_MODE`, `rebase-merge/`, `BISECT_*` | root refs and the state of an operation in progress | the operation | state (section 3.10) |
| `reftable/` | refs and reflogs in the reftable format | every ref update, in a reftable repository | primary (section 3.13) |
| `modules/`, `worktrees/`, `shallow` | repositories of submodules; data of linked worktrees; the boundary of a shallow clone | Chapters 23, 25 and 26 | primary |

**In production.** The directory is the whole history: a container image, a CI cache or a backup that includes `.git` includes every version of every file, also the credentials file that was "deleted" two years ago. A copy of `.git` taken while no Git process is writing is a complete backup, and the only kind that includes reflogs, hooks, `info/exclude` and local configuration. And the right column of the table is your triage sheet in an incident: derived data is rebuilt, primary data is restored from another copy.

## 3.3 The loose object format

**In one sentence.** A loose object is one compressed file whose content is a short header, a NUL byte and the data, and whose file name is the hash of exactly those bytes.

**Analogy.** A sealed envelope filed under a number that is computed from what is inside it. Two envelopes with the same content get the same number, so the office keeps one; an envelope whose content differs by one character gets an unrelated number. The analogy breaks at correction: a real archive can fix a filing mistake by relabelling, and here the label cannot be changed without changing the content.

**Precisely.** The manual defines the format in three sentences: the object is the prefix `<type> <size>\0` followed by the data, where the type is `blob`, `tree`, `commit` or `tag` and the size is the length of the data in decimal; prefix and data together are compressed with zlib and stored; and "the object ID of the object is the SHA-1 or SHA-256 (as appropriate) hash of the uncompressed data" ([gitformat-loose](https://github.com/git/git/blob/v2.56.0/Documentation/gitformat-loose.adoc)). The file sits under `objects/`, in a directory named after the first two hexadecimal digits of the ID. `git hash-object <file>` 🟢 computes the ID that the file's content has as a blob, and writes the object with `-w`. It hashes what `git add` would store: if a clean filter or a line-ending conversion applies to the path, that is the converted content (`--no-filters` hashes the file as it is; Chapter 14C).

**Inside `.git`.** One new file under `objects/`, created read-only. Nothing else: no index entry, no ref, no reflog line.

**See it.**

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

The object file is not the working tree file. Decompress it and hash it yourself:

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

`shasum` knows nothing about Git and prints the same forty digits. That is all an object ID is: a hash of `blob 16`, a NUL byte, and sixteen bytes of content. The compression is a storage detail and is not part of the identity.

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

`-t` prints the type, `-s` the size of the data without the header, `-p` the content. The ID depends on nothing except the content: not the file name, not the directory, not the time, not the author, not the repository. One changed byte gives an ID that has nothing in common with the old one.

**Picture.**

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

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git hash-object -w <file>` | unchanged | unchanged | unchanged | unchanged | one new file under `objects/`, unless the object already exists; without `-w`, nothing | unchanged | unchanged |

An object in the database is not a tracked file. Tracking is a matter of the index:

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

`git add` created the index entry and wrote no second object: the blob it needed was already there, under the name it would have computed.

**In production.** Content addressing gives you three properties for free. Deduplication: the same lock file on forty branches is one object. Integrity: an ID is a checksum, so a copy of an object from any clone, backup or colleague is known to be the right bytes if its ID matches. Idempotence: recording the same content twice changes nothing. The second property is the foundation of every recovery in this book; Lab 16.2 uses it to repair a damaged pack from a file in the working tree.

## 3.4 The four object types in full

**In one sentence.** A blob is the bytes of one file, a tree is one directory listing, a commit is a snapshot with its ancestry and its metadata, and a tag object is a named, dated pointer to another object.

**Analogy.** A filesystem taken apart. Blobs are file contents with the name torn off, trees are the directory pages that put names back, and a commit is a dated cover sheet stapled to the top directory page, noting which cover sheets came before. The analogy breaks at mutation: a directory entry points at a place whose content can change, a tree entry points at content. Change one file, and its blob, every tree above it and the commit are new objects with new IDs.

**Precisely.** The four types and what each does not contain:

| Type | Content | Deliberately absent |
|---|---|---|
| blob | the bytes of a file, or the target path of a symbolic link | name, mode, timestamps |
| tree | entries of mode, name and object ID, sorted by name | its own path; any history |
| commit | headers `tree`, `parent`, `author`, `committer`, optional headers, a blank line, the message | a diff; a branch name |
| tag | headers `object`, `type`, `tag`, `tagger`, a blank line, the message, optionally a signature | any guarantee that the ref of the same name still points at it |

**Inside `.git`.** Each is one entry in the object database, loose or packed, stored and named exactly as section 3.3 describes; the type is the first word of the header.

### Trees and the five entry modes

The demo repository is a small inference service whose top-level directory contains every kind of entry Git can record:

<!-- snippet: ch03/object-types/01-tree-modes -->
```text
$ ls -F
config.toml
current-model@
models/
run.sh*
src/
tokenizer/
$ git ls-tree HEAD
100644 blob 60a72d9888260645df622ecd424e474d09d40560	config.toml
120000 blob ac850302da978fa7e1ffb2915871a2a50175cfea	current-model
040000 tree a67ce55a4207beac5330d0947d65bffa4354fc52	models
100755 blob ea66be4ca05594e98649f4f08ac9fa9ff25578dc	run.sh
040000 tree c009bc4782e140b36dc7a2136770393623a345bf	src
160000 commit 9eb542d53a49342a2e19fbca1482a3d10d638739	tokenizer
# A symbolic link is a blob whose content is the target path:
$ git cat-file -p HEAD:current-model; echo
models/v2.bin
```
<!-- /snippet -->

| Mode | The entry is | The ID names |
|---|---|---|
| `100644` | a regular file | a blob |
| `100755` | an executable file | a blob |
| `120000` | a symbolic link | a blob whose content is the link target |
| `040000` | a directory | another tree |
| `160000` | a gitlink, the record of a submodule | a commit in another repository |

These five are the complete list ([gitdatamodel](https://github.com/git/git/blob/v2.56.0/Documentation/gitdatamodel.adoc)). The modes look like Unix permissions and are not: the executable bit is the only permission Git records; owner, group, the other bits and all timestamps are not in the repository. A directory exists only as a tree with entries, which is why an empty directory cannot be committed. The commit that a gitlink names is not stored here at all; `git cat-file` reports it as missing in section 3.5, correctly ([Chapter 23](ch23-submodules.md)).

`git ls-tree` and `git cat-file -p` print a tree in a readable form. The stored form is binary:

<!-- snippet: ch03/object-types/02-tree-raw -->
```text
$ git cat-file -p HEAD:src
040000 tree 1722c9815eb7036ae06efcaf8d93c9c3140fb744	handlers
100644 blob e2238784c412f0a5151764c07c7a44e7b3a9c073	server.py
# The same tree as stored: mode, space, name, NUL, then the ID as 20 raw bytes.
$ git cat-file tree HEAD:src | xxd
00000000: 3430 3030 3020 6861 6e64 6c65 7273 0017  40000 handlers..
00000010: 22c9 815e b703 6ae0 6efc af8d 93c9 c314  "..^..j.n.......
00000020: 0fb7 4431 3030 3634 3420 7365 7276 6572  ..D100644 server
00000030: 2e70 7900 e223 8784 c412 f0a5 1517 64c0  .py..#........d.
00000040: 7c7a 44e7 b3a9 c073                      |zD....s
```
<!-- /snippet -->

Read the hex dump against the listing: each entry is the mode in ASCII (`40000`, without the leading zero the listing prints), a space, the name, a NUL byte, and the object ID as twenty raw bytes (`17 22 c9 81 ...` is `1722c981...`). The type column of the listing is not stored; Git derives it from the mode.

### Commits, header by header

<!-- snippet: ch03/object-types/03-commit -->
```text
$ git log --graph --oneline
*   0c2cf43 Merge feature/batching
|\  
| * 62001eb Add batch size setting
* | 4f2cc0c Add readiness handler
|/  
* b602c1f Add inference service skeleton
# A merge commit: one tree, two parent headers.
$ git cat-file -p HEAD
tree 31fc0d39799d6931bb12f7befeb250a539f84a96
parent 4f2cc0c5f842120f109977a97bc72acef5aa5ccd
parent 62001eb879c6506f6d3c8e625dfadfa5029367b7
author Lab User <you@example.com> 1788756720 +0530
committer Lab User <you@example.com> 1788756720 +0530

Merge feature/batching
# A root commit has no parent header at all:
$ git cat-file -p HEAD~2
tree b6f6972aea97f7f084242c2b859bf307959a0920
author Lab User <you@example.com> 1788756360 +0530
committer Lab User <you@example.com> 1788756360 +0530

Add inference service skeleton
```
<!-- /snippet -->

| Header | How many | Meaning |
|---|---|---|
| `tree` | exactly one | the ID of the top-level tree: the complete snapshot |
| `parent` | none, one or several | the commits this one follows, in order: the first is the commit you were on, the second is the one you merged |
| `author` | one | who wrote the change: name, email, seconds since 1 January 1970 UTC, time-zone offset |
| `committer` | one | who created this commit object, in the same format; it differs from the author after an amend, a rebase, a cherry-pick or an applied patch (Chapter 6) |
| `encoding` | optional | the encoding of the message when it is not UTF-8 |
| `gpgsig` | optional | a signature over the rest of the commit; the header has this name for OpenPGP, SSH and X.509 signatures alike (Chapter 14B) |
| `mergetag` | optional | the complete signed tag object that this commit merged |

After the headers come one blank line and the message. A header value that spans several lines continues on lines that begin with a space. `gpgsig` and `mergetag` are documented in `git help gitformat-signature`. Both were checked on Git 2.55.0 with a throwaway SSH key, which also showed that the header is named `gpgsig-sha256` in a SHA-256 repository; the output is not printed because a signature differs on every run. The `encoding` header is deterministic:

<!-- snippet: ch03/object-types/06-encoding -->
```text
# An optional header: the encoding of the message when it is not UTF-8.
$ printf 'max_tokens = 256\n' >> config.toml
$ git -c i18n.commitEncoding=ISO-8859-1 commit -q -am "Add token limit"
$ git cat-file -p HEAD
tree 4274d7332863c24a4bebec4082f0ea6c6fdbd467
parent 0c2cf4371cac2e5d412153dc58293c0cb484c4ba
author Lab User <you@example.com> 1788757800 +0530
committer Lab User <you@example.com> 1788757800 +0530
encoding ISO-8859-1

Add token limit
```
<!-- /snippet -->

A commit ID is computed like a blob ID, over the header `commit <size>`, a NUL byte, and the text you have been reading:

<!-- snippet: ch03/object-types/04-commit-id -->
```text
# A commit ID is the hash of "commit <size>", a NUL byte, and exactly the text above.
$ git cat-file -s HEAD
271
$ (printf 'commit %s\0' "$(git cat-file -s HEAD)"; git cat-file commit HEAD) | shasum
0c2cf4371cac2e5d412153dc58293c0cb484c4ba  -
$ git rev-parse HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
```
<!-- /snippet -->

Follow that through. The commit contains the ID of its tree, which contains the IDs of every blob and subtree; it contains the IDs of its parents, which contain the IDs of theirs. One commit ID therefore fixes every file in the snapshot and every commit behind it, and nothing in a commit can be edited: a different message, timestamp or parent is a different text with a different hash. "Amending" and "rebasing" always create new commits (Chapters 6 and 9).

### Annotated tags

<!-- snippet: ch03/object-types/05-tag -->
```text
$ git cat-file -t v1.0.0
tag
$ git cat-file -t v1.0.0-rc1
commit
$ git cat-file -p v1.0.0
object 0c2cf4371cac2e5d412153dc58293c0cb484c4ba
type commit
tag v1.0.0
tagger Lab User <you@example.com> 1788756780 +0530

Release 1.0.0
# The ref holds the ID of the tag object; ^{} peels it to the commit it tags.
$ git rev-parse v1.0.0 "v1.0.0^{}" HEAD
0b624edf4a556c702b6ed110ef2702570ced1558
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
```
<!-- /snippet -->

`v1.0.0-rc1` is a lightweight tag: a ref that holds a commit ID, and nothing else. `v1.0.0` is an annotated tag: the ref holds the ID of a tag object, and the tag object names the commit, its type, the tag's own name, who tagged and when. `v1.0.0^{}` peels the tag, that is, follows it until it reaches something that is not a tag.

**Picture.** The objects of the demo repository and how they point at each other:

```text
 refs/tags/v1.0.0 --> tag 0b624ed --> commit 0c2cf43 --tree--> tree 31fc0d3
                                       |          |              100644 blob 60a72d9  config.toml
                          1st parent   |          |  2nd parent  120000 blob ac85030  current-model
                                       v          v              040000 tree a67ce55  models
                           commit 4f2cc0c      commit 62001eb    100755 blob ea66be4  run.sh
                                       |          |              040000 tree c009bc4  src
                                       v          v              160000 commit 9eb542d  tokenizer
                                    commit b602c1f (root)                (in another repository)
```

Every arrow is an object ID stored inside the object at its tail, and there are none in the other direction: a blob does not know which trees contain it, and a commit does not know its children or its branches.

**In production.** A deploy step fails with "permission denied" on `run.sh` on the server and works on every laptop: `git ls-tree HEAD run.sh` shows `100644`, so the executable bit was never recorded, and the fix is a commit that changes the mode (`git update-index --chmod=+x run.sh`, [Chapter 4](ch04-working-tree.md)). A release is "the same code" as the last one according to its notes: compare `git rev-parse v1.0.0^{tree}` with the tree of the other tag. Equal tree IDs mean identical content in every file.

## 3.5 Reading objects: `git cat-file`, `git ls-tree`, `git show`

**In one sentence.** `git cat-file` answers questions about objects (type, size, content, existence) for one object or for millions, `git ls-tree` lists a tree, and `git show` formats any object for a person.

**Precisely.** All three only read. The forms of `git cat-file`:

| Form | Answers |
|---|---|
| `git cat-file -t <object>` | the type |
| `git cat-file -s <object>` | the size of the content in bytes, without the header |
| `git cat-file -p <object>` | the content, formatted according to its type |
| `git cat-file -e <object>` | whether the object exists, by exit status only |
| `git cat-file <type> <object>` | the raw content; `git cat-file tree HEAD` also steps from the commit to its tree |
| `git cat-file --batch-check[=<format>]` | one line per name read from standard input |
| `git cat-file --batch` | the same line followed by the content |
| `... --batch-all-objects` | every object in the database, reachable or not, without reading standard input |

`<object>` is anything that `git rev-parse` can resolve (section 3.6): an ID, a ref, `HEAD^{tree}`, `HEAD:path`.

**See it.**

<!-- snippet: ch03/read-objects/01-cat-file -->
```text
# Type, size and content of one object, named three different ways.
$ git cat-file -t HEAD
commit
$ git cat-file -t "HEAD^{tree}"
tree
$ git cat-file -t HEAD:config.toml
blob
$ git cat-file -s HEAD:config.toml
46
$ git cat-file -p HEAD:config.toml
retry_limit = 3
timeout_s = 30
batch_size = 8
# -e answers "does this object exist?" with the exit status only.
$ git cat-file -e HEAD:config.toml
[exit status: 0]
$ git cat-file -e 1234567890123456789012345678901234567890
[exit status: 1]
```
<!-- /snippet -->

Starting one process per object is slow in a script. The batch modes read names from standard input and answer in one process:

<!-- snippet: ch03/read-objects/02-batch-check -->
```text
# Many objects in one process: names on standard input, one line of output each.
$ printf 'HEAD\nHEAD^{tree}\nHEAD:run.sh\nv1.0.0\nno-such-branch\n' | git cat-file --batch-check
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit 271
31fc0d39799d6931bb12f7befeb250a539f84a96 tree 214
ea66be4ca05594e98649f4f08ac9fa9ff25578dc blob 42
0b624edf4a556c702b6ed110ef2702570ced1558 tag 137
no-such-branch missing
# A custom format. %(rest) echoes whatever followed the name on the input line.
$ git ls-tree -r HEAD | awk '{print $3, $4}' | git cat-file --batch-check='%(objectsize) %(objecttype) %(rest)'
46 blob config.toml
13 blob current-model
11 blob models/v2.bin
42 blob run.sh
30 blob src/handlers/health.py
29 blob src/handlers/ready.py
40 blob src/server.py
9eb542d53a49342a2e19fbca1482a3d10d638739 missing
```
<!-- /snippet -->

The default line is ID, type, size. A name that does not resolve gives `<name> missing` and the command carries on. With a custom format, `%(rest)` repeats whatever followed the name on the input line, which is how the second command carries each path through to the output. Its last line is the gitlink: the tree names commit `9eb542d`, and this object database does not contain it.

<!-- snippet: ch03/read-objects/03-batch-all-objects -->
```text
# Every object in the database, reachable or not, without walking any history:
$ git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
   8 blob
   4 commit
   1 tag
   9 tree
# The three largest blobs in the whole history, with the path that leads to them:
$ git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | grep '^blob' | sort -k2 -n | tail -3
blob 40 src/server.py
blob 42 run.sh
blob 46 config.toml
```
<!-- /snippet -->

Twenty-two objects for four commits. `--batch-all-objects` visits loose and packed objects without walking any history, so it also finds objects that nothing refers to. The second command is the first one to run when a repository is larger than expected: `git rev-list --objects --all` prints every reachable object with the path that leads to it, and `cat-file` adds the sizes.

`git ls-tree` reads one tree, or with `-r` every tree below it:

<!-- snippet: ch03/read-objects/04-ls-tree -->
```text
$ git ls-tree HEAD src/
040000 tree 1722c9815eb7036ae06efcaf8d93c9c3140fb744	src/handlers
100644 blob e2238784c412f0a5151764c07c7a44e7b3a9c073	src/server.py
# -r recurses into subtrees and lists only the leaves; -t also shows the trees on the way.
$ git ls-tree -r HEAD
100644 blob 60a72d9888260645df622ecd424e474d09d40560	config.toml
120000 blob ac850302da978fa7e1ffb2915871a2a50175cfea	current-model
100644 blob ba6f678b335f69ce9ddd1551c01e264366b80a6b	models/v2.bin
100755 blob ea66be4ca05594e98649f4f08ac9fa9ff25578dc	run.sh
100644 blob 7dd511683bc85b8cb7d31982e55a6d1a06f814f9	src/handlers/health.py
100644 blob 1ea8895d490a68d48ff799a4b567792e5fb4c2fb	src/handlers/ready.py
100644 blob e2238784c412f0a5151764c07c7a44e7b3a9c073	src/server.py
160000 commit 9eb542d53a49342a2e19fbca1482a3d10d638739	tokenizer
$ git ls-tree -r -t HEAD src
040000 tree c009bc4782e140b36dc7a2136770393623a345bf	src
040000 tree 1722c9815eb7036ae06efcaf8d93c9c3140fb744	src/handlers
100644 blob 7dd511683bc85b8cb7d31982e55a6d1a06f814f9	src/handlers/health.py
100644 blob 1ea8895d490a68d48ff799a4b567792e5fb4c2fb	src/handlers/ready.py
100644 blob e2238784c412f0a5151764c07c7a44e7b3a9c073	src/server.py
# -l adds the blob size; -d lists only trees.
$ git ls-tree -l HEAD
100644 blob 60a72d9888260645df622ecd424e474d09d40560      46	config.toml
120000 blob ac850302da978fa7e1ffb2915871a2a50175cfea      13	current-model
040000 tree a67ce55a4207beac5330d0947d65bffa4354fc52       -	models
100755 blob ea66be4ca05594e98649f4f08ac9fa9ff25578dc      42	run.sh
040000 tree c009bc4782e140b36dc7a2136770393623a345bf       -	src
160000 commit 9eb542d53a49342a2e19fbca1482a3d10d638739       -	tokenizer
$ git ls-tree -d --name-only HEAD
models
src
tokenizer
```
<!-- /snippet -->

Without `-r` you see one directory level, with trees as entries. With `-r` you see only the leaves, which is the flat list of paths that a checkout would create; `-t` adds the trees that were passed on the way. `-l` prints sizes, and prints `-` where an entry is not a blob. `-d` keeps the entries that are directories, the gitlink among them.

`git show` is the porcelain on top and picks a presentation by object type:

<!-- snippet: ch03/read-objects/05-show -->
```text
# git show adapts to the object type. A blob: its content.
$ git show HEAD:config.toml
retry_limit = 3
timeout_s = 30
batch_size = 8
# A tree: the names in it.
$ git show "HEAD^{tree}"
tree HEAD^{tree}

config.toml
current-model
models/
run.sh
src/
tokenizer
# An annotated tag: the tag object, then the commit it points at.
$ git show --no-patch v1.0.0
tag v1.0.0
Tagger: Lab User <you@example.com>
Date:   Mon Sep 7 10:23:00 2026 +0530

Release 1.0.0

commit 0c2cf4371cac2e5d412153dc58293c0cb484c4ba
Merge: 4f2cc0c 62001eb
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:22:00 2026 +0530

    Merge feature/batching
# A commit in raw form: the object headers, then the message.
$ git show --no-patch --format=raw HEAD^2
commit 62001eb879c6506f6d3c8e625dfadfa5029367b7
tree 537b759e6f31d04b14514d85b1cca6e8db79933c
parent b602c1fa61adb577fc9ca3113292b7cf734e856a
author Asha Rao <asha@example.com> 1788756480 +0530
committer Asha Rao <asha@example.com> 1788756480 +0530

    Add batch size setting
```
<!-- /snippet -->

**In production.** Reading a file as it was in another commit without touching the working tree: `git show <commit>:<path>`. Finding what makes a repository large: the `rev-list` and `--batch-check` pipeline above, sorted by size. Checking in CI that a commit exists before deploying it: `git cat-file -e "$id^{commit}"`, which fails for a missing object and for an ID that names anything other than a commit.

## 3.6 Turning names into IDs: `git rev-parse`

**In one sentence.** `git rev-parse` resolves anything that can name an object to its object ID and answers questions about the repository itself, by the same rules that every other Git command applies to its arguments.

**Precisely.** The revision syntax, as defined in `git help revisions`:

| You write | It means | In the demo repository |
|---|---|---|
| `main`, `v1.0.0`, `HEAD` | the object that the ref names; for an annotated tag, the tag object | `0c2cf43`; the tag `0b624ed` |
| `HEAD~2` | two steps back, following first parents only | `b602c1f` |
| `HEAD^2` | the second parent of a merge; `HEAD^1` or `HEAD^` is the first | `62001eb` |
| `HEAD^{tree}` | the object of that type reached by following the name: here the commit's tree | `31fc0d3` |
| `v1.0.0^{commit}`, `v1.0.0^{}` | the tag peeled to a commit; peeled until it is no longer a tag | `0c2cf43` |
| `HEAD:src/server.py` | the blob or tree at that path in that commit | `e223878` |
| `:config.toml`, `:2:config.toml` | the entry for the path in the index; the entry at stage 2 | section 3.12 |
| `main@{1}` | the previous value of the ref, read from its reflog | `4f2cc0c` |

A bare name is looked up in a fixed order: `$GIT_DIR/<name>`, then `refs/<name>`, `refs/tags/<name>`, `refs/heads/<name>`, `refs/remotes/<name>` and `refs/remotes/<name>/HEAD`. A tag therefore wins over a branch of the same name; Git 2.55 prints `warning: refname 'main' is ambiguous.` and uses the tag. In scripts, write the full name, `refs/heads/main`.

**See it.**

<!-- snippet: ch03/rev-parse/01-revisions -->
```text
$ git log --graph --oneline
*   0c2cf43 Merge feature/batching
|\  
| * 62001eb Add batch size setting
* | 4f2cc0c Add readiness handler
|/  
* b602c1f Add inference service skeleton
$ git rev-parse HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
$ git rev-parse --short HEAD
0c2cf43
# ~2 follows first parents twice. ^2 is the second parent of a merge. ^1 is the first.
$ git rev-parse HEAD~2 HEAD^2 HEAD^1
b602c1fa61adb577fc9ca3113292b7cf734e856a
62001eb879c6506f6d3c8e625dfadfa5029367b7
4f2cc0c5f842120f109977a97bc72acef5aa5ccd
# From a commit to its tree, to a subtree, to a blob:
$ git rev-parse "HEAD^{tree}" HEAD:src HEAD:src/server.py
31fc0d39799d6931bb12f7befeb250a539f84a96
c009bc4782e140b36dc7a2136770393623a345bf
e2238784c412f0a5151764c07c7a44e7b3a9c073
# A tag object, and the commit it peels to:
$ git rev-parse v1.0.0 "v1.0.0^{commit}"
0b624edf4a556c702b6ed110ef2702570ced1558
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
```
<!-- /snippet -->

**Picture.** The same answers on the graph:

```text
                62001eb   feature/batching                   HEAD^2
               /       \
   b602c1f ---+         +--- 0c2cf43   main, tag v1.0.0   (HEAD -> main)
               \       /
                4f2cc0c   tag v1.0.0-rc1                     HEAD^1 = HEAD~1

   HEAD~2 = HEAD^1^1 = b602c1f                  ~ counts generations, ^ chooses a parent
```

The other direction, from an ID or a short name to a full name, and the reflog and index forms:

<!-- snippet: ch03/rev-parse/02-names -->
```text
$ git rev-parse --abbrev-ref HEAD
main
$ git rev-parse --symbolic-full-name HEAD
refs/heads/main
$ git rev-parse --symbolic-full-name v1.0.0 feature/batching
refs/tags/v1.0.0
refs/heads/feature/batching
# The previous value of a branch comes from its reflog:
$ git rev-parse "main@{1}"
4f2cc0c5f842120f109977a97bc72acef5aa5ccd
# A leading colon reads the index, not a commit:
$ git rev-parse :config.toml
60a72d9888260645df622ecd424e474d09d40560
```
<!-- /snippet -->

The second family of options describes the repository. These are what a script should use in place of assumptions about paths:

<!-- snippet: ch03/rev-parse/03-repository -->
```text
$ git rev-parse --git-dir --show-toplevel
.git
$LAB/ch03/rev-parse/inference-service
$ cd src/handlers
$ git rev-parse --git-dir
$LAB/ch03/rev-parse/inference-service/.git
$ git rev-parse --show-prefix --show-cdup
src/handlers/
../../
$ git rev-parse --is-inside-work-tree --is-bare-repository
true
false
$ git rev-parse --show-object-format --show-ref-format
sha1
files
$ git rev-parse --git-path hooks/pre-commit
../../.git/hooks/pre-commit
$ cd ../..
```
<!-- /snippet -->

`--git-dir` answers relative to where you are. `--show-prefix` and `--show-cdup` are the path from the top level down to the current directory and back up. `--show-object-format` and `--show-ref-format` name the two storage formats of sections 3.13 and 3.14. `--git-path` gives the location of a file inside the repository, and stays right when the repository is a linked worktree or an environment variable relocates part of it.

Error handling is where scripts go wrong:

<!-- snippet: ch03/rev-parse/04-errors -->
```text
# Without --verify, rev-parse prints what it cannot resolve on standard output:
$ id=$(git rev-parse no-such-branch 2>/dev/null); echo "status=$? captured=[$id]"
status=128 captured=[no-such-branch]
# With --verify it prints one object ID or nothing, and --quiet drops the message:
$ id=$(git rev-parse --verify --quiet no-such-branch); echo "status=$? captured=[$id]"
status=1 captured=[]
$ git rev-parse --verify no-such-branch
fatal: Needed a single revision
[exit status: 128]
$ git rev-parse --verify --quiet "v1.0.0^{commit}"
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
[exit status: 0]
# --short implies --verify, so it accepts exactly one revision:
$ git rev-parse --short HEAD~2 HEAD^2
fatal: Needed a single revision
[exit status: 128]
# A merge with two parents has no third parent:
$ git rev-parse --verify "HEAD^3"
fatal: Needed a single revision
[exit status: 128]
```
<!-- /snippet -->

```text
Observed behavior : a deploy script stores the text "no-such-branch" in a variable that should hold a commit ID
Git state         : the name resolves to nothing
Mechanism         : without --verify, git rev-parse prints an argument it cannot resolve on standard output,
                    writes the error to standard error, and exits with status 128
Root cause        : the script captured standard output and never looked at the exit status
Why Git does this : the first purpose of rev-parse is to sort the arguments of a calling script into
                    revisions and everything else, so what is not a revision is passed through
Correct fix       : id=$(git rev-parse --verify --quiet "$name^{commit}") || exit 1
Prevention        : use --verify in every script; add ^{commit} when the object must exist and be a commit
```

`--verify` accepts exactly one argument and prints one ID or nothing. It checks that the argument can be turned into an ID, not that the object is in the database: a full forty-digit ID passes even if no such object exists. The peeling suffix closes that gap, because `^{commit}` has to read the object.

**In production.** `git rev-parse --show-toplevel` at the start of a script makes it independent of the calling directory; `git rev-parse --verify --quiet "refs/heads/$branch^{commit}"` tests whether a branch exists with nothing to parse; and when two people disagree about what a build contained, `git rev-parse HEAD^{tree}` in both checkouts settles it.

## 3.7 Packfiles, pack indexes and delta compression

**In one sentence.** A packfile stores many objects in one file and may store an object as a difference from a similar object, an index file beside it finds any object by ID, and none of this changes what an object is.

**Analogy.** A warehouse keeps one complete copy of a long contract and, for each earlier draft, a sheet of instructions: "copy bytes 0 to 2,400 of the complete copy, insert these twelve bytes, copy the rest". You ask for a draft by its number and always receive the complete draft. The analogy breaks at who decides: the warehouse chooses which version is kept whole, may choose differently at every reorganisation, and nothing you see through Git depends on it.

**Precisely.** Every command that records content writes loose objects. Maintenance (`git gc` 🟡 here; the automatic strategies are the subject of Chapter 26) later consolidates them into a pack:

- `pack-<checksum>.pack`: a 12-byte header (the signature `PACK`, a version, the number of objects), one entry per object, and a checksum of everything before it. An entry is a type, a size and zlib-compressed data; in the deltified form the data is a list of copy and insert instructions against a base object, named by its offset in the same pack or by its ID ([gitformat-pack](https://git-scm.com/docs/gitformat-pack)).
- `pack-<checksum>.idx`: the object IDs in sorted order, a CRC32 and the pack offset for each, and a 256-entry table saying where the IDs with each first byte begin. Finding an object is a binary search here, then one read at the offset.
- `pack-<checksum>.rev`: the reverse map, from position in the pack to position in the index.

The manual states the principle in one line: "Conceptually there are only four object types: commit, tree, tag and blob. However to save space, an object could be stored as a 'delta' of another 'base' object." Which objects are compared is a heuristic: `git pack-objects` sorts them by type, size and name, compares each with its neighbours inside a window of ten (`--window`), and does not let a chain grow deeper than fifty (`--depth`).

**Inside `.git`.** Loose object files disappear, one `.pack`, one `.idx` and one `.rev` appear under `objects/pack/`, and `git gc` also writes `packed-refs` (section 3.9) and `objects/info/commit-graph` (Chapter 26).

**See it.** An evaluation harness whose test-case file has 200 lines; five commits each change one line of it:

<!-- snippet: ch03/packfiles/01-loose -->
```text
$ git log --oneline
14fbba9 Relax case 150 to two sentences
d076308 Relax case 120 to two sentences
5c0b0dc Relax case 90 to two sentences
709d5d8 Relax case 60 to two sentences
213918f Relax case 30 to two sentences
609e81f Add evaluation cases
$ wc -l eval/cases.jsonl
     200 eval/cases.jsonl
$ git count-objects -v
count: 25
size: 100
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0
size-garbage: 0
```
<!-- /snippet -->

Twenty-five loose objects: six commits, twelve trees, six versions of `cases.jsonl` and one small configuration file. `count` and `size` describe loose objects, and `size` is disk space in KiB: every one of the 25 files occupies a 4 KiB block, however small its content.

<!-- snippet: ch03/packfiles/02-gc -->
```text
$ git gc
$ git count-objects -v
count: 0
size: 0
in-pack: 25
packs: 1
size-pack: 4
prune-packable: 0
garbage: 0
size-garbage: 0
$ find .git/objects -type f | sort
.git/objects/info/commit-graph
.git/objects/info/packs
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.idx
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.rev
```
<!-- /snippet -->

The same 25 objects, now `in-pack`, in 4 KiB instead of 100. Look inside:

<!-- snippet: ch03/packfiles/03-verify-pack -->
```text
$ git verify-pack -v .git/objects/pack/pack-*.idx
14fbba9f81a145d88e699ad6379b7844b71e855a commit 232 163 12
d076308a75023ff48e849cd91e1acac4fce7f4c6 commit 232 166 175
5c0b0dc76a1661cca61de1475a80959793e9280c commit 231 164 341
709d5d8beab89236b8649acadca336e7406c6132 commit 231 163 505
213918f93a4e5886620977a101f7181e57459140 commit 231 165 668
609e81f2752953bc7efa6215b74b1d08bde2ceef commit 173 128 833
a4e58256c921e15fecaaaf744fbdb04b37907a40 blob   16789 1372 961
26489f627fb36b56d87f8b615855f57c7888fd60 blob   17 27 2333
794774c4549fba17c4a64943e946feeac7c0ed4d tree   31 40 2360
89f3a9862e1b2373ab6e9bcac1e76d158b8c478f tree   78 85 2400
8c9b4e17e9e4d4e2aa09bd48ba220549944e06d2 tree   31 40 2485
5a92fde4e91ed06f182b9a45d78fa51d92e87e7f tree   78 85 2525
739088cda5ca15c1fd59dc40238f8852f7f677de blob   22 35 2610 1 a4e58256c921e15fecaaaf744fbdb04b37907a40
59ded879fc1920533dd82f4e9f2a55ecc7480549 tree   31 41 2645
9513db28fdebd67318d477e402e045a33336949c tree   78 84 2686
d77675f2a7b00158d41dc879b35011a742015f48 blob   17 30 2770 2 739088cda5ca15c1fd59dc40238f8852f7f677de
b19c9a4c02f3742eab5f0ccfc40e1fc2b4f66b3c tree   31 40 2800
5b0701b0d0b031208d1e4972513376c5cd0ae392 tree   78 85 2840
d900a91b8bd7c1bafc34c1c8baef1c92f5af3832 blob   22 35 2925 3 d77675f2a7b00158d41dc879b35011a742015f48
be320f0afa9a2877aa5134ee84b85c6ada640031 tree   31 40 2960
b99c6ada4476e39a26ae54f9ab22db3aec8d1f1d tree   78 84 3000
782b8e9b7662fd152695234c4ba08fde34c18f73 blob   18 30 3084 4 d900a91b8bd7c1bafc34c1c8baef1c92f5af3832
b803d0495a5e56f35f19109a922d0ca78f64c184 tree   31 41 3114
a1356effbbb0a03fd3fa3115791bcf98670794b4 tree   78 84 3155
0928d48c558a6457e11c9fa47f347fb2a190259f blob   22 35 3239 5 782b8e9b7662fd152695234c4ba08fde34c18f73
non delta: 20 objects
chain length = 1: 1 object
chain length = 2: 1 object
chain length = 3: 1 object
chain length = 4: 1 object
chain length = 5: 1 object
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack: ok
```
<!-- /snippet -->

The columns are object ID, type, size, size in the pack and offset; a deltified object has two more, the depth of its chain and the ID of its base. One version of the file, `a4e58256`, is stored whole: 16,789 bytes that compress to 1,372. The other five are deltas of about twenty bytes each, and for those the size column is the size of the delta. The summary counts chain lengths.

**Picture.** The chain that the listing describes. Each arrow reads "is stored as a delta against":

```text
   newest version                                                       oldest version
   a4e58256 <--- 739088cd <--- d77675f2 <--- d900a91b <--- 782b8e9b <--- 0928d48c
   whole         depth 1       depth 2       depth 3       depth 4       depth 5
   1372 bytes    35 bytes      30 bytes      35 bytes      30 bytes      35 bytes    in the pack
   16789 bytes   16788         16787         16786         16785         16784       as an object
```

The newest version is the whole one, and the old versions are the deltas: the opposite of what "Git stores diffs" would suggest. To read the oldest version, Git reads the base and applies five deltas. The object you get is complete:

<!-- snippet: ch03/packfiles/04-snapshots-intact -->
```text
# Logical size, size on disk, and delta base of each version of the file, newest first:
$ git log --format='%H:eval/cases.jsonl' | git cat-file --batch-check='%(objectname) %(objectsize) %(objectsize:disk) %(deltabase)'
a4e58256c921e15fecaaaf744fbdb04b37907a40 16789 1372 0000000000000000000000000000000000000000
739088cda5ca15c1fd59dc40238f8852f7f677de 16788 35 a4e58256c921e15fecaaaf744fbdb04b37907a40
d77675f2a7b00158d41dc879b35011a742015f48 16787 30 739088cda5ca15c1fd59dc40238f8852f7f677de
d900a91b8bd7c1bafc34c1c8baef1c92f5af3832 16786 35 d77675f2a7b00158d41dc879b35011a742015f48
782b8e9b7662fd152695234c4ba08fde34c18f73 16785 30 d900a91b8bd7c1bafc34c1c8baef1c92f5af3832
0928d48c558a6457e11c9fa47f347fb2a190259f 16784 35 782b8e9b7662fd152695234c4ba08fde34c18f73
# The oldest version sits at the end of a five-step chain and still reads back whole:
$ git cat-file -p 0928d48c | wc -l
     200
$ git cat-file -p 0928d48c | sed -n 30p
{"id": 30, "prompt": "Summarise ticket 30 in one sentence", "expected_tokens": 30}
$ git cat-file -p HEAD:eval/cases.jsonl | sed -n 30p
{"id": 30, "prompt": "Summarise ticket 30 in two sentences", "expected_tokens": 30}
```
<!-- /snippet -->

`%(objectsize)` is the size of the object, `%(objectsize:disk)` is what its entry costs in the pack, and `%(deltabase)` is all zeros for an object that is stored whole. Three statements keep the two levels apart:

1. A delta is between two objects chosen for similarity, not "the change a commit made"; the base can be another version of the same file or a different file.
2. IDs are computed from full content, so packing changes no ID, no tree and no commit, and `git cat-file`, `git show` and `git checkout` always deliver full content.
3. The choice of base "is arbitrary and is subject to change during a repack" (`git help cat-file`), so a size on disk says little about which commit "caused" it.

The files themselves:

<!-- snippet: ch03/pack-anatomy/01-pack-file -->
```text
$ ls .git/objects/pack
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.idx
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
pack-8027c3005e9ed6293511e1bef76969aa63a131bc.rev
# The first twelve bytes of the pack: signature, version, number of objects (0x19 is 25).
$ head -c 12 .git/objects/pack/pack-*.pack | xxd
00000000: 5041 434b 0000 0002 0000 0019            PACK........
# The last twenty bytes: a checksum of everything before them. It is also the name of the file.
$ tail -c 20 .git/objects/pack/pack-*.pack | xxd -p
8027c3005e9ed6293511e1bef76969aa63a131bc
```
<!-- /snippet -->

<!-- snippet: ch03/pack-anatomy/02-pack-index -->
```text
# The index starts with a magic number and its own version:
$ head -c 8 .git/objects/pack/pack-*.idx | xxd
00000000: ff74 4f63 0000 0002                      .tOc....
# Its entries, decoded: offset in the pack, object ID, CRC32. They are sorted by object ID:
$ git show-index < .git/objects/pack/pack-*.idx | head -4
3239 0928d48c558a6457e11c9fa47f347fb2a190259f (713cb177)
12 14fbba9f81a145d88e699ad6379b7844b71e855a (197f240b)
668 213918f93a4e5886620977a101f7181e57459140 (d1bdaf2c)
2333 26489f627fb36b56d87f8b615855f57c7888fd60 (ac6cf501)
# Sorted by offset instead, the same entries give the order of the objects inside the pack:
$ git show-index < .git/objects/pack/pack-*.idx | sort -n | head -4
12 14fbba9f81a145d88e699ad6379b7844b71e855a (197f240b)
175 d076308a75023ff48e849cd91e1acac4fce7f4c6 (06d8d7ea)
341 5c0b0dc76a1661cca61de1475a80959793e9280c (b18d9a25)
505 709d5d8beab89236b8649acadca336e7406c6132 (7d7faf7e)
# The index ends with the checksum of its pack, then a checksum of itself:
$ tail -c 40 .git/objects/pack/pack-*.idx | xxd -p -c 20
8027c3005e9ed6293511e1bef76969aa63a131bc
d34871f7ea2e09071ce733054562a3a8be5765c3
```
<!-- /snippet -->

The pack is named after its own checksum. The index starts with `\377tOc` and version 2, lists the IDs in sorted order with the offsets `12`, `175`, `341` that the pack listing showed, and ends with the checksum of the pack it belongs to. The index is derived data: Lab 16.1 deletes it and rebuilds an identical one with `git index-pack`.

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git gc` | unchanged | unchanged | unchanged | same value; the loose file moves into `packed-refs` | loose objects become a pack; `packed-refs` and `commit-graph` written; reflog entries past their expiry removed; unreachable objects past the grace period deleted | unchanged | unchanged |

After a `git gc`, new commits are loose objects again, next to the pack, until the next consolidation. That is the normal state of a working repository.

> **Version note.** Older behavior: porcelain commands ran `git gc --auto` when about 6,700 loose objects or 50 packs had accumulated. Current behavior: automatic maintenance uses the "geometric" strategy and does not run `git gc`. Since: Git 2.54 ([maintenance configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/maintenance.adoc)). Recommended: learn the storage model here with `git gc`, and read Chapter 26 for what runs on its own.

**In production.** The answer to the fourth question of section 3.1: four hundred versions of a line-oriented 16 MB file that differ in a few records cost roughly one compressed copy plus four hundred small deltas. Three limits apply. Deltas need similar bytes, so compressed archives and model weights gain nothing. Files above `core.bigFileThreshold` (512 MiB by default) are stored without any attempt at deltas. And a clone transfers a pack, so everything reachable is downloaded however well it compresses (Chapters 22 and 26).

## 3.8 Reachability, `git fsck`, and where Git checks its hashes

**In one sentence.** An object is reachable if you can arrive at it from a starting point by following the IDs stored inside objects; `git fsck` verifies that everything reachable is present and well-formed, and lists what nothing reaches.

**Analogy.** A library with a catalogue. A book is findable if a card names it or a findable book cites it. A book that nothing names is still on its shelf, complete, until the next clear-out. The analogy breaks at direction: in Git, citations only run from newer to older (a commit names its parents, never its children), so losing the card for the newest commit of a line makes the whole line unfindable at once.

**Precisely.** The glossary: one object is reachable from another "if we can reach the one from the other by a chain that follows tags to whatever they tag, commits to their parents or trees, and trees to the trees or blobs that they contain". An unreachable object is one that no starting point reaches; a dangling object is an unreachable object that no other unreachable object refers to, the tip of a lost line. The starting points of `git fsck` are "the index file, all SHA-1 references in the `refs` namespace, and all reflogs" (`git help fsck`), plus `HEAD`. Garbage collection keeps the same set alive and deletes an unreachable object only after a grace period, two weeks by default (`gc.pruneExpire`).

**Inside `.git`.** `git fsck` changes nothing. `git gc` removes unreachable objects from `objects/` once they are past the grace period, and `git reflog expire` removes lines from `logs/`.

**See it.**

<!-- snippet: ch03/fsck-reachability/01-healthy -->
```text
# A healthy repository: no output, exit status 0.
$ git fsck
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch03/fsck-reachability/02-dangling-blob -->
```text
# Stage a file, then change your mind and unstage it.
$ printf 'api_token = "test-0000-not-a-real-token"\n' > secrets.toml
$ git add secrets.toml
$ git rm --cached --quiet secrets.toml
$ git status --short
?? secrets.toml
# The index entry is gone. The blob that "git add" wrote is not:
$ git fsck
dangling blob e6773e7e30f399953039ee95529a70c172b7bf5e
$ git cat-file -p e6773e7e
api_token = "test-0000-not-a-real-token"
```
<!-- /snippet -->

Unstaging removed an index entry, not the blob that `git add` had written: anyone with access to this directory can still read the token (Chapter 21B), and the same fact saves you the day you lose a staged file.

<!-- snippet: ch03/fsck-reachability/03-unreachable -->
```text
# A commit on a branch, and then the branch is deleted.
$ git switch --quiet -c experiment/cache
$ printf 'cache_ttl_s = 300\n' >> config.toml
$ git commit --quiet -am "Add cache TTL"
$ git switch --quiet main
$ git branch -D experiment/cache
Deleted branch experiment/cache (was 728ac29).
# Starting from refs and the index only (--no-reflogs), four objects are unreachable:
# the commit, its tree, its new blob, and the blob that was unstaged earlier.
$ git fsck --no-reflogs --unreachable
unreachable blob e6773e7e30f399953039ee95529a70c172b7bf5e
unreachable commit 728ac2949c899feb5120ad1d50640f48e299c311
unreachable tree 73c1adebf83ff39f155fe1236171279e58109bc6
unreachable blob 35376fb465bd033dbe3a382c6a66467bef321292
# Only the objects that nothing at all points to are called dangling:
$ git fsck --no-reflogs
dangling blob e6773e7e30f399953039ee95529a70c172b7bf5e
dangling commit 728ac2949c899feb5120ad1d50640f48e299c311
```
<!-- /snippet -->

Four objects are unreachable from the refs and the index, and two of them are dangling. The tree `73c1ade` and the blob `35376fb` are not dangling, because the unreachable commit refers to them. Find the dangling commit and you have found everything behind it.

<!-- snippet: ch03/fsck-reachability/04-reflog-still-holds-it -->
```text
# The HEAD reflog still records the commit, which is what keeps it safe for now:
$ git reflog -3
0c2cf43 HEAD@{0}: checkout: moving from experiment/cache to main
728ac29 HEAD@{1}: commit: Add cache TTL
0c2cf43 HEAD@{2}: checkout: moving from main to experiment/cache
$ git log --oneline -1 "HEAD@{1}"
728ac29 Add cache TTL
# With reflog entries as starting points again, only the blob is left over:
$ git fsck
dangling blob e6773e7e30f399953039ee95529a70c172b7bf5e
```
<!-- /snippet -->

**Picture.**

```text
  starting points                         objects
  refs/heads/main --------------------->  0c2cf43 ---> trees and blobs, parents ...   reachable
  refs/tags/..., index, HEAD
  reflog entry HEAD@{1} --------------->  728ac29 ---> 73c1ade ---> 35376fb           reachable
                                          (commit)     (tree)       (blob)            through the reflog only
  nothing ------------------------------  e6773e7                                     dangling
                                          (blob that was staged and unstaged)
```

One reflog entry stands between the deleted branch and the garbage collector. Entries expire (90 days by default, 30 when the commit is no longer reachable from the ref's tip; the lab configuration switches both off), and a deleted branch loses its own reflog at once. [Chapter 13](ch13-recovery.md) builds its procedures on these facts.

```text
Observed behavior : git fsck reports "dangling commit" for a commit that git reflog still lists
Git state         : the only reference to the commit is a reflog entry dated later than the current time
Mechanism         : git fsck notes the time at which it starts and ignores reflog entries newer than that
Root cause        : the entry was written with a committer date in the future: a wrong system clock,
                    or a script that sets GIT_COMMITTER_DATE
Why Git does this : fsck must not be confused by commits that are created while it runs; skipping
                    newer reflog entries is the "coarse solution" its commit message describes
Correct fix       : none is needed; git gc does not apply the rule, and the commit is not deleted
Prevention        : read "dangling" as information; compare with git reflog before pruning anything
```

<!-- snippet: ch03/fsck-reflog-clock/02-fsck -->
```text
# Reflog entries in the past count as starting points. Nothing is dangling:
$ git -C dated-2001 reflog --date=short
2cc599e HEAD@{2001-01-01}: reset: moving to HEAD~1
778d03a HEAD@{2001-01-01}: commit: Raise retry limit
2cc599e HEAD@{2001-01-01}: commit (initial): Add configuration
$ git -C dated-2001 fsck
[exit status: 0]
# Reflog entries dated after "now" are skipped, so the dropped commit looks dangling:
$ git -C dated-2099 reflog --date=short
a3c4e27 HEAD@{2099-01-01}: reset: moving to HEAD~1
279be34 HEAD@{2099-01-01}: commit: Raise retry limit
a3c4e27 HEAD@{2099-01-01}: commit (initial): Add configuration
$ git -C dated-2099 fsck
dangling commit 279be34d74a15f6b04f2ec46f2113b8dc8291065
[exit status: 0]
# The commit is in the reflog either way, and the reflog is what you recover from:
$ git -C dated-2099 log --oneline -1 "HEAD@{1}"
279be34 Raise retry limit
```
<!-- /snippet -->

<!-- snippet: ch03/fsck-reflog-clock/03-gc-keeps-it -->
```text
# Garbage collection does not apply the clock rule. Even with no grace period, the commit stays:
$ git -C dated-2099 gc --quiet --prune=now
$ git -C dated-2099 cat-file -t "HEAD@{1}"
commit
$ git -C dated-2099 count-objects -v | grep -e count -e in-pack
count: 0
in-pack: 6
# fsck still calls it dangling. "Dangling" is a statement about fsck starting points, not a verdict:
$ git -C dated-2099 fsck
dangling commit 279be34d74a15f6b04f2ec46f2113b8dc8291065
[exit status: 0]
```
<!-- /snippet -->

> **Version note.** Older behavior: `git fsck` treated every reflog entry as a starting point. Current behavior: entries dated after the moment fsck starts are skipped; fsck reads the system clock for this. Since: Git 2.53.0, with the commit ["fsck: snapshot default refs before object walk"](https://github.com/git/git/commit/f6b262581a885a11e3e817bf635303e40b640f2a); `builtin/fsck.c` has the check at the [v2.53.0 tag](https://github.com/git/git/blob/v2.53.0/builtin/fsck.c) and not at v2.52.0. Verified locally: Git 2.55.0 applies it, Apple's Git 2.50.1 does not. Recommended: nothing to configure; know that the two Gits on your Mac can disagree about one repository.

### Where the hash is checked, and where it is not

An object ID is a checksum, and Git does not recompute it on every read. A file under `objects/` that is a well-formed object with the wrong content is served as it is:

<!-- snippet: ch03/object-integrity/01-tamper -->
```text
$ git rev-parse HEAD:src/server.py
e2238784c412f0a5151764c07c7a44e7b3a9c073
$ git cat-file -p HEAD:src/server.py
def predict(text):
    return len(text)
# Overwrite that loose object with a valid zlib stream: same header, same length, other content.
$ chmod u+w .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073
$ python3 -c "import sys, zlib; open(sys.argv[1], 'wb').write(zlib.compress(b'blob 40\0def predict(text):\n    return 999999999\n'))" .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073
# Ordinary commands read the object by its name and do not recompute the hash:
$ git cat-file -p HEAD:src/server.py
def predict(text):
    return 999999999
[exit status: 0]
$ git status --short
[exit status: 0]
```
<!-- /snippet -->

This substitution was crafted. Random damage, such as a flipped bit, normally breaks the zlib stream and fails loudly on the first read (Lab 16.2). Two operations do recompute IDs from content:

<!-- snippet: ch03/object-integrity/02-detect -->
```text
# git fsck hashes what it finds and compares the result with the file name:
$ git fsck
error: bf8a76ba21df71f4f19002c42f44ea784df0f99d: hash-path mismatch, found at: .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073
missing blob e2238784c412f0a5151764c07c7a44e7b3a9c073
[exit status: 3]
# A fetch-style transfer rebuilds every ID on the receiving side, so the bad object cannot travel:
$ git clone --quiet --no-local . ../clone-over-transport
fatal: did not receive expected object e2238784c412f0a5151764c07c7a44e7b3a9c073
fatal: fetch-pack: invalid index-pack output
[exit status: 128]
# A plain file copy has no such check:
$ git clone --quiet . ../clone-by-file-copy
[exit status: 0]
$ git -C ../clone-by-file-copy cat-file -p HEAD:src/server.py
def predict(text):
    return 999999999
```
<!-- /snippet -->

`git fsck` hashes what it finds and compares the result with the name. A transfer through Git's transport sends object content without IDs, and the receiving side computes every ID itself, so an object cannot arrive under a name that its content does not have. A clone from a local path skips the transport and copies or hard-links the files, bad object included; `--no-local` forces the transport.

<!-- snippet: ch03/object-integrity/03-repair -->
```text
# The working tree still holds the true content, and content alone determines the ID.
$ git hash-object src/server.py
e2238784c412f0a5151764c07c7a44e7b3a9c073
# Git will not rewrite an object it believes it has, so remove the bad file first.
$ rm -f .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073
$ git hash-object -w src/server.py
e2238784c412f0a5151764c07c7a44e7b3a9c073
$ git fsck
[exit status: 0]
$ git cat-file -p HEAD:src/server.py
def predict(text):
    return len(text)
```
<!-- /snippet -->

The repair is the property of section 3.3 used in reverse: content determines the ID, so the same content from anywhere restores the object.

**In production.** Run `git fsck` on a schedule against the repositories you could not afford to lose (mirrors, backups, the build server's clone); treat `missing` and `error:` lines as an incident and `dangling` lines as routine. Take backups through Git's transport (`git clone --mirror` from a URL, or `--no-local` from a path) when you want every hash recomputed on the way, and as a file copy when you also need reflogs and hooks. The reachability rule is also the precise form of an uncomfortable fact about leaked secrets: removing a commit from every branch leaves it in the object database of every clone that has it.

## 3.9 Refs in depth: loose refs, `packed-refs` and symbolic refs

**In one sentence.** A ref is a name that holds an object ID or the name of another ref, and in the default `files` format a ref is a small file under `refs/`, a line in `packed-refs`, or both.

**Analogy.** Signposts. Each carries a name and points at one house (an object); a few point at another signpost (symbolic refs). Moving a signpost is cheap and changes no house. The analogy breaks at demolition: in Git, a house that no signpost leads to is eventually torn down (section 3.8).

**Precisely.** The glossary defines a ref as "a name that points to an object name or another ref (the latter is called a symbolic ref)". Names either start with `refs/` or sit in the root of the hierarchy (section 3.10). The namespaces under `refs/`:

| Namespace | Names | Moved by |
|---|---|---|
| `refs/heads/<name>` | a local branch | `git commit`, `git merge`, `git reset`, `git rebase`, `git branch -f` |
| `refs/tags/<name>` | a tag, pointing at a commit or at a tag object | `git tag`; meant to stay put |
| `refs/remotes/<remote>/<name>` | a remote-tracking branch: the last known position of a branch in that remote | `git fetch`, `git push` |
| `refs/stash` | the newest stash entry; older entries live in its reflog | `git stash` |
| `refs/bisect/`, `refs/notes/`, `refs/replace/`, others | refs owned by a tool | that tool |

In the `files` format, a loose ref is a file holding the ID and a newline, a symbolic ref is a file holding `ref: <name>`, and `packed-refs` is one sorted text file with many refs. Lookup reads the loose file first and `packed-refs` second, and "subsequent updates to branches always create new files under `$GIT_DIR/refs`" ([git-pack-refs](https://github.com/git/git/blob/v2.56.0/Documentation/git-pack-refs.adoc)). The plumbing works the same in every format: `git for-each-ref` lists and formats, `git show-ref` lists and verifies, `git update-ref` 🟡 writes or deletes one ref with an optional check of its old value, `git symbolic-ref` 🟡 reads and writes symbolic refs, and `git pack-refs` 🟢 moves loose refs into `packed-refs` without changing a value.

**Inside `.git`.** Files under `refs/`, the file `packed-refs`, and for every update a line in the corresponding file under `logs/`.

**See it.** The demo repository with a remote, a stash entry and two tags:

<!-- snippet: ch03/refs-storage/01-loose-refs -->
```text
$ find .git/refs -type f | sort
.git/refs/heads/feature/batching
.git/refs/heads/main
.git/refs/remotes/origin/HEAD
.git/refs/remotes/origin/main
.git/refs/stash
.git/refs/tags/v1.0.0
.git/refs/tags/v1.0.0-rc1
$ cat .git/refs/heads/main
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
$ cat .git/refs/tags/v1.0.0
0b624edf4a556c702b6ed110ef2702570ced1558
# Two symbolic refs. They hold a ref name, not an object ID:
$ cat .git/HEAD
ref: refs/heads/main
$ cat .git/refs/remotes/origin/HEAD
ref: refs/remotes/origin/main
```
<!-- /snippet -->

<!-- snippet: ch03/refs-storage/02-list -->
```text
$ git for-each-ref
62001eb879c6506f6d3c8e625dfadfa5029367b7 commit	refs/heads/feature/batching
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit	refs/heads/main
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit	refs/remotes/origin/HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit	refs/remotes/origin/main
0c3d1b1c205d3248bab3061f235ef2309f653b49 commit	refs/stash
0b624edf4a556c702b6ed110ef2702570ced1558 tag	refs/tags/v1.0.0
4f2cc0c5f842120f109977a97bc72acef5aa5ccd commit	refs/tags/v1.0.0-rc1
$ git for-each-ref --format='%(refname:short) -> %(objectname:short) %(upstream:short)' refs/heads
feature/batching -> 62001eb 
main -> 0c2cf43 origin/main
# show-ref can peel annotated tags (the ^{} lines) and test for existence:
$ git show-ref --tags --dereference
0b624edf4a556c702b6ed110ef2702570ced1558 refs/tags/v1.0.0
0c2cf4371cac2e5d412153dc58293c0cb484c4ba refs/tags/v1.0.0^{}
4f2cc0c5f842120f109977a97bc72acef5aa5ccd refs/tags/v1.0.0-rc1
$ git show-ref --verify refs/heads/main
0c2cf4371cac2e5d412153dc58293c0cb484c4ba refs/heads/main
[exit status: 0]
$ git show-ref --exists refs/heads/no-such-branch
error: reference does not exist
[exit status: 2]
```
<!-- /snippet -->

`for-each-ref` prints ID, type and full name by default, and `--format` chooses any field; `%(upstream:short)` is the information that `git branch -vv` prints after each branch. `show-ref --dereference` adds a `^{}` line with the commit that an annotated tag peels to. `--verify` takes a full name and `--exists` answers by exit status.

<!-- snippet: ch03/refs-storage/03-update-ref -->
```text
# A branch is a ref, so plumbing can create one: name, new value, reflog message.
$ git update-ref -m "experiment: start at the release candidate" refs/heads/experiment v1.0.0-rc1
$ git branch --list --verbose experiment
  experiment 4f2cc0c Add readiness handler
# With a third argument the update happens only if the ref still has that old value.
$ git update-ref refs/heads/experiment main b602c1fa61adb577fc9ca3113292b7cf734e856a
fatal: update_ref failed for ref 'refs/heads/experiment': cannot lock ref 'refs/heads/experiment': is at 4f2cc0c5f842120f109977a97bc72acef5aa5ccd but expected b602c1fa61adb577fc9ca3113292b7cf734e856a
[exit status: 128]
$ git update-ref refs/heads/experiment main v1.0.0-rc1
[exit status: 0]
$ git reflog show experiment
0c2cf43 experiment@{0}: 
4f2cc0c experiment@{1}: experiment: start at the release candidate
# Two refusals: an object that does not exist, and a branch that would not name a commit.
$ git update-ref refs/heads/broken 1234567890123456789012345678901234567890
fatal: update_ref failed for ref 'refs/heads/broken': trying to write ref 'refs/heads/broken' with nonexistent object 1234567890123456789012345678901234567890
[exit status: 128]
$ git update-ref refs/heads/broken HEAD:config.toml
fatal: update_ref failed for ref 'refs/heads/broken': trying to write non-commit object 60a72d9888260645df622ecd424e474d09d40560 to branch 'refs/heads/broken'
[exit status: 128]
$ git update-ref -d refs/heads/experiment
```
<!-- /snippet -->

`update-ref` is how a branch comes into being: a name, a value and a reflog message, with no checkout involved. With a third argument it is a compare-and-swap: the update happens only if the ref still has the expected old value, which keeps concurrent writers from overwriting each other and is the idea behind `git push --force-with-lease` ([Chapter 12](ch12-remote-operations.md)). It refuses an ID that names no object and a non-commit under `refs/heads/`. `--stdin` applies several updates as one transaction: if one fails, none is written.

<!-- snippet: ch03/refs-storage/04-symbolic-ref -->
```text
$ git symbolic-ref HEAD
refs/heads/main
$ git symbolic-ref --short HEAD
main
$ git symbolic-ref refs/remotes/origin/HEAD
refs/remotes/origin/main
# Any ref can be symbolic. This one makes "latest" another name for main:
$ git symbolic-ref refs/heads/latest refs/heads/main
$ cat .git/refs/heads/latest
ref: refs/heads/main
$ git rev-parse latest main
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
$ git symbolic-ref --delete refs/heads/latest
# Detached HEAD: the file holds an object ID, so there is no symbolic ref to read.
$ git switch --quiet --detach v1.0.0-rc1
$ cat .git/HEAD
4f2cc0c5f842120f109977a97bc72acef5aa5ccd
$ git symbolic-ref HEAD
fatal: ref HEAD is not a symbolic ref
[exit status: 128]
$ git switch --quiet main
```
<!-- /snippet -->

A symbolic ref is a name for a name: `HEAD` is the one you use every day, `refs/remotes/origin/HEAD` records the default branch of the remote, and a detached `HEAD` holds an ID instead.

<!-- snippet: ch03/refs-storage/06-packed-refs -->
```text
$ git pack-refs --all
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
0c2cf4371cac2e5d412153dc58293c0cb484c4ba refs/heads/main
0c2cf4371cac2e5d412153dc58293c0cb484c4ba refs/remotes/origin/main
0c3d1b1c205d3248bab3061f235ef2309f653b49 refs/stash
0b624edf4a556c702b6ed110ef2702570ced1558 refs/tags/v1.0.0
^0c2cf4371cac2e5d412153dc58293c0cb484c4ba
4f2cc0c5f842120f109977a97bc72acef5aa5ccd refs/tags/v1.0.0-rc1
# The loose files are gone, except the symbolic ref, which cannot be packed:
$ find .git/refs -type f | sort
.git/refs/remotes/origin/HEAD
# The next update writes a loose file again. It wins over the stale packed line:
$ printf 'max_tokens = 256\n' >> config.toml
$ git commit --quiet -am "Add token limit"
$ find .git/refs -type f | sort
.git/refs/heads/main
.git/refs/remotes/origin/HEAD
$ grep refs/heads/main .git/packed-refs
0c2cf4371cac2e5d412153dc58293c0cb484c4ba refs/heads/main
$ git rev-parse main
a8eea183b656f17da1e2456a2e49995e8388fcb4
```
<!-- /snippet -->

The header lists the traits of the file: `peeled` and `fully-peeled` promise that every annotated tag is followed by a `^` line with the commit it points at, and `sorted` that the lines are in order. Symbolic refs are never packed. The last commands show the rule that trips scripts: after the next update, the loose file is back and wins, and the line in `packed-refs` is stale.

```text
Observed behavior : a release script runs "cat .git/refs/heads/main" and finds no file; a variant greps
                    packed-refs and stamps the build with last week's commit
Git state         : main was packed by git gc (or arrived packed from git clone), then moved on
Mechanism         : lookup reads the loose file first and packed-refs second; maintenance moves loose
                    refs into packed-refs; a later update writes a new loose file and leaves the old line
Root cause        : the scripts read one of several storage locations instead of asking Git
Why Git does this : one file per ref wastes space and is slow with thousands of refs
Correct fix       : git rev-parse --verify refs/heads/main
Prevention        : never read .git/refs or packed-refs from a script; use rev-parse, for-each-ref,
                    update-ref and symbolic-ref, which also work with reftable
```

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git update-ref refs/heads/<b> <id>` | unchanged | unchanged | unchanged | moves if `<b>` is the current branch, and then no longer matches the index and working tree | the ref and a line in its reflog | unchanged | unchanged |
| `git symbolic-ref HEAD refs/heads/<b>` | unchanged | unchanged | now names `<b>` | unchanged | a line in `logs/HEAD` | unchanged | unchanged |
| `git pack-refs --all` | unchanged | unchanged | unchanged | same value, stored in `packed-refs` | loose ref files removed except symbolic refs | unchanged | unchanged |

**In production.** Put your automation on `git for-each-ref --format=...`; it needs no parsing, and `git branch --format` and `git tag --format` accept the same language (`git for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short)' refs/heads` lists branches by age). Treat `update-ref` on a checked-out branch and `symbolic-ref HEAD` as repairs that leave the index and the working tree behind. And read a stale `packed-refs` line as what it is: harmless, as long as nothing reads it by hand.

## 3.10 Root refs, pseudorefs, and the state of an operation

**In one sentence.** A few refs live directly in the repository directory instead of under `refs/`, with names in capital letters that end in `_HEAD`; two of them, `FETCH_HEAD` and `MERGE_HEAD`, are not refs at all in the strict sense and are called pseudorefs.

**Precisely.** The glossary's naming rule for a root ref: upper-case letters and underscores only, and the name is `HEAD` or ends in `_HEAD`, plus five irregular names such as `AUTO_MERGE` and `MERGE_AUTOSTASH`. A pseudoref is "a ref that has different semantics than normal refs. These refs can be read via normal Git commands, but cannot be written to by commands like git-update-ref(1)"; the glossary lists two: `FETCH_HEAD`, which "may refer to multiple object IDs", each annotated with its source, and `MERGE_HEAD`, which "contains all commit IDs which are being merged" ([gitglossary](https://git-scm.com/docs/gitglossary)).

> **Version note.** Older behavior: the glossary called every special file under `.git` a pseudoref and gave `MERGE_HEAD` and `CHERRY_PICK_HEAD` as examples. Current behavior: "pseudoref" means `FETCH_HEAD` and `MERGE_HEAD` only; the others are root refs, stored by the ref backend like any other ref. Since: Git 2.46 ([glossary at v2.45.0](https://github.com/git/git/blob/v2.45.0/Documentation/glossary-content.txt), [at v2.46.0](https://github.com/git/git/blob/v2.46.0/Documentation/glossary-content.txt)). Recommended: say "root ref" for `ORIG_HEAD` and its relatives, and notice that older tutorials and the description of `--include-root-refs` in `git help for-each-ref` still use the old wording.

The names, who writes them, and when they go away (`git help revisions`, and Lab 17.3, which visits each one):

| Name | Written by | Holds | Gone when |
|---|---|---|---|
| `HEAD` | `git init`, `git switch`, `git checkout` | the current branch, or a commit ID when detached | never |
| `ORIG_HEAD` | `git merge`, `git rebase`, `git reset`, `git am`; on Git 2.55 also `git stash push` | where `HEAD` was before | overwritten by the next such command |
| `FETCH_HEAD` | `git fetch`, `git pull` | one line per fetched ref: ID, a `not-for-merge` marker, origin | overwritten by the next fetch |
| `MERGE_HEAD` | a `git merge` that stops | the commit or commits being merged | the merge is committed or aborted |
| `CHERRY_PICK_HEAD`, `REVERT_HEAD` | a cherry-pick or revert that stops or runs with `--no-commit` | the commit being applied | committed, skipped or aborted |
| `REBASE_HEAD` | a rebase that stops | the commit at which it stopped | continued past it, or aborted |
| `BISECT_HEAD` | `git bisect --no-checkout` | the commit to test | `git bisect reset` |
| `AUTO_MERGE` | the `ort` merge machinery when it leaves conflicts, and on Git 2.55 also a clean `git stash pop` | a tree: what was written to the working tree | the next commit |

Beside them sit files that are not refs: `MERGE_MSG` and `MERGE_MODE`, the `rebase-merge/` directory with the branch name and todo list of a rebase, `sequencer/` for a multi-commit cherry-pick or revert, and the `BISECT_*` files.

**Inside `.git`.** In the `files` format all of these are files in the top of the directory; in reftable the root refs are records in the tables and only the two pseudorefs remain files (section 3.13).

**See it.** The two pseudorefs hold more than a single ID:

<!-- snippet: ch03/root-refs/01-fetch-head -->
```text
$ git fetch origin
# One line per fetched branch: object ID, a marker for "git pull", and where it came from.
$ cat .git/FETCH_HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba		branch 'main' of ../server
62001eb879c6506f6d3c8e625dfadfa5029367b7	not-for-merge	branch 'feature/batching' of ../server
# Used as a revision, FETCH_HEAD means its first line:
$ git rev-parse FETCH_HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
```
<!-- /snippet -->

<!-- snippet: ch03/root-refs/02-merge-head -->
```text
# A merge of two branches at once, stopped before the commit is made:
$ git merge --no-commit topic/metrics topic/tracing
Fast-forwarding to: topic/metrics
Trying simple merge with topic/tracing
Automatic merge went well; stopped before committing as requested
# MERGE_HEAD holds one line per branch being merged. ORIG_HEAD holds where main was:
$ cat .git/MERGE_HEAD
228726e45b0adbf88785b4d004845222a7d5e973
67b8eefa35c8ad680fc5cb88ec2d028ba2c09cc6
$ cat .git/ORIG_HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
$ ls -A .git
COMMIT_EDITMSG
config
description
FETCH_HEAD
HEAD
hooks
index
info
logs
MERGE_HEAD
MERGE_MODE
MERGE_MSG
objects
ORIG_HEAD
refs
```
<!-- /snippet -->

That is the "different semantics": a list of IDs with notes, where a ref holds exactly one. Git reads the first line when you use the name as a revision, and `update-ref` keeps its hands off both files:

<!-- snippet: ch03/root-refs/03-root-refs -->
```text
# The refs outside refs/, as Git lists them. The two pseudorefs are not in the list:
$ git for-each-ref --include-root-refs | grep -v refs/
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit	HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba commit	ORIG_HEAD
# A root ref is an ordinary ref, so update-ref writes it. A pseudoref is refused:
$ git update-ref ORIG_HEAD HEAD~1
[exit status: 0]
$ git update-ref MERGE_HEAD HEAD~1
fatal: update_ref failed for ref 'MERGE_HEAD': refusing to update pseudoref 'MERGE_HEAD'
[exit status: 128]
$ git reflog exists ORIG_HEAD; echo "exit status: $?"
exit status: 1
$ git merge --abort
```
<!-- /snippet -->

`for-each-ref --include-root-refs` lists `HEAD` and `ORIG_HEAD` and leaves out the two pseudorefs. `ORIG_HEAD` accepts an update like any ref and has no reflog of its own.

The property that matters in an incident: these names, `HEAD` excepted, are not starting points for reachability. Section 3.8 listed the starting points: `refs/`, `HEAD`, the reflogs and the index.

<!-- snippet: ch03/root-refs/04-not-a-starting-point -->
```text
# A branch of a teammate, fetched by path without a destination ref. It lands in FETCH_HEAD only:
$ git fetch ../teammate fix/timeout
From ../teammate
 * branch            fix/timeout -> FETCH_HEAD
$ git log --oneline -1 FETCH_HEAD
25623b2 Lower the timeout to 20 seconds
# No ref under refs/ and no reflog entry names that commit, so fsck reports it.
# (The dangling tree is the result of the two-branch merge that was aborted above.)
$ git fsck
dangling commit 25623b2b4f51bc94cebfa8e80099a56f6b754270
dangling tree 7396eea3ac2000acc286f477277694a681054728
# A garbage collection without a grace period deletes it. The name stays behind and names nothing:
$ git gc --quiet --prune=now
$ cat .git/FETCH_HEAD
25623b2b4f51bc94cebfa8e80099a56f6b754270		branch 'fix/timeout' of ../teammate
$ git log --oneline -1 FETCH_HEAD
fatal: bad object FETCH_HEAD
[exit status: 128]
```
<!-- /snippet -->

`git gc --prune=now` 🔴 removes every unreachable object at once instead of after the two-week grace period, and so destroys the recovery material that `git fsck` had listed. Preview it with `git fsck --unreachable` and `git prune -n`; recover afterwards only from another clone or a backup; use it in a repository whose unreachable objects you have examined and want gone, for example after removing a leaked secret from history (Chapter 21B), and never as routine maintenance.

> **Root cause.** A commit fetched by URL into `FETCH_HEAD`, a position saved in `ORIG_HEAD`, or a tree in `AUTO_MERGE` is protected by nothing except the grace period. Give it a ref before you rely on it: `git fetch <url> <branch>:refs/heads/review/<name>`, or `git switch -c review/<name> FETCH_HEAD`.

**In production.** Automation that asks "is a merge in progress?" should resolve the name through Git, `git rev-parse --verify --quiet MERGE_HEAD`, rather than test for a file, because root refs are not files in every format (section 3.13).

## 3.11 Reflog storage under `logs/`

**In one sentence.** A reflog is an append-only record of the values a ref has had, one file per ref under `logs/` in the `files` format, written whenever the ref moves.

**Precisely.** `core.logAllRefUpdates` is `true` in a repository with a working tree, which creates logs for `HEAD`, branches, remote-tracking branches and notes; `always` extends this to every ref under `refs/`; a bare repository has it off and keeps no reflogs by default ([core configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/core.adoc)). Each line records the old ID, the new ID, the committer's identity and time, a tab, and a message naming the command. `logs/HEAD` records every move of `HEAD`, including switches between branches, which is why `git reflog` without arguments is the most complete history of what you did.

**Inside `.git`.** `logs/HEAD` and `logs/refs/<ref>`, each a text file with one line per update; nothing else is written.

**See it.**

<!-- snippet: ch03/refs-storage/05-reflog-files -->
```text
$ find .git/logs -type f | sort
.git/logs/HEAD
.git/logs/refs/heads/feature/batching
.git/logs/refs/heads/main
.git/logs/refs/remotes/origin/HEAD
.git/logs/refs/remotes/origin/main
.git/logs/refs/stash
$ cat .git/logs/refs/heads/feature/batching
0000000000000000000000000000000000000000 b602c1fa61adb577fc9ca3113292b7cf734e856a Lab User <you@example.com> 1788756420 +0530	branch: Created from HEAD
b602c1fa61adb577fc9ca3113292b7cf734e856a 62001eb879c6506f6d3c8e625dfadfa5029367b7 Asha Rao <asha@example.com> 1788756480 +0530	commit: Add batch size setting
$ git reflog show feature/batching
62001eb feature/batching@{0}: commit: Add batch size setting
b602c1f feature/batching@{1}: branch: Created from HEAD
# Tags get no reflog by default. A deleted branch loses its reflog with it:
$ git reflog exists refs/tags/v1.0.0
[exit status: 1]
$ git branch -d feature/batching
Deleted branch feature/batching (was 62001eb).
$ find .git/logs -type f | sort
.git/logs/HEAD
.git/logs/refs/heads/main
.git/logs/refs/remotes/origin/HEAD
.git/logs/refs/remotes/origin/main
.git/logs/refs/stash
```
<!-- /snippet -->

Tags get no reflog under the default setting, and deleting a branch deletes its log. `refs/stash` has a log, and that log is the stash list: every entry is a reflog line. In a reftable repository the same records live inside the tables (section 3.13), and `git reflog` reads them identically.

**Picture.** One reflog line, field by field:

```text
 b602c1fa... 62001eb8... Asha Rao <asha@example.com> 1788756480 +0530 <TAB> commit: Add batch size setting
 old value   new value   committer                   seconds    zone        message
```

**In production.** The reflog is local: it is not pushed, and a clone starts with an empty one; whether a server keeps reflogs is a decision of whoever runs it ([Chapter 12](ch12-remote-operations.md)). Entries expire as `git gc` runs, after 90 days, or 30 days for entries whose commit is no longer reachable from the tip of the ref; the lab configuration sets both to `never` so that the labs behave the same on any day. Before a risky rewrite, `git reflog show <branch>` is your cheapest insurance, and deleting a branch cancels its policy.

## 3.12 The index file

**In one sentence.** The index is one binary file that records, for every tracked path, a mode, a blob ID, a stage number and a copy of the file's `stat` data, followed by extensions that let Git skip work; it is at once the proposed next commit and the cache that makes `git status` fast.

**Analogy.** A packing list for the next shipment, with an inspection sticker on every line saying when the item was last checked and how big it was. The list becomes the commit's tree; the stickers let the clerk skip boxes nobody touched. The analogy breaks during a conflict, when the list carries three lines for one item.

**Precisely.** The format is specified in `git help gitformat-index` ([gitformat-index](https://github.com/git/git/blob/v2.56.0/Documentation/gitformat-index.adoc)). A 12-byte header: the signature `DIRC`, a version (2, 3 or 4), the number of entries. Then the entries, sorted by path as bytes and then by stage. Each entry has 40 bytes of `stat` data (change and modification time with nanoseconds, device, inode, mode, user, group, size), the object ID, and 16 bits of flags: an assume-valid bit, an "extended" bit, the two-bit stage and the length of the path; version 3 adds 16 bits with the skip-worktree and intent-to-add flags. The path follows, padded with NUL bytes to a multiple of eight; version 4 compresses each path against the previous one and drops the padding. Then the extensions, each a four-letter signature, a length and data: `TREE` caches the tree IDs that unchanged parts of the index already correspond to, `REUC` keeps the stages of a resolved conflict so that `git checkout -m` can recreate it, and others serve the split index, the untracked cache and the filesystem monitor. The file ends with a checksum, unless `index.skipHash` replaces it by zeros.

**Inside `.git`.** One file, `index`, rewritten as a whole by every command that changes it, including `git status`, which refreshes the stat data and writes the result back ([git-status](https://git-scm.com/docs/git-status)).

**See it.** The eight entries of the demo repository, as `git ls-files --stage` shows them and as the bytes begin:

<!-- snippet: ch03/index-file/01-stage -->
```text
$ git ls-files --stage
100644 60a72d9888260645df622ecd424e474d09d40560 0	config.toml
120000 ac850302da978fa7e1ffb2915871a2a50175cfea 0	current-model
100644 ba6f678b335f69ce9ddd1551c01e264366b80a6b 0	models/v2.bin
100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc 0	run.sh
100644 7dd511683bc85b8cb7d31982e55a6d1a06f814f9 0	src/handlers/health.py
100644 1ea8895d490a68d48ff799a4b567792e5fb4c2fb 0	src/handlers/ready.py
100644 e2238784c412f0a5151764c07c7a44e7b3a9c073 0	src/server.py
160000 9eb542d53a49342a2e19fbca1482a3d10d638739 0	tokenizer
# The first twelve bytes of the file: signature, version, number of entries.
$ head -c 12 .git/index | xxd
00000000: 4449 5243 0000 0002 0000 0008            DIRC........
```
<!-- /snippet -->

`4449 5243` is `DIRC`, `0000 0002` is version 2, `0000 0008` is eight entries. A sixty-line Python script in the course, `labs/ch03/read-index.py`, decodes the rest by following the manual page:

<!-- snippet: ch03/index-file/02-read-index -->
```text
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index
header     signature=DIRC version=2 entries=8
entry      100644 60a72d9888260645df622ecd424e474d09d40560 stage=0 size=46    config.toml
entry      120000 ac850302da978fa7e1ffb2915871a2a50175cfea stage=0 size=13    current-model
entry      100644 ba6f678b335f69ce9ddd1551c01e264366b80a6b stage=0 size=11    models/v2.bin
entry      100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc stage=0 size=42    run.sh
entry      100644 7dd511683bc85b8cb7d31982e55a6d1a06f814f9 stage=0 size=30    src/handlers/health.py
entry      100644 1ea8895d490a68d48ff799a4b567792e5fb4c2fb stage=0 size=29    src/handlers/ready.py
entry      100644 e2238784c412f0a5151764c07c7a44e7b3a9c073 stage=0 size=40    src/server.py
entry      160000 9eb542d53a49342a2e19fbca1482a3d10d638739 stage=0 size=0     tokenizer
extension  TREE (117 bytes)
checksum   valid
```
<!-- /snippet -->

The stat data is what the volatile demo prints; its numbers come from your filesystem and differ on every machine, so this transcript is not reproduced by `labs/verify-all.sh`:

<!-- snippet: ch03/index-debug/01-debug -->
```text
$ git ls-files --debug config.toml run.sh
config.toml
  ctime: 1790892135:837284071
  mtime: 1790892135:837284071
  dev: 16777231	ino: 67018155
  uid: 501	gid: 0
  size: 46	flags: 0
run.sh
  ctime: 1790892135:668514559
  mtime: 1790892135:665748392
  dev: 16777231	ino: 67018022
  uid: 501	gid: 0
  size: 42	flags: 0
# The same numbers, asked from the filesystem (BSD stat, as on macOS):
$ stat -f 'ctime=%c mtime=%m dev=%d ino=%i uid=%u gid=%g size=%z' config.toml
ctime=1790892135 mtime=1790892135 dev=16777231 ino=67018155 uid=501 gid=0 size=46
```
<!-- /snippet -->

Here is the cache at work. Change only the modification time of a file:

<!-- snippet: ch03/index-file/03-stat-cache -->
```text
# Change the modification time of a file, not its content.
$ touch -t 202001010000 config.toml
# Plumbing compares cached stat data only, and reports the path as possibly changed:
$ git diff-files
:100644 100644 60a72d9888260645df622ecd424e474d09d40560 0000000000000000000000000000000000000000 M	config.toml
# Porcelain re-reads the file, finds the same content, and refreshes the cached stat data:
$ git status --short
$ git diff-files
```
<!-- /snippet -->

`git diff-files`, a plumbing command, compares stat data only and reports the path as possibly changed, with an all-zero ID meaning "look at the working tree". `git status` reads the file, hashes it, finds the blob the index already names, and writes fresh stat data back; the second `diff-files` is silent. Now copy a whole repository:

<!-- snippet: ch03/index-file/04-copied-repository -->
```text
# Copy the whole repository, as a backup restore or a CI cache would.
$ cp -R . ../restored-copy
$ git -C ../restored-copy diff-files --name-status
M	config.toml
M	current-model
M	models/v2.bin
M	run.sh
M	src/handlers/health.py
M	src/handlers/ready.py
M	src/server.py
$ git -C ../restored-copy diff-files --quiet
[exit status: 1]
# New inode numbers and change times: every cached entry is stale. One refresh fixes it.
$ git -C ../restored-copy update-index --refresh
$ git -C ../restored-copy diff-files --quiet
[exit status: 0]
```
<!-- /snippet -->

Every entry is stale, because the copy has new inode numbers and change times, and no file has changed. One refresh repairs it. This is the whole explanation of "every file shows as modified" after a restore from backup, a CI cache or a `COPY` into a container, and it is never a data problem.

The flags, set by `git update-index --assume-unchanged`, `--skip-worktree` and `git add -N` ([Chapter 5](ch05-index.md) explains what each is for):

<!-- snippet: ch03/index-file/05-flags -->
```text
$ git update-index --assume-unchanged run.sh
$ git update-index --skip-worktree config.toml
$ printf '# Inference service\n' > README.md
$ git add --intent-to-add README.md
# Only the header and the entries that carry a flag:
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e "\["
header     signature=DIRC version=3 entries=9
entry      100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 stage=0 size=0     README.md  [intent-to-add]
entry      100644 60a72d9888260645df622ecd424e474d09d40560 stage=0 size=46    config.toml  [skip-worktree]
entry      100755 ea66be4ca05594e98649f4f08ac9fa9ff25578dc stage=0 size=42    run.sh  [assume-valid]
```
<!-- /snippet -->

Setting a version-3 flag upgraded the file from version 2 to version 3 on the spot, and the intent-to-add entry names the empty blob. Stages appear when a merge stops:

<!-- snippet: ch03/index-file/06-stages -->
```text
$ git merge feature/timeouts
Auto-merging config.toml
CONFLICT (content): Merge conflict in config.toml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
# One path, three entries: stage 1 is the merge base, 2 is ours, 3 is theirs.
$ git ls-files --unmerged
100644 60a72d9888260645df622ecd424e474d09d40560 1	config.toml
100644 cf333b0c40d2484e3c6d5040d289bdfb06d7e62a 2	config.toml
100644 62235dd3403d45d5edec627dcf862fe1b0ba940e 3	config.toml
$ git cat-file -p :1:config.toml | grep timeout
timeout_s = 30
$ git cat-file -p :2:config.toml | grep timeout
timeout_s = 45
$ git cat-file -p :3:config.toml | grep timeout
timeout_s = 60
```
<!-- /snippet -->

<!-- snippet: ch03/index-file/07-resolve -->
```text
$ git restore --theirs config.toml
$ git add config.toml
$ git ls-files --stage config.toml
100644 62235dd3403d45d5edec627dcf862fe1b0ba940e 0	config.toml
# The three stages moved into the "resolve undo" extension (REUC):
$ python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e extension -e checksum
header     signature=DIRC version=2 entries=8
extension  TREE (98 bytes)
extension  REUC (93 bytes)
checksum   valid
$ git commit --quiet -m "Merge feature/timeouts"
```
<!-- /snippet -->

One path, three entries: stage 1 is the merge base, 2 is ours, 3 is theirs ([Chapter 8](ch08-merge.md)). `git add` replaced the three by one stage-0 entry and moved them into the `REUC` extension. Finally the version field:

<!-- snippet: ch03/index-file/08-version-4 -->
```text
$ git update-index --show-index-version
2
$ wc -c < .git/index
     898
$ git update-index --index-version 4
$ head -c 12 .git/index | xxd
00000000: 4449 5243 0000 0004 0000 0008            DIRC........
$ wc -c < .git/index
     860
$ git update-index --index-version 2
```
<!-- /snippet -->

Version 4 saved 38 bytes here by sharing path prefixes; in a repository with a hundred thousand paths the saving is what makes `feature.manyFiles` worth switching on (Chapter 26).

**Picture.** One entry in version 2, as the reader script walks it:

```text
 header     DIRC | version | entry count                                            12 bytes
 entry      ctime  ctime_ns  mtime  mtime_ns  dev  ino  mode  uid  gid  size        40 bytes of stat data
            object ID                                                               20 bytes
            flags: assume-valid | extended | stage (2 bits) | path length           2 bytes
            path, NUL, padding to a multiple of 8 bytes                             variable
 ...        one entry per path, and per stage during a conflict, sorted by path
 extension  TREE | size | cached tree IDs        REUC | size | the stages that were resolved
 checksum   hash of everything above                                                20 bytes
```

**In production.** Three incidents and their first command. "Everything is modified after the restore": `git update-index --refresh`. "`git status` takes a minute on the monorepo": the stat cache already does its job; the next steps are `core.untrackedCache`, `core.fsmonitor` and `feature.manyFiles` (Chapter 26). "`fatal: index file corrupt`": delete the file and run `git reset`; history and working tree are untouched, and only what was staged and not committed must be staged again (Lab 17.1).

## 3.13 The reftable backend

**In one sentence.** reftable stores refs and reflogs in binary, block-structured tables under `.git/reftable/` instead of in loose files, `packed-refs` and `logs/`; it has been available since Git 2.45 and is planned as the default for new repositories in Git 3.0.

**Analogy.** A stack of ledgers instead of a drawer of index cards. Every transaction adds a thin ledger on top; from time to time thin ledgers are merged into a thick one, and a lookup reads the stack from the newest down. The analogy breaks at correction: a ledger page could be amended, a table never is.

**Precisely.** The tables live in `$GIT_DIR/reftable/`, and `tables.list` names the ones in use, oldest first; a table name is its first and last update number and a random suffix ([reftable](https://git-scm.com/docs/reftable)). Each table starts with a 24-byte header: `REFT`, a version byte, a block size, and the range of update numbers it covers. Two stubs stay for tools that look for them: `.git/HEAD` containing `ref: refs/heads/.invalid`, and `.git/refs/heads` as a regular file. The format is declared by `extensions.refstorage = reftable` with `core.repositoryformatversion = 1`, and a Git that does not know the extension must refuse the repository. Three ways in: `git init --ref-format=reftable` or `git clone --ref-format=reftable`, the setting `init.defaultRefFormat` (Git 2.47), or `git refs migrate --ref-format=reftable` 🟡 for an existing repository (Git 2.46), which cannot migrate a repository with linked worktrees and must not run while anything else writes ([git-refs](https://github.com/git/git/blob/v2.55.0/Documentation/git-refs.adoc)).

The project's reasons for making it the default: the `files` format cannot store two refs whose names differ only in case on the case-insensitive filesystems of macOS and Windows, deleting a packed ref rewrites the whole `packed-refs` file, and multi-ref updates are not atomic; reftable compacts geometrically after every write and uses prefix compression ([BreakingChanges](https://github.com/git/git/blob/v2.56.0/Documentation/BreakingChanges.adoc)).

**Inside `.git`.** `reftable/tables.list` and the tables it names, two extension lines in `config`, the two stubs, and no `logs/`, `packed-refs` or loose ref files.

**See it.**

<!-- snippet: ch03/reftable/01-init -->
```text
$ git init --ref-format=reftable inference-service
Initialized empty Git repository in $LAB/ch03/reftable/inference-service/.git/
$ cd inference-service
$ git rev-parse --show-ref-format
reftable
$ cat .git/config
[extensions]
	refstorage = reftable
[core]
	repositoryformatversion = 1
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
```
<!-- /snippet -->

<!-- snippet: ch03/reftable/02-stubs -->
```text
$ ls -A .git
config
description
HEAD
hooks
info
objects
refs
reftable
# Two stub files are kept for tools that look for them. Neither holds a ref:
$ cat .git/HEAD
ref: refs/heads/.invalid
$ cat .git/refs/heads
this repository uses the reftable format
# The real answer comes from Git:
$ git symbolic-ref HEAD
refs/heads/main
```
<!-- /snippet -->

<!-- snippet: ch03/reftable/03-tables -->
```text
$ printf 'retry_limit = 3\n' > config.toml
$ git add config.toml
$ git commit --quiet -m "Add service configuration"
$ git branch feature/batching
$ git tag -a v1.0.0 -m "Release 1.0.0"
# Refs and reflogs live in binary tables. tables.list names the tables in use, oldest first.
# A table name is first update number, last update number and a random suffix (masked here).
$ sed -E 's/-[0-9a-f]{8}\./-<random>./' .git/reftable/tables.list
0x000000000001-0x000000000003-<random>.ref
0x000000000004-0x000000000004-<random>.ref
# Compaction merges tables. Git does it on its own; git pack-refs asks for it explicitly:
$ git pack-refs --all
$ sed -E 's/-[0-9a-f]{8}\./-<random>./' .git/reftable/tables.list
0x000000000001-0x000000000004-<random>.ref
# The 24-byte header: REFT, version 1, block size, first and last update number.
$ head -c 24 .git/reftable/*.ref | xxd
00000000: 5245 4654 0100 1000 0000 0000 0000 0001  REFT............
00000010: 0000 0000 0000 0004                      ........
```
<!-- /snippet -->

The commit wrote update 2, the branch update 3, the tag update 4. Auto-compaction had already merged updates 1 to 3 into one table; `git pack-refs --all` merged all four. The header bytes read `REFT`, version `01`, block size `00 1000` (4,096 bytes), then update numbers 1 and 4 as 64-bit integers.

<!-- snippet: ch03/reftable/04-same-answers -->
```text
# No logs directory and no packed-refs file. Plumbing answers as in any other repository:
$ ls -A .git
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
objects
refs
reftable
$ git for-each-ref
849357d27dcaa9267a13a0be93d3ea0b5c52ea01 commit	refs/heads/feature/batching
849357d27dcaa9267a13a0be93d3ea0b5c52ea01 commit	refs/heads/main
90350c8a07136a48c3b158534161e6057047243a tag	refs/tags/v1.0.0
$ git reflog show feature/batching
849357d feature/batching@{0}: branch: Created from main
$ git rev-parse main
849357d27dcaa9267a13a0be93d3ea0b5c52ea01
```
<!-- /snippet -->

No `logs/`, no `packed-refs`, no files under `refs/heads/`, and every plumbing command answers as before. The reflog of the branch is in the same tables as the branch.

<!-- snippet: ch03/reftable/05-root-refs -->
```text
# A conflicted merge, to see where the refs outside refs/ are kept in this format:
$ git switch --quiet feature/batching && printf 'retry_limit = 4\n' > config.toml && git commit --quiet -am 'Allow four retries'
$ git switch --quiet main && printf 'retry_limit = 5\n' > config.toml && git commit --quiet -am 'Allow five retries'
$ git merge feature/batching
Auto-merging config.toml
CONFLICT (content): Merge conflict in config.toml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
# MERGE_HEAD is a file, as in every repository. ORIG_HEAD and AUTO_MERGE are not files here:
$ ls -A .git
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
MERGE_HEAD
MERGE_MODE
MERGE_MSG
objects
refs
reftable
$ git for-each-ref --include-root-refs | grep -v refs/
4c07605aeed786c4596df1b9212ab37962730b08 tree	AUTO_MERGE
1dd74b5d1a428941e018b4c2f6f98f0559cc5b27 commit	HEAD
1dd74b5d1a428941e018b4c2f6f98f0559cc5b27 commit	ORIG_HEAD
$ git merge --abort
```
<!-- /snippet -->

This is the cleanest demonstration of section 3.10: `ORIG_HEAD` and `AUTO_MERGE` are refs and live in the tables; `MERGE_HEAD` and `FETCH_HEAD` are files in every format, which is what makes them pseudorefs.

<!-- snippet: ch03/reftable/06-names -->
```text
# Names that differ only in case are two refs here, on a filesystem that ignores case:
$ git branch Hotfix
$ git branch hotfix
$ git branch --list "[Hh]otfix"
  Hotfix
  hotfix
# The same two commands in a files-format repository on the same disk:
$ git init --quiet ../files-repo
$ git -C ../files-repo commit --quiet --allow-empty -m "Start"
$ git -C ../files-repo branch Hotfix
$ git -C ../files-repo branch hotfix
fatal: a branch named 'hotfix' already exists
[exit status: 128]
# One rule of the files layout is kept: a ref cannot be both a name and a prefix of names.
$ git branch feature
fatal: 'refs/heads/feature/batching' exists; cannot create 'refs/heads/feature'
[exit status: 128]
```
<!-- /snippet -->

The last refusal is deliberate: the rule that `feature` and `feature/batching` cannot both exist is a rule of the ref namespace that the `files` layout made necessary, and reftable keeps it so that repositories stay interchangeable (Chapter 7).

<!-- snippet: ch03/reftable/07-git-3-preview -->
```text
# The two formats that Git 3.0 plans as defaults for new repositories can be chosen today:
$ git init --quiet --object-format=sha256 --ref-format=reftable ../future-repo
$ cat ../future-repo/.git/config
[extensions]
	objectformat = sha256
	refstorage = reftable
[core]
	repositoryformatversion = 1
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
```
<!-- /snippet -->

**Picture.** The comparison, as a table:

| | `files` | `reftable` |
|---|---|---|
| Default | yes, in Git 2.55 | planned for new repositories in Git 3.0 |
| Names differing only in case, on macOS or Windows | collide | distinct |
| Deleting a ref | rewrites `packed-refs` when the ref is packed | appends a record |
| Several refs in one transaction | not atomic | atomic |
| Readable with `cat` | yes, and that is the trap | no |

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git refs migrate --ref-format=reftable` | unchanged | unchanged | same target; the file becomes a stub | same value, stored in a table | `refs/*` files, `packed-refs` and `logs/` replaced by `reftable/`; `extensions.refstorage` set | unchanged | unchanged |

The ref format is local to each repository: Lab 17.2 fetches with a `files` clone from a reftable server and migrates the clone while the server stays as it is.

**In production.** Adopt reftable where it solves a problem you have: branch names that collide on a case-insensitive disk (Lab 17.2), tens of thousands of refs, or automation that updates many refs at once. Before migrating a shared repository, check every tool that opens it, stop all writers, and remember that linked worktrees block the migration. The habit that costs nothing and works in both formats: read refs through plumbing.

## 3.14 SHA-1 with collision detection versus SHA-256

**In one sentence.** Git names objects with SHA-1 by default, computed by an implementation that detects attempted collision attacks, and can create repositories that use SHA-256 instead; the two kinds cannot exchange objects, and a repository that must live on GitHub stays SHA-1.

**Precisely.** Since Git 2.13 the default SHA-1 code is the collision-detecting variant ("SHA1_DC"), which recognises the patterns of the known attacks on SHA-1; `git version --build-options` shows it ([RelNotes 2.13](https://github.com/git/git/blob/master/Documentation/RelNotes/2.13.0.adoc)). SHA-256 repositories were experimental in 2.29 and are a supported format since 2.42, created with `git init --object-format=sha256`, declared by `extensions.objectformat = sha256`, and fixed for the life of the repository: changing the setting afterwards "will not work and will produce hard-to-diagnose issues" ([extensions configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/extensions.adoc)). The format applies to object IDs, the index checksum and the pack checksums alike. There is "no interoperability between SHA-256 repositories and SHA-1 repositories" ([object-format-disclaimer](https://github.com/git/git/blob/v2.56.0/Documentation/object-format-disclaimer.adoc)); a clone adopts the format of what it clones. The project's reasons for moving are the published attacks on SHA-1; the plan to make SHA-256 the default for new repositories in Git 3.0 is conditional on libraries, applications and forges being ready, with no plan to deprecate SHA-1 ([BreakingChanges](https://github.com/git/git/blob/v2.56.0/Documentation/BreakingChanges.adoc)).

**Inside `.git`.** `extensions.objectformat = sha256` and `repositoryformatversion = 1` in `config`; object directories named by the first two of 64 hexadecimal digits; 32-byte IDs inside trees, indexes and packs.

**See it.**

<!-- snippet: ch03/sha256/01-build -->
```text
# What this Git was built with:
$ git version --build-options | grep -e SHA -e default
SHA-1: SHA1_DC
SHA-256: SHA256_BLK
default-ref-format: files
default-hash: sha1
```
<!-- /snippet -->

<!-- snippet: ch03/sha256/02-init -->
```text
$ git init --quiet sha1-repo
$ git init --quiet --object-format=sha256 sha256-repo
$ cat sha256-repo/.git/config
[extensions]
	objectformat = sha256
[core]
	repositoryformatversion = 1
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
$ git -C sha1-repo rev-parse --show-object-format
sha1
$ git -C sha256-repo rev-parse --show-object-format
sha256
```
<!-- /snippet -->

<!-- snippet: ch03/sha256/03-ids -->
```text
# The same sixteen bytes, hashed by each repository:
$ printf 'retry_limit = 3\n' > sha1-repo/config.toml
$ cp sha1-repo/config.toml sha256-repo/config.toml
$ git -C sha1-repo hash-object config.toml
f784b58423ef67be5af8d1cfdfd9bea5eaa26bae
$ git -C sha256-repo hash-object config.toml
ca399e7aeebdebc3e8ae90cbb2d8cab88b72cd16ebf654d483f48652356f1d68
# The object format is the same; only the hash function differs:
$ printf 'blob 16\0retry_limit = 3\n' | shasum -a 256
ca399e7aeebdebc3e8ae90cbb2d8cab88b72cd16ebf654d483f48652356f1d68  -
$ git -C sha256-repo log --oneline
ecfdab6 Add service configuration
$ git -C sha256-repo cat-file -p HEAD
tree 13e25952da64d7ebd81886b745d0ddef276fe0249a4869054efe6b27a72675b5
author Lab User <you@example.com> 1788756240 +0530
committer Lab User <you@example.com> 1788756240 +0530

Add service configuration
$ cat sha256-repo/.git/refs/heads/main
ecfdab60723aa25daa18b6d1de7fba739cdd5c2013ef47d827cc33d48261bfb5
```
<!-- /snippet -->

The same `blob 16`, the same NUL, the same sixteen bytes; only the hash function differs, and `shasum -a 256` agrees with Git. Everything in the repository now carries 64-digit IDs.

<!-- snippet: ch03/sha256/04-no-interop -->
```text
# The two formats cannot exchange objects, in either direction:
$ git -C sha1-repo fetch ../sha256-repo main
fatal: mismatched algorithms: client sha1; server sha256
[exit status: 128]
$ git -C sha1-repo push ../sha256-repo main:refs/heads/from-sha1
fatal: the receiving end does not support this repository's hash algorithm
fatal: the remote end hung up unexpectedly
[exit status: 128]
$ git -C sha256-repo push ../sha1-repo main:refs/heads/from-sha256
fatal: the receiving end does not support this repository's hash algorithm
fatal: the remote end hung up unexpectedly
[exit status: 128]
# A clone adopts the format of what it clones:
$ git clone --quiet sha256-repo sha256-clone
$ git -C sha256-clone rev-parse --show-object-format
sha256
```
<!-- /snippet -->

<!-- snippet: ch03/sha256/05-forty-hex -->
```text
# A check that assumes forty hexadecimal digits accepts one repository and rejects the other:
$ git -C sha1-repo rev-parse HEAD | grep -E -c '^[0-9a-f]{40}$'
1
$ git -C sha256-repo rev-parse HEAD | grep -E -c '^[0-9a-f]{40}$'
0
```
<!-- /snippet -->

> **GitHub, not Git.** GitHub had no publicly available support for SHA-256 repositories on 1 October 2026. A private preview is reported by GitLab's blog, by a community comment and by a conference speaker, but no GitHub blog post, changelog entry or documentation page announces it, so the Phase 0 report marks it unverified ([GitLab](https://about.gitlab.com/blog/whats-new-in-git-2-56-0/), [community discussion](https://github.com/orgs/community/discussions/12490)). Forgejo supports SHA-256 repositories since v7.0; GitLab announced experimental support in August 2024. Every repository in this course that touches GitHub therefore stays SHA-1.

**In production.** Decide the object format at `git init` and never afterwards. Keep every repository that is pushed to GitHub in SHA-1, and treat a SHA-256 repository as an island. And never write code that assumes forty hexadecimal digits: ask `git rev-parse --show-object-format`, or accept 40 and 64; the length is a property of the repository, not of Git.

## 3.15 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| `fatal: index file corrupt` | `head -c 12 .git/index \| xxd` does not start with `DIRC` | `rm .git/index && git reset`; stage again what was staged (Lab 17.1) | none needed; derived data |
| Every file shows as modified after a restore, a CI cache or a container copy | `git diff-files` lists everything, `git diff` shows no change | `git update-index --refresh` or any `git status` | copy repositories with Git rather than `cp` where you can |
| A script reads `.git/refs/heads/<b>` and finds no file or a stale ID | the ref is in `packed-refs`, or the repository uses reftable | `git rev-parse --verify refs/heads/<b>` | never read `.git` files in scripts |
| `git fsck` prints `dangling commit` | `git reflog` names it, or its reflog entry is dated in the future | nothing, or `git branch rescue/<x> <id>` to keep it | treat `dangling` as information |
| `hash-path mismatch` or `missing blob` from `git fsck` | an object's content does not match its name, or the object is gone | restore it from another clone, a backup or the working tree (section 3.8) | scheduled `git fsck`; backups through Git's transport |
| `pack has bad object at offset`, `failed to read delta base object` | damage inside a pack; `git verify-pack` names the offset | restore the pack from a backup or another clone, or recreate the base object and repack (Lab 16.2) | backups and mirrors |
| `warning: no corresponding .idx` | the pack index was deleted or never written | `git index-pack <pack>` (Lab 16.1) | none needed; derived data |
| `git fetch` complains about a case-insensitive filesystem | `git ls-remote` shows names that differ only in case; `git rev-parse` and `git for-each-ref` disagree | `git refs migrate --ref-format=reftable` in the clone, or rename a branch on the server (Lab 17.2) | a branch naming rule |
| `mismatched algorithms: client sha1; server sha256`, or `the receiving end does not support this repository's hash algorithm` | `git rev-parse --show-object-format` differs between the two repositories | recreate one side in the other format; there is no conversion | decide the object format at `git init` |
| `There is no merge in progress (MERGE_HEAD missing)` | a state file was removed by hand; a commit made now has one parent | rebuild the merge commit with `git commit-tree` and move the branch (Lab 17.3) | repair `.git` only with documented procedures |

## 3.16 When not to use it, and dangerous edge cases

Plumbing is for repair, inspection and automation. Use porcelain for daily work, because porcelain keeps the three trees consistent and plumbing does not:

- `git update-ref` on the checked-out branch and `git symbolic-ref HEAD` move the branch and leave the index and the working tree behind; `git status` then reports every difference as your change. Use `git switch` and `git reset` unless you are rebuilding a damaged repository.
- Deleting a file under `.git` by hand is a repair only where this book or the manual says so (`index`, a pack `.idx`); deleting `MERGE_HEAD`, a ref file or anything under `objects/` is damage.
- `git hash-object -w` and `git add` write objects that stay until they are pruned, also after the file is unstaged or the commit is dropped. A secret that was ever staged is in `.git/objects` until a garbage collection removes it, two weeks after it became unreachable at the earliest (Chapter 21B).
- `git gc --prune=now`, `git prune --expire=now`, `git reflog expire --expire=now --all` and `git repack -a -d` destroy what recovery depends on: unreachable objects and reflog entries. Run them in a copy, after `git fsck --unreachable` has shown what will go, and never while another process writes to the repository (`git help gc` carries that warning).
- `git clone <path>` copies or hard-links the object files and verifies nothing. Add `--no-local` when the point of the clone is to check them.
- `extensions.objectFormat` and `extensions.refStorage` are set by `git init` and `git refs migrate`; editing them in `.git/config` corrupts the repository. A tool built on an older Git library refuses such a repository: the repository is fine, the tool is behind.
- `git fsck` racing with a writer reports missing objects; `git gc` racing with one can delete an object the writer is about to reference. Run both on quiet repositories.

## 3.17 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git cat-file`, `git ls-tree`, `git rev-parse`, `git for-each-ref`, `git show-ref`, `git count-objects`, `git verify-pack`, `git show-index`, `git ls-files`, `git fsck` | 🟢 | nothing (`fsck --lost-found` writes copies of dangling objects under `.git/lost-found/`) | — | — |
| `git hash-object -w` | 🟢 | adds one object | `git hash-object` without `-w` | not needed |
| `git pack-refs --all`, `git update-index --index-version 4` | 🟢 | the storage of refs or of the index, not their content | — | not needed |
| `git update-ref <ref> <new> [<old>]` | 🟡 | one ref and its reflog | `git rev-parse <ref>` | `git update-ref <ref> "<ref>@{1}"` from its reflog |
| `git update-ref -d <ref>` | 🔴 | deletes the ref and its reflog, with no merge check: the safety net for that ref goes with it ([Chapter 2](ch02-mental-model.md), section 2.14 answers the five questions) | `git rev-parse <ref>`, and note the ID | `git update-ref <ref> <id>`; the HEAD reflog or `git fsck` find the ID |
| `git symbolic-ref HEAD <ref>` | 🟡 | which branch is current, without touching the index or the working tree | `git symbolic-ref HEAD` | `git symbolic-ref HEAD <previous>`; `git reflog` |
| `git refs migrate --ref-format=<f>` | 🟡 | the ref storage format; values are kept | `--dry-run` | migrate back, or restore the `.git` copy you made first |
| `git gc` | 🟡 | packs objects and refs, expires reflog entries by age, deletes unreachable objects older than two weeks | `git fsck --unreachable`; `git reflog expire --dry-run --all` | within the periods nothing is lost; beyond them, another clone or a backup |
| `git gc --prune=now`, `git prune`, `git repack -a -d` | 🔴 | deletes unreachable objects at once (`repack -a -d` drops the unreachable objects of the packs it replaces) | `git fsck --unreachable`; `git prune -n` | another clone or a backup only |
| `git reflog expire --expire=now --all` | 🔴 | deletes every reflog entry | `git reflog expire --dry-run --expire=now --all` | none for the entries; `git fsck` still finds the objects until they are pruned |

The 🔴 commands change the object database or the reflogs and can destroy every unreachable object and every record of where a ref used to point, the safety net of Chapter 13. Preview with the commands in the table, recover only from another copy, and use them after a deliberate history rewrite in a repository you have copied first, never as routine maintenance.

## 3.18 Version notes

| Topic | Older behavior | Current behavior | Since | Recommended |
|---|---|---|---|---|
| Reflog entries dated in the future | `git fsck` used every reflog entry as a starting point | entries newer than the moment `fsck` starts are skipped; `git gc` is unaffected | Git 2.53.0 (section 3.8) | read `dangling` as information |
| "pseudoref" | any special file under `.git` | only `FETCH_HEAD` and `MERGE_HEAD`; the rest are root refs | Git 2.46 | say "root ref" |
| Ref storage | loose files and `packed-refs` only | `reftable` available; `git refs migrate` converts | 2.45; migrate 2.46; `init.defaultRefFormat` 2.47 | plumbing for all ref reads |
| Object format | SHA-1 only | SHA-256 repositories supported, without interoperability | experimental 2.29; supported 2.42 | SHA-1 for anything on GitHub |
| Automatic maintenance | `git gc --auto` from porcelain commands | the geometric strategy of `git maintenance` | 2.54 | Chapter 26 |
| Git 3.0 plans for new repositories | — | SHA-256 and reftable as defaults, `main` as the initial branch; conditional, unreleased, no date in the official documentation | announced; 2.98 and 2.99 come first | opt in early with `--object-format` and `--ref-format` in throwaway repositories |

## 3.19 Practice

Labs 16.1 and 16.2 in [lab-manual/m16-object-database.md](../lab-manual/m16-object-database.md): loose objects become a pack and a missing pack index is rebuilt; a pack listing, its delta chain, and the recovery from one damaged byte. Labs 17.1 to 17.3 in [lab-manual/m17-index-refs-gitdir.md](../lab-manual/m17-index-refs-gitdir.md): the index as a data structure and the rebuild of a corrupt one; `files` against `reftable` and a case-clash; a tour of every special ref and the repair of a merge whose `MERGE_HEAD` was deleted. Then replay the demos with `labs/run ch03/<name>` and change one thing in each. Answers: [solutions/m16-lab-answers.md](../solutions/m16-lab-answers.md), [solutions/m17-lab-answers.md](../solutions/m17-lab-answers.md).

## 3.20 Interview questions

1. Compute the object ID of a blob by hand. Which bytes are hashed, and why does the compression level not matter?
2. A tree entry has mode `160000`. What is it, what object type does the ID name, and why can `git cat-file` not show it?
3. What does a commit ID commit you to? Explain why changing a commit message three commits back changes the ID of `HEAD`.
4. We have six versions of a 16 MB file. What does the pack contain, which version is stored whole, and what happens when a byte in that version is damaged?
5. `git fsck` says `dangling commit`. Walk me through what you check before you decide whether anything is at risk.
6. Why can a corrupt object survive `git cat-file` and `git status` but not a clone over the network?
7. A deploy script reads `.git/refs/heads/main`. Name two situations in which that file does not describe the branch, and the command that always does.
8. What is the difference between `ORIG_HEAD`, `FETCH_HEAD` and `refs/heads/main` as far as garbage collection is concerned?
9. Someone copied a repository with `cp -R` and now every file is "modified". Explain the mechanism and the one-command fix.
10. When would you migrate a repository to reftable, what breaks if you do it carelessly, and what stays the same?
11. Why do we keep our repositories in SHA-1 although Git supports SHA-256, and what would have to change for that to change?

## 3.21 Sources

**Primary sources.** The local manual pages for the Git you run: `git help gitformat-loose`, `gitformat-pack`, `gitformat-index`, `gitformat-signature`, `gitrepository-layout`, `gitdatamodel`, `gitglossary`, `gitrevisions`, and the pages of every command used above. Online, at the 2.56.0 tag: [gitdatamodel](https://github.com/git/git/blob/v2.56.0/Documentation/gitdatamodel.adoc), [gitformat-loose](https://github.com/git/git/blob/v2.56.0/Documentation/gitformat-loose.adoc), [gitformat-pack](https://github.com/git/git/blob/v2.56.0/Documentation/gitformat-pack.adoc), [gitformat-index](https://github.com/git/git/blob/v2.56.0/Documentation/gitformat-index.adoc), [gitformat-signature](https://github.com/git/git/blob/v2.56.0/Documentation/gitformat-signature.adoc), [gitrepository-layout](https://github.com/git/git/blob/v2.56.0/Documentation/gitrepository-layout.adoc), [glossary](https://github.com/git/git/blob/v2.56.0/Documentation/glossary-content.adoc), [revisions](https://github.com/git/git/blob/v2.56.0/Documentation/revisions.adoc), [git-refs at 2.55](https://github.com/git/git/blob/v2.55.0/Documentation/git-refs.adoc), [the reftable design](https://github.com/git/git/blob/v2.56.0/Documentation/technical/reftable.adoc), [repository format versions](https://github.com/git/git/blob/v2.56.0/Documentation/technical/repository-version.adoc), [hash-function-transition](https://github.com/git/git/blob/v2.56.0/Documentation/technical/hash-function-transition.adoc), [BreakingChanges](https://github.com/git/git/blob/v2.56.0/Documentation/BreakingChanges.adoc), the release notes for [2.13](https://github.com/git/git/blob/master/Documentation/RelNotes/2.13.0.adoc), [2.29](https://github.com/git/git/blob/master/Documentation/RelNotes/2.29.0.adoc), [2.42](https://github.com/git/git/blob/master/Documentation/RelNotes/2.42.0.adoc), [2.45](https://github.com/git/git/blob/master/Documentation/RelNotes/2.45.0.adoc), [2.46](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc), [2.51](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc) and [2.53](https://github.com/git/git/blob/master/Documentation/RelNotes/2.53.0.adoc), and the commit ["fsck: snapshot default refs before object walk"](https://github.com/git/git/commit/f6b262581a885a11e3e817bf635303e40b640f2a).

**Secondary sources.** Pro Git, chapter 10: [objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects), [packfiles](https://git-scm.com/book/en/v2/Git-Internals-Packfiles) and [maintenance and recovery](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery); frozen since May 2024, so it predates reftable and the glossary change. The GitHub Blog, [Git's database internals, part I](https://github.blog/open-source/git/gits-database-internals-i-packed-object-store/). The Phase 0 report of this course for the hosting facts of section 3.14.

**Videos.** Derrick Stolee, ["Git Internals: a Database Perspective"](https://www.youtube.com/watch?v=YdstUWcg5j4) (Git Merge 2022, 27 min): packfiles and the storage layer; current. John Britton, ["Git Internals"](https://www.youtube.com/watch?v=lG90LZotrpo) (CS50, 2018, 58 min): the object model, correct and clear; `master`, `checkout`, SHA-1 only, almost nothing on packfiles. Patrick Steinhardt, ["Reftable Backend"](https://www.youtube.com/watch?v=TqHYOGCJkS8) (2025, 20 min) and Emily Shaffer, ["SHA-256 at a Hyperscaler"](https://www.youtube.com/watch?v=eJJp0RE7cd4) (Git Merge 2026, 32 min): both assume this chapter's level; the second had almost no views when the report checked it.

**Further reading.** James Coglan, *Building Git*, teaches the formats by reimplementing them; ["Write yourself a Git"](https://wyag.thb.lt/) does the same in Python. Both predate reftable.
