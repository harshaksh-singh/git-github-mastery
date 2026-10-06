# Module 27 lab answers

> Answers to the "Questions" of the [Module 27 labs](../lab-manual/m27-build-package-deliver.md). GitHub behavior is cited from the documentation as in [Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md); nothing here was run on GitHub by the author.

## Lab 27.1: A container image that identifies its commit

1. **"Deploy the image tagged `main`."** A registry tag is a movable name. Every push to `main` moves it to a new digest, so the instruction means something different each time it is carried out, and a restart of the service can change the running code. Write "deploy `ghcr.io/ORG/inventory-api@sha256:<digest>`, built from commit `<ID>`" and record both in the deployment's summary.
2. **`packages: write` at the top.** Top-level permissions apply to every job of the workflow, including any job added later. A test or lint job that runs dependency code would then hold a token that can publish packages. At job level only the job that pushes has the scope.
3. **Build but do not push on pull requests.** First, a pull request from a fork gets a read-only token, so a login and push would fail anyway. Second, a pull request is unreviewed code: building it proves the Dockerfile still works, and publishing it would put an unreviewed image under the project's name in the registry.
4. **`git describe` inside workflow 6.** No. The checkout step of workflow 6 sets only `persist-credentials: false`, so it fetches one commit and no tags. `git describe` would exit with "No names found". The image tags come from `docker/metadata-action`, which reads the ref and commit of the event and does not need history.

## Lab 27.2: One build, carried between jobs

1. **Download, do not rebuild.** The build job's output is what was produced from the tested commit with the tested tool versions. A second build on another machine can differ (see answer 4), and then what is deployed is not what was checked. It also costs time twice.
2. **Artifact and cache.** An artifact is an output of a run that you want to keep or pass on: it belongs to the run, is immutable under its name, and has a retention period. A cache holds inputs that are expensive to fetch again, shared across runs under a key; it may be evicted at any time, so a job must work without it.
3. **A three-week-old build with seven days of retention.** It is gone: expired artifacts are deleted, and since 24 September 2026 they are no longer listed in the interface or the API. Roll back by building the old commit or tag again, knowing it may not be byte-identical. To change it: publish release builds somewhere meant to last (release assets, a package or container registry) and keep short retention for everyday builds.
4. **Why a build may not be reproducible.** Timestamps or host names embedded in the output; dependency versions resolved at build time without a lock file; a base image referenced by a moving tag; a different version of the build tool on the runner image.

## Lab 27.3: Deploy to staging

1. **The line that protects staging.** `needs: build` on the deploy job. The build job runs the tests before it builds and uploads; if any step fails, the job fails, and a job that needs a failed job is skipped.
2. **Three pushes during a deployment.** Run 1 is in progress and continues, because `cancel-in-progress` is `false`. Run 2 is queued as pending. Run 3 is queued, and the pending run 2 is cancelled, because by default a group keeps one pending run. Run 4 does the same to run 3. When run 1 finishes, run 4 deploys. Staging ends at the newest commit, which contains the others; runs 2 and 3 never deployed on their own.
3. **`env`, not interpolation.** `${{ }}` is substituted into the script text before the shell starts. A value written into the text becomes part of the program: it can break or change the command, and it appears wherever the script text does. Through `env` the value stays data that the script reads as `$DEPLOY_TOKEN`. Chapter 21A builds the injection case on this.
4. **What a re-run reuses.** The commit and ref of the original event, and the privileges of the actor who triggered the original run. For a deploy workflow that means the old commit is deployed again, over whatever is there now: an unannounced rollback.
5. **Environment created by the workflow.** The first run would have created `staging` without rules. The job would have run with `vars.STAGING_URL` and `secrets.DEPLOY_TOKEN` both empty strings, without an error from GitHub. For `staging` that is a confusing first run; for `production` it is an unprotected deployment.

## Lab 27.4: Staging, then production behind an approval

1. **Three controls.**
   - A ruleset on `main` that requires pull requests and review. Without it, anyone with write access pushes to `main`, and the deployment of that push is "from `main`" and looks legitimate.
   - The deployment branch rule `main` on the environment. Without it, a run on any branch, including one whose workflow file was edited on that branch, can reach the production job.
   - A required reviewer (with self-review prevented in a team). Without it, every merge to `main` goes to production with no human decision at the moment of release.
2. **The waiting job and the secret.** Environment secrets are available only to jobs that reference the environment, and "if the environment requires approval, a job cannot access environment secrets until one of the required reviewers approves it". The waiting job has not been sent to a runner at all.
3. **Where the difference lives.** On GitHub, in the two environment objects: their variables, their secrets and their protection rules. Repository administrators configure environments; anyone who can edit workflows can name one. That split is the point: the procedure is reviewed as code, the gate is held by fewer people.
4. **Private repository on Team.** Required reviewers, wait timers, custom protection rules and switching off the administrator bypass are available only in public repositories on Free, Pro and Team. The deployment branch rule and the environment secrets and variables do work on Team. So the workflow runs, staging and production are separated by credentials and by the branch rule, but the production job does not wait for a person.
5. **The administrator in a hurry.** "By default, administrators can bypass the protection rules and force deployments to specific environments"; the setting can be switched off per environment (public repositories only on Free, Pro and Team). Where a bypass is recorded is not stated on the pages read for this course. Look at the run's deployment review history and at the organization's audit log, and confirm in your own organization what each shows.

## Lab 27.5: A reusable workflow and its caller

1. **Keys of a calling job.** `name`, `uses`, `with`, `secrets` (including `secrets: inherit`), `strategy`, `needs`, `if`, `concurrency`, `permissions` and `cache-mode`. Missing: `runs-on` and `steps`. The called workflow's jobs choose their own runners and contain the steps.
2. **Why a repository secret.** The calling job cannot name an environment, and "environment secrets cannot be passed from the caller workflow as `on.workflow_call` does not support the `environment` keyword". A secret the caller can pass must be visible to the caller's job: a repository or organization secret. An environment's secrets are read inside the called job, which names the environment.
3. **`permissions: {}` in the caller.** The caller's grant is the ceiling: the called workflow's permissions "can be only downgraded (not elevated)". With an empty grant, the called job cannot have `contents: read`. What GitHub does when the called file asks for more than the caller allows (refuse the run at start-up, or give less) is not stated on the pages read for this course. Try it on a branch and record what you see.
4. **A case for a composite action.** The three steps "install uv, `uv sync --locked`, `uv run pytest`" are repeated in the build jobs of workflows 8 and 9 and in the called workflow. They are steps inside a job, need no runner choice, no environment and no secret: a composite action in `.github/actions/` fits. A reusable workflow would add a job boundary, and with it an artifact hand-over, for no gain.
5. **`@main` and re-runs.** "Re-run all jobs" resolves the reference again, so the run can use a newer version of the shared workflow than the first attempt did. "Re-run failed jobs" uses the same commit of the called workflow as the first attempt. Pin the reference to a full commit ID, and let Dependabot propose updates: then every attempt, and every repository, uses the version that was reviewed.
