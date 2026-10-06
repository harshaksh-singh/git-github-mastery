# V003: A first repository, read file by file

- **Part.** 0: Orientation
- **Module.** 0
- **Planned minutes.** 22
- **Prerequisites.** V002
- **Textbook sections.** [Chapter 1: Fundamentals](../../textbook/ch01-fundamentals.md), section 1.9
- **Demo scripts.** `labs/ch01/first-repo.sh`, `labs/ch01/lab-00-2-empty-git-dir.sh`

## HOOK

**[ON SCREEN]** An editor window with a saved file, and beside it a red build.

You edit a file. You save it. Your editor shows the new line, your local test passes, and the build server, the shared machine that builds and tests the team's code, fails as if you had done nothing.

Here's the fact behind that failure. A build server checks out a commit, one saved snapshot of the project. It never sees your working tree, and it never sees your index. Both get defined in a minute. For now: a change that was edited but not added, or added but not committed, doesn't exist for anyone else, however real it looks in your editor.

**[PAUSE]**

So there are places a change can be, and "saved" is only the first of them. In this video you watch one file travel through all of them, and after every step you look inside the dot git folder to see what moved. Keep that red build in mind. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Most people learn `git init`, `git add` and `git commit` as three words to type. You're going to learn them as three sets of files that appear on disk.

We create a repository for a small evaluation harness called `rag-eval`. A repository is the place where a project's recorded history is kept. After every step we list the files in the dot git folder. The listings leave out the sample hooks, example scripts that never change.

Nothing here is hidden. The dot git folder is a directory of ordinary files, and by the end of this video you'll have seen every file that a first commit creates. We won't open the objects themselves today. That's video 7, which starts from this same commit.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Predict which files appear under `.git` after `git init`, after `git add` and after `git commit`.
2. Read the output of `git status` in the four states of the guided repository.
3. Show that a commit moved the branch ref and that HEAD still names the branch.
4. Count the objects that a first and a second commit create.

## CONCEPT

**`git init` creates a directory, not a connection.** Recall the last video: the whole repository is the dot git directory at the top of your project. `git init` creates that directory. It contacts no server, creates no account and asks no permission, because Git has none of those things.

**[ANIMATION]** trees: file=configs/eval.yaml names=Working_tree,Index,Repository ref=main commits=f7c044e,2da8d74 title=One_file,_three_places

**One file, three places.** A file you work on can be in three places, and the three commands of this video move it between them.

**[ANIMATION]** step: edit

The first place is the working tree: the files you see and edit. Editing files is invisible to Git until you tell it.

The second place is the index, also called the staging area. It's one file, named index, inside the dot git folder, and it's the list of what the next commit will contain.

The third place is the repository proper: the objects in the objects folder and the names in the refs folder, both inside dot git. On screen the third box shows the last commit, which Git finds through a name called HEAD.

**[ANIMATION]** end

**[ANIMATION]** step: add

**What `git add` writes.** `git add` does two things. It stores the content of the file as an object, one stored piece of data. And it records in the index which content belongs to which path. No commit exists after `git add`.

**[ANIMATION]** end

**[ANIMATION]** step: commit

**What `git commit` writes.** `git commit` records the index. It writes the objects that describe the directories, called trees, and one commit object. Then it moves the current branch to that commit and writes a line in each of two journals, the reflogs.

**The mechanism of "being on a branch".** A branch is a name that points at a commit. HEAD names a branch, and the branch names a commit. That's the whole mechanism. A commit moves the current branch, and HEAD follows only because it names that branch.

**The risk labels.** All three commands carry the label 🟢 SAFE in the textbook's command-safety table. `git init` creates the dot git folder, and in an existing repository it only adds missing template files. `git add` stores content as objects and points index entries at it. `git commit` adds tree and commit objects, moves the current branch, and appends to the reflogs. Each one only adds.

## MENTAL MODEL

**[ANIMATION]** step: commit

Picture three boxes in a row: working tree, index, repository. A file starts in the left box. `git add` copies its content to the middle box. `git commit` records the middle box into the right box.

Notice the word "copies". After `git add`, the content is in the working tree and in the index. After `git commit`, it's in all three. Nothing leaves a box when it enters the next one.

