# V151: Publishing a container image, and release automation in outline

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 27
- **Planned minutes.** 16
- **Prerequisites.** V130, V150
- **Textbook sections.** [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), section 20B.7
- **Demo scripts.** `labs/ch20b/lab-27-1-image-identity.sh`, then a screen walkthrough of Lab 27.1 in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md)

## HOOK

**[ON SCREEN]** One question: "Which commit is running in production?"

The on-call engineer looks at the deployment and reads the image reference. It ends in `:latest`.

That tag was pushed four times this week. It names whatever was pushed last, not what is running. To answer the question, someone now has to correlate timestamps from a registry, a deployment log and a workflow history, and hope they line up.

The team could have answered in one command if the image had been identified by something that cannot move, and if that identifier had been recorded together with the commit. This video is about making an artifact carry its own answer.

## INTRODUCTION

This is the last video of the delivery module, and it is short. It finishes two threads.

The first thread is workflow 6, which you read in V148 for its syntax. Here you look at it again for delivery: what identifies an image, and how an image is tied to exactly one commit.

The second thread is release automation, in outline, as the section gives it: three facts and one trap. The trap is the reason a release created by a workflow so often triggers nothing.

The local demonstration is about the Git side of identity: is the working tree exactly a commit, and what is that commit called relative to the release tags? The sample project's Dockerfile could not be built while the book was written, because the author could pull no base image. Lab 27.1 has you run it.

## LEARNING OBJECTIVES

After this video you can:

- make a container image identify the commit it was built from;
- explain why a release created by the workflow's own token triggers no further workflow;
- derive the version of a release from a tag in CI and say what the checkout needs for that;
- outline release automation as the section gives it.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**The image.** Workflow 6 builds and pushes an image to the GitHub container registry at `ghcr.io`. Three facts matter for delivery.

First, authentication. The job authenticates with the `GITHUB_TOKEN` and needs `packages: write`. The documentation recommends the token over a personal access token, and says that publishing from a workflow with that token is also the easiest way to connect the package to the repository.

Second, how tags and content are produced. The metadata action derives tags and labels from the Git ref and commit. The build action builds and, with `push: true`, pushes. By default that action builds from the Git context, not from the checked-out directory, so files changed by earlier steps are ignored unless `context: .` is set.

Third, and this is the sentence of the video: an image is identified by its digest, not by a tag. A tag such as `latest` or `main` is a movable name, exactly like a branch. So: deploy by digest, and record the digest and the commit together. The textbook adds that `actions/attest` can attach signed build provenance to the digest; that belongs to Part 7.

**One commit per image.** An image tag should identify one commit. Git can tell you two things that make that statement checkable. Whether a working tree is exactly a commit: `git status` in its short or porcelain form prints nothing when it is. And what that commit is called relative to the release tags: `git describe` with `--tags` and `--match` for the release pattern.

`git describe` has an option for exactly this purpose: `--dirty`. It appends `-dirty` when the working tree differs from HEAD. A runner's checkout is clean, which is one reason the textbook gives for building release images in CI and not on a laptop.

And the connection to V145: a job that derives the version from a tag needs the tags and enough history for `git describe` to walk. The default checkout has neither.

**Releases, in outline.** Three facts and one trap.

Fact one. A release is a GitHub object on a Git tag. In a job, `gh release create` with the tag, the files, `--verify-tag` and `--generate-notes` creates it, with the token in the environment and `contents: write` permission. `--verify-tag` refuses to invent a tag that does not exist. You saw why that matters in V140: without it the command may create a tag on the default branch, and section 15.22 labels that form 🔴 DANGEROUS. With `--verify-tag` and `--draft` the label is 🟡 CAUTION.

Fact two. With immutable releases, create a draft, attach every asset, then publish.

Fact three. Tools such as release-please derive the release from conventional commit messages. The textbook is explicit: it is named as a concept and was not run for the book.

**The trap.** Events caused by the `GITHUB_TOKEN` do not start new workflow runs, with narrow exceptions. A workflow that creates a tag or a release with the job token will not trigger your separate `on: release` or tag-push workflow.

The textbook gives two ways out. Either chain the work as jobs of one workflow with `needs`. Or create the tag with a GitHub App token.

Why does GitHub do this? You heard the rule in V143 as a property of the job token. Think about the alternative: a workflow that pushes with its own token and thereby starts itself again.

## MENTAL MODEL

There are three kinds of names on an image, and you already know all three from Git.

A tag like `main` or `latest` behaves like a branch: it is a name that moves when someone pushes.

A tag like `0.2.0` behaves like a release tag: it is meant to stay, and nothing but discipline makes it stay.

The digest behaves like a commit ID: it is computed from the content, so it cannot name anything else.

The model you built in Part 1, that a branch is a ref and a commit ID is the identity, carries over directly. Deploying `:latest` is like deploying "whatever `main` is at the moment the machine pulls".

Where the comparison breaks: a commit ID covers the source. A digest covers the built image. The same commit built twice does not necessarily give the same digest, because a build tool is not always reproducible; you heard that in V149. So neither identifier replaces the other. You record both, together, and that pair is what answers the on-call engineer's question.

## DIAGRAM

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

