# V154: Required checks that stay pending, the debugging instruments, linting, and what a local emulator cannot reproduce

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 28
- **Planned minutes.** 24
- **Prerequisites.** V132, V153
- **Textbook sections.** [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), sections 20B.13 to 20B.18
- **Demo scripts.** `labs/ch20b/lab-28-1-broken-workflows.sh`; the six files in `workflows/broken/`, which are teaching material with faults on purpose; a screen walkthrough of Lab 28.1 in [`lab-manual/m28-runners-debugging-ci.md`](../../lab-manual/m28-runners-debugging-ci.md)

## HOOK

**[ON SCREEN]** A merge box. One line: a required check, "Waiting for status to be reported". No run exists.

Every pull request that touches only documentation is stuck like this. There is no red check to click on, no log to read, no failed step. Someone suggests re-running the workflow. There is nothing to re-run. Someone else starts the workflow by hand on the branch. It goes green, and the merge box still waits.

Both attempts were reasonable and both were wrong, for reasons that are written in the documentation. A workflow that was filtered out never reports the name the rule is waiting for. And a run started by hand is not evaluated for the pull request. This video is about the design that makes the situation impossible, and about the instruments you use when a run does exist.

## INTRODUCTION

This is the last teaching video of Part 6. It gathers what you need at the moment a pull request is stuck or a run is red.

Four topics, in the order of sections 20B.13 to 20B.15. Required checks that stay pending: five situations, what the check reports in each, and one design that survives all of them. The debugging instruments: reading a failure, re-running and what a re-run really is, debug logging, and managing workflows from the terminal. Linting: what can be caught before the push. And the limits of a local emulator.

The demonstration uses Lab 28.1. Its six workflow files are in `workflows/broken/`. They have faults on purpose. Never copy them into a repository you care about; the lab has you add one at a time to your practice repository, observe, fix, and remove.

## LEARNING OBJECTIVES

After this video you can:

- give the causes of a required check that waits forever and the design that avoids each;
- diagnose six broken workflows, each with a different documented root cause;
- use the instruments: failed-step logs, rerun with debug logging, watch, cache listing;
- say exactly what `gh run rerun` re-runs and why that is dangerous for a deployment;
- say what a linter finds before a push and what a local emulator cannot tell you.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub and GitHub Actions.

**Required checks that stay pending.** The ruleset side is GitHub, from Chapter 18. The reporting side is GitHub Actions. A check is required by name, and here is what reports that name in five situations.

**[ON SCREEN]** The table of section 20B.13.

The workflow never started, because of a path filter, a branch filter, or `[skip ci]` in the commit message. The check reports nothing. It stays pending. The merge is blocked.

The workflow started and the job was skipped by its `if`. The check reports success, because skipped counts as passing. The merge is allowed.

A job was skipped because a job it needs failed. It is skipped, so it may not block. The merge is allowed, and the textbook adds one word: wrongly.

The check ran on a `workflow_dispatch` run of the head branch. It is not evaluated for the pull request. The merge is blocked.

A merge queue is used and the workflow lacks `on: merge_group`. Nothing is reported in the queue. The merge is blocked in the queue.

Three of those five block a merge that has nothing wrong with it. Two let a merge through without a real result. And a path filter has its own edges, which you heard in V143: a push with more than 1,000 commits always runs the workflow, and with more than 3,000 changed files a match beyond the first 3,000 is not seen.

**The robust design.** The textbook is careful about its status: the Phase 0 report labels it an inference from these rules. Do not filter the workflow. Start it always. Decide inside which jobs to run, with `if`. And require one aggregate job that always runs and fails when something it needs failed or was cancelled.

```yaml
  all-checks:
    name: all-checks
    if: ${{ !cancelled() }}
    needs: [unit-tests, lint]
    runs-on: ubuntu-24.04
    steps:
      - name: Fail if a needed job failed or was cancelled
        if: ${{ contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled') }}
        run: exit 1
```

Read it against the table. The workflow has no filter, so the name is always reported: that removes row one. The job's own `if` is `!cancelled()`, so it is not skipped when a needed job fails: that removes row three. And its one step fails the job when any needed result is a failure or a cancellation. Require `all-checks` in the ruleset and nothing else. The matrix and the job list can then change without touching the rule.

**The instruments. Read the failure first.**

```bash
gh run list --workflow 08-deploy-staging.yml --limit 5
gh run view RUN_ID
gh run view RUN_ID --log-failed
gh run view RUN_ID --json event,headBranch,headSha,conclusion,jobs
gh run watch RUN_ID --exit-status
gh pr checks --watch
```

All 🟢 SAFE; they change nothing. `--log-failed` prints the log of the failed steps only. `gh run watch` follows a run until it ends and, with `--exit-status`, exits non-zero when it fails, so it can be chained in a script. `gh pr checks` exits with status 8 while checks are pending. The flags are from the help output of GitHub CLI 2.88.1.

