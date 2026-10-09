# V017: Staging deletions and renames, the scope of git add, and unstaging three ways

- **Part.** 1: Foundations
- **Module.** 2
- **Planned minutes.** 26
- **Prerequisites.** V016
- **Textbook sections.** [Chapter 5: The Index](../../textbook/ch05-index.md), sections 5.7 to 5.10
- **Demo scripts.** `labs/ch05/stage-deletions-renames-binary.sh`, `labs/ch05/add-scope.sh`, `labs/ch05/unstage-three-ways.sh`, `labs/ch05/commit-shortcuts.sh`

## HOOK

**[ON SCREEN]** "A developer wanted to keep one file out of a commit. The commit deleted that file from the project for everyone. What did they type, and why did Git itself suggest it?"

Your CTO asks: "A developer wanted to keep one file out of a commit. The commit deleted that file from the project for everyone. What did they type, and why did Git itself suggest it?" Make your guess before I answer.

**[PAUSE]**

They typed `git rm --cached`. And Git did suggest it: in a repository without commits, `git status` prints that exact command as the way to unstage. There the advice is right. It's also where the habit starts.

`git rm --cached` deletes an index entry. The index is Git's list of what goes into the next commit, one entry for each file. Unstaging means restoring an entry. Those are the same thing in exactly one situation, and different in every other. Today we sort out which command does what to an index entry, so that you choose by effect and not by habit. Watch for that one situation. It's a single row of a table.

## INTRODUCTION

**[ANIMATION]** trees: file=src/retriever.py steps=setup,edit,add,commit title=Stage,_then_commit

**[ANIMATION]** step: add

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You know that the index is a full snapshot, and you know how to stage content, whole or in part. Here's the five-second reminder: you edit in the working tree, `git add` copies a version into the index, and HEAD is the last commit. This video completes the set of operations on the index.

**[ANIMATION]** end

Four parts. How deletions, renames and binary files look in the index. What the bulk forms of `git add` take in: `.`, `-u` and `-A`. Three commands that people use to unstage, with two different meanings. And two forms of `git commit` that take content from the working tree and bypass what you staged.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Stage a deletion, a rename and a binary change, and read each in `git status`.
2. Predict what `git add .`, `git add -u` and `git add -A` stage from a given directory.
3. Choose between `git restore --staged`, `git reset <path>` and `git rm --cached` for a given path.
4. Explain how `git commit -a` and `git commit <path>` bypass what was staged.

## CONCEPT

**Deletions, renames, binary files.** In one sentence: in index terms a deletion is a removed entry, a rename is a removed entry plus an added one, and a binary file is an ordinary entry whose content Git will neither show nor split.

After `rm`, the entry exists and the file doesn't: a space and `D`. `git add` on the missing path removes the entry: `D` and a space. `git rm` does both steps at once. For a rename, status prints `R`, but the index only lost one entry and gained another with the same blob ID, the ID of the stored file content. Nothing recorded a rename: status inferred it from the pair, as you learned in video 13.

For binary content, such as an image: unless a `diff` attribute decides, Git inspects the content. The manual says "if it looks like text and is smaller than core.bigFileThreshold, it is treated as text". For a binary file, the diff says that the files differ, and `git add -p` has nothing to offer. When one byte changes, the next add writes a complete new blob.

**The scope of `git add`.** In one sentence: the bulk forms differ in two things: whether untracked files are included, and whether the command is limited to the current directory. An untracked file is one with no entry in the index.

**[ON SCREEN]** The table of section 5.8.

`git add -u`: modified tracked files staged, deleted tracked files staged, untracked files not touched. Scope, the whole working tree.

`git add -A`: modified, deleted and untracked, all staged. Scope, the whole working tree.

`git add .`: modified, deleted and untracked, all staged. Scope, the current directory and below.

`git add -u .`: like `-u`, limited to the current directory and below.

`git add --no-all <path>`: modified staged, deletions not touched, untracked staged. Scope, the pathspec, meaning the path or pattern you name.

No form adds ignored files. All forms are 🟢 SAFE, and all have a preview: `--dry-run`, or `-n`.

**[ANIMATION]** end

