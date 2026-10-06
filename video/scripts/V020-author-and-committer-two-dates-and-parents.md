# V020: Author and committer, two dates, and parents

- **Part.** 1: Foundations
- **Module.** 3
- **Planned minutes.** 22
- **Prerequisites.** V019
- **Textbook sections.** [Chapter 6: Commits](../../textbook/ch06-commits.md), sections 6.5 and 6.6 (with the identity failure of section 6.13)
- **Demo scripts.** `labs/ch06/author-committer.sh`, `labs/ch06/date-filters.sh`, `labs/ch06/identity.sh`, `labs/ch06/parents.sh`

## HOOK

**[ON SCREEN]** "`git log` dates this change 24 August. The release notes list it under 'merged since 1 September'. Which system is wrong?"

Your CTO asks: "`git log` dates this change 24 August. The release notes list it under 'merged since 1 September'. Which system is wrong?"

And a second question the same week: "Half of our release manager's commits appear on GitHub without her avatar, under a name that is not a link. Did somebody else push them?" Make your guess on both, out loud.

**[PAUSE]**

Neither system is wrong, and nobody else pushed. A commit, one saved snapshot of the project, records two people and two times, and Git prints one date and filters by the other. And Git copies a name and an email address from configuration into each commit, and checks neither. Today is about the two identity lines and the parent lines of a commit. You'll reproduce the first puzzle on screen, and solve the second before we finish.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you read a commit object: tree, parent, author, committer, message. Today we take the middle three lines seriously.

First, author and committer: who they are, when they differ, and what that does to dates in a log. Then a commit made with the wrong identity: how to diagnose it and fix the cause. Then parents: root commits, ordinary commits and merge commits, and the two suffixes, caret and tilde, that walk the parent links.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Distinguish author from committer, and name three operations that make them differ.
2. Say which date `git log` prints, and which date `--since` filters on.
3. Diagnose a commit made with the wrong identity, and fix the cause.
4. Navigate the parents of a merge with `^` and `~`.

## CONCEPT

**Author and committer.** In one sentence: the author is the person who wrote the change, and the committer is the person who created this commit object. Each is recorded with a name, an email address, a time and a time-zone offset.

Where do the values come from? For both identities, Git reads the environment first, the variables your shell hands to a program: `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_AUTHOR_DATE`, and the three `GIT_COMMITTER_` variables. Then `user.name` and `user.email`, from the configuration. And as a last resort it guesses from the system user name and host name. `--author` and `--date` set the author fields of one commit. The committer has no such option: only the environment, the configuration and the clock.

**[ON SCREEN]** The operation table of section 6.5.

`git commit`: author you, now. Committer you, now.

`git commit --author=... --date=...`: author as given. Committer you, now.

`git cherry-pick`, `git rebase`, `git commit --amend`: author copied from the original commit. Committer you, now. Those are the three operations to remember. Cherry-pick copies a commit, rebase replays a branch, and amend replaces the last commit. Each gets its own video.

`git commit --amend --reset-author`: you, now, for both.

`git am`, applying a mailed patch: the author's name from the mail's `From:` line and the date from its `Date:` line. Committer you, now.

**[ANIMATION]** end

Quick quiz, three options. You rebase a branch that a colleague wrote last month. On the new commits, who is the author: you, your colleague, or both? Say your answer.

**[PAUSE]**

Your colleague. The author is copied from the original commit, and you become the committer, with today's time.

**Times and zones.** The seconds identify the instant. The offset only says what the wall clock showed where the commit was made. By default Git prints each date with its recorded offset.

**Which date Git uses where.** This is the root cause of the hook, in the textbook's words: `git log` prints the author date, and `--since` and `--until` select by committer date. A listing of "everything since the first of September" therefore contains a commit that displays the 24th of August. Both are correct: the change was written in August, and entered this history in September.

Why two dates? Git needs the committer date for its own work: the manual says the history-walking machinery assumes that commits have non-decreasing commit timestamps. The author date is for people: it survives every rebase and cherry-pick.

**Identity is an assertion.** Git copies name and email into the commit and checks neither. When a repository-local `user.email` is left over from another project, it overrides the global one, and every commit in that repository carries it. `git var GIT_AUTHOR_IDENT` prints the identity the next commit would record. `git config get --show-scope --show-origin --all user.email` names the file each value comes from. `get` needs Git 2.46 or later. And `user.useConfigOnly` turns Git's guess into an error.