**Re-run.** The textbook starts with a correction: a re-run is not a new run. It uses, in the documentation's words, "the same `GITHUB_SHA` and `GITHUB_REF` of the original event", and the privileges of the actor who triggered the original. It is possible for 30 days, and at most 50 times.

```bash
gh run rerun RUN_ID --failed
gh run rerun RUN_ID --failed --debug
gh run rerun --job JOB_ID
```

`gh run rerun` is 🟡 CAUTION. What it changes: a new attempt of the same run, at the original commit and ref; new checks on that commit; and for a deploy workflow, a new deployment of that commit. That last part is the danger. Re-running last week's deploy run deploys last week's commit over today's. The preview: `gh run view` with the JSON field `headSha`, compared with `main`. The textbook's rule: use a re-run to retry a flaky step of the latest run, and a fresh run for everything else.

**Debug logging.** Two switches, each a repository secret or variable set to `true`; the secret wins if both exist. `ACTIONS_STEP_DEBUG` adds debug lines to step logs. `ACTIONS_RUNNER_DEBUG` adds runner and worker diagnostic logs to the downloaded log archive. For one run, `gh run rerun --debug`, or the checkbox on the re-run dialog, does the same without leaving the switch on. Anyone who may run the workflow may enable it.

**Skipped jobs.** Since 29 January 2026 the log of a skipped job shows the original `if` expression and its expanded values.

**Run and manage workflows.**

```bash
gh workflow list --all
gh workflow view 09-environments.yml --yaml
gh workflow run 09-environments.yml --ref main
gh cache list --key Linux-inventory-api
```

The listing and viewing commands are 🟢 SAFE. `gh workflow run` is 🟡 CAUTION: it starts a run, and on a deploy workflow, a deployment; the preview is to read the file with `gh workflow view --yaml`. It needs `on: workflow_dispatch` in the file on the default branch. And, as in the hook, a run started this way does not satisfy a required check of a pull request.

One warning. Dumping the whole `github` context into a log is a documented debugging aid, and that context contains the token. Print the fields you need.

**Linting.** Catch what can be caught before the push. `actionlint` checks workflow syntax, expression types and embedded shell. The GitHub Actions language service in the editor does part of that while you type. Neither is installed for this course. The course's own check is only that each file parses as YAML and has `on` and `jobs`, which finds indentation errors and nothing else.

Then the sentence that sets the expectation: all six broken workflows of Lab 28.1 pass that check, and a linter would pass most of them too. A linter proves that a file is well formed. It cannot know that the history is shallow or that a secret is withheld.

**A local emulator.** `act` runs workflows locally in Docker containers. Its own documentation lists what it does not implement: `concurrency`, job `permissions`, `environment`, OIDC, `timeout-minutes`, `continue-on-error`, step summaries, and a complete `github` context. The textbook's verdict: useful for the shell logic of steps, and useless for exactly the topics of this chapter: gates, tokens, groups, runner images. Treat a green local run as evidence about your scripts, never about your deployment.

## MENTAL MODEL

A required check is a name, and the rule waits for somebody to say that name with a result.

Picture a roll call. The rule reads a name from its list and waits for an answer. If the workflow that owns the name was never started, nobody is in the room to answer, and the rule keeps waiting. It does not conclude "absent means fine". If the job was in the room and was told by its `if` to sit this one out, it answers "present", and that counts.

Where the picture breaks: at a roll call, anyone can see the empty chair. In a merge box, a check that will never report and a check that will report in two minutes look alike. You tell them apart by asking whether a run exists at all, which is step 1 of the investigation order.

The aggregate job is the one person who is always in the room and answers for everyone else, truthfully.

And a model for the instruments: each one is tied to a step of the order. `gh run view` with JSON fields is steps 1 and 2. `--log-failed` is step 9. `gh run download` is step 10. `gh cache list` is step 11. `gh run list` for the workflow is step 12. If you reach for an instrument, know which step you are on.

## DIAGRAM

**[DIAGRAM]** A pull request on the left with its changed paths. A ruleset in the middle that requires a check named X. Two workflows on the right. Draw the first workflow reporting X. Then draw the second, filtered, and ask what it reports.

```text
  pull request                      ruleset on main                  workflows
  changed paths:                    requires check "X"
    docs/runbook.md                        |
                                           |   waits for the NAME "X"
                                           v
        (a) workflow without a filter  ---------------------------->  run exists, job X reports
            on: pull_request                                          success or failure
                                                                      => the rule gets its answer

        (b) workflow with  paths: ["src/**"]  ---- no path matches -> NO RUN.  Nothing reports "X".
            on: pull_request                                          => "expected", forever

        the design that removes (b):
            on: pull_request            (no filter)
            jobs:  unit-tests (if: ...),  lint (if: ...)
                   all-checks: if !cancelled(), needs both, fails on failure or cancelled
            ruleset requires "all-checks" only
```

