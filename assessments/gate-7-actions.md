# Gate 7: Actions

> **Baseline.** Git 2.55.0 on macOS; GitHub Actions facts as of 1 October 2026, as the textbook cites them. Nothing in this gate was run on GitHub, and no GitHub output is shown. The transcripts in part 2 are real output of `labs/gates/g7-predict.sh`: Git and a shell doing locally what a runner does. This file contains no answers. The answer key is for the examiner; do not open it before the gate is scored, and not at all if you failed and will take variant B.

**Taken after** Module 28. **Covers** the workflow model, the first eleven workflows of the course (`workflows/01-tests.yml` to `workflows/11-caller.yml`), runners and CI debugging: Chapters [20A](../textbook/ch20a-actions-fundamentals.md) and [20B](../textbook/ch20b-actions-delivery-debugging.md). The security of workflows is Gate 8.

**Pass rule.** 85 points or more out of 100, and at least 70% in every part. How a gate is taken, timed and scored is in the [README](README.md).

| Part | Points | Minimum to pass the part | Time |
|---|---|---|---|
| 1 Concepts | 30 | 21 | 45 minutes, closed book |
| 2 Prediction | 20 | 14 | 25 minutes, no terminal |
| 3 Hands-on diagnosis | 30 | 21 | 60 minutes, on paper |
| 4 Oral interview | 20 | 14 | 20 minutes, spoken, no terminal |

**Label the layer.** Say for each statement whether it is about Git, about GitHub, or about GitHub Actions.

---

## Part 1: Concepts (30 points)

Six questions, 5 points each. Answer in writing, in five to ten sentences.

### C1 (5 points)

For each of the events `push`, `pull_request`, `schedule` and `workflow_dispatch`, state which commit the run is about, what `GITHUB_REF` is, and which copy of the workflow file defines the run. Then explain what `actions/checkout` puts on the runner for a `pull_request` event, in Git terms, and why that choice is the right one for the question a pull request asks.

### C2 (5 points)

"A workflow file is data, not a script." Explain the three stages a `run:` line passes through before a shell executes it: the YAML parser, the expression engine, the shell. Give one mistake that belongs to each stage, with its symptom. Include what `python-version: 3.10` becomes, and when `${{ ... }}` is replaced.

### C3 (5 points)

Explain why each of these does not work, and give the supported way: (a) a step runs `cd service` and the next step expects to be in `service/`; (b) a step runs `export BUILD_ID=...` and the next step reads `$BUILD_ID`; (c) job `build` writes `dist/app.tar.gz` and job `deploy` tries to read the file; (d) a step runs `tests | tee log.txt` without a `shell:` key and stays green when the tests fail.

### C4 (5 points)

Describe what `actions/checkout` fetches by default and name three commands whose results are wrong or failing because of it. Which of them fails loudly and which fail silently? A colleague proposes `git describe --always` to "fix" the version step of a release build. Explain what that does and why it is the wrong repair.

### C5 (5 points)

Distinguish a cache from an artifact: what each is for, how each is addressed, how long it lives, and whether a job may depend on it being present. Explain why a cache key without a hash of the lock file serves old dependencies for weeks, and what a restore key adds to the problem. Then state the "build once" rule for a pipeline with staging and production, and what it protects against.

### C6 (5 points)

An environment named in a workflow, a concurrency group, and a self-hosted runner each carry a property that the YAML file does not show. For each of the three, say what that property is, where it lives, and one incident it causes when it is assumed and not verified. For concurrency, give the two patterns that want opposite settings.

---

## Part 2: Prediction (20 points)

Four items, 5 points each. No terminal. Write the output you expect and one sentence of mechanism for each prediction. Where a commit ID would appear, write `<id>`.

### P1 (5 points)

<!-- snippet: gates/g7-predict/p1-setup -->
```text
# The last block imitates GitHub: it records the head of pull request 7 and builds the test merge.
$ git init -q gateway
$ cd gateway
$ printf 'MAX_TOKENS = 512\n' > limits.py && git add . && git commit -q -m 'Add limits'
$ git switch -q -c feature/streaming
$ printf 'def stream(chunks):\n    yield from chunks\n' > stream.py && git add . && git commit -q -m 'Add streaming'
$ git switch -q main
$ printf 'MAX_TOKENS = 256\n' > limits.py && git commit -q -am 'Halve the token limit'
$ git update-ref refs/pull/7/head feature/streaming
$ git switch -q --detach main
$ git merge -q --no-ff -m "Merge feature/streaming into main" feature/streaming
$ git update-ref refs/pull/7/merge HEAD
$ git switch -q feature/streaming
# The runner, on a pull_request event:
$ git switch -q --detach refs/pull/7/merge
```
<!-- /snippet -->

