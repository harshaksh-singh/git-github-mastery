# Module 25 labs: GitHub CLI and API

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Read [Chapter 15](../textbook/ch15-github.md), sections 15.8, 15.12, 15.16 and 15.17, and [Chapter 16](../textbook/ch16-authentication.md) first. Answers to the questions are in [the solutions](../solutions/m25-lab-answers.md); write your own first.

## How these labs work

**These labs contact GitHub, so they run in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where macOS usually configures the credential helper, so it cannot authenticate to GitHub. You work in `~/git-mastery/practice-repo`, your clone of `YOUR-ORG/practice-repo` from Lab 19.1.

What "Expected output" means here:

- For Git commands it is the real output of a replay script in `labs/ch15/`, in which a bare repository on disk stands in for GitHub. Where the platform acts (the squash merge), a plain Git command plays its part and a note in the transcript says so. Your commit IDs and identity differ from the book's.
- For `gh` commands, nothing could be run or captured while this book was written. The expected result is described from `gh <command> --help` of version 2.88.1 and from the linked documentation. Every flag used was checked against that help text. If your `gh` is newer, a flag may have gained company; if a command is rejected, read its `--help`.

No step asks you to paste a token anywhere. `gh` uses the login you already have (`gh auth status`).

The practice repository is public. Everything you write into issues and pull requests there is readable by anyone.

## Lab 25.1: A full feature cycle with `gh`

### Objective

Take one change from issue to release without opening the browser: issue, branch, commits, pull request, review comment, squash merge, local clean-up, tag and release. At each step say which objects were created in Git and which on GitHub.

### Prerequisites

Labs 19.1 and 20.2. Chapter 15, sections 15.8, 15.12 and 15.16. Chapter 17 if pull requests are new to you. The repository setting "automatically delete head branches" from Lab 19.1.

### Setup

```bash
cd ~/git-mastery/practice-repo
git switch main
git pull --ff-only
git status -sb
gh auth status
gh repo set-default --view
```

The working tree must be clean and `main` up to date. If `gh repo set-default --view` prints nothing, that is fine: with one remote there is nothing to choose.

### Commands

```bash
# 1. An issue. Note the number in the URL that gh prints; it is N below.
gh issue create --title "List the registered prompt names" \
  --body "The registry cannot say what it holds. Add names()." --label enhancement
gh issue list

# 2. A branch and a commit
git switch -c feature/list-names
printf '\n    def names(self):\n        """Return the registered prompt names, sorted."""\n        return sorted(self._versions)\n' >> src/prompt_registry/registry.py
git diff --stat
python3 -m unittest discover -s tests 2>&1 | tail -1
git commit -q -am "Add names() to list registered prompts"

# 3. Push, then a pull request that will close the issue
git push -u origin feature/list-names
git status -sb
gh pr create --title "Add names() to list registered prompts" --body "Closes #N"
gh pr view
gh pr view --json number,state,isDraft,baseRefName,headRefName,closingIssuesReferences
gh pr diff
gh pr checks

# 4. A review comment, then the commit that answers it
gh pr review --comment --body "Please document names() in docs/architecture.md."
printf '\nnames() returns the registered prompt names in sorted order.\n' >> docs/architecture.md
git commit -q -am "Document names()"
git status -sb
git push
git log --oneline main..origin/feature/list-names
gh pr view --json commits --jq '.commits | length'

# 5. Squash and merge. If gh asks questions, answer them, but do not let it delete the local branch.
gh pr merge --squash
gh pr view --json state,mergedAt,mergeCommit
gh issue view N --json state,closedAt

# 6. Bring your clone up to date and clean up
git switch main
git pull --ff-only
git log --oneline -3
git fetch --prune
git branch -vv
git branch -d feature/list-names
git diff --quiet main feature/list-names && echo "same content"
git branch -D feature/list-names

# 7. A release, cut on purpose: annotated tag first, then the release
git tag -a v0.1.0 -m "practice-repo 0.1.0"
git push origin v0.1.0
gh release create v0.1.0 --verify-tag --generate-notes
gh release view v0.1.0
gh release list

# 8. The experiment that Chapter 15 left open: a release for a tag that does not exist
gh release create v0.1.1 --prerelease --notes "Experiment: a release without a tag."
git ls-remote --tags origin
git fetch --tags origin
git cat-file -t v0.1.0
git cat-file -t v0.1.1
git describe
git describe --tags
gh release delete v0.1.1 --cleanup-tag --yes
git tag -d v0.1.1
git ls-remote --tags origin
```

