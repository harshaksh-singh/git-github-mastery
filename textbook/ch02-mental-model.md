# Chapter 2: The Mental Model

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch02/`; one continues a script in `labs/ch01/`.

## 2.1 Why this matters

An evaluation report from three weeks ago says that its numbers were produced "at commit `2e76f67`". Today the numbers are disputed, and your CTO asks:

1. What does that ID pin down: one file, one change, or the whole project?
2. Could anything behind that ID have been altered since then, by accident or on purpose?
3. The same fix is on `main` as `cf6a5b3` and on the release branch as `e460212`. Is that one fix or two different things?

No command answers these. A model does: what Git stores, how it names what it stores, and how a name such as `main` relates to it. With the model, each answer is one sentence. The ID pins down every byte of every tracked file, the complete history before it, and who recorded it when. Nothing behind the ID can change without the ID changing. The two commits are the same change recorded as two different snapshots, which is what a cherry-pick produces.

Sections 2.2 to 2.9 build the model. Section 2.10 reconciles it with the intuition that a commit is a diff, section 2.11 lists the wrong models behind most Git confusion, and section 2.12 puts GitHub on the map.

## 2.2 Start from what you have: the first commit of Chapter 1

In [Chapter 1](ch01-fundamentals.md), section 1.9, five files appeared under `.git/objects` when you made the first commit of `rag-eval`. Each file is one *object*. `git cat-file -t` prints the type of an object and `git cat-file -p` prints its content in readable form. This transcript continues the Chapter 1 script (`labs/ch01/first-repo.sh`):

<!-- snippet: ch01/first-repo/08-open-objects -->
```text
$ git cat-file -t f7c044e
commit
$ git cat-file -p f7c044e
tree e621cb090a7d826cce2a614885f534bde7015533
author Lab User <you@example.com> 1788756360 +0530
committer Lab User <you@example.com> 1788756360 +0530

Add README and evaluation config
$ git cat-file -p 'f7c044e^{tree}'
100644 blob 3a79082bc80505c7543e79c4312e3e3d276a0e04	README.md
040000 tree 0d722fc2a87c4b61afef355250e6e77f41a44cd0	configs
$ git cat-file -p f7c044e:configs
100644 blob 422e9c0c59f64154ed466adcfb7b7b7c0d43e89f	eval.yaml
$ git cat-file -p f7c044e:configs/eval.yaml
model: small-v2
timeout_s: 60
```
<!-- /snippet -->

- The commit `f7c044e` contains no file name and no file content: one `tree` line, author and committer with their times, the message.
- The tree `e621cb0` is the top directory at that moment. Each entry has a mode, the type and ID of an object, and a name. `README.md` is a *blob*, an object that holds file content; `configs` is another tree.
- The tree `0d722fc` is the directory `configs/`, with one blob for `eval.yaml`.
- The blob `422e9c0` is the content of that file and nothing else: no name, no date.

`<commit>^{tree}` means "the tree of this commit", and `<commit>:<path>` means "the object at this path in this commit" ([gitrevisions](https://git-scm.com/docs/gitrevisions)).

**Picture.** Five objects, connected only by the IDs they contain.

```text
 commit f7c044e               tree e621cb0  (top directory)        tree 0d722fc  (configs/)
+-----------------------+    +--------------------------------+   +--------------------------------+
| tree e621cb0 ---------+--->| 100644 blob 3a79082  README.md |   | 100644 blob 422e9c0  eval.yaml |
| author, committer,    |    | 040000 tree 0d722fc  configs --+-->|                 |              |
| times, message        |    +-----------------|--------------+   +-----------------|--------------+
+-----------------------+                      v                                    v
                                         blob 3a79082                         blob 422e9c0
                                         # rag-eval                           model: small-v2
                                                                              timeout_s: 60
```

Git's manual counts four kinds of data in a repository ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)). The working tree is a fifth thing, and it is not repository data.

| Kind of data | What it is | Default location | Read more |
|---|---|---|---|
| Objects | Immutable commits, trees, blobs and tag objects, named by their IDs | `.git/objects/` | 2.3 to 2.7; Chapter 3: Git Internals |
| References (refs) | Names for object IDs: branches, tags, remote-tracking branches, HEAD | `.git/refs/`, `.git/HEAD` | 2.8; Chapter 7: Branches |
| The index | The next commit, as a flat list of paths | `.git/index` | 2.9; Chapter 5: Index |
| Reflogs | A local journal of the values each ref has had | `.git/logs/` | 2.7; Chapter 13: Recovery |
| Working tree | The files you edit | The project directory | 2.9; [Chapter 4](ch04-working-tree.md) |

## 2.3 Snapshots, not diffs

**In one sentence.** A commit records the complete state of every tracked file at one moment, as the ID of one tree; it does not record what changed.

**Analogy.** A photograph of the whole whiteboard after every meeting, instead of a list of what was wiped and written. Each photograph can be read on its own, and any two can be compared. The analogy breaks in one place: an album stores every photograph in full, while Git stores each distinct file content once and lets every snapshot that contains it refer to that object.

**Precisely.** The official data model lists what a commit must contain: the directory structure and file contents of that version, stored as the ID of the top-level tree; the IDs of its parent commits; an author and a committer, each with a time; and a message. It states that Git stores no diff for a commit and that `git show` calculates one from the parent when you ask ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)). Full snapshots stay cheap because a file whose content did not change is not stored again: the new tree lists the ID of the blob that already exists.

**See it.** A scorer with three files is committed; then one file changes and is committed again (`labs/ch02/snapshots.sh`). `git ls-tree` prints the tree of a commit.

<!-- snippet: ch02/snapshots/01-first-commit -->
```text
$ ls
config.yaml
judge_prompt.txt
metrics.py
$ git add .
$ git commit -m "Add scorer: metrics, judge prompt, config"
[main (root-commit) 916dec3] Add scorer: metrics, judge prompt, config
 3 files changed, 5 insertions(+)
 create mode 100644 config.yaml
 create mode 100644 judge_prompt.txt
 create mode 100644 metrics.py
$ git ls-tree HEAD
100644 blob e09e51ff381d1fdcf4ca91fce8852f43d3593e26	config.yaml
100644 blob f5970a3d9f36718a1c1e51b244e7d891dbf365d5	judge_prompt.txt
100644 blob 652e0e2f7afd2080aef8c6b86ce436380d11ecc4	metrics.py
```
<!-- /snippet -->

<!-- snippet: ch02/snapshots/02-second-commit -->
```text
$ printf 'model: small-v2\ntemperature: 0.2\n' > config.yaml
$ git commit -am "Raise judge temperature to 0.2"
[main 2e76f67] Raise judge temperature to 0.2
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git ls-tree HEAD~1
100644 blob e09e51ff381d1fdcf4ca91fce8852f43d3593e26	config.yaml
100644 blob f5970a3d9f36718a1c1e51b244e7d891dbf365d5	judge_prompt.txt
100644 blob 652e0e2f7afd2080aef8c6b86ce436380d11ecc4	metrics.py
$ git ls-tree HEAD
100644 blob f72ae7508cafa27bf9eb379d094c09b65825fe07	config.yaml
100644 blob f5970a3d9f36718a1c1e51b244e7d891dbf365d5	judge_prompt.txt
100644 blob 652e0e2f7afd2080aef8c6b86ce436380d11ecc4	metrics.py
```
<!-- /snippet -->

Compare the two listings. `judge_prompt.txt` and `metrics.py` have the same blob IDs in both commits, `f5970a3` and `652e0e2`. Only `config.yaml` has a new one, `f72ae75` instead of `e09e51f`. The second snapshot is complete, and it needed one new blob. (`git commit -a` first stages every tracked file that was modified or deleted.)

<!-- snippet: ch02/snapshots/03-all-objects -->
```text
$ git cat-file --batch-all-objects --batch-check
2e76f6786049b00c41eedcc3833d89ab882de618 commit 231
4798110f4ba90e7736ec51e1ad0ef9a5fc55912b tree 121
652e0e2f7afd2080aef8c6b86ce436380d11ecc4 blob 69
916dec36a1932b80b97f7a15d37d621c5830e6a7 commit 194
e09e51ff381d1fdcf4ca91fce8852f43d3593e26 blob 33
f3b0ea8770296178f91e353cda6f362acf83c1e7 tree 121
f5970a3d9f36718a1c1e51b244e7d891dbf365d5 blob 44
f72ae7508cafa27bf9eb379d094c09b65825fe07 blob 33
```
<!-- /snippet -->

`git cat-file --batch-all-objects --batch-check` lists every object with its type and size in bytes: two commits, two trees and four blobs, where six blobs would be needed if nothing were shared.

<!-- snippet: ch02/snapshots/04-no-diff-inside -->
```text
$ git cat-file -p HEAD
tree 4798110f4ba90e7736ec51e1ad0ef9a5fc55912b
parent 916dec36a1932b80b97f7a15d37d621c5830e6a7
author Lab User <you@example.com> 1788755880 +0530
committer Lab User <you@example.com> 1788755880 +0530

