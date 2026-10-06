# V148: Workflows 6, 7 and 10, action versions and the Node 24 runtime, and the syntax added in 2025 and 2026

- **Part.** 6: CI/CD with GitHub Actions
- **Modules.** 26 and 27
- **Planned minutes.** 24
- **Prerequisites.** V147
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), section 20A.13 (workflows 6, 7 and 10) and sections 20A.14 to 20A.18
- **Demo scripts.** `labs/ch20a/lab-26-6-image-tags.sh`, `labs/ch20a/lab-26-7-artifact.sh`; the files [`06-docker-image.yml`](../../workflows/06-docker-image.yml), [`07-artifact.yml`](../../workflows/07-artifact.yml), [`10-matrix.yml`](../../workflows/10-matrix.yml) and [`ACTION_PINS.md`](../../workflows/ACTION_PINS.md); screen walkthroughs of Labs 26.6 and 26.7 in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md)

## HOOK

**[ON SCREEN]** One line of YAML: `uses: actions/checkout@v4`.

That line is in many older workflow files, and it has worked for years. A workflow is a file that tells GitHub Actions which jobs to run when an event happens, and this line asks for an action, a packaged step written by someone else. Two questions about it.

**[ANIMATION]** pin: id=pin A-B-C main; B tag:v4; HEAD=none; title:actions/checkout:_someone_else's_repository; say:v4_names_a_tag,_and_a_tag_names_one_commit => + C tag:v4; name:moved; say:Whoever_controls_the_repository_can_move_the_tag => + note:B:a_40-character_commit_ID_still_names_this_commit; name:pinned; say:A_full_commit_ID_cannot_be_made_to_name_different_content at_moved=62

**[ANIMATION]** step: moved

First: what does `v4` name? It names a tag in someone else's repository. A tag is a name for one commit that isn't expected to move. But a tag can be moved by whoever controls that repository. So the code your job runs tomorrow is whatever that tag points at tomorrow.

**[ANIMATION]** cards: id=node question=Since_23_September_2026,_Node_24_is_the_only_JavaScript_action_runtime cards=an_older_major_declares_Node_20|it_is_not_rejected|it_is_executed_on_Node_24:a_configuration_its_authors_did_not_test marks=3:ring at_1=45 at_2=58 at_3=70 at_marks=90

**[ANIMATION]** step: marks

Second: since the twenty-third of September 2026, Node 24 is the only JavaScript action runtime on github.com runners. The runtime is the program that executes an action's code. An older major version of an action that declares Node 20 isn't rejected. According to the runner's source it's executed on Node 24, a configuration its authors didn't test.

So that one line now runs code you didn't choose on a runtime its authors didn't test, and it still shows green. This video is about taking control of both. Before the end, you'll see that line rewritten the way the course writes it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you read workflows 1 to 5. This one finishes the set of Chapter 20A with three files. Workflow 6 builds a container image, an application packaged with what it needs to run, and pushes it to the GitHub container registry. Workflow 7 creates an artifact, a set of files that a job uploads to GitHub, in one job and consumes it in the next. And workflow 10 is the matrix, which you counted in video 146.

Then two sections that keep your knowledge current. Action versions and the Node 24 runtime: which versions the course pins, and the behavior change each brought. And the syntax added in 2025 and 2026: keys that a file written this year can contain and that no older course mentions.

One production note for this video in particular. Action versions are re-verified on the day of each lesson. Every version I say is read from `workflows/ACTION_PINS.md` on screen. That file states when its pins were read: on the first of October 2026, with an anonymous `git ls-remote`. If you watch this later, the file in your copy of the course is the authority, and the method to re-verify a pin yourself is in it.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- explain every line of the image, artifact and matrix workflows;
- say which tags the image workflow gives an image and what each identifies;
- explain why actions are pinned by a 40-character commit ID and how the pin is kept current;
- state what the Node 24 change means for old action versions, as the section gives it;
- name the syntax additions of 2025 and 2026 that the section lists.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions. `06-docker-image.yml`, full screen.

