# Answer key, Gate 1: Fundamentals

> **For the examiner.** This file holds the model answers, the marking guidance and the real outputs for [Gate 1](../assessments/gate-1-fundamentals.md). A learner who has failed the gate does not get this file: they get the remediation map in the gate file and variant B. Every transcript is real output of a script under `labs/gates/` on Git 2.55.0.

**Marking, in general.** A concept answer is marked on mechanism. Full marks need the Git state (objects, refs, files) and the cause in the right order; correct vocabulary without mechanism earns at most 2 of 5. Deduct a point for each statement that is wrong about Git, even inside an otherwise complete answer: a senior engineer is trusted, so a confident wrong statement costs more than an omission.

---

## Part 1: Concepts

### C1 (5 points)

**Model answer.** A commit object contains the ID of one tree, the IDs of its parents, an author line, a committer line and the message. The tree names a complete snapshot: every file of the project is reachable from it as a blob. No commit stores a diff. `git show <commit>` computes the diff at the moment you ask, by comparing the commit's tree with the tree of its parent. Checking out the newest commit reads one tree and its blobs; it replays nothing, and its cost does not depend on the length of the history. A file that did not change is not stored again: the new tree entry carries the same blob ID as before, and a directory in which nothing changed is the same tree object. Deltas exist one level below this model: when Git packs objects into a packfile it may store an object as a difference against a similar object. That is compression. `git cat-file -p` returns the full content either way.

**Marking.** 1 point: the content of a commit object (tree, parents, author, committer, message). 1 point: a tree is a full snapshot. 1 point: a diff is computed from two trees on demand. 1 point: unchanged files and directories are shared by ID. 1 point: deltas are a storage detail of packfiles. Partial credit of 3 for "snapshots, not diffs" with sharing explained and nothing about `git show` or packs.

**Common wrong answers.** "Git stores the first version in full and diffs after that" (the model of older systems). "Each commit copies all files, so history is expensive" (misses sharing). "A packfile proves Git stores diffs" (confuses compression with the model).

**Reference.** Chapter 2, sections 2.3 and 2.10.

### C2 (5 points)

**Model answer.** New objects: one blob for the new content of `README.md`; one tree for `docs/` three levels down and one for each directory above it up to the root, because a tree contains the IDs of its entries, so a new child ID changes the parent; and one commit. That is one blob, four trees (three directories and the root) and one commit. Every other blob and every tree outside that path is reused by ID. Two commits with an empty diff between them have the same tree. Their IDs can still differ because the ID is the hash of the whole commit object, and that object also holds the parents, the author line, the committer line with its timestamp, and the message. An amend, a rebase or a cherry-pick writes a new committer line and therefore a new ID. To prove equal content, compare the trees: `git rev-parse X^{tree} Y^{tree}` prints the same ID twice.

**Marking.** 2 points: the correct set of new objects with the reason (a tree embeds child IDs). 1 point: everything else is reused. 1 point: what the commit ID covers. 1 point: the tree comparison. A candidate who says "only the blob and the commit are new" gets at most 2.

**Common wrong answers.** Forgetting the intermediate trees. "The ID is the hash of the changes." "Same diff means same commit."

**Reference.** Chapter 2, sections 2.4 and 2.5; Chapter 6, section 6.4 (root-cause box "the deployed commit is not the reviewed commit").

### C3 (5 points)

**Model answer.**

| Command | Reads | Writes |
|---|---|---|
| `git add <path>` | working tree | the object database (a blob, at once) and the index entry |
| `git commit` | index | a tree and a commit object; then the branch ref that `HEAD` names. Working tree and index entries are unchanged |
| `git restore --staged <path>` | `HEAD` | index |
| `git restore <path>` | index | working tree |

`git diff` without arguments compares the working tree with the index. It prints nothing when they agree, and they agree right after `git add`. `git commit` writes the index, so it commits whatever differs between the index and `HEAD`, which is what `git diff --cached` shows. An empty `git diff` therefore says only that nothing is unstaged.

**Marking.** 1 point for each correct row, 1 point for the two diffs. A candidate who says `git commit` reads the working tree loses that row and the last point.

