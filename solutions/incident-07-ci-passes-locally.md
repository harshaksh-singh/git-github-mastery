# Incident 7: CI passes locally and fails on GitHub Actions — solution

> Read this only after your own attempt at [`incidents/07-ci-passes-locally`](../incidents/07-ci-passes-locally/SYMPTOMS.md). GitHub Actions cannot be run from this course. The run report in `incidents/07-ci-passes-locally/evidence/` is constructed for the exercise. The transcripts below are real output from `labs/incidents/solve-07-ci-passes-locally.sh` and show the part that plain Git can reproduce. Layers: the first cause is a default of the `actions/checkout` action (GitHub Actions); the second is a file-name case mismatch (Git and the filesystem).

## 1. Symptoms

The step "Compute version" fails on the runner with exit code 128 and the message `fatal: No names found, cannot describe anything.` The same script prints a version on a laptop. Re-runs fail the same way. `main` has been red since the step was added. The reporter suspects a flaky runner and asks for an administrator to merge anyway.

## 2. Evidence, in the fixed investigation order

The order is that of [Chapter 20B: Delivery, Runners, Cost and Debugging](../textbook/ch20b-actions-delivery-debugging.md), section 20B.11. Most questions are answered by the workflow file and the run report without touching a log.

| # | Question | Answer from the evidence | Verdict |
|---|---|---|---|
| 1 | Workflow | `ci.yml`; triggered by `pull_request`, so the file version is the one in the pull request's merge commit | Not the cause |
| 2 | Event | `pull_request`: the job checks out the merge ref, not the head branch. The same job fails on `push` to `main` | Rules out "it is the pull request" |
| 3 | Permissions | `contents: read`; the failing step needs no API call | Not the cause |
| 4 | Runner | `ubuntu-24.04`, a fixed label; no image change in the window | Not the first cause; relevant to the second |
| 5 | Environment | None referenced | Not applicable |
| 6 | Dependencies | The step runs only `git` | Not the cause |
| 7 | Secrets | None used | Not applicable |
| 8 | Action versions | Both actions pinned by commit SHA; nothing moved | Not the cause |
| 9 | Logs | One line, and it is a Git message | **Points at the repository the runner had** |
| 10 | Artifacts | None | Not applicable |
| 11 | Cache | None | Not applicable |
| 12 | Concurrency | No group; no cancellation | Not applicable |

Two observations already exclude "flaky": the failure is deterministic across re-runs, and it started with a commit, not at a point in time.

## 3. Hypotheses

| # | Hypothesis | Test | Result |
|---|---|---|---|
| 1 | Runner outage or flakiness | Does a re-run differ? Did it start without a change? | No and no |
| 2 | The tag is missing on the server | `git ls-remote --tags origin` | The tag is there |
| 3 | The runner's clone lacks the tag | What `actions/checkout` fetches by default | Confirmed below |
| 4 | The pull request's merge ref hides the tag | The job also fails on `push` | Excluded |

## 4. Diagnostic commands

Locally the script works, three commits after the tag:

<!-- snippet: incidents/solve-07-ci-passes-locally/01-local -->
```text
$ cd you
$ git log --oneline --decorate -5
367b8fb (HEAD -> main, origin/main) Move the template path into a constant
261eb76 Stamp reports with the version from git describe
5a1005a Add CI workflow
e18efbb (tag: v1.4.0) Add README
ef03c89 Add report renderer
$ cat scripts/version.sh
#!/usr/bin/env bash
# Prints the version of this checkout, derived from the newest release tag.
set -e
git describe --tags --match "v*"
$ bash scripts/version.sh
v1.4.0-3-g367b8fb
[exit status: 0]
```
<!-- /snippet -->

The checkout step has no `with:` block, and the version step arrived in `261eb76`:

<!-- snippet: incidents/solve-07-ci-passes-locally/02-workflow -->
```text
$ grep -n -A1 'actions/checkout' .github/workflows/ci.yml
18:      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
19-
$ git log --oneline -- scripts/version.sh .github/workflows/ci.yml
261eb76 Stamp reports with the version from git describe
5a1005a Add CI workflow
```
<!-- /snippet -->

