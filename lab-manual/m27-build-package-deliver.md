# Module 27 labs: Build, package and deliver

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Read [Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md), sections 20B.2 to 20B.7, first. Answers to the questions are in [the solutions](../solutions/m27-lab-answers.md); write your own first. Every transcript under "Expected output", "Failure scenario" and "Recovery" is real output of a replay script in `labs/ch20b/`, and shows plain Git. Nothing in this file was run against GitHub: the workflow files were parse-checked and assembled from documented syntax, but the author did not execute them on GitHub. You do that here.

## How these labs work

Each lab has two parts.

**Part A is local and runs in the lab shell.** A setup script builds a small repository, `warehouse-api`, and you type the Git commands that show the repository state behind the delivery step: what identifies a build, what a deployment contains, which ref a rule sees. Your commit IDs match the transcripts, because the setup script uses the fixed lab clock.

**Part B is on GitHub and runs in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub. Part B uses the practice repository `YOUR-ORG/inventory-api` (the sample project, which you pushed to GitHub as its own repository in the Module 26 labs) with `uv.lock` committed. For Part B there is no captured output. What you should see is described from the linked documentation and from `gh <command> --help`; trust the page in front of you over the description.

Set these once in your normal shell:

```bash
ORG=your-practice-org
COURSE=/path/to/this/course          # the directory that contains labs/ and workflows/
cd /path/to/your/clone/of/inventory-api
```

Rules for Part B:

- The practice repository is public. Every secret in these labs is a dummy string such as `not-a-real-token`. Type it when `gh secret set` asks; never put a secret on a command line.
- If `main` is protected by a ruleset from earlier labs, "push to main" below means: push a branch, open a pull request, merge it.
- Workflows 7, 8, 9 and 11 all react to a push to `main`. To keep the picture clear, disable the ones a lab does not need with `gh workflow disable "<workflow name>"` and enable them again later with `gh workflow enable`. The help text of both commands names the workflow ID or the workflow name (the `name:` in the file) as the argument, so the labs use names.

In transcripts, a line `[exit status: N]` is added by the replay tool; in your shell, `echo $?` prints the same number.

## Lab 27.1: A container image that identifies its commit (workflow 6)

### Objective

Explain what ties a published image to one commit, and why a tag is not that tie. Publish an image from a release tag with `06-docker-image.yml` and read its digest.

### Prerequisites

Chapter 20B, section 20B.7; Chapter 20A's walk through workflow 6; Lab 26.6 completed, so `06-docker-image.yml` is in the practice repository.

### Setup

**Part A.**

```bash
bash labs/ch20b/setup-27-1-image-identity.sh
labs/shell m27-1
cd warehouse-api
```

**Part B.** Your clone of `inventory-api`, on an up-to-date `main`.

### Commands

**Part A (lab shell).**

```bash
git rev-parse HEAD
git status --porcelain
git tag --points-at HEAD
git describe --tags --match 'v*'
```

**Part B (normal shell).** Predict first: which tags will the image get for a push of the Git tag `v0.1.0`? Read the `tags:` input of the `docker/metadata-action` step in the workflow and write your prediction down.

```bash
git switch main && git pull
git tag -a v0.1.0 -m "Release 0.1.0"
git push origin v0.1.0
gh run list --workflow 06-docker-image.yml --limit 3
gh run watch RUN_ID --exit-status
gh run view RUN_ID --web
```

Take `RUN_ID` from the list. In the browser, read the job summary that the last step of the workflow writes: the digest and the list of tags.

### Expected output

**Part A.**

<!-- snippet: ch20b/lab-27-1-image-identity/01-identity -->
```text
$ git rev-parse HEAD
57c8425908f43c74c14b2642edb59e0f99dac38c
$ git status --porcelain
$ git tag --points-at HEAD
$ git describe --tags --match 'v*'
v1.1.0-2-g57c8425
```
<!-- /snippet -->

