# V149: Environments, deploying to staging, and promotion to production behind an approval

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 27
- **Planned minutes.** 28
- **Prerequisites.** V148
- **Textbook sections.** [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), sections 20B.1 to 20B.4, with sections 20B.16 to 20B.18
- **Demo scripts.** `labs/ch20b/lab-27-2-artifact-digest.sh`, `labs/ch20b/lab-27-3-deploy-range.sh`, `labs/ch20b/lab-27-4-promotion.sh`; the files [`08-deploy-staging.yml`](../../workflows/08-deploy-staging.yml) and [`09-environments.yml`](../../workflows/09-environments.yml); screen walkthroughs of Labs 27.3 and 27.4 in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md)

## HOOK

**[ON SCREEN]** One question from section 20B.1: "Who approved what is running in production, and which commit is it?"

Production is the live system that real users depend on, and a commit is one saved snapshot of the project. The textbook's comment on that question is the lesson of this video: the answer isn't in Git. It's in GitHub objects: an environment, its protection rules, a deployment record. If you can't say which rules gate the production job and who can bypass them, you don't control your releases.

And here's how a team finds out that it doesn't. The workflow file says `environment: production`. Everyone has read that line and assumed a gate. One day a deployment goes to production without anyone approving it. The YAML was correct. So what was missing? Take a guess, out loud.

**[PAUSE]**

**[ANIMATION]** gates: id=nogate packet=the_job_that_names_production gates=the_environment:pass:GitHub:created_by_the_first_run_that_named_it|protection_rules:skip:GitHub:none_were_configured result=nobody_approved title=A_line_that_looked_like_a_gate at_1=10 at_result=45

The gate had never been configured, and naming an environment that doesn't exist creates it, without any rule. So what does make a real gate? Three things together, and before this video ends you'll be able to say all three to a CTO.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A workflow is a file that tells GitHub Actions which jobs to run when an event happens, and a job is a list of steps on one fresh machine, the runner. Chapter 20A taught the parts of a workflow. Chapter 20B uses those parts to deliver software, and this is its first video.

**[ON SCREEN]** Lower third: GitHub Actions and GitHub.

The textbook is firm about the layers here. Nothing in this chapter is a Git feature. Git supplies the commit, the ref and the tag. GitHub Actions decides when to run, on which machine, with which token. And GitHub decides what a "deployment" and a "check" are.

Three topics. Environments: what they are, what their rules do, and what you must configure outside the workflow file. Workflow 8, which deploys to staging, the rehearsal system, what was built once. And workflow 9, which promotes the same artifact to production behind an approval. An artifact is a set of files that a job uploads to GitHub.

Git still earns its place in the demonstration, because three questions about a deployment are Git questions. Are these the same bytes? Which commits am I about to ship? And is this deployment going forwards or backwards?

The deployments in the labs are simulated. The script prints what it would deploy and changes nothing anywhere.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- list what must be configured on GitHub, outside the workflow file, for `environment:` to protect anything;
- explain required reviewers, deployment branch rules and environment secrets;
- explain workflow 8 line by line and say which commit range a deployment contains;
- explain workflow 9 and what "the bytes that were tested are the bytes that ship" requires;
- guard a deployment against going backwards.

## CONCEPT

**In one sentence.** An environment is a named GitHub object that a job can reference, and that holds protection rules the job must pass before it starts, and secrets and variables the job can read only after that. A secret is an encrypted value stored in GitHub's settings.

**Precisely.** A job references an environment with the `environment` key, either as a name or as a mapping with a name and a URL. The rules:

**[ON SCREEN]** The table of section 20B.2.

Required reviewers: the job waits until a listed person or team approves. Up to six users or teams. One approval is enough. And "prevent self-review" stops the person who started the run from approving it.

Wait timer: the job waits a fixed time after it is triggered, from 1 to 43,200 minutes, which is 30 days. Waiting isn't billed.

Deployment branches and tags: only runs on matching refs may deploy. The choices are "No restriction", "Protected branches only", or "Selected branches and tags". Patterns are matched against the ref, and a star doesn't match a slash.

