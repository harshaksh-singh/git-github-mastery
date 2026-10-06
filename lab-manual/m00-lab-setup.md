# Module 0 labs: Lab setup and working method

> **Baseline.** Git 2.55.0 on macOS. Every transcript is real output from the replay scripts in `labs/ch01/`. Read [Chapter 1](../textbook/ch01-fundamentals.md), sections 1.6 to 1.9, first.

## How to run these labs

Both labs are typed by hand. Open a terminal in the course folder, the directory that contains `textbook/`, `labs/` and `lab-manual/`. Lab 0.1 starts in that normal shell and then opens the lab shell; Lab 0.2 takes place inside the lab shell:

```bash
labs/shell m00        # opens your shell in $LAB/hands-on/m00 with an isolated Git configuration
exit                  # leaves it again
```

Inside the lab shell, Git reads and writes the configuration file `$LAB/hands-on/home/.gitconfig` and never your real `~/.gitconfig`. The clock is real there, so any commit you make gets an ID that differs from the book; Module 0 makes no commits, so nothing differs here.

Three differences between your terminal and the transcripts:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command to see its exit status.
- Lines that start with `#` are notes from the replay script.
- `$LAB` stands for the lab root, `~/git-mastery-labs` unless you set `GIT_MASTERY_LABS`. The replays run in their own sandbox under `$LAB/ch01/`; you work under `$LAB/hands-on/m00/`, so paths in your output differ in that part.

To see a lab exactly as printed, replay it: `labs/run ch01/lab-00-2-empty-git-dir`. Answers to the questions are in [solutions/m00-lab-answers.md](../solutions/m00-lab-answers.md). Write your own first.

## Lab 0.1: Verify the toolchain and build the sandbox

### Objective

Establish which Git and which GitHub CLI run in your shell, create the lab root by running the smoke test, open the lab shell, and prove that Git inside it reads and writes only the sandbox configuration.

### Prerequisites

Chapter 1, sections 1.6 to 1.8. A terminal in the course folder. Nothing else: this lab creates the lab root.

### Setup

None. The replay script for this lab, `labs/ch01/lab-00-1-toolchain.sh`, is marked *volatile*: its output depends on the machine (search path, installed versions, build options), so `labs/verify-all.sh` checks only that it runs. The transcripts below were produced on the author's Mac. Where yours should differ, the text says so.

### Commands

Step 1, in the normal shell. Which programs answer to `git` and `gh`?

```bash
which -a git
git --version
/usr/bin/git --version
git version --build-options
gh --version
```

Step 2, still in the normal shell. The smoke test creates the lab root, replays the reference demo and compares its output with the book:

```bash
labs/verify-all.sh ch00
```

Step 3. Open the lab shell and look at the configuration that Git sees inside it. Then write a setting and find out where it landed:

```bash
labs/shell m00
echo "$GIT_CONFIG_GLOBAL"
git config list --show-origin --show-scope
git config get user.email
git config set --global alias.lab-probe "status --short --branch"
git config get --show-origin --show-scope alias.lab-probe
exit
```

Back in the normal shell, confirm that your real configuration did not receive the alias:

```bash
git config get --global alias.lab-probe; echo $?
```

### Expected output

<!-- snippet: ch01/lab-00-1-toolchain/01-which -->
```text
$ which -a git
/opt/homebrew/bin/git
/usr/bin/git
/opt/homebrew/bin/git
$ git --version
git version 2.55.0
$ /usr/bin/git --version
git version 2.50.1 (Apple Git-155)
```
<!-- /snippet -->

The first line of `which -a git` is the Git that runs when you type `git`. On this Mac it is the Homebrew build; the third line repeats it because the Homebrew directory appears twice in the search path, which is harmless. If your first line is `/usr/bin/git`, stop and fix your `PATH` before going on: the book's commands assume Git 2.55.

<!-- snippet: ch01/lab-00-1-toolchain/02-build-options -->
```text
$ git version --build-options
git version 2.55.0
cpu: arm64
no commit associated with this build
sizeof-long: 8
sizeof-size_t: 8
shell-path: /bin/sh
rust: disabled
feature: fsmonitor--daemon
gettext: enabled
libcurl: 8.7.1
zlib: 1.2.12
SHA-1: SHA1_DC
SHA-256: SHA256_BLK
default-ref-format: files
default-hash: sha1
```
<!-- /snippet -->

`gh --version` is not replayed, because no script in this course runs the GitHub CLI. Compare its first line with Chapter 1, section 1.6: 2.88.1 was installed there, and the section explains why an upgrade is advised before the GitHub chapters.

<!-- snippet: ch01/lab-00-1-toolchain/03-smoke-test -->
```text
# Run from the course folder.
$ labs/verify-all.sh ch00
PASS      ch00/smoke-test
----
pass=1 volatile=0 fail=0  (git 2.55.0)
```
<!-- /snippet -->