**Part B.** Described, not captured: `gh run list` shows a run of "Docker image" for the event `push`, started by the tag; the job summary shows one `sha256:` digest and several tags for `ghcr.io/<org>/inventory-api`. The Dockerfile was not built by the author. If the build fails, treat that as the lab: apply the investigation order of section 20B.11 and read `gh run view RUN_ID --log-failed`.

### What happened internally

Part A: `git status --porcelain` printed nothing, so the working tree is exactly the commit `git rev-parse HEAD` names. No tag points at HEAD, so `git describe` names the commit relative to the nearest tag: tag, number of commits since, abbreviated commit ID. That string identifies one commit as long as the tag does not move.

Part B: the tag push created a run whose `GITHUB_REF` is `refs/tags/v0.1.0`. The job's token had `packages: write` because the job asks for it. The metadata action computed tag names from the ref and the commit; the build action pushed one image and reported its digest. Git gained one tag object and one ref. GitHub gained a workflow run and a package version. The registry's tags are movable names; the digest is the content address of the image, as a commit ID is of a commit.

### Checkpoint

You can answer, without looking: which of the image's names will still mean the same bytes next month? If you said the digest, and the commit-derived tag as long as nobody overwrites it, continue.

### Failure scenario

Build from a working tree that is not the commit it claims to be.

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

`-dirty` is the only sign. An image built now and labelled with the commit ID would contain a line that is in no commit. On GitHub the equivalent accident is a moving tag: push another commit to `main` and the image tag `main` names a different digest, while a deployment that says "run `main`" silently changes.

### Recovery

<!-- snippet: ch20b/lab-27-1-image-identity/03-recovery -->
```text
$ git restore src/warehouse/rules.py
$ git describe --tags --match 'v*' --dirty
v1.1.0-2-g57c8425
# A release: tag the commit, and the name becomes the tag itself.
$ git tag -a v1.2.0 -m "Release 1.2.0"
$ git tag --points-at HEAD
v1.2.0
$ git describe --tags --match 'v*' --dirty
v1.2.0
```
<!-- /snippet -->

Restore the tree, and for a release give the commit a name that is meant to be permanent: an annotated tag. `git describe` then prints the tag itself.

### Verification

Part A: `git describe --tags --match 'v*' --dirty` prints `v1.2.0` with no suffix. Part B: the digest in the job summary of the tag run differs from the digest of the latest `main` run only if the commits differ; compare the two summaries and explain what you see.

### Questions

1. Why is "deploy the image tagged `main`" not a reproducible instruction, and what would you write instead?
2. The image job has `packages: write` in a job-level `permissions` block. What would be worse about putting it at the top of the file?
3. Workflow 6 builds on pull requests but does not log in or push. Give the two reasons.
4. `git describe` printed `v1.1.0-2-g…` before you tagged. Would the same command have worked inside the job of workflow 6? Why?

## Lab 27.2: One build, carried between jobs (workflow 7)

### Objective

Show that the thing deployed is the thing built, and detect when it is not. Download an artifact of a real run.

### Prerequisites

Chapter 20B, section 20B.3; Lab 26.7 completed, so `07-artifact.yml` is in the practice repository.

### Setup

**Part A.**

```bash
bash labs/ch20b/setup-27-2-artifact-digest.sh
labs/shell m27-2
cd warehouse-api
```

**Part B.** Your clone of `inventory-api`.

### Commands

**Part A (lab shell).**

```bash
git archive --format=tar --prefix=warehouse-api/ HEAD | shasum -a 256
git archive --format=tar --prefix=warehouse-api/ HEAD | shasum -a 256
git archive --format=tar --prefix=warehouse-api/ v1.1.0 | shasum -a 256
```

**Part B (normal shell).**

