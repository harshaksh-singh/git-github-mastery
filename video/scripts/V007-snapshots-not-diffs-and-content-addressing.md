# V007: Snapshots, not diffs, and content addressing

- **Part.** 1: Foundations
- **Module.** 1
- **Planned minutes.** 24
- **Prerequisites.** V003
- **Textbook sections.** [Chapter 2: The Mental Model](../../textbook/ch02-mental-model.md), sections 2.1 to 2.4
- **Demo scripts.** `labs/ch01/first-repo.sh` (snippet `08-open-objects`), `labs/ch02/snapshots.sh`, `labs/ch02/content-ids.sh`

## HOOK

**[ON SCREEN]** A line from a report: "Numbers produced at commit `2e76f67`."

An evaluation report from three weeks ago says its numbers were produced "at commit `2e76f67`". Today the numbers are disputed, and your CTO asks two questions.

What does that ID pin down: one file, one change, or the whole project?

And could anything behind that ID have been altered since then, by accident or on purpose?

**[PAUSE]**

No command answers those. A model does: what Git stores, and how it names what it stores. With the model, each answer is one sentence. The ID pins down every byte of every tracked file, the complete history before it, and who recorded it when. And nothing behind the ID can change without the ID changing. This video is where you earn the right to say those two sentences.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair: this is Part 1. In Part 0 you watched files appear in the objects folder, inside the dot git folder, and you didn't open them. Today you open them.

Two ideas carry this video. The first: a commit is a snapshot of the whole project, not a record of what changed. Hold on to that word, snapshot. In a few minutes it explains why a second commit didn't store `README.md` again. The second: every object is named by a hash of its own content, which is called content addressing. Together they also explain why the IDs on my screen equal the IDs in your book, and why "Git stores diffs" is false as a statement about storage.

I'll say this once for the whole part, because you'll want to compare: the commit IDs on screen are read from replays with the fixed clock, so they equal the IDs in the textbook.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Open the first commit of the guided repository and name the object behind the commit, its tree and its files.
2. Show with object IDs that two commits share the blob of an unchanged file.
3. Explain why a diff is computed on demand and is stored nowhere.
4. Predict whether the same content gets the same object ID in two unrelated repositories, and say why.

## CONCEPT

**Start from what you have.** Back in video 3, five files appeared in that objects folder when you made the first commit of `rag-eval`. Each file is one object, and two commands open them. `git cat-file -t` prints the type of an object. `git cat-file -p` prints its content in readable form. Both are 🟢 SAFE: they change nothing.

**[ANIMATION]** objects: commits=916dec3,2e76f67 trees=f3b0ea8,4798110 files=config.yaml:e09e51f>f72ae75,judge_prompt.txt:f5970a3,metrics.py:652e0e2 messages=Add_scorer,Raise_temperature

**[ANIMATION]** step: blobs

When you open those five, you find three kinds. A commit, which contains no file name and no file content: one tree line, the author and the committer with their times, and the message. A tree, which is one directory at that moment: each entry has a mode, the type and ID of an object, and a name. And a blob, an object that holds file content and nothing else. No name, no date.

Git's manual counts four kinds of data in a repository. Objects: immutable commits, trees, blobs and tag objects, named by their IDs. References, or refs: names for object IDs. The index: the next commit, as a flat list of paths. And reflogs: a local journal of the values each ref has had. The working tree is a fifth thing, and it isn't repository data.

**Snapshots, not diffs.** In one sentence: a commit records the complete state of every tracked file at one moment, as the ID of one tree. It doesn't record what changed.

**[ANIMATION]** step: second-commit

Now precisely. The official data model lists what a commit must contain: the directory structure and file contents of that version, stored as the ID of the top-level tree. The IDs of its parent commits. An author and a committer, each with a time. And a message. It states that Git stores no diff for a commit, and that `git show` calculates one from the parent when you ask.

**[ANIMATION]** step: shared

So how can full snapshots be cheap? Because a file whose content didn't change isn't stored again. The new tree lists the ID of the blob that already exists.

**[ANIMATION]** hash: differs=byte

**Content addressing.** In one sentence: an object's ID is a hash of the object's type and content. So identical content has the identical ID in every repository on every machine, and different content has, for all practical purposes, a different ID.

Precisely. The manual defines the ID, also called the object name, as a cryptographic hash of the object's type and contents. With the default hash, SHA-1, an ID has 40 hexadecimal digits, and commands accept and print unique prefixes.

Here's the key: what is hashed decides what an ID identifies.

**[ON SCREEN]** The three-row table of section 2.4.

For a blob, the bytes of the file are hashed. Not its name, not its mode, not any time. So a blob ID identifies one exact file content, wherever it occurs.

For a tree: for each entry, the mode, the name and the object ID. So a tree ID identifies one exact directory state, including everything below it.

For a commit: the tree ID, the parent IDs, the author, the committer, both times, and the message. So a commit ID identifies one project state, the whole history behind it, and who recorded it when.

