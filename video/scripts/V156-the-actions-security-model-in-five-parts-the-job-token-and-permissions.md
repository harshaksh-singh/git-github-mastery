# V156: The Actions security model in five parts, the job token, and permissions

- **Part.** 7: Security
- **Module.** 29
- **Planned minutes.** 22
- **Prerequisites.** V119, V155
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), sections 21A.1 to 21A.3
- **Demo scripts.** `labs/ch21a/lab-29-1-inventory.sh` (snippets `files`, `triggers`, `permissions`, `uses`, `secrets-and-tokens`), which reads the five files in `workflows/vulnerable/`; a short screen walkthrough of the practice repository's token setting

## HOOK

**[ON SCREEN]** The question from section 21A.1.

"A contributor we have never heard of opened a pull request on our public evaluation library. Eight hours later there were malicious versions of our package on the registry, published by our own release workflow. No password was stolen. How?"

That's the shape of a real incident of the eleventh of May 2026, and video 162 goes through it. Notice one thing: each step was documented behavior. A workflow trigger, the event that starts an automated run, that runs with the base repository's privileges. A checkout of the contributor's code. A cache, a directory one run stores for a later run, shared with the release job. A release job that could request a publishing identity, the credential it publishes the package with.

A CTO who asks "how?" doesn't want a list of settings. They want to know which line of which file gave an outsider code execution next to a credential, why the platform allowed it, what the smallest change is that closes it, and how you'll know it stays closed. A smaller puzzle for today: one workflow file, copied unchanged into a second repository, where one step now fails. Hold on to it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is Part 7: security. A word about what this part is and isn't.

It is defensive. The chapter says so in its second paragraph: it shows unsafe workflow patterns next to their fixes, at the level of detail GitHub's own security documentation uses, so that you can review and harden your team's workflows. It contains no working attack. The same holds for these videos.

And the evidence statement, as for Part 6. Nothing in this chapter was run on GitHub. The transcripts show plain Git and `grep`, a command that prints the matching lines of a file, on the course's workflow files. The five files in `workflows/vulnerable/` are teaching material with faults on purpose. They were assembled from documented syntax and parse-checked, and never executed. Never copy them into a real repository.

Five words before we start. A workflow is a file that says: when this event happens, run these jobs. A job is a list of steps on one fresh machine, the runner. A token is a credential: a string that stands for an account with a subset of its rights. A pull request proposes merging a branch into yours, and a fork is a second repository on GitHub, made from yours.

This first video gives you the model in five parts, and then takes the first part in full: the job token and the `permissions` key. The demonstration is an inventory: five files you've never seen, and four `grep` commands that tell you where to look.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- describe the security model of a workflow run in the five parts the section names;
- say what the job token can do when a workflow has no `permissions` key and what that depends on;
- write least-privilege `permissions` for a job;
- inventory the triggers, permissions, actions and secrets of a set of workflow files with local commands.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions. One line, large:

"Whose code runs in this job, on whose text does it operate, and what can the job reach?"

The textbook says the whole chapter reduces to that one question, asked of every job. If the answer to the first two parts is "somebody outside the team", and the answer to the third is anything other than "nothing", you've found a vulnerability, a weakness an outsider could use.

**In one sentence.** A workflow run is a program that GitHub starts on your behalf, with a credential for your repository in its pocket, and its safety depends on who controls the program's code and its inputs.

**Precisely: five parts.**

**[ON SCREEN]** The table of section 21A.2.

One. The job token. Each job receives a `GITHUB_TOKEN` limited to the workflow's repository, and the `permissions` key sets what it may do.

Two. Fork pull requests. A `pull_request` run from a fork gets a read-only token and no secrets, the encrypted values kept in GitHub's settings. By default only first-time contributors need approval.

Three. Privileged triggers. `pull_request_target`, and also `workflow_run` and `issue_comment`, run with the base repository's token and secrets. The base repository is the one that receives the pull request. These triggers are safe only while they don't run the fork's code.

Four. Expression injection. The dollar-brace expression, a formula that Actions replaces with its value, is substituted into the script text before the shell starts, so attacker-controlled fields become code.

Five. Third-party actions. An action is a packaged step: someone else's code inside your job. It runs with the job's token and secrets. A tag can be moved. Only a full commit ID is immutable.

