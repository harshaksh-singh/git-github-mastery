# V038: What a remote is, and git clone step by step

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 7, Remote operations
- **Planned minutes:** 24
- **Prerequisites:** V025
- **Textbook sections:** [Chapter 12](../../textbook/ch12-remote-operations.md), sections 12.2 and 12.3 (with the model of section 12.1)
- **Demo scripts:** `labs/ch12/remote-anatomy.sh`, `labs/ch12/clone-by-hand.sh`, `labs/ch12/clone-options.sh`, `labs/ch12/mirror-refresh.sh`, `labs/ch12/origin-head.sh`

## HOOK

**[ON SCREEN]** "`git status` said 'up to date'. We tagged. The tag does not contain yesterday's fix."

A CTO asks: "`git status` said 'up to date' on the release laptop. We tagged, and the tag does not contain yesterday's fix. Why did Git say that?"

Git said it because it was true about the only thing `git status` looks at, which is a ref, a name that points at a commit, stored on that laptop. `git status` never contacts a server. To see why that sentence is not a technicality, you need to know what a remote is. It's not a connection. It's a few lines of configuration and some refs, all of them in your own `.git`. Keep that laptop in mind. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video opens the module on remote operations. A repository is the dot git folder: the commits, the names that point at them, and the settings. Until now every repository in this course was alone. From here on there are at least two, and the first skill is to keep them apart in your head.

Two things today. First, look at what a remote is inside `.git`: a name, a URL, a refspec, and the refs that refspec creates. Second, take `git clone` apart into six steps and rebuild a clone by hand, so that nothing about a fresh clone is a mystery. On the way you compare a normal clone, a bare clone and a mirror clone by their refs, and you look at `origin/HEAD`, a small ref that goes stale without telling anyone.

The project in this module is `support-bot`, retrieval-augmented answers for a help desk. A bare repository on disk plays the server. A bare repository on disk and GitHub differ in authentication and in the rules a platform adds on top. The Git mechanics are the same.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The four objectives.

After this video you can:

- Describe a remote as a name, URLs and refspecs in the configuration.
- Take `git clone` apart into the commands it performs.
- Explain where `origin/main` is stored and what `origin/HEAD` is.
- Compare a normal clone, a bare clone and a mirror clone by their refs.

## CONCEPT

Start with the model the whole module rests on. There are at least three things called `main`.

**[ANIMATION]** cards: question=Which_command_contacts_the_server? cards=A:git_status|B:git_log_origin/main|C:git_fetch at_1=45 at_2=58 at_3=75

**[ANIMATION]** step: 3

Quick quiz. Which of these commands contacts the server? A, `git status`. B, `git log origin/main`. C, `git fetch`. Your answer?

**[PAUSE]**

**[ANIMATION]** end

**[ON SCREEN]** The three-row table of section 12.1.

```text
Name                          Full ref                   Lives in             Moved by
----------------------------  -------------------------  -------------------  ------------------------------------
your branch                   refs/heads/main            your repository      you: commit, merge, rebase, reset,
                                                                              the second half of pull
your remote-tracking branch   refs/remotes/origin/main   your repository      Git, when it talks to the remote:
                                                                              fetch, pull, a successful push
the server's branch           refs/heads/main            another repository   whoever pushes there
```

It's C, and only C. Git contacts another repository only when you run a command that says so: `clone`, `fetch`, `pull`, `push`, `ls-remote`, and a few `git remote` subcommands. Every other command, including `status`, `log origin/main` and `branch -vv`, reads refs stored in your own `.git`. That is the answer to the hook.

