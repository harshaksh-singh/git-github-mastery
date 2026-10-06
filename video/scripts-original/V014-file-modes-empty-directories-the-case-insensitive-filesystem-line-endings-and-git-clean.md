# V014: File modes, empty directories, the case-insensitive filesystem, line endings, and git clean

- **Part.** 1: Foundations
- **Module.** 2
- **Planned minutes.** 26
- **Prerequisites.** V013
- **Textbook sections.** [Chapter 4: The Working Tree](../../textbook/ch04-working-tree.md), sections 4.10 to 4.17
- **Demo scripts.** `labs/ch04/modes-symlinks.sh`, `labs/ch04/empty-directories.sh`, `labs/ch04/case-insensitive.sh`, `labs/ch04/line-endings.sh`, `labs/ch04/clean.sh`

## HOOK

**[ON SCREEN]** Two CTO questions, one above the other.

"The same commit runs on every laptop and fails in CI with a missing module. What is different?"

"One cleanup command deleted two days of labelled evaluation data. Can Git bring it back?"

**[PAUSE]**

The answer to the first: the laptops have a case-insensitive filesystem and the CI runner does not. The answer to the second: `git clean -fdx` deletes files that Git never had a copy of, so no.

Both failures happen at the border between Git and the filesystem. Git has a small, exact idea of what a file is. Your filesystem has a different one. This video walks that border: permissions, directories, upper and lower case, line endings, and the one everyday command that removes data Git has no copy of.

## INTRODUCTION

This is the last video on the working tree, and it collects five topics that have the same shape. In each, the question is: what does Git record, what does the filesystem do, and what happens when the two disagree?

The first four are quick. The fifth, `git clean`, carries a red label, and before I run it I will answer the five questions for a dangerous command aloud.

## LEARNING OBJECTIVES

After this video you can:

1. State what Git records about file permissions, and set the executable bit in the index.
2. Explain why Git cannot track an empty directory.
3. Reproduce and repair a case-only rename on a case-insensitive filesystem.
4. Preview and run `git clean` with the narrowest scope that does the job.

## CONCEPT

**File modes and symbolic links.** In one sentence: besides its content, Git records one more thing about a file: its type, and whether it is executable.

Precisely. An index entry and a tree entry carry a mode. For files there are three: `100644`, a regular file; `100755`, an executable file; and `120000`, a symbolic link. The User's Manual puts it bluntly: "Git actually only pays attention to the executable bit." Owner, group, the other permission bits and timestamps are not recorded.

A mode change is a change: status reports it, and the diff shows `old mode` and `new mode` with no content lines. The mode is not part of the blob. When the filesystem cannot express the bit, you set it in the index directly, with `git add --chmod=+x` or `git update-index --chmod=+x`. Both are 🟢 SAFE: they change the mode in the index entry. With `core.fileMode=false`, Git stops comparing the bit, which is what `git init` and `git clone` configure when they detect a filesystem that does not keep it.

A symbolic link is stored as a blob whose content is the link text. Git never follows the link, and never stores the target's content under the link's path.

**Empty directories.** In one sentence: Git tracks files; a directory exists in a commit only because a file path passes through it.

The index is a list of files, so there is nothing to add for an empty directory. The convention is to give the directory a file. A `.gitignore` inside it, with the pattern `*` and the exception `!.gitignore`, does two jobs at once: it keeps the directory in the repository and ignores its content. You will also meet empty files named `.gitkeep`; the name means nothing to Git and appears nowhere in its documentation. The rule works in the other direction too: `git rm` on the last tracked file removes the directory.

**The case-insensitive filesystem.** In one sentence: Git treats `Config.py` and `config.py` as two different paths, the default macOS filesystem treats them as one file, and the setting that reconciles the two, `core.ignoreCase`, hides case-only renames.

Precisely. Git stores file names as byte sequences and performs no case folding. When `git init` or `git clone` creates a repository, it probes the filesystem and sets `core.ignoreCase=true` if names are case-insensitive, as they are on a default APFS volume. The manual describes the effect: if a directory listing finds `makefile` when Git expects `Makefile`, Git will assume it is really the same file, and continue to remember it as `Makefile`. The manual also calls the variable internal, and warns that changing it by hand may result in unexpected behavior.

The transcripts in this segment assume a case-insensitive volume. On a case-sensitive one they come out differently, and that difference is the lesson.

