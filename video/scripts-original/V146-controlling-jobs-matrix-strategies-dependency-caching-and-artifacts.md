# V146: Controlling jobs, matrix strategies, dependency caching, and artifacts

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 26
- **Planned minutes.** 26
- **Prerequisites.** V145
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), sections 20A.9 to 20A.12
- **Demo scripts.** `labs/ch20a/lab-26-4-cache-key.sh`, `labs/ch20a/lab-26-7-artifact.sh`, then a screen walkthrough of Lab 26.8 in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md) with [`workflows/10-matrix.yml`](../../workflows/10-matrix.yml)

## HOOK

**[ON SCREEN]** Two lines. "We upgraded the dependency two days ago. CI is still installing the old version." "And what we deployed is not what we tested."

The first is a cache doing exactly what a cache is defined to do. The second is a team that rebuilt in the deploy job what it had already built and tested in another job, and got a different result because the dependencies resolved again.

Both come from using a cache or an artifact without knowing what each one promises. A cache promises nothing: it may be absent. An artifact promises that the bytes you download are the bytes that were uploaded. This video gives you both definitions, and the rules for ordering and multiplying jobs that you need before either matters.

## INTRODUCTION

You can now read a trigger, an expression and a shell invocation, and you know what the checkout leaves on the runner. This video is about the structure above the steps: how jobs relate to each other.

Four topics, in the order of sections 20A.9 to 20A.12. Controlling jobs with `needs`, `if`, `timeout-minutes` and `continue-on-error`, including two rules about skipping that decide whether a pull request can merge. Matrix strategies, and how to count the jobs of a matrix. Dependency caching: keys, restore order, scope, eviction and trust. And artifacts: what crosses from one job to the next as files.

The local demonstration computes a cache key and consumes a simulated artifact. The matrix is yours to run in Lab 26.8.

## LEARNING OBJECTIVES

After this video you can:

- order jobs with `needs` and predict what `if`, `timeout-minutes` and `continue-on-error` do to the run's result;
- count the jobs of a matrix with `include` and `exclude`;
- design a cache key and say what happens on a miss and on a stale hit;
- distinguish a cache from an artifact by purpose, scope, lifetime and trust;
- carry one build from a build job to a later job.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**Controlling jobs. In one sentence:** `needs` orders jobs and carries their results, `if` decides whether a job or step runs, `timeout-minutes` bounds how long it may run, and `continue-on-error` lets a failure pass without failing what contains it.

`needs`, at job level: the job waits for the listed jobs. If one of them fails or is skipped, this job is skipped, unless its `if` says otherwise. Without `needs`, jobs run in parallel.

`if`, at job or step level: the job or step runs when the expression is truthy. An `if` without a status function behaves as if `success()` and a logical "and" were in front of it. So the default is `success()`.

`timeout-minutes`: the job or step is cancelled after that many minutes. The default for a job is 360.

`continue-on-error`: a failure does not fail the job, at step level, or the run, at job level.

The status functions change the implicit `success()`. `failure()` is true when an earlier step or needed job failed. `always()` is true even when the run was cancelled. `cancelled()` is true on cancellation. The expressions page advises against `always()` for anything that could fail critically and recommends `!cancelled()` for "run whether or not the earlier steps passed". You saw that form in the lint workflow.

`continue-on-error` at step level splits a step's result in two. The `outcome` is the result before the setting is applied; the `conclusion` is the result after. A failed step with the setting has outcome `failure` and conclusion `success`.

Now the two rules about skipping. They decide whether a pull request can merge, and they point in opposite directions.

**[ON SCREEN]** The two rules, side by side.

A job skipped by its `if` reports success for its check. So a required check is satisfied.

A workflow that never starts, because of a path or branch filter or a skip instruction, reports nothing. So a required check stays pending.

The textbook's summary: they make `if` on a job a way to bypass a required check by accident, and `paths` on a workflow a way to block every unrelated pull request.

And one instruction for production: set `timeout-minutes` on every job. The default of 360 minutes is also the hard limit for a GitHub-hosted job, so a test that hangs on a network call bills six hours unless you say otherwise. The course workflows use 5 to 20 minutes.

**Matrix. In one sentence:** a matrix turns one job definition into one job per combination of the values you list, each with its own runner and its own `matrix` context.

