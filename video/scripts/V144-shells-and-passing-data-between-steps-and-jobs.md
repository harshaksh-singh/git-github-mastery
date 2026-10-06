# V144: Shells, and passing data between steps and jobs

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 26
- **Planned minutes.** 18
- **Prerequisites.** V143
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), section 20A.7
- **Demo scripts.** `labs/ch20a/step-shell.sh`, then a screen walkthrough of Lab 26.3 in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md) with [`workflows/03-build.yml`](../../workflows/03-build.yml)

## HOOK

**[ON SCREEN]** Question 4 of section 20A.1: "The job is green. Did the tests run, or did a pipe swallow the failure?"

A nightly evaluation job has been green for three weeks. Someone opens the saved report by chance and finds failing tests in it, from the first of those nights on. The step ran the tests and piped their output into `tee`, a program that copies what it receives into a file, to keep a copy of the log. A pipe is the vertical bar that feeds one command's output to the next. The tests failed. `tee` succeeded. The step was green.

**[ANIMATION]** walk: id=green columns=what_ran,how_it_ended rows=the_tests:failed|tee:succeeded|the_step:green marks=1.2:bad,2.2:ok,3.2:ok mono=off title=Green_for_three_weeks pace=quick

Nobody wrote a wrong command. The command was run by a shell, the program that reads and runs command lines, with options nobody had looked up. In this video you look them up, and you reproduce the green failure on your own machine in two lines. Keep that green step in mind.

## INTRODUCTION

**[ANIMATION]** end

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You know from video 142 that a step is the unit of process: each `run` step is a new shell process. This video takes that sentence seriously, in two directions.

First: which shell, started how? The runner uses a documented command template, and the template differs depending on whether you wrote a `shell` key or not. That difference decides whether a failing command in a pipeline fails the step.

Second: if every step is a new process, how does anything get from one step to the next, and from one job to the next? Through files that the runner provides, and through declared job outputs.

The demonstration reproduces the runner's shell invocation locally. It's the same `bash` with the same options, on your Mac. Nothing runs on GitHub.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- state the default shell and its options for a `run` step on a Linux runner;
- explain why a pipeline with a failing first command can leave a step green, and fix it;
- explain why a variable set in one step is gone in the next;
- pass a value to a later step and to a later job through `GITHUB_OUTPUT` and job outputs;
- recognize the deprecated command the section names.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**In one sentence.** Every `run` step is a new shell process started from a documented command template, so state survives a step only if it's written to a file the runner provides: `GITHUB_OUTPUT` for named outputs, `GITHUB_ENV` for environment variables, `GITHUB_STEP_SUMMARY` for a report.

**The shell, precisely.** The runner writes your `run` text to a temporary script file and executes it with a template in which a placeholder stands for that file.

**[ON SCREEN]** The template table of section 20A.7.

If you write nothing, on Linux or macOS, the runner executes `bash -e` with the file.

If you write `shell: bash`, on any platform, it executes `bash --noprofile --norc -eo pipefail` with the file.

If you write nothing on Windows: PowerShell Core.

If you write nothing inside a job container on Linux: `sh`, not `bash`.

And `shell: python` runs the file with Python.

Quick quiz. On a Linux runner, bash already runs your script. You add `shell: bash` to the step. Does anything change? A, nothing. B, the shell's options. Your answer?

**[PAUSE]**

B, the options change. Look at the first two rows again, because they're the hook. Both have `-e`. Only the second has `pipefail`.

**[ANIMATION]** cards: id=pipe cards=-e:stops_the_script_at_the_first_command_that_fails|a_pipeline:its_status_is_the_status_of_its_last_command|pipefail:a_failing_command_inside_the_pipeline_counts|tests_piped_into_tee:pass_under_the_implicit_default marks=4:bad title=Two_options,_one_pipeline at_1=3 at_2=45 at_3=62 at_4=78 at_marks=86

**[ANIMATION]** step: marks

