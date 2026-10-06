# Module 35 labs: The diagnosis method

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch29/`. Read [Chapter 29: Production Troubleshooting](../textbook/ch29-production-troubleshooting.md) first, and keep the [troubleshooting playbook](../playbooks/troubleshooting-playbook.md) open.

## How to run these labs

Each lab has a setup script that builds prepared repositories in the hands-on sandbox, and a replay script that runs the whole lab with a fixed clock and produced the transcripts below. From the course root:

```bash
bash labs/ch29/setup-35-1-three-repositories.sh    # build the starting state (run again to start over)
labs/shell m35-1                                   # open the isolated lab shell in that sandbox
labs/run ch29/lab-35-1-three-repositories          # optional: replay the whole lab and print its transcript
```

The setup scripts use the fixed lab clock, so the commits they create have the IDs printed here. Commits you make by hand in the lab shell get the real time and therefore other IDs. Paths printed as `$LAB/...` are below your lab root.

These labs train one habit: **write down the state before you read the explanation.** Each lab tells you where to stop and write. The explanation under "What happened internally" is worth reading only after that.

## Lab 35.1: The ten-command diagnosis on three repositories

### Objective

Run the ten-command diagnosis on three repositories you have never seen, each with a symptom card. For each one, write the state table, three hypotheses and the root-cause box from the evidence alone, without running a single state-changing command.

### Prerequisites

- Chapter 29, sections 29.2 to 29.5.
- Chapter 1, sections 1.10 and 1.11.

### Setup

```bash
bash labs/ch29/setup-35-1-three-repositories.sh
labs/shell m35-1
```

The script builds three repositories, `annotator`, `batch-infer` and `prompt-router`, two bare repositories that play their servers, and one symptom card per repository (`<name>.SYMPTOM.txt`).

### Commands

For each repository, in this order: read the card, enter the directory, type the eleven lines, then stop and write.

```bash
cat annotator.SYMPTOM.txt
cd annotator
git status
git branch -vv
git remote -v
git log --graph --decorate --oneline --all
git reflog
git rev-parse HEAD
git rev-parse --abbrev-ref HEAD
git show --stat HEAD
git diff
git diff --cached
git config list --show-origin --show-scope
git ls-files
```

**Stop and write**, on paper or in a file outside the repository:

1. The state table of the playbook, section 2: working tree, index, HEAD, current branch, other refs, reflog, server.
2. At least three hypotheses, each with the command that would confirm or reject it.
3. Only then run those commands. They must be read-only; `git fetch` is allowed.
4. The seven-line root-cause box and the lowest-risk fix. Do not execute the fix.

Then `cd ..` and repeat for `batch-infer` and `prompt-router`. Do all three before you read on.

### Expected output

The replay prints the cards, a condensed version of the eleven lines, and the commands that test the hypotheses. Compare it with your notes after you have written them.

**Repository 1: `annotator`.**

<!-- snippet: ch29/lab-35-1-three-repositories/01-a-symptom -->
```text
$ cat annotator.SYMPTOM.txt
Reported by the developer:
"I made two commits this morning. git log on main does not show them,
and a change to export.py that I was working on last week is gone too."
$ cd annotator
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-1-three-repositories/02-a-state -->
```text
$ git status
HEAD detached from v0.2.0
nothing to commit, working tree clean
$ git branch -vv
* (HEAD detached from v0.2.0) 720369a Add kappa stub
  main                        b7b08aa Add partially_relevant label
$ git remote -v
$ git log --graph --decorate --oneline --all
* 720369a (HEAD) Add kappa stub
* 0bd9dc1 Add inter-annotator agreement
| *   84580f0 (refs/stash) On main: export only finished rows
| |\  
| | * d791760 index on main: b7b08aa Add partially_relevant label
| |/  
| * b7b08aa (main) Add partially_relevant label
|/  
* e6d7ef1 (tag: v0.2.0) Add JSON export
* c2d2166 Add label set
$ git reflog
720369a HEAD@{0}: commit: Add kappa stub
0bd9dc1 HEAD@{1}: commit: Add inter-annotator agreement
e6d7ef1 HEAD@{2}: checkout: moving from main to v0.2.0
b7b08aa HEAD@{3}: reset: moving to HEAD
b7b08aa HEAD@{4}: commit: Add partially_relevant label
e6d7ef1 HEAD@{5}: commit: Add JSON export
c2d2166 HEAD@{6}: commit (initial): Add label set
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-1-three-repositories/03-a-details -->
```text
$ git rev-parse HEAD main
720369a5760827058faae373012ae92f6d2cfc97
b7b08aa0783cd61110d6b722e6fd9ca93f9411d2
$ git rev-parse --abbrev-ref HEAD
HEAD
$ git show --stat HEAD
commit 720369a5760827058faae373012ae92f6d2cfc97
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:10:00 2026 +0530

    Add kappa stub

 agreement.py | 2 ++
 1 file changed, 2 insertions(+)
$ git diff
$ git diff --cached
$ git config list --show-scope | grep -E "user[.]|remote[.]|branch[.]"
global	user.name=Lab User
global	user.email=you@example.com
$ git ls-files
agreement.py
export.py
labels.py
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-1-three-repositories/04-a-test -->
```text
$ git log --oneline main..HEAD
720369a Add kappa stub
0bd9dc1 Add inter-annotator agreement
$ git branch -a --contains HEAD
* (HEAD detached from v0.2.0)
$ git stash list
stash@{0}: On main: export only finished rows
$ git stash show -p stash@{0}
diff --git a/export.py b/export.py
index 1762acd..316cf26 100644
--- a/export.py
+++ b/export.py
@@ -1,2 +1,2 @@
 def export(rows):
-    return [r.to_json() for r in rows]
+    return [r.to_json() for r in rows if r.done]
```
<!-- /snippet -->

