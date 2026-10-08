# V142: The Actions model, and YAML read carefully

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 26
- **Planned minutes.** 22
- **Prerequisites.** V115, V141
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), sections 20A.1 to 20A.3, and the walk-through of workflow 1 in section 20A.13
- **Demo scripts.** `labs/ch20a/yaml-reading.sh`; the file [`workflows/01-tests.yml`](../../workflows/01-tests.yml); then a screen walkthrough of Lab 26.1 in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md)

## HOOK

**[ON SCREEN]** Four questions from section 20A.1.

Four questions a CTO can ask about one pull request, a proposal on GitHub to merge one branch into another. "The tests passed on your laptop and failed in CI on the same commit. Was it the same commit?" "The build stamped the release with a commit ID and not with a version. Who removed the tags?" "This workflow has a `paths` filter and is a required check. Why is the pull request waiting forever?" "The job is green. Did the tests run, or did a pipe swallow the failure?" CI, by the way, is the automated checking of each change.

The chapter makes a claim about these four, and it's the claim of this whole part of the course: none of them is answered by knowing YAML keys. Each is answered by knowing what a runner, the machine that runs your job, has on disk and in its environment when your command starts.

**[ANIMATION]** cards: id=disk question=What_does_the_runner_have_when_your_command_starts? cards=which_commit|how_much_history|which_shell,_with_which_flags|which_token|which_variables|asked_for_Python_3.10:got_Python_3.1,_with_no_error ask=6 at_1=2 at_2=10 at_3=20 at_4=32 at_5=40 at_6=72

Which commit, how much history, which shell with which flags, which token, which variables. And one smaller puzzle for today. A team asks for Python 3.10 and gets Python 3.1, with no error anywhere. Keep that one in mind. You'll watch it happen.

## INTRODUCTION

**[ANIMATION]** end

Welcome back to Git and GitHub Deep Mastery. Pull up a chair, and welcome to Part 6. So far the course has been about Git and about GitHub as a platform. From here on there's a third layer, and you'll see its lower-third label often.

**[ON SCREEN]** Lower third: GitHub Actions.

The textbook's framing: everything in this part except the repository content is GitHub Actions, a service that reacts to events on GitHub by running commands on machines. Git appears in exactly one place, when a job fetches commits onto the runner. That place causes most of the surprises, and it has its own video, video 145.

This video does two things. It gives you the model: seven terms and which contains which. And it teaches you to read YAML, the indented text format that workflow files are written in, as data, because a workflow file is parsed before GitHub Actions interprets a single key.

One statement about evidence, which holds for all of Part 6. Nothing in these chapters was run on GitHub by the authors. The workflow files of the course were parse-checked and assembled from documented syntax and from each action's own definition at the pinned version. They weren't executed on GitHub by the author. The labs have you run them. So when a workflow fails for a reason the authors couldn't test, that's material for diagnosis and not a defect in your setup.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- define workflow, event, job, step, action, runner and shell and say which contains which;
- read a workflow file in a fixed order to predict when it runs, where, and with what;
- name the YAML features that change the meaning of a workflow without an error;
- explain why the key `on` needs care and what a tab does;
- say what was and was not verified about the course's workflow files.

## CONCEPT

**[ANIMATION]** ci: id=ci push file=off job=test runner=ubuntu-24.04 title=One_event,_one_run,_one_job_on_a_fresh_runner (Check out the repository, Show what was checked out, Set up Python, Run the tests)

**[ANIMATION]** step: steps

**In one sentence.** A workflow is a YAML file in the repository that says "when this event happens, run these jobs". Each job is a list of steps that run in order on one fresh machine called a runner. A step is either a shell command or an action, which is a packaged program.

**Precisely.** The terms, as the workflow syntax reference uses them.

**[ON SCREEN]** The table of section 20A.2, one row at a time.

A workflow is a configurable automated process defined by a YAML file. The file must be in `.github/workflows` and end in `.yml` or `.yaml`.

An event is an activity on GitHub, such as a push, a pull request activity or a release. Or a schedule. Or a manual or API request. An event isn't written anywhere. It happens.