The next videos take parts two to five one at a time. And one statement about layers: nothing in this model is a property of Git.

**[ANIMATION]** pin: A-B-C main; B tag:tag; HEAD=none; say:The_two_facts_Git_contributes => + C tag:tag; say:A_tag_is_a_ref_that_can_be_moved => + note:B:a_commit_ID_names_content_that_cannot_change; say:off at_state_1=8 at_state_2=40 at_state_3=72

Git contributes exactly two facts that the model relies on. A tag, a name for one commit, is a ref that can be moved. And a commit ID names content that can't change.

**The job token. In one sentence:** every job gets its own short-lived token for the repository that contains the workflow, and the `permissions` key decides what that token may do.

**Precisely.** The documentation: "At the start of each workflow job, GitHub automatically creates a unique `GITHUB_TOKEN` secret to use in your workflow." It's a GitHub App installation access token, and its permissions "are limited to the repository that contains your workflow". It expires when the job finishes. On GitHub-hosted runners it can live for a maximum of 6 hours.

**[ANIMATION]** layers: probe=GITHUB__TOKEN layers=the_default:repository_or_organization+read_and_write_for_all_permissions+or_read_for_contents_and_packages|the_workflow:top-level_permissions|the_job:permissions_under_the_job title=Three_layers_decide_what_the_token_may_do id=three say_1=The_setting_"Workflow_permissions":_for_a_workflow_with_no_permissions_key say_2=The_token_of_every_job_that_does_not_override_it say_3=The_token_of_that_job_only

**[ANIMATION]** step: three.1

What the token may do is decided in three layers.

The repository or organization default: the setting called "Workflow permissions". It decides what a workflow with no `permissions` key gets. There are two options, quoted from the documentation: "read and write access for all permissions", or read access for the `contents` and `packages` permissions only.

**[ANIMATION]** step: three.2

The workflow: the top-level `permissions` key sets the token of every job that doesn't override it.

**[ANIMATION]** step: three.3

The job: a `permissions` key under the job sets the token of that job only.

**[ANIMATION]** end

Three rules of the key carry most of the weight.

**[ANIMATION]** walk: columns=contents,issues,every_other_scope,all_that_the_file_says rows=read:none:none:permissions:_contents:_read|none:write:none:permissions:_issues:_write|none:none:none:permissions:_an_empty_map marks=1.1:ok,2.2:ok title=Name_one_scope,_and_the_rest_are_none id=rule

**[ANIMATION]** step: rule.1

Rule one, quoted: "If you specify the access for any of these permissions, all of those that are not specified are set to `none`." So writing `contents: read` also removes `issues`, `packages`, `pull-requests` and every other scope. A scope is one named area of access.

Quick quiz. A workflow's only permissions line is `issues: write`. Can its token read the repository's contents? A, yes. B, no. Your answer?

**[PAUSE]**

**[ANIMATION]** step: rule.2

B. Naming one scope sets every other one to none, reading contents included. Almost everyone expects A the first time.

**[ANIMATION]** step: rule.3

Rule two: `permissions` with an empty map removes everything. `read-all` and `write-all` are the two shorthands.

**[ANIMATION]** say: Each_scope_takes_read,_write_or_none;_write_includes_read

Rule three: the scopes. On the first of October 2026 the list has sixteen names, among them `actions`, `attestations`, `checks`, `contents`, `deployments`, `id-token`, `issues`, `packages`, `pull-requests`, `security-events` and `statuses`. Each takes `read`, `write` or `none`, and `write` includes `read`.

**[ON SCREEN]** Callout: Version note.

Older behavior: a workflow without a `permissions` key received a read-write token. Current behavior: the default is read-only for new repositories, organizations and enterprises. Since the second of February 2023, and the changelog adds: "this change will not impact any existing enterprises, organizations or repositories". Recommended: never rely on the default. Declare `permissions` at the top of every workflow, because a repository created before February 2023 may still have the permissive setting. The Nx project's post-mortem, its published account of the incident, names exactly this as one of three causes.

So the answer to "what can the token do when there is no `permissions` key?" is: it depends on a setting you can't see in the file, and on when the repository was created.

**[ON SCREEN]** The unsafe and the safe form, side by side.

```yaml
# Unsafe: every job, and every action in every job, can push, tag, release and edit issues.
permissions: write-all
```

