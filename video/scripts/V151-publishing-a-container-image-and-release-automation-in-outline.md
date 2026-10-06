# V151: Publishing a container image, and release automation in outline

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 27
- **Planned minutes.** 16
- **Prerequisites.** V130, V150
- **Textbook sections.** [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), section 20B.7
- **Demo scripts.** `labs/ch20b/lab-27-1-image-identity.sh`, then a screen walkthrough of Lab 27.1 in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md)

## HOOK

**[ON SCREEN]** One question: "Which commit is running in production?"

The on-call engineer looks at the deployment and reads the image reference. It ends in `:latest`. A container image is an application packaged with what it needs to run, and a registry is the server that stores images.

**[ANIMATION]** stores: id=latest boxes=the_registry:four_pushes_this_week|production:the_image_reference rows=1:A:the_first_push|1:A:the_second_push|1:A:the_third_push|1:A:the_fourth_push:_latest_names_this_one@ref|2:B:it_ends_in_:latest@hl|2:B:which_push_is_running?@bad title=A_tag_names_whatever_was_pushed_last at_1=5 at_2=35

That tag was pushed four times this week. It names whatever was pushed last, not what is running. To answer the question, someone now has to correlate timestamps from a registry, a deployment log and a workflow history, and hope they line up.

The team could have answered in one command if the image had been identified by something that can't move, and if that identifier had been recorded together with the commit, the saved snapshot of the source. This video is about making an artifact carry its own answer. Keep that question. By the end it has a one-line answer.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the last video of the delivery module, and it's short. It finishes two threads.

The first thread is workflow 6, which you read in video 148 for its syntax. A workflow is a file that tells GitHub Actions which jobs to run. Here you look at it again for delivery: what identifies an image, and how an image is tied to exactly one commit.

The second thread is release automation, in outline, as the section gives it: three facts and one trap. A release is a GitHub record that points at a tag and adds notes and files. The trap is the reason a release created by a workflow so often triggers nothing.

The local demonstration is about the Git side of identity: is the working tree exactly a commit, and what is that commit called relative to the release tags? The sample project's Dockerfile couldn't be built while the book was written, because the author could pull no base image. Lab 27.1 has you run it.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- make a container image identify the commit it was built from;
- explain why a release created by the workflow's own token triggers no further workflow;
- derive the version of a release from a tag in CI and say what the checkout needs for that;
- outline release automation as the section gives it.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**The image.** Workflow 6 builds and pushes an image to the GitHub container registry at `ghcr.io`. Three facts matter for delivery.

First, authentication. The job authenticates with the `GITHUB_TOKEN`, the short-lived token every job gets, and needs `packages: write`. The documentation recommends the token over a personal access token, and says that publishing from a workflow with that token is also the easiest way to connect the package to the repository.

Second, how tags and content are produced. The metadata action derives tags and labels from the Git ref and commit. The build action builds and, with `push: true`, pushes. By default that action builds from the Git context, not from the checked-out directory, so files changed by earlier steps are ignored unless `context: .` is set.

Third, and this is the sentence of the video: an image is identified by its digest, not by a tag. The digest is a fingerprint computed from the image's content. A tag such as `latest` or `main` is a movable name, exactly like a branch. So: deploy by digest, and record the digest and the commit together. The textbook adds that `actions/attest` can attach signed build provenance to the digest. That belongs to Part 7.

**One commit per image.** An image tag should identify one commit. Git can tell you two things that make that statement checkable. Whether a working tree is exactly a commit: `git status` in its short or porcelain form prints nothing when it is. And what that commit is called relative to the release tags: `git describe` with `--tags` and `--match` for the release pattern.

`git describe` has an option for exactly this purpose: `--dirty`. It appends `-dirty` when the working tree differs from HEAD. A runner's checkout is clean, which is one reason the textbook gives for building release images in CI and not on a laptop.

And the connection to video 145: a job that derives the version from a tag needs the tags and enough history for `git describe` to walk. The default checkout has neither.

**[ANIMATION]** cards: id=facts question=Releases,_in_outline cards=A_release_is_a_GitHub_object_on_a_Git_tag:gh_release_create_with_--verify-tag|With_immutable_releases:a_draft,_every_asset,_then_publish|release-please:named_as_a_concept,_not_run_for_the_book|and_one_trap ask=4 numbered=on

**[ANIMATION]** step: 1

**Releases, in outline.** Three facts and one trap.

Fact one. A release is a GitHub object on a Git tag. In a job, `gh release create` with the tag, the files, `--verify-tag` and `--generate-notes` creates it, with the token in the environment and `contents: write` permission. `--verify-tag` refuses to invent a tag that doesn't exist. You saw why that matters in video 140: without it the command may create a tag on the default branch, and section 15.22 labels that form 🔴 DANGEROUS. With `--verify-tag` and `--draft` the label is 🟡 CAUTION.