### Expected output

The Git half, from the replay `labs/ch15/lab-25-1-feature-cycle.sh`:

<!-- snippet: ch15/lab-25-1-feature-cycle/01-branch -->
```text
$ cd you/practice-repo
$ git switch -c feature/list-names
Switched to a new branch 'feature/list-names'
$ printf '\n    def names(self):\n        """Return the registered prompt names, sorted."""\n        return sorted(self._versions)\n' >> src/prompt_registry/registry.py
$ git diff --stat
 src/prompt_registry/registry.py | 4 ++++
 1 file changed, 4 insertions(+)
$ python3 -m unittest discover -s tests 2>&1 | tail -1
OK
$ git commit -q -am "Add names() to list registered prompts"
```
<!-- /snippet -->

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

In the replay the squash commit is numbered `(#2)` because a script wrote that subject. On GitHub the number is your pull request's.

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

The `gh` half, described and not captured:

- `gh issue create` and `gh pr create` each print the URL of the object they created; `gh pr create` says so in its help: "Upon success, the URL of the created pull request will be printed."
- `gh pr view --json ...` prints one JSON object. Expect the state open, `baseRefName` `main`, `headRefName` `feature/list-names`, and your issue in `closingIssuesReferences`, because the description contains a closing keyword and the base is the default branch ([linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue)).
- `gh pr checks` has no checks to show, because the repository has no workflows yet (Chapter 20A). It says so in gh's words.
- `gh pr view --json commits --jq '.commits | length'` prints `2` after the second push.
- After `gh pr merge --squash`: the state is merged, `mergeCommit` names one new commit, and the issue's state is closed. The branch `feature/list-names` no longer exists on GitHub, because Lab 19.1 enabled automatic deletion of head branches ([docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-the-automatic-deletion-of-branches)).
- `gh release create v0.1.0 --verify-tag --generate-notes` prints the URL of the release. Its notes list the merged pull request ([generated release notes](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes)).
- In step 8, `git ls-remote --tags origin` shows two lines for `v0.1.0` (the tag object and, with `^{}`, its commit) and, if the tag that the release created is lightweight, one line for `v0.1.1`. `git cat-file -t` then prints `tag` for `v0.1.0` and `commit` for `v0.1.1`. Both `git describe` commands print `v0.1.0` here: the two tags name the same commit, and an annotated tag takes precedence over a lightweight one even with `--tags` (checked locally with Git 2.55.0). They disagree only when the lightweight tag sits on a later commit, as in Chapter 15, section 15.12. **The tag type is the observation the chapter marks as unverified. Write down what you see.**

### What happened internally

| Step | Git data | GitHub objects |
|---|---|---|
| 1 | none | an issue with a label |
| 2 | a commit and a local branch | none |
| 3 | `refs/heads/feature/list-names` on the server; your remote-tracking ref and upstream | a pull request; a read-only ref `refs/pull/N/head` on the server; the link to the issue |
| 4 | a second commit; the server's branch moves | a review with a comment; the pull request now lists two commits |
| 5 | **one new commit on `main`, created by GitHub**, containing both changes; the feature branch deleted on the server | the pull request is merged; the issue is closed |
| 6 | your `main` fast-forwards; your stale remote-tracking ref is pruned; your local branch is deleted | none |
| 7 | a tag object and `refs/tags/v0.1.0`, locally and then on the server | a release that points at the tag |
| 8 | a tag created on the server by the release; later deleted | a pre-release, later deleted |

Step 6 is where the squash shows. Your two commits are not ancestors of `main`: `main` has one different commit with the same content. Once the upstream branch is gone, `git branch -d` compares with `HEAD`, finds the branch "not fully merged" and refuses. `git diff --quiet main feature/list-names` proves that nothing would be lost, and only then is `-D` right.

### Checkpoint

```bash
git branch -a
git status -sb
python3 -m unittest discover -s tests 2>&1 | tail -1
gh pr list --state merged
gh release list
```

<!-- snippet: ch15/lab-25-1-feature-cycle/06-checkpoint -->
```text
$ git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
$ git status -sb
## main...origin/main
$ python3 -m unittest discover -s tests 2>&1 | tail -1
OK
```
<!-- /snippet -->

Only `main` remains, in step with `origin/main`, and the tests pass. `gh pr list --state merged` lists your pull request, and `gh release list` lists `v0.1.0` only.

