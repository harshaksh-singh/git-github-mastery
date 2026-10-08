# V143: Events and filters, contexts and expressions, and env, vars and secrets

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 26
- **Planned minutes.** 24
- **Prerequisites.** V064, V142
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), sections 20A.4 to 20A.6
- **Demo scripts.** `labs/ch20a/path-filter.sh`, `labs/ch20a/lab-26-5-path-filter.sh`, then a screen walkthrough of Lab 26.2 in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md) with [`workflows/02-lint.yml`](../../workflows/02-lint.yml)

## HOOK

**[ON SCREEN]** Question 3 of section 20A.1: "This workflow has a `paths` filter and is a required check. Why is the pull request waiting forever?"

A monorepo, one repository that holds several projects, with a Python service and a Java service. Each has its own workflow, the file that tells GitHub Actions what to run and when. Each workflow has a `paths` filter, so that a documentation change doesn't spend twenty runner minutes on Maven. Sensible. Then someone makes the Java workflow a required check, one that a rule says must pass before a merge. The next documentation pull request shows a check that's waiting, and it waits until somebody gives up. Why? Take a guess, out loud.

**[PAUSE]**

**[ANIMATION]** ci: id=ci pull_request result=skipped file=off job=off runner=off skip_text=the_paths_filter_matched_nothing steps=event,workflow,result say_result=No_run_exists,_and_the_required_check_waits_for_a_result_that_will_not_come title=Nothing_failed at_event=0 at_workflow=8 at_result=22

Nothing failed. The filter did what it was written to do: it decided that no run should exist. And a ruleset that requires a check waits for a result that won't come. To predict that before you push, you need to know how an event becomes a run, and that's this video. Keep that waiting pull request in mind. You'll rebuild it in the terminal.

## INTRODUCTION

**[ANIMATION]** end

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you learned the model, and a reading order that starts with the trigger. Now you learn to read the trigger properly, and then two more things that sit between the trigger and your commands.

Three parts. Events and filters: which commit and ref a run is about, which copy of the workflow file is used, and how a branch or path filter decides whether a run is created at all. Contexts and expressions: the data a workflow can read and the small formula language over it, with the question that matters most, which is when an expression is evaluated. And `env`, `vars` and `secrets`: three things that look alike in a script and differ in where they're defined and who can read them.

The path filter part has a local demonstration, because the comparison GitHub documents is a plain Git diff, and you can run it before pushing.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- say for `push`, `pull_request`, `schedule` and `workflow_dispatch` which commit the run refers to and from which branch the workflow file is read;
- predict whether a branch or path filter starts a workflow for a given change;
- explain how changed paths are computed for a pull request and for a push;
- read an expression and say when it is evaluated;
- distinguish `env`, `vars` and `secrets` by where they are defined and who can read them.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**Events. In one sentence:** the `on` key lists the events that start a run. Each event fixes which commit and ref the run is about and which copy of the workflow file is used. A ref is a name such as a branch or a tag. And filters narrow an event to branches, tags or paths.

`on` takes one event, a list, or a map from event to its configuration. The textbook lists eight events with the values the events reference gives for `GITHUB_SHA` and `GITHUB_REF`. Take the four you'll meet first.

**[ANIMATION]** walk: id=ev columns=event|the_commit,_GITHUB__SHA|the_ref,_GITHUB__REF rows=push:the_tip_commit_pushed_to_the_ref:the_updated_ref|pull__request:the_last_merge_commit_on_the_GITHUB__REF_branch:refs/pull/N/merge|workflow__dispatch:the_last_commit_on_the_chosen_branch_or_tag:the_chosen_branch_or_tag|schedule:the_last_commit_on_the_default_branch:the_default_branch mono=off title=Each_event_fixes_a_commit_and_a_ref at_1=5

**[ANIMATION]** step: 1

`push` starts when commits or tags are pushed. The commit is the tip commit pushed to the ref. The ref is the updated ref. It runs for any branch, including workflows not merged into the default branch.

**[ANIMATION]** step: 2

`pull_request` starts when a pull request is opened, gets new commits, or is reopened. Other activity types need `types`. The commit is the last merge commit on the `GITHUB_REF` branch, and the ref is `refs/pull/N/merge`. That's the test merge that GitHub computes for the pull request. So the commit isn't the tip of your branch. Video 145 is about that. And the reference adds: it doesn't run while the pull request has a merge conflict.

**[ANIMATION]** step: 3

