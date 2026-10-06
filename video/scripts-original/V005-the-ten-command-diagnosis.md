# V005: The ten-command diagnosis

- **Part.** 0: Orientation
- **Module.** 0
- **Planned minutes.** 22
- **Prerequisites.** V004
- **Textbook sections.** [Chapter 1: Fundamentals](../../textbook/ch01-fundamentals.md), section 1.11 (and the edge case about `git status` in section 1.14)
- **Demo scripts.** `labs/ch01/diagnosis.sh` (snippets `01-status` to `10-ls-files`)

## HOOK

**[ON SCREEN]** "The evaluation job in CI fails with a timeout after 60 seconds."

Here is a real-looking report. The evaluation job in CI fails with a timeout after 60 seconds. The commit "Raise eval timeout to 120s" is on `main`. On the author's laptop, the same test passes.

You already have a theory. Everybody does. Maybe it was not pushed. Maybe CI caches something. Maybe it is on another branch.

**[PAUSE]**

Hold the theory. People under pressure skip the one command that would have shown the cause, because they think they already know the answer. The remedy is a ritual: the same commands, in the same order, every time, including when you think you know.

## INTRODUCTION

In the last video you learned the eleven steps of the root-cause framework. The third step is "collect evidence", and it always starts the same way: with the ten-command diagnosis. `git diff` is run twice, once for each of its two comparisons, so you type eleven lines.

In this video you run those eleven lines on a repository with a real problem. For each one I state the question first, then show the output, then say what it rules out. We will not solve the problem today. Today you collect the evidence and resist the temptation to fix. The solution is the next video.

The repository is `rag-eval`, the one you created in V003, some days later. A bare repository on disk plays the server.

## LEARNING OBJECTIVES

After this video you can:

1. Run the ten-command diagnosis in order from memory.
2. Say for each command which question about the repository it answers.
3. Explain why the ritual is run before any state-changing command.
4. Name the commands of the ritual that can write to disk, and why that is harmless.

## CONCEPT

**State before hypothesis.** The framework says: understand the state, then form hypotheses. The ritual is how you get the state. It is ordered from the outside in: where am I, what do my branches follow, which other repositories exist, what does the history look like, what happened here recently, what does a name resolve to, what is in one commit, what is uncommitted, which settings are in force, and what does Git track.

Each command answers one question.

**[ON SCREEN]** The table of section 1.11, one row at a time.

`git status`: the current branch, its relation to its upstream as of the last exchange, and the staged, unstaged and untracked paths.

`git branch -vv`: each local branch, the commit it points at, its upstream, and how far ahead or behind it is.

`git remote -v`: the other repositories this one exchanges data with.

`git log --graph --decorate --oneline --all`: the shape of the history, and where every name points.

`git reflog`: what happened to HEAD in this repository, newest first.

`git rev-parse`: the exact object ID behind a name; the current branch; the repository root.

`git show`: one commit, with its author, date, message and change.

`git diff`: working tree against index, which is what is not staged.

`git diff --cached`: index against the last commit, which is what the next commit would record.

`git config list --show-origin --show-scope`: every setting in effect and the file it comes from.

`git ls-files`: the paths in the index, which are the tracked files.

**Why before any state-changing command.** Two reasons, both from the framework. The evidence you collect describes the state that produced the symptom, and a state-changing command replaces that state with another. And a fix chosen before the state is understood is a guess with side effects.

**Read-only, with one footnote.** All eleven commands carry the label 🟢 SAFE: they read state. The footnote is in the textbook's list of dangerous edge cases: `git status` can write. By default it refreshes the cached file information in `.git/index` and writes the file back. That never changes history. It matters in two situations. When you investigate a damaged repository, work on a copy. And in scripts that run in the background, use `git --no-optional-locks status`, as the git-status manual advises.

**When the ritual is not enough.** The ten commands describe one clone. They say nothing certain about the server until you fetch, and nothing at all about GitHub objects such as pull requests, rulesets and check results. `origin/main` in these outputs is your cached copy, as of your last exchange.

## MENTAL MODEL

Think of a pilot's checklist. The pilot does not run it because flying is unfamiliar. The pilot runs it because the one item you skip on the day you are in a hurry is the one that matters.

