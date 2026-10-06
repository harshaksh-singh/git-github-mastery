# Chapter 1: Fundamentals

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch01/`.

## 1.1 Why this matters

A deploy pipeline goes red on a Friday evening. The engineer on call says the fix is committed and can show the commit on screen. The pipeline fails again on the same line. Your CTO asks three questions:

1. What exactly is in the commit that the pipeline built?
2. Where does that commit exist right now: on the laptop, on the server, or on both?
3. What is the smallest change that makes the main branch correct, and how will we know that it worked?

None of these is a question about commands. Each is a question about state: which bytes Git recorded, which names point at them, and which machine holds them. An engineer who knows fifty commands and cannot answer these questions will try things until something appears to work. An engineer who can answer them needs about ten read-only commands and a method.

This chapter builds that base: a toolchain you can vouch for, a sandbox where mistakes cost nothing, a first repository watched from the inside, a diagnosis ritual, and a root-cause framework that every later chapter reuses. Section 1.12 solves the Friday problem with them.

## 1.2 The problem version control solves

**In one sentence.** A version control system records successive states of a set of files so that you can recall any state, compare any two, and see who recorded each one, when, and why.

**Analogy.** A bound laboratory notebook: pages are numbered, dated and signed, and a correction is a new page, never an erased one. The analogy breaks in two places: a notebook is one sequence kept by one person, while a repository holds many lines of work that people extend in parallel and later join; and each recorded state in Git is the whole project, not that day's notes.

**Precisely.** Four capabilities define the category.

| Capability | Question it answers |
|---|---|
| Recall | What did the project look like when release 2.3 was built? |
| Compare | What differs between what runs in production and what I have here? |
| Attribute | Who changed this line, when, and with what explanation? |
| Integrate | Two people changed the project at the same time. What is the combined result, and where do their changes collide? |

The first three are bookkeeping. The fourth is the reason the tool has a learning curve: combining states that were produced independently needs a model of history in which "independently" has a precise meaning. [Chapter 2](ch02-mental-model.md) gives you that model.

**In production.** The evaluation score of an LLM application drops from one week to the next. To explain the drop you need the prompt templates, the evaluation configuration and the scoring code exactly as they were when last week's number was produced. If they live in one repository and the report recorded a commit ID, one command restores that state. If they live on a shared drive, the question has no reliable answer. Datasets and model weights need additional tools (Chapter 22: Git LFS, Chapter 28: AI/ML workflows).

## 1.3 Centralized versus distributed

**In one sentence.** In a centralized system the history lives on one server and each developer holds one checked-out version; in a distributed system every developer's copy contains the history, and "the server" is one more copy that the team agrees to treat as the meeting point.

**Analogy.** A centralized system is a reference library: the books stay in the building, and when the building is closed nobody reads. A distributed system gives every reader a copy of the whole library. The analogy breaks because library copies never need to agree again, while repositories must: each copy accumulates its own additions, and exchanging them is an explicit act that can find two copies in disagreement.

**Precisely.** The classification follows Pro Git ([About Version Control](https://git-scm.com/book/en/v2/Getting-Started-About-Version-Control)).

| | Centralized (CVS, Subversion, Perforce) | Distributed (Git, Mercurial) |
|---|---|---|
| Where the history lives | On one server | In every clone |
| Recording a change | A network operation against the server | A local write; publishing is a separate step |
| Server unreachable | Nobody can record changes or collaborate | Local work continues; the exchange waits |
| Server disk lost, no backups | The history is gone | Every clone still holds what it had fetched |

Three consequences shape daily work with Git.

1. **Commit and publish are different operations.** `git commit` writes to the repository on your disk. `git push` copies commits to another repository. "It is committed" and "it is on the server" are independent facts, checked with different commands.
2. **Your view of the server is a cached copy.** A name such as `origin/main` records "the last-known state of a branch in a remote repository" ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)), as of your last exchange with it. Chapter 12: Remote Operations is built on this fact.
3. **Nothing in Git makes one repository the authority.** The team does, by convention and through permissions on the hosting platform.

**Inside `.git`.** The whole repository, meaning the history and every name in it, is the `.git` directory at the top of your project. A clone is a copy of another repository's objects and names. The copy on a server is normally a *bare* repository: the same contents with no checked-out files beside them.

**Picture.**

```text
 Centralized                                Distributed

  +--------------------+                    +--------------------------+
  | server             |                    | server (bare repository) |
  | the only history   |                    | history                  |
  +--------------------+                    +--------------------------+
      ^            ^                           ^   |             ^   |
      | commit     | commit              push  |   | fetch  push |   | fetch
      | (network)  | (network)                 |   v             |   v
  +---------+  +---------+              +--------------+   +--------------+
  | Asha    |  | Ravi    |              | Asha         |   | Ravi         |
  | one     |  | one     |              | history +    |   | history +    |
  | version |  | version |              | one version  |   | one version  |
  +---------+  +---------+              +--------------+   +--------------+
                                         commit = local     commit = local
