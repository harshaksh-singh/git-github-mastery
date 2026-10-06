# V154: Required checks that stay pending, the debugging instruments, linting, and what a local emulator cannot reproduce

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 28
- **Planned minutes.** 24
- **Prerequisites.** V132, V153
- **Textbook sections.** [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), sections 20B.13 to 20B.18
- **Demo scripts.** `labs/ch20b/lab-28-1-broken-workflows.sh`; the six files in `workflows/broken/`, which are teaching material with faults on purpose; a screen walkthrough of Lab 28.1 in [`lab-manual/m28-runners-debugging-ci.md`](../../lab-manual/m28-runners-debugging-ci.md)

## HOOK

**[ON SCREEN]** A merge box. One line: a required check, "Waiting for status to be reported". No run exists.

A pull request is GitHub's proposal to merge one branch into another, and the merge box is where GitHub says whether it may merge. A required check is a result that a rule says must be reported as passing first. Every pull request that touches only documentation is stuck like this. There's no red check to click on, no log to read, no failed step. Someone suggests re-running the workflow. There is nothing to re-run. Someone else starts the workflow by hand on the branch. It goes green, and the merge box still waits.

Why would a green run, started by hand, not count? Say your guess out loud.

**[PAUSE]**

**[ANIMATION]** walk: id=tries columns=what_was_tried,why_it_did_not_count rows=the_filtered_workflow:it_never_reports_the_name_the_rule_waits_for|re-run_the_workflow:there_is_nothing_to_re-run|start_it_by_hand_on_the_branch:not_evaluated_for_the_pull_request marks=1.2:wait,2.2:bad,3.2:bad mono=off title=Waiting_for_status_to_be_reported at_1=22 at_2=30 at_3=38

Both attempts were reasonable and both were wrong, for reasons that are written in the documentation. A workflow that was filtered out never reports the name the rule is waiting for. And a run started by hand isn't evaluated for the pull request. This video is about the design that makes the situation impossible, and about the instruments you use when a run does exist. That design is one small job. Watch for it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A workflow is a file that tells GitHub Actions which jobs to run when an event happens, and a run is one execution of it. This is the last teaching video of Part 6. It gathers what you need at the moment a pull request is stuck or a run is red.

Four topics, in the order of sections 20B.13 to 20B.15. Required checks that stay pending: five situations, what the check reports in each, and one design that survives all of them. The debugging instruments: reading a failure, re-running and what a re-run really is, debug logging, and managing workflows from the terminal. Linting: what can be caught before the push. And the limits of a local emulator.

The demonstration uses Lab 28.1. Its six workflow files are in `workflows/broken/`. They have faults on purpose. Never copy them into a repository you care about. The lab has you add one at a time to your practice repository, observe, fix, and remove.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- give the causes of a required check that waits forever and the design that avoids each;
- diagnose six broken workflows, each with a different documented root cause;
- use the instruments: failed-step logs, rerun with debug logging, watch, cache listing;
- say exactly what `gh run rerun` re-runs and why that is dangerous for a deployment;
- say what a linter finds before a push and what a local emulator cannot tell you.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub and GitHub Actions.

**Required checks that stay pending.** The ruleset side is GitHub, from Chapter 18, and a ruleset is a named list of rules for branches. The reporting side is GitHub Actions. A check is required by name, and here's what reports that name in five situations.

**[ON SCREEN]** The table of section 20B.13.

The workflow never started, because of a path filter, a branch filter, or `[skip ci]` in the commit message. The check reports nothing. It stays pending. The merge is blocked.

**[ANIMATION]** walk: id=five columns=the_situation,the_check_reports,the_merge rows=the_workflow_never_started:nothing,_it_stays_pending:blocked|the_job_was_skipped_by_its_if:success:allowed|a_job_it_needs_failed,_so_it_was_skipped:skipped,_so_it_may_not_block:allowed,_wrongly|it_ran_on_a_workflow__dispatch_run:not_evaluated_for_the_pull_request:blocked|a_merge_queue,_and_no_merge__group_event:nothing_in_the_queue:blocked_in_the_queue marks=1.3:bad,2.3:ok,3.3:wait,4.3:bad,5.3:bad mono=off title=Who_reports_the_required_name? at_1=3 at_2=15

