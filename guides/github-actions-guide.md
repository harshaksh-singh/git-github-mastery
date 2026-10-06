# The GitHub Actions guide

> **Baseline.** GitHub facts as of 1 October 2026; GitHub CLI 2.88.1; action versions from [`workflows/ACTION_PINS.md`](../workflows/ACTION_PINS.md), read on 1 October 2026. This is the practical companion to [Chapter 20A](../textbook/ch20a-actions-fundamentals.md), [Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md) and [Chapter 21A](../textbook/ch21a-actions-security.md). The chapters explain why; this guide is what you keep open while you write, review or debug a workflow.

> **What was verified.** Every workflow file of this course was parse-checked with PyYAML and assembled from syntax documented on docs.github.com or in the action's README at the pinned version. None was executed on GitHub by the authors. The labs have you run them. Where this guide says what GitHub does, it is described from the linked documentation.

## 1. How to use this guide

| You want to | Go to |
|---|---|
| find a workflow to copy from | section 2 |
| write or review a workflow | section 3, the authoring checklist |
| know which commit a job builds | section 4, events |
| know which context a value comes from | section 5, contexts |
| deploy with a gate | section 6 |
| find out why a run failed | section 7, the debugging runbook |
| unblock a pull request that waits for a check | section 8 |
| update an action | section 9, pins |
| estimate cost or check a limit | section 10 |

GitHub Actions is a GitHub product. Git supplies commits, refs and tags; everything else in this guide (events, runners, tokens, environments, checks) exists only on GitHub.

## 2. The twelve workflows

The files are in [`workflows/`](../workflows/ACTION_PINS.md). You copy each into `.github/workflows/` of your practice repository `YOUR-ORG/inventory-api` (the sample project, pushed as its own repository in Lab 26.1) in the lab named in the table. The file names are fixed; other course material refers to them.

| # | File | Purpose | Concepts it teaches | Lab |
|---|---|---|---|---|
| 1 | [`01-tests.yml`](../workflows/01-tests.yml) | Minimal CI: run the tests | workflow, job, step; `push` and `pull_request` with a branch filter; least-privilege `permissions`; what `actions/checkout` puts on the runner | 26.1 |
| 2 | [`02-lint.yml`](../workflows/02-lint.yml) | Lint and format check with ruff | install from the lock file with `uv sync --locked`; `if: ${{ !cancelled() }}` so both checks report; a job summary through `GITHUB_STEP_SUMMARY` | 26.2 |
| 3 | [`03-build.yml`](../workflows/03-build.yml) | Build the sdist and wheel | tag filter and manual trigger; `fetch-depth: 0` for `git describe`; step outputs, job outputs, `needs`; `shell: bash` and `pipefail` | 26.3 |
| 4 | [`04-python-tests.yml`](../workflows/04-python-tests.yml) | Python tests with uv and caching | the cache built into `astral-sh/setup-uv`, keyed on `uv.lock`; reading a cache result; a concurrency group that cancels superseded runs | 26.4 |
| 5 | [`05-java-tests.yml`](../workflows/05-java-tests.yml) | Java tests with Maven | a path filter; `defaults.run.working-directory`; the Maven cache of `actions/setup-java`; uploading reports only on failure | 26.5 |
| 6 | [`06-docker-image.yml`](../workflows/06-docker-image.yml) | Build a container image and push it to `ghcr.io` | job-level `permissions` with `packages: write`; login with the job token; tags and labels from `docker/metadata-action`; build on pull requests, push only from the repository's own refs; the BuildKit cache | 26.6, 27.1 |
| 7 | [`07-artifact.yml`](../workflows/07-artifact.yml) | Create an artifact and consume it in a later job | every job is a new machine; artifact ID and digest; retention; the digest check on download | 26.7, 27.2 |
| 8 | [`08-deploy-staging.yml`](../workflows/08-deploy-staging.yml) | Deploy to staging | build once, deploy the artifact; a job that references an environment; environment secrets and variables; a concurrency group that serialises deployments | 27.3 |
| 9 | [`09-environments.yml`](../workflows/09-environments.yml) | Staging, then production with approval | two environments with different rules; required reviewers and a deployment branch rule; promotion of one artifact; plan gates | 27.4 |
| 10 | [`10-matrix.yml`](../workflows/10-matrix.yml) | Matrix testing | `strategy.matrix` with `include` and `exclude`; `fail-fast: false`; an experimental leg with `continue-on-error`; one aggregate job that is safe to require | 26.8 |
| 11 | [`11-reusable-workflow.yml`](../workflows/11-reusable-workflow.yml) with [`11-caller.yml`](../workflows/11-caller.yml) | A reusable workflow and its caller | `on: workflow_call`; typed inputs, a named secret, an output; `jobs.<job_id>.uses`; the caller's permissions as a ceiling; the check name `<caller job> / <called job>` | 27.5 |
| 12 | [`12-secure.yml`](../workflows/12-secure.yml) | A secure-by-default workflow | read-only token by default; untrusted input only through `env`; `persist-credentials: false`; OIDC behind a protected environment | 29.2 |

