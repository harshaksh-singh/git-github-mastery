# Chapter 14D: The Frontier

> **Baseline.** Git 2.55.0 on macOS; facts about releases and about GitHub as of 1 October 2026. Transcripts are real output from `labs/ch14d/`. Git 2.56 features are described from its documentation and marked "not run here". Dates that rest on secondary sources are marked as such.

## 14D.1 Why this matters

Three questions a CTO can ask in the next twelve months:

1. "I read that Git 3.0 changes the hash and the default branch. What breaks for us, and when?"
2. "Should new repositories use SHA-256 now?"
3. "A blog post says `git history` replaces interactive rebase. Do we change our guidelines?"

Short answers. The planned changes of Git 3.0 are defaults for newly created repositories and the removal of a few long-deprecated features; existing repositories keep their formats, and no official date exists (sections 14D.2 and 14D.3). SHA-256 works locally and cannot be pushed to github.com today, so a repository that must live there stays SHA-1 (section 14D.5). `git history` is experimental, refuses histories with merges and runs no hooks, so it is a convenience for local cleanup and not a guideline (section 14D.6).

The skill this chapter trains is not knowing those answers. They will be out of date. It is finding them in primary sources within a few minutes: the BreakingChanges document, the release notes, the manual page of your installed version, and a sandbox. Chapter 3 (Git Internals) explains the SHA-256 and reftable formats and Chapter 9 (Rebase) introduces `git replay` and `git history`; this chapter builds on both.

## 14D.2 The road to Git 3.0

