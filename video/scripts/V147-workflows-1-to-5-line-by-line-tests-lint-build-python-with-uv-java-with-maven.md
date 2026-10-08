# V147: Workflows 1 to 5, line by line: tests, lint, build, Python with uv, Java with Maven

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 26
- **Planned minutes.** 28
- **Prerequisites.** V146
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), section 20A.13 (workflows 1 to 5), with sections 20A.16 and 20A.17
- **Demo scripts.** `labs/ch20a/lab-26-1-first-workflow.sh`, `labs/ch20a/lab-26-2-lint-branch.sh`; the files [`01-tests.yml`](../../workflows/01-tests.yml), [`02-lint.yml`](../../workflows/02-lint.yml), [`03-build.yml`](../../workflows/03-build.yml), [`04-python-tests.yml`](../../workflows/04-python-tests.yml), [`05-java-tests.yml`](../../workflows/05-java-tests.yml); screen walkthroughs of Labs 26.1, 26.4 and 26.5 in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md)

## HOOK

**[ON SCREEN]** One sentence: "The pipeline is green, so the tests passed and the change is safe to merge."

An executive says that, and it sounds reasonable. The pipeline is the automated run that checks each change, and green means it reported success.

**[ANIMATION]** cards: id=green question=Green,_and_still_false:_every_word_of_the_log_is_true cards=The_job_was_skipped_by_its_if:a_skipped_job_reports_success|The_failing_command_was_on_the_left_side_of_a_pipe|The_tests_ran_on_a_commit_that_is_no_longer_what_will_be_merged|The_run_tested_the_workflow_file_from_the_branch:which_the_author_had_edited numbered=on at_1=30 at_2=50 at_3=65 at_4=82

**[ANIMATION]** step: 4

After the last five videos you can already name several ways in which the sentence is false while every word of the log is true. The job was skipped by its `if`, and a skipped job reports success. The failing command was on the left side of a pipe. The tests ran on a commit that is no longer what will be merged. The run tested the workflow file from the branch, which the author had edited.

None of these is exotic. Each is a default. So the way to trust a green result is to be able to defend every line of the file that produced it. In this video you read five files that way. And keep one question open: of all the lines in such a file, how many are the test itself?

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A workflow is a file in the repository that says: when this event happens, run these jobs. A job is a list of steps on one fresh machine, the runner. This video is different in form from the last five. There's no new concept. There are five workflow files, and you read each of them in the fixed order: trigger, permissions, job and runner, checkout, commands.

The files are in the `workflows` directory of the course. Each carries a header comment, declares `permissions` at the top, and pins every action to a full commit ID, with the version as a comment. An action is a packaged, reusable step, and the permissions say what the job's token may do. The IDs are listed in [`workflows/ACTION_PINS.md`](../../workflows/ACTION_PINS.md). When I name a version in this video, I'm reading it from the file on screen, not from memory, and so should you.

And once more what was verified. These files were parse-checked and assembled from documented syntax. The author didn't execute them on GitHub. For workflow 5 there is an additional statement: the Maven module and the plugin versions in its `pom.xml` weren't built by the author. The versions were confirmed to exist in Maven Central on the second of October 2026. So if one of these files fails on your practice repository for a reason nobody could test, you have a real diagnosis exercise, and the method for it is the subject of the next module.

**[ANIMATION]** gates: id=moves gates=add:done:-:the_workflow_file|predict:done:-:when_it_runs_and_what_is_checked_out|run:done:-:it|read:done:-:the_log|break:done:-:it_on_purpose,_and_diagnose title=The_five_movements_of_every_lab at_1=22 at_2=30 at_3=45 at_4=50 at_5=56

The labs of Module 26 all have the same five movements, and the lab manual names them: add the workflow file, predict when it runs and what is checked out, run it, read the log, then break it on purpose and diagnose. The manual adds a sentence I'll repeat: a prediction you didn't write isn't a prediction.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- explain every line of the first five workflows;
- say for each which event starts it, what is checked out and which permissions the token has;
- predict the outcome of each before running it and compare with the run;
- break each on purpose and diagnose from the log;
- state what the authors did and did not verify about these files.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions. The five files, one at a time, full screen.