Two further directories are exercises, not templates. Never copy from them into a real repository.

| Directory | Contents | Diagnosed in |
|---|---|---|
| `workflows/broken/` | six workflows, each failing for a different documented reason: `01-version-stamp.yml`, `02-source-tests.yml`, `03-pr-summary-comment.yml`, `04-integration-tests.yml`, `05-branch-ci.yml`, `06-cached-environment.yml` | Lab 28.1; answers in `solutions/m28-broken-workflows.md` |
| `workflows/vulnerable/` | five workflows with planted vulnerabilities | Lab 29.1 |

The sample project's Java module and Dockerfile could not be built while the course was written (no JDK, no image pulls). Workflows 5 and 6 are therefore the least tested files: expect to read their logs carefully the first time.

## 3. The authoring checklist

Use it when you write a workflow and when you review one in a pull request. Each line names the chapter section that explains it.

**Trigger**

- [ ] The events are the smallest set that does the job. For CI: `pull_request` plus `push` to the default branch. (20A)
- [ ] You can say, for each event, which ref and commit the job checks out (section 4).
- [ ] No `paths` or `branches` filter on a workflow whose job is a required status check (section 8).
- [ ] `pull_request_target` and `workflow_run` are absent, or justified in a comment and reviewed against Chapter 21A.
- [ ] If the repository uses a merge queue, workflows that provide required checks also trigger on `merge_group`.

**Token and secrets**

- [ ] Top-level `permissions` is present. Start with `contents: read`. Naming any scope sets all unnamed scopes to `none`.
- [ ] A job that needs more (for example `packages: write`, `pull-requests: write`) gets it in a job-level `permissions` block, not at the top.
- [ ] Secrets reach scripts through `env`, never through `${{ }}` inside the text of `run`.
- [ ] No secret is used in a job that runs code from a fork. Secrets are not passed to fork runs anyway; an unset secret is an empty string, so the job must not treat "empty" as "configured".
- [ ] Deployment credentials are environment secrets, read only by the job that deploys.

**Actions**

- [ ] Every `uses` is pinned to a full commit ID with the version in a trailing comment, taken from `workflows/ACTION_PINS.md` or re-verified (section 9).
- [ ] `actions/checkout` has `persist-credentials: false` unless a later step must push with the job token.
- [ ] `fetch-depth: 0` only in jobs that need history or tags.
- [ ] Setup actions state the tool version. Nothing relies on what the image happens to contain.

**Runner and shell**

- [ ] `runs-on` is a fixed label (`ubuntu-24.04`), not a `-latest` label, and the retirement date of that image is known.
- [ ] `timeout-minutes` is set on every job. The default is 360.
- [ ] Multi-line and piped `run` steps declare `shell: bash`, which adds `-e` and `-o pipefail`. The implicit shell has no `pipefail`.
- [ ] No self-hosted runner for a public repository.

**Data flow**

