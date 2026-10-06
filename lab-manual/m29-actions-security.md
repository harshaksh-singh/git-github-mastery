# Module 29 labs: GitHub Actions security

> **Baseline.** Git 2.55.0 on macOS; GitHub CLI 2.88.1; GitHub facts as of 1 October 2026. Read [Chapter 21A](../textbook/ch21a-actions-security.md) first. Every transcript under "Expected output" is real output of a replay script in `labs/ch21a/`; the transcripts show Git and `grep` working on workflow files. Nothing in this file was run against GitHub. The workflow files (`workflows/12-secure.yml`, the five files in `workflows/vulnerable/`, and the reference fixes in `labs/ch21a/fixed/`) were assembled from documented syntax and parse-checked with PyYAML; they were not executed on GitHub by the author. What GitHub shows is described from its documentation, with the link, and you record what you actually see.

## How these labs work

These labs are defensive: you review, harden and justify. You are never asked to attack anything, and no lab needs an exploit to be complete. A finding is proven by pointing at the line and naming the documented mechanism.

Each lab has a local Part A in the lab shell. Labs 29.1 and 29.2 have an optional Part B on GitHub.

> **Run Part B in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub.

Part B uses the practice repository `inventory-api` (the sample project of the Module 26 labs) in your practice organization. Two rules for Part B:

- **Never push an unfixed file from `workflows/vulnerable/` to GitHub.** Part B uses only workflow 12 and your fixed files.
- Keep the practice repository free of real secrets. Where a lab needs a secret to exist, its value is a dummy string.

For Part B, set `COURSE=/path/to/this/course` (the directory that contains `labs/` and `workflows/`) in your normal shell.

In transcripts, a line `[exit status: N]` is added by the replay tool; in your own shell, `echo $?` prints the same number. `grep` exits with status 1 when it finds nothing, which in these labs is often the result you want.

## Lab 29.1: Find and fix five planted weaknesses

### Objective

Review five workflows, each with one planted weakness of a different documented class. For each: locate the line, name the class, state what an attacker could achieve and under which condition, and make the smallest change that removes it.

### Prerequisites

Chapter 21A, sections 21A.2 to 21A.9. You need no GitHub access for Part A.

### Setup

```bash
bash labs/ch21a/setup-29-1-workflows.sh
labs/shell m29-1
```

The sandbox holds a repository `inventory-api` with one commit. Its `.github/workflows/` directory contains `12-secure.yml` and the five files `v1-…` to `v5-…`. Each teaching file says at the top what it is meant to do; that description is neutral on purpose.

### Commands

**Part A, in the lab shell.** First collect evidence, then read each file in full. Do not skip the reading: the scans tell you where to look, not what is wrong.

```bash
cd inventory-api/.github/workflows

# 1. Evidence: the five questions of Chapter 21A, section 21A.16
ls v*.yml
grep -n -A3 '^on:' v*.yml
grep -n -A2 '^permissions:' v*.yml
grep -n 'uses:' v*.yml
grep -n 'secrets\.\|github\.token' v*.yml
grep -n '${{' v*.yml

# 2. Read each file completely
less v1-issue-triage.yml        # and the other four

# 3. Write your findings before you change anything: one row per file
#    file | line | class | what an attacker could achieve, and when | smallest fix

# 4. Fix each file in your editor, one commit per file
git add v1-issue-triage.yml
git commit -m "v1: <what you fixed>"
```

**Part B, on GitHub (optional, normal shell).** Only after Part A is complete and verified. Copy your fixed `v3` and `v4` files into the practice repository on a branch, open a pull request, and watch the runs. Those two need no secret and no special trigger.

```bash
cd /path/to/your/clone/of/inventory-api
git switch -c lab/m29-fixed-workflows
cp ~/git-mastery-labs/hands-on/m29-1/inventory-api/.github/workflows/v3-nightly-check.yml .github/workflows/
cp ~/git-mastery-labs/hands-on/m29-1/inventory-api/.github/workflows/v4-format-check.yml .github/workflows/
git add .github/workflows
git commit -m "Add two reviewed workflows from Lab 29.1"
git push -u origin lab/m29-fixed-workflows
gh pr create --fill
gh pr checks
```

### Expected output

The evidence, from the replay `labs/ch21a/lab-29-1-inventory.sh`. Triggers first:

<!-- snippet: ch21a/lab-29-1-inventory/02-triggers -->
```text
$ grep -n -A3 '^on:' v*.yml
v1-issue-triage.yml:10:on:
v1-issue-triage.yml-11-  issues:
v1-issue-triage.yml-12-    types: [opened]
v1-issue-triage.yml-13-
--
v2-pr-test-report.yml:11:on:
v2-pr-test-report.yml-12-  pull_request_target:
v2-pr-test-report.yml-13-    types: [opened, synchronize, reopened]
v2-pr-test-report.yml-14-
--
v3-nightly-check.yml:10:on:
v3-nightly-check.yml-11-  schedule:
v3-nightly-check.yml-12-    - cron: "30 1 * * *"
v3-nightly-check.yml-13-  workflow_dispatch:
--
v4-format-check.yml:10:on:
v4-format-check.yml-11-  pull_request:
v4-format-check.yml-12-
v4-format-check.yml-13-permissions:
--
v5-build-and-deploy.yml:11:on:
v5-build-and-deploy.yml-12-  push:
v5-build-and-deploy.yml-13-    branches: [main]
v5-build-and-deploy.yml-14-
```
<!-- /snippet -->

Permissions:

<!-- snippet: ch21a/lab-29-1-inventory/03-permissions -->
```text
$ grep -n -A2 '^permissions:' v*.yml
v1-issue-triage.yml:14:permissions:
v1-issue-triage.yml-15-  issues: write
v1-issue-triage.yml-16-
--
v2-pr-test-report.yml:15:permissions:
v2-pr-test-report.yml-16-  contents: read
v2-pr-test-report.yml-17-  pull-requests: write
--
v3-nightly-check.yml:15:permissions: write-all
v3-nightly-check.yml-16-
v3-nightly-check.yml-17-jobs:
--
v4-format-check.yml:13:permissions:
v4-format-check.yml-14-  contents: read
v4-format-check.yml-15-
--
v5-build-and-deploy.yml:15:permissions:
v5-build-and-deploy.yml-16-  contents: read
v5-build-and-deploy.yml-17-
```
<!-- /snippet -->

Every action reference:

<!-- snippet: ch21a/lab-29-1-inventory/04-uses -->
```text
$ grep -n 'uses:' v*.yml
v2-pr-test-report.yml:26:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
v2-pr-test-report.yml:33:        uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
v3-nightly-check.yml:24:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
v3-nightly-check.yml:27:        uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
v4-format-check.yml:23:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
v4-format-check.yml:28:        uses: actions/setup-python@v7
v4-format-check.yml:33:        uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
v5-build-and-deploy.yml:28:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
v5-build-and-deploy.yml:32:        uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
v5-build-and-deploy.yml:44:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
v5-build-and-deploy.yml:48:        uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
v5-build-and-deploy.yml:61:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```
<!-- /snippet -->

Secrets and explicit uses of the job token:

<!-- snippet: ch21a/lab-29-1-inventory/05-secrets-and-tokens -->
```text
$ grep -n 'secrets\.\|github\.token' v*.yml
v1-issue-triage.yml:25:          GH_TOKEN: ${{ github.token }}
v2-pr-test-report.yml:45:          GH_TOKEN: ${{ github.token }}
v5-build-and-deploy.yml:19:  DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
```
<!-- /snippet -->

Every expression:

<!-- snippet: ch21a/lab-29-1-inventory/07-wide-scan -->
```text
# Every expression, with its line number. Classify each one by hand: is it inside a script?
$ grep -n '${{' v*.yml
v1-issue-triage.yml:25:          GH_TOKEN: ${{ github.token }}
v1-issue-triage.yml:26:          GH_REPO: ${{ github.repository }}
v1-issue-triage.yml:27:          ISSUE_NUMBER: ${{ github.event.issue.number }}
v1-issue-triage.yml:32:          echo "Labelled issue #${{ github.event.issue.number }}: ${{ github.event.issue.title }}" >> "$GITHUB_STEP_SUMMARY"
v2-pr-test-report.yml:28:          ref: ${{ github.event.pull_request.head.sha }}
v2-pr-test-report.yml:43:        if: ${{ !cancelled() }}
v2-pr-test-report.yml:45:          GH_TOKEN: ${{ github.token }}
v2-pr-test-report.yml:46:          GH_REPO: ${{ github.repository }}
v2-pr-test-report.yml:47:          PR_NUMBER: ${{ github.event.pull_request.number }}
v2-pr-test-report.yml:48:          OUTCOME: ${{ steps.test.outcome }}
v5-build-and-deploy.yml:19:  DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
```
<!-- /snippet -->

