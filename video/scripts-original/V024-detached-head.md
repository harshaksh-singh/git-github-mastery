# V024: Detached HEAD

- **Part.** 1: Foundations
- **Module.** 4
- **Planned minutes.** 20
- **Prerequisites.** V023
- **Textbook sections.** [Chapter 7: Branches](../../textbook/ch07-branches.md), section 7.7
- **Demo scripts.** `labs/ch07/detached-head.sh`, `labs/ch07/detached-ways.sh`

## HOOK

**[ON SCREEN]** "A contractor says two days of work vanished after she 'checked out a tag to test something'. Is it gone?"

Your CTO asks: "A contractor says two days of work vanished after she 'checked out a tag to test something'. Is it gone?"

She checked out a tag. She kept working, and committed, for two days. Then she switched back to `main`, and her commits are not in any log she knows how to read.

**[PAUSE]**

No, it is not gone. The commits exist, and are recoverable from the reflog. And Git told her so at the moment she left: it printed a warning, named the commits, and printed the command that would have kept them. This video is about the state she was in, why it is normal, and why one command is enough to keep work made there.

## INTRODUCTION

"Detached HEAD" is one of the most searched phrases in Git, and it sounds like damage. It is not an error. It is the second of the three contents of `.git/HEAD` from V022: a commit ID in place of a branch name.

In this video you enter the state on purpose, commit in it, leave it, lose sight of the commits, and bring them back. Then you see the ordinary operations that put you there without asking: checking out a tag or a remote-tracking branch, bisect, rebase, a clone of one release, a worktree from a tag.

## LEARNING OBJECTIVES

After this video you can:

1. Explain detached HEAD as HEAD holding a commit ID in place of a branch name.
2. List the ordinary operations that detach HEAD.
3. Make commits while detached, and keep them before leaving.
4. Recover commits left behind after switching away.

## CONCEPT

**In one sentence.** HEAD is detached when it holds a commit ID instead of a branch name; Git works normally, and new commits advance HEAD itself rather than any branch.

**Precisely.** The manual: in detached HEAD state "HEAD refers to a specific commit, as opposed to referring to a named branch", and a commit made there "is referenced only by HEAD". Git detaches HEAD whenever you ask for a commit that no branch names, and several commands do it for you.

Recall the state table from V019: `git commit` in detached HEAD sets HEAD to the new commit ID; there is no current branch, no branch moves, and one line is written in `logs/HEAD` only.

**What happens when you leave.** Commits made while detached are reachable only through HEAD. Once HEAD moves to a branch, no ref reaches them. They still exist as objects, and the reflog of HEAD still refers to them.

**Three ways to ask "which branch am I on".** Each answers differently when the answer is "none". `git symbolic-ref HEAD` fails with status 128. `git branch --show-current` prints nothing. `git rev-parse --abbrev-ref HEAD` prints the literal word `HEAD`. Scripts must handle all three.

**Where `git status` gets its words.** It reads the HEAD reflog backwards for the latest `checkout: moving from ... to X` entry. X is printed after "at" if HEAD still equals that entry's commit, and after "from" otherwise. With no such entry, as in a fresh clone, it prints `Not currently on any branch.` The textbook cites the Git 2.55.0 source for this.

**Every way it happens.**

**[ON SCREEN]** The table of section 7.7, one row at a time.

Checking out a tag. Checking out a commit by ID or by a relative name such as `HEAD~1`. Checking out a remote-tracking branch such as `origin/main`. `git bisect`: every step checks out a commit to test. `git rebase`, while it runs or is stopped: the rebase replays commits on a detached HEAD, and moves the branch only at the end; this is why an interrupted rebase looks like a detached HEAD: it is one. `git clone --branch <tag>`: a clone of one release, the shape of many deploy scripts. `git worktree add` with a tag or a commit. `git submodule update`: the default mode puts each submodule on a detached HEAD; that one is not run here. And a CI checkout.

**[ON SCREEN]** Lower third: **GitHub Actions**. On `pull_request` events the default checkout is a merge commit in detached HEAD, as GitHub's documentation describes. That is behavior of GitHub Actions, not of Git, and it is not run here.

