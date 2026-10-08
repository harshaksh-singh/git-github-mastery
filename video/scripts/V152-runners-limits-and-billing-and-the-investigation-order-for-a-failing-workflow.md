# V152: Runners, limits and billing, and the investigation order for a failing workflow

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 28
- **Planned minutes.** 26
- **Prerequisites.** V151
- **Textbook sections.** [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), sections 20B.8 to 20B.11
- **Demo scripts.** `labs/ch20b/lab-28-2-merge-ref.sh`, then a screen walkthrough of Lab 28.2 in [`lab-manual/m28-runners-debugging-ci.md`](../../lab-manual/m28-runners-debugging-ci.md)

## HOOK

**[ON SCREEN]** Two questions from section 20B.1. "The tests pass on my machine. Why is the pull request red?" "Why did our Actions bill triple?"

Take the first. A pull request is GitHub's proposal to merge one branch into another, and red means that one of its automated checks failed. The textbook's answer: almost always because the job didn't run what you ran. Another commit, another shell, another tool version, no secrets, an empty history. Each cause is a documented default. And then the sentence that separates two kinds of engineer. One who knows the defaults finds the cause in minutes. One who doesn't re-runs the job and hopes.

Re-running and hoping has a recognizable first move: open the red step and start reading the log. This video gives you a different first move, and eleven more after it. The log is step nine. Why ninth, and not first? Keep that question for the demonstration.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video opens the last module of Part 6: runners and debugging. A runner is the machine that runs one job, and a job is a list of steps in a workflow, the file that tells GitHub Actions what to run. From here to the gate, the subject is the skill that Chapter 20B says a CTO pays for: finding out why a run failed, in a fixed order, with evidence.

Four topics, in the order of sections 20B.8 to 20B.11. GitHub-hosted runners: what they are and why a label ending in `-latest` is a moving target. Self-hosted runners: the risks, and what "ephemeral" changes. Limits and billing, as the section gives them. And the investigation order for a failing workflow: twelve questions, from "did the right thing start at all" to "what did it say".

A note on the numbers. Limits and prices in this video are quoted from section 20B.10 and are re-verified on the recording day. If you watch this later, check the price page before you write a cost estimate. The textbook says the same.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- say what a GitHub-hosted runner is and why a `-latest` label is a moving target;
- state the risks of self-hosted runners and what "ephemeral" changes;
- state the limits and the billing model as the section gives them;
- recite the investigation order: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency;
- explain why the log is not the first thing to read.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**[ANIMATION]** gates: id=life gates=a_published_image:done:-:the_template|a_fresh_virtual_machine:done:-:selected_by_its_label|one_job:done|destroyed:done title=The_life_of_a_GitHub-hosted_runner at_1=30 at_2=45 at_3=70 at_4=85

**Hosted runners. In one sentence:** a GitHub-hosted runner is a fresh virtual machine, built from a published image, that runs one job and is then destroyed.

`runs-on` selects it by label. A virtual machine is a computer made in software, and the image is the template it's built from.

**[ANIMATION]** end

**[ON SCREEN]** The label table of section 20B.8, as of 1 October 2026.

`ubuntu-latest` is Ubuntu 24.04 on the first of October 2026, and GitHub has announced its migration to Ubuntu 26.04 between the nineteenth of October and the nineteenth of November 2026. `windows-latest` is Windows Server 2025. `macos-latest` is macOS 26 on arm64, moved from macOS 15 in June and July 2026. Then the fixed labels, which name a version. `ubuntu-22.04` is deprecated since the seventeenth of September 2026, with the end of support announced for the seventeenth of April 2027. For `macos-14` the announced end of support is the second of November 2026. Those three dates lie after the course baseline: check the changelog on the day you watch this. And `ubuntu-slim`: one CPU, runs the job in a container, with jobs limited to 15 minutes.

