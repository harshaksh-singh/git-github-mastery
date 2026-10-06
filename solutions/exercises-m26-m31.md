# Solutions, Modules 26 to 31: GitHub Actions and security

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Every transcript is real output of a script in `labs/ex3/`. Nothing was run on GitHub: the workflow files under `exercises/workflows/` were parse-checked and never executed, and every statement about what GitHub Actions does is taken from the textbook section cited beside it, which carries the link to the documentation. Corrected workflow lines in this file were assembled from the same documented syntax and were not executed either. The security material is defensive: weaknesses are named and fixed, and no attack is given.

Questions are in [the exercise file](../exercises/m26-m31-actions-security.md). Each solution has four parts: the solution, the reasoning, the common mistakes, and the expert approach.

---

## Module 26

### Solution 26.1: True or false, with the reason

**Solution.**

1. False. A job is the unit of isolation: each starts on a fresh machine. Data crosses jobs only as job outputs, artifacts or caches.
2. True. Steps of one job share the runner's filesystem.
3. False. Each `run` step is a new shell process. Write to `$GITHUB_ENV` to set a variable for later steps.
4. True. The implicit template is `bash -e {0}`.
5. False. `-e` does not look inside a pipeline; the status is that of `tee`. Only `shell: bash` adds `-o pipefail`.
6. True. For `push` and `pull_request` the workflow file is read from the commit the event refers to.
7. False. `schedule` uses the file on the default branch.
8. False. An unset secret is an empty string, not an error; the step fails later, somewhere else, if at all.
9. False. One commit, no tags. For a pull request, HEAD is detached at the test merge.
10. False. "You cannot change the contents of an existing cache."

**Reasoning.** Each statement is one documented default about what a runner has when your command starts (Chapter 20A, sections 20A.2, 20A.4, 20A.6, 20A.7, 20A.8 and 20A.11).

**Common mistakes.** Treating a workflow as one script on one machine. Assuming "green" means "every command succeeded".

**Expert approach.** For any job, say aloud: which machine, which commit, how much history, which shell, which token, which variables. Reference: Chapter 20A, sections 20A.2 to 20A.11.

### Solution 26.2: Which commit, which ref, which file?

**Solution.**

| # | `GITHUB_REF` | `GITHUB_SHA` | Workflow file from |
|---|---|---|---|
| 1 | `refs/heads/feature/x` | the tip commit that was pushed | the pushed commit |
| 2 | `refs/pull/N/merge` | the test merge commit | the commit of the event, so the branch's version takes part |
| 3 | no run at all | | `pull_request` workflows do not run while the pull request conflicts |
| 4 | the default branch | the last commit on the default branch | the default branch; yesterday's change on `feature/x` is not used |
| 5 | `refs/heads/feature/x` | the last commit on that branch | see below |
| 6 | no run | | events created with the job token start no workflow runs |
| 7 | as in the original run | the original test merge commit | as in the original run |

5. It works only if the workflow file exists on the default branch and declares `on: workflow_dispatch`. The events table of section 20A.4 gives the ref and commit above. The run uses the copy of the file on the chosen ref (the events table, and the investigation table of Chapter 20B, section 20B.11: it "can be triggered only if the file exists on the default branch, and the run is dispatched against the branch or tag you choose"); confirm it from the run itself: `gh run view RUN_ID --json headSha,headBranch`.
6. None, with the documented exceptions `workflow_dispatch`, `repository_dispatch` and, since June 2026, pull request events that wait for approval.
7. The original one. A re-run uses the same `GITHUB_SHA` and `GITHUB_REF` as the original event; it does not pick up a newer `main`.

**Reasoning.** Events come in three families: about a commit somebody produced (`push`, `pull_request`), about the default branch (`schedule`), and about a ref somebody chose (`workflow_dispatch`) (Chapter 20A, section 20A.4; Chapter 20B, section 20B.14).

**Common mistakes.** Expecting `GITHUB_SHA` of a pull request run to be the head commit. Testing a scheduled workflow from a branch. Expecting a re-run to test today's base.

**Expert approach.** Read the event, the ref and the commit of a run before reading its log. Reference: Chapter 20A, sections 20A.4 and 20A.8; Chapter 20B, sections 20B.11 and 20B.14.

### Solution 26.3: Six things the author did not mean

**Solution.**

| # | Line | What happens | What the author sees | Fix |
|---|---|---|---|---|
| 1 | `python: [3.9, 3.10, 3.11]` | unquoted `3.10` is the number 3.1 | a job that asks for Python 3.1 | `["3.9", "3.10", "3.11"]` |
| 2 | `run: >` | `>` folds the lines into one: `uv sync --locked uv run pytest \| tee test-log.txt` | one wrong command instead of two right ones | `run: \|` |
| 3 | `uv run pytest \| tee test-log.txt` with no `shell:` | `bash -e` without `pipefail`: the step takes the status of `tee` | green when tests fail | `shell: bash`, or `defaults.run.shell: bash` |
| 4 | `> "$GITHUB_OUTPUT"` twice, in a step without `id` | the second `>` discards the first line, and a step without an `id` has no addressable outputs | an empty value later | `>>` both times, and `id: version` |
| 5 | `if: ${{ ... }} && github.ref == ...` | text outside `${{ }}` makes the value a non-empty string, which is truthy | the report job also runs for pull requests | wrap the whole expression: `${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}` |
| 6 | `${{ steps.version.outputs.version }}` in the `report` job | a step output is local to its job; a missing property is an empty string, without an error | "Built version " with nothing after it | declare `outputs:` on `build` and read `needs.build.outputs.version` |

Flaws 3 and 5 are the two that turn red into green or run what should not run. The corrected `build` and `report` jobs:

```yaml
  build:
    name: Build
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - name: Compute the version
        id: version
        run: |
          echo "commit=$GITHUB_SHA" >> "$GITHUB_OUTPUT"
          echo "version=0.4.${GITHUB_RUN_NUMBER}" >> "$GITHUB_OUTPUT"

  report:
    name: Report
    needs: build
    if: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - name: Print the version
        env:
          VERSION: ${{ needs.build.outputs.version }}
        run: echo "Built version $VERSION" >> "$GITHUB_STEP_SUMMARY"
```

**Reasoning.** A workflow file is data that a YAML parser reads before Actions interprets any key, and expressions fail silently by design: a missing property is an empty string (Chapter 20A, sections 20A.3, 20A.5 and 20A.7). PyYAML reads the matrix of this file as `[3.9, 3.1, 3.11]` and the folded block as one line; that was checked when the file was written.

**Common mistakes.** Looking for a syntax error: the file parses. Fixing flaw 6 by copying the computation into the second job. Quoting only `3.10`.

**Expert approach.** Print outputs in the step that writes them, quote every version, set the shell once per workflow, and read the annotation that a run shows for an `if` with stray text. Reference: Chapter 20A, sections 20A.3, 20A.5, 20A.7 and 20A.16.

### Solution 26.4: Will the path filter start the workflow?

**Solution.**

<!-- snippet: ex3/x26-path-filter/02-pull-request -->
```text
$ git diff --name-only origin/main...docs/chunk-sizes
docs/chunk-sizes.md
$ git diff --name-only origin/main..docs/chunk-sizes
config/chunking.yaml
docs/chunk-sizes.md
```
<!-- /snippet -->

- a. No. For a pull request the filter is evaluated on the three-dot diff, which lists only `docs/chunk-sizes.md`. The first two commits cancel each other, so the branch as a whole does not change `chunker/split.py`.
- b. The two-dot diff adds `config/chunking.yaml`, which changed on `main`, not on your branch. It would blame the branch for somebody else's change; it still lists nothing under `chunker/`.

<!-- snippet: ex3/x26-path-filter/03-push -->
```text
# The first commit is on the server. You push the second and third together: old tip, new tip.
$ git diff --name-only docs/chunk-sizes~2..docs/chunk-sizes
chunker/split.py
docs/chunk-sizes.md
# Instead: the first two commits are on the server. You push the third alone.
$ git diff --name-only docs/chunk-sizes~1..docs/chunk-sizes
docs/chunk-sizes.md
```
<!-- /snippet -->

- c. Yes. For a push the filter uses a two-dot diff between the old and the new tip of the pushed branch. The old tip is the first commit, in which `chunker/split.py` has the overlap parameter; the new tip does not have it. The file differs, so the workflow starts.
- d. No. Between the second and the third commit only the documentation file differs.
- e. A workflow that a filter skips never creates its check, so a ruleset that requires it waits for a result that will not come. Do not filter a required workflow: start it always, decide inside which jobs do work, and require one job that always reports.
- f. No. Path filters are not evaluated for pushes of tags.

**Reasoning.** A path filter compares snapshots, not commits: what matters is the difference between two trees, and which two depends on the event (Chapter 20A, section 20A.4). What the first push of a new branch is compared with is not stated in the chapter, so the exercise avoids that case.

**Common mistakes.** "A commit touched `chunker/`, so the workflow runs." Predicting with `git diff main`, which is the two-dot form. Requiring a filtered workflow.

**Expert approach.** Before pushing, run the diff that GitHub will run. For a pull request: `git diff --name-only origin/main...HEAD`. Reference: Chapter 20A, sections 20A.4 and 20A.16; Chapter 20B, section 20B.13.

### Solution 26.5: Two shells, three scripts

**Solution.**

<!-- snippet: ex3/x26-shell/02-answers -->
```text
$ bash -e ../a.sh
tests finished
[exit status: 0]
$ bash --noprofile --norc -eo pipefail ../a.sh
[exit status: 1]
$ bash -e ../b.sh
[exit status: 128]
$ bash --noprofile --norc -eo pipefail ../b.sh
[exit status: 128]
$ bash -e ../c.sh
version is []
[exit status: 0]
$ bash --noprofile --norc -eo pipefail ../c.sh
version is []
[exit status: 0]
```
<!-- /snippet -->

| Script | `bash -e` | `shell: bash` template |
|---|---|---|
| a, a pipeline | status 0, the `echo` prints | status 1, no `echo` |
| b, a plain assignment | status 128, no `echo` | status 128, no `echo` |
| c, `export` with a substitution | status 0, prints an empty version | status 0, prints an empty version |

