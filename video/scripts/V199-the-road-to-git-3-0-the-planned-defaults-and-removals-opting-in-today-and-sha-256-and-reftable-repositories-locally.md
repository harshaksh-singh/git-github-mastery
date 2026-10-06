# V199: The road to Git 3.0, the planned defaults and removals, opting in today, and SHA-256 and reftable repositories locally

- **Part.** 11, Expert: the frontier
- **Module.** 42
- **Planned minutes.** 24
- **Prerequisites.** V107, V198
- **Textbook sections.** [Chapter 14D](../../textbook/ch14d-frontier.md), sections 14D.1 to 14D.5
- **Demo scripts.** `labs/ch14d/git3-optin.sh` (snippets `01-build` to `06-removals`), `labs/ch14d/safe-bare.sh` (snippets `01-explicit` to `04-refused`), `labs/ch14d/lab-42-1-sha256-reftable.sh` (snippets `01-today` to `04-migrate`)

## HOOK

**[ON SCREEN]** "I read that Git 3.0 changes the hash and the default branch. What breaks for us, and when?"

A CTO can ask that in the next twelve months, after reading a headline. There are two tempting answers. "Nothing, it is years away." And: "Everything, we need a migration project." Both are guesses.

The honest answer has three parts, and each comes from a different kind of source. What is planned is written in a document that ships with your own Git installation. When it happens has one official sentence, one primary announcement and a set of secondary reports that you must label as such. And what breaks for your team is something you can find out this afternoon, in a sandbox, by switching the future defaults on. Hold on to the CTO's question. Before the end you'll hear it answered in three paragraphs, each with its source.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is Part 11, the last part of the course. Its three videos look ahead. Features that need Git 2.56 are named as such and not run. The lab has Git 2.55.0.

The skill this part trains isn't knowing the answers. They will be out of date. It's finding them in primary sources within a few minutes: the BreakingChanges document, the release notes, the manual page of your installed version, and a sandbox.

From video 107 you know the two new formats: SHA-256 as an object format and reftable as a ref backend. The object format is the hash function that gives every object its ID. The ref backend is how names such as branches and tags are stored on disk. Today you see what the next major version plans to do with them, which keys choose the planned behavior ahead of time, and what a team has to know before it lets any of this near a shared repository.

Every statement about dates in this video carries its source. Listen for the labels: official, primary through a mirror, secondary, unverified.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. State what Git 3.0 plans to change, for which repositories, and what is officially said about its date.
2. Name the configuration keys that choose the planned defaults ahead of time and say where you would set them.
3. Create a repository with the planned formats today and convert the ref format of an existing one.
4. Say what `safe.bareRepository=explicit` refuses and allows.
5. Say what would have to be true before a hosted team repository can use SHA-256.

## CONCEPT

**What is official.** The Git project keeps a document named BreakingChanges, shipped with every installation. It says that breaking releases happen rarely: 1.6.0 in August 2008, 2.0 in May 2014. It lists what Git 3.0 will change. And it states: "There is no planned release date for this breaking version yet." That sentence is in the copy installed with Git 2.55.0 and, according to the course's research report, unchanged at 2.56.0.

The same document makes two promises. The last version before 3.0 will be a long-term-support release, with important bug fixes for at least four release cycles and security fixes for six. And every breaking change is guarded by a build switch, `WITH_BREAKING_CHANGES`, so that the future behavior can be tested before it ships.

**What the maintainer announced.** Git 2.56.0 was released on 28 September 2026. On the same day the maintainer wrote that the next version will be numbered 2.98, "scheduled near the end of this year", to be followed by 2.99 "to solidify the codebase in preparation for Git 3.0". The textbook read that message through a mailing-list mirror. The jump in the number is the signal.

**What only secondary sources say.** Calendar months, and the relation between 2.99 and 3.0, are not in any official document.

**[ON SCREEN]** The table of section 14D.2.

| Statement | Source | Status |
|---|---|---|
| Git 3.0 is planned; no date | BreakingChanges | official |
| Next release is 2.98, near the end of 2026; then 2.99 | maintainer's message of 28 September 2026 | primary, read through a mirror |
| 2.98 in December 2026 | LWN, GitLab | secondary |
| 2.99 in April 2027 (LWN) or spring 2027 (GitLab), as the long-term-support release | the same two | secondary |
| 2.99 and 3.0 ship together and differ only in the breaking-changes switch | GitLab; LWN similar | secondary |

