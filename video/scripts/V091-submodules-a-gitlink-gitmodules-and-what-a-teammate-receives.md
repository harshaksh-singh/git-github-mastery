# V091: Submodules: a gitlink, .gitmodules, and what a teammate receives

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 15, Submodules, subtrees, Git LFS
- **Planned minutes.** 24
- **Prerequisites.** V008, V038
- **Textbook sections.** [Chapter 23](../../textbook/ch23-submodules.md), sections 23.1 to 23.4
- **Demo scripts.** `labs/ch23/submodule-add.sh`, `labs/ch23/submodule-clone.sh`

## HOOK

**[ON SCREEN]** Four reports from one week:

1. "I cloned the service and the `vendor/textsplit` directory is empty. The imports fail."
2. "`git pull` worked for everyone yesterday. Today it dies with `not our ref`."
3. "I pulled, changed one line in `ingest.py`, committed, and the reviewer says my commit downgrades the library."
4. "CI is green on my branch and red on `main`, and the only difference is a directory I never touched."

All four are about a submodule: another repository checked out in a subdirectory of yours. A CTO who hears these asks two things. Why does this mechanism fail so often? And should we be using it at all?

Both questions have precise answers, and both start from one fact. The superproject, the repository that contains the submodule, records a commit ID, not a branch, and Git's defaults don't keep the nested checkout in sync with that record.

**[ANIMATION]** cards: id=three question=Three_things_that_should_agree cards=Recorded:the_commit_ID_in_the_superproject|Checked_out:the_commit_in_the_submodule's_working_tree|Available:the_commits_in_the_submodule's_shared_repository numbered=on

Every standard submodule failure is a gap between three things that should agree: the commit ID recorded in the superproject, the commit checked out in the submodule's working tree, and the commits that exist in the submodule's shared repository.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video opens the last module of this part: three ways to bring something into a repository that doesn't live in its history the ordinary way. Submodules, subtrees, and Git LFS.

Today you answer the first report, the empty directory, and you build the model that explains the other three. Hold on to that empty directory. You need two things from earlier: the tree object, Git's listing of one directory, with its entry modes, and what `git clone` transfers.

The projects are `doc-qa`, a document question-answering service owned by your team, and `textsplit`, a small text-chunking library that Asha maintains in a repository of its own. Ravi is your teammate on `doc-qa`.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- say what a superproject stores about a submodule and where each piece is;
- read a gitlink entry in a tree and explain why `git cat-file` cannot show its target;
- take a plain clone through `init` and `update` and say what each writes;
- explain why a recursive clone of an untrusted repository is a security decision.

## CONCEPT

**[ANIMATION]** objects: id=gl cards=commit:bf751ba:tree_(root),tree:root:100644_9f740c3_.gitmodules+100644_09f9084_README.md+100644_b5c3d8b_answer.py+100644_eb72b3e_ingest.py+040000_341fc98_vendor,tree:341fc98:160000_e216665_textsplit,commit:e216665 refs=main>bf751ba missing=e216665 title=The_superproject's_objects

**[ANIMATION]** step: gl.level-2

In one sentence: a submodule is another repository checked out in a subdirectory of yours. Your repository records exactly one thing about it in its history: the ID of the commit that should be checked out there.

Precisely, there are three pieces, in three different places.

**[ON SCREEN]** The table of section 23.2.

| Piece | Where | Versioned in the superproject? | What it holds |
|---|---|---|---|
| The **gitlink** | A tree entry (and index entry) with mode `160000` at the submodule path | Yes | The commit ID the superproject expects there |
| **`.gitmodules`** | A file at the top of the superproject's working tree | Yes | For each submodule: a name, the path, the URL to clone from, optional settings such as `branch` |
| The submodule's **repository** | `.git/modules/<name>/` inside the superproject's Git directory, plus a `.git` file in the submodule's working tree that points to it | No | The submodule's own objects, refs, HEAD, index, configuration |

A fourth, local piece connects them. `git submodule init` copies the URL from `.gitmodules` into the superproject's `.git/config`. From then on Git uses the copy. That's why a changed URL doesn't reach existing clones by itself.

**[ANIMATION]** step: gl.level-3

The point that the rest of the module depends on: the superproject's object database doesn't contain the commit that the gitlink names. A tree entry of mode `160000` is the only place in Git where an object ID names something that the repository isn't required to have. Git doesn't check that the ID exists anywhere when you commit it or when you push it. Everything that makes the entry useful, where to get the object, whether it has been fetched, whether it's checked out, is arranged outside the commit.

**[ANIMATION]** stores: id=plain boxes=.git/config:local|.git/modules/:local|vendor/textsplit/:the_working_tree rows=1:C:empty@bad|2:A:the_URL,_from_.gitmodules@ok|3:B:a_clone_of_textsplit@ok|3:C:e216665_checked_out@ok title=A_plain_clone,_then_init,_then_update