**[ANIMATION]** step: 2

The workflow started and the job was skipped by its `if`. The check reports success, because skipped counts as passing. The merge is allowed.

Quick quiz, before the third row. A job is skipped because a job it needs failed. Does that block the merge? A, yes, because something failed. B, no, because a skipped job doesn't block. Your answer?

**[PAUSE]**

**[ANIMATION]** step: 3

B. A job was skipped because a job it needs failed. It's skipped, so it may not block. The merge is allowed, and the textbook adds one word: wrongly. If that surprised you, good. It surprises almost everyone, and the design that follows exists because of it.

**[ANIMATION]** step: 4

The check ran on a `workflow_dispatch` run of the head branch. It's not evaluated for the pull request. The merge is blocked.

**[ANIMATION]** step: 5

A merge queue is used and the workflow lacks `on: merge_group`. A merge queue merges pull requests one group at a time, and runs the required checks on each group first. Nothing is reported in the queue. The merge is blocked in the queue.

**[ANIMATION]** say: Three_block_a_merge_with_nothing_wrong._Two_let_one_through_without_a_real_result

Three of those five block a merge that has nothing wrong with it. Two let a merge through without a real result. And a path filter has its own edges, which you heard in video 143: a push with more than 1,000 commits always runs the workflow, and with more than 3,000 changed files a match beyond the first 3,000 isn't seen.

**[ANIMATION]** run: id=agg event=pull_request jobs=unit-tests|lint|all-checks:unit-tests+lint title=The_robust_design:_an_inference_from_these_rules say_jobs=Require_all-checks,_and_nothing_else at_jobs=45

**The robust design.** The textbook is careful about its status: the Phase 0 report labels it an inference from these rules. Don't filter the workflow. Start it always. Decide inside which jobs to run, with `if`. And require one aggregate job that always runs and fails when something it needs failed or was cancelled.

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

Read it against the table. The workflow has no filter, so the name is always reported: that removes row one. The job's own `if` is `!cancelled()`, so it's not skipped when a needed job fails: that removes row three. And its one step fails the job when any needed result is a failure or a cancellation. Require `all-checks` in the ruleset and nothing else. The matrix and the job list can then change without touching the rule. There's the one small job from the opening.

**The instruments. Read the failure first.**

```bash
gh run list --workflow 08-deploy-staging.yml --limit 5
gh run view RUN_ID
gh run view RUN_ID --log-failed
gh run view RUN_ID --json event,headBranch,headSha,conclusion,jobs
gh run watch RUN_ID --exit-status
gh pr checks --watch
```

All 🟢 SAFE: they change nothing. `--log-failed` prints the log of the failed steps only. `gh run watch` follows a run until it ends and, with `--exit-status`, exits non-zero when it fails, so it can be chained in a script. `gh pr checks` exits with status 8 while checks are pending. The flags are from the help output of GitHub CLI 2.88.1.

**[ANIMATION]** graph: id=rerun A-...-B main; HEAD=none; note:A:the_original_run_was_bound_to_this_commit; note:B:main_today; say:A_re-run_is_not_a_new_run => + mark:re-run:A; name:again; say:The_same_GITHUB__SHA_and_GITHUB__REF_as_the_original_event dx=330 at_again=40

**Re-run.** The textbook starts with a correction: a re-run isn't a new run. It uses, in the documentation's words, "the same `GITHUB_SHA` and `GITHUB_REF` of the original event", and the privileges of the actor who triggered the original. It's possible for 30 days, and at most 50 times.

```bash
gh run rerun RUN_ID --failed
gh run rerun RUN_ID --failed --debug
gh run rerun --job JOB_ID
```

`gh run rerun` is 🟡 CAUTION. What it changes: a new attempt of the same run, at the original commit and ref. New checks on that commit. And for a deploy workflow, a new deployment of that commit. That last part is the danger. Re-running last week's deploy run deploys last week's commit over today's. The preview: `gh run view` with the JSON field `headSha`, compared with `main`. The textbook's rule: use a re-run to retry a flaky step of the latest run, and a fresh run for everything else.

