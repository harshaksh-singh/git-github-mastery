# V140: The GitHub CLI, gh pr, gh api, the REST API and GraphQL, rate limits, webhooks and GitHub Apps

- **Part.** 5: GitHub
- **Module.** 25
- **Planned minutes.** 26
- **Prerequisites.** V127, V134
- **Textbook sections.** [Chapter 15](../../textbook/ch15-github.md), sections 15.16 to 15.18 and 15.20 to 15.22; [Chapter 17](../../textbook/ch17-pull-requests.md), section 17.16
- **Demo scripts.** `labs/ch15/gh-help.sh`, `labs/ch15/jq-rehearsal.sh`, `labs/ch15/lab-25-1-feature-cycle.sh`, `labs/ch15/lab-25-2-api-queries.sh`, then a screen walkthrough of Lab 25.1 in [`lab-manual/m25-github-cli-api.md`](../../lab-manual/m25-github-cli-api.md)

## HOOK

**[ON SCREEN]** Two lines. "The report says every repository has exactly 30 open pull requests." "And on Tuesday the script opened an issue in the production repository."

Both come from one script, written in an afternoon, that calls `gh api` in a loop. Nobody intended either result. The first is a default of the API. The second is a default of the CLI: one flag changed the HTTP method without the author noticing.

If you are going to automate anything on GitHub, and on an AI/ML team you will, you need to know what the CLI does on your behalf. This video gives you that, and the two defaults behind those two lines.

## INTRODUCTION

Through Part 5 you have used `gh` in almost every lab without a formal introduction. This video is that introduction, and it closes the GitHub part before the gate.

Four topics. First, what `gh` is: a client of GitHub's API that knows which repository you are in. Second, `gh pr`: a full pull request cycle from the terminal, and which of its commands change state. Third, `gh api`: the REST API, its method, fields, pagination and version header, then GraphQL at concept level, and rate limits. Fourth, the integration model: webhooks and GitHub Apps, and when an integration should be an App and not your personal token.

A word on evidence. The authors captured no GitHub output. The local replays show two things only: the `--help` output of the installed CLI, version 2.88.1, and the `jq` program run on a stored practice document. Everything else is described from the documentation and performed by you on your practice repository.

## LEARNING OBJECTIVES

After this video you can:

- drive a complete feature cycle from the terminal with `gh`;
- say which `gh` commands change state and which only read;
- query pull request and ruleset data with `gh api` and shape the result with a jq filter;
- explain REST API versioning, pagination and rate limits as the section gives them;
- say when an integration should be a GitHub App.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub.

**In one sentence.** `gh` is a client for GitHub's API that knows which repository you are in, so the GitHub objects become reachable from the directory where your Git data is.

**Precisely.** `gh` is not Git and does not replace it. It calls the REST and GraphQL APIs with a stored token. It runs `git` for you where a task needs both, as in `gh repo clone` and `gh pr checkout`. And it can act as Git's credential helper.

Four behaviors explain most surprises.

Which repository? Inside a clone, `gh` picks the repository from your remotes. With a fork there are two candidates, and `gh repo set-default` records which one to use. Outside a clone, or to override, you pass `-R` with owner and repository, or set `GH_REPO`.

Machine-readable output. Most listing commands take `--json` with a list of fields, then `--jq` with an expression, or `--template`. `--json` without a field list prints the available fields.

Exit codes. 0 for success, 1 for failure, 2 when cancelled, 4 when authentication is required. `gh pr checks` adds 8 for pending checks. Scripts should test exit codes and not parse human-readable output.

Its own token. `GH_TOKEN` in the environment takes precedence over the stored login. A stale one in a shell profile explains "gh works in one terminal and not in another".

**`gh pr`.** In one sentence: `gh pr` drives the pull request object from the terminal; the Git work around it stays with `git`.

**[ON SCREEN]** The command block of section 17.16, in four groups: create, inspect, review and iterate, finish.