**[ANIMATION]** step: 2

Fact two. With immutable releases, create a draft, attach every asset, then publish.

**[ANIMATION]** step: 4

Fact three. Tools such as release-please derive the release from conventional commit messages. The textbook is explicit: it's named as a concept and wasn't run for the book.

Quick quiz. One workflow creates a release with the job token. A second workflow has the trigger `on: release`. Does the second one start? A, yes. B, no. Your answer?

**[PAUSE]**

**[ANIMATION]** flow: id=trap actors=workflow_one,*GitHub,workflow_two subs=creates_the_release,-,on_release msgs=1>2:a_release,_with_the_job_token|2>3:no_new_run_starts:fail|1>1:or_jobs_of_one_workflow,_with_needs:ok|1>2:or_the_tag,_with_a_GitHub_App_token:ok title=A_release_that_triggers_nothing at_1=25 at_2=50

**[ANIMATION]** step: 2

**The trap.** B, it doesn't. Events caused by the `GITHUB_TOKEN` don't start new workflow runs, with narrow exceptions. A workflow that creates a tag or a release with the job token won't trigger your separate `on: release` or tag-push workflow.

**[ANIMATION]** step: 4

The textbook gives two ways out. Either chain the work as jobs of one workflow with `needs`. Or create the tag with a GitHub App token.

Why does GitHub do this? You heard the rule in video 143 as a property of the job token. Think about the alternative: a workflow that pushes with its own token and thereby starts itself again.

## MENTAL MODEL

**[ANIMATION]** walk: id=names columns=a_name_on_an_image,behaves_like,because rows=a_tag_like_main_or_latest:a_branch:it_moves_when_someone_pushes|a_tag_like_0.2.0:a_release_tag:meant_to_stay,_and_only_discipline_keeps_it|the_digest:a_commit_ID:computed_from_the_content marks=1.3:bad,2.3:wait,3.3:ok mono=off title=Three_kinds_of_names,_each_with_a_twin_in_Git

**[ANIMATION]** step: header

There are three kinds of names on an image, and each has a twin in Git.

**[ANIMATION]** step: 1

A tag like `main` or `latest` behaves like a branch: it's a name that moves when someone pushes.

**[ANIMATION]** step: 2

A tag like `0.2.0` behaves like a release tag: it's meant to stay, and nothing but discipline makes it stay.

**[ANIMATION]** step: 3

The digest behaves like a commit ID: it's computed from the content, so it can't name anything else.

The model you built in Part 1, that a branch is a ref and a commit ID is the identity, carries over directly. Deploying `:latest` is like deploying "whatever `main` is at the moment the machine pulls".

**[ANIMATION]** say: A_commit_ID_covers_the_source,_a_digest_the_built_image:_record_both,_together

Where the comparison breaks: a commit ID covers the source. A digest covers the built image. The same commit built twice doesn't necessarily give the same digest, because a build tool isn't always reproducible. You heard that in video 149. So neither identifier replaces the other. You record both, together, and that pair is what answers the on-call engineer's question.

## DIAGRAM

**[ANIMATION]** stores: id=chain boxes=commit:on_main|build:a_clean_runner_checkout|image:digest_sha256,_tags_are_names|deployment:by_digest rows=1:B:commit_ID_in_the_checkout|2:C:commit_ID_in_tag_sha-<short_ID>_and_label|3:D:digest_+_commit_ID_recorded|3:D:environment_production|4:A:git_describe,_with_--dirty@hl arrows=1:A>B:ID|2:B>C:ID|3:C>D:ID title=The_commit_ID_travels_along_the_chain

**[DIAGRAM]** A chain from left to right. Draw the commit first. Then each box and arrow in turn, and write the commit ID on every arrow, so that at no point in the chain the question "from which commit?" needs a lookup.

```text
              commit ID            commit ID in tag             digest + commit ID
              in the checkout      sha-<short ID> and label     in the deployment record
   +--------+   |    +---------+     |    +----------------+      |     +--------------+
   | commit | -----> |  build  | -------> | image          | ---------> | deployment   |
   | on main|        | (clean  |          | digest: sha256 |            | by digest    |
   +--------+        |  runner |          | tags: names    |            | environment: |
       ^             | checkout|          +----------------+            | production   |
       |             +---------+                                        +--------------+
   git describe --tags --match 'v*' --dirty
   says what the commit is called, and whether the tree IS the commit
```

**[ANIMATION]** step: 3

Start at the commit. The build gets its ID in the checkout. The image carries it in a tag and a label. The deployment record holds the digest and the commit ID together.

**[ANIMATION]** step: 4

Follow the commit ID along the chain: it's written on every arrow.