**Debug logging.** Two switches, each a repository secret or variable set to `true`. The secret wins if both exist. `ACTIONS_STEP_DEBUG` adds debug lines to step logs. `ACTIONS_RUNNER_DEBUG` adds runner and worker diagnostic logs to the downloaded log archive. For one run, `gh run rerun --debug`, or the checkbox on the re-run dialog, does the same without leaving the switch on. Anyone who may run the workflow may enable it.

**Skipped jobs.** Since the twenty-ninth of January 2026 the log of a skipped job shows the original `if` expression and its expanded values.

**Run and manage workflows.**

```bash
gh workflow list --all
gh workflow view 09-environments.yml --yaml
gh workflow run 09-environments.yml --ref main
gh cache list --key Linux-inventory-api
```

The listing and viewing commands are 🟢 SAFE. `gh workflow run` is 🟡 CAUTION: it starts a run, and on a deploy workflow, a deployment. The preview is to read the file with `gh workflow view --yaml`. It needs `on: workflow_dispatch` in the file on the default branch. And, as in the hook, a run started this way doesn't satisfy a required check of a pull request.

One warning. Dumping the whole `github` context into a log is a documented debugging aid, and that context contains the token. Print the fields you need.

**Linting.** Linting means checking a file for mistakes without running it. Catch what can be caught before the push. `actionlint` checks workflow syntax, expression types and embedded shell. The GitHub Actions language service in the editor does part of that while you type. Neither is installed for this course. The course's own check is only that each file parses as YAML and has `on` and `jobs`, which finds indentation errors and nothing else.

Then the sentence that sets the expectation: all six broken workflows of Lab 28.1 pass that check, and a linter would pass most of them too. A linter proves that a file is well formed. It can't know that the history is shallow or that a secret is withheld.

**[ANIMATION]** cards: id=act question=What_act_does_not_implement,_by_its_own_documentation cards=concurrency|job_permissions|environment|OIDC|timeout-minutes|continue-on-error|step_summaries|a_complete_github_context at_1=30 at_2=34 at_3=38 at_4=42 at_5=46 at_6=50 at_7=54 at_8=58

**A local emulator.** `act` runs workflows locally in Docker containers. Its own documentation lists what it doesn't implement: `concurrency`, job `permissions`, `environment`, OIDC, `timeout-minutes`, `continue-on-error`, step summaries, and a complete `github` context. The textbook's verdict: useful for the shell logic of steps, and useless for exactly the topics of this chapter: gates, tokens, groups, runner images. Treat a green local run as evidence about your scripts, never about your deployment.

## MENTAL MODEL

A picture helps.

**[ANIMATION]** stores: id=roll boxes=the_rule:reads_a_name_from_its_list|the_room:who_answers? rows=1:A:the_required_name|1:A:it_waits_for_an_answer|2:B:the_workflow_never_started:_nobody_answers@bad|3:B:told_by_its_if_to_sit_out:_answers_"present"@ok|4:B:the_aggregate_job:_always_in_the_room@hl title=A_roll_call at_1=40 at_2=25 at_3=65

**[ANIMATION]** step: 1

A required check is a name, and the rule waits for somebody to say that name with a result.

**[ANIMATION]** step: 3

Picture a roll call. The rule reads a name from its list and waits for an answer. If the workflow that owns the name was never started, nobody is in the room to answer, and the rule keeps waiting. It doesn't conclude "absent means fine". If the job was in the room and was told by its `if` to sit this one out, it answers "present", and that counts.

Where the picture breaks: at a roll call, anyone can see the empty chair. In a merge box, a check that will never report and a check that will report in two minutes look alike. You tell them apart by asking whether a run exists at all, which is step 1 of the investigation order.

**[ANIMATION]** step: 4

The aggregate job is the one person who is always in the room and answers for everyone else, truthfully.

**[ANIMATION]** walk: id=instr columns=instrument,step_of_the_order rows=gh_run_view_with_JSON_fields:1_and_2|--log-failed:9|gh_run_download:10|gh_cache_list:11|gh_run_list_for_the_workflow:12 title=Each_instrument_belongs_to_a_step at_1=18 at_2=38 at_3=50 at_4=60 at_5=70