**[ON SCREEN]** Unverified.

Every date in the last three rows of the table. Treat them as a plan reported from conference talks, and re-check BreakingChanges and the release announcement before you put a date into a migration plan.

**The planned defaults.** All of the following is from BreakingChanges as installed with Git 2.55.0.

| Planned change | Today (2.55) | In 3.0 | Condition or note | Opt in or out with |
|---|---|---|---|---|
| Hash function of new repositories | `sha1` | `sha256` | when libraries, applications and forges are ready; SHA-1 is not being deprecated | `init.defaultObjectFormat` |
| Ref storage of new repositories | `files` | `reftable` | JGit, libgit2 and Gitoxide need to support it | `init.defaultRefFormat` |
| Initial branch name | `master`, with a hint | `main` | | `init.defaultBranch` |
| Bare repositories found by walking up directories | used (`all`) | refused (`explicit`) | the fourth key | `safe.bareRepository` |
| Rust in the build | optional | mandatory | may be deferred if distributions are hit hard | a build option, not a setting |

Read the table as a plan, row by row. New repositories would use SHA-256 as their hash function, when libraries, applications and forges are ready, and SHA-1 is not being deprecated. Their refs would be stored with reftable, which JGit, libgit2 and Gitoxide need to support. The initial branch would be named `main`. A bare repository found by walking up directories would be refused. And Rust would be mandatory in the build, which may be deferred if distributions are hit hard.

**The removals.** Grafts, replaced by `git replace`. `git pack-redundant`. The directories `.git/branches/` and `.git/remotes/` as sources of remotes. `git name-rev --stdin`, replaced by `--annotate-stdin`. `git whatchanged`. And the values `core.commentString=auto` and `core.preferSymlinkRefs=true`. One section of the document records a decision not to remove something: `git checkout` stays next to `git switch` and `git restore`.

Quick quiz. Suppose Git 3.0 is released and you upgrade. What happens to the repositories you already have? A, they're converted to the new formats. B, nothing converts them. Your answer?

**[PAUSE]**

**Three points keep the scale in proportion.** The answer is B. The changed defaults apply when a repository is created. Nothing converts an existing repository. A proposal to accept only lowercase hexadecimal object IDs was still waiting for review on 28 September 2026 and is not a decision. And hosting decides more than Git does.

**Opting in, in one sentence.** Four configuration keys select, for the repositories you create, the behavior that Git 3.0 will make the default, and the same keys keep today's behavior afterwards.

**`safe.bareRepository`.** The fourth key is about which repositories Git agrees to use. A bare repository is one with no working tree, such as the one a server holds. With `explicit`, a bare repository is used only when you name it. Fetching from it, pushing to it and cloning it still work, because those commands name the repository, and a `.git` directory inside a working tree is not "bare" in this sense.

The reason for the change is a case you met in video 163. A clone never brings a `.git/config`. It can bring a tracked directory that is shaped like a bare repository, with a `HEAD`, a `config`, `objects/` and `refs/`. Step into that directory, and with the current default Git takes it for a repository and reads the configuration file that arrived as ordinary tracked content. BreakingChanges describes the attack in which such a file names a command, through `core.fsmonitor` for example, that runs when a shell prompt calls `git status`.

**SHA-256 and reftable, locally.** Two practical facts complete what video 107 taught.

History can cross the format boundary only as a stream. `git fast-export` writes history as text and `git fast-import` rebuilds it in the format of the receiving repository. Every object gets a new ID. Signatures do not survive, and commit IDs quoted in messages, issue trackers and CI configuration point at nothing in the new repository. A conversion is a migration project with a cut-over date, not a setting.

The ref format can change in place and back. `git refs migrate --ref-format=reftable` converts an existing repository, with the limits the manual lists: not with linked worktrees, and no concurrent writers during the migration. Code that reads `.git/refs/heads/<branch>` breaks at that moment, and code that expects forty hexadecimal digits breaks on SHA-256. The repair is the habit this course has used since Part 4: ask Git, with `git rev-parse`, `git for-each-ref` or `git refs list`, and never read the directory.