**[ON SCREEN]** Lower third: **GitHub**. The textbook quotes GitHub's documentation: "GitHub links a commit to a user by matching the email address in the commit header to an email address on a GitHub account". Nothing in that match proves that the owner of the address made the commit. And commits that GitHub creates for you carry a GitHub address as committer email. An author who differs from the committer is normal, and no sign of tampering.

**[ANIMATION]** graph: d4c9fab-bb904cd-191bbd1-ae6795c main; bb904cd-79ff6d7-59c914e feature/f1; 59c914e-ae6795c; HEAD=main

**Parents.** In one sentence: the `parent` lines of a commit are the only links in the history graph: none for a root commit, one for an ordinary commit, two or more for a merge commit. In the picture, `d4c9fab` is the root and `ae6795c` is a merge.

Parents are ordered. The first parent is the commit HEAD pointed at when the commit was made, HEAD being the commit you're on. For a merge, the further parents are the commits you merged in. Two suffixes walk these links. `^<n>` selects the n-th parent of one commit. `~<n>` follows first parents n times. Caret chooses among the parents of one commit. Tilde goes back in a straight line.

A repository can have more than one root: `git switch --orphan` starts a history with no parent, and `git merge --allow-unrelated-histories` joins two of them.

**Risk labels in this video.** `git cherry-pick` is 🟡 CAUTION: it adds one commit to the current branch. `git commit --amend` is 🟡 CAUTION: it replaces the tip commit with a new one. `git config unset` is 🟡 CAUTION: it changes one configuration file, which has no history. `git merge` is 🟡 CAUTION: it moves the current branch and rewrites index and working tree.

**When not to rewrite an identity.** For the last commit, unpublished: `--amend --reset-author`. For published commits, the textbook's fix column says: leave them.

## MENTAL MODEL

Think of a letter and its envelope. The author line is the signature inside the letter: who wrote it, and the date they wrote it. The committer line is the postmark: who put it into this particular history, and when. Forward the letter, which is what a cherry-pick or a rebase does, and it gets a new postmark. The signature inside stays.

`git log` shows you the date on the letter. `--since` sorts by the postmark.

Where it breaks: neither the signature nor the postmark is verified. Both are text supplied by whoever creates the commit. A real postmark is stamped by a trusted office. A committer line is not.

**[ANIMATION]** step: state-1

For parents, keep the family tree from video 9: each record lists the parents, none lists the children.

## DIAGRAM

**[ANIMATION]** step: state-1

**[DIAGRAM]** The diagram of section 6.6.

```text
  d4c9fab---bb904cd---191bbd1-------------ae6795c   main   (HEAD -> main)
                  \                       /
                   79ff6d7---59c914e-----+          feature/f1
```

Try it now, on paper, thirty seconds. Copy this graph. HEAD is the merge commit, `ae6795c`. Mark the commit that `HEAD^2` names, and the one that `HEAD~2` names. Pause me, and write your answer.

**[PAUSE]**

**[DIAGRAM]** The same graph with the expressions written on the commits they name.

```text
                        HEAD~2      HEAD^1 = HEAD~1          HEAD
  d4c9fab-------------bb904cd---------191bbd1--------------ae6795c   main
                          \                                /
                           79ff6d7------------59c914e-----+
                           HEAD^2~1           HEAD^2
```

Start at HEAD, the merge commit `ae6795c`. `HEAD^1`, also written `HEAD^` or `HEAD~1`, is its first parent, `191bbd1`: where `main` was. `HEAD^2` is its second parent, `59c914e`: the tip of the merged branch. `HEAD~2` goes two steps along first parents, to `bb904cd`. And `HEAD^2~1` is the first parent of the second parent, `79ff6d7`. `HEAD~2` and `HEAD^^` are the same commit. `HEAD^2` is not. If you mixed the two up, you're in good company.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch06/author-committer.sh`.

```bash
labs/run ch06/author-committer
```