**[ANIMATION]** end

Where does this model stop being enough? It tells you where content is, and it says nothing yet about how the right-hand box is organized: what a commit is made of, and why a second commit doesn't store an unchanged file again. You'll see that the object count hints at an answer. The full answer is Part 1.

## DIAGRAM

**[DIAGRAM]** First the strip of three boxes, empty. During the demo, a marker for `configs/eval.yaml` moves across it.

```text
  Working tree              Index                     Repository
 +-------------------+     +-------------------+     +-------------------+
 |                   | add |                   | commit                  |
 |  edit a file here | --> |  the next commit  | --> |  objects and refs |
 +-------------------+     +-------------------+     +-------------------+
```

**[DIAGRAM]** After the demo, the diagram of section 1.9: the state after the second commit, with the abbreviated IDs from the transcript.

```text
  Working tree              Index (.git/index)              Repository (.git/objects, .git/refs)
 +-------------------+     +---------------------------+   +----------------------------------+
 | README.md         |     | README.md         3a79082 |   |  f7c044e <--- 2da8d74            |
 | configs/eval.yaml |     | configs/eval.yaml 327cd0b |   |                  ^               |
 +-------------------+     +---------------------------+   |  refs/heads/main      HEAD: main |
          |     git add          ^      |    git commit    +----------------------------------+
          +----------------------+      +-----------------------------^
```

Build it from the left. The working tree holds two files. The index lists the same two paths, each with the ID of its content. The repository holds two commits, and the arrow between them points from the newer commit back to the older one. `refs/heads/main` points at the newer commit, and HEAD says `main`. The two arrows underneath are the two commands: `git add` carries content from the working tree to the index, and `git commit` records the index in the repository.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch01/first-repo.sh`. Split layout: the three-box strip on the left.

Replay it yourself with:

```bash
labs/run ch01/first-repo
```

The IDs on my screen equal the IDs in section 1.9 of the book, because replays use the fixed clock.

**Step 1: `git init`** 🟢 SAFE.

Predict: after `git init`, does a branch exist? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch01/first-repo/01-init -->
```text
$ git init rag-eval
Initialized empty Git repository in $LAB/ch01/first-repo/rag-eval/.git/
$ cd rag-eval
$ ls -1F .git
config
description
HEAD
hooks/
info/
objects/
refs/
$ cat .git/HEAD
ref: refs/heads/main
$ git status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```
<!-- /snippet -->

`git init` created the directory and, inside it, `.git`. Three entries matter now. `objects/` will hold every version of every file, and it's empty. `refs/` will hold branch and tag names, and it's empty too. `HEAD` says which branch you're on: `refs/heads/main`. No such file exists yet under `refs/`, and that's why `git status` says `No commits yet`. So: not yet. Git calls this an unborn branch. The name `main` comes from the lab configuration.

That's the first of four `git status` states: no commits, nothing to commit.

**Step 2: create files.**

The script creates `README.md` and `configs/eval.yaml`. Predict: what changes under `.git`?

<!-- snippet: ch01/first-repo/02-untracked -->
```text
$ echo '# rag-eval' > README.md
$ mkdir configs
$ printf 'model: small-v2\ntimeout_s: 60\n' > configs/eval.yaml
$ find .git -type f -not -path '.git/hooks/*' | sort
.git/config
.git/description
.git/HEAD
.git/info/exclude
$ git status
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	README.md
	configs/