**[ANIMATION]** walk: id=w1 columns=in_this_order,01-tests.yml rows=trigger:pushes_to_main,_and_pull_requests|permissions:contents:_read|job_and_runner:ubuntu-24.04,_a_ten-minute_limit|checkout:one_commit,_no_tags,_persist-credentials:_false|commands:print_what_was_checked_out,_Python_3.13,_the_tests mono=off title=Workflow_1:_run_the_tests at_1=30 at_2=75 at_3=3 at_4=50 at_5=10

**[ANIMATION]** step: 2

**Workflow 1: run the tests.** You read this file in video 142, so only the summary. Trigger: pushes to `main`, and pull requests, GitHub's proposals to merge one branch into another. The branch filter on `push` stops a second run for every push to a pull request branch. Permissions: `contents: read`, and every other permission is none.

**[ANIMATION]** step: 4

One job on `ubuntu-24.04` with a ten-minute limit. A fixed label doesn't move when `ubuntu-latest` migrates. Checkout with the defaults you know from video 145, one commit and no tags, and `persist-credentials: false`.

**[ANIMATION]** step: 5

A step that prints what was checked out. Python 3.13, quoted. The tests, with `PYTHONPATH` set for that step only, because `env` at step level is the narrowest scope.

**[ANIMATION]** end

Quick quiz. On a pull request, which ref does that printing step show? A, `refs/heads/main`. B, the name of the pull request's branch. C, `refs/pull/N/merge`. Your answer?

**[PAUSE]**

C, the test merge that GitHub computes for the pull request. The textbook's prediction for the printing step, from the documentation: on a push to `main` it prints `refs/heads/main`, the pushed commit, `true` for shallow, and a status line that names a branch. On a pull request it prints `refs/pull/N/merge`, the test merge commit, `true`, and "HEAD (no branch)". Lab 26.1 has you confirm it.

**Workflow 2: linting.** Linting is an automated check for mistakes and style, such as an unused import. Same trigger, same permissions. The differences are in the steps.

**[ON SCREEN]** `02-lint.yml`, the steps.

`astral-sh/setup-uv` installs uv, the tool these workflows use to provide Python and install packages. Its `python-version` input sets a variable for the rest of the job, and uv then provides that interpreter when a command needs it.

**[ANIMATION]** walk: id=w2 columns=step,what_it_does rows=Install_uv:provides_Python_and_installs_packages|uv_sync_--locked:CI_installs_what_was_reviewed,_or_stops|Lint:uv_run_ruff_check|Check_formatting:uv_run_ruff_format_--check,_with_if_!cancelled()|Write_the_job_summary:the_two_step_outcomes_as_a_Markdown_table mono=off title=Workflow_2:_linting at_1=2 at_2=12 at_3=5 at_4=30

**[ANIMATION]** step: 2

`uv sync --locked` creates the virtual environment from `uv.lock`, the lock file that pins each dependency to an exact version. It fails if the lock file doesn't match `pyproject.toml`. The textbook's summary of that line: CI installs what was reviewed, or stops.

**[ANIMATION]** step: 4

Then two checks with IDs: `uv run ruff check`, and `uv run ruff format --check`. The second has `if: !cancelled()` in the expression wrapper. That replaces the implicit `success()`, so formatting is checked even when linting failed. One push reports both problems. And the job still fails, because a failed step fails the job unless `continue-on-error` is set.

**[ANIMATION]** step: 5

The last step reads the two step outcomes through `env` and appends a Markdown table to the step summary. The braces group the `echo` commands so that one redirection covers all of them.

**[ANIMATION]** end

**Workflow 3: build.** You read this in video 144. Trigger: pushes to `main`, pushes of tags that match `v*`, and manual runs. The pattern is quoted, because a star is YAML syntax at the start of a scalar. `branches` and `tags` under one `push` are alternatives: a push matches if it's a matching branch or a matching tag. There is no `pull_request` trigger, so a pull request that adds this file starts no run of it.