Raise judge temperature to 0.2
```
<!-- /snippet -->

The commit object holds a tree, a parent, two identities with times, and a message. It holds no diff. The diff that `git show` prints is computed when you ask for it:

<!-- snippet: ch02/snapshots/05-diff-on-demand -->
```text
$ git show HEAD
commit 2e76f6786049b00c41eedcc3833d89ab882de618
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:08:00 2026 +0530

    Raise judge temperature to 0.2

diff --git a/config.yaml b/config.yaml
index e09e51f..f72ae75 100644
--- a/config.yaml
+++ b/config.yaml
@@ -1,2 +1,2 @@
 model: small-v2
-temperature: 0.0
+temperature: 0.2
```
<!-- /snippet -->

The line `index e09e51f..f72ae75` names the two blobs that Git compared.

**Inside `.git`.** The second commit added three object files: the new blob, the new top-level tree and the commit. In Chapter 1 the second commit added four, because the changed file was in a subdirectory, so the tree of `configs/` and the top-level tree both changed. `README.md` was not stored again. That was the question section 1.9 left open.

**Picture.**

```text
 commit 916dec3 <-------------------- commit 2e76f67          (arrow: the parent link)
      |                                    |
      v                                    v
 tree f3b0ea8                         tree 4798110
   config.yaml       e09e51f            config.yaml       f72ae75    new blob
   judge_prompt.txt  f5970a3            judge_prompt.txt  f5970a3    same object
   metrics.py        652e0e2            metrics.py        652e0e2    same object
```

**In production.** Any commit can be checked out, built or compared on its own; no chain of patches is replayed. A commit costs what changed, not what exists: in a repository of 40,000 files, an edit to two files in `services/ranker/` writes two blobs, three trees (`ranker/`, `services/`, the top directory) and one commit. The same rule is the weak point for large binary files: every version of a 2 GB model file is a new 2 GB blob (Chapter 22: Git LFS).

The model says "full snapshots". Git may later pack objects into packfiles and store some as differences against similar objects (Chapter 3). That is compression below the model: `git cat-file -p` returns the full content either way.

## 2.4 Content addressing

**In one sentence.** An object's ID is a hash of the object's type and content, so identical content has the identical ID in every repository on every machine, and different content has, for all practical purposes, a different ID.

**Analogy.** A warehouse that shelves each parcel at an address computed from its content. Two warehouses in different cities put identical parcels at identical addresses without talking to each other, and an altered parcel no longer belongs at its address. The analogy breaks because nobody finds a parcel by guessing its content: you need a catalogue from names to addresses, and in Git that catalogue is the trees and the refs.

**Precisely.** The manual defines the ID, also called the object name, as a cryptographic hash of the object's type and contents ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)). With the default hash, SHA-1, an ID has 40 hexadecimal digits; commands accept and print unique prefixes such as `b5fee68`. Chapter 3 reproduces an ID with `shasum`. What is hashed decides what an ID identifies:

| Object | What is hashed | What the ID identifies |
|---|---|---|
| Blob | The bytes of the file; not its name, its mode or any time | One exact file content, wherever it occurs |
| Tree | For each entry: mode, name, object ID | One exact directory state, including everything below it |
| Commit | Tree ID, parent IDs, author, committer, both times, message | One project state, the whole history behind it, and who recorded it when |

Four properties follow. **Deduplication:** equal content is stored once, whatever its path, commit or branch. **Immutability:** an object cannot be edited, because other content is another object with another ID, so "changing a commit" always means creating a new one ([Chapter 9](ch09-rebase.md), [Chapter 11](ch11-reset-revert-restore.md)). **Integrity:** Git can recompute the hash of whatever it reads, so corruption and tampering are detectable (`git fsck`, Chapter 3). **Cheap comparison:** two files, directories or project states are equal when their IDs are equal, and merge and diff skip everything whose IDs match ([Chapter 8](ch08-merge.md)).

**See it.** `git hash-object` computes the ID that a file's content has as a blob. First outside any repository (`labs/ch02/content-ids.sh`):

<!-- snippet: ch02/content-ids/01-no-repository -->
```text
# No repository here: hash-object only computes.
$ printf 'temperature: 0.2\n' | git hash-object --stdin
b5fee68e16090ca243c174fd28853ad0abe8b77a
$ printf 'temperature: 0.2\n' | git hash-object --stdin
b5fee68e16090ca243c174fd28853ad0abe8b77a
$ printf 'temperature: 0.3\n' | git hash-object --stdin
885f7cec8d3b132ef5144951a0fc37ee1cb80fba
```
<!-- /snippet -->

The same bytes give the same ID twice; one changed character gives an unrelated ID. No repository exists here, so the ID cannot depend on one. Next, two repositories and two file names with the same bytes; with `-w` 🟢 the command also stores the object:

<!-- snippet: ch02/content-ids/02-two-repositories -->
```text
$ git init -q laptop
$ git init -q server
$ printf 'temperature: 0.2\n' > laptop/eval.yaml
$ printf 'temperature: 0.2\n' > server/settings.yaml
$ git -C laptop hash-object -w eval.yaml
b5fee68e16090ca243c174fd28853ad0abe8b77a
$ git -C server hash-object -w settings.yaml
b5fee68e16090ca243c174fd28853ad0abe8b77a
$ find laptop/.git/objects server/.git/objects -type f
laptop/.git/objects/b5/fee68e16090ca243c174fd28853ad0abe8b77a
server/.git/objects/b5/fee68e16090ca243c174fd28853ad0abe8b77a
```
<!-- /snippet -->

**Inside `.git`.** Both repositories hold an object file at the same path, `objects/b5/fee68e…`: the first two digits of the ID name a directory, the other 38 the file. Neither file name is recorded in it.

Names are stored in trees, so they show up in tree IDs. `git write-tree` 🟢 writes the index as a tree and prints its ID (section 2.6):

<!-- snippet: ch02/content-ids/03-trees -->
```text
$ git -C laptop add eval.yaml
$ git -C server add settings.yaml
$ git -C laptop write-tree
097da7ea458de812ac723fb7085d40be43fdae05
$ git -C server write-tree
8bc25e61fadf002956ecddf2f643b04dd386a8dc
$ mv server/settings.yaml server/eval.yaml
$ git -C server add -A
$ git -C server write-tree
097da7ea458de812ac723fb7085d40be43fdae05
```
<!-- /snippet -->

With different file names the two trees differ. After the rename (`git add -A` stages the removal of the old name with the new file), both repositories contain the same directory state and the tree IDs are equal: `097da7e`.

**Picture.** Each ID is computed from the IDs below it, so one changed byte changes every ID above it.

```text
 blob ID   = hash(file content)
 tree ID   = hash(names, modes, IDs of the blobs and trees in the directory)
 commit ID = hash(tree ID, parent commit IDs, author, committer, times, message)

 one byte changes in one file
   -> new blob ID -> new ID for every tree above it -> new commit ID
   -> new ID for every commit that is later built on that commit
