# V157: Fork pull requests, the approval gate, and privileged triggers

- **Part.** 7: Security
- **Module.** 29
- **Planned minutes.** 26
- **Prerequisites.** V116, V123, V156
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), sections 21A.4 and 21A.5
- **Demo scripts.** `labs/ch21a/lab-29-1-inventory.sh` (snippets `triggers`, `narrow-scan`, `wide-scan`, `run-blocks`). There is no GitHub walkthrough in this video: the mechanism is described from section 21A.5 and its sources, and is not reproduced.

## HOOK

**[ON SCREEN]** A pull request from a fork. One failing check: "evaluation". The log says an API key is empty.

An open-source evaluation harness wants to show benchmark scores on contributor pull requests. The scores need a provider API key. For every outside contributor the job fails, because the key isn't there.

**[ANIMATION]** stores: boxes=the_workflow:its_trigger|the_check_"evaluation":on_a_fork_pull_request|anyone_who_opens_a_pull_request:what_they_are_handed rows=1:A:pull__request|1:B:fails:_the_API_key_is_empty@bad|2:A:pull__request__target@hl|2:B:the_check_goes_green@ok|3:C:the_API_key@bad|3:C:a_read-write_token_for_the_repository@bad arrows=3:A2>C title=One_word_in_the_trigger id=word mono=on at_1=4 at_2=45 at_3=78

**[ANIMATION]** step: word.3

A maintainer searches for the error, finds an answer with many upvotes, and changes one word in the trigger, the line that says which event starts the workflow: `pull_request` becomes `pull_request_target`. The check goes green. The contributor is happy. The maintainer has handed the API key, and a read-write token for the repository, to anyone who opens a pull request.

**[ANIMATION]** say: The_failing_check_was_the_security_model_working

The failing check was the security model working. The one-word change removed it. In this video you learn exactly what that word changes, and which line, usually two steps further down, completes the vulnerability. Keep those two steps in mind.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you saw the model in five parts. This video is parts two and three: fork pull requests, and privileged triggers.

A reminder of four words. A workflow is a file that says: when this event happens, run these jobs, each on a fresh machine called a runner. A fork is a second repository on GitHub, made from yours. A pull request proposes merging a branch into yours. A secret is an encrypted value stored in GitHub's settings.

Part two is a protection. A workflow triggered by `pull_request` from a fork runs the contributor's version of the code with a read-only token and without your secrets. You'll learn what that protects and what it leaves exposed, and what the approval gate for first-time contributors does and doesn't do.

Part three is where the protection is switched off on purpose. `pull_request_target` runs your workflow with your token and your secrets in response to a stranger's pull request. That can be exactly right. It becomes a vulnerability at one identifiable step.

This video is defensive, like the chapter. You'll see the unsafe pattern as GitHub's own documentation prints it, marked insecure, next to its fixes. You won't see anything that could be used as it stands, and nothing is run against GitHub.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- explain why a fork pull request under `pull_request` gets no secrets and a read-only token, and what remains exposed;
- say what the approval gate for first-time contributors does;
- explain what `pull_request_target` and `workflow_run` change: whose workflow file, which token, which secrets;
- name the step that turns a privileged trigger into a vulnerability;
- state when `pull_request_target` is the right trigger and what changes on 2 November 2026, as the section gives it.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**Fork pull requests. In one sentence:** a workflow triggered by `pull_request` from a fork runs the contributor's version of the code with a read-only token and without your secrets.

**Precisely.** The documentation: "With the exception of `GITHUB_TOKEN`, secrets are not passed to the runner when a workflow is triggered from a forked repository. The `GITHUB_TOKEN` has read-only permissions in pull requests from forked repositories." Pull requests opened by Dependabot, GitHub's dependency update feature, are treated the same way.

**[ANIMATION]** decide: nodes=q:Any_commit_or_pull_request_merged_before?|no:requires_approval_to_run_workflows|yes:will_not_require_approval edges=q>no:no|q>yes:yes path=q,yes title=The_approval_gate,_at_its_default id=gate say_path=A_first-contact_check,_not_a_per-request_review at_path=70

**[ANIMATION]** step: gate.level-2