And a model for the instruments: each one is tied to a step of the order. `gh run view` with JSON fields is steps 1 and 2. `--log-failed` is step 9. `gh run download` is step 10. `gh cache list` is step 11. `gh run list` for the workflow is step 12. If you reach for an instrument, know which step you're on.

## DIAGRAM

**[ANIMATION]** stores: id=who boxes=pull_request:changed_paths|*ruleset_on_main:requires_check_"X"|workflows:who_says_the_name? rows=1:A:docs/runbook.md|1:B:waits_for_the_NAME_"X"|2:C:(a)_no_filter,_on_pull__request|2:C:(b)_paths_"src/**",_on_pull__request|3:C:(a)_a_run_exists:_X_reports_success_or_failure@ok|3:C:(b)_no_path_matches:_NO_RUN@bad|3:B:from_(b):_"expected",_forever@bad|4:C:the_design:_no_filter,_and_all-checks_with_!cancelled()_needs_both@hl|4:B:then_require_"all-checks"_only@hl title=Who_says_the_name_X? at_1=10 at_2=45 at_3=5 at_4=70

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

**[ANIMATION]** step: 2

Try it now, on paper. Thirty seconds. Draw a ruleset that requires the name X, and two workflows that could say it: one without a filter, and one with a path filter for `src`. A pull request changes only `docs/runbook.md`. Under each workflow, write what the rule hears.

**[PAUSE]**

**[ANIMATION]** step: 4

From the first: success or failure, so the rule gets its answer. From the second: nothing. No run exists, and the rule waits.

**[DIAGRAM]** In case (b) there is nothing wrong with the pull request and nothing wrong with the workflow. The fault is in the combination: a filterable workflow owns a required name.

## LIVE TERMINAL DEMO

Into the lab.

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

`git clone` is 🟢 SAFE. This case is the one from the last video. Say the cause out loud before the output appears.

**[PAUSE]**

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

One commit, no tags, and "No names found" with status 128 in the clone that is like the job's. In your own repository, the proper description.

**Workflow 2: "a pull request that changes only docs cannot be merged; the merge box waits for the required check unit-tests; no run exists."**

```bash
git diff --name-only main...docs/rollback-steps
git diff --name-only main...feature/safety-stock
```

The workflow has a path filter for `src`. For which of the two branches would it start? Make your prediction.

**[PAUSE]**

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

The documentation branch changed one file under `docs`. The feature branch changed a file under `src` and the lock file.

**[ANIMATION]** walk: id=diff columns=branch,changed_paths,a_filter_for_src,the_required_check rows=docs/rollback-steps:docs/runbook.md:no_match,_no_run:unit-tests_never_reports|feature/safety-stock:src/warehouse/rules.py,_uv.lock:a_match,_a_run_starts:unit-tests_reports marks=1.3:bad,1.4:bad,2.3:ok,2.4:ok mono=off title=A_path_filter_on_the_three-dot_diff pace=quick

The workflow starts for the second and not for the first. Its job is a required check. This is the hook, proven with a three-dot diff.

**[ANIMATION]** end

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

Three refs receive pushes. You saw this snippet in video 150. A concurrency group must tell them apart, and the report says it happens when a colleague pushes to a different branch at about the same time. Open the file and read its group name.

**Workflow 6: "a pull request added a dependency and updated the lock file; the tests fail in the job because the new package cannot be imported; the install step shows as skipped."**

```bash
git rev-parse main:uv.lock feature/safety-stock:uv.lock
git diff --stat main feature/safety-stock -- uv.lock
```

`git rev-parse` with a ref, a colon and a path prints the ID of the blob at that path, and a blob is the stored content of one file.

If the two IDs differ, what must be true of a correct cache key on the two refs? Say it out loud.

**[PAUSE]**

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

Part B of Lab 28.1, on your practice repository, in your normal shell. The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors. These six reports are constructed descriptions written from the documented behavior. They aren't captured logs.

Add one broken file at a time. For each: observe, fix it yourself, observe again, remove it. The lab asks for at least workflows 1, 3 and 5.

