# V002: What version control solves, and Git the tool versus GitHub the platform

- **Part.** 0: Orientation
- **Module.** 0 and 1
- **Planned minutes.** 18
- **Prerequisites.** V001
- **Textbook sections.** [Chapter 1: Fundamentals](../../textbook/ch01-fundamentals.md), sections 1.2 to 1.6
- **Demo scripts.** `labs/ch01/lab-00-1-toolchain.sh` (volatile: its output is specific to the machine)

## HOOK

**[ON SCREEN]** A chat message: "The merge is blocked."

Someone on your team writes three words in chat: "The merge is blocked." Your CTO asks why.

That sentence has three different root causes, in three different layers. Git stops a merge when both sides changed the same lines. GitHub stops a merge when a ruleset requires a review that has not been given. GitHub Actions stops a merge when a required check has not reported success. The three symptoms look alike in a chat message, and the three fixes have nothing in common.

**[PAUSE]**

If you say "GitHub" when you mean Git, or "Git" when you mean GitHub, you will look for the cause in the wrong layer. This video draws the line between the two.

## INTRODUCTION

In the last video you set up the sandbox. In this one you get the two ideas that frame everything else. The first is the problem that version control solves, stated without naming any product. The second is the difference between Git, a program on your machine, and GitHub, a platform that hosts Git repositories. On the way you will see what "distributed" means for your daily work, the design goals that Git was written to meet, and a fact about your own Mac: it has two Git installations, and you need to know which one is answering.

## LEARNING OBJECTIVES

After this video you can:

1. Describe the problem that version control solves without naming a product.
2. Contrast a centralized with a distributed system by what each clone holds.
3. Name Git's design goals as the textbook lists them.
4. Say for a given feature whether it belongs to Git the tool or to GitHub the platform.
5. State which of the two Gits on the Mac a command runs, and how to find out.

## CONCEPT

**The problem version control solves.** In one sentence: a version control system records successive states of a set of files, so that you can recall any state, compare any two, and see who recorded each one, when, and why.

Four capabilities define the category, and each answers a question.

**[ON SCREEN]** The four-row table of section 1.2.

Recall: what did the project look like when release 2.3 was built? Compare: what differs between what runs in production and what I have here? Attribute: who changed this line, when, and with what explanation? Integrate: two people changed the project at the same time; what is the combined result, and where do their changes collide?

The first three are bookkeeping. The fourth is the reason the tool has a learning curve. Combining states that were produced independently needs a model of history in which "independently" has a precise meaning. Part 1 of this course gives you that model.

**Centralized versus distributed.** In one sentence: in a centralized system the history lives on one server and each developer holds one checked-out version; in a distributed system every developer's copy contains the history, and "the server" is one more copy that the team agrees to treat as the meeting point.

Compare the two by four questions. Where does the history live? Centralized: on one server. Distributed: in every clone. How is a change recorded? Centralized: a network operation against the server. Distributed: a local write, and publishing is a separate step. What if the server is unreachable? Centralized: nobody can record changes or collaborate. Distributed: local work continues, and the exchange waits. What if the server's disk is lost and there are no backups? Centralized: the history is gone. Distributed: every clone still holds what it had fetched.

Three consequences shape your daily work with Git. One: commit and publish are different operations. `git commit` writes to the repository on your disk. `git push` copies commits to another repository. "It is committed" and "it is on the server" are independent facts, checked with different commands. Two: your view of the server is a cached copy. A name such as `origin/main` records, in the words of Git's data model manual, "the last-known state of a branch in a remote repository", as of your last exchange with it. Three: nothing in Git makes one repository the authority. The team does, by convention and through permissions on the hosting platform.

Inside `.git`: the whole repository, meaning the history and every name in it, is the `.git` directory at the top of your project. A clone is a copy of another repository's objects and names. The copy on a server is normally a bare repository: the same contents, with no checked-out files beside them.

**Git's design goals.** Git was written in 2005 for the Linux kernel, after the kernel project lost free use of the proprietary tool BitKeeper. Pro Git lists the goals of the new system, and each one explains a design decision you will meet later.

**[ON SCREEN]** The goals table of section 1.4.

Speed: almost every operation reads local files. Simple design: four object types named by a hash of their content, plus names that point at them. Strong support for non-linear development, with thousands of parallel branches: a branch is one small name that points at a commit, so creating one costs almost nothing. Fully distributed: every clone has the history, and fetch and push exchange objects and update names. Able to handle large projects like the Linux kernel efficiently: compressed pack files, and later, partial clone and sparse checkout.

Git's manual describes it as "a fast, scalable, distributed revision control system with an unusually rich command set that provides both high-level operations and full access to internals". The high-level commands, such as `git add`, `git commit` and `git merge`, are called porcelain. The low-level ones, such as `git hash-object` and `git update-ref`, are called plumbing. This course uses plumbing to prove what porcelain did.

Two things are absent from the goals, and both surprise people. Git has no user accounts and no permissions: the layer that hosts a repository decides who may read or write it. And Git stores content, not intentions: it does not record that a file was renamed, and it does not track empty directories.