**[ANIMATION]** stores: id=latest boxes=Ubuntu_24.04:an_image|Ubuntu_26.04:an_image rows=1:A:ubuntu-latest,_on_1_October_2026@ref|2:B:ubuntu-latest,_after_the_announced_migration@ref|3:A:ubuntu-24.04:_a_fixed_label@hl|3:A:rebuilt_weekly:_tool_versions_move_too arrows=2:A1>B1:19_October_to_19_November_2026 title=A_-latest_label_is_a_moving_name at_1=20 at_2=45

**[ANIMATION]** step: 2

The textbook's comparison is one you can keep: a `-latest` label is a moving name, the runner equivalent of a branch. A migration is rolled out gradually over weeks, so two runs of one workflow on the same day can get different images.

**[ANIMATION]** step: 3

And a fixed label isn't frozen either. Images are rebuilt weekly, so tool versions inside a fixed label move too. The textbook's example: in May 2026 Node 20 left the images and the default `node` became 22. That's why the course workflows use a fixed label and also install their tools with setup actions at stated versions.

**[ANIMATION]** say: The_cost_of_pinning:_move_the_label_yourself_before_the_image_retires

The cost of pinning: you must move the label yourself before the image retires. Put the retirement dates in your calendar.

**[ANIMATION]** end

Where do you see which image a job received? The "Set up job" section of a run's log names it. The textbook adds a caveat that I pass on: the Phase 0 notes didn't verify that section separately, so read it in your own run.

**[ANIMATION]** walk: id=hw columns=standard_runners,CPUs,memory,disk rows=Linux_and_Windows,_public_repositories:4:16_GB:14_GB|Linux_and_Windows,_private_repositories:2:8_GB:14_GB|macOS_arm64:3:7_GB:- marks=2.2:bad,2.3:bad mono=off title=Hardware at_1=18 at_2=32 at_3=55

**Hardware.** Standard Linux and Windows runners have 4 CPUs and 16 gigabytes of memory in public repositories, and 2 CPUs and 8 gigabytes in private ones, with 14 gigabytes of disk in both. macOS arm64 runners have 3 CPUs and 7 gigabytes. So a test suite that fits in a public repository can run out of memory or time after the repository is made private.

**[ANIMATION]** stores: id=self boxes=a_GitHub-hosted_runner:a_clean_machine_per_job|a_persistent_self-hosted_runner:a_machine_you_operate|an_ephemeral_runner:registered_with_--ephemeral rows=1:A:destroyed_after_the_job@ok|1:B:runs_jobs_with_whatever_access_the_machine_has|2:B:a_pull_request_can_run_code_on_it@bad|2:B:can_be_persistently_compromised@bad|2:B:an_environment_does_not_isolate_secrets_here@bad|3:C:takes_one_job_and_is_removed@ok|3:C:reused_hardware_can_still_expose_information title=Whose_machine,_and_for_how_long? at_1=40 at_2=15 at_3=5

**[ANIMATION]** step: 1

**Self-hosted runners. In one sentence:** a self-hosted runner is the same runner program on a machine you operate, which asks GitHub for jobs and runs them with whatever access that machine has.

**[ANIMATION]** step: 2

The risk, in GitHub's own words from the secure use reference: self-hosted runners "should almost never be used for public repositories", because anyone can open a pull request that runs code on them. The warning extends to private repositories where anyone with read access can fork and open a pull request. A hosted runner is a clean machine per job. A persistent self-hosted runner "can be persistently compromised by untrusted code in a workflow". And on a self-hosted runner an environment doesn't isolate secrets from other jobs on the same machine.

**[ANIMATION]** step: 3

Ephemeral runners. Registering with the `--ephemeral` option gives a runner that takes one job and is removed. So-called just-in-time runners are created through the REST API and also run at most one job. GitHub recommends autoscaling with ephemeral runners and advises against autoscaling persistent ones. And one more sentence from the documentation: reusing hardware for such runners can still expose information from the environment. The textbook's reading: "ephemeral" must include the disk.

**[ANIMATION]** end