```

**In production.** After a rollback, `git rev-parse 'HEAD^{tree}'` printing the tree ID of the last good commit proves that every tracked file is back in that state, with no file-by-file comparison (Lab 1.2). An ID in a report or an incident ticket means one exact state to everyone who has the repository; write all 40 digits, because an abbreviation is unique only in one repository at one time (`core.abbrev`). Files that look identical and have different IDs differ in bytes you cannot see, such as a carriage return (Lab 1.3). The same files committed one second later give the same tree ID and a different commit ID, which is why commits you type by hand never have the book's IDs (Chapter 1, section 1.7).

## 2.5 The four object types

| Type | Holds | Refers to | Written by |
|---|---|---|---|
| Blob | The bytes of one file | Nothing | `git add` |
| Tree | One directory: for each entry a mode, a name and an object ID | Blobs and other trees | `git commit`, from the index |
| Commit | One tree ID, the parent commit IDs, author, committer, message | Its tree and its parents | `git commit`, `git merge`, `git cherry-pick` and others |
| Tag object | The ID and type of another object, a tag name, the tagger, a message | Usually a commit | `git tag -a` |

**See it.** A repository `ranker` with one commit and one annotated tag (`labs/ch02/object-types.sh`):

<!-- snippet: ch02/object-types/01-inventory -->
```text
$ git cat-file --batch-all-objects --batch-check
08dd0d94a4c377361126a24ed13ad97267786d6f tree 35
0f7f193a9e915f3327b1349744e32c6b87e4f3a2 tag 146
572a34a9da9d2cc636c2b011e3956e1894059ee0 blob 51
895d61e52d8c1f55dfe0af9f20403cc940a44742 blob 9
95722c300fc5cfe6cc70305e21038a12ea6dfd61 tree 37
aa1a031ca30744c677a82eac91b9c4672542593f blob 30
b5688c9112aa76d0d5d5ff35e0bec6723ff89f02 tree 101
e375b7b7f8ad9877dd3bd0ff5272ef6323a9b55f commit 182
```
<!-- /snippet -->

Eight objects: three blobs, three trees, one commit, one tag object.

<!-- snippet: ch02/object-types/02-commit -->
```text
$ git cat-file -t HEAD
commit
$ git cat-file -p HEAD
tree b5688c9112aa76d0d5d5ff35e0bec6723ff89f02
author Lab User <you@example.com> 1788755580 +0530
committer Lab User <you@example.com> 1788755580 +0530

Add reranker with test script
```
<!-- /snippet -->

This commit has no `parent` line, so it is a *root commit*. `1788755580 +0530` is a time in Git's raw format: seconds since 1 January 1970 UTC, then the offset from UTC.

<!-- snippet: ch02/object-types/03-tree -->
```text
$ git cat-file -p 'HEAD^{tree}'
100644 blob 895d61e52d8c1f55dfe0af9f20403cc940a44742	README.md
040000 tree 08dd0d94a4c377361126a24ed13ad97267786d6f	scripts
040000 tree 95722c300fc5cfe6cc70305e21038a12ea6dfd61	src
$ git cat-file -p HEAD:scripts
100755 blob aa1a031ca30744c677a82eac91b9c4672542593f	test.sh
$ git ls-tree -r HEAD
100644 blob 895d61e52d8c1f55dfe0af9f20403cc940a44742	README.md
100755 blob aa1a031ca30744c677a82eac91b9c4672542593f	scripts/test.sh
100644 blob 572a34a9da9d2cc636c2b011e3956e1894059ee0	src/rerank.py
```
<!-- /snippet -->

`git cat-file -p` prints one level of a tree. `git ls-tree -r` walks down and prints every file with its full path. The first column is the mode ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)):

| Mode | Kind of entry |
|---|---|
| `100644` | Regular file |
| `100755` | Executable file |
| `120000` | Symbolic link |
| `040000` | Directory: the entry points at a tree |
| `160000` | Gitlink: a commit of another repository (Chapter 1, section 1.13; Chapter 23: Submodules) |

`scripts/test.sh` has mode `100755`. Executable or not is the only permission that Git records; it stores no owner and no other permission bits.

<!-- snippet: ch02/object-types/04-blob -->
```text
$ git cat-file -t HEAD:src/rerank.py
blob
$ git cat-file -p HEAD:src/rerank.py
def rerank(docs):
    return sorted(docs, key=len)
```
<!-- /snippet -->

A blob is content without a name. The name `rerank.py` is stored in the tree `95722c3`.

<!-- snippet: ch02/object-types/05-tag -->
```text
$ git cat-file -t v0.1.0
tag
$ git cat-file -p v0.1.0
object e375b7b7f8ad9877dd3bd0ff5272ef6323a9b55f
type commit
tag v0.1.0
tagger Lab User <you@example.com> 1788755640 +0530

First internal release
```
<!-- /snippet -->

The tag object `0f7f193` names the commit `e375b7b` and its type, repeats the tag name, and adds a tagger and a message. The ref `v0.1.0` points at the tag object. A *lightweight* tag has no object: it is a ref that points at the commit directly (Chapter 14B).

**Picture.** All eight objects and the two names that lead to them.

```text
 refs/tags/v0.1.0 --> tag 0f7f193 --+
                                    v
 refs/heads/main ------------> commit e375b7b --> tree b5688c9 --+--> blob 895d61e  README.md
                                                                 +--> tree 08dd0d9  scripts --> blob aa1a031  test.sh
                                                                 +--> tree 95722c3  src ------> blob 572a34a  rerank.py
```

**In production.** Author and committer are text supplied by whoever creates the commit; Git does not check them. A signature makes authorship verifiable (Chapter 14B, Chapter 21B).

## 2.6 Building a commit by hand

`git add` and `git commit` are porcelain. Five plumbing commands do the same work in separate, visible steps.

| Step | Plumbing command | Porcelain that does it for you |
|---|---|---|
| 1 | `git hash-object -w` 🟢 stores content as a blob | `git add` |
| 2 | `git update-index --add --cacheinfo <mode>,<id>,<path>` 🟡 records in the index that this path has this content | `git add` |
| 3 | `git write-tree` 🟢 writes the index as tree objects | `git commit` |
| 4 | `git commit-tree <tree> [-p <parent>] -m <message>` 🟢 writes a commit object | `git commit` |
| 5 | `git update-ref refs/heads/<branch> <commit>` 🟡 points the branch at the commit | `git commit` |

**See it.** A repository with no working-tree file at all (`labs/ch02/commit-by-hand.sh`); the content arrives through a pipe:

<!-- snippet: ch02/commit-by-hand/01-blob -->
```text
$ git init handmade
Initialized empty Git repository in $LAB/ch02/commit-by-hand/handmade/.git/
$ cd handmade
$ printf 'Answer only from the provided context.\n' | git hash-object -w --stdin
a7f6bbccac4db25937e64faa9292a454e408d871
$ find .git/objects -type f
.git/objects/a7/f6bbccac4db25937e64faa9292a454e408d871
$ git cat-file -t a7f6bbccac4db25937e64faa9292a454e408d871
blob
$ git cat-file -p a7f6bbccac4db25937e64faa9292a454e408d871
Answer only from the provided context.
```
<!-- /snippet -->

One object exists. There is no index yet.

<!-- snippet: ch02/commit-by-hand/02-index -->
```text
$ git update-index --add --cacheinfo 100644,a7f6bbccac4db25937e64faa9292a454e408d871,prompts/system.txt
$ git ls-files --stage
100644 a7f6bbccac4db25937e64faa9292a454e408d871 0	prompts/system.txt
$ git status
On branch main

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
	new file:   prompts/system.txt

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	deleted:    prompts/system.txt
```
<!-- /snippet -->

`--cacheinfo` takes a mode, a full object ID and a path; `--add` permits a path that the index does not have yet. `git status` reports the path twice, and both lines are correct: "new file" compares the index with HEAD, which has no commit, and "deleted" compares the working tree with the index, which lists a file that is not on disk (section 2.9).

<!-- snippet: ch02/commit-by-hand/03-tree -->
```text
$ git write-tree
5445e77320236121d609466c32a9b87e30cc3b93
$ git cat-file -p 5445e77320236121d609466c32a9b87e30cc3b93
040000 tree 4015b7b95e10b15e3f75a77197c1fa3e0999d344	prompts
$ git cat-file -p 4015b7b95e10b15e3f75a77197c1fa3e0999d344
100644 blob a7f6bbccac4db25937e64faa9292a454e408d871	system.txt
$ git ls-tree -r 5445e77320236121d609466c32a9b87e30cc3b93
100644 blob a7f6bbccac4db25937e64faa9292a454e408d871	prompts/system.txt
```
<!-- /snippet -->

The index is a flat list of full paths; trees are nested, one object per directory. So `git write-tree` wrote two trees: `5445e77` for the top directory and `4015b7b` for `prompts/`.

<!-- snippet: ch02/commit-by-hand/04-commit -->
```text
$ git commit-tree 5445e77320236121d609466c32a9b87e30cc3b93 -m 'Add system prompt'
cc0ef1583aec692cf787228d912e5e33ff228a9a
$ git cat-file -p cc0ef1583aec692cf787228d912e5e33ff228a9a
tree 5445e77320236121d609466c32a9b87e30cc3b93
author Lab User <you@example.com> 1788756300 +0530
committer Lab User <you@example.com> 1788756300 +0530