`-e` stops the script at the first command that fails, that is, a command that returns an exit status other than zero. It doesn't look inside a pipeline. The status of a pipeline is the status of its last command, unless `pipefail` is set. So the implicit default lets a failing test command piped into `tee` pass.

**[ANIMATION]** say: shell:_bash_looks_like_the_default._The_default_is_a_weaker_invocation_of_the_same_program

The irony is worth saying aloud: writing `shell: bash` explicitly, which looks like stating the default, changes the behavior. It isn't the default. The default is a weaker invocation of the same program.

**[ANIMATION]** say: defaults.run.shell:_bash_gives_every_run_step_the_strict_template

Workflow 3 of the course sets `defaults.run.shell: bash` at the top for this reason. One line, and every `run` step in the file gets the strict template.

**[ANIMATION]** end

**The files, precisely.** The runner creates files and puts their paths in environment variables.

**[ANIMATION]** cards: id=files cards=GITHUB__OUTPUT:named_outputs,_under_the_steps_context|GITHUB__ENV:environment_variables_for_later_steps_of_the_job|GITHUB__PATH:a_directory_prepended_to_PATH_for_later_steps|GITHUB__STEP__SUMMARY:Markdown_on_the_run's_summary_page title=Files_the_runner_provides

**[ANIMATION]** step: 1

`GITHUB_OUTPUT`: you append `name=value`. The step, which needs an `id`, then has an output of that name under the `steps` context. Job outputs are limited to 1 MB per job and 50 MB per run.

**[ANIMATION]** step: 2

`GITHUB_ENV`: you append `NAME=value`. Later steps of the job get the environment variable. The writing step itself doesn't. And it can't override variables that start with `GITHUB_` or `RUNNER_`.

**[ANIMATION]** step: 3

`GITHUB_PATH`: you append a directory, and it's prepended to `PATH` for later steps.

**[ANIMATION]** step: 4

`GITHUB_STEP_SUMMARY`: you append Markdown, and it's shown on the run's summary page. The limit is 1 MiB per step, and 20 step summaries are shown per job.

**[ANIMATION]** end

**Crossing a job boundary.** A step output is local to its job. To cross to another job it must be re-exported as a job output, under the `outputs` key of the job, and read in the other job through the `needs` context. Two details: an output that looks like a secret is dropped with a message. And multi-line values use a delimiter form.

What doesn't cross a job boundary this way: files. Job outputs are strings. Files cross as artifacts, which is video 146.

**[ON SCREEN]** Callout: Outdated advice.

Older tutorials write outputs with a line that starts with two colons and `set-output`. That form, and `save-state`, are deprecated since the eleventh of October 2022. They still work with a warning. The planned removal was postponed on the twenty-fourth of July 2023, and the current workflow commands page no longer documents them. The reason for the change is visible in the form itself: it was a magic line on standard output. So any program whose output a step printed, including a test that echoed untrusted input, could set outputs.

## MENTAL MODEL

**[ANIMATION]** stores: id=rooms boxes=a_run_step:a_sealed_room|the_filesystem:the_corridor|a_small_file:the_tube|the_next_job:another_building rows=1:A:a_new_shell_starts|2:A:then_the_room_is_cleared@ghost|3:B:files_you_wrote_are_still_there@ok|4:C:notes,_one_per_line|5:D:only_declared_outputs,_as_strings@hl arrows=4:A>C: title=Rooms,_a_corridor,_a_tube at_1=12 at_2=45 at_3=75

**[ANIMATION]** step: boxes

Think of a job as a row of sealed rooms along one corridor.

**[ANIMATION]** step: 3

Each `run` step is a room. A new shell is started in it, your script runs, the shell exits, and the room is cleared: its variables, its current directory, its shell options. What's left is the corridor, which is the runner's filesystem. Files you wrote to disk are still there for the next step.

**[ANIMATION]** step: 4

Underneath the rooms runs a pneumatic tube: a small file whose path the runner gives to every step. A step may drop notes into it, one per line, `name=value`. When the step ends, the runner reads the notes and makes them available to later steps by name.