**[ANIMATION]** stores: id=w3 boxes=job_build:its_own_runner|job_report:needs_build,_no_checkout rows=1:A:checkout_with_fetch-depth:_0|1:A:git_describe_--tags_--always|2:A:the_step_appends_to_GITHUB__OUTPUT|2:A:the_job_publishes_two_outputs|3:B:reads_the_outputs_through_env|3:B:two_strings_arrived,_nothing_else@hl arrows=3:A4>B1:two_strings title=Workflow_3:_build at_1=12 at_2=42 at_3=62

`defaults.run.shell: bash`, so pipelines fail properly. `fetch-depth: 0`, because the next step runs `git describe --tags --always` and needs history and tags. That step has the ID `describe` and appends to `GITHUB_OUTPUT`. The job publishes two outputs. The second job, `report`, has `needs: build`, no checkout, and reads the outputs through `env`. The textbook's sentence: the only things that reached the second machine are two strings.

**[ANIMATION]** end

**Workflow 4: Python tests with uv and caching.**

**[ON SCREEN]** `04-python-tests.yml`.

Same trigger and permissions as workflows 1 and 2. Then a block you haven't read yet: `concurrency`.

**[ANIMATION]** run: id=w4 event=pull_request ref=refs/pull/N/merge jobs=pytest concurrency=github.workflow-github.ref cache=pytest:uv.lock steps=event,jobs,cancel,data title=Workflow_4:_Python_tests_with_uv_and_caching at_jobs=10 at_cancel=40

**[ANIMATION]** step: cancel

The group is built from the workflow name and `github.ref`, with `cancel-in-progress: true`. One run at a time per workflow and ref. A new push to the same branch or pull request cancels the run in progress. For pull requests `github.ref` is `refs/pull/N/merge`, so each pull request is its own group. Concurrency has its own video, video 150.

**[ANIMATION]** step: data

The setup step has an ID and two new inputs. `enable-cache: true` turns on the cache built into the action. `cache-dependency-glob: uv.lock` makes the lock file the only input to the key. So a changed lock file gives a new key and a miss, and any other change gives a hit. You computed exactly that in the last video.

**[ANIMATION]** say: The_log_states_cache-hit._Then_uv_sync_--locked,_then_uv_run_pytest

The next step prints the action's `cache-hit` output, mapped through `env`, so the log states which case occurred. Then `uv sync --locked`, then `uv run pytest`, which collects the `unittest` classes of the sample project.

**[ANIMATION]** end

**Workflow 5: Java tests with Maven.**

**[ON SCREEN]** `05-java-tests.yml`.

This is the file with a path filter.

**[ANIMATION]** walk: id=w5 columns=a_pull_request_that_changes,the_path_filter,a_run,a_check rows=java-service:matches:starts:is_reported|05-java-tests.yml:matches:starts:is_reported|only_other_files:no_match:none:none marks=3.2:wait,3.3:wait,3.4:bad mono=off title=Workflow_5:_a_path_filter at_1=40 at_2=60

**[ANIMATION]** step: 2

Under both `push` and `pull_request`, two paths: everything under `java-service`, and the workflow file itself. Listing the workflow file means that an edit to the CI is tested by the CI.

**[ANIMATION]** step: 3

And here's the sentence from the textbook that connects to the hook of video 143: don't make this workflow a required check, a check that a rule says must pass before merging. A workflow that the filter skips creates no check.

**[ANIMATION]** end

The job sets `defaults.run.working-directory` to `java-service`. The comment in the file states the limit: it applies to `run` steps only. `uses` steps still resolve paths from the workspace root, which is why the upload path further down is written in full.

`actions/setup-java` installs Temurin 21, and the `distribution` input is required. `cache: maven` restores the local Maven repository from a cache keyed on the given `pom.xml`.

`mvn -B verify` runs Maven, the build tool of the Java module. `-B` is Maven's batch mode, with no interactive prompts and no color codes in the log.