Predict, in the state of the "runner":

1. The first line of `git status -sb`.
2. The subject of `HEAD` and the number of its parents; the subject of `HEAD^1` and of `HEAD^2`.
3. The output of `cat limits.py`, and of `git show feature/streaming:limits.py`.
4. The exit status of `test "$(git rev-parse HEAD)" = "$(git rev-parse refs/pull/7/head)"`.

### P2 (5 points)

<!-- snippet: gates/g7-predict/p2-setup -->
```text
$ git init -q mono
$ cd mono
$ mkdir py-service java-service
$ printf 'print(1)\n' > py-service/app.py && printf 'class Build {}\n' > java-service/Build.java
$ git add . && git commit -q -m "Add two services"
$ git switch -q -c feature/py-logging
$ printf 'print(2)\n' > py-service/app.py && git commit -q -am 'Log the request id'
$ git switch -q main
$ printf 'class Build { int v = 2; }\n' > java-service/Build.java && git commit -q -am 'Bump the Java build'
```
<!-- /snippet -->

A pull request from `feature/py-logging` into `main` exists. A workflow has `on: pull_request: paths: ["java-service/**"]`.

1. Predict the output of `git diff --name-only main...feature/py-logging` and of `git diff --name-only main..feature/py-logging`.
2. Predict the exit status of `git diff --quiet <range> -- "java-service/**"` for each of the two ranges.
3. From the textbook: which of the two comparisons does GitHub use for the path filter of a `pull_request` event, and does the workflow run?

### P3 (5 points)

<!-- snippet: gates/g7-predict/p3-setup -->
```text
$ printf 'test_load PASSED\ntest_save PASSED\n' > results.txt
$ printf 'grep -c FAILED results.txt | tee failed-count.txt\necho "report written"\n' > step.sh
$ cat step.sh
grep -c FAILED results.txt | tee failed-count.txt
echo "report written"
```
<!-- /snippet -->

The script is the text of a `run:` step. Predict the complete output and the exit status:

1. when the step has no `shell:` key, on a Linux runner;
2. when the step has `shell: bash`.

For each, give the command template the runner uses.

### P4 (5 points)

<!-- snippet: gates/g7-predict/p4-setup -->
```text
# key prints what  deps-${{ hashFiles(...) }}  would be if only uv.lock were hashed (shortened).
$ printf 'requests==2.32.0\n' > uv.lock
$ printf '[project]\ndependencies = ["requests"]\n' > pyproject.toml
$ key > key-1.txt
$ printf '[project]\ndependencies = ["requests", "httpx"]\n' > pyproject.toml
$ key > key-2.txt
$ printf 'requests==2.32.0\nhttpx==0.28.0\n' > uv.lock
$ key > key-3.txt
$ printf 'requests==2.32.0\n' > uv.lock
$ key > key-4.txt
```
<!-- /snippet -->

Predict, for the keys 2, 3 and 4, whether each equals an earlier key, and say for each of the four moments what a cache step with `key: <that key>` and no restore keys would do: restore, or miss and save at the end of the job.

---

## Part 3: Hands-on diagnosis (30 points)

On paper: three cases built from workflow files and described runs. Variant A is the first attempt; variant B is for a retake and is not to be opened before.

| | Variant A | Variant B (retake) |
|---|---|---|
| The cases | [`variant-a/CASES.md`](gen/gate-7-actions/variant-a/CASES.md) | [`variant-b/CASES.md`](gen/gate-7-actions/variant-b/CASES.md) |
| The files | `assessments/gen/gate-7-actions/variant-a/` | `assessments/gen/gate-7-actions/variant-b/` |

| Case | Points | Graded on |
|---|---|---|
| 1 A workflow and its complaints | 12 | 2 points per complaint: the causing lines, the mechanism, the corrected lines |
| 2 Passes locally, fails in CI | 9 | the two states that were compared without knowing it; the reproduction; root cause, fix and prevention |
| 3 A pipeline incident | 9 | 3 points per root cause: lines, mechanism, correction |

A diagnosis that says "flaky", "retry" or "runner problem" without evidence earns nothing for that item. A correction that silences the symptom (`|| true`, `continue-on-error`, `--always`) loses the points of the item.