Asha wrote a commit on her branch. You cherry-pick it onto `main`. `git cherry-pick` 🟡 CAUTION. Predict the four lines of `--format=fuller` on the new commit: who is the author, who is the committer, and which time does each carry? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch06/author-committer/01-cherry-pick -->
```text
$ git log -1 --format=fuller asha/bleu
commit da5c9a3495f90d9d260daeecb19aa556173c4ae0
Author:     Asha Rao <asha@example.com>
AuthorDate: Mon Sep 7 10:05:00 2026 +0530
Commit:     Asha Rao <asha@example.com>
CommitDate: Mon Sep 7 10:05:00 2026 +0530

    Add BLEU metric skeleton
$ git cherry-pick asha/bleu
[main 0cf479c] Add BLEU metric skeleton
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 evalkit/bleu.py
$ git log -1 --format=fuller
commit 0cf479ca16372d2f084f0f13e3b109a1eafaa883
Author:     Asha Rao <asha@example.com>
AuthorDate: Mon Sep 7 10:05:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:08:00 2026 +0530

    Add BLEU metric skeleton
```
<!-- /snippet -->

The new commit, `0cf479c`, keeps Asha as author with her time, and records you as committer, three minutes later.

<!-- snippet: ch06/author-committer/02-author-option -->
```text
# Ravi mailed you evalkit/rouge.py from San Francisco. You commit it under his name and his date.
$ git add evalkit/rouge.py
$ git commit --author='Ravi Menon <ravi@example.com>' --date='2026-09-03T09:30:00-07:00' -m 'Add ROUGE-L metric skeleton'
[main c757945] Add ROUGE-L metric skeleton
 Author: Ravi Menon <ravi@example.com>
 Date: Thu Sep 3 09:30:00 2026 -0700
 1 file changed, 2 insertions(+)
 create mode 100644 evalkit/rouge.py
$ git cat-file -p HEAD
tree e0a2e8aeef531e14e6b6665551ead658c6e70782
parent 0cf479ca16372d2f084f0f13e3b109a1eafaa883
author Ravi Menon <ravi@example.com> 1788453000 -0700
committer Lab User <you@example.com> 1788756060 +0530

Add ROUGE-L metric skeleton
```
<!-- /snippet -->

The author can also be set by hand, here for a file that Ravi mailed from another time zone: `--author` and `--date`.

<!-- snippet: ch06/author-committer/03-dates -->
```text
$ git log -1 --format='author:    %ad%ncommitter: %cd'
author:    Thu Sep 3 09:30:00 2026 -0700
committer: Mon Sep 7 10:11:00 2026 +0530
$ git log -1 --format='author:    %ad%ncommitter: %cd' --date=iso-local
author:    2026-09-03 22:00:00 +0530
committer: 2026-09-07 10:11:00 +0530
$ git log -1 --format='author:    %ad%ncommitter: %cd' --date=unix
author:    1788453000
committer: 1788756060
```
<!-- /snippet -->

Three views of the same two instants. With the recorded offsets. With `--date=iso-local`, converted to your zone: Ravi's half past nine in the morning, at UTC minus 7, is ten in the evening at UTC plus five and a half hours. And with `--date=unix`, the stored seconds.

<!-- snippet: ch06/author-committer/04-who -->
```text
$ git log --format='%h  author: %an  committer: %cn  %s'
c757945  author: Ravi Menon  committer: Lab User  Add ROUGE-L metric skeleton
0cf479c  author: Asha Rao  committer: Lab User  Add BLEU metric skeleton
d4c9fab  author: Lab User  committer: Lab User  Add exact-match metric
$ git shortlog -sn HEAD
     1	Asha Rao
     1	Lab User
     1	Ravi Menon
$ git shortlog -sn --committer HEAD
     3	Lab User
$ git log --oneline --author=Asha
0cf479c Add BLEU metric skeleton
$ git log --oneline --committer=Asha
```
<!-- /snippet -->

Contribution counts depend on which identity is counted. By author, three people. By committer, one.