**[DIAGRAM]** Read it backwards, as the on-call engineer would: deployment, digest, the commit recorded with it, and `git describe` for a name a human can use.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch20b/lab-27-1-image-identity`. Git, in the sandbox, in a repository called `warehouse-api`.

**Step 1: is this tree exactly a commit, and what is the commit called?**

```bash
git rev-parse HEAD
git status --porcelain
git tag --points-at HEAD
git describe --tags --match 'v*'
```

All four read. **[PAUSE]** No tag points at HEAD; the newest release tag is two commits back. What will `git describe` print?

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

The full ID of HEAD. Then nothing from `git status --porcelain`: the tree is clean, it is exactly that commit. Nothing from `git tag --points-at`: this commit is not a release. And the description: `v1.1.0-2-g57c8425`. The last release, two commits since, and the abbreviated ID. That string is a usable build identifier: it names one commit and tells a human where it sits.

**Step 2: a build from a tree that is not the commit.**

```bash
printf '\n# local tweak\n' >> src/warehouse/rules.py
git status --short
git describe --tags --match 'v*' --dirty
```

Someone builds on a laptop with one uncommitted line. **[PAUSE]** What does `--dirty` add?

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

`-dirty`. Git is saying that the working tree differs from HEAD. An image built now and labelled with the commit ID alone would claim to be `57c8425` and would not be.

**Step 3: recovery, and a release.**

```bash
git restore src/warehouse/rules.py
git describe --tags --match 'v*' --dirty
git tag -a v1.2.0 -m "Release 1.2.0"
git describe --tags --match 'v*' --dirty
```

`git restore` on a path is 🔴 DANGEROUS, so the five answers before it runs. What it changes: the file in the working tree, from the index. What it can destroy: uncommitted edits to that file that were never staged. How to preview: `git diff` for the path. How to recover: there is no recovery for content that was never staged. When it is appropriate: here, for a one-line tweak made on purpose in a sandbox, after `git status` showed that it is the only change.

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

After the restore the description is clean again. After the annotated tag, the tag points at HEAD and the description is the tag name itself: `v1.2.0`. That is the moment a release build wants: the commit's name is the version, with nothing after it.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough.

Part B of Lab 27.1, on your practice repository, in your normal shell. The interface changes; the lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

Predict first, as the lab asks: which tags will the image get for a push of a Git version tag? Read the `tags` input of the metadata step in workflow 6 and write your prediction down.

```bash
git push origin v0.1.0
gh run list --workflow 06-docker-image.yml --limit 3
```

`git push` of a tag is 🟡 CAUTION: it creates a tag on GitHub and starts every workflow with a matching tag filter, here an image push, and deleting the tag afterwards does not unpublish the image. `gh run list` reads.

Open the run in the browser and go to the job summary that the last step of the workflow writes. Find two things: the digest, and the list of tags. Compare the tags with your prediction. Then write down the pair that identifies this release: the digest and the commit ID. Find the package from the repository's page and see whether its tag list tells you which of its names can still move.

## COMMON MISTAKES

1. **Deploying by a tag such as `latest` or `main`.** Root cause: a tag is a movable name, exactly like a branch; only the digest identifies the image.
2. **Building a release image on a laptop.** Root cause: the working tree may differ from the commit it claims to be; a runner's checkout is clean.
3. **A release workflow that waits for an event its own token caused.** Root cause: events caused by the `GITHUB_TOKEN` do not start new workflow runs, with narrow exceptions.
4. **Deriving the version from a tag in a job with the default checkout.** Root cause: one commit and no tags, so `git describe` has nothing to find.
5. **Omitting `context: .` after steps that changed files.** Root cause: by default the build action builds from the Git context and ignores local file changes.

## PRODUCTION EXAMPLE

A team that serves a ranking model has two workflows. The first runs on pushes to `main`: it tests, computes the next version, and creates a release with the job token. The second has the trigger `on: release` and builds and publishes the image. The first workflow goes green. A release appears. The second workflow never starts, and for a day people look for a typing error in its trigger.

There is none. The release was created by the `GITHUB_TOKEN`, and events caused by that token do not start new workflow runs.

The team chooses the first of the textbook's two repairs: one workflow, with the image job chained after the release job by `needs`. In the same change, the image job stops deploying `latest`. It writes the digest and the commit ID into its job summary, and the deploy job refers to the image by digest. The on-call engineer's question now has a one-line answer.

## PRACTICE EXERCISE

Do Lab 27.1, "A container image that identifies its commit (workflow 6)", in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md). Part A runs in `labs/shell`; your IDs differ there. Part B runs in your normal shell.

In Part A, predict the output of `git describe` before each run: on the clean commit, on the modified tree, and after tagging. In Part B, predict the image tags for the tag push before you look at the summary.

The challenge is Exercise 27.6, "The release that triggers nothing", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q305: "Design the path from a merge on `main` to production for a backend service such that the bytes that were tested are the bytes that are deployed, no test or build code runs in a job that holds a deployment credential, and two production deployments never overlap. Defend each decision."

This is a design question with three requirements, and a strong answer takes them one at a time and names the mechanism from Module 27 that meets each: how bytes travel between jobs and what verifies them; which job names the environment and why the others cannot read its secrets; and which concurrency setting serializes production, with the setting it must not have. Then it says what gates the production job and what that gate rests on. The follow-up is the approver asking "what exactly am I approving?": answer with a commit range, and say what an approval does not cover.

## RECAP

You should now be able to say:

- An image is identified by its digest; a tag is a movable name, like a branch.
- Deploy by digest and record the digest and the commit ID together.
- `git describe --tags --match` names a commit relative to the release tags, and `--dirty` says when the tree is not that commit.
- A tag-driven release job needs the tags and the history, which the default checkout does not fetch.
- Events caused by the job token start no new workflow runs: chain jobs with `needs`, or use a GitHub App token.

## HOMEWORK

Read section 20B.7 of [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md). Do Lab 27.2, "One build, carried between jobs (workflow 7)", in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md).