Add system prompt
$ git log --oneline
fatal: your current branch 'main' does not have any commits yet
[exit status: 128]
$ git fsck
notice: No default references
dangling commit cc0ef1583aec692cf787228d912e5e33ff228a9a
```
<!-- /snippet -->

`git commit-tree` wrote the commit `cc0ef15`, with the author and the committer taken from the environment, as `git commit` does. `git log` fails, because HEAD names the branch `main` and no ref `refs/heads/main` exists. `git fsck`, which checks the object database, calls the commit *dangling*: it exists, and nothing refers to it.

<!-- snippet: ch02/commit-by-hand/05-ref -->
```text
$ git update-ref refs/heads/main cc0ef1583aec692cf787228d912e5e33ff228a9a
$ git log --oneline
cc0ef15 Add system prompt
$ git fsck
$ git status --short
 D prompts/system.txt
```
<!-- /snippet -->

One ref makes the difference: `git log` works and `git fsck` is silent. `git status --short` prints ` D prompts/system.txt`: the commit and the index contain the file, the working tree does not.

<!-- snippet: ch02/commit-by-hand/06-working-tree -->
```text
$ git restore prompts/system.txt
$ cat prompts/system.txt
Answer only from the provided context.
$ git status
On branch main
nothing to commit, working tree clean
```
<!-- /snippet -->

`git restore <path>` 🔴 copies the file from the index into the working tree. Nothing can be lost here, because no file existed; on a file with uncommitted edits the same command overwrites them ([Chapter 4](ch04-working-tree.md), section 4.7).

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git hash-object -w` | unchanged | unchanged | unchanged | unchanged | One new blob | unchanged | unchanged |
| `git update-index --add --cacheinfo` | unchanged | One entry added or replaced | unchanged | unchanged | `.git/index` is written | unchanged | unchanged |
| `git write-tree` | unchanged | unchanged | unchanged | unchanged | One tree per directory, unless it exists already | unchanged | unchanged |
| `git commit-tree` | unchanged | unchanged | unchanged | unchanged | One commit object; no ref, no reflog line | unchanged | unchanged |
| `git update-ref refs/heads/main <id>` | unchanged | unchanged | unchanged | Created, or moved to `<id>` | Reflog lines for the branch and for HEAD, without a message unless you pass `-m` | unchanged | unchanged |

`git commit` does more than steps 3 to 5: it refuses to record nothing (Chapter 1, section 1.13), runs hooks, and writes a reason into the reflogs. The plumbing is still worth knowing. Every porcelain command is a combination of these moves, so when a command surprises you, ask which objects it wrote and which refs it moved. Recovery uses the same tools: a commit found by `git fsck` or in a reflog is reattached with one ref (Lab 1.1, Chapter 13).

## 2.7 The commit graph

**In one sentence.** Every commit names its parent commits, so the commits form a graph that is walked from child to parent, and "the history of X" means everything you can reach from X by following those links.

**Analogy.** A family tree in which each record lists the parents and none lists the children: from any person you can find all ancestors, but to find descendants you must start from someone younger. The analogy breaks on the counts: a commit has no parent (a root commit), one (an ordinary commit) or several (a merge).

**Precisely.** The commits form a directed acyclic graph, a DAG ([gitglossary](https://git-scm.com/docs/gitglossary)). It is directed because the link is stored in the child and points at the parent. It is acyclic because a commit's ID is computed from its parents' IDs: a parent must exist before its child, so no chain of links can return to its start. An object is *reachable* from another if a chain leads to it that follows tags to what they tag, commits to their parents and trees, and trees to their entries. Three things follow.

- A commit does not know its children, so "what came after this commit?" has an answer only relative to a starting point. History commands start from a ref.
- "The commits on a branch" is not a stored list but the set reachable from the commit that the branch names.
- "A is an ancestor of B" means that A is reachable from B. `git merge-base --is-ancestor A B` answers with its exit status.

**See it.** Five commits, one of them a merge (`labs/ch02/graph.sh`):

<!-- snippet: ch02/graph/01-graph -->
```text
$ git log --graph --decorate --oneline --all
*   2511274 (HEAD -> main) Merge branch 'feature/dedupe'
|\  
| * ea0d3fa (feature/dedupe) Add dedupe rules
* | 6d7e946 Add split step
|/  
* 0fd50fb Add clean step
* dec99b5 Add load step
```
<!-- /snippet -->

<!-- snippet: ch02/graph/02-parents -->
```text
$ git log --format='%h  parents: %p' main
2511274  parents: 6d7e946 ea0d3fa
6d7e946  parents: 0fd50fb
ea0d3fa  parents: 0fd50fb
0fd50fb  parents: dec99b5
dec99b5  parents: 
$ git cat-file -p main
tree a9772be4c20443bc529f1b4fd1072be849341e67
parent 6d7e94608a939094e01cc57ba109f162c33cf7cd
parent ea0d3faa4a9e73d5df7cf0b7df41e67546ae932f
author Lab User <you@example.com> 1788755940 +0530
committer Lab User <you@example.com> 1788755940 +0530

Merge branch 'feature/dedupe'
```
<!-- /snippet -->

`%p` prints the parents. The merge commit `2511274` has two `parent` lines: first the commit that `main` pointed at when the merge was made, `6d7e946`, then the tip of the merged branch, `ea0d3fa`. A merge commit is an ordinary commit with more than one parent, and its tree is the merged snapshot ([Chapter 8](ch08-merge.md)).

<!-- snippet: ch02/graph/03-reachable -->
```text
$ git rev-list --count main
5
$ git rev-list --count feature/dedupe
3
$ git log --oneline feature/dedupe
ea0d3fa Add dedupe rules
0fd50fb Add clean step
dec99b5 Add load step
$ git merge-base --is-ancestor feature/dedupe main
[exit status: 0]
$ git merge-base --is-ancestor main feature/dedupe
[exit status: 1]
```
<!-- /snippet -->

Five commits are reachable from `main`, and three from `feature/dedupe`: its own commit and the two it shares with `main`. The branch is an ancestor of `main` (status 0); `main` is not an ancestor of the branch (status 1).

<!-- snippet: ch02/graph/04-unreachable -->
```text
$ git commit-tree 'main^{tree}' -p main -m 'Experiment that no ref points at'
2c65cfc7d0ba9f3dcd757786eba7734820034807
$ git cat-file -t 2c65cfc7d0ba9f3dcd757786eba7734820034807
commit
$ git rev-list --count --all
5
$ git fsck
dangling commit 2c65cfc7d0ba9f3dcd757786eba7734820034807
```
<!-- /snippet -->

`git commit-tree` created a sixth commit whose parent is the tip of `main`. The object exists, but no ref leads to it: `git rev-list --count --all` still counts five, and `git fsck` reports a dangling commit.

<!-- snippet: ch02/graph/05-rescued -->
```text
$ git branch rescue 2c65cfc7d0ba9f3dcd757786eba7734820034807
$ git rev-list --count --all
6
$ git fsck
$ git log --graph --decorate --oneline --all
* 2c65cfc (rescue) Experiment that no ref points at
*   2511274 (HEAD -> main) Merge branch 'feature/dedupe'
|\  
| * ea0d3fa (feature/dedupe) Add dedupe rules
* | 6d7e946 Add split step
|/  
* 0fd50fb Add clean step
* dec99b5 Add load step
```
<!-- /snippet -->

`git branch rescue <id>` 🟢 created a ref for it. Six commits are reachable, `git fsck` is silent, and the graph shows the commit. No object changed; a name was added.

**Inside `.git`.** The graph is not stored anywhere as a whole. Parent IDs are inside commit objects, and the starting points are refs.

**Picture.**

```text
                    ea0d3fa -----------+          feature/dedupe -> ea0d3fa
                   /                    \
 dec99b5---0fd50fb---6d7e946----------2511274---2c65cfc
                                          ^         ^
                                        main      rescue
                                    (HEAD -> main)
```

**In production.** "Is the fix in what we shipped?" is an ancestry question: `git merge-base --is-ancestor <fix> <released commit>`. Deleting a branch deletes a name, never a commit, and unreachable is not gone: `git gc` removes unreachable objects only after a grace period, two weeks by default (`gc.pruneExpire`). Reflog entries also count as starting points and are kept for 90 days by default, or 30 days once the commit is no longer reachable from the tip of its ref (`gc.reflogExpire`, `gc.reflogExpireUnreachable`; the lab configuration sets both to `never`). Chapter 13: Recovery is built on these numbers.

## 2.8 Refs and HEAD

**In one sentence.** A ref is a name for an object ID, a branch is a ref that moves forward when you commit, and HEAD records which branch, or which commit, you are on.

**Analogy.** Sticky labels on a wall chart of the commit graph. Moving a label changes nothing on the chart, and removing one removes no commit. HEAD is the "you are here" marker, normally stuck onto a label rather than onto the chart. The analogy breaks because labels are local: every clone has its own set and learns about another repository's labels only when it fetches (section 2.12).

**Precisely.** A ref refers either to an object ID or to another ref, in which case it is a *symbolic ref* ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)). Its place in the hierarchy decides how Git treats it.