```bash
gh workflow run 07-artifact.yml --ref main
gh run list --workflow 07-artifact.yml --limit 1
gh run watch RUN_ID --exit-status
gh run view RUN_ID --log --job JOB_ID
gh run download RUN_ID --name inventory-api-dist --dir /tmp/inventory-api-dist
ls /tmp/inventory-api-dist
```

`JOB_ID` of the second job comes from `gh run view RUN_ID --json jobs --jq '.jobs[] | {name, databaseId}'`.

### Expected output

**Part A.**

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

**Part B.** Described, not captured: the log of the job "Simulated deployment" contains the lines the step "Show what arrived" prints (an artifact ID, an artifact digest, the file names) and the report of `scripts/deploy.sh`. The download directory contains an sdist and a wheel. `uv build` was not run by the author; if the names differ from what you expect, read the build step's log.

### What happened internally

Part A: `git archive` writes the tree of a commit as a tar stream with the commit's time as the modification time of every entry, so two runs give identical bytes and identical SHA-256 digests. A different commit gives a different digest.

Part B: the build job ran on one machine and was destroyed. The files survived as an artifact, stored by GitHub with a digest computed at upload. The second job started on a new machine, downloaded the artifact, and `actions/download-artifact` v8 compared the digest. Nothing changed in Git: an artifact is a GitHub object attached to a run, kept for the `retention-days` of the upload step (7 here) within the repository's limit.

### Checkpoint

Explain why the second job contains a checkout step although it downloads the build. (It needs `scripts/deploy.sh`, which is in the repository and not in the artifact.)

### Failure scenario

<!-- snippet: ch20b/lab-27-2-artifact-digest/02-failure -->
```text
$ git archive --format=tar --prefix=warehouse-api/ -o ../build.tar HEAD
$ (cd .. && shasum -a 256 build.tar > build.tar.sha256)
# Something between the build job and the deploy job changes one byte:
$ printf 'x' >> ../build.tar
$ (cd .. && shasum -a 256 -c build.tar.sha256)
build.tar: FAILED
shasum: WARNING: 1 computed checksum did NOT match
[exit status: 1]
```
<!-- /snippet -->

One appended byte, and the check fails. On GitHub, break the hand-over differently: on a branch, change the `name:` of the download step to `inventory-api-dists`, push the branch, and run `gh workflow run 07-artifact.yml --ref <branch>`. Expect the download step to fail; read its message with `gh run view RUN_ID --log-failed`.

### Recovery

<!-- snippet: ch20b/lab-27-2-artifact-digest/03-recovery -->
```text
# Do not repair the file. Produce it again from the commit and compare.
$ git archive --format=tar --prefix=warehouse-api/ -o ../build.tar HEAD
$ (cd .. && shasum -a 256 -c build.tar.sha256)
build.tar: OK
[exit status: 0]
```
<!-- /snippet -->

You did not edit the damaged file. You produced it again from its source and compared. On GitHub, delete the branch; `main` was never changed.

### Verification

`shasum -a 256 -c build.tar.sha256` in the sandbox root prints `build.tar: OK`. On GitHub, the latest run of `07-artifact.yml` on `main` is green: `gh run list --workflow 07-artifact.yml --branch main --limit 1`.

### Questions

1. Why does the deploy job download the artifact and not run `uv build` again?
2. What is the difference in purpose between an artifact and a cache?
3. An artifact has `retention-days: 7`. A colleague wants to roll back to a build from three weeks ago. What do you tell them, and what would you change?
4. `git archive` of one commit is reproducible. Name one reason a `uv build` or `docker build` of one commit might not be.

## Lab 27.3: Deploy to staging (workflow 8)

### Objective

Create an environment, scope a variable and a secret to it, deploy to it from `main`, and state exactly which commits a deployment adds. See why a re-run of an old run is a rollback.

### Prerequisites

Chapter 20B, sections 20B.2, 20B.3, 20B.5 and 20B.14.

### Setup

**Part A.**

```bash
bash labs/ch20b/setup-27-3-deploy-range.sh
labs/shell m27-3
cd warehouse-api
```

