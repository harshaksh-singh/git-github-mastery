# Chapter 23: Submodules and Subtrees

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch23/`.

## 23.1 Why this matters

Four reports from one week on a team that vendors a shared library:

1. "I cloned the service and the `vendor/textsplit` directory is empty. The imports fail."
2. "`git pull` worked for everyone yesterday. Today it dies with `not our ref`."
3. "I pulled, changed one line in `ingest.py`, committed, and the reviewer says my commit downgrades the library."
4. "CI is green on my branch and red on `main`, and the only difference is a directory I never touched."

A CTO who hears these asks two things: why does this mechanism fail so often, and should we be using it at all? Both questions have precise answers, and both start from one fact that the Phase 0 report puts in a sentence: **the superproject records a commit ID, not a branch, and Git's defaults do not keep the nested checkout in sync with that record.** Every standard failure in this chapter is a gap between three things that should agree: the commit ID recorded in the superproject, the commit checked out in the submodule's working tree, and the commits that exist in the submodule's shared repository.

The projects: `doc-qa`, a document question-answering service owned by your team, and `textsplit`, a small text-chunking library that Asha maintains in a repository of its own. Ravi is your teammate on `doc-qa`. The second half of the chapter solves the same problem with a subtree and compares both with a package manager.

## 23.2 What a submodule is: a gitlink, `.gitmodules`, and a repository under `.git/modules`

**In one sentence.** A submodule is another repository checked out in a subdirectory of yours, of which your repository records exactly one thing in its history: the ID of the commit that should be checked out there.

**Analogy.** A recipe that says "use the stock from page 212 of the other book, third printing". Your book does not contain the stock recipe; it contains a precise reference to one version of it. Anyone cooking from your book needs the other book as well, opened at that page. Where the analogy breaks: the other book keeps being reprinted, your reference does not update itself, and the reader can scribble in their copy of the other book without your book noticing until they compare.

**Precisely.** Three pieces, in three different places ([gitsubmodules](https://git-scm.com/docs/gitsubmodules)):

| Piece | Where | Versioned in the superproject? | What it holds |
|---|---|---|---|
| The **gitlink** | A tree entry (and index entry) with mode `160000` at the submodule path | Yes | The commit ID the superproject expects there |
| **`.gitmodules`** | A file at the top of the superproject's working tree | Yes | For each submodule: a name, the path, the URL to clone from, optional settings such as `branch` |
| The submodule's **repository** | `.git/modules/<name>/` inside the superproject's Git directory, plus a `.git` file in the submodule's working tree that points to it | No | The submodule's own objects, refs, HEAD, index, configuration |

A fourth, local piece connects them: `git submodule init` copies the URL from `.gitmodules` into the superproject's `.git/config` as `submodule.<name>.url`. From then on Git uses the copy. That is why a changed URL does not reach existing clones by itself (section 23.11).

[Chapter 3](ch03-git-internals.md) listed mode `160000` among the five entry modes of a tree. This chapter is about what that entry does not contain.

**See it.** In your clone of `doc-qa`, add the library. The option before `submodule` is explained in section 23.4; the lab remotes are directories, and Git is cautious about those.

<!-- snippet: ch23/submodule-add/02-add -->
```text
$ git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit
Cloning into '$LAB/ch23/submodule-add/doc-qa/vendor/textsplit'...
done.
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   .gitmodules
	new file:   vendor/textsplit
```
<!-- /snippet -->

The command cloned the library into `vendor/textsplit` and staged two things. First, `.gitmodules` and the copy of the URL in the local configuration:

<!-- snippet: ch23/submodule-add/03-gitmodules -->
```text
$ cat .gitmodules
[submodule "vendor/textsplit"]
	path = vendor/textsplit
	url = ../textsplit.git
$ git config list --local | grep ^submodule
submodule.vendor/textsplit.url=$LAB/ch23/submodule-add/remotes/textsplit.git
submodule.vendor/textsplit.active=true
```
<!-- /snippet -->

The versioned file holds the relative URL `../textsplit.git`. A URL that starts with `./` or `../` is resolved against the superproject's own remote, here `remotes/doc-qa.git`, which gives its sibling `remotes/textsplit.git`. The local configuration holds the resolved, absolute result. Relative URLs are worth using when both repositories live on the same host: a clone made over HTTPS fetches the submodule over HTTPS, a clone made over SSH uses SSH, and no protocol is written into a versioned file.

Second, the gitlink in the index:

<!-- snippet: ch23/submodule-add/04-gitlink -->
```text
$ git ls-files --stage
100644 9f740c3c709ae97192a6f851e624b01da96b7224 0	.gitmodules
100644 09f9084395224cf2f392b6a549a62c2cdc28d7dd 0	README.md
100644 b5c3d8b6ef195753d164433b23610b16e4fbdb62 0	answer.py
100644 eb72b3ec2e343a1cc0d789f693ab705990af7f35 0	ingest.py
160000 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 0	vendor/textsplit
$ git -C vendor/textsplit log --oneline --decorate -1
e216665 (HEAD -> main, origin/main, origin/HEAD) Add overlap between neighbouring chunks
```
<!-- /snippet -->

Four blobs with mode `100644` and one entry with mode `160000`. Its ID, `e216665`, is the commit that the library's `main` pointed at when you ran the command. Nothing in the entry says "main".

<!-- snippet: ch23/submodule-add/05-modules-dir -->
```text
$ cat vendor/textsplit/.git
gitdir: ../../.git/modules/vendor/textsplit
$ ls .git/modules/vendor/textsplit
config
description
HEAD
hooks
index
info
logs
objects
packed-refs
refs
$ git -C vendor/textsplit rev-parse --git-dir
$LAB/ch23/submodule-add/doc-qa/.git/modules/vendor/textsplit
$ git -C vendor/textsplit config get core.worktree
../../../../vendor/textsplit
```
<!-- /snippet -->

The submodule's working tree has a `.git` file, the same device a linked worktree uses ([Chapter 25](ch25-worktrees.md)), and the real Git directory sits under the superproject's `.git/modules/`. Keeping it there means the repository survives when the working tree directory disappears, for example when you switch to a commit of the superproject from before the submodule existed.

<!-- snippet: ch23/submodule-add/06-diff -->
```text
$ git diff --cached -- vendor/textsplit
diff --git a/vendor/textsplit b/vendor/textsplit
new file mode 160000
index 0000000..e216665
--- /dev/null
+++ b/vendor/textsplit
@@ -0,0 +1 @@
+Subproject commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4
```
<!-- /snippet -->

To the superproject a submodule is a one-line file whose content is `Subproject commit <ID>`. That is how every later change to it appears in diffs and in review.

<!-- snippet: ch23/submodule-add/07-commit -->
```text
$ git commit -m "Vendor textsplit as a submodule"
[main bf751ba] Vendor textsplit as a submodule
 2 files changed, 4 insertions(+)
 create mode 100644 .gitmodules
 create mode 160000 vendor/textsplit
$ git ls-tree HEAD
100644 blob 9f740c3c709ae97192a6f851e624b01da96b7224	.gitmodules
100644 blob 09f9084395224cf2f392b6a549a62c2cdc28d7dd	README.md
100644 blob b5c3d8b6ef195753d164433b23610b16e4fbdb62	answer.py
100644 blob eb72b3ec2e343a1cc0d789f693ab705990af7f35	ingest.py
040000 tree 341fc987ffe5b926508788b966cbd3b8e0f19927	vendor
$ git ls-tree HEAD vendor/
160000 commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4	vendor/textsplit
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
```
<!-- /snippet -->

`git ls-tree` prints the type `commit` for the entry. `git submodule status` prints the checked-out commit, the path, and the output of `git describe` for it. And the point that the rest of the chapter depends on:

<!-- snippet: ch23/submodule-add/08-not-our-object -->
```text
# The tree entry names a commit, but the commit object is not in this repository:
$ git cat-file -t HEAD:vendor/textsplit
fatal: git cat-file: could not get object info
[exit status: 128]
# It lives in the object database of the submodule:
$ git -C vendor/textsplit cat-file -t HEAD
commit
$ git -C vendor/textsplit rev-parse HEAD
e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4
```
<!-- /snippet -->

The superproject's object database does not contain commit `e216665`. A tree entry of mode `160000` is the only place in Git where an object ID names something that the repository is not required to have. Git does not check that the ID exists anywhere when you commit it or when you push it. Everything that makes the entry useful (where to get the object, whether it has been fetched, whether it is checked out) is arranged outside the commit.

**Picture.**

```text
  doc-qa  (superproject)                                   textsplit  (its own repository)
  +---------------------------------------------+          +----------------------------------+
  | commit bf751ba                              |          |  ceaafe1 --- e216665   main      |
  |   tree                                      |          |  (v0.1.0)                        |
  |     100644 blob  .gitmodules  ----------------- url -->|  remotes/textsplit.git           |
  |     100644 blob  ingest.py                  |          +----------------------------------+
  |     040000 tree  vendor                     |                         ^
  |       160000 commit e216665  textsplit  ------- "check this out" ------+
  |                                             |
  | .git/config        submodule.vendor/textsplit.url = <absolute URL>   (local, not versioned)
  | .git/modules/vendor/textsplit/              the clone of textsplit    (local, not versioned)
  | vendor/textsplit/.git   (file) -> ../../.git/modules/vendor/textsplit
  +---------------------------------------------+