**Common wrong answers.** "`git restore <path>` restores from the last commit" (it copies from the index unless `--source` is given). "`git add` marks a file for the next commit" (it copies content; a later edit is not included).

**Reference.** Chapter 2, section 2.9; Chapter 5, sections 5.3, 5.4 and 5.9; Chapter 4, section 4.7.

### C4 (5 points)

**Model answer.** Switching to `release-1.0`: Git has to write the tracked file of that branch into the working tree. The private file is in the way, and because it is ignored Git overwrites it without a message. Switching back to `main`: the path is not in the tree of `main`, so Git removes the tracked file. The private content is gone after the first switch and the file itself after the second. No object holds the private content, because it was never added, so neither the reflog nor `git fsck` can find it. Git prints no warning because `--overwrite-ignore` is the default of `git switch`, `git checkout` and `git merge`: an ignored file is assumed to be a build product that can be regenerated. An untracked file that is not ignored stops the switch with "The following untracked working tree files would be overwritten by checkout". Prevention: give private files a name that no commit on any branch has ever tracked, and keep irreplaceable data outside the working tree.

**Marking.** 2 points: both switches described correctly. 1 point: `--overwrite-ignore` is the default and why. 1 point: the contrast with a plain untracked file. 1 point: nothing to recover from, and a prevention that addresses the cause. "Git never deletes untracked files" earns 0 for the first three points.

**Common wrong answers.** "Git refuses to switch." "The reflog has it." "Ignored means protected."

**Reference.** Chapter 4, section 4.16 (root-cause box "An ignored local file was replaced, then deleted, by two branch switches"), and section 4.3.

### C5 (5 points)

**Model answer.** `git add` writes a blob for each staged file into `.git/objects` and rewrites `.git/index` so that the entry names the blob. `git commit` then: builds tree objects from the index (one per directory whose content is new) and writes them; writes the commit object, which names the root tree, the current commit as parent, author, committer and message; sets the ref that `HEAD` names, `refs/heads/main`, to the new commit ID; appends one line to `logs/HEAD` and one to `logs/refs/heads/main`; and leaves the message in `COMMIT_EDITMSG`. `.git/HEAD` itself is not rewritten: it still contains `ref: refs/heads/main`. With a detached `HEAD` the objects are the same, but there is no branch to move: Git writes the new commit ID into `.git/HEAD` directly and only the `HEAD` reflog gains a line. An hour later that matters because no ref names the commit. After a switch to a branch it is reachable only through the `HEAD` reflog, it does not appear in `git log --all`, and it is not pushed with any branch.

**Marking.** 1 point: the blob is written by `git add`, not by `git commit`. 1 point: trees and the commit object. 1 point: the branch ref moves and `HEAD` is unchanged. 1 point: both reflogs. 1 point: the detached case with its consequence.

**Common wrong answers.** "`git commit` updates HEAD" as a statement about the file. "A detached commit is deleted when you switch away" (it is unreachable from refs, not deleted).

**Reference.** Chapter 5, section 5.3; Chapter 6, section 6.3; Chapter 7, sections 7.4 and 7.7.

### C6 (5 points)

**Model answer.** For an identity Git reads the environment first: `GIT_AUTHOR_EMAIL` and `GIT_COMMITTER_EMAIL` win over every configuration value. Then configuration, where the value read last wins: `-c user.email=...` on the command line and the `GIT_CONFIG_COUNT` family (the command scope); the worktree file if `extensions.worktreeConfig` is on; the repository's `.git/config` (local); the global file, including any file it pulls in through `include.path` or `includeIf`, where the position of the include decides which line is read last; the system file. A local value beats the new global one, and so does a conditional include that stands after the `[user]` section of the global file. The command is `git config get --show-scope --show-origin user.email`, or with `--all` to see every value in reading order, the last line being the winner. It shows configuration only: an identity that comes from the environment is invisible to it, so check `env | grep '^GIT_'` as well. `git commit --author=` is a third source, for the author only.

**Marking.** 1 point: local beats global. 1 point: command scope beats local. 1 point: includes and their order. 1 point: the environment variables beat configuration and are not shown by `git config`. 1 point: the command with `--show-scope --show-origin`.