<!-- snippet: ch01/lab-00-1-toolchain/04-sandbox -->
```text
# Typed inside the lab shell. The replay prints the paths of its own sandbox.
$ echo "$GIT_CONFIG_GLOBAL"
$LAB/ch01/lab-00-1-toolchain/home/.gitconfig
$ git config list --show-origin --show-scope
global	file:$LAB/ch01/lab-00-1-toolchain/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch01/lab-00-1-toolchain/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch01/lab-00-1-toolchain/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch01/lab-00-1-toolchain/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch01/lab-00-1-toolchain/home/.gitconfig	gc.reflogexpireunreachable=never
$ git config get user.email
you@example.com
$ git config set --global alias.lab-probe "status --short --branch"
$ git config get --show-origin --show-scope alias.lab-probe
global	file:$LAB/ch01/lab-00-1-toolchain/home/.gitconfig	status --short --branch
```
<!-- /snippet -->

Two differences are expected in the lab shell. The file is `$LAB/hands-on/home/.gitconfig`, not a path under `$LAB/ch01/`. And the listing has three lines, not five: `labs/shell` writes `user.name`, `user.email` and `init.defaultBranch`, while a replay sandbox also sets `gc.reflogExpire` and `gc.reflogExpireUnreachable` to `never` (Chapter 1, section 1.7 explains why the replays need them and the lab shell does not). The last command of step 3 prints nothing and exits with status 1 in your normal shell: the key does not exist in your real configuration.

### What happened internally

`which -a git` walks the directories in `PATH` in order and prints every `git` it finds; the shell runs the first. `git version --build-options` reports what the binary was built with: here SHA-1 object names (`default-hash: sha1`) and refs stored as files (`default-ref-format: files`), the two defaults this book relies on when it reads `.git` with `cat`.

`labs/verify-all.sh` created `$LAB` with a marker file, `.git-mastery-lab-root`, then ran `labs/ch00/smoke-test.sh` with its output redirected into a temporary directory and compared every snippet it produced with the stored files in `labs/ch00/out/smoke-test/`, byte for byte. `PASS` means that your machine reproduces the book.

