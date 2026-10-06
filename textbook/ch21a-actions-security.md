# Chapter 21A: GitHub Actions security

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026, with the quoted documentation pages re-read on 2 October 2026. Transcripts are real output from `labs/ch21a/`. They show plain Git and `grep` on this course's workflow files. Nothing in this chapter was run on GitHub: `workflows/12-secure.yml` and the five files in `workflows/vulnerable/` were assembled from documented syntax and parse-checked with PyYAML, but not executed. Every statement about how GitHub Actions behaves comes from the documentation, a changelog entry, or a published post-mortem, and carries the link.

This chapter is defensive. It shows unsafe workflow patterns next to their fixes, at the level of detail GitHub's own security documentation uses, so that you can review and harden your team's workflows. It contains no working attack. Workflow mechanics (events, contexts, caching, environments, runners) are taught in [Chapter 20A](ch20a-actions-fundamentals.md) and [Chapter 20B](ch20b-actions-delivery-debugging.md). Repository security and the response to a leaked secret are [Chapter 21B](ch21b-repository-security-incident-response.md).

## 21A.1 Why this matters

"A contributor we have never heard of opened a pull request on our public evaluation library. Eight hours later there were malicious versions of our package on the registry, published by our own release workflow. No password was stolen. How?"

That is the shape of the TanStack incident of 11 May 2026 (section 21A.18), and each step in it was documented behavior: a workflow trigger that runs with the base repository's privileges, a checkout of the contributor's code, a cache shared with the release job, and a release job that could request a publishing identity. A CTO who asks this question does not want a list of settings. They want to know which line of which file gave an outsider code execution next to a credential, why the platform allowed it, what the smallest change is that closes it, and how you will know it stays closed.

The whole chapter reduces to one question that you ask of every job:

> Whose code runs in this job, on whose text does it operate, and what can the job reach?

If the answer to the first two parts is "somebody outside the team" and the answer to the third is anything other than "nothing", you have found a vulnerability.

## 21A.2 The model in five parts

**In one sentence.** A workflow run is a program that GitHub starts on your behalf, with a credential for your repository in its pocket, and its safety depends on who controls the program's code and its inputs.

**Analogy.** A contractor is let into your office each time a parcel arrives. The front desk gives the contractor a badge; the badge opens whatever doors the desk configured. The contractor follows a written procedure (the workflow file), uses tools bought from other firms (actions), and reads the label on the parcel (event data). Three things can go wrong: the badge opens too many doors, the procedure was written by the person who sent the parcel, or the contractor reads the label aloud as if it were an instruction. The analogy breaks in one place that matters: this contractor executes text literally and instantly, so a label that contains an instruction is carried out before anyone can notice.

**Precisely.** The Phase 0 report condenses GitHub's documentation into five parts, and the rest of this chapter takes them one at a time:

| Part | The fact | Section |
|---|---|---|
| 1. The job token | Each job receives a `GITHUB_TOKEN` limited to the workflow's repository; the `permissions` key sets what it may do | 21A.3 |
| 2. Fork pull requests | A `pull_request` run from a fork gets a read-only token and no secrets; by default only first-time contributors need approval | 21A.4 |
| 3. Privileged triggers | `pull_request_target` (and `workflow_run`, `issue_comment`) run with the base repository's token and secrets; they are safe only while they do not run the fork's code | 21A.5 |
| 4. Expression injection | `${{ }}` is substituted into the script text before the shell starts, so attacker-controlled fields become code | 21A.6 |
| 5. Third-party actions | An action runs with the job's token and secrets; a tag can be moved; only a full commit SHA is immutable | 21A.7 |

**Picture.** Trust flows downward. Everything above the dashed line is controlled by people with write access; everything below it can be controlled by anyone on the internet.

```text
  TRUSTED (write access required)
  +----------------------------+   +---------------------------+   +--------------------+
  | workflow file on the       |   | secrets, variables,       |   | actions pinned to  |
  | default branch             |   | environments, OIDC trust  |   | a full commit SHA  |
  +-------------+--------------+   +-------------+-------------+   +---------+----------+
                |                                |                           |
                v                                v                           v
        +------------------------------- one job on one runner -------------------------------+
        |  GITHUB_TOKEN (permissions)   secrets named in the job   OIDC token if id-token     |
        +-------------------------------------------------------------------------------------+
                ^                                ^                           ^
  - - - - - - - | - - - - - - - - - - - - - - - -| - - - - - - - - - - - - - | - - - - - - - -
                |                                |                           |
  +-------------+--------------+   +-------------+-------------+   +---------+----------+
  | code of a fork pull        |   | event text: titles,       |   | actions referenced |
  | request, if checked out    |   | bodies, branch names,     |   | by tag or branch;  |
  | and run                    |   | labels, commit messages   |   | caches; artifacts  |
  +----------------------------+   +---------------------------+   +--------------------+
  UNTRUSTED (anyone who can open a pull request or an issue, or who controls a dependency)
```

> **GitHub Actions, not Git.** Nothing in this model is a property of Git. Git contributes exactly two facts that the model relies on: a tag is a ref that can be moved, and a commit ID names content that cannot change (section 21A.7).

## 21A.3 The job token and `permissions`

**In one sentence.** Every job gets its own short-lived token for the repository that contains the workflow, and the `permissions` key decides what that token may do.