There are two forms of the trap. In the first, you rename a file with `mv`, changing only the case. On a case-insensitive filesystem such a rename never reaches the index, so it is never committed. In the second, someone on Linux commits two files whose names differ only by case, which is legal there. On a Mac both names cannot exist.

**Line endings, in brief.** Git stores the bytes it is given. A file saved with Windows line endings, CRLF, is stored with them unless an attribute or a configuration value tells Git to convert. When an editor on another platform rewrites every line ending, the whole file becomes one change. The durable fix is a committed `.gitattributes` with `* text=auto` and one `git add --renormalize .`, so that the repository holds LF for everyone regardless of personal settings. A later chapter covers attributes in full; here you only need to recognize the symptom.

**`git clean`.** In one sentence: `git clean` deletes untracked files from the working tree, which makes it the one everyday command that removes data Git has no copy of. It is 🔴 DANGEROUS.

By default it removes untracked files that are not ignored, in the current directory and below, and does not enter untracked directories. The options widen that.

**[ON SCREEN]** The option table of section 4.14.

`-n`, or `--dry-run`: show what would be removed, and remove nothing. `-f`: required to delete anything, because `clean.requireForce` defaults to true; a second `-f` allows deleting untracked directories that contain their own `.git`. `-d`: also remove untracked directories. Capital `-X`: remove only ignored files, which means build products and caches, keeping files you created by hand. Small `-x`: do not use ignore rules at all; remove untracked and ignored files alike. `-e` with a pattern: add an exclude pattern for this run. `-i`: interactive mode.

`-x` and `-X` differ by one keystroke, and by which of your files survive.

Inside `.git`, nothing changes. Clean reads the index to learn which paths are tracked, and the ignore rules to classify the rest. It writes no object, moves no ref, and leaves no record of what it deleted.

## MENTAL MODEL

Keep the workbench and the parts cabinet from V011. For `git clean`, the textbook's analogy is sweeping the workbench into the bin. Everything that came out of the cabinet is safe, because the cabinet still has it. Everything else is gone, and Git cannot tell a wood shaving from the prototype you spent a week on. The textbook says this analogy holds well; its only weakness is that a real bin can be searched afterwards.

For the other four topics, one sentence covers them: Git's idea of a file is content, a path as bytes, and one of three modes. Everything else your filesystem knows, such as owners, other permission bits, empty directories, and whether upper and lower case are the same, is outside that idea. Trouble starts where the filesystem's idea leaks in.

## DIAGRAM

**[DIAGRAM]** The root-cause box of section 4.12, one line at a time.

```text
Observed behavior : A module was renamed from Config.py to config.py. It works on every Mac
                    and fails in CI on Linux, where the file is still called Config.py.
Git state         : The index and every commit say src/Config.py. The Mac's disk says config.py.
Mechanism         : With core.ignoreCase=true Git matches the directory entry "config.py" to
                    the tracked path "Config.py" and keeps the name it already had.
Root cause        : The rename was made in the filesystem only. On a case-insensitive
                    filesystem such a rename never reaches the index, so it is never committed.
Why Git does this : So that tools which change the case of a name on these filesystems do not
                    make a tracked file look deleted and a new one look untracked.
Correct fix       : git mv src/Config.py src/config.py, then commit.
Prevention        : Rename with git mv. Keep one naming convention. Let CI run on a
                    case-sensitive filesystem and fail on paths that differ only by case.
```

**[DIAGRAM]** The mirror image: one tree with two entries, and the single file a Mac checkout produces.

```text
   tree in the commit (made on Linux)            working tree after a clone on a Mac
  +---------------------------------+           +-----------------------------------+
  | src/Config.py   -> blob 1e0b1ad |           | src/                              |
  | src/config.py   -> blob 5fac60c |  ------>  |   one file on disk                |
  +---------------------------------+           |   (two names, one directory slot) |
     two entries, two blobs                     +-----------------------------------+
```

Two entries in the tree, two different blobs. The filesystem has one slot for both names. Whichever is written second overwrites the first, and the other path is reported as modified for ever.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch04/modes-symlinks.sh`.

```bash
labs/run ch04/modes-symlinks
```

<!-- snippet: ch04/modes-symlinks/01-executable-bit -->
```text
$ git ls-files --stage scripts/run_eval.sh
100644 75fd1dcf59cec1b6e5f88119344383b4a77d980b 0	scripts/run_eval.sh
$ chmod +x scripts/run_eval.sh
$ git status --short
 M scripts/run_eval.sh