```

**In production.** If GitHub is unreachable for an hour, you can still commit, create branches, compare versions and search history, because all of that reads your own `.git`. You cannot push, fetch, open a pull request or start a workflow. The reverse also holds: a commit that exists only on one laptop is one disk failure away from not existing. Distributed means that copies are possible, not that they are made for you.

## 1.4 Git's design goals

Git was written in 2005 for the Linux kernel, after the kernel project lost free use of the proprietary tool BitKeeper. Pro Git lists the goals of the new system ([A Short History of Git](https://git-scm.com/book/en/v2/Getting-Started-A-Short-History-of-Git)). Each goal explains a design decision you will meet later.

| Goal as listed in Pro Git | Design decision it led to | Where you study it |
|---|---|---|
| Speed | Almost every operation reads local files | This chapter |
| Simple design | Four object types named by a hash of their content, plus names that point at them | Chapter 2; Chapter 3: Git Internals |
| Strong support for non-linear development (thousands of parallel branches) | A branch is one small name that points at a commit, so creating one costs almost nothing | Chapter 7: Branches; Chapter 8: Merge |
| Fully distributed | Every clone has the history; fetch and push exchange objects and update names | Chapter 12: Remote Operations |
| Able to handle large projects like the Linux kernel efficiently | Compressed pack files; later, partial clone and sparse checkout | Chapter 3; Chapter 26: Performance |

Git's manual describes it as "a fast, scalable, distributed revision control system with an unusually rich command set that provides both high-level operations and full access to internals" ([git(1)](https://git-scm.com/docs/git)). The high-level commands (`git add`, `git commit`, `git merge`) are called *porcelain*. The low-level ones (`git hash-object`, `git update-ref`) are called *plumbing*. This course uses plumbing to prove what porcelain did.

Two things are absent from the goals, and both surprise people. Git has no user accounts and no permissions: the layer that hosts a repository decides who may read or write it. And Git stores content, not intentions: it does not record that a file was renamed, and it does not track empty directories (Chapter 4: Working Tree).

## 1.5 Git the tool versus GitHub the platform

**In one sentence.** Git is a program on your machine that stores history in a `.git` directory; GitHub is a hosted service that stores Git repositories and surrounds them with its own objects: accounts, permissions, pull requests, reviews, rulesets and workflows.

**Analogy.** Git is a file format with its editor; GitHub is a document-management service where such files are stored, discussed and approved. The analogy breaks because GitHub also runs Git on its servers and performs Git operations for you: pressing a merge button creates commits. Platform actions change Git data, so you must know which layer did what.

**Precisely.** For each thing you will meet, the table gives the layer that owns it and whether it comes along with `git clone`.

| Thing | Layer | Where it lives | Arrives with a clone? |
|---|---|---|---|
| Commits, directory trees, file contents, annotated tags | Git | Objects in the repository | Yes |
| Branches and tags | Git | Names (refs) in the repository | Yes; the server's branches arrive as remote-tracking branches such as `origin/main` |
| Author and committer name and email; a signature | Git | Inside each commit | Yes |
| The "Verified" badge next to a commit | GitHub | GitHub's database: its judgement of the signature | No |
| HEAD, the index, reflogs, stashes, hooks, `.git/config` | Git, local only | Your `.git` | No; each clone has its own |
| Pull request, review, comment | GitHub | GitHub's database, plus read-only refs that GitHub creates on the server for the pull request's commits | No |
| Issue, discussion, star | GitHub | GitHub's database | No |
| Fork | GitHub | A server-side repository linked to its parent; to Git it is one more remote | Not applicable |
| Ruleset, branch protection | GitHub | Repository or organization settings | No |
| Release | GitHub | An object that points at a Git tag and adds notes and files | The tag yes, the release no |
| A workflow file under `.github/workflows/` | Git | A tracked file in commits | Yes |
| A workflow run, its logs, artifacts and secrets | GitHub Actions | GitHub | No |
| Access tokens, SSH keys, collaborator roles | GitHub | Your account and the repository settings | No |

The GitHub rows are described from the Phase 0 research report, which links the documentation page for each ([report](../reports/Git%20and%20GitHub%20mastery%20research.md), sections 2 and 12). Other hosts such as GitLab, Bitbucket and Forgejo run the same Git and surround it with different platform objects.

> **GitHub, not Git.** A pull request is not a Git feature. Git has commits, branches and merges. GitHub adds the pull request as a place to discuss a proposed merge, and performs the merge on its servers when you press the button (Chapter 17: Pull Requests).

**In production.** "The merge is blocked" has three root causes in three layers. Git stops a merge when both sides changed the same lines. GitHub stops one when a ruleset requires a review that has not been given. GitHub Actions stops one when a required check has not reported success. The symptoms look alike in a chat message and the fixes have nothing in common, so every explanation in this book names the layer that acted.

## 1.6 The two Gits on your Mac

Your Mac has two Git installations. Which one runs depends on the order of directories in the `PATH` of the shell that starts it. This transcript is specific to this machine: its lab script is marked volatile, so the verification tool checks that it runs and does not compare its output.

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

`which -a` lists every match in search order; the first line is the program that runs when you type `git`. Here it is the Homebrew build, 2.55.0. `/usr/bin/git` is the Git that Apple ships with its developer tools, 2.50.1. The third line repeats the first because the Homebrew directory appears twice in this shell's `PATH`, which is harmless.

The difference matters. Git 2.50.1 has no `git history` and no `git last-modified`, and its manual still labels `git switch` and `git restore` as experimental, a label Git removed in 2.51 ([report](../reports/Git%20and%20GitHub%20mastery%20research.md), section 1). Each installation also reads its own system-level configuration file. You meet the Apple Git in three situations: a script that calls `/usr/bin/git` by its full path, a scheduled job or graphical tool that starts with a shorter `PATH` than your terminal, and a colleague's Mac without Homebrew.

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

Three lines are worth reading now. `default-hash: sha1` means new repositories name objects with SHA-1, and `SHA-1: SHA1_DC` means the implementation detects known collision attacks. `default-ref-format: files` means branch and tag names are stored as plain files, which is why this book can show them with `cat`. Chapter 3: Git Internals covers the alternatives, SHA-256 and reftable.

> **Version note.** Older behavior: Git 2.55.0 of 29 June 2026 is what Homebrew installed here. Current behavior: the latest release is Git 2.56.0 of 28 September 2026, which adds a few commands and no security fix that 2.55.0 lacks. Since: Git 2.56. Recommended: upgrading is optional (`brew upgrade git`); this book marks what needs it as "added in Git 2.56 (not run here)". Source: [report](../reports/Git%20and%20GitHub%20mastery%20research.md), section 1.

> **GitHub, not Git.** The GitHub CLI `gh` is a separate program. Installed here: 2.88.1. Latest on 1 October 2026: 2.102.0, with six security-fix releases in between, so upgrade it (`brew upgrade gh`) before the GitHub chapters. From 2.91.0 the CLI collects pseudonymous usage telemetry unless you opt out with `gh config set telemetry disabled` or `export GH_TELEMETRY=false`. Neither was run here, because the setting does not exist in 2.88.1. Sources: [GitHub changelog](https://github.blog/changelog/2026-04-22-github-cli-opt-out-usage-telemetry/), [gh environment variables](https://cli.github.com/manual/gh_help_environment).

## 1.7 How to use this book

### Conventions

| You see | It means |
|---|---|
| **In one sentence.** **Analogy.** **Precisely.** **Inside `.git`.** **See it.** **Picture.** **In production.** | The ladder on which each important concept is taught, from plain words down to files on disk and back up to a real team |
| A transcript in a `text` block | Real output, produced by a script under `labs/` and inserted by a tool; never typed by hand |
| `$LAB` | The lab root, `~/git-mastery-labs` unless you set `GIT_MASTERY_LABS` |
| `[exit status: 1]`; a line starting with `#` | The exit status of the command above; a comment written by the script |
| A state table | What a command did to the working tree, the index, HEAD, the current branch, the rest of `.git`, the remote and GitHub |
| A root-cause box | A surprising behavior explained in seven fixed lines (section 1.10) |
| `> **Version note.**`, `> **GitHub, not Git.**`, `> **Outdated advice.**`, `> **Unverified.**` | Version-dependent behavior; a warning about which layer acts; advice from older tutorials that no longer holds; a statement that could not be confirmed |

### Three tools

Run them from the course folder, the directory that contains `textbook/`, `labs/` and `lab-manual/`. The lab manual's introduction has the details ([lab-manual/README.md](../lab-manual/README.md)).

| Tool | What it does |
|---|---|
| `labs/shell m00` | Opens your shell in `$LAB/hands-on/m00` with an isolated Git configuration and the real clock. This is where you type labs by hand. `exit` leaves it |
| `labs/run ch01/first-repo` | Replays one demo or lab with a fixed identity and clock and prints its transcript. The sandbox stays in `$LAB/ch01/first-repo` for inspection |
| `labs/verify-all.sh ch01` | Replays every script of a chapter and compares the output with the snippets printed in the book: `PASS`, `VOLATILE` or `FAIL` per script |

### Why the lab configuration is isolated

Git reads settings from several files, and one of them is your personal `~/.gitconfig`. If labs read it, your aliases and defaults would change the output; if labs wrote it, an experiment would change your real setup. The lab environment therefore points Git at a configuration file inside the sandbox and switches off the system-wide file.

**See it.** The Git environment that the lab library sets for every replay. A shell can export other variables whose names begin with `GIT_`: the course's own `GIT_MASTERY_LABS`, which only moves the lab root, or prompt settings such as `GIT_PS1_SHOWDIRTYSTATE`. The script `labs/ch01/sandbox.sh` removes those before it prints the listing, so the transcript is the same on every machine:

<!-- snippet: ch01/sandbox/01-env -->
```text
$ env | grep '^GIT_' | sort
GIT_AUTHOR_DATE=@1788755520 +0530
GIT_AUTHOR_EMAIL=you@example.com
GIT_AUTHOR_NAME=Lab User
GIT_CEILING_DIRECTORIES=$LAB:$LAB
GIT_COMMITTER_DATE=@1788755520 +0530
GIT_COMMITTER_EMAIL=you@example.com
GIT_COMMITTER_NAME=Lab User
GIT_CONFIG_GLOBAL=$LAB/ch01/sandbox/home/.gitconfig
GIT_CONFIG_NOSYSTEM=1
GIT_EDITOR=true
GIT_MERGE_AUTOEDIT=no
GIT_PAGER=cat
GIT_TERMINAL_PROMPT=0
GIT_TEST_DATE_NOW=1788755520
```
<!-- /snippet -->

| Variable | Effect | In `labs/shell` too? |
|---|---|---|
| `GIT_CONFIG_GLOBAL` | Git reads this file instead of `~/.gitconfig` | Yes |
| `GIT_CONFIG_NOSYSTEM=1` | Git skips the system-wide configuration file | Yes |
| `GIT_CEILING_DIRECTORIES` | Git stops searching for a `.git` directory at the lab root, so a sandbox never acts on a repository above it | Yes |
| `GIT_AUTHOR_DATE`, `GIT_COMMITTER_DATE` | The fixed clock | No: real clock |
| `GIT_TEST_DATE_NOW` | A variable Git's own test suite uses to fix "now" for date arithmetic, so that relative dates ("2 minutes ago") and time-based selectors (`HEAD@{5.minutes.ago}`) give the same answer on every run | No: real clock |
| `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL` and the committer pair | A fixed identity that overrides configuration | No: identity comes from the lab configuration |
| `GIT_EDITOR=true`, `GIT_PAGER=cat`, `GIT_TERMINAL_PROMPT=0` | No editor, pager or password prompt, because a script cannot answer them | No: your editor and pager work |
| `GIT_MERGE_AUTOEDIT=no` | A merge does not open an editor for its message | Yes |

Inside the sandbox, a "global" setting is global only to the sandbox:

<!-- snippet: ch01/sandbox/02-config -->
```text
$ git config list --show-origin --show-scope
global	file:$LAB/ch01/sandbox/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch01/sandbox/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch01/sandbox/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch01/sandbox/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch01/sandbox/home/.gitconfig	gc.reflogexpireunreachable=never
$ git config set --global alias.st "status --short --branch"
$ git config list --show-origin --show-scope
global	file:$LAB/ch01/sandbox/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch01/sandbox/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch01/sandbox/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch01/sandbox/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch01/sandbox/home/.gitconfig	gc.reflogexpireunreachable=never
global	file:$LAB/ch01/sandbox/home/.gitconfig	alias.st=status --short --branch
```
<!-- /snippet -->

`--show-scope` and `--show-origin` print the scope of every setting and the file it came from. The alias landed in the sandbox file; your real configuration was neither read nor written. The two `gc.reflogexpire…` lines are part of every sandbox configuration; the next subsection explains why they are there.

### Why the clock is fixed

A commit records when it was made, and the commit ID is computed from everything in the commit, including that time. The same commands run at two different moments produce different IDs. Replays pin the identity and the clock, so the IDs printed in this book are the IDs you get.

<!-- snippet: ch01/sandbox/03-clock -->
```text
$ git init -q clock && cd clock
$ git commit -q --allow-empty -m "Check the lab clock"
$ git log --format=fuller
commit c67262763db796bdaa778e529bc358323e7f96df
Author:     Lab User <you@example.com>
AuthorDate: Mon Sep 7 10:07:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:07:00 2026 +0530

    Check the lab clock
```
<!-- /snippet -->

The lab clock starts at Monday 7 September 2026, 10:00 at UTC+05:30, and advances one minute before each command. `@1788755520 +0530` in the environment listing is that clock in Git's raw format: seconds since 1 January 1970 UTC, then the time-zone offset. In `labs/shell` the clock is real, so commits you type by hand get IDs that differ from the book. Chapter 6: Commits explains why in full.

A fixed clock has a side effect that the lab environment has to neutralise, and the reason is worth knowing because it is the first example in this book of a behavior that depends on *which clock* Git reads.

```text
Observed behavior : with a fixed lab clock, some replays would print different output depending on the real date
Git state         : every commit and every reflog entry in a sandbox carries the fixed lab date
Mechanism         : two parts of Git compare reflog dates with the REAL clock, not with the commit dates:
                    1. git fsck (Git 2.53.0 and later) skips reflog entries dated later than the real "now"
                    2. git gc and git reflog expire drop reflog entries older than 90 days,
                       or older than 30 days when the commit is no longer reachable from a branch
Root cause        : a lab date in the future trips rule 1; a lab date in the past trips rule 2 once it is old enough
Why Git does this : expiry is a real-time retention policy (Chapter 13: Recovery)
Correct fix       : keep the lab clock in the past, and switch time-based reflog expiry off in the sandbox
Prevention        : the sandbox configuration sets gc.reflogExpire and gc.reflogExpireUnreachable to "never"
```

In a replay your commits therefore always behave like fresh work, on whatever day you run it. Three things follow. First, the two `gc.*` lines appear in every sandbox configuration listing in this book. Second, real repositories use Git's defaults, which Chapter 13 covers; the labs demonstrate only explicit expiry (`--expire=now`), which does not depend on any clock. Third, `GIT_TEST_DATE_NOW` pins date arithmetic only: `git fsck` and reflog expiry read the real clock regardless, which is why the configuration lines are needed as well.

> **Version note.** The `git fsck` rule exists in Git 2.53.0 and later (git/git commit `f6b262581a`, "fsck: snapshot default refs before object walk"; Chapter 3 cites the source). Apple's Git 2.50.1 on the same Mac does not apply it.

### GitHub-side material

What happens on GitHub's servers cannot be replayed on your Mac. Those parts show commands without output and describe the expected result from GitHub's documentation, with a link. For the GitHub chapters you create a free organization with public practice repositories yourself (Chapter 15: GitHub). Nothing in this book asks you to type credentials into a script.

## 1.8 Command risk labels

The first time a state-changing command appears in a chapter it carries one of three labels, and each chapter ends with a table of them.

| Label | Meaning | Examples |
|---|---|---|
| 🟢 SAFE | Reads state or only adds objects. Nothing is lost | `git status`, `git log`, `git fetch`, `git reflog`, `git commit` |
| 🟡 CAUTION | Moves refs or rewrites local history. Recoverable through the reflog if you know how | `git reset --soft`, `git rebase`, `git commit --amend` |
| 🔴 DANGEROUS | Can destroy uncommitted work, remote history, or the safety net itself | `git reset --hard`, `git clean -fd`, `git push --force` and its conditional forms `--force-with-lease` and `--force-if-includes`, `git reflog expire --expire=now --all`, `git gc --prune=now` |

Before any 🔴 command this book answers five questions: what it changes, what it can destroy, how to preview it, how to recover, and when it is appropriate. Make that your own rule: if you cannot answer the five questions, you are not ready to run the command on a repository that matters.