`workflow_dispatch` starts when someone starts it by hand, with the CLI or the API. The commit is the last commit on the chosen branch or tag, and the ref is that branch or tag. It works only if the workflow file exists on the default branch.

**[ANIMATION]** step: 4

`schedule` starts when a cron expression matches. The commit is the last commit on the default branch. The ref is the default branch. It's in UTC unless a timezone is given. The shortest interval is five minutes. It can be delayed or dropped under load. And in a public repository it is disabled after 60 days without repository activity.

**[ANIMATION]** say: The_other_four:_workflow__call,_workflow__run,_merge__group_and_release

The other four in the table are `workflow_call`, `workflow_run`, `merge_group` and `release`. One remark on `merge_group` now, because it's the same class of problem as the hook: required checks must listen to it, or the merge queue never gets a result.

**[ANIMATION]** say: Three_families:_a_specific_commit,_the_default_branch,_the_ref_a_person_chose

The textbook tells you to read the table as three families. `push`, `pull_request`, `merge_group` and `release` are about a specific commit that somebody produced. `schedule` and `workflow_run` are about the default branch, whatever happened elsewhere. `workflow_dispatch` is about whatever ref the person chose.

**[ANIMATION]** end

One event is deliberately not in the table: `pull_request_target`. It starts on the same pull request activity, but it's about the base repository: the workflow file comes from the default branch and the job receives the base repository's token and secrets. The textbook's instruction is plain: don't use it before reading section 21A.5. That is video 157.

**Which copy of the workflow file.** From the last video: for `push` and `pull_request` the workflow definition is read from the commit the event refers to, so a branch can change its own CI. For several other events it is read from the default branch only.

**Filters.** `push` accepts filters for branches, tags and paths, each with an `-ignore` form. `pull_request` accepts the branch filters, which match the base branch, and the two path filters. Four rules.

**[ANIMATION]** cards: id=filt cards=a_filter_and_its_-ignore_form:cannot_be_combined_for_one_event|a_branch_filter_and_a_path_filter:the_workflow_runs_only_when_both_are_satisfied|pushes_of_tags:path_filters_are_not_evaluated|what_a_path_filter_compares:three_dots_for_pull_requests,_two_dots_for_pushes numbered=on title=Four_rules_for_filters

**[ANIMATION]** step: 1

A positive filter and an `-ignore` filter of the same kind can't be combined for one event. You use an exclamation mark pattern inside the positive filter, and order matters.

**[ANIMATION]** step: 2

When a branch filter and a path filter are both present, the workflow runs only when both are satisfied.

**[ANIMATION]** step: 3

Path filters aren't evaluated for pushes of tags.

**[ANIMATION]** step: 4

And the rule the demonstration is built on: path filters compare with a three-dot diff for pull requests and a two-dot diff for pushes. Two limits come with it. A push with more than 1,000 commits, or a diff that times out, always runs the workflow. A diff of more than 3,000 files in which the match isn't among the first 3,000 doesn't.

**[ANIMATION]** end

Two more ways a run doesn't come to exist. A commit whose message contains `[skip ci]`, or one of its documented variants, skips `push` and `pull_request` workflows. And events created by a workflow's own job token don't start new workflow runs, with documented exceptions: `workflow_dispatch`, `repository_dispatch`, and pull request events, which wait for approval since the eleventh of June 2026. So a job that pushes a commit with the job token doesn't trigger the `push` workflows for that commit.

**Contexts and expressions. In one sentence:** a context is a named object of facts about the run, and an expression, written with a dollar sign and double braces, is a small formula over contexts that GitHub Actions replaces with its value before your step starts.

**[ANIMATION]** cards: id=ctx cards=github:event,_ref,_commit,_actor,_run_numbers|env|vars|secrets|inputs|matrix|steps:earlier_steps_with_an_id|needs:the_jobs_listed_in_needs title=The_contexts_you_use_first at_1=10 at_2=42 at_3=46 at_4=50 at_5=54 at_6=58 at_7=63 at_8=82

The contexts you'll use first: `github`, with the event name, the full event payload, the ref, the commit, the actor and the run numbers. `env`. `vars`. `secrets`. `inputs`. `matrix`. `steps`, which holds the outputs and outcome of earlier steps that have an `id`. And `needs`, which holds the outputs and result of the jobs listed in `needs`.

**[ANIMATION]** end

The rules of the expression language that cause surprises.

Strings use single quotes inside the braces. Double quotes are an error.

