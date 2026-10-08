# V140: The GitHub CLI, gh pr, gh api, the REST API and GraphQL, rate limits, webhooks and GitHub Apps

- **Part.** 5: GitHub
- **Module.** 25
- **Planned minutes.** 26
- **Prerequisites.** V127, V134
- **Textbook sections.** [Chapter 15](../../textbook/ch15-github.md), sections 15.16 to 15.18 and 15.20 to 15.22; [Chapter 17](../../textbook/ch17-pull-requests.md), section 17.16
- **Demo scripts.** `labs/ch15/gh-help.sh`, `labs/ch15/jq-rehearsal.sh`, `labs/ch15/lab-25-1-feature-cycle.sh`, `labs/ch15/lab-25-2-api-queries.sh`, then a screen walkthrough of Lab 25.1 in [`lab-manual/m25-github-cli-api.md`](../../lab-manual/m25-github-cli-api.md)

## HOOK

**[ON SCREEN]** Two lines. "The report says every repository has exactly 30 open pull requests." "And on Tuesday the script opened an issue in the production repository."

Both come from one script, written in an afternoon, that calls `gh api` in a loop. `gh` is GitHub's command-line program, and `gh api` sends a request to GitHub's API, the interface that programs use to talk to GitHub. Nobody intended either result. The first is a default of the API. The second is a default of the CLI: one flag changed the HTTP method, the verb of the request, without the author noticing.

**[ANIMATION]** cards: id=two question=One_script,_one_loop_of_gh_api,_two_results_nobody_intended cards=exactly_30_open_pull_requests:a_default_of_the_API|an_issue_in_the_production_repository:a_default_of_the_CLI pace=quick

If you're going to automate anything on GitHub, and on an AI and ML team you will, you need to know what the CLI does on your behalf. This video gives you that, and the two defaults behind those two lines. Keep both lines in mind. Each gets its explanation.

## INTRODUCTION

**[ANIMATION]** end

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Through Part 5 you've used `gh` in almost every lab without a formal introduction. This video is that introduction, and it closes the GitHub part before the gate.

Four topics. First, what `gh` is: a client of GitHub's API that knows which repository you're in. Second, `gh pr`: a full pull request cycle from the terminal, and which of its commands change state. A pull request is GitHub's proposal to merge one branch into another. Third, `gh api`: the REST API, its method, fields, pagination and version header, then GraphQL at concept level, and rate limits. Fourth, the integration model: webhooks and GitHub Apps, and when an integration should be an App and not your personal token.

A word on evidence. The authors captured no GitHub output. The local replays show two things only: the `--help` output of the installed CLI, version 2.88.1, and the `jq` program run on a stored practice document. Everything else is described from the documentation and performed by you on your practice repository.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- drive a complete feature cycle from the terminal with `gh`;
- say which `gh` commands change state and which only read;
- query pull request and ruleset data with `gh api` and shape the result with a jq filter;
- explain REST API versioning, pagination and rate limits as the section gives them;
- say when an integration should be a GitHub App.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub.

**In one sentence.** `gh` is a client for GitHub's API that knows which repository you're in, so the GitHub objects become reachable from the directory where your Git data is.

**Precisely.** `gh` isn't Git and doesn't replace it. It calls the REST and GraphQL APIs with a stored token, a string that stands for your account with a subset of its rights. It runs `git` for you where a task needs both, as in `gh repo clone` and `gh pr checkout`. And it can act as Git's credential helper.

Four behaviors explain most surprises.

**[ANIMATION]** cards: id=four cards=which_repository?:your_remotes,_gh_repo_set-default,_-R_or_GH__REPO|machine-readable_output:--json,_then_--jq_or_--template|exit_codes:0,_1,_2,_4,_and_8_for_pending_checks|its_own_token:GH__TOKEN_wins_over_the_stored_login numbered=on title=Four_behaviors_explain_most_surprises

**[ANIMATION]** step: 1