<!-- snippet: ch06/author-committer/05-amend -->
```text
# HEAD is the cherry-picked commit again: author Asha, committer you.
$ git commit --amend --no-edit
[main e79045d] Add BLEU metric skeleton
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 evalkit/bleu.py
$ git log -1 --format=fuller
commit e79045d6ec8bd3e6d974c4ce880488e9835e515a
Author:     Asha Rao <asha@example.com>
AuthorDate: Mon Sep 7 10:05:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:22:00 2026 +0530

    Add BLEU metric skeleton
$ git commit --amend --no-edit --reset-author
[main 42cbfdd] Add BLEU metric skeleton
 1 file changed, 2 insertions(+)
 create mode 100644 evalkit/bleu.py
$ git log -1 --format=fuller
commit 42cbfdd550e822dbb810fb7d8071b628b0b47db1
Author:     Lab User <you@example.com>
AuthorDate: Mon Sep 7 10:24:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:24:00 2026 +0530

    Add BLEU metric skeleton
```
<!-- /snippet -->

An amend 🟡 CAUTION keeps the author and renews the committer. `--reset-author` makes you the author as well.

**[TERMINAL]** Caption bar: `labs/ch06/date-filters.sh`.

```bash
labs/run ch06/date-filters
```

A commit written on the 24th of August and cherry-picked on the seventh of September.

<!-- snippet: ch06/date-filters/01-which-date-is-shown -->
```text
$ git log -1
commit 0e42f9ba14e36f898a645cbd664537470d01d9d0
Author: Asha Rao <asha@example.com>
Date:   Mon Aug 24 15:20:00 2026 +0530

    Add BLEU metric skeleton
$ git log --format='%h  authored %as  committed %cs  %an: %s'
0e42f9b  authored 2026-08-24  committed 2026-09-07  Asha Rao: Add BLEU metric skeleton
1c52ba8  authored 2026-08-10  committed 2026-08-10  Lab User: Add exact-match metric
```
<!-- /snippet -->

Plain `git log` shows the 24th of August. The format line shows both: authored in August, committed in September. Now the filter. Does `--since=2026-09-01` list this commit? Yes or no. Say your answer.

**[PAUSE]**

<!-- snippet: ch06/date-filters/02-which-date-is-filtered -->
```text
$ git log --oneline --since=2026-09-01
0e42f9b Add BLEU metric skeleton
$ git log --oneline --until=2026-09-01
1c52ba8 Add exact-match metric
$ git log --since=2026-09-01 --format='%h  Date: %ad' --date=short
0e42f9b  Date: 2026-08-24
```
<!-- /snippet -->

Yes, it does. And the last command prints the trap in one line: selected by `--since=2026-09-01`, displayed with the date 24 August. That's the CTO's first question, reproduced.

**[TERMINAL]** Caption bar: `labs/ch06/identity.sh`.

```bash
labs/run ch06/identity
```

<!-- snippet: ch06/identity/01-wrong-email -->
```text
$ git add evalkit/judge.py
$ git commit -q -m "Add judge client"
$ git log --format='%h  %an <%ae>  %s'
0d3dc20  Lab User <lab.user@personal.example>  Add judge client
6eab4a9  Lab User <you@example.com>  Add README
```
<!-- /snippet -->

The new commit carries a different email address from the one before it. Diagnose before you fix. Which two commands tell you what the next commit would record, and where the value comes from?

<!-- snippet: ch06/identity/02-diagnose -->
```text
$ git var GIT_AUTHOR_IDENT
Lab User <lab.user@personal.example> 1788755880 +0530
$ git config get --show-scope --show-origin --all user.email
global	file:$LAB/ch06/identity/home/.gitconfig	you@example.com
local	file:.git/config	lab.user@personal.example
```
<!-- /snippet -->

`git var GIT_AUTHOR_IDENT` prints the identity. `git config get --show-scope --show-origin --all user.email` shows two values: a global one and a local one in `.git/config`. The local one wins.

<!-- snippet: ch06/identity/03-fix -->
```text
$ git config unset user.email
$ git var GIT_AUTHOR_IDENT
Lab User <you@example.com> 1788756060 +0530
$ git commit --amend --no-edit --reset-author
[main 2f1be8c] Add judge client
 1 file changed, 2 insertions(+)
 create mode 100644 evalkit/judge.py
$ git log --format='%h  %an <%ae>  %s'
2f1be8c  Lab User <you@example.com>  Add judge client
6eab4a9  Lab User <you@example.com>  Add README
```
<!-- /snippet -->

Fix the cause first: `git config unset` 🟡 CAUTION removes the wrong setting. Then rewrite the unpublished commit with `--amend --no-edit --reset-author`.