```

**In production.** A team keeps prompt templates, a tokenizer vocabulary or protocol definitions in one repository that five services consume. A submodule gives each service an exact, reviewable pin: the pull request that moves the pin shows `-Subproject commit` and `+Subproject commit`, and a release of the service is reproducible from one commit ID of the superproject. The price is the set of failures below.

State table for `git submodule add <url> <path>`:

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| `<path>/` created and populated; `.gitmodules` created or extended | `.gitmodules` and a gitlink staged | unchanged | unchanged | `.git/modules/<name>/` created (a clone); `submodule.<name>.url` and `.active` in `.git/config` | unchanged (a fetch from the submodule's remote) | unchanged |

## 23.3 What a teammate receives: clone, init, update

A plain clone transfers the superproject's objects. The gitlink arrives; the commit it names does not.

<!-- snippet: ch23/submodule-clone/01-plain-clone -->
```text
$ git clone remotes/doc-qa.git ravi-doc-qa
Cloning into 'ravi-doc-qa'...
done.
$ cd ravi-doc-qa
$ ls -A vendor/textsplit
$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
$ git submodule status
-e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit
```
<!-- /snippet -->

Read the three outputs together. The directory exists and is empty. `git status` says "nothing to commit, working tree clean": an uninitialized submodule is not a modification, so nothing warns Ravi. Only `git submodule status` tells him, with the leading `-`, that the submodule is not initialized. This is report 1 from section 23.1.

Two steps fill the directory. 🟢 `git submodule init` registers the submodule: it copies the URL into `.git/config`.

<!-- snippet: ch23/submodule-clone/02-init -->
```text
$ git config get submodule.vendor/textsplit.url
[exit status: 1]
$ git submodule init
Submodule 'vendor/textsplit' ($LAB/ch23/submodule-clone/remotes/textsplit.git) registered for path 'vendor/textsplit'
$ git config list --local | grep ^submodule
submodule.vendor/textsplit.active=true
submodule.vendor/textsplit.url=$LAB/ch23/submodule-clone/remotes/textsplit.git
```
<!-- /snippet -->

🟡 `git submodule update` then clones the repository into `.git/modules/`, and checks out the recorded commit:

<!-- snippet: ch23/submodule-clone/03-update -->
```text
$ git -c protocol.file.allow=always submodule update
Cloning into '$LAB/ch23/submodule-clone/ravi-doc-qa/vendor/textsplit'...
done.
Submodule path 'vendor/textsplit': checked out 'e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4'
$ ls -A vendor/textsplit
.git
README.md
splitter.py
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
```
<!-- /snippet -->

`git submodule update --init` does both steps, and `--recursive` repeats them for submodules inside submodules. For a fresh clone, one command does everything:

<!-- snippet: ch23/submodule-clone/07-recursive -->
```text
$ git -c protocol.file.allow=always clone --recurse-submodules remotes/doc-qa.git asha-doc-qa
Cloning into 'asha-doc-qa'...
done.
Submodule 'vendor/textsplit' ($LAB/ch23/submodule-clone/remotes/textsplit.git) registered for path 'vendor/textsplit'
Cloning into '$LAB/ch23/submodule-clone/asha-doc-qa/vendor/textsplit'...
done.
Submodule path 'vendor/textsplit': checked out 'e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4'
$ git -C asha-doc-qa submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
```
<!-- /snippet -->

The table of prefixes that `git submodule status` prints is worth memorising, because it is the fastest diagnosis in this chapter:

| Prefix | Meaning |
|---|---|
| (space) | Initialized, and the checked-out commit equals the recorded one |
| `-` | Not initialized |
| `+` | The checked-out commit differs from the one recorded in the superproject's index |
| `U` | The submodule path has a merge conflict in the superproject |

## 23.4 Why the lab needs `protocol.file.allow`, and what that says about security

Without the extra option, the very first command of this chapter fails:

<!-- snippet: ch23/submodule-add/01-blocked -->
```text
$ git remote -v
origin	$LAB/ch23/submodule-add/remotes/doc-qa.git (fetch)
origin	$LAB/ch23/submodule-add/remotes/doc-qa.git (push)
$ git submodule add ../textsplit.git vendor/textsplit
Cloning into '$LAB/ch23/submodule-add/doc-qa/vendor/textsplit'...
fatal: transport 'file' not allowed
fatal: clone of '$LAB/ch23/submodule-add/remotes/textsplit.git' into submodule path '$LAB/ch23/submodule-add/doc-qa/vendor/textsplit' failed
[exit status: 128]
```
<!-- /snippet -->

So does a recursive clone, at the moment it starts cloning the submodule by itself:

<!-- snippet: ch23/submodule-clone/05-recursive-refused -->
```text
$ cd ..
$ git clone --recurse-submodules remotes/doc-qa.git asha-doc-qa
Cloning into 'asha-doc-qa'...
done.
Submodule 'vendor/textsplit' ($LAB/ch23/submodule-clone/remotes/textsplit.git) registered for path 'vendor/textsplit'
Cloning into '$LAB/ch23/submodule-clone/asha-doc-qa/vendor/textsplit'...
fatal: transport 'file' not allowed
fatal: clone of '$LAB/ch23/submodule-clone/remotes/textsplit.git' into submodule path '$LAB/ch23/submodule-clone/asha-doc-qa/vendor/textsplit' failed
Failed to clone 'vendor/textsplit'. Retry scheduled
Cloning into '$LAB/ch23/submodule-clone/asha-doc-qa/vendor/textsplit'...
fatal: transport 'file' not allowed
fatal: clone of '$LAB/ch23/submodule-clone/remotes/textsplit.git' into submodule path '$LAB/ch23/submodule-clone/asha-doc-qa/vendor/textsplit' failed
Failed to clone 'vendor/textsplit' a second time, aborting
[exit status: 1]
```
<!-- /snippet -->
<!-- snippet: ch23/submodule-clone/06-policy -->
```text
# The clone of the superproject worked; only the clone that Git started by itself was refused.
$ git -C asha-doc-qa submodule status
-e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit
# The default policy for the file transport is "user". This variable is how Git marks
# a transfer that the user did not type:
$ GIT_PROTOCOL_FROM_USER=0 git clone remotes/textsplit.git probe
Cloning into 'probe'...
fatal: transport 'file' not allowed
[exit status: 128]
```
<!-- /snippet -->

**Mechanism.** Git has a per-transport policy, `protocol.<name>.allow`, with three values: `always`, `never` and `user`. The local manual gives the defaults: `http`, `https`, `git` and `ssh` are `always`; `ext` is `never`; everything else, the `file` transport included, is `user`. Under `user` a transport may be used only when the environment variable `GIT_PROTOCOL_FROM_USER` is unset or `1`, that is, when a person typed the clone, fetch or push. The `git submodule` command sets the variable to `0` before it does anything (it is the second statement of the `git-submodule` script in Git's exec path), because the URLs it will use come from `.gitmodules`, a file written by whoever authored the repository. A recursive clone runs the same code. The second half of the last transcript reproduces the refusal with an ordinary `git clone` and that variable.

**Why the default is what it is.** The value `user` for `file` dates from the fix for CVE-2022-39253, shipped in Git 2.38.1 and the maintenance releases of the same day. The release notes describe two changes: local clones no longer dereference symbolic links, and "the value of `protocol.file.allow` is changed to be "user" by default" ([release notes 2.38.1](https://github.com/git/git/blob/master/Documentation/RelNotes/2.38.1.adoc), [protocol configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/protocol.adoc)). The idea behind the policy is in the manual's wording: a protocol that is fine when you name it yourself should not be usable "by commands which execute clone/fetch/push commands without user input, e.g. recursive submodule initialization".

**What the lab does.** The lab's "servers" are bare repositories in a directory, so the submodule URL is a file path. Each command that makes Git clone or fetch a submodule on its own initiative is therefore run with `-c protocol.file.allow=always`, for that one command. Nothing is written to any configuration file. With a real remote over HTTPS or SSH you never need the option.

> **Outdated advice.** "Run `git config --global protocol.file.allow always` to fix submodule errors." That switches a security default off for every repository you will ever clone. Use `-c` for a single command on repositories you created yourself, and leave the setting alone otherwise. The Phase 0 report's rule set says the same.

**The wider security note.** A recursive clone is the one common Git operation in which a repository you have not inspected decides what else gets cloned and where it is written. That is where the recent client vulnerabilities have been:

| CVE | Fixed in | What a recursive clone of a hostile repository could do |
|---|---|---|
| CVE-2024-32002 (critical) | 2.45.1 and backports, May 2024 | On a case-insensitive filesystem with symbolic links (the default on macOS), write a hook into `.git/` and run it during the clone ([advisory](https://github.com/git/git/security/advisories/GHSA-8h77-4q3w-gfgv)) |
| CVE-2025-48384 (high) | 2.50.1 and backports, July 2025 | Through a submodule path ending in a carriage return, check content out to an unintended location where a hook could run ([advisory](https://github.com/git/git/security/advisories/GHSA-vwqx-4fm8-6qc9)) |

Both are fixed in the Git 2.55.0 this book uses and in Apple's 2.50.1. The second advisory's own workaround is the durable rule: do not recursively clone submodules of repositories you do not trust. Clone without recursion, read `.gitmodules`, and then decide. `git submodule init` also refuses, for the same reason, to copy a `submodule.<name>.update` setting that is a custom command from `.gitmodules` into your configuration.

## 23.5 The detached HEAD after `update`, and why it is correct

<!-- snippet: ch23/submodule-clone/04-detached -->
```text
$ git -C vendor/textsplit status
HEAD detached at e216665
nothing to commit, working tree clean
$ git -C vendor/textsplit branch --all
* (HEAD detached at e216665)
  main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
```
<!-- /snippet -->

**Why.** The superproject asked for commit `e216665`. It did not ask for a branch, and it cannot: the gitlink has no room for one. `git submodule update` therefore does what `git switch --detach <commit>` does. A local `main` exists in the submodule because the clone created it; HEAD is not on it. This is the detached HEAD of [Chapter 7](ch07-branches.md), reached by one more route, and it is the correct state for a dependency you only consume.

It becomes a trap the moment you edit the library in place. Ravi fixes something inside `vendor/textsplit` and commits:

<!-- snippet: ch23/submodule-detached/01-commit-on-detached -->
```text
$ cd vendor/textsplit
$ git status --short --branch
## HEAD (no branch)
$ git commit -am "Add line splitter"
[detached HEAD 679aa20] Add line splitter
 1 file changed, 5 insertions(+)
$ git log --oneline --decorate -2
679aa20 (HEAD) Add line splitter
e216665 (origin/main, origin/HEAD, main) Add overlap between neighbouring chunks
$ cd ../..
```
<!-- /snippet -->

The commit `679aa20` is on no branch. Meanwhile you have moved the pointer to the library's 0.2.0 release and pushed. Ravi pulls and updates:

<!-- snippet: ch23/submodule-detached/02-update-moves-head -->
```text
$ git pull
From $LAB/ch23/submodule-detached/remotes/doc-qa
   907dbd3..3719d28  main       -> origin/main