**Common wrong answers.** "Global overrides local, because it is global." "`-c` beats everything" (the author variable beats it, see P4). Forgetting the environment, which is how CI systems and some editors set identities.

**Reference.** Chapter 14B, sections 14B.2 to 14B.4; Chapter 6, section 6.5.

---

## Part 2: Prediction

Marking for every prediction item: the points are split as stated; a prediction counts when the lines and their order are right. Exact spacing is not required. A right output with a wrong mechanism earns half of that sub-item.

### P1 (5 points)

<!-- snippet: gates/g1-predict/p1-answer -->
```text
$ git count-objects | cut -d, -f1
4 objects
$ git ls-tree HEAD
100644 blob ff33e07f184dbc8dbed20e96eead7d59b8fec732	default.yaml
040000 tree d6eb565d5f169b6ba6675c8866f351d033a30f75	eu
040000 tree d6eb565d5f169b6ba6675c8866f351d033a30f75	us
$ git ls-tree -r HEAD
100644 blob ff33e07f184dbc8dbed20e96eead7d59b8fec732	default.yaml
100644 blob ff33e07f184dbc8dbed20e96eead7d59b8fec732	eu/service.yaml
100644 blob ff33e07f184dbc8dbed20e96eead7d59b8fec732	us/service.yaml
$ git cat-file --batch-all-objects --batch-check='%(objecttype) %(objectname)'
tree 29617cae7b9845cbcd7b2c51601179c890901053
commit 614c93ba8f23e8976f1e50e0859a9aba35a3f614
tree d6eb565d5f169b6ba6675c8866f351d033a30f75
blob ff33e07f184dbc8dbed20e96eead7d59b8fec732
```
<!-- /snippet -->

Four objects: one commit, the root tree, one tree that serves as both `eu` and `us`, and one blob that serves as all three files. Git stores content, not files: three files with the same bytes are one blob, and two directories with the same entries (same name, same mode, same blob) are one tree.

**Marking.** 2 points: "4 objects". 2 points: `eu` and `us` carry the same tree ID. 1 point: the types (one commit, two trees, one blob). The common answer "6 objects" (one blob shared, but a tree per directory) earns 2 of 5; "8 objects" earns 0.

**Reference.** Chapter 2, sections 2.4 and 2.5.

### P2 (5 points)

