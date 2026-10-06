# Lab 28.1: diagnoses of the six broken workflows

> Read this after you have written your own six diagnoses. The files are in `workflows/broken/`. Each fix below was assembled from documented syntax and parse-checked; none was executed on GitHub by the author. Reproduce and confirm in Part B of [Lab 28.1](../lab-manual/m28-runners-debugging-ci.md). Background: [Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md), sections 20B.11 to 20B.13.

| # | File | Root cause in one line | Layer | Step of the investigation order that finds it |
|---|---|---|---|---|
| 1 | `01-version-stamp.yml` | shallow, tagless checkout; `git describe` has nothing to describe | GitHub Actions default, Git mechanism | 2, event and checkout |
| 2 | `02-source-tests.yml` | a path filter keeps the workflow from starting, so the required check never reports | GitHub Actions and GitHub (rulesets) | 1, workflow |
| 3 | `03-pr-summary-comment.yml` | the job token has no permission to write to pull requests | GitHub Actions | 3, permissions |
| 4 | `04-integration-tests.yml` | secrets are not passed to runs triggered from a fork | GitHub Actions | 7, secrets |
| 5 | `05-branch-ci.yml` | one concurrency group for all branches, with `cancel-in-progress: true` | GitHub Actions | 12, concurrency |
| 6 | `06-cached-environment.yml` | a cache key that never changes, plus an install that is skipped on a hit | GitHub Actions | 11, cache |

## 1. `01-version-stamp.yml`: the history is one commit long

```text
Observed behavior : "Derive the version from the latest tag" exits with status 128.
Git state         : The job's repository is shallow: one commit, no refs under refs/tags.
Mechanism         : git describe walks from HEAD through parents to a tagged commit. There
                    are no parents and no tags.
Root cause        : The checkout step uses the defaults fetch-depth: 1 and fetch-tags: false.
Why it does this  : "Only a single commit is fetched by default"; most jobs need no more.
Correct fix       : fetch-depth: 0 on this job's checkout step.
Prevention        : Derive the version in one place; fail loudly when no tag is found.
```

The fix:

```yaml
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
          fetch-depth: 0
```