**Workflow 6: build and push an image.** Read it in order.

Trigger: pushes to `main`, pushes of tags that match `v*`, and pull requests. Three different events will give three different sets of image tags. Hold that thought.

**[ANIMATION]** layers: id=perm layers=workflow_level:contents:_read|the_job_that_pushes:contents:_read+packages:_write winner=2 rule=the_job's_token title=A_job-level_permissions_block_replaces_the_workflow-level_one at_1=3 at_2=20 at_result=55

Permissions: at workflow level, `contents: read`. Then the one job that pushes has its own block: `contents: read` and `packages: write`. Why is `contents: read` repeated? Because a job-level `permissions` block replaces the workflow-level one for that job. If you wrote only `packages: write` there, the job couldn't read the repository.

**[ANIMATION]** end

Workflow-level `env`: the registry, `ghcr.io`, and the image name from `github.repository`, which is owner and name. The metadata action lowercases image names, which a registry requires.

**[ANIMATION]** gates: id=pr6 packet=a_pull__request gates=Checkout:pass|Buildx_setup:pass|Login:skip:-:only_when_the_event_is_not_pull__request|Tags_and_labels:pass|Build:pass:-:push_is_false|Job_summary:pass result=built,_never_pushed title=Workflow_6_on_a_pull_request,_by_the_file at_1=5 at_2=12 at_3=20

**[ANIMATION]** step: 3

The steps. Checkout, with `persist-credentials: false`. Buildx setup. Then the login step, with an `if`: it runs only when the event isn't `pull_request`. It logs in with the job token. GitHub's guide recommends the token over a personal access token, and states that a package published this way inherits the visibility and permissions of the repository. So on pull requests the image is built, but the job never logs in and never pushes.

**[ANIMATION]** walk: id=rules columns=rule,gives rows=type=ref,event=branch:the_branch_name,_for_example_main|type=ref,event=pr:pr-_and_the_number|type=semver:0.2.0_for_a_Git_tag_v0.2.0|type=sha:sha-_plus_the_short_commit_ID|the_default_flavor:a_semver_tag_also_produces_latest title=Tags_computed_from_Git_facts at_1=22 at_2=38 at_3=52 at_4=70 at_5=84

The next step computes tags and labels from Git facts. Four rules, each from the action's README. `type=ref,event=branch` gives the branch name, for example `main`. `type=ref,event=pr` gives `pr-` and the number. `type=semver` with the version pattern gives `0.2.0` for a Git tag `v0.2.0`. `type=sha` gives `sha-` plus the short commit ID. And with the default flavor, a semver tag also produces `latest`.

**[ANIMATION]** step: pr6.5

The build step: `context: .` builds from the checked-out workspace. The textbook explains why the dot matters: without it the action builds from the Git context, which skips the checkout and ignores local file changes. `push` is an expression that is false on pull requests. And the two cache lines with `type=gha` store BuildKit layers in the Actions cache, subject to the scope and eviction rules you learned in video 146.

**[ANIMATION]** step: pr6.result

The last step writes the digest and the tags into the job summary.

**[ANIMATION]** end

And the verification statement for this file: the Dockerfile wasn't built by the author. The lab says it more directly: your run is the first build of that Dockerfile anywhere. If the build step fails, read which Dockerfile instruction the log names and fix it on the branch.

**[ON SCREEN]** `07-artifact.yml`.

**Workflow 7: create an artifact and consume it.** Trigger: pushes to `main`, and manual runs. Permissions: read.

**[ANIMATION]** run: id=w7 event=push jobs=build|deploy-simulated:build artifact=build>deploy-simulated:inventory-api-dist title=Workflow_7:_create_an_artifact_and_consume_it at_jobs=10

**[ANIMATION]** step: jobs

The `build` job runs `uv build` and uploads `dist/` under the name `inventory-api-dist`, with seven days of retention. `if-no-files-found: error` turns an empty `dist` into a failure at the upload, not a mystery at the download. The upload step has an ID, and its artifact ID and digest become job outputs.

