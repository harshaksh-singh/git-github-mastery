# V147: Workflows 1 to 5, line by line: tests, lint, build, Python with uv, Java with Maven

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 26
- **Planned minutes.** 28
- **Prerequisites.** V146
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), section 20A.13 (workflows 1 to 5), with sections 20A.16 and 20A.17
- **Demo scripts.** `labs/ch20a/lab-26-1-first-workflow.sh`, `labs/ch20a/lab-26-2-lint-branch.sh`; the files [`01-tests.yml`](../../workflows/01-tests.yml), [`02-lint.yml`](../../workflows/02-lint.yml), [`03-build.yml`](../../workflows/03-build.yml), [`04-python-tests.yml`](../../workflows/04-python-tests.yml), [`05-java-tests.yml`](../../workflows/05-java-tests.yml); screen walkthroughs of Labs 26.1, 26.4 and 26.5 in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md)

## HOOK

**[ON SCREEN]** One sentence: "The pipeline is green, so the tests passed and the change is safe to merge."

An executive says that, and it sounds reasonable. After the last five videos you can already name several ways in which it is false while every word of the log is true. The job was skipped by its `if`, and a skipped job reports success. The failing command was on the left side of a pipe. The tests ran on a commit that is no longer what will be merged. The run tested the workflow file from the branch, which the author had edited.

None of these is exotic. Each is a default. So the way to trust a green result is to be able to defend every line of the file that produced it. In this video you read five files that way.

## INTRODUCTION

This video is different in form from the last five. There is no new concept. There are five workflow files, and you read each of them in the fixed order: trigger, permissions, job and runner, checkout, commands.

The files are in the `workflows` directory of the course. Each carries a header comment, declares `permissions` at the top, and pins every action to a full commit ID, with the version as a comment. The IDs are listed in [`workflows/ACTION_PINS.md`](../../workflows/ACTION_PINS.md). When I name a version in this video, I am reading it from the file on screen, not from memory, and so should you.

And once more what was verified. These files were parse-checked and assembled from documented syntax. The author did not execute them on GitHub. For workflow 5 there is an additional statement: the Maven module and the plugin versions in its `pom.xml` were not built by the author; the versions were confirmed to exist in Maven Central on 2 October 2026. So if one of these files fails on your practice repository for a reason nobody could test, you have a real diagnosis exercise, and the method for it is the subject of the next module.

The labs of Module 26 all have the same five movements, and the lab manual names them: add the workflow file, predict when it runs and what is checked out, run it, read the log, then break it on purpose and diagnose. The manual adds a sentence I will repeat: a prediction you did not write is not a prediction.

## LEARNING OBJECTIVES

After this video you can:

- explain every line of the first five workflows;
- say for each which event starts it, what is checked out and which permissions the token has;
- predict the outcome of each before running it and compare with the run;
- break each on purpose and diagnose from the log;
- state what the authors did and did not verify about these files.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions. The five files, one at a time, full screen.

**Workflow 1: run the tests.** You read this file in V142, so only the summary. Trigger: pushes to `main`, and pull requests; the branch filter on `push` stops a second run for every push to a pull request branch. Permissions: `contents: read`, and every other permission is none. One job on `ubuntu-24.04` with a ten-minute limit; a fixed label does not move when `ubuntu-latest` migrates. Checkout with the defaults you know from V145, and `persist-credentials: false`. A step that prints what was checked out. Python 3.13, quoted. The tests, with `PYTHONPATH` set for that step only, because `env` at step level is the narrowest scope.

The textbook's prediction for the printing step, from the documentation: on a push to `main` it prints `refs/heads/main`, the pushed commit, `true` for shallow, and a status line that names a branch. On a pull request it prints `refs/pull/N/merge`, the test merge commit, `true`, and "HEAD (no branch)". Lab 26.1 has you confirm it.

**Workflow 2: linting.** Same trigger, same permissions. The differences are in the steps.

**[ON SCREEN]** `02-lint.yml`, the steps.

`astral-sh/setup-uv` installs uv. Its `python-version` input sets a variable for the rest of the job, and uv then provides that interpreter when a command needs it.

`uv sync --locked` creates the virtual environment from `uv.lock`, and fails if the lock file does not match `pyproject.toml`. The textbook's summary of that line: CI installs what was reviewed, or stops.

Then two checks with IDs: `uv run ruff check`, and `uv run ruff format --check`. The second has `if: !cancelled()` in the expression wrapper. That replaces the implicit `success()`, so formatting is checked even when linting failed. One push reports both problems. And the job still fails, because a failed step fails the job unless `continue-on-error` is set.

The last step reads the two step outcomes through `env` and appends a Markdown table to the step summary. The braces group the `echo` commands so that one redirection covers all of them.

**Workflow 3: build.** You read this in V144. Trigger: pushes to `main`, pushes of tags that match `v*`, and manual runs. The pattern is quoted, because a star is YAML syntax at the start of a scalar. `branches` and `tags` under one `push` are alternatives: a push matches if it is a matching branch or a matching tag. There is no `pull_request` trigger, so a pull request that adds this file starts no run of it.

