# GitHub Actions cheat sheet

> **Baseline.** GitHub Actions facts as of 1 October 2026; GitHub CLI 2.88.1 (flags checked with `gh <command> --help`); Git 2.55.0. Nothing here was run against GitHub: behavior is described from the documentation cited in Chapters 20A, 20B and 21A. 🟢 SAFE reads · 🟡 CAUTION changes something recoverable · 🔴 DANGEROUS can destroy or expose. The numbers in brackets are textbook sections.

This sheet is the one-look version. The working documents are the [GitHub Actions guide](../guides/github-actions-guide.md) (the twelve workflows, the authoring checklist, the full event and context tables, limits and cost) and the [action pins](../workflows/ACTION_PINS.md). Hardening is on the [security cheat sheet](security-cheat-sheet.md).

## 1. The model in six words

| Word | What it is | Section |
|---|---|---|
| Workflow | A YAML file under `.github/workflows/`: "when this event happens, run these jobs". It is data, not a script: a YAML parser reads it before GitHub Actions interprets any key | 20A.2, 20A.3 |
| Event | What starts a run; it fixes which commit and ref the run is about and which copy of the workflow file is used | 20A.4 |
| Job | A list of steps on one fresh runner; jobs run in parallel unless `needs` orders them | 20A.2 |
| Step | A shell command (`run`) or an action (`uses`); every `run` step is a new shell process | 20A.7 |
| Action | Someone else's code that runs inside your job; only a full commit ID guarantees it is the code you reviewed | 21A.7 |
| Runner | The machine: GitHub-hosted (fresh, then destroyed) or self-hosted (yours, keeps state unless ephemeral) | 20B.8, 20B.9 |

## 2. Workflow keys

| Key | Purpose | Minimal example | Common mistake | Section |
|---|---|---|---|---|
| `on` | The events, with `branches`, `tags` and `paths` filters | `on: { pull_request: {}, push: { branches: [main] } }` | A `paths` or `branches` filter on a workflow whose job is a required check: a skipped workflow never reports, and the pull request waits forever | 20A.4, 20B.13 |
| `permissions` | What the job token may do; naming any scope sets all unnamed scopes to `none` | `permissions: { contents: read }` | Write scopes at the top level instead of on the one job that needs them; "Resource not accessible by integration" after adding the key means a scope is missing on that job | 21A.3 |
| `concurrency` | At most one run or job per group name at a time | `group: ${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true` for CI | A group name without workflow and ref: CI runs of different branches cancel each other. For deployments use a fixed group with `cancel-in-progress: false`, and `queue: max` if every run must execute | 20B.5 |
| `jobs.<id>.runs-on` | The runner label | `runs-on: ubuntu-24.04` | A `-latest` label: every one of them moved in 2026 | 20B.8 |
| `needs` | Orders jobs and carries their results and outputs | `needs: build` | Reading an output the upstream job never declared under `outputs:` | 20A.9 |
| `if` | Whether a job or step runs | `if: ${{ !cancelled() }}` | An `if` that is always true because only part of the condition is inside `${{ }}`: wrap the whole expression | 20A.9 |
| `timeout-minutes` | Upper bound for a job | `timeout-minutes: 15` | Leaving the default of 360 | 20A.9 |
| `continue-on-error` | Lets a failure pass without failing what contains it | on an experimental matrix leg | Using it to hide a failing required step | 20A.9 |
| `strategy.matrix` | One job per combination of values; `include`, `exclude`, `fail-fast` | `matrix: { python: ["3.12", "3.13"] }` | An unquoted version: YAML reads `3.10` as the number 3.1 | 20A.10 |
| `steps[*].uses` | Runs an action | `uses: actions/checkout@<full commit ID> # v7.0.1`, from the pin file | A tag or branch after `@`: the tag can be moved by whoever controls the action's repository | 21A.7 |
| `steps[*].run`, `shell` | Runs a shell command | `shell: bash` | The implicit shell on Linux and macOS is `bash -e` without `pipefail`: the job is green although a command in a pipeline failed. `shell: bash` adds `-o pipefail`; set `defaults.run.shell` once | 20A.7 |
| `env` | Environment variables defined in the file | `env: { TITLE: "${{ github.event.pull_request.title }}" }` | Putting untrusted `${{ }}` values into the text of `run` instead of passing them through `env` | 20A.6, 21A.6 |
| `vars`, `secrets` (contexts) | Values stored in GitHub settings; only secrets are encrypted and masked | `${{ secrets.DEPLOY_KEY }}` in `env` | Treating an empty secret as "configured": an unset secret is an empty string, and fork runs get none | 20A.6, 21A.9 |
| `outputs` | Step outputs through `GITHUB_OUTPUT`; job outputs through the job's `outputs:` map | `echo "version=1.2.0" >> "$GITHUB_OUTPUT"` | Expecting shell state to survive a step: only `GITHUB_OUTPUT`, `GITHUB_ENV` and files do | 20A.7 |
| `environment` | Names a GitHub environment: protection rules before the job starts, its secrets and variables after | `environment: production` | A misspelled name creates a new, unprotected environment: production deploys without approval | 20B.2 |
| `jobs.<id>.uses` | Calls a reusable workflow (`on: workflow_call`) as one job | `uses: ./.github/workflows/11-reusable-workflow.yml` | An empty secret in the called workflow: secrets are passed by name, and environment secrets are read in the job that names the environment | 20B.6 |