$ git diff
diff --git a/scripts/run_eval.sh b/scripts/run_eval.sh
old mode 100644
new mode 100755
$ git add scripts/run_eval.sh
$ git ls-files --stage scripts/run_eval.sh
100755 75fd1dcf59cec1b6e5f88119344383b4a77d980b 0	scripts/run_eval.sh
# The blob ID did not change. The mode is stored in the index entry, and later in the tree.
```
<!-- /snippet -->

A mode change is a change: status shows it, and the diff has no content lines, only `old mode` and `new mode`. After `git add`, the entry has mode `100755` and the same blob ID as before.

<!-- snippet: ch04/modes-symlinks/02-only-the-x-bit -->
```text
# Other permission bits are not recorded at all.
$ chmod 600 config/settings.yaml
$ git status --short
M  scripts/run_eval.sh
$ chmod 644 config/settings.yaml
```
<!-- /snippet -->

Other permission bits are not recorded at all: `chmod 600` on a file leaves status unchanged.

<!-- snippet: ch04/modes-symlinks/03-chmod-in-index -->
```text
# Set the bit in the index without touching the file on disk.
$ git add --chmod=+x scripts/deploy.sh
$ git ls-files --stage scripts/deploy.sh
100755 d11e0661a7a15ee7be23789363e0fb67052ec70c 0	scripts/deploy.sh
$ test -x scripts/deploy.sh && echo "executable on disk" || echo "not executable on disk"
not executable on disk
$ git status --short
MM scripts/deploy.sh
M  scripts/run_eval.sh
# With core.fileMode=false Git stops comparing the bit on disk with the index.
$ git -c core.fileMode=false status --short
M  scripts/deploy.sh
M  scripts/run_eval.sh
```
<!-- /snippet -->

`git add --chmod=+x` 🟢 SAFE sets the bit in the index without touching the file on disk. Afterwards the index says executable and the disk does not, so status reports the file as modified in the working tree as well.

<!-- snippet: ch04/modes-symlinks/04-symlink -->
```text
$ ln -s settings.yaml config/current.yaml
$ git add config/current.yaml
$ git ls-files --stage config
120000 4cba9211b05dfbfce96b9e2ce5c8a33d4110caf6 0	config/current.yaml
100644 4da99e38a05a2a7b436aaea17b946e0288949413 0	config/settings.yaml
# The blob of a symbolic link holds the link text, not the content of the target.
$ git cat-file -p :config/current.yaml; echo
settings.yaml
$ git cat-file -s :config/current.yaml
13
```
<!-- /snippet -->

A symbolic link: mode `120000`, and a blob that holds the link text, not the content of the target.

**[TERMINAL]** Caption bar: `labs/ch04/empty-directories.sh`.

```bash
labs/run ch04/empty-directories
```

Two empty directories are created. Predict what `git status` and `git add data` say.

<!-- snippet: ch04/empty-directories/01-invisible -->
```text
$ mkdir -p data/raw data/processed
$ git status
On branch main
nothing to commit, working tree clean
$ git add data
$ git status --short
$ git ls-files data
```
<!-- /snippet -->

A clean working tree. `git add data` adds nothing and says nothing, and the index has no entry under `data/`.

<!-- snippet: ch04/empty-directories/02-placeholder -->
```text
# The index holds file paths only. A directory reaches a commit through a file inside it.
$ printf '*\n!.gitignore\n' > data/raw/.gitignore
$ git add data/raw/.gitignore
$ git status --short
A  data/raw/.gitignore
$ git commit -m "Keep data/raw in the repository, ignore its content"
[main 2105d8a] Keep data/raw in the repository, ignore its content
 1 file changed, 2 insertions(+)
 create mode 100644 data/raw/.gitignore