**Part B.** Create the environment before the workflow exists, then give it its configuration. When `gh secret set` asks, type a dummy value.

```bash
gh api -X PUT "repos/$ORG/inventory-api/environments/staging"
gh variable set STAGING_URL --env staging --body "https://staging.inventory.example.com"
gh secret set DEPLOY_TOKEN --env staging
gh api "repos/$ORG/inventory-api/environments" --jq '.environments[].name'
gh workflow disable "Artifact"
```

### Commands

**Part A (lab shell).** Staging runs `v1.1.0`; a push to `main` is about to deploy its tip.

```bash
git log --oneline v1.1.0..main
git diff --stat v1.1.0 main
./scripts/deploy.sh staging
```

**Part B (normal shell).** Predict: how many jobs, in which order, and which of them can read `DEPLOY_TOKEN`?

```bash
cp "$COURSE/workflows/08-deploy-staging.yml" .github/workflows/
git add .github/workflows/08-deploy-staging.yml
git commit -m "Add the staging deployment workflow"
git push origin main
gh run list --workflow 08-deploy-staging.yml --limit 1
gh run watch RUN_ID --exit-status
gh run view RUN_ID --log --job DEPLOY_JOB_ID
gh api "repos/$ORG/inventory-api/deployments" --jq '.[0] | {environment, sha, ref, created_at}'
```

### Expected output

**Part A.**

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

**Part B.** Described, not captured: one run with the jobs "Build and test" and "Deploy to staging"; the second starts after the first succeeded. The deploy job's log contains the report of `scripts/deploy.sh` with `environment : staging` and the commit of the run. The deployments endpoint returns an object whose `environment` is `staging` and whose `sha` equals `git rev-parse origin/main` ([REST: deployments](https://docs.github.com/en/rest/deployments/deployments)).

### What happened internally

Part A: `v1.1.0..main` is every commit reachable from `main` and not from the tag: exactly what the deployment adds to what is running.

Part B: the push moved `refs/heads/main` on GitHub and created a run for the `push` event at that commit. The build job could not read `DEPLOY_TOKEN`, because it does not reference the environment. The deploy job referenced `staging`; it has no protection rules, so the job was sent to a runner at once, received the environment's secret and variable, and GitHub created a deployment record with the run's commit. In Git nothing happened beyond the push.

### Checkpoint

`gh secret list --env staging` shows `DEPLOY_TOKEN`; `gh secret list` (repository level) does not. If the second list shows it, you set it at the wrong level: delete it there with `gh secret delete DEPLOY_TOKEN` and think about which jobs could have read it.

### Failure scenario

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

The old commit is an ancestor of `main` (exit status 0), so deploying it moves staging backwards by the two commits listed. On GitHub, after at least two runs of workflow 8 exist: take the ID of the older one from `gh run list --workflow 08-deploy-staging.yml` and run `gh run rerun OLD_RUN_ID`. When it finishes, the newest deployment record carries the older commit.

### Recovery

<!-- snippet: ch20b/lab-27-3-deploy-range/03-recovery -->
```text
$ git switch --quiet main
$ ./scripts/deploy.sh staging
would deploy 57c8425 to staging
$ git merge-base --is-ancestor v1.1.0 HEAD
[exit status: 0]
```
<!-- /snippet -->

Deploy the current tip with a new run, not a re-run: `gh workflow run 08-deploy-staging.yml --ref main`.

### Verification

```bash
gh api "repos/$ORG/inventory-api/deployments" --jq '.[0].sha'
git rev-parse origin/main
```

The two IDs are equal.

### Questions