<!-- snippet: ch06/identity/04-no-guessing -->
```text
# In this sandbox user.email is now configured nowhere.
$ git -c user.useConfigOnly=true commit --allow-empty -m "Re-run the nightly evaluation"
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: no email was given and auto-detection is disabled
[exit status: 128]
```
<!-- /snippet -->

With `user.useConfigOnly=true` and no email configured, Git refuses instead of guessing.

**[TERMINAL]** Caption bar: `labs/ch06/parents.sh`.

```bash
labs/run ch06/parents
```

<!-- snippet: ch06/parents/01-root -->
```text
$ git log --format='%h  parents: [%p]  %s'
191bbd1  parents: [bb904cd]  Document how to run the tests
bb904cd  parents: [d4c9fab]  Test exact match
d4c9fab  parents: []  Add exact-match metric
$ git rev-list --max-parents=0 HEAD
d4c9fabe9326ab4edbe04ed3a6f5f0b001bf6d86
```
<!-- /snippet -->

`%p` prints the parents. The oldest commit has none, and `git rev-list --max-parents=0` finds it.

<!-- snippet: ch06/parents/02-merge -->
```text
$ git merge --no-ff feature/f1
Merge made by the 'ort' strategy.
 evalkit/metrics.py    | 4 ++++
 tests/test_metrics.py | 4 ++++
 2 files changed, 8 insertions(+)
$ git cat-file -p HEAD
tree bc9f5dde767002a5a4e19d2bd8f0ccae4d29738e
parent 191bbd14a6ce45fcdc2b74169e84f8cbb54826ba
parent 59c914e58743f5a89da4758dfb73b1c93fc62b1e
author Lab User <you@example.com> 1788756120 +0530
committer Lab User <you@example.com> 1788756120 +0530

Merge branch 'feature/f1'
$ git log -1 --format=fuller
commit ae6795c6c675be2cdc3e275aceee9161491b5342
Merge: 191bbd1 59c914e
Author:     Lab User <you@example.com>
AuthorDate: Mon Sep 7 10:12:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:12:00 2026 +0530

    Merge branch 'feature/f1'
```
<!-- /snippet -->

`git merge --no-ff` 🟡 CAUTION. A merge commit is an ordinary commit object with a second `parent` line. Its tree is a complete snapshot like any other.

<!-- snippet: ch06/parents/03-navigate -->
```text
$ git log --oneline --graph
*   ae6795c Merge branch 'feature/f1'
|\  
| * 59c914e Test F1 on empty strings
| * 79ff6d7 Add F1 metric
* | 191bbd1 Document how to run the tests
|/  
* bb904cd Test exact match
* d4c9fab Add exact-match metric
$ git log -1 --format='%h %s' 'HEAD^1'
191bbd1 Document how to run the tests
$ git log -1 --format='%h %s' 'HEAD^2'
59c914e Test F1 on empty strings
$ git log -1 --format='%h %s' 'HEAD~2'
bb904cd Test exact match
$ git log -1 --format='%h %s' 'HEAD^2~1'
79ff6d7 Add F1 metric
$ git rev-parse --verify --quiet 'HEAD^3'
[exit status: 1]
```
<!-- /snippet -->

Check your paper answers against the real output: `HEAD^1`, `HEAD^2`, `HEAD~2` and `HEAD^2~1`. And `HEAD^3`? This merge has two parents, so there's no third, and the command exits with status 1.

<!-- snippet: ch06/parents/04-two-diffs -->
```text
$ git diff --stat 'HEAD^1' HEAD
 evalkit/metrics.py    | 4 ++++
 tests/test_metrics.py | 4 ++++
 2 files changed, 8 insertions(+)
$ git diff --stat 'HEAD^2' HEAD
 README.md | 2 ++
 1 file changed, 2 insertions(+)
$ git log --oneline --first-parent
ae6795c Merge branch 'feature/f1'
191bbd1 Document how to run the tests
bb904cd Test exact match
d4c9fab Add exact-match metric
```
<!-- /snippet -->

A merge commit has one diff per parent. Against the first parent, you see what the merge brought into `main`. Against the second, what `main` had that the feature branch lacked. `--first-parent` lists what happened to `main` itself, one line per merge.