Quick quiz, three options. You're in a subdirectory. You want to stage your edits to tracked files across the whole project, and no new files. `git add .`, `git add -u`, or `git add -A`? Say your answer.

**[PAUSE]**

`git add -u`. The dot stays in the current directory, and capital A takes new files too.

An outdated-advice note from the textbook: tutorials written before Git 2.0 say that `git add -u` and `git add -A` cover only the current directory, and that `git add <path>` ignores removed files. Both changed in 2.0.

**[ANIMATION]** step: add

**Unstaging: three commands, two meanings.** In one sentence: to unstage a path is to make its index entry equal to HEAD's again. `git restore --staged <path>` and `git reset <path>` do that. `git rm --cached <path>` deletes the entry, which is the same thing only when HEAD has no such path. All three are 🟡 CAUTION: they change index entries, and files on disk stay.

**[ON SCREEN]** The comparison table of section 5.9, built row by row.

A path that HEAD has: `git restore --staged` undoes the staged change. `git reset <path>` undoes the staged change. `git rm --cached` stages a deletion.

A path that HEAD lacks: all three remove the entry.

A repository without commits: `git restore --staged` fails, because HEAD can't be resolved. `git reset` works. `git rm --cached` works.

Safety check: the first two have none. `git rm --cached` refuses when the staged content matches neither HEAD nor the file. That guard protects a staged version that would otherwise survive only as an unreachable object, one that nothing points to.

`git reset` without a path unstages everything. And when the working tree has moved on since the add, the unreachable blob is the only copy of the staged version.

**[ANIMATION]** step: commit

**Two commit forms that bypass what you staged.** In one sentence: `git commit -a` stages every modified and deleted tracked file and then commits, and `git commit <path>` commits the working-tree content of the named paths and nothing else. Both read the working tree at commit time, whatever you staged before. Both are 🟢 SAFE in the textbook's table, and both have a preview: `--dry-run`.

Precisely, from the manual: with paths, the commit takes "the updated working tree contents of the paths specified on the command line, disregarding any contents that have been staged for other paths". `-i`, or `--include`, instead stages the named paths on top of what is already staged, "usually not what you want unless you are concluding a conflicted merge".

**[ANIMATION]** end

So, three cases. With `git commit -a`, the tree of the new commit is the index after staging every tracked modification and deletion, and staged changes to other paths are committed. With `git commit <path>`, it's HEAD's tree with the named paths taken from the working tree, and staged changes to other paths stay staged and are not committed. With `git commit -i <path>`, it's the index after staging the named paths.

**When staging adds nothing.** The textbook is fair to `-a`: one finished change in an otherwise clean working tree, and `git commit -a` after reading `git status` is fine. The index earns its keep when the working tree holds more than one change. After `git add -p`, `-a` is the wrong reflex: it stages again every hunk you left out.

## MENTAL MODEL

Go back to the packing list from video 15, the index as a shipping list. Every operation in this video is an edit to one line of the list.

Staging a deletion: strike the line. Staging a rename: strike one line, and write another with the same item number. Unstaging: copy the line back from the last shipment's list. `git rm --cached`: strike the line. If the last shipment had that item, a struck line means "do not ship it any more", and that's a deletion for everyone who receives the next box.

Where it breaks: `git commit -a` and `git commit <path>` don't read your list as you left it. They rewrite lines from the shelf, at the last moment, and then ship.

## DIAGRAM

**[DIAGRAM]** A three-row table against the three unstage commands. Fill it during the demo.

```text
                              git restore --staged    git reset <path>       git rm --cached
 ---------------------------  ----------------------  ---------------------  ----------------------
 path that HEAD has           staged change undone    staged change undone   DELETION STAGED
 path that HEAD lacks (new)   entry removed           entry removed          entry removed
 no commits yet (unborn)      fails: no HEAD          works                  works
```

Read the middle row first: for a new path, all three agree. That's the one situation I asked you to watch for, and that row is why people believe the commands are interchangeable. The top right cell is the incident.

**[DIAGRAM]** The root-cause box of section 5.9, one line at a time.

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

That's the incident from the hook, line by line. Read the line marked mechanism.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch05/stage-deletions-renames-binary.sh`.

