# Chapter 6: Commits

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch06/`.

## 6.1 Why this matters

Three questions a CTO can ask about one week of history.

1. "Security reviewed commit X on Friday. Monday's build was made from commit Y. The diff between X and Y is empty. Did we deploy reviewed code or not?"
2. "`git log` dates this change 24 August. The release notes list it under 'merged since 1 September'. Which system is wrong?"
3. "Half of our release manager's commits appear on GitHub without her avatar, under a name that is not a link. Did somebody else push them?"

None of the three is a bug. (1) A commit ID is the hash of the whole commit object, and that object contains the moment the commit was created. An amend, a rebase or a cherry-pick writes a new object with the same content and a different ID (sections 6.4 and 6.7; Lab 3.2). (2) A commit records two people and two times, and Git prints one date and filters by the other (section 6.5). (3) Git copies a name and an email address from her configuration into each commit and checks neither; GitHub links a commit to an account by that email address (sections 6.11 and 6.13).

Hold on to one idea through the chapter: a commit is a small text object that never changes after it is written. Every command that seems to change one (amend, rebase, cherry-pick, sign) writes another object and moves a ref.

## 6.2 What a commit is

**In one sentence.** A commit is an immutable object that names one complete snapshot of the project, the commit or commits it was built on, who wrote the change and when, who created the commit and when, and a message.

**Analogy.** An entry in a ledger whose page numbers are computed from what is written on the page. Each entry points at a full inventory sheet, cites the page number of the entry before it, and names who did the work and who entered it. Change one character and the page number changes. The analogy breaks at the binding: a ledger is one sequence, while an entry in Git may cite two earlier entries (a merge) or none (a root).

**Precisely.** The manual lists five required fields ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)):

| Field | Content | Count |
|---|---|---|
| `tree` | The tree object of the top-level directory: the full snapshot | one |
| `parent` | A commit this one was built on | none (root), one (ordinary), two or more (merge) |
| `author` | Name, email, time and time-zone offset of the person who wrote the change | one |
| `committer` | The same for the person who created this commit object | one |
| message | Free text after one empty line | one, possibly empty |

Optional headers can follow the committer line: `encoding`, written when `i18n.commitEncoding` declares a legacy encoding ([git-commit](https://git-scm.com/docs/git-commit)), and `gpgsig`, a signature (section 6.11). A commit holds no diff, no branch name and no file names. File names live in trees, and "Git does not store the diff for a commit": `git show` "calculates the diff from its parent on the fly" (gitdatamodel).

**Inside `.git`.** One object per commit in the object database ([Chapter 3](ch03-git-internals.md)). Nothing else describes a commit: there is no table of commits and no per-branch list. A branch reaches its commits by following `parent` IDs from its tip.

**See it.** A new repository, `evalkit`, and its first commit:

<!-- snippet: ch06/commit-anatomy/01-root-commit -->
```text
$ git init evalkit
Initialized empty Git repository in $LAB/ch06/commit-anatomy/evalkit/.git/
$ cd evalkit
$ git add README.md evalkit/metrics.py
$ git commit -m "Add exact-match metric"
[main (root-commit) 51d62b3] Add exact-match metric
 2 files changed, 5 insertions(+)
 create mode 100644 README.md
 create mode 100644 evalkit/metrics.py
```
<!-- /snippet -->

`(root-commit)` in the summary line says that this commit has no parent. Now read the object itself:

<!-- snippet: ch06/commit-anatomy/02-object -->
```text
$ git cat-file -t HEAD
commit
$ git cat-file -p HEAD
tree 0fbd18cca19ea00c195639456eecd36debe578ab
author Lab User <you@example.com> 1788755700 +0530
committer Lab User <you@example.com> 1788755700 +0530

Add exact-match metric
$ git cat-file -p 'HEAD^{tree}'
100644 blob 4793849f9215e303b89dd4fb1ab163499fb69815	README.md
040000 tree bd12437744ea02734adf3138606ecfb4509b509f	evalkit
```
<!-- /snippet -->

`git cat-file -p` prints the object as stored. The `tree` line names the snapshot, and `HEAD^{tree}` asks for that tree: a blob for `README.md` and a subtree for `evalkit`. There is no `parent` line. `author` and `committer` end with a time in seconds since 1 January 1970 UTC and an offset from UTC. One empty line separates headers and message.

**Picture.**

```text
  refs/heads/main
        |
        v
  commit 51d62b3                       tree 0fbd18c                   blob 4793849
 +--------------------------+         +---------------------+        +------------------+
 | tree      0fbd18c -------|-------> | blob  README.md ----|------> | # evalkit ...    |
 | (no parent)              |         | tree  evalkit ------|---+    +------------------+
 | author    Lab User, time |         +---------------------+   |
 | committer Lab User, time |                                   |     tree bd12437
 |                          |                                   |    +------------------+
 | Add exact-match metric   |                                   +--> | blob metrics.py  |
 +--------------------------+                                        +------------------+
```

**In production.** A commit ID in a deploy record or an evaluation report identifies the code exactly, and nothing outside the commit. A run started from a working tree with uncommitted edits executed code that no commit ID describes, and trackers may not notice: MLflow's classic run context records the commit and does not inspect uncommitted changes ([git context source](https://github.com/mlflow/mlflow/blob/master/mlflow/tracking/context/git_context.py)). Record `git rev-parse HEAD` together with `git status --porcelain`, or refuse a tracked run when that output is not empty ([Chapter 28](ch28-ai-ml-workflows.md)).

## 6.3 How `git commit` creates a commit

**In one sentence.** `git commit` 🟢 SAFE turns the index into tree objects, wraps the top tree in a new commit object whose parent is the current HEAD commit, and moves the current branch to that object.

**Precisely.** The steps, in the order in which their results depend on each other:

1. **Content.** The index, also called the staging area, is the proposed snapshot ([Chapter 5](ch05-index.md)).
2. **Checks and message.** The `pre-commit` hook runs before the message is obtained, and the `commit-msg` hook can reject the message ([githooks](https://git-scm.com/docs/githooks); [Chapter 14C](ch14c-stash-rerere-attributes-hooks.md)). `--no-verify` skips both.
3. **Trees.** Git builds one tree per directory from the index entries. A tree that the object database already holds keeps its ID, and nothing new is stored. `git write-tree` performs this step alone.
4. **Parent.** The commit that HEAD resolves to becomes the parent. A first commit has none; a merge in progress adds the commits in `MERGE_HEAD`.
5. **Commit object.** Tree ID, parent IDs, author, committer and message are written as one object. Its hash is the commit ID.
6. **Refs.** The ref that HEAD names is set to the new ID, and the reflogs of HEAD and of the branch each gain a line.

**See it.** Edit a file, stage it, and compare what the plumbing reports before the commit with the commit itself:

<!-- snippet: ch06/commit-anatomy/03-step-by-step -->
```text
# evalkit/metrics.py has been edited: it now also defines f1().
$ git add evalkit/metrics.py
$ git write-tree
27d56e4ea4080b5719bf97b9985f6f543eda349d
$ git rev-parse HEAD
51d62b3de231309f8aba10baba050cf2220fcc61
$ git commit -m "Add F1 metric"
[main 0d77920] Add F1 metric
 1 file changed, 9 insertions(+)