```yaml
# Safe: read-only for the workflow; one job adds the one scope it needs.
permissions:
  contents: read

jobs:
  label:
    permissions:
      issues: write        # contents is now none for this job, which is fine: it checks nothing out
```

Read the comment in the second block. The job-level block replaces the workflow-level one, so `contents` is none for that job. That's correct here, because the job checks nothing out. GitHub's guidance says the same in prose: set the default permission to read access only for repository contents, and increase it as required for individual jobs. That practice is called least privilege: the smallest set of rights that does the job.

**[ANIMATION]** flow: actors=one_job,*the_repository,a_new_workflow_run subs=holds_GITHUB__TOKEN,-,- msgs=1>2:an_event_triggered_by_the_token|2>3:no_new_run:fail|2>3:workflow__dispatch:ok|2>3:repository__dispatch:ok|1>1:the_token_dies_with_the_job title=Two_limits_on_a_stolen_job_token id=limits at_5=88

**Two properties limit what a stolen job token can do.** First: events triggered by the `GITHUB_TOKEN` will not create a new workflow run, with `workflow_dispatch` and `repository_dispatch` as the documented exceptions. The textbook warns that the exception isn't academic: in the Nx incident a stolen read-write token was used to dispatch the publish workflow. Second: the token dies with the job.

**[ANIMATION]** gates: packet=GITHUB__TOKEN gates=the_job_starts:done:-:created,_unique_to_this_job|checkout:done:-:persisted_in_the_local_git_config|every_later_step:done:-:can_run_authenticated_git_commands|the_job_ends:stop:-:removed_during_post-job_cleanup title=The_life_of_a_job_token id=life result=the_token_dies_with_the_job

**Inside `.git`.** The token also reaches Git. The checkout action, which fetches the repository onto the runner, says in its README: "The auth token is persisted in the local git config. This enables your scripts to run authenticated git commands. The token is removed during post-job cleanup. Set `persist-credentials: false` to opt-out." Since version 6 of the action the credential is stored in a separate file under the runner's temporary directory. Either way, until the job ends, every later step and every process it starts can run authenticated Git commands against your repository with whatever `contents` permission the job has. A job that only builds and tests has no reason to leave it there.

## MENTAL MODEL

**[ANIMATION]** walk: columns=in_the_office,in_a_workflow_run rows=a_badge_from_the_front_desk:the_job_token|a_written_procedure:the_workflow_file|tools_bought_from_other_firms:actions|the_label_on_the_parcel:event_data title=A_contractor,_let_in_each_time_a_parcel_arrives mono=off id=office

**Analogy for the model,** from the textbook. A contractor is let into your office each time a parcel arrives. The front desk gives the contractor a badge, and the badge opens whatever doors the desk configured. The contractor follows a written procedure, which is the workflow file. Uses tools bought from other firms, which are actions. And reads the label on the parcel, which is event data.

**[ANIMATION]** cards: cards=The_badge_opens_too_many_doors|The_procedure_was_written_by_the_person_who_sent_the_parcel|The_contractor_reads_the_label_aloud_as_if_it_were_an_instruction numbered=on title=Three_things_can_go_wrong id=wrong

**[ANIMATION]** step: wrong.3

Three things can go wrong. The badge opens too many doors. The procedure was written by the person who sent the parcel. Or the contractor reads the label aloud as if it were an instruction.

**[ANIMATION]** say: The_contractor_executes_text_literally_and_instantly

The analogy breaks in one place that matters: this contractor executes text literally and instantly, so a label that contains an instruction is carried out before anyone can notice.

**[ANIMATION]** replay: life

**Analogy for the token.** A visitor badge printed at the start of each shift and shredded at the end. The desk can print it with access to one room or to the whole building.

**[ANIMATION]** say: Every_step_can_use_the_token._You_only_decide_what_it_can_do

It breaks because every tool the visitor picks up can use the badge without asking. The documentation: "An action can access the `GITHUB_TOKEN` through the `github.token` context even if the workflow does not explicitly pass the `GITHUB_TOKEN` to the action."

**[ANIMATION]** end

Put the two together and you have the reason for least privilege. You don't decide which steps use the token. Every step can. You only decide what the token can do.

## DIAGRAM

