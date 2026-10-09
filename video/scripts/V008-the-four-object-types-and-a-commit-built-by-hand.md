# V008: The four object types, and a commit built by hand

- **Part.** 1: Foundations
- **Module.** 1
- **Planned minutes.** 26
- **Prerequisites.** V007
- **Textbook sections.** [Chapter 2: The Mental Model](../../textbook/ch02-mental-model.md), sections 2.5 and 2.6
- **Demo scripts.** `labs/ch02/object-types.sh`, `labs/ch02/commit-by-hand.sh`

## HOOK

**[ON SCREEN]** `git log`: "fatal: your current branch 'main' does not have any commits yet".

A release script at your company builds a commit without a working tree, the folder of files you normally edit. It writes the objects, it prints a commit ID, and it exits with status zero, the usual sign of success. Then the next step runs `git log`, and Git says the branch doesn't have any commits yet.

The commit exists. You can print it by its ID. And no history shows it. How can both be true?

**[PAUSE]**

To explain that, you have to stop thinking of `git commit` as one act. It's five moves. When a Git command surprises you, the useful question is always the same: which objects did it write, and which refs did it move? A ref is a name that points at an object. Today you make a commit with your own hands, one move at a time, and you see exactly which move was missing in that script.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you saw three kinds of object: blob, tree and commit. A blob is the content of one file, a tree is one directory, and a commit is one saved snapshot. There's a fourth, the tag object, and this video opens one of each.

Then we put the porcelain away. Porcelain is Git's word for the everyday commands, such as `git add` and `git commit`. Plumbing is the low-level layer underneath, and five plumbing commands do the same work in separate, visible steps. We'll build a commit from nothing: no file in the working tree, no `git add`, no `git commit`. After each step I'll ask you which object or file is about to appear. And keep that release script in mind. It comes back.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Name the four object types, and say what each contains and what it points at.
2. Read a tree entry: mode, type, object ID, name.
3. Build a commit with plumbing only, without `git add` or `git commit`.
4. Explain which step of the hand-built commit corresponds to which porcelain command.

## CONCEPT

**The four object types.**

**[ON SCREEN]** The table of section 2.5, one row at a time.

A blob holds the bytes of one file. It refers to nothing. It is written by `git add`.

A tree holds one directory: for each entry, a mode, a name and an object ID. It refers to blobs and to other trees. It is written by `git commit`, from the index.

A commit holds one tree ID, the parent commit IDs, an author, a committer and a message. It refers to its tree and its parents. It is written by `git commit`, `git merge`, `git cherry-pick` and others.

A tag object holds the ID and type of another object, a tag name, the tagger, and a message. It refers, usually, to a commit. It is written by `git tag -a`.

**[ANIMATION]** objects: commits=916dec3,2e76f67 trees=f3b0ea8,4798110 files=config.yaml:e09e51f>f72ae75,judge_prompt.txt:f5970a3,metrics.py:652e0e2 messages=Add_scorer,Raise_temperature title=Names_live_in_trees

**[ANIMATION]** step: blobs

**Names live in trees.** A blob is content without a name. The name of a file is stored in the tree that lists it. On screen is the scorer from the last video: the tree holds the three names, and each name points at a blob. This is why, in the last video, two files with different names and the same bytes were one blob.

**Reading a tree entry.** Four fields: mode, type, object ID, name. The mode tells you the kind of entry.

**[ON SCREEN]** The mode table of section 2.5.

`100644` is a regular file. `100755` is an executable file. `120000` is a symbolic link. `040000` is a directory: the entry points at a tree. `160000` is a gitlink: a commit of another repository, which you met in video 6 as the embedded repository. Executable or not is the only permission that Git records. It stores no owner and no other permission bits.

**The tag object, and the tag without one.** An annotated tag is a ref that points at a tag object, and the tag object names a commit. A lightweight tag has no object: it is a ref that points at the commit directly. A later chapter develops tags.

**A commit in five moves.**

**[ON SCREEN]** The five-row table of section 2.6. Risk labels beside each command.

Step 1: `git hash-object -w` stores content as a blob. 🟢 SAFE. The porcelain that does it for you is `git add`.