Four properties follow. Deduplication: equal content is stored once, whatever its path, commit or branch. Immutability: an object can't be edited, because other content is another object with another ID. So "changing a commit" always means creating a new one. Integrity: Git can recompute the hash of whatever it reads, so corruption and tampering are detectable. And cheap comparison: two files, directories or project states are equal when their IDs are equal, and merge and diff skip everything whose IDs match.

If that felt fast, here it is in one sentence: the name of a thing is computed from the thing.

**Where this model stops.** The model says "full snapshots". Later, Git may pack objects into packfiles and store some of them as differences against similar objects. That's compression below the model: `git cat-file -p` returns the full content either way. And there's a real weak point. Every version of a 2 gigabyte model file is a new 2 gigabyte blob. That's the subject of the Git LFS chapter.

## MENTAL MODEL

**[ANIMATION]** step: shared

Two pictures now. The textbook's analogy for snapshots: a photograph of the whole whiteboard after every meeting, instead of a list of what was wiped and written. Each photograph can be read on its own, and any two can be compared. It breaks in one place: an album stores every photograph in full, while Git stores each distinct file content once and lets every snapshot that contains it refer to that object.

**[ANIMATION]** hash: differs=parcel

The analogy for content addressing: a warehouse that shelves each parcel at an address computed from its content. Two warehouses in different cities put identical parcels at identical addresses without ever talking to each other, and an altered parcel no longer belongs at its address. It breaks because nobody finds a parcel by guessing its content. You need a catalogue from names to addresses, and in Git that catalogue is the trees and the refs.

**[ANIMATION]** end

Put the two together and you have the sentence to keep: a commit is a photograph whose address is computed from what is in it.

## DIAGRAM

Let's put real IDs on that photograph.

**[ANIMATION]** step: compare

**[DIAGRAM]** The diagram of section 2.3. Draw the left commit and its tree, then the right commit and its tree, then mark the shared rows.

```text
 commit 916dec3 <-------------------- commit 2e76f67          (arrow: the parent link)
      |                                    |
      v                                    v
 tree f3b0ea8                         tree 4798110
   config.yaml       e09e51f            config.yaml       f72ae75    new blob
   judge_prompt.txt  f5970a3            judge_prompt.txt  f5970a3    same object
   metrics.py        652e0e2            metrics.py        652e0e2    same object
```

Two commits. The arrow between them is the parent link, and it points from the newer commit back to the older one. Each commit has its own tree. Now read the rows. `config.yaml` has a different ID on the right: a new blob. `judge_prompt.txt` and `metrics.py` have the same IDs on both sides. Not equal copies. The same object, listed by two trees.

**[DIAGRAM]** The hash chain of section 2.4, as a function box.

```text
 blob ID   = hash(file content)
 tree ID   = hash(names, modes, IDs of the blobs and trees in the directory)
 commit ID = hash(tree ID, parent commit IDs, author, committer, times, message)

 one byte changes in one file
   -> new blob ID -> new ID for every tree above it -> new commit ID
   -> new ID for every commit that is later built on that commit
```

Each ID is computed from the IDs below it, so one changed byte changes every ID above it. Feed the function two inputs that differ in one byte, and the two outputs have nothing in common. You'll see that in the terminal in a moment.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch01/first-repo.sh`, snippet `08-open-objects`.

We start where video 3 stopped: the first commit of `rag-eval`, `f7c044e`. Predict: does the commit object contain the file names?

**[PAUSE]**

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

The commit `f7c044e` has no file name in it: a `tree` line, author, committer, message. Now the third command: the commit ID, a caret, and the word tree in curly braces. That notation means "the tree of this commit", and it prints the top directory, tree `e621cb0`. In it, `README.md` is a blob, and `configs` is another tree. A commit, a colon, then a path means "the object at this path in this commit". So the tree `0d722fc` is the configs directory, with one blob for `eval.yaml`. And the blob `422e9c0` is the content of that file and nothing else. Five objects, connected only by the IDs they contain.

**[TERMINAL]** Caption bar: `labs/ch02/snapshots.sh`.

```bash
labs/run ch02/snapshots
```

A scorer with three files is committed. `git ls-tree` prints the tree of a commit.

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

Three files, three blob IDs. Now one file changes, `config.yaml`, and it's committed again. `git commit -a` first stages every tracked file that was modified or deleted. Predict, and remember the word snapshot: the second commit is a full snapshot of three files. How many of the three blob IDs will be new? Say it out loud. I'll wait.

**[PAUSE]**

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

Compare the two listings. `judge_prompt.txt` and `metrics.py` have the same blob IDs in both commits, `f5970a3` and `652e0e2`. Only `config.yaml` has a new one, `f72ae75` instead of `e09e51f`. The second snapshot is complete, and it needed one new blob.

Count everything.

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

`git cat-file --batch-all-objects --batch-check` lists every object with its type and its size in bytes. Two commits, two trees and four blobs, where six blobs would be needed if nothing were shared.

That also answers the question video 3 left open. Here the second commit added three object files: the new blob, the new top-level tree, and the commit. In Chapter 1 the second commit added four, because the changed file was in a subdirectory, so the tree of the configs directory and the top-level tree both changed. `README.md` wasn't stored again. That's your snapshot, paid off.

Now look for the diff. If Git stored diffs, the second commit is where one would be hiding.

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