| Ref | Refers to | Moves when |
|---|---|---|
| `refs/heads/<name>`, a branch | A commit | You commit, merge, reset or rebase while it is the current branch |
| `refs/tags/<name>`, a tag | Usually a commit or a tag object | Normally never |
| `refs/remotes/<remote>/<name>`, a remote-tracking branch | A commit | You fetch from that remote or push to it |
| `HEAD` | The current branch, as a symbolic ref; or one commit ID directly (*detached HEAD*) | You switch |

A branch contains no commits: it names one, and its history is what is reachable from there. Creating a branch writes one ref and copies nothing. Git records no "parent branch", so merge and rebase must be told the other side ([Chapter 9](ch09-rebase.md)).

**See it.** One commit on `main` (`labs/ch02/refs-head.sh`):

<!-- snippet: ch02/refs-head/01-files -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ cat .git/refs/heads/main
3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git rev-parse HEAD main
3046dc6147cc4993920eb20efeb20d44f2b73d77
3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git symbolic-ref HEAD
refs/heads/main
```
<!-- /snippet -->

HEAD contains the name of a branch, and the branch file contains a commit ID. `git rev-parse` resolves both names to that ID; `git symbolic-ref HEAD` prints the branch that HEAD names.

<!-- snippet: ch02/refs-head/02-new-branch -->
```text
$ git cat-file --batch-all-objects --batch-check
3046dc6147cc4993920eb20efeb20d44f2b73d77 commit 171
3a19f43c4181bfd7a3b52b74fbb1b1079e9c2bac tree 37
bfb2990471be330c8cdd6365bd10b4d3fac0ddbc blob 10
$ git branch feature/unicode
$ cat .git/refs/heads/feature/unicode
3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git cat-file --batch-all-objects --batch-check
3046dc6147cc4993920eb20efeb20d44f2b73d77 commit 171
3a19f43c4181bfd7a3b52b74fbb1b1079e9c2bac tree 37
bfb2990471be330c8cdd6365bd10b4d3fac0ddbc blob 10
$ git for-each-ref
3046dc6147cc4993920eb20efeb20d44f2b73d77 commit	refs/heads/feature/unicode
3046dc6147cc4993920eb20efeb20d44f2b73d77 commit	refs/heads/main
```
<!-- /snippet -->

The object list is identical before and after `git branch feature/unicode` 🟢; the command wrote one small file holding one ID. `git for-each-ref` lists every ref with the object it names.

<!-- snippet: ch02/refs-head/03-commit-moves-branch -->
```text
$ git switch feature/unicode
Switched to branch 'feature/unicode'
$ cat .git/HEAD
ref: refs/heads/feature/unicode
$ printf 'lowercase\nnormalize NFC\n' > rules.txt
$ git commit -am "Normalize to NFC"
[feature/unicode 4a3fb80] Normalize to NFC
 1 file changed, 1 insertion(+)
$ cat .git/HEAD
ref: refs/heads/feature/unicode
$ git for-each-ref
4a3fb8058851f5b863aea726837405da25a9a7e9 commit	refs/heads/feature/unicode
3046dc6147cc4993920eb20efeb20d44f2b73d77 commit	refs/heads/main
$ git log --graph --decorate --oneline --all
* 4a3fb80 (HEAD -> feature/unicode) Normalize to NFC
* 3046dc6 (main) Add lowercase rule
```
<!-- /snippet -->

`git switch` 🟢 rewrote HEAD to name the other branch. The commit then moved `feature/unicode` to `4a3fb80`; `main` stayed at `3046dc6`, and HEAD reads the same before and after. A commit moves the current branch, and HEAD follows because it names that branch.

<!-- snippet: ch02/refs-head/04-checkout-equivalent -->
```text
# Older scripts switch branches with git checkout. Same effect.
$ git checkout main
Switched to branch 'main'
$ cat .git/HEAD
ref: refs/heads/main
```
<!-- /snippet -->

<!-- snippet: ch02/refs-head/05-detached -->
```text
# The second form of HEAD: a commit ID instead of a branch name.
$ git switch --detach feature/unicode
HEAD is now at 4a3fb80 Normalize to NFC
$ cat .git/HEAD
4a3fb8058851f5b863aea726837405da25a9a7e9
$ git symbolic-ref HEAD
fatal: ref HEAD is not a symbolic ref
[exit status: 128]
$ git switch main
Previous HEAD position was 4a3fb80 Normalize to NFC
Switched to branch 'main'
$ cat .git/HEAD
ref: refs/heads/main
```
<!-- /snippet -->

`git switch --detach` wrote a commit ID into HEAD. No branch is current, so a new commit would move no branch (Chapter 7: Branches). Switching back to `main` restores the symbolic form.

**Inside `.git`.** Here each ref is a file that `cat` can read. That is the default "files" format, not a guarantee: refs can be packed into one file, and the reftable format stores them in binary (Chapter 3). `git rev-parse`, `git symbolic-ref` and `git for-each-ref` work with every format.

**Picture.**

```text
 before the commit                          after the commit

   3046dc6                                    3046dc6 <------ 4a3fb80
      ^                                          ^               ^
      +-- main                                   |               |
      +-- feature/unicode <-- HEAD               main            feature/unicode <-- HEAD
