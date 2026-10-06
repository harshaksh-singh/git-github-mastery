# Module 26 labs: GitHub Actions fundamentals

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Read [Chapter 20A](../textbook/ch20a-actions-fundamentals.md) first; each lab names the sections it uses. Every transcript under "Expected output" is real output of a replay script in `labs/ch20a/`. Nothing in this file was run on GitHub: the eight workflows were parse-checked and assembled from documented syntax, and **you are the first to execute them**. What GitHub shows is described from its documentation, with the link, and you record what you actually see. Answers to the questions are in [the solutions](../solutions/m26-lab-answers.md); write your own first.

## How these labs work

**These labs contact GitHub, so their GitHub steps run in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub (Chapter 16: Authentication explains the mechanism). GitHub commands are shown in `bash` blocks without output, because nothing was captured from GitHub.

Each lab has the same five movements: **add** the workflow file, **predict** when it runs and what is checked out, **run** it, **read** the log, then **break** it on purpose and diagnose. Write your prediction down before you look at the run. A prediction you did not write is not a prediction.

What "Expected output" means here:

- For local commands it is the output of a replay script, in which a bare repository on disk stands in for GitHub. Watch any of them with `labs/run`, for example `labs/run ch20a/lab-26-3-describe`. Commits you make by hand have other IDs than the book's, because the commit time is part of the ID. A line `[exit status: N]` is added by the replay tool; in your own shell `echo $?` prints the same number.
- For GitHub it is a description from the documentation. Where a workflow has never been executed, the honest expectation includes "it may fail for a reason the author could not test"; the labs say where that risk is and treat such a failure as material for diagnosis.

Names used in this module:

| Placeholder | Meaning |
|---|---|
| `YOUR-ORG` | your practice organization (Lab 19.1) |
| `inventory-api` | the practice repository for Actions, `YOUR-ORG/inventory-api`, created in Lab 26.1 from `sample-project/` |
| `~/git-mastery/inventory-api` | your clone of it |
| `COURSE` | the course folder. Set it once per shell: `COURSE=/path/to/the/course` |

The repository is **public**: standard GitHub-hosted runners are free for public repositories ([billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions)), and anyone can read its logs and artifacts. Never put a secret, work code or customer data in it.

**The standard cycle.** Labs refer to these commands by name. `FILE` is the workflow file name and `BRANCH` your branch.

```bash
# add: copy a workflow into the repository on a branch, and open a pull request
cd ~/git-mastery/inventory-api
git switch -c BRANCH main
cp "$COURSE/workflows/FILE" .github/workflows/
git add .github/workflows/FILE
git commit -m "Add workflow FILE"
git push -u origin BRANCH
gh pr create --fill --base main

# run and read
gh pr checks --watch                       # the checks of the pull request, until they finish
gh run list --workflow FILE --limit 5      # the runs of one workflow, newest first
gh run view RUN-ID --verbose               # jobs and steps of one run
gh run view RUN-ID --log                   # the full log
gh run view RUN-ID --log-failed            # only the failed steps

# finish
gh pr merge --squash --delete-branch
git switch main && git pull --ff-only
```

All flags were checked with `gh <command> --help` of version 2.88.1. If a push that adds a file under `.github/workflows/` is rejected with a message that mentions the `workflow` scope, run `gh auth refresh --scopes workflow` and push again.

> **Unverified.** The exact wording of that rejection, and the wording of every log line and error message of GitHub Actions quoted as "expect" below, could not be captured here. Where a lab says what a log contains, it is a prediction from the documentation; correct it in your notes with what you see.

## Lab 26.1: Workflow 1, run the tests

### Objective

Turn the sample project into a repository on GitHub, add the minimal test workflow, and confirm from the log which commit a `push` run and a `pull_request` run check out. Break a test and read the failure.

### Prerequisites

Chapter 20A, sections 20A.2, 20A.4, 20A.8 and the walk-through of workflow 1 in 20A.13. Lab 19.1 (the practice organization). `gh auth status` reports that you are logged in.

### Setup

```bash
COURSE=/path/to/the/course
mkdir -p ~/git-mastery
cp -R "$COURSE/sample-project" ~/git-mastery/inventory-api
cd ~/git-mastery/inventory-api
git init
PYTHONPATH=src python3 -m unittest discover -s tests
```

The last command must end with `OK`.

### Commands

```bash
# 1. First commit: the project and workflow 1 together
mkdir -p .github/workflows
cp "$COURSE/workflows/01-tests.yml" .github/workflows/
git add .
git commit -m "Add inventory-api and the tests workflow"
git ls-files

# 2. Predict. Write down: which event will the next command cause, which workflow starts,
#    what will GITHUB_REF and GITHUB_SHA be, how many commits will the runner have?
git rev-parse HEAD

# 3. Create the repository on GitHub and push (this is a push to main)
gh repo create YOUR-ORG/inventory-api --public --source . --remote origin --push

# 4. Run and read
gh run list --workflow 01-tests.yml --limit 5
gh run view RUN-ID --verbose
gh run view RUN-ID --log
```

In the log, find the step "Show what was checked out" and compare its six lines with your prediction.

### Expected output

The local part, replayed (`labs/run ch20a/lab-26-1-first-workflow`):

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