**Git the tool versus GitHub the platform.** In one sentence: Git is a program on your machine that stores history in a `.git` directory; GitHub is a hosted service that stores Git repositories and surrounds them with its own objects: accounts, permissions, pull requests, reviews, rulesets and workflows.

**[ON SCREEN]** Lower-third label switches between **Git**, **GitHub** and **GitHub Actions** as each row is read.

Fill the two columns with me, and for each row ask: does it arrive with `git clone`? Commits, directory trees, file contents and annotated tags: Git, objects in the repository, and yes, they arrive. Branches and tags: Git, names in the repository, and yes; the server's branches arrive as remote-tracking branches such as `origin/main`. Author and committer name and email, and a signature: Git, inside each commit. But the "Verified" badge next to a commit: GitHub. It is GitHub's judgement of the signature, stored in GitHub's database, and it does not arrive with a clone. HEAD, the index, reflogs, stashes, hooks and `.git/config`: Git, but local only. Each clone has its own. A pull request, a review, a comment: GitHub's database, plus read-only refs that GitHub creates on the server for the pull request's commits. Issues, discussions, stars: GitHub. A fork: GitHub, a server-side repository linked to its parent; to Git it is one more remote. Rulesets and branch protection: GitHub settings. A release: a GitHub object that points at a Git tag and adds notes and files, so the tag arrives and the release does not. A workflow file under `.github/workflows/`: Git, because it is a tracked file in commits. A workflow run, its logs, its artifacts and its secrets: GitHub Actions. Access tokens, SSH keys and collaborator roles: GitHub.

The GitHub rows are described from the course's research report, which links the documentation page for each. Other hosts, such as GitLab, Bitbucket and Forgejo, run the same Git and surround it with different platform objects.

One row deserves its own sentence. A pull request is not a Git feature. Git has commits, branches and merges. GitHub adds the pull request as a place to discuss a proposed merge, and performs the merge on its servers when you press the button.

## MENTAL MODEL

The textbook gives one analogy for each idea, and each has a breaking point that teaches more than the analogy.

For version control: a bound laboratory notebook. Pages are numbered, dated and signed, and a correction is a new page, never an erased one. It breaks in two places. A notebook is one sequence kept by one person, while a repository holds many lines of work that people extend in parallel and later join. And each recorded state in Git is the whole project, not that day's notes.

For centralized versus distributed: a centralized system is a reference library. The books stay in the building, and when the building is closed nobody reads. A distributed system gives every reader a copy of the whole library. It breaks because library copies never need to agree again, while repositories must. Each copy accumulates its own additions, and exchanging them is an explicit act that can find two copies in disagreement.

For Git and GitHub: Git is a file format with its editor; GitHub is a document-management service where such files are stored, discussed and approved. It breaks because GitHub also runs Git on its servers and performs Git operations for you: pressing a merge button creates commits. Platform actions change Git data, so you must know which layer did what.

## DIAGRAM

**[DIAGRAM]** Draw the left half first, then the right half, then the caption under the right half.

```text
 Centralized                                Distributed

  +--------------------+                    +--------------------------+
  | server             |                    | server (bare repository) |
  | the only history   |                    | history                  |
  +--------------------+                    +--------------------------+
      ^            ^                           ^   |             ^   |
      | commit     | commit              push  |   | fetch  push |   | fetch
      | (network)  | (network)                 |   v             |   v
  +---------+  +---------+              +--------------+   +--------------+
  | Asha    |  | Ravi    |              | Asha         |   | Ravi         |
  | one     |  | one     |              | history +    |   | history +    |
  | version |  | version |              | one version  |   | one version  |
  +---------+  +---------+              +--------------+   +--------------+
                                         commit = local     commit = local
```

On the left, one server holds the only history. Asha and Ravi each hold one version, and every commit is an arrow to the server: a network operation. On the right, the server is a bare repository with the history, and Asha and Ravi each hold the history plus one checked-out version. The arrows are now push and fetch. Commit does not appear as an arrow at all, because a commit is local. That missing arrow is the difference.

