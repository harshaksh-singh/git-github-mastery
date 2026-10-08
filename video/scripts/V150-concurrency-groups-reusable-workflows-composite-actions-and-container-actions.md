# V150: Concurrency groups, reusable workflows, composite actions and container actions

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 27
- **Planned minutes.** 24
- **Prerequisites.** V149
- **Textbook sections.** [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), sections 20B.5 and 20B.6
- **Demo scripts.** `labs/ch20b/lab-27-5-reusable-ref.sh`, with one snippet of `labs/ch20b/lab-28-1-broken-workflows.sh`; the files [`11-caller.yml`](../../workflows/11-caller.yml) and [`11-reusable-workflow.yml`](../../workflows/11-reusable-workflow.yml); a screen walkthrough of Lab 27.5 in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md)

## HOOK

**[ON SCREEN]** A timeline: three merges on `main` at 10:00, 10:02 and 10:04. One deploy workflow. One line in it: `concurrency: production`.

The release manager looks at the deployment history in the afternoon and finds two deployments, not three. A deployment is one delivery of the software to a live system, and here each merge to `main` starts a run of the deploy workflow. The second merge was never deployed on its own. Nobody cancelled anything by hand.

**[ANIMATION]** walk: id=sym columns=in_the_deployment_history,merge_on_main_at rows=a_deployment:10:00|never_deployed_on_its_own:10:02|a_deployment:10:04 marks=2.1:wait mono=off title=Three_merges,_two_deployments at_1=5 at_2=15 at_3=25

Was a change lost? Is the pipeline broken? Before you answer, you need to know what a concurrency group does by default with a run that is waiting when another one arrives. The answer is one sentence in the workflow syntax reference, and most teams have never read it. Keep those three merges in mind. They come back, as trains.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A workflow is a file that tells GitHub Actions which jobs to run when an event happens. A job is a list of steps on one fresh machine, the runner, and a run is one execution of a workflow. In the last video the production job had a block you were asked to accept for the moment: a concurrency group named `production` with `cancel-in-progress: false`. This video explains it, and then turns to a different question that every growing organization meets: how do forty repositories share one deployment procedure without copying it forty times?

Two topics. Concurrency groups: one name, at most one run at a time, and a rule for everyone else. And reuse: reusable workflows, composite actions and Docker container actions, which differ in what they replace. The reusable workflow gets the most time, because it's the one that changes the names of your required checks and the path of your secrets. A required check is a result that a rule says must pass before a merge, and a secret is an encrypted value stored in GitHub's settings.

The local demonstration is short and makes one point with Git: which version of a reusable workflow a caller runs.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- predict which of several queued runs deploy under a concurrency group, with and without cancellation;
- choose between a reusable workflow, a composite action and a container action;
- explain what each choice does to the names of required checks;
- say why a caller cannot pass an environment secret to a reusable workflow and where it must be read;
- explain which version of a reusable workflow a caller runs.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**Concurrency. In one sentence:** a concurrency group is a name. GitHub lets at most one run or job with that name execute at a time and decides what happens to the others.

**Precisely,** from the workflow syntax.

`concurrency` can be set for the whole workflow or for one job. Its value is a group name, or a mapping with `group`, `cancel-in-progress` and `queue`.

The default behavior: when a run is queued and another run in the same group is in progress, the new one is pending, and any run already pending in that group is cancelled. So by default at most one runs and one waits.

Quick quiz. Three runs arrive in one group, one after another, with the default settings. How many of them finish? A, all three. B, two. C, only the last one. Your answer?

**[PAUSE]**

**[ANIMATION]** walk: id=three columns=run,when_it_is_queued,what_happens rows=run_1:in_progress:it_finishes|run_2:pending:cancelled_when_run_3_is_queued|run_3:pending:it_waits,_then_runs marks=1.3:ok,2.3:bad,3.3:ok mono=off title=One_group,_three_runs,_the_default at_1=12 at_2=35 at_3=65

B, two. The first is in progress and finishes. The second is pending, and it's cancelled when the third is queued. The third waits, and then runs. If you said A, you're in good company.

**[ANIMATION]** end

`cancel-in-progress: true` also cancels the run in progress. It may be an expression.

`queue: max`, since the seventh of May 2026, keeps up to 100 pending runs and processes them in order. Combining it with `cancel-in-progress: true` is a validation error.