On GitHub, from the documentation: the push to `main` matches `on.push.branches: [main]`, so one run of "Tests" starts with `GITHUB_REF` `refs/heads/main` and `GITHUB_SHA` equal to the ID that `git rev-parse HEAD` printed ([events: push](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#push)). `git rev-parse --is-shallow-repository` prints `true`, because the checkout fetched one commit ([checkout README](https://github.com/actions/checkout/blob/v7.0.1/README.md)). The test step lists 15 tests and ends with `OK`.

### What happened internally

`gh repo create --source . --push` created a GitHub repository, added the remote `origin`, and pushed `main`. The push delivered commits and updated `refs/heads/main` on GitHub: that is Git. GitHub then generated a `push` event, found a workflow file in the pushed commit whose trigger matched, created a workflow run, and assigned its one job to a new virtual machine with the `ubuntu-24.04` image: that is GitHub Actions. On that machine the checkout action fetched one commit; the next step printed what is there; `setup-python` put Python 3.13 on `PATH`; the last step ran the tests. Nothing in your clone changed, and no Git object was created by the run.

### Checkpoint

- `gh run list --workflow 01-tests.yml` shows one completed run with the event `push`.
- You can point at the log line that proves the clone was shallow.

### Failure scenario

Break a test on a branch and open a pull request, so that the event is `pull_request`.

```bash
git switch -c break/wrong-total
# edit tests/test_stock.py: in test_total_units change the expected 12 to 13
PYTHONPATH=src python3 -m unittest discover -s tests; echo "exit status: $?"
git commit -am "Break a test on purpose"

# Predict again before pushing: GITHUB_REF? GITHUB_SHA? Is the commit you just made the one CI tests?
git rev-parse HEAD
git push -u origin break/wrong-total
gh pr create --fill --base main
gh pr checks --watch
gh run view RUN-ID --log-failed
```

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

On GitHub, expect the check "Unit tests" to fail. In the log, "Show what was checked out" prints `refs/pull/N/merge` as `GITHUB_REF`, a `GITHUB_SHA` that is **not** the ID you printed, and a status line `## HEAD (no branch)` ([how the merge branch affects your workflow](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#how-the-merge-branch-affects-your-workflow)). The transcript `labs/run ch20a/merge-ref` shows the same state built locally.

### Recovery

A pushed commit is undone with a new commit, not by rewriting the branch (Chapter 11).

```bash
git revert --no-edit HEAD
PYTHONPATH=src python3 -m unittest discover -s tests; echo "exit status: $?"
git push
gh pr checks --watch
```

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

### Verification

```bash
gh pr checks                       # the check passes on the new run
git diff --stat main               # prints nothing: the branch content equals main
gh pr close --delete-branch        # nothing to merge
git switch main
```

### Questions

1. For the `push` run and for the `pull_request` run: what were `GITHUB_REF` and `GITHUB_SHA`, and which of the two IDs exists in your clone?
2. Why does `on.push` have `branches: [main]`? What would happen on every push to a pull request branch without it?
3. The workflow sets `permissions: contents: read`. Name one thing the job could do without that block that it cannot do with it, given a repository whose default token permission is read and write.
4. The pull request run failed, you pushed the revert, and a new run passed. Could "Re-run failed jobs" on the first run have turned it green? Why?
5. The test step sets `PYTHONPATH` under `env:` of the step. What would change if it were set at the top of the workflow file?

## Lab 26.2: Workflow 2, linting

### Objective

Create the lock file, add the lint workflow, and make it fail in a way that shows two things: which step failed, and that the step after it still ran.

### Prerequisites

Chapter 20A, sections 20A.7, 20A.9 and the walk-through of workflow 2. Lab 26.1. [uv](https://docs.astral.sh/uv/) installed (`uv --version`).

### Setup

`uv lock` resolves the `dev` dependency group and writes `uv.lock`. It contacts the Python package index, which is why the course could not ship the file.

```bash
cd ~/git-mastery/inventory-api
git switch main && git pull --ff-only
git switch -c ci/lint main
uv lock
git add uv.lock
git commit -m "Add uv.lock"
```

### Commands

```bash
# 1. The same commands the workflow runs, locally first
uv sync --locked
uv run ruff check .
uv run ruff format --check .

# 2. Add the workflow (standard cycle, FILE=02-lint.yml, on the branch ci/lint)
cp "$COURSE/workflows/02-lint.yml" .github/workflows/
git add .github/workflows/02-lint.yml
git commit -m "Add workflow 02-lint.yml"

# 3. Predict: which workflows start for the pull request, and how many checks will it show?
git push -u origin ci/lint
gh pr create --fill --base main
gh pr checks --watch
gh run view RUN-ID --verbose
gh pr merge --squash --delete-branch
git switch main && git pull --ff-only
```

### Expected output

There is no replay of `uv` or `ruff`: they are not part of the lab environment. With ruff 0.15.21 on the author's machine, `ruff check .` printed `All checks passed!` and `ruff format --check .` printed `3 files already formatted` for the sample project as shipped. Your ruff version is whatever `uv lock` resolved, so a newer rule set may report something; that would be a real finding to fix, not a lab error.

On GitHub, from the documentation: the pull request shows two checks, "Unit tests" from workflow 1 and "ruff" from workflow 2, because both workflows listen to `pull_request`. The run's summary page shows the table that the last step appended to `GITHUB_STEP_SUMMARY`, with `success` in both rows ([job summaries](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary)).

### What happened internally

`uv lock` wrote one file. `uv sync --locked` created `.venv/` (ignored by `.gitignore`) from that file and would have failed if the file did not match `pyproject.toml`. On the runner, `setup-uv` installed uv and set `UV_PYTHON`; the `sync` step installed pytest and ruff; each `uv run` started the tool inside the environment. Each of the three `run` steps was a separate `bash -e` process.

### Checkpoint

- `uv.lock` is committed on `main`.
- The pull request showed two checks from two workflow files.

### Failure scenario

An unused import, on a branch:

```bash
git switch -c break/unused-import main
# edit src/inventory_api/stock.py: add the line "import os" above "from collections.abc import Mapping"
uv run ruff check .; echo "exit status: $?"
uv run ruff format --check .; echo "exit status: $?"
git commit -am "Add an unused import on purpose"
git push -u origin break/unused-import
gh pr create --fill --base main
gh pr checks --watch
gh run view RUN-ID --verbose
```

The Git side, replayed on the reduced fixture project (`labs/run ch20a/lab-26-2-lint-branch`):

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

With ruff 0.15.21 the first local command reported rule F401 ("`os` imported but unused") with exit status 1, and the format check passed with status 0. On GitHub, expect the step "Lint" to fail, the step "Check formatting" to run and pass, the summary to show `failure` and `success`, and the check "ruff" to fail. The check "Unit tests" passes: an unused import breaks no test.

### Recovery

```bash
uv run ruff check --fix .
git diff
git commit -am "Remove the unused import"
git push
gh pr checks --watch
```

### Verification

```bash
gh pr checks
git diff --stat main          # prints nothing
gh pr close --delete-branch
git switch main
```

### Questions

1. The lint step failed. Why did the formatting step run anyway, and why did the job still fail?
2. The summary step reads `steps.lint.outcome`. What is the difference between `outcome` and `conclusion`, and when do they differ?
3. What does `--locked` protect against? What would `uv sync` without it do on the runner when `uv.lock` is stale?
4. The summary step passes the outcomes through `env` and not by writing `${{ steps.lint.outcome }}` inside the script. The value is not attacker-controlled. Why does the course still do it this way?
5. Both workflows ran for one pull request. On how many machines, and what did they share?

## Lab 26.3: Workflow 3, build the application

### Objective

Build the sdist and wheel on GitHub, pass two values from a step to another job, and see what `git describe` reports with and without history on the runner.

### Prerequisites

Chapter 20A, sections 20A.7, 20A.8 and the walk-through of workflow 3. Labs 26.1 and 26.2.

### Setup

Add the workflow through a pull request and merge it (standard cycle, `FILE=03-build.yml`, `BRANCH=ci/build`). The pull request itself starts no run of this workflow: it has no `pull_request` trigger. The merge is a push to `main`, which does.

### Commands

```bash
cd ~/git-mastery/inventory-api
git switch main && git pull --ff-only

# 1. An annotated tag, so that describe has something to find
git tag -a v0.1.0 -m "inventory-api 0.1.0"
git describe --tags --always

# 2. Predict: which workflows start when the tag is pushed? What will the build job print
#    for "Building ..."? Then push the tag.
git push origin v0.1.0
gh run list --workflow 03-build.yml --limit 5
gh run view RUN-ID --log

# 3. One more commit on main through a pull request, then predict the description again
git switch -c docs/build-note main
echo "Build with: uv build" >> README.md
git commit -am "Document the build command"
git push -u origin docs/build-note
gh pr create --fill --base main
gh pr merge --squash --delete-branch
git switch main && git pull --ff-only
git describe --tags --always
gh run list --workflow 03-build.yml --limit 5

# 4. A manual run
gh workflow run 03-build.yml --ref main
gh run watch
```

### Expected output

What `describe` prints in three kinds of clone, replayed on the fixture (`labs/run ch20a/lab-26-3-describe`):

<!-- snippet: ch20a/lab-26-3-describe/01-predict -->
```text
$ git tag --list -n1
v0.1.0          inventory-api 0.1.0
$ git describe --tags --always
v0.1.0-1-g6fe5455
# A clone like the default checkout (one commit, no tags):
$ git clone --quiet --depth 1 --no-tags "file://$PWD" ../default-checkout
$ git -C ../default-checkout describe --tags --always
6fe5455
# A clone like fetch-depth: 0 (all history, all tags):
$ git clone --quiet "file://$PWD" ../full-checkout
$ git -C ../full-checkout describe --tags --always
v0.1.0-1-g6fe5455
```
<!-- /snippet -->

<!-- snippet: ch20a/lab-26-3-describe/02-tagged-commit -->
```text
# On the tagged commit itself the description is the tag name:
$ git describe --tags --always v0.1.0
v0.1.0
$ git cat-file -t v0.1.0
tag
$ git rev-parse v0.1.0 "v0.1.0^{commit}"
192d2bc34d491d9b35cc1c00e50dde959dd9df55
ae299cbfba5ad3d9388d3dded0eeee37b09946aa
```
<!-- /snippet -->

On GitHub, from the documentation: the tag push matches `tags: ["v*"]`, so "Build" runs with `GITHUB_REF` `refs/tags/v0.1.0`; the job prints `Building v0.1.0`, because HEAD is the tagged commit. The run after step 3 prints `Building v0.1.0-1-g` followed by the abbreviated ID of the squash commit, the same text your clone printed. The "Report" job's summary shows both values. The file names in `dist/` should be `inventory_api-0.1.0.tar.gz` and `inventory_api-0.1.0-py3-none-any.whl`.

`uv build` with the hatchling backend was not run by the author. If the build step fails, the failed step's log is your material: read which file the backend could not find, and compare with the `[build-system]` and `[tool.hatch.build.targets.wheel]` tables of `pyproject.toml`.

### What happened internally

`git tag -a` created a tag object and the ref `refs/tags/v0.1.0`; the push sent both. On the runner, `fetch-depth: 0` fetched every commit and every tag, so `git describe` could walk from HEAD to the tagged commit. The step appended `describe=...` to the file named by `GITHUB_OUTPUT`; the runner turned it into a step output; the job's `outputs` block turned that into a job output; the second job, on another machine, received it through `needs`.

### Checkpoint

- Three runs of "Build": one for the merge, one for the tag, one for the next merge. A fourth after the manual run.
- You can say why the tag push did not start "Tests" (workflow 1).

### Failure scenario

Remove the history and watch the version degrade without an error. The workflow has no pull request trigger, so run the branch's version by hand: `workflow_dispatch` uses the workflow file of the ref you name.

```bash
git switch -c break/shallow-build main
# edit .github/workflows/03-build.yml: delete the line "fetch-depth: 0"
git commit -am "Remove fetch-depth on purpose"
git push -u origin break/shallow-build
gh workflow run 03-build.yml --ref break/shallow-build
gh run watch
gh run view RUN-ID --log
```

Expect a green run whose "Describe the commit" step prints `Building ` followed by a bare abbreviated commit ID, as in the middle of the first transcript above. Nothing failed. A release built this way would carry a commit ID where a version belongs.

### Recovery

```bash
git revert --no-edit HEAD
git push
gh workflow run 03-build.yml --ref break/shallow-build
gh run watch
```

### Verification

```bash
gh run view RUN-ID --log          # "Building v0.1.0-..." again
git push origin --delete break/shallow-build
git switch main && git branch -D break/shallow-build
```

`git branch -D` is 🟡 CAUTION: it deletes a branch that is not merged. Here the branch holds only the deliberate break and its revert.

### Questions

1. Why did the failure scenario produce a green run? Which flag of `git describe` made that possible, and would you keep it in a release workflow?
2. Would `fetch-tags: true` without `fetch-depth: 0` have repaired the description? Use the transcript of section 20A.8 to justify the answer.
3. Trace the value `describe` from the shell variable to the job summary of the second job. Name every hop.
4. `gh workflow run 03-build.yml --ref break/shallow-build` ran the edited file. What must be true of the default branch for this command to work at all?
5. The workflow sets `defaults.run.shell: bash`. Which line of the build job has a pipeline, and what would the implicit default have done if `ls dist` failed?

## Lab 26.4: Workflow 4, Python tests with uv and caching

### Objective

Run pytest through uv with a dependency cache, observe a miss followed by a hit, inspect the cache with the CLI, and break the lock-file contract.

### Prerequisites

Chapter 20A, section 20A.11 and the walk-through of workflow 4. Lab 26.2 (`uv.lock` is on `main`).

### Setup

None beyond a current `main`:

```bash
cd ~/git-mastery/inventory-api
git switch main && git pull --ff-only
```

### Commands

```bash
# 1. Add the workflow (standard cycle, FILE=04-python-tests.yml, BRANCH=ci/python-tests)
#    Predict before pushing: cache hit or miss on the first run? Why?
#    After the run: read the step "Report the cache result".
gh run view RUN-ID --log

# 2. Push one more commit that does not touch uv.lock to the same branch. Predict: hit or miss?
echo "Test with: uv run pytest" >> README.md
git commit -am "Document the test command"
git push
gh pr checks --watch
gh run view RUN-ID --log

# 3. Look at the caches of the repository, then merge
gh cache list
gh pr merge --squash --delete-branch
git switch main && git pull --ff-only
gh cache list
```

### Expected output

The idea behind the key, replayed with a stand-in lock file (`labs/run ch20a/lab-26-4-cache-key`). The hash shown is a plain SHA-256 of the file; `hashFiles` and `setup-uv` combine their inputs in their own way, so the value on GitHub is different, but it changes at the same moments.

<!-- snippet: ch20a/lab-26-4-cache-key/01-key -->
```text
$ cat uv.lock
version = 1

[[package]]
name = "pytest"
version = "8.4.0"
$ shasum -a 256 uv.lock | cut -c1-16
0071e96c6821a1de
# A commit that does not touch the lock file: same hash, same key, cache hit.
$ echo "Run the linter with: uv run ruff check ." >> README.md
$ git commit --quiet -am "Document the linter"
$ git diff --stat HEAD~1 -- uv.lock
$ shasum -a 256 uv.lock | cut -c1-16
0071e96c6821a1de
```
<!-- /snippet -->

<!-- snippet: ch20a/lab-26-4-cache-key/02-key-changes -->
```text
# A dependency update: new hash, new key, cache miss, and a new cache saved after the job.
$ sed -i.bak 's/8.4.0/8.4.1/' uv.lock && rm uv.lock.bak
$ git commit --quiet -am "Update pytest in the lock file"
$ git diff --stat HEAD~1 -- uv.lock
 uv.lock | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ shasum -a 256 uv.lock | cut -c1-16
6ac54238033dafef
```
<!-- /snippet -->

On GitHub, from the documentation: the first run reports a miss and saves a cache when the job ends successfully; the second run on the same pull request reports a hit, because the key did not change and a cache created by a pull request run is restorable by later runs of the same pull request ([restrictions for accessing a cache](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching#restrictions-for-accessing-a-cache)). The first `gh cache list` shows an entry whose ref is `refs/pull/N/merge`. After the merge, the push run on `main` cannot read that entry; it misses and saves an entry for `refs/heads/main`, which every later branch can restore.

### What happened internally

The cache is a GitHub object addressed by key, version and ref scope. `setup-uv` computed a key that depends on the files matched by `cache-dependency-glob` (its output `cache-key` holds the full key), asked the cache service for it, and registered a post-job step that saves uv's cache directory if there was no hit. Nothing about the cache is in Git.

### Checkpoint

- You saw `false` and then `true` in "Report the cache result" (or the equivalent wording of the action's log).
- `gh cache list` shows entries under two different refs.

### Failure scenario

Change the dependencies without updating the lock file.

```bash
git switch -c break/stale-lock main
# edit pyproject.toml: in the dev group, add the line   "pytest-cov>=5",
git commit -am "Add a dev dependency without relocking"
git push -u origin break/stale-lock
gh pr create --fill --base main
gh pr checks --watch
gh run view RUN-ID --log-failed
```

Expect "Install the project and the dev group from the lock file" to fail in the workflows that run `uv sync --locked` (workflows 2 and 4): `--locked` asserts that `uv.lock` will remain unchanged (`uv sync --help`), and the new dependency would change it. Workflow 1 passes, because it installs nothing.

### Recovery

```bash
uv lock
git add uv.lock
git commit -m "Update uv.lock for pytest-cov"
git push
gh pr checks --watch
```

Predict before you look: is this run a cache hit?

### Verification

```bash
gh pr checks
gh cache list
gh pr close --delete-branch
git switch main
```

### Questions

1. Why was the first run after the merge to `main` a cache miss, although a cache with the same key existed?
2. The recovery run: hit or miss, and why?
3. `cache-hit` of `actions/cache` is `false` when a restore key matched. Why is "false" the useful answer there?
4. What does the concurrency block of this workflow do when you push twice within a few seconds? What is `github.ref` for a pull request run?
5. A colleague proposes caching a 6 GB evaluation model the same way. Give three reasons from section 20A.11 against it.

## Lab 26.5: Workflow 5, Java tests with Maven

### Objective

Predict from Git alone whether a path-filtered workflow starts, build the Maven module for the first time, and retrieve test reports from a failed run.

### Prerequisites

Chapter 20A, sections 20A.4, 20A.9, 20A.12 and the walk-through of workflow 5. Lab 26.1.

### Setup

Add the workflow (standard cycle, `FILE=05-java-tests.yml`, `BRANCH=ci/java-tests`). The pull request changes `.github/workflows/05-java-tests.yml`, which the filter lists, so this pull request does start the workflow.

**This is the first build of the Maven module anywhere.** The author had no JDK. If `mvn -B verify` fails for a reason other than a test, diagnose it as you would a colleague's untested code: read the first `[ERROR]` line of the log, decide whether it is the `pom.xml`, the source, or the environment, fix it on the branch, and note what it was.

### Commands

```bash
cd ~/git-mastery/inventory-api
git switch main && git pull --ff-only

# 1. A documentation-only branch. Predict with Git whether workflow 5 starts.
git switch -c docs/java-readme main
echo "The Java module lives in java-service/." >> README.md
git commit -am "Mention the Java module"
git fetch origin
git diff --name-only origin/main...HEAD
git diff --quiet origin/main...HEAD -- "java-service/**" ".github/workflows/05-java-tests.yml"; echo "exit status: $?"
git push -u origin docs/java-readme
gh pr create --fill --base main
gh pr checks --watch

# 2. Now touch the Java module on the same branch and predict again.
#    edit java-service/pom.xml: change <version>0.1.0</version> to <version>0.1.1</version>
git commit -am "Bump java-service to 0.1.1"
git diff --quiet origin/main...HEAD -- "java-service/**" ".github/workflows/05-java-tests.yml"; echo "exit status: $?"
git push
gh pr checks --watch
```

### Expected output

Replayed on the fixture (`labs/run ch20a/lab-26-5-path-filter`):

<!-- snippet: ch20a/lab-26-5-path-filter/01-docs-only -->
```text
$ git switch -c docs/java-readme
Switched to a new branch 'docs/java-readme'
$ echo "The Java module lives in java-service/." >> README.md
$ git commit --quiet -am "Mention the Java module"
$ git diff --name-only origin/main...HEAD
README.md
$ git diff --quiet origin/main...HEAD -- "java-service/**" ".github/workflows/05-java-tests.yml"
[exit status: 0]
# Status 0: nothing under the filtered paths changed. The workflow does not start.
```
<!-- /snippet -->

<!-- snippet: ch20a/lab-26-5-path-filter/02-java-change -->
```text
$ sed -i.bak 's/0.1.0/0.1.1/' java-service/pom.xml && rm java-service/pom.xml.bak
$ git commit --quiet -am "Bump java-service to 0.1.1"
$ git diff --name-only origin/main...HEAD
README.md
java-service/pom.xml
$ git diff --quiet origin/main...HEAD -- "java-service/**" ".github/workflows/05-java-tests.yml"
[exit status: 1]
# Status 1: a filtered path changed somewhere in the pull request. The workflow starts.
```
<!-- /snippet -->

On GitHub, from the documentation: after step 1 the pull request lists the checks of the other workflows and no "mvn verify"; after step 2 it lists "mvn verify" as well. Note that the second push changed only `pom.xml`, yet the filter is evaluated on the whole pull request's three-dot diff ([diff comparisons](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#git-diff-comparisons)), which is why the transcript's second diff lists both files.

### What happened internally

For a pull request, GitHub compared the merge base of base and head with the head and matched the changed paths against the `paths` patterns. No match: no workflow run was created, so no check exists. That is different from a job that ran and was skipped. On the runner, `setup-java` installed a JDK, restored or created the Maven cache, and `mvn -B verify` compiled, ran the JUnit tests through Surefire, and packaged the jar under `java-service/target/`.

### Checkpoint

- You predicted both outcomes with `git diff --quiet` before GitHub showed them.
- "mvn verify" passed once.

### Failure scenario

```bash
# edit java-service/src/test/java/com/example/inventory/PriceCalculatorTest.java:
#   in lineTotalMultipliesAndRounds change "59.97" to "59.98"
git commit -am "Break a Java test on purpose"
git push
gh pr checks --watch
gh run view RUN-ID --log-failed
gh run download RUN-ID --name surefire-reports --dir /tmp/surefire-reports
ls /tmp/surefire-reports
```

Expect "Build and test" to fail, "Upload the test reports when the job failed" to run because of `if: ${{ failure() }}`, and the download to contain Surefire's text and XML reports for `PriceCalculatorTest`.

### Recovery

```bash
git revert --no-edit HEAD
git push
gh pr checks --watch
```

### Verification

```bash
gh pr checks
gh pr merge --squash --delete-branch
git switch main && git pull --ff-only
rm -r /tmp/surefire-reports
```

### Questions

1. After step 1 the pull request had no "mvn verify" check. If a ruleset required that check, what would the pull request page show, and for how long?
2. Why does the filter list the workflow file itself?
3. `defaults.run.working-directory` is `java-service`, yet the upload step's `path` starts with `java-service/`. Why?
4. On a successful run the upload step does not run. Is its check "skipped" a problem for a required check? Compare with question 1.
5. Your second push changed only `pom.xml`. Suppose instead the first commit had touched `java-service/` and the second only the README. Would the second push start the workflow? Why?

## Lab 26.6: Workflow 6, build and push a container image

### Objective

Build the image on every pull request without pushing it, push it to `ghcr.io` from `main` and from a version tag, and predict the image tags from Git facts. [Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md) and Lab 27.1 return to this file for delivery.

### Prerequisites

Chapter 20A, section 20A.6 and the walk-through of workflow 6. Lab 26.3 (the tag `v0.1.0` exists).

### Setup

Add the workflow (standard cycle, `FILE=06-docker-image.yml`, `BRANCH=ci/docker-image`). Do not merge yet: step 1 below reads the pull request run first.

**This is the first build of the Dockerfile anywhere.** The author could pull no base image. If the build step fails on the pull request, read which Dockerfile instruction the log names and fix it on the branch.

### Commands

```bash
cd ~/git-mastery/inventory-api

# 1. The pull request run. Predict: is the login step executed? Is anything pushed? Which tags
#    does the "Compute tags and labels" step produce for a pull request?
gh pr checks --watch
gh run view RUN-ID --verbose
gh pr merge --squash --delete-branch
git switch main && git pull --ff-only

# 2. The push run on main. Predict the tags from these two values:
git branch --show-current
git rev-parse --short=7 HEAD
gh run list --workflow 06-docker-image.yml --limit 5
gh run view RUN-ID --log

# 3. A version tag. Predict which workflows start and which image tags appear.
git tag -a v0.2.0 -m "inventory-api 0.2.0"
git push origin v0.2.0
gh run list --limit 5
```

If Docker is installed and you want to see the result, the image of a public repository can be pulled without logging in (replace the organization name with yours, in lower case):

```bash
docker run --rm ghcr.io/your-org/inventory-api:0.2.0
```

### Expected output

The Git facts, replayed on the fixture (`labs/run ch20a/lab-26-6-image-tags`):

<!-- snippet: ch20a/lab-26-6-image-tags/01-inputs -->
```text
$ git branch --show-current
main
$ git rev-parse --short=7 HEAD
6fe5455
$ git tag -a v0.2.0 -m "inventory-api 0.2.0"
$ git push origin v0.2.0
To ../../hub/inventory-api.git
 * [new tag]         v0.2.0 -> v0.2.0
$ git ls-remote --tags origin
192d2bc34d491d9b35cc1c00e50dde959dd9df55	refs/tags/v0.1.0
ae299cbfba5ad3d9388d3dded0eeee37b09946aa	refs/tags/v0.1.0^{}
21ea2601b402ac0121b4b87c37b464dd1d01390b	refs/tags/v0.2.0
6fe5455926c26261fe2c73104018ca2d96fdb554	refs/tags/v0.2.0^{}
$ git for-each-ref --format="%(refname) %(objecttype)" refs/tags
refs/tags/v0.1.0 tag
refs/tags/v0.2.0 tag
```
<!-- /snippet -->

On GitHub, from the READMEs of the Docker actions at the pinned versions:

| Run | Login | Push | Tags computed |
|---|---|---|---|
| pull request N | skipped | no | `pr-N`, `sha-<7 characters>` |
| push to `main` | yes | yes | `main`, `sha-<7 characters>` |
| push of tag `v0.2.0` | yes | yes | `0.2.0`, `latest`, `sha-<7 characters>` |

For the pull request, the commit behind `sha-` is the test merge commit, not your head commit: the action uses the commit that triggered the workflow unless `DOCKER_METADATA_PR_HEAD_SHA` is set (metadata-action README). `type=ref,event=branch` produces nothing for a tag push and `type=semver` nothing for a branch push. `docker run` should print the two report lines of `inventory_api.stock.main()`. The package appears in the organization's Packages list and inherits the repository's visibility ([publishing with Actions](https://docs.github.com/en/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions)).

### What happened internally

The tag push created `refs/tags/v0.2.0` on GitHub and a `push` event for that ref. Workflows 3 and 6 match it through `tags: ["v*"]`; workflows whose `push` trigger lists only `branches` do not. In workflow 6 the job token had `packages: write` for that job only; `docker/login-action` used it as the registry password; `docker/metadata-action` turned the event into tag names and OCI labels; `docker/build-push-action` built from the checked-out directory and pushed. The image is a GitHub package, not Git data.

### Checkpoint

- Three runs of "Docker image": pull request (no push), `main`, tag.
- You predicted each run's tags before reading the summary.

### Failure scenario

A Dockerfile that copies a directory that does not exist. A pull request is enough, and it pushes nothing.

```bash
git switch -c break/dockerfile main
# edit Dockerfile: change "COPY src/ ./src/" to "COPY sources/ ./src/"
git commit -am "Break the Dockerfile on purpose"
git push -u origin break/dockerfile
gh pr create --fill --base main
gh pr checks --watch
gh run view RUN-ID --log-failed
```

Expect "Build, and push unless this is a pull request" to fail with a message from the builder that names the `COPY` instruction and the missing path. The other workflows pass: nothing they test changed.

### Recovery

```bash
git revert --no-edit HEAD
git push
gh pr checks --watch
```

### Verification

```bash
gh pr checks
gh pr close --delete-branch
git switch main
git ls-remote --tags origin
```

### Questions

1. Why does the workflow declare `packages: write` on the job and not at the top of the file? What does the job-level block do to the top-level one?
2. A pull request from a fork runs this workflow. Which steps run, and what would happen if the `if` on the login step were removed?
3. The tag `v0.2.0` produced the image tag `latest`. Which input controls that, and when would you turn it off?
4. Deleting the Git tag `v0.2.0` on GitHub: what happens to the image `0.2.0`? Label each object as Git data or a GitHub object.
5. `cache-from: type=gha` restores layers from the Actions cache. A pull request run and a `main` run: which can read the other's cached layers, by the scope rules of section 20A.11?

## Lab 26.7: Workflow 7, create an artifact and consume it

### Objective

Upload build outputs in one job, download them in the next, deploy them with the simulated script, and download the artifact to your machine. Then remove the job dependency and diagnose the result.

### Prerequisites

Chapter 20A, sections 20A.9, 20A.12 and the walk-through of workflow 7. Lab 26.3.

### Setup

Add the workflow through a pull request and merge it (standard cycle, `FILE=07-artifact.yml`, `BRANCH=ci/artifact`). The merge is a push to `main` and starts the first run.

### Commands

```bash
cd ~/git-mastery/inventory-api
git switch main && git pull --ff-only

# 1. The deployment script, locally, against a stand-in for the downloaded artifact
mkdir -p /tmp/dist-standin
touch /tmp/dist-standin/inventory_api-0.1.0.tar.gz /tmp/dist-standin/inventory_api-0.1.0-py3-none-any.whl
bash scripts/deploy.sh staging /tmp/dist-standin; echo "exit status: $?"

# 2. Predict: in which order do the two jobs run, and what does the second job have on disk
#    before its download step? Then read the run.
gh run list --workflow 07-artifact.yml --limit 5
gh run view RUN-ID --verbose
gh run view RUN-ID --log

# 3. The artifact, on your machine
gh run download RUN-ID --name inventory-api-dist --dir /tmp/inventory-api-dist
ls /tmp/inventory-api-dist
```

### Expected output

The script, replayed (`labs/run ch20a/lab-26-7-artifact`). The commit is `unknown` and the ref `local` because the replay runs outside a repository and outside Actions; in your clone the script prints your HEAD.

<!-- snippet: ch20a/lab-26-7-artifact/01-deploy -->
```text
$ mkdir dist
$ touch dist/inventory_api-0.1.0.tar.gz dist/inventory_api-0.1.0-py3-none-any.whl
$ bash scripts/deploy.sh staging dist
Simulated deployment of inventory-api
  environment : staging
  target      : https://staging.inventory.example.com
  commit      : unknown
  ref         : local
  artifacts   :
    - inventory_api-0.1.0-py3-none-any.whl
    - inventory_api-0.1.0.tar.gz
Nothing was changed anywhere. A real script would now upload the artifacts to https://staging.inventory.example.com.
[exit status: 0]
```
<!-- /snippet -->

On GitHub, from the documentation: "Build and upload" runs first; "Simulated deployment" starts when it has succeeded. The step "Show what arrived" prints a numeric artifact ID, a SHA-256 digest, and the two file names. The deploy step prints the same block as above with `GITHUB_SHA` as the commit and `refs/heads/main` as the ref. `gh run download` leaves the sdist and the wheel in the directory you named. The artifact expires after 7 days ([upload-artifact README](https://github.com/actions/upload-artifact/blob/v7.0.1/README.md)).

### What happened internally

The upload step zipped `dist/`, sent it to GitHub's artifact storage, and returned an ID and a digest. The first runner was then discarded. The second runner started empty, checked out the repository, asked for the artifact by name, verified the digest, and unpacked it into `dist/`. The two jobs never shared a disk. The files deployed are byte for byte the files built.

### Checkpoint

- The run shows two jobs in sequence.
- The files in `/tmp/inventory-api-dist` have the names the build job listed.

### Failure scenario

Remove the dependency between the jobs and run the branch's version by hand.

```bash
git switch -c break/no-needs main
# edit .github/workflows/07-artifact.yml, job deploy-simulated: delete the line "needs: build"
git commit -am "Remove needs on purpose"
git push -u origin break/no-needs
gh workflow run 07-artifact.yml --ref break/no-needs
gh run list --workflow 07-artifact.yml --limit 3
gh run view RUN-ID --verbose
gh run view RUN-ID --log-failed
```

Predict first. Without `needs`, the two jobs are independent and start together (section 20A.9), so the download step asks for an artifact that the other job has not uploaded yet, and the documented behavior of a download for a name that does not exist is a failed step. One detail the author could not test: the step "Show what arrived" still reads `needs.build.outputs`, and the `needs` context "contains the outputs of all jobs that are defined as a dependency of the current job" ([contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#needs-context)). Either the values are empty strings, or GitHub rejects the file before any job starts. Record which you see; if no run appears in the list, `gh workflow view 07-artifact.yml` and the Actions tab show the validation message.

The script's own two failure modes, for comparison:

<!-- snippet: ch20a/lab-26-7-artifact/02-failures -->
```text
# The artifact did not arrive: the directory is empty.
$ mkdir empty
$ bash scripts/deploy.sh staging empty
Simulated deployment of inventory-api
  environment : staging
  target      : https://staging.inventory.example.com
  commit      : unknown
  ref         : local
deploy.sh: no build outputs in 'empty'; nothing to deploy
[exit status: 1]
# A misspelled environment name:
$ bash scripts/deploy.sh stagging dist
deploy.sh: unknown environment 'stagging' (expected staging or production)
[exit status: 2]
```
<!-- /snippet -->

### Recovery

```bash
git revert --no-edit HEAD
git push
gh workflow run 07-artifact.yml --ref break/no-needs
gh run watch
```

### Verification

```bash
gh run view RUN-ID --verbose      # two jobs, in sequence, both green
git push origin --delete break/no-needs
git switch main && git branch -D break/no-needs
rm -r /tmp/dist-standin /tmp/inventory-api-dist
```

### Questions

1. Without `needs`, why did the download fail and not wait for the artifact?
2. The deploy job checks out the repository again. What exactly does it need from the checkout, and what from the artifact? Why not rebuild in the deploy job?
3. Could a cache have carried `dist/` to the second job? Give two reasons it is the wrong tool.
4. `if-no-files-found: error` is set on the upload. What would the run look like with the default `warn` if `uv build` produced nothing?
5. A release has to stay downloadable for two years. Is a workflow artifact the place? What is?

## Lab 26.8: Workflow 10, matrix testing

### Objective

Count the jobs of a matrix before it runs, see one combination fail while the others finish, and use one aggregate job as the result of the whole matrix.

### Prerequisites

Chapter 20A, sections 20A.9, 20A.10 and the walk-through of workflow 10. Lab 26.2 (`uv.lock`).

### Setup

```bash
cd ~/git-mastery/inventory-api
git switch main && git pull --ff-only
```

### Commands

```bash
# 1. Predict on paper: the list of jobs (operating system, Python version, experimental or not),
#    and the name each will show. Then add the workflow (standard cycle, FILE=10-matrix.yml,
#    BRANCH=ci/matrix) and compare.
gh pr checks --watch
gh run view RUN-ID --verbose

# 2. Which job is allowed to fail? Find the key in the file.
grep -n "experimental\|continue-on-error\|fail-fast" .github/workflows/10-matrix.yml

gh pr merge --squash --delete-branch
git switch main && git pull --ff-only
```

### Expected output

This lab has no local replay: a matrix is expanded by GitHub, and reimplementing its rules here would only test the reimplementation. From the documentation ([matrix](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstrategymatrix)) and section 20A.10, expect seven checks:

| Check name | Runner | Python | May fail |
|---|---|---|---|
| py3.11 on ubuntu-24.04 | ubuntu-24.04 | 3.11 | no |
| py3.12 on ubuntu-24.04 | ubuntu-24.04 | 3.12 | no |
| py3.13 on ubuntu-24.04 | ubuntu-24.04 | 3.13 | no |
| py3.12 on macos-15 | macos-15 | 3.12 | no |
| py3.13 on macos-15 | macos-15 | 3.13 | no |
| py3.14 on ubuntu-24.04 | ubuntu-24.04 | 3.14 | yes |
| All matrix tests | ubuntu-24.04 | none | no |

The sample code uses nothing newer than Python 3.11, so all six test jobs should pass. If the 3.14 job fails because a dependency has no build for it, the run stays green: that is what `continue-on-error` is for.

### What happened internally

Before any runner was assigned, GitHub expanded `strategy.matrix` into six job instances, each with its own `matrix` context, and evaluated `runs-on`, `name` and `continue-on-error` per instance. Six machines ran the same four steps. The job `all-tests` waited for all six through `needs: test`, ran because of `if: ${{ always() }}`, and compared `needs.test.result` with `success`.

### Checkpoint

- Seven checks on the pull request, with the names above.
- You can explain why there is no "py3.11 on macos-15".

### Failure scenario

Syntax that exists only from Python 3.12 on.

```bash
git switch -c break/py312-syntax main
printf '\ntype Quantity = int\n' >> src/inventory_api/stock.py
python3 -c "import ast,sys; ast.parse(open('src/inventory_api/stock.py').read(), feature_version=(3, 11))"; echo "exit status: $?"
git commit -am "Use 3.12-only syntax on purpose"
git push -u origin break/py312-syntax
gh pr create --fill --base main
gh pr checks --watch
gh run view RUN-ID --verbose
```

Locally, the `ast.parse` line ends with `SyntaxError: Type statement is only supported in Python 3.12 and greater` (Python 3.14.6 on the author's machine). On GitHub, expect "py3.11 on ubuntu-24.04" to fail with a `SyntaxError` during test collection, the five other test jobs to run to completion and pass because `fail-fast` is `false`, and "All matrix tests" to fail. The checks of workflows 1, 2 and 4 pass or fail according to the Python each of them uses; explain each one you see.

### Recovery

```bash
git revert --no-edit HEAD
git push
gh pr checks --watch
```

### Verification

```bash
gh pr checks
gh pr close --delete-branch
git switch main
```

### Questions

1. Show the arithmetic from the matrix definition to six jobs. Why did the `include` entry create a new job and not modify existing ones?
2. With `fail-fast: true`, what would the failure scenario have looked like, and what information would you have lost?
3. Why is "All matrix tests" the check to require in a ruleset, and why does it need `if: ${{ always() }}`? What would happen to a required check if the job were skipped?
4. The `pyproject.toml` says `requires-python = ">=3.11"`. Which part of the failure scenario shows that this line is a promise that only CI can keep?
5. Each matrix job uploads nothing. If each uploaded a test report under the name `report`, what would happen, and how would you name the artifacts?

## After the module

You now have eight workflow files in `inventory-api` and a run history for each. Keep the repository: [Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md) adds deployment and reusable workflows to it, and [Chapter 21A](../textbook/ch21a-actions-security.md) audits it. To stop spending runner time on a workflow you are not studying, `gh workflow disable FILE` switches it off and `gh workflow enable FILE` back on.