String comparison ignores case. When the two sides of an equality differ in type, both are converted to numbers.

A property that doesn't exist evaluates to an empty string, without an error. A typing error in the name of a step ID is therefore silent.

The functions include `contains`, `startsWith`, `format`, `toJSON`, `fromJSON`, `hashFiles`, and the status functions `success()`, `failure()`, `cancelled()` and `always()`. The function `case` has existed since the twenty-ninth of January 2026. Older files imitate it with "condition and a, or b", which returns b whenever a is falsy.

**[ANIMATION]** walk: id=avail columns=an_if_at,can_read,cannot_read rows=job_level:github,_needs,_vars,_inputs:matrix,_steps,_env,_secrets|step_level:matrix,_steps,_env:secrets marks=1.3:bad,2.3:bad mono=off title=Context_availability_is_per_key at_1=5 at_2=42

**[ANIMATION]** step: 2

**Context availability is per key.** A job-level `if` can read `github`, `needs`, `vars` and `inputs`, but not `matrix`, `steps`, `env` or `secrets`. A step-level `if` can read `matrix`, `steps` and `env`, but still not `secrets`. The reason is timing: a job-level `if` is decided before a runner exists, so nothing that lives on the runner can take part.

**[ANIMATION]** end

**The trap in `if`.** The wrapper of dollar sign and braces is optional in an `if`, unless the expression starts with an exclamation mark. Text outside the wrapper turns the whole value into a non-empty string, which is truthy. The condition is then always true.

**[ON SCREEN]** The three lines of section 20A.5.

```yaml
if: ${{ github.event_name == 'push' }}            # an expression
if: github.event_name == 'push'                   # the same expression
if: ${{ github.event_name == 'push' }} && true    # a string, always truthy
```

Since the twenty-ninth of January 2026 the editor validation flags the third form and the run shows an annotation.

**`env`, `vars` and `secrets`. In one sentence:** `env` is defined in the workflow file and becomes environment variables of the process. `vars` and `secrets` are stored in GitHub settings and are read through contexts. Only `secrets` are encrypted and masked.

**[ON SCREEN]** The table of section 20A.6.

Where each is defined: `env` in the workflow file, at workflow, job or step level. `vars` and `secrets` in the settings of the organization, the repository or an environment.

Who can see it: `env` is in the file. `vars` aren't in the repository but readable in settings and logs. `secrets` are write-only in settings.

How it reaches a step: `env` as an environment variable. `vars` and `secrets` only through their context. You map them into `env`, or for a secret into `env` or `with`.

Precedence for the same name: for `env`, the most specific wins, step over job over workflow. For `vars`, environment over repository over organization. For secrets, the environment-level secret wins.

Masking: `env` no, `vars` no, `secrets` yes, when the exact value appears. The textbook adds three words: not a guarantee.

Quick quiz. A deploy step reads a secret that nobody ever set. What does the step receive? A, an error that stops the run. B, an empty string. Your answer?

**[PAUSE]**

B, an empty string. Three behaviors cause real failures. An unset secret is an empty string, not an error. A deploy step that receives an empty credential fails later and elsewhere, with a message about authentication. Secrets aren't passed to workflows triggered from forks or by Dependabot, apart from a read-only job token. A fork is a second repository on GitHub, made from the first. A fork pull request that "fails only in CI" is often a job that needed a secret. And `secrets` can't be used in `if`. You map the secret into `env` and test whether the variable is non-empty.

`GITHUB_TOKEN` is a secret that GitHub creates for each job. What it may do is set by the `permissions` key, and when any permission is named, every unnamed one becomes none.

## MENTAL MODEL

**Analogy,** from the textbook. An expression is a mail-merge field. The letter, which is your step, is printed with the field already filled in. The recipient, which is the shell, never sees the field, only the text.

The textbook says the analogy is exact about the danger and incomplete about the timing. Exact about the danger: text substituted into a script becomes part of the script. That's how an untrusted pull request title becomes a shell command, and video 158 is about that. Incomplete about the timing: not every field is available in every place.

So for every expression ask: who evaluates this, and when? There are three moments.

**[ANIMATION]** stores: id=when boxes=workflow_file:what_you_write|GitHub_Actions_service:before_a_runner_is_assigned|runner:per_step rows=1:A:on:,_jobs.<id>.if,_strategy.matrix|1:B:evaluated_before_a_runner_is_assigned|2:A:steps[*].if,_with:,_env:,_run:_${{_..._}}|2:C:evaluated_per_step,_BEFORE_the_shell_starts|3:A:run:_echo_"$NAME"|3:C:expanded_by_the_shell,_at_run_time arrows=1:A1>B1:|2:A2>C1:|3:A3>C2: mono=off title=Who_evaluates_this,_and_when? at_1=10

