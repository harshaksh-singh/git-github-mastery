# Answer key, Gate 7: Actions

> **For the examiner.** This file holds the model answers, the marking guidance and the real outputs for [Gate 7](../assessments/gate-7-actions.md). A learner who has failed the gate does not get this file: they get the remediation map in the gate file and variant B. The transcripts are real output of `labs/gates/g7-predict.sh` and `labs/gates/g7-evidence.sh`. Nothing was run on GitHub. Every statement about GitHub Actions is taken from the textbook section named in the reference line, which cites GitHub's documentation.

**Marking, in general.** Mechanism and layer. "The runner is flaky" is never a cause. A correction that hides a symptom earns nothing and, in the cases, loses the item.

---

## Part 1: Concepts

### C1 (5 points)

**Model answer.**

| Event | Commit (`GITHUB_SHA`) | `GITHUB_REF` | Workflow file used |
|---|---|---|---|
| `push` | the tip commit that was pushed | the updated branch or tag | the file in the pushed commit; it runs for any branch, also for workflows not yet on the default branch |
| `pull_request` | the test merge commit | `refs/pull/N/merge` | the file in that merge commit |
| `schedule` | the last commit on the default branch | the default branch | the file on the default branch |
| `workflow_dispatch` | the last commit on the chosen branch or tag | that branch or tag | the file on the chosen ref; the workflow can be triggered only if the file also exists on the default branch |

A runner starts with no repository. `actions/checkout` fetches one commit, without tags, for the ref of the event. For `pull_request` that is `refs/pull/N/merge`: a merge commit that GitHub built from the head of the pull request and the current tip of the base, checked out with a detached `HEAD`; parent 1 is the base, parent 2 the head. It is the right choice because the question a pull request asks is "is the result of merging safe", and only the merged tree answers it. The consequence: the job does not test the commit the author pushed, and it does not run at all while the pull request has a conflict.

**Marking.** 1 point per event row that is right in all three columns (max 3). 1 point: the merge ref, detached, with its two parents. 1 point: why, and the consequence.

**Common wrong answers.** "CI tests my branch." "A scheduled workflow runs the file on my branch." "`GITHUB_SHA` is my last commit" for a pull request.

**Reference.** Chapter 20A, sections 20A.4 and 20A.8.

### C2 (5 points)

**Model answer.** Stage 1, the YAML parser, turns the file into maps, lists and scalars before Actions sees a key. Mistakes of this stage: an unquoted `3.10` is the number 3.1, so a matrix asks for Python 3.1; a tab in indentation is a syntax error; `>` where `|` was meant folds a multi-line script into one line; a pattern that starts with `*` must be quoted. Stage 2, the expression engine, replaces every `${{ ... }}` by its value in the text of the workflow before the step starts. Mistakes of this stage: the result is pasted into the script text, so a value that contains shell syntax becomes code (the injection of Gate 8); a secret that is not set, or is withheld from a fork, is an empty string and not an error; a context that is not available at that place evaluates to empty. Stage 3, the shell: the runner writes the resulting text to a temporary file and runs it with a command template, `bash -e {0}` when no `shell:` is given on Linux and macOS. Mistakes of this stage: no `pipefail`, so a failing command in front of a pipe is not seen; each step is a new process, so variables and the working directory do not carry over.

**Marking.** 1 point per stage described correctly (3). 1 point: `3.10` becomes 3.1. 1 point: substitution happens before the shell starts, with a consequence.

**Common wrong answers.** "`${{ }}` is a shell variable." "YAML keeps 3.10 as written." "The whole workflow is one script."

**Reference.** Chapter 20A, sections 20A.3, 20A.5 and 20A.7.

### C3 (5 points)

**Model answer.** (a) and (b): every `run` step is a new shell process started from the command template. A `cd` and an `export` end with the process. For the directory use `working-directory:` on the step or as a job default; for a variable append `NAME=value` to the file named by `GITHUB_ENV` (later steps of the same job see it), or write a step output to `GITHUB_OUTPUT` and read it as `steps.<id>.outputs.<name>`. (c) Every job starts on a fresh machine. The file exists only on the runner of `build`. Upload it as an artifact in `build` and download it in `deploy`, with `needs: build`; small values travel as job outputs. (d) Without a `shell:` key the template is `bash -e {0}`. `-e` stops at the first failing command but does not look inside a pipeline: the status of a pipeline is that of its last command, `tee`, which succeeds. With `shell: bash` the template is `bash --noprofile --norc -eo pipefail {0}` and the step fails.