Allow administrators to bypass: lets a repository administrator force the deployment. It's on by default and can be switched off per environment.

Custom deployment protection rules, where a GitHub App decides: public preview.

Environment secrets: secrets that exist only for jobs that reference the environment, and that aren't readable before a required approval is given. Environment variables: the same scoping, without secrecy.

Two details decide how safe this is.

**[ANIMATION]** stores: id=front boxes=a_job:references_the_environment|*the_environment:on_GitHub|a_runner:the_machine rows=1:A:waits|1:B:all_protection_rules_must_pass|2:C:the_job_starts|2:C:secrets_are_readable_only_now arrows=1:A1>B1:first|2:B1>C1:then title=The_gate_is_in_front_of_the_machine at_1=10 at_2=55

First: all protection rules must pass before a job that references the environment is sent to a runner. The gate is in front of the machine. It's not a step inside the job that the job could skip.

**[ANIMATION]** end

Quick quiz. A workflow names an environment with a typing error in the name. What happens? A, the run stops with an error. B, the job starts, with no gate at all. Your answer?

**[PAUSE]**

**[ANIMATION]** stores: id=typo boxes=the_environment_you_configured:by_a_repository_administrator|the_misspelled_name:created_by_the_workflow rows=1:A:its_protection_rules@ok|2:B:no_rule_at_all@bad|3:B:no_error:_the_job_starts@bad title=A_typing_error_makes_a_second_environment at_1=5 at_2=30 at_3=75

B, and that's the second detail. A workflow that names an environment that doesn't exist creates it, without any rule. Anyone who can edit workflows can do that, while only repository administrators can configure an environment. So a typing error in the name gives you an unprotected environment, not an error.

**[ANIMATION]** walk: id=plans columns=what,public_repositories,private_repositories rows=required_reviewers,_wait_timers,_custom_rules,_no_administrator_bypass:any_plan:Enterprise|deployment_branch_and_tag_rules,_environment_secrets:any_plan:Pro,_Team_or_Enterprise marks=1.3:wait mono=off title=Plan_gates at_1=15 at_2=70

**Plan gates.** Check these before you design a gate. Required reviewers, wait timers, custom rules and disabling the administrator bypass are available in public repositories on any plan, and in private repositories on Enterprise. They aren't available in private repositories on Free, Pro or Team. Deployment branch and tag rules and environment secrets: public on any plan, private on Pro, Team or Enterprise.

**[ANIMATION]** end

**[ON SCREEN]** Callout: Unverified.

Whether a private repository on a Free plan can use environments at all is a conflict inside GitHub's own material. A changelog entry of the fifteenth of May 2025 says environments are available on all plans in public and private repositories. The managing-environments page on the first of October 2026 still says users on Free plans can configure environments only for public repositories. The Phase 0 report couldn't resolve it. The practice repository of the labs is public, so the labs aren't affected. For a private repository, test it before you promise a gate.

**Inside `.git`.** Nothing. An environment, its rules, its secrets and the deployment records it produces are GitHub objects. The only trace in Git is the word after `environment:` in the workflow file. That's why a repository that is mirrored to another host loses its gates, and why the YAML line proves nothing until you've read the environment's settings.

**Creating environments.** The documented path in the interface is the repository's settings, then Environments. The same can be done with the REST API, which is what you want for configuration that is reviewed as code.

```bash
gh api -X PUT repos/YOUR-ORG/inventory-api/environments/staging
gh secret set DEPLOY_TOKEN --env staging
gh variable set STAGING_URL --env staging --body "https://staging.example.com"
gh api repos/YOUR-ORG/inventory-api/environments --jq '.environments[].name'
gh secret list --env staging
```

The two reading commands are 🟢 SAFE. `gh secret set` and `gh variable set` are 🟡 CAUTION: they overwrite the stored value, and the old secret value can't be read back. `gh secret set` without `--body` reads the value from standard input or prompts for it, which keeps it out of your shell history. Never put a real secret value on screen.

