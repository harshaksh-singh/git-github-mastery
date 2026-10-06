# V011: The working tree, three categories of file, and the anatomy of git status

- **Part.** 1: Foundations
- **Module.** 2
- **Planned minutes.** 22
- **Prerequisites.** V010
- **Textbook sections.** [Chapter 4: The Working Tree](../../textbook/ch04-working-tree.md), sections 4.1 to 4.4
- **Demo scripts.** `labs/ch04/worktree-basics.sh`, `labs/ch04/three-categories.sh`, `labs/ch04/status-anatomy.sh`

## HOOK

**[ON SCREEN]** "The same commit builds on the laptop and behaves differently in CI."

A laptop build and a CI build of the same commit behave differently. CI is the automated system that builds and tests every change. The commit ID is identical. And somebody says "but `git status` is clean on my machine".

A clean `git status` doesn't mean the directory equals the commit. Ignored files, the ones Git has been told not to list, are present and invisible: a local `.env` file of settings, compiled caches, a stale `build/` folder. Any tool that reads the directory sees the working tree, not the commit: a container build that copies the project directory, a packaging step, a test runner, an evaluation script.

**[PAUSE]**

To reason about that, you need a precise idea of what the working tree is, which category each path in it belongs to, and what `git status` compares. That's this video. And one command in the demo shows exactly what the laptop has that the commit doesn't.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Part 1 continues with the place where you spend your day: the working tree, the folder of files you edit. Most tutorials treat it as too plain to explain. The textbook opens Chapter 4 with three CTO questions that all turn out to be working-tree questions. Why did a secret scanner find a key although `.env` was in `.gitignore`? Why does the same commit fail in CI with a missing module? And can Git bring back two days of labelled evaluation data that a cleanup command deleted? The next four videos answer them.

**[ANIMATION]** trees: file=src/retriever.py order=reverse names=Working_tree,Index,HEAD_commit steps=setup,edit,add,restore title=Three_places_for_one_file

**[ANIMATION]** step: edit

Hold on to one idea through all four. A version of a file can live in three places: in the working tree, in the index, or in a commit. The index is Git's list of what the next commit will contain. The working tree is the only one of the three with no history and no second copy. Git can rebuild tracked files in it from the index or from a commit. It can't rebuild content that never left it, such as an edit you haven't staged.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Define the working tree, and say what a bare repository lacks.
2. Classify a path as tracked, untracked or ignored from the index and the ignore rules.
3. Explain `git status` as two comparisons, and read the two columns of the short format.
4. Choose the status format that a script should parse.

## CONCEPT

**What the working tree is.** In one sentence: the working tree is the directory of ordinary files that you edit, build and run: one checked-out version of the project, plus whatever else is lying in that directory.

Now precisely. The glossary defines the working tree as "the tree of actual checked out files", which "normally contains the contents of the HEAD commit's tree, plus any local changes that you have made but not yet committed". It starts at the directory that contains the dot git folder, called the top level, and every path Git prints is relative to that directory unless a command says otherwise. A repository can have no working tree, which is a bare repository, the form used on servers. Or one, the normal case. Or several, which are linked worktrees and belong to a later chapter.

And inside the dot git folder? Nothing. The working tree isn't stored there at all. The only trace of it is in the index file. For each tracked path, the index remembers which blob the file last matched, and the file's size and timestamps, so that Git can find changed files without reading every file.

**Three categories.** In one sentence: every path in the working tree is in exactly one of three categories, and the index decides which. Tracked, if it has an index entry. Ignored, if it has none and matches an ignore pattern. Untracked otherwise.

**[ON SCREEN]** The table of section 4.3.

A tracked path is shown by `git status` when it differs from the index or from HEAD. `git ls-files` lists it. `git add .` updates it. `git clean` never touches it.

An untracked path is shown under "Untracked files". `git add .` adds it. `git clean` removes it.

An ignored path is hidden unless you pass `--ignored`. `git add .` does not add it, unless you force it with `-f`. `git clean` removes it only with `-x` or `-X`.

Two consequences follow from the definitions. "Ignored" is a kind of untracked, so a tracked path can never be ignored. And "tracked" says nothing about commits: a path becomes tracked the moment `git add` writes its index entry. Almost everyone hears "tracked" as "committed" at first. It means: has an index entry.

**[ANIMATION]** step: add

**The anatomy of `git status`.** In one sentence: `git status` is two comparisons and one scan. HEAD against the index. The index against the working tree. And a scan of the working tree for paths that have no index entry.