**[ANIMATION]** step: plain.1

**What a teammate receives.** A plain clone transfers the superproject's objects. The gitlink arrives. The commit it names doesn't. Two steps fill the directory.

**[ANIMATION]** end

🟢 SAFE: `git submodule init` registers the submodule by copying the URL into `.git/config`. 🟡 CAUTION: `git submodule update` then clones the repository into `.git/modules/` and checks out the recorded commit. `git submodule update --init` does both, and `--recursive` repeats them for submodules inside submodules. `git clone --recurse-submodules` does everything for a fresh clone.

**[ANIMATION]** decide: id=policy nodes=q1:protocol.<name>.allow|a:http,_https,_git,_ssh|n:ext|q2:everything_else,_file_included|ok:allowed|no:transport_'file'_not_allowed edges=q1>a:always|q1>n:never|q1>q2:user|q2>ok:typed|q2>no:not_typed path=q1,q2,no title=The_per-transport_policy

**[ANIMATION]** step: policy.level-3

**The security side.** Git has a per-transport policy, `protocol.<name>.allow`, with three values: `always`, `never` and `user`. The manual gives the defaults. `http`, `https`, `git` and `ssh` are `always`. `ext` is `never`. Everything else, the `file` transport included, is `user`. Under `user`, a transport may be used only when a person typed the clone, fetch or push. The `git submodule` command marks its transfers as not typed by the user, because the URLs it will use come from `.gitmodules`, a file written by whoever authored the repository.

**[ANIMATION]** say: The value user for file: since Git 2.38.1

The value `user` for `file` dates from the fix for CVE-2022-39253, shipped in Git 2.38.1. The lab's "servers" are bare repositories in a directory, so the submodule URL is a file path, and each command that makes Git clone a submodule on its own initiative is run with `-c protocol.file.allow=always`, for that one command. With a real remote over HTTPS or SSH you never need the option.

**[ANIMATION]** end

When not to use a recursive clone: on a repository you don't trust. A recursive clone is the one common Git operation in which a repository you haven't inspected decides what else gets cloned and where it is written.

## MENTAL MODEL

**[ANIMATION]** say: Your book cites one version of a recipe in another book

The textbook's analogy: a recipe that says "use the stock from page 212 of the other book, third printing". Your book doesn't contain the stock recipe. It contains a precise reference to one version of it. Anyone cooking from your book needs the other book as well, opened at that page.

**[ANIMATION]** say: The reference doesn't update itself

Where the analogy breaks: the other book keeps being reprinted, and your reference doesn't update itself. And the reader can scribble in their copy of the other book without your book noticing, until they compare.

**[ANIMATION]** say: The page cited, the page open, the pages that exist

From this, three values that you'll compare in every submodule diagnosis: the page your book cites, the page the reader's copy is open at, and the pages that exist in the bookshop's edition.

**[ANIMATION]** end

Try it now, on paper, thirty seconds. Draw two boxes, `doc-qa` and `textsplit`. Then draw the two arrows that leave `doc-qa`, and write on each what you predict it carries.

**[PAUSE]**

## DIAGRAM

**[DIAGRAM]** The picture of section 23.2. Draw the superproject's commit and tree, then the gitlink arrow that leaves the box, then the URL arrow, then the three local lines at the bottom.

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

Check your drawing. Two arrows leave the superproject's box. One carries a URL, from a versioned file. The other carries a commit ID, from a tree entry. Neither carries any content of the library. The three lines at the bottom are local: a plain clone has none of them.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch23/submodule-add`. In your clone of `doc-qa`, add the library. Try it first the way you would type it.

```bash
git remote -v
git submodule add ../textsplit.git vendor/textsplit
```

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

"transport 'file' not allowed". That's the transport policy, and you'll return to it. For the lab's directory remotes, the option goes on the one command.

```bash
git -c protocol.file.allow=always submodule add ../textsplit.git vendor/textsplit
git status
```

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

The command cloned the library into `vendor/textsplit` and staged two things. First:

```bash
cat .gitmodules
git config list --local | grep ^submodule
```

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

The versioned file holds the relative URL `../textsplit.git`. A URL that starts with one or two dots is resolved against the superproject's own remote. The local configuration holds the resolved, absolute result. Relative URLs are worth using when both repositories live on the same host: a clone made over HTTPS fetches the submodule over HTTPS, a clone made over SSH uses SSH, and no protocol is written into a versioned file.

Second, the gitlink. Predict the mode of the entry for `vendor/textsplit`. Say it out loud. I'll wait.

**[PAUSE]**