The `PUT` is 🔴 DANGEROUS. Five answers. What it changes: it replaces the environment's protection settings with the body sent. What it can destroy: the previous settings, required reviewers included, which exist nowhere else unless you saved them. How to preview: read the environment with a `GET` first. How to recover: send the previous configuration again. When it's appropriate: for environment rules kept as code.

**Workflow 8: deploying to staging.**

**[ON SCREEN]** `08-deploy-staging.yml`, the two jobs.

The `build` job installs from the lock file, runs the tests, builds, and uploads the artifact.

**[ANIMATION]** run: id=w8 event=push jobs=build|deploy-staging:build artifact=build>deploy-staging:inventory-api-dist title=Workflow_8:_deploying_to_staging at_jobs=8

**[ANIMATION]** step: jobs

The `deploy-staging` job needs `build`, names the environment `staging` with a URL taken from a variable, checks out the repository, downloads the artifact, and runs the deployment script with the token in `env`.

The textbook names four decisions worth defending in a review.

**[ANIMATION]** step: data

Build once, deploy what was built. The deploy job doesn't run the build again. It downloads the artifact. Every job starts on a fresh machine, so the artifact is the only way the bytes travel, and it's also the point: the thing that was tested is the thing that is deployed. The download action at version 8 fails by default when the content doesn't match the digest recorded at upload.

**[ANIMATION]** say: Only_deploy-staging_names_the_environment:_build_cannot_read_the_deployment_token

The environment belongs to the job that deploys. Only `deploy-staging` names it. The build job can't read the deployment token, because an environment secret is "only available to workflow jobs that reference the environment". So test code and build scripts, including those of your dependencies, never run in a job that holds a deployment credential.

**[ANIMATION]** say: The_secret_reaches_the_script_through_env,_never_in_the_text_of_a_run_command

The secret reaches the script through `env`. It's never interpolated into the text of a `run` command.

**[ANIMATION]** say: environment.url_comes_from_an_environment_variable:_no_host_name_in_the_file

And `environment.url`: shown with the deployment on GitHub, taken from an environment variable, so the workflow file contains no host name.

**[ANIMATION]** end

Every job that references an environment creates a deployment object, unless `deployment: false` is set under `environment`. That form was added on the nineteenth of March 2026. Required reviewers and wait timers still apply, and it can't be combined with custom protection rules. Use it for a job that needs an environment's secrets but deploys nothing, for example an integration test against a staging database.

**Workflow 9: promotion to production.**

**[ON SCREEN]** `09-environments.yml`, the third job.

`deploy-production` needs `deploy-staging`.

**[ANIMATION]** run: id=w9 event=push jobs=build|deploy-staging:build|deploy-production:deploy-staging artifact=build>deploy-production:inventory-api-dist env=deploy-production:production:a_required_reviewer title=Workflow_9:_promotion_to_production at_jobs=5

**[ANIMATION]** step: jobs

It has a concurrency group named `production` with `cancel-in-progress: false`. The next video explains that block. It names the environment `production`. Its steps are the same checkout, the same download, the same script with another argument.

**[ANIMATION]** step: data

The two deploy jobs are textually almost the same. The difference is on GitHub: each environment has a variable and a secret of the same name with different values, and only `production` has rules. The textbook calls this the pattern to aim for: the workflow describes the procedure, the environments hold what differs.

**[ANIMATION]** step: gate

**[ANIMATION]** say: From_the_documentation,_not_captured:_the_job_waits_until_a_reviewer_approves

**What the reviewer sees,** from the documentation. Nothing of it was captured for the book, and the labels are GitHub's and may change. The run shows the job as waiting. A required reviewer opens the run, chooses to review deployments, selects the environment, and approves or rejects. A rejection fails the workflow. A job that nobody approves fails automatically after 30 days.

**[ANIMATION]** say: An_approval_releases_one_job_of_one_run,_and_a_run_is_bound_to_one_commit

