# V157: Fork pull requests, the approval gate, and privileged triggers

- **Part.** 7: Security
- **Module.** 29
- **Planned minutes.** 26
- **Prerequisites.** V116, V123, V156
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), sections 21A.4 and 21A.5
- **Demo scripts.** `labs/ch21a/lab-29-1-inventory.sh` (snippets `triggers`, `narrow-scan`, `wide-scan`, `run-blocks`). There is no GitHub walkthrough in this video: the mechanism is described from section 21A.5 and its sources, and is not reproduced.

## HOOK

**[ON SCREEN]** A pull request from a fork. One failing check: "evaluation". The log says an API key is empty.

An open-source evaluation harness wants to show benchmark scores on contributor pull requests. The scores need a provider API key. For every outside contributor the job fails, because the key is not there.

A maintainer searches for the error, finds an answer with many upvotes, and changes one word in the trigger: `pull_request` becomes `pull_request_target`. The check goes green. The contributor is happy. The maintainer has handed the API key, and a read-write token for the repository, to anyone who opens a pull request.

The failing check was the security model working. The one-word change removed it. In this video you learn exactly what that word changes, and which line, usually two steps further down, completes the vulnerability.

## INTRODUCTION

In the last video you saw the model in five parts. This video is parts two and three: fork pull requests, and privileged triggers.

Part two is a protection. A workflow triggered by `pull_request` from a fork runs the contributor's version of the code with a read-only token and without your secrets. You will learn what that protects and what it leaves exposed, and what the approval gate for first-time contributors does and does not do.

Part three is where the protection is switched off on purpose. `pull_request_target` runs your workflow with your token and your secrets in response to a stranger's pull request. That can be exactly right. It becomes a vulnerability at one identifiable step.

This video is defensive, like the chapter. You will see the unsafe pattern as GitHub's own documentation prints it, marked insecure, next to its fixes. You will not see anything that could be used as it stands, and nothing is run against GitHub.

## LEARNING OBJECTIVES

After this video you can:

- explain why a fork pull request under `pull_request` gets no secrets and a read-only token, and what remains exposed;
- say what the approval gate for first-time contributors does;
- explain what `pull_request_target` and `workflow_run` change: whose workflow file, which token, which secrets;
- name the step that turns a privileged trigger into a vulnerability;
- state when `pull_request_target` is the right trigger and what changes on 2 November 2026, as the section gives it.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**Fork pull requests. In one sentence:** a workflow triggered by `pull_request` from a fork runs the contributor's version of the code with a read-only token and without your secrets.

**Precisely.** The documentation: "With the exception of `GITHUB_TOKEN`, secrets are not passed to the runner when a workflow is triggered from a forked repository. The `GITHUB_TOKEN` has read-only permissions in pull requests from forked repositories." Pull requests opened by Dependabot are treated the same way.

**The approval gate.** Whether such a run starts at all is a separate setting. For public repositories, by default, all first-time contributors require approval to run workflows. The options are approval for first-time contributors who are new to GitHub, for all first-time contributors, or for all external contributors.

The documentation attaches a warning. A user who has had any commit or pull request merged into the repository will not require approval. And a malicious user could meet that requirement by getting a small typing fix accepted. So the gate at its default is a first-contact check, not a per-request review.

**[ON SCREEN]** The two-column table of section 21A.4.

What the fork model protects. Your secrets: they are not sent to the runner. Your repository: the token cannot write.

What it does not protect. The runner itself: the contributor's code still executes on it. Readable data: a public repository's contents, and the caches a pull request may restore. A self-hosted runner, which is your machine. And workflows on privileged triggers, which, in the documentation's words, "will always run, regardless of approval settings".

The textbook calls that last row the hinge. The approval gate applies to `pull_request`. It does not apply to `pull_request_target`.

**Privileged triggers. In one sentence:** `pull_request_target` runs your workflow, from your default branch, with your token and your secrets, in response to a stranger's pull request; it is safe exactly as long as it never executes that stranger's code.

**Precisely.** GitHub's reference says such workflows "run with elevated trust: the job receives the base repository's `GITHUB_TOKEN` and access to repository and organization secrets". The trigger is safe by default because the workflow, and any later checkout that does not specify a `ref`, is taken from the base repository's default branch. Then the sentence that locates the risk: "You introduce risk when a workflow author overrides this default to run the fork's code."

