# Module 32 labs: Branching and release strategy

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" is real output of a replay script in `labs/ch27/`. Read [Chapter 27](../textbook/ch27-open-source-team-workflows.md) first; the lab names the sections it uses.

## How this lab works

There is no network. Two copies of one repository stand for one company that could have chosen either of two strategies. A pull request merge is imitated with `git merge --no-ff`, which produces the merge commit that GitHub's "Create a merge commit" method produces ([Chapter 17](../textbook/ch17-pull-requests.md), section 17.8).

```bash
bash labs/ch27/setup-32-1-two-strategies.sh   # build (or rebuild) the starting state
labs/shell m32-1                              # open the lab shell in that sandbox, then type the commands
labs/run ch27/lab-32-1-two-strategies         # or: watch the exact replay that the book prints
```

Differences between your terminal and the book that are expected:

- **Commit IDs.** Commits made by the setup script have the same IDs as in the book. Commits and tags that you make have other IDs, because the commit time is part of the ID, and so does everything built on them. Compare shapes, not IDs.
- **Graph order.** `git log --graph` orders commits by date. Yours carry the real time, so the same graph can be drawn with its lines in another order.

## Lab 32.1: One release and one hotfix under two strategies

### Objective

Take the same repository through the same release (1.4.0), the same later feature and the same hotfix (1.4.1) twice: once with releases as tags on `main` (GitHub Flow), once with a release branch and a cherry-picked backport. Compare what each 1.4.1 contains. Then let a fix be forgotten on `main`, find it with one command, and repair it.

### Prerequisites

Chapter 27, sections 27.6 and 27.8 to 27.10. `git cherry-pick` from [Chapter 10](../textbook/ch10-cherry-pick.md), annotated tags from [Chapter 14B](../textbook/ch14b-config-tags-signing.md), and the `A...B` notation from the Module 10 range lab.

### Setup

```bash
bash labs/ch27/setup-32-1-two-strategies.sh
labs/shell m32-1
```