**[ANIMATION]** stores: id=refs boxes=the_remote:another_repository|*your_repository:its_own_.git rows=1:A:refs/heads/main|1:A:refs/heads/feature/reranker|2:B:refs/remotes/origin/main@ref|2:B:refs/remotes/origin/feature/reranker@ref arrows=2:A1>B1:+|2:A2>B2:+ mono=on title=+refs/heads/*:refs/remotes/origin/* at_1=45 at_2=68

**[ANIMATION]** step: boxes

Now the definition. In one sentence: a remote is a name in your repository's configuration that stands for another repository: its URL, and the rules for copying refs between that repository and yours.

**[ANIMATION]** step: refs.2

Precisely: a remote is a configuration section, `[remote "<name>"]`, holding one or more URLs and one or more fetch refspecs. A refspec has the form, optional plus sign, source, colon, destination, and it maps ref names on one side to ref names on the other. The default written by `git clone` and by `git remote add` is `+refs/heads/*:refs/remotes/<name>/*`. Read it aloud: every branch of the remote becomes a ref of yours under `refs/remotes/<name>/`, and the plus sign allows the update even when it is not a fast-forward.

**[ANIMATION]** remotes: [origin] f56c1bb-95671d3-510ee94 main tag:v0.1.0; 510ee94-336d5ee feature/reranker; HEAD=main || [your clone] f56c1bb-95671d3-510ee94 main origin/main origin/HEAD tag:v0.1.0; 510ee94-336d5ee origin/feature/reranker; HEAD=main title=What_a_fresh_clone_holds id=clone

The refs it creates are remote-tracking branches. The glossary defines one as a ref that is used to follow changes from another repository. The data-model manual is blunter: it is how Git stores the last-known state of a branch in a remote repository. Last-known. On screen is a fresh clone of today's project. `main` is your branch. `origin/main` and `origin/feature/reranker` are remote-tracking branches. And `origin` is only the name that `git clone` picks by default.

**[ANIMATION]** stores: boxes=*.git:four_places_per_remote|.git/objects:one_database_for_every_remote rows=1:A:config:_[remote]_and_[branch]|2:A:refs/remotes/<name>/|3:A:their_reflogs|4:A:FETCH__HEAD,_rewritten_by_every_fetch|5:B:objects_from_every_remote mono=off title=Where_a_remote_lives at_1=18 at_2=40 at_3=52 at_4=58 at_5=72

Inside `.git` a remote occupies four places. The `[remote]` and `[branch]` sections of `.git/config`. The refs under `refs/remotes/<name>/`. Their reflogs. And `FETCH_HEAD`, rewritten by every fetch. There is no object store per remote: objects from every remote land in the one object database.

**[ANIMATION]** end

Then `git clone` 🟢. In one sentence: it creates a new repository, registers the source as the remote `origin`, fetches everything the default refspec covers, and checks out one branch. Six steps, each of which you can run yourself.

**[ON SCREEN]** The six steps.

1. Create the directory and an empty repository: `git init`.
2. Write the remote, its URL and the default fetch refspec: `git remote add origin <url>`.
3. Fetch: copy the objects, create a remote-tracking branch for every branch of the remote, copy the tags.
4. Record the remote's default branch as the symbolic ref `refs/remotes/origin/HEAD`.
5. Create one local branch, named after the branch that the remote's `HEAD` points at, starting at the same commit, with that branch as its upstream.
6. Check it out: fill the index and the working tree.

**[ANIMATION]** walk: id=kinds columns=clone,working_tree,branches_land_in,fetch_refspec rows=git_clone:yes:refs/remotes/origin/*:+refs/heads/*:refs/remotes/origin/*|--bare:no:refs/heads/*:none|--mirror:no:refs/heads/*:+refs/*:refs/* title=Three_kinds_of_clone at_1=5 at_2=20 at_3=30

**[ANIMATION]** step: 3

When is a clone not this? With `--bare` and `--mirror`, which have no working tree and copy branches to `refs/heads/*` directly. They differ from each other in one thing, the configuration, and that difference decides whether a "backup" follows its source. You will see it fail.

## MENTAL MODEL

**[ON SCREEN]** "A remote is an address-book entry with a filing instruction."

A picture helps. The textbook's analogy: an entry in an address book with a filing instruction attached. "The supplier we call `origin` is at this address; file our copy of whatever they call X under `origin/X`."

It breaks in two places, and both matter. The entry is not a connection: nothing is live, and the filed copies are as old as your last visit. And the supplier is not special: it is a full Git repository like yours, and the name `origin` exists only in your address book.

**[ANIMATION]** step: clone.state-1

For clone, the analogy is moving into a furnished copy of an office. You receive every document, a board that shows where the head office's bookmarks stood this morning, and one desk set up for work. On screen, the dashed labels are that board, and `main` is your desk. It breaks because nothing ties the copy to the original afterwards except the address on file.

So when you look at `origin/main`, say to yourself: this is where `main` was on the server the last time this repository asked.

## DIAGRAM

Try it now. Thirty seconds, on paper. Draw two boxes, a server and your clone. The server has two branches, `main` and `feature/reranker`, and one tag. Write down every ref your clone has after `git clone`. Then say out loud how many of them are local branches.

**[PAUSE]**

**[DIAGRAM]** Two boxes. Draw the server box and its three refs first. Then your box: the three copies on the right of each arrow, and last, the single local branch at the bottom.

```text
  server/support-bot.git  (bare)                 you/support-bot
  +---------------------------------------+      +------------------------------------------------+
  | HEAD -> refs/heads/main               |      | refs/remotes/origin/HEAD -> origin/main        |
  | refs/heads/main              510ee94  | ---> | refs/remotes/origin/main              510ee94  |
  | refs/heads/feature/reranker  336d5ee  | ---> | refs/remotes/origin/feature/reranker  336d5ee  |
  | refs/tags/v0.1.0             2828fba  | ---> | refs/tags/v0.1.0                      2828fba  |
  +---------------------------------------+      |                                                |
                                                 | refs/heads/main  510ee94   (HEAD -> main)      |
        fetch copies names left to right         +------------------------------------------------+
        push copies names right to left, only the refs you name, only if the rules allow it
```

Here's the answer. The server has two branches. Your clone has two remote-tracking branches and exactly one local branch. The server's `feature/reranker` is not a branch of yours. It's `origin/feature/reranker`, a bookmark of where that branch was when you cloned.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch12/remote-anatomy`. The IDs you see equal the IDs in the book, because replays use the fixed clock.

**Part 1: what a clone wrote down.**

```bash
git clone server/support-bot.git you/support-bot
cd you/support-bot
cat .git/config
```

Predict which sections the configuration has besides `[core]`. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch12/remote-anatomy/01-clone -->
```text
$ git clone server/support-bot.git you/support-bot
Cloning into 'you/support-bot'...
done.
$ cd you/support-bot
$ cat .git/config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
[remote "origin"]
	url = $LAB/ch12/remote-anatomy/server/support-bot.git
	fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
	remote = origin
	merge = refs/heads/main
```
<!-- /snippet -->

Two. `[remote "origin"]` is the whole remote: a URL, an absolute path here because the clone source was a local path, and one refspec. `[branch "main"]` records the upstream of your branch `main`, which a later video covers.

Now compare the refs on the two sides.

<!-- snippet: ch12/remote-anatomy/02-refs -->
```text
$ git remote -v
origin	$LAB/ch12/remote-anatomy/server/support-bot.git (fetch)
origin	$LAB/ch12/remote-anatomy/server/support-bot.git (push)
# Refs in your clone:
$ git show-ref --abbrev
510ee94 refs/heads/main
510ee94 refs/remotes/origin/HEAD
336d5ee refs/remotes/origin/feature/reranker
510ee94 refs/remotes/origin/main
2828fba refs/tags/v0.1.0
# Refs in the server repository:
$ git -C ../../server/support-bot.git show-ref --abbrev
336d5ee refs/heads/feature/reranker
510ee94 refs/heads/main
2828fba refs/tags/v0.1.0
```
<!-- /snippet -->

The server: two branches and a tag. Your clone: the tag under the same name, both branches under `refs/remotes/origin/`, one local branch, and `refs/remotes/origin/HEAD`.

<!-- snippet: ch12/remote-anatomy/03-branches -->
```text
$ git branch -a -vv
* main                            510ee94 [origin/main] Add retrieval config
  remotes/origin/HEAD             -> origin/main
  remotes/origin/feature/reranker 336d5ee Add reranker stub
  remotes/origin/main             510ee94 Add retrieval config
$ git log --oneline --graph --decorate --all
* 336d5ee (origin/feature/reranker) Add reranker stub
* 510ee94 (HEAD -> main, tag: v0.1.0, origin/main, origin/HEAD) Add retrieval config
* 95671d3 Add retriever skeleton
* f56c1bb Add README
```
<!-- /snippet -->

`git branch -a -vv` is the quickest complete view: local branches with their upstream in brackets, then the remote-tracking branches.

The server is a bare repository: no working tree, and its directory is itself the Git directory.

<!-- snippet: ch12/remote-anatomy/04-bare -->
```text
$ ls -F ../../server/support-bot.git
config
description
HEAD
hooks/
info/
objects/
refs/
$ git -C ../../server/support-bot.git config get core.bare
true
$ git -C ../../server/support-bot.git status
fatal: this operation must be run in a work tree
[exit status: 128]
```
<!-- /snippet -->

No `index`, and `git status` refuses. Notice also what the listing lacks: `logs/`. `core.logAllRefUpdates` defaults to true in a repository with a working tree and to false in a bare one, so a plain bare server keeps no reflog, the list of values a ref has had. When a branch on such a server is overwritten, the server has no record of the old value. The video on forced pushes depends on this.

A version note that the textbook attaches here: Git 2.55 works inside any bare repository it finds, `safe.bareRepository=all`, but the 2.55 manual states that `explicit` will be the default in Git 3.0. Under `explicit`, the `git -C <bare-repository>` form these demos use fails, and `git --git-dir=<path>` works.

One line of housekeeping. `git remote set-url` 🟡 CAUTION rewrites the URL.

<!-- snippet: ch12/remote-anatomy/05-relative-url -->
```text
$ git remote set-url origin ../../server/support-bot.git
$ git remote -v
origin	../../server/support-bot.git (fetch)
origin	../../server/support-bot.git (push)
$ git config get --all --show-names --regexp "^(remote|branch)\."
remote.origin.url ../../server/support-bot.git
remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
branch.main.remote origin
branch.main.merge refs/heads/main
```
<!-- /snippet -->

The demos store a relative path so that the commit IDs do not depend on where your lab root is. The last command, `git config get --all --show-names --regexp`, needs Git 2.46 or later. It prints the four lines that are the entire relationship between your clone and the server.

**Part 2: a clone by hand.** `labs/run ch12/clone-by-hand`. Steps 1 and 2.

```bash
git init by-hand
cd by-hand
git remote add origin ../server/support-bot.git
```

<!-- snippet: ch12/clone-by-hand/01-init-remote -->
```text
$ git init by-hand
Initialized empty Git repository in $LAB/ch12/clone-by-hand/by-hand/.git/
$ cd by-hand
$ git remote add origin ../server/support-bot.git
$ git config get --all --show-names --regexp "^remote\."
remote.origin.url ../server/support-bot.git
remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
```
<!-- /snippet -->

`git remote add` wrote the URL and the default refspec. No network activity, no objects. Step 3. Predict: after `git fetch origin`, how many local branches exist?

**[PAUSE]**

<!-- snippet: ch12/clone-by-hand/02-fetch -->
```text
$ git fetch origin
From ../server/support-bot
 * [new branch]      feature/reranker -> origin/feature/reranker
 * [new branch]      main             -> origin/main
 * [new tag]         v0.1.0           -> v0.1.0
$ git show-ref --abbrev
510ee94 refs/remotes/origin/HEAD
336d5ee refs/remotes/origin/feature/reranker
510ee94 refs/remotes/origin/main
2828fba refs/tags/v0.1.0
$ git symbolic-ref refs/remotes/origin/HEAD
refs/remotes/origin/main
$ git status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```
<!-- /snippet -->

None. If you said one, you're in good company. The fetch created remote-tracking branches, a tag and `origin/HEAD`, and nothing else. `git status` still says "No commits yet": HEAD names a `main` that has not been born. Steps 5 and 6:

<!-- snippet: ch12/clone-by-hand/03-switch -->
```text
$ git switch main
Already on 'main'
branch 'main' set up to track 'origin/main'.
$ git config get --all --show-names --regexp "^branch\."
branch.main.remote origin
branch.main.merge refs/heads/main
$ git branch -vv
* main 510ee94 [origin/main] Add retrieval config
$ ls
app
config.yaml
README.md
```
<!-- /snippet -->

**[ANIMATION]** remotes: [server] f56c1bb-95671d3-510ee94 main tag:v0.1.0; 510ee94-336d5ee feature/reranker; HEAD=main || [by-hand] HEAD=none; cmd:git_init,_git_remote_add => || [by-hand] f56c1bb-95671d3-510ee94 origin/main origin/HEAD tag:v0.1.0; 510ee94-336d5ee origin/feature/reranker; HEAD=none; cmd:git_fetch_origin; name:fetch => || + 510ee94 main; HEAD=main; cmd:git_switch_main; name:switch title=A_clone_by_hand id=byhand

**[ANIMATION]** step: switch

`git switch main` found no local `main`, found exactly one remote-tracking branch of that name, and created the branch from `origin/main` with upstream configuration. That's the picture of a fresh clone again, this time built by hand. This is the `--guess` behavior of `git switch`, on by default. The older spelling is `git checkout main`.

**[ANIMATION]** say: A_real_git_clone_differs_in_three_details

A real `git clone` differs from the hand-built version in three details. It takes the name of the initial branch from the remote's `HEAD`, not from your `init.defaultBranch`. It writes `clone: from <url>` into the reflogs. And when the source is a local path it does not transfer a pack: the object files are hard-linked or copied.

**Part 3: options that change the result.** `labs/run ch12/clone-options`.

<!-- snippet: ch12/clone-options/01-origin-branch -->
```text
$ git clone --origin company --branch release/0.1 server/support-bot.git by-name
Cloning into 'by-name'...
done.
$ git -C by-name config get --all --show-names --regexp "^(remote|branch)\."
remote.company.url $LAB/ch12/clone-options/server/support-bot.git
remote.company.fetch +refs/heads/*:refs/remotes/company/*
branch.release/0.1.remote company
branch.release/0.1.merge refs/heads/release/0.1
$ git -C by-name branch -a -vv
* release/0.1                      510ee94 [company/release/0.1] Add retrieval config
  remotes/company/HEAD             -> company/main
  remotes/company/feature/reranker f1552ff Add reranker stub
  remotes/company/main             510ee94 Add retrieval config
  remotes/company/release/0.1      510ee94 Add retrieval config
```
<!-- /snippet -->

`--origin company` changes the name of the remote and with it the prefix of every remote-tracking branch. `--branch release/0.1` changes which local branch is created and checked out. It does not limit what is fetched, and `company/HEAD` still records the remote's own default, `main`.

`--branch` also accepts a tag.

<!-- snippet: ch12/clone-options/04-tag -->
```text
$ git clone --branch v0.1.0 server/support-bot.git at-tag 2>&1 | head -4
Cloning into 'at-tag'...
done.
warning: refs/tags/v0.1.0 5ff339bf8f9ce7c8035bcda803ebf0afe0fc417b is not a commit!
Note: switching to '510ee948fb6354959cf03862f0ebe47c58eb2a74'.
$ git -C at-tag status
Not currently on any branch.
nothing to commit, working tree clean
```
<!-- /snippet -->

The result is a detached HEAD at the tagged commit: HEAD holds a commit ID instead of a branch name. The warning only says that the name given was an annotated tag object and not a commit.

<!-- snippet: ch12/clone-options/05-single-branch -->
```text
$ git clone --single-branch server/support-bot.git narrow
Cloning into 'narrow'...
done.
$ git -C narrow config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
$ git -C narrow branch -r
  origin/HEAD -> origin/main
  origin/main
```
<!-- /snippet -->

`--single-branch` narrows the refspec to one branch. Every later `git fetch` in that clone follows only that branch. `--depth` implies it, and CI systems produce clones like this.

Now bare and mirror. Predict the difference in their refs.

**[PAUSE]**

<!-- snippet: ch12/clone-options/02-bare -->
```text
$ git clone --bare server/support-bot.git copy.git
Cloning into bare repository 'copy.git'...
done.
$ git -C copy.git config get --all --show-names --regexp "^(core\.bare|remote)"
core.bare true
remote.origin.url $LAB/ch12/clone-options/server/support-bot.git
$ git -C copy.git show-ref --abbrev
f1552ff refs/heads/feature/reranker
510ee94 refs/heads/main
510ee94 refs/heads/release/0.1
5ff339b refs/tags/v0.1.0
```
<!-- /snippet -->

<!-- snippet: ch12/clone-options/03-mirror -->
```text
$ git clone --mirror server/support-bot.git mirror.git
Cloning into bare repository 'mirror.git'...
done.
$ git -C mirror.git config get --all --show-names --regexp "^(core\.bare|remote)"
core.bare true
remote.origin.url $LAB/ch12/clone-options/server/support-bot.git
remote.origin.tagopt --no-tags
remote.origin.fetch +refs/*:refs/*
remote.origin.mirror true
$ git -C mirror.git show-ref --abbrev
f1552ff refs/heads/feature/reranker
510ee94 refs/heads/main
510ee94 refs/heads/release/0.1
5ff339b refs/tags/v0.1.0
```
<!-- /snippet -->

The refs are identical. If you looked for the difference there, so does almost everyone. Both are bare, and both copied the branches to `refs/heads/*`. The difference is in the configuration. The `--bare` clone has a URL and no fetch refspec. The `--mirror` clone has the refspec `+refs/*:refs/*`, every ref, same name, forced, and `mirror = true`.

**[ANIMATION]** remotes: [server] 510ee94-04db75f main release/1.0; HEAD=none || [copy.git] 510ee94 main; HEAD=none || [mirror.git] 510ee94 main; HEAD=none => || || [mirror.git] 510ee94-04db75f main release/1.0; HEAD=none; cmd:git_fetch; name:follows => [server] 510ee94-04db75f main; HEAD=none || || [mirror.git] 510ee94-04db75f main; HEAD=none; cmd:git_remote_update_--prune; name:prunes title=A_bare_copy_and_a_mirror id=mirror

**[ANIMATION]** step: state-1

**Part 4: the consequence.** `labs/run ch12/mirror-refresh`. The server has moved: one new commit on `main` and a new branch.

<!-- snippet: ch12/mirror-refresh/01-bare-does-not-follow -->
```text
# The server has moved: one new commit on main and a new branch release/1.0.
$ git ls-remote --branches ../server/support-bot.git
04db75fbdfbdbffc617297a4d0d76042bff057ba	refs/heads/main
04db75fbdfbdbffc617297a4d0d76042bff057ba	refs/heads/release/1.0
$ git -C copy.git fetch
From ../../server/support-bot
 * branch            HEAD       -> FETCH_HEAD
$ git -C copy.git show-ref --abbrev
510ee94 refs/heads/main
$ git -C copy.git config get --all remote.origin.fetch || echo "(no fetch refspec configured)"
(no fetch refspec configured)
```
<!-- /snippet -->

With no refspec, `git fetch` downloads the remote's `HEAD` into `FETCH_HEAD` and moves no ref. This "backup" still has the old `main` and has never heard of `release/1.0`.

<!-- snippet: ch12/mirror-refresh/02-mirror-follows -->
```text
$ git -C mirror.git fetch
From ../../server/support-bot
   510ee94..04db75f  main        -> main
 * [new branch]      release/1.0 -> release/1.0
$ git -C mirror.git show-ref --abbrev
04db75f refs/heads/main
04db75f refs/heads/release/1.0
```
<!-- /snippet -->

The mirror follows.

<!-- snippet: ch12/mirror-refresh/03-mirror-prunes -->
```text
# release/1.0 has been deleted on the server.
$ git -C mirror.git remote update --prune
From ../../server/support-bot
 - [deleted]         (none)     -> release/1.0
$ git -C mirror.git show-ref --abbrev
04db75f refs/heads/main
```
<!-- /snippet -->

And with `--prune` it deletes what the source deleted. That faithfulness is the catch.

**[ANIMATION]** step: mirror.prunes

A mirror reproduces a destructive force push or a branch deletion at its next update, and being bare it keeps no reflog. It is a replica of the present, not a record of the past.

**Part 5: `origin/HEAD`.** `labs/run ch12/origin-head`.

<!-- snippet: ch12/origin-head/01-symref -->
```text
$ cat .git/refs/remotes/origin/HEAD
ref: refs/remotes/origin/main
$ git rev-parse --abbrev-ref origin/HEAD
origin/main
$ git log --oneline -1 origin
510ee94 Add retrieval config
```
<!-- /snippet -->

A symbolic ref, which is a ref that holds the name of another ref. In a files-format repository, it's a one-line file. It makes the bare remote name a valid revision, which is why `git log origin` works. It's a local record, and it goes stale. The server's default branch is now `trunk`. Predict what `git fetch` does to `origin/HEAD`.

**[PAUSE]**

<!-- snippet: ch12/origin-head/02-stale -->
```text
# The server default branch is now trunk (its HEAD was repointed).
$ git ls-remote --symref origin HEAD
ref: refs/heads/trunk	HEAD
510ee948fb6354959cf03862f0ebe47c58eb2a74	HEAD
$ git fetch
From ../../server/support-bot
 * [new branch]      trunk      -> origin/trunk
$ git rev-parse --abbrev-ref origin/HEAD
origin/main
$ git remote set-head origin --auto
'origin/HEAD' has changed from 'main' and now points to 'trunk'
$ git rev-parse --abbrev-ref origin/HEAD
origin/trunk
```
<!-- /snippet -->

Nothing. The fetch brought the new branch and left `origin/HEAD` on `main`. `git remote set-head origin --auto` 🟡 asks the server and repoints it. If the old default branch is later deleted and pruned, the symbolic ref dangles:

<!-- snippet: ch12/origin-head/03-dangling -->
```text
$ cd ../../asha/support-bot
$ git fetch --prune
From ../../server/support-bot
 - [deleted]         (none)     -> origin/main
   refs/remotes/origin/HEAD has become dangling after refs/remotes/origin/main was deleted
$ git rev-parse --verify origin/HEAD
warning: ignoring dangling symref refs/remotes/origin/HEAD
fatal: Needed a single revision
[exit status: 128]
$ git remote set-head origin --auto
'origin/HEAD' has changed from 'main' and now points to 'trunk'
$ git branch -r
  origin/HEAD -> origin/trunk
  origin/trunk
```
<!-- /snippet -->

And a fetch creates `origin/HEAD` when it is missing.

<!-- snippet: ch12/origin-head/04-created-by-fetch -->
```text
$ git remote set-head origin --delete
$ git branch -r
  origin/trunk
$ git fetch --dry-run
$ git branch -r
  origin/HEAD -> origin/trunk
  origin/trunk
```
<!-- /snippet -->

Look at the command that created it: on Git 2.55.0, `git fetch --dry-run` wrote the ref. "Dry run" does not cover this side effect. The textbook's version note: `git fetch` has created the ref when missing since Git 2.48, and what it does when the ref exists and disagrees is the per-remote setting `remote.<name>.followRemoteHEAD`, whose default, `create`, never touches an existing ref. The recommendation is `warn` in long-lived clones.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Reading `git status` as a statement about the server.** Root cause: `status` reads `refs/remotes/origin/main` in your own `.git`, which is as old as your last fetch.
2. **Using `git clone --bare` plus a nightly `git fetch` as a backup.** Root cause: a bare clone has a URL and no fetch refspec, so the fetch writes `FETCH_HEAD` and moves no ref.
3. **Treating a mirror as a backup.** Root cause: a mirror copies every ref, forced, and being bare keeps no reflog, so it reproduces a destructive push or a deletion at its next update.
4. **Scripts that trust `origin/HEAD` after a default-branch rename.** Root cause: `origin/HEAD` is a local symbolic ref that a fetch with the default setting does not update; `git remote set-head origin --auto` does.
5. **Two people saying "origin" and meaning different repositories.** Root cause: the name exists only in each clone's configuration; `git remote -v` shows what it stands for.

## PRODUCTION EXAMPLE

**[ANIMATION]** stores: boxes=the_server:two_branches|*the_nightly_clone:git_clone_--depth_1 rows=1:A:main|1:A:release/2.3|2:B:origin/main@ref|3:B:release/2.3:_invalid_reference@bad arrows=2:A1>B1:fetch mono=off title=--depth_implies_--single-branch at_1=5 at_2=20 at_3=45

**[ANIMATION]** step: 3

Now, out of the lab. A nightly evaluation job clones with `--depth 1`. An engineer debugging in that workspace types `git switch release/2.3` and gets `fatal: invalid reference`, although the branch exists on the server. The clone's refspec does not include it: `--depth` implies `--single-branch`, and the refspec names one branch.

**[ANIMATION]** stores: boxes=the_server:after_the_rename|*an_existing_clone:nobody_ran_set-head rows=1:A:HEAD_->_the_renamed_branch|2:B:origin/HEAD_->_the_old_branch@bad|3:B:git_remote_set-head_origin_-a@ok mono=off title=origin/HEAD_is_a_local_record at_1=5 at_2=35 at_3=75

**[ANIMATION]** step: 3

Second case, same team. After a default-branch rename, every script that says `origin/HEAD` or `origin/master` keeps comparing against the old branch until `set-head` has run in that clone.

**[ON SCREEN]** Layer label: GitHub.

**[ANIMATION]** end

Across the layer boundary: which branch is the default is a property of the server repository, its `HEAD`. On GitHub a repository administrator changes it in the repository settings or by renaming the branch. After a rename GitHub redirects web URLs and retargets open pull requests, but it cannot reach into clones: its documentation lists four commands for every existing clone, ending with `git remote set-head origin -a`. This is described from the documentation.

And the rule for incidents, from the textbook: read `git remote -v` before you read anything else.

## PRACTICE EXERCISE

Your turn. Do Lab 7.1, "A bare server and two clones, watching every ref", in [`lab-manual/m07-remotes.md`](../../lab-manual/m07-remotes.md).

Predict before each step:

- After the clone, which refs exist in the clone and which on the server? Write both lists.
- After a commit in one clone and before any push or fetch, which of the three things called `main` have moved?
- Which command, and only which, will change the other clone's view?

The challenge is Exercise 7.7, Level 3, "the branch that this clone cannot see", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q210: "Take `git clone` apart into separate commands. What does `--mirror` add to `--bare`, and why does the difference matter for a backup?"

**[PAUSE]**

Answer out loud before you open the answers file. A strong answer lists the steps in order and says, for each, what appears in `.git`. It states the difference between the two clone types in terms of configuration, not in terms of what the refs look like on day one. And it is honest about the backup question in both directions: what one of them fails to do, and what the other does too faithfully. If you end by saying what a backup needs that neither gives, you have answered as an engineer and not as a manual.

## RECAP

Let's land this. You should now be able to say:

**[ANIMATION]** step: clone.state-1

A remote is configuration: a name, a URL and a refspec, and the remote-tracking branches under `refs/remotes/` that the refspec creates. `origin/main` is the last-known position of the server's `main`, stored in my own repository and moved only when Git talks to the remote.

**[ANIMATION]** step: kinds.3

`git clone` is init, remote add, fetch, recording `origin/HEAD`, creating one local branch with an upstream, and a checkout. A bare clone has no fetch refspec and does not follow its source. A mirror follows every ref, including deletions and forced updates. `origin/HEAD` is a local record of the server's default branch and has to be repointed after a rename.

## HOMEWORK

Read sections 12.1 to 12.3 of [Chapter 12](../../textbook/ch12-remote-operations.md).

Do Exercise 7.1, Level 1, "what a clone writes down about its remote", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Today the word remote stopped meaning a connection. It's configuration and a few refs in your own repository, and that's how the release laptop could say "up to date" and still be behind. Do Lab 7.1 while this is fresh. Next time: `git fetch`, and which refs move. Until then, look at the state first and type second. See you in the next one.