Checkout facts that explain most surprises (20A.8): `actions/checkout` fetches **one commit, without tags**, for the ref of the event; on `pull_request` that ref is the test merge commit `refs/pull/N/merge`, checked out with a detached HEAD; `fetch-depth: 0` gets history and tags for `git describe`; `persist-credentials: false` keeps the job token out of `.git/config` unless a later step must push.

## 3. Events at a glance

The full table (ref, commit, which copy of the workflow file, notes) is section 4 of the [guide](../guides/github-actions-guide.md) and section 10 of the [GitHub reference](../reference/github-reference.md). The four facts to carry in your head:

| Event | What a default checkout gets | Token and secrets | Section |
|---|---|---|---|
| `push` | The tip commit that was pushed | The repository's token and secrets | 20A.4 |
| `pull_request` | The test merge commit of head into base; no run while the pull request conflicts | From a fork: a read-only token and no secrets | 20A.4, 21A.4 |
| `pull_request_target` | The default branch, and the workflow file from the default branch | The repository's token and secrets, in response to a stranger's pull request: never build or execute the pull request's code in it | 21A.5 |
| `workflow_dispatch`, `schedule`, `workflow_run` | The chosen ref, or the default branch | The repository's; `workflow_run` has secrets even when the triggering run had none | 20A.4, 21A.5 |

A re-run reuses the original ref and commit. Events caused by the `GITHUB_TOKEN` start no new runs, with the exceptions listed in the guide.

## 4. Caching, artifacts, reuse

| Feature | What it is | Rule | Common mistake | Section |
|---|---|---|---|---|
| Cache | A directory stored under a key; immutable per key | Put `hashFiles()` of the lock file in the key | Treating it as storage: it may be absent, and for a release job it is untrusted input | 20A.11, 21A.11 |
| Artifact | Files uploaded by a job and stored with the run | Set `retention-days`; `if-no-files-found: error` where a missing file must fail the job | Rebuilding in the deploy job: build once and deploy the artifact | 20A.12, 20B.3 |
| Reusable workflow | A workflow called as a job; it chooses its own runners and can name an environment | The caller's permissions are a ceiling | Renaming a job or moving it into a reusable workflow without changing the ruleset: the check name becomes `<caller job> / <called job>` | 20B.6 |
| Composite action | Several steps packaged in `action.yml` with `runs.using: "composite"`; runs on the caller's runner | Use it for repeated steps, not for whole jobs | Expecting it to name an environment: it cannot | 20B.6 |
| Aggregate job | One job with a stable name that `needs` all the others | Require this job, and only this job, in the ruleset | Requiring a matrix leg or a filterable workflow | 20A.10, 20B.13 |

## 5. Commands for runs, workflows, caches, secrets

