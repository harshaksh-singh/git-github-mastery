# Module 36 labs: incident drills, local and history

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from a replay script in `labs/incidents/`. Read [Chapter 30: Incident Response](../textbook/ch30-incident-response.md), sections 30.1 to 30.4, first. Do **not** read sections 30.5 to 30.14 or the files in `solutions/` for an incident before you have attempted it.

## How these drills work

A drill is not a guided lab. You get a report from a colleague, a sandbox in a broken state, and a check script. Nobody tells you which commands repair it. That is the point: a diagnosis you have read cannot be made again.

```bash
incidents/01-hard-reset/generate.sh        # builds the sandbox and prints its path (run again to start over)
labs/shell "<the path it printed>"         # the isolated lab shell, in that sandbox
incidents/01-hard-reset/check.sh           # from the course root: exit status 0 when the recovery is complete
```

The sandbox always contains `server.git` (a bare repository in the role of the server) and clones named `you`, `asha` and `ravi`. You may read and work in every clone. [`incidents/README.md`](../incidents/README.md) has the details.

| Lab | Incident | Directory | The report says |
|---|---|---|---|
| 36.1 | 1 | `incidents/01-hard-reset` | "I think `git pull` ate my work." |
| 36.2 | 8 | `incidents/08-branch-disappeared` | "My branch has disappeared." |
| 36.3 | 10 | `incidents/10-commit-local-not-remote` | "It is pushed. GitHub must be caching." |
| 36.4 | 9 | `incidents/09-misunderstood-conflict` | "My fix is in the log and not in the file." |
| 36.5 | 5 | `incidents/05-rebased-shared-branch` | "Every commit is in the pull request twice." |

**The procedure, for every drill.** Keep a text file open and write into it as you go.

1. Read `SYMPTOMS.md`. Write the symptom in one sentence, without interpretation.
2. Collect evidence with read-only commands: the ten-command diagnosis of [Chapter 1](../textbook/ch01-fundamentals.md), section 1.11, in each clone that matters, and `git ls-remote origin`.
3. Write at least three hypotheses, each with the command whose output would tell it apart. Run those commands.
4. Write the root cause as the seven-line box of Chapter 1, section 1.10. Name the layer.
5. Anchor every state you may need: `git branch rescue/<what> <ID>`.
6. Choose the fix that destroys least. Run it one command at a time.
7. Verify with the commands that showed the problem, then with `check.sh`.
8. Write three lines to the reporter and four lines to the CTO.

Only then read the solution, `solutions/incident-NN-<slug>.md`, and compare: did you find the same cause, by which evidence, and was your fix riskier than it had to be?

**IDs.** The generators use the fixed lab clock, so every commit that exists when you enter a sandbox has the ID printed here and in the solution. Commits you create yourself get other IDs. Lines such as `[exit status: 1]` are printed by the replay scripts; by hand, run `echo $?`.

**Failure scenarios.** Each lab ends with a deliberate wrong move and its repair. Do that part after your own check has passed, on a freshly generated sandbox. It shows the recovery, so it spoils the drill if you read it first.

Answers to the Questions are in [solutions/m36-lab-answers.md](../solutions/m36-lab-answers.md). Write your own answers first.

## Lab 36.1: An accidental `git reset --hard` (incident 1)

### Objective

Recover a colleague's work after a hard reset, and tell him exactly which parts could and could not be recovered and why.

### Prerequisites

- [Chapter 13: Recovery](../textbook/ch13-recovery.md), sections 13.2, 13.3, 13.7 and 13.9.
- [Chapter 11: Reset, Revert, Restore](../textbook/ch11-reset-revert-restore.md), sections 11.4 to 11.6.

### Setup

```bash
incidents/01-hard-reset/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/01-hard-reset"     # or the path the generator printed
cat "<course root>/incidents/01-hard-reset/SYMPTOMS.md"
```

### Commands

No recovery commands are given. Start in `ravi/` with the evidence commands, then follow the procedure above.

```bash
cd ravi
git status -sb
git branch -vv
git log --oneline --graph --all
```

Three kinds of work are mentioned in the report. Decide for each one on which layer Git has it, if at all, before you try to recover it.

### Expected output

The state you should see on entry:

<!-- snippet: incidents/solve-01-hard-reset/01-observe -->
```text
$ cd ravi
$ git status -sb
## feature/escalation-rules
$ git branch -vv
* feature/escalation-rules 4e4c0b7 Mention escalation in the README
  main                     44fa655 [origin/main: behind 1] Add README
$ git log --oneline --graph --all
* 4e4c0b7 Mention escalation in the README
* 2876d93 Document how to run the tests
* 44fa655 Add README
* 43fb607 Add ticket classifier
```
<!-- /snippet -->

When you are done, `incidents/01-hard-reset/check.sh` prints nine `ok` lines and `PASS`.

### What happened internally

The cause is in the solution file, section 5, and you should find it yourself. What you can know beforehand: every value a branch ever had is in `.git/logs/refs/heads/<branch>`; content that was staged and never committed is a blob in `.git/objects` that no tree references; content that was never staged is in no file under `.git`.

### Checkpoint

Before you change anything, your notes contain: the ID of the lost tip and where you read it; an answer to "did `git pull` do this?" with the command that proves it; a three-row table of what was lost, with a layer for each row.

### Failure scenario

Generate the incident again. Then make the move that looks like an undo: reset the branch back to where it was before the accident.

<!-- snippet: incidents/lab-36-1-hard-reset/01-failure -->
```text
$ cd ravi
# The tempting move: put the branch back where it was before the accident.
$ git reset --hard 'feature/escalation-rules@{2}'
HEAD is now at 0322a16 Never escalate spam
$ git log --oneline
0322a16 Never escalate spam
a26c697 Route escalated tickets to the on-call queue
95d110d Add escalation predicate
44fa655 Add README
43fb607 Add ticket classifier
$ cd ..
$ incidents/01-hard-reset/check.sh
Checking incident 01-hard-reset
  ok    the commit "Add escalation predicate" is on feature/escalation-rules again
  ok    the commit "Route escalated tickets to the on-call queue" is on feature/escalation-rules again
  ok    the commit "Never escalate spam" is on feature/escalation-rules again
  FAIL  the commit made after the reset is still on the branch
  FAIL  the main commit "Document how to run the tests" appears 0 times on feature/escalation-rules (expected once)
  FAIL  the branch contains the current origin/main
  ok    triage/escalate.py in the last commit has the spam rule
  FAIL  rules/priority.yaml (staged, never committed) is not back in the working tree with its content
  ok    no operation is left in progress
NOT YET: 4 check(s) failed.
[exit status: 1]
```
<!-- /snippet -->

The three commits are back, and the check reports four failures: the commit made after the accident is gone, the branch is behind `main` again, and the staged file is still missing. A second hard reset repaired one loss by causing another.

### Recovery

<!-- snippet: incidents/lab-36-1-hard-reset/02-recovery -->
```text
$ cd ravi
$ git reflog show feature/escalation-rules -3
0322a16 feature/escalation-rules@{0}: reset: moving to feature/escalation-rules@{2}
4e4c0b7 feature/escalation-rules@{1}: commit: Mention escalation in the README
2876d93 feature/escalation-rules@{2}: reset: moving to origin/main
# The reflog also recorded the second reset. Name the old tip, undo the reset, then add:
$ git branch rescue/before-reset
$ git reset --keep 'feature/escalation-rules@{1}'
$ git cherry-pick origin/main..rescue/before-reset
[feature/escalation-rules 82d6626] Add escalation predicate
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:13:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 triage/escalate.py
[feature/escalation-rules e57429e] Route escalated tickets to the on-call queue
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:14:00 2026 +0530
 1 file changed, 1 insertion(+)
[feature/escalation-rules a8267b7] Never escalate spam
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:15:00 2026 +0530
 1 file changed, 2 insertions(+)
$ git fsck --lost-found
dangling blob 959c2056cb4f78bc321cf5bcf50cf2bf42d049bd
$ git cat-file -p $(ls .git/lost-found/other) > rules/priority.yaml
$ cd ..
$ incidents/01-hard-reset/check.sh
Checking incident 01-hard-reset
  ok    the commit "Add escalation predicate" is on feature/escalation-rules again
  ok    the commit "Route escalated tickets to the on-call queue" is on feature/escalation-rules again
  ok    the commit "Never escalate spam" is on feature/escalation-rules again
  ok    the commit made after the reset is still on the branch
  ok    no commit of main was copied
  ok    the branch contains the current origin/main
  ok    triage/escalate.py in the last commit has the spam rule
  ok    the staged file rules/priority.yaml is back with its content
  ok    no operation is left in progress
PASS: the recovery of incident 01-hard-reset is complete.
[exit status: 0]
```
<!-- /snippet -->