**Repository 2: `batch-infer`.**

<!-- snippet: ch29/lab-35-1-three-repositories/05-b-symptom -->
```text
$ cd ..
$ cat batch-infer.SYMPTOM.txt
Reported by the developer:
"git push is rejected. Also .env shows as modified every day,
although it is in .gitignore."
$ cd batch-infer
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-1-three-repositories/06-b-state -->
```text
$ git status
On branch main
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   chunks.py

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   .env

$ git branch -vv
* main 58a42a9 [origin/main: ahead 1] Add chunk helper
$ git remote -v
origin	../batch-server.git (fetch)
origin	../batch-server.git (push)
$ git log --graph --decorate --oneline --all
* 58a42a9 (HEAD -> main) Add chunk helper
* 0880c4c (origin/main, origin/HEAD) Add batch inference job
$ git reflog
58a42a9 HEAD@{0}: commit: Add chunk helper
0880c4c HEAD@{1}: clone: from $LAB/ch29/lab-35-1-three-repositories/batch-server.git
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-1-three-repositories/07-b-details -->
```text
$ git rev-parse HEAD origin/main
58a42a967765504d336ae05936e0dd3be86d783e
0880c4cf658a93cf6e40c77d622e28b3036f0247
$ git show --stat HEAD
commit 58a42a967765504d336ae05936e0dd3be86d783e
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:23:00 2026 +0530

    Add chunk helper

 chunks.py | 3 +++
 1 file changed, 3 insertions(+)
$ git diff
diff --git a/.env b/.env
index 93af99d..2947152 100644
--- a/.env
+++ b/.env
@@ -1 +1 @@
-MODEL_ENDPOINT=http://localhost:8080
+MODEL_ENDPOINT=http://10.0.4.17:8080
$ git diff --cached
diff --git a/chunks.py b/chunks.py
index d4252f9..7d7bf1e 100644
--- a/chunks.py
+++ b/chunks.py
@@ -1,3 +1,4 @@
 def chunks(seq, n):
+    """Yield lists of at most n items."""
     for i in range(0, len(seq), n):
         yield seq[i:i + n]
$ git ls-files
.env
.gitignore
chunks.py
infer.py
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-1-three-repositories/08-b-test -->
```text
# What does the server have now? Two questions that change nothing locally, then a fetch,
# which moves only remote-tracking refs.
$ git ls-remote origin main
92aea830efa6f6d02da94f7347d08a2eee842735	refs/heads/main
$ git fetch
From ../batch-server
   0880c4c..92aea83  main       -> origin/main
$ git status -sb
## main...origin/main [ahead 1, behind 2]
 M .env
M  chunks.py
$ git log --oneline --left-right HEAD...origin/main
< 58a42a9 Add chunk helper
> 92aea83 List retryable errors
> d11fb5f Add retries parameter
# Why is an ignored file reported as modified?
$ cat .gitignore
.env
__pycache__/
$ git ls-files .env
.env
$ git check-ignore -v .env
[exit status: 1]
$ git check-ignore -v --no-index .env
.gitignore:1:.env	.env
$ git log --oneline -- .env
0880c4c Add batch inference job
```
<!-- /snippet -->

**Repository 3: `prompt-router`.**

<!-- snippet: ch29/lab-35-1-three-repositories/09-c-symptom -->
```text
$ cd ..
$ cat prompt-router.SYMPTOM.txt
Reported by the developer:
"CI on my branch fails with ModuleNotFoundError: router.cache_keys.
The file is on my machine and git status says the working tree is clean.
Also my commit is not linked to my account on GitHub."
$ cd prompt-router
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-1-three-repositories/10-c-state -->
```text
$ git status
On branch feature/router-cache
nothing to commit, working tree clean
$ git branch -vv
* feature/router-cache 332e5c5 Cache routing decisions
  main                 b68bb4c [origin/main] Add prompt routes
$ git remote -v
origin	../router-server.git (fetch)
origin	../router-server.git (push)
$ git log --graph --decorate --oneline --all
* 332e5c5 (HEAD -> feature/router-cache, origin/feature/router-cache) Cache routing decisions
* b68bb4c (origin/main, origin/HEAD, main) Add prompt routes
$ git reflog
332e5c5 HEAD@{0}: commit: Cache routing decisions
b68bb4c HEAD@{1}: checkout: moving from main to feature/router-cache
b68bb4c HEAD@{2}: clone: from $LAB/ch29/lab-35-1-three-repositories/router-server.git
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-1-three-repositories/11-c-details -->
```text
$ git rev-parse HEAD origin/feature/router-cache
332e5c5e86e837dd5447bd45d6a23544a022c5ac
332e5c5e86e837dd5447bd45d6a23544a022c5ac
$ git show --stat HEAD
commit 332e5c5e86e837dd5447bd45d6a23544a022c5ac
Author: Lab User <lab.user@personal.example>
Date:   Mon Sep 7 10:33:00 2026 +0530

    Cache routing decisions

 router/cache.py | 6 ++++++
 1 file changed, 6 insertions(+)
$ git diff
$ git diff --cached
$ git config list --show-origin --show-scope | grep -E "user[.]"
global	file:$LAB/ch29/lab-35-1-three-repositories/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch29/lab-35-1-three-repositories/home/.gitconfig	user.email=you@example.com
local	file:.git/config	user.email=lab.user@personal.example
$ git ls-files
router/cache.py
router/routes.py
$ ls router
cache_keys.py
cache.py
routes.py
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-1-three-repositories/12-c-test -->
```text
$ git status --ignored
On branch feature/router-cache
Ignored files:
  (use "git add -f <file>..." to include in what will be committed)
	router/cache_keys.py

nothing to commit, working tree clean
$ git check-ignore -v router/cache_keys.py
.git/info/exclude:7:*_keys.py	router/cache_keys.py
$ git ls-tree -r --name-only origin/feature/router-cache
router/cache.py
router/routes.py
$ git config get --show-origin --show-scope --all user.email
global	file:$LAB/ch29/lab-35-1-three-repositories/home/.gitconfig	you@example.com
local	file:.git/config	lab.user@personal.example
$ git log -1 --format='%an <%ae>'
Lab User <lab.user@personal.example>
```
<!-- /snippet -->