The manual describes the same three parts. The first is what `git commit` would record. The second and third are what you could still add.

The short format puts the two comparisons in two columns. The first column, X, is comparison one: HEAD against the index. The second column, Y, is comparison two: the index against the working tree.

**[ON SCREEN]** The XY table of section 4.4.

`M` and a space: a modification is staged, and the working tree matches the index. A space and `M`: modified in the working tree, not staged. `MM`: staged, then modified again. `A` and a space: a new file is staged. `D` and a space: a deletion is staged. A space and `D`: the file was deleted in the working tree, and the deletion is not staged. `R` and a space: a rename is staged. Two question marks: untracked. Two exclamation marks: ignored, shown only with `--ignored`.

**Formats for scripts.** There are two stable formats. `--porcelain`, version 1, looks like the short format, but it's guaranteed not to change between Git versions or with user configuration, and it always prints paths relative to the top level. `--porcelain=v2` adds the file modes and object IDs that status compared. Add `-z` when file names may contain spaces or newlines: entries are then separated by NUL bytes and never quoted.

**Three details that matter in practice.** Untracked directories are collapsed: status prints the directory, not the files in it. `--untracked-files=all` lists every file, and `--untracked-files=no` skips the scan, which is the expensive part in a large working tree. Second, status writes. By default it refreshes the cached file information in the index and writes the index back, taking a lock while it does. The manual's advice for background tools is `git --no-optional-locks status`. Third, status is local: a line such as "Your branch is up to date with 'origin/main'" compares with the last fetched state, not with the server.

All commands in this video are 🟢 SAFE except two that appear once: `git restore .`, which I'll label when it appears, and `git add`, which only adds.

## MENTAL MODEL

Two pictures now. The textbook's analogy for the working tree: a workbench in front of a parts cabinet. The cabinet, the object database, holds labelled parts that never change. The bench is where you assemble and modify. Git can lay any stored version out on the bench again, but shavings and half-built parts that never went into the cabinet exist only on the bench. It breaks in two places. Git doesn't watch the bench. It looks only when a command asks. And the bench may hold things the cabinet has never seen, untracked files, which Git will list but doesn't protect.

**[ANIMATION]** step: add

For status: a warehouse audit with three clipboards. What the last signed inventory says: HEAD. What the next inventory will say: the index. And what is on the shelves: the working tree. Status reads out the differences between neighbouring clipboards. It breaks because the middle clipboard isn't a list of differences. It's a complete inventory, and status computes the differences each time you ask.

## DIAGRAM

**[DIAGRAM]** The diagram of section 4.2.

```text
   working tree                   index (.git/index)              HEAD commit
 +---------------------+        +----------------------+        +----------------------+
 | plain files you     |  add   | one entry per        | commit | a full snapshot:     |
 | edit, build and run | -----> | tracked path:        | -----> | tree and blobs,      |
 |                     |        | mode, blob ID, path  |        | immutable            |
 | plus untracked and  | <----- |                      | <----- |                      |
 | ignored files       | restore|                      | restore|                      |
 +---------------------+        +----------------------+ --staged+---------------------+
   no history,                    one proposed snapshot           every committed snapshot
   no second copy
```

Three boxes. Content moves right with `add` and `commit`, and back left with `restore`. Read the captions under the boxes: the right box holds every committed snapshot, the middle box one proposed snapshot, and the left box has no history and no second copy.

**[DIAGRAM]** The decision tree of section 4.3.

```text
                    does the path have an entry in the index?
                       /                               \
                     yes                                no
                      |                                  |
                  TRACKED                  does an ignore pattern match it?
                                               /                    \
                                             no                      yes
                                              |                       |
                                         UNTRACKED                 IGNORED
                                    (status lists it)         (status hides it)

   git add <path>             untracked -> tracked     (an ignored path needs -f)
   git rm --cached <path>     tracked   -> untracked, or ignored if a pattern matches
```

The first question is always about the index. Only on the "no" branch is an ignore pattern consulted. Keep that order in mind. The next video is built on it.

**[DIAGRAM]** The diagram of section 4.4.

```text
     HEAD commit              index                 working tree
   +-------------+        +-------------+         +-------------+
   |  last       |        |  proposed   |         |  files on   |
   |  snapshot   |        |  snapshot   |         |  disk       |
   +-------------+        +-------------+         +-------------+
           \                 /       \                 /      \
            \               /         \               /        scan for paths
             comparison 1               comparison 2           without an index entry
          "Changes to be committed"   "Changes not staged"     "Untracked files"
             column X                    column Y                 ??
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch04/worktree-basics.sh`.