**GitHub, not Git.** GitHub had no publicly available support for SHA-256 repositories on 1 October 2026. A private preview is reported by GitLab's blog, a community comment and a conference speaker, and no GitHub blog post, changelog entry or documentation page announces it, so the course's research report marks it unverified. Whether a host stores refs with reftable on its servers does not concern you: the ref format is local.

So, for objective five: before a hosted team repository can use SHA-256, the host has to accept it, and so do the libraries and applications around the repository: the condition in the first row of the table. Until then a repository that must live on github.com stays SHA-1.

**In production.** The textbook's advice has three lines. Set `init.defaultBranch=main` everywhere now. It is what 3.0 will do. Set `safe.bareRepository=explicit` on developer machines now, and check the scripts that `cd` into bare repositories, backup jobs, mirror scripts, self-hosted Git servers, before 3.0 does it for you. Leave the object and ref formats at their defaults in shared configuration until your hosting and your tools are ready.

## MENTAL MODEL

A picture helps. Think of a country that announces it will change the side of the road on which new roads are built. Existing roads stay as they are. No date is fixed. The transport ministry publishes the plan in a document anyone can read, and offers a test track where you can drive the new way today.

The questions a sensible haulage company asks are yours. Which of our vehicles assume the old side? That is the script that reads `.git/refs/heads/main` by hand. Can we drive on the test track? That is the sandbox with the four keys set. And what do the newspapers say about the date, as opposed to the ministry? That is the table with its status column.

Where the picture breaks: roads are shared, and two of these four changes are not. The ref format is local to each clone and the protocol never sees it. The object format is the opposite: it is shared by everything that exchanges objects, which is why hosting decides.

## DIAGRAM

**[DIAGRAM]** The diagram of section 14D.2. Draw the line left to right. Put the two released versions first, with their dates. Then the announced ones. Then mark the three zones underneath.

```text
   2.55.0          2.56.0          2.98                  2.99                  3.0
   29 Jun 2026     28 Sep 2026     "near the end         after 2.98            no official date
   (this course)   (current)       of this year"         LTS (secondary)       with 2.99 (secondary)
   ------------ released ------------|---------- announced ----------|------- reported only -------
```

Say each zone's kind of source as you mark it. Released, which you can install. Announced, by the maintainer. Reported only, by secondary sources. The words "LTS" under 2.99 and "with 2.99" under 3.0 are in the third zone although the version numbers above them are in the second. That is exactly the distinction the interview question asks for.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14d/git3-optin`.

**What this Git was built with.** 🟢 SAFE.

```bash
git version
git version --build-options | grep -e rust -e default
```

<!-- snippet: ch14d/git3-optin/01-build -->
```text
$ git version
git version 2.55.0
$ git version --build-options | grep -e rust -e default
rust: disabled
default-ref-format: files
default-hash: sha1
```
<!-- /snippet -->

Three lines to remember: Rust disabled, default ref format `files`, default hash `sha1`. The same command on a later Git is how you check what your installation was built with.

Try it now, in any repository of your own. Thirty seconds, and it's read-only: `git rev-parse --show-object-format`. Predict first: what will it print?

**[PAUSE]**

If it printed `sha1`, that's today's default, the one the build options named. And notice how you found out: you asked Git, and you didn't read the dot git folder.

**An unconfigured `git init` today.** The lab configuration normally sets `init.defaultBranch`, so the demo removes it first. Predict the branch name. Say it out loud.

**[PAUSE]**

```bash
git config unset --global init.defaultBranch
git init today 2>&1 | grep -v "^hint: *$"
git -C today symbolic-ref HEAD
git -C today rev-parse --show-object-format --show-ref-format
```

<!-- snippet: ch14d/git3-optin/02-today -->
```text
# The lab configuration sets init.defaultBranch. Remove it to see what Git 2.55 does on its own:
$ git config unset --global init.defaultBranch
$ git init today 2>&1 | grep -v "^hint: *$"
hint: Using 'master' as the name for the initial branch. This default branch name
hint: will change to "main" in Git 3.0. To configure the initial branch name
hint: to use in all of your new repositories, which will suppress this warning,
hint: call:
hint: 	git config --global init.defaultBranch <name>
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint: 	git branch -m <name>
hint: Disable this message with "git config set advice.defaultBranchName false"
Initialized empty Git repository in $LAB/ch14d/git3-optin/today/.git/
$ git -C today symbolic-ref HEAD
refs/heads/master
$ git -C today rev-parse --show-object-format --show-ref-format
sha1
files
```
<!-- /snippet -->