The labels describe the worst case. `git commit` is 🟢 because it only adds, and a wrong commit is corrected by another commit. `git reset --hard` is 🔴 because it overwrites working-tree files that were never recorded anywhere, and Git cannot bring back what it never stored.

## 1.9 A guided first repository

You will create a repository for a small evaluation harness, `rag-eval`, and list the files under `.git` after every step. The listings leave out the sample hooks, which never change. The script is `labs/ch01/first-repo.sh`; replay it with `labs/run ch01/first-repo`.

### Step 1: `git init` 🟢

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

`git init` created the directory and, inside it, `.git`. Three entries matter now. `objects/` will hold every version of every file; it is empty. `refs/` will hold branch and tag names; it is empty too. `HEAD` says which branch you are on: `refs/heads/main`. No such file exists yet under `refs/`, which is why `git status` says `No commits yet`. Git calls this an *unborn* branch. The name `main` comes from the lab configuration; section 1.13 shows what unconfigured Git chooses.

### Step 2: create files

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

Two files exist in the working tree, and `.git` holds the same four files as before. Editing files is invisible to Git until you tell it. `git status` calls the files untracked and shows `configs/` as one line because nothing inside it is tracked.

### Step 3: `git add` 🟢

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

Three files are new. `.git/index` is the index, also called the staging area: the list of what the next commit will contain. The two files under `objects/` hold the contents of `README.md` and `configs/eval.yaml`. Each object is named by a 40-digit ID, split into a two-digit directory and a 38-digit file name. `git ls-files --stage` prints the index: file mode, object ID, stage number, path. The IDs in the index are the names of the two object files. So `git add` did two things: it stored the content, and it recorded which content belongs to which path. No commit exists yet.

### Step 4: `git commit` 🟢

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

`[main (root-commit) f7c044e]` reads: on branch `main`, a commit without a parent, whose ID starts with `f7c044e`. Seven files are new.

- Three objects: the commit (`f7/c044e2…`), a tree for the top directory (`e6/21cb09…`) and a tree for `configs/` (`0d/722fc2…`). A tree is Git's record of one directory. Chapter 2 opens all three.
- `refs/heads/main`: the branch now exists.
- `logs/HEAD` and `logs/refs/heads/main`: the reflogs, journals of where HEAD and `main` have pointed.
- `COMMIT_EDITMSG`: the text of the last commit message.

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

`HEAD` still contains the branch name. The branch file contains the commit ID. That is the whole mechanism of being "on a branch": HEAD names a branch, and the branch names a commit. `git status` compares that commit, the index and the working tree, finds them identical, and reports a clean working tree.

### Step 5: a second commit

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

After the edit, `git status` lists the file under "Changes not staged for commit": the working tree differs from the index, and `git diff` shows that difference. `git add` copies the new content into the index, and `git commit` records the index.

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

`HEAD` did not change. The branch file did: it now holds `2da8d74…`. A commit moves the current branch, and HEAD follows only because it names that branch. `logs/HEAD` has one line per movement: old ID, new ID, who, when (the lab clock) and why. The first old ID is all zeros because nothing came before. Nine objects exist: five from the first commit and four from the second, namely one new file content, two new trees because `configs/` and the top directory both changed, and the commit. `README.md` was not stored a second time. Chapter 2 explains why.

**Picture.** The state after the second commit, with the abbreviated IDs from the transcript.

```text
  Working tree              Index (.git/index)              Repository (.git/objects, .git/refs)
 +-------------------+     +---------------------------+   +----------------------------------+
 | README.md         |     | README.md         3a79082 |   |  f7c044e <--- 2da8d74            |
 | configs/eval.yaml |     | configs/eval.yaml 327cd0b |   |                  ^               |
 +-------------------+     +---------------------------+   |  refs/heads/main      HEAD: main |
          |     git add          ^      |    git commit    +----------------------------------+
          +----------------------+      +-----------------------------^
```

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git init rag-eval` | Empty directory created | Does not exist yet | Created: `ref: refs/heads/main` | Does not exist (unborn) | `config`, `description`, `hooks/`, `info/`, empty `objects/` and `refs/` | unchanged | unchanged |
| Create or edit a file | Changed | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |
| `git add <path>` | unchanged | The entry for the path points at the new content | unchanged | unchanged | One new object per new file content | unchanged | unchanged |
| `git commit` | unchanged | unchanged | unchanged: still names the branch | Created, or moved to the new commit | New tree and commit objects, a line in each reflog, `COMMIT_EDITMSG` | unchanged | unchanged |

**In production.** A build server checks out a commit. It never sees your working tree or your index. A change that was edited but not added, or added but not committed, does not exist for anyone else, however real it looks in your editor.

## 1.10 The root-cause framework

Every problem in this book is handled in the same eleven steps.

```text
SYMPTOM -> OBSERVE -> COLLECT EVIDENCE -> UNDERSTAND STATE -> FORM HYPOTHESES -> TEST HYPOTHESES
        -> IDENTIFY ROOT CAUSE -> SELECT LOWEST-RISK FIX -> EXECUTE -> VERIFY -> PREVENT
```

| Step | What you do |
|---|---|
| SYMPTOM | Write down what was observed, without interpretation. "CI fails with a timeout" is a symptom; "the commit is broken" is already a guess |
| OBSERVE | Look before you touch. Start with `git status` |
| COLLECT EVIDENCE | Run the diagnosis ritual of section 1.11 and keep the output |
| UNDERSTAND STATE | State what the working tree, the index, HEAD, the branches and the remote contain |
| FORM HYPOTHESES | List every mechanism that could produce the symptom from that state. One hypothesis is a belief, not an analysis |
| TEST HYPOTHESES | For each, name the command whose output would differ if it were true, and run it |
| IDENTIFY ROOT CAUSE | Name the mechanism that survived and the layer it belongs to: Git, GitHub or GitHub Actions |
| SELECT LOWEST-RISK FIX | List the possible fixes with their risk labels. Choose the one that destroys least and is simplest to undo |
| EXECUTE | Preview, then run, one change at a time |
| VERIFY | Repeat the commands that showed the problem. The evidence must have changed for the reason you predicted |
| PREVENT | Change a habit, a setting or a rule so the problem cannot recur silently |

Two rules make the framework safe. First, everything up to and including IDENTIFY ROOT CAUSE is read-only. Most damage in Git incidents is done by a command typed before the state was understood. Second, every explanation ends in the same seven-line box, so that a reader can check whether it is complete:

```text
Observed behavior : what was seen
Git state         : what the working tree, index, HEAD, refs and remote held
Mechanism         : what Git does with that state
Root cause        : the one fact that, had it been different, would have prevented the symptom
Why Git does this : the design reason
Correct fix       : the lowest-risk change that repairs the state
Prevention        : what stops a silent recurrence
```

## 1.11 The ten-command diagnosis

COLLECT EVIDENCE always starts with the same ten commands. `git diff` is run twice, once for each of its two comparisons, so you type eleven lines. Run them every time, in this order, including when you think you already know the answer. The ritual exists because people under pressure skip the one command that would have shown the cause.

The repository below is `rag-eval` some days later, with a real problem. **Symptom:** the evaluation job in CI fails with a timeout after 60 seconds, although the commit "Raise eval timeout to 120s" is on `main`; on the author's laptop the same test passes. A bare repository on disk plays the server. The script is `labs/ch01/diagnosis.sh`.

**1. `git status`: where am I, and what is uncommitted?**

<!-- snippet: ch01/diagnosis/01-status -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   eval/runner.py

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	run.log

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

You are on `main`. It matches `origin/main` as of the last exchange with the server. One tracked file is modified and not staged, and one file is untracked.

**2. `git branch -vv`: which branches exist, and what do they follow?**

<!-- snippet: ch01/diagnosis/02-branch -->
```text
$ git branch -vv
  feature/cache 1c96817 Cache embeddings between runs
