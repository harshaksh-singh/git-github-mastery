# YouTube metadata for the video course

For each of the 201 videos: the title, the description and the thumbnail file, in upload order and grouped by course part. The title and the description are in plain blocks so that they can be copied exactly. The same data is in [`thumbnails/thumbnail-data.json`](thumbnails/thumbnail-data.json), which is the source of truth; the thumbnails are described in [`thumbnails/README.md`](thumbnails/README.md).

Titles are at most 70 characters and descriptions at most 300, each in two sentences. A title ends with the series name and the video number only where that fits in the limit.

| Part | Videos | Count |
|---|---|---|
| 0: Orientation | V001 to V006 | 6 |
| 1: Foundations | V007 to V029 | 23 |
| 2: Integration and collaboration mechanics | V030 to V065 | 36 |
| 3: Investigation, recovery and power tools | V066 to V098 | 33 |
| 4: Git internals | V099 to V114 | 16 |
| 5: GitHub | V115 to V141 | 27 |
| 6: CI/CD with GitHub Actions | V142 to V155 | 14 |
| 7: Security | V156 to V169 | 14 |
| 8: Professional practice | V170 to V179 | 10 |
| 9: Production debugging and incident response | V180 to V194 | 15 |
| 10: Senior engineer: assessment | V195 to V198 | 4 |
| 11: Expert: the frontier | V199 to V201 | 3 |

## Part 0: Orientation

### V001

Title:

```text
How This Git Course Works: Book, Lab Sandbox, Fixed Clock
```

Description:

```text
You will be able to open the lab sandbox, run a lab and check every transcript against real output. You will also know how the book, the labs, the exercises and the gates fit together.
```

Thumbnail: [`thumbnails/V001.png`](thumbnails/V001.png)

### V002

Title:

```text
Git vs GitHub: What Version Control Actually Solves
```

Description:

```text
You will be able to say what problem version control solves and why every clone is a full repository. You will also separate what Git does from what GitHub adds on top.
```

Thumbnail: [`thumbnails/V002.png`](thumbnails/V002.png)

### V003

Title:

```text
Your First Git Repository, Read File by File
```

Description:

```text
You will be able to create a repository and follow one file from untracked to staged to committed. You will also see which files and which ref each command wrote.
```

Thumbnail: [`thumbnails/V003.png`](thumbnails/V003.png)

### V004

Title:

```text
The Root-Cause Framework for Any Git Problem
```

Description:

```text
You will be able to work from a symptom to a tested root cause instead of guessing at commands. You will also write the seven-line summary that records the fix and its prevention.
```

Thumbnail: [`thumbnails/V004.png`](thumbnails/V004.png)

### V005

Title:

```text
Diagnose Any Git Repository With Ten Read-Only Commands
```

Description:

```text
You will be able to read the full state of a repository with ten commands that change nothing. You will also know which question each command answers.
```

Thumbnail: [`thumbnails/V005.png`](thumbnails/V005.png)

### V006

Title:

```text
Worked Example: The Fix That Was Committed but Did Not Ship
```

Description:

```text
You will be able to apply the diagnosis ritual to a real symptom and separate three hypotheses with one test. You will also recognize the common first-day mistakes.
```

Thumbnail: [`thumbnails/V006.png`](thumbnails/V006.png)

## Part 1: Foundations

### V007

Title:

```text
Git Stores Snapshots, Not Diffs: Content Addressing Explained
```

Description:

```text
You will be able to explain why a commit is a full snapshot and where a diff comes from. You will also compute an object ID yourself and see why identical content is stored once.
```

Thumbnail: [`thumbnails/V007.png`](thumbnails/V007.png)

### V008

Title:

```text
Build a Git Commit by Hand From Blobs and Trees
```

Description:

```text
You will be able to name the four object types and say what each one holds. You will also build a commit with plumbing commands only and point a branch at it.
```

Thumbnail: [`thumbnails/V008.png`](thumbnails/V008.png)

### V009

Title:

```text
The Commit Graph: Reachability, Refs and HEAD
```

Description:

```text
You will be able to read history as a graph walked backwards from its tips. You will also test whether one commit can reach another and say what HEAD points at.
```

Thumbnail: [`thumbnails/V009.png`](thumbnails/V009.png)

### V010

Title:

```text
The Three Trees of Git and the Mental Models That Fail
```

Description:

```text
You will be able to place any change in HEAD, the index or the working tree. You will also replace the common wrong models of what a commit is with the correct one.
```

Thumbnail: [`thumbnails/V010.png`](thumbnails/V010.png)

### V011

Title:

```text
How to Read git status: Tracked, Untracked and Ignored Files
```

Description:

```text
You will be able to read every section of git status as a comparison between two trees. You will also sort any file into tracked, untracked or ignored.
```

Thumbnail: [`thumbnails/V011.png`](thumbnails/V011.png)

### V012

Title:

```text
.gitignore Not Working? The Already-Tracked Trap
```

Description:

```text
You will be able to write ignore patterns and find the exact rule that matches a path. You will also stop tracking a file that was committed before the rule existed.
```

Thumbnail: [`thumbnails/V012.png`](thumbnails/V012.png)

### V013

Title:

```text
git restore, git mv, git rm and Why Git Records No Renames
```

Description:

```text
You will be able to restore a file from the index or from any commit and know what that overwrites. You will also explain how Git detects a rename that it never stored.
```

Thumbnail: [`thumbnails/V013.png`](thumbnails/V013.png)

### V014

Title:

```text
File Modes, Case-Insensitive Filesystems and Line Endings in Git
```

Description:

```text
You will be able to predict what Git records for modes, links and empty directories. You will also spot case and line-ending problems on macOS and preview git clean before it deletes.
```

Thumbnail: [`thumbnails/V014.png`](thumbnails/V014.png)

### V015

Title:

```text
The Git Index: What git add Actually Writes | Git & GitHub Mastery 015
```

Description:

```text
You will be able to read the index as the next commit in flat form. You will also explain why an edit made after git add is not in the staged version.
```

Thumbnail: [`thumbnails/V015.png`](thumbnails/V015.png)

### V016

Title:

```text
Three Diffs and Partial Staging With git add -p
```

Description:

```text
You will be able to choose the right diff for each pair of trees. You will also stage single hunks and know why a partially staged commit was never tested.
```

Thumbnail: [`thumbnails/V016.png`](thumbnails/V016.png)

### V017

Title:

```text
Unstage Three Ways: Deletions, Renames and the Scope of git add
```

Description:

```text
You will be able to stage deletions and renames and predict what each form of git add includes. You will also pick the right unstaging command for the case.
```

Thumbnail: [`thumbnails/V017.png`](thumbnails/V017.png)

### V018

Title:

```text
Reading the Git Index: ls-files, assume-unchanged, skip-worktree
```

Description:

```text
You will be able to script against the index with git ls-files. You will also explain why the two per-entry bits are not an ignore mechanism and how each one breaks.
```

Thumbnail: [`thumbnails/V018.png`](thumbnails/V018.png)

### V019

Title:

```text
What a Git Commit Is and How Its ID Is Computed
```

Description:

```text
You will be able to read a commit object field by field. You will also list the steps git commit performs and explain why any change gives a new ID.
```

Thumbnail: [`thumbnails/V019.png`](thumbnails/V019.png)

### V020

Title:

```text
Author vs Committer in Git: Two Dates and Parent Commits
```

Description:

```text
You will be able to tell author from committer and say which operations renew which field. You will also read root, ordinary and merge commits by their parents.
```

Thumbnail: [`thumbnails/V020.png`](thumbnails/V020.png)

### V021

Title:

```text
git commit --amend, Trailers and Atomic Commits
```

Description:

```text
You will be able to amend a commit knowing that it creates a new one and leaves the old in the reflog. You will also write messages and trailers that tools can read.
```

Thumbnail: [`thumbnails/V021.png`](thumbnails/V021.png)

### V022

Title:

```text
A Git Branch Is a Ref: What a Commit Does to HEAD
```

Description:

```text
You will be able to describe a branch as one ref that holds one commit ID. You will also read refs with plumbing whether they are loose or packed.
```