**[ANIMATION]** step: data

The second job, "Simulated deployment", waits for `build`. It's a new machine. So it checks out the repository again, to get `scripts/deploy.sh`, and downloads the artifact by name into `dist`. A single artifact is extracted directly into the path. Version 8 of the download action compares the digest and fails on a mismatch. Then it prints the ID, the digest and the directory listing, and runs the deployment script, which lists exactly the downloaded files and changes nothing anywhere.

**[ANIMATION]** say: The_files_that_were_tested_are_the_files_that_are_deployed

This file is the textbook's bold sentence turned into YAML: the files that were tested are the files that are deployed.

**[ANIMATION]** end

**Workflow 10: the matrix.** You know it from video 146. Six jobs, one of them experimental. The job name is built from the matrix values, the runner is chosen per combination, and `continue-on-error` lets the Python 3.14 job fail without failing the run. The last job, "All matrix tests", is the pattern to remember: a ruleset that requires it needs no edit when a Python version is added.

**Action versions and Node 24.**

**[ON SCREEN]** `workflows/ACTION_PINS.md`, then the table of section 20A.14.

A JavaScript action declares its runtime in its `action.yml`. Node 24 is the only JavaScript action runtime on github.com runners since the twenty-third of September 2026. Older majors that declare Node 20 aren't rejected. According to the runner's source they're executed on Node 24, a configuration their authors didn't test. The rule for a workflow author is to use the Node 24 majors.

Reading from the pin file and the table. `actions/checkout`, pinned at v7.0.1: version 6 moved the persisted credential under the runner's temporary directory, and version 7 refuses fork pull request checkouts under `pull_request_target` and `workflow_run`. `actions/setup-python` at v7.0.0: Node 24. The release notes and the README disagree about whether the `pip-install` input was removed, and the course doesn't use it. `actions/setup-java` at v6.0.1: `distribution` stays required, and downloaded JDKs are verified against vendor checksums.

`actions/cache` at v6.1.0: it handles read-only cache access, and versions before v4.2.0 and v3.4.0 fail since the cache service was rewritten in February 2025. The artifact actions at v7.0.1 and v8.0.1: immutable artifacts since version 4, and the digest check on download in version 8. `astral-sh/setup-uv` at v10.2.0: there is no floating major tag since version 8, so `@v10` doesn't exist. You pin a full version or a commit. And the four Docker actions at the Node 24 majors released in March 2026.

Runner images move too. On the first of October 2026 `ubuntu-latest` is Ubuntu 24.04, and GitHub has announced that it migrates to Ubuntu 26.04 between the nineteenth of October and the nineteenth of November 2026. Check the changelog on the day you watch this. The course workflows say `ubuntu-24.04` and `macos-15`, so that, in the textbook's words, a change of image is a commit you make and not a date you discover.

**[ANIMATION]** step: pin.pinned

**Why a commit ID, and how it stays current.** The pin file gives the reason in one sentence: a tag can be moved by whoever controls the action's repository. A full commit ID can't be made to name different content. Part 7 has a whole video on what happens when a tag moves.

A pin is written as the action, an at sign, the 40-character ID, and the version as a trailing comment. That's the line from the opening, rewritten. To re-verify one yourself, the file gives the command, which needs no login:

```bash
git ls-remote --tags https://github.com/actions/checkout 'refs/tags/v7.0.1*'
```

It reads from a remote and changes nothing locally. If the tag is annotated you see two lines, and the one ending in `^{}` is the commit. If it's lightweight you see one line.

Try it now. Thirty seconds, and nothing to run. Open `workflows/ACTION_PINS.md` in your copy of the course and find the pin for `actions/checkout`. Which version does the comment name, and how long is the ID?

**[PAUSE]**

The comment names v7.0.1, and the ID is 40 characters long: a full commit ID, not a tag.

And keeping pins current: pins go stale on purpose. Nothing changes until you change it. The file's recommendation is to let Dependabot, GitHub's update service, propose updates through the `github-actions` ecosystem in its configuration file. It updates the ID and the version comment together.

