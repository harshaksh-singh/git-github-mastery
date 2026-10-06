# V001: How this course works: the book, the lab sandbox and the fixed clock

- **Part.** 0: Orientation
- **Module.** 0
- **Planned minutes.** 16
- **Prerequisites.** None
- **Textbook sections.** [Chapter 1: Fundamentals](../../textbook/ch01-fundamentals.md), sections 1.1, 1.7 and 1.8
- **Demo scripts.** `labs/ch00/smoke-test.sh`, `labs/ch01/sandbox.sh`

## HOOK

**[ON SCREEN]** Title card: "A deploy pipeline goes red on a Friday evening."

A deploy pipeline goes red on a Friday evening. The engineer on call says, "The fix is committed. Look, here's the commit." The pipeline runs again, and fails again, on the same line. Then your CTO asks three calm questions. What exactly is in the commit that the pipeline built? Where does that commit exist right now: on the laptop, on the server, or on both? And what's the smallest change that makes the main branch correct, and how will we know it worked?

**[PAUSE]**

**[ANIMATION]** graph: A-B-C main; C-D fix/deploy; HEAD=fix/deploy

Notice something? None of those is a question about commands. Each one is a question about state: which bytes Git recorded, which names point at them, and which machine holds them. An engineer who knows fifty commands and can't answer those questions will try things until something appears to work. An engineer who can answer them needs about ten read-only commands and a method. This course teaches the second engineer.

## INTRODUCTION

Welcome to Git and GitHub Deep Mastery. Pull up a chair. This first video has no Git theory. It sets up three things that every later video depends on: the way the book and the videos are written, the lab sandbox where you'll type every command, and the fixed clock that makes the output on my screen equal to the output in your book.

The goal of the course fits in one sentence. You'll learn to diagnose a Git or GitHub problem from first principles, choose the lowest-risk fix, verify that it worked, and prevent it from happening silently again. Four verbs: diagnose, choose, verify, prevent. Notice what's not on the list? Knowing commands.

By the end of these sixteen minutes you'll have a working sandbox, and you'll know that nothing in this course reads or writes your real Git configuration. You'll also be able to say why the commit ID on my screen is the commit ID in your textbook. Hold that thought until the end of the demo.

## LEARNING OBJECTIVES

Here's that promise as a checklist.

**[ON SCREEN]** The five objectives, shown one at a time.

After this video you can:

1. State the goal of the course in one sentence: diagnose from first principles, choose the lowest-risk fix, verify, prevent.
2. Open an isolated lab shell with `labs/shell`, replay a demo with `labs/run`, and check a chapter with `labs/verify-all.sh`.
3. Explain why the lab configuration is isolated, and name the variable that redirects the global configuration file.
4. Explain why replays pin the clock, and why the sandbox sets the two `gc.reflogExpire` settings to `never`.
5. Give the meaning of the three risk labels and the five questions asked before a dangerous command.

## CONCEPT

So that's the destination. Now, why is the course built the way it is?

**The ladder.** Every important concept in the textbook is taught on the same ladder, and these videos climb it too. In one sentence: the plain explanation. Analogy: one comparison, and the place where it breaks. Precisely: the technical statement, with the correct terms. Inside the dot git folder: which files change on disk. See it: a real transcript. Picture: a diagram. In production: a realistic case from a backend team or an AI and ML team. The ladder goes from plain words, down to files on disk, and back up to a real team. When you can walk a concept down and up that ladder yourself, you own it.

**Transcripts are real.** Whenever you see terminal output in a text block in the book, or on my screen, it's real output. A script in the labs folder produced it, and a tool inserted it into the page. Nobody typed it by hand. In those transcripts, `$LAB` stands for the lab root, which is the git-mastery-labs folder in your home directory, unless you set the variable `GIT_MASTERY_LABS`. A line in square brackets that says exit status and a number is the exit status of the command above it. And a line that starts with a hash sign is a comment written by the script.

**Three tools.** You run all three from the course folder, the directory that contains the textbook, labs and lab-manual folders.

**[ON SCREEN]** The table of three tools from section 1.7.