**[ANIMATION]** step: 5

Where the picture breaks: the corridor ends at the job. The next job is in another building, on another machine, and neither the corridor nor the tube reaches it. Only what the job declares at its door, under `outputs`, is carried over, and only as a string.

**[ANIMATION]** say: Whether_a_room_has_the_pipefail_rule_depends_on_a_key_you_may_not_have_written

The second break concerns the rooms. They aren't all built alike. Whether a room has the `pipefail` rule depends on a key you may not have written.

## DIAGRAM

**[DIAGRAM]** Draw three boxes in a row, one per step, and label each "new shell process". Then draw the file underneath, with the first step appending to it and the later steps reading through the `steps` context. Last, the job boundary on the right.

```text
  JOB build (one runner, one filesystem)
  +----------------------+   +----------------------+   +----------------------+
  | step id=describe     |   | step                 |   | step id=list         |
  | new shell process    |   | new shell process    |   | new shell process    |
  | export X=1  (lost)   |   | X is empty           |   |                      |
  | cd build    (lost)   |   | back in workspace    |   |                      |
  +----------+-----------+   +-----------^----------+   +----------+-----------+
             | echo "describe=..." >>    | ${{ steps.describe      | echo "files=..." >>
             v "$GITHUB_OUTPUT"          |     .outputs.describe }}v "$GITHUB_OUTPUT"
  ==========================================================================================
   GITHUB_OUTPUT: an append-only file per step; the runner reads it when the step ends
  ==========================================================================================
             |
             |  jobs.build.outputs:  describe, files        (strings only)
             v
  JOB report (another runner):  env: DESCRIBE: ${{ needs.build.outputs.describe }}
                                run: echo "$DESCRIBE"
```

Three mechanisms on one picture. Nothing in the shell survives a step. A named value survives through the file. Only a job output leaves the box.