**Syntax added in 2025 and 2026.** The core model hasn't changed, but you must be able to read these.

**[ON SCREEN]** The table of section 20A.15, row by row.

The eighteenth of September 2025: YAML anchors and aliases. The fourth of December 2025: 25 inputs for `workflow_dispatch`, up from 10. The twenty-ninth of January 2026: the `case()` function, replacing the "and, or" idiom. The nineteenth of March 2026: a `timezone` next to `cron`, and `environment` with `deployment: false`. The second of April 2026: `entrypoint` and `command` for service containers. The seventh of May 2026: `concurrency.queue: max`, with up to 100 pending runs per group.

The twenty-fifth of June 2026: parallel steps, with the keys `background`, `wait`, `wait-all`, `cancel` and `parallel`. The thirtieth of July 2026: `uses` with a dollar sign and a path, meaning the same repository at the running commit, without a checkout. That one is for github.com only, with runner 2.336.0 or later. The third of September 2026: the `vulnerability-alerts` permission and new `job.workflow` context fields. The tenth of September 2026: `cache-mode` at workflow or job level.

None of the eight course workflows needs these keys, and the course didn't add them for show. One of them changes a statement from video 142 in a controlled way: steps with `background: true` don't run in order.

**[ON SCREEN]** Callout: Unverified. A workflow-level dependency lock announced in GitHub's 2026 security roadmap does not appear in the syntax reference as of 1 October 2026. Do not write it.

One caution, on screen now, and marked unverified. A workflow-level dependency lock was announced in GitHub's 2026 security roadmap. As of the first of October 2026 it doesn't appear in the syntax reference. Don't write it.

## MENTAL MODEL

A picture helps.

**[ANIMATION]** stores: id=pf boxes=pinned:changes_only_when_you_make_a_commit|floating:changes_on_a_date_you_don't_control rows=1:A:the_actions:_by_commit_ID|2:A:the_runner_image:_ubuntu-24.04|3:A:the_Python_version:_stated_and_quoted|4:B:the_base_image_in_the_Dockerfile|4:B:the_packages_on_the_runner_image|4:B:the_registry title=Pinned_or_floating? at_1=18 at_2=30 at_3=45 at_4=60

**[ANIMATION]** step: boxes

Think of everything a workflow depends on as either pinned or floating.

Pinned means: it changes only when you make a commit. Floating means: it changes on a date you don't control.

**[ANIMATION]** step: 4

Go through workflow 6 with that question. The actions: pinned, by commit ID. The runner image: pinned, by the label `ubuntu-24.04`. The Python version, in the other files: stated and quoted. What is left? The base image in the Dockerfile, the packages on the runner image, the registry. Some things always float. The discipline is to know which, and to keep the list short.

**[ANIMATION]** end

The same question applies to what the workflow produces. An image tag is a name, and names differ in whether they move.

Quick quiz. Three image tags: `main`, `latest`, and `sha-` plus the short commit ID. Which one would you write into a deployment record? A, `main`. B, `latest`. C, the `sha-` tag. Your answer?

**[PAUSE]**

C, the one that names a commit. `main` moves on every push to `main`, and `latest` moves too. If you said `latest`, that's a common habit, and the diagram shows why to drop it.

Where this model breaks: "pinned" doesn't mean "safe" or "current". A pin to a commit with a known problem stays on that commit until someone moves it. That's why the pin file says pins go stale on purpose, and why something has to propose updates.

## DIAGRAM

**[ANIMATION]** walk: id=names columns=tag_on_the_image,what_it_names,does_it_move? rows=sha-<short_commit_ID>:one_commit:does_not_move|main:a_branch_tip:MOVES_on_every_push_to_main|0.2.0:a_version,_from_the_Git_tag_v0.2.0:-|latest:added_with_a_semver_tag_by_the_default_flavor:MOVES|pr-<N>:computed_on_a_pull_request:nothing_is_pushed marks=1.3:ok,2.3:bad,4.3:bad,5.3:dim mono=off title=One_image_in_ghcr.io,_identified_by_its_digest_(sha256)



