# Chapter 7: Branches

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch07/`.

## 7.1 Why this matters

Three questions a CTO can ask after an ordinary week.

1. "A contractor says two days of work vanished after she 'checked out a tag to test something'. Is it gone?"
2. "Why does every laptop in the team fail with `cannot lock ref 'refs/heads/feature/login'` since this morning?"
3. "We have 340 branches on the server. Which ones can be deleted without losing anything?"

All three are questions about refs, and none has a Git command as its answer. The commits exist and are recoverable from the reflog (section 7.7, Lab 4.2). Somebody created a branch named `feature`, and a ref cannot be both a name and a directory of names (section 7.12, Lab 4.3). "Merged" has a precise meaning that `git branch --merged` tests, and a squash merge defeats it (section 7.13).

The polls in the Phase 0 report found that 58 percent of practising developers think of a branch as the commits that branched off, and 15 percent as a pointer ([jvns.ca](https://jvns.ca/blog/2024/03/28/git-poll-results/)). The second group is right in a way that decides outcomes. A branch is one line of text: a name and the ID of one commit. Everything in this chapter follows from that fact.

## 7.2 A branch is a ref

**In one sentence.** A branch is a ref, a name under `refs/heads/` that holds the ID of one commit, the tip; the branch's history is whatever that commit reaches through its parents.

**Analogy.** A bookmark in a book that is still being written. The bookmark marks one page; the chapters before that page are "the story so far", but they are the book's pages, not the bookmark's. Moving the bookmark changes nothing in the book, and two bookmarks can sit on the same page. The analogy breaks at the edge: pages after a bookmark exist too, unless nothing points at them, and then Git may eventually throw them away.

**Precisely.** The glossary: a branch head is "a named reference to the commit at the tip of a branch", stored "in a file in $GIT_DIR/refs/heads/ directory, except when using packed refs" ([gitglossary](https://git-scm.com/docs/gitglossary)). The ref holds nothing but the ID. There is no list of the branch's commits, no record of where it started, no owner, no creation date. `git log feature` is a walk that starts at the ID in the ref and follows `parent` lines ([Chapter 6](ch06-commits.md)).

**Inside `.git`.** With the files backend, which Git 2.55 uses by default, a loose branch is the file `.git/refs/heads/<name>` containing the ID and a newline. Packed refs move the same information into lines of `.git/packed-refs`. The reftable backend keeps refs in a binary store under `.git/reftable/` ([Chapter 3](ch03-git-internals.md)). The reflog of a branch lives in `.git/logs/refs/heads/<name>`.

**See it.** Create a branch with porcelain and read what was written:

<!-- snippet: ch07/branch-is-a-ref/01-porcelain -->
```text
$ git log --oneline
7aecf06 Add batch runner
69d8252 Add exact-match metric
6eab4a9 Add README
$ git branch feature/retry-backoff
$ git branch -v
  feature/retry-backoff 7aecf06 Add batch runner
* main                  7aecf06 Add batch runner
```
<!-- /snippet -->

<!-- snippet: ch07/branch-is-a-ref/02-what-was-written -->
```text
$ cat .git/refs/heads/feature/retry-backoff
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f
$ git rev-parse feature/retry-backoff
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f
$ git for-each-ref refs/heads
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f commit	refs/heads/feature/retry-backoff
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f commit	refs/heads/main
$ git reflog show feature/retry-backoff
7aecf06 feature/retry-backoff@{0}: branch: Created from main
```
<!-- /snippet -->

The file holds the full ID of `7aecf06`, and nothing else. `git for-each-ref` is the plumbing listing: for every ref, the ID, the type of object it names, and the full ref name. Both branches name the same commit. The branch also received a reflog whose first line records how it was created.

Plumbing creates branches too. `git update-ref` 🟡 CAUTION writes a ref, with two checks that porcelain also relies on:

<!-- snippet: ch07/branch-is-a-ref/03-plumbing -->
```text
$ git update-ref refs/heads/hotfix/judge-timeout HEAD~1
$ git branch -v
  feature/retry-backoff 7aecf06 Add batch runner
  hotfix/judge-timeout  69d8252 Add exact-match metric
* main                  7aecf06 Add batch runner
$ git update-ref refs/heads/typo 1234567890123456789012345678901234567890
fatal: update_ref failed for ref 'refs/heads/typo': trying to write ref 'refs/heads/typo' with nonexistent object 1234567890123456789012345678901234567890
[exit status: 128]
$ git update-ref refs/heads/not-a-commit 'HEAD^{tree}'
fatal: update_ref failed for ref 'refs/heads/not-a-commit': trying to write non-commit object 416a81e352e688b7791f11f2e8159ea3be84dd9c to branch 'refs/heads/not-a-commit'
[exit status: 128]
```
<!-- /snippet -->

The object must exist, and a ref under `refs/heads/` must name a commit. Writing the file by hand bypasses both checks and the reflog:

<!-- snippet: ch07/branch-is-a-ref/04-by-hand -->
```text
$ git rev-parse HEAD~2 > .git/refs/heads/by-hand
$ git branch -v
  by-hand               6eab4a9 Add README
  feature/retry-backoff 7aecf06 Add batch runner
  hotfix/judge-timeout  69d8252 Add exact-match metric
* main                  7aecf06 Add batch runner
$ git reflog show by-hand
$ git update-ref -d refs/heads/by-hand
$ git branch --list by-hand
```
<!-- /snippet -->

`git branch -v` reads the hand-written file like any other, but `git reflog show by-hand` is empty: no Git command wrote this ref, so nothing logged it. `git update-ref -d` deletes the ref. The last snippet is the reason to read refs with plumbing and never by path:

<!-- snippet: ch07/branch-is-a-ref/05-packed -->
```text
$ git pack-refs --all
$ cat .git/refs/heads/main
cat: .git/refs/heads/main: No such file or directory
[exit status: 1]
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f refs/heads/feature/retry-backoff
69d82526af97115a79ad14d198c1ba24c22d5fb9 refs/heads/hotfix/judge-timeout
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f refs/heads/main
$ git rev-parse main
7aecf069859aa045bb7e47a6b1fb0693f7c3da7f
```
<!-- /snippet -->

After `git pack-refs --all` the file is gone and the ref lives in `packed-refs`. `git rev-parse main` does not care. A script that reads `.git/refs/heads/main` breaks on the first packed repository, and on every reftable repository.

**Picture.**

```text
  .git/refs/heads/main                   -----> 7aecf06 "Add batch runner"
  .git/refs/heads/feature/retry-backoff  -----> 7aecf06            |
  .git/refs/heads/hotfix/judge-timeout   -----> 69d8252 "Add exact-match metric"
                                                                   |
                                                  6eab4a9 "Add README"
```

Three refs, three small files, one history. Creating the second and third branch wrote no commit, no tree and no blob.

**In production.** Because a branch is a name for a commit, "the branch" has a different value in every repository that holds a copy of it: your clone, each colleague's clone, the server. `main` on the server and `main` in your clone are two refs that happen to share a name ([Chapter 12](ch12-remote-operations.md)). A statement such as "the fix is on `main`" is only meaningful with a repository attached.

## 7.3 HEAD is a symbolic ref

**In one sentence.** HEAD is the ref that says where you are: normally a symbolic ref that names the current branch, and in detached state a direct reference to a commit.

**Precisely.** A symbolic ref is "a regular file that stores a string that begins with ref: refs/" ([git-symbolic-ref](https://git-scm.com/docs/git-symbolic-ref)). When HEAD contains `ref: refs/heads/main`, every command that needs "the current commit" resolves HEAD to `refs/heads/main` and then to the ID in that ref. HEAD is per worktree: a linked worktree has its own ([Chapter 25](ch25-worktrees.md)).

**See it.** Four ways to read it, from raw to friendly:

<!-- snippet: ch07/head-symref/01-read -->
```text
$ cat .git/HEAD
ref: refs/heads/main
$ git symbolic-ref HEAD
refs/heads/main
$ git symbolic-ref --short HEAD
main
$ git branch --show-current
main
$ git rev-parse --abbrev-ref HEAD
main
$ git rev-parse HEAD
69d82526af97115a79ad14d198c1ba24c22d5fb9
```
<!-- /snippet -->

A new repository shows that HEAD can name a branch that does not exist yet:

<!-- snippet: ch07/head-symref/02-unborn -->
```text
$ git init -q ../scratch
$ cat ../scratch/.git/HEAD
ref: refs/heads/main
$ git -C ../scratch rev-parse --verify HEAD
fatal: Needed a single revision
[exit status: 128]
$ git -C ../scratch branch
$ git -C ../scratch status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
$ git -C ../scratch branch feature
fatal: not a valid object name: 'main'
[exit status: 128]
```
<!-- /snippet -->

HEAD points at `refs/heads/main`, but no such ref exists until the first commit writes it. The glossary calls this an unborn branch. `git rev-parse --verify HEAD` fails, `git branch` lists nothing, and `git branch feature` fails because there is no commit to point the new branch at.

**Inside `.git`.** Moving HEAD alone shows what `git switch` adds on top of a ref change:

<!-- snippet: ch07/head-symref/03-head-only -->
```text
$ git symbolic-ref HEAD refs/heads/feature/retry-backoff
$ git status
On branch feature/retry-backoff
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	deleted:    evalkit/retry.py