```bash
gh pr create --base main --title "Accept tickets without a subject" --body "Fixes #12"
gh pr view 12 --json baseRefName,headRefOid,mergeable,mergeStateStatus,reviewDecision
gh pr checks 12 --required                  # exit status 8 while checks are pending
gh pr checkout 12                           # local branch for the head of pull request 12
gh pr merge 12 --squash --delete-branch
gh pr merge 12 --merge --match-head-commit "$(git rev-parse HEAD)"
```

Every flag was checked against the help of version 2.88.1. None was run against GitHub by the authors.

Now the labels, because this is the objective people skip. `gh pr view`, `gh pr checks`, `gh pr diff` and `gh pr status` read: 🟢 SAFE. `gh pr checkout` is 🟢 SAFE too; it changes local files and refs only. `gh pr create` is 🟡 CAUTION: it may push the branch, and it creates a GitHub object that notifies people; the preview is `--dry-run`, and the textbook notes that even the dry run may still push. `gh pr merge`, `gh pr update-branch` and `gh pr edit --base` are 🟡 CAUTION: they write to the base branch, move the head branch or change the base, and they can dismiss approvals.

One flag is 🔴 DANGEROUS: `gh pr merge --admin`. What it changes: the base branch, without the required reviews or checks. What it can destroy: no data; what is lost is the review and the checks that the rules required. Preview: `gh pr checks --required`. Recovery: `gh pr revert`, and record the reason. Appropriate: a documented emergency, by someone the bypass list names.

Two details from the help text. `gh pr create` takes the base from `--base`, else from a Git configuration value for the current branch, else the default branch. And `--match-head-commit` merges only if the head is the given commit: you merge what you reviewed, and not what was pushed a second ago.

**`gh api`.** In one sentence: everything GitHub shows you comes from an API that you can call yourself; `gh api` adds your token, the host and the placeholders, and prints the JSON.

The REST API is a set of URLs, one per resource. `gh api` takes the path and fills in the placeholders for owner, repository and branch from the current repository.

```bash
gh api repos/{owner}/{repo} --jq '{full_name, default_branch, visibility, fork}'
gh api repos/{owner}/{repo}/pulls --jq '.[] | "#\(.number) \(.title)"'
gh api repos/{owner}/{repo}/rulesets --jq '.[] | "\(.id) \(.name) \(.enforcement)"'
gh api rate_limit --jq '.resources.core'
gh api -H 'X-GitHub-Api-Version: 2026-03-10' repos/{owner}/{repo}/pulls --paginate --jq '.[].number'
```

The paths and field names were checked against the REST reference on 2 October 2026. The commands were not run.

Five rules of the road.

Method. `GET` by default, and `POST` as soon as you add a field with `-f` or `-F`. To send parameters with a `GET`, you say `-X GET`. That is the second line of the hook: a filter parameter turned a read into a create.

Fields. `-f` sends a string. `-F` converts `true`, `false`, `null` and integers to JSON types and can read a file.

Pagination. Lists return 30 items per page unless you ask otherwise. `--paginate` follows the pages; `--slurp` wraps them into one array. That is the first line of the hook.

Versioning. The REST API is versioned by date through the `X-GitHub-Api-Version` header. Without the header, a request gets version `2022-11-28`, which is supported until 10 March 2028. `2026-03-10` is the first version with breaking changes. An unsupported version answers `410 Gone`. The CLI pins its own REST calls to `2022-11-28` since version 2.87.0. In a script that must keep working, send the header explicitly.

Not found means "not for you". For a private resource and a token without access, the API answers `404`, not `403`, in the documentation's words "to avoid confirming the existence of private repositories".

Every `gh api` call with `GET` is 🟢 SAFE. Every call with `POST`, `PATCH`, `PUT` or `DELETE`, and every GraphQL mutation, is 🔴 DANGEROUS, and section 15.22 gives the reason in one line: it changes whatever the endpoint says, with all your permissions. The preview is always the `GET` first. The recovery depends on the endpoint, and often there is none.

**GraphQL** is the second API: one endpoint, a typed schema, and a query that names exactly the fields wanted, so one call can replace several REST requests. `gh api graphql -f query=` followed by the query calls it. A GraphQL query only reads, although it is sent as a `POST`. Some features exist in only one of the two APIs.