```bash
labs/run ch05/stage-deletions-renames-binary
```

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

After `rm`, a space and `D`: the entry exists, the file doesn't. `git add` on the missing path removes the entry: `D` and a space.

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

A manual `mv`, then both paths are added. Status prints `R`. The index lost one entry and gained another with the same blob ID, `67b3f03`.

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

A small image is staged like any other file. The entry looks like any other. `--stat` gives byte sizes.

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

One byte changes, and there are no hunks to choose from.

**[TERMINAL]** Caption bar: `labs/ch05/add-scope.sh`.

```bash
labs/run ch05/add-scope
```

We're inside `src/`, with one modification, one deletion and one new file both inside and outside that directory. `--dry-run` prints what would happen and stages nothing.

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

Try it now, on paper, thirty seconds. Six changed paths are on screen. Write down the ones `git add .` would stage from inside `src`. Then do the same for `-u` and for `-A`. Pause me, and write your answer.

**[PAUSE]**

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

Check your lists. `.` stayed inside `src/`, and included the new file and the removal. `-u` reached `README.md` and `docs/guide.md` outside the directory, and skipped both new files. `-A` took everything. If the removal surprised you, that's normal.

<!-- snippet: ch05/add-scope/05-no-all -->
```text
# --no-all with a pathspec: new and modified files, but removals are left unstaged.
$ git add --dry-run --no-all .
add 'src/app.py'
add 'src/prompts.py'
```
<!-- /snippet -->

And `--no-all` with a pathspec: new and modified files, but removals are left unstaged.

**[TERMINAL]** Caption bar: `labs/ch05/unstage-three-ways.sh`. Split layout with the three-row table.

```bash
labs/run ch05/unstage-three-ways
```

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

A tracked file with a staged modification, and a new file that has only been added. Predict what each of the three commands leaves in the index for each of the two paths.

`git restore --staged` 🟡 CAUTION:

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

The tracked file's entry holds HEAD's blob `1e0b1ad` again, and the path shows a space and `M`. The new file, which HEAD lacks, lost its entry and is untracked.

`git reset <path>` 🟡 CAUTION:

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

The identical index, and a report of what remains unstaged.

`git rm --cached` 🟡 CAUTION. Predict the status code for the tracked file. Say it out loud. I'll wait.

**[PAUSE]**

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

`git rm --cached` removed both entries. For the new file the outcome is the same. For the tracked file it's a staged deletion, `D` and a space: the next commit would remove `src/retriever.py` from the project, although the file stays on your disk.

**[DIAGRAM]** Show the root-cause box.

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

The guard: when index, HEAD and working tree hold three different versions of one file, `git rm --cached` refuses.

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

And the repository with no commit yet. `git status` itself recommends `git rm --cached` here, and `git restore --staged` fails, because there's no HEAD to copy from. Every staged path is new, so the advice is right. This is where the habit starts.

**[TERMINAL]** Caption bar: `labs/ch05/commit-shortcuts.sh`.

```bash
labs/run ch05/commit-shortcuts
```

One modified file, one deleted file, one new file. Nothing staged. Predict what `git commit -a` records. Two of them, or all three?

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

Two. The modification and the deletion. Not the new file.

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

`settings.yaml` is staged, and `retriever.py` is modified and not staged. The path form committed `retriever.py` alone, and left the staged `settings.yaml` for later.

**[ANIMATION]** cards: id=surprise question=What_does_git_commit_src/retriever.py_record? cards=Staged:a_clean_version_of_retriever.py|Working_tree:the_same,_plus_one_debug_line title=Now_the_surprise at_1=15 at_2=45

Now the surprise. A clean version of `retriever.py` is staged, and the working tree holds one more line, a debug line. Predict what `git commit src/retriever.py` records. Say it out loud. I'll wait.

**[PAUSE]**

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

The commit contains the debug line. What you staged for that path was replaced by the file on disk.