1. Which line of workflow 8 keeps a failing test from reaching staging?
2. The workflow has `concurrency: { group: deploy-staging, cancel-in-progress: false }`. Three pushes arrive while the first deployment is still running. What happens to each run?
3. Why is `DEPLOY_TOKEN` passed through `env` and not written as `${{ secrets.DEPLOY_TOKEN }}` inside the `run` text?
4. What does `gh run rerun` reuse from the original run, and what does that mean for a deploy workflow?
5. You created the environment before pushing the workflow. What would have happened if you had not?

## Lab 27.4: Staging, then production behind an approval (workflow 9)

### Objective

Gate a production deployment with a required reviewer and a deployment branch rule, approve a run, and show which commits the approval released. Find the gap that a rule on one environment leaves on the other.

### Prerequisites

Chapter 20B, sections 20B.2 and 20B.4; Lab 27.3 completed. The practice repository must be public: on Free, Pro and Team plans required reviewers work only in public repositories.

### Setup

**Part A.**

```bash
bash labs/ch20b/setup-27-4-promotion.sh
labs/shell m27-4
cd warehouse-api
```

**Part B.** Create `production` with yourself as required reviewer and a rule that accepts only `main`. Self-review stays allowed, because you work alone here; with a team you would set `prevent_self_review` to `true`.

```bash
MY_ID=$(gh api user --jq .id)
cat > /tmp/production-environment.json <<JSON
{
  "wait_timer": 0,
  "prevent_self_review": false,
  "reviewers": [ { "type": "User", "id": $MY_ID } ],
  "deployment_branch_policy": { "protected_branches": false, "custom_branch_policies": true }
}
JSON
gh api -X PUT "repos/$ORG/inventory-api/environments/production" --input /tmp/production-environment.json
gh api -X POST "repos/$ORG/inventory-api/environments/production/deployment-branch-policies" -f name=main -f type=branch
gh variable set DEPLOY_URL --env staging --body "https://staging.inventory.example.com"
gh variable set DEPLOY_URL --env production --body "https://inventory.example.com"
gh secret set DEPLOY_TOKEN --env production
gh workflow disable "Deploy to staging"
```