The group expression may use only the `github`, `inputs` and `vars` contexts at workflow level. A context is a named object of facts about a run. A job-level group may also use `needs`, `strategy` and `matrix`.

Group names are case-insensitive, and a group isn't private to a workflow: two workflows that use the group name `deploy` share one track.

And the documentation states that ordering isn't guaranteed.

Two patterns cover most needs, and they want opposite settings.

**[ON SCREEN]** The two blocks of section 20B.5.

```yaml
# Continuous integration: only the newest commit of a branch or pull request matters.
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

```yaml
# Deployment: never interrupt one, never run two at once.
concurrency:
  group: production
  cancel-in-progress: false
```

The first includes the workflow name and the ref, so that only runs of the same workflow on the same ref compete. The second is deliberately the same for every ref. Workflow 8 uses the second form for the whole workflow. Workflow 9 uses one group per environment at job level, so that a staging deployment doesn't wait for a production approval.

Why never `cancel-in-progress: true` on a deployment? Section 20B.17: a deployment cancelled half-way leaves a state nobody designed.

One more sentence from the documentation that people assume the opposite of: `concurrency` and `environment` aren't connected. An environment doesn't serialise anything by itself.

**Reuse.** Three mechanisms remove duplication. They differ in what they replace.

**[ON SCREEN]** The comparison table of section 20B.6.

A reusable workflow replaces one or more whole jobs. It's a workflow file with `on: workflow_call`, called with `uses` at job level. It chooses its own runners. It can name an environment. Its secrets are declared in its interface, or passed with `secrets: inherit`. In the log it shows as separate jobs.

A composite action replaces several steps inside a job. It's an `action.yml` with `runs.using: "composite"`, called with `uses` at step level. It runs on the caller's runner. It can't name an environment. It can't read the `secrets` context, so values are passed as inputs. In the log it's one step.

A Docker container action replaces one step. It's an `action.yml` with `runs.using: "docker"`. It needs a Linux runner, and the documentation notes it's slower than the other kinds, because the image is built or pulled first.

**Reusable workflows, in one sentence:** a reusable workflow is a workflow file that another workflow calls as if it were a single job.

**[ON SCREEN]** `11-reusable-workflow.yml`, the interface; then `11-caller.yml`.

The called file declares its interface under `on.workflow_call`: two inputs, each with a type, one secret, and one output, mapped from a job output.

**[ANIMATION]** stores: id=cross boxes=11-caller.yml:the_caller|*11-reusable-workflow.yml:on.workflow__call rows=1:B:two_inputs,_each_with_a_type|1:B:one_secret|1:B:one_output,_from_a_job_output|2:A:job_staging:_uses,_with,_secrets|3:A:a_second_job_needs_staging|4:B:an_environment_secret_is_read_here@hl|5:A:workflow-level_env_does_not_cross@bad|6:B:token_permissions:_only_narrower|7:B:github_context_and_billing:_the_caller's arrows=2:A1>B1:with,_secrets|3:B3>A2:the_output title=What_crosses_between_caller_and_called_file at_1=3 at_2=30 at_3=50

**[ANIMATION]** step: 2

The caller has a job named `staging` whose body is `uses`, `with` and `secrets`, and a second job that needs `staging` and reads its output.

The rules.

**[ANIMATION]** step: 3

Inputs have a type of boolean, number or string. Outputs are declared at workflow level and mapped from job outputs. The caller reads them through `needs` and the name of the calling job.

**[ANIMATION]** say: A_calling_job_has_uses,_with_and_secrets:_no_runs-on_and_no_steps

A calling job isn't a normal job. It may contain only a fixed set of keys, among them `name`, `uses`, `with`, `secrets`, `strategy`, `needs`, `if`, `concurrency` and `permissions`. It has no `runs-on` and no `steps`. No context or expression is allowed in `uses`.

**[ANIMATION]** say: ./_means_the_same_repository_at_the_commit_of_the_run

Where the file comes from. A path starting with `./` is the same repository at the commit of the run. The form with owner, repository, path and a ref after the at sign is another repository. Pin the ref to a full commit ID, for the reason every action is pinned. Since the thirtieth of July 2026 the documentation recommends a form starting with `$/` for the same repository on github.com. It needs runner 2.336.0 or later and doesn't exist on GitHub Enterprise Server. And files in subdirectories of `.github/workflows` can't be called.

**[ANIMATION]** step: 4

Secrets pass only one level: a workflow called by a called workflow needs them passed again. `secrets: inherit` passes all of the caller's secrets and works within one organization or enterprise. And environment secrets can't be passed by the caller, because, in the documentation's words, "`on.workflow_call` does not support the `environment` keyword". The called job names the environment. In workflow 11 the `deploy` job does that with the environment taken from an input. So an environment secret is read where the environment is named: in the called job.

**[ANIMATION]** step: 5

`env` doesn't cross. Variables in the caller's workflow-level `env` aren't visible in the called workflow. Use inputs, or configuration variables.

**[ANIMATION]** step: 6

Permissions only narrow. The called workflow's token permissions can be reduced, not raised, relative to the caller's.

**[ANIMATION]** step: 7

The `github` context is the caller's: event, ref, commit and `github.workflow`. Billing is the caller's too.

Limits: up to ten levels of workflows, and at most 50 unique reusable workflows called from one workflow file, since the sixth of November 2025.

**[ANIMATION]** cards: id=name question=The_check_of_a_job_in_a_called_workflow cards=Staging:the_calling_job's_name|Test,_build_and_deploy:the_called_job's_name say_2=Staging_/_Test,_build_and_deploy at_1=30 at_2=45

And check names. A required status check for a job in a called workflow is named with the calling job's name, a slash, and the called job's name. With the two course files, the check is "Staging / Test, build and deploy". Renaming either job silently breaks a rule that requires the old name.

**[ANIMATION]** end

**[ON SCREEN]** Callout: Unverified. How secrets of the environment that a called job names appear in that job when the caller passes named secrets and does not use `secrets: inherit` is not spelled out on the pages read for the chapter. Workflow 11 avoids the question: the caller passes a repository secret, and the called file documents it. Verify the behavior in your repository before you depend on it.

One point is unverified, and it's on screen now. How the secrets of an environment that a called job names appear in that job, when the caller passes named secrets and doesn't use `secrets: inherit`, isn't spelled out on the pages read for the chapter. Workflow 11 avoids the question. Verify the behavior in your repository before you depend on it.

**[ANIMATION]** pin: id=rerun A main; HEAD=none; note:A:the_first_attempt_ran_this_commit; title:A_called_workflow_referenced_as_@main => + A-B main; note:B:re-running_all_jobs_resolves_@main_again; name:moved; say:Re-running_failed_or_selected_jobs_stays_on_the_first_commit dx=420 at_moved=55

**Re-runs.** Re-running all jobs resolves a reference that's not a commit ID again. Re-running failed or selected jobs uses the same commit of the called workflow as the first attempt. A reusable workflow referenced as `@main` can therefore differ between a first run and a full re-run.

**[ANIMATION]** end

**Composite actions.** The documented rules that differ from workflow steps. Every `run` step must state its `shell`. Inputs are read through the `inputs` context. Outputs need a `value` that maps to a step output. The `secrets` context isn't available. And the parallel-step keywords of June 2026 can't be used inside one. In the log the whole action is one step, which makes a failure inside it harder to locate than the same steps written out.

**[ANIMATION]** walk: id=which columns=what_repeats,use rows=steps_inside_jobs:a_composite_action|a_whole_job,_or_one_that_needs_an_environment,_a_runner_choice_or_secrets:a_reusable_workflow|a_tool_that_needs_its_own_operating_system_environment:a_container_action|two_short_blocks_in_one_file:YAML_anchors_or_plain_repetition mono=off title=Which_one? at_1=8 at_2=25 at_3=50 at_4=72

**Which one.** The textbook's rule. Steps that repeat inside jobs: a composite action. A whole job, or a job that needs an environment, a runner choice or secrets: a reusable workflow. A tool that needs an operating system environment you don't want on the runner: a container action. And neither, when the duplication is two short blocks in one file: YAML anchors or plain repetition are easier to read and to debug.

## MENTAL MODEL

A picture helps, and this one has trains.

**[ANIMATION]** stores: id=rail boxes=the_track:one_run_in_progress|the_siding:one_run_pending|sent_away:cancelled rows=1:A:merge_one|2:B:merge_two|3:C:merge_two,_when_merge_three_arrives@bad|3:B:then_merge_three|4:A:then_merge_three@ok title=A_single_track_with_one_siding at_1=12 at_2=22 at_3=32 at_4=50

**[ANIMATION]** step: boxes

**Analogy for concurrency,** from the textbook. A single-track railway section with one waiting siding. One train is on the track. A second train waits in the siding. If a third arrives, the second is sent away and the third takes the siding. With `cancel-in-progress: true`, the arriving train also removes the one on the track.

The analogy breaks with `queue: max`, which turns the siding into a yard for up to 100 trains.

**[ANIMATION]** step: 4

Now run the three merges from the opening through it. Merge one is on the track. Merge two waits in the siding. Merge three arrives, merge two is sent away, and merge three takes the siding. Two deployments, and that's the release manager's afternoon, explained. Is anything lost? Usually not, because the third run's commit contains the second merge. It's not fine when each run must happen, for example a database migration per commit. Then you use `queue: max`, or you design the deployment to be cumulative.

**[ANIMATION]** end

**Analogy for a reusable workflow.** A subcontractor who brings a whole crew, their own tools and their own site rules, and works to a written order, which is the inputs. You can't give the crew individual instructions. You can only place the order and read the delivery note, which is the outputs.

The textbook says it breaks on trust: the subcontractor works with your access badge, and can use less of its access than you gave, never more. That is "permissions only narrow", and "the `github` context is the caller's".

## DIAGRAM

**[DIAGRAM]** The picture of section 20B.5: default behavior, three pushes in quick succession into one group. Draw run 1 as a long bar. Add run 2 as pending. Then ask what happens to run 2 when run 3 is queued, and only then draw the cross.

```text
 time --->
 run 1  [=========== in progress ===========]
 run 2        [ pending ]--X  cancelled when run 3 is queued
 run 3              [ pending .............][=== in progress ===]
