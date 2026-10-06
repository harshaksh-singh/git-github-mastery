# Chapter 13: Recovery

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch13/`.

## 13.1 Why this matters

It is 18:40 on a release day. An engineer on your team writes in the incident channel: "I ran a reset and three days of work on the reranker are gone." Your CTO asks you two questions, and neither of them is "which command do we type". The first is "can we get it back?". The second is "how sure are you, and how long do we have?".

Both questions have exact answers. They depend on three facts about the lost work:

1. **Was it ever written into the object database?** A commit was. A file that was staged with `git add` was. An edit that was only saved in the editor was not.
2. **Does anything still name it?** A branch, a tag, a remote-tracking ref, a stash entry, a reflog entry, or another repository.
3. **Has the clock run out?** Reflog entries expire, and objects that nothing names are deleted after a grace period, but only when maintenance runs.

This chapter teaches you to answer those three questions from evidence, for fifteen kinds of accident: nine that lose commits (section 13.8), two that lose uncommitted work (13.9), two that involve the server (13.10), and two that damage the repository itself (13.11). It also teaches the opposite skill, which a senior engineer needs as much: to say "this cannot be recovered, and here is exactly why".

Three earlier chapters supply the foundations, and this one does not repeat them. [Chapter 3: Git Internals](ch03-git-internals.md) defines reachability, shows the reflog files under `.git/logs`, and introduces `git fsck`. [Chapter 11: Reset, Revert, Restore](ch11-reset-revert-restore.md) proves what `git reset --hard` destroys and explains the stash. [Chapter 12: Remote Operations](ch12-remote-operations.md) explains force pushes and remote-tracking refs. Here those pieces become procedures.

The transcripts in sections 13.8 to 13.11 come from the replays of the twelve disaster labs of Module 12. You meet each incident twice: here with the explanation, and in the [lab manual](../lab-manual/m12-recovery.md) with your own hands.

## 13.2 What Git keeps: four layers of protection

**In one sentence.** Git never deletes an object that something still names, it keeps a private log of every name that recently changed, and it waits before deleting what nothing names; work is lost only when it was never an object or when all of these protections are gone.

**Analogy.** A bank vault with a ledger. The safe-deposit boxes are objects. The index cards at the front desk are refs: each card names one box. When a card is rewritten, the clerk notes the old box number in a ledger, the reflog. Boxes that no card and no ledger line mentions are emptied in a periodic clear-out, but only boxes that have been untouched for two weeks. The analogy breaks in two places. A box in Git also holds the numbers of older boxes (a commit names its parents and its tree), so one card protects a whole chain. And the ledger is private to one branch office: no other clone, and no server, sees your reflog.

**Precisely.** An object is kept as long as it is reachable from a starting point. The manual of `git gc` lists the starting points: branches and tags, the index, remote-tracking branches, reflogs, "and anything else in the refs/* namespace" (`git help gc`, section NOTES). The same section adds one exclusion: a note attached to an object does not keep it alive. An object that no starting point reaches is unreachable. It still exists until a collection deletes it, and a collection deletes only objects older than a cut-off, two weeks by default (`gc.pruneExpire`).

That gives four layers, and a recovery is always a move from a lower layer back to the first one:

| Layer | What protects the object | Lifetime by default | Tool that finds it |
|---|---|---|---|
| 1. Refs | A branch, tag, remote-tracking ref, `refs/stash`, HEAD, or the index names it | Until the ref is moved or deleted | `git log --all`, `git for-each-ref` |
| 2. Reflogs | A reflog entry names it | 90 days, or 30 days for entries off the current history (section 13.4) | `git reflog`, `git log -g` |
| 3. Grace period | Nothing names it; the object file is younger than the prune cut-off | Two weeks from the time the object was written, then until the next collection runs | `git fsck` |
| 4. Other repositories | Another clone, the server, a bundle, a backup | Independent of this repository | `git fetch`, `git bundle`, a teammate |

Before the layers comes a precondition, the question from section 13.1: was the work ever an object?

| Form of the work | Object written? | Named by |
|---|---|---|
| Committed | Yes: commit, trees, blobs | A branch or HEAD, and the reflog |
| Stashed | Yes: two or three commits (Chapter 11, section 11.11) | `refs/stash` and its reflog |
| Staged with `git add`, not committed | Yes: a blob | Only the index entry |
| Saved in the working tree, never staged | No | Nothing in Git |
| Untracked or ignored file | No | Nothing in Git |

**Inside `.git`.** Layer 1 is `refs/`, `packed-refs`, `HEAD` and `index`. Layer 2 is `logs/`. Layer 3 is the modification time of files under `objects/`: of loose objects, and of the `.mtimes` file that accompanies a cruft pack (section 13.13). Layer 4 is not in this `.git` at all.

**See it.** A commit that was removed from its branch with `git reset --hard` 🔴 is on layer 2. A collection with no grace period at all, `git gc --prune=now` 🔴, does not touch it, because the reflog names it:

<!-- snippet: ch13/gc-ladder/01-reflog-protects -->
```text
$ git reflog -2
da62b60 HEAD@{0}: reset: moving to HEAD~1
dbe6ec8 HEAD@{1}: commit: Add cache TTL
$ git prune -n
$ git gc --prune=now
$ git cat-file -t dbe6ec8
commit
$ git count-objects -v | grep -e "^count" -e in-pack
count: 0
in-pack: 12
```
<!-- /snippet -->

`git prune -n` lists what an immediate prune would delete: nothing. `git gc --prune=now` packed all twelve objects, the lost commit `dbe6ec8` included. Section 13.13 takes the same commit down the remaining layers.

**Picture.**

```text
  layer 1   refs/heads/main ----------------> da62b60 --> parents, trees, blobs      kept
            index, HEAD, tags, refs/stash

  layer 2   reflog entry HEAD@{1} ----------> dbe6ec8 --> tree, blob                 kept while the entry lives
            (.git/logs/HEAD)

  layer 3   nothing ------------------------> a staged blob, a pruned fetch          kept until a collection
                                                                                     finds it older than the cut-off

  layer 4   another repository -------------> its own copy of the objects            not affected by this one
```

**In production.** The first minute of a recovery is classification, not typing. "Committed on a branch that was deleted" is layer 2 or 3 and almost always recoverable. "Edited in the editor and then `git restore`" was never an object, so you move on to editor history and backups at once.

## 13.3 The reflog

**In one sentence.** A reflog is a local, append-only list of the values a ref has had, with the time, the person and the command behind each change, and every one of those old values is a name you can use.

**Analogy.** The "undo history" of an editor, kept per document. The analogy breaks in two places. A reflog has no undo command: it gives you old positions, and you decide what to do with them. And it records movements of refs only. Edits to files, staging and unstaging leave no entry.

**Precisely.** There is one reflog per ref that has logging enabled, plus one for HEAD. With the default `core.logAllRefUpdates=true` of a repository that has a working tree, Git logs HEAD, branches, remote-tracking branches and notes refs; tags get no reflog unless the setting is `always` (Chapter 3, section 3.11). Each entry stores the value before the change, the value after it, the committer identity and time, and a message written by the command. `git reflog` is `git reflog show HEAD`, and the manual defines `git reflog show` as an alias for `git log -g --abbrev-commit --pretty=oneline` (`git help reflog`). 🟢 SAFE: all of these read.

The two kinds of reflog answer different questions:

| Reflog | Records | Use it to answer |
|---|---|---|
| `HEAD` | Every movement of HEAD: commits, switches, resets, each step of a rebase, merges, cherry-picks | "What did I do, in order?" It is the only log that sees detached HEAD |
| A branch, for example `main` | Only changes of that branch's value | "Where was this branch before the operation?" A whole rebase is one entry |

**Inside `.git`.** `logs/HEAD` and `logs/refs/heads/<branch>`, one line per change. A command that moves the current branch appends to both files.

**See it.** A small history: a branch, a commit, an amend, a fast-forward merge, and a reset that takes the merge back.

<!-- snippet: ch13/reflog-anatomy/01-make-history -->
```text
$ git switch -c feature/rerank
Switched to a new branch 'feature/rerank'
$ printf 'def rerank(q, docs):\n    return sorted(docs)\n' > rerank.py
$ git add rerank.py
$ git commit -q -m "Add reranker"
$ git commit -q --amend -m "Add cross-encoder reranker"
$ git switch main
Switched to branch 'main'
$ git merge -q feature/rerank
$ git reset -q --hard HEAD~1
```
<!-- /snippet -->

<!-- snippet: ch13/reflog-anatomy/02-head-reflog -->
```text
$ git reflog
da62b60 HEAD@{0}: reset: moving to HEAD~1
f1f247e HEAD@{1}: merge feature/rerank: Fast-forward
da62b60 HEAD@{2}: checkout: moving from feature/rerank to main
f1f247e HEAD@{3}: commit (amend): Add cross-encoder reranker
14a18d6 HEAD@{4}: commit: Add reranker
da62b60 HEAD@{5}: checkout: moving from main to feature/rerank
da62b60 HEAD@{6}: commit: Raise top_k to 10
536f5df HEAD@{7}: commit: Add embedding client
538ea2f HEAD@{8}: commit (initial): Add retriever config
```
<!-- /snippet -->

Read it from the bottom. Each line is "the value HEAD had after this event". `HEAD@{0}` is always the current value. The amend at `HEAD@{3}` replaced `14a18d6` with `f1f247e`; the old commit is still listed one line below. The two `checkout` lines record branch switches, which change HEAD and no branch.

<!-- snippet: ch13/reflog-anatomy/03-branch-reflogs -->
```text
$ git reflog show main
da62b60 main@{0}: reset: moving to HEAD~1
f1f247e main@{1}: merge feature/rerank: Fast-forward
da62b60 main@{2}: commit: Raise top_k to 10
536f5df main@{3}: commit: Add embedding client
538ea2f main@{4}: commit (initial): Add retriever config
$ git reflog show feature/rerank
f1f247e feature/rerank@{0}: commit (amend): Add cross-encoder reranker
14a18d6 feature/rerank@{1}: commit: Add reranker
da62b60 feature/rerank@{2}: branch: Created from HEAD
$ git reflog list
HEAD
refs/heads/feature/rerank
refs/heads/main
```
<!-- /snippet -->

The reflog of `main` has five lines where HEAD has nine: the switches and the work on the other branch are absent. `git reflog list` (Git 2.45 and later) names every ref that has a log.

A reflog entry is addressed with a selector, and a selector is a revision that every command accepts:

<!-- snippet: ch13/reflog-anatomy/04-selectors -->
```text
# Position: the n-th previous value of HEAD, of a branch, of the current branch.
$ git rev-parse --short 'HEAD@{1}'
f1f247e
$ git rev-parse --short 'main@{2}'
da62b60
$ git rev-parse --short '@{1}'
f1f247e
# The n-th branch checked out before the current one.
$ git rev-parse --abbrev-ref '@{-1}'
feature/rerank
# A selector is a revision like any other.
$ git diff --stat 'main@{1}' main
 rerank.py | 2 --
 1 file changed, 2 deletions(-)
```
<!-- /snippet -->

| Selector | Meaning |
|---|---|
| `HEAD@{2}` | The value HEAD had two changes ago |
| `main@{1}` | The value `main` had before its latest change |
| `@{1}` | The same, for the current branch (not for HEAD: on `main`, `@{1}` is `main@{1}`) |
| `main@{yesterday}`, `main@{2026-09-07 10:10:30}`, `HEAD@{5.minutes.ago}` | The value the ref had at that time, according to this repository's log |
| `@{-1}` | The branch that was checked out before the current one. This is a name, not a position, and `git switch -` uses it |

Quote selectors in the shell: braces are special to some shells.

Time-based selectors read the timestamps in the log:

<!-- snippet: ch13/reflog-anatomy/05-time -->
```text
$ git reflog --date=iso -4
da62b60 HEAD@{2026-09-07 10:13:00 +0530}: reset: moving to HEAD~1
f1f247e HEAD@{2026-09-07 10:12:00 +0530}: merge feature/rerank: Fast-forward
da62b60 HEAD@{2026-09-07 10:11:00 +0530}: checkout: moving from feature/rerank to main
f1f247e HEAD@{2026-09-07 10:10:00 +0530}: commit (amend): Add cross-encoder reranker
$ git rev-parse --short 'main@{2026-09-07 10:10:30}'
da62b60
$ git rev-parse --short 'HEAD@{5.minutes.ago}'
da62b60
$ git rev-parse --short 'main@{2.days.ago}'
warning: log for 'main' only goes back to Mon, 7 Sep 2026 10:03:00 +0530
538ea2f
```
<!-- /snippet -->

At 10:10:30 `main` was still at `da62b60`, because the merge happened at 10:12. The last command asks for a time before the log begins. Git answers with the oldest value it knows and says so in a warning. A time selector is therefore a statement about your local log, never about the project: in a clone made today, `main@{1.week.ago}` cannot know where `main` was a week ago.

`git log -g` walks a reflog instead of the ancestry, and it has placeholders for the reflog fields:

<!-- snippet: ch13/reflog-anatomy/06-log-g -->
```text
$ git log -g --format='%h %gd %gs' -4
da62b60 HEAD@{0} reset: moving to HEAD~1
f1f247e HEAD@{1} merge feature/rerank: Fast-forward
da62b60 HEAD@{2} checkout: moving from feature/rerank to main
f1f247e HEAD@{3} commit (amend): Add cross-encoder reranker
$ git log -g --date=relative --format='%h %gd | %gn | %s' -3 main
da62b60 main@{15 minutes ago} | Lab User | Raise top_k to 10
f1f247e main@{16 minutes ago} | Lab User | Add cross-encoder reranker
da62b60 main@{23 minutes ago} | Lab User | Raise top_k to 10
$ git log -g --format='%h %gd %gs' --grep-reflog='^commit'
f1f247e HEAD@{3} commit (amend): Add cross-encoder reranker
14a18d6 HEAD@{4} commit: Add reranker
da62b60 HEAD@{6} commit: Raise top_k to 10
536f5df HEAD@{7} commit: Add embedding client
538ea2f HEAD@{8} commit (initial): Add retriever config
```
<!-- /snippet -->

`%gd` is the selector, `%gs` the reflog message, `%gn` the name of the person who made the change; with `--date`, the selector shows the time instead of the position. `--grep-reflog` filters by reflog message. The third command lists only the entries that created commits, which is how you search a long log for the event you need instead of counting positions.

On disk, one event on the current branch is two lines, one in each file:

<!-- snippet: ch13/reflog-anatomy/07-on-disk -->
```text
$ tail -2 .git/logs/HEAD
da62b6073a1d8c0afa10417bc244ed245ccdff86 f1f247eb281770cea385642df710bd095c262b17 Lab User <you@example.com> 1788756120 +0530	merge feature/rerank: Fast-forward
f1f247eb281770cea385642df710bd095c262b17 da62b6073a1d8c0afa10417bc244ed245ccdff86 Lab User <you@example.com> 1788756180 +0530	reset: moving to HEAD~1
$ tail -1 .git/logs/refs/heads/main
f1f247eb281770cea385642df710bd095c262b17 da62b6073a1d8c0afa10417bc244ed245ccdff86 Lab User <you@example.com> 1788756180 +0530	reset: moving to HEAD~1
$ cat .git/refs/heads/main
da62b6073a1d8c0afa10417bc244ed245ccdff86
```
<!-- /snippet -->

The first ID of a line is the old value and the second the new one. That is more than `git reflog` prints, and it matters: the old value of the newest line tells you where a ref was even when no older line exists (section 13.4 shows a server log that starts this way).

**Picture.**

```text
  one command:  git reset --hard HEAD~1     (on main)

  .git/refs/heads/main      f1f247e  ->  da62b60          the ref itself: only the new value
  .git/logs/refs/heads/main f1f247e da62b60 ... reset: moving to HEAD~1     main@{0}, and main@{1} = f1f247e
  .git/logs/HEAD            f1f247e da62b60 ... reset: moving to HEAD~1     HEAD@{0}, and HEAD@{1} = f1f247e