### Verification

`incidents/01-hard-reset/check.sh` exits 0. In `ravi/`, `git status -sb` shows `rules/priority.yaml` as untracked content to review and commit.

### Questions

1. Which line of which command proves that `git pull` was not involved?
2. Why must you write the recovered `rules/priority.yaml` back by hand under its path?
3. Why is the edit to `rules/routing.yaml` unrecoverable, while the new file is recoverable?
4. After the failure scenario, why does `git branch rescue/before-reset` without an ID anchor the right commit?
5. Which command should Ravi have used for what he wanted to do?

## Lab 36.2: A branch appears to have disappeared (incident 8)

### Objective

Establish what happened to a branch that is gone from the server and from a clone, state which work is safe and where, and publish the unmerged part so that its pull request shows that change only.

### Prerequisites

- Chapter 13, sections 13.3, 13.4 and 13.8 (a deleted branch).
- [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md), sections 17.8 and 17.12.

### Setup

```bash
incidents/08-branch-disappeared/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/08-branch-disappeared"
```

### Commands

No recovery commands are given. Start in `asha/`:

```bash
cd asha
git status -sb
git branch -a
git ls-remote origin
```

The report contains two statements of fact that you must test: "none of my commits are in `main`" and "I always push before I go home".

### Expected output

<!-- snippet: incidents/solve-08-branch-disappeared/01-observe -->
```text
$ cd asha
$ git status -sb
## main...origin/main
$ git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
$ git ls-remote origin
1a7ca10d4574f2b74570b1c78760a98c51498ce5	HEAD
1a7ca10d4574f2b74570b1c78760a98c51498ce5	refs/heads/main
```
<!-- /snippet -->

When you are done, the check prints eight `ok` lines and `PASS`.

### What happened internally

Find it yourself; the solution has it in sections 4 and 5. Known beforehand: deleting a branch deletes `.git/logs/refs/heads/<branch>` with it, and leaves `.git/logs/HEAD` alone.

### Checkpoint

Before you change anything: the ID of the last commit made on the lost branch; for each of its commits, whether its content is in `main`, decided by a comparison of trees; the name of the branch you will publish and what its pull request must show.

### Failure scenario

Generate the incident again. Recreate the branch under its old name and push it, as if it had never been merged.

<!-- snippet: incidents/lab-36-2-branch-disappeared/01-failure -->
```text
$ cd asha
# The tempting move: recreate the branch under its old name and push it.
$ git branch feature/prompt-versioning 70df7f7
$ git push origin feature/prompt-versioning
To ../server.git
 * [new branch]      feature/prompt-versioning -> feature/prompt-versioning
# What a pull request from it into main would show:
$ git log --oneline origin/main..origin/feature/prompt-versioning
70df7f7 Validate prompt variables before save
ceaa8bc Add version history
a93889a Load a prompt by version
c12fb6d Store every save as a new version
$ git diff --stat origin/main...origin/feature/prompt-versioning
 registry/history.py  | 2 ++
 registry/store.py    | 8 +++++---
 registry/validate.py | 9 +++++++++
 3 files changed, 16 insertions(+), 3 deletions(-)
$ cd ..
$ incidents/08-branch-disappeared/check.sh
Checking incident 08-branch-disappeared
  FAIL  the server has the branch feature/prompt-validation
  FAIL  the branch has "Validate prompt variables before save"
  FAIL  the branch is based on the current main
  FAIL  a pull request for the branch would list  commits (expected 1: the squashed work must not come back)
  FAIL  a pull request for the branch would change: nothing
  FAIL  registry/validate.py does not have the content of the lost commit
  ok    main on the server still ends with the squash merge
  FAIL  the merged branch was not pushed again
NOT YET: 7 check(s) failed.
[exit status: 1]
```
<!-- /snippet -->