Step 2: `git update-index --add --cacheinfo`, with a mode, an ID and a path, records in the index that this path has this content. 🟡 CAUTION: it changes one index entry. The porcelain is again `git add`. So `git add` is two moves.

Step 3: `git write-tree` writes the index as tree objects. 🟢 SAFE. The porcelain is `git commit`.

Step 4: `git commit-tree`, with a tree, optionally `-p` and a parent, and `-m` with a message, writes a commit object. 🟢 SAFE. The porcelain is `git commit`.

Step 5: `git update-ref refs/heads/<branch> <commit>` points the branch at the commit. 🟡 CAUTION: it moves one ref, and nothing else. The porcelain is `git commit`. So `git commit` is three moves.

Steps 1, 3 and 4 only add objects. No ref and no index entry changes, and garbage collection removes objects that nothing refers to. That's why they're green.

**What porcelain adds.** `git commit` does more than steps 3 to 5. It refuses to record nothing, as you saw in video 4. It runs hooks, the scripts a repository can run at moments such as a commit. And it writes a reason into the reflogs. `git update-ref` writes reflog lines for the branch and for HEAD without a message, unless you pass `-m`.

**When to use plumbing, and when not.** For daily work, don't. `git add`, `git commit`, `git switch` and `git branch` make the same objects and refs, and add checks. The read-only plumbing, `git cat-file`, `git ls-tree`, `git rev-parse`, `git for-each-ref` and `git merge-base`, is always appropriate, and settles arguments about state fastest. And know the limits of the writing plumbing: `git update-ref` verifies little. It refuses a blob as the value of a branch and a stale expected value, but it accepts any existing commit, and it never looks at the index or the working tree.

**Recovery.** The plumbing is worth knowing because recovery uses the same tools. A commit found by `git fsck` or in a reflog is reattached with one ref.

## MENTAL MODEL

**[ANIMATION]** step: blobs

Think of the objects as documents in a filing system. A blob is a page with no title. A tree is a table of contents: titles, and where each page or sub-table is filed. A commit is a cover sheet: "the project is this table of contents; it follows that earlier cover sheet; signed by this author and this committer, with this note". A tag object is a labelled note that points at a cover sheet.

**[ANIMATION]** step: second-commit

The model breaks at one point that matters: in a filing system you could pull a page and correct it. Here you can't. Every one of these documents is filed under a number computed from its content. So a corrected page is a second, different page with a different number, and every table of contents and cover sheet that should include it must be written anew.

**[ANIMATION]** end

For the five moves: `git add` is "file the page and enter it in the draft table of contents". `git commit` is "write out the tables, write the cover sheet, and move the bookmark".

## DIAGRAM

**[DIAGRAM]** The diagram of section 2.5. Draw the commit, then its tree, then the three entries, then the tag object above.

```text
 refs/tags/v0.1.0 --> tag 0f7f193 --+
                                    v
 refs/heads/main ------------> commit e375b7b --> tree b5688c9 --+--> blob 895d61e  README.md
                                                                 +--> tree 08dd0d9  scripts --> blob aa1a031  test.sh
                                                                 +--> tree 95722c3  src ------> blob 572a34a  rerank.py
```

All eight objects, and the two names that lead to them. The branch `main` points at the commit. The commit points at one tree. The tree has three entries: a blob and two more trees, each with a blob. And from the top left, the ref `v0.1.0` points at the tag object, which points at the same commit.

**[ANIMATION]** walk: columns=step,plumbing,what_appears,porcelain rows=1:git_hash-object_-w:one_blob:git_add|2:git_update-index_--add_--cacheinfo:.git/index,_one_entry:git_add|3:git_write-tree:one_tree_per_directory:git_commit|4:git_commit-tree_<tree>_-m_<message>:one_commit,_no_ref:git_commit|5:git_update-ref_refs/heads/<branch>_<id>:the_branch_ref:git_commit title=A_commit_in_five_moves

**[DIAGRAM]** A five-rung ladder for the hand-built commit, with the porcelain beside each rung. One rung lights up per demo step.