<!-- snippet: gates/g1-predict/p2-answer -->
```text
$ git show --stat --format=%s HEAD
Raise the limit

 limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status --short
M  router.py
?? notes.txt
$ git diff --cached --stat
 router.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

`git commit <path>` commits the working-tree content of the named paths and nothing else. It bypasses what is staged: the staged change to `router.py` is not in the commit and is still staged afterwards. `notes.txt` was never tracked.

**Marking.** 2 points: the commit contains `limits.py` only. 2 points: `M  router.py` in the first column (staged), and `?? notes.txt`. 1 point: `git diff --cached --stat` lists `router.py`. The common wrong answer puts `router.py` into the commit ("it was staged, so it is committed") and earns at most 1.

**Reference.** Chapter 5, section 5.10.

### P3 (5 points)

<!-- snippet: gates/g1-predict/p3-answer-a -->
```text
$ git symbolic-ref HEAD
fatal: ref HEAD is not a symbolic ref
[exit status: 128]
$ git status -sb
## HEAD (no branch)
$ git log --oneline --all
f169bdc Try dynamic padding
156c87b Add truncation
e84b1f1 Add padding
ff9cb24 Add batcher
```
<!-- /snippet -->

<!-- snippet: gates/g1-predict/p3-answer-b -->
```text
$ git log --oneline --all
156c87b Add truncation
e84b1f1 Add padding
ff9cb24 Add batcher
$ git reflog -2
156c87b HEAD@{0}: checkout: moving from f169bdcfc1ccafc5f2a07ad4b6f569b0dc7197df to main
f169bdc HEAD@{1}: commit: Try dynamic padding
$ git cat-file -t 'HEAD@{1}'
commit
$ git branch --contains 'HEAD@{1}'
```
<!-- /snippet -->

While `HEAD` is detached it holds a commit ID, so it is not a symbolic ref (exit status 128). `git log --all` walks from all refs and from `HEAD`, which is why the detached commit is listed before the switch and missing after it. The commit object still exists, the `HEAD` reflog names it, and no branch contains it.

**Marking.** 1 point: the error and a non-zero status. 1 point: four commits before the switch, with "Try dynamic padding" first. 2 points: three commits after the switch. 1 point: `commit`, and an empty list of branches. A candidate who expects four commits after the switch has the wrong model of `--all` and earns at most 2.

**Reference.** Chapter 7, sections 7.3 and 7.7.

### P4 (5 points)

<!-- snippet: gates/g1-predict/p4-answer -->
```text
$ git log -1 --format='author    %ae%ncommitter %ce'
author    env@example.com
committer flag@example.com
$ git config get --show-scope --show-origin user.email
local	file:.git/config	local@example.com
$ git config get --all --show-scope user.email
global	global@example.com
local	local@example.com
```
<!-- /snippet -->

The author email comes from the environment, which beats every configuration value. No `GIT_COMMITTER_EMAIL` is set, so the committer email comes from configuration, where the command scope (`-c`) is read last and wins. `git config get` was run without `-c`, so it reports the local value; with `--all` it lists the values in reading order, global first, and the last line is the winner.

**Marking.** 2 points: author `env@example.com`. 1 point: committer `flag@example.com`. 1 point: `local` with `file:.git/config`. 1 point: two lines, global before local. "Both are flag@example.com" earns 2 of 5.

**Reference.** Chapter 6, section 6.5; Chapter 14B, section 14B.2.

---

## Part 3: Hands-on diagnosis

**End state (12 points).** Run `check.sh`. 12 points for `PASS`; otherwise 12 minus the number of `FAIL` lines, not below zero.

**Safety of the path (8 points).** Read the candidate's command log.

| Points | Evidence in the log |
|---|---|
| 2 | Read-only commands first: `git status`, `git log`, the three versions of the file, before any change |
| 2 | No `git reset --hard`, `git checkout -- .`, `git clean` or `git stash` used as a shortcut around uncommitted work that the report says must survive |
| 2 | History rewritten only where the task demands it (one amend of an unpublished commit), and the candidate said why an amend is acceptable here: nothing is published |
| 2 | Each state-changing command annotated with what it changes |

**Explanation (10 points).** Three root causes, 3 points each, and 1 point for prevention that addresses a cause and not a symptom. For each cause: 1 point for the Git state, 1 for the mechanism, 1 for a root cause that names the mistaken belief or the command.

### Variant A (`tokmeter`): model solution

Evidence first. The short status already shows two of the three problems: `MM` means the index differs from `HEAD` and the working tree differs from the index.

<!-- snippet: gates/solve-g1-a/01-observe -->
```text
$ cd tokmeter
$ git status -sb
## main
MM rates.yaml
 M reports/last-run.json
$ git log --oneline
1e6bc72 Update rate table for September
f436478 Add command-line entry point
7b94706 Ignore generated reports
a8ee2ed Add token counter and rate table
```
<!-- /snippet -->

<!-- snippet: gates/solve-g1-a/02-three-trees -->
```text
# rates.yaml in the last commit, in the index, in the working tree
$ git show HEAD:rates.yaml
input_per_1k: 0.40
output_per_1k: 1.50
$ git show :rates.yaml
input_per_1k: 0.40
output_per_1k: 1.20
$ cat rates.yaml
input_per_1k: 0.40
output_per_1k: 1.20
cached_input_per_1k: 0.10
$ git diff --cached --stat
 rates.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --stat
 rates.yaml            | 1 +
 reports/last-run.json | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

**Root cause 1.** State: `HEAD` has output 1.50, the index has 1.20, the working tree has a third line. Mechanism: `git add` copies the content of that moment into a blob and `git commit` writes the index. Asha staged after the first edit, edited again and committed without staging again, so the commit holds the first edit only. Root cause: the belief that `git add` marks a file. The repository has no remote, so the commit is unpublished and an amend is the correct repair: it replaces the commit with one that has the same parent, author and message.