`strategy.matrix` maps variable names to lists, and the jobs are the Cartesian product. Then:

`exclude` removes combinations; a partial match is enough.

`include` is processed after `exclude`. An entry is added to every existing combination it can extend without overwriting an original matrix value. If it would overwrite one, it becomes a new combination of its own.

`fail-fast` defaults to true: when one matrix job fails, the in-progress and queued ones are cancelled. `max-parallel` caps how many run at once.

A run may generate at most 256 matrix jobs.

A job-level `if` is evaluated before the matrix is expanded, so it cannot read `matrix`.

And outputs of matrix jobs are merged into one set, and the last writer wins, in no guaranteed order.

**[ON SCREEN]** Callout: Unverified. The names of the checks that matrix jobs report are not specified on an official page that the course's research could find. Workflow 10 therefore sets the job name explicitly from the matrix values, and adds a final job with a fixed name to serve as the required check.

**Caching. In one sentence:** a cache stores a directory under a key so that a later run with the same key can restore it and skip the download; it is an optimization that may be absent, never a place to keep something you need.

The key: at most 512 characters, usually built from the operating system and `hashFiles` of a lock file. An existing key is never overwritten. The documentation: "You cannot change the contents of an existing cache."

The restore order: the exact key; then entries whose key starts with the key; then each `restore-keys` prefix in order, the most recently created match winning.

Saving: on a miss, the cache is saved at the end of the job, and only if the job completes successfully.

The `cache-hit` output: true only for an exact match on the primary key. False when a restore key matched, or nothing was restored.

Scope: a run can restore caches created on its own branch or on the default branch. A pull request run can also restore from its base branch. Sibling branches cannot read each other's caches. A cache saved by a pull request run belongs to the merge ref and is restorable only by re-runs of that pull request.

Eviction: entries not accessed for 7 days are removed. A repository gets 10 GB without charge; above the limit the least recently used entries are deleted. Administrators can raise the limit, billed, since 20 November 2025.

Trust: anyone who can open a pull request can read caches of the base branch, and cache contents are not signed. Since 26 June 2026, events that people without write access can cause get a read-only token for the default branch's caches. And since 10 September 2026 the `cache-mode` key states the access explicitly, with the values `read`, `write`, `write-only` and `none`. Cache poisoning is a topic of Part 7.

Most projects never write a cache block, because the setup actions contain it. `actions/setup-java` with `cache: maven` stores the Maven repository under a key that hashes the POM files by default. `astral-sh/setup-uv` has `enable-cache` with the default `auto`: enabled on GitHub-hosted runners except for release, tag push, `pull_request_target` and `workflow_run` events.

**Artifacts. In one sentence:** an artifact is a set of files that a job uploads to GitHub, where it is stored with the run, can be downloaded by later jobs or by people, and expires after a retention period.

**[ON SCREEN]** The property table of section 20A.12, from the READMEs of the upload action at version 7.0.1 and the download action at version 8.0.1.

Immutability: an artifact cannot be changed after upload. A second upload with the same name in one run fails unless `overwrite` is true.

Availability: downloadable by a later job of the same run as soon as the upload step ends.

Retention: 90 days by default; `retention-days` from 1 to 90, never above the repository or organization setting. Since 1 October 2026 the same setting also deletes checks, workflow runs and commit statuses.

Limits: 500 artifacts per job. Hidden files are excluded unless you include them explicitly.

Permissions: zipped uploads do not keep file permissions. If the executable bit matters, tar the files first.

Outputs: an artifact ID, a URL, and a SHA-256 digest.

Download: by name into a path. Version 8 fails on a digest mismatch by default.

## MENTAL MODEL

**Analogy,** from the textbook. A cache is the shared fridge at work with labelled boxes. If a box with your label is there, lunch is quick. If it was cleared out, you cook again. You do not keep your passport in it, and you do not eat from a box whose label you did not write.

The textbook says where it holds and where it breaks. It holds for eviction and for trust. It breaks on mutability, because a cache entry can never be changed once saved. The fridge box can be refilled. A cache key cannot.

That immutability is the mechanism behind the first line of the hook. If the key does not change when the dependencies change, the old box keeps being found.

Then the documentation's rule for choosing between the two: a cache for files that are reused between runs and can be recreated, such as dependencies. An artifact for files a job produced that must be passed to another job or kept after the run, such as build outputs and test reports.