The body fields are those of the [environments REST reference](https://docs.github.com/en/rest/deployments/environments); the second call is [create a deployment branch policy](https://docs.github.com/en/rest/deployments/branch-policies), which requires `custom_branch_policies` to be `true`.

### Commands

**Part A (lab shell).** Two refs under `refs/deployed/` stand in for GitHub's deployment records. They are bookkeeping for this exercise; GitHub does not store deployments as refs.

```bash
git for-each-ref --format="%(refname) %(objectname:short)" refs/deployed
git log --oneline refs/deployed/production..refs/deployed/staging
```

**Part B (normal shell).**

```bash
gh api "repos/$ORG/inventory-api/environments/production" --jq '{protection_rules, deployment_branch_policy}'
cp "$COURSE/workflows/09-environments.yml" .github/workflows/
git add .github/workflows/09-environments.yml
git commit -m "Add the staging-to-production workflow"
git push origin main
gh run list --workflow 09-environments.yml --limit 1
gh run view RUN_ID
gh run view RUN_ID --web
```

When `gh run view` shows the production job waiting, approve it in the browser. The documented steps ([reviewing deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments)): on the run page choose **Review deployments**, select `production`, then **Approve and deploy**. Before you approve, say which commits you are releasing.

### Expected output

**Part A.**

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

**Part B.** Described, not captured: the first `gh api` call prints the two keys `protection_rules` and `deployment_branch_policy` of the environment object: the first should contain a rule that names you as reviewer, the second should show custom branch policies switched on. The run shows "Build and test" and "Deploy to staging" completed and "Deploy to production" waiting. After the approval the job runs and its log shows `environment : production`.

### What happened internally

Part A: the range `production..staging` is what staging has and production lacks. Approving the production job of a run releases exactly the commits between production's current commit and the commit of that run.

Part B: all three jobs belong to one run and therefore to one commit. The production job was created at once, but GitHub did not send it to a runner, and did not expose the production secret, until two rules passed: the run's ref matched the branch policy `main`, and a listed reviewer approved. The approval is recorded on GitHub with your name. Nothing about it is stored in Git.

### Checkpoint

`gh run view RUN_ID --json jobs --jq '.jobs[] | {name, status, conclusion}'` shows the production job without a conclusion while it waits. If it ran without waiting, the rule is not there: read the environment back and compare with the JSON you sent.

### Failure scenario

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

The ref is not `refs/heads/main` and the commit is not contained in `main`. On GitHub: create a branch `lab-27-4-hotfix` with any small commit, push it, and run `gh workflow run 09-environments.yml --ref lab-27-4-hotfix`. Predict before you look which job is stopped. Expect the production job to be rejected by the branch rule, and notice what happened one job earlier: `staging` has no branch rule, so the branch was deployed to staging.

### Recovery

<!-- snippet: ch20b/lab-27-4-promotion/03-recovery -->
```text
# The fix reaches production the way everything else does: through main.
$ git switch --quiet main
$ git merge --quiet --no-ff -m "Merge hotfix/lead-days" hotfix/lead-days
$ git symbolic-ref HEAD
refs/heads/main
$ git merge-base --is-ancestor hotfix/lead-days main
[exit status: 0]
$ git log --oneline refs/deployed/production..main
fe34a26 Merge hotfix/lead-days
e39e6de Raise the lead time to seven days
57c8425 Add the lock file
197d992 Document the release runbook
```
<!-- /snippet -->

The fix reaches production through `main`. On GitHub, close the gap you found and remove the branch:

```bash
gh api -X PUT "repos/$ORG/inventory-api/environments/staging" \
  -F 'deployment_branch_policy[protected_branches]=false' -F 'deployment_branch_policy[custom_branch_policies]=true'
gh api -X POST "repos/$ORG/inventory-api/environments/staging/deployment-branch-policies" -f name=main -f type=branch
git push origin --delete lab-27-4-hotfix
```

### Verification

```bash
gh api "repos/$ORG/inventory-api/environments/staging/deployment-branch-policies" --jq '.branch_policies[].name'
gh api "repos/$ORG/inventory-api/deployments?environment=production" --jq '.[0].sha'
git rev-parse origin/main
```

The first command prints `main`; the two IDs are equal after an approved run on `main`.

### Questions

1. Name the three controls that together make the production gate, and for each the bypass that remains if it is missing.
2. Why can the production job not read `DEPLOY_TOKEN` of `production` while it waits?
3. The deploy jobs of workflow 9 are almost identical text. Where is the difference between staging and production stored, and who can change it?
4. Your company's repository is private on a Team plan. Which parts of this lab would not work there?
5. An administrator is in a hurry. Which default lets them skip your reviewer, and how would you find out whether it was used?

## Lab 27.5: A reusable workflow and its caller (workflow 11)

### Objective

Call a workflow from another workflow with an input, a secret and an output; name the check it produces; and show that caller and called file must agree in one commit.

### Prerequisites

Chapter 20B, section 20B.6; Lab 27.3 completed (the environment `staging` exists).

### Setup

**Part A.**

```bash
bash labs/ch20b/setup-27-5-reusable-ref.sh
labs/shell m27-5
cd warehouse-api
```

**Part B.** A repository-level secret for the caller to pass (a dummy value), and the other deploy workflows switched off.

```bash
gh secret set SHARED_DEPLOY_TOKEN
gh workflow disable "Deploy through environments"
```

### Commands

**Part A (lab shell).**

```bash
git ls-files .github/workflows
git grep -n "uses:" main -- .github/workflows/deploy.yml
git diff --stat main ci/python-version
git grep -c "python-version" main ci/python-version -- .github/workflows/reusable-deploy.yml
```

**Part B (normal shell).** Predict the names of the jobs the run will show.

```bash
cp "$COURSE/workflows/11-reusable-workflow.yml" "$COURSE/workflows/11-caller.yml" .github/workflows/
git add .github/workflows/11-reusable-workflow.yml .github/workflows/11-caller.yml
git commit -m "Add a reusable deploy workflow and its caller"
git push origin main
gh run list --workflow 11-caller.yml --limit 1
gh run watch RUN_ID --exit-status
gh run view RUN_ID --json jobs --jq '.jobs[].name'
gh workflow list --all
```

### Expected output

**Part A.**

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

**Part B.** Described, not captured: one run of "Deploy with a reusable workflow". From the documented naming rule the job of the called workflow appears as `Staging / Test, build and deploy`, followed by `Report`, whose job summary names the revision that the called workflow returned. Look at `gh workflow list --all` and note whether "Reusable deploy" is listed as a workflow of its own; it has no runs of its own, because it runs only when called.

### What happened internally

Part A: the caller refers to the called file with `./`, which means "this repository, at the commit of the run". `main` and the branch hold different versions of the called file; each ref's runs use their own.

Part B: the caller's job `staging` has no runner. GitHub expanded it into the jobs of the called file, with the caller's event, ref, commit and token ceiling. The input chose the environment inside the called job; the named secret travelled one level; the output travelled back through `needs.staging.outputs.revision`.

### Checkpoint

Without running anything: what would the required status check be called if a ruleset had to require the called job? Compare with the names `gh run view` printed.

### Failure scenario

<!-- snippet: ch20b/lab-27-5-reusable-ref/02-failure -->
```text
# On main, the caller starts passing an input that the called file on main does not declare:
$ printf '      python-version: "3.13"\n' >> .github/workflows/deploy.yml
$ git commit -q -am "Deploy with Python 3.13"
$ git show HEAD:.github/workflows/deploy.yml | tail -n 4
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: staging
      python-version: "3.13"
$ git grep -c "python-version" HEAD -- .github/workflows/reusable-deploy.yml
[exit status: 1]
```
<!-- /snippet -->

`git grep -c` exits with status 1: the called file at HEAD does not declare `python-version`, although the caller at HEAD passes it. The events reference states that passing an input the called workflow does not declare is an error. On GitHub: on a branch, add `region: eu` under `with:` in `11-caller.yml`, push the branch and run `gh workflow run 11-caller.yml --ref <branch>`. Expect GitHub to reject the run as invalid; read the reason on the run page and note at which point it stopped.

### Recovery

<!-- snippet: ch20b/lab-27-5-reusable-ref/03-recovery -->
```text
# Caller and called file must agree in the same commit. Bring the declaration to main:
$ git merge --quiet --no-ff -m "Merge ci/python-version" ci/python-version
$ git grep -c "python-version" HEAD -- .github/workflows
HEAD:.github/workflows/deploy.yml:1
HEAD:.github/workflows/reusable-deploy.yml:1
```
<!-- /snippet -->

Both files now mention the input in the same commit. On GitHub, delete the branch; then put the workflows back the way you want to keep them:

```bash
gh workflow enable "Artifact"
gh workflow enable "Deploy through environments"
gh workflow disable "Deploy with a reusable workflow"
```

### Verification

`git grep -c "python-version" HEAD -- .github/workflows` prints a count for both files. On GitHub, `gh run list --workflow 11-caller.yml --branch main --limit 1` shows a successful run.

### Questions

1. Which keys may a job that calls a reusable workflow contain, and which two keys that every normal job has are missing?
2. Why does the caller pass a repository secret and not the `staging` environment's `DEPLOY_TOKEN`?
3. The called workflow sets `permissions: contents: read`. The caller is later changed to `permissions: {}`. What does the called job's token get?
4. When is a composite action the better tool than a reusable workflow? Give one case from this repository.
5. A team references a shared reusable workflow as `org/platform/.github/workflows/deploy.yml@main`. What differs between "re-run all jobs" and "re-run failed jobs" for them, and how would you remove the difference?
