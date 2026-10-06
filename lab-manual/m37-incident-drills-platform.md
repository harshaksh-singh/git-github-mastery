# Module 37 labs: incident drills, remote, platform, CI and security

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Every "Expected output" block is real output from a replay script in `labs/incidents/`. Read [Chapter 30: Incident Response](../textbook/ch30-incident-response.md), sections 30.1 to 30.4, first. Do **not** read the chapter's section on an incident, or its file in `solutions/`, before you have attempted it.

## How these drills work

The procedure is the one of [Module 36](m36-incident-drills-local.md): symptom in one sentence, read-only evidence, three hypotheses, the root-cause box, anchors, the lowest-risk fix, verification, and the messages to the reporter and the CTO. The difference in this module is the server. All five incidents involve shared state on it, so two things are added to every drill:

- **A first message.** Before you investigate, write the one sentence you would send to the team to stop the damage from spreading.
- **The GitHub side.** A bare repository has no Activity view, rulesets, pull requests, Actions or Support desk. For each drill, write down which GitHub instrument would have given you evidence and which GitHub control would have prevented the incident. Nothing on GitHub is run from these labs; where a lab names a GitHub feature, it is described from GitHub's documentation.

```bash
incidents/02-force-push-wrong-branch/generate.sh     # builds the sandbox and prints its path (run again to start over)
labs/shell "<the path it printed>"
incidents/02-force-push-wrong-branch/check.sh        # from the course root: exit status 0 when recovered
```

| Lab | Incident | Directory | The report says |
|---|---|---|---|
| 37.1 | 2 | `incidents/02-force-push-wrong-branch` | "The top commit on `main` says WIP." |
| 37.2 | 4 | `incidents/04-production-history-rewritten` | "The deployed commit is not an ancestor of `production`." |
| 37.3 | 6 | `incidents/06-pr-500-changes` | "I pushed one commit and the pull request shows 500 files." |
| 37.4 | 7 | `incidents/07-ci-passes-locally` | "It passes on my Mac. It must be a flaky runner." |
| 37.5 | 3 | `incidents/03-committed-secret` | "I deleted the file, so the branch is clean now." |

Each lab ends with a failure scenario and its recovery. Do that part after your own check has passed, on a freshly generated sandbox: it shows parts of the solution.

Answers to the Questions are in [solutions/m37-lab-answers.md](../solutions/m37-lab-answers.md). Write your own answers first.

## Lab 37.1: A force push to the wrong branch (incident 2)

### Objective

Find out how a push from a feature branch replaced `main` on the server, restore `main` without losing anybody's commits, and remove the cause.

### Prerequisites

- [Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md), sections 12.5, 12.7 and 12.8.
- [Chapter 13: Recovery](../textbook/ch13-recovery.md), sections 13.10 and 13.15.

### Setup

```bash
incidents/02-force-push-wrong-branch/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/02-force-push-wrong-branch"
```

### Commands

No recovery commands are given. Start in `you/`, and notice which of these commands talks to the server:

```bash
cd you
git status -sb
git log --oneline -3
git ls-remote origin
```

Before you restore anything, answer two questions in your notes: is your copy of the old value the newest one that exists, and where on the server will the commits live that you are about to remove from `main`?

### Expected output

<!-- snippet: incidents/solve-02-force-push-wrong-branch/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ git log --oneline -3
ca03e42 Close the input file after loading
27215c8 Reject rows without a timestamp
f273cd3 Add row validation
# The status is a statement about the last contact with the server. Ask the server:
$ git ls-remote origin
b4554be04054a80a74009ade9d329d2d820c8c5c	HEAD
b4554be04054a80a74009ade9d329d2d820c8c5c	refs/heads/main
```
<!-- /snippet -->

When you are done, the check prints ten `ok` lines and `PASS`.

### What happened internally

Find it yourself; the solution has it in section 5. Known beforehand: the server is bare and has no reflog. Its previous value survives only in `.git/logs/refs/remotes/origin/main` of the clones that saw it.

### Checkpoint

Before you change anything: the old and the new ID of `main` on the server, and the list of commits lost and gained; the configuration line that explains the destination of the push; a rescue branch at the old value.

### Failure scenario

Generate the incident again. Restore `main` at once, and stop there: do not save the forced-in commits and do not touch the cause.

<!-- snippet: incidents/lab-37-1-force-push-wrong-branch/01-failure -->
```text
$ cd you
$ git fetch
From ../server
 + ca03e42...b4554be main       -> origin/main  (forced update)