**Rate limits.** With no authentication: 60 requests per hour, per IP address. An authenticated user, which is your token and `gh`: 5,000 per hour. A GitHub App installation: 5,000 per hour at minimum, 15,000 on Enterprise Cloud organizations. The `GITHUB_TOKEN` in a workflow: 1,000 requests per hour per repository. Secondary limits apply on top: at most 100 concurrent requests, and a points budget per minute. Exceeding a limit returns `403` or `429`. So a `403` is not always a permission problem. `gh api rate_limit` tells you where you stand.

**Webhooks and GitHub Apps.** Polling asks GitHub repeatedly whether something happened. A webhook reverses the direction: you register a URL and the events you care about, and GitHub sends an HTTP request with a JSON payload when one occurs. A `push` webhook carries the ref and the commit IDs before and after the push. The textbook's remark is worth repeating: that is the information of a reflog line, delivered to your server.

A GitHub App is the identity an integration should have. It is installed on chosen repositories. It holds fine-grained permissions. It receives webhooks. It acts with installation tokens that expire after one hour. And it is not tied to a person, so it does not stop working when someone leaves. The alternatives are a personal token, which acts as you everywhere you have access, and a machine user. One fact for tool writers: the API for check runs and check suites is available only to GitHub Apps; the older commit statuses can be created with Write access.

**[ON SCREEN]** Callout: Unverified. Webhook delivery retries and signature validation were not researched for the Phase 0 report, and are not described in the course.

## MENTAL MODEL

There is one API. Everything else is a client.

The browser is a client. `gh` is a client. A script with `curl` is a client. A GitHub App is a client. What differs between them is the credential each presents, and therefore what each may do and how often.

So for any automation question, ask three things in this order. Which endpoint am I calling, and with which method? Which credential is making the call, and what else can that credential do? And what happens to this automation when the person who wrote it changes teams?

The model breaks slightly for `gh`, because `gh` is two clients in one. It talks to the API, and it also runs `git` on your machine. `gh pr checkout` creates a local branch. `gh pr create` may push. When you read a `gh` command, split it in your head into the part that touches Git data and the part that touches GitHub objects.

## DIAGRAM

**[DIAGRAM]** Draw the API box on the right first. Then the three clients on the left, one at a time, and write the credential on each arrow before the client's name.

```text
   client                         credential it presents                    one API
   ------                         ----------------------                    -------
   +-------------+
   | the browser | ---- your signed-in session ------------------------+
   +-------------+                                                     |
                                                                       v
   +-------------+      your stored token (or GH_TOKEN),       +----------------+
   | gh          | ---- acts as you, everywhere you have ----> | GitHub's API   |
   | (also runs  |      access; 5,000 requests per hour        | REST + GraphQL |
   |  git)       |                                             +----------------+
   +-------------+                                                     ^
                                                                       |
   +-------------+      installation token: chosen repositories,       |
   | GitHub App  | ---- fine-grained permissions, expires after -------+
   |             |      one hour; not tied to a person
   +-------------+ <--- webhooks: GitHub calls the App when an event occurs
```

**[DIAGRAM]** The last arrow points the other way. Only the App is called by GitHub. The other two can only ask.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch15/gh-help`. This replay calls `gh` with `--help` only. It is marked volatile because it depends on the installed CLI version: this is gh 2.88.1.

**Step 1: the families.**

```bash
gh --help
```

<!-- snippet: ch15/gh-help/01-families -->
```text
$ gh --help | sed -n '/^CORE COMMANDS/,/^HELP TOPICS/p' | sed '$d'
CORE COMMANDS
  auth:          Authenticate gh and git with GitHub
  browse:        Open repositories, issues, pull requests, and more in the browser
  codespace:     Connect to and manage codespaces
  gist:          Manage gists
  issue:         Manage issues
  org:           Manage organizations
  pr:            Manage pull requests
  project:       Work with GitHub Projects.
  release:       Manage releases
  repo:          Manage repositories