* main          f29df3b [origin/main] Raise eval timeout to 120s
```
<!-- /snippet -->

The star marks the current branch. `[origin/main]` is its upstream; no "ahead" or "behind" appears, so the last commit has been pushed. `feature/cache` has no upstream: it exists only here.

**3. `git remote -v`: which other repositories does this one talk to?**

<!-- snippet: ch01/diagnosis/03-remote -->
```text
$ git remote -v
origin	$LAB/ch01/diagnosis/origin.git (fetch)
origin	$LAB/ch01/diagnosis/origin.git (push)
```
<!-- /snippet -->

One remote named `origin`, with the same address for fetching and pushing. In your own projects this is a GitHub URL.

**4. `git log --graph --decorate --oneline --all`: what does the history look like?**

<!-- snippet: ch01/diagnosis/04-log -->
```text
$ git log --graph --decorate --oneline --all
* f29df3b (HEAD -> main, origin/main) Raise eval timeout to 120s
| * 1c96817 (feature/cache) Cache embeddings between runs
|/  
* 25fbbb0 Add evaluation runner and config
```
<!-- /snippet -->

`--all` includes every branch, `--graph` draws the lines between commits, and `--decorate` prints the names that point at each commit. `HEAD`, `main` and `origin/main` all sit on `f29df3b`.

**5. `git reflog`: what was done in this repository, and in which order?**

<!-- snippet: ch01/diagnosis/05-reflog -->
```text
$ git reflog
f29df3b HEAD@{0}: commit: Raise eval timeout to 120s
25fbbb0 HEAD@{1}: checkout: moving from feature/cache to main
1c96817 HEAD@{2}: commit: Cache embeddings between runs
25fbbb0 HEAD@{3}: checkout: moving from main to feature/cache
25fbbb0 HEAD@{4}: commit (initial): Add evaluation runner and config
```
<!-- /snippet -->

The reflog lists every position HEAD has had, newest first. It is a local journal that no other clone has. The latest action here was the commit under suspicion.

**6. `git rev-parse`: which exact object does a name stand for?**

<!-- snippet: ch01/diagnosis/06-rev-parse -->
```text
$ git rev-parse HEAD origin/main
f29df3b2e662b85dc3a9228a7b1b36248235bb3d
f29df3b2e662b85dc3a9228a7b1b36248235bb3d
$ git rev-parse --abbrev-ref HEAD
main
$ git rev-parse --show-toplevel
$LAB/ch01/diagnosis/rag-eval
```
<!-- /snippet -->

Names can be ambiguous; object IDs cannot. `HEAD` and `origin/main` resolve to the same ID. `--abbrev-ref HEAD` prints the current branch, and `--show-toplevel` prints the root of the working tree, which settles whether you are in the repository you think you are in.

**7. `git show`: what is in this commit?**

<!-- snippet: ch01/diagnosis/07-show -->
```text
$ git show --stat HEAD
commit f29df3b2e662b85dc3a9228a7b1b36248235bb3d
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:11:00 2026 +0530

    Raise eval timeout to 120s

 configs/eval.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

The commit changes one file, `configs/eval.yaml`. With `--stat` you get the list of changed files; without it, the full difference.

**8 and 9. `git diff` and `git diff --cached`: what is not committed?**

<!-- snippet: ch01/diagnosis/08-diff -->
```text
$ git diff
diff --git a/eval/runner.py b/eval/runner.py
index 817bce0..2d928f5 100644
--- a/eval/runner.py
+++ b/eval/runner.py
@@ -1,6 +1,6 @@
 """Run one evaluation batch against the retrieval service."""
 
-MAX_TIMEOUT_S = 60
+MAX_TIMEOUT_S = 120
 
 
 def effective_timeout(cfg):
$ git diff --cached
```
<!-- /snippet -->

`git diff` compares the working tree with the index: the change to `MAX_TIMEOUT_S` exists on disk and is not staged. `git diff --cached` compares the index with the last commit and prints nothing: nothing is staged. (`--staged` is a synonym of `--cached`.)

**10. `git config list --show-origin --show-scope`: which settings are in effect?**

<!-- snippet: ch01/diagnosis/09-config -->
```text
$ git config list --show-origin --show-scope
global	file:$LAB/ch01/diagnosis/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch01/diagnosis/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch01/diagnosis/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch01/diagnosis/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch01/diagnosis/home/.gitconfig	gc.reflogexpireunreachable=never
local	file:.git/config	core.repositoryformatversion=0
local	file:.git/config	core.filemode=true
local	file:.git/config	core.bare=false
local	file:.git/config	core.logallrefupdates=true
local	file:.git/config	core.ignorecase=true
local	file:.git/config	core.precomposeunicode=true
local	file:.git/config	remote.origin.url=$LAB/ch01/diagnosis/origin.git
local	file:.git/config	remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
local	file:.git/config	branch.main.remote=origin
local	file:.git/config	branch.main.merge=refs/heads/main
```
<!-- /snippet -->

Identity, the remote's address, and the two `branch.main.*` lines that make `origin/main` the upstream of `main`. When a command behaves differently on two machines, this listing is where the difference shows.

**11. `git ls-files`: what does Git track?**

<!-- snippet: ch01/diagnosis/10-ls-files -->
```text
$ git ls-files
README.md
configs/eval.yaml
eval/runner.py
```
<!-- /snippet -->

`eval/runner.py` is tracked. `run.log` is absent, which matches "untracked" in the status output.

| Command | What it reveals |
|---|---|
| `git status` | Current branch, relation to its upstream as of the last exchange, staged, unstaged and untracked paths |
| `git branch -vv` | Each local branch, the commit it points at, its upstream, and how far ahead or behind it is |
| `git remote -v` | The other repositories this one exchanges data with |
| `git log --graph --decorate --oneline --all` | The shape of the history and where every name points |
| `git reflog` | What happened to HEAD in this repository, newest first |
| `git rev-parse` | The exact object ID behind a name; the current branch; the repository root |
| `git show` | One commit: author, date, message and change |
| `git diff` | Working tree against index: what is not staged |
| `git diff --cached` | Index against the last commit: what the next commit would record |
| `git config list --show-origin --show-scope` | Every setting in effect and the file it comes from |
| `git ls-files` | The paths in the index, which are the tracked files |

## 1.12 Worked example: the fix that was committed and did not ship

The evidence is collected. The remaining steps of the framework follow.

**UNDERSTAND STATE.** Outputs 6, 7 and 8 give the content of the two files in each place.

| | Last commit `f29df3b` (also on the server) | Index | Working tree |
|---|---|---|---|
| `configs/eval.yaml` | `timeout_s: 120` | same | same |
| `eval/runner.py` | `MAX_TIMEOUT_S = 60` | `MAX_TIMEOUT_S = 60` | `MAX_TIMEOUT_S = 120` |