**[DIAGRAM]** One image in the middle, identified by its digest. Draw the tags as labels on it, one at a time, and for each draw an arrow to what it names. Ask for each: does this name move?

```text
                                   +--------------------------------------+
                                   |  one image in ghcr.io                |
                                   |  identified by its digest (sha256)   |
                                   +--------------------------------------+
                                      ^        ^         ^          ^
   tag on the image                   |        |         |          |
   --------------------------------   |        |         |          |
   sha-<short commit ID>  ------------+        |         |          |    names one commit; does not move
   main                   ---------------------+         |          |    names a branch tip; MOVES on
                                                         |          |    every push to main
   0.2.0                  -------------------------------+          |    names a version, from the Git
                                                                    |    tag v0.2.0
   latest                 ------------------------------------------+    added with a semver tag by the
                                                                         default flavor; MOVES

   on a pull request:  pr-<N>  is computed, and nothing is pushed
```

**[ANIMATION]** step: header

Four names on one image. Ask of each one: does this name move?

**[ANIMATION]** step: 5

The `sha-` tag names one commit, and doesn't move. `main` names a branch tip, and moves on every push to `main`. `0.2.0` names a version, from the Git tag. `latest` comes along with a semver tag, and it moves. On a pull request, `pr-` and the number is computed, and nothing is pushed.

**[DIAGRAM]** Which tag would you write into a deployment record? The one that names a commit. And beneath every tag is the digest, which the next video uses.

## LIVE TERMINAL DEMO

Into the lab.

**[TERMINAL]** Replay with `labs/run ch20a/lab-26-6-image-tags`. It shows the Git facts from which the metadata step computes image tags. Nothing is built and nothing is pushed to a registry.

**Step 1: the inputs for a push to `main`.**

```bash
git branch --show-current
git rev-parse --short=7 HEAD
```

From these two values and the four tag rules, predict the image tags of a push to `main`. Write them down.

**[PAUSE]**

**Step 2: a version tag.**

```bash
git tag -a v0.2.0 -m "inventory-api 0.2.0"
git push origin v0.2.0
git ls-remote --tags origin
git for-each-ref --format="%(refname) %(objecttype)" refs/tags
```

`git tag -a` is 🟢 SAFE: it adds an object and a ref. `git push origin v0.2.0` is 🟡 CAUTION, and section 20A.18 says exactly why in this context: it creates a tag on GitHub and starts every workflow with a matching tag filter, here an image push. The preview is `git ls-remote --tags origin`. And the recovery line is a warning: deleting the tag doesn't unpublish the image.

<!-- snippet: ch20a/lab-26-6-image-tags/01-inputs -->
```text
$ git branch --show-current
main
$ git rev-parse --short=7 HEAD
6fe5455
$ git tag -a v0.2.0 -m "inventory-api 0.2.0"
$ git push origin v0.2.0
To ../../hub/inventory-api.git
 * [new tag]         v0.2.0 -> v0.2.0
$ git ls-remote --tags origin
192d2bc34d491d9b35cc1c00e50dde959dd9df55	refs/tags/v0.1.0
ae299cbfba5ad3d9388d3dded0eeee37b09946aa	refs/tags/v0.1.0^{}
21ea2601b402ac0121b4b87c37b464dd1d01390b	refs/tags/v0.2.0
6fe5455926c26261fe2c73104018ca2d96fdb554	refs/tags/v0.2.0^{}
$ git for-each-ref --format="%(refname) %(objecttype)" refs/tags
refs/tags/v0.1.0 tag
refs/tags/v0.2.0 tag
```
<!-- /snippet -->

The branch is `main` and the short ID is `6fe5455`. So for the push to `main`: the tag `main` and the tag `sha-6fe5455`.