```bash
labs/run ch04/worktree-basics
```

`git rev-parse` answers "where am I" questions. From a subdirectory, `--show-prefix` prints the path from the top level to the current directory.

<!-- snippet: ch04/worktree-basics/01-where -->
```text
$ git init support-bot
Initialized empty Git repository in $LAB/ch04/worktree-basics/support-bot/.git/
$ cd support-bot
$ git rev-parse --show-toplevel
$LAB/ch04/worktree-basics/support-bot
$ git rev-parse --git-dir
.git
$ cd src
$ git rev-parse --show-toplevel --show-prefix --git-dir
$LAB/ch04/worktree-basics/support-bot
src/
$LAB/ch04/worktree-basics/support-bot/.git
$ git rev-parse --is-inside-work-tree
true
$ cd ..
```
<!-- /snippet -->

Next, a repository without a working tree. Predict what `git status` says in it. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch04/worktree-basics/02-bare -->
```text
# A bare repository is a repository without a working tree.
$ git init --bare ../central.git
Initialized empty Git repository in $LAB/ch04/worktree-basics/central.git/
$ git -C ../central.git rev-parse --is-bare-repository
true
$ git -C ../central.git status
fatal: this operation must be run in a work tree
[exit status: 128]
```
<!-- /snippet -->

A bare repository has the `.git` content and nothing to check out into, so any command that needs a working tree refuses.

Now the asymmetry that the rest of this block depends on. The script deletes two tracked directories and one untracked file, `.env`, and then asks Git to rebuild the working tree.

**[ANIMATION]** step: restore

`git restore` on working-tree paths is 🔴 DANGEROUS in general: it overwrites files from the index, and content that was never staged has no recovery. Video 13 answers the five questions for it in full.

**[ANIMATION]** end

Here the files are already deleted, so nothing further can be lost. Predict: which files come back?

**[PAUSE]**

<!-- snippet: ch04/worktree-basics/03-rebuild -->
```text
# Tracked content can be rebuilt from the index. Untracked content cannot.
$ echo 'LLM_API_KEY=lab-secret-0001' > .env
$ rm -r src config .env
$ git status --short
 D config/settings.yaml
 D src/app.py
 D src/retriever.py
$ git restore .
$ find . -path ./.git -prune -o -type f -print | sort
./config/settings.yaml
./src/app.py
./src/retriever.py
$ git restore .env
error: pathspec '.env' did not match any file(s) known to git
[exit status: 1]
```
<!-- /snippet -->

The three tracked files came back from the index. `.env` didn't. Git has never heard of it, and says so. Tracked content had a second copy. The untracked file had none.

**[TERMINAL]** Caption bar: `labs/ch04/three-categories.sh`.

```bash
labs/run ch04/three-categories
```

The repository has four committed files and a three-line `.gitignore`. Four more paths were then created in the working tree.

<!-- snippet: ch04/three-categories/01-status -->
```text
$ cat .gitignore
.env
__pycache__/
data/
$ git status
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes/

nothing added to commit but untracked files present (use "git add" to track)
```
<!-- /snippet -->

Status shows one untracked directory, and says nothing about `.env`, `data/` or the bytecode cache.

<!-- snippet: ch04/three-categories/02-status-ignored -->
```text
$ git status --ignored
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes/

Ignored files:
  (use "git add -f <file>..." to include in what will be committed)
	.env
	data/
	src/__pycache__/

nothing added to commit but untracked files present (use "git add" to track)
```
<!-- /snippet -->

With `--ignored` they appear. This is the command for the hook: it lists what the laptop has that the commit doesn't.

<!-- snippet: ch04/three-categories/03-ls-files -->
```text
# Tracked: every path that has an entry in the index.
$ git ls-files
.gitignore
config/settings.yaml
src/app.py
src/retriever.py
# Untracked and not ignored.
$ git ls-files --others --exclude-standard
notes/ideas.md
# Untracked and ignored.
$ git ls-files --others --ignored --exclude-standard
.env
data/tickets.jsonl
src/__pycache__/app.cpython-314.pyc
```
<!-- /snippet -->

`git ls-files` lists each category exactly: tracked, then untracked and not ignored, then ignored.

Quick quiz before the next snippet. We run `git add` on the ignored file `.env`. Option one: it's added quietly. Option two: it's refused, with a hint. Say it out loud.