The last step uploads the test reports with `if: failure()`, so only when an earlier step failed, and keeps them for seven days.

**What can go wrong across all five.** Section 20A.16 is a table of nine symptoms, and you can now explain each one from a mechanism: the merge ref, the shallow clone, the filter that creates no run, the missing `pipefail`, the empty output, the `if` that is a string, the stale cache, the unquoted version, and the secret that doesn't reach a fork.

## MENTAL MODEL

A picture helps.

Every workflow file has four kinds of lines, and only one of them is the check.

**[ANIMATION]** layers: id=kinds layers=the_trigger:does_a_run_exist,_and_for_which_commit?|the_permissions:what_may_the_job's_token_do?|the_environment_setup:the_checkout+the_language_toolchain+the_cache|the_commands:the_check_itself result=uv_sync_--locked+uv_run_pytest rule=workflow_4:_the_check title=Four_kinds_of_lines

**[ANIMATION]** step: 1

The trigger decides whether a run exists and which commit it's about.

**[ANIMATION]** step: 2

The permissions decide what the job's token may do.

**[ANIMATION]** step: 3

The environment setup decides what is on the machine: the checkout, the language toolchain, the cache.

**[ANIMATION]** step: 4

And the commands are the check itself: `python -m unittest`, `uv run ruff check`, `uv build`, `uv run pytest`, `mvn -B verify`.

Try it now. Thirty seconds. Open `04-python-tests.yml` in the `workflows` directory, or wait for the diagram, and count the lines in each of the four categories. How many lines are the check?

**[PAUSE]**

**[ANIMATION]** step: result

Two. The check is two lines. Everything else exists to make those two lines mean something: the right commit, the dependencies that were reviewed, a token that can't do harm, a run that stops when a newer push makes it pointless.

That proportion is the answer to the executive in the hook, and to the question you kept open. "Green" is a statement about the two lines. Whether it's evidence about the change depends on all the others.

**[ANIMATION]** end

One rule from section 20A.17 follows from this picture: don't put the only copy of a procedure in a workflow. A build that exists only as YAML steps can't be run on a laptop or on another CI system. Keep the commands in the repository and let the workflow call them. Look at the five files again with that rule in mind: each check is a command you can type locally. The lab has you do so before you push.

## DIAGRAM

**[DIAGRAM]** Workflow 4 with four brackets. Draw the file first, plain. Then add one bracket at a time and name it. In the recording the brackets have four neutral colors; none of them is green, amber or red, which are reserved for the risk labels.

```text
  name: Python tests
  on:                                              --+
    push:                                            |  TRIGGER
      branches: [main]                               |  does a run exist, and for which commit?
    pull_request:                                  --+
  permissions:                                     --+  PERMISSIONS
    contents: read                                 --+  what may the job token do?
  concurrency: ...                                 --+
  jobs:                                              |
    pytest:                                          |
      runs-on: ubuntu-24.04                          |  ENVIRONMENT SETUP
      timeout-minutes: 10                            |  what is on the machine?
      steps:                                         |
        - uses: actions/checkout@<commit ID>         |
        - uses: astral-sh/setup-uv@<commit ID>       |
        - run: echo "uv cache hit - $CACHE_HIT"    --+
        - run: uv sync --locked                    --+  THE CHECK
        - run: uv run pytest                       --+  the commands you could run on a laptop
```

Read it from the top bracket down: trigger, permissions, environment setup, and at the bottom, two lines.

**[DIAGRAM]** The bottom bracket is two lines. Read a workflow from the top bracket down, and judge a green result by all four.

## LIVE TERMINAL DEMO

Into the lab.

**[TERMINAL]** Replay with `labs/run ch20a/lab-26-1-first-workflow`. This is the Git side of Lab 26.1: what you commit before anything reaches GitHub.

**Step 1: add.**

