# Exercises, Modules 26 to 31: GitHub Actions and security

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Every transcript in this file is real output of a script in `labs/ex3/`. Nothing here was run on GitHub. The workflow files in [`workflows/`](workflows/README.md) are teaching material with planted flaws: they were assembled from documented syntax and parse-checked with PyYAML, and never executed. The security exercises are defensive: you find a weakness and fix it. Every secret is a dummy such as `DUMMY-KEY-not-a-real-secret-0042`, spelled so that no scanner pattern matches it.

## How to use these exercises

Do the labs of a module first. Write your answer before you open [the solutions](../solutions/exercises-m26-m31.md). This file contains no answers.

**Levels.** Level 1: instructions to follow. Level 2: a goal and limited hints. Level 3: a situation to diagnose on your own. Level 4: symptoms only, in a repository that a script builds for you. Level 5: a production incident with incomplete and partly misleading evidence.

**Kinds.** "Do it on GitHub" tasks run in your normal shell, in your clone of `YOUR-ORG/inventory-api`, and end with a self-check list; the lab shell cannot authenticate to GitHub. "Read and diagnose" and "workflow review" tasks are done on paper. "Local simulation" tasks run in the lab shell (`labs/shell`); Exercises 28.5 and 31.5 have a setup script, and the others ask for a prediction whose transcript is in the solution (`labs/run ex3/<name>` replays it). "Design" tasks are marked against a rubric.

**For every workflow review**, use the question of Chapter 21A, section 21A.1, even when the flaw is not a security one: which commit and which files does this job have, whose code and whose text does it run, and what can it reach?

---

## Module 26: Actions fundamentals

Chapter: [20A, GitHub Actions fundamentals](../textbook/ch20a-actions-fundamentals.md).

### Exercise 26.1 (Level 1, read and diagnose): True or false, with the reason

1. Two jobs of one run share a filesystem.
2. Two `run` steps of one job share a filesystem.
3. `export API_URL=...` in one `run` step is visible in the next `run` step.
4. On a GitHub-hosted Linux runner, a `run` step without a `shell:` key stops at the first command that fails.
5. On the same runner, `pytest | tee log.txt` fails the step when pytest fails.
6. A workflow file on a feature branch decides what runs for a push to that branch.
7. A workflow file on a feature branch decides what its `schedule` trigger runs.
8. A secret that does not exist makes the step that references it fail with an error about the secret.
9. `actions/checkout` leaves you on the branch that was pushed, with full history.
10. A cache entry can be updated in place under its key.

### Exercise 26.2 (Level 2, read and diagnose): Which commit, which ref, which file?

For each run, give `GITHUB_REF`, what `GITHUB_SHA` names, and from which commit the workflow file is read.

1. A push of two commits to `feature/x`.
2. A pull request from `feature/x` into `main`, just opened, no conflict.
3. The same pull request after `main` gained a commit that conflicts with it.
4. A `schedule` run of a workflow whose file was changed on `feature/x` yesterday and not merged.
5. `gh workflow run ci.yml --ref feature/x`. What must be true for this to work at all?
6. A job, using the job token, pushes a version-bump commit to `main`. Which workflows does that push start?
7. Someone re-runs the failed jobs of run 2 a day later, after `main` has moved again. Which commit does the re-run test?

### Exercise 26.3 (Level 2, workflow review): Six things the author did not mean

Read [`workflows/x26-matrix-and-outputs.yml`](workflows/x26-matrix-and-outputs.yml). Its header states the intended behavior. Find the six flaws. For each: the line, what GitHub Actions or the shell does with it, what the author sees (which is often "a green run"), and the corrected lines. Two of the six make the workflow green when it should be red.

### Exercise 26.4 (Level 2, local simulation): Will the path filter start the workflow?

A workflow has this trigger:

```yaml
on:
  push:
    paths: ["chunker/**"]
  pull_request:
    paths: ["chunker/**"]
```

Your branch `docs/chunk-sizes` has three commits; `main` has moved by one since you branched:

<!-- snippet: ex3/x26-path-filter/01-setup -->
```text
$ git log --oneline --stat --format="%h %s" origin/main..docs/chunk-sizes
c54fc1f Document chunk sizes

 docs/chunk-sizes.md | 3 +++
 1 file changed, 3 insertions(+)
9926b34 Take the overlap parameter out again

 chunker/split.py | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)
7f017ad Try an overlap parameter

 chunker/split.py | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)
$ git log --oneline -1 --stat --format="%h %s" origin/main
1b220ee Double the default chunk size

 config/chunking.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

Predict:

- a. You open a pull request into `main`. Does the workflow start? Name the diff that GitHub evaluates and what it lists.
- b. What would a two-dot diff of the same two branches list, and why would using it mislead you?
- c. Suppose the first commit was already on the server and you then pushed the second and third together. Does the workflow start for that push? Name the two commits that are compared.
- d. Suppose instead the first two commits were on the server and you pushed the third alone. Does it start?
- e. The job of this workflow is a required check on `main`. What happens to your pull request, and what is the design that avoids it?
- f. You push a tag that points at the tip of this branch. Is the path filter evaluated?

### Exercise 26.5 (Level 2, local simulation): Two shells, three scripts

The runner executes a `run` step with `bash -e {0}` when no shell is named, and with `bash --noprofile --norc -eo pipefail {0}` under `shell: bash`. Three scripts, in a repository that has no tags:

<!-- snippet: ex3/x26-shell/01-scripts -->
```text
$ cat ../a.sh
false | tee test-log.txt
echo "tests finished"
$ cat ../b.sh
VERSION=$(git describe 2>/dev/null)
echo "version is [$VERSION]"
$ cat ../c.sh
export VERSION=$(git describe 2>/dev/null)
echo "version is [$VERSION]"
$ git describe
fatal: No names found, cannot describe anything.
[exit status: 128]
```
<!-- /snippet -->

For each of the three scripts under each of the two templates, predict the exit status and whether the `echo` line prints. Then:

1. Which script is "green with a failed command" under the implicit default only?
2. Which script hides the failure under *both* templates, and why does `-e` not catch it?
3. Rewrite script c so that a failing `git describe` fails the step.
4. In a workflow, where do you write the shell so that every `run` step of every job gets it?

### Exercise 26.6 (Level 3, read and diagnose): Caches and artifacts

1. A dependency was upgraded in `uv.lock` and merged. CI on `main` still installs the old version. The cache step has `key: deps-${{ runner.os }}` and `restore-keys: deps-`. Explain the mechanism and give two changes, one to the key and one to the install command.
2. A pull request from `feature/a` cannot restore the cache that the last run on `feature/b` saved, although both use the same key. Why? From which branches can it restore?
3. The step output `cache-hit` is `false`, and the log says a cache was restored. Is that a contradiction?
4. A deploy job rebuilds the wheel with `uv build` "because artifacts are slow". Name the property that is lost, in one sentence a CTO would accept.
5. A test report was uploaded yesterday as an artifact named `report`; today's re-run of the same run fails at the upload step. Why, and which two fixes exist?
6. A team stores a 6 GB model checkpoint in the Actions cache to speed up evaluation. Give two documented reasons this goes wrong.

### Exercise 26.7 (Level 1, do it on GitHub): Read a run from the terminal

In your clone of `YOUR-ORG/inventory-api`, with workflow 1 installed (Lab 26.1), push any small commit to a branch and open a pull request. Then:

```bash
gh run list --limit 5
gh run view RUN_ID --json event,headBranch,headSha,conclusion
gh run view RUN_ID --log | grep -n -E 'GITHUB_REF|GITHUB_SHA|HEAD '
git rev-parse HEAD
gh run watch RUN_ID --exit-status
```

Self-check:

- [ ] You can explain why `headSha` equals your `git rev-parse HEAD` while the `GITHUB_SHA` that the job printed does not.
- [ ] You can say what `git rev-parse --is-shallow-repository` printed in the job, and what that means for `git describe`.
- [ ] You can say what `gh run watch --exit-status` returns for a failed run, and why that matters in a script.
- [ ] You fetched the commit that the job tested into your clone by its ref, or you can say why its ID is unknown to your clone.

---

## Module 27: Build, package, and deliver

Chapter: [20B](../textbook/ch20b-actions-delivery-debugging.md), sections 20B.2 to 20B.7.

### Exercise 27.1 (Level 1, do it on GitHub): An environment, read back

In your normal shell, for the public repository `YOUR-ORG/inventory-api`:

```bash
gh api -X PUT repos/YOUR-ORG/inventory-api/environments/exercise-27
gh variable set TARGET_URL --env exercise-27 --body "https://staging.example.com"
gh api repos/YOUR-ORG/inventory-api/environments --jq '.environments[].name'
gh api repos/YOUR-ORG/inventory-api/environments/exercise-27
gh variable list --env exercise-27
```

Self-check:

- [ ] You can say which of these calls changed something and with which HTTP method.
- [ ] From the read-back, you can say whether a job that names this environment would wait for anybody.
- [ ] You can say what would have happened if, instead of the first command, a workflow had named an environment `exercise-27` that did not exist, and who is allowed to do that.
- [ ] You can explain why none of this is in your clone, and what a move to another host would lose.
- [ ] You deleted the environment in the repository settings when you were done, or you can name the risk of leaving unused environments behind.

### Exercise 27.2 (Level 3, workflow review): A deployment with five flaws

Read [`workflows/x27-deploy.yml`](workflows/x27-deploy.yml) and its header. Find the five flaws. For each: what happens on GitHub, why nothing reports an error, and the fix. Then answer: after your fixes, which three things together make "only reviewed code reaches production" true, and which of them is not in this file at all?

### Exercise 27.3 (Level 2, read and diagnose): Three pushes in ten minutes

A workflow deploys on every push to `main`. One deployment takes six minutes. Pushes arrive at 10:00 (A), 10:02 (B), 10:04 (C) and 10:05 (D). For each configuration, say which runs deploy, in which order, and which are cancelled:

1. `concurrency: production` (a group name only)
2. `group: production` with `cancel-in-progress: true`
3. `group: production` with `queue: max`
4. No `concurrency` key at all

Then: which configuration do you choose for a deployment that applies one database migration per commit, and which for CI on pull request branches? What is wrong with using configuration 2 for a deployment? What would the group name `${{ github.workflow }}-${{ github.ref }}` change in the CI case?

### Exercise 27.4 (Level 3, local simulation): A guard against going backwards

Chapter 20B warns that re-running an old deployment run deploys the old commit over a newer one. Write a shell script `guard.sh` that a deploy script calls with the commit it is about to deploy. It must:

- read what production runs from the ref `refs/deployed/production` (your own bookkeeping; GitHub keeps deployments as platform objects),
- exit 0 and print the commits the deployment adds when the candidate contains everything production runs, and more,
- exit non-zero, with a message that lists what would be lost, when the candidate is older than production, equal to it, or on a line of history that does not contain it.

Test it in the lab shell on a small repository with a `main` of four commits, a deployed ref two commits behind, and a `hotfix` branch cut from the deployed commit. The solution shows one implementation with its transcript (`labs/run ex3/x27-deploy-guard`).

Then answer: which of the three refusals is sometimes wrong to refuse, and how would you let a human override it without removing the guard?

### Exercise 27.5 (Level 3, read and diagnose): Four reusable-workflow surprises

A team moved its deploy job into a reusable workflow that forty repositories call. Explain each report and give the fix.

1. "The called workflow's deploy step gets an empty `DEPLOY_TOKEN`. The caller has `secrets: inherit`. The secret is defined on the `production` environment of the calling repository."
2. "The caller sets `env: REGION: ap-south-1` at the top of its file. In the called workflow `$REGION` is empty."
3. "Since the move, every pull request waits for the required check `deploy-check`, which never reports. The job is still called `deploy-check` inside the called workflow."
4. "Both files have `concurrency: { group: ${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true }`. Runs cancel themselves."

Then: the callers reference the reusable workflow as `@main`. Name two consequences, one for security and one for reproducibility of a re-run.

### Exercise 27.6 (Level 3, design): The release that triggers nothing

A workflow `tag-release.yml` runs on pushes to `main`, decides whether a release is due, and if so creates the tag and the GitHub Release with `gh release create "$TAG" --generate-notes`, using the job token. A second workflow, `publish.yml`, has `on: release: types: [published]` and uploads the package. Since this was set up, releases appear and nothing is ever published.

1. Explain why `publish.yml` never starts. Quote the rule and name its documented exceptions.
2. Give two designs that work, and the trade-off between them.
3. The `gh release create` line has a second weakness that is independent of the first. Name it and the flag that removes it.
4. The team wants immutable releases. In which order must the release job do its three steps?

A rubric is in the solution.

### Exercise 27.7 (Level 5, production incident): Production changed, and nobody approved it

Friday 17:40: production of `inventory-api` serves a build from Tuesday, although Thursday's release had been live since Thursday noon. Evidence:

- The workflow file names `environment: production` in its deploy job. "Production has required reviewers", says the team lead.
- The repository was changed from public to private on Wednesday. The organization is on the Team plan.
- The Actions tab shows that at 17:31 on Friday a developer re-ran the failed jobs of Tuesday's deploy run "to get its artifact for a bug report". Tuesday's run had failed in a post-deployment notification step.
- The deploy job of that re-run did not wait for an approval.
- A senior engineer suspects that someone force-pushed `main`. `git log origin/main` shows Thursday's commits intact.
- Another suspects the concurrency group, because "it cancels things".

1. Why did Tuesday's code get deployed? Name the mechanism and the sentence from the documentation.
2. Why did the job not wait? Use the Wednesday event. What would you read to confirm it?
3. Dismiss the force-push theory and the concurrency theory, each with one piece of evidence.
4. What do you do in the next ten minutes, and why is a "re-run of Thursday's run" an acceptable or unacceptable way to do it?
5. Name three preventions, one in the deploy script, one in GitHub settings, one outside GitHub.

---

## Module 28: Runners, cost, and debugging CI

Chapter: [20B](../textbook/ch20b-actions-delivery-debugging.md), sections 20B.8 to 20B.15.

### Exercise 28.1 (Level 1, read and diagnose): Where in the order?

The chapter's investigation order has twelve questions: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency. For each symptom, name the first question in that order that would find the cause, and the command or place you would look at.

1. The run's conclusion is `cancelled`, and nobody cancelled it.
2. A scheduled run executed last week's version of the workflow, not the one on your branch.
3. A step fails with "Resource not accessible by integration".
4. The deploy step fails with an authentication error from the cloud; the same script works for a maintainer's pull request... and this run is for a pull request from a fork.
5. The job was killed without a test failure after the repository became private.
6. The test job reports a version of a dependency that is not the one in `uv.lock`.
7. The deploy job downloaded nothing: "artifact not found".
8. The job has been "waiting" for two days.

### Exercise 28.2 (Level 3, workflow review): The nightly evaluation that never fails

Read [`workflows/x28-nightly-eval.yml`](workflows/x28-nightly-eval.yml) and its header. Find the five flaws. One concerns when it runs, one a condition that does not mean what it says, one the machine, and two the reason the run is green every night although the score dropped a month ago. Give the fix for each, and add the two properties of `schedule` that the team should know even after the fixes.

### Exercise 28.3 (Level 3, workflow review): A required check that cannot be red

Read [`workflows/x28-aggregate.yml`](workflows/x28-aggregate.yml). The ruleset requires `all-checks` only.

1. The unit tests fail. Walk through what each of the three jobs reports, and what the merge box concludes.
2. The linter finds an error. Same question.
3. Find the three flaws and rewrite the `lint` and `all-checks` jobs.
4. Why does the documentation recommend `!cancelled()` over `always()` for the aggregate job?
5. Which skipped-job rule makes "require the individual jobs instead" a worse fix than it looks?

### Exercise 28.4 (Level 2, read and diagnose): What does this pipeline cost?

A private repository runs this on every push: three Linux jobs that take 2 min 10 s, 4 min 5 s and 20 s, and one macOS job of 6 min 30 s. There are 40 pushes on each of 22 working days a month. Use the list prices of Chapter 20B, section 20B.10 (standard 2-core Linux and macOS), and the rounding rule.

1. How many billed minutes of each kind per month, and what do they cost at list price, before any included minutes?
2. Which single change saves the most, and what does it cost in coverage?
3. The 20-second job is "free anyway". Is it? What does merging it into another job change?
4. The team adds `concurrency` with `cancel-in-progress: true` keyed on the ref. Which runs stop being billed in full, and what is the risk on `main`?
5. One number that people quote in this area is marked unverified in the chapter. Which, and what do you do instead of quoting it?

### Exercise 28.5 (Level 4, local simulation): Green here, red in a fresh clone

```bash
bash labs/ex3/setup-x28-5-fresh-clone.sh
labs/shell x28-5/you/chunker
```

You are in your clone, on `main`, with everything pushed. A bare repository beside it plays GitHub. `./scripts/smoke.sh` stands in for the CI command.

Symptoms:

- `./scripts/smoke.sh` passes in your clone. `git status` is clean.
- The CI job runs the same command on the same commit and fails. After a teammate "fixed" the first error on the runner by hand, a second, different error appeared.

Reproduce what the runner has, without GitHub. Find both causes with Git commands, repair them in the repository, push, and prove the repair the way a runner would see it.

Self-check:

- [ ] You reproduced each failure before you fixed it.
- [ ] For each cause you can name the Git command that showed it and the one local setting or file that hid it from you.
- [ ] Your proof of the repair does not use your working clone.
- [ ] You did not fix either problem by changing the CI command.
- [ ] You can name a third cause of the same family that this repository does not have.

### Exercise 28.6 (Level 3, read and diagnose): The machine changed, the code did not

Explain each report from the documented facts about runners, and say what you would change.

1. "Our evaluation job has been killed since the repository was made private. Same commit, same workflow."
2. "Two runs of the same commit on the same day used different operating system versions. We use `ubuntu-latest`."
3. "Our self-hosted runners were built from a fixed image in July with automatic updates disabled. In October they stopped receiving jobs."
4. "A workflow pinned to `macos-14` fails on some days in October 2026 and works on others."
5. "A job on our self-hosted GPU runner waited a day and then failed without running."

### Exercise 28.7 (Level 5, production incident): Every pull request is waiting

Monday 09:30: no pull request in `inventory-api` can merge. The merge box of each one says it is waiting for the status of `Staging / Test, build and deploy` to be reported. Evidence:

- On Friday evening a refactoring was merged: the calling job in the workflow was renamed from `Staging` to `staging-deploy`, "for consistency".
- The ruleset on `main` was not changed. It requires one check, by name.
- All workflow runs since Friday are green.
- A developer re-ran the workflow on one pull request three times; each run was green and the merge box did not change.
- Someone proposes to merge with `gh pr merge --admin` "just today".
- Someone else proposes to start the workflow by hand with `gh workflow run` on each pull request branch, "so that the check gets reported".
- The bypass list of the ruleset is empty.

1. State the root cause in one sentence. How is the name of this check formed?
2. Why do green re-runs not help?
3. Would the `gh workflow run` proposal help? Give the rule.
4. Would `--admin` work here? What would it mean if it did?
5. Give the lowest-risk repair and say who can perform it. Then give the design change that makes the rule independent of job names.

---

## Module 29: GitHub Actions security

Chapter: [21A, GitHub Actions security](../textbook/ch21a-actions-security.md). These exercises are defensive: find the weakness, name its class, fix it. No exercise asks you to write or run an attack.

### Exercise 29.1 (Level 1, read and diagnose): Whose code, whose text, what can it reach?

Ask the three-part question of section 21A.1 for each job and say whether you have found a vulnerability.

1. `on: pull_request`; checks out the default ref; runs `make test`; no secrets; `permissions: contents: read`.
2. `on: pull_request_target`; no checkout; adds a label with `permissions: pull-requests: write`.
3. `on: pull_request_target`; checks out `github.event.pull_request.head.sha`; runs `npm install`; the job token is read-write.
4. `on: issues`; one step: `run: echo "New issue: ${{ github.event.issue.title }}"`; the workflow has `permissions: write-all`.
5. `on: push` to `main`; `uses: some-org/some-action@v3`; the job has `id-token: write` and assumes a deployment role.
6. `on: pull_request`; `runs-on: self-hosted`; public repository.

### Exercise 29.2 (Level 3, workflow review): The comment workflow

Read [`workflows/x29-pr-report.yml`](workflows/x29-pr-report.yml). It is the privileged half of the two-workflow design that the chapter recommends, done carelessly. Find the three weaknesses, name the class of each, and rewrite the two `run` steps. State exactly which data in this job is attacker-controlled and by which path it arrives. Then say what this workflow gets right, compared with running the tests under `pull_request_target`.

The solution shows a `grep` audit of this file and the next two (`labs/run ex3/x29-audit`).

### Exercise 29.3 (Level 3, workflow review): The release workflow

Read [`workflows/x29-release.yml`](workflows/x29-release.yml). Find the five weaknesses. For each: which code gains which capability, the section of Chapter 21A that covers it, and the corrected lines. Then describe the cloud-side trust policy condition you would want for the publishing role, in words, and say why the workflow file cannot enforce it.

### Exercise 29.4 (Level 3, workflow review): The GPU box

Read [`workflows/x29-gpu-eval.yml`](workflows/x29-gpu-eval.yml). Find the three weaknesses. Then design the evaluation set-up you would defend: which trigger, which runners, registered how, reachable from which repositories, with which credentials on the machine.

### Exercise 29.5 (Level 2, read and diagnose): What can this token do?

```yaml
permissions:
  contents: read

jobs:
  a:
    runs-on: ubuntu-24.04
    steps: [...]
  b:
    runs-on: ubuntu-24.04
    permissions:
      issues: write
    steps: [...]
  c:
    runs-on: ubuntu-24.04
    permissions: {}
    steps: [...]
```

1. For jobs a, b and c, list what the job token may do.
2. Job b starts with a checkout of this private repository and fails. Why, and what is the fix?
3. The whole `permissions` block is deleted. What can the token do now? What does the answer depend on, and since when?
4. The same file is triggered by a pull request from a fork. What changes for job b?
5. A stolen job token is used to push a commit. Which workflows start? Name the documented exceptions that make a stolen token dangerous anyway.

### Exercise 29.6 (Level 3, read and diagnose): Who can assume the role?

A cloud role for publishing trusts GitHub's OIDC provider with one condition on the subject. For each form of the condition, say which of these runs of `northwind-ml/chunker` can obtain the role: (i) a push to `main`, (ii) a push to `feature/x`, (iii) a pull request run, (iv) a tag push `v1.2.0`, (v) a job on `main` that references the environment `production`.

- A. the subject must be like `repo:northwind-ml/chunker:*`
- B. the subject must equal `repo:northwind-ml/chunker:ref:refs/heads/main`
- C. the subject must equal `repo:northwind-ml/chunker:environment:production`

Then:

1. Which form do you choose for publishing, and what on the GitHub side makes it meaningful?
2. With form C, a new repository created in August 2026 fails to assume the role. Why?
3. `id-token: write` is set at workflow level "because it grants no write access to anything". What is right and what is wrong in that sentence?
4. What did the TanStack post-mortem say about OIDC that keeps this from being the last control?

### Exercise 29.7 (Level 3, design): Benchmark scores on fork pull requests

An open-source evaluation library wants every pull request, including those from forks, to show benchmark scores. Computing them needs a paid provider API key. A contributor proposes `pull_request_target` "so that the key is available". Design the safe version: which workflows, on which triggers, with which permissions, what crosses between them and in what form, when the key is used and on whose code. List what you give up. The solution has a rubric.

### Exercise 29.8 (Level 5, production incident): A workflow nobody wrote

Tuesday 08:15: a maintainer of `northwind-ml/ranker-service` notices a file `.github/workflows/format.yml` on a branch `chore/format`, pushed at 03:12 by the account of a teammate who was asleep. The workflow ran once, on `push`. Evidence:

- The run's log is short. No secret value appears in it; everything that could be a secret shows as `***`.
- The repository has six repository-level secrets, among them a registry token and a cloud key. It has one environment, `production`, with a required reviewer and two more secrets.
- The teammate's account has two-factor authentication. Last week he installed a new editor extension.
- "Nothing leaked: the log is masked", says one engineer.
- "The token was read-only: our workflows all say `permissions: contents: read`", says another.
- The branch was deleted at 03:20.

1. Which secrets do you treat as exposed, which not, and why? Use the sentence about write access.
2. Answer both engineers.
3. What does the deletion of the branch change?
4. Order the response for the first hour. Which mistake in the Trivy case does your order avoid?
5. Which two controls would have prevented the run or limited what it could read?
6. What does the two-factor fact tell you about how the account was used?

---

## Module 30: Repository and supply-chain security

Chapter: [21B](../textbook/ch21b-repository-security-incident-response.md), sections 21B.1 to 21B.13.

### Exercise 30.1 (Level 1, read and diagnose): What could that have run?

For each action on an untrusted repository, say whether Git itself can execute something the author prepared, and through which file.

1. `git clone https://...` followed by `git log -p`
2. Unpacking a `.tar.gz` that contains a `.git` directory, then `cd` into it with a shell prompt that shows the branch
3. `git clone --recurse-submodules https://...`
4. `git clone --no-local ./package clean`, then working in `clean`
5. After a plain clone: `pip install -e .`
6. `cd` into a subdirectory of a clone that contains a tracked bare repository, then `git status`
7. In a container: `git config --global --add safe.directory '*'` to silence "dubious ownership"

Then give the three settings or habits you would put on a new team laptop.

### Exercise 30.2 (Level 2, read and diagnose): Four questions about one commit

A commit on `main` shows a colleague's avatar and name. She says she did not write it. It has no badge. For each of the chapter's four questions (who is displayed, who pushed, who signed, what is enforced), say what decides the answer, where you read it, and whether someone with push access can forge it. Then say what changes for this commit, and for a future one like it, when (a) she enables vigilant mode and (b) the repository requires signed commits.

### Exercise 30.3 (Level 2, read and diagnose): Blocked or not?

Push protection for users is on (the default). For each push, say whether GitHub's push-time check stops it, and why.

1. A recognized provider key pushed to your own public repository.
2. The same key pushed to a private repository of an organization that has not bought Secret Protection.
3. A database password in a connection string, pushed to a public repository.
4. A Google API key pushed to a public repository.
5. A recognized key, where the pusher chooses the bypass reason "It's used in tests".
6. A recognized key in a commit that you then "fix" with a second commit that deletes the file, pushing both together.

Then: what is the one moment at which rewriting history removes a secret completely, and how does case 6 keep you there?

### Exercise 30.4 (Level 1, do it on GitHub): The baseline of a public repository

For `YOUR-ORG/practice-repo`, in your normal shell:

```bash
gh repo view --json isSecurityPolicyEnabled,visibility
gh repo edit --enable-secret-scanning
gh repo edit --enable-secret-scanning-push-protection
git config get --show-origin safe.bareRepository
git config get --show-origin transfer.credentialsInUrl
```

Then check in the repository's security settings, in the browser, that Dependabot alerts and private vulnerability reporting are enabled, and add a `SECURITY.md` if the first command says there is none. Do not test push protection with anything that looks like a real key; Lab 30.1 has a safe procedure.

Self-check:

- [ ] You can say which of the features you enabled are free on a public repository and what they cost on a private one.
- [ ] You can say what repository-level push protection adds to the user-level default.
- [ ] You can say what secret scanning scans beyond the files on the default branch.
- [ ] You know what your two Git settings are, and what you would set them to.

### Exercise 30.5 (Level 3, read and diagnose): Six leaked credentials

Each of these was found in a public repository this morning. Rank them from widest reach to narrowest, give the lifetime of each, and name the first action. One of them needs no action from you; say why.

1. A classic personal access token with the `repo` scope, belonging to a staff engineer.
2. A deploy key, read-only, for one repository.
3. The private key of a GitHub App that is installed on the whole organization.
4. An Actions `GITHUB_TOKEN`, printed in a log of a job that finished yesterday.
5. A fine-grained token for one repository with read access to contents, expiring next week.
6. A personal SSH private key, without passphrase.

Then: how do you find out what the token in 1 did, without pasting it anywhere, and which two limits decide whether that works?

### Exercise 30.6 (Level 3, design): A baseline for a new ML repository

Write the security baseline for a new private repository on the Team plan that will hold an LLM application: prompts, evaluation code, a Dockerfile, workflows, and no model weights. Cover the Git client settings for the team, secrets at commit time, at push time and in history, dependencies, code scanning, reporting, credentials for automation, and review of workflow files. For each layer say what it does not cover and what it costs. The solution has a rubric.

### Exercise 30.7 (Level 5, production incident): The reproduction package

An intern received `repro-package.tar.gz` from the author of a paper, unpacked it under `~/work`, and typed `cd repro-package`. Her terminal froze for a second. That evening the security team sees an outbound connection from her laptop to an unknown host at the same minute. Evidence:

- She says: "I did not run anything. I did not even run `git status`."
- Her shell prompt shows the current branch.
- The archive contains a `.git` directory.
- `git log` in the package shows three ordinary commits by the paper's author. The repository on GitHub that the paper links has 4,100 stars.
- A colleague says: "Cloning is safe. Git fixed all of that in 2024."
- Her laptop has an SSH agent with her work key loaded, and cloud credentials in her home directory.

1. What most likely executed, and through which mechanism? Name the two kinds of file under `.git` that can make Git run a program.
2. Is the colleague's statement true, and is it relevant?
3. What does the star count prove?
4. What is in scope for rotation, and why all of it at once?
5. What should she have done with the archive? Give the command from Git's manual.
6. Which two configuration settings narrow this class of problem, and which popular "fix" widens it?

---

## Module 31: Secret-leak response and history rewriting as an operation

Chapter: [21B](../textbook/ch21b-repository-security-incident-response.md), sections 21B.9 to 21B.19.

### Exercise 31.1 (Level 1, read and diagnose): Three things that are not removal

A key was committed and pushed last week. For each action, say what it changes and name every place where the key still is.

1. A new commit deletes the file.
2. `git commit --amend` on the commit that added it (it was the tip), then `git push --force-with-lease`.
3. The repository is made private.
4. The branch is deleted on the server, and it had an open pull request.
5. `.env` is added to `.gitignore`.

Then name the one action that makes the key harmless wherever it is.

### Exercise 31.2 (Level 2, read and diagnose): Fix the order

A team wrote this plan after finding a provider API key in history. Reorder it, say what is missing, and say which steps may be unnecessary.

1. Rewrite history with git-filter-repo.
2. Force-push.
3. Ask everyone to re-clone.
4. Open a ticket with GitHub Support.
5. Rotate the key "once the repository is clean, so that the new key does not leak too".
6. Write the postmortem.

### Exercise 31.3 (Level 2, read and diagnose): Rewrite or not?

For each case decide whether a history rewrite is warranted, and give the reason from section 21B.14.

1. An LLM provider key, revoked within the hour; the provider's logs show no use.
2. A CSV with 4,000 customer email addresses, in a private repository with twelve collaborators.
3. A 900 MB model checkpoint with proprietary weights, in a public repository for two days.
4. A password to a staging database that the DBA says takes three weeks to rotate.
5. A dummy key in a test fixture that a scanner flagged.

Then list four costs of a rewrite that the team pays whatever the reason.

### Exercise 31.4 (Level 3, read and diagnose): Review this runbook

A colleague drafted this for removing a file from history. Find the mistakes; there are at least seven. For each, the consequence and the correction.

```text
1. In my working clone, run the filter to remove the file from main and develop.
2. Push with: git push --force origin main develop
3. Post in the channel: "History was rewritten, please git pull."
4. Colleagues with local work: run the same filter command yourselves, then pull.
5. Re-run the secret scan on main. Clean means done.
6. Rules that block force pushes: switch them off before step 2. (No further step.)
7. Close the incident.
```

### Exercise 31.5 (Level 4, local simulation): How far did it get?

```bash
bash labs/ex3/setup-x31-5-exposure.sh
labs/shell x31-5/you/chunker
```

You are in your clone of `chunker`, on `main`. A bare repository beside it plays GitHub. A scanner in another system flagged the string `DUMMY-KEY` in this repository. The key is a dummy; treat it as a real storage key for the exercise.

Symptoms:

- `git grep DUMMY-KEY` finds nothing. A teammate says: "It was removed last week. False alarm."
- The scanner's alert names no commit.

Produce the assessment sheet of section 21B.14, as far as Git can answer it: which file, the first commit that contains the key, who committed it and when, the commit that removed it, how many snapshots contain it, which branches and tags contain it, and every place where the key is that a file-path removal would not touch. State which of the five assessment facts Git cannot answer and who can.

Self-check:

- [ ] You used at least one command that searches diffs and one that searches snapshots, and you can say what each cannot see.
- [ ] You looked on every ref, not only on your current branch.
- [ ] You found the occurrence that is not in any file.
- [ ] You can say what a rewrite that removes only the file would leave behind, in two places.
- [ ] You changed nothing in the repository.

### Exercise 31.6 (Level 3, read and diagnose): The secret came back

A history rewrite was completed on Tuesday and verified: a scan over all refs was clean. On Wednesday the scanner reports the secret on `main` again. `git log --merges -1 main` shows a merge commit made by a colleague on Wednesday morning with the message "Merge branch 'main' of ..." and two parents. No force push happened; the rule that blocks force pushes was switched back on Tuesday evening.

1. Reconstruct what the colleague did, command by command, and why the server accepted the push.
2. Which parent of the merge leads to the old history? How do you tell with one command per parent?
3. Why did the force-push rule not help?
4. Write the repair for the server, and the exact instructions for the colleague's clone, in order. Why does the rebase in those instructions need `--onto`?
5. Name a server-side control that would have refused the push, and its nearest equivalents on GitHub.

### Exercise 31.7 (Level 5, production incident): Lead the response

Thursday 11:00. An engineer reports that a notebook `analysis/eval-2026-09.ipynb`, committed three weeks ago to the public repository `northwind-ml/eval-reports`, has an output cell that prints an LLM provider key. Evidence and statements:

- The engineer already removed the output and pushed at 10:40. "It is gone from `main`."
- The provider is one that GitHub notifies about public leaks. "So they will have disabled it already."
- No push-protection block was seen three weeks ago.
- The repository has 14 forks and a tag `v2026.09` that was created two weeks ago.
- The key belongs to the team's shared provider account, which also hosts two fine-tuned models.
- Someone proposes making the repository private "right now, before anything else".
- Someone else has already started `git filter-branch` in his working clone.

1. What is the first action, who does it, and why does none of the others come first?
2. Assess the "they will have disabled it" statement. What do you check, and where?
3. Why might push protection not have blocked the push, even for a supported key type?
4. Write the assessment facts you need and the Git command for each one that Git can answer.
5. Decide on a history rewrite. Give the reason, and what you say to the colleague running `filter-branch`.
6. What do the forks and the tag mean for the exposure?
7. Give the prevention list, with the item that addresses notebooks specifically.