The trigger is the `on` key of a workflow: which events, with which filters, start a run.

A workflow run is one execution of a workflow for one event. It has a run ID, a run number and, when re-run, an attempt number.

A job is a set of steps that execute on the same runner. Jobs of one run execute in parallel unless `needs` orders them.

A step is one `run` command line or script, or one `uses` reference to an action. Steps of a job execute in order.

An action is a reusable program referenced by `uses`, with an owner, a repository and a ref. It's a JavaScript program, a composite of steps, or a Docker container, declared by the `action.yml` in its repository.

A runner is the machine that executes one job. A GitHub-hosted runner is a new virtual machine per job, chosen by `runs-on`.

And the shell is the program that executes a `run` step. Each `run` step is a new process.

Three properties follow from those definitions, and they explain most of what the next videos show.

**[ANIMATION]** run: id=iso event=push jobs=build|report:build artifact=build>report:outputs title=A_job_is_the_unit_of_isolation at_event=0 at_jobs=15 at_data=62

**[ANIMATION]** step: data

First: a job is the unit of isolation. A job starts on a fresh machine. Files, installed tools and environment variables don't carry from job to job. Data crosses jobs only as job outputs, which are strings. As artifacts, which are files. Or as caches, which are files on a best-effort basis.

Quick quiz. Step one of a job runs `cd src`. Step two runs `ls`. Where does step two start? A, inside `src`. B, back where step one started. Your answer?

**[PAUSE]**

**[ANIMATION]** step: ci.steps

**[ANIMATION]** say: Each_run_step_is_a_new_shell_process:_a_cd_or_an_export_is_gone_in_the_next

B. Second: a step is the unit of process. Steps of one job share the filesystem of the runner, but each `run` step is a new shell process. A `cd` or an `export` in one step is gone in the next.

**[ANIMATION]** end

Third: the workflow file is versioned with the code. For `push` and `pull_request` the workflow definition is read from the commit the event refers to, so a branch can change its own CI. For several other events it is read from the default branch only.

**[ANIMATION]** stores: id=where boxes=in_a_clone:Git_data|on_GitHub_only:GitHub_objects rows=1:A:.github/workflows/,_an_ordinary_blob|2:B:runs|2:B:jobs|2:B:logs|2:B:artifacts|2:B:caches|2:B:secrets|2:B:variables title=What_a_clone_contains at_1=10 at_2=52

**Inside `.git`.** A workflow is an ordinary blob, the object that holds the bytes of one file, at a path under `.github/workflows/` in a commit's tree. Nothing else in the repository's Git data describes Actions. Runs, jobs, logs, artifacts, caches, secrets and variables are GitHub objects. A clone doesn't contain them, and `git log` can't show them.

**[ANIMATION]** end

**YAML. In one sentence:** a workflow file is data, not a script. A YAML parser turns it into nested maps, lists and scalars before GitHub Actions interprets any key, so indentation and quoting decide what GitHub sees.

Four rules cover the mistakes that occur in workflow files.

**[ANIMATION]** cards: id=yaml cards=indentation_is_structure:a_tab_in_indentation_is_a_syntax_error|an_unquoted_scalar_is_typed_by_its_shape:3.10_is_the_number_3.1|the_bar_keeps_line_breaks:the_greater-than_sign_folds_them_into_spaces|an_anchor_marks_a_node:an_alias_reuses_it numbered=on title=Four_rules_for_reading_YAML

**[ANIMATION]** step: 1

One. Indentation is structure, and tabs aren't indentation. A key belongs to the map whose column it sits in. A tab character in indentation is a syntax error.

**[ANIMATION]** step: 2

Two. An unquoted scalar is typed by its shape. `3.10` without quotes is a number, and the number is 3.1. `v1.0` is a string because of the `v`. So quote everything that's a version, a label or a glob. The filter pattern cheat sheet adds that patterns starting with a star, a square bracket or an exclamation mark must be quoted, because those characters are YAML syntax.

**[ANIMATION]** step: 3

Three. The vertical bar keeps line breaks. The greater-than sign folds them into spaces. A multi-line `run` script needs the bar.