**The approval gate.** Whether such a run starts at all is a separate setting. For public repositories, by default, all first-time contributors require approval to run workflows. The options are approval for first-time contributors who are new to GitHub, for all first-time contributors, or for all external contributors.

**[ANIMATION]** step: gate.path

The documentation attaches a warning. A user who has had any commit or pull request merged into the repository will not require approval. And a malicious user could meet that requirement by getting a small typing fix accepted. So the gate at its default is a first-contact check, not a per-request review.

**[ON SCREEN]** The two-column table of section 21A.4.

What the fork model protects. Your secrets: they aren't sent to the runner. Your repository: the token can't write.

What it doesn't protect. The runner itself: the contributor's code still executes on it. Readable data: a public repository's contents, and the caches a pull request may restore. A cache is a stored directory that a later run can restore. A self-hosted runner, which is your machine. And workflows on privileged triggers, which, in the documentation's words, "will always run, regardless of approval settings".

The textbook calls that last row the hinge. The approval gate applies to `pull_request`. It doesn't apply to `pull_request_target`.

**[ANIMATION]** cards: question=A_stranger's_fork_pull_request_starts_a_pull__request_run._What_does_the_job_hold? cards=A:a_read-write_token_and_your_secrets|B:a_read-only_token_and_no_secrets marks=1:bad,2:ok id=quiz

**[ANIMATION]** step: quiz.2

Quick quiz. A stranger's fork pull request starts a `pull_request` run. What does the job hold? A, a read-write token and your secrets. B, a read-only token and no secrets. Your answer?

**[PAUSE]**

**[ANIMATION]** step: quiz.marks

B. The token can read, and your secrets stay behind. But the stranger's code still runs on the runner.

**[ANIMATION]** end

**Privileged triggers. In one sentence:** `pull_request_target` runs your workflow, from your default branch, with your token and your secrets, in response to a stranger's pull request. It's safe exactly as long as it never executes that stranger's code. The default branch is the branch a repository presents first.

**[ANIMATION]** gates: packet=a_stranger's_pull_request gates=pull__request__target:pass:the_trigger:your_workflow,_your_token,_your_secrets|a_checkout_with_a_ref:pass:brings_the_fork's_code:alone_does_not_execute_untrusted_code|the_next_step_that_runs_checked-out_code:stop:completes_the_vulnerability:for_example_make_test title=Where_a_privileged_trigger_becomes_a_vulnerability id=risk

**[ANIMATION]** step: risk.1

**Precisely.** GitHub's reference says such workflows "run with elevated trust: the job receives the base repository's `GITHUB_TOKEN` and access to repository and organization secrets". The base repository is the one that receives the pull request. The trigger is safe by default because the workflow, and any later checkout that doesn't specify a `ref`, is taken from the base repository's default branch. A checkout fetches code onto the runner, and a `ref` says which commit. Then the sentence that locates the risk: "You introduce risk when a workflow author overrides this default to run the fork's code."

**[ANIMATION]** step: risk.3

And the sentence that locates the step. Quoting the reference: "The checkout step alone does not execute untrusted code… The vulnerability is completed by the next step that runs code checked out into the current working directory." The documentation gives this pattern a name and says it "has been the root cause of multiple supply-chain compromises".

**[ANIMATION]** say: The_token_is_read/write,_even_when_triggered_from_a_public_fork

The token isn't read-only here. The workflow syntax reference: under `pull_request_target` the token "is granted read/write repository permission, even when it is triggered from a public fork".

**[ANIMATION]** end

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

Read it with the question from the last video. Whose code runs? `make test` runs the Makefile of the pull request, so the contributor's. What can the job reach? A read-write token, and every repository and organization secret the workflow names. What an attacker achieves is whatever those credentials allow. There's the line from the opening: not the trigger, not the checkout, but the step after it.

**[ANIMATION]** cards: cards=A_build|An_install_step_with_lifecycle_scripts|A_test_runner|A_linter_that_loads_a_configuration_file_from_the_working_directory title="Run"_is_wider_than_it_looks id=wider

And the textbook widens one word. "Run" is wider than it looks. A build. An install step with lifecycle scripts. A test runner. A linter that loads a configuration file from the working directory. Each executes or is steered by files from the checkout.