```bash
git ls-files --stage
git -C vendor/textsplit log --oneline --decorate -1
```

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

Four blobs with mode `100644` and one entry with mode `160000`. That last one is the gitlink.

**[ANIMATION]** submodule: id=sub [doc-qa] ...older main; HEAD=main || [vendor/textsplit] ceaafe1-e216665 main origin/main; ceaafe1 v0.1.0; HEAD=main; title:The_library's_own_history => [doc-qa] ...older-bf751ba main; HEAD=main; name:commit || => + link:bf751ba>e216665:records_e216665_(mode_160000); name:link; title:What_the_superproject_records ||

**[ANIMATION]** step: sub.state-1

This is the library's own history. The ID in the entry, `e216665`, is the commit that the library's `main` pointed at when you ran the command. Nothing in the entry says "main".

```bash
cat vendor/textsplit/.git
ls .git/modules/vendor/textsplit
```

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

The submodule's working tree has a `.git` file, the same device a linked worktree uses.

**[ANIMATION]** stores: id=gitfile boxes=vendor/textsplit/:the_submodule's_working_tree|doc-qa/.git/modules/vendor/textsplit/:the_real_Git_directory rows=1:A:.git_(a_file)@hl|1:A:README.md|1:A:splitter.py|2:B:HEAD|2:B:index|2:B:objects|2:B:refs arrows=2:A1>B:gitdir: mono=on title=A_.git_file,_not_a_.git_directory

The real Git directory sits under the superproject's `.git/modules/`. Keeping it there means the repository survives when the working tree directory disappears, for example when you switch to a commit of the superproject from before the submodule existed.

```bash
git diff --cached -- vendor/textsplit
```

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

To the superproject a submodule is a one-line file whose content is "Subproject commit" and an ID. That's how every later change to it appears in diffs and in review.

```bash
git commit -m "Vendor textsplit as a submodule"
git ls-tree HEAD
git submodule status
```

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

`git ls-tree` prints the type `commit` for the entry.

The tree entry names commit `e216665`. Predict: can the superproject show you that object? I'll wait.

**[PAUSE]**

```bash
git cat-file -t HEAD:vendor/textsplit
git -C vendor/textsplit cat-file -t HEAD
git -C vendor/textsplit rev-parse HEAD
```

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

"could not get object info".

**[ANIMATION]** step: sub.link

The commit object isn't in this repository. It lives in the object database of the submodule.

