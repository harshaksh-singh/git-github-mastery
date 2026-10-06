# V015: The index: the proposed next commit, and what git add writes

- **Part.** 1: Foundations
- **Module.** 2
- **Planned minutes.** 22
- **Prerequisites.** V008, V011
- **Textbook sections.** [Chapter 5: The Index](../../textbook/ch05-index.md), sections 5.1 to 5.3
- **Demo scripts.** `labs/ch05/index-is-snapshot.sh`, `labs/ch05/add-writes.sh`, `labs/ch05/add-leaves-a-blob.sh`

## HOOK

**[ON SCREEN]** "You ran the tests, they passed, you committed. CI ran that commit and failed on the line you had fixed. Which of the two is wrong?"

Your CTO asks: "You ran the tests, they passed, you committed. CI ran that commit and failed on the line you had fixed. Which of the two is wrong?"

Neither. They tested different things. The commit contained what was in the index, and your tests ran against something else: the files on disk.

**[PAUSE]**

Git does not build a commit from your files. It builds it from the index, a second complete record of the project that sits between the working tree and HEAD. Understanding usually stops at this layer. The textbook notes that "How do I undo 'git add' before commit?" is the fifth most-voted Git question on Stack Overflow, with 11,626 votes on 1 October 2026, and that none of the ten popular beginner resources surveyed for this course teaches the index as a data structure. We will.

## INTRODUCTION

The next four videos take the index apart. This one establishes what it is and what `git add` does to it.

Hold on to one idea, and I will repeat it: the index is not a list of changes. It is a full snapshot. Everything that confuses people about staging follows from getting that sentence wrong, and everything in these four videos follows from getting it right.

## LEARNING OBJECTIVES

After this video you can:

1. Describe the index as a flat list of paths with blob IDs, and prove that it equals HEAD's tree when nothing is staged.
2. Name the two things `git add` writes.
3. Show that staging is a snapshot of the file at the moment of `git add`.
4. Explain what remains in the repository after a staged file is unstaged.

## CONCEPT

**In one sentence.** The index is a single file, `.git/index`, that lists every tracked path together with the ID of a blob, and `git commit` turns exactly that list into the tree of the new commit.

**Precisely.** Git's data-model document says: "The index, also known as the 'staging area', is a list of files and the contents of each file, stored as a blob". And: "Unlike a tree, the index is a flat list of files. When you commit, Git converts the list of files in the index to a directory tree and uses that tree in the new commit".

Each entry has four fields: the file type and mode, the blob ID, a stage number, which is 0 except during a conflict, and the full path. Mode, blob ID and path are what the commit's tree receives. Each entry also carries bookkeeping that never leaves your machine: cached filesystem data, and flag bits. V018 opens both. The old name "cache" survives in options such as `--cached`.

**The correction.** The definition corrects the most common wrong model. Nothing in the index is a "change". "Staged changes" are the result of comparing the index with HEAD. And an index with nothing staged is not empty: it describes the same tree as HEAD.

**Inside `.git`.** One binary file, created by the first `git add`: a 12-byte header, the entries sorted by path, optional extensions, and a checksum.

**What `git add` writes.** In one sentence: `git add <path>` stores the current content of the file as a blob in the object database, and writes that blob's ID into the path's index entry. It is a copy taken at that moment, not a subscription to the file.

The manual: "It only adds the content of the specified file(s) at the time the add command is run; if you want subsequent changes included in the next commit, then you must run `git add` again".

Two things are written: one object, unless an identical blob already exists, and one index entry. No ref moves, so no reflog records an add. `git add` is 🟢 SAFE: it writes a blob and an index entry.

**[ON SCREEN]** The state table for `git add <path>`: working tree unchanged; index entry created or updated, and what was staged for the path before is replaced; HEAD and refs unchanged; one new blob if the content is new; remote and GitHub unchanged.

**The root cause from the hook.** A fix that was tested but is missing from the commit was edited after the last `git add`. The commit is written from the index, which still held the earlier version. Status showed `MM`. Add the file again and commit, and read `git diff --cached` before every commit.