GITHUB ACTIONS COMMANDS
  cache:         Manage GitHub Actions caches
  run:           View details about workflow runs
  workflow:      View details about GitHub Actions workflows

ALIAS COMMANDS
  co:            Alias for "pr checkout"

ADDITIONAL COMMANDS
  agent-task:    Work with agent tasks (preview)
  alias:         Create command shortcuts
  api:           Make an authenticated GitHub API request
  attestation:   Work with artifact attestations
  completion:    Generate shell completion scripts
  config:        Manage configuration for gh
  copilot:       Run the GitHub Copilot CLI (preview)
  extension:     Manage gh extensions
  gpg-key:       Manage GPG keys
  label:         Manage labels
  licenses:      View third-party license information
  preview:       Execute previews for gh features
  ruleset:       View info about repo rulesets
  search:        Search for repositories, issues, and pull requests
  secret:        Manage GitHub secrets
  ssh-key:       Manage SSH keys
  status:        Print information about relevant issues, pull requests, and notifications across repositories
  variable:      Manage GitHub Actions variables
```
<!-- /snippet -->

Find four lines. `pr`, where you will spend most of your time. `api`, the one command that reaches everything else. `ruleset`, described as "View info", which you met in V134. And under the Actions heading, `run` and `workflow`, which belong to the next part of the course.

**Step 2: the release command explains itself.**

<!-- snippet: ch15/gh-help/02-release-create -->
```text
$ gh release create --help | sed -n '/^If a matching git tag/,/^If the tag is not annotated/p'
If a matching git tag does not yet exist, one will automatically get created
from the latest state of the default branch.
Use `--target` to point to a different branch or commit for the automatic tag creation.
Use `--verify-tag` to abort the release if the tag doesn't already exist.
To fetch the new tag locally after the release, do `git fetch --tags origin`.

To create a release from an annotated git tag, first create one locally with
git, push the tag to GitHub, then run this command.
Use `--notes-from-tag` to get the release notes from the annotated git tag.
If the tag is not annotated, the commit message will be used instead.
$ gh release create --help | grep -E -- '--(verify-tag|target|notes-from-tag|generate-notes|draft|prerelease) '
  -d, --draft                        Save the release as a draft instead of publishing it
      --generate-notes               Automatically generate title and notes for the release via GitHub Release Notes API
      --notes-from-tag               Fetch notes from the tag annotation or message of commit associated with tag
  -p, --prerelease                   Mark the release as a prerelease
      --target branch                Target branch or full commit SHA (default [main branch])
      --verify-tag                   Abort in case the git tag doesn't already exist in the remote repository
$ gh release delete --help | grep -- '--cleanup-tag'
      --cleanup-tag   Delete the specified tag in addition to its release
```
<!-- /snippet -->

Read the first sentence of the help text aloud: if a matching Git tag does not yet exist, one will automatically get created from the latest state of the default branch. That is why section 15.22 labels `gh release create` without `--verify-tag` as 🔴 DANGEROUS, and with `--verify-tag --draft` as 🟡 CAUTION. The textbook's production case: a release script on the day the version variable holds a typo. `--verify-tag` turns that into an error before anything is created.

**Step 3: the flags of `gh api`.**

```bash
gh api --help
```

**[PAUSE]** Before the output: which flag's default is "GET", and which two flags will change that default without mentioning it?

<!-- snippet: ch15/gh-help/03-api-flags -->
```text
$ gh api --help | sed -n '/^FLAGS/,/^INHERITED FLAGS/p' | sed '$d'
FLAGS
      --cache duration        Cache the response, e.g. "3600s", "60m", "1h"
  -F, --field key=value       Add a typed parameter in key=value format (use "@<path>" or "@-" to read value from file or stdin)
  -H, --header key:value      Add a HTTP request header in key:value format
      --hostname string       The GitHub hostname for the request (default "github.com")
  -i, --include               Include HTTP response status line and headers in the output
      --input file            The file to use as body for the HTTP request (use "-" to read from standard input)
  -q, --jq string             Query to select values from the response using jq syntax
  -X, --method string         The HTTP method for the request (default "GET")
      --paginate              Make additional HTTP requests to fetch all pages of results
  -p, --preview strings       Opt into GitHub API previews (names should omit '-preview')
  -f, --raw-field key=value   Add a string parameter in key=value format
      --silent                Do not print the response body
      --slurp                 Use with "--paginate" to return an array of all pages of either JSON arrays or objects
  -t, --template string       Format JSON output using a Go template; see "gh help formatting"
      --verbose               Include full HTTP request and response in the output
