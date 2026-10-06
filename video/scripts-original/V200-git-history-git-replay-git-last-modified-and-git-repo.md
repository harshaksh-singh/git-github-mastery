# V200: git history, git replay, git last-modified and git repo

- **Part.** 11, Expert: the frontier
- **Module.** 42
- **Planned minutes.** 24
- **Prerequisites.** V055, V199
- **Textbook sections.** [Chapter 14D](../../textbook/ch14d-frontier.md), sections 14D.6 to 14D.8, with 14D.13 and 14D.14; [Chapter 9](../../textbook/ch09-rebase.md), section 9.20
- **Demo scripts.** `labs/ch14d/history.sh` (snippets `01-help` to `09-limits`), `labs/ch14d/replay.sh` (snippets `01-bare` to `04-revert`), `labs/ch14d/inspect.sh` (snippets `01-last-modified` to `04-repo-structure`), `labs/ch09/replay-conflict.sh` (snippet `01-conflict`)

## HOOK

**[ON SCREEN]** "A blog post says `git history` replaces interactive rebase. Do we change our guidelines?"

A colleague has read that there is a new command that rewords an old commit in one line, with no todo list and no editor full of `pick`. It is true. The command exists in the Git on your machine, and it does what the post says.

It also moves every local branch that contains the commit, without asking. It runs no hooks. It refuses any history with a merge in it, and any operation that would conflict. And the first line of its manual page is one word in capitals: EXPERIMENTAL. A guideline is a promise about what works next year. This is not yet that.

## INTRODUCTION

This video covers four new commands. Two of them rewrite or replay commits without a working tree: `git history` and `git replay`. Two of them inspect a repository: `git last-modified` and `git repo`. All four are marked experimental in their manuals.

In V055 you learned interactive rebase: `reword`, `fixup`, `squash`, `edit`. You know what it does to the working tree, to HEAD and to the state directory while it runs. That knowledge is the measuring stick for today, because the question for each new command is the same: what does it do differently, and what follows from the difference?

Versions matter here, so listen for them. Every "added in Git 2.56" in this video means: not run here. The lab has Git 2.55.0.

## LEARNING OBJECTIVES

After this video you can:

1. Reword, fix up and split a commit with `git history` and say which branches move.
2. Compare `git history reword` with an interactive rebase: working tree, hooks, merges, conflicts.
3. Explain why a server needs `git replay` and what `--ref-action=print` gives it.
4. Use `git last-modified`, `git repo info` and `git repo structure` to inspect a repository.
5. State which of these commands are experimental and which part is a Git 2.56 addition.

## CONCEPT

**`git history`, in one sentence.** `git history` rewrites one commit, its message, its content, or its division into two, and replays every descendant on top, updating all local branches that contain the commit, without touching a working tree and without a todo list. Its label is 🟡 CAUTION.

**Precisely.** The command arrived in Git 2.54 with `reword` and `split`. Git 2.55 added `fixup`. `drop` is new in Git 2.56 and is not run here. The first line of its manual says EXPERIMENTAL.

Compared with `git rebase -i`, the manual names three differences. Most subcommands need neither index nor working tree, so they work in a bare repository. No hooks are run. And by default every branch that descends from the commit is updated, where a rebase moves one branch unless you add `--update-refs`.

Two limits are by design for now: no merges in the affected history, and no operation that would conflict.

**Inside `.git`.** New commit objects for the target and all its descendants. Every affected branch ref moves, each with a reflog entry of the form "reword: updating" followed by what you typed. HEAD's reflog gets one entry.

**[ON SCREEN]** The state table of section 14D.6.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| 🟡 `git history reword <commit>` | unchanged | unchanged | follows its branch | moved to the rewritten tip | every other local branch that contains the commit is moved too; reflog entries; new objects | unchanged; branches that were pushed now diverge | unchanged |
| 🟡 `git history fixup <commit>` | unchanged | the staged change is consumed | as above | as above | as above | as above | unchanged |
| 🟢 `git history ... --dry-run` | unchanged | unchanged | unchanged | unchanged | new objects only | unchanged | unchanged |

Read the "Remote" cell of the first row: branches that were pushed now diverge. That is the sentence that decides when not to use the command.

**When to use it, and when not.** The default of moving every descendant branch is right for a stack of local branches and wrong the moment one of them is published. Because no hooks run, a message convention enforced by a `commit-msg` hook is not checked. So: use it for local cleanup before the first push, read `--dry-run` first, and keep `git rebase -i` for everything with merges or conflicts.

One observation from the lab, which the textbook marks as unverified because the manual does not state it: on Git 2.55.0, `git history reword` gives the rewritten commit a new committer date, although the manual says that all other details stay as they were.