$ git symbolic-ref HEAD refs/heads/main
$ git status --short
```
<!-- /snippet -->

`git symbolic-ref HEAD <ref>` 🟡 CAUTION rewrote one file. The index and the working tree still hold the content of `main`, so `git status` reports the difference between the commit HEAD now names and the index as a staged deletion. Switching back makes the report disappear. A branch switch is this ref change plus an update of the index and the working tree (section 7.6).

## 7.4 What a commit does to the current branch

**In one sentence.** A commit writes the new commit's ID into the ref that HEAD names, and nothing else moves.

**See it.** Two branches on the same commit, then one commit on the new branch:

<!-- snippet: ch07/commit-moves-branch/01-before -->
```text
$ git switch -c feature/retry-backoff
Switched to a new branch 'feature/retry-backoff'
$ cat .git/HEAD
ref: refs/heads/feature/retry-backoff
$ git for-each-ref --format='%(objectname:short) %(refname)' refs/heads
23b0907 refs/heads/feature/retry-backoff
23b0907 refs/heads/main
```
<!-- /snippet -->

<!-- snippet: ch07/commit-moves-branch/02-commit -->
```text
# evalkit/judge.py has been edited: call_judge() now retries on HTTP 429.
$ git commit -am "Retry judge calls on HTTP 429"
[feature/retry-backoff f5192c8] Retry judge calls on HTTP 429
 1 file changed, 10 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

<!-- snippet: ch07/commit-moves-branch/03-after -->
```text
$ cat .git/HEAD
ref: refs/heads/feature/retry-backoff
$ git for-each-ref --format='%(objectname:short) %(refname)' refs/heads
f5192c8 refs/heads/feature/retry-backoff
23b0907 refs/heads/main
$ git reflog show feature/retry-backoff
f5192c8 feature/retry-backoff@{0}: commit: Retry judge calls on HTTP 429
23b0907 feature/retry-backoff@{1}: branch: Created from HEAD
$ git reflog -2
f5192c8 HEAD@{0}: commit: Retry judge calls on HTTP 429
23b0907 HEAD@{1}: checkout: moving from main to feature/retry-backoff
$ git log --oneline --graph --all
* f5192c8 Retry judge calls on HTTP 429
* 23b0907 Add judge client
* 6eab4a9 Add README
```
<!-- /snippet -->

`.git/HEAD` is unchanged. `feature/retry-backoff` moved to `f5192c8`; `main` stayed on `23b0907`. The branch reflog gained a `commit:` line, and the HEAD reflog shows the switch and the commit. In the graph the two branches now name different commits, and `main` is an ancestor of the feature branch.

**Picture.**

```text
  before:                                   after:
                 feature/retry-backoff                        feature/retry-backoff
                 main   (HEAD -> ...)                                 |
                   |                                                  v
  6eab4a9---23b0907                         6eab4a9---23b0907---f5192c8
                                                         ^
                                                         main
```

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git commit` on `feature/retry-backoff` | unchanged | unchanged | unchanged: `ref: refs/heads/feature/retry-backoff` | moves to the new commit | `main` unchanged; new objects; one line in each of two reflogs | unchanged | unchanged |

**In production.** This is why "I committed to the wrong branch" is a ref problem and not a content problem. The commit object is correct; only the name that moved is wrong. Section 7.14 repairs it with two ref writes and no copying.

## 7.5 `git branch`: list, create, delete, rename, force

**In one sentence.** `git branch` lists refs under `refs/heads/`, creates one at a commit, deletes one, renames one, or moves one; it never touches the working tree.

**See it.** A clone with five local branches, three of which have been pushed. The remote is a bare repository on disk:

<!-- snippet: ch07/branch-commands/01-list -->
```text
$ git branch
  docs/metrics
  feature/f1
  fix/typo-readme
* main
  spike/judge-cache
$ git branch -v
  docs/metrics      a8a1b5f Document the metrics
  feature/f1        de7c39b [ahead 1] F1: handle empty reference
  fix/typo-readme   6a04691 Fix grammar in README
* main              55144fd [ahead 4] Merge branch 'docs/metrics'
  spike/judge-cache 44483e6 Spike: cache judge responses
$ git branch -vv
  docs/metrics      a8a1b5f Document the metrics
  feature/f1        de7c39b [origin/feature/f1: ahead 1] F1: handle empty reference
  fix/typo-readme   6a04691 [origin/fix/typo-readme] Fix grammar in README
* main              55144fd [origin/main: ahead 4] Merge branch 'docs/metrics'
  spike/judge-cache 44483e6 Spike: cache judge responses
```
<!-- /snippet -->

`-v` adds the tip and its title and, for branches with an upstream, how far they are ahead or behind it; `-vv` names the upstream. `spike/judge-cache` has none, so its line shows no relationship. Remote-tracking branches have their own listing:

<!-- snippet: ch07/branch-commands/02-remotes -->
```text
$ git branch -r
  origin/feature/f1
  origin/fix/typo-readme
  origin/main
$ git branch -a
  docs/metrics
  feature/f1
  fix/typo-readme
* main
  spike/judge-cache
  remotes/origin/feature/f1
  remotes/origin/fix/typo-readme
  remotes/origin/main
```
<!-- /snippet -->

`-r` lists `refs/remotes/`, `-a` both namespaces. The `remotes/` prefix in `-a` output marks the second kind; section 7.10 explains what they are.

**Merged, not merged, contains.** `--merged` lists "branches whose tips are reachable from" the named commit, HEAD by default, and `--no-merged` the others ([git-branch](https://git-scm.com/docs/git-branch)). `--contains <commit>` turns the question around: which branches reach this commit?

<!-- snippet: ch07/branch-commands/03-merged -->
```text
$ git log --oneline --graph --all
*   55144fd Merge branch 'docs/metrics'
|\  
| * a8a1b5f Document the metrics
|/  
* de7c39b F1: handle empty reference
* 35581b1 Add F1 metric
| * 44483e6 Spike: cache judge responses
|/  
| * 6a04691 Fix grammar in README
|/  
* d1e8f22 Add exact-match metric
* faf3622 Add README
$ git branch --merged
  docs/metrics
  feature/f1
* main
$ git branch --no-merged
  fix/typo-readme
  spike/judge-cache
$ git branch --contains origin/feature/f1
  docs/metrics
  feature/f1
* main
```
<!-- /snippet -->

`docs/metrics` and `feature/f1` are merged: `main` reaches their tips, one through a merge commit and one by fast-forward. `fix/typo-readme` and `spike/judge-cache` have commits that `main` does not reach.

**Delete.** `-d` 🟡 CAUTION refuses a branch that is not fully merged; `-D` 🔴 DANGEROUS deletes regardless, and both delete the branch's reflog with it:

<!-- snippet: ch07/branch-commands/04-delete -->
```text
$ git branch -d docs/metrics
Deleted branch docs/metrics (was a8a1b5f).
$ git branch -d spike/judge-cache
error: the branch 'spike/judge-cache' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D spike/judge-cache'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git branch -D spike/judge-cache
Deleted branch spike/judge-cache (was 44483e6).
$ git reflog show spike/judge-cache
fatal: ambiguous argument 'spike/judge-cache': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
$ git branch spike/judge-cache 44483e6
$ git reflog show spike/judge-cache
44483e6 spike/judge-cache@{0}: branch: Created from 44483e6
```
<!-- /snippet -->

After `-D` the branch's own reflog is gone, so `git reflog show` has nothing to resolve. The commit itself still exists, and the `was 44483e6` in the deletion message is the ID you need to recreate the branch. If that message has scrolled away, the HEAD reflog still lists the commit if it was ever checked out (Lab 4.2). What `-D` can destroy is the branch reflog and the only name of commits that were never checked out; preview with `git log --oneline main..<branch>` (section 7.8), and recover with `git branch <name> <id>`. It is appropriate for a branch whose commits you have decided to abandon or that you know to be squash-merged (section 7.13).

The rule behind `-d` is about the upstream, not about `main`: "The branch must be fully merged in its upstream branch, or in HEAD if no upstream was set" (git-branch).

<!-- snippet: ch07/branch-commands/05-upstream-rule -->
```text
$ git branch -d fix/typo-readme
warning: deleting branch 'fix/typo-readme' that has been merged to
         'refs/remotes/origin/fix/typo-readme', but not yet merged to HEAD
Deleted branch fix/typo-readme (was 6a04691).
$ git branch -d feature/f1
warning: not deleting branch 'feature/f1' that is not yet merged to
         'refs/remotes/origin/feature/f1', even though it is merged to HEAD
error: the branch 'feature/f1' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/f1'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
```
<!-- /snippet -->

`fix/typo-readme` is not merged into HEAD, but it is pushed and equal to its upstream, so `-d` deletes it with a warning. `feature/f1` is merged into HEAD, but it has one commit that its upstream lacks, so `-d` refuses. Read both messages before reaching for `-D`.

**Rename and force.**

<!-- snippet: ch07/branch-commands/06-rename -->
```text
$ git branch -m feature/f1 feature/f1-metric
$ git branch -vv
  feature/f1-metric de7c39b [origin/feature/f1: ahead 1] F1: handle empty reference
* main              55144fd [origin/main: ahead 4] Merge branch 'docs/metrics'
  spike/judge-cache 44483e6 Spike: cache judge responses
$ git config get branch.feature/f1-metric.merge
refs/heads/feature/f1
$ git reflog show feature/f1-metric
de7c39b feature/f1-metric@{0}: Branch: renamed refs/heads/feature/f1 to refs/heads/feature/f1-metric
de7c39b feature/f1-metric@{1}: commit: F1: handle empty reference
35581b1 feature/f1-metric@{2}: commit: Add F1 metric
d1e8f22 feature/f1-metric@{3}: branch: Created from HEAD
```
<!-- /snippet -->

`-m` 🟡 CAUTION renames the ref, its reflog and its configuration section in one step, and logs the rename. The upstream still points at `origin/feature/f1`, because renaming a local branch changes nothing on the remote ([Chapter 12](ch12-remote-operations.md)).

<!-- snippet: ch07/branch-commands/07-force -->
```text
$ git branch release/0.2 main
$ git branch release/0.2 main~1
fatal: a branch named 'release/0.2' already exists
[exit status: 128]
$ git branch -f release/0.2 main~1
$ git reflog show release/0.2
de7c39b release/0.2@{0}: branch: Reset to main~1
55144fd release/0.2@{1}: branch: Created from main
$ git branch -f main main~1
fatal: cannot force update the branch 'main' used by worktree at '$LAB/ch07/branch-commands/evalkit'
[exit status: 128]
```
<!-- /snippet -->

Without `-f`, `git branch` refuses to change an existing branch. With it, 🟡 CAUTION, the ref moves and the reflog records `Reset to main~1`, so the old position is one entry away. A branch that is checked out in a worktree cannot be force-moved at all; `git reset` is the command for that ([Chapter 11](ch11-reset-revert-restore.md)).

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git branch <name> [<start>]` | unchanged | unchanged | unchanged | unchanged | new ref and reflog; with a remote-tracking start point, `branch.<name>.*` configuration | unchanged | unchanged |
| `git branch -d` or `-D <name>` | unchanged | unchanged | unchanged | unchanged | ref and its reflog deleted; `branch.<name>.*` configuration removed | unchanged | unchanged |
| `git branch -m <old> <new>` | unchanged | unchanged | follows the rename if `<old>` was current | renamed | ref, reflog and configuration renamed; a reflog line records it | unchanged | unchanged |
| `git branch -f <name> <commit>` | unchanged | unchanged | unchanged | not allowed | ref set to the commit; reflog line `branch: Reset to ...` | unchanged | unchanged |