```

Try it now, on paper. Thirty seconds. Copy these three bars. Then draw them again for `cancel-in-progress: true`. Which runs finish now?

**[PAUSE]**

**[ANIMATION]** walk: id=vars columns=run_1,run_2,run_3,with rows=finishes:cancelled:finishes:the_default|cancelled:cancelled:finishes:cancel-in-progress:_true|finishes:finishes:finishes:queue:_max marks=1.2:bad,2.1:bad,2.2:bad mono=off title=Three_runs_in_one_group at_1=3 at_2=20 at_3=50

Only run 3. Run 1 is cancelled when run 2 arrives, and run 2 when run 3 arrives.

**[DIAGRAM]** One running, one pending, one cancelled. Then redraw it in your head for the two variations. With `cancel-in-progress: true`: run 1 is cancelled when run 2 arrives, and run 2 when run 3 arrives; only run 3 finishes. With `queue: max`: nothing is cancelled, and the three run one after another.

So the default once more: one running, one pending, one cancelled. Redraw it in your head for queue: max. Nothing is cancelled, and the three run one after another.

## LIVE TERMINAL DEMO

Into the lab.

**[TERMINAL]** Two short pieces, both Git in the sandbox.

**Step 1: what makes groups distinct.** One snippet from the replay `labs/run ch20b/lab-28-1-broken-workflows`, which video 154 uses in full.

```bash
git for-each-ref --format="%(refname)" refs/heads
```

<!-- snippet: ch20b/lab-28-1-broken-workflows/03-refs -->
```text
# Workflow 5. Each of these refs gets pushes; a concurrency group should tell them apart:
$ git for-each-ref --format="%(refname)" refs/heads
refs/heads/docs/rollback-steps
refs/heads/feature/safety-stock
refs/heads/main
```
<!-- /snippet -->

Three branches, each of which gets pushes. A workflow's group is named `ci`, with `cancel-in-progress: true`. A colleague pushes to `docs/rollback-steps` while your run on `feature/safety-stock` is in progress. What happens to your run? Say it out loud.

**[PAUSE]**

**[ANIMATION]** walk: id=tracks columns=a_push_to,group_ci,a_group_with_github.ref rows=refs/heads/docs/rollback-steps:the_one_shared_track:its_own_track|refs/heads/feature/safety-stock:the_one_shared_track:its_own_track|refs/heads/main:the_one_shared_track:its_own_track marks=1.2:bad,2.2:bad,3.2:bad,1.3:ok,2.3:ok,3.3:ok title=What_makes_groups_distinct pace=quick

It's cancelled. A group named `ci` gives all three refs one track. A group that contains `github.ref` gives each its own. Section 20B.16 lists exactly this symptom: CI runs of different branches cancel each other, because the group lacks the ref.

**[ANIMATION]** end

**Step 2: which version of a reusable workflow runs.** Replay `labs/run ch20b/lab-27-5-reusable-ref`.

```bash
git ls-files .github/workflows
git grep -n "uses:" main -- .github/workflows/deploy.yml
git diff --stat main ci/python-version
git grep -c "python-version" main ci/python-version -- .github/workflows/reusable-deploy.yml
```

All four read. The repository has a caller, `deploy.yml`, and a called file, `reusable-deploy.yml`. A branch, `ci/python-version`, adds an input to the called file.

`git grep -c` counts matches per ref. For which of the two refs will it print a line? Make your prediction.

**[PAUSE]**

<!-- snippet: ch20b/lab-27-5-reusable-ref/01-two-versions -->
```text
$ git ls-files .github/workflows
.github/workflows/deploy.yml
.github/workflows/reusable-deploy.yml
$ git grep -n "uses:" main -- .github/workflows/deploy.yml
main:.github/workflows/deploy.yml:9:    uses: ./.github/workflows/reusable-deploy.yml
$ git diff --stat main ci/python-version
 .github/workflows/reusable-deploy.yml | 4 ++++
 1 file changed, 4 insertions(+)