Which repository? Inside a clone, `gh` picks the repository from your remotes. With a fork there are two candidates, and `gh repo set-default` records which one to use. Outside a clone, or to override, you pass `-R` with owner and repository, or set `GH_REPO`.

**[ANIMATION]** step: 2

Machine-readable output. Most listing commands take `--json` with a list of fields, then `--jq` with an expression, or `--template`. JSON is a text format for structured data. `--json` without a field list prints the available fields.

**[ANIMATION]** step: 3

Exit codes. 0 for success, 1 for failure, 2 when cancelled, 4 when authentication is required. `gh pr checks` adds 8 for pending checks. Scripts should test exit codes and not parse human-readable output.

**[ANIMATION]** step: 4

Its own token. `GH_TOKEN` in the environment takes precedence over the stored login. A stale one in a shell profile explains "gh works in one terminal and not in another".

**[ANIMATION]** end

**`gh pr`.** In one sentence: `gh pr` drives the pull request object from the terminal. The Git work around it stays with `git`.

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

Now the labels, because this is the objective people skip. `gh pr view`, `gh pr checks`, `gh pr diff` and `gh pr status` read: 🟢 SAFE. `gh pr checkout` is 🟢 SAFE too. It changes local files and refs only. `gh pr create` is 🟡 CAUTION: it may push the branch, and it creates a GitHub object that notifies people. The preview is `--dry-run`, and the textbook notes that even the dry run may still push. `gh pr merge`, `gh pr update-branch` and `gh pr edit --base` are 🟡 CAUTION: they write to the base branch, move the head branch or change the base, and they can dismiss approvals.

One flag is 🔴 DANGEROUS: `gh pr merge --admin`. What it changes: the base branch, without the required reviews or checks. What it can destroy: no data. What's lost is the review and the checks that the rules required. Preview: `gh pr checks --required`. Recovery: `gh pr revert`, and record the reason. Appropriate: a documented emergency, by someone the bypass list names.

Two details from the help text. `gh pr create` takes the base from `--base`, else from a Git configuration value for the current branch, else the default branch. And `--match-head-commit` merges only if the head is the given commit: you merge what you reviewed, and not what was pushed a second ago.

**`gh api`.** In one sentence: everything GitHub shows you comes from an API that you can call yourself. `gh api` adds your token, the host and the placeholders, and prints the JSON.

The REST API is a set of URLs, one per resource. `gh api` takes the path and fills in the placeholders for owner, repository and branch from the current repository.

```bash
gh api repos/{owner}/{repo} --jq '{full_name, default_branch, visibility, fork}'
gh api repos/{owner}/{repo}/pulls --jq '.[] | "#\(.number) \(.title)"'
gh api repos/{owner}/{repo}/rulesets --jq '.[] | "\(.id) \(.name) \(.enforcement)"'
gh api rate_limit --jq '.resources.core'
gh api -H 'X-GitHub-Api-Version: 2026-03-10' repos/{owner}/{repo}/pulls --paginate --jq '.[].number'
```

The paths and field names were checked against the REST reference on the second of October 2026. The commands weren't run.

Five rules of the road.

First, a quick quiz. A `GET` request reads, and a `POST` creates. You call `gh api` to list issues, and you add one filter with `-f`. What does the CLI send? A, a `GET` with a filter. B, a `POST`. Your answer?

**[PAUSE]**

**[ANIMATION]** walk: id=rules columns=rule,the_default,to_be_explicit rows=method:GET,_but_POST_once_a_field_is_added:-X_GET|fields:-f_sends_a_string:-F_converts_types,_reads_a_file|pagination:30_items_per_page:--paginate,_--slurp|versioning:2022-11-28_without_the_header:send_X-GitHub-Api-Version|not_found:404_for_a_private_resource,_not_403:- marks=1.2:bad,3.2:bad mono=off title=gh_api:_five_rules_of_the_road at_1=20

**[ANIMATION]** step: 1