Fetching submodule vendor/textsplit
From $LAB/ch23/submodule-detached/remotes/textsplit
   e216665..b3c86ce  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Updating 907dbd3..3719d28
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git submodule update
Submodule path 'vendor/textsplit': checked out 'b3c86ceee1901d9cfff1a21920bd863a64ffb738'
$ git -C vendor/textsplit log --oneline --decorate -2
b3c86ce (HEAD, tag: v0.2.0, origin/main, origin/HEAD) Reject an overlap that is not smaller than the chunk size
e216665 (main) Add overlap between neighbouring chunks
# Which branch, local or remote-tracking, contains the commit Ravi made? None:
$ git -C vendor/textsplit branch --all --contains 679aa20
```
<!-- /snippet -->

`git submodule update` checked out the commit that the superproject now records and said nothing about the commit it left behind. No branch contains it. It is not lost: the submodule is a repository with its own reflog ([Chapter 13](ch13-recovery.md)).

<!-- snippet: ch23/submodule-detached/03-rescue -->
```text
# No branch ever pointed at the commit. The submodule has a reflog of its own:
$ git -C vendor/textsplit reflog -3
b3c86ce HEAD@{0}: checkout: moving from 679aa200d3e14163fc2fc5764cdd69de4c189dbd to b3c86ceee1901d9cfff1a21920bd863a64ffb738
679aa20 HEAD@{1}: commit: Add line splitter
e216665 HEAD@{2}: checkout: moving from main to e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4
$ git -C vendor/textsplit branch line-splitter 'HEAD@{1}'
$ git -C vendor/textsplit log --oneline --decorate -1 line-splitter
679aa20 (line-splitter) Add line splitter
```
<!-- /snippet -->

The prevention is a habit: before you change anything inside a submodule, get on a branch there.

<!-- snippet: ch23/submodule-detached/04-work-on-a-branch -->
```text
# The way to work in a submodule: get on a branch first.
$ git -C vendor/textsplit switch line-splitter
Previous HEAD position was b3c86ce Reject an overlap that is not smaller than the chunk size
Switched to branch 'line-splitter'
$ git -C vendor/textsplit status --short --branch
## line-splitter
$ git status --short
 M vendor/textsplit
$ git submodule status
+679aa200d3e14163fc2fc5764cdd69de4c189dbd vendor/textsplit (v0.1.0-2-g679aa20)
```
<!-- /snippet -->

With the submodule on a branch, `git submodule update --merge` or `--rebase` integrates the recorded commit into that branch and leaves HEAD attached; `submodule.<name>.update` makes either the default for one submodule. They are for people who develop the library inside the superproject. For consumers, the default checkout is right.

## 23.6 Moving the pointer: `update --remote`, status, diff, commit

Asha has released textsplit 0.2.0. Nothing changes in `doc-qa` until someone moves the gitlink. 🟡 `git submodule update --remote` fetches in the submodule and checks out the tip of its remote-tracking branch instead of the recorded commit:

<!-- snippet: ch23/submodule-update/01-remote -->
```text
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
$ git -c protocol.file.allow=always submodule update --remote
From $LAB/ch23/submodule-update/remotes/textsplit
   e216665..b3c86ce  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Submodule path 'vendor/textsplit': checked out 'b3c86ceee1901d9cfff1a21920bd863a64ffb738'
$ git submodule status
+b3c86ceee1901d9cfff1a21920bd863a64ffb738 vendor/textsplit (v0.2.0)
```
<!-- /snippet -->

Which branch? By default the one the remote's HEAD points at. `git submodule set-branch --branch <name> <path>` records another in `.gitmodules` as `submodule.<name>.branch`, and `git submodule add -b <name>` does so at creation. That setting is read by `update --remote` and by nothing else: it does not make the submodule "follow" a branch, and the gitlink is still a commit ID.

The submodule's working tree is now at `b3c86ce`, the superproject still records `e216665`, and `git submodule status` marks the difference with `+`. The superproject sees a modified one-line file:

<!-- snippet: ch23/submodule-update/02-status-diff -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   vendor/textsplit (new commits)

no changes added to commit (use "git add" and/or "git commit -a")
$ git diff
diff --git a/vendor/textsplit b/vendor/textsplit
index e216665..b3c86ce 160000
--- a/vendor/textsplit
+++ b/vendor/textsplit
@@ -1 +1 @@
-Subproject commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4
+Subproject commit b3c86ceee1901d9cfff1a21920bd863a64ffb738
$ git diff --submodule=log
Submodule vendor/textsplit e216665..b3c86ce:
  > Reject an overlap that is not smaller than the chunk size
```
<!-- /snippet -->

`(new commits)` in `git status` means "the submodule's HEAD differs from the gitlink in the index". `git diff --submodule=log` replaces the two IDs by the list of commits between them, which is what a reviewer wants to read; `git config set diff.submodule log` makes it the default.

Recording the new pointer is an ordinary add and commit:

<!-- snippet: ch23/submodule-update/03-commit-pointer -->
```text
$ git add vendor/textsplit
$ git commit -m "Update textsplit to 0.2.0"
[main 0d51dbc] Update textsplit to 0.2.0
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push origin main
To $LAB/ch23/submodule-update/remotes/doc-qa.git
   907dbd3..0d51dbc  main -> main
```
<!-- /snippet -->

State table for the two commands of this section:

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git submodule update` (with or without `--remote`) | Files inside the submodule path change; the superproject's own files do not | unchanged | unchanged; the **submodule's** HEAD is detached at the target commit | unchanged | `.git/modules/<name>/`: new objects after a fetch, its HEAD and HEAD reflog | unchanged (fetch only) | unchanged |
| `git add <path>` then `git commit` | unchanged | gitlink updated | new commit | advanced | reflogs | unchanged until pushed | unchanged until pushed |

Treat the resulting commit like any dependency bump: one purpose, its own pull request, CI on the result.

## 23.7 Keeping clones in step: the stale submodule and the silent rollback

You pushed the pointer change. Ravi pulls:

<!-- snippet: ch23/submodule-update/04-teammate-pull -->
```text
$ cd ../ravi-doc-qa
$ git pull
From $LAB/ch23/submodule-update/remotes/doc-qa
   907dbd3..0d51dbc  main       -> origin/main
Fetching submodule vendor/textsplit
From $LAB/ch23/submodule-update/remotes/textsplit
   e216665..b3c86ce  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Updating 907dbd3..0d51dbc
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   vendor/textsplit (new commits)

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

`git pull` fetched the superproject, noticed that the new commits change a gitlink, and fetched inside the submodule as well ("Fetching submodule vendor/textsplit"; this on-demand fetch is the default of `fetch.recurseSubmodules`). Then it fast-forwarded the superproject. It did **not** check out the new commit in the submodule. Ravi made no change, and `git status` reports one:

<!-- snippet: ch23/submodule-update/05-teammate-stale -->
```text
$ git submodule status
+e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
$ git diff --submodule=log
Submodule vendor/textsplit b3c86ce..e216665 (rewind):
  < Reject an overlap that is not smaller than the chunk size
```
<!-- /snippet -->

The `+` and the word `(rewind)` are the evidence. The superproject now records `b3c86ce`; the submodule's working tree is still at `e216665`. Seen from the superproject, the working tree differs from the index by going one library commit backwards.

```text
Observed behavior : After a pull that changed nothing of his own, git status shows
                    "modified: vendor/textsplit (new commits)".
Git state         : HEAD and index of the superproject record gitlink b3c86ce. The submodule's HEAD is
                    still e216665. The library commit b3c86ce has been fetched into .git/modules/.
Mechanism         : pull = fetch + merge. The merge updates the gitlink in the index. Checking out a
                    superproject commit does not move the HEAD of a submodule unless recursion is on.
Root cause        : Two repositories, two HEADs, and no default that ties the second to the first.
Why Git does this : The submodule may hold work in progress; Git will not move it without being asked.
Correct fix       : git submodule update      (then git status is clean)
Prevention        : git config set submodule.recurse true, or git pull --recurse-submodules.
```

If Ravi does not look closely, the stale state turns into a commit. He edits one file and uses `git commit -a`, which stages everything that is modified:

<!-- snippet: ch23/submodule-update/06-accidental-rollback -->
```text
# Ravi does not look closely. He edits a file and commits everything that is modified:
$ git commit -am "Use larger chunks"
[main b98f829] Use larger chunks
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git show --stat --format="%h %an: %s"
b98f829 Ravi Menon: Use larger chunks

 ingest.py        | 2 +-
 vendor/textsplit | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git ls-tree HEAD vendor/
160000 commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4	vendor/textsplit
```
<!-- /snippet -->

Two files changed. His commit moved the gitlink back to `e216665`. This is report 3 from section 23.1, and after a push it is report 4 for everyone else: the service silently runs the old library again. A reviewer sees it only as one changed line, `vendor/textsplit | 2 +-`, in a commit that claims to be about chunk sizes.

The commit has not been pushed, so it can be repaired in place: check out the right library commit, stage the gitlink, amend.

<!-- snippet: ch23/submodule-update/07-repair -->
```text
# Not pushed yet, so repair the commit: put the submodule on the commit that main records
# upstream, stage it, amend.
$ git -C vendor/textsplit checkout --quiet $(git rev-parse origin/main:vendor/textsplit)
$ git add vendor/textsplit
$ git commit --amend --no-edit
[main 2b86667] Use larger chunks
 Date: Mon Sep 7 10:35:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --stat --format="%h %an: %s"
2b86667 Ravi Menon: Use larger chunks

 ingest.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git submodule status
 b3c86ceee1901d9cfff1a21920bd863a64ffb738 vendor/textsplit (v0.2.0)
```
<!-- /snippet -->

`origin/main:vendor/textsplit` is the gitlink as the remote-tracking branch records it; `git rev-parse` returns the ID even though the object is not in the superproject. If the bad commit had already been pushed, the fix is a new commit that moves the pointer forward again.

The cure for the whole section is to make the second step automatic. After a pull, the manual sequence is two commands:

<!-- snippet: ch23/submodule-recurse/01-two-steps -->
```text
$ git pull
From $LAB/ch23/submodule-recurse/remotes/doc-qa
   907dbd3..3719d28  main       -> origin/main
Fetching submodule vendor/textsplit
From $LAB/ch23/submodule-recurse/remotes/textsplit
   e216665..b3c86ce  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Updating 907dbd3..3719d28
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git submodule status
+e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
$ git submodule update
Submodule path 'vendor/textsplit': checked out 'b3c86ceee1901d9cfff1a21920bd863a64ffb738'
$ git submodule status
 b3c86ceee1901d9cfff1a21920bd863a64ffb738 vendor/textsplit (v0.2.0)
$ git status --short --branch
## main...origin/main
```
<!-- /snippet -->

The same staleness appears with every command that moves the superproject's HEAD:

<!-- snippet: ch23/submodule-recurse/02-switch-without -->
```text
# An older commit of doc-qa records the older library commit. Without recursion:
$ git switch --detach HEAD~1
HEAD is now at 907dbd3 Vendor textsplit as a submodule and chunk documents
M	vendor/textsplit
$ git submodule status
+b3c86ceee1901d9cfff1a21920bd863a64ffb738 vendor/textsplit (v0.2.0)
$ git switch -
Previous HEAD position was 907dbd3 Vendor textsplit as a submodule and chunk documents
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git status --short
```
<!-- /snippet -->

With `submodule.recurse` set, `checkout`, `fetch`, `grep`, `pull`, `push`, `read-tree`, `reset`, `restore` and `switch` behave as if `--recurse-submodules` were given (the list is from `git help -m config`), and the submodule follows:

<!-- snippet: ch23/submodule-recurse/03-recurse -->
```text
$ git config set submodule.recurse true
$ git switch --detach HEAD~1
HEAD is now at 907dbd3 Vendor textsplit as a submodule and chunk documents
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
$ git switch -
Previous HEAD position was 907dbd3 Vendor textsplit as a submodule and chunk documents
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git submodule status
 b3c86ceee1901d9cfff1a21920bd863a64ffb738 vendor/textsplit (v0.2.0)
$ git config get submodule.recurse
true
```
<!-- /snippet -->

`git clone` is the exception: it needs its own `--recurse-submodules`, and so does `git ls-files`. The manual's workflow section recommends `submodule.recurse true` for repositories that are split into submodules ([gitsubmodules](https://git-scm.com/docs/gitsubmodules)). The setting is local or global configuration, so it cannot be shipped with the repository: every clone, and every CI job, has to set it or pass the option.

## 23.8 Push order: the commit your teammate cannot fetch

You improve the library from inside the service. You are on the submodule's `main`, as section 23.5 advised:

<!-- snippet: ch23/submodule-push-order/01-local-library-commit -->
```text
$ cd vendor/textsplit
$ git switch main
Already on 'main'
Your branch is up to date with 'origin/main'.
$ git commit -am "Add line splitter"
[main 17d7857] Add line splitter
 1 file changed, 5 insertions(+)
$ cd ../..
$ git status --short
 M vendor/textsplit
$ git commit -am "Use the line splitter from textsplit"
[main ee30f63] Use the line splitter from textsplit
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

There are now two unpushed commits in two repositories: `17d7857` in the library and `ee30f63` in the superproject, whose tree names `17d7857`. Pushing the superproject alone is accepted, because a gitlink is only an ID and the server does not check it:

<!-- snippet: ch23/submodule-push-order/03-mistake -->
```text
# Without the guard, the push of the superproject succeeds:
$ git push origin main
To $LAB/ch23/submodule-push-order/remotes/doc-qa.git
   907dbd3..ee30f63  main -> main
```
<!-- /snippet -->

Ravi pulls:

<!-- snippet: ch23/submodule-push-order/04-teammate -->
```text
$ cd ../ravi-doc-qa
$ git pull
From $LAB/ch23/submodule-push-order/remotes/doc-qa
   907dbd3..ee30f63  main       -> origin/main
Fetching submodule vendor/textsplit
fatal: git upload-pack: not our ref 17d78577459b6c2e681d54d4cfac2b350aaf7b2c
fatal: remote error: upload-pack: not our ref 17d78577459b6c2e681d54d4cfac2b350aaf7b2c
Errors during submodule fetch:
	vendor/textsplit
[exit status: 1]
```
<!-- /snippet -->

> **Root cause.** The superproject on the server records library commit `17d7857`. That commit exists in exactly one place: `.git/modules/vendor/textsplit` on your machine. The server-side `git upload-pack` of the library was asked for it by ID and answered `not our ref`.

In this transcript two processes report the same refusal: the client (`remote error: upload-pack: not our ref`) and `git upload-pack` itself, which runs on your own machine when the remote is a path. Their two lines can appear in either order, which is why `labs/verify-all.sh` treats this demo as volatile. Over HTTPS or SSH you see only the `remote error` line.

Note what state the failure left. The fetch of the superproject succeeded and the merge did not run:

<!-- snippet: ch23/submodule-push-order/05-diagnose -->
```text
$ git status --short --branch
## main...origin/main [behind 1]
$ git ls-tree origin/main vendor/
160000 commit 17d78577459b6c2e681d54d4cfac2b350aaf7b2c	vendor/textsplit
$ git ls-remote ../remotes/textsplit.git
e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4	HEAD
e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4	refs/heads/main
f8fdba471fcee4fa0c9a10d59be41c10c86f79ec	refs/tags/v0.1.0
ceaafe1cb2284284c7aa91a8ac843268d1dad25e	refs/tags/v0.1.0^{}
```
<!-- /snippet -->
<!-- snippet: ch23/submodule-push-order/05b-not-here -->
```text
$ git -C vendor/textsplit cat-file -t 17d7857
fatal: Not a valid object name 17d7857
[exit status: 128]
$ git -C ../doc-qa/vendor/textsplit branch --all --contains 17d7857
* main
```
<!-- /snippet -->

The diagnosis in three questions. Which library commit does the superproject want? `git ls-tree origin/main vendor/`. Does the library's shared repository have it? `git ls-remote` shows `main` still at `e216665`, and no ref leads to `17d7857`. Who has it? The author of the superproject commit, on a local branch.

The fix is on the author's side: push the library commit. Then the teammate's commands work:

<!-- snippet: ch23/submodule-push-order/06-fix -->
```text
$ cd ../doc-qa
$ git -C vendor/textsplit push origin main
To $LAB/ch23/submodule-push-order/remotes/textsplit.git
   e216665..17d7857  main -> main
$ cd ../ravi-doc-qa
$ git pull
Updating 907dbd3..ee30f63
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git -c protocol.file.allow=always submodule update
From $LAB/ch23/submodule-push-order/remotes/textsplit
   e216665..17d7857  main       -> origin/main
Submodule path 'vendor/textsplit': checked out '17d78577459b6c2e681d54d4cfac2b350aaf7b2c'
$ git submodule status
 17d78577459b6c2e681d54d4cfac2b350aaf7b2c vendor/textsplit (v0.1.0-2-g17d7857)
```
<!-- /snippet -->

Git has a guard for this, and it is off by default. 🟢 `git push --recurse-submodules=check` verifies, before anything is sent, that every submodule commit named by the commits being pushed is reachable from a remote-tracking branch of that submodule:

<!-- snippet: ch23/submodule-push-order/02-guard -->
```text
$ git push --recurse-submodules=check origin main
The following submodule paths contain changes that can
not be found on any remote:
  vendor/textsplit

Please try

	git push --recurse-submodules=on-demand

or cd to the path and use

	git push

to push them to a remote.

fatal: Aborting.
fatal: the remote end hung up unexpectedly
[exit status: 128]
```
<!-- /snippet -->

`--recurse-submodules=on-demand` goes one step further and pushes the submodules first:

<!-- snippet: ch23/submodule-push-order/07-on-demand -->
```text
$ cd ../doc-qa
$ git -C vendor/textsplit commit -am "Add sentence splitter"
[main 0dd831a] Add sentence splitter
 1 file changed, 4 insertions(+)
$ git commit -am "Use the sentence splitter from textsplit"
[main 9b2d81f] Use the sentence splitter from textsplit
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push --recurse-submodules=on-demand origin main
Pushing submodule 'vendor/textsplit'
To $LAB/ch23/submodule-push-order/remotes/textsplit.git
   17d7857..0dd831a  main -> main
To $LAB/ch23/submodule-push-order/remotes/doc-qa.git
   ee30f63..9b2d81f  main -> main
```
<!-- /snippet -->
<!-- snippet: ch23/submodule-push-order/08-config -->
```text
$ git config set push.recurseSubmodules check
$ git config get push.recurseSubmodules
check
```
<!-- /snippet -->

`push.recurseSubmodules=check` is the setting to put in every developer's configuration for a repository with submodules. Its limits: `check` trusts your remote-tracking branches, so it is satisfied by a commit that sits on a library branch you pushed and that someone later deletes; and `on-demand` needs push permission on the library, which consumers often do not have. In that case the library change goes through the library's own review first, and the superproject bumps the pointer afterwards.

## 23.9 Dirty submodules and switching branches

A submodule's working tree can have uncommitted changes of its own. The superproject reports them and cannot record them:

<!-- snippet: ch23/submodule-dirty/01-dirty -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
  (commit or discard the untracked or modified content in submodules)
	modified:   vendor/textsplit (modified content, untracked content)

no changes added to commit (use "git add" and/or "git commit -a")
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
```
<!-- /snippet -->
<!-- snippet: ch23/submodule-dirty/02-diff -->
```text
$ git diff
diff --git a/vendor/textsplit b/vendor/textsplit
--- a/vendor/textsplit
+++ b/vendor/textsplit
@@ -1 +1 @@
-Subproject commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4
+Subproject commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4-dirty
$ git diff --submodule=diff
Submodule vendor/textsplit contains modified content
diff --git a/vendor/textsplit/splitter.py b/vendor/textsplit/splitter.py
index c0dea76..6f4648f 100644
--- a/vendor/textsplit/splitter.py
+++ b/vendor/textsplit/splitter.py
@@ -2,3 +2,4 @@ def split(text, size=200, overlap=0):
     """Cut text into pieces of at most `size` characters; neighbours share `overlap` characters."""
     step = size - overlap
     return [text[i:i + size] for i in range(0, len(text), step)]
+# debug: print every chunk
```
<!-- /snippet -->

`(modified content, untracked content)` means the submodule's HEAD is the recorded commit and its working tree is not clean; `git submodule status` therefore shows no `+`. The diff appends `-dirty` to the ID. A gitlink can only name a commit, so there is nothing for the superproject to stage:

<!-- snippet: ch23/submodule-dirty/03-commit-a -->
```text
$ git commit -am "Save my work"
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
  (commit or discard the untracked or modified content in submodules)
	modified:   vendor/textsplit (modified content, untracked content)

no changes added to commit (use "git add" and/or "git commit -a")
[exit status: 1]
```
<!-- /snippet -->

The work has to be committed inside the submodule first (on a branch), and then the new commit ID can be staged in the superproject. To look into all submodules at once, `git submodule foreach` runs a shell command in each. The lower-case `m` and `?` in short status are the superproject's markers for modified and untracked content inside a submodule, and `--ignore-submodules` chooses how much of that is shown:

<!-- snippet: ch23/submodule-dirty/04-foreach -->
```text
$ git submodule foreach "git status --short"
Entering 'vendor/textsplit'
 M splitter.py
?? notes.txt
$ git status --short
 m vendor/textsplit
$ git status --short --ignore-submodules=untracked
 m vendor/textsplit
$ git status --short --ignore-submodules=dirty
```
<!-- /snippet -->

To get back to exactly the recorded state, 🔴 `git submodule update --force` checks the files out again and discards edits to tracked files; untracked files need `git clean` inside the submodule ([Chapter 4](ch04-working-tree.md)), previewed with `-n`:

<!-- snippet: ch23/submodule-dirty/05-discard -->
```text
# update does nothing: the checked-out commit already is the recorded one.
$ git submodule update
$ git status --short
 m vendor/textsplit
# --force checks the files out again, which discards the edit to the tracked file:
$ git submodule update --force
Submodule path 'vendor/textsplit': checked out 'e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4'
$ git status --short
 ? vendor/textsplit
$ git -C vendor/textsplit clean -n
Would remove notes.txt
$ git -C vendor/textsplit clean -f
Removing notes.txt
$ git status --short
```
<!-- /snippet -->

**Switching to a commit without the submodule** leaves its directory behind, because Git will not delete a directory that contains a repository's working tree:

<!-- snippet: ch23/submodule-switch/01-stray-directory -->
```text
$ git log --oneline
907dbd3 Vendor textsplit as a submodule and chunk documents
bf78eb9 Add keyword answerer
1d93b09 Add document loader
$ git switch --detach HEAD~1
warning: unable to rmdir 'vendor/textsplit': Directory not empty
HEAD is now at bf78eb9 Add keyword answerer
$ git status
HEAD detached at bf78eb9
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	vendor/

nothing added to commit but untracked files present (use "git add" to track)
$ ls -A vendor/textsplit
.git
README.md
splitter.py
```
<!-- /snippet -->

The stray `vendor/` is untracked on that commit. A careless `git add -A` there stages it as a new gitlink, with the warning `adding embedded git repository: vendor/textsplit`, and `git clean -f -d` answers `Skipping repository vendor/textsplit` (both run for this chapter). With recursion, the checkout removes and restores the submodule's working tree together with the superproject's files; the repository itself stays in `.git/modules/` either way:

<!-- snippet: ch23/submodule-switch/03-recurse -->
```text
$ git switch --recurse-submodules --detach HEAD~1
HEAD is now at bf78eb9 Add keyword answerer
$ git status --short
$ ls vendor 2>&1
ls: vendor: No such file or directory
$ git switch --recurse-submodules main
Previous HEAD position was bf78eb9 Add keyword answerer
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
```
<!-- /snippet -->

## 23.10 Pointer conflicts

Two branches of `doc-qa` move the gitlink. What a merge does depends on how the two library commits relate, and Git can look that up only in the submodule's repository.

<!-- snippet: ch23/submodule-conflict/01-two-pointers -->
```text
$ git log --graph --oneline --decorate --all
* 7a1b409 (HEAD -> use-tokens) Use the token splitter of textsplit
| * e5a77ed (use-release) Use textsplit 0.2.0
|/  
* 907dbd3 (origin/main, main) Vendor textsplit as a submodule and chunk documents
* bf78eb9 Add keyword answerer
* 1d93b09 Add document loader
$ git ls-tree use-release vendor/
160000 commit de689e20c2a64f6ebe2a0f3ec7c98efc09459cb9	vendor/textsplit
$ git ls-tree use-tokens vendor/
160000 commit cd2a8a45f5da8ab7bfedfe413228a50b91874c72	vendor/textsplit
$ git -C vendor/textsplit log --graph --oneline --decorate v0.2.0 origin/feature/tokens
* de689e2 (tag: v0.2.0, origin/main, origin/HEAD) Reject an overlap that is not smaller than the chunk size
| * cd2a8a4 (HEAD, origin/feature/tokens) Add token splitter
|/  
* e216665 (main) Add overlap between neighbouring chunks
* ceaafe1 (tag: v0.1.0) Add fixed-size splitter
```
<!-- /snippet -->

`use-release` records `de689e2` (the 0.2.0 release) and `use-tokens` records `cd2a8a4` (a feature branch of the library). The two library commits have diverged: neither is an ancestor of the other.

<!-- snippet: ch23/submodule-conflict/02-conflict -->
```text
$ git merge use-release
hint: Recursive merging with submodules currently only supports trivial cases.
hint: Please manually handle the merging of each conflicted submodule.
hint: This can be accomplished with the following steps:
hint:  - go to submodule (vendor/textsplit), and either merge commit de689e2
hint:    or update to an existing commit which has merged those changes
hint:  - come back to superproject and run:
hint:
hint:       git add vendor/textsplit
hint:
hint:    to record the above merge or update
hint:  - resolve any other conflicts in the superproject
hint:  - commit the resulting index in the superproject
hint:
hint: Disable this message with "git config set advice.submoduleMergeConflict false"
Failed to merge submodule vendor/textsplit
CONFLICT (submodule): Merge conflict in vendor/textsplit
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
```
<!-- /snippet -->
<!-- snippet: ch23/submodule-conflict/03-stages -->
```text
$ git status --short
UU vendor/textsplit
$ git ls-files --unmerged
160000 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 1	vendor/textsplit
160000 cd2a8a45f5da8ab7bfedfe413228a50b91874c72 2	vendor/textsplit
160000 de689e20c2a64f6ebe2a0f3ec7c98efc09459cb9 3	vendor/textsplit
$ git submodule status
U0000000000000000000000000000000000000000 vendor/textsplit
$ git diff
diff --cc vendor/textsplit
index cd2a8a4,de689e2..0000000
--- a/vendor/textsplit
+++ b/vendor/textsplit
```
<!-- /snippet -->

The index has the three stages of [Chapter 8](ch08-merge.md), each a gitlink: stage 1 the merge base's pointer, stage 2 ours, stage 3 theirs. There are no conflict markers, because there is no file to put them in. The superproject cannot produce the answer: the correct pointer is a library commit that contains both lines of development, and only the library can create it. Git's hint lists the two ways. One is to merge inside the submodule yourself; that creates a merge commit which exists only in your clone and must be pushed to the library before anyone else can use it (section 23.8). The other, used here, is to wait for the library to merge and then point at the result:

<!-- snippet: ch23/submodule-conflict/04-library-merges -->
```text
$ git -C vendor/textsplit fetch origin
From $LAB/ch23/submodule-conflict/remotes/textsplit
   de689e2..5a1935a  main       -> origin/main
$ git -C vendor/textsplit log --graph --oneline --decorate -4 origin/main
*   5a1935a (origin/main, origin/HEAD) Merge feature/tokens
|\  
| * cd2a8a4 (HEAD, origin/feature/tokens) Add token splitter
* | de689e2 (tag: v0.2.0) Reject an overlap that is not smaller than the chunk size
|/  
* e216665 (main) Add overlap between neighbouring chunks
```
<!-- /snippet -->
<!-- snippet: ch23/submodule-conflict/05-resolve -->
```text
$ git -C vendor/textsplit checkout --quiet origin/main
$ git add vendor/textsplit
$ git status --short
M  vendor/textsplit
$ git commit --no-edit
[use-tokens c927444] Merge branch 'use-release' into use-tokens
$ git ls-tree HEAD vendor/
160000 commit 5a1935ae4e615fa75f14284cab1eb1906c8cdf33	vendor/textsplit
$ git submodule status
 5a1935ae4e615fa75f14284cab1eb1906c8cdf33 vendor/textsplit (v0.2.0-2-g5a1935a)
```
<!-- /snippet -->

`git add vendor/textsplit` stages whatever commit the submodule has checked out, which resolves the path; `git commit` concludes the merge.

When one of the two library commits is an ancestor of the other, Git resolves the pointer by itself and takes the descendant. It says so in one line:

<!-- snippet: ch23/submodule-conflict/06-ancestor-case -->
```text
# A new branch from main that records the library merge commit. use-release records v0.2.0,
# an ancestor of that merge. Both branches moved the pointer away from the one main has.
$ git ls-tree main vendor/
160000 commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4	vendor/textsplit
$ git ls-tree use-merged vendor/
160000 commit 5a1935ae4e615fa75f14284cab1eb1906c8cdf33	vendor/textsplit
$ git ls-tree use-release vendor/
160000 commit de689e20c2a64f6ebe2a0f3ec7c98efc09459cb9	vendor/textsplit
$ git merge use-release
Note: Fast-forwarding submodule vendor/textsplit to 5a1935ae4e615fa75f14284cab1eb1906c8cdf33
Merge made by the 'ort' strategy.
[exit status: 0]
$ git ls-tree HEAD vendor/
160000 commit 5a1935ae4e615fa75f14284cab1eb1906c8cdf33	vendor/textsplit
```
<!-- /snippet -->

That automatic resolution needs both commits to be present in the submodule's local repository. In a clone where the submodule is not checked out, Git cannot determine ancestry and reports `Failed to merge submodule vendor/textsplit (not checked out)` and a conflict instead. `-X theirs` does not help either: the merge stops with the same submodule conflict. (Both were run for this chapter; no transcript is printed.)

## 23.11 Removing a submodule, and a submodule whose URL changes

There are two different "removals". 🟡 `git submodule deinit <path>` is local: it empties the working directory and removes the `submodule.<name>` section from your `.git/config`. The superproject's history is untouched, and `git submodule update --init` undoes it.

<!-- snippet: ch23/submodule-remove/01-deinit -->
```text
$ git submodule deinit vendor/textsplit
Cleared directory 'vendor/textsplit'
Submodule 'vendor/textsplit' (../textsplit.git) unregistered for path 'vendor/textsplit'
$ git submodule status
-e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit
$ ls -A vendor/textsplit
$ git status --short
$ git config list --local | grep ^submodule
$ ls .git/modules/vendor
textsplit
```
<!-- /snippet -->

🟡 `git rm <path>` removes the submodule from the project: it deletes the gitlink and the section in `.gitmodules`, and you commit that.

