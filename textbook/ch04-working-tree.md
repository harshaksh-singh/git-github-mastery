# Chapter 4: The Working Tree

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch04/`.

## 4.1 Why this matters

Three questions a CTO can ask after an ordinary week:

1. "We put `.env` in `.gitignore` months ago. Why did the secret scanner find the key in the repository last night?"
2. "The same commit runs on every laptop and fails in CI with a missing module. What is different?"
3. "One cleanup command deleted two days of labelled evaluation data. Can Git bring it back?"

None of these is about commits, branches or GitHub. All three are about the working tree, the part of Git that most tutorials treat as too plain to explain. The answers are: an ignore rule never applies to a path that is already tracked (section 4.6); the laptops have a case-insensitive filesystem and the CI runner does not (section 4.12); and `git clean -fdx` deletes files that Git never had a copy of, so no (section 4.14).

Hold on to one idea through the chapter. A version of a file can live in three places: in the working tree, in the index, or in a commit. The working tree is the only one of the three with no history and no second copy. Git can rebuild tracked files in it from the index or from a commit. It cannot rebuild content that never left it.

## 4.2 What the working tree is

**In one sentence.** The working tree is the directory of ordinary files that you edit, build and run: one checked-out version of the project, plus whatever else is lying in that directory.

**Analogy.** A workbench in front of a parts cabinet. The cabinet (the object database) holds labelled parts that never change. The bench is where you assemble and modify. Git can lay any stored version out on the bench again, but shavings and half-built parts that never went into the cabinet exist only on the bench. The analogy breaks in two places: Git does not watch the bench, it looks only when a command asks; and the bench may hold things the cabinet has never seen (untracked files), which Git will list but does not protect.

**Precisely.** The glossary defines the working tree as "the tree of actual checked out files", which "normally contains the contents of the HEAD commit's tree, plus any local changes that you have made but not yet committed" ([gitglossary](https://git-scm.com/docs/gitglossary)). It starts at the directory that contains `.git`, called the top level, and every path Git prints is relative to that directory unless a command says otherwise. A repository can have no working tree (a bare repository, the form used on servers and for the local "remotes" in later labs), one (the normal case), or several (linked worktrees, Chapter 25, Worktrees).

**Inside `.git`.** Nothing. The working tree is not stored in `.git` at all. The only trace of it there is in `.git/index`: for each tracked path the index remembers which blob the file last matched, and the file's size and timestamps, so that Git can find changed files without reading every file (Chapter 5, section 5.14).

**See it.** `git rev-parse` answers "where am I" questions. From a subdirectory, `--show-prefix` prints the path from the top level to the current directory.

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

A bare repository has the `.git` content and nothing to check out into, so any command that needs a working tree refuses:

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

Now the asymmetry that the rest of the chapter depends on. Delete two tracked directories and one untracked file, then ask Git to rebuild the working tree:

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

The three tracked files came back from the index. `.env` did not: Git has never heard of it, and says so.

**Picture.**

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

**In production.** Any tool that reads the directory sees the working tree, not the commit: a container build that copies the project directory, a packaging step, a test runner, an evaluation script. A clean `git status` does not mean the directory equals the commit, because ignored files are present and invisible: a local `.env`, compiled caches, a stale `build/`. When a laptop build and a CI build of the same commit behave differently, list what the laptop has that the commit does not with `git status --ignored` (section 4.3) before looking anywhere else. A build that must contain exactly the commit should run in a fresh clone or a fresh worktree.

## 4.3 Tracked, untracked, ignored

**In one sentence.** Every path in the working tree is in exactly one of three categories, and the index decides which: tracked if it has an index entry, ignored if it has none and matches an ignore pattern, untracked otherwise.

**Precisely.**

| Category | Defined by | `git status` | Listed by | Touched by `git add .` | Touched by `git clean` |
|---|---|---|---|---|---|
| Tracked | The path has an entry in the index | Shown when it differs from the index or from HEAD | `git ls-files` | Yes, updated | Never |
| Untracked | No index entry, no ignore pattern matches | Shown under "Untracked files" | `git ls-files --others --exclude-standard` | Yes, added | Yes |
| Ignored | No index entry, an ignore pattern matches | Hidden unless `--ignored` | `git ls-files --others --ignored --exclude-standard` | No (`-f` to force) | Only with `-x` or `-X` |

Two consequences follow from the definitions. "Ignored" is a kind of untracked, so a tracked path can never be ignored. And "tracked" says nothing about commits: a path becomes tracked the moment `git add` writes its index entry.

**See it.** The repository has four committed files and a three-line `.gitignore`. Four more paths were then created in the working tree.

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

Status shows one untracked directory and says nothing about `.env`, `data/` or the bytecode cache. `git ls-files` lists each category exactly:

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

Moving between categories is always an index operation:

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

In the short format `A ` is a staged new file and `!!` marks ignored paths. The refusal to add `.env` is a courtesy of `git add`, not a lock: `git add -f .env` would add it.

**Picture.**

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

## 4.4 The anatomy of `git status`

**In one sentence.** `git status` is two comparisons and one scan: HEAD against the index, the index against the working tree, and a scan of the working tree for paths that have no index entry.

**Analogy.** A warehouse audit with three clipboards: what the last signed inventory says (HEAD), what the next inventory will say (the index), and what is on the shelves (the working tree). Status reads out the differences between neighbouring clipboards. The analogy breaks because the middle clipboard is not a list of differences: it is a complete inventory, and status computes the differences each time you ask.

**Precisely.** The manual describes the same three parts: "paths that have differences between the index file and the current HEAD commit, paths that have differences between the working tree and the index file, and paths in the working tree that are not tracked by Git" ([git-status](https://git-scm.com/docs/git-status)). The first is what `git commit` would record. The second and third are what you could still add.

**See it.** One repository, one path in each interesting state:

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

`src/retriever.py` appears twice. That is not a contradiction: it was staged and then edited again, so both comparisons find a difference. The short format puts the two comparisons in two columns:

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

The first column (X) is comparison 1, the second (Y) is comparison 2. You can reproduce each column with the diff command that performs the same comparison:

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

| XY | Meaning | In the transcript |
|---|---|---|
| `M ` | Modification staged; working tree matches the index | `config/settings.yaml` |
| ` M` | Modified in the working tree, not staged | `src/app.py` |
| `MM` | Staged, then modified again | `src/retriever.py` |
| `A ` | New file staged | `src/prompts.py` |
| `D ` | Deletion staged | `docs/old-notes.md` |
| ` D` | File deleted in the working tree, deletion not staged | `requirements.txt` |
| `R ` | Rename staged (detected, section 4.9) | `README.md -> docs/README.md` |
| `??` | Untracked | `scratch/` |
| `!!` | Ignored, shown only with `--ignored` | section 4.3 |
| `UU`, `AA`, `DU` and others | Unmerged during a conflict | Chapter 5, section 5.13 |

For scripts there are two stable formats. `--porcelain` (version 1) looks like the short format but is guaranteed not to change between Git versions or with user configuration, and always prints paths relative to the top level. `--porcelain=v2` adds the file modes and object IDs that status compared:

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

Read one version 2 line: `1 .M N... 100644 100644 100644 9069bfc… 9069bfc… src/app.py`. The three modes are HEAD, index and working tree. The two object IDs are HEAD and index. They are equal, so nothing is staged for this path, and there is no third ID because status compares the working tree file with the index entry and does not need to name its content. Add `-z` when file names may contain spaces or newlines: entries are then separated by NUL bytes and never quoted.

Three details matter in practice:

- **Untracked directories are collapsed.** Status printed `scratch/`, not the two files inside it. `--untracked-files=all` (`-uall`) lists every file, and `--untracked-files=no` (`-uno`) skips the scan, which is the expensive part in a large working tree. Run `labs/run ch04/status-anatomy` to see both.
- **Status writes.** By default `git status` refreshes the cached file information in the index and writes the index back, taking a lock while it does. A tool that runs status in the background can therefore collide with your foreground command. The manual's advice for such tools is `git --no-optional-locks status`.
- **Status is local.** Lines such as "Your branch is up to date with 'origin/main'" compare with the last fetched state, not with the server (Chapter 12, Remote Operations).

**Picture.**

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

**In production.** A CI job that must prove "the build left the tree clean" (generated code is committed, the formatter changed nothing) should test `git status --porcelain` for empty output. `git diff --exit-code` is not enough: it performs comparison 2 only, so a generator that created a new, untracked file passes unnoticed.

## 4.5 Ignore rules

**In one sentence.** An ignore pattern tells the commands that scan the working tree for untracked paths to leave matching paths out.

**Analogy.** A "do not list" note taped to the warehouse door for the people doing the audit. It changes what the auditors report. It does not move, lock or hide anything, and it has no effect on items that are already in the inventory. That last clause is where most people's mental model breaks, and section 4.6 is about it.

**Precisely.** Patterns come from four sources. From highest to lowest precedence ([gitignore](https://git-scm.com/docs/gitignore)):

| Source | Scope | Shared with the team | Use it for |
|---|---|---|---|
| Command-line options, for commands that take them (for example `git clean -e`) | One command | No | A one-off exception |
| `.gitignore` in the path's directory or any parent directory; a deeper file overrides a shallower one | That directory and below | Yes, it is a tracked file | Build output, caches, datasets, secrets files: what every developer should ignore |
| `.git/info/exclude` (formally `$GIT_COMMON_DIR/info/exclude`) | This clone | No | Your own scratch files in this repository |
| The file named by `core.excludesFile`; default `$XDG_CONFIG_HOME/git/ignore`, or `~/.config/git/ignore` when that variable is not set | Every repository on this machine | No | Editor and operating-system noise such as `.DS_Store` and `.idea/` |

Within one source, the last matching pattern decides.

| Pattern form | Meaning | Example in the demo |
|---|---|---|
| No slash, or only a trailing slash | Matches at any depth below the `.gitignore` | `*.log` matches `logs/app.log` |
| Trailing slash | Matches directories only | `__pycache__/` |
| Slash at the start or in the middle | Anchored to the directory of the `.gitignore` | `/build/` matches `build/`, not `src/build/` |
| `*`, `?`, `[a-z]` | Wildcards that do not match a `/` | `data/*` |
| `**/x`, `x/**`, `a/**/b` | Any number of directories | `models/**/*.bin` |
| Leading `!` | Negation: re-include a path that an earlier pattern excluded | `!data/README.md` |
| Leading `#` | Comment; write `\#` for a literal hash | |