**[ANIMATION]** cards: cards=Checking_out_the_pull_request's_head_or_merge_commit:through_a_ref_built_from_the_event|Pointing_the_checkout_at_the_fork:through_the_repository_input|Fetching_the_code_another_way_and_running_it:git_fetch,_gh_pr_checkout,_an_artifact title=The_shapes_to_look_for_in_review numbered=on id=shapes

**[ANIMATION]** step: shapes.3

**The shapes to look for in review,** from the same reference. Checking out the pull request's head or merge commit, through a `ref` built from the event. Pointing the checkout at the fork, through the `repository` input. Or fetching the code another way and running it: a `git fetch` of the pull request ref, `gh pr checkout`, or downloading an artifact built from it. An artifact is a set of files a job uploads for later download.

**[ANIMATION]** say: Not_unique_to_pull__request__target:_issue__comment_and_workflow__run_too

And the scope is wider than one trigger. The reference: such patterns "are also not unique to `pull_request_target`… an `issue_comment` or `workflow_run` workflow that fetches and runs a fork's pull request code is vulnerable in the same way." For `workflow_run`, remember from video 143: it's about the default branch, and it can read secrets even when the first workflow couldn't. Its privilege comes from its position, not from the run that triggered it.

**[ANIMATION]** end

**The fix, in order of preference.**

One. Don't use the trigger. The reference: "If the workflow does not need `pull_request_target`, update it to use a safer event where appropriate, such as `pull_request`." Most CI, the automated testing of each change, needs no secrets and no write token.

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

Two. If a privileged action is needed, such as a comment or a label, keep `pull_request_target` but never check out or run the pull request's code. Operate on metadata only, facts about the pull request, not its files, with the narrowest `permissions`. This is the case in which `pull_request_target` is the right trigger.

**[ANIMATION]** stores: boxes=unprivileged_pull__request_workflow:the_contributor's_code_runs_here|privileged_workflow__run_workflow:never_executes_that_code rows=1:A:builds_and_tests|1:A:uploads_its_result_as_an_artifact@hl|2:B:downloads_the_artifact@hl|2:B:reads_it_as_data:_PR_numbers,_a_code_coverage_text|3:B:comments_on_the_pull_request@ok arrows=2:A2>B1:artifact title=Separate_the_two id=split

**[ANIMATION]** step: split.3

Three. If the privileged action needs a result computed from the contributor's code, separate the two. GitHub Security Lab's design is an unprivileged `pull_request` workflow that builds and tests and uploads its result as an artifact, and a privileged `workflow_run` workflow that downloads the artifact and comments. Artifact data is safe there when it's used, in the article's words, "in a safe manner, like reading PR numbers or reading a code coverage text to comment on the PR".

**[ANIMATION]** end

A label as a gate, "run only when a maintainer adds a certain label", is weaker than it looks. The Security Lab article notes it's still prone to a race condition, in which the attacker may push new changes after the workflow was approved by the label but hasn't started yet.

**The platform now leans against the pattern.** Four changes matter in review, and the textbook is exact that none of them removes the need for review.

**[ON SCREEN]** The four-row table at the end of section 21A.5.

The eighth of December 2025: the workflow file for `pull_request_target` always comes from the default branch. What it doesn't cover: a vulnerable workflow that is on the default branch.

`actions/checkout` version 7, the eighteenth of June 2026, back-ported to older lines on the twentieth of July 2026: the action refuses to fetch a fork pull request's head or merge ref under `pull_request_target`, and under `workflow_run` started by a pull request event, unless `allow-unsafe-pr-checkout: true` is set. What it doesn't cover: a `git fetch` or `gh pr checkout` in a `run` step, and other events such as `issue_comment`.

Read-only caches for low-trust triggers, the twenty-sixth of June 2026: a privileged-trigger run can't write the default branch's cache. What it doesn't cover: restoring a cache that was already poisoned.

And workflow execution protections, generally available on the seventeenth of September 2026. GitHub announced that a default rule will block `pull_request_target` in public repositories from the second of November 2026 unless a maintainer allows it. Check the changelog on the day you watch this. What it doesn't cover: private and internal repositories.