### What happened internally

**`annotator`.** Two findings, both visible in the first five commands.

- `git status` begins with `HEAD detached from v0.2.0`. The reflog shows why: `checkout: moving from main to v0.2.0`, then two `commit` entries. Checking out a tag detaches HEAD, and commits made there advance HEAD and no branch ([Chapter 7](../textbook/ch07-branches.md), section 7.7). `git log main..HEAD` lists the two commits; `git branch -a --contains HEAD` lists no branch. "From" instead of "at" in the status line means HEAD has moved since the checkout.
- `git log --all` shows `refs/stash`, and the reflog has `reset: moving to HEAD`, which is what `git stash push` leaves behind. `git stash show -p` prints the "lost" change to `export.py`. A stash belongs to the repository, not to a branch, and nothing reminds you of it ([Chapter 11](../textbook/ch11-reset-revert-restore.md), section 11.11).
- `git remote -v` prints nothing: there is no server, so nothing is backed up anywhere.
- Lowest-risk fix: `git branch feature/agreement HEAD` 🟢. One new ref; nothing else moves. The stash is applied later on the branch it belongs to.

**`batch-infer`.** Three findings.

- `git status` says "ahead of 'origin/main' by 1 commit" and nothing about "behind". That is the state at the last fetch. `git ls-remote origin main` prints an ID that is not `origin/main`; after `git fetch`, `git status -sb` says `[ahead 1, behind 2]`. The push is rejected because the server's branch has two commits this clone lacks ([Chapter 12](../textbook/ch12-remote-operations.md), section 12.7).
- `.env` is listed by `git ls-files`: it is tracked. `git check-ignore -v .env` prints nothing and exits with 1, because ignore rules are not consulted for tracked files; with `--no-index` it shows the rule `.gitignore:1`. The file was committed in the first commit, forced past the rule. An ignore rule never stops tracking ([Chapter 4](../textbook/ch04-working-tree.md), section 4.6).
- `git diff --cached` shows a staged docstring that is in no commit.
- Lowest-risk fix for the push: commit or stash the local changes, then `git pull --rebase` (the one local commit is unpublished) or `git merge origin/main`, then push. For `.env`: `git rm --cached .env` and a commit, after warning the team that their next pull deletes their copy of the file. If the endpoint in it is sensitive, treat it as a leaked secret: it stays in history.

**`prompt-router`.** Three findings.

- `git status` is clean and `ls router` shows `cache_keys.py`, which `git ls-files` does not. `git status --ignored` lists it, and `git check-ignore -v` names the rule: `.git/info/exclude`, line 7, `*_keys.py`. That file is a per-clone ignore list that is never committed, so no colleague and no CI job has the rule or can see it in the repository ([Chapter 4](../textbook/ch04-working-tree.md), section 4.5). The commit imports a module that was never committed; `git ls-tree -r origin/feature/router-cache` confirms that the server's tree lacks it.
- `git branch -vv` shows no brackets for `feature/router-cache`: no upstream. That is why `git status` has no "up to date" line. A clean status without that line says nothing about the server.
- `git show` prints the author address `lab.user@personal.example`. `git config get --show-origin --show-scope --all user.email` shows two values, and the local one wins ([Chapter 14B](../textbook/ch14b-config-tags-signing.md), section 14B.2). GitHub links commits to accounts by address ([Chapter 6](../textbook/ch06-commits.md), section 6.11).
- Lowest-risk fix: `git add -f router/cache_keys.py` and a new commit; narrow or remove the exclude rule; correct `user.email` for future commits. Whether to rewrite the author of the pushed commit is a separate decision with a risk label of its own.

### Checkpoint

- You have three written root-cause boxes, each naming the layer (all three are Git).
- For `annotator` you named both findings before running `git stash list`.
- For `batch-infer` you can say which output proved that `git status` was stale.
- In none of the three repositories did the reflog gain an entry: `git reflog -1` prints the same line as before you started.

### Failure scenario

The reflex that this lab trains you out of: acting before diagnosing. In `annotator`, "go back to main and look":

```bash
cd ../annotator
git switch main
git log --graph --decorate --oneline --all
git branch -a --contains 720369a
```

<!-- snippet: ch29/lab-35-1-three-repositories/13-failure -->
```text
$ cd ../annotator
# The reflex: "let me go back to main and look".
$ git switch main
Warning: you are leaving 2 commits behind, not connected to
any of your branches:

  720369a Add kappa stub
  0bd9dc1 Add inter-annotator agreement

If you want to keep them by creating a new branch, this may be a good time
to do so with:

 git branch <new-branch-name> 720369a

Switched to branch 'main'
$ git log --graph --decorate --oneline --all
*   84580f0 (refs/stash) On main: export only finished rows
|\  
| * d791760 index on main: b7b08aa Add partially_relevant label
|/  
* b7b08aa (HEAD -> main) Add partially_relevant label
* e6d7ef1 (tag: v0.2.0) Add JSON export
* c2d2166 Add label set
$ git branch -a --contains 720369a
```
<!-- /snippet -->

Git prints a warning with the two commits and the ID of the tip, and then does what it was told. `git log --all` no longer shows the commits, and no branch contains `720369a`. The warning is the last time Git volunteers that ID. A developer who clears the terminal now has "lost" two commits.

### Recovery

The HEAD reflog still has them. The entry below the `checkout` is the last position on the detached HEAD:

```bash
git reflog -3
git branch feature/agreement 'HEAD@{1}'
git log --graph --decorate --oneline --all
```

<!-- snippet: ch29/lab-35-1-three-repositories/14-recovery -->
```text
$ git reflog -3
b7b08aa HEAD@{0}: checkout: moving from 720369a5760827058faae373012ae92f6d2cfc97 to main
720369a HEAD@{1}: commit: Add kappa stub
0bd9dc1 HEAD@{2}: commit: Add inter-annotator agreement
$ git branch feature/agreement 'HEAD@{1}'
$ git log --graph --decorate --oneline --all
* 720369a (feature/agreement) Add kappa stub
* 0bd9dc1 Add inter-annotator agreement
| *   84580f0 (refs/stash) On main: export only finished rows
| |\  
| | * d791760 index on main: b7b08aa Add partially_relevant label
| |/  
| * b7b08aa (HEAD -> main) Add partially_relevant label
|/  
* e6d7ef1 (tag: v0.2.0) Add JSON export
* c2d2166 Add label set
```
<!-- /snippet -->

### Verification

```bash
git branch --contains feature/agreement
git log --oneline main..feature/agreement
git fsck --no-reflogs
```

<!-- snippet: ch29/lab-35-1-three-repositories/15-verification -->
```text
$ git branch --contains feature/agreement
  feature/agreement
$ git log --oneline main..feature/agreement
720369a Add kappa stub
0bd9dc1 Add inter-annotator agreement
$ git fsck --no-reflogs
```
<!-- /snippet -->

The two commits are on a branch, and `git fsck --no-reflogs` prints nothing: no commit depends on a reflog to stay alive.

### Questions

1. In `annotator`, which single line of which output first told you that the commits were not on `main`? Which later output only confirmed it?
2. `git status` in `batch-infer` said "ahead 1" before the fetch and "ahead 1, behind 2" after it. Which ref changed, and which did not?
3. Why does `git check-ignore -v .env` print nothing in `batch-infer` and print a rule for `router/cache_keys.py` in `prompt-router`?
4. In `prompt-router`, `git status` reported a clean working tree. Name two things that a clean status does not tell you, with the command that does.
5. The failure scenario "lost" two commits with a 🟢 command, `git switch`. In what sense is the command safe, and what made the situation unsafe?
6. For each repository, which of the ten commands could you have skipped without missing a finding? What does that say about skipping commands?

## Lab 35.2: Five operations in progress, read from `.git` alone

### Objective

Identify five interrupted operations from the files in `.git`, without `git status`: which operation, on which branch, applying which commit, with what remaining, and where an abort would return to. Then use `git status` only to check your answers.

### Prerequisites

- Chapter 29, section 29.6.
- Chapter 3, section 3.10 (root refs, pseudorefs and the state of an operation).

### Setup

```bash
bash labs/ch29/setup-35-2-five-states.sh
labs/shell m35-2
```

The script builds five repositories, `case-1` to `case-5`. All have the same history. Each was stopped in the middle of a different operation: a merge, a rebase, a cherry-pick, a revert and a bisect. The directory names do not say which.

### Commands

Step 1. Survey. For every case, print HEAD and the state files:

```bash
for d in case-1 case-2 case-3 case-4 case-5; do echo "== $d"; cat $d/.git/HEAD; ls $d/.git | grep -E "_HEAD$|rebase-|sequencer|BISECT"; done
```

**Stop and write** the operation for each case, and whether HEAD is attached.

Step 2. For each case, read the state files that exist, with `cat` and `ls` only (use `git cat-file -p <id>` to look at a commit an ID names). Answer in writing: (a) which commit is being applied or undone; (b) which branch will be changed; (c) what remains to be done; (d) where the operation started.

```bash
cd case-1
cat .git/REVERT_HEAD
git cat-file -p $(cat .git/REVERT_HEAD) | tail -1
cat .git/MERGE_MSG

cd ../case-2
cat .git/BISECT_START
cat .git/BISECT_LOG
ls .git/refs/bisect

cd ../case-3
cat .git/MERGE_HEAD
git cat-file -p $(cat .git/MERGE_HEAD) | tail -1
cat .git/MERGE_MSG
cat .git/ORIG_HEAD

cd ../case-4
cat .git/CHERRY_PICK_HEAD
cat .git/sequencer/head
cat .git/sequencer/todo

cd ../case-5
cat .git/rebase-merge/head-name
cat .git/rebase-merge/onto .git/rebase-merge/orig-head
cat .git/rebase-merge/done
cat .git/rebase-merge/git-rebase-todo
cat .git/REBASE_HEAD
```

Step 3. Only now, in each case: `git status | head -2`.

### Expected output

<!-- snippet: ch29/lab-35-2-five-states/01-survey -->
```text
$ for d in case-1 case-2 case-3 case-4 case-5; do echo "== $d"; cat $d/.git/HEAD; ls $d/.git | grep -E "_HEAD$|rebase-|sequencer|BISECT"; done
== case-1
ref: refs/heads/feature/strict-guard
REVERT_HEAD
== case-2
b72524538276c07c843592891337df95fc8ad0e4
BISECT_ANCESTORS_OK
BISECT_EXPECTED_REV
BISECT_LOG
BISECT_NAMES
BISECT_START
BISECT_TERMS
== case-3
ref: refs/heads/main
MERGE_HEAD
ORIG_HEAD
== case-4
ref: refs/heads/main
CHERRY_PICK_HEAD
sequencer
== case-5
5c14f0f7980a7ba5446f53700a514eb9b1ffe8b7
ORIG_HEAD
REBASE_HEAD
rebase-merge
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-2-five-states/02-case-1 -->
```text
$ cd case-1
$ cat .git/REVERT_HEAD
5c28c34f60bd60053158c59857595ba81d27a249
$ git cat-file -p $(cat .git/REVERT_HEAD) | tail -1
Raise guard threshold to 0.80
$ cat .git/MERGE_MSG
Revert "Raise guard threshold to 0.80"

