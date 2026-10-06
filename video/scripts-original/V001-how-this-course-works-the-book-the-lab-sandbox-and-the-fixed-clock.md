# V001: How this course works: the book, the lab sandbox and the fixed clock

- **Part.** 0: Orientation
- **Module.** 0
- **Planned minutes.** 16
- **Prerequisites.** None
- **Textbook sections.** [Chapter 1: Fundamentals](../../textbook/ch01-fundamentals.md), sections 1.1, 1.7 and 1.8
- **Demo scripts.** `labs/ch00/smoke-test.sh`, `labs/ch01/sandbox.sh`

## HOOK

**[ON SCREEN]** Title card: "A deploy pipeline goes red on a Friday evening."

A deploy pipeline goes red on a Friday evening. The engineer on call says the fix is committed, and can show the commit on screen. The pipeline fails again, on the same line. Your CTO asks three questions. What exactly is in the commit that the pipeline built? Where does that commit exist right now: on the laptop, on the server, or on both? And what is the smallest change that makes the main branch correct, and how will we know that it worked?

**[PAUSE]**

None of these is a question about commands. Each one is a question about state: which bytes Git recorded, which names point at them, and which machine holds them. An engineer who knows fifty commands and cannot answer these questions will try things until something appears to work. An engineer who can answer them needs about ten read-only commands and a method. This course teaches the second engineer.

## INTRODUCTION

Welcome to Git and GitHub Deep Mastery. This first video contains no Git theory. It sets up the three things that every later video depends on: the way the book and the videos are written, the lab sandbox in which you will type every command, and the fixed clock that makes the output on my screen equal to the output in your book.

The goal of the course fits in one sentence. You will learn to diagnose a Git or GitHub problem from first principles, choose the lowest-risk fix, verify that it worked, and prevent it from happening silently again. That is four verbs: diagnose, choose, verify, prevent. Knowing commands is not on the list.

By the end of these sixteen minutes you will have a working sandbox, you will know that nothing in this course reads or writes your real Git configuration, and you will be able to say why the commit ID on screen is the commit ID in the textbook.

## LEARNING OBJECTIVES

**[ON SCREEN]** The five objectives, shown one at a time.

After this video you can:

1. State the goal of the course in one sentence: diagnose from first principles, choose the lowest-risk fix, verify, prevent.
2. Open an isolated lab shell with `labs/shell`, replay a demo with `labs/run`, and check a chapter with `labs/verify-all.sh`.
3. Explain why the lab configuration is isolated, and name the variable that redirects the global configuration file.
4. Explain why replays pin the clock, and why the sandbox sets the two `gc.reflogExpire` settings to `never`.
5. Give the meaning of the three risk labels and the five questions asked before a dangerous command.

## CONCEPT

Start with why the course is built the way it is.

**The ladder.** Every important concept in the textbook is taught on the same ladder, and the videos follow it. In one sentence: the plain explanation. Analogy: one comparison, and the place where the comparison breaks. Precisely: the technical statement with the correct terms. Inside `.git`: which files change on disk. See it: a real transcript. Picture: a diagram. In production: a realistic case from a backend or AI/ML team. The ladder goes from plain words down to files on disk and back up to a real team. When you can walk a concept down and up that ladder yourself, you own it.

**Transcripts are real.** Whenever you see terminal output in a `text` block in the book, or on my screen, it is real output. A script under `labs/` produced it and a tool inserted it into the page. Nobody typed it by hand. In those transcripts, `$LAB` stands for the lab root, which is `~/git-mastery-labs` unless you set the variable `GIT_MASTERY_LABS`. A line of the form `[exit status: 1]` is the exit status of the command above it, and a line that starts with `#` is a comment written by the script.

**Three tools.** You run all three from the course folder, the directory that contains `textbook/`, `labs/` and `lab-manual/`.

**[ON SCREEN]** The table of three tools from section 1.7.

The first is `labs/shell m00`. It opens your shell in `$LAB/hands-on/m00` with an isolated Git configuration and the real clock. This is where you type labs by hand, and `exit` leaves it. The second is `labs/run ch01/first-repo`. It replays one demo or lab with a fixed identity and a fixed clock, prints the transcript, and leaves the sandbox in `$LAB/ch01/first-repo` so that you can inspect it afterwards. The third is `labs/verify-all.sh ch01`. It replays every script of a chapter and compares the output with the snippets printed in the book. For each script it prints `PASS`, `VOLATILE` or `FAIL`.

**Why the configuration is isolated.** Git reads its settings from several files, and one of them is your personal `~/.gitconfig`. Think about both directions. If the labs read that file, your aliases and your defaults would change the output, and my screen would not match yours. If the labs wrote that file, an experiment in a lab would change your real setup. So the lab environment points Git at a configuration file inside the sandbox, and switches off the system-wide file. Three variables do this. `GIT_CONFIG_GLOBAL` names the file Git reads instead of `~/.gitconfig`. `GIT_CONFIG_NOSYSTEM=1` makes Git skip the system-wide configuration file. `GIT_CEILING_DIRECTORIES` makes Git stop searching for a `.git` directory at the lab root, so a sandbox never acts on a repository above it.