A pull request from this branch would list four commits and three files, although three of the commits are already in `main` as one squashed commit.

### Recovery

<!-- snippet: incidents/lab-36-2-branch-disappeared/02-recovery -->
```text
$ cd asha
$ git push origin --delete feature/prompt-versioning
To ../server.git
 - [deleted]         feature/prompt-versioning
$ git switch -c feature/prompt-validation main
Switched to a new branch 'feature/prompt-validation'
$ git cherry-pick feature/prompt-versioning
[feature/prompt-validation e6535f5] Validate prompt variables before save
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:26:00 2026 +0530
 1 file changed, 9 insertions(+)
 create mode 100644 registry/validate.py
$ git push -u origin feature/prompt-validation
To ../server.git
 * [new branch]      feature/prompt-validation -> feature/prompt-validation
branch 'feature/prompt-validation' set up to track 'origin/feature/prompt-validation'.
$ git diff --stat feature/prompt-versioning feature/prompt-validation
$ git branch -D feature/prompt-versioning
Deleted branch feature/prompt-versioning (was 70df7f7).
$ cd ..
$ incidents/08-branch-disappeared/check.sh
Checking incident 08-branch-disappeared
  ok    the server has the branch feature/prompt-validation
  ok    the branch has "Validate prompt variables before save"
  ok    the branch is based on the current main
  ok    a pull request for the branch would list one commit
  ok    a pull request for the branch would change registry/validate.py only
  ok    registry/validate.py has the content of the lost commit
  ok    main on the server still ends with the squash merge
  ok    the merged branch was not pushed again
PASS: the recovery of incident 08-branch-disappeared is complete.
[exit status: 0]
```
<!-- /snippet -->

### Verification

`incidents/08-branch-disappeared/check.sh` exits 0, and `git diff --stat` between the old tip and the new branch prints nothing.

### Questions

1. Why did `git branch -d` refuse to delete a branch whose pull request had been merged?
2. `git cherry -v main <old tip>` marks all four commits with `+`. Why is that misleading here, and which command gives the reliable answer?
3. What can GitHub's **Restore branch** button bring back in this incident, and what can it not?
4. Which setting in Asha's clone made the remote-tracking branch vanish, and is that setting a mistake?
5. By default, how long would the only copy of the fourth commit have survived, and what determines that?

## Lab 36.3: A commit exists locally but not remotely (incident 10)

### Objective

Find where a commit is and where it is not, explain why three truthful local signals led to a wrong conclusion, and get the fix into the team repository without disturbing newer work.

### Prerequisites

- [Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md), sections 12.2, 12.5, 12.7, 12.10 and 12.14.

### Setup

```bash
incidents/10-commit-local-not-remote/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/10-commit-local-not-remote"
```

### Commands

No recovery commands are given. Start in `ravi/` by confirming or refuting each of his three statements:

```bash
cd ravi
git status -sb
git log --oneline -2
git branch -r --contains HEAD
```

In the sandbox the merge of a pull request is simulated by a fast-forward push to `main` of the team repository.

### Expected output

<!-- snippet: incidents/solve-10-commit-local-not-remote/01-ravi-is-right -->
```text
$ cd ravi
$ git status -sb
## main...origin/main
$ git log --oneline -2
f3bb790 Guard against NaN in score aggregation
133c159 Add accuracy panel
$ git branch -r --contains HEAD
  origin/HEAD -> origin/main
  origin/main
```
<!-- /snippet -->

When you are done, the check prints eight `ok` lines and `PASS`.

### What happened internally

Find it yourself. Known beforehand: `git status` compares a local branch with a remote-tracking ref under `.git/refs/remotes/`; it does not contact any server.

### Checkpoint

Before you change anything: a list of every repository this clone talks to; for each one, the ID of its `main`, obtained from the server and not from a remote-tracking ref; a statement of which commits each side has that the other lacks.

### Failure scenario

Generate the incident again. Push to the team repository, and when the push is rejected, force it.