**Keeping the work.** Three commands create a ref for the commit HEAD is on, as the manual lists them. `git switch -c <name>` attaches HEAD to a new branch there. `git branch <name>` creates the branch and leaves HEAD detached. `git tag <name>` creates a tag. All three are 🟢 SAFE: each adds a ref. After you have moved away, find the ID in `git reflog` first.

**When to use it, and when not.** Use it on purpose to look at an old state, to test a release, to try an experiment you may throw away. Do not leave it with commits you want and no name for them. The rule for people is one sentence: before you leave a detached HEAD with commits on it, give them a branch.

**How long recovery works.** The reflog is the safety net, and it expires: by default, entries not reachable from the current tip after 30 days, as you learned in V021. The lab configuration sets expiry to `never`.

## MENTAL MODEL

The textbook's analogy: reading a book with no bookmark in it. You can read any page, and even write notes on new pages, but when you put the book down, nothing marks where your notes are.

The analogy breaks because Git keeps a diary of where you have been, the reflog, and the notes can be found again through it.

So the contractor's two days are notes on unmarked pages. The diary says which pages. One bookmark, placed now, makes them part of the story again.

## DIAGRAM

**[DIAGRAM]** The diagram of section 7.7. Draw the left half first, then the right half.

```text
  attached                                  detached, two commits later

  HEAD -> refs/heads/main -> d27ae01          HEAD -> b23bce3 "Experiment: threshold 0.9"
                                                        |
  0381ff6---8c6d240---d27ae01   main          0381ff6---8c6d240---d27ae01   main
            tag v0.1.0                                  \
                                                         f678c98---b23bce3
```

On the left: HEAD points at a branch, and the branch points at a commit. Two hops. On the right: HEAD points at a commit directly. One hop. Two commits grow from the tagged commit `8c6d240`, and the only thing that names the newer one, `b23bce3`, is HEAD. There is no branch label on that lower line. If HEAD moves away, the line has no name at all.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch07/detached-head.sh`.

```bash
labs/run ch07/detached-head
```

Check out a tag. The script uses the older `git checkout` spelling here, which detaches without being asked; `git switch --detach` is the explicit form. Both are 🟢 SAFE.

<!-- snippet: ch07/detached-head/01-enter -->
```text
$ git checkout v0.1.0
Note: switching to 'v0.1.0'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 8c6d240 Add exact-match metric
$ cat .git/HEAD
8c6d240f33727a5e974eed76dadd337c298ed748
$ git status
HEAD detached at v0.1.0
nothing to commit, working tree clean
$ git branch
* (HEAD detached at v0.1.0)
  main
```
<!-- /snippet -->

Read the advice block: it is Git's own explanation, printed once per detach unless `advice.detachedHead` is false. Then the evidence: `.git/HEAD` holds a raw ID; `git status` says `HEAD detached at v0.1.0`; `git branch` lists a pseudo-entry instead of a current branch.

<!-- snippet: ch07/detached-head/02-no-current-branch -->
```text
$ git symbolic-ref HEAD
fatal: ref HEAD is not a symbolic ref
[exit status: 128]
$ git branch --show-current
$ git rev-parse --abbrev-ref HEAD
HEAD
```
<!-- /snippet -->

The three answers to "which branch am I on": an error with status 128, an empty line, and the literal `HEAD`.

Now two commits. Predict: which ref moves?

<!-- snippet: ch07/detached-head/03-commit -->
```text
$ printf 'judge_model: judge-v1\nthreshold: 0.8\n' > configs/eval.yaml
$ git commit -am "Experiment: stricter judge threshold"
[detached HEAD f678c98] Experiment: stricter judge threshold
 1 file changed, 1 insertion(+), 1 deletion(-)