Thumbnail: [`thumbnails/V022.png`](thumbnails/V022.png)

### V023

Title:

```text
git branch and git switch: Every Option as a Ref Operation
```

Description:

```text
You will be able to create, rename, move and delete branches and predict each result. You will also know when git switch carries local changes and when it refuses.
```

Thumbnail: [`thumbnails/V023.png`](thumbnails/V023.png)

### V024

Title:

```text
Detached HEAD Explained: Keep the Commits You Made There
```

Description:

```text
You will be able to recognize a detached HEAD and say why Git itself uses it. You will also save commits made there before they are named only by the reflog.
```

Thumbnail: [`thumbnails/V024.png`](thumbnails/V024.png)

### V025

Title:

```text
Why Git Has No Parent Branch: Divergence and Ancestry
```

Description:

```text
You will be able to measure how far two branches have diverged and find their merge base. You will also explain why no branch records where it came from.
```

Thumbnail: [`thumbnails/V025.png`](thumbnails/V025.png)

### V026

Title:

```text
Lightweight Tags, Branch Naming Rules and Stale Branches
```

Description:

```text
You will be able to create lightweight tags and explain which ref names collide. You will also find branches that are safe to delete.
```

Thumbnail: [`thumbnails/V026.png`](thumbnails/V026.png)

### V027

Title:

```text
Git Configuration: Scopes, Precedence and Where a Value Comes From
```

Description:

```text
You will be able to find which file sets any Git setting. You will also read and write configuration at the right scope with the current subcommands.
```

Thumbnail: [`thumbnails/V027.png`](thumbnails/V027.png)

### V028

Title:

```text
includeIf, Aliases and GIT_TRACE: Configuration for Diagnosis
```

Description:

```text
You will be able to switch identity by directory with conditional includes. You will also define aliases and use trace variables to see what Git actually runs.
```

Thumbnail: [`thumbnails/V028.png`](thumbnails/V028.png)

### V029

Title:

```text
Gate Briefing: Git Fundamentals | Git & GitHub Mastery 029
```

Description:

```text
You will know what the Fundamentals gate covers, how it is scored and what the hands-on part expects. You will also be able to plan your revision from the typical losses of points.
```

Thumbnail: [`thumbnails/V029.png`](thumbnails/V029.png)

## Part 2: Integration and collaboration mechanics

### V030

Title:

```text
Fast-Forward Merges, Divergence and the Merge Base
```

Description:

```text
You will be able to predict whether a merge is a fast-forward before running it. You will also find the merge base and explain why a fast-forward writes no object.
```

Thumbnail: [`thumbnails/V030.png`](thumbnails/V030.png)

### V031

Title:

```text
The True Merge: How Git's Three-Way Merge Decides Each Path
```

Description:

```text
You will be able to apply the per-path rule table to base, ours and theirs. You will also explain what Git does when two histories have more than one merge base.
```

Thumbnail: [`thumbnails/V031.png`](thumbnails/V031.png)

### V032

Title:

```text
Merge Strategies, -X Options and Exactly Why Conflicts Occur
```

Description:

```text
You will be able to state the exact condition that produces a conflict. You will also tell the option that settles conflicting hunks from the strategy that discards a whole side.
```

Thumbnail: [`thumbnails/V032.png`](thumbnails/V032.png)

### V033

Title:

```text
Anatomy of a Merge Conflict: Markers, Index Stages and .git
```

Description:

```text
You will be able to read a stopped merge in the working tree, the index and the repository directory. You will also extract base, ours and theirs for any conflicted path.
```

Thumbnail: [`thumbnails/V033.png`](thumbnails/V033.png)

### V034

Title:

```text
Resolving Merge Conflicts: Abort, Continue, Quit, Take One Side
```

Description:

```text
You will be able to resolve, stage and continue a merge or leave it cleanly. You will also know what taking one whole side silently discards.
```

Thumbnail: [`thumbnails/V034.png`](thumbnails/V034.png)

### V035

Title:

```text
Merge Conflicts Without Markers: Renames, Deletes and Binaries
```

Description:

```text
You will be able to recognize conflicts that leave no markers in any file. You will also resolve rename, modify/delete, add/add and binary conflicts from the index stages.
```

Thumbnail: [`thumbnails/V035.png`](thumbnails/V035.png)

### V036

Title:

```text
--ff-only, --no-ff, --squash: Control What a Merge Records
```

Description:

```text
You will be able to choose the merge form that leaves the history you want. You will also read first-parent history and explain what a squash does not record.
```

Thumbnail: [`thumbnails/V036.png`](thumbnails/V036.png)

### V037

Title:

```text
Merged Cleanly, Still Broken: Auditing a Merge
```

Description:

```text
You will be able to explain how a merge without conflicts can still break the code. You will also audit a merge commit and test a merge without touching your working tree.
```

Thumbnail: [`thumbnails/V037.png`](thumbnails/V037.png)

### V038

Title:

```text
What a Git Remote Is, and git clone Step by Step
```

Description:

```text
You will be able to take git clone apart into the commands it performs. You will also compare normal, bare and mirror clones by the refs each one holds.
```

Thumbnail: [`thumbnails/V038.png`](thumbnails/V038.png)

### V039

Title:

```text
git fetch: Exactly Which Refs Move | Git & GitHub Mastery 039
```

Description:

```text
You will be able to say what a fetch changes and what it leaves alone. You will also explain why git status can be out of date about the server.
```

Thumbnail: [`thumbnails/V039.png`](thumbnails/V039.png)

### V040

Title:

```text
Upstream Branches, push.default and What git pull Really Runs
```

Description:

```text
You will be able to read and set a branch's upstream. You will also predict what a bare push and a bare pull will do from the configuration.
```

Thumbnail: [`thumbnails/V040.png`](thumbnails/V040.png)

### V041

Title:

```text
git push Explained: Why the Server Rejects Your Push
```

Description:

```text
You will be able to describe a push as a request to move refs in another repository. You will also read the two rejection messages and choose the right response.
```

Thumbnail: [`thumbnails/V041.png`](thumbnails/V041.png)

### V042

Title:

```text
Force Push Safely: --force-with-lease and --force-if-includes
```

Description:

```text
You will be able to say exactly what a forced push removes from the server. You will also use the lease correctly and know what defeats it.
```

Thumbnail: [`thumbnails/V042.png`](thumbnails/V042.png)

### V043

Title:

```text
Multiple Remotes, Pruning and Branches Whose Upstream Is Gone
```

Description:

```text
You will be able to set up a repository that fetches from one remote and pushes to another. You will also prune stale remote-tracking branches and clean up after them.
```

Thumbnail: [`thumbnails/V043.png`](thumbnails/V043.png)

### V044

Title:

```text
Refspecs in Depth: Why a Clone Cannot See a Branch
```

Description:

```text
You will be able to read and write a refspec. You will also diagnose a branch that is invisible in a narrow clone from first principles.
```

Thumbnail: [`thumbnails/V044.png`](thumbnails/V044.png)

### V045

Title:

```text
Gate Briefing: Branching and Remotes | Git & GitHub Mastery 045
```

Description:

```text
You will know what the Branching gate covers, how it is scored and where candidates lose points. You will also be able to check a remote's real state before trusting a local ref.
```

Thumbnail: [`thumbnails/V045.png`](thumbnails/V045.png)

### V046

Title:

```text
The Git Undo Map: Four Places and git restore
```

Description:

```text
You will be able to locate what you want to undo in one of four places. You will also restore files or index entries from any commit without moving a branch.
```

Thumbnail: [`thumbnails/V046.png`](thumbnails/V046.png)

### V047

Title:

```text
git reset: --soft, --mixed, --hard and the Safer Resets
```

Description:

```text
You will be able to predict what each reset mode does to the branch, the index and the working tree. You will also know what a hard reset loses and which resets check first.
```

Thumbnail: [`thumbnails/V047.png`](thumbnails/V047.png)

### V048

Title:

```text
git revert: Undo a Published Commit Without Rewriting
```

Description:

```text
You will be able to undo a pushed commit with a new commit that applies the inverse change. You will also handle a revert sequence that stops halfway.
```

Thumbnail: [`thumbnails/V048.png`](thumbnails/V048.png)

### V049

Title:

```text
Reverting a Merge Commit and the Re-Merge Problem
```

Description:

```text
You will be able to revert a merge and choose the right mainline parent. You will also explain why merging the branch again brings back less than expected, and repair it.
```

Thumbnail: [`thumbnails/V049.png`](thumbnails/V049.png)

### V050

Title:

```text
git stash and git clean: Uncommitted Work Parked as Commits
```

Description:

```text
You will be able to park and restore uncommitted work, including staged and untracked files. You will also preview git clean and know that Git keeps no copy of what it removes.
```

Thumbnail: [`thumbnails/V050.png`](thumbnails/V050.png)

### V051

Title:

```text
Which Git Undo Command? A Decision Tree and Seven Scenarios
```

Description:

```text
You will be able to choose between restore, reset, revert, clean and stash from three questions. You will also work seven undo scenarios from an unpushed commit to a pushed merge.
```

Thumbnail: [`thumbnails/V051.png`](thumbnails/V051.png)

### V052

Title:

```text
What git rebase Really Does: New Commits, New IDs
```

Description:

```text
You will be able to explain a rebase as writing new commits and moving the branch to the last copy. You will also find the originals afterwards.
```

Thumbnail: [`thumbnails/V052.png`](thumbnails/V052.png)

### V053

Title:

```text
Inside git rebase: The State Directory, HEAD and Special Refs
```

Description:

```text
You will be able to read a rebase in progress from its state directory. You will also explain how an abort finds its way back to where you started.
```

Thumbnail: [`thumbnails/V053.png`](thumbnails/V053.png)

### V054

Title:

```text
git rebase --onto: Choose Which Commits Move and Where
```

Description:

```text
You will be able to state which commits a rebase will replay and onto what. You will also move a branch off a base that was squash-merged or rewritten.
```

Thumbnail: [`thumbnails/V054.png`](thumbnails/V054.png)

### V055

Title:

```text
Interactive Rebase: Reword, Squash, Fixup, Edit, Drop, Exec
```

Description:

```text
You will be able to edit, combine, split, drop and reorder commits with the todo list. You will also run a test after every step of a rebase.
```

Thumbnail: [`thumbnails/V055.png`](thumbnails/V055.png)

### V056

Title:

```text
Fixup Commits, --autosquash and Stacked Branches
```

Description:

```text
You will be able to record fixups that fold into their targets automatically. You will also rebase a stack of branches in one operation and keep its merges.
```

Thumbnail: [`thumbnails/V056.png`](thumbnails/V056.png)

### V057

Title:

```text
Rebase Conflicts: Who Is Ours and Who Is Theirs?
```

Description:

```text
You will be able to say which side is ours at each step of a rebase and why. You will also choose between continue, skip and quit, and spot commits that are already upstream.
```

Thumbnail: [`thumbnails/V057.png`](thumbnails/V057.png)

### V058

Title:

```text
git pull --rebase and Reviewing a Rebase With git range-diff
```

Description:

```text
You will be able to pull without writing merge commits. You will also compare two versions of a branch commit by commit to see what a rebase changed.
```

Thumbnail: [`thumbnails/V058.png`](thumbnails/V058.png)

### V059

Title:

```text
A Shared Branch Was Rebased: Repair It and Recover
```

Description:

```text
You will be able to explain what goes wrong when a branch others use is rewritten. You will also repair a teammate's clone and return from a bad rebase with the reflog.
```

Thumbnail: [`thumbnails/V059.png`](thumbnails/V059.png)

### V060

Title:

```text
Rebase or Merge? Publishing a Rebased Branch Safely
```

Description:

```text
You will be able to publish a rebased branch without destroying anyone's work. You will also weigh rebase against merge by what each does to history.
```

Thumbnail: [`thumbnails/V060.png`](thumbnails/V060.png)

### V061

Title:

```text
What git cherry-pick Does: A Three-Way Merge, a New Commit
```

Description:

```text
You will be able to name base, ours and theirs for a cherry-pick. You will also predict what the new commit keeps from the original and what it replaces.
```

Thumbnail: [`thumbnails/V061.png`](thumbnails/V061.png)

### V062

Title:

```text
Cherry-Pick Conflicts, the Sequencer and Empty Picks
```

Description:

```text
You will be able to read a stopped cherry-pick from its state files. You will also continue, skip or abort a range and handle picks whose change is already present.
```

Thumbnail: [`thumbnails/V062.png`](thumbnails/V062.png)

### V063

Title:

```text
The Backport Workflow: Cherry-Pick, Duplicates and Patch IDs
```

Description:

```text
You will be able to backport a fix to a release branch and leave a traceable record. You will also find which fixes a branch already has when ancestry cannot tell you.
```

Thumbnail: [`thumbnails/V063.png`](thumbnails/V063.png)

### V064

Title:

```text
A..B vs A...B: Git Revisions and Ranges for log and diff
```

Description:

```text
You will be able to name any commit with revision syntax. You will also read two-dot and three-dot ranges correctly in git log and in git diff, where they mean different things.
```

Thumbnail: [`thumbnails/V064.png`](thumbnails/V064.png)

### V065

Title:

```text
Gate Briefing: Merge and Rebase | Git & GitHub Mastery 065
```

Description:

```text
You will know what the Merge and rebase gate covers and which table carries most of it. You will also be able to name base, ours and theirs for each operation.
```

Thumbnail: [`thumbnails/V065.png`](thumbnails/V065.png)

## Part 3: Investigation, recovery and power tools

### V066

Title:

```text
Reading a Git Diff: Summaries, Renames, Whitespace, Algorithms
```

Description:

```text
You will be able to answer what changed before reading how it changed. You will also control rename detection, whitespace handling and the diff algorithm.
```

Thumbnail: [`thumbnails/V066.png`](thumbnails/V066.png)

### V067

Title:

```text
git log Is a Graph Query: Selection, Filters and Formats
```

Description:

```text
You will be able to select commits by path, author, message and date. You will also follow the mainline and print history in a format a script can read.
```

Thumbnail: [`thumbnails/V067.png`](thumbnails/V067.png)

### V068

Title:

```text
Set Questions in git log, and Searching Code With git grep
```

Description:

```text
You will be able to ask which commits one side has and the other lacks. You will also trace the chain between two commits and search tracked content with git grep.
```

Thumbnail: [`thumbnails/V068.png`](thumbnails/V068.png)

### V069

Title:

```text
History of One File: --follow, Pickaxe -S and -G, and log -L
```

Description:

```text
You will be able to follow one file across renames and find the commit that added or removed a string. You will also trace a range of lines and recover a deleted file.
```

Thumbnail: [`thumbnails/V069.png`](thumbnails/V069.png)

### V070

Title:

```text
git blame Done Right: Ignore Reformatting, Find Moved Code
```

Description:

```text
You will be able to say what a blame row does and does not assert. You will also look through formatting commits and moved code to the commit where a bug began.
```

Thumbnail: [`thumbnails/V070.png`](thumbnails/V070.png)

### V071

Title:

```text
git bisect: Find the Commit That Broke It by Binary Search
```

Description:

```text
You will be able to run a manual bisect from a good and a bad commit. You will also skip commits that cannot be tested and leave the bisect cleanly.
```

Thumbnail: [`thumbnails/V071.png`](thumbnails/V071.png)

### V072

Title:

```text
Automate git bisect: bisect run, Exit Codes and Pitfalls
```

Description:

```text
You will be able to write a test script that follows the bisect exit-code protocol. You will also use custom terms, replay a log and avoid the common failures.
```

Thumbnail: [`thumbnails/V072.png`](thumbnails/V072.png)

### V073

Title:

```text
What Git Keeps: Four Layers of Protection and the Reflog
```

Description:

```text
You will be able to name the four layers that protect your work. You will also read HEAD and branch reflogs to find any earlier position.
```