This is evidence, not analysis. The transcripts deliberately do not say which line of which file is the weakness; that is your work, and the analysis is in [the solutions file](../solutions/m29-vulnerable-workflows.md).

**Part B**, described from the documentation: `v4` runs on the pull request, with a read-only token; `v3` does not run, because neither of its triggers is a pull request event: `schedule` uses the workflow file on the default branch, and `workflow_dispatch` runs only when someone starts it, which is possible only once the file exists on the default branch ([events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)). Record what `gh pr checks` shows. Both runs need `uv.lock` in the repository, which you created in the Module 26 labs.

### What happened internally

Nothing ran. You read five programs and decided, for each, whose code and whose text reach which credential. Git recorded your fixes as five ordinary commits. On GitHub the files have no effect until they exist under `.github/workflows/` on a ref that an event resolves to: the pull request's merge ref for `pull_request`, the default branch for `schedule`, `issues` and `pull_request_target`.

### Checkpoint

Before you fix anything, you can state for each file, in one sentence each: the event that starts it, who can cause that event, what the token may do, which secrets the jobs hold, and whose code runs. If two files seem to have the same weakness, re-read: the five classes are different.

### Failure scenario

Use a scan that looks rigorous and misses a finding. A common first attempt at "find expressions inside scripts" searches for `run:` lines that contain an expression:

<!-- snippet: ch21a/lab-29-1-inventory/06-narrow-scan -->
```text
# A scan that looks convincing: expressions on a line that starts a run step.
$ grep -n 'run:.*${{' v*.yml
[exit status: 1]
```
<!-- /snippet -->

No match, exit status 1. If you stop here you report "no expression reaches a shell" for all five files, and the report is wrong.

### Recovery

A script may start on the line *after* `run: |`. The narrow pattern only sees single-line scripts. Scan the lines that belong to multi-line scripts instead:

<!-- snippet: ch21a/lab-29-1-inventory/08-run-blocks -->
```text
# The lines of every multi-line script (from "run: |" to the next step or job).
$ awk '/run: \|/ {inrun=1; next} /^ *- name:|^ *- uses:|^  [a-z-]*:$/ {inrun=0} inrun && /\$\{\{/ {print FILENAME ":" FNR ":" $0}' v*.yml
v1-issue-triage.yml:32:          echo "Labelled issue #${{ github.event.issue.number }}: ${{ github.event.issue.title }}" >> "$GITHUB_STEP_SUMMARY"
```
<!-- /snippet -->

The lesson is about tooling: a line-based pattern does not understand YAML block scalars. Purpose-built scanners parse the file (Chapter 21A, section 21A.14). Whether the line this scan prints is a weakness, and why, is for your findings table.

### Verification

Run the same scans on your fixed files. The replay `labs/ch21a/lab-29-1-fixes.sh` runs them on the reference fixes:

<!-- snippet: ch21a/lab-29-1-fixes/20-verify-patterns -->
```text
# After your fixes, each of these scans must come back empty (exit status 1 from grep).
$ grep -n 'pull_request_target\|allow-unsafe\|write-all' v*.yml
[exit status: 1]
$ grep -n 'uses:' v*.yml | grep -vE '@[0-9a-f]{40}( |$)'
[exit status: 1]
$ awk '/run: \|/ {inrun=1; next} /^ *- name:|^ *- uses:|^  [a-z-]*:$/ {inrun=0} inrun && /\$\{\{/ {print FILENAME ":" FNR ":" $0}' v*.yml
$ grep -n 'run:.*${{' v*.yml
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch21a/lab-29-1-fixes/21-verify-scope -->
```text
# Every workflow declares permissions, and the one secret is named in one step.
$ grep -c '^permissions:' v*.yml
v1-issue-triage.yml:1
v2-pr-test-report.yml:1
v3-nightly-check.yml:1
v4-format-check.yml:1
v5-build-and-deploy.yml:1
$ grep -n -B2 'secrets\.' v*.yml
v5-build-and-deploy.yml-61-      - name: Deploy (simulated)
v5-build-and-deploy.yml-62-        env:
v5-build-and-deploy.yml:63:          DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
```
<!-- /snippet -->

Your line numbers may differ. Then confirm that each file still parses (this needs PyYAML in your normal Python; skip it if you do not have it):

```bash
for f in v*.yml; do python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$f" && echo "parses: $f"; done
```

Passing scans do not prove that a fix is right, only that the known patterns are gone. Compare your fixes with the solutions file.

### Questions

1. For each of the five files: which line is the weakness, which class is it, and who must do what for it to matter?
2. Which of the five weaknesses can be exploited by someone with no access to the repository at all, and which need a prior compromise elsewhere?
3. `v2` sets `persist-credentials: false` and limits `permissions`. Why is that not enough?
4. `v1` uses three expressions in an `env:` block and two in a script. Which of the five are dangerous, and why not the others?
5. In `v5`, the secret is not printed anywhere. What is the exposure?
6. `v3` has a `schedule` trigger and no outside input. Why does its token matter?
7. Which organization-level policy would have rejected `v4` before it ran? Which would have blocked `v2` in a public repository from 2 November 2026?
8. Your narrow scan missed a finding. What does that say about relying on `grep` in CI, and what would you run instead?

## Lab 29.2: Justify every control of workflow 12

### Objective

Read `workflows/12-secure.yml` line by line and write, for each control, the threat it answers and what breaks if it is removed. Then remove two controls in a sandbox copy and see which checks notice.

### Prerequisites

Chapter 21A, section 21A.16, and Lab 29.1. Part B needs the practice repository `inventory-api` with `uv.lock`.

### Setup

The sandbox of Lab 29.1 (run `bash labs/ch21a/setup-29-1-workflows.sh` again for a clean copy), then `labs/shell m29-1`.

### Commands

**Part A, in the lab shell.**

```bash
cd inventory-api

# 1. Read the file with line numbers
grep -n '' .github/workflows/12-secure.yml | less

# 2. The five questions
grep -n -A4 '^on:' .github/workflows/12-secure.yml
grep -n -A2 'permissions:' .github/workflows/12-secure.yml
grep -n 'uses:' .github/workflows/12-secure.yml
grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
grep -n '${{' .github/workflows/12-secure.yml
grep -n 'secrets\.' .github/workflows/12-secure.yml

# 3. Write the table: control | line | threat | what breaks without it
#    The file marks nine controls with comments. Find at least two more that have no comment.
```

**Part B, on GitHub (normal shell).** Add the workflow to the practice repository through a pull request and observe which jobs run.

```bash
cd /path/to/your/clone/of/inventory-api
git switch -c lab/m29-secure-ci
cp "$COURSE/workflows/12-secure.yml" .github/workflows/secure-ci.yml
git add .github/workflows/secure-ci.yml
git commit -m "Add the secure-by-default CI workflow"
git push -u origin lab/m29-secure-ci
gh pr create --title "Add the secure-by-default CI workflow" --body "Lab 29.2"
gh pr checks
gh run list --workflow secure-ci.yml --limit 5
```

Then make the title job fail on purpose and repair it:

```bash
gh pr edit --title "Add the secure-by-default CI workflow with a title that is deliberately far too long for the rule"
```

Editing the title does not start a new run: the `pull_request` trigger without `types` reacts to `opened`, `synchronize` and `reopened` ([events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request)). Push an empty commit to start one (`git commit --allow-empty -m "Re-run CI" && git push`), read the failed job with `gh run view --log-failed`, then restore the short title and push again.

### Expected output

**Part A.** The scans are the ones printed in Chapter 21A, section 21A.16. The baseline in the replay `labs/ch21a/lab-29-2-controls.sh`:

<!-- snippet: ch21a/lab-29-2-controls/01-baseline -->
```text
$ git status --short
$ grep -c 'uses:' .github/workflows/12-secure.yml
6
$ grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
[exit status: 1]
$ grep -c 'persist-credentials: false' .github/workflows/12-secure.yml
4
```
<!-- /snippet -->

Six action references, none unpinned. The count 4 for `persist-credentials: false` is the three checkout steps plus the line of the header comment that names the control.

**Part B**, described from the documentation, not observed by the author. On the pull request the jobs `test`, `pr-metadata` and `dependency-review` run. `deploy-staging` is skipped: its `if:` requires a push to `main` and a repository variable `AWS_ROLE_ARN`, which you have not created. Dependency review depends on the repository's dependency graph; if that job fails in your repository, record the message and look up the requirement it names before changing anything. After the merge, `test` runs on `main` and the deployment job is still skipped. Leave it skipped unless you have a cloud account and have written the trust policy of section 21A.10 for the `staging` environment.

### What happened internally

On a pull request GitHub ran the workflow file from the pull request's merge ref with a token limited by the top-level `permissions`. The title reached the script as the value of `PR_TITLE`; the script text was the same for every title. No job requested an OIDC token, because the only job with `id-token: write` did not run.

### Checkpoint

You can explain, without looking, why `pr-metadata` has `permissions: {}`, why `deploy-staging` sets `cache-mode: none`, and why the deployment condition tests both the event name and the ref.

### Failure scenario

In the sandbox, make a "cleanup" that a hurried reviewer would approve: version tags in place of commit IDs, and less boilerplate.

<!-- snippet: ch21a/lab-29-2-controls/02-break -->
```text
# A "cleanup" that many reviewers would approve: readable version tags, less boilerplate.
$ sed -i.bak -e 's/@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1/@v7/' -e '/persist-credentials: false/d' .github/workflows/12-secure.yml
$ rm .github/workflows/12-secure.yml.bak
$ git diff --stat
 .github/workflows/12-secure.yml | 10 +++-------
 1 file changed, 3 insertions(+), 7 deletions(-)