```

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git branch <name>` | unchanged | unchanged | unchanged | unchanged | New ref `refs/heads/<name>` at the current commit, with its own reflog | unchanged | unchanged |
| `git switch <branch>`, `git switch --detach <commit>` | Files that differ between the two commits are updated; refused if that would overwrite uncommitted changes | Updated in the same way | Rewritten: the branch name, or the commit ID | unchanged; another branch, or none, is now current | A reflog line for HEAD | unchanged | unchanged |

**In production.** "Which commit is deployed?" must be answered with a commit ID. `main` is a moving name: it meant another commit yesterday and may mean a different one in a colleague's clone today. A tag is a name that is not supposed to move; whether it can is decided by the rules on the server (Chapter 18).

## 2.9 The three trees: a preview

**In one sentence.** A file can exist in three states at the same time, in the commit that HEAD names, in the index and in the working tree, and `git status` reports the differences between them.

**Precisely.** "Tree" here means a complete set of files, not a tree object. The commit that HEAD names is the last snapshot. The index is the proposed next snapshot: every tracked path with the ID of a blob. The working tree is the files on disk. `git add` copies content from the working tree into the index, and `git commit` turns the index into tree objects and a commit.

**See it.** One file is committed, then changed and staged, then changed again (`labs/ch02/three-trees.sh`):

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

`git show HEAD:rules.txt` prints the committed version, and `git show :rules.txt` prints the version in the index. Three versions exist at once.

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

`git diff --cached` compares HEAD with the index, and `git diff` compares the index with the working tree. Neither shows the whole distance from HEAD to the working tree; `git diff HEAD` does.

**Picture.**

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

A commit made now would record the middle version: the index, not the file on disk. That is the mechanism behind the worked example in Chapter 1, section 1.12. [Chapter 4](ch04-working-tree.md) and Chapter 5: Index take the three trees apart.

## 2.10 A commit is a snapshot, and it can be read as a change

"A commit is a diff" is wrong as a statement about storage and right as a way to read history. You need both views, and you need to know which one a command uses.

| View | Definition | Used by |
|---|---|---|
| Snapshot | The tree that the commit records | Checkout, builds, `git ls-tree`, `git diff A B`, merge (three snapshots) |
| Change | The difference between the commit's tree and its parent's, computed on demand | `git show`, `git log -p`, cherry-pick, rebase, revert |

**See it.** `main` is two commits ahead of `release/1.0` (`labs/ch02/two-views.sh`):

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

`git cherry-pick` 🟡 copies the last commit onto the release branch:

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

The result is a new commit, `e460212`, with the same message. The `Date:` line is the author date, which a cherry-pick takes over from the original ([Chapter 10](ch10-cherry-pick.md), section 10.3).

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

The change is the same. `git patch-id` reduces a diff to an ID that ignores line numbers and whitespace, and both commits give `22602bf…`. Same change, different snapshot, different parent, different commit ID: that answers the third question of section 2.1.

**Picture.**

```text
              92b1ad4---cf6a5b3     main          workers: 4, retries: 3
             /
 68dcb3b----+
             \
              e460212               release/1.0   workers: 2, retries: 3     (HEAD -> release/1.0)

 change of cf6a5b3 = change of e460212 = "retries: 1 becomes 3"; their snapshots differ
```