`master`, with a hint, and the hint names Git 3.0. The formats: `sha1` and `files`.

**Opt in.** 🟡 CAUTION: `git config set --global` changes the global configuration file. Nothing changes in existing repositories.

```bash
git config set --global init.defaultBranch main
git config set --global init.defaultObjectFormat sha256
git config set --global init.defaultRefFormat reftable
git init tomorrow
git -C tomorrow symbolic-ref HEAD
git -C tomorrow rev-parse --show-object-format --show-ref-format
cat tomorrow/.git/config
```

<!-- snippet: ch14d/git3-optin/03-opt-in -->
```text
$ git config set --global init.defaultBranch main
$ git config set --global init.defaultObjectFormat sha256
$ git config set --global init.defaultRefFormat reftable
$ git init tomorrow
Initialized empty Git repository in $LAB/ch14d/git3-optin/tomorrow/.git/
$ git -C tomorrow symbolic-ref HEAD
refs/heads/main
$ git -C tomorrow rev-parse --show-object-format --show-ref-format
sha256
reftable
$ cat tomorrow/.git/config
[extensions]
	objectformat = sha256
	refstorage = reftable
[core]
	repositoryformatversion = 1
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
```
<!-- /snippet -->

`main`, `sha256`, `reftable`. Look at the configuration file of the new repository: `repositoryformatversion = 1` and an `[extensions]` section. That makes older Git versions refuse it instead of misreading it.

**New repositories only.** Predict: the old repository, and a clone of it made now. Which formats? Say it out loud.

**[PAUSE]**

<!-- snippet: ch14d/git3-optin/04-new-repositories-only -->
```text
# The settings act when a repository is created. An existing repository keeps what it has,
# and a clone takes its object format from the source and its ref format from your settings:
$ git -C today rev-parse --show-object-format --show-ref-format
sha1
files
$ git clone -q today today-clone
$ git -C today-clone rev-parse --show-object-format --show-ref-format
sha1
reftable
```
<!-- /snippet -->

The existing repository did not change. Its clone took the object format from the source, as it must, and the ref format from your setting, because ref storage is a local matter that the protocol never sees. One line of output, and both halves of the mental model are in it.

**Opt out.** The same keys keep the old behavior after 3.0, for the tools that need it.

<!-- snippet: ch14d/git3-optin/05-opt-out -->
```text
# The same keys keep the old behavior after 3.0, for the tools that need it:
$ git config set --global init.defaultObjectFormat sha1
$ git config set --global init.defaultRefFormat files
$ git init -q legacy-style
$ git -C legacy-style rev-parse --show-object-format --show-ref-format
sha1
files
$ git config list --global | grep init
init.defaultbranch=main
init.defaultobjectformat=sha1
init.defaultrefformat=files
```
<!-- /snippet -->

**The removals announce themselves.**

```bash
git -C today whatchanged -1 2>&1 | sed -n "1,5p;\$p"
git -C today log -1 --raw --no-merges --format="%h %s"
```

<!-- snippet: ch14d/git3-optin/06-removals -->
```text
$ git -C today whatchanged -1 2>&1 | sed -n "1,5p;\$p"
'git whatchanged' is nominated for removal.

hint: You can replace 'git whatchanged <opts>' with:
hint:	git log <opts> --raw --no-merges
hint: Or make an alias:
fatal: refusing to run without --i-still-use-this
$ git -C today whatchanged -1 > /dev/null 2>&1
[exit status: 128]
$ git -C today log -1 --raw --no-merges --format="%h %s"
c63b350 First commit

:000000 100644 0000000 587be6b A	a.txt
```
<!-- /snippet -->

On Git 2.55, `git whatchanged` refuses to run without a flag that says you still use it, exits with 128, and prints its own replacement: `git log` with `--raw --no-merges`. A script that calls it has already failed. That's the kind of thing an opt-in afternoon finds.

**[TERMINAL]** Replay `labs/run ch14d/safe-bare`.

**`explicit` in a bare repository.**