By default `actions/checkout` fetches a single commit and no tags: `fetch-depth` defaults to 1 and `fetch-tags` to `false` ([checkout README, v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md)). Git can make the same clone:

<!-- snippet: incidents/solve-07-ci-passes-locally/03-runner-clone -->
```text
# What the checkout step does by default, reproduced with Git: depth 1 and no tags.
$ git clone --quiet --depth 1 --no-tags "file://$PWD/../server.git" ../runner-checkout
$ cd ../runner-checkout
$ git rev-parse --is-shallow-repository
true
$ git rev-list --count HEAD
1
$ git tag --list
$ bash scripts/version.sh
fatal: No names found, cannot describe anything.
[exit status: 128]
```
<!-- /snippet -->

One commit, no tags, and the message from the run report with exit status 128. The runner was never flaky; it was given a repository in which the question "what is the nearest tag" has no answer.

## 5. Root cause

```text
Observed behavior : "git describe" fails on the runner with "No names found" and works on every laptop
Git state         : the runner's clone is shallow (one commit) and has no tags; a laptop clone has all history and all tags
Mechanism         : git describe walks back from HEAD to the nearest tag; with one commit and no tag refs there is nothing to find
Root cause        : the workflow added a step that needs history and tags, without changing the checkout step that provides neither
Why it does this  : actions/checkout defaults to depth 1 and no tags, because most jobs need only the files (speed)
Correct fix       : "fetch-depth: 0" on the checkout step
Prevention        : treat the checkout as part of a tool's inputs; make the version script fail with a message that names the cause
```

The remedy, shown with Git: fetching all history and the tags makes the same script succeed in the same clone.

<!-- snippet: incidents/solve-07-ci-passes-locally/04-remedy-proof -->
```text
# What "fetch-depth: 0" changes: all history and the tags.
$ git fetch --quiet --unshallow --tags
$ git rev-list --count HEAD
5
$ git tag --list
v1.4.0
$ bash scripts/version.sh
v1.4.0-3-g367b8fb
[exit status: 0]
```
<!-- /snippet -->

## 6. The second failure behind the first

The job has never reached "Run tests" since the version step was added, so a later defect in the tests would be invisible. Check before promising a green run.

<!-- snippet: incidents/solve-07-ci-passes-locally/05-second-failure -->
```text
$ cd ../you
# Would the tests pass on Linux once the version step is fixed? Names as Git stores them:
$ git ls-files templates
templates/summary.md.tmpl
$ grep -n 'tmpl' reports/render.py
4:TEMPLATE = os.path.join(HERE, "templates", "Summary.md.tmpl")
$ git log --oneline -S'Summary.md.tmpl' -- reports/render.py
367b8fb Move the template path into a constant
```
<!-- /snippet -->