<!-- snippet: incidents/lab-36-3-commit-local-not-remote/01-failure -->
```text
$ cd ravi
$ git push upstream main
To ../server.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
# The tempting move: it is "only" rejected, so force it.
$ git push --force upstream main
To ../server.git
 + ebd3afc...f3bb790 main -> main (forced update)
$ git ls-remote upstream main
f3bb79056b4293f31ae8479851be75b1f71339a6	refs/heads/main
$ cd ..
$ incidents/10-commit-local-not-remote/check.sh
Checking incident 10-commit-local-not-remote
  ok    main of the team repository has "Add score aggregation" exactly once
  ok    main of the team repository has "Add accuracy panel" exactly once
  FAIL  main of the team repository has "Show p95 latency on the dashboard" 0 times (expected once)
  ok    main of the team repository has "Guard against NaN in score aggregation" exactly once
  ok    dashboard/aggregate.py on main filters NaN
  FAIL  dashboard/panels.py on main still shows p95 latency
  FAIL  in ravi/, main follows origin/main (expected upstream/main)
  ok    main in ravi/ equals main of the team repository
NOT YET: 3 check(s) failed.
[exit status: 1]
```
<!-- /snippet -->

The fix is on the team's `main`, and a teammate's commit is gone from it. You have turned incident 10 into incident 2.

### Recovery

The recovery contains a second trap, which the transcript shows on purpose.

<!-- snippet: incidents/lab-36-3-commit-local-not-remote/02-recovery -->
```text
# The removed commit is still in the clone of the person who made it.
$ cd you
$ git fetch
From ../server
 + ebd3afc...f3bb790 main       -> origin/main  (forced update)
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git log --format='%h %an: %s' origin/main..main
ebd3afc Lab User: Show p95 latency on the dashboard
# A second trap. "git pull --rebase" looks like the way to put my commit on top:
$ git pull --rebase
Successfully rebased and updated refs/heads/main.
$ git log --oneline -3
f3bb790 Guard against NaN in score aggregation
133c159 Add accuracy panel
6e16f60 Add score aggregation
# My commit is gone from main. The rebase judged it to be part of the old upstream history
# (it is in the reflog of origin/main), so it did not replay it. ORIG_HEAD still names it:
$ git log --oneline -1 ORIG_HEAD
ebd3afc Show p95 latency on the dashboard
$ git cherry-pick ORIG_HEAD
[main 1c90db3] Show p95 latency on the dashboard
 Date: Mon Sep 7 10:19:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
To ../server.git
   f3bb790..1c90db3  main -> main
$ cd ../ravi
$ git fetch upstream
From ../server
   f3bb790..1c90db3  main       -> upstream/main
$ git branch --set-upstream-to=upstream/main main
branch 'main' set up to track 'upstream/main'.
$ git pull --ff-only
Updating f3bb790..1c90db3
Fast-forward
 dashboard/panels.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git config set remote.pushDefault upstream
$ cd ..
$ incidents/10-commit-local-not-remote/check.sh
Checking incident 10-commit-local-not-remote
  ok    main of the team repository has "Add score aggregation" exactly once
  ok    main of the team repository has "Add accuracy panel" exactly once
  ok    main of the team repository has "Show p95 latency on the dashboard" exactly once
  ok    main of the team repository has "Guard against NaN in score aggregation" exactly once
  ok    dashboard/aggregate.py on main filters NaN
  ok    dashboard/panels.py on main still shows p95 latency
  ok    in ravi/, main follows upstream/main (the team repository)
  ok    main in ravi/ equals main of the team repository
PASS: the recovery of incident 10-commit-local-not-remote is complete.
[exit status: 0]
```
<!-- /snippet -->

`git pull --rebase` printed "Successfully rebased" and left the removed commit off the branch. With no upstream named on the command line, the rebase starts from the fork point recorded in the reflog of `origin/main`; a commit that was once pushed counts as old upstream history. `ORIG_HEAD` kept the ID.

### Verification

`incidents/10-commit-local-not-remote/check.sh` exits 0. `git ls-remote upstream main` equals `git rev-parse main` in `ravi/`.

### Questions

1. Which single command would have shown Ravi, before he said "it is pushed", that the team repository lacked the commit?
2. Why did the push to `upstream` fail with `(fetch first)` and not with `(non-fast-forward)`?
3. In the recovery, why did `git pull --rebase` drop the commit, and which two places still named it?
4. What does `remote.pushDefault` change, and what does it leave unchanged?
5. Write the release-checklist line that would have caught this.