The first is `labs/shell m00`. It opens your shell in the hands-on directory for m00, under the lab root, with an isolated Git configuration and the real clock. This is where you type labs by hand, and typing exit leaves it. The second is `labs/run ch01/first-repo`. It replays one demo or lab with a fixed identity and a fixed clock, prints the transcript, and leaves the sandbox under the lab root so that you can inspect it afterwards. The third is `labs/verify-all.sh ch01`. It replays every script of a chapter and compares the output with the snippets printed in the book. For each script it prints `PASS`, `VOLATILE` or `FAIL`.

**[ANIMATION]** sandbox: steps=outside,shield,room,inside title=Why_the_configuration_is_isolated

**Why the configuration is isolated.** Git reads its settings from several files, and one of them is your personal dot gitconfig file in your home directory. Think about both directions. If the labs read that file, your aliases and your defaults would change the output, and my screen wouldn't match yours. If the labs wrote that file, an experiment in a lab would change your real setup. So the lab environment points Git at a configuration file inside the sandbox, and switches off the system-wide file. Three variables do this. `GIT_CONFIG_GLOBAL` names the file Git reads instead of your personal one. `GIT_CONFIG_NOSYSTEM`, set to one, makes Git skip the system-wide configuration file. `GIT_CEILING_DIRECTORIES` makes Git stop searching for a dot git directory at the lab root, so a sandbox never acts on a repository above it.

**[ANIMATION]** hash: differs=date steps=one,different,same

**Why the clock is fixed.** A commit records when it was made, and the commit ID is computed from everything in the commit, including that time. So the same commands, run at two different moments, produce different IDs. That's why replays pin the identity and the clock. The lab clock starts on Monday the seventh of September 2026, at ten in the morning, five and a half hours ahead of UTC, and it advances one minute before each command. That's why the IDs printed in the book are the IDs you get from a replay. One catch: in `labs/shell` the clock is real, so commits you type by hand get IDs that differ from the book. That's expected, and Chapter 6 explains it in full.

**Risk labels.** The first time a state-changing command appears in a chapter, or in a video, it carries one of three labels.

**[ON SCREEN]** The three labels in their colors: green, amber, red.

🟢 SAFE: the command reads state or only adds objects. Nothing is lost. The book's examples are `git status`, `git log`, `git fetch`, `git reflog` and `git commit`.

🟡 CAUTION: the command moves refs or rewrites local history. It's recoverable through the reflog, if you know how. Examples: `git reset --soft`, `git rebase`, `git commit --amend`.

🔴 DANGEROUS: the command can destroy uncommitted work, remote history, or the safety net itself. Examples: `git reset --hard`, `git clean -fd`, and `git push --force` together with its conditional forms. Yes, we all know a teammate who force-pushes. We'll meet them later, kindly.

**[ANIMATION]** trees: setup, edit, add, commit, reset file=notes.txt

**[ANIMATION]** step: reset

The labels describe the worst case. `git commit` is green because it only adds, and a wrong commit is corrected by another commit. `git reset --hard` is red because it overwrites working-tree files that were never recorded anywhere, and Git can't bring back what it never stored.

**[ANIMATION]** end

Before any red command, the book answers five questions, and so will I, out loud, before I run it: what it changes, what it can destroy, how to preview it, how to recover, and when it's appropriate. Make that your own rule. If you can't answer the five questions, you're not ready to run the command on a repository that matters.

**GitHub-side material.** What happens on GitHub's servers can't be replayed on your Mac. Those parts of the course show commands without output, and describe the expected result from GitHub's documentation, with a link. For the GitHub chapters you create a free organization with public practice repositories yourself. Nothing in this course asks you to type credentials into a script.

## MENTAL MODEL

**[ANIMATION]** sandbox:

**[ANIMATION]** step: room

One picture holds all of that. The lab is a sealed room on your own Mac.

**[ANIMATION]** step: enter

Inside the room there's a Git configuration file that belongs to the room, a clock that I control during replays, and one directory per replay. Outside the room is everything you care about: your real dot gitconfig file, your real repositories, your credentials. `labs/shell` and `labs/run` both walk into the room, and nowhere else.

**[ANIMATION]** step: doors

So where does the model break? In two places. First, the room has two doors with different clocks. `labs/run` uses the fixed clock, and `labs/shell` uses the real one. So "inside the sandbox" doesn't always mean "same IDs as the book". Second, the fixed clock isn't airtight. Two parts of Git ignore it and read the real clock, and the sandbox needs two configuration lines to deal with that. The diagram shows the reason in a root-cause box, the first of many in this course.