```text
 step  plumbing                                   what appears                porcelain
 ----  -----------------------------------------  --------------------------  ----------
  1    git hash-object -w                         one blob                    git add
  2    git update-index --add --cacheinfo         .git/index, one entry       git add
  3    git write-tree                             one tree per directory      git commit
  4    git commit-tree <tree> -m <message>        one commit, no ref          git commit
  5    git update-ref refs/heads/<branch> <id>    the branch ref              git commit
```

The five moves as a ladder: the plumbing command, what appears, and the porcelain that does it for you.

**[ANIMATION]** end

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch02/object-types.sh`.

```bash
labs/run ch02/object-types
```

A repository called `ranker`, with one commit and one annotated tag. First the inventory.

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

Eight objects: three blobs, three trees, one commit, one tag object. We open one of each.

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

A commit. This one has no `parent` line, so it's a root commit. The number after the email address, followed by `+0530`, is a time in Git's raw format: seconds since the first of January 1970 UTC, then the offset from UTC.

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

Trees. `git cat-file -p` prints one level of a tree. `git ls-tree -r` walks down and prints every file with its full path. Read one entry in four fields: `100755`, `blob`, the ID beginning `aa1a031`, `scripts/test.sh`. Mode `100755`: an executable file.

Try it now. Thirty seconds: find the `README.md` line and read it out loud in four fields. Then check your answer.

**[PAUSE]**

Mode `100644`, a regular file. Type `blob`. The ID beginning `895d61e`. And the name, `README.md`.

<!-- snippet: ch02/object-types/04-blob -->
```text
$ git cat-file -t HEAD:src/rerank.py
blob
$ git cat-file -p HEAD:src/rerank.py
def rerank(docs):
    return sorted(docs, key=len)