```bash
cp -R "$COURSE/sample-project" inventory-api
cd inventory-api
git init --quiet
PYTHONPATH=src python3 -m unittest discover -s tests
mkdir -p .github/workflows
cp "$COURSE/workflows/01-tests.yml" .github/workflows/
git add .
git commit --quiet -m "Add inventory-api and the tests workflow"
git ls-files
```

`git commit` is 🟢 SAFE: it adds objects and moves the current branch forward. Notice the order: the tests run locally first, with the same command the workflow uses.

How many files under `.github` will `git ls-files` list, and what does that tell you about where a workflow lives? Say it out loud.

**[PAUSE]**

<!-- snippet: ch20a/lab-26-1-first-workflow/01-create -->
```text
# COURSE is the course folder.
$ cp -R "$COURSE/sample-project" inventory-api
$ cd inventory-api
$ git init --quiet
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null
[exit status: 0]
$ mkdir -p .github/workflows
$ cp "$COURSE/workflows/01-tests.yml" .github/workflows/
$ git add .
$ git commit --quiet -m "Add inventory-api and the tests workflow"
$ git ls-files
.github/workflows/01-tests.yml
.gitignore
Dockerfile
README.md
java-service/pom.xml
java-service/src/main/java/com/example/inventory/PriceCalculator.java
java-service/src/test/java/com/example/inventory/PriceCalculatorTest.java
pyproject.toml
scripts/deploy.sh
src/inventory_api/__init__.py
src/inventory_api/stock.py
tests/test_stock.py
$ git status --short --branch
## main
```
<!-- /snippet -->

One: `.github/workflows/01-tests.yml`, a tracked file among the others. A workflow lives in the repository like any other file. The project also contains a Dockerfile, a Java module, a `pyproject.toml` and a deployment script. Workflows 3 to 7 use them.

Here the lab's second movement would follow. Before the push that creates the repository on GitHub, you write down: the event, the workflow that starts, `GITHUB_REF`, `GITHUB_SHA`, and how many commits the runner will have. Don't skip it.

**Step 2: break.**

```bash
git switch -c break/wrong-total
git diff --stat
PYTHONPATH=src python3 -m unittest discover -s tests
git commit --quiet -am "Break a test on purpose"
```

`git switch -c` is 🟢 SAFE: it adds a ref. The failure scenario changes one expected value in a test, on a branch.

<!-- snippet: ch20a/lab-26-1-first-workflow/02-break -->
```text
# Failure scenario: a wrong expectation, on a branch.
$ git switch -c break/wrong-total
Switched to a new branch 'break/wrong-total'
$ sed -i.bak 's/{"bolt": 5, "nut": 7}), 12)/{"bolt": 5, "nut": 7}), 13)/' tests/test_stock.py && rm tests/test_stock.py.bak
$ git diff --stat
 tests/test_stock.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null
[exit status: 1]
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1
FAILED (failures=1)
$ git commit --quiet -am "Break a test on purpose"
```
<!-- /snippet -->

Locally: exit status 1, one failure. On GitHub, pushed as a pull request, the same command is the last step of the job.

Which step of workflow 1 will be red, and what will the printing step have shown for the ref? Say it out loud.

**[PAUSE]**

**[ANIMATION]** gates: id=fail packet=the_breaking_pull_request gates=Check_out_the_repository:pass|Show_what_was_checked_out:pass:-:refs/pull/N/merge|Set_up_Python:pass|Run_the_tests:stop:-:exit_status_1 result=predicted,_not_executed title=Workflow_1_on_the_breaking_pull_request:_the_prediction

The last step is the red one, because the same command exits with status 1. And by the documentation, the step that shows what was checked out prints `refs/pull/N/merge` for the ref. Lab 26.1 has you confirm both.

**Step 3: recover.**

```bash
git revert --no-edit HEAD
git log --format=%s -3
git diff --stat main
```

`git revert` is 🟡: it adds one commit. The branch moves, the index and files are updated, and nothing is removed.