```
<!-- /snippet -->

The file still parses, and on GitHub it would still pass its tests. Two controls are gone. Ask the audit questions again:

<!-- snippet: ch21a/lab-29-2-controls/03-detect -->
```text
$ grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
36:        uses: actions/checkout@v7
82:        uses: actions/checkout@v7
111:        uses: actions/checkout@v7
[exit status: 0]
$ grep -c 'persist-credentials: false' .github/workflows/12-secure.yml
0
[exit status: 1]
```
<!-- /snippet -->

Three references now follow a movable tag, and no checkout opts out of persisting the token. Nothing failed; a scan noticed.

### Recovery

The change was never committed, so the committed version is one command away:

<!-- snippet: ch21a/lab-29-2-controls/04-recover -->
```text
$ git restore .github/workflows/12-secure.yml
$ git status --short
$ grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
[exit status: 1]
$ grep -c 'persist-credentials: false' .github/workflows/12-secure.yml
4
```
<!-- /snippet -->

`git restore <path>` overwrites the working-tree file with the version from the index (the older spelling is `git checkout -- <path>`). 🔴 It discards uncommitted edits to that file without a reflog entry; look at `git diff` first.

### Verification

`git status --short` prints nothing, the unpinned scan exits with 1, and the count of `persist-credentials: false` is 4 again. For Part B: `gh pr checks` shows the three pull request jobs, and the run list shows no run of `deploy-staging` that executed steps.

### Questions

1. List every control in the file with the threat it answers. Which two have no numbered comment?
2. The workflow token is `contents: read`. Why does `pr-metadata` still override it with `{}`?
3. Why is `${{ vars.AWS_ROLE_ARN }}` acceptable as an action input, while `${{ github.event.pull_request.title }}` in a script is not?
4. `deploy-staging` runs only on a push to `main`. Which separate control makes sure that what reaches `main` was reviewed?
5. What would change in the OIDC subject if you removed `environment: staging`, and what would that do to an exact-match trust policy?
6. The "cleanup" in the failure scenario kept the tests green. Which three mechanisms would have stopped it in a real organization?
7. Name two things this workflow does not protect against.

## Lab 29.3: Review a pull request that changes workflows

### Objective

Write the review a security engineer would leave on a pull request that changes one workflow and adds another: one comment per finding, each with the line, the mechanism, the consequence, and the requested change, and an overall verdict.

### Prerequisites

Chapter 21A, sections 21A.18 and 21A.19. Chapter 17 for three-dot diffs.

### Setup

```bash
bash labs/ch21a/setup-29-3-review.sh
labs/shell m29-3
```

A repository `inventory-api` with a sound `ci.yml` on `main`, and a branch `feature/coverage-comment` by a teammate. **The pull request is constructed for this exercise.** The action `example-org/coverage-comment` and the host `coverage-tool.example.com` do not exist. The author's description reads:

> Contributors from forks could not see coverage on their pull requests because the token is missing there. This switches CI to the trigger that has secrets, adds the coverage uploader and a comment, moves CI to our own runner to save minutes, and adds a release workflow that publishes to PyPI on a version tag.

### Commands

```bash
cd inventory-api