**[ANIMATION]** graph: id=tags ae299cb-6fe5455 main; ae299cb atag:v0.1.0#192d2bc; 6fe5455 atag:v0.2.0#21ea260; HEAD=main; say:Two_annotated_tags:_each_ref_names_a_tag_object,_and_the_^{}_line_names_the_commit dx=320

After the tag push the server lists `v0.2.0` twice: the tag object, and the line ending in `^{}`, which is the commit it points at, `6fe5455` again. Both tags are annotated: the object type is `tag`.

**[ANIMATION]** end

Now predict for the tag push. Which workflows of the course have a tag filter that matches? And which image tags appear? Use the semver rule, the sha rule, and the remark about the default flavor. Say it out loud.

**[PAUSE]**

**[ANIMATION]** walk: id=out columns=event,image_tags,by_which_rule rows=push_to_main:main,_sha-6fe5455:branch,_sha|push_of_the_tag_v0.2.0:0.2.0,_sha-6fe5455,_latest:semver,_sha,_default_flavor title=Derived_from_the_documentation,_not_executed at_1=5 at_2=40

By the rules: workflows 3 and 6 both filter on tags that match `v*`, so both start. And the image gets `0.2.0` from the semver rule, `sha-6fe5455` from the sha rule, and `latest` from the default flavor. That's derived from the documentation, and Lab 26.6 is where you check it.

**[ANIMATION]** end

**Step 3: the artifact, consumed.** Replay `labs/run ch20a/lab-26-7-artifact`. You saw it in video 146. Look at it now as the last step of workflow 7.

<!-- snippet: ch20a/lab-26-7-artifact/01-deploy -->
```text
$ mkdir dist
$ touch dist/inventory_api-0.1.0.tar.gz dist/inventory_api-0.1.0-py3-none-any.whl
$ bash scripts/deploy.sh staging dist
Simulated deployment of inventory-api
  environment : staging
  target      : https://staging.inventory.example.com
  commit      : unknown
  ref         : local
  artifacts   :
    - inventory_api-0.1.0-py3-none-any.whl
    - inventory_api-0.1.0.tar.gz
Nothing was changed anywhere. A real script would now upload the artifacts to https://staging.inventory.example.com.
[exit status: 0]
```
<!-- /snippet -->

On a runner, the commit and the ref lines would carry the run's values, and the two files would be the ones the download step placed there.

<!-- snippet: ch20a/lab-26-7-artifact/02-failures -->
```text
# The artifact did not arrive: the directory is empty.
$ mkdir empty
$ bash scripts/deploy.sh staging empty
Simulated deployment of inventory-api
  environment : staging
  target      : https://staging.inventory.example.com
  commit      : unknown
  ref         : local
deploy.sh: no build outputs in 'empty'; nothing to deploy
[exit status: 1]
# A misspelled environment name:
$ bash scripts/deploy.sh stagging dist
deploy.sh: unknown environment 'stagging' (expected staging or production)
[exit status: 2]
```
<!-- /snippet -->

Two guards in the script, two in the workflow. The script refuses an empty directory and an unknown environment. The workflow refuses an empty upload with `if-no-files-found: error`, and the download action refuses a digest mismatch.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthroughs.

On your practice repository, in your normal shell. The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

Lab 26.6. Add workflow 6 on a branch and open a pull request. Don't merge yet. Predict: is the login step executed, is anything pushed, and which tags does the metadata step produce for a pull request? Then open the run and look at the login step's status, and at the job summary for the tags. After merging, read the run for the push to `main`, and compare the tags with your prediction from the two Git values. Then push the version tag, list the runs, and see which workflows started. Find the package on your organization's page and look at its list of tags.

Lab 26.7. Add workflow 7, and after the run, open the run's summary page and find the artifact with its name, and the place where its digest is shown. In the second job's log, compare the digest that was printed with it. Then start one run by hand: `gh workflow run` is 🟡 CAUTION, since it starts a run that uses minutes and may deploy if the workflow deploys. This one only simulates.

## COMMON MISTAKES

Five mistakes to watch for.