```text
  Your clone                                            The server (origin.git, bare)
 +----------------------------------------------+      +-------------------------------+
 |  25fbbb0---f29df3b   main, origin/main       | push |  25fbbb0---f29df3b   main     |
 |        \                (HEAD -> main)       | ---> |                               |
 |         1c96817      feature/cache           |      |  CI builds f29df3b:           |
 |                                              |      |  MAX_TIMEOUT_S = 60           |
 |  index:        runner.py has 60              |      +-------------------------------+
 |  working tree: runner.py has 120  (the fix)  |
 +----------------------------------------------+
```

**FORM HYPOTHESES and TEST HYPOTHESES.**

| Hypothesis | Evidence that would confirm it | Result |
|---|---|---|
| H1: the change to `runner.py` was never saved | The working tree shows 60 | Rejected: it shows 120 |
| H2: it was saved and never staged, so no commit contains it | The commit shows 60; `git diff` shows the change | Confirmed |
| H3: it was committed on another branch | Another commit touches `runner.py` | Rejected: only `25fbbb0` does |
| H4: it was committed and not pushed, so CI built an older commit | `HEAD` and `origin/main` differ | Rejected: same ID |

<!-- snippet: ch01/diagnosis/11-test -->
```text
$ git log --oneline --all -- eval/runner.py
25fbbb0 Add evaluation runner and config
$ git show HEAD:eval/runner.py | grep '^MAX_TIMEOUT_S'
MAX_TIMEOUT_S = 60
$ grep '^MAX_TIMEOUT_S' eval/runner.py
MAX_TIMEOUT_S = 120
```
<!-- /snippet -->

`git log --all -- <path>` lists the commits on any branch that changed the path. `git show HEAD:eval/runner.py` prints the file as the last commit recorded it.

**IDENTIFY ROOT CAUSE.**

```text
Observed behavior : CI fails with the old 60-second limit although the fix commit is on main.
                    The test passes on the author's laptop.
Git state         : HEAD = origin/main = f29df3b, which changes configs/eval.yaml only.
                    eval/runner.py is modified in the working tree and not staged.
Mechanism         : git commit records the index. Two files were edited; one was staged.
                    The local test reads the working tree. CI checks out the commit.
Root cause        : The second file was never added to the index, so it is in no commit.
Why Git does this : The index exists so that you choose what a commit contains. A commit is
                    what was staged, not what is on disk.
Correct fix       : Stage eval/runner.py, commit, push. One new commit; nothing is rewritten.
Prevention        : Read git status and git diff --cached before each commit.
                    Trust the test that runs on the commit, which is what CI does.
```

The layer is Git. GitHub and Actions did their job: the pipeline tested the commit it was given.

**SELECT LOWEST-RISK FIX.**

| Option | Risk | Verdict |
|---|---|---|
| A new commit with the missing file | 🟢 adds a commit; anyone who already fetched `f29df3b` is unaffected | Chosen |
| Amend `f29df3b` and force-push | 🟡 then 🔴: replaces a commit that the server and possibly colleagues already have | Rejected: a tidier log is not worth rewriting shared history |

**EXECUTE.** `git push` 🟡 changes shared state, so preview it with `--dry-run`.

<!-- snippet: ch01/diagnosis/12-fix -->
```text
$ git add eval/runner.py
$ git diff --cached --stat
 eval/runner.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git commit -m "Raise runner timeout cap to 120s"
[main 230ef10] Raise runner timeout cap to 120s
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push --dry-run
To $LAB/ch01/diagnosis/origin.git
   f29df3b..230ef10  main -> main
$ git push
To $LAB/ch01/diagnosis/origin.git
   f29df3b..230ef10  main -> main
```
<!-- /snippet -->

`git diff --cached` now shows exactly what the commit will record. `f29df3b..230ef10  main -> main` means the server's `main` moved from the old commit to the new one.

**VERIFY.**

<!-- snippet: ch01/diagnosis/13-verify -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	run.log

nothing added to commit but untracked files present (use "git add" to track)
$ git log --oneline -3
230ef10 Raise runner timeout cap to 120s
f29df3b Raise eval timeout to 120s
25fbbb0 Add evaluation runner and config
$ git rev-parse HEAD origin/main
230ef105d2234274936997629350568cbac83839
230ef105d2234274936997629350568cbac83839
$ git show HEAD:eval/runner.py | grep '^MAX_TIMEOUT_S'
MAX_TIMEOUT_S = 120
```
<!-- /snippet -->

Nothing tracked is modified, the new commit is on top, `HEAD` and `origin/main` agree, and the committed file has the new value. On GitHub, the pipeline run for `230ef10` must pass; that part cannot be shown from a local sandbox.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git push` 🟡 | unchanged | unchanged | unchanged | unchanged | `refs/remotes/origin/main` moves to the pushed commit | The server's `main` moves; missing objects are copied to it | If the remote is on GitHub, workflows that listen for pushes can start (Chapter 20A) |

**PREVENT.** Before every commit, read both lists in `git status`, and read `git diff --cached` as the text of what you are about to record. `git commit -a` would have included the second file, because it stages every modified tracked file first; for the same reason it also includes changes you did not mean to commit, so it is not a substitute for looking.

## 1.13 What can go wrong

Four failures that people meet on the first day, from `labs/ch01/pitfalls.sh`.

**The first branch is not called `main`.**

<!-- snippet: ch01/pitfalls/01-unconfigured-init -->
```text
# With no configuration at all, Git 2.55 still names the first branch master.
$ GIT_CONFIG_GLOBAL=/dev/null git init plain
hint: Using 'master' as the name for the initial branch. This default branch name
hint: will change to "main" in Git 3.0. To configure the initial branch name
hint: to use in all of your new repositories, which will suppress this warning,
hint: call:
hint:
hint: 	git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint: 	git branch -m <name>
hint:
hint: Disable this message with "git config set advice.defaultBranchName false"
Initialized empty Git repository in $LAB/ch01/pitfalls/plain/.git/
$ cat plain/.git/HEAD
ref: refs/heads/master
$ git -C plain branch -m main
$ cat plain/.git/HEAD
ref: refs/heads/main
```
<!-- /snippet -->

With no configuration at all, Git 2.55 names the first branch `master` and prints a hint. The lab configuration sets `init.defaultBranch=main`, which is why every other transcript says `main`. `git branch -m main` 🟡 renames the unborn branch; the last line shows that only the text in `HEAD` changed.

**Git says there is no repository.**

<!-- snippet: ch01/pitfalls/02-not-a-repository -->
```text
$ mkdir notes && cd notes
$ git status
fatal: not a git repository (or any of the parent directories): .git
[exit status: 128]
$ cd ..
```
<!-- /snippet -->

Git searched the current directory and its parents for a `.git` directory and found none. Lab 0.2 produces the same message a second way, by damaging `.git` itself.

**`git commit` records nothing.**

<!-- snippet: ch01/pitfalls/03-nothing-staged -->
```text
$ echo 'Evaluation harness.' >> README.md
$ git commit -m "Describe the project"
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[exit status: 1]
```
<!-- /snippet -->

Exit status 1 and no commit: the change is in the working tree and the index was never updated. The partial form of this failure, some files staged and others not, is the worked example of section 1.12.