<!-- snippet: gates/solve-g1-a/03-amend -->
```text
$ git add rates.yaml
$ git commit --amend --no-edit
[main 5067c29] Update rate table for September
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 3 insertions(+), 2 deletions(-)
$ git log -2 --format='%h %an | %s'
5067c29 Asha Rao | Update rate table for September
f436478 Asha Rao | Add command-line entry point
$ git show HEAD:rates.yaml
input_per_1k: 0.40
output_per_1k: 1.20
cached_input_per_1k: 0.10
```
<!-- /snippet -->

**Root cause 2.** State: the index has an entry for `reports/last-run.json`; the ignore rule was added one commit after the file. Mechanism: ignore rules decide only whether an untracked file is listed and added. They are not consulted for a path that has an index entry, which is why `git check-ignore -v` prints nothing until `--no-index` is given. Fix: remove the index entry and keep the file, then commit.

<!-- snippet: gates/solve-g1-a/04-ignored-but-tracked -->
```text
$ git check-ignore -v reports/last-run.json
$ git check-ignore -v --no-index reports/last-run.json
.gitignore:1:reports/	reports/last-run.json
$ git ls-files -s reports
100644 8f449f44015909fb21424b434109ae86b6ea386e 0	reports/last-run.json
$ git log --oneline --diff-filter=A -- reports/last-run.json .gitignore
7b94706 Ignore generated reports
a8ee2ed Add token counter and rate table
```
<!-- /snippet -->

<!-- snippet: gates/solve-g1-a/05-untrack -->
```text
$ git rm --cached reports/last-run.json
rm 'reports/last-run.json'
$ git status -sb
## main
D  reports/last-run.json
$ git commit -m "Stop tracking the generated report"
[main e31350a] Stop tracking the generated report
 1 file changed, 1 deletion(-)
 delete mode 100644 reports/last-run.json
$ cat reports/last-run.json
{"tokens": 18234}
$ git check-ignore -v reports/last-run.json
.gitignore:1:reports/	reports/last-run.json
```
<!-- /snippet -->

The candidate should add the consequence: on every other clone, the pull that brings this commit deletes the file from the working tree.

**Root cause 3.** State: `tokmeter/cache.py` is untracked and not ignored (`git check-ignore` exits with 1). The local configuration sets `status.showUntrackedFiles=no`. Mechanism: with that setting `git status` does not list untracked files at all. Root cause: a setting copied into the repository's configuration; the file was never ignored.

<!-- snippet: gates/solve-g1-a/06-hidden-untracked -->
```text
$ git check-ignore -v tokmeter/cache.py
[exit status: 1]
$ git status -sb --untracked-files=all
## main
?? tokmeter/cache.py
$ git config get --show-scope --show-origin status.showUntrackedFiles
local	file:.git/config	no
```
<!-- /snippet -->

<!-- snippet: gates/solve-g1-a/07-fix-setting -->
```text
$ git config unset status.showUntrackedFiles
$ git status -sb
## main
?? tokmeter/cache.py
$ git add tokmeter/cache.py
$ git commit -m "Add a cache for token counts"
[main 14b0e6e] Add a cache for token counts
 1 file changed, 7 insertions(+)
 create mode 100644 tokmeter/cache.py
$ git status -sb
## main
$ git log --oneline
14b0e6e Add a cache for token counts
e31350a Stop tracking the generated report
5067c29 Update rate table for September
f436478 Add command-line entry point
7b94706 Ignore generated reports
a8ee2ed Add token counter and rate table
$ cd ..
$ assessments/gen/gate-1-fundamentals/variant-a/check.sh
Checking g1-a
  ok    HEAD is on main
  ok    exactly one commit is called "Update rate table for September"
  ok    its parent is the commit it had before
  ok    it is still authored by Asha
  ok    it contains the rate table with all three rates
  ok    rates.yaml on disk has all three rates
  ok    reports/last-run.json is not in the last commit
  ok    reports/last-run.json is still on disk with the result of the last run
  ok    reports/last-run.json is ignored now
  ok    tokmeter/cache.py is in the last commit
  ok    no setting hides untracked files from git status
  ok    nothing is staged, modified or untracked
PASS: the end state of g1-a is right.
[exit status: 0]
```
<!-- /snippet -->