**[ANIMATION]** step: 4

Four. An ampersand with a name marks a node, and a star with the name reuses it. Anchors and aliases are standard YAML and have been accepted in workflow files since the eighteenth of September 2025.

## MENTAL MODEL

**Analogy.** A workflow is a standing order at a print shop: "Whenever a manuscript arrives, give one copy to the proofreader and one to the typesetter, each at a clean desk, each following a numbered checklist, some items of which say 'use the house stamping machine'." The manuscript arriving is the event. The two workers are two jobs. The clean desk is the runner. The checklist is the steps. The stamping machine is an action.

The textbook says the analogy breaks in two places. The desks are destroyed after each job, so nothing left on one is found by the next. And the manuscript isn't handed over: the worker must fetch it, and by default fetches only the last page.

Hold on to "only the last page". It's the shallow checkout, and it answers the CTO's second question.

**A reading order.** The textbook explains workflow 1 from top to bottom: name, trigger, permissions, job and runner, then the steps. This course uses that as a fixed order for every workflow file you meet, and you'll use it in the gate.

**[ANIMATION]** cards: id=order cards=the_trigger:when_a_run_exists,_for_which_commit_and_ref|the_permissions:what_the_job's_token_may_do|each_job:which_runner,_after_which_jobs,_under_which_conditions|the_first_steps:what_is_checked_out,_and_how_much|the_commands:the_real_check numbered=on title=A_fixed_reading_order

**[ANIMATION]** step: 1

First, the trigger. Which events, with which filters? That tells you when a run exists at all, and for which commit and ref.

**[ANIMATION]** step: 2

Second, the permissions. What may the job's token, the credential it uses to call GitHub, do?

**[ANIMATION]** step: 3

Third, each job: on which runner, after which other jobs, under which conditions.

**[ANIMATION]** step: 4

Fourth, the first steps of the job: what's checked out, and how much of it.

**[ANIMATION]** step: 5

Fifth and last, the commands that are the real check.

**[ANIMATION]** say: People_read_in_the_opposite_order:_the_test_command_first

People read in the opposite order. They go to the test command first because it's familiar. But a correct test command that runs on the wrong commit, or never runs, proves nothing.

## DIAGRAM

**[DIAGRAM]** Draw from the outside in. The workflow box first. Then the event as an arrow that enters from the left and creates a run. Inside the run, two jobs. Beside each job its runner. Inside a job, the steps, and mark each step as an action or a shell process.

```text
   EVENT ----------------> starts one RUN of each workflow whose trigger matches
   (push, pull request,
    schedule, manual)

   +-- WORKFLOW: a file in .github/workflows/ on a commit -------------------------+
   |                                                                               |
   |  +-- RUN (run ID, run number, attempt) -----------------------------------+   |
   |  |                                                                        |   |
   |  |  +-- JOB build -------------------+      +-- JOB report -----------+   |   |
   |  |  | RUNNER: a new VM               |      | RUNNER: another new VM  |   |   |
   |  |  |                                |      | (needs: build)          |   |   |
   |  |  |  STEP 1  uses: an ACTION       |      |                         |   |   |
   |  |  |  STEP 2  run:  a SHELL process | ---> |  STEP 1  run: a SHELL   |   |   |
   |  |  |  STEP 3  uses: an ACTION       | job  |          process        |   |   |
   |  |  |  STEP 4  run:  a SHELL process | outputs                        |   |   |
   |  |  +--------------------------------+ (strings) ---------------------+   |   |
   |  |    files stay on this VM; the VM is discarded when the job ends        |   |
   |  +------------------------------------------------------------------------+   |
   +-------------------------------------------------------------------------------+
```

Read it from the outside in. An event starts a run. The run holds two jobs, each on its own new machine. Inside a job, every step is an action or a shell process. And between `build` and `report`, only job outputs cross, and those are strings.