$ git ls-tree -r --name-only HEAD
data/raw/.gitignore
docs/old-notes.md
src/app.py
$ echo '{"id": 1}' > data/raw/tickets.jsonl
$ git status --short
```
<!-- /snippet -->

The placeholder: a `.gitignore` that ignores everything in the directory except itself.

<!-- snippet: ch04/empty-directories/03-last-file-leaves -->
```text
# Remove the only tracked file in docs/: Git removes the directory with it.
$ git rm docs/old-notes.md
rm 'docs/old-notes.md'
$ ls docs
ls: docs: No such file or directory
[exit status: 1]
# An untracked file keeps a directory alive on disk, and Git still does not track the directory.
$ git restore --staged --worktree docs/old-notes.md
$ echo 'draft' > docs/draft.md
$ git rm docs/old-notes.md
rm 'docs/old-notes.md'
$ ls docs
draft.md
```
<!-- /snippet -->

And the other direction: `git rm` 🟡 CAUTION on the only tracked file in `docs/` removes the directory with it. An untracked file keeps the directory alive on disk, and Git still does not track the directory.

**[TERMINAL]** Caption bar: `labs/ch04/case-insensitive.sh`.

```bash
labs/run ch04/case-insensitive
```

<!-- snippet: ch04/case-insensitive/01-probe -->
```text
$ git init support-bot
Initialized empty Git repository in $LAB/ch04/case-insensitive/support-bot/.git/
$ cd support-bot
$ git config get core.ignoreCase
true
```
<!-- /snippet -->

`git init` probed the filesystem and set `core.ignoreCase` to true.

Now rename `Config.py` to `config.py` with plain `mv`. Predict what `git status` reports.

**[PAUSE]**

<!-- snippet: ch04/case-insensitive/02-invisible-rename -->
```text
$ git ls-files
src/Config.py
src/app.py
$ mv src/Config.py src/config.py
$ ls src
app.py
config.py
$ git status
On branch main
nothing to commit, working tree clean
$ git add -A
$ git ls-files
src/Config.py
src/app.py
```
<!-- /snippet -->

The file on disk is now `config.py`. Status is clean, `git add -A` records nothing, and the index still says `src/Config.py`. Every commit you make will keep the old name, and every Linux machine will check out the old name.

<!-- snippet: ch04/case-insensitive/03-git-mv -->
```text
# The file on disk already has the new name. The index does not. "git mv" renames the index entry.
$ git mv src/Config.py src/config.py
$ git status --short
R  src/Config.py -> src/config.py
$ git ls-files
src/app.py
src/config.py
```
<!-- /snippet -->

The rename has to be made in the index, and `git mv` 🟢 SAFE does that.

**[DIAGRAM]** Show the root-cause box.

The mirror image. A teammate on Linux commits two files whose names differ only by case. A Mac cannot hold both on disk, so the script imitates the teammate by writing the index directly.

<!-- snippet: ch04/case-insensitive/04-collision-made-on-linux -->
```text
# A teammate on Linux commits two files whose names differ only by case.
# A Mac cannot hold both on disk, so this imitation writes the index directly.
$ cd ..
$ git init -q linux-teammate && cd linux-teammate
$ five=$(printf 'TOP_K = 5\n' | git hash-object -w --stdin)
$ eight=$(printf 'TOP_K = 8\n' | git hash-object -w --stdin)
$ git update-index --add --cacheinfo 100644,$five,src/Config.py
$ git update-index --add --cacheinfo 100644,$eight,src/config.py
$ git commit -q -m "Add config module"
$ git ls-tree -r HEAD
100644 blob 1e0b1ade696068e087656f8ae5e859fe92aef3b8	src/Config.py
100644 blob 5fac60c5a32ec062dcb2163acd05c4c1c20dda0c	src/config.py
```
<!-- /snippet -->

Two entries, two blobs: `1e0b1ad` and `5fac60c`. Predict what a clone on a Mac does.

<!-- snippet: ch04/case-insensitive/05-clone-on-mac -->
```text
$ cd ..
$ git clone linux-teammate mac-clone
Cloning into 'mac-clone'...
done.
warning: the following paths have collided (e.g. case-sensitive paths
on a case-insensitive filesystem) and only one from the same
colliding group is in the working tree:

  'src/Config.py'
  'src/config.py'
$ cd mac-clone
$ ls src
config.py
$ git status --short
 M src/Config.py