The [checkout README](https://github.com/actions/checkout/blob/v7.0.1/README.md) says: "Set `fetch-depth: 0` to fetch all history for all branches and tags." The transcript `01-shallow` of the lab is the local proof; section 20B.12 shows that fetching the tags alone, still at depth 1, changes the message to "No tags can describe" and fixes nothing.

Wrong repairs: `git describe --always` (stamps a commit ID where a version belongs); `|| echo 0.0.0` (ships a false version); `fetch-tags: true` alone (tags without the path to them). Cost of the right fix: a full clone, which on a large repository is slow; then use a partial clone filter or compute the version in a dedicated job. Workflow 3 of the course, `03-build.yml`, is the working counterpart.

## 2. `02-source-tests.yml`: a check that is required but never reports

```text
Observed behavior : A documentation-only pull request waits for "unit-tests" forever.
Git state         : git diff --name-only main...<branch> lists only files outside the filter.
Mechanism         : With on.pull_request.paths, the workflow starts only when a changed file
                    matches. A workflow that does not start creates no check.
Root cause        : A ruleset requires a check from a workflow that can be skipped.
Why GitHub does it: A required check must pass on the latest commit; "no result" is not a pass.
                    A job skipped by its own if does report (as skipped, which passes).
Correct fix       : Remove the paths filter from the workflow that provides the required check.
Prevention        : Require one aggregate job; put conditions on jobs, not on the workflow.
```

The documentation says it directly: a workflow skipped by path filtering, branch filtering or a commit message leaves its checks "Pending", and the advice is to "avoid requiring workflows that can be skipped" ([skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs), [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks)).

The smallest fix:

```yaml
on:
  pull_request:
    branches: [main]
```

That spends runner minutes on documentation pull requests. To keep the saving, start the workflow always, decide inside it whether the test job is needed, guard that job with `if`, and require an aggregate job as in section 20B.13. A job skipped by `if` counts as passing; a workflow that never started does not.

Wrong repairs: removing the check from the ruleset (now code changes merge untested too); asking an administrator to bypass each documentation pull request; running the workflow manually on the branch (a `workflow_dispatch` run does not satisfy a pull request's required check).

## 3. `03-pr-summary-comment.yml`: the token may read contents and nothing else

```text
Observed behavior : The tests pass; the comment step is refused with HTTP 403.
Git state         : Irrelevant.
Mechanism         : The workflow sets permissions: contents: read. "If you specify the access
                    for any of these permissions, all of those that are not specified are set
                    to none." The token therefore has no access to pull requests.
Root cause        : The job writes to a pull request without the pull-requests: write scope.
Why GitHub does it: Least privilege: a job gets only what the file grants.
Correct fix       : A job-level permissions block that adds pull-requests: write.
Prevention        : For every API call a job makes, name the scope in a comment beside it.
```

The fix, at job level so that no other job inherits it:

```yaml
jobs:
  test-and-comment:
    name: Test and comment
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    permissions:
      contents: read
      pull-requests: write
```

Source for the rule: [workflow syntax, permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions).

> **Unverified.** The exact text of the refusal, and whether commenting through `gh pr comment` is satisfied by `pull-requests: write` alone or also needs `issues: write` (a pull request comment is created through the issue-comment API: "every pull request is an issue"), were not confirmed from a documentation page for this book. Start with `pull-requests: write`; if the 403 remains in Part B, add `issues: write` and note which one was needed.

Two more things to say in a review. The fix does not help pull requests from forks: their token is read-only whatever the file asks for, so the comment step should be skipped for them or moved to a design from Chapter 21A. And the wrong repair is `permissions: write-all`, which gives a job that runs pull request code every scope there is.

## 4. `04-integration-tests.yml`: the secret is withheld from fork runs

```text
Observed behavior : Green for branches of the repository, red for a pull request from a fork;
                    the step reports that SUPPLIER_API_KEY is empty.
Git state         : Irrelevant. The head commit lives in another repository of the fork network.
Mechanism         : "With the exception of GITHUB_TOKEN, secrets are not passed to the runner
                    when a workflow is triggered from a forked repository." An unset secret
                    evaluates to an empty string, without an error.
Root cause        : A check that needs a secret runs in a job that outsiders can trigger.
Why GitHub does it: A fork's author controls the code that runs; a secret given to that job
                    is a secret given to that author.
Correct fix       : Make the job fork-safe: skip the secret-dependent step when the secret is
                    absent, and run the integration check where the secret is safe.
Prevention        : Classify every job: "runs untrusted code" or "holds secrets". Never both.
```

Source: [using secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets). The same applies to pull requests opened by Dependabot.

A fork-safe version. The `secrets` context is not available in `if`, so the secret goes into a job-level environment variable and the step tests that, which is the approach the same page describes:

```yaml
jobs:
  integration:
    name: Integration
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    env:
      SUPPLIER_API_KEY: ${{ secrets.SUPPLIER_API_KEY }}
    steps:
      # checkout, setup-uv, uv sync --locked, uv run pytest as before
      - name: Check the supplier sandbox
        if: ${{ env.SUPPLIER_API_KEY != '' }}
        shell: bash
        run: echo "would call the supplier sandbox with a key of ${#SUPPLIER_API_KEY} characters"
```

Be honest about what this does: for fork pull requests the integration check does not run. Say so in the job summary, and run it after the merge, in a workflow triggered by `push` to `main`, or on demand by a maintainer. A job-level `env` also exposes the value to every step of the job, including the test run; in a real repository give the secret-dependent check its own job.

Wrong repair: `on: pull_request_target`, "so that the secret is available". That runs with the base repository's secrets and a write-capable token while the job checks out and executes the contributor's code. It is the vulnerability class Chapter 21A calls a pwn request, and `actions/checkout` v7 refuses that checkout by default.

## 5. `05-branch-ci.yml`: every branch shares one track

```text
Observed behavior : Runs end as "cancelled" when somebody pushes to another branch.
Git state         : Several branches; each push moves a different ref.
Mechanism         : All runs are in the concurrency group "ci". With cancel-in-progress: true
                    a newly queued run cancels the run in progress in the same group.
Root cause        : The group name does not contain the ref.
Why GitHub does it: A group is only a string; equal strings mean "the same thing, one at a time".
Correct fix       : group: ${{ github.workflow }}-${{ github.ref }}
Prevention        : Copy the group from a reviewed pattern; include the workflow and the ref.
```

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

Source: [workflow syntax, concurrency](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency). `github.ref` separates the branches, which is the intended behavior of the header comment: only an older run of the same branch stops. `github.workflow` keeps a second workflow that uses the same pattern from sharing the group; group names are case-insensitive. The transcript `03-refs` lists the three refs that the fixed expression tells apart.

Wrong repairs: deleting the `concurrency` block (every superseded run now burns minutes to the end); `cancel-in-progress: false` with the shared group (branches no longer cancel each other but wait for each other, and pending runs are still replaced). One refinement for later: on `main` you may want every commit tested to the end; `cancel-in-progress` accepts an expression such as `${{ github.ref != 'refs/heads/main' }}`.

## 6. `06-cached-environment.yml`: a key that cannot notice a change

```text
Observed behavior : After uv.lock changed, the new package is missing in the job; the install
                    step is skipped.
Git state         : uv.lock differs between main and the pull request (two blob IDs).
Mechanism         : The key is "<os>-inventory-api-venv" for every commit. The first run saved
                    .venv under it. Every later run gets an exact hit, cache-hit is 'true', the
                    install step's condition is false, and uv run --no-sync uses the old .venv.
                    A cache is not rewritten on a hit: a key is immutable.
Root cause        : The key does not depend on the file that defines the cached content.
Why GitHub does it: A cache is addressed by its key; equal key means "already have it".
Correct fix       : Put hashFiles('uv.lock') into the key.
Prevention        : A cache key must change when its content should; never skip the step that
                    establishes correctness because a cache was restored.
```

```yaml
      - name: Restore the virtual environment
        id: venv
        uses: actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0
        with:
          path: .venv
          key: ${{ runner.os }}-inventory-api-venv-${{ hashFiles('uv.lock') }}
```

Sources: the [cache README](https://github.com/actions/cache/blob/v6.1.0/README.md) ("if the provided `key` matches an existing cache, a new cache is not created") and the [dependency caching reference](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching). The pull request run could restore the cache that `main` created because a pull request may restore caches of its base branch. In the transcript `04-cache-key`, the two blob IDs of `uv.lock` differ; a key that contains a hash of the file differs with them.

The better design removes the hand-made cache: let `astral-sh/setup-uv` cache uv's download cache (its `enable-cache` input; the cache key follows the files matched by its `cache-dependency-glob` input) and run `uv sync --locked` in every run, followed by plain `uv run pytest`. Then the lock file is checked every time and the cache only saves download time. That is workflow 4 of the course.

Wrong repairs: `restore-keys` with a broad prefix (restores the most recent stale environment even more reliably); `gh cache delete --all` (works once, until the next dependency change); removing `--no-sync` only (hides the stale cache behind a re-sync, and the cache never gets updated).

## What the six have in common

None is a syntax error: every file parses, and a linter that checks structure accepts all six. Each is a documented default or rule meeting an assumption nobody wrote down. That is why the investigation order starts with "which workflow, which event, which commit, which token" and reaches the log only at step 9.
