# Chapter 5: The Index

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch05/`.

## 5.1 Why this matters

Three questions a CTO can ask:

1. "You ran the tests, they passed, you committed. CI ran that commit and failed on the line you had fixed. Which of the two is wrong?"
2. "A developer wanted to keep one file out of a commit. The commit deleted that file from the project for everyone. What did they type, and why did Git itself suggest it?"
3. "Half the team hides local configuration edits with `git update-index --assume-unchanged`. Last week a pull was refused on a clean working tree, and then somebody's settings were gone. Why is there no switch for 'ignore my local changes'?"

The three share one root. Git does not build a commit from your files. It builds it from the index, a second complete record of the project that sits between the working tree and HEAD. The answers: the commit contained what was in the index, and the tests ran against something else (sections 5.3 and 5.5); `git rm --cached` deletes an index entry, where unstaging means restoring it (section 5.9); and the bit is a promise that you will not edit the file, not a request to overlook edits (section 5.12).

Understanding usually stops at this layer. "How do I undo 'git add' before commit?" is the fifth most-voted Git question on Stack Overflow (11,626 votes on 1 October 2026, from the Phase 0 report of this course), and none of the ten popular beginner resources that the report surveyed teaches the index as a data structure. Hold on to one idea: the index is not a list of changes. It is a full snapshot.

## 5.2 The index: the proposed next commit, stored as one file

**In one sentence.** The index is a single file, `.git/index`, that lists every tracked path together with the ID of a blob, and `git commit` turns exactly that list into the tree of the new commit.

**Analogy.** The packing list for the next shipment. It names every item that will be in the box, not the items that differ from the last box, and the warehouse ships what the list says even if the shelf has changed since. The analogy breaks in two places: writing a line on this list also puts a copy of the item into storage at that moment (section 5.3), and during a conflict the list can carry three candidate lines for one item (section 5.13).

**Precisely.** Git's data-model document: "The index, also known as the 'staging area', is a list of files and the contents of each file, stored as a blob", and "Unlike a tree, the index is a flat list of files. When you commit, Git converts the list of files in the index to a directory tree and uses that tree in the new commit" ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)). Each entry has four fields: the file type and mode, the blob ID, a stage number (0 except during a conflict) and the full path; mode, blob ID and path are what the commit's tree receives. Each entry also carries bookkeeping that never leaves your machine: cached filesystem data (section 5.14) and flag bits (sections 5.6 and 5.12). The old name "cache" survives in options such as `--cached`.

The definition corrects the most common wrong model. Nothing in the index is a "change". "Staged changes" are the result of comparing the index with HEAD, and an index with nothing staged is not empty: it describes the same tree as HEAD.

**Inside `.git`.** One binary file, created by the first `git add`: a 12-byte header, the entries sorted by path, optional extensions and a checksum ([gitformat-index](https://git-scm.com/docs/gitformat-index)). Chapter 3 (Git Internals) reads it byte by byte.

**See it.** `git ls-files --stage` prints the four fields of every entry:

<!-- snippet: ch05/index-is-snapshot/01-flat-list -->
```text
# The index: one line per file, with mode, blob ID, stage number and full path.
$ git ls-files --stage
100644 87806e1f4037a90d2243b92a5136fd330bd6570c 0	README.md
100644 4da99e38a05a2a7b436aaea17b946e0288949413 0	config/settings.yaml
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 1e0b1ade696068e087656f8ae5e859fe92aef3b8 0	src/retriever.py
# The tree of HEAD: the same files, arranged as nested tree objects.
$ git ls-tree HEAD
100644 blob 87806e1f4037a90d2243b92a5136fd330bd6570c	README.md
040000 tree d654a67edecb91bd680f03493196872f0b3626eb	config
040000 tree 8e3c2dcba993bebbb0d2d3439234797c8b3cbbe0	src
$ git ls-tree -r HEAD
100644 blob 87806e1f4037a90d2243b92a5136fd330bd6570c	README.md
100644 blob 4da99e38a05a2a7b436aaea17b946e0288949413	config/settings.yaml
100644 blob 63df51b788f2464137e0f30355056e42a320f705	src/app.py
100644 blob 1e0b1ade696068e087656f8ae5e859fe92aef3b8	src/retriever.py
```
<!-- /snippet -->

Four lines with full paths. HEAD's tree has three entries, two of them trees; flattened with `git ls-tree -r`, it gives the same four modes, blob IDs and paths. The file itself starts with the signature `DIRC`, the format version and the entry count:

<!-- snippet: ch05/index-is-snapshot/02-file-header -->
```text
# The index is one binary file. Its first 12 bytes: signature, format version, number of entries.
$ head -c 12 .git/index | hexdump -C
00000000  44 49 52 43 00 00 00 02  00 00 00 04              |DIRC........|
0000000c
$ git update-index --show-index-version
2
$ git ls-files | wc -l
       4
```
<!-- /snippet -->

🟢 `git write-tree` does on request what `git commit` does every time: it writes the index out as tree objects and prints the ID of the top one. With nothing staged, that is the tree HEAD already has:

<!-- snippet: ch05/index-is-snapshot/03-index-equals-head -->
```text
# Write the index out as a tree object. With nothing staged it is the tree HEAD already has.
$ git write-tree
676700b510b47ab35c5d2aa71977f80d234cdcbc
$ git rev-parse HEAD^{tree}
676700b510b47ab35c5d2aa71977f80d234cdcbc
```
<!-- /snippet -->

Stage one change. One entry gets a new blob ID (`4da99e3` becomes `0217758`), and the index describes a different tree:

<!-- snippet: ch05/index-is-snapshot/04-stage-one-file -->
```text
$ echo 'temperature: 0.2' >> config/settings.yaml
$ git add config/settings.yaml
$ git ls-files --stage
100644 87806e1f4037a90d2243b92a5136fd330bd6570c 0	README.md
100644 0217758d92bf9cd7d8ebba62175a33a9ef51ba2f 0	config/settings.yaml
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 1e0b1ade696068e087656f8ae5e859fe92aef3b8 0	src/retriever.py
# One entry has a new blob ID. Every other entry is untouched. The tree this index describes:
$ git write-tree
dd3751c99563c335e9d6db98fd3ebaedfc6ad007
```
<!-- /snippet -->

<!-- snippet: ch05/index-is-snapshot/05-commit-takes-that-tree -->
```text
$ git commit -m "Set sampling temperature"
[main e3aa1bc] Set sampling temperature
 1 file changed, 1 insertion(+)
$ git rev-parse HEAD^{tree}
dd3751c99563c335e9d6db98fd3ebaedfc6ad007
$ git status
On branch main
nothing to commit, working tree clean
```
<!-- /snippet -->

The commit's tree is `dd3751c`, the ID that `git write-tree` printed before the commit existed. The commit did not read the working tree. Afterwards the index and HEAD describe the same tree again, which is what "nothing to commit" means.

**Picture.**

```text
   .git/index: flat, sorted by path                    tree objects, written at commit time

   mode    blob ID  stage  path                        676700b                 (top-level tree)
   100644  87806e1  0      README.md                    |-- blob 87806e1  README.md
   100644  4da99e3  0      config/settings.yaml   ==>   |-- tree d654a67  config
   100644  63df51b  0      src/app.py                   |     `-- blob 4da99e3  settings.yaml
   100644  1e0b1ad  0      src/retriever.py             `-- tree 8e3c2dc  src
                                                              |-- blob 63df51b  app.py
                                                              `-- blob 1e0b1ad  retriever.py
```

**In production.** "What exactly will be in this commit?" has one authoritative answer, the index. Reviewers, CI and every clone receive the tree that was written from it, never your working tree.

> **GitHub, not Git.** GitHub never sees your index. A push transfers commits and the objects they refer to, and everything GitHub shows or checks is derived from those.

## 5.3 What `git add` writes

**In one sentence.** 🟢 `git add <path>` stores the current content of the file as a blob in the object database and writes that blob's ID into the path's index entry: a copy taken at that moment, not a subscription to the file.