**Marking.** 1 point each for (a), (b) and (c) with the supported way. 2 points for (d): the two templates and the pipeline rule.

**Common wrong answers.** "Steps share a shell." "Jobs share a workspace." "`set -e` catches it."

**Reference.** Chapter 20A, sections 20A.7 and 20A.12.

### C4 (5 points)

**Model answer.** By default: one commit (`fetch-depth: 1`), no tags (`fetch-tags: false`), for the ref of the event. Wrong or failing: `git describe` (no tag is reachable: it fails loudly); `git log`, `git shortlog` and anything that counts commits or authors (one commit, exit status 0); `git blame` (every line attributed to the boundary commit, exit status 0); `git merge-base` and "what changed since the base" scripts (no merge base). Only `git describe` fails loudly; the others return plausible wrong answers, which is the greater danger. `git describe --always` falls back to the abbreviated commit ID when no tag is found. The step turns green and the build is named after a commit ID instead of a version: the error is hidden and a wrong version ships. The repair is `fetch-depth: 0` on the checkout step of the job that asks history a question, and to derive the version in one job only.

**Marking.** 1 point: the two defaults. 2 points: three commands with their behavior. 1 point: loud against silent. 1 point: why `--always` is wrong and the real repair.

**Common wrong answers.** "Checkout clones the repository." "Add `git fetch --tags`" alone (the tags arrive, the history between tag and `HEAD` does not).

**Reference.** Chapter 20A, section 20A.8 (root-cause box); Chapter 20B, section 20B.12 (root-cause box).

### C5 (5 points)

**Model answer.** A cache stores a directory under a key so that a later run can skip a download. It is an optimization that may be absent: entries not used for 7 days are evicted, the repository has a size limit, and a job must work without it. An artifact is a set of files uploaded by a job, stored with the run, downloadable by later jobs and by people, kept for a retention period (90 days by default). A job may depend on an artifact of its own run. A cache entry is immutable per key: once `pip-Linux` exists it is restored forever and never rewritten, so a key without a hash of the lock file serves the dependencies of the day it was first saved. A restore key matches by prefix and restores the most recent older entry, which is then extended and saved under the new key: old content travels forward. Use `hashFiles` of the lock file in the key and install strictly from the lock file, so that a stale cache can make the job slower but never different. "Build once": the build job produces the deliverable and uploads it (or pushes an image and outputs its digest); the staging and production jobs deploy exactly that artifact or digest and never build again. It protects against deploying something other than what was tested, because builds are not always reproducible and a tag can be moved.

**Marking.** 1 point: cache. 1 point: artifact. 1 point: immutable per key and the lock-file hash. 1 point: restore keys. 1 point: build once.

**Common wrong answers.** "The cache is updated on every run." "Pass files between jobs with the cache." "Rebuilding from the same commit gives the same image."

**Reference.** Chapter 20A, sections 20A.11 (root-cause box) and 20A.12; Chapter 20B, sections 20B.3 and 20B.4.

### C6 (5 points)

**Model answer.** Environment: its protection rules (required reviewers, wait timer, allowed branches) and its secrets are properties of the environment object on GitHub, not of the YAML. Naming an environment that does not exist creates it, with no rules. Incident: a job that names `production` under a misspelled or new name starts without waiting for anybody. Verify with `gh api repos/OWNER/REPO/environments/<name>`. Concurrency group: a group is a name shared across the repository, not private to a workflow; at most one run executes and one waits, a newer pending run cancels the older pending one, and `cancel-in-progress: true` also cancels the running one. Incident: a deployment cancelled in the middle of a migration, or two workflows that share the name `deploy` blocking each other. Two patterns: for pull request CI, a group per workflow and ref with `cancel-in-progress: true`, because only the newest commit matters; for deployments, a group per environment with `cancel-in-progress: false`, because a running deployment must finish. Self-hosted runner: the machine and everything on it persist between jobs, with whatever network access and credentials that machine has. Incident: a job finds files, caches or credentials of the previous job, or a pull request from a fork runs code on a machine inside the company network. Use ephemeral runners, and do not attach self-hosted runners to public repositories.