**[DIAGRAM]** In case (b) there is nothing wrong with the pull request and nothing wrong with the workflow. The fault is in the combination: a filterable workflow owns a required name.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch20b/lab-28-1-broken-workflows`. It collects the evidence Git can give for four of the six broken workflows. The other two have no Git evidence: their causes are in the token and in the secrets, which are GitHub Actions objects.

The lab's instruction comes first: for each file, write your hypothesis and the line you suspect before you collect evidence.

**Workflow 1: "the version step fails with exit status 128 on every push to main."**

```bash
git clone --quiet --depth 1 --no-tags "file://$PWD" ../runner
git -C ../runner rev-list --count HEAD
git -C ../runner tag --list
git -C ../runner describe --tags --match 'v*'
git describe --tags --match 'v*'
```

`git clone` is 🟢 SAFE. You know this from the last video; say the cause before the output appears.

<!-- snippet: ch20b/lab-28-1-broken-workflows/01-shallow -->
```text
# Workflow 1. The job sees a clone like this one:
$ git clone --quiet --depth 1 --no-tags "file://$PWD" ../runner
$ git -C ../runner rev-list --count HEAD
1
$ git -C ../runner tag --list
$ git -C ../runner describe --tags --match 'v*'
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git describe --tags --match 'v*'
v1.1.0-2-g57c8425
```
<!-- /snippet -->

One commit, no tags, "No names found" with status 128 in the clone that is like the job's; the proper description in your own repository.

**Workflow 2: "a pull request that changes only docs cannot be merged; the merge box waits for the required check unit-tests; no run exists."**

```bash
git diff --name-only main...docs/rollback-steps
git diff --name-only main...feature/safety-stock
```

**[PAUSE]** The workflow has a path filter for `src`. For which of the two branches would it start?

<!-- snippet: ch20b/lab-28-1-broken-workflows/02-paths -->
```text
# Workflow 2. For a pull request, a path filter is evaluated on the three-dot diff:
$ git diff --name-only main...docs/rollback-steps
docs/runbook.md
$ git diff --name-only main...feature/safety-stock
src/warehouse/rules.py
uv.lock
```
<!-- /snippet -->

The documentation branch changed one file under `docs`. The feature branch changed a file under `src` and the lock file. The workflow starts for the second and not for the first. Its job is a required check. This is the hook, proven with a three-dot diff.

**Workflow 5: "runs on feature branches end as cancelled although nobody cancelled them."**

<!-- snippet: ch20b/lab-28-1-broken-workflows/03-refs -->
```text
# Workflow 5. Each of these refs gets pushes; a concurrency group should tell them apart:
$ git for-each-ref --format="%(refname)" refs/heads
refs/heads/docs/rollback-steps
refs/heads/feature/safety-stock
refs/heads/main
```
<!-- /snippet -->

Three refs receive pushes. You saw this snippet in V150. A concurrency group must tell them apart, and the report says it happens when a colleague pushes to a different branch at about the same time. Open the file and read its group name.

**Workflow 6: "a pull request added a dependency and updated the lock file; the tests fail in the job because the new package cannot be imported; the install step shows as skipped."**

```bash
git rev-parse main:uv.lock feature/safety-stock:uv.lock
git diff --stat main feature/safety-stock -- uv.lock
```

`git rev-parse` with a ref, a colon and a path prints the ID of the blob at that path. **[PAUSE]** If the two IDs differ, what must be true of a correct cache key on the two refs?

<!-- snippet: ch20b/lab-28-1-broken-workflows/04-cache-key -->
```text
# Workflow 6. A key built from the lock file changes exactly when the lock file does:
$ git rev-parse main:uv.lock feature/safety-stock:uv.lock
d4209093593c0ed4d1d0ef470f155c412e19b219
dfb559935055c75ba939582753a8735a0e1240ab
$ git diff --stat main feature/safety-stock -- uv.lock
 uv.lock | 4 ++++
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

Two different blob IDs, `d420909` on `main` and `dfb5599` on the branch, and four added lines. The lock file differs, so a key built from the lock file must differ too, and the branch must get a miss. The report says the install step was skipped, so something was restored. Read the file's key and its restore keys, and its condition for installing.

**The tempting repair.**

<!-- snippet: ch20b/lab-28-1-broken-workflows/05-failure -->
```text
# A tempting repair of workflow 1 that hides the fault instead of fixing it:
$ git -C ../runner describe --tags --match 'v*' --always
57c8425
```
<!-- /snippet -->

`--always`. The command now prints `57c8425` and the step is green. The comment in the transcript names it: a repair that hides the fault instead of fixing it. Section 20B.17 has a list of these: `continue-on-error`, "or true", `--always`, broader restore keys. Each hides a cause from the next engineer.

