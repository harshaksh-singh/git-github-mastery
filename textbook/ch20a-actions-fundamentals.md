# Chapter 20A: GitHub Actions Fundamentals

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026, with the quoted documentation pages and action READMEs re-read on 2 October 2026. Transcripts are real output from `labs/ch20a/`. Nothing in this chapter was run on GitHub. The eight workflow files in `workflows/` were parse-checked with PyYAML and assembled from documented syntax and from each action's `action.yml` at the pinned version; they were **not executed on GitHub by the author**. The labs of Module 26 have you run them. Every statement about what GitHub Actions does carries the link it was taken from.

## 20A.1 Why this matters

Four questions a CTO can ask about one pull request:

1. "The tests passed on your laptop and failed in CI on the same commit. Was it the same commit?"
2. "The build stamped the release as `6fe5455` and not as a version. Who removed the tags?"
3. "This workflow has a `paths` filter and is a required check. Why is the pull request waiting forever?"
4. "The job is green. Did the tests run, or did a pipe swallow the failure?"

None of these is answered by knowing YAML keys. Each is answered by knowing what a runner has on disk and in its environment when your command starts: which commit, how much history, which shell with which flags, which token, which variables. This chapter builds that picture from the documentation and, wherever plain Git can show the mechanism, from a local transcript. The answers: question 1 in section 20A.8, question 2 in 20A.8, question 3 in 20A.4 and 20A.16, question 4 in 20A.7.

Two neighbors complete the subject. [Chapter 20B: Delivery, runners, cost and debugging](ch20b-actions-delivery-debugging.md) covers environments, deployments, concurrency in depth, reusable workflows, runners, billing and the investigation order for a failing run. [Chapter 21A: GitHub Actions security](ch21a-actions-security.md) covers the job token, fork pull requests, `pull_request_target`, injection, and pinning. This chapter mentions those topics only where a fundamental cannot be stated without them.

> **GitHub, not Git.** Everything in this chapter except the repository content is GitHub Actions: a service that reacts to events on GitHub by running commands on machines. Git appears in exactly one place, when a job fetches commits onto the runner. That place causes most of the surprises.

## 20A.2 The model: workflow, event, job, step, action, runner, shell

**In one sentence.** A workflow is a YAML file in the repository that says "when this event happens, run these jobs"; each job is a list of steps that run in order on one fresh machine called a runner; a step is either a shell command or an action, which is a packaged program.

**Analogy.** A workflow is a standing order at a print shop: "whenever a manuscript arrives (event), give one copy to the proofreader and one to the typesetter (two jobs), each at a clean desk (runner), each following a numbered checklist (steps), some items of which say 'use the house stamping machine' (an action)". The analogy breaks in two places. The desks are destroyed after each job, so nothing left on one is found by the next. And the manuscript is not handed over: the worker must fetch it, and by default fetches only the last page (section 20A.8).

**Precisely.** The terms, as the [workflow syntax reference](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) uses them:

| Term | Definition | Where it is written |
|---|---|---|
| Workflow | A configurable automated process defined by a YAML file. The file must be in `.github/workflows` and end in `.yml` or `.yaml` | the file itself |
| Event | An activity on GitHub (a push, a pull request activity, a release), a schedule, or a manual or API request | not written; it happens |
| Trigger | The `on` key of a workflow: which events, with which filters, start a run | `on:` |
| Workflow run | One execution of a workflow for one event. It has a run ID, a run number and, when re-run, an attempt number | created by GitHub |
| Job | A set of steps that execute on the same runner. Jobs of one run execute in parallel unless `needs` orders them | `jobs.<job_id>` |
| Step | One `run` command line (or script) or one `uses` reference to an action. Steps of a job execute in order | `jobs.<job_id>.steps[*]` |
| Action | A reusable program referenced by `uses: owner/repo@ref`. It is a JavaScript program, a composite of steps, or a Docker container, declared by the `action.yml` in its repository | another repository |
| Runner | The machine that executes one job. A GitHub-hosted runner is a new virtual machine per job, chosen by `runs-on` | `jobs.<job_id>.runs-on` |
| Shell | The program that executes a `run` step. Each `run` step is a new process | `shell:`, or the default |

Three properties follow from the definitions and explain most of what later sections show:

- **A job is the unit of isolation.** A job starts on a fresh machine ([GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)). Files, installed tools and environment variables do not carry from job to job. Data crosses jobs only as job outputs (strings), artifacts (files) or caches (files, best effort).
- **A step is the unit of process.** Steps of one job share the filesystem of the runner, but each `run` step is a new shell process. A `cd` or an `export` in one step is gone in the next (section 20A.7).
- **The workflow file is versioned with the code.** For `push` and `pull_request` the workflow definition is read from the commit the event refers to, so a branch can change its own CI. For several other events it is read from the default branch only (section 20A.4).

**Inside `.git`.** A workflow is an ordinary blob at the path `.github/workflows/<name>.yml` in a commit's tree. Nothing else in the repository's Git data describes Actions. Runs, jobs, logs, artifacts, caches, secrets and variables are GitHub objects: a clone does not contain them and `git log` cannot show them.

**Picture.**

```text
 EVENT on GitHub                 WORKFLOW RUN (one per event per workflow file)
 push to main  ───────────────►  .github/workflows/03-build.yml, read from the pushed commit
                                 │
                 ┌───────────────┴────────────────┐
                 ▼                                ▼
        JOB build                         JOB report          (needs: build, so it waits)
        runner: new VM, ubuntu-24.04      runner: another new VM
        ┌──────────────────────────┐      ┌──────────────────────────┐
        │ step 1  uses: checkout   │      │ step 1  run: write the   │
        │         (an ACTION)      │      │         job summary      │
        │ step 2  run: git describe│      │         (a SHELL process)│
        │         (a SHELL process)│      └──────────────────────────┘
        │ step 3  uses: setup-uv   │               ▲
        │ step 4  run: uv build    │               │ job outputs (strings)
        └──────────────────────────┘ ──────────────┘
          files stay on this VM; the VM is discarded when the job ends
```

## 20A.3 YAML read carefully

**In one sentence.** A workflow file is data, not a script: a YAML parser turns it into nested maps, lists and scalars before GitHub Actions interprets any key, so indentation and quoting decide what GitHub sees.

**Precisely.** Four rules cover the mistakes that occur in workflow files.