nothing added to commit but untracked files present (use "git add" to track)
```
<!-- /snippet -->

Nothing changed. `.git` holds the same four files as before. Two files exist in the working tree, and `git status` calls them untracked. Notice that it shows `configs/` as one line, because nothing inside that directory is tracked. Second status state: untracked files.

Try it now, on paper. Draw the three boxes: working tree, index, repository. Put a mark for `configs/eval.yaml` in every box that holds its content right now. Thirty seconds, then check your answer.

**[PAUSE]**

One mark, in the left box. The file is saved, and Git hasn't been told. If you marked more, that's the natural guess.

**[DIAGRAM]** The marker sits in the left box only.

**Step 3: `git add`** 🟢 SAFE.

Now the question I asked you to hold: what will change under `.git` when we add the two files? How many new files, and where?

**[PAUSE]**

<!-- snippet: ch01/first-repo/03-add -->
```text
$ git add README.md configs/eval.yaml
$ find .git -type f -not -path '.git/hooks/*' | sort
.git/config
.git/description
.git/HEAD
.git/index
.git/info/exclude
.git/objects/3a/79082bc80505c7543e79c4312e3e3d276a0e04
.git/objects/42/2e9c0c59f64154ed466adcfb7b7b7c0d43e89f
$ git ls-files --stage
100644 3a79082bc80505c7543e79c4312e3e3d276a0e04 0	README.md
100644 422e9c0c59f64154ed466adcfb7b7b7c0d43e89f 0	configs/eval.yaml
$ git status
On branch main

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
	new file:   README.md
	new file:   configs/eval.yaml
```
<!-- /snippet -->

Three files are new. `.git/index` is the index. The two files under `objects/` hold the contents of `README.md` and `configs/eval.yaml`. Each object is named by a 40-digit ID, split into a two-digit directory and a 38-digit file name. Read the first one: directory `3a`, then the rest.

`git ls-files --stage` prints the index: file mode, object ID, stage number, path. Look at the IDs: `3a79082` for `README.md`, `422e9c0` for `configs/eval.yaml`. They're the names of the two object files above. So `git add` did two things: it stored the content, and it recorded which content belongs to which path.

Third status state: "Changes to be committed". And still `No commits yet`.

**[DIAGRAM]** The marker is now in the left and middle boxes.

**Step 4: `git commit`** 🟢 SAFE.

Same question. What will change under `.git`? Think about objects, about `refs/`, and about anything else.

**[PAUSE]**

<!-- snippet: ch01/first-repo/04-commit -->
```text
$ git commit -m "Add README and evaluation config"
[main (root-commit) f7c044e] Add README and evaluation config
 2 files changed, 3 insertions(+)
 create mode 100644 README.md
 create mode 100644 configs/eval.yaml
$ find .git -type f -not -path '.git/hooks/*' | sort
.git/COMMIT_EDITMSG
.git/config
.git/description
.git/HEAD
.git/index
.git/info/exclude
.git/logs/HEAD
.git/logs/refs/heads/main
.git/objects/0d/722fc2a87c4b61afef355250e6e77f41a44cd0
.git/objects/3a/79082bc80505c7543e79c4312e3e3d276a0e04
.git/objects/42/2e9c0c59f64154ed466adcfb7b7b7c0d43e89f
.git/objects/e6/21cb090a7d826cce2a614885f534bde7015533
.git/objects/f7/c044e2033a8967176ac7d6b5c18e17042ea1cf
.git/refs/heads/main
```
<!-- /snippet -->

Read the first line of the output: `[main (root-commit) f7c044e]`. On branch `main`, a commit without a parent, whose ID starts with `f7c044e`.

Seven files are new. Three are objects: the commit, in directory `f7`. A tree for the top directory, in `e6`. And a tree for `configs/`, in `0d`. A tree is Git's record of one directory. Then `refs/heads/main`: the branch now exists. Then `logs/HEAD` and `logs/refs/heads/main`: the reflogs, journals of where HEAD and `main` have pointed. And `COMMIT_EDITMSG`: the text of the last commit message.

<!-- snippet: ch01/first-repo/05-after-commit -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ cat .git/refs/heads/main
f7c044e2033a8967176ac7d6b5c18e17042ea1cf
$ git log
commit f7c044e2033a8967176ac7d6b5c18e17042ea1cf
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:16:00 2026 +0530

    Add README and evaluation config
$ git status
On branch main
nothing to commit, working tree clean
```
<!-- /snippet -->

`HEAD` still contains the branch name. The branch file contains the commit ID. `git status` compares that commit, the index and the working tree, finds them identical, and reports a clean working tree. Fourth status state.

**[DIAGRAM]** The marker is in all three boxes.

**Step 5: a second commit.**

The script appends one line to `configs/eval.yaml`. Before it stages anything, look at `git status` and `git diff`.