**Precisely.** The manual: "It only adds the content of the specified file(s) at the time the add command is run; if you want subsequent changes included in the next commit, then you must run `git add` again" ([git-add](https://git-scm.com/docs/git-add)). Two things are written: one object, unless an identical blob already exists, and one index entry. No ref moves, so no reflog records an add.

**See it.** `git hash-object` computes the ID that the edited file would get. No such object exists yet:

<!-- snippet: ch05/add-writes/01-before-add -->
```text
$ git cat-file --batch-all-objects --batch-check
4da99e38a05a2a7b436aaea17b946e0288949413 blob 25
701a11e018456aece1cb6cee6528889539fde3ff tree 33
7bd7d2318a2a4a2b9a16bfbfdd11e7c48a2fda07 commit 165
d654a67edecb91bd680f03493196872f0b3626eb tree 41
$ echo 'max_tokens: 512' >> config/settings.yaml
# hash-object computes the ID this content would get. It writes nothing.
$ git hash-object config/settings.yaml
e4eb0e6d146a5b1eb62d3a52301f262836a0a224
$ git cat-file -t e4eb0e6
fatal: Not a valid object name e4eb0e6
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch05/add-writes/02-add -->
```text
$ git add config/settings.yaml
$ git cat-file --batch-all-objects --batch-check
4da99e38a05a2a7b436aaea17b946e0288949413 blob 25
701a11e018456aece1cb6cee6528889539fde3ff tree 33
7bd7d2318a2a4a2b9a16bfbfdd11e7c48a2fda07 commit 165
d654a67edecb91bd680f03493196872f0b3626eb tree 41
e4eb0e6d146a5b1eb62d3a52301f262836a0a224 blob 41
$ git ls-files --stage
100644 e4eb0e6d146a5b1eb62d3a52301f262836a0a224 0	config/settings.yaml
$ git cat-file -p e4eb0e6
model: small-v1
top_k: 5
max_tokens: 512
```
<!-- /snippet -->

After the add there is a fifth object, a blob with the predicted ID, and the index entry names it. Now edit the file again without adding it:

<!-- snippet: ch05/add-writes/03-add-is-a-snapshot -->
```text
# Edit the file again after the add. The index keeps what it was given.
$ echo 'debug: true' >> config/settings.yaml
$ git status --short
MM config/settings.yaml
$ git show :config/settings.yaml
model: small-v1
top_k: 5
max_tokens: 512
$ git commit -m "Limit response length"
[main 388a0ba] Limit response length
 1 file changed, 1 insertion(+)
$ git show HEAD:config/settings.yaml
model: small-v1
top_k: 5
max_tokens: 512
$ git status --short
 M config/settings.yaml
```
<!-- /snippet -->

`MM` says that both comparisons of `git status` find a difference (Chapter 4, section 4.4). `git show :config/settings.yaml` prints the staged blob, which lacks `debug: true`. The commit records that blob, and the file is still modified afterwards (` M`).

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git add <path>` | unchanged | entry for `<path>` created or updated; what was staged for it before is replaced | unchanged | unchanged | one new blob under `objects/` if the content is new | unchanged | unchanged |

> **Root cause.** A fix that was tested but is missing from the commit was edited after the last `git add`. The commit is written from the index, which still held the earlier version; status showed `MM`. Add the file again and commit, and read `git diff --cached` before every commit. Chapter 1, section 1.12 works through the two-file form of this failure.

**What an add leaves behind.** Unstaging removes the entry, not the object. Here `git add .` picked up an environment file, and the slip was corrected at once:

<!-- snippet: ch05/add-leaves-a-blob/01-add-then-unstage -->
```text
$ echo 'LLM_API_KEY=lab-secret-0001' > .env
# The slip: everything is added, including the environment file.
$ git add .
$ git status --short
A  .env
$ git restore --staged .env
$ git status --short
?? .env
```
<!-- /snippet -->

<!-- snippet: ch05/add-leaves-a-blob/02-the-blob-is-still-there -->
```text
# The index entry is gone. The object that "git add" wrote is not.
$ git fsck
dangling blob 5620d7c0158994dedf8a5ff7d48b68e5479f513c
$ git cat-file -p 5620d7c
LLM_API_KEY=lab-secret-0001
```
<!-- /snippet -->

`git fsck` reports a dangling blob, an object that nothing refers to, and `git cat-file -p` prints the secret from it. Has it left the machine?

<!-- snippet: ch05/add-leaves-a-blob/03-a-push-does-not-send-it -->
```text
# A push sends the objects that the pushed commits need. Nothing refers to this blob.
$ git push -q ../central.git main
$ git -C ../central.git rev-parse main
a03ed3139b72f324996c67688f6c26074f601f3c
$ git -C ../central.git cat-file -t 5620d7c
fatal: Not a valid object name 5620d7c
[exit status: 128]
$ git cat-file -t 5620d7c
blob
```
<!-- /snippet -->

The repository that received the push has the commit and not the blob. A push sends what the pushed commits need, and no commit refers to this object.

**In production.** A secret or a 2 GB checkpoint that was added and then unstaged is in no commit and has not travelled, so there is no history to rewrite. Garbage collection removes the stray object once it is older than `gc.pruneExpire`, two weeks by default (Chapter 13, Recovery). Until then it is also a rescue route: content that was staged once and then lost can be found with `git fsck` (Lab 2.1).

## 5.4 Three diffs, three comparisons

**In one sentence.** Three places for a version of a file give three pairwise comparisons, and `git diff` performs a different one depending on its arguments.

| Command | Compares | Answers |
|---|---|---|
| `git diff` | index with working tree | What could I still stage? |
| `git diff --cached` (synonym: `--staged`) | HEAD with index | What will the next commit change? |
| `git diff HEAD` | HEAD with working tree | What changed since the last commit, staged or not? |

**See it.** `TOP_K` was changed and staged, then `MIN_SCORE` was changed and not staged:

<!-- snippet: ch05/three-diffs/02-diff -->
```text
# Index against working tree: what you could still stage.
$ git diff
diff --git a/src/retriever.py b/src/retriever.py
index 399da0e..5853020 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,5 +1,5 @@
 TOP_K = 8
-MIN_SCORE = 0.2
+MIN_SCORE = 0.35
 
 
 def retrieve(query, index):
```
<!-- /snippet -->

<!-- snippet: ch05/three-diffs/03-diff-cached -->
```text
# HEAD against index: what the next commit will change. --staged is a synonym.
$ git diff --cached
diff --git a/src/retriever.py b/src/retriever.py
index bd144df..399da0e 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,4 +1,4 @@
-TOP_K = 5
+TOP_K = 8
 MIN_SCORE = 0.2
 
 
```
<!-- /snippet -->

<!-- snippet: ch05/three-diffs/04-diff-head -->
```text
# HEAD against working tree: everything since the last commit, staged or not.
$ git diff HEAD
diff --git a/src/retriever.py b/src/retriever.py
index bd144df..5853020 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,5 +1,5 @@
-TOP_K = 5
-MIN_SCORE = 0.2
+TOP_K = 8
+MIN_SCORE = 0.35
 
 
 def retrieve(query, index):
```
<!-- /snippet -->

Read the `index` line of each diff: `399da0e..5853020`, `bd144df..399da0e`, `bd144df..5853020`. `bd144df` is the blob in HEAD, `399da0e` the staged blob, and `5853020` the ID that the working tree content would get; no object with that ID exists until you add the file. Each command compares two of the three.

Now put HEAD's content back into the working tree only (Chapter 4, section 4.7):

<!-- snippet: ch05/three-diffs/05-cancel-out -->
```text
# Put the content of HEAD back into the working tree only. The index still has TOP_K = 8.
$ git restore --source=HEAD src/retriever.py
$ git status --short
MM src/retriever.py
$ git diff HEAD
$ git diff --cached --stat
 src/retriever.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --stat
 src/retriever.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
# The files on disk match HEAD, yet a commit made now would set TOP_K to 8.
```
<!-- /snippet -->

`git diff HEAD` is empty, because the files on disk equal HEAD. The other two comparisons each show one changed line, in opposite directions, and a commit made now would set `TOP_K` to 8.

**Picture.**

```text
        HEAD                       index                    working tree
      bd144df                    399da0e                      5853020
   +------------+             +------------+             +--------------+
   | TOP_K = 5  |  git diff   | TOP_K = 8  |             | TOP_K = 8    |
   | MIN = 0.2  |  --cached   | MIN = 0.2  |  git diff   | MIN = 0.35   |
   +------------+ <---------> +------------+ <---------> +--------------+
          ^                                                      ^
          +---------------------- git diff HEAD -----------------+
```

**In production.** Make `git diff --cached` the last command before `git commit`: it is the review of what you are about to record. An empty `git diff HEAD` proves nothing about the next commit, and none of the three shows a file that has no index entry (section 5.6).

## 5.5 Partial staging: `git add -p`

**In one sentence.** 🟢 `git add -p` walks through the difference between the index and the working tree one hunk at a time and stages only the hunks you accept, so one edited file can feed several commits and leave a remainder that is never committed.

**Analogy.** Marking, on a manuscript full of your own edits, the blocks that go to the printer today. The analogy breaks where it matters most: the printer receives a page that never lay on your desk in that form, and nobody has read that page as a whole.

**Precisely.** A hunk is a block of changed lines with its context, as in `git diff`. Git asks about each hunk and you answer with a letter ([git-add](https://git-scm.com/docs/git-add), "Interactive mode"):

| Answer | Effect |
|---|---|
| `y`, `n` | Stage this hunk; leave it |
| `s` | Split the hunk. Offered only when unchanged lines separate the changes in it |
| `e` | Open the hunk in your editor and stage the edited version |
| `a`, `d` | Stage, or leave, this hunk and all later hunks of the file |
| `q` | Stop. Hunks already accepted are staged |
| `j`, `J`, `k`, `K`, `g`, `/`, `p`, `?` | Move between hunks, search, print the hunk again, print the help |

The same selector runs in the other direction in `git restore -p`, `git restore --staged -p` and `git reset -p`.

**See it.** One file holds a tuning change (`TOP_K`), a bug fix (the guard for a zero vector) and a debug print. The fix must become a commit of its own:

<!-- snippet: ch05/add-patch/03-split-and-choose -->
```text
# Answers: s (split), n (TOP_K: not in this commit), y (the fix), n (the debug print).
$ git add -p
diff --git a/src/retriever.py b/src/retriever.py
index 177cb37..e548d1b 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1,12 +1,14 @@
 """Retrieval for the support bot."""
 import math
 
-TOP_K = 5
+TOP_K = 8
 MIN_SCORE = 0.2
 
 
 def normalize(vec):
     length = math.sqrt(sum(x * x for x in vec))
+    if length == 0:
+        return vec
     return [x / length for x in vec]
 
 
(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,s,e,p,P,?]? s
Split into 2 hunks.
@@ -1,9 +1,9 @@
 """Retrieval for the support bot."""
 import math
 
-TOP_K = 5
+TOP_K = 8
 MIN_SCORE = 0.2
 
 
 def normalize(vec):
     length = math.sqrt(sum(x * x for x in vec))
(1/3) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? n
@@ -5,8 +5,10 @@
 MIN_SCORE = 0.2
 
 
 def normalize(vec):
     length = math.sqrt(sum(x * x for x in vec))
+    if length == 0:
+        return vec
     return [x / length for x in vec]
 
 
(2/3) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? y
@@ -18,4 +20,5 @@ def retrieve(query_vec, index):
     query_vec = normalize(query_vec)
     scored = [(score(query_vec, vec), doc_id) for doc_id, vec in index]
     scored.sort(reverse=True)
+    print("DEBUG scored:", scored)
     return [(s, doc_id) for s, doc_id in scored[:TOP_K] if s >= MIN_SCORE]
(3/3) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? n
```
<!-- /snippet -->

Git first offered two hunks, because the `TOP_K` line and the guard were close enough to share context. `s` split the first one (`1/2` became `1/3`), and the answers were no, yes, no:

<!-- snippet: ch05/add-patch/04-result -->
```text
$ git status --short
MM src/retriever.py
$ git diff --cached
diff --git a/src/retriever.py b/src/retriever.py
index 177cb37..a7cba42 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -7,6 +7,8 @@ MIN_SCORE = 0.2
 
 def normalize(vec):
     length = math.sqrt(sum(x * x for x in vec))
+    if length == 0:
+        return vec
     return [x / length for x in vec]
 
 
```
<!-- /snippet -->

**Inside `.git`.** One new blob, `a7cba42`, and one changed index entry; the state table of section 5.3 applies. The blob is HEAD's version plus one hunk, content that has never existed as a file.

Three versions of the file now exist. HEAD (`177cb37`) has none of the three edits. The working tree (`e548d1b`) has all three and is what you ran. The index (`a7cba42`) has the guard alone, and that version has never run anywhere. Before you commit it, copy the staged snapshot out of the index and test that:

<!-- snippet: ch05/add-patch/05-export-the-proposed-commit -->
```text
# The staged snapshot has never existed as files. Export it to test it.
$ git checkout-index --all --prefix=../staged-snapshot/
$ diff ../staged-snapshot/src/retriever.py src/retriever.py
4c4
< TOP_K = 5
---
> TOP_K = 8
22a23
>     print("DEBUG scored:", scored)
```
<!-- /snippet -->

🟢 `git checkout-index --all --prefix=<dir>/` writes every index entry as a file below `<dir>` (the trailing slash matters). The `diff` confirms that the export lacks the two lines you left out.

**When `s` is not offered.** Changed lines that touch each other form one hunk:

<!-- snippet: ch05/add-patch-edit/01-cannot-split -->
```text
# The changed lines touch each other, so the prompt offers no "s". Typing it anyway:
$ git add -p
diff --git a/config/settings.yaml b/config/settings.yaml
index bfcfe5c..d56fa8e 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1,4 +1,5 @@
 model: small-v1
-top_k: 5
-temperature: 0.7
+top_k: 8
+temperature: 0.2
+debug: true
 max_tokens: 512
(1/1) Stage this hunk [y,n,q,a,d,e,p,P,?]? s
Sorry, cannot split this hunk
(1/1) Stage this hunk [y,n,q,a,d,e,p,P,?]? q
```
<!-- /snippet -->

The answer `e` opens the hunk as a patch, with Git's own instructions below it:

<!-- snippet: ch05/add-patch-edit/02-edit -->
```text
# Answer "e". In the editor, delete the line "+debug: true", then save and close.
$ git add -p
diff --git a/config/settings.yaml b/config/settings.yaml
index bfcfe5c..d56fa8e 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1,4 +1,5 @@
 model: small-v1
-top_k: 5
-temperature: 0.7
+top_k: 8
+temperature: 0.2
+debug: true
 max_tokens: 512
(1/1) Stage this hunk [y,n,q,a,d,e,p,P,?]? e
--- the hunk file as Git opened it in the editor ---
# Manual hunk edit mode -- see bottom for a quick guide.
@@ -1,4 +1,5 @@
 model: small-v1
-top_k: 5
-temperature: 0.7
+top_k: 8
+temperature: 0.2
+debug: true
 max_tokens: 512
# ---
# To remove '-' lines, make them ' ' lines (context).
# To remove '+' lines, delete them.
# Lines starting with # will be removed.
# If the patch applies cleanly, the edited hunk will immediately be marked for staging.
# If it does not apply cleanly, you will be given an opportunity to
# edit again.  If all lines of the hunk are removed, then the edit is
# aborted and the hunk is left unchanged.
--- the hunk as saved (comment lines left out) ---
@@ -1,4 +1,5 @@
 model: small-v1
-top_k: 5
-temperature: 0.7
+top_k: 8
+temperature: 0.2
 max_tokens: 512
```
<!-- /snippet -->

Deleting a `+` line keeps that addition out of the index. Replacing the `-` of a removed line with a space keeps that removal out. Git then recounts the hunk header and applies the patch to the index. Section 5.17 shows how this goes wrong.

**In production.** A commit that does one thing can be reviewed, reverted, cherry-picked and bisected on its own (Chapter 6). Debugging sessions do not produce changes in that shape, and partial staging sorts one messy working tree into such commits. The price is a version in the index that never ran. CI is the backstop, and the export is the local check.

## 5.6 Intent-to-add: `git add -N`

**In one sentence.** 🟢 `git add -N <path>` gives a new file an index entry without staging its content, so that commands which compare the index with the working tree stop overlooking the file.

**Precisely.** "Record only the fact that the path will be added later. An entry for the path is placed in the index with no content" ([git-add](https://git-scm.com/docs/git-add)).

**See it.** A new file is invisible to `git diff`, because there is no entry to compare it with:

<!-- snippet: ch05/intent-to-add/01-untracked-is-invisible-to-diff -->
```text
$ git status --short
?? src/prompts.py
$ git diff
# A new file does not appear in "git diff": there is no index entry to compare it with.
```
<!-- /snippet -->

<!-- snippet: ch05/intent-to-add/02-add-n -->
```text
$ git add -N src/prompts.py
$ git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	new file:   src/prompts.py

no changes added to commit (use "git add" and/or "git commit -a")
$ git ls-files --stage
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	src/prompts.py
```
<!-- /snippet -->

Status lists the path as a new file under "Changes not staged for commit", and its entry holds `e69de29`, the ID of the empty blob.

<!-- snippet: ch05/intent-to-add/03-now-diff-sees-it -->
```text
$ git diff
diff --git a/src/prompts.py b/src/prompts.py
new file mode 100644
index 0000000..bdcb5f9
--- /dev/null
+++ b/src/prompts.py
@@ -0,0 +1,2 @@
+SYSTEM = "You are a support assistant."
+MAX_TURNS = 6
$ git diff --cached
# Nothing is staged: the entry is a placeholder, and "git commit" has nothing to record.
$ git commit -m "Add prompts"
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	new file:   src/prompts.py

no changes added to commit (use "git add" and/or "git commit -a")
[exit status: 1]
```
<!-- /snippet -->

`git diff` shows the whole file as an addition, `git diff --cached` shows nothing, and `git commit` refuses: nothing is staged. The hunk selector reads the same comparison as `git diff`, so it has the same blind spot and the same cure:

<!-- snippet: ch05/add-patch-edit/06-new-file -->
```text
# The hunk selector reads the same comparison as "git diff", so it does not see an untracked file.
$ git add -p src/prompts.py
No changes.
$ git add -N src/prompts.py
$ git add -p src/prompts.py
diff --git a/src/prompts.py b/src/prompts.py
new file mode 100644
index 0000000..bdcb5f9
--- /dev/null
+++ b/src/prompts.py
@@ -0,0 +1,2 @@
+SYSTEM = "You are a support assistant."
+MAX_TURNS = 6
(1/1) Stage addition [y,n,q,a,d,e,p,P,?]? y

$ git status --short
 M config/settings.yaml
A  src/prompts.py
```
<!-- /snippet -->

**Inside `.git`.** The entry carries an intent-to-add flag. Index format version 2 has no room for it, so Git writes the index as version 3 while such an entry exists and as version 2 again after the real add (`labs/run ch05/intent-to-add` shows the switch).

**In production.** The classic "works on my machine" commit lacks a new file. The code runs locally because the file is on disk, `git diff` looked complete, `git commit -a` skipped the file (section 5.10), and CI fails with a missing module. `git add -N` when you create a file puts it into every later `git diff`, `git add -p` and `git commit -a`.

## 5.7 Staging deletions, renames and binary files

**In one sentence.** In index terms a deletion is a removed entry, a rename is a removed entry plus an added one, and a binary file is an ordinary entry whose content Git will neither show nor split.

**See it.**

<!-- snippet: ch05/stage-deletions-renames-binary/01-deletion -->
```text
$ git ls-files --stage
100644 4dddde5373611e10f9ec6bc328a25ae216552487 0	docs/old-notes.md
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 67b3f03b8c4ab448c68cda278050d05e9c1865f0 0	src/retriever.py
$ rm docs/old-notes.md
$ git status --short
 D docs/old-notes.md
# Staging a deletion removes the index entry. "git add" does it for a path that is gone.
$ git add docs/old-notes.md
$ git status --short
D  docs/old-notes.md
$ git ls-files --stage
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 67b3f03b8c4ab448c68cda278050d05e9c1865f0 0	src/retriever.py
```
<!-- /snippet -->

After `rm`, the entry exists and the file does not (` D`). `git add` on the missing path removes the entry (`D `). `git rm` does both steps at once (Chapter 4, section 4.8).

<!-- snippet: ch05/stage-deletions-renames-binary/02-rename -->
```text
$ mv src/retriever.py src/search.py
$ git status --short
D  docs/old-notes.md
 D src/retriever.py
?? src/search.py
$ git add src/retriever.py src/search.py
$ git status --short
D  docs/old-notes.md
R  src/retriever.py -> src/search.py
$ git ls-files --stage
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 67b3f03b8c4ab448c68cda278050d05e9c1865f0 0	src/search.py
# One entry removed, one entry added with the same blob ID. "Renamed" is a conclusion status draws.
```
<!-- /snippet -->

Status prints `R`, but the index only lost one entry and gained another with the same blob ID, `67b3f03`. Nothing recorded a rename: status inferred it from the pair (Chapter 4, section 4.9). A binary file, here a small image, is staged like any other file:

<!-- snippet: ch05/stage-deletions-renames-binary/03-binary -->
```text
$ git add assets/logo.png
$ git ls-files --stage assets
100644 5b7d1ca0ae1e65da75b02e4d87cedec1edd00589 0	assets/logo.png
$ git diff --cached --stat -- assets
 assets/logo.png | Bin 0 -> 20 bytes
 1 file changed, 0 insertions(+), 0 deletions(-)
$ git diff --cached -- assets
diff --git a/assets/logo.png b/assets/logo.png
new file mode 100644
index 0000000..5b7d1ca
Binary files /dev/null and b/assets/logo.png differ
$ git diff --cached --numstat -- assets
-	-	assets/logo.png
```
<!-- /snippet -->

The entry looks like any other. The diff says "Binary files ... differ", `--stat` gives byte sizes and `--numstat` prints dashes. When one byte changes, the next add writes a complete new blob, and `git add -p` has nothing to offer:

<!-- snippet: ch05/stage-deletions-renames-binary/04-binary-change -->
```text
# Change one byte of the image.
$ git diff --stat
 assets/logo.png | Bin 20 -> 20 bytes
 1 file changed, 0 insertions(+), 0 deletions(-)
# There are no hunks to choose from in a binary file.
$ git add -p assets/logo.png
Only binary files changed.
$ git add assets/logo.png
$ git ls-files --stage assets
100644 9d52479bdc3b8b3068d9f2c4ace19bc88fe1c5d2 0	assets/logo.png
```
<!-- /snippet -->

**Precisely.** Unless a `diff` attribute decides, Git inspects the content: "if it looks like text and is smaller than core.bigFileThreshold, it is treated as text" ([gitattributes](https://git-scm.com/docs/gitattributes)).

**In production.** Model weights, images and compressed datasets get no partial staging and no readable diff, and every changed version is stored whole when it is added: they belong in Git LFS or outside Git (Chapter 22). A Jupyter notebook is text to Git, so `git add -p` works on it, but its hunks are JSON with embedded outputs (Chapter 28, AI/ML Workflows).

## 5.8 `git add -u`, `git add -A` and `git add .`

**In one sentence.** The bulk forms differ in two things: whether untracked files are included, and whether the command is limited to the current directory.

| Command | Modified tracked | Deleted tracked | Untracked | Scope |
|---|---|---|---|---|
| `git add -u` | staged | staged | not touched | whole working tree |
| `git add -A` | staged | staged | staged | whole working tree |
| `git add .` | staged | staged | staged | current directory and below |
| `git add -u .` | staged | staged | not touched | current directory and below |
| `git add --no-all <path>` | staged | not touched | staged | the pathspec |

No form adds ignored files (Chapter 4, section 4.3).

**See it.** From inside `src/`, with one modification, one deletion and one new file both inside and outside that directory. `--dry-run` (`-n`) prints what would happen and stages nothing:

<!-- snippet: ch05/add-scope/01-state -->
```text
$ git status --short
 M README.md
 D docs/guide.md
 M src/app.py
 D src/retriever.py
?? notes.md
?? src/prompts.py
$ cd src
# From a subdirectory, the short format shows paths relative to where you stand.
$ git status --short
 M ../README.md
 D ../docs/guide.md
 M app.py
 D retriever.py
?? ../notes.md
?? prompts.py
```
<!-- /snippet -->

<!-- snippet: ch05/add-scope/02-dot -->
```text
# A pathspec limits the command. "." means this directory and below.
$ git add --dry-run .
add 'src/app.py'
remove 'src/retriever.py'
add 'src/prompts.py'
```
<!-- /snippet -->

<!-- snippet: ch05/add-scope/03-update -->
```text
# -u: every tracked path in the whole working tree. No new files.
$ git add --dry-run -u
add 'README.md'
remove 'docs/guide.md'
add 'src/app.py'
remove 'src/retriever.py'
# -u with a pathspec: tracked paths in this directory and below.
$ git add --dry-run -u .
add 'src/app.py'
remove 'src/retriever.py'
```
<!-- /snippet -->

<!-- snippet: ch05/add-scope/04-all -->
```text
# -A: every change in the whole working tree, new files included.
$ git add --dry-run -A
add 'README.md'
remove 'docs/guide.md'
add 'src/app.py'
remove 'src/retriever.py'
add 'notes.md'
add 'src/prompts.py'
```
<!-- /snippet -->

`.` stayed inside `src/` and included the new file and the removal. `-u` reached `README.md` and `docs/guide.md` outside the directory and skipped both new files. `-A` took everything.

> **Outdated advice.** Tutorials written before Git 2.0 say that `git add -u` and `git add -A` cover only the current directory and that `git add <path>` ignores removed files. Both changed in 2.0 (section 5.19).

**In production.** `git add -A` and `git add .` are how files that nobody meant to track get tracked: an `.env` created before its ignore rule, a dataset, the output of a failed experiment. Use `git add -u` for "what I changed in files Git already knows", name new files explicitly, and run a bulk form with `-n` first in a working tree you have not inspected.

## 5.9 Unstaging: three commands, two meanings

**In one sentence.** To unstage a path is to make its index entry equal to HEAD's again: 🟡 `git restore --staged <path>` and 🟡 `git reset <path>` do that, while 🟡 `git rm --cached <path>` deletes the entry, which is the same thing only when HEAD has no such path.

**See it.** A tracked file with a staged modification, and a new file that has only been added:

<!-- snippet: ch05/unstage-three-ways/01-setup -->
```text
# A tracked file with a staged modification, and a new file that has only been added.
$ echo 'TOP_K = 8' > src/retriever.py
$ echo 'SYSTEM = "You are a support assistant."' > src/prompts.py
$ git add src/retriever.py src/prompts.py
$ git status --short
A  src/prompts.py
M  src/retriever.py
$ git ls-files --stage
100644 5e83731ea002effc7ffce6c4a2b565cbf889abd8 0	src/prompts.py
100644 5fac60c5a32ec062dcb2163acd05c4c1c20dda0c 0	src/retriever.py
```
<!-- /snippet -->

<!-- snippet: ch05/unstage-three-ways/02-restore-staged -->
```text
# restore --staged copies the entry from HEAD. A path HEAD lacks loses its entry.
$ git restore --staged src/retriever.py src/prompts.py
$ git status --short
 M src/retriever.py
?? src/prompts.py
$ git ls-files --stage
100644 1e0b1ade696068e087656f8ae5e859fe92aef3b8 0	src/retriever.py
```
<!-- /snippet -->

The tracked file's entry holds HEAD's blob `1e0b1ad` again, and the path shows ` M`. The new file, which HEAD lacks, lost its entry and is untracked. `git reset <path>` leaves the identical index and reports what remains unstaged:

<!-- snippet: ch05/unstage-three-ways/03-reset-path -->
```text
# reset <path> does the same to the index, and reports what is left unstaged.
$ git reset src/retriever.py src/prompts.py
Unstaged changes after reset:
M	src/retriever.py
$ git status --short
 M src/retriever.py
?? src/prompts.py
$ git ls-files --stage
100644 1e0b1ade696068e087656f8ae5e859fe92aef3b8 0	src/retriever.py
```
<!-- /snippet -->

<!-- snippet: ch05/unstage-three-ways/04-rm-cached -->
```text
# rm --cached removes the entry, whatever HEAD has.
$ git rm --cached src/retriever.py src/prompts.py
rm 'src/prompts.py'
rm 'src/retriever.py'
$ git status --short
D  src/retriever.py
?? src/
$ git ls-files --stage
# For the tracked file that is a staged deletion: the next commit would remove it from the project.
```
<!-- /snippet -->

`git rm --cached` removed both entries. For the new file the outcome is the same. For the tracked file it is a staged deletion (`D `): the next commit would remove `src/retriever.py` from the project, although the file stays on your disk.

| | `git restore --staged` | `git reset <path>` | `git rm --cached` |
|---|---|---|---|
| Path that HEAD has | staged change undone | staged change undone | deletion staged |
| Path that HEAD lacks | entry removed | entry removed | entry removed |
| Repository without commits | fails: HEAD cannot be resolved | works | works |
| Safety check | none | none | refuses when the staged content matches neither HEAD nor the file |

The last two rows, as run:

<!-- snippet: ch05/unstage-three-ways/05-rm-cached-guard -->
```text
# Index, HEAD and working tree now hold three different versions of one file.
$ echo 'TOP_K = 12' > src/retriever.py
$ git rm --cached src/retriever.py
error: the following file has staged content different from both the
file and the HEAD:
    src/retriever.py
(use -f to force removal)
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch05/unstage-three-ways/06-unborn-branch -->
```text
# A repository with no commit yet has no HEAD to copy from.
$ cd ..
$ git init -q fresh && cd fresh
$ echo 'TOP_K = 5' > retriever.py
$ git add retriever.py
$ git status
On branch main

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
	new file:   retriever.py

$ git restore --staged retriever.py
fatal: could not resolve 'HEAD'
[exit status: 128]
$ git reset retriever.py
[exit status: 0]
$ git status --short
?? retriever.py
```
<!-- /snippet -->

The guard protects a staged version that would otherwise survive only as an unreachable object ([git-rm](https://git-scm.com/docs/git-rm)); the other two commands have no such check. And before the first commit, `git status` itself recommends `git rm --cached`. There the advice is right, because every staged path is new. It is also where the habit starts.

```text
Observed behavior : A developer "unstaged" a file to keep it out of a commit. The commit deleted
                    the file from the project, and teammates lost it on their next pull.
Git state         : The path existed in HEAD. After git rm --cached the index had no entry for
                    it, and status showed "D " and "??" for the same path.
Mechanism         : A path that HEAD has and the index lacks is a deletion in the next commit.
Root cause        : git rm --cached was used to unstage. It removes the entry instead of
                    restoring the one from HEAD.
Why Git does this : rm --cached exists to stop tracking a file (Chapter 4, section 4.6).
Correct fix       : Before the commit: git restore --staged <path>. After it:
                    git restore --source=HEAD~1 --staged <path>, then a new commit (Lab 2.4).
Prevention        : Unstage with git restore --staged. Read "D " as "the next commit deletes this".
```

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git restore --staged <path>`, `git reset <path>` | unchanged | entry replaced by HEAD's, or removed if HEAD has no such path | unchanged | unchanged | unchanged; the blob that was staged stays as an unreachable object | unchanged | unchanged |
| `git rm --cached <path>` | unchanged | entry removed | unchanged | unchanged | unchanged | unchanged | unchanged |

`git reset` without a path unstages everything. And when the working tree has moved on since the add, the unreachable blob is the only copy of the staged version (Lab 2.1 recovers one).

## 5.10 Two commit forms that bypass what you staged

**In one sentence.** 🟢 `git commit -a` stages every modified and deleted tracked file and then commits, and 🟢 `git commit <path>` commits the working tree content of the named paths and nothing else: both read the working tree at commit time, whatever you staged before.

**Precisely.** With paths, the commit takes "the updated working tree contents of the paths specified on the command line, disregarding any contents that have been staged for other paths"; `-i` (`--include`) instead stages the named paths on top of what is already staged, "usually not what you want unless you are concluding a conflicted merge" ([git-commit](https://git-scm.com/docs/git-commit)).

| Command | Tree of the new commit | Staged changes to other paths |
|---|---|---|
| `git commit -a` | the index after staging every tracked modification and deletion | committed |
| `git commit <path>` | HEAD's tree with the named paths taken from the working tree | stay staged, not committed |
| `git commit -i <path>` | the index after staging the named paths | committed |

**See it.**

<!-- snippet: ch05/commit-shortcuts/01-commit-a -->
```text
# One modified file, one deleted file, one new file. Nothing staged.
$ git status --short
 D docs/old-notes.md
 M src/retriever.py
?? src/prompts.py
$ git commit -a -m "Raise TOP_K and drop old notes"
[main 3a8aac6] Raise TOP_K and drop old notes
 2 files changed, 1 insertion(+), 2 deletions(-)
 delete mode 100644 docs/old-notes.md
$ git status --short
?? src/prompts.py
# -a staged the modification and the deletion. The new file is still untracked.
```
<!-- /snippet -->

<!-- snippet: ch05/commit-shortcuts/02-commit-path -->
```text
# settings.yaml is staged. retriever.py is modified and not staged.
$ git status --short
M  config/settings.yaml
 M src/retriever.py
?? src/prompts.py
$ git commit src/retriever.py -m "Raise TOP_K to 10"
[main b271980] Raise TOP_K to 10
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --stat --format=%s HEAD
Raise TOP_K to 10

 src/retriever.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status --short
M  config/settings.yaml
?? src/prompts.py
# The commit took retriever.py from the working tree and left the staged settings.yaml for later.
```
<!-- /snippet -->

The path form committed `retriever.py` alone and left the staged `settings.yaml` for later. It also overrides partial staging of the file it names. Below, a clean version of `retriever.py` is staged and the working tree holds one more line:

<!-- snippet: ch05/commit-shortcuts/03-commit-path-overrides-partial-staging -->
```text
# Stage a clean version of retriever.py while the working tree also holds a debug line.
$ git diff --cached -- src/retriever.py
diff --git a/src/retriever.py b/src/retriever.py
index 474e4c9..f028408 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1 +1 @@
-TOP_K = 10
+TOP_K = 12
$ git diff -- src/retriever.py
diff --git a/src/retriever.py b/src/retriever.py
index f028408..66f5344 100644
--- a/src/retriever.py
+++ b/src/retriever.py
@@ -1 +1,2 @@
 TOP_K = 12
+print("DEBUG TOP_K", TOP_K)
$ git commit src/retriever.py -m "Raise TOP_K to 12"
[main aa38475] Raise TOP_K to 12
 1 file changed, 2 insertions(+), 1 deletion(-)
$ git show HEAD:src/retriever.py
TOP_K = 12
print("DEBUG TOP_K", TOP_K)
```
<!-- /snippet -->

The commit contains the debug line: what you staged for that path was replaced by the file on disk. A path that Git does not know is an error, not an add, and `--dry-run` previews any commit command:

<!-- snippet: ch05/commit-shortcuts/05-untracked-path -->
```text
$ git commit src/prompts.py -m "Add prompts"
error: pathspec 'src/prompts.py' did not match any file(s) known to git
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch05/commit-shortcuts/06-dry-run -->
```text
# Preview what a commit command would record without creating the commit.
$ git commit --dry-run --short -a
M  src/retriever.py
?? src/prompts.py
$ git status --short
 M src/retriever.py
?? src/prompts.py
```
<!-- /snippet -->

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git commit -a` | unchanged | entries of modified tracked files updated, entries of deleted files removed | unchanged: still names the branch | moves to the new commit | new blobs, trees and a commit; the reflogs of HEAD and the branch gain an entry | unchanged until you push | unchanged until you push |
| `git commit <path>` | unchanged | entries of the named paths updated; other staged entries kept | as above | as above | as above | as above | as above |

**In production.** `-a` suits a working tree that holds one finished change. After `git add -p` it is the wrong reflex: it stages again every hunk you left out (Lab 2.2 does this on purpose). `git commit <path>` surprises in two ways: it takes the whole file, and it leaves other staged work behind for a later commit.

## 5.11 Reading the index: `git ls-files`

**In one sentence.** `git ls-files` is the plumbing view of the index: it lists entries and, with options, compares them with the working tree, without the interpretation that `git status` adds ([git-ls-files](https://git-scm.com/docs/git-ls-files)).

| Option | Lists |
|---|---|
| none, `-c` | every path in the index |
| `-s`, `--stage` | mode, blob ID, stage number and path of every entry |
| `-m`, `-d` | tracked paths whose file differs from the entry (a deleted file counts); tracked paths whose file is missing |
| `-o`, `--others` | paths with no entry; ignore rules apply only with `--exclude-standard` |
| `-i`, `--ignored` | with `-o`: untracked paths that an ignore rule matches; with `-c`: tracked paths that one matches |

`-u` restricts the list to unmerged entries (section 5.13), `-v` adds a status tag (section 5.12), and `--error-unmatch`, `--format` and `-z` serve scripts.

**See it.** The repository has a modified file, a deleted file, an untracked file, two ignored ones, and an `.env` that was committed before its ignore rule:

<!-- snippet: ch05/ls-files-tour/02-against-working-tree -->
```text
# -m: tracked paths whose working tree file differs from the index. A deleted file counts.
$ git ls-files --modified
config/settings.yaml
src/retriever.py
# -d: tracked paths whose working tree file is gone.
$ git ls-files --deleted
config/settings.yaml
```
<!-- /snippet -->

<!-- snippet: ch05/ls-files-tour/03-others -->
```text
# -o: paths with no index entry. Ignore rules apply only when you ask for them.
$ git ls-files --others
notes.md
server.log
src/__pycache__/app.cpython-314.pyc
$ git ls-files --others --exclude-standard
notes.md
# -o -i: untracked paths that an ignore rule matches.
$ git ls-files --others --ignored --exclude-standard
server.log
src/__pycache__/app.cpython-314.pyc
# -c -i: TRACKED paths that an ignore rule matches. This finds the already-tracked trap.
$ git ls-files --cached --ignored --exclude-standard
.env
```
<!-- /snippet -->

`--others` alone lists ignored files too, which is why `--exclude-standard` appears in nearly every real use. The last command is the detector for the already-tracked trap of Chapter 4.

<!-- snippet: ch05/ls-files-tour/06-scripting -->
```text
# Is this path tracked? The exit status answers.
$ git ls-files --error-unmatch src/app.py
src/app.py
[exit status: 0]
$ git ls-files --error-unmatch notes.md
error: pathspec 'notes.md' did not match any file(s) known to git
Did you forget to 'git add'?
[exit status: 1]
# A custom format, one field at a time.
$ git ls-files --abbrev --format='%(objectmode) %(objectname) %(objectsize:padded) %(path)'
100644 5620d7c      28 .env
100644 458a0d0      24 .gitignore
100644 4da99e3      25 config/settings.yaml
100755 08029a1      20 scripts/run_eval.sh
100644 63df51b      38 src/app.py
100644 1e0b1ad      10 src/retriever.py
```
<!-- /snippet -->

**In production.** `git ls-files -z | xargs -0 <tool>` runs a formatter or linter on tracked files only and survives names with spaces.

## 5.12 Two bits that are not an ignore mechanism

**In one sentence.** 🟡 `git update-index --assume-unchanged` and `--skip-worktree` each set a flag on an index entry that tells Git not to examine the working tree file, and neither is a way to keep private edits to a tracked file, because Git has no such feature.

**Precisely.** Both flags are documented for other jobs ([git-update-index](https://git-scm.com/docs/git-update-index)):

| | `--assume-unchanged` | `--skip-worktree` |
|---|---|---|
| Documented purpose | Speed on filesystems with a slow `lstat`: "the user promises not to change the file" | Sparse checkout: "avoid writing the file to the working directory when reasonably possible" |
| Tag in `git ls-files -v` | lower case, `h` | `S` |
| `git add <path>` | does nothing, silently | refused with a sparse-checkout message |
| A merge that changes the file | refused: local changes would be overwritten | refused in the same way |
| `git restore <path>` | overwrites the edit without warning | refused: the pathspec matches nothing |

The FAQ answers the underlying wish directly: "How do I ignore changes to a tracked file? Git doesn't provide a way to do this", and the two bits "don't work properly for this purpose and shouldn't be used this way" ([gitfaq](https://git-scm.com/docs/gitfaq)).

**Inside `.git`.** One bit in one entry of your `.git/index`. No commit, ref or configuration file records it, so no clone has it, and rebuilding the index (section 5.15) erases it.

**See it.** A private edit points the service at a local model server:

<!-- snippet: ch05/assume-skip/01-assume-unchanged -->
```text
$ git update-index --assume-unchanged config/settings.yaml
# ls-files -v shows the bit as a lower-case tag.
$ git ls-files -v
h config/settings.yaml
H src/app.py
# Point the service at a local model server. A private edit you do not want to commit.
$ cat config/settings.yaml
model: small-v1
api_base: http://localhost:8080
$ git status --short
$ git diff
```
<!-- /snippet -->

<!-- snippet: ch05/assume-skip/02-assume-unchanged-hides-from-everything -->
```text
# It is hidden from every command that asks "what changed?", including the ones you want.
$ git add config/settings.yaml
$ git status --short
$ git stash
No local changes to save
```
<!-- /snippet -->

The edit is hidden from status and diff, and also from `git add` and `git stash`, the commands you would use to save it. Then a teammate's change to the same file arrives:

<!-- snippet: ch05/assume-skip/03-assume-unchanged-breaks -->
```text
# The teammate changed the same file. Git checks the real file before overwriting it.
$ git merge teammate
error: Your local changes to the following files would be overwritten by merge:
	config/settings.yaml
Please commit your changes or stash them before you merge.
Aborting
Updating b52b27b..0fac3ad
[exit status: 1]
$ git status
On branch main
nothing to commit, working tree clean
# A clean status and a refused merge at the same time. And restore silently discards the edit:
$ git restore config/settings.yaml
$ cat config/settings.yaml
model: small-v1
api_base: https://llm.internal.example
$ git update-index --no-assume-unchanged config/settings.yaml
```
<!-- /snippet -->

A refused merge and a clean status at the same time. Then 🔴 `git restore` replaced the edit with the index version, silently. `--skip-worktree` fails differently and no better:

<!-- snippet: ch05/assume-skip/04-skip-worktree -->
```text
$ git update-index --skip-worktree config/settings.yaml
$ git ls-files -v
S config/settings.yaml
H src/app.py
# The same private edit again.
$ git status --short
$ git add config/settings.yaml
The following paths and/or pathspecs matched paths that exist
outside of your sparse-checkout definition, so will not be
updated in the index:
config/settings.yaml
hint: If you intend to update such entries, try one of the following:
hint: * Use the --sparse option.
hint: * Disable or modify the sparsity rules.
hint: Disable this message with "git config set advice.updateSparsePath false"
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch05/assume-skip/05-skip-worktree-breaks -->
```text
$ git merge teammate
error: Your local changes to the following files would be overwritten by merge:
	config/settings.yaml
Please commit your changes or stash them before you merge.
Aborting
Updating b52b27b..0fac3ad
[exit status: 1]
$ git restore config/settings.yaml
error: pathspec 'config/settings.yaml' did not match any file(s) known to git
[exit status: 1]
$ git status --short
```
<!-- /snippet -->

```text
Observed behavior : git status says "nothing to commit, working tree clean". git merge stops
                    with "Your local changes to the following files would be overwritten".
Git state         : The entry of config/settings.yaml has the assume-unchanged bit (git ls-files
                    -v prints "h"). The file on disk differs from the entry.
Mechanism         : Commands that list changes skip flagged entries. A command that must replace
                    the file checks the real file first, finds the edit and stops.
Root cause        : The bit was used to hide a local edit. It is a promise that there is none.
Why Git does this : It cannot know whether a local change is precious, so it "has to take the
                    safe route and always preserve them" (gitfaq).
Correct fix       : Clear the bit (--no-assume-unchanged, --no-skip-worktree), then commit,
                    stash or discard the edit in the open.
Prevention        : Private settings in a separate, ignored file. Find leftover bits with
                    git ls-files -v | grep -e '^[a-z]' -e '^S'
```

> **Unverified.** Do not read "refused" in the table above as a guarantee. Git decides whether a flagged file still matches its entry from the stat data cached in the index (size and timestamps), not by reading the file every time. Two exercise authors each saw, once, a merge or pull overwrite a hidden edit that had the same size as the committed file and was made within the same second; the run could not be reproduced on demand (four further attempts on Git 2.55.0 for this pass were all refused), so no transcript is shown. See the note in [the Module 17 solutions](../solutions/exercises-m16-m18.md), exercise 17.8. The refusal is a best effort that depends on the cached stat data, which is one more reason not to hide edits behind either bit.

**In production.** The arrangement that works is the one the FAQ recommends: shared defaults in a tracked file, private overrides in an ignored file that no commit on any branch has ever tracked (Chapter 4, section 4.16), and an application that reads both.

<!-- snippet: ch05/assume-skip/07-the-arrangement-that-works -->
```text
# Keep the shared defaults tracked. Put private overrides in a file that no commit has ever tracked.
$ echo 'config/settings.local.yaml' >> .gitignore
$ git add .gitignore
$ git commit -m "Ignore the per-developer settings override"
[main ce22e5e] Ignore the per-developer settings override
 1 file changed, 1 insertion(+)
 create mode 100644 .gitignore
$ echo 'api_base: http://localhost:8080' > config/settings.local.yaml
$ git status --short --ignored
!! config/settings.local.yaml
# The teammate change to the tracked defaults now merges, and the private file is untouched.
$ git merge teammate
Merge made by the 'ort' strategy.
 config/settings.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat config/settings.yaml config/settings.local.yaml
model: small-v2
api_base: https://llm.internal.example
api_base: http://localhost:8080
```
<!-- /snippet -->

## 5.13 Index stages during a conflict

**In one sentence.** When a merge cannot decide the content of a path, the index holds up to three entries for it, at stages 1, 2 and 3, and resolving the conflict means replacing them with one entry at stage 0.

**Precisely.** "During a merge, stage 1 is the common ancestor, stage 2 is the target branch's version (typically the current branch), and stage 3 is the version from the branch which is being merged" ([gitrevisions](https://git-scm.com/docs/gitrevisions)). `:<n>:<path>` names the blob at stage n.

**See it.** Two branches changed the same line:

<!-- snippet: ch05/conflict-stages/02-conflict -->
```text
$ git merge tune-retrieval
Auto-merging config/settings.yaml
CONFLICT (content): Merge conflict in config/settings.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UU config/settings.yaml
$ git ls-files --stage
100644 4da99e38a05a2a7b436aaea17b946e0288949413 1	config/settings.yaml
100644 9b521fd0f699b5fd45c7618b4e7560d00cc24088 2	config/settings.yaml
100644 2e6bc1476312458dcdd5e7eacf04942211ccb27f 3	config/settings.yaml
```
<!-- /snippet -->

<!-- snippet: ch05/conflict-stages/03-read-the-stages -->
```text
# Stage 1: the merge base. Stage 2: the current branch. Stage 3: the branch being merged.
$ git show :1:config/settings.yaml
model: small-v1
top_k: 5
$ git show :2:config/settings.yaml
model: small-v1
top_k: 3
$ git show :3:config/settings.yaml
model: small-v1
top_k: 8
$ cat config/settings.yaml
model: small-v1
<<<<<<< HEAD
top_k: 3
=======
top_k: 8
>>>>>>> tune-retrieval
```
<!-- /snippet -->

<!-- snippet: ch05/conflict-stages/04-resolve -->
```text
# Resolve: write the content you want, then "git add" replaces the three entries with one.
$ printf 'model: small-v1\ntop_k: 8\n' > config/settings.yaml
$ git add config/settings.yaml
$ git ls-files --stage
100644 2e6bc1476312458dcdd5e7eacf04942211ccb27f 0	config/settings.yaml
$ git status --short
M  config/settings.yaml
$ git commit -m "Merge tune-retrieval: keep top_k at 8"
[main 531d34d] Merge tune-retrieval: keep top_k at 8
```
<!-- /snippet -->

One path, three entries, three blob IDs. Each stage can be read as a complete file while the working tree holds the version with markers. `git add` replaced the three entries with one at stage 0.

Take two facts into Chapter 8 (Merge). An index with unmerged entries cannot be written out as a tree, so `git commit` refuses until every path is back at stage 0. And `git add` does not judge a resolution: it stages the file as it is, conflict markers included if you left them in.

## 5.14 The cached stat data

**In one sentence.** Each index entry remembers the size and timestamps that the file had when Git last saw it match the entry, so "has this file changed?" normally costs one `lstat` call instead of reading and hashing the file.

**Analogy.** A librarian who checks whether a book was touched by looking at the dust on it instead of rereading it. Disturbed dust only means that the book must be reread. The analogy breaks at one point: Git knows when dust can lie, an edit that keeps the size and lands in the same timestamp tick as the index write, and rereads then.

**Precisely.** In Git's own words, "the index entries record the information obtained from the filesystem via `lstat(2)` system call when they were last updated", and the comparison uses the modification and change times, size, inode, owner, group, file type and executable bit ([racy-git](https://github.com/git/git/blob/v2.56.0/Documentation/technical/racy-git.adoc)). Matching data mean "unchanged". A mismatch means "possibly changed": plumbing commands report the path as changed, while porcelain commands first *refresh* the index, that is, re-read the file and, when the content still equals the blob, store the new stat data.

**See it.**

<!-- snippet: ch05/stat-cache/01-entry -->
```text
# The stat fields are your machine and your clock, so this transcript masks their values with N.
$ git ls-files --debug src/app.py | sed -E '/time|dev|uid/s/[0-9]+/N/g'
src/app.py
  ctime: N:N
  mtime: N:N
  dev: N	ino: N
  uid: N	gid: N
  size: 38	flags: 0
# size is the length of the file on disk. Here it equals the size of the blob.
$ git cat-file -s :src/app.py
38
```
<!-- /snippet -->

<!-- snippet: ch05/stat-cache/02-touch -->
```text
# Change the modification time of the file. The content stays the same.
$ touch -t 202001010000 src/app.py
# Plumbing compares stat data only, and reports the entry as possibly changed.
$ git diff-files
:100644 100644 63df51b788f2464137e0f30355056e42a320f705 0000000000000000000000000000000000000000 M	src/app.py
```
<!-- /snippet -->

<!-- snippet: ch05/stat-cache/03-refresh -->
```text
# Porcelain re-reads the file, finds the same content, and stores the new stat data.
$ git status --short
$ git diff-files
```
<!-- /snippet -->

After `touch`, the plumbing command `git diff-files` reports `M`; the all-zero ID on the right is its notation for a working tree file that is "out of sync with the index" ([git-diff-files](https://git-scm.com/docs/git-diff-files)). `git status` printed nothing: it re-read the file, found the same content and wrote the new stat data back, so the second `git diff-files` is silent as well. 🟢 `git update-index --refresh` does the same on request and names the files that have a real change:

<!-- snippet: ch05/stat-cache/05-real-change -->
```text
# A real edit: refresh cannot make this entry match, and says so.
$ echo 'TOP_K = 10' > src/retriever.py
$ git update-index --refresh
src/retriever.py: needs update
[exit status: 1]
$ git diff-files
:100644 100644 1e0b1ade696068e087656f8ae5e859fe92aef3b8 0000000000000000000000000000000000000000 M	src/retriever.py
```
<!-- /snippet -->

**In production.** Speed: a clean working tree costs about one `lstat` call per tracked file and no file reads, and after anything that gives the files new timestamps or inodes, the next command hashes them all once. Correctness: a script that asks plumbing must refresh first.

<!-- snippet: ch05/dirty-check-in-scripts/01-false-positive -->
```text
# A release script asks plumbing: does anything differ from HEAD? Exit status 0 means no.
$ git diff-index --quiet HEAD
[exit status: 0]
# Copy the repository, as a build context or a restored CI cache does. No file content changes.
$ cp -R ../support-bot ../build-copy
$ cd ../build-copy
$ git diff-index --quiet HEAD
[exit status: 1]
$ git diff-files --name-status
M	config/settings.yaml
M	src/app.py
```
<!-- /snippet -->

<!-- snippet: ch05/dirty-check-in-scripts/02-refresh-first -->
```text
# Refresh: re-read the files whose stat data differ, and store the new stat data when the content matches.
$ git update-index -q --refresh
$ git diff-index --quiet HEAD
[exit status: 0]
$ git diff-files --name-status
```
<!-- /snippet -->

A copy of a clean repository is "dirty" to `git diff-index --quiet HEAD` until the index is refreshed. This is one way in which a release build of an unchanged commit gets labelled dirty inside a container or after a cache restore. Run `git update-index -q --refresh` before plumbing checks, or use `git status --porcelain`.

## 5.15 The index file in operation: the lock, and a rebuild

**In one sentence.** Every writer creates `.git/index.lock`, writes a complete new index into it and renames it over `.git/index`; a leftover lock therefore blocks all writers, and a damaged index can be discarded and rebuilt from HEAD at the price of whatever was only staged.

**Precisely.** Git's lock-file code states the protocol: the `.lock` file is created "with `O_CREAT|O_EXCL` so that we can notice and fail if somebody else has already locked the file", and exit and signal handlers remove it ([lockfile.h](https://github.com/git/git/blob/v2.56.0/lockfile.h)). A lock without a process therefore means a crash, a `kill -9` or a power loss. A lock with a live process is normal: an editor, a hook, another terminal.

**See it.**

<!-- snippet: ch05/index-lock-and-rebuild/01-lock -->
```text
# Imitate a Git process that died while it was writing the index.
$ touch .git/index.lock
$ echo 'TOP_K = 8' > src/retriever.py
$ git add src/retriever.py
fatal: Unable to create '$LAB/ch05/index-lock-and-rebuild/support-bot/.git/index.lock': File exists.

Another git process seems to be running in this repository, or the lock file may be stale
[exit status: 128]
# Reading still works. Only writers need the lock.
$ git status --short
 M src/retriever.py
# After checking that no Git process is running, remove the stale lock.
$ rm .git/index.lock
$ git add src/retriever.py
$ git status --short
M  src/retriever.py
```
<!-- /snippet -->

Readers work and writers fail. Before you remove a lock 🟡, check that no Git process is running (`pgrep -fl git`).

<!-- snippet: ch05/index-lock-and-rebuild/02-corrupt -->
```text
# One staged change (retriever.py) and one unstaged change (settings.yaml) exist.
$ echo 'temperature: 0.2' >> config/settings.yaml
$ git status --short
 M config/settings.yaml
M  src/retriever.py
# Now the index file is damaged.
$ printf 'garbage' > .git/index
$ git status
fatal: .git/index: index file smaller than expected
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch05/index-lock-and-rebuild/03-rebuild -->
```text
# Delete the damaged file. With no index, every path in HEAD looks deleted and every file looks new.
$ rm .git/index
$ git status --short
D  config/settings.yaml
D  src/app.py
D  src/retriever.py
?? config/
?? src/
# Rebuild the index from HEAD. A mixed reset writes the index and leaves the working tree alone.
$ git reset
Unstaged changes after reset:
M	config/settings.yaml
M	src/retriever.py
$ git status --short
 M config/settings.yaml
 M src/retriever.py
```
<!-- /snippet -->

<!-- snippet: ch05/index-lock-and-rebuild/04-what-was-lost -->
```text
# The files are intact. What is gone is the knowledge of which change was staged.
$ git diff --stat
 config/settings.yaml | 1 +
 src/retriever.py     | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git fsck
dangling blob 5fac60c5a32ec062dcb2163acd05c4c1c20dda0c
```
<!-- /snippet -->

Without an index, every path of HEAD looks like a staged deletion and every file looks untracked. 🟡 `git reset` wrote a new index from HEAD and left the files alone. What is lost is the knowledge of what was staged (both changes are unstaged now), together with any intent-to-add entries and the bits of section 5.12. The blob that was staged for `retriever.py` is still in the object database: `git fsck` lists it as dangling. Do not rebuild during a merge, because the conflict stages exist only in the index.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git reset` (no path, no commit) | unchanged | rewritten from HEAD's tree; staging state and flag bits gone | unchanged | unchanged | `ORIG_HEAD` written; the HEAD reflog gains an entry | unchanged | unchanged |
| `git update-index --[no-]assume-unchanged`, `--[no-]skip-worktree` | unchanged | one flag bit of the entry | unchanged | unchanged | unchanged | unchanged | unchanged |

**In production.** The lock message in CI usually means two Git processes in one working tree. Background tools should run `git --no-optional-locks status`, or set `GIT_OPTIONAL_LOCKS=0`, so that their optional refresh of the index never takes the lock ([git-status](https://git-scm.com/docs/git-status), "Background refresh").

## 5.16 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| The commit lacks your latest edit | Still modified after the commit (section 5.3) | `git add`, then a new commit or `--amend` | `git diff --cached` before every commit |
| The commit contains a line you left out with `-p` | It was made with `-a` or with a path | `git reset HEAD~1` if private, stage again, plain `git commit` (Lab 2.2) | No `-a`, no path after partial staging |
| A new file is missing from the commit | `git status` shows `??` | `git add`, commit | `git add -N` when you create a file |
| A commit deleted a file you meant to unstage | `git show --stat HEAD` says "delete mode" (section 5.9) | `git restore --source=HEAD~1 --staged <path>`, commit (Lab 2.4) | Unstage with `git restore --staged` |
| Clean status, yet a merge refuses to overwrite local changes | `git ls-files -v` shows `h` or `S` | Clear the bit; commit, stash or discard the edit | Never hide edits with the bits |
| "Unable to create ... index.lock" | `pgrep -fl git` | Wait, or remove a stale lock | `--no-optional-locks` for background tools |
| "index file smaller than expected" | `git status`, `git diff` and `git fsck` fail; `git log` works | `rm .git/index`, `git reset`, stage again | None |
| A script reports a dirty tree in a fresh copy | `git diff-files` lists every file, `git status` none | `git update-index -q --refresh` | Refresh before plumbing checks |
| A staged version is gone after unstaging | `git fsck` lists dangling blobs | `git cat-file -p <id> > <path>` (Lab 2.1) | Commit early |

## 5.17 When not to use it, and dangerous edge cases

**A hunk edit can stage content that exists nowhere.** Take the hunk of section 5.5 again and stage only the `top_k` change: turn `-temperature` into a context line and delete two `+` lines.

<!-- snippet: ch05/add-patch-edit/04-edit-one-of-two -->
```text
# Start again. This time stage only the top_k change.
$ git restore --staged config/settings.yaml
# In the editor: turn "-temperature: 0.7" into a context line, delete "+temperature: 0.2" and "+debug: true".
$ git add -p
diff --git a/config/settings.yaml b/config/settings.yaml
index bfcfe5c..d56fa8e 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1,4 +1,5 @@
 model: small-v1
-top_k: 5
-temperature: 0.7
+top_k: 8
+temperature: 0.2
+debug: true
 max_tokens: 512
(1/1) Stage this hunk [y,n,q,a,d,e,p,P,?]? e
--- the hunk as saved (comment lines left out) ---
@@ -1,4 +1,5 @@
 model: small-v1
-top_k: 5
 temperature: 0.7
+top_k: 8
 max_tokens: 512
```
<!-- /snippet -->

<!-- snippet: ch05/add-patch-edit/05-order-changed -->
```text
# The staged file. Compare the order of its lines with HEAD and with the working tree.
$ git show :config/settings.yaml
model: small-v1
temperature: 0.7
top_k: 8
max_tokens: 512
$ git show HEAD:config/settings.yaml
model: small-v1
top_k: 5
temperature: 0.7
max_tokens: 512
$ cat config/settings.yaml
model: small-v1
top_k: 8
temperature: 0.2
debug: true
max_tokens: 512
```
<!-- /snippet -->

The patch applied. But in the saved hunk the context line `temperature: 0.7` stands before `+top_k: 8`, so the staged file has the two keys in an order that neither HEAD nor the working tree has. For YAML keys that is harmless. For two statements of a program it is behavior that no file on disk ever had. In the editor, move the `+` line up to its `-` line, and after every `e` read `git diff --cached`.

**Do not stage partially what cannot stand alone.** If the accepted hunks do not build without the rejected ones, that commit is broken in history although your working tree works, and `git bisect` (Chapter 14A, History investigation) will stop on it one day.

**The index is not storage.** A blob that only the index refers to becomes unreachable the moment its entry changes, and garbage collection prunes unreachable loose objects after two weeks by default. Work you want to keep belongs in a commit, on a throwaway branch if need be.

**The two bits in team documentation.** A README that tells every developer to run `--skip-worktree` on a config file creates state that no clone and no CI image reproduces, and it fails at the next upstream change to that file.

**When staging adds nothing.** One finished change in an otherwise clean working tree: `git commit -a` after reading `git status` is fine. The index earns its keep when the working tree holds more than one change.

## 5.18 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git diff`, `git ls-files`, `git diff-files`, `git diff-index`, `git write-tree`, `git update-index --refresh`, `git checkout-index --prefix=<dir>/` | 🟢 SAFE | Nothing, or only tree objects, cached stat data, files below `<dir>` | not needed | not needed |
| `git add` in all its forms | 🟢 SAFE | Blobs and index entries; replaces what was staged for those paths | `git add -n`; `-p` shows each hunk | `git restore --staged <path>` |
| `git commit -a`, `git commit <path>` | 🟢 SAFE | Index, a new commit, the branch ref | `--dry-run` | `git reset HEAD~1` 🟡 while the commit is private (Chapter 11) |
| `git restore --staged <path>`, `git reset [<path>]` | 🟡 CAUTION | Index entries copied from HEAD | `git diff --cached` | `git add` again; `git fsck` if the file has changed since |
| `git rm --cached <path>` | 🟡 CAUTION | Removes the entry: a deletion if HEAD has the path | `git rm --cached -n` | `git restore --staged <path>` |
| `git update-index --assume-unchanged`, `--skip-worktree` | 🟡 CAUTION | A flag bit that hides later edits | `git ls-files -v` | the `--no-` forms |
| `rm .git/index.lock` | 🟡 CAUTION | Removes a lock; unsafe while a Git process is writing | `pgrep -fl git` | none needed for a stale lock |
| `rm .git/index`, then `git reset` | 🔴 DANGEROUS | Discards staging state, flag bits, conflict stages, outside Git's locking. What it can destroy: the record of what was staged and not committed, which no reflog holds | `git diff --cached`; move the file aside instead of deleting it | `git fsck` for blobs that were staged; move the file back. Appropriate only for a corrupt index (section 5.15) |
| `git restore <path>` on a file with the assume-unchanged bit | 🔴 DANGEROUS | Overwrites the hidden edit without warning | clear the bit, then `git diff` | none (Chapter 4, section 4.7 answers the five questions) |

## 5.19 Version notes

> **Version note.** Older behavior: `git add -u` and `git add -A` without a pathspec covered only the current directory, and `git add <path>` ignored removed files. Current behavior: both cover the whole working tree, and `git add <path>` records removals. Since: Git 2.0 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.0.0.adoc)). Recommended: `git add -u .` to stay in the current directory.

> **Version note.** Older behavior: a path added with `git add -N` appeared in `git diff` as a change to an empty file, and an index holding only such paths let `git commit` create an empty commit. Current behavior: `git diff` shows a new file, and the commit is refused (section 5.6). Since: Git 2.19 for the diff and 2.11 for the commit ([2.19](https://github.com/git/git/blob/master/Documentation/RelNotes/2.19.0.adoc), [2.11](https://github.com/git/git/blob/master/Documentation/RelNotes/2.11.0.adoc)). Recommended: nothing to change.

> **Version note.** Older behavior: none; the features did not exist. Current behavior: as shown above. Since: `git add -p` 1.5.4; `git add -N` and `--staged` 1.6.1 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/1.6.1.adoc)); `git restore --staged` 2.23 (Chapter 4, section 4.18); `git ls-files --format` 2.38. Recommended: write `restore --staged`, read `reset HEAD`; only `--format` needs a version check.

## 5.20 Practice

- Labs 2.1 (the three-trees prediction table), 2.2 (partial staging) and 2.4 (unstage three ways) in the [Module 2 lab manual](../lab-manual/m02-working-tree-index-head.md). Lab 2.3 there belongs to [Chapter 4](ch04-working-tree.md).
- Replay any transcript with `labs/run ch05/<demo>`, for example `labs/run ch05/add-patch-edit`. The sandbox stays in place for your own experiments.
- Three drills, each in a sandbox left by a replay:
  1. In `ch05/three-diffs`, predict the three diffs after `git add src/retriever.py`, then run them.
  2. In `ch05/add-patch-edit`, repeat the second edit by hand and place `+top_k: 8` so that the staged order is right.
  3. In `ch05/stat-cache`, run `git ls-files --debug` before and after `git status` on a touched file and say which field changed.

## 5.21 Interview questions

1. What is in the index when nothing is staged? Prove it with two commands.
2. A file shows `MM` in `git status --short`. Which three versions exist, where is each stored, and which one does `git commit` record?
3. What exactly does `git add` write, and what remains of it after `git restore --staged`? Does a push send it?
4. `git diff HEAD` prints nothing. Can `git commit` still create a non-empty commit? Construct the case.
5. You staged half of a file with `git add -p`, using `e` where `s` was not offered. Why is that commit riskier than a normal one, what can `e` get wrong, and how do you test what you are about to commit?
6. Compare `git restore --staged`, `git reset <path>` and `git rm --cached` for a path that HEAD has, for a path that HEAD lacks, and in a repository without commits.
7. A developer ran `git commit -a` after careful partial staging. What did the commit contain, and what is the lowest-risk fix before and after a push?
8. Why are `--assume-unchanged` and `--skip-worktree` not ways to ignore local changes? What do you recommend to a team that needs per-developer settings?
9. `git status` is clean, and `git diff-index --quiet HEAD` in the release script exits with 1. Explain the mechanism and fix the script.
10. One CI job fails because `.git/index.lock` exists, another because the index file is corrupt. For each: diagnosis, fix, and what is lost.

## 5.22 Sources

**Primary sources**

- [git-add](https://git-scm.com/docs/git-add), [git-diff](https://git-scm.com/docs/git-diff), [git-commit](https://git-scm.com/docs/git-commit), [git-restore](https://git-scm.com/docs/git-restore), [git-reset](https://git-scm.com/docs/git-reset), [git-rm](https://git-scm.com/docs/git-rm), [git-ls-files](https://git-scm.com/docs/git-ls-files), [git-update-index](https://git-scm.com/docs/git-update-index), [git-checkout-index](https://git-scm.com/docs/git-checkout-index), [git-write-tree](https://git-scm.com/docs/git-write-tree), [git-diff-files](https://git-scm.com/docs/git-diff-files), [git-status](https://git-scm.com/docs/git-status). The local copies (`git help -m <command>`) are the Git 2.55.0 text used for the transcripts.
- [gitdatamodel](https://git-scm.com/docs/gitdatamodel), [gitformat-index](https://git-scm.com/docs/gitformat-index), [gitrevisions](https://git-scm.com/docs/gitrevisions) and [gitfaq](https://git-scm.com/docs/gitfaq) ("How do I ignore changes to a tracked file?").
- [racy-git](https://github.com/git/git/blob/v2.56.0/Documentation/technical/racy-git.adoc): the cached stat data and its one known weakness. [lockfile.h](https://github.com/git/git/blob/v2.56.0/lockfile.h): the lock-file protocol.
- Release notes [2.0.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.0.0.adoc), [1.6.1](https://github.com/git/git/blob/master/Documentation/RelNotes/1.6.1.adoc), [2.11.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.11.0.adoc), [2.19.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.19.0.adoc); 1.5.4 and 2.38.0 as shipped with Git 2.55.0.

**Secondary sources**

- Pro Git, [Interactive Staging](https://git-scm.com/book/en/v2/Git-Tools-Interactive-Staging). Caveat: its prompt and its `git stash save --patch` come from an older Git.
- Pro Git, [Reset Demystified](https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified): the three trees, with the index as "your proposed next commit". Caveat: it says "working directory" for the working tree.
- The Phase 0 report of this course, sections 11 and 12: the Stack Overflow figure and the survey of ten beginner resources (outline-based; transcripts were not reviewed).

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- [Lecture 5: Version Control and Git](https://www.youtube.com/watch?v=9K8lB61dl3Y), MIT Missing Semester 2026: the staging area as part of the data model; the [notes](https://missing.csail.mit.edu/2026/version-control/) list `add -p`. Caveats: describes object IDs as SHA-1 only; the demo starts on `master`.
- [Git for Professionals](https://www.youtube.com/watch?v=Uszj_k0DGsg), Tobias Günther for freeCodeCamp, September 2021: commit craft with `git add -p`. Caveat: 2021 interface.

**Further reading**

- [git-sparse-checkout](https://git-scm.com/docs/git-sparse-checkout), the feature that the skip-worktree bit was built for.