**[DIAGRAM]** Two boundaries matter. The job box is the unit of isolation: nothing crosses it except outputs, artifacts and caches. The step is the unit of process: the filesystem is shared, the shell is not.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch20a/yaml-reading`. The script parses YAML locally and runs nothing on GitHub. Every command reads a file and prints the parsed structure as JSON.

One caveat before the first output, and the textbook is exact about it. The parser here is PyYAML, the library that parse-checks the course workflows. It implements YAML 1.1. GitHub uses its own parser. So read each result with the note that follows it.

**Step 1: scalars.**

```bash
cat scalars.yml
python3 -c "$show" scalars.yml
```

The file has a list of Python versions: 3.9, then 3.10 without quotes, then 3.10 in quotes, then 3.11. And three more values: `yes`, `NO`, and `v1.0`. Predict the type and value of each. Say it out loud.

**[PAUSE]**

<!-- snippet: ch20a/yaml-reading/01-scalars -->
```text
$ cat scalars.yml
python: [3.9, 3.10, "3.10", 3.11]
version: 1.0
enabled: yes
country: NO
tag: v1.0
$ python3 -c "$show" scalars.yml
{
  "python": [
    3.9,
    3.1,
    "3.10",
    3.11
  ],
  "version": 1.0,
  "enabled": true,
  "country": false,
  "tag": "v1.0"
}
```
<!-- /snippet -->

The second element is `3.1`. There's the puzzle from the opening. A matrix, a list of variants that each get their own job, written with unquoted `3.10` asks for Python 3.1. This is a property of numbers, not of one parser. The quoted one stayed a string. `yes` and `NO` became booleans, because YAML 1.1 says so.

Try it now, thirty seconds, on paper. Rewrite that list of Python versions so that every element arrives as text. I'll wait.

**[PAUSE]**

Put each version in quotes. Quoted, `3.10` keeps its zero, exactly as the third element did. That's rule two: quote everything that's a version, a label or a glob.

**[ON SCREEN]** Callout: Unverified. Whether GitHub's workflow parser also reads unquoted `yes`, `no`, `on` and `off` values as booleans is not stated on the documentation pages read for the chapter. Quote such values and the question does not arise.

One point is unverified. Whether GitHub's workflow parser also reads unquoted yes, no, on and off values as booleans isn't stated on the documentation pages read for the chapter. Quote such values and the question doesn't arise.

**Step 2: the key `on`.**

```bash
cat on-key.yml
python3 -c "$show" on-key.yml
```

A minimal workflow with `name`, `on` and `jobs`. What will the three top-level keys be after parsing? Make your prediction.

**[PAUSE]**

<!-- snippet: ch20a/yaml-reading/02-on-key -->
```text
$ cat on-key.yml
name: Tests
on:
  push:
    branches: [main]
  pull_request:
jobs: {}
$ python3 -c "$show" on-key.yml
{
  "name": "Tests",
  "true": {
    "push": {
      "branches": [
        "main"
      ]
    },
    "pull_request": null
  },
  "jobs": {}
}
```
<!-- /snippet -->

`name`, `true`, and `jobs`. The key `on` came out as the boolean true. GitHub Actions documents `on` as the trigger key and reads it as such. A generic YAML 1.1 tool doesn't. The consequence is for your own tooling: a script that loads workflow files with PyYAML must look up the key `True`. The course's own checker does that.

Also notice `pull_request: null`. An event with no configuration is a key with an empty value, and the documentation requires the colon on every event once any event in the map has configuration.

**Step 3: anchors.**

<!-- snippet: ch20a/yaml-reading/03-anchors -->
```text
$ cat anchors.yml
jobs:
  test:
    env: &common_env
      PYTHONPATH: src
      CI_PROFILE: fast
    steps: &setup
      - uses: actions/checkout@SHA
  lint:
    env: *common_env
    steps: *setup
