# Answer key, Gate 9: Production debugging

> **For the examiner.** This file holds the model answers, the marking guidance and the real outputs for [Gate 9](../assessments/gate-9-production-debugging.md). A learner who has failed the gate does not get this file: they get the remediation map in the gate file and variant B. Every transcript is real output of a script under `labs/gates/` on Git 2.55.0. Statements about GitHub are taken from the textbook sections named in the reference lines.

**Marking, in general.** This gate marks judgment. A correct command used before the evidence was collected is worth less than the same command after it. In the hands-on part, a correct end state reached through a forced push, a reset of a shared branch or an untested assumption fails the safety row whatever `check.sh` says. In every written answer, "be more careful" earns nothing as prevention.

---

## Part 1: Concepts

### C1 (5 points)

**Model answer.** Phase 1, read-only: symptom, observe, collect evidence, understand the state, form hypotheses, test them, identify the root cause. Only commands that read. Phase 2, preserve: record the output, create a backup ref, copy the repository or make a bundle; this adds refs and files and destroys nothing. Phase 3, change: select the lowest-risk fix, execute it one step at a time with a preview, verify with the same commands, prevent. Phase 3 is the first moment a ref moves or a file is overwritten. The places: working tree (`git status`, `git diff`); index (`git diff --cached`, `git ls-files -u`); `HEAD` (`git symbolic-ref HEAD`, and is an operation in progress); refs and their upstreams (`git branch -vv`, `git for-each-ref`); the history of the refs (`git reflog`); the server as it is now and not as of the last fetch (`git ls-remote origin`); and what the platform recorded. Three hypotheses, because the first explanation that fits is usually the one the reporter already offered, and a single hypothesis is confirmed by whatever you look at; with three you need a command that separates them, which is a test. The copy: a repair can be rehearsed on a copy first, and the original remains as evidence.

**Marking.** 1 point: three phases with their permissions. 1 point: the boundary (first moved ref or overwritten file). 1 point: at least five places with a command each, the server among them. 1 point: why three hypotheses. 1 point: rehearsal on a copy.

**Common wrong answers.** "First try the obvious fix." "Check `git status` and `git log`" as the whole list. Leaving out the server.

**Reference.** Chapter 29, section 29.2; Chapter 1, sections 1.10 and 1.11.

### C2 (5 points)

**Model answer.** The local branch (`git rev-parse <branch>`), the remote-tracking branch in the same clone (`git rev-parse origin/<branch>`, as fresh as the last fetch or push), and the branch on the server (`git ls-remote origin <branch>`). States that produce the sentence: (1) the commit is on another local branch, or on a detached `HEAD`, and the push named a branch that did not hold it, so "Everything up-to-date" was true for that branch: `git branch -a --contains <commit>` shows where it is. (2) The push went to a different destination than the developer thinks: another remote, or the branch's upstream has a different name: `git rev-parse --abbrev-ref @{upstream} @{push}` and the last lines of the push output. (3) The push was rejected or never ran, and the developer read the remote-tracking ref, or the page of another branch: `git status -sb` shows "ahead", and `git ls-remote` shows the old ID. (4) The commit was pushed and then replaced on the server by someone's forced push: `git ls-remote` differs from `origin/<branch>`, and after a fetch the reflog of `origin/<branch>` shows a forced update. GitHub does not cache branch tips; compare IDs, not names.

**Marking.** 1 point: the three places with read-only commands. 3 points: three distinct states with the separating command each. 1 point: "compare IDs", or the explicit rejection of the cache theory.

**Common wrong answers.** "Wait a few minutes." "Push again with force." Naming only local and "GitHub".

**Reference.** Chapter 29, sections 29.3 and 29.4; Chapter 12, sections 12.4 and 12.14.

### C3 (5 points)

**Model answer.** The questions, in order: does it destroy uncommitted work; does it rewrite commits that another repository has; does it change the server; is it undone by one command; can it be previewed. (a) and (c) both rewrite published history: every clone that has the three later commits diverges, the deployed commit stops being an ancestor of the branch, and both need a forced push that the rules of a deployed branch should refuse. (a) additionally discards the three later commits unless they are re-applied. (b) adds one commit, rewrites nothing, is undone by reverting it, and can be previewed with `git diff <merge>^1 <merge>`. Take (b). Its later cost: the merge stays in the graph, so the reverted commits count as already merged; if that side is ever to be merged again, or if this branch is merged into the branch the content came from, the revert travels with it and removes the content there. Record that, and resolve it by reverting the revert at the right time. What would change the choice: if the merge had not been pushed, a local reset to `ORIG_HEAD` or the reflog entry is cleaner; if the content must not exist in history at all, for example an unrotatable secret, a rewrite becomes an operation of its own with a freeze.

**Marking.** 1 point: the questions. 2 points: (b), with the reasons against (a) and (c). 1 point: the later cost. 1 point: a condition that changes the choice.

**Common wrong answers.** "(c), because `--force-with-lease` is safe." "(b) has no downside."

**Reference.** Chapter 29, section 29.9; Chapter 11, section 11.9.

### C4 (5 points)

**Model answer.** (1) Who pushed this commit or this forced update? A commit records an author and a committer, which are typed text; it does not record the account that pushed. Source: the repository's Activity view, which lists pushes, force pushes and branch changes with the authenticated user; limit: it covers the repository's refs, not who fetched. (2) What did the branch point at before the forced push, when nobody fetched in between? A bare repository keeps no reflog by default and you cannot run `git reflog` on GitHub's copy. Source: the Activity view's before and after, or the Events API `PushEvent` with `before` and `head`; limit: a bounded number of recent events. (3) Was a rule evaluated, passed or bypassed for this update? Source: Rule Insights; limit: only for refs that a ruleset targets, and the audit log's Git events are retained for a short time and only on Enterprise. Also valid: what a pull request showed at the time of approval (the pull request timeline). The colleague's clone: its reflogs, including the reflog of its remote-tracking branches, record what that person's commands did and what the server held at their last fetch; and unreachable commits there may be the only copy of lost work. Ask them not to run `git gc`, not to re-clone, not to delete the directory, and not to "tidy up" before you have looked.