<!-- snippet: ch20b/lab-28-1-broken-workflows/06-recovery -->
```text
$ git -C ../runner fetch --quiet --unshallow --tags
$ git -C ../runner describe --tags --match 'v*'
v1.1.0-2-g57c8425
```
<!-- /snippet -->

The real repair, in Git terms: the full history and the tags. `git fetch --unshallow --tags` is 🟢 SAFE.

Workflows 3 and 4 you diagnose by reading. The reports: for 3, the step that comments on the pull request fails for every pull request, including those from the repository's own branches, and the API refuses with a 403. For 4, green for every maintainer and red for the first pull request from an outside contributor's fork, with the workflow's own message that a secret is empty, although the secret exists. For each, read the file against the event that started the run, and ask step 3 and step 7 of the order.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough.

Part B of Lab 28.1, on your practice repository, in your normal shell. The interface changes; the lab text and the linked documentation are the reference. No GitHub output was captured by the authors. These six reports are constructed descriptions written from the documented behavior; they are not captured logs.

Add one broken file at a time. For each: observe, fix it yourself, observe again, remove it. The lab asks for at least workflows 1, 3 and 5.

For workflow 1, after the push, list the runs and print the failed step's log with the instrument for step 9. For workflow 3, open the failed step and find the status code; then read the `permissions` of the file. For workflow 5, push to two branches in quick succession and look at the run list for the conclusion of each run. Each time, before you fix anything, say which step of the order gave you the cause.

## COMMON MISTAKES

1. **Requiring a check that a filterable workflow owns.** Root cause: a workflow that never started reports nothing, and the required check stays pending.
2. **Trying to satisfy a pull request's required check with `gh workflow run`.** Root cause: a check from a `workflow_dispatch` run of the head branch is not evaluated for the pull request.
3. **An aggregate job without `!cancelled()`.** Root cause: a job that needs a failed job is skipped, and a skipped job counts as passing.
4. **Re-running an old deploy run.** Root cause: a re-run uses the same commit and ref as the original event, so it deploys old code over new.
5. **Treating a green local emulator run as proof.** Root cause: the emulator does not implement concurrency, job permissions, environments or OIDC, and has no complete `github` context.

## PRODUCTION EXAMPLE

A platform team with a busy repository adopts a merge queue to stop pull requests from going out of date. On the first morning the queue fills and nothing leaves it. Every entry waits for the required check.

Go to the table. Row five: a merge queue is used and the workflow lacks `on: merge_group`. Nothing is reported in the queue. The workflow listens for `pull_request` and for `push`, and neither of those is the event of a merge group.

The fix is one more event in the trigger of the workflow that owns the required name. The lesson is the same as for the path filter: for every way a merge can be attempted, ask whether anything will say the required name. With one aggregate job as the only required check, that question has to be answered for exactly one workflow.

## PRACTICE EXERCISE

Do Lab 28.1, "Six broken workflows", in [`lab-manual/m28-runners-debugging-ci.md`](../../lab-manual/m28-runners-debugging-ci.md).

For each of the six, before any evidence: the hypothesis, the suspected line, and the layer. After the evidence: the root cause from the documentation, the smallest correct fix, and what would have prevented it. Each of the six has a different documented root cause; if two of your answers are the same, one is wrong.

The challenge is Exercise 28.7, "Every pull request is waiting", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q300: "A pull request shows "waiting for status to be reported" and no run exists. Name three causes and the design that avoids all of them."

A strong answer starts from what "required" means: a name, and something that must report it. It gives three distinct causes for nothing reporting, each with the documented mechanism, and then one design, with the reason each part of the design is there. It says how you would confirm which cause applies before changing anything. The follow-up asks how you predict, before pushing, whether a path-filtered workflow will start, and where that prediction breaks down; you know the command, and you have heard the two edges of the filter.

## RECAP

You should now be able to say:

- A check is required by name; a workflow that was filtered out never reports that name, and a manually started run does not count for the pull request.
- A job skipped by its `if` counts as passing, and so does a job skipped because a needed job failed.
- The design that avoids all of it: no filter on the workflow, decisions inside jobs, and one aggregate job with `!cancelled()` as the only required check.
- A re-run is a new attempt at the original commit and ref; on a deploy workflow it is a rollback nobody announced.
- A linter proves a file is well formed; a local emulator is evidence about your scripts and never about gates, tokens, groups or runner images.

## HOMEWORK

Read sections 20B.13 to 20B.18 of [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md) and do the Practice section 20B.20. Do Exercise 28.3, "A required check that cannot be red", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md). Read [`guides/github-actions-guide.md`](../../guides/github-actions-guide.md) and [`cheatsheets/github-actions-cheat-sheet.md`](../../cheatsheets/github-actions-cheat-sheet.md).