**What is official.** The Git project keeps a document named BreakingChanges, shipped with every installation ([BreakingChanges](https://git-scm.com/docs/BreakingChanges)). It says that breaking releases happen rarely (1.6.0 in August 2008, 2.0 in May 2014), lists what Git 3.0 will change, and states: "There is no planned release date for this breaking version yet." That sentence is in the copy installed with Git 2.55.0 and, according to the Phase 0 report, unchanged at 2.56.0. The same document promises that the last version before 3.0 will be a long-term-support release with important bug fixes for at least four release cycles and security fixes for six, and that every breaking change is guarded by a build switch, `WITH_BREAKING_CHANGES`, so that the future behavior can be tested before it ships.

**What the maintainer announced.** Git 2.56.0 was released on 28 September 2026. On the same day the maintainer wrote that the next version will be numbered 2.98, "scheduled near the end of this year", to be followed by 2.99 "to solidify the codebase in preparation for Git 3.0" ([mailing-list mirror](https://ratatoskr.run/git/2026/09/17654892)). The jump in the number is the signal.

**What only secondary sources say.** Calendar months and the relation between 2.99 and 3.0 are not in any official document.

| Statement | Source | Status |
|---|---|---|
| Git 3.0 is planned; no date | BreakingChanges | official |
| Next release is 2.98, near the end of 2026; then 2.99 | maintainer's message of 28 September 2026 | primary, read through a mirror |
| 2.98 in December 2026 | [LWN](https://lwn.net/Articles/1094575/), [GitLab](https://about.gitlab.com/blog/whats-new-in-git-2-56-0/) | secondary |
| 2.99 in April 2027 (LWN) or spring 2027 (GitLab), as the long-term-support release | the same two | secondary |
| 2.99 and 3.0 ship together and differ only in the breaking-changes switch | GitLab; LWN similar | secondary |

**Picture.**

```text
   2.55.0          2.56.0          2.98                  2.99                  3.0
   29 Jun 2026     28 Sep 2026     "near the end         after 2.98            no official date
   (this course)   (current)       of this year"         LTS (secondary)       with 2.99 (secondary)
   ------------ released ------------|---------- announced ----------|------- reported only -------
```

> **Unverified.** Every date in the last three rows of the table. Treat them as a plan reported from conference talks, and re-check BreakingChanges and the release announcement before you put a date into a migration plan.

## 14D.3 The planned defaults and removals

All of the following is from BreakingChanges as installed with Git 2.55.0.

| Planned change | Today (2.55) | In 3.0 | Condition or note | Opt in or out with |
|---|---|---|---|---|
| Hash function of new repositories | `sha1` | `sha256` | when libraries, applications and forges are ready; SHA-1 is not being deprecated | `init.defaultObjectFormat` |
| Ref storage of new repositories | `files` | `reftable` | JGit, libgit2 and Gitoxide need to support it | `init.defaultRefFormat` |
| Initial branch name | `master`, with a hint | `main` | | `init.defaultBranch` |
| Bare repositories found by walking up directories | used (`all`) | refused (`explicit`) | section 14D.4 | `safe.bareRepository` |
| Rust in the build | optional | mandatory | may be deferred if distributions are hit hard | a build option, not a setting |

Removals: grafts (use `git replace`), `git pack-redundant`, the directories `.git/branches/` and `.git/remotes/` as sources of remotes, `git name-rev --stdin` (use `--annotate-stdin`), `git whatchanged`, and the values `core.commentString=auto` and `core.preferSymlinkRefs=true`. One section of the document records a decision not to remove something: `git checkout` stays next to `git switch` and `git restore`.

Two of the removals already announce themselves on Git 2.55:

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

Three points keep the scale of this in proportion. The changed defaults apply when a repository is created; nothing converts an existing repository. A proposal to accept only lowercase hexadecimal object IDs was still waiting for review on 28 September 2026 and is not a decision ([mailing-list mirror](https://ratatoskr.run/git/2026/09/17654892)). And hosting decides more than Git does: see the callout in section 14D.5.

## 14D.4 Opting in today, and opting out later

**In one sentence.** Four configuration keys select, for the repositories you create, the behavior that Git 3.0 will make the default, and the same keys keep today's behavior afterwards.

**See it.** What this Git was built with:

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

An unconfigured `git init` on 2.55 (the lab configuration normally sets `init.defaultBranch`, so the demo removes it first):

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

The hint names Git 3.0. Now the three `init.*` keys:

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

A repository with either new format has `repositoryformatversion = 1` and an `[extensions]` section, which makes older Git versions refuse it instead of misreading it (Chapter 3, sections 3.13 and 3.14).

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

The existing repository did not change. Its clone took the object format from the source, as it must, and the ref format from your setting, because ref storage is a local matter that the protocol never sees.

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

**`safe.bareRepository`.** The fourth key is about which repositories Git agrees to use. With `explicit`, a bare repository is used only when you name it:

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

Fetching from it, pushing to it and cloning it still work, because those commands name the repository, and a `.git` directory inside a working tree is not "bare" in this sense. The reason for the change is the case that Chapter 14C, section 14C.12 left open. A clone never brings a `.git/config`. It can bring a tracked directory that is shaped like a bare repository, with a `HEAD`, a `config`, `objects/` and `refs/`:

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

Inside that directory Git found a repository and read a `config` file that arrived as ordinary tracked content. This demo stops at reading a value; BreakingChanges describes the attack in which such a file names a command (through `core.fsmonitor`, for example) that runs when a shell prompt calls `git status`. With `explicit`:

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

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| 🟡 `git config set --global init.default*` | unchanged | unchanged | unchanged | unchanged | none in existing repositories; the global configuration file changes | unchanged | unchanged |
| 🟢 `git init` with those keys | new, empty | none yet | `ref: refs/heads/<init.defaultBranch>` (a stub with reftable) | unborn | `extensions.objectformat`, `extensions.refstorage`, `reftable/` | unchanged | unchanged |
| 🟡 `git config set --global safe.bareRepository explicit` | unchanged | unchanged | unchanged | unchanged | none; Git commands run inside bare repositories now need `--git-dir` or `GIT_DIR` | unchanged | unchanged |

**In production.** Set `init.defaultBranch=main` everywhere now; it is what 3.0 will do. Set `safe.bareRepository=explicit` on developer machines now, and check the scripts that `cd` into bare repositories (backup jobs, mirror scripts, self-hosted Git servers) before 3.0 does it for you. Leave the object and ref formats at their defaults in shared configuration until your hosting and your tools are ready.

## 14D.5 SHA-256 and reftable repositories, locally

Chapter 3 explains both formats and shows that SHA-1 and SHA-256 repositories cannot exchange objects. Two practical facts complete the picture, and Lab 42.1 exercises both.

**History can cross the format boundary only as a stream.** `git fast-export` writes history as text and `git fast-import` rebuilds it in the format of the receiving repository. Every object gets a new ID:

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

The subjects match and no ID does. Signatures do not survive, and commit IDs quoted in messages, issue trackers and CI configuration point at nothing in the new repository. A conversion is a migration project with a cut-over date, not a setting.

**The ref format can change in place and back.** `git refs migrate --ref-format=reftable` converts an existing repository, with the limits the manual lists (not with linked worktrees, and no concurrent writers during the migration). Code that reads `.git/refs/heads/<branch>` breaks at that moment, and code that expects forty hexadecimal digits breaks on SHA-256:

<!-- snippet: ch14d/lab-42-1-sha256-reftable/05-failure -->
```text
# The release script has not changed. Two repositories, two different failures:
$ sh ../scripts/release-id.sh
cat: .git/refs/heads/main: Not a directory
[exit status: 1]
$ cd ../inference-sha256
$ sh ../scripts/release-id.sh
release-id: not a commit ID: 587a0ea1903116442c9bc9d9014567a4bfdde436c0268f95ddbfb247362f5639
[exit status: 1]
```
<!-- /snippet -->

The repair is the habit this course has used since Chapter 3: ask Git (`git rev-parse`, `git for-each-ref`, `git refs list`) and never read the directory.

> **GitHub, not Git.** GitHub had no publicly available support for SHA-256 repositories on 1 October 2026. A private preview is reported by GitLab's blog, a community comment and a conference speaker, and no GitHub blog post, changelog entry or documentation page announces it, so the Phase 0 report marks it unverified ([community discussion](https://github.com/orgs/community/discussions/12490)). Whether a host stores refs with reftable on its servers does not concern you: the ref format is local.

## 14D.6 `git history`: single-purpose rewrites

**In one sentence.** 🟡 `git history` rewrites one commit (its message, its content, or its division into two) and replays every descendant on top, updating all local branches that contain the commit, without touching a working tree and without a todo list.

**Precisely.** The command arrived in Git 2.54 with `reword` and `split`; 2.55 added `fixup`; `drop` is new in Git 2.56 (not run here) ([git-history at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/git-history.adoc)). The first line of its manual says EXPERIMENTAL. Compared with `git rebase -i` the manual names three differences: most subcommands need neither index nor working tree, so they work in a bare repository; no hooks are run; and by default every branch that descends from the commit is updated, where a rebase moves one branch unless you add `--update-refs`. Two limits are by design for now: no merges in the affected history, and no operation that would conflict.

**Inside `.git`.** New commit objects for the target and all its descendants; every affected branch ref moves, each with a reflog entry `reword: updating <what you typed>`; HEAD's reflog gets one entry.

**See it.** The repository has a typo in its oldest commit and three branches above it:

<!-- snippet: ch14d/history/02-reword -->
```text
$ git log --oneline --graph --all
* f0d1c5a Add development requirements
| * 67d2d0a Add judge prompt
|/  
* 39f5b0c Add README
* 156aedd Add F1 and its test
* ec69d27 Add exact match metirc
$ git history reword HEAD~3
$ git log --oneline --graph --all
* 544b01e Add development requirements
| * 131e7a7 Add judge prompt
|/  
* 545a235 Add README
* ccbad89 Add F1 and its test
* ff71a66 Add exact-match metric
```
<!-- /snippet -->

The editor opened with the old message, and the message was replaced. Every commit ID changed, and `main`, `release/0.1` and `topic/judge` all point into the new history:

<!-- snippet: ch14d/history/03-reflogs -->
```text
$ git reflog -1
544b01e HEAD@{0}: reword: updating HEAD~3
$ git reflog show -1 release/0.1
545a235 release/0.1@{0}: reword: updating HEAD~3
$ git reflog show -1 topic/judge
131e7a7 topic/judge@{0}: reword: updating HEAD~3
$ git status -sb
## main
```
<!-- /snippet -->

`--dry-run` shows what would move. It writes the new objects and prints the ref updates in the input format of `git update-ref --stdin`:

<!-- snippet: ch14d/history/04-dry-run -->
```text
# A dry run writes the new objects and prints the ref updates instead of making them:
$ git history reword --dry-run HEAD~2
update refs/heads/release/0.1 3d69bd220ec3abddad18c7e8b3346dfce1e86875 545a2357ebf779e3ff3fe25722f31fa7cdec7c18
update refs/heads/topic/judge 817d179159be202eaac73a802d2d6ee5809a7d0d 131e7a7a4f0c7f2fecd731a761cea3d6826886f6
update refs/heads/main a61938caa6eebb699fad4e1eb3ac960d840a2e26 544b01e4b86859029e518ca1f02c4779bedc01eb
$ git log --oneline -3
544b01e Add development requirements
545a235 Add README
ccbad89 Add F1 and its test
```
<!-- /snippet -->

`fixup` folds the staged change into an older commit, which is the autosquash workflow of Chapter 9 in one step:

<!-- snippet: ch14d/history/05-fixup -->
```text
# A staged change is folded into an older commit, and its descendants are replayed:
$ printf 'from metrics import f1\n\n\ndef test_f1():\n    assert f1(1, 0, 0) == 1.0\n    assert f1(0, 1, 1) == 0.0\n' > test_metrics.py
$ git add test_metrics.py
$ git history fixup HEAD~2
[exit status: 0]
$ git status -s
$ git log --oneline --stat --format='%h %s' -3
6794ec8 Add development requirements

 requirements-dev.txt | 1 +
 1 file changed, 1 insertion(+)
f5e9c9c Add README

 README.md | 3 +++
 1 file changed, 3 insertions(+)
49ba6c8 Add F1 and its test

 metrics.py      | 4 ++++
 test_metrics.py | 6 ++++++
 2 files changed, 10 insertions(+)
```
<!-- /snippet -->

`split` asks, hunk by hunk, what to move into a new commit that becomes the parent of the original. The demo answers `y` and `n` and supplies two messages:

<!-- snippet: ch14d/history/06-split -->
```text
# Answers typed at the two prompts: y (move this hunk into the new, earlier commit), then n.
$ printf 'y\nn\n' | git history split HEAD~2
diff --git a/metrics.py b/metrics.py
index d6bc9be..e1c56b4 100644
--- a/metrics.py
+++ b/metrics.py
@@ -1,2 +1,6 @@
 def exact(pred, gold):
     return pred == gold
+
+
+def f1(tp, fp, fn):
+    return 2 * tp / (2 * tp + fp + fn)
(1/1) Stage this hunk [y,n,q,a,d,?]? 
diff --git a/test_metrics.py b/test_metrics.py
new file mode 100644
index 0000000..d3c2e3e
--- /dev/null
+++ b/test_metrics.py
@@ -0,0 +1,6 @@
+from metrics import f1
+
+
+def test_f1():
+    assert f1(1, 0, 0) == 1.0
+    assert f1(0, 1, 1) == 0.0
(1/1) Stage addition [y,n,q,a,d,?]? 
```
<!-- /snippet -->

<!-- snippet: ch14d/history/07-after-split -->
```text
$ git log --stat --format='%h %s' -4
f6c5fad Add development requirements

 requirements-dev.txt | 1 +
 1 file changed, 1 insertion(+)
06c85c9 Add README

 README.md | 3 +++
 1 file changed, 3 insertions(+)
298f4d9 Test the F1 metric

 test_metrics.py | 6 ++++++
 1 file changed, 6 insertions(+)
24381a5 Add F1 metric

 metrics.py | 4 ++++
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

The limits, each with its real message:

<!-- snippet: ch14d/history/08-no-hooks -->
```text
# A commit-msg hook that refuses every message does not stop it: git history runs no hooks.
$ printf '#!/bin/sh\necho "commit-msg: refused" >&2\nexit 1\n' > .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg
$ git commit --allow-empty -m "probe"
commit-msg: refused
[exit status: 1]
$ git history reword HEAD
$ git log --oneline -1
82c3f29 Add dev requirements
```
<!-- /snippet -->

<!-- snippet: ch14d/history/09-limits -->
```text
# A fixup that would conflict is refused, and nothing changes:
$ printf 'def exact(pred, gold):\n    return pred.strip() == gold.strip()\n\n\ndef f1(tp, fp, fn):\n    return 2 * tp / (2 * tp + fp + fn)\n' > metrics.py && git add metrics.py
$ git history fixup HEAD~4
error: fixup would produce conflicts; aborting
[exit status: 255]
$ git status -s
M  metrics.py
# History with a merge commit above the target is refused as well:
$ git log --oneline --graph -4
*   b8a371c Merge topic/judge
|\  
| * 5ac3007 Add judge prompt
* | 82c3f29 Add dev requirements
|/  
* 06c85c9 Add README
$ git history reword HEAD~2
error: replaying merge commits is not supported yet!
[exit status: 255]
```
<!-- /snippet -->

**State table.**

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| 🟡 `git history reword <commit>` | unchanged | unchanged | follows its branch | moved to the rewritten tip | every other local branch that contains the commit is moved too; reflog entries; new objects | unchanged; branches that were pushed now diverge | unchanged |
| 🟡 `git history fixup <commit>` | unchanged | the staged change is consumed | as above | as above | as above | as above | unchanged |
| 🟢 `git history ... --dry-run` | unchanged | unchanged | unchanged | unchanged | new objects only | unchanged | unchanged |

**In production.** The default of moving every descendant branch is right for a stack of local branches and wrong the moment one of them is published: Lab 42.2 rewords a pushed commit and then puts two branches back from their reflogs. Because no hooks run, a message convention enforced by `commit-msg` is not checked. The lab also shows that the committer date of the rewritten commit changes although the manual says that all other details stay as they were. Use it for local cleanup before the first push, read `--dry-run` first, and keep `git rebase -i` for everything with merges or conflicts.

## 14D.7 `git replay`: rebase and cherry-pick without a working tree

Chapter 9, section 9.20 showed `git replay --onto` and its silent failure on a conflict. The command exists for servers: a hosting service that rebases or cherry-picks for you has no working tree to do it in. In the bare repository of the demo, `fix/timeout` branches off an old commit of `main`:

<!-- snippet: ch14d/replay/02-print -->
```text
# Put the two commits of fix/timeout on top of main, and only say which ref would move:
$ git replay --ref-action=print --advance=main main..fix/timeout
update refs/heads/main 1653f1a9ffb2929d943f9eea08a045ec877c6e21 36761eb01933290987d1bcfb23c957a4a0f35f8d
[exit status: 0]
$ git log --oneline -1 main
36761eb Raise the rate limit to 120
```
<!-- /snippet -->

`--ref-action=print` creates the commits and prints the update, which a server can inspect or feed to `git update-ref --stdin`. Without it (the default since Git 2.53) the ref moves in one transaction:

<!-- snippet: ch14d/replay/03-advance -->
```text
$ git replay --advance=main main..fix/timeout
[exit status: 0]
$ git log --oneline --graph --all
* 863b8b5 Document the timeout
* dc10709 Add a 10 second timeout to routing
* 36761eb Raise the rate limit to 120
| * 9e11dcc Document the timeout
| * f21ac0f Add a 10 second timeout to routing
|/  
* c55bd6f Add gateway skeleton
$ git log -2 --format='%h author: %an, committer: %cn | %s' main
863b8b5 author: Lab User, committer: Lab User | Document the timeout
dc10709 author: Lab User, committer: Lab User | Add a 10 second timeout to routing
```
<!-- /snippet -->

`--advance=main` is a cherry-pick of the range onto `main`; the original author is kept. Since Git 2.54 the same machinery reverts:

<!-- snippet: ch14d/replay/04-revert -->
```text
# Since Git 2.54 the same machinery reverts:
$ git replay --revert=main main~1..main
[exit status: 0]
$ git log -1 --format=%B main
Revert "Document the timeout"

This reverts commit 863b8b52c9ef9bbf4d884372524d9fd9a4cb9021.

# A bare repository keeps no reflog unless it is configured to, so this prints nothing:
$ git reflog show main
```
<!-- /snippet -->

The last command printed nothing: a bare repository keeps no reflog unless `core.logAllRefUpdates` says so, so a replay there has no local undo. `git replay --linearize` was added in Git 2.56 (not run here) ([git-replay at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/git-replay.adoc)). The command is experimental, and its value for you is mostly indirect: it is the kind of operation behind a "rebase and merge" button.

## 14D.8 `git last-modified` and `git repo`

Two experimental commands from Git 2.52 answer questions that used to need a loop or a peek into `.git`.

<!-- snippet: ch14d/inspect/01-last-modified -->
```text
$ git log --oneline --graph
*   5bcf6ca Merge branch 'fix/timeout'
|\  
| * 9e11dcc Document the timeout
| * f21ac0f Add a 10 second timeout to routing
* | 36761eb Raise the rate limit to 120
|/  
* c55bd6f Add gateway skeleton
# One line per entry of the top-level tree: the commit that last changed it.
$ git last-modified
5bcf6ca2deb65d80283c0a190f491cf04040bd48	src
9e11dccdbbb9baf1ebd438d9185161322cc66779	docs
$ git last-modified -r
9e11dccdbbb9baf1ebd438d9185161322cc66779	docs/README.md
f21ac0fee598130815a3870c12ac15b75494d550	src/router.py
36761eb01933290987d1bcfb23c957a4a0f35f8d	src/limits.yaml
```
<!-- /snippet -->

`git last-modified` prints, for each path, the commit that last changed it: the "last commit" column of a file browser. For the directory `src` the answer is the merge commit, because the two sides changed different files in it and only the merge produced the present tree. With `-r` it descends to files.

<!-- snippet: ch14d/inspect/03-repo-info -->
```text
$ git repo info --keys
layout.bare
layout.shallow
object.format
references.format
$ git repo info --all
layout.bare=false
layout.shallow=false
object.format=sha1
references.format=files
$ git -C ../server.git repo info layout.bare references.format
layout.bare=true
references.format=files
```
<!-- /snippet -->

`git repo info` returns named facts about a repository in a stable `key=value` form, which is what a script should use in place of reading `.git/config`. Git 2.56 adds `path.*` keys (not run here). `git repo structure` counts refs and objects:

<!-- snippet: ch14d/inspect/04-repo-structure -->
```text
$ git repo structure --format=lines | grep -e count -e inflated
references.branches.count=2
references.tags.count=0
references.remotes.count=2
references.others.count=0
objects.commits.count=5
objects.trees.count=11
objects.blobs.count=6
objects.tags.count=0
objects.commits.inflated_size=1132
objects.trees.inflated_size=683
objects.blobs.inflated_size=230
objects.tags.inflated_size=0
```
<!-- /snippet -->

## 14D.9 Rust in Git, stacked workflows, and Git-compatible tools

**Rust.** BreakingChanges gives the milestones: Rust code entered Git as optional in 2.49, was auto-detected by one of the two build systems in 2.52, is enabled by default in both from 2.55, and becomes mandatory in 3.0 unless the impact on distributions leads to a deferral. The long-term-support promise of section 14D.2 exists for platforms without a Rust toolchain. For you as a user nothing changes except where the binary comes from. The first transcript of section 14D.4 printed `rust: disabled`: Homebrew builds its Git 2.55.0 with `NO_RUST=1` ([formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/g/git.rb), read on 2 October 2026). So "enabled by default" is a statement about the build system, and each distributor decides.

**Stacked workflows.** A stack is a chain of small dependent branches, each reviewed on its own. In Git the tools are `git rebase --update-refs` (Chapter 9, Lab 9.7), `git range-diff` for comparing versions, and now `git history`, whose default of moving all descendant branches fits a stack.

> **GitHub, not Git.** Stacked pull requests entered public preview on GitHub on 30 July 2026, with a `gh stack` extension for the command line ([changelog](https://github.blog/changelog/2026-07-30-stacked-pull-requests-are-now-in-public-preview/)). Described from the changelog; not exercised here.

**Tools worth knowing by name.** None is part of Git, and none is needed for this course.

| Tool | What it is | Relation to Git |
|---|---|---|
| [Jujutsu (`jj`)](https://github.com/jj-vcs/jj) | A version-control system with no index, automatic rebasing of descendants and conflicts that can be committed | stores its data in Git repositories; its README calls it experimental |
| [Sapling](https://sapling-scm.com/docs/introduction/) | Meta's client with first-class stacks | Git-compatible client |
| [git-branchless](https://github.com/arxanas/git-branchless) | Adds undo, a smart log and restacking | a set of commands on top of Git; self-described alpha |
| Graphite, GitButler | Commercial products for stacked changes and branch management | on top of Git and GitHub |
| [libgit2](https://libgit2.org/), [JGit](https://github.com/eclipse-jgit/jgit), [Gitoxide](https://github.com/GitoxideLabs/gitoxide) | Implementations of Git as libraries, in C, Java and Rust | what many IDEs, servers and tools use in place of the `git` program |

The last row is the one that matters for the 3.0 defaults: BreakingChanges names exactly these three libraries as the ones that must support reftable before it becomes the default. A tool built on a library reads your repository with that library's abilities, not with those of the `git` you installed.

## 14D.10 Reading release notes, BreakingChanges and the GitHub Changelog

**Release notes.** Every release has one file, on [GitHub](https://github.com/git/git/tree/master/Documentation/RelNotes) and on your disk:

<!-- snippet: ch14d/release-notes/01-where -->
```text
$ ls "$(git --html-path)/RelNotes" | grep -c adoc
541
$ ls "$(git --html-path)/RelNotes" | grep "^2\.5[3-5]"
2.53.0.adoc
2.54.0.adoc
2.54.1.adoc
2.55.0.adoc
```
<!-- /snippet -->

A file for 2.54.1 exists, and the Phase 0 report found no tag and no tarball for that version: a notes file is not proof of a release. The tag list is. Each file has the same three parts:

<!-- snippet: ch14d/release-notes/02-sections -->
```text
$ grep -n -B1 "^---" "$(git --html-path)/RelNotes/2.55.0.adoc" | grep -v -e "---" -e "^--$"
4-UI, Workflows & Features
82-Performance, Internal Implementation, Development Support etc.
236-Fixes since v2.54
```
<!-- /snippet -->

Read the first part completely: it is short and it is where behavior changes are. Search the rest for the commands you depend on:

<!-- snippet: ch14d/release-notes/03-search -->
```text
# What did 2.55 say about the commands of this chapter?
$ grep -n -A1 -e "git history" -e "Rust support" -e "Hook scripts" "$(git --html-path)/RelNotes/2.55.0.adoc"
7: * Hook scripts defined via the configuration system can now be
8-   configured to run in parallel.
--
28: * "git history" learned "fixup" command.
29-
--
88: * Rust support is enabled by default (but still allows opting out) in
89-   some future version of Git.
```
<!-- /snippet -->

The style is terse, one bullet per topic, often without the option names. The procedure that works: find the bullet, open the manual page of that command at the new version, and try it in a sandbox. Note the third hit. The wording about Rust in the installed notes is vaguer than the milestone in BreakingChanges, and the Phase 0 report quotes a different sentence for the same release, which shows why this course cites the installed copy when it can.

**BreakingChanges.**

<!-- snippet: ch14d/release-notes/04-breaking-changes -->
```text
$ grep -n "^==" "$(git --html-path)/BreakingChanges.adoc"
62:== Procedure
80:== Git 3.0
89:=== Changes
243:=== Removals
342:== Superseded features that will not be deprecated
$ grep -n "planned release date" "$(git --html-path)/BreakingChanges.adoc"
83:is no planned release date for this breaking version yet.
# One line per planned change of a default:
$ sed -n '/^=== Changes/,/^=== Removals/p' "$(git --html-path)/BreakingChanges.adoc" | grep '^\* ' | cut -c1-78
* The default hash function for new repositories will be changed from "sha1"
* The default storage format for references in newly created repositories will
* In new repositories, the default branch name will be `main`. We have been
* Git will require Rust as a mandatory part of the build process. While Git
* The default value of `safe.bareRepository` will change from `all` to
```
<!-- /snippet -->

The headings are the whole structure: the procedure, the changes, the removals, and what will not be deprecated. Each item links to the mailing-list thread where it was decided.

**The other channels.** The maintainer's "What's cooking" messages list every topic in flight and its state, and [Git Rev News](https://git.github.io/rev_news/) summarizes the list monthly. Vendor posts (the highlight posts of GitHub and GitLab for each release) are readable and selective: use them to learn that something exists and the primary text to learn what it does.

> **GitHub, not Git.** The [GitHub Changelog](https://github.blog/changelog/) is the primary source for platform behavior, dated entry by entry. A feature there has a state (preview or generally available) and often a plan gate. Nothing in it describes the `git` program on your machine, and a Git release changes nothing on github.com until GitHub deploys it.

A routine that takes fifteen minutes per release: read the first section of the notes; search for your team's commands; look at the diff of BreakingChanges; decide whether any default you rely on is named; write down the minimum version for anything new you want to adopt.

## 14D.11 The patch-based workflow of the Git project

**In one sentence.** Git itself is developed by sending commits as e-mail: `git format-patch` turns commits into message files, reviewers answer on the list, and the maintainer applies accepted series with `git am`; no pull request is involved.

**Precisely.** A contribution starts on a topic branch. Each commit carries a `Signed-off-by` trailer (`git commit -s`), by which the author certifies the right to submit it. `git format-patch` writes one file per commit plus an optional cover letter, and `git send-email` posts them to `git@vger.kernel.org`; GitGitGadget is a bridge that turns a pull request on GitHub into such a series ([SubmittingPatches](https://git-scm.com/docs/SubmittingPatches), [MyFirstContribution](https://git-scm.com/docs/MyFirstContribution), [GitGitGadget](https://gitgitgadget.github.io/)). After review the author sends a complete new version (`v2`, `v3`) with a range-diff against the previous one. The maintainer queues topics on the branch `seen`, merges them to `next` for testing and then to `master`; `maint` receives fixes for the last release ([maintain-git](https://github.com/git/git/blob/v2.56.0/Documentation/howto/maintain-git.adoc)).

**See it.** Asha has a branch with two signed-off commits and no push access to the maintainer's repository:

<!-- snippet: ch14d/patch-series/01-format-patch -->
```text
$ cd contributor
$ git log --format='%h %an | %s' origin/main..casefold
4309e9b Asha Rao | README: document the lowercasing
0cddac1 Asha Rao | tok: lowercase the input before splitting
$ git format-patch --cover-letter --base=origin/main -o ../outbox/v1 origin/main
../outbox/v1/0000-cover-letter.patch
../outbox/v1/0001-tok-lowercase-the-input-before-splitting.patch
../outbox/v1/0002-README-document-the-lowercasing.patch
```
<!-- /snippet -->

<!-- snippet: ch14d/patch-series/02-patch-file -->
```text
$ cat ../outbox/v1/0001-tok-lowercase-the-input-before-splitting.patch
From 0cddac17b0e047370ed3799c71bf9c20fd534983 Mon Sep 17 00:00:00 2001
From: Asha Rao <asha@example.com>
Date: Mon, 7 Sep 2026 10:08:00 +0530
Subject: [PATCH 1/2] tok: lowercase the input before splitting

Signed-off-by: Asha Rao <asha@example.com>
---
 tok.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tok.py b/tok.py
index 2800645..d89f8b7 100644
--- a/tok.py
+++ b/tok.py
@@ -1,2 +1,2 @@
 def tokenize(text):
-    return text.split()
+    return text.lower().split()
-- 
2.55.0
```
<!-- /snippet -->

A patch file is an e-mail. The `From <id>` line and the fixed date after it mark the format. `From:`, `Date:` and `Subject:` become author, author date and subject. The message body follows, then `---`, then a diffstat that is ignored on application, then the diff. `[PATCH 1/2]` is stripped by `git am`.

<!-- snippet: ch14d/patch-series/03-cover-letter -->
```text
$ sed -n '/^Subject/,$p' ../outbox/v1/0000-cover-letter.patch
Subject: [PATCH 0/2] *** SUBJECT HERE ***

*** BLURB HERE ***

Asha Rao (2):
  tok: lowercase the input before splitting
  README: document the lowercasing

 README.md | 2 +-
 tok.py    | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)


base-commit: 9ba24bca99d4152c3fd1aff140540eb6cb16a88f
-- 
2.55.0
```
<!-- /snippet -->

The cover letter is a template to fill in. `base-commit` tells reviewers and tools which commit the series applies to. The maintainer applies the two patches:

<!-- snippet: ch14d/patch-series/04-am -->
```text
# The maintainer, in a repository that has never seen the branch:
$ cd ../upstream
$ git switch -q -c review/casefold
$ git am ../outbox/v1/0001-*.patch ../outbox/v1/0002-*.patch
Applying: tok: lowercase the input before splitting
Applying: README: document the lowercasing
$ git log --format='%h author: %an, committer: %cn | %s' -2
632b3e7 author: Asha Rao, committer: Ravi Menon | README: document the lowercasing
463b82b author: Asha Rao, committer: Ravi Menon | tok: lowercase the input before splitting
$ git log -1 --format=%B
README: document the lowercasing

Signed-off-by: Asha Rao <asha@example.com>
```
<!-- /snippet -->

The author is Asha, the committer is the person who ran `git am`: the two identities of a commit (Chapter 6) exist for this workflow. The commits are new objects with the same content:

<!-- snippet: ch14d/patch-series/05-same-change-new-id -->
```text
# The applied commits have new IDs and the same content as the originals:
$ git rev-parse 'HEAD^{tree}'
95b752c13b6b8cd0443d6e6cc40521f652ffafe6
$ git -C ../contributor rev-parse 'casefold^{tree}'
95b752c13b6b8cd0443d6e6cc40521f652ffafe6
$ git show HEAD~1 | git patch-id --stable | cut -d" " -f1
20e1452a5c438e93046c3c9fcf204de5c866748a
$ git -C ../contributor show casefold~1 | git patch-id --stable | cut -d" " -f1
20e1452a5c438e93046c3c9fcf204de5c866748a
```
<!-- /snippet -->

Equal trees, equal patch IDs, different commit IDs (Chapter 10, section 10.10 on patch IDs). Review asks for a change, and the contributor rewrites the branch and sends version 2:

<!-- snippet: ch14d/patch-series/06-v2 -->
```text
# Review asked for casefold() instead of lower(). The contributor keeps v1 and rewrites the branch:
$ cd ../contributor
$ git branch casefold-v1
$ git range-diff origin/main casefold-v1 casefold
1:  0cddac1 < -:  ------- tok: lowercase the input before splitting
-:  ------- > 1:  3e0656d tok: lowercase the input before splitting
2:  4309e9b = 2:  5b37458 README: document the lowercasing
```
<!-- /snippet -->

<!-- snippet: ch14d/patch-series/07-v2-series -->
```text
$ git format-patch -v2 --cover-letter --range-diff=casefold-v1 --base=origin/main -o ../outbox/v2 origin/main
../outbox/v2/v2-0000-cover-letter.patch
../outbox/v2/v2-0001-tok-lowercase-the-input-before-splitting.patch
../outbox/v2/v2-0002-README-document-the-lowercasing.patch
$ sed -n '/^Range-diff/,/^-- /p' ../outbox/v2/v2-0000-cover-letter.patch
Range-diff against v1:
1:  0cddac1 ! 1:  3e0656d tok: lowercase the input before splitting
    @@ tok.py
     @@
      def tokenize(text):
     -    return text.split()
    -+    return text.lower().split()
    ++    return text.casefold().split()
2:  4309e9b = 2:  5b37458 README: document the lowercasing

base-commit: 9ba24bca99d4152c3fd1aff140540eb6cb16a88f
-- 
```
<!-- /snippet -->

`git range-diff` pairs the commits of the two versions. On its own it judged the rewritten first patch a total rewrite and printed it as removed (`<`) and added (`>`): its `--creation-factor` defaults to 60, and in a two-line patch one changed line is a large share. `format-patch --range-diff` defaults to 999, because it compares iterations of one topic, so the cover letter shows the same pair with `!` and a diff of the two diffs. The second patch is `=`: unchanged. This is how a reviewer of version 2 sees what changed since version 1 without reading everything again. Chapter 9, section 9.14 uses the same command to review a rebase.

**In production.** You will meet this workflow in three places besides the Git project: the Linux kernel and other list-based projects, vendors who send fixes as patch files, and environments where two repositories cannot reach each other. `git am` also underlies `git rebase --apply`. Lab 42.3 does the round trip and repairs a patch that no longer applies. On GitHub the same ideas have other names: the pull request is the cover letter, a force-pushed branch is a new version, and "compare" is a weaker range-diff.

## 14D.12 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| `fatal: mismatched algorithms: client sha256; server sha1` | The two repositories use different object formats (`git rev-parse --show-object-format` in each) | Recreate one side in the other format through `fast-export` and `fast-import`; plan it as a migration | Decide the format at `git init`; SHA-1 for everything that goes to GitHub |
| New repositories are SHA-256 or reftable and a tool cannot open them | `git config list --show-origin` shows `init.defaultObjectFormat` or `init.defaultRefFormat` | Unset the key; `git refs migrate --ref-format=files` for the ref format | Opt in per repository with `git init --object-format`, `--ref-format`, not globally |
| A script fails with `Not a directory` or `No such file` under `.git/refs` | The repository uses reftable, or the ref is packed | Use `git rev-parse`, `git for-each-ref` | Never read `.git` directly |
| `fatal: cannot use bare repository ... (safe.bareRepository is 'explicit')` | A command ran inside a bare repository without naming it | `git --git-dir=<path> ...` or `GIT_DIR` | Fix server and backup scripts before 3.0 |
| `'git whatchanged' is nominated for removal` | The command is on the removal list | `git log --raw --no-merges` | Read the Removals list once per release |
| After `git history`, branches are "ahead N, behind M" | A commit that was already pushed was rewritten; all descendant branches moved | Put each branch back from its reflog (Lab 42.2) | `git branch -r --contains <commit>` first; `--dry-run` |
| `error: replaying merge commits is not supported yet!` | `git history` met a merge above the target | `git rebase -i --rebase-merges` | Clean up before merging |
| `git replay` exits 1 without output | The replay would conflict | Rebase in a working tree | Not applicable |
| `error: patch failed` ... `patch does not apply` in `git am` | The base moved; `git am --show-current-patch=diff` | `git am --abort`, then `git am -3` and resolve (Lab 42.3) | `--base` in `format-patch`; apply to the stated base |
| `git range-diff` shows a changed patch as `<` and `>` | The pair fell under the creation factor | `--creation-factor=<higher>` | Not applicable |

## 14D.13 When not to use it, and dangerous edge cases

**Do not adopt experimental commands in shared automation.** `git history`, `git replay`, `git last-modified` and `git repo` carry the word EXPERIMENTAL in their manuals: output and options may change between releases. Use them at the keyboard, and pin the Git version where a script depends on one.

**Do not set the 3.0 formats globally on a machine that talks to GitHub.** A repository created with SHA-256 cannot be pushed there today, and the error appears at the first push, after the work is done.

**Do not treat a secondary date as a deadline.** The only dated facts about 3.0 are that 2.56 is out and that 2.98 is next.

**`git history` and published commits.** It moves every local branch that contains the commit, in one command and without asking. The reflog of each branch has the old tip; there is no single undo.

**`git am` in a dirty tree, and `git apply`.** `git am` refuses to start when the index has changes. `git apply` without `--index` or `--3way` patches working files only and creates no commit; it is a tool for trying a patch, not for integrating one.

**`safe.bareRepository=explicit` and tools.** Editors and prompts that run Git inside bare repositories stop working until they pass `--git-dir`.

## 14D.14 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git version --build-options`, `git repo info`, `git repo structure`, `git last-modified` | 🟢 | nothing | not needed | not needed |
| `git config set --global init.default*`, `safe.bareRepository` | 🟡 | behavior of later commands | `git config list --show-origin` | unset the keys |
| `git init --object-format=sha256 --ref-format=reftable` | 🟢 | creates a repository | not needed | delete the directory |
| `git refs migrate --ref-format=<format>` | 🟡 | rewrites ref storage of the repository | `--dry-run` | migrate back |
| `git fast-export --all \| git fast-import` | 🟢 | fills the receiving repository; the source is untouched | not needed | delete the new repository |
| `git history reword`, `fixup`, `split` | 🟡 | new commits; every descendant local branch moves | `--dry-run` | each branch's reflog |
| `git replay --onto`, `--advance`, `--revert` | 🟡 | new commits; refs move in one transaction | `--ref-action=print` | reflog, where one exists; none by default in a bare repository |
| `git format-patch`, `git range-diff`, `git apply --check`, `--stat` | 🟢 | writes patch files, or nothing | not needed | delete the files |
| `git am` | 🟡 | new commits on the current branch | `git apply --check` | `git am --abort` while it is stopped; afterwards the reflog of the branch |
| `git apply` | 🟡 | working files (and the index with `--index`) | `--check`, `--stat` | `git apply -R` |

## 14D.15 Version notes

> **Version note.** Older behavior: SHA-1 object IDs, refs in files, `master`, bare repositories used wherever found. Current behavior: the same on Git 2.55 and 2.56. Since: the changes are planned for Git 3.0, which has no official date; 2.98 and 2.99 come first. Recommended: `init.defaultBranch=main` and `safe.bareRepository=explicit` now; the formats when your hosting supports them.

> **Version note.** Older behavior: interactive rebase for every rewrite. Current behavior: `git history reword` and `split` (Git 2.54), `fixup` (2.55), `drop` (2.56, not run here), all experimental. Recommended: local cleanup only.

> **Version note.** Older behavior: `git replay` printed ref updates. Current behavior: it updates refs in a transaction, and `--ref-action=print` restores the old output. Since: Git 2.53; the command exists since 2.44, `--revert` since 2.54, `--linearize` since 2.56 (not run here).

> **Version note.** Older behavior: scripts read `.git/config` and counted files. Current behavior: `git repo info`, `git repo structure` and `git last-modified`, all experimental. Since: Git 2.52. Recommended: prefer them to reading `.git`, and check the manual of your version.

> **Unverified.** The calendar months for 2.98, 2.99 and 3.0; a GitHub preview of SHA-256 repositories; and one observation made on Git 2.55.0 that the manual does not state: `git history reword` gives the rewritten commit a new committer date (Lab 42.2).

## 14D.16 Practice

- **Module 42** ([lab manual](../lab-manual/m42-frontier.md)): 42.1 SHA-256 and reftable repositories, and a script that breaks on both; 42.2 `git history reword`, and a pushed commit rewritten by mistake; 42.3 a format-patch and am round trip, and a patch that no longer applies.
- Replay any transcript with `labs/run ch14d/<demo>`.
- Two drills. Read the "UI, Workflows & Features" section of the newest release notes on your disk and write down, for three bullets, the command you would run to see the change. In the sandbox left by `ch14d/patch-series`, apply version 2 in `upstream` on a fresh branch and use `git range-diff` there to compare it with the applied version 1.

## 14D.17 Interview questions

1. What will Git 3.0 change, for which repositories, and what is the official statement about its date? Which parts of the schedule come from secondary sources?
2. Name the four configuration keys that choose the 3.0 defaults ahead of time. Which of them would you set on a developer laptop today, and which not?
3. What does `safe.bareRepository=explicit` refuse, what does it still allow, and which attack is it aimed at?
4. A team wants SHA-256 for a new service that is hosted on GitHub. What do you tell them, and how would an existing repository be converted later?
5. Compare `git history reword` with `git rebase -i` and `reword`: working tree, hooks, which branches move, merges, conflicts.
6. Why does a server need `git replay`, and what does `--ref-action=print` give it?
7. How do you find out whether a behavior change in a new Git release affects your team? Which documents do you read, in which order?
8. Explain a patch file line by line. Which parts become the commit, and why do the author and the committer differ after `git am`?
9. What does `git range-diff` compare, and what do `=`, `!`, `<` and `>` mean?
10. Your Git reports `rust: disabled`. What does that tell you, and what does the BreakingChanges document promise to platforms without Rust?

## 14D.18 Sources

**Primary sources**

- [BreakingChanges](https://git-scm.com/docs/BreakingChanges), read in the copy installed with Git 2.55.0, and the [release notes directory](https://github.com/git/git/tree/master/Documentation/RelNotes).
- [git-init](https://git-scm.com/docs/git-init), [git-config](https://git-scm.com/docs/git-config) (`init.*`, `safe.bareRepository`), [git-refs](https://git-scm.com/docs/git-refs), [hash-function-transition](https://git-scm.com/docs/hash-function-transition), [git-fast-export](https://git-scm.com/docs/git-fast-export), [git-fast-import](https://git-scm.com/docs/git-fast-import).
- [git-history](https://git-scm.com/docs/git-history), [git-replay](https://git-scm.com/docs/git-replay), [git-last-modified](https://git-scm.com/docs/git-last-modified), [git-repo](https://git-scm.com/docs/git-repo); for 2.56-only parts, [git-history at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/git-history.adoc) and [git-replay at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/git-replay.adoc).
- [git-format-patch](https://git-scm.com/docs/git-format-patch), [git-am](https://git-scm.com/docs/git-am), [git-apply](https://git-scm.com/docs/git-apply), [git-range-diff](https://git-scm.com/docs/git-range-diff), [git-patch-id](https://git-scm.com/docs/git-patch-id), [git-send-email](https://git-scm.com/docs/git-send-email), [SubmittingPatches](https://git-scm.com/docs/SubmittingPatches), [MyFirstContribution](https://git-scm.com/docs/MyFirstContribution), [maintain-git](https://github.com/git/git/blob/v2.56.0/Documentation/howto/maintain-git.adoc).
- The maintainer's message of 28 September 2026, through a [mailing-list mirror](https://ratatoskr.run/git/2026/09/17654892), as cited in the Phase 0 report.
- The [GitHub Changelog](https://github.blog/changelog/), with the entry on [stacked pull requests](https://github.blog/changelog/2026-07-30-stacked-pull-requests-are-now-in-public-preview/); the [Homebrew formula for Git](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/g/git.rb).

**Secondary sources**

- [LWN on the road to 3.0](https://lwn.net/Articles/1094575/) and [GitLab on Git 2.56](https://about.gitlab.com/blog/whats-new-in-git-2-56-0/): the only sources for calendar months. The Phase 0 report records a conflict between LWN's paraphrase and the primary message.
- The Phase 0 report of this course, section 1, with its table of flags.
- [Git Rev News](https://git.github.io/rev_news/); the repositories and documentation of [Jujutsu](https://github.com/jj-vcs/jj), [Sapling](https://sapling-scm.com/docs/introduction/) and [git-branchless](https://github.com/arxanas/git-branchless).

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- [Reftable Backend: What it is, where it's headed and why should you care](https://www.youtube.com/watch?v=TqHYOGCJkS8), Patrick Steinhardt, 20 minutes, 3 September 2025. Caveat: assumes knowledge of internals.
- [SHA-256 at a Hyperscaler](https://www.youtube.com/watch?v=eJJp0RE7cd4), Emily Shaffer, Git Merge 2026, 32 minutes, uploaded 1 October 2026. Caveat from the report: almost no views when checked, so there is no secondary quality signal.
- [You Don't Know Git](https://www.youtube.com/watch?v=DZI0Zl-1JqQ), Edward Thomson, NDC London 2025, 1 hour 2 minutes: rerere, the reflog, worktrees and rebase variants.

**Further reading**

- [Chapter 3](ch03-git-internals.md) for the formats, [Chapter 9](ch09-rebase.md) for rebase, `--update-refs` and `git range-diff`, [Chapter 10](ch10-cherry-pick.md) for patch IDs, [Chapter 14C](ch14c-stash-rerere-attributes-hooks.md) for hooks and their security.