**Marking.** 1 point per question with reason, source and limit (3). 1 point: the colleague's reflog as evidence. 1 point: what to ask them not to do.

**Common wrong answers.** "`git log` shows who pushed." "GitHub has a reflog I can read." "The author of the commit did it."

**Reference.** Chapter 29, sections 29.7 and 29.8; Chapter 13, sections 13.10 and 13.15.

### C5 (5 points)

**Model answer.** Local reset: SEV 4, one person's local work; the person, and nobody else unless a habit needs changing. Live credential on a public repository: SEV 1; the CTO and security at once, before any Git work, because the first action is rotation. Rebased shared feature branch: SEV 3, a team is blocked and no wrong content is on a protected branch; the team, the lead on request. Fix silently lost and shipped: wrong code reached production, so SEV 1 by the definition (it would be SEV 2 if caught before or shortly after release); the engineering lead at once and the CTO. The summary: (1) what happened: impact first, in business terms, times with a time zone, no names; (2) root cause: one sentence with the layer named (a Git default, a missing GitHub rule, an Actions default); (3) what was done and how it was verified: the recovery in one sentence, the check that proves it, and what is not yet verified; (4) prevention: the control, its owner, its date. It fits on one screen and contains no commands.

**Marking.** 2 points: four classifications (three right 1). 1 point: who is told for the SEV 1 cases. 2 points: the four parts with their rules (parts only 1).

**Common wrong answers.** Rating by how upset the reporter is. A summary that begins with the timeline of commands. Names in the summary.

**Reference.** Chapter 30, sections 30.3 and 30.15.

### C6 (5 points)

**Model answer.** A control is something that still works when the person is new, tired or in a hurry; an appeal to care decays and does not reach the next hire. Strengths: (1) the server refuses, for example a ruleset that blocks force pushes; (2) automation checks, for example a release job's ancestry test or push protection; (3) a safe default on the client, for example `push.default=simple`; (4) a step in a checklist or review, for example reading the commit list of a pull request; (5) training and habit. For "the release branch accepted a merge of `main`": the strongest available control is on the server, a ruleset for `release/**` that requires a pull request and linear history, so that a merge commit cannot land and every change is a reviewed, cherry-picked commit; I know it works by trying a merge push against a test branch and reading Rule Insights. A weaker one that I add anyway: a pipeline check on release branches that fails when the diff against the last release tag touches paths outside an allow-list, or when `git log --merges <tag>..HEAD` is not empty; I know it works because it fails on the incident's commit. Prefer one strong control to five weak ones. Blameless: the postmortem treats each person's action as reasonable given what they knew and explains how the system allowed the outcome. It is a technical requirement because the evidence comes from people (reflogs, accounts of what they typed), and people who expect blame run `git gc`, re-clone or stay silent. The test: replace every name by a role; if the document still explains the incident, it is about the system.

**Marking.** 1 point: why care is not a control. 1 point: five strengths in order. 1 point: a server-side control with its verification. 1 point: a second control with its verification. 1 point: blameless, with the reason and the test.

**Common wrong answers.** "More training." A list of ten actions with no ranking. "Blameless means nobody is responsible."

**Reference.** Chapter 30, sections 30.19 and 30.20.

---

## Part 2: Prediction

### P1 (5 points)

<!-- snippet: gates/g9-predict/p1-answer-a -->
```text
$ git status
On branch main
Cherry-pick currently in progress.
  (run "git cherry-pick --continue" to continue)
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

nothing to commit, working tree clean
$ git log --format=%s -3
Fix A: add retries
Tune the limit
Add limits
$ ls .git | grep -E "CHERRY|sequencer" || echo "(none of these exist)"
sequencer
```
<!-- /snippet -->

`git reset --hard` cleaned the index and the working tree and removed `CHERRY_PICK_HEAD`, so the conflicted pick of Fix B is gone. It did not remove `.git/sequencer`, which still lists Fix C. `git status` therefore reports a cherry-pick in progress and a clean tree.

<!-- snippet: gates/g9-predict/p1-answer-b -->
```text
$ git log --format=%s -4
Fix C: add a timeout
Fix A: add retries
Tune the limit
Add limits
$ cat limits.yaml
limit: 15
$ git status -sb
## main
```
<!-- /snippet -->

`--continue` finds nothing to commit for the interrupted pick and goes on to the next instruction: Fix C is applied. Fix B is on neither `main` nor in any message: the limit is still 15, and every command exited with status 0. The correct way out of the conflict was `git cherry-pick --abort` (back to before the sequence) or resolving and continuing.

**Marking.** 1 point: "Cherry-pick currently in progress" with a clean tree. 1 point: A, "Tune the limit", "Add limits". 2 points: C, A, "Tune the limit", "Add limits", and `limit: 15`. 1 point: Fix B is missing and nothing said so.

**Reference.** Chapter 29, section 29.6; Chapter 10, section 10.6.

### P2 (5 points)

<!-- snippet: gates/g9-predict/p2-answer -->
```text
$ git ls-files
core.txt
$ git merge-base --is-ancestor feature/invoices main
[exit status: 0]
$ git branch --merged main
  feature/invoices
* main
$ git merge feature/invoices
Already up to date.
$ git ls-files
core.txt
```
<!-- /snippet -->

The revert removed `invoices.txt` and left the merge in the graph. The branch is still an ancestor of `main` and is listed as merged, so merging it again does nothing: "Already up to date", and the file stays absent. Reachability says "merged"; the content says "not there".