Thumbnail: [`thumbnails/V073.png`](thumbnails/V073.png)

### V074

Title:

```text
Reflog Retention, ORIG_HEAD and git fsck as a Search Tool
```

Description:

```text
You will be able to state how long Git keeps reflog entries and unreachable objects. You will also use git fsck to find commits that no reflog names.
```

Thumbnail: [`thumbnails/V074.png`](thumbnails/V074.png)

### V075

Title:

```text
Recover a Deleted Branch or a Hard Reset: The Method
```

Description:

```text
You will be able to follow one recovery method under pressure. You will also bring back commits after a hard reset, a deleted branch or a dropped commit.
```

Thumbnail: [`thumbnails/V075.png`](thumbnails/V075.png)

### V076

Title:

```text
Recover From a Wrong Rebase, a Bad Merge or the Wrong Branch
```

Description:

```text
You will be able to pick the right reflog for each kind of mistake. You will also undo a wrong rebase, a bad merge, commits on the wrong branch and a wrong cherry-pick.
```

Thumbnail: [`thumbnails/V076.png`](thumbnails/V076.png)

### V077

Title:

```text
Recover Uncommitted Work and a Dropped Stash
```

Description:

```text
You will be able to recover staged content and dropped stash entries from unreachable objects. You will also recover a branch from the remote side after a forced push.
```

Thumbnail: [`thumbnails/V077.png`](thumbnails/V077.png)

### V078

Title:

```text
A Damaged Git Repository: Repair and What Cannot Be Recovered
```

Description:

```text
You will be able to recognize missing and corrupt objects and repair them from another repository. You will also say plainly which work Git cannot bring back.
```

Thumbnail: [`thumbnails/V078.png`](thumbnails/V078.png)

### V079

Title:

```text
The Point of No Return: Expire, Prune, Backup Refs and Bundles
```

Description:

```text
You will be able to say which commands make data unrecoverable locally. You will also protect work in advance with backup refs and verified bundles.
```

Thumbnail: [`thumbnails/V079.png`](thumbnails/V079.png)

### V080

Title:

```text
Git Tags: Lightweight, Annotated, Signed and How They Travel
```

Description:

```text
You will be able to create and inspect each kind of tag. You will also predict which tags a fetch brings and which a push sends.
```

Thumbnail: [`thumbnails/V080.png`](thumbnails/V080.png)

### V081

Title:

```text
Why a Published Git Tag Must Never Move | Git & GitHub Mastery 081
```

Description:

```text
You will be able to explain what happens in old clones, new clones and caches after a tag is moved. You will also choose the low-risk repair.
```

Thumbnail: [`thumbnails/V081.png`](thumbnails/V081.png)

### V082

Title:

```text
git describe, Semantic Versioning and Release Branches
```

Description:

```text
You will be able to name any commit by its nearest tag and distance. You will also explain what breaks the count and how release branches look on the Git side.
```

Thumbnail: [`thumbnails/V082.png`](thumbnails/V082.png)

### V083

Title:

```text
Git Worktrees: What Is Shared and One Branch per Worktree
```

Description:

```text
You will be able to add a second working tree on the same repository. You will also say what the worktrees share and why one branch cannot be checked out twice.
```

Thumbnail: [`thumbnails/V083.png`](thumbnails/V083.png)

### V084

Title:

```text
Worktrees in Use: A Hotfix During a Rebase | Git & GitHub Mastery 084
```

Description:

```text
You will be able to start urgent work without aborting or stashing what is in progress. You will also remove, move, lock and repair worktrees correctly.
```

Thumbnail: [`thumbnails/V084.png`](thumbnails/V084.png)

### V085

Title:

```text
Stash Internals: A Stash Entry Is a Small Commit Graph
```

Description:

```text
You will be able to read a stash entry as commits with parents. You will also explain where older entries live and create a stash commit without touching the stash list.
```

Thumbnail: [`thumbnails/V085.png`](thumbnails/V085.png)

### V086

Title:

```text
git rerere: Resolve a Merge Conflict Once | Git & GitHub Mastery 086
```

Description:

```text
You will be able to turn on rerere and watch it replay a recorded resolution. You will also make it forget a wrong resolution before it repeats the mistake.
```

Thumbnail: [`thumbnails/V086.png`](thumbnails/V086.png)

### V087

Title:

```text
.gitattributes and Line Endings: Per-Path Settings That Travel
```

Description:

```text
You will be able to set line-ending rules that apply to every clone. You will also check which attributes a path has and renormalize an existing repository.
```

Thumbnail: [`thumbnails/V087.png`](thumbnails/V087.png)

### V088

Title:

```text
Diff Drivers, Merge Drivers, and Clean and Smudge Filters
```

Description:

```text
You will be able to change how a file type is displayed, merged or stored. You will also know which of these are configured per clone and can therefore be missing.
```

Thumbnail: [`thumbnails/V088.png`](thumbnails/V088.png)

### V089

Title:

```text
Git Hooks: Programs That Git Runs at Fixed Points
```

Description:

```text
You will be able to write a pre-commit hook that checks the staged content and a pre-push hook that reads its input. You will also know which commands skip which hooks.
```

Thumbnail: [`thumbnails/V089.png`](thumbnails/V089.png)

### V090

Title:

```text
Why Git Hooks Cannot Enforce Policy: --no-verify, hooksPath
```

Description:

```text
You will be able to share hooks through a tracked directory. You will also explain why a clone receives none and why enforcement belongs on the server.
```

Thumbnail: [`thumbnails/V090.png`](thumbnails/V090.png)

### V091

Title:

```text
Git Submodules: The Gitlink, .gitmodules and a Fresh Clone
```

Description:

```text
You will be able to describe a submodule as a recorded commit ID, a URL and a separate repository. You will also bring a fresh clone to a working state.
```

Thumbnail: [`thumbnails/V091.png`](thumbnails/V091.png)

### V092

Title:

```text
Submodules in Motion: Stale Pointers and the Silent Rollback
```

Description:

```text
You will be able to move a submodule pointer deliberately and commit it. You will also detect a stale submodule before it is committed back as a rollback.
```

Thumbnail: [`thumbnails/V092.png`](thumbnails/V092.png)

### V093

Title:

```text
Submodule Failures: Push Order, Pointer Conflicts and Removal
```

Description:

```text
You will be able to avoid publishing a pointer that nobody can fetch. You will also resolve pointer conflicts, change a URL and remove a submodule completely.
```

Thumbnail: [`thumbnails/V093.png`](thumbnails/V093.png)

### V094

Title:

```text
Submodule, Subtree or Package Manager? How to Choose
```

Description:

```text
You will be able to add, update and split a subtree. You will also choose between a submodule, a subtree and a package manager from a decision table.
```

Thumbnail: [`thumbnails/V094.png`](thumbnails/V094.png)

### V095

Title:

```text
Git LFS Explained: Pointer Files, Filters and Tracking
```

Description:

```text
You will be able to explain why large binaries hurt every clone. You will also track a file type with LFS and read the pointer that Git stores in its place.
```

Thumbnail: [`thumbnails/V095.png`](thumbnails/V095.png)

### V096

Title:

```text
Git LFS Day to Day: Status, Push, Fetch and the Local Store
```

Description:

```text
You will be able to push and fetch LFS content and see what a clone without the client contains. You will also prune the local store safely.
```

Thumbnail: [`thumbnails/V096.png`](thumbnails/V096.png)

### V097

Title:

```text
git lfs migrate, Common LFS Errors and When LFS Is Wrong
```

Description:

```text
You will be able to move existing history to LFS and name every consequence of the rewrite. You will also read the common LFS errors and decide when another tool fits better.
```

Thumbnail: [`thumbnails/V097.png`](thumbnails/V097.png)

### V098

Title:

```text
Gate Briefing: Recovery | Git & GitHub Mastery 098
```

Description:

```text
You will know what the Recovery gate covers and what fails candidates in the hands-on part. You will also be able to anchor lost work before attempting any repair.
```

Thumbnail: [`thumbnails/V098.png`](thumbnails/V098.png)

## Part 4: Git internals