```
<!-- /snippet -->

`--method` says default "GET". `--field` and `--raw-field` add parameters. And `--paginate` says what it does in plain words: make additional HTTP requests to fetch all pages of results.

<!-- snippet: ch15/gh-help/04-ruleset -->
```text
$ gh ruleset --help | sed -n '/^AVAILABLE COMMANDS/,/^FLAGS/p' | sed '$d'
AVAILABLE COMMANDS
  check:         View rules that would apply to a given branch
  list:          List rulesets for a repository or organization
  view:          View information about a ruleset
```
<!-- /snippet -->

Three subcommands: check, list, view. No create, no edit.

**Step 4: rehearse the filters offline.** Replay `labs/run ch15/jq-rehearsal`. The input is a practice document written for the course, with the field names of the pull request list. It is not output from GitHub.

```bash
jq '.[].title' pulls-sample.json
jq -r '.[].title' pulls-sample.json
```

<!-- snippet: ch15/jq-rehearsal/01-one-field -->
```text
$ jq '.[].title' pulls-sample.json
"Add names() to list registered prompts"
"Persist versions to SQLite"
"Backport: reject empty prompt names"
$ jq -r '.[].title' pulls-sample.json
Add names() to list registered prompts
Persist versions to SQLite
Backport: reject empty prompt names
```
<!-- /snippet -->

`.[]` iterates over the array. `-r` prints strings without quotes. With `gh api`, the same filter goes after `--jq` and no `-r` is needed.

<!-- snippet: ch15/jq-rehearsal/02-several-fields -->
```text
$ jq -r '.[] | "#\(.number)  \(.user.login)  \(.head.ref) -> \(.base.ref)"' pulls-sample.json
#14  asha-rao  feature/list-names -> main
#15  ravi-menon  feature/sqlite-store -> main
#16  asha-rao  backport/empty-names -> release/0.1
```
<!-- /snippet -->

The backslash-parenthesis form interpolates a field into a string. Three pull requests, two authors, two base branches.

```bash
jq -r '.[] | select(.draft | not) | select(.base.ref == "main") | .number' pulls-sample.json
```

**[PAUSE]** Three pull requests. One is a draft, one targets a release branch. Which number is printed?

<!-- snippet: ch15/jq-rehearsal/03-select -->
```text
$ jq -r '.[] | select(.draft | not) | select(.base.ref == "main") | .number' pulls-sample.json
14
$ jq '[.[] | select(.user.login == "asha-rao")] | length' pulls-sample.json
2
```
<!-- /snippet -->

`select` keeps the elements for which the condition holds. Only number 14 is ready and targets `main`.

<!-- snippet: ch15/jq-rehearsal/04-reshape -->
```text
$ jq -c '.[] | {number, draft, base: .base.ref}' pulls-sample.json
{"number":14,"draft":false,"base":"main"}
{"number":15,"draft":true,"base":"main"}
{"number":16,"draft":false,"base":"release/0.1"}
```
<!-- /snippet -->

And building a new object per element, with a renamed field.

**Step 5: the Git half of a feature cycle.** Replay `labs/run ch15/lab-25-1-feature-cycle`. It runs against a local bare server, so it shows only what Git does; the platform steps appear as comments.

<!-- snippet: ch15/lab-25-1-feature-cycle/02-push -->
```text
$ git push -u origin feature/list-names
To ../../server/practice-repo.git
 * [new branch]      feature/list-names -> feature/list-names