B, a `POST`. Method. `GET` by default, and `POST` as soon as you add a field with `-f` or `-F`. To send parameters with a `GET`, you say `-X GET`. That's the second line of the hook: a filter parameter turned a read into a create.

**[ANIMATION]** step: 2

Fields. `-f` sends a string. `-F` converts `true`, `false`, `null` and integers to JSON types and can read a file.

**[ANIMATION]** step: 3

Pagination. Lists return 30 items per page unless you ask otherwise. `--paginate` follows the pages. `--slurp` wraps them into one array. That's the first line of the hook.

**[ANIMATION]** step: 4

Versioning. The REST API is versioned by date through the `X-GitHub-Api-Version` header. Without the header, a request gets version `2022-11-28`, which is supported until the tenth of March 2028. `2026-03-10` is the first version with breaking changes. An unsupported version answers `410 Gone`. The CLI pins its own REST calls to `2022-11-28` since version 2.87.0. In a script that must keep working, send the header explicitly.

**[ANIMATION]** step: 5

Not found means "not for you". For a private resource and a token without access, the API answers `404`, not `403`, in the documentation's words "to avoid confirming the existence of private repositories".

**[ANIMATION]** end

Every `gh api` call with `GET` is 🟢 SAFE. Every call with `POST`, `PATCH`, `PUT` or `DELETE`, and every GraphQL mutation, is 🔴 DANGEROUS, and section 15.22 gives the reason in one line: it changes whatever the endpoint says, with all your permissions. The preview is always the `GET` first. The recovery depends on the endpoint, and often there's none.

**GraphQL** is the second API: one endpoint, a typed schema, and a query that names exactly the fields wanted, so one call can replace several REST requests. `gh api graphql -f query=` followed by the query calls it. A GraphQL query only reads, although it's sent as a `POST`. Some features exist in only one of the two APIs.

**[ANIMATION]** bars: id=limits bars=no_authentication:60|your_token_and_gh:5000|an_App_installation:5000|an_App,_Enterprise_Cloud:15000|GITHUB__TOKEN_in_a_workflow:1000 unit=per_hour title=Primary_rate_limits,_requests_per_hour at_1=4 at_2=14 at_3=26 at_4=33 at_5=40

**[ANIMATION]** step: 5

**Rate limits.** With no authentication: 60 requests per hour, per IP address. An authenticated user, which is your token and `gh`: 5,000 per hour. A GitHub App installation: 5,000 per hour at minimum, 15,000 on Enterprise Cloud organizations. The `GITHUB_TOKEN` in a workflow: 1,000 requests per hour per repository. Secondary limits apply on top: at most 100 concurrent requests, and a points budget per minute. Exceeding a limit returns `403` or `429`. So a `403` isn't always a permission problem. `gh api rate_limit` tells you where you stand.

**[ANIMATION]** flow: id=hook actors=your_server,*GitHub msgs=1>2:polling,_did_something_happen?|1>2:register_a_URL_and_the_events|2>1:an_HTTP_request_with_a_JSON_payload|2>1:a_push,_the_ref_and_the_commit_IDs_before_and_after title=A_webhook_reverses_the_direction at_1=5 at_2=30 at_3=45 at_4=65

**[ANIMATION]** step: 4

**Webhooks and GitHub Apps.** Polling asks GitHub repeatedly whether something happened. A webhook reverses the direction: you register a URL and the events you care about, and GitHub sends an HTTP request with a JSON payload when one occurs. A `push` webhook carries the ref and the commit IDs before and after the push. The textbook's remark is worth repeating: that's the information of a reflog line, delivered to your server.

**[ANIMATION]** cards: id=app question=A_GitHub_App:_the_identity_an_integration_should_have cards=installed_on_chosen_repositories|fine-grained_permissions|receives_webhooks|installation_tokens:expire_after_one_hour|not_tied_to_a_person:keeps_working_when_someone_leaves at_1=10 at_2=18 at_3=25 at_4=31 at_5=42

**[ANIMATION]** step: 5