**Partial credit and common mistakes, variant A.**

- A new commit "Fix rate table" in place of the amend: the end state fails two lines. Acceptable reasoning in a published history, wrong here, where the task states the commit must contain the rates.
- `git commit --amend -a` or `git add -A` before the amend: puts the report (and, once visible, the cache module) into the rate commit. `check.sh` still passes if they are cleaned up afterwards; deduct 1 safety point for a commit that mixes unrelated changes.
- `git rm reports/last-run.json` without `--cached`: deletes Asha's file. The end state fails one line; deduct 2 safety points.
- Adding `!tokmeter/cache.py` to `.gitignore`, or `git add -f`, to "un-ignore" the module: treats a symptom. The check for the setting fails, and the explanation earns no points for cause 3.
- Reasons that earn no explanation points: "Git did not see the change", "`.gitignore` is broken", "the file is ignored".

**Reference.** Chapter 5, sections 5.3 and 5.4; Chapter 6, section 6.7; Chapter 4, sections 4.4 and 4.6; Chapter 14B, section 14B.3.

### Variant B (`shardmap`): model solution

<!-- snippet: gates/solve-g1-b/01-observe -->
```text
$ cd shardmap
$ git status -sb
## main
?? shardmap/hashing.py
$ git log --oneline
2a3492b Add shard weights
396a107 Add README
604f1b3 Add rebalance script
d6597b8 Add hash ring
$ git show --stat --format=%s HEAD
Add shard weights

 shardmap/hashing.py | 4 ----
 shardmap/weights.py | 1 +
 2 files changed, 1 insertion(+), 4 deletions(-)
```
<!-- /snippet -->

**Root cause 3 first, because it distorts every later command that names `main`.** State: a file `.git/main` holds the ID of the first commit; `refs/heads/main` is intact. Mechanism: `git update-ref main <id>` writes exactly the ref it is given, and name lookup tries `<name>` at the top of `.git` before `refs/heads/<name>`. Root cause: a plumbing command received a short name where it needs `refs/heads/main`. `git for-each-ref` lists only `refs/`, so it does not show the stray ref, and the reflog has no entry for it.

<!-- snippet: gates/solve-g1-b/02-ambiguous -->
```text
$ git log --oneline main
warning: refname 'main' is ambiguous.
d6597b8 Add hash ring
$ git rev-parse main refs/heads/main HEAD
warning: refname 'main' is ambiguous.
d6597b81abd0d7f80e7e71c7b162c8cd2c3bfce2
2a3492b93fa2ffb5dba1f1555b648af7692e7a9c
2a3492b93fa2ffb5dba1f1555b648af7692e7a9c
$ git for-each-ref
2a3492b93fa2ffb5dba1f1555b648af7692e7a9c commit	refs/heads/main
$ cat .git/main
d6597b81abd0d7f80e7e71c7b162c8cd2c3bfce2
$ git reflog -3
2a3492b HEAD@{0}: commit: Add shard weights
396a107 HEAD@{1}: commit: Add README
604f1b3 HEAD@{2}: commit: Add rebalance script
```
<!-- /snippet -->

`git update-ref -d main` is refused: deletion accepts only names under `refs/` and names in capitals. After confirming what the file holds, delete the file.

<!-- snippet: gates/solve-g1-b/03-fix-name -->
```text
$ git update-ref -d main
error: refusing to update ref with bad name 'main'
[exit status: 1]
# Deletion accepts only names under refs/ and names in capitals. The stray ref is one file.
$ rm .git/main
$ git rev-parse main refs/heads/main
2a3492b93fa2ffb5dba1f1555b648af7692e7a9c
2a3492b93fa2ffb5dba1f1555b648af7692e7a9c
$ git status -sb
## main
?? shardmap/hashing.py
```
<!-- /snippet -->

**Root cause 1.** State: the path `shardmap/hashing.py` is in `HEAD~1` and not in `HEAD`; on disk it is untracked. Mechanism: `git rm --cached` removes the index entry. A path that `HEAD` has and the index lacks is a deletion in the next commit. Root cause: `git rm --cached` was used to unstage; it stops tracking. The repair puts the committed blob back into the index without touching the working tree and amends, which is acceptable because nothing is published.