One input deserves a sentence of its own. The changelog says the opt-out flag "is intentionally named to be easy to spot in code review and static analysis". The reference says: "Only do this after confirming the checked-out code is never executed." In a pull request, the line `allow-unsafe-pr-checkout: true` needs a written justification.

## MENTAL MODEL

**Analogy for the fork model.** A visitor may use the lobby computer, which has no access to the internal network.

It breaks in two places. By default a visitor who has been in the building once is waved through without a check from then on. And the lobby computer may be one of your own machines: a self-hosted runner.

**Analogy for the privileged trigger.** The front desk has a procedure for parcels from unknown senders: log the parcel, put a sticker on it, send a receipt. The procedure is safe because the desk never opens the parcel. The vulnerability is the day someone amends the procedure to "open the parcel and follow the instructions inside", while the clerk still holds the master key.

Where that breaks: the parcel can also influence the clerk without being opened. Its label is event text. That's the next video.

**[ANIMATION]** replay: risk

So carry two questions into every review of a privileged trigger. Does anything bring the stranger's files onto the runner? And does any later step execute or get steered by files in the working directory? If both answers are yes, the trigger is no longer safe, whatever the intentions were.

## DIAGRAM

Try it now, thirty seconds, on paper. Draw two columns, `pull_request` and `pull_request_target`, and four rows: where the workflow file is read from, the token, the secrets, the approval gate. Fill in both columns, and say each row out loud.

**[PAUSE]**

**[ANIMATION]** walk: columns=for_a_pull_request_from_a_fork,on:_pull__request,on:_pull__request__target rows=workflow_file_read_from:the_commit_the_event_refers_to_(the_pull_request_can_change_it):the_base_repository's_default_branch|checked_out_by_default:the_test_merge,_refs/pull/N/merge_(the_contributor's_code):the_base_repository's_default_branch_(NOT_the_contributor's_code)|GITHUB__TOKEN:read-only:read/write,_even_from_a_public_fork|secrets:none_(except_the_token):repository_and_organization_secrets|approval_gate:applies:does_not_apply:_it_always_runs|safe_when:it_needs_no_secret_and_no_write_token:it_never_checks_out,_fetches_or_runs_the_pull_request's_code marks=2.2:hl,3.3:hl,4.3:hl mono=off title=Two_lanes id=lanes say_6=The_vulnerability:_the_NEXT_step_that_runs_code_checked_out_into_the_working_directory

**[ANIMATION]** step: lanes.header

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

**[ANIMATION]** step: lanes.6

Now check your rows. The left lane gives the stranger's code no privilege. The right lane gives privilege and, by default, no stranger's code. The vulnerability is a workflow that takes the token and secrets from the right lane and the code from the left.

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

The lab calls this the wide scan: every expression, with its line number, to be classified by hand. An expression is the dollar-brace formula that Actions replaces with its value. In file 2, which line would tell you whether the stranger's code is brought onto the runner? You know the shape from the review table. Say it out loud.

**[PAUSE]**

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

Line 28 of file 2: a `ref` built from the head commit of the pull request. That's the first shape in the documentation's table: checking out the pull request's head. Under `pull_request_target`.

**[ANIMATION]** step: risk.3

Remember what the reference says about that line: the checkout step alone doesn't execute untrusted code. So the review isn't finished. You open the file and read what comes after the checkout, and ask of each step whether it runs or is steered by files in the working directory. That reading is yours to do in the lab. And you look for one more line near the checkout, the one that the changelog says is named to be spotted.

**[ANIMATION]** end

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

Exit status 1: no match. A reviewer who stops here reports that no script contains an expression. Why can that be wrong? Think about how a multi-line script is written in YAML, the format of workflow files. Make your prediction.

**[PAUSE]**

**Step 4: the lines of every multi-line script.**

<!-- snippet: ch21a/lab-29-1-inventory/08-run-blocks -->
```text
# The lines of every multi-line script (from "run: |" to the next step or job).
$ awk '/run: \|/ {inrun=1; next} /^ *- name:|^ *- uses:|^  [a-z-]*:$/ {inrun=0} inrun && /\$\{\{/ {print FILENAME ":" FNR ":" $0}' v*.yml
v1-issue-triage.yml:32:          echo "Labelled issue #${{ github.event.issue.number }}: ${{ github.event.issue.title }}" >> "$GITHUB_STEP_SUMMARY"
```
<!-- /snippet -->