**See it.** The demo's `.gitignore`:

<!-- snippet: ch04/gitignore-patterns/01-file -->
```text
$ cat -n .gitignore
     1	# caches and logs, at any depth
     2	__pycache__/
     3	*.log
     4	
     5	# build output, only at the top level
     6	/build/
     7	
     8	# datasets stay out; the README that documents them stays in
     9	data/*
    10	!data/README.md
    11	
    12	# secrets, with one documented exception
    13	.env*
    14	!.env.example
    15	
    16	# model weights under models/, at any depth
    17	models/**/*.bin
```
<!-- /snippet -->

`git check-ignore -v` is the debugger for ignore rules. For each path it prints the source file, the line number and the pattern that decided:

<!-- snippet: ch04/gitignore-patterns/02-check-ignore -->
```text
# Output: <source>:<line>:<pattern> TAB <path>. With -n, a path that matches no pattern prints "::".
$ git check-ignore -v -n src/__pycache__/app.cpython-314.pyc logs/app.log build/out.txt src/build/helper.py
.gitignore:2:__pycache__/	src/__pycache__/app.cpython-314.pyc
.gitignore:3:*.log	logs/app.log
.gitignore:6:/build/	build/out.txt
::	src/build/helper.py
$ git check-ignore -v -n data/tickets.jsonl data/README.md .env .env.local .env.example
.gitignore:9:data/*	data/tickets.jsonl
.gitignore:10:!data/README.md	data/README.md
.gitignore:13:.env*	.env
.gitignore:13:.env*	.env.local
.gitignore:14:!.env.example	.env.example
$ git check-ignore -v -n models/v1/model.bin models/v1/checkpoints/step-100.bin models/v1/card.md
.gitignore:17:models/**/*.bin	models/v1/model.bin
.gitignore:17:models/**/*.bin	models/v1/checkpoints/step-100.bin
::	models/v1/card.md
```
<!-- /snippet -->

Read it line by line. `/build/` on line 6 ignores the top-level `build/` and not `src/build/helper.py`, because the leading slash anchors it. `.env.example` matched line 13 and then line 14; the later line wins, and because that line is a negation the path is not ignored. A match on a `!` pattern means "not ignored", so read the pattern, not only the fact that there is output.

**Negation has a hard limit.** The manual states that "it is not possible to re-include a file if a parent directory of that file is excluded", because Git does not look inside an excluded directory at all. Change `data/*` (ignore the things in `data`) to `data/` (ignore the directory):

<!-- snippet: ch04/gitignore-patterns/04-negation-limit -->
```text
# Edit line 10 from "data/*" to "data/": the directory itself is now excluded.
$ grep -n 'data' .gitignore
8:# datasets stay out; the README that documents them stays in
9:data/
10:!data/README.md
$ git check-ignore -v data/README.md
.gitignore:9:data/	data/README.md
$ git status --short --untracked-files=all data
```
<!-- /snippet -->

Line 10 still says `!data/README.md`, and it no longer has any effect. To keep one file inside an otherwise ignored directory, exclude the directory's contents (`data/*`), not the directory.

**Precedence between files.** A `.gitignore` deeper in the tree overrides the ones above it:

<!-- snippet: ch04/gitignore-patterns/05-nested -->
```text
# A .gitignore in a subdirectory overrides the ones above it, for paths below it.
$ printf '!*.log\n' > experiments/.gitignore
$ git check-ignore -v -n experiments/run1/train.log logs/app.log
experiments/.gitignore:1:!*.log	experiments/run1/train.log
.gitignore:3:*.log	logs/app.log
```
<!-- /snippet -->

The two personal sources never travel with the repository. In the lab, `XDG_CONFIG_HOME` points into the sandbox; on your machine the default global file is `~/.config/git/ignore`:

<!-- snippet: ch04/gitignore-patterns/06-personal -->
```text
# Patterns for this clone only, never committed: .git/info/exclude
$ printf 'scratch/\n' >> .git/info/exclude
# Patterns for every repository on this machine: the file named by core.excludesFile.
# Its default is $XDG_CONFIG_HOME/git/ignore, or ~/.config/git/ignore when that variable is unset.
$ mkdir -p "$XDG_CONFIG_HOME/git"
$ printf '.DS_Store\n.idea/\n*.ipynb\n' > "$XDG_CONFIG_HOME/git/ignore"
$ git check-ignore -v scratch/try.py .DS_Store notebooks/scratch.ipynb
.git/info/exclude:7:scratch/	scratch/try.py
$LAB/ch04/gitignore-patterns/home/.config/git/ignore:1:.DS_Store	.DS_Store
$LAB/ch04/gitignore-patterns/home/.config/git/ignore:3:*.ipynb	notebooks/scratch.ipynb
```
<!-- /snippet -->

And the repository outranks both personal files, so a project can insist on tracking something that one developer ignores globally:

<!-- snippet: ch04/gitignore-patterns/07-precedence -->
```text
# The repository wants one notebook tracked. A per-directory .gitignore outranks the personal files.
$ printf '\n!notebooks/report.ipynb\n' >> .gitignore
$ git check-ignore -v -n notebooks/report.ipynb notebooks/scratch.ipynb
.gitignore:19:!notebooks/report.ipynb	notebooks/report.ipynb
$LAB/ch04/gitignore-patterns/home/.config/git/ignore:3:*.ipynb	notebooks/scratch.ipynb
$ git status --short --untracked-files=all notebooks
?? notebooks/report.ipynb
```
<!-- /snippet -->

**Inside `.git`.** Ignore rules leave no trace in the index or the object database. `.gitignore` is an ordinary tracked file; `.git/info/exclude` is a plain file that `git init` creates with a few comment lines; neither is consulted for a path that has an index entry.

**In production.** For an AI/ML repository the shared `.gitignore` usually starts from a language template and adds what the template lacks. GitHub's Python template covers interpreter, packaging, environment and tool caches and has nothing specific to machine learning ([Python.gitignore](https://github.com/github/gitignore/blob/main/Python.gitignore)). The Phase 0 research for this course lists the usual additions: data directories, checkpoint and export formats (`*.pt`, `*.pth`, `*.ckpt`, `*.safetensors`, `*.onnx`, `*.gguf`), experiment-tracker output (`wandb/`, `mlruns/`) and `.env` files, with editor and operating-system noise kept in each developer's global ignore file. Two rules keep the file honest: put a pattern in the shared file only if every developer and CI should ignore the path, and never treat the file as a security control. It hides paths from `git status`. It does not stop `git add -f`, and it does nothing about history.