Try it now, thirty seconds, on paper. Draw a box for one job. On its left, write what only people with write access control. On its right, what an outsider can control. For each, who can write it? Say it out loud.

**[PAUSE]**

**[ANIMATION]** stores: boxes=TRUSTED:write_access_required|*one_job_on_one_runner:what_it_holds|UNTRUSTED:anyone_on_the_internet rows=1:B:GITHUB__TOKEN_(permissions)|1:B:secrets_named_in_the_job|1:B:OIDC_token_if_id-token|2:A:workflow_file_on_the_default_branch|2:A:secrets,_variables,_environments,_OIDC_trust|2:A:actions_pinned_to_a_full_commit_SHA|3:C:code_of_a_fork_pull_request,_if_checked_out_and_run@hl|4:C:event_text:_titles,_bodies,_branch_names,_labels,_commit_messages@hl|5:C:actions_referenced_by_tag_or_branch;_caches;_artifacts@hl arrows=2:A>B|3:C1>B|4:C2>B|5:C3>B id=trust title=Who_can_write_this? say_2=Controlled_by_people_with_write_access say_3=Anyone_who_can_open_a_pull_request_or_an_issue,_or_who_controls_a_dependency at_2=18 at_3=50 at_4=64 at_5=78

**[ANIMATION]** step: trust.1

**[DIAGRAM]** The picture of section 21A.2. Draw the job in the middle first, with what it holds. Then the three trusted boxes above it. Then the dashed line. Then the three untrusted boxes below, and for each one ask: who can write this?

```text
  TRUSTED (write access required)
  +----------------------------+   +---------------------------+   +--------------------+
  | workflow file on the       |   | secrets, variables,       |   | actions pinned to  |
  | default branch             |   | environments, OIDC trust  |   | a full commit SHA  |
  +-------------+--------------+   +-------------+-------------+   +---------+----------+
                |                                |                           |
                v                                v                           v
        +------------------------------- one job on one runner -------------------------------+
        |  GITHUB_TOKEN (permissions)   secrets named in the job   OIDC token if id-token     |
        +-------------------------------------------------------------------------------------+
                ^                                ^                           ^
  - - - - - - - | - - - - - - - - - - - - - - - -| - - - - - - - - - - - - - | - - - - - - - -
                |                                |                           |
  +-------------+--------------+   +-------------+-------------+   +---------+----------+
  | code of a fork pull        |   | event text: titles,       |   | actions referenced |
  | request, if checked out    |   | bodies, branch names,     |   | by tag or branch;  |
  | and run                    |   | labels, commit messages   |   | caches; artifacts  |
  +----------------------------+   +---------------------------+   +--------------------+
  UNTRUSTED (anyone who can open a pull request or an issue, or who controls a dependency)
```

First the job in the middle, with what it holds: the token with its permissions, the secrets named in the job, and an OIDC token if it has id-token.

**[DIAGRAM]** Trust flows downward. Everything above the dashed line is controlled by people with write access. Everything below it can be controlled by anyone on the internet. Each arrow from below is one of the next four videos.

**[ANIMATION]** step: trust.5