A GitHub App is the identity an integration should have. It's installed on chosen repositories. It holds fine-grained permissions. It receives webhooks. It acts with installation tokens that expire after one hour. And it isn't tied to a person, so it doesn't stop working when someone leaves. The alternatives are a personal token, which acts as you everywhere you have access, and a machine user. One fact for tool writers: the API for check runs and check suites is available only to GitHub Apps. The older commit statuses can be created with Write access.

**[ANIMATION]** end

**[ON SCREEN]** Callout: Unverified. Webhook delivery retries and signature validation were not researched for the Phase 0 report, and are not described in the course.

One thing here is unverified. Webhook delivery retries and signature validation weren't researched for the Phase 0 report, and aren't described in the course.

## MENTAL MODEL

**[ANIMATION]** stores: id=clients boxes=clients:each_presents_a_credential|GitHub's_API:one_API rows=1:A:the_browser|2:A:gh|3:A:a_script_with_curl|4:A:a_GitHub_App|5:A:gh_also_runs_git_on_your_machine@hl arrows=1:A1>B:|2:A2>B:|3:A3>B:|4:A4>B: title=One_API,_many_clients at_1=2 at_2=12 at_3=22 at_4=38

**[ANIMATION]** step: boxes

There's one API. Everything else is a client.

**[ANIMATION]** step: 4

The browser is a client. `gh` is a client. A script with `curl` is a client. A GitHub App is a client. What differs between them is the credential each presents, and therefore what each may do and how often.

**[ANIMATION]** cards: id=ask cards=which_endpoint,_and_which_method?|which_credential,_and_what_else_can_it_do?|what_happens_when_its_author_changes_teams? numbered=on title=Three_questions,_in_this_order at_1=18 at_2=42 at_3=68

So for any automation question, ask three things in this order. Which endpoint am I calling, and with which method? Which credential is making the call, and what else can that credential do? And what happens to this automation when the person who wrote it changes teams?

**[ANIMATION]** step: clients.5

The model breaks slightly for `gh`, because `gh` is two clients in one. It talks to the API, and it also runs `git` on your machine.

**[ANIMATION]** end

Try it now, thirty seconds, on paper. Two commands: `gh pr checkout` and `gh pr create`. For each, write what it does to Git data on your machine and what it does on GitHub. I'll wait.

**[PAUSE]**

**[ANIMATION]** walk: id=split columns=command,Git_data_on_your_machine,on_GitHub rows=gh_pr_checkout:a_local_branch,_files_and_refs:-|gh_pr_create:may_push:creates_a_pull_request mono=off title=Two_halves_of_one_command at_1=3 at_2=30

**[ANIMATION]** step: 2

`gh pr checkout` creates a local branch: it changes local files and refs only. `gh pr create` may push, which is Git data, and it creates a pull request, which is a GitHub object. When you read a `gh` command, split it in your head into the part that touches Git data and the part that touches GitHub objects.

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

Three clients, one API, and a credential on every arrow. The last arrow points the other way. Only the App is called by GitHub. The other two can only ask.

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

Find four lines. `pr`, where you'll spend most of your time. `api`, the one command that reaches everything else. `ruleset`, described as "View info", which you met in video 134. And under the Actions heading, `run` and `workflow`, which belong to the next part of the course.

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

Read the first sentence of the help text aloud: if a matching Git tag doesn't yet exist, one will automatically get created from the latest state of the default branch. That's why section 15.22 labels `gh release create` without `--verify-tag` as 🔴 DANGEROUS, and with `--verify-tag --draft` as 🟡 CAUTION. The textbook's production case: a release script on the day the version variable holds a typo. `--verify-tag` turns that into an error before anything is created.

**Step 3: the flags of `gh api`.**

```bash
gh api --help
```

Before the output: which flag's default is "GET", and which two flags will change that default without mentioning it? Say it out loud.

**[PAUSE]**

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

**Step 4: rehearse the filters offline.** Replay `labs/run ch15/jq-rehearsal`. The input is a practice document written for the course, with the field names of the pull request list. It isn't output from GitHub. And `jq` is a command-line filter for JSON.

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