$ git grep -c "python-version" main ci/python-version -- .github/workflows/reusable-deploy.yml
ci/python-version:.github/workflows/reusable-deploy.yml:1
```
<!-- /snippet -->

Only for the branch.

**[ANIMATION]** stores: id=vers boxes=main:the_commit_of_the_run|ci/python-version:the_branch rows=1:A:deploy.yml_uses_./.github/workflows/reusable-deploy.yml|1:A:reusable-deploy.yml:_no_python-version|1:B:reusable-deploy.yml_declares_python-version@hl|2:A:deploy.yml_now_passes_python-version@bad|3:A:after_the_merge:_both_files_mention_it@ok arrows=3:B1>A4:merge title=Caller_and_called_file,_from_the_same_commit at_1=10

**[ANIMATION]** step: 1

The caller on `main` uses the `./` form, which means: the called file from the same commit as the caller. So a branch that changes the called file tests its own version, and `main` keeps using the old one until the merge.

**Step 3: caller and called file disagree.**

```bash
printf '      python-version: "3.13"\n' >> .github/workflows/deploy.yml
git commit -q -am "Deploy with Python 3.13"
git grep -c "python-version" HEAD -- .github/workflows/reusable-deploy.yml
```

`git commit` adds an object and moves the branch. On `main`, the caller starts passing the new input.

Does the called file on `main` declare that input? Make your prediction.

**[PAUSE]**

<!-- snippet: ch20b/lab-27-5-reusable-ref/02-failure -->
```text
# On main, the caller starts passing an input that the called file on main does not declare:
$ printf '      python-version: "3.13"\n' >> .github/workflows/deploy.yml
$ git commit -q -am "Deploy with Python 3.13"
$ git show HEAD:.github/workflows/deploy.yml | tail -n 4
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: staging
      python-version: "3.13"