And the reason behind that rule, which the textbook sets in bold: the files that were tested are the files that are deployed. A rebuild in a second job resolves dependencies again, possibly to different versions.

So when you see data moving between jobs, ask: is this something I could lose without consequence? Then it is a cache. Is this the thing itself? Then it is an artifact.

## DIAGRAM

**[DIAGRAM]** The matrix of workflow 10 as a grid. Draw the two-by-three grid from the two lists first and count: six. Then cross out the excluded cell: five. Then add the included entry and ask: does it extend an existing cell, or become a new one?

```text
  matrix:  os: [ubuntu-24.04, macos-15]   python: ["3.11", "3.12", "3.13"]   experimental: [false]

                    3.11          3.12          3.13          3.14
                 +-----------+-------------+-------------+................+
  ubuntu-24.04   |   job 1   |    job 2    |    job 3    :  job 6         :   include:
                 |           |             |             :  experimental  :   would overwrite python
                 +-----------+-------------+-------------+................+   and experimental, so it
  macos-15       |  XXXXXXX  |    job 4    |    job 5    |                    becomes a NEW combination
                 |  exclude  |             |             |
                 +-----------+-------------+-------------+

  2 x 3 = 6     minus 1 excluded = 5     plus 1 included = 6 jobs, one of them experimental
```

**[DIAGRAM]** Then the last job of the workflow, outside the grid: "All matrix tests", with `needs: test` and `if: always()`. That one fixed name is what a ruleset requires.