1. **A job-level `permissions` block that names only the extra permission.** Root cause: the job-level block replaces the workflow-level one, so every permission not named becomes none, including `contents: read`.
2. **Writing `@v10` for `astral-sh/setup-uv`.** Root cause: that action has no floating major tag since version 8.
3. **Deploying by the image tag `main` or `latest`.** Root cause: both are names that move; they do not identify what was tested.
4. **Deleting a Git tag to undo a release.** Root cause: the tag push already started the workflows with a matching filter, and deleting the tag does not unpublish the image.
5. **Leaving an old action major in place because the run is green.** Root cause: an action that declares Node 20 is executed on Node 24, a configuration its authors did not test.

## PRODUCTION EXAMPLE

**[ANIMATION]** gates: id=autumn packet=a_release_workflow_written_in_2024 gates=23_September:done:-:Node_20_stops_being_available|19_October_to_19_November:wait:-:ubuntu-latest_migrates,_as_announced result=nothing_to_bisect title=Autumn_2026:_neither_is_a_commit_to_the_repository at_1=55 at_2=80

**[ANIMATION]** step: 2

Now, out of the lab. A team that serves models has a release workflow written in 2024. It references actions by major tag and runs on `ubuntu-latest`. In the autumn of 2026 two things happen within weeks, and neither is a commit to the repository. On the twenty-third of September, Node 20 stops being available, and their older action majors are executed on Node 24. Between the nineteenth of October and the nineteenth of November, by the schedule GitHub announced, `ubuntu-latest` migrates to Ubuntu 26.04.

**[ANIMATION]** step: result

If a release then fails, the team has nothing to bisect: the repository didn't change. That's the cost of floating references.

**[ANIMATION]** step: pf.4

**[ANIMATION]** say: Each_change_now_arrives_as_a_pull_request:_a_diff,_a_run,_a_commit_to_revert

Apply the model. Pin each action to a commit ID with the version as a comment, on the Node 24 majors. Name the runner image. Let Dependabot propose the pin updates. From then on each of those changes arrives as a pull request with a diff, a run, and a commit to revert.

## PRACTICE EXERCISE

Your turn. Do Lab 26.6, "Workflow 6, build and push a container image", in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md), in your normal shell.

Three predictions, written down before each run. For the pull request: whether the login step runs and which tags are computed. For the push to `main`: the tags from the branch name and the short commit ID. For the version tag: which workflows start and which image tags appear.

The challenge is Lab 26.7, "Workflow 7, create an artifact and consume it", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q294: "Why would you pin `actions/checkout` in a workflow by a 40-character commit ID, and what does the Node 24 change of September 2026 mean for a file that says `@v4`?"

**[PAUSE]**

Answer out loud. A strong answer explains what a tag is and who can move it, and what a commit ID gives you that a tag doesn't, in Git terms. It says how the pin is kept current so that pinning doesn't become neglect. For the second half it states the date, what happens to an action that declares the older runtime, and what the rule for a workflow author is. The follow-up asks what still moves under a workflow when every action is pinned. Use the pinned-or-floating list from this video.

## RECAP

Let's land this.

You should now be able to say:

- Workflow 6 builds on every pull request without logging in, and pushes from `main` and from version tags, with tags computed from Git facts.
- An image tag is a name: `sha-` plus the commit ID names a commit, `main` and `latest` move, a version comes from a Git tag.
- Workflow 7 builds once, uploads an artifact, and deploys exactly the downloaded files, with a digest check.
- Actions are pinned by commit ID because a tag can be moved; Dependabot proposes the updates.
- Node 24 is the only JavaScript action runtime since 23 September 2026; use the Node 24 majors, and name the runner image.

## HOMEWORK

Read the rest of section 20A.13 and sections 20A.14 to 20A.18 of [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md). Do the Practice section 20A.20.

That one old line holds no surprise for you now: you can say what it names, what runs it, and how to pin it. Re-verify one pin yourself this week. Next time: environments, deploying to staging, and promotion to production behind an approval. Until then, look at the state first and type second. See you in the next one.