**What an approval releases.** The reviewer approves a job of a run, and a run is bound to one commit. The useful habit is to look at the range between what production has and what the run carries.

**[ANIMATION]** end

**What the branch rule guarantees.** A deployment branch rule compares the run's ref with name patterns. Since the eighth of December 2025, for runs triggered by `pull_request` events the ref that is evaluated is `refs/pull/N/merge`, and for `pull_request_target` it's the default branch. A rule "Selected branches: main" therefore rejects pull request runs and runs on other branches. It says nothing about review of the commits on `main`. That's the job of the ruleset on `main`, the named list of rules for that branch.

## MENTAL MODEL

A picture helps.

**Analogy,** from the textbook. An environment is the locked door of a server room with its own key cabinet inside. The job is a technician. The door has rules: someone must sign the visitor in, the visitor must come from a known department, there may be a waiting period. The keys in the cabinet are only reachable after the door has opened.

The analogy breaks in one place, and it's the place that matters in an audit: the door is guarded by GitHub, not by the server room. If your cloud account also accepts credentials from somewhere else, the environment protects nothing.

**[ANIMATION]** cards: id=gate3 question=The_gate_is_a_combination_of_three_things cards=a_ruleset:changes_to_main_only_through_reviewed_pull_requests|an_environment:accepts_only_main|a_required_reviewer marks=1:lock,2:lock,3:lock at_1=28 at_2=45 at_3=58 at_marks=72

**[ANIMATION]** step: marks

Now the sentence I promised, the one to say to a CTO. The gate is a combination of three things. A ruleset that forces changes to `main` through reviewed pull requests. An environment that accepts only `main`. And a required reviewer. In the textbook's words: remove any one and there is a path around the other two.

**[ANIMATION]** walk: id=around columns=without,the_path_around rows=the_ruleset:anyone_can_push_to_main,_and_the_branch_rule_is_satisfied|the_branch_rule:a_run_on_any_branch_can_ask_for_approval|the_reviewer:every_merge_deploys_on_its_own|the_bypass_switched_off:administrators_can_bypass_the_rules|a_credential_bound_to_the_environment:it_also_works_from_a_laptop marks=1.2:bad,2.2:bad,3.2:bad,4.2:wait,5.2:wait mono=off title=Remove_any_one_and_there_is_a_path_around at_1=3 at_2=35 at_3=75

**[ANIMATION]** step: 3

Without the ruleset, anyone can push to `main` and the branch rule is satisfied. Without the branch rule, a run on any branch can ask for approval, or with no reviewer, deploy. Without the reviewer, every merge deploys on its own.

**[ANIMATION]** step: 5

And two more conditions from section 20B.17 that sit outside all three. Administrators can bypass protection rules unless that is switched off, and whoever can edit the environment can remove the rule. And the credential itself must be bound to the environment at the cloud provider, or it also works from a laptop.

## DIAGRAM

**[DIAGRAM]** The picture of section 20B.2. Draw the three boxes left to right. For the middle box write "rules: none", and for the right box list the rules. Then write into the right box what the job does while the rules are unmet.

```text
 push to main
      |
      v
 +-----------+      +--------------------+      +------------------------+
 |  build    | ---> | deploy-staging     | ---> | deploy-production      |
 |  (runner) |      | environment:       |      | environment:           |
 +-----------+      |   staging          |      |   production           |
                    | rules: none        |      | rules: reviewers,      |
                    | job starts at once |      |   branch = main        |
                    +--------------------+      | job WAITS, no runner,  |
                                                | no secrets, until all  |
                                                | rules pass             |
                                                +------------------------+
```

Three boxes, and the security argument is in the right one. While the production job waits, there's no runner and there are no secrets.

**[DIAGRAM]** Three words in the right box carry the security argument: no runner, no secrets. While the job waits, no machine exists that holds the production credential.