**What an add leaves behind.** Unstaging removes the entry, not the object. The blob that `git add` wrote stays in the object database as a dangling blob. A push does not send it: a push sends what the pushed commits need, and no commit refers to this object. Garbage collection removes the stray object once it is older than `gc.pruneExpire`, two weeks by default. Until then it is also a rescue route: content that was staged once and then lost can be found with `git fsck`.

**Where this matters and where it does not.** This is not something to "use" or "not use"; it is how every commit is made. The practical rule is about trust: "What exactly will be in this commit?" has one authoritative answer, the index. Reviewers, CI and every clone receive the tree that was written from it, never your working tree.

## MENTAL MODEL

The textbook's analogy: the packing list for the next shipment. It names every item that will be in the box, not the items that differ from the last box, and the warehouse ships what the list says even if the shelf has changed since.

Use it on the hook. You changed the item on the shelf after you wrote the list. The warehouse shipped what the list said.

The analogy breaks in two places. Writing a line on this list also puts a copy of the item into storage at that moment; that is the blob. And during a conflict, the list can carry three candidate lines for one item; that is for V018 and Part 2.

## DIAGRAM

**[DIAGRAM]** The diagram of section 5.2. Draw the flat list on the left, then the arrow, then the nested trees on the right.

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

On the left, four lines: mode, blob ID, stage, full path. A flat list, sorted by path. On the right, the same information as tree objects: a top-level tree with one blob and two subtrees. The blob IDs on the left are the blob IDs on the right. The arrow is `git commit`, or `git write-tree`: Git converts the flat list into a directory tree. Nothing on either side is a change.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch05/index-is-snapshot.sh`.

```bash
labs/run ch05/index-is-snapshot
```

`git ls-files --stage` prints the four fields of every entry. The repository is clean: nothing is staged. Predict: how many lines does the index have?

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

Four lines with full paths, although nothing is staged. HEAD's tree has three entries, two of them trees; flattened with `git ls-tree -r`, it gives the same four modes, blob IDs and paths.

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

The file itself: the signature `DIRC`, the format version, and the entry count, four.

`git write-tree` 🟢 SAFE does on request what `git commit` does every time: it writes the index out as tree objects and prints the ID of the top one. Predict how that ID relates to the tree of HEAD.

**[PAUSE]**

<!-- snippet: ch05/index-is-snapshot/03-index-equals-head -->
```text
# Write the index out as a tree object. With nothing staged it is the tree HEAD already has.
$ git write-tree
676700b510b47ab35c5d2aa71977f80d234cdcbc
$ git rev-parse HEAD^{tree}
676700b510b47ab35c5d2aa71977f80d234cdcbc
```
<!-- /snippet -->

The same ID, `676700b`. That is the proof for objective one: with nothing staged, the index describes the tree HEAD already has.

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

Stage one change. One entry gets a new blob ID: `4da99e3` becomes `0217758`. The index now describes a different tree, and `git write-tree` prints its ID.

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

**[TERMINAL]** Caption bar: `labs/ch05/add-writes.sh`.

```bash
labs/run ch05/add-writes
```

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

The object list, then an edit. `git hash-object` computes the ID that the edited file would get. No such object exists yet. Predict what `git add` 🟢 SAFE changes in this list.

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

After the add there is a fifth object, a blob with the predicted ID, and the index entry names it. Two writes: one object, one entry.

Now the script edits the file again, without adding it. Predict what a commit made now would contain.

**[PAUSE]**

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

`MM` says that both comparisons of `git status` find a difference. `git show :config/settings.yaml` prints the staged blob, which lacks `debug: true`. The commit records that blob, and the file is still modified afterwards. That is the CTO's question, reproduced.

<!-- snippet: ch05/add-writes/04-same-content-same-blob -->
```text
# Adding content that the object database already holds creates no new object.
$ git cat-file --batch-all-objects --batch-check | grep -c blob
2
$ git show HEAD:config/settings.yaml > config/settings.staging.yaml
$ git add config/settings.staging.yaml
$ git ls-files --stage
100644 e4eb0e6d146a5b1eb62d3a52301f262836a0a224 0	config/settings.staging.yaml
100644 e4eb0e6d146a5b1eb62d3a52301f262836a0a224 0	config/settings.yaml
$ git cat-file --batch-all-objects --batch-check | grep -c blob
2
```
<!-- /snippet -->

And the "unless": adding content that the object database already holds creates no new object. Two index entries, one blob ID, and the blob count stays at two.

**[TERMINAL]** Caption bar: `labs/ch05/add-leaves-a-blob.sh`.

```bash
labs/run ch05/add-leaves-a-blob
```

A slip: `git add .` picks up an environment file. It is corrected at once with `git restore --staged`, which is 🟡 CAUTION: it changes an index entry, and files on disk stay.

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

Status is back to untracked. Predict: is the secret anywhere in `.git`?

<!-- snippet: ch05/add-leaves-a-blob/02-the-blob-is-still-there -->
```text
# The index entry is gone. The object that "git add" wrote is not.
$ git fsck
dangling blob 5620d7c0158994dedf8a5ff7d48b68e5479f513c
$ git cat-file -p 5620d7c
LLM_API_KEY=lab-secret-0001
```
<!-- /snippet -->

`git fsck` reports a dangling blob, `5620d7c`, an object that nothing refers to, and `git cat-file -p` prints the secret from it. The index entry is gone. The object that `git add` wrote is not. Has it left the machine?

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

No. The repository that received the push has the commit and not the blob.

**[ON SCREEN]** Lower third: **GitHub**. GitHub never sees your index. A push transfers commits and the objects they refer to, and everything GitHub shows or checks is derived from those.

## COMMON MISTAKES

1. **Thinking the index is a list of changes.** Root cause: "staged changes" is the result of comparing the index with HEAD; the index itself is a complete list of every tracked path.
2. **A fix that was tested is missing from the commit.** Root cause: the file was edited after the last `git add`, and the commit is written from the index.
3. **Believing an empty "Changes to be committed" means an empty index.** Root cause: with nothing staged, the index describes the same tree as HEAD.
4. **Assuming an unstaged secret left no trace.** Root cause: unstaging removes the entry, not the object; the blob remains until garbage collection.
5. **Panicking that the unstaged secret was pushed.** Root cause: forgetting what a push sends: the objects that the pushed commits need, and no commit refers to that blob.

## PRODUCTION EXAMPLE

An engineer on an LLM application team runs `git add .` and notices in the status output that a 2 GB checkpoint and an `.env` file were picked up. They unstage both immediately. Two questions follow, and the model answers both. Is there history to rewrite? No: a secret or a checkpoint that was added and then unstaged is in no commit and has not travelled. Is it still on the laptop? Yes, as a stray object, until garbage collection removes it once it is older than `gc.pruneExpire`, two weeks by default. The same fact works in your favour on a bad day: content that was staged once and then lost can be found with `git fsck`.

## PRACTICE EXERCISE

Do Lab 2.1, "The three-trees prediction table", in [`lab-manual/m02-working-tree-index-head.md`](../../lab-manual/m02-working-tree-index-head.md).

The lab is a prediction exercise by design. Fill in each row of the table, working tree, index and HEAD, before you run the step, and mark every cell you got wrong. Those cells show you which sentence of this video you have not yet absorbed.

## INTERVIEW QUESTION

Q27: "What exactly does `git add` write, and what remains of it after `git restore --staged`? Does a push send it?"

Answer aloud. A strong answer counts the writes and names where each lands, says which of them `git restore --staged` reverses and which it does not, and reasons about the push from the rule for what a push transfers. Say how long the leftover stays, and what removes it.

## RECAP

You should now be able to say: the index is one file that lists every tracked path with a mode and a blob ID, flat and sorted; it is a full snapshot, not a list of changes. With nothing staged it describes the same tree as HEAD, and I can prove that with `git write-tree`. `git add` writes a blob and an index entry, as a copy at that moment; later edits are not in it. `git commit` records the index and does not read the working tree. Unstaging removes the entry and leaves the blob, which no push sends and which garbage collection removes later.

## HOMEWORK

- Read sections 5.1 to 5.3 of [Chapter 5](../../textbook/ch05-index.md).
- Challenge: Exercise 2.4, Level 2, "what does the commit contain?", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