### Failure scenario

After a few squash merges, `git branch -D` becomes a reflex. Use it once on the wrong branch: new work that was committed and never pushed.

```bash
git switch -q -c docs/usage
printf '\n## Usage\n\nRegister a template, then render it with values.\n' >> README.md
git commit -q -am "Add usage section to README"
git switch -q main
git branch -D docs/usage
git branch -a
```

<!-- snippet: ch15/lab-25-1-feature-cycle/07-failure -->
```text
# New work, committed and never pushed. Then the clean-up habit strikes the wrong branch.
$ git switch -q -c docs/usage
$ printf '\n## Usage\n\nRegister a template, then render it with values.\n' >> README.md
$ git commit -q -am "Add usage section to README"
$ git switch -q main
$ git branch -D docs/usage
Deleted branch docs/usage (was 0d28c8c).
$ git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
```
<!-- /snippet -->

The branch is gone, it was never on GitHub, and no pull request refers to it. Nothing on the platform can bring it back.

### Recovery

The commit still exists in your object database, and the reflog of `HEAD` remembers it ([Chapter 13](../textbook/ch13-recovery.md)):

```bash
git reflog -3
git branch docs/usage 'HEAD@{1}'
git log --oneline -1 docs/usage
```

<!-- snippet: ch15/lab-25-1-feature-cycle/08-recovery -->
```text
$ git reflog -3
9477a3f HEAD@{0}: checkout: moving from docs/usage to main
0d28c8c HEAD@{1}: commit: Add usage section to README
9477a3f HEAD@{2}: checkout: moving from main to docs/usage
$ git branch docs/usage 'HEAD@{1}'
$ git log --oneline -1 docs/usage
0d28c8c Add usage section to README
```
<!-- /snippet -->

The message of `git branch -D` also printed the abbreviated commit ID (`was ...`); `git branch docs/usage <that ID>` works as well.

### Verification

```bash
git branch -vv
git log --oneline main..docs/usage
git diff --stat main docs/usage
```

<!-- snippet: ch15/lab-25-1-feature-cycle/09-verification -->
```text
$ git branch -vv
  docs/usage 0d28c8c Add usage section to README
* main       9477a3f [origin/main] Add names() to list registered prompts (#2)
$ git log --oneline main..docs/usage
0d28c8c Add usage section to README
$ git diff --stat main docs/usage
 README.md | 4 ++++
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

Keep the branch for Lab 25.2 or delete it; it is yours.

### Questions

1. After the squash merge, `git branch -d feature/list-names` refused. What exactly did Git check, and why did the check fail although the work is on `main`? What would `-d` have done before `git fetch --prune`?
2. Who is the author of the squash commit on `main`, and who created it? How would you find out with `git log --format=fuller`, and what do you expect in the committer field?
3. The issue closed when the pull request merged. Name the two conditions that had to hold, and one way each could have failed.
4. In step 8, what did `git cat-file -t` print for the two tags, and what does that tell you about tags created by releases? What did `git describe` print, and why?
5. `gh release delete v0.1.1 --cleanup-tag` removed the tag on GitHub. Why was `git tag -d v0.1.1` still necessary, and what would have happened on your next `git push --tags` without it?
6. Which steps of the cycle would have been impossible, or different, with the Read role? With Triage?
7. In the failure scenario, why could nothing on GitHub restore the branch? Name every place where the commit still existed after `git branch -D`.

## Lab 25.2: Queries with `gh api`

### Objective

Read repository, pull request, ruleset and rate-limit data through the REST API with `gh api`, shape it with `--jq`, paginate, pin the API version, and call GraphQL once. Know which requests change something.

### Prerequisites

Lab 25.1. Chapter 15, section 15.17.

### Setup

Part A is an offline rehearsal of the filters with the `jq` program that macOS ships, in your normal shell, from the course folder:

```bash
cd labs/ch15/api-examples
cat README.md
```

`pulls-sample.json` is a practice document written for this course. It is not output from GitHub. Its field names were checked against the REST reference for the pull request list.

Part B runs in `~/git-mastery/practice-repo`.

### Commands

Part A, in `labs/ch15/api-examples`:

```bash
# 1. Shape first: what is the top-level type, and which keys does an element have?
jq 'type, length' pulls-sample.json
jq '.[0] | keys' pulls-sample.json | tr -d ' \n'; echo