Runner groups restrict which repositories may send jobs to which runners. They're available to organizations on every plan since the seventeenth of October 2024. The risk is a group open to "all repositories": every repository in the organization, including the least reviewed one, can run code on the machines that can reach production.

Versions. Since the twenty-ninth of September 2026 a runner older than 2.329.0 can't register on github.com, and a runner must install each new release within 30 days or it stops receiving jobs. That bites fleets built from a fixed image with updates disabled.

Queueing. A job waits until a matching runner is online and fails after 24 hours in the queue. A self-hosted job may run for up to five days.

**Limits.**

**[ON SCREEN]** The limits table of section 20B.10.

A job on a GitHub-hosted runner: 6 hours. A workflow run, including waiting for approval: 35 days. An environment approval: fails after 30 days. A matrix: 256 jobs per run. Re-runs: 50 per workflow run, within 30 days of the first run. Reusable workflows: 10 levels, 50 unique called workflows per file.

Concurrent jobs on standard runners: 20 on Free, 40 on Pro, 60 on Team, 500 on Enterprise. For macOS, 5, or 50 on Enterprise. Cache: ten gigabytes per repository without charge, with entries unused for seven days evicted. Artifacts and logs: 90 days by default, and since the first of October 2026 the same setting also removes checks, runs and statuses.

**Billing.** Standard hosted runners are free in public repositories. Self-hosted runners are free. Private repositories include 2,000 minutes per month on Free, 3,000 on Pro and Team, and 50,000 on Enterprise Cloud, with artifact storage allowances that are shared with GitHub Packages.

List prices per minute since the first of January 2026: Linux 2-core, 0.6 cents. Linux arm64 2-core, 0.5 cents. `ubuntu-slim`, 0.2 cents. Windows 2-core, 1 cent. macOS, 6.2 cents. Each job is rounded up to a whole minute. Storage beyond the allowance: artifacts 25 cents and cache 7 cents per gigabyte per month. Larger runners are always billed, in public repositories too. A reusable workflow is billed to the caller. Time spent in a wait timer isn't billed.

**[ON SCREEN]** Callout: Unverified. How Windows and macOS minutes consume the included minutes is not stated on any 2026 page the Phase 0 research could fetch. Older material gives multipliers of 2 for Windows and 10 for macOS; the old multiplier page now redirects to the price list. Do not quote a multiplier. Read your own usage in the billing settings.

One thing here is unverified, and it's on screen. How Windows and macOS minutes consume the included minutes isn't stated on any 2026 page the research could fetch. Don't quote a multiplier. Read your own usage in the billing settings.

**[ON SCREEN]** Callout: Version note. Tutorials quote prices from before 2026; prices were cut by up to 39 percent on 1 January 2026. And one item is announced and not in effect: a charge of 0.2 cents per minute for self-hosted runners, announced on 16 December 2025 for 1 March 2026 and then postponed without a new date.

And a version note. Prices were cut by up to 39 percent on the first of January 2026, so older tutorials quote more. One charge is announced and not in effect: 0.2 cents per minute for self-hosted runners, postponed without a new date.

Quick quiz, on that rounding rule. Which costs more? A, one job with ten steps of six seconds each. B, ten jobs with one six-second step each. Your answer?

**[PAUSE]**

**[ANIMATION]** bars: id=round bars=one_job,_ten_steps:1|ten_jobs,_one_step_each:10 unit=min title=Each_job_is_rounded_up_to_a_whole_minute at_1=10 at_2=40

B. Each job is rounded up to a whole minute, so ten short jobs are billed as ten minutes, and the one job as one. Almost everyone misses that once, because the work is the same.

**[ANIMATION]** end

The cost levers follow from the rules. Cancel superseded CI runs with a concurrency group. Prefer one job with several steps over many one-step jobs, because each job rounds up. Keep macOS for what needs macOS, at roughly ten times the Linux price. Use `ubuntu-slim` for glue jobs. Shorten artifact retention. Path filters also save minutes, and video 154 shows what they cost you.