**[ON SCREEN]** The state table for `git submodule add <url> <path>`.

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| `<path>/` created and populated; `.gitmodules` created or extended | `.gitmodules` and a gitlink staged | unchanged | unchanged | `.git/modules/<name>/` created (a clone); `submodule.<name>.url` and `.active` in `.git/config` | unchanged (a fetch from the submodule's remote) | unchanged |

**[TERMINAL]** Replay `labs/run ch23/submodule-clone`. Ravi clones the service. Predict three outputs: the listing of `vendor/textsplit`, `git status`, and the first character of `git submodule status`.

```bash
git clone remotes/doc-qa.git ravi-doc-qa
cd ravi-doc-qa
ls -A vendor/textsplit
git status
git submodule status
```

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

Read the three together. The directory exists and is empty. `git status` says "nothing to commit, working tree clean": an uninitialized submodule isn't a modification, so nothing warns Ravi. Only `git submodule status` tells him, with the leading minus sign. That's report 1, the empty directory, explained.

```bash
git config get submodule.vendor/textsplit.url
git submodule init
git config list --local | grep ^submodule
```

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

`init` copied the URL into `.git/config`. Nothing was downloaded.

```bash
git -c protocol.file.allow=always submodule update
ls -A vendor/textsplit
git submodule status
```

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

"checked out" and the full ID.

**[ANIMATION]** step: plain.3

The directory is populated, and the status line now starts with a space.

**[ON SCREEN]** The prefix table of section 23.3. Memorise it; it is the fastest diagnosis in this module.

| Prefix | Meaning |
|---|---|
| (space) | Initialized, and the checked-out commit equals the recorded one |
| `-` | Not initialized |
| `+` | The checked-out commit differs from the one recorded in the superproject's index |
| `U` | The submodule path has a merge conflict in the superproject |

One step we skip today. The lab's snippet named `04-detached` shows that HEAD in the submodule is detached after `update`. That's the first topic of the next video.

Now the recursive clone, without the option. A quick quiz: after this command, is the superproject there, or is nothing cloned at all? Say it out loud.

**[PAUSE]**

```bash
git clone --recurse-submodules remotes/doc-qa.git asha-doc-qa
```

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

The superproject is there. Its clone worked. Only the clone that Git started by itself was refused.

```bash
git -C asha-doc-qa submodule status
GIT_PROTOCOL_FROM_USER=0 git clone remotes/textsplit.git probe
```

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

The second command reproduces the mechanism.

**[ANIMATION]** step: policy.path

With the variable set to 0, Git treats even a clone you typed as one the user didn't type, and the `file` transport is refused.

**[ANIMATION]** end

With the option on the one command, the recursive clone completes:

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

**[ON SCREEN]** "Outdated advice": "Run `git config --global protocol.file.allow always` to fix submodule errors." That switches a security default off for every repository you will ever clone. Use `-c` for a single command on repositories you created yourself, and leave the setting alone otherwise.

**[ON SCREEN]** The CVE table of section 23.4.

| CVE | Fixed in | What a recursive clone of a hostile repository could do |
|---|---|---|
| CVE-2024-32002 (critical) | 2.45.1 and backports, May 2024 | On a case-insensitive filesystem with symbolic links (the default on macOS), write a hook into `.git/` and run it during the clone |
| CVE-2025-48384 (high) | 2.50.1 and backports, July 2025 | Through a submodule path ending in a carriage return, check content out to an unintended location where a hook could run |

Both are fixed in the Git 2.55.0 this course uses. The second advisory's own workaround is the durable rule: do not recursively clone submodules of repositories you do not trust. Clone without recursion, read `.gitmodules`, and then decide.

## COMMON MISTAKES

Five mistakes to watch for.

1. **"The clone is broken, the vendor directory is empty."** Root cause: a plain clone transfers the gitlink and not the commit it names; the submodule has to be initialized and updated.
2. **Trusting `git status` to report it.** Root cause: an uninitialized submodule is not a modification; only `git submodule status` shows the leading minus.
3. **Believing the submodule follows a branch.** Root cause: the gitlink is a commit ID; nothing in the entry names a branch.
4. **Setting `protocol.file.allow=always` globally.** Root cause: it removes, for every repository, the default that stops Git from using the file transport on its own initiative.
5. **`git clone --recurse-submodules` on an unknown repository.** Root cause: the repository's `.gitmodules` then decides what else is cloned and where it is written, which is where recent client vulnerabilities have been.

## PRODUCTION EXAMPLE

Now, out of the lab. A team keeps prompt templates, a tokenizer vocabulary and protocol definitions in one repository that five services consume. A submodule gives each service an exact, reviewable pin. The pull request that moves the pin shows one line removed and one line added, each "Subproject commit" with an ID. A release of the service is reproducible from one commit ID of the superproject.

**[ANIMATION]** replay: plain

The price is the set of failures on the first slide. So the team's onboarding page has three lines for new engineers. Clone with `--recurse-submodules`. If a vendor directory is empty, run `git submodule update --init`. And read `git submodule status` before you ask why an import fails.

## PRACTICE EXERCISE

Your turn. Do Exercise 15.1, Level 1, "Add a submodule and read what was recorded", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Before you look, write down the three places where something was recorded and what each holds. Predict the mode and type that `git ls-tree` prints for the submodule path, and predict the result of asking the superproject for the object behind it.

The challenge is Exercise 15.7, Level 3, "An empty directory on the build machine", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q421: "What exactly does a superproject store about a submodule, and what does it not store? Where is each piece?"

**[PAUSE]**

Answer out loud. A strong answer separates what is versioned from what is local and gives a location for each piece: a tree entry with its mode, a file at the top of the working tree, a directory under the Git directory, and a configuration key. It says in so many words what the superproject's object database doesn't contain, and what Git doesn't check when you commit or push the entry. And it draws one consequence for a teammate's fresh clone and one for a changed URL.

## RECAP

**[ANIMATION]** step: sub.link

Let's land this. One commit in the library's own history, `e216665`: that's all your repository records about it. You explained the first report, and you have the model for the other three.

You should now be able to say:

- A submodule is a gitlink, a tree entry of mode 160000 that holds a commit ID; a URL in `.gitmodules`; and a separate repository under `.git/modules`.
- The superproject does not contain the submodule's objects and does not check that the recorded commit exists.
- A plain clone leaves the directory empty and `git status` clean; `init` copies the URL and `update` clones and checks out the recorded commit.
- The first character of `git submodule status` is the diagnosis: space, minus, plus or U.
- A recursive clone lets the cloned repository decide what else is fetched, so for untrusted repositories I clone without recursion first.

## HOMEWORK

Read sections 23.1 to 23.4 of [Chapter 23](../../textbook/ch23-submodules.md).

Today you read a gitlink and filled an empty directory, one step at a time. If the three places still blur, that's normal. Draw the two arrows once more before you move on. Next time: submodules in motion, and the detached HEAD. Until then, look at the state first and type second. See you in the next one.
