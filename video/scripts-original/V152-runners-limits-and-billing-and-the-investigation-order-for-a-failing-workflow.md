# V152: Runners, limits and billing, and the investigation order for a failing workflow

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 28
- **Planned minutes.** 26
- **Prerequisites.** V151
- **Textbook sections.** [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), sections 20B.8 to 20B.11
- **Demo scripts.** `labs/ch20b/lab-28-2-merge-ref.sh`, then a screen walkthrough of Lab 28.2 in [`lab-manual/m28-runners-debugging-ci.md`](../../lab-manual/m28-runners-debugging-ci.md)

## HOOK

**[ON SCREEN]** Two questions from section 20B.1. "The tests pass on my machine. Why is the pull request red?" "Why did our Actions bill triple?"

Take the first. The textbook's answer: almost always because the job did not run what you ran. Another commit, another shell, another tool version, no secrets, an empty history. Each cause is a documented default. And then the sentence that separates two kinds of engineer: one who knows the defaults finds the cause in minutes; one who does not re-runs the job and hopes.

Re-running and hoping has a recognizable first move: open the red step and start reading the log. This video gives you a different first move, and eleven more after it. The log is step nine.

## INTRODUCTION

This video opens the last module of Part 6: runners and debugging. From here to the gate, the subject is the skill that Chapter 20B says a CTO pays for: finding out why a run failed, in a fixed order, with evidence.

Four topics, in the order of sections 20B.8 to 20B.11. GitHub-hosted runners: what they are and why a label ending in `-latest` is a moving target. Self-hosted runners: the risks, and what "ephemeral" changes. Limits and billing, as the section gives them. And the investigation order for a failing workflow: twelve questions, from "did the right thing start at all" to "what did it say".

A note on the numbers. Limits and prices in this video are quoted from section 20B.10 and are re-verified on the recording day. If you watch this later, check the price page before you write a cost estimate; the textbook says the same.

## LEARNING OBJECTIVES

After this video you can:

- say what a GitHub-hosted runner is and why a `-latest` label is a moving target;
- state the risks of self-hosted runners and what "ephemeral" changes;
- state the limits and the billing model as the section gives them;
- recite the investigation order: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency;
- explain why the log is not the first thing to read.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**Hosted runners. In one sentence:** a GitHub-hosted runner is a fresh virtual machine, built from a published image, that runs one job and is then destroyed.

`runs-on` selects it by label.

**[ON SCREEN]** The label table of section 20B.8, as of 1 October 2026.

`ubuntu-latest` is Ubuntu 24.04 on 1 October 2026, and GitHub has announced its migration to Ubuntu 26.04 between 19 October and 19 November 2026. `windows-latest` is Windows Server 2025. `macos-latest` is macOS 26 on arm64, moved from macOS 15 in June and July 2026. Then the fixed labels, which name a version. `ubuntu-22.04` is deprecated since 17 September 2026, with the end of support announced for 17 April 2027. For `macos-14` the announced end of support is 2 November 2026. Those three dates lie after the course baseline: check the changelog on the day you watch this. And `ubuntu-slim`: one CPU, runs the job in a container, with jobs limited to 15 minutes.

The textbook's comparison is one you can keep: a `-latest` label is a moving name, the runner equivalent of a branch. A migration is rolled out gradually over weeks, so two runs of one workflow on the same day can get different images.

And a fixed label is not frozen either. Images are rebuilt weekly, so tool versions inside a fixed label move too. The textbook's example: in May 2026 Node 20 left the images and the default `node` became 22. That is why the course workflows use a fixed label and also install their tools with setup actions at stated versions.

The cost of pinning: you must move the label yourself before the image retires. Put the retirement dates in your calendar.

Where do you see which image a job received? The "Set up job" section of a run's log names it. The textbook adds a caveat that I pass on: the Phase 0 notes did not verify that section separately, so read it in your own run.

**Hardware.** Standard Linux and Windows runners have 4 CPUs and 16 GB of memory in public repositories, and 2 CPUs and 8 GB in private ones, with 14 GB of disk in both. macOS arm64 runners have 3 CPUs and 7 GB. So a test suite that fits in a public repository can run out of memory or time after the repository is made private.

**Self-hosted runners. In one sentence:** a self-hosted runner is the same runner program on a machine you operate, which asks GitHub for jobs and runs them with whatever access that machine has.