### V099

Title:

```text
The .git Directory File by File and the Loose Object Format
```

Description:

```text
You will be able to name what each file and directory in the repository holds. You will also decode a loose object and reproduce its ID.
```

Thumbnail: [`thumbnails/V099.png`](thumbnails/V099.png)

### V100

Title:

```text
Git's Four Object Types in Full: cat-file, ls-tree and show
```

Description:

```text
You will be able to read tree entries and their modes. You will also list every object in a repository in batch mode for scripts.
```

Thumbnail: [`thumbnails/V100.png`](thumbnails/V100.png)

### V101

Title:

```text
git rev-parse: Turning Names Into Object IDs
```

Description:

```text
You will be able to resolve any revision to an ID safely in a script. You will also ask a repository for its paths and formats without reading its files.
```

Thumbnail: [`thumbnails/V101.png`](thumbnails/V101.png)

### V102

Title:

```text
Git Packfiles, Pack Indexes and Delta Compression
```

Description:

```text
You will be able to inspect a packfile and its index. You will also explain a delta as a storage detail that never changes what an object contains.
```

Thumbnail: [`thumbnails/V102.png`](thumbnails/V102.png)

### V103

Title:

```text
Reachability, git fsck and Where Git Verifies Its Hashes
```

Description:

```text
You will be able to list the starting points of git fsck and read its findings. You will also say which operations rehash objects and which trust what they read.
```

Thumbnail: [`thumbnails/V103.png`](thumbnails/V103.png)

### V104

Title:

```text
Why a Git Repository Gets Slow: gc, maintenance, Cruft Packs
```

Description:

```text
You will be able to tell which kind of size makes a repository slow. You will also run the right maintenance task and explain geometric repacking and cruft packs.
```

Thumbnail: [`thumbnails/V104.png`](thumbnails/V104.png)

### V105

Title:

```text
Git Refs in Depth: Loose, Packed, Symbolic and Root Refs
```

Description:

```text
You will be able to explain how refs and reflogs are stored. You will also read and update them with plumbing that works whatever the storage.
```

Thumbnail: [`thumbnails/V105.png`](thumbnails/V105.png)

### V106

Title:

```text
The Git Index File as a Data Structure | Git & GitHub Mastery 106
```

Description:

```text
You will be able to read an index entry with its mode, stage, flags and cached metadata. You will also explain why Git can skip reading files and when that goes wrong.
```

Thumbnail: [`thumbnails/V106.png`](thumbnails/V106.png)

### V107

Title:

```text
The Reftable Backend, and SHA-1 vs SHA-256 in Git
```

Description:

```text
You will be able to create and identify a reftable repository and a SHA-256 repository. You will also explain what Git's SHA-1 implementation detects.
```

Thumbnail: [`thumbnails/V107.png`](thumbnails/V107.png)

### V108

Title:

```text
Commit-Graph, Multi-Pack-Index and Reachability Bitmaps
```

Description:

```text
You will be able to write and verify a commit-graph. You will also say which slow operation each of Git's caches speeds up.
```

Thumbnail: [`thumbnails/V108.png`](thumbnails/V108.png)

### V109

Title:

```text
Shallow Clone vs Partial Clone: The Fetch Conversation
```

Description:

```text
You will be able to describe what client and server say during a fetch. You will also choose between a full, shallow and partial clone and name what each one breaks.
```

Thumbnail: [`thumbnails/V109.png`](thumbnails/V109.png)

### V110

Title:

```text
Git Bundles, and When Each Scale Feature Matters
```

Description:

```text
You will be able to create, verify and fetch from a bundle. You will also decide which scale feature a repository needs, if any.
```

Thumbnail: [`thumbnails/V110.png`](thumbnails/V110.png)

### V111

Title:

```text
Monorepo vs Polyrepo, and Sparse-Checkout in Cone Mode
```

Description:

```text
You will be able to weigh a monorepo against many repositories by their costs. You will also limit a working tree to chosen directories with cone mode.
```

Thumbnail: [`thumbnails/V111.png`](thumbnails/V111.png)

### V112

Title:

```text
Living in a Sparse Checkout, and the Sparse Index
```

Description:

```text
You will be able to predict which commands see only the cone and which see everything. You will also narrow a cone safely and turn on the sparse index.
```

Thumbnail: [`thumbnails/V112.png`](thumbnails/V112.png)

### V113

Title:

```text
Partial Clone Plus Sparse-Checkout: What scalar clone Sets Up
```

Description:

```text
You will be able to build a blobless sparse clone by hand and say what scalar would configure. You will also find the projects a change affects in a monorepo.
```

Thumbnail: [`thumbnails/V113.png`](thumbnails/V113.png)

### V114

Title:

```text
Gate Briefing: Git Internals | Git & GitHub Mastery 114
```

Description:

```text
You will know what the Internals gate covers and the kind of mechanism each question asks for. You will also be able to inspect a repository with plumbing instead of reading its files.
```

Thumbnail: [`thumbnails/V114.png`](thumbnails/V114.png)

## Part 5: GitHub

### V115

Title:

```text
Git Data vs GitHub Objects: Accounts, Roles and Settings
```

Description:

```text
You will be able to separate what lives in Git from what exists only on the platform. You will also name the repository roles and the settings that matter.
```

Thumbnail: [`thumbnails/V115.png`](thumbnails/V115.png)

### V116

Title:

```text
GitHub Forks and the Fork Network: What Is Really Shared
```

Description:

```text
You will be able to explain what a fork owns and what the network shares. You will also state the security consequence for commits pushed anywhere in it.
```

Thumbnail: [`thumbnails/V116.png`](thumbnails/V116.png)

### V117

Title:

```text
GitHub Issues, Projects, Templates and Community Health Files
```

Description:

```text
You will be able to set up issues, templates and health files in the locations GitHub reads. You will also lay out a repository professionally and know the platform's limits.
```

Thumbnail: [`thumbnails/V117.png`](thumbnails/V117.png)

### V118

Title:

```text
Authentication vs Authorization, and Git Credential Helpers
```

Description:

```text
You will be able to tell an identity failure from an access failure. You will also trace which credential helper answers Git over HTTPS.
```

Thumbnail: [`thumbnails/V118.png`](thumbnails/V118.png)

### V119

Title:

```text
GitHub Tokens: Fine-Grained vs Classic, and Never in a URL
```

Description:

```text
You will be able to choose a token kind with least privilege and an expiry. You will also find and remove a token that was written into a remote URL.
```

Thumbnail: [`thumbnails/V119.png`](thumbnails/V119.png)

### V120

Title:

```text
SSH for GitHub: Keys, the Agent, ~/.ssh/config and Host Keys
```

Description:

```text
You will be able to create a key, load it into the agent and test the connection. You will also read the effective configuration for a host and handle a host-key mismatch.
```

Thumbnail: [`thumbnails/V120.png`](thumbnails/V120.png)

### V121

Title:

```text
Two GitHub Identities on One Machine, SSO and Machine Users
```

Description:

```text
You will be able to keep two accounts apart with host aliases and conditional includes. You will also choose a credential for a machine and scope it correctly.
```

Thumbnail: [`thumbnails/V121.png`](thumbnails/V121.png)

### V122

Title:

```text
Diagnose GitHub Authentication Failures: SSH and HTTPS
```

Description:

```text
You will be able to attribute an error message to the program that printed it. You will also work through SSH and HTTPS failures with a decision tree.
```

Thumbnail: [`thumbnails/V122.png`](thumbnails/V122.png)

### V123

Title:

```text
What GitHub Creates When a Pull Request Opens
```

Description:

```text
You will be able to describe a pull request as a platform object over two refs. You will also fetch its head and reproduce its diff and commit list locally.
```

Thumbnail: [`thumbnails/V123.png`](thumbnails/V123.png)

### V124

Title:

```text
The Pull Request Lifecycle: Reviews, Checks and Mergeability
```

Description:

```text
You will be able to follow a pull request from draft to merged and read why it is blocked. You will also explain the two settings that deal with approvals after a new push.
```