**Marking.** 1 point: environment. 1 point: its incident and verification. 1 point: concurrency semantics. 1 point: the two patterns. 1 point: self-hosted persistence with an incident.

**Common wrong answers.** "The reviewers are defined in the workflow." "A concurrency group belongs to one workflow." "A self-hosted runner is like a hosted one, only faster."

**Reference.** Chapter 20B, sections 20B.2, 20B.4 (root-cause box), 20B.5 and 20B.9.

---

## Part 2: Prediction

### P1 (5 points)

<!-- snippet: gates/g7-predict/p1-answer -->
```text
$ git status -sb
## HEAD (no branch)
$ git log -1 --format='%s (parents: %p)' | sed 's/ [0-9a-f]\{7\}/ <id>/g'
Merge feature/streaming into main (parents: <id> <id>)
$ git log -1 --format=%s HEAD^1
Halve the token limit
$ git log -1 --format=%s HEAD^2
Add streaming
$ cat limits.py
MAX_TOKENS = 256
$ git show feature/streaming:limits.py
MAX_TOKENS = 512
$ test "$(git rev-parse HEAD)" = "$(git rev-parse refs/pull/7/head)"
[exit status: 1]
```
<!-- /snippet -->

The runner is on a detached `HEAD` at a merge commit with two parents: the tip of `main` and the head of the pull request. The merged tree has the limit 256 from `main`; the author's branch still has 512. The commit under test is not the commit the author pushed.

**Marking.** 1 point: `## HEAD (no branch)`. 2 points: the merge subject with two parents, "Halve the token limit" as parent 1 and "Add streaming" as parent 2 (1 point if the parents are swapped). 1 point: 256 and 512. 1 point: exit status 1.

**Reference.** Chapter 20A, section 20A.8.

### P2 (5 points)

<!-- snippet: gates/g7-predict/p2-answer -->
```text
$ git diff --name-only main...feature/py-logging
py-service/app.py
$ git diff --name-only main..feature/py-logging
java-service/Build.java
py-service/app.py
$ git diff --quiet main...feature/py-logging -- "java-service/**"
[exit status: 0]
$ git diff --quiet main..feature/py-logging -- "java-service/**"
[exit status: 1]
```
<!-- /snippet -->

Three dots compare the merge base with the head: only what the branch changed. Two dots compare the tips and attribute the change that `main` made to the Java service to the branch. For a `pull_request` event GitHub evaluates path filters on the three-dot diff, so the workflow does not run. (For a `push` it uses two dots between the old and the new tip of the pushed branch.)

**Marking.** 2 points: the two file lists. 1 point: exit statuses 0 and 1. 2 points: three dots, and the workflow does not run.

**Reference.** Chapter 20A, section 20A.4; Chapter 20B, section 20B.13.

### P3 (5 points)

<!-- snippet: gates/g7-predict/p3-answer -->
```text
# A run step without a shell key, on Linux or macOS: bash -e {0}
$ bash -e step.sh
0
report written
[exit status: 0]
# A run step with "shell: bash": bash --noprofile --norc -eo pipefail {0}
$ bash --noprofile --norc -eo pipefail step.sh
0
[exit status: 1]
```
<!-- /snippet -->

`grep -c` prints 0 and exits with status 1 because nothing matched. Under `bash -e {0}` the pipeline's status is that of `tee`, so the script continues and the step is green. Under `bash --noprofile --norc -eo pipefail {0}` the pipeline fails and `-e` stops the script: no "report written", exit status 1. Here the "failure" is a `grep` that found nothing, so the stricter shell makes a correct step red; the same mechanism in the other direction makes failing tests green. The candidate should see both.

**Marking.** 2 points: `0`, `report written`, status 0, with the template. 2 points: `0`, status 1, with the template. 1 point: the remark that `grep -c` exits 1 on zero matches, or the equivalent insight about which command failed.

**Reference.** Chapter 20A, section 20A.7.