## DIAGRAM

Let's draw that room.

**[ANIMATION]** step: shield

**[DIAGRAM]** Build the outer box first, then the two inner boxes, then the arrows.

```text
 +--------------------------------- your Mac ----------------------------------+
 |                                                                             |
 |  +-----------------------------+      +----------------------------------+  |
 |  | your real ~/.gitconfig      |      | $LAB                             |  |
 |  | (never read, never written) |      |   sandbox configuration          |  |
 |  +-----------------------------+      |   hands-on directories           |  |
 |                                       |   one directory per replay       |  |
 |                                       +----------------------------------+  |
 |                                            ^                    ^           |
 |                                            |                    |           |
 |                                       labs/shell            labs/run        |
 |                                       (real clock)         (fixed clock)    |
 +-----------------------------------------------------------------------------+
```

The outer box is your Mac. On the left is your real configuration file. No arrow reaches it: it's never read and never written. On the right is the lab root, which holds the sandbox configuration, the hands-on directories, and one directory per replay. Two arrows enter it, one from `labs/shell` and one from `labs/run`. Nothing points at the left box.

**[DIAGRAM]** The root-cause box of section 1.7, one line at a time.

```text
Observed behavior : with a fixed lab clock, some replays would print different output depending on the real date
Git state         : every commit and every reflog entry in a sandbox carries the fixed lab date
Mechanism         : two parts of Git compare reflog dates with the REAL clock, not with the commit dates:
                    1. git fsck (Git 2.53.0 and later) skips reflog entries dated later than the real "now"
                    2. git gc and git reflog expire drop reflog entries older than 90 days,
                       or older than 30 days when the commit is no longer reachable from a branch
Root cause        : a lab date in the future trips rule 1; a lab date in the past trips rule 2 once it is old enough
Why Git does this : expiry is a real-time retention policy (Chapter 13: Recovery)
Correct fix       : keep the lab clock in the past, and switch time-based reflog expiry off in the sandbox
Prevention        : the sandbox configuration sets gc.reflogExpire and gc.reflogExpireUnreachable to "never"
```

Read it with me, and notice the form: seven lines, always the same seven. The mechanism is the line to remember: two parts of Git compare reflog dates with the real clock, not with the commit dates. A lab date in the future trips the first rule, and a lab date in the past trips the second once it's old enough. So the lab clock is kept in the past, and time-based reflog expiry is switched off in the sandbox. That's why you'll see `gc.reflogexpire=never` and `gc.reflogexpireunreachable=never` in every sandbox configuration listing in this course.

Three things follow. In a replay, your commits always behave like fresh work, on whatever day you run it. Real repositories use Git's defaults, which Chapter 13 covers, and the labs demonstrate only explicit expiry, which doesn't depend on any clock. And the variable `GIT_TEST_DATE_NOW` pins date arithmetic only. `git fsck` and reflog expiry read the real clock regardless, which is why the configuration lines are needed as well. The `git fsck` rule exists in Git 2.53.0 and later. Apple's Git 2.50.1 on the same Mac doesn't apply it.

## LIVE TERMINAL DEMO

**[TERMINAL]** Course folder. Caption bar: `labs/ch00/smoke-test.sh`.

Enough about the room. Let's walk in. From the course folder, replay the smoke test.

```bash
labs/run ch00/smoke-test
```

Before the output appears, predict which file the settings will come from. Your home directory, or somewhere under the lab root? Say it out loud.

<!-- snippet: ch00/smoke-test/01-init -->
```text
$ git init shop
Initialized empty Git repository in $LAB/ch00/smoke-test/shop/.git/
$ cd shop
$ git config list --show-origin --show-scope
global	file:$LAB/ch00/smoke-test/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch00/smoke-test/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch00/smoke-test/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch00/smoke-test/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch00/smoke-test/home/.gitconfig	gc.reflogexpireunreachable=never
local	file:.git/config	core.repositoryformatversion=0
local	file:.git/config	core.filemode=true
local	file:.git/config	core.bare=false
local	file:.git/config	core.logallrefupdates=true
local	file:.git/config	core.ignorecase=true
local	file:.git/config	core.precomposeunicode=true
```
<!-- /snippet -->