$ printf 'judge_model: judge-v1\nthreshold: 0.9\n' > configs/eval.yaml
$ git commit -am "Experiment: threshold 0.9"
[detached HEAD b23bce3] Experiment: threshold 0.9
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status
HEAD detached from v0.1.0
nothing to commit, working tree clean
$ git log --oneline --graph --all
* b23bce3 Experiment: threshold 0.9
* f678c98 Experiment: stricter judge threshold
| * d27ae01 Add batch runner
|/  
* 8c6d240 Add exact-match metric
* 0381ff6 Add README and eval config
```
<!-- /snippet -->

No branch. The summary line says `[detached HEAD f678c98]`, then `[detached HEAD b23bce3]`. The status line now says `HEAD detached from v0.1.0`: "at" became "from", because HEAD has moved since it was detached. `git log --all` shows the new commits, because `--all` includes HEAD.

Now leave. Before the output: what do you expect Git to print, and will `git log --all` still show the two commits afterwards?

**[PAUSE]**

<!-- snippet: ch07/detached-head/04-leave -->
```text
$ git switch main
Warning: you are leaving 2 commits behind, not connected to
any of your branches:

  b23bce3 Experiment: threshold 0.9
  f678c98 Experiment: stricter judge threshold

If you want to keep them by creating a new branch, this may be a good time
to do so with:

 git branch <new-branch-name> b23bce3

Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git log --oneline --graph --all
* d27ae01 Add batch runner
* 8c6d240 Add exact-match metric
* 0381ff6 Add README and eval config
```
<!-- /snippet -->

Read the warning aloud. "You are leaving 2 commits behind, not connected to any of your branches." It names them: `b23bce3` and `f678c98`. And it prints the command that keeps them: `git branch`, a new branch name, and the ID. Then `git log --all` no longer shows them: no ref reaches them.

<!-- snippet: ch07/detached-head/05-keep -->
```text
$ git branch experiment/judge-threshold b23bce3
$ git log --oneline --graph --all
* b23bce3 Experiment: threshold 0.9
* f678c98 Experiment: stricter judge threshold
| * d27ae01 Add batch runner
|/  
* 8c6d240 Add exact-match metric
* 0381ff6 Add README and eval config
```
<!-- /snippet -->

`git branch experiment/judge-threshold b23bce3` 🟢 SAFE. The graph shows both commits again. One command. If the warning has scrolled away, `git reflog` has the ID: look for the `commit:` lines above the last `checkout: moving from` an ID to a branch.

<!-- snippet: ch07/detached-head/06-remote-and-bisect -->
```text
$ git switch --detach origin/main
HEAD is now at d27ae01 Add batch runner
$ git status
HEAD detached at origin/main
nothing to commit, working tree clean
$ git switch -q main
$ git bisect start HEAD HEAD~2
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[8c6d240f33727a5e974eed76dadd337c298ed748] Add exact-match metric
$ git status
HEAD detached at 8c6d240
You are currently bisecting, started from branch 'main'.
  (use "git bisect reset" to get back to the original branch)

nothing to commit, working tree clean
$ git bisect reset
Previous HEAD position was 8c6d240 Add exact-match metric
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```
<!-- /snippet -->

Two more ways in. `git switch --detach origin/main`: a remote-tracking branch is not a local branch, so standing on it means detached. And `git bisect`, which checks out a commit to test.

<!-- snippet: ch07/detached-head/07-rebase -->
```text
$ git rebase -i HEAD~1
--- todo list as Git opened it (comment lines removed) ---
pick d27ae01 # Add batch runner
--- todo list as saved ---
edit d27ae01 # Add batch runner
Rebasing (1/1)
Stopped at d27ae01...  # Add batch runner
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
$ git branch
* (no branch, rebasing main)
  experiment/judge-threshold
  main