<!-- snippet: ch23/submodule-remove/03-rm -->
```text
$ git rm vendor/textsplit
rm 'vendor/textsplit'
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   .gitmodules
	deleted:    vendor/textsplit

$ git diff --cached
diff --git a/.gitmodules b/.gitmodules
index 9f740c3..e69de29 100644
--- a/.gitmodules
+++ b/.gitmodules
@@ -1,3 +0,0 @@
-[submodule "vendor/textsplit"]
-	path = vendor/textsplit
-	url = ../textsplit.git
diff --git a/vendor/textsplit b/vendor/textsplit
deleted file mode 160000
index e216665..0000000
--- a/vendor/textsplit
+++ /dev/null
@@ -1 +0,0 @@
-Subproject commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4
```
<!-- /snippet -->
<!-- snippet: ch23/submodule-remove/04-commit -->
```text
$ git commit -m "Stop vendoring textsplit"
[main 4adef58] Stop vendoring textsplit
 2 files changed, 4 deletions(-)
 delete mode 160000 vendor/textsplit
$ ls -A
.git
.gitmodules
answer.py
ingest.py
README.md
vendor
```
<!-- /snippet -->

Three leftovers remain, and each causes a question later. An empty `.gitmodules` is still tracked (delete it with `git rm .gitmodules` if no submodule is left). The section in `.git/config` and the repository under `.git/modules/` are still on your disk:

<!-- snippet: ch23/submodule-remove/05-leftovers -->
```text
$ git config list --local | grep ^submodule
submodule.vendor/textsplit.active=true
submodule.vendor/textsplit.url=$LAB/ch23/submodule-remove/remotes/textsplit.git
$ ls .git/modules/vendor
textsplit
```
<!-- /snippet -->

Git keeps the repository on purpose, so that old commits which still contain the gitlink can be checked out without a new clone. The cost shows when someone adds a submodule under the same name again:

<!-- snippet: ch23/submodule-remove/06-readd-refused -->
```text
$ git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit
fatal: A git directory for 'vendor/textsplit' is found locally with remote(s):
  origin	$LAB/ch23/submodule-remove/remotes/textsplit.git
If you want to reuse this local git directory instead of cloning again from
  $LAB/ch23/submodule-remove/remotes/textsplit.git
use the '--force' option. If the local git directory is not the correct repo
or you are unsure what this means choose another name with the '--name' option.
[exit status: 128]
```
<!-- /snippet -->

To remove a submodule completely from your clone, delete the leftovers. 🔴 The first command deletes a repository; if the submodule held unpushed commits, they are gone.

<!-- snippet: ch23/submodule-remove/07-complete-removal -->
```text
$ rm -rf .git/modules/vendor/textsplit
$ git config remove-section submodule.vendor/textsplit
$ git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit
Cloning into '$LAB/ch23/submodule-remove/doc-qa/vendor/textsplit'...
done.
$ git status --short
M  .gitmodules
A  vendor/textsplit
```
<!-- /snippet -->

History is not rewritten by any of this. A checkout of a commit from before the removal has the gitlink again, and the directory is empty until the next `git submodule update --init`.

**A changed URL** shows the role of the local copy in `.git/config`. The library's repository has moved. You record the new URL with `git submodule set-url`, which edits `.gitmodules` and synchronizes your own configuration:

<!-- snippet: ch23/submodule-url/01-set-url -->
```text
$ git submodule set-url vendor/textsplit ../chunking.git
Synchronizing submodule url for 'vendor/textsplit'
$ git diff
diff --git a/.gitmodules b/.gitmodules
index 9f740c3..7902bc0 100644
--- a/.gitmodules
+++ b/.gitmodules
@@ -1,3 +1,3 @@
 [submodule "vendor/textsplit"]
 	path = vendor/textsplit
-	url = ../textsplit.git
+	url = ../chunking.git
$ git config get submodule.vendor/textsplit.url
$LAB/ch23/submodule-url/remotes/chunking.git
$ git -c protocol.file.allow=always submodule update --remote
From $LAB/ch23/submodule-url/remotes/chunking
   e216665..4f00a5b  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Submodule path 'vendor/textsplit': checked out '4f00a5b8bb1f8ba700d273d9ec2f453be23efc75'
$ git commit -am "textsplit moved to chunking.git; update to 0.2.0"
[main 109e5d9] textsplit moved to chunking.git; update to 0.2.0
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git push --recurse-submodules=check origin main
To $LAB/ch23/submodule-url/remotes/doc-qa.git
   907dbd3..109e5d9  main -> main
```
<!-- /snippet -->

Ravi pulls the new `.gitmodules`. His configuration still has the URL that `init` copied months ago:

<!-- snippet: ch23/submodule-url/02-teammate-stale-url -->
```text
$ cd ../ravi-doc-qa
$ git pull --no-recurse-submodules
From $LAB/ch23/submodule-url/remotes/doc-qa
   907dbd3..109e5d9  main       -> origin/main
Updating 907dbd3..109e5d9
Fast-forward
 .gitmodules      | 2 +-
 vendor/textsplit | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
$ cat .gitmodules
[submodule "vendor/textsplit"]
	path = vendor/textsplit
	url = ../chunking.git
$ git config get submodule.vendor/textsplit.url
$LAB/ch23/submodule-url/remotes/textsplit.git
$ git -c protocol.file.allow=always submodule update
fatal: '$LAB/ch23/submodule-url/remotes/textsplit.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
Unable to fetch in submodule path 'vendor/textsplit'; trying to directly fetch 4f00a5b8bb1f8ba700d273d9ec2f453be23efc75:
fatal: '$LAB/ch23/submodule-url/remotes/textsplit.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
fatal: Fetched in submodule path 'vendor/textsplit', but it did not contain 4f00a5b8bb1f8ba700d273d9ec2f453be23efc75. Direct fetching of that commit failed.
[exit status: 128]
```
<!-- /snippet -->

🟢 `git submodule sync` copies the URLs from `.gitmodules` into `.git/config` and into the `origin` remote of each initialized submodule:

<!-- snippet: ch23/submodule-url/03-sync -->
```text
$ git submodule sync
Synchronizing submodule url for 'vendor/textsplit'
$ git config get submodule.vendor/textsplit.url
$LAB/ch23/submodule-url/remotes/chunking.git
$ git -C vendor/textsplit remote get-url origin
$LAB/ch23/submodule-url/remotes/chunking.git
$ git -c protocol.file.allow=always submodule update
From $LAB/ch23/submodule-url/remotes/chunking
   e216665..4f00a5b  main       -> origin/main
 * [new tag]         v0.2.0     -> v0.2.0
Submodule path 'vendor/textsplit': checked out '4f00a5b8bb1f8ba700d273d9ec2f453be23efc75'
```
<!-- /snippet -->

## 23.12 CI consequences

A CI job is a fresh clone made by a script, so every default of this chapter applies to it, and nobody is there to read `git status`.