$ git cat-file -p HEAD
tree 27d56e4ea4080b5719bf97b9985f6f543eda349d
parent 51d62b3de231309f8aba10baba050cf2220fcc61
author Lab User <you@example.com> 1788756120 +0530
committer Lab User <you@example.com> 1788756120 +0530

Add F1 metric
```
<!-- /snippet -->

`git write-tree` printed `27d56e4`, and the new commit's `tree` line carries the same ID: the commit recorded the index. `git rev-parse HEAD` printed `51d62b3`, which is now the `parent` line.

<!-- snippet: ch06/commit-anatomy/04-what-moved -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ git rev-parse main
0d77920ea1ff22bc46fcaf5051fd6e5d86078a54
$ git reflog
0d77920 HEAD@{0}: commit: Add F1 metric
51d62b3 HEAD@{1}: commit (initial): Add exact-match metric
$ git reflog show main
0d77920 main@{0}: commit: Add F1 metric
51d62b3 main@{1}: commit (initial): Add exact-match metric
```
<!-- /snippet -->

`.git/HEAD` still holds the same text. The commit moved the branch, and HEAD follows only because it names the branch ([Chapter 7](ch07-branches.md) builds on this). Both reflogs gained an entry.

**Inside `.git`.** A second sandbox with a similar edit, this time comparing the object database before and after each command. `git cat-file --batch-all-objects --batch-check` prints ID, type and size of every object:

<!-- snippet: ch06/inside-git/01-add-writes-the-blob -->
```text
# evalkit/metrics.py has been edited: it now also defines f1().
$ objects() { git cat-file --batch-all-objects --batch-check | sort; }
$ objects > ../objects-before-add.txt
$ git add evalkit/metrics.py
$ objects | comm -13 ../objects-before-add.txt -
5ca6473ff5c0d818666928cda8551455b0794cd2 blob 154
```
<!-- /snippet -->

`git add` wrote the blob: the content is in the object database before any commit exists.

<!-- snippet: ch06/inside-git/02-commit-writes-trees-and-commit -->
```text
$ objects > ../objects-before-commit.txt
$ files() { find .git -type f -exec shasum {} + | sort; }
$ files > ../files-before-commit.txt
$ git commit -q -m "Add F1 metric"
$ objects | comm -13 ../objects-before-commit.txt -
1ed5d56b9ea6962262eb6c2e5634e45c7543b391 tree 38
29b018434273c541b9fce4dfc1e29fb92a358447 tree 71
529480e39c5092c92c130d091ce54617310747b7 commit 214
```
<!-- /snippet -->

The commit wrote three objects: a tree for `evalkit/`, a tree for the top level, and the commit. It wrote no blob, and the new top-level tree points at the `README.md` blob that the first commit already uses.

<!-- snippet: ch06/inside-git/03-files-touched -->
```text
# Every file under .git that is new, or whose content differs from the snapshot taken before the commit:
$ files | comm -13 ../files-before-commit.txt - | awk '{print $2}' | sort
.git/COMMIT_EDITMSG
.git/index
.git/logs/HEAD
.git/logs/refs/heads/main
.git/objects/1e/d5d56b9ea6962262eb6c2e5634e45c7543b391
.git/objects/29/b018434273c541b9fce4dfc1e29fb92a358447
.git/objects/52/9480e39c5092c92c130d091ce54617310747b7
.git/refs/heads/main
$ cat .git/COMMIT_EDITMSG
Add F1 metric
$ cat .git/HEAD
ref: refs/heads/main
```
<!-- /snippet -->

Eight files: three objects, the branch ref, two reflogs, the index (same entries, refreshed bookkeeping), and `COMMIT_EDITMSG` with the last message. `.git/HEAD` is not in the list.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git commit` | unchanged | entries unchanged; file rewritten | unchanged; resolves to the new commit | set to the new commit | new tree and commit objects; one line in `logs/HEAD` and in the branch reflog; `COMMIT_EDITMSG` | unchanged | unchanged |
| `git commit` in detached HEAD | unchanged | entries unchanged; file rewritten | set to the new commit ID | no current branch; no branch moves | new objects; one line in `logs/HEAD` only | unchanged | unchanged |

**In production.** Nothing in a commit says which branch it is on. It goes wherever HEAD pointed when you ran the command: onto `main` if HEAD named `main`, onto no branch if HEAD was detached in a CI checkout. Check `git status` before you commit, not after.

## 6.4 The commit ID

**In one sentence.** A commit ID is the hash of the commit object, so one ID names the snapshot, the metadata and, through the parent IDs, the whole history behind the commit.

**Precisely.** Git hashes the bytes `commit <size>`, one NUL byte, and the object content. With the default object format the hash is SHA-1 and the ID has 40 hexadecimal digits; a SHA-256 repository has 64 ([Chapter 3](ch03-git-internals.md)). Two properties follow.

- **Same bytes, same ID**, on any machine. The replays in this book pin the identity and the clock, which is the only reason your IDs can equal the printed ones.
- **Any change, new ID.** The `parent` line contains the parent's ID, so an ID depends on every ancestor. Nobody can alter an old commit without changing the ID of every commit after it.

**See it.** Compute an ID by hand, then let Git confirm it. `git hash-object -t commit --stdin` hashes the text the way `git commit` does:

<!-- snippet: ch06/commit-id/01-hash-by-hand -->
```text
$ git rev-parse HEAD
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
$ git cat-file -s HEAD
214
$ (printf 'commit %s\0' "$(git cat-file -s HEAD)"; git cat-file commit HEAD) | shasum
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29  -
$ git cat-file commit HEAD | git hash-object -t commit --stdin
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
```
<!-- /snippet -->

Rebuild the same commit from its parts. `git commit-tree` writes a commit object from a tree, a parent and a message; the dates come from the environment:

<!-- snippet: ch06/commit-id/02-same-inputs -->
```text
$ git cat-file -p HEAD
tree 29b018434273c541b9fce4dfc1e29fb92a358447
parent d4c9fabe9326ab4edbe04ed3a6f5f0b001bf6d86
author Lab User <you@example.com> 1788755640 +0530
committer Lab User <you@example.com> 1788755640 +0530