Compare with yours. Here the job stands in the middle, and trust flows in from one side only. On the left, people with write access. On the right, anyone on the internet. Each arrow from the right is one of the next four videos.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21a/lab-29-1-inventory`. Plain `ls` and `grep` on five workflow files. Nothing is executed and nothing touches GitHub. Every command reads.

Into the lab. These five files each have one planted weakness of a different documented class. In this video you don't look for the weaknesses. You take the inventory: for each file, the trigger, the permissions, the actions, and the secrets. That's the first half of the question on screen: what can the job reach, and what starts it?

**Step 1: what is there.**

```bash
ls v*.yml
grep -c '' v*.yml
```

<!-- snippet: ch21a/lab-29-1-inventory/01-files -->
```text
$ ls v*.yml
v1-issue-triage.yml
v2-pr-test-report.yml
v3-nightly-check.yml
v4-format-check.yml
v5-build-and-deploy.yml
$ grep -c '' v*.yml
v1-issue-triage.yml:32
v2-pr-test-report.yml:50
v3-nightly-check.yml:36
v4-format-check.yml:42
v5-build-and-deploy.yml:65
```
<!-- /snippet -->

Five files, between 32 and 65 lines. Small enough to read in full, which the lab insists on.

**Step 2: the triggers.**

```bash
grep -n -A3 '^on:' v*.yml
```

Five triggers will appear. Which kinds of event let an outsider start a run, and which of those run with the base repository's privileges? Say it out loud.

**[PAUSE]**

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

`issues`, opened. `pull_request_target`. `schedule` with a manual trigger. `pull_request`. `push` to `main`.

**[ANIMATION]** walk: columns=file,trigger,who_can_cause_the_event rows=v1-issue-triage.yml:issues,_opened:anyone_can_open_an_issue|v2-pr-test-report.yml:pull__request__target:anyone_can_open_a_pull_request|v4-format-check.yml:pull__request:anyone_can_open_a_pull_request|v5-build-and-deploy.yml:push_to_main:write_access|v3-nightly-check.yml:workflow__dispatch:write_access|v3-nightly-check.yml:schedule:nobody marks=1.3:hl,2.3:hl,3.3:hl title=Where_an_outsider's_input_can_arrive id=who

Sort them by who can cause the event. Anyone can open an issue. Anyone can open a pull request. A push to `main` and a manual run need write access, and a schedule needs nobody. And one of the two pull request triggers is the privileged one. You haven't found a weakness yet. You've found where an outsider's input can arrive.

**Step 3: the permissions.**

```bash
grep -n -A2 '^permissions:' v*.yml
```

Apply rule one to each block before you read on. For each file, which scopes does the token have, and which are none? Make your prediction.

**[PAUSE]**

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

File 1: `issues: write`, and therefore nothing else, not even reading contents. File 2: read contents, write pull requests. File 3: `write-all`, on one line. Files 4 and 5: read contents. Every file declares the key, so none of them depends on the repository's default setting. Whether each declaration is the least the job needs is the lab's question.

**Step 4: the actions.**

```bash
grep -n 'uses:' v*.yml
```

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

Twelve references. Read down the part after the at sign. Eleven are 40-character commit IDs with a version comment. One line is different. Part five of the model tells you why that matters, and video 159 is about it.

**Step 5: secrets and tokens.**

```bash
grep -n 'secrets\.\|github\.token' v*.yml
```

<!-- snippet: ch21a/lab-29-1-inventory/05-secrets-and-tokens -->
```text
$ grep -n 'secrets\.\|github\.token' v*.yml
v1-issue-triage.yml:25:          GH_TOKEN: ${{ github.token }}
v2-pr-test-report.yml:45:          GH_TOKEN: ${{ github.token }}
v5-build-and-deploy.yml:19:  DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
```
<!-- /snippet -->

Three lines. Two files hand the job token to a step through `env`, its environment variables, for the GitHub CLI. One file names a deployment secret, and look at the line number: 19, near the top of the file, before any job. Ask where in a file an `env` entry applies, and therefore which jobs and steps can read that secret. Hold that question for video 160.

**[ANIMATION]** walk: columns=file,trigger,uses,token_or_secret,permissions rows=v1-issue-triage.yml:issues:none:github.token:issues:_write|v2-pr-test-report.yml:pull__request__target:2:github.token:contents:_read,_pull-requests:_write|v3-nightly-check.yml:schedule,_workflow__dispatch:2:none:write-all|v4-format-check.yml:pull__request:3:none:contents:_read|v5-build-and-deploy.yml:push_to_main:5:secrets.STAGING__DEPLOY__TOKEN:contents:_read title=Five_rows,_four_columns:_where_to_read id=inventory pace=quick

You now have a table with five rows and four columns, made in one minute. It tells you where to read. It doesn't tell you what is wrong. The lab manual says so in those words.

**[ON SCREEN]** Lower third: GitHub. A short screen walkthrough.

**On your own practice repository.** The interface changes. The documentation linked from section 21A.3 is the reference, and no GitHub output was captured by the authors. Lab 29.1 itself needs no GitHub access for its main part. This is one look that belongs to this video.

**[ANIMATION]** replay: three

**[ANIMATION]** step: three.1

Open the repository's settings for Actions and find the setting the documentation calls "Workflow permissions". Read which of the two options is selected: read and write for all permissions, or read for contents and packages. Don't change anything. Changing a setting is a decision, and this is an inspection. Then say aloud what a workflow without a `permissions` key would get in this repository, and why none of the course workflows depends on that answer.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Relying on the default token permissions.** Root cause: the default is a repository or organization setting, read-only only for repositories created since the second of February 2023; the file does not show it.
2. **Adding one permission and breaking another step.** Root cause: when any permission is specified, all unspecified ones are set to none.
3. **`permissions: write-all` "to make it work".** Root cause: every job, and every action in every job, can then push, tag, release and edit issues.
4. **Assuming an action cannot use the token because the workflow did not pass it.** Root cause: an action can read the token through the `github.token` context.
5. **Leaving the checkout credential in place in a job that only builds and tests.** Root cause: until the job ends, every later step can run authenticated Git commands with the job's `contents` permission.

## PRODUCTION EXAMPLE

**[ANIMATION]** stores: boxes=repository_created_in_2021:the_old_one|repository_created_last_month:the_new_one rows=1:A:a_workflow_with_no_permissions_key|1:B:the_same_workflow,_copied|1:A:the_step_creates_a_release@ok|1:B:the_step_fails_for_lack_of_permission@bad|2:A:"Workflow_permissions":_permissive@hl|2:B:"Workflow_permissions":_restrictive@hl|3:A:read-write_tokens_for_years,_in_every_job,_for_every_action@bad|4:A:permissions:_contents:_read_at_the_top@ok|4:B:permissions:_contents:_read_at_the_top@ok|4:A:one_write_scope_for_the_job_that_creates_the_release@ok|4:B:one_write_scope_for_the_job_that_creates_the_release@ok arrows=1:A1>B1:copied_unchanged title=One_workflow_file,_two_repositories id=puzzle say_2=What_differs_is_the_setting_behind_them say_4=Now_the_files_say_what_the_tokens_can_do

**[ANIMATION]** step: puzzle.1

Now, out of the lab. A team that maintains an evaluation library has a repository created in 2021. Its workflows have no `permissions` key, because "the default is read-only now". A new engineer copies one of those workflows into a repository created last month, where it behaves differently: a step that used to create a release fails for lack of permission.

**[ANIMATION]** step: puzzle.3

Nothing in the two files differs. There's the puzzle from the opening. What differs is the "Workflow permissions" setting behind them: permissive in the old repository, restrictive in the new one. The engineer has found, by accident, that the old repository's workflows have been running with read-write tokens for years, in every job, for every action.

**[ANIMATION]** step: puzzle.4

The fix isn't to switch the new repository to the permissive option. It's to declare `permissions: contents: read` at the top of every workflow in both repositories, and to add the one write scope to the one job that creates the release. After that, the two repositories behave the same, and the files say what the tokens can do.

## PRACTICE EXERCISE

Your turn. Do Exercise 29.1, "Whose code, whose text, what can it reach?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

For each job in the exercise, answer the three parts of the question in writing before you judge anything: whose code, whose text, what it can reach. Predict which jobs will have "somebody outside the team" in one of the first two answers.

The challenge is Exercise 29.5, "What can this token do?", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q306: "A workflow has no `permissions` key. What can its token do, and what does the answer depend on?"

Read the question on screen. Say your answer out loud.

**[PAUSE]**

A strong answer refuses to give one answer and explains why: it names the setting that decides, the two options that setting has, and the date and scope of the change of default. It says what the token is limited to in any case, and how long it lives. Then it gives the recommendation and its reason. The follow-up adds `contents: read` at the top and a labeling job starts failing with a "not accessible" message. Explain it with rule one, and give the smallest correct change, at the right level of the file.

## RECAP

Let's land this.

You should now be able to say:

- The question for every job: whose code runs, on whose text does it operate, and what can the job reach?
- The model has five parts: the job token, fork pull requests, privileged triggers, expression injection, third-party actions.
- The job token is created per job, limited to the workflow's repository, and expires with the job.
- Without a `permissions` key the token's scope depends on a repository or organization setting; naming any scope sets all others to none.
- Declare `permissions: contents: read` at the top of every workflow and add scopes per job.

## HOMEWORK

Read sections 21A.1 to 21A.3 of [Chapter 21A](../../textbook/ch21a-actions-security.md).

Today you read five unfamiliar workflow files and knew where to look. Try that inventory in the lab. Next time: fork pull requests, the approval gate, and privileged triggers. Until then, look at the state first and type second. See you in the next one.