The analogy breaks in a useful place. A checklist confirms that things are as expected. The ritual has no expectation. You are not ticking boxes; you are reading output, and every line of output either supports a hypothesis or removes one. So each time, say what the output rules out.

A second way to hold it: each command reads from a place. Working tree, index, refs, reflog, objects, configuration. When you know which place a command reads, you know what it cannot tell you.

## DIAGRAM

**[DIAGRAM]** A three-column table, empty at first. One row is filled after each snippet of the demo.

```text
 command                                      question it answers                    place it reads
 -------------------------------------------  -------------------------------------  ---------------------------------
 git status                                   where am I, what is uncommitted?       HEAD, index, working tree
 git branch -vv                               what do the branches follow?           refs, configuration
 git remote -v                                which other repositories?              configuration
 git log --graph --decorate --oneline --all   what does the history look like?       objects, refs
 git reflog                                   what happened here, in which order?    reflog
 git rev-parse                                which exact object is this name?       refs
 git show                                     what is in this commit?                objects
 git diff                                     what is not staged?                    working tree, index
 git diff --cached                            what would the next commit record?     index, objects
 git config list --show-origin --show-scope   which settings are in force?           configuration
 git ls-files                                 what does Git track?                   index
```

Read the right-hand column from top to bottom when the table is complete. Between them, the eleven lines touch every place in the repository. That is why the ritual works without knowing what the problem is.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch01/diagnosis.sh`.

```bash
labs/run ch01/diagnosis
```

Keep the symptom on screen: CI times out at 60 seconds, the fix commit is on `main`, the test passes on the laptop.

**1. Where am I, and what is uncommitted?**

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

You are on `main`. It matches `origin/main` as of the last exchange with the server. One tracked file is modified and not staged, `eval/runner.py`, and one file is untracked, `run.log`. What this rules out: we are not on some other branch by accident.

**2. Which branches exist, and what do they follow?**

<!-- snippet: ch01/diagnosis/02-branch -->
```text
$ git branch -vv
  feature/cache 1c96817 Cache embeddings between runs