<!-- snippet: ch01/first-repo/06-second-commit -->
```text
$ echo 'top_k: 5' >> configs/eval.yaml
$ git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   configs/eval.yaml

no changes added to commit (use "git add" and/or "git commit -a")
$ git diff
diff --git a/configs/eval.yaml b/configs/eval.yaml
index 422e9c0..327cd0b 100644
--- a/configs/eval.yaml
+++ b/configs/eval.yaml
@@ -1,2 +1,3 @@
 model: small-v2
 timeout_s: 60
+top_k: 5
$ git add configs/eval.yaml
$ git commit -m "Add top_k to evaluation config"
[main 2da8d74] Add top_k to evaluation config
 1 file changed, 1 insertion(+)
$ git log --oneline
2da8d74 Add top_k to evaluation config
f7c044e Add README and evaluation config
```
<!-- /snippet -->

After the edit, `git status` lists the file under "Changes not staged for commit": the working tree differs from the index, and `git diff` shows that difference, the one added line `top_k: 5`. `git add` copies the new content into the index, and `git commit` records the index. The log now has two commits, `2da8d74` on top of `f7c044e`.

**[ANIMATION]** trees: setup, edit, add, commit file=configs/eval.yaml names=Working_tree,Index,Repository ref=main commits=f7c044e,2da8d74 title=One_file,_three_places say_commit=commit_records_the_index_as_a_new_snapshot

Here's that step in the three boxes. The edit changes only the working tree. The add copies it into the index. The commit records it, and all three agree again.

**[ANIMATION]** end

Now the prediction that this whole video was built for, as a quiz with two options. HEAD is a file. `refs/heads/main` is a file. We committed a second time. Option one: HEAD changed. Option two: the branch file changed. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch01/first-repo/07-ref-moved -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ cat .git/refs/heads/main
2da8d743d511369d13dcc318644c8c1ba33eea28
$ cat .git/logs/HEAD
0000000000000000000000000000000000000000 f7c044e2033a8967176ac7d6b5c18e17042ea1cf Lab User <you@example.com> 1788756360 +0530	commit (initial): Add README and evaluation config
f7c044e2033a8967176ac7d6b5c18e17042ea1cf 2da8d743d511369d13dcc318644c8c1ba33eea28 Lab User <you@example.com> 1788756960 +0530	commit: Add top_k to evaluation config
$ find .git/objects -type f | wc -l
       9
```
<!-- /snippet -->

Option two. `HEAD` did not change. The branch file did: it now holds the ID that begins `2da8d74`. In the picture the label `main` moved to the new commit, and HEAD went with it. The file `HEAD` still names `main`, because HEAD follows the branch by name. `logs/HEAD` has one line per movement: old ID, new ID, who, when, and why. The first old ID is all zeros because nothing came before.

And the count: nine objects. Five from the first commit and four from the second, namely one new file content, two new trees because `configs/` and the top directory both changed, and the commit. `README.md` was not stored a second time. Keep that observation. Video 7 explains it.

**[ANIMATION]** graph: f7c044e-2da8d74 main; HEAD=main

As a picture: two commits. The label `main` points at the newer one, and HEAD names `main`.

**[TERMINAL]** Caption bar: `labs/ch01/lab-00-2-empty-git-dir.sh`.

One more replay, to read an empty `.git` in full. This is the first part of Lab 0.2.

```bash
labs/run ch01/lab-00-2-empty-git-dir
```

<!-- snippet: ch01/lab-00-2-empty-git-dir/01-init -->
```text
$ git init tour
Initialized empty Git repository in $LAB/ch01/lab-00-2-empty-git-dir/tour/.git/
$ cd tour
$ find .git -type d | sort
.git
.git/hooks
.git/info
.git/objects
.git/objects/info
.git/objects/pack
.git/refs
.git/refs/heads
.git/refs/tags
$ find .git -type f | sort
.git/config
.git/description
.git/HEAD
.git/hooks/applypatch-msg.sample
.git/hooks/commit-msg.sample
.git/hooks/fsmonitor-watchman.sample
.git/hooks/post-update.sample
.git/hooks/pre-applypatch.sample
.git/hooks/pre-commit.sample
.git/hooks/pre-merge-commit.sample
.git/hooks/pre-push.sample
.git/hooks/pre-rebase.sample
.git/hooks/pre-receive.sample
.git/hooks/prepare-commit-msg.sample
.git/hooks/push-to-checkout.sample
.git/hooks/sendemail-validate.sample
.git/hooks/update.sample
.git/info/exclude
```
<!-- /snippet -->

This time nothing is left out: the directories, then every file, including the sample hooks.

<!-- snippet: ch01/lab-00-2-empty-git-dir/02-read -->
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
$ head -n 8 .git/hooks/pre-commit.sample
#!/bin/sh
#
# An example hook script to verify what is about to be committed.
# Called by "git commit" with no arguments.  The hook should
# exit with non-zero status after issuing an appropriate message if
# it wants to stop the commit.
#
# To enable this hook, rename this file to "pre-commit".
```
<!-- /snippet -->