**Marking.** 1 point: `core.txt` only. 2 points: exit status 0 and the branch listed as merged. 2 points: "Already up to date." and `core.txt` only.

**Reference.** Chapter 11, section 11.9; Chapter 30, section 30.13.

### P3 (5 points)

<!-- snippet: gates/g9-predict/p3-answer-a -->
```text
$ git push --force-with-lease --force-if-includes origin feature/cache
To ../server.git
 ! [rejected]        feature/cache -> feature/cache (remote ref updated since checkout)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout. If you want to integrate the
hint: remote changes, use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git -C ../server.git log --format=%s feature/cache
Asha: add cache metrics
Add cache
Add service
```
<!-- /snippet -->

The fetch moved `origin/feature/cache` to Asha's commit. With `--force-if-includes` Git also requires that the tip of the remote-tracking ref is reachable from a reflog entry of the local branch: it is not, the local branch never contained her commit, and the push is rejected.

<!-- snippet: gates/g9-predict/p3-answer-b -->
```text
$ tail -1 push.log
exit status: 0
$ git -C ../server.git log --format=%s feature/cache
Add cache with eviction
Add service
$ git log -g --format='%h %gs' origin/feature/cache
3cdc416 update by push
067bab3 fetch -q: fast-forward
431c62b update by push
```
<!-- /snippet -->

The lease alone compares the server's ref with the remote-tracking ref. The fetch made them equal, so the condition "nothing changed since I looked" holds and Asha's commit is overwritten. It still exists in Asha's clone, in the reflog of your `origin/feature/cache` (the middle entry), and on the server as an unreachable object.

**Marking.** 2 points: rejected, status 1, three subjects with Asha's on top. 2 points: status 0, two subjects, Asha's gone. 1 point: at least two of the three places.

**Reference.** Chapter 12, section 12.8 (root-cause box); Chapter 30, sections 30.6 and 30.8.

### P4 (5 points)

<!-- snippet: gates/g9-predict/p4-answer -->
```text
$ git fetch
From ../server
   31878e7..ed42dfa  main       -> origin/main
$ git log -1 --format=%s 'v1.4.0^{commit}'
Release candidate
$ git fetch --tags
From ../server
 ! [rejected] v1.4.0     -> v1.4.0  (would clobber existing tag)
[exit status: 1]
$ git log -1 --format=%s 'v1.4.0^{commit}'
Release candidate
$ git ls-remote origin 'refs/tags/v1.4.0^{}' | cut -f1 | xargs git log -1 --format=%s
Late fix
```
<!-- /snippet -->

A plain fetch updates `origin/main` and does not touch an existing tag. `git fetch --tags` asks for the tag explicitly and is rejected: "would clobber existing tag", exit status 1. The local tag still names "Release candidate"; the server's names "Late fix". A build "of v1.4.0" in a clone made before the move contains one commit, a build in a fresh clone another, under the same name. A published tag must not move; the repair is a new version.

**Marking.** 1 point: `origin/main` moves, the tag does not. 2 points: the rejection with a non-zero status and the unchanged local tag. 1 point: "Late fix" on the server. 1 point: two builds with one name.

**Reference.** Chapter 14B, sections 14B.10 and 14B.11 (root-cause box).

---

## Part 3: Hands-on diagnosis

**End state (10 points).** Run `check.sh`. 10 points for `PASS`; otherwise 10 minus the number of `FAIL` lines, not below zero.

**Safety of the path (8 points).**

| Points | Evidence in the log |
|---|---|
| 2 | A read-only phase that includes `git fetch` or `git ls-remote` before any conclusion about the server |
| 2 | Each colleague's statement tested with a command before it is accepted or dismissed |
| 2 | A preservation step (a backup ref, or an explicit statement that nothing is rewritten and why) and a preview of the repair (`git diff`, `git merge-tree`, `--dry-run`) before the first change |
| 2 | No forced push, no moved tag, no `git reset` of a shared branch; the push verified by comparing IDs with `git ls-remote` or `git status -sb` after a fetch |

**Diagnosis (6 points).** 3 points for the verdicts with their commands. 3 points for the root-cause box: state, mechanism, root cause with its layer.

**Communication and prevention (6 points).** 3 points: the four-part summary, in order, impact first, no names, no commands, severity with reason, stating what is not yet verified. 2 points: a control with its strength and how one will know it works. 1 point: the consequence that `SYMPTOMS.md` asks for.

### Variant A (`storefront-api`): model solution

<!-- snippet: gates/solve-g9-a/01-observe -->
```text
# PHASE 1: read-only
$ cd you
$ git status -sb
## main...origin/main
$ git fetch
$ git ls-remote origin
ac1adb6d7c35da94db06971d464137a2d18e173e	HEAD
ac1adb6d7c35da94db06971d464137a2d18e173e	refs/heads/main
52a3950a606678f1e606a0c2279ca26654889321	refs/heads/release/2.2
8d0f21835e49cf362f347ec50eabed0d7c52ee0b	refs/tags/v2.2.0
b1c5bf0dad7387dbe10648dbeb9ce7092b12b58a	refs/tags/v2.2.0^{}
419f212a6d4a7506214bc97e238d52e2638096fc	refs/tags/v2.2.1
23db7c9e55f8fd08c9b840f55f62f2280dab4e9b	refs/tags/v2.2.1^{}
```
<!-- /snippet -->