Three pull requests. One is a draft, one targets a release branch. Which number is printed? Make your prediction.

**[PAUSE]**

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

**Step 5: the Git half of a feature cycle.** Replay `labs/run ch15/lab-25-1-feature-cycle`. It runs against a local bare server, so it shows only what Git does. The platform steps appear as comments.

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

A review comment asks for documentation. You commit and push again. The pull request now has two commits: `c0b29a8` and `8e723d1`.

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

The pull request was squash-merged on the platform. `git pull --ff-only` is 🟡 CAUTION: it fetches and moves your branch forward. On `main` there's one new commit, `9477a3f`, and its subject ends with the pull request number in parentheses.

**[ANIMATION]** graph: id=sq ...2-e4be0df-bf7889c main; bf7889c-8e723d1-c0b29a8 feature/list-names; HEAD=main => ...2-e4be0df-bf7889c-9477a3f main; bf7889c-8e723d1-c0b29a8 feature/list-names; HEAD=main => ...2-e4be0df-bf7889c-9477a3f main; bf7889c-8e723d1-c0b29a8; HEAD=main; reflog:8e723d1,c0b29a8 title=After_a_squash_merge

**[ANIMATION]** step: state-1

Here's that moment as a graph. Before the pull, your branch `feature/list-names` is two commits ahead of `main`.

**[ANIMATION]** step: state-2

After the pull, `main` moves to the squash commit. Your two commits, `8e723d1` and `c0b29a8`, aren't in its history.

```bash
git fetch --prune
git branch -vv
git branch -d feature/list-names
```

`git fetch --prune` is 🟡 CAUTION: it deletes stale remote-tracking refs and their reflogs. The branch was merged on the platform. Will `git branch -d` agree that it's merged? Say yes or no.

**[PAUSE]**

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

It refuses: "not fully merged". After a squash merge your two commits aren't ancestors of `main`. Git checks ancestry, not content. So the script checks content: `git diff --quiet` between `main` and the branch prints "same content".

Only then comes `git branch -D`, which is 🔴 DANGEROUS, so the five answers first. What it changes: it deletes a ref and its reflog. What it can destroy: your only name for commits that are on no other branch. How to preview: the tree comparison you saw. How to recover: `git branch` with the name and the ID, and the ID is in the output, `c0b29a8`. When it's appropriate: here, after you've shown that the content is on `main`.

**[ANIMATION]** step: state-3

And the picture after the deletion: the branch name is gone, and no branch reaches the two commits any more.

**[ANIMATION]** end

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

Lab 25.1 on your practice repository, in your normal shell and not in `labs/shell`, because the lab shell switches off the system configuration where the credential helper lives. The interface changes. The lab text and the linked documentation are the reference.

The cycle is: an issue, a branch, commits, a pull request whose body closes the issue, a review comment, a squash merge, local clean-up, then an annotated tag and a release with `--verify-tag`. After each `gh` command, say aloud which object was created and in which layer. `gh issue create`: a GitHub object, no Git data. `git push`: Git data on the server. `gh pr create`: a GitHub object, and according to Chapter 17 also refs under `refs/pull/`. `gh pr merge --squash`: a new commit on the server's `main`, made by GitHub. Keep the browser closed until the end, then open the pull request page once and compare it with what the JSON fields told you.

## COMMON MISTAKES

Five mistakes to watch for.

1. **A script reports exactly 30 items.** Root cause: lists return 30 items per page and the script did not pass `--paginate`.
2. **A script created something by accident.** Root cause: a field flag switched the method from `GET` to `POST`; `-X GET` keeps it a read.
3. **`gh` acts on the wrong one of fork and upstream.** Root cause: with two remotes there are two candidates, and no default was recorded with `gh repo set-default`.
4. **Reading a `404` as "the repository does not exist".** Root cause: for a private resource and a token without access the API answers `404` on purpose.
5. **Building tooling on a personal token and on human-readable output.** Root cause: the token acts as one person everywhere and stops when that person leaves, and the text output is not a stable interface; use `--json`, the version header, and a GitHub App.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: limits.5