**Precisely.** The manual describes cherry-pick in the change view: it applies the change that a commit introduces and records a new commit ([git-cherry-pick](https://git-scm.com/docs/git-cherry-pick)). The implementation is a three-way merge whose base is the parent of the picked commit, so it works on three snapshots ([how cherry-pick and revert work](https://jvns.ca/blog/2023/11/10/how-cherry-pick-and-revert-work/)). Rebase repeats this for a series of commits ([Chapter 9](ch09-rebase.md)); revert applies the inverse change ([Chapter 11](ch11-reset-revert-restore.md)). The result is always a new commit with a new ID.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git cherry-pick <commit>` | Updated to the new commit | Updated to the new commit | unchanged | Moves to the new commit | New commit, and new trees and blobs where content is new; reflog lines | unchanged | unchanged |

**In production.** In a poll of 2,466 mostly professional developers, 50% think of a commit as a diff and 42% as a snapshot ([poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/); a self-selected sample). Each group holds half of the model. The snapshot view says what a build contains and why two IDs differ; the change view says what a cherry-pick or a rebase will carry over and what it will leave behind.

## 2.11 Common wrong mental models

The rows come from section 12 of the [research report](../reports/Git%20and%20GitHub%20mastery%20research.md), which has the complete table. "Proof" says where this book demonstrates the reality.

| Wrong model | Verified reality | Layer | Proof | Source |
|---|---|---|---|---|
| A commit stores a diff | A commit records a full snapshot, the ID of the top-level tree, with its parents, author, committer and message. Diffs are computed on demand | Git | 2.3 | [gitdatamodel](https://git-scm.com/docs/gitdatamodel) |
| Cherry-pick and revert apply patches | Cherry-pick is a three-way merge whose base is the picked commit's parent; revert swaps the base and "theirs" | Git | 2.10, Chapter 10 | [jvns.ca](https://jvns.ca/blog/2023/11/10/how-cherry-pick-and-revert-work/) |
| A branch is a copy of the code, with a parent branch | A branch is a ref that names one commit. Git has no notion of a parent branch | Git | 2.8 | [gitdatamodel](https://git-scm.com/docs/gitdatamodel), [jvns.ca](https://jvns.ca/blog/2023/11/23/branches-intuition-reality/) |
| HEAD is the latest commit | HEAD is a symbolic ref to the current branch, or a direct reference to a commit, in which case no branch is current | Git | 2.8 | [gitdatamodel](https://git-scm.com/docs/gitdatamodel) |
| `origin/main` is the branch on the server | A remote-tracking branch records the last-known state of the remote branch, as of the last fetch | Git | 2.12, Chapter 12 | [gitdatamodel](https://git-scm.com/docs/gitdatamodel), [jvns.ca](https://jvns.ca/blog/2023/11/01/confusing-git-terminology/) |
| The staging area is a list of files to commit | The index is a flat list of entries, each with a file type, a blob ID, a stage number and a path; it describes the whole next snapshot | Git | 2.6, 2.9 | [gitdatamodel](https://git-scm.com/docs/gitdatamodel), [gitformat-index](https://git-scm.com/docs/gitformat-index) |
| Amend and rebase edit commits | Objects never change. Amend and rebase create new commits with new IDs; the old ones remain until their reflog entries expire | Git | 2.4, Chapters 9 and 11 | [gitdatamodel](https://git-scm.com/docs/gitdatamodel), [gc configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/gc.adoc) |
| The reflog will always save me, even for a deleted branch or on the server | Reflogs are local and are not shared with remotes. Deleting a branch deletes its reflog. Bare repositories keep none by default | Git | 2.12, Chapter 13 | [gitdatamodel](https://git-scm.com/docs/gitdatamodel), [git-branch](https://github.com/git/git/blob/v2.56.0/Documentation/git-branch.adoc) |
| Git tracks renames and directories | Git does not record renames, and it tracks file content, not directories | Git | 2.5, Chapter 4 | [Git User's Manual](https://github.com/git/git/blob/v2.56.0/Documentation/user-manual.adoc) |
| A pull request is a Git feature | It is a GitHub object, backed by hidden refs, a test merge commit and a three-dot diff | GitHub | 2.12, Chapter 17 | [pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests) |
| Deleting the file or force-pushing removes a leaked secret | The commits stay accessible in clones and forks, by ID in cached views, and through pull-request refs; rotation is the remedy | GitHub | 2.7, Chapter 21B | [removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) |

These are not beginner errors: in the same polls, only 10% of respondents were fully confident that they understood HEAD.

## 2.12 The mental map of Git versus GitHub

Chapter 1, section 1.5 sorted things into layers. This chapter's model adds the rule for what can cross between repositories at all: **a push or a fetch transfers objects and updates refs; nothing else in `.git` leaves your machine.**

**See it.** A bare repository on disk plays the Git layer of the server (`labs/ch02/what-travels.sh`). Your clone has one commit, a second branch `wip/unicode`, a staged change, and an alias `st` in its `.git/config`:

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

Four objects exist locally: the commit, its tree, the committed blob and the blob of the staged change. `git push` 🟡 published `main` (its state table is in Chapter 1, section 1.12).

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

The server received three objects and one ref. The staged blob `298e6b4` is absent, because no pushed commit refers to it. The branch `wip/unicode` is absent, because it was not pushed. There is no index, no `logs/` directory and no working tree, so `git status` cannot run.

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

A colleague's clone has the server's branch as the remote-tracking branch `refs/remotes/origin/main`, and Git created a local `main` from it. The reflog begins with the clone, and the alias is unknown. Your reflogs and your `.git/config` stayed with you.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git clone <url>` 🟢 | Created from the default branch | Created | Created; names the default branch | Created from the remote-tracking branch | All reachable objects, `refs/remotes/origin/*`, a new reflog, a `.git/config` that names the remote | unchanged | unchanged |

**Picture.**

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

> **GitHub, not Git.** The two lower boxes exist only in GitHub's systems. A pull request, for example, is a database record plus read-only refs under `refs/pull/` that GitHub maintains on the server, as described in GitHub's documentation ([pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests), [removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)). A clone copies none of it, and deleting your clone loses none of it.

**In production.** "It is on GitHub" translates to: which objects were pushed, and which ref on the server points at them? "GitHub shows X" raises the question whether X is Git data that any clone would show, or a platform record. [Chapter 12](ch12-remote-operations.md) develops the arrows of the picture; Chapters 15 to 21 the right-hand boxes.

## 2.13 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A commit made with `git commit-tree` is not in `git log` | `git fsck` reports a dangling commit | `git update-ref refs/heads/<branch> <id>`, or `git branch <name> <id>` | In scripts, create the commit and move the ref together (Lab 1.1) |
| After `git update-ref` moved the current branch, `git status` shows changes that nobody made | The ref moved; the index and the working tree did not | Decide which state you want; `git restore --staged --worktree <paths>` 🔴 takes them from the new HEAD | Move the current branch with porcelain, which updates all three ([Chapter 11](ch11-reset-revert-restore.md)) |
| Git warns that a name such as `main` is ambiguous | A stray ref outside `refs/` (below) | Delete the stray file | Give `git update-ref` full names that begin with `refs/` |
| Two files look identical and have different IDs | `cmp`, `od -c` and `git hash-object` on both | Remove the invisible bytes (Lab 1.3) | Normalize line endings by rule ([Chapter 4](ch04-working-tree.md), section 4.13) |
| `fatal: bad object`, or `git fsck` reports a missing object | `git fsck` names the type and the ID | Write the same content back, or copy the object from another clone (Lab 1.2, Chapter 13) | Never edit `.git/objects`; keep more than one clone |

**`git update-ref` takes the name literally.** The intent below is to move the branch `main`. The name given is `main` instead of `refs/heads/main` (`labs/ch02/update-ref-trap.sh`):

<!-- snippet: ch02/update-ref-trap/01-stray-ref -->
```text
# Intent: point the branch main at the first commit. Mistake: the short name.
$ git log --oneline
cfa6dbc Normalize to NFC
3046dc6 Add lowercase rule
$ git update-ref main 3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git branch -vv
* main cfa6dbc Normalize to NFC
$ git rev-parse main
warning: refname 'main' is ambiguous.
3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git rev-parse refs/heads/main
cfa6dbcdb38cee2b5a32420a51a8dea71fab1dc1
```
<!-- /snippet -->

The command printed nothing, and the branch did not move: `git branch -vv` still shows `cfa6dbc`. But the name `main` now resolves to the old commit, with a warning.

<!-- snippet: ch02/update-ref-trap/02-find-and-remove -->
```text
$ git for-each-ref
cfa6dbcdb38cee2b5a32420a51a8dea71fab1dc1 commit	refs/heads/main
$ find .git -maxdepth 1 -type f | sort
.git/COMMIT_EDITMSG
.git/config
.git/description
.git/HEAD
.git/index
.git/main
$ cat .git/main
3046dc6147cc4993920eb20efeb20d44f2b73d77
$ git update-ref -d main
error: refusing to update ref with bad name 'main'
[exit status: 1]
$ rm .git/main
$ git rev-parse main
cfa6dbcdb38cee2b5a32420a51a8dea71fab1dc1
```
<!-- /snippet -->

```text
Observed behavior : git update-ref main <id> prints nothing. Afterwards "main" is ambiguous and
                    resolves to <id>, while the branch main still points at its own commit.
Git state         : a file .git/main holds <id>. refs/heads/main is unchanged. git for-each-ref,
                    which lists refs/, does not show the stray ref.
Mechanism         : update-ref writes exactly the ref it is given. For an update it checks only
                    that the name is well-formed. Name lookup tries <name> at the top of .git
                    before refs/heads/<name>. For a deletion Git accepts only names under refs/
                    and names in capitals such as ORIG_HEAD, so "git update-ref -d main" is refused.
Root cause        : a plumbing command received a short name where it needs the full ref name.
Why Git does this : plumbing serves scripts. It does what it is told and guesses nothing.
Correct fix       : confirm that .git/main is the stray ref, then delete that file.
Prevention        : write refs/heads/<name> for update-ref; move branches with porcelain.
```

The lookup order is in [gitrevisions](https://git-scm.com/docs/gitrevisions); the two name checks were read from the Git 2.55.0 source ([refs.c](https://github.com/git/git/blob/v2.55.0/refs.c)). The fix applies to the files format, where a ref is a file.

## 2.14 When not to use it, and dangerous edge cases

**When not to use plumbing.** For daily work: `git add`, `git commit`, `git switch` and `git branch` make the same objects and refs and add checks. The read-only plumbing (`git cat-file`, `git ls-tree`, `git rev-parse`, `git for-each-ref`, `git merge-base`) is always appropriate and settles arguments about state fastest.

**Dangerous edge cases.**

- `git update-ref` verifies little. It refuses a blob as the value of a branch and a stale expected value (Lab 1.1), but it accepts any existing commit and never looks at the index or the working tree. Porcelain refuses more: `git branch -f` will not move the checked-out branch.
- `git update-ref -d <ref>` 🔴. **What it changes:** it deletes the ref and its reflog, even for the current branch. **What it can destroy:** the only name that leads to those commits. **Preview:** `git rev-parse <ref>`; write the ID down. **Recovery:** `git update-ref <ref> <id>` with that ID; without it, `git fsck --no-reflogs` lists the commits as dangling while they exist. **When appropriate:** scripts that remove refs they created themselves.
- Deleting or editing files under `.git/objects` 🔴. One object can be part of every snapshot in the history (Lab 1.2).
- `git add` and `git hash-object -w` store content at once. A secret that was staged for a second is an object in `.git/objects` until garbage collection removes it, even if it was never committed (Chapter 21B).
- An abbreviated ID in a script or a ticket can become ambiguous as the repository grows; store full IDs.

## 2.15 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git cat-file`, `git ls-tree`, `git rev-parse`, `git for-each-ref`, `git rev-list`, `git merge-base`, `git fsck`, `git patch-id`, `git hash-object` without `-w` | 🟢 | Nothing | not needed | not needed |
| `git hash-object -w`, `git write-tree`, `git commit-tree` | 🟢 | Add objects; no ref and no index entry changes | not needed | Garbage collection removes objects that nothing refers to |
| `git update-index --add --cacheinfo` | 🟡 | One index entry | `git ls-files --stage` | `git restore --staged <path>` |
| `git update-ref <ref> <new> [<old>]` | 🟡 | One ref, and nothing else | `git rev-parse <ref>`; pass `<old>` so that a surprise stops the command | `git update-ref <ref> <previous ID>`, taken from the reflog |
| `git update-ref -d <ref>` | 🔴 | Deletes the ref and its reflog | `git rev-parse <ref>` | Recreate the ref from the ID; `git fsck --no-reflogs` if you did not keep it |
| `git branch <name> [<commit>]` | 🟢 | Adds one ref | `git branch -vv` | `git branch -d <name>` |
| `git switch <branch>`, `git checkout <branch>`, `git switch --detach <commit>` | 🟢 | HEAD, index and working tree; refuses to overwrite uncommitted changes (exception: Chapter 4, section 4.17) | `git status` | `git switch -` |
| `git cherry-pick <commit>` | 🟡 | Adds one commit to the current branch, which moves it, and updates index and working tree | `git show <commit>` | [Chapter 10](ch10-cherry-pick.md) |
| `git restore <path>` | 🔴 | Overwrites the file from the index | `git diff -- <path>` | None for content that was never staged |
| `git push`, `git clone` | 🟡, 🟢 | Chapter 1, section 1.15 and [Chapter 12](ch12-remote-operations.md) | `git push --dry-run` | Chapter 12 |

## 2.16 Version notes

| Topic | Older behavior | Current behavior | Since | Recommended |
|---|---|---|---|---|
| Object IDs | SHA-1, 40 digits | Still the default. SHA-256 repositories, with 64 digits, are supported and cannot exchange data with SHA-1 repositories | Supported since Git 2.42; planned default for new repositories in Git 3.0 | Never assume 40 digits in a script or a regular expression |
| Ref storage | One file per ref, plus `packed-refs` | Still the default; reftable is optional | Git 2.45; planned default for new repositories in Git 3.0 | Read refs with `git rev-parse`, `git for-each-ref` and `git symbolic-ref` |
| `gitdatamodel` | Not available | `git help datamodel` | Git 2.53 | Read it next |
| `git switch` | `git checkout` for switching | A stable command; `git checkout` remains supported | Git 2.23; no longer experimental since 2.51 | Use `git switch`; read `git checkout` in older scripts |

All rows come from sections 1 and 4 of the [research report](../reports/Git%20and%20GitHub%20mastery%20research.md), which links the release notes.

> **Outdated advice.** Tutorials that read `.git/refs/heads/master` to find "the latest commit" assume the files format and an old default branch name. `git rev-parse <branch>` works in every repository.

## 2.17 Practice

1. [Lab 1.1](../lab-manual/m01-what-git-is.md): build two commits by hand, lose a third on purpose and get it back.
2. [Lab 1.2](../lab-manual/m01-what-git-is.md): prove that snapshots share unchanged blobs and trees, then delete a shared object and rebuild it.
3. [Lab 1.3](../lab-manual/m01-what-git-is.md): the same content in two repositories, down to an identical commit ID, and one invisible byte that breaks it.
4. Replay `labs/run ch02/graph` and `labs/run ch02/what-travels`, then inspect the sandboxes under `$LAB/ch02/` with `git cat-file -p` and `git for-each-ref`.
5. Read `git help datamodel` from top to bottom. After this chapter every sentence in it should be familiar.

## 2.18 Interview questions

1. A report quotes a commit ID. What does that ID guarantee about file contents, history and authorship, and what does it not guarantee?
2. A commit changes one file out of 5,000, three directories deep. How many objects does it create, and of which types?
3. Why can a commit object not be edited? What do `git commit --amend` and `git rebase` do instead?
4. Two engineers commit identical content with identical messages on two laptops. Which IDs are equal, which differ, and why?
5. Define "reachable". Why is a commit that no ref can reach still in the repository, and for how long by default?
6. What is a branch, what does creating one cost, and what does Git know about the branch it was created from?
7. Describe the two forms of HEAD and how you would tell them apart on a machine you have never seen.
8. `git status` lists one file under "Changes to be committed" and under "Changes not staged for commit". Explain the state of the three trees.
9. A cherry-picked commit has a different ID from the original. Is it the same commit, the same change, or the same snapshot, and how would you prove it?
10. Which parts of `.git` reach the server when you push, and which never do? What does GitHub hold that no clone contains?

## 2.19 Sources

**Primary sources**

- [gitdatamodel](https://git-scm.com/docs/gitdatamodel): objects, refs, the index and reflogs; on your machine as `git help datamodel`.
- [gitglossary](https://git-scm.com/docs/gitglossary): DAG, reachable, dangling object, HEAD, ref, symref.
- [gitrevisions](https://git-scm.com/docs/gitrevisions): `<rev>^{tree}`, `<rev>:<path>`, `:<path>`, and the lookup order of a short ref name.
- Manual pages: [git-hash-object](https://git-scm.com/docs/git-hash-object), [git-update-index](https://git-scm.com/docs/git-update-index), [git-write-tree](https://git-scm.com/docs/git-write-tree), [git-commit-tree](https://git-scm.com/docs/git-commit-tree), [git-update-ref](https://git-scm.com/docs/git-update-ref), [git-cat-file](https://git-scm.com/docs/git-cat-file), [git-ls-tree](https://git-scm.com/docs/git-ls-tree), [git-fsck](https://git-scm.com/docs/git-fsck), [git-patch-id](https://git-scm.com/docs/git-patch-id), [git-cherry-pick](https://git-scm.com/docs/git-cherry-pick).
- Git source at the v2.55.0 tag: [refs.c](https://github.com/git/git/blob/v2.55.0/refs.c), read for the root-cause box in section 2.13.
- Pro Git, second edition, chapter 10: [Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects), [Git References](https://git-scm.com/book/en/v2/Git-Internals-Git-References). Frozen since May 2024; the object model is current, the commands use `master` and `git checkout`.
- GitHub Docs: [pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests), [removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository).

**Secondary sources**

- [Phase 0 research report](../reports/Git%20and%20GitHub%20mastery%20research.md): section 12 for the misconceptions, sections 1 and 4 for versions.
- Julia Evans: [how cherry-pick and revert work](https://jvns.ca/blog/2023/11/10/how-cherry-pick-and-revert-work/), [branches: intuition and reality](https://jvns.ca/blog/2023/11/23/branches-intuition-reality/), [confusing Git terminology](https://jvns.ca/blog/2023/11/01/confusing-git-terminology/), [poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/). The polls are self-selected samples: direction, not population figures.

**Videos**

The report assessed these from caption searches, chapter lists and descriptions, not by full viewing.

- ["Lecture 5: Version Control and Git"](https://www.youtube.com/watch?v=9K8lB61dl3Y), MIT Missing Semester 2026, 1 hour 10 minutes, 19 February 2026, with [notes and exercises](https://missing.csail.mit.edu/2026/version-control/). The data model before the commands. SHA-1 only; the demo starts on `master`; nothing on GitHub.
- ["Git Internals by John Britton of GitHub - CS50 Tech Talk"](https://www.youtube.com/watch?v=lG90LZotrpo), 58 minutes, 11 April 2018. Blobs, trees, commits, hashing, refs as files. Correct and clear; `master`, `git checkout`, SHA-1 only.
- ["Complete git and Github course in Hindi"](https://www.youtube.com/watch?v=q8EevlEpQ2A), Chai aur Code, Hindi, 2 hours 55 minutes, 8 June 2024, from 55:16. Commit, tree and blob by name; HEAD as a pointer to the current branch. Local `master`; no revert, restore or cherry-pick.

**Further reading**

- [gitcore-tutorial](https://git-scm.com/docs/gitcore-tutorial), the Git project's own walk through the plumbing, and [The Git User's Manual](https://git-scm.com/docs/user-manual).