And the sentence that locates the step. Quoting the reference: "The checkout step alone does not execute untrusted code… The vulnerability is completed by the next step that runs code checked out into the current working directory." The documentation gives this pattern a name and says it "has been the root cause of multiple supply-chain compromises".

The token is not read-only here. The workflow syntax reference: under `pull_request_target` the token "is granted read/write repository permission, even when it is triggered from a public fork".

**The unsafe pattern, as the documentation prints it.** The checkout line with `@v6` is the documentation's own example, quoted unchanged. The workflows of this course pin the checkout action at version 7.0.1 by commit ID, and since version 7 and its back-ports the action refuses this checkout unless a specific input is set.

```yaml
# INSECURE. Provided as an example only.
on:
  pull_request_target:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - name: Test
        run: make test
```

Read it with the question from the last video. Whose code runs? `make test` runs the Makefile of the pull request, so the contributor's. What can the job reach? A read-write token, and every repository and organization secret the workflow names. What an attacker achieves is whatever those credentials allow.

And the textbook widens one word. "Run" is wider than it looks. A build. An install step with lifecycle scripts. A test runner. A linter that loads a configuration file from the working directory. Each executes or is steered by files from the checkout.

**The shapes to look for in review,** from the same reference. Checking out the pull request's head or merge commit, through a `ref` built from the event. Pointing the checkout at the fork, through the `repository` input. Or fetching the code another way and running it: a `git fetch` of the pull request ref, `gh pr checkout`, or downloading an artifact built from it.

And the scope is wider than one trigger. The reference: such patterns "are also not unique to `pull_request_target`… an `issue_comment` or `workflow_run` workflow that fetches and runs a fork's pull request code is vulnerable in the same way." For `workflow_run`, remember from V143: it is about the default branch, and it can read secrets even when the first workflow could not. Its privilege comes from its position, not from the run that triggered it.

**The fix, in order of preference.**

One. Do not use the trigger. The reference: "If the workflow does not need `pull_request_target`, update it to use a safer event where appropriate, such as `pull_request`." Most CI needs no secrets and no write token.

```yaml
# Safe: the contributor's code runs, but with a read-only token and no secrets.
on:
  pull_request:

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - name: Test
        run: make test
```

Two. If a privileged action is needed, such as a comment or a label, keep `pull_request_target` but never check out or run the pull request's code. Operate on metadata only, with the narrowest `permissions`. This is the case in which `pull_request_target` is the right trigger.

Three. If the privileged action needs a result computed from the contributor's code, separate the two. GitHub Security Lab's design is an unprivileged `pull_request` workflow that builds and tests and uploads its result as an artifact, and a privileged `workflow_run` workflow that downloads the artifact and comments. Artifact data is safe there when it is used, in the article's words, "in a safe manner, like reading PR numbers or reading a code coverage text to comment on the PR".

A label as a gate, "run only when a maintainer adds a certain label", is weaker than it looks. The Security Lab article notes it is still prone to a race condition, in which the attacker may push new changes after the workflow was approved by the label but has not started yet.

**The platform now leans against the pattern.** Four changes matter in review, and the textbook is exact that none of them removes the need for review.

**[ON SCREEN]** The four-row table at the end of section 21A.5.

8 December 2025: the workflow file for `pull_request_target` always comes from the default branch. What it does not cover: a vulnerable workflow that is on the default branch.

`actions/checkout` version 7, 18 June 2026, back-ported to older lines on 20 July 2026: the action refuses to fetch a fork pull request's head or merge ref under `pull_request_target`, and under `workflow_run` started by a pull request event, unless `allow-unsafe-pr-checkout: true` is set. What it does not cover: a `git fetch` or `gh pr checkout` in a `run` step, and other events such as `issue_comment`.

Read-only caches for low-trust triggers, 26 June 2026: a privileged-trigger run cannot write the default branch's cache. What it does not cover: restoring a cache that was already poisoned.

And workflow execution protections, generally available 17 September 2026: GitHub announced that a default rule will block `pull_request_target` in public repositories from 2 November 2026 unless a maintainer allows it; check the changelog on the day you watch this. What it does not cover: private and internal repositories.