`labs/shell` exports `GIT_CONFIG_GLOBAL`, which replaces `~/.gitconfig` and `~/.config/git/config` with the sandbox file, and `GIT_CONFIG_NOSYSTEM=1`, which skips the system-wide file ([git(1)](https://git-scm.com/docs/git), environment variables). `--show-origin` prints the file each setting came from, which is how you prove isolation. `GIT_CEILING_DIRECTORIES` stops Git from searching above `$LAB` for a `.git` directory, so a sandbox can never act on a repository that contains the lab root.

### Checkpoint

Before you continue, all three must hold:

- `labs/verify-all.sh ch00` printed `PASS      ch00/smoke-test` and `fail=0`.
- Inside the lab shell, every line of `git config list --show-origin --show-scope` names a file under `$LAB`; no line names your home directory.
- Outside the lab shell, `git config get --global alias.lab-probe` printed nothing and `echo $?` printed `1`.

### Failure scenario

A shell whose search path finds the Apple Git first. Inside the lab shell, put `/usr/bin` in front of `PATH` and try a command that exists only in newer Git:

```bash
labs/shell m00
PATH="/usr/bin:$PATH"
which git
git --version
git history -h; echo $?
```

<!-- snippet: ch01/lab-00-1-toolchain/05-wrong-git -->
```text
# Failure scenario: a shell whose PATH finds the Apple Git first.
$ PATH="/usr/bin:$PATH"
$ which git
/usr/bin/git
$ git --version
git version 2.50.1 (Apple Git-155)
$ git history -h
git: 'history' is not a git command. See 'git --help'.
[exit status: 1]
```
<!-- /snippet -->

Git 2.50.1 has no `git history`, so it reports an unknown command and exits with status 1. Every command in this book that needs Git 2.51 or later fails the same way in such a shell.

### Recovery

Put the Homebrew directory back in front, or leave the shell with `exit` and open a new one, which has the original `PATH`:

```bash
PATH="/opt/homebrew/bin:$PATH"
which git
```

<!-- snippet: ch01/lab-00-1-toolchain/06-recover -->
```text
# Recovery: put the Homebrew directory back in front.
$ PATH="/opt/homebrew/bin:$PATH"
$ which git
/opt/homebrew/bin/git
```
<!-- /snippet -->

### Verification

```bash
git --version
git history -h; echo $?
```

<!-- snippet: ch01/lab-00-1-toolchain/07-verify -->
```text
$ git --version
git version 2.55.0
$ git history -h
usage: git history fixup <commit> [--dry-run] [--update-refs=(branches|head)] [--reedit-message] [--empty=(drop|keep|abort)]
   or: git history reword <commit> [--dry-run] [--update-refs=(branches|head)]
   or: git history split <commit> [--dry-run] [--update-refs=(branches|head)] [--] [<pathspec>...]

[exit status: 129]
```
<!-- /snippet -->

Git 2.55.0 answers, and `git history -h` prints its usage. The exit status 129 is Git's code for "usage was printed"; the Phase 0 report notes that Git 2.56 changed `-h` to exit with 0 ([report](../reports/Git%20and%20GitHub%20mastery%20research.md), section 1), so after an upgrade this line reads `0`.

### Questions

1. Your shell found the Homebrew Git first. Name three situations in which a Git command on this same Mac would run the Apple Git instead, and the one-line check that tells you which Git ran.
2. `git config list --show-origin --show-scope` showed three settings in the lab shell and five in the replay. Explain the two extra lines and why the lab shell does not need them.
3. Two environment variables make the isolation work. Name them, and say which configuration file Git would still read if only `GIT_CONFIG_GLOBAL` were set.
4. `labs/verify-all.sh ch00` printed PASS. State precisely what was compared, and name two things that could make it print FAIL on a machine where Git works correctly.
5. `git history -h` exited with status 1 in the failure scenario and with 129 in the verification. What does each status mean, and why may the second change after an upgrade?

## Lab 0.2: Read every file in an empty `.git`

### Objective

Create an empty repository, read every file that `git init` wrote, ask Git what it sees, and then find out by experiment which parts of `.git` Git cannot live without.

### Prerequisites

Lab 0.1. Chapter 1, section 1.9, steps 1 and 2. Keep `git help repository-layout` open: it documents every entry you are about to read.

### Setup

```bash
labs/shell m00
rm -rf tour          # only if a previous attempt left one behind
```

### Commands

Create the repository and list what it contains, directories first, then files:

```bash
git init tour
cd tour
find .git -type d | sort
find .git -type f | sort
```

Read the files that are not hook samples, and the top of one sample:

```bash
cat .git/HEAD
cat .git/config
cat .git/description
cat .git/info/exclude
head -n 8 .git/hooks/pre-commit.sample
```

Ask Git what it makes of the repository:

```bash
git status
git symbolic-ref HEAD
git rev-parse --git-dir --show-toplevel
git count-objects -v
git log; echo $?
```

### Expected output

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

Nine directories and eighteen files, fourteen of them hook samples. `objects/` and `refs/` contain only empty subdirectories.

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

### What happened internally

Every entry has a documented role ([gitrepository-layout](https://git-scm.com/docs/gitrepository-layout)):

| Entry | What it is | Written by |
|---|---|---|
| `HEAD` | A symbolic ref: the branch you are on, here `refs/heads/main`, which does not exist yet. The layout manual says a valid repository must have this file | `git init` |
| `config` | Settings of this repository. `core.repositoryformatversion`, `filemode`, `bare` and `logallrefupdates` are written for every repository; `ignorecase` and `precomposeunicode` were probed for this filesystem, a case-insensitive volume | `git init` |
| `description` | A one-line name used by the gitweb web interface and by nothing in this course | the template |
| `hooks/*.sample` | Example hook scripts. Each is disabled until the `.sample` suffix is removed (Chapter 14C) | the template |
| `info/exclude` | Ignore patterns for this clone only, as opposed to a tracked `.gitignore` ([Chapter 4](../textbook/ch04-working-tree.md)) | the template |
| `objects/`, `objects/info/`, `objects/pack/` | The object database, empty | `git init` |
| `refs/`, `refs/heads/`, `refs/tags/` | Where branches and tags will be stored, empty | `git init` |

The template is a directory of files that `git init` copies; the three entries marked "the template" are conveniences, not machinery.

### Checkpoint

<!-- snippet: ch01/lab-00-2-empty-git-dir/03-ask-git -->
```text
$ git status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
$ git symbolic-ref HEAD
refs/heads/main
$ git rev-parse --git-dir --show-toplevel
.git
$LAB/ch01/lab-00-2-empty-git-dir/tour
$ git count-objects -v
count: 0
size: 0
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0
size-garbage: 0
$ git log
fatal: your current branch 'main' does not have any commits yet
[exit status: 128]
```
<!-- /snippet -->

Your output must match this apart from the path: `git status` says "No commits yet", `git symbolic-ref HEAD` prints `refs/heads/main`, every counter of `git count-objects -v` is 0, and `git log` fails with exit status 128 because the branch is *unborn*: HEAD names it, but no ref exists for it. If your HEAD names `master`, the lab shell did not provide `init.defaultBranch`; check `git config list --show-origin --show-scope`.

### Failure scenario

Take the repository apart in four steps, and after each one ask `git status` whether it still sees a repository. Parts 2 and 3 move things aside and put them back; part 4 leaves HEAD missing.

```bash
rm -r .git/hooks .git/info .git/description
git status; echo $?

mv .git/config ../config.saved
git status; echo $?
git config list --local; echo $?
mv ../config.saved .git/config

mv .git/refs ../refs.saved
git status; echo $?
mv ../refs.saved .git/refs
mv .git/objects ../objects.saved
git status; echo $?
mv ../objects.saved .git/objects

mv .git/HEAD ../HEAD.saved
git status; echo $?
git symbolic-ref HEAD refs/heads/main; echo $?
```

<!-- snippet: ch01/lab-00-2-empty-git-dir/04-optional-files -->
```text
# Failure scenario, part 1: delete what came from the template.
$ rm -r .git/hooks .git/info .git/description
$ git status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch01/lab-00-2-empty-git-dir/05-config -->
```text
# Part 2: set the configuration file aside, look, and put it back.
$ mv .git/config ../config.saved
$ git status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
[exit status: 0]
$ git config list --local
fatal: unable to read config file '.git/config': No such file or directory
[exit status: 128]
$ mv ../config.saved .git/config
```
<!-- /snippet -->

<!-- snippet: ch01/lab-00-2-empty-git-dir/06-refs-objects -->
```text
# Part 3: set refs/ aside and put it back; then the same with objects/.
$ mv .git/refs ../refs.saved
$ git status
fatal: not a git repository (or any of the parent directories): .git
[exit status: 128]
$ mv ../refs.saved .git/refs
$ mv .git/objects ../objects.saved
$ git status
fatal: not a git repository (or any of the parent directories): .git
[exit status: 128]
$ mv ../objects.saved .git/objects
```
<!-- /snippet -->

<!-- snippet: ch01/lab-00-2-empty-git-dir/07-break-head -->
```text
# Part 4: take HEAD away, and leave it away.
$ mv .git/HEAD ../HEAD.saved
$ git status
fatal: not a git repository (or any of the parent directories): .git
[exit status: 128]
$ git symbolic-ref HEAD refs/heads/main
fatal: not a git repository (or any of the parent directories): .git
[exit status: 128]
```
<!-- /snippet -->

The template files and the configuration file are optional for recognising a repository. `refs/`, `objects/` and `HEAD` are not: without any one of them Git reports "not a git repository", and the plumbing command that could rewrite HEAD fails for the same reason. That matches the test in Git's source: a directory is a repository when it has a valid `HEAD`, an `objects/` directory and a `refs/` directory ([setup.c](https://github.com/git/git/blob/v2.55.0/setup.c), `is_git_directory`).

### Recovery

HEAD is a one-line text file. Write it back, then let `git init` recreate the template files; the manual says that running it in an existing repository is safe and will not overwrite what is already there ([git-init](https://git-scm.com/docs/git-init)):

```bash
printf 'ref: refs/heads/main\n' > .git/HEAD
git status; echo $?
git init
```

<!-- snippet: ch01/lab-00-2-empty-git-dir/08-recover -->
```text
# Recovery: HEAD is a one-line text file. Write it back, then let git init restore the template files.
$ printf 'ref: refs/heads/main\n' > .git/HEAD
$ git status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
[exit status: 0]
$ git init
Reinitialized existing Git repository in $LAB/ch01/lab-00-2-empty-git-dir/tour/.git/
```
<!-- /snippet -->

### Verification

```bash
find .git -type d | sort
git symbolic-ref HEAD
cmp .git/HEAD ../HEAD.saved; echo $?
git fsck; echo $?
```

<!-- snippet: ch01/lab-00-2-empty-git-dir/09-verify -->
```text
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
$ git symbolic-ref HEAD
refs/heads/main
$ cmp .git/HEAD ../HEAD.saved
[exit status: 0]
$ git fsck
notice: No default references
[exit status: 0]
```
<!-- /snippet -->

The directories are back, HEAD resolves, `cmp` finds the rewritten HEAD byte-identical to the original (exit status 0), and `git fsck` exits with 0. Its notice means that no ref exists yet to start a check from, which is the normal state of an empty repository.

### Questions

1. Which three parts of `.git` did the experiment show to be required, what does Git say when one is missing, and which documented rule do they correspond to?
2. Moving `config` aside changed nothing in `git status`. Why would deleting it still be a bad idea in a real repository, and does `git init` bring everything back?
3. Why was `git symbolic-ref HEAD refs/heads/main` unable to repair HEAD, and what would `git init` have done to HEAD in a repository where you had been on a branch other than `main`?
4. `git fsck` printed "notice: No default references" after the repair. Is that an error, and what makes the notice disappear?
5. Every counter of `git count-objects -v` was 0. After `git add` of one small file, which counters change, and to what?