# 2. Fields
jq -r '.[].title' pulls-sample.json
jq -r '.[] | "#\(.number)  \(.user.login)  \(.head.ref) -> \(.base.ref)"' pulls-sample.json

# 3. Selection
jq -r '.[] | select(.draft | not) | select(.base.ref == "main") | .number' pulls-sample.json
jq -c '[.[] | select(.user.login == "asha-rao") | .number]' pulls-sample.json
```

Part B, in `~/git-mastery/practice-repo`:

```bash
# 1. One object: the repository
gh api repos/{owner}/{repo} --jq '{full_name, default_branch, visibility, fork}'

# 2. A list: pull requests in every state. -X GET keeps the request a query although it has a field.
gh api -X GET repos/{owner}/{repo}/pulls -f state=all \
  --jq '.[] | "#\(.number)  \(.state)  \(.user.login)  \(.head.ref) -> \(.base.ref)"'

# 3. Pagination, made visible with a page size of one
gh api -X GET repos/{owner}/{repo}/pulls -f state=all -F per_page=1 --jq '.[].number'
gh api -X GET repos/{owner}/{repo}/pulls -f state=all -F per_page=1 --paginate --jq '.[].number'

# 4. Rules and rulesets (empty until Module 23)
gh api repos/{owner}/{repo}/rulesets
gh api repos/{owner}/{repo}/rules/branches/main

# 5. Status line and headers; your rate limit; the API version
gh api -i repos/{owner}/{repo} | head -25
gh api rate_limit --jq '.resources.core'
gh api versions
gh api -H 'X-GitHub-Api-Version: 2026-03-10' repos/{owner}/{repo} --jq .full_name

# 6. GitHub's SSH host key fingerprints, from the API
gh api meta --jq '.ssh_key_fingerprints'

# 7. GraphQL: the last releases, in one query (the form of the example in "gh api --help")
gh api graphql -F owner='{owner}' -F name='{repo}' -f query='
  query($name: String!, $owner: String!) {
    repository(owner: $owner, name: $name) {
      releases(last: 3) {
        nodes { tagName }
      }
    }
  }