The `awk` program, a small text-processing tool, prints expression lines that lie inside a block that starts with `run:` and a vertical bar. One line comes back, in file 1. The narrow scan missed it, because the expression isn't on the line that says `run:`. It's on the line after. This is the subject of the next video. For now the lesson is about method: a scan tells you where to look, and a scan that returns nothing tells you only what that scan can see.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Switching to `pull_request_target` so that fork pull requests get the secrets.** Root cause: that trigger gives the job the base repository's read-write token and secrets and is not subject to the approval gate; the textbook lists this advice as outdated and as the vulnerability class of this chapter.
2. **Treating the checkout of the pull request's head as the whole problem, or as no problem.** Root cause: the checkout alone executes nothing; the vulnerability is completed by the next step that runs code from the working directory.
3. **Thinking only of `make test` as "running code".** Root cause: a build, an install with lifecycle scripts, a test runner or a linter that loads a configuration file are all steered by files from the checkout.
4. **Relying on the approval gate.** Root cause: by default it covers first-time contributors only, and it does not apply to privileged triggers at all.
5. **Using a label as the gate for a privileged run.** Root cause: the contributor can push new changes after the label was added and before the workflow starts.

## PRODUCTION EXAMPLE

Now, out of the lab. The textbook's case was the hook: an open-source evaluation harness wants benchmark scores on contributor pull requests, and the scores need a provider API key. Under `pull_request` the key is absent, so the job fails for every outside contributor. The textbook's comment: this is the fork model working.

The wrong fix is the one-word change. The right ones, as the textbook lists them: run the keyed evaluation after merge. Or run it on demand, by a maintainer, on a branch inside the repository.

**[ANIMATION]** replay: split

Or split the work into an unprivileged run and a privileged follow-up that never executes the contributor's code, and that treats what the first run produced as data. It never executes it and never interpolates it into a script.

**[ANIMATION]** end

Each of the three costs something: later feedback, a manual step, or a second workflow to maintain. That cost is the price of not putting an outsider's code next to your credential.

## PRACTICE EXERCISE

Your turn. Do Lab 29.1, "Find and fix five planted weaknesses", in [`lab-manual/m29-actions-security.md`](../../lab-manual/m29-actions-security.md). Part A runs in `labs/shell` and needs no GitHub access.

Collect the evidence with the scans, then read each file completely. Before you change anything, write one row per file: the line, the class, what an attacker could achieve and under which condition, and the smallest fix. For the file with the privileged trigger, predict which step completes the vulnerability before you read below the checkout.

The challenge is Exercise 29.2, "The comment workflow", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q312: "Explain a "pwn request" without using the word. Which step completes the vulnerability?"

Read the question on screen. Say your answer out loud.

**[PAUSE]**

A strong answer describes the pattern in terms of the two lanes: which trigger, what that trigger gives the job, what the workflow then brings onto the runner, and what happens next. It quotes the idea that the checkout alone executes nothing and names the kind of step that does. It says what an attacker can reach and why the approval gate doesn't help. The follow-up notes that the checkout action has refused that checkout since version 7 and asks whether the pattern is closed. Answer from the "what it does not cover" column, and say what you still look for in review.

## RECAP

Let's land this.

You should now be able to say:

- Under `pull_request`, a fork's code runs with a read-only token and no secrets; the runner, readable data and restorable caches remain exposed.
- The approval gate covers first-time contributors by default and does not apply to privileged triggers.
- `pull_request_target` takes the workflow from the default branch and gives the job a read-write token and the repository's secrets.
- The vulnerability is completed by the step that runs code checked out from the pull request, and "run" includes builds, installs, tests and tools that read configuration from the working directory.
- The trigger is right for metadata-only work; GitHub announced that from 2 November 2026 a default rule blocks it in public repositories unless a maintainer allows it.

## HOMEWORK

Read sections 21A.4 and 21A.5 of [Chapter 21A](../../textbook/ch21a-actions-security.md).

Today you learned to read a privileged trigger in two lanes, and to point at the step that matters. Run the scans yourself in the lab shell. Next time: script injection through untrusted event fields. Until then, look at the state first and type second. See you in the next one.