One input deserves a sentence of its own. The changelog says the opt-out flag "is intentionally named to be easy to spot in code review and static analysis". The reference says: "Only do this after confirming the checked-out code is never executed." In a pull request, the line `allow-unsafe-pr-checkout: true` needs a written justification.

## MENTAL MODEL

**Analogy for the fork model.** A visitor may use the lobby computer, which has no access to the internal network.

It breaks in two places. By default a visitor who has been in the building once is waved through without a check from then on. And the lobby computer may be one of your own machines: a self-hosted runner.

**Analogy for the privileged trigger.** The front desk has a procedure for parcels from unknown senders: log the parcel, put a sticker on it, send a receipt. The procedure is safe because the desk never opens the parcel. The vulnerability is the day someone amends the procedure to "open the parcel and follow the instructions inside", while the clerk still holds the master key.

Where that breaks: the parcel can also influence the clerk without being opened. Its label is event text. That is the next video.

So carry two questions into every review of a privileged trigger. Does anything bring the stranger's files onto the runner? And does any later step execute or get steered by files in the working directory? If both answers are yes, the trigger is no longer safe, whatever the intentions were.

## DIAGRAM

**[DIAGRAM]** Two lanes, side by side. Fill the left lane first, row by row. Then ask the viewer to predict each row of the right lane before you write it.

```text
  for a pull request      on: pull_request                     on: pull_request_target
  from a fork
  --------------------    ---------------------------------    -------------------------------------
  workflow file read      the commit the event refers to       the base repository's default branch
  from                    (the pull request can change it)
  checked out by          the test merge, refs/pull/N/merge    the base repository's default branch
  default                 (the contributor's code)             (NOT the contributor's code)
  GITHUB_TOKEN            read-only                            read/write, even from a public fork
  secrets                 none (except the token)              repository and organization secrets
  approval gate           applies                              does not apply: it always runs
  safe when               it needs no secret and no            it never checks out, fetches or runs
                          write token                          the pull request's code

                                                               the step that completes the
                                                               vulnerability: the NEXT step that runs
                                                               code checked out into the working
                                                               directory
```