$ git diff
diff --git a/src/Config.py b/src/Config.py
index 1e0b1ad..5fac60c 100644
--- a/src/Config.py
+++ b/src/Config.py
@@ -1 +1 @@
-TOP_K = 5
+TOP_K = 8
```
<!-- /snippet -->

Git warns during the clone that paths have collided. One file lands on disk, and the other path is reported as modified for ever: when Git reads one name, it gets the content of the other. No `git restore` can fix it, because writing either file overwrites the other.

<!-- snippet: ch04/case-insensitive/06-detect-and-fix -->
```text
# Detect: fold every tracked path to lower case and look for duplicates.
$ git ls-files | tr '[:upper:]' '[:lower:]' | sort | uniq -d
src/config.py
# Fix: stop tracking one of the two names, commit, and check the other one out again.
$ git rm --cached src/Config.py
rm 'src/Config.py'
$ git commit -q -m "Remove Config.py, which collides with config.py on case-insensitive filesystems"
$ git restore .
$ git status --short
$ git ls-files
src/config.py
```
<!-- /snippet -->

The detector folds every tracked path to lower case and looks for duplicates. The documented fix is to stop tracking one of the names with `git rm --cached` 🟡 CAUTION, commit, and check the other one out again. The detector is cheap enough to run in CI on every pull request.

**[TERMINAL]** Caption bar: `labs/ch04/line-endings.sh`.

```bash
labs/run ch04/line-endings
```

<!-- snippet: ch04/line-endings/01-eol -->
```text
# i/ is the content in the index, w/ the content in the working tree, attr/ the attribute in force.
$ git ls-files --eol
i/lf    w/lf    attr/                 	requirements.txt
i/crlf  w/crlf  attr/                 	scripts/deploy.bat
```
<!-- /snippet -->

`git ls-files --eol`: `i/` is the content in the index, `w/` the content in the working tree, `attr/` the attribute in force.

<!-- snippet: ch04/line-endings/02-whole-file-diff -->
```text
# An editor on another platform saves requirements.txt with CRLF line endings.
$ git ls-files --eol requirements.txt
i/lf    w/crlf  attr/                 	requirements.txt
$ git diff --stat
 requirements.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