1. Script a: the pipeline's status is that of `tee`.
2. Script c. The status of `export VERSION=$(...)` is the status of `export`, which succeeded; the failed substitution is lost. `-e` reacts to the status of a command, and here the command is `export`. In script b the assignment has no command of its own, so its status is that of the substitution.
3. Two lines: `VERSION=$(git describe)` and then `export VERSION`.
4. `defaults: run: shell: bash` at the top level of the workflow.

**Reasoning.** The runner writes the `run` text to a file and executes it with a documented template (Chapter 20A, section 20A.7). `pipefail` closes one hole. It does not close the hole in script c, which is a property of the shell and not of the template.

**Common mistakes.** Believing `shell: bash` makes every failure visible. Silencing `git describe` with `2>/dev/null` or `--always` in a release build, which ships a wrong version.

**Expert approach.** State the shell once, keep assignments and `export` on separate lines, and let version commands fail loudly. Reference: Chapter 20A, sections 20A.7 and 20A.8.

### Solution 26.6: Caches and artifacts

**Solution.**

1. The key does not depend on the lock file, so it never changes; a cache is immutable per key, and the entry saved long ago is restored every time. Put `hashFiles('uv.lock')` into the key, and install with `uv sync --locked` so that a stale cache cannot change what is installed.
2. Cache scope. A run can restore caches created on its own branch or on the default branch, and a pull request run also from its base branch. Sibling branches cannot read each other's caches.
3. No. `cache-hit` is `true` only for an exact match on the primary key. A restore key matched, which restores an entry and reports `false`.
4. "The files that were tested are the files that are deployed": a rebuild resolves dependencies again, possibly to other versions.
5. An artifact cannot be changed after upload, and a second upload with the same name in one run fails. Either set `overwrite: true`, or put `${{ github.run_attempt }}` into the name. That a re-run counts as the same run for this rule is an inference from "a re-run is a new attempt of the same run"; confirm it on your repository.
6. A repository has 10 GB of cache without charge, shared by all branches, and above the limit the least recently used entries are deleted: the checkpoint evicts the dependency caches. And a cache is an optimization that may be absent: entries unused for 7 days are removed.

**Reasoning.** A cache is for files that can be recreated and are reused between runs; an artifact is for files a job produced that must be passed on or kept (Chapter 20A, sections 20A.11 and 20A.12).

**Common mistakes.** Broad `restore-keys` as a habit. Treating a cache as storage. Rebuilding in the deploy job.

**Expert approach.** Key on the lock file, install from the lock file, move build outputs as artifacts, and keep models in a registry. Reference: Chapter 20A, sections 20A.11, 20A.12 and 20A.17.

### Solution 26.7: Read a run from the terminal

**Solution.** `headSha` is the head commit of your branch, which is what you have locally. The job printed `GITHUB_SHA`, which for a `pull_request` event is the test merge commit under `refs/pull/N/merge`, a commit that neither you nor anybody else on the team created. The job's clone is shallow (`true`), so `git describe` finds no tag to describe. `gh run watch --exit-status` exits non-zero when the run fails, so a script can chain on it. To bring the tested commit into your clone: `git fetch origin pull/N/merge`, after which it is in `FETCH_HEAD`.

**Reasoning.** CI on a pull request tests the merged result, not the head alone (Chapter 20A, section 20A.8; Chapter 17, section 17.2).

**Common mistakes.** Comparing the wrong two IDs and concluding that CI ran "another branch". Running `git show` on the ID from the log and reading the error as corruption.

**Expert approach.** Compare the run's commit with `git rev-parse HEAD` before comparing anything else. The commands were checked against `--help` of 2.88.1 and not run by the author. Reference: Chapter 20A, section 20A.8; Chapter 20B, sections 20B.11 and 20B.14.

---

## Module 27

### Solution 27.1: An environment, read back

**Solution.** The first command is a `PUT` and creates or replaces the environment; `gh variable set` writes a variable; the other three are reads. The read-back of the environment shows its protection rules: after a bare `PUT` there are none, so a job that names it starts at once. Had a workflow named a missing environment instead, GitHub would have created it, without rules, and anyone who can edit workflows can cause that; only repository administrators can configure it. Environments, their rules, secrets and deployment records are GitHub objects: no clone contains them, and a mirror to another host loses every gate.

**Reasoning.** The only trace of an environment in Git is the word after `environment:` in a workflow file (Chapter 20B, section 20B.2).

**Common mistakes.** Believing a gate exists because the YAML names an environment. Leaving unused environments behind, which later look like protected targets.

**Expert approach.** Create environments before the workflows that use them, keep their configuration in a reviewed script, and read the rules back after every change. Reference: Chapter 20B, sections 20B.2 and 20B.4.

### Solution 27.2: A deployment with five flaws

**Solution.**

| # | Flaw | What happens, silently | Fix |
|---|---|---|---|
| 1 | `environment: name: prodution` | naming a missing environment creates it, with no rules: no reviewer, no branch rule, and none of the real environment's secrets, so `DEPLOY_TOKEN` is empty | `production`; delete the stray environment |
| 2 | No `needs: build` on the deploy job | jobs run in parallel unless ordered: the deployment starts before the tests have finished | `needs: build` |
| 3 | The deploy job runs `uv sync` and `uv build` again | it deploys a second build, resolved without `--locked`, that nobody tested | upload `dist/` in `build`, download it in the deploy job |
| 4 | Workflow-level `concurrency` with `cancel-in-progress: true` | a second push to `main` cancels a deployment half-way | for the deploy job: `group: production`, `cancel-in-progress: false` |
| 5 | The `build` job reads `secrets.DEPLOY_TOKEN` | an environment secret is available only to jobs that reference the environment; here the value is an empty string and `test -n` fails the build. If someone "fixes" that by making it a repository secret, test code and dependency scripts run next to a deployment credential | remove the step; the credential belongs in the one job that deploys |

Three things together make "only reviewed code reaches production" true: a ruleset that forces changes to `main` through reviewed pull requests, an environment that accepts only `main`, and a required reviewer on that environment. The ruleset is not in this file at all, and neither are the environment's rules.

**Reasoning.** Protection rules are properties of the environment object, checked before a runner is assigned; the workflow file only names it (Chapter 20B, sections 20B.2 to 20B.5).

**Common mistakes.** Reading the typo as a failure that GitHub would report. Checking for the credential in the build job "to fail early". Copying the CI concurrency pattern onto a deployment.

**Expert approach.** For a delivery workflow ask: is there one build, does every job that deploys wait for it, which job holds the credential, and what does the environment on GitHub say when read back with `gh api`? Reference: Chapter 20B, sections 20B.2 to 20B.5 and 20B.16.

### Solution 27.3: Three pushes in ten minutes

**Solution.**

1. Group only: A runs. B is pending. C arrives and cancels the pending B. D arrives and cancels the pending C. When A ends, D runs. Deployed: A, then D.
2. With `cancel-in-progress: true`: B cancels A while A is deploying, C cancels B, D cancels C. Only D completes, and three deployments were interrupted half-way.
3. With `queue: max`: A, B, C and D all run, one at a time. The documentation states that ordering is not guaranteed, so design the deployment to tolerate that or to be cumulative.
4. No key: four runs, overlapping, deploying at the same time.

A migration per commit needs configuration 3. Pull request CI wants `cancel-in-progress: true`, because only the newest commit matters. Configuration 2 on a deployment leaves a state nobody designed. A group named `${{ github.workflow }}-${{ github.ref }}` gives every branch and pull request its own track, so that runs on different refs do not cancel each other.

**Reasoning.** By default a group lets one run execute and one wait, and a newly queued run cancels the one already pending (Chapter 20B, section 20B.5).

**Common mistakes.** Expecting the default to queue everything. Assuming an environment serialises deployments: `concurrency` and `environment` are not connected. Sharing a group name between two workflows by accident; a group is not private to a workflow.

**Expert approach.** Decide per workflow whether every run must happen or only the latest, and write the queue policy on purpose. Reference: Chapter 20B, section 20B.5.

### Solution 27.4: A guard against going backwards

**Solution.** One implementation, with the history it is tested on:

<!-- snippet: ex3/x27-deploy-guard/01-state -->
```text
$ git log --graph --oneline --all --decorate-refs=refs/heads --decorate-refs=refs/deployed
* d020302 Double the default chunk size
| * dec6332 Reject an overlap that is not smaller than the size
| * 5a94977 Add overlap parameter
|/  
* 8ccb72e Add chunking config
* 39a113d Add fixed-size splitter
```
<!-- /snippet -->

<!-- snippet: ex3/x27-deploy-guard/02-guard -->
```text
$ cat guard.sh
#!/bin/sh
# usage: sh guard.sh <candidate commit>
# Exit 0 only if the candidate contains everything that production runs, and more.
deployed=$(git rev-parse --verify --quiet refs/deployed/production^{commit}) || { echo "guard: nothing recorded as deployed"; exit 2; }
candidate=$(git rev-parse --verify --quiet "$1^{commit}") || { echo "guard: unknown commit $1"; exit 2; }
if [ "$candidate" = "$deployed" ]; then
  echo "guard: $1 is what production already runs"; exit 1
fi
if git merge-base --is-ancestor "$candidate" "$deployed"; then
  echo "guard: REFUSED, $1 is older than production; this would roll back:"
  git log --oneline "$candidate..$deployed"; exit 1
fi
if ! git merge-base --is-ancestor "$deployed" "$candidate"; then
  echo "guard: REFUSED, $1 does not contain what production runs; missing:"
  git log --oneline "$candidate..$deployed"; exit 1
fi
echo "guard: ok, this deployment adds:"
git log --oneline "$deployed..$candidate"
```
<!-- /snippet -->

<!-- snippet: ex3/x27-deploy-guard/03-forward -->
```text
$ sh guard.sh main
guard: ok, this deployment adds:
dec6332 Reject an overlap that is not smaller than the size
5a94977 Add overlap parameter
[exit status: 0]
$ git update-ref refs/deployed/production main
```
<!-- /snippet -->