Look at the second column. Every `global` line comes from a dot gitconfig file under the lab root. The `local` lines come from the repository's own config file, inside its dot git folder. Your own file isn't in the list.

**[TERMINAL]** Caption bar: `labs/ch01/sandbox.sh`, snippet `01-env`.

Now the script that shows the room itself.

```bash
labs/run ch01/sandbox
```

The first snippet lists the Git environment that the lab library sets for every replay.

<!-- snippet: ch01/sandbox/01-env -->
```text
$ env | grep '^GIT_' | sort
GIT_AUTHOR_DATE=@1788755520 +0530
GIT_AUTHOR_EMAIL=you@example.com
GIT_AUTHOR_NAME=Lab User
GIT_CEILING_DIRECTORIES=$LAB:$LAB
GIT_COMMITTER_DATE=@1788755520 +0530
GIT_COMMITTER_EMAIL=you@example.com
GIT_COMMITTER_NAME=Lab User
GIT_CONFIG_GLOBAL=$LAB/ch01/sandbox/home/.gitconfig
GIT_CONFIG_NOSYSTEM=1
GIT_EDITOR=true
GIT_MERGE_AUTOEDIT=no
GIT_PAGER=cat
GIT_TERMINAL_PROMPT=0
GIT_TEST_DATE_NOW=1788755520
```
<!-- /snippet -->

Read the variables against the table of section 1.7. `GIT_CONFIG_GLOBAL` points into the sandbox, so Git reads this file instead of your personal one. `GIT_CONFIG_NOSYSTEM=1` means the system-wide file is skipped. And `GIT_CEILING_DIRECTORIES` makes Git stop searching for a dot git directory at the lab root. Those three are also set in `labs/shell`.

`GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` are the fixed clock, in Git's raw format: seconds since the first of January 1970 UTC, then the time-zone offset. `GIT_TEST_DATE_NOW` is a variable that Git's own test suite uses to fix "now" for date arithmetic, so that relative dates such as "2 minutes ago" give the same answer on every run. The name and email variables are a fixed identity that overrides configuration.

`GIT_EDITOR=true`, `GIT_PAGER=cat` and `GIT_TERMINAL_PROMPT=0` mean no editor, no pager and no password prompt, because a script can't answer them. `GIT_MERGE_AUTOEDIT=no` means a merge doesn't open an editor for its message. In `labs/shell`, the clock, the identity variables and the editor settings aren't pinned: the clock is real, the identity comes from the lab configuration, and your editor and pager work.

**[TERMINAL]** Snippet `02-config`.

Next, the script lists the configuration, sets a global alias, and lists the configuration again. `git config set --global` carries the label 🟡 CAUTION in the book's command-safety table, because it writes your personal configuration file. A slightly nervous prediction: where will that alias land?

**[PAUSE]**

<!-- snippet: ch01/sandbox/02-config -->
```text
$ git config list --show-origin --show-scope
global	file:$LAB/ch01/sandbox/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch01/sandbox/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch01/sandbox/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch01/sandbox/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch01/sandbox/home/.gitconfig	gc.reflogexpireunreachable=never
$ git config set --global alias.st "status --short --branch"
$ git config list --show-origin --show-scope
global	file:$LAB/ch01/sandbox/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch01/sandbox/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch01/sandbox/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch01/sandbox/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch01/sandbox/home/.gitconfig	gc.reflogexpireunreachable=never
global	file:$LAB/ch01/sandbox/home/.gitconfig	alias.st=status --short --branch
```
<!-- /snippet -->

`--show-scope` and `--show-origin` print the scope of every setting and the file it came from. Look at the last line: `alias.st` is in the sandbox file. Inside the sandbox, a "global" setting is global only to the sandbox. Your real configuration was neither read nor written. You can breathe out. And there are the two `gc.reflogexpire` lines from the root-cause box.

**[TERMINAL]** Snippet `03-clock`.

Last, the clock, and the promise from the start of this video. The script makes one empty commit and prints it with both dates.

<!-- snippet: ch01/sandbox/03-clock -->
```text
$ git init -q clock && cd clock
$ git commit -q --allow-empty -m "Check the lab clock"
$ git log --format=fuller
commit c67262763db796bdaa778e529bc358323e7f96df
Author:     Lab User <you@example.com>
AuthorDate: Mon Sep 7 10:07:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:07:00 2026 +0530

    Check the lab clock
```
<!-- /snippet -->