# 1. What is in the pull request
git log --oneline main..feature/coverage-comment
git diff --stat main...feature/coverage-comment

# 2. Read the diff, file by file
git diff main...feature/coverage-comment -- .github/workflows/ci.yml
git diff main...feature/coverage-comment -- .github/workflows/release.yml

# 3. Read the new files whole: a diff hides the lines that did not change
git show feature/coverage-comment:.github/workflows/ci.yml
git show feature/coverage-comment:.github/workflows/release.yml

# 4. Apply the checklist of section 21A.19, item by item, and write your comments:
#    file:line | severity | what the line does | what an attacker could achieve | requested change
```

Write the comments in a file `review.md`. Finish with a verdict (approve, comment, or request changes) and a two-sentence summary for the author that is specific and not hostile: they were solving a real problem.

### Expected output

From the replay `labs/ch21a/lab-29-3-review.sh`. The overview:

<!-- snippet: ch21a/lab-29-3-review/01-overview -->
```text
$ git log --oneline --format="%h %an: %s" main..feature/coverage-comment
4b55a46 Ravi Menon: Post coverage comments on fork pull requests; add release workflow
$ git diff --stat main...feature/coverage-comment
 .github/workflows/ci.yml      | 22 +++++++++++++++++-----
 .github/workflows/release.yml | 17 +++++++++++++++++
 2 files changed, 34 insertions(+), 5 deletions(-)
```
<!-- /snippet -->

The diff to review, first file (constructed for the exercise):

<!-- snippet: ch21a/lab-29-3-review/02-diff-ci -->
```text
$ git diff main...feature/coverage-comment -- .github/workflows/ci.yml
diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
index ed885e4..ee07560 100644
--- a/.github/workflows/ci.yml
+++ b/.github/workflows/ci.yml
@@ -1,21 +1,33 @@
 name: ci
 
 on:
-  pull_request:
+  pull_request_target:
   push:
     branches: [main]
 
 permissions:
-  contents: read
+  contents: write
+  pull-requests: write
+
+env:
+  COVERAGE_TOKEN: ${{ secrets.COVERAGE_TOKEN }}
+  PYPI_API_TOKEN: ${{ secrets.PYPI_API_TOKEN }}
 
 jobs:
   test:
-    runs-on: ubuntu-24.04
-    timeout-minutes: 15
+    runs-on: [self-hosted, linux]
     steps:
       - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
         with:
-          persist-credentials: false
+          ref: ${{ github.event.pull_request.head.sha }}
+          allow-unsafe-pr-checkout: true
       - uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
       - run: uv sync --locked
       - run: uv run pytest
+      - name: Install the coverage uploader
+        run: curl -sSL https://coverage-tool.example.com/install.sh | bash
+      - name: Announce
+        run: echo "Coverage for ${{ github.head_ref }} uploaded"
+      - uses: example-org/coverage-comment@v3
+        with:
+          token: ${{ secrets.GITHUB_TOKEN }}
```
<!-- /snippet -->

Second file, new in this pull request (constructed for the exercise):

<!-- snippet: ch21a/lab-29-3-review/03-diff-release -->
```text
$ git diff main...feature/coverage-comment -- .github/workflows/release.yml
diff --git a/.github/workflows/release.yml b/.github/workflows/release.yml
new file mode 100644
index 0000000..bc9f3ce
--- /dev/null
+++ b/.github/workflows/release.yml
@@ -0,0 +1,17 @@
+name: release
+
+on:
+  push:
+    tags: ["v*"]
+
+jobs:
+  publish:
+    runs-on: ubuntu-24.04
+    steps:
+      - uses: actions/checkout@v7
+      - uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
+        with:
+          enable-cache: true
+      - run: uv build
+      - name: Publish
+        run: uv publish --token "${{ secrets.PYPI_API_TOKEN }}"
```
<!-- /snippet -->

### What happened internally

`main...feature/coverage-comment` compares the branch with its merge base, which is what a pull request page shows. `git show <branch>:<path>` prints a blob from the branch's tree without touching your working tree. You changed nothing: a review is read-only.

### Checkpoint

You have at least eight separate findings across the two files, and for each one you can name the section of Chapter 21A that explains the mechanism. You also have at least one line that looks alarming and is acceptable, with the reason.

### Failure scenario

Review the wrong diff. While the pull request was open, `main` moved (in the replay, a README change). A reviewer who compares the two branch tips with two dots sees a change that the author never made:

<!-- snippet: ch21a/lab-29-3-review/05-wrong-base -->
```text
# Two dots compare the tips. After main moves, the same command shows changes the author never made.
$ git diff --stat main..feature/coverage-comment
 .github/workflows/ci.yml      | 22 +++++++++++++++++-----
 .github/workflows/release.yml | 17 +++++++++++++++++
 README.md                     |  2 --
 3 files changed, 34 insertions(+), 7 deletions(-)