**[ON SCREEN]** The root-cause box of section 20B.4, one line at a time. Observed behavior: a job that names "production" started without waiting for anybody. Git state: irrelevant; the workflow file names the environment correctly. Mechanism: protection rules are properties of the environment object on GitHub; the environment had been created by the first run that named it, with no rules; or the repository is private on a plan where reviewers do not apply. Root cause: the gate was assumed from the YAML and never configured or verified. Why GitHub does it: naming a missing environment creates it, so that a first deployment works without an administrator; rules are an administrator's decision. Correct fix: configure the rules; read them back with a `gh api` call on the environment. Prevention: create environments before the workflow that uses them; keep their configuration in a reviewed script; test the gate with a harmless run.

Read the root-cause line: the gate was assumed from the YAML and never configured or verified.

## LIVE TERMINAL DEMO

Into the lab.

**[TERMINAL]** Three lab replays, all Git, all in the sandbox. The IDs equal the book's.

**Step 1: the same bytes.** Replay `labs/run ch20b/lab-27-2-artifact-digest`.

```bash
git archive --format=tar --prefix=warehouse-api/ HEAD | shasum -a 256
git archive --format=tar --prefix=warehouse-api/ HEAD | shasum -a 256
git archive --format=tar --prefix=warehouse-api/ v1.1.0 | shasum -a 256
```

`git archive` only reads the repository, and it writes an archive to standard output. The digest of a file is a fingerprint computed from its bytes.

Three digests. Which are equal? Say it out loud.

**[PAUSE]**

<!-- snippet: ch20b/lab-27-2-artifact-digest/01-same-bytes -->
```text
$ git archive --format=tar --prefix=warehouse-api/ HEAD | shasum -a 256
28e6e91f0be5134ce817c81ab4dfb7e7e0ac69ac7cd756cb8859f27c4746d1e2  -
$ git archive --format=tar --prefix=warehouse-api/ HEAD | shasum -a 256
28e6e91f0be5134ce817c81ab4dfb7e7e0ac69ac7cd756cb8859f27c4746d1e2  -
$ git archive --format=tar --prefix=warehouse-api/ v1.1.0 | shasum -a 256
1581f1ac4facda70544419ab7165fd84af4c05ce715e387aa9c44d4a38eddd44  -
```
<!-- /snippet -->

The first two are equal, because `git archive` of one commit is deterministic. The third differs, because `v1.1.0` is another commit. A build tool isn't always this reproducible. That's the reason to move the built file between jobs and not to rebuild it.

<!-- snippet: ch20b/lab-27-2-artifact-digest/02-failure -->
```text
$ git archive --format=tar --prefix=warehouse-api/ -o ../build.tar HEAD
$ (cd .. && shasum -a 256 build.tar > build.tar.sha256)
# Something between the build job and the deploy job changes one byte:
$ printf 'x' >> ../build.tar
$ (cd .. && shasum -a 256 -c build.tar.sha256)
build.tar: FAILED
shasum: WARNING: 1 computed checksum did NOT match
[exit status: 1]
```
<!-- /snippet -->

One byte appended between "build" and "deploy". The recorded digest no longer matches: FAILED, exit status 1. This is what the download action's digest check does for you.

<!-- snippet: ch20b/lab-27-2-artifact-digest/03-recovery -->
```text
# Do not repair the file. Produce it again from the commit and compare.
$ git archive --format=tar --prefix=warehouse-api/ -o ../build.tar HEAD
$ (cd .. && shasum -a 256 -c build.tar.sha256)
build.tar: OK
[exit status: 0]
```
<!-- /snippet -->

And the recovery has a rule in its comment: don't repair the file. Produce it again from the commit and compare.

**Step 2: what a deployment contains.** Replay `labs/run ch20b/lab-27-3-deploy-range`. Staging runs `v1.1.0`. A push to `main` is about to deploy the tip of `main`.

```bash
git log --oneline v1.1.0..main
git diff --stat v1.1.0 main
```

A two-dot range, from what is deployed to what will be deployed. It lists the commits reachable from the second name and not from the first. What does it list here? Make your prediction.

**[PAUSE]**