- [ ] Files cross jobs as artifacts; values cross steps through `GITHUB_OUTPUT` or `GITHUB_ENV`; nothing assumes shell state from an earlier step.
- [ ] Artifacts have a `retention-days` and `if-no-files-found: error` where a missing file must fail the job.
- [ ] A cache key contains `hashFiles()` of the lock file. A cache is never the only source of something the job needs.

**Concurrency and deployment**

- [ ] CI: `group: ${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true`.
- [ ] Deployment: a fixed group per target with `cancel-in-progress: false`; `queue: max` if every run must execute.
- [ ] The environment named in the file exists on GitHub and has the rules you think it has (section 6).
- [ ] A deployment job states what it deploys (commit, artifact or image digest) in the job summary.

**Required checks**

- [ ] The required check is one aggregate job with a stable name. Job names are unique across workflows.
- [ ] Renaming a job, or moving it into a reusable workflow, is accompanied by a ruleset change.

**Before pushing**

- [ ] The file parses: `python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" FILE`.
- [ ] If you have `actionlint`, it is clean. Neither check proves the workflow does what you intend.
- [ ] Changes under `.github/workflows/` require review by a named owner through CODEOWNERS ([Chapter 19](../textbook/ch19-codeowners.md)).

## 4. Events and what they check out