**[ANIMATION]** step: 1

Before a runner is assigned, the service evaluates `on`, the job-level `if`, and the matrix.

**[ANIMATION]** step: 2

On the runner, per step, before the shell starts, the step-level `if`, `with`, `env`, and any expression inside a `run` text are evaluated.

**[ANIMATION]** step: 3

And at run time, the shell expands an ordinary shell variable.

**[ANIMATION]** say: An_expression_in_run_pastes_text_into_the_script._A_value_in_env_reaches_the_shell_as_data

The difference between the last two is a security boundary. An expression inside `run` pastes the value into the script text. A value mapped into `env` and then read as a shell variable is handed to the shell as data. Every course workflow uses the second form, including for values that aren't attacker-controlled, so that the habit is uniform.

## DIAGRAM

**[ANIMATION]** end

**[DIAGRAM]** Four rows, three questions. Fill the commit column first, then the ref column, and ask the viewer for the third column before you write it.

```text
  event               commit (GITHUB_SHA)              ref (GITHUB_REF)            workflow file
  ------------------  -------------------------------  --------------------------  -----------------------------
  push                tip commit pushed to the ref     the updated ref             read from the commit the
                                                                                   event refers to
  pull_request        last merge commit on the         refs/pull/N/merge           read from the commit the
                      GITHUB_REF branch (the test                                  event refers to: a branch
                      merge, not your branch tip)                                  can change its own CI
  workflow_dispatch   last commit on the chosen        the chosen branch or tag    runs only if the file exists
                      branch or tag                                                on the default branch
  schedule            last commit on the default       the default branch          the default branch
                      branch
```

Four rows, three questions: which commit, which ref, and which copy of the workflow file. Look at the last column. Only `push` and `pull_request` read the file from the commit the event refers to.

**[ANIMATION]** step: when.3

**[DIAGRAM]** Then the second picture, from section 20A.5: where each piece is evaluated.

```text
  workflow file                 GitHub Actions service             runner
  ---------------               -----------------------            ---------------------------
  on:, jobs.<id>.if,     --->   evaluated before a runner
  strategy.matrix               is assigned
  steps[*].if, with:,    --->                              --->    evaluated per step, on the
  env:, run: ${{ ... }}                                            runner, BEFORE the shell starts
  run: echo "$NAME"                                        --->    expanded by the shell, at run time
```