<!-- snippet: ch20b/lab-27-3-deploy-range/01-range -->
```text
# Staging runs v1.1.0. A push to main is about to deploy the tip of main.
$ git log --oneline v1.1.0..main
57c8425 Add the lock file
197d992 Document the release runbook
$ git diff --stat v1.1.0 main
 docs/runbook.md | 4 ++++
 uv.lock         | 6 ++++++
 2 files changed, 10 insertions(+)
$ ./scripts/deploy.sh staging
would deploy 57c8425 to staging
```
<!-- /snippet -->

Two commits and two files: a runbook and a lock file. That's the question "what am I about to ship?", answered with a range, and the textbook says it's worth one line in every deployment's job summary. The script would deploy `57c8425`.

**Step 3: going backwards.**

```bash
git switch --quiet --detach v1.1.0
./scripts/deploy.sh staging
git merge-base --is-ancestor HEAD main
git log --oneline HEAD..main
```

Try it now, on paper. Thirty seconds. Draw three commits in a row, with `v1.1.0` under the first and `main` under the last. Now somebody re-runs an old workflow run. A re-run uses the commit of the original run, and the replay imitates that by detaching HEAD on the old tag. Mark HEAD on your drawing. What would the script deploy, and how do you ask Git whether that is behind what staging already has?

**[PAUSE]**

<!-- snippet: ch20b/lab-27-3-deploy-range/02-failure -->
```text
# Somebody re-runs an old workflow run. A re-run uses the commit of the original run:
$ git switch --quiet --detach v1.1.0
$ ./scripts/deploy.sh staging
would deploy c4b5de2 to staging
# Is that commit behind what staging already had? (exit status 0 means yes)
$ git merge-base --is-ancestor HEAD main
[exit status: 0]
$ git log --oneline HEAD..main
57c8425 Add the lock file
197d992 Document the release runbook
```
<!-- /snippet -->

It would deploy `c4b5de2`, the old commit. `git merge-base --is-ancestor HEAD main` exits with 0: yes, the commit to be deployed is an ancestor of what is there. And the log shows the two commits that would be taken away.

**[ANIMATION]** graph: id=rerun ...older-c4b5de2-197d992-57c8425 main; c4b5de2 v1.1.0; HEAD=main => ...older-c4b5de2-197d992-57c8425 main; c4b5de2 v1.1.0; HEAD=c4b5de2 title=A_re-run_is_a_time_machine

**[ANIMATION]** step: state-1

Compare it with your drawing. Three commits, the tag `v1.1.0` under the first, and `main` under the last.

**[ANIMATION]** step: state-2

Now HEAD sits on the old tag, two commits behind `main`. Section 20B.17 has a name for this: a re-run is a time machine. On a deploy workflow it's a rollback nobody announced.

<!-- snippet: ch20b/lab-27-3-deploy-range/03-recovery -->
```text
$ git switch --quiet main
$ ./scripts/deploy.sh staging
would deploy 57c8425 to staging
$ git merge-base --is-ancestor v1.1.0 HEAD
[exit status: 0]
```
<!-- /snippet -->

The guard is the same command with the arguments in the other order: is what is deployed an ancestor of what I am about to deploy? Exit status 0 means forwards. A deploy script that runs that test and refuses on any other status can't go backwards by accident. Exercise 27.4 has you write it.

**Step 4: what an approval releases.** Replay `labs/run ch20b/lab-27-4-promotion`. Two refs under `refs/deployed/` stand in for GitHub's deployment records. They're the author's bookkeeping for the demonstration. GitHub keeps deployments as platform objects, not as refs.

```bash
git for-each-ref --format="%(refname) %(objectname:short)" refs/deployed
git log --oneline refs/deployed/production..refs/deployed/staging
```

<!-- snippet: ch20b/lab-27-4-promotion/01-waiting -->
```text
$ git for-each-ref --format="%(refname) %(objectname:short)" refs/deployed
refs/deployed/production c4b5de2
refs/deployed/staging 57c8425
# What an approval of the production job would release:
$ git log --oneline refs/deployed/production..refs/deployed/staging
57c8425 Add the lock file
197d992 Document the release runbook
```
<!-- /snippet -->