`actions/checkout` without a `ref` input checks out the ref and commit of the event. That is why the event decides what your tests test. From [events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) and the [checkout README](https://github.com/actions/checkout/blob/v7.0.1/README.md):

| Event | `GITHUB_REF` | `GITHUB_SHA` (what a default checkout gets) | Workflow file taken from | Notes |
|---|---|---|---|---|
| `push` | the updated branch or tag | the tip commit that was pushed | the pushed commit | runs for branches that are not merged; path filters are not evaluated for tag pushes |
| `pull_request` | `refs/pull/N/merge` | the test merge commit of head into base, detached HEAD | the merge commit | does not run while the pull request has a conflict; default types `opened`, `synchronize`, `reopened`; fork runs get no secrets and a read-only token |
| `pull_request_target` | the default branch | the last commit of the default branch | the default branch (always, since 8 December 2025) | has secrets and a write-capable token; never build pull request code in it (Chapter 21A) |
| `merge_group` | the merge group's ref | the merge group's commit | that commit | required for checks in a merge queue |
| `workflow_dispatch` | the branch or tag chosen | its tip | the chosen ref, but the workflow must exist on the default branch | its checks do not satisfy a pull request's required checks; up to 25 inputs |
| `schedule` | the default branch | its latest commit | the default branch | UTC unless `timezone` is set; can be delayed or dropped; disabled after 60 days without activity in a public repository |
| `workflow_call` | the caller's | the caller's | the reference in the caller's `uses` | the `github` context is the caller's |
| `workflow_run` | the default branch | its latest commit | the default branch | has secrets even when the triggering run had none; at most three levels of chaining |
| `release` | `refs/tags/<tag>` | the tagged commit | that commit | a release created with the `GITHUB_TOKEN` starts no run |
| `issue_comment` | the default branch | its latest commit | the default branch | fires for comments on pull requests too |

Four consequences to remember:

1. **A pull request run tests a commit that exists nowhere in your clone.** To reproduce it, merge the base into your branch locally (Lab 28.2).
2. **A default checkout is one commit without tags.** `git describe`, changelog tools and "changed files since" logic need `fetch-depth: 0`.
3. **A re-run reuses the original ref and commit.** It does not pick up new commits or a changed workflow file.
4. **Events caused by the `GITHUB_TOKEN` start no new runs**, except `workflow_dispatch` and `repository_dispatch`, and pull request events, which since 11 June 2026 create runs that wait for approval ([GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token), [changelog](https://github.blog/changelog/2026-06-11-bot-created-pull-requests-can-run-workflows-if-approved/)).

To test only the head commit of a pull request and not the merge, the documented form is `ref: ${{ github.event.pull_request.head.sha }}` on the checkout step. Know that you are then not testing what will land on the base branch.

## 5. Contexts

A context is a named object you read inside `${{ }}`. From the [contexts reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts):

| Context | Holds | Typical use | Watch for |
|---|---|---|---|
| `github` | the event, ref, commit, actor, run and workflow identity | `github.event_name`, `github.ref`, `github.sha`, `github.head_ref`, `github.run_id` | `github.event.*` fields written by users are untrusted input; `github.token` is inside this context, so never dump it whole |
| `env` | variables set by `env:` at workflow, job or step level | step keys | not available where the job is not yet on a runner, for example in `runs-on`; the caller's `env` does not reach a called workflow |
| `vars` | configuration variables of the organization, repository and environment | `vars.STAGING_URL` | not secret; environment variables appear only in jobs that reference the environment |
| `secrets` | secrets, and `secrets.GITHUB_TOKEN` | values passed into `env` or `with` | empty string when unset or withheld; not usable directly in `if`; not available in composite actions |
| `inputs` | inputs of `workflow_dispatch` and `workflow_call` | `inputs.environment` | reusable workflow inputs are `boolean`, `number` or `string` only |
| `needs` | outputs and results of jobs listed in `needs` | `needs.build.outputs.x`, `needs.build.result` | `result` is `success`, `failure`, `cancelled` or `skipped` |
| `steps` | outputs, `outcome` and `conclusion` of earlier steps that have an `id` | `steps.rev.outputs.revision` | `outcome` is before `continue-on-error`, `conclusion` after |
| `job` | status and service containers of the current job | `job.status` | |
| `jobs` | job outputs, in a reusable workflow only | `on.workflow_call.outputs.<id>.value` | |
| `runner` | the machine: `runner.os`, `runner.arch`, `runner.temp`, `runner.debug`, `runner.environment` | cache keys, paths | `runner.os` is `Linux`, `Windows` or `macOS` |
| `strategy`, `matrix` | the matrix of the current job | `matrix.python` | |

**Availability is per key.** The documented table is long; these rows cause most errors:

| Key | Contexts allowed |
|---|---|
| workflow-level `concurrency`, `run-name` | `github`, `inputs`, `vars` |
| `jobs.<job_id>.if` | `github`, `needs`, `vars`, `inputs` |
| `jobs.<job_id>.runs-on` | `github`, `needs`, `strategy`, `matrix`, `vars`, `inputs` |
| `jobs.<job_id>.environment` | `github`, `needs`, `strategy`, `matrix`, `vars`, `inputs` |
| `jobs.<job_id>.steps.if` | `github`, `needs`, `strategy`, `matrix`, `job`, `runner`, `env`, `vars`, `steps`, `inputs` |
| `jobs.<job_id>.uses` | none: no expression is allowed |

`secrets` is missing from both `if` rows. To make a step conditional on a secret being present, put the secret into a job-level `env` variable and test `env.NAME` in the step's `if`, as the [secrets how-to](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets) describes.

**Expression facts that bite.** String comparison ignores case. A reference to a property that does not exist is an empty string, not an error. An `if` with text outside `${{ }}` is a non-empty string and therefore always true; since 29 January 2026 this produces an annotation. Prefer `!cancelled()` to `always()`. `hashFiles()` works only in step keys. The `case()` function exists since 29 January 2026 ([expressions](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions)).

**Passing data.**

| From | To | Mechanism |
|---|---|---|
| step | later step, same job | `echo "name=value" >> "$GITHUB_OUTPUT"` and `steps.<id>.outputs.name`; or `GITHUB_ENV` |
| job | later job | `jobs.<job_id>.outputs` and `needs.<job_id>.outputs.name`; files as artifacts |
| called workflow | caller | `on.workflow_call.outputs` and `needs.<calling job>.outputs.name` |
| run | later run | cache (may be absent), or an artifact downloaded with a run ID |
| run | humans | `GITHUB_STEP_SUMMARY` |

## 6. Deployment recipe

The pattern of workflows 8 and 9, as a procedure.

1. **Create the environments first**, in the repository settings or with the REST API, before any workflow names them. A workflow that names a missing environment creates it without rules.

```bash
gh api -X PUT repos/YOUR-ORG/inventory-api/environments/staging
gh api -X PUT repos/YOUR-ORG/inventory-api/environments/production --input production-environment.json
gh api repos/YOUR-ORG/inventory-api/environments/production
```

The JSON body may contain `wait_timer`, `prevent_self_review`, `reviewers` and `deployment_branch_policy` ([REST reference](https://docs.github.com/en/rest/deployments/environments)); Lab 27.4 gives the file.

2. **Scope what differs to the environment.**

```bash
gh variable set DEPLOY_URL --env staging --body "https://staging.inventory.example.com"
gh variable set DEPLOY_URL --env production --body "https://inventory.example.com"
gh secret set DEPLOY_TOKEN --env staging
gh secret set DEPLOY_TOKEN --env production
```

3. **Build once.** One job tests and builds and uploads an artifact, or pushes an image and records its digest. Deploy jobs download; they do not rebuild.
4. **One job per target, chained with `needs`.** Each names its environment and has its own concurrency group with `cancel-in-progress: false`.
5. **Protect production with three things together:** a ruleset on `main` that requires reviewed pull requests; a deployment branch rule that accepts only `main`; a required reviewer with self-review prevented.
6. **Verify the gate** with a harmless run before you rely on it, and read the rules back with `gh api`.
7. **Record** the commit and target in the job summary.

Plan gates, from the [environments reference](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments): on Free, Pro and Team, required reviewers and wait timers work only in public repositories; branch rules and environment secrets work in private repositories from Pro and Team. Whether a Free private repository can use environments at all is an unresolved conflict between a May 2025 changelog entry and the current documentation; Chapter 20B, section 20B.2 has the details.

Before you approve a production job, ask Git what the approval releases: `git log --oneline <commit in production>..<commit of the run>`.

## 7. The debugging runbook

Work through the list in order. Stop at the first step that explains the failure. Write down what you found at each step; that record is the root-cause analysis.

**Step 0: get the facts of the run.**

```bash
gh run list --limit 10
gh run view RUN_ID
gh run view RUN_ID --json workflowName,event,headBranch,headSha,conclusion,attempt
git rev-parse HEAD
```

| # | Check | Questions | Commands and places |
|---|---|---|---|
| 1 | Workflow | Is this the file and the version of the file I think it is? Did it run at all? | `gh workflow list --all`; `gh workflow view FILE --yaml --ref BRANCH`. No run: the file is not on the default branch (for `schedule`, `workflow_dispatch`), is disabled, was filtered out, or the event came from the `GITHUB_TOKEN` |
| 2 | Event | Which event, ref and commit? Is `headSha` the commit I tested locally? | section 4. For a pull request run, reproduce the merge locally |
| 3 | Permissions | Which scopes did the token have? Was this a fork or Dependabot run? | the `permissions` blocks; a 403 from the API in the log; the "Set up job" section of the log lists the token's permissions |
| 4 | Runner | Which label, image and size? Did a `-latest` label move? Is the repository private (2 CPUs, 8 GB)? | `runs-on`; the image named at the top of the job log |
| 5 | Environment | Did the job wait, get rejected, or fail a branch rule? Does the environment have the rules I expect? | `gh api repos/OWNER/REPO/environments/NAME` |
| 6 | Dependencies | Same versions as locally? Was the lock file respected? | versions printed by setup steps; `uv sync --locked` |
| 7 | Secrets | Present, or empty? | never print a secret; test for emptiness in the script and fail with a clear message |
| 8 | Action versions | Which commit of each action ran? Was a pin updated recently? | `git log -p -- .github/workflows/`; section 9 |
| 9 | Logs | What did the failed step print? | `gh run view RUN_ID --log-failed`; `gh run rerun RUN_ID --failed --debug` |
| 10 | Artifacts | Produced? Right name? Expired? | `gh run download RUN_ID --dir /tmp/run-artifacts` |
| 11 | Cache | Restored from which key? Exact hit or a prefix? | the cache step's log; `gh cache list --key PREFIX` |
| 12 | Concurrency | Cancelled by a newer run? Same group as another workflow? | conclusion `cancelled`; `gh run list --workflow FILE` |

That the "Set up job" section lists the token's permissions and the runner image is common knowledge among Actions users, but the Phase 0 research did not verify it against a documentation page. Confirm it in your first real log.

**Symptom to first suspect.**

| Symptom | Look first at | Usual cause |
|---|---|---|
| `fatal: No names found, cannot describe anything` | 2 | shallow, tagless checkout |
| Tests pass on the branch, fail in the pull request | 2 | the run tests the merge with the current base |
| HTTP 403 from `gh` or the API inside a job | 3 | missing `permissions` scope; fork or Dependabot run |
| A step that needs a credential fails only for outside contributors | 7 | secrets are not passed to fork runs |
| File not found on Linux, fine on a Mac | Git | file-name case; `git ls-files` shows the recorded name |
| `bash\r: No such file or directory` | Git | CRLF in a script; `git ls-files --eol` |
| A step with a pipe passes although a command in the pipe failed | runner | implicit shell has no `pipefail`; add `shell: bash` |
| Run shows "cancelled" and nobody cancelled it | 12 | concurrency group shared too widely |
| New dependency missing although the lock file changed | 11 | cache key without the lock file hash |
| Job killed or very slow after a visibility change | 4 | smaller runners in private repositories |
| Job waits and never starts | 4, 5 | no matching self-hosted runner; environment approval pending |
| No run at all | 1 | filter, disabled workflow, default-branch rule, `GITHUB_TOKEN` event |
| Pull request "waiting for status to be reported" | section 8 | the required workflow never started |

**Instruments.**

- Failed-step log: `gh run view RUN_ID --log-failed`. Whole log of one job: `gh run view --log --job JOB_ID`. Job IDs: `gh run view RUN_ID --json jobs --jq '.jobs[] | {name, databaseId}'`.
- Follow a run: `gh run watch RUN_ID --exit-status`. Checks of a pull request: `gh pr checks --watch`; `gh pr checks --required`.
- Re-run with debug logging: `gh run rerun RUN_ID --failed --debug`. Permanent switches: repository secret or variable `ACTIONS_STEP_DEBUG` or `ACTIONS_RUNNER_DEBUG` set to `true` ([enable debug logging](https://docs.github.com/en/actions/how-tos/monitor-workflows/enable-debug-logging)). Remove them afterwards.
- A skipped job's log shows its `if` expression with the values it was evaluated with (since 29 January 2026).
- A re-run uses the original commit, ref and actor privileges, is possible for 30 days and at most 50 times. Do not re-run old deploy runs.
- `GIT_TRACE=1 GIT_CURL_VERBOSE=1` in a step's `env` makes Git explain a fetch or push failure.

**Local reproduction, in rising cost.**

1. The same commit: for a pull request, `git fetch origin && git switch --detach origin/main && git merge --no-ff <your branch>`, then run the tests.
2. A clean clone, not your working tree: `git clone --depth 1 --no-tags <url>` shows what a default checkout contains.
3. The same commands with the same flags: `uv sync --locked`, not `uv sync`; `CI=true` in the environment.
4. The same image, in a container, if you have Docker.
5. `act`, knowing that it ignores `concurrency`, job `permissions`, `environment` and OIDC ([unsupported functionality](https://nektosact.com/not_supported.html)).

**After the fix.** Say in the pull request what the root cause was and which layer it belongs to (Git, GitHub, or GitHub Actions). Add the prevention to the checklist of section 3 if it is not there.

## 8. Required checks: the short version

From [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks):

- Passing conclusions are `success`, `skipped` and `neutral`. Checks must pass on the latest commit.
- A workflow that never starts (path filter, branch filter, `[skip ci]`) leaves its required check pending and blocks the merge. A job skipped by `if` passes.
- Only runs triggered by `push`, `pull_request`, `pull_request_review`, `pull_request_target`, `deployment` and `deployment_status` count for a pull request. A manual run does not.
- A check must have completed successfully in the repository within the last seven days to be selectable as required.
- A job in a reusable workflow reports as `<calling job name> / <called job name>`. The name a matrix job reports is not stated on the pages read for this course: read it from a real run with `gh pr checks`.
- With a merge queue, the workflow must also trigger on `merge_group`.

The design that survives all of this: no filters on the workflow; conditions on jobs; one aggregate job that runs with `if: ${{ !cancelled() }}`, `needs` every other job, fails when any needed result is `failure` or `cancelled`, and is the only required check. Workflow 10 contains such a job; Chapter 20B, section 20B.13 shows it.

## 9. Action pins

Every `uses` in this course is pinned to a full commit ID with the version as a comment. A tag can be moved by whoever controls the action's repository; a commit ID cannot. The table is a copy of [`workflows/ACTION_PINS.md`](../workflows/ACTION_PINS.md), read on 1 October 2026 with an anonymous `git ls-remote --tags`. For annotated tags the ID is the commit the tag points at.

| Action | Version | Commit ID |
|---|---|---|
| actions/checkout | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| actions/setup-python | v7.0.0 | `5fda3b95a4ea91299a34e894583c3862153e4b97` |
| actions/setup-java | v6.0.1 | `de7274f081f381c8f8158605e0321c36c376e2e6` |
| actions/setup-node | v7.0.0 | `820762786026740c76f36085b0efc47a31fe5020` |
| actions/cache | v6.1.0 | `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` |
| actions/upload-artifact | v7.0.1 | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` |
| actions/download-artifact | v8.0.1 | `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` |
| actions/github-script | v9.0.0 | `3a2844b7e9c422d3c10d287c895573f7108da1b3` |
| actions/attest | v4.2.2 | `1e69f48acb82d1966a394da916b4c1698aa569d6` |
| actions/dependency-review-action | v5.0.0 | `a1d282b36b6f3519aa1f3fc636f609c47dddb294` |
| actions/configure-pages | v6.0.0 | `45bfe0192ca1faeb007ade9deae92b16b8254a0d` |
| actions/upload-pages-artifact | v5.0.0 | `fc324d3547104276b827a68afc52ff2a11cc49c9` |
| actions/deploy-pages | v5.0.1 | `368f82528645a54fb793d4d04e342629a3f51346` |
| astral-sh/setup-uv | v10.2.0 | `c18668ad3cf93ea998bef934396af7bb5c839dc7` |
| docker/login-action | v4.6.0 | `dbcb813823bdd20940b903addbd779551569679f` |
| docker/setup-buildx-action | v4.4.1 | `f87e5991a6d7451dcb8d9637bfbc97413f497069` |
| docker/setup-qemu-action | v4.4.0 | `99012661954931238ded8c8b007157a8430204e1` |
| docker/build-push-action | v7.4.0 | `c3c9e263c25d99ce0380d002d59b67737d91b0dc` |
| docker/metadata-action | v6.2.0 | `dc802804100637a589fabce1cb79ff13a1411302` |
| github/codeql-action | v4.38.2 | `2892aa5e19bbd11bc0cff5427e3b750a04d9e3c2` |
| softprops/action-gh-release | v3.0.3 | `efb35369e0ad2afab669f228072c1b0d510eae64` |
| gradle/actions | v6.4.0 | `3f5f9adaf7d9fecd50b5935e54106014257a94e6` |
| aws-actions/configure-aws-credentials | v6.3.0 | `e1253824e5c10ff9df46874f81ed3ec929e19cfd` |
| google-github-actions/auth | v3.0.0 | `7c6bc770dae815cd3e89ee6cdf493a5fab2cc093` |
| azure/login | v3.1.0 | `a641126d1b8aa4d1fa005f4f92df94a3a4c4c906` |

**How a pin is written.**

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```

**Re-verify a pin yourself.** It needs no login, and you should do it before you trust any pin, including these.

```bash
git ls-remote --tags https://github.com/actions/checkout 'refs/tags/v7.0.1*'
```

Two lines mean an annotated tag: the line ending in `^{}` is the commit, and that is the ID a workflow must reference. One line means a lightweight tag, and it is the commit.

**Keep pins current.** A pin does not move until you move it, which is its purpose and its cost.

- Add the `github-actions` ecosystem to `.github/dependabot.yml`. Dependabot proposes updates that change the commit ID and the version comment together; version updates wait a default three-day cooldown since 14 July 2026 ([changelog](https://github.blog/changelog/2026-07-14-dependabot-version-updates-introduce-default-package-cooldown/)). Chapter 21A covers the configuration.
- Review an update like code: read the action's release notes for the new version, and check the ID with `git ls-remote`.
- An organization can require full-commit pinning through its allowed-actions policy (since 15 August 2025).
- A pin fixes the action's own code. It does not fix what the action downloads at run time, such as a tool binary or a container image. Chapter 21A discusses that limit.

**Version facts that change what you write** (from the Phase 0 report): `actions/checkout` v7 refuses to check out fork pull request code under `pull_request_target` and `workflow_run`; `astral-sh/setup-uv` has no floating major tag since v8, so it can only be referenced by full version or commit; `actions/download-artifact` v8 fails on a digest mismatch; `actions/cache` versions older than v4.2.0 and v3.4.0 fail since the cache service change of February 2025; all JavaScript actions run on Node 24 since 23 September 2026, including old majors written for Node 20.

## 10. Limits and cost on one page

| Item | Value | Source |
|---|---|---|
| Job on a hosted runner | 6 hours | [limits](https://docs.github.com/en/actions/reference/limits) |
| Workflow run | 35 days, including waiting | limits |
| Environment approval | fails after 30 days | [control deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments) |
| Matrix | 256 jobs per run | limits |
| Re-runs | 50 per run | limits |
| Reusable workflows | 10 levels, 50 unique per file | [reference](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations) |
| Job outputs | 1 MB per job, 50 MB per run | [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idoutputs) |
| Cache | 10 GB per repository free; evicted after 7 days unused | [dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching) |
| Artifacts, logs, checks, runs | 90 days by default | [changelog](https://github.blog/changelog/2026-08-27-actions-retention-will-cover-checks-workflow-runs-and-statuses/) |
| Included minutes, private repositories | Free 2,000; Pro and Team 3,000; Enterprise Cloud 50,000 per month | [billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions) |
| Price per minute | Linux 2-core $0.006; Linux arm64 $0.005; `ubuntu-slim` $0.002; Windows $0.010; macOS $0.062 | [runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing) |
| Standard runner size | public: 4 CPUs, 16 GB; private: 2 CPUs, 8 GB | [hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) |

Public repositories use standard runners without charge. Each job is rounded up to a whole minute. Larger runners are always billed. How Windows and macOS minutes count against the included minutes is unverified in 2026 documentation; do not quote a multiplier. A charge for self-hosted runner minutes was announced in December 2025 and postponed; it is not in effect.

Runner labels on 1 October 2026: `ubuntu-latest` is Ubuntu 24.04 and moves to 26.04 between 19 October and 19 November 2026; `windows-latest` is Windows Server 2025; `macos-latest` is macOS 26 on arm64. `ubuntu-22.04` is deprecated (unsupported from 17 April 2027) and `macos-14` ends on 2 November 2026.

## 11. Sources

- GitHub Docs: [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts), [expressions](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions), [variables](https://docs.github.com/en/actions/reference/workflows-and-actions/variables), [workflow commands](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands).
- GitHub Docs: [deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments), [reusing workflow configurations](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations), [troubleshooting workflows](https://docs.github.com/en/actions/how-tos/troubleshoot-workflows), [re-running workflows and jobs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs), [skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs), [secure use](https://docs.github.com/en/actions/reference/security/secure-use).
- GitHub CLI: [gh run view](https://cli.github.com/manual/gh_run_view), [gh run rerun](https://cli.github.com/manual/gh_run_rerun), [gh run watch](https://cli.github.com/manual/gh_run_watch), [gh workflow run](https://cli.github.com/manual/gh_workflow_run), [gh cache](https://cli.github.com/manual/gh_cache); flags checked against `--help` of 2.88.1.
- The course's Phase 0 research report, sections 2, 12 and 13, for dated changes and flags.