### P4 (5 points)

<!-- snippet: gates/g7-predict/p4-answer -->
```text
$ cmp -s key-1.txt key-2.txt && echo "key 2 = key 1" || echo "key 2 differs from key 1"
key 2 = key 1
$ cmp -s key-2.txt key-3.txt && echo "key 3 = key 2" || echo "key 3 differs from key 2"
key 3 differs from key 2
$ cmp -s key-1.txt key-4.txt && echo "key 4 = key 1" || echo "key 4 differs from key 1"
key 4 = key 1
```
<!-- /snippet -->

The key follows the lock file only. Moment 1: miss, saved under key 1. Moment 2 (`pyproject.toml` changed, lock file not): same key, the cache is restored, and the new dependency is not in it. Moment 3 (lock file changed): a new key, a miss, saved. Moment 4 (lock file as at the start): key 1 again, and the entry saved at moment 1 is restored if it has not been evicted.

**Marking.** 1 point per comparison (3). 2 points: the four cache behaviors, of which the restore at moment 2 with stale content is worth 1.

**Reference.** Chapter 20A, section 20A.11.

---

## Part 3: Hands-on diagnosis

### Variant A

#### Case 1 (12 points): 2 points per complaint

| # | Lines | Mechanism | Correction |
|---|---|---|---|
| 1 | `python: [3.10, 3.12]` | YAML types an unquoted `3.10` as the number 3.1 | `python: ["3.10", "3.12"]` |
| 2 | the checkout step, and `git describe --tags` | checkout fetches one commit and no tags | `with: fetch-depth: 0` on that checkout. Not `--always` |
| 3 | `export VERSION` in one step, `$VERSION` in the next | each `run` step is a new shell process | `echo "VERSION=$(git describe --tags)" >> "$GITHUB_ENV"`, or a step output |
| 4 | `python -m unittest discover 2>&1 \| tee test.log`, no `shell:` | `bash -e {0}` has no `pipefail`; the pipeline's status is that of `tee` | `shell: bash` on the step, or as `defaults.run.shell` |
| 5 | `key: pip-${{ runner.os }}` | a cache entry is immutable per key; this key never changes | `key: pip-${{ runner.os }}-${{ hashFiles('**/requirements*.txt') }}` (the project's lock file), and install from the lock file |
| 6a | `if: github.ref == 'refs/heads/main'` on `package`, with `on: pull_request` | on a pull request the ref is `refs/pull/N/merge`, so the condition is always false; a job skipped by its `if` reports success, and the required check is satisfied without having run | decide what the required check is meant to prove. Either run a real packaging step for pull requests, or require an aggregate job that fails unless the needed jobs succeeded |
| 6b | `paths-ignore: ["docs/**"]` | a workflow skipped by a path filter reports nothing; the required check stays pending forever | remove the filter from a workflow whose check is required; skip work inside the job instead |

Complaint 6 earns its 2 points only with both causes. **Parser or runner:** only complaint 1 is visible to a YAML parser (`python3 -c 'import yaml,sys; print(yaml.safe_load(open(sys.argv[1])))' ci.yml` prints 3.1). The other five need knowledge of events, checkout, the shell template and the cache. 1 bonus mention, no points.

**Common wrong answers.** `git describe --tags --always`. `continue-on-error` on the version step. "Clear the cache" for complaint 5 (it returns with the next run under the same key). "`package` is green because it passed."

**Reference.** Chapter 20A, sections 20A.3, 20A.7, 20A.8, 20A.9 and 20A.11; Chapter 20B, section 20B.13.

#### Case 2 (9 points)

- **The two commits (3 points).** The laptop tested the head of the pull request, on a `main` it had not updated. The runner tested `refs/pull/31/merge`: the merge of that head into the current tip of `main`. "The same commit" names the head; the runner never checks the head out.
- **Reproduction (2 points).** `git fetch origin`, then merge the base into a scratch state and run the check, or fetch the merge ref itself (`git fetch origin pull/31/merge` and check out `FETCH_HEAD`):

<!-- snippet: gates/g7-evidence/a2-reproduce -->
```text
$ git fetch origin
$ git log --oneline --graph --all
* 69cd9d0 Lower the batch limit after the latency incident
| * 4687647 Batch 48 requests at a time
|/  
* e950bf8 Add batch limit and its check
# What the runner tested: the result of merging the head into the base.
$ git switch -q --detach origin/main
$ git merge -q --no-ff -m "Merge feature/bigger-batches into main" feature/bigger-batches
$ sh check.sh
check: FAILED (batch 48 exceeds limit 32)
[exit status: 1]
$ git switch -q feature/bigger-batches
```
<!-- /snippet -->

- **Root cause (2 points).** The base branch gained a commit, "Lower the batch limit after the latency incident", that changes behavior the new code relies on: the limit is 32 and the branch batches 48. Neither commit is wrong alone. It is a clean merge that is wrong for humans, found by CI because CI tests the merge.
- **Fix and prevention (2 points).** Update the branch (merge `main` into it or rebase onto it), change the batch size, push. Prevention on the platform: "require branches to be up to date" in the required status checks, or a merge queue. A re-run cannot help: it reuses the original commit and ref, and the result is deterministic.

**Common wrong answers.** "Flaky runner." "Different Python version." "Cache." All of them skip question 2 of the investigation order: which ref and commit did the job check out?

**Reference.** Chapter 20A, section 20A.8 (root-cause box "tests pass locally, fail in CI on the same commit"); Chapter 20B, sections 20B.11 and 20B.12.

#### Case 3 (9 points): 3 points per root cause

1. **The cancelled migration.** `concurrency: group: release` with `cancel-in-progress: true` at workflow level. The second push started a run in the same group, and GitHub cancelled the run in progress, inside the production job. Correction: no cancellation for deployments. Put the group on the deploying jobs, one group per environment, with `cancel-in-progress: false`, so that a second run waits.
2. **No approval.** `environment: prod`. The administrator configured `production`. Naming an environment that does not exist creates it, without rules, so the job started at once. The settings will show three environments: `staging`, `production` (with reviewers, never used) and `prod` (no rules, with deployments). Verification: `gh api repos/OWNER/REPO/environments/prod` and the same for `production`, and compare the protection rules. Correction: `environment: production`; delete `prod`; create environments before the workflows that name them.
3. **Three different images.** Each of the three jobs runs `make image` on its own fresh runner. A tag is a movable name; three builds of one commit are three images unless the build is reproducible. Correction: build once in `build`, push by digest or upload as an artifact, pass the digest as a job output, and let `staging` and `production` deploy that digest and never build.

**Common wrong answers.** "Someone cancelled it." "The reviewers were on holiday." "Use the commit ID as tag, then the images are identical."

**Reference.** Chapter 20B, sections 20B.2 to 20B.5 (root-cause box in 20B.4).

### Variant B

#### Case 1 (12 points): 2 points per complaint

| # | Lines | Mechanism | Correction |
|---|---|---|---|
| 1 | `continue-on-error: true` on "Unit tests" | the step's outcome is failure and its conclusion success; the job is green | remove it. If a later step must run after a failure, give it `if: ${{ !cancelled() }}` and let the job fail |
| 2 | `all-green` with `needs: [lint, test]` and no `if` | a job whose needed job failed is skipped, and a skipped job does not block a required check | see below |
| 3 | `publish-report` reads `report.html` | every job is a new machine; the file is on the runner of `test` | upload the file as an artifact in `test`, download it in `publish-report` |
| 4 | `secrets.REPORT_TOKEN` in a `pull_request` run from a fork | secrets are not passed to runs from forks; the job received an empty string, not an error | do not publish from fork runs: `if: github.event.pull_request.head.repo.full_name == github.repository` on the job, or publish from a run on `main`. Not `pull_request_target` with a checkout of the fork's code: that hands the secret to code the fork controls (Gate 8) |
| 5 | `concurrency: group: pr` | one group for all pull requests; a run for one pull request cancels the run of another | `group: ${{ github.workflow }}-${{ github.ref }}`, keeping `cancel-in-progress: true` |
| 6 | no `timeout-minutes` anywhere | the default for a job is 360 minutes, which is also the limit of a hosted job | `timeout-minutes` on every job |

The corrected aggregate job:

```yaml
  all-green:
    if: ${{ always() }}
    needs: [lint, test]
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - name: Fail unless every needed job succeeded
        env:
          LINT: ${{ needs.lint.result }}
          TEST: ${{ needs.test.result }}
        run: |
          test "$LINT" = "success"
          test "$TEST" = "success"
```

**Common wrong answers.** "Make the secret available to forks." "`if: success()` on `all-green`" (that is the default and the bug). "Retry cancelled runs."

**Reference.** Chapter 20A, sections 20A.9, 20A.12 and 20A.13; Chapter 20B, sections 20B.5, 20B.12 and 20B.13.

#### Case 2 (9 points)

- **Root cause and layer (3 points).** Git tracks the file as `prompts/System.txt`; the code opens `prompts/system.txt`. Git stores names case-sensitively. The default macOS file system ignores case when it looks a name up, so the open succeeds on every laptop; the Linux runner's file system does not, so the file is not found. The fault is in the repository's content (a name in Git that does not match the name in the code); the runner is correct.
- **Repair (2 points).** `git mv prompts/System.txt prompts/system.txt`, commit, push. Git 2.55 performs a rename that changes only case with `git mv`; older instructions go through a temporary name. Renaming in the Finder or with `mv` changes the name on disk and nothing that Git notices, because Git, told by `core.ignoreCase` that the file system ignores case, still sees its tracked name.
- **A check (2 points).** For two names that differ only in case: `git ls-files | tr '[:upper:]' '[:lower:]' | sort | uniq -d`. For this case, a single name in the wrong case, the reliable check is the Linux job itself, kept required; or a test that compares the paths the code opens with `git ls-files` exactly.
- **Investigation order (2 points).** It is found at question 2 or at question 6 at the latest ("were the same files and versions present as locally"), by asking what is in the checkout: `git ls-files`. Questions about permissions, environments, secrets and action versions can be skipped: the job starts, has no secret, and fails in the program. A custom runner image would have changed nothing.

**Reference.** Chapter 20B, sections 20B.11 and 20B.12; Chapter 4, section 4.12.

#### Case 3 (9 points): 3 points per report

1. **The schedule ignores the branch.** `schedule` runs the workflow file of the default branch, on the last commit of the default branch. The edit on `feature/eval-v8` has no effect until it is merged. Copies used: `schedule`, the default branch; `workflow_dispatch`, the file on the ref chosen when starting it (and only startable if the file exists on the default branch); `push`, the pushed commit; `pull_request`, the merge commit.
2. **The empty dataset name.** `DATASET=golden-v7` is a shell variable of one step in the job `prepare`. `evaluate` is another job on another machine. Correction: a step output written to `GITHUB_OUTPUT`, exposed as a job output of `prepare`, read in `evaluate` as `needs.prepare.outputs.dataset`.
3. **The missing file.** `scores.json` is written on the runner of `evaluate`; `compare` starts on a new machine. Correction: upload it as an artifact in `evaluate` and download it in `compare`.

The three ways: within a job, `GITHUB_ENV` (variables for later steps) and `GITHUB_OUTPUT` (step outputs); between jobs, job outputs for small values; between jobs, artifacts for files. Report 2 needs a job output, report 3 an artifact.

**Common wrong answers.** "Cron is delayed." "Use the cache to pass `scores.json`." "Put the three jobs' steps under `env:` at workflow level with `DATASET: $DATASET`."

**Reference.** Chapter 20A, sections 20A.4, 20A.7 and 20A.12.

---

## Part 4: Oral interview

O1 to O4: 3 points for a complete answer with the follow-up, 2 for a correct answer with a weak follow-up, 1 for a definition without mechanism. O5 and O6: 4, 3, 2 or 1 on the same scale, the fourth point for the production consequence.

### O1 (3 points)

**Model answer.** From "did the right thing start at all" to "what did it say": an answer early in the order makes everything after it irrelevant, and a log read without knowing which file, event and commit produced it is read with the wrong assumptions. *Follow-up:* (1) Workflow: which workflow file, from which commit, defined this run; scheduled and some other events use the file on the default branch. (2) Event: what triggered it and which ref and commit the job checked out; a pull request builds the merge ref, a re-run reuses the original commit. (3) Permissions: what the token could do; fork and Dependabot runs get a read-only token. Then runner, environment, dependencies, secrets, action versions, and only then the log, artifacts, cache and concurrency.

**Weak answer.** "Read the error and search for it." **Reference.** Chapter 20B, section 20B.11.

### O2 (3 points)

**Model answer.** Git state (a shallow, tagless clone; the merge ref instead of my commit; names that differ in case; line endings), missing secrets on fork runs, the shell template without `pipefail`, moving images and tool versions, a stale or missing cache, less memory, and an environment in which steps share no state and every job is a new machine. *Follow-up:* the first group. I make the laptop show the runner's state with Git: `git fetch origin && git merge origin/main` on a scratch branch, or fetch `pull/N/merge`; `git clone --depth 1` into a temporary directory to see what a shallow checkout answers; `git ls-files` to see the names Linux will see.

**Weak answer.** "The runner has a different OS." **Reference.** Chapter 20B, section 20B.12.

### O3 (3 points)

**Model answer.** A workflow that never started (path filter, branch filter, `[skip ci]`) reports nothing: the required check stays pending and the merge is blocked forever. A job skipped by its `if` inside a workflow that ran reports success: the check is satisfied without having run. A job skipped because a needed job failed is skipped too and may not block. *Follow-up:* require one aggregate job per workflow that always runs (`if: ${{ always() }}`), needs the real jobs and fails unless each result is `success`; put no path filter on that workflow; pin the required check to the GitHub App that is expected to report it.

**Weak answer.** "Skipped means failed." **Reference.** Chapter 20B, section 20B.13; Chapter 20A, section 20A.13.

### O4 (3 points)

**Model answer.** When the same job must run for several combinations: language versions, operating systems, shards. Each combination is its own job on its own runner with its own `matrix` context. `fail-fast`, true by default, cancels the in-progress and queued combinations when one fails; turn it off when you need the full picture. *Follow-up:* mark the entry in the matrix (an `experimental` value added with `include`) and set `continue-on-error: ${{ matrix.experimental }}` on the job, so only that combination may fail, and let an aggregate job judge the rest. Not a blanket `continue-on-error: true`.

**Weak answer.** "To run jobs in parallel." **Reference.** Chapter 20A, sections 20A.9 and 20A.10.

### O5 (4 points)

**Model answer.** Build once: one job builds, tests and publishes the deliverable and outputs its identity, a digest. Staging: a job with `environment: staging` that deploys that digest and runs a smoke test. Production: a job with `environment: production`, which carries required reviewers and a branch restriction on GitHub, and deploys the same digest. The gates are the environment's rules, verified on the platform and not assumed from the YAML; the secrets of each environment are readable only after its rules passed. Between jobs travel a digest as a job output and artifacts, never a rebuild. *Follow-up:* each deploying job is in a concurrency group named after its environment with `cancel-in-progress: false`: the second run waits for the first, nothing is cancelled half-way, and a third arrival replaces the waiting one, which is acceptable because the newest is a superset on `main`. If hotfixes must not wait behind a queue, that is a decision about the group, made before the incident.

**Weak answer.** "A deploy job after the tests, with a manual approval step." **Reference.** Chapter 20B, sections 20B.2 to 20B.5.

### O6 (4 points)

**Model answer.** Start with GitHub-hosted runners: a fresh virtual machine per job from a published image, nothing to operate, nothing left behind. Move a job to a self-hosted runner only for a reason hosted runners cannot meet: a GPU or large memory, data that may not leave the network, a long evaluation beyond the six-hour limit. Then the cost is operations and security: the machine is yours, with its network access and credentials. For model work that usually means unit tests and linting on hosted runners, and evaluation on ephemeral self-hosted runners, never on a public repository. *Follow-up:* everything: the checkout, caches, built artifacts, files written outside the workspace, credentials a job logged in with, running processes. The next job, possibly from another branch or person, starts in that state: results stop being reproducible, and a malicious job can leave something for the next one. Ephemeral runners that take one job and are removed close that gap.

**Weak answer.** "Self-hosted is cheaper." **Reference.** Chapter 20B, sections 20B.8 to 20B.10.
