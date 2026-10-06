# V144: Shells, and passing data between steps and jobs

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 26
- **Planned minutes.** 18
- **Prerequisites.** V143
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), section 20A.7
- **Demo scripts.** `labs/ch20a/step-shell.sh`, then a screen walkthrough of Lab 26.3 in [`lab-manual/m26-actions-fundamentals.md`](../../lab-manual/m26-actions-fundamentals.md) with [`workflows/03-build.yml`](../../workflows/03-build.yml)

## HOOK

**[ON SCREEN]** Question 4 of section 20A.1: "The job is green. Did the tests run, or did a pipe swallow the failure?"

A nightly evaluation job has been green for three weeks. Someone opens the saved report by chance and finds failing tests in it, from the first of those nights on. The step ran the tests and piped their output into `tee`, to keep a copy of the log. The tests failed. `tee` succeeded. The step was green.

Nobody wrote a wrong command. The command was run by a shell with options nobody had looked up. In this video you look them up, and you reproduce the green failure on your own machine in two lines.

## INTRODUCTION

You know from V142 that a step is the unit of process: each `run` step is a new shell process. This video takes that sentence seriously, in two directions.

First: which shell, started how? The runner uses a documented command template, and the template differs depending on whether you wrote a `shell` key or not. That difference decides whether a failing command in a pipeline fails the step.

Second: if every step is a new process, how does anything get from one step to the next, and from one job to the next? Through files that the runner provides, and through declared job outputs.

The demonstration reproduces the runner's shell invocation locally. It is the same `bash` with the same options, on your Mac. Nothing runs on GitHub.

## LEARNING OBJECTIVES

After this video you can:

- state the default shell and its options for a `run` step on a Linux runner;
- explain why a pipeline with a failing first command can leave a step green, and fix it;
- explain why a variable set in one step is gone in the next;
- pass a value to a later step and to a later job through `GITHUB_OUTPUT` and job outputs;
- recognize the deprecated command the section names.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**In one sentence.** Every `run` step is a new shell process started from a documented command template, so state survives a step only if it is written to a file the runner provides: `GITHUB_OUTPUT` for named outputs, `GITHUB_ENV` for environment variables, `GITHUB_STEP_SUMMARY` for a report.

**The shell, precisely.** The runner writes your `run` text to a temporary script file and executes it with a template in which a placeholder stands for that file.

**[ON SCREEN]** The template table of section 20A.7.

If you write nothing, on Linux or macOS, the runner executes `bash -e` with the file.

If you write `shell: bash`, on any platform, it executes `bash --noprofile --norc -eo pipefail` with the file.

If you write nothing on Windows: PowerShell Core.

If you write nothing inside a job container on Linux: `sh`, not `bash`.

And `shell: python` runs the file with Python.

Look at the first two rows again, because they are the hook. Both have `-e`. Only the second has `pipefail`.

`-e` stops the script at the first command that fails. It does not look inside a pipeline. The status of a pipeline is the status of its last command, unless `pipefail` is set. So the implicit default lets a failing test command piped into `tee` pass.

The irony is worth saying aloud: writing `shell: bash` explicitly, which looks like stating the default, changes the behavior. It is not the default. The default is a weaker invocation of the same program.

Workflow 3 of the course sets `defaults.run.shell: bash` at the top for this reason. One line, and every `run` step in the file gets the strict template.

**The files, precisely.** The runner creates files and puts their paths in environment variables.

`GITHUB_OUTPUT`: you append `name=value`. The step, which needs an `id`, then has an output of that name under the `steps` context. Job outputs are limited to 1 MB per job and 50 MB per run.

`GITHUB_ENV`: you append `NAME=value`. Later steps of the job get the environment variable. The writing step itself does not. And it cannot override variables that start with `GITHUB_` or `RUNNER_`.

`GITHUB_PATH`: you append a directory, and it is prepended to `PATH` for later steps.

`GITHUB_STEP_SUMMARY`: you append Markdown, and it is shown on the run's summary page. The limit is 1 MiB per step, and 20 step summaries are shown per job.

**Crossing a job boundary.** A step output is local to its job. To cross to another job it must be re-exported as a job output, under the `outputs` key of the job, and read in the other job through the `needs` context. Two details: an output that looks like a secret is dropped with a message. And multi-line values use a delimiter form.

What does not cross a job boundary this way: files. Job outputs are strings. Files cross as artifacts, which is V146.

**[ON SCREEN]** Callout: Outdated advice.

Older tutorials write outputs with a line that starts with two colons and `set-output`. That form, and `save-state`, are deprecated since 11 October 2022. They still work with a warning. The planned removal was postponed on 24 July 2023, and the current workflow commands page no longer documents them. The reason for the change is visible in the form itself: it was a magic line on standard output. So any program whose output a step printed, including a test that echoed untrusted input, could set outputs.

## MENTAL MODEL

Think of a job as a row of sealed rooms along one corridor.

Each `run` step is a room. A new shell is started in it, your script runs, the shell exits, and the room is cleared: its variables, its current directory, its shell options. What is left is the corridor, which is the runner's filesystem. Files you wrote to disk are still there for the next step.

Underneath the rooms runs a pneumatic tube: a small file whose path the runner gives to every step. A step may drop notes into it, one per line, `name=value`. When the step ends, the runner reads the notes and makes them available to later steps by name.

Where the picture breaks: the corridor ends at the job. The next job is in another building, on another machine, and neither the corridor nor the tube reaches it. Only what the job declares at its door, under `outputs`, is carried over, and only as a string.