**[DIAGRAM]** Each lane is consistent on its own. The left lane gives the stranger's code no privilege. The right lane gives privilege and, by default, no stranger's code. The vulnerability is a workflow that takes the token and secrets from the right lane and the code from the left.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21a/lab-29-1-inventory`. The same replay as in the last video; now you read four of its snippets as a reviewer of privileged triggers. Plain `grep` and `awk` on files. Nothing is executed.

**Step 1: the triggers, read with this video's question.**

```bash
grep -n -A3 '^on:' v*.yml
```

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

Two of the five files run with the base repository's token in response to something an outsider can do: file 1, on an opened issue, and file 2, on `pull_request_target`. Those two are where you now read every line. File 4 uses plain `pull_request`: the left lane of the diagram.

**Step 2: every expression in the files.**

```bash
grep -n '${{' v*.yml
```

The lab calls this the wide scan: every expression, with its line number, to be classified by hand. **[PAUSE]** In file 2, which line would tell you whether the stranger's code is brought onto the runner? You know the shape from the review table.

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

Line 28 of file 2: a `ref` built from the head commit of the pull request. That is the first shape in the documentation's table: checking out the pull request's head. Under `pull_request_target`.

Remember what the reference says about that line: the checkout step alone does not execute untrusted code. So the review is not finished. You open the file and read what comes after the checkout, and ask of each step whether it runs or is steered by files in the working directory. That reading is yours to do in the lab. And you look for one more line near the checkout, the one that the changelog says is named to be spotted.

**Step 3: a scan that looks convincing.**

```bash
grep -n 'run:.*${{' v*.yml
```

<!-- snippet: ch21a/lab-29-1-inventory/06-narrow-scan -->
```text
# A scan that looks convincing: expressions on a line that starts a run step.
$ grep -n 'run:.*${{' v*.yml
[exit status: 1]
```
<!-- /snippet -->

Exit status 1: no match. A reviewer who stops here reports that no script contains an expression. **[PAUSE]** Why can that be wrong? Think about how a multi-line script is written in YAML.

**Step 4: the lines of every multi-line script.**

<!-- snippet: ch21a/lab-29-1-inventory/08-run-blocks -->
```text
# The lines of every multi-line script (from "run: |" to the next step or job).
$ awk '/run: \|/ {inrun=1; next} /^ *- name:|^ *- uses:|^  [a-z-]*:$/ {inrun=0} inrun && /\$\{\{/ {print FILENAME ":" FNR ":" $0}' v*.yml
v1-issue-triage.yml:32:          echo "Labelled issue #${{ github.event.issue.number }}: ${{ github.event.issue.title }}" >> "$GITHUB_STEP_SUMMARY"
```
<!-- /snippet -->

The `awk` program prints expression lines that lie inside a block that starts with `run:` and a vertical bar. One line comes back, in file 1. The narrow scan missed it, because the expression is not on the line that says `run:`. It is on the line after. This is the subject of the next video. For now the lesson is about method: a scan tells you where to look, and a scan that returns nothing tells you only what that scan can see.

## COMMON MISTAKES

1. **Switching to `pull_request_target` so that fork pull requests get the secrets.** Root cause: that trigger gives the job the base repository's read-write token and secrets and is not subject to the approval gate; the textbook lists this advice as outdated and as the vulnerability class of this chapter.
2. **Treating the checkout of the pull request's head as the whole problem, or as no problem.** Root cause: the checkout alone executes nothing; the vulnerability is completed by the next step that runs code from the working directory.
3. **Thinking only of `make test` as "running code".** Root cause: a build, an install with lifecycle scripts, a test runner or a linter that loads a configuration file are all steered by files from the checkout.
4. **Relying on the approval gate.** Root cause: by default it covers first-time contributors only, and it does not apply to privileged triggers at all.
5. **Using a label as the gate for a privileged run.** Root cause: the contributor can push new changes after the label was added and before the workflow starts.

## PRODUCTION EXAMPLE

The textbook's case, which was the hook. An open-source evaluation harness wants to show benchmark scores on contributor pull requests. The scores need a provider API key. Under `pull_request` the key is absent, so the job fails for every outside contributor. The textbook's comment: this is the fork model working.

The wrong fix is the one-word change. The right ones, as the textbook lists them: run the keyed evaluation after merge. Or run it on demand, by a maintainer, on a branch inside the repository. Or split the work into an unprivileged run and a privileged follow-up that never executes the contributor's code, and that treats what the first run produced as data: it never executes it and never interpolates it into a script.

Each of the three costs something: later feedback, a manual step, or a second workflow to maintain. That cost is the price of not putting an outsider's code next to your credential.

## PRACTICE EXERCISE

Do Lab 29.1, "Find and fix five planted weaknesses", in [`lab-manual/m29-actions-security.md`](../../lab-manual/m29-actions-security.md). Part A runs in `labs/shell` and needs no GitHub access.

Collect the evidence with the scans, then read each file completely. Before you change anything, write one row per file: the line, the class, what an attacker could achieve and under which condition, and the smallest fix. For the file with the privileged trigger, predict which step completes the vulnerability before you read below the checkout.

The challenge is Exercise 29.2, "The comment workflow", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q312: "Explain a "pwn request" without using the word. Which step completes the vulnerability?"

A strong answer describes the pattern in terms of the two lanes: which trigger, what that trigger gives the job, what the workflow then brings onto the runner, and what happens next. It quotes the idea that the checkout alone executes nothing and names the kind of step that does. It says what an attacker can reach and why the approval gate does not help. The follow-up notes that the checkout action has refused that checkout since version 7 and asks whether the pattern is closed; answer from the "what it does not cover" column, and say what you still look for in review.

## RECAP

You should now be able to say:

- Under `pull_request`, a fork's code runs with a read-only token and no secrets; the runner, readable data and restorable caches remain exposed.
- The approval gate covers first-time contributors by default and does not apply to privileged triggers.
- `pull_request_target` takes the workflow from the default branch and gives the job a read-write token and the repository's secrets.
- The vulnerability is completed by the step that runs code checked out from the pull request, and "run" includes builds, installs, tests and tools that read configuration from the working directory.
- The trigger is right for metadata-only work; GitHub announced that from 2 November 2026 a default rule blocks it in public repositories unless a maintainer allows it.

## HOMEWORK

Read sections 21A.4 and 21A.5 of [Chapter 21A](../../textbook/ch21a-actions-security.md).