<!-- snippet: ch20a/lab-26-1-first-workflow/03-recover -->
```text
# Recovery: a new commit that undoes the bad one. The branch history stays honest.
$ git revert --no-edit HEAD > /dev/null
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null
[exit status: 0]
$ git log --format=%s -3
Revert "Break a test on purpose"
Break a test on purpose
Add inventory-api and the tests workflow
# No output from the next command: the branch content equals main again.
$ git diff --stat main
```
<!-- /snippet -->

A new commit that undoes the bad one. Three subjects in the log, and the last command prints nothing: the branch content equals `main` again.

**[ANIMATION]** graph: id=rev ?the_first_commit main; HEAD=main; say:main:_the_tests_pass => + ?the_first_commit-?Break_a_test_on_purpose break/wrong-total; HEAD=break/wrong-total; fail:?Break_a_test_on_purpose; name:break; say:On_the_branch:_FAILED_(failures=1) => + ?Break_a_test_on_purpose-?the_revert break/wrong-total; pass:?the_revert; name:revert; cmd:git_revert_--no-edit_HEAD; say:A_new_commit_undoes_the_bad_one:_the_content_equals_main_again dx=330 at_state_1=5 at_break=30 at_revert=60

**[ANIMATION]** step: revert

As a picture: the break, then the revert on top of it. The branch history stays honest about what happened.

**[ANIMATION]** end

**Step 4: the Git side of Lab 26.2.** Replay `labs/run ch20a/lab-26-2-lint-branch`.