Thumbnail: [`thumbnails/V124.png`](thumbnails/V124.png)

### V125

Title:

```text
Why a Pull Request Shows Unexpected Commits or a Huge Diff
```

Description:

```text
You will be able to trace any surprising pull request to its base, its head or its merge base. You will also repair the branch or change the base.
```

Thumbnail: [`thumbnails/V125.png`](thumbnails/V125.png)

### V126

Title:

```text
Stacked Pull Requests and Indirect Merges | Git & GitHub Mastery 126
```

Description:

```text
You will be able to explain when GitHub marks a pull request as merged. You will also keep a stack healthy after the bottom layer is squashed.
```

Thumbnail: [`thumbnails/V126.png`](thumbnails/V126.png)

### V127

Title:

```text
The Fork Workflow End to End, and How to Review Well
```

Description:

```text
You will be able to contribute through a fork from first clone to merged pull request. You will also keep the fork in sync and review someone else's branch locally.
```

Thumbnail: [`thumbnails/V127.png`](thumbnails/V127.png)

### V128

Title:

```text
GitHub's Three Merge Methods: Merge Commit, Squash, Rebase
```

Description:

```text
You will be able to reproduce each merge method locally. You will also say which commits keep their IDs and which are rewritten.
```

Thumbnail: [`thumbnails/V128.png`](thumbnails/V128.png)

### V129

Title:

```text
What Your Merge Method Costs Later: Bisect, Blame and Revert
```

Description:

```text
You will be able to predict how each merge method affects bisect, blame and revert. You will also explain what auto-merge and the merge queue do.
```

Thumbnail: [`thumbnails/V129.png`](thumbnails/V129.png)

### V130

Title:

```text
Git Tag vs GitHub Release: What the Release Adds
```

Description:

```text
You will be able to publish a release on a tag that you created and pushed yourself. You will also explain what GitHub creates when the tag does not exist.
```

Thumbnail: [`thumbnails/V130.png`](thumbnails/V130.png)

### V131

Title:

```text
GitHub Rulesets: What a Rule Is, Layering and Bypass
```

Description:

```text
You will be able to describe a rule as a test on a request to move a ref. You will also predict how several rulesets combine and who may bypass them.
```

Thumbnail: [`thumbnails/V131.png`](thumbnails/V131.png)

### V132

Title:

```text
Required Reviews, Status Checks and Their Traps
```

Description:

```text
You will be able to configure required reviews and status checks with their sub-options. You will also avoid a required check that never reports.
```

Thumbnail: [`thumbnails/V132.png`](thumbnails/V132.png)

### V133

Title:

```text
Tag Rulesets, Push Rulesets and Organization-Level Rules
```

Description:

```text
You will be able to protect tags on the server and write patterns that match what you intend. You will also explain how classic protection layers with rulesets.
```

Thumbnail: [`thumbnails/V133.png`](thumbnails/V133.png)

### V134

Title:

```text
Why Can't I Merge? Finding the Rule That Blocks a Pull Request
```

Description:

```text
You will be able to find which rule blocks a merge and to what it applies. You will also design the rules for a production branch.
```

Thumbnail: [`thumbnails/V134.png`](thumbnails/V134.png)

### V135

Title:

```text
CODEOWNERS: Location, Syntax and Why the Last Match Wins
```

Description:

```text
You will be able to write a CODEOWNERS file and predict the owner of any path. You will also avoid the syntax that is accepted and silently does nothing.
```

Thumbnail: [`thumbnails/V135.png`](thumbnails/V135.png)

### V136

Title:

```text
CODEOWNERS in Force: Base Branch, Monorepos and Reviewers
```

Description:

```text
You will be able to say which version of the file applies to a pull request. You will also protect the file itself and find out why a team is never requested.
```

Thumbnail: [`thumbnails/V136.png`](thumbnails/V136.png)

### V137

Title:

```text
Sign Git Commits With SSH: Setup and Verification End to End
```

Description:

```text
You will be able to sign commits and tags with an SSH key. You will also verify them locally against an allowed-signers file.
```

Thumbnail: [`thumbnails/V137.png`](thumbnails/V137.png)

### V138

Title:

```text
What a Git Signature Proves, and Author Spoofing
```

Description:

```text
You will be able to show that author and committer fields are only assertions. You will also state exactly what a valid signature binds and what it leaves open.
```

Thumbnail: [`thumbnails/V138.png`](thumbnails/V138.png)

### V139

Title:

```text
GitHub's Verified Badge: The States and What It Does Not Prove
```

Description:

```text
You will be able to read GitHub's verification states and say who signed a web or squash commit. You will also name what the badge does not prove.
```

Thumbnail: [`thumbnails/V139.png`](thumbnails/V139.png)

### V140

Title:

```text
The GitHub CLI and API: gh pr, gh api, REST and GraphQL
```

Description:

```text
You will be able to drive pull requests from the terminal and reach any endpoint with gh api. You will also handle pagination and rate limits and say when a GitHub App fits.
```

Thumbnail: [`thumbnails/V140.png`](thumbnails/V140.png)

### V141

Title:

```text
Gate Briefing: GitHub | Git & GitHub Mastery 141
```

Description:

```text
You will know what the GitHub gate covers and how its paper cases are built. You will also be able to keep Git facts and platform state apart in an answer.
```

Thumbnail: [`thumbnails/V141.png`](thumbnails/V141.png)

## Part 6: CI/CD with GitHub Actions

### V142

Title:

```text
The GitHub Actions Model, and YAML Read Carefully
```

Description:

```text
You will be able to name the parts of a workflow run and how they nest. You will also read YAML without being caught by its implicit types.
```

Thumbnail: [`thumbnails/V142.png`](thumbnails/V142.png)

### V143

Title:

```text
Actions Events, Filters, Contexts and Secrets
```

Description:

```text
You will be able to predict whether an event creates a run and for which commit. You will also choose correctly between env, vars and secrets.
```

Thumbnail: [`thumbnails/V143.png`](thumbnails/V143.png)

### V144

Title:

```text
GitHub Actions Shells, and Passing Data Between Steps and Jobs
```

Description:

```text
You will be able to predict how a run step's shell treats a failing command. You will also pass values between steps and between jobs.
```

Thumbnail: [`thumbnails/V144.png`](thumbnails/V144.png)

### V145

Title:

```text
What actions/checkout Does by Default: Depth, Tags, Merge Ref
```

Description:

```text
You will be able to say which commit a workflow checks out for each event. You will also fix the builds that need history or tags.
```

Thumbnail: [`thumbnails/V145.png`](thumbnails/V145.png)

### V146

Title:

```text
GitHub Actions: Job Control, Matrix, Caching and Artifacts
```

Description:

```text
You will be able to control when jobs run and what a skipped job reports. You will also use a matrix, a dependency cache and artifacts correctly.
```

Thumbnail: [`thumbnails/V146.png`](thumbnails/V146.png)

### V147

Title:

```text
Five CI Workflows Line by Line: Test, Lint, Build, Python, Java
```

Description:

```text
You will be able to read five complete workflows and explain every line. You will also adapt them with least-privilege permissions and pinned actions.
```

Thumbnail: [`thumbnails/V147.png`](thumbnails/V147.png)

### V148

Title:

```text
Image, Artifact and Matrix Workflows, and Action Versions
```

Description:

```text
You will be able to read workflows that build an image, hand over an artifact and run a matrix. You will also check action versions and runtimes on the day you use them.
```

Thumbnail: [`thumbnails/V148.png`](thumbnails/V148.png)

### V149

Title:

```text
Actions Environments: Staging, Approval and Promotion
```

Description:

```text
You will be able to deploy one build to staging and promote the same artifact to production. You will also protect an environment with an approval.
```

Thumbnail: [`thumbnails/V149.png`](thumbnails/V149.png)

### V150

Title:

```text
Concurrency Groups, Reusable Workflows and Composite Actions
```

Description:

```text
You will be able to stop overlapping deployments with a concurrency group. You will also choose between a reusable workflow, a composite action and a container action.
```

Thumbnail: [`thumbnails/V150.png`](thumbnails/V150.png)

