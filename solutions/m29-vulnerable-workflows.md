# Module 29: analysis of the five teaching workflows

> **Baseline.** GitHub facts as of 1 October 2026. This is the analysis for Lab 29.1 of the [Module 29 lab manual](../lab-manual/m29-actions-security.md). Do the lab first. The files in `workflows/vulnerable/` and the reference fixes in `labs/ch21a/fixed/` were assembled from documented syntax and parse-checked with PyYAML; none was executed on GitHub. The diffs below are real `git diff` output from the replay `labs/ch21a/lab-29-1-fixes.sh`. Each analysis says what an attacker could achieve and how the fix prevents it; it contains no attack input, and you do not need one to justify the finding.

## Summary

| File | Line | Class | Who can trigger it | Smallest fix |
|---|---|---|---|---|
| `v1-issue-triage.yml` | 32 | Expression injection in a `run` step | Anyone who can open an issue | Pass the title through `env:` |
| `v2-pr-test-report.yml` | 12, 28, 29 | Privileged trigger that checks out and runs untrusted code | Anyone who can open a pull request | Use `pull_request`; drop the head checkout |
| `v3-nightly-check.yml` | 15 | Over-broad `permissions` | Nobody directly; it multiplies any other compromise | `contents: read` |
| `v4-format-check.yml` | 28 | Action referenced by a mutable tag | Whoever controls the tag | Pin to the commit |
| `v5-build-and-deploy.yml` | 18, 19 | Secret exposed to more jobs than need it | Any code that runs in any job | Name the secret in the one step that uses it |

The fixes change 24 lines in and 33 lines out across the five files:

<!-- snippet: ch21a/lab-29-1-fixes/01-stat -->
```text
$ git diff --stat
 .github/workflows/v1-issue-triage.yml     |  9 +++++----
 .github/workflows/v2-pr-test-report.yml   | 22 +++++++---------------
 .github/workflows/v3-nightly-check.yml    |  9 +++++----
 .github/workflows/v4-format-check.yml     |  6 ++----
 .github/workflows/v5-build-and-deploy.yml | 11 +++++------
 5 files changed, 24 insertions(+), 33 deletions(-)
```
<!-- /snippet -->

## v1: expression injection in a `run` step

**The line.** Line 32, inside a multi-line script: the issue title is written with `${{ github.event.issue.title }}`.