<!-- snippet: gates/solve-g9-a/02-what-is-on-the-branch -->
```text
$ git log --graph --format='%h %an: %s' v2.2.1..origin/release/2.2
* 52a3950 Ravi Menon: Pin the base image for 2.2.2
* cf4d345 Asha Rao: Merge remote-tracking branch 'origin/main' into release/2.2
* ac1adb6 Lab User: Start the 2.3 changelog
* bfae860 Lab User: Fix currency rounding for half cents
* 74fdcbf Lab User: Apply the wallet balance in the total
* 57d514a Lab User: Add wallet payments behind a flag
$ git diff --stat v2.2.1 origin/release/2.2
 Dockerfile           | 2 ++
 checkout/rounding.py | 4 +++-
 checkout/total.py    | 7 +++++--
 checkout/wallet.py   | 4 ++++
 docs/CHANGELOG.md    | 5 +++++
 5 files changed, 19 insertions(+), 3 deletions(-)
```
<!-- /snippet -->

Since `v2.2.1` the release branch has gained six commits, four of them from `main`, and five files have changed. QA is right.

<!-- snippet: gates/solve-g9-a/03-how-it-got-there -->
```text
$ git log --first-parent --format='%h %an: %s (parents: %p)' v2.2.1..origin/release/2.2
52a3950 Ravi Menon: Pin the base image for 2.2.2 (parents: cf4d345)
cf4d345 Asha Rao: Merge remote-tracking branch 'origin/main' into release/2.2 (parents: 23db7c9 ac1adb6)
$ git show -s --format='%s%n  parents: %p' cf4d345
Merge remote-tracking branch 'origin/main' into release/2.2
  parents: 23db7c9 ac1adb6
$ git log -1 --format='%h %s' cf4d345^1
23db7c9 Release 2.2.1
$ git log -1 --format='%h %s' cf4d345^2
ac1adb6 Start the 2.3 changelog
$ git branch -r --contains bfae860
  origin/HEAD -> origin/main
  origin/main
  origin/release/2.2
$ git log --oneline cf4d345^1..cf4d345^2
ac1adb6 Start the 2.3 changelog
bfae860 Fix currency rounding for half cents
74fdcbf Apply the wallet balance in the total
57d514a Add wallet payments behind a flag
```
<!-- /snippet -->

Along the first parent, the branch has two commits since the tag: Asha's merge of `origin/main` and Ravi's base-image commit. The merge has two parents: "Release 2.2.1" and the tip of `main`. It brought everything on `main` that the release branch did not have: four commits.

**The verdicts.**

| Statement | Verdict | Deciding command |
|---|---|---|
| QA: the candidate contains wallet code | Right | `git diff --stat v2.2.1 origin/release/2.2` |
| Ravi: CI built the wrong branch | Wrong about the cause, right about the observation. The commit CI printed does have a parent on `main`: it is, or descends from, a merge commit on the release branch. The runner built exactly what the branch holds. A re-run builds the same commit | `git log --first-parent ... v2.2.1..origin/release/2.2` with the parents |
| Asha: "one commit, I did not touch wallet" | Right about the intent, wrong about the result. She wanted one commit and merged the branch that contains it. A merge brings every commit the other side has | `git log --oneline <merge>^1..<merge>^2` lists four |
| Release manager: reset to `v2.2.1` and redo | Wrong repair. It rewrites a shared branch, needs a forced push, and discards Ravi's commit, which was made after the merge and is legitimate | `git log --first-parent` shows Ravi's commit on top |

**Root cause.**

```text
Observed behavior : The 2.2.2 release candidate contains the unreleased wallet feature.
Git state         : release/2.2 has a merge commit whose second parent is the tip of main;
                    four commits of main are reachable from the release branch.
Mechanism         : git merge integrates everything reachable from the other tip that the
                    current branch lacks. It cannot bring "one commit".
Root cause        : A fix was moved between branches with a merge of the whole source branch
                    where a cherry-pick of one commit was meant. Layer: Git usage; and on the
                    platform layer no rule stopped a merge commit from landing on release/**.
Why Git does this : A merge joins two histories. Selecting single changes is what cherry-pick is for.
Correct fix       : Revert the merge with -m 1 on the release branch, then cherry-pick -x the fix.
Prevention        : A ruleset for release/** that requires pull requests and linear history.
```

<!-- snippet: gates/solve-g9-a/04-preserve -->
```text
# PHASE 2: preserve
$ git switch release/2.2
Switched to branch 'release/2.2'
Your branch is behind 'origin/release/2.2' by 6 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)
$ git merge --ff-only origin/release/2.2
Updating 23db7c9..52a3950
Fast-forward
 Dockerfile           | 2 ++
 checkout/rounding.py | 4 +++-
 checkout/total.py    | 7 +++++--
 checkout/wallet.py   | 4 ++++
 docs/CHANGELOG.md    | 5 +++++
 5 files changed, 19 insertions(+), 3 deletions(-)
 create mode 100644 Dockerfile
 create mode 100644 checkout/wallet.py
 create mode 100644 docs/CHANGELOG.md
$ git branch rescue/release-2.2-before-repair
# Rehearse: what would undoing the merge leave?
$ git diff --stat cf4d345^1 cf4d345
 checkout/rounding.py | 4 +++-
 checkout/total.py    | 7 +++++--
 checkout/wallet.py   | 4 ++++
 docs/CHANGELOG.md    | 5 +++++
 4 files changed, 17 insertions(+), 3 deletions(-)
```
<!-- /snippet -->

<!-- snippet: gates/solve-g9-a/05-revert -->
```text
# PHASE 3: change
$ git revert -m 1 --no-edit cf4d345
[release/2.2 d8eac52] Revert "Merge remote-tracking branch 'origin/main' into release/2.2"
 Date: Mon Sep 7 10:51:00 2026 +0530
 4 files changed, 3 insertions(+), 17 deletions(-)
 delete mode 100644 checkout/wallet.py
 delete mode 100644 docs/CHANGELOG.md
$ git diff --stat v2.2.1 HEAD
 Dockerfile | 2 ++
 1 file changed, 2 insertions(+)
$ git cherry-pick -x bfae860
[release/2.2 8a350b6] Fix currency rounding for half cents
 Date: Mon Sep 7 10:19:00 2026 +0530
 1 file changed, 3 insertions(+), 1 deletion(-)
$ git log -1 --format=%B
Fix currency rounding for half cents

(cherry picked from commit bfae860f0b6d6a8a7d6e1f6c0fbb90deba35d070)
```
<!-- /snippet -->