$ python3 -c "$show" anchors.yml
{
  "jobs": {
    "test": {
      "env": {
        "PYTHONPATH": "src",
        "CI_PROFILE": "fast"
      },
      "steps": [
        {
          "uses": "actions/checkout@SHA"
        }
      ]
    },
    "lint": {
      "env": {
        "PYTHONPATH": "src",
        "CI_PROFILE": "fast"
      },
      "steps": [
        {
          "uses": "actions/checkout@SHA"
        }
      ]
    }
  }
}
```
<!-- /snippet -->

The `test` job defines two anchors. The `lint` job reuses them. After parsing, the alias is indistinguishable from a copy. So an anchor removes repetition inside one file and nothing more. It can't cross files.

**[ON SCREEN]** Callout: Unverified. YAML merge keys are not mentioned by the anchors documentation or the changelog entry. The course's research notes mark their support as unverified, and the course's examples do not use them.

One more point is unverified. YAML merge keys aren't mentioned by the anchors documentation or the changelog entry. The course's research notes mark their support as unverified, and the course's examples don't use them.

**Step 4: block scalars.**

```bash
cat blocks.yml
python3 -c "$show" blocks.yml
```

The same two command lines, once under a vertical bar and once under a greater-than sign. What string does each produce? Say it out loud.

**[PAUSE]**

<!-- snippet: ch20a/yaml-reading/04-block-scalars -->
```text
$ cat blocks.yml
literal: |
  uv sync --locked
  uv run pytest
folded: >
  uv sync --locked
  uv run pytest
$ python3 -c "$show" blocks.yml
{
  "literal": "uv sync --locked\nuv run pytest\n",
  "folded": "uv sync --locked uv run pytest\n"
}
```
<!-- /snippet -->

With the bar: two lines. With the greater-than sign: one line, `uv sync --locked uv run pytest`. That's one wrong command and not two right ones. The file is valid YAML both ways. No error tells you.

**Step 5: a tab.**

<!-- snippet: ch20a/yaml-reading/05-tab -->
```text
$ python3 -c "$show" tab.yml 2>&1 | tail -3
yaml.scanner.ScannerError: while scanning for the next token
found character '\t' that cannot start any token
  in "tab.yml", line 5, column 1