## 7.6 `git switch`, and `git checkout`

**In one sentence.** `git switch` 🟢 SAFE changes which branch HEAD names and updates the index and the working tree to that branch's commit, refusing when a local change would be lost.

**Precisely.** `git switch <branch>` points HEAD at the branch, then makes the index and working tree match its tip. `-c <new>` creates the branch first and is "the transactional equivalent" of `git branch` followed by `git switch` ([git-switch](https://git-scm.com/docs/git-switch)); `-C` resets an existing branch like `git branch -f`. `--detach` points HEAD at a commit instead of a branch (section 7.7). `-` means `@{-1}`, the previously checked-out branch or commit. `--orphan <new>` creates an unborn branch and removes all tracked files from the working tree, so the next commit starts a disconnected history.

**See it.**

<!-- snippet: ch07/switch-commands/01-create -->
```text
$ git switch -c feature/retry
Switched to a new branch 'feature/retry'
$ git switch -c feature/retry
fatal: a branch named 'feature/retry' already exists
[exit status: 128]
$ git switch main
Switched to branch 'main'
$ git switch -C feature/retry main~1
Switched to and reset branch 'feature/retry'
$ git reflog show feature/retry
b01a3f1 feature/retry@{0}: branch: Reset to main~1
2daf400 feature/retry@{1}: branch: Created from HEAD
```
<!-- /snippet -->

<!-- snippet: ch07/switch-commands/02-previous -->
```text
$ git switch main
Switched to branch 'main'
$ git switch -
Switched to branch 'feature/retry'
$ git switch -
Switched to branch 'main'
$ git rev-parse --abbrev-ref '@{-1}'
feature/retry
```
<!-- /snippet -->

<!-- snippet: ch07/switch-commands/03-detach -->
```text
$ git switch v0.1.0
fatal: a branch is expected, got tag 'v0.1.0'
hint: If you want to detach HEAD at the commit, try again with the --detach option.
[exit status: 128]
$ git switch --detach v0.1.0
HEAD is now at b01a3f1 Add exact-match metric
$ git switch -
Previous HEAD position was b01a3f1 Add exact-match metric
Switched to branch 'main'
```
<!-- /snippet -->

`git switch` wants a branch and refuses a tag, with a hint. `--detach` is the explicit way to stand on a commit that is not a branch tip. `git checkout` does the same jobs with older spellings. Learn them to read other people's scripts; write `switch` and `restore` yourself:

<!-- snippet: ch07/switch-commands/04-checkout-equivalents -->
```text
$ git checkout -b feature/cache
Switched to a new branch 'feature/cache'
$ git checkout main
Switched to branch 'main'
$ git checkout -B feature/cache main~1
Switched to and reset branch 'feature/cache'
$ git checkout -
Switched to branch 'main'
$ git checkout --detach
HEAD is now at 2daf400 Add batch runner
$ git checkout main
Switched to branch 'main'
```
<!-- /snippet -->

| Task | `git switch` | `git checkout` |
|---|---|---|
| Switch to a branch | `git switch <branch>` | `git checkout <branch>` |
| Create and switch | `git switch -c <new> [<start>]` | `git checkout -b <new> [<start>]` |
| Reset and switch | `git switch -C <new> [<start>]` | `git checkout -B <new> [<start>]` |
| Previous branch | `git switch -` | `git checkout -` |
| Detach at a commit | `git switch --detach <commit>` | `git checkout --detach <commit>`, or `git checkout <commit>` |
| Unborn branch | `git switch --orphan <new>` | `git checkout --orphan <new>` |
| Restore a file | not this command: `git restore` | `git checkout -- <path>` |

`git checkout <name>` guesses whether you mean a branch or a path, which is the ambiguity the two newer commands remove. One difference shows in the next transcript: `switch --orphan` empties the working tree, while `checkout --orphan` keeps the files and stages them.

<!-- snippet: ch07/switch-commands/05-orphan -->
```text
$ git switch --orphan gh-pages
Switched to a new branch 'gh-pages'
$ cat .git/HEAD
ref: refs/heads/gh-pages
$ git status --short
$ ls -A
.git
$ git switch main
Switched to branch 'main'
$ git branch --list gh-pages
$ git checkout --orphan docs-site
Switched to a new branch 'docs-site'
$ git status --short
A  README.md
A  configs/eval.yaml
A  evalkit/metrics.py
A  evalkit/runner.py
$ git switch main
Switched to branch 'main'
```
<!-- /snippet -->

After `git switch --orphan gh-pages`, HEAD names a branch that has no commit, and `git branch --list gh-pages` prints nothing after switching away: an unborn branch disappears when you leave it, because no ref was ever written.

**Local changes.** Switching does not require a clean working tree. A change in a file that is identical on both branches is carried along; a change in a file that differs is refused:

<!-- snippet: ch07/switch-commands/06-local-changes -->
```text
$ printf '\nRun the tests with: python -m pytest\n' >> README.md
$ git switch feature/threshold
Switched to branch 'feature/threshold'
M	README.md
$ git switch main
Switched to branch 'main'
M	README.md
$ printf 'judge_model: judge-v2\nthreshold: 0.5\n' > configs/eval.yaml
$ git switch feature/threshold
error: Your local changes to the following files would be overwritten by checkout:
	configs/eval.yaml
Please commit your changes or stash them before you switch branches.
Aborting
[exit status: 1]
$ git status --short
 M README.md
 M configs/eval.yaml
```
<!-- /snippet -->

The edited `README.md` travelled to `feature/threshold` and back, marked `M`. The edit to `configs/eval.yaml` could not, because the two branches have different versions of that file, and the switch would have had to overwrite the edit. Commit, stash ([Chapter 11](ch11-reset-revert-restore.md)) or use `--merge`, which stashes and reapplies for you.

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git switch <branch>` | files that differ between the two tips are replaced; local edits to other files stay | updated to the target tip | `ref: refs/heads/<branch>` | unchanged | reflog line `checkout: moving from A to B` in `logs/HEAD` | unchanged | unchanged |
| `git switch -c <new> [<start>]` | as above, relative to `<start>` | as above | `ref: refs/heads/<new>` | unchanged | new ref and reflog | unchanged | unchanged |
| `git switch --detach <commit>` | as above | as above | the commit ID | no current branch | reflog line in `logs/HEAD` | unchanged | unchanged |
| `git switch --orphan <new>` | tracked files removed | emptied | `ref: refs/heads/<new>` | unborn: no ref yet | nothing until the first commit | unchanged | unchanged |

## 7.7 Detached HEAD

**In one sentence.** HEAD is detached when it holds a commit ID instead of a branch name; Git works normally, and new commits advance HEAD itself rather than any branch.

**Analogy.** Reading a book with no bookmark in it. You can read any page and even write notes on new pages, but when you put the book down nothing marks where your notes are. The analogy breaks because Git keeps a diary of where you have been, the reflog, and the notes can be found again through it.

**Precisely.** The manual: in detached HEAD state "HEAD refers to a specific commit, as opposed to referring to a named branch", and a commit made there "is referenced only by HEAD" ([git-checkout](https://git-scm.com/docs/git-checkout), "Detached HEAD"). It is not an error. Git detaches HEAD whenever you ask for a commit that no branch names, and several commands do it for you.

**See it.** Check out a tag and inspect the state:

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

The advice block is Git's own explanation, printed once per detach unless `advice.detachedHead` is false. `.git/HEAD` holds a raw ID; `git status` says `HEAD detached at v0.1.0`; `git branch` lists a pseudo-entry instead of a current branch.

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

Each of the three commands that answer "which branch am I on" answers differently: `git symbolic-ref HEAD` fails with status 128, `git branch --show-current` prints nothing, and `git rev-parse --abbrev-ref HEAD` prints the literal `HEAD`. Scripts must handle all three.

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

Two commits later, the status line says `HEAD detached from v0.1.0`: "at" became "from" because HEAD has moved since it was detached. `git log --all` shows the new commits because `--all` includes HEAD. Now leave:

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

Git warns, names the commits, and prints the command that keeps them. `git log --all` no longer shows them: no ref reaches them. Section 6.7 of Chapter 6 told the rest of the story: the commits still exist, and the reflog of HEAD still refers to them.

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

**Inside `.git`.** Where `git status` gets its words. It reads the HEAD reflog backwards for the latest `checkout: moving from ... to <X>` entry; `X` is printed after "at" if HEAD still equals that entry's commit, after "from" otherwise. With no such entry, as in a fresh clone, it prints `Not currently on any branch.` ([wt-status.c at 2.55.0](https://github.com/git/git/blob/v2.55.0/wt-status.c)).

**Every way it happens.**

| Cause | What you typed or ran | Seen in |
|---|---|---|
| Checking out a tag | `git checkout v0.1.0`, `git switch --detach v0.1.0` | above |
| Checking out a commit by ID or relative name | `git checkout <id>`, `git switch --detach HEAD~1` | below |
| Checking out a remote-tracking branch | `git checkout origin/main`, `git switch --detach origin/main` | below |
| `git bisect` | every step checks out a commit to test | below |
| `git rebase` while it runs or is stopped | the rebase replays commits on a detached HEAD ([Chapter 9](ch09-rebase.md)) | below |
| `git clone --branch <tag>` | a clone of one release, the shape of many deploy scripts | below |
| `git worktree add <path> <tag-or-commit>` | a linked worktree not on a branch ([Chapter 25](ch25-worktrees.md)) | below |
| `git submodule update` | the default `checkout` mode puts each submodule on a detached HEAD ([git-submodule](https://git-scm.com/docs/git-submodule); [Chapter 23](ch23-submodules.md)) | not run here |
| A CI checkout | on `pull_request` events the default checkout is a merge commit in detached HEAD ([events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows); [Chapter 20A](ch20a-actions-fundamentals.md)) | GitHub Actions, not run here |

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

During a stopped rebase, `git branch` prints `(no branch, rebasing main)` and `.git/HEAD` holds an ID; the rebase moves `main` only at the end. This is why an interrupted rebase looks like a detached HEAD: it is one.

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

A clone made with `--branch v0.1.0` has no local branch at all: `git branch -a` shows `(no branch)` and the remote-tracking refs. A deploy script that commits a generated file in such a clone commits onto nothing.

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

**Picture.**

```text
  attached                                  detached, two commits later

  HEAD -> refs/heads/main -> d27ae01          HEAD -> b23bce3 "Experiment: threshold 0.9"
                                                        |
  0381ff6---8c6d240---d27ae01   main          0381ff6---8c6d240---d27ae01   main
            tag v0.1.0                                  \
                                                         f678c98---b23bce3
```

**Keeping the work.** Three commands create a ref for the commit HEAD is on, as the manual lists them: `git switch -c <name>` attaches HEAD to a new branch there, `git branch <name>` creates the branch and leaves HEAD detached, and `git tag <name>` creates a tag. After you have moved away, find the ID in `git reflog` first (Lab 4.2).

**In production.** Detached HEAD is the normal state of a CI job, a deploy checkout and a submodule, so a script that assumes a current branch (`git branch --show-current`, `git push` with no refspec) fails in exactly those places. Use `git rev-parse HEAD` for the commit and name the branch explicitly when pushing. For people, the rule is one sentence: before you leave a detached HEAD with commits on it, give them a branch.

## 7.8 Divergence and ancestry

**In one sentence.** Two branches have diverged when neither tip is an ancestor of the other; their merge base is the best common ancestor, and "ahead" and "behind" are counted from it.

**Precisely.** A common ancestor is a commit reachable from both tips. "One common ancestor is better than another common ancestor if the latter is an ancestor of the former", and a best one is a merge base ([git-merge-base](https://git-scm.com/docs/git-merge-base)); there can be more than one ([Chapter 8](ch08-merge.md), section 8.5). Ranges are sets of commits ([gitrevisions](https://git-scm.com/docs/gitrevisions)): `A..B` is everything reachable from B but not from A, and `A...B` is the symmetric difference, reachable from one side but not both. `git merge-base --is-ancestor A B` exits with 0 when A is an ancestor of B and with 1 when it is not.

**See it.** `main` and `feature/rouge` after both received commits:

<!-- snippet: ch07/divergence/01-graph -->
```text
$ git log --oneline --graph --all
* e12f113 Add CI workflow
* 9500b9e Exact match: strip whitespace
| * eaab34d ROUGE-L: add tests
| * 5351fa7 ROUGE-L: tokenize on whitespace
| * 22c856c Add ROUGE-L metric
|/  
* 03f74b9 Add exact-match metric
* 6eab4a9 Add README
```
<!-- /snippet -->

<!-- snippet: ch07/divergence/02-merge-base -->
```text
$ git merge-base main feature/rouge
03f74b9ac8547c31330105153beb4b90c5ddeea8
$ git log --oneline main..feature/rouge
eaab34d ROUGE-L: add tests
5351fa7 ROUGE-L: tokenize on whitespace
22c856c Add ROUGE-L metric
$ git log --oneline feature/rouge..main
e12f113 Add CI workflow
9500b9e Exact match: strip whitespace
```
<!-- /snippet -->

The merge base is `03f74b9`. `main..feature/rouge` is what the feature has that `main` lacks (three commits); `feature/rouge..main` is the reverse (two).

<!-- snippet: ch07/divergence/03-count -->
```text
$ git rev-list --left-right --count main...feature/rouge
2	3
$ git log --oneline --left-right main...feature/rouge
< e12f113 Add CI workflow
< 9500b9e Exact match: strip whitespace
> eaab34d ROUGE-L: add tests
> 5351fa7 ROUGE-L: tokenize on whitespace
> 22c856c Add ROUGE-L metric
$ git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads
feature/rouge 3 2
main 0 0
```
<!-- /snippet -->

`--left-right --count` prints the two numbers in the order of the operands: two commits only on the left side, three only on the right. The `%(ahead-behind:main)` field of `git for-each-ref` computes the same pair for every branch at once, from the branch's point of view: `feature/rouge` is 3 ahead of `main` and 2 behind.

<!-- snippet: ch07/divergence/04-ancestor -->
```text
$ git merge-base --is-ancestor main feature/rouge
[exit status: 1]
$ git merge-base --is-ancestor main~2 feature/rouge
[exit status: 0]
$ git merge-base --is-ancestor main~2 main
[exit status: 0]
```
<!-- /snippet -->

`main` is not an ancestor of the feature branch, so merging the feature into `main` cannot be a fast-forward ([Chapter 8](ch08-merge.md), section 8.3). `main~2`, the merge base, is an ancestor of both.

<!-- snippet: ch07/divergence/05-diff-dots -->
```text
$ git diff --stat main...feature/rouge
 evalkit/rouge.py | 6 ++++++
 test_rouge.py    | 2 ++
 2 files changed, 8 insertions(+)
$ git diff --stat main..feature/rouge
 ci.yaml            | 1 -
 evalkit/metrics.py | 2 +-
 evalkit/rouge.py   | 6 ++++++
 test_rouge.py      | 2 ++
 4 files changed, 9 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

| Notation | In `git log` and `git rev-list` | In `git diff` |
|---|---|---|
| `A..B` | commits reachable from B and not from A | the two tips compared directly; the same as `git diff A B` |
| `A...B` | commits reachable from exactly one side | from the merge base of A and B to B: what B changed |

The two meanings are a known trap ([Phase 0 report, section 12](../reports/Git%20and%20GitHub%20mastery%20research.md)). In the transcript, `git diff --stat main...feature/rouge` lists the feature's own work, while `main..feature/rouge` also shows `main`'s two commits reversed.

**Picture.**

```text
                       9500b9e---e12f113   main          <  left: 2 commits
                      /
  6eab4a9---03f74b9--+                 merge base: 03f74b9
                      \
                       22c856c---5351fa7---eaab34d   feature/rouge   > right: 3 commits
```

**In production.** `[ahead 2, behind 3]` in `git status`, the counts on a pull request, "can this be fast-forwarded", and "which commits does this release contain" are all this arithmetic. Compute them with ranges, not with dates (Chapter 6, section 6.5), and state the base: "3 commits ahead" is meaningless until you say ahead of what.

> **GitHub, not Git.** GitHub computes a pull request's changes from a merge base too: "Compare pages and pull request pages can calculate changed files from different merge bases", because "Pull request pages focus on what the pull request introduced, while compare pages reflect the current comparison between two refs" ([pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests); [Chapter 17](ch17-pull-requests.md)).

## 7.9 Git has no parent-branch concept

**In one sentence.** Nothing in a repository records which branch a branch was created from; the only trace is a line in a local reflog, and every comparison needs a base that you name.

**See it.** Create a branch from `feature/rouge` and look for the relationship:

<!-- snippet: ch07/no-parent-branch/01-created-from -->
```text
$ git switch -c feature/rouge-stemming feature/rouge
Switched to a new branch 'feature/rouge-stemming'
$ cat .git/refs/heads/feature/rouge-stemming
936bfbd7a649344c04602bfd7b614a32596b06a7
$ git cat-file -p HEAD
tree 8dd91332643c665aad37f53a444b610cabdfd9c0
parent 7a1ccc7e383d6b20935992a53b77015c81bbd978
author Lab User <you@example.com> 1788755820 +0530
committer Lab User <you@example.com> 1788755820 +0530

ROUGE-L: tokenize on whitespace
$ git config list --local
core.repositoryformatversion=0
core.filemode=true
core.bare=false
core.logallrefupdates=true
core.ignorecase=true
core.precomposeunicode=true
$ git reflog show feature/rouge-stemming
936bfbd feature/rouge-stemming@{0}: branch: Created from feature/rouge
```
<!-- /snippet -->

The new ref holds an ID. The commit it names has no field for a branch. The local configuration has no entry for the branch. The only mention of `feature/rouge` is the reflog line `branch: Created from feature/rouge`, which exists in this clone and nowhere else, and which `git branch -D` or reflog expiry removes.

<!-- snippet: ch07/no-parent-branch/02-which-branch -->
```text
$ git log --oneline --graph --all
* 37431c0 ROUGE-L: stem tokens
* 936bfbd ROUGE-L: tokenize on whitespace
* 7a1ccc7 Add ROUGE-L metric
* 69d8252 Add exact-match metric
* 6eab4a9 Add README
$ git branch --contains feature/rouge
  feature/rouge
* feature/rouge-stemming
$ git branch --contains main
  feature/rouge
* feature/rouge-stemming
  main
```
<!-- /snippet -->

`git branch --contains` answers "which branches reach this commit", which is reachability, not origin: the commits of `feature/rouge` are on `feature/rouge-stemming` as much as on `feature/rouge`.

<!-- snippet: ch07/no-parent-branch/03-you-choose-the-base -->
```text
$ git log --oneline main..feature/rouge-stemming
37431c0 ROUGE-L: stem tokens
936bfbd ROUGE-L: tokenize on whitespace
7a1ccc7 Add ROUGE-L metric
$ git log --oneline feature/rouge..feature/rouge-stemming
37431c0 ROUGE-L: stem tokens
$ git branch -D feature/rouge
Deleted branch feature/rouge (was 936bfbd).
$ git log --oneline main..feature/rouge-stemming
37431c0 ROUGE-L: stem tokens
936bfbd ROUGE-L: tokenize on whitespace
7a1ccc7 Add ROUGE-L metric
```
<!-- /snippet -->

`main..feature/rouge-stemming` lists three commits; against `feature/rouge` it lists one. Delete `feature/rouge` and the first answer does not change, because the commits never belonged to a branch. The nearest thing to an answer is a guess: `%(is-base:<commit>)` marks "the ref that is most likely the ref used as a starting point for the branch that produced <commit-ish>", chosen by a first-parent heuristic ([git-for-each-ref](https://git-scm.com/docs/git-for-each-ref)), and the guess changes with the refs that exist:

<!-- snippet: ch07/base-guess/01-guess -->
```text
$ git log --oneline --decorate
ad8abff (HEAD -> feature/rouge-stemming) ROUGE-L: stem tokens
936bfbd (feature/rouge) ROUGE-L: tokenize on whitespace
7a1ccc7 Add ROUGE-L metric
69d8252 (main) Add exact-match metric
6eab4a9 Add README
$ git for-each-ref --format='%(refname:short) %(is-base:feature/rouge-stemming)' refs/heads/main refs/heads/feature/rouge
feature/rouge (feature/rouge-stemming)
main 
$ git branch -D feature/rouge
Deleted branch feature/rouge (was 936bfbd).
$ git for-each-ref --format='%(refname:short) %(is-base:feature/rouge-stemming)' refs/heads/main
main (feature/rouge-stemming)
```
<!-- /snippet -->

**In production.** Stacked branches are where this bites. Branch B was created from branch A, A is merged with a squash or deleted, and B's "changes against `main`" suddenly include everything A did, because the base you implied no longer exists. `git rebase --onto` moves B to its real base ([Chapter 9](ch09-rebase.md), sections 9.5 and 9.9). Commands such as `git rebase` and `git merge` take the target as an argument for the same reason: Git cannot infer it.

> **GitHub, not Git.** A pull request has a base branch, chosen when it is opened and stored by GitHub, not by Git. It is the one place where "created from" is recorded ([Chapter 17](ch17-pull-requests.md)).

## 7.10 Remote-tracking branches and upstream: a preview

**In one sentence.** A remote-tracking branch such as `origin/main` is a ref in your own repository that records the last position of a branch in another repository, and an upstream is two configuration lines that pair a local branch with one.

**Precisely.** Remote-tracking branches live under `refs/remotes/<remote>/` and are "how Git stores the last-known state of a branch in a remote repository"; `git fetch` updates them ([gitdatamodel](https://git-scm.com/docs/gitdatamodel)). The upstream of branch B is configured by `branch.B.remote` and `branch.B.merge`, and `B@{upstream}` or `@{u}` names the corresponding remote-tracking branch ([gitrevisions](https://git-scm.com/docs/gitrevisions)). `git status -sb` and `git branch -v` compare a branch with its upstream; nothing in that comparison talks to the server.

**See it.**

<!-- snippet: ch07/upstream-preview/01-refs -->
```text
$ git for-each-ref --format='%(objectname:short) %(refname)'
d1e8f22 refs/heads/main
d1e8f22 refs/remotes/origin/main
$ git branch -vv
* main d1e8f22 [origin/main] Add exact-match metric
```
<!-- /snippet -->

<!-- snippet: ch07/upstream-preview/02-upstream -->
```text
$ git rev-parse --abbrev-ref '@{upstream}'
origin/main
$ git rev-parse --symbolic-full-name '@{u}'
refs/remotes/origin/main
$ git config get branch.main.remote
origin
$ git config get branch.main.merge
refs/heads/main
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

Two refs, same ID, two namespaces. `@{upstream}` resolves through the two configuration entries to `refs/remotes/origin/main`. Now Asha pushes a commit from her own clone:

<!-- snippet: ch07/upstream-preview/03-last-known-state -->
```text
# Asha has pushed one commit to the server. Your repository has not been told.
$ git status -sb
## main...origin/main
$ git rev-parse --short origin/main
d1e8f22
$ git fetch
From $LAB/ch07/upstream-preview/origin
   d1e8f22..0015820  main       -> origin/main
$ git rev-parse --short origin/main
0015820
$ git status -sb
## main...origin/main [behind 1]
```
<!-- /snippet -->

Before the fetch, `git status -sb` reports no difference, because `origin/main` is what your repository last heard. The fetch moves `origin/main` and the status changes to `behind 1`. "Up to date with origin/main" is a statement about your copy of the remote, never about the remote itself.

<!-- snippet: ch07/upstream-preview/04-setting-upstream -->
```text
$ git switch -c feature/rouge
Switched to a new branch 'feature/rouge'
$ git rev-parse --abbrev-ref '@{upstream}'
fatal: no upstream configured for branch 'feature/rouge'
[exit status: 128]
$ git switch -c hotfix/ci origin/main
Switched to a new branch 'hotfix/ci'
branch 'hotfix/ci' set up to track 'origin/main'.
$ git branch -vv
  feature/rouge d1e8f22 Add exact-match metric
* hotfix/ci     0015820 [origin/main] Add CI workflow
  main          d1e8f22 [origin/main: behind 1] Add exact-match metric
```
<!-- /snippet -->

A branch created from another local branch has no upstream. A branch created from a remote-tracking branch gets one automatically (`branch.autoSetupMerge`, default `true`), which is what the line `set up to track` reports. [Chapter 12](ch12-remote-operations.md) covers fetch, push, refspecs and `@{push}`.

## 7.11 Lightweight tags as refs

**In one sentence.** A lightweight tag is a ref under `refs/tags/` that names an object directly; it is a label that is not expected to move.

**See it.**

<!-- snippet: ch07/lightweight-tags/01-a-ref -->
```text
$ git tag v0.1.0
$ cat .git/refs/tags/v0.1.0
69d82526af97115a79ad14d198c1ba24c22d5fb9
$ git cat-file -t v0.1.0
commit
$ git for-each-ref
69d82526af97115a79ad14d198c1ba24c22d5fb9 commit	refs/heads/main
69d82526af97115a79ad14d198c1ba24c22d5fb9 commit	refs/tags/v0.1.0
```
<!-- /snippet -->

The tag file holds the commit ID, and `git cat-file -t` on the tag name reaches the commit: no object was created. One commit later, the branch has moved and the tag has not:

<!-- snippet: ch07/lightweight-tags/02-does-not-move -->
```text
$ git log --oneline --decorate
e09c144 (HEAD -> main) Add batch runner
69d8252 (tag: v0.1.0) Add exact-match metric
6eab4a9 Add README
```
<!-- /snippet -->

<!-- snippet: ch07/lightweight-tags/03-annotated-contrast -->
```text
$ git tag -a v0.2.0 -m "Release 0.2.0"
$ git cat-file -t v0.2.0
tag
$ git rev-parse v0.2.0 'v0.2.0^{commit}' HEAD
f850d5e1360ebcb51575a79519e389642a005ad3
e09c14440a4310ac2cb3110c0a778b2f2ec34e0f
e09c14440a4310ac2cb3110c0a778b2f2ec34e0f
```
<!-- /snippet -->

An annotated tag, `-a`, is different: the ref names a tag object with its own ID, tagger, date and message, and `v0.2.0^{commit}` peels it to the commit. The manual reserves annotated tags for releases and lightweight tags for "private or temporary object labels" ([git-tag](https://git-scm.com/docs/git-tag)); [Chapter 14B](ch14b-config-tags-signing.md) covers annotated and signed tags.

<!-- snippet: ch07/lightweight-tags/04-no-reflog -->
```text
$ ls .git/logs/refs
heads
$ git tag v0.1.0 HEAD
fatal: tag 'v0.1.0' already exists
[exit status: 128]
$ git tag -f v0.1.0 HEAD
Updated tag 'v0.1.0' (was 69d8252)
$ git tag -d v0.1.0
Deleted tag 'v0.1.0' (was e09c144)
```
<!-- /snippet -->

`.git/logs/refs` has a `heads` directory and no `tags` directory: `core.logAllRefUpdates` creates reflogs for branches, remote-tracking branches, notes and HEAD, not for tags ([git-config](https://git-scm.com/docs/git-config)). `git tag -f` 🟡 CAUTION and `git tag -d` 🟡 CAUTION therefore leave no trace except the `was ...` ID in their output. Write it down.

<!-- snippet: ch07/lightweight-tags/05-ambiguous -->
```text
$ git branch v0.2.0 HEAD~1
$ git log -1 --format='%h %s' v0.2.0
warning: refname 'v0.2.0' is ambiguous.
e09c144 Add batch runner
$ git log -1 --format='%h %s' heads/v0.2.0
69d8252 Add exact-match metric
$ git branch -D v0.2.0
Deleted branch v0.2.0 (was 69d8252).
```
<!-- /snippet -->

A branch and a tag with the same short name are legal and confusing. Git resolves a short name by trying `refs/tags/<name>` before `refs/heads/<name>` ([gitrevisions](https://git-scm.com/docs/gitrevisions)), so `v0.2.0` meant the tag, with a warning. `heads/v0.2.0` and `tags/v0.2.0` are unambiguous.

## 7.12 Naming branches, and the `feature` versus `feature/x` conflict

**Conventions.** A branch name is a path under `refs/heads/`, so slashes group branches: `feature/retry-backoff`, `fix/judge-timeout`, `release/0.2`, `asha/bleu`. The grouping is what `git branch --list 'feature/*'` and `git for-each-ref refs/heads/feature/` match, and what GitHub's branch rules target by pattern, `qa/*` for example ([Chapter 18](ch18-branch-protection.md)). Lowercase names with hyphens avoid the case trap of section 7.15 and need no quoting. Ticket numbers in names (`fix/EVAL-212-empty-gold`) tie a branch to its reason without a lookup.

**Rules.** Git rejects names with a space, `..`, `~`, `^`, `:`, `?`, `*`, `[`, `\`, a control character, a component that starts with `.` or ends with `.lock`, a trailing `.`, the sequence `@{`, a leading or trailing slash, or a double slash; a branch name may not start with `-` ([git-check-ref-format](https://git-scm.com/docs/git-check-ref-format)). `git check-ref-format --branch <name>` tests a candidate without creating anything.

**The conflict.** One more rule follows from the path structure: a name cannot be both a ref and the prefix of other refs.

<!-- snippet: ch07/ref-name-conflict/01-conflict -->
```text
$ git branch feature
$ git branch feature/login
fatal: cannot lock ref 'refs/heads/feature/login': 'refs/heads/feature' exists; cannot create 'refs/heads/feature/login'
[exit status: 128]
$ ls .git/refs/heads
feature
main
```
<!-- /snippet -->

With the files backend the reason is visible: `refs/heads/feature` is a file, and `refs/heads/feature/login` would need a directory of the same name. The rule is not a file-system accident, though. It holds for packed refs and in a reftable repository, where there are no such files:

<!-- snippet: ch07/ref-name-conflict/02-not-only-files -->
```text
$ git pack-refs --all
$ ls .git/refs/heads
$ git branch feature/login
fatal: 'refs/heads/feature' exists; cannot create 'refs/heads/feature/login'
[exit status: 128]
$ git init -q --ref-format=reftable ../reftable-repo
$ git -C ../reftable-repo commit -q --allow-empty -m "Start"
$ git -C ../reftable-repo branch feature
$ git -C ../reftable-repo branch feature/login
fatal: 'refs/heads/feature' exists; cannot create 'refs/heads/feature/login'
[exit status: 128]
```
<!-- /snippet -->

It also holds in the other direction, and the fix is a rename:

<!-- snippet: ch07/ref-name-conflict/03-other-direction -->
```text
$ git branch -m feature feature/base
$ git branch feature/login
$ git branch feature
fatal: cannot lock ref 'refs/heads/feature': 'refs/heads/feature/base' exists; cannot create 'refs/heads/feature'
[exit status: 128]
$ git branch
  feature/base
  feature/login
* main
```
<!-- /snippet -->

<!-- snippet: ch07/ref-name-conflict/04-invalid-names -->
```text
$ git branch 'fix bug'
fatal: 'fix bug' is not a valid branch name
hint: See 'git help check-ref-format'
hint: Disable this message with "git config set advice.refSyntax false"
[exit status: 128]
$ git check-ref-format --branch fix..bug
fatal: 'fix..bug' is not a valid branch name
[exit status: 128]
$ git check-ref-format --branch fix/judge.lock
fatal: 'fix/judge.lock' is not a valid branch name
[exit status: 128]
$ git check-ref-format --branch fix/judge-timeout
fix/judge-timeout
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch07/ref-name-conflict/05-full-name-trap -->
```text
$ git branch refs/heads/fix/judge-timeout
$ git for-each-ref --format='%(refname)' refs/heads
refs/heads/feature/base
refs/heads/feature/login
refs/heads/main
refs/heads/refs/heads/fix/judge-timeout
$ git branch -D refs/heads/fix/judge-timeout
Deleted branch refs/heads/fix/judge-timeout (was 6eab4a9).
```
<!-- /snippet -->

The last transcript shows a name that is legal and wrong: `git branch refs/heads/fix/judge-timeout` created `refs/heads/refs/heads/fix/judge-timeout`, because `git branch` takes a short name and prepends `refs/heads/` itself.

```text
Observed behavior : since this morning, git fetch fails on every laptop with "cannot lock ref 'refs/heads/feature/login'"
                    or reports "unable to update local ref" for origin/feature/login
Git state         : each clone still has refs/remotes/origin/feature from an earlier fetch; the server now has feature/login
Mechanism         : the fetch tries to create origin/feature/login while origin/feature exists, and a ref cannot be
                    a name and a prefix at the same time
Root cause        : a branch named "feature" was deleted on the server after branches under "feature/" were agreed on,
                    and nobody's clone was told about the deletion
Why Git does this : ref names form one hierarchy; the rule keeps every ref name unambiguous
Correct fix       : git fetch --prune (or git remote prune origin) deletes the stale origin/feature and the fetch succeeds
Prevention        : reserve top-level names for namespaces (feature/, fix/) and never create a plain branch with one of them
```

Lab 4.3 runs this incident from both sides.

## 7.13 Stale branches

**In one sentence.** A stale branch is a ref that nobody needs any more, and Git offers three tests for it, each with a blind spot: age, reachability from `main`, and a deleted upstream.

**See it.** A repository with branches from a whole year. `git for-each-ref --sort=committerdate` lists refs by the date of their tip commit:

<!-- snippet: ch07/stale-branches/01-by-date -->
```text
$ git for-each-ref --sort=committerdate --format='%(committerdate:short) %(authorname) | %(refname:short)' refs/heads
2026-06-30 Lab User | feature/rouge
2026-08-20 Lab User | wip/prompt-tuning
2026-08-31 Lab User | fix/empty-gold
2026-09-07 Lab User | main
$ git for-each-ref --sort=committerdate --exclude=refs/remotes/origin/HEAD --format='%(committerdate:short) %(authorname) | %(refname:short)' refs/remotes/origin
2026-03-12 Asha Rao | origin/spike/judge-cache
2026-06-30 Lab User | origin/feature/rouge
2026-08-31 Lab User | origin/fix/empty-gold
2026-09-07 Lab User | origin/main
$ git for-each-ref --sort=committerdate --format='%(committerdate:short) %(refname:short)' refs/remotes/origin | awk '$1 < "2026-07-01"'
2026-03-12 origin/spike/judge-cache
2026-06-30 origin/feature/rouge
```
<!-- /snippet -->

Age says when the branch last changed, not whether its work landed. The second test is reachability:

<!-- snippet: ch07/stale-branches/02-merged -->
```text
$ git branch --merged main
  fix/empty-gold
* main
$ git branch --no-merged main
  feature/rouge
  wip/prompt-tuning
$ git branch -r --no-merged origin/main
  origin/feature/rouge
  origin/spike/judge-cache
```
<!-- /snippet -->

`--merged main` lists `fix/empty-gold`, merged with a merge commit. `feature/rouge` is missing although its content is in `main`: it was squash-merged, so `main` contains a new commit with the same tree and none of the branch's commits. Reachability cannot see that. The third test asks the server, through the remote-tracking refs:

<!-- snippet: ch07/stale-branches/03-gone -->
```text
# The two merged branches have been deleted on the server.
$ git fetch --prune
From $LAB/ch07/stale-branches/origin
 - [deleted]         (none)     -> origin/feature/rouge
 - [deleted]         (none)     -> origin/fix/empty-gold
$ git branch -vv
  feature/rouge     842be74 [origin/feature/rouge: gone] ROUGE-L: return a float
  fix/empty-gold    cad8f2c [origin/fix/empty-gold: gone] Exact match: handle empty gold answer
* main              00b2e49 [origin/main] Add CI workflow
  wip/prompt-tuning 9287f33 WIP: stricter judge prompt
$ git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads
feature/rouge [gone]
fix/empty-gold [gone]
main 
wip/prompt-tuning 
```
<!-- /snippet -->

`git fetch --prune` 🟡 CAUTION removes remote-tracking refs for branches the server no longer has, and `[gone]` marks every local branch whose upstream disappeared. On a team that deletes branches on the server after merging, `gone` is the most reliable signal. It still has to be read: `wip/prompt-tuning` was never pushed, so it has no upstream and no `gone`, and nothing but your memory says whether it matters.

<!-- snippet: ch07/stale-branches/04-squash-merged -->
```text
$ git branch -d fix/empty-gold
Deleted branch fix/empty-gold (was cad8f2c).
$ git branch -d feature/rouge
error: the branch 'feature/rouge' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/rouge'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git merge-tree --write-tree main feature/rouge
1442f02427f21cdc85e98b91d69535929f65e7ab
$ git rev-parse 'main^{tree}'
1442f02427f21cdc85e98b91d69535929f65e7ab
$ git branch -D feature/rouge
Deleted branch feature/rouge (was 842be74).
```
<!-- /snippet -->

`git branch -d` deletes the merge-commit branch and refuses the squash-merged one, for the reason above. The refusal is conditional: `-d` tests the branch against its upstream, or against HEAD when it has no upstream. Here the upstream is `gone` (pruned), so Git falls back to HEAD and finds commits that `main` cannot reach; a branch that was never pushed behaves the same. While the remote-tracking ref still exists and contains the branch, `-d` deletes it with a warning instead (section 7.5). The proof that the squash-merged branch is finished is a merge without a working tree: `git merge-tree --write-tree main feature/rouge` prints the tree a merge would produce, and it equals the tree of `main`. Merging the branch would change nothing, so `-D` is safe.

<!-- snippet: ch07/stale-branches/05-git-2-56 -->
```text
$ git branch --delete-merged 'origin/*' 2>&1 | head -n 1
error: unknown option `delete-merged'
```
<!-- /snippet -->

> **Version note.** Older behavior: cleaning up merged branches needs `git branch --merged` plus judgement, or a script. Current behavior: Git 2.56 adds `git branch --delete-merged <pattern>`, which deletes "local branches whose configured upstream matches <pattern>, but only when their tip is reachable from that upstream", with `--dry-run` to list them first (not run here: Git 2.55 reports the option as unknown). It skips a branch when "its configured upstream ref no longer exists", so it does not handle `[gone]` branches, and a branch whose tip is not reachable from its upstream, which a squash-merged one is not, "is silently skipped" ([git-branch at 2.56.0](https://github.com/git/git/blob/v2.56.0/Documentation/git-branch.adoc)). Since: Git 2.56 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc)). Recommended: after upgrading, `git branch --delete-merged 'origin/*' --dry-run` first; keep `-d` with `[gone]` and `merge-tree` for the rest.

**In production.** Deleting a local branch deletes a name in your clone. Deleting the branch on the server is a push (`git push origin --delete <branch>`, [Chapter 12](ch12-remote-operations.md)) and affects everyone's next prune. Before either, answer the CTO's question with the three tests and `git log --oneline main..<branch>`: if that range is empty or every commit in it is squash-merged, nothing is lost.

## 7.14 What can go wrong

**Commits on the wrong branch.** Two commits were made on `main` that belong on a feature branch, and the working tree holds a third, uncommitted edit:

<!-- snippet: ch07/wrong-branch/01-symptom -->
```text
$ git status -sb
## main...origin/main [ahead 2]
 M README.md
$ git log --oneline --decorate
cf0610c (HEAD -> main) Add cached() helper
478ecd8 Cache judge responses in memory
6b3b610 (origin/main) Add judge client
faf3622 Add README
```
<!-- /snippet -->

`[ahead 2]` says the commits are local only, so the repair is private. Because branches are refs, it takes two ref writes and copies nothing:

<!-- snippet: ch07/wrong-branch/02-two-ref-writes -->
```text
$ git switch -c feature/judge-cache
Switched to a new branch 'feature/judge-cache'
$ git branch -f main origin/main
branch 'main' set up to track 'origin/main'.
$ git log --oneline --decorate
cf0610c (HEAD -> feature/judge-cache) Add cached() helper
478ecd8 Cache judge responses in memory
6b3b610 (origin/main, main) Add judge client
faf3622 Add README
$ git status -sb
## feature/judge-cache
 M README.md
```
<!-- /snippet -->

`git switch -c feature/judge-cache` creates a branch at the current commit and attaches HEAD to it; the index and working tree are untouched, so the uncommitted edit comes along. `git branch -f main origin/main` is allowed now that `main` is no longer checked out, and it moves `main` back to the published commit. `set up to track` appears because the start point is a remote-tracking branch.

<!-- snippet: ch07/wrong-branch/03-what-moved -->
```text
$ git reflog show main -2
6b3b610 main@{0}: branch: Reset to origin/main
cf0610c main@{1}: commit: Add cached() helper
$ git reflog -1
cf0610c HEAD@{0}: checkout: moving from main to feature/judge-cache
$ git branch -vv
* feature/judge-cache cf0610c Add cached() helper
  main                6b3b610 [origin/main] Add judge client
```
<!-- /snippet -->

Had the commits been pushed, the repair would be the same two writes plus a decision about the server copy ([Chapter 12](ch12-remote-operations.md), section 12.8). [Chapter 11](ch11-reset-revert-restore.md) shows the same scenario with `git reset`.

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| Commits "disappeared" after switching branches | `git reflog` shows `commit:` lines above the last `checkout: moving from <id> to <branch>` entry | `git branch <name> <id>` (Lab 4.2) | Give a detached HEAD a branch before leaving it |
| `git branch -d` refuses although the branch "was merged" | `git log --oneline main..<branch>` lists commits: squash or rebase merge, and the branch has no upstream or its upstream is `gone` (with an upstream that still contains it, `-d` deletes with a warning) | Verify with `git merge-tree --write-tree main <branch>`, then `-D` | Delete the branch in the same step as the squash merge |
| `cannot lock ref 'refs/heads/feature/x'` | `git branch --list feature` shows a branch named `feature` | `git branch -m feature feature/<something>` | Reserve namespace names |
| `git fetch` fails with `unable to update local ref` | `git branch -r` shows `origin/feature` next to a new `feature/...` on the server | `git fetch --prune` (Lab 4.3) | `fetch.prune=true` on a team that uses namespaces |
| `git switch` refuses: "Your local changes ... would be overwritten" | `git status` lists edits in files that differ between the branches | Commit or stash first, or `git switch --merge` | Commit before switching |
| `git branch -f main <x>` fails with "used by worktree" | `main` is checked out here or in a linked worktree | `git reset --soft <x>` while on `main`, or switch away first | Expected: force-moving the current branch needs `reset` |
| `git branch feature` fails: `not a valid object name: 'main'` | A new repository with no commit; `git log` shows nothing | Make the first commit, then branch | Expected on an unborn branch |
| `warning: refname 'v0.2.0' is ambiguous` | `git for-each-ref --format='%(refname)' '*v0.2.0'` lists a tag and a branch | Use `heads/v0.2.0` or `tags/v0.2.0`; rename one | Keep tag and branch names disjoint |
| `git branch -vv` shows `[origin/x: gone]` | The upstream branch was deleted on the server | `git branch -d x` once its work is confirmed merged | Prune regularly |
| `git status` says `HEAD detached at <id>` in a script's checkout | `cat .git/HEAD` shows a raw ID: a clone with `--branch <tag>`, a CI job, a worktree from a tag | Use `git rev-parse HEAD`; push with an explicit refspec | Write scripts for detached HEAD |
| A rename left `-vv` pointing at the old upstream name | `git config get branch.<new>.merge` still names `refs/heads/<old>` | `git push -u origin <new>` and delete the old remote branch (Chapter 12) | Rename before the first push |

## 7.15 When not to use it, and dangerous edge cases

**Case-insensitive file systems.** The default macOS volume format does not distinguish `main` from `MAIN`. With the files backend a loose ref is a file, so a wrong-case name finds the right file and HEAD records the wrong name:

<!-- snippet: ch07/case-trap/01-wrong-case -->
```text
$ git config get core.ignoreCase
true
$ git switch MAIN
Switched to branch 'MAIN'
$ cat .git/HEAD
ref: refs/heads/MAIN
$ git branch
  main
$ git status
On branch MAIN
nothing to commit, working tree clean
```
<!-- /snippet -->

`git switch MAIN` succeeded, HEAD says `refs/heads/MAIN`, and `git branch` lists `main` without an asterisk: the current branch is not in the list. A commit in this state moves the file that exists, `refs/heads/main`:

<!-- snippet: ch07/case-trap/02-commit -->
```text
$ printf '\nRun the tests with: python -m pytest\n' >> README.md
$ git commit -am "Document how to run the tests"
[MAIN 6e419d0] Document how to run the tests
 1 file changed, 2 insertions(+)
$ git log --oneline --decorate
6e419d0 (HEAD, main) Document how to run the tests
6eab4a9 Add README
$ git for-each-ref --format='%(objectname:short) %(refname)' refs/heads
6e419d0 refs/heads/main
```
<!-- /snippet -->

`git log --decorate` prints `(HEAD, main)` rather than `(HEAD -> main)`: HEAD and `main` name the same commit, but HEAD does not point at `main`. Switching to the correctly spelled name repairs it, and nothing was lost:

<!-- snippet: ch07/case-trap/03-fix -->
```text
$ git switch main
Switched to branch 'main'
$ git branch
* main
$ git log --oneline --decorate -1
6e419d0 (HEAD -> main) Document how to run the tests
```
<!-- /snippet -->

<!-- snippet: ch07/case-trap/04-two-names -->
```text
$ git branch Main
fatal: a branch named 'Main' already exists
[exit status: 128]
$ git pack-refs --all
$ git branch Main
$ git for-each-ref --format='%(objectname:short) %(refname)' refs/heads
6e419d0 refs/heads/Main
6e419d0 refs/heads/main
```
<!-- /snippet -->

Once the refs are packed, the file system is out of the picture and `Main` is created as a second ref. The repository now has two branches that differ only in case. A case-sensitive file system keeps them apart; on this volume they collide again as soon as one of them is written back as a loose file. The report's reasons for making reftable the default in Git 3.0 include exactly this class of clash ([Phase 0 report, section 1](../reports/Git%20and%20GitHub%20mastery%20research.md)). Use lowercase names, and check `cat .git/HEAD` when `git branch` shows no asterisk.

**Other edge cases.**

- **`git branch -D` deletes the branch's reflog.** For a branch whose commits were never checked out, nothing but the printed `was <id>` and the object grace period remains. Preview with `git log --oneline main..<branch>`.
- **A plain `git branch -d` can delete `main`.** There is nothing special about the name; if `main` is not checked out and its tip is reachable from its upstream, `-d` deletes it. Recreate it from `origin/main`.
- **Deleting a branch does not delete its commits**, and it does not remove them from the server, from colleagues' clones or from a pull request. A branch deletion is never a way to withdraw content.
- **`git switch` can overwrite an ignored file** that is tracked on the other branch ([Chapter 4](ch04-working-tree.md), section 4.16).
- **`git switch --discard-changes` (also `-f`) is 🔴 DANGEROUS.** It changes the index and working tree to the target and destroys uncommitted edits in the files it touches, with no preview beyond `git status` and no recovery for content that was never staged. It is appropriate only when you have decided to throw the edits away.
- **Hand-written ref files are 🔴 DANGEROUS.** `echo <id> > .git/refs/heads/x` skips validation, locking and the reflog; a typo produces a broken ref that `git log --all` refuses to read (Lab 4.1 repairs one). Use `git update-ref`.
- **Tags have no reflog by default.** `git tag -f` and `git tag -d` leave only the ID in their output.

## 7.16 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git branch`, `git for-each-ref`, `git symbolic-ref HEAD`, `git rev-parse`, `git merge-base`, `git rev-list`, `git log` | 🟢 SAFE | Nothing | not needed | not needed |
| `git branch <name> [<start>]`, `git switch -c`, `git tag <name>` | 🟢 SAFE | Adds a ref (and for branches a reflog) | `git rev-parse <start>` | Delete the ref |
| `git switch <branch>`, `git switch --detach`, `git switch -`, `git switch --orphan`, the `git checkout` equivalents | 🟢 SAFE | HEAD, index and working tree (`--orphan` removes tracked files); all refuse to overwrite local edits | `git status` | `git switch -`, or the `checkout:` line in `git reflog` |
| `git branch -m`, `git branch -f`, `git switch -C`, `git update-ref <ref> <id>`, `git symbolic-ref HEAD <ref>` | 🟡 CAUTION | Renames or moves a ref; the old value stays in the reflog | `git branch -vv`, `git rev-parse <ref>` | `git branch -f <ref> <ref>@{1}`; rename back |
| `git branch -d`, `git tag -d`, `git tag -f`, `git fetch --prune` | 🟡 CAUTION | Deletes or moves a ref; `-d` checks merge status first; tags and remote-tracking refs have no reflog by default | `git branch --merged`, `git remote prune origin --dry-run` | Recreate from the `was <id>` output or from `git reflog` |
| `git branch -D`, `git update-ref -d` | 🔴 DANGEROUS | Deletes a ref and its reflog with no merge check | `git log --oneline main..<branch>` | `git branch <name> <id>` while the objects exist; the HEAD reflog if the commits were checked out |
| `git switch --discard-changes`, `git checkout -f` | 🔴 DANGEROUS | Overwrites uncommitted changes in the index and working tree | `git status`, `git diff` | None for content that was never staged |
| Writing a file under `.git/refs/` by hand | 🔴 DANGEROUS | A ref without validation, locking or reflog | `git update-ref` instead | `git update-ref` after deleting the broken file (Lab 4.1) |

## 7.17 Version notes

> **Version note.** Older behavior: `git checkout` switched branches, created them with `-b`, detached HEAD and restored files. Current behavior: `git switch` and `git restore` split those jobs; `git checkout` still does all of them and is not scheduled for removal. Since: Git 2.23 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.23.0.adoc)); no longer labelled experimental from Git 2.51 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc)). Recommended: write `switch`, read `checkout`.

> **Version note.** Older behavior: the current branch had to be parsed out of `git branch` or `git symbolic-ref`. Current behavior: `git branch --show-current`, which prints nothing in detached HEAD. Since: Git 2.22 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.22.0.adoc)). Recommended: use it in scripts, and treat empty output as detached.

> **Version note.** Older behavior: `git checkout -m <branch>`, and `git switch -m`, gave one chance to resolve conflicts between local edits and the target branch. Current behavior: the local changes are saved in a stash and reapplied. Since: Git 2.55 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc)). Recommended: commit or stash yourself; use `--merge` when you understand the stash it may leave behind.

> **Version note.** Older behavior: no built-in way to ask which branch a commit was probably based on. Current behavior: `%(is-base:<commit>)` in `git for-each-ref`. Since: Git 2.47 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.47.0.adoc)). Recommended: a hint for humans, never an input to automation.

> **Version note.** Current behavior: Git 2.56 adds `git branch --delete-merged` and `--forked <branch>`, which lists branches whose configured upstream matches ([git-branch at 2.56.0](https://github.com/git/git/blob/v2.56.0/Documentation/git-branch.adoc)). Not run here; section 7.13 has the details and the limits.

> **Version note.** Older behavior: `git config --get branch.x.merge`. Current behavior: `git config get branch.x.merge`, as used in this chapter; the old form still works. Since: Git 2.46. Recommended: the subcommand form.

> **Unverified.** The releases that introduced `%(ahead-behind:<commit>)` for `git for-each-ref` and `git refs verify` were not found in the release notes available for this chapter. Both ran on Git 2.55.0 as shown.

## 7.18 Practice

- **Labs 4.1 to 4.4** in the [Module 4 lab manual](../lab-manual/m04-refs-branches-head.md): refs by hand, the detached-HEAD rescue, the `feature` versus `feature/x` conflict, and counting divergence.
- Replay any transcript with `labs/run ch07/<demo>` and continue by hand in the sandbox it leaves behind.
- Three drills. In `ch07/divergence`, predict the output of `git rev-list --left-right --count feature/rouge...main` before running it. In `ch07/detached-head`, find the two commits of the experiment with `git reflog` alone, without scrolling back. In `ch07/stale-branches`, write one `git for-each-ref` command that lists every local branch with its upstream state and the date of its tip.

## 7.19 Interview questions

1. Define a branch in one sentence that mentions neither "copy" nor "line of development", and prove the definition with two commands.
2. What is in `.git/HEAD` in the three states: on a branch, detached, and on an unborn branch? How does each state change what `git commit` does?
3. A colleague's two days of commits are "gone" after she checked out a tag and later switched back to `main`. Walk through the recovery and explain why it works.
4. Why does `git branch -d` refuse a branch that was squash-merged once its upstream is gone (or when it never had one), why does it delete the same branch with a warning while the remote-tracking ref still contains it, and how do you prove the branch is safe to delete?
5. Explain the `-d` rule in terms of the upstream. Give one case where `-d` deletes a branch that `main` does not contain, and one where it refuses a branch that `main` does contain.
6. What does `git switch -c fix origin/main` write to `.git`, including configuration?
7. `git log main..feature` and `git diff main..feature`: how do the two dots differ in meaning? Which one do you want for a review?
8. Does Git know which branch a branch was created from? What is the closest it can offer, and why is a pull request's base branch not the same thing?
9. Why does `git fetch` fail on every clone after someone pushes `feature/login`, and what is the one-command fix?
10. Why does `git tag -d` have no undo through the reflog, while `git branch -D` sometimes does?
11. On macOS, `git branch` shows no current branch and `git log --decorate` says `(HEAD, main)`. What happened?
12. Which commands in this chapter are dangerous enough that you would want a preview, and what is the preview for each?

## 7.20 Sources

**Primary sources**

- [git-branch](https://git-scm.com/docs/git-branch), [git-switch](https://git-scm.com/docs/git-switch), [git-checkout](https://git-scm.com/docs/git-checkout) ("Detached HEAD"), [git-symbolic-ref](https://git-scm.com/docs/git-symbolic-ref), [git-update-ref](https://git-scm.com/docs/git-update-ref), [git-for-each-ref](https://git-scm.com/docs/git-for-each-ref), [git-rev-parse](https://git-scm.com/docs/git-rev-parse), [git-merge-base](https://git-scm.com/docs/git-merge-base), [git-rev-list](https://git-scm.com/docs/git-rev-list), [git-tag](https://git-scm.com/docs/git-tag), [git-check-ref-format](https://git-scm.com/docs/git-check-ref-format), [git-pack-refs](https://git-scm.com/docs/git-pack-refs), [git-merge-tree](https://git-scm.com/docs/git-merge-tree), [git-fetch](https://git-scm.com/docs/git-fetch), [git-clone](https://git-scm.com/docs/git-clone), [git-worktree](https://git-scm.com/docs/git-worktree), [git-submodule](https://git-scm.com/docs/git-submodule), [git-config](https://git-scm.com/docs/git-config). The local copies (`git help -m <command>`) are the Git 2.55.0 text that the transcripts were checked against.
- [gitrevisions](https://git-scm.com/docs/gitrevisions), [gitglossary](https://git-scm.com/docs/gitglossary), [gitdatamodel](https://git-scm.com/docs/gitdatamodel).
- Git source at 2.55.0, [wt-status.c](https://github.com/git/git/blob/v2.55.0/wt-status.c), for how `git status` chooses "detached at", "detached from" and "Not currently on any branch".
- [git-branch at 2.56.0](https://github.com/git/git/blob/v2.56.0/Documentation/git-branch.adoc) and release notes [2.22](https://github.com/git/git/blob/master/Documentation/RelNotes/2.22.0.adoc), [2.23](https://github.com/git/git/blob/master/Documentation/RelNotes/2.23.0.adoc), [2.47](https://github.com/git/git/blob/master/Documentation/RelNotes/2.47.0.adoc), [2.51](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc), [2.55](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc), [2.56](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).
- GitHub Docs: [pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests), [events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows).

**Secondary sources**

- Pro Git, [Branches in a Nutshell](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell) and [Git References](https://git-scm.com/book/en/v2/Git-Internals-Git-References). Caveats: `master` throughout, and branch switching with `git checkout`.
- Julia Evans, [git branches: intuition & reality](https://jvns.ca/blog/2023/11/23/branches-intuition-reality/) and [how HEAD works in git](https://jvns.ca/blog/2024/03/08/how-head-works-in-git/); the [2024 poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/) quoted in section 7.1.
- The Phase 0 report of this course, sections 1 and 12, for the reftable rationale and the misconception table.

**Videos** (optional; assessments in the Phase 0 report rest on captions, not on full viewing)

- [Git Internals by John Britton of GitHub - CS50 Tech Talk](https://www.youtube.com/watch?v=lG90LZotrpo), 2018: refs as files holding an ID, branches as pointers. Caveats: `master` and `checkout`; SHA-1 only.
- [Git For Beginners](https://www.youtube.com/watch?v=vwj89i2FmG0), Telusko, 2023: asks whether a branch copies the project and explains why it does not. Caveat: no undo or rebase.
- [Intern DELETED a Git Branch!](https://www.youtube.com/watch?v=jXoOEfpgzF4), Chai aur Code, Hindi, 2026: recovering a deleted branch through the reflog. Caveat: a single scenario.

> **Outdated advice.** Several popular tutorials introduce a branch as a copy of the project and HEAD as the latest commit; the report lists [Apna College's 2023 tutorial](https://www.youtube.com/watch?v=Ez8F0nW6S-w) among them. Both statements fail the transcripts of sections 7.2 and 7.3.

**Further reading**

- [Chapter 8](ch08-merge.md), section 8.2, for merge bases with more than one candidate; [Chapter 12](ch12-remote-operations.md) for everything about `origin/`; [Chapter 13](ch13-recovery.md) for the reflog as a recovery tool.