<!-- snippet: ch06/parents/05-log-basics -->
```text
$ git log --oneline -3
ae6795c Merge branch 'feature/f1'
191bbd1 Document how to run the tests
59c914e Test F1 on empty strings
$ git log -1 --stat feature/f1
commit 59c914e58743f5a89da4758dfb73b1c93fc62b1e
Author: Asha Rao <asha@example.com>
Date:   Mon Sep 7 10:07:00 2026 +0530

    Test F1 on empty strings

 tests/test_metrics.py | 4 ++++
 1 file changed, 4 insertions(+)
$ git log --format='%h %ad %an: %s' --date=short --no-merges -3
191bbd1 2026-09-07 Lab User: Document how to run the tests
59c914e 2026-09-07 Asha Rao: Test F1 on empty strings
79ff6d7 2026-09-07 Asha Rao: Add F1 metric
$ git log --oneline -- README.md
191bbd1 Document how to run the tests
d4c9fab Add exact-match metric
```
<!-- /snippet -->

## COMMON MISTAKES

Five mistakes to watch for.

1. **Calling a commit dated last month in "changes since Monday" a bug.** Root cause: `git log` prints the author date, and `--since` selects by committer date.
2. **Reading "author differs from committer" as tampering.** Root cause: cherry-pick, rebase and amend copy the author and renew the committer; commits created on GitHub carry a GitHub committer address.
3. **Commits carry the wrong name or email.** Root cause: a repository-local `user.email` overrides the global one; `git config get --show-origin --all user.email` shows both.
4. **Using `HEAD^2` where `HEAD~2` was meant.** Root cause: caret selects among the parents of one commit, tilde follows first parents.
5. **Taking the line below a merge in `git log` for the previous state of the branch.** Root cause: plain `git log` interleaves both sides of a merge by date; use `HEAD^1` or `--first-parent`.

## PRODUCTION EXAMPLE

Now, out of the lab. A team builds its weekly report with `git log --since`. After a large branch is rebased and merged, the report counts every commit of that branch as new, while plain `git log` shows dates from weeks ago. The textbook explains it: after a rebase, every commit of the branch has the rebase time as committer date and the original time as author date. Its advice: for release notes, select by a range between two tags, not by date. In an audit, print both dates with `--format=fuller`.

And the release manager from the hook? Her commits were made in a repository with a leftover local `user.email` that matches no address on her GitHub account, so GitHub can't link them. Nobody else pushed. The prevention the textbook lists: `user.useConfigOnly=true`, and per-directory identity with `includeIf`, which video 28 covers.

## PRACTICE EXERCISE

Your turn. Do Exercise 3.2, Level 1, "author and committer", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Before each operation in the exercise, predict the four values of `--format=fuller`: author, author date, committer, committer date.

## INTERVIEW QUESTION

Q32: "Explain author and committer with three operations that make them differ. Which date does `git log` print, and which one does `--since` use?"

**[PAUSE]**

Answer out loud. A strong answer defines the two roles by what each person did, names three operations and says what each keeps and what it renews, and then answers the two date questions and explains why Git needs the second date at all. End with the consequence for a report.

## RECAP

Let's land this. You should now be able to say, in your own words: the author wrote the change and the committer created this commit object. Each has a name, an email, a time and an offset. Cherry-pick, rebase and amend keep the author and renew the committer. `git log` prints the author date. `--since` and `--until` filter on the committer date. Identity is copied from the environment or the configuration and checked by nobody. `git var GIT_AUTHOR_IDENT` and `git config get --show-origin` diagnose it.

**[ANIMATION]** step: state-1

A commit has zero, one or several ordered parents. `^n` picks the n-th parent and `~n` walks n first parents.

## HOMEWORK

- Read sections 6.5 and 6.6 of [Chapter 6](../../textbook/ch06-commits.md).
- Do Exercise 3.3, Level 1, "zero, one and two parents", and Exercise 3.5, Level 2, "which date is shown, which date filters?", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
- Challenge: Exercise 3.8, Level 3, "the commit that `--author` does not find", in the same file.

Today you answered both of the CTO's questions from three lines of a commit object. Do the author and committer exercise before the next video. Next time: amend, empty commits, trailers, messages and atomic commits. Until then, look at the state first and type second. See you in the next one.