## Lab 36.4: A merge conflict is misunderstood (incident 9)

### Objective

Show where two merged fixes went, explain why the usual commands could not see it, and restore them on a shared branch without rewriting its history.

### Prerequisites

- [Chapter 8: Merge](../textbook/ch08-merge.md), sections 8.8, 8.10, 8.15 and 8.16.
- [Chapter 14A: History Investigation](../textbook/ch14a-history-investigation.md), section 14A.9 (path-limited `git log` and history simplification).

### Setup

```bash
incidents/09-misunderstood-conflict/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/09-misunderstood-conflict"
```

### Commands

No recovery commands are given. Start in `you/`:

```bash
cd you
git status -sb
cat limiter/bucket.py
git log --oneline --graph
```

Reproduce the command the reporter ran, `git log -- limiter/bucket.py`, and explain its output before you go on.

### Expected output

<!-- snippet: incidents/solve-09-misunderstood-conflict/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ cat limiter/bucket.py
DEFAULT_RATE = 100
BURST = 200


def allow(key, now):
    bucket = buckets.get(key)
    refill(bucket, now, rate_for(key))
    return bucket.take(1)


def refill(bucket, now, rate):
    bucket.tokens = bucket.tokens + (now - bucket.ts) * rate
    bucket.ts = now
```
<!-- /snippet -->

When you are done, the check prints twelve `ok` lines and `PASS`.

### What happened internally

Find it yourself. Known beforehand: a merge commit stores a complete tree like any other commit; nothing in Git verifies that this tree contains the changes of both parents.

### Checkpoint

Before you change anything: the ID of the commit in which the two changes were lost; the evidence that the loss is in that commit; a decision between rewriting, reverting and adding, with one reason for each rejected option.

### Failure scenario

Generate the incident again. Revert the pull request merge that "lost" the fix.

<!-- snippet: incidents/lab-36-4-misunderstood-conflict/01-failure -->
```text
$ cd you
# The tempting move: revert the pull request merge that "lost" the fix.
$ git revert --no-edit -m 1 fb67f49
[main a9477c9] Revert "Merge pull request #17 from feature/per-tenant-limits"
 Date: Mon Sep 7 10:32:00 2026 +0530
 2 files changed, 3 insertions(+), 7 deletions(-)
 delete mode 100644 limiter/tenants.py
$ git show --stat --format=%s HEAD
Revert "Merge pull request #17 from feature/per-tenant-limits"

 limiter/bucket.py  | 6 +++---
 limiter/tenants.py | 4 ----
 2 files changed, 3 insertions(+), 7 deletions(-)
$ ls limiter
bucket.py
metrics.py
$ cat limiter/bucket.py
RATE = 50
BURST = 200


def allow(key, now):
    bucket = buckets.get(key)
    refill(bucket, now, RATE)
    return bucket.take(1)


def refill(bucket, now, rate):
    bucket.tokens = min(BURST, bucket.tokens + (now - bucket.ts) * rate)
    bucket.ts = now
```
<!-- /snippet -->

The file now has Asha's two changes, because the per-tenant feature has been removed with them: `limiter/tenants.py` is gone. Then try to revert the merge that made the bad resolution:

<!-- snippet: incidents/lab-36-4-misunderstood-conflict/02-revert-inner-merge -->
```text
# Undo that (nothing was pushed), and try the merge that made the bad resolution:
$ git reset --keep origin/main
$ git revert --no-edit -m 1 d7497e2
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
[exit status: 1]
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

"Nothing to commit". Relative to its first parent, that merge changed nothing: this is the precise statement of what went wrong.

### Recovery