1. **Indentation is structure, and tabs are not indentation.** A key belongs to the map whose column it sits in. A tab character in indentation is a syntax error.
2. **An unquoted scalar is typed by its shape.** `3.10` is a number, and the number is 3.1. `v1.0` is a string because of the `v`. Quote everything that is a version, a label or a glob: `"3.10"`, `"v*"`, `"**/*.py"`. The [filter pattern cheat sheet](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#filter-pattern-cheat-sheet) adds that patterns starting with `*`, `[` or `!` must be quoted, because those characters are YAML syntax.
3. **`|` keeps line breaks, `>` folds them into spaces.** A multi-line `run` script needs `|`.
4. **`&name` marks a node and `*name` reuses it.** Anchors and aliases are standard YAML and have been accepted in workflow files since 18 September 2025 ([changelog](https://github.blog/changelog/2025-09-18-actions-yaml-anchors-and-non-public-workflow-templates/), [reference](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations#yaml-anchors-and-aliases)).

**See it.** The parser below is PyYAML, the library that parse-checks the course workflows. It implements YAML 1.1. GitHub uses its own parser, so read each result with the note that follows it.

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

`3.10` became `3.1`: a matrix written `python: [3.9, 3.10]` asks for Python 3.1. This is a property of numbers, not of one parser, and it is why the READMEs of `actions/setup-python` and `astral-sh/setup-uv` quote every version. The values `yes` and `NO` became booleans because YAML 1.1 says so.

> **Unverified.** Whether GitHub's workflow parser also reads unquoted `yes`, `no`, `on` and `off` values as booleans is not stated on the documentation pages read for this chapter. Quote such values and the question does not arise.

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

The key `on` came out as the boolean `true`. GitHub Actions documents `on` as the trigger key and reads it as such; a generic YAML 1.1 tool does not. The practical consequence is for your own tooling: a script that loads workflow files with PyYAML must look up the key `True`, which is what `tools/check_course.py` of this course does. Notice also `pull_request: null`. An event with no configuration is a key with an empty value, and the documentation requires the colon on every event once any event in the map has configuration ([`on`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#on)).

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

After parsing, the alias is indistinguishable from a copy. An anchor therefore removes repetition inside one file and nothing more; it cannot cross files. For that, Chapter 20B covers reusable workflows and composite actions.

> **Unverified.** YAML merge keys (`<<: *name`) are not mentioned by the anchors documentation or the changelog entry. The course's research notes mark their support as unverified. The examples in this course do not use them.

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

With `>` the two commands became one line, `uv sync --locked uv run pytest`, which is one wrong command and not two right ones.

<!-- snippet: ch20a/yaml-reading/05-tab -->
```text
$ python3 -c "$show" tab.yml 2>&1 | tail -3
yaml.scanner.ScannerError: while scanning for the next token
found character '\t' that cannot start any token
  in "tab.yml", line 5, column 1
[exit status: 0]
```
<!-- /snippet -->

## 20A.4 Events and filters

**In one sentence.** The `on` key lists the events that start a run; each event fixes which commit and ref the run is about and which copy of the workflow file is used, and filters narrow an event to branches, tags or paths.

**Precisely.** `on` takes one event (`on: push`), a list (`on: [push, pull_request]`), or a map from event to its configuration. The eight events a backend or ML team uses constantly, with the values the [events reference](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) gives for the commit (`GITHUB_SHA`) and the ref (`GITHUB_REF`):

| Event | Starts when | `GITHUB_SHA` | `GITHUB_REF` | Notes from the reference |
|---|---|---|---|---|
| `push` | commits or tags are pushed | tip commit pushed to the ref | the updated ref | runs for any branch, including workflows not merged into the default branch |
| `pull_request` | a pull request is opened, gets new commits (`synchronize`) or is reopened; other activity types need `types:` | last merge commit on the `GITHUB_REF` branch | `refs/pull/N/merge` | does not run while the pull request has a merge conflict |
| `workflow_dispatch` | someone starts it by hand, the CLI or the API | last commit on the chosen branch or tag | the branch or tag that received the dispatch | only if the workflow file exists on the default branch; up to 25 inputs |
| `schedule` | a POSIX cron expression matches | last commit on the default branch | the default branch | UTC unless a `timezone` is given; shortest interval 5 minutes; can be delayed or dropped under load; disabled after 60 days without repository activity in a public repository |
| `workflow_call` | another workflow calls this one | same as the caller | same as the caller | makes the workflow reusable (Chapter 20B) |
| `workflow_run` | another workflow is requested, in progress or completed | last commit on the default branch | the default branch | only if the file exists on the default branch; can read secrets even when the first workflow could not (Chapter 21A) |
| `merge_group` | a pull request enters a merge queue (`checks_requested`) | the commit of the merge group | the ref of the merge group | required checks must listen to it or the queue never gets a result (Chapter 17, section 17.11) |
| `release` | a release is published, created, edited and so on | last commit in the tagged release | `refs/tags/<tag_name>` | subscribe to `published` to cover stable and pre-releases |

Read the table as three families. `push`, `pull_request`, `merge_group` and `release` are about a specific commit that somebody produced. `schedule` and `workflow_run` are about the default branch, whatever happened elsewhere. `workflow_dispatch` is about whatever ref the person chose.

One event is deliberately not in the table: `pull_request_target`. It starts on the same pull request activity as `pull_request`, but it is about the base repository: the workflow file comes from the default branch and the job receives the base repository's token and secrets. Chapter 18, section 18.8 counts its checks, and [Chapter 21A](ch21a-actions-security.md), section 21A.5 explains when it is safe; do not use it before reading that section.

**Filters.** `push` accepts `branches`, `branches-ignore`, `tags`, `tags-ignore`, `paths` and `paths-ignore`. `pull_request` accepts `branches` and `branches-ignore`, which match the **base** branch, and the two path filters. The rules that matter ([filters](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore)):

- A positive and an `-ignore` filter of the same kind cannot be combined for one event. Use `!pattern` inside the positive filter; order matters.
- When a branch filter and a path filter are both present, the workflow runs only when both are satisfied.
- Path filters are not evaluated for pushes of tags.
- Path filters compare with a **three-dot diff for pull requests and a two-dot diff for pushes** ([diff comparisons](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#git-diff-comparisons)). A push with more than 1,000 commits, or a diff that times out, always runs the workflow; a diff of more than 3,000 files in which the match is not among the first 3,000 does not.

**See it.** Those two diffs are plain Git (Chapter 14A covers range notation), so you can predict a path filter before pushing. The repository has a pull request branch that touches only Python files, while `main` moved on.

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

The three-dot form compares the merge base with the head, so it lists what the branch did. The two-dot form compares the tips and blames the branch for `stock.py`, which changed on `main`. For a pull request GitHub uses the first. For a push it uses two dots between the old and new tip of the pushed branch, which is the same thing as "the commits you just pushed":

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

**In production.** A monorepo with a Python service and a Java service gives each its own workflow with a `paths` filter, so a documentation change does not spend twenty runner minutes on Maven. The saving has a price that question 3 of section 20A.1 names: a workflow that a filter skips never creates its check, and a ruleset that requires that check waits for a result that will not come ([troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks)). Section 20A.16 gives the fix. The same applies to commits whose message contains `[skip ci]` and its documented variants, which skip `push` and `pull_request` workflows ([skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs)).

> **GitHub, not Git.** Events created by a workflow's own job token do not start new workflow runs, with documented exceptions (`workflow_dispatch`, `repository_dispatch`, and pull request events, which wait for approval since 11 June 2026) ([GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token), [changelog](https://github.blog/changelog/2026-06-11-bot-created-pull-requests-can-run-workflows-if-approved/)). A job that pushes a commit with the job token does not trigger the `push` workflows for that commit.

## 20A.5 Contexts and expressions

**In one sentence.** A context is a named object of facts about the run (`github`, `matrix`, `steps`, and others), and an expression, written `${{ ... }}`, is a small formula over contexts that GitHub Actions replaces with its value before your step starts.

**Analogy.** An expression is a mail-merge field. The letter (your step) is printed with the field already filled in; the recipient (the shell) never sees the field, only the text. The analogy is exact about the danger and incomplete about the timing: text substituted into a script becomes part of the script, which is how untrusted pull request titles become shell commands (Chapter 21A), and not every field is available in every place.

**Precisely.** The contexts, from the [contexts reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts):

| Context | Holds | Typical use |
|---|---|---|
| `github` | the event and the run: `event_name`, `event` (the full webhook payload), `ref`, `ref_name`, `sha`, `head_ref` and `base_ref` (pull request events only), `actor`, `repository`, `run_id`, `run_number`, `run_attempt`, `workflow` | conditions, names, concurrency groups |
| `env` | variables set with `env:` in the workflow, job or step | passing configuration to steps |
| `vars` | configuration variables stored in GitHub settings | non-secret settings per repository or environment |
| `secrets` | secrets, including `GITHUB_TOKEN` | credentials |
| `inputs` | inputs of `workflow_dispatch` or `workflow_call` | manual and reusable workflows |
| `matrix`, `strategy` | the current matrix combination and the strategy settings | matrix jobs |
| `steps` | per earlier step with an `id`: `outputs`, `outcome`, `conclusion` | using a step's result |
| `needs` | per job listed in `needs`: `outputs`, `result` | using a job's result |
| `job`, `runner` | the running job (`status`, service ports) and its machine (`os`, `arch`, `temp`, `environment`) | paths, conditions on platform |
| `jobs` | job results, in reusable workflows only | outputs of a called workflow |

Rules of the expression language ([expressions](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions)):

- Literals are booleans, `null`, numbers and strings. **Strings use single quotes** inside `${{ }}`; double quotes are an error.
- Operators are `( ) [ ] . ! < <= > >= == != && ||`. String comparison ignores case. When the two sides of `==` differ in type, both are converted to numbers, and a string that is not a number becomes `NaN`.
- The falsy values are `false`, `0`, `-0`, `""`, `''` and `null`.
- A property that does not exist evaluates to an empty string, without an error. A typo in `steps.buld.outputs.version` is therefore silent.
- Functions: `contains`, `startsWith`, `endsWith`, `format`, `join`, `toJSON`, `fromJSON`, `hashFiles`, `case`, and the status functions `success()`, `failure()`, `cancelled()`, `always()`.
- `hashFiles(pattern)` computes a SHA-256 per matched file and then one SHA-256 over those; the pattern is relative to the workspace, and no match gives an empty string.
- `case(pred1, val1, pred2, val2, ..., default)` returns the value for the first true predicate, and has existed since 29 January 2026 ([changelog](https://github.blog/changelog/2026-01-29-github-actions-smarter-editing-clearer-debugging-and-a-new-case-function/)). Older files imitate it with `cond && a || b`, which returns `b` whenever `a` is falsy.

**Context availability is per key.** Not every context exists everywhere ([context availability](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability)). A job-level `if` can read `github`, `needs`, `vars` and `inputs`, but not `matrix`, `steps`, `env` or `secrets`. A step-level `if` can read `matrix`, `steps` and `env`, but still not `secrets`. `hashFiles` works only in step keys. The reason is timing: a job-level `if` is decided before a runner exists, so nothing that lives on the runner can take part.

**The trap in `if`.** In an `if`, the `${{ }}` wrapper is optional unless the expression starts with `!`. Text outside the wrapper turns the whole value into a non-empty string, which is truthy, so the condition is always true. Since 29 January 2026 the editor validation flags this and the run shows an annotation (same changelog as above).

```yaml
if: ${{ github.event_name == 'push' }}            # an expression
if: github.event_name == 'push'                   # the same expression
if: ${{ github.event_name == 'push' }} && true    # a string, always truthy
```

**Picture.** Where each piece is evaluated:

```text
  workflow file                 GitHub Actions service             runner
  ───────────────               ───────────────────────            ───────────────────────────
  on:, jobs.<id>.if,     ───►   evaluated before a runner
  strategy.matrix               is assigned
  steps[*].if, with:,    ───►                              ───►    evaluated per step, on the
  env:, run: ${{ ... }}                                            runner, BEFORE the shell starts
  run: echo "$NAME"                                        ───►    expanded by the shell, at run time
```

**In production.** The difference between the last two rows is a security boundary. `run: echo "${{ github.event.pull_request.title }}"` pastes the title into the script text. `env: TITLE: ${{ github.event.pull_request.title }}` followed by `run: echo "$TITLE"` hands the title to the shell as data. Every course workflow uses the second form, including for values that are not attacker-controlled, so that the habit is uniform. Chapter 21A explains the attack.

## 20A.6 `env`, `vars` and `secrets`

**In one sentence.** `env` is defined in the workflow file and becomes environment variables of the process; `vars` and `secrets` are stored in GitHub settings and are read through contexts; only `secrets` are encrypted and masked.

**Precisely.**

| | `env` | `vars` | `secrets` |
|---|---|---|---|
| Defined in | the workflow file, at workflow, job or step level | settings of the organization, repository or environment | settings of the organization, repository or environment |
| Visible in the repository | yes, it is in the file | no, but readable in settings and logs | no; write-only in settings |
| Reaches a step as | an environment variable, and `${{ env.NAME }}` | `${{ vars.NAME }}` only; map it into `env` to get a variable | `${{ secrets.NAME }}` only; map it into `env` or `with` |
| Same name at several levels | the most specific wins (step over job over workflow) | the lowest level wins: environment over repository over organization | the environment-level secret wins |
| Limits | part of the file | 48 KB each; 1,000 per organization, 500 per repository, 100 per environment | 48 KB each; 1,000 per organization, 100 per repository, 100 per environment |
| Masked in logs | no | no | yes, when the exact value appears; not a guarantee |

Sources: [variables](https://docs.github.com/en/actions/reference/workflows-and-actions/variables), [secrets](https://docs.github.com/en/actions/reference/security/secrets). Names of variables and secrets may contain letters, digits and underscores, must not start with `GITHUB_` or a digit, and are case-insensitive when referenced.

Three behaviors that cause real failures:

- **An unset secret is an empty string, not an error.** A deploy step that receives an empty credential fails later and elsewhere, with a message about authentication ([using secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)).
- **Secrets are not passed to workflows triggered from forks or by Dependabot**, apart from a read-only job token (same page; the security model is Chapter 21A). A fork pull request that "fails only in CI" is often a job that needed a secret.
- **`secrets` cannot be used in `if`.** Map the secret into `env` and test `env.NAME != ''`.

`GITHUB_TOKEN` is a secret that GitHub creates for each job. What it may do is set by the `permissions` key. All eight course workflows declare `permissions: contents: read` at the top, and when any permission is named, every unnamed one becomes `none` ([permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions)). Workflow 6 adds `packages: write` for one job. Least privilege is the subject of Chapter 21A; here it is enough to know that the block is not optional decoration.

The runner also sets default environment variables. The ones this chapter uses: `CI` (always `true`), `GITHUB_SHA`, `GITHUB_REF`, `GITHUB_REF_NAME`, `GITHUB_EVENT_NAME`, `GITHUB_WORKSPACE` (the default working directory of steps), `GITHUB_EVENT_PATH` (a file holding the webhook payload), `RUNNER_OS`, `RUNNER_TEMP`. Each has a `github.` or `runner.` context twin; use the variable inside scripts and the context in YAML keys.

## 20A.7 Shells, and passing data between steps and jobs

**In one sentence.** Every `run` step is a new shell process started from a documented command template, so state survives a step only if it is written to a file the runner provides: `GITHUB_OUTPUT` for named outputs, `GITHUB_ENV` for environment variables, `GITHUB_STEP_SUMMARY` for a report.

**Precisely: the shell.** The runner writes your `run` text to a temporary script file and executes it with a template in which `{0}` is that file ([shell](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepsshell)):

| You write | Platform | Command the runner executes |
|---|---|---|
| nothing | Linux, macOS | `bash -e {0}` |
| `shell: bash` | any | `bash --noprofile --norc -eo pipefail {0}` |
| nothing | Windows | PowerShell Core (`pwsh`) |
| nothing, inside a job `container` | Linux | `sh`, not `bash` |
| `shell: python` | any | `python {0}` |

`-e` stops the script at the first command that fails. It does not look inside a pipeline: the status of a pipeline is the status of its last command unless `pipefail` is set. The implicit default therefore lets `failing-tests | tee log.txt` pass.

**See it.** The two templates, run locally on the same three-line script:

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

Under `bash -e` the step is green although `false` failed, because `tee` succeeded. With the `shell: bash` template the same script stops with status 1. This answers question 4 of section 20A.1: a green job proves only that the last command of every pipeline succeeded, unless the shell was declared. Workflow 3 sets `defaults.run.shell: bash` for this reason.

A new process per step:

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

The export and the `cd` of the first script did not reach the second. On a runner the same happens between steps, which is why `defaults.run.working-directory` and `GITHUB_ENV` exist.

**Precisely: the files.** The runner creates files and puts their paths in environment variables ([workflow commands](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#environment-files)):

| File | You append | Effect | Limits |
|---|---|---|---|
| `GITHUB_OUTPUT` | `name=value` | the step (it needs an `id`) gets `steps.<id>.outputs.name` | job outputs at most 1 MB per job and 50 MB per run |
| `GITHUB_ENV` | `NAME=value` | later steps of the job get the environment variable; the writing step does not | cannot override `GITHUB_*` or `RUNNER_*` |
| `GITHUB_PATH` | a directory | prepended to `PATH` for later steps | |
| `GITHUB_STEP_SUMMARY` | GitHub-flavored Markdown | shown on the run's summary page | 1 MiB per step; 20 step summaries shown per job |

A step output is local to its job. To cross to another job it must be re-exported as a **job output** (`jobs.<id>.outputs`) and read through `needs.<id>.outputs`. An output that looks like a secret is dropped with a message. Multi-line values use a delimiter.

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

The file is an append-only list of assignments that the runner reads when the step ends. Always quote `"$GITHUB_OUTPUT"` and always use `>>`: a single `>` discards what earlier lines of the same step wrote.

> **Outdated advice.** `echo "::set-output name=x::value"` and `::save-state` are deprecated since 11 October 2022. They still work with a warning; the planned removal was postponed on 24 July 2023, and the current workflow commands page no longer documents them ([deprecation](https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/), [postponement](https://github.blog/changelog/2023-07-24-github-actions-update-on-save-state-and-set-output-commands/)). The reason for the change is visible in the transcript below: the old form was a magic line on standard output, so any program whose output a step printed, including a test that echoed untrusted input, could set outputs.

<!-- snippet: ch20a/step-shell/04-deprecated-set-output -->
```text
# The deprecated form wrote a command to standard output, where any program can print it:
$ echo "::set-output name=describe::v0.1.0"
::set-output name=describe::v0.1.0
```
<!-- /snippet -->

**Picture.**

```text
  JOB build (one runner)                                   JOB report (another runner)
  ┌─────────────────────────────────────────────┐          ┌──────────────────────────────┐
  │ step id=describe                            │          │ env:                         │
  │   echo "describe=..." >> "$GITHUB_OUTPUT" ──┼─┐        │   DESCRIBE: ${{ needs.build  │
  │ step                                        │ │        │     .outputs.describe }}     │
  │   reads ${{ steps.describe.outputs... }}    │ │        │ run: echo "$DESCRIBE"        │
  │ outputs:                                    │ │        └──────────────▲───────────────┘
  │   describe: ${{ steps.describe.outputs... }}◄─┘                       │
  └──────────────────────┬──────────────────────┘                         │
                         └───────────── job output (a string) ────────────┘
```

## 20A.8 What `actions/checkout` does by default

**In one sentence.** A runner starts with no repository at all; `actions/checkout` fetches **one commit, without tags**, for the ref of the event, and on `pull_request` events that ref is the test merge commit `refs/pull/N/merge`, checked out with a detached HEAD.

**Analogy.** You asked a courier for "the contract" and received the last page, unstapled, with a cover sheet that merges your draft and the other party's latest draft. It is the right thing to sign and the wrong thing to consult about the history of clause 4. The analogy breaks because the last page here is a complete snapshot of every file: only the history is missing, not the content.

**Precisely.** From the action's [README](https://github.com/actions/checkout/blob/v7.0.1/README.md) and [`action.yml`](https://github.com/actions/checkout/blob/v7.0.1/action.yml) at v7.0.1, the version pinned in this course:

| Input | Default | Consequence |
|---|---|---|
| `ref` | the ref or commit of the event; the default branch for another repository | on `pull_request`, `refs/pull/N/merge` |
| `fetch-depth` | `1` | "Only a single commit is fetched by default"; `0` fetches all history for all branches and tags |
| `fetch-tags` | `false` | no tags, so nothing for `git describe` to find |
| `persist-credentials` | `true` | the job token is kept for later `git` commands of the job and removed in post-job cleanup; since v6 it is stored under `$RUNNER_TEMP` and not in `.git/config` |
| `lfs`, `submodules` | `false` | LFS pointers are not replaced by content; submodule directories are empty |
| `clean` | `true` | matters on self-hosted runners that reuse a workspace |
| `allow-unsafe-pr-checkout` | `false` | v7 refuses to check out fork pull request code under `pull_request_target` and `workflow_run` (Chapter 21A) |

The course workflows set `persist-credentials: false` because none of them runs an authenticated `git` command after the checkout: a credential that is not on disk cannot be read by a later step.

**Inside `.git`.** A shallow fetch writes the fetched commit's ID to the file `.git/shallow`. That file tells Git to treat the commit as having no parents, although the commit object itself still names them ([Chapter 26](ch26-performance.md), section 26.11 covers shallow clones and their limits). No tag refs are created. HEAD is a branch for `push` events and a bare commit ID for pull requests.

**See it: one commit, no tags.** Your clone of the fixture has three commits and an annotated tag:

<!-- snippet: ch20a/shallow-checkout/01-full-clone -->
```text
# Your clone: three commits, one annotated tag.
$ cd you/inventory-api
$ git log --oneline --decorate
6fe5455 (HEAD -> main, origin/main) Document how to run the tests
ae299cb (tag: v0.1.0) Add Maven module for price calculation
05d3477 Add stock functions and tests
$ git describe --tags
v0.1.0-1-g6fe5455
$ cd ../..
```
<!-- /snippet -->

The documented defaults, reproduced as a clone from a `file://` URL. (A plain path would make Git copy the repository and ignore `--depth`; the URL form goes through the transfer protocol, as a runner does. The runner's own sequence of Git commands is an implementation detail and is not what is shown.)

<!-- snippet: ch20a/shallow-checkout/02-runner-clone -->
```text
# HUB is a file:// URL of the bare repository that plays GitHub.
# fetch-depth: 1 and fetch-tags: false, as a clone:
$ git clone --depth 1 --no-tags "$HUB" runner
Cloning into 'runner'...
$ cd runner
$ git log --oneline --decorate
6fe5455 (grafted, HEAD -> main, origin/main, origin/HEAD) Document how to run the tests
$ git rev-parse --is-shallow-repository
true
$ cat .git/shallow
6fe5455926c26261fe2c73104018ca2d96fdb554
$ git tag --list
$ git rev-list --count HEAD
1
```
<!-- /snippet -->

`grafted` in the log decoration and the ID in `.git/shallow` say the same thing: history is cut here. The commit count is 1 and the tag list is empty.

<!-- snippet: ch20a/shallow-checkout/03-describe-fails -->
```text
$ git describe --tags
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git describe --tags --always
6fe5455
[exit status: 0]
# History questions get wrong answers, not errors:
$ git log --oneline -- java-service/pom.xml
6fe5455 Document how to run the tests
$ git merge-base HEAD origin/main~1
fatal: Not a valid object name origin/main~1
[exit status: 128]
```
<!-- /snippet -->

`git describe` fails with "No names found". With `--always` it does not fail: it prints the abbreviated commit ID `6fe5455`, and a build stamps that as the version. That is question 2 of section 20A.1. Worse than the error are the two lines after it. `git log -- java-service/pom.xml` claims the file was last changed by the only commit there is, because a parentless commit "adds" every file. The true answer, in the full clone, is `ae299cb`. Any tool that asks history a question (changed-file detection, blame-based analysis, changelog generators, version-from-tag plugins) gets a confident wrong answer.

<!-- snippet: ch20a/shallow-checkout/04-tags-are-not-enough -->
```text
# fetch-tags: true with depth 1: the tag arrives, its commit is not an ancestor we have.
$ git fetch --depth 1 origin "refs/tags/*:refs/tags/*"
From file://$LAB/ch20a/shallow-checkout/hub/inventory-api
 * [new tag]         v0.1.0     -> v0.1.0
$ git tag --list
v0.1.0
$ git describe --tags
fatal: No tags can describe '6fe5455926c26261fe2c73104018ca2d96fdb554'.
Try --always, or create some tags.
[exit status: 128]
```
<!-- /snippet -->

Fetching tags alone does not repair `describe`. The tag now exists, but `describe` walks from HEAD through parents to find a tagged ancestor, and the walk ends at the graft. Tags need the history between them and HEAD.

<!-- snippet: ch20a/shallow-checkout/05-full-history -->
```text
# fetch-depth: 0, as a repair of this clone:
$ git fetch --unshallow --tags
$ git rev-parse --is-shallow-repository
false
$ git rev-list --count HEAD
3
$ git describe --tags
v0.1.0-1-g6fe5455
$ git log --oneline -- java-service/pom.xml
ae299cb Add Maven module for price calculation
```
<!-- /snippet -->

```text
Observed behavior : the build names the release 6fe5455 instead of v0.1.0-1-g6fe5455
Git state         : .git/shallow lists HEAD; one commit; no refs under refs/tags
Mechanism         : git describe walks parents looking for a tagged commit; the graft ends the walk
Root cause        : actions/checkout defaults: fetch-depth 1, fetch-tags false
Why it does this  : a job that only compiles and tests needs the snapshot, not the history;
                    fetching one commit is the fastest correct default for that job
Correct fix       : fetch-depth: 0 in the job that needs history or tags (workflow 3)
Prevention        : decide per job whether it asks history a question; never use --always
                    to silence describe in a release build
```

State table for the two Git operations of this demonstration, on the runner's clone:

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| 🟢 `git clone --depth 1 --no-tags` | files of one commit | matches that commit | `main` (or detached for a pull request) | the fetched commit | `.git/shallow` written; `origin/main`; no tags | unchanged | unchanged |
| 🟢 `git fetch --unshallow --tags` | unchanged | unchanged | unchanged | unchanged | `.git/shallow` removed; missing commits and tag refs added | unchanged | unchanged |

**See it: the merge ref.** Chapter 17, section 17.2 showed that GitHub keeps, for a mergeable pull request, a test merge commit under `refs/pull/N/merge`. The events reference states that `pull_request` workflows set `GITHUB_REF` to that ref and `GITHUB_SHA` to that commit, and that the checkout action therefore "checks out the merge branch", so that "CI tests run against the merged result, not just the head branch alone" ([how the merge branch affects your workflow](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#how-the-merge-branch-affects-your-workflow)).

The fixture: your branch adds a reorder report whose test assumes the low-stock threshold is 5. Meanwhile a colleague raised the threshold to 10 on `main`. The two changes touch different files, so they merge without a conflict.

<!-- snippet: ch20a/merge-ref/01-your-branch -->
```text
# Your clone, on the pull request branch. The tests pass.
$ cd you/inventory-api
$ git switch feature/reorder-report
Switched to branch 'feature/reorder-report'
Your branch is up to date with 'origin/feature/reorder-report'.
$ git log --oneline -2
80c9cfa Add reorder report
6fe5455 Document how to run the tests
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1
OK
$ cd ../..
```
<!-- /snippet -->

The server side below is a bare repository in which the fixture created the two pull request refs with plain Git, imitating the documented behavior.

<!-- snippet: ch20a/merge-ref/02-server-refs -->
```text
# The repository on the platform after pull request 7 was opened:
$ git ls-remote "$HUB"
29b222ba49c3886f27c205a7ec4c982d141052c3	HEAD
80c9cfa3a369de2fb126f79a0e34f6139c858a76	refs/heads/feature/reorder-report
29b222ba49c3886f27c205a7ec4c982d141052c3	refs/heads/main
80c9cfa3a369de2fb126f79a0e34f6139c858a76	refs/pull/7/head
d04ef31e3ed5a74c9a89af11e2cbb441599e84c7	refs/pull/7/merge
192d2bc34d491d9b35cc1c00e50dde959dd9df55	refs/tags/v0.1.0
ae299cbfba5ad3d9388d3dded0eeee37b09946aa	refs/tags/v0.1.0^{}
```
<!-- /snippet -->

`refs/pull/7/head` is your commit `80c9cfa`. `refs/pull/7/merge` is `d04ef31`, a commit that neither you nor your colleague created. The runner fetches that one commit:

<!-- snippet: ch20a/merge-ref/03-runner-checkout -->
```text
# The runner: fetch one commit, the one refs/pull/7/merge names, and detach HEAD on it.
$ git init --quiet runner && cd runner
$ git remote add origin "$HUB"
$ git fetch --no-tags --depth=1 origin +refs/pull/7/merge:refs/remotes/pull/7/merge
From file://$LAB/ch20a/merge-ref/hub/inventory-api
 * [new ref]         refs/pull/7/merge -> pull/7/merge
$ git checkout --detach refs/remotes/pull/7/merge
HEAD is now at d04ef31 Merge 80c9cfa3a369de2fb126f79a0e34f6139c858a76 into 29b222ba49c3886f27c205a7ec4c982d141052c3
```
<!-- /snippet -->

<!-- snippet: ch20a/merge-ref/04-what-is-checked-out -->
```text
$ git status --short --branch
## HEAD (no branch)
$ git log -1 --format="GITHUB_SHA would be %H%n%an: %s"
GITHUB_SHA would be d04ef31e3ed5a74c9a89af11e2cbb441599e84c7
GitHub: Merge 80c9cfa3a369de2fb126f79a0e34f6139c858a76 into 29b222ba49c3886f27c205a7ec4c982d141052c3
$ git rev-list --count HEAD
1
$ git branch --show-current
$ grep LOW_STOCK_THRESHOLD src/inventory_api/stock.py
LOW_STOCK_THRESHOLD = 10
def low_stock(stock, threshold=LOW_STOCK_THRESHOLD):
$ ls src/inventory_api
__init__.py
report.py
stock.py
```
<!-- /snippet -->

HEAD is detached, there is no current branch, the history is one commit deep, and the working tree contains both changes: your `report.py` and the threshold of 10 from `main`.

<!-- snippet: ch20a/merge-ref/05-tests-on-the-merge -->
```text
# The merged code is what CI tests. main changed the threshold; the new test assumed 5.
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null
[exit status: 1]
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1
FAILED (failures=1)
```
<!-- /snippet -->

The tests fail on the runner and pass on your laptop. Both results are correct. They tested different commits.

<!-- snippet: ch20a/merge-ref/06-not-in-your-clone -->
```text
# Back in your clone: the commit CI tested is not there, and your branch is unchanged.
$ cd ../you/inventory-api
$ merge=$(git ls-remote "$HUB" refs/pull/7/merge | cut -f1)
$ git cat-file -t $merge
fatal: git cat-file: could not get object info
[exit status: 128]
# Reproduce what CI tested: merge the current base into a throwaway copy of your branch.
$ git fetch --quiet origin
$ git switch --quiet --detach feature/reorder-report
$ git merge --quiet --no-edit origin/main
$ git rev-parse HEAD^{tree}
745aaaaed0f47d2429feeb200e9776b329be83ef
$ git -C ../../runner rev-parse HEAD^{tree}
745aaaaed0f47d2429feeb200e9776b329be83ef
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1
FAILED (failures=1)
$ git switch --quiet feature/reorder-report
```
<!-- /snippet -->

The commit that CI tested does not exist in your clone, so `git show` of the ID in the CI log fails there. Merging the current base into a detached copy of your branch produces the same tree (the two tree IDs are equal), and the failure reproduces locally.

```text
Observed behavior : tests pass locally, fail in CI "on the same commit"
Git state         : laptop HEAD = 80c9cfa (pull request head); runner HEAD = d04ef31 (test merge)
Mechanism         : pull_request sets GITHUB_REF to refs/pull/N/merge; checkout uses GITHUB_REF
Root cause        : the base branch gained a commit that changes behavior the new code relies on
Why it does this  : the question a pull request asks is "is the result of merging safe",
                    which only the merged tree can answer
Correct fix       : update the branch (merge or rebase onto the base), fix the code, push
Prevention        : reproduce with `git fetch origin && git merge origin/main` before debugging;
                    a merge queue or "require branches to be up to date" closes the remaining gap
```

Picture, with the IDs of the transcript:

```text
   6fe5455 ─────────────── 29b222b            main          (threshold 10)
        \                         \
         \                         d04ef31    refs/pull/7/merge   ◄── runner HEAD (detached)
          \                       /
           80c9cfa ──────────────             feature/reorder-report, refs/pull/7/head
                                              ◄── your HEAD
```

Three consequences, all from the same pages:

- **The test merge can be older than `main`.** It is regenerated when the pull request branch is pushed, when the merge base changes, or when it is older than 12 hours (Chapter 17, section 17.2). A re-run of a job reuses the original commit ([re-running](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs)), so a re-run does not pick up a newer base.
- **A conflicted pull request has no merge ref, and its `pull_request` workflows do not run at all.** The symptom is missing checks, not failed ones.
- **To test the head commit alone**, the README documents `ref: ${{ github.event.pull_request.head.sha }}`. You then test something that will never be on the base branch; do it knowingly, for example for a linter that should judge only the author's files.

**In production.** An ML team's pull request adds a metric and passes locally. CI fails in an unrelated data-loader test. The author spends an hour on the loader before looking at the first lines of the checkout step's log, where the fetched ref is `refs/pull/412/merge`. Someone had merged a loader change twenty minutes earlier. The habit that prevents the lost hour: read which commit the job checked out before reading anything else. Workflow 1 prints it in its own step for that reason.

## 20A.9 Controlling jobs: `needs`, `if`, `timeout-minutes`, `continue-on-error`

**In one sentence.** `needs` orders jobs and carries their results, `if` decides whether a job or step runs, `timeout-minutes` bounds how long it may run, and `continue-on-error` lets a failure pass without failing what contains it.

**Precisely.** From the [workflow syntax reference](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idneeds):

| Key | Level | Rule | Default |
|---|---|---|---|
| `needs` | job | the job waits for the listed jobs. If one of them fails or is skipped, this job is skipped, unless its `if` says otherwise | none: jobs run in parallel |
| `if` | job, step | the job or step runs when the expression is truthy. An `if` without a status function behaves as if `success() &&` were in front of it | `success()` |
| `timeout-minutes` | job, step | the job or step is cancelled after this many minutes | 360 for a job |
| `continue-on-error` | job, step | a failure does not fail the job (step level) or the run (job level) | `false` |

Status functions change the implicit `success()`: `failure()` is true when an earlier step or needed job failed; `always()` is true even when the run was cancelled; `cancelled()` is true on cancellation. The expressions page advises against `always()` for anything that could fail critically and recommends `if: ${{ !cancelled() }}` for "run whether or not the earlier steps passed".

`continue-on-error` at step level splits a step's result in two: `steps.<id>.outcome` is the result before the setting is applied and `steps.<id>.conclusion` the result after. A failed step with `continue-on-error: true` has outcome `failure` and conclusion `success` ([steps context](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#steps-context)).

Two rules about skipping decide whether a pull request can merge, and they point in opposite directions:

- A **job** skipped by its `if` reports success for its check, so a required check is satisfied.
- A **workflow** that never starts, because of a path or branch filter or a skip instruction, reports nothing, and a required check stays pending.

Both are from [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks). They make `if` on a job a way to bypass a required check by accident, and `paths` on a workflow a way to block every unrelated pull request.

**In production.** Set `timeout-minutes` on every job. The default of 360 minutes is also the hard limit for a GitHub-hosted job ([limits](https://docs.github.com/en/actions/reference/limits)), so a test that hangs on a network call bills six hours unless you say otherwise. The course workflows use 5 to 20 minutes.

## 20A.10 Matrix strategies

**In one sentence.** A matrix turns one job definition into one job per combination of the values you list, each with its own runner and its own `matrix` context.

**Precisely.** `strategy.matrix` maps variable names to lists; the jobs are the Cartesian product ([matrix](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstrategymatrix)).

- `exclude` removes combinations; a partial match is enough.
- `include` is processed after `exclude`. An entry is added to every existing combination it can extend without overwriting an original matrix value; if it would overwrite one, it becomes a new combination of its own.
- `fail-fast` defaults to `true`: when one matrix job fails, the in-progress and queued ones are cancelled. `max-parallel` caps how many run at once.
- A run may generate at most 256 matrix jobs.
- A job-level `if` is evaluated before the matrix is expanded, so it cannot read `matrix`.
- Outputs of matrix jobs are merged into one set and the last writer wins, in no guaranteed order.

Workflow 10 lists `os: [ubuntu-24.04, macos-15]`, `python: ["3.11", "3.12", "3.13"]` and `experimental: [false]`. That is six combinations. `exclude` removes macOS with 3.11, leaving five. The `include` entry (Ubuntu, 3.14, `experimental: true`) would overwrite `python` and `experimental` of any existing combination, so it is added as a sixth job. `continue-on-error: ${{ matrix.experimental }}` is `true` only for that job.

> **Unverified.** The names of the checks that matrix jobs report are not specified on an official page that the course's research could find. Workflow 10 therefore sets `name:` explicitly from the matrix values, and adds a final job with a fixed name to serve as the required check.

## 20A.11 Dependency caching

**In one sentence.** A cache stores a directory under a key so that a later run with the same key can restore it and skip the download; it is an optimization that may be absent, never a place to keep something you need.

**Analogy.** A cache is the shared fridge at work with labelled boxes. If a box with your label is there, lunch is quick. If it was cleared out, you cook again. You do not keep your passport in it, and you do not eat from a box whose label you did not write. The analogy holds for eviction and for trust; it breaks on mutability, because a cache entry can never be changed once saved.

**Precisely.** From the [dependency caching reference](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching) and the [`actions/cache` README](https://github.com/actions/cache/blob/v6.1.0/README.md):

- **Key.** At most 512 characters, usually built from the operating system and `hashFiles` of a lock file. An existing key is never overwritten: "You cannot change the contents of an existing cache."
- **Restore order.** The exact `key`; then entries whose key starts with `key`; then each `restore-keys` prefix in order, the most recently created match winning.
- **Save.** On a miss, the cache is saved at the end of the job, and only if the job completes successfully.
- **`cache-hit` output.** `true` only for an exact match on the primary key; `false` when a restore key matched or nothing was restored.
- **Scope.** A run can restore caches created on its own branch or on the default branch; a pull request run can also restore from its base branch. Sibling branches cannot read each other's caches. A cache saved by a pull request run belongs to the merge ref and is restorable only by re-runs of that pull request.
- **Eviction.** Entries not accessed for 7 days are removed. A repository gets 10 GB without charge; above the limit the least recently used entries are deleted. Administrators can raise the limit, billed, since 20 November 2025 ([changelog](https://github.blog/changelog/2025-11-20-github-actions-cache-size-can-now-exceed-10-gb-per-repository/)).
- **Trust.** Anyone who can open a pull request can read caches of the base branch, and cache contents are not signed. Since 26 June 2026, events that people without write access can cause get a read-only token for the default branch's caches, and since 10 September 2026 the `cache-mode` key (`read`, `write`, `write-only`, `none`) states the access explicitly ([read-only caches](https://github.blog/changelog/2026-06-26-read-only-actions-cache-for-untrusted-triggers/), [cache-mode](https://github.blog/changelog/2026-09-10-control-github-actions-cache-access-with-cache-mode/)). Chapter 21A covers cache poisoning.

The explicit form, as the README shows it, for a tool whose download directory you know:

```yaml
- uses: actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0
  id: cache
  with:
    path: ~/.m2/repository
    key: maven-${{ runner.os }}-${{ hashFiles('java-service/pom.xml') }}
    restore-keys: |
      maven-${{ runner.os }}-
```

Most projects never write this block, because the setup actions contain it. `actions/setup-java` with `cache: maven` stores `~/.m2/repository` under a key that hashes `**/pom.xml` by default ([README](https://github.com/actions/setup-java/blob/v6.0.1/README.md)). `astral-sh/setup-uv` has `enable-cache`, default `auto`: enabled on GitHub-hosted runners except for release, tag push, `pull_request_target` and `workflow_run` events, and keyed on the files matched by `cache-dependency-glob` ([README](https://github.com/astral-sh/setup-uv/blob/v10.2.0/README.md)). Workflows 4 and 5 use these.

```text
Observed behavior : a dependency was upgraded, CI still installs the old version from cache
Mechanism         : the key had no lock-file hash, or a broad restore key matched an old entry,
                    which was then extended and saved under the new key
Root cause        : caches are immutable per key and restore keys match by prefix
Correct fix       : put hashFiles of the lock file in the key; install from the lock file
                    (uv sync --locked) so that a stale cache cannot change what is installed
Prevention        : a manual prefix (v2-) to invalidate everything at once
```

**In production.** Cache package downloads and small test models, never multi-gigabyte checkpoints: 10 GB per repository is shared by all branches, and a model cache evicts the dependency caches that made CI fast.

## 20A.12 Artifacts

**In one sentence.** An artifact is a set of files that a job uploads to GitHub, where it is stored with the run, can be downloaded by later jobs or by people, and expires after a retention period.

**Precisely.** From the READMEs of [`upload-artifact` v7.0.1](https://github.com/actions/upload-artifact/blob/v7.0.1/README.md) and [`download-artifact` v8.0.1](https://github.com/actions/download-artifact/blob/v8.0.1/README.md):

| Property | Rule |
|---|---|
| Immutability | an artifact cannot be changed after upload. A second upload with the same name in one run fails unless `overwrite: true`, which replaces it |
| Availability | scoped to the job: downloadable by a later job of the same run as soon as the upload step ends |
| Retention | 90 days by default; `retention-days` from 1 to 90, never above the repository or organization setting. Since 1 October 2026 the same setting also deletes checks, workflow runs and commit statuses ([changelog](https://github.blog/changelog/2026-08-27-actions-retention-will-cover-checks-workflow-runs-and-statuses/)) |
| Limits | 500 artifacts per job; hidden files are excluded unless `include-hidden-files: true` |
| Permissions | zipped uploads do not keep file permissions (files become 644). Tar the files first if the executable bit matters |
| Outputs | `artifact-id`, `artifact-url`, `artifact-digest` (SHA-256) |
| Download | by `name` into `path`; without `name`, all artifacts, each in a directory of its name. v8 fails on a digest mismatch (`digest-mismatch: error` is the default) |
| Since v7 | `archive: false` uploads one file without zipping it |

Artifact or cache? The [documentation's rule](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts): a cache for files that are reused between runs and can be recreated (dependencies); an artifact for files a job produced that must be passed to another job or kept after the run (build outputs, test reports).

The reason to pass build outputs as an artifact, and not to rebuild in the deploy job, is the one a CTO cares about: **the files that were tested are the files that are deployed.** A rebuild in a second job resolves dependencies again, possibly to different versions.

**In production.** Upload test reports with `if: ${{ failure() }}` and a short retention. Never upload a directory that may contain credential files or a `.git` folder with persisted credentials: an artifact is a copy of those files that outlives the job.

## 20A.13 The eight workflows, line by line

The files are in [`workflows/`](../workflows/). Each carries a header comment, declares `permissions` at the top, and pins every action to a full commit ID from [`workflows/ACTION_PINS.md`](../workflows/ACTION_PINS.md) with the version as a comment (Chapter 21A explains why a tag is not enough). They were parse-checked and assembled from documented syntax; the author did not execute them on GitHub. Line numbers below refer to the files. Lines that repeat in every file are explained once, in workflow 1.

### Workflow 1: `01-tests.yml`, run the tests

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:

# The job token may read the repository contents and nothing else.
permissions:
  contents: read

jobs:
  test:
    name: Unit tests
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - name: Check out the repository
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false

      - name: Show what was checked out
        run: |
          echo "event      : $GITHUB_EVENT_NAME"
          echo "GITHUB_REF : $GITHUB_REF"
          echo "GITHUB_SHA : $GITHUB_SHA"
          git log -1 --format='HEAD       : %H %s'
          git rev-parse --is-shallow-repository
          git status --short --branch

      - name: Set up Python
        uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: "3.13"

      - name: Run the tests with the standard library
        env:
          PYTHONPATH: src
        run: python -m unittest discover -s tests -v
```

| Lines | What they say | Why |
|---|---|---|
| 10 | `name` is what the Actions tab and the check show | without it the file path is shown |
| 12 to 15 | run on pushes to `main` and on pull request activity (opened, synchronize, reopened) | `branches: [main]` on `push` stops a second run for every push to a pull request branch, which `pull_request` already covers |
| 18, 19 | the job token may read repository contents; every other permission is `none` | least privilege, and independence from the repository's default setting |
| 22 to 25 | one job, ID `test`, display name `Unit tests`, on the fixed image `ubuntu-24.04`, at most 10 minutes | a fixed label does not move when `ubuntu-latest` migrates (section 20A.14) |
| 27 to 30 | step 1 is an action: fetch the event's commit into the workspace, and do not keep the token on disk | defaults of section 20A.8 |
| 32 to 39 | step 2 is a shell script that prints the event, ref, commit, whether the clone is shallow, and the branch status | the first thing to read in any log: what was checked out |
| 41 to 44 | step 3 installs CPython 3.13 and puts it on `PATH`; the version is quoted | section 20A.3 |
| 46 to 49 | step 4 sets `PYTHONPATH` for this step only and runs the tests; a non-zero exit status fails the step, the job and the run | `env` at step level is the narrowest scope |

On a push to `main`, step 2 prints `refs/heads/main`, the pushed commit, `true` for shallow, and a status line that names a branch. On a pull request it prints `refs/pull/N/merge`, the test merge commit, `true`, and `## HEAD (no branch)`, as in the transcript of section 20A.8. That prediction is from the documentation; Lab 26.1 has you confirm it.

### Workflow 2: `02-lint.yml`, linting

```yaml
      - name: Install uv
        uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
        with:
          python-version: "3.13"

      - name: Install the project and the dev group from the lock file
        run: uv sync --locked

      - name: Lint
        id: lint
        run: uv run ruff check .

      # Runs even when the lint step failed, so one push reports both problems.
      - name: Check formatting
        id: format
        if: ${{ !cancelled() }}
        run: uv run ruff format --check .

      - name: Write the job summary
        if: ${{ !cancelled() }}
        env:
          LINT_OUTCOME: ${{ steps.lint.outcome }}
          FORMAT_OUTCOME: ${{ steps.format.outcome }}
        run: |
          {
            echo "### ruff"
            echo ""
            echo "| Check | Outcome |"
            echo "|---|---|"
            echo "| ruff check | $LINT_OUTCOME |"
            echo "| ruff format --check | $FORMAT_OUTCOME |"
          } >> "$GITHUB_STEP_SUMMARY"
```

- Lines 32 to 35: `astral-sh/setup-uv` installs uv. Its `python-version` input sets the variable `UV_PYTHON` for the rest of the job (README, "Python version"); uv then provides that interpreter when a command needs it.
- Lines 37, 38: `uv sync --locked` creates the virtual environment from `uv.lock` and fails if the lock file does not match `pyproject.toml` ([uv guide for GitHub Actions](https://docs.astral.sh/uv/guides/integration/github/)). CI installs what was reviewed, or stops.
- Lines 40 to 48: two checks with IDs. The second has `if: ${{ !cancelled() }}`, which replaces the implicit `success()`, so formatting is checked even when linting failed. The job still fails, because a failed step fails the job unless `continue-on-error` is set.
- Lines 50 to 63: the summary step reads `steps.<id>.outcome` through `env` and appends a Markdown table to `$GITHUB_STEP_SUMMARY`. The braces group the `echo` commands so that one redirection covers all of them.

### Workflow 3: `03-build.yml`, build the application

```yaml
on:
  push:
    branches: [main]
    tags: ["v*"]
  workflow_dispatch:

permissions:
  contents: read

defaults:
  run:
    shell: bash

jobs:
  build:
    name: Build sdist and wheel
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    outputs:
      describe: ${{ steps.describe.outputs.describe }}
      files: ${{ steps.list.outputs.files }}
    steps:
      # All history and all tags: `git describe` needs the tags and the commits between them.
      - name: Check out the repository with full history
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          fetch-depth: 0
          persist-credentials: false

      - name: Describe the commit
        id: describe
        run: |
          describe="$(git describe --tags --always)"
          echo "describe=$describe" >> "$GITHUB_OUTPUT"
          echo "Building $describe"
```

- Lines 13 to 17: pushes to `main`, pushes of tags matching `v*` (quoted, because `*` is YAML syntax at the start of a scalar), and manual runs. `branches` and `tags` under one `push` are alternatives: a push matches if it is a matching branch or a matching tag.
- Lines 22 to 24: every `run` step of the file uses the `shell: bash` template, so pipelines fail properly (section 20A.7).
- Lines 31 to 33: the job publishes two outputs, each defined as the output of a step.
- Lines 36 to 40: `fetch-depth: 0` fetches all history and tags, which line 45 needs (section 20A.8).
- Lines 42 to 47: the step has `id: describe`; line 46 appends `describe=<value>` to `$GITHUB_OUTPUT`.

The second job, `report` (lines 63 to 80), has `needs: build`, no checkout, and reads `needs.build.outputs.*` through `env`. It proves the point of section 20A.2: the only things that reached the second machine are two strings.

### Workflow 4: `04-python-tests.yml`, Python tests with uv and caching

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
# ...
      - name: Install uv with its cache enabled
        id: setup-uv
        uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
        with:
          python-version: "3.13"
          enable-cache: true
          cache-dependency-glob: uv.lock

      - name: Report the cache result
        env:
          CACHE_HIT: ${{ steps.setup-uv.outputs.cache-hit }}
        run: echo "uv cache hit - $CACHE_HIT"

      - name: Install the project and the dev group from the lock file
        run: uv sync --locked

      - name: Run the tests
        run: uv run pytest
```

- Lines 22 to 24: one run at a time per workflow and ref. A new push to the same branch or pull request cancels the run in progress. `github.ref` is `refs/pull/N/merge` for pull requests, so each pull request is its own group. Chapter 20B treats concurrency in full.
- Lines 37 to 43: `enable-cache: true` turns on the cache built into `setup-uv`, and `cache-dependency-glob: uv.lock` makes the lock file the only input to the key. A changed lock file gives a new key and a miss; any other change gives a hit.
- Lines 45 to 48: the action's `cache-hit` output, printed, so the log states which case occurred.
- Lines 50 to 54: install from the lock file, then run pytest, which collects the `unittest` classes.

### Workflow 5: `05-java-tests.yml`, Java tests with Maven

```yaml
on:
  push:
    branches: [main]
    paths:
      - "java-service/**"
      - ".github/workflows/05-java-tests.yml"
  pull_request:
    paths:
      - "java-service/**"
      - ".github/workflows/05-java-tests.yml"
# ...
    # Applies to `run` steps only. `uses` steps still resolve paths from the workspace root.
    defaults:
      run:
        working-directory: java-service
# ...
      - name: Set up the JDK and the Maven cache
        uses: actions/setup-java@de7274f081f381c8f8158605e0321c36c376e2e6 # v6.0.1
        with:
          distribution: temurin
          java-version: "21"
          cache: maven
          cache-dependency-path: java-service/pom.xml

      - name: Build and test
        run: mvn -B verify

      - name: Upload the test reports when the job failed
        if: ${{ failure() }}
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: surefire-reports
          path: java-service/target/surefire-reports/
          if-no-files-found: warn
          retention-days: 7
```

- Lines 14 to 23: the workflow starts only when a file under `java-service/` or the workflow file itself changed. Listing the workflow file means that an edit to the CI is tested by the CI. Do not make this workflow a required check (section 20A.16).
- Lines 34 to 36: `run` steps start in `java-service`. The comment on line 33 states the limit: `defaults.run` applies to `run` steps only, so the `path` on line 59 is written from the workspace root.
- Lines 43 to 49: `actions/setup-java` installs Temurin 21 (`distribution` is required) and restores `~/.m2/repository` from a cache keyed on the given `pom.xml`.
- Line 52: `-B` is Maven's batch mode: no interactive prompts and no color codes in the log.
- Lines 54 to 61: `if: ${{ failure() }}` runs the upload only when an earlier step failed. The reports are kept for 7 days.

The Maven module and the plugin versions in its `pom.xml` were not built by the author. The versions were confirmed to exist in Maven Central on 2 October 2026.

### Workflow 6: `06-docker-image.yml`, build and push an image to ghcr.io

```yaml
permissions:
  contents: read

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  image:
    name: Build and push
    runs-on: ubuntu-24.04
    timeout-minutes: 20
    permissions:
      contents: read
      packages: write
# ...
      - name: Log in to ghcr.io
        if: ${{ github.event_name != 'pull_request' }}
        uses: docker/login-action@dbcb813823bdd20940b903addbd779551569679f # v4.6.0
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Compute tags and labels
        id: meta
        uses: docker/metadata-action@dc802804100637a589fabce1cb79ff13a1411302 # v6.2.0
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=sha

      - name: Build, and push unless this is a pull request
        id: build
        uses: docker/build-push-action@c3c9e263c25d99ce0380d002d59b67737d91b0dc # v7.4.0
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

- Lines 21, 22 and 33 to 35: the workflow default is read-only; the one job that pushes adds `packages: write`. A job-level `permissions` block replaces the workflow-level one for that job, so `contents: read` is repeated.
- Lines 24 to 26: workflow-level `env`. `github.repository` is `owner/name`; `docker/metadata-action` lowercases image names (README, "Image name and tag sanitization"), which a registry requires.
- Lines 46 to 52: log in with the job token. GitHub's guide recommends the token over a personal access token, and states that a package published this way inherits the visibility and permissions of the repository ([publishing with Actions](https://docs.github.com/en/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions)). The step is skipped on pull requests.
- Lines 54 to 63: tags are computed from Git facts. From the action's README: `type=ref,event=branch` gives the branch name (`main`); `type=ref,event=pr` gives `pr-N`; `type=semver,pattern={{version}}` gives `0.2.0` for a tag `v0.2.0`; `type=sha` gives `sha-` plus the short commit ID. With the default `flavor`, a semver tag also produces `latest`.
- Lines 65 to 74: `context: .` builds from the checked-out workspace. Without it the action builds from the Git context, which skips the checkout and ignores local file changes (README, "Git context"). `push` is an expression that is `false` on pull requests. `type=gha` stores BuildKit layers in the Actions cache ([Docker documentation](https://docs.docker.com/build/ci/github-actions/cache/)), subject to the scope and eviction rules of section 20A.11.

The Dockerfile was not built by the author. Chapter 20B returns to this file for delivery.

### Workflow 7: `07-artifact.yml`, create an artifact and consume it

```yaml
    outputs:
      artifact-id: ${{ steps.upload.outputs.artifact-id }}
      artifact-digest: ${{ steps.upload.outputs.artifact-digest }}
# ...
      - name: Upload the build outputs
        id: upload
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: inventory-api-dist
          path: dist/
          if-no-files-found: error
          retention-days: 7
# ...
  deploy-simulated:
    name: Simulated deployment
    needs: build
    runs-on: ubuntu-24.04
    timeout-minutes: 5
# ...
      - name: Download the build outputs
        uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: inventory-api-dist
          path: dist

      - name: Show what arrived
        env:
          ARTIFACT_ID: ${{ needs.build.outputs.artifact-id }}
          ARTIFACT_DIGEST: ${{ needs.build.outputs.artifact-digest }}
        run: |
          echo "artifact ID     : $ARTIFACT_ID"
          echo "artifact digest : $ARTIFACT_DIGEST"
          ls dist

      - name: Deploy (simulated)
        run: bash scripts/deploy.sh staging dist
```

- Lines 45 to 52: `if-no-files-found: error` turns an empty `dist/` into a failure at the upload, not a mystery at the download. The step's outputs become job outputs on lines 28 to 30.
- Lines 54 to 58: the second job waits for `build`. It is a new machine, so it checks out the repository again to get `scripts/deploy.sh`.
- Lines 66 to 70: download by name into `dist`. A single artifact is extracted directly into `path`. Version 8 of the action compares the digest and fails on a mismatch.
- Lines 81, 82: the simulated deployment lists exactly the downloaded files. The script changes nothing anywhere; Lab 26.7 shows its real output.

### Workflow 10: `10-matrix.yml`, matrix testing

```yaml
  test:
    name: py${{ matrix.python }} on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    timeout-minutes: 15
    continue-on-error: ${{ matrix.experimental }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-24.04, macos-15]
        python: ["3.11", "3.12", "3.13"]
        experimental: [false]
        exclude:
          - os: macos-15
            python: "3.11"
        include:
          - os: ubuntu-24.04
            python: "3.14"
            experimental: true
# ...
  all-tests:
    name: All matrix tests
    if: ${{ always() }}
    needs: test
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - name: Check the result of the matrix
        env:
          RESULT: ${{ needs.test.result }}
        run: |
          echo "matrix result: $RESULT"
          test "$RESULT" = "success"
```

Section 20A.10 counted the jobs: six, of which one is experimental. Line 24 names each job from its matrix values. Line 25 chooses the runner per combination. Line 27 lets the Python 3.14 job fail without failing the run.

The last job is the pattern to remember. A ruleset that requires "All matrix tests" needs no edit when a Python version is added. `if: ${{ always() }}` makes it run even when a matrix job failed, because a skipped job would report success and satisfy the required check (section 20A.9). It then fails unless `needs.test.result` is `success`.

> **Unverified.** How `needs.<job>.result` aggregates the results of a matrix whose only failure had `continue-on-error: true` is not spelled out on the pages read for this chapter. The expectation, from the definition of `continue-on-error`, is `success`. Lab 26.8 has you observe it.

## 20A.14 Action versions and the Node 24 runtime

**Node 24 is the only JavaScript action runtime on github.com runners since 23 September 2026** ([changelog](https://github.blog/changelog/2026-09-23-node-20-is-no-longer-available-in-github-actions/)). A JavaScript action declares its runtime in `action.yml` (`runs.using: node24`). Older majors that declare `node20` are not rejected: according to the runner's source they are executed on Node 24, a configuration their authors did not test ([runner source](https://github.com/actions/runner/blob/v2.337.0/src/Runner.Worker/Handlers/HandlerFactory.cs)). The rule for a workflow author is to use the Node 24 majors.

The versions this chapter's workflows pin, with the behavior change each brought (Phase 0 report, section 2, and the release notes linked there):

| Action | Pinned | What changed that you must know |
|---|---|---|
| `actions/checkout` | v7.0.1 | v6 moved the persisted credential under `$RUNNER_TEMP`; v7 refuses fork pull request checkouts under `pull_request_target` and `workflow_run` |
| `actions/setup-python` | v7.0.0 | Node 24, ESM. The release notes and the README disagree about whether the `pip-install` input was removed; the course does not use it |
| `actions/setup-java` | v6.0.1 | `distribution` stays required; downloaded JDKs are verified against vendor checksums |
| `actions/cache` | v6.1.0 | handles read-only cache access; versions before v4.2.0 and v3.4.0 fail since the cache service was rewritten in February 2025 |
| `actions/upload-artifact`, `actions/download-artifact` | v7.0.1, v8.0.1 | immutable artifacts since v4; `archive: false` in upload v7; download v8 fails on a digest mismatch |
| `astral-sh/setup-uv` | v10.2.0 | no floating major tag since v8, so `@v10` does not exist: pin a full version or a commit; cache disabled by default for `pull_request_target`, `workflow_run` and `release` since v10 |
| `docker/login-action`, `setup-buildx-action`, `metadata-action`, `build-push-action` | v4.6.0, v4.4.1, v6.2.0, v7.4.0 | the Node 24 majors, released March 2026 |

Runner images move too. On 1 October 2026 `ubuntu-latest` is Ubuntu 24.04, and it migrates to Ubuntu 26.04 between 19 October and 19 November 2026 ([changelog](https://github.blog/changelog/2026-09-17-ubuntu-26-generally-available-and-latest-migration/)). The course workflows say `ubuntu-24.04` and `macos-15`, so that a change of image is a commit you make and not a date you discover. Chapter 20B covers runners, labels and retirements.

## 20A.15 Syntax added in 2025 and 2026

The core model has not changed, but a file written this year can contain keys that no older course mentions ([workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax); each row links its changelog entry):

| Since | Addition | What it replaces |
|---|---|---|
| 18 Sep 2025 | YAML anchors and aliases ([changelog](https://github.blog/changelog/2025-09-18-actions-yaml-anchors-and-non-public-workflow-templates/)) | copy and paste inside one file |
| 4 Dec 2025 | 25 `workflow_dispatch` inputs, up from 10 ([changelog](https://github.blog/changelog/2025-12-04-actions-workflow-dispatch-workflows-now-support-25-inputs/)) | |
| 29 Jan 2026 | the `case()` function ([changelog](https://github.blog/changelog/2026-01-29-github-actions-smarter-editing-clearer-debugging-and-a-new-case-function/)) | the `a && b \|\| c` idiom |
| 19 Mar 2026 | a `timezone` next to `cron`; `environment` with `deployment: false` ([changelog](https://github.blog/changelog/2026-03-19-github-actions-late-march-2026-updates/)) | UTC arithmetic in cron lines |
| 2 Apr 2026 | `entrypoint` and `command` for service containers ([changelog](https://github.blog/changelog/2026-04-02-github-actions-early-april-2026-updates/)) | custom service images |
| 7 May 2026 | `concurrency.queue: max`, up to 100 pending runs per group ([changelog](https://github.blog/changelog/2026-05-07-github-actions-concurrency-groups-now-allow-larger-queues/)) | only one pending run |
| 25 Jun 2026 | parallel steps: `background`, `wait`, `wait-all`, `cancel`, `parallel` ([changelog](https://github.blog/changelog/2026-06-25-actions-steps-can-now-be-run-in-parallel/)) | `&` and `wait` in shell |
| 30 Jul 2026 | `uses: $/path`, the same repository at the running commit, without a checkout; github.com only, runner 2.336.0 or later ([changelog](https://github.blog/changelog/2026-07-30-reference-same-repository-actions-with-self-repository-syntax/)) | `uses: ./path` after a checkout |
| 3 Sep 2026 | the `vulnerability-alerts` permission; `job.workflow_*` context fields ([changelog](https://github.blog/changelog/2026-09-03-github-actions-early-september-2026-updates/)) | |
| 10 Sep 2026 | `cache-mode` at workflow or job level ([changelog](https://github.blog/changelog/2026-09-10-control-github-actions-cache-access-with-cache-mode/)) | trusting the trigger-based default |

None of the eight workflows needs these keys, and the course did not add them for show. Know them so that you can read them. Parallel steps break one statement of section 20A.2 in a controlled way: steps with `background: true` do not run in order.

> **Unverified.** A workflow-level dependency lock announced in GitHub's 2026 security roadmap does not appear in the syntax reference as of 1 October 2026 ([roadmap](https://github.blog/news-insights/product-news/whats-coming-to-our-github-actions-2026-security-roadmap/)). Do not write it.

## 20A.16 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| Passes locally, fails in CI on a pull request | the checkout log shows `refs/pull/N/merge`; reproduce with `git fetch origin && git merge origin/main` on a detached copy | update the branch and fix the interaction | read the checked-out commit first; print it as workflow 1 does |
| Version is a bare commit ID, or `git describe` fails | `git rev-parse --is-shallow-repository` prints `true`; `git tag` prints nothing | `fetch-depth: 0` in that job | decide per job whether it asks history a question |
| A required check never reports and the pull request cannot merge | the workflow has `paths`, `branches` or a skip instruction, so no run exists for this commit | remove the filter from required workflows, or require a job that always runs | require one aggregate job; filter inside jobs, not on the workflow |
| The job is green but a command in a pipeline failed | no `shell:` key, so `bash -e` without `pipefail` | `shell: bash`, or `defaults.run.shell: bash` | set the default once per workflow |
| A step's output is empty in a later step | missing `id`, a typo in the name (no error for a missing property), `>` instead of `>>`, or a read from another job without a job output | fix the reference; add `outputs:` to the job | print outputs in the step that writes them |
| An `if` is always true | text outside `${{ }}` made the value a string | wrap the whole expression | read the annotation that the run shows since January 2026 |
| The old dependency version is installed | a restore key matched a stale cache | key on the lock-file hash | install from the lock file |
| The Python matrix runs 3.1 | `3.10` was not quoted | quote it | quote every version |
| A secret-dependent step fails only for fork pull requests | secrets are not passed to fork runs; the value is an empty string | make the job work without the secret, or skip that step for forks | never switch to `pull_request_target` as a shortcut (Chapter 21A) |

The investigation order for a failing run, and the debug-logging and re-run tools, are Chapter 20B.

## 20A.17 When not to use it, and dangerous edge cases

- **Do not put the only copy of a procedure in a workflow.** A build that exists only as YAML steps cannot be run on a laptop or on another CI system. Keep the commands in the repository (`uv run pytest`, `scripts/deploy.sh`) and let the workflow call them.
- **Do not use a cache as storage or an artifact as a registry.** Caches disappear after 7 days without access; artifacts after the retention period. A release belongs in a package registry or a GitHub Release.
- **Do not use `schedule` for anything that must happen at a given minute.** The documentation says runs can be delayed and, under high load, dropped.
- **Do not add `fetch-depth: 0` everywhere.** On a repository with a long history it turns a one-second fetch into a full clone for every job. Add it to the job that needs history.
- **`continue-on-error` and `if: always()` hide failures by design.** Each use should have a comment that says why. An aggregate job with `always()` must test the results explicitly, as workflow 10 does, or it turns red runs green.
- **A workflow file is code that runs with a token.** Anyone who can push a branch can change what `push` and `pull_request` workflows do on that branch. Protect `.github/workflows/` with CODEOWNERS and a ruleset (Chapter 19).

## 20A.18 Command safety

This chapter's own commands are local reads and additive fetches. The GitHub CLI commands are used in the labs; flags were checked with `gh <command> --help` of version 2.88.1.

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git clone --depth 1 --no-tags <url>` | 🟢 SAFE | creates a new shallow repository | none needed | delete the directory |
| `git fetch --unshallow --tags` | 🟢 SAFE | adds objects and tag refs; removes `.git/shallow` | `git rev-parse --is-shallow-repository` | none needed |
| `git diff --name-only A...B` | 🟢 SAFE | nothing | | |
| `gh run list`, `gh run view --log-failed`, `gh run watch`, `gh cache list` | 🟢 SAFE | nothing on GitHub | | |
| `gh workflow run <file> --ref <branch>` | 🟡 CAUTION | starts a run, which uses minutes and may deploy if the workflow deploys | read the workflow file at that ref | cancel with `gh run cancel <run-id>` |
| `gh run rerun <run-id> --failed` | 🟡 CAUTION | starts a new attempt on the original commit | `gh run view <run-id>` | cancel the attempt |
| `git push origin v0.2.0` | 🟡 CAUTION | creates a tag on GitHub; starts every workflow with a matching tag filter, here an image push | `git ls-remote --tags origin` | deleting the tag does not unpublish the image |

No command in this chapter is 🔴 DANGEROUS.

## 20A.19 Version notes

> **Version note.** Older behavior: JavaScript actions ran on Node 16, then Node 20. Current behavior: Node 24 only. Since: 23 September 2026. Recommended: current majors of every action, pinned by commit ID.

> **Version note.** Older behavior: `actions/checkout` wrote the job token into `.git/config`. Current behavior: stored in a separate file under `$RUNNER_TEMP`. Since: v6 (20 November 2025). Recommended: `persist-credentials: false` unless a later step needs authenticated Git.

> **Version note.** Older behavior: step outputs through `::set-output` on standard output. Current behavior: append to `$GITHUB_OUTPUT`. Since: 11 October 2022 (deprecation; the old form still works with a warning). Recommended: the file.

> **Version note.** Older behavior: any trigger could write the default branch's caches. Current behavior: read-only for triggers that people without write access can cause; `cache-mode` to be explicit. Since: 26 June and 10 September 2026. Recommended: leave the default; do not add `cache-mode: write` to make a warning disappear.

> **Version note.** Older behavior: checks, runs and statuses were kept for 400 days or more. Current behavior: they follow the artifact and log retention setting, 90 days by default, not retroactively. Since: 1 October 2026. The status checks page still says 400 days; the Phase 0 report records the conflict and follows the changelog.

## 20A.20 Practice

- [Module 26 labs](../lab-manual/m26-actions-fundamentals.md): Labs 26.1 to 26.8, one per workflow. Each has you add the file, predict when it runs and what it checks out, run it, read the log, then break it and diagnose.
- Replay any transcript of this chapter, for example `labs/run ch20a/merge-ref` or `labs/run ch20a/shallow-checkout`.
- Then read [Chapter 20B: Delivery, runners, cost and debugging](ch20b-actions-delivery-debugging.md) and [Chapter 21A: GitHub Actions security](ch21a-actions-security.md).

## 20A.21 Interview questions

1. A pull request's CI fails and the author says "it passes on my machine, same commit". What do you check first, and why can both be right?
2. What does `actions/checkout` put on the runner by default? Name three tools or commands that give wrong results there, and say whether each fails or lies.
3. Explain the difference between `run: echo "${{ github.event.pull_request.title }}"` and passing the title through `env`. When is each evaluated, and by what?
4. A job is green although `pytest | tee report.txt` had failing tests. Give the exact shell command line the runner used, and two ways to fix it.
5. For each of `push`, `pull_request`, `schedule` and `workflow_dispatch`: which commit does the run refer to, and from which commit is the workflow file read?
6. A required check stays "expected" forever on documentation-only pull requests. Explain the mechanism and design a fix that keeps the path filter's saving.
7. How do you pass a value from a step to a later step, and from a job to a later job? What cannot be passed this way, and what do you use for it?
8. What is the difference between a cache and an artifact in purpose, scope, lifetime and trust? Which one may a release job consume?
9. A matrix has `os` with two values, `python` with three, one `exclude` and one `include`. How do you count the jobs, and how do you make one of them allowed to fail?
10. Why does this course pin `actions/checkout` by a 40-character commit ID, and what does the Node 24 change of September 2026 mean for a file that says `@v4`?
11. A teammate proposes `if: always()` on the deploy job "so it is not skipped". What happens, and what do you propose?
12. You inherit a repository with twelve workflow files. In what order do you read one of them to predict when it runs, where, with what code, and with what permissions?

## 20A.22 Sources

**Primary sources** (docs.github.com, the GitHub Changelog, and each action's repository at the pinned tag; read on 1 and 2 October 2026)

- Reference pages: [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts), [expressions](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions), [variables](https://docs.github.com/en/actions/reference/workflows-and-actions/variables), [secrets](https://docs.github.com/en/actions/reference/security/secrets), [workflow commands](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands), [dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching), [limits](https://docs.github.com/en/actions/reference/limits), [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [reusing workflow configurations](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations).
- Other documentation: [workflow artifacts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts), [GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token), [skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs), [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [publishing a package with Actions](https://docs.github.com/en/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions).
- Action READMEs and `action.yml` files at the pinned versions: [checkout v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md), [setup-python v7.0.0](https://github.com/actions/setup-python/blob/v7.0.0/README.md), [setup-java v6.0.1](https://github.com/actions/setup-java/blob/v6.0.1/README.md), [cache v6.1.0](https://github.com/actions/cache/blob/v6.1.0/README.md), [upload-artifact v7.0.1](https://github.com/actions/upload-artifact/blob/v7.0.1/README.md), [download-artifact v8.0.1](https://github.com/actions/download-artifact/blob/v8.0.1/README.md), [setup-uv v10.2.0](https://github.com/astral-sh/setup-uv/blob/v10.2.0/README.md), [docker/login-action v4.6.0](https://github.com/docker/login-action/blob/v4.6.0/README.md), [docker/metadata-action v6.2.0](https://github.com/docker/metadata-action/blob/v6.2.0/README.md), [docker/build-push-action v7.4.0](https://github.com/docker/build-push-action/blob/v7.4.0/README.md), [docker/setup-buildx-action v4.4.1](https://github.com/docker/setup-buildx-action/blob/v4.4.1/README.md).
- Tool documentation: [uv with GitHub Actions](https://docs.astral.sh/uv/guides/integration/github/), [Docker: cache management with GitHub Actions](https://docs.docker.com/build/ci/github-actions/cache/).
- Changelog entries, linked where they are used.
- Git 2.55 manual pages: `git help clone`, `git help fetch`, `git help describe`, `git help diff`. GitHub CLI 2.88.1: `gh run --help`, `gh workflow --help`, `gh cache --help`.

**Secondary sources**

- The Phase 0 report of this course, sections 2, 3, 4, 12 and 13, and its notes on GitHub Actions, including the flags carried into this chapter as "Unverified".

**Videos** (from the Phase 0 report, with its caveats)

- ["Complete GitHub Actions Course - From BEGINNER to PRO"](https://www.youtube.com/watch?v=Xwpi0ITkL3U), Sid Palas, DevOps Directive, 3 h 43 min, 24 September 2025. The most complete current free course on workflow mechanics. It predates the Node 24-only runtime and `actions/checkout` v7, says "branch protections" and never mentions rulesets.
- ["GitHub Actions tutorial in Hindi"](https://www.youtube.com/watch?v=ookIfjc8dW0), CODERS NEVER QUIT, 1 h 51 min, 27 September 2024, Hindi. Jobs, expressions, checkout, caching and artifacts. Mostly current in concept; the action versions shown were not checked; no pinning.

**Further reading**

- [Chapter 17: Pull Requests](ch17-pull-requests.md), sections 17.2, 17.6 and 17.11; [Chapter 18: Branch Protection and Rulesets](ch18-branch-protection.md) on required status checks; [Chapter 19: CODEOWNERS](ch19-codeowners.md) on protecting the workflows directory; [Chapter 26: Performance](ch26-performance.md), section 26.11 on shallow clones; [Chapter 14A: History investigation](ch14a-history-investigation.md) on two-dot and three-dot ranges.