Add F1 metric
$ mk() { GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$2" git commit-tree -p "$3" -m "$4" "$5"; }
$ T='@1788755640 +0530'
$ mk "$T" "$T" HEAD~1 'Add F1 metric' 'HEAD^{tree}'
1f9c5d8d7bd2b007d3ee4ff4e5c023c01bb40a29
```
<!-- /snippet -->

Identical inputs gave `1f9c5d8` again. Now change one input at a time:

<!-- snippet: ch06/commit-id/03-one-field-changes -->
```text
# Each call changes exactly one input of the call above.
$ mk "$T" "$T" HEAD~1 'Add F1 metric.' 'HEAD^{tree}'                 # message: one more character
f22660f55b1a794df68ae4053dcaa8248a3d8636
$ mk '@1788755641 +0530' "$T" HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # author date: one second later
6ace11eacd33eda2b2c22c2f05b3a30a0f94ac63
$ mk "$T" '@1788755641 +0530' HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # committer date: one second later
8d3a6660cc08d014e4d3eb108aa22364504ecb86
$ mk '@1788755640 +0000' "$T" HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # author time zone: same instant, other offset
1a5c7c949d901b1455717b67cb1fad6b9e7e0c49
$ mk "$T" "$T" HEAD 'Add F1 metric' 'HEAD^{tree}'                    # parent: HEAD instead of HEAD~1
5be2270d868fdb4922293b1051405f2c660f5756
$ mk "$T" "$T" HEAD~1 'Add F1 metric' 'HEAD~1^{tree}'                # tree: the previous snapshot
097a2da44a07874ffc33633728cb207e29e89358
$ GIT_AUTHOR_EMAIL=You@example.com mk "$T" "$T" HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # author email: capital Y
b96c648475d2e36d3c55883a81e1473b2868e4fd
```
<!-- /snippet -->

Seven changes, seven new IDs. One second on the committer date is enough. The same instant with another offset is a different commit, because the offset is part of the text. So is a capital letter in an email address.

**Abbreviated IDs.** Any unique prefix of at least four characters names an object. Git prints abbreviations whose length it computes from the size of the repository (`core.abbrev`), seven characters in these sandboxes. A prefix that is unique today can become ambiguous later, so deploy records and model cards should store the full ID.

**In production.** This is the first CTO question.

```text
Observed behavior : the deployed commit is not the reviewed commit, yet git diff between the two is empty
Git state         : two commit objects with the same tree and the same parent; the branch points at the newer one
Mechanism         : an amend, a rebase or a cherry-pick wrote a new commit object with a new committer line
Root cause        : the commit ID is the hash of the commit object, and the committer time is part of that object
Why Git does this : an ID that covers every byte lets any two repositories agree on history by comparing IDs alone
Correct fix       : prove equal content with git rev-parse X^{tree} Y^{tree}; then move the branch back to X or re-approve Y
Prevention        : do not rewrite a commit after review or deployment; gate deploys on the approved ID, not on a branch name
```

## 6.5 Author and committer, two times, time zones

**In one sentence.** The author is the person who wrote the change and the committer is the person who created this commit object; each is recorded with a name, an email address, a time and a time-zone offset.

**Precisely.** For both identities Git reads the environment first (`GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_AUTHOR_DATE` and the three `GIT_COMMITTER_` variables), then `user.name` and `user.email`, and as a last resort guesses from the system user name and host name ([git-commit](https://git-scm.com/docs/git-commit), "Commit information"). `--author` and `--date` set the author fields of one commit. The committer has no such option: only the environment, the configuration and the clock.

| Operation | Author | Committer |
|---|---|---|
| `git commit` | you, now | you, now |
| `git commit --author=... --date=...` | as given | you, now |
| `git cherry-pick`, `git rebase`, `git commit --amend` | copied from the original commit | you, now |
| `git commit --amend --reset-author` | you, now | you, now |
| `git am` applying a mailed patch | name from the mail's `From:` line, date from its `Date:` line ([git-am](https://git-scm.com/docs/git-am)) | you, now |

**See it.** Asha wrote a commit on her branch. You cherry-pick it onto `main`:

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

The new commit `0cf479c` keeps Asha as author with her time, and records you as committer three minutes later. The author can also be set by hand, here for a file that Ravi mailed from another time zone:

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

The seconds identify the instant; the offset only says what the wall clock showed where the commit was made. By default Git prints each date with its recorded offset. `--date=iso-local` converts to your zone: Ravi's 09:30 at UTC-7 is 22:00 at UTC+5:30. `--date=unix` prints the stored seconds.

An amend keeps the author and renews the committer; `--reset-author` makes you the author as well:

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

Contribution counts depend on which identity is counted:

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

**Which date Git uses where.** A commit written on 24 August and cherry-picked on 7 September:

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

> **Root cause.** `git log` prints the author date, and `--since` and `--until` select by committer date. A listing of "everything since 1 September" therefore contains a commit that displays 24 August. Both are correct: the change was written in August and entered this history in September.

Git needs the committer date for its own work: "the history walking machinery assumes that commits have non-decreasing commit timestamps" (git-am). The author date is for people: it survives every rebase and cherry-pick.

**In production.** After a rebase, every commit of the branch has the rebase time as committer date and the original time as author date. A report built with `--since` counts all of them as new, while plain `git log` shows old dates. For release notes, select by a range between two tags, not by date. In an audit, print both dates with `--format=fuller`.

> **GitHub, not Git.** Commits that GitHub creates for you carry a GitHub address as committer email: a ruleset that restricts committer email "must also include `noreply@github.com` for web-based merges and other commits created on GitHub.com" ([available rules for rulesets](https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)). An author who differs from the committer is normal and no sign of tampering.

## 6.6 Parents: root commits, ordinary commits, merge commits

**In one sentence.** The `parent` lines of a commit are the only links in the history graph: none for a root commit, one for an ordinary commit, two or more for a merge commit.

**Precisely.** Parents are ordered. The first parent is the commit HEAD pointed at when the commit was made; for a merge, the further parents are the commits you merged in ([Chapter 8](ch08-merge.md), section 8.13). Two suffixes walk these links ([gitrevisions](https://git-scm.com/docs/gitrevisions)): `^<n>` selects the n-th parent of one commit, and `~<n>` follows first parents n times.

**See it.** `evalkit` with a feature branch written by Asha, before any merge:

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

`%p` prints the parents. The oldest commit has none, and `git rev-list --max-parents=0` finds it. A repository can have more than one root: `git switch --orphan` starts a history with no parent ([Chapter 7](ch07-branches.md)), and `git merge --allow-unrelated-histories` joins two of them.

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

A merge commit is an ordinary commit object with a second `parent` line. Its tree is a complete snapshot like any other. Porcelain shows the parents on the `Merge:` line.

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

**Picture.**

```text
  d4c9fab---bb904cd---191bbd1-------------ae6795c   main   (HEAD -> main)
                  \                       /
                   79ff6d7---59c914e-----+          feature/f1
```

| Expression | Reads as | Commit here |
|---|---|---|
| `HEAD^` or `HEAD^1` | first parent | `191bbd1` |
| `HEAD^2` | second parent | `59c914e` |
| `HEAD~2` | first parent of the first parent | `bb904cd` |
| `HEAD^2~1` | first parent of the second parent | `79ff6d7` |
| `HEAD^3` | third parent | none: exit status 1 |

`^` chooses among the parents of one commit, `~` goes back in a straight line. `HEAD~2` and `HEAD^^` are the same commit; `HEAD^2` is not.

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

A merge commit has one diff per parent. Against the first parent you see what the merge brought into `main`; against the second, what `main` had that the feature branch lacked. `--first-parent` lists what happened to `main` itself, one line per merge.

**In production.** A tool that needs "the previous state of this branch" must ask for `HEAD^1` or use `--first-parent`. Plain `git log` interleaves both sides of a merge by date, so the line below a merge can be the tip of the merged branch, which never was a state of `main`.

## 6.7 `git commit --amend`

**In one sentence.** `git commit --amend` 🟡 CAUTION writes a new commit that takes the place of the current one: same parent, new tree and message as you choose, new ID.

**Precisely.** The manual's description is "Replace the tip of the current branch by creating a new commit", and "The new commit has the same parents and author as the current one" ([git-commit](https://git-scm.com/docs/git-commit)). The old commit is neither modified nor deleted. The branch stops pointing at it, and only reflog entries still refer to it. [Chapter 11](ch11-reset-revert-restore.md), section 11.7, shows the equivalence with a soft reset plus a new commit.

**See it.** A commit with a typo in its message and a forgotten test file:

<!-- snippet: ch06/amend/01-mistake -->
```text
$ git add evalkit/metrics.py
$ git commit -m "Add F1 metrc"
[main 831f9ff] Add F1 metrc
 1 file changed, 4 insertions(+)
$ git status --short
?? tests/
$ git log --oneline
831f9ff Add F1 metrc
d4c9fab Add exact-match metric
```
<!-- /snippet -->

<!-- snippet: ch06/amend/02-amend -->
```text
$ git add tests/test_metrics.py
$ git commit --amend -m "Add F1 metric"
[main 8f6fa22] Add F1 metric
 Date: Mon Sep 7 10:05:00 2026 +0530
 2 files changed, 9 insertions(+)
 create mode 100644 tests/test_metrics.py
$ git log --oneline
8f6fa22 Add F1 metric
d4c9fab Add exact-match metric
```
<!-- /snippet -->

The log shows `8f6fa22` where `831f9ff` was. The `Date:` line in the summary is the author date, carried over by the amend. Both objects exist:

<!-- snippet: ch06/amend/03-two-objects -->
```text
$ git reflog
8f6fa22 HEAD@{0}: commit (amend): Add F1 metric
831f9ff HEAD@{1}: commit: Add F1 metrc
d4c9fab HEAD@{2}: commit (initial): Add exact-match metric
$ git cat-file -p 'HEAD@{1}'
tree 29b018434273c541b9fce4dfc1e29fb92a358447
parent d4c9fabe9326ab4edbe04ed3a6f5f0b001bf6d86
author Lab User <you@example.com> 1788755700 +0530
committer Lab User <you@example.com> 1788755700 +0530

Add F1 metrc
$ git cat-file -p HEAD
tree 304b1d11e74d6497529760e3c17e94c881773561
parent d4c9fabe9326ab4edbe04ed3a6f5f0b001bf6d86
author Lab User <you@example.com> 1788755700 +0530
committer Lab User <you@example.com> 1788755940 +0530

Add F1 metric
```
<!-- /snippet -->

Same `parent`, same `author` line; different `tree`, `committer` time and message. Two commits that share a parent.

<!-- snippet: ch06/amend/04-reachability -->
```text
$ git branch --contains 'HEAD@{1}'
$ git log --oneline --all
8f6fa22 Add F1 metric
d4c9fab Add exact-match metric
$ git fsck --no-reflogs
dangling commit 831f9ff6c0dc934d7528503ecc13565dfe506791
```
<!-- /snippet -->

No branch contains the old commit, and `git log --all` does not list it. `git fsck --no-reflogs` reports it as dangling: only the reflog still refers to it. Give it a name and it is an ordinary commit again:

<!-- snippet: ch06/amend/05-keep-it -->
```text
$ git branch before-amend 'HEAD@{1}'
$ git log --oneline --graph --all
* 8f6fa22 Add F1 metric
| * 831f9ff Add F1 metrc
|/  
* d4c9fab Add exact-match metric
```
<!-- /snippet -->

**Picture.**

```text
             831f9ff  "Add F1 metrc"     reachable only from HEAD@{1} and main@{1}
            /
  d4c9fab--+
            \
             8f6fa22  "Add F1 metric"    main   (HEAD -> main)
```

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git commit --amend` | unchanged | entries unchanged; they become the tree of the new commit | unchanged; resolves to the new commit | set to the new commit, whose parent is the old commit's parent | new commit object; old commit kept; reflog lines `commit (amend)` | unchanged; if the old commit was pushed, branch and upstream now diverge | unchanged |

**How long the old commit survives.** By default a reflog entry that is not reachable from the current tip expires after 30 days, and any other entry after 90. An object that no ref and no reflog entry refers to is pruned by maintenance once it is more than two weeks old ([git-gc](https://git-scm.com/docs/git-gc): `gc.reflogExpireUnreachable`, `gc.reflogExpire`, `gc.pruneExpire`). The lab configuration sets the two reflog values to `never`, so replays do not depend on the calendar. [Chapter 13](ch13-recovery.md) covers recovery in full.

**In production.** Amend freely while a commit exists only in your repository. `--no-edit` keeps the message, `--only` leaves staged changes out, and `--reset-author` repairs a wrong identity. Everything staged goes into an amend unless you say `--only`; Lab 3.1 breaks a commit that way. Once the commit has been pushed, an amend rewrites shared history (section 6.13).

## 6.8 Empty commits: `--allow-empty`

**In one sentence.** An empty commit has the same tree as its parent: a point in history with a message and no change.

**See it.**

<!-- snippet: ch06/empty-commit/01-allow-empty -->
```text
$ git commit -m "Re-run the nightly evaluation"
On branch main
nothing to commit, working tree clean
[exit status: 1]
$ git commit --allow-empty -m "Re-run the nightly evaluation"
[main 6642d40] Re-run the nightly evaluation
$ git rev-parse 'HEAD^{tree}' 'HEAD~1^{tree}'
0fbd18cca19ea00c195639456eecd36debe578ab
0fbd18cca19ea00c195639456eecd36debe578ab
$ git show --stat --format=fuller HEAD
commit 6642d40c372fdf1e58fbcc287284a33ad528da84
Author:     Lab User <you@example.com>
AuthorDate: Mon Sep 7 10:05:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:05:00 2026 +0530

    Re-run the nightly evaluation
```
<!-- /snippet -->

Without the option Git refuses with exit status 1. With it, the new commit and its parent have the same tree ID, and `--stat` has nothing to list.

**In production.** The manual says the option "is primarily for use by foreign SCM interface scripts". Teams use it to start a push-triggered pipeline without touching a file. Two cautions: a pipeline filtered by changed paths has no path to match, so an empty commit may not start it; and the commit stays in history, where a manual trigger in the CI system leaves no trace ([Chapter 20A](ch20a-actions-fundamentals.md)).

## 6.9 Trailers

**In one sentence.** A trailer is a `Key: value` line in the last paragraph of a commit message: ordinary text, placed where Git and other tools can find and parse it.

**See it.** `-s` adds a `Signed-off-by` trailer with the committer's identity, and `--trailer` adds any other:

<!-- snippet: ch06/trailers/01-write -->
```text
$ git add evalkit/judge.py
$ git commit -s -m 'Retry judge calls on HTTP 429' \
    -m 'The judge endpoint rate-limits bursts. Retry with exponential backoff, at most five attempts.' \
    --trailer 'Co-authored-by: Asha Rao <asha@example.com>' --trailer 'Refs: EVAL-212'
[main 7b588dd] Retry judge calls on HTTP 429
 1 file changed, 10 insertions(+)
 create mode 100644 evalkit/judge.py
$ git cat-file -p HEAD
tree a4e08def686cfbb567d5f427573310e3344a9056
parent 6eab4a90f8944518dce3aef708249b338e8f709a
author Lab User <you@example.com> 1788755700 +0530
committer Lab User <you@example.com> 1788755700 +0530

Retry judge calls on HTTP 429

The judge endpoint rate-limits bursts. Retry with exponential backoff, at most five attempts.

Signed-off-by: Lab User <you@example.com>
Co-authored-by: Asha Rao <asha@example.com>
Refs: EVAL-212
```
<!-- /snippet -->

The trailers are part of the message, so they are part of the commit object and of its ID. Three ways to read them back, one to count by them:

<!-- snippet: ch06/trailers/02-read -->
```text
$ git log -1 --format=%B | git interpret-trailers --parse
Signed-off-by: Lab User <you@example.com>
Co-authored-by: Asha Rao <asha@example.com>
Refs: EVAL-212
$ git log -1 --format='%(trailers:key=Refs,valueonly)'
EVAL-212

$ git log --oneline --grep='^Refs: EVAL-212'
7b588dd Retry judge calls on HTTP 429
$ git shortlog -sn --group=author --group=trailer:co-authored-by HEAD
     2	Lab User
     1	Asha Rao
```
<!-- /snippet -->

**Precisely.** Git recognises a trailer block only at the end of the message, after an empty line. Every line of the block must be a trailer, unless at least a quarter of the lines are and one of them has a key that Git generates itself (`Signed-off-by`, or the `(cherry picked from commit ...)` line) or a key defined in your configuration ([git-interpret-trailers](https://git-scm.com/docs/git-interpret-trailers); the two generated prefixes are listed in [trailer.c](https://github.com/git/git/blob/v2.55.0/trailer.c)). The five cases in order: recognised; no empty line before it; a sentence inside the block; the same with `Refs` configured as a key; text after the block.

<!-- snippet: ch06/trailers/03-rules -->
```text
# A trailer block is the last paragraph, and it must look like trailers.
$ printf 'Fix tokenizer\n\nRefs: EVAL-300\n' | git interpret-trailers --parse
Refs: EVAL-300
$ printf 'Fix tokenizer\nRefs: EVAL-300\n' | git interpret-trailers --parse
$ printf 'Fix tokenizer\n\nSee the design note.\nRefs: EVAL-300\n' | git interpret-trailers --parse
$ printf 'Fix tokenizer\n\nSee the design note.\nRefs: EVAL-300\n' | git -c trailer.ticket.key=Refs interpret-trailers --parse
Refs: EVAL-300
$ printf 'Fix tokenizer\n\nRefs: EVAL-300\n\nThanks to the platform team.\n' | git interpret-trailers --parse
```
<!-- /snippet -->

| Trailer | Who writes it | What it means |
|---|---|---|
| `Signed-off-by` | `git commit -s` | A statement defined by the project, commonly the [Developer Certificate of Origin](https://developercertificate.org). It is text, not a cryptographic signature |
| `Co-authored-by` | you, with `--trailer` | Credit for a further author. Git only stores the line |
| `Reviewed-by`, `Refs`, `Fixes` and others | you or your tooling | Whatever your team defines; the Git project documents its own set in [SubmittingPatches](https://github.com/git/git/blob/v2.56.0/Documentation/SubmittingPatches) |

> **GitHub, not Git.** GitHub reads these trailers: "Add one or more `Co-authored-by` trailers to a commit message to attribute a commit to multiple authors", with an email address associated with each co-author's account ([creating a commit with multiple authors](https://docs.github.com/en/pull-requests/how-tos/commit-changes/creating-a-commit-with-multiple-authors)).

**In production.** A ticket number or an evaluation-run ID in a trailer travels with the commit into every clone; a pull-request label does not. Lab 3.3 builds a report from trailers.

## 6.10 Messages and atomic commits

**How Git reads a message.** Two rules matter. First, the title is the text up to the first empty line, not the first line:

<!-- snippet: ch06/message/01-title -->
```text
$ cat msg.txt
Add whitespace tokenizer
F1 and ROUGE need the same token boundaries.
$ git commit -q -F msg.txt
$ git log --oneline -1
0095661 Add whitespace tokenizer F1 and ROUGE need the same token boundaries.
$ git log -1 --format='subject=[%s]%nbody=[%b]'
subject=[Add whitespace tokenizer F1 and ROUGE need the same token boundaries.]
body=[]
```
<!-- /snippet -->

Without the empty line, both lines became the title and the body is empty. Second, when a message passes through the editor, lines that begin with `#` are comments and are removed. `--edit` sends a message from a file through that path:

<!-- snippet: ch06/message/02-comment-lines -->
```text
$ cat msg.txt
Handle empty references in F1

#212 reported a ZeroDivisionError when the gold answer is empty.
Return 0.0 instead.
$ git commit -q -F msg.txt --edit
$ git log -1 --format=%B
Handle empty references in F1

Return 0.0 instead.

$ git commit -q --amend -F msg.txt
$ git log -1 --format=%B
Handle empty references in F1

#212 reported a ZeroDivisionError when the gold answer is empty.
Return 0.0 instead.
```
<!-- /snippet -->

The sentence about issue 212 disappeared the first time: the default `--cleanup` mode is `strip` when the message is edited and `whitespace` otherwise ([git-commit](https://git-scm.com/docs/git-commit)). Do not start a line with `#`.

**Craft, with the reasons.**

| Rule | Reason |
|---|---|
| A title of about 50 characters without a full stop | "that title is used throughout Git" (git-commit, "Discussion"): one-line logs, shortlog, branch listings, reflogs, mail subjects and patch file names |
| An empty line, then the body | Otherwise the body becomes part of the title, as shown above |
| Imperative mood: "Retry judge calls", not "Retried" | The Git project asks for it, "as if you are giving orders to the codebase" (SubmittingPatches), and Git's own titles (`Merge branch ...`, `Revert ...`) read the same way |
| The body states the problem and why this solution | "The goal of your log message is to convey the why behind your change" (SubmittingPatches). The diff shows what changed; nothing else records why |
| Lines of at most about 72 characters | Git does not re-wrap, and `git log` indents the message by four spaces |
| Machine-readable facts as trailers | They can be parsed (section 6.9) |

<!-- snippet: ch06/message-craft/01-message -->
```text
$ cat ../msg.txt
Retry judge calls on HTTP 429

Nightly evaluation runs failed about once a week with "judge rate
limit": the judge endpoint rejects bursts, and one rejected call
aborted the whole run after the generation step had already used
its GPU hours.

Retry up to five times with exponential backoff (1, 2, 4, 8, 16 s).
Other HTTP errors still fail at once, because retrying them would
hide real bugs.

Refs: EVAL-212
$ git commit -q -F ../msg.txt
$ git show -s --format=reference HEAD
6083abf (Retry judge calls on HTTP 429, 2026-09-07)
```
<!-- /snippet -->

`--format=reference` prints the form in which one message should cite another commit. The title appears wherever Git needs one line for a commit. Compare it with the title of the commit above it:

<!-- snippet: ch06/message-craft/02-where-the-title-is-used -->
```text
$ git log --oneline
24f43cf fix stuff
6083abf Retry judge calls on HTTP 429
6eab4a9 Add README
$ git shortlog HEAD
Asha Rao (1):
      fix stuff

Lab User (2):
      Add README
      Retry judge calls on HTTP 429

$ git branch -v
* main 24f43cf fix stuff
$ git reflog -2
24f43cf HEAD@{0}: commit: fix stuff
6083abf HEAD@{1}: commit: Retry judge calls on HTTP 429
```
<!-- /snippet -->

<!-- snippet: ch06/message-craft/03-format-patch -->
```text
$ git format-patch -1 --stdout HEAD~1 | head -n 6
From 6083abf1acecb06ad1ccb415b8036c7dfb1229db Mon Sep 17 00:00:00 2001
From: Lab User <you@example.com>
Date: Mon, 7 Sep 2026 10:06:00 +0530
Subject: [PATCH] Retry judge calls on HTTP 429

Nightly evaluation runs failed about once a week with "judge rate
$ git format-patch -1 -o ../outbox HEAD~1
../outbox/0001-Retry-judge-calls-on-HTTP-429.patch
```
<!-- /snippet -->

Team conventions such as [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) add a `type(scope): description` pattern to the title; they are agreements on top of Git, enforced by hooks or CI if at all.

**Atomic commits.** An atomic commit contains one logical change, complete enough that the project still builds and passes its tests. The Git project's rule is "Make separate commits for logically separate changes" (SubmittingPatches). Two unrelated edits in the working tree, committed separately:

<!-- snippet: ch06/atomic/01-two-commits -->
```text
$ git status --short
 M evalkit/metrics.py
 M requirements.txt
$ git add evalkit/metrics.py
$ git commit -q -m "Return 0.0 from F1 when no tokens overlap"
$ git add requirements.txt
$ git commit -q -m "Bump tokenizers to 0.21.0"
$ git log --oneline --stat -2
edc60de Bump tokenizers to 0.21.0
 requirements.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
4ea5f60 Return 0.0 from F1 when no tokens overlap
 evalkit/metrics.py | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch06/atomic/02-revert-one -->
```text
# The new tokenizers release breaks the nightly run. Undo that change only.
$ git revert --no-edit HEAD
[main fb38675] Revert "Bump tokenizers to 0.21.0"
 Date: Mon Sep 7 10:10:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ cat requirements.txt
tokenizers==0.20.3
pyyaml==6.0.2
$ grep -n "common == 0" evalkit/metrics.py
4:    if common == 0:
```
<!-- /snippet -->

The dependency bump was undone and the bug fix stayed, because they were two commits. The same separation lets you cherry-pick the fix to a release branch ([Chapter 10](ch10-cherry-pick.md)) and lets `git bisect` stop on a commit small enough to read ([Chapter 14A](ch14a-history-investigation.md)). `git add -p` builds such commits from a mixed working tree ([Chapter 5](ch05-index.md)).

## 6.11 Signatures and attribution

A signed commit carries its signature inside the commit object, in a `gpgsig` header. This demo creates a throwaway SSH key in the sandbox, so its output differs on every run:

<!-- snippet: ch06/signed-header/01-gpgsig -->
```text
$ git commit -q -S -m "Describe the project"
$ git cat-file -p HEAD
tree 5dca3a6e589a5d9b648e2563ac9c17bee742e961
parent 150744516440fbc2cc4197e81141ce63d5fa7cb2
author Lab User <you@example.com> 1788755880 +0530
committer Lab User <you@example.com> 1788755880 +0530
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgeAvXs1QLvASH7oyGmTC81lgOeA
 6h9gfo2suPhirxoDgAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQMMcYH0dg+LhdIIe0rd3ubk6j0JVijcMdpjwjHWVTTO8y+/dNh80pVbiWWOPlTtXcO
 T8VhfAj9d5XxVa0EFx6gU=
 -----END SSH SIGNATURE-----

Describe the project
```
<!-- /snippet -->

The header sits between the committer line and the message; continuation lines begin with a space ([gitformat-signature](https://git-scm.com/docs/gitformat-signature)). Because it is inside the object, it is covered by the commit ID, and signing a commit that already exists means writing a new commit. Do not confuse the two options: `-S` signs with a key, `-s` adds the `Signed-off-by` text. Keys, verification and trust are the subject of [Chapter 14B](ch14b-config-tags-signing.md).

> **GitHub, not Git.** "GitHub links a commit to a user by matching the email address in the commit header to an email address on a GitHub account" ([troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits)). Nothing in that match proves that the owner of the address made the commit. A "Verified" label is a separate statement about a signature. [Chapter 21B](ch21b-repository-security-incident-response.md) treats identity as a security topic.

## 6.12 Reading commits

| Command | Shows |
|---|---|
| `git cat-file -p <commit>` | The object as stored |
| `git show --format=raw --no-patch <commit>` | The same headers with the ID in front and the message indented |
| `git show --format=fuller <commit>` | Both identities and both dates, then the diff against the parent |
| `git show --stat <commit>` | A summary of changed paths in place of the diff |
| `git log` with `-<n>`, `--oneline`, `--graph`, `--stat`, `-p` | A walk backwards from HEAD or from the commits you name |
| `git log --author=<pattern>`, `--committer=<pattern>`, `--grep=<pattern>`, `--no-merges`, `-- <path>` | The same walk, filtered |

<!-- snippet: ch06/commit-anatomy/05-show-fuller -->
```text
$ git show --format=fuller --stat HEAD
commit 0d77920ea1ff22bc46fcaf5051fd6e5d86078a54
Author:     Lab User <you@example.com>
AuthorDate: Mon Sep 7 10:12:00 2026 +0530
Commit:     Lab User <you@example.com>
CommitDate: Mon Sep 7 10:12:00 2026 +0530

    Add F1 metric

 evalkit/metrics.py | 9 +++++++++
 1 file changed, 9 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch06/commit-anatomy/06-show-raw -->
```text
$ git show --format=raw --no-patch HEAD
commit 0d77920ea1ff22bc46fcaf5051fd6e5d86078a54
tree 27d56e4ea4080b5719bf97b9985f6f543eda349d
parent 51d62b3de231309f8aba10baba050cf2220fcc61
author Lab User <you@example.com> 1788756120 +0530
committer Lab User <you@example.com> 1788756120 +0530

    Add F1 metric
```
<!-- /snippet -->

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

Every diff here is computed when you ask. `git log -- README.md` lists the commits whose snapshot of that path differs from their parent's. [Chapter 14A](ch14a-history-investigation.md) turns these options into investigation techniques.

## 6.13 What can go wrong

**An amended commit that was already pushed.** The amend creates a sibling of the published commit:

<!-- snippet: ch06/amend-pushed/01-diverged -->
```text
$ git status -sb
## main...origin/main
$ git commit --amend -m "Exact match: strip whitespace"
[main 4f33829] Exact match: strip whitespace
 Date: Mon Sep 7 10:05:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git log --oneline --graph --all
* 4f33829 Exact match: strip whitespace
| * f8456dc Exact match: strp whitespace
|/  
* 4279e65 Add exact-match metric
```
<!-- /snippet -->

<!-- snippet: ch06/amend-pushed/02-push-rejected -->
```text
$ git push
To $LAB/ch06/amend-pushed/origin.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '$LAB/ch06/amend-pushed/origin.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

`[ahead 1, behind 1]` is the diagnosis: your branch has the new commit, the upstream has the old one. Do not follow the hint to pull, which would merge two versions of one commit. If others may have the published commit, return to it with `git reset --soft '@{u}'` and fix the mistake in a new commit. If the branch is yours alone, replace the published commit deliberately ([Chapter 12](ch12-remote-operations.md), section 12.8).

**A commit under the wrong identity.** A repository-local `user.email`, left from another project, overrides the global one:

<!-- snippet: ch06/identity/01-wrong-email -->
```text
$ git add evalkit/judge.py
$ git commit -q -m "Add judge client"
$ git log --format='%h  %an <%ae>  %s'
0d3dc20  Lab User <lab.user@personal.example>  Add judge client
6eab4a9  Lab User <you@example.com>  Add README
```
<!-- /snippet -->

<!-- snippet: ch06/identity/02-diagnose -->
```text
$ git var GIT_AUTHOR_IDENT
Lab User <lab.user@personal.example> 1788755880 +0530
$ git config get --show-scope --show-origin --all user.email
global	file:$LAB/ch06/identity/home/.gitconfig	you@example.com
local	file:.git/config	lab.user@personal.example
```
<!-- /snippet -->

`git var GIT_AUTHOR_IDENT` prints the identity the next commit would record, and `git config get --show-origin --all` names the file each value comes from (`get` needs Git 2.46 or later). Remove the wrong setting, then rewrite the unpublished commit:

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

When no email is configured, Git guesses one from the login name and the host name. `user.useConfigOnly` turns the guess into an error:

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

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| `git push` rejected after an amend | `git status -sb` shows `[ahead 1, behind 1]` | `git reset --soft '@{u}'` and a new commit; or a deliberate `--force-with-lease` on a private branch | Amend only unpublished commits |
| An amend swallowed unrelated staged changes | `git show --stat HEAD` lists files that do not belong | `git reset --soft 'HEAD@{1}'`, unstage, amend again (Lab 3.1) | `git status` before amending; `--only` for message fixes |
| The "old" commit is needed again | `git reflog` shows it one entry down | `git branch <name> 'HEAD@{1}'` | None needed |
| Commits carry the wrong name or email | `git log --format='%an <%ae>'`; `git config get --show-origin --all user.email` | Last commit: `--amend --reset-author`. Published commits: leave them | `user.useConfigOnly=true`; per-directory identity with `includeIf` (Chapter 14B) |
| The deployed ID is no longer on the branch | `git merge-base --is-ancestor <id> HEAD` exits with 1; `git diff --quiet <id> HEAD` exits with 0 | Move the branch back to the deployed commit (Lab 3.2) | Freeze commits after review |
| A line of the message is missing | The line began with `#` and the message went through the editor | Amend with `-F <file>`, or reword the line | Never start a line with `#` |
| `git log --oneline` shows a very long title | No empty line after the first line | Amend the message | Title, empty line, body |
| A trailer is not found by tooling | `git log -1 --format=%B \| git interpret-trailers --parse` prints nothing | Move the trailer to the last paragraph (Lab 3.3) | Add trailers with `--trailer`, not by hand |

## 6.14 When not to use it, and dangerous edge cases

- **Do not amend what others may have.** On a shared branch an amend produces the divergence of section 6.13 for every colleague.
- **An amend does not delete anything.** A secret committed and then amended away is still in the old commit, in your reflog, and on the server if it was pushed. Rotate the secret ([Chapter 21B](ch21b-repository-security-incident-response.md)).
- **`--no-verify` skips the `pre-commit` and `commit-msg` hooks**, and with them whatever your team relies on them to catch.
- **`git commit -a` commits every tracked change**, including edits you did not mean to publish.
- **Author and committer are assertions.** `--author`, the configuration and the environment accept any text. Only a verified signature is evidence of who created a commit.
- **Git does not validate the clock.** A machine with a wrong date writes that date into the commit, and Git's history walk relies on committer dates (section 6.5).
- **Empty commits are permanent.** Use `--allow-empty` for an event worth recording.

## 6.15 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git show`, `git log`, `git cat-file`, `git var`, `git interpret-trailers --parse` | 🟢 SAFE | Nothing | not needed | not needed |
| `git commit`, `git commit --allow-empty` | 🟢 SAFE | Adds objects, moves the current branch forward | `git diff --cached`, `git commit --dry-run` | A further commit, or [Chapter 11](ch11-reset-revert-restore.md) |
| `git commit -a` | 🟢 SAFE | The same, after staging every tracked change | `git diff HEAD` | as above |
| `git commit --no-verify` | 🟡 CAUTION | As `git commit`, without two hooks | Run the hook's checks by hand | Amend, or a further commit |
| `git commit --amend` (with or without `--no-edit`, `--only`, `--reset-author`) | 🟡 CAUTION | Replaces the tip commit with a new one | `git diff --cached`, `git log -1` | `git reset --soft 'HEAD@{1}'` |
| `git commit-tree` | 🟢 SAFE | Adds one commit object and moves no ref | not needed | not needed |
| `git interpret-trailers --in-place <file>` | 🟢 SAFE | Rewrites a message file, never a commit | Run it without `--in-place` | Edit the file |

No command in this chapter is 🔴. The dangerous moment is the push after a rewrite (Chapter 12).

## 6.16 Version notes

> **Version note.** Older behavior: trailers were typed by hand or added by a hook that called `git interpret-trailers`. Current behavior: `git commit --trailer <key>=<value>`. Since: Git 2.32 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.32.0.adoc)). Recommended: `--trailer`, and `-s` for the sign-off.

> **Version note.** Older behavior: `git shortlog` grouped by author or committer only. Current behavior: `--group=trailer:<key>` counts by trailer. Since: Git 2.29 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.29.0.adoc)). Recommended: use it for review and co-author statistics.

> **Version note.** Older behavior: up to Git 2.55 the trailer parser can take a line that begins with a URL for a trailer. Current behavior: Git 2.56 no longer does (not run here). Since: Git 2.56 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc)). Recommended: keep URLs out of the last paragraph, or put them in a trailer value.

> **Version note.** Older behavior: `git config --get user.email`. Current behavior: `git config get user.email`, as in section 6.13; the old form still works. Since: Git 2.46. Recommended: the subcommand form, which fails on older Git.

## 6.17 Practice

- **Labs 3.1, 3.2 and 3.3** in the [Module 3 lab manual](../lab-manual/m03-commits.md): amend a commit and find the old one; change only the committer date and watch the ID change; write and repair trailers.
- Replay any transcript with `labs/run ch06/<demo>` and continue by hand in the sandbox it leaves behind.
- Two drills. In `ch06/parents`, write two expressions for commit `79ff6d7` that start from `HEAD`. In `ch06/date-filters`, make `git log` print the committer date of each commit.

## 6.18 Interview questions

1. List every field of a commit object. Which of them can differ between two commits that have identical diffs?
2. A colleague says "I only fixed the commit message, the code is the same commit". What is wrong with that sentence, and how do you prove it?
3. Explain author and committer with three operations that make them differ. Which date does `git log` print, and which one does `--since` use?
4. What exactly does `git commit` write inside `.git`, and what does it leave untouched?
5. After `git commit --amend`, where is the old commit, how long does it stay, and how do you get it back?
6. `HEAD^2`, `HEAD~2`, `HEAD^^`: which commits are these on a merge commit, and which two are the same?
7. Our deploy tool stores abbreviated IDs. What can go wrong, and what should it store?
8. What is the difference between `git commit -s` and `git commit -S`? Where does each leave its mark in the object?
9. Why does GitHub show a teammate's commits without a profile link, and what does that tell you about who pushed them?
10. When does Git fail to recognise a trailer? How would you make ticket IDs queryable across a year of history?
11. A commit dated last month appears in "changes since Monday". Explain it without calling it a bug.

## 6.19 Sources

**Primary sources**

- [git-commit](https://git-scm.com/docs/git-commit), [git-show](https://git-scm.com/docs/git-show), [git-log](https://git-scm.com/docs/git-log), [git-cat-file](https://git-scm.com/docs/git-cat-file), [git-commit-tree](https://git-scm.com/docs/git-commit-tree), [git-interpret-trailers](https://git-scm.com/docs/git-interpret-trailers), [git-shortlog](https://git-scm.com/docs/git-shortlog), [git-var](https://git-scm.com/docs/git-var), [git-am](https://git-scm.com/docs/git-am), [git-gc](https://git-scm.com/docs/git-gc), [githooks](https://git-scm.com/docs/githooks). The local copies (`git help -m <command>`) are the Git 2.55.0 text that the transcripts were checked against.
- [gitdatamodel](https://git-scm.com/docs/gitdatamodel), [gitrevisions](https://git-scm.com/docs/gitrevisions), [gitformat-signature](https://git-scm.com/docs/gitformat-signature).
- The Git project's [SubmittingPatches](https://github.com/git/git/blob/v2.56.0/Documentation/SubmittingPatches): separate commits, the message, sign-off and trailers. [trailer.c at 2.55.0](https://github.com/git/git/blob/v2.55.0/trailer.c) for the trailers Git generates.
- Release notes [2.29](https://github.com/git/git/blob/master/Documentation/RelNotes/2.29.0.adoc), [2.32](https://github.com/git/git/blob/master/Documentation/RelNotes/2.32.0.adoc) and [2.56](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).
- GitHub Docs: [troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits), [creating a commit with multiple authors](https://docs.github.com/en/pull-requests/how-tos/commit-changes/creating-a-commit-with-multiple-authors), [setting your commit email address](https://docs.github.com/en/account-and-profile/how-tos/email-preferences/setting-your-commit-email-address), [about commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification).

**Secondary sources**

- Pro Git, [Git Internals: Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects) and the commit guidelines in [Contributing to a Project](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project). Caveat: both use `master`.
- Chris Beams, [How to Write a Git Commit Message](https://cbea.ms/git-commit/) (2014): the widely quoted seven rules.
- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/), a title convention whose footers follow the trailer format.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- [Lecture 5: Version Control and Git](https://www.youtube.com/watch?v=9K8lB61dl3Y), MIT Missing Semester 2026: snapshots, history as a graph, content-addressed objects. Caveats: describes object IDs as SHA-1 only; the demo starts on `master`.
- [RubyConf 2018 - Branch in Time](https://www.youtube.com/watch?v=8OOTVxKDwe0), Tekin Süleyman: why history quality matters, told as one story. Nothing in it depends on a Git version.
- [How to Undo Mistakes With Git Using the Command Line](https://www.youtube.com/watch?v=lX9hsdsAeTk), Tobias Günther for freeCodeCamp, 2020: includes amend. Caveat: `master` naming.

**Further reading**

- [Chapter 9](ch09-rebase.md), section 9.3, and [Chapter 10](ch10-cherry-pick.md), section 10.3: the "new object, new ID" rule applied to rebase and cherry-pick.