$ git diff --stat --ignore-cr-at-eol
```
<!-- /snippet -->

An editor saved the file with CRLF. Three lines "changed", although no character you can see did, and `--ignore-cr-at-eol` confirms that the only difference is the carriage return at the end of each line.

**[TERMINAL]** Caption bar: `labs/ch04/clean.sh`.

```bash
labs/run ch04/clean
```

<!-- snippet: ch04/clean/01-start -->
```text
$ git status --short --ignored
?? experiments/
?? scratch.py
?? vendor/
!! .env
!! data/
!! server.log
!! src/__pycache__/
```
<!-- /snippet -->

The starting point: three untracked paths and four ignored ones.

<!-- snippet: ch04/clean/02-refuses -->
```text
$ git clean
fatal: clean.requireForce is true and -f not given: refusing to clean
[exit status: 128]
```
<!-- /snippet -->

Without `-f`, `-n` or `-i`, Git refuses to run. Always start with the dry runs. `git clean -n` is 🟢 SAFE: it is the preview.

<!-- snippet: ch04/clean/03-dry-runs -->
```text
# Untracked files in the current directory only.
$ git clean -n
Would remove scratch.py
# Add -d: untracked directories too.
$ git clean -n -d
Would remove experiments/
Would remove scratch.py
Would skip repository vendor/tokenizer
# Add -X: only what the ignore rules match.
$ git clean -n -d -X
Would remove .env
Would remove data/
Would remove server.log
Would remove src/__pycache__/
# Add -x instead: ignore rules are not used at all, so everything untracked goes.
$ git clean -n -d -x
Would remove .env
Would remove data/
Would remove experiments/
Would remove scratch.py
Would remove server.log
Would remove src/__pycache__/
Would skip repository vendor/tokenizer
```
<!-- /snippet -->

Each added option widens the list. The last one includes `.env` and `data/`. The directory `vendor/tokenizer` is a repository of its own, and is skipped by every run with fewer than two `-f`.

<!-- snippet: ch04/clean/04-exclude -->
```text
# Protect one pattern from a -x run.
$ git clean -n -d -x -e .env
Would remove data/
Would remove experiments/
Would remove scratch.py
Would remove server.log
Would remove src/__pycache__/
Would skip repository vendor/tokenizer
```
<!-- /snippet -->

`-e` protects one pattern from a `-x` run.

**[ON SCREEN]** `git clean -f` 🔴 DANGEROUS. The five questions, one at a time, before the command is run.

What it changes: the working tree only. What it can destroy: untracked files; with `-d`, untracked directories; with `-x`, also ignored files such as `.env`, downloaded datasets, model checkpoints, virtual environments and local databases. How to preview: the same command with `-n` in place of `-f`; read every line of the output. How to recover: not through Git; backups, or editor history for single files. When it is appropriate: to prove a build from a pristine tree, to reset a CI workspace, to clear generated files that the build tool's own clean target misses. Prefer `-X` to `-x`, pass a pathspec to narrow the blast radius, and protect what must survive with `-e`.

<!-- snippet: ch04/clean/05-clean-fd -->
```text
$ git clean -f -d
Removing experiments/
Removing scratch.py
Skipping repository vendor/tokenizer
$ git status --short --ignored
?? vendor/
!! .env
!! data/
!! server.log
!! src/__pycache__/
```
<!-- /snippet -->

`git clean -f -d`: the untracked file and directory are removed, the nested repository is skipped, and the ignored paths are still there.

<!-- snippet: ch04/clean/06-clean-fdx -->
```text
$ git clean -f -d -x
Removing .env
Removing data/
Removing server.log
Removing src/__pycache__/
Skipping repository vendor/tokenizer
$ git status --short --ignored
?? vendor/
$ cat .env
cat: .env: No such file or directory
[exit status: 1]
$ git fsck
# fsck prints nothing: no object ever held those files. Git cannot bring them back.
```
<!-- /snippet -->

`git clean -f -d -x`: `.env`, `data/`, the log and the cache are removed. And `git fsck` prints nothing. There is no dangling blob to rescue, because none of these files was ever added. That is the whole difference between this command and the losses of the last video.

<!-- snippet: ch04/clean/07-nested-repository -->
```text
# One -f never deletes a directory that has its own .git. Two do.
$ git clean -n -d -f -f
Would remove vendor/
```
<!-- /snippet -->

One `-f` never deletes a directory that has its own `.git`. Two do. The script shows it as a dry run only.

## COMMON MISTAKES

1. **A script fails in CI with "Permission denied".** Root cause: it was committed with mode `100644`; `git ls-files --stage <path>` shows it, and the fix is to set the bit in the index and commit.
2. **An expected directory is missing after a clone.** Root cause: Git does not track empty directories; commit a placeholder or, better, have the code create the directory it writes to.
3. **A renamed file still has its old name on Linux.** Root cause: a case-only rename made with `mv` on macOS never reached the index; rename with `git mv`.
4. **Every line of a file shows as changed.** Root cause: an editor rewrote the line endings; `git ls-files --eol` shows `i/lf w/crlf`.
5. **`git clean -fdx` copied from an answer deletes the only copies of ignored data.** Root cause: `-x` disregards ignore rules, and the files were never added, so no object holds them; run `-n` first.

## PRODUCTION EXAMPLE

The typical loss, as the textbook describes it, is in an ML repository where `data/`, `checkpoints/` and `.env` are ignored on purpose. Someone copies `git clean -fdx` from a "fix your broken build" answer, and the ignored files, which were the only copies, are deleted in under a second. The command did what its options say. The defence is the habit of running `-n` first, and of keeping irreplaceable data outside the working tree or in real storage.

And the case trap is specific to teams that develop on macOS or Windows and deploy on Linux, which describes most backend and ML teams. Python imports, Java class files and Docker `COPY` paths are all case-sensitive on Linux.

## PRACTICE EXERCISE

Do Exercise 2.1, Level 1, "every short status code, made on purpose", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md), repeated with an executable script and a case-only rename added to the states you make.

Predict the status code for the mode change before you look. For the case-only rename made with `mv`, predict what `git status` and `git ls-files` will show, and only then run them.

## INTERVIEW QUESTION

Q48: "A Python module imports fine on macOS and fails on the Linux CI runner after someone renamed it. What happened inside Git, and how do you prevent a recurrence?"

Answer aloud. A strong answer says what the index held before and after the rename, names the setting involved and who set it, and explains why Git behaves this way by design. For prevention, give more than one layer: a habit for the person, and a check for the pipeline.

## RECAP

You should now be able to say: Git records one permission bit, executable or not, and stores a symbolic link as a blob holding the link text. It tracks files, so an empty directory does not exist for it. On a case-insensitive filesystem, a case-only rename made with `mv` never reaches the index, and two paths that differ only by case collide on checkout; I rename with `git mv` and detect collisions in CI. Git stores the bytes it is given, line endings included. And `git clean` deletes files that no object holds, so I run it with `-n` first, prefer `-X` to `-x`, and give it the narrowest scope that does the job.

## HOMEWORK

- Read sections 4.10 to 4.17 of [Chapter 4](../../textbook/ch04-working-tree.md), and do the Practice section 4.19.
- Challenge: Exercise 2.9, Level 4, "Git does not see my edits", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