Look at `AuthorDate` and `CommitDate`: Monday the seventh of September 2026, a few minutes after ten, at plus five thirty. Now the commit ID, `c672627`. Open section 1.7 of the textbook: the same ID is printed there. It'll be the same on your Mac when you replay the script, today or next year. Don't take my word for it. Compare it yourself, because that comparison is the test that your lab works.

## COMMON MISTAKES

Five mistakes to watch for, each with its root cause.

1. **Expecting the book's commit IDs in `labs/shell`.** Root cause: `labs/shell` uses the real clock, and the commit ID is computed from everything in the commit, including the time.
2. **Running the tools from the wrong directory.** Root cause: `labs/shell`, `labs/run` and `labs/verify-all.sh` are run from the course folder, the directory that contains `textbook/`, `labs/` and `lab-manual/`.
3. **Believing that `GIT_TEST_DATE_NOW` freezes all of Git's time.** Root cause: it pins date arithmetic only; `git fsck` and reflog expiry read the real clock, which is why the two `gc.reflogExpire` settings exist.
4. **Reading a risk label as the typical outcome.** Root cause: the labels describe the worst case; green means nothing can be lost, not that the result is what you wanted.
5. **Assuming a lab can show what GitHub does.** Root cause: what happens on GitHub's servers cannot be replayed on your Mac; those parts are described from the documentation.

## PRODUCTION EXAMPLE

Now, out of the lab. Two engineers on an evaluation team type the same Git command on two Macs, and see different behavior. One has an alias and a personal default in their dot gitconfig file. The other doesn't. Neither knows, because neither has ever listed where their settings come from. The command you saw in the demo, `git config list --show-origin --show-scope`, is where that difference shows: every setting in effect, and the file it comes from.

The lab removes this whole class of confusion by giving every replay one known configuration file. On your team you can't isolate everyone's configuration. So you do the next best thing: you look at it before you theorize.

## PRACTICE EXERCISE

Your turn. Do Lab 0.1, "Verify the toolchain and build the sandbox", in [`lab-manual/m00-lab-setup.md`](../../lab-manual/m00-lab-setup.md). Type it by hand.

Before you start, write down two predictions. First: when the lab lists the configuration inside the sandbox, which file will the `global` lines name? Second: when you make a commit by hand in `labs/shell m00`, will its ID equal an ID printed in the book? Check both against what you see. And if one was wrong, good. Explain why.

## INTERVIEW QUESTION

**[ON SCREEN]** Q15, from the question bank.

Q15: "The same commands typed at two different times produce different commit IDs. Why? What did the lab environment pin to prevent it, and what did it not need to pin?"

Answer it out loud before you open the answers file. A strong answer says what a commit ID is computed from, and names time as one of the inputs. It names what the replays pin, and by which mechanism. And it reasons about the last part of the question instead of guessing: which inputs to an ID are already identical on two machines, without any pinning? If that part feels out of reach today, that's normal. You'll be able to answer it fully after video 7.

## RECAP

Let's land this. You should now be able to say these sentences. The goal of this course is to diagnose from first principles, choose the lowest-risk fix, verify, and prevent. Every transcript is real output from a script in the labs folder, and I can replay it with `labs/run` and check a chapter with `labs/verify-all.sh`. The lab never touches my real configuration, because `GIT_CONFIG_GLOBAL` redirects the global file and `GIT_CONFIG_NOSYSTEM` switches off the system file. Replays pin the clock because a commit ID depends on time, and the sandbox sets two reflog-expiry settings to never, because `git fsck` and expiry read the real clock. A risk label describes the worst case, and before a red command I answer five questions.

## HOMEWORK

- Read sections 1.1, 1.7 and 1.8 of [Chapter 1](../../textbook/ch01-fundamentals.md).
- Run `labs/verify-all.sh ch01` and keep the output.
- Read [`lab-manual/README.md`](../../lab-manual/README.md).
- Challenge: without the book open, write the table of the three risk labels with two example commands each, and the five questions for a dangerous command. Then check it against section 1.8.

That's video one. No Git commands yet, and you already have a safe room to break things in, and a way to prove it's safe. Next time: what version control actually solves, and why Git the tool and GitHub the platform are two different things. Until then, look at the state first and type second. See you in the next one.