**Why the clock is fixed.** A commit records when it was made, and the commit ID is computed from everything in the commit, including that time. So the same commands run at two different moments produce different IDs. Replays pin the identity and the clock. The lab clock starts on Monday 7 September 2026, at 10:00 at UTC plus 05:30, and it advances one minute before each command. That is why the IDs printed in the book are the IDs you get from a replay. In `labs/shell` the clock is real, so commits you type by hand get IDs that differ from the book. That is expected, and Chapter 6 explains it in full.

**Risk labels.** The first time a state-changing command appears in a chapter, or in a video, it carries one of three labels.

**[ON SCREEN]** The three labels in their colors: green, amber, red.

🟢 SAFE: the command reads state or only adds objects. Nothing is lost. The book's examples are `git status`, `git log`, `git fetch`, `git reflog` and `git commit`. 🟡 CAUTION: the command moves refs or rewrites local history. It is recoverable through the reflog if you know how. Examples: `git reset --soft`, `git rebase`, `git commit --amend`. 🔴 DANGEROUS: the command can destroy uncommitted work, remote history, or the safety net itself. Examples: `git reset --hard`, `git clean -fd`, and `git push --force` together with its conditional forms.

The labels describe the worst case. `git commit` is green because it only adds, and a wrong commit is corrected by another commit. `git reset --hard` is red because it overwrites working-tree files that were never recorded anywhere, and Git cannot bring back what it never stored.

Before any red command, the book answers five questions, and so will I, aloud, before I run it: what it changes, what it can destroy, how to preview it, how to recover, and when it is appropriate. Make that your own rule. If you cannot answer the five questions, you are not ready to run the command on a repository that matters.

**GitHub-side material.** What happens on GitHub's servers cannot be replayed on your Mac. Those parts of the course show commands without output and describe the expected result from GitHub's documentation, with a link. For the GitHub chapters you create a free organization with public practice repositories yourself. Nothing in this course asks you to type credentials into a script.

## MENTAL MODEL

Hold this model: the lab is a sealed room on your own Mac.

Inside the room there is a Git configuration file that belongs to the room, a clock that I control during replays, and one directory per replay. Outside the room is everything you care about: your real `~/.gitconfig`, your real repositories, your credentials. `labs/shell` and `labs/run` both walk into the room and nowhere else.

Where does the model break? In two places. First, the room has two doors with different clocks. `labs/run` uses the fixed clock; `labs/shell` uses the real one. So "inside the sandbox" does not always mean "same IDs as the book". Second, the fixed clock is not airtight. Two parts of Git ignore it and read the real clock, and the sandbox needs two configuration lines to deal with that. The diagram segment shows the reason in a root-cause box, the first of many in this course.

## DIAGRAM

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

The outer box is your Mac. On the left is your real configuration file. No arrow reaches it: it is never read and never written. On the right is `$LAB`, which holds the sandbox configuration, the hands-on directories, and one directory per replay. Two arrows enter it, one from `labs/shell`, one from `labs/run`. Nothing points at the left box.

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

Read it with me, and notice the form: seven lines, always the same seven. The mechanism is the line to remember: two parts of Git compare reflog dates with the real clock, not with the commit dates. A lab date in the future trips the first rule, and a lab date in the past trips the second once it is old enough. So the lab clock is kept in the past, and time-based reflog expiry is switched off in the sandbox. That is why you will see `gc.reflogexpire=never` and `gc.reflogexpireunreachable=never` in every sandbox configuration listing in this course.

Three things follow. In a replay your commits always behave like fresh work, on whatever day you run it. Real repositories use Git's defaults, which Chapter 13 covers; the labs demonstrate only explicit expiry, which does not depend on any clock. And the variable `GIT_TEST_DATE_NOW` pins date arithmetic only. `git fsck` and reflog expiry read the real clock regardless, which is why the configuration lines are needed as well. The `git fsck` rule exists in Git 2.53.0 and later; Apple's Git 2.50.1 on the same Mac does not apply it.

## LIVE TERMINAL DEMO

**[TERMINAL]** Course folder. Caption bar: `labs/ch00/smoke-test.sh`.

First, proof that the sandbox works. From the course folder, replay the smoke test.

```bash
labs/run ch00/smoke-test
```

Before the output: predict which file the settings will come from. Your home directory, or somewhere under `$LAB`?

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

Point at the second column. Every `global` line comes from a `.gitconfig` under `$LAB/ch00/smoke-test/home`. The `local` lines come from the repository's own `.git/config`. Your own file is not in the list.

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