The risk, in GitHub's own words from the secure use reference: self-hosted runners "should almost never be used for public repositories", because anyone can open a pull request that runs code on them. The warning extends to private repositories where anyone with read access can fork and open a pull request. A hosted runner is a clean machine per job. A persistent self-hosted runner "can be persistently compromised by untrusted code in a workflow". And on a self-hosted runner an environment does not isolate secrets from other jobs on the same machine.

Ephemeral runners. Registering with the `--ephemeral` option gives a runner that takes one job and is removed. So-called just-in-time runners are created through the REST API and also run at most one job. GitHub recommends autoscaling with ephemeral runners and advises against autoscaling persistent ones. And one more sentence from the documentation: reusing hardware for such runners can still expose information from the environment. The textbook's reading: "ephemeral" must include the disk.

Runner groups restrict which repositories may send jobs to which runners. They are available to organizations on every plan since 17 October 2024. The risk is a group open to "all repositories": every repository in the organization, including the least reviewed one, can run code on the machines that can reach production.

Versions. Since 29 September 2026 a runner older than 2.329.0 cannot register on github.com, and a runner must install each new release within 30 days or it stops receiving jobs. That bites fleets built from a fixed image with updates disabled.

Queueing. A job waits until a matching runner is online and fails after 24 hours in the queue. A self-hosted job may run for up to five days.

**Limits.**

**[ON SCREEN]** The limits table of section 20B.10.

A job on a GitHub-hosted runner: 6 hours. A workflow run, including waiting for approval: 35 days. An environment approval: fails after 30 days. A matrix: 256 jobs per run. Re-runs: 50 per workflow run, within 30 days of the first run. Reusable workflows: 10 levels, 50 unique called workflows per file. Concurrent jobs on standard runners: 20 on Free, 40 on Pro, 60 on Team, 500 on Enterprise; for macOS, 5, or 50 on Enterprise. Cache: 10 GB per repository without charge, with entries unused for 7 days evicted. Artifacts and logs: 90 days by default, and since 1 October 2026 the same setting also removes checks, runs and statuses.

**Billing.** Standard hosted runners are free in public repositories. Self-hosted runners are free. Private repositories include 2,000 minutes per month on Free, 3,000 on Pro and Team, and 50,000 on Enterprise Cloud, with artifact storage allowances that are shared with GitHub Packages.

List prices per minute since 1 January 2026: Linux 2-core, 0.6 cents. Linux arm64 2-core, 0.5 cents. `ubuntu-slim`, 0.2 cents. Windows 2-core, 1 cent. macOS, 6.2 cents. Each job is rounded up to a whole minute. Storage beyond the allowance: artifacts 25 cents and cache 7 cents per GB per month. Larger runners are always billed, in public repositories too. A reusable workflow is billed to the caller. Time spent in a wait timer is not billed.

**[ON SCREEN]** Callout: Unverified. How Windows and macOS minutes consume the included minutes is not stated on any 2026 page the Phase 0 research could fetch. Older material gives multipliers of 2 for Windows and 10 for macOS; the old multiplier page now redirects to the price list. Do not quote a multiplier. Read your own usage in the billing settings.

**[ON SCREEN]** Callout: Version note. Tutorials quote prices from before 2026; prices were cut by up to 39 percent on 1 January 2026. And one item is announced and not in effect: a charge of 0.2 cents per minute for self-hosted runners, announced on 16 December 2025 for 1 March 2026 and then postponed without a new date.

The cost levers follow from the rules. Cancel superseded CI runs with a concurrency group. Prefer one job with several steps over many one-step jobs, because each job rounds up. Keep macOS for what needs macOS, at roughly ten times the Linux price. Use `ubuntu-slim` for glue jobs. Shorten artifact retention. Path filters also save minutes, and V154 shows what they cost you.

**The investigation order.** The textbook's instruction: a failing run tempts you to open the red step and start reading. Do that last but three. The order goes from "did the right thing start at all" to "what did it say", because an answer early in the list makes everything after it irrelevant.

One. Workflow. Which workflow file, from which commit, defined this run?

Two. Event. What triggered it, and which ref and commit did the job check out? `push` builds the pushed commit. `pull_request` builds `refs/pull/N/merge`. A re-run reuses the original commit and ref.

Three. Permissions. What could the token do? Top-level and job-level `permissions`; unlisted scopes are none; fork and Dependabot runs get a read-only token.