`defaults.run.shell: bash`, so pipelines fail properly. `fetch-depth: 0`, because the next step runs `git describe --tags --always` and needs history and tags. That step has the ID `describe` and appends to `GITHUB_OUTPUT`. The job publishes two outputs. The second job, `report`, has `needs: build`, no checkout, and reads the outputs through `env`. The textbook's sentence: the only things that reached the second machine are two strings.

**Workflow 4: Python tests with uv and caching.**

**[ON SCREEN]** `04-python-tests.yml`.

Same trigger and permissions as workflows 1 and 2. Then a block you have not read yet: `concurrency`. The group is built from the workflow name and `github.ref`, with `cancel-in-progress: true`. One run at a time per workflow and ref; a new push to the same branch or pull request cancels the run in progress. For pull requests `github.ref` is `refs/pull/N/merge`, so each pull request is its own group. Concurrency has its own video, V150.

The setup step has an ID and two new inputs. `enable-cache: true` turns on the cache built into the action. `cache-dependency-glob: uv.lock` makes the lock file the only input to the key. So a changed lock file gives a new key and a miss, and any other change gives a hit. You computed exactly that in the last video.

The next step prints the action's `cache-hit` output, mapped through `env`, so the log states which case occurred. Then `uv sync --locked`, then `uv run pytest`, which collects the `unittest` classes of the sample project.

**Workflow 5: Java tests with Maven.**

**[ON SCREEN]** `05-java-tests.yml`.

This is the file with a path filter. Under both `push` and `pull_request`, two paths: everything under `java-service`, and the workflow file itself. Listing the workflow file means that an edit to the CI is tested by the CI.

And here is the sentence from the textbook that connects to the hook of V143: do not make this workflow a required check. A workflow that the filter skips creates no check.

The job sets `defaults.run.working-directory` to `java-service`. The comment in the file states the limit: it applies to `run` steps only. `uses` steps still resolve paths from the workspace root, which is why the upload path further down is written in full.

`actions/setup-java` installs Temurin 21; the `distribution` input is required. `cache: maven` restores the local Maven repository from a cache keyed on the given `pom.xml`.

`mvn -B verify`: `-B` is Maven's batch mode, with no interactive prompts and no color codes in the log.

The last step uploads the test reports with `if: failure()`, so only when an earlier step failed, and keeps them for 7 days.

**What can go wrong across all five.** Section 20A.16 is a table of nine symptoms, and you can now explain each one from a mechanism: the merge ref, the shallow clone, the filter that creates no run, the missing `pipefail`, the empty output, the `if` that is a string, the stale cache, the unquoted version, and the secret that does not reach a fork.

## MENTAL MODEL

Every workflow file has four kinds of lines, and only one of them is the check.

The trigger decides whether a run exists and which commit it is about.

The permissions decide what the job's token may do.

The environment setup decides what is on the machine: the checkout, the language toolchain, the cache.

And the commands are the check itself: `python -m unittest`, `uv run ruff check`, `uv build`, `uv run pytest`, `mvn -B verify`.

Count the lines in each category in workflow 4. The check is two lines. Everything else exists to make those two lines mean something: the right commit, the dependencies that were reviewed, a token that cannot do harm, a run that stops when a newer push makes it pointless.

That proportion is the answer to the executive in the hook. "Green" is a statement about the two lines. Whether it is evidence about the change depends on all the others.

One rule from section 20A.17 follows from this picture: do not put the only copy of a procedure in a workflow. A build that exists only as YAML steps cannot be run on a laptop or on another CI system. Keep the commands in the repository and let the workflow call them. Look at the five files again with that rule in mind: each check is a command you can type locally. The lab has you do so before you push.

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

**[DIAGRAM]** The bottom bracket is two lines. Read a workflow from the top bracket down, and judge a green result by all four.

## LIVE TERMINAL DEMO

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

`git commit` is 🟢 SAFE: it adds objects and moves the current branch forward. Notice the order: the tests run locally first, with the same command the workflow uses. **[PAUSE]** How many files under `.github` will `git ls-files` list, and what does that tell you about where a workflow lives?

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

One: `.github/workflows/01-tests.yml`, a tracked file among the others. The project also contains a Dockerfile, a Java module, a `pyproject.toml` and a deployment script; workflows 3 to 7 use them.

Here the lab's second movement would follow. Before the push that creates the repository on GitHub, you write down: the event, the workflow that starts, `GITHUB_REF`, `GITHUB_SHA`, and how many commits the runner will have. Do not skip it.

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

Locally: exit status 1, one failure. On GitHub, pushed as a pull request, the same command is the last step of the job. **[PAUSE]** Which step of workflow 1 will be red, and what will the step before it have printed for the ref?

**Step 3: recover.**

```bash
git revert --no-edit HEAD
git log --format=%s -3
git diff --stat main
```