[exit status: 0]
```
<!-- /snippet -->

This is the one mistake of the five that's reported: a scanner error with the line and the column.

**[ON SCREEN]** The file `workflows/01-tests.yml`, full screen.

Now read workflow 1 in the order you learned.

**[ANIMATION]** walk: id=w1 columns=read,in_workflows/01-tests.yml rows=the_trigger:push_to_main,_and_pull__request|the_permissions:contents_read,_every_other_permission_none|the_job:test,_"Unit_tests",_on_ubuntu-24.04,_at_most_10_minutes|the_checkout:an_action_pinned_to_a_full_commit_ID,_persist-credentials_false|a_shell_step:Show_what_was_checked_out|an_action:Set_up_Python,_"3.13"_in_quotes|the_check:Run_the_tests_with_the_standard_library mono=off title=Workflow_1,_in_the_reading_order at_1=5 at_6=3 at_7=45

**[ANIMATION]** step: 1

The trigger: pushes to `main`, and pull request activity. The branch filter on `push` stops a second run for every push to a pull request branch, which `pull_request` already covers.

**[ANIMATION]** step: 2

The permissions: `contents: read`. The job token may read repository contents, and every other permission is none. That's least privilege, and it makes the file independent of the repository's default setting.

**[ANIMATION]** step: 3

The job: one job with the ID `test` and the display name "Unit tests", on the fixed image `ubuntu-24.04`, at most ten minutes.

**[ANIMATION]** step: 4

The checkout: an action, pinned to a full commit ID with the version as a comment. Read the ID from the file and from [`workflows/ACTION_PINS.md`](../../workflows/ACTION_PINS.md), never from memory. `persist-credentials: false` means: don't keep the token on disk.

**[ANIMATION]** step: 5

Then a shell step that prints the event, the ref, the commit, whether the clone is shallow, and the branch status. The textbook calls this the first thing to read in any log: what was checked out.

**[ANIMATION]** step: 7

Then Python 3.13, with the version quoted, as you now know why. And last, the check itself: the unit tests. A non-zero exit status fails the step, the job and the run.

**[ANIMATION]** end

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough.

**Lab 26.1 on your own practice repository, in your normal shell.** The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

You copy the sample project, add workflow 1, commit, and create the repository with `gh repo create` and `--push`. Section 15.22 labels that command 🟡 CAUTION: it creates a repository on GitHub, a remote and a push, and what reaches a public repository is published. Before you run it, the lab makes you predict: which event the push causes, which workflow starts, what `GITHUB_REF` and `GITHUB_SHA` will be, and how many commits the runner will have.

```bash
gh run list --workflow 01-tests.yml --limit 5
gh run view RUN-ID --log
```

Both read. In the browser, open the Actions tab, find the run, open the job, and expand the step "Show what was checked out". Compare its six lines with your prediction.

## COMMON MISTAKES

Five mistakes to watch for.

1. **An unquoted version such as 3.10 in a matrix.** Root cause: an unquoted scalar is typed by its shape, and as a number it is 3.1.
2. **A multi-line script under `>`.** Root cause: the folded form joins the lines with spaces, so two commands become one wrong command, without an error.
3. **A custom tool that looks for the key `on` after loading the file with a YAML 1.1 parser.** Root cause: that parser reads `on` as the boolean true.
4. **Expecting a file or an installed tool from one job in the next.** Root cause: a job is the unit of isolation and runs on a fresh machine.
5. **Reading the test command first and the trigger last.** Root cause: whether a run exists, and for which commit, is decided before any step runs.

## PRODUCTION EXAMPLE

Now, out of the lab. An evaluation team adds Python 3.10 to the test matrix of their harness, so that the nightly run covers the interpreter their largest customer still uses. The pull request is one line: a new element in a list. It's reviewed in a minute. The new matrix job doesn't ask for Python 3.10. It asks for Python 3.1.

**[ANIMATION]** cards: id=saw cards=the_reviewer_saw:3.10|the_parser_saw:3.1|the_repair:two_quote_characters marks=2:bad,3:ok title=One_line,_two_readers at_1=2 at_2=10 at_3=20 at_marks=30

The reviewer saw `3.10`. The parser saw `3.1`. The repair is two quote characters. The prevention is the rule from this video, applied in review: every version, label and glob in a workflow file is quoted, and a reviewer who sees an unquoted one asks what type it has.

## PRACTICE EXERCISE

**[ANIMATION]** end

Your turn. Do Lab 26.1, "Workflow 1, run the tests", in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md), in your normal shell on your practice organization.

The lab's second step is the prediction, and it's the point of the lab. Write down, before you push: the event, the workflow that starts, the values of `GITHUB_REF` and `GITHUB_SHA`, and the number of commits on the runner. Then read the log.

The challenge is Exercise 26.3, "Six things the author did not mean", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q296: "You inherit a repository with twelve workflow files. In what order do you read one of them to predict when it runs, where, with what code, and with what permissions?"

**[PAUSE]**

Answer out loud first. A strong answer gives an order and a reason for each position in it, in the terms of the model: event, ref and commit, token, runner, checkout, commands. It says what each stage lets you predict. The follow-up asks what you still can't know from the repository alone after reading all twelve. Think about which of the things in this video are GitHub objects and not Git data.

## RECAP

**[ANIMATION]** step: result

Let's land this. One event, one run, one job on a fresh runner, steps in order, and a result at the end. And before any of that, a parser reads the file.

You should now be able to say:

- An event starts a run of a workflow; a run has jobs; each job runs on its own fresh runner; a job has steps; a step is an action or a shell process.
- A job is the unit of isolation and a step is the unit of process.
- A workflow file is an ordinary blob in a commit; runs, logs, secrets and variables are GitHub objects that no clone contains.
- YAML is parsed before Actions reads it: quote versions and globs, use the bar for scripts, never a tab.
- The course's workflow files were parse-checked and assembled from documentation, and not run on GitHub by the author.

## HOMEWORK

Read sections 20A.1 to 20A.3 of [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md). Do Exercise 26.1, "True or false, with the reason", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

Today you learned the seven terms of the Actions model, and you caught YAML changing a value without an error. Before the next video, read workflow 1 once in the fixed order: trigger, permissions, job, checkout, commands. Next time: events and filters, contexts and expressions, and env, vars and secrets. Until then, look at the state first and type second. See you in the next one.