$ cat .git/HEAD
d27ae01097b4cc8528d18538aae3da2c83a38984
$ git rebase --abort
$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```
<!-- /snippet -->

During a stopped rebase, `git branch` prints `(no branch, rebasing main)`, and `.git/HEAD` holds an ID. The rebase moves `main` only at the end.

**[TERMINAL]** Caption bar: `labs/ch07/detached-ways.sh`.

```bash
labs/run ch07/detached-ways
```

<!-- snippet: ch07/detached-ways/01-by-commit -->
```text
$ git switch --detach HEAD~1
HEAD is now at 8c6d240 Add exact-match metric
$ git status
HEAD detached at 8c6d240
nothing to commit, working tree clean
$ git -c advice.detachedHead=false checkout 0381ff6
Previous HEAD position was 8c6d240 Add exact-match metric
HEAD is now at 0381ff6 Add README and eval config
$ git status
HEAD detached at 0381ff6
nothing to commit, working tree clean
$ git switch main
Previous HEAD position was 0381ff6 Add README and eval config
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```
<!-- /snippet -->

By relative name and by ID.

<!-- snippet: ch07/detached-ways/02-clone-at-a-tag -->
```text
# A deploy script that clones one release. The detached-HEAD advice is switched off to keep the transcript short.
$ git -c advice.detachedHead=false clone -q --branch v0.1.0 ../origin.git ../deploy
$ cat ../deploy/.git/HEAD
8c6d240f33727a5e974eed76dadd337c298ed748
$ git -C ../deploy status
Not currently on any branch.
nothing to commit, working tree clean
$ git -C ../deploy branch -a
* (no branch)
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
```
<!-- /snippet -->

A deploy script that clones one release with `--branch v0.1.0`. The clone has no local branch at all. `git status` prints `Not currently on any branch.`, because the fresh clone's HEAD reflog has no `checkout:` entry. A deploy script that commits a generated file in such a clone commits onto nothing.

<!-- snippet: ch07/detached-ways/03-worktree-from-a-tag -->
```text
$ git worktree add ../evalkit-v0.1.0 v0.1.0
Preparing worktree (detached HEAD 8c6d240)
HEAD is now at 8c6d240 Add exact-match metric
$ git -C ../evalkit-v0.1.0 status
Not currently on any branch.
nothing to commit, working tree clean
$ git branch
* main
$ git worktree remove ../evalkit-v0.1.0
```
<!-- /snippet -->

And a linked worktree created from a tag: detached, while the main working tree stays on `main`.

## COMMON MISTAKES

1. **Commits "disappeared" after switching branches.** Root cause: they were made in detached HEAD and were reachable only through HEAD; `git reflog` shows them, and `git branch <name> <id>` brings them back.
2. **Treating the detached-HEAD message as an error to make go away.** Root cause: it is a normal state that Git itself uses for bisect and rebase; the message is advice.
3. **A script that calls `git branch --show-current` fails in CI.** Root cause: CI jobs, deploy checkouts and submodules are in detached HEAD, and the command prints nothing there.
4. **`git push` with no refspec from a deploy checkout does nothing useful.** Root cause: no branch is current; use `git rev-parse HEAD` for the commit, and name the branch explicitly when pushing.
5. **Assuming an interrupted rebase broke the branch.** Root cause: a rebase runs on a detached HEAD and moves the branch only at the end.

## PRODUCTION EXAMPLE

The textbook states the production rule in one paragraph. Detached HEAD is the normal state of a CI job, a deploy checkout and a submodule, so a script that assumes a current branch fails in exactly those places. An ML team's release job clones the repository at a tag, generates a model card, commits it, and pushes. The commit succeeds, onto nothing. The push, which has no refspec, has no branch to push. The repaired job uses `git rev-parse HEAD` to record the commit it built from, creates a branch with `git switch -c` before committing, and names that branch in the push.

## PRACTICE EXERCISE

Do Lab 4.2, "Detached HEAD rescue", in [`lab-manual/m04-refs-branches-head.md`](../../lab-manual/m04-refs-branches-head.md).

Before you leave the detached HEAD in the lab, write down what you expect in three places afterwards: `git log --all`, `git reflog`, and `git fsck`. Then switch away and compare.

## INTERVIEW QUESTION

Q98: "A colleague's two days of commits are "gone" after she checked out a tag and later switched back to `main`. Walk through the recovery and explain why it works."

Answer aloud. A strong answer starts with the state of HEAD after the checkout and says which ref her commits moved. It names where the IDs can still be found and the one command that makes them reachable, explains why the objects were never in danger at that point, and says what the time limit is. Mention what Git printed when she switched away.

## RECAP

You should now be able to say: detached HEAD means `.git/HEAD` holds a commit ID instead of a branch name. It is a normal state, entered by checking out a tag, a commit or a remote-tracking branch, and by bisect, rebase, a clone at a tag, a worktree from a tag, submodules and CI checkouts. Commits made there advance HEAD only. When I switch away, Git names the commits and prints the command that keeps them; afterwards the HEAD reflog still has their IDs. Keeping the work is one command: create a branch.

## HOMEWORK

- Read section 7.7 of [Chapter 7](../../textbook/ch07-branches.md).
- Challenge: Exercise 4.4, Level 2, "a commit made while HEAD was detached", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