This reverts commit 5c28c34f60bd60053158c59857595ba81d27a249.

# Conflicts:
#	guard.yaml
$ git status | head -2
On branch feature/strict-guard
You are currently reverting commit 5c28c34.
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-2-five-states/03-case-2 -->
```text
$ cd ../case-2
$ cat .git/BISECT_START
feature/strict-guard
$ cat .git/BISECT_LOG
# bad: [0947fe75830e5937b3ba8f1489196498b15e01cb] Lower max_tokens to 128
# good: [ce24e430e4e9932d080b5023233ebe6e5de1adef] Add output guard
git bisect start 'HEAD' 'main~3'
# good: [2ef6f1e4499755333f3e0bfa5a24331b1554365f] Raise guard threshold to 0.80
git bisect good 2ef6f1e4499755333f3e0bfa5a24331b1554365f
$ ls .git/refs/bisect
bad
good-2ef6f1e4499755333f3e0bfa5a24331b1554365f
good-ce24e430e4e9932d080b5023233ebe6e5de1adef
$ git status | head -2
HEAD detached at b725245
You are currently bisecting, started from branch 'feature/strict-guard'.
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-2-five-states/04-case-3 -->
```text
$ cd ../case-3
$ cat .git/MERGE_HEAD
26d9af610934be99be7cdd43985bc5754cf1d527
$ git cat-file -p $(cat .git/MERGE_HEAD) | tail -1
Lower max_tokens to 128
$ cat .git/MERGE_MSG
Merge branch 'feature/strict-guard'

# Conflicts:
#	guard.yaml
$ cat .git/ORIG_HEAD
81f478cf449c7a1943ac8f22ee78c1271c705cd5
$ git status | head -2
On branch main
You have unmerged paths.
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-2-five-states/05-case-4 -->
```text
$ cd ../case-4
$ cat .git/CHERRY_PICK_HEAD
51c83989a70676a69bc4e49b5013c45867375220
$ cat .git/sequencer/head
ad1088156fac3ba85bac5d02c300998d318ad876
$ cat .git/sequencer/todo
pick 51c8398 Raise guard threshold to 0.80
pick b06763c Add blocklist
pick 9e654c4 Lower max_tokens to 128
$ git status | head -2
On branch main
You are currently cherry-picking commit 51c8398.
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-2-five-states/06-case-5 -->
```text
$ cd ../case-5
$ cat .git/rebase-merge/head-name
refs/heads/feature/strict-guard
$ cat .git/rebase-merge/onto .git/rebase-merge/orig-head
5c14f0f7980a7ba5446f53700a514eb9b1ffe8b7
2e9cad0aeb9b38d47671d2dd41ac74c9bb424168
$ cat .git/rebase-merge/done
pick 585bc9953ace291724f0692d1b2b7a3e2991618e # Raise guard threshold to 0.80
$ cat .git/rebase-merge/git-rebase-todo
pick 7ca1519c5d286eb4ba8cdea5e1d14ce3eafa6d85 # Add blocklist
pick 2e9cad0aeb9b38d47671d2dd41ac74c9bb424168 # Lower max_tokens to 128
$ cat .git/REBASE_HEAD
585bc9953ace291724f0692d1b2b7a3e2991618e
$ git status | head -2
interactive rebase in progress; onto 5c14f0f
Last command done (1 command done):
```
<!-- /snippet -->

### What happened internally

- **case-1, a revert.** `REVERT_HEAD` names the commit being undone, "Raise guard threshold to 0.80". HEAD is attached to `feature/strict-guard`. `MERGE_MSG` holds the prepared message and the conflicted path. There is no `sequencer` directory, because one commit was requested.
- **case-2, a bisect.** HEAD is a raw ID: the commit under test. `BISECT_START` is the branch to return to. `BISECT_LOG` is the whole session, replayable with `git bisect replay`; the marks are refs under `refs/bisect/`. No conflict, no unmerged path, a clean working tree: nothing but these files and the detached HEAD shows that a bisect is open.
- **case-3, a merge.** `MERGE_HEAD` names the tip of `feature/strict-guard`; it becomes the second parent when you commit. `ORIG_HEAD` is the tip of `main` before the merge. HEAD stays attached. Note that `git status` does not use the word "merging" while paths are unmerged.
- **case-4, a cherry-pick of three commits.** `CHERRY_PICK_HEAD` is the commit whose application stopped. `sequencer/head` is the tip of `main` before the first pick, which is where `--abort` returns. `sequencer/todo` lists the stopped pick first and then those still to come.
- **case-5, a rebase.** HEAD is detached on the new base, the ID in `onto`. `head-name` is the branch that moves when the last pick succeeds; `orig-head` is where `--abort` puts it back. `done` has one line, `git-rebase-todo` two. `REBASE_HEAD` is the commit whose replay stopped.

In every case the files are the operation. Git has no other memory of it ([Chapter 3](../textbook/ch03-git-internals.md), section 3.10).

### Checkpoint

- Your written answers for step 1 match the first two lines of `git status` in all five cases.
- For case-4 and case-5 you can say, from the files alone, which commit `--abort` would return the branch to.
- You ran no command that changed a ref.

### Failure scenario

Advice that circulates in old forum posts: "delete the MERGE files and the merge is gone". Try it in `case-3`:

```bash
cd ../case-3
rm .git/MERGE_HEAD .git/MERGE_MODE .git/MERGE_MSG
git status
git merge --abort
```

<!-- snippet: ch29/lab-35-2-five-states/07-failure -->
```text
$ cd ../case-3
# Advice found in an old forum post: "delete the MERGE files and the merge is gone".
$ rm .git/MERGE_HEAD .git/MERGE_MODE .git/MERGE_MSG
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   blocklist.py

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml

$ git merge --abort
fatal: There is no merge to abort (MERGE_HEAD missing).
[exit status: 128]
```
<!-- /snippet -->

The merge is not gone. The index still holds the three conflict stages and the staged file from the other branch. What is gone is Git's knowledge that this is a merge: `git status` offers no abort, and `git merge --abort` fails. Now "finish" the work as someone in that position would:

```bash
printf 'threshold: 0.80\nmax_tokens: 128\n' > guard.yaml
git add guard.yaml
git commit -m "Merge strict guard"
git log --graph --oneline -4
git cat-file -p HEAD | grep -c "^parent"
git branch --no-merged
```

<!-- snippet: ch29/lab-35-2-five-states/08-failure-commit -->
```text
$ printf 'threshold: 0.80\nmax_tokens: 128\n' > guard.yaml
$ git add guard.yaml
$ git commit -m "Merge strict guard"
[main 0561e7a] Merge strict guard
 2 files changed, 3 insertions(+), 2 deletions(-)
 create mode 100644 blocklist.py
$ git log --graph --oneline -4
* 0561e7a Merge strict guard
* 81f478c Add README
* 1f742f2 Raise guard threshold to 0.65
* a26258d Count tokens, not characters
$ git cat-file -p HEAD | grep -c "^parent"
1
$ git branch --no-merged
  feature/strict-guard
```
<!-- /snippet -->

The commit has the merged content and one parent. It is an ordinary commit that copies the changes of the branch. Git still lists `feature/strict-guard` as not merged, so the next merge of that branch starts from the old merge base and can conflict with its own content. This is the same defect as a squash merge followed by reuse of the branch ([Chapter 17](../textbook/ch17-pull-requests.md), section 17.12), produced by one `rm`.

### Recovery

The commit is local and unpublished, so the lowest-risk repair is to take it off the branch and merge properly. Anchor it first: it holds the conflict resolution.

```bash
git branch rescue/one-parent-merge
git reset --keep HEAD~1
git merge feature/strict-guard
git status | head -2
git restore --source=rescue/one-parent-merge -- guard.yaml
git add guard.yaml
git -c core.editor=true commit
```

<!-- snippet: ch29/lab-35-2-five-states/09-recovery -->
```text
$ git branch rescue/one-parent-merge
$ git reset --keep HEAD~1
$ git merge feature/strict-guard
Auto-merging guard.yaml
CONFLICT (content): Merge conflict in guard.yaml
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status | head -2
On branch main
You have unmerged paths.
$ git restore --source=rescue/one-parent-merge -- guard.yaml
$ git add guard.yaml
$ git -c core.editor=true commit
[main 303097f] Merge branch 'feature/strict-guard'
```
<!-- /snippet -->

`git reset --keep` 🟡 moves the branch back and would refuse if an uncommitted change were in the way. The merge stops at the same conflict; `git restore --source` takes the resolved file from the rescue branch. `-c core.editor=true` accepts the prepared merge message without opening an editor.

### Verification

```bash
git log --graph --oneline -5
git cat-file -p HEAD | grep -c "^parent"
git branch --no-merged
git diff --stat rescue/one-parent-merge HEAD
git branch -D rescue/one-parent-merge
ls .git | grep -c MERGE
```

<!-- snippet: ch29/lab-35-2-five-states/10-verification -->
```text
$ git log --graph --oneline -5
*   303097f Merge branch 'feature/strict-guard'
|\  
| * 26d9af6 Lower max_tokens to 128
| * bd90cf4 Add blocklist
| * 4933596 Raise guard threshold to 0.80
* | 81f478c Add README
$ git cat-file -p HEAD | grep -c "^parent"
2
$ git branch --no-merged
  rescue/one-parent-merge
