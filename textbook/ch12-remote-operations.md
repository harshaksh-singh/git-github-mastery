# Chapter 12: Remote Operations

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch12/`.

## 12.1 Why this matters

Three questions a CTO can ask in the same week:

1. "The deploy job says the hotfix is not on the server. The engineer says they pushed it, and their terminal printed `Everything up-to-date`. Which one is wrong?"
2. "Someone force-pushed with the 'safe' option, `--force-with-lease`, and a colleague's commit still disappeared from the shared branch. How, and where is that commit now?"
3. "`git status` said 'up to date' on the release laptop. We tagged, and the tag does not contain yesterday's fix. Why did Git say that?"

Neither is wrong: the push named a branch that had nothing new (section 12.14). The lease was satisfied by a fetch that nobody looked at, and the commit still sits in places you can name (section 12.8). And `git status` never contacts a server (section 12.4).

All three answers come from one model. There are at least three things called `main`:

| Name | Full ref | Lives in | Moved by |
|---|---|---|---|
| your branch | `refs/heads/main` | your repository | you: commit, merge, rebase, reset, the second half of pull |
| your remote-tracking branch | `refs/remotes/origin/main` | your repository | Git, when it talks to the remote: fetch, pull, a successful push |
| the server's branch | `refs/heads/main` | another repository | whoever pushes there |

Git contacts another repository only when you run a command that says so: `clone`, `fetch`, `pull`, `push`, `ls-remote`, and a few `git remote` subcommands. Every other command, including `status`, `log origin/main` and `branch -vv`, reads refs stored in your own `.git`. A remote operation is fully described by which of the three kinds of ref it reads and which it moves:

| Operation | Server's refs | Your remote-tracking refs | Your branches | Index and working tree |
|---|---|---|---|---|
| `git fetch` | read | moved | untouched | untouched |
| `git pull` | read | moved | current branch moved | updated |
| `git push` | moved | moved, for the refs pushed | untouched | untouched |
| `git clone` | read | created | one created | checked out |

The rest of the chapter makes each cell of that table precise. The demos use one project, `support-bot` (retrieval-augmented answers for a help desk), a bare repository on disk that plays the server, and three clones: yours, Asha's and Ravi's. A bare repository on disk and GitHub differ in authentication and in the rules a platform adds on top. The Git mechanics are the same, and where the platform changes the picture the text says so.

## 12.2 What a remote is

**In one sentence.** A remote is a name in your repository's configuration that stands for another repository: its URL, and the rules for copying refs between that repository and yours.

**Analogy.** An entry in an address book with a filing instruction attached: "the supplier we call `origin` is at this address; file our copy of whatever they call `X` under `origin/X`". The analogy breaks in two places. The entry is not a connection: nothing is live, and the filed copies are as old as your last visit. And the supplier is not special: it is a full Git repository like yours, and the name `origin` exists only in your address book.

**Precisely.** A remote is a configuration section `[remote "<name>"]` holding one or more URLs (`url`, optionally `pushurl`) and one or more fetch refspecs (`fetch`). A refspec has the form `[+]<source>:<destination>` and maps ref names on one side to ref names on the other. The default written by `git clone` and `git remote add` is `+refs/heads/*:refs/remotes/<name>/*`: every branch of the remote becomes a ref of yours under `refs/remotes/<name>/`, and the `+` allows the update even when it is not a fast-forward (section 12.12). The refs it creates are **remote-tracking branches**. The glossary defines one as "a ref that is used to follow changes from another repository", which "should not contain direct modifications or have local commits made to it" ([gitglossary](https://git-scm.com/docs/gitglossary)). The data-model manual is blunter: it is how Git stores the last-known state of a branch in a remote repository ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)). `origin` is only the name that `git clone` picks by default.

**Inside `.git`.** Four places. The `[remote]` and `[branch]` sections of `.git/config`; the refs under `refs/remotes/<name>/`; their reflogs under `logs/refs/remotes/<name>/` (paths as in a files-format repository, [Chapter 3](ch03-git-internals.md)); and `FETCH_HEAD`, rewritten by every fetch. There is no object store per remote. Objects from every remote land in the one object database, which is why fetching from a second remote that shares history transfers very little.

**See it.** A fresh clone, and the configuration it wrote:

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

`[remote "origin"]` is the whole remote: a URL (an absolute path here, because the clone source was a local path) and one refspec. `[branch "main"]` records the upstream of your branch `main`, the subject of section 12.5. `ignorecase` and `precomposeunicode` describe the macOS filesystem ([Chapter 4](ch04-working-tree.md)). Now compare the refs on the two sides:

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

The server has two branches and a tag. Your clone has the tag under the same name, both branches under `refs/remotes/origin/`, and exactly one local branch. The server's `feature/reranker` is not a branch of yours. It is `origin/feature/reranker`, a bookmark of where that branch was when you cloned. `refs/remotes/origin/HEAD` is a symbolic ref that records which branch the server treats as its default (section 12.3).

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

**Picture.**

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

**A bare repository.** The server in every demo is a bare repository: a repository with no working tree, whose directory is itself the Git directory.

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

There is no `index` and no working tree, so nothing can be edited there and commands that need a working tree refuse. That is the point: a repository that only receives pushes must not hold files that a push could leave stale (section 12.9). Notice also what the listing lacks: `logs/`. `core.logAllRefUpdates` defaults to true in a repository with a working tree and to false in a bare one, so a plain bare server keeps no reflog ([core configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/core.adoc)). When a branch on such a server is overwritten, the server has no record of the old value. Section 12.8 depends on this.

> **Version note.** Older behavior: Git works inside any bare repository it finds. Current behavior: the same (`safe.bareRepository=all`), but the manual of Git 2.55 states that `explicit` will be the default in Git 3.0. Under `explicit`, `git -C <bare-repository>`, which this chapter's demos use to look inside the server, fails; `git --git-dir=<path>` works, and fetching from or pushing to a bare repository is not affected. Since: the setting is documented in the `git config` manual of 2.55. Recommended: in scripts, address bare repositories with `--git-dir`.

**The URL in the demos.** One line of housekeeping that every later transcript relies on:

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

🟡 `git remote set-url` rewrites the URL. `git remote -v` prints one line for fetching and one for pushing, because the two can differ (section 12.10). The demos store a relative path so that the commit IDs printed in this book do not depend on where your lab root is: a `git pull` that merges writes the URL into the merge message, and the message is part of what a commit ID is computed from. Real remotes are HTTPS or SSH URLs (section 12.13). `git config get --all --show-names --regexp` needs Git 2.46 or later.

**In production.** When a repository moves (a renamed organization, a migration from a self-hosted server to GitHub), nothing in your objects or branches changes. The fix is one `git remote set-url origin <new-url>` per clone and per CI configuration. The opposite problem causes real incidents: two people say "origin" and mean different repositories, for example a fork and the shared repository. In an incident, read `git remote -v` before you read anything else.

## 12.3 `git clone`, step by step

**In one sentence.** 🟢 `git clone` creates a new repository, registers the source as the remote `origin`, fetches everything the default refspec covers, and checks out one branch.

**Analogy.** Moving into a furnished copy of an office: you receive every document, a board that shows where the head office's bookmarks stood this morning, and one desk set up for work. It breaks because nothing ties the copy to the original afterwards except the address on file.

**Precisely.** Six steps, each of which you can run yourself:

1. Create the directory and an empty repository (`git init`).
2. Write the remote: its URL and the default fetch refspec (`git remote add origin <url>`).
3. Fetch: copy the objects, create a remote-tracking branch for every branch of the remote, copy the tags (`git fetch origin`).
4. Record the remote's default branch as the symbolic ref `refs/remotes/origin/HEAD`.
5. Create one local branch, named after the branch that the remote's `HEAD` points at, starting at the same commit, with that branch as its upstream.
6. Check it out: fill the index and the working tree.

**See it.** The same result built by hand. Steps 1 and 2:

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

Step 3, with step 4 as a side effect:

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

The fetch created remote-tracking branches, a tag and `origin/HEAD`, and nothing else. `git status` still says "No commits yet": there is no local branch, and `HEAD` names a `main` that has not been born. Steps 5 and 6:

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

`git switch main` found no local `main`, found exactly one remote-tracking branch of that name, and created the branch from `origin/main` with upstream configuration. This is the `--guess` behavior of `git switch`, on by default; the older spelling is `git checkout main`. "Already on 'main'" appears because `HEAD` already named the unborn branch. A real `git clone` differs from the hand-built version in three details. It takes the name of the initial branch from the remote's `HEAD`, not from your `init.defaultBranch`. It writes `clone: from <url>` into the reflogs of `HEAD` and of the new branch. And when the source is a local path it does not transfer a pack: the object files are hard-linked or copied (`--local`, the default for paths; a `file://` URL or `--no-local` uses the normal pack transfer).

**State table** for `git clone <url> <directory>`, in the new repository:

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| created: files of the default branch's tip | created to match | `ref: refs/heads/<default>` | created at the remote's tip | `config` (remote and upstream), `refs/remotes/origin/*`, `origin/HEAD`, tags, reflogs | unchanged (read only) | unchanged |

**Options that change the result.**

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

`--origin company` changes the name of the remote and with it the prefix of every remote-tracking branch. `--branch release/0.1` changes which local branch is created and checked out. It does not limit what is fetched, and `company/HEAD` still records the remote's own default, `main`. `--branch` also accepts a tag:

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

The result is a detached HEAD at the tagged commit. The warning only says that the name given was an annotated tag object and not a commit. A Docker build that clones "a version" like this has no current branch, so a plain `git pull` inside it stops and asks which branch you mean.

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

`--single-branch` narrows the refspec to one branch. Every later `git fetch` in that clone follows only that branch. `--depth <n>` implies it, and CI systems produce clones like this; section 12.12 widens one. Shallow and partial clones (`--depth`, `--filter`) belong to Chapter 26, Performance.

**Bare and mirror clones.**

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

Both are bare, and both copied the branches to `refs/heads/*` instead of `refs/remotes/origin/*`. The difference is in the configuration. The `--bare` clone has a URL and no fetch refspec. The `--mirror` clone has the refspec `+refs/*:refs/*` (every ref, same name, forced) and `mirror = true`, which makes a push from it behave as `git push --mirror`. The consequence appears when the source moves:

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

The mirror follows, and with `--prune` it deletes what the source deleted. That faithfulness is the catch. A mirror reproduces a destructive force push or a branch deletion at its next update, and being bare it keeps no reflog. It is a replica of the present, not a record of the past. A backup needs history of its own: reflogs switched on in the mirror (`core.logAllRefUpdates`), or periodic bundles (section 12.13).

**`origin/HEAD`.**

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

In a files-format repository the symbolic ref is a one-line file. It makes the bare remote name a valid revision: `origin` resolves to `refs/remotes/origin/HEAD` (the last rule of the name lookup in [gitrevisions](https://git-scm.com/docs/gitrevisions)), which is why `git log origin` works. Scripts use it to find the default branch without hard-coding `main`. It is a local record, and it goes stale:

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

`git ls-remote --symref` asks the server, whose default is now `trunk`. The fetch brought the new branch and left `origin/HEAD` alone. 🟡 `git remote set-head origin --auto` asks the server and repoints it. If the old default branch is later deleted and pruned, the symbolic ref dangles until someone repairs it:

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

A fetch creates `origin/HEAD` when it is missing:

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

Look at the command that created it: on Git 2.55.0 `git fetch --dry-run` wrote the ref. "Dry run" does not cover this side effect. What a fetch does when `origin/HEAD` exists and disagrees with the server is a per-remote setting, `remote.<name>.followRemoteHEAD`, whose default `create` never touches an existing ref:

<!-- snippet: ch12/follow-remote-head/01-warn -->
```text
$ git rev-parse --abbrev-ref origin/HEAD
origin/main
$ git config set remote.origin.followRemoteHEAD warn
$ git fetch
hint: Run 'git remote set-head origin trunk' to follow the change, or set
hint: 'remote.origin.followRemoteHEAD' configuration option to a different value
hint: if you do not want to see this message. Specifically running
hint: 'git config set remote.origin.followRemoteHEAD warn-if-not-branch-trunk'
hint: will disable the warning until the remote changes HEAD to something else.
hint: Disable this message with "git config set advice.fetchRemoteHEADWarn false"
'HEAD' at 'origin' is 'trunk', but we have 'main' locally.
$ git rev-parse --abbrev-ref origin/HEAD
origin/main
```
<!-- /snippet -->

`warn` reports the mismatch and changes nothing. The hint proposes a value that silences the warning for one branch name. On Git 2.55.0 the spelling printed in the hint does not silence anything; the spelling described in the `git config` manual, `warn-if-not-<branch>`, does:

<!-- snippet: ch12/follow-remote-head/02-silence -->
```text
# The value suggested by the hint above, then the value described in the manual:
$ git config set remote.origin.followRemoteHEAD warn-if-not-branch-trunk
$ git fetch 2>&1 | tail -1
'HEAD' at 'origin' is 'trunk', but we have 'main' locally.
$ git config set remote.origin.followRemoteHEAD warn-if-not-trunk
$ git fetch
```
<!-- /snippet -->

`always` makes every fetch follow the server silently:

<!-- snippet: ch12/follow-remote-head/03-always -->
```text
$ git config set remote.origin.followRemoteHEAD always
$ git fetch
$ git rev-parse --abbrev-ref origin/HEAD
origin/trunk
```
<!-- /snippet -->

> **Version note.** Older behavior: `git fetch` never wrote `refs/remotes/<remote>/HEAD`; it came from `git clone` or `git remote set-head`. Current behavior: `git fetch` creates it when missing and honors `remote.<name>.followRemoteHEAD` (`create`, `warn`, `warn-if-not-<branch>`, `always`, `never`). Since: Git 2.48 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.48.0.adoc)). A global `fetch.followRemoteHEAD` was added in Git 2.56 (not run here; [fetch configuration at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/config/fetch.adoc)). Recommended: `warn` in long-lived clones, so that a renamed default branch announces itself.

> **GitHub, not Git.** Which branch is the default is a property of the server repository, its `HEAD`. On GitHub a repository administrator changes it in the repository settings ([Changing the default branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/changing-the-default-branch)) or by renaming the branch. After a rename GitHub redirects web URLs and retargets open pull requests, but it cannot reach into clones: its documentation lists four commands for every existing clone, ending with `git remote set-head origin -a` ([Renaming a branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/renaming-a-branch)).

**In production.** A nightly evaluation job clones with `--depth 1`. An engineer debugging in that workspace types `git switch release/2.3` and gets `fatal: invalid reference`, although the branch exists on the server: the clone's refspec does not include it. And after a default-branch rename, every script that says `origin/HEAD` or `origin/master` keeps comparing against the old branch until `set-head` has run in that clone.

## 12.4 `git fetch`: which refs move

**In one sentence.** 🟢 `git fetch` asks a remote where its refs point, downloads the objects you lack, and moves your remote-tracking refs to match; it never moves a local branch, the index or the working tree.

**Analogy.** A scout returns and you redraw the wall map: the other team's flags are placed where the scout saw them. Your own flags stay where they are, and the map starts to age the moment it is drawn. The analogy breaks in one place: the scout also brings back a complete copy of everything the other team built, not only the positions.

**Precisely.** `git fetch [<remote>] [<refspec>...]`. The remote defaults to the upstream remote of the current branch, otherwise `origin`. Without a refspec on the command line, the configured `remote.<name>.fetch` values select the server's refs and say which local ref records each. For every selected ref Git downloads missing objects and updates the destination if the update is a fast-forward or the refspec begins with `+`. Three extras: tags that point into the fetched history are created (tag following), `FETCH_HEAD` is rewritten, and a missing `origin/HEAD` is created.

**Inside `.git`.** New objects; `refs/remotes/<remote>/*` and their reflogs; possibly `refs/tags/*`; `FETCH_HEAD`. Not touched: `refs/heads/*`, `HEAD`, `index`.

**See it.** Asha has published a commit on `main`, a new branch and a tag. You have not fetched since you cloned:

<!-- snippet: ch12/fetch-anatomy/01-stale-status -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
$ git show-ref --abbrev
510ee94 refs/heads/main
510ee94 refs/remotes/origin/HEAD
510ee94 refs/remotes/origin/main
```
<!-- /snippet -->

"Your branch is up to date with 'origin/main'" compares two refs in your own repository, both at `510ee94`. No connection was made. The sentence is true of your last fetch and says nothing about the server. To ask the server without changing anything, use `git ls-remote`:

<!-- snippet: ch12/fetch-anatomy/02-ls-remote -->
```text
$ git ls-remote origin
ef22149d97a296904ccbf984cf520a1fc387e195	HEAD
698e2261b0e2c60654fc059c6016c8d743a05571	refs/heads/feature/reranker
ef22149d97a296904ccbf984cf520a1fc387e195	refs/heads/main
effd2621f6264b45f395c4ba776533482d6f466b	refs/tags/v0.1.0
ef22149d97a296904ccbf984cf520a1fc387e195	refs/tags/v0.1.0^{}
```
<!-- /snippet -->

One line per ref on the server; `main` is at `ef22149`. The line ending in `^{}` is the commit that the annotated tag points to. `git ls-remote` accepts `--branches`, `--tags` and name patterns, and with `--exit-code` it fails when nothing matches, which is how a script should test whether a branch exists on a server.

<!-- snippet: ch12/fetch-anatomy/03-fetch -->
```text
$ git fetch
From ../../server/support-bot
   510ee94..ef22149  main             -> origin/main
 * [new branch]      feature/reranker -> origin/feature/reranker
 * [new tag]         v0.1.0           -> v0.1.0
$ cat .git/FETCH_HEAD
ef22149d97a296904ccbf984cf520a1fc387e195		branch 'main' of ../../server/support-bot
698e2261b0e2c60654fc059c6016c8d743a05571	not-for-merge	branch 'feature/reranker' of ../../server/support-bot
effd2621f6264b45f395c4ba776533482d6f466b	not-for-merge	tag 'v0.1.0' of ../../server/support-bot
```
<!-- /snippet -->

`510ee94..ef22149  main -> origin/main` is a fast-forward of a remote-tracking branch, printed as a range that you can paste into `git log`. `* [new branch]` and `* [new tag]` are creations. The name after the arrow is always a ref of yours. `FETCH_HEAD` holds one line per fetched ref: object ID, a marker, a description. Exactly one line is not marked `not-for-merge`: the upstream of the branch you are on. That line is what `git pull` integrates (section 12.6).

<!-- snippet: ch12/fetch-anatomy/04-after -->
```text
$ git show-ref --abbrev
510ee94 refs/heads/main
ef22149 refs/remotes/origin/HEAD
698e226 refs/remotes/origin/feature/reranker
ef22149 refs/remotes/origin/main
effd262 refs/tags/v0.1.0
$ git status
On branch main
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
```
<!-- /snippet -->

`refs/heads/main` did not move. `git status`, still without any network access, now gives a different answer because one of the two refs it compares has changed.

<!-- snippet: ch12/fetch-anatomy/05-graph -->
```text
$ git log --oneline --graph --decorate --all
* 698e226 (origin/feature/reranker) Add reranker stub
* ef22149 (tag: v0.1.0, origin/main, origin/HEAD) Implement retrieval
* 510ee94 (HEAD -> main) Add retrieval config
* 95671d3 Add retriever skeleton
* f56c1bb Add README
$ git log --oneline main..origin/main
ef22149 Implement retrieval
```
<!-- /snippet -->

Between a fetch and an integration you can inspect exactly what arrived: `main..origin/main` lists the commits the remote has and your branch lacks. This is the practical argument for fetching instead of pulling: you look first and decide second.

<!-- snippet: ch12/fetch-anatomy/06-reflog -->
```text
$ git reflog show origin/main
ef22149 refs/remotes/origin/main@{0}: fetch: fast-forward
$ git reflog show main
510ee94 main@{0}: clone: from $LAB/ch12/fetch-anatomy/server/support-bot.git
```
<!-- /snippet -->

Every remote-tracking ref has a reflog. Its entries are a history of what you observed on the server, and in plain Git it is the only such history, because the bare server keeps none. The reflog of the local branch shows that it has not moved since the clone.

<!-- snippet: ch12/fetch-anatomy/07-integrate -->
```text
$ git merge --ff-only origin/main
Updating 510ee94..ef22149
Fast-forward
 app/retriever.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

Integration is a separate, local step, here a fast-forward merge. `## main...origin/main` with nothing in brackets means the two refs are equal.

**Picture.**

```text
  before git fetch                                  after git fetch

  server   ...---510ee94---ef22149   main           server   unchanged
  you      ...---510ee94             main           you      ...---510ee94---ef22149
                 origin/main                                      main      origin/main
                                                                  (HEAD)    tag: v0.1.0
```

**State table** for `git fetch`:

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged | unchanged | unchanged | unchanged | remote-tracking refs and their reflogs; followed tags; `FETCH_HEAD`; `origin/HEAD` if missing; new objects | unchanged | unchanged |

**Fetching one branch, or from a URL.**

<!-- snippet: ch12/fetch-anatomy/08-fetch-one-branch -->
```text
$ git fetch origin main
From ../../server/support-bot
 * branch            main       -> FETCH_HEAD
   ef22149..3f226f1  main       -> origin/main
$ cat .git/FETCH_HEAD
3f226f11ffbe22690dad919d155901b0885028cc		branch 'main' of ../../server/support-bot
$ git status -sb
## main...origin/main [behind 1]
```
<!-- /snippet -->

With a branch named on the command line only that branch is fetched, and `FETCH_HEAD` has a single line. `origin/main` is updated as well, because the configured refspec says where `main` of `origin` is recorded.

<!-- snippet: ch12/fetch-anatomy/09-fetch-url -->
```text
$ git fetch ../../server/support-bot.git feature/reranker
From ../../server/support-bot
 * branch            feature/reranker -> FETCH_HEAD
$ cat .git/FETCH_HEAD
698e2261b0e2c60654fc059c6016c8d743a05571		branch 'feature/reranker' of ../../server/support-bot
$ git log --oneline -1 FETCH_HEAD
698e226 Add reranker stub
```
<!-- /snippet -->

A fetch from a URL records its result in `FETCH_HEAD` and nowhere else, although the URL is the same repository as `origin`. Git knows remotes by name, not by URL. Use this form for a single look at somebody's branch (`git log FETCH_HEAD`).

**Tags.** A fetch creates tags that point into the history it fetched. It does not update a tag you already have:

<!-- snippet: ch12/fetch-tags/01-moved-tag -->
```text
$ git ls-remote --tags origin
e4e2561179ddf88e121ea1ebbb2485416f92363c	refs/tags/experiment/rejected-1
f858aefbb840dff2a665a6adbbaf8103bb645238	refs/tags/v0.1.0
99b643016420ca155f7432cf4555c1991c7679a5	refs/tags/v0.1.0^{}
$ git fetch
From ../../server/support-bot
   510ee94..99b6430  main       -> origin/main
$ git show-ref --abbrev --tags
5ff339b refs/tags/v0.1.0
```
<!-- /snippet -->

On the server `v0.1.0` has been moved by a forced tag push, and a second tag sits on a commit that is on no branch. The plain fetch brought neither: your `v0.1.0` already exists, and the other tag does not point into fetched history.

<!-- snippet: ch12/fetch-tags/02-fetch-tags -->
```text
$ git fetch --tags
From ../../server/support-bot
 * [new tag] experiment/rejected-1 -> experiment/rejected-1
 ! [rejected] v0.1.0                -> v0.1.0  (would clobber existing tag)
[exit status: 1]
$ git show-ref --abbrev --tags
e4e2561 refs/tags/experiment/rejected-1
5ff339b refs/tags/v0.1.0
```
<!-- /snippet -->

<!-- snippet: ch12/fetch-tags/03-force -->
```text
$ git fetch --tags --force
From ../../server/support-bot
 t [tag update]      v0.1.0     -> v0.1.0
$ git show-ref --abbrev --tags
e4e2561 refs/tags/experiment/rejected-1
f858aef refs/tags/v0.1.0
```
<!-- /snippet -->

`--tags` asks for every tag: the new one arrives, the moved one is rejected ("would clobber existing tag"), and only 🟡 `git fetch --tags --force` replaces it. Until someone forces, your `v0.1.0` and the server's are different commits under one name, and a build "by tag" gives different results on different machines. That is why moving a published tag is a release incident and not a convenience ([Chapter 14B](ch14b-config-tags-signing.md)).

```text
Observed behavior : "Your branch is up to date with 'origin/main'", yet the server has newer commits.
Git state         : refs/heads/main and refs/remotes/origin/main name the same commit; the server's
                    refs/heads/main names a newer one.
Mechanism         : git status compares two local refs. It opens no connection.
Root cause        : origin/main is a record of your last fetch, not a view of the server.
Why Git does this : every command except the transfer commands works offline and instantly; a status
                    that needed the network would be slow, and useless on a plane.
Correct fix       : git fetch, then read the status again; or git ls-remote origin main to ask the
                    server without changing anything.
Prevention        : fetch before any decision that depends on the server (tagging, releasing, cutting
                    a hotfix branch). In scripts compare against git ls-remote, never against a
                    remote-tracking ref of unknown age.
```

**In production.** A release engineer tags from a laptop whose status said "up to date". The last fetch was two days old, so the tag misses yesterday's hotfix. The control is not "be careful". It is a release script that begins with `git fetch` and refuses to continue unless `git rev-parse HEAD` equals the ID that `git ls-remote origin refs/heads/main` prints.

## 12.5 Upstream branches and `push.default`

**In one sentence.** The upstream of a local branch is the branch on a remote that `status` compares it with and that `pull` integrates from; it is two lines of configuration.

**Analogy.** A default correspondent printed on a letter template, so that `pull` and `push` need no address. It breaks because incoming and outgoing mail can have different defaults: `@{upstream}` and `@{push}` are two questions (section 12.10).

**Precisely.** `branch.<name>.remote` names a remote. `branch.<name>.merge` names a ref on that remote, such as `refs/heads/main`: the server's name, not your remote-tracking ref. `<branch>@{upstream}`, short `@{u}`, resolves the pair to the remote-tracking branch that records it. `git status` and `git branch -vv` use it for the ahead and behind counts, `git pull` for what to integrate, and `git push` for where to push under the default `push.default`.

**Inside `.git`.** Only `.git/config`. An upstream is not a ref and not an object.

**See it.** A new local branch has no upstream, and a bare 🟡 `git push` refuses to guess:

<!-- snippet: ch12/upstream-config/01-no-upstream -->
```text
$ git switch -c feature/eval-harness
Switched to a new branch 'feature/eval-harness'
$ git branch -vv
* feature/eval-harness b83418c Add eval harness entry point
  main                 510ee94 [origin/main] Add retrieval config
$ git push
fatal: The current branch feature/eval-harness has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin feature/eval-harness

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.

[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch12/upstream-config/02-push-u -->
```text
$ git push -u origin feature/eval-harness
To ../../server/support-bot.git
 * [new branch]      feature/eval-harness -> feature/eval-harness
branch 'feature/eval-harness' set up to track 'origin/feature/eval-harness'.
$ git config get --all --show-names --regexp "^branch\.feature/eval-harness\."
branch.feature/eval-harness.remote origin
branch.feature/eval-harness.merge refs/heads/feature/eval-harness
$ git branch -vv
* feature/eval-harness b83418c [origin/feature/eval-harness] Add eval harness entry point
  main                 510ee94 [origin/main] Add retrieval config
```
<!-- /snippet -->

`-u` (`--set-upstream`) pushes and then writes the two keys. Look at the value of `merge`: the name of the branch on the remote.

<!-- snippet: ch12/upstream-config/03-shorthands -->
```text
$ git rev-parse --abbrev-ref @{upstream}
origin/feature/eval-harness
$ git rev-parse --symbolic-full-name @{u} @{push}
refs/remotes/origin/feature/eval-harness
refs/remotes/origin/feature/eval-harness
$ git log --oneline @{u}..
fc5bd70 Add first eval case
$ git status -sb
## feature/eval-harness...origin/feature/eval-harness [ahead 1]
```
<!-- /snippet -->

`@{u}` resolves to the remote-tracking ref. `@{push}` is where `git push` would send the branch; with one remote it is the same ref. `git log @{u}..` lists what you have not pushed, and `git log ..@{u}` what you have fetched and not integrated.

<!-- snippet: ch12/upstream-config/04-guess -->
```text
$ git switch feature/reranker
Switched to a new branch 'feature/reranker'
branch 'feature/reranker' set up to track 'origin/feature/reranker'.
$ git config get --all --show-names --regexp "^branch\.feature/reranker\."
branch.feature/reranker.remote origin
branch.feature/reranker.merge refs/heads/feature/reranker
```
<!-- /snippet -->

<!-- snippet: ch12/upstream-config/05-branch-u -->
```text
$ git switch -c docs/runbook main
Switched to a new branch 'docs/runbook'
$ git rev-parse --abbrev-ref @{u}
fatal: no upstream configured for branch 'docs/runbook'
[exit status: 128]
$ git branch -u origin/main
branch 'docs/runbook' set up to track 'origin/main'.
$ git status -sb
## docs/runbook...origin/main
$ git branch --unset-upstream
$ git status -sb
## docs/runbook
```
<!-- /snippet -->

Switching to a name that exists only as a remote-tracking branch creates the local branch with its upstream (the guess from section 12.3). 🟡 `git branch -u` sets an upstream for an existing branch without pushing, and `--unset-upstream` removes it. The ways an upstream comes to exist:

| Command | Upstream is set |
|---|---|
| `git clone` | for the initial branch |
| `git switch <name>` (guess), `git switch -c <new> <remote>/<branch>` | when the start point is a remote-tracking branch (`branch.autoSetupMerge`, default `true`) |
| `git push -u <remote> <branch>` | after a successful push |
| `git branch -u <remote>/<branch>` | explicitly, no transfer |
| `git push` with `push.autoSetupRemote=true` | on the first push of a branch that has none |

<!-- snippet: ch12/upstream-config/06-auto-setup-remote -->
```text
$ git config set push.autoSetupRemote true
$ git push
To ../../server/support-bot.git
 * [new branch]      docs/runbook -> docs/runbook
branch 'docs/runbook' set up to track 'origin/docs/runbook'.
$ git branch -vv
* docs/runbook         9416de1 [origin/docs/runbook] Start the runbook
  feature/eval-harness fc5bd70 [origin/feature/eval-harness: ahead 1] Add first eval case
  feature/reranker     336d5ee [origin/feature/reranker] Add reranker stub
  main                 510ee94 [origin/main] Add retrieval config
```
<!-- /snippet -->

**`push.default`: what a bare `git push` updates.**

<!-- snippet: ch12/upstream-config/07-simple-name-mismatch -->
```text
$ git switch -c latency-fix origin/main
Switched to a new branch 'latency-fix'
branch 'latency-fix' set up to track 'origin/main'.
$ git branch -vv
  docs/runbook         9416de1 [origin/docs/runbook] Start the runbook
  feature/eval-harness fc5bd70 [origin/feature/eval-harness: ahead 1] Add first eval case
  feature/reranker     336d5ee [origin/feature/reranker] Add reranker stub
* latency-fix          70d0911 [origin/main: ahead 1] Set request timeout
  main                 510ee94 [origin/main] Add retrieval config
$ git push
fatal: The upstream branch of your current branch does not match
the name of your current branch.  To push to the upstream branch
on the remote, use

    git push origin HEAD:main

To push to the branch of the same name on the remote, use

    git push origin HEAD

To choose either option permanently, see push.default in 'git help config'.

To avoid automatically configuring an upstream branch when its name
won't match the local branch, see option 'simple' of branch.autoSetupMerge
in 'git help config'.

[exit status: 128]
```
<!-- /snippet -->

`latency-fix` was created from `origin/main`, so automatic setup made `origin/main` its upstream. Under the default `simple`, Git refuses to push when the upstream's name differs from the branch's name: it cannot know whether you mean "update `main`" or "publish `latency-fix`". The other values of `push.default` each answer that question. `-c push.default=<value>` with `--dry-run` shows them without changing anything:

<!-- snippet: ch12/upstream-config/08-push-default-dry-runs -->
```text
$ git -c push.default=upstream push --dry-run
To ../../server/support-bot.git
   510ee94..70d0911  latency-fix -> main
$ git -c push.default=current push --dry-run
To ../../server/support-bot.git
 * [new branch]      latency-fix -> latency-fix
$ git -c push.default=nothing push --dry-run
fatal: You didn't specify any refspecs to push, and push.default is "nothing".
[exit status: 128]
$ git -c push.default=matching push --dry-run
To ../../server/support-bot.git
   b83418c..fc5bd70  feature/eval-harness -> feature/eval-harness
```
<!-- /snippet -->

| Value | A bare `git push` on `latency-fix`, upstream `origin/main` |
|---|---|
| `simple` (default since Git 2.0) | refuses: the names differ |
| `upstream` | updates `main` on the server |
| `current` | creates or updates `latency-fix` on the server |
| `nothing` | refuses: you must name a refspec |
| `matching` (default before Git 2.0) | pushes every local branch that has a branch of the same name on the server |

Read the last transcript line again. Under `matching` the command pushed `feature/eval-harness`, a branch you were not on, and did not push the branch you were on. That is why the default changed ([push configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/push.adoc)).

**In production.** An ML engineer branches `exp/lr-sweep` from `origin/main` and commits a sweep configuration. If their configuration says `push.default=upstream`, a bare `git push` sends those commits straight to `main`. With `simple` it stops. Two clean setups for topic branches: `branch.autoSetupMerge=simple` (an upstream only when the names match; Git 2.37 or later), or `git switch -c <name> --no-track origin/main` together with `push.autoSetupRemote`.

## 12.6 `git pull`: fetch plus one integration step

**In one sentence.** 🟡 `git pull` is `git fetch` followed by one integration of the fetched upstream into the current branch: a fast-forward, a merge or a rebase; when the two branches have diverged, Git makes you say which.

**Analogy.** "Collect the mail and file it" as a single instruction. It breaks when filing needs a decision: if both sides have new commits there are two legitimate ways to combine them, they produce different histories, and pull will not choose for you.

**Precisely.** Step 1 runs `git fetch` with the same arguments, so remote-tracking refs and `FETCH_HEAD` are updated. Step 2 integrates the `FETCH_HEAD` line that is marked for merging. If your branch is an ancestor of it, the branch is fast-forwarded. If it is an ancestor of your branch, there is nothing to do. If neither is true the branches have diverged, and `pull.rebase`, `pull.ff` or a flag must select the method.

**Inside `.git`.** Everything a fetch changes, then everything a merge or a rebase changes: the branch ref, the reflogs (entries begin with `pull`), `ORIG_HEAD`, the index and the working tree; with conflicts, the state described in [Chapter 8](ch08-merge.md) and [Chapter 9](ch09-rebase.md).

**See it.** First the case with no local commits:

<!-- snippet: ch12/pull-anatomy/01-fast-forward -->
```text
$ git pull
From ../../server/support-bot
   510ee94..ef22149  main       -> origin/main
Updating 510ee94..ef22149
Fast-forward
 app/retriever.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git reflog -1
ef22149 HEAD@{0}: pull: Fast-forward
$ git reflog show origin/main -1
ef22149 refs/remotes/origin/main@{0}: pull: fast-forward
```
<!-- /snippet -->

The output is two outputs glued together: the `From` block is the fetch, and `Updating ... Fast-forward` is the merge. Now both sides have a new commit:

<!-- snippet: ch12/pull-anatomy/02-diverged -->
```text
# Asha has pushed "Raise top_k to 8"; you have committed "Add dev requirements".
$ git status -sb
## main...origin/main [ahead 1]
$ git pull
From ../../server/support-bot
   ef22149..527a708  main       -> origin/main
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint:
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
[exit status: 128]
```
<!-- /snippet -->

`[ahead 1]` was the stale view. The fetch half worked (`ef22149..527a708  main -> origin/main`), then Git stopped with exit status 128.

<!-- snippet: ch12/pull-anatomy/03-after-fatal -->
```text
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git log --oneline --graph --decorate --all -4
* c498de8 (HEAD -> main) Add dev requirements
| * 527a708 (origin/main, origin/HEAD) Raise top_k to 8
|/  
* ef22149 Implement retrieval
* 510ee94 Add retrieval config
```
<!-- /snippet -->

A pull that ends in this error is not a no-op. Your remote-tracking ref moved, and status now tells the truth: `[ahead 1, behind 1]`. Your branch, index and working tree are untouched.

> **Root cause.** The fatal error is not a network failure and not damage. Git fetched successfully and then declined to pick one of two possible histories on your behalf.

The hint offers three answers. Each one as a flag:

<!-- snippet: ch12/pull-anatomy/04-ff-only -->
```text
$ git pull --ff-only
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
[exit status: 128]
```
<!-- /snippet -->

`--ff-only` (configuration: `pull.ff=only`) means "move my branch only when there is nothing to combine". On diverged branches it refuses, with a different message from the unconfigured case.

<!-- snippet: ch12/pull-anatomy/05-merge -->
```text
$ git pull --no-rebase
Merge made by the 'ort' strategy.
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --decorate -5
*   7044e06 (HEAD -> main) Merge branch 'main' of ../../server/support-bot
|\  
| * 527a708 (origin/main, origin/HEAD) Raise top_k to 8
* | c498de8 Add dev requirements
|/  
* ef22149 Implement retrieval
* 510ee94 Add retrieval config
$ git reflog -2
7044e06 HEAD@{0}: pull --no-rebase: Merge made by the 'ort' strategy.
c498de8 HEAD@{1}: commit: Add dev requirements
```
<!-- /snippet -->

`--no-rebase` (`pull.rebase=false`) creates a merge commit with two parents. Its message contains the URL because pull merges `FETCH_HEAD`, not `origin/main`.

<!-- snippet: ch12/pull-anatomy/06-back-to-diverged -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at c498de8 Add dev requirements
$ git status -sb
## main...origin/main [ahead 1, behind 1]
```
<!-- /snippet -->

The merge recorded the previous tip in `ORIG_HEAD`, so `git reset --hard ORIG_HEAD` takes back a pull you did not want. It is a 🔴 command: it also discards uncommitted changes ([Chapter 11](ch11-reset-revert-restore.md)).

<!-- snippet: ch12/pull-anatomy/07-rebase -->
```text
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git log --oneline --graph --decorate -4
* 45eec24 (HEAD -> main) Add dev requirements
* 527a708 (origin/main, origin/HEAD) Raise top_k to 8
* ef22149 Implement retrieval
* 510ee94 Add retrieval config
$ git reflog -4
45eec24 HEAD@{0}: pull --rebase (finish): returning to refs/heads/main
45eec24 HEAD@{1}: pull --rebase (pick): Add dev requirements
527a708 HEAD@{2}: pull --rebase (start): checkout 527a708c84be3e9847d2e65528c2d8cb7ce6b863
c498de8 HEAD@{3}: reset: moving to ORIG_HEAD
```
<!-- /snippet -->

`--rebase` (`pull.rebase=true`) re-creates your commit on top of the upstream: `c498de8` became `45eec24`. History stays linear, and the old commit remains reachable from the reflog.

**Picture.**

```text
  diverged, after the fetch half:          --no-rebase (merge):                --rebase:

        c498de8    main (HEAD)                   c498de8---7044e06  main       ef22149---527a708---45eec24  main
       /                                        /         /                              origin/main
  ef22149---527a708  origin/main           ef22149---527a708  origin/main      (45eec24 replaces c498de8)

  --ff-only: refuses, nothing moves
```

**Which setting wins.** The script in `labs/ch12/pull-matrix.sh` runs `git pull` from one diverged state under every combination of the two configuration keys, and then with each flag:

<!-- snippet: ch12/pull-matrix/02-config-only -->
```text
$ sh ../../try-pull.sh
pull.rebase=unset pull.ff=unset -> fatal: Need to specify how to reconcile divergent branches.
pull.rebase=unset pull.ff=only  -> fatal: Not possible to fast-forward, aborting.
pull.rebase=unset pull.ff=false -> merge commit
pull.rebase=unset pull.ff=true  -> merge commit
pull.rebase=false pull.ff=unset -> merge commit
pull.rebase=false pull.ff=only  -> fatal: Not possible to fast-forward, aborting.
pull.rebase=false pull.ff=false -> merge commit
pull.rebase=false pull.ff=true  -> merge commit
pull.rebase=true  pull.ff=unset -> rebase
pull.rebase=true  pull.ff=only  -> fatal: Not possible to fast-forward, aborting.
pull.rebase=true  pull.ff=false -> rebase
pull.rebase=true  pull.ff=true  -> rebase
```
<!-- /snippet -->

<!-- snippet: ch12/pull-matrix/03-flags -->
```text
$ sh ../../try-pull.sh --rebase | cut -d'>' -f2 | sort | uniq -c
  12  rebase
$ sh ../../try-pull.sh --no-rebase | cut -d'>' -f2 | sort | uniq -c
  12  merge commit
$ sh ../../try-pull.sh --ff-only | cut -d'>' -f2 | sort | uniq -c
  12  fatal: Not possible to fast-forward, aborting.
```
<!-- /snippet -->

Three rules, as observed on Git 2.55.0. With nothing set, a diverged pull is fatal. `pull.ff=only` in configuration beats `pull.rebase` in configuration: the row `pull.rebase=true pull.ff=only` refuses. A flag on the command line beats all configuration: each flag gave the same result in all twelve rows.

**State table** for `git pull`, by outcome:

| Outcome | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| fast-forward | updated | updated | unchanged | moved forward | as fetch, plus `ORIG_HEAD` | unchanged | unchanged |
| merge | merge result | merge result | unchanged | new merge commit | as fetch, plus `ORIG_HEAD` | unchanged | unchanged |
| rebase | result of replay | updated | detached during the replay, then the branch again | moved to the new commits | as fetch, plus `ORIG_HEAD` | unchanged | unchanged |
| fatal, or `--ff-only` refusal | unchanged | unchanged | unchanged | unchanged | as fetch | unchanged | unchanged |

**Choosing.** Rebase keeps history linear, but every replayed commit is a new commit that nobody has tested, local merge commits are flattened unless you use `--rebase=merges`, and it treats commits that used to be on the upstream in a way that can surprise you (section 12.8). Merge preserves exactly what you tested and adds one merge commit per pull. A global `pull.ff=only` is a defensible default: pull never creates a commit unless you pass `--rebase` or `--no-rebase` at that moment.

> **Version note.** Older behavior: an unconfigured `git pull` on diverged branches merged silently (before Git 2.27), then merged with a warning (2.27 to 2.33.0). Current behavior: it fetches, prints the hint and stops with `fatal: Need to specify how to reconcile divergent branches.` Since: Git 2.33.1 and 2.34.0 ([pull.c at 2.56](https://github.com/git/git/blob/v2.56.0/builtin/pull.c#L1150), [release notes 2.34](https://github.com/git/git/blob/master/Documentation/RelNotes/2.34.0.adoc)). Recommended: decide once, in configuration, and override with a flag when the situation differs.

**In production.** A deploy host or a CI job should never create commits. Its update step is `git pull --ff-only`, or `git fetch` followed by an explicit checkout of the fetched commit. A host that merges on pull will one day build a commit that exists nowhere else.

## 12.7 `git push`: asking another repository to move its refs

**In one sentence.** 🟡 `git push` asks a remote to make some of its refs point at commits of yours, sends the objects it lacks, and succeeds for each ref only if both your Git and the remote accept the update.

**Analogy.** Posting entries to a shared ledger: "I have seen everything up to entry N; here are my entries after it." Your own clerk checks the claim before you reach the counter, then the office applies its house rules. The analogy breaks because you can instruct your clerk to skip the check (force), and the office then refuses only if someone configured it to.

**Precisely.** A push runs in a fixed order:

```text
  your clone                                          server (git-receive-pack)
  1 read the server's refs                    <----   advertisement: refs/heads/main = 719650d
  2 client rules for each ref:
      fast-forward? tag exists? lease holds?
      no  -->  "! [rejected]"   (nothing is sent)
  3 send "<old> <new> <ref>" + packfile       ---->   4 objects go into a quarantine directory
                                                      5 ref still at <old>?  receive.deny* settings?
                                                        pre-receive and update hooks?
                                                        no  -->  "! [remote rejected]"
                                                      6 refs updated; post-receive hooks run
  7 move refs/remotes/origin/<branch>         <----   report: ok refs/heads/main
```

What is pushed when you name nothing was section 12.5. With arguments, each refspec is `[+]<source>:<destination>`: the source is any commit expression of yours, the destination a ref name on the remote. The client rules of step 2 are in the manual's "push rules": an existing branch may only be fast-forwarded, an existing tag may not be updated at all, and creations and deletions are allowed unless configuration or hooks forbid them ([git-push](https://git-scm.com/docs/git-push)).

**Inside `.git`.** In your repository, only the remote-tracking ref of each ref that was pushed, and its reflog. On the server: new objects and the updated refs.

**See it: one rule, two messages.** Asha has pushed. You have one local commit and a stale view:

<!-- snippet: ch12/push-rejections/01-fetch-first -->
```text
$ git status -sb
## main...origin/main [ahead 1]
$ git push
To ../../server/support-bot.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git status -sb
## main...origin/main [ahead 1]
```
<!-- /snippet -->

`(fetch first)`: the server's `main` names a commit that your repository does not contain, so your Git cannot even test ancestry. Status still shows the stale `[ahead 1]`, because a rejected push fetches nothing.

<!-- snippet: ch12/push-rejections/02-non-fast-forward -->
```text
$ git fetch
From ../../server/support-bot
   510ee94..719650d  main       -> origin/main
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git push
To ../../server/support-bot.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

After a fetch you have the server's commit, the ancestry test is possible, and it fails: `(non-fast-forward)`. The server's tip is not an ancestor of what you push, so accepting it would drop Asha's commit from `main`. One cause, two messages, and the only difference is whether you had fetched. Both lines say `! [rejected]`, not `! [remote rejected]`. Your own Git decided:

<!-- snippet: ch12/push-rejections/03-wire -->
```text
# The client side of the conversation during the rejected push:
$ GIT_TRACE_PACKET=1 git push 2>&1 | sed -n 's/.*packet: *\(push[<>]\)/\1/p' | fold -s -w 76
push< 719650da56c2910ce851d3c0f47ec270ebb88945 
refs/heads/main\0report-status report-status-v2 delete-refs side-band-64k 
quiet atomic ofs-delta object-format=sha1 agent=git/2.55.0-Darwin
push< 0000
push> 0000
```
<!-- /snippet -->

The server advertised its ref (`push<`). Your Git answered with an empty request (`push> 0000`) and closed the connection. The server was never asked.

<!-- snippet: ch12/push-rejections/04-integrate-and-push -->
```text
$ git rebase origin/main
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git push --dry-run
To ../../server/support-bot.git
   719650d..8bf53be  main -> main
$ git push
To ../../server/support-bot.git
   719650d..8bf53be  main -> main
$ git status -sb
## main...origin/main
$ git reflog show origin/main
8bf53be refs/remotes/origin/main@{0}: update by push
719650d refs/remotes/origin/main@{1}: fetch: fast-forward
```
<!-- /snippet -->

Integrate (a rebase here; a merge works as well), preview with `--dry-run`, push. The successful push moved `origin/main` immediately, recorded as `update by push`: your Git knows what the server has now, so no fetch is needed.

**Pushes that fail before any comparison.**

<!-- snippet: ch12/push-errors/01-src-refspec -->
```text
$ git branch
* hotfix/timeout
  main
$ git push origin master
error: src refspec master does not match any
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git push origin hotfix
error: src refspec hotfix does not match any
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/push-errors/02-unborn -->
```text
# A new repository with a remote but no commit yet:
$ git init -q ../../scratch
$ git -C ../../scratch remote add origin ../server/support-bot.git
$ git -C ../../scratch push -u origin main
error: src refspec main does not match any
error: failed to push some refs to '../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

`src refspec <name> does not match any` is about your side: the source name matched no ref of yours. Either the name is wrong (`master` where your branch is `main`, or half a branch name), or the repository has no commit yet, because an unborn branch is not a ref. This message is among the thirty highest-voted Git questions on [Stack Overflow](https://stackoverflow.com/questions/tagged/git?tab=Votes).

<!-- snippet: ch12/push-errors/03-detached -->
```text
$ git switch --detach
HEAD is now at c19ab53 Set request timeout
$ git push
fatal: You are not currently on a branch.
To push the history leading to the current (detached HEAD)
state now, use

    git push origin HEAD:<name-of-remote-branch>

[exit status: 128]
$ git push origin HEAD:refs/heads/hotfix/timeout
To ../../server/support-bot.git
 * [new branch]      HEAD -> hotfix/timeout
$ git switch -
Switched to branch 'hotfix/timeout'
```
<!-- /snippet -->

With a detached HEAD there is no current branch whose upstream could supply a destination, so you name both sides. The destination is written in full, `refs/heads/...`, because a detached `HEAD` is not a ref under `refs/heads/` from which Git could infer that you mean a branch.

<!-- snippet: ch12/push-errors/04-no-such-remote -->
```text
$ git push orign hotfix/timeout
fatal: 'orign' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
$ git remote
origin
```
<!-- /snippet -->

A misspelled remote name is taken for a path to a repository, hence the misleading text about access rights.

**Deleting, tags, several refs.**

<!-- snippet: ch12/push-refs/01-delete-branch -->
```text
$ git push origin --delete feature/eval-harness
To ../../server/support-bot.git
 - [deleted]         feature/eval-harness
$ git branch -vv
  feature/eval-harness edc57ed [origin/feature/eval-harness: gone] Add eval harness entry point
* main                 510ee94 [origin/main] Add retrieval config
  release/0.1          510ee94 [origin/release/0.1] Add retrieval config
$ git ls-remote --branches origin
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/main
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/release/0.1
```
<!-- /snippet -->

🔴 `git push <remote> --delete <branch>` (or a refspec with an empty source, `:feature/eval-harness`) removes the branch on the server and your remote-tracking ref. Your local branch stays, with its upstream marked `gone` (section 12.11). For this 🔴 command: it changes one ref on the server. It can destroy the only name that the branch's commits have there, and a bare server keeps no record of the deletion. Preview with `git log --oneline origin/<branch> --not origin/main`, which lists the commits that only that branch holds. Recover by pushing the tip again from any clone that has it: `git push origin <commit>:refs/heads/<branch>`. It is appropriate for branches that are merged, or abandoned by agreement.

<!-- snippet: ch12/push-refs/02-tags-are-not-pushed -->
```text
$ git tag -a v0.2.0 -m "Release 0.2.0"
$ git tag nightly
$ git push
Everything up-to-date
$ git ls-remote --tags origin
```
<!-- /snippet -->

<!-- snippet: ch12/push-refs/03-push-tags -->
```text
$ git push origin v0.2.0
To ../../server/support-bot.git
 * [new tag]         v0.2.0 -> v0.2.0
$ git tag -a v0.2.1 -m "Release 0.2.1"
$ git push --follow-tags
To ../../server/support-bot.git
   510ee94..7aec635  main -> main
 * [new tag]         v0.2.1 -> v0.2.1
$ git ls-remote --tags origin
e4cbd524cd2ce2e1757843ad5ee0c371484fd6f9	refs/tags/v0.2.0
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/tags/v0.2.0^{}
3b6d020723c18782f5703818be9f01f07146e2f7	refs/tags/v0.2.1
7aec635a45c70d81f8a60b04ce73a0dcfdbb15c8	refs/tags/v0.2.1^{}
```
<!-- /snippet -->

Tags travel only when asked. `git push origin <tag>` pushes one. `--follow-tags` adds annotated tags that point into the commits being pushed: `v0.2.1` went, the lightweight `nightly` did not. `--tags` pushes all of them.

<!-- snippet: ch12/push-refs/04-tag-update-rejected -->
```text
$ git tag -f -a v0.2.0 -m "Release 0.2.0, retagged"
Updated tag 'v0.2.0' (was e4cbd52)
$ git push origin v0.2.0
To ../../server/support-bot.git
 ! [rejected]        v0.2.0 -> v0.2.0 (already exists)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the tag already exists in the remote.
[exit status: 1]
```
<!-- /snippet -->

That is the tag rule: a tag that exists on the remote is not replaced without force.

<!-- snippet: ch12/push-refs/05-atomic -->
```text
# main is behind the server (Asha pushed); release/0.1 is one commit ahead.
$ git config set advice.pushUpdateRejected false
$ git push --atomic origin main release/0.1
error: atomic push failed for ref refs/heads/main. status: 5
To ../../server/support-bot.git
 ! [rejected]        main -> main (fetch first)
 ! [rejected]        release/0.1 -> release/0.1 (atomic push failed)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git ls-remote --branches origin
bb34561abaa5aa4fabf570a6dd8417f74b6abb81	refs/heads/main
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/release/0.1
```
<!-- /snippet -->

<!-- snippet: ch12/push-refs/06-not-atomic -->
```text
$ git push origin main release/0.1
To ../../server/support-bot.git
   510ee94..0c10e7b  release/0.1 -> release/0.1
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git ls-remote --branches origin
bb34561abaa5aa4fabf570a6dd8417f74b6abb81	refs/heads/main
0c10e7b5f43e3b449f31c690a82fee2a5af38d81	refs/heads/release/0.1
```
<!-- /snippet -->

Refs in one push are independent by default: `release/0.1` was updated although `main` was rejected, and the exit status is 1. With `--atomic` nothing was sent because one ref failed. A release script that pushes a branch and a tag needs `--atomic` and must check the exit status. (`advice.pushUpdateRejected=false` in the transcript only hides the hint block that the earlier rejections printed.)

**The server's own rules.**

<!-- snippet: ch12/server-rules/01-deny-non-fast-forwards -->
```text
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git -C ../../server/support-bot.git config set receive.denyNonFastForwards true
$ git push --force
remote: error: denying non-fast-forward refs/heads/main (you should pull first)        
To ../../server/support-bot.git
 ! [remote rejected] main -> main (non-fast-forward)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/server-rules/02-deny-deletes -->
```text
$ git push origin HEAD:refs/heads/tmp/scratch
To ../../server/support-bot.git
 * [new branch]      HEAD -> tmp/scratch
$ git -C ../../server/support-bot.git config set receive.denyDeletes true
$ git push origin --delete tmp/scratch
remote: error: denying ref deletion for refs/heads/tmp/scratch        
To ../../server/support-bot.git
 ! [remote rejected] tmp/scratch (deletion prohibited)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/server-rules/03-pre-receive -->
```text
$ git -C ../../server/support-bot.git config unset receive.denyNonFastForwards
$ cp ../../pre-receive ../../server/support-bot.git/hooks/pre-receive
$ chmod +x ../../server/support-bot.git/hooks/pre-receive
$ cat ../../server/support-bot.git/hooks/pre-receive
#!/bin/sh
# Refuse every direct update of main. Standard input has one line per ref:
#   <old-id> <new-id> <ref-name>
while read old new ref; do
  if [ "$ref" = "refs/heads/main" ]; then
    echo "policy: main only changes through a reviewed merge" >&2
    exit 1
  fi
done
exit 0
$ git push --force
remote: policy: main only changes through a reviewed merge        
To ../../server/support-bot.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

Now the lines read `! [remote rejected]`, and the `remote:` lines carry the server's own words. `--force` switches off your Git's checks, not the server's. Plain Git has `receive.denyNonFastForwards`, `receive.denyDeletes` and hooks: `pre-receive` reads one `old new ref` line per proposed update and can refuse the whole push, while the pushed objects wait in quarantine ([git-receive-pack](https://git-scm.com/docs/git-receive-pack)).

> **GitHub, not Git.** On GitHub the server-side rules are rulesets, branch protection and push protection. They answer in the same shape. GitHub's documentation gives `remote: error: GH006: Protected branch update failed for refs/heads/main.` as the reply of a branch protection rule ([About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)); [Chapter 18](ch18-branch-protection.md) covers them.

**State table** for a successful `git push`:

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged | unchanged | unchanged | unchanged | remote-tracking ref of each pushed ref and its reflog; upstream keys with `-u` | refs created, moved or deleted; new objects; hooks run | push events: pull request updates, workflow runs, rule evaluation |

**In production.** "It said rejected" is not a diagnosis. Read the word before the bracket closes. `rejected` means your clone must change: fetch and integrate. `remote rejected` means a policy on the server spoke: read the `remote:` lines and talk to whoever owns that policy. Retrying with `--force` answers neither.

## 12.8 Forcing a push

A forced push tells step 2 of the pipeline to skip the fast-forward test. The server's ref is set to your commit, and whatever it named before is no longer reachable from that ref.

🔴 **DANGEROUS: `git push --force`** (also `-f`, or a `+` before one refspec).

- **What it changes:** the ref on the server, and your remote-tracking ref.
- **What it can destroy:** every commit on the server's branch that is not in your history, including commits you have never seen. A default bare server has no reflog, so it keeps no pointer to them.
- **How to preview:** `git fetch`, then `git log --oneline HEAD..origin/<branch>` lists exactly the commits that would be dropped. `git push --dry-run --force` prints the server's current commit ID to the left of the three dots.
- **How to recover:** the old tip survives in any clone that had it (a teammate's branch, or the reflog of anybody's remote-tracking ref) and, until the server's garbage collection removes it, as an unreachable object on the server. Push it back.
- **When it is appropriate:** on a branch that only you use, such as your own pull request branch after a rebase, or in a coordinated history rewrite ([Chapter 21B](ch21b-repository-security-incident-response.md)). Then use a lease.

**See it: plain force destroys what you never saw.** You reworded a published commit on `docs/runbook`. Asha has since pushed a commit there, and you have not fetched:

<!-- snippet: ch12/lease-forms/03-plain-force -->
```text
# What your clone believes the server has, and what the server reports during a dry run:
$ git rev-parse --short origin/docs/runbook
17783a7
$ git push --dry-run --force origin docs/runbook
To ../../server/support-bot.git
 + 73f4877...ca3cabb docs/runbook -> docs/runbook (forced update)
$ git cat-file -t 73f4877
fatal: Not a valid object name 73f4877
[exit status: 128]
$ git push --force origin docs/runbook
To ../../server/support-bot.git
 + 73f4877...ca3cabb docs/runbook -> docs/runbook (forced update)
$ git reflog show origin/docs/runbook
ca3cabb refs/remotes/origin/docs/runbook@{0}: update by push
17783a7 refs/remotes/origin/docs/runbook@{1}: update by push
```
<!-- /snippet -->

Your clone believes the server is at `17783a7`. The dry run prints `73f4877...ca3cabb`: the server is at `73f4877`, an object your repository does not have. That is Asha's commit. The forced push replaces it, and the reflog of your remote-tracking ref goes from `17783a7` straight to `ca3cabb`. Your clone never held the commit it destroyed.

<!-- snippet: ch12/lease-forms/04-where-it-survives -->
```text
# The overwritten commit still exists: on the server, unreachable, and in the clone of Asha.
$ git -C ../../server/support-bot.git fsck --unreachable --no-reflogs | grep commit
unreachable commit 45de2936b350e2be1d34e97b160ee2af2d260b6d
unreachable commit 17783a7948f064198be834dfcce16644cba85192
unreachable commit 73f4877fe6ae70fc95aacb4cd751411a277c5f0e
$ git -C ../../asha/support-bot log --oneline -2 docs/runbook
73f4877 Add paging section
17783a7 Start the runbook
```
<!-- /snippet -->

<!-- snippet: ch12/lease-forms/05-fetch-by-id -->
```text
# Asking the server for the overwritten commit by its object ID:
$ git fetch origin 73f4877
fatal: couldn't find remote ref 73f4877
[exit status: 128]
$ git -c protocol.version=0 fetch origin 73f4877fe6ae70fc95aacb4cd751411a277c5f0e
error: Server does not allow request for unadvertised object 73f4877fe6ae70fc95aacb4cd751411a277c5f0e
[exit status: 1]
$ git fetch origin 73f4877fe6ae70fc95aacb4cd751411a277c5f0e
From ../../server/support-bot
 * branch            73f4877fe6ae70fc95aacb4cd751411a277c5f0e -> FETCH_HEAD
$ git log --oneline -2 FETCH_HEAD
73f4877 Add paging section
17783a7 Start the runbook
```
<!-- /snippet -->

The commit survives in Asha's clone and, unreachable, in the server's object database; the other two unreachable commits are your own earlier versions, replaced on purpose. Under protocol version 2, the default, a plain Git server hands out any object it has when asked by full ID; an abbreviation is not accepted, and under protocol version 0 the request is refused. This is a recovery route for as long as the object exists. It is also one reason why a forced push does not remove a leaked secret from a server.

**`--force-with-lease`: force only if the server is where I think it is.** The idea is the compare-and-swap of optimistic locking: "set the branch to my commit only if it still has the value I last read". The analogy breaks at "I": your Git does the reading, and a fetch that you never looked at refreshes the value.

You squash two published commits of `feature/prompt-cache` into one, after marking the old tip with a branch:

<!-- snippet: ch12/force-push/01-rewrite -->
```text
$ git log --oneline --decorate -3
12cdd3d (HEAD -> feature/prompt-cache, origin/feature/prompt-cache) wip: ttl
bdbe39f Add prompt cache
510ee94 (origin/main, origin/HEAD, main) Add retrieval config
$ git branch backup/prompt-cache
$ git reset --soft HEAD~2
$ git commit -q -m "Add prompt cache with TTL"
$ git log --oneline --graph --decorate --all -4
* 1a1fa49 (HEAD -> feature/prompt-cache) Add prompt cache with TTL
| * 12cdd3d (origin/feature/prompt-cache, backup/prompt-cache) wip: ttl
| * bdbe39f Add prompt cache
|/  
* 510ee94 (origin/main, origin/HEAD, main) Add retrieval config
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache [ahead 1, behind 2]
```
<!-- /snippet -->

Meanwhile Asha pushes a test commit on top of the old history. You try to publish:

<!-- snippet: ch12/force-push/02-lease-holds -->
```text
# Asha, in her clone: git push   (her test commit lands on top of "wip: ttl")
$ git push --force-with-lease
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> feature/prompt-cache (stale info)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git rev-parse --short origin/feature/prompt-cache
12cdd3d
$ git ls-remote origin feature/prompt-cache
833bc8ad64cffe287b9e4280a0c93cb6537d625b	refs/heads/feature/prompt-cache
```
<!-- /snippet -->

The bare form means "overwrite only if the server's branch still equals my remote-tracking ref". Your `origin/feature/prompt-cache` says `12cdd3d`, the server has `833bc8a`: `(stale info)`, decided by your Git from the advertisement. Asha's commit is safe. Now something fetches without your attention: an editor's auto-fetch, a scheduled job, or you in another terminal.

<!-- snippet: ch12/force-push/03-background-fetch -->
```text
# What an editor or a scheduled job does behind your back:
$ git fetch
From ../../server/support-bot
   12cdd3d..833bc8a  feature/prompt-cache -> origin/feature/prompt-cache
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache [ahead 1, behind 3]
```
<!-- /snippet -->

Your remote-tracking ref now equals the server. You have not looked at Asha's commit, but the lease cannot know that. Two stronger forms still refuse:

<!-- snippet: ch12/force-push/04-guards -->
```text
$ git push --force-with-lease --force-if-includes
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> feature/prompt-cache (remote ref updated since checkout)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout. If you want to integrate the
hint: remote changes, use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease=feature/prompt-cache:backup/prompt-cache
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> feature/prompt-cache (stale info)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

`--force-if-includes` adds a second condition: the tip of the remote-tracking ref must be reachable from some entry in the reflog of your local branch, meaning your branch contained that commit at some time. It did not: "remote ref updated since checkout". The explicit form `--force-with-lease=<ref>:<expect>` ignores the remote-tracking ref and compares the server with a commit you name, here the backup branch at the commit you rewrote. The bare form has no such defense:

<!-- snippet: ch12/force-push/05-lease-defeated -->
```text
$ git push --force-with-lease
To ../../server/support-bot.git
 + 833bc8a...1a1fa49 feature/prompt-cache -> feature/prompt-cache (forced update)
[exit status: 0]
$ git ls-remote origin feature/prompt-cache
1a1fa4964ca5cb5de17112e84ab62441aeac53fd	refs/heads/feature/prompt-cache
```
<!-- /snippet -->

```text
Observed behavior : git push --force-with-lease overwrote a teammate's commit that I had never looked at.
Git state         : refs/remotes/origin/feature/prompt-cache had been moved to the teammate's commit
                    by a fetch; my local branch did not contain that commit.
Mechanism         : the lease compares the server's ref with my remote-tracking ref. After the fetch
                    they were equal, so the condition "nothing changed since I looked" was true.
Root cause        : a remote-tracking ref records what my clone has fetched, not what I have seen or
                    integrated. Any fetch renews the lease.
Why Git does this : the remote-tracking ref is the only record Git has of "the state I based my work on",
                    and the manual says so and calls the forms without an explicit value experimental.
Correct fix       : restore the overwritten commit (below); nothing can be un-pushed.
Prevention        : --force-with-lease together with --force-if-includes (or push.useForceIfIncludes=true),
                    or the explicit --force-with-lease=<ref>:<commit>; and never rewrite a branch
                    that someone else pushes to without telling them.
```

<!-- snippet: ch12/force-push/06-what-is-left -->
```text
$ git reflog show origin/feature/prompt-cache
1a1fa49 refs/remotes/origin/feature/prompt-cache@{0}: update by push
833bc8a refs/remotes/origin/feature/prompt-cache@{1}: fetch: fast-forward
12cdd3d refs/remotes/origin/feature/prompt-cache@{2}: update by push
$ ls ../../server/support-bot.git/logs
ls: ../../server/support-bot.git/logs: No such file or directory
[exit status: 1]
$ git -C ../../server/support-bot.git fsck --unreachable --no-reflogs | grep commit
unreachable commit 833bc8ad64cffe287b9e4280a0c93cb6537d625b
unreachable commit 12cdd3d76a43de79f4cbd643a62ead3eb6d44dec
unreachable commit bdbe39fab454ec59484b2f16d05ff952de9cd6e6
```
<!-- /snippet -->

This time your clone does hold the overwritten commit: the fetch recorded it, and `origin/feature/prompt-cache@{1}` names it. The server has no `logs` directory at all, only unreachable objects.

**The other forms.** The next two transcripts come from the same demo as the plain forced push at the start of this section and were recorded before it, while `docs/runbook` on the server still held Asha's commit.

<!-- snippet: ch12/lease-forms/01-one-ref -->
```text
# Both branches were reworded locally. Asha has pushed to docs/runbook; you have not fetched.
$ git branch -vv
  docs/runbook         ca3cabb [origin/docs/runbook: ahead 1, behind 1] Start the on-call runbook
* feature/prompt-cache 886feab [origin/feature/prompt-cache: ahead 1, behind 1] Add prompt cache module
  main                 510ee94 [origin/main] Add retrieval config
$ git config set advice.pushUpdateRejected false
$ git push --force-with-lease=feature/prompt-cache origin feature/prompt-cache docs/runbook
To ../../server/support-bot.git
 + 45de293...886feab feature/prompt-cache -> feature/prompt-cache (forced update)
 ! [rejected]        docs/runbook -> docs/runbook (fetch first)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git ls-remote --branches origin
73f4877fe6ae70fc95aacb4cd751411a277c5f0e	refs/heads/docs/runbook
886feab6db3f48e44fe9bb9310d582ba8d094014	refs/heads/feature/prompt-cache
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/main
```
<!-- /snippet -->

`--force-with-lease=<ref>` leases and forces one ref. Every other ref in the same push follows the normal rules, so `docs/runbook` was rejected. The push was also not atomic: one ref was overwritten and one refused.

<!-- snippet: ch12/lease-forms/02-must-not-exist -->
```text
$ git push --force-with-lease=release/1.0: origin main:refs/heads/release/1.0
To ../../server/support-bot.git
 * [new branch]      main -> release/1.0
$ git push --force-with-lease=release/1.0: origin feature/prompt-cache:refs/heads/release/1.0
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> release/1.0 (stale info)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

An empty expected value means "the ref must not exist yet": a create-only push. Without the lease, the second command would have been a legal fast-forward of `release/1.0`.

| Form | The server's ref must equal | Defeated by a background fetch |
|---|---|---|
| `--force`, `-f`, `+<refspec>` | nothing is checked | not applicable |
| `--force-with-lease` | your remote-tracking ref, for every ref pushed | yes |
| `--force-with-lease=<ref>` | your remote-tracking ref, for that ref | yes |
| `--force-with-lease=<ref>:<expect>` | the commit you name; empty means "absent" | no |
| `--force-with-lease[=<ref>]` plus `--force-if-includes` | your remote-tracking ref, whose tip must also have been in your branch at some time | no |

**What the teammate sees.**

<!-- snippet: ch12/force-push/07-teammate-fetch -->
```text
$ cd ../../asha/support-bot
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache
$ git fetch
From ../../server/support-bot
 + 833bc8a...1a1fa49 feature/prompt-cache -> origin/feature/prompt-cache  (forced update)
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache [ahead 3, behind 1]
$ git log --oneline --graph --decorate --all -5
* 1a1fa49 (origin/feature/prompt-cache) Add prompt cache with TTL
| * 833bc8a (HEAD -> feature/prompt-cache) Add cache test
| * 12cdd3d wip: ttl
| * bdbe39f Add prompt cache
|/  
* 510ee94 (origin/main, origin/HEAD, main) Add retrieval config
```
<!-- /snippet -->

`+ 833bc8a...1a1fa49 ... (forced update)` in fetch output is the signal that a branch was rewritten under you. Asha is `[ahead 3, behind 1]`. The reflex is `git pull --rebase`:

<!-- snippet: ch12/force-push/08-pull-rebase-drops -->
```text
$ git reflog show origin/feature/prompt-cache
1a1fa49 refs/remotes/origin/feature/prompt-cache@{0}: fetch: forced-update
833bc8a refs/remotes/origin/feature/prompt-cache@{1}: update by push
$ git merge-base --fork-point origin/feature/prompt-cache
833bc8ad64cffe287b9e4280a0c93cb6537d625b
$ git pull --rebase
Successfully rebased and updated refs/heads/feature/prompt-cache.
$ git log --oneline --decorate -3
1a1fa49 (HEAD -> feature/prompt-cache, origin/feature/prompt-cache) Add prompt cache with TTL
510ee94 (origin/main, origin/HEAD, main) Add retrieval config
95671d3 Add retriever skeleton
```
<!-- /snippet -->

"Successfully rebased", no conflict, and her commit `Add cache test` is no longer on the branch.

```text
Observed behavior : after a teammate's forced push, git pull --rebase succeeded and my commit vanished
                    from the branch.
Git state         : I had pushed that commit earlier, so the reflog of origin/feature/prompt-cache
                    contains it ("update by push"). The server's branch was then replaced.
Mechanism         : pull --rebase replays only the commits after the fork point, and the fork point is
                    found through the reflog of the remote-tracking ref (git merge-base --fork-point).
                    It was my own pushed commit, so nothing was left to replay.
Root cause        : Git cannot tell "the upstream removed this commit on purpose" from "someone
                    overwrote it by accident". The reflog says only: it was upstream once, it is not now.
Why Git does this : without the rule, everyone downstream of a deliberately rebased branch would
                    re-apply the commits that the upstream had dropped.
Correct fix       : the commit is in my reflog; cherry-pick it onto the new tip and push.
Prevention        : after any "(forced update)" line, look before integrating:
                    git log --oneline --graph HEAD @{u}. Do not pull on a branch that others rewrite.
```

<!-- snippet: ch12/force-push/09-recover -->
```text
$ git reflog -4
1a1fa49 HEAD@{0}: pull --rebase (finish): returning to refs/heads/feature/prompt-cache
1a1fa49 HEAD@{1}: pull --rebase (start): checkout 1a1fa4964ca5cb5de17112e84ab62441aeac53fd
833bc8a HEAD@{2}: commit: Add cache test
12cdd3d HEAD@{3}: checkout: moving from main to feature/prompt-cache
$ git cherry-pick HEAD@{2}
[feature/prompt-cache 9074b47] Add cache test
 Date: Mon Sep 7 10:15:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 tests/test_cache.py
$ git push
To ../../server/support-bot.git
   1a1fa49..9074b47  feature/prompt-cache -> feature/prompt-cache
$ git log --oneline --decorate -3
9074b47 (HEAD -> feature/prompt-cache, origin/feature/prompt-cache) Add cache test
1a1fa49 Add prompt cache with TTL
510ee94 (origin/main, origin/HEAD, main) Add retrieval config
```
<!-- /snippet -->

**State table** for a forced push that succeeds:

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged | unchanged | unchanged | unchanged | remote-tracking ref moved; its reflog holds the old tip only if a fetch recorded it | ref moved to a non-descendant; old commits unreachable; no reflog on a default bare server | pull requests built on the old commits are disturbed; rules may refuse the push |

> **GitHub, not Git.** "Block force pushes" is enabled by default in a new ruleset, and classic branch protection rules disable force pushes by default ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#block-force-pushes)). GitHub offers no reflog that Git can query, but its Activity view lists force pushes and offers a comparison for each entry ([Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository)), and its troubleshooting page gives the plain-Git answer: ask a collaborator who still has the commit to push it to a new branch ([Troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone)). [Chapter 30](ch30-incident-response.md) drills this.

**In production.** A routine for rewriting a branch that is already published: fetch and read `git status -sb`; mark the old tip (`git branch backup/<name>`); rewrite; push with `--force-with-lease=<name>:backup/<name>`; tell everyone who has the branch what to do next. Set `push.useForceIfIncludes=true` once, for the days you forget the explicit form.

> **Outdated advice.** Tutorials that teach "`git reset --hard`, then `git push -f`" as a routine undo, even on `main`, teach the one habit in this chapter that loses other people's work. Undo published commits with `git revert` ([Chapter 11](ch11-reset-revert-restore.md)).

## 12.9 Pushing into a repository that has a working tree

A push moves refs. It checks nothing out. If the pushed ref is the branch that the receiving repository has checked out, that repository's `HEAD` would name a commit that its index and working tree do not match, and its next `git status` would present the pushed changes as local edits that undo them. Git refuses by default:

<!-- snippet: ch12/push-non-bare/01-refused -->
```text
$ git remote add staging ../../staging-box
$ git push staging main
remote: error: refusing to update checked out branch: refs/heads/main        
remote: error: By default, updating the current branch in a non-bare repository        
remote: is denied, because it will make the index and work tree inconsistent        
remote: with what you pushed, and will require 'git reset --hard' to match        
remote: the work tree to HEAD.        
remote: 
remote: You can set the 'receive.denyCurrentBranch' configuration variable        
remote: to 'ignore' or 'warn' in the remote repository to allow pushing into        
remote: its current branch; however, this is not recommended unless you        
remote: arranged to update its work tree to match what you pushed in some        
remote: other way.        
remote: 
remote: To squelch this message and still keep the default behaviour, set        
remote: 'receive.denyCurrentBranch' configuration variable to 'refuse'.        
To ../../staging-box
 ! [remote rejected] main -> main (branch is currently checked out)
error: failed to push some refs to '../../staging-box'
[exit status: 1]
```
<!-- /snippet -->

`receive.denyCurrentBranch` defaults to `refuse`. Any branch that is not checked out can be pushed to:

<!-- snippet: ch12/push-non-bare/02-other-branch -->
```text
$ git push staging main:refs/heads/incoming/timeout
To ../../staging-box
 * [new branch]      main -> incoming/timeout
$ git -C ../../staging-box branch -vv
  incoming/timeout c19ab53 Set request timeout
* main             510ee94 [origin/main] Add retrieval config
```
<!-- /snippet -->

For the legitimate case, a test or deployment machine that you reach over SSH, the receiving side can opt in to `updateInstead`, which updates the working tree as part of the push:

<!-- snippet: ch12/push-non-bare/03-update-instead -->
```text
$ git -C ../../staging-box config set receive.denyCurrentBranch updateInstead
$ git push staging main
To ../../staging-box
   510ee94..c19ab53  main -> main
$ git -C ../../staging-box log --oneline -1
c19ab53 Set request timeout
$ ls ../../staging-box/app
retriever.py
settings.py
```
<!-- /snippet -->

<!-- snippet: ch12/push-non-bare/04-dirty-target -->
```text
$ printf 'hotfix typed directly on the box\n' >> ../../staging-box/README.md
$ git push staging main
To ../../staging-box
 ! [remote rejected] main -> main (Working directory has unstaged changes)
error: failed to push some refs to '../../staging-box'
[exit status: 1]
```
<!-- /snippet -->

It works only while the target is clean. One uncommitted edit on the box makes every later push fail with `Working directory has unstaged changes`, which is the correct outcome: somebody hot-fixed on the machine, and the push tells you before it overwrites anything. The general rule stands: a repository that people push to is bare.

## 12.10 More than one remote

**In one sentence.** A repository can have any number of remotes, each with its own URL, refspecs and namespace of remote-tracking refs; nothing connects them except the objects they share.

**See it: a fork, in plain Git.** By convention `origin` is the repository you push to and `upstream` is the shared repository you take changes from:

<!-- snippet: ch12/fork-triangular/01-fork-and-clone -->
```text
# The Fork button, in plain Git: a server-side clone.
$ git clone --bare server/support-bot.git forks/you/support-bot.git
Cloning into bare repository 'forks/you/support-bot.git'...
done.
$ git clone forks/you/support-bot.git you/support-bot
Cloning into 'you/support-bot'...
done.
$ cd you/support-bot
$ git remote add upstream ../../server/support-bot.git
$ git fetch upstream
From ../../server/support-bot
 * [new branch]      main       -> upstream/main
$ git remote -v
origin	../../forks/you/support-bot.git (fetch)
origin	../../forks/you/support-bot.git (push)
upstream	../../server/support-bot.git (fetch)
upstream	../../server/support-bot.git (push)
```
<!-- /snippet -->

<!-- snippet: ch12/fork-triangular/02-refs -->
```text
$ git show-ref --abbrev
510ee94 refs/heads/main
510ee94 refs/remotes/origin/HEAD
510ee94 refs/remotes/origin/main
510ee94 refs/remotes/upstream/HEAD
510ee94 refs/remotes/upstream/main
```
<!-- /snippet -->

Two namespaces, `origin/*` and `upstream/*`, each with its own `HEAD`, all naming the same commit, which is stored once.

> **GitHub, not Git.** Git has no notion of a fork. The Fork button creates a GitHub object: a server-side copy that stays connected to its parent and shares Git data with it in a repository network ([Forks](https://docs.github.com/en/pull-requests/reference/forks)). To Git it is one more repository with a URL. `gh repo fork --clone` names your fork `origin` and the parent `upstream`, the convention used here.

**A triangular workflow** fetches from one repository and pushes to another:

<!-- snippet: ch12/fork-triangular/03-triangular-config -->
```text
$ git config set remote.pushDefault origin
$ git config set push.default current
$ git switch -c feature/streaming upstream/main
Switched to a new branch 'feature/streaming'
branch 'feature/streaming' set up to track 'upstream/main'.
# One commit made here: "Add streaming responses".
$ git push
To ../../forks/you/support-bot.git
 * [new branch]      feature/streaming -> feature/streaming
$ git rev-parse --abbrev-ref @{upstream} @{push}
upstream/main
origin/feature/streaming
$ git config get --all --show-names --regexp "^(remote\.pushdefault|push\.default|branch\.feature)"
remote.pushdefault origin
push.default current
branch.feature/streaming.remote upstream
branch.feature/streaming.merge refs/heads/main
```
<!-- /snippet -->

`remote.pushDefault=origin` sends every bare `git push` to your fork, whatever the upstream of the branch is. The branch tracks `upstream/main`, so `git pull` takes changes from the shared repository. `@{upstream}` and `@{push}` are now two different refs.

```text
        upstream = server/support-bot.git        shared; you fetch from it
              |
              |  git fetch upstream, git pull --rebase         (@{upstream} = upstream/main)
              v
        you/support-bot     feature/streaming
              |
              |  git push                                      (@{push} = origin/feature/streaming)
              v
        origin = forks/you/support-bot.git       yours; a pull request offers this branch to upstream
```

Which remote a bare push uses is decided by three settings in a fixed order, and the branch name by `push.default`:

<!-- snippet: ch12/push-destination/01-push-default-remote -->
```text
$ git branch -vv
* feature/streaming 08b274c [upstream/main: ahead 1] Add streaming responses
  main              510ee94 [origin/main] Add retrieval config
$ git config set remote.pushDefault origin
$ git push --dry-run
To ../../forks/you/support-bot.git
 * [new branch]      feature/streaming -> feature/streaming
$ git rev-parse --abbrev-ref @{push}
fatal: cannot resolve 'simple' push to a single destination
[exit status: 128]
```
<!-- /snippet -->

With only `remote.pushDefault` set, the push goes to the fork under the branch's own name, but Git 2.55 cannot answer `@{push}` under `push.default=simple`.

<!-- snippet: ch12/push-destination/02-current -->
```text
$ git config set push.default current
$ git push
To ../../forks/you/support-bot.git
 * [new branch]      feature/streaming -> feature/streaming
$ git rev-parse --abbrev-ref @{upstream} @{push}
upstream/main
origin/feature/streaming
$ git for-each-ref --format='%(refname:short): pull from %(upstream:short), push to %(push:short)' refs/heads
feature/streaming: pull from upstream/main, push to origin/feature/streaming
main: pull from origin/main, push to origin/main
```
<!-- /snippet -->

`push.default=current` makes the destination a plain function of the branch name. The `for-each-ref` line is the one to remember in an incident: for every branch, where it pulls from and where it pushes to.

<!-- snippet: ch12/push-destination/03-per-branch -->
```text
$ git config set branch.feature/streaming.pushRemote upstream
$ git push --dry-run
To ../../server/support-bot.git
 * [new branch]      feature/streaming -> feature/streaming
$ git config unset branch.feature/streaming.pushRemote
$ git push --dry-run
Everything up-to-date
```
<!-- /snippet -->

The order is `branch.<name>.pushRemote`, then `remote.pushDefault`, then `branch.<name>.remote`, then `origin`.

<!-- snippet: ch12/fork-triangular/04-two-comparisons -->
```text
$ git config set status.compareBranches "@{upstream} @{push}"
$ git fetch upstream
From ../../server/support-bot
   510ee94..f11a751  main       -> upstream/main
$ git status
On branch feature/streaming
Your branch and 'upstream/main' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

Your branch is up to date with 'origin/feature/streaming'.

nothing to commit, working tree clean
```
<!-- /snippet -->

`status.compareBranches` (Git 2.54 or later) makes `git status` report both relationships.

<!-- snippet: ch12/fork-triangular/05-rebase-and-republish -->
```text
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/streaming.
$ git status -sb
## feature/streaming...upstream/main [ahead 1]
$ git push
To ../../forks/you/support-bot.git
 ! [rejected]        feature/streaming -> feature/streaming (non-fast-forward)
error: failed to push some refs to '../../forks/you/support-bot.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease
To ../../forks/you/support-bot.git
 + 5d5414c...4ce24f2 feature/streaming -> feature/streaming (forced update)
```
<!-- /snippet -->

After a rebase onto the moved upstream, the branch in your fork still holds the old commit, so the push is not a fast-forward. This is the legitimate forced push: a branch that only you push to, with a lease.

<!-- snippet: ch12/fork-triangular/06-sync-fork-main -->
```text
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git merge --ff-only upstream/main
Updating 510ee94..f11a751
Fast-forward
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
To ../../forks/you/support-bot.git
   510ee94..f11a751  main -> main
$ git log --oneline --graph --decorate --all -4
* 4ce24f2 (origin/feature/streaming, feature/streaming) Add streaming responses
* f11a751 (HEAD -> main, upstream/main, upstream/HEAD, origin/main, origin/HEAD) Raise top_k to 8
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
```
<!-- /snippet -->

Bringing the fork's `main` up to date is a fast-forward from `upstream/main` and a push to `origin`. GitHub documents the same steps for the command line, next to its "Sync fork" button and `gh repo sync` ([Syncing a fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork)).

**Fetch URL, push URL and other URL tools.**

<!-- snippet: ch12/remote-urls/01-push-url -->
```text
$ git remote add upstream ../../server/support-bot.git
$ git remote set-url --push upstream DISABLED
$ git remote -v
origin	../../server/support-bot.git (fetch)
origin	../../server/support-bot.git (push)
upstream	../../server/support-bot.git (fetch)
upstream	DISABLED (push)
$ git config get --all --show-names --regexp "^remote\.upstream\."
remote.upstream.url ../../server/support-bot.git
remote.upstream.fetch +refs/heads/*:refs/remotes/upstream/*
remote.upstream.pushurl DISABLED
$ git push upstream main
fatal: 'DISABLED' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

`git remote set-url --push` gives a remote a separate push URL. Here it is deliberately not a repository, a cheap guard that makes pushing to `upstream` impossible from this clone. The manual warns that a real fetch URL and push URL of one remote must lead to the same repository; for two different places, use two remotes ([git-remote](https://git-scm.com/docs/git-remote)).

<!-- snippet: ch12/remote-urls/02-two-push-urls -->
```text
$ git remote set-url --add --push origin ../../server/support-bot.git
$ git remote set-url --add --push origin ../../backup/support-bot.git
$ git remote -v
origin	../../server/support-bot.git (fetch)
origin	../../server/support-bot.git (push)
origin	../../backup/support-bot.git (push)
upstream	../../server/support-bot.git (fetch)
upstream	DISABLED (push)
$ git push origin main
To ../../server/support-bot.git
   510ee94..c19ab53  main -> main
To ../../backup/support-bot.git
   510ee94..c19ab53  main -> main
```
<!-- /snippet -->

Several push URLs make one push update several repositories, one after the other and not atomically.

<!-- snippet: ch12/remote-urls/03-instead-of -->
```text
$ git config set url.../../server/.insteadOf https://git.example.com/acme/
$ git remote add company https://git.example.com/acme/support-bot.git
$ git config get remote.company.url
https://git.example.com/acme/support-bot.git
$ git remote get-url company
../../server/support-bot.git
$ git ls-remote company main
c19ab53ef3dba868f5f8b8c60d19a9687069f366	refs/heads/main
```
<!-- /snippet -->

`url.<base>.insteadOf` rewrites URLs when they are used. The configuration keeps the URL that was written; `git remote get-url` shows what will be contacted. Teams use it in the global configuration to move a whole host from HTTPS to SSH, or to an internal mirror, without editing any clone.

<!-- snippet: ch12/remote-urls/04-remote-group -->
```text
$ git remote add backup ../../backup/support-bot.git
$ git config set remotes.offsite "company backup"
$ git fetch offsite
Fetching company
From ../../server/support-bot
 * [new branch]      main       -> company/main
Fetching backup
From ../../backup/support-bot
 * [new branch]      main       -> backup/main
$ git push --dry-run offsite main
Pushing to company
Everything up-to-date
Pushing to backup
Everything up-to-date
```
<!-- /snippet -->

`remotes.<group>` names a list of remotes. `git fetch <group>` has long accepted one; `git push <group>` does since Git 2.55.

<!-- snippet: ch12/remote-urls/05-rename -->
```text
$ git branch -u company/main
branch 'main' set up to track 'company/main'.
$ git remote rename company canonical
$ git branch -r
  backup/HEAD -> backup/main
  backup/main
  canonical/HEAD -> canonical/main
  canonical/main
  origin/HEAD -> origin/main
  origin/main
$ git config get --all --show-names --regexp "^(remote\.canonical|branch\.main)\."
branch.main.remote canonical
branch.main.merge refs/heads/main
remote.canonical.url https://git.example.com/acme/support-bot.git
remote.canonical.fetch +refs/heads/*:refs/remotes/canonical/*
```
<!-- /snippet -->

<!-- snippet: ch12/remote-urls/06-remove -->
```text
$ git remote remove canonical
$ git branch -r
  backup/HEAD -> backup/main
  backup/main
  origin/HEAD -> origin/main
  origin/main
$ git branch -vv
* main c19ab53 Set request timeout
$ git remote remove canonical
error: No such remote: 'canonical'
[exit status: 2]
```
<!-- /snippet -->

🟡 `git remote rename` moves the remote-tracking refs and rewrites the configuration, including the upstream of `main`. 🟡 `git remote remove` deletes the remote-tracking refs with their reflogs and removes upstream settings that pointed at the remote: `main` is left with none.

**In production.** You contribute a fix to an open-source evaluation library: fork, clone, add `upstream`, branch from `upstream/main`, push to `origin`, open the pull request. Inside a company the same triangle appears when a team keeps a patched copy of a vendor repository. In both cases write down which remote is which before the first push.

## 12.11 Pruning and branches whose upstream is gone

**In one sentence.** A fetch creates and moves remote-tracking refs but by default never deletes one, so branches deleted on the server live on in your clone until you prune.

**See it.** This transcript runs in Asha's clone. Since she last fetched, `feature/reranker` was merged and deleted on the server, and the team replaced the branch `release` by `release/1.0`:

<!-- snippet: ch12/prune-gone/01-stale -->
```text
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/eval-harness
  origin/feature/reranker
  origin/main
  origin/release
$ git ls-remote --branches origin
edc57ed67d3ef2451ee0ad599a1769c54adc92c5	refs/heads/feature/eval-harness
52d3c1ada36809341bc3fac2af09a619cf85ec00	refs/heads/main
52d3c1ada36809341bc3fac2af09a619cf85ec00	refs/heads/release/1.0
```
<!-- /snippet -->

<!-- snippet: ch12/prune-gone/02-remote-show -->
```text
$ git remote show origin
* remote origin
  Fetch URL: ../../server/support-bot.git
  Push  URL: ../../server/support-bot.git
  HEAD branch: main
  Remote branches:
    feature/eval-harness                 tracked
    main                                 tracked
    refs/remotes/origin/feature/reranker stale (use 'git remote prune' to remove)
    refs/remotes/origin/release          stale (use 'git remote prune' to remove)
    release/1.0                          new (next fetch will store in remotes/origin)
  Local branches configured for 'git pull':
    feature/eval-harness merges with remote feature/eval-harness
    feature/reranker     merges with remote feature/reranker
    main                 merges with remote main
  Local refs configured for 'git push':
    feature/eval-harness pushes to feature/eval-harness (up to date)
    main                 pushes to main                 (local out of date)
```
<!-- /snippet -->

`git branch -r` reads the stale local view and `git ls-remote` the server. `git remote show origin` contacts the server and classifies every branch as tracked, stale or new; it also lists what each local branch pulls from and pushes to.

<!-- snippet: ch12/prune-gone/03-fetch-blocked -->
```text
$ git fetch
error: some local refs could not be updated; try running
 'git remote prune origin' to remove any old, conflicting branches
From ../../server/support-bot
   510ee94..52d3c1a  main        -> origin/main
 ! [new branch]      release/1.0 -> origin/release/1.0  (unable to update local ref)
[exit status: 1]
```
<!-- /snippet -->

A stale ref can block a fetch. `origin/release` still exists, so `origin/release/1.0` cannot be created: one ref name cannot be a directory-like prefix of another, in any ref storage format.

<!-- snippet: ch12/prune-gone/04-prune -->
```text
$ git remote prune --dry-run origin
Pruning origin
URL: ../../server/support-bot.git
 * [would prune] origin/feature/reranker
 * [would prune] origin/release
$ git fetch --prune
From ../../server/support-bot
 - [deleted]         (none)      -> origin/feature/reranker
 - [deleted]         (none)      -> origin/release
 * [new branch]      release/1.0 -> origin/release/1.0
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/eval-harness
  origin/main
  origin/release/1.0
```
<!-- /snippet -->

`git remote prune --dry-run` previews. 🟡 `git fetch --prune` deletes remote-tracking refs that no longer exist on the server and then fetches.

<!-- snippet: ch12/prune-gone/05-gone -->
```text
$ git branch -vv
  feature/eval-harness edc57ed [origin/feature/eval-harness] Add eval harness entry point
  feature/reranker     5176652 [origin/feature/reranker: gone] Add reranker stub
* main                 510ee94 [origin/main: behind 2] Add retrieval config
$ git for-each-ref --format="%(refname:short) %(upstream:track)" refs/heads
feature/eval-harness 
feature/reranker [gone]
main [behind 2]
```
<!-- /snippet -->

Pruning never touches local branches. Their upstream is now reported as `gone`, and `%(upstream:track)` gives the same fact to scripts. A branch in that state hides a trap:

<!-- snippet: ch12/prune-gone/06-zombie -->
```text
$ git switch feature/reranker
Switched to branch 'feature/reranker'
Your branch is based on 'origin/feature/reranker', but the upstream is gone.
  (use "git branch --unset-upstream" to fixup)
$ git pull
Your configuration specifies to merge with the ref 'refs/heads/feature/reranker'
from the remote, but no such ref was fetched.
[exit status: 1]
$ git push
To ../../server/support-bot.git
 * [new branch]      feature/reranker -> feature/reranker
$ git ls-remote --branches origin
edc57ed67d3ef2451ee0ad599a1769c54adc92c5	refs/heads/feature/eval-harness
5176652525c1216c70b16c80ecb9625c8f350595	refs/heads/feature/reranker
52d3c1ada36809341bc3fac2af09a619cf85ec00	refs/heads/main
52d3c1ada36809341bc3fac2af09a619cf85ec00	refs/heads/release/1.0
```
<!-- /snippet -->

`git pull` fails with a clear message. `git push` succeeds and re-creates the branch on the server: a branch that the team merged and deleted is back, with old commits, and somebody will build on it.

<!-- snippet: ch12/prune-gone/07-cleanup -->
```text
$ git push origin --delete feature/reranker
To ../../server/support-bot.git
 - [deleted]         feature/reranker
$ git switch main
Switched to branch 'main'
Your branch is behind 'origin/main' by 2 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)
$ git pull --ff-only
Updating 510ee94..52d3c1a
Fast-forward
 app/reranker.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 app/reranker.py
$ git branch -d feature/reranker
Deleted branch feature/reranker (was 5176652).
```
<!-- /snippet -->

Delete it on the server again, bring `main` up to date, and delete the local branch with `-d`, which refuses if the commits are not merged.

<!-- snippet: ch12/prune-gone/08-fetch-prune-config -->
```text
$ git config set fetch.prune true
# You have deleted feature/eval-harness on the server in the meantime.
$ git fetch
From ../../server/support-bot
 - [deleted]         (none)     -> origin/feature/eval-harness
$ git branch -vv
  feature/eval-harness edc57ed [origin/feature/eval-harness: gone] Add eval harness entry point
* main                 52d3c1a [origin/main] Merge branch feature/reranker
```
<!-- /snippet -->

With `fetch.prune=true` every fetch prunes. Set globally, it keeps clones free of the stale `origin/*` refs that deleted feature branches leave behind. Section 12.16 shows the price.

**State table** for `git remote prune <remote>`; `git fetch --prune` adds the effects of a fetch:

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged | unchanged | unchanged | unchanged | stale remote-tracking refs and their reflogs deleted; upstream settings of local branches kept | unchanged | unchanged |

## 12.12 Refspecs in depth

**In one sentence.** A refspec, `[+]<source>:<destination>`, is the only thing that decides which refs a fetch or a push touches: the source is on the sending side, the destination on the receiving side.

**Analogy.** A mail-forwarding rule: "whatever is addressed to `refs/heads/X` over there, file it here as `refs/remotes/origin/X`". It breaks because the rule runs only at the moment of a fetch or a push; nothing is forwarded in between.

| Refspec | Where | Meaning |
|---|---|---|
| `+refs/heads/*:refs/remotes/origin/*` | fetch, configured | every branch to a remote-tracking ref, forced |
| `+refs/heads/main:refs/remotes/origin/main` | fetch, configured | one branch only |
| `^refs/heads/dependabot/*` | fetch or push | negative: exclude what matches (Git 2.29 or later) |
| `+refs/pull/*/head:refs/remotes/origin/pr/*` | fetch, configured | map another namespace |
| `pull/7/head:pr-7` | fetch, command line | one ref into a local branch |
| `main` | push | `refs/heads/main:refs/heads/main` |
| `HEAD~1:main` | push | any commit of yours to a branch of theirs |
| `HEAD:refs/heads/review/x` | push | create a branch under another name |
| `:review/x` | push | delete |
| `+main` | push | force this ref only |

**See it.** A clone made with `--single-branch`, as a CI job makes it:

<!-- snippet: ch12/refspec-surgery/01-narrow-clone -->
```text
$ git clone --single-branch server/support-bot.git you/support-bot
Cloning into 'you/support-bot'...
done.
$ cd you/support-bot
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git switch release/0.1
fatal: invalid reference: release/0.1
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch12/refspec-surgery/02-widen -->
```text
$ git remote set-branches --add origin release/0.1
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
+refs/heads/release/0.1:refs/remotes/origin/release/0.1
$ git fetch
From ../../server/support-bot
 * [new branch]      release/0.1 -> origin/release/0.1
$ git remote set-branches origin "*"
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
$ git fetch
From ../../server/support-bot
 * [new branch]      dependabot/pip/requests-2.33 -> origin/dependabot/pip/requests-2.33
```
<!-- /snippet -->

`git remote set-branches --add` appends a refspec for one more branch, and `set-branches origin "*"` restores the wildcard. Each `git fetch` then brings exactly what the configured refspecs cover.

<!-- snippet: ch12/refspec-surgery/03-plus -->
```text
# Asha has rewritten the tip of release/0.1 on the server. Your refspec, without its +:
$ git config set remote.origin.fetch "refs/heads/*:refs/remotes/origin/*"
$ git fetch
From ../../server/support-bot
 ! [rejected] release/0.1 -> origin/release/0.1  (non-fast-forward)
[exit status: 1]
$ git config set remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
$ git fetch
From ../../server/support-bot
 + d5379f1...6c2ddc6 release/0.1 -> origin/release/0.1  (forced update)
```
<!-- /snippet -->

The meaning of `+`. Asha rewrote the tip of `release/0.1`. Without the plus sign, your fetch refuses the non-fast-forward update and your picture of the server stays wrong. With it, the remote-tracking ref is forced. The default refspec carries the `+` on purpose: a remote-tracking ref has to record the server as it is, rewritten or not. (The `git fetch` manual of 2.55 says updates outside `refs/heads/` and `refs/tags/` are accepted without `+`. This transcript shows that Git 2.55.0 rejects a non-fast-forward update of `refs/remotes/origin/release/0.1` without it.)

<!-- snippet: ch12/refspec-surgery/04-negative -->
```text
$ git config set --append remote.origin.fetch "^refs/heads/dependabot/*"
$ git branch -r -d origin/dependabot/pip/requests-2.33
Deleted remote-tracking branch origin/dependabot/pip/requests-2.33 (was 510ee94).
$ git fetch
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
  origin/release/0.1
```
<!-- /snippet -->

A negative refspec excludes matching refs from later fetches. It does not delete a ref you already have, hence the `git branch -r -d`.

<!-- snippet: ch12/refspec-surgery/05-pull-request-refs -->
```text
$ git ls-remote origin "refs/pull/*"
a3b0283892821a8f9fc95bda5760237390817915	refs/pull/7/head
$ git fetch origin pull/7/head:pr-7
From ../../server/support-bot
 * [new ref]         refs/pull/7/head -> pr-7
$ git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"
$ git fetch
From ../../server/support-bot
 * [new ref]         refs/pull/7/head -> origin/pr/7
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
^refs/heads/dependabot/*
+refs/pull/*/head:refs/remotes/origin/pr/*
```
<!-- /snippet -->

Refs outside `refs/heads/` are invisible to the default refspec. Name one on the command line to fetch it into a local branch, or map the namespace permanently.

> **GitHub, not Git.** `refs/pull/<number>/head` is how GitHub exposes the head commit of every pull request. Its documentation gives `git fetch origin pull/ID/head:BRANCH_NAME` and states that the namespace is read-only: a push to it is answered with `! [remote rejected] ... (deny updating a hidden ref)` ([Checking out pull requests locally](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/checking-out-pull-requests-locally)). `gh pr checkout <number>` wraps the fetch.

<!-- snippet: ch12/refspec-surgery/06-push-refspecs -->
```text
# Two commits made on main: "Start the runbook", then "Add on-call notes".
$ git push origin HEAD~1:main
To ../../server/support-bot.git
   510ee94..73bb3c8  HEAD~1 -> main
$ git push origin HEAD:refs/heads/review/oncall-notes
To ../../server/support-bot.git
 * [new branch]      HEAD -> review/oncall-notes
$ git push origin :review/oncall-notes
To ../../server/support-bot.git
 - [deleted]         review/oncall-notes
$ git status -sb
## main...origin/main [ahead 1]
```
<!-- /snippet -->

Three push refspecs: publish everything except your newest commit, create a branch under a different name, and delete it. Status then shows the one commit that stayed local.

**In production.** A fetch refspec is configuration that silently shapes what a clone can see. Lab 7.7 ends with a mirror-style refspec, `+refs/heads/*:refs/heads/*`, pasted into an ordinary clone: the next fetch overwrites local branches. When a clone "cannot see" a branch or "keeps losing" one, print `git config get --all remote.origin.fetch` first.

## 12.13 Transports in brief

The URL selects how the two Gits reach each other. What they say to each other is the same.

<!-- snippet: ch12/transports/01-url-forms -->
```text
# One scheme per URL, in the order given:
$ git url-parse -c scheme https://github.com/acme/support-bot.git git@github.com:acme/support-bot.git ssh://git@github.com/acme/support-bot.git file:///srv/git/support-bot.git
https
ssh
ssh
file
$ git url-parse -c host git@github.com:acme/support-bot.git
github.com
$ git url-parse -c path git@github.com:acme/support-bot.git
/acme/support-bot.git
$ git url-parse -c scheme ../../server/support-bot.git
fatal: '../../server/support-bot.git' is not a URL; if you meant a local repository, use a 'file://' URL with an absolute path
[exit status: 128]
```
<!-- /snippet -->

`git url-parse` (Git 2.55 or later) shows how Git reads a URL. The form `git@github.com:acme/support-bot.git` is SSH. A plain path is not a URL at all: it names a local repository.

| Transport | URL form | Authentication | Notes |
|---|---|---|---|
| local | `/path/repo.git`, `../repo.git` | filesystem permissions | `git clone` hard-links or copies object files |
| file | `file:///path/repo.git` | filesystem permissions | always the pack protocol |
| SSH | `ssh://git@host/path`, `git@host:path` | SSH keys | runs Git's server programs on the host |
| HTTPS | `https://host/path` | credentials supplied by a credential helper | the same conversation carried in HTTP requests |
| git | `git://host/path` | none | anyone who can reach the port can read |
| bundle | a file | none | offline; fetch and clone only |

<!-- snippet: ch12/transport-trace/03-programs -->
```text
# Which program does Git start for the other side of the conversation?
$ GIT_TRACE=1 git fetch 2>&1 | sed -n 's/.*trace: run_command: //p' | head -1
unset GIT_PREFIX; GIT_PROTOCOL=version=2 'git-upload-pack '\''../../server/support-bot.git'\'''
$ GIT_TRACE=1 git push 2>&1 | sed -n 's/.*trace: run_command: //p' | head -1
unset GIT_PREFIX; 'git-receive-pack '\''../../server/support-bot.git'\'''
```
<!-- /snippet -->

The other side of a fetch is `git-upload-pack`; the other side of a push is `git-receive-pack`. Over SSH the same two programs are started on the server.

<!-- snippet: ch12/transport-trace/01-fetch -->
```text
$ GIT_TRACE_PACKET=1 git fetch 2>&1 | sed -n 's/.*packet: *\(fetch[<>]\)/\1/p'
fetch< version 2
fetch< agent=git/2.55.0-Darwin
fetch< ls-refs=unborn
fetch< fetch=shallow wait-for-done
fetch< server-option
fetch< object-format=sha1
fetch< 0000
fetch> command=ls-refs
fetch> agent=git/2.55.0-Darwin
fetch> object-format=sha1
fetch> 0001
fetch> peel
fetch> symrefs
fetch> unborn
fetch> ref-prefix refs/heads/
fetch> ref-prefix refs/heads/main
fetch> ref-prefix refs/tags/
fetch> ref-prefix HEAD
fetch> 0000
fetch< 719650da56c2910ce851d3c0f47ec270ebb88945 HEAD symref-target:refs/heads/main
fetch< 719650da56c2910ce851d3c0f47ec270ebb88945 refs/heads/main
fetch< 0000
fetch> command=fetch
fetch> agent=git/2.55.0-Darwin
fetch> object-format=sha1
fetch> 0001
fetch> thin-pack
fetch> no-progress
fetch> include-tag
fetch> ofs-delta
fetch> want 719650da56c2910ce851d3c0f47ec270ebb88945
fetch> have 510ee948fb6354959cf03862f0ebe47c58eb2a74
fetch> have 95671d3baba80df6b53e79e6583c1a6e01fdf451
fetch> have f56c1bb279a37dc704979733d4314bd9c1e2893d
fetch> 0000
fetch< acknowledgments
fetch< ACK 510ee948fb6354959cf03862f0ebe47c58eb2a74
fetch< ready
fetch< 0001
fetch< packfile
```
<!-- /snippet -->

`GIT_TRACE_PACKET=1` prints the conversation; `fetch<` is received, `fetch>` is sent. The server announces protocol version 2 and its capabilities. The client asks for refs with `ls-refs`, limited by `ref-prefix` lines derived from your refspecs, so a server with very many refs lists only those you can use. Then `want` names what you need and `have` what you already hold, and the server answers with a packfile of the difference.

<!-- snippet: ch12/transport-trace/02-push -->
```text
# One local commit, already rebased onto the fetched origin/main:
$ GIT_TRACE_PACKET=1 git push 2>&1 | sed -n 's/.*packet: *\(push[<>]\)/\1/p' | cut -c1-110
push< 719650da56c2910ce851d3c0f47ec270ebb88945 refs/heads/main\0report-status report-status-v2 delete-refs sid
push< 0000
push> 719650da56c2910ce851d3c0f47ec270ebb88945 b109fc2446651be551de03e7834e6db8804e1cd1 refs/heads/main\0 repo
push> 0000
push< unpack ok
push< ok refs/heads/main
push< 0000
```
<!-- /snippet -->

A push is shorter: the advertisement, one `<old> <new> <ref>` command, the pack, and the report `unpack ok`, `ok refs/heads/main`. These traces are the first tool when a transfer hangs or is refused without explanation ([Chapter 29](ch29-production-troubleshooting.md)).

<!-- snippet: ch12/transports/02-bundle-create -->
```text
$ git bundle create ../../support-bot.bundle HEAD --branches
$ git bundle verify ../../support-bot.bundle
../../support-bot.bundle is okay
The bundle contains these 3 refs:
510ee948fb6354959cf03862f0ebe47c58eb2a74 HEAD
e553023017ca8545817a0931e13090569b6fe0c4 refs/heads/feature/eval-harness
510ee948fb6354959cf03862f0ebe47c58eb2a74 refs/heads/main
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
```
<!-- /snippet -->

<!-- snippet: ch12/transports/03-bundle-clone -->
```text
$ cd ../..
$ git clone support-bot.bundle airgap/support-bot
Cloning into 'airgap/support-bot'...
$ git -C airgap/support-bot branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/feature/eval-harness
  remotes/origin/main
$ git -C airgap/support-bot remote -v
origin	$LAB/ch12/transports/support-bot.bundle (fetch)
origin	$LAB/ch12/transports/support-bot.bundle (push)
```
<!-- /snippet -->

A bundle is a file that plays the part of a remote. It serves networks with no route between the two sides, such as an air-gapped training cluster: carry the file across, then clone or fetch from it. You cannot push to it.

> **GitHub, not Git.** GitHub accepts HTTPS and SSH URLs ([About remote repositories](https://docs.github.com/en/get-started/git-basics/about-remote-repositories)). It stopped accepting account passwords for Git over HTTPS on 13 August 2021 ([GitHub Blog](https://github.blog/security/application-security/token-authentication-requirements-for-git-operations/)) and removed the unauthenticated `git://` protocol on 15 March 2022 ([GitHub Blog](https://github.blog/security/application-security/improving-git-protocol-security-github/)). [Chapter 16](ch16-authentication.md) covers authentication.

## 12.14 Two diagnoses from first principles

**"The commit exists locally but not on the server."**

<!-- snippet: ch12/diagnose/01-the-push-that-pushed-nothing -->
```text
$ git log --oneline -1
c19ab53 Set request timeout
$ git push origin main
Everything up-to-date
```
<!-- /snippet -->

`Everything up-to-date` is a true statement about the refspec that was pushed. Three questions locate the commit:

<!-- snippet: ch12/diagnose/02-where-is-the-commit -->
```text
$ git branch -a --contains HEAD
* hotfix/timeout
$ git status -sb
## hotfix/timeout
$ git log --oneline --branches --not --remotes
c19ab53 Set request timeout
```
<!-- /snippet -->

Which branches contain it: one local branch and no remote-tracking branch. Does that branch have an upstream: `## hotfix/timeout` with nothing after it means no. Which commits has no remote-tracking ref ever seen: `git log --branches --not --remotes` lists it.

<!-- snippet: ch12/diagnose/03-ask-the-server -->
```text
$ git rev-parse HEAD
c19ab53ef3dba868f5f8b8c60d19a9687069f366
$ git ls-remote origin
510ee948fb6354959cf03862f0ebe47c58eb2a74	HEAD
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/main
```
<!-- /snippet -->

And the server, asked directly, has no ref at that ID.

```text
Observed behavior : git push printed "Everything up-to-date"; the deploy job cannot find the commit.
Git state         : HEAD is on hotfix/timeout, which has no upstream. The commit is on that branch only.
                    main equals origin/main.
Mechanism         : "git push origin main" is a refspec: send my main to their main. There was nothing
                    to send.
Root cause        : the command named a branch that does not hold the commit. A push transfers the
                    refs you name, not "my work".
Why Git does this : an explicit refspec is obeyed literally; Git has no idea which commit you care about.
Correct fix       : git push -u origin hotfix/timeout, then merge it by the team's process.
Prevention        : read the last lines of push output (<source> -> <destination>); verify with
                    git branch -a --contains <commit>; let deploy scripts verify with git ls-remote.
```

<!-- snippet: ch12/diagnose/04-fix -->
```text
$ git push -u origin hotfix/timeout
To ../../server/support-bot.git
 * [new branch]      hotfix/timeout -> hotfix/timeout
branch 'hotfix/timeout' set up to track 'origin/hotfix/timeout'.
$ git branch -a --contains HEAD
* hotfix/timeout
  remotes/origin/hotfix/timeout
$ git log --oneline --branches --not --remotes
```
<!-- /snippet -->

The same three questions sort out the other causes of this symptom: a rejected push whose exit status a script ignored, a push to the wrong remote (your fork instead of the shared repository), a commit made on a detached HEAD, or a reader who looked at a stale remote-tracking ref instead of the server.

**"My remote-tracking refs cannot be trusted."**

<!-- snippet: ch12/diagnose/05-ambiguous-name -->
```text
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git branch origin/main HEAD~1
$ git rev-parse --short origin/main
warning: refname 'origin/main' is ambiguous.
95671d3
$ git branch -a
  hotfix/timeout
* main
  origin/main
  remotes/origin/HEAD -> remotes/origin/main
  remotes/origin/hotfix/timeout
  remotes/origin/main
$ git branch -D origin/main
Deleted branch origin/main (was 95671d3).
```
<!-- /snippet -->

A local branch named `origin/main`, usually created by a mistyped command. Git warns that the name is ambiguous and then resolves it to the local branch, because `refs/heads/` comes before `refs/remotes/` in the lookup order. Every comparison "against `origin/main`" now uses the wrong commit. In `git branch -a` the impostor is the entry without the `remotes/` prefix.

<!-- snippet: ch12/diagnose/06-rebuild-remote-tracking -->
```text
$ git remote set-head origin --delete
$ git for-each-ref --format='delete %(refname)' refs/remotes/origin | git update-ref --stdin
$ git branch -r
$ git status -sb
## main...origin/main [gone]
$ git fetch
From ../../server/support-bot
 * [new branch]      main           -> origin/main
 * [new branch]      hotfix/timeout -> origin/hotfix/timeout
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

When the remote-tracking refs themselves are in doubt (a tool wrote to them, a URL was switched to a different repository), remember what they are: a cache. Delete them all (🟡) and fetch. Local branches and their upstream settings are not touched; status says `[gone]` in between and is correct again afterwards. The price is the reflogs of the deleted refs, your only record of earlier server states.

## 12.15 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| `! [rejected] ... (fetch first)` or `(non-fast-forward)` | someone pushed before you; `git fetch`, then `git status -sb` shows `behind` | integrate (`git rebase @{u}` or `git merge @{u}`), push again | fetch before you start; short-lived branches |
| `! [remote rejected] ... (pre-receive hook declined)`, or a platform rule | the `remote:` lines state the policy | follow the policy, usually a pull request; do not force | know which branches are protected |
| `fatal: Need to specify how to reconcile divergent branches.` | `git status -sb` shows `ahead` and `behind` | `git pull --rebase` or `--no-rebase`; or look first with `git log --oneline --graph HEAD @{u}` | set `pull.rebase` or `pull.ff` on purpose |
| `fatal: Not possible to fast-forward, aborting.` | `pull.ff=only` is set, perhaps in another scope: `git config list --show-origin --show-scope` | pass `--rebase` or `--no-rebase` for this pull | know your global configuration |
| `Everything up-to-date`, but the commit is not on the server | `git branch -a --contains <commit>`; `git ls-remote origin` | push the branch that holds the commit | read `<source> -> <destination>` in push output |
| `error: src refspec <name> does not match any` | `git branch`: no such branch, or no commit yet | use the real branch name; commit first | do not copy `master` or `main` from a tutorial without checking |
| `fatal: The current branch <name> has no upstream branch.` | `git branch -vv` shows no brackets | `git push -u origin <name>` | `push.autoSetupRemote=true` |
| "Up to date" locally while teammates see newer commits | the last fetch is old: `git reflog show --date=iso origin/main -1` prints when that ref last moved | `git fetch` | fetch before decisions; scripts use `git ls-remote` |
| A commit vanished after `git pull --rebase` | the fetch printed `(forced update)`; `git reflog` still lists the commit | `git cherry-pick <commit>`, push | after a forced update, look before integrating |
| `error: some local refs could not be updated` | a stale remote-tracking ref blocks a new name | `git fetch --prune` | `fetch.prune=true` |
| A deleted branch is back on the server | pushed from a clone whose branch showed `gone` | delete it again; delete the local branch | prune, then remove `gone` branches |
| `warning: refname 'origin/main' is ambiguous.` | `git branch -a` lists a local `origin/main` | `git branch -D origin/main` after checking what it holds | never create local branches named `<remote>/...` |
| A tag is a different commit on two machines | `git rev-parse <tag>` against `git ls-remote --tags origin <tag>` | after confirming the server is right, `git fetch --tags --force` | never move a published tag |
| `git switch <branch>`: `invalid reference`, though the server has the branch | `git config get --all remote.origin.fetch` shows a narrow refspec | `git remote set-branches --add origin <branch>`, fetch | know how the clone was made |

## 12.16 When not to use it, and dangerous edge cases

**Pruning is forgetting.** A remote-tracking ref may be the last name that some commits have in your clone:

<!-- snippet: ch12/prune-forgets/01-last-name -->
```text
# Asha has deleted spike/hybrid-search on the server. Your clone has not fetched since.
$ git branch -a --contains origin/spike/hybrid-search
  remotes/origin/spike/hybrid-search
$ git log --oneline -2 origin/spike/hybrid-search
509f067 Return the query as a stub result
249e18e Try hybrid search
$ git fetch --prune
From ../../server/support-bot
 - [deleted]         (none)     -> origin/spike/hybrid-search
$ git reflog show origin/spike/hybrid-search 2>&1 | head -1
fatal: ambiguous argument 'origin/spike/hybrid-search': unknown revision or path not in the working tree.
$ git fsck --unreachable | grep commit
unreachable commit 509f0670ffe15a66ea88e923674de467cf3a58ff
unreachable commit 249e18e16ceb304d7eea2d0b42a167965316b737
```
<!-- /snippet -->

Asha deleted the spike branch on the server. Before the prune your clone still named its two commits. Afterwards the ref is gone, its reflog is gone with it, and the commits are unreachable. They stay in the object database until garbage collection removes them ([Chapter 13](ch13-recovery.md)), and until then `git fsck` can find them:

<!-- snippet: ch12/prune-forgets/02-rescue -->
```text
$ git fsck --lost-found | grep commit
dangling commit 509f0670ffe15a66ea88e923674de467cf3a58ff
$ git branch rescue/hybrid-search 509f067
$ git log --oneline -2 rescue/hybrid-search
509f067 Return the query as a stub result
249e18e Try hybrid search
```
<!-- /snippet -->

With `fetch.prune=true` this happens on every fetch, without a preview. That is acceptable for merged feature branches and costly on the day someone deletes the wrong branch and every clone forgets it at its next fetch. If your clones are the team's only safety net, prune deliberately.

Other cases where the technique is the wrong one:

- **`git pull` in automation, and on branches that other people rewrite.** A job that pulls can create merge commits nobody reviewed. A pull with rebase after someone's forced push can drop commits (section 12.8). Fetch, compare, then act.
- **A forced push to a branch that anyone else pushes to.** The lease forms reduce the risk; they do not make the rewrite harmless for people who already have the old commits.
- **`git push --mirror` and `git push --prune`.** Both delete refs on the server that your repository lacks. From an ordinary clone, `--mirror` would also publish your remote-tracking refs. They are migration tools for a `--mirror` clone, 🔴 everywhere else.
- **A refspec that writes into `refs/heads/*` or `refs/tags/*` combined with pruning.** The `git fetch` manual warns that `--prune` with a tag refspec, which is what `--prune-tags` adds, deletes local tags that the remote lacks, including tags you made yourself.
- **A `--bare` clone as a backup.** It does not follow its source (section 12.3). A `--mirror` clone follows, and reproduces deletions too.
- **A token inside the URL.** `https://<token>@host/...` in `remote.origin.url` stores the secret in plain text in `.git/config`, and `git remote -v` prints it wherever it runs, CI logs included. Use a credential helper ([Chapter 16](ch16-authentication.md)).
- **A forced push as a way to remove a leaked secret.** The commit stays in clones, in the server's object database, and can be fetched by ID where the server allows it (section 12.8). Rotate the secret first ([Chapter 21B](ch21b-repository-security-incident-response.md)).

## 12.17 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git remote -v`, `git remote show`, `git ls-remote`, `git branch -vv` | 🟢 SAFE | nothing (`remote show` and `ls-remote` contact the server) | not needed | not needed |
| `git clone` | 🟢 SAFE | creates a new directory | not needed | delete the directory |
| `git fetch`, `git remote update` | 🟢 SAFE | remote-tracking refs, followed tags, `FETCH_HEAD`, objects | `git ls-remote`; `git fetch --dry-run` | `origin/<branch>@{1}` in the reflog |
| `git fetch --prune`, `git remote prune` | 🟡 CAUTION | deletes stale remote-tracking refs and their reflogs | `git remote prune --dry-run <remote>` | `git fsck --lost-found`, then `git branch <name> <id>`, before garbage collection |
| `git fetch --tags --force` | 🟡 CAUTION | replaces local tags | `git ls-remote --tags` | note `git rev-parse <tag>` first, re-create from that ID |
| `git remote add` | 🟢 SAFE | adds configuration | not needed | `git remote remove` |
| `git remote set-url`, `set-head`, `set-branches`, `rename`; `git branch -u`; `git config set push.default` | 🟡 CAUTION | where later fetches, pulls and pushes go | `git remote -v`; `git config list --local` | set the previous value |
| `git remote remove` | 🟡 CAUTION | the remote, its remote-tracking refs and reflogs, upstream settings | `git branch -r`, `git branch -vv` | add and fetch again; the reflogs are lost |
| `git pull --ff-only` | 🟡 CAUTION | fetch, then moves the branch forward; working tree | `git fetch`; `git log ..@{u}` | `git reset --hard ORIG_HEAD` (itself 🔴) |
| `git pull --no-rebase`, `git pull --rebase` | 🟡 CAUTION | fetch, then a merge commit or re-created local commits | `git fetch`; `git log --oneline --graph HEAD @{u}` | `git reset --hard ORIG_HEAD`; the reflog |
| `git push`, `git push -u`, `git push --follow-tags` | 🟡 CAUTION | refs on the server (fast-forward or new), your remote-tracking refs | `git push --dry-run`; `git log @{u}..` | published commits are not taken back; `git revert` and push |
| `git push <remote> --delete <ref>`, `git push <remote> :<ref>` | 🔴 DANGEROUS | deletes a ref on the server | `git ls-remote <remote>` | from any clone that has the commit: `git push <remote> <id>:refs/heads/<name>` |
| `git push --force`, `git push <remote> +<ref>` | 🔴 DANGEROUS | sets the server's ref with no check | `git fetch`; `git log HEAD..@{u}` lists what would be lost | section 12.8: a clone that has the old tip, or the server's unreachable object |
| `git push --force-with-lease[=<ref>[:<expect>]]`, with or without `--force-if-includes` | 🔴 DANGEROUS | the same, only if the server's ref has the expected value | the same | the same |
| `git push --mirror`, `git push --prune` | 🔴 DANGEROUS | creates, forces and deletes server refs to match yours | `--dry-run` | from other clones, ref by ref |

## 12.18 Version notes

Two version notes are placed where they are needed: `origin/HEAD` and `git fetch` in section 12.3, and the fatal error of `git pull` in section 12.6.

> **Version note.** Older behavior: `push.default=matching`, so a bare `git push` pushed every branch with a same-named branch on the server. Current behavior: `simple`. Since: Git 2.0 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.0.0.adoc)); `push.autoSetupRemote` since 2.37 ([push configuration at 2.37](https://github.com/git/git/blob/v2.37.0/Documentation/config/push.txt)). Recommended: keep `simple`; set `push.autoSetupRemote=true`.

> **Version note.** Older behavior: `git push --force` was the only way to overwrite. Current behavior: `--force-with-lease` (since Git 1.8.5) and `--force-if-includes` (since 2.30); the manual still calls every lease form without an explicit expected value experimental ([git-push at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/git-push.adoc), [release notes 2.30](https://github.com/git/git/blob/master/Documentation/RelNotes/2.30.0.adoc)). Recommended: `--force-with-lease --force-if-includes`, or the explicit form.

> **Version note.** Older behavior: a fetch that included tags, such as `git fetch --tags`, replaced a tag you already had when the server's tag differed. Current behavior: it rejects the update unless forced. Since: Git 2.20 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.20.0.adoc)). Recommended: treat every "would clobber existing tag" as a question to the person who moved the tag.

> **Version note.** Older behavior: `git ls-remote --heads` and `git show-ref --heads`. Current behavior: `--branches`; `--heads` remains as a deprecated synonym. Since: Git 2.46 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc)), the release that also introduced `git config get` and `git config set`. Recommended: write `--branches`, read `--heads`.

> **Version note.** Older behavior: the original wire protocol, in which the server lists every ref first. Current behavior: protocol version 2. Since: default in Git 2.26 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.26.0.adoc)). Recommended: nothing to configure; know that `protocol.version` exists when you read an old trace.

Dated additions used in this chapter: `remote.pushDefault`, `branch.<name>.pushRemote` and `--follow-tags` (Git 1.8.3), the update of `origin/<branch>` by `git fetch origin <branch>` (1.8.4), `fetch.prune` (1.8.5), `git push --atomic` (2.4), `@{push}` (2.5), negative refspecs (2.29), `status.compareBranches` (2.54), and `git push` to a remote group and `git url-parse` (2.55), each according to the release notes of that version. Also since 2.55, terminal control sequences in the `remote:` lines that a server sends are masked, except colors (`sideband.allowControlCharacters`). The legacy remote definitions in `$GIT_DIR/remotes` and `$GIT_DIR/branches` are scheduled for removal in Git 3.0 ([BreakingChanges](https://github.com/git/git/blob/v2.56.0/Documentation/BreakingChanges.adoc)).

> **Unverified.** Whether a hosting platform serves unreachable commits to `git fetch <remote> <full-id>` depends on its server configuration; it was verified here only for a plain Git 2.55.0 server. The release in which `git branch -vv` began to print `gone` was not looked up.

## 12.19 Practice

- Labs 7.1 to 7.7 in the [Module 7 lab manual](../lab-manual/m07-remotes.md). Do 7.1 first; it builds the server and both clones by hand. Answers to the lab questions are in [the solutions](../solutions/m07-lab-answers.md).
- Replay any transcript with `labs/run ch12/<demo>`, for example `labs/run ch12/force-push`. The sandbox stays in place, so you can continue by hand.
- Five drills in those sandboxes. Predict, then run.
  1. `ch12/fetch-anatomy`: what will `.git/FETCH_HEAD` contain after `git fetch origin feature/reranker`, and which refs will move?
  2. `ch12/pull-matrix`: add `branch.main.rebase=false` to the row `pull.rebase=true`. Which key wins?
  3. `ch12/push-destination`: with `push.default=upstream`, what does `git push --dry-run` do on `feature/streaming`?
  4. `ch12/force-push`: name every repository that still holds `833bc8a` at the end, and how it is reachable there.
  5. `ch12/refspec-surgery`: write the configuration that fetches only `main` and `release/*`.

## 12.20 Interview questions

1. What exactly is `origin/main`? Where is it stored, and which commands move it?
2. `git status` says "Your branch is up to date with 'origin/main'". What did Git compare, and what do you run before tagging a release?
3. Take `git clone` apart into separate commands. What does `--mirror` add to `--bare`, and why does the difference matter for a backup?
4. A pull stopped with "Need to specify how to reconcile divergent branches". What changed in the repository and what did not? Give the three answers and their effect on history.
5. Two engineers in the same situation got `rejected (fetch first)` and `rejected (non-fast-forward)`. Explain the difference and who made each decision. How is `remote rejected` different?
6. Explain `--force-with-lease`, one way it fails to protect a teammate's commit, and the two stronger forms.
7. After a colleague's forced push, a developer ran `git pull --rebase`. It succeeded and their commit was gone. Explain the mechanism and recover the commit.
8. A forced push overwrote a commit on a self-hosted bare repository. List every place where the commit may still exist and how you would bring it back.
9. What do `branch.<name>.remote`, `branch.<name>.merge`, `remote.pushDefault` and `push.default` each decide? Configure a clone that pulls from `upstream` and pushes to `origin`.
10. A branch that was deleted a month ago is back on the server, and nobody intended it. How did it happen, and what do you change?
11. Why does Git refuse a push into a checked-out branch, and what would you configure on a staging machine?
12. The deploy job cannot find a commit, and the developer's push printed "Everything up-to-date". Give your first four commands and what each one proves.

## 12.21 Sources

**Primary sources**

- [git-clone](https://git-scm.com/docs/git-clone), [git-fetch](https://git-scm.com/docs/git-fetch), [git-pull](https://git-scm.com/docs/git-pull), [git-push](https://git-scm.com/docs/git-push), [git-remote](https://git-scm.com/docs/git-remote), [git-ls-remote](https://git-scm.com/docs/git-ls-remote), [git-branch](https://git-scm.com/docs/git-branch), [git-merge-base](https://git-scm.com/docs/git-merge-base) (fork point), [git-receive-pack](https://git-scm.com/docs/git-receive-pack), [git-bundle](https://git-scm.com/docs/git-bundle), [git-url-parse](https://git-scm.com/docs/git-url-parse), [gitrevisions](https://git-scm.com/docs/gitrevisions), [gitglossary](https://git-scm.com/docs/gitglossary), [gitdatamodel](https://git-scm.com/docs/gitdatamodel). The local copies (`git help -m <command>`) are the Git 2.55.0 text that every flag in this chapter was checked against.
- [gitprotocol-v2](https://git-scm.com/docs/gitprotocol-v2) and [gitprotocol-pack](https://git-scm.com/docs/gitprotocol-pack): the fetch and push conversations of section 12.13, including "wants can be anything".
- Configuration reference at 2.56: [push](https://github.com/git/git/blob/v2.56.0/Documentation/config/push.adoc), [pull](https://github.com/git/git/blob/v2.56.0/Documentation/config/pull.adoc), [fetch](https://github.com/git/git/blob/v2.56.0/Documentation/config/fetch.adoc), [core](https://github.com/git/git/blob/v2.56.0/Documentation/config/core.adoc).
- Release notes: [1.8.3](https://github.com/git/git/blob/master/Documentation/RelNotes/1.8.3.adoc), [1.8.4](https://github.com/git/git/blob/master/Documentation/RelNotes/1.8.4.adoc), [1.8.5](https://github.com/git/git/blob/master/Documentation/RelNotes/1.8.5.adoc), [2.0.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.0.0.adoc), [2.4.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.4.0.adoc), [2.5.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.5.0.adoc), [2.20.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.20.0.adoc), [2.26.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.26.0.adoc), [2.29.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.29.0.adoc), [2.34.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.34.0.adoc), [2.48.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.48.0.adoc), [2.54.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc), [2.55.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc). Homebrew installs the same files under `share/doc/git-doc/RelNotes/`.

**Secondary sources**

- Pro Git: [Working with Remotes](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes), [Remote Branches](https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches), [The Refspec](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec), [Transfer Protocols](https://git-scm.com/book/en/v2/Git-Internals-Transfer-Protocols). Caveats: `master` and `git checkout` throughout; the first still says that `git pull` only warns when `pull.rebase` is unset, which was true from 2.27 to 2.33.0; the last does not mention protocol version 2.
- GitHub Docs: [About remote repositories](https://docs.github.com/en/get-started/git-basics/about-remote-repositories), [Forks](https://docs.github.com/en/pull-requests/reference/forks), [Syncing a fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork), [Checking out pull requests locally](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/checking-out-pull-requests-locally), [Renaming a branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/renaming-a-branch), [Troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone).
- Julia Evans, [Confusing git terminology](https://jvns.ca/blog/2023/11/01/confusing-git-terminology/), cited by the Phase 0 report for what "Your branch is up to date with 'origin/main'" does and does not say.
- The Phase 0 report of this course, sections 1, 4, 12 and 13, for the dated defaults, the misconception table and the force-push safety facts.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- [Introduction to Git - Remotes](https://www.youtube.com/watch?v=Gg4bLk8cGNo), David Mahler, 31 minutes, 27 March 2018: clone, fetch versus pull and tracking branches drawn on the commit graph. Caveat: `master` throughout.
- [Git and GitHub - Full Course](https://www.youtube.com/watch?v=rH3zE7VlIMs), ThePrimeagen for Boot.dev, 12 November 2024: the chapter on remotes and GitHub starts at 1:54:18, followed by forks. Caveat: digressive style.
- [Complete Git and GitHub Tutorial](https://www.youtube.com/watch?v=apGV9Kg7ics), Kunal Kushwaha, 1 August 2021: fork, upstream remote, keeping a fork in sync. Caveats from the report: recorded days before password removal, uses a plain force push, mixes `master` and `main`, and could not be transcript-audited.

**Further reading**

- [gitprotocol-http](https://git-scm.com/docs/gitprotocol-http), for what "smart HTTP" does with the conversation of section 12.13.
- [git-maintenance](https://github.com/git/git/blob/v2.56.0/Documentation/git-maintenance.adoc), task `prefetch`: Git's own scheduled fetch writes to `refs/prefetch/` so that it does not move remote-tracking branches, and therefore does not renew a lease.
- Chapter 13 (Recovery) for reflogs and `git fsck`, Chapter 26 (Performance) for shallow and partial clones and bundle URIs, and Chapter 30 (Incident response) for the force-push drill.