```
<!-- /snippet -->

A blob: two lines of Python and nothing else. The name `rerank.py` isn't in it. It's stored in the tree `95722c3`.

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

And the tag object, `0f7f193`. It names the commit `e375b7b` and its type, repeats the tag name, and adds a tagger and a message.

**[TERMINAL]** Caption bar: `labs/ch02/commit-by-hand.sh`. Split layout with the ladder.

```bash
labs/run ch02/commit-by-hand
```

A repository with no working-tree file at all. The content arrives through a pipe.

**Step 1.** `git hash-object -w` 🟢 SAFE. Predict: after this command, what exists under `.git/objects`, and does an index exist? Say it out loud. I'll wait.

**[PAUSE]**

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

One object exists, the blob `a7f6bbc`. There is no index yet.

**Step 2.** `git update-index --add --cacheinfo` 🟡 CAUTION. `--cacheinfo` takes a mode, a full object ID and a path. `--add` permits a path that the index does not have yet. Predict what `git status` will say about a path that is in the index, in no commit, and not on disk.

**[PAUSE]**

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

`git status` reports the path twice, and both lines are correct. "new file" compares the index with HEAD, which has no commit. "deleted" compares the working tree with the index, which lists a file that isn't on disk. Two comparisons, two answers. If that looked like a bug, you're in good company. Remember this picture for video 10.

**Step 3.** `git write-tree` 🟢 SAFE. The index holds one path, `prompts/system.txt`. Quick quiz: how many tree objects will it write? Option one: one. Option two: two. Say it out loud.

**[PAUSE]**

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

Two. The index is a flat list of full paths, and trees are nested, one object per directory. So `git write-tree` wrote `5445e77` for the top directory and `4015b7b` for `prompts/`.

**Step 4.** `git commit-tree` 🟢 SAFE. Predict: after this, will `git log` show the commit?

**[PAUSE]**

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

`git commit-tree` wrote the commit `cc0ef15`, with the author and the committer taken from the environment, as `git commit` does. And `git log` fails. HEAD names the branch `main`, and no ref `refs/heads/main` exists. `git fsck`, which checks the object database, calls the commit dangling: it exists, and nothing refers to it.

That's the release script from the hook. It stopped after step 4. The commit existed, and no name led to it.

**Step 5.** `git update-ref` 🟡 CAUTION, with the full name `refs/heads/main`.

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

One ref makes the difference: `git log` works and `git fsck` is silent. And `git status --short` prints ` D prompts/system.txt`: the commit and the index contain the file, the working tree doesn't. The commit exists, and the working tree is still empty.

**[TERMINAL]** Snippet `06-working-tree`.

The last step fills the working tree, and it uses a command with a red label, so the five questions come first. `git restore <path>` is 🔴 DANGEROUS. What it changes: it overwrites the file in the working tree from the index. What it can destroy: uncommitted edits in that file. How to preview: `git diff -- <path>` shows what would be overwritten. How to recover: there is no recovery for content that was never staged. When it's appropriate: when you've looked at that diff and want to discard it. Twig looks worried, and with a red label on screen, fairly so. Here, though, nothing can be lost, because no file exists.

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

The file is on disk, and the working tree is clean.

**[ON SCREEN]** The state table of section 2.6: five rows, with "unchanged" everywhere except one cell per row.

The state table of the five moves. `git hash-object -w`: one new blob. `git update-index`: one index entry. `git write-tree`: one tree per directory.

`git commit-tree`: one commit object, no ref, no reflog line.

`git update-ref`: the branch ref. Everything else is unchanged.

## COMMON MISTAKES

Five mistakes to watch for.

1. **A commit made with `git commit-tree` is not in `git log`.** Root cause: the commit object exists and no ref points at it; `git fsck` reports a dangling commit, and one `git update-ref` or `git branch` fixes it.
2. **Looking for the file name inside the blob.** Root cause: a blob is content without a name; names and modes are stored in the tree.
3. **After `git update-ref` moved the current branch, `git status` shows changes that nobody made.** Root cause: the ref moved and the index and working tree did not; move the current branch with porcelain, which updates all three.
4. **Giving `git update-ref` a short name.** Root cause: plumbing takes the name literally; write the full name beginning with `refs/`. The next video shows what happens otherwise.
5. **Assuming Git records file permissions and owners.** Root cause: executable or not is the only permission that Git records.

## PRODUCTION EXAMPLE

Now, out of the lab. A data-platform team has a job that publishes generated configuration as commits, on a server with no checkout. It uses exactly the moves you saw: store the blobs, register them in an index, write the tree, write the commit with the previous commit as its parent, and move the branch. The textbook's advice for such scripts is in its table of what can go wrong: create the commit and move the ref together. A script that creates the commit and then fails before moving the ref leaves a dangling commit that no history shows.

One more production point from the textbook: author and committer are text supplied by whoever creates the commit. Git doesn't check them. A signature makes authorship verifiable, and later chapters cover it.

## PRACTICE EXERCISE

Your turn. Do Lab 1.1, "Build a commit by hand", in [`lab-manual/m01-what-git-is.md`](../../lab-manual/m01-what-git-is.md).

Before each of the five steps, write down which object or file will appear and what `git status` and `git log` will say afterwards. The step where your prediction fails is the step to repeat.

## INTERVIEW QUESTION

Q66: "What are a blob, a tree and a commit object?"

**[PAUSE]**

Answer out loud. The question sounds elementary, and it's used to find out whether you know the model or only the words. A strong answer says for each type what it contains, what it refers to and, as important, what it doesn't contain. Then it connects them: how you get from a commit to the bytes of one file. Offer the fourth type without being asked.

## RECAP

**[ANIMATION]** step: second-commit

Let's land this. You should now be able to say: Git has four object types. A blob is file content with no name. A tree is one directory: modes, names and IDs. A commit is one tree, its parents, an author, a committer and a message. A tag object names another object.

**[ANIMATION]** end

`git add` is two moves: store the blob and record it in the index. `git commit` is three: write the trees, write the commit, move the ref. A commit that no ref points at exists and is dangling, and one ref makes it reachable.

## HOMEWORK

- Read sections 2.5 and 2.6 of [Chapter 2](../../textbook/ch02-mental-model.md).
- Repeat Lab 1.1, "Build a commit by hand", a second time from memory, with a different file name and message.
- Challenge: Exercise 1.8, Level 3, "the object that no history shows", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

You built a commit by hand today, one move at a time, so `git commit` has no hidden part left. Repeat the lab from memory before the next video. Next time: the commit graph, reachability, refs and HEAD. Until then, look at the state first and type second. See you in the next one.