<!-- snippet: ch20a/lab-26-2-lint-branch/01-branch -->
```text
$ git switch -c break/unused-import
Switched to a new branch 'break/unused-import'
$ sed -i.bak 's/^LOW_STOCK_THRESHOLD/import os\
\
LOW_STOCK_THRESHOLD/' src/inventory_api/stock.py && rm src/inventory_api/stock.py.bak
$ git diff
diff --git a/src/inventory_api/stock.py b/src/inventory_api/stock.py
index 47b3010..2ab34b0 100644
--- a/src/inventory_api/stock.py
+++ b/src/inventory_api/stock.py
@@ -1,5 +1,7 @@
 """Stock arithmetic."""
 
+import os
+
 LOW_STOCK_THRESHOLD = 5
 
 
$ git commit --quiet -am "Add an unused import on purpose"
$ git push --quiet -u origin break/unused-import
# What the pull request would list and show:
$ git log --oneline origin/main..HEAD
41794f1 Add an unused import on purpose
$ git diff --stat origin/main...HEAD
 src/inventory_api/stock.py | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

A branch that adds an unused import on purpose, committed and pushed. `git push` is 🟡 CAUTION. The last two commands show what a pull request would list and show: one commit, `41794f1`, and two added lines in one file. Predict from workflow 2: which step fails on this, `ruff check` or `ruff format --check`? And does the other one still run? Say it out loud.

**[PAUSE]**

The other one still runs: you know that from the `if`. And the lab manual records a local run with ruff 0.15.21: `ruff check` reported the unused import with exit status 1, and the format check passed. So on GitHub, expect the step "Lint" to fail, and "Check formatting" to run and pass. Lab 26.2 is where you confirm it.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthroughs.

**On your practice repository, in your normal shell.** The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

Lab 26.1. After the push, open the run of the "Tests" workflow, open the job "Unit tests", and expand the step "Show what was checked out". Compare its six lines with what you wrote. Then push the breaking branch as a pull request and read the same step again: the ref and the commit are different in kind. That comparison is the lab.

Lab 26.4. Add workflow 4 through a pull request. In the job log, find the step that reports the cache result, on the first run and on the second. Then change the lock file as the lab describes and find it a third time. In the run list, look for a run that was cancelled when you pushed again quickly, and connect it to the `concurrency` block.

Lab 26.5. Add workflow 5. First open a pull request that changes only documentation and look at its list of checks: is the Java check there at all? Then one that touches the Java module. This is where you may meet a failure the authors couldn't test, since the Maven module wasn't built by them. If so, read the log from the checked-out commit downward, and treat it as practice for the next module.

For manual runs in these labs, section 20A.18 labels `gh workflow run` as 🟡 CAUTION: it starts a run, which uses minutes and may deploy if the workflow deploys. The preview is to read the workflow file at that ref.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Making the path-filtered workflow a required check.** Root cause: a workflow that a filter skips never creates its check, so the pull request waits for a result that will not come.
2. **Installing without `--locked` in CI.** Root cause: without the lock file as the authority, a stale cache or a new upstream release can change what is installed between the review and the run.
3. **Adding `fetch-depth: 0` to every job.** Root cause: on a repository with a long history it turns a one-second fetch into a full clone for every job; only the job that asks history a question needs it.
4. **Using `continue-on-error` or `if: always()` without a comment and without testing results.** Root cause: both hide failures by design.
5. **Expecting `defaults.run.working-directory` to apply to an action's paths.** Root cause: it applies to `run` steps only; `uses` steps resolve paths from the workspace root.

## PRODUCTION EXAMPLE

Now, out of the lab. A backend team with a Python service and a small Java module adopts these five files. Two weeks later a pull request that changes only a README can't be merged. The Java workflow had been added to the required checks "for consistency".

**[ANIMATION]** step: w5.3

**[ANIMATION]** say: One_Markdown_file:_no_run_exists,_no_check_is_reported,_the_ruleset_waits

The diagnosis is the one you can now do in your head. Trigger of workflow 5: a path filter. Changed paths of the pull request: one Markdown file. No run exists, so no check is reported, and the ruleset waits.

**[ANIMATION]** end

Section 20A.16 gives the fix and the prevention. The fix: remove the filter from required workflows, or require a job that always runs. The prevention: require one aggregate job, and filter inside jobs, not on the workflow.

And the last line of section 20A.17 is the governance point for the whole set: a workflow file is code that runs with a token. Anyone who can push a branch can change what `push` and `pull_request` workflows do on that branch. Protect `.github/workflows/` with CODEOWNERS, the file that assigns reviewers to paths, and a ruleset, a named list of rules, as you learned in video 136.

## PRACTICE EXERCISE

Your turn. Do Lab 26.5, "Workflow 5, Java tests with Maven", in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md), in your normal shell.

Before each push, predict with a three-dot diff whether the workflow will start, as you did in video 143. Write the prediction down, then look at the list of checks.

The challenge is Exercise 26.3, "Six things the author did not mean", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q302: "An executive says: "The pipeline is green, so the tests passed and the change is safe to merge." Explain in plain terms the distinct ways a green result on GitHub Actions can be false evidence, and the organization-wide controls you would set."

**[PAUSE]**

Answer out loud. A strong answer is in plain language, because the listener is an executive, and still names distinct mechanisms, not one mechanism five times. Group them by the four brackets. Did a run exist for this commit? Was it the commit that will be merged? Did the step's status reflect the command? Was the workflow file itself the reviewed one? Then give controls at organization level, each matched to a mechanism. The follow-up asks which of those controls one engineer with push access to a branch can undo for their own pull request without touching any setting. Think about which file is read from the branch.

## RECAP

Let's land this.

You should now be able to say:

- Each of the five files answers four questions in order: when it runs, with what token, on what machine and commit, and which command is the check.
- CI installs from the lock file with `--locked`, so what runs is what was reviewed.
- A cache keyed on the lock file hits on every change except a dependency change.
- A path-filtered workflow must not be a required check; require one job that always runs.
- These files were parse-checked and assembled from documentation, not run on GitHub by the author; the Maven module was not built by the author either.

## HOMEWORK

Read the first five workflows of section 20A.13 in [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md). Do Lab 26.2, "Workflow 2, linting", to Lab 26.4, "Workflow 4, Python tests with uv and caching", in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md) if not done. Do Exercise 26.7, "Read a run from the terminal", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

Five files, and you can now defend every line of each. Do the labs with a written prediction every time. Next time: workflows 6, 7 and 10, action versions and the Node 24 runtime, and the syntax added in 2025 and 2026. Until then, look at the state first and type second. See you in the next one.