The complete `gh` tables are in the [GitHub CLI cheat sheet](github-cli-cheat-sheet.md). `RUN_ID`, `FILE`, `NAME` are yours to fill.

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `gh run list` | Recent runs, optionally of one workflow (20B.14) | `gh run list --workflow 01-tests.yml` | 🟢 | Looking at the newest run when the failure is on another branch | Not needed |
| `gh run view` | One run: jobs, steps, logs of failed steps (20B.14) | `gh run view RUN_ID --log-failed` | 🟢 | Reading the last line only: the first failing step is the cause | Not needed |
| `gh run view --json headSha` | Which commit the run was about (20B.18) | `gh run view RUN_ID --json headSha` | 🟢 | Assuming it is the tip of your branch: on `pull_request` it is a merge commit | Not needed |
| `gh run watch` | Follows a run until it ends (20A.18) | `gh run watch RUN_ID` | 🟢 | Not needed | Not needed |
| `gh pr checks` | The checks of a pull request, and which are required (17.21) | `gh pr checks --required` | 🟢 | Waiting for a check that a filter skipped | Require an aggregate job |
| `gh run rerun` | A new attempt on the original commit and workflow file (20B.18) | `gh run rerun RUN_ID --failed` | 🟡 | Expecting it to pick up new commits: old code is deployed | Start a new run from the current commit |
| `gh run cancel` | Stops a run, possibly mid-deployment (20B.18) | `gh run cancel RUN_ID` | 🟡 | Cancelling a deployment half-way | Re-run; check the target's state by hand |
| `gh workflow view` | The workflow file as GitHub has it (20B.18) | `gh workflow view FILE --yaml` | 🟢 | Reading your local copy instead | Not needed |
| `gh workflow run` | Starts a `workflow_dispatch` run; uses minutes and may deploy (20A.18) | `gh workflow run FILE --ref BRANCH` | 🟡 | Expecting its checks to satisfy a pull request's required checks | `gh run cancel RUN_ID` |
| `gh cache list` | The repository's caches (20B.18) | `gh cache list` | 🟢 | Not needed | Not needed |
| `gh cache delete --all` | Removes every cache of the repository (20B.18) | `gh cache delete --all` | 🟡 | Doing it before a release: the next runs are slow | Caches are rebuilt by the next runs |
| `gh secret list` | Names of secrets, never values (20B.18) | `gh secret list --env NAME` | 🟢 | Expecting to read a value back | Not needed |
| `gh secret set`, `gh variable set` | Overwrites the stored value (20B.18) | `gh secret set NAME --env production` | 🟡 | Overwriting without the old value in your secret store | Set the previous value again |

## 6. "Passes locally, fails on GitHub Actions"

The investigation order is 20B.11; the causes below are the table of 20B.12, shortened. The runbook is section 7 of the [guide](../guides/github-actions-guide.md), and Git-side symptoms are in the [troubleshooting playbook](../playbooks/troubleshooting-playbook.md).

| Cause | Mechanism | Remedy |
|---|---|---|
| Shallow, tagless clone | The checkout fetches one commit and no tags, so `git describe` and tag-derived versions fail | `fetch-depth: 0` |
| The job is not testing the pushed commit | On `pull_request` the job checks out a merge of the head into the current base | Merge or rebase the base locally to reproduce |
| Missing secrets | Not passed to runs from forks or from Dependabot; an unset secret is an empty string | Fork-safe jobs; never `pull_request_target` as a shortcut |
| Shell differences | No `pipefail` in the implicit shell; `sh` in a job container; PowerShell on Windows | State the shell |
| Moving images and tools | Weekly image rebuilds; `-latest` labels move | Fixed labels; setup actions with versions |
| Required check stays pending | A workflow skipped by a filter or `[skip ci]` never reports | Require an aggregate job |
| Runs cancelled | A newer run in the same concurrency group | Workflow name and ref in the group |
| Stale or missing cache | Immutable per key; pull request caches are scoped to the merge ref | Hash of the lock file in the key |
| Environment differences | `CI=true` is set; steps share no shell state; every job is a new machine | `GITHUB_ENV`, outputs, artifacts |
| A workflow that never fires | Events made with the `GITHUB_TOKEN` start no runs; scheduled workflows are disabled after 60 days without repository activity in public repositories | A GitHub App token, or jobs chained with `needs` |
| Case sensitivity (Git) | macOS and Windows filesystems ignore case by default; a Linux runner does not | Fix the names in Git (Chapter 4, section 4.12) |
| Line endings (Git) | CRLF committed, or converted on checkout by `core.autocrlf` | `.gitattributes` (Chapter 14C, section 14C.5) |

## 7. Numbers worth knowing

All limits, prices and runner labels, with their sources and their "unverified" notes, are in section 10 of the [guide](../guides/github-actions-guide.md) and section 3 of the [GitHub reference](../reference/github-reference.md). The ones that change designs: a job on a hosted runner ends after 6 hours and `timeout-minutes` defaults to 360; a matrix has at most 256 jobs per run; artifacts and logs are kept 90 days by default; a cache is evicted after 7 days unused (20B.10).

## 8. The files

| File | Use |
|---|---|
| [`01-tests.yml`](../workflows/01-tests.yml) to [`12-secure.yml`](../workflows/12-secure.yml) | The twelve teaching workflows; the table of what each teaches is section 2 of the guide |
| [`ACTION_PINS.md`](../workflows/ACTION_PINS.md) | The full commit ID for every action used, read on 1 October 2026 |
| `workflows/broken/`, `workflows/vulnerable/` | Exercises, not templates: never copy from them |