**[ANIMATION]** say: Sixty_repositories,_and_60_requests_per_hour_for_that_IP_address

Now, out of the lab. The textbook's case. A nightly job lists the pull requests of sixty repositories with unauthenticated `curl`. It worked from a laptop. It fails on the shared CI runner, where the sixty requests per hour of that IP address are spent before the job starts. Unauthenticated limits were lowered on the eighth of May 2025, anonymous HTTPS clones included.

**[ANIMATION]** say: The_fix_is_an_identity_for_the_job,_not_a_retry_loop

The tempting repair is a retry loop. The textbook's verdict: the fix is an identity for the job, not a retry loop. For an evaluation dashboard on an AI and ML team that reads pull request data every night, the identity is a GitHub App installed on those sixty repositories with read permission for pull requests. The job then has its own rate limit, and it survives the departure of whoever wrote it.

## PRACTICE EXERCISE

**[ANIMATION]** end

Your turn. Do Lab 25.1, "A full feature cycle with `gh`", in [`lab-manual/m25-github-cli-api.md`](../../lab-manual/m25-github-cli-api.md), on your practice repository in your normal shell.

Before each step, predict which objects will be created in Git and which on GitHub. Before step 6, predict what `git branch -d` will say after a squash merge, and why.

The challenge is Exercise 25.4, "Five scripts that stopped working", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q230: "A script using `gh api` returns 30 results everywhere, and once created an issue by accident. Explain both."

**[PAUSE]**

Answer out loud first. A strong answer treats them as two separate defaults and names each precisely: one belongs to the API, the other to the CLI. For each, say what the default is, what in the script triggered it, and the flag that makes the intent explicit. Then generalize: what you put in every script regardless. The follow-up is about a `403` on a shared CI runner with a token that has access. Think about what else returns that status, and about what a script must pin to keep working over years.

## RECAP

**[ANIMATION]** cards: id=named cards=exactly_30:lists_come_in_pages_of_30_without_--paginate|the_accidental_issue:a_field_flag_turns_a_GET_into_a_POST marks=1:ok,2:ok title=Two_defaults_you_can_name at_1=35 at_2=65 at_marks=85

Let's land this. The two lines from the opening are now two defaults you can name. Exactly 30: lists come in pages of 30 without `--paginate`. The accidental issue: a field flag turns a `GET` into a `POST`.

You should now be able to say:

- `gh` is a client of GitHub's API with your credentials; it also runs `git` where a task needs both.
- Reading commands are safe; `gh pr create` and `gh pr merge` are caution; `--admin` and every non-`GET` `gh api` call are dangerous.
- `gh api` defaults to `GET`, switches to `POST` when a field is passed, and returns 30 items per page without `--paginate`.
- The REST API is versioned by a date header; without it you get `2022-11-28`.
- An integration that must outlive you should be a GitHub App, with installation tokens and its own rate limit.

## HOMEWORK

Read sections 15.16 to 15.18 and 15.20 to 15.22 of [Chapter 15](../../textbook/ch15-github.md), and section 17.16 of [Chapter 17](../../textbook/ch17-pull-requests.md). Do Lab 25.2, "Queries with `gh api`", in [`lab-manual/m25-github-cli-api.md`](../../lab-manual/m25-github-cli-api.md). Then Exercise 25.1, "Ask the CLI, not the browser", to Exercise 25.3, "Six filters, offline", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). Read [`cheatsheets/github-cli-cheat-sheet.md`](../../cheatsheets/github-cli-cheat-sheet.md).

Today you took the CLI apart into its Git half and its GitHub half, and you met the two defaults that surprise every script once. Before the next video, read `gh api --help` and find the default method yourself. Next time: the gate briefing for the GitHub part. Until then, look at the state first and type second. See you in the next one.