**A repository inside a repository.**

<!-- snippet: ch01/pitfalls/04-embedded-repository -->
```text
$ git status --short
?? vendor/
$ git add .
warning: adding embedded git repository: vendor/tokenizer
hint: You've added another git repository inside your current repository.
hint: Clones of the outer repository will not contain the contents of
hint: the embedded repository and will not know how to obtain it.
hint: If you meant to add a submodule, use:
hint:
hint: 	git submodule add <url> vendor/tokenizer
hint:
hint: If you added this path by mistake, you can remove it from the
hint: index with:
hint:
hint: 	git rm --cached vendor/tokenizer
hint:
hint: See "git help submodule" for more information.
hint: Disable this message with "git config set advice.addEmbeddedRepo false"
$ git ls-files --stage
100644 3a79082bc80505c7543e79c4312e3e3d276a0e04 0	README.md
160000 26803e94675c7c4dba579a4a20be4109737ce628 0	vendor/tokenizer
```
<!-- /snippet -->

`vendor/tokenizer` has its own `.git` directory. Git does not add its files. It records one entry with mode `160000`, a *gitlink*: the ID of a commit in the inner repository. A clone of the outer repository would contain an empty directory there. This happens when you run `git init` or `git clone` inside an existing working tree. The hint tells you how to undo it:

<!-- snippet: ch01/pitfalls/05-embedded-undo -->
```text
# The command from the hint is refused. Unstaging with git restore works.
$ git rm --cached vendor/tokenizer
error: the following file has staged content different from both the
file and the HEAD:
    vendor/tokenizer
(use -f to force removal)
[exit status: 1]
$ git restore --staged vendor/tokenizer
$ git status --short
?? vendor/
```
<!-- /snippet -->

```text
Observed behavior : git rm --cached vendor/tokenizer, the command printed in the hint, is refused.
Git state         : The index holds a new gitlink for vendor/tokenizer. HEAD has no entry for it.
                    vendor/tokenizer still contains its own .git directory.
Mechanism         : git rm refuses to drop an index entry that matches neither HEAD nor the
                    working tree. For a gitlink, the working-tree half of that test treats a nested
                    repository that keeps its own .git directory as something removal could lose.
Root cause        : A freshly added embedded repository fails both halves of the test.
Why Git does this : The test protects staged content that exists nowhere else.
Correct fix       : git restore --staged vendor/tokenizer resets only the index entry. Before the
                    first commit there is no HEAD to restore from; there, git rm --cached -f works,
                    and --cached guarantees that the working tree is not touched.
Prevention        : Run git rev-parse --show-toplevel before git init or git clone.
```