**`git replay`.** From section 9.20: `git replay` replays a range onto a new base without touching the working tree or the index, so it also works in a bare repository. The command exists for servers. A hosting service that rebases or cherry-picks for you has no working tree to do it in. It was introduced in Git 2.44 as a server-side tool.

Three forms. `--onto` rebases a range onto a new base. `--advance=<branch>` is a cherry-pick of the range onto that branch; the original author is kept. And since Git 2.54 the same machinery reverts, with `--revert`. `--linearize` was added in Git 2.56 and is not run here.

`--ref-action=print` creates the commits and prints the ref update, which a server can inspect or feed to `git update-ref --stdin`. Without it, the default since Git 2.53, the ref moves in one transaction.

The price of having no working tree: it cannot stop for a conflict. A replay that would conflict exits with status 1, prints nothing, and leaves the branch where it was.

And a second price in a bare repository: a bare repository keeps no reflog unless `core.logAllRefUpdates` says so, so a replay there has no local undo.

Its value for you is mostly indirect: it is the kind of operation behind a "rebase and merge" button.

**`git last-modified` and `git repo`.** Two experimental commands from Git 2.52 answer questions that used to need a loop or a peek into `.git`.

`git last-modified` prints, for each path, the commit that last changed it: the "last commit" column of a file browser. With `-r` it descends to files.

`git repo info` returns named facts about a repository in a stable `key=value` form, which is what a script should use in place of reading `.git/config`. Git 2.56 adds `path.*` keys, not run here. `git repo structure` counts refs and objects.

**The rule for all four.** Do not adopt experimental commands in shared automation. Output and options may change between releases. Use them at the keyboard, and pin the Git version where a script depends on one.

## MENTAL MODEL

Think of two ways to correct a typo on page one of a bound manuscript.

Interactive rebase takes the binding apart on your desk. Page by page it rebuilds the book in front of you, and while it works your desk is covered: the working tree is checked out at each step, HEAD is detached, hooks run, and if a page does not fit you are asked to fix it by hand.

`git history` works in the archive. It writes a corrected page one and fresh copies of every later page, in the object database, and then moves the shelf labels, all of them, in one step. Your desk is never touched.

That is why it is fast, why it works in a bare repository, why no hook is called, and why it cannot ask you to resolve a conflict: there is no desk to put the conflict on.

Where the picture breaks: an archivist would ask before moving a label that somebody else's catalogue points at. `git history` moves every local branch that contains the commit and asks nothing. The reflog of each branch has the old tip. There is no single undo.

## DIAGRAM

**[DIAGRAM]** A new drawing: the same reword done twice. On the left by interactive rebase, with the working tree marked as touched. On the right by `git history`, with the working tree untouched and every branch moved.

```text
  git rebase -i  (reword an old commit)              git history reword <commit>

   working tree : checked out at each step,           working tree : untouched
                  rewritten to the new tip             index        : untouched
   index        : rewritten                            HEAD         : stays on its branch
   HEAD         : detached during the run              .git         : no state directory
   .git         : rebase-merge/ during the run
                                                       hooks        : none run
   hooks        : run
                                                       branches     : every local branch that contains
   branches     : the current branch only                             the commit moves
                  (others with --update-refs)
                                                       merges above : refused
   merges above : --rebase-merges                      conflicts    : refused, nothing changes
   conflicts    : stops, you resolve, continue

        A---B---C   main                                    A---B---C   main
             \                                                   \
              D     topic            only main moves              D     topic         main AND topic move:
                                     unless --update-refs                              A', B', C', D' are all new
```

Build the left column from what you know from V055, then the right column line by line against it. The bottom drawing is the difference to remember: on the left `topic` keeps pointing at the old commits unless you ask; on the right it is moved for you.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14d/history`.

**What the command offers on this version.**

<!-- snippet: ch14d/history/01-help -->
```text
$ git history -h
usage: git history fixup <commit> [--dry-run] [--update-refs=(branches|head)] [--reedit-message] [--empty=(drop|keep|abort)]
   or: git history reword <commit> [--dry-run] [--update-refs=(branches|head)]
   or: git history split <commit> [--dry-run] [--update-refs=(branches|head)] [--] [<pathspec>...]