**[ANIMATION]** stores: id=order boxes=steps_1_to_4:did_the_right_thing_start_at_all?|steps_5_to_8:still_before_the_first_log_line|steps_9_to_12:what_did_it_say? rows=1:A:1_workflow|2:A:2_event|3:A:3_permissions|4:A:4_runner|5:B:5_environment|6:B:6_dependencies|7:B:7_secrets|8:B:8_action_versions title=The_investigation_order

**[ANIMATION]** step: boxes

**The investigation order.** The textbook's instruction: a failing run tempts you to open the red step and start reading. Do that last but three. The order goes from "did the right thing start at all" to "what did it say", because an answer early in the list makes everything after it irrelevant.

**[ANIMATION]** step: 1

One. Workflow. Which workflow file, from which commit, defined this run?

**[ANIMATION]** step: 2

Two. Event. What triggered it, and which ref and commit did the job check out? `push` builds the pushed commit. `pull_request` builds `refs/pull/N/merge`. A re-run reuses the original commit and ref.

**[ANIMATION]** step: 3

Three. Permissions. What could the token do? Top-level and job-level `permissions`. Unlisted scopes are none. Fork and Dependabot runs get a read-only token.

**[ANIMATION]** step: 4

Four. Runner. Which image, which size? The label, the image named at the top of the job log, and whether the repository is public or private.

**[ANIMATION]** step: 5

Five. Environment. Did the job reference one, and did its rules pass? Waiting, rejected, wrong branch, or an environment created by accident.

**[ANIMATION]** step: 6

Six. Dependencies. Were the same versions installed as locally? The lock file, `--locked`, the versions printed by setup steps.

**[ANIMATION]** step: 7

Seven. Secrets. Were they present? An unset or withheld secret is an empty string, not an error.

**[ANIMATION]** step: 8

Eight. Action versions. Which commit of each action ran? The pins, an old major on Node 24, a moved tag.

**[ANIMATION]** stores: id=order2 boxes=steps_1_to_4:did_the_right_thing_start_at_all?|steps_5_to_8:still_before_the_first_log_line|steps_9_to_12:what_did_it_say? rows=1:A:1_workflow|1:A:2_event|1:A:3_permissions|1:A:4_runner|1:B:5_environment|1:B:6_dependencies|1:B:7_secrets|1:B:8_action_versions|2:C:9_logs@hl|3:C:10_artifacts|4:C:11_cache|5:C:12_concurrency title=The_investigation_order at_1=3 at_2=40

**[ANIMATION]** step: 2

Nine. Logs. What did the failed step print?

**[ANIMATION]** step: 3

Ten. Artifacts. Were the expected files produced and passed on?

**[ANIMATION]** step: 4

Eleven. Cache. What was restored, under which key?

**[ANIMATION]** step: 5

Twelve. Concurrency. Was the run cancelled or replaced by another?

**[ANIMATION]** end

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

A picture helps.

**[ANIMATION]** step: self.3

**[ANIMATION]** say: A_rented_workshop_is_demolished_after_each_job._Yours_stays

**Analogy for self-hosted runners,** from the textbook. Lending your workshop to anyone who holds a work order. A GitHub-hosted runner is a rented workshop that is demolished after each job. Yours stays: tools, leftovers, and everything a previous visitor hid there.

The analogy breaks in one respect, and the textbook says that respect is everything: you choose who may write work orders, and that choice is the whole security question.

**[ANIMATION]** step: order2.5

**[ANIMATION]** say: A_chain_of_decisions,_each_made_before_the_next_can_matter

**A model for the investigation order.** Think of a run as a chain of decisions, each made before the next can matter. Was a run created, from which file? For which commit? With what authority? On what machine? Past which gate? With which dependencies, which secrets, which action code? Only then does your command start and print anything.

**[ANIMATION]** say: If_an_earlier_link_was_different,_the_log_records_the_wrong_experiment

The log is the output of the last link. If an earlier link was different from what you assume, the log is a faithful record of the wrong experiment. You can read it for an hour and learn nothing, because nothing in it says "this is not the commit you think".