**[DIAGRAM]** Read it backwards, as the on-call engineer would: deployment, digest, the commit recorded with it, and `git describe` for a name a human can use.

## LIVE TERMINAL DEMO

Into the lab.

**[TERMINAL]** Replay with `labs/run ch20b/lab-27-1-image-identity`. Git, in the sandbox, in a repository called `warehouse-api`.

**Step 1: is this tree exactly a commit, and what is the commit called?**

```bash
git rev-parse HEAD
git status --porcelain
git tag --points-at HEAD
git describe --tags --match 'v*'
```

All four only read. No tag points at HEAD, and the newest release tag is two commits back. What will `git describe` print? Say it out loud.

**[PAUSE]**

<!-- snippet: ch20b/lab-27-1-image-identity/01-identity -->
```text
$ git rev-parse HEAD
57c8425908f43c74c14b2642edb59e0f99dac38c
$ git status --porcelain
$ git tag --points-at HEAD
$ git describe --tags --match 'v*'
v1.1.0-2-g57c8425
```
<!-- /snippet -->

The full ID of HEAD. Then nothing from `git status --porcelain`: the tree is clean, it's exactly that commit. Nothing from `git tag --points-at`: this commit isn't a release.

**[ANIMATION]** graph: id=desc ...older-c4b5de2-197d992-57c8425 main; c4b5de2 atag:v1.1.0; HEAD=main; range:197d992,57c8425:2_commits_since_v1.1.0; cmd:git_describe_--tags_--match_'v*'; say:v1.1.0-2-g57c8425:_the_last_release,_two_commits_since,_the_abbreviated_ID => + 57c8425 atag:v1.2.0; range:; name:tagged; cmd:git_tag_-a_v1.2.0_-m_"Release_1.2.0"; say:The_tag_points_at_HEAD:_the_description_is_v1.2.0 dx=260 at_state_1=8

**[ANIMATION]** step: state-1

And the description: `v1.1.0-2-g57c8425`. The last release, two commits since, and the abbreviated ID. That string is a usable build identifier: it names one commit and tells a human where it sits.

**[ANIMATION]** end

Try it now. Thirty seconds, in any repository of your own. Run `git status --porcelain`, which only reads. Does it print anything?

**[PAUSE]**

If it printed nothing, your working tree is exactly a commit. If it printed lines, each one is a difference, and a build from that tree wouldn't be the commit it claims to be.

**Step 2: a build from a tree that is not the commit.**

```bash
printf '\n# local tweak\n' >> src/warehouse/rules.py
git status --short
git describe --tags --match 'v*' --dirty
```

Someone builds on a laptop with one uncommitted line. What does `--dirty` add? Make your prediction.

**[PAUSE]**

<!-- snippet: ch20b/lab-27-1-image-identity/02-failure -->
```text
# A build from a working tree that differs from the commit it claims to be:
$ printf '\n# local tweak\n' >> src/warehouse/rules.py
$ git status --short
 M src/warehouse/rules.py
$ git describe --tags --match 'v*' --dirty
v1.1.0-2-g57c8425-dirty
```
<!-- /snippet -->

`-dirty`. Git is saying that the working tree differs from HEAD. An image built now and labelled with the commit ID alone would claim to be `57c8425` and wouldn't be.

**[ANIMATION]** trees: file=src/warehouse/rules.py steps=setup,edit,restore versions=the_commit,one_uncommitted_line title=Is_the_tree_exactly_the_commit

**[ANIMATION]** step: edit

Here's the same state in the three-trees picture from Part 1. HEAD and the index still hold the commit. Only the working tree has the extra line.

**Step 3: recovery, and a release.**

```bash
git restore src/warehouse/rules.py
git describe --tags --match 'v*' --dirty
git tag -a v1.2.0 -m "Release 1.2.0"
git describe --tags --match 'v*' --dirty
```

**[ANIMATION]** step: restore

`git restore` on a path is 🔴 DANGEROUS, so the five answers before it runs. What it changes: the file in the working tree, from the index. What it can destroy: uncommitted edits to that file that were never staged. How to preview: `git diff` for the path. How to recover: there is no recovery for content that was never staged. When it's appropriate: here, for a one-line tweak made on purpose in a sandbox, after `git status` showed that it's the only change.

**[ANIMATION]** end

`git tag -a` is 🟢 SAFE: it adds an object and a ref.

<!-- snippet: ch20b/lab-27-1-image-identity/03-recovery -->
```text
$ git restore src/warehouse/rules.py
$ git describe --tags --match 'v*' --dirty
v1.1.0-2-g57c8425
# A release: tag the commit, and the name becomes the tag itself.
$ git tag -a v1.2.0 -m "Release 1.2.0"
$ git tag --points-at HEAD
v1.2.0
$ git describe --tags --match 'v*' --dirty
v1.2.0
```
<!-- /snippet -->