Read them out loud. `HEAD`: one line, the name of a branch. `config`: the repository's own settings. `description`: a line of text. `info/exclude`: comments only. And a sample hook, which says in its own comment how it would be enabled. I stop the replay here. The rest of the lab removes these files one group at a time, to find out which of them Git can't live without. That experiment is yours.

## COMMON MISTAKES

Five mistakes to watch for.

1. **`git commit` records nothing, or records a commit that lacks a file.** Root cause: `git commit` records the index, and the change was never added to it.
2. **Believing that saving a file changes the repository.** Root cause: editing files is invisible to Git until `git add`; `.git` held the same four files before and after the edit.
3. **Expecting HEAD to hold the new commit ID after a commit.** Root cause: HEAD names the branch; the commit moves the branch file, and HEAD follows only through that name.
4. **Running `git init` in the wrong place.** Root cause: `git init` creates `.git` wherever it runs; in your home directory it turns everything you own into one working tree, so give it a directory argument.
5. **Expecting your hand-typed IDs to match the book.** Root cause: in `labs/shell` the clock is real, and the commit ID depends on the time.

## PRODUCTION EXAMPLE

Now, out of the lab. A backend engineer changes a retry limit in two places: a configuration file and a constant in the code. She stages the configuration file, commits, and pushes. Locally everything passes, because her test reads the working tree, where both edits exist. The build server checks out the commit, where only one exists. Her report says "the fix is committed", and by the meaning of the three boxes that's half true: one file reached the right-hand box, and the other is still in the left-hand one. That's the red build from the start of this video. Video 6 works this case from report to prevention.

## PRACTICE EXERCISE

Your turn. Do Lab 0.2, "Read every file in an empty `.git`", in [`lab-manual/m00-lab-setup.md`](../../lab-manual/m00-lab-setup.md), by hand in `labs/shell m00`.

Predict before the failure scenario: of `hooks/`, `info/`, `description`, `config`, `refs/`, `objects/` and `HEAD`, which can be taken away while `git status` still works, and which can't? Write your list first. Then run the lab and compare.

## INTERVIEW QUESTION

Q14: "What makes a directory a Git repository? Which files in a fresh `.git` can you delete without breaking it?"

Answer out loud, after you've done the lab. A strong answer is based on the experiment and not on a guess. It names what Git looks for when it decides whether a directory is a repository, separates what came from a template from what Git depends on, and says how you would restore what is missing.

## RECAP

Let's land this. You should now be able to say: `git init` creates a `.git` directory with a `HEAD` that names an unborn branch, and nothing else of substance. Editing a file changes nothing under `.git`. `git add` writes the content as an object and writes the index. `git commit` writes tree and commit objects, creates or moves the branch ref, and appends to the reflogs.

**[ANIMATION]** step: state-1

HEAD names a branch and the branch names a commit, so a commit moves the branch and HEAD stays as it was.

## HOMEWORK

- Read section 1.9 of [Chapter 1](../../textbook/ch01-fundamentals.md).
- Repeat the guided repository by hand in `labs/shell m00`, and compare your object count with the book. Explain why your IDs differ. Predict before you look: which of your object IDs will equal the book's, and which will not?
- Challenge: Exercise 1.4, Level 2, "how many objects?", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Three commands, and you've now seen every file they write. Do Lab 0.2 before the next video. Next time: the root cause framework. Until then, look at the state first and type second. See you in the next one.