```

**In production.** Read the branch reflog, not the HEAD reflog, when the question is "where was this branch": it has one line per operation, where HEAD has one line per step. In an incident note, record the full ID, not the selector. `main@{1}` means something else after the next command, and nothing at all on a colleague's machine.

## 13.4 Retention: how long the safety net lasts, and its exceptions

**The defaults.** Three numbers govern recoverability in a repository with default configuration ([gc configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/gc.adoc), and `git help gc` on your machine):

| Setting | Default | What it removes |
|---|---|---|
| `gc.reflogExpire` | 90 days | Reflog entries older than this |
| `gc.reflogExpireUnreachable` | 30 days | Reflog entries older than this that are "not reachable from the current tip" |
| `gc.pruneExpire` | 2 weeks | Unreachable objects whose file is older than this |

The lab configuration overrides the first two with `never` (Chapter 1, section 1.7), because the lab clock is fixed and the expiry code reads the real clock. Everything in this section that concerns the 90 and 30 days is therefore stated from the manual, and the transcripts use only cut-offs that do not depend on a clock.

Two facts about these numbers are routinely misunderstood.

First, nothing happens when the time is up. Expiry is work done by a command: `git gc`, `git reflog expire`, or the maintenance that Git starts after some commands (section 13.13). An entry that is 100 days old is still there until one of them runs.

Second, the 30-day rule is the one that matters for recovery, because it is the one that applies to the entries you recover from. The manual explains what such entries are: they "are generally created as a result of using `git commit --amend` or `git rebase` and are the commits prior to the amend or rebase occurring". The exact test is in the source ([reflog.c](https://github.com/git/git/blob/v2.55.0/reflog.c)): an entry is subject to the shorter period if its old value or its new value is not reachable from the ref's current tip. For the HEAD reflog the code tests against the tips of all refs. You can ask Git which entries those are, with a cut-off of `now` and `--dry-run`:

<!-- snippet: ch13/reflog-retention/01-which-entries -->
```text
$ git reflog show main
dfcbd4b main@{0}: reset: moving to HEAD~1
5c75388 main@{1}: commit: Temporary debug flag
dfcbd4b main@{2}: commit (amend): Raise top_k from 5 to 10
da62b60 main@{3}: commit: Raise top_k to 10
536f5df main@{4}: commit: Add embedding client
538ea2f main@{5}: commit (initial): Add retriever config
# Which entries does the 30-day rule apply to? Ask with a cut-off of "now" and --dry-run:
$ git reflog expire --dry-run --verbose --expire-unreachable=now refs/heads/main
keep commit (initial): Add retriever config
keep commit: Add embedding client
prune commit: Raise top_k to 10
prune commit (amend): Raise top_k from 5 to 10
prune commit: Temporary debug flag
prune reset: moving to HEAD~1
# It was a dry run. All six entries are still there:
$ git reflog show main | grep -c main@
6
```
<!-- /snippet -->

The branch was amended, extended by one commit, and reset by one commit. Four of six entries fall under the shorter rule: the commit before the amend, the commit that was reset away, and also the two entries whose *other* end is one of those commits. The amend entry is marked because its old value is the replaced commit, and the reset entry because its old value is the discarded commit. Despite the word `prune`, the dry run removed nothing, as the count shows.

When the expiry is carried out, the reflog of the branch loses exactly the lines a recovery would need:

<!-- snippet: ch13/reflog-retention/02-after-expiry -->
```text
$ git reflog expire --expire-unreachable=now refs/heads/main
$ git reflog show main
536f5df main@{0}: commit: Add embedding client
538ea2f main@{1}: commit (initial): Add retriever config
$ git log --oneline -1 main
dfcbd4b Raise top_k from 5 to 10
$ git reflog -3
dfcbd4b HEAD@{0}: reset: moving to HEAD~1
5c75388 HEAD@{1}: commit: Temporary debug flag
dfcbd4b HEAD@{2}: commit (amend): Raise top_k from 5 to 10
```
<!-- /snippet -->

```text
Observed behavior : "git reflog show main" starts at "Add embedding client", but main points at dfcbd4b
Git state         : refs/heads/main = dfcbd4b; the newest line left in logs/refs/heads/main records 536f5df
Mechanism         : reflog expiry removed every entry with an end that the current tip does not reach,
                    including the entries that moved the branch to its current value
Root cause        : a reflog is a list of past changes that is trimmed by a retention policy; it is not
                    a second copy of the ref
Why Git does this : such changes "are not part of the current project", so "most users will want to
                    expire them sooner" (git help gc)
Correct fix       : none needed; the ref is right and the log is shorter
Prevention        : anchor anything you may want later with a branch or tag before the 30 days are over
```

The HEAD reflog was not named in that command and still has every entry. In a real repository both logs are trimmed in the same run.

**The grace period is not added on top.** A common summary is "30 days in the reflog, then two more weeks". The manual does not promise that. `gc.pruneExpire` compares the cut-off with the modification time of the object: "Any object with modification time newer than the `--prune` date is kept, along with everything reachable from it", and most operations that would write an object that already exists refresh that time (`git help gc`, section NOTES). The two weeks are measured against that modification time, not from the moment the object became unreachable. A commit that was written 40 days ago, has not been touched since, and loses its last reflog entry today may already be older than the cut-off. The grace period protects what never had a reflog entry and was written recently: a blob you staged yesterday, a branch you fetched last week and pruned today. The lab cannot age a file, so this is the manual's statement, not a demonstration.

**Picture.** The life of a commit that was replaced by `git commit --amend`, in a repository with default settings:

```text
  day 0            amend: the old commit leaves the branch.   Layer 2: two reflogs name it.
  day 0 to 30      "git reset --hard <id>" or "git branch <name> <id>" brings it back.
  after day 30     the next maintenance run removes those reflog entries.   Layer 3, or gone:
                   the object file is older than two weeks, so the same run may delete it.
  later            a collection deletes whatever is unreachable and older than the cut-off.
```

### The exceptions

Four situations give you less than the table promises, and one gives you more.

**A deleted branch loses its reflog at once.** The manual of `git branch` says so for `-d` and `-D`: "If the branch currently has a reflog then the reflog will also be deleted." The commits stay reachable from the HEAD reflog if you ever had the branch checked out, and section 13.8 uses that. The same holds for a remote-tracking branch that `git fetch --prune` 🟡 removes.

**A commit that was never checked out has no HEAD reflog entry.** A teammate's branch that you only fetched exists in your clone as a remote-tracking ref. When that ref is pruned, nothing names the commits, and they are on layer 3 from that moment.

**A bare repository keeps no reflogs by default.** `core.logAllRefUpdates` is "true by default in a repository that has a working directory associated with it, and false by default in a bare repository" ([core configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/core.adoc)). A server that receives a force push therefore has no record of the value that was overwritten:

<!-- snippet: ch13/reflog-retention/07-bare -->
```text
$ git -C searchsvc push -q origin main
$ git -C server.git reflog list
$ git -C server.git config get core.logAllRefUpdates
[exit status: 1]
$ git -C searchsvc config get core.logAllRefUpdates
true
```
<!-- /snippet -->

Whoever administers a bare repository can change that (`git config set` and `git config get` need Git 2.46 or later). From then on a push is an entry, and the overwritten value of a forced push can be read back:

<!-- snippet: ch13/reflog-retention/08-bare-with-reflog -->
```text
# Whoever runs a bare repository can switch reflogs on:
$ git -C server.git config set core.logAllRefUpdates true
$ git -C searchsvc commit -q --amend -m "Raise top_k to ten"
$ git -C searchsvc push -q --force origin main
$ git -C server.git reflog show main
803db47 main@{0}: push
$ git -C server.git log --oneline -1 'main@{1}'
dfcbd4b Raise top_k from 5 to 10
```
<!-- /snippet -->

The log has one line, and `main@{1}` still resolves: Git takes the old value recorded in that line. It is a setting for servers you run yourself; a hosting service has its own instruments (section 13.15).

**Tags have no reflog.** Moving a tag with `git tag -f` prints the old ID once (`Updated tag 'v1' (was ...)`), and that line is the only record.

**Stash entries do not expire, until they are dropped.** The stash list is the reflog of `refs/stash`, and Git's expiry code exempts that ref when nothing is configured for it: the comment in the source reads "If unconfigured, make stash never expire" ([reflog.c, lines 117 to 126](https://github.com/git/git/blob/v2.55.0/reflog.c#L117-L126); no manual page states it). An entry removed with `git stash drop` 🔴, `pop` or `clear` 🔴 is a different matter: it has left the reflog, and the stash manual says that such entries "cannot be recovered through the normal safety mechanisms". Section 13.9 recovers them from layer 3.

The exemption applies to the default periods only. A cut-off given on the command line applies to every ref, `refs/stash` included, and the result is one of the stranger states Git can be in:

<!-- snippet: ch13/reflog-retention/04-stash -->
```text
$ printf 'top_k: 20\n' > retriever.yaml
$ git stash push -q -m "try top_k 20"
$ printf 'top_k: 50\n' > retriever.yaml
$ git stash push -q -m "try top_k 50"
$ git stash list
stash@{0}: On main: try top_k 50
stash@{1}: On main: try top_k 20
$ git reflog show refs/stash
71ed40a refs/stash@{0}: On main: try top_k 50
89fc6b8 refs/stash@{1}: On main: try top_k 20
```
<!-- /snippet -->

<!-- snippet: ch13/reflog-retention/05-stash-after-expire -->
```text
$ git reflog expire --expire=now --all
$ git stash list
$ git log --oneline -1 refs/stash
71ed40a On main: try top_k 50
$ git fsck
dangling commit 89fc6b87236ad6fbf9108422f65174e9dfc095dd
dangling commit da62b6073a1d8c0afa10417bc244ed245ccdff86
dangling commit 5c7538866f5b5c9cfc3186aa957123a55108d5a0
```
<!-- /snippet -->

```text
Observed behavior : "git stash list" prints nothing after "git reflog expire --expire=now --all"
Git state         : refs/stash still points at 71ed40a, the newest entry; its log is empty;
                    the older entry 89fc6b8 is a dangling commit
Mechanism         : "git stash list" prints the reflog of refs/stash. The command emptied the log
                    and left the ref alone
Root cause        : only the newest stash entry is held by a ref. Every older entry is held by a
                    reflog line and by nothing else
Why Git does this : the stash was built as one ref plus its reflog, so that "stash@{n}" is ordinary
                    reflog syntax
Correct fix       : "git stash pop" still restores the newest entry (below). The older ones are found
                    with git fsck while their objects exist
Prevention        : do not expire reflogs with --all in a repository that holds stashes you need;
                    commit long-lived work to a branch instead of stashing it