<!-- snippet: ex3/x27-deploy-guard/04-backward -->
```text
# A re-run of an old deployment run carries the old commit:
$ sh guard.sh main~1
guard: REFUSED, main~1 is older than production; this would roll back:
dec6332 Reject an overlap that is not smaller than the size
[exit status: 1]
$ sh guard.sh main
guard: main is what production already runs
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ex3/x27-deploy-guard/05-sideways -->
```text
$ sh guard.sh hotfix/config
guard: REFUSED, hotfix/config does not contain what production runs; missing:
dec6332 Reject an overlap that is not smaller than the size
5a94977 Add overlap parameter
[exit status: 1]
```
<!-- /snippet -->

The refusal that is sometimes wrong is the first: a rollback is a legitimate decision. Let a human override it explicitly and visibly, for example with an input of a manually started run that the deploy script reads, in a job behind an environment with a required reviewer. The sideways case should stay refused: a hotfix must first contain what production runs.

**Reasoning.** "Does this deployment go forwards?" is the ancestry question `git merge-base --is-ancestor`, asked in both directions. A re-run is a new attempt at the original commit and ref, so on a deploy workflow it is a rollback nobody announced (Chapter 20B, section 20B.14).

**Common mistakes.** Comparing dates or version strings instead of ancestry. Testing only one direction, which lets a sideways deployment through. Running the guard in a shallow clone: with `fetch-depth: 1` the ancestry question cannot be answered, so the deploy job needs history.

**Expert approach.** Print the range a deployment adds into the job summary every time, and make the guard part of the deploy script, where every caller gets it. Reference: Chapter 20B, sections 20B.3, 20B.14 and 20B.16.

### Solution 27.5: Four reusable-workflow surprises

**Solution.**

1. Environment secrets cannot be passed by the caller, because `on.workflow_call` does not support the `environment` keyword. The called job must name the environment itself, for example `environment: ${{ inputs.environment }}`, and read the secret there. The chapter marks one detail of this area as unverified: how an environment's secrets appear when the caller passes named secrets without `inherit`.
2. `env` does not cross. Variables in the caller's workflow-level `env` are not visible in the called workflow. Use an input, or a configuration variable in `vars`.
3. The check of a job in a called workflow is named `<calling job name> / <called job name>`. The ruleset still requires the old, bare name. Require the new name, or better, one aggregate job.
4. A called workflow sees the caller's name in `github.workflow`, so both files compute the same group, and with `cancel-in-progress: true` the called job cancels its own caller. Keep the group in one of the two files, or give the called one a distinct name.

`@main` is a mutable reference to a file that runs with deployment credentials in forty repositories: pin it to a full commit ID. And re-running all jobs resolves a reference that is not a commit ID again, so a first run and a full re-run can execute different versions.

**Reasoning.** A reusable workflow is called as if it were one job, with its own interface: inputs, declared secrets, outputs. The `github` context is the caller's (Chapter 20B, sections 20B.5 and 20B.6).

**Common mistakes.** Assuming `secrets: inherit` covers environment secrets. Extracting a reusable workflow without updating required check names.

**Expert approach.** Treat the move to a reusable workflow as an interface change: list what crossed implicitly before (env, secrets, check names, concurrency) and decide each one. Reference: Chapter 18, section 18.8; Chapter 20B, sections 20B.5, 20B.6 and 20B.17.

### Solution 27.6: The release that triggers nothing

**Solution.**

1. "Events triggered by the `GITHUB_TOKEN` will not create a new workflow run." The release was created with the job token, so `on: release` never fires. The documented exceptions are `workflow_dispatch` and `repository_dispatch`, and since June 2026 pull request events that wait for approval.
2. Either make publishing a job of the same workflow, ordered with `needs`, or create the tag and release with a GitHub App token, whose events do start workflows. The first is simpler and keeps everything in one run; the second keeps two files and costs you an app and the safe-keeping of its private key.
3. Without `--verify-tag`, `gh release create` creates a tag that does not exist, at the tip of the default branch. `--verify-tag` turns that into an error.
4. Create a draft, attach every asset, then publish.

**Rubric** (2 points each, 8 in total): the rule and its exceptions; a working design with its trade-off; `--verify-tag`; the draft, assets, publish order.

**Reasoning.** The rule exists so that a workflow cannot start itself in a loop; it is also one of the two properties that limit a stolen job token (Chapter 20B, section 20B.7; Chapter 21A, section 21A.3).

**Common mistakes.** Storing a personal token as a secret to "make the trigger work". Debugging `publish.yml`, which is correct and never runs.

**Expert approach.** When a workflow "never fires", ask which identity caused the event before reading the trigger. Reference: Chapter 15, section 15.12; Chapter 20A, section 20A.4; Chapter 20B, section 20B.7.

### Solution 27.7: Production changed, and nobody approved it

**Solution.**

1. A re-run is not a new run: it uses "the same `GITHUB_SHA` and `GITHUB_REF` of the original event". Re-running the failed jobs of Tuesday's run executed the deploy job again, at Tuesday's commit, over Thursday's release.
2. On Wednesday the repository became private, on the Team plan. Required reviewers on environments are available for public repositories on every plan and for private ones only on Enterprise. The rule the team lead remembers no longer applies. Confirm by reading the environment: `gh api repos/OWNER/REPO/environments/production`.
3. Force push: `origin/main` has Thursday's commits, and a deployment changes nothing in Git anyway. Concurrency: the re-run's deploy job completed; a cancelled run has the conclusion `cancelled`.
4. Deploy Thursday's commit with a fresh run from `main`. A re-run of Thursday's run would also deploy Thursday's commit, which happens to be right today; as a habit it is the mechanism that caused this incident, so start a new run and verify what it carries with `gh run view RUN_ID --json headSha`.
5. In the deploy script: an ancestry guard that refuses to go backwards (Exercise 27.4). On GitHub: a plan or visibility on which the reviewer rule exists, re-read after every visibility change; a short artifact retention for deploy runs. Outside GitHub: bind the production credential to the environment at the cloud provider, so that the gate does not depend on one platform setting.

**Reasoning.** Two documented behaviors met: a re-run is a time machine, and environment protection is plan-gated (Chapter 20B, sections 20B.2, 20B.14 and 20B.17). The plan table is among the facts most likely to have changed; re-check it.

**Common mistakes.** Looking for the cause in Git. Trusting the YAML's `environment: production` as evidence of a gate. Re-running old deploy runs to fetch their artifacts: `gh run download` does that without executing anything.

**Expert approach.** For "who approved what is running", go to the GitHub objects: the run, its commit, the environment's rules as they are today. Reference: Chapter 20B, sections 20B.1, 20B.2, 20B.4, 20B.14 and 20B.16.

---

## Module 28

### Solution 28.1: Where in the order?

**Solution.**

| # | First question that finds it | Look at |
|---|---|---|
| 1 | 12, concurrency | `gh run list --workflow FILE`; the group name |
| 2 | 1, workflow | `schedule` uses the file on the default branch |
| 3 | 3, permissions | the top-level and job-level `permissions`; unlisted scopes are `none` |
| 4 | 2, event, which leads to 7, secrets | a fork pull request gets no secrets; the value is an empty string |
| 5 | 4, runner | public or private repository: 4 CPUs and 16 GB against 2 and 8 |
| 6 | 6, dependencies | the lock file, `--locked`, versions printed by the setup steps |
| 7 | 10, artifacts | names, the uploading job, expiry |
| 8 | 5, environment | waiting for a reviewer or a wait timer |

**Reasoning.** The order goes from "did the right thing start at all" to "what did it say"; an answer early in the list makes everything after it irrelevant (Chapter 20B, section 20B.11).

**Common mistakes.** Opening the red step first. In case 4, debugging the cloud credentials.

**Expert approach.** Steps 1 and 2 remove the most confusion for the least effort: `gh run view RUN_ID --json workflowName,headSha,headBranch,event`. Reference: Chapter 20B, sections 20B.11 and 20B.12.

### Solution 28.2: The nightly evaluation that never fails

**Solution.**

| # | Flaw | Effect | Fix |
|---|---|---|---|
| 1 | `cron: "0 2 * * *"` | cron is UTC unless a time zone is given: this is 07:30 in Bengaluru | `"30 20 * * *"` for 02:00 Indian time, or the `timezone` setting added in March 2026 |
| 2 | `if: ${{ ... }} && github.repository == ...` | text outside the wrapper makes a truthy string: the condition is always true, also in forks | wrap the whole expression |
| 3 | `runs-on: ubuntu-latest`, no `timeout-minutes` | the image changes under you (the label migrates to Ubuntu 26.04 from 19 October 2026), and a hung evaluation bills up to six hours | `ubuntu-24.04` and a timeout |
| 4 | `continue-on-error: true` on the evaluation step | a failed step has outcome `failure` and conclusion `success`: the job stays green | remove it |
| 5 | `uv run pytest tests/eval \| tee eval-log.txt` without a declared shell | even without flaw 4, the step takes the status of `tee` | `defaults.run.shell: bash` |

The last step has a sixth, smaller problem: `git describe --always` in a one-commit clone prints a bare commit ID as if it were a version.

Two properties of `schedule` that remain: a scheduled run can be delayed and, under load, dropped, so nothing that must happen at a given minute belongs there; and in a public repository scheduled workflows are disabled after 60 days without repository activity. The run always uses the workflow file and the last commit of the default branch.

**Reasoning.** Flaws 4 and 5 each hide the failure alone, which is why removing one of them changes nothing visible (Chapter 20A, sections 20A.4, 20A.5, 20A.7 and 20A.9; Chapter 20B, section 20B.8).

**Common mistakes.** Removing `continue-on-error` and concluding from the still-green run that the score is fine. Testing the schedule from a branch.

**Expert approach.** For a job whose purpose is to alarm, make it fail once on purpose and watch the alarm arrive. Reference: Chapter 20A, sections 20A.4, 20A.5, 20A.7, 20A.9 and 20A.17; Chapter 20B, sections 20B.8 and 20B.17.

### Solution 28.3: A required check that cannot be red

**Solution.**

1. `unit-tests` fails. `lint` needs it and is skipped. `all-checks` runs because of `always()`, prints a line and succeeds. The only required check is green: the pull request can merge with failing tests.
2. The `ruff` step fails with `continue-on-error: true`, so the `lint` job succeeds. `all-checks` is green.
3. The flaws: the aggregate job never looks at the results it aggregates; `lint` is ordered after `unit-tests` for no reason, so a test failure also hides the linter's verdict; and `continue-on-error` makes the linter unable to fail. The rewrite, in the form the chapter gives:

```yaml
  lint:
    name: lint
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
      - run: uv sync --locked
      - run: uv run ruff check .

  all-checks:
    name: all-checks
    if: ${{ !cancelled() }}
    needs: [unit-tests, lint]
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - name: Fail if a needed job failed or was cancelled
        if: ${{ contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled') }}
        run: exit 1
```

4. `always()` is true even when the run was cancelled; the expressions page advises against it for anything that could fail critically and recommends `!cancelled()` for "run whether or not the earlier steps passed".
5. A skipped job reports success, and a job skipped because a job it needs failed "may not block merging". Requiring `lint` directly would have been satisfied by the skipped `lint` in case 1.

**Reasoning.** An aggregate job with a status function must test the results explicitly, or it turns red runs green (Chapter 20A, sections 20A.9 and 20A.17; Chapter 20B, section 20B.13). The file does have the `merge_group` trigger, which is right.

**Common mistakes.** Believing `needs` makes the aggregate job inherit failure: with a status function in `if`, it does not. Using `continue-on-error` to "keep the pipeline moving".

**Expert approach.** After writing an aggregate check, break each needed job once and confirm that the required check turns red. Reference: Chapter 18, section 18.8; Chapter 20B, section 20B.13.

### Solution 28.4: What does this pipeline cost?

**Solution.**

1. Each job is rounded up to a whole minute: 3 + 5 + 1 = 9 Linux minutes and 7 macOS minutes per push. With 880 pushes a month: 7,920 Linux minutes at $0.006 is $47.52, and 6,160 macOS minutes at $0.062 is $381.92. Together $429.44 a month at list price.
2. The macOS job: it is 89% of the bill. Running it only on `main` or nightly saves most of it, and the price is that a macOS-only failure is found after the merge instead of before.
3. No. It is billed as one minute, 880 minutes a month. As a step of the 4 min 5 s job it adds 20 seconds to a job that still rounds to 5 minutes, so the 880 minutes disappear.
4. Runs that are superseded by a newer push to the same ref are cancelled and stop accruing minutes. On `main` that also cancels the run of a commit that was merged, so its result and, if the workflow deploys, its deployment never happen; key the group on the ref and do not cancel in progress on `main`.
5. How Windows and macOS minutes consume the *included* minutes: older material gives multipliers of 2 and 10, and no 2026 page the research could fetch states it. Read your own usage in the billing settings.

**Reasoning.** The cost levers follow from the rules: per-job rounding, the macOS price at roughly ten times Linux, and cancellation (Chapter 20B, section 20B.10). Prices change; check the price page before writing an estimate.

**Common mistakes.** Summing seconds and multiplying. Splitting work into many small jobs "for clarity". Quoting a multiplier.

**Expert approach.** Estimate from billed minutes per job and per operating system, then check against the billing page, which is the only authoritative number. Reference: Chapter 20B, section 20B.10.

### Solution 28.5: Green here, red in a fresh clone

**Solution.** Replayed by `labs/run ex3/x28-fresh-clone`. A runner has a fresh clone and nothing else, so make one:

<!-- snippet: ex3/x28-fresh-clone/01-symptom -->
```text
$ ./scripts/smoke.sh
smoke ok: sample has 3 lines
[exit status: 0]
$ git status -sb
## main...origin/main
# What a runner has: a fresh clone and nothing else.
$ git clone -q ../../server/chunker.git ../../runner
$ (cd ../../runner && sh -c ./scripts/smoke.sh)
sh: ./scripts/smoke.sh: Permission denied
[exit status: 126]
```
<!-- /snippet -->

**Cause 1: the executable bit was never committed.** The index records mode `100644`. Your working file is executable, and `core.fileMode=false` in this clone told Git to ignore the difference, so `git status` was clean.

<!-- snippet: ex3/x28-fresh-clone/02-cause-1 -->
```text
$ git ls-files -s scripts/smoke.sh
100644 8a3399eaed79038ff3233552d217046645584dbc 0	scripts/smoke.sh
$ git config get --show-origin core.fileMode
file:.git/config	false
$ git update-index --chmod=+x scripts/smoke.sh
$ git ls-files -s scripts/smoke.sh
100755 8a3399eaed79038ff3233552d217046645584dbc 0	scripts/smoke.sh
$ git commit -q -m "Make the smoke test executable" && git push -q origin main
$ (cd ../../runner && git pull -q && sh -c ./scripts/smoke.sh)
grep: tests/fixtures/sample.txt: No such file or directory
[exit status: 2]
```
<!-- /snippet -->

**Cause 2: the fixture was never committed.** An unanchored ignore rule, `fixtures/`, meant for build output, also matches `tests/fixtures/`. The file exists only on your disk.

<!-- snippet: ex3/x28-fresh-clone/03-cause-2 -->
```text
$ git ls-files tests
tests/test_split.py
$ git check-ignore -v tests/fixtures/sample.txt
.gitignore:2:fixtures/	tests/fixtures/sample.txt
$ printf 'build/\n/build/fixtures/\n__pycache__/\n' > .gitignore
$ git status -s
 M .gitignore
?? tests/fixtures/
$ git add .gitignore tests/fixtures/sample.txt
$ git commit -q -m "Track the smoke-test fixture; anchor the ignore rule" && git push -q origin main
```
<!-- /snippet -->

<!-- snippet: ex3/x28-fresh-clone/04-verify -->
```text
$ rm -rf ../../runner && git clone -q ../../server/chunker.git ../../runner
$ (cd ../../runner && sh -c ./scripts/smoke.sh)
smoke ok: sample has 3 lines
[exit status: 0]
```
<!-- /snippet -->

**Reasoning.** "Passes locally" compares your working tree with the runner's clone of a commit. Everything that is on your disk and not in the commit is a candidate: ignored files, file modes that a local setting hides, and the tool versions around them (Chapter 20B, section 20B.12; Chapter 4 for ignore rules).

**Common mistakes.** Changing the CI command to `sh scripts/smoke.sh`, which hides cause 1. `chmod +x` and a commit, in a clone with `core.fileMode=false`: Git sees no change, so use `git update-index --chmod=+x` or `git add --chmod=+x`. Forcing the fixture in with `git add -f` and leaving the broad ignore rule to catch the next file.

**Expert approach.** Reproduce with `git clone` into a scratch directory before reading any log, and ask Git why a file is absent: `git ls-files`, `git ls-files -s`, `git check-ignore -v`. Other members of the family, which this repository does not have: a name that differs only in case, CRLF line endings, an LFS pointer that was not replaced, an empty submodule directory. Reference: Chapter 20B, sections 20B.11 and 20B.12.

### Solution 28.6: The machine changed, the code did not

**Solution.**

1. Standard runners have 4 CPUs and 16 GB in public repositories and 2 CPUs and 8 GB in private ones. Split the job or pay for a larger runner.
2. A `-latest` label is a moving name, and a migration is rolled out gradually over weeks, so two runs on one day can get different images. Use a fixed label such as `ubuntu-24.04`, and put its retirement date in the calendar.
3. A self-hosted runner must install each new release within 30 days or it stops receiving jobs, and since 29 September 2026 a runner older than 2.329.0 cannot register. Rebuild the image regularly or allow updates.
4. `macos-14` is unsupported from 2 November 2026, with brownouts in October. Move to a supported label.
5. A job waits until a matching runner is online and fails after 24 hours in the queue. The runner was offline or its labels did not match.

**Reasoning.** The runner is an input of the job like any other (Chapter 20B, sections 20B.8 and 20B.9).

**Common mistakes.** Re-running until the "flaky" job passes. Pinning a label and never moving it.

**Expert approach.** Ask first for the repository's visibility, then the label, then the image named in the job's log. Reference: Chapter 20B, sections 20B.8 to 20B.10.

### Solution 28.7: Every pull request is waiting

**Solution.**

1. The required check is a job in a called workflow, whose check is named `<calling job name> / <called job name>`. Renaming the calling job from `Staging` to `staging-deploy` changed the reported name; the ruleset still waits for the old one.
2. Every run reports a check under the new name. No run will ever report the old name again.
3. No. Required checks count only for runs triggered by certain events, and a `workflow_dispatch` run on the head branch is not evaluated for the pull request. It would also report the new name.
4. Not with a ruleset whose bypass list is empty: a ruleset binds administrators too. If it did work, it would mean a bypass exists that nobody knew about, and it would merge without the check.
5. A repository administrator edits the ruleset to require the name that the runs report today, read from `gh pr checks` and not typed from memory. That is a deliberate, recorded change, and it has to be the ruleset: a pull request that reverts the rename cannot merge either. Then move the rule to one aggregate job in the workflow itself, such as `all-checks`, so that job names and the matrix can change without touching the rule.

**Reasoning.** A required status check is a name. Nothing connects the rule to the workflow except that string (Chapter 18, section 18.8; Chapter 20B, section 20B.6).

**Common mistakes.** Re-running. Starting runs by hand. Reaching for `--admin`. Renaming jobs in a refactoring without searching the rulesets for their names.

**Expert approach.** Read the exact names from a real run, change workflow names and the rule in one coordinated step, and require an aggregate job. Reference: Chapter 18, sections 18.5, 18.8 and 18.17; Chapter 20B, sections 20B.6 and 20B.13.

---

## Module 29

### Solution 29.1: Whose code, whose text, what can it reach?

**Solution.**

| # | Whose code | Whose text | Reach | Verdict |
|---|---|---|---|---|
| 1 | the contributor's | none interpolated | a read-only token, no secrets | not a vulnerability: the fork model contains it |
| 2 | yours, from the default branch | none | may write to pull requests | safe as long as it never checks out or runs the pull request's code |
| 3 | the contributor's (`npm install` runs lifecycle scripts) | | a read-write token and the secrets the workflow names | a vulnerability: the "pwn request" pattern. `actions/checkout` v7 refuses this checkout unless `allow-unsafe-pr-checkout: true` is set, which is why that flag needs a written justification |
| 4 | yours | the issue title, pasted into the script | every write scope | a vulnerability: script injection on a trigger anyone can cause |
| 5 | the action's maintainers, or whoever moves the tag | | a cloud deployment identity | a finding: a mutable reference in the job that holds the most valuable credential. Pin it |
| 6 | the contributor's | | your machine and network, and its state after the job | a vulnerability: self-hosted runners "should almost never be used for public repositories" |

**Reasoning.** If the answer to the first two parts is "somebody outside the team" and the third is anything other than "nothing", you have found a vulnerability (Chapter 21A, section 21A.1).

**Common mistakes.** Calling case 1 unsafe and case 3 safe because "both run the tests". Judging case 4 by the harmless look of `echo`.

**Expert approach.** Ask the question per job, not per workflow, and review workflows as a set: the incidents come from two safe-looking workflows that share something. Reference: Chapter 21A, sections 21A.1 to 21A.7, 21A.12 and 21A.21.

### Solution 29.2: The comment workflow

**Solution.** The attacker-controlled data is the content of the artifact `pr-report`: `number.txt` and `summary.md` were produced by the unprivileged CI run, which executed the fork's code. They arrive through the download step.

<!-- snippet: ex3/x29-audit/03-expressions-in-run -->
```text
# An expression on a "run:" line, or on a line of a script (a line that is not "key: value"):
$ grep -n 'run:.*[$]{{' x29-*.yml
[exit status: 1]
$ grep -n '[$]{{' x29-*.yml | grep -v -E ':[0-9]+: +(- )?[A-Za-z_-]+: '
x29-pr-report.yml:44:          gh pr comment ${{ steps.pr.outputs.number }} --repo "$GITHUB_REPOSITORY" --body-file report/summary.md
```
<!-- /snippet -->

| # | Weakness | Class | Section |
|---|---|---|---|
| 1 | `${{ steps.pr.outputs.number }}` inside a `run` script: the value comes from a file the fork controls and is pasted into the script text before the shell starts | script injection, fed by an untrusted artifact | 21A.6, 21A.11 |
| 2 | The file's content is written to `$GITHUB_OUTPUT` without validation: whatever the file contains becomes outputs of the step | untrusted data used as structure | 21A.5, 21A.6 |
| 3 | `contents: write` on a job that only comments | excessive permissions | 21A.3 |

The two steps, rewritten so that the script is a constant and the artifact is data:

```yaml
      - name: Read and validate the pull request number
        id: pr
        run: |
          number=$(head -n 1 report/number.txt | tr -cd '0-9')
          [ -n "$number" ] || { echo "no pull request number in the report" >&2; exit 1; }
          echo "number=$number" >> "$GITHUB_OUTPUT"

      - name: Post the comment
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER: ${{ steps.pr.outputs.number }}
        run: gh pr comment "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --body-file report/summary.md
```

and at the top, `permissions: pull-requests: write` only. Posting `summary.md` as the body of a comment is the kind of use the chapter calls safe: the text is displayed, never executed and never interpolated into a script.

What the workflow gets right: the privileged half never checks out or runs the fork's code. That separation is the recommended design; the weaknesses are in how it handles what crosses.

**Reasoning.** "A `workflow_run` workflow should treat artifacts uploaded by other workflows as untrusted data, since their contents can come from a fork." The `env:` form works because the value no longer takes part in generating the script (Chapter 21A, sections 21A.5, 21A.6 and 21A.11). The `run-id` and `github-token` inputs of `actions/download-artifact` are documented in its [README at v8.0.1](https://github.com/actions/download-artifact/blob/v8.0.1/README.md), and the `workflow_run` trigger in the [events reference](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run); both pages were read on 5 October 2026.

**Common mistakes.** "It is only a number." Trusting an artifact because your own workflow uploaded it. Moving the expression to `env:` and then using the variable unquoted.

**Expert approach.** Draw the line that data crosses between the unprivileged and the privileged run, and for every item say: displayed, parsed or executed? Only "displayed", and "parsed after validation", are acceptable. Reference: Chapter 21A, sections 21A.3, 21A.5, 21A.6, 21A.11 and 21A.19.

### Solution 29.3: The release workflow

**Solution.**

<!-- snippet: ex3/x29-audit/02-uses -->
```text
$ grep -n 'uses:' x29-*.yml | grep -v -E '@[0-9a-f]{40} # v[0-9]'
x29-release.yml:45:        uses: aws-actions/configure-aws-credentials@v6
x29-release.yml:55:    uses: YOUR-ORG/shared-workflows/.github/workflows/notify.yml@main
```
<!-- /snippet -->

| # | Weakness | Which code gains what | Fix | Section |
|---|---|---|---|---|
| 1 | `id-token: write` at workflow level | every job, including `test` and everything `uv sync` and pytest execute, can request an OIDC token | grant it on the `publish` job only | 21A.10 |
| 2 | The `publish` job has no `environment` | no reviewer and no branch or tag rule stands between a tag push and the publishing role; the OIDC subject is a tag ref, which anyone with write access can create | `environment: production`, with protection rules, and a trust policy that names it | 21A.10, 21A.13 |
| 3 | The `publish` job restores a cache | an unsigned, shared directory is unpacked next to the publishing identity | `cache-mode: none` on that job; no `enable-cache` | 21A.11 |
| 4 | `aws-actions/configure-aws-credentials@v6` | whoever can move that tag runs code in the job that assumes the role | the commit ID from `workflows/ACTION_PINS.md`, with the version as a comment | 21A.7 |
| 5 | A reusable workflow at `@main` with `secrets: inherit` | a mutable reference receives every secret of the caller | pin to a full commit ID; pass only the secrets it needs, by name | 21A.7, 21A.21 |

A sixth, smaller point: neither checkout sets `persist-credentials: false`.

The corrected skeleton of the publishing job:

```yaml
permissions:
  contents: read

jobs:
  publish:
    name: Publish
    needs: test
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    environment:
      name: production
    permissions:
      contents: read
      id-token: write
    cache-mode: none
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - name: Assume the publishing role
        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: ${{ vars.PUBLISH_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
```

The trust policy you want, in words: the subject must *equal* the form for this repository and the environment `production`, not match a wildcard over the repository. That condition lives in the cloud account. The workflow can name the environment; only the cloud decides whether a token with another subject is accepted.

**Reasoning.** OIDC removes the long-lived key and does not make the job trustworthy: once configured, any code path in the job can mint the token. So the job that holds the identity must run only trusted code, on trusted input, behind a gate (Chapter 21A, sections 21A.10 to 21A.13 and 21A.16).

**Common mistakes.** "`id-token: write` grants no write access, so it is harmless at the top." Pinning third-party actions and forgetting reusable workflows. Caching in a release job for speed.

**Expert approach.** Compare a privileged job line by line with workflow 12 and justify every difference. Reference: Chapter 21A, sections 21A.7, 21A.10, 21A.11, 21A.13, 21A.16 and 21A.19.

### Solution 29.4: The GPU box

**Solution.**

<!-- snippet: ex3/x29-audit/04-runners-remote-code -->
```text
$ grep -n -E 'runs-on:|curl|toJSON|secrets: inherit|enable-cache|environment:' x29-*.yml
x29-gpu-eval.yml:20:    runs-on: [self-hosted, gpu]
x29-gpu-eval.yml:27:          CONTEXT: ${{ toJSON(github) }}
x29-gpu-eval.yml:32:          curl -fsSL https://example.com/install-eval-tools.sh | bash
x29-pr-report.yml:25:    runs-on: ubuntu-24.04
x29-release.yml:22:    runs-on: ubuntu-24.04
x29-release.yml:28:          enable-cache: true
x29-release.yml:35:    runs-on: ubuntu-24.04
x29-release.yml:41:          enable-cache: true
x29-release.yml:56:    secrets: inherit
```
<!-- /snippet -->

| # | Weakness | Why it matters | Section |
|---|---|---|---|
| 1 | A persistent self-hosted runner, on `pull_request`, in a public repository | anyone can open a pull request whose code runs on your machine, inside your network, and the machine keeps its state for the next job | 21A.12 |
| 2 | `toJSON(github)` echoed to the log | that context contains `github.token`; redaction of logs is not guaranteed, and a public repository's logs are world-readable | 20B.14, 21A.9 |
| 3 | `curl ... \| bash` | a remote script fetched and executed at run time is the mutable-tag risk with no pin available | 21A.7 |

The checkout also leaves the job token on the runner by default; set `persist-credentials: false`.

A set-up you can defend: pull requests are tested on GitHub-hosted runners without the GPU. The GPU evaluation runs on ephemeral runners, in a runner group that only this repository may use, triggered by `push` to protected branches and by `workflow_dispatch`, never by pull requests from forks. No long-lived cloud credentials are on the machine. Tools are installed from pinned, checksummed sources.

**Reasoning.** The fork model protects your secrets and your repository; it does not protect the runner, and a self-hosted runner is your machine (Chapter 21A, sections 21A.4 and 21A.12; Chapter 20B, section 20B.9).

**Common mistakes.** Relying on the first-time-contributor approval gate: a contributor with one merged typo fix is past it. Believing a private repository removes the risk. Printing whole contexts to debug.

**Expert approach.** For every self-hosted label ask which events can reach it and from which repositories. Print the fields you need, never a whole context. Reference: Chapter 20B, sections 20B.9 and 20B.14; Chapter 21A, sections 21A.4, 21A.7, 21A.9 and 21A.12.

### Solution 29.5: What can this token do?

**Solution.**

1. Job a: read repository contents, nothing else. Job b: write issues, and nothing else; `contents` is `none`, because a job-level block replaces the workflow-level one. Job c: nothing.
2. With `contents: none` the token cannot fetch a private repository. Add `contents: read` to job b's block.
3. It depends on the "Workflow permissions" default of the repository or organization: read and write for all scopes, or read access to `contents` and `packages`. Read-only has been the default for *new* repositories and organizations since 2 February 2023; older ones may still have the permissive setting.
4. A fork pull request gets a read-only token whatever the file says. Job b cannot write issues.
5. None for the push: events triggered by the job token create no new workflow run. The documented exceptions are `workflow_dispatch` and `repository_dispatch`; in the Nx incident a stolen read-write token dispatched the publish workflow.

**Reasoning.** "If you specify the access for any of these permissions, all of those that are not specified are set to `none`" (Chapter 21A, section 21A.3).

**Common mistakes.** Reading a job-level block as an addition to the workflow-level one. Relying on the default. Reaching for `write-all` when a step fails with "Resource not accessible by integration".

**Expert approach.** Declare `permissions` at the top of every workflow, read-only, and add one scope to the one job that needs it. Reference: Chapter 21A, sections 21A.3, 21A.4 and 21A.20.

### Solution 29.6: Who can assume the role?

**Solution.**

| Condition | (i) push to `main` | (ii) push to `feature/x` | (iii) pull request | (iv) tag `v1.2.0` | (v) job with environment `production` |
|---|---|---|---|---|---|
| A, wildcard | yes | yes | yes | yes | yes |
| B, `ref:refs/heads/main` | yes | no | no | no | no: a job that references an environment has the environment form of the subject |
| C, `environment:production` | no | no | no | no | yes |

1. C, and it means something only if the environment has protection rules: a required reviewer, and a deployment branch rule that accepts `main` only.
2. Repositories created after 15 July 2026 use an immutable default subject that includes the owner ID and the repository ID. A policy written in the old, names-only format does not match.
3. Right: the permission only enables fetching the OIDC token and grants no write access to other resources. Wrong: at workflow level every job, and any code in those jobs, can fetch it; what the token then opens is decided by the cloud's trust policy.
4. "OIDC trusted-publisher binding has no per-publish review. Once configured, any code path in the workflow can mint a publish-capable token."

**Reasoning.** The trust policy is where the security lives, and "you must define at least one condition" (Chapter 21A, section 21A.10).

**Common mistakes.** The wildcard form, because the guide shows it. Expecting form B to cover a deployment job that names an environment.

**Expert approach.** Keep trust policies in code next to the workflow, compare the token's `sub` with the policy when the cloud rejects it, and bind to an environment. Reference: Chapter 21A, sections 21A.10, 21A.13 and 21A.20.

### Solution 29.7: Benchmark scores on fork pull requests

**Solution.** One defensible design.

- **Pull request CI** on `pull_request`, with `permissions: contents: read` and no secrets: build, unit tests, and whatever part of the benchmark needs no key.
- **Keyed evaluation** never runs on unreviewed fork code. Either it runs after the merge, on `push` to `main`; or a maintainer starts it on demand, on a branch inside the repository, after reading the diff.
- **If scores must appear on the pull request**, the unprivileged run uploads its results as an artifact, and a `workflow_run` workflow from the default branch posts them, treating the artifact strictly as data (Exercise 29.2). That workflow does not hold the provider key either.
- **The key** is an environment secret behind a required reviewer, dedicated to CI, low-privilege and spend-capped.
- **Given up:** provider-backed scores computed automatically on every outside contribution.

**Rubric** (2 points each, 12 in total): rejects `pull_request_target` for building or testing and says why; no job runs fork code next to the key; a concrete path for showing results that carries data only; least-privilege `permissions` stated per workflow; the key scoped to an environment with a human gate; states what is lost. Deduct for a label such as `safe-to-test` as the only gate: the attacker may push new changes after the label and before the run starts.

**Reasoning.** Under `pull_request` the key is absent for forks; that is the fork model working, not a bug to route around (Chapter 21A, sections 21A.4 and 21A.5). From 2 November 2026 a default rule blocks `pull_request_target` in affected public repositories unless a maintainer allows it.

**Common mistakes.** The privileged trigger "so that CI works for forks". Trusting the first-time-contributor approval. Putting the key in a repository secret that every job can read.

**Expert approach.** Decide which result needs the key, compute it only on trusted code, and move everything else to the unprivileged run. Reference: Chapter 21A, sections 21A.4, 21A.5, 21A.8, 21A.9, 21A.13 and 21A.17.

### Solution 29.8: A workflow nobody wrote

**Solution.**

1. Treat all six repository-level secrets as exposed, and any organization secrets this repository can read. "Any user with write access to your repository has read access to all secrets configured in your repository": they can push a branch with a workflow that uses them, which is what happened. The two environment secrets behind a required reviewer are not exposed unless somebody approved a deployment for that run; check that.
2. Masking redacts known strings in log output. It does nothing about a process that sends a value elsewhere. And the `permissions` blocks in your workflow files are irrelevant: the attacker wrote their own workflow, with their own block, and secrets are not the token in any case.
3. Nothing. The run happened. Deleting the branch removed a name.
4. Revoke the teammate's sessions, tokens and keys, so that the attacker loses the account. Rotate all six secrets, and every other credential that account or those secrets could reach, together and not one by one: in the Trivy case an incomplete, non-atomic rotation after the first incident led to the second. Then search the audit log for what else the account did: other repositories, new workflows, new runners. Preserve the run and its log as evidence. Tell the team.
5. Environment-scoped secrets behind required reviewers, or OIDC, so that a workflow on an arbitrary branch has nothing to read. And a control on who may add workflow files: a push ruleset that restricts the path `.github/workflows/`, where the plan has push rulesets; a code-owner rule on that directory protects the default branch but not a push to a new branch.
6. Two-factor authentication protects the login. A token or an already authenticated session is used without it; the new editor extension is a plausible way to lose one, as in the cases the chapter cites.

**Reasoning.** This is the GhostAction pattern: stolen write access equals secret access. The robust controls are preventing untrusted code from running in privileged jobs and limiting which secrets a job holds (Chapter 21A, sections 21A.9 and 21A.18; Chapter 21B, section 21B.8).

**Common mistakes.** Concluding from a masked log that nothing left the runner. Rotating only the secret that "looks most important". Investigating before containing.

**Expert approach.** Scope by what the compromised identity could reach, not by what the log shows. Contain, rotate atomically, then reconstruct. Reference: Chapter 18, section 18.12; Chapter 21A, sections 21A.9, 21A.13 and 21A.18; Chapter 21B, sections 21B.8 and 21B.22.

---

## Module 30

### Solution 30.1: What could that have run?

**Solution.**

1. Nothing. A clone copies objects and refs; configuration and hooks are not copied, so cloning and reading with `git log` is generally safe.
2. Yes. The archive's `.git` is the author's own: its `config` (aliases, `core.fsmonitor`, pagers, helpers) and its hooks. A prompt that shows the branch runs `git status`, which consults that configuration.
3. Treat it as running the repository's code. The recurring vulnerability class is the recursive clone that tricks Git into writing and running a hook.
4. Nothing. This is the manual's way to get a clean copy of an untrusted directory.
5. Not Git: `pip install -e .` runs the project's code. Cloning was the safe part.
6. Yes, with the default `safe.bareRepository=all`: Git discovers the embedded bare repository and reads its `config`.
7. It runs nothing by itself and switches the ownership check off for every repository on the machine.

For a new laptop: clone, never unpack somebody else's `.git`, and if you must, `git clone --no-local` it first; set `safe.bareRepository=explicit`; clone untrusted repositories without submodules and read `.gitmodules` before deciding. Leave `protocol.file.allow` alone and never set `safe.directory=*`.

**Reasoning.** Two kinds of file under `.git` can make Git execute a program: hooks and configuration. `git clone` creates both fresh from your own installation (Chapter 21B, sections 21B.2 to 21B.4).

**Common mistakes.** "I only changed directory." "Cloning is safe, so `--recurse-submodules` is safe." Silencing the ownership message with `*`.

**Expert approach.** Distinguish what Git runs from what you run. Git protects you from the first, not from `make`, `pip` or a notebook's first cell. Reference: Chapter 21B, sections 21B.2 to 21B.4.

### Solution 30.2: Four questions about one commit

**Solution.**

| Question | Decided by | Read it with | Forgeable by someone with push access? |
|---|---|---|---|
| Who is displayed? | the email in the commit, matched with addresses on accounts | the commit page; `git log --format='%an <%ae> %cn'` | yes |
| Who pushed? | the authenticated credential | the repository's activity view; the audit log | no, though a stolen credential pushes as its owner |
| Who signed? | a signature verified against a key | `git log --format='%G? %GS'`; the badge | only with the private key |
| What is enforced? | a rule that rejects unsigned or unverified commits | the rulesets of the branch | no |

Here nobody signed, nothing is enforced, and the display proves nothing. The investigation is about the account that pushed, not about the colleague. (a) Once she enables vigilant mode, unsigned commits attributed to her are shown as Unverified, this one included. (b) A signed-commits rule rejects such a push in future; it does not change commits already on the branch.

**Reasoning.** Author and committer are two lines of text that the person running Git supplies; the transport authenticates the pusher and does not compare the two (Chapter 21B, sections 21B.5 and 21B.6).

**Common mistakes.** Treating the avatar as evidence. Interrogating the named person. Assuming "no badge" means "checked and fine".

**Expert approach.** Answer the four questions separately and from their own sources. Reference: Chapter 14B, section 14B.18; Chapter 21B, sections 21B.5, 21B.6 and 21B.21.

### Solution 30.3: Blocked or not?

**Solution.**

1. Blocked: user push protection guards your pushes to public repositories.
2. Not blocked. A private repository without Secret Protection has no push-time check at all.
3. Not blocked. Push protection blocks high-confidence provider patterns; generic secrets such as passwords and connection strings are not blocked.
4. Not blocked, according to the supported-pattern data the chapter read: Google API keys are detected and not blocked by push protection. The list changes; re-read it.
5. It goes through. By default anyone with write access can bypass a block by choosing a reason; with repository-level protection the bypass creates an alert, here a closed one, and is written to the audit log.
6. Still blocked. The push would deliver the commit whose snapshot contains the key, whatever a later commit does. The secret has to be removed from the commit that introduced it.

The moment is before the first push. Because nothing has been pushed, replacing the unpushed commits removes the secret completely, and a push-time block exists to keep you at that point.

**Reasoning.** A block is a prompt, not a wall, unless delegated bypass is configured, and coverage differs by provider (Chapter 21B, section 21B.12).

**Common mistakes.** "GitHub blocks secrets", as a general statement. Answering a block with a deletion commit. Choosing "used in tests" to get on with the day.

**Expert approach.** Know your providers' rows in the supported-pattern table, add a scanner in pre-commit and in CI over full history, and treat every bypass as an event somebody reviews. Reference: Chapter 21B, section 21B.12.

### Solution 30.4: The baseline of a public repository

**Solution.** Secret scanning, push protection for the repository, Dependabot alerts and updates, and code scanning are free on public repositories. On private organization repositories secret scanning and repository push protection need GitHub Secret Protection ($19 per active committer per month, as read for the chapter), and code scanning needs GitHub Code Security ($30). Repository-level push protection covers every push to that repository by anyone and leaves an alert on a bypass; the user-level default covers only your own pushes to public repositories. Secret scanning scans the entire history on all branches, plus issues, pull requests, discussions and wikis. For the two Git settings, the chapters recommend `safe.bareRepository=explicit` and `transfer.credentialsInUrl=die`.

**Reasoning.** These layers are independent: each covers something the others do not (Chapter 21B, sections 21B.12 and 21B.13).

**Common mistakes.** Testing push protection with a real-looking key. Assuming the settings carry over when the repository becomes private.

**Expert approach.** Write the baseline as a checklist with a command or a settings page for each item, and re-check it when visibility or plan changes. The `gh repo edit` flags were checked against `--help` of 2.88.1; the commands were not run by the author. Reference: Chapter 16, section 16.7; Chapter 21B, sections 21B.3, 21B.12 and 21B.13.

### Solution 30.5: Six leaked credentials

**Solution.** From widest to narrowest:

| Rank | Credential | Reach | Lifetime | First action |
|---|---|---|---|---|
| 1 | 3, the App's private key | mints installation tokens for every installation of the app | never expires | generate a new key and delete the leaked one in the app's settings |
| 2 | 1, the classic token | every repository and organization its owner can reach, by scope | long-lived | revoke it; GitHub revokes its own tokens found in public repositories, but verify |
| 3 | 6, the SSH key | everything the account can reach over SSH | until deleted (GitHub deletes one unused for a year) | delete it from the account |
| 4 | 5, the fine-grained token | one repository, read | a week | revoke it; same automatic revocation applies |
| 5 | 2, the deploy key | one repository, read-only | no expiry | remove it from the repository |
| 6 | 4, the job token | the workflow's repository, within the job's permissions | the job | none for the token: it expired when the job finished. The finding is that a job printed it |

For the token in 1: compute its SHA-256 and search the audit log for the hash, with the token read from a variable and never typed or pasted. Two limits decide whether that answers the question: a search by token hash returns no Git events (clones, fetches, pushes) in the interface or through the API, so those need an export of Git events data, which the enterprise audit log retains for seven days; and the organization audit log covers 180 days.

**Reasoning.** The type of a credential decides how far a leak reaches and for how long. The App key is the row people forget: short-lived installation tokens are only as safe as the long-lived key that mints them (Chapter 21B, section 21B.8).

**Common mistakes.** Ranking by how "secret" a thing sounds. Assuming automatic revocation happened. Treating the expired job token as an emergency and the App key as routine.

**Expert approach.** Revoke in order of reach, then ask what each one did, from the audit log and the provider's logs. Reference: Chapter 16, sections 16.6 and 16.14; Chapter 21B, section 21B.8.

### Solution 30.6: A baseline for a new ML repository

**Solution.** A model baseline.

| Layer | Control | Does not cover | Cost |
|---|---|---|---|
| Git client | `safe.bareRepository=explicit`; `transfer.credentialsInUrl=die`; clone, never unpack | code you choose to run | none |
| Commit time | a scanner as a pre-commit hook; `.env` ignored from the first commit; staging named files | anyone who skips the hook | seconds per commit |
| Push time | repository push protection (Secret Protection on a private repository); a push ruleset for paths and sizes | generic passwords; providers that are not blocked | a licence per committer |
| History | the same scanner in CI over full history | commits no ref reaches | CI minutes |
| Dependencies | Dependabot alerts, security updates, and version updates for the package manager, Docker and Actions | pinned actions get no alerts, so version updates must move the pins | review time |
| Code | code scanning, including workflow analysis | secrets and dependencies | Code Security on a private repository; minutes |
| Reporting | `SECURITY.md`; private vulnerability reporting where available | | none |
| Automation credentials | job token and OIDC first, App tokens next, no classic tokens | a compromised runner | set-up time |
| Workflows | code-owner review of `.github/` required by a ruleset; actions pinned by commit | a malicious pin chosen on purpose | review time |

**Rubric** (2 points each, 16 in total): client settings; a commit-time check with the admission that it can be skipped; a server-side check; a history scan; all three Dependabot features with the pin trade-off; a reporting path; a credential hierarchy for automation; workflow review. Deduct for presenting any single layer as sufficient, and for features that the plan does not have.

**Reasoning.** Local hooks are advice; a server-side check is enforcement. Each layer has a documented gap (Chapter 21B, sections 21B.12, 21B.13 and 21B.20).

**Common mistakes.** Relying on privacy: internal repositories were about six times more likely than public ones to contain a hardcoded secret in the report the chapter cites. Buying a scanner and skipping rotation practice.

**Expert approach.** Design for the day prevention fails: who is alerted, who revokes, and how you will know what a credential did. Reference: Chapter 21A, section 21A.19; Chapter 21B, sections 21B.8, 21B.9, 21B.12, 21B.13 and 21B.20.

### Solution 30.7: The reproduction package

**Solution.**

1. Her prompt ran `git status` when she entered the directory, and Git read the package's own `.git/config`; a setting there that names a command, such as `core.fsmonitor`, was executed. The two kinds of file are hooks and configuration.
2. Cloning is generally safe, and it is beside the point: she did not clone. She unpacked the author's `.git` directory, which a clone would never have given her.
3. Nothing. Stars can be manufactured, and they say nothing about who sent this archive.
4. Everything that code running as her could read: the SSH key loaded in the agent, the cloud credentials in her home directory, tokens in credential stores and configuration files. All at once, because partial rotation after a compromised runtime is how a second breach happens.
5. `git clone --no-local repro-package clean`, and work in `clean`.
6. `safe.bareRepository=explicit` and the ownership check behind `safe.directory` narrow related ways of running Git inside configuration you did not write. The popular fix that widens it is `safe.directory=*`.

**Reasoning.** Git protects you from Git running something after a clone. An unpacked archive that contains `.git` is the previous owner's own copy (Chapter 21B, sections 21B.2 to 21B.4 and 21B.22).

**Common mistakes.** Believing her statement and looking for another cause. Rotating only the SSH key. Blaming the paper's repository on GitHub, which may be unrelated to the archive.

**Expert approach.** Treat "received as an archive" as a different threat model from "cloned", and write the one-line procedure into the team's onboarding. Reference: Chapter 15, section 15.6; Chapter 21B, sections 21B.2 to 21B.4, 21B.8 and 21B.22.

---

## Module 31

### Solution 31.1: Three things that are not removal

**Solution.**

| Action | What it changes | Where the key still is |
|---|---|---|
| 1 Deletion commit | adds a commit whose tree lacks the file | in every commit from the one that added it up to the deletion, on this branch, on tags and on other branches |
| 2 Amend and force-push | moves a ref to a different commit | in the old commit, which stays in the server's object database; in every clone and fork that fetched it; in cached views |
| 3 Private | who may read through the normal interface | in every clone and fork made while it was public |
| 4 Delete the branch | removes a name | under the pull request's head ref, which is read-only and outlives the branch; in clones |
| 5 `.gitignore` | nothing for a tracked file | everywhere; the file even stays tracked until `git rm --cached` |

The one action: revoke the key at its issuer.

**Reasoning.** A commit is a permanent snapshot. Moving or hiding refs changes who can easily find an old snapshot, not whether it exists (Chapter 21B, section 21B.10; Chapter 17, section 17.2).

**Common mistakes.** Reporting "removed" after any of the five. Counting the exposure from the deletion instead of from the first push.

**Expert approach.** Ask "is it still valid?" before "where is it?". Reference: Chapter 21B, sections 21B.10 and 21B.14.

### Solution 31.2: Fix the order

**Solution.** Rotate first. The stated reason for waiting is backwards: the new key is not in the repository, and the old one works for whoever copied it until it is revoked. The corrected plan:

1. **Contain:** revoke or rotate the key at the provider, now.
2. **Assess:** what the key could reach; the first commit that contains it and when it was pushed; which refs contain it; who could read it; whether it was used, from the provider's logs. This step is missing from the plan.
3. **Eradicate:** remove the key from current code. Decide whether a history rewrite is warranted. For a revoked API key with no sign of use it often is not, and then the team's steps 1 to 4 disappear.
4. **Recover:** update the services that use the key; if history was rewritten, have collaborators re-clone and switch force-push protection back on.
5. **Communicate:** tell collaborators exactly what to do. Missing from the plan.
6. **Prevent**, then the postmortem.

The Support ticket is needed only after a rewrite, and Support assists only where rotation cannot mitigate the risk.

**Reasoning.** The repository is not where the damage happens. It happens at the issuer, and revocation is the only step that works against clones, forks, caches and screenshots alike (Chapter 21B, section 21B.14).

**Common mistakes.** Cleaning first because cleaning feels like action. Rewriting by reflex. Skipping assessment, and so never learning whether the key was used.

**Expert approach.** Contain, assess, eradicate, recover, communicate, prevent, in that order, with the decision about a rewrite recorded with its reason. Reference: Chapter 21B, section 21B.14.

### Solution 31.3: Rewrite or not?

**Solution.**

1. No. The credential is revoked and the logs show no use. Record the decision and stop.
2. Yes. Personal data stays harmful after any rotation, because it cannot be rotated.
3. Yes for your own repository, with clear eyes: proprietary weights cannot be rotated either, and two days in public means copies may exist that no rewrite recalls.
4. Yes, or at least seriously considered: revocation takes weeks, so the data stays harmful in the meantime. Start the rotation now anyway.
5. No. Nothing was leaked. Mark the alert as used in tests, and spell dummies so that they match no pattern.

Four costs: every collaborator's clone must be replaced or carefully rebased; every recorded commit ID becomes stale, including those in experiment records and deployment manifests; signatures are stripped; and existing copies in clones, forks, pull request refs and caches are not recalled.

**Reasoning.** Rewrite when the data stays harmful after rotation or cannot be rotated (Chapter 21B, sections 21B.14, 21B.16 and 21B.22).

**Common mistakes.** Rewriting to feel thorough. Believing a rewrite of a public repository un-publishes anything.

**Expert approach.** Decide from two questions: can it be rotated, and how fast? Then write the decision down. Reference: Chapter 21B, sections 21B.14, 21B.16 and 21B.22.

### Solution 31.4: Review this runbook

**Solution.**

| # | Mistake | Consequence | Correction |
|---|---|---|---|
| 1 | No containment step | the secret works throughout the cleanup | revoke or rotate first |
| 2 | "In my working clone" | the tool prunes reflogs and stashes; stale local refs take part | a fresh clone |
| 3 | Only `main` and `develop` | tags and other branches keep the old commits, and a tag keeps all its ancestors alive | rewrite all refs; push all refs |
| 4 | No freeze | work pushed during the rewrite is discarded or reintroduces old history | announce a freeze before the fresh clone is taken |
| 5 | "Please git pull" | a pull merges old and new history and pushes the secret back as a fast-forward | re-clone; where impossible, `git rebase --onto` with an explicit base |
| 6 | Colleagues run the same filter | identical commands can still produce different commit IDs | never; only the one rewritten history exists |
| 7 | Scan only `main` | a clean tip says nothing about tags, other branches and backup refs | verify across all refs before pushing: both of the manual's checks must print nothing |
| 8 | Rules switched off, never back on | the repository stays open to force pushes | switch them back on as a step of the runbook |
| 9 | Nothing about GitHub's copies | pull request refs, cached views and forks keep the old commits | count affected pull requests; file the Support request with the first changed commits; contact fork owners |
| 10 | The commit map is not kept | old IDs in tickets and experiment records cannot be translated | store `commit-map` with the incident record |

**Reasoning.** A whole-history rewrite replaces the first affected commit and every descendant, and the command is the smallest part of the work (Chapter 21B, sections 21B.16 to 21B.19).

**Common mistakes.** Treating the rewrite as a Git task for one person on one afternoon. Tags: an ordinary fetch does not update them, so clones that pulled keep the old history through an old tag.

**Expert approach.** Write the runbook as an operation: freeze, fresh clone, rewrite all refs, verify, push, re-enable rules, clean every clone, Support, record. Rehearse it on a copy, as Lab 31.1 does. Reference: Chapter 21B, sections 21B.16 to 21B.19 and 21B.22.

### Solution 31.5: How far did it get?

**Solution.** Replayed by `labs/run ex3/x31-exposure`.

<!-- snippet: ex3/x31-exposure/01-tip-is-clean -->
```text
$ git grep -n DUMMY-KEY
[exit status: 1]
$ git log --oneline -3
8eb7fdc Stop tracking the settings file
bf137f4 Reject an overlap that is not smaller than the size
6df9722 Add overlap parameter
```
<!-- /snippet -->

The tip is clean, and that says nothing about history.

<!-- snippet: ex3/x31-exposure/02-entered-and-left -->
```text
$ git fetch -q
$ git log --all -SDUMMY-KEY --format='%h %an %ad %s' --date=iso-strict --name-status
8eb7fdc Ravi Menon 2026-09-07T10:21:00+05:30 Stop tracking the settings file

D	config/settings.env
6df9722 Ravi Menon 2026-09-07T10:11:00+05:30 Add overlap parameter

A	config/settings.env
```
<!-- /snippet -->

The pickaxe over all refs gives the entry and the exit: `config/settings.env` was added in `6df9722` by Ravi at 10:11 on 7 September 2026 and deleted in `8eb7fdc` ten minutes later.

<!-- snippet: ex3/x31-exposure/03-snapshots -->
```text
$ git grep -l DUMMY-KEY $(git rev-list --all) | cut -c1-7,41-
bf137f4:config/settings.env
d4cc30b:config/settings.env
6df9722:config/settings.env
$ git rev-list --all | wc -l
       8
```
<!-- /snippet -->

Three of the eight commits contain the file with the key.

<!-- snippet: ex3/x31-exposure/04-refs -->
```text
$ git branch -a --contains 6df9722
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/debug/storage
  remotes/origin/main
$ git tag --contains 6df9722
v0.5.0
```
<!-- /snippet -->

The first commit is contained in `main`, in `origin/debug/storage` and in the tag `v0.5.0`. A release was cut while the key was in the tree.

<!-- snippet: ex3/x31-exposure/05-not-in-any-file -->
```text
$ git log --all --grep=DUMMY-KEY --format='%h %d %s'
d4cc30b  (origin/debug/storage) Debug storage timeouts
$ git log --all -SDUMMY-KEY --oneline -- config/storage.yaml
```
<!-- /snippet -->

And the key is in the *message* of `d4cc30b` on `debug/storage`. A search of file contents does not see it, and a rewrite that removes the file path would leave it there.

The sheet: the secret is a storage key in `config/settings.env`; first commit `6df9722`; contained in two branches and one tag; three snapshots; also in one commit message. A path-only rewrite would leave the commit message, and would leave the tag pointing at old history unless tags are rewritten too. Git cannot say when the commit was first pushed (the commit date is the committer's claim), who could read it (visibility, forks, collaborators, CI logs: GitHub), or whether the key was used (the provider's logs).

**Reasoning.** `git log -S` answers "where did it enter and leave"; `git grep` over `git rev-list --all` answers "in which snapshots is it present", which is the exposure; `--grep` searches messages, which neither of the others reads (Chapter 21B, sections 21B.11, 21B.14 and 21B.22).

**Common mistakes.** Stopping at a clean `git grep`. Searching only the current branch. Forgetting tags. Forgetting that text can leak in a message, a branch name or a pull request description.

**Expert approach.** Run the three searches over all refs, turn the first commit into scope with `--contains`, and write down which assessment facts are still open and who owns them. Add `--reflog` to the walk when amended or reset commits in a clone matter. Reference: Chapter 21B, sections 21B.11 and 21B.14.

### Solution 31.6: The secret came back

**Solution.**

1. The colleague's clone predated the rewrite and had a local commit. `git pull` fetched the rewritten `main` (a forced update of the remote-tracking branch) and merged it into the local `main`, which still descended from the old history. `git push` then sent a merge commit whose first-parent chain or second parent contains the server's current tip: a fast-forward for the server.
2. For each parent, ask whether the first commit that contained the secret is its ancestor: `git merge-base --is-ancestor <first changed commit> <parent>`; exit status 0 marks the old side. Or search each parent's history: `git log -S<secret> --oneline <parent>`.
3. The push was not a force push. A rule that blocks force pushes asks whether the old tip is an ancestor of the new one, and it was.
4. Server: force-push the clean tip again, which is the merge's parent on the rewritten side, after switching the rule off and with a freeze; then switch it back on. In the colleague's clone, in this order:

```bash
git tag -l | xargs git tag -d                                  # old tags keep old history alive
git fetch --prune --tags
git rebase --onto origin/main <old-upstream-tip> <branch>      # replay only their own commits
git reflog expire --expire=now --all                           # 🔴 drops reflogs and stashes
git gc --prune=now
git cat-file -t <first-changed-commit>                         # must fail
```

   The explicit `--onto` is needed because, after a fetch, a plain `git rebase origin/main` treats every old commit that is missing from the new history as theirs and replays it, the commit that added the secret included. Re-cloning is simpler where possible.
5. A `pre-receive` check on your own server that rejects the first changed commit or the secret pattern. On GitHub the nearest equivalents are push protection, when the secret matches a supported pattern, and a push ruleset that blocks the file path; the chapter found no documented built-in control that bans a specific commit.

**Reasoning.** To Git the two histories are unrelated lines of work that someone chose to merge. GitHub lists "high risk of recontamination" first among the side effects of a rewrite, and the rule is rebase, never merge (Chapter 21B, section 21B.18).

**Common mistakes.** Rewriting again from scratch. Telling the colleague to "just pull again". Forgetting the tags in the stale clone.

**Expert approach.** After a rewrite, treat every existing clone as contaminated until its owner has re-cloned or run the six commands, and watch `main` for merge commits in the first days. Reference: Chapter 21B, sections 21B.18, 21B.21 and 21B.22.

### Solution 31.7: Lead the response

**Solution.**

1. Revoke the key at the provider, by whoever administers the shared account, now. Until then it works for anyone who copied it during three weeks, whatever happens to the repository; every other proposal changes discoverability, not validity.
2. Do not assume it. Partner notification does not guarantee revocation: the chapter's example is a provider key that stayed valid for about two months after the first alert. Check the key's state in the provider's console, and read the provider's usage logs for the three weeks.
3. Coverage is per provider and per pattern, in independent columns, and the secret was in a notebook's output cell, embedded in JSON. Also, user push protection covers only pushes to public repositories by users who have it on. Whichever applies, a missing block proves nothing about the key's status.
4. What the key can reach (the account and its two fine-tuned models: the provider). The first commit that contains it: `git log --all -S<key> --diff-filter=A`, or `-G` with the key's shape. Which snapshots: `git grep -l <pattern> $(git rev-list --all)`. Which refs: `git branch -a --contains` and `git tag --contains`. Who could read it: public, 14 forks. Whether it was used: the provider's logs.
5. Probably no rewrite: once the key is revoked, the old commits are harmless, and a rewrite of a public repository with 14 forks cannot recall anything. Record that decision. Tell the colleague to stop: `filter-branch` is not the recommended tool, a working clone is the wrong place, and nothing should be rewritten before containment and assessment.
6. The forks have their own refs to the old commits and share the object store; the tag keeps the commit and its ancestors reachable in every clone that fetched it. Both are reasons why "removed from `main`" was never containment, and both are irrelevant once the key is dead.
7. Strip notebook outputs with a clean filter backed by a CI check; a scanner in pre-commit and in CI over full history; repository push protection; a CI-only, spend-capped key per use instead of the shared account's key; rotation on a schedule; and an alert route that reaches a team, not one inbox.

**Reasoning.** An LLM key reaches more than a bill: here, fine-tuned models. Notebook outputs leak secrets that the author never typed (Chapter 21B, sections 21B.11, 21B.12, 21B.14 and 21B.15; Chapter 28, section 28.4 for the filter).

**Common mistakes.** Making the repository private first, which costs stars and detaches forks and revokes nothing. Trusting the provider to have acted. Letting a rewrite start because someone is keen.

**Expert approach.** Give one person the incident, run the six steps in order, and write down each decision with its reason, the decision not to rewrite included. Reference: Chapter 15, section 15.5; Chapter 21B, sections 21B.10 to 21B.15 and 21B.19; Chapter 28, sections 28.3, 28.4 and 28.14.