Git tracks `templates/summary.md.tmpl`. The code opens `templates/Summary.md.tmpl` since `367b8fb`. On the default macOS filesystem, which ignores case when it looks up a name, the file opens. On a Linux runner, where names are case-sensitive, it does not exist. This is a Git-level mechanism documented under `core.ignoreCase` ([git-config](https://git-scm.com/docs/git-config#Documentation/git-config.txt-coreignoreCase)).

> **Unverified.** The Phase 0 report could not confirm from official GitHub Actions documentation that hosted runners' filesystems are case-sensitive. The statement here rests on the Git documentation and on the default behavior of Linux filesystems.

`git ls-files` is the instrument: it prints names exactly as the index stores them, independent of what the local filesystem tolerates.

## 7. Recovery

<!-- snippet: incidents/solve-07-ci-passes-locally/06-fix -->
```text
$ git switch -c fix/ci-checkout
Switched to a new branch 'fix/ci-checkout'
# (edit .github/workflows/ci.yml: add "with: fetch-depth: 0" to the checkout step)
# (edit reports/render.py: spell the template name as it is tracked)
$ git diff
diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
index 683eadc..2df54cb 100644
--- a/.github/workflows/ci.yml
+++ b/.github/workflows/ci.yml
@@ -16,6 +16,8 @@ jobs:
     runs-on: ubuntu-24.04
     steps:
       - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
+        with:
+          fetch-depth: 0
 
       - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
         with:
diff --git a/reports/render.py b/reports/render.py
index 23a58f3..dca0003 100644
--- a/reports/render.py
+++ b/reports/render.py
@@ -1,7 +1,7 @@
 import os
 
 HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
-TEMPLATE = os.path.join(HERE, "templates", "Summary.md.tmpl")
+TEMPLATE = os.path.join(HERE, "templates", "summary.md.tmpl")
 
 def render(title, accuracy):
     with open(TEMPLATE) as f:
```
<!-- /snippet -->

<!-- snippet: incidents/solve-07-ci-passes-locally/07-publish -->
```text
$ git commit -a -m 'Fetch full history and tags in CI; fix template name case'
[fix/ci-checkout 194406a] Fetch full history and tags in CI; fix template name case
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git push -u origin fix/ci-checkout
To ../server.git
 * [new branch]      fix/ci-checkout -> fix/ci-checkout
branch 'fix/ci-checkout' set up to track 'origin/fix/ci-checkout'.
$ cd ..
$ incidents/07-ci-passes-locally/check.sh
Checking incident 07-ci-passes-locally
  ok    the server has the branch fix/ci-checkout
  ok    the branch is based on main
  ok    the checkout step fetches the full history and the tags (fetch-depth: 0)
  ok    actions/checkout is still pinned to a full commit SHA
  ok    the workflow still declares permissions
  ok    reports/render.py opens templates/summary.md.tmpl, which is tracked with exactly that spelling
  ok    the release tag v1.4.0 is still on the server
PASS: the recovery of incident 07-ci-passes-locally is complete.
[exit status: 0]
```
<!-- /snippet -->

The code is changed to match the tracked name, which avoids a case-only rename on a case-insensitive filesystem. `fetch-depth: 0` fetches all history for all branches and tags, per the README. On a large repository that costs time; `fetch-tags: true` with a sufficient depth is the documented alternative.

## 8. Verification

The check script confirms the files on `fix/ci-checkout`. The real verification is the run of the workflow on the pull request for that branch, which you can observe only on GitHub:

```bash
gh run list --workflow ci.yml --branch fix/ci-checkout
gh run view <run-id> --log-failed
```

Until that run is green, the honest status is "cause found and fixed in the files; not yet confirmed by a run".

## 9. The request to "merge it anyway"

No. A required check that is red on `main` is not noise to be bypassed; bypassing it once teaches the team that red is negotiable, and here the red check was hiding a second real defect. The docstring pull request waits until `fix/ci-checkout` is merged and then needs its branch updated.

## 10. Prevention, communication, postmortem

**Prevention.** A workflow change that adds a tool is reviewed together with what the tool reads: history, tags, submodules, LFS files. A red default branch is an incident on the day it turns red, not a week later. A lint step can compare `git ls-files` with itself in lower case to catch names that differ only by case.

**To the team:** "CI was not flaky. The version step needs tags and history, and the checkout step fetches one commit without tags by default. Fix is on `fix/ci-checkout` (`fetch-depth: 0`). The same branch fixes a template name whose case differs between the code and the repository; it worked only on macOS. After the merge, update your open pull requests."

**To the CTO:** "`main` was red for five days and nobody owned it. No release was blocked yet. The cause was a workflow change, not the platform. We now treat a red default branch as an incident."

**Postmortem.** Severity medium: every pull request was unverifiable for five days, and one real defect was masked. What made sense at the time: "passes on my machine" is true, and a hosted runner is a plausible suspect. Actions: owner for the default branch's status; the case check; a comment in `scripts/version.sh` naming its requirement.