$ git grep -c "python-version" HEAD -- .github/workflows/reusable-deploy.yml
[exit status: 1]
```
<!-- /snippet -->

Exit status 1: no match.

**[ANIMATION]** step: vers.2

The caller on `main` now passes an input that the called file on `main` doesn't declare. You found the disagreement with `git grep`, before any run.

<!-- snippet: ch20b/lab-27-5-reusable-ref/03-recovery -->
```text
# Caller and called file must agree in the same commit. Bring the declaration to main:
$ git merge --quiet --no-ff -m "Merge ci/python-version" ci/python-version
$ git grep -c "python-version" HEAD -- .github/workflows
HEAD:.github/workflows/deploy.yml:1
HEAD:.github/workflows/reusable-deploy.yml:1
```
<!-- /snippet -->

The recovery brings the declaration to `main` with a merge. `git merge --no-ff` is 🟡 CAUTION. Now both files mention the input in the same commit.

**[ANIMATION]** step: vers.3

The rule from the textbook: caller and called file must agree in one commit when they live in one repository, and across a pinned ref when they don't.

**[ANIMATION]** end

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough.

**Lab 27.5 on your practice repository, in your normal shell.** The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

Add the two files of workflow 11. After the run, open it and look at the list of jobs. Find the job that came from the called workflow and read its full name: it should be composed of two names, as the documentation describes. Write that name down exactly, because it's the name a ruleset would have to require. Then open the summary and find the revision that the second job wrote: one string that crossed from the called workflow to the caller as an output.

Then the lab's failure case: change the called file on a branch and open a pull request. Ask yourself before you look: which version of the called file does this pull request's run use?

## COMMON MISTAKES

Five mistakes to watch for.

1. **A CI group without the ref.** Root cause: a group is a name shared by everything that uses it, so runs of different branches cancel each other.
2. **Expecting every queued deployment to run.** Root cause: by default a newly queued run cancels the run already pending in the group.
3. **`cancel-in-progress: true` on a deployment.** Root cause: the run in progress is cancelled half-way and leaves a state nobody designed.
4. **An empty secret in a called workflow.** Root cause: secrets pass one level only, and an environment secret cannot be passed by the caller; it is read in the job that names the environment.
5. **Renaming a job after extracting a reusable workflow.** Root cause: the check is named from the calling job and the called job, so a rule that requires the old name waits for a check that no longer exists.

## PRODUCTION EXAMPLE

Now, out of the lab. The textbook's case: a platform team owns one deploy workflow in a central repository. Forty service repositories call it at a pinned commit and pass an environment name. A change to the deployment procedure is one reviewed pull request, rolled out by Dependabot updates of the pin.

Then the sentence that makes it a security design and not only a convenience: that one file runs with deployment credentials in forty repositories, so its repository needs the strictest ruleset in the organization.

And the trap the textbook attaches to concurrency in this setting. A called workflow sees the caller's name in `github.workflow`. So if the caller and the called workflow both use the group built from workflow name and ref, with `cancel-in-progress: true`, the called job cancels its own caller.

One counterweight from section 20B.17: don't extract a reusable workflow for two callers. Indirection costs debugging time, and the check name changes and can break required checks.

## PRACTICE EXERCISE

Your turn. Do Lab 27.5, "A reusable workflow and its caller (workflow 11)", in [`lab-manual/m27-build-package-deliver.md`](../../lab-manual/m27-build-package-deliver.md).

Before the first run, predict the exact name of the check that the called job will report. Before the failure case, predict which version of the called file the pull request's run uses.

The challenge is Exercise 27.5, "Four reusable-workflow surprises", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q286: "Three merges land on `main` within five minutes and the deploy workflow uses `concurrency: production`. Which runs deploy, and why?"

**[PAUSE]**

Answer out loud. A strong answer states the default rule first, in the documentation's terms: in progress, pending, and what happens to a pending run when another is queued. Then it walks the three runs through that rule on a timeline, and says whether anything was lost and under which condition that matters. The follow-up combines `queue: max` with `cancel-in-progress: true`. Say what GitHub does with that combination, and then judge each of the two settings separately for a deployment.

## RECAP

Let's land this.

You should now be able to say:

- A concurrency group allows one run in progress and, by default, one pending; a newly queued run cancels the one already pending.
- CI wants a group with workflow name and ref and cancellation; a deployment wants one fixed group and no cancellation.
- A reusable workflow replaces whole jobs, a composite action replaces steps, a container action replaces one step in its own image.
- A called job's check is named from the calling job and the called job, and an environment secret is read in the called job that names the environment.
- With the `./` form the called file comes from the same commit as the caller; across repositories the ref after the at sign decides, and it should be a commit ID.

## HOMEWORK

Read sections 20B.5 and 20B.6 of [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md). Do Exercise 27.3, "Three pushes in ten minutes", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

Three merges, two deployments, and you can now say why without opening a log. Draw the three bars once more from memory before the next video. Next time: publishing a container image, and release automation in outline. Until then, look at the state first and type second. See you in the next one.