**Mechanism.** The expression is replaced by the title in the script text before the shell starts ([script injections](https://docs.github.com/en/actions/concepts/security/script-injections)). `title` is on the documented list of untrusted context endings. The surrounding double quotes are part of the script, and the title is pasted between them, so a title that contains a double quote ends the string.

**What an attacker could achieve.** Commands of their choice in this job, by opening an issue, which needs no access to the repository. The job's token has `issues: write`, so the direct reach is editing, labelling and closing issues, plus whatever the runner can reach on the network. The damage is bounded because the workflow is otherwise careful: narrow `permissions`, no secrets, no checkout. That is the argument for least privilege: it decides what an injection is worth.

**Why the other expressions are fine.** Lines 25 to 27 sit under `env:`: their values never enter script text. The issue number on line 32 is in the script, but it is a number assigned by GitHub and cannot carry code. The reference fix moves it anyway, so that the script contains no expression at all and can be reviewed once.

**The fix.**

<!-- snippet: ch21a/lab-29-1-fixes/11-diff-v1 -->
```text
$ git diff -U2 -- v1-issue-triage.yml | grep -v '^index '
diff --git a/.github/workflows/v1-issue-triage.yml b/.github/workflows/v1-issue-triage.yml
--- a/.github/workflows/v1-issue-triage.yml
+++ b/.github/workflows/v1-issue-triage.yml
@@ -1,5 +1,3 @@
-# TEACHING MATERIAL. DO NOT USE THIS WORKFLOW IN A REAL REPOSITORY.
-# It contains one deliberately planted security weakness for Lab 29.1 (Module 29).
-# Find it, name its class, and fix it. The analysis is in solutions/m29-vulnerable-workflows.md.
+# Reference fix for Lab 29.1 (see solutions/m29-vulnerable-workflows.md).
 # Assembled from documented syntax and parse-checked with PyYAML; never executed on GitHub.
 #
@@ -29,4 +27,7 @@ jobs:
 
       - name: Record the issue in the job summary
+        env:
+          ISSUE_NUMBER: ${{ github.event.issue.number }}
+          ISSUE_TITLE: ${{ github.event.issue.title }}
         run: |
-          echo "Labelled issue #${{ github.event.issue.number }}: ${{ github.event.issue.title }}" >> "$GITHUB_STEP_SUMMARY"
+          echo "Labelled issue #$ISSUE_NUMBER: $ISSUE_TITLE" >> "$GITHUB_STEP_SUMMARY"
```
<!-- /snippet -->

The script is now constant. The title reaches the shell as the value of `$ISSUE_TITLE` after parsing, and the shell does not re-parse a variable's value as commands. The quotes around the `echo` argument keep the value from being split into words.

**An insufficient fix.** Changing the quoting inside the script (single quotes, escaping) leaves the substitution in place: the title still becomes script text.

## v2: a privileged trigger that checks out and runs untrusted code

**The lines.** Line 12 (`pull_request_target`), lines 28 and 29 (`ref:` set to the pull request's head commit, with `allow-unsafe-pr-checkout: true`), and then the steps that run code from that checkout: `uv sync --locked` and `uv run pytest`.

**Mechanism.** The trigger runs the workflow with the base repository's token and access to its secrets, for pull requests from forks, and without the first-time-contributor approval gate. The checkout replaces the trusted working tree with the contributor's. "The vulnerability is completed by the *next* step that runs code checked out into the current working directory" ([securely using pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)). A test suite is code; so is a build backend named in `pyproject.toml`.

**What an attacker could achieve.** Code execution in a job whose token has `pull-requests: write`, started by opening a pull request. With this workflow's narrow `permissions` and no named secrets, the direct reach is commenting on and editing pull requests. Two things make it worse than it reads: the same pattern with one more scope or one secret is a repository compromise, and before the cache change of 26 June 2026 a job like this could write the default branch's cache regardless of `permissions` (Chapter 21A, section 21A.11).

**What does not save it.** `persist-credentials: false` keeps the token out of the Git configuration, but `GH_TOKEN` is still handed to a later step and the job token is available to actions. `allow-unsafe-pr-checkout: true` is the author switching off the refusal that `actions/checkout` v7 would otherwise apply: the line that should have triggered the review.

**The fix.**

<!-- snippet: ch21a/lab-29-1-fixes/12-diff-v2 -->
```text
$ git diff -U2 -- v2-pr-test-report.yml | grep -v '^index '
diff --git a/.github/workflows/v2-pr-test-report.yml b/.github/workflows/v2-pr-test-report.yml
--- a/.github/workflows/v2-pr-test-report.yml
+++ b/.github/workflows/v2-pr-test-report.yml
@@ -1,8 +1,6 @@
-# TEACHING MATERIAL. DO NOT USE THIS WORKFLOW IN A REAL REPOSITORY.
-# It contains one deliberately planted security weakness for Lab 29.1 (Module 29).
-# Find it, name its class, and fix it. The analysis is in solutions/m29-vulnerable-workflows.md.
+# Reference fix for Lab 29.1 (see solutions/m29-vulnerable-workflows.md).
 # Assembled from documented syntax and parse-checked with PyYAML; never executed on GitHub.
 #
-# What it does: runs the test suite for a pull request and posts the result as a comment,
+# What it does: runs the test suite for a pull request and writes the result to the job summary,
 # including on pull requests that come from forks.
 
@@ -10,14 +8,13 @@ name: pr-test-report
 
 on:
-  pull_request_target:
+  pull_request:
     types: [opened, synchronize, reopened]
 
 permissions:
   contents: read
-  pull-requests: write
 
 jobs:
-  test-and-comment:
-    name: Test and comment
+  test:
+    name: Test
     runs-on: ubuntu-24.04
     timeout-minutes: 15
@@ -26,6 +23,4 @@ jobs:
         uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
         with:
-          ref: ${{ github.event.pull_request.head.sha }}
-          allow-unsafe-pr-checkout: true
           persist-credentials: false
 
@@ -40,11 +35,8 @@ jobs:
         run: uv run pytest
 
-      - name: Comment on the pull request
+      - name: Write the result to the job summary
         if: ${{ !cancelled() }}
         env:
-          GH_TOKEN: ${{ github.token }}
-          GH_REPO: ${{ github.repository }}
-          PR_NUMBER: ${{ github.event.pull_request.number }}
           OUTCOME: ${{ steps.test.outcome }}
         run: |
-          gh pr comment "$PR_NUMBER" --body "Test result: $OUTCOME"
+          echo "Test result: $OUTCOME" >> "$GITHUB_STEP_SUMMARY"
```
<!-- /snippet -->

Under `pull_request`, a checkout without `ref` gets the merge ref, the contributor's code runs with a read-only token and no secrets, and the approval gate applies. The comment is gone, because a fork run cannot write; the result goes to the job summary. If the team wants the comment back, the design is the split of section 21A.5: this workflow uploads the result as an artifact, and a `workflow_run` workflow with `pull-requests: write` posts it, treating the artifact as data.

**Insufficient fixes.** Removing only the flag makes the workflow fail at checkout, which is safe but broken. Keeping the trigger and adding a label condition leaves the race described in section 21A.5.

## v3: over-broad `permissions`

**The line.** Line 15: `permissions: write-all`.

**Mechanism.** The shorthand grants `write` on every scope to every job ([workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions)). The job lints and tests; it needs to read the repository and nothing else. In addition, the checkout persists the token for the rest of the job.

**What an attacker could achieve.** Nothing by themselves: `schedule` and `workflow_dispatch` take no outside input. The weakness is a multiplier. The job runs third-party code (two actions, and every dependency that `uv sync` installs and `pytest` imports). If any of it is compromised upstream, it holds a token that can push commits and tags, create releases, write packages and edit issues and pull requests, limited only by rulesets. With `contents: read` the same compromise can read a repository.

**The fix.**

<!-- snippet: ch21a/lab-29-1-fixes/13-diff-v3 -->
```text
$ git diff -U2 -- v3-nightly-check.yml | grep -v '^index '
diff --git a/.github/workflows/v3-nightly-check.yml b/.github/workflows/v3-nightly-check.yml
--- a/.github/workflows/v3-nightly-check.yml
+++ b/.github/workflows/v3-nightly-check.yml
@@ -1,5 +1,3 @@
-# TEACHING MATERIAL. DO NOT USE THIS WORKFLOW IN A REAL REPOSITORY.
-# It contains one deliberately planted security weakness for Lab 29.1 (Module 29).
-# Find it, name its class, and fix it. The analysis is in solutions/m29-vulnerable-workflows.md.
+# Reference fix for Lab 29.1 (see solutions/m29-vulnerable-workflows.md).
 # Assembled from documented syntax and parse-checked with PyYAML; never executed on GitHub.
 #
@@ -13,5 +11,6 @@ on:
   workflow_dispatch:
 
-permissions: write-all
+permissions:
+  contents: read
 
 jobs:
@@ -23,4 +22,6 @@ jobs:
       - name: Check out the repository
         uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
+        with:
+          persist-credentials: false
 
       - name: Install uv
```
<!-- /snippet -->

The second hunk, `persist-credentials: false`, is a related hardening and not the planted weakness. Deleting the `permissions` line instead would be worse than it looks: the token would then follow the repository's default, which is still read-write in repositories created before February 2023.

## v4: an action referenced by a mutable tag

**The line.** Line 28: `uses: actions/setup-python@v7`. The other two references are commit IDs.

**Mechanism.** `v7` is a tag in the action's repository; the reference is resolved on every run. A tag "can be moved or deleted if a bad actor gains access to the repository" ([secure use](https://docs.github.com/en/actions/reference/security/secure-use#using-third-party-actions)). The local demonstration is in Chapter 21A, section 21A.7.

**What an attacker could achieve.** Someone who gains push access to the action's repository, or to a maintainer's token, can repoint the tag; from the next run on, their code executes in this job. Here that means a read-only token and no secrets, on pull requests: again the surrounding least privilege limits the value. The same line in a release workflow would be the tj-actions scenario. That the action is published by GitHub lowers the likelihood; it does not change the mechanism, and the organization policy that requires pinning makes no exception for GitHub's own actions.

**The fix.**

<!-- snippet: ch21a/lab-29-1-fixes/14-diff-v4 -->
```text
$ git diff -U2 -- v4-format-check.yml | grep -v '^index '
diff --git a/.github/workflows/v4-format-check.yml b/.github/workflows/v4-format-check.yml
--- a/.github/workflows/v4-format-check.yml
+++ b/.github/workflows/v4-format-check.yml
@@ -1,5 +1,3 @@
-# TEACHING MATERIAL. DO NOT USE THIS WORKFLOW IN A REAL REPOSITORY.
-# It contains one deliberately planted security weakness for Lab 29.1 (Module 29).
-# Find it, name its class, and fix it. The analysis is in solutions/m29-vulnerable-workflows.md.
+# Reference fix for Lab 29.1 (see solutions/m29-vulnerable-workflows.md).
 # Assembled from documented syntax and parse-checked with PyYAML; never executed on GitHub.
 #
@@ -26,5 +24,5 @@ jobs:
 
       - name: Set up Python
-        uses: actions/setup-python@v7
+        uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
         with:
           python-version: "3.12"
```
<!-- /snippet -->

The commit ID and version come from `workflows/ACTION_PINS.md`. Re-verify it with the `git ls-remote` command in that file before you trust it.

**Insufficient fixes.** `@v7.0.0` is still a tag. An abbreviated commit ID is not a full-length pin.

## v5: a secret exposed to more jobs than need it

**The lines.** Lines 18 and 19: a workflow-level `env:` block that puts `secrets.STAGING_DEPLOY_TOKEN` into the environment of every step of every job.

**Mechanism.** Workflow-level `env` applies to all jobs. `lint` and `test` install and run dependencies, and all three jobs run third-party actions. Each of those processes can read its environment. Masking does not help: it redacts log output, and "this redaction is not guaranteed" ([secure use](https://docs.github.com/en/actions/reference/security/secure-use#use-secrets-for-sensitive-information)).

**What an attacker could achieve.** A compromised dependency or action in the lint or test job obtains the deployment token, although only the deploy step needs it. The exposure is three jobs wide where it should be one step wide, and it is not gated by any environment rule.

**The fix.**

<!-- snippet: ch21a/lab-29-1-fixes/15-diff-v5 -->
```text
$ git diff -U2 -- v5-build-and-deploy.yml | grep -v '^index '
diff --git a/.github/workflows/v5-build-and-deploy.yml b/.github/workflows/v5-build-and-deploy.yml
--- a/.github/workflows/v5-build-and-deploy.yml
+++ b/.github/workflows/v5-build-and-deploy.yml
@@ -1,5 +1,3 @@
-# TEACHING MATERIAL. DO NOT USE THIS WORKFLOW IN A REAL REPOSITORY.
-# It contains one deliberately planted security weakness for Lab 29.1 (Module 29).
-# Find it, name its class, and fix it. The analysis is in solutions/m29-vulnerable-workflows.md.
+# Reference fix for Lab 29.1 (see solutions/m29-vulnerable-workflows.md).
 # Assembled from documented syntax and parse-checked with PyYAML; never executed on GitHub.
 #
@@ -16,7 +14,4 @@ permissions:
   contents: read
 
-env:
-  DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
-
 jobs:
   lint:
@@ -57,4 +52,6 @@ jobs:
     runs-on: ubuntu-24.04
     timeout-minutes: 15
+    environment:
+      name: staging
     steps:
       - name: Check out the repository
@@ -63,3 +60,5 @@ jobs:
           persist-credentials: false
       - name: Deploy (simulated)
+        env:
+          DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
         run: bash scripts/deploy.sh staging
```
<!-- /snippet -->

The secret is named in one step. The `environment` key lets you move the secret from the repository to the `staging` environment and put protection rules in front of it; creating the environment secret and its rules is a settings change that the diff cannot show. The better end state replaces the stored token with OIDC, as workflow 12 does.

**Insufficient fix.** Moving the `env:` block to the job level of `deploy` is an improvement, but the checkout action in that job would still receive the token in its environment. Step level is the narrowest place.

## What the five have in common

Each file is otherwise careful, so that exactly one weakness stands out. In real repositories they arrive together, and the incidents of section 21A.18 are combinations: an injection (v1) in a privileged trigger (v2) with a write token (v3) reached a publish secret that was in scope (v5) in the Nx case. Fix the class, then ask what the remaining weaknesses would have multiplied.