**Analogy.** A visitor badge printed at the start of each shift and shredded at the end. The desk can print it with access to one room or to the whole building. The analogy breaks because every tool the visitor picks up can use the badge without asking: "An action can access the `GITHUB_TOKEN` through the `github.token` context even if the workflow does not explicitly pass the `GITHUB_TOKEN` to the action" ([authenticate with GITHUB_TOKEN](https://docs.github.com/en/actions/tutorials/authenticate-with-github_token)).

**Precisely.** "At the start of each workflow job, GitHub automatically creates a unique `GITHUB_TOKEN` secret to use in your workflow." It is a GitHub App installation access token, and "the token's permissions are limited to the repository that contains your workflow". It expires when the job finishes; on GitHub-hosted runners it "can live for a maximum of 6 hours" ([GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token)).

What the token may do is decided in three layers:

| Layer | Where | What it decides |
|---|---|---|
| The repository or organization default | The "Workflow permissions" setting | What a workflow with no `permissions` key gets: either "read and write access for all permissions" or "just read access for the `contents` and `packages` permissions" ([repository settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#setting-the-permissions-of-the-github_token-for-your-repository)) |
| The workflow | Top-level `permissions` | The token of every job that does not override it |
| The job | `jobs.<job_id>.permissions` | The token of that job only |

Three rules of the `permissions` key carry most of the weight ([workflow syntax, permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions)):

1. "If you specify the access for any of these permissions, all of those that are not specified are set to `none`." Writing `contents: read` therefore also removes `issues`, `packages`, `pull-requests` and every other scope.
2. `permissions: {}` removes everything. `permissions: read-all` and `permissions: write-all` are the two shorthands.
3. The scopes listed on 1 October 2026 are `actions`, `artifact-metadata`, `attestations`, `checks`, `code-quality`, `contents`, `deployments`, `discussions`, `id-token`, `issues`, `packages`, `pages`, `pull-requests`, `security-events`, `statuses` and `vulnerability-alerts`; each takes `read`, `write` or `none`, and `write` includes `read`.

> **Version note.** Older behavior: a workflow without a `permissions` key received a read-write token. Current behavior: the default is read-only for *new* repositories, organizations and enterprises. Since: 2 February 2023, and "this change will not impact any existing enterprises, organizations or repositories" ([changelog](https://github.blog/changelog/2023-02-02-github-actions-updating-the-default-github_token-permissions-to-read-only/)). Recommended: never rely on the default. Declare `permissions` at the top of every workflow, because a repository created before February 2023 may still have the permissive setting. The Nx project's post-mortem names exactly this as one of three causes (section 21A.18).

The unsafe and the safe form, side by side:

```yaml
# Unsafe: every job, and every action in every job, can push, tag, release and edit issues.
permissions: write-all
```

```yaml
# Safe: read-only for the workflow; one job adds the one scope it needs.
permissions:
  contents: read

jobs:
  label:
    permissions:
      issues: write        # contents is now none for this job, which is fine: it checks nothing out
```

GitHub's guidance is the same in prose: "It's good security practice to set the default permission for the `GITHUB_TOKEN` to read access only for repository contents. The permissions can then be increased, as required, for individual jobs within the workflow file" ([secure use](https://docs.github.com/en/actions/reference/security/secure-use#use-secrets-for-sensitive-information)).

Two properties limit what a stolen job token can do. First, "events triggered by the `GITHUB_TOKEN` will not create a new workflow run", with `workflow_dispatch` and `repository_dispatch` as the documented exceptions ([GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token)). The exception is not academic: in the Nx incident a stolen read-write token was used to dispatch the publish workflow. Second, the token dies with the job.

**Inside `.git`.** The token also reaches Git. The `actions/checkout` README says: "The auth token is persisted in the local git config. This enables your scripts to run authenticated git commands. The token is removed during post-job cleanup. Set `persist-credentials: false` to opt-out" ([checkout README](https://github.com/actions/checkout/blob/v7.0.1/README.md)). Since version 6 of the action the credential is stored "in a separate file under `$RUNNER_TEMP` instead of directly in `.git/config`" (same page). Either way, until the job ends, every later step and every process it starts can run authenticated Git commands against your repository with whatever `contents` permission the job has. A job that only builds and tests has no reason to leave it there.

## 21A.4 Fork pull requests and the approval gate

**In one sentence.** A workflow triggered by `pull_request` from a fork runs the contributor's version of the code with a read-only token and without your secrets.

**Analogy.** A visitor may use the lobby computer, which has no access to the internal network. The analogy breaks in two places: by default a visitor who has been in the building once is waved through without a check from then on, and the lobby computer may be one of your own machines (a self-hosted runner, section 21A.12).

**Precisely.** "With the exception of `GITHUB_TOKEN`, secrets are not passed to the runner when a workflow is triggered from a forked repository. The `GITHUB_TOKEN` has read-only permissions in pull requests from forked repositories" ([events, workflows in forked repositories](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflows-in-forked-repositories)). Pull requests opened by Dependabot are treated the same way.

Whether such a run starts at all is a separate setting. For public repositories, "by default, all first-time contributors require approval to run workflows", and the options are approval for first-time contributors who are new to GitHub, for all first-time contributors, or for all external contributors. The documentation attaches a warning: a user "that has had any commit or pull request merged into the repository will not require approval", and "a malicious user could meet this requirement by getting a simple typo" fix accepted ([controlling changes from forks](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#controlling-changes-from-forks-to-workflows-in-public-repositories)).

| What the fork model protects | What it does not protect |
|---|---|
| Your secrets: they are not sent to the runner | The runner itself: the contributor's code still executes on it |
| Your repository: the token cannot write | Readable data: a public repository's contents, and the caches a pull request may restore (section 21A.11) |
| | A self-hosted runner, which is your machine |
| | Workflows on privileged triggers, which "will always run, regardless of approval settings" (same page) |

The last row is the hinge of the next section. The approval gate applies to `pull_request`. It does not apply to `pull_request_target`.

**In production.** An open-source evaluation harness wants to show benchmark scores on contributor pull requests. The scores need a provider API key. Under `pull_request` the key is absent, so the job fails for every outside contributor. This is the fork model working. The wrong fix is in the next section; the right ones are to run the keyed evaluation after merge, or on demand by a maintainer on a branch inside the repository, or to split the work into an unprivileged run and a privileged follow-up that never executes the contributor's code.

## 21A.5 Privileged triggers and the "pwn request"

**In one sentence.** `pull_request_target` runs your workflow, from your default branch, with your token and your secrets, in response to a stranger's pull request; it is safe exactly as long as it never executes that stranger's code.

**Analogy.** The front desk has a procedure for parcels from unknown senders: log the parcel, put a sticker on it, send a receipt. The procedure is safe because the desk never opens the parcel. A "pwn request" is the day someone amends the procedure to "open the parcel and follow the instructions inside", while the clerk still holds the master key. The analogy breaks because the parcel can also influence the clerk without being opened: its label is event text (section 21A.6).

**Precisely.** GitHub's reference says such workflows "run with elevated trust: the job receives the base repository's `GITHUB_TOKEN` and access to repository and organization secrets". The trigger is safe by default because "the workflow, and any subsequent `actions/checkout` call that does not specify a `ref`, is taken from the base repository's default branch". Then: "You introduce risk when a workflow author overrides this default to run the fork's code." And: "The checkout step alone does not execute untrusted code… The vulnerability is completed by the *next* step that runs code checked out into the current working directory." "This pattern is known as a 'pwn request' and has been the root cause of multiple supply-chain compromises" ([securely using pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)).

The token is not read-only here: "When a workflow is triggered by the `pull_request_target` event, the `GITHUB_TOKEN` is granted read/write repository permission, even when it is triggered from a public fork" ([workflow syntax, permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions)).

The unsafe pattern, as the documentation prints it. The `actions/checkout@v6` line is the documentation's own example, quoted unchanged; the workflows of this course pin `actions/checkout` v7.0.1 by commit ID (section 21A.7), and since v7 and its back-ports the action refuses this checkout unless `allow-unsafe-pr-checkout: true` is set (the table at the end of this section):

```yaml
# INSECURE. Provided as an example only.
on:
  pull_request_target:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - name: Test
        run: make test
```

Read it with the question from section 21A.1. Whose code runs? `make test` runs the `Makefile` of the pull request, so the contributor's. What can the job reach? A read-write token and every repository and organization secret the workflow names. What an attacker achieves is whatever those credentials allow: pushing commits, publishing packages, reading secrets. "Run" is wider than it looks. A build, an install step with lifecycle scripts, a test runner, a linter that loads a configuration file from the working directory: each executes or is steered by files from the checkout.

The same reference lists the shapes to look for in review:

| Shape | Example |
|---|---|
| Checking out the pull request's head or merge commit | `ref: ${{ github.event.pull_request.head.sha }}`, or `ref: refs/pull/${{ github.event.pull_request.number }}/merge` |
| Pointing the checkout at the fork | `repository: ${{ github.event.pull_request.head.repo.full_name }}` |
| Fetching the code another way and running it | `git fetch` of the pull request ref, `gh pr checkout`, or downloading an artifact built from it |

And it widens the scope: "Pwn requests are also not unique to `pull_request_target`… an `issue_comment` or `workflow_run` workflow that fetches and runs a fork's pull request code is vulnerable in the same way."

**The fix, in order of preference.**

1. Do not use the trigger. "If the workflow does not need `pull_request_target`, update it to use a safer event where appropriate, such as `pull_request`" (same reference). Most CI needs no secrets and no write token.

```yaml
# Safe: the contributor's code runs, but with a read-only token and no secrets.
on:
  pull_request:

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - name: Test
        run: make test
```

2. If a privileged action is needed (a comment, a label), keep `pull_request_target` but never check out or run the pull request's code: operate on metadata only, with the narrowest `permissions`.
3. If the privileged action needs a result computed from the contributor's code, separate the two. GitHub Security Lab's design is an unprivileged `pull_request` workflow that builds and tests and uploads its result as an artifact, and a privileged `workflow_run` workflow that downloads the artifact and comments. Artifact data is safe there when used "in a safe manner, like reading PR numbers or reading a code coverage text to comment on the PR" ([preventing pwn requests](https://securitylab.github.com/resources/github-actions-preventing-pwn-requests/)). The secure-use reference agrees: "For privilege separation between workflows, `workflow_run` is a better trigger", and such workflows "should treat artifacts uploaded from other workflows with caution" ([untrusted code checkout](https://docs.github.com/en/actions/reference/security/secure-use#mitigating-the-risks-of-untrusted-code-checkout)).

```text
  fork pull request
        |
        v
  [ pull_request workflow ]  read-only token, no secrets
     runs the contributor's code, uploads result.txt as an artifact
        |
        v  (workflow_run: completed)
  [ workflow_run workflow ]  write token, taken from the default branch
     downloads result.txt, treats it as DATA (never executes it,
     never interpolates it into a script), posts the comment
```

A label as a gate ("run only when a maintainer adds `safe-to-test`") is weaker than it looks. The Security Lab article notes it "is still prone to a race condition in which the attacker may push new changes after the workflow was approved (labeled), but has not started yet".

**The platform now leans against the pattern.** Four changes matter in review, and none of them removes the need for it:

| Change | Effect | What it does not cover |
|---|---|---|
| 8 December 2025 ([changelog](https://github.blog/changelog/2025-11-07-actions-pull_request_target-and-environment-branch-protections-changes/)) | The workflow file for `pull_request_target` always comes from the default branch | A vulnerable workflow that is on the default branch |
| `actions/checkout` v7, 18 June 2026, back-ported to older lines on 20 July 2026 ([changelog](https://github.blog/changelog/2026-06-18-safer-pull_request_target-defaults-for-github-actions-checkout/)) | The action refuses to fetch a fork pull request's head or merge ref under `pull_request_target`, and under `workflow_run` started by a pull request event, unless `allow-unsafe-pr-checkout: true` | `git fetch` or `gh pr checkout` in a `run` step; other events such as `issue_comment` |
| Read-only caches for low-trust triggers, 26 June 2026 (section 21A.11) | A privileged-trigger run cannot write the default branch's cache | Restoring a cache that was already poisoned |
| Workflow execution protections, generally available 17 September 2026 (section 21A.8) | A default rule will block `pull_request_target` in public repositories from 2 November 2026 unless a maintainer allows it | Private and internal repositories |

The opt-out input deserves one sentence of its own. The changelog says "the flag is intentionally named to be easy to spot in code review and static analysis", and the reference says: "Only do this after confirming the checked-out code is never executed." In a pull request, `allow-unsafe-pr-checkout: true` is a line that needs a written justification.

## 21A.6 Script injection

**In one sentence.** An expression in `${{ }}` is replaced by its value in the text of the script before the shell starts, so a value that an outsider controls becomes part of your program.

**Analogy.** Mail merge. You write "Dear {name}, your order shipped" and the software pastes the name in. If the letter is then read aloud by someone who obeys every sentence, a customer whose "name" contains a sentence gets it obeyed. The analogy is close; it breaks only in that a shell is far more obedient than any reader, and treats quotes and separators in the pasted text as structure.

**Precisely.** "The `run` command executes within a temporary shell script on the runner. Before the shell script is run, the expressions inside `${{ }}` are evaluated and then substituted with the resulting values, which can make it vulnerable to shell command injection" ([script injections](https://docs.github.com/en/actions/concepts/security/script-injections)). The order is the whole mechanism:

```text
  workflow file            GitHub Actions                     runner
  -------------            --------------                     ------
  run: |                   1. evaluate ${{ ... }}             3. write the text to a
    title="${{ X }}"  -->  2. paste the VALUE of X     -->       temporary script file
                              into the script text            4. start the shell on it

  The shell never sees "${{ X }}". It sees whatever X contained, as source code.
```

Which values are attacker-controlled? The documentation: "Attackers can add their own malicious content to the `github` context, which should be treated as potentially untrusted input. These contexts typically end with `body`, `default_branch`, `email`, `head_ref`, `label`, `message`, `name`, `page_name`, `ref`, and `title`" (same page). Branch names are on the list (`head_ref`), and Git allows characters in a branch name that a shell treats as syntax. Commit messages, author names and email addresses are Git data that anyone can set to anything ([Chapter 21B](ch21b-repository-security-incident-response.md) shows the spoofing locally).

The unsafe step, as the documentation prints it:

```yaml
- name: Check PR title
  run: |
    title="${{ github.event.pull_request.title }}"
    if [[ $title =~ ^octocat ]]; then
    echo "PR title starts with 'octocat'"
    exit 0
    else
    echo "PR title did not start with 'octocat'"
    exit 1
    fi
```

The author's quotes do not help, because the value arrives before the shell parses anything: a title that contains a double quote closes the string, and what follows it is parsed as commands. The documentation's own demonstration uses a title that closes the quote and lists the workspace directory. What an attacker achieves is arbitrary commands in that job, with that job's token and secrets. On `pull_request` from a fork that is contained by the fork model. On `pull_request_target`, `issues`, `issue_comment` or `discussion`, it is not: the Nx compromise began with exactly this, a pull request title echoed in a `pull_request_target` workflow (section 21A.18).

The fixed step uses the documented mitigation, an intermediate environment variable ([secure use, script injection](https://docs.github.com/en/actions/reference/security/secure-use#good-practices-for-mitigating-script-injection-attacks)):

```yaml
- name: Check PR title
  env:
    TITLE: ${{ github.event.pull_request.title }}
  run: |
    if [[ "$TITLE" =~ ^octocat ]]; then
    echo "PR title starts with 'octocat'"
    exit 0
    else
    echo "PR title did not start with 'octocat'"
    exit 1
    fi
```

**Why the environment-variable form is safe.** The expression is still evaluated, but its value no longer goes into the script text. In the documentation's words, the value "is stored in memory and used as a variable, and doesn't interact with the script generation process". The script that the shell parses is now a constant: it is identical for every pull request, and you can review it once. The title reaches the shell as the *value* of `$TITLE` after parsing is over, and the shell does not re-parse the value of a variable as commands when it expands it. The double quotes around `"$TITLE"` are still needed, for the ordinary shell reason that an unquoted expansion is split into words and glob-expanded; the documentation tells you to quote for that reason.

```text
Observed behavior : a step that only prints a pull request title runs commands nobody wrote
Git state         : irrelevant; the title is GitHub data, a branch name or commit message is Git data
Mechanism         : ${{ }} is substituted into the script text before the shell starts
Root cause        : attacker-controlled text was placed where the shell expects source code
Why Actions does  : expressions are a templating layer over the whole workflow file; the
  this              template engine does not know that the result will be parsed by a shell
Correct fix       : pass the value through env: (or as an action input with with:) and use "$VAR"
Prevention        : treat every ${{ }} inside run: as a finding until proven constant; run CodeQL
                    for workflows, zizmor or actionlint in CI (section 21A.14)
```

The same reference gives a second mitigation, which it prefers when available: "Use an action instead of an inline script", passing the value through `with:`. Two notes for review. The rule is about where the value lands, not which context it comes from; a pull request number cannot carry code, but a reviewer who decides case by case will eventually decide wrongly, so many teams adopt the mechanical rule of no `${{ }}` inside `run:` at all. And `env:` does not make later misuse safe: `eval "$TITLE"`, or writing the value unvalidated into `$GITHUB_ENV`, brings the problem back one layer down.

**In production.** A prompt-evaluation workflow prints the pull request title in a job that holds a provider API key because it runs on `pull_request_target`. That one line is the Nx pattern (section 21A.18). The fix is two edits: the `env:` form, and removing the privileged trigger so that the key is not in the job at all.

## 21A.7 Third-party actions: mutable tags and commit pinning

**In one sentence.** `uses: owner/repo@ref` downloads and runs someone else's code inside your job, and only a full commit ID guarantees that it is the code you reviewed.

**Analogy.** A tag is a street address; a commit ID is a fingerprint. Whoever owns the plot can put up a different building at the same address overnight. The analogy breaks in your favor: a fingerprint can in principle be shared by two people, while forging a commit ID means producing "a SHA-1 collision for a valid Git object payload" ([secure use, third-party actions](https://docs.github.com/en/actions/reference/security/secure-use#using-third-party-actions)).

**Precisely.** A compromised action "would have access to all secrets configured on your repository, and may be able to use the `GITHUB_TOKEN` to write to the repository". "Pinning an action to a full-length commit SHA is currently the only way to use an action as an immutable release." Tags are a matter of trust: "Pin actions to a tag only if you trust the creator… a tag can be moved or deleted if a bad actor gains access to the repository" (same page). The same applies to reusable workflows.

**See it.** This is Git, not GitHub Actions, so it can be shown locally. A bare repository stands for an action's repository; `v1` is an annotated tag.

<!-- snippet: ch21a/mutable-tag/01-resolve -->
```text
# What a consumer gets for "report-size@v1" today. The line ending in ^{} is the commit.
$ git ls-remote --tags hosting/report-size.git
71c87ced80cd16d0206b29b9a557f2bdf5e3d3b2	refs/tags/v1
80827f43993c0dc6fc8324685d01e720707e5429	refs/tags/v1^{}
```
<!-- /snippet -->

The first line is the tag object, the second (ending in `^{}`) the commit it points at. Now someone with push access, a maintainer or whoever holds a maintainer's token, moves the tag:

<!-- snippet: ch21a/mutable-tag/02-move -->
```text
# Anyone who can push to the action repository can point v1 somewhere else.
$ git tag -f -a v1 -m "report-size v1"
Updated tag 'v1' (was 71c87ce)
$ git push --force origin v1
To $LAB/ch21a/mutable-tag/hosting/report-size.git
 + 71c87ce...0ca190d v1 -> v1 (forced update)
```
<!-- /snippet -->

<!-- snippet: ch21a/mutable-tag/03-after -->
```text
# Same name, different commit. No consumer workflow changed.
$ git ls-remote --tags hosting/report-size.git
0ca190da3c6db48b75af6a358aef5b189725e9a4	refs/tags/v1
5de1e2d145bc0b3fbb28e6d457f7220359d63f84	refs/tags/v1^{}

# The commit that was reviewed still exists, and its ID still names exactly that content.
$ git -C hosting/report-size.git cat-file -p 80827f43993c0dc6fc8324685d01e720707e5429:action.yml
name: report-size
description: Prints the size of the build output
runs:
  using: composite
  steps:
    - run: du -sh dist
      shell: bash
```
<!-- /snippet -->

A workflow that says `@v1` now runs `5de1e2d`. A workflow that says `@80827f43993c0dc6fc8324685d01e720707e5429` runs what it ran yesterday. 🔴 DANGEROUS: `git push --force origin v1` replaces a published tag. It changes the remote tag ref; it can silently change what every consumer of the tag runs; preview with `git ls-remote --tags origin v1`; recover by pushing the old tag object back, if you still have it; it is appropriate only for a deliberate "moving major tag" policy that consumers know about.

| | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git tag -f -a v1` | unchanged | unchanged | unchanged | unchanged | `refs/tags/v1` points at a new tag object | unchanged | unchanged |
| `git push --force origin v1` | unchanged | unchanged | unchanged | unchanged | unchanged | `refs/tags/v1` replaced | every `@v1` reference resolves to the new commit on its next run |

**Writing and maintaining a pin.**

```yaml
# Unsafe: resolved again on every run, to whatever the tag points at then.
- uses: actions/setup-python@v7

# Safe: the commit, with the version as a comment for humans and for Dependabot.
- uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
```

Take the commit ID from the action's own repository (`workflows/ACTION_PINS.md` shows the `git ls-remote` command): "you should verify it is from the action's repository and not a repository fork" (same page). Pins do not update themselves, which is the point, so let Dependabot propose the updates. The documented configuration ([keeping your actions up to date](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot)):

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

Since 14 July 2026, version updates wait a default cooldown of three days after a release before a pull request is opened; security updates are immediate, and the `cooldown` option configures it ([changelog](https://github.blog/changelog/2026-07-14-dependabot-version-updates-introduce-default-package-cooldown/)). A cooldown gives the ecosystem time to notice a malicious release before you adopt it.

**The limits of pinning.** State these whenever you recommend it:

- A pin protects against a moved tag, "but not against a malicious commit pinned deliberately or against unpinned actions nested inside composite actions" (Phase 0 report). Read the diff of a pin update.
- "Dependabot only creates alerts for vulnerable actions that use semantic versioning and will not create alerts for actions pinned to SHA values" ([secure use](https://docs.github.com/en/actions/reference/security/secure-use#keeping-the-actions-in-your-workflows-secure-and-up-to-date)). Pinning trades automatic alerts for immutability; version updates and advisories you read yourself fill the gap.
- A remote script fetched and executed in a `run` step (`curl … | bash`) is the same risk class with no pin available. That is the Codecov case.
- Immutable releases (generally available since 28 October 2025) make a published release's tag unchangeable once a maintainer enables the feature ([changelog](https://github.blog/changelog/2025-10-28-immutable-releases-are-now-generally-available/)); `astral-sh/setup-uv` has used them since v8.0.0. You cannot see from a `uses:` line whether a tag is protected this way, so the pin remains the rule.

> **Unverified.** "Immutable actions" (actions published as packages) had no general-availability announcement that the research could find by 1 October 2026, and the secure-use page still calls commit pinning "currently the only way". GitHub's 2026 roadmap describes workflow-level dependency locking as future work ([roadmap](https://github.blog/news-insights/product-news/whats-coming-to-our-github-actions-2026-security-roadmap/)); it has not shipped.

## 21A.8 Organization policies

**In one sentence.** Policies move three of this chapter's rules from "every author must remember" to "the platform refuses".

| Policy | What it enforces | Source |
|---|---|---|
| Allowed actions and reusable workflows | Allow all; only those in the owner's organization or enterprise; or the owner plus a selection, with switches for actions created by GitHub and by verified Marketplace creators and a pattern list. Available on all plans since 5 February 2026 | [repository settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#allowing-select-actions-and-reusable-workflows-to-run), [changelog](https://github.blog/changelog/2026-02-05-github-actions-early-february-2026-updates/) |
| Blocking | "Prefix an entry with `!` to block a specific action or version" (since 15 August 2025) | [changelog](https://github.blog/changelog/2025-08-15-github-actions-policy-now-supports-blocking-and-sha-pinning-actions/) |
| "Require actions to be pinned to a full-length commit SHA" | "any workflow that attempts to use an action that isn't pinned will fail", including GitHub's own actions; "Reusable workflows can still be referenced by tag" | same changelog; [repository settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#managing-github-actions-permissions-for-your-repository) |
| Workflow permissions default | Read-only token for workflows without a `permissions` key; a restrictive organization default disables the permissive option below it | section 21A.3 |
| Fork pull request approval | Who needs approval before a `pull_request` run starts | section 21A.4 |
| Workflow execution protections | Actor rules (who may trigger workflows) and event rules (which events may run), built on rulesets, at enterprise, organization and repository level | [changelog](https://github.blog/changelog/2026-09-17-workflow-execution-protections-in-github-actions-generally-available/), [about Actions policies](https://docs.github.com/en/actions/concepts/about-actions-policies) |
| "Allow GitHub Actions to create and approve pull requests" | Off by default for new personal repositories; keep it off so that a workflow cannot approve its own change | [repository settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#setting-the-permissions-of-the-github_token-for-your-repository) |

The labels are quoted from the documentation; the interface changes, so trust the linked page over this table.

**The change dated 2 November 2026.** With execution protections, GitHub introduced a default event rule: "For public repositories that do not already have an applicable event policy, GitHub is introducing a default rule that disables `pull_request_target`… It initially runs in evaluate mode… On November 2, 2026, we'll automatically enforce the default rule for affected repositories" ([changelog](https://github.blog/changelog/2026-09-17-workflow-execution-protections-in-github-actions-generally-available/); the [reference](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target#default-policy-for-pull_request_target) words it as enforcement "for affected repositories that were using the default `pull_request_target` policy before general availability"). Private and internal repositories are not affected. A maintainer can explicitly allow the event, optionally for named workflow files. If your public repository has a labeler or a welcome bot on `pull_request_target`, decide before that date: migrate it, or allow it deliberately after reviewing it against section 21A.5.

Policies do not replace review of the files. The control for that is a code-owner rule on `.github/workflows/` enforced by a ruleset ([Chapter 19](ch19-codeowners.md), section 19.8): "If all your workflow files are stored .github/workflows, you can add this directory to the code owners list, so that any proposed changes to these files will first require approval" ([secure use](https://docs.github.com/en/actions/reference/security/secure-use#using-codeowners-to-monitor-changes)).

## 21A.9 Secrets: scope, and why masking is not a boundary

**In one sentence.** A secret is as exposed as the least trustworthy code in any job that receives it.

**Precisely.** Secrets exist at organization, repository and environment level, and "GitHub Actions can only read a secret if you explicitly include the secret in a workflow" ([secrets](https://docs.github.com/en/actions/concepts/security/secrets)). Where you include it sets the exposure:

```yaml
# Unsafe: every step of every job, including third-party actions and your dependencies'
# install scripts, has the token in its environment.
env:
  DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}

jobs:
  lint: ...
  test: ...
  deploy: ...
```

```yaml
# Safe: one step of one job, behind an environment.
jobs:
  deploy:
    environment:
      name: staging
    steps:
      - name: Deploy
        env:
          DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
        run: bash scripts/deploy.sh staging
```

Two facts are routinely misunderstood.

1. **Write access is secret access.** "Any user with write access to your repository has read access to all secrets configured in your repository" ([secure use](https://docs.github.com/en/actions/reference/security/secure-use#use-secrets-for-sensitive-information)): they can push a branch with a workflow that uses them. GhostAction and Shai-Hulud are this sentence at scale. Environment secrets behind required reviewers (section 21A.13) are the exception that makes the sentence false for your most valuable credentials.
2. **Masking is a courtesy for logs.** Registered secrets are redacted from logs, but "because there are multiple ways a secret value can be transformed, this redaction is not guaranteed"; "never use structured data as a secret"; and "if an unredacted secret is sent to a workflow run log, you should delete the log and rotate the secret" (same page). Redaction matches known strings in log output. It does nothing about a process that sends the value elsewhere, and nothing about code that reads the runner's memory, the technique the report finds recurring from tj-actions to TanStack. The boundary is which code runs in the job and which secrets the job holds.

## 21A.10 OIDC federation

**In one sentence.** Instead of storing a cloud key as a secret, the job asks GitHub for a signed statement of what it is, and the cloud exchanges that statement for a credential valid for that job only.

**Analogy.** A notarized letter of introduction in place of a copied house key. The cloud reads the letter (repository, branch, environment) and decides whether to open. The analogy breaks at one point: any code running in the job can ask the notary for the letter.

**Precisely.** "The job or workflow must grant the `id-token: write` permission to allow GitHub's OIDC provider to create a JSON Web Token"; the setting "only enables fetching and setting the OIDC token; it does not grant write access to other resources". The issuer is `https://token.actions.githubusercontent.com`, the default audience is the URL of the repository owner, and the cloud returns "a short-lived access token that is only valid for a single job" ([OIDC reference](https://docs.github.com/en/actions/reference/security/oidc), [OpenID Connect](https://docs.github.com/en/actions/concepts/security/openid-connect)).

The token's claims describe the run: besides the standard `aud`, `iss`, `sub`, `exp`, `iat`, `jti` and `nbf` there are `repository`, `repository_id`, `repository_owner`, `repository_owner_id`, `repository_visibility`, `ref`, `ref_type`, `environment`, `event_name`, `workflow_ref`, `job_workflow_ref`, `runner_environment`, `actor` and others. The cloud's trust policy matches on them, above all on the subject:

| Run | Default subject (`sub`) |
|---|---|
| Job that references an environment | `repo:ORG-NAME/REPO-NAME:environment:ENVIRONMENT-NAME` |
| Pull request event, no environment | `repo:ORG-NAME/REPO-NAME:pull_request` |
| Branch | `repo:ORG-NAME/REPO-NAME:ref:refs/heads/BRANCH-NAME` |
| Tag | `repo:ORG-NAME/REPO-NAME:ref:refs/tags/TAG-NAME` |

"You **must** define at least one condition, so that untrusted repositories can't request access tokens for your cloud resources" (OIDC reference). The trust policy is where the security lives. GitHub's AWS guide gives this condition for an environment ([OIDC in AWS](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws)):

```json
"Condition": {
  "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
    "token.actions.githubusercontent.com:sub": "repo:octo-org/octo-repo:environment:prod"
  }
}
```

The same guide also shows a wildcard form, `"StringLike"` with `repo:octo-org/octo-repo:*`. Read that one as: every branch, every tag and every pull request workflow of the repository may assume the role. Prefer the exact form.

> **Version note.** Older behavior: the subject contains only names, so a deleted and re-registered organization or repository name could mint the same subject. Current behavior: "repositories created after July 15, 2026 now use an immutable default subject format that includes both the owner ID and repository ID", for example `repo:octo-org@123456/octo-repo@456789:ref:refs/heads/main`; renames and transfers after that date switch as well, and existing repositories can opt in. Since: opt-in 23 April 2026, default 15 July 2026 ([changelog](https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/), [reference](https://docs.github.com/en/actions/reference/security/oidc#immutable-subject-claims)). Recommended: check which format your repository issues before writing the trust policy; a policy in the old format will not match a new repository.

Subject customization lets an organization or repository change which claims form the subject, through the REST API's `include_claim_keys` (for example to require `job_workflow_ref`, so that only a particular reusable workflow can obtain the role). The AWS guide notes that custom claims are not supported there, which is why customizing the subject matters on that cloud.

**What OIDC does not do.** It removes the long-lived key. It does not make the job trustworthy. In the TanStack post-mortem's words: "OIDC trusted-publisher binding has no per-publish review. Once configured, any code path in the workflow can mint a publish-capable token." Grant `id-token: write` to one job, bind the subject to an environment with protection rules, and let no untrusted code or cache into that job.

## 21A.11 Caches and artifacts are untrusted input

**In one sentence.** A cache is a shared, unsigned directory keyed by a string; whoever can write an entry under the key your release job computes controls what that job restores.

**Precisely.** "Anyone with read access can create a pull request on a repository and access the contents of a cache", and "cache contents are not signed or verified" ([dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching)). A run can restore caches from its own branch and from the default branch. A `pull_request` run saves to its own merge ref, which other branches cannot restore. A privileged trigger runs in the default branch's context, and that was the opening: the TanStack post-mortem records that "cache writes use a runner-internal token, not the workflow `GITHUB_TOKEN`… Setting `permissions: contents: read` does not block cache mutation."

Two platform changes followed:

| Date | Change |
|---|---|
| 26 June 2026 | Only `push`, `workflow_dispatch`, `repository_dispatch`, `delete`, `registry_package`, `page_build` and `schedule` can create or overwrite caches in the default branch's scope. Other triggers that resolve to it get "read-only access" ([changelog](https://github.blog/changelog/2026-06-26-read-only-actions-cache-for-untrusted-triggers/), [reference](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching#cache-access-for-low-trust-workflow-triggers)) |
| 10 September 2026 | `cache-mode`, at workflow or job level, with the values `read`, `write`, `write-only` and `none`. The job value overrides the workflow value. "Explicitly declaring `cache-mode: write` or `cache-mode: write-only` reintroduces the risk of cache-poisoning" on a low-trust trigger ([changelog](https://github.blog/changelog/2026-09-10-control-github-actions-cache-access-with-cache-mode/), [syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#cache-mode)) |

```yaml
jobs:
  publish:
    cache-mode: none      # a job that holds a publishing identity restores nothing it did not build
```

Setup actions cache implicitly, so check them too: `astral-sh/setup-uv` v10 disables its cache by default for `pull_request_target`, `workflow_run` and `release` events ([release notes](https://github.com/astral-sh/setup-uv/releases/tag/v10.0.0)). Artifacts follow the same rule: "A `workflow_run` workflow should treat artifacts uploaded by other workflows as untrusted data, since their contents can come from a fork" ([securely using pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)).

## 21A.12 Self-hosted runners

**In one sentence.** A self-hosted runner is your machine, on your network, executing whatever the workflow says, and it keeps its state between jobs unless you make it ephemeral.

**Precisely.** "Self-hosted runners should almost never be used for public repositories on GitHub, because any user can open pull requests against the repository and compromise the environment." Private repositories are not exempt: "anyone who can fork the repository and open a pull request (generally those with read access to the repository) are able to compromise the self-hosted runner environment". GitHub-hosted runners are "ephemeral and clean isolated virtual machines"; self-hosted ones "can be persistently compromised by untrusted code in a workflow" ([hardening for self-hosted runners](https://docs.github.com/en/actions/reference/security/secure-use#hardening-for-self-hosted-runners)). The fork approval gate does not help once a contributor is past it: the code "will execute automatically if the user is allowed to bypass approval in the set approval policy or if the pull request is approved" ([repository settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#controlling-changes-from-forks-to-workflows-in-public-repositories)).

The controls, all documented: ephemeral or just-in-time runners that take one job and are removed ([reference](https://docs.github.com/en/actions/reference/runners/self-hosted-runners#ephemeral-runners-for-autoscaling)); runner groups that restrict which repositories may use a runner; the organization setting that restricts or disables repository-level runners ([organization settings](https://docs.github.com/en/organizations/managing-organization-settings/disabling-or-limiting-github-actions-for-your-organization#limiting-the-use-of-self-hosted-runners)); approval for all external contributors. Note also that on self-hosted runners environments do not isolate secrets ([deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments#environment-secrets)). Chapter 20B covers runner operation.

## 21A.13 Environment protection

**In one sentence.** An environment puts a human decision, a branch condition, or both between a job and the secrets and cloud identity that belong to a deployment target.

**Precisely.** "All deployment protection rules must pass before a job referencing the environment is sent to a runner", and environment secrets are available only to jobs that reference the environment, after approval if reviewers are required ([deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments)). For security review, three details matter:

- Referencing a name that does not exist creates an environment with no rules, and "anyone that can edit workflows in the repository can create environments via a workflow file, but only repository admins can configure the environment" ([managing environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)). A typo in the name silently removes the gate.
- Deployment branch rules are evaluated against the ref the run executes on: since 8 December 2025 that is `refs/pull/number/merge` for `pull_request` events and the default branch for `pull_request_target` ([changelog](https://github.blog/changelog/2025-11-07-actions-pull_request_target-and-environment-branch-protections-changes/)).
- Required reviewers and wait timers are plan-gated: on Free, Pro and Team they exist only for public repositories. Chapter 20B has the plan table.

Combined with OIDC, an environment name in the subject means the cloud role can be assumed only by a job that passed that environment's rules.

## 21A.14 Static analysis of workflows

| Tool | Layer | What it finds | Source |
|---|---|---|---|
| CodeQL for workflows | GitHub code scanning; generally available since 22 April 2025; enabled by default setup when workflow files exist on the default branch | "missing required permissions, dangerous inputs without proper validation, and script injection vulnerabilities"; since CodeQL 2.26.4, mutable references to reusable workflows | [changelog](https://github.blog/changelog/2025-04-22-github-actions-workflow-security-analysis-with-codeql-is-now-generally-available/), [changelog](https://github.blog/changelog/2026-09-03-codeql-2-26-4-improves-github-actions-security-detections/) |
| zizmor | Third party; v1.30.1 observed on 1 October 2026 | Audits named `template-injection`, `dangerous-triggers`, `excessive-permissions`, `unpinned-uses`, `cache-poisoning`, `artipacked`, `overprovisioned-secrets`, `secrets-inherit`, `self-hosted-runner`, `dependabot-cooldown` and others | [audits](https://docs.zizmor.sh/audits/) |
| actionlint | Third party; v1.7.12 | Syntax and expression type checks, shellcheck integration, and "script injection by untrusted inputs, hard-coded credentials" | [README](https://github.com/rhysd/actionlint/blob/main/README.md) |
| OpenSSF Scorecard | Third party; results can surface in code scanning | The checks Dangerous-Workflow, Token-Permissions and Pinned-Dependencies | [checks](https://github.com/ossf/scorecard/blob/main/docs/checks.md) |

Neither zizmor nor actionlint is installed in this course's environment, so no output is shown. A scanner finds patterns; it does not know which of your jobs holds the credential that matters. Run one in CI as a required check, and still read the file.

## 21A.15 The platform changes of 2025 and 2026

The dates are sourced. Pairing each change with an incident is the researchers' inference, not GitHub's statement; GitHub's changelog posts do not name the incidents.

| Date | Change | Section |
|---|---|---|
| 22 April 2025 | CodeQL analysis of workflow files generally available | 21A.14 |
| 15 August 2025 | Allowed-actions policy can block entries and require full commit pins | 21A.8 |
| 28 October 2025 | Immutable releases generally available | 21A.7 |
| 8 December 2025 | `pull_request_target` always uses the workflow from the default branch; environment branch rules follow the execution ref | 21A.5, 21A.13 |
| 5 February 2026 | Action allow-listing on all plans | 21A.8 |
| 23 April and 15 July 2026 | Immutable OIDC subject claims: opt-in, then default for new repositories | 21A.10 |
| 18 June and 20 July 2026 | `actions/checkout` v7 refuses fork pull request code under privileged triggers; back-ported | 21A.5 |
| 26 June 2026 | Read-only default-branch cache for low-trust triggers | 21A.11 |
| 14 July 2026 | Dependabot version updates get a default cooldown | 21A.7 |
| 28 July 2026 | Runs "identified as potentially malicious" are held until a collaborator with write access approves them; public repositories only, no configuration ([changelog](https://github.blog/changelog/2026-07-28-github-actions-holds-potentially-malicious-workflows-for-approval/)) | 21A.18 |
| 10 September 2026 | `cache-mode` | 21A.11 |
| 17 September 2026 | Workflow execution protections generally available | 21A.8 |
| **2 November 2026** | The default rule that disables `pull_request_target` in affected public repositories is enforced | 21A.8 |

> **Unverified.** The heuristics behind the holds on suspicious runs are not documented. Do not count on them as a control.

## 21A.16 Workflow 12: a secure-by-default workflow

[`workflows/12-secure.yml`](../workflows/12-secure.yml) puts the controls in one file: a test job, a job that reads the pull request title, a dependency review, and a staging deployment through OIDC. It was assembled from documented syntax and input names and parse-checked; it was not executed on GitHub, and Lab 29.2 has you run it. Read it by asking five questions, which `grep` can answer for any workflow.

<!-- snippet: ch21a/workflow-audit/01-trigger-permissions -->
```text
# Question 1: which events start it? Question 2: what may the token do?
$ grep -n -A4 '^on:' 12-secure.yml
15:on:
16-  pull_request:
17-  push:
18-    branches: [main]
19-
$ grep -n -A2 'permissions:' 12-secure.yml
21:permissions:
22-  contents: read
23-
--
60:    permissions: {}
61-    steps:
62-      - name: Title must not be empty or longer than 72 characters
--
80:    permissions:
81-      contents: read
82-    steps:
--
104:    permissions:
105-      contents: read
106-      id-token: write
```
<!-- /snippet -->

`pull_request`, not `pull_request_target`: fork code runs without secrets. The workflow token is read-only; the title job has none (`{}`); only the deployment job adds `id-token: write`.

<!-- snippet: ch21a/workflow-audit/02-uses -->
```text
# Question 3: whose code runs, and is every reference a full commit ID?
$ grep -n 'uses:' 12-secure.yml
37:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
43:        uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
84:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
89:        uses: actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294 # v5.0.0
114:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
120:        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
# References that are not 40 hexadecimal characters (no output means none):
$ grep -n 'uses:' 12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
[exit status: 1]
```
<!-- /snippet -->

Six references, six commit IDs, all from `workflows/ACTION_PINS.md`. Exit status 1 from the second command means `grep -v` found nothing to print.

<!-- snippet: ch21a/workflow-audit/03-expressions -->
```text
# Question 4: where does an expression appear, and is any of them inside a script?
$ grep -n '${{' 12-secure.yml
26:  group: ${{ github.workflow }}-${{ github.ref }}
27:  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
56:    if: ${{ github.event_name == 'pull_request' }}
66:          PR_TITLE: ${{ github.event.pull_request.title }}
77:    if: ${{ github.event_name == 'pull_request' }}
96:    if: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' && vars.AWS_ROLE_ARN != '' }}
122:          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
123:          aws-region: ${{ vars.AWS_REGION }}
```
<!-- /snippet -->

Classify each line by where the value lands. Lines 26, 27, 56, 77 and 96 are evaluated by Actions and never reach a shell. Lines 122 and 123 are action inputs taken from repository variables, which only people with repository access set. Line 66 is the one untrusted value, and it sits under `env:`. No expression appears inside a script.

<!-- snippet: ch21a/workflow-audit/04-secrets -->
```text
# Question 5: which stored secrets does it read? (no output means none)
$ grep -n 'secrets\.' 12-secure.yml
[exit status: 1]
$ grep -n -B1 -A1 'id-token' 12-secure.yml
105-      contents: read
106:      id-token: write
107-    # Control 8: a job that holds a cloud identity neither restores nor saves a cache.
```
<!-- /snippet -->

The workflow reads no stored secret. Its only credential beyond the job token is the OIDC token of the deployment job.

| Control in the file | Threat it answers | Section |
|---|---|---|
| `permissions: contents: read` at the top; `{}` and per-job additions below | A compromised step using a write token | 21A.3 |
| `on: pull_request` | Fork code running next to secrets | 21A.4, 21A.5 |
| Every `uses:` is a commit ID with a version comment | A moved tag | 21A.7 |
| `persist-credentials: false` on every checkout | Later steps using the token through Git | 21A.3 |
| The title only under `env:` | Script injection | 21A.6 |
| The deployment `if:` requires a push to `main` | Unreviewed code reaching the cloud identity | 21A.10 |
| `environment: staging` | A deployment without the environment's rules; it also fixes the OIDC subject | 21A.13 |
| `id-token: write` on one job only | Any other job requesting a cloud token | 21A.10 |
| `cache-mode: none` on the deployment job | A poisoned cache executing next to the cloud identity | 21A.11 |
| `timeout-minutes` and `concurrency` | Runaway or overlapping runs | Chapter 20B |

What it does not do: it does not attest the build, it does not scan itself (add CodeQL default setup), and the staging role's trust policy lives in the cloud account, where the workflow cannot enforce it.

## 21A.17 AI agents inside workflows

An agent in a workflow (an LLM reviewer, a triage bot, a coding agent) combines parts 3 and 4 of the model in a new form: it reads attacker-controlled text and holds credentials, and for an agent, text is instruction. No `env:` trick separates data from code in a prompt.

Two findings from the report. An automated account ran a week-long campaign in February and March 2026 that combined `pull_request_target` abuse, branch-name and filename injection, and prompt injection against an AI reviewer ([StepSecurity](https://www.stepsecurity.io/blog/hackerbot-claw-github-actions-exploitation)). And researchers reported in April 2026 that AI coding agents run as GitHub Actions could be steered by text in pull request titles, issue bodies or comments into revealing CI secrets ([Techzine](https://www.techzine.eu/news/security/140524/ai-agents-on-github-leak-api-keys-via-prompt-injection/)); this is secondary reporting only, and the primary write-up was not fetched.

The report's recommendation, labelled there as an inference: an agent in a workflow gets a dedicated low-privilege, spend-capped key; no write token unless required; and it does not run automatically on untrusted contributions. In this chapter's terms: give the agent's job `permissions` as if the pull request author had written the job, because through the prompt they partly did.

## 21A.18 Case studies

Each case is given as what happened, root cause, lesson, from the Phase 0 report and its sources. Flags from the report are carried in the last column. No GitHub output or attack detail beyond the published summaries is reproduced.

| Incident | What happened | Root cause | Lesson | Flags |
|---|---|---|---|---|
| tj-actions/changed-files, March 2025 ([CISA](https://www.cisa.gov/news-events/alerts/2025/03/18/supply-chain-compromise-third-party-tj-actionschanged-files-cve-2025-30066-and-reviewdogaction), [advisory](https://github.com/advisories/GHSA-mrrh-fwg8-r2c3)) | Version tags were repointed to a malicious commit that printed secrets from runner memory into workflow logs; more than 23,000 repositories used the action | A stolen bot token; the chain began with a `pull_request_target` flaw in an upstream project ([Unit 42](https://unit42.paloaltonetworks.com/github-actions-supply-chain-attack/)) | Tags are mutable; only commit-pinned workflows were unaffected; public logs are world-readable | **Conflict:** CISA gives the window as 12 March 00:00 UTC to 15 March 12:00 UTC 2025, the advisory says 14 to 15 March, Unit 42 places the mass tag override at 14 March 16:57 UTC. Use CISA's window for audits. How many repositories leaked secrets is not stated by either; a "218 repositories" figure is secondary and unverified |
| Nx "s1ngularity", August 2025 ([post-mortem](https://nx.dev/blog/s1ngularity-postmortem)) | Malicious versions of eight packages were live for about four hours and harvested developer credentials | A `pull_request_target` workflow that echoed an unsanitised pull request title; a legacy read-write default token; a publish workflow that could be dispatched | One injectable line plus a write token reaches a publish credential | None |
| GhostAction, September 2025 ([GitGuardian](https://blog.gitguardian.com/ghostaction-campaign-3-325-secrets-stolen/)) | Compromised maintainer accounts pushed a workflow that sent secrets to an attacker's server: 3,325 secrets from 817 repositories | Write access equals secret access | Protect workflow files with code-owner review; prefer environment-scoped secrets and OIDC | Vendor report |
| Shai-Hulud and its sequel, September and November 2025 ([GitHub Blog](https://github.blog/security/supply-chain-security/our-plan-for-a-more-secure-npm-supply-chain/), [Wiz](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack)) | A self-replicating npm worm stole tokens, pushed secret-dumping workflows, and in its second wave registered infected machines as self-hosted runners | Stolen developer and CI tokens | A token with workflow write access is equivalent to every secret it can reach; monitor for new workflows, runners and repositories | The size of the second wave is approximate: the notes cite the same Wiz post for about 700 malicious versions and about 800 packages |
| PyTorch runners (disclosed January 2024) and Ultralytics (December 2024) ([researcher write-up](https://johnstawinski.com/2024/01/11/playing-with-fire-how-we-executed-a-critical-supply-chain-attack-on-pytorch/), [PyPI](https://blog.pypi.org/posts/2024-12-11-ultralytics-attack-analysis/)) | Persistent self-hosted runners on a public ML repository could be reached by a pull request; a poisoned Actions cache led to malicious PyPI releases published through the legitimate workflow | Self-hosted runners with weak approval settings; an insecure trigger plus cache trust | ML projects are prime targets; use ephemeral runners and treat caches as untrusted | PyTorch is a researcher disclosure, not an observed attack |
| Trivy and LiteLLM, February to March 2026 ([advisory](https://github.com/advisories/GHSA-69fq-xp46-6x23), [Aqua notice](https://github.com/aquasecurity/trivy/discussions/10425), [Datadog](https://securitylabs.datadoghq.com/articles/litellm-compromised-pypi-teampcp-supply-chain-campaign/)) | A `pull_request_target` flaw leaked a token; weeks later a malicious scanner release was published and almost all action tags were force-pushed to malicious commits; a downstream LLM gateway library that ran the scanner unpinned had its publishing credential stolen, and two malicious versions were on PyPI for about three hours | Incomplete, non-atomic credential rotation after the first incident; tag-pinned security tooling | Rotate everything at once; security tools in CI are high-value targets; pin by commit | **Conflict:** 75 of 76 tags (Wiz) versus 76 of 77 (Datadog); write-ups name the account behind the first exploit differently. Use the advisory and the vendor notice for exact figures |
| TanStack, 11 May 2026 ([post-mortem](https://tanstack.com/blog/npm-supply-chain-compromise-postmortem)) | 84 malicious versions of 42 packages were published through the project's own trusted-publisher identity; no npm token was stolen | A `pull_request_target` workflow built fork code; the fork poisoned the shared cache; the release job restored it; malware read the job's OIDC token from runner memory | Read-only `permissions` did not block cache writes; OIDC is not safe if untrusted code runs in the job; `pull_request_target` bypassed the first-time-contributor gate | Whether the versions carried valid provenance attestations, and the "Mini Shai-Hulud" name, come from secondary reports; the post-mortem does not say so. No GitHub-authored post-mortem was found |
| Codecov, 2021 ([Codecov](https://about.codecov.io/security-update/)) | A modified uploader script exported CI environment variables for two months | A mutable script fetched and executed in CI | Remote scripts are the same risk class as mutable tags | History only |

A further tag hijack, of the actions-cool actions in May 2026, is known to this course only through secondary reporting ([The Hacker News](https://thehackernews.com/2026/05/github-actions-supply-chain-attack.html)); it is mentioned for completeness and nothing is built on it.

Three patterns recur. Mutable references were repointed after a maintainer credential was stolen (tj-actions, Trivy). A privileged trigger ran or interpolated outsider input (the upstream of tj-actions, Nx, Trivy, TanStack). Stolen tokens were used to push workflows (GhostAction, Shai-Hulud). And one technique recurs across them: reading the runner process's memory to collect secrets and OIDC tokens. The report's conclusion is the sentence to carry into a design review: masked logs are irrelevant once attacker code runs in a job; "the robust controls are preventing untrusted code from running in privileged jobs and limiting which secrets a job holds."

## 21A.19 A review checklist for workflow pull requests

Use it on every pull request that touches `.github/workflows/`, an action definition, or a script that a workflow runs. Lab 29.3 applies it.

1. **Trigger.** Does the change add or keep `pull_request_target`, `workflow_run`, `issue_comment`, `issues` or `discussion`? If so, which outsider-controlled input reaches the job?
2. **Checkout.** Any `ref:` or `repository:` taken from the event? Any `allow-unsafe-pr-checkout`? Any `git fetch` or `gh pr checkout` of pull request code in a privileged job?
3. **Permissions.** Is there a top-level `permissions` block, read-only? Is each `write` scope on the one job that needs it? Did the change widen anything?
4. **Expressions.** Is there any `${{ }}` inside `run:`, or inside an input that is evaluated as code? Including multi-line scripts?
5. **Actions.** Is every `uses:` a 40-character commit ID from the action's own repository, with a version comment? Is a new action necessary, and who maintains it?
6. **Remote code.** Any download piped into a shell, or an installer fetched without a checksum?
7. **Secrets.** Is each secret referenced in the narrowest place: one step, in a job behind an environment? Could OIDC replace it? Does any secret appear on a command line?
8. **Privileged jobs.** For each job that publishes, deploys or holds `id-token: write`: does it run only on trusted refs, behind an environment, with `cache-mode: none` or `read`, and with no artifact from an untrusted run executed?
9. **Runner.** Did `runs-on` change to a self-hosted label? For which events?
10. **Credentials in Git.** `persist-credentials: false` wherever the job does not push?
11. **Process.** Was the change reviewed by a code owner of `.github/workflows/`, and does a ruleset require that? Does a workflow scanner run on the pull request?

## 21A.20 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A step fails with "Resource not accessible by integration" after you add `permissions` | Naming one scope set the others to `none` | Add the missing scope to that job only | Decide scopes per job when the job is written |
| CI works for the team and fails for outside contributors | The job needs a secret; fork runs get none | Split secret-dependent work out of pull request CI (section 21A.5) | Design pull request CI to need no secrets |
| A public repository's `pull_request_target` workflow stops running after 2 November 2026 | The default event rule is enforced | Migrate to `pull_request`, or allow the event explicitly after review | Review the evaluate-mode insights before the date |
| The cloud rejects the OIDC token | The subject does not match the trust policy: wrong environment or branch, or the immutable format | Compare the token's `sub` with the policy | Keep trust policies in code, next to the workflow |
| A secret appears in a log | Redaction is not guaranteed | Delete the log and rotate the secret | Keep secrets out of jobs that print untrusted data |
| An unknown workflow file or runner appears | A token with write access was used | Chapter 21B: contain, rotate everything at once | Code-owner rule on workflows; audit log alerts |

## 21A.21 When not to use it, and dangerous edge cases

- **`pull_request_target`:** not for building, testing or linting. If you cannot state why the job needs a write token or a secret, it does not need the trigger.
- **Self-hosted runners:** not for public repositories, and not persistent ones for anything a pull request can reach.
- **`secrets: inherit` and workflow-level `env:` secrets:** not when any job in scope runs third-party code.
- **The edge case behind most incidents:** two safe-looking workflows that share something. A low-privilege workflow that can write a cache, an artifact, a label or a branch, and a high-privilege workflow that trusts it. Review workflows as a set.

## 21A.22 Command safety

Editing workflow files is ordinary Git work; the risk lies in what the files do once pushed.

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git ls-remote --tags <url>` | 🟢 SAFE | Nothing; lists a remote's tags | Not needed | Not needed |
| `grep -n 'uses:' .github/workflows/*.yml` | 🟢 SAFE | Nothing | Not needed | Not needed |
| `git tag -f -a v1` | 🟡 CAUTION | Moves a local tag | `git rev-parse 'v1^{commit}'` | Re-create the tag at the old commit |
| `git push --force origin v1` | 🔴 DANGEROUS | Replaces a published tag (section 21A.7) | `git ls-remote --tags origin v1` | Push the old tag object back, if you still have it |
| Pushing a change under `.github/workflows/` | 🟡 CAUTION | Git: an ordinary commit. GitHub Actions: the next matching event runs the new file with the repository's token and secrets | Review the diff with section 21A.19 | Revert the commit; rotate any secret the changed workflow could read |

## 21A.23 Version notes

Section 21A.15 lists every dated change. The four that change how you write a workflow:

| Topic | Older | Current | Since | Recommended |
|---|---|---|---|---|
| Default token | Read and write | Read-only for new repositories and organizations | 2 February 2023 | Declare `permissions` in every workflow |
| Checkout of fork code under privileged triggers | Allowed | Refused without an explicit flag | checkout v7, 18 June 2026 | Never set the flag for code that runs |
| Default-branch cache | Writable by any run in its scope | Read-only for low-trust triggers; `cache-mode` | 26 June and 10 September 2026 | `cache-mode: none` or `read` in release jobs |
| `pull_request_target` in public repositories | Runs | Blocked by a default rule unless allowed | Enforced 2 November 2026 | Decide per workflow before that date |

> **Outdated advice.** "Use `pull_request_target` so that CI works for forks" and "pin to the major tag so that you get fixes automatically" are both still common in tutorials. The first is the pattern behind most of section 21A.18. The second is the tj-actions incident.

## 21A.24 Practice

Do the [Module 29 labs](../lab-manual/m29-actions-security.md): Lab 29.1 (five planted weaknesses in `workflows/vulnerable/`), Lab 29.2 (justify each control of workflow 12), Lab 29.3 (review a pull request diff). Then re-read [Chapter 19](ch19-codeowners.md), section 19.8, and add a code-owner line for `.github/workflows/` to your practice repository. Chapter 21B continues with repository security and the response to a leaked secret.

## 21A.25 Interview questions

1. A workflow has no `permissions` key. What can its token do, and what does the answer depend on?
2. Why does a fork pull request under `pull_request` not receive secrets, and what remains exposed anyway?
3. Explain a "pwn request" without using the word. Which step completes the vulnerability?
4. Why does moving `${{ github.event.pull_request.title }}` from `run:` to `env:` fix an injection, when the same value still reaches the same shell?
5. Your team pins every action to a commit. Name three things that this does not protect against.
6. What does `id-token: write` grant, and where is the access decision made?
7. In the TanStack incident no credential was stolen from storage. Walk through how a fork pull request led to a publish, and name the control that would have broken each link.
8. A colleague says "the secret is masked in the logs, so it is safe". Respond.
9. When is `pull_request_target` the right trigger, and what changes on 2 November 2026?
10. Why are self-hosted runners and public repositories a dangerous combination, and what makes ML projects particularly exposed?
11. How would you give an LLM review agent access to pull requests from outside contributors?
12. You may enable one organization-level control today. Which one, and why?

## 21A.26 Sources

**Primary sources**

- GitHub Docs: [secure use reference](https://docs.github.com/en/actions/reference/security/secure-use); [securely using pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target); [script injections](https://docs.github.com/en/actions/concepts/security/script-injections); [GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token); [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax); [OIDC reference](https://docs.github.com/en/actions/reference/security/oidc); [OIDC in AWS](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws); [dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching); [secrets reference](https://docs.github.com/en/actions/reference/security/secrets); [managing GitHub Actions settings for a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository); [about Actions policies](https://docs.github.com/en/actions/concepts/about-actions-policies); [keeping your actions up to date with Dependabot](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot).
- GitHub changelog entries, linked where each change is described (sections 21A.3, 21A.5, 21A.7, 21A.8, 21A.10, 21A.11, 21A.15).
- [actions/checkout README at v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md).
- Advisories and post-mortems: [CISA on tj-actions](https://www.cisa.gov/news-events/alerts/2025/03/18/supply-chain-compromise-third-party-tj-actionschanged-files-cve-2025-30066-and-reviewdogaction); [GHSA-mrrh-fwg8-r2c3](https://github.com/advisories/GHSA-mrrh-fwg8-r2c3); [Nx post-mortem](https://nx.dev/blog/s1ngularity-postmortem); [GHSA-69fq-xp46-6x23](https://github.com/advisories/GHSA-69fq-xp46-6x23); [Aqua incident notice](https://github.com/aquasecurity/trivy/discussions/10425); [TanStack post-mortem](https://tanstack.com/blog/npm-supply-chain-compromise-postmortem); [PyPI on Ultralytics](https://blog.pypi.org/posts/2024-12-11-ultralytics-attack-analysis/); [Codecov security update](https://about.codecov.io/security-update/).

**Secondary sources**

- [GitHub Security Lab: preventing pwn requests](https://securitylab.github.com/resources/github-actions-preventing-pwn-requests/) (2021; parts 2 to 4 of the series were not consulted).
- Vendor and researcher analyses: [Unit 42](https://unit42.paloaltonetworks.com/github-actions-supply-chain-attack/); [GitGuardian on GhostAction](https://blog.gitguardian.com/ghostaction-campaign-3-325-secrets-stolen/); [Wiz on Shai-Hulud 2.0](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack); [Datadog Security Labs](https://securitylabs.datadoghq.com/articles/litellm-compromised-pypi-teampcp-supply-chain-campaign/); [StepSecurity on hackerbot-claw](https://www.stepsecurity.io/blog/hackerbot-claw-github-actions-exploitation); [John Stawinski on PyTorch](https://johnstawinski.com/2024/01/11/playing-with-fire-how-we-executed-a-critical-supply-chain-attack-on-pytorch/).
- Secondary reporting only: [Techzine](https://www.techzine.eu/news/security/140524/ai-agents-on-github-leak-api-keys-via-prompt-injection/); [The Hacker News](https://thehackernews.com/2026/05/github-actions-supply-chain-attack.html).
- Tools: [zizmor audits](https://docs.zizmor.sh/audits/); [actionlint](https://github.com/rhysd/actionlint/blob/main/README.md); [OpenSSF Scorecard checks](https://github.com/ossf/scorecard/blob/main/docs/checks.md).

**Videos** (from the Phase 0 report, with its caveats)

- [Adnan Khan, "The dark side of GitHub Actions"](https://www.youtube.com/watch?v=76NEylOsOS0), RomHack 2024, 53 min. The vulnerability classes are current; GitHub defaults have changed since.
- [Niek Palm, "Beyond the Commit: Weaponizing and Hardening GitHub Actions"](https://www.youtube.com/watch?v=19l6sLyR3zo), NDC Security 2026, 55 min. The most current defender-oriented talk; it pre-dates the June to September 2026 platform changes.
- ["Tag, You're Leaked: Surviving the tj-actions Supply Chain Attack"](https://www.youtube.com/watch?v=FxHIaRwc9c4), BSides PDX 2025, 24 min. An incident-response case study.

**Further reading**

- [GitHub's 2026 security roadmap for Actions](https://github.blog/news-insights/product-news/whats-coming-to-our-github-actions-2026-security-roadmap/): announced work, not shipped features.
- `workflows/ACTION_PINS.md` in this course: the pins and how to re-verify them.