branch 'feature/list-names' set up to track 'origin/feature/list-names'.
$ git status -sb
## feature/list-names...origin/feature/list-names
```
<!-- /snippet -->

`git push -u` is 🟡 CAUTION: it creates a ref on the server. On GitHub, the next command would be `gh pr create`.

<!-- snippet: ch15/lab-25-1-feature-cycle/03-second-commit -->
```text
# The pull request is open. A review comment asks for documentation:
$ printf '\nnames() returns the registered prompt names in sorted order.\n' >> docs/architecture.md
$ git commit -q -am "Document names()"
$ git status -sb
## feature/list-names...origin/feature/list-names [ahead 1]
$ git push
To ../../server/practice-repo.git
   8e723d1..c0b29a8  feature/list-names -> feature/list-names
$ git log --oneline main..origin/feature/list-names
c0b29a8 Document names()
8e723d1 Add names() to list registered prompts
```
<!-- /snippet -->

A review comment asks for documentation; you commit and push again. The pull request now has two commits: `c0b29a8` and `8e723d1`.

<!-- snippet: ch15/lab-25-1-feature-cycle/04-after-merge -->
```text
# The pull request was merged on the platform with "Squash and merge", and the branch deleted there.
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git pull --ff-only
From ../../server/practice-repo
   bf7889c..9477a3f  main       -> origin/main
Updating bf7889c..9477a3f
Fast-forward
 docs/architecture.md            | 2 ++
 src/prompt_registry/registry.py | 4 ++++
 2 files changed, 6 insertions(+)