```

<!-- snippet: ch13/reflog-retention/06-stash-rescue -->
```text
$ git stash pop
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   retriever.yaml

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (71ed40a90f00616a336fa87d8470ab2abfc42ce6)
$ git stash list
$ git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'
71ed40a On main: try top_k 50
89fc6b8 On main: try top_k 20
```
<!-- /snippet -->

### Removing entries by hand

`git reflog expire` 🔴 removes entries by age and reachability; `--expire=<time>` and `--expire-unreachable=<time>` override the two settings for one run, `--all` processes every ref, and `-n` previews. `git reflog delete <ref>@{<n>}` 🔴 removes single entries, and `git reflog drop <ref>` 🔴 (Git 2.50 and later) removes the whole log of a ref. The manual calls `expire` and `delete` "typically not used directly by end users". None of them changes a ref or deletes an object. What they remove is the name that kept an object on layer 2:

<!-- snippet: ch13/reflog-retention/03-delete-and-drop -->
```text
# delete removes one entry, drop removes the whole log of a ref. Neither touches the ref.
$ git reflog delete 'HEAD@{1}'
$ git reflog -3
dfcbd4b HEAD@{0}: reset: moving to HEAD~1
dfcbd4b HEAD@{1}: commit (amend): Raise top_k from 5 to 10
da62b60 HEAD@{2}: commit: Raise top_k to 10
$ git reflog drop refs/heads/main
$ git reflog exists refs/heads/main
[exit status: 1]
$ git log --oneline -1 main
dfcbd4b Raise top_k from 5 to 10
```
<!-- /snippet -->

`git stash drop` is the everyday user of this machinery: it deletes one entry from the reflog of `refs/stash` and updates the ref to match ([builtin/stash.c](https://github.com/git/git/blob/v2.55.0/builtin/stash.c), function `do_drop_stash`). Section 13.13 returns to `git reflog expire` as the first half of the point of no return.

## 13.5 `ORIG_HEAD`: one slot, written by four commands

**In one sentence.** `ORIG_HEAD` is a file that holds the commit HEAD pointed at before the last "drastic" command, so that the command can be undone with `git reset --hard ORIG_HEAD`.

**Analogy.** The "last number redial" button of a phone. It holds exactly one number, the newest call replaces it, and it tells you nothing about which call that was. The reflog is the full call list.

**Precisely.** The manual: `ORIG_HEAD` "is created by commands that move your HEAD in a drastic way (`git am`, `git merge`, `git rebase`, `git reset`), to record the position of the HEAD before their operation" (`git help revisions`). `git pull` writes it too, because it runs a merge or a rebase. So does `git stash push`, through the reset it performs (Chapter 11, section 11.4). Commands that move HEAD in an ordinary way do not write it.

**Inside `.git`.** One file, `.git/ORIG_HEAD`, containing one ID. It has no reflog, and it is not a starting point for garbage collection (section 13.13 proves that).

**See it.** A fresh repository has no `ORIG_HEAD`. Four commands that move HEAD leave it that way:

<!-- snippet: ch13/orig-head/01-not-written -->
```text
$ git log --oneline --graph --all
* 584d822 Add README
| * 68e6fff Rerank the top 20
| * 155d4ba Add reranker
|/  
* da62b60 Raise top_k to 10
* 536f5df Add embedding client
* 538ea2f Add retriever config
# A fresh repository has no ORIG_HEAD. These four commands move HEAD and do not create it:
$ git commit -q --amend -m "Add a README"
$ git switch -q feature/rerank && git switch -q main
$ git cherry-pick feature/rerank~1 > /dev/null
$ git revert --no-edit HEAD > /dev/null
$ git rev-parse --verify --short ORIG_HEAD
fatal: Needed a single revision
[exit status: 128]
$ git reflog -4
78070c2 HEAD@{0}: revert: Revert "Add reranker"
1ab399b HEAD@{1}: cherry-pick: Add reranker
f912289 HEAD@{2}: checkout: moving from feature/rerank to main
68e6fff HEAD@{3}: checkout: moving from main to feature/rerank
```
<!-- /snippet -->

An amend, two switches, a cherry-pick and a revert: five movements of HEAD, each with a reflog entry, and no `ORIG_HEAD`. A reset, a merge and a rebase each write it:

<!-- snippet: ch13/orig-head/02-reset -->
```text
$ git reset -q --hard HEAD~2
$ git log --oneline -1 ORIG_HEAD
78070c2 Revert "Add reranker"
```
<!-- /snippet -->

<!-- snippet: ch13/orig-head/03-merge -->
```text
$ git log --oneline -1
f912289 Add a README
$ git merge -q feature/rerank
$ git log --oneline -1 ORIG_HEAD
f912289 Add a README
```
<!-- /snippet -->

<!-- snippet: ch13/orig-head/04-rebase -->
```text
$ git reset -q --hard ORIG_HEAD
$ git switch -q feature/rerank
$ git log --oneline -1
68e6fff Rerank the top 20
$ git rebase -q main
$ git log --oneline -1 ORIG_HEAD
68e6fff Rerank the top 20
```
<!-- /snippet -->

Each time the value is the tip from immediately before the command. The trap is the other list. After a command that does not write the slot, the slot still holds the value from an earlier one:

<!-- snippet: ch13/orig-head/05-stale -->
```text
# A later command that does not write ORIG_HEAD leaves the old value in place:
$ git switch -q main
$ git cherry-pick feature/rerank > /dev/null
$ git log --oneline -1 ORIG_HEAD
68e6fff Rerank the top 20
$ git branch --contains ORIG_HEAD
$ cat .git/ORIG_HEAD
68e6fff0a6256f993946e89883a38d029db3cce6
$ git reflog exists ORIG_HEAD
[exit status: 1]
```
<!-- /snippet -->

You are on `main`, you have cherry-picked a commit, and `ORIG_HEAD` names a commit of the feature branch from before its rebase, which no branch contains any more. `git reset --hard ORIG_HEAD` at this moment would move `main` onto abandoned history.

| Writes `ORIG_HEAD` | Does not write it |
|---|---|
| `git reset` (every mode), `git merge` (also a fast-forward), `git rebase`, `git am`, `git pull`, `git stash push` | `git commit`, `git commit --amend`, `git switch`, `git checkout`, `git cherry-pick`, `git revert`, `git fetch`, `git push` |

The left column is from the manual and from the transcripts of this book. The right column is observed: the transcript above for commit, amend, switch, cherry-pick and revert, and the lab fixtures for the rest (the repository of Lab 12.7 was built with `git checkout` and commits, the clone of Lab 12.2 with commits, a fetch and a push, and neither has a `.git/ORIG_HEAD`).

**In production.** Use `ORIG_HEAD` only as the very next command after the operation you want to undo, and only if that operation is in the left column. In every other case read the reflog of the branch. The rebase manual gives the same advice for long rebases: `ORIG_HEAD` "is not guaranteed to still point to that commit at the end of the rebase if other commands that change `ORIG_HEAD` (like `git reset`) are used during the rebase", while the previous tip stays available as `@{1}` (`git help rebase`).

## 13.6 `git fsck` as a search tool

**In one sentence.** `git fsck` walks the object database from every starting point and reports what it cannot reach, which makes it the tool for finding work that no ref and no reflog names.

**Precisely.** Chapter 3, section 3.8 introduced the command as an integrity check. For recovery, four options matter (`git help fsck`). 🟢 SAFE, except that `--lost-found` writes files into `.git/lost-found`.

| Option | Effect |
|---|---|
| `--dangling` (the default) | Report unreachable objects that no other object refers to: the tips of lost history, and blobs that lost their index entry |
| `--unreachable` | Report every unreachable object, including the ancestors, trees and blobs behind a dangling commit |
| `--no-reflogs` | Do not count reflog entries as starting points. The manual: "meant only to search for commits that used to be in a ref, but now aren't, but are still in that corresponding reflog" |
| `--lost-found` | In addition, write each dangling commit's ID into `.git/lost-found/commit/` and each dangling blob's *content* into `.git/lost-found/other/` |

The difference between "dangling" and "unreachable" is the difference between a tip and a chain. If three commits are lost, all three are unreachable, and only the newest is dangling, because the newest still refers to the other two. For recovery you want dangling commits: anchor the tip and the chain comes with it.

**See it.** A branch with three commits is deleted. A file was staged earlier and then thrown away by a reset.

<!-- snippet: ch13/fsck-find/01-with-reflogs -->
```text
$ git branch -D exp/hybrid
Deleted branch exp/hybrid (was 2ae0c97).
$ git fsck
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
```
<!-- /snippet -->

By default `git fsck` reports only the blob. The three commits are still reachable from the HEAD reflog, because the branch was checked out when they were made. That default is what you want when you ask "what is at risk of being collected?". When you ask "what is no longer on any branch?", take the reflogs out:

<!-- snippet: ch13/fsck-find/02-no-reflogs -->
```text
$ git fsck --no-reflogs
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
dangling commit 2ae0c97ba880a6defccc70c29261e46cb2d37bdf
$ git fsck --no-reflogs --unreachable
unreachable blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
unreachable blob d101568e3177507ffec6dd9a56c478cce1751b2f
unreachable tree 918936da64f9772a5456d5940fb80ffa0d220346
unreachable tree 17b30d538538f6762ec168c66bcaeae783356477
unreachable commit 53c5b13f7e8f3f23e8a4363f15be846e93ff5862
unreachable blob 257d9cc0829b942c09bd1d17b1ec8490ec8bd2b1
unreachable commit 2ae0c97ba880a6defccc70c29261e46cb2d37bdf
unreachable tree b08f744630034d54db33226cb5fff7e5a816fb87
unreachable blob 34ddd608dd3b612063f7806ca172b6ab36381925
unreachable commit b9975128858772d81064c041f60f4944ec3f428f
```
<!-- /snippet -->

One dangling commit, `2ae0c97`, stands for three unreachable commits, three trees and three more blobs. In a repository that has been used for months, the list of dangling commits is long: every amend, every rebase and every dropped stash leaves one. Turn the list into something you can read, newest first, with author and subject:

<!-- snippet: ch13/fsck-find/03-triage -->
```text
$ git fsck --no-reflogs | awk '/dangling commit/ {print $3}' | xargs git log --no-walk --date=iso --format='%h  %cd  %an  %s'
2ae0c97  2026-09-07 10:09:00 +0530  Lab User  Tune alpha to 0.6
$ git log --oneline 2ae0c97 --not --all
2ae0c97 Tune alpha to 0.6
53c5b13 Add hybrid weights
b997512 Add dense scorer
```
<!-- /snippet -->

The second command shows the whole lost line: commits reachable from the found tip and from no ref. `--lost-found` saves the same findings as files, which is convenient for blobs, since a blob has no name and no date and can only be recognised by its content:

<!-- snippet: ch13/fsck-find/04-lost-found -->
```text
$ git fsck --no-reflogs --lost-found
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
dangling commit 2ae0c97ba880a6defccc70c29261e46cb2d37bdf
$ find .git/lost-found -type f | sort
.git/lost-found/commit/2ae0c97ba880a6defccc70c29261e46cb2d37bdf
.git/lost-found/other/8fb6e9c8eb419f470869b10b7fcc64cf510486a0
$ cat .git/lost-found/other/*
alpha: [0.5, 0.6, 0.7]
```
<!-- /snippet -->

A found commit is still unreachable. Reading it does not protect it. Give it a ref:

<!-- snippet: ch13/fsck-find/05-anchor -->
```text
$ git branch rescue/hybrid 2ae0c97
$ git fsck --no-reflogs
dangling blob 8fb6e9c8eb419f470869b10b7fcc64cf510486a0
$ git log --oneline main..rescue/hybrid
2ae0c97 Tune alpha to 0.6
53c5b13 Add hybrid weights
b997512 Add dense scorer
```
<!-- /snippet -->

`git branch <name> <id>` 🟢 writes one ref and changes nothing else. From this moment the three commits are on layer 1, and no expiry or collection can touch them.

**Picture.**

```text
  b997512 <-- 53c5b13 <-- 2ae0c97                   8fb6e9c
  unreachable  unreachable  unreachable and          a blob: unreachable and dangling
                            DANGLING (nothing        (it was staged, then the index entry was reset)
                            refers to it)
```

**In production.** `git fsck` reads every object, so on a large repository it is slow; `--connectivity-only` skips reading blobs and is enough for a search. Since Git 2.53 it also ignores reflog entries dated after the moment it starts (Chapter 3, section 3.8), so a machine whose clock was once wrong can report "dangling" for commits the reflog still lists. Dangling is information, not damage: only lines that begin with `missing`, `broken` or `error` describe a repository that needs repair (section 13.11).

## 13.7 The recovery method

Every recovery in the rest of this chapter follows the same eight steps. They are the root-cause framework of Chapter 1, section 1.10, specialised for loss.

1. **Stop.** Do not run another command that moves refs or deletes files, and do not run `git gc`, `git prune`, `git clean` or `git stash clear`. Waiting loses nothing; a second "fix" can.
2. **Record the symptom and the last commands.** Copy the terminal scrollback if you have it. Git prints the ID you need in more places than people remember: `Deleted branch x (was 2f65488)`, `Dropped refs/stash@{0} (...)`, `HEAD is now at ...`, the warning on leaving detached HEAD.
3. **Classify.** Was the work committed, stashed, staged, or only saved? That decides the layer (section 13.2) and whether to continue with Git at all.
4. **Find the ID.** From the scrollback, the branch reflog, the HEAD reflog, `ORIG_HEAD`, `git fsck`, or another repository, in that order.
5. **Anchor it.** `git branch rescue/<what> <id>`. An anchored commit cannot expire.
6. **Inspect before you move anything.** `git log`, `git show --stat`, `git diff`, `git range-diff`, `git cherry` against the anchor.
7. **Integrate with the lowest-risk move.** Prefer adding (a branch, a cherry-pick, a merge) over rewinding, and `git reset --keep` over `git reset --hard` (Chapter 11, section 11.6).
8. **Verify, then clean up.** Prove that the result holds what was lost, and only then delete the rescue branch.

**Picture.** Where to look, as a decision flow:

```text
  Was the lost work ever committed, stashed, or staged with "git add"?
   |
   +-- no ----> Git has no object. Editor history, IDE local history, backups, Time Machine.   (13.12)
   |
   +-- staged only ----> git fsck --lost-found ; look in .git/lost-found/other                  (13.9)
   |
   +-- stashed, then dropped or cleared ----> git fsck --unreachable | ... git log --merges     (13.9)
   |
   +-- committed
        |
        +-- Do you have the ID (scrollback, CI log, pull request, chat)? -- yes --> git branch rescue <id>
        |
        +-- Did a branch move (reset, rebase, merge, amend, cherry-pick)?
        |      --> git reflog show <branch> ; take the entry below the bad operation            (13.8)
        |
        +-- Is the branch itself gone, or was the work done in detached HEAD?
        |      --> git reflog (HEAD) ; or git fsck --no-reflogs for the dangling tips           (13.8)
        |
        +-- Did the server lose it (force push, deleted remote branch)?
        |      --> git reflog show origin/<branch> ; a teammate's clone ; the host's tools      (13.10, 13.15)
        |
        +-- No reflog entry anywhere (pruned fetch, expired log, other machine)?
               --> git fsck --lost-found ; then another clone, a bundle, a backup               (13.6, 13.14)
```

What the commands of a recovery change, so that you know how little they risk:

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git branch rescue/x <id>` 🟢 | unchanged | unchanged | unchanged | unchanged | New ref `refs/heads/rescue/x` with a new reflog | unchanged | unchanged |
| `git fsck --lost-found` 🟢 | unchanged | unchanged | unchanged | unchanged | Files written under `.git/lost-found/` | unchanged | unchanged |
| `git cherry-pick <id>` 🟡 | Updated to the new commit | Updated | Moves with the branch | Advances by one new commit | Reflog entries; `CHERRY_PICK_HEAD` during a conflict | unchanged | unchanged |
| `git reset --keep <id>` 🟡 | Updated to `<id>`; refuses if a file with local changes differs between the two commits | Updated | Moves with the branch | Set to `<id>` | `ORIG_HEAD` written; reflog entries | unchanged | unchanged |
| `git reset --hard <id>` 🔴 | Overwritten to match `<id>`; uncommitted changes to tracked files destroyed | Overwritten | Moves with the branch | Set to `<id>` | `ORIG_HEAD` written; reflog entries | unchanged | unchanged |
| `git stash store <id>` 🟢 | unchanged | unchanged | unchanged | unchanged | `refs/stash` set to `<id>`, one reflog line added | unchanged | unchanged |

## 13.8 Recovering commits

Nine accidents that involve committed work. In all of them the work is on layer 2 or 3, and all nine end with the same act: a ref is pointed at a commit that never stopped existing.

### An accidental reset without `--hard`

**Symptom.** You typed `git reset HEAD~2` where you meant something smaller. The log is shorter, and `git status` shows modified files.

<!-- snippet: ch13/lab-12-1-hard-reset/06-mixed -->
```text
# The same slip without --hard: the branch moves, the files do not.
$ git reset HEAD~2
Unstaged changes after reset:
M	config.yaml
M	retriever.py
$ git log --oneline -1
798cb66 Add recall@k evaluation
$ git status -s
 M config.yaml
 M retriever.py
$ cat config.yaml
top_k: 10
$ git reset 'HEAD@{1}'
$ git status -s
$ git log --oneline -1
3106f68 Normalise queries before search
```
<!-- /snippet -->

**Why nothing was lost.** A mixed reset moves the branch and the index and leaves the working tree alone (Chapter 11, section 11.4). The content of the two "missing" commits is still in your files, shown as modifications. `HEAD@{1}` is the commit the branch pointed at before, and a second mixed reset to it puts the branch and the index back. The working tree already matched that commit, so the status is clean. A soft reset is undone the same way.

### An accidental hard reset

**Symptom.** One wrong digit: `HEAD~3` instead of `HEAD~1`. Three commits and their changes are gone from the branch and from the working tree.

<!-- snippet: ch13/lab-12-1-hard-reset/02-disaster -->
```text
# The plan: drop the last commit. The typo: 3 instead of 1.
$ git reset --hard HEAD~3
HEAD is now at 798cb66 Add recall@k evaluation
$ git log --oneline
798cb66 Add recall@k evaluation
8d2e200 Add retrieval config
7525edc Add BM25 retriever
$ cat config.yaml
top_k: 5
```
<!-- /snippet -->

**Evidence.** Three places name the old tip, and they agree:

<!-- snippet: ch13/lab-12-1-hard-reset/03-evidence -->
```text
$ git reflog -3
798cb66 HEAD@{0}: reset: moving to HEAD~3
495f3a9 HEAD@{1}: commit: WIP: debug prints
3106f68 HEAD@{2}: commit: Normalise queries before search
$ git log --oneline -1 ORIG_HEAD
495f3a9 WIP: debug prints
$ git reflog show main -2
798cb66 main@{0}: reset: moving to HEAD~3
495f3a9 main@{1}: commit: WIP: debug prints
```
<!-- /snippet -->

**Recovery.** Anchor, look, move:

<!-- snippet: ch13/lab-12-1-hard-reset/04-recover -->
```text
$ git branch rescue/before-reset ORIG_HEAD
$ git log --oneline rescue/before-reset
495f3a9 WIP: debug prints
3106f68 Normalise queries before search
13ed88d Raise top_k to 10
798cb66 Add recall@k evaluation
8d2e200 Add retrieval config
7525edc Add BM25 retriever
$ git reset --hard rescue/before-reset
HEAD is now at 495f3a9 WIP: debug prints
$ git log --oneline -3
495f3a9 WIP: debug prints
3106f68 Normalise queries before search
13ed88d Raise top_k to 10
$ cat config.yaml
top_k: 10
```
<!-- /snippet -->

`ORIG_HEAD` was safe to use here, because `git reset` wrote it and nothing has run since. The lost commits were on layer 2 for the whole time. What a hard reset destroys for good is uncommitted work, and that is section 13.9.

**The usual complication.** If you committed new work on the shortened branch before you noticed, a reset back to the old tip trades one loss for another. Anchor both tips, reset to the one you want as the base, and `git cherry-pick` the commits from the other (Lab 12.1).

### A deleted branch

**Symptom.** `git branch -D` 🔴 on a branch that was not merged.

<!-- snippet: ch13/lab-12-2-deleted-branch/02-disaster -->
```text
$ git branch -d feature/cross-encoder
error: the branch 'feature/cross-encoder' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/cross-encoder'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git branch -D feature/cross-encoder
Deleted branch feature/cross-encoder (was 2f65488).
$ git branch
* main
$ git log --oneline --graph --all
* 6f16e54 Document the pipeline stages
| * 60184f9 Deduplicate mined negatives
| * 0cea4ee Mine hard negatives from click logs
|/  
* 0875e65 Add pipeline config
* f9b487c Add retrieval pipeline
```
<!-- /snippet -->

Git refused the safe form, `-d`, because the branch was "not fully merged": that refusal is the first safety net. `-D` skips the check. It also prints the one fact you need, `(was 2f65488)`.

**Recovery.** A branch is a ref, so recreating the ref recreates the branch:

<!-- snippet: ch13/lab-12-2-deleted-branch/04-recover -->
```text
$ git branch feature/cross-encoder 2f65488
$ git log --oneline main..feature/cross-encoder
2f65488 Cache reranker scores
405080d Rerank the top 50 candidates
7e43259 Add cross-encoder reranker
$ git reflog show feature/cross-encoder
2f65488 feature/cross-encoder@{0}: branch: Created from 2f65488
```
<!-- /snippet -->

The three commits are back. The reflog of the branch is not: it has one line, `branch: Created from 2f65488`. The record of how the branch moved over its life was deleted with it and cannot be restored (section 13.12).

**Without the printed ID.** The HEAD reflog has an entry for the moment you last left the branch:

<!-- snippet: ch13/lab-12-2-deleted-branch/03-evidence -->
```text
$ git reflog show feature/cross-encoder
fatal: ambiguous argument 'feature/cross-encoder': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
$ git reflog -6
6f16e54 HEAD@{0}: commit: Document the pipeline stages
0875e65 HEAD@{1}: checkout: moving from feature/cross-encoder to main
2f65488 HEAD@{2}: commit: Cache reranker scores
405080d HEAD@{3}: commit: Rerank the top 50 candidates
7e43259 HEAD@{4}: commit: Add cross-encoder reranker
0875e65 HEAD@{5}: checkout: moving from main to feature/cross-encoder
```
<!-- /snippet -->

`checkout: moving from feature/cross-encoder to main` records where HEAD went. The entry below it, `HEAD@{2}`, is the last thing HEAD pointed at while it was on the branch: the tip, unless the branch was moved afterwards without being checked out.

**When no reflog knows the commits.** A teammate's branch that you fetched and never checked out is held by a remote-tracking ref only. If she deletes the branch on the server and you fetch with `--prune`, that ref and its reflog go:

<!-- snippet: ch13/lab-12-2-deleted-branch/06-failure -->
```text
$ git branch -r
  origin/HEAD -> origin/main
  origin/exp/hard-negatives
  origin/main
$ git log --oneline -2 origin/exp/hard-negatives
60184f9 Deduplicate mined negatives
0cea4ee Mine hard negatives from click logs
$ git fetch --prune
From ../server
 - [deleted]         (none)     -> origin/exp/hard-negatives
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git reflog show origin/exp/hard-negatives
fatal: ambiguous argument 'origin/exp/hard-negatives': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
$ git reflog | grep -c negatives
0
```
<!-- /snippet -->

Git printed `(none)` where a local deletion prints the old ID. The commits are on layer 3 now, and `git fsck` finds the tip without any option, because no reflog entry competes:

<!-- snippet: ch13/lab-12-2-deleted-branch/07-recovery-find -->
```text
$ git fsck
dangling commit 60184f9abb50a1f151181c08df375e5274ead3c6
$ git fsck --lost-found
dangling commit 60184f9abb50a1f151181c08df375e5274ead3c6
$ git log --format='%h %an, %ad%n        %s' --date=short $(cat .git/lost-found/commit/*) --not --all
60184f9 Asha Rao, 2026-09-07
        Deduplicate mined negatives
0cea4ee Asha Rao, 2026-09-07
        Mine hard negatives from click logs
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-2-deleted-branch/08-recovery-anchor -->
```text
$ git branch exp/hard-negatives $(cat .git/lost-found/commit/*)
$ git log --oneline main..exp/hard-negatives
60184f9 Deduplicate mined negatives
0cea4ee Mine hard negatives from click logs
$ git push -u origin exp/hard-negatives
To ../server.git
 * [new branch]      exp/hard-negatives -> exp/hard-negatives
branch 'exp/hard-negatives' set up to track 'origin/exp/hard-negatives'.
```
<!-- /snippet -->

`--not --all` limited the listing to commits that no ref reaches, which is the lost work and nothing else. Pushing the branch puts it on layer 4 as well. In a repository with default settings this rescue has a deadline: the grace period, counted from the day the objects were written into your repository, and then the next collection.

### A deleted commit

**Symptom.** A commit that you remember is not in the branch, and a setting it introduced is not in the file. The branch has newer commits, so the loss is not recent.

<!-- snippet: ch13/lab-12-3-deleted-commit/01-symptom -->
```text
$ cd embedder
$ git log --oneline main..feature/batching
a7061c1 Document batching in the README
0309a41 Log batch sizes
285e3af Retry on rate limit
696a15f Batch embedding requests
$ cat client.yaml
model: embed-small-v2
$ git log --oneline --all -- client.yaml
f7736c7 Add client config
```
<!-- /snippet -->

`git log --all -- client.yaml` knows one commit for that file. The timeout commit is on no branch.

**Evidence.** Commits leave a branch through three commands: `git reset`, `git rebase` (a `drop` line, or a line deleted from the todo list), and `git commit --amend`. The reflog of the branch says which one ran:

<!-- snippet: ch13/lab-12-3-deleted-commit/02-evidence -->
```text
$ git reflog show feature/batching
a7061c1 feature/batching@{0}: commit: Document batching in the README
0309a41 feature/batching@{1}: rebase (finish): refs/heads/feature/batching onto f7736c7d7ea7d8c345ef1888de925509d5117e39
76a49ed feature/batching@{2}: commit: Log batch sizes
f35b47a feature/batching@{3}: commit: Retry on rate limit
2ebd700 feature/batching@{4}: commit: Add request timeout
696a15f feature/batching@{5}: commit: Batch embedding requests
f7736c7 feature/batching@{6}: branch: Created from HEAD
```
<!-- /snippet -->

One `rebase (finish)` line, with the old tip `76a49ed` directly below it and the lost commit `2ebd700` two lines further down. To prove what the rebase changed, anchor the old tip and compare by content. `git cherry` marks with `+` the commits whose change has no equivalent on the other side (Chapter 10, section 10.10):

<!-- snippet: ch13/lab-12-3-deleted-commit/03-compare -->
```text
# Anchor the tip from before the rebase, then ask what the rebase left out:
$ git branch rescue/before-rebase 'feature/batching@{2}'
$ git log --oneline main..rescue/before-rebase
76a49ed Log batch sizes
f35b47a Retry on rate limit
2ebd700 Add request timeout
696a15f Batch embedding requests
$ git cherry -v feature/batching rescue/before-rebase
+ 2ebd700e9eb436ad1c04d80c284f18f294fc5011 Add request timeout
- f35b47a4e60533a59aba361e16d42aa94602ee05 Retry on rate limit
- 76a49edc7fb8cf1ba56ecdc367f05eb1dae9ec89 Log batch sizes
```
<!-- /snippet -->

Two commits were rebuilt with new IDs and the same change (`-`). One was left out (`+`).

**Recovery.** Do not move the branch back: a commit was added after the rebase, and a reset would lose it. Copy the one missing commit forward:

<!-- snippet: ch13/lab-12-3-deleted-commit/04-recover -->
```text
$ git show --stat --format='%h %s' 2ebd700
2ebd700 Add request timeout

 client.yaml | 1 +
 1 file changed, 1 insertion(+)
$ git cherry-pick 2ebd700
[feature/batching ff46c25] Add request timeout
 Date: Mon Sep 7 10:07:00 2026 +0530
 1 file changed, 1 insertion(+)
$ cat client.yaml
model: embed-small-v2
timeout_s: 10
```
<!-- /snippet -->

**The amend variant.** `git commit --amend` replaces the tip. If you meant to add a commit, the previous commit has disappeared into the new one. The reflog has the commit from before the amend, and a soft reset to it leaves exactly the new change staged:

<!-- snippet: ch13/lab-12-3-deleted-commit/06-failure -->
```text
# A typo fix that was meant to be a commit of its own:
$ printf 'Embedding client. Requests are sent in batches of 32.\n' > README.md
$ git commit -a --amend -m "Fix typo in README"
[feature/batching 50df155] Fix typo in README
 Date: Mon Sep 7 10:07:00 2026 +0530
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git log --oneline -3
50df155 Fix typo in README
a7061c1 Document batching in the README
0309a41 Log batch sizes
$ git show --stat --format=%s HEAD
Fix typo in README

 README.md   | 2 +-
 client.yaml | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-3-deleted-commit/07-recovery -->
```text
$ git reflog -2
50df155 HEAD@{0}: commit (amend): Fix typo in README
ff46c25 HEAD@{1}: cherry-pick: Add request timeout
$ git reset --soft 'HEAD@{1}'
$ git status -s
M  README.md
$ git diff --cached
diff --git a/README.md b/README.md
index 202d75c..5c95234 100644
--- a/README.md
+++ b/README.md
@@ -1 +1 @@
-Embedding client. Requests are sent in batchs of 32.
+Embedding client. Requests are sent in batches of 32.
$ git commit -m "Fix typo in README"
[feature/batching fdbbfc7] Fix typo in README
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

A soft reset moves the branch only. The index still holds the tree of the amended commit, so the difference between the two commits, the typo fix, is what is staged.

### A wrong rebase

**Symptom.** A hotfix branch that was cut from `release/1.4` contains commits that belong to `main`. A pull request against the release branch would list six commits instead of three.

<!-- snippet: ch13/lab-12-4-wrong-rebase/01-symptom -->
```text
$ cd evalharness
$ git status -sb
## hotfix/judge-timeout
$ git log --oneline release/1.4..HEAD
37bb577 Log judge latency
6ef447a Retry judge on timeout
262dc41 Add judge timeout
7213db9 Pin judge model for 1.4
5783ca4 Add faithfulness metric
9288f20 Switch judge to JSON mode
$ git log --oneline --graph --all
* 37bb577 Log judge latency
* 6ef447a Retry judge on timeout
* 262dc41 Add judge timeout
* 7213db9 Pin judge model for 1.4
* 5783ca4 Add faithfulness metric
* 9288f20 Switch judge to JSON mode
| * dc1ff44 Pin judge model for 1.4
|/  
* 1d7a7cc Add judge prompt
* cd80329 Add eval runner
```
<!-- /snippet -->

`git rebase main`, typed by habit, replayed the branch onto `main`: the two hotfix commits and the release-only commit below them, all with new IDs. Chapter 9, section 9.16 covers the simple case, where `git reset --hard ORIG_HEAD` or the branch reflog undoes a rebase that was noticed at once. Here a commit was added after the rebase.

**Evidence and anchor.**

<!-- snippet: ch13/lab-12-4-wrong-rebase/02-evidence -->
```text
$ git reflog show hotfix/judge-timeout
37bb577 hotfix/judge-timeout@{0}: commit: Log judge latency
6ef447a hotfix/judge-timeout@{1}: rebase (finish): refs/heads/hotfix/judge-timeout onto 5783ca45370007569bfb3217980f447300484db9
eb1f140 hotfix/judge-timeout@{2}: commit: Retry judge on timeout
c5f4fb7 hotfix/judge-timeout@{3}: commit: Add judge timeout
dc1ff44 hotfix/judge-timeout@{4}: branch: Created from HEAD
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-4-wrong-rebase/03-anchor -->
```text
$ git branch rescue/pre-rebase 'hotfix/judge-timeout@{2}'
$ git log --oneline release/1.4..rescue/pre-rebase
eb1f140 Retry judge on timeout
c5f4fb7 Add judge timeout
$ git branch backup/rebased-hotfix
```
<!-- /snippet -->

Two refs now hold the two versions of the branch: `rescue/pre-rebase` is the tip from before the rebase, and `backup/rebased-hotfix` is the present state. Nothing can be lost by what follows.

**Recovery.** Move only the commit that was made after the rebase onto the old tip. `git rebase --onto <new base> <upstream>` replays the commits after `<upstream>` (Chapter 9, section 9.5):

<!-- snippet: ch13/lab-12-4-wrong-rebase/04-transplant -->
```text
$ git rebase --onto rescue/pre-rebase HEAD~1
Rebasing (1/1)
Successfully rebased and updated refs/heads/hotfix/judge-timeout.
$ git log --oneline release/1.4..HEAD
13305ef Log judge latency
eb1f140 Retry judge on timeout
c5f4fb7 Add judge timeout
```
<!-- /snippet -->

The branch is on `release/1.4` again, with three commits. A wrong rebase is repaired with a correct rebase.

### A bad merge

Three situations, three different tools.

| The merge is | Tool | Reference |
|---|---|---|
| In progress, with conflicts you do not want to resolve | `git merge --abort` | Chapter 8 |
| Committed, not pushed | `git reset --keep ORIG_HEAD`, or the branch reflog | Below |
| Pushed to a shared branch | `git revert -m 1 <merge>`, and know the re-merge problem | Chapter 11, section 11.9 |

**Symptom.** The wrong branch was merged into `main`, and the merge was a fast-forward:

<!-- snippet: ch13/lab-12-5-bad-merge/02-disaster -->
```text
# The branch you meant to merge is feature/citations.
$ git merge exp/few-shot
Updating 0529d31..deec1c6
Fast-forward
 examples.txt | 4 ++++
 system.txt   | 1 -
 2 files changed, 4 insertions(+), 1 deletion(-)
 create mode 100644 examples.txt
$ git log --oneline
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
$ cat system.txt
You answer questions about our product documentation.
```
<!-- /snippet -->

**Evidence.**

<!-- snippet: ch13/lab-12-5-bad-merge/03-evidence -->
```text
$ git reflog -2
deec1c6 HEAD@{0}: merge exp/few-shot: Fast-forward
0529d31 HEAD@{1}: checkout: moving from exp/few-shot to main
$ git log --oneline -1 ORIG_HEAD
0529d31 Add prompt loader
$ git log --oneline ORIG_HEAD..HEAD
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
```
<!-- /snippet -->

`ORIG_HEAD..HEAD` lists what the merge brought in: three commits, and no merge commit among them.

**Recovery.**

<!-- snippet: ch13/lab-12-5-bad-merge/04-recover -->
```text
$ git reset --keep ORIG_HEAD
$ git log --oneline
0529d31 Add prompt loader
5aab090 Add system prompt
$ git merge feature/citations
Updating 0529d31..3aae83f
Fast-forward
 system.txt | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

`--keep` instead of `--hard`: it moves the branch and the files in the same way and refuses if that would overwrite an uncommitted change. The experiment branch still exists; only `main` moved back.

The recipe that many tutorials give for "undo the last merge" is `git reset --hard HEAD~1`. For a fast-forward it is wrong:

<!-- snippet: ch13/lab-12-5-bad-merge/06-failure -->
```text
$ cd ../promptstore-incident
$ git log --oneline
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
# The recipe from a tutorial: "undo the merge" by dropping one commit.
$ git reset --hard HEAD~1
HEAD is now at df44d03 WIP: longer examples
$ git log --oneline
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
# Still two experiment commits. The other recipe:
$ git reset --hard ORIG_HEAD
HEAD is now at deec1c6 WIP: drop the refusal rule
$ git log --oneline
deec1c6 WIP: drop the refusal rule
df44d03 WIP: longer examples
efee0cd Try few-shot examples
0529d31 Add prompt loader
5aab090 Add system prompt
```
<!-- /snippet -->

```text
Observed behavior : "git reset --hard HEAD~1" after a merge leaves two of the three merged commits on main;
                    "git reset --hard ORIG_HEAD" then brings the third one back
Git state         : the merge was a fast-forward: main moved from 0529d31 to deec1c6 along three commits,
                    and no merge commit was created
Mechanism         : HEAD~1 is the first parent of the tip. After a true merge that is the previous tip of
                    main. After a fast-forward it is the previous commit of the branch that was merged.
                    The first reset wrote ORIG_HEAD = deec1c6, so the second one returned to the merged state
Root cause        : the recipe assumes a merge commit, and "ORIG_HEAD" was used two commands late
Why Git does this : a fast-forward only moves a ref (Chapter 8); there is nothing to mark where it started
                    except the reflog and, for one command, ORIG_HEAD
Correct fix       : read "git reflog show main" and reset to the entry below the merge line
Prevention        : undo a merge with ORIG_HEAD immediately, or by reflog entry; never by counting parents
```

<!-- snippet: ch13/lab-12-5-bad-merge/07-recovery-read -->
```text
$ git reflog show main
deec1c6 main@{0}: reset: moving to ORIG_HEAD
df44d03 main@{1}: reset: moving to HEAD~1
deec1c6 main@{2}: merge exp/few-shot: Fast-forward
0529d31 main@{3}: commit: Add prompt loader
5aab090 main@{4}: commit (initial): Add system prompt
```
<!-- /snippet -->

The line `merge exp/few-shot: Fast-forward` is the accident. The line below it, `main@{3}`, is where `main` was before.

### Commits on the wrong branch

**Symptom.** You committed twice on `main` while you believed you were on the feature branch. Nothing is pushed.

<!-- snippet: ch13/lab-12-6-wrong-branch/01-symptom -->
```text
$ cd ingest
$ git status -sb
## main...origin/main [ahead 2]
$ git log --oneline --graph --all
* c8fec4d Add a table fixture for tests
* 0eece93 Keep table rows together when chunking
| * fb8cb6c Parse PDF tables
|/  
* 4711dcc Add chunker
* 5a80a30 Add document loader
$ git log --oneline origin/main..main
c8fec4d Add a table fixture for tests
0eece93 Keep table rows together when chunking
```
<!-- /snippet -->

`origin/main..main` is the precise name of the misplaced work: the commits on `main` that the server does not have.

**Recovery.** Nothing is lost here; the commits have the wrong name on them. Copy first, remove second:

<!-- snippet: ch13/lab-12-6-wrong-branch/02-copy -->
```text
$ git switch feature/pdf-tables
Switched to branch 'feature/pdf-tables'
$ git cherry-pick origin/main..main
[feature/pdf-tables c7f48b2] Keep table rows together when chunking
 Date: Mon Sep 7 10:11:00 2026 +0530
 1 file changed, 3 insertions(+)
[feature/pdf-tables ed2177f] Add a table fixture for tests
 Date: Mon Sep 7 10:12:00 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 fixtures/table.json
$ git log --oneline -3
ed2177f Add a table fixture for tests
c7f48b2 Keep table rows together when chunking
fb8cb6c Parse PDF tables
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-6-wrong-branch/03-move-main-back -->
```text
$ git switch main
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)
$ git reset --keep origin/main
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

If the target branch does not exist yet, the copy is not needed: `git branch feature/new` creates a ref at the current commit, and `git reset --keep origin/main` then moves `main` back. The order matters in both forms. If you reset `main` first, the two commits are held by the reflog only, and you recover them as `origin/main..main@{1}` (Lab 12.6 does it in that order on purpose). If the commits were already pushed to a shared `main`, do not rewind it: cherry-pick them to the feature branch and revert them on `main` (Chapter 11, section 11.8).

### Lost work in detached HEAD

**Symptom.** Work that you did "a few days ago" is on no branch. You remember checking out a tag.

A commit made in detached HEAD belongs to no branch, so only the HEAD reflog records it (Chapter 7, section 7.7). Git warns when you leave such commits behind, and Chapter 7's Lab 4.2 rescues them from that warning. This is the case where the warning scrolled away long ago:

<!-- snippet: ch13/lab-12-7-detached-head/02-reflog -->
```text
$ git reflog
f4a81dc HEAD@{0}: commit: Document the endpoints
20459b3 HEAD@{1}: checkout: moving from 852224fe93ed50676b587ace22cee739d967505f to main
852224f HEAD@{2}: commit: Experiment: disable response cache
f6f6bbb HEAD@{3}: checkout: moving from main to HEAD~1
20459b3 HEAD@{4}: commit: Export latency metrics
f6f6bbb HEAD@{5}: checkout: moving from 266d3b2a96a6a113c06fe5974b09562b1d3f440b to main
266d3b2 HEAD@{6}: commit: Hotfix: reject empty prompts
ba8c3d9 HEAD@{7}: commit: Hotfix: cap max_tokens at 4096
be53ce8 HEAD@{8}: checkout: moving from main to v1.2.0
f6f6bbb HEAD@{9}: commit: Add streaming endpoint
be53ce8 HEAD@{10}: commit: Add request limits
3838324 HEAD@{11}: commit (initial): Add inference endpoint
```
<!-- /snippet -->

The marks of a detached session are a `checkout: moving from main to <tag or commit>` line, commits above it, and a `checkout: moving from <forty hexadecimal digits> to main` line that ends it. There are two sessions in this log. Reading reflogs of real length for such patterns is slow. `git fsck --no-reflogs` goes straight to the result: the tips that no branch and no tag reaches.

<!-- snippet: ch13/lab-12-7-detached-head/03-fsck -->
```text
$ git fsck --no-reflogs
dangling commit 852224fe93ed50676b587ace22cee739d967505f
dangling commit 266d3b2a96a6a113c06fe5974b09562b1d3f440b
$ git log --oneline --graph 266d3b2 852224f --not --all
* 852224f Experiment: disable response cache
* 266d3b2 Hotfix: reject empty prompts
* ba8c3d9 Hotfix: cap max_tokens at 4096
```
<!-- /snippet -->

Two dangling commits, and the graph shows what hangs on each: a line of two hotfix commits and a single experiment.

**Recovery.**

<!-- snippet: ch13/lab-12-7-detached-head/05-anchor -->
```text
$ git branch hotfix/1.2.1 266d3b2
$ git branch exp/no-response-cache 852224f
$ git log --oneline --graph --all
* f4a81dc Document the endpoints
* 20459b3 Export latency metrics
| * 852224f Experiment: disable response cache
|/  
* f6f6bbb Add streaming endpoint
| * 266d3b2 Hotfix: reject empty prompts
| * ba8c3d9 Hotfix: cap max_tokens at 4096
|/  
* be53ce8 Add request limits
* 3838324 Add inference endpoint
```
<!-- /snippet -->

Each line has a name now. What happens to the hotfixes next is an ordinary decision, made without time pressure.

### A wrong cherry-pick

**Symptom.** The commit that landed on the release branch is a feature, not the fix:

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/02-disaster -->
```text
# The fix to backport is "Fix off-by-one in rate limit window". The newest commit on main is not it.
$ git cherry-pick -x main
[release/2.1 1bccf8e] Add per-tenant quotas
 Date: Mon Sep 7 10:08:00 2026 +0530
 2 files changed, 2 insertions(+)
 create mode 100644 quotas.yaml
$ git log --oneline -3
1bccf8e Add per-tenant quotas
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
$ git show --stat --format=%B HEAD
Add per-tenant quotas

(cherry picked from commit cad5d75479789f69b0c584495258e2ad3f7ce87f)


 quotas.yaml | 1 +
 router.py   | 1 +
 2 files changed, 2 insertions(+)
```
<!-- /snippet -->

`-x` recorded the source, `cad5d75`, which makes the mistake visible in review. The pick itself was clean, and that is the dangerous case: a wrong pick that conflicts gets attention, and a clean one ships.

**Recovery.** While the pick is still in progress (it stopped on a conflict), `git cherry-pick --abort` returns to the state before it (Chapter 10, section 10.6). After it has finished and before a push, step the branch back by one reflog entry and pick the right commit:

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/04-recover -->
```text
$ git reset --keep 'HEAD@{1}'
$ git log --oneline -2
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
$ git cherry-pick -x main~1
[release/2.1 5564cff] Fix off-by-one in rate limit window
 Date: Mon Sep 7 10:06:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

After a push to a shared release branch, `git revert` the wrong commit instead.

The reflex that fails here is `git reset --hard ORIG_HEAD`:

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/06-failure -->
```text
$ cd ../apigw-incident
$ git log --oneline -3
48b4def Add per-tenant quotas
e30eec3 Pin dependencies for 2.1
3171b7b Add request router
# The wrong pick is already here. A recipe remembered from the merge chapter:
$ git reset --hard ORIG_HEAD
HEAD is now at f028350 Fix off-by-one in rate limit window
$ git log --oneline
f028350 Fix off-by-one in rate limit window
3171b7b Add request router
239cf05 Add rate limiter
$ git status -sb
## release/2.1
$ ls
limiter.py
router.py
```
<!-- /snippet -->

```text
Observed behavior : after "git reset --hard ORIG_HEAD" the release branch shows the history of main,
                    and the release-only commit "Pin dependencies for 2.1" is gone
Git state         : ORIG_HEAD = f028350, written days earlier by a fast-forward merge on main
Mechanism         : git cherry-pick does not write ORIG_HEAD (section 13.5), so the slot held a value from
                    another operation on another branch; the reset moved release/2.1 to that commit
Root cause        : ORIG_HEAD was used as "undo the last command"; it means "before the last reset,
                    merge, rebase or am"
Why Git does this : ORIG_HEAD is one file with no notion of which branch or which command it belongs to
Correct fix       : git reflog show release/2.1, then reset --keep to the entry below the cherry-pick
Prevention        : undo by reflog entry; check "git log -1 ORIG_HEAD" before every use of ORIG_HEAD
```

<!-- snippet: ch13/lab-12-9-wrong-cherry-pick/07-recovery-read -->
```text
$ git reflog show release/2.1
f028350 release/2.1@{0}: reset: moving to ORIG_HEAD
48b4def release/2.1@{1}: cherry-pick: Add per-tenant quotas
e30eec3 release/2.1@{2}: commit: Pin dependencies for 2.1
3171b7b release/2.1@{3}: branch: Created from main
$ git reflog -4
f028350 HEAD@{0}: reset: moving to ORIG_HEAD
48b4def HEAD@{1}: cherry-pick: Add per-tenant quotas
e30eec3 HEAD@{2}: commit: Pin dependencies for 2.1
3171b7b HEAD@{3}: checkout: moving from main to release/2.1
```
<!-- /snippet -->

The result looked plausible, which is what makes this failure expensive: the tip was the very fix that should have been picked. Only the missing file `requirements.txt` gave it away. In the branch reflog, `release/2.1@{2}` is the state before the wrong pick.

## 13.9 Recovering uncommitted work

### Staged, never committed, then overwritten

**Symptom.** `git reset --hard` (or `git restore --staged --worktree`, or a checkout with `-f`) ran over work that was not committed.

<!-- snippet: ch13/lab-12-8-overwritten-changes/01-start -->
```text
$ cd finetune
$ git status -s
A  sweep.yaml
MM train.yaml
?? notes.md
$ git diff --cached --stat
 sweep.yaml | 2 ++
 train.yaml | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git diff --stat
 train.yaml | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

Three kinds of work are at stake: `sweep.yaml` is new and staged, `train.yaml` has a staged change and a later edit that is not staged, and `notes.md` is untracked.

<!-- snippet: ch13/lab-12-8-overwritten-changes/02-disaster -->
```text
$ git reset --hard
HEAD is now at cf76919 Add training config
$ git status -s
?? notes.md
$ ls
notes.md
train.py
train.yaml
$ cat train.yaml
lr: 3e-5
epochs: 3
```
<!-- /snippet -->

`notes.md` survived, because a reset does not touch untracked files. `sweep.yaml` is deleted and `train.yaml` is back at the committed version.

**Where the work is.** Chapter 5 showed that `git add` writes a blob at the moment you run it. The reset removed the index entries, not the blobs. Nothing names them, so they are dangling, on layer 3:

<!-- snippet: ch13/lab-12-8-overwritten-changes/03-find -->
```text
$ git fsck --lost-found
dangling blob e199091045de591b8baa02bcd6a807b1788fb1cd
dangling blob e4e919703dbad4b896c710848d17d14d447f39ee
dangling blob 0697c1f85fe6c2da00446682c1a538103d96ea5c
$ ls .git/lost-found/other
0697c1f85fe6c2da00446682c1a538103d96ea5c
e199091045de591b8baa02bcd6a807b1788fb1cd
e4e919703dbad4b896c710848d17d14d447f39ee
```
<!-- /snippet -->

Three blobs for two files, because `sweep.yaml` was staged twice and each `git add` wrote a blob. A blob has no file name and no date: the name lived in the index entry that is gone. Identify the blobs by content:

<!-- snippet: ch13/lab-12-8-overwritten-changes/04-identify -->
```text
$ grep -c "" .git/lost-found/other/*
.git/lost-found/other/0697c1f85fe6c2da00446682c1a538103d96ea5c:1
.git/lost-found/other/e199091045de591b8baa02bcd6a807b1788fb1cd:2
.git/lost-found/other/e4e919703dbad4b896c710848d17d14d447f39ee:2
$ grep -l warmup_ratio .git/lost-found/other/*
.git/lost-found/other/e199091045de591b8baa02bcd6a807b1788fb1cd
$ grep -l epochs .git/lost-found/other/*
.git/lost-found/other/e4e919703dbad4b896c710848d17d14d447f39ee
```
<!-- /snippet -->

<!-- snippet: ch13/lab-12-8-overwritten-changes/05-restore -->
```text
$ cp .git/lost-found/other/e199091045de591b8baa02bcd6a807b1788fb1cd sweep.yaml
$ git cat-file -p e4e9197 > train.yaml
$ cat sweep.yaml train.yaml
lr: [1e-5, 3e-5]
warmup_ratio: [0.0, 0.1]
lr: 3e-5
epochs: 5
$ git add sweep.yaml train.yaml
$ git status -s
A  sweep.yaml
M  train.yaml
?? notes.md
```
<!-- /snippet -->

Both staged versions are back. The third blob, `0697c1f`, is the earlier staging of `sweep.yaml`: every `git add` is a checkpoint that outlives the index entry.

**What is not there.** The line `early_stopping: true` was typed after the last `git add`. Its content was never hashed, so no object holds it:

<!-- snippet: ch13/lab-12-8-overwritten-changes/06-never-staged -->
```text
# The line that was typed after the last "git add". This is the ID its file would have had:
$ printf 'lr: 3e-5\nepochs: 5\nearly_stopping: true\n' | git hash-object --stdin
fd0a951c99adb02cad59bdf1d4debd1d4de26084
$ git cat-file -t fd0a951
fatal: Not a valid object name fd0a951
[exit status: 128]
```
<!-- /snippet -->

`git hash-object` computes the ID that the full file would have had. No object with that ID exists. This is the boundary of Git's safety net, drawn in two commands.

### A dropped or cleared stash

**Symptom.** `git stash drop`, a `git stash pop` followed by a reset, or `git stash clear`.

<!-- snippet: ch13/lab-12-8-overwritten-changes/07-failure -->
```text
$ cd ../finetune-incident
$ git stash list
stash@{0}: On main: lora: rank 16 trial
stash@{1}: WIP on main: cf76919 Add training config
$ git stash clear
$ git stash list
```
<!-- /snippet -->

`git stash drop` prints the ID of what it dropped. `git stash clear` prints nothing. A stash entry is a commit with two or three parents (Chapter 11, section 11.11), and dropping it removed its reflog line, so the commit is unreachable. The stash manual gives a recipe that lists unreachable commits which look like stash entries (`git help stash`, section EXAMPLES):

<!-- snippet: ch13/lab-12-8-overwritten-changes/08-recovery-recipe -->
```text
# The recipe from the git-stash manual:
$ git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --grep=WIP --format='%h %s'
a0cbbaf WIP on main: cf76919 Add training config
# Without --grep=WIP:
$ git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git log --merges --no-walk --format='%h %s'
0b0c40d On main: lora: rank 16 trial
a0cbbaf WIP on main: cf76919 Add training config
```
<!-- /snippet -->

The recipe ends in `--grep=WIP`, and it found one of two entries. The default message of a stash is `WIP on <branch>: ...`; an entry made with `git stash push -m` is named `On <branch>: <your message>` and does not match. Leave the `--grep` out, as the second command does, and rely on `--merges`: a stash entry is a merge commit, and few other unreachable commits are.

**Recovery.** `git stash apply <id>` applies a found entry directly. `git stash store` puts it back into the list:

<!-- snippet: ch13/lab-12-8-overwritten-changes/09-recovery-apply -->
```text
$ git stash store -m 'recovered: grad clip' a0cbbaf
$ git stash store -m 'recovered: lora rank 16 trial' 0b0c40d
$ git stash list
stash@{0}: recovered: lora rank 16 trial
stash@{1}: recovered: grad clip
$ git stash show -p 'stash@{0}'
diff --git a/train.yaml b/train.yaml
index 58da445..db55f58 100644
--- a/train.yaml
+++ b/train.yaml
@@ -1,2 +1,3 @@
 lr: 3e-5
 epochs: 3
+lora_rank: 16
```
<!-- /snippet -->

The deadline is the one of layer 3, and it is shorter than for a rewritten commit: a dropped stash never has a reflog entry to fall back on.

## 13.10 Recovering from the remote side

### A force push, seen from your clone

**Symptom.** A teammate pushed with `--force` 🔴. Chapter 12, section 12.8 explains the mechanics on the pushing side. This is what the others see, and why your clone is the recovery tool.

<!-- snippet: ch13/lab-12-11-force-push/02-fetch -->
```text
$ git fetch
From ../server
 + d8a3934...882b940 main       -> origin/main  (forced update)
$ git status -sb
## main...origin/main [ahead 2, behind 1]
$ git log --oneline --graph main origin/main
* 882b940 Rename settings keys
| * d8a3934 Add cache metrics
| * 2a2bf94 Add answer cache
|/  
* 6955492 Add settings
* 1203ec5 Add question answering endpoint
```
<!-- /snippet -->

The `+` and `(forced update)` in the fetch output mean that `origin/main` did not move forward: the server's branch was replaced by a commit that does not descend from the old one. Status calls it divergence, `ahead 2, behind 1`.

**Evidence.** Your remote-tracking ref has a reflog, and it recorded the value the server had before:

<!-- snippet: ch13/lab-12-11-force-push/03-evidence -->
```text
$ git reflog show origin/main
882b940 refs/remotes/origin/main@{0}: fetch: forced-update
d8a3934 refs/remotes/origin/main@{1}: update by push
2a2bf94 refs/remotes/origin/main@{2}: pull: fast-forward
6955492 refs/remotes/origin/main@{3}: update by push
$ git log --format='%h %an: %s' origin/main..'origin/main@{1}'
d8a3934 Lab User: Add cache metrics
2a2bf94 Asha Rao: Add answer cache
$ git log --format='%h %an: %s' 'origin/main@{1}'..origin/main
882b940 Ravi Menon: Rename settings keys
```
<!-- /snippet -->

`origin/main@{1}` is the server's old tip. The two `git log` ranges are the damage report: two commits by two authors were removed from the server, and one commit was put in their place.

The server itself cannot tell you that. It is a bare repository without reflogs. A teammate who has not fetched since is another witness:

<!-- snippet: ch13/lab-12-11-force-push/04-server-has-no-record -->
```text
# The server is a bare repository. It kept no record of the value that was overwritten:
$ ls ../server.git
config
description
HEAD
hooks
info
objects
refs
$ git -C ../server.git reflog list
$ git -C ../server.git config get core.logAllRefUpdates
[exit status: 1]
# A teammate who has not fetched still has the value from her last contact with the server:
$ git -C ../asha log --oneline -1 origin/main
2a2bf94 Add answer cache
```
<!-- /snippet -->

**Recovery.** There are two honest repairs, and the choice is a judgment about the commit that was forced in.

| Repair | Command | Effect | Choose it when |
|---|---|---|---|
| Keep both | `git merge origin/main`, then `git push` | The lost commits return with their original IDs, the forced commit stays, and the push is a fast-forward | The forced commit is legitimate work |
| Restore the old value | `git push --force-with-lease=main:<forced id> origin <old id>:main` | The server's branch is set back; the forced commit leaves the branch | The forced commit must not be on the branch (a rewrite that drops history) |

<!-- snippet: ch13/lab-12-11-force-push/05-repair -->
```text
$ git merge -m 'Merge origin/main: restore commits removed by a force push' origin/main
Merge made by the 'ort' strategy.
 settings.yaml | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git push
To ../server.git
   882b940..d967a92  main -> main
```
<!-- /snippet -->

The merge needed no force: the server's tip `882b940` is an ancestor of the merge commit. Every clone that already has the old commits, and every CI record that quotes their IDs, stays valid. Rebasing the lost commits onto the forced one would give them new IDs and create the duplicates of Chapter 9, section 9.15.

The second repair is a force push in its own right. Give it an explicit expected value, the forced commit, so that it fails if the server has moved again (Chapter 12, section 12.8).

**A reflex to avoid.** Faced with `ahead 2, behind 1`, people run `git reset --hard origin/main` "to get in sync". That removes the lost commits from the one local branch that still held them. They remain in `main@{1}` and `origin/main@{1}`, and Lab 12.11 recovers them from there.

### Remote-tracking refs that cannot be trusted

**Symptom.** `git status` says the branch is in sync with `origin/main`, and `git push` is rejected.

<!-- snippet: ch13/lab-12-10-remote-tracking/01-symptom -->
```text
$ cd docsearch
$ git status -sb
## main...origin/main
$ git push
To ../server.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

A remote-tracking ref is a local record of the last contact with the server (Chapter 12, section 12.4). Status compared two local refs. Push talked to the server. When they disagree, the server is right, and `git ls-remote` asks it without changing anything:

<!-- snippet: ch13/lab-12-10-remote-tracking/02-ask-the-server -->
```text
$ git ls-remote origin
e2753886b206a1781cfc9cb9520d36220feeae8e	HEAD
c6ec9d6c4248646f6256680df1f68a2772c1f442	refs/heads/feature/hybrid-search
e2753886b206a1781cfc9cb9520d36220feeae8e	refs/heads/main
$ git for-each-ref --format='%(objectname) %(refname)' refs/remotes/origin
warning: ignoring broken ref refs/remotes/origin/feature/hybrid-search
5eda6ed9f98f81e3870aadd032aaf47706d771bf refs/remotes/origin/main
```
<!-- /snippet -->

Two discrepancies. `origin/main` holds an ID that the server does not have at all, and `origin/feature/hybrid-search` is reported as a broken ref. The ordinary repair, a fetch, fails on the second:

<!-- snippet: ch13/lab-12-10-remote-tracking/03-fetch-fails -->
```text
$ git fetch
fatal: bad object refs/remotes/origin/feature/hybrid-search
error: ../server.git did not send all necessary objects
[exit status: 1]
$ git fsck
error: refs/remotes/origin/feature/hybrid-search: badRefContent: 
error: refs/remotes/origin/feature/hybrid-search: invalid sha1 pointer 0000000000000000000000000000000000000000
dangling commit e2753886b206a1781cfc9cb9520d36220feeae8e
[exit status: 10]
```
<!-- /snippet -->

`badRefContent` names the file that is damaged. The dangling commit is a side effect worth reading: the fetch downloaded the server's new commit and then failed before it could update any ref.

<!-- snippet: ch13/lab-12-10-remote-tracking/04-evidence -->
```text
$ wc -c < .git/refs/remotes/origin/feature/hybrid-search
       0
$ git reflog show origin/main
5eda6ed refs/remotes/origin/main@{0}: 
6edd8a2 refs/remotes/origin/main@{1}: update by push
$ git log -g --date=iso --format='%gd | %gn | %gs' origin/main
origin/main@{2026-09-07 10:19:00 +0530} | Lab User | 
origin/main@{2026-09-07 10:07:00 +0530} | Lab User | update by push
```
<!-- /snippet -->

The ref file is empty: a broken ref of the kind the Git FAQ attributes to file-syncing tools (section 13.11). The reflog of `origin/main` explains the first discrepancy: its newest entry has no message. A fetch writes `fetch: ...` and a push writes `update by push`. An entry without a message was written by `git update-ref` from a script or by hand.

**Recovery.** Remote-tracking refs are derived data. Remove what is broken, and let a fetch write the truth:

<!-- snippet: ch13/lab-12-10-remote-tracking/05-repair -->
```text
$ git update-ref -d refs/remotes/origin/feature/hybrid-search
error: cannot lock ref 'refs/remotes/origin/feature/hybrid-search': unable to resolve reference 'refs/remotes/origin/feature/hybrid-search': reference broken
[exit status: 1]
$ rm .git/refs/remotes/origin/feature/hybrid-search
$ git fetch
From ../server
 + 5eda6ed...e275388 main                  -> origin/main  (forced update)
 * [new branch]      feature/hybrid-search -> origin/feature/hybrid-search
$ git status -sb
## main...origin/main [ahead 2, behind 1]
```
<!-- /snippet -->

`git update-ref -d` cannot delete a ref it cannot read, so the empty file has to be removed by hand 🔴. That is a rare legitimate reason to touch a file under `.git/refs`. The fetch then corrected `origin/main` with a forced update and recreated the other ref. Status now tells the truth: two commits to push, one to integrate. Chapter 12, section 12.14 has the wholesale version: delete every ref under `refs/remotes/origin`, then fetch.

## 13.11 A damaged repository

Losing a name is one kind of problem. Losing an object that is still needed is another: a reachable commit, tree or blob cannot be read. The causes are outside Git: failing hardware, and tools that copy the repository file by file. The Git FAQ is direct about the second: do not "use a cloud syncing service to sync any portion of a Git repository, since this can cause corruption, such as missing objects, changed or added files, broken refs" (`git help gitfaq`).

### A missing or corrupt object

**Symptom.** Commands that need the object fail; commands that do not need it keep working, which is why damage can go unnoticed for weeks.

<!-- snippet: ch13/corruption/02-symptoms -->
```text
$ git status -sb
## main...origin/main
$ git log --oneline -3
98a37af Raise top_k to 10
688c9f2 Add embedding client
87fda00 Add retriever config
$ git log --oneline --stat -2
error: inflate: data stream error (incorrect header check)
error: unable to unpack 3a87d97273a9e9f1038d516277e2fbe853c4fccf header
fatal: loose object 3a87d97273a9e9f1038d516277e2fbe853c4fccf (stored in .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf) is corrupt
[exit status: 128]
```
<!-- /snippet -->

`git status` and `git log --oneline` read commits and the index. `git log --stat` needs the tree of the second commit, whose file was overwritten with garbage, and stops.

<!-- snippet: ch13/corruption/03-fsck -->
```text
$ git fsck
error: inflate: data stream error (incorrect header check)
error: unable to unpack header of .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf
error: 3a87d97273a9e9f1038d516277e2fbe853c4fccf: object corrupt or missing: .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf
missing tree 3a87d97273a9e9f1038d516277e2fbe853c4fccf
[exit status: 3]
```
<!-- /snippet -->

`missing tree` is the diagnosis: this is the line that distinguishes damage from the harmless `dangling` reports of section 13.6. A file that is present but unreadable counts as missing.

**Why a fetch does not repair it.** A fetch negotiates by commits: your repository says which commits it has, and the server sends what is not reachable from them. Your refs say you have everything.

<!-- snippet: ch13/corruption/04-fetch-does-not-help -->
```text
$ git fetch origin
[exit status: 0]
$ git fsck 2>&1 | tail -1
missing tree 3a87d97273a9e9f1038d516277e2fbe853c4fccf
```
<!-- /snippet -->

**Recovery from another copy.** An object's ID is determined by its content (Chapter 3, section 3.3), so the same object from any other repository is the object you lost. Ask a healthy clone for a pack that contains it:

<!-- snippet: ch13/corruption/05-repair-one-object -->
```text
# Ask a clone that has the object for a pack with that one object, and unpack it here:
$ echo 3a87d97273a9e9f1038d516277e2fbe853c4fccf | git -C ../asha pack-objects --stdout -q | git unpack-objects -q
$ git fsck 2>&1 | tail -1
missing tree 3a87d97273a9e9f1038d516277e2fbe853c4fccf
# Nothing changed: a file with that name exists, so the object was not written.
# Move the damaged file out of the object database (keep it as evidence), then repeat.
$ mv .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf ../damaged-tree.saved
$ echo 3a87d97273a9e9f1038d516277e2fbe853c4fccf | git -C ../asha pack-objects --stdout -q | git unpack-objects -q
$ git fsck
[exit status: 0]
$ git log --oneline --stat -2
98a37af Raise top_k to 10
 retriever.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
688c9f2 Add embedding client
 embed.py | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

`git pack-objects` reads IDs on standard input and writes a pack, and `git unpack-objects` stores the objects of a pack as loose files. The first attempt changed nothing, because `git unpack-objects` does not write "objects that already exist in the repository" (`git help unpack-objects`), and a file with that name existed. The damaged file was moved out, not deleted: the official how-to on this subject asks you to keep it, since a corrupt object can only be analysed next to its intact twin.

When many objects are affected, or you cannot reach a teammate's disk, fetch everything again. `--refetch` "fetches all objects as a fresh clone would" (`git help fetch`); the [release notes of Git 2.36](https://github.com/git/git/blob/master/Documentation/RelNotes/2.36.0.adoc), which added it, describe it as useful "when you cannot trust what you have in the local object store":

<!-- snippet: ch13/corruption/06-refetch -->
```text
# The blunt repair: lose two objects, then download everything again from the server.
$ rm -f .git/objects/3a/87d97273a9e9f1038d516277e2fbe853c4fccf .git/objects/$(git rev-parse HEAD:embed.py | sed 's/../&\//')
$ git fsck
broken link from  commit 688c9f2046a2fb925cc202a4387cf9b7631c5f84
              to    tree 3a87d97273a9e9f1038d516277e2fbe853c4fccf
missing blob 5501ef2431a0a61c1dde82cf50840bbfc7072980
missing tree 3a87d97273a9e9f1038d516277e2fbe853c4fccf
[exit status: 2]
$ git fetch --refetch origin
$ git fsck
[exit status: 0]
```
<!-- /snippet -->

`--refetch` can only bring back what the server has. Commits that exist only in your clone and lost an object are repaired from your own working tree if the file is still there (`git hash-object -w <file>`, Chapter 3, section 3.8), and otherwise they are lost from that point of history on.

### A corrupt index

**Symptom.** Every command that looks at the working tree fails with the same two lines; history commands still work.

<!-- snippet: ch13/lab-12-10-remote-tracking/07-failure -->
```text
$ printf 'def parse(q):\n    return PHRASE.findall(q.lower().strip())\n' > query.py
$ git add query.py
$ printf 'def cached(q):\n    return CACHE.get(q.strip())\n' > cache.py
$ git status -s
 M cache.py
M  query.py
# Simulate a damaged index file: overwrite its first four bytes.
$ printf 'XXXX' | dd of=.git/index bs=1 conv=notrunc 2>/dev/null
$ git status
error: bad signature 0x58585858
fatal: index file corrupt
[exit status: 128]
$ git log --oneline -1
5eda6ed Add query cache
[exit status: 0]
```
<!-- /snippet -->

**Recovery.** The index is derived data too, except for one thing: the record of what you had staged. Move the file away and let `git reset` build a new index from HEAD:

<!-- snippet: ch13/lab-12-10-remote-tracking/08-recovery -->
```text
$ mv .git/index .git/index.corrupt
$ git status -s
D  cache.py
D  index.py
D  query.py
?? cache.py
?? index.py
?? query.py
$ git reset
Unstaged changes after reset:
M	cache.py
M	query.py
$ git status -s
 M cache.py
 M query.py
```
<!-- /snippet -->

Without an index, every tracked file looks deleted and untracked at once. `git reset` (mixed, to HEAD) writes a fresh index and does not touch the working tree. Both edits are still in the files. What is gone is the distinction between them: `query.py` had been staged, and now both show as unstaged. If the staged content differed from the file on disk, it is a dangling blob, found as in section 13.9.

## 13.12 What cannot be recovered, and exactly why

Saying "it is gone" with a reason is part of the job. Every row below is a consequence of sections 13.2 to 13.4, not a separate rule.

| What was lost | Why Git cannot bring it back | Evidence | What would have saved it |
|---|---|---|---|
| Edits to a tracked file that were never staged, overwritten by `git reset --hard`, `git restore` or `git checkout -- <path>` | No object was ever written for that content | Section 13.9; Chapter 11, section 11.5 | `git add` or a commit; editor history; a backup |
| Untracked or ignored files removed by `git clean`, or overwritten by a checkout | Git never stored them | Chapter 11, section 11.10 | `git clean -n` first; `git stash -u` |
| The reflog of a deleted branch | Deleted with the branch; the commits survive through other names, the branch's own history of movements does not | Section 13.8 | Renaming the branch instead of deleting it: the reflog moves with the name |
| The file name and staging time of a dangling blob | Names live in trees and index entries; the entry is gone | Section 13.9 | A commit |
| Which changes were staged, after a corrupt index | That distinction existed only in the index file | Section 13.11 | A commit |
| A commit whose reflog entries expired and whose objects were pruned | Nothing names it and the object is deleted | Section 13.13 | A branch, a tag, a push, a bundle |
| A stash entry after its commits were pruned | The same | Section 13.9 | A branch instead of a stash |
| Anything in a clone you deleted and that was never pushed | The only object database that held it is gone | Layer 4 never existed | `git push`, even to a personal branch |
| The value a server branch had before a force push, when no clone fetched it and the host kept no record | Bare repositories keep no reflog by default | Section 13.4 | Protection against force pushes; section 13.15 for GitHub |

Two losses that people expect in this table are not in it: a commit removed by a rebase, an amend or a reset is recoverable for weeks, and a deleted branch for as long as you can find its tip.

## 13.13 The point of no return

**In one sentence.** A lost commit becomes unrecoverable in two steps, first when the last reflog entry that names it is removed and then when a collection deletes the object, and two commands can force both steps at once.

**Precisely.** The destructive pair is the documented procedure for shrinking a repository after a history rewrite (`git help filter-branch`, "Checklist for shrinking a repository", which calls it "a very destructive approach"), and for the same reason it is the documented way to destroy the safety net:

```bash
git reflog expire --expire=now --all     # step 1: remove every reflog entry
git gc --prune=now                       # step 2: delete every unreachable object
```

For each 🔴 command of this section:

| Command | What it changes | What it can destroy | Preview | Recovery | Appropriate when |
|---|---|---|---|---|---|
| `git reflog expire --expire=now --all` 🔴 | Empties every reflog, the stash list included | Every layer 2 protection, and the list of all stash entries except the newest | `git reflog expire --dry-run --verbose ...` | The objects still exist: `git fsck`, until a prune | A secret must be purged after a history rewrite (Chapter 21B) |
| `git gc --prune=now` 🔴 | Repacks; deletes all unreachable objects | Everything on layer 3 | `git prune -n`; `git fsck --unreachable` | None in this repository; only layer 4 | The same purge, with no other process using the repository |
| `git prune` 🔴 | Deletes unreachable loose objects, with no grace period unless `--expire` is given | The same, for loose objects | `git prune -n` | None | Rarely; the manual says to run `git gc` instead |
| `git gc` 🟡 | Repacks; expires reflogs by the configured periods; deletes unreachable objects older than two weeks | Old layer 3 objects, and reflog entries past their period | `git count-objects -v`; the previews above | None for what was deleted | Routine housekeeping |

The manual attaches a second warning to `--prune=now`: it "increases the risk of corruption if another process is writing to the repository concurrently" (`git help gc`). An object that a running command has written and not yet attached to a ref looks unreachable.

**Inside `.git`.** Step 1 truncates files under `logs/`. Step 2 rewrites `objects/pack/` and removes loose object files.

**See it.** The commit `dbe6ec8` of section 13.2 survived `git gc --prune=now` because a reflog entry named it. Now the entry is removed. `git prune -n` 🟢 previews what a prune would delete:

<!-- snippet: ch13/gc-ladder/02-preview -->
```text
$ cd ../searchsvc
$ git reflog expire --expire=now --all
$ git fsck
dangling commit dbe6ec85eb878f765ce8aad54c6e44b160a5efbb
$ git prune -n
76020a0a06a8e075a0095bdd4e66f5adfc4bad1b blob
dbe6ec85eb878f765ce8aad54c6e44b160a5efbb commit
e0c634deb63e58e853366c3dc3cff67a35e6aaa2 tree
```
<!-- /snippet -->

Three objects: the commit, its tree and the one blob that no other commit shares. The commit is on layer 3 and still fully readable. A collection that respects a grace period does not delete such objects. It moves them into a cruft pack, a pack for unreachable objects with a `.mtimes` file that records each object's age:

<!-- snippet: ch13/gc-ladder/03-cruft-pack -->
```text
# A collection that prunes nothing ("never"; the default cut-off is two weeks):
$ git gc --prune=never
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 0
in-pack: 12
packs: 2
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   2 idx
   1 mtimes
   2 pack
   2 rev
$ git cat-file -t dbe6ec8
commit
$ git fsck
dangling commit dbe6ec85eb878f765ce8aad54c6e44b160a5efbb
```
<!-- /snippet -->

The transcript uses `--prune=never` so that it does not depend on a clock. A plain `git gc` behaves the same way for objects younger than two weeks. Without the grace period, the objects are deleted:

<!-- snippet: ch13/gc-ladder/04-prune-now -->
```text
$ git gc --prune=now
$ git count-objects -v | grep -e "^count" -e in-pack -e "^packs"
count: 0
in-pack: 9
packs: 1
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   1 idx
   1 pack
   1 rev
$ git cat-file -t dbe6ec8
fatal: Not a valid object name dbe6ec8
[exit status: 128]
$ git fsck
```
<!-- /snippet -->

Nine objects are left, in one pack. `git fsck` reports nothing: the repository is healthy, and the commit does not exist. Lab 12.12 walks the same ladder and then tries every tool of this chapter against the result, including `ORIG_HEAD`, which still holds the ID of the deleted commit and resolves to nothing.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git reflog expire --expire=now --all` | unchanged | unchanged | unchanged | unchanged | Every file under `logs/` emptied; `refs/stash` keeps its value | unchanged | unchanged |
| `git gc --prune=now` | unchanged | unchanged | unchanged | unchanged | Objects repacked, unreachable objects deleted, refs packed into `packed-refs` | unchanged | unchanged |

**Picture.**

```text
  reflog entry exists      -->  git reset --hard <id>            recoverable, by name
          |
          |  git reflog expire --expire=now --all      (or: 30 or 90 days, then maintenance)
          v
  object exists, unnamed   -->  git fsck ; git branch x <id>     recoverable, by search
          |
          |  git gc --prune=now                        (or: older than two weeks, then maintenance)
          v
  object deleted           -->  another clone, the server, a bundle, a backup        ... or nothing
```

**Automatic maintenance.** You rarely run `git gc` yourself. Some commands start maintenance when they finish (`maintenance.auto`, default true). Since Git 2.54 that automatic run uses the `geometric` strategy and not the `gc` task: it "expires data in the reflog", puts unreachable objects into a cruft pack, and "Objects that are already part of a cruft pack will be expired" (`git help maintenance`; [maintenance configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/maintenance.adoc)). The Phase 0 report of this course traced such a run on Git 2.55.0 and found the same expiry values at work: `git reflog expire --all` and a repack with a cruft expiration of two weeks. The retention periods of section 13.4 therefore hold under either strategy. Chapter 26: Performance covers maintenance itself.

> **Version note.** Older behavior: commands ran `git gc --auto`, and unreachable objects were kept as loose files. Current behavior: automatic maintenance uses the geometric strategy, and unreachable objects are kept in cruft packs. Since: cruft packs are the default from Git 2.41, the geometric strategy from Git 2.54. Recommended: nothing to configure; the manual of `git gc` still describes the older trigger, so read "automatic gc" in older texts as "automatic maintenance".

## 13.14 Prevention: backup refs and bundles

**A backup ref before every risky operation.** A branch costs one small file. Created before a rebase, a history filter, a large merge or a reset, it turns recovery into one command that needs no reflog, no search and no deadline:

<!-- snippet: ch13/backup-and-bundle/01-backup-ref -->
```text
$ git log --oneline main..HEAD
72b1150 fixup! Rerank the top 20
68e6fff Rerank the top 20
155d4ba Add reranker
$ git branch backup/rerank-before-squash
$ git rebase -q --autosquash main
$ git log --oneline main..HEAD
120120d Rerank the top 20
155d4ba Add reranker
```
<!-- /snippet -->

<!-- snippet: ch13/backup-and-bundle/02-compare-and-restore -->
```text
$ git diff --stat backup/rerank-before-squash HEAD
$ git range-diff main backup/rerank-before-squash HEAD
1:  155d4ba = 1:  155d4ba Add reranker
2:  68e6fff < -:  ------- Rerank the top 20
3:  72b1150 < -:  ------- fixup! Rerank the top 20
-:  ------- > 2:  120120d Rerank the top 20
# Had the result been wrong, one command would undo it, with no reflog involved:
$ git reset --hard backup/rerank-before-squash
HEAD is now at 72b1150 fixup! Rerank the top 20
$ git log --oneline main..HEAD
72b1150 fixup! Rerank the top 20
68e6fff Rerank the top 20
155d4ba Add reranker
```
<!-- /snippet -->

The empty `git diff --stat` proves that the squashed branch has the same content as the original, and `git range-diff` shows how the commits map (Chapter 9, section 9.14). You compare against a name, not against a reflog position that moves. Delete the backup when the result is pushed and verified. For work in progress, a push to a personal branch on the server adds layer 4.

**In one sentence, the bundle.** `git bundle` writes refs and the objects they reach into one file that Git can clone and fetch from, which makes it a backup you can copy anywhere.

**Precisely.** A bundle is a pack file with a header that lists refs (`git help bundle`). `git bundle create <file> --all` 🟢 includes every ref; `git bundle verify` checks the file and says whether it is self-contained.

<!-- snippet: ch13/backup-and-bundle/03-bundle-create -->
```text
$ git bundle create ../searchsvc-2026-09-07.bundle --all
$ git bundle verify ../searchsvc-2026-09-07.bundle
../searchsvc-2026-09-07.bundle is okay
The bundle contains these 5 refs:
72b11500bad27ce9dc19833da51fca7015d8655c refs/heads/backup/rerank-before-squash
72b11500bad27ce9dc19833da51fca7015d8655c refs/heads/feature/rerank
da62b6073a1d8c0afa10417bc244ed245ccdff86 refs/heads/main
da62b6073a1d8c0afa10417bc244ed245ccdff86 refs/tags/v0.3.0
72b11500bad27ce9dc19833da51fca7015d8655c HEAD
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
```
<!-- /snippet -->

<!-- snippet: ch13/backup-and-bundle/04-bundle-use -->
```text
$ git bundle list-heads ../searchsvc-2026-09-07.bundle
72b11500bad27ce9dc19833da51fca7015d8655c refs/heads/backup/rerank-before-squash
72b11500bad27ce9dc19833da51fca7015d8655c refs/heads/feature/rerank
da62b6073a1d8c0afa10417bc244ed245ccdff86 refs/heads/main
da62b6073a1d8c0afa10417bc244ed245ccdff86 refs/tags/v0.3.0
72b11500bad27ce9dc19833da51fca7015d8655c HEAD
$ git clone -q ../searchsvc-2026-09-07.bundle ../restored
$ git -C ../restored log --oneline --graph --all
* 72b1150 fixup! Rerank the top 20
* 68e6fff Rerank the top 20
* 155d4ba Add reranker
* da62b60 Raise top_k to 10
* 536f5df Add embedding client
* 538ea2f Add retriever config
```
<!-- /snippet -->

A bundle holds what its refs reach, and Git recomputes every object ID when it reads one. It does not hold reflogs, the index, hooks, the configuration, or untracked files, and of the stash at most the newest entry, which `refs/stash` names. For stashes, Git 2.51 added `git stash export` and `git stash import`, which turn the stash list into a chain of commits that can be pushed and fetched (`git help stash`). A copy of the whole directory, made while no Git command runs, holds everything, and verifies nothing. Use both kinds for a repository you cannot afford to lose, and run `git fsck` on the copy.

**In production.** A team that keeps experiment branches for months should not rely on the reflog of one laptop. Push the branches, and before a history rewrite store a bundle of the old state with the incident record: it preserves every old commit ID that experiment logs and model cards refer to.

## 13.15 The server side: what GitHub adds

> **GitHub, not Git.** Everything in this section is a feature of the GitHub platform. It is described from GitHub's documentation, not from a run, and [Chapter 30: Incident Response](ch30-incident-response.md) works through the incidents.

Git gives a server no reflog by default, and you cannot run `git reflog` or `git fsck` on GitHub's copy of your repository. GitHub provides its own instruments instead.

| Instrument | What it gives you | Limits and flags |
|---|---|---|
| [Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository) of a repository | Pushes, force pushes, merges, branch creations and deletions, with the user and a comparison | Described from the documentation |
| ["Restore branch"](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request) on a closed pull request | Recreates the deleted head branch | Only for branches that had a pull request |
| [Events API](https://docs.github.com/en/rest/activity/events) | `PushEvent` records whose `before` and `head` fields are the IDs on both sides of a push | The last 300 events and 30 days; delivery can lag by 30 seconds to 6 hours |
| [Git references API](https://docs.github.com/en/rest/git/refs#create-a-reference) | Creates a ref at a commit ID you supply | Works only while GitHub still has the commit |
| [Audit log](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization) | Organization events for 180 days | Git events such as `git.push` are in the enterprise log only, for seven days, through the REST API, streaming or export; a search by token hash does not return them, so that question needs the export ([Chapter 21B](ch21b-repository-security-incident-response.md), section 21B.8) |

The recipe these pieces suggest is to read the ID from before the force push in the Activity view or a `PushEvent`, and to create a branch at it:

```bash
gh api repos/OWNER/REPO/git/refs -f ref=refs/heads/recovered -f sha=<commit ID from before the force push>
```

> **Unverified.** GitHub documents each instrument, not this combined procedure, and it publishes no retention period for commits that no ref reaches. One group of researchers observed that such commits appear to be kept indefinitely ([Truffle Security](https://trufflesecurity.com/blog/guest-post-how-i-scanned-all-of-github-s-oops-commits-for-leaked-secrets)); that is their observation, not a statement by GitHub.

GitHub's own advice for a deleted or force-pushed branch is the plain Git route of section 13.10: ask a collaborator who still has the commit to push it to a new branch ([troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone)). The same persistence means that a force push does not remove a leaked secret from GitHub; rotation is the remedy (Chapter 21B). Prevention on this layer is a ruleset that blocks force pushes and deletions on shared branches (Chapter 18).

## 13.16 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| `git reset --hard ORIG_HEAD` lands on an unrelated commit | `git log -1 ORIG_HEAD`: the slot was written by an earlier reset, merge or rebase | Reset by entry of the branch reflog | Use `ORIG_HEAD` only as the next command; otherwise the reflog |
| `HEAD@{1}` is not the commit you expected | Any later movement, even a switch, shifts the positions | Search with `git log -g --grep-reflog=...`; use the full ID | Anchor with a branch as soon as you find the commit |
| `git reflog show <branch>` fails with "unknown revision" | The branch was deleted and its log with it | HEAD reflog, the printed `(was ...)` ID, or `git fsck --no-reflogs` | Delete with `-d`; read the refusal |
| The reflog is empty in a fresh clone or on the CI runner | Reflogs are local and start with the clone | The clone where the work was done; the server; a teammate | Push work in progress |
| `git stash list` is empty after housekeeping | Reflogs were expired with an explicit cut-off | `git stash pop` for the newest; the fsck recipe for the rest | Branches for long-lived work |
| A recovered commit conflicts when cherry-picked | It depends on commits you did not pick | Abort; pick the range, or merge the rescue branch (Lab 12.7) | Inspect with `git log <tip> --not --all` first |
| `fatal: bad object refs/remotes/...` on fetch | An empty or damaged ref file | Remove the file, fetch | Keep repositories out of file-syncing folders |
| `error: bad signature` and `index file corrupt` | Damaged `.git/index` | Move it away, `git reset` | The same |
| `missing blob`, `missing tree` or `broken link` in `git fsck` | A reachable object is gone or unreadable | Another copy of the object (section 13.11) | Backups, pushes, periodic `git fsck` |

## 13.17 When not to use it, and dangerous edge cases

- **Do not recover a secret.** If the "lost" commit contains a credential, restoring it puts the credential back on a branch. Rotate first (Chapter 21B).
- **Do not rewind shared history to recover.** On a branch that others have pulled, add commits (revert, merge, cherry-pick). Moving the branch backwards turns one incident into several.
- **Do not "clean up" during an incident.** `git gc`, `git prune`, `git stash clear` and `git reflog expire` remove the evidence you are about to need. So does deleting and re-cloning the repository, the classic non-fix: the clone has no reflog and none of your unpushed objects.
- **Copy the repository before a doubtful repair.** `cp -R` of the whole directory, made while no Git command runs, preserves reflogs and unreachable objects. Work on the copy.
- **A reflog date is the committer date of the moment.** Time selectors such as `main@{yesterday}` trust the clock of the machine at the time of each entry, and a script that sets `GIT_COMMITTER_DATE` writes that date into the reflog.
- **Each working tree has its own HEAD reflog.** With linked working trees (Chapter 25), detached work done in one of them is recorded in that tree's HEAD log, and removing the working tree removes the log. Branch reflogs are shared.
- **`git fsck --lost-found` accumulates.** It never removes old files from `.git/lost-found`. Clear the directory before a new search.
- **Recovered is not verified.** A branch that points at the right commit proves nothing about the working tree you now have. Run the tests.

## 13.18 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git reflog`, `git log -g`, `git reflog list`, `git fsck` with `--no-reflogs`, `--unreachable`, `--dangling` | 🟢 SAFE | Nothing | Not needed | Not needed |
| `git fsck --lost-found` | 🟢 SAFE | Writes files under `.git/lost-found/` | `git fsck` | Delete the directory |
| `git branch <name> <id>`, `git tag <name> <id>` | 🟢 SAFE | Adds one ref | Not needed | `git branch -d`, `git tag -d` |
| `git bundle create` | 🟢 SAFE | Writes one file outside `.git` | `git bundle verify` afterwards | Delete the file |
| `git stash store <id>`, `git stash apply <id>` | 🟢 SAFE / 🟡 CAUTION | `store` adds a reflog line; `apply` changes the working tree and can conflict | `git stash show -p <id>` | `git stash drop`; `git restore` |
| `git cherry-pick <id>`, `git merge <rescue branch>` | 🟡 CAUTION | New commits on the current branch | `git show --stat <id>`, `git cherry -v` | `--abort`; the branch reflog |
| `git reset --keep <id>`, `git rebase --onto ...` | 🟡 CAUTION | Move the branch | `git log <id>`, a backup branch | The branch reflog, the backup branch |
| `git reset --hard <id>` | 🔴 DANGEROUS | Moves the branch and overwrites index and working tree; destroys unstaged work | `git status`, `git stash -u` first | Commits: reflog. Staged work: `git fsck --lost-found`. Unstaged work: none |
| `git fetch --prune` | 🟡 CAUTION | Deletes stale remote-tracking refs and their reflogs | `git remote prune --dry-run <remote>` | `git fsck --lost-found`, within the grace period |
| `git branch -D`, `git stash drop`, `git stash clear` | 🔴 DANGEROUS | Delete a ref or stash entries together with their reflog lines | `git branch -d`; `git stash show -p` | Sections 13.8 and 13.9, while the objects exist |
| `git reflog expire`, `git reflog delete`, `git reflog drop` | 🔴 DANGEROUS | Remove reflog entries | `--dry-run --verbose` | `git fsck`, until a prune |
| `git gc --prune=now`, `git prune` | 🔴 DANGEROUS | Delete unreachable objects | `git prune -n` | None in this repository |
| `rm` of a file under `.git/refs` or of `.git/index` | 🔴 DANGEROUS | Removes a ref or the index outside Git's locking | Move the file aside instead of deleting it | Move it back |

## 13.19 Version notes

> **Version note.** Older behavior: `git fsck` treated every reflog entry as a starting point. Current behavior: it skips entries dated after the moment it starts. Since: Git 2.53. Recommended: treat "dangling" as information and compare with `git reflog` (Chapter 3, section 3.8).

> **Version note.** Older behavior: `git reflog` had the subcommands `show`, `expire`, `delete` and `exists`. Current behavior: `list` names the refs that have a log, and `drop` removes a whole log. Since: Git 2.45 and Git 2.50. Recommended: `git reflog list` as the first command in a repository you do not know.

> **Version note.** Older behavior: stash entries could not be transferred between repositories. Current behavior: `git stash export` and `git stash import`. Since: Git 2.51 (`git help gitfaq`). Recommended: still prefer a branch for work that must survive.

> **Outdated advice.** "Undo the last merge with `git reset --hard HEAD~1`" works only when a merge commit was created. "Run `git gc --prune=now --aggressive` to fix a slow repository" deletes the safety net as a side effect. "Delete the folder and clone again" discards every unpushed commit, stash and reflog entry.

The retention defaults of section 13.4 are the same in Git 2.55 and 2.56.

## 13.20 Practice

- Labs 12.1 to 12.12 in the [Module 12 lab manual](../lab-manual/m12-recovery.md). Do each lab twice: first with the guide, then after running its setup script again, from the symptom alone.
- Replay any transcript with `labs/run ch13/<demo>`, for example `labs/run ch13/gc-ladder`. The sandbox stays in place for your own experiments.
- Three drills in sandboxes left by replays:
  1. In `ch13/reflog-retention/searchsvc`, explain every line of `git fsck --unreachable`.
  2. In `ch13/fsck-find/searchsvc`, delete `rescue/hybrid` again and recover it with the HEAD reflog only.
  3. In `ch13/corruption/searchsvc`, remove the object of `HEAD^{tree}` and repair the repository in two different ways.

## 13.21 Interview questions

1. Someone lost work. Which three questions do you ask before you type anything, and what does each answer rule in or out?
2. What is the difference between the HEAD reflog and a branch reflog? Give an incident for which only the first helps and one for which the second is the better tool.
3. State the default retention periods, say which event starts each period, and explain why "30 days plus two weeks" is not a guarantee.
4. Name the situations in which a reflog does not exist or is deleted at once. How do you recover in each?
5. `git reset --hard ORIG_HEAD` restored the wrong state. Explain the mechanism and the correct procedure.
6. What is the difference between a dangling and an unreachable object, and why does `git fsck` hide some lost commits unless you pass `--no-reflogs`?
7. A file was staged and then wiped by `git reset --hard`. What exactly can you get back, how, and what is gone? Why?
8. A teammate force-pushed over two commits on `main`. What evidence exists in your clone, on the server, and in other clones, and which repair do you choose?
9. `git fsck` reports `missing tree`. Why does `git fetch` not repair it, and what does?
10. Describe precisely what `git reflog expire --expire=now --all` followed by `git gc --prune=now` does, when it is appropriate, and what can still bring a commit back afterwards.
11. On GitHub, a branch was deleted after its pull request was closed, and another was force-pushed. Which GitHub instruments apply to each, and what are their limits?

## 13.22 Sources

**Primary sources**

- [git-reflog](https://git-scm.com/docs/git-reflog), [git-fsck](https://git-scm.com/docs/git-fsck), [git-gc](https://git-scm.com/docs/git-gc) (with its NOTES section), [git-prune](https://git-scm.com/docs/git-prune), [git-bundle](https://git-scm.com/docs/git-bundle), [git-stash](https://git-scm.com/docs/git-stash) (the recovery recipe in EXAMPLES), [git-branch](https://git-scm.com/docs/git-branch), [git-fetch](https://git-scm.com/docs/git-fetch), [gitrevisions](https://git-scm.com/docs/gitrevisions), [git-maintenance](https://git-scm.com/docs/git-maintenance), [git-pack-objects](https://git-scm.com/docs/git-pack-objects), [git-unpack-objects](https://git-scm.com/docs/git-unpack-objects), [gitfaq](https://git-scm.com/docs/gitfaq).
- Configuration reference at the 2.56.0 tag: [gc](https://github.com/git/git/blob/v2.56.0/Documentation/config/gc.adoc), [core](https://github.com/git/git/blob/v2.56.0/Documentation/config/core.adoc), [maintenance](https://github.com/git/git/blob/v2.56.0/Documentation/config/maintenance.adoc).
- Git source at the 2.55.0 tag: [reflog.c](https://github.com/git/git/blob/v2.55.0/reflog.c) (the expiry rules and the stash exemption), [builtin/stash.c](https://github.com/git/git/blob/v2.55.0/builtin/stash.c).
- [How to recover a corrupted blob object](https://github.com/git/git/blob/v2.56.0/Documentation/howto/recover-corrupted-blob-object.adoc), a how-to in Git's documentation, written in 2007; its method is unchanged.
- [Release notes of Git 2.36](https://github.com/git/git/blob/master/Documentation/RelNotes/2.36.0.adoc) for `git fetch --refetch`.
- GitHub Docs: [Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository), [deleting and restoring branches in a pull request](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request), [events API](https://docs.github.com/en/rest/activity/events), [create a reference](https://docs.github.com/en/rest/git/refs#create-a-reference), [troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone).

**Secondary sources**

- Pro Git, [Maintenance and Data Recovery](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery). Caveats: it gives "around 7,000" loose objects as the automatic threshold where the configuration reference says 6700, and it predates cruft packs.
- The Phase 0 report of this course, sections 1, 12 and 13, for the retention defaults, the traced maintenance run and the GitHub instruments.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- [How to Rescue Your Commits with Git Reflog](https://www.youtube.com/watch?v=K7-wrGpnqUM), System Crafters, 14 minutes, November 2024: a deleted branch, commits in detached HEAD, a rebase mistake. Caveat: `master` and `checkout`.
- [Intern DELETED a Git Branch!](https://www.youtube.com/watch?v=jXoOEfpgzF4), Chai aur Code, Hindi, 9 minutes, 4 March 2026: a deleted branch recovered through the reflog. A single scenario.
- [The BIGGEST Git Mistake Every Intern Makes](https://www.youtube.com/watch?v=xZNQitQo5KI), Chai aur Code, Hindi, 14 minutes, 4 March 2026: commits on the wrong branch, moved with cherry-pick and reset. A single scenario.

**Further reading**

- Chapter 30: Incident Response, for the same accidents at team scale, and the disaster-recovery playbook that grows out of the method of section 13.7.