The mechanism was read from the Git 2.55.0 source ([builtin/rm.c](https://github.com/git/git/blob/v2.55.0/builtin/rm.c), [submodule.c](https://github.com/git/git/blob/v2.55.0/submodule.c)). After unstaging, decide what the inner repository is: a separate project to ignore, or a dependency to add properly as a submodule (Chapter 23: Submodules).

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A command from this book is "not a git command" | `which -a git`, `git --version` | Put the Homebrew directory first in `PATH`; do not call `/usr/bin/git` by full path | Print `git --version` at the top of scripts and CI logs |
| The first branch is `master` | `git config list --show-origin` shows no `init.defaultBranch` | `git branch -m main` in the new repository | Set `init.defaultBranch` once (Chapter 14B) |
| "not a git repository" | `pwd`, `git rev-parse --show-toplevel`, then look at `.git/HEAD` | Change into the project, or restore `HEAD` (Lab 0.2) | Know where the repository root is before you act |
| `git commit` makes no commit, or one that lacks a file | `git status`, `git show --stat HEAD`, `git diff` | `git add` the paths and commit again | Read `git diff --cached` before committing |
| "adding embedded git repository" | `git ls-files --stage` shows mode `160000` | `git restore --staged <path>`, then ignore it or make it a submodule | `git rev-parse --show-toplevel` before `git init` or `git clone` |
| Every folder in your home directory shows as untracked | `git rev-parse --show-toplevel` prints your home directory | Remove the stray `.git` after checking that it holds no commits you need | Give `git init` a directory argument |

## 1.14 When not to use it, and dangerous edge cases

**When Git alone is the wrong tool.**

- Large binary data such as datasets, model weights and media. Every version of every file stays in the history and travels to every clone. Keep a pointer in Git and the data elsewhere (Chapter 22: Git LFS, Chapter 28: AI/ML workflows).
- Secrets. A committed and pushed secret is in every clone. Deleting the file in a later commit does not remove it from history, and the remedy starts with rotating the secret (Chapter 21B).
- Generated files: build output, virtual environments, caches. Ignore them (Chapter 4: Working Tree).

**When the ritual is not enough.** The ten commands describe one clone. They say nothing certain about the server until you fetch, and nothing at all about GitHub objects such as pull requests, rulesets and check results.

**Dangerous edge cases.**

- `git status` can write. By default it refreshes the cached file information in `.git/index` and writes the file back. That never changes history, but it matters in two situations: when you investigate a damaged repository, work on a copy; and in scripts that run in the background, use `git --no-optional-locks status`, as the git-status manual advises.
- Editing `.git` by hand. Lab 0.2 does it in a sandbox to show which files Git cannot live without. In a real repository, use the plumbing command that performs the same edit with locking and a reflog entry, for example `git symbolic-ref` or `git update-ref`.
- `git init` in the wrong place. In your home directory it turns everything you own into one working tree. Inside another repository it creates the embedded repository of section 1.13.
- `rm -rf .git` 🔴. **What it changes:** it deletes the repository and leaves the working-tree files. **What it can destroy:** every commit that was never pushed, every local branch, stash and reflog; that is, the safety net itself. **Preview:** `git log --oneline --all` and `git branch -vv` show what exists only here. **Recovery:** none through Git; another clone or a disk backup is the only source. **When appropriate:** a repository created by mistake that holds no commit you need.

## 1.15 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git init` | 🟢 | Creates `.git`; in an existing repository it only adds missing template files | `git rev-parse --show-toplevel` tells you whether you are already inside a repository | Remove the new `.git` if it was created in the wrong place and holds nothing |
| `git add <path>` | 🟢 | Stores content as objects and points index entries at it | `git status`, `git diff` | `git restore --staged <path>` |
| `git commit` | 🟢 | Adds tree and commit objects, moves the current branch, appends to the reflogs | `git diff --cached` | A further commit, or Chapter 11: Reset, Revert, Restore |
| `git restore --staged <path>`, `git rm --cached <path>` | 🟡 | Change or remove an index entry; files on disk stay | `git diff --cached`, `git ls-files --stage` | `git add <path>` |
| `git branch -m <name>` | 🟡 | Renames the current branch | `git branch -vv` | Rename it back |
| `git config set --global <key> <value>` | 🟡 | Writes your personal configuration file (the sandbox file in the lab) | `git config list --show-origin --show-scope` | `git config unset --global <key>` |
| `git push` | 🟡 | Moves a branch on the remote and copies objects to it | `git push --dry-run` | Cannot be taken back quietly once others have fetched; publish a correcting commit |
| `rm -rf .git` | 🔴 | Deletes the repository | `git log --oneline --all`, `git branch -vv` | None through Git |

## 1.16 Version notes

| Topic | Older behavior | Current behavior | Since | Recommended |
|---|---|---|---|---|
| `git config` | `--list`, `--get`, `--unset` options | `list`, `get`, `set`, `unset` subcommands; the options still work | Git 2.46 | Use the subcommands, and remember that they fail on older Gits such as the 2.43.0 that Ubuntu 24.04 ships |
| Name of the first branch | Always `master` | Still `master` when unconfigured, with a hint; `init.defaultBranch` and `git init -b` choose it | Setting since Git 2.28; `main` is planned as the default in Git 3.0, which has no release date | Set `init.defaultBranch`; never hard-code a branch name in a script |
| `git switch`, `git restore` | Labelled experimental | Stable | Introduced in Git 2.23; label removed in 2.51 | Use them; read `git checkout` in older scripts |
| Object IDs and ref storage | Not applicable | 40-digit SHA-1 IDs and refs stored as files are the defaults | Git 3.0 plans SHA-256 and reftable as defaults for new repositories | Never assume the length of an ID, or that a ref is a file (Chapter 3) |
| `gitdatamodel` manual page | Did not exist | `git help datamodel` | Git 2.53 | Read it after Chapter 2 |
| Installed versus latest | Git 2.55.0; `gh` 2.88.1 | Git 2.56.0 (28 September 2026); `gh` 2.102.0 (30 September 2026) | Not applicable | Git: optional. `gh`: upgrade before the GitHub chapters |

All rows come from sections 1 and 4 of the [research report](../reports/Git%20and%20GitHub%20mastery%20research.md), which links the release notes.

> **Outdated advice.** Tutorials written before 2020 switch branches and discard changes with `git checkout` and assume a branch called `master`. Neither is wrong: `git checkout` remains supported, and unconfigured Git still creates `master`. Do not "correct" a script because it uses them. Do write new commands with `git switch` and `git restore`.

## 1.17 Practice

1. [Lab 0.1](../lab-manual/m00-lab-setup.md): verify the toolchain and build the sandbox.
2. [Lab 0.2](../lab-manual/m00-lab-setup.md): read every file in an empty `.git`, then find out which of them Git cannot live without.
3. Replay `labs/run ch01/first-repo`, then repeat section 1.9 by hand in `labs/shell m00`. Predict before you look: which of your object IDs will equal the book's, and which will not?
4. Replay `labs/run ch01/diagnosis` and inspect the sandbox it leaves in `$LAB/ch01/diagnosis/rag-eval`. Run the ritual yourself before reading section 1.12 again.
5. Then continue with [Chapter 2](ch02-mental-model.md), which explains the objects you saw appear under `.git/objects`.

## 1.18 Interview questions

1. A colleague says "the fix is committed". List the distinct places where that statement can be true or false, and the command that checks each.
2. Name three things that Git stores and GitHub only displays, and three things that exist only on GitHub. Why does the distinction matter during an incident?
3. `git status` reports that your branch is up to date with `origin/main`. What exactly did Git compare, and how old can that information be?
4. Why can `git log` work without a network connection while `git push` cannot? What does your answer imply about backups?
5. Between `git add` and `git commit`, which files under `.git` have changed, and what does each contain?
6. What makes a directory a Git repository? Which files in a fresh `.git` can you delete without breaking it?
7. Two engineers type the same Git command on two Macs and see different behavior. Name three causes outside the repository and the command that detects each.
8. A fix must reach a shared branch that already contains the faulty commit. Compare a new commit with amending and force-pushing. Which do you choose, and what would change your answer?
9. The same commands typed at two different times produce different commit IDs. Why? What did the lab environment pin to prevent it, and what did it not need to pin?
10. Which of the ten diagnosis commands can write to disk, and why does that matter when you investigate a damaged repository?
11. Git prints a hint that recommends `git rm --cached <path>` and then refuses that command. Explain how you would find out why.
12. Walk through the eleven steps of the root-cause framework for the symptom "my commit is not on GitHub".

## 1.19 Sources

**Primary sources**

- [git(1)](https://git-scm.com/docs/git): description, environment variables, `--no-optional-locks`.
- [gitrepository-layout](https://git-scm.com/docs/gitrepository-layout): every file in `.git`.
- [gitglossary](https://git-scm.com/docs/gitglossary): bare repository, unborn branch, plumbing, porcelain.
- [gitdatamodel](https://git-scm.com/docs/gitdatamodel): the official data model page, on your machine as `git help datamodel`.
- [git-init](https://git-scm.com/docs/git-init), [git-status](https://git-scm.com/docs/git-status), [git-config](https://git-scm.com/docs/git-config), [git-rev-parse](https://git-scm.com/docs/git-rev-parse), [git-ls-files](https://git-scm.com/docs/git-ls-files), [git-rm](https://git-scm.com/docs/git-rm).
- Git source at the v2.55.0 tag: [builtin/rm.c](https://github.com/git/git/blob/v2.55.0/builtin/rm.c), [submodule.c](https://github.com/git/git/blob/v2.55.0/submodule.c) and [builtin/fsck.c](https://github.com/git/git/blob/v2.55.0/builtin/fsck.c), read for the two root-cause notes in sections 1.7 and 1.13.
- Pro Git, second edition: [About Version Control](https://git-scm.com/book/en/v2/Getting-Started-About-Version-Control), [A Short History of Git](https://git-scm.com/book/en/v2/Getting-Started-A-Short-History-of-Git), [What is Git?](https://git-scm.com/book/en/v2/Getting-Started-What-is-Git%3F). The book is hosted on the official site and has been frozen since May 2024, so its command style is older than this chapter's.
- GitHub: [changelog entry on CLI telemetry](https://github.blog/changelog/2026-04-22-github-cli-opt-out-usage-telemetry/), [gh environment variables](https://cli.github.com/manual/gh_help_environment).

**Secondary sources**

- [Phase 0 research report](../reports/Git%20and%20GitHub%20mastery%20research.md), sections 1, 2, 4 and 12: versions, dates, the two Gits, and the Git and GitHub layers, each with a link to its primary source.

**Videos**

The report assessed these from captions and chapter lists, not by full viewing.

- ["Learn Git & GitHub for Beginners (2026) Tutorial"](https://www.youtube.com/watch?v=h2a3Kw-I_Ec), Coder Coder, 56 minutes, 28 June 2026. Current commands, including `git switch` and `git restore`. Beginner scope only.
- ["Git Tutorial for Beginners: Learn Git in One Video"](https://www.youtube.com/watch?v=AB3J8ufDYHQ), CodeWithHarry, Hindi, 2 hours 32 minutes, 12 July 2026. Current commands. It teaches no reset, revert or reflog, uses a local `master`, and first calls a branch a copy before correcting that to a pointer.
- ["Tech Talk: Linus Torvalds on git"](https://www.youtube.com/watch?v=4XpnKHJAok8), 2007, and ["Two decades of Git"](https://www.youtube.com/watch?v=sCr_gb8rdEI), 2025. Design intent and history. Polemical; his 2025 remark that the SHA-256 work was needless churn is his opinion, not the project's position.

**Further reading**

- [gittutorial](https://git-scm.com/docs/gittutorial) and [giteveryday](https://git-scm.com/docs/giteveryday), also available as `git help tutorial` and `git help everyday`.
- [The Git User's Manual](https://git-scm.com/docs/user-manual).