Production is at `c4b5de2`, staging at `57c8425`.

**[ANIMATION]** graph: id=promo ...older-c4b5de2-197d992-57c8425 main; c4b5de2 special:refs/deployed/production; 57c8425 special:refs/deployed/staging; HEAD=none; range:197d992,57c8425:production..staging; title:What_an_approval_releases; say:An_approval_would_release_these_two_commits => + ^57c8425-e39e6de hotfix/lead-days; HEAD=hotfix/lead-days; range:; name:hotfix; title:The_fix_goes_through_main; say:The_ref_is_refs/heads/hotfix/lead-days:_the_fix_is_not_contained_in_main => + 57c8425-fe34a26 main; e39e6de-fe34a26; HEAD=main; range:197d992,57c8425,e39e6de,fe34a26:production..main; name:merged; say:Through_main:_the_range_from_production_to_main_lists_four_commits dx=230 at_state_1=10 at_hotfix=0

**[ANIMATION]** step: state-1

An approval of the production job would release the two commits between them. That's what a reviewer should read before choosing "approve".

**[ANIMATION]** end

**Step 5: the hotfix that wants a shortcut.**

```bash
git switch --quiet hotfix/lead-days
git symbolic-ref HEAD
test "$(git symbolic-ref HEAD)" = refs/heads/main
git merge-base --is-ancestor HEAD main
```

An urgent fix on a branch. The rule on production says: selected branches, `main`.

A branch rule looks at one fact. Which of these commands computes that fact? Say it out loud.

**[PAUSE]**

<!-- snippet: ch20b/lab-27-4-promotion/02-failure -->
```text
# An urgent fix on a branch. The rule on production says: selected branches, main.
$ git switch --quiet hotfix/lead-days
$ git symbolic-ref HEAD
refs/heads/hotfix/lead-days
$ test "$(git symbolic-ref HEAD)" = refs/heads/main
[exit status: 1]
$ git merge-base --is-ancestor HEAD main
[exit status: 1]
```
<!-- /snippet -->

The ref is `refs/heads/hotfix/lead-days`, so the comparison with `refs/heads/main` fails. The second test shows that the commit isn't contained in `main` either. The branch rule looks at the first fact only: the name of the ref the run was started for.

<!-- snippet: ch20b/lab-27-4-promotion/03-recovery -->
```text
# The fix reaches production the way everything else does: through main.
$ git switch --quiet main
$ git merge --quiet --no-ff -m "Merge hotfix/lead-days" hotfix/lead-days
$ git symbolic-ref HEAD
refs/heads/main
$ git merge-base --is-ancestor hotfix/lead-days main
[exit status: 0]
$ git log --oneline refs/deployed/production..main
fe34a26 Merge hotfix/lead-days
e39e6de Raise the lead time to seven days
57c8425 Add the lock file
197d992 Document the release runbook
```
<!-- /snippet -->

The comment in the transcript is the policy: the fix reaches production the way everything else does, through `main`. `git merge --no-ff` is 🟡 CAUTION: it moves the current branch.

**[ANIMATION]** step: promo.hotfix

Before the merge, HEAD is on the hotfix branch, and the fix, `e39e6de`, isn't contained in `main`.

**[ANIMATION]** step: promo.merged

After the merge the ref is `main`, the hotfix is an ancestor, and the range from production to `main` now lists four commits, with the merge `fe34a26` on top.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthroughs.

**On your practice repository, in your normal shell.** The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors. Never show a real secret value.

Lab 27.3. Create the `staging` environment before you add workflow 8, set its variable and its secret with a made-up value, and read both back with the listing commands. Then add the workflow. After the push to `main`, open the run: find the two jobs and the order between them. Open the repository's list of deployments and find the record for `staging` with the commit it names.