Read the variables against the table of section 1.7. `GIT_CONFIG_GLOBAL` points into the sandbox: Git reads this file instead of `~/.gitconfig`. `GIT_CONFIG_NOSYSTEM=1`: the system-wide file is skipped. `GIT_CEILING_DIRECTORIES`: Git stops searching for a `.git` directory at the lab root. Those three are also set in `labs/shell`. `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` are the fixed clock, in Git's raw format: seconds since 1 January 1970 UTC, then the time-zone offset. `GIT_TEST_DATE_NOW` is a variable that Git's own test suite uses to fix "now" for date arithmetic, so that relative dates such as "2 minutes ago" give the same answer on every run. The name and email variables are a fixed identity that overrides configuration. `GIT_EDITOR=true`, `GIT_PAGER=cat` and `GIT_TERMINAL_PROMPT=0` mean no editor, no pager and no password prompt, because a script cannot answer them. `GIT_MERGE_AUTOEDIT=no` means a merge does not open an editor for its message. In `labs/shell` the clock, the identity variables and the editor settings are not pinned: the clock is real, the identity comes from the lab configuration, and your editor and pager work.

**[TERMINAL]** Snippet `02-config`.

Next, the script lists the configuration, sets a global alias, and lists the configuration again. `git config set --global` carries the label 🟡 CAUTION in the book's command-safety table, because it writes your personal configuration file. Predict: where will the alias land?

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

`--show-scope` and `--show-origin` print the scope of every setting and the file it came from. Point at the last line: `alias.st` is in the sandbox file. Inside the sandbox, a "global" setting is global only to the sandbox. Your real configuration was neither read nor written. And there are the two `gc.reflogexpire` lines from the root-cause box.

**[TERMINAL]** Snippet `03-clock`.

Last, the clock. The script makes one empty commit and prints it with both dates.

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

Point at `AuthorDate` and `CommitDate`: Monday 7 September 2026, a few minutes after ten, at plus 05:30. Then point at the commit ID, `c672627`. Open section 1.7 of the textbook: the same ID is printed there. It will be the same on your Mac when you replay the script, today or next year. Compare it yourself; that comparison is the test that your lab works.

## COMMON MISTAKES

1. **Expecting the book's commit IDs in `labs/shell`.** Root cause: `labs/shell` uses the real clock, and the commit ID is computed from everything in the commit, including the time.
2. **Running the tools from the wrong directory.** Root cause: `labs/shell`, `labs/run` and `labs/verify-all.sh` are run from the course folder, the directory that contains `textbook/`, `labs/` and `lab-manual/`.
3. **Believing that `GIT_TEST_DATE_NOW` freezes all of Git's time.** Root cause: it pins date arithmetic only; `git fsck` and reflog expiry read the real clock, which is why the two `gc.reflogExpire` settings exist.
4. **Reading a risk label as the typical outcome.** Root cause: the labels describe the worst case; green means nothing can be lost, not that the result is what you wanted.
5. **Assuming a lab can show what GitHub does.** Root cause: what happens on GitHub's servers cannot be replayed on your Mac; those parts are described from the documentation.

## PRODUCTION EXAMPLE

Two engineers on an evaluation team type the same Git command on two Macs and see different behavior. One has an alias and a personal default in `~/.gitconfig`; the other does not. Neither knows, because neither has ever listed where their settings come from. The command you saw in the demo, `git config list --show-origin --show-scope`, is where that difference shows: every setting in effect and the file it comes from. The lab removes this whole class of confusion by giving every replay one known configuration file. On your team you cannot isolate everyone's configuration, so you do the next best thing: you look at it before you theorize.

## PRACTICE EXERCISE

Do Lab 0.1, "Verify the toolchain and build the sandbox", in [`lab-manual/m00-lab-setup.md`](../../lab-manual/m00-lab-setup.md). Type it by hand.

Before you start, write down two predictions. First: when the lab lists the configuration inside the sandbox, which file will the `global` lines name? Second: when you make a commit by hand in `labs/shell m00`, will its ID equal an ID printed in the book? Check both predictions against what you see, and explain any that were wrong.

## INTERVIEW QUESTION

**[ON SCREEN]** Q15, from the question bank.

Q15: "The same commands typed at two different times produce different commit IDs. Why? What did the lab environment pin to prevent it, and what did it not need to pin?"

Answer it aloud before you open the answers file. A strong answer says what a commit ID is computed from, and names time as one of the inputs. It names what the replays pin and by which mechanism. And it reasons about the last part of the question instead of guessing: which inputs to an ID are already identical on two machines without any pinning? You will be able to answer that part fully after V007.

## RECAP

You should now be able to say these sentences. The goal of this course is to diagnose from first principles, choose the lowest-risk fix, verify, and prevent. Every transcript is real output from a script under `labs/`, and I can replay it with `labs/run` and check a chapter with `labs/verify-all.sh`. The lab never touches my real configuration, because `GIT_CONFIG_GLOBAL` redirects the global file and `GIT_CONFIG_NOSYSTEM` switches off the system file. Replays pin the clock because a commit ID depends on time, and the sandbox sets two reflog-expiry settings to `never` because `git fsck` and expiry read the real clock. A risk label describes the worst case, and before a red command I answer five questions.

## HOMEWORK

- Read sections 1.1, 1.7 and 1.8 of [Chapter 1](../../textbook/ch01-fundamentals.md).
- Run `labs/verify-all.sh ch01` and keep the output.
- Read [`lab-manual/README.md`](../../lab-manual/README.md).
- Challenge: without the book open, write the table of the three risk labels with two example commands each, and the five questions for a dangerous command. Then check it against section 1.8.