Four. Runner. Which image, which size? The label, the image named at the top of the job log, and whether the repository is public or private.

Five. Environment. Did the job reference one, and did its rules pass? Waiting, rejected, wrong branch, or an environment created by accident.

Six. Dependencies. Were the same versions installed as locally? The lock file, `--locked`, the versions printed by setup steps.

Seven. Secrets. Were they present? An unset or withheld secret is an empty string, not an error.

Eight. Action versions. Which commit of each action ran? The pins; an old major on Node 24; a moved tag.

Nine. Logs. What did the failed step print?

Ten. Artifacts. Were the expected files produced and passed on?

Eleven. Cache. What was restored, under which key?

Twelve. Concurrency. Was the run cancelled or replaced by another?

**[ON SCREEN]** The instruments for the first steps, as the table gives them.

```bash
gh run view <id> --json workflowName,headSha,headBranch,event
gh workflow view <file> --yaml --ref <branch>
gh run view <id> --log-failed
gh run download <id>
gh cache list --key <prefix>
gh run list --workflow <file>
```

All of these are 🟢 SAFE: they change nothing on GitHub. `gh run download` writes files into your local directory.

The textbook's summary of the method: steps 1 and 2 remove the most confusion for the least effort. `gh run view` prints the event, the branch and the commit ID. Compare that ID with `git rev-parse HEAD` on your machine before you compare anything else.

## MENTAL MODEL

**Analogy for self-hosted runners,** from the textbook. Lending your workshop to anyone who holds a work order. A GitHub-hosted runner is a rented workshop that is demolished after each job. Yours stays: tools, leftovers, and everything a previous visitor hid there.

The analogy breaks in one respect, and the textbook says that respect is everything: you choose who may write work orders, and that choice is the whole security question.

**A model for the investigation order.** Think of a run as a chain of decisions, each made before the next can matter. Was a run created, from which file? For which commit? With what authority? On what machine? Past which gate? With which dependencies, which secrets, which action code? Only then does your command start and print anything.

The log is the output of the last link. If an earlier link was different from what you assume, the log is a faithful record of the wrong experiment. You can read it for an hour and learn nothing, because nothing in it says "this is not the commit you think".

That is why the order is fixed and why the log sits at nine. The three steps after it, artifacts, cache and concurrency, are about what the run handed on or was done to it.

## DIAGRAM

**[DIAGRAM]** A vertical list. Reveal one line at a time, question first. Draw a horizontal rule above step 9 and label everything above it "decided before the first log line".

```text
   #   what                  the question it answers
  ---  --------------------  ---------------------------------------------------------------
   1   workflow              which workflow file, from which commit, defined this run?
   2   event                 what triggered it; which ref and commit did the job check out?
   3   permissions           what could the token do?
   4   runner                which image, which size?
   5   environment           did the job reference one, and did its rules pass?
   6   dependencies          were the same versions installed as locally?
   7   secrets               were they present?  (an unset secret is an empty string)
   8   action versions       which commit of each action ran?
  ------------------------------- decided before the first log line ------------------------
   9   logs                  what did the failed step print?
  10   artifacts             were the expected files produced and passed on?
  11   cache                 what was restored, under which key?
  12   concurrency           was the run cancelled or replaced by another?
```