`git revert -m 1` undoes what the merge brought relative to its first parent, the release side. After it, the branch differs from `v2.2.1` by Ravi's `Dockerfile` only. The fix is then copied with `-x`, which records the ID of the commit on `main`.

<!-- snippet: gates/solve-g9-a/06-verify -->
```text
$ git diff --stat v2.2.1 HEAD
 Dockerfile           | 2 ++
 checkout/rounding.py | 4 +++-
 2 files changed, 5 insertions(+), 1 deletion(-)
$ git log --format='%h %an: %s' origin/release/2.2..HEAD
8a350b6 Lab User: Fix currency rounding for half cents
d8eac52 Lab User: Revert "Merge remote-tracking branch 'origin/main' into release/2.2"
$ git ls-tree -r --name-only HEAD
Dockerfile
VERSION
checkout/rounding.py
checkout/total.py
$ git push origin release/2.2
To ../server.git
   52a3950..8a350b6  release/2.2 -> release/2.2
$ git status -sb
## release/2.2...origin/release/2.2
```
<!-- /snippet -->

**What goes wrong weeks from now.** The merge is still in the graph of `release/2.2`, and the revert is a change on that branch that deletes the wallet files. If `release/2.2` is ever merged into `main` (some release strategies merge fixes upward), Git sees: `main` did not change those files since the merge base, the release branch deleted them. The deletion wins, without a conflict:

<!-- snippet: gates/solve-g9-a/07-the-trap -->
```text
# Weeks from now: release/2.2 merged into main would carry the revert with it.
$ git ls-tree -r --name-only origin/main
VERSION
checkout/rounding.py
checkout/total.py
checkout/wallet.py
docs/CHANGELOG.md
# The tree that a merge of release/2.2 into main would produce:
$ git ls-tree -r --name-only "$(git merge-tree --write-tree origin/main release/2.2)"
Dockerfile
VERSION
checkout/rounding.py
checkout/total.py
$ git branch -D rescue/release-2.2-before-repair
Deleted branch rescue/release-2.2-before-repair (was 52a3950).
$ cd ..
$ assessments/gen/gate-9-production-debugging/variant-a/check.sh
Checking g9-a
  ok    the history of release/2.2 on the server was not rewritten
  ok    release/2.2 no longer contains the wallet feature
  ok    release/2.2 no longer contains the 2.3 changelog
  ok    checkout/total.py on release/2.2 is the file of v2.2.1
  ok    release/2.2 has the rounding fix
  ok    Ravi's commit is still on release/2.2
  ok    a commit on release/2.2 reverts the merge and names it
  ok    the fix on release/2.2 names the commit on main it was copied from
  ok    no further merge was added to release/2.2
  ok    main on the server has not moved
  ok    the tag v2.2.1 has not moved
  ok    your release/2.2 equals the server
  ok    nothing is staged, modified or untracked in you/
  ok    no operation is left in progress
PASS: the end state of g9-a is right.
[exit status: 0]
```
<!-- /snippet -->

A merge of `release/2.2` into `main` would remove `checkout/wallet.py` and `docs/CHANGELOG.md` from `main`. Record today, on the release branch's page and in the incident record: "`release/2.2` must not be merged into `main`; fixes travel by `cherry-pick -x`. If a merge upward is ever needed, revert the revert on `main` directly afterwards."

**The summary (model).**

```text
Subject: [Resolved] storefront-api: release branch 2.2 contained unreleased code (SEV 2, not shipped)
What happened   From Tuesday until today 12:30 IST the branch release/2.2 contained four changes meant
                for 2.3, among them wallet payments. The 2.2.2 release candidate built from it was
                stopped by QA before release. Production (2.2.1) was never affected.
Root cause      Git, usage: a fix was brought to the release branch by merging main, which brings
                every change on main. GitHub: no rule prevents a merge commit on release branches.
What was done   The merge was reverted on the release branch and the one fix was copied over with a
                reference to its origin; no history was rewritten. Verified: the branch now differs
                from 2.2.1 in two files, the base image and the rounding fix, on the server.
                Not yet verified: a new release candidate has to be built and pass QA.
Prevention      A ruleset on release/** requiring pull requests and linear history (owner: platform
                lead, this week), and a note that release/2.2 must never be merged into main.
```

Severity: SEV 2, a shared release branch held wrong content, caught before release. A candidate who argues SEV 1 must show that wrong code reached production; it did not.

**Control.** Strength 1, the server refuses: a ruleset on `release/**` with "require a pull request" and "require linear history". Known to work when a test push of a merge commit is rejected.

**Partial credit and common mistakes, variant A.**

- Reset and forced push: not available here; a candidate who tries, or who recommends it in writing, loses the safety row for it and the diagnosis point for the release manager's statement.
- Reverting the four commits of `main` one by one with `git revert <commit>`: the content is right. The check fails on the line that asks for a commit naming the merge. 6 or more of 10 for the end state; the explanation must say why `-m 1` on the merge is the single, traceable undo.
- Reverting the merge and forgetting the fix: one line fails; Asha's legitimate need was the reason for the incident.
- Cherry-picking without `-x`: one line fails.
- Merging `main` "again, properly": two or more lines fail.
- No mention of the upward-merge trap: the last communication point is lost. This is the item that separates a correct repair from a senior one.
- Accepting "CI built the wrong branch" and asking for a re-run: 0 for the verdicts.

**Reference.** Chapter 29, sections 29.2, 29.7, 29.9 and 29.10; Chapter 11, sections 11.8 and 11.9; Chapter 10, section 10.4; Chapter 27, sections 27.8 to 27.10; Chapter 30, sections 30.3, 30.15 and 30.20.