> **GitHub Actions, not Git.** `actions/checkout` does not check out submodules unless told to: its `submodules` input defaults to `false`, and the README describes the values as "`true` to checkout submodules or `recursive` to recursively checkout submodules" ([action.yml](https://github.com/actions/checkout/blob/v7.0.1/action.yml), [README](https://github.com/actions/checkout/blob/v7.0.1/README.md)). The job's `github.token` is scoped to the repository that triggered the run, so a private submodule in another repository needs a token or an SSH key with access to it, passed through the action's `token` or `ssh-key` input. The README also notes that, without `ssh-key`, URLs beginning with `git@github.com:` are converted to HTTPS. None of this was run for this book.

What follows from the mechanics:

- **An empty directory is not an error to Git.** A job without submodule checkout fails later and elsewhere: an import error, a missing file in a Docker build context, a test that is silently skipped. Add an explicit step such as `git submodule status` and fail if any line starts with `-` or `+`.
- **The job tests the recorded commit**, not the library's latest. A library fix reaches the service only through a pointer commit.
- **The push-order failure of section 23.8 appears in CI first**, as "not our ref" or "did not contain" during checkout, on the commit of the person who forgot to push the library.
- **Trust.** A workflow that recursively checks out submodules of a pull request from a fork lets the fork's `.gitmodules` choose what is cloned onto the runner. Combine that with section 23.4 before enabling recursion for untrusted code ([Chapter 21A](ch21a-actions-security.md)).
- **Docker and archives.** `git archive` does not include submodule contents: the archive of this chapter's superproject contains the entry `vendor/textsplit/` and nothing below it (run for this chapter, no transcript printed). A build that starts from an archive needs the submodules fetched separately.

## 23.13 Subtrees: the dependency's files inside your own history

**In one sentence.** 🟡 `git subtree add` copies another project's files into a subdirectory of your repository as ordinary tracked files, and records in commit messages where they came from, so that later commands can merge newer upstream versions in or extract your changes back out.

**Analogy.** Instead of a reference to page 212 of the other book, you photocopy the page and bind the copy into yours, with a note in the margin saying which printing it was copied from. Every reader of your book has the recipe. The margin note is the only link to the original: if somebody copies a newer printing over it without updating the note, the next update has nothing to go by.

**Precisely.** `git subtree` is a script from Git's `contrib/` directory. The Homebrew Git on this Mac installs it. It has no page in `git help`; its documentation is in the Git source tree, and `git subtree -h` prints the usage. That documentation describes the contrast with submodules itself: subtrees "do not need any special constructions (like `.gitmodules` files or gitlinks) be present in your repository, and do not force end-users of your repository to do anything special or to understand how subtrees work" ([git-subtree](https://github.com/git/git/blob/v2.55.0/contrib/subtree/git-subtree.adoc)). Do not confuse the command with the `subtree` merge strategy of `git merge -s subtree`, which it builds on.

**See it.** Start again from `doc-qa` without any dependency and add the library under the same path:

<!-- snippet: ch23/subtree/01-add -->
```text
$ git subtree add --prefix=vendor/textsplit ../remotes/textsplit.git main --squash
git fetch ../remotes/textsplit.git main
From ../remotes/textsplit
 * branch            main       -> FETCH_HEAD
Added dir 'vendor/textsplit'
$ git log --graph --format="%h %an: %s"
*   fb692e1 Lab User: Merge commit 'c77d389e2c498a974e85fe327f712348bbe6f573' as 'vendor/textsplit'
|\  
| * c77d389 Lab User: Squashed 'vendor/textsplit/' content from commit e216665
* bf78eb9 Lab User: Add keyword answerer
* 1d93b09 Lab User: Add document loader
```
<!-- /snippet -->

`--squash` produced two commits. `c77d389` is a commit with no parent in your history whose tree is the library's tree at upstream commit `e216665`; `fb692e1` merges it into `main` and places that tree at `vendor/textsplit`. Without `--squash` the merge would bring the library's entire history into yours.

<!-- snippet: ch23/subtree/02-what-it-is -->
```text
$ git ls-tree HEAD vendor/
040000 tree bb3d20df131c55a48b035cace5cd1812d87d5332	vendor/textsplit
$ git ls-files vendor
vendor/textsplit/README.md
vendor/textsplit/splitter.py
$ git log -1 --format=%B HEAD^2
Squashed 'vendor/textsplit/' content from commit e216665

git-subtree-dir: vendor/textsplit
git-subtree-split: e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4

$ git status --short
$ ls -A
.git
answer.py
ingest.py
README.md
vendor
```
<!-- /snippet -->

**Inside `.git`.** Nothing special at all. The entry at `vendor/textsplit` has mode `040000`: a tree like any other directory. The files are blobs in your object database. There is no `.gitmodules`, no `.git/modules`, no configuration. The whole mechanism is the two trailer lines in the squash commit's message: `git-subtree-dir` and `git-subtree-split`, the upstream commit that the content corresponds to.

For a teammate there is nothing to learn and nothing to forget:

<!-- snippet: ch23/subtree/03-teammate -->
```text
$ git push origin main
To $LAB/ch23/subtree/remotes/doc-qa.git
   bf78eb9..fb692e1  main -> main
$ cd ..
$ git clone remotes/doc-qa.git ravi-doc-qa
Cloning into 'ravi-doc-qa'...
done.
$ ls ravi-doc-qa/vendor/textsplit
README.md
splitter.py
$ cd doc-qa
```
<!-- /snippet -->

A plain clone, by a person or a CI job, has the library. No `init`, no `update`, no second fetch, no second set of credentials.

**Updating.** 🟡 `git subtree pull` fetches the upstream branch, builds a squash commit for the difference since the recorded `git-subtree-split`, and merges it:

<!-- snippet: ch23/subtree/04-pull -->
```text
# Asha has published textsplit 0.2.0.
$ git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main --squash
From ../remotes/textsplit
 * branch            main       -> FETCH_HEAD
Merge made by the 'ort' strategy.
 vendor/textsplit/splitter.py | 2 ++
 1 file changed, 2 insertions(+)
$ git log --graph --format="%h %an: %s"
*   7241fca Lab User: Merge commit 'c2dc1b7050d0f35c26e98632a0a8916c9f9b61e3'
|\  
| * c2dc1b7 Lab User: Squashed 'vendor/textsplit/' changes from e216665..4980f0b
* | fb692e1 Lab User: Merge commit 'c77d389e2c498a974e85fe327f712348bbe6f573' as 'vendor/textsplit'
|\| 
| * c77d389 Lab User: Squashed 'vendor/textsplit/' content from commit e216665
* bf78eb9 Lab User: Add keyword answerer
* 1d93b09 Lab User: Add document loader
```
<!-- /snippet -->
<!-- snippet: ch23/subtree/05-pull-message -->
```text
$ git log -1 --format=%B HEAD^2
Squashed 'vendor/textsplit/' changes from e216665..4980f0b

4980f0b Reject an overlap that is not smaller than the chunk size

git-subtree-dir: vendor/textsplit
git-subtree-split: 4980f0b1f99fa205fd4882634ce93e661ede41fd
```
<!-- /snippet -->

The new squash commit's message lists the upstream commits it covers and records the new split point. It is an ordinary merge: if you changed the vendored files yourself and upstream changed the same lines, you resolve a normal content conflict in normal files.

The option has to be used consistently. A repository whose subtree was added with `--squash` has none of the upstream commits in its history, so a pull without `--squash` tries to merge two histories with no common ancestor:

<!-- snippet: ch23/lab-15-2-subtree/05-failure -->
```text
# Update the vendored copy, and forget --squash:
$ git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main
From ../remotes/textsplit
 * branch            main       -> FETCH_HEAD
fatal: refusing to merge unrelated histories
[exit status: 128]
$ git status --short --branch
## main...origin/main
```
<!-- /snippet -->

**Contributing back.** Because the files are yours, one commit can change the library and the application together, which a submodule cannot do:

<!-- snippet: ch23/subtree/06-local-change -->
```text
# A change of your own that touches the library and the application in one commit:
$ git commit -am "Split documents by paragraph"
[main e3827e6] Split documents by paragraph
 2 files changed, 9 insertions(+)
$ git show --stat --format="%h %s"
e3827e6 Split documents by paragraph

 ingest.py                    | 4 ++++
 vendor/textsplit/splitter.py | 5 +++++
 2 files changed, 9 insertions(+)
```
<!-- /snippet -->

🟢 `git subtree split` walks your history and synthesizes a history that contains only what happened under the prefix, with the prefix removed from the paths:

<!-- snippet: ch23/subtree/07-split -->
```text
$ git subtree split --quiet --prefix=vendor/textsplit -b textsplit-export
ee9c8f1aeeb272a682e93f0137db86efd7c142e8
$ git log --graph --format="%h %an: %s" textsplit-export
* ee9c8f1 Lab User: Split documents by paragraph
* 4980f0b Asha Rao: Reject an overlap that is not smaller than the chunk size
* e216665 Asha Rao: Add overlap between neighbouring chunks
* ceaafe1 Asha Rao: Add fixed-size splitter
$ git ls-tree --name-only textsplit-export
README.md
splitter.py
$ git show --stat --format="%h %s" textsplit-export
ee9c8f1 Split documents by paragraph

 splitter.py | 5 +++++
 1 file changed, 5 insertions(+)
```
<!-- /snippet -->

Look at the IDs. The synthetic branch ends in `ee9c8f1`, your commit reduced to its library part (`ingest.py` is gone from it), and below it are `4980f0b`, `e216665` and `ceaafe1`: the upstream commits themselves, with their original IDs and Asha as author. The split found them through the `git-subtree-split` trailers, so the result is a branch that upstream can merge or review as a normal contribution. `git subtree push` is a split followed by a push of the result:

<!-- snippet: ch23/subtree/08-push -->
```text
$ git subtree push --quiet --prefix=vendor/textsplit ../remotes/textsplit.git docqa/paragraphs
git push using:  ../remotes/textsplit.git docqa/paragraphs
To ../remotes/textsplit.git
 * [new branch]      ee9c8f1aeeb272a682e93f0137db86efd7c142e8 -> docqa/paragraphs
$ git ls-remote --heads ../remotes/textsplit.git
ee9c8f1aeeb272a682e93f0137db86efd7c142e8	refs/heads/docqa/paragraphs
4980f0b1f99fa205fd4882634ce93e661ede41fd	refs/heads/main
```
<!-- /snippet -->

`--rejoin` merges the synthetic history back into yours so that, in the words of its documentation, "future splits can search only the part of history that has been added since the most recent --rejoin".

**In production.** Vendoring a small, slowly changing dependency into a service where every CI job and every Docker build must work from a plain clone. The price: the repository grows with every vendored version, the link to upstream lives in commit messages that a rebase or a squash-merge of the pull request can destroy, and everyone who updates the copy must use the same command with the same options.

State table:

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git subtree add --squash`, `git subtree pull --squash` | Files under the prefix created or updated | updated to match | two new commits (a squash commit and a merge) | advanced | new objects; `FETCH_HEAD` | unchanged (a fetch) | unchanged |
| `git subtree split -b <branch>` | unchanged | unchanged | unchanged | unchanged | a new branch with synthetic commits | unchanged | unchanged |
| `git subtree push` | unchanged | unchanged | unchanged | unchanged | new synthetic commits | a branch created or updated in the **library's** repository | as for any push |

## 23.14 Submodule, subtree, or a package manager

| Question | Submodule | Subtree | Package manager (pip, npm, Maven, Go modules) |
|---|---|---|---|
| What the consuming repository records | A commit ID (gitlink) and a URL in `.gitmodules` | The files themselves, plus trailers in commit messages | A name and a version, in a manifest and a lock file |
| Where the dependency's content lives | In the dependency's repository; cloned beside yours | In your repository's own objects | In a registry or artifact store; installed at build time |
| After a plain `git clone` | An empty directory | Complete | Manifest only; an install step is required |
| Updating | `update --remote`, then commit the pointer | `git subtree pull --squash` | Change the version, regenerate the lock file |
| Changing the dependency from inside the consumer | Commit in the submodule, push it, then commit the pointer: two repositories, in order | Edit and commit normally; `split` and `push` to offer it upstream | Not possible in place; publish a new version or use the tool's local-override mechanism |
| Access control and licensing separation | Kept: the dependency keeps its own repository and permissions | Lost: whoever can read your repository reads the copy | Kept, through the registry |
| Typical failure | The states of this chapter: uninitialized, stale, unpushed, detached | Lost trailers; mixed `--squash` usage; local edits that conflict on every update | Version conflicts; a registry that is unavailable; unpinned versions |
| Fits | A dependency developed in step with the consumer by people who have access to both; large or access-restricted content | A small dependency that must be present in every clone and changes rarely | Anything that is published with versions, which is most libraries |

**How to decide.** If the dependency is published as a package, use the package manager; it solves versioning, transitive dependencies and security advisories, which neither Git mechanism attempts. If it is not a package and must be present after a plain clone, use a subtree. If it must remain a separate repository (its own access rules, its own release cadence, a size you do not want in your history) and the team will adopt the configuration of section 23.16, use a submodule. If the real wish is "one atomic commit across both", the two projects may belong in one repository ([Chapter 24](ch24-monorepos.md)).

## 23.15 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| The submodule directory is empty after a clone | `git submodule status` shows `-` | `git submodule update --init --recursive` | `git clone --recurse-submodules`; document it in the README; check it in CI |
| `modified: <path> (new commits)` after a pull, with no edits of your own | `git submodule status` shows `+`; `git diff --submodule=log` shows `(rewind)` | `git submodule update` | `submodule.recurse=true`; `git pull --recurse-submodules` |
| A commit about something else changes `<path> \| 2 +-` | `git show --stat <commit>`; the gitlink moved backwards | Unpushed: check out the right commit in the submodule, `git add`, amend. Pushed: a new commit that restores the pointer | Update before committing; avoid `git commit -a` in superprojects; review gitlink changes |
| `not our ref <id>`, or "did not contain <id>. Direct fetching of that commit failed" | `git ls-tree origin/main <path>` against `git ls-remote <library URL>`: the recorded commit is on no branch of the library's remote | The author pushes the library commit; or the pointer is moved to a published commit | `push.recurseSubmodules=check`; CI on a fresh recursive clone |
| Work done inside the submodule vanished after `git submodule update` | `git -C <path> reflog`: a commit made on a detached HEAD | `git -C <path> branch <name> <id>` | Switch to a branch inside the submodule before editing |
| `modified: <path> (modified content)` and `git commit -a` commits nothing | `git submodule foreach 'git status --short'` | Commit inside the submodule, or discard there | Keep consumed submodules clean |
| `CONFLICT (submodule)` | `git ls-files -u`; compare the two commits inside the submodule | Check out a library commit that contains both, `git add <path>`, commit | Move pointers in dedicated, short-lived branches |
| `does not appear to be a git repository` on update after the library moved | `git config get submodule.<name>.url` shows the old URL | `git submodule sync`, then update | Announce URL changes; relative URLs |
| `git subtree pull` ends in `refusing to merge unrelated histories` | The subtree was added with `--squash` and pulled without | Repeat the pull with `--squash` | A script or alias for the update command |

## 23.16 When not to use it, and dangerous edge cases

Do not use a submodule:

- **For a library that is available as a package.** You would rebuild a worse package manager.
- **When contributors cannot be expected to learn it**, for example an open-source project with many occasional contributors.
- **For content from sources you do not trust**, combined with recursive clones (23.4).

Do not use a subtree when the vendored content is large or changes often (every version stays in your history, [Chapter 22](ch22-git-lfs.md) explains why that matters for binaries), or when its access rules must differ from those of the consuming repository.

A configuration that removes most of the submodule failures. It is local configuration, so each clone and each CI job needs it:

```bash
git config set submodule.recurse true            # switch, pull, checkout, reset follow the gitlink
git config set push.recurseSubmodules check      # refuse to push a pointer to an unpublished commit
git config set diff.submodule log                # diffs list the library commits
git config set status.submoduleSummary true      # status shows them too
```

Edge cases:

- 🔴 `git submodule update --force` and `git submodule deinit --force` discard uncommitted changes inside the submodule. Preview with `git submodule foreach 'git status --short'`.
- 🔴 Deleting `.git/modules/<name>` deletes a repository, including commits that were never pushed.
- **A pointer to a commit on a library branch that is later rebased or deleted.** The commit becomes unreachable on the server and will eventually be unobtainable. Record only commits that are on a protected branch or a tag of the library.
- **`update --remote` in CI.** A job that runs it tests a library commit that no superproject commit records, so the run cannot be reproduced. Use it in a scheduled job that opens a pull request with the pointer change.
- **Linked worktrees** of a superproject have incomplete submodule support according to the worktree manual ([Chapter 25](ch25-worktrees.md), section 25.7).
- **Rewriting a subtree's history.** Squash-merging or rebasing the commits that `git subtree` created discards or rewrites the trailers that the next pull depends on.

## 23.17 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git submodule status`, `summary`, `foreach '<read-only command>'`, `git diff --submodule=log`, `git push --recurse-submodules=check`, `git subtree split` | 🟢 SAFE | Nothing in your branches, index or files (`split` adds synthetic commits and, with `-b`, a branch) | not needed | not needed |
| `git submodule add` | 🟢 SAFE | Clones; stages `.gitmodules` and a gitlink; writes `.git/config` and `.git/modules/` | `git ls-remote <url>` | `git rm -f <path>` before committing, and remove the leftovers (23.11) |
| `git submodule init`, `sync`, `set-url`, `set-branch` | 🟢 SAFE | `.git/config`; `set-url` and `set-branch` also edit `.gitmodules` | `cat .gitmodules`; `git config list --local` | Edit the values back |
| `git submodule update` (default checkout) | 🟡 CAUTION | Moves the submodule's HEAD (detached) and its files; refuses to overwrite local edits to files it must change | `git submodule status`; `git -C <path> status` | The submodule's reflog: `git -C <path> reflog` |
| `git submodule update --remote` | 🟡 CAUTION | As above, to the tip of the remote-tracking branch; the superproject then shows a modified gitlink | `git -C <path> fetch && git -C <path> log --oneline HEAD..origin/HEAD` | `git submodule update` returns to the recorded commit |
| `git submodule update --force` | 🔴 DANGEROUS | Overwrites modified tracked files in the submodule | `git submodule foreach 'git status --short'` | None for uncommitted edits |
| `git submodule deinit <path>` | 🟡 CAUTION | Empties the working directory; removes the section from `.git/config`; refuses if there are local modifications unless `--force` | `git -C <path> status` | `git submodule update --init` |
| `git rm <submodule path>` | 🟡 CAUTION | Removes the gitlink, the `.gitmodules` section and the working directory | `git status` | `git restore --staged --worktree .gitmodules <path>`, then `git submodule update --init` |
| `git push --recurse-submodules=on-demand` | 🟡 CAUTION | Pushes in the submodules, then the superproject | `git submodule foreach 'git status --short --branch'` | As for any push |
| `git subtree add`, `git subtree pull` | 🟡 CAUTION | New commits on the current branch (a merge); needs a clean working tree | `git ls-remote <repository> <ref>` | `git reset --hard ORIG_HEAD` if not pushed (🔴 for uncommitted work, [Chapter 11](ch11-reset-revert-restore.md)); `git revert -m 1` if pushed |
| `git subtree push` | 🟡 CAUTION | Creates or updates a branch in the library's repository | `git subtree split` first and inspect the result | Delete or reset that branch in the library's repository |

## 23.18 Version notes

> **Version note.** Older behavior: submodule commands could clone from local paths without restriction. Current behavior: transfers that Git starts by itself over the `file` transport are refused unless `protocol.file.allow` permits them. Since: Git 2.38.1 and the maintenance releases issued with it ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.38.1.adoc)). Recommended: leave the default; use `-c protocol.file.allow=always` on single commands in local test setups.