<!-- snippet: incidents/lab-36-4-misunderstood-conflict/03-recovery -->
```text
# The fix is a new commit, as in the solution:
$ git diff --stat
 limiter/bucket.py | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git commit -a -m 'Restore the burst cap and the lowered default rate'
[main 30202dc] Restore the burst cap and the lowered default rate
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git push
To ../server.git
   fc1898f..30202dc  main -> main
$ cd ..
$ incidents/09-misunderstood-conflict/check.sh
Checking incident 09-misunderstood-conflict
  ok    bucket.py on main caps the bucket at BURST
  ok    bucket.py on main has the lowered default rate under its new name
  ok    bucket.py on main still looks up the rate per tenant
  ok    bucket.py on main has no leftover "RATE = 50" or "DEFAULT_RATE = 100"
  ok    bucket.py on main has no conflict markers
  ok    limiter/tenants.py is still on main
  ok    main still has "Cap the bucket at BURST tokens" (history was not rewritten)
  ok    main still has "Halve the default rate after the overload" (history was not rewritten)
  ok    main still has "Look up the rate per tenant" (history was not rewritten)
  ok    main still has "Merge pull request #17 from feature/per-tenant-limits" (history was not rewritten)
  ok    main still has "Add limiter metrics" (history was not rewritten)
  ok    the faulty merge is still in the history of main
PASS: the recovery of incident 09-misunderstood-conflict is complete.
[exit status: 0]
```
<!-- /snippet -->

### Verification

`incidents/09-misunderstood-conflict/check.sh` exits 0. `git log --merges --oneline main` still lists both merges.

### Questions

1. Why does `git log -- limiter/bucket.py` omit the two commits, and which option shows them?
2. In `git show --remerge-diff`, which hunk proves that a whole file was taken from one side, and why?
3. In `git merge origin/main` on a feature branch, which side is "ours"? Which side is it during `git rebase origin/main`?
4. Why did reverting the inner merge with `-m 1` report "nothing to commit"?
5. Name one control that would have detected the loss before the pull request was merged.

## Lab 36.5: A developer rebases a shared branch (incident 5)

### Objective

Explain why a pull request lists every commit twice, rebuild the branch so that it contains each change once on top of the current base, and publish it without undoing a teammate's work.

### Prerequisites

- [Chapter 9: Rebase](../textbook/ch09-rebase.md), sections 9.3, 9.5, 9.14, 9.15 and 9.17.
- Chapter 12, section 12.8 (the lease forms).

### Setup

```bash
incidents/05-rebased-shared-branch/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/05-rebased-shared-branch"
```

### Commands

No recovery commands are given. Start in `you/`:

```bash
cd you
git status -sb
git fetch
git log --oneline --graph origin/main feature/online-serving
```

Then produce the two views of the pull request: the commit list (`main..head`) and the changed files (`main...head`).

### Expected output

<!-- snippet: incidents/solve-05-rebased-shared-branch/01-state -->
```text
$ cd you
$ git status -sb
## feature/online-serving...origin/feature/online-serving
$ git fetch
$ git log --oneline --graph origin/main feature/online-serving
*   6e7ebbd Merge branch 'feature/online-serving' of ../server into feature/online-serving
|\  
| * d4fd03c Add cache warm-up job
| * 5e57ed9 Decode online values
| * c8d1712 Add online lookup
| * 8131d29 Lower the TTL to 15 minutes
* | 57b5972 Decode batched values
* | af1f6de Add batched online lookup
* | 4967e71 Add cache warm-up job
* | 8f79c42 Decode online values
* | be7fb7a Add online lookup
|/  
* 65cb28c Add store config
* c587823 Add feature lookup
```
<!-- /snippet -->

When you are done, the check prints thirteen `ok` lines and `PASS`. Chapter 30, section 30.16 walks through this incident in eleven steps; read it after your attempt.

### What happened internally

Find it yourself. Known beforehand: a rebased commit is a new object with a new ID; your clone records every value of `origin/<branch>` it has seen in `.git/logs/refs/remotes/origin/<branch>`.

### Checkpoint

Before you change anything: three commit IDs with their sources (the shared tip before the rebase, the rebased tip, your tip before the pull); proof that the two series carry the same changes; two rescue branches.

### Failure scenario

Generate the incident again. "Undo" the duplicates by going back to your tip from before the pull and forcing it.