# Three dots compare the branch with the merge base, as the pull request page does.
$ git diff --stat main...feature/coverage-comment
 .github/workflows/ci.yml      | 22 +++++++++++++++++-----
 .github/workflows/release.yml | 17 +++++++++++++++++
 2 files changed, 34 insertions(+), 5 deletions(-)
```
<!-- /snippet -->

The two-dot form reports that the branch "removes" two README lines. A comment on that would be wrong and would cost you credibility for the comments that matter. In your sandbox, reproduce it:

```bash
printf '\nRuns on GitHub Actions.\n' >> README.md
git commit -am "Describe CI in the README"
git diff --stat main..feature/coverage-comment
```

### Recovery

Use three dots, as in the second half of the transcript above: the comparison starts at the merge base, so only the author's changes appear. Nothing needs to be undone; the extra commit on your sandbox `main` is harmless.

### Verification

A pattern search over the branch versions of both files gives a floor for your findings: every line it prints should be covered by one of your comments, or be explicitly accepted.

<!-- snippet: ch21a/lab-29-3-review/04-added-lines -->
```text
# The branch versions of both files, searched for the patterns of the checklist.
$ git grep -n -E "pull_request_target|allow-unsafe|self-hosted|\| bash|@v[0-9]|secrets\.|write" feature/coverage-comment -- .github/workflows
feature/coverage-comment:.github/workflows/ci.yml:4:  pull_request_target:
feature/coverage-comment:.github/workflows/ci.yml:9:  contents: write
feature/coverage-comment:.github/workflows/ci.yml:10:  pull-requests: write
feature/coverage-comment:.github/workflows/ci.yml:13:  COVERAGE_TOKEN: ${{ secrets.COVERAGE_TOKEN }}
feature/coverage-comment:.github/workflows/ci.yml:14:  PYPI_API_TOKEN: ${{ secrets.PYPI_API_TOKEN }}
feature/coverage-comment:.github/workflows/ci.yml:18:    runs-on: [self-hosted, linux]
feature/coverage-comment:.github/workflows/ci.yml:23:          allow-unsafe-pr-checkout: true
feature/coverage-comment:.github/workflows/ci.yml:28:        run: curl -sSL https://coverage-tool.example.com/install.sh | bash
feature/coverage-comment:.github/workflows/ci.yml:31:      - uses: example-org/coverage-comment@v3
feature/coverage-comment:.github/workflows/ci.yml:33:          token: ${{ secrets.GITHUB_TOKEN }}
feature/coverage-comment:.github/workflows/release.yml:11:      - uses: actions/checkout@v7
feature/coverage-comment:.github/workflows/release.yml:17:        run: uv publish --token "${{ secrets.PYPI_API_TOKEN }}"
```
<!-- /snippet -->

The search cannot find what is *missing* (a `permissions` block, a `timeout-minutes`, an environment). Check your review for at least two findings about absent lines, then compare with the [answers](../solutions/m29-lab-answers.md).

### Questions

1. List your findings in order of severity. Which single line would you fix first if you could fix only one, and why?
2. The author's goal is legitimate. Design a version that gives fork contributors a coverage comment without any of the findings.
3. Which findings in `ci.yml` combine into something worse than each alone? Name the incident in section 21A.18 that had the same combination.
4. `release.yml` has no `permissions` key. What does its token get, and what does the answer depend on?
5. `uv publish --token "${{ secrets.PYPI_API_TOKEN }}"` passes a secret through an expression in a script. Is it script injection? What is wrong with it anyway, and what replaces it?
6. Which finding does `actions/checkout` v7 make visible by itself, and how?
7. The pull request passed CI. Why is that not evidence of anything here?
8. Which repository or organization settings would have prevented this pull request from merging without a security review?
