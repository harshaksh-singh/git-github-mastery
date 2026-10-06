# Chapter 20B: GitHub Actions: delivery, runners, cost and debugging

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch20b/`. Everything about GitHub Actions is described from the linked documentation: the workflow files of this chapter were parse-checked and assembled from documented syntax, but the author did not execute them on GitHub. You run them in the labs.

[Chapter 20A](ch20a-actions-fundamentals.md) taught the parts of a workflow and built eight of them. This chapter uses those parts to deliver software, and then teaches the skill a CTO pays for: finding out why a run failed, in a fixed order, with evidence. Security of workflows is [Chapter 21A](ch21a-actions-security.md); it is referred to here and not repeated.

## 20B.1 Why this matters

Three questions reach a senior engineer every month.

"Who approved what is running in production, and which commit is it?" The answer is not in Git. It is in GitHub objects: an environment, its protection rules, a deployment record. If you cannot say which rules gate the production job and who can bypass them, you do not control your releases.

"The tests pass on my machine. Why is the pull request red?" Almost always because the job did not run what you ran: another commit, another shell, another tool version, no secrets, an empty history. Each cause is a documented default. An engineer who knows the defaults finds the cause in minutes; one who does not re-runs the job and hopes.

"Why did our Actions bill triple, and why does the merge button say it is waiting for a check that never comes?" Both are consequences of how runs are started, cancelled, billed and reported. Both are explainable from the documentation.

> **GitHub, not Git.** Nothing in this chapter is a Git feature. Git supplies the commit, the ref and the tag. GitHub Actions decides when to run, on which machine, with which token, and GitHub decides what a "deployment" and a "check" are. Where Git explains a failure (a shallow history, a file-name case, a line ending), the chapter shows it with a local transcript.

## 20B.2 Environments

**In one sentence.** An environment is a named GitHub object that a job can reference, and that holds protection rules the job must pass before it starts and secrets and variables the job can read only after that.

**Analogy.** An environment is the locked door of a server room with its own key cabinet inside. The job is a technician. The door has rules: someone must sign the visitor in, the visitor must come from a known department, there may be a waiting period. The keys in the cabinet are only reachable after the door has opened. The analogy breaks in one place: the door is guarded by GitHub, not by the server room. If your cloud account also accepts credentials from somewhere else, the environment protects nothing.

**Precisely.** A job references an environment with `jobs.<job_id>.environment`, either as a name or as a mapping with `name` and `url`. The [environments reference](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments) defines the rules:

| Rule or content | What it does | Documented detail |
|---|---|---|
| Required reviewers | The job waits until a listed person or team approves | Up to six users or teams; one approval is enough; "prevent self-review" stops the person who started the run from approving it |
| Wait timer | The job waits a fixed time after it is triggered | 1 to 43,200 minutes (30 days); waiting is not billed |
| Deployment branches and tags | Only runs on matching refs may deploy | "No restriction", "Protected branches only", or "Selected branches and tags"; patterns are matched against the ref, and `*` does not match `/` |
| Allow administrators to bypass | Lets a repository administrator force the deployment | On by default; can be switched off per environment |
| Custom deployment protection rules | A GitHub App decides (for example an observability product) | Public preview; at most six protection rules enabled per environment |
| Environment secrets | Secrets that exist only for jobs that reference the environment | Not readable before a required approval is given |
| Environment variables | Non-secret configuration in the `vars` context | Same scoping as the secrets |

Two details decide how safe this is. First, the [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idenvironment) says all protection rules must pass before a job that references the environment is sent to a runner. The gate is in front of the machine, not a step inside the job that the job could skip. Second, [managing environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments) says that a workflow that names an environment that does not exist creates it, without any rule, and that anyone who can edit workflows can do so, while only repository administrators can configure an environment. A typing error in the name (`prodution`) therefore gives you an unprotected environment, not an error.

**Plan gates.** These come straight from the same reference and are the first thing to check before you design a gate:

| Feature | Public repository, any plan | Private repository on Free | Private on Pro or Team | Private on Enterprise |
|---|---|---|---|---|
| Required reviewers, wait timers, custom rules, disabling admin bypass | yes | no | no | yes |
| Deployment branch and tag rules | yes | no | yes | yes |
| Environment secrets | yes | no | yes | yes |
| Environment variables | yes | not stated for Free | yes | yes |

> **Unverified.** Whether a private repository on a Free plan can use environments at all is a conflict inside GitHub's own material. A [changelog entry of 15 May 2025](https://github.blog/changelog/2025-05-15-new-releases-for-github-actions/) says environments are available on all plans in public and private repositories; the [managing environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments) page on 1 October 2026 still says users on Free plans can configure environments only for public repositories. The Phase 0 report could not resolve it. The practice repository of the Actions labs, `YOUR-ORG/inventory-api`, is public, so the labs are not affected. For a private repository, test it before you promise a gate.

**Inside `.git`.** Nothing. An environment, its rules, its secrets and the deployment records it produces are GitHub objects. A clone of the repository contains none of them. The only trace in Git is the word after `environment:` in the workflow file. That is why a repository that is mirrored to another host loses its gates, and why "the workflow file says `environment: production`" proves nothing until you have read the environment's settings.

**See it.** You cannot see an environment with Git. What Git can show is the thing a deployment branch rule is matched against: the ref of the run. In this transcript a hotfix branch is checked out; the commands print the ref and test it against `refs/heads/main` the way a rule "Selected branches: `main`" would.

<!-- snippet: ch20b/lab-27-4-promotion/02-failure -->
```text
# An urgent fix on a branch. The rule on production says: selected branches, main.
$ git switch --quiet hotfix/lead-days
$ git symbolic-ref HEAD
refs/heads/hotfix/lead-days
$ test "$(git symbolic-ref HEAD)" = refs/heads/main
[exit status: 1]
$ git merge-base --is-ancestor HEAD main
[exit status: 1]
```
<!-- /snippet -->

The first test fails because the ref is `refs/heads/hotfix/lead-days`. The second shows that the commit is not yet contained in `main` either. A branch rule looks at the first fact only: the name of the ref the run was started for. Section 20B.4 comes back to what that does and does not guarantee.

**Picture.**

```text
 push to main
      |
      v
 +-----------+      +--------------------+      +------------------------+
 |  build    | ---> | deploy-staging     | ---> | deploy-production      |
 |  (runner) |      | environment:       |      | environment:           |
 +-----------+      |   staging          |      |   production           |
                    | rules: none        |      | rules: reviewers,      |
                    | job starts at once |      |   branch = main        |
                    +--------------------+      | job WAITS, no runner,  |
                                                | no secrets, until all  |
                                                | rules pass             |
                                                +------------------------+
```

**In production.** A team serving an LLM application keeps two cloud roles: one that can update the staging service and one that can update production. The production role's credentials are reachable only from the `production` environment, which requires one approval from the on-call group, prevents self-review and accepts only `main`. An engineer who edits a workflow on a feature branch to "quickly deploy" gets a job that fails the branch rule before any runner starts. The gate did its work without anybody reading the diff. With federated credentials the same idea is enforced by the cloud provider as well, because the token's subject names the environment; that is part of Chapter 21A.

### Creating environments

The documented interface path is the repository's **Settings**, then **Environments**, then **New environment** ([managing environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments); the interface changes, so trust the page in front of you). The same can be done with the REST API, which is what you want for infrastructure that is reviewed as code. The endpoint is `PUT /repos/{owner}/{repo}/environments/{environment_name}` and its body accepts `wait_timer`, `prevent_self_review`, `reviewers` (objects with `type` `User` or `Team` and a numeric `id`) and `deployment_branch_policy` (an object with the two booleans `protected_branches` and `custom_branch_policies`, which must have opposite values) ([REST: deployment environments](https://docs.github.com/en/rest/deployments/environments)).

```bash
# Create (or update) an environment without rules
gh api -X PUT repos/YOUR-ORG/inventory-api/environments/staging

# Secrets and variables scoped to it (gh asks for the secret value; it is not put on the command line)
gh secret set DEPLOY_TOKEN --env staging
gh variable set STAGING_URL --env staging --body "https://staging.example.com"

# Read back what exists
gh api repos/YOUR-ORG/inventory-api/environments --jq '.environments[].name'
gh secret list --env staging
```

`gh secret set` without `--body` reads the value from standard input or prompts for it, which keeps it out of your shell history (`gh secret set --help`). Lab 27.4 adds the reviewer and the branch rule to `production` with one `gh api` call and a JSON file.

## 20B.3 Deploying to staging: workflow 8

Read [`workflows/08-deploy-staging.yml`](../workflows/08-deploy-staging.yml) beside this section. It has two jobs.

```yaml
jobs:
  build:
    runs-on: ubuntu-24.04
    steps:
      # checkout, setup-uv, then:
      - run: uv sync --locked
      - run: uv run pytest
      - run: uv build
      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: inventory-api-dist
          path: dist/

  deploy-staging:
    needs: build
    runs-on: ubuntu-24.04
    environment:
      name: staging
      url: ${{ vars.STAGING_URL }}
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: inventory-api-dist
          path: dist/
      - run: bash scripts/deploy.sh staging
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