'
```

### Expected output

Part A, from the replay `labs/ch15/lab-25-2-api-queries.sh`:

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

<!-- snippet: ch15/lab-25-2-api-queries/02-fields -->
```text
$ jq -r '.[].title' pulls-sample.json
Add names() to list registered prompts
Persist versions to SQLite
Backport: reject empty prompt names
$ jq -r '.[] | "#\(.number)  \(.user.login)  \(.head.ref) -> \(.base.ref)"' pulls-sample.json
#14  asha-rao  feature/list-names -> main
#15  ravi-menon  feature/sqlite-store -> main
#16  asha-rao  backport/empty-names -> release/0.1
```
<!-- /snippet -->

<!-- snippet: ch15/lab-25-2-api-queries/03-select -->
```text
$ jq -r '.[] | select(.draft | not) | select(.base.ref == "main") | .number' pulls-sample.json
14
$ jq -c '[.[] | select(.user.login == "asha-rao") | .number]' pulls-sample.json
[14,16]
```
<!-- /snippet -->

Part B, described from the REST reference and `gh api --help`, not captured:

- Step 1 prints an object with four keys. `visibility` is `public` and `fork` is `false` ([get a repository](https://docs.github.com/en/rest/repos/repos#get-a-repository)).
- Step 2 prints one line per pull request of Lab 25.1, in the state `closed`: the REST API has the states open and closed, and a merged pull request is a closed one with a merge time ([list pull requests](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests)).
- Step 3: the first command prints one number, the second prints all of them, one page per request.
- Step 4 prints an empty array (`[]`) for each request while the repository has no rulesets and no rules on `main` ([rules](https://docs.github.com/en/rest/repos/rules)).
- Step 5: the first lines are the HTTP status line and the response headers, among them the `x-ratelimit-*` headers ([rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)). `rate_limit` prints `limit`, `used`, `remaining` and `reset` for the core bucket; the limit for an authenticated user is 5,000 per hour. `versions` prints an array of version names that includes `2022-11-28` and `2026-03-10` ([API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions)).
- Step 6 prints an object with one fingerprint per key type, under keys such as `SHA256_ED25519`. Compare the Ed25519, ECDSA and RSA values with the table in Chapter 16, section 16.11 ([meta](https://docs.github.com/en/rest/meta/meta#get-github-meta-information)).
- Step 7 prints a JSON document whose `data.repository.releases.nodes` holds `{"tagName": "v0.1.0"}`.

### What happened internally

- Every command made one or more HTTPS requests to `api.github.com` with your token in a header. `gh` replaced `{owner}` and `{repo}` from the repository of the current directory.
- `--jq` ran the filter inside `gh`. The `jq` program was not involved in Part B.
- In step 2, `-f state=all` would have turned the request into a `POST`; `-X GET` kept it a query and sent the field in the query string.
- In step 3, `--paginate` followed the `link` header from page to page.
- Nothing in this lab changed Git data or GitHub objects. Every request was a `GET`, except the GraphQL call, which is an HTTP `POST` that carries a read-only query.

### Checkpoint

Part A:

```bash
jq -c 'group_by(.base.ref) | map({base: .[0].base.ref, open: length})' pulls-sample.json
```

<!-- snippet: ch15/lab-25-2-api-queries/04-checkpoint -->
```text
$ jq -c 'group_by(.base.ref) | map({base: .[0].base.ref, open: length})' pulls-sample.json
[{"base":"main","open":2},{"base":"release/0.1","open":1}]
```
<!-- /snippet -->

Part B: write one command that prints, for your practice repository, the number of pull requests in any state. It needs `--paginate` and a filter. Then check `gh api rate_limit --jq '.resources.core.used'` before and after it.

### Failure scenario

Part A. A filter written for one object, applied to a list:

```bash
jq '.title' pulls-sample.json
```

<!-- snippet: ch15/lab-25-2-api-queries/05-failure -->
```text
$ jq '.title' pulls-sample.json
jq: error (at pulls-sample.json:32): Cannot index array with string "title"
[exit status: 5]
```
<!-- /snippet -->

The same mistake with `gh api ... --jq '.title'` fails with a message in the words of gh's built-in filter engine, which differ from those of the `jq` program.

Part B, described and not to be run with valid fields: drop `-X GET` from step 2.

```bash
gh api repos/{owner}/{repo}/pulls -f state=all
```

According to `gh api --help`, a field switches the method to `POST`, and `POST /repos/{owner}/{repo}/pulls` is "Create a pull request". This request lacks the required `head` and `base`, so the API refuses it with an error status (the reference lists 422 for a failed validation). With valid fields it would have created a pull request. Run it once to see the refusal; it creates nothing.

### Recovery

Part A: look at the shape first, then index or iterate:

```bash
jq '.[0].title' pulls-sample.json
jq -c 'map(.title)' pulls-sample.json
```

<!-- snippet: ch15/lab-25-2-api-queries/06-recovery -->
```text
$ jq '.[0].title' pulls-sample.json
"Add names() to list registered prompts"
$ jq -c 'map(.title)' pulls-sample.json
["Add names() to list registered prompts","Persist versions to SQLite","Backport: reject empty prompt names"]
```
<!-- /snippet -->

Part B: put `-X GET` back. For any `gh api` command with a field, write the method explicitly.

### Verification

Part A:

```bash
jq -r '.[] | select(.base.ref != "main") | "#\(.number) targets \(.base.ref)"' pulls-sample.json
```

<!-- snippet: ch15/lab-25-2-api-queries/07-verification -->
```text
$ jq -r '.[] | select(.base.ref != "main") | "#\(.number) targets \(.base.ref)"' pulls-sample.json
#16 targets release/0.1
```
<!-- /snippet -->

Part B:

```bash
gh pr list --state all
gh api -X GET repos/{owner}/{repo}/pulls -f state=all --paginate --jq '.[].number'
```

The numbers from the API are the pull requests that `gh pr list --state all` shows, and no new one appeared.

### Questions

1. `gh pr list` and `gh api repos/{owner}/{repo}/pulls` show the same objects. When would you use each in a script, and why?
2. Why did step 2 need `-X GET`? What is the general rule, and where is it documented?
3. A list endpoint returned 30 items for a repository that has 240. Give two ways to get all of them and the trade-off between them.
4. A request without the `X-GitHub-Api-Version` header works today. What will it get after 10 March 2028, and what should a long-lived script do now?
5. You ran about a dozen requests. How many did the core rate limit count, and which request in this lab is documented as not counting against the primary limit?
6. The API answers `404` for `repos/YOUR-ORG/practice-repo-private` although a colleague can open it in the browser. List the possible causes in the order you would check them.
7. The fingerprints from `gh api meta` match the ones in Chapter 16. Does fetching them over the API make them more trustworthy than reading the documentation page? What is each of the two protected by?