```bash
cd server.git
git log --oneline
git config set --global safe.bareRepository explicit
git log --oneline
git --git-dir=. log --oneline
```

<!-- snippet: ch14d/safe-bare/01-explicit -->
```text
$ cd server.git
$ git log --oneline
0169310 Add service
$ git config set --global safe.bareRepository explicit
$ git log --oneline
fatal: cannot use bare repository '$LAB/ch14d/safe-bare/server.git' (safe.bareRepository is 'explicit')
[exit status: 128]
# Naming the repository is what "explicit" asks for:
$ git --git-dir=. log --oneline
0169310 Add service
$ cd ..
```
<!-- /snippet -->

The same command, before and after the setting. After it: "cannot use bare repository", with the reason in parentheses. Naming the repository with `--git-dir` is what "explicit" asks for.

<!-- snippet: ch14d/safe-bare/02-still-works -->
```text
# Fetch, push and clone name the repository, and a .git directory is not "bare":
$ git -C svc fetch origin
$ git clone -q server.git svc2
$ cd svc/.git && git rev-parse --is-inside-git-dir && cd ../..
true
```
<!-- /snippet -->

What still works: the commands that name the repository.

**The embedded bare repository.** The setting is back at its default for this step. You clone a project and step into one of its directories. Predict what `git rev-parse --git-dir` will say there. Say it out loud.

**[PAUSE]**

```bash
git clone -q server.git victim
cd victim/vendor/cache.git
ls
git rev-parse --git-dir --is-bare-repository
git config get core.fsmonitor
```

<!-- snippet: ch14d/safe-bare/03-embedded -->
```text
# You clone a project and step into one of its directories:
$ git clone -q server.git victim
$ cd victim/vendor/cache.git
$ ls
config
HEAD
objects
refs
# With the default (safe.bareRepository=all) Git takes this directory for a repository and reads
# the configuration file that arrived with the clone:
$ git rev-parse --git-dir --is-bare-repository
.
true
$ git config get core.fsmonitor
echo this-would-run
```
<!-- /snippet -->

Git found a repository in a tracked directory and read a `config` file that arrived as ordinary content of the clone. The demo stops at reading a value. The value is a command.

<!-- snippet: ch14d/safe-bare/04-refused -->
```text
$ git config set --global safe.bareRepository explicit
$ git rev-parse --git-dir
fatal: cannot use bare repository '$LAB/ch14d/safe-bare/victim/vendor/cache.git' (safe.bareRepository is 'explicit')
[exit status: 128]
$ git config get core.fsmonitor
[exit status: 1]
$ cd ../..
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

With `explicit`, Git refuses the directory, the configuration value is not read, and the real repository one level up works as before.

**[TERMINAL]** Replay `labs/run ch14d/lab-42-1-sha256-reftable`, the first four snippets. The failure scenario is your lab.

**Today: a SHA-1 repository and a script from 2019.**

<!-- snippet: ch14d/lab-42-1-sha256-reftable/01-today -->
```text
$ cd inference
$ git repo info --all
layout.bare=false
layout.shallow=false
object.format=sha1
references.format=files
$ git log --oneline --graph --all
* c284765 Pad batches to a fixed length
* 53a79b6 Raise batch size to 16
* 3e283dd Add inference service
$ cat ../scripts/release-id.sh
#!/bin/sh
# Print the commit that a release is built from: the tip of main. (Written in 2019.)
id=$(cat .git/refs/heads/main) || exit 1
if ! echo "$id" | grep -Eq '^[0-9a-f]{40}$'; then
  echo "release-id: not a commit ID: $id" >&2
  exit 1