<!-- snippet: gates/solve-g1-b/04-deleted-file -->
```text
$ git ls-files -s shardmap
100644 cdc5d94ed799b8e618e775c0610e81f6967dac0c 0	shardmap/ring.py
100644 c4de3e3b613379dadeaafb8950e8e6b47a76d533 0	shardmap/weights.py
$ git ls-tree -r --name-only HEAD~1 shardmap
shardmap/hashing.py
shardmap/ring.py
$ git restore --staged --source=HEAD~1 shardmap/hashing.py
$ git status -sb
## main
AM shardmap/hashing.py
$ git commit --amend --no-edit
[main d6aad25] Add shard weights
 Date: Mon Sep 7 10:09:00 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 shardmap/weights.py
$ git show --stat --format=%s HEAD
Add shard weights

 shardmap/weights.py | 1 +
 1 file changed, 1 insertion(+)
$ git status -sb
## main
 M shardmap/hashing.py
$ git diff --stat
 shardmap/hashing.py | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

**Root cause 2.** State: the index entry of the script has mode `100644`, the file on disk is executable, and the local configuration has `core.fileMode=false`. Mechanism: with that setting Git does not compare the executable bit on disk with the index, so the change is invisible to `git status` and to `git add`. Root cause: a setting meant for file systems that cannot store the bit, set in a repository on a file system that can.

<!-- snippet: gates/solve-g1-b/05-mode -->
```text
$ git config get --show-scope --show-origin core.fileMode
local	file:.git/config	false
$ git ls-files -s scripts
100644 08f5966ccb33ad86a857c7099a85c92248459ef2 0	scripts/rebalance.sh
$ git -c core.fileMode=true status -sb
## main
 M scripts/rebalance.sh
 M shardmap/hashing.py
$ git -c core.fileMode=true diff scripts
diff --git a/scripts/rebalance.sh b/scripts/rebalance.sh
old mode 100644
new mode 100755
```
<!-- /snippet -->

<!-- snippet: gates/solve-g1-b/06-fix-mode -->
```text
$ git config unset core.fileMode
$ git add scripts/rebalance.sh
$ git commit -m "Make the rebalance script executable"
[main 01e62c0] Make the rebalance script executable
 1 file changed, 0 insertions(+), 0 deletions(-)
 mode change 100644 => 100755 scripts/rebalance.sh
$ git ls-tree HEAD scripts/
100755 blob 08f5966ccb33ad86a857c7099a85c92248459ef2	scripts/rebalance.sh
$ git status -sb
## main
 M shardmap/hashing.py
$ git log --oneline
01e62c0 Make the rebalance script executable
d6aad25 Add shard weights
396a107 Add README
604f1b3 Add rebalance script
d6597b8 Add hash ring
$ cd ..
$ assessments/gen/gate-1-fundamentals/variant-b/check.sh
Checking g1-b
  ok    HEAD is on main
  ok    exactly one commit is called "Add shard weights"
  ok    its parent is the commit it had before
  ok    it is still authored by Ravi
  ok    it contains shardmap/hashing.py as it was committed before
  ok    it contains shardmap/weights.py
  ok    the half-done edit of shardmap/hashing.py is still in the working tree
  ok    the half-done edit is not committed
  ok    scripts/rebalance.sh is executable in the last commit
  ok    the name "main" is not ambiguous
  ok    the name "main" resolves to the branch
  ok    the half-done edit is the only change that git status reports