$ git diff --stat rescue/one-parent-merge HEAD
$ git branch -D rescue/one-parent-merge
Deleted branch rescue/one-parent-merge (was 0561e7a).
$ ls .git | grep -c MERGE
0
```
<!-- /snippet -->

Two parents. The only branch still listed as unmerged is the rescue branch itself. `git diff --stat` between the rescue commit and the merge prints nothing: the same content, now with the right ancestry. After the rescue branch is deleted, no `MERGE` file remains.

### Questions

1. Which two of the five operations detach HEAD, and why do the other three not need to?
2. In case-4, `sequencer/todo` still lists the commit that `CHERRY_PICK_HEAD` names. What does that tell you about when Git removes a line from the todo list?
3. A repository has `ORIG_HEAD` and `FETCH_HEAD` in `.git` and no other file in capitals besides `HEAD`. Is an operation in progress?
4. In case-2 the working tree is clean and no path is unmerged. Give two observations, other than `git status`, that reveal the bisect.
5. After the failure scenario the tree of the one-parent commit and the tree of the real merge are identical. Why does the difference still matter? Name one later command whose result differs.
6. `git merge --quit` and `rm .git/MERGE_*` both make Git forget the merge. Why is neither a way to undo it, and which command is?

## Lab 35.3: Preserve evidence, then fix

### Objective

Take over a repository in the middle of someone else's operation. Preserve the state in four layers before changing anything, finish the work, verify it, and then see in a rehearsal copy what the "obvious" command would have destroyed and recover from the evidence.

### Prerequisites

- Chapter 29, sections 29.6, 29.7, 29.9 and 29.10.
- Chapter 10, sections 10.6 and 10.9 (the sequencer; the backport workflow).

### Setup

```bash
bash labs/ch29/setup-35-3-preserve-then-fix.sh
labs/shell m35-3
```

The script builds the repository `guardrail` and a handover note. A colleague was backporting three commits from `main` to `release/1.4` with `git cherry-pick -x`. The first pick succeeded. The second stopped at a conflict. The colleague resolved the file by hand, did not stage it, and left.

### Commands

Step 1. Read the note and observe.

```bash
cat guardrail.HANDOVER.txt
cd guardrail
git status
```

Step 2. Diagnose, read-only. Which commit stopped, what remains, and what does the hand-made resolution look like?

```bash
git log --graph --decorate --oneline --all
cat .git/CHERRY_PICK_HEAD
cat .git/sequencer/todo
git ls-files -u
git diff
```

**Stop and write:** which parts of the current state exist in a commit, which exist only in the index, and which exist only in the working tree. Then decide what each layer of preservation must hold.

Step 3. Preserve: the recorded output, a backup ref, a copy, a second copy for rehearsal, a bundle.

```bash
mkdir ../evidence
{ git status; git log --graph --decorate --oneline --all; git reflog; git diff; } > ../evidence/state.txt 2>&1
git branch rescue/backport-partial HEAD
cp -Rp . ../evidence/guardrail-copy
cp -Rp . ../rehearsal
git bundle create ../evidence/guardrail.bundle --all
git bundle verify ../evidence/guardrail.bundle
```

Step 4. Fix: check the resolution against the note, stage it, continue.

```bash
cat guard.yaml
git add guard.yaml
git -c core.editor=true cherry-pick --continue
```

Step 5. Verify.

```bash
git status
git log --oneline -4
git show HEAD~1:guard.yaml
git cherry -v release/1.4 main
ls .git | grep -c -E "CHERRY_PICK_HEAD|sequencer"
```

### Expected output

<!-- snippet: ch29/lab-35-3-preserve-then-fix/01-handover -->
```text
$ cat guardrail.HANDOVER.txt
Handover note:
"Backporting the blocklist and the token limit to release/1.4 for tonight.
Got a conflict in guard.yaml. On 1.4 the threshold must stay 0.50; the limit
becomes 128. I fixed the file by hand and then had to leave. Please finish."
$ cd guardrail
$ git status
On branch release/1.4
You are currently cherry-picking commit e0631de.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-3-preserve-then-fix/02-diagnose -->
```text
$ git log --graph --decorate --oneline --all
* 5c011a9 (HEAD -> release/1.4) Add blocklist
* 329817a Allow 512 tokens on the 1.4 line
| * f9e40d6 (main) Block the word secret
| * e0631de Lower max_tokens to 128
| * b24fd62 Add blocklist
| * 73ef788 Raise guard threshold to 0.65
|/  
* b039fd7 Add output guard
$ cat .git/CHERRY_PICK_HEAD
e0631de25fbc27decbe5c84018d24bdf95f12aa2
$ cat .git/sequencer/todo
pick e0631de Lower max_tokens to 128
pick f9e40d6 Block the word secret
$ git ls-files -u
100644 ea5b34d7cbddccfdf80d8ac18aa35c90353b7249 1	guard.yaml
100644 383f082880d9887c5a67715cf7c9fba0f9bce715 2	guard.yaml
100644 47a6e5c84e76259832497409533332fd12f8d066 3	guard.yaml
$ git diff
diff --cc guard.yaml
index 383f082,47a6e5c..0000000
--- a/guard.yaml
+++ b/guard.yaml
@@@ -1,2 -1,2 +1,2 @@@
 -threshold: 0.65
 +threshold: 0.50
- max_tokens: 512
+ max_tokens: 128
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-3-preserve-then-fix/03-preserve -->
```text
$ mkdir ../evidence
$ { git status; git log --graph --decorate --oneline --all; git reflog; git diff; } > ../evidence/state.txt 2>&1
$ git branch rescue/backport-partial HEAD
$ cp -Rp . ../evidence/guardrail-copy
$ cp -Rp . ../rehearsal
$ git bundle create ../evidence/guardrail.bundle --all
$ git bundle verify ../evidence/guardrail.bundle
../evidence/guardrail.bundle is okay
The bundle contains these 4 refs:
f9e40d623e77c7f311cf07e75d14016adff35ae5 refs/heads/main
5c011a9e9d1248da21f080d2613a4bb38655ed67 refs/heads/release/1.4
5c011a9e9d1248da21f080d2613a4bb38655ed67 refs/heads/rescue/backport-partial
5c011a9e9d1248da21f080d2613a4bb38655ed67 HEAD
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-3-preserve-then-fix/04-fix -->
```text
$ cat guard.yaml
threshold: 0.50
max_tokens: 128
$ git add guard.yaml
$ git -c core.editor=true cherry-pick --continue
[release/1.4 99a0531] Lower max_tokens to 128
 Date: Mon Sep 7 10:07:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
[release/1.4 78b0e20] Block the word secret
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch29/lab-35-3-preserve-then-fix/05-verify -->
```text
$ git status
On branch release/1.4
nothing to commit, working tree clean
$ git log --oneline -4
78b0e20 Block the word secret
99a0531 Lower max_tokens to 128
5c011a9 Add blocklist
329817a Allow 512 tokens on the 1.4 line
$ git show HEAD~1:guard.yaml
threshold: 0.50
max_tokens: 128
$ git cherry -v release/1.4 main
+ 73ef78885a54252a1af4b097f3d5f4d73b1f5c2e Raise guard threshold to 0.65
- b24fd6204b321b7b34d07ecd0e969bb3c610c30c Add blocklist
+ e0631de25fbc27decbe5c84018d24bdf95f12aa2 Lower max_tokens to 128
- f9e40d623e77c7f311cf07e75d14016adff35ae5 Block the word secret
$ ls .git | grep -c -E "CHERRY_PICK_HEAD|sequencer"
0
```
<!-- /snippet -->

### What happened internally

- The state had three layers. **Committed:** the first pick, `5c011a9`, on `release/1.4`. **Index only:** the three conflict stages of `guard.yaml` printed by `git ls-files -u`. **Working tree only:** the hand-made resolution. `git diff` in a conflict prints a combined diff: the two columns of markers show that the result takes `threshold: 0.50` from the release side and `max_tokens: 128` from the picked commit, as the note demands.
- The backup ref holds the committed layer. Only the copies hold the other two: no ref can point at an unstaged file. The bundle lists four refs, among them the rescue branch, and would restore the commits on another machine.
- `git cherry-pick --continue` committed the staged resolution as `99a0531`, then applied the remaining commit of `sequencer/todo` as `78b0e20`, and removed `CHERRY_PICK_HEAD` and the `sequencer` directory.
- `git cherry -v release/1.4 main` compares by patch. The minus sign marks "Add blocklist" and "Block the word secret" as present on the release branch in equivalent form. "Raise guard threshold to 0.65" has a plus sign because it was deliberately not backported. "Lower max_tokens to 128" has a plus sign although it was backported: the conflict resolution changed its diff, so the patch IDs differ ([Chapter 10](../textbook/ch10-cherry-pick.md), section 10.10). Read a plus sign as "no identical patch", not as "missing".

### Checkpoint

- `../evidence` holds `state.txt`, `guardrail-copy` and `guardrail.bundle`; `git bundle verify` printed "is okay".
- `git -C ../evidence/guardrail-copy status` still reports the cherry-pick in progress.
- `release/1.4` has four commits on top of "Add output guard", and `git show HEAD~1:guard.yaml` prints a threshold of 0.50 with 128 tokens.

### Failure scenario

The command that many people would have typed first, because `git status` suggests it: `git cherry-pick --abort`. Run it in the rehearsal copy, which is still in the state of step 3.

```bash
cd ../rehearsal
git status | head -2
git cherry-pick --abort
git status
git log --oneline -2
cat guard.yaml
```

<!-- snippet: ch29/lab-35-3-preserve-then-fix/06-failure -->
```text
$ cd ../rehearsal
$ git status | head -2
On branch release/1.4
You are currently cherry-picking commit e0631de.
$ git cherry-pick --abort
$ git status
On branch release/1.4
nothing to commit, working tree clean
$ git log --oneline -2
329817a Allow 512 tokens on the 1.4 line
b039fd7 Add output guard
$ cat guard.yaml
threshold: 0.50
max_tokens: 512
```
<!-- /snippet -->

The abort printed nothing and returned the branch to the commit before the whole sequence, the ID stored in `sequencer/head`. The first pick is off the branch. The hand-made resolution, which existed only in the working tree, was overwritten: `guard.yaml` has 512 tokens again. Nothing in this repository can bring that file content back, because it was never staged and never hashed ([Chapter 13](../textbook/ch13-recovery.md), section 13.12).

### Recovery

Each lost layer comes from the evidence that held it. The committed pick is on the rescue branch, which the copy carried along; a fast-forward restores it. The sequence is started again for the two remaining commits; the resolution comes from the evidence copy.

```bash
git merge --ff-only rescue/backport-partial
git cherry-pick -x main~1 main
cp ../evidence/guardrail-copy/guard.yaml guard.yaml
git add guard.yaml
git -c core.editor=true cherry-pick --continue
```

<!-- snippet: ch29/lab-35-3-preserve-then-fix/07-recovery -->
```text
$ git merge --ff-only rescue/backport-partial
Updating 329817a..5c011a9
Fast-forward
 blocklist.py | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 blocklist.py
