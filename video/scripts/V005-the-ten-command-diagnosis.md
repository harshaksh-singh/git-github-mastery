# V005: The ten-command diagnosis

- **Part.** 0: Orientation
- **Module.** 0
- **Planned minutes.** 22
- **Prerequisites.** V004
- **Textbook sections.** [Chapter 1: Fundamentals](../../textbook/ch01-fundamentals.md), section 1.11 (and the edge case about `git status` in section 1.14)
- **Demo scripts.** `labs/ch01/diagnosis.sh` (snippets `01-status` to `10-ls-files`)

## HOOK

**[ON SCREEN]** "The evaluation job in CI fails with a timeout after 60 seconds."

Here's a real-looking report. The evaluation job in CI, the automated system that tests every change, fails with a timeout after 60 seconds. The commit "Raise eval timeout to 120s" is on `main`, the team's main branch. On the author's laptop, the same test passes.

You already have a theory. Everybody does. So make it a quiz with three options. One: it was never pushed. Two: CI caches something. Three: it's on another branch. Which would you bet on? Say it out loud.

**[PAUSE]**

Hold the theory. People under pressure skip the one command that would have shown the cause, because they think they already know the answer. The remedy is a ritual: the same commands, in the same order, every time, including when you think you know.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you learned the eleven steps of the root-cause framework. The third step is "collect evidence", and it always starts the same way: with the ten-command diagnosis. `git diff` is run twice, once for each of its two comparisons, so you type eleven lines.

In this video you run those eleven lines on a repository with a real problem. For each one I state the question first, then show the output, then say what it rules out. We won't solve the problem today. Today you collect the evidence and resist the temptation to fix. The solution is the next video.

**[ANIMATION]** remotes: solo fetch note=a_bare_repository_on_disk title=One_clone,_one_server

**[ANIMATION]** step: setup

The repository is `rag-eval`, the one you created in video 3, some days later. A bare repository on disk, one with no checked-out files, plays the server.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Run the ten-command diagnosis in order from memory.
2. Say for each command which question about the repository it answers.
3. Explain why the ritual is run before any state-changing command.
4. Name the commands of the ritual that can write to disk, and why that is harmless.

## CONCEPT

**State before hypothesis.** The framework says: understand the state, then form hypotheses. The ritual is how you get the state. It's ordered from the outside in. Where am I? What do my branches follow? Which other repositories exist? What does the history look like? What happened here recently? What does a name resolve to? What's in one commit? What's uncommitted? Which settings are in force? And what does Git track?

Each command answers one question.

**[ON SCREEN]** The table of section 1.11, one row at a time.

`git status`: the current branch, its relation to its upstream as of the last exchange, and the staged, unstaged and untracked paths. Staged means added to the index, and untracked means the file has no entry there.

`git branch -vv`: each local branch, the commit it points at, its upstream, and how far ahead or behind it is.

`git remote -v`: the other repositories this one exchanges data with.

`git log --graph --decorate --oneline --all`: the shape of the history, and where every name points.

`git reflog`: what happened to HEAD in this repository, newest first.

`git rev-parse`: the exact object ID behind a name, the current branch, and the repository root.

`git show`: one commit, with its author, date, message and change.

`git diff`: working tree against index, which is what is not staged.

`git diff --cached`: index against the last commit, which is what the next commit would record.

`git config list --show-origin --show-scope`: every setting in effect and the file it comes from.

`git ls-files`: the paths in the index, which are the tracked files.

**Why before any state-changing command.** Two reasons, both from the framework. The evidence you collect describes the state that produced the symptom, and a state-changing command replaces that state with another. And a fix chosen before the state is understood is a guess with side effects.

**Read-only, with one footnote.** All eleven commands carry the label 🟢 SAFE: they read state. The footnote is in the textbook's list of dangerous edge cases: `git status` can write. By default it refreshes the cached file information in the index file and writes the file back. That never changes history. It matters in two situations. When you investigate a damaged repository, work on a copy. And in scripts that run in the background, use `git --no-optional-locks status`, as the git-status manual advises.

**[ANIMATION]** end

**[ANIMATION]** step: fetch

**When the ritual is not enough.** The ten commands describe one clone. A teammate pushes, and your clone hasn't heard. So the commands say nothing certain about the server until you fetch, and nothing at all about GitHub objects such as pull requests, rulesets and check results. `origin/main` in these outputs is your cached copy, as of your last exchange.