**[ON SCREEN]** The root-cause box of section 20A.11, one line at a time. Observed behavior: a dependency was upgraded, CI still installs the old version from cache. Mechanism: the key had no lock-file hash, or a broad restore key matched an old entry, which was then extended and saved under the new key. Root cause: caches are immutable per key and restore keys match by prefix. Correct fix: put `hashFiles` of the lock file in the key; install from the lock file, with `uv sync --locked`, so that a stale cache cannot change what is installed. Prevention: a manual prefix, such as `v2-`, to invalidate everything at once.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch20a/lab-26-4-cache-key`. It computes locally the kind of value a cache key is built from. `hashFiles` is described in the documentation as a SHA-256 per matched file and then one over those; the replay uses `shasum` on the lock file to show the principle, which is that the key changes exactly when the file changes.

**Step 1: a key from the lock file.**

```bash
cat uv.lock
shasum -a 256 uv.lock | cut -c1-16
```

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

A small lock file with one package at one version, and the first sixteen characters of its hash.

**Step 2: two commits.**

```bash
git commit --quiet -am "Document the linter"
shasum -a 256 uv.lock | cut -c1-16
git commit --quiet -am "Update pytest in the lock file"
shasum -a 256 uv.lock | cut -c1-16
```

`git commit` adds an object and moves the branch. The first commit changes only the README. The second changes the version in the lock file. **[PAUSE]** After which commit does the hash change, and what does that mean for the cache on the next run?

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

After the README commit: the same hash. Same key, cache hit. After the dependency update: a new hash. New key, cache miss, the dependencies are downloaded, and a new cache is saved after the job, if the job succeeds.

Now turn it around. If the key had been built without the lock file, both commits would have hit the old entry. That is the stale hit of the root-cause box.

**Step 3: consuming an artifact.** Replay `labs/run ch20a/lab-26-7-artifact`. The sample project has a deployment script that simulates a deployment and changes nothing anywhere.

```bash
mkdir dist
touch dist/inventory_api-0.1.0.tar.gz dist/inventory_api-0.1.0-py3-none-any.whl
bash scripts/deploy.sh staging dist
```

The two empty files stand in for the build outputs that a download step would place in `dist`.

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

The script names the environment, the target, the commit and ref, which are "unknown" and "local" outside a runner, and the two files it would deploy. Exit status 0.

**Step 4: when the artifact did not arrive.**

```bash
mkdir empty
bash scripts/deploy.sh staging empty
bash scripts/deploy.sh stagging dist
```

**[PAUSE]** An empty directory, then a misspelled environment name. What should a deployment script do in each case, and what would a careless one do?

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

Exit status 1 for "no build outputs", exit status 2 for the unknown environment. The script refuses. A careless one would report success on an empty directory, and the run would be green with nothing deployed. Whatever consumes an artifact must check that it arrived.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough, with `workflows/10-matrix.yml` on screen first.

Read the `test` job. The name is built from the matrix values. `runs-on` takes the operating system from the matrix. `continue-on-error` takes its value from `matrix.experimental`, so it is true only for one job. `fail-fast` is false, so one failing combination does not cancel the others.

Then the `all-tests` job. `if: always()` makes it run even when a matrix job failed. Why is that necessary? Because a job that needs a failed job is skipped, and a skipped job reports success, which would satisfy the required check. With `always()` the job runs, and then fails unless the result of `test` is `success`.

**[ON SCREEN]** Callout: Unverified. How the result of a needed matrix job is aggregated when its only failure had `continue-on-error` is not spelled out on the pages read for the chapter. The expectation, from the definition of `continue-on-error`, is `success`. Lab 26.8 has you observe it.

Now Lab 26.8 on your practice repository, in your normal shell. The interface changes; the lab text and the linked documentation are the reference, and no GitHub output was captured by the authors. Before you open the run, write the list of jobs on paper: operating system, Python version, experimental or not, and the name each will show. Then open the pull request's checks and the run, and count. Find the aggregate job by its fixed name.

## COMMON MISTAKES

1. **A cache key without the lock file's hash, or with a broad restore key.** Root cause: caches are immutable per key and restore keys match by prefix, so an old entry keeps being restored.
2. **Rebuilding in the deploy job.** Root cause: a second build resolves dependencies again, so the deployed files are not the tested files; pass the build as an artifact.
3. **An `if` on a job that is a required check.** Root cause: a job skipped by its `if` reports success for its check.
4. **No `timeout-minutes`.** Root cause: the default of 360 minutes is also the hard limit for a GitHub-hosted job, so a hanging test bills six hours.
5. **Requiring the individual matrix jobs in a ruleset.** Root cause: their set and names change when the matrix changes; require one aggregate job with a fixed name.

## PRODUCTION EXAMPLE

The textbook's instruction for an ML team: cache package downloads and small test models, never multi-gigabyte checkpoints.

Here is how that goes wrong. A team that evaluates language models caches a model checkpoint of several gigabytes "to make the evaluation job faster". It works. A week later every other job in the repository is slow. The 10 GB per repository is shared by all branches, the checkpoint filled most of it, and above the limit the least recently used entries are deleted. The model cache evicted the dependency caches that made CI fast.

The decision is the one from the mental model. Can the checkpoint be lost without consequence? It can be downloaded again, so it is cache material in principle, but its size makes it the wrong tenant for a shared 10 GB. And for upload of reports from that evaluation, the textbook adds two rules: upload test reports with `if: failure()` and a short retention, and never upload a directory that may contain credential files or a `.git` folder with persisted credentials, because an artifact is a copy of those files that outlives the job.

## PRACTICE EXERCISE

Do Lab 26.4, "Workflow 4, Python tests with uv and caching", in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md), in your normal shell.

Before each run, predict whether the cache will be hit or missed, and say which file decides. After a change to the lock file, predict again.

The challenge is Exercise 26.6, "Caches and artifacts", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q281: "What is the difference between a cache and an artifact in purpose, scope, lifetime and trust? Which one may a release job consume?"

A strong answer takes the four words in the question as four rows and fills both columns for each, with the facts from this video. For trust, it says who can read and who can write each. Then it answers the last sentence with a reason, not only a choice. The follow-up is the first line of the hook: a lock file upgraded and CI still installing the old version. Explain the mechanism from immutability and prefix matching, and give the fix and the prevention.

## RECAP

You should now be able to say:

- `needs` orders jobs; a job that needs a failed or skipped job is skipped unless its own `if` says otherwise.
- A job skipped by its `if` reports success; a workflow that never starts reports nothing.
- A matrix is the Cartesian product, minus `exclude`, then `include`, which extends a combination or adds a new one.
- A cache is an immutable, evictable speed-up keyed by content; a stale key gives stale dependencies.
- An artifact is the output of a job, immutable and kept for a retention period: build once, pass the artifact, deploy what was tested.

## HOMEWORK

Read sections 20A.9 to 20A.12 of [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md). Do Lab 26.8, "Workflow 10, matrix testing", in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md).