> **GitHub, not Git.** The `.gitignore` template that GitHub offers when you create a repository comes from the public [github/gitignore](https://github.com/github/gitignore) collection. It is a starting file that GitHub commits for you. Git itself ships no templates and attaches no meaning to the choice.

## 4.6 The already-tracked trap

This is the eighth most-voted Git question on Stack Overflow ("How do I make Git forget about a file that was tracked, but is now in .gitignore?", 8,647 votes on 1 October 2026 according to the Phase 0 report), and it has one cause.

**See it.** The first commit of a project is made with `git add .` before any `.gitignore` exists, so `.env` is committed. The rule arrives one commit later:

<!-- snippet: ch04/ignore-tracked-trap/02-ignore-does-nothing -->
```text
$ echo '.env' > .gitignore
$ git add .gitignore
$ git commit -m "Ignore local environment file"
[main ff0b08f] Ignore local environment file
 1 file changed, 1 insertion(+)
 create mode 100644 .gitignore
$ echo 'LLM_API_KEY=lab-secret-0002' > .env
$ git status --short
 M .env
```
<!-- /snippet -->

`.env` is listed in `.gitignore` and still shows as modified. The debugger explains why:

<!-- snippet: ch04/ignore-tracked-trap/03-diagnose -->
```text
# check-ignore reports nothing for a tracked path: ignore rules are not consulted for it.
$ git check-ignore -v .env
[exit status: 1]
# Ask the same question with the index left out of it.
$ git check-ignore -v --no-index .env
.gitignore:1:.env	.env
[exit status: 0]
# List every path that is tracked and also matches an ignore pattern.
$ git ls-files --cached --ignored --exclude-standard
.env
```
<!-- /snippet -->

`check-ignore` prints nothing and exits with status 1 for a tracked path, because ignore rules are not consulted for it. `--no-index` asks the same question with the index left out and shows that the pattern itself is fine. The last command is the detector to remember: `git ls-files --cached --ignored --exclude-standard` (short: `-ci --exclude-standard`) lists every path that is tracked and also matches an ignore pattern. In a healthy repository it prints nothing.

```text
Observed behavior : .env is listed in .gitignore, yet git status reports it as modified
                    and it keeps appearing in commits.
Git state         : .env has an entry in the index. It was added before the rule existed.
Mechanism         : Ignore patterns are consulted only for paths that have no index entry:
                    when status lists untracked files and when add walks a directory.
                    A tracked path is compared with its index entry. No pattern is checked.
Root cause        : The file was tracked first and ignored second. Tracking wins.
Why Git does this : The manual defines the purpose of ignore files narrowly: "to ensure
                    that certain files not tracked by Git remain untracked". What is
                    tracked changes only when a command says so (git add, git rm).
Correct fix       : git rm --cached <path>, commit, keep the pattern in .gitignore.
                    Treat any secret in the file as leaked and rotate it.
Prevention        : Write .gitignore before the first "git add ."; read git status before
                    the first commit; make CI fail when
                    "git ls-files -ci --exclude-standard" prints anything.
```

**The fix.** 🟡 `git rm --cached` removes the index entry and leaves the file on disk:

<!-- snippet: ch04/ignore-tracked-trap/04-fix -->
```text
$ git rm --cached .env
rm '.env'
$ git status --short --ignored
D  .env
!! .env
$ git commit -m "Stop tracking .env"
[main b0ddc57] Stop tracking .env
 1 file changed, 1 deletion(-)
 delete mode 100644 .env
$ git ls-files
.gitignore
src/app.py
$ cat .env
LLM_API_KEY=lab-secret-0002
```
<!-- /snippet -->

Between the `rm` and the commit, status shows the path twice: `D ` because the index no longer has what HEAD has, and `!!` because the file on disk is now an untracked path that matches a pattern. After the commit the file is still on disk with your content, and later edits are invisible to status.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git rm --cached <path>` | unchanged | entry for `<path>` removed | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git commit` afterwards | unchanged | unchanged | new commit whose tree lacks `<path>` | moves to the new commit | reflogs of HEAD and the branch gain an entry | unchanged until you push | unchanged until you push |

**What the fix does not do.** Two things, and both have caused incidents.

First, it does not remove the file from history. Every earlier commit still contains it:

<!-- snippet: ch04/ignore-tracked-trap/06-history-still-has-it -->
```text
# The fix changed the index and the new commit. It did not change any earlier commit.
$ git log --oneline -- .env
b0ddc57 Stop tracking .env
cd1e384 Add service skeleton
$ git show HEAD~1:.env
LLM_API_KEY=lab-secret-0001
```
<!-- /snippet -->

If the file held a credential, the credential is in every clone and, once pushed, on the server. Removing the path from the next commit changes nothing about that. The order of operations for a leaked secret is to revoke or rotate it first; Chapter 21 (Security) covers the full response.

Second, the fix is a deletion commit, and Git applies deletions to working trees. A teammate who cloned while `.env` was tracked loses her copy when she pulls:

<!-- snippet: ch04/ignore-tracked-trap/07-teammate -->
```text
# Asha cloned while .env was still tracked. Her local runs read that file.
$ cd ../asha-clone
$ ls -A
.env
.git
.gitignore
src
$ git pull
From $LAB/ch04/ignore-tracked-trap/support-bot
   ff0b08f..b0ddc57  main        -> origin/main
 * [new branch]      release-1.0 -> origin/release-1.0
Updating ff0b08f..b0ddc57
Fast-forward
 .env | 1 -
 1 file changed, 1 deletion(-)
 delete mode 100644 .env
$ ls -A
.git
.gitignore
src
# The content is still in the previous commit, so she can get her file back as an ignored file.
$ git restore --source=HEAD~1 .env
$ git status --short --ignored
!! .env
```
<!-- /snippet -->

From Git's point of view this is correct: the path was tracked in her HEAD, unmodified, and is absent from the new commit, so it is removed like any other deleted file. She can take the content back out of the previous commit with `git restore --source=HEAD~1 .env`; the file is then untracked and ignored, which is the state you wanted for everyone. If she had edited her `.env`, the pull would have stopped with "Your local changes to the following files would be overwritten by merge" instead. Announce a fix of this kind before you push it, with those two commands in the message.

A third consequence, for ignored files in general, is in section 4.16.

## 4.7 Restoring paths: `git restore`

**In one sentence.** 🔴 `git restore <path>` overwrites files in the working tree with a stored version: the version in the index by default, the version in a commit with `--source`.

**Analogy.** "Revert to saved" in an editor, where "saved" means "last staged". The analogy breaks twice: there is no undo afterwards, and "saved" is the index, not the last commit, which surprises people who have staged something and forgotten.

**Precisely.** Two choices define a restore ([git-restore](https://git-scm.com/docs/git-restore)):

- **Where the content comes from.** Without `--source`: the index, or HEAD if `--staged` is given. With `--source=<tree>`: that commit or tree.
- **Where it is written.** The working tree by default (`--worktree`, `-W`); the index with `--staged` (`-S`); both when both options are given.

The command needs at least one pathspec, and the default mode is "no overlay": a tracked path that does not exist in the source is removed, so that the destination matches the source exactly.

**Inside `.git`.** Restoring the working tree from the index reads the blob that the index entry names and writes it to disk. No object is created and no ref moves, so no reflog records the event. The content that was overwritten is not saved anywhere.

**See it.** One staged line, one unstaged line:

<!-- snippet: ch04/restore-paths/01-from-index -->
```text
# Stage one change, then make a second change that is not staged.
$ echo 'max_tokens: 512' >> config/settings.yaml
$ git add config/settings.yaml
$ echo 'debug: true' >> config/settings.yaml
$ git status --short
MM config/settings.yaml
# Default source is the index: the unstaged line goes, the staged line stays.
$ git restore config/settings.yaml
$ cat config/settings.yaml
model: small-v1
top_k: 5
max_tokens: 512
$ git status --short
M  config/settings.yaml
```
<!-- /snippet -->

The file now equals the index, not HEAD: the staged `max_tokens` line survived and `debug: true` is gone. With `--source` the content comes from a commit and, without `--staged`, only the working tree is written:

<!-- snippet: ch04/restore-paths/02-from-head -->
```text
# With --source, the content comes from a commit. Only the working tree is written.
$ git restore --source=HEAD config/settings.yaml
$ cat config/settings.yaml
model: small-v1
top_k: 5
$ git status --short
MM config/settings.yaml
# Add --staged to write the index as well. Now all three trees agree.
$ git restore --source=HEAD --staged --worktree config/settings.yaml
$ git status --short
```
<!-- /snippet -->

After the first command the status is `MM`: the index still holds the staged line, and the working tree now lacks it, so both comparisons differ. `--staged --worktree` writes both places and the path is clean. Any commit can be the source:

<!-- snippet: ch04/restore-paths/04-older-commit -->
```text
$ git log --oneline
3139437 Raise top_k to 5
aab6b8e Add service skeleton
$ git restore --source=HEAD~1 config/settings.yaml
$ cat config/settings.yaml
model: small-v1
top_k: 3
$ git status --short
 M config/settings.yaml
$ git diff
diff --git a/config/settings.yaml b/config/settings.yaml
index 4da99e3..9b521fd 100644
--- a/config/settings.yaml
+++ b/config/settings.yaml
@@ -1,2 +1,2 @@
 model: small-v1
-top_k: 5
+top_k: 3
$ git restore config/settings.yaml
```
<!-- /snippet -->

Older scripts use `git checkout` for the same job, with one difference that matters:

<!-- snippet: ch04/restore-paths/05-checkout-equivalent -->
```text
# The older spelling. With a commit named, "git checkout" writes the index too.
$ git checkout HEAD~1 -- config/settings.yaml
$ git status --short
M  config/settings.yaml
$ git checkout HEAD -- config/settings.yaml
$ git status --short
```
<!-- /snippet -->

`git checkout <commit> -- <path>` writes the index as well as the working tree (`M ` above), where `git restore --source=<commit> <path>` wrote only the working tree (` M` in the previous transcript).

| Task | Current command | Older spelling |
|---|---|---|
| Discard unstaged changes | `git restore <path>` | `git checkout -- <path>` |
| Take a path from a commit into index and working tree | `git restore --source=<commit> --staged --worktree <path>` | `git checkout <commit> -- <path>` |
| Take a path from a commit into the working tree only | `git restore --source=<commit> <path>` | none in one step |
| Unstage (Chapter 5) | `git restore --staged <path>` | `git reset HEAD <path>` |

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git restore <path>` | `<path>` overwritten with the index version; unstaged changes destroyed | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git restore --source=<commit> <path>` | `<path>` overwritten with the version in `<commit>`; tracked paths under `<path>` that `<commit>` lacks are deleted | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git restore --source=<commit> --staged --worktree <path>` | as above | entries under `<path>` replaced by those of `<commit>` | unchanged | unchanged | unchanged | unchanged | unchanged |

**What survives.** The command is 🔴 because the overwritten content has no other copy, with one exception worth knowing. Anything that was ever staged went into the object database when `git add` ran:

<!-- snippet: ch04/restore-paths/06-what-survives -->
```text
# The staged line from the first step was written into the object database by "git add".
$ git fsck
dangling blob e4eb0e6d146a5b1eb62d3a52301f262836a0a224
$ git cat-file -p $(git fsck | cut -d" " -f3)
model: small-v1
top_k: 5
max_tokens: 512
# The line "debug: true" was never added. No object holds it. It is gone.
```
<!-- /snippet -->

`git fsck` reports a dangling blob: an object that no ref, commit or index entry points to. It is the staged version from the first transcript. The unstaged `debug: true` line was never added, so nothing holds it. Dangling objects are removed by garbage collection after a grace period (`gc.pruneExpire`, two weeks by default), so this is a rescue route, not a storage plan. Chapter 13 (Recovery) builds on it.

For this 🔴 command:

- **What it changes:** files in the working tree (and index entries with `--staged`).
- **What it can destroy:** every unstaged change in the named paths, without confirmation.
- **How to preview:** `git diff -- <path>` shows exactly what a restore from the index will discard; `git diff <commit> -- <path>` shows it for `--source=<commit>`.
- **How to recover:** not through Git, unless the content was staged or committed at some point. Editor history and backups are outside Git.
- **When it is appropriate:** after you have read the diff and decided that the changes are worthless. When in doubt, commit to a throwaway branch or stash (Chapter 11, Reset, Revert, Restore) instead: both keep the content.

**In production.** `git restore .` at the top level of a repository is the working-tree half of `git reset --hard`. The usual trigger is frustration during a failed experiment, and the usual loss is the one useful change among twenty useless ones. Use `git restore -p` to discard hunk by hunk when the changes are mixed.

## 4.8 Moving and removing files: `git mv` and `git rm`

**In one sentence.** `git mv` and `git rm` do in one step what you can do in two: change the working tree with `mv` or `rm`, then tell the index.

**Precisely.** 🟢 `git mv <source> <destination>` renames the file on disk and renames its index entry. 🟡 `git rm <path>` deletes the file on disk and removes its index entry; it refuses when the file's content is not safely stored in HEAD. Neither creates a commit: "the index is updated after successful completion, but the change must still be committed" ([git-mv](https://git-scm.com/docs/git-mv)).

**See it.** The index before and after a `git mv`:

<!-- snippet: ch04/mv-rm-renames/01-git-mv -->
```text
$ git ls-files --stage src
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 9d77f9cf9e4a6e1da622b599a95cd3afc3ee77c1 0	src/retriever.py
$ git mv src/retriever.py src/search.py
$ git status --short
R  src/retriever.py -> src/search.py
$ git ls-files --stage src
100644 63df51b788f2464137e0f30355056e42a320f705 0	src/app.py
100644 9d77f9cf9e4a6e1da622b599a95cd3afc3ee77c1 0	src/search.py
# Same blob ID, new path. The tree that this index would produce:
$ git write-tree
566379be59e0cde72aa450cfea467a891457268c
```
<!-- /snippet -->

The entry kept its blob ID and changed its path. `git write-tree` prints the ID of the tree that this index describes (Chapter 5, section 5.2). Now undo everything and perform the rename with shell commands:

<!-- snippet: ch04/mv-rm-renames/02-same-as-manual -->
```text
# Undo, then do the same rename with plain shell commands.
$ git restore --staged --worktree --source=HEAD .
$ git status --short
$ mv src/retriever.py src/search.py
$ git status --short
 D src/retriever.py
?? src/search.py
$ git add -A src
$ git status --short
R  src/retriever.py -> src/search.py
$ git write-tree
566379be59e0cde72aa450cfea467a891457268c
```
<!-- /snippet -->

The tree ID is identical, `566379b…` both times. That is the proof that `git mv` adds nothing that `mv` plus `git add -A` does not: the two routes produce the same index, byte for byte in what a commit would record.

`git rm` has a safety check that plain `rm` lacks:

<!-- snippet: ch04/mv-rm-renames/07-git-rm -->
```text
$ git rm docs/old-notes.md
rm 'docs/old-notes.md'
$ git status --short
D  docs/old-notes.md
$ ls docs
runbook.md
# git rm refuses to delete content that exists nowhere else.
$ echo 'Escalation contacts.' >> docs/runbook.md
$ git rm docs/runbook.md
error: the following file has local modifications:
    docs/runbook.md
(use --cached to keep the file, or -f to force removal)
[exit status: 1]
$ git rm --cached docs/runbook.md
rm 'docs/runbook.md'
$ git status --short
D  docs/old-notes.md
D  docs/runbook.md
?? docs/
```
<!-- /snippet -->

The first removal went through because the file matched HEAD, so the content is recoverable. The second was refused because `docs/runbook.md` had a modification that exists nowhere else. `-f` overrides the check and is 🔴 for that reason. `--cached` removes only the index entry.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git mv a b` | `a` renamed to `b` | entry `a` removed, entry `b` added with the same blob ID | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git rm <path>` | file deleted; its directory too if that leaves it empty | entry removed | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git rm --cached <path>` | unchanged | entry removed | unchanged | unchanged | unchanged | unchanged | unchanged |

Two behaviors found while writing the demos for this chapter are worth knowing before they surprise you. `git rm` deletes a directory when it removes the last file in it (section 4.11). And `git mv` does not create a missing destination directory: `git mv README.md docs/README.md` fails with "renaming 'README.md' failed: No such file or directory" when `docs/` does not exist.

## 4.9 Why Git does not record renames

**In one sentence.** A commit stores a snapshot of paths and contents, so there is no place in it where "this file used to be called that" could be written; a rename is a conclusion that Git draws later by comparing two snapshots.

**Precisely.** The Git User's Manual: "a commit does not itself contain any information about what actually changed; all changes are calculated by comparing the contents of the tree referred to by this commit with the trees associated with its parents. In particular, Git does not attempt to record file renames explicitly, though it can identify cases where the existence of the same file data at changing paths suggests a rename" ([user-manual](https://github.com/git/git/blob/v2.56.0/Documentation/user-manual.adoc)).

**See it.** Commit the rename from the previous section and look inside the commit:

<!-- snippet: ch04/mv-rm-renames/03-commit-has-no-rename -->
```text
$ git commit -m "Rename retriever module to search"
[main a7a3aae] Rename retriever module to search
 1 file changed, 0 insertions(+), 0 deletions(-)
 rename src/{retriever.py => search.py} (100%)
$ git cat-file -p HEAD
tree 566379be59e0cde72aa450cfea467a891457268c
parent f518810d6545244f37e647a360377229b00b306e
author Lab User <you@example.com> 1788756300 +0530
committer Lab User <you@example.com> 1788756300 +0530

Rename retriever module to search
$ git ls-tree -r HEAD
100644 blob 4dddde5373611e10f9ec6bc328a25ae216552487	docs/old-notes.md
100644 blob 3e9f19511d48a09c7080a74f7f78b97f62e2d153	docs/runbook.md
100644 blob 63df51b788f2464137e0f30355056e42a320f705	src/app.py
100644 blob 9d77f9cf9e4a6e1da622b599a95cd3afc3ee77c1	src/search.py
```
<!-- /snippet -->

The summary line says `rename src/{retriever.py => search.py} (100%)`, but the commit object has a tree, a parent, two identities and a message, and the tree has four paths. No field mentions a rename. The word comes from the comparison:

<!-- snippet: ch04/mv-rm-renames/04-detected-on-demand -->
```text
# The rename is computed when two snapshots are compared.
$ git diff --name-status HEAD~1 HEAD
R100	src/retriever.py	src/search.py
$ git diff --name-status --no-renames HEAD~1 HEAD
D	src/retriever.py
A	src/search.py
```
<!-- /snippet -->

`R100` means "a deleted path and an added path whose contents are 100% similar". Turn detection off and the same two commits show a deletion and an addition. When a commit renames and edits, the similarity drops, and whether you see a rename depends on a threshold:

<!-- snippet: ch04/mv-rm-renames/05-rename-and-edit -->
```text
# Rename and edit in one commit: similarity drops below 100.
$ git diff --name-status HEAD~1 HEAD
R096	src/search.py	src/vector_search.py
$ git diff --name-status -M98% HEAD~1 HEAD
D	src/search.py
A	src/vector_search.py
```
<!-- /snippet -->

The default threshold is 50% (`-M50%`). History that follows a file depends on the same detection:

<!-- snippet: ch04/mv-rm-renames/06-follow -->
```text
$ git log --oneline -- src/vector_search.py
8ae9ce9 Rename search module and raise TOP_K
$ git log --oneline --follow -- src/vector_search.py
8ae9ce9 Rename search module and raise TOP_K
a7a3aae Rename retriever module to search
f518810 Add service skeleton
```
<!-- /snippet -->

Without `--follow`, the log of `src/vector_search.py` starts at the commit where that path first appears. With it, Git detects the two renames and continues. `--follow` works for a single file only.

**In production.** Three habits follow from detection being a heuristic. Rename in one commit and edit in the next when the edit is large: a rename combined with a rewrite can fall below the threshold, and then `git log --follow`, `git blame` and the rename handling in merges (Chapter 8, Merge) all treat it as an unrelated new file. Expect very large moves to look like delete plus add: the exhaustive part of detection is skipped when the number of candidate files exceeds `diff.renameLimit`, whose default the 2.55 manual gives as 1000. And do not look for a "rename" flag to audit: there is none in the data.

## 4.10 File modes and symbolic links

**In one sentence.** Besides its content, Git records one more thing about a file: its type and whether it is executable.

**Precisely.** An index entry and a tree entry carry a mode. For files there are three: `100644` (regular file), `100755` (executable file) and `120000` (symbolic link). The User's Manual puts it bluntly: "Git actually only pays attention to the executable bit." Owner, group, the other permission bits and timestamps are not recorded.

**See it.**

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

A mode change is a change: status shows ` M`, and the diff has no content lines, only `old mode` and `new mode`. After `git add`, the entry has mode `100755` and the same blob ID as before. The mode is not part of the blob.

When the filesystem cannot express the bit, set it in the index directly:

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

After `git add --chmod=+x` the index says executable and the disk does not, so status reports the file as modified in the working tree (`MM`). With `core.fileMode=false` Git stops comparing the bit, which is what `git init` and `git clone` configure when they detect a filesystem that does not keep it.

A symbolic link is stored as a blob whose content is the link text:

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

The blob is 13 bytes long: the characters of `settings.yaml`. Git never follows the link and never stores the target's content under the link's path.

**In production.** A script that was made executable on one machine and committed from another where the bit was not set fails in CI with "Permission denied". Check with `git ls-files --stage <path>`, fix with `git update-index --chmod=+x <path>` or `git add --chmod=+x <path>`, and commit. For links, remember that the stored text is whatever you typed: a link to an absolute path on your laptop is committed faithfully and is broken on every other machine. On a filesystem without symbolic links (`core.symlinks=false`) the link is checked out as a small plain file containing the link text.

## 4.11 Empty directories

**In one sentence.** Git tracks files; a directory exists in a commit only because a file path passes through it.

**See it.**

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

Two empty directories exist on disk. Status reports a clean working tree, `git add data` adds nothing and says nothing, and the index has no entry under `data/`. There is nothing to add: the index is a list of files (Chapter 5).

The convention is to give the directory a file. A `.gitignore` inside it does two jobs at once:

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

The pattern `*` ignores everything in `data/raw/`, and `!.gitignore` keeps the placeholder itself tracked. A dataset dropped into the directory stays out of status. You will also meet empty files named `.gitkeep`; the name means nothing to Git and appears nowhere in its documentation.

The rule works in the other direction too. `git rm` on the last tracked file removes the directory, as section 4.8 noted, and a checkout of a commit that no longer has any file in a directory removes that directory unless untracked files are in it.

**In production.** Code that expects `logs/`, `outputs/` or `data/processed/` to exist after a clone will fail on a fresh CI runner. Either commit a placeholder or, better, have the code create the directory it writes to.

## 4.12 The case-insensitive filesystem trap

**In one sentence.** Git treats `Config.py` and `config.py` as two different paths, the default macOS filesystem treats them as one file, and the setting that reconciles the two (`core.ignoreCase`) hides case-only renames.

**Precisely.** Git stores file names as byte sequences and performs no case folding ([gitfaq](https://git-scm.com/docs/gitfaq)). When `git init` or `git clone` creates a repository, it probes the filesystem and sets `core.ignoreCase=true` if names are case-insensitive, as they are on a default APFS volume. The manual describes the effect: if a directory listing finds `makefile` when Git expects `Makefile`, "Git will assume it is really the same file, and continue to remember it as `Makefile`". It also calls the variable internal and warns that changing it by hand "may result in unexpected behavior". The transcripts in this section assume a case-insensitive volume; on a case-sensitive one they come out differently, and that difference is the lesson.

**See it.**

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

The file on disk is now `config.py`. Status is clean, `git add -A` records nothing, and the index still says `src/Config.py`. Every commit you make will keep the old name, and every Linux machine will check out the old name. The rename has to be made in the index:

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

The mirror image of the problem arrives from the other side. Someone on Linux commits two files whose names differ only by case, which is legal there. On a Mac both names cannot exist:

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

Git warns during the clone, one file lands on disk, and the other path is reported as modified for ever: when Git reads `src/Config.py` it gets the content of `src/config.py`. No `git restore` can fix it, because writing either file overwrites the other. The documented fix is to stop tracking one of the names:

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

The one-line detector, `git ls-files | tr '[:upper:]' '[:lower:]' | sort | uniq -d`, is cheap enough to run in CI on every pull request.

**In production.** This trap is specific to teams that develop on macOS or Windows and deploy on Linux, which describes most backend and ML teams. Python imports, Java class files and Docker `COPY` paths are all case-sensitive on Linux. macOS has a second, rarer cousin: it may hand back a file name in a different Unicode normalization form than the one you wrote, and `core.precomposeUnicode` (set to true by `git init` on macOS, as the first transcript of the course shows) exists to undo that.

## 4.13 Line endings, in brief

Git stores the bytes it is given. A file saved with Windows line endings (CRLF) is stored with them unless an attribute or a configuration value tells Git to convert. `git ls-files --eol` shows what is in the index, what is in the working tree, and which attribute applies:

<!-- snippet: ch04/line-endings/01-eol -->
```text
# i/ is the content in the index, w/ the content in the working tree, attr/ the attribute in force.
$ git ls-files --eol
i/lf    w/lf    attr/                 	requirements.txt
i/crlf  w/crlf  attr/                 	scripts/deploy.bat
```
<!-- /snippet -->

When an editor on another platform rewrites every line ending, the whole file becomes one change:

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

Three lines "changed" although no character you can see did, and the second command confirms that the only difference is the carriage return at the end of each line. Such a commit makes `git blame` useless for the file and produces conflicts on every line for anyone with pending work. The durable fix is a committed `.gitattributes` with `* text=auto` and one `git add --renormalize .`, so that the repository holds LF for everyone regardless of personal settings. Chapter 14C (Stash internals, rerere, attributes, hooks) covers attributes, and `core.autocrlf` with its limits, in full.

## 4.14 `git clean`

**In one sentence.** 🔴 `git clean` deletes untracked files from the working tree, which makes it the one everyday command that removes data Git has no copy of.

**Analogy.** Sweeping the workbench into the bin. Everything that came out of the cabinet is safe, because the cabinet still has it. Everything else is gone, and Git cannot tell a wood shaving from the prototype you spent a week on. The analogy holds well; its only weakness is that a real bin can be searched afterwards.

**Precisely.** By default `git clean` removes untracked files that are not ignored, in the current directory and below, and does not enter untracked directories ([git-clean](https://git-scm.com/docs/git-clean)). The options widen that:

| Option | Effect |
|---|---|
| `-n`, `--dry-run` | Show what would be removed and remove nothing |
| `-f`, `--force` | Required to delete anything, because `clean.requireForce` defaults to true. A second `-f` allows deleting untracked directories that contain their own `.git` |
| `-d` | Also remove untracked directories |
| `-X` (capital) | Remove only ignored files: build products and caches, keeping files you created by hand |
| `-x` (small) | Do not use ignore rules at all: remove untracked and ignored files alike |
| `-e <pattern>` | Add an exclude pattern for this run |
| `-i` | Interactive mode: choose what to delete |

`-x` and `-X` differ by one keystroke and by which of your files survive.

**Inside `.git`.** Nothing changes. Clean reads the index to learn which paths are tracked and the ignore rules to classify the rest. It writes no object, moves no ref, and leaves no record of what it deleted.

**See it.** The starting point: three untracked paths and four ignored ones.

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

Without `-f`, `-n` or `-i`, Git refuses to run. Always start with the dry runs:

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

Each added option widens the list. The last one includes `.env` and `data/`. The directory `vendor/tokenizer` is a repository of its own and is skipped by every run with fewer than two `-f`.

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

`git fsck` prints nothing. There is no dangling blob to rescue, because none of these files was ever added. That is the whole difference between this command and the losses in section 4.7.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git clean -n ...` | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git clean -f` | untracked, non-ignored files in the current directory deleted | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git clean -f -d -x` | every untracked path below the current directory deleted, ignored ones included | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |

For this 🔴 command:

- **What it changes:** the working tree only.
- **What it can destroy:** untracked files; with `-d` untracked directories; with `-x` also ignored files such as `.env`, downloaded datasets, model checkpoints, virtual environments and local databases.
- **How to preview:** the same command with `-n` in place of `-f`. Read every line of the output.
- **How to recover:** not through Git. Backups, or editor history for single files.
- **When it is appropriate:** to prove a build from a pristine tree, to reset a CI workspace, to clear generated files that the build tool's own clean target misses. Prefer `-X` to `-x`, pass a pathspec (`git clean -n -d -X -- build/`) to narrow the blast radius, and protect what must survive with `-e`.

**In production.** The typical loss is in an ML repository where `data/`, `checkpoints/` and `.env` are ignored on purpose. Someone copies `git clean -fdx` from a "fix your broken build" answer, and the ignored files, which were the only copies, are deleted in under a second. The command did what its options say. The defence is the habit of running `-n` first and of keeping irreplaceable data outside the working tree or in real storage (Chapter 28, AI/ML Workflows).

## 4.15 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A file listed in `.gitignore` keeps showing as modified | `git check-ignore -v <path>` prints nothing; `git ls-files -ci --exclude-standard` lists it: the path is tracked | `git rm --cached <path>`, commit; rotate any secret | `.gitignore` before the first `git add .`; the detector in CI |
| A new file is not offered by `git status` | `git check-ignore -v <path>` names the pattern and the file it lives in, which may be `.git/info/exclude` or your global ignore file | Fix the pattern, add a `!` exception, or `git add -f` once | Keep personal patterns narrow; keep shared patterns anchored (`/build/`) |
| A `!` exception has no effect | The parent directory is excluded (`data/` instead of `data/*`) | Exclude the contents, not the directory | Test new patterns with `git check-ignore -v -n` |
| A teammate's local config vanished after `git pull` | The pull contained a commit that stopped tracking the file (`git log --diff-filter=D --name-only`) | `git restore --source=<commit before> <path>` | Announce "stop tracking" commits with the restore command |
| Edits disappeared after `git restore <path>` | Nothing to diagnose: the working tree was overwritten from the index | `git fsck` finds versions that were staged at some point; otherwise editor history | `git diff` before restore; stash or commit when unsure |
| `git status` is clean but the build differs from CI | Ignored or untracked files in the working tree (`git status --ignored`, `git clean -ndx`) | Build in a fresh clone or worktree | Never build release artifacts from a developer working tree |
| A file is "modified" immediately after a clone on macOS | Two tracked paths differ only by case (the clone printed a warning) | `git rm --cached` one of them, commit, `git restore .` | Case-collision check in CI |
| A renamed file still has its old name on Linux | Case-only rename made with `mv` on macOS; `git ls-files` shows the old name | `git mv old new`, commit | Rename with `git mv` |
| A script fails in CI with "Permission denied" | `git ls-files --stage <path>` shows `100644` | `git update-index --chmod=+x <path>`, commit | Check modes in review; `git diff` shows `old mode`/`new mode` |
| Every line of a file shows as changed | `git ls-files --eol <path>` shows `i/lf w/crlf`; `git diff --ignore-cr-at-eol` is empty | Restore the endings; adopt `.gitattributes` (Chapter 14C) | `* text=auto` committed for everyone |
| History of a file stops at a rename | The rename commit also rewrote the file; similarity fell below the threshold (`git log --follow -M30% -- <path>` to test) | None for existing history; lower the threshold when reading | Rename and edit in separate commits |
| Expected directory missing after clone | Git does not track empty directories | Commit a placeholder or create the directory in code | Same |

## 4.16 When not to use it, and dangerous edge cases

**Ignored means expendable.** Git treats an ignored file as something it may overwrite without asking. Continue the story of section 4.6. Your `.env` is now ignored and holds a value that exists nowhere else. The branch `release-1.0` was cut while `.env` was still tracked:

<!-- snippet: ch04/ignore-tracked-trap/08-ignored-is-expendable -->
```text
# Back in your clone. Your .env is ignored now and holds a value that exists nowhere else.
$ cd ../support-bot
$ cat .env
LLM_API_KEY=lab-secret-0003
# release-1.0 was cut while .env was still tracked.
$ git switch release-1.0
Switched to branch 'release-1.0'
$ cat .env
LLM_API_KEY=lab-secret-0001
$ git switch main
Switched to branch 'main'
$ cat .env
cat: .env: No such file or directory
[exit status: 1]
```
<!-- /snippet -->

Switching to the old branch replaced your file with the tracked version, silently. Switching back deleted it, because the path is tracked there and absent here. Your value is gone and no object holds it.

```text
Observed behavior : An ignored local file was replaced, then deleted, by two branch switches.
                    No warning was printed.
Git state         : On main the path is untracked and ignored. On release-1.0 it is tracked.
Mechanism         : To check out release-1.0 Git must write the tracked file. An untracked file
                    in the way normally stops the checkout. An ignored file does not:
                    --overwrite-ignore is the default for checkout, switch and merge.
Root cause        : The same path is ignored on one branch and tracked on another.
Why Git does this : Ignored files are assumed to be regenerable build products, and refusing
                    to switch branches because of them would make ignoring pointless.
Correct fix       : None for the lost content. Recreate the file.
Prevention        : Give private files a name that no commit on any branch has ever tracked
                    (settings.local.yaml, not the formerly tracked settings.yaml). Keep
                    irreplaceable data outside the working tree. Use
                    git switch --no-overwrite-ignore when moving to old branches.
```

The guard exists, as an option:

<!-- snippet: ch04/ignore-tracked-trap/09-no-overwrite-ignore -->
```text
$ echo 'LLM_API_KEY=lab-secret-0004' > .env
$ git switch --no-overwrite-ignore release-1.0
error: The following untracked working tree files would be overwritten by checkout:
	.env
Please move or remove them before you switch branches.
Aborting
[exit status: 1]
$ cat .env
LLM_API_KEY=lab-secret-0004
```
<!-- /snippet -->

`--no-overwrite-ignore` is documented for [git checkout](https://git-scm.com/docs/git-checkout) and `git merge`; `git switch -h` on 2.55 lists it as well.

**`git restore --source` on a directory deletes files.** Because restore runs in no-overlay mode, `git restore --source=HEAD~5 src/` removes every tracked file under `src/` that did not exist five commits ago, together with any unstaged changes in them. Name files, not directories, when you take content from an old commit, or add `--overlay` to forbid deletions.

**`git clean` in the wrong directory.** Clean works from the current directory down. Run at the top level with `-d -x` it reaches everything. Run it from the narrowest directory that contains what you want gone.

**`git rm --cached` is a deletion for everyone else.** It is the right tool to stop tracking a file and the wrong tool to unstage a change (Chapter 5, section 5.9).

**When not to use `.gitignore`.** Not as protection for secrets: it is advice to `git status` and `git add`, nothing more. Not for files the team must share. And not for "ignore my local edits to a tracked file": Git has no such feature, and the two index bits that look like one are covered in Chapter 5, section 5.12.

**When not to use `git restore` or `git clean`.** When you cannot say what will be lost. Both have a preview (`git diff`, `git clean -n`). A stash or a throwaway commit costs seconds and keeps everything.

## 4.17 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git status`, `git check-ignore`, `git ls-files`, `git diff` | 🟢 SAFE | Nothing (status may refresh cached file information in the index) | not needed | not needed |
| `git add <path>`, `git add -f <path>` | 🟢 SAFE | Writes a blob and an index entry | `git add -n <path>` | `git restore --staged <path>` |
| `git mv <a> <b>` | 🟢 SAFE | Renames the file and its index entry | `git mv -n <a> <b>` | `git mv <b> <a>` |
| `git add --chmod=+x`, `git update-index --chmod=+x` | 🟢 SAFE | Mode in the index entry | `git ls-files --stage <path>` | the opposite `--chmod=-x` |
| `git rm <path>` | 🟡 CAUTION | Deletes the file and its index entry; refuses if content is not in HEAD | `git rm -n <path>` | `git restore --staged --worktree <path>` |
| `git rm --cached <path>` | 🟡 CAUTION | Removes the index entry; the next commit deletes the path for everyone who pulls | `git rm --cached -n <path>` | `git restore --staged <path>` before committing |
| `git rm -f <path>` | 🔴 DANGEROUS | As `git rm`, without the check; destroys uncommitted changes in the file | `git diff HEAD -- <path>` | none for unstaged content |
| `git restore <path>`, `git checkout -- <path>` | 🔴 DANGEROUS | Overwrites working tree files from the index | `git diff -- <path>` | none for content never staged; `git fsck` for content that was |
| `git restore --source=<commit> [--staged] [--worktree] <path>` | 🔴 DANGEROUS | Overwrites working tree files (and index entries) from a commit; deletes tracked paths the commit lacks | `git diff <commit> -- <path>` | as above |
| `git clean -n` | 🟢 SAFE | Nothing | it is the preview | not needed |
| `git clean -f [-d] [-X or -x]` | 🔴 DANGEROUS | Deletes untracked (and with `-x`/`-X` ignored) files | the same options with `-n` | none through Git |
| `git switch <branch>` when an ignored file is tracked on that branch | 🔴 DANGEROUS | Overwrites the ignored file | `git ls-tree -r --name-only <branch>` compared with `git status --ignored` | none; prevent with `--no-overwrite-ignore` |

## 4.18 Version notes

> **Version note.** Older behavior: `git checkout -- <path>` restored files and `git checkout <branch>` switched branches. Current behavior: `git restore` and `git switch` do the two jobs separately; `git checkout` still works and is not scheduled for removal. Since: introduced in Git 2.23 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.23.0.adoc)), no longer labelled experimental from Git 2.51 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc)). Recommended: write `restore` and `switch`, read `checkout`. Apple's Git 2.50.1 at `/usr/bin/git` still prints the experimental label.

> **Version note.** Older behavior: status hints suggested `git reset HEAD <file>...` to unstage and `git checkout -- <file>...` to discard, and many tutorials and the Pro Git chapter on recording changes still show those hints. Current behavior: Git 2.55 prints the `git restore` forms shown in this chapter. Since: the exact release in which the hints changed was not verified for this chapter. Recommended: treat old hints as valid spellings of the same operations.

> **Version note.** Older behavior: none; the command did not exist. Current behavior: `git check-ignore` explains which pattern ignores a path, and `--no-index` diagnoses paths that were tracked by mistake. Since: Git 1.8.2 for the command and 1.8.5 for `--no-index`, according to the release notes shipped with Git 2.55.0. Recommended: use it before editing any ignore file.

> **Version note.** Older behavior: `git config --get core.ignoreCase`. Current behavior: `git config get core.ignoreCase`, as used in this chapter; the old form still works. Since: Git 2.46. Recommended: the subcommand form, remembering that it fails on Git older than 2.46.

> **Unverified.** The release in which `git status --porcelain=v2` appeared, and the release in which `git mv` began to handle case-only renames on case-insensitive filesystems, were not found in the sources available for this chapter. Both behaviors were run on Git 2.55.0 and are shown above.

## 4.19 Practice

- **Lab 2.3, the `.gitignore` trap and its fix**, in the [Module 2 lab manual](../lab-manual/m02-working-tree-index-head.md). Do it now: it uses only this chapter.
- Labs 2.1, 2.2 and 2.4 in the same file need [Chapter 5](ch05-index.md).
- Replay any transcript of this chapter with `labs/run ch04/<demo>`, for example `labs/run ch04/gitignore-patterns`. The sandbox stays in place afterwards, so you can continue by hand in it.
- Five short drills, each in a sandbox left by a replay:
  1. In `ch04/gitignore-patterns`, write one pattern that ignores `*.bin` only directly inside `models/v1/` and prove it with `git check-ignore -v -n`.
  2. In `ch04/status-anatomy`, predict the output of `git status --short` after `git restore --staged src/retriever.py`, then run it.
  3. In `ch04/mv-rm-renames`, find the smallest `-M` percentage at which the second rename is still reported as `R`.
  4. In `ch04/clean`, list what `git clean -n -d -X -- src` would remove and explain each line.
  5. In `ch04/case-insensitive`, run `git config get core.ignoreCase` in each of the three repositories and explain the values.

## 4.20 Interview questions

1. Define tracked, untracked and ignored in terms of the index. Can a path be tracked and ignored at the same time?
2. `git status` shows the same file under "Changes to be committed" and under "Changes not staged for commit". Explain exactly which comparisons produced the two lines.
3. A developer added `config/secrets.yaml` to `.gitignore` and it is still in every new commit. Walk through your diagnosis commands, the fix, and the two things the fix does not solve.
4. What are the four sources of ignore patterns, in precedence order, and which would you use for `.DS_Store`, for `build/`, and for a personal scratch directory?
5. Why can `!data/README.md` fail to re-include a file, and how do you write the rule so that it works?
6. What does `git restore file.py` take its content from? How does that differ from `git restore --source=HEAD file.py`, and from `git checkout HEAD -- file.py`?
7. After `git restore` destroyed some edits, a colleague says "use the reflog". What is wrong with that advice, and under what condition can part of the work still be recovered?
8. Prove to me that Git does not store renames. Then explain what `R087` in a diff means and name two features that depend on it.
9. A Python module imports fine on macOS and fails on the Linux CI runner after someone renamed it. What happened inside Git, and how do you prevent a recurrence?
10. Compare `git clean -fdX` with `git clean -fdx`. Which one would you allow in a CI cleanup step for an ML repository, and what would you run first?
11. Why did switching branches delete a file that was listed in `.gitignore`?
12. What does Git record about file permissions, and how do you make a script executable for everyone when your own filesystem cannot express that?

## 4.21 Sources

**Primary sources**

- [git-status](https://git-scm.com/docs/git-status), [gitignore](https://git-scm.com/docs/gitignore), [git-check-ignore](https://git-scm.com/docs/git-check-ignore), [git-restore](https://git-scm.com/docs/git-restore), [git-rm](https://git-scm.com/docs/git-rm), [git-mv](https://git-scm.com/docs/git-mv), [git-clean](https://git-scm.com/docs/git-clean), [git-ls-files](https://git-scm.com/docs/git-ls-files), [git-checkout](https://git-scm.com/docs/git-checkout), [git-diff](https://git-scm.com/docs/git-diff), [git-config](https://git-scm.com/docs/git-config). The local copies (`git help -m <command>`) are the Git 2.55.0 text that the transcripts were checked against.
- [gitfaq](https://git-scm.com/docs/gitfaq): "I asked Git to ignore various files, yet they are still tracked" and "Why do I have a file that's always modified?".
- [gitglossary](https://git-scm.com/docs/gitglossary) and [gitattributes](https://git-scm.com/docs/gitattributes).
- [Git User's Manual](https://github.com/git/git/blob/v2.56.0/Documentation/user-manual.adoc): renames are not recorded; only the executable bit is.
- Release notes: [2.23.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.23.0.adoc), [2.51.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc), and 1.8.2 and 1.8.5 as shipped with Git 2.55.0 (`Documentation/RelNotes/` in the Git source tree).

**Secondary sources**

- Pro Git, [Recording Changes to the Repository](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository). Caveat: its status transcripts mix the current `git restore --staged` hint with the older `git reset HEAD <file>` hint.
- GitHub Docs, [Ignoring files](https://docs.github.com/en/get-started/git-basics/ignoring-files), and the [github/gitignore](https://github.com/github/gitignore) template collection.
- GitHub Docs, [Removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository), for what a committed secret requires beyond `git rm --cached`.
- Perez De Rosso and Jackson, [Purposes, Concepts, Misfits, and a Redesign of Git](https://spderosso.github.io/oopsla16.pdf) (OOPSLA 2016): file tracking, untracking a file, file rename and empty directory are four of its seven "operational misfits".
- The Phase 0 report of this course, sections 4, 12 and 15, for the Stack Overflow figures and the ML ignore list.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- [Git Tutorial for Beginners: Learn Git in One Video](https://www.youtube.com/watch?v=AB3J8ufDYHQ), CodeWithHarry, Hindi, 12 July 2026: covers staging, ignoring files and tracking empty directories with `git restore --staged`. Caveats from the report: no reset, revert or reflog; local `master`; an early "branch is a copy" phrase that the video corrects later.
- [How to Undo Mistakes With Git Using the Command Line](https://www.youtube.com/watch?v=lX9hsdsAeTk), Tobias Günther for freeCodeCamp, 24 November 2020: `git restore`, including `-p`. Caveat: `master` naming.

**Further reading**

- [git-update-index](https://git-scm.com/docs/git-update-index), section "Untracked cache", and the "Untracked files and performance" section of git-status, for why status is slow in very large working trees. Chapter 26 (Performance) continues from there.