**[DIAGRAM]** Three mechanisms on one picture: nothing in the shell survives a step; a named value survives through the file; and a job output is the only line that leaves the box.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch20a/step-shell`. The script runs `bash` locally with the two documented templates.

**Step 1: the same script, two templates.**

```bash
cat step.sh
bash -e step.sh
bash --noprofile --norc -eo pipefail step.sh
```

The script has three lines. `set -u`. Then `false` piped into `tee`. Then an `echo` that says the step reached its last line. `false` always fails. Under the first template, does the script reach its last line, and what's the exit status? And under the second? Say it out loud.

**[PAUSE]**

<!-- snippet: ch20a/step-shell/01-pipefail -->
```text
$ cat step.sh
set -u
false | tee /dev/null
echo "the step reached its last line"
# No shell key on Linux or macOS: bash -e {0}
$ bash -e step.sh
the step reached its last line
[exit status: 0]
# shell: bash: bash --noprofile --norc -eo pipefail {0}
$ bash --noprofile --norc -eo pipefail step.sh
[exit status: 1]
```
<!-- /snippet -->

Under `bash -e`, the last line is printed and the exit status is 0. The step would be green, although `false` failed, because `tee` succeeded. There's the green failure from the opening. Under the `shell: bash` template the same script stops with status 1 and never prints the line.

This answers the CTO's fourth question. A green job proves only that the last command of every pipeline succeeded, unless the shell was declared.

Try it now, thirty seconds, in your own terminal. Type `false | tee /dev/null`, press Enter, then type `echo $?`. Nothing is written anywhere. Which number do you get?

**[PAUSE]**

Zero. `echo $?` prints the exit status of the line before it, and a pipeline reports its last command. `tee` succeeded, so the failure of `false` is gone.

**Step 2: a new process per step.**

```bash
cat step1.sh
bash -e step1.sh
cat step2.sh
bash -e step2.sh
```

The first script exports `BUILD_ID`, changes into `build`, and prints the directory. The second prints `BUILD_ID` and the directory. What does the second script print? Make your prediction.

**[PAUSE]**

<!-- snippet: ch20a/step-shell/02-new-process-per-step -->
```text
$ cat step1.sh
export BUILD_ID=build-42
cd build
pwd
$ bash -e step1.sh
$LAB/ch20a/step-shell/build
$ cat step2.sh
echo "BUILD_ID is [${BUILD_ID:-}]"
pwd
$ bash -e step2.sh
BUILD_ID is []
$LAB/ch20a/step-shell
```
<!-- /snippet -->

`BUILD_ID` is empty, and the directory is the starting directory again. The export and the `cd` of the first script didn't reach the second. On a runner the same happens between steps. That's why `defaults.run.working-directory` and `GITHUB_ENV` exist.

**Step 3: `GITHUB_OUTPUT`.**

```bash
export GITHUB_OUTPUT="$PWD/step-describe.output"
echo "describe=..." >> "$GITHUB_OUTPUT"
cat "$GITHUB_OUTPUT"
```

On a runner the path is given to each step. Here a file in the sandbox stands in for it.

<!-- snippet: ch20a/step-shell/03-github-output -->
```text
# The runner gives each step a file path in GITHUB_OUTPUT. A file stands in for it here.
$ export GITHUB_OUTPUT="$PWD/step-describe.output"
$ echo "describe=v0.1.0-1-g$(printf abc1234)" >> "$GITHUB_OUTPUT"
$ echo "files=inventory_api-0.1.0.tar.gz inventory_api-0.1.0-py3-none-any.whl" >> "$GITHUB_OUTPUT"
$ cat "$GITHUB_OUTPUT"
describe=v0.1.0-1-gabc1234
files=inventory_api-0.1.0.tar.gz inventory_api-0.1.0-py3-none-any.whl
# A multi-line value needs the delimiter form:
$ printf "notes<<EOF_NOTES\nline one\nline two\nEOF_NOTES\n" >> "$GITHUB_OUTPUT"
$ cat "$GITHUB_OUTPUT"
describe=v0.1.0-1-gabc1234
files=inventory_api-0.1.0.tar.gz inventory_api-0.1.0-py3-none-any.whl
notes<<EOF_NOTES
line one
line two
EOF_NOTES
```
<!-- /snippet -->

The file is an append-only list of assignments. Two single-line values first. Then a multi-line value in the delimiter form: the name, two less-than signs and a delimiter word, the lines, and the delimiter word again.

Two habits, both from the textbook. Always quote the variable. And always use two greater-than signs: a single one discards what earlier lines of the same step wrote.

**Step 4: the deprecated form.**

<!-- snippet: ch20a/step-shell/04-deprecated-set-output -->
```text
# The deprecated form wrote a command to standard output, where any program can print it:
$ echo "::set-output name=describe::v0.1.0"
::set-output name=describe::v0.1.0
```
<!-- /snippet -->

It's an `echo`. The "command" is whatever appears on standard output. Any program that prints that line sets an output. When you see it in an inherited workflow, replace it.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough, with `workflows/03-build.yml` on screen first.

Read the file in the order you know. Trigger: pushes to `main`, tags that start with `v`, and manual runs. Permissions: read. Then the line this video is about: `defaults.run.shell: bash`.

**[ANIMATION]** run: id=jobs event=push ref=main jobs=build|report:build artifact=build>report:outputs title=workflows/03-build.yml:_what_crosses_from_build_to_report at_event=0 at_jobs=6 at_data=42

**[ANIMATION]** step: data

In the `build` job, the step with the ID `describe` appends one line to `GITHUB_OUTPUT`. The job declares two outputs that refer to step outputs. The `report` job says `needs: build`, runs on a new machine, maps the two job outputs into `env`, and writes them into the step summary. The comment in the file says it: nothing from the build job is here except what `needs` hands over.

**[ANIMATION]** end

Now Lab 26.3 on your practice repository, in your normal shell. The interface changes. The lab text and the linked documentation are the reference, and no GitHub output was captured by the authors. After the merge to `main` starts a run, open the run, open the `build` job, and expand a `run` step. Look in the step's log for where it states the shell that ran your script, and compare it with the template table. The textbook doesn't describe that part of the log, so treat what you find as your own observation and check it against the documented templates. Then open the run's summary page and find the two values that crossed from one job to the other.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Piping a test command into `tee` in a step without a `shell` key.** Root cause: the implicit template is `bash -e` without `pipefail`, so the pipeline's status is that of `tee`.
2. **Setting a variable or changing directory in one step and relying on it in the next.** Root cause: each `run` step is a new shell process.
3. **Writing to `GITHUB_OUTPUT` with a single `>`.** Root cause: that truncates the file and discards what earlier lines of the same step wrote.
4. **Reading a step's output from another job.** Root cause: a step output is local to its job; it must be re-exported as a job output and read through `needs`.
5. **Assuming `bash` inside a job container.** Root cause: the default shell there is `sh`.

## PRODUCTION EXAMPLE

Now, out of the lab. The nightly evaluation from the hook, on an AI and ML team. The step is one line: run the evaluation, pipe the output into `tee` to keep the report as a file, and upload the file afterwards. The workflow has no `shell` key anywhere.

**[ANIMATION]** cards: id=diag cards=what_ran_the_script?:bash_-e_and_the_file|the_status_of_a_pipeline?:the_status_of_its_last_command|which_command_is_last?:tee numbered=on title=The_diagnosis,_in_the_reading_order at_1=14 at_2=40 at_3=82

**[ANIMATION]** step: 3

The diagnosis follows the reading order. What ran the script? `bash -e` and the file. What's the status of a pipeline under that invocation? The status of the last command. Which command is last? `tee`.

**[ANIMATION]** say: Two_repairs:_declare_shell:_bash,_or_take_the_command_out_of_the_pipeline

There are two repairs, and they're the two ways to get the strict template or its effect: declare `shell: bash` for the step or as a default for the file, or stop using a pipeline for the command whose status matters. The prevention is a line in the team's workflow template: `defaults.run.shell: bash` at the top of every file, as workflow 3 has it.

## PRACTICE EXERCISE

**[ANIMATION]** end

Your turn. Do Exercise 26.5, "Two shells, three scripts", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

For each script and each shell, predict the exit status and the last line printed before you check anything. Write the full command line the runner would use beside each prediction.

The challenge is Exercise 28.2, "The nightly evaluation that never fails", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q284: "A job is green although `pytest | tee report.txt` had failing tests. Give the exact shell command line the runner used, and two ways to fix it."

**[PAUSE]**

Answer out loud first. A strong answer quotes the template, option by option, and says which option is missing and what that option does to the status of a pipeline. It gives two repairs that are different in kind, and says which one it would make the team default. The follow-up moves the step into a job that runs in a container: recall what the default shell is there, and reason about what that does to both of your repairs.

## RECAP

**[ANIMATION]** step: green.3

**[ANIMATION]** say: Without_pipefail,_the_step_reported_the_status_of_tee

Let's land this. The green job from the opening, in one line: without `pipefail`, the step reported the status of `tee`.

You should now be able to say:

- Without a `shell` key on Linux the runner executes `bash -e`; with `shell: bash` it executes `bash --noprofile --norc -eo pipefail`.
- Without `pipefail`, a pipeline's status is its last command's, so a failing command piped into `tee` leaves the step green.
- Each `run` step is a new process; exports and `cd` do not survive it.
- A value reaches a later step through `GITHUB_OUTPUT` and the `steps` context, and a later job through a declared job output and `needs`.
- The `set-output` form is deprecated; replace it when you see it.

## HOMEWORK

Read section 20A.7 of [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md).

Today you reproduced a green failure in two lines, and you can carry a value across a step and across a job. Before the next video, look for a pipe in a workflow you know, and check for a `shell` key. Next time: what the checkout action does by default. One commit, no tags, and the merge ref. Until then, look at the state first and type second. See you in the next one.