`git revert` is 🟡: it adds one commit; the branch moves, the index and files are updated, and nothing is removed.

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

A new commit that undoes the bad one. Three subjects in the log, and the last command prints nothing: the branch content equals `main` again. The branch history stays honest about what happened.

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

A branch that adds an unused import on purpose, committed and pushed. `git push` is 🟡 CAUTION. The last two commands show what a pull request would list and show: one commit, `41794f1`, and two added lines in one file. Predict from workflow 2: which step fails on this, `ruff check` or `ruff format --check`? And does the other one still run? You know the answer to the second question from the `if`.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthroughs.

On your practice repository, in your normal shell. The interface changes; the lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

Lab 26.1. After the push, open the run of the "Tests" workflow, open the job "Unit tests", and expand the step "Show what was checked out". Compare its six lines with what you wrote. Then push the breaking branch as a pull request and read the same step again: the ref and the commit are different in kind. That comparison is the lab.

Lab 26.4. Add workflow 4 through a pull request. In the job log, find the step that reports the cache result, on the first run and on the second. Then change the lock file as the lab describes and find it a third time. In the run list, look for a run that was cancelled when you pushed again quickly, and connect it to the `concurrency` block.

Lab 26.5. Add workflow 5. First open a pull request that changes only documentation and look at its list of checks: is the Java check there at all? Then one that touches the Java module. This is where you may meet a failure the authors could not test, since the Maven module was not built by them. If so, read the log from the checked-out commit downward, and treat it as practice for the next module.

For manual runs in these labs, section 20A.18 labels `gh workflow run` as 🟡 CAUTION: it starts a run, which uses minutes and may deploy if the workflow deploys. The preview is to read the workflow file at that ref.

## COMMON MISTAKES

1. **Making the path-filtered workflow a required check.** Root cause: a workflow that a filter skips never creates its check, so the pull request waits for a result that will not come.
2. **Installing without `--locked` in CI.** Root cause: without the lock file as the authority, a stale cache or a new upstream release can change what is installed between the review and the run.
3. **Adding `fetch-depth: 0` to every job.** Root cause: on a repository with a long history it turns a one-second fetch into a full clone for every job; only the job that asks history a question needs it.
4. **Using `continue-on-error` or `if: always()` without a comment and without testing results.** Root cause: both hide failures by design.
5. **Expecting `defaults.run.working-directory` to apply to an action's paths.** Root cause: it applies to `run` steps only; `uses` steps resolve paths from the workspace root.

## PRODUCTION EXAMPLE

A backend team with a Python service and a small Java module adopts these five files. Two weeks later a pull request that changes only a README cannot be merged. The Java workflow had been added to the required checks "for consistency".

The diagnosis is the one you can now do in your head. Trigger of workflow 5: a path filter. Changed paths of the pull request: one Markdown file. No run exists, so no check is reported, and the ruleset waits.

Section 20A.16 gives the fix and the prevention. The fix: remove the filter from required workflows, or require a job that always runs. The prevention: require one aggregate job, and filter inside jobs, not on the workflow.

And the last line of section 20A.17 is the governance point for the whole set: a workflow file is code that runs with a token. Anyone who can push a branch can change what `push` and `pull_request` workflows do on that branch. Protect `.github/workflows/` with CODEOWNERS and a ruleset, as you learned in V136.

## PRACTICE EXERCISE

Do Lab 26.5, "Workflow 5, Java tests with Maven", in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md), in your normal shell.

Before each push, predict with a three-dot diff whether the workflow will start, as you did in V143. Write the prediction down, then look at the list of checks.

The challenge is Exercise 26.3, "Six things the author did not mean", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q302: "An executive says: "The pipeline is green, so the tests passed and the change is safe to merge." Explain in plain terms the distinct ways a green result on GitHub Actions can be false evidence, and the organization-wide controls you would set."

A strong answer is in plain language, because the listener is an executive, and still names distinct mechanisms, not one mechanism five times. Group them by the four brackets: did a run exist for this commit; was it the commit that will be merged; did the step's status reflect the command; was the workflow file itself the reviewed one. Then give controls at organization level, each matched to a mechanism. The follow-up asks which of those controls one engineer with push access to a branch can undo for their own pull request without touching any setting. Think about which file is read from the branch.

## RECAP

You should now be able to say:

- Each of the five files answers four questions in order: when it runs, with what token, on what machine and commit, and which command is the check.
- CI installs from the lock file with `--locked`, so what runs is what was reviewed.
- A cache keyed on the lock file hits on every change except a dependency change.
- A path-filtered workflow must not be a required check; require one job that always runs.
- These files were parse-checked and assembled from documentation, not run on GitHub by the author; the Maven module was not built by the author either.

## HOMEWORK

Read the first five workflows of section 20A.13 in [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md). Do Lab 26.2, "Workflow 2, linting", to Lab 26.4, "Workflow 4, Python tests with uv and caching", in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md) if not done. Do Exercise 26.7, "Read a run from the terminal", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).