* main          f29df3b [origin/main] Raise eval timeout to 120s
```
<!-- /snippet -->

The star marks the current branch. `[origin/main]` is its upstream. No "ahead" or "behind" appears, so the last commit has been pushed. `feature/cache` has no upstream: it exists only here. What this rules out, as far as this clone knows: "it was committed and not pushed".

**3. Which other repositories does this one talk to?**

<!-- snippet: ch01/diagnosis/03-remote -->
```text
$ git remote -v
origin	$LAB/ch01/diagnosis/origin.git (fetch)
origin	$LAB/ch01/diagnosis/origin.git (push)
```
<!-- /snippet -->

One remote named `origin`, with the same address for fetching and pushing. In your own projects this is a GitHub URL. What this rules out: a second remote that CI might be building from.

**4. What does the history look like?**

Predict: how many commits, and on how many lines?

<!-- snippet: ch01/diagnosis/04-log -->
```text
$ git log --graph --decorate --oneline --all
* f29df3b (HEAD -> main, origin/main) Raise eval timeout to 120s
| * 1c96817 (feature/cache) Cache embeddings between runs
|/  
* 25fbbb0 Add evaluation runner and config
```
<!-- /snippet -->

`--all` includes every branch, `--graph` draws the lines between commits, and `--decorate` prints the names that point at each commit. `HEAD`, `main` and `origin/main` all sit on `f29df3b`. `feature/cache` is one commit, `1c96817`, off to the side.

**5. What was done in this repository, and in which order?**

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

The reflog lists every position HEAD has had, newest first. It is a local journal that no other clone has. The latest action here was the commit under suspicion. Nothing after it: no reset, no switch.

**6. Which exact object does a name stand for?**

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

**7. What is in this commit?**

Predict before you look: the commit is called "Raise eval timeout to 120s". Which files does it change?

**[PAUSE]**

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

The commit changes one file, `configs/eval.yaml`. With `--stat` you get the list of changed files; without it, the full difference. Keep that line in mind and do not act on it yet.

**8 and 9. What is not committed?**

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

`git diff` compares the working tree with the index: a change to `MAX_TIMEOUT_S` in `eval/runner.py` exists on disk and is not staged. `git diff --cached` compares the index with the last commit and prints nothing: nothing is staged. `--staged` is a synonym of `--cached`. Silence is output too. Here it rules out "the change is staged and waiting".

**10. Which settings are in effect?**

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

Identity, the remote's address, and the two `branch.main.*` lines that make `origin/main` the upstream of `main`. When a command behaves differently on two machines, this listing is where the difference shows. And there are the two `gc.reflogexpire` lines of the sandbox that V001 explained.

**11. What does Git track?**

<!-- snippet: ch01/diagnosis/10-ls-files -->
```text
$ git ls-files
README.md
configs/eval.yaml
eval/runner.py
```
<!-- /snippet -->

`eval/runner.py` is tracked. `run.log` is absent, which matches "untracked" in the status output.

**[ON SCREEN]** The completed three-column table.

Eleven lines, and nothing in the repository has changed. Now, and only now, are you allowed a theory. You probably have a sharper one than you had at the start. Write it down, and write at least two others beside it. The next video tests them.

## COMMON MISTAKES

1. **Skipping the ritual because the answer seems known.** Root cause: pressure; the ritual exists because people under pressure skip the one command that would have shown the cause.
2. **Reading "up to date with 'origin/main'" as a statement about the server now.** Root cause: `git status` compares with a cached copy, as of the last exchange; the ten commands say nothing certain about the server until you fetch.
3. **Running only `git diff` and concluding that nothing is pending.** Root cause: `git diff` has two comparisons; without `--cached` it shows working tree against index, not index against the last commit.
4. **Trusting a branch name where an ID is needed.** Root cause: names can be ambiguous and can point at different commits in different places; `git rev-parse` gives the object ID.
5. **Calling the ritual strictly read-only on a damaged repository.** Root cause: `git status` refreshes cached file information in `.git/index` and writes the file back; on a damaged repository, work on a copy.

## PRODUCTION EXAMPLE

A data-pipeline team has a rule for incidents: the first message in the incident thread is the pasted output of the ritual, before any opinion. One week, two engineers disagree about whether a hotfix reached the server. One says yes, the other says the deployment does not show it. The pasted `git branch -vv` settles the local half in one line: the branch has an upstream, and the output shows whether it is ahead. The `git config list --show-origin --show-scope` output explains why one engineer's push behaved differently from the other's: a setting from a file only one of them had. Neither fact needed a theory. Both were on the page because the rule put them there. And the team knows the limit of the page: it describes one clone, so the next step for the server's state is a fetch, and for the deployment it is a look at the platform.

## PRACTICE EXERCISE

Lab 35.1, "The ten-command diagnosis on three repositories", in [`lab-manual/m35-diagnosis-method.md`](../../lab-manual/m35-diagnosis-method.md) is the full drill, later in the course. For now, do Exercise 1.3, Level 1, "the diagnosis ritual on a small state", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md) again, this time from memory, and time it.

Before each command, say aloud which question it answers and what you expect it to print for the state you built. The exercise is done when you can do that without looking at the card.

## INTERVIEW QUESTION

Q40: "The course's ten-command diagnosis ritual is meant to be read-only. Which of its commands can write to disk, and why does that matter when you investigate a damaged repository?"

Answer aloud. A strong answer separates "does not change history" from "does not write a byte". It names what is written and where, says why that is harmless in ordinary work, and then says what you do differently when the repository itself is the evidence. Mention the form of the command that the manual advises for background scripts.

## RECAP

You should now be able to say: before I form a hypothesis, I run the same eleven lines in the same order. `git status`, `git branch -vv` and `git remote -v` tell me where I am and what I am connected to. `git log --graph --decorate --oneline --all` and `git reflog` tell me the shape of the history and what happened here. `git rev-parse` and `git show` tell me exactly which object a name means and what is in it. The two `git diff` commands tell me what is unstaged and what is staged. `git config list --show-origin --show-scope` and `git ls-files` tell me which settings are in force and what Git tracks. All of this describes one clone, and nothing certain about the server until I fetch.

## HOMEWORK

- Read section 1.11 of [Chapter 1](../../textbook/ch01-fundamentals.md).
- Write the eleven commands on a card, and run them on three repositories of your own without changing anything.
- Challenge: Exercise 1.9, Level 4, "git log says there are no commits", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