PASS: the end state of g1-b is right.
[exit status: 0]
```
<!-- /snippet -->

`git update-index --chmod=+x scripts/rebalance.sh` or `git add --chmod=+x` followed by a commit is an equally correct repair of the commit and passes the check; the candidate should then say that the setting is still wrong and will hide the next mode change.

**Partial credit and common mistakes, variant B.**

- `git reset --hard HEAD~1` to "redo the commit": destroys the experiment, which exists in no object. The end state fails; 0 for safety.
- `git add shardmap/hashing.py` before the amend: commits the experiment. Two lines of the check fail.
- `git branch -f main <id>` or `git reset` to repair "main": moves the real branch and leaves the stray ref. Deduct 2 safety points even if it is undone.
- Editing `.git/main` without first reading it and comparing it with `refs/heads/main`: correct result, 1 safety point deducted for no evidence.

**Reference.** Chapter 5, section 5.9 (root-cause box); Chapter 4, section 4.10; Chapter 2, section 2.13 (root-cause box); Chapter 6, section 6.7.

---

## Part 4: Oral interview

Mark each answer on four things: is it correct, does it name the mechanism, is the vocabulary exact, and does the follow-up hold. O1 to O4: 3 points for a complete answer with the follow-up, 2 for a correct answer with a weak follow-up, 1 for a definition without mechanism. O5 and O6: 4, 3, 2 or 1 on the same scale, the fourth point for the production consequence.

### O1 (3 points)

**Model answer.** A branch is a ref under `refs/heads/` that holds the ID of one commit. It is a movable name, one small file in the default files format, and it contains no commits. *Follow-up:* "the branch contains a commit" is a statement about reachability: the commit can be reached from the branch's commit by following parent links. That is why deleting a branch deletes a name and not history, and why one commit can be "on" many branches.

**Weak answer.** "A copy of the code", "a line of development", "a series of commits". **Reference.** Chapter 7, section 7.2; Chapter 2, section 2.7.

### O2 (3 points)

**Model answer.** `HEAD` is the ref that says what is checked out and what the next commit's parent will be. It is the file `.git/HEAD`. *Follow-up:* normally it is a symbolic ref, the text `ref: refs/heads/main`; a commit then moves the branch `main`, and `HEAD` follows because it names the branch. Detached, it holds a commit ID; a commit then rewrites `HEAD` itself and no branch moves.

**Weak answer.** "The latest commit", "the tip of main". **Reference.** Chapter 7, sections 7.3 and 7.7.

### O3 (3 points)

**Model answer.** The commit ID is the hash of the commit object, and the message is part of that object, as are the tree, the parents, the author and the committer. Any change to any of them is a different object with a different ID. *Follow-up:* each later commit names its parent by ID. A new parent ID changes the child object, so every descendant gets a new ID as well, although no tree changed.

**Weak answer.** "Because Git tracks changes to messages." **Reference.** Chapter 6, sections 6.4 and 6.7.

### O4 (3 points)

**Model answer.** Ignore rules apply to untracked files only. The file has an index entry, so Git compares it with the index like any tracked file. The fix is `git rm --cached <path>` and a commit; the file stays on disk and is ignored from then on. *Follow-up:* the commit records a deletion. On the teammate's machine the pull that brings it removes the file from their working tree, so warn them, or have them keep a copy.

**Weak answer.** "Clear the Git cache" with no idea what the command does to the index and to others. **Reference.** Chapter 4, section 4.6.

### O5 (4 points)

**Model answer.** The version at the time of `git add`. That command wrote a blob into the object database at once and put its ID into the index; the commit wrote the index. The second edit is only in the working tree. *Follow-up:* yes. The blob was written by `git add` and unstaging removes only the index entry. The object stays in `.git/objects`, unreachable, until garbage collection removes it. It was never in a commit, so it is not pushed, but it is on that disk and `git fsck` can list it. If the password was real, rotate it.

**Weak answer.** "The latest version, Git commits the file." "No, it was never committed." **Reference.** Chapter 5, section 5.3; Chapter 2, section 2.14.

### O6 (4 points)

**Model answer.** Compare the effective configuration on both machines: `git config list --show-scope --show-origin` in the repository, and diff the two listings. Then the environment (`env | grep '^GIT_'`), `git --version` and `which git`, because two Git installations can be on one machine. *Follow-up:* the system file, a file pulled in by `include.path` or `includeIf`, the worktree file, the command scope (`-c`, `GIT_CONFIG_COUNT` variables set by a wrapper script or an alias), or an environment variable that overrides the setting. `--show-origin` names the file for every configuration case.

**Weak answer.** "Reinstall Git", "clone again". **Reference.** Chapter 14B, sections 14B.2, 14B.3 and 14B.7; Chapter 1, section 1.6.