$ git log --oneline -3
9477a3f Add names() to list registered prompts (#2)
bf7889c Add contribution guide, security policy and templates
e4be0df Add registry tests
```
<!-- /snippet -->

The pull request was squash-merged on the platform. `git pull --ff-only` is 🟡 CAUTION: it fetches and moves your branch forward. On `main` there is one new commit, `9477a3f`, and its subject ends with the pull request number in parentheses. Your two commits are not in that log.

```bash
git fetch --prune
git branch -vv
git branch -d feature/list-names
```

`git fetch --prune` is 🟡 CAUTION: it deletes stale remote-tracking refs and their reflogs. **[PAUSE]** The branch was merged on the platform. Will `git branch -d` agree that it is merged?

<!-- snippet: ch15/lab-25-1-feature-cycle/05-cleanup -->
```text
$ git fetch --prune
From ../../server/practice-repo
 - [deleted]         (none)     -> origin/feature/list-names
$ git branch -vv
  feature/list-names c0b29a8 [origin/feature/list-names: gone] Document names()
* main               9477a3f [origin/main] Add names() to list registered prompts (#2)
$ git branch -d feature/list-names
error: the branch 'feature/list-names' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/list-names'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git diff --quiet main feature/list-names && echo "same content"
same content
$ git branch -D feature/list-names
Deleted branch feature/list-names (was c0b29a8).
```
<!-- /snippet -->

It refuses: "not fully merged". After a squash merge your two commits are not ancestors of `main`; Git checks ancestry, not content. So the script checks content: `git diff --quiet` between `main` and the branch prints "same content". Only then comes `git branch -D`, which is 🔴 DANGEROUS, so the five answers first. What it changes: it deletes a ref and its reflog. What it can destroy: your only name for commits that are on no other branch. How to preview: the tree comparison you saw. How to recover: `git branch` with the name and the ID, and the ID is in the output, `c0b29a8`. When it is appropriate: here, after you have shown that the content is on `main`.

**Step 6: the lab replay for API queries.** Replay `labs/run ch15/lab-25-2-api-queries`.

<!-- snippet: ch15/lab-25-2-api-queries/01-shape -->
```text
$ cd api-examples
$ jq 'type, length' pulls-sample.json
"array"
3
$ jq '.[0] | keys' pulls-sample.json | tr -d ' \n'; echo
["base","created_at","draft","head","number","state","title","user"]
```
<!-- /snippet -->

Before you filter a response, ask for its shape: the type, the length, the keys of the first element. Keep that habit for real responses.

**[ON SCREEN]** Lower third: GitHub. Screen walkthrough.

Lab 25.1 on your practice repository, in your normal shell and not in `labs/shell`, because the lab shell switches off the system configuration where the credential helper lives. The interface changes; the lab text and the linked documentation are the reference.

The cycle is: an issue, a branch, commits, a pull request whose body closes the issue, a review comment, a squash merge, local clean-up, then an annotated tag and a release with `--verify-tag`. After each `gh` command, say aloud which object was created and in which layer. `gh issue create`: a GitHub object, no Git data. `git push`: Git data on the server. `gh pr create`: a GitHub object, and according to Chapter 17 also refs under `refs/pull/`. `gh pr merge --squash`: a new commit on the server's `main`, made by GitHub. Keep the browser closed until the end, then open the pull request page once and compare it with what the JSON fields told you.

## COMMON MISTAKES

1. **A script reports exactly 30 items.** Root cause: lists return 30 items per page and the script did not pass `--paginate`.
2. **A script created something by accident.** Root cause: a field flag switched the method from `GET` to `POST`; `-X GET` keeps it a read.
3. **`gh` acts on the wrong one of fork and upstream.** Root cause: with two remotes there are two candidates, and no default was recorded with `gh repo set-default`.
4. **Reading a `404` as "the repository does not exist".** Root cause: for a private resource and a token without access the API answers `404` on purpose.
5. **Building tooling on a personal token and on human-readable output.** Root cause: the token acts as one person everywhere and stops when that person leaves, and the text output is not a stable interface; use `--json`, the version header, and a GitHub App.

## PRODUCTION EXAMPLE

The textbook's case. A nightly job lists the pull requests of sixty repositories with unauthenticated `curl`. It worked from a laptop. It fails on the shared CI runner, where the sixty requests per hour of that IP address are spent before the job starts. Unauthenticated limits were lowered on 8 May 2025, anonymous HTTPS clones included.

The tempting repair is a retry loop. The textbook's verdict: the fix is an identity for the job, not a retry loop. For an evaluation dashboard on an AI/ML team that reads pull request data every night, the identity is a GitHub App installed on those sixty repositories with read permission for pull requests. The job then has its own rate limit, and it survives the departure of whoever wrote it.

## PRACTICE EXERCISE

Do Lab 25.1, "A full feature cycle with `gh`", in [`lab-manual/m25-github-cli-api.md`](../../lab-manual/m25-github-cli-api.md), on your practice repository in your normal shell.

Before each step, predict which objects will be created in Git and which on GitHub. Before step 6, predict what `git branch -d` will say after a squash merge, and why.

The challenge is Exercise 25.4, "Five scripts that stopped working", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q230: "A script using `gh api` returns 30 results everywhere, and once created an issue by accident. Explain both."

A strong answer treats them as two separate defaults and names each precisely: one belongs to the API, the other to the CLI. For each, say what the default is, what in the script triggered it, and the flag that makes the intent explicit. Then generalize: what you put in every script regardless. The follow-up is about a `403` on a shared CI runner with a token that has access; think about what else returns that status, and about what a script must pin to keep working over years.

## RECAP

You should now be able to say:

- `gh` is a client of GitHub's API with your credentials; it also runs `git` where a task needs both.
- Reading commands are safe; `gh pr create` and `gh pr merge` are caution; `--admin` and every non-`GET` `gh api` call are dangerous.
- `gh api` defaults to `GET`, switches to `POST` when a field is passed, and returns 30 items per page without `--paginate`.
- The REST API is versioned by a date header; without it you get `2022-11-28`.
- An integration that must outlive you should be a GitHub App, with installation tokens and its own rate limit.

## HOMEWORK

Read sections 15.16 to 15.18 and 15.20 to 15.22 of [Chapter 15](../../textbook/ch15-github.md), and section 17.16 of [Chapter 17](../../textbook/ch17-pull-requests.md). Do Lab 25.2, "Queries with `gh api`", in [`lab-manual/m25-github-cli-api.md`](../../lab-manual/m25-github-cli-api.md); then Exercise 25.1, "Ask the CLI, not the browser", to Exercise 25.3, "Six filters, offline", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). Read [`cheatsheets/github-cli-cheat-sheet.md`](../../cheatsheets/github-cli-cheat-sheet.md).