---

## Part 4: Oral interview (20 points)

Six questions, asked one at a time by the examiner, who then asks the follow-up. Answer aloud in one to two minutes each. O1 to O4 are worth 3 points each, O5 and O6 are worth 4 points each.

### O1 (3 points)

A workflow run is red. In which order do you investigate, and why do you not start with the log of the red step? *Follow-up:* give me the first three questions of your order and what answers each of them.

### O2 (3 points)

"It passes locally and fails on GitHub Actions." Name the classes of difference between a laptop and a runner. *Follow-up:* which of them are differences in Git state, and how do you make the laptop show the runner's state?

### O3 (3 points)

What is the difference between a job that was skipped and a workflow that did not start, for a required status check? *Follow-up:* how do you design a required check that cannot be satisfied by accident?

### O4 (3 points)

When do you use a matrix, and what does `fail-fast` decide? *Follow-up:* one matrix entry is experimental and allowed to fail. How do you express that without hiding real failures?

### O5 (4 points)

Design the deployment part of a pipeline for a service with staging and production. What are the jobs, what passes between them, and where are the gates? *Follow-up:* a hotfix run and a regular run start within a minute of each other. What happens with your design?

### O6 (4 points)

GitHub-hosted or self-hosted runners: how do you decide for a team that trains and evaluates models? *Follow-up:* what stays on a self-hosted runner after a job, and why does that matter for the next job?

---

## Score sheet

| Item | Max | Score | | Item | Max | Score |
|---|---|---|---|---|---|---|
| C1 | 5 | | | P1 | 5 | |
| C2 | 5 | | | P2 | 5 | |
| C3 | 5 | | | P3 | 5 | |
| C4 | 5 | | | P4 | 5 | |
| C5 | 5 | | | **Prediction** | **20** | |
| C6 | 5 | | | H case 1 | 12 | |
| **Concepts** | **30** | | | H case 2 | 9 | |
| O1 to O4 | 12 | | | H case 3 | 9 | |
| O5, O6 | 8 | | | **Hands-on** | **30** | |
| **Oral** | **20** | | | **Total** | **100** | |

Pass: total 85 or more, Concepts 21 or more, Prediction 14 or more, Hands-on 21 or more, Oral 14 or more.

## Remediation map

After scoring, restudy the sections of every item on which you lost more than a third of the points, redo the labs of that module, and take the gate again with variant B of the hands-on part.

| Item | Restudy | Lab module |
|---|---|---|
| C1 | Chapter 20A, sections 20A.4 and 20A.8 | 26 |
| C2 | Chapter 20A, sections 20A.3, 20A.5 and 20A.7 | 26 |
| C3 | Chapter 20A, sections 20A.7 and 20A.12 | 26 |
| C4 | Chapter 20A, section 20A.8; Chapter 20B, section 20B.12 | 26, 28 |
| C5 | Chapter 20A, sections 20A.11 and 20A.12; Chapter 20B, sections 20B.3 and 20B.4 | 26, 27 |
| C6 | Chapter 20B, sections 20B.2, 20B.4, 20B.5 and 20B.9 | 27, 28 |
| P1 | Chapter 20A, section 20A.8 | 28 |
| P2 | Chapter 20A, section 20A.4; Chapter 20B, section 20B.13 | 26 |
| P3 | Chapter 20A, section 20A.7 | 26 |
| P4 | Chapter 20A, section 20A.11 | 26 |
| Case 1 | Chapter 20A, sections 20A.3, 20A.7 to 20A.9 and 20A.11; Chapter 20B, section 20B.13 | 26, 28 |
| Case 2 | Chapter 20A, section 20A.8; Chapter 20B, sections 20B.11 and 20B.12 | 28 |
| Case 3 | Chapter 20B, sections 20B.2 to 20B.5 (variant A); Chapter 20A, sections 20A.4, 20A.7 and 20A.12 (variant B) | 27 |
| O1 | Chapter 20B, section 20B.11 | 28 |
| O2 | Chapter 20B, section 20B.12 | 28 |
| O3 | Chapter 20B, section 20B.13; Chapter 20A, section 20A.13 | 28 |
| O4 | Chapter 20A, sections 20A.9 and 20A.10 | 26 |
| O5 | Chapter 20B, sections 20B.2 to 20B.5 | 27 |
| O6 | Chapter 20B, sections 20B.8 to 20B.10 | 28 |