### Variant B (`cart-svc`): model solution

<!-- snippet: gates/solve-g9-b/01-observe -->
```text
# PHASE 1: read-only
$ cd you
$ git status -sb
## main...origin/main
$ git fetch
$ git ls-remote origin
d18d1bda5bc775d57afec2bc21a06cce1a7bc63d	HEAD
d18d1bda5bc775d57afec2bc21a06cce1a7bc63d	refs/heads/main
f6728d80daeb238da1b6e4aafd73c3cec6ff0eeb	refs/heads/port/clamp-quantities
d779cc9abd3a7adb59daf59291ecc6c1d5b92a33	refs/heads/release/3.0
296688c1b78c7a9f2d1ce98fad19e45ccf223562	refs/tags/v3.0.0
1cd1e716e8fcbb4f366e55f644dd2d624a5e35de	refs/tags/v3.0.0^{}
5b3375c91ae3e6b82abd9dfbfff0553aef5e3b5d	refs/tags/v3.0.1
d779cc9abd3a7adb59daf59291ecc6c1d5b92a33	refs/tags/v3.0.1^{}
f1aa8c16714b7415f02fbe64edbc993b85acdd75	refs/tags/v3.1.0
d18d1bda5bc775d57afec2bc21a06cce1a7bc63d	refs/tags/v3.1.0^{}
```
<!-- /snippet -->

<!-- snippet: gates/solve-g9-b/02-the-search-by-title -->
```text
$ git log --all --format='%h %s' --grep 'Clamp negative'
f6728d8 Clamp negative quantities in the line total
d779cc9 Clamp negative quantities in the line total
$ git branch -r --contains d779cc9
  origin/release/3.0
$ git branch -r --contains f6728d8
  origin/port/clamp-quantities
$ git tag --contains d779cc9
v3.0.1
$ git tag --contains f6728d8
```
<!-- /snippet -->

Ravi's search is correct and proves nothing about production. `--all` searches every ref, so it finds two commits with that title: the fix on `release/3.0`, contained in the tag `v3.0.1` and in no other release, and its copy on the branch `port/clamp-quantities`, contained in no tag at all. A title on some branch is not a commit in a release.

<!-- snippet: gates/solve-g9-b/03-ancestry -->
```text
$ git merge-base --is-ancestor d779cc9 v3.1.0
[exit status: 1]
$ git merge-base --is-ancestor f6728d8 v3.1.0
[exit status: 1]
$ git cherry -v v3.1.0 origin/release/3.0
+ d779cc9abd3a7adb59daf59291ecc6c1d5b92a33 Clamp negative quantities in the line total
$ git show v3.1.0:cart/pricing.py | head -2
def line_total(price, qty):
    return price * qty
$ git show v3.0.1:cart/total.py | head -2
def line_total(price, qty):
    return price * max(qty, 0)
```
<!-- /snippet -->

Neither commit is an ancestor of `v3.1.0`, `git cherry` marks the fix with `+` (no equivalent patch in `v3.1.0`), and the file content settles it: `v3.1.0` multiplies by `qty`, `v3.0.1` by `max(qty, 0)`. Production is missing the fix. The port was prepared and never merged.

<!-- snippet: gates/solve-g9-b/04-the-other-hypothesis -->
```text
$ git log --oneline v3.0.1..v3.1.0
d18d1bd Add coupon support
0465b07 Bump pricing-lib to 4.2
53440cf Rename the total module to pricing
$ git diff --stat v3.0.1 v3.1.0
 cart/coupons.py               | 2 ++
 cart/{total.py => pricing.py} | 2 +-
 requirements.txt              | 2 +-
 3 files changed, 4 insertions(+), 2 deletions(-)
$ git log --oneline main..oncall/revert-pricing-lib
10b6e72 Revert "Bump pricing-lib to 4.2"
```
<!-- /snippet -->

The on-call engineer is right that the bump is the only pricing change that 3.1 added, and wrong that it is the cause: the regression is a change that 3.1 lacks, not one that it has. A diff between the two releases shows the module renamed with one changed line, the line of the fix, in the direction of removal. Reverting the bump would ship a second change under incident pressure and leave the bug in place.

**The verdicts.** On-call: wrong; decided by `git show v3.1.0:cart/pricing.py` against `git show v3.0.1:cart/total.py`. Ravi: right that he made and ported the fix, wrong that it is in; decided by `git merge-base --is-ancestor` and `git tag --contains`.

**Root cause.**

```text
Observed behavior : v3.1.0 has a bug that v3.0.1 fixed.
Git state         : The fix commit is reachable from release/3.0 and v3.0.1 only. Its copy is
                    reachable from port/clamp-quantities only. main and v3.1.0 contain neither,
                    and no commit with the same change.
Mechanism         : A commit on one branch is on another only if somebody merges or cherry-picks
                    it. Nothing in Git carries a fix from a release branch to main.
Root cause        : The fix was made on the release branch, and the step that carries it to main
                    was a pull request that nobody merged. Layer: process, on GitHub (an open pull
                    request is not a merged one); Git behaved as designed.
Why Git does this : Branches are independent refs; reachability is the only relation between them.
Correct fix       : A 3.1.1 from v3.1.0 plus the fix, and the fix on main, both with -x.
Prevention        : A release check that every fix on the previous release line has an equivalent
                    on the commit being tagged.
```