Starting state: `github-flow/promptgate` and `release-branch/promptgate` are identical. Release `v1.3.0` is tagged. Two pull requests (#41 streaming, #42 tenant limits) are merged into `main`. A branch `feature/batch-api` with one commit is waiting. The tenant-limits change contains a bug: in `gateway/limits.py` a limit of `0` is treated as "no limit set".

### Commands

Part A, GitHub Flow:

```bash
# 1. Look, then release 1.4.0 as a tag on main
cd github-flow/promptgate
git log --oneline --graph --decorate --all
git tag -a v1.4.0 -m "promptgate 1.4.0"

# 2. Work continues: pull request #43 is merged
git merge --no-ff -m "Merge pull request #43 from feature/batch-api" feature/batch-api
git branch -d feature/batch-api

# 3. The hotfix: a short branch from main, merged, tagged
git switch -c hotfix/suspended-tenant
sed -i.bak "s/LIMITS.get(tenant) or LIMITS\[\"default\"\]/LIMITS.get(tenant, LIMITS[\"default\"])/" gateway/limits.py && rm gateway/limits.py.bak
git diff --stat
git commit -q -am "Fix limit 0 being treated as unlimited"
git switch -q main
git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant
git branch -d hotfix/suspended-tenant
git tag -a v1.4.1 -m "promptgate 1.4.1"

# 4. What did 1.4.1 ship?
git log --oneline --graph --decorate -6
git log --oneline --no-merges v1.4.0..v1.4.1
```

Part B, release branch:

```bash
# 5. Cut the release branch, tag on it, and let main move on
cd ../../release-branch/promptgate
git branch release/1.4 main
git tag -a v1.4.0 -m "promptgate 1.4.0" release/1.4
git merge --no-ff -m "Merge pull request #43 from feature/batch-api" feature/batch-api
git branch -d feature/batch-api

# 6. The hotfix: on main first, then cherry-picked to the release branch
git switch -c hotfix/suspended-tenant
sed -i.bak "s/LIMITS.get(tenant) or LIMITS\[\"default\"\]/LIMITS.get(tenant, LIMITS[\"default\"])/" gateway/limits.py && rm gateway/limits.py.bak
git commit -q -am "Fix limit 0 being treated as unlimited"
git switch -q main
git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant
git switch -q release/1.4
git cherry-pick -x hotfix/suspended-tenant
git tag -a v1.4.1 -m "promptgate 1.4.1"
git branch -D hotfix/suspended-tenant

# 7. What did 1.4.1 ship here?
git log --oneline --graph --decorate --all -8
git log --oneline --no-merges v1.4.0..v1.4.1

# 8. The same two questions asked of both repositories
git -C ../../github-flow/promptgate diff --stat v1.4.0 v1.4.1
git diff --stat v1.4.0 v1.4.1
git -C ../../github-flow/promptgate for-each-ref --format="%(refname:short)" refs/heads
git for-each-ref --format="%(refname:short)" refs/heads
```

`git branch -D` in step 6 is 🔴 DANGEROUS in general: it deletes a ref and its reflog with no merge check. It is appropriate here because the branch's one commit is reachable from `main` through the merge you made two commands earlier; preview with `git branch --contains hotfix/suspended-tenant`.

### Expected output

The starting state, identical in both copies:

<!-- snippet: ch27/lab-32-1-two-strategies/01-start -->
```text
$ cd github-flow/promptgate
$ git log --oneline --graph --decorate --all
* 98cc48f (feature/batch-api) Add batch endpoint
*   518d961 (HEAD -> main) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
* |   a7ccb4b Merge pull request #41 from feature/streaming
|\ \  
| |/  
|/|   
| * b00109d Stream tokens to the client
|/  
* b6e2f58 (tag: v1.3.0) Add per-tenant rate limits
* 9df3d07 Add gateway skeleton
```
<!-- /snippet -->

Part A:

<!-- snippet: ch27/lab-32-1-two-strategies/02-flow-release -->
```text
$ git tag -a v1.4.0 -m "promptgate 1.4.0"
$ git merge --no-ff -m "Merge pull request #43 from feature/batch-api" feature/batch-api
Merge made by the 'ort' strategy.
 gateway/batch.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 gateway/batch.py
$ git branch -d feature/batch-api
Deleted branch feature/batch-api (was 98cc48f).
```
<!-- /snippet -->

<!-- snippet: ch27/lab-32-1-two-strategies/03-flow-hotfix -->
```text
$ git switch -c hotfix/suspended-tenant
Switched to a new branch 'hotfix/suspended-tenant'
$ sed -i.bak "s/LIMITS.get(tenant) or LIMITS\[\"default\"\]/LIMITS.get(tenant, LIMITS[\"default\"])/" gateway/limits.py && rm gateway/limits.py.bak
$ git diff --stat
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git switch -q main
$ git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant
Merge made by the 'ort' strategy.
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git branch -d hotfix/suspended-tenant
Deleted branch hotfix/suspended-tenant (was fde1267).
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
```
<!-- /snippet -->

<!-- snippet: ch27/lab-32-1-two-strategies/04-flow-result -->
```text
$ git log --oneline --graph --decorate -6
*   d4b2c19 (HEAD -> main, tag: v1.4.1) Merge pull request #44 from hotfix/suspended-tenant
|\  
| * fde1267 Fix limit 0 being treated as unlimited
|/  
*   4c206ca Merge pull request #43 from feature/batch-api
|\  
| * 98cc48f Add batch endpoint
|/  
*   518d961 (tag: v1.4.0) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
$ git log --oneline --no-merges v1.4.0..v1.4.1
fde1267 Fix limit 0 being treated as unlimited
98cc48f Add batch endpoint
```
<!-- /snippet -->

Part B:

<!-- snippet: ch27/lab-32-1-two-strategies/05-rb-release -->
```text
$ cd ../../release-branch/promptgate
$ git branch release/1.4 main
$ git tag -a v1.4.0 -m "promptgate 1.4.0" release/1.4
$ git merge --no-ff -m "Merge pull request #43 from feature/batch-api" feature/batch-api
Merge made by the 'ort' strategy.
 gateway/batch.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 gateway/batch.py
$ git branch -d feature/batch-api
Deleted branch feature/batch-api (was 98cc48f).
```
<!-- /snippet -->

<!-- snippet: ch27/lab-32-1-two-strategies/06-rb-hotfix -->
```text
$ git switch -c hotfix/suspended-tenant
Switched to a new branch 'hotfix/suspended-tenant'
$ sed -i.bak "s/LIMITS.get(tenant) or LIMITS\[\"default\"\]/LIMITS.get(tenant, LIMITS[\"default\"])/" gateway/limits.py && rm gateway/limits.py.bak
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git switch -q main
$ git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant
Merge made by the 'ort' strategy.
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git switch -q release/1.4
$ git cherry-pick -x hotfix/suspended-tenant
[release/1.4 8444832] Fix limit 0 being treated as unlimited
 Date: Mon Sep 7 10:42:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
$ git branch -D hotfix/suspended-tenant
Deleted branch hotfix/suspended-tenant (was c73fb72).
```
<!-- /snippet -->

<!-- snippet: ch27/lab-32-1-two-strategies/07-rb-result -->
```text
$ git log --oneline --graph --decorate --all -8
* 8444832 (HEAD -> release/1.4, tag: v1.4.1) Fix limit 0 being treated as unlimited
| *   16db603 (main) Merge pull request #44 from hotfix/suspended-tenant
| |\  
| | * c73fb72 Fix limit 0 being treated as unlimited
| |/  
| * 45c76bf Merge pull request #43 from feature/batch-api
|/| 
| * 98cc48f Add batch endpoint
|/  
*   518d961 (tag: v1.4.0) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
* |   a7ccb4b Merge pull request #41 from feature/streaming
|\ \  
| |/  
|/|   
$ git log --oneline --no-merges v1.4.0..v1.4.1
8444832 Fix limit 0 being treated as unlimited
```
<!-- /snippet -->

<!-- snippet: ch27/lab-32-1-two-strategies/08-compare -->
```text
# The same question asked of both repositories: what changed between the two releases?
$ git -C ../../github-flow/promptgate diff --stat v1.4.0 v1.4.1
 gateway/batch.py  | 2 ++
 gateway/limits.py | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git diff --stat v1.4.0 v1.4.1
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
# And: which long-lived refs does each strategy leave behind?
$ git -C ../../github-flow/promptgate for-each-ref --format="%(refname:short)" refs/heads
main
$ git for-each-ref --format="%(refname:short)" refs/heads
main
release/1.4
```
<!-- /snippet -->

### What happened internally

- **Steps 1 and 5.** `git tag -a` created a tag object and a ref under `refs/tags/`. In part A the tag names the tip of `main`. In part B it names the same commit, `518d961`, which is also the tip of the new ref `refs/heads/release/1.4`. Until step 2 the two repositories differ by exactly one ref.
- **Steps 2 and 5.** The merge of `feature/batch-api` moved `main` in both. In part B the tag and the release branch stayed where they were: a tag never moves, and a branch moves only when you commit on it or update it.
- **Step 3.** The hotfix branch started from the current `main`, which already contains the batch endpoint. Tagging the merge as `v1.4.1` therefore released the batch endpoint with the fix.
- **Step 6.** The fix was committed once, on a branch from `main`, and merged into `main`. `git cherry-pick -x` then created a second commit on `release/1.4` with the same change, a different parent and therefore a different ID, and appended the "(cherry picked from commit ...)" line. `v1.4.1` names that second commit.
- **Step 8.** `git diff --stat v1.4.0 v1.4.1` compares two snapshots. In part A they differ by two files, in part B by one.

### Checkpoint

In `release-branch/promptgate`:

```bash
git tag --contains release/1.4        # expect: v1.4.1
git branch --contains v1.4.1          # expect: release/1.4 only
git log --oneline --cherry-pick --right-only --no-merges main...release/1.4   # expect: no output
```

If the last command prints a commit, the release branch has a change that `main` lacks. At this point it must print nothing.

### Failure scenario

Still in `release-branch/promptgate`, on `release/1.4`. A second problem is reported: usage counters can be negative after a refund. Somebody fixes it directly on the release branch, releases 1.4.2, and goes home. Later, release 1.5 is cut from `main`.

```bash
# 9. A fix committed only on the release branch
sed -i.bak "s/return used < limit/return max(used, 0) < limit/" gateway/limits.py && rm gateway/limits.py.bak
git commit -q -am "Clamp negative usage counters"
git tag -a v1.4.2 -m "promptgate 1.4.2"

# 10. The next release is cut from main
git switch -q main
git branch release/1.5 main && git tag -a v1.5.0 -m "promptgate 1.5.0" release/1.5
git grep -c "max(used, 0)" v1.4.2 v1.5.0 -- gateway/limits.py

# 11. Find it
git log --oneline --cherry-pick --right-only --no-merges main...release/1.4
```

<!-- snippet: ch27/lab-32-1-two-strategies/09-failure -->
```text
# Failure scenario: a second fix is committed straight to the release branch.
$ sed -i.bak "s/return used < limit/return max(used, 0) < limit/" gateway/limits.py && rm gateway/limits.py.bak
$ git commit -q -am "Clamp negative usage counters"
$ git tag -a v1.4.2 -m "promptgate 1.4.2"
# Nobody ports it. Later, release 1.5 is cut from main:
$ git switch -q main
$ git branch release/1.5 main && git tag -a v1.5.0 -m "promptgate 1.5.0" release/1.5
$ git grep -c "max(used, 0)" v1.4.2 v1.5.0 -- gateway/limits.py
v1.4.2:gateway/limits.py:1
```
<!-- /snippet -->

`git grep` lists only `v1.4.2`: release 1.5.0 does not contain the fix that 1.4.2 shipped. A customer who upgrades gets the bug back.

<!-- snippet: ch27/lab-32-1-two-strategies/10-detect -->
```text
$ git log --oneline --cherry-pick --right-only --no-merges main...release/1.4
8196669 Clamp negative usage counters
```
<!-- /snippet -->

### Recovery

Port the fix forward to `main`, then to the release branch that shipped without it, and release a new patch version. Do not move `v1.5.0`.

```bash
# 12. Forward-port, then patch 1.5
git cherry-pick -x release/1.4
git switch -q release/1.5
git cherry-pick -x main
git tag -a v1.5.1 -m "promptgate 1.5.1"
```

<!-- snippet: ch27/lab-32-1-two-strategies/11-recover -->
```text
# Recovery: port the fix forward to main, then to the release branch that shipped without it.
$ git cherry-pick -x release/1.4
[main 95d616e] Clamp negative usage counters
 Date: Mon Sep 7 10:56:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git switch -q release/1.5
$ git cherry-pick -x main
[release/1.5 327dcd4] Clamp negative usage counters
 Date: Mon Sep 7 10:56:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git tag -a v1.5.1 -m "promptgate 1.5.1"
```
<!-- /snippet -->

`git cherry-pick -x release/1.4` picks the commit at the tip of that branch, which is the unported fix. If the tip were not the commit you want, you would name the commit by the ID that step 11 printed.

### Verification

```bash
git log --oneline --cherry-pick --right-only --no-merges main...release/1.4
git log --oneline --cherry-pick --right-only --no-merges main...release/1.5
git grep -c "max(used, 0)" v1.5.0 v1.5.1 main -- gateway/limits.py
git tag --list "v1.*" --format="%(refname:short) %(*objectname:short)"
```

<!-- snippet: ch27/lab-32-1-two-strategies/12-verify -->
```text
$ git log --oneline --cherry-pick --right-only --no-merges main...release/1.4
$ git log --oneline --cherry-pick --right-only --no-merges main...release/1.5
$ git grep -c "max(used, 0)" v1.5.0 v1.5.1 main -- gateway/limits.py
v1.5.1:gateway/limits.py:1
main:gateway/limits.py:1
$ git tag --list "v1.*" --format="%(refname:short) %(*objectname:short)"
v1.3.0 b6e2f58
v1.4.0 518d961
v1.4.1 8444832
v1.4.2 8196669
v1.5.0 16db603
v1.5.1 327dcd4
```
<!-- /snippet -->

Both port checks are empty. `v1.5.1` and `main` contain the fix; `v1.5.0` still does not, and still names the commit it always named.

### Questions

1. In part A, `git log --no-merges v1.4.0..v1.4.1` lists two commits. A customer on 1.4.0 asks for "the security fix only". What can you offer them from the part A repository, and what would you have to create first?
2. In part B the fix exists as two commits. Name three different pieces of evidence in the repository that they are the same fix, and say which of them survives a cherry-pick that needed a manual conflict resolution.
3. `git branch --contains v1.4.1` printed only `release/1.4` in part B. Is the fix therefore missing from `main`? Which command answers that question correctly?
4. The step 11 check printed one commit. Explain why it did not also print the commit of step 6, although that commit, too, is on `release/1.4` and is not an ancestor of `main`.
5. In the recovery you created `v1.5.1` instead of moving `v1.5.0` to the fixed commit. Give the Git reason and the platform reason.
6. Suppose the team had used the merge-upward convention instead. Which single command in the failure scenario would have been different, what invariant could a release gate test, and what would that merge have brought into `main` besides the fix?
7. Part A ended with one long-lived branch and part B with three (`main`, `release/1.4`, `release/1.5`). What does each additional branch cost every week, and what decides when a release branch may be deleted?