Lab 27.4. Add the reviewer and the branch rule to `production`, then read the environment back before you rely on it. Add workflow 9. After the next push to `main`, open the run and find the production job in its waiting state. Before you approve, run the range command in your clone and say aloud what you are approving. Then approve, and afterwards try the lab's failure case, a run from another branch, and see where it stops.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Assuming a gate from the line `environment: production`.** Root cause: protection rules are properties of the environment object on GitHub, and naming a missing environment creates it without any rule.
2. **A misspelled environment name.** Root cause: the misspelling names a new, unprotected environment; there is no error.
3. **Rebuilding in the deploy job.** Root cause: a second build is not guaranteed to produce the same bytes, so the deployed thing is not the tested thing.
4. **Re-running an old deploy run.** Root cause: a re-run uses the commit of the original run, so it deploys old code over new.
5. **Treating the environment as the only production control.** Root cause: it is enforced by GitHub, and credentials that also work from elsewhere bypass it.

## PRODUCTION EXAMPLE

**[ANIMATION]** gates: id=prod packet=a_job_on_a_feature_branch gates=accepts_only_main:stop:environment_production:the_branch_rule_fails|one_approval,_no_self-review:skip:environment_production|the_production_role:skip:the_cloud_account result=no_runner_started title=The_gate_did_its_work

**[ANIMATION]** step: setup

Now, out of the lab. The textbook's case: a team serving an LLM application keeps two cloud roles. One can update the staging service, and one can update production. The production role's credentials are reachable only from the `production` environment, which requires one approval from the on-call group, prevents self-review and accepts only `main`.

**[ANIMATION]** step: result

An engineer edits a workflow on a feature branch to "quickly deploy". The job fails the branch rule before any runner starts. The textbook's remark: the gate did its work without anybody reading the diff.

**[ANIMATION]** end

And the next layer, which Part 7 covers: with federated credentials the same idea is enforced by the cloud provider as well, because the token's subject names the environment.

## PRACTICE EXERCISE

Your turn. Do Lab 27.3, "Deploy to staging (workflow 8)", in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md).

Before the push that starts the deployment, run the range from the last deployed commit to the tip of `main` and write down which commits and files the deployment contains. Then predict what will exist on GitHub after the run: how many jobs, how many artifacts, and which deployment record.

The challenge is Exercise 27.2, "A deployment with five flaws", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q303: "A job names `environment: production`. List everything that must be true on GitHub, outside the workflow file, for that to be a real gate."

**[PAUSE]**

Answer out loud. A strong answer is a list, and every item is a GitHub object or setting, not a line of YAML: that the environment exists under exactly that name, which rules it has, what plan and visibility make those rules available, who can bypass and who can edit them, where the credential lives, and what protects the branch the environment accepts. Say how you would read each item back as evidence. The follow-up assumes all of it is in place and asks for the remaining ways around the approval. Think about re-runs, about who can change the environment, and about credentials that work from somewhere else.

## RECAP

Let's land this.

You should now be able to say:

- An environment is a GitHub object; its rules must pass before the job is sent to a runner, and its secrets are readable only after that.
- Naming an environment that does not exist creates it without rules, so a gate must be configured and read back, not assumed from YAML.
- Build once and pass the artifact: the bytes that were tested are the bytes that ship, checked by a digest.
- What a deployment contains is the two-dot range from the deployed commit to the new one, and a deploy script should refuse unless the old commit is an ancestor of the new.
- The gate is a ruleset on `main`, an environment that accepts only `main`, and a required reviewer; remove any one and there is a path around the other two.

## HOMEWORK

Read sections 20B.1 to 20B.4 of [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md). Do Lab 27.4, "Staging, then production behind an approval (workflow 9)", in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md). Then do Exercise 27.1, "An environment, read back", and Exercise 27.4, "A guard against going backwards", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

You can now say where a production gate really lives, and how to read it back as evidence. Try the range command once before your next real deployment. Next time: concurrency groups, reusable workflows, composite actions, and container actions. Until then, look at the state first and type second. See you in the next one.