**[DIAGRAM]** Say the twelve words in order once, aloud: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency. You will be asked for them.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch20b/lab-28-2-merge-ref`. This is the investigation order applied to a constructed case: a run that tested another commit than the author's. Git, in the sandbox; the IDs equal the book's.

The developer's report: "The checks pass on my machine. The pull request is red."

**Step 1: what the developer sees.**

```bash
git status --short --branch
python3 tests/check_rules.py
python3 tests/check_bulk.py
```

<!-- snippet: ch20b/lab-28-2-merge-ref/01-local -->
```text
$ git status --short --branch
## feature/bulk-reorder
$ python3 tests/check_rules.py
ok: 2 checks
$ python3 tests/check_bulk.py
ok: bulk reorder
```
<!-- /snippet -->

On the branch `feature/bulk-reorder`, both checks pass. The developer is not wrong about that.

**Step 2 of the order, before any log: which commit did the job check out?** For a `pull_request` run you know the answer in kind: the test merge. So look at the two sides of that merge.

```bash
git log --oneline --graph --format="%h %an: %s" main feature/bulk-reorder -4
git merge-base main feature/bulk-reorder
```

**[PAUSE]** What do you expect to see on `main` that the branch does not have?

<!-- snippet: ch20b/lab-28-2-merge-ref/02-graph -->
```text
$ git log --oneline --graph --format="%h %an: %s" main feature/bulk-reorder -4
* 2230054 Asha Rao: Require a safety stock in the reorder rules
| * 34f82ef Lab User: Add bulk reorder
|/  
* 57c8425 Lab User: Add the lock file
* 197d992 Lab User: Document the release runbook
$ git merge-base main feature/bulk-reorder
57c8425908f43c74c14b2642edb59e0f99dac38c
```
<!-- /snippet -->

`main` has a commit by Asha, `2230054`, "Require a safety stock in the reorder rules". The branch has `34f82ef`, "Add bulk reorder". They share the merge base `57c8425`. Two people changed related code on two sides.

**Step 3: build what the pull request run checks out.**

```bash
git merge-tree --write-tree main feature/bulk-reorder
git switch --quiet --detach main
git merge --quiet --no-ff -m "Merge feature/bulk-reorder into main (test merge)" feature/bulk-reorder
python3 tests/check_rules.py
python3 tests/check_bulk.py
```

`git merge-tree` reads and writes an unreferenced tree. The switch detaches HEAD on `main` so that no branch moves. `git merge` is 🟡 CAUTION; here it moves only the detached HEAD. **[PAUSE]** The merge is clean. Will both checks pass on it?

<!-- snippet: ch20b/lab-28-2-merge-ref/03-merge-commit -->
```text
# Build what the pull request run checks out: the merge of the branch into main, detached.
$ git merge-tree --write-tree main feature/bulk-reorder
fe5b8f225d8a79237933117a63958bbd7dd8a2c6
$ git switch --quiet --detach main
$ git merge --quiet --no-ff -m "Merge feature/bulk-reorder into main (test merge)" feature/bulk-reorder
$ git status --short --branch
## HEAD (no branch)
$ python3 tests/check_rules.py
ok: 2 checks
$ python3 tests/check_bulk.py
FAIL: TypeError: needs_reorder() missing 1 required positional argument: 'safety_stock'
[exit status: 1]
```
<!-- /snippet -->

"HEAD (no branch)", as on the runner. The first check passes. The second fails with a `TypeError`: a function now needs an argument that the new code does not pass. Asha's commit changed a signature; the branch calls the old one. No conflict, because the changes are in different places. The failure exists only in the merge.

**Step 4: the wrong reflex.**

<!-- snippet: ch20b/lab-28-2-merge-ref/04-failure -->
```text
# Re-checking the branch alone reproduces nothing, however often it is repeated:
$ git switch --quiet feature/bulk-reorder
$ python3 tests/check_bulk.py
ok: bulk reorder
[exit status: 0]
```
<!-- /snippet -->

Back on the branch, the check passes again. The comment in the transcript is the lesson: re-checking the branch alone reproduces nothing, however often it is repeated. On GitHub the equivalent is pressing re-run, and you know from V145 that a re-run reuses the original commit.

**Step 5: recovery.**

```bash
git merge --quiet -m "Merge main into feature/bulk-reorder" main
python3 tests/check_bulk.py
```

<!-- snippet: ch20b/lab-28-2-merge-ref/05-recovery -->
```text
# Bring the base into the branch, then fix the call that the base change broke.
$ git merge --quiet -m "Merge main into feature/bulk-reorder" main
$ python3 tests/check_bulk.py
FAIL: TypeError: needs_reorder() missing 1 required positional argument: 'safety_stock'
[exit status: 1]
$ sed -i.bak 's/needs_reorder(stock, daily, lead_days)/needs_reorder(stock, daily, lead_days, 0)/' src/warehouse/bulk.py && rm src/warehouse/bulk.py.bak
$ python3 tests/check_bulk.py
ok: bulk reorder
[exit status: 0]
$ git commit -q -am "Pass the safety stock to needs_reorder"
$ git log --oneline --graph -4
* 2cb0b73 Pass the safety stock to needs_reorder
*   9c7cc7e Merge main into feature/bulk-reorder
|\  
| * 2230054 Require a safety stock in the reorder rules
* | 34f82ef Add bulk reorder
|/  
```
<!-- /snippet -->

Bring the base into the branch, and the failure is now on the branch, where you can work on it. One call is fixed and committed; `git commit` is 🟢 SAFE. The graph shows the merge `9c7cc7e` and the fix `2cb0b73` on top.

**Step 6: verify the same way CI will.**

<!-- snippet: ch20b/lab-28-2-merge-ref/06-verify -->
```text
$ git switch --quiet --detach main
$ git merge --quiet --no-ff -m "Test merge" feature/bulk-reorder
$ python3 tests/check_rules.py && python3 tests/check_bulk.py
ok: 2 checks
ok: bulk reorder
[exit status: 0]
$ git switch --quiet feature/bulk-reorder
$ git status --short --branch
## feature/bulk-reorder
```
<!-- /snippet -->

A new test merge on a detached HEAD, both checks pass, and you return to the branch with a clean status. You have verified the thing the next run will test, before pushing.

Count what you did not do: you never read a log. Step 2 of the order answered the question.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough.

Lab 28.2 on your practice repository, in your normal shell. The interface changes; the lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

Take a failing run from the lab and go down the list with the run page and the CLI side by side. For step 1 and 2, find on the run page the workflow name, the event, the branch and the commit ID, and compare the commit ID with `git rev-parse HEAD` in your clone. For step 3, read the `permissions` blocks of the workflow file at that commit. For step 4, expand the "Set up job" section and find the image. For step 5, look at whether the job names an environment. Only when you reach step 9, expand the failed step. Write down at which step you had the answer.

## COMMON MISTAKES

1. **Reading the log first.** Root cause: most failures are decided before the first log line, by the workflow file, the event, the commit, the token or the machine.
2. **Re-running to reproduce or to "pick up main".** Root cause: a re-run reuses the original commit and ref.
3. **Using `-latest` labels and being surprised by a change.** Root cause: a `-latest` label is a moving name, and migrations roll out gradually over weeks.
4. **A persistent self-hosted runner for a repository that accepts pull requests from forks.** Root cause: the machine runs whatever a workflow tells it, and what one job leaves behind is there for the next.
5. **Many one-step jobs "for clarity".** Root cause: each job is rounded up to a whole minute and starts on a new machine.

## PRODUCTION EXAMPLE

Two cases from the textbook, both from ML teams.

The first. A model-evaluation job that fits in the team's public mirror is killed in the private repository, with identical code. The textbook's instruction: ask first for the visibility of the repository, then for the label. Public means 4 CPUs and 16 GB; private means 2 and 8. That is step 4 of the order, and no log line will say it in those words.

The second. An ML team runs GPU evaluation on its own machines, because hosted GPU minutes are expensive. The textbook calls this the defensible design: ephemeral runners, in a runner group that only the evaluation repository may use; workflows on those runners triggered only by `push` to protected branches and by `workflow_dispatch`, never by `pull_request` from forks; and no long-lived cloud credentials on the machine.

## PRACTICE EXERCISE

Do Lab 28.2, "The investigation order, applied to a failing run", in [`lab-manual/m28-runners-debugging-ci.md`](../../lab-manual/m28-runners-debugging-ci.md).

Before you open anything, write the twelve steps from memory. Then, for the failing run, predict at which step the cause will show itself, and write that number down before you start.

The challenge is Exercise 28.4, "What does this pipeline cost?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q290: "In which order do you investigate a failed run, and why is the log not first?"

A strong answer gives the order as a list with one question per step, and then the principle behind it: what it means that an early answer makes the later steps irrelevant. It names the two steps that remove the most confusion for the least effort and the one comparison you make first. The follow-up asks for a concrete case in which reading the log first costs an hour that the second step would have saved; you have replayed one, so tell it with the commits named.

## RECAP

You should now be able to say:

- A hosted runner is a fresh virtual machine per job from an image that changes; a `-latest` label is a moving name.
- A self-hosted runner runs whatever a workflow tells it with the machine's access, and persists unless it is ephemeral, disk included.
- Jobs are rounded up to whole minutes; private repositories get smaller standard runners; prices and limits must be checked on the day.
- The investigation order is workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency.
- The log is ninth because everything above it was decided before the first log line.

## HOMEWORK

Read sections 20B.8 to 20B.11 of [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md). Do Exercise 28.1, "Where in the order?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).