## MENTAL MODEL

Think of a pilot's checklist. The pilot doesn't run it because flying is unfamiliar. The pilot runs it because the one item you skip on the day you're in a hurry is the one that matters.

The analogy breaks in a useful place. A checklist confirms that things are as expected. The ritual has no expectation. You're not ticking boxes. You're reading output, and every line of output either supports a hypothesis or removes one. So each time, say what the output rules out.

**[ANIMATION]** trees: setup, edit file=eval/runner.py

**[ANIMATION]** step: setup

A second way to hold it: each command reads from a place. Working tree, index, refs, reflog, objects, configuration. When you know which place a command reads, you know what it can't tell you.

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

Read the right-hand column from top to bottom when the table is complete. Between them, the eleven lines touch every place in the repository. That's why the ritual works without knowing what the problem is.

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

You're on `main`. It matches `origin/main` as of the last exchange with the server. One tracked file is modified and not staged, `eval/runner.py`, and one file is untracked, `run.log`. What this rules out: we're not on some other branch by accident. If option three was your bet, the very first command has retired it.

**2. Which branches exist, and what do they follow?**

<!-- snippet: ch01/diagnosis/02-branch -->
```text
$ git branch -vv
  feature/cache 1c96817 Cache embeddings between runs
* main          f29df3b [origin/main] Raise eval timeout to 120s
```
<!-- /snippet -->

The star marks the current branch. `[origin/main]` is its upstream. No "ahead" or "behind" appears, so the last commit has been pushed. `feature/cache` has no upstream: it exists only here. What this rules out, as far as this clone knows: "it was committed and not pushed". So option one is gone too.

**3. Which other repositories does this one talk to?**

<!-- snippet: ch01/diagnosis/03-remote -->
```text
$ git remote -v
origin	$LAB/ch01/diagnosis/origin.git (fetch)
origin	$LAB/ch01/diagnosis/origin.git (push)
```
<!-- /snippet -->

One remote named `origin`, with the same address for fetching and pushing. In your own projects this is a GitHub URL. What this rules out: a second remote that CI might be building from.

Try it now, thirty seconds, from memory. Name the three commands so far, and the question each one answers. Say your answer out loud.

**[PAUSE]**

`git status`: where am I, and what's uncommitted? `git branch -vv`: what do the branches follow? `git remote -v`: which other repositories?

**4. What does the history look like?**

Predict: how many commits, and on how many lines? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch01/diagnosis/04-log -->
```text
$ git log --graph --decorate --oneline --all
* f29df3b (HEAD -> main, origin/main) Raise eval timeout to 120s
| * 1c96817 (feature/cache) Cache embeddings between runs
|/  
* 25fbbb0 Add evaluation runner and config
```
<!-- /snippet -->

`--all` includes every branch, `--graph` draws the lines between commits, and `--decorate` prints the names that point at each commit. Three commits, on two lines.

**[ANIMATION]** graph: 25fbbb0-f29df3b main origin/main; 25fbbb0-1c96817 feature/cache; HEAD=main

Here's the same history as a picture: the commits first, then the names. `HEAD`, `main` and `origin/main` all sit on `f29df3b`. `feature/cache` is one commit, `1c96817`, off to the side.

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

The reflog lists every position HEAD has had, newest first. HEAD is the name that says where you are now. The reflog is a local journal that no other clone has. The latest action here was the commit under suspicion. Nothing after it: no reset, no switch.

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

Names can be ambiguous. Object IDs can't. `HEAD` and `origin/main` resolve to the same ID. `--abbrev-ref HEAD` prints the current branch, and `--show-toplevel` prints the root of the working tree, which settles whether you're in the repository you think you're in.

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

The commit changes one file, `configs/eval.yaml`. With `--stat` you get the list of changed files, and without it, the full difference. Keep that line in mind, and don't act on it yet. I know it's tempting.

**8 and 9. What is not committed?**

Quick quiz first. Plain `git diff` compares which two places? Option one: the working tree and the index. Option two: the index and the last commit. Say it out loud.

**[PAUSE]**

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

Option one. `git diff` compares the working tree with the index: a change to `MAX_TIMEOUT_S` in `eval/runner.py` exists on disk and is not staged. `git diff --cached` compares the index with the last commit and prints nothing: nothing is staged. `--staged` is a synonym of `--cached`.