<!-- snippet: ch05/commit-shortcuts/04-include -->
```text
# settings.yaml is still staged. -i adds the named path on top of what is staged.
$ git status --short
M  config/settings.yaml
 M src/retriever.py
?? src/prompts.py
$ git commit -i src/retriever.py -m "Tune retrieval and sampling"
[main af2189f] Tune retrieval and sampling
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git show --stat --format=%s HEAD
Tune retrieval and sampling

 config/settings.yaml | 1 +
 src/retriever.py     | 3 +--
 2 files changed, 2 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

`-i` adds the named path on top of what is staged: two files in the commit.

<!-- snippet: ch05/commit-shortcuts/05-untracked-path -->
```text
$ git commit src/prompts.py -m "Add prompts"
error: pathspec 'src/prompts.py' did not match any file(s) known to git
[exit status: 1]
```
<!-- /snippet -->

A path that Git doesn't know is an error, not an add.

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

And `--dry-run` previews any commit command without creating the commit.

## COMMON MISTAKES

Five mistakes to watch for.

1. **A commit deleted a file you meant to unstage.** Root cause: `git rm --cached` was used on a path that HEAD has; it removes the entry instead of restoring the one from HEAD.
2. **The commit contains a line you left out with `-p`.** Root cause: it was made with `-a` or with a path, and both read the working tree at commit time.
3. **`git add .` in a subdirectory missed changes elsewhere.** Root cause: `.` is a pathspec for the current directory and below; `-u` and `-A` cover the whole working tree.
4. **An `.env` or a dataset became tracked by accident.** Root cause: `git add -A` and `git add .` stage untracked files; use `-u` for files Git already knows, and name new files explicitly.
5. **`git commit <path>` left other staged work behind.** Root cause: the path form disregards contents staged for other paths; they stay staged for a later commit.

## PRODUCTION EXAMPLE

Now, out of the lab. A developer on a backend team stages a configuration file by accident, notices it in `git status`, and runs the command they remember from their first day with Git: `git rm --cached config/settings.yaml`. Status now shows the path twice, as `D` in the first column and as untracked, which they read as "unstaged". They commit and push. On the next pull, every teammate's `settings.yaml` is deleted from the working tree, and the service fails to start on three laptops.

The fix after the commit, from the textbook: `git restore --source=HEAD~1 --staged <path>`, then a new commit. The prevention: unstage with `git restore --staged`, and read `D` in the first column as "the next commit deletes this".

## PRACTICE EXERCISE

Your turn. Do Lab 2.4, "Unstage three ways and compare the results", in [`lab-manual/m02-working-tree-index-head.md`](../../lab-manual/m02-working-tree-index-head.md).

Before each of the three commands, predict the output of `git status --short` and of `git ls-files --stage` for both paths. Before the step in a repository without commits, predict which of the three commands will fail.

## INTERVIEW QUESTION

Q28: "Compare `git restore --staged`, `git reset <path>` and `git rm --cached` for a path that HEAD has, for a path that HEAD lacks, and in a repository without commits."

**[PAUSE]**

Answer out loud, as a three-by-three table. A strong answer defines "unstage" in terms of the index entry and HEAD first, and derives each cell from that definition. It names the one cell that causes incidents, and the safety check that one of the three commands has and the others lack.

## RECAP

**[ANIMATION]** trees: file=src/retriever.py steps=setup,edit,add,commit title=What_a_plain_commit_records

Let's land this. You should now be able to say, in your own words: a staged deletion is a removed index entry, and a staged rename is a removed entry plus an added one with the same blob. `git add .` is limited to the current directory, `-u` covers all tracked files and no new ones, and `-A` covers everything. Unstaging means making the entry equal to HEAD's: `git restore --staged` and `git reset <path>` do that, and `git rm --cached` removes the entry, which stages a deletion when HEAD has the path.

`git commit -a` and `git commit <path>` take content from the working tree at commit time, so after partial staging I use plain `git commit`.

## HOMEWORK

- Read sections 5.7 to 5.10 of [Chapter 5](../../textbook/ch05-index.md).
- Challenge: Exercise 2.8, Level 3, "the commit that took more than was staged", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Today you learned to choose an index command by its effect, and you can explain the CTO's deleted file. Do the unstaging lab before the next video. Next time: reading the index with `git ls-files`, and two bits that are not an ignore mechanism. Until then, look at the state first and type second. See you in the next one.