<!-- snippet: incidents/lab-36-5-rebased-shared-branch/01-failure -->
```text
$ cd you
# The tempting move: go back to my tip from before the pull and force it.
$ git reset --hard 'feature/online-serving@{1}'
HEAD is now at 57b5972 Decode batched values
$ git push --force
To ../server.git
 + 6e7ebbd...57b5972 feature/online-serving -> feature/online-serving (forced update)
$ git log --oneline origin/main..origin/feature/online-serving
57b5972 Decode batched values
af1f6de Add batched online lookup
4967e71 Add cache warm-up job
8f79c42 Decode online values
be7fb7a Add online lookup
$ git merge-base --is-ancestor origin/main origin/feature/online-serving
[exit status: 1]
# Asha's view after her next fetch:
$ git -C ../asha fetch
From ../server
 + d4fd03c...57b5972 feature/online-serving -> origin/feature/online-serving  (forced update)
$ git -C ../asha status -sb
## feature/online-serving...origin/feature/online-serving [ahead 4, behind 5]
$ cd ..
$ incidents/05-rebased-shared-branch/check.sh
Checking incident 05-rebased-shared-branch
  ok    the server still has the branch
  ok    "Add online lookup" is on the branch exactly once
  ok    "Decode online values" is on the branch exactly once
  ok    "Add cache warm-up job" is on the branch exactly once
  ok    "Add batched online lookup" is on the branch exactly once
  ok    "Decode batched values" is on the branch exactly once
  ok    the branch has five commits that main does not have
  ok    the branch contains no merge commit
  FAIL  the branch is based on the current main
  ok    store/batch.py decodes values
  ok    store/warm.py is on the branch
  ok    the branch in you/ equals the branch on the server
  FAIL  the branch in asha/ differs from the branch on the server
NOT YET: 2 check(s) failed.
[exit status: 1]
```
<!-- /snippet -->

Five commits, no duplicates, and the branch no longer contains the current `main`: you have undone Asha's rebase, and her clone is now four ahead and five behind.

### Recovery

<!-- snippet: incidents/lab-36-5-rebased-shared-branch/02-recovery -->
```text
$ cd you
# The rebased tip is still in my object database and in my reflog of origin/...:
$ git reflog show origin/feature/online-serving -3
57b5972 refs/remotes/origin/feature/online-serving@{0}: update by push
6e7ebbd refs/remotes/origin/feature/online-serving@{1}: update by push
d4fd03c refs/remotes/origin/feature/online-serving@{2}: pull: forced-update
$ git rebase --onto d4fd03c 4967e71
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/online-serving.
$ git push --force-with-lease=feature/online-serving:57b5972 origin feature/online-serving
To ../server.git
 + 57b5972...9d65651 feature/online-serving -> feature/online-serving (forced update)
$ git -C ../asha pull --ff-only
From ../server
 + 57b5972...9d65651 feature/online-serving -> origin/feature/online-serving  (forced update)
Updating d4fd03c..9d65651
Fast-forward
 store/batch.py | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 store/batch.py
$ cd ..
$ incidents/05-rebased-shared-branch/check.sh
Checking incident 05-rebased-shared-branch
  ok    the server still has the branch
  ok    "Add online lookup" is on the branch exactly once
  ok    "Decode online values" is on the branch exactly once
  ok    "Add cache warm-up job" is on the branch exactly once
  ok    "Add batched online lookup" is on the branch exactly once
  ok    "Decode batched values" is on the branch exactly once
  ok    the branch has five commits that main does not have
  ok    the branch contains no merge commit
  ok    the branch is based on the current main
  ok    store/batch.py decodes values
  ok    store/warm.py is on the branch
  ok    the branch in you/ equals the branch on the server
  ok    the branch in asha/ equals the branch on the server
PASS: the recovery of incident 05-rebased-shared-branch is complete.
[exit status: 0]
```
<!-- /snippet -->

### Verification

`incidents/05-rebased-shared-branch/check.sh` exits 0, and `git log --oneline origin/main..origin/feature/online-serving` lists five commits.

### Questions

1. Why do the commit list and the changed-files view of the same pull request disagree?
2. `--force-with-lease` succeeded for Asha. What does a lease protect, and what did it not protect here?
3. In `git rebase --onto <new> <old>`, what do the two arguments select?
4. How can you prove before publishing that the rebuilt branch changes history and no content?
5. Which `pull` configuration would have prevented the incident, and through which mechanism?