**[PAUSE]**

<!-- snippet: ch04/three-categories/04-transitions -->
```text
# Untracked becomes tracked the moment the path gets an index entry.
$ git add notes/ideas.md
$ git ls-files notes
notes/ideas.md
# An ignored path is refused unless you force it.
$ git add .env
The following paths are ignored by one of your .gitignore files:
.env
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
[exit status: 1]
$ git status --short --ignored
A  notes/ideas.md
!! .env
!! data/
!! src/__pycache__/
```
<!-- /snippet -->

Option two. Moving between categories is always an index operation. `git add` 🟢 SAFE makes an untracked path tracked. An ignored path is refused unless you force it. In the short format, `A` and a space is a staged new file, and `!!` marks ignored paths. The refusal to add `.env` is a courtesy of `git add`, not a lock: `git add -f .env` would add it.

**[TERMINAL]** Caption bar: `labs/ch04/status-anatomy.sh`.

```bash
labs/run ch04/status-anatomy
```

One repository, one path in each interesting state.

<!-- snippet: ch04/status-anatomy/01-long -->
```text
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   config/settings.yaml
	renamed:    README.md -> docs/README.md
	deleted:    docs/old-notes.md
	new file:   src/prompts.py
	modified:   src/retriever.py

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	deleted:    requirements.txt
	modified:   src/app.py
	modified:   src/retriever.py

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	scratch/
```
<!-- /snippet -->

`src/retriever.py` appears twice. That's not a contradiction: it was staged and then edited again, so both comparisons find a difference.

<!-- snippet: ch04/status-anatomy/02-short -->
```text
$ git status --short
M  config/settings.yaml
R  README.md -> docs/README.md
D  docs/old-notes.md
 D requirements.txt
 M src/app.py
A  src/prompts.py
MM src/retriever.py
?? scratch/
$ git status --short --branch
## main
M  config/settings.yaml
R  README.md -> docs/README.md
D  docs/old-notes.md
 D requirements.txt
 M src/app.py
A  src/prompts.py
MM src/retriever.py
?? scratch/
```
<!-- /snippet -->

The same state in two columns.

**[ON SCREEN]** Cover the output of the next snippet. Show only the list of paths.

Try it now. For each of these files, say the letter in column X and the letter in column Y, from what the long format told you. Take thirty seconds and write your answers down. Then I uncover the two diff commands that perform the same two comparisons.

**[PAUSE]**

<!-- snippet: ch04/status-anatomy/03-two-comparisons -->
```text
# Comparison 1: HEAD against the index. This is the X column.
$ git diff --cached --name-status
M	config/settings.yaml
R100	README.md	docs/README.md
D	docs/old-notes.md
A	src/prompts.py
M	src/retriever.py
# Comparison 2: the index against the working tree. This is the Y column.
$ git diff --name-status
D	requirements.txt
M	src/app.py
M	src/retriever.py
# Third pass: paths in the working tree that have no index entry.
$ git ls-files --others --exclude-standard
scratch/notes.py
scratch/try.py
```
<!-- /snippet -->

`git diff --cached --name-status` is comparison one, the X column. `git diff --name-status` is comparison two, the Y column. `src/retriever.py` is in both lists, so its code is `MM`. If you had that one, you have the model.

<!-- snippet: ch04/status-anatomy/04-porcelain -->
```text
$ git status --porcelain
M  config/settings.yaml
R  README.md -> docs/README.md
D  docs/old-notes.md
 D requirements.txt
 M src/app.py
A  src/prompts.py
MM src/retriever.py
?? scratch/
$ git status --porcelain=v2 --branch
# branch.oid 7b557e0425ff4598b69acdedec3ca379116db157
# branch.head main
1 M. N... 100644 100644 100644 4da99e38a05a2a7b436aaea17b946e0288949413 0217758d92bf9cd7d8ebba62175a33a9ef51ba2f config/settings.yaml
2 R. N... 100644 100644 100644 384f3ba8db7735cfcccc8a6644808c37adbe6fba 384f3ba8db7735cfcccc8a6644808c37adbe6fba R100 docs/README.md	README.md
1 D. N... 100644 000000 000000 4dddde5373611e10f9ec6bc328a25ae216552487 0000000000000000000000000000000000000000 docs/old-notes.md
1 .D N... 100644 100644 000000 fbce96793add271886cc2acbd6b5bca38d960391 fbce96793add271886cc2acbd6b5bca38d960391 requirements.txt
1 .M N... 100644 100644 100644 9069bfc5af86dd8daf593b43de35ae691a7e682f 9069bfc5af86dd8daf593b43de35ae691a7e682f src/app.py
1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 5e83731ea002effc7ffce6c4a2b565cbf889abd8 src/prompts.py
1 MM N... 100644 100644 100644 67b3f03b8c4ab448c68cda278050d05e9c1865f0 ecfe75fa97c452977d0fa9decbbca215f5633779 src/retriever.py
? scratch/
```
<!-- /snippet -->