$ git cherry-pick -x main~1 main
Auto-merging guard.yaml
CONFLICT (content): Merge conflict in guard.yaml
error: could not apply e0631de... Lower max_tokens to 128
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
$ cp ../evidence/guardrail-copy/guard.yaml guard.yaml
$ git add guard.yaml
$ git -c core.editor=true cherry-pick --continue
[release/1.4 dc02c3b] Lower max_tokens to 128
 Date: Mon Sep 7 10:07:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
[release/1.4 f46f218] Block the word secret
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

### Verification

```bash
git log --oneline -4
git rev-parse 'HEAD^{tree}'
git -C ../guardrail rev-parse 'HEAD^{tree}'
git status -sb
```

<!-- snippet: ch29/lab-35-3-preserve-then-fix/08-verification -->
```text
$ git log --oneline -4
f46f218 Block the word secret
dc02c3b Lower max_tokens to 128
5c011a9 Add blocklist
329817a Allow 512 tokens on the 1.4 line
$ git rev-parse 'HEAD^{tree}'
940671b2b37f12fe7f0b2599c35bb6c88e7f9443
$ git -C ../guardrail rev-parse 'HEAD^{tree}'
940671b2b37f12fe7f0b2599c35bb6c88e7f9443
$ git status -sb
## release/1.4
```
<!-- /snippet -->

The two tree IDs are equal: the recovered branch in the rehearsal copy has exactly the content of the branch you finished in `guardrail`. The commit IDs differ (`dc02c3b` here, `99a0531` there) because the commits were created at another time, and the committer date is part of a commit. Compare trees when you want to compare content. When you are done, leave the lab shell and remove the evidence, as you would after a real incident.

### Questions

1. Before step 3, which part of the state would have been lost by `git cherry-pick --abort` with no way back, and which part would have been recoverable from the reflog?
2. The bundle was created after the rescue branch. Would the bundle have contained the first pick without the rescue branch? Explain with the refs that `git bundle verify` listed.
3. Why did the recovery use `git merge --ff-only rescue/backport-partial` and not `git reset --hard rescue/backport-partial`?
4. `git cherry -v release/1.4 main` marks "Lower max_tokens to 128" with a plus sign although the commit was backported. What should you check before you conclude that a plus-marked commit is missing from a release branch?
5. The handover note said what the resolution should be. What would you have done if there had been no note?
6. The lab made two copies: one as evidence and one for rehearsal. Why not rehearse in the evidence copy?