The second break concerns the rooms. They are not all built alike. Whether a room has the `pipefail` rule depends on a key you may not have written.

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

**[DIAGRAM]** Three mechanisms on one picture: nothing in the shell survives a step; a named value survives through the file; and a job output is the only line that leaves the box.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch20a/step-shell`. The script runs `bash` locally with the two documented templates.

**Step 1: the same script, two templates.**

```bash
cat step.sh
bash -e step.sh
bash --noprofile --norc -eo pipefail step.sh
```

The script has three lines. `set -u`. Then `false` piped into `tee`. Then an `echo` that says the step reached its last line. **[PAUSE]** `false` always fails. Under the first template, does the script reach its last line, and what is the exit status? And under the second?

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

Under `bash -e`, the last line is printed and the exit status is 0. The step would be green, although `false` failed, because `tee` succeeded. Under the `shell: bash` template the same script stops with status 1 and never prints the line.

This answers the CTO's fourth question. A green job proves only that the last command of every pipeline succeeded, unless the shell was declared.

**Step 2: a new process per step.**

```bash
cat step1.sh
bash -e step1.sh
cat step2.sh
bash -e step2.sh
```

The first script exports `BUILD_ID`, changes into `build`, and prints the directory. The second prints `BUILD_ID` and the directory. **[PAUSE]** What does the second script print?

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

`BUILD_ID` is empty, and the directory is the starting directory again. The export and the `cd` of the first script did not reach the second. On a runner the same happens between steps. That is why `defaults.run.working-directory` and `GITHUB_ENV` exist.

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

It is an `echo`. The "command" is whatever appears on standard output. Any program that prints that line sets an output. When you see it in an inherited workflow, replace it.

**[ON SCREEN]** Lower third: GitHub Actions. Screen walkthrough, with `workflows/03-build.yml` on screen first.

Read the file in the order you know. Trigger: pushes to `main`, tags that start with `v`, and manual runs. Permissions: read. Then the line this video is about: `defaults.run.shell: bash`.

In the `build` job, the step with the ID `describe` appends one line to `GITHUB_OUTPUT`. The job declares two outputs that refer to step outputs. The `report` job says `needs: build`, runs on a new machine, maps the two job outputs into `env`, and writes them into the step summary. The comment in the file says it: nothing from the build job is here except what `needs` hands over.

Now Lab 26.3 on your practice repository, in your normal shell. The interface changes; the lab text and the linked documentation are the reference, and no GitHub output was captured by the authors. After the merge to `main` starts a run, open the run, open the `build` job, and expand a `run` step. Look in the step's log for where it states the shell that ran your script, and compare it with the template table. The textbook does not describe that part of the log, so treat what you find as your own observation and check it against the documented templates. Then open the run's summary page and find the two values that crossed from one job to the other.

## COMMON MISTAKES

1. **Piping a test command into `tee` in a step without a `shell` key.** Root cause: the implicit template is `bash -e` without `pipefail`, so the pipeline's status is that of `tee`.
2. **Setting a variable or changing directory in one step and relying on it in the next.** Root cause: each `run` step is a new shell process.
3. **Writing to `GITHUB_OUTPUT` with a single `>`.** Root cause: that truncates the file and discards what earlier lines of the same step wrote.
4. **Reading a step's output from another job.** Root cause: a step output is local to its job; it must be re-exported as a job output and read through `needs`.
5. **Assuming `bash` inside a job container.** Root cause: the default shell there is `sh`.

## PRODUCTION EXAMPLE

The nightly evaluation from the hook, on an AI/ML team. The step is one line: run the evaluation, pipe the output into `tee` to keep the report as a file, and upload the file afterwards. The workflow has no `shell` key anywhere.

The diagnosis follows the reading order. What ran the script? `bash -e` and the file. What is the status of a pipeline under that invocation? The status of the last command. Which command is last? `tee`.

There are two repairs, and they are the two ways to get the strict template or its effect: declare `shell: bash` for the step or as a default for the file, or stop using a pipeline for the command whose status matters. The prevention is a line in the team's workflow template: `defaults.run.shell: bash` at the top of every file, as workflow 3 has it.

## PRACTICE EXERCISE

Do Exercise 26.5, "Two shells, three scripts", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

For each script and each shell, predict the exit status and the last line printed before you check anything. Write the full command line the runner would use beside each prediction.

The challenge is Exercise 28.2, "The nightly evaluation that never fails", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q284: "A job is green although `pytest | tee report.txt` had failing tests. Give the exact shell command line the runner used, and two ways to fix it."

A strong answer quotes the template, option by option, and says which option is missing and what that option does to the status of a pipeline. It gives two repairs that are different in kind, and says which one it would make the team default. The follow-up moves the step into a job that runs in a container: recall what the default shell is there, and reason about what that does to both of your repairs.

## RECAP

You should now be able to say:

- Without a `shell` key on Linux the runner executes `bash -e`; with `shell: bash` it executes `bash --noprofile --norc -eo pipefail`.
- Without `pipefail`, a pipeline's status is its last command's, so a failing command piped into `tee` leaves the step green.
- Each `run` step is a new process; exports and `cd` do not survive it.
- A value reaches a later step through `GITHUB_OUTPUT` and the `steps` context, and a later job through a declared job output and `needs`.
- The `set-output` form is deprecated; replace it when you see it.

## HOMEWORK

Read section 20A.7 of [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md).