The formats for scripts. Read one version 2 line, the one for `src/app.py`: the three modes are HEAD, index and working tree. The two object IDs are HEAD and index. They're equal, so nothing is staged for this path. There's no third ID, because status compares the working-tree file with the index entry and doesn't need to name its content.

<!-- snippet: ch04/status-anatomy/05-untracked-modes -->
```text
$ git status --short --untracked-files=all
M  config/settings.yaml
R  README.md -> docs/README.md
D  docs/old-notes.md
 D requirements.txt
 M src/app.py
A  src/prompts.py
MM src/retriever.py
?? scratch/notes.py
?? scratch/try.py
$ git status --short --untracked-files=no
M  config/settings.yaml
R  README.md -> docs/README.md
D  docs/old-notes.md
 D requirements.txt
 M src/app.py
A  src/prompts.py
MM src/retriever.py
```
<!-- /snippet -->

And the untracked modes: `all` lists the two files inside `scratch/`, and `no` skips the scan.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Taking a clean `git status` to mean "the directory equals the commit".** Root cause: ignored files are present and hidden; `git status --ignored` lists them.
2. **Thinking "tracked" means "committed".** Root cause: tracked means "has an index entry"; a path becomes tracked at `git add`.
3. **Reading a path listed twice as a contradiction.** Root cause: status makes two comparisons, and a file staged and then edited again differs in both.
4. **Parsing the long or short format in a script.** Root cause: those formats follow user configuration and may change; `--porcelain` is the stable one, with `-z` for unusual file names.
5. **Using `git diff --exit-code` to prove that a build left the tree clean.** Root cause: it performs comparison two only, so a generator that created a new, untracked file passes unnoticed.

## PRODUCTION EXAMPLE

Now, out of the lab. A CI job has to prove that the build left the tree clean: generated code is committed, and the formatter changed nothing. The job should test `git status --porcelain` for empty output. `git diff --exit-code` isn't enough, for the reason you now know: it covers the index against the working tree and nothing else, so a generator that wrote a new, untracked file passes.

And for the laptop-versus-CI difference from the hook: a build that must contain exactly the commit should run in a fresh clone or a fresh worktree.

## PRACTICE EXERCISE

Your turn. Do Exercise 2.1, Level 1, "every short status code, made on purpose", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

For each file, write the two-letter code you expect before you run `git status --short`, and say which of the two comparisons produced each letter.

## INTERVIEW QUESTION

Q5: "Define tracked, untracked and ignored in terms of the index. Can a path be tracked and ignored at the same time?"

**[PAUSE]**

Answer out loud. A strong answer defines all three from one question about the index and one about ignore patterns, in that order, and derives the answer to the second half from the definitions instead of asserting it. Say which command lists each category.

## RECAP

Let's land this. You should now be able to say: the working tree is one checked-out version plus whatever else lies in the directory, and it has no history and no second copy. A path is tracked if it has an index entry, ignored if it has none and matches a pattern, and untracked otherwise.

**[ANIMATION]** trees: file=src/retriever.py order=reverse names=Working_tree,Index,HEAD_commit steps=setup,edit,add cmd=off title=git_status:_two_comparisons_and_one_scan say_setup=Three_places_for_one_file say_edit=off say_add=HEAD_against_the_index,_then_the_index_against_the_working_tree

`git status` is two comparisons and one scan: HEAD against the index, the index against the working tree, and a scan for paths without an index entry. In the short format the left column is the index and the right column is the working tree. Scripts parse `--porcelain`.

## HOMEWORK

- Read sections 4.1 to 4.4 of [Chapter 4](../../textbook/ch04-working-tree.md).
- Challenge: Exercise 2.9, Level 4, "Git does not see my edits", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

You can now read every line and every letter that git status prints, and that's the report you'll read most often. Do the status-code exercise before the next video. Next time: ignore rules, and the already-tracked trap. Until then, look at the state first and type second. See you in the next one.