(The file itself has more: timeouts, `persist-credentials: false`, a job summary. This excerpt keeps what the argument needs.)

Four decisions are worth defending in a review.

**Build once, deploy what was built.** The deploy job does not run `uv build` again. It downloads the artifact the build job uploaded. Every job starts on a fresh machine, so the artifact is the only way the bytes travel, and it is also the point: the thing that was tested is the thing that is deployed. `actions/download-artifact` v8 fails by default when the downloaded content does not match the digest recorded at upload ([README](https://github.com/actions/download-artifact/blob/v8.0.1/README.md)). The same idea in plain Git: the same commit always produces the same archive bytes, and a digest detects any change.

<!-- snippet: ch20b/lab-27-2-artifact-digest/01-same-bytes -->
```text
$ git archive --format=tar --prefix=warehouse-api/ HEAD | shasum -a 256
28e6e91f0be5134ce817c81ab4dfb7e7e0ac69ac7cd756cb8859f27c4746d1e2  -
$ git archive --format=tar --prefix=warehouse-api/ HEAD | shasum -a 256
28e6e91f0be5134ce817c81ab4dfb7e7e0ac69ac7cd756cb8859f27c4746d1e2  -
$ git archive --format=tar --prefix=warehouse-api/ v1.1.0 | shasum -a 256
1581f1ac4facda70544419ab7165fd84af4c05ce715e387aa9c44d4a38eddd44  -
```
<!-- /snippet -->

The first two digests are equal because `git archive` of one commit is deterministic; the third differs because `v1.1.0` is another commit. A build tool is not always this reproducible, which is the reason to move the built file between jobs and not to rebuild it.

**The environment belongs to the job that deploys.** Only `deploy-staging` names the environment. The build job cannot read `DEPLOY_TOKEN`, because an environment secret is "only available to workflow jobs that reference the environment". Test code and build scripts, including those of your dependencies, never run in a job that holds a deployment credential.

**The secret reaches the script through `env`.** The expression `${{ secrets.DEPLOY_TOKEN }}` is placed in the step's `env` mapping and the script reads `$DEPLOY_TOKEN`. It is never interpolated into the text of a `run` command. Chapter 21A explains why that difference is a security boundary.

**`environment.url`.** The URL is shown with the deployment on GitHub. It may be an expression; here it comes from an environment variable, so the workflow file contains no host name.

What changes when you push to `main` with this workflow installed:

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged | unchanged | unchanged | unchanged | `refs/remotes/origin/main` moves to the pushed commit | `refs/heads/main` moves | a workflow run for the `push` event at the new commit; one artifact; one deployment record and status for `staging`; a check on the commit for each job |

Every job that references an environment creates a deployment object, unless `deployment: false` is set under `environment` (added on 19 March 2026; required reviewers and wait timers still apply, and it cannot be combined with custom protection rules) ([control deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments#using-environments-without-deployments)). Use that form for a job that needs an environment's secrets but deploys nothing, for example an integration test against a staging database.

**What a deployment contains.** Before you approve or trigger a deployment, ask Git what it adds to what is running. If staging runs `v1.1.0` and the run is for the tip of `main`:

<!-- snippet: ch20b/lab-27-3-deploy-range/01-range -->
```text
# Staging runs v1.1.0. A push to main is about to deploy the tip of main.
$ git log --oneline v1.1.0..main
57c8425 Add the lock file
197d992 Document the release runbook
$ git diff --stat v1.1.0 main
 docs/runbook.md | 4 ++++
 uv.lock         | 6 ++++++
 2 files changed, 10 insertions(+)
$ ./scripts/deploy.sh staging
would deploy 57c8425 to staging
```
<!-- /snippet -->

Two commits and two files. This is the question "what am I about to ship?" answered with a two-dot range, and it is worth one line in every deployment's job summary.

## 20B.4 Promotion to production: workflow 9

[`workflows/09-environments.yml`](../workflows/09-environments.yml) adds a third job.

```yaml
  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-24.04
    concurrency:
      group: production
      cancel-in-progress: false
    environment:
      name: production
      url: ${{ vars.DEPLOY_URL }}
    steps:
      # checkout and download-artifact as in deploy-staging, then:
      - run: bash scripts/deploy.sh production
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

The two deploy jobs are textually almost the same. The difference is on GitHub: `staging` and `production` each have a variable `DEPLOY_URL` and a secret `DEPLOY_TOKEN` with different values, and only `production` has rules. That is the pattern to aim for: the workflow describes the procedure, the environments hold what differs.

**What the reviewer sees.** From the documentation ([reviewing deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments)): the run shows the job as waiting; a required reviewer opens the run, chooses **Review deployments**, selects the environment and chooses **Approve and deploy** or **Reject**. A rejection fails the workflow. A job that nobody approves fails automatically after 30 days. Nothing in this was captured for the book; the labels are GitHub's and may change.

**What an approval releases.** The reviewer approves a job of a run, and a run is bound to one commit. The useful habit is to look at the range between what production has and what the run carries. In this transcript two refs under `refs/deployed/` stand in for GitHub's deployment records. They are the author's bookkeeping for the demonstration; GitHub keeps deployments as platform objects, not as refs.

<!-- snippet: ch20b/lab-27-4-promotion/01-waiting -->
```text
$ git for-each-ref --format="%(refname) %(objectname:short)" refs/deployed
refs/deployed/production c4b5de2
refs/deployed/staging 57c8425
# What an approval of the production job would release:
$ git log --oneline refs/deployed/production..refs/deployed/staging
57c8425 Add the lock file
197d992 Document the release runbook
```
<!-- /snippet -->

**What the branch rule guarantees.** A deployment branch rule compares the run's ref with name patterns. Since 8 December 2025, for runs triggered by `pull_request` events the ref that is evaluated is `refs/pull/<number>/merge`, and for `pull_request_target` it is the default branch ([changelog](https://github.blog/changelog/2025-11-07-actions-pull_request_target-and-environment-branch-protections-changes/)). A rule "Selected branches: `main`" therefore rejects pull request runs and runs on other branches. It says nothing about review of the commits on `main`; that is the job of the ruleset on `main` ([Chapter 18](ch18-branch-protection.md)). The gate is the combination: a ruleset that forces changes to `main` through reviewed pull requests, plus an environment that accepts only `main`, plus a required reviewer. Remove any one and there is a path around the other two.

```text
Observed behavior : A job that names "production" started without waiting for anybody.
Git state         : Irrelevant. The workflow file names the environment correctly.
Mechanism         : Protection rules are properties of the environment object on GitHub. The
                    environment had been created by the first run that named it, with no rules;
                    or the repository is private on a plan where reviewers do not apply.
Root cause        : The gate was assumed from the YAML and never configured or verified.
Why GitHub does it: Naming a missing environment creates it, so that a first deployment works
                    without an administrator; rules are an administrator's decision.
Correct fix       : Configure the rules; read them back with
                    gh api repos/OWNER/REPO/environments/production.
Prevention        : Create environments before the workflow that uses them; keep their
                    configuration in a reviewed script; test the gate with a harmless run.
```

## 20B.5 Concurrency groups

**In one sentence.** A concurrency group is a name; GitHub lets at most one run or job with that name execute at a time and decides what happens to the others.

**Analogy.** A single-track railway section with one waiting siding. One train is on the track. A second train waits in the siding. If a third arrives, the second is sent away and the third takes the siding. With `cancel-in-progress: true` the arriving train also removes the one on the track. The analogy breaks with `queue: max`, which turns the siding into a yard for up to 100 trains.

**Precisely.** From the [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency):

- `concurrency` can be set for the whole workflow or for one job. Its value is a group name, or a mapping with `group`, `cancel-in-progress` and `queue`.
- Default behavior: when a run is queued and another run in the same group is in progress, the new one is pending, and **any run already pending in that group is cancelled**. So by default at most one runs and one waits.
- `cancel-in-progress: true` also cancels the run in progress. It may be an expression.
- `queue: max` (since 7 May 2026) keeps up to 100 pending runs and processes them in order; combining it with `cancel-in-progress: true` is a validation error ([changelog](https://github.blog/changelog/2026-05-07-github-actions-concurrency-groups-now-allow-larger-queues/)).
- The group expression may use only the `github`, `inputs` and `vars` contexts at workflow level (a job-level group may also use `needs`, `strategy` and `matrix`).
- Group names are case-insensitive, and a group is not private to a workflow: two workflows that use the group name `deploy` share one track.
- The documentation states that ordering is not guaranteed.

Two patterns cover most needs, and they want opposite settings.

```yaml
# Continuous integration: only the newest commit of a branch or pull request matters.
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

```yaml
# Deployment: never interrupt one, never run two at once.
concurrency:
  group: production
  cancel-in-progress: false
```

The first includes the workflow name and the ref, so that only runs of the same workflow on the same ref compete. The second is deliberately the same for every ref. Workflow 8 uses the second form for the whole workflow; workflow 9 uses one group per environment at job level, so a staging deployment does not wait for a production approval.

**Inside `.git`.** Nothing changes. But the ref is the usual ingredient of a group name, and the refs of a repository are what make groups distinct:

<!-- snippet: ch20b/lab-28-1-broken-workflows/03-refs -->
```text
# Workflow 5. Each of these refs gets pushes; a concurrency group should tell them apart:
$ git for-each-ref --format="%(refname)" refs/heads
refs/heads/docs/rollback-steps
refs/heads/feature/safety-stock
refs/heads/main
```
<!-- /snippet -->

A group that contains `github.ref` gives each of these three its own track. A group named `ci` gives all of them one.

**Picture.** Default behavior, three pushes in quick succession into one group:

```text
 time --->
 run 1  [=========== in progress ===========]
 run 2        [ pending ]--X  cancelled when run 3 is queued
 run 3              [ pending .............][=== in progress ===]
```

**In production.** The default has a consequence for deployments that surprises teams: with three merges in ten minutes, the middle one is never deployed on its own. That is usually fine, because the third run contains the second merge. It is not fine when each run must happen, for example a database migration per commit. Then use `queue: max`, or design the deployment to be cumulative. The second trap is in reusable workflows: a called workflow sees the caller's name in `github.workflow`, so the same `${{ github.workflow }}-${{ github.ref }}` group with `cancel-in-progress: true` in caller and called workflow makes the called job cancel its own caller ([reusing workflow configurations](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations)). The documentation also notes that `concurrency` and `environment` are not connected: an environment does not serialise anything by itself.

## 20B.6 Reuse: reusable workflows, composite actions, container actions

Three mechanisms remove duplication. They differ in what they replace.

| | Reusable workflow | Composite action | Docker container action |
|---|---|---|---|
| Replaces | one or more whole jobs | several steps inside a job | one step |
| Defined in | a workflow file with `on: workflow_call` | `action.yml` with `runs.using: "composite"` | `action.yml` with `runs.using: "docker"` |
| Called with | `jobs.<job_id>.uses` | `steps[*].uses` | `steps[*].uses` |
| Chooses the runner | yes, each of its jobs has `runs-on` | no, runs on the caller's runner | no; needs a Linux runner |
| Can name an environment | yes | no | no |
| Secrets | declared under `on.workflow_call.secrets`, or `secrets: inherit` | cannot read the `secrets` context; pass values as inputs | receives inputs and `env` |
| Shows in the log as | separate jobs | one step | one step |

Sources: [reusing workflow configurations](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations), [custom actions](https://docs.github.com/en/actions/concepts/workflows-and-actions/custom-actions), [metadata syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/metadata-syntax). A JavaScript action is the fourth kind; since 23 September 2026 it runs on Node 24 only, and Chapter 20A covers it.

### Reusable workflows: workflow 11

**In one sentence.** A reusable workflow is a workflow file that another workflow calls as if it were a single job.

**Analogy.** A subcontractor who brings a whole crew, their own tools and their own site rules, and works to a written order (the inputs). You cannot give the crew individual instructions; you can only place the order and read the delivery note (the outputs). The analogy breaks on trust: the subcontractor works with your access badge, and can use less of its access than you gave, never more.

**Precisely.** [`workflows/11-reusable-workflow.yml`](../workflows/11-reusable-workflow.yml) declares its interface:

```yaml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      python-version:
        required: false
        type: string
        default: "3.13"
    secrets:
      deploy-token:
        required: false
    outputs:
      revision:
        description: Abbreviated ID of the commit that was deployed
        value: ${{ jobs.deploy.outputs.revision }}
```

and [`workflows/11-caller.yml`](../workflows/11-caller.yml) uses it:

```yaml
jobs:
  staging:
    uses: ./.github/workflows/11-reusable-workflow.yml
    with:
      environment: staging
    secrets:
      deploy-token: ${{ secrets.SHARED_DEPLOY_TOKEN }}

  report:
    needs: staging
    runs-on: ubuntu-24.04
    steps:
      - run: echo "Staging now runs revision $REVISION" >> "$GITHUB_STEP_SUMMARY"
        env:
          REVISION: ${{ needs.staging.outputs.revision }}
```

The rules, all from the two documentation pages linked above and the [how-to](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows):

- **Inputs** have a `type` of `boolean`, `number` or `string`. **Outputs** are declared at workflow level and mapped from job outputs; the caller reads them as `needs.<calling job>.outputs.<name>`.
- **A calling job is not a normal job.** It may contain only `name`, `uses`, `with`, `secrets`, `strategy`, `needs`, `if`, `concurrency`, `permissions` and `cache-mode`. It has no `runs-on` and no `steps`. No context or expression is allowed in `uses`.
- **Where the file comes from.** `./.github/workflows/file.yml` is the same repository at the commit of the run. `owner/repo/.github/workflows/file.yml@ref` is another repository; pin `ref` to a full commit ID for the reason every action is pinned. Since 30 July 2026 the documentation recommends `$/.github/workflows/file.yml` for the same repository on github.com; it needs runner 2.336.0 or later and does not exist on GitHub Enterprise Server ([changelog](https://github.blog/changelog/2026-07-30-reference-same-repository-actions-with-self-repository-syntax/)). Files in subdirectories of `.github/workflows` cannot be called.
- **Secrets** pass only one level: a workflow called by a called workflow needs them passed again. `secrets: inherit` passes all of the caller's secrets and works within one organization or enterprise. Environment secrets cannot be passed by the caller, "as `on.workflow_call` does not support the `environment` keyword": the called job names the environment, as `deploy` does with `environment: ${{ inputs.environment }}`.
- **`env` does not cross.** Variables in the caller's workflow-level `env` are not visible in the called workflow. Use inputs, or configuration variables in `vars`.
- **Permissions only narrow.** The called workflow's `GITHUB_TOKEN` permissions can be reduced, not raised, relative to the caller's.
- **The `github` context is the caller's.** Event, ref, commit and `github.workflow` are those of the calling workflow. Billing is the caller's too.
- **Limits.** Up to ten levels of workflows (the top-level caller and nine below it) and at most 50 unique reusable workflows called from one workflow file, since 6 November 2025 ([changelog](https://github.blog/changelog/2025-11-06-new-releases-for-github-actions-november-2025/)).
- **Check names.** A required status check for a job in a called workflow is named `<calling job name> / <called job name>` ([Chapter 18, section 18.8](ch18-branch-protection.md)). With the two files above, the check is `Staging / Test, build and deploy`. Renaming either job silently breaks a rule that requires the old name.

> **Unverified.** How secrets of the environment that a called job names appear in that job when the caller passes named secrets and does not use `secrets: inherit` is not spelled out on the pages read for this chapter. Workflow 11 avoids the question: the caller passes a repository secret, and the called file documents it. Verify the behavior in your repository before you depend on it.

**Inside `.git`.** Both files are ordinary blobs in the commit. With the `./` form, the run uses the called file from the same commit as the caller. So a branch that changes the called file tests its own version, and `main` keeps using the old one until the merge:

<!-- snippet: ch20b/lab-27-5-reusable-ref/01-two-versions -->
```text
$ git ls-files .github/workflows
.github/workflows/deploy.yml
.github/workflows/reusable-deploy.yml
$ git grep -n "uses:" main -- .github/workflows/deploy.yml
main:.github/workflows/deploy.yml:9:    uses: ./.github/workflows/reusable-deploy.yml
$ git diff --stat main ci/python-version
 .github/workflows/reusable-deploy.yml | 4 ++++
 1 file changed, 4 insertions(+)
$ git grep -c "python-version" main ci/python-version -- .github/workflows/reusable-deploy.yml
ci/python-version:.github/workflows/reusable-deploy.yml:1
```
<!-- /snippet -->

`git grep -c` finds the new input only on the branch. A caller on `main` that already passes `python-version` would be passing an input that the called file on `main` does not declare. Caller and called file must agree in one commit when they live in one repository, and across a pinned ref when they do not.

**Re-runs.** Re-running all jobs resolves a reference that is not a commit ID again; re-running failed or selected jobs uses the same commit of the called workflow as the first attempt ([reference](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations#behavior-of-reusable-workflows-when-re-running-jobs)). A reusable workflow referenced as `@main` can therefore differ between a first run and a full re-run.

**In production.** A platform team owns one deploy workflow in a central repository. Forty service repositories call it at a pinned commit and pass an environment name. A change to the deployment procedure is one reviewed pull request, rolled out by Dependabot updates of the pin. That one file then runs with deployment credentials in forty repositories, so its repository needs the strictest ruleset in the organization.

### Composite actions

A composite action packages steps. A minimal `action.yml`, placed for example in `.github/actions/setup-project/action.yml`:

```yaml
name: Set up the project
description: Install uv and the locked dependencies
inputs:
  python-version:
    description: Python version to use
    required: false
    default: "3.13"
runs:
  using: "composite"
  steps:
    - uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
      with:
        python-version: ${{ inputs.python-version }}
    - run: uv sync --locked
      shell: bash
```

A job uses it after a checkout with `uses: ./.github/actions/setup-project`. The documented rules that differ from workflow steps: every `run` step must state its `shell`; inputs are read as `${{ inputs.name }}`; outputs need a `value` that maps to a step output; the `secrets` context is not available, so a secret must arrive as an input; and the parallel-step keywords of June 2026 cannot be used inside a composite action. In the log the whole action is one step, which makes a failure inside it harder to locate than the same steps written out.

### Docker container actions

```yaml
name: Check the migration files
description: Run the migration linter in its own image
inputs:
  directory:
    description: Directory that holds the migrations
    required: true
runs:
  using: "docker"
  image: "Dockerfile"
  args:
    - ${{ inputs.directory }}
```

The runner builds the image from the `Dockerfile` beside `action.yml` and runs it with the arguments; inputs also arrive as environment variables named `INPUT_<NAME>`. It needs a Linux runner, and the documentation notes it is slower than the other kinds because the image is built or pulled first. Use it when the tool needs an operating system environment you do not want on the runner; otherwise prefer a composite action.

**Which one.** Steps that repeat inside jobs: composite action. A whole job, or a job that needs an environment, a runner choice or secrets: reusable workflow. Neither, when the duplication is two short blocks in one file: YAML anchors (supported since 18 September 2025) or plain repetition are easier to read and to debug.

## 20B.7 Publishing a container image, and release automation in outline

**The image.** Workflow 6 from Chapter 20A, `workflows/06-docker-image.yml`, builds and pushes an image to the GitHub container registry at `ghcr.io`. The delivery-relevant facts, from [publishing Docker images](https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images) and the Phase 0 report:

- The job authenticates with the `GITHUB_TOKEN` and needs `packages: write`; the documentation recommends the token over a personal access token. Publishing from a workflow with that token is also, in the documentation's words, the easiest way to connect the package to the repository.
- `docker/metadata-action` derives tags and labels from the Git ref and commit; `docker/build-push-action` builds and, with `push: true`, pushes. By default that action builds from the Git context, not from the checked-out directory, so files changed by earlier steps are ignored unless `context: .` is set ([README](https://github.com/docker/build-push-action/blob/v7.4.0/README.md)).
- An image is identified by its digest, not by a tag. A tag such as `latest` or `main` is a movable name, exactly like a branch. Deploy by digest, and record the digest and the commit together. `actions/attest` can attach signed build provenance to the digest (Chapter 21B).

An image tag should identify one commit. Git can tell you whether a working tree is exactly a commit and what that commit is called relative to the release tags:

<!-- snippet: ch20b/lab-27-1-image-identity/02-failure -->
```text
# A build from a working tree that differs from the commit it claims to be:
$ printf '\n# local tweak\n' >> src/warehouse/rules.py
$ git status --short
 M src/warehouse/rules.py
$ git describe --tags --match 'v*' --dirty
v1.1.0-2-g57c8425-dirty
```
<!-- /snippet -->

`-dirty` is Git saying that the working tree differs from HEAD. A runner's checkout is clean, which is one reason to build release images in CI and not on a laptop. The sample project's Dockerfile could not be built while this book was written (no image pulls); Lab 27.1 has you run it.

**Releases, in outline.** A release pipeline is three facts and one trap.

- A release is a GitHub object on a Git tag ([Chapter 15](ch15-github.md)). In a job, `gh release create "$TAG" dist/* --verify-tag --generate-notes` with `GH_TOKEN` set and `contents: write` creates it; `--verify-tag` refuses to invent a tag that does not exist ([using the GitHub CLI in workflows](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-github-cli), `gh release create --help`).
- With immutable releases, create a draft, attach every asset, then publish ([immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)).
- Tools such as [release-please](https://github.com/googleapis/release-please-action/blob/v5.0.0/README.md) derive the release from conventional commit messages. It is named as a concept and was not run for this book.
- **The trap.** Events caused by the `GITHUB_TOKEN` do not start new workflow runs, with narrow exceptions ([GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token)). A workflow that creates a tag or a release with the job token will not trigger your separate `on: release` or tag-push workflow. Either chain the work as jobs of one workflow with `needs`, or create the tag with a GitHub App token.

A release job that derives the version from a tag also needs the tags, which leads to section 20B.12.

## 20B.8 GitHub-hosted runners

**In one sentence.** A GitHub-hosted runner is a fresh virtual machine, built from a published image, that runs one job and is then destroyed.

**Precisely.** `runs-on` selects it by label. The facts below are from the [hosted runners reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) and the [runner-images repository](https://github.com/actions/runner-images/blob/main/README.md) as recorded in the Phase 0 report.

| Label on 1 October 2026 | Image | Change in 2026 |
|---|---|---|
| `ubuntu-latest` | Ubuntu 24.04 | migrates to Ubuntu 26.04 between 19 October and 19 November 2026 ([changelog](https://github.blog/changelog/2026-09-17-ubuntu-26-generally-available-and-latest-migration/)) |
| `windows-latest` | Windows Server 2025 with Visual Studio 2026 | Visual Studio 2026 since June 2026 |
| `macos-latest` | macOS 26 on arm64 | moved from macOS 15 in June and July 2026 |
| `ubuntu-24.04`, `ubuntu-26.04`, `windows-2022`, `macos-15`, `macos-26` | the named version | fixed labels |
| `ubuntu-22.04` | Ubuntu 22.04 | deprecated since 17 September 2026, unsupported from 17 April 2027 ([announcement](https://github.com/actions/runner-images/issues/14254)) |
| `macos-14` | macOS 14 | unsupported from 2 November 2026, with brownouts in October ([announcement](https://github.com/actions/runner-images/issues/13518)) |
| `ubuntu-24.04-arm`, `windows-11-arm` | arm64 | usable in private repositories since 29 January 2026 |
| `ubuntu-slim` | one CPU, runs the job in a container | jobs limited to 15 minutes |

`ubuntu-20.04`, `windows-2019` and `macos-13` no longer exist.

A `-latest` label is a moving name, the runner equivalent of a branch. A migration is rolled out gradually over weeks, so two runs of one workflow on the same day can get different images. Images are also rebuilt weekly, so tool versions inside a fixed label move too: in May 2026 Node 20 left the images and the default `node` became 22 ([announcement](https://github.com/actions/runner-images/issues/14029)). The workflows of this course therefore use `ubuntu-24.04` and install their tools with setup actions at stated versions. The cost of pinning is that you must move the label yourself before the image retires; put the retirement dates in your calendar. The "Set up job" section of a run's log names the image the job received; the Phase 0 notes did not verify that section separately, so read it in your own run.

**Hardware.** Standard Linux and Windows runners have 4 CPUs and 16 GB of memory in public repositories and 2 CPUs and 8 GB in private ones, with 14 GB of disk in both; macOS arm64 runners have 3 CPUs and 7 GB. A test suite that fits in a public repository can run out of memory or time after the repository is made private. Linux and macOS runners allow `sudo` without a password.

**In production.** A model-evaluation job that fits in the team's public mirror is killed in the private repository, with identical code. Ask first for the visibility of the repository, then for the label. GPU and larger runners exist for this; they are billed per minute on Team and Enterprise plans and are never covered by included minutes ([larger runners](https://docs.github.com/en/actions/reference/runners/larger-runners)).

## 20B.9 Self-hosted runners

**In one sentence.** A self-hosted runner is the same runner program on a machine you operate, which asks GitHub for jobs and runs them with whatever access that machine has.

**Analogy.** Lending your workshop to anyone who holds a work order. A GitHub-hosted runner is a rented workshop that is demolished after each job. Yours stays: tools, leftovers and everything a previous visitor hid there. The analogy breaks in that you choose who may write work orders, and that choice is the whole security question.

**Precisely.**

- **Risk.** GitHub's [secure use reference](https://docs.github.com/en/actions/reference/security/secure-use#hardening-for-self-hosted-runners) says self-hosted runners "should almost never be used for public repositories", because anyone can open a pull request that runs code on them, and it extends the warning to private repositories where anyone with read access can fork and open a pull request. A hosted runner is a clean machine per job; a persistent self-hosted runner "can be persistently compromised by untrusted code in a workflow". On a self-hosted runner an environment does not isolate secrets from other jobs on the same machine.
- **Ephemeral runners.** Registering with `./config.sh --ephemeral` gives a runner that takes one job and is removed. Just-in-time runners are created through the REST API and also run at most one job. GitHub recommends autoscaling with ephemeral runners and advises against autoscaling persistent ones ([self-hosted runners reference](https://docs.github.com/en/actions/reference/runners/self-hosted-runners#ephemeral-runners-for-autoscaling)). The documentation adds that reusing hardware for just-in-time runners can still expose information from the environment: "ephemeral" must include the disk.
- **Actions Runner Controller** is the Kubernetes operator GitHub documents as the reference implementation for scale sets of ephemeral runners ([concept](https://docs.github.com/en/actions/concepts/runners/actions-runner-controller)).
- **Runner groups** restrict which repositories may send jobs to which runners, and a job selects one with `runs-on: { group: name }`. They are available to organizations on every plan since 17 October 2024 ([changelog](https://github.blog/changelog/2024-10-17-actions-runner-groups-now-available-for-organizations-on-free-plan/)). The risk is a group open to "all repositories": every repository in the organization, including the least reviewed one, can run code on the machines that can reach production.
- **Versions.** Since 29 September 2026 a runner older than 2.329.0 cannot register on github.com, and a runner must install each new release within 30 days or it stops receiving jobs ([changelog](https://github.blog/changelog/2026-09-28-self-hosted-runner-version-enforcement-date-has-moved/)). This bites fleets built from a fixed image with updates disabled.
- **Queueing.** A job waits until a matching runner is online and fails after 24 hours in the queue; a self-hosted job may run for up to five days ([limits](https://docs.github.com/en/actions/reference/limits)).

**In production.** An ML team runs GPU evaluation on its own machines because hosted GPU minutes are expensive. The defensible design: ephemeral runners in a runner group that only the evaluation repository may use; workflows on those runners triggered only by `push` to protected branches and by `workflow_dispatch`, never by `pull_request` from forks; no long-lived cloud credentials on the machine.

## 20B.10 Limits and billing

Limits that shape designs, from [Actions limits](https://docs.github.com/en/actions/reference/limits) unless linked otherwise:

| Limit | Value |
|---|---|
| Job on a GitHub-hosted runner | 6 hours (`timeout-minutes` defaults to 360) |
| Workflow run, including waiting for approval | 35 days |
| Environment approval | fails after 30 days without approval |
| Matrix | 256 jobs per run |
| Re-runs | 50 per workflow run, within 30 days of the first run ([changelog](https://github.blog/changelog/2026-04-10-actions-workflows-are-limited-to-50-reruns/)) |
| Reusable workflows | 10 levels; 50 unique called workflows per file |
| Concurrent jobs on standard runners | Free 20, Pro 40, Team 60, Enterprise 500; macOS 5 (50 on Enterprise) |
| Cache | 10 GB per repository without charge; entries unused for 7 days are evicted |
| Artifacts and logs | 90 days by default; since 1 October 2026 the same setting also removes checks, runs and statuses ([changelog](https://github.blog/changelog/2026-08-27-actions-retention-will-cover-checks-workflow-runs-and-statuses/)) |

Billing, from [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions) and [runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing):

- Standard hosted runners are free in public repositories. Self-hosted runners are free.
- Private repositories include 2,000 minutes per month on Free, 3,000 on Pro and Team, 50,000 on Enterprise Cloud, and 500 MB, 1 GB, 2 GB and 50 GB of artifact storage, which is shared with GitHub Packages.
- List prices per minute since 1 January 2026: Linux 2-core $0.006, Linux arm64 2-core $0.005, `ubuntu-slim` $0.002, Windows 2-core $0.010, macOS $0.062. Each job is rounded up to a whole minute.
- Storage beyond the allowance: artifacts $0.25 and cache $0.07 per GB per month.
- Larger runners are always billed, in public repositories too.
- A reusable workflow is billed to the caller. Time spent in a wait timer is not billed.

> **Unverified.** How Windows and macOS minutes consume the *included* minutes is not stated on any 2026 page the Phase 0 research could fetch. Older material gives multipliers of 2 for Windows and 10 for macOS; the old multiplier page now redirects to the price list. Do not quote a multiplier. Read your own usage in the billing settings.

> **Version note.** Older behavior: tutorials quote pre-2026 prices. Current behavior: prices were cut by up to 39% on 1 January 2026. Announced and not in effect: a charge of $0.002 per minute for self-hosted runners, announced on 16 December 2025 for 1 March 2026 and then postponed without a new date ([announcement and postponement](https://github.blog/changelog/2025-12-16-coming-soon-simpler-pricing-and-a-better-experience-for-github-actions/)). Recommended: check the price page before you write a cost estimate.

The cost levers follow from the rules: cancel superseded CI runs with a concurrency group; prefer one job with several steps over many one-step jobs, because each job rounds up; keep macOS for what needs macOS, at roughly ten times the Linux price; use `ubuntu-slim` for glue jobs; shorten artifact retention. Path filters also save minutes, and section 20B.13 shows what they cost you.

## 20B.11 The investigation order for a failing workflow

A failing run tempts you to open the red step and start reading. Do that last but three. The order below goes from "did the right thing start at all" to "what did it say", because an answer early in the list makes everything after it irrelevant.

| # | Question | What to look at |
|---|---|---|
| 1 | **Workflow.** Which workflow file, from which commit, defined this run? | `gh run view <id> --json workflowName,headSha,headBranch,event`; `gh workflow view <file> --yaml --ref <branch>`. `schedule`, `issue_comment` and `workflow_run` use the file on the default branch. `workflow_dispatch` can be triggered only if the file exists on the default branch, and the run is dispatched against the branch or tag you choose (Chapter 20A, section 20A.4) |
| 2 | **Event.** What triggered it, and which ref and commit did the job check out? | `push` builds the pushed commit; `pull_request` builds `refs/pull/N/merge`; a re-run reuses the original commit and ref |
| 3 | **Permissions.** What could the token do? | top-level and job-level `permissions`; unlisted scopes are `none`; fork and Dependabot runs get a read-only token |
| 4 | **Runner.** Which image, which size? | `runs-on`, the image named at the top of the job log, public or private repository |
| 5 | **Environment.** Did the job reference one, and did its rules pass? | waiting, rejected, wrong branch, or an environment created by accident |
| 6 | **Dependencies.** Were the same versions installed as locally? | lock file, `--locked`, versions printed by setup steps |
| 7 | **Secrets.** Were they present? | an unset or withheld secret is an empty string, not an error |
| 8 | **Action versions.** Which commit of each action ran? | the pins; an old major on Node 24; a moved tag |
| 9 | **Logs.** What did the failed step print? | `gh run view <id> --log-failed` |
| 10 | **Artifacts.** Were the expected files produced and passed on? | `gh run download <id>`; names; expiry |
| 11 | **Cache.** What was restored, under which key? | the cache step's log; `gh cache list --key <prefix>` |
| 12 | **Concurrency.** Was the run cancelled or replaced by another? | conclusion `cancelled`; the group name; `gh run list --workflow <file>` |

Steps 1 and 2 remove the most confusion for the least effort. `gh run view` prints the event, the branch and the commit ID; compare that ID with `git rev-parse HEAD` on your machine before you compare anything else. The method is applied to a constructed case in Lab 28.2 and summarised as a runbook in the [GitHub Actions guide](../guides/github-actions-guide.md).

## 20B.12 "Passes locally, fails on GitHub Actions"

The documented causes, from section 13 of the Phase 0 report. All rows are GitHub Actions behavior except the last two, which are Git.

| Cause | Mechanism | Remedy |
|---|---|---|
| Shallow, tagless clone | `actions/checkout` fetches one commit and no tags, so `git describe` and tag-derived versions fail ([README](https://github.com/actions/checkout/blob/v7.0.1/README.md)) | `fetch-depth: 0` |
| The job is not testing the pushed commit | On `pull_request` the job checks out `refs/pull/N/merge`, a merge of the head into the current base, in detached HEAD; it does not run at all while the pull request conflicts ([events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#how-the-merge-branch-affects-your-workflow)) | merge or rebase the base locally to reproduce |
| Missing secrets | Not passed to runs from forks or from Dependabot; the token is read-only; an unset secret is an empty string ([using secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)) | fork-safe jobs; never `pull_request_target` as a shortcut (Chapter 21A) |
| Shell differences | The implicit shell on Linux and macOS is `bash -e` without `pipefail`; `shell: bash` adds `-o pipefail`; in a job container the default is `sh`; on Windows it is PowerShell ([shell](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepsshell)) | state the shell |
| Moving images and tools | Weekly image rebuilds; every `-latest` label moved in 2026 | fixed labels, setup actions with versions |
| Old action majors | Actions written for Node 20 now run on Node 24 ([changelog](https://github.blog/changelog/2026-09-23-node-20-is-no-longer-available-in-github-actions/)) | current majors |
| Required check stays pending | A workflow skipped by a filter or `[skip ci]` never reports ([skipping runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs)) | require an aggregate job (20B.13) |
| Runs cancelled | A newer run in the same concurrency group | workflow name and ref in the group |
| Stale or missing cache | A cache is immutable per key; `restore-keys` restore the most recent prefix match; pull request caches are scoped to the merge ref ([dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching)) | hash of the lock file in the key |
| Out of memory or time | Smaller runners in private repositories; six-hour limit | split or resize |
| Environment differences | `CI=true` is set; steps share no shell state; every job is a new machine ([variables](https://docs.github.com/en/actions/reference/workflows-and-actions/variables)) | `GITHUB_ENV`, outputs, artifacts |
| A workflow that never fires | Events made with the `GITHUB_TOKEN` start no runs; scheduled workflows are disabled after 60 days without repository activity in public repositories | a GitHub App token, or jobs chained with `needs` |
| Case sensitivity (Git) | macOS and Windows filesystems ignore case by default; a Linux runner does not | fix the names in Git |
| Line endings (Git) | CRLF committed, or converted on checkout by `core.autocrlf` | `.gitattributes` |

> **Unverified.** The official Actions pages read for the Phase 0 report do not state the time zone and locale of hosted runners, whether Windows runners check out with CRLF by default, or whether the hosted runners' filesystems are case-sensitive. Only the Git mechanisms below are sourced, from Git's documentation and from real runs. Linux filesystems being case-sensitive is the general rule this chapter relies on.

Three of these are Git, and can be reproduced on your machine.

### A shallow clone has no tags to describe

On your laptop the version comes out of the history:

<!-- snippet: ch20b/shallow-describe/01-laptop -->
```text
# Your clone: full history, all tags.
$ git log --oneline --decorate
57c8425 (HEAD -> main) Add the lock file
197d992 Document the release runbook
c4b5de2 (tag: v1.1.0) Add the deploy workflows
3c8340d Add reorder thresholds
e797c71 (tag: v1.0.0) Add the deploy script
91fe9ab Add stock rules and their checks
$ git describe --tags --match 'v*'
v1.1.0-2-g57c8425
```
<!-- /snippet -->

`v1.1.0-2-g57c8425` reads: two commits after the tag `v1.1.0`, at commit `57c8425`. Now the clone a job gets by default, imitated with `git clone --depth 1 --no-tags` (the action's documented defaults are `fetch-depth: 1` and `fetch-tags: false`):

<!-- snippet: ch20b/shallow-describe/02-runner -->
```text
# A clone with one commit and no tags, which is what the checkout action fetches by default:
$ cd ..
$ git clone --quiet --depth 1 --no-tags "file://$PWD/warehouse-api" runner
$ cd runner
$ git log --oneline --decorate
57c8425 (grafted, HEAD -> main, origin/main, origin/HEAD) Add the lock file
$ git tag --list
$ git rev-parse --is-shallow-repository
true
$ git describe --tags --match 'v*'
fatal: No names found, cannot describe anything.
[exit status: 128]
```
<!-- /snippet -->

One commit, marked `grafted` because its parent is deliberately missing, no tags, and `git describe` exits with status 128. Fetching the tags alone does not help:

<!-- snippet: ch20b/shallow-describe/03-tags-without-history -->
```text
# Fetching the tags alone, still at depth 1, brings the tag objects but not the path to them:
$ git fetch --quiet --depth 1 origin "refs/tags/*:refs/tags/*"
$ git tag --list
v1.0.0
v1.1.0
$ git describe --tags --match 'v*'
fatal: No tags can describe '57c8425908f43c74c14b2642edb59e0f99dac38c'.
Try --always, or create some tags.
[exit status: 128]
$ git rev-list --count HEAD
1
```
<!-- /snippet -->

The tags exist now, but `git describe` walks from HEAD through parents to find a tagged commit, and the history is one commit long. The error changed from "No names found" to "No tags can describe"; both mean the same root cause. With full history it works:

<!-- snippet: ch20b/shallow-describe/04-full-history -->
```text
# With the whole history the tag is reachable from HEAD again:
$ git fetch --quiet --unshallow --tags
$ git rev-parse --is-shallow-repository
false
$ git rev-list --count HEAD
6
$ git describe --tags --match 'v*'
v1.1.0-2-g57c8425
```
<!-- /snippet -->

```text
Observed behavior : The version step fails in the job; the same command works on every laptop.
Git state         : .git/shallow lists the one fetched commit; refs/tags is empty.
Mechanism         : git describe needs a tag that is reachable from HEAD through parent links.
Root cause        : actions/checkout defaults to fetch-depth: 1 and fetch-tags: false.
Why it does this  : One commit is all most jobs need, and it is fast on a large repository.
Correct fix       : fetch-depth: 0 on the checkout step of the job that needs history.
Prevention        : Derive versions in one job; never add "|| echo 0.0.0" or --always to
                    make the error disappear, because that ships a wrong version.
```

### A name that differs only in case

<!-- snippet: ch20b/case-clash/01-works-here -->
```text
# Git recorded the name with a capital T. The loader asks for a lower-case name.
$ git config get core.ignorecase
true
$ git ls-files configs
configs/Thresholds.yaml
$ cat configs/thresholds.yaml
reorder:
  lead_days: 5
  safety_stock: 10
```
<!-- /snippet -->

Git recorded `Thresholds.yaml`. The code asks for `thresholds.yaml`, and on a default macOS volume the file opens. Git set `core.ignorecase` to `true` when it created the repository because it detected such a filesystem. Git's own lookup compares bytes, as a Linux filesystem does:

<!-- snippet: ch20b/case-clash/02-what-linux-sees -->
```text
# Git itself compares names byte by byte, as a case-sensitive filesystem does:
$ git cat-file -e HEAD:configs/thresholds.yaml
fatal: path 'configs/thresholds.yaml' exists on disk, but not in 'HEAD'
[exit status: 128]
$ git cat-file -e HEAD:configs/Thresholds.yaml
[exit status: 0]
```
<!-- /snippet -->

The fix must be a rename in Git, `git mv configs/Thresholds.yaml configs/thresholds.yaml`, committed and pushed. Renaming in Finder changes nothing that Git notices. The opposite accident is a commit made on Linux that contains both spellings; a Mac clone warns and checks out only one:

<!-- snippet: ch20b/case-clash/04-two-names -->
```text
# The other half of the problem: a commit made on Linux that holds both spellings.
$ git ls-files | grep -i readme
README.md
Readme.md
$ cd ..
$ git clone --quiet warehouse-api second-clone
warning: the following paths have collided (e.g. case-sensitive paths
on a case-insensitive filesystem) and only one from the same
colliding group is in the working tree:

  'README.md'
  'Readme.md'
$ ls second-clone | grep -i readme
Readme.md
```
<!-- /snippet -->

This transcript depends on a case-insensitive volume, the macOS default. On a case-sensitive volume the first `cat` fails and there is no collision warning.

### A script with CRLF line endings

<!-- snippet: ch20b/line-endings/01-symptom -->
```text
$ ./scripts/deploy.sh staging
env: bash\r: No such file or directory
[exit status: 127]
```
<!-- /snippet -->

The kernel read the first line and looked for an interpreter named `bash` followed by a carriage return. `git ls-files --eol` shows where the carriage returns live:

<!-- snippet: ch20b/line-endings/02-eol -->
```text
# i/ is the index (what is committed), w/ the working tree, attr/ the attributes in force.
$ git ls-files --eol scripts/deploy.sh README.md
i/lf    w/lf    attr/                 	README.md
i/crlf  w/crlf  attr/                 	scripts/deploy.sh
$ git config get core.autocrlf
```
<!-- /snippet -->

`i/crlf` means the committed blob itself contains CRLF. No attribute applies and `core.autocrlf` is unset, so nothing normalised it. The repair is a rule in the repository and a renormalisation of the index:

<!-- snippet: ch20b/line-endings/03-fix -->
```text
# Declare the rule in the repository, so that it does not depend on anybody's configuration:
$ printf '* text=auto\n*.sh text eol=lf\n' > .gitattributes
$ git add --renormalize .
$ git status --short
M  scripts/deploy.sh
?? .gitattributes
$ git commit -q -m "Normalise line endings; shell scripts are always LF"
$ git ls-files --eol scripts/deploy.sh
i/lf    w/crlf  attr/text eol=lf      	scripts/deploy.sh
```
<!-- /snippet -->

After the commit the index holds LF (`i/lf`) while this working tree still has the old bytes (`w/crlf`) until the file is checked out again. A fresh clone, which is what a runner makes, gets LF. Chapter 14C covers attributes in depth.

## 20B.13 Required checks that stay pending

The rules, from [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks) and [skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs); Chapter 18, section 18.8 gives the ruleset side.

| Situation | What the check reports | Merge |
|---|---|---|
| The workflow never started: path filter, branch filter, or `[skip ci]` in the commit message | nothing; the required check stays "pending" | blocked |
| The workflow started and the job was skipped by its `if` | success (`skipped` counts as passing) | allowed |
| A job was skipped because a job it `needs` failed | skipped, so it may not block | allowed, wrongly |
| The check ran on a `workflow_dispatch` run of the head branch | not evaluated for the pull request | blocked |
| A merge queue is used and the workflow lacks `on: merge_group` | nothing in the queue | blocked in the queue |

A path filter is evaluated on the pull request's three-dot diff. Git shows the list GitHub would test:

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

A workflow with `paths: ["src/**"]` starts for the second branch and not for the first. If its job is a required check, the documentation-only pull request waits forever. The filter also has edges: a push with more than 1,000 commits always runs the workflow, and with more than 3,000 changed files a match beyond the first 3,000 is not seen ([syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#git-diff-comparisons)).

The robust design, which the report labels an inference from these rules: do not filter the workflow. Start it always, decide inside which jobs to run with `if`, and require one aggregate job that always runs and fails when something it needs failed or was cancelled.

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

Require `all-checks` in the ruleset and nothing else. The matrix and the job list can then change without touching the rule. The `*` object filter, `contains` and `cancelled` are documented in the [expressions reference](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions), which also recommends `!cancelled()` over `always()`; `needs.<job_id>.result` is in the [contexts reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts).

## 20B.14 The debugging instruments

**Read the failure first.**

```bash
gh run list --workflow 08-deploy-staging.yml --limit 5
gh run view RUN_ID
gh run view RUN_ID --log-failed
gh run view RUN_ID --json event,headBranch,headSha,conclusion,jobs
gh run watch RUN_ID --exit-status
gh pr checks --watch
```

`--log-failed` prints the log of the failed steps only. `gh run watch` follows a run until it ends and, with `--exit-status`, exits non-zero when it fails, so it can be chained in a script. `gh pr checks` exits with status 8 while checks are pending. All flags are from the `--help` output of GitHub CLI 2.88.1.

**Re-run.** A re-run is not a new run. It uses "the same `GITHUB_SHA` and `GITHUB_REF` of the original event" and the privileges of the actor who triggered the original, is possible for 30 days, and at most 50 times ([re-running workflows and jobs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs)).

```bash
gh run rerun RUN_ID --failed
gh run rerun RUN_ID --failed --debug
gh run rerun --job JOB_ID
```

| Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|
| unchanged | unchanged | unchanged | unchanged | unchanged | unchanged | a new attempt of the same run, at the original commit and ref; new checks on that commit; for a deploy workflow, a new deployment of that commit |

The last cell is the danger. Re-running last week's deploy run deploys last week's commit over today's. Git can tell you whether a commit is behind what is already deployed:

<!-- snippet: ch20b/lab-27-3-deploy-range/02-failure -->
```text
# Somebody re-runs an old workflow run. A re-run uses the commit of the original run:
$ git switch --quiet --detach v1.1.0
$ ./scripts/deploy.sh staging
would deploy c4b5de2 to staging
# Is that commit behind what staging already had? (exit status 0 means yes)
$ git merge-base --is-ancestor HEAD main
[exit status: 0]
$ git log --oneline HEAD..main
57c8425 Add the lock file
197d992 Document the release runbook
```
<!-- /snippet -->

Exit status 0 from `git merge-base --is-ancestor HEAD main` means the commit of the re-run is an ancestor of `main`: the deployment would go backwards by the two commits listed. Use a re-run to retry a flaky step of the latest run, and a fresh run for everything else.

**Debug logging.** Two switches, each a repository secret or variable set to `true` (the secret wins if both exist): `ACTIONS_STEP_DEBUG` adds debug lines to step logs, and `ACTIONS_RUNNER_DEBUG` adds runner and worker diagnostic logs in the `runner-diagnostic-logs` folder of the downloaded log archive ([enable debug logging](https://docs.github.com/en/actions/how-tos/monitor-workflows/enable-debug-logging)). For one run, `gh run rerun --debug` or the checkbox on the re-run dialog does the same without leaving the switch on. Anyone who may run the workflow may enable it.

**Skipped jobs.** Since 29 January 2026 the log of a skipped job shows the original `if` expression and its expanded values ([troubleshooting](https://docs.github.com/en/actions/how-tos/troubleshoot-workflows#debugging-job-conditions)).

**Run and manage workflows.**

```bash
gh workflow list --all
gh workflow view 09-environments.yml --yaml
gh workflow run 09-environments.yml --ref main
gh workflow disable "Deploy through environments"
gh cache list --key Linux-inventory-api
gh cache delete --all
```

`gh workflow run` needs `on: workflow_dispatch` in the file on the default branch, and a run started this way does not satisfy a required check of a pull request.

**Do not print contexts carelessly.** Dumping `toJSON(github)` into a log is a documented debugging aid, and that context contains `github.token`. Print the fields you need.

## 20B.15 Linting, and what a local emulator cannot reproduce

Catch what can be caught before the push. `actionlint` checks workflow syntax, expression types and embedded shell ([README](https://github.com/rhysd/actionlint/blob/main/README.md)); the GitHub Actions language service in the editor does part of that while you type. Neither is installed for this course, and the course's own check is only that each file parses as YAML and has `on` and `jobs`, which finds indentation errors and nothing else:

```bash
python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" workflows/08-deploy-staging.yml
```

All six broken workflows of Lab 28.1 pass this check, and a linter would pass most of them too. A linter proves that a file is well formed. It cannot know that the history is shallow or that a secret is withheld.

`act` runs workflows locally in Docker containers. Its own documentation lists what it does not implement: `concurrency`, job `permissions`, `environment`, OIDC, `timeout-minutes`, `continue-on-error`, step summaries, and a complete `github` context ([unsupported functionality](https://nektosact.com/not_supported.html)). It is useful for the shell logic of steps and useless for exactly the topics of this chapter: gates, tokens, groups, runner images. Treat a green local run as evidence about your scripts, never about your deployment.

## 20B.16 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| Production deployed without approval | `gh api repos/OWNER/REPO/environments/production` shows no rules, or the name in the workflow is misspelled | configure the rules; correct the name; delete the stray environment | create environments first; review workflow changes through CODEOWNERS |
| A middle deployment never happened | default concurrency cancelled the pending run | `queue: max`, or cumulative deployments | choose the queue policy on purpose |
| CI runs of different branches cancel each other | the group lacks `github.ref` | add workflow name and ref | copy the two patterns of 20B.5 |
| Empty secret in a called workflow | secrets pass one level only, or the secret is an environment secret | pass it again; read it in the job that names the environment | keep the secret path short |
| Pull request waits for a check forever | the workflow was filtered out | aggregate job | never require a filterable workflow |
| Old code deployed | a re-run of an old run | start a new run | `git merge-base --is-ancestor` guard in the deploy script |
| Job killed after the repository became private | 2 CPUs and 8 GB | split the job or pay for a larger runner | note visibility in the runbook |

## 20B.17 When not to use it, and dangerous edge cases

- **Do not use an environment as your only production control.** It is enforced by GitHub. Credentials that also work from a laptop bypass it. Bind the credential to the environment at the cloud provider (Chapter 21A).
- **Administrators can bypass** protection rules unless that is switched off, and whoever can edit the environment can remove the rule. Know who that is.
- **Do not put `cancel-in-progress: true` on a deployment.** A deployment cancelled half-way leaves a state nobody designed.
- **Do not extract a reusable workflow for two callers.** Indirection costs debugging time; the check name changes and can break required checks.
- **Do not use self-hosted runners for public repositories**, and do not give a persistent runner credentials you would not give every contributor.
- **Do not make a job green by weakening it**: `continue-on-error`, `|| true`, `--always`, broader `restore-keys`. Each hides a cause from the next engineer.
- **A re-run is a time machine.** On a deploy workflow it is a rollback nobody announced.

## 20B.18 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `gh run view`, `gh run list`, `gh run watch`, `gh pr checks`, `gh workflow view`, `gh cache list` | 🟢 SAFE | nothing | not needed | not needed |
| `git describe`, `git ls-files --eol`, `git diff --name-only A...B`, `git merge-base --is-ancestor` | 🟢 SAFE | nothing | not needed | not needed |
| `git fetch --unshallow --tags` | 🟢 SAFE | adds objects and tags; removes `.git/shallow` | `git rev-parse --is-shallow-repository` | not needed |
| `git add --renormalize .` | 🟡 CAUTION | rewrites index entries to normalised line endings | `git ls-files --eol`; `git status` afterwards | `git restore --staged .` before committing |
| `gh workflow run` | 🟡 CAUTION | starts a run; on a deploy workflow, a deployment | read the file with `gh workflow view --yaml` | `gh run cancel`; deploy the previous commit |
| `gh run rerun` | 🟡 CAUTION | new attempt at the original commit | `gh run view RUN_ID --json headSha` and compare with `main` | start a new run from the current commit |
| `gh run cancel` | 🟡 CAUTION | stops a run, possibly mid-deployment | `gh run view` | re-run; check the target's state by hand |
| `gh secret set`, `gh variable set` | 🟡 CAUTION | overwrites the stored value; the old secret value cannot be read back | `gh secret list --env NAME` | set the previous value again from your secret store |
| `gh api -X PUT .../environments/NAME` | 🔴 DANGEROUS | replaces the environment's protection settings with the body sent. What it can destroy: the previous settings, required reviewers included, which exist nowhere else unless you saved them; the label is the one Chapter 15, section 15.22 gives every `gh api` call that is not a `GET`. Appropriate for environment rules kept as code | `gh api .../environments/NAME` | send the previous configuration again |
| `gh cache delete --all` | 🟡 CAUTION | removes every cache of the repository | `gh cache list` | caches are rebuilt by the next runs, slowly |

No command in this chapter destroys Git history. The irreversible effects are outside Git: a deployment that ran, a secret value overwritten.

## 20B.19 Version notes

> **Version note.** Older behavior: `concurrency` kept one pending run per group. Current behavior: the same by default, with `queue: max` for up to 100. Since: 7 May 2026. Recommended: `queue: max` only where every run must execute.

> **Version note.** Older behavior: same-repository workflows and actions referenced with `./`. Current behavior: `$/` is the recommended form on github.com. Since: 30 July 2026, runner 2.336.0. Recommended: `./` where GitHub Enterprise Server or older self-hosted runners must run the file.

> **Version note.** Older behavior: a deployment branch rule on a pull request run was evaluated against the head branch. Current behavior: against `refs/pull/N/merge`, and against the default branch for `pull_request_target`. Since: 8 December 2025.

> **Version note.** Older behavior: `ubuntu-latest` meant Ubuntu 22.04, then 24.04. Current behavior: 24.04, moving to 26.04 from 19 October 2026. Recommended: a fixed label.

> **Version note.** Older behavior: checks, runs and statuses were kept 400 days or more. Current behavior: they follow the Actions retention setting, 90 days by default. Since: 1 October 2026. The status-checks page that still says 400 days is flagged as a conflict in the Phase 0 report.

> **Outdated advice.** "Use `git reset --hard` and a force push to redo a deployment", and "add `pull_request_target` so that fork pull requests get the secrets". The first rewrites shared history to fix something that is not in Git; the second is the vulnerability class of Chapter 21A.

## 20B.20 Practice

- [Module 27 labs](../lab-manual/m27-build-package-deliver.md): Labs 27.1 to 27.5 run workflows 6, 7, 8, 9 and 11 in your practice repository `YOUR-ORG/inventory-api`.
- [Module 28 labs](../lab-manual/m28-runners-debugging-ci.md): Lab 28.1 has six broken workflows from `workflows/broken/`, each with a different documented root cause; Lab 28.2 applies the investigation order to a described failing run.
- Keep the [GitHub Actions guide](../guides/github-actions-guide.md) open while you work: it lists all twelve workflows, the authoring checklist and the debugging runbook.

## 20B.21 Interview questions

1. A job names `environment: production`. List everything that must be true on GitHub, outside the workflow file, for that to be a real gate.
2. Three merges land on `main` within five minutes and the deploy workflow uses `concurrency: production`. Which runs deploy, and why?
3. When would you choose a reusable workflow over a composite action, and what does each choice do to the names of required status checks?
4. Why can a caller not pass an environment secret to a reusable workflow, and where must the secret be read?
5. `git describe` works on every laptop and fails in the job. Explain the state of the runner's repository and give the minimal fix.
6. A pull request shows "waiting for status to be reported" and no run exists. Name three causes and the design that avoids all of them.
7. What exactly does `gh run rerun` re-run, and why is that dangerous for a deploy workflow?
8. Your CI bill rose after a repository became private and one job started timing out. What changed?
9. Make the case for and against self-hosted GPU runners for model evaluation, including the controls you would require.
10. A test passes on a Mac and fails on `ubuntu-24.04` with a file-not-found error. How do you prove the cause with Git alone?
11. In which order do you investigate a failed run, and why is the log not first?
12. What can a local emulator tell you about a deployment workflow, and what can it not?

## 20B.22 Sources

**Primary sources**

- GitHub Docs: [deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments), [managing environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments), [control deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments), [reviewing deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments), [REST: deployment environments](https://docs.github.com/en/rest/deployments/environments).
- GitHub Docs: [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [reusing workflow configurations](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations), [reuse workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows), [metadata syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/metadata-syntax), [custom actions](https://docs.github.com/en/actions/concepts/workflows-and-actions/custom-actions).
- GitHub Docs: [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [self-hosted runners](https://docs.github.com/en/actions/reference/runners/self-hosted-runners), [secure use](https://docs.github.com/en/actions/reference/security/secure-use), [limits](https://docs.github.com/en/actions/reference/limits), [billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions), [runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing).
- GitHub Docs: [dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching), [using secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets), [enable debug logging](https://docs.github.com/en/actions/how-tos/monitor-workflows/enable-debug-logging), [re-running workflows and jobs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs), [troubleshooting workflows](https://docs.github.com/en/actions/how-tos/troubleshoot-workflows), [skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs), [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks).
- Action documentation at the pinned versions: [actions/checkout v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md), [actions/cache v6.1.0](https://github.com/actions/cache/blob/v6.1.0/README.md), [actions/upload-artifact v7.0.1](https://github.com/actions/upload-artifact/blob/v7.0.1/README.md), [actions/download-artifact v8.0.1](https://github.com/actions/download-artifact/blob/v8.0.1/README.md), [astral-sh/setup-uv v10.2.0](https://github.com/astral-sh/setup-uv/blob/v10.2.0/README.md).
- GitHub CLI manual: [gh run view](https://cli.github.com/manual/gh_run_view), [gh run rerun](https://cli.github.com/manual/gh_run_rerun), [gh run watch](https://cli.github.com/manual/gh_run_watch), [gh workflow run](https://cli.github.com/manual/gh_workflow_run), and the `--help` output of the installed 2.88.1.
- The local Git manual: `git help describe`, `git help ls-files`, `git help gitattributes`, `git help config` (`core.ignoreCase`).

**Secondary sources**

- [actionlint](https://github.com/rhysd/actionlint/blob/main/README.md) and [act: unsupported functionality](https://nektosact.com/not_supported.html), third-party tools, not installed for this course.
- The GitHub changelog entries linked in the text for each dated change.

**Videos** (from the Phase 0 report, with its caveats)

- ["Complete GitHub Actions Course - From BEGINNER to PRO"](https://www.youtube.com/watch?v=Xwpi0ITkL3U), Sid Palas, DevOps Directive, 3 h 43 min, 24 September 2025. The most complete current free course; it has sponsor segments, says "branch protections" and never mentions rulesets, and pre-dates Node 24-only runners and `actions/checkout` v7.
- ["Introduction to GitHub Actions - Part 6 - Repository Rulesets"](https://www.youtube.com/watch?v=ZTbM-h9RZOo), Mickey Gousset, 15 min, 6 December 2024. A ruleset that requires a status check.

**Further reading**

- [Chapter 18](ch18-branch-protection.md), section 18.8, for required status checks from the ruleset side; [Chapter 21A](ch21a-actions-security.md) for the security model of everything in this chapter.