- The local manual of Git 2.55.0 documents `git submodule add --ref-format`, `set-branch`, `set-url` and `absorbgitdirs`. The last one moves a `.git` directory that is embedded in a submodule's working tree into the superproject's `.git/modules/`.

> **Unverified.** The release in which `git submodule update` began to fetch a missing commit directly by ID ("trying to directly fetch"), and the release that introduced `submodule.recurse`, were not looked up for this chapter. Both behaviors were run on Git 2.55.0 and are shown above.

> **Outdated advice.** "After cloning, run `git submodule init` and then `git submodule update`." It still works. `git clone --recurse-submodules`, or `git submodule update --init --recursive` in an existing clone, does the same in one step and also handles nested submodules.

## 23.19 Practice

- Lab 15.1 (a submodule that breaks for a teammate) and Lab 15.2 (the same dependency as a subtree) in the [Module 15 lab manual](../lab-manual/m15-submodules-subtrees-lfs.md).
- Replay any transcript with `labs/run ch23/<demo>`, for example `labs/run ch23/submodule-update`.
- Two drills. In the sandbox of `ch23/submodule-conflict`, resolve the conflict the other way: merge inside the submodule yourself, and then list everything that must be pushed, and in which order, before a teammate can use your merge. In the sandbox of `ch23/subtree`, find with `git log --grep` the commit that records the current upstream version of the vendored library, and say what would happen to the next `git subtree pull` if that commit's message were edited.

## 23.20 Interview questions

1. What exactly does a superproject store about a submodule, and what does it not store? Where is each piece?
2. A colleague says "our submodule tracks the library's `main`". Correct the statement and explain what `submodule.<name>.branch` does.
3. Why is HEAD detached in a submodule after `git submodule update`? When does that lose work, and how do you get it back?
4. After `git pull`, `git status` shows a modified submodule that you never touched. Explain the state of the three relevant commit IDs, the risk, and the fix.
5. A teammate's pull fails with `not our ref`. Give the root cause, the three commands that prove it, the fix, and the setting that prevents it.
6. Why does Git refuse `file` URLs for submodules by default, and why is a recursive clone of an untrusted repository a security decision?
7. Two branches moved the same gitlink and the merge conflicts. Why can Git not resolve it, when does it resolve it by itself, and what does a correct resolution look like?
8. Explain how `git subtree split` can reproduce the original upstream commit IDs. What would break that?
9. Submodule, subtree, package manager: decide for (a) an internal protocol-definition repository used by eight services, (b) a 300-line utility copied from an open-source project, (c) a tokenizer library published on a package index.
10. You are asked to introduce submodules for a team of thirty. Which four configuration settings and which CI check do you require, and why?

## 23.21 Sources

**Primary sources**

- [git-submodule](https://git-scm.com/docs/git-submodule), [gitsubmodules](https://git-scm.com/docs/gitsubmodules), [gitmodules](https://git-scm.com/docs/gitmodules), [git-push](https://git-scm.com/docs/git-push) (`--recurse-submodules`). The local copies (`git help -m submodule`, `git help -m gitsubmodules`, `git help -m config`) are the Git 2.55.0 text that the transcripts were checked against.
- [git-subtree](https://github.com/git/git/blob/v2.55.0/contrib/subtree/git-subtree.adoc) in Git's `contrib/` directory, read on 2 October 2026; locally, `git subtree -h`.
- [Protocol configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/protocol.adoc); release notes [2.38.1](https://github.com/git/git/blob/master/Documentation/RelNotes/2.38.1.adoc) and [2.30.6](https://github.com/git/git/blob/master/Documentation/RelNotes/2.30.6.adoc).
- Security advisories [GHSA-8h77-4q3w-gfgv](https://github.com/git/git/security/advisories/GHSA-8h77-4q3w-gfgv) (CVE-2024-32002) and [GHSA-vwqx-4fm8-6qc9](https://github.com/git/git/security/advisories/GHSA-vwqx-4fm8-6qc9) (CVE-2025-48384).
- `actions/checkout` [action.yml](https://github.com/actions/checkout/blob/v7.0.1/action.yml) and [README](https://github.com/actions/checkout/blob/v7.0.1/README.md) at v7.0.1, the README read on 2 October 2026.

**Secondary sources**

- Pro Git, [Git Tools: Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules), which documents the failure modes of sections 23.5 to 23.10 from the user's side.
- The Phase 0 report of this course, section 12 (the misconception table), section 13 ("Scale, submodules and large files") and section 14 ("The Git client").

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- Tobias Günther for freeCodeCamp, ["Advanced Git Tutorial"](https://www.youtube.com/watch?v=qsTthZi23VE) (34 min, 2021): includes a submodules segment. Concepts current; mixes `master` and `main` and uses `checkout`.

**Further reading**

- [gitrepository-layout](https://git-scm.com/docs/gitrepository-layout) for `modules/`; [Chapter 24](ch24-monorepos.md) for the alternative of one repository.