fi
echo "$id"
$ sh ../scripts/release-id.sh
53a79b6a9382bec33a6eef3d133390d21760ed78
[exit status: 0]
```
<!-- /snippet -->

`git repo info --all` prints the layout and the two formats. Then read the release script: it reads `.git/refs/heads/main` with `cat` and checks for exactly forty hexadecimal digits. It works today. Predict two ways in which it will stop working.

**The future: both formats at creation.** 🟢 SAFE: `git init` creates a new repository.

```bash
git init --object-format=sha256 --ref-format=reftable future
cd future
git repo info --all
ls .git
cat .git/HEAD
git log --format="%H %s"
git refs list
```

<!-- snippet: ch14d/lab-42-1-sha256-reftable/02-future -->
```text
$ cd ..
$ git init --object-format=sha256 --ref-format=reftable future
Initialized empty Git repository in $LAB/ch14d/lab-42-1-sha256-reftable/future/.git/
$ cd future
$ git repo info --all
layout.bare=false
layout.shallow=false
object.format=sha256
references.format=reftable
$ ls .git
config
description
HEAD
hooks
info
objects
refs
reftable
$ cat .git/HEAD
ref: refs/heads/.invalid
$ printf 'def predict(batch):\n    return model(batch)\n' > serve.py && git add serve.py
$ git commit -q -m "Add inference service"
$ git log --format="%H %s"
6d0637831bf2a3c8930ac8f5fd161b98a63ed74471242e1f7974994c83b975df Add inference service
$ git refs list
6d0637831bf2a3c8930ac8f5fd161b98a63ed74471242e1f7974994c83b975df commit	refs/heads/main
```
<!-- /snippet -->

A `reftable` directory in `.git`. `HEAD` is a stub that names `refs/heads/.invalid`: with reftable, the file exists for tools that look for it, and the real value is in the table. And the commit ID has sixty-four characters. `git refs list` reads refs whatever the backend.

**Converting the object format.** Predict what a fetch between the two repositories will say. Say it out loud.

**[PAUSE]**

```bash
git -C future fetch -q ../inference main
git init -q --object-format=sha256 inference-sha256
git -C inference fast-export --all | git -C inference-sha256 fast-import --quiet
git -C inference log --oneline --all
git -C inference-sha256 log --oneline --all
```

<!-- snippet: ch14d/lab-42-1-sha256-reftable/03-convert -->
```text
# Object formats cannot be mixed, so history moves as a stream and every object gets a new name:
$ cd ..
$ git -C future fetch -q ../inference main
fatal: mismatched algorithms: client sha256; server sha1
[exit status: 128]
$ git init -q --object-format=sha256 inference-sha256
$ git -C inference fast-export --all | git -C inference-sha256 fast-import --quiet
$ git -C inference log --oneline --all
c284765 Pad batches to a fixed length
53a79b6 Raise batch size to 16
3e283dd Add inference service
$ git -C inference-sha256 log --oneline --all
4fea7f1 Pad batches to a fixed length
587a0ea Raise batch size to 16
6daacca Add inference service
$ git -C inference-sha256 repo info object.format references.format
object.format=sha256
references.format=files
```
<!-- /snippet -->

"Mismatched algorithms": the two formats cannot exchange objects. The stream carries the history across. The subjects match and no ID does: `53a79b6` on one side, `587a0ea` on the other, for the same commit.

**Migrating the ref format in place.** 🟡 CAUTION: `git refs migrate` rewrites how refs are stored in this repository. Preview: `git for-each-ref` before, to compare afterwards. It can be migrated back. Not with linked worktrees, and no concurrent writers.

```bash
git for-each-ref
git refs migrate --ref-format=reftable
git repo info references.format
git for-each-ref
```

<!-- snippet: ch14d/lab-42-1-sha256-reftable/04-migrate -->
```text
# The ref format of an existing repository can be changed in place:
$ cd inference
$ git for-each-ref
c28476567742db22d0af945e617907ddec7c325d commit	refs/heads/feature/batching
53a79b6a9382bec33a6eef3d133390d21760ed78 commit	refs/heads/main
2c5a6d507719d6d960f0d6a892995d8d612279c5 tag	refs/tags/v0.1.0
$ git refs migrate --ref-format=reftable
$ git repo info references.format
references.format=reftable
$ git for-each-ref
c28476567742db22d0af945e617907ddec7c325d commit	refs/heads/feature/batching
53a79b6a9382bec33a6eef3d133390d21760ed78 commit	refs/heads/main
2c5a6d507719d6d960f0d6a892995d8d612279c5 tag	refs/tags/v0.1.0
```
<!-- /snippet -->

The same three refs with the same IDs before and after. Nothing a Git command can see has changed. What changed is what `cat .git/refs/heads/main` can see, and that's the lab's failure scenario.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Quoting a release month for Git 3.0 as a fact.** Root cause: the official document says there is no planned date; the months come from secondary reports of conference talks.
2. **Expecting 3.0 to convert existing repositories.** Root cause: the planned changes are defaults applied when a repository is created, plus removals of deprecated features.
3. **Setting SHA-256 as the default in shared configuration now.** Root cause: the object format is shared by everything that exchanges objects, and on 1 October 2026 github.com had no publicly available support for it.
4. **Reading refs from files in scripts.** Root cause: with reftable there is no file per branch, so only commands such as `git rev-parse` and `git for-each-ref` give the value on every backend.
5. **Treating a format conversion as a setting.** Root cause: every object gets a new ID, signatures do not survive, and every recorded commit ID points at nothing in the new repository.

## PRODUCTION EXAMPLE

Now, out of the lab. A platform engineer is asked the hook's question by her CTO on a Monday. She answers on Tuesday, with three paragraphs and their sources.

What is planned: new defaults for new repositories and a list of removals, from the BreakingChanges document installed on her own laptop. When: no official date. The maintainer has announced versions 2.98 and 2.99. The months in circulation are from two secondary sources, and she labels them so. What breaks for us: she spent the afternoon on that. In a sandbox with the four keys set, she ran the team's release tooling and its backup job. Two things failed. A release script read a branch file with `cat` and checked for forty characters. And the nightly mirror job changed directory into bare repositories and ran `git log` there, which `safe.bareRepository=explicit` refuses.

Her recommendation follows the textbook's three lines. `init.defaultBranch=main` everywhere, today. `safe.bareRepository=explicit` on developer machines today, after the mirror job is changed to name its repository. Object and ref formats left at their defaults in shared configuration, with one sentence on why: the host. The two scripts are fixed that week, and they are fixed in the durable way: they ask Git. And that's the question from the opening, answered: three paragraphs, each with its source.

## PRACTICE EXERCISE

Your turn. Do Lab 42.1, "SHA-256 and reftable repositories", in [`lab-manual/m42-frontier.md`](../../lab-manual/m42-frontier.md).

Before you create the repository with the planned formats, predict what `.git` will contain that a repository of today does not, and what `.git/HEAD` will hold. Before the conversion, predict which of these survive it: subjects, commit IDs, tags, signatures. Before the lab's failure scenario, read the release script and write down the two lines that will break and in which repository each will break.

The challenge: opt in to the planned defaults in a sandbox configuration and run your own team's Git scripts there. List what breaks and why. Use a sandbox configuration, not your real global file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q425: "What will Git 3.0 change, for which repositories, and what is the official statement about its date? Which parts of the schedule come from secondary sources?"

Read the question, then answer out loud.

**[PAUSE]**

The question has four parts and rewards separation of sources. A strong answer lists the changes in two groups, defaults and removals, and says precisely to which repositories the defaults apply. It gives the official statement about the date as what it is, one sentence in one document, and names the document. It then separates what the maintainer announced from what only secondary sources report, and labels the last group as unverified. It ends on what a team should do with that uncertainty, which is not to wait: name the two settings worth adopting now and the two worth leaving alone, with the reason for each.

## RECAP

Let's land this.

- Git 3.0 plans new defaults for newly created repositories, SHA-256, reftable, `main`, `safe.bareRepository=explicit`, mandatory Rust in the build, and a list of removals; existing repositories keep their formats.
- Officially there is no planned release date; the maintainer has announced 2.98 and 2.99; calendar months come from secondary sources.
- Four keys choose the planned behavior today and keep the old behavior later: `init.defaultObjectFormat`, `init.defaultRefFormat`, `init.defaultBranch` and `safe.bareRepository`.
- The ref format is local and can be migrated in place; the object format is shared, changes every ID when converted, and depends on the host.
- Scripts ask Git for refs and IDs; they never read `.git` by hand.

## HOMEWORK

Read sections 14D.1 to 14D.5. Then find the BreakingChanges document of your own installation, in the directory that `git --html-path` prints, and find the sentence about the release date. Video 201 shows the exact command. Check whether it still reads as quoted in this video. If it doesn't, you've learned the most important thing this part teaches.

Today you separated a plan from a rumour, and you tried the planned defaults in a sandbox, where nothing of yours could break. Next time: `git history`, `git replay`, `git last-modified` and `git repo`. Until then, look at the state first and type second. See you in the next one.