[exit status: 129]
```
<!-- /snippet -->

Three subcommands on Git 2.55: `fixup`, `reword`, `split`. No `drop`: that is the 2.56 addition. Each takes `--dry-run`, and `--update-refs` with two values, `branches` and `head`.

**Reword.** The repository has a typo in its oldest commit and three branches above it. 🟡 CAUTION: `git history reword` creates new commits and moves every descendant local branch. Preview: `--dry-run`. Recovery: each branch's reflog. Predict: after rewording the oldest commit, how many commit IDs in this graph stay the same?

```bash
git log --oneline --graph --all
git history reword HEAD~3
git log --oneline --graph --all
```

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

None. The editor opened with the old message, and the message was replaced: "metirc" became "metric". Every commit ID changed, including `67d2d0a` on the side branch, which is now `131e7a7`.

```bash
git reflog -1
git reflog show -1 release/0.1
git reflog show -1 topic/judge
git status -sb
```

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

`main`, `release/0.1` and `topic/judge` all point into the new history, each with its own reflog entry. And `git status` says we are on `main`, as if nothing happened: no checkout took place.

**Dry run.**

```bash
git history reword --dry-run HEAD~2
git log --oneline -3
```

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

A dry run writes the new objects and prints the ref updates instead of making them, in the input format of `git update-ref --stdin`: three branches would move. The log afterwards is unchanged. This is the list to read before every real run: is any of these branches published?

**Fixup.** A staged change is folded into an older commit, and its descendants are replayed. This is the autosquash workflow of V056 in one step.

```bash
git add test_metrics.py
git history fixup HEAD~2
git status -s
git log --oneline --stat --format='%h %s' -3
```

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

The status is empty: the staged change was consumed. The commit two back now contains the test file as well.

**Split.** `split` asks, hunk by hunk, what to move into a new commit that becomes the parent of the original. The demo answers yes to the first hunk and no to the second, and supplies two messages.

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

One commit became two: "Add F1 metric" with the function, then "Test the F1 metric" with the test, and the two later commits were replayed on top.

**No hooks.** A `commit-msg` hook that refuses every message is installed. Predict: will it stop a reword?

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

**[PAUSE]** An ordinary `git commit` is refused by the hook. `git history reword` goes through, and the new message is in the log. If your team's message convention lives in a `commit-msg` hook, this command walks past it.

**The limits, each with its real message.**

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

A fixup that would conflict: "fixup would produce conflicts; aborting", exit status 255, and the staged change is still staged. Nothing changed. A history with a merge above the target: "replaying merge commits is not supported yet!". Both are refusals, not half-finished states. That is the good side of having no desk.

**[TERMINAL]** Replay `labs/run ch14d/replay`.

**A bare repository.**

<!-- snippet: ch14d/replay/01-bare -->
```text
$ git rev-parse --is-bare-repository
true
$ git log --oneline --graph --all
* 9e11dcc Document the timeout
* f21ac0f Add a 10 second timeout to routing
| * 36761eb Raise the rate limit to 120
|/  
* c55bd6f Add gateway skeleton
```
<!-- /snippet -->

No working tree. `fix/timeout` has two commits and branches off an old commit of `main`.

**Print the update.** 🟢 for this form: with `--ref-action=print` only new objects are written.

```bash
git replay --ref-action=print --advance=main main..fix/timeout
git log --oneline -1 main
```

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

One line in `update-ref` format: the ref, the new value, the old value. `main` itself has not moved. A server can inspect that line, check rules against it, and then apply it.

**Advance.** 🟡 CAUTION: `git replay --advance` creates commits and moves the ref in one transaction. Preview: the print form you saw. Recovery: the reflog, where one exists; none by default in a bare repository.

```bash
git replay --advance=main main..fix/timeout
git log --oneline --graph --all
git log -2 --format='%h author: %an, committer: %cn | %s' main
```

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

`main` now carries copies of the two commits, `dc10709` and `863b8b5`; the originals are still on `fix/timeout`. It is a cherry-pick of a range, done where no checkout exists.

**Revert, and the missing reflog.**

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

The revert commit has the usual message. And the last command printed nothing: this bare repository keeps no reflog, so the replay has no local undo.

**The conflict case.** Replay `labs/run ch09/replay-conflict`. Predict what a replay prints when the range would conflict.

```bash
git replay --onto=main main..feat/rerank
git log --oneline --decorate -1 feat/rerank
git status --short --branch
```

<!-- snippet: ch09/replay-conflict/01-conflict -->
```text
$ git replay --onto=main main..feat/rerank
[exit status: 1]
$ git log --oneline --decorate -1 feat/rerank
ad106e3 (feat/rerank) Enable reranking in config
$ git status --short --branch
## main
```
<!-- /snippet -->

**[PAUSE]** Exit status 1, no output, and the branch is where it was. No message, no state directory, nothing to continue. In a script, the exit status is the only signal. For a conflict you rebase in a working tree.

**[TERMINAL]** Replay `labs/run ch14d/inspect`. All commands are 🟢 SAFE.

**`git last-modified`.**

```bash
git log --oneline --graph
git last-modified
git last-modified -r
```

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

One line per entry of the top-level tree. For the directory `src` the answer is the merge commit, `5bcf6ca`, because the two sides changed different files in it and only the merge produced the present tree. With `-r` it descends to files, and each file names an ordinary commit.

<!-- snippet: ch14d/inspect/02-compare -->
```text
# The same answer for one path, the way it was asked before Git 2.52:
$ git log -1 --format='%H' -- src/limits.yaml
36761eb01933290987d1bcfb23c957a4a0f35f8d
# A revision range limits the search:
$ git last-modified -r HEAD~1 -- src
36761eb01933290987d1bcfb23c957a4a0f35f8d	src/limits.yaml
c55bd6fa76f857bdfa065a08270542fcd387e99a	src/router.py
```
<!-- /snippet -->

The same answer for one path, the way it was asked before Git 2.52: `git log -1` with a path. And a revision range limits the search.

**`git repo info` and `git repo structure`.**

```bash
git repo info --keys
git repo info --all
git -C ../server.git repo info layout.bare references.format
```

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

Four keys on this version: whether the repository is bare, whether it is shallow, the object format and the ref format. This is what a script should ask in place of reading `.git/config`, and it is what you would have used in V199's release script.

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

Counts of refs and objects by kind, and their inflated sizes, as lines a script can parse.

## COMMON MISTAKES

1. **Running `git history` on a commit that was already pushed.** Root cause: it moves every local branch that contains the commit, so each published branch now diverges from the server.
2. **Expecting hooks to check a reworded message.** Root cause: the command runs no hooks, so a convention enforced by `commit-msg` is not applied.
3. **Reading exit status 1 from `git replay` as a crash.** Root cause: with no working tree it cannot stop for a conflict, so it reports one by exiting with 1 and no output.
4. **Putting an experimental command into shared automation.** Root cause: output and options may change between releases, and the manual says so in its first line.
5. **Assuming a replay in a bare repository can be undone locally.** Root cause: a bare repository keeps no reflog unless it is configured to.

## PRODUCTION EXAMPLE

A team lead is asked the hook's question: do we change our guidelines? She tests before she answers.

In a sandbox she takes a typical local stack: three small branches for one feature, none of them pushed. A typo in the first commit's message is fixed with one `git history reword`, after a dry run that lists three branches, all local. All three move together. She notes that this used to need a rebase with `--update-refs`.

Then she tries what the team's guidelines protect. The message convention is enforced by a `commit-msg` hook: the reword goes past it. A second stack has a merge in it: refused. A branch that is already pushed: the dry run lists it, and she stops there.

Her answer to the team is three sentences. The guidelines do not change: interactive rebase stays the documented tool, because it runs hooks and handles merges and conflicts. `git history` is allowed for local cleanup before the first push, always after `--dry-run`. And nothing experimental goes into the release scripts; where a script wants `git repo info`, the script pins the Git version and says so in a comment.

## PRACTICE EXERCISE

Do Lab 42.2, "`git history reword`", in [`lab-manual/m42-frontier.md`](../../lab-manual/m42-frontier.md).

Before the dry run, predict which branches it will list and why. Before the real reword, predict what `git status -sb` will print afterwards for a branch that has an upstream. In the lab's failure scenario a pushed commit is reworded: before you repair it, write down where the old tip of each affected branch can be found and how many separate repairs you will need.

The challenge: in a sandbox, rebuild Lab 9.1 with `git history` where it applies, and note which steps still need an interactive rebase.

## INTERVIEW QUESTION

**[ON SCREEN]** Q437: "Compare `git history reword` with `git rebase -i` and `reword`: working tree, hooks, which branches move, merges, conflicts."

Answer aloud. The question hands you five headings; use them as your structure and give each one sentence for each command. A strong answer explains the differences from one cause instead of listing five facts: what it means that one of the two never checks anything out. It states the version and the status of the newer command. And it ends, as the rule says, on a limit and a control: when you would refuse to use the newer command, and what you would run first to find out whether you are in that case.

## RECAP

- `git history` rewords, fixes up or splits one commit without a working tree, replays every descendant, and moves every local branch that contains the commit.
- It runs no hooks and refuses merges and conflicts; it is experimental, with `reword` and `split` since Git 2.54, `fixup` since 2.55, and `drop` added in 2.56, not run here.
- `git replay` rebases, cherry-picks or reverts without a working tree, for servers; `--ref-action=print` prints the ref update instead of making it; a conflict is exit status 1 with no output.
- `git last-modified` names the commit that last changed each path; `git repo info` and `git repo structure` report facts and counts in a form scripts can read.
- Use all four at the keyboard, read `--dry-run` or the printed update first, and keep experimental commands out of shared automation.

## HOMEWORK

Read sections 14D.6 to 14D.8 and section 9.20. Then open the manual page of `git history` in your own installation and check its first line and its list of subcommands against this video. If they differ, your Git is newer than the course, and the manual is right.