### V151

Title:

```text
Publish a Container Image and Automate a Release
```

Description:

```text
You will be able to publish an image and deploy it by digest. You will also outline a tag-driven release and explain why some events start no further runs.
```

Thumbnail: [`thumbnails/V151.png`](thumbnails/V151.png)

### V152

Title:

```text
Runners, Limits, and How to Investigate a Failing Workflow
```

Description:

```text
You will be able to compare hosted and self-hosted runners. You will also investigate a failing workflow in a fixed order from the terminal.
```

Thumbnail: [`thumbnails/V152.png`](thumbnails/V152.png)

### V153

Title:

```text
Passes Locally, Fails on GitHub Actions: The Documented Causes
```

Description:

```text
You will be able to list how a runner differs from your machine. You will also test each cause on the Git side without rerunning the workflow.
```

Thumbnail: [`thumbnails/V153.png`](thumbnails/V153.png)

### V154

Title:

```text
Required Checks Stuck on Pending, and Debugging Actions
```

Description:

```text
You will be able to explain why a required check never reports and fix it. You will also use reruns and debug logging and know what a local emulator cannot reproduce.
```

Thumbnail: [`thumbnails/V154.png`](thumbnails/V154.png)

### V155

Title:

```text
Gate Briefing: GitHub Actions | Git & GitHub Mastery 155
```

Description:

```text
You will know what the Actions gate covers and how its paper cases are built. You will also be able to read a workflow file for faults before trusting it.
```

Thumbnail: [`thumbnails/V155.png`](thumbnails/V155.png)

## Part 7: Security

### V156

Title:

```text
The Actions Security Model: GITHUB_TOKEN and Permissions
```

Description:

```text
You will be able to analyze a workflow with five questions about code, token, runner, secrets and trigger. You will also set least-privilege permissions for the job token.
```

Thumbnail: [`thumbnails/V156.png`](thumbnails/V156.png)

### V157

Title:

```text
Fork Pull Requests and the Risk of pull_request_target
```

Description:

```text
You will be able to say what a workflow started from a fork can reach. You will also recognize the privileged-trigger pattern that hands secrets to untrusted code.
```

Thumbnail: [`thumbnails/V157.png`](thumbnails/V157.png)

### V158

Title:

```text
Script Injection in GitHub Actions via Untrusted Event Fields
```

Description:

```text
You will be able to spot an expression that turns untrusted text into shell code. You will also rewrite it so that the value arrives as data.
```

Thumbnail: [`thumbnails/V158.png`](thumbnails/V158.png)

### V159

Title:

```text
Pin GitHub Actions by Commit SHA: Why Tags Are Not Enough
```

Description:

```text
You will be able to explain why a tag reference can change under you. You will also pin actions to full commit IDs and keep the pins updated.
```

Thumbnail: [`thumbnails/V159.png`](thumbnails/V159.png)

### V160

Title:

```text
Actions Secrets, OIDC Federation and Why Masking Is No Boundary
```

Description:

```text
You will be able to explain what any step holding a secret can do with it. You will also replace stored cloud keys with short-lived tokens and treat caches and artifacts as untrusted.
```

Thumbnail: [`thumbnails/V160.png`](thumbnails/V160.png)

### V161

Title:

```text
A Secure-by-Default Workflow and a Review Checklist
```

Description:

```text
You will be able to review a workflow against a security checklist. You will also reason about an AI agent in a workflow that reads attacker-controlled text.
```

Thumbnail: [`thumbnails/V161.png`](thumbnails/V161.png)

### V162

Title:

```text
Actions Security Case Studies: Root Causes and Lessons
```

Description:

```text
You will be able to name the three patterns that recur in real Actions compromises. You will also map each case to the control that would have limited it.
```

Thumbnail: [`thumbnails/V162.png`](thumbnails/V162.png)

### V163

Title:

```text
Git Client Security: What a Clone Runs and the Three Guards
```

Description:

```text
You will be able to say what a clone copies and what it never copies. You will also explain the client's guards and the risk of an unpacked working repository.
```

Thumbnail: [`thumbnails/V163.png`](thumbnails/V163.png)

### V164

Title:

```text
Why Deleting or Force-Pushing Does Not Remove a Secret
```

Description:

```text
You will be able to find every ref and commit that still holds a secret. You will also explain why deletion, a forced push and going private do not remove it.
```

Thumbnail: [`thumbnails/V164.png`](thumbnails/V164.png)

### V165

Title:

```text
Secret Scanning, Push Protection, Dependabot, Code Scanning
```

Description:

```text
You will be able to respond correctly when push protection blocks a push. You will also say what secret scanning, Dependabot and code scanning do not cover.
```

Thumbnail: [`thumbnails/V165.png`](thumbnails/V165.png)

### V166

Title:

```text
Responding to a Leaked Secret: Six Steps in the Right Order
```

Description:

```text
You will be able to respond to a leaked secret in the order that limits damage. You will also explain why revocation comes before any rewrite.
```

Thumbnail: [`thumbnails/V166.png`](thumbnails/V166.png)

### V167

Title:

```text
History Rewriting as an Operation: The Mechanics
```

Description:

```text
You will be able to predict which commits get new IDs in a rewrite. You will also plan the operation from mirror clone to forced push and local cleanup.
```

Thumbnail: [`thumbnails/V167.png`](thumbnails/V167.png)

### V168

Title:

```text
After a History Rewrite: The Stale Clone That Pushes It Back
```

Description:

```text
You will be able to explain how an old clone returns removed history to the server. You will also repair a clone and name the controls that limit the damage.
```

Thumbnail: [`thumbnails/V168.png`](thumbnails/V168.png)

### V169

Title:

```text
Gate Briefing: Security | Git & GitHub Mastery 169
```

Description:

```text
You will know what the Security gate covers and why the order of your steps is scored. You will also be able to state the leak response sequence without notes.
```

Thumbnail: [`thumbnails/V169.png`](thumbnails/V169.png)

## Part 8: Professional practice

### V170

Title:

```text
Keep a Fork in Sync When Upstream Moves, and Fork Etiquette
```

Description:

```text
You will be able to keep a fork's main branch a pure fast-forward of upstream. You will also update a pull request branch the way the project expects.
```

Thumbnail: [`thumbnails/V170.png`](thumbnails/V170.png)

### V171

Title:

```text
GitHub Flow, Git Flow, GitLab Flow and Trunk-Based Development
```

Description:

```text
You will be able to describe each branching model by its long-lived branches and merge directions. You will also say which problems each one was designed for.
```

Thumbnail: [`thumbnails/V171.png`](thumbnails/V171.png)

### V172

Title:

```text
One Release and One Hotfix Under Two Branching Strategies
```

Description:

```text
You will be able to ship a hotfix under two branching strategies. You will also decide whether a fix merges upward or is backported, and verify that no branch lacks it.
```

Thumbnail: [`thumbnails/V172.png`](thumbnails/V172.png)

### V173

Title:

```text
Feature Flags, Merge Queues, Stacked Changes: What Evidence Shows
```

Description:

```text
You will be able to weigh feature flags, merge queues and stacked changes by their costs. You will also say what the published evidence supports and where it stops.
```

Thumbnail: [`thumbnails/V173.png`](thumbnails/V173.png)

### V174

Title:

```text
Git Best Practices With Reasons, Code Review, Commit Messages
```

Description:

```text
You will be able to give the reason behind each practice and the root cause behind each anti-pattern. You will also write commit messages that work as a queryable record.
```

Thumbnail: [`thumbnails/V174.png`](thumbnails/V174.png)

### V175

Title:

```text
What Belongs in Git: Notebooks and an Output-Stripping Filter
```

Description:

```text
You will be able to decide what an ML project commits and what it only references. You will also set up a clean filter that strips notebook outputs.
```

Thumbnail: [`thumbnails/V175.png`](thumbnails/V175.png)

### V176

Title:

```text
Data and Model Versioning, and Reproducibility Beyond the Commit
```

Description:

```text
You will be able to version data and models by reference. You will also record what a commit ID alone does not capture about a run.
```