# The tempting move: put main back at once.
$ git push --force-with-lease=main:b4554be origin main
To ../server.git
 + b4554be...ca03e42 main -> main (forced update)
# Which branch on the server holds Asha's two commits now?
$ git ls-remote origin
ca03e42e9a0a5df9443021ab8b91f1a8364a77ac	HEAD
ca03e42e9a0a5df9443021ab8b91f1a8364a77ac	refs/heads/main
# Asha, told that main is fixed, publishes her branch the way she did before:
$ cd ../asha
$ git push
To ../server.git
 ! [rejected]        feature/dedupe -> main (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ cd ..
$ incidents/02-force-push-wrong-branch/check.sh
Checking incident 02-force-push-wrong-branch
  ok    main on the server has "Add loader"
  ok    main on the server has "Add row validation"
  ok    main on the server has "Reject rows without a timestamp"
  ok    main on the server has "Close the input file after loading"
  ok    main on the server has no WIP commit
  FAIL  the server has a branch feature/dedupe
  FAIL  feature/dedupe on the server has "WIP dedupe by id"
  FAIL  feature/dedupe on the server has the amended commit
  FAIL  in asha/, feature/dedupe still has origin/main as its upstream
  FAIL  in asha/, push.default is still "upstream"
NOT YET: 5 check(s) failed.
[exit status: 1]
```
<!-- /snippet -->

After the restore, no branch on the server holds Asha's two commits. And when she publishes her branch the way she did before, the push is aimed at `main` again: `feature/dedupe -> main`. This time it is rejected, only because she did not type `--force`.

### Recovery

<!-- snippet: incidents/lab-37-1-force-push-wrong-branch/02-recovery -->
```text
$ cd asha
# The rejection is the only thing that saved main this time. Fix the cause, then push by name:
$ git config unset push.default
$ git push -u origin feature/dedupe
To ../server.git
 * [new branch]      feature/dedupe -> feature/dedupe
branch 'feature/dedupe' set up to track 'origin/feature/dedupe'.
$ git branch -vv
* feature/dedupe b4554be [origin/feature/dedupe] WIP config flag and readable dedupe, tests still red
  main           f273cd3 [origin/main: behind 2] Add row validation
$ cd ..
$ incidents/02-force-push-wrong-branch/check.sh
Checking incident 02-force-push-wrong-branch
  ok    main on the server has "Add loader"
  ok    main on the server has "Add row validation"
  ok    main on the server has "Reject rows without a timestamp"
  ok    main on the server has "Close the input file after loading"
  ok    main on the server has no WIP commit
  ok    the server has a branch feature/dedupe
  ok    feature/dedupe on the server has "WIP dedupe by id"
  ok    feature/dedupe on the server has the amended commit
  ok    in asha/, the upstream of feature/dedupe is no longer origin/main (now: origin/feature/dedupe)
  ok    in asha/, push.default is unset (simple)
PASS: the recovery of incident 02-force-push-wrong-branch is complete.
[exit status: 0]
```
<!-- /snippet -->

### Verification

`incidents/02-force-push-wrong-branch/check.sh` exits 0. `git ls-remote origin` shows two branches.

**GitHub side.** Evidence: the repository's [Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository) lists force pushes with the user. Control: "Block force pushes" in a ruleset on `main` ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#block-force-pushes)).

### Questions

1. Which three conditions had to hold together for this push to replace `main`?
2. Why must Asha's commits get a branch on the server before `main` is restored?
3. What does `--force-with-lease=main:<ID>` check, and why is the explicit ID better than the bare form during an incident?
4. When would `git revert` have been the right repair instead of a second forced update?
5. A teammate fetched during the incident. What do they see, and what do you tell them to run?

## Lab 37.2: Production branch history is rewritten (incident 4)

### Objective

Establish exactly what a "cosmetic" rewrite of the production branch changed, restore a history that deployment records can trust without losing work shipped since, and bring every clone back in line.

### Prerequisites

- [Chapter 9: Rebase](../textbook/ch09-rebase.md), sections 9.6 and 9.14.
- Chapter 13, section 13.10.
- [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md), section 18.18.

### Setup

```bash
incidents/04-production-history-rewritten/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/04-production-history-rewritten"
```

### Commands

No recovery commands are given. Start in `you/`:

```bash
cd you
git fetch
git branch -vv
git log --oneline --graph production origin/production
```

The report contains the claim "same code, fewer commits". Decide which Git comparison tests that claim, and run it before anything else.

### Expected output

<!-- snippet: incidents/solve-04-production-history-rewritten/01-observe -->
```text
$ cd you
$ git fetch
From ../server
 + 3277739...4fae70f production -> origin/production  (forced update)
$ git branch -vv
* main       905f1ab [origin/main] Add README
  production 3277739 [origin/production: ahead 4, behind 2] Log the invoice id on failure
$ git log --oneline --graph production origin/production
* 4fae70f Add invoice PDF footer
* f2783aa Tax calculation, formatting and logging
| * 3277739 Log the invoice id on failure
| * 45e5eb3 Add currency formatting
| * 1d8b2fc Round tax to two decimals
| * c644065 Add tax calculation
|/  
* f46af3d Add invoice totals
* 905f1ab Add README
```
<!-- /snippet -->

When you are done, the check prints thirteen `ok` lines and `PASS`.

### What happened internally

Find it yourself. Known beforehand: an annotated tag is an object on the server that names one commit, and no fetch moves it. A rewritten commit keeps its author and gets a new committer.

### Checkpoint

Before you change anything: the old tip, confirmed by three independent sources; the file-level difference between the old and the new tip, with an explanation for every file; a decision between "keep the rewrite and fix forward" and "restore", with the reason.

### Failure scenario

Generate the incident again. Your `production` is the good history, so force it back.

<!-- snippet: incidents/lab-37-2-production-history-rewritten/01-failure -->
```text
$ cd you
$ git fetch
From ../server
 + 3277739...4fae70f production -> origin/production  (forced update)
# The tempting move: my production is the good history, so force it.
$ git push --force-with-lease=production:4fae70f origin production
To ../server.git
 + 4fae70f...3277739 production -> production (forced update)
$ cd ..
$ incidents/04-production-history-rewritten/check.sh
Checking incident 04-production-history-rewritten
  ok    production on the server has "Add invoice totals"
  ok    production on the server has "Add tax calculation"
  ok    production on the server has "Round tax to two decimals"
  ok    production on the server has "Add currency formatting"
  ok    production on the server has "Log the invoice id on failure"
  FAIL  production on the server has "Add invoice PDF footer"
  ok    the squashed commit is no longer on production
  ok    the deployed tag is an ancestor of production again
  ok    billing/tax.py on production rounds to two decimals
  FAIL  billing/pdf.py is on production
  ok    production in you/ equals production on the server
  FAIL  production in asha/ differs from production on the server
  FAIL  production in ravi/ differs from production on the server
NOT YET: 4 check(s) failed.
[exit status: 1]
```
<!-- /snippet -->

The deployed tag is an ancestor again, and a commit that was shipped on the rewritten branch is gone from the server.

### Recovery

The realignment step of the solution is also what finds the lost commit: a `+` line in `git cherry -v` is work the server lacks.

<!-- snippet: incidents/lab-37-2-production-history-rewritten/02-recovery -->
```text
# The commit that was shipped in between is still in its author's clone. The realign step finds it:
$ cd asha
$ git fetch
From ../server
 + 4fae70f...3277739 production -> origin/production  (forced update)
$ git cherry -v origin/production production
+ f2783aa72335f59cef8731e0d5ed00dda990cd72 Tax calculation, formatting and logging
+ 4fae70f86a56f9c739bd55c2e9830f4fba9145da Add invoice PDF footer
# Two "+" lines. One is the rewrite, which is being retired. The other is real work:
$ git branch rescue/footer production
$ git reset --keep origin/production
$ git cherry-pick rescue/footer
[production 53564ab] Add invoice PDF footer
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:30:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 billing/pdf.py
$ git push
To ../server.git
   3277739..53564ab  production -> production
$ git branch -D rescue/footer
Deleted branch rescue/footer (was 4fae70f).
$ cd ../ravi
$ git fetch
From ../server
 + f2783aa...53564ab production -> origin/production  (forced update)
$ git reset --keep origin/production
$ cd ../you
$ git switch production
Switched to branch 'production'
Your branch is up to date with 'origin/production'.
$ git pull --ff-only
From ../server
   3277739..53564ab  production -> origin/production
Updating 3277739..53564ab
Fast-forward
 billing/pdf.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 billing/pdf.py
$ cd ..
$ incidents/04-production-history-rewritten/check.sh
Checking incident 04-production-history-rewritten
  ok    production on the server has "Add invoice totals"
  ok    production on the server has "Add tax calculation"
  ok    production on the server has "Round tax to two decimals"
  ok    production on the server has "Add currency formatting"
  ok    production on the server has "Log the invoice id on failure"
  ok    production on the server has "Add invoice PDF footer"
  ok    the squashed commit is no longer on production
  ok    the deployed tag is an ancestor of production again
  ok    billing/tax.py on production rounds to two decimals
  ok    billing/pdf.py is on production
  ok    production in you/ equals production on the server
  ok    production in asha/ equals production on the server
  ok    production in ravi/ equals production on the server
PASS: the recovery of incident 04-production-history-rewritten is complete.
[exit status: 0]
```
<!-- /snippet -->

### Verification

`incidents/04-production-history-rewritten/check.sh` exits 0, and `git merge-base --is-ancestor deploy-2026-09-07 origin/production` exits 0.

**GitHub side.** Control: a ruleset on `production` that blocks force pushes and deletions and requires a pull request, with an empty bypass list. Evidence afterwards: Rule Insights records every pass, failure and bypass per ref update ([managing rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository#viewing-insights-for-rulesets)).

### Questions

1. `git range-diff` found no pairs between the old and the rewritten series. Why, and which command answered the real question?
2. The folded commit shows `Lab User` as author. Where do you read who rewrote the branch?
3. What should a developer conclude from "your branch has diverged" on a branch where they made no commits?
4. Give one argument for keeping the rewritten history and one for restoring the old one. Which decided it here?
5. In the realignment, what does each of `+` and `-` in `git cherry -v origin/production production` tell a teammate to do?

## Lab 37.3: A pull request suddenly shows 500 unrelated changes (incident 6)

### Objective

Find where 500 unrelated changes in a pull request come from, using only the comparisons a pull request is made of, and repair the head branch in a way that causes no second problem later.

### Prerequisites

- [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md), sections 17.3, 17.5 and 17.12.
- [Chapter 11: Reset, Revert, Restore](../textbook/ch11-reset-revert-restore.md), section 11.9.

### Setup

```bash
incidents/06-pr-500-changes/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/06-pr-500-changes"
```

### Commands

No recovery commands are given. There is no GitHub in the sandbox; produce the two views of the pull request yourself:

```bash
cd you
git fetch
git log --oneline origin/main..origin/feature/snippet-highlight
git diff --shortstat origin/main...origin/feature/snippet-highlight
```

The reporter offers two hypotheses (a rewritten `main`, a changed base). Test both before you form your own.

### Expected output

<!-- snippet: incidents/solve-06-pr-500-changes/01-pull-request-view -->
```text
$ cd you
$ git fetch
From ../server
 * [new branch]      develop    -> origin/develop
 * [new branch]      feature/snippet-highlight -> origin/feature/snippet-highlight
# The commit list of the pull request, and the size of its diff:
$ git log --format='%h %an: %s' origin/main..origin/feature/snippet-highlight
5dc3109 Ravi Menon: Highlight every query term
461c3ea Ravi Menon: Merge branch 'develop' of ../server into feature/snippet-highlight
f94e7f0 Ravi Menon: Escape HTML in snippets
6d230a6 Ravi Menon: Test snippet highlighting
bdb4a59 Ravi Menon: Add snippet highlighting
069daa8 Asha Rao: Switch the tokenizer to ICU word breaking
5f0c2ae Asha Rao: Regenerate golden fixtures
796fd96 Asha Rao: Add golden fixture generator
$ git diff --shortstat origin/main...origin/feature/snippet-highlight
 504 files changed, 517 insertions(+), 1 deletion(-)
$ git diff --dirstat=files,5 origin/main...origin/feature/snippet-highlight
  99.2% tests/golden/
```
<!-- /snippet -->

When you are done, the check prints twelve `ok` lines and `PASS`.

### What happened internally

Find it yourself. Known beforehand: a pull request lists every commit reachable from the head and not from the base, whoever wrote it and however it got there.

### Checkpoint

Before you change anything: the one commit through which the unrelated changes entered; the command, from a reflog, that created it; an anchor at the current tip; a written reason why your fix will not hurt when `develop` is released.

### Failure scenario

Generate the incident again. Shrink the pull request without a forced push: revert the merge.

<!-- snippet: incidents/lab-37-3-pr-500-changes/01-failure -->
```text
$ cd ravi
# The tempting move: no forced push needed.
$ git revert --no-edit -m 1 461c3ea | head -3
[feature/snippet-highlight 7b5a821] Revert "Merge branch 'develop' of ../server into feature/snippet-highlight"
 Date: Mon Sep 7 10:29:00 2026 +0530
 502 files changed, 1 insertion(+), 508 deletions(-)
$ git push
To ../server.git
   5dc3109..7b5a821  feature/snippet-highlight -> feature/snippet-highlight
# The pull request afterwards:
$ git diff --shortstat main...feature/snippet-highlight
 2 files changed, 9 insertions(+)
$ git rev-list --count main..feature/snippet-highlight
9
```
<!-- /snippet -->

Two files in the diff, as wished, and nine commits in the list. Now play the future on a detached HEAD: the pull request is merged, then `develop` is released.

<!-- snippet: incidents/lab-37-3-pr-500-changes/02-consequence -->
```text
# Later: the pull request is merged into main, and then develop is released into main.
$ git switch -q --detach main
$ git merge -q --no-ff -m 'Merge pull request: snippet highlighting' feature/snippet-highlight
$ git merge -m 'Release develop' origin/develop
Already up to date.
$ ls tests
test_highlight.py
test_tokenize.py
$ git switch -q feature/snippet-highlight
$ cd ..
$ incidents/06-pr-500-changes/check.sh
Checking incident 06-pr-500-changes
  ok    the server still has the feature branch
  ok    "Add snippet highlighting" is in the pull request exactly once
  ok    "Test snippet highlighting" is in the pull request exactly once
  ok    "Escape HTML in snippets" is in the pull request exactly once
  ok    "Highlight every query term" is in the pull request exactly once
  FAIL  the pull request lists 9 commits (expected 4)
  ok    the pull request changes two files
  FAIL  no commit of develop is reachable from the feature branch
  FAIL  the feature branch contains 1 merge commit(s); a reverted merge is not a removed merge
  ok    search/highlight.py handles every query term
  ok    develop on the server is untouched
  ok    main on the server is untouched
NOT YET: 3 check(s) failed.
[exit status: 1]
```
<!-- /snippet -->

`Already up to date.` The release of `develop` brought nothing, and `tests/golden/` is not in `main`: its commits were already ancestors, together with the commit that undid them.

### Recovery

<!-- snippet: incidents/lab-37-3-pr-500-changes/03-recovery -->
```text
$ cd ravi
# Rebuild the branch from the commits that are really its own:
$ git rebase --onto 461c3ea^1 461c3ea
Rebasing (1/2)
Rebasing (2/2)
dropping 7b5a82146fb7b2ae08fd4224100282595ebee0af Revert "Merge branch 'develop' of ../server into feature/snippet-highlight" -- patch contents already upstream
Successfully rebased and updated refs/heads/feature/snippet-highlight.
$ git log --oneline main..feature/snippet-highlight
c5d22d4 Highlight every query term
f94e7f0 Escape HTML in snippets
6d230a6 Test snippet highlighting
bdb4a59 Add snippet highlighting
$ git push --force-with-lease --force-if-includes
To ../server.git
 + 7b5a821...c5d22d4 feature/snippet-highlight -> feature/snippet-highlight (forced update)
$ cd ..
$ incidents/06-pr-500-changes/check.sh
Checking incident 06-pr-500-changes
  ok    the server still has the feature branch
  ok    "Add snippet highlighting" is in the pull request exactly once
  ok    "Test snippet highlighting" is in the pull request exactly once
  ok    "Escape HTML in snippets" is in the pull request exactly once
  ok    "Highlight every query term" is in the pull request exactly once
  ok    the pull request lists four commits
  ok    the pull request changes two files
  ok    no commit of develop is reachable from the feature branch
  ok    the feature branch contains no merge commit
  ok    search/highlight.py handles every query term
  ok    develop on the server is untouched
  ok    main on the server is untouched
PASS: the recovery of incident 06-pr-500-changes is complete.
[exit status: 0]
```
<!-- /snippet -->

The rebase dropped the revert commit by itself: on a base without the merge, it has nothing left to undo.

### Verification

`incidents/06-pr-500-changes/check.sh` exits 0.

**GitHub side.** Whether the approval survived depends on "dismiss stale pull request approvals when new commits are pushed" (Chapter 17, section 17.5). On GitHub you would confirm the repaired pull request with:

```bash
gh pr view <number> --json commits,changedFiles
gh pr diff <number> --name-only
```

### Questions

1. Which two outputs excluded "`main` was rewritten" and "the branch was force-pushed"?
2. Why did `git log --first-parent` make Ravi's statement "I pushed one small commit" understandable?
3. After the revert, why did the later merge of `develop` say `Already up to date.`?
4. What do the two arguments of `git rebase --onto <merge>^1 <merge>` mean?
5. What should a reviewer conclude about an approval that was given before the 500 files appeared?

## Lab 37.4: CI works locally but fails on GitHub Actions (incident 7)

> **This drill is diagnosed on paper.** GitHub Actions cannot be run from this course. You get the workflow file and a description of what each step of the failed run reported, both in `incidents/07-ci-passes-locally/evidence/` and both constructed for the exercise, plus the repository as a sandbox. Wherever plain Git can reproduce what the runner did, you reproduce it.

### Objective

Explain why a step fails on the runner and works on a laptop, by following the fixed investigation order; fix the cause in the repository; and find the second failure that the first one hides.

### Prerequisites

- [Chapter 20B: Delivery, Runners, Cost and Debugging](../textbook/ch20b-actions-delivery-debugging.md), sections 20B.11 and 20B.12.
- [Chapter 12](../textbook/ch12-remote-operations.md), section 12.3 (what a clone fetches).

### Setup

```bash
incidents/07-ci-passes-locally/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/07-ci-passes-locally"
```

Read `SYMPTOMS.md`, `evidence/ci.yml` and `evidence/RUN-REPORT.md` in `incidents/07-ci-passes-locally/`.

### Commands

First on paper: a table with the twelve areas of the investigation order (workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency) and, for each, what the evidence says and whether it can be the cause. Then in the sandbox:

```bash
cd you
git log --oneline --decorate -5
cat scripts/version.sh
bash scripts/version.sh
```

Then build, with `git clone` and its options, a clone like the one the checkout step makes by default, and run the script in it. Push your fix as the branch `fix/ci-checkout`.

### Expected output

<!-- snippet: incidents/solve-07-ci-passes-locally/01-local -->
```text
$ cd you
$ git log --oneline --decorate -5
367b8fb (HEAD -> main, origin/main) Move the template path into a constant
261eb76 Stamp reports with the version from git describe
5a1005a Add CI workflow
e18efbb (tag: v1.4.0) Add README
ef03c89 Add report renderer
$ cat scripts/version.sh
#!/usr/bin/env bash
# Prints the version of this checkout, derived from the newest release tag.
set -e
git describe --tags --match "v*"
$ bash scripts/version.sh
v1.4.0-3-g367b8fb
[exit status: 0]
```
<!-- /snippet -->

When you are done, the check prints eight `ok` lines and `PASS`. The check reads files on the server. It cannot run the workflow.

### What happened internally

Find it yourself. Known beforehand, from the [checkout README](https://github.com/actions/checkout/blob/v7.0.1/README.md): "Only a single commit is fetched by default, for the ref/SHA that triggered the workflow."

### Checkpoint

Before you edit anything: the completed twelve-row table; a local clone in which the script fails with the message from the run report; an answer to "is the runner flaky?" with two reasons; a look at what the job would do after the failing step.

### Failure scenario

A partial fix: give the shallow clone its tags, and keep the depth at 1. This is an approximation of that state with plain Git, not a run of the action.

<!-- snippet: incidents/lab-37-4-ci-passes-locally/01-failure -->
```text
# A clone of depth 1, and then the tags, also at depth 1:
$ git clone --quiet --depth 1 --no-tags "file://$PWD/server.git" runner-checkout
$ cd runner-checkout
$ git fetch --quiet --depth 1 origin 'refs/tags/*:refs/tags/*'
$ git tag --list
v1.4.0
$ git rev-list --count HEAD
1
$ bash scripts/version.sh
fatal: No tags can describe '367b8fb86f55484ce386316098cdbb174a5a65f5'.
Try --always, or create some tags.
[exit status: 128]
```
<!-- /snippet -->

The tag exists in the clone and the message changes to `No tags can describe`: the tag names a commit that HEAD cannot reach, because the commits in between were not fetched.

### Recovery

<!-- snippet: incidents/lab-37-4-ci-passes-locally/02-recovery -->
```text
$ git fetch --quiet --unshallow
$ git rev-list --count HEAD
5
$ bash scripts/version.sh
v1.4.0-3-g367b8fb
[exit status: 0]
$ cd ..
```
<!-- /snippet -->

### Verification

`incidents/07-ci-passes-locally/check.sh` exits 0. The real verification is a green run of the workflow on the fix branch, which you can observe only on GitHub:

```bash
gh run list --workflow ci.yml --branch fix/ci-checkout
gh run view <run-id> --log-failed
```

### Questions

1. Which two observations in the report exclude a flaky runner before you read any log?
2. Which areas of the investigation order did the workflow file answer without a log, and what was each answer?
3. Why does `git describe` need more than the tag refs?
4. What is the second defect, why did no laptop show it, and which Git command shows it independently of the filesystem?
5. What do you answer to "can an administrator merge it anyway"?

## Lab 37.5: A secret is committed (incident 3)

> The string in this drill, `lab-fixture-not-a-real-password`, is a dummy made for the course. It unlocks nothing and matches no secret-scanner pattern. Treat it as a production password.

### Objective

Decide the order of the response to a pushed secret, do the Git part of it (scope, rewrite, publication, clean-up of server and clones), and write down the part that is not Git.

### Prerequisites

- [Chapter 21B: Repository Security and Secret-Leak Response](../textbook/ch21b-repository-security-incident-response.md), sections 21B.10, 21B.11, 21B.14 and 21B.16 to 21B.19.
- Chapter 9, section 9.6 (interactive rebase).

### Setup

```bash
incidents/03-committed-secret/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/03-committed-secret"
```

### Commands

Before any Git command, write the first step of the response and who performs it. It is not a Git command, and the check script cannot see it.

Then no recovery commands are given. Start in `you/` with the scope:

```bash
cd you
git fetch
git log --all --format='%h %an: %s' -- .env
```

`git filter-repo` is not installed in the course environment. The affected history is one short unmerged branch and one branch built on it; an interactive rebase is enough. In the sandbox you are also the administrator of `server.git`.

### Expected output

<!-- snippet: incidents/solve-03-committed-secret/01-find -->
```text
$ cd you
$ git fetch
From ../server
 * [new branch]      feature/digest-template -> origin/feature/digest-template
 * [new branch]      feature/email-digest    -> origin/feature/email-digest
# Every commit, on any branch, that added or removed the file:
$ git log --all --format='%h %an: %s' -- .env
c5d0303 Ravi Menon: Remove env file
76aa6c4 Ravi Menon: Add SMTP sender
```
<!-- /snippet -->

When you are done, the check prints seventeen `ok` lines, a note that it sees Git state only, and `PASS`.

### What happened internally

Find it yourself. Known beforehand: a commit that deletes a file adds a snapshot and leaves every earlier snapshot in place; a force push moves a ref and deletes no object.

### Checkpoint

Before you rewrite anything, the incident record has five facts: what the secret can reach; the first commit that contains it and the time it was first pushed; every ref that reaches it; who could read it; and where you would look to learn whether it was used.

### Failure scenario

Generate the incident again and bring it to the point where Ravi's branch is rewritten and force-pushed (the replay does that part without a transcript). Asha has not been told what to do, and updates her branch the ordinary way.

<!-- snippet: incidents/lab-37-5-committed-secret/01-failure -->
```text
# Ravi's branch has been rewritten and force-pushed. Asha has not been told what to do.
$ cd asha
$ git fetch
From ../server
 + bb4230f...70a9966 feature/email-digest -> origin/feature/email-digest  (forced update)
# The tempting move: bring in the latest state of the branch mine is built on.
$ git merge -m 'Merge the updated email-digest branch' origin/feature/email-digest
Merge made by the 'ort' strategy.
 .gitignore | 1 +
 1 file changed, 1 insertion(+)
$ git push
To ../server.git
   668b910..b3c55d2  feature/digest-template -> feature/digest-template
$ git log --oneline --graph feature/digest-template -8
*   b3c55d2 Merge the updated email-digest branch
|\  
| * 70a9966 Schedule the digest hourly
| * 3a04e90 Sort digest events by time
| * 5a56a9f Add SMTP sender
* | 668b910 Add HTML digest template
* | bb4230f Schedule the digest hourly
* | c5d0303 Remove env file
* | fdd903c Sort digest events by time
# Is the file back in the history of a branch on the server?
$ git log --format='%h %s' origin/feature/digest-template -- .env
c5d0303 Remove env file
76aa6c4 Add SMTP sender
$ git branch -r --contains 76aa6c4
  origin/feature/digest-template
```
<!-- /snippet -->

An ordinary merge and an ordinary push, with no force and no warning, and the removed commits are reachable from a branch on the server again.

### Recovery

<!-- snippet: incidents/lab-37-5-committed-secret/02-recovery -->
```text
# Back to the tip before the merge, then transplant, then force with a lease:
$ git reset --keep 'feature/digest-template@{1}'
$ git rebase --onto origin/feature/email-digest 'origin/feature/email-digest@{1}'
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/digest-template.
$ git push --force-with-lease --force-if-includes
To ../server.git
 + b3c55d2...a885588 feature/digest-template -> feature/digest-template (forced update)
$ git log --format='%h %s' origin/feature/digest-template -- .env
$ git branch -r --contains 76aa6c4
[exit status: 0]
```
<!-- /snippet -->

The transcript ends when her branch is clean. The old objects are still stored in the server and in three clones; pruning them is the last part of the drill.

### Verification

`incidents/03-committed-secret/check.sh` exits 0. Outside Git: the old credential is rejected by its issuer.

**GitHub side.** You cannot prune on GitHub. Removing unreachable commits is a request to GitHub Support, quoting the first changed commit and the number of affected pull requests, and Support assists only where rotation cannot mitigate the risk ([removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)). Control: push protection for recognised formats ([docs](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection)), and an ignore rule for everything else.

### Questions

1. What is the first step of the response, and why does it come before every Git command?
2. Ravi made three claims: the deletion cleaned the branch, it was only his branch, the repository is private. Which command or fact refutes each?
3. After the force push, which command shows that the server still has the secret, and what is the equivalent of your `git gc --prune=now` on GitHub?
4. Why must a teammate rebase, and not merge or pull, a branch built on the old commits?
5. When is a history rewrite **not** warranted after a leak?