After the restore the description is clean again.

**[ANIMATION]** step: desc.tagged

After the annotated tag, the tag points at HEAD and the description is the tag name itself: `v1.2.0`. That's the moment a release build wants: the commit's name is the version, with nothing after it.

**[ANIMATION]** end

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough.

Part B of Lab 27.1, on your practice repository, in your normal shell. The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

Predict first, as the lab asks: which tags will the image get for a push of a Git version tag? Read the `tags` input of the metadata step in workflow 6 and write your prediction down.

```bash
git push origin v0.1.0
gh run list --workflow 06-docker-image.yml --limit 3
```

`git push` of a tag is 🟡 CAUTION: it creates a tag on GitHub and starts every workflow with a matching tag filter, here an image push, and deleting the tag afterwards doesn't unpublish the image. `gh run list` reads.

Open the run in the browser and go to the job summary that the last step of the workflow writes. Find two things: the digest, and the list of tags. Compare the tags with your prediction. Then write down the pair that identifies this release: the digest and the commit ID. Find the package from the repository's page and see whether its tag list tells you which of its names can still move.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Deploying by a tag such as `latest` or `main`.** Root cause: a tag is a movable name, exactly like a branch; only the digest identifies the image.
2. **Building a release image on a laptop.** Root cause: the working tree may differ from the commit it claims to be; a runner's checkout is clean.
3. **A release workflow that waits for an event its own token caused.** Root cause: events caused by the `GITHUB_TOKEN` do not start new workflow runs, with narrow exceptions.
4. **Deriving the version from a tag in a job with the default checkout.** Root cause: one commit and no tags, so `git describe` has nothing to find.
5. **Omitting `context: .` after steps that changed files.** Root cause: by default the build action builds from the Git context and ignores local file changes.

## PRODUCTION EXAMPLE

Now, out of the lab. A team that serves a ranking model has two workflows. The first runs on pushes to `main`: it tests, computes the next version, and creates a release with the job token. The second has the trigger `on: release` and builds and publishes the image. The first workflow goes green. A release appears. The second workflow never starts, and for a day people look for a typing error in its trigger.

**[ANIMATION]** step: trap.4

There is none. The release was created by the `GITHUB_TOKEN`, and events caused by that token don't start new workflow runs.

**[ANIMATION]** step: chain.4

**[ANIMATION]** say: One_workflow:_the_digest_and_the_commit_ID,_recorded_together

The team chooses the first of the textbook's two repairs: one workflow, with the image job chained after the release job by `needs`. In the same change, the image job stops deploying `latest`. It writes the digest and the commit ID into its job summary, and the deploy job refers to the image by digest. The on-call engineer's question now has a one-line answer.

## PRACTICE EXERCISE

Your turn. Do Lab 27.1, "A container image that identifies its commit (workflow 6)", in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md). Part A runs in `labs/shell`, and your IDs differ there. Part B runs in your normal shell.

In Part A, predict the output of `git describe` before each run: on the clean commit, on the modified tree, and after tagging. In Part B, predict the image tags for the tag push before you look at the summary.

The challenge is Exercise 27.6, "The release that triggers nothing", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q305: "Design the path from a merge on `main` to production for a backend service such that the bytes that were tested are the bytes that are deployed, no test or build code runs in a job that holds a deployment credential, and two production deployments never overlap. Defend each decision."

**[PAUSE]**

Answer out loud. This is a design question with three requirements, and a strong answer takes them one at a time and names the mechanism from Module 27 that meets each. How bytes travel between jobs and what verifies them. Which job names the environment and why the others can't read its secrets. And which concurrency setting serializes production, with the setting it must not have. Then it says what gates the production job and what that gate rests on. The follow-up is the approver asking "what exactly am I approving?": answer with a commit range, and say what an approval doesn't cover.

## RECAP

Let's land this.

You should now be able to say:

- An image is identified by its digest; a tag is a movable name, like a branch.
- Deploy by digest and record the digest and the commit ID together.
- `git describe --tags --match` names a commit relative to the release tags, and `--dirty` says when the tree is not that commit.
- A tag-driven release job needs the tags and the history, which the default checkout does not fetch.
- Events caused by the job token start no new workflow runs: chain jobs with `needs`, or use a GitHub App token.

## HOMEWORK

Read section 20B.7 of [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md). Do Lab 27.2, "One build, carried between jobs (workflow 7)", in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md).

You can now make an image carry its own answer: a digest and a commit ID, recorded together. Try `git describe` with `--dirty` in the lab shell before the next video. Next time: runners, limits and billing, and the investigation order for a failing workflow. Until then, look at the state first and type second. See you in the next one.