For workflow 1, after the push, list the runs and print the failed step's log with the instrument for step 9. For workflow 3, open the failed step and find the status code. Then read the `permissions` of the file. For workflow 5, push to two branches in quick succession and look at the run list for the conclusion of each run. Each time, before you fix anything, say which step of the order gave you the cause.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Requiring a check that a filterable workflow owns.** Root cause: a workflow that never started reports nothing, and the required check stays pending.
2. **Trying to satisfy a pull request's required check with `gh workflow run`.** Root cause: a check from a `workflow_dispatch` run of the head branch is not evaluated for the pull request.
3. **An aggregate job without `!cancelled()`.** Root cause: a job that needs a failed job is skipped, and a skipped job counts as passing.
4. **Re-running an old deploy run.** Root cause: a re-run uses the same commit and ref as the original event, so it deploys old code over new.
5. **Treating a green local emulator run as proof.** Root cause: the emulator does not implement concurrency, job permissions, environments or OIDC, and has no complete `github` context.

## PRODUCTION EXAMPLE

Now, out of the lab. A platform team with a busy repository adopts a merge queue to stop pull requests from going out of date. On the first morning the queue fills and nothing leaves it. Every entry waits for the required check.

**[ANIMATION]** step: five.5

**[ANIMATION]** say: Row_five:_nothing_is_reported_in_the_queue

Go to the table. Row five: a merge queue is used and the workflow lacks `on: merge_group`. Nothing is reported in the queue. The workflow listens for `pull_request` and for `push`, and neither of those is the event of a merge group.

**[ANIMATION]** say: For_every_way_a_merge_can_be_attempted:_will_anything_say_the_required_name?

The fix is one more event in the trigger of the workflow that owns the required name. The lesson is the same as for the path filter: for every way a merge can be attempted, ask whether anything will say the required name. With one aggregate job as the only required check, that question has to be answered for exactly one workflow.

## PRACTICE EXERCISE

Your turn. Do Lab 28.1, "Six broken workflows", in [`lab-manual/m28-runners-debugging-ci.md`](../../lab-manual/m28-runners-debugging-ci.md).

For each of the six, before any evidence: the hypothesis, the suspected line, and the layer. After the evidence: the root cause from the documentation, the smallest correct fix, and what would have prevented it. Each of the six has a different documented root cause. If two of your answers are the same, one is wrong.

The challenge is Exercise 28.7, "Every pull request is waiting", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q300: "A pull request shows "waiting for status to be reported" and no run exists. Name three causes and the design that avoids all of them."

**[PAUSE]**

Answer out loud. A strong answer starts from what "required" means: a name, and something that must report it. It gives three distinct causes for nothing reporting, each with the documented mechanism, and then one design, with the reason each part of the design is there. It says how you would confirm which cause applies before changing anything. The follow-up asks how you predict, before pushing, whether a path-filtered workflow will start, and where that prediction breaks down. You know the command, and you've heard the two edges of the filter.

## RECAP

Let's land this.

You should now be able to say:

- A check is required by name; a workflow that was filtered out never reports that name, and a manually started run does not count for the pull request.
- A job skipped by its `if` counts as passing, and so does a job skipped because a needed job failed.
- The design that avoids all of it: no filter on the workflow, decisions inside jobs, and one aggregate job with `!cancelled()` as the only required check.
- A re-run is a new attempt at the original commit and ref; on a deploy workflow it is a rollback nobody announced.
- A linter proves a file is well formed; a local emulator is evidence about your scripts and never about gates, tokens, groups or runner images.

## HOMEWORK

Read sections 20B.13 to 20B.18 of [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md) and do the Practice section 20B.20. Do Exercise 28.3, "A required check that cannot be red", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md). Read [`guides/github-actions-guide.md`](../../guides/github-actions-guide.md) and [`cheatsheets/github-actions-cheat-sheet.md`](../../cheatsheets/github-actions-cheat-sheet.md).

That was the last teaching video of Part 6. A stuck merge box is no longer a mystery to you: you ask whether a run exists, and who would say the required name. Do Lab 28.1 with a written hypothesis for each file. Next time: the gate briefing for Actions. Until then, look at the state first and type second. See you in the next one.