**[DIAGRAM]** Second diagram: two empty columns headed "Git" and "GitHub", filled from the table of section 1.5 as the rows were read in the concept segment. Leave it on screen for ten seconds at the end.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch01/lab-00-1-toolchain.sh`, snippet `01-which`.

Before we trust any transcript, we find out which Git produced it. This script is marked volatile, because its output is specific to the machine: the verification tool checks that it runs and does not compare its output. Your paths may differ from mine.

```bash
labs/run ch01/lab-00-1-toolchain
```

The first command is `which -a git`. Predict: how many lines will it print on your Mac?

<!-- snippet: ch01/lab-00-1-toolchain/01-which -->
```text
$ which -a git
/opt/homebrew/bin/git
/usr/bin/git
/opt/homebrew/bin/git
$ git --version
git version 2.55.0
$ /usr/bin/git --version
git version 2.50.1 (Apple Git-155)
```
<!-- /snippet -->

`which -a` lists every match in search order. The first line is the program that runs when you type `git`. On this machine it is the Homebrew build, and it prints version 2.55.0. `/usr/bin/git` is the Git that Apple ships with its developer tools, and it prints 2.50.1. The third line repeats the first because the Homebrew directory appears twice in this shell's `PATH`, which is harmless.

The difference matters. Git 2.50.1 has no `git history` and no `git last-modified`, and its manual still labels `git switch` and `git restore` as experimental, a label that Git removed in 2.51. Each installation also reads its own system-level configuration file. You meet the Apple Git in three situations: a script that calls `/usr/bin/git` by its full path, a scheduled job or graphical tool that starts with a shorter `PATH` than your terminal, and a colleague's Mac without Homebrew.

**[TERMINAL]** Snippet `02-build-options`.

Now ask the Git that answered how it was built.

<!-- snippet: ch01/lab-00-1-toolchain/02-build-options -->
```text
$ git version --build-options
git version 2.55.0
cpu: arm64
no commit associated with this build
sizeof-long: 8
sizeof-size_t: 8
shell-path: /bin/sh
rust: disabled
feature: fsmonitor--daemon
gettext: enabled
libcurl: 8.7.1
zlib: 1.2.12
SHA-1: SHA1_DC
SHA-256: SHA256_BLK
default-ref-format: files
default-hash: sha1
```
<!-- /snippet -->

Three lines are worth reading now. `default-hash: sha1` means new repositories name objects with SHA-1. `SHA-1: SHA1_DC` means the implementation detects known collision attacks. And `default-ref-format: files` means branch and tag names are stored as plain files, which is why this course can show them with `cat`. Chapter 3 covers the alternatives.

**[ON SCREEN]** "Every transcript in this course comes from Git 2.55.0."

A version note from the textbook: Git 2.55.0 of 29 June 2026 is what Homebrew installed here. The latest release is Git 2.56.0 of 28 September 2026, which adds a few commands and no security fix that 2.55.0 lacks. Upgrading is optional, and the course marks what needs it as "added in Git 2.56, not run here".

**[ON SCREEN]** Lower third: **GitHub**.

And one note on the other layer. The GitHub CLI, `gh`, is a separate program. Installed here is 2.88.1. The latest on 1 October 2026 is 2.102.0, with six security-fix releases in between, so upgrade it before the GitHub chapters. From 2.91.0 the CLI collects pseudonymous usage telemetry unless you opt out; the textbook gives the two ways to opt out and says that neither was run here, because the setting does not exist in 2.88.1.

## COMMON MISTAKES

1. **Saying "it is committed" to mean "it is on the server".** Root cause: commit and publish are different operations; `git commit` writes to your disk and `git push` copies commits to another repository.
2. **Treating `origin/main` as the live state of the server.** Root cause: it is a cached copy, the last-known state as of your last exchange.
3. **Assuming a clone is a backup that somebody made for you.** Root cause: distributed means that copies are possible, not that they are made; a commit that exists only on one laptop is one disk failure away from not existing.
4. **Looking for a pull request, a review or a ruleset inside Git.** Root cause: those are GitHub objects in GitHub's database, and they do not arrive with a clone.
5. **A command from the course is "not a git command".** Root cause: the shell found the Apple Git first; `which -a git` and `git --version` show it, and the fix is to put the Homebrew directory first in `PATH`.

## PRODUCTION EXAMPLE

The evaluation score of an LLM application drops from one week to the next. To explain the drop you need the prompt templates, the evaluation configuration and the scoring code exactly as they were when last week's number was produced. If they live in one repository and the report recorded a commit ID, one command restores that state. If they live on a shared drive, the question has no reliable answer. Datasets and model weights need additional tools, which later chapters cover.

And the second half of the picture: GitHub is unreachable for an hour. You can still commit, create branches, compare versions and search history, because all of that reads your own `.git`. You cannot push, fetch, open a pull request or start a workflow.

## PRACTICE EXERCISE

Do Exercise 1.2, Level 1, "Git or GitHub?", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Before you look anything up, decide each item from the rule you heard today: where does this thing live, and would a `git clone` carry it? Write your prediction beside each item first, then check.

## INTERVIEW QUESTION

Q1: "Why can `git log` work without a network connection while `git push` cannot? What does your answer imply about backups?"

Answer aloud. A strong answer says where the history that `git log` reads is stored, and what `git push` has to reach. It separates recording from publishing. And it does not stop at the first half: it draws the consequence for a commit that exists in exactly one place, in both directions, the laptop and the server.

## RECAP

You should now be able to say: version control gives me recall, comparison, attribution and integration, and integration is the hard one. In a distributed system every clone holds the history, so committing is local and publishing is a separate step. Git has no accounts and no permissions, and it stores content, not intentions. Git is a program and a data format; GitHub is a platform that hosts Git repositories and adds its own objects, most of which a clone does not carry. And on my Mac, `which -a git` tells me which of two Gits I am talking to.

## HOMEWORK

- Read sections 1.2 to 1.6 of [Chapter 1](../../textbook/ch01-fundamentals.md).
- Note the output of the three version commands on your machine: `which -a git`, `git --version`, `git version --build-options`.
- Challenge: take five things from a repository page of a project you use, and decide for each whether a `git clone` would carry it. Keep the list; V115 returns to it with proof.