<!-- snippet: gates/solve-g9-b/05-release -->
```text
# PHASE 2: preserve. Nothing is rewritten; the new refs are the record.
# PHASE 3: change
$ git switch -c release/3.1 v3.1.0
Switched to a new branch 'release/3.1'
$ git cherry-pick -x d779cc9
[release/3.1 68278ed] Clamp negative quantities in the line total
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:16:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --stat --format=%B HEAD
Clamp negative quantities in the line total

(cherry picked from commit d779cc9abd3a7adb59daf59291ecc6c1d5b92a33)


 cart/pricing.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --stat v3.1.0 HEAD
 cart/pricing.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git tag -a v3.1.1 -m "cart-svc 3.1.1: clamp negative quantities"
$ git push origin release/3.1 v3.1.1
To ../server.git
 * [new branch]      release/3.1 -> release/3.1
 * [new tag]         v3.1.1 -> v3.1.1
```
<!-- /snippet -->

The release branch starts at the tag, so 3.1.1 is 3.1.0 plus one commit. The cherry-pick follows the rename: the fix was made in `cart/total.py` and lands in `cart/pricing.py`. Nothing existing is rewritten, so the preservation step is a statement and not a backup ref.

<!-- snippet: gates/solve-g9-b/06-main -->
```text
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git cherry-pick -x d779cc9
[main 87d38e5] Clamp negative quantities in the line total
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:16:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push origin main
To ../server.git
   d18d1bd..87d38e5  main -> main
```
<!-- /snippet -->

<!-- snippet: gates/solve-g9-b/07-verify -->
```text
$ git show v3.1.1:cart/pricing.py | head -2
def line_total(price, qty):
    return price * max(qty, 0)
$ git show origin/main:cart/pricing.py | head -2
def line_total(price, qty):
    return price * max(qty, 0)
$ git log --format='%h %s' --grep 'cherry picked from commit d779cc9abd3a' v3.1.1 origin/main
87d38e5 Clamp negative quantities in the line total
68278ed Clamp negative quantities in the line total
# The original commit never becomes an ancestor, and the patch test does not see the copy:
# on this branch the file has another name. The -x line is the record.
$ git merge-base --is-ancestor d779cc9 v3.1.1
[exit status: 1]
$ git cherry -v v3.1.1 origin/release/3.0
+ d779cc9abd3a7adb59daf59291ecc6c1d5b92a33 Clamp negative quantities in the line total
$ git describe release/3.1
v3.1.1
$ git status -sb
## main...origin/main
$ cd ..
$ assessments/gen/gate-9-production-debugging/variant-b/check.sh
Checking g9-b
  ok    release/3.1 exists on the server and starts at v3.1.0
  ok    release/3.1 has exactly one commit on top of v3.1.0: the fix
  ok    that commit names the commit of 3.0.1 it was copied from
  ok    release/3.1 has the clamp in cart/pricing.py
  ok    the tag v3.1.1 is an annotated tag
  ok    v3.1.1 names the tip of release/3.1
  ok    main on the server was extended, not rewritten
  ok    main on the server has the clamp
  ok    the dependency bump is still on main
  ok    coupon support is still on main
  ok    main has no file under the old module name
  ok    the tags v3.0.1 and v3.1.0 have not moved
  ok    nothing is staged, modified or untracked in you/
  ok    no operation is left in progress
PASS: the end state of g9-b is right.
[exit status: 0]
```
<!-- /snippet -->

Verification is by content and by the `-x` line. Two checks that a candidate may expect to pass do not: the original commit is not an ancestor of `v3.1.1` (a copy never is), and `git cherry` still prints `+`, because on this branch the patch applies to a file with another name. The candidate who relies on `git cherry` alone would conclude that the fix is still missing. Say what you verified and how.

**The summary (model).**

```text
Subject: [Mitigated] cart-svc: returns reduce the cart total again since Friday (SEV 1)
What happened   From Friday's release of 3.1.0 until the release of 3.1.1 today, a cart line with a
                negative quantity reduced the total: customers were undercharged. The same fault
                was fixed three weeks ago in 3.0.1. The number of affected orders is being counted.
Root cause      Process, on GitHub: the fix was made on the 3.0 release branch and its port to main
                was prepared as a pull request that was never merged, so 3.1.0 was built without it.
                Git and the pipeline behaved as designed.
What was done   3.1.1 was built as 3.1.0 plus that one fix and the fix was added to main. Verified:
                the pricing code in 3.1.1 and on main clamps negative quantities. Not yet verified:
                the deployment of 3.1.1, and the count and correction of affected orders.
Prevention      A release check that fails when a fix on the previous release line has no
                equivalent on the commit being tagged (owner: release engineering, date: this sprint).
```

Severity: SEV 1, wrong code reached production and customers were affected.

**Control.** Strength 2, automation checks: in the release job, compare the previous release line with the commit being tagged (`git cherry -v <new tag commit> <previous release branch>`, plus a search for `cherry picked from commit` lines), and fail on any fix without a counterpart. As this incident shows, the patch test has to be combined with the `-x` reference, because a rename hides the equivalence. A strength 4 control beside it: fixes are made on `main` first and copied to release branches, never the other way round, so that a forgotten step leaves the old release unfixed and not the new one.

**Partial credit and common mistakes, variant B.**

- Pushing the on-call revert: the bug stays, a dependency is downgraded in production. Two lines of the check fail; 0 for the verdicts.
- Tagging `v3.1.1` on `main` after adding the fix there: with this history it happens to contain only the fix, and the check fails on the release branch lines. The instruction was the smallest possible release from the tag; in a real repository `main` would have moved on.
- Merging `port/clamp-quantities` into `main`: the fix arrives (through the rename), with a commit whose `-x` line points at the release commit. Accept for `main`; the release branch still needs its own pick.
- Cherry-picking from the port branch's copy: the message then carries the reference of the copy. One line fails.
- A lightweight tag: one line fails; `git describe` ignores it by default.
- Moving `v3.1.0` to include the fix: 0 for safety. A published tag does not move.
- Verification by `git cherry` only, concluding "still missing": no deduction for the end state; 1 point off the diagnosis for not reading the content.