A tree, a parent, two identities with times, and a message. No diff. So where does this come from?

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

The diff that `git show` prints is computed when you ask for it. Look at the line that starts with `index`: `e09e51f`, two dots, `f72ae75`. It names the two blobs that Git compared. Those are the two `config.yaml` IDs from the tree listings.

**[TERMINAL]** Caption bar: `labs/ch02/content-ids.sh`.

```bash
labs/run ch02/content-ids
```

`git hash-object` computes the ID that a file's content has as a blob. First, outside any repository. Predict: the same line hashed twice, then with one character changed.

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

The same bytes give the same ID twice, `b5fee68`. One changed character, `0.2` to `0.3`, gives an unrelated ID. And no repository exists here, so the ID can't depend on one.

Next: two repositories, and two different file names with the same bytes. With `-w`, `git hash-object` also stores the object. That form is 🟢 SAFE, because it only adds an object. Remember the two warehouses. Same ID, or different?

**[PAUSE]**

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

The same ID, in both. Both repositories hold an object file at the same path: the first two digits of the ID name a directory, the other 38 the file. Neither file name is recorded in it.

So where do names go? Into trees. `git write-tree`, also 🟢 SAFE, writes the index as a tree and prints its ID.

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

With different file names, the two trees differ. Then the script renames the file in `server`, so that both repositories contain the same directory state. `git add -A` stages the removal of the old name together with the new file. And now the tree IDs are equal: `097da7e`. Two repositories that have never exchanged a byte agree on the name of a directory state.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Saying "Git stores diffs".** Root cause: the output of `git show` was taken for the content of the commit; the commit holds a tree ID, and the diff is calculated from the parent on request.
2. **Believing a full snapshot per commit must be expensive.** Root cause: forgetting deduplication; a file whose content did not change is the same blob, listed again by the new tree.
3. **Two files look identical and have different IDs.** Root cause: they differ in bytes you cannot see, such as a carriage return; `cmp`, `od -c` and `git hash-object` on both show it.
4. **Quoting an abbreviated ID in a report or a script.** Root cause: an abbreviation is unique only in one repository at one time, and can become ambiguous as the repository grows; write all 40 digits.
5. **Expecting hand-typed commits to have the book's commit IDs when the files are identical.** Root cause: the same files committed one second later give the same tree ID and a different commit ID, because the times are hashed.

## PRODUCTION EXAMPLE

Now, out of the lab. A backend team rolls back a bad release, and someone asks: "Are we sure every file is back to the last good state?" Nobody compares files. After the rollback, `git rev-parse 'HEAD^{tree}'` prints the tree ID of the last good commit, and that proves that every tracked file is back in that state. One ID, and the on-call engineer gets their Friday evening back.

The cost side, from the textbook. In a repository of 40,000 files, an edit to two files in the ranker directory under services writes two blobs, three trees, namely ranker, services and the top directory, and one commit. A commit costs what changed, not what exists. And any commit can be checked out, built or compared on its own. No chain of patches is replayed.

## PRACTICE EXERCISE

Your turn. Do Lab 1.2, "Snapshots share unchanged blobs", in [`lab-manual/m01-what-git-is.md`](../../lab-manual/m01-what-git-is.md), by hand in the lab shell.

Before each commit in the lab, predict two numbers: how many objects the commit will add, and how many of the blob IDs in its tree you've already seen. Then list the objects and check.

## INTERVIEW QUESTION

Q16: "A commit changes one file out of 5,000, three directories deep. How many objects does it create, and of which types?"

Answer out loud, and derive the number. Don't recite it. A strong answer walks from the changed file upward, says which objects have to be new and why, says which are reused, and mentions the one object that every commit adds. And if you can also say what would make your count wrong, you understand the rule and not only the example.

## RECAP

**[ANIMATION]** objects: commits=916dec3,2e76f67 trees=f3b0ea8,4798110 files=config.yaml:e09e51f>f72ae75,judge_prompt.txt:f5970a3,metrics.py:652e0e2 messages=Add_scorer,Raise_temperature title=The_whole_model_in_one_picture

Let's land this. You should now be able to say: a commit records the whole project as the ID of one tree, with its parents, author, committer and message. It contains no diff. `git show` computes one from the parent. An unchanged file is the same blob, referenced again, so a commit costs what changed. An object's ID is a hash of its type and content, so the same content has the same ID in every repository, and one changed byte changes the blob ID, every tree ID above it, and the commit ID. That gives me deduplication, immutability, integrity and cheap comparison.

And that disputed report? You can now answer both of the CTO's questions, one sentence each.

## HOMEWORK

- Read sections 2.1 to 2.4 of [Chapter 2](../../textbook/ch02-mental-model.md).
- Do Lab 1.3, "Same content, same ID, in two repositories", in [`lab-manual/m01-what-git-is.md`](../../lab-manual/m01-what-git-is.md).
- Challenge: Exercise 1.7, Level 3, "the same files, two different commit IDs", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

If today felt abstract in places, that's normal. You opened Git's objects and read them yourself. Next time: all four object types, and a commit built by hand. Until then, look at the state first and type second. See you in the next one.