**[ANIMATION]** step: edit

Here it is in the three places. The edit is in the working tree only, and the index and the last commit still agree. Silence is output too. Here it rules out "the change is staged and waiting".

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

Identity, the remote's address, and the two `branch.main.*` lines that make `origin/main` the upstream of `main`. When a command behaves differently on two machines, this listing is where the difference shows. And there are the two `gc.reflogexpire` lines of the sandbox that video 1 explained.

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

**Eleven lines, and nothing in the repository has changed.** Now, and only now, are you allowed a theory. You probably have a sharper one than the bet you made at the start. Write it down, and write at least two others beside it. The next video tests them.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Skipping the ritual because the answer seems known.** Root cause: pressure; the ritual exists because people under pressure skip the one command that would have shown the cause.
2. **Reading "up to date with 'origin/main'" as a statement about the server now.** Root cause: `git status` compares with a cached copy, as of the last exchange; the ten commands say nothing certain about the server until you fetch.
3. **Running only `git diff` and concluding that nothing is pending.** Root cause: `git diff` has two comparisons; without `--cached` it shows working tree against index, not index against the last commit.
4. **Trusting a branch name where an ID is needed.** Root cause: names can be ambiguous and can point at different commits in different places; `git rev-parse` gives the object ID.
5. **Calling the ritual strictly read-only on a damaged repository.** Root cause: `git status` refreshes cached file information in `.git/index` and writes the file back; on a damaged repository, work on a copy.

## PRODUCTION EXAMPLE

Now, out of the lab. A data-pipeline team has a rule for incidents: the first message in the incident thread is the pasted output of the ritual, before any opinion. One week, two engineers disagree about whether a hotfix reached the server. One says yes, the other says the deployment doesn't show it. The pasted `git branch -vv` settles the local half in one line: the branch has an upstream, and the output shows whether it's ahead. The `git config list --show-origin --show-scope` output explains why one engineer's push behaved differently from the other's: a setting from a file only one of them had. Neither fact needed a theory. Both were on the page because the rule put them there.

**[ANIMATION]** step: fetch

And the team knows the limit of the page: it describes one clone, so the next step for the server's state is a fetch, and for the deployment it's a look at the platform.

## PRACTICE EXERCISE

Your turn. Lab 35.1, "The ten-command diagnosis on three repositories", in [`lab-manual/m35-diagnosis-method.md`](../../lab-manual/m35-diagnosis-method.md) is the full drill, later in the course. For now, do Exercise 1.3, Level 1, "the diagnosis ritual on a small state", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md) again, this time from memory, and time it.

Before each command, say out loud which question it answers and what you expect it to print for the state you built. The exercise is done when you can do that without looking at the card.

## INTERVIEW QUESTION

Q40: "The course's ten-command diagnosis ritual is meant to be read-only. Which of its commands can write to disk, and why does that matter when you investigate a damaged repository?"

**[PAUSE]**

Answer out loud. A strong answer separates "does not change history" from "does not write a byte". It names what is written and where, says why that is harmless in ordinary work, and then says what you do differently when the repository itself is the evidence. Mention the form of the command that the manual advises for background scripts.

## RECAP

Let's land this. You should now be able to say: before I form a hypothesis, I run the same eleven lines in the same order. `git status`, `git branch -vv` and `git remote -v` tell me where I am and what I am connected to. `git log --graph --decorate --oneline --all` and `git reflog` tell me the shape of the history and what happened here. `git rev-parse` and `git show` tell me exactly which object a name means and what is in it. The two `git diff` commands tell me what is unstaged and what is staged. `git config list --show-origin --show-scope` and `git ls-files` tell me which settings are in force and what Git tracks.

**[ANIMATION]** step: fetch

All of this describes one clone, and nothing certain about the server until I fetch.

## HOMEWORK

- Read section 1.11 of [Chapter 1](../../textbook/ch01-fundamentals.md).
- Write the eleven commands on a card, and run them on three repositories of your own without changing anything.
- Challenge: Exercise 1.9, Level 4, "git log says there are no commits", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Eleven lines, and a real repository read from end to end. Put them on a card before the next video. Next time, a worked example: the fix that was committed and did not ship. Until then, look at the state first and type second. See you in the next one.