And the second picture: three moments. The service evaluates before a runner is assigned. The runner fills in expressions per step, before the shell starts. And the shell expands its own variables at run time.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch20a/path-filter`. This is Git, in the sandbox, standing in for a decision that GitHub Actions makes. Every revealing command is `git diff`, which reads.

The situation: a pull request branch, `feature/reorder-report`, that touches only Python files, while `main` moved on. A Java workflow has the path filter `java-service/**`.

**Step 1: the pull request comparison.**

```bash
git diff --name-only origin/main...feature/reorder-report
git diff --quiet origin/main...feature/reorder-report -- "java-service/**"
```

Three dots. Which files are listed, and what's the exit status of the second command? Say it out loud.

**[PAUSE]**

<!-- snippet: ch20a/path-filter/01-pull-request -->
```text
# Pull request: base main, head feature/reorder-report. Three dots: what the branch changed.
$ git diff --name-only origin/main...feature/reorder-report
src/inventory_api/report.py
tests/test_report.py
# Does any changed path match java-service/** ?
$ git diff --quiet origin/main...feature/reorder-report -- "java-service/**"
[exit status: 0]
# Exit status 0 means no difference under that path: the Java workflow would not start.
```
<!-- /snippet -->

Two Python files. Exit status 0 from `git diff --quiet` means no difference under that path. The Java workflow wouldn't start.

**Step 2: what two dots would say.**

```bash
git diff --name-only origin/main..feature/reorder-report
```

<!-- snippet: ch20a/path-filter/02-two-dots-would-mislead -->
```text
# Two dots compare the two tips, so the change made on main shows up as if it were yours:
$ git diff --name-only origin/main..feature/reorder-report
src/inventory_api/report.py
src/inventory_api/stock.py
tests/test_report.py
tests/test_stock.py
```
<!-- /snippet -->

Four files. `stock.py` and its test changed on `main`, not on the branch.

**[ANIMATION]** graph: id=dots ...2-?merge_base-?on_main origin/main; ?merge_base-?on_the_branch feature/reorder-report; HEAD=none; note:?on_main:stock.py,_test__stock.py; note:?on_the_branch:report.py,_test__report.py => + range:?on_main,?on_the_branch:two_dots; name:two; say:Two_dots_compare_the_two_tips => + range:?on_the_branch:three_dots; name:three; say:Three_dots:_the_merge_base_compared_with_the_head dx=240 at_state_1=6 at_two=14 at_three=55

Two dots compare the two tips and blame the branch for what `main` did. For a pull request GitHub is documented to use three dots: the merge base compared with the head, which is what the branch did.

**[ANIMATION]** end

Try it now, thirty seconds, in a repository of your own, on a branch other than the default one. Run `git diff --name-only origin/main...HEAD`, with your default branch's name if it isn't `main`. Three dots, and it only reads. What does the list show?

**[PAUSE]**

**[ANIMATION]** step: dots.three

It shows every path your branch changed since the merge base, the commit where it left the default branch. For a pull request, that's the list a `paths` filter is documented to be compared with. If nothing in it matches, no run is created.

**Step 3: a push.**

```bash
before=$(git rev-parse HEAD)
git commit --quiet -am "Bump java-service to 0.2.0"
git diff --name-only $before..HEAD
git diff --quiet $before..HEAD -- "java-service/**"
```

`git commit` adds an object and moves the branch. For a push, the comparison is two dots between the old and the new tip of the pushed branch: the commits you pushed. Exit status? Make your prediction.

**[PAUSE]**

<!-- snippet: ch20a/path-filter/03-push -->
```text
# Push: the diff from the old tip of the branch to the new one.
$ git switch --quiet feature/reorder-report
$ before=$(git rev-parse HEAD)
$ git commit --quiet -am "Bump java-service to 0.2.0"
$ git diff --name-only $before..HEAD
java-service/pom.xml
$ git diff --quiet $before..HEAD -- "java-service/**"
[exit status: 1]
# Exit status 1: a path under java-service/ changed, so the Java workflow would start.
```
<!-- /snippet -->

Status 1: a path under `java-service/` changed. The Java workflow would start.

**Step 4: the lab replay.** Replay `labs/run ch20a/lab-26-5-path-filter`. Here the filter has two entries: the Java directory and the workflow file itself.

<!-- snippet: ch20a/lab-26-5-path-filter/01-docs-only -->
```text
$ git switch -c docs/java-readme
Switched to a new branch 'docs/java-readme'
$ echo "The Java module lives in java-service/." >> README.md
$ git commit --quiet -am "Mention the Java module"
$ git diff --name-only origin/main...HEAD
README.md
$ git diff --quiet origin/main...HEAD -- "java-service/**" ".github/workflows/05-java-tests.yml"
[exit status: 0]
# Status 0: nothing under the filtered paths changed. The workflow does not start.
```
<!-- /snippet -->

A documentation branch. Only `README.md` changed. Status 0: the workflow doesn't start. If that workflow were a required check, this is the pull request from the hook.

<!-- snippet: ch20a/lab-26-5-path-filter/02-java-change -->
```text
$ sed -i.bak 's/0.1.0/0.1.1/' java-service/pom.xml && rm java-service/pom.xml.bak
$ git commit --quiet -am "Bump java-service to 0.1.1"
$ git diff --name-only origin/main...HEAD
README.md
java-service/pom.xml
$ git diff --quiet origin/main...HEAD -- "java-service/**" ".github/workflows/05-java-tests.yml"
[exit status: 1]
# Status 1: a filtered path changed somewhere in the pull request. The workflow starts.
```
<!-- /snippet -->

A second commit on the same branch changes `pom.xml`. The three-dot diff now lists both files, and the status is 1. Notice what this means for a pull request: the comparison is over the whole pull request, so once any commit in it touches a filtered path, the workflow starts on every later push to it as well.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough.

**Lab 26.2 on your practice repository, in your normal shell.** The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

Read the trigger of `workflows/02-lint.yml` first: pushes to `main`, and pull requests. The lab has you add the workflow on a branch named `ci/lint`, push the branch and open a pull request. `git push` is 🟡 CAUTION and `gh pr create` is 🟡 CAUTION: it creates a GitHub object that notifies people.

Before the push, the lab asks you to predict: which workflows start for the pull request, and how many checks will it show? Think about it with what you know. The push to `ci/lint` is a push, but not to `main`, so the `push` trigger with its branch filter doesn't match. The `pull_request` trigger matches once the pull request exists. And the lint workflow file is on the branch, not yet on `main`: for `pull_request`, which copy is used?

```bash
gh pr checks --watch
```

In the browser, open the pull request and find the list of checks. Name each by the workflow and job it comes from. Then look at two expressions in the file while the run is in progress: the `if` with `!cancelled()` on the formatting step, which needs the wrapper because it starts with an exclamation mark, and the summary step that maps two step outcomes into `env` before the shell reads them.

## COMMON MISTAKES

Five mistakes to watch for.

1. **A required check on a workflow with a `paths` filter.** Root cause: a workflow that a filter skips never creates its check, and the ruleset waits for a result that will not come.
2. **Predicting a pull request path filter with a two-dot diff.** Root cause: for pull requests the comparison is three dots, from the merge base; two dots include what changed on the base branch.
3. **An `if` with text outside the expression wrapper.** Root cause: the whole value becomes a non-empty string, which is truthy, so the condition is always true.
4. **A typing error in `steps.<id>.outputs`.** Root cause: a property that does not exist evaluates to an empty string, without an error.
5. **Expecting a secret in a fork pull request, or testing `secrets` in `if`.** Root cause: secrets are not passed to workflows triggered from forks, and the `secrets` context is not available in `if`.

## PRODUCTION EXAMPLE

Now, out of the lab. A platform team runs a nightly evaluation with `schedule`. An engineer improves the evaluation workflow on a feature branch and waits for the night to see the result. In the morning the run has used the old workflow, and the engineer suspects a cache.

**[ANIMATION]** step: ev.4

**[ANIMATION]** say: schedule:_the_default_branch._workflow__dispatch:_the_ref_a_person_chose

Read the table. For `schedule`, the commit is the last commit on the default branch and the ref is the default branch. A scheduled run knows nothing about a feature branch. To try the changed workflow before merging, the engineer needs an event that's about a chosen ref. That is `workflow_dispatch`, with its own condition: it works only if the workflow file exists on the default branch. So the first version of a manually started workflow has to be merged before it can be started by hand from any branch at all.

## PRACTICE EXERCISE

**[ANIMATION]** end

Your turn. Do Lab 26.2, "Workflow 2, linting", in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md), in your normal shell.

Predict before step 3: which workflows start for the pull request, and how many checks it will show. Then, in the failure part of the lab, predict which step fails and whether the step after it still runs.

The challenge is Exercise 26.4, "Will the path filter start the workflow?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q292: "For each of `push`, `pull_request`, `schedule` and `workflow_dispatch`: which commit does the run refer to, and from which commit is the workflow file read?"

**[PAUSE]**

Answer out loud first. A strong answer goes event by event and keeps the two questions separate, because they have different answers for some events. For `pull_request` it names the commit exactly and says why it isn't the branch tip. It mentions the condition attached to `workflow_dispatch`. The follow-up is about a pull request that edits its own workflow to remove a test: say whether the edited file runs, and then what that implies about who may change workflow files and what a required check can and can't guarantee.

## RECAP

**[ANIMATION]** step: ci.result

Let's land this. The waiting pull request from the opening has its explanation: the filter created no run, so no check was reported, and the rule kept waiting.

You should now be able to say:

- Each event fixes a commit and a ref: the pushed tip for `push`, the test merge under `refs/pull/N/merge` for `pull_request`, the default branch for `schedule`, the chosen ref for `workflow_dispatch`.
- A filter decides whether a run is created at all, and a run that is not created reports no check.
- Path filters use a three-dot diff for pull requests and a two-dot diff for pushes, and you can compute both locally.
- An expression is replaced by its value before the shell starts; which contexts exist depends on the key.
- `env` is in the file, `vars` and `secrets` are in settings, only secrets are masked, and an unset secret is an empty string.

## HOMEWORK

Read sections 20A.4 to 20A.6 of [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md). Do Exercise 26.2, "Which commit, which ref, which file?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

Today you learned to say, for an event, which commit, which ref and which file, and you computed a path filter with a plain diff. Run the three-dot diff on a branch of yours before the next video. Next time: shells, and passing data between steps and jobs. Until then, look at the state first and type second. See you in the next one.