**Reference.** Chapter 29, sections 29.2, 29.9 and 29.10; Chapter 27, sections 27.9 and 27.10 (root-cause box "v1.5.0 ships a bug that v1.4.1 fixed"); Chapter 10, sections 10.4, 10.9 and 10.10; Chapter 14B, sections 14B.8, 14B.11 and 14B.14; Chapter 30, sections 30.3, 30.15 and 30.20.

---

## Part 4: Oral interview

O1 to O4: 3 points for a complete answer with the follow-up, 2 for a correct answer with a weak follow-up, 1 for a list without reasons. O5 and O6: 4, 3, 2 or 1 on the same scale, the fourth point for judgment under the pressure the question applies.

### O1 (3 points)

**Model answer.** I ask them to stop typing: no clean-up, no `git gc`, no re-clone, no "let me try one thing". Then I ask what they did and what they expected, and I look, read-only: `git status`, the reflog of `HEAD` and of the branch, `git stash list`, `git branch -a`, and what the server has. Whatever I find gets a branch before anything else. *Follow-up:* the work was committed and a ref moved away from it (reset, rebase, amend, deleted branch): the reflog shows it. The work was stashed or staged and never committed: `git stash list`, then `git fsck` for dangling commits and blobs. The work was only saved in files: no object exists, and `git status` plus the developer's account of a `restore`, `checkout` or `clean` confirm it; then the answer is "this is gone, and here is why".

**Weak answer.** "Check the reflog." **Reference.** Chapter 29, sections 29.2 and 29.7; Chapter 13, section 13.7.

### O2 (3 points)

**Model answer.** Five questions in order: does it destroy uncommitted work; does it rewrite commits another repository has; does it change the server; can it be undone by one command; can it be previewed. I take the candidate that answers "no, no, as little as possible, yes, yes", and I rehearse it on a copy if anything is unclear. A new ref beats a new commit, a new commit beats a local rewrite, a local rewrite beats a forced push. *Follow-up:* when the history itself is the problem and nothing was built on it: my own feature branch after a rebase, with `--force-with-lease --force-if-includes`; or a shared branch where a forced push by someone else has to be put back to its previous commit, with an explicit lease on the bad value; or a history rewrite for data that cannot be rotated, as an announced operation with a freeze. Never as the quick way out of a rejected push.

**Weak answer.** "The fastest one." **Reference.** Chapter 29, section 29.9.

### O3 (3 points)

**Model answer.** Git, in a clone that fetched before and after: the reflog of `origin/main` holds the old and the new value, the fetch output said "forced update", and the old commits are still in that clone, so the branch can be restored from it. Git cannot tell me who pushed or when: commits name authors, not pushers, and the server side has no reflog I can read. GitHub: the Activity view lists the force push with the authenticated user and the before and after commits; Rule Insights shows whether a rule was evaluated or bypassed; the audit log and the Events API add detail within their limits. *Follow-up:* that build server's clone is then the only place outside GitHub that still has the old commits and the old value of the ref in a reflog. I preserve it before its next job fetches with pruning or re-clones: copy the directory or create a branch there. And it tells me the build server may have built the rewritten history.

**Weak answer.** "`git log` shows who did it." **Reference.** Chapter 29, section 29.8; Chapter 13, sections 13.10 and 13.15.

### O4 (3 points)

**Model answer.** Four checks: the symptom is gone, shown by the same command that showed it; the state that caused it is gone, shown by the diagnosis commands; every copy is right, comparing IDs between my clone, the server and the colleague's clone or the pipeline run; and nothing else changed, shown by a diff against the preserved state. I write down what I expect before I run each check. *Follow-up:* after a reverted merge, `git branch --merged` and `git merge` both say the feature is merged, and the files are not there. Or after a backport through a rename, `git cherry` says the fix is missing when it is present. A check answers the question it asks, reachability or patch equality, which may not be the question I have, which is about content.

**Weak answer.** "Run the tests." **Reference.** Chapter 29, section 29.10.

### O5 (4 points)

**Model answer.** "I can tell you which mechanism let it happen and whether it can happen again; a name will not tell you either. At the moment: the branch accepted the update because no rule prevents it. The person involved is helping us, and their reflog is our best evidence. I will have the cause and the control in the summary." If pressed: the account that pushed is in the Activity view, and it will be in the timeline of the postmortem as a role, because the document has to explain the incident with every name replaced by a role. *Follow-up:* the four parts for one of the ten incidents, impact first: what was affected, for how long, with what business impact and whether customers saw it; the root cause in one sentence with its layer; what was done and the check that proves it, and what is not yet verified; the control with owner and date. No commands, no names, one screen.

**Marking note.** A candidate who names a person, or who refuses to answer a CTO at all, earns at most 2. The model answer gives the CTO something better than what was asked for.

**Weak answer.** "It was Ravi, he force-pushed." **Reference.** Chapter 30, sections 30.15 and 30.19.

### O6 (4 points)

**Model answer.** The one that makes the server refuse: a ruleset on `main` that blocks force pushes for everyone, with a narrow bypass list. It applies to every client and tool whatever their configuration. I rank the rest by strength and keep few: an automated check (for example the deploy job refuses a commit that is not a descendant of the last deployed one), a safe client default (`push.default=simple`, an alias that always adds the lease options), a review step, and training last. Twelve items with equal weight mean none will be done; one strong control with an owner, a date and a test is the outcome. *Follow-up:* then the strongest control that is available on the plan: classic branch protection where rulesets are gated, or moving the repository to a plan or visibility where the rule exists if the branch is worth it. If the server truly cannot refuse, the pipeline has to detect: an ancestry test before every deployment, and an alert on forced updates from the Events API. And I say in the postmortem that the remaining risk is accepted, by whom, and until when.

**Weak answer.** "All twelve, by the end of the quarter." **Reference.** Chapter 30, section 30.20; Chapter 18, section 18.15.