**[ANIMATION]** say: The_log_is_ninth:_eight_things_were_decided_before_its_first_line

That's why the order is fixed and why the log sits at nine, which answers the question from the opening. The three steps after it, artifacts, cache and concurrency, are about what the run handed on or was done to it.

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

Try it now, on paper. Thirty seconds. Look away from the screen and write the first four words of the order. Then check them.

**[PAUSE]**

Workflow, event, permissions, runner. If you had the first two, you have the two that remove the most confusion for the least effort.

**[DIAGRAM]** Say the twelve words in order once, aloud: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency. You will be asked for them.

## LIVE TERMINAL DEMO

Into the lab.

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

On the branch `feature/bulk-reorder`, both checks pass. The developer isn't wrong about that.

**Step 2 of the order, before any log: which commit did the job check out?** For a `pull_request` run you know the answer in kind: the test merge. So look at the two sides of that merge.

```bash
git log --oneline --graph --format="%h %an: %s" main feature/bulk-reorder -4
git merge-base main feature/bulk-reorder
```

What do you expect to see on `main` that the branch doesn't have? Say it out loud.

**[PAUSE]**

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

**[ANIMATION]** graph: id=sides ...older-197d992-57c8425-2230054 main; ^57c8425-34f82ef feature/bulk-reorder; HEAD=feature/bulk-reorder; title:Two_sides_of_the_test_merge => + 2230054-?test_merge; 34f82ef-?test_merge; HEAD=none; note:?test_merge:HEAD_(no_branch); pass:34f82ef; fail:?test_merge; name:merge; say:The_failure_exists_only_in_the_merge => + reflog:?test_merge; 34f82ef-9c7cc7e-2cb0b73 feature/bulk-reorder; 2230054-9c7cc7e; HEAD=feature/bulk-reorder; drop:34f82ef; pass:2cb0b73; name:fixed; say:The_base_is_merged_into_the_branch,_and_the_call_is_fixed dx=230

**[ANIMATION]** step: state-1

`main` has a commit by Asha, `2230054`, "Require a safety stock in the reorder rules". The branch has `34f82ef`, "Add bulk reorder". They share the merge base `57c8425`, the most recent commit that both histories contain. Two people changed related code on two sides.

**Step 3: build what the pull request run checks out.**

```bash
git merge-tree --write-tree main feature/bulk-reorder
git switch --quiet --detach main
git merge --quiet --no-ff -m "Merge feature/bulk-reorder into main (test merge)" feature/bulk-reorder
python3 tests/check_rules.py
python3 tests/check_bulk.py
```

`git merge-tree` reads and writes an unreferenced tree. The switch detaches HEAD on `main` so that no branch moves. `git merge` is 🟡 CAUTION, and here it moves only the detached HEAD.

The merge is clean. Will both checks pass on it? Make your prediction.

**[PAUSE]**

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

"HEAD (no branch)", as on the runner. The first check passes. The second fails with a `TypeError`: a function now needs an argument that the new code doesn't pass.

**[ANIMATION]** step: sides.merge

Asha's commit changed a signature, and the branch calls the old one. No conflict, because the changes are in different places. The failure exists only in the merge.

**[ANIMATION]** end

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

Back on the branch, the check passes again. The comment in the transcript is the lesson: re-checking the branch alone reproduces nothing, however often it's repeated. On GitHub the equivalent is pressing re-run, and you know from video 145 that a re-run reuses the original commit.

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

Bring the base into the branch, and the failure is now on the branch, where you can work on it. One call is fixed and committed, and `git commit` is 🟢 SAFE.

**[ANIMATION]** step: sides.fixed

The graph shows the merge `9c7cc7e` and the fix `2cb0b73` on top.

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

Count what you didn't do: you never read a log. Step 2 of the order answered the question.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough.

**Lab 28.2 on your practice repository, in your normal shell.** The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