Thumbnail: [`thumbnails/V176.png`](thumbnails/V176.png)

### V177

Title:

```text
.gitignore, .gitattributes and pre-commit for ML Projects
```

Description:

```text
You will be able to set up ignore and attribute rules before the first data file exists. You will also back pre-commit hooks with CI, since hooks can be skipped.
```

Thumbnail: [`thumbnails/V177.png`](thumbnails/V177.png)

### V178

Title:

```text
CI for ML Projects: LLM Evals, Fork PRs, Secrets and AI Agents
```

Description:

```text
You will be able to design CI for an ML project without exposing provider keys to fork pull requests. You will also assess the risk of GPU runners and coding agents.
```

Thumbnail: [`thumbnails/V178.png`](thumbnails/V178.png)

### V179

Title:

```text
Design Review Briefing: Branching, Governance, CI and Security
```

Description:

```text
You will know what the design review asks you to produce and defend. You will also be able to name the layer that enforces each decision.
```

Thumbnail: [`thumbnails/V179.png`](thumbnails/V179.png)

## Part 9: Production debugging and incident response

### V180

Title:

```text
Git Says Nothing to Push, but the Work Is Not on the Server
```

Description:

```text
You will be able to apply the full diagnosis method to a real case. You will also find why a push reports nothing to send while the server lacks the work.
```

Thumbnail: [`thumbnails/V180.png`](thumbnails/V180.png)

### V181

Title:

```text
I Pulled and the Push Is Still Rejected: A Worked Diagnosis
```

Description:

```text
You will be able to explain how a pull and a push can address different refs. You will also pick the right tool for each kind of question from the extended toolbox.
```

Thumbnail: [`thumbnails/V181.png`](thumbnails/V181.png)

### V182

Title:

```text
Stuck Mid-Merge or Mid-Rebase? Read the Operation in Progress
```

Description:

```text
You will be able to identify any operation in progress from its signature files. You will also choose between abort, quit and continue knowing what each one keeps.
```

Thumbnail: [`thumbnails/V182.png`](thumbnails/V182.png)

### V183

Title:

```text
Preserve Evidence Before You Fix: Refs, Bundles, GitHub Data
```

Description:

```text
You will be able to record and anchor the state of a repository before changing it. You will also collect the evidence that exists only on GitHub.
```

Thumbnail: [`thumbnails/V183.png`](thumbnails/V183.png)

### V184

Title:

```text
Choosing the Lowest-Risk Git Fix, and Verifying It
```

Description:

```text
You will be able to rank candidate fixes from read-only to shared rewrite. You will also verify a fix on every repository that showed the problem.
```

Thumbnail: [`thumbnails/V184.png`](thumbnails/V184.png)

### V185

Title:

```text
The Git Incident Loop, Severity and How to Run the Drills
```

Description:

```text
You will be able to run an incident through seven steps from stabilising to prevention. You will also judge severity and set up each of the ten drills.
```

Thumbnail: [`thumbnails/V185.png`](thumbnails/V185.png)

### V186

Title:

```text
Incident Drills: An Accidental Hard Reset, a Vanished Branch
```

Description:

```text
You will be able to recover what a hard reset left recoverable and say what is gone. You will also find which mechanism made a branch appear to disappear.
```

Thumbnail: [`thumbnails/V186.png`](thumbnails/V186.png)

### V187

Title:

```text
Incident Drills: Commit Missing on the Remote, a Bad Resolution
```

Description:

```text
You will be able to find where a commit that was pushed actually went. You will also locate the merge whose resolution dropped a change.
```

Thumbnail: [`thumbnails/V187.png`](thumbnails/V187.png)

### V188

Title:

```text
Incident Drill: A Shared Branch Was Rebased and Force-Pushed
```

Description:

```text
You will be able to repair a shared branch after a rewrite met a teammate's clone. You will also give the complete eleven-step response expected of a senior engineer.
```

Thumbnail: [`thumbnails/V188.png`](thumbnails/V188.png)

### V189

Title:

```text
Incident Drills: Force Push to the Wrong Branch, Rewritten Prod
```

Description:

```text
You will be able to find the witnesses that still hold the overwritten commits. You will also restore the branch and re-establish what production actually runs.
```

Thumbnail: [`thumbnails/V189.png`](thumbnails/V189.png)

### V190

Title:

```text
Incident Drill: A Pull Request Suddenly Shows 500 Changes
```

Description:

```text
You will be able to work out which endpoint or merge base caused the huge diff. You will also repair the pull request without losing the author's commits.
```

Thumbnail: [`thumbnails/V190.png`](thumbnails/V190.png)

### V191

Title:

```text
Incident Drill: CI Works Locally but Fails on GitHub Actions
```

Description:

```text
You will be able to find the Git-side difference between your machine and the runner. You will also give the senior-level response when a workflow suddenly starts failing.
```

Thumbnail: [`thumbnails/V191.png`](thumbnails/V191.png)

### V192

Title:

```text
Incident Drill: A Secret Is Committed | Git & GitHub Mastery 192
```

Description:

```text
You will be able to run the full response to a committed secret, starting with revocation. You will also scope the exposure, publish the rewrite and repair every clone.
```

Thumbnail: [`thumbnails/V192.png`](thumbnails/V192.png)

### V193

Title:

```text
The Incident Summary a CTO Needs, and Blameless Postmortems
```

Description:

```text
You will be able to write an incident summary that states the root cause and its layer. You will also turn that root cause into a control that prevents a repeat.
```

Thumbnail: [`thumbnails/V193.png`](thumbnails/V193.png)

### V194

Title:

```text
Gate Briefing: Production Debugging | Git & GitHub Mastery 194
```

Description:

```text
You will know what the Production debugging gate covers and that your command log is read. You will also be able to hold back state-changing commands until the evidence is in.
```

Thumbnail: [`thumbnails/V194.png`](thumbnails/V194.png)

## Part 10: Senior engineer: assessment

### V195

Title:

```text
The CTO Interview Series: Structure of a Strong Answer
```

Description:

```text
You will be able to structure a spoken answer and keep Git, GitHub and Actions apart. You will also practise with the question bank and its follow-up questions.
```

Thumbnail: [`thumbnails/V195.png`](thumbnails/V195.png)

### V196

Title:

```text
Briefing: The Final Git and GitHub Knowledge Test
```

Description:

```text
You will know the format, the item types and the pass marks of the final test. You will also be able to plan revision across the eighteen areas.
```

Thumbnail: [`thumbnails/V196.png`](thumbnails/V196.png)

### V197

Title:

```text
The Capstone: Eight Incidents at a Fictional Company
```

Description:

```text
You will know how the eight capstone stages arrive and what you must hand in for each. You will also be able to work when nobody names the cause.
```

Thumbnail: [`thumbnails/V197.png`](thumbnails/V197.png)

### V198

Title:

```text
Capstone Debrief: Reading Your Work Against the Evaluation
```

Description:

```text
You will be able to judge your own capstone work against the evaluation criteria. You will also recognize a different path that is equally safe and fully verified.
```

Thumbnail: [`thumbnails/V198.png`](thumbnails/V198.png)

## Part 11: Expert: the frontier

### V199

Title:

```text
The Road to Git 3.0: Planned Defaults, Removals and Opting In
```

Description:

```text
You will be able to say what Git 3.0 plans to change and what stays the same. You will also opt in early and try SHA-256 and reftable repositories locally.
```

Thumbnail: [`thumbnails/V199.png`](thumbnails/V199.png)

### V200

Title:

```text
git history, git replay, git last-modified and git repo
```

Description:

```text
You will be able to make single-purpose rewrites with git history and replay commits without a working tree. You will also query a repository with the newer commands.
```

Thumbnail: [`thumbnails/V200.png`](thumbnails/V200.png)

### V201

Title:

```text
Rust in Git, Release Notes and the Patch-Based Workflow
```

Description:

```text
You will be able to follow Git's development from its primary sources. You will also prepare, send and apply a patch series the way the Git project does.
```

Thumbnail: [`thumbnails/V201.png`](thumbnails/V201.png)