Take a failing run from the lab and go down the list with the run page and the CLI side by side. For step 1 and 2, find on the run page the workflow name, the event, the branch and the commit ID, and compare the commit ID with `git rev-parse HEAD` in your clone. For step 3, read the `permissions` blocks of the workflow file at that commit. For step 4, expand the "Set up job" section and find the image. For step 5, look at whether the job names an environment. Only when you reach step 9, expand the failed step. Write down at which step you had the answer.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Reading the log first.** Root cause: most failures are decided before the first log line, by the workflow file, the event, the commit, the token or the machine.
2. **Re-running to reproduce or to "pick up main".** Root cause: a re-run reuses the original commit and ref.
3. **Using `-latest` labels and being surprised by a change.** Root cause: a `-latest` label is a moving name, and migrations roll out gradually over weeks.
4. **A persistent self-hosted runner for a repository that accepts pull requests from forks.** Root cause: the machine runs whatever a workflow tells it, and what one job leaves behind is there for the next.
5. **Many one-step jobs "for clarity".** Root cause: each job is rounded up to a whole minute and starts on a new machine.

## PRODUCTION EXAMPLE

Now, out of the lab. Two cases from the textbook, both from ML teams.

**[ANIMATION]** step: hw.3

**[ANIMATION]** say: Step_4_of_the_order:_ask_first_for_the_visibility,_then_for_the_label

The first. A model-evaluation job that fits in the team's public mirror is killed in the private repository, with identical code. The textbook's instruction: ask first for the visibility of the repository, then for the label. Public means 4 CPUs and 16 gigabytes. Private means 2 and 8. That's step 4 of the order, and no log line will say it in those words.

**[ANIMATION]** cards: id=gpu question=The_defensible_design_for_GPU_evaluation_on_your_own_machines cards=ephemeral_runners|a_runner_group:only_the_evaluation_repository_may_use_it|push_to_protected_branches,_and_workflow__dispatch|never_pull__request_from_forks|no_long-lived_cloud_credentials:on_the_machine at_1=35 at_2=45 at_3=60 at_4=78 at_5=88

The second. An ML team runs GPU evaluation on its own machines, because hosted GPU minutes are expensive. The textbook calls this the defensible design. Ephemeral runners, in a runner group that only the evaluation repository may use. Workflows on those runners triggered only by `push` to protected branches and by `workflow_dispatch`, never by `pull_request` from forks. And no long-lived cloud credentials on the machine.

## PRACTICE EXERCISE

Your turn. Do Lab 28.2, "The investigation order, applied to a failing run", in [`lab-manual/m28-runners-debugging-ci.md`](../../lab-manual/m28-runners-debugging-ci.md).

Before you open anything, write the twelve steps from memory. Then, for the failing run, predict at which step the cause will show itself, and write that number down before you start.

The challenge is Exercise 28.4, "What does this pipeline cost?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q290: "In which order do you investigate a failed run, and why is the log not first?"

**[PAUSE]**

Answer out loud. A strong answer gives the order as a list with one question per step, and then the principle behind it: what it means that an early answer makes the later steps irrelevant. It names the two steps that remove the most confusion for the least effort and the one comparison you make first. The follow-up asks for a concrete case in which reading the log first costs an hour that the second step would have saved. You've replayed one, so tell it with the commits named.

## RECAP

Let's land this.

You should now be able to say:

- A hosted runner is a fresh virtual machine per job from an image that changes; a `-latest` label is a moving name.
- A self-hosted runner runs whatever a workflow tells it with the machine's access, and persists unless it is ephemeral, disk included.
- Jobs are rounded up to whole minutes; private repositories get smaller standard runners; prices and limits must be checked on the day.
- The investigation order is workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency.
- The log is ninth because everything above it was decided before the first log line.

## HOMEWORK

Read sections 20B.8 to 20B.11 of [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md). Do Exercise 28.1, "Where in the order?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

You now have a first move that isn't the log, and eleven more after it. Write the twelve words from memory once today. Next time: passes locally, fails on GitHub Actions, and the documented causes. Until then, look at the state first and type second. See you in the next one.
