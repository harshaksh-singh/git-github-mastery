# Chapter 19: CODEOWNERS

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026, with the quoted documentation pages re-read on 2 October 2026. Transcripts are real output from `labs/ch18/` (the CODEOWNERS demos live there). Git cannot evaluate a CODEOWNERS file. Every statement about how GitHub matches patterns or requests reviews comes from its documentation and carries the link; where a transcript uses Git's ignore matcher, the text says exactly how the two syntaxes differ.

## 19.1 Why this matters

"We have a CODEOWNERS file. How did a change to the deployment workflow merge without the platform team seeing it?"

There are six ordinary answers: no rule required the review; a later line in the file took the path away from the team; the team has no explicit write access, so its line was skipped; the pull request was a draft; the file that counted was the one on the base branch; or the person who merged could bypass the rule. Each is documented behavior. None is a bug.

## 19.2 What CODEOWNERS is

**In one sentence.** `CODEOWNERS` is a text file in the repository that maps path patterns to users and teams, which GitHub uses to request reviews automatically and, if a rule says so, to require them.

**Analogy.** A building directory in the lobby tells a visitor whom to call. It locks no door. The lock is a separate device (a ruleset) that can be told to consult the directory. The analogy breaks because this directory is read top to bottom and the *last* line that fits wins.

**Precisely.** "Code owners are automatically requested for review when someone opens a pull request that modifies code that they own. Code owners are not automatically requested to review draft pull requests" ([about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)). Three layers again:

| Item | Layer |
|---|---|
| The file, its content, its history | Git: an ordinary tracked file |
| Reading the file, matching changed paths, requesting reviewers | GitHub |
| Blocking the merge until an owner approves | GitHub, and only through a ruleset or a classic rule ([Chapter 18](ch18-branch-protection.md), section 18.7) |

Availability: code owners can be defined "in public repositories with GitHub Free and GitHub Free for organizations, and in public and private repositories" on paid plans (same page).

## 19.3 Where the file lives, and which one counts

**In one sentence.** GitHub looks in `.github/`, then the repository root, then `docs/`, uses the first file it finds, and reads it from the base branch of the pull request.

**Precisely.** "If `CODEOWNERS` files exist in more than one of those locations, GitHub will search for them in that order and use the first one it finds." And: "Each CODEOWNERS file assigns the code owners for a single branch", so `main` and `release/1.0` can have different owners. The file "must be under 3 MB in size"; a larger one "will not be loaded", which means no review requests at all.

**See it.** The search order and the size are plain Git questions about the base branch:

<!-- snippet: ch18/codeowners-base/01-which-file -->
```text
# The documented search order, applied to the base branch of the pull request:
$ for p in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do git cat-file -e origin/main:$p 2>/dev/null && echo "exists on main: $p"; done
exists on main: .github/CODEOWNERS
exists on main: docs/CODEOWNERS
# The first one found is used. Its size in bytes (the documented limit is 3 MB):
$ git cat-file -s origin/main:.github/CODEOWNERS
531
```
<!-- /snippet -->

Two files exist on `main`. The one in `.github/` is used; the older `docs/CODEOWNERS` is dead text that will mislead whoever finds it. Delete it.

## 19.4 Syntax

**In one sentence.** Each line is a pattern followed by one or more owners; comments start with `#`.

The file of the sample repository, as it is on `main`:

<!-- snippet: ch18/codeowners-base/02-base-version -->
```text
$ git show origin/main:.github/CODEOWNERS
# Default owners for everything in the repository.
*                       @example-org/platform

# The routing code.
/router/                @example-org/routing
/router/priority.py     @example-org/routing @example-org/on-call

# Configuration, wherever it lives.
*.yaml                  @example-org/platform @example-org/sre

# Documentation: files directly in docs/.
docs/*                  @example-org/docs

# The files that decide who must review, and what automation runs.
/.github/               @example-org/repo-admins
```
<!-- /snippet -->

The documented rules ([CODEOWNERS syntax](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners#codeowners-syntax)):

- Owners are written `@username` or `@org/team-name`. An email address added to a user's account also works "in most cases", but not for managed user accounts.
- Several owners for one pattern go on **one line**. "If the code owners are not on the same line, the pattern matches only the last mentioned code owner."
- A pattern with **no** owner after it removes ownership: in the documented example `/apps/ @octocat` followed by `/apps/github`, changes under `apps/github` "can be made with the approval of any user who has write access".
- Inline comments are allowed after the owners.
- "CODEOWNERS paths are case sensitive, because GitHub uses a case sensitive file system", even when your Mac is not.
- "If any line in your CODEOWNERS file contains invalid syntax, that line will be skipped." The rest of the file still applies.

**Owners need write access.** This is the rule that fails silently most often. "The people you choose as code owners must have write permissions for the repository. When the code owner is a team, that team must be visible and it must have write permissions, even if all the individual members of the team already have write permissions directly, through organization membership, or through another team membership." And the consequence: "If you specify a user or team that doesn't exist or has insufficient access, a code owner will not be assigned." A secret team cannot be an owner, and a team whose members can all push through the organization's base permission is not an owner until the team itself is granted write access.

## 19.5 Pattern matching: last match wins, and how it differs from gitignore

**In one sentence.** For each changed path GitHub takes the last line of the file whose pattern matches it, and the patterns follow "most of the same rules used in gitignore files", with documented exceptions.

**Last match wins.** "Order is important; the last matching pattern takes the most precedence." In the sample file, `router/classify.py` matches `*` and `/router/`; the later one decides, so the routing team owns it. The trap is a general line placed *after* a specific one. `router/rules/eu.yaml` matches `*`, `/router/` and `*.yaml`. The last of the three is `*.yaml`, so the platform and SRE teams own it, and the routing team is not asked. Put general patterns first and specific ones last, and remember that "specific" means "later in the file", not "longer".

The pattern forms that GitHub documents with examples:

| Pattern | Documented meaning |
|---|---|
| `*` | every file: the default owners |
| `*.js` | files with that extension, anywhere |
| `/build/logs/` | that directory at the repository root, and its subdirectories |
| `docs/*` | files directly in `docs/`, "but not further nested files like `docs/build-app/troubleshooting.md`" |
| `apps/` | "any file in an `apps` directory anywhere in your repository" |
| `/docs/` | the `docs` directory at the root "and any of its subdirectories" |
| `**/logs` | any `logs` directory at any depth, such as `/build/logs` and `/deeply/nested/logs` |

**What does not work.** The documentation warns about three gitignore features: "Escaping a pattern starting with `#` using `\` so it is treated as a pattern and not a comment doesn't work", "Using `!` to negate a pattern doesn't work", and "Using `[ ]` to define a character range doesn't work".

**See it, with a caution.** Git has a matcher for gitignore syntax, `git check-ignore`, and it is tempting to use it as a CODEOWNERS tester. The following transcripts show Git's matcher, not GitHub's. Where the two agree, the transcript illustrates the shared rule. Where they differ, the difference is the lesson.

Within one file, Git also lets the last matching pattern decide, as long as only files are involved:

<!-- snippet: ch18/codeowners-vs-gitignore/01-last-match-wins -->
```text
# Three patterns in one gitignore-format file. check-ignore -v names the pattern that decides:
$ printf '*.py\n/router/*.py\n/router/priority.py\n' > .gitignore
$ git check-ignore -v --no-index tests/test_classify.py router/classify.py router/priority.py
.gitignore:1:*.py	tests/test_classify.py
.gitignore:2:/router/*.py	router/classify.py
.gitignore:3:/router/priority.py	router/priority.py
```
<!-- /snippet -->

But gitignore works on directories first. When a pattern matches a directory, Git excludes the whole directory and never looks at the files inside it:

<!-- snippet: ch18/codeowners-vs-gitignore/03-directory-capture -->
```text
# Where the two part ways: a catch-all first line, then a more specific pattern.
$ printf '*\n*.py\n' > .gitignore
$ git check-ignore -v --no-index setup.py tests/test_classify.py
.gitignore:2:*.py	setup.py
.gitignore:1:*	tests/test_classify.py
# Git stops at the directory tests/, which the first line already matches.
# CODEOWNERS documentation: after "*", a later "*.js" line owns every JS file.
```
<!-- /snippet -->

For `tests/test_classify.py` Git reports line 1, not line 2. CODEOWNERS is documented to behave differently: in GitHub's own example, `*` followed by `*.js` gives every JavaScript file to the JavaScript owner. The same mechanism explains the documented `docs/*` example:

<!-- snippet: ch18/codeowners-vs-gitignore/04-docs-star -->
```text
# The same mechanism behind a documented example: docs/* and nested files.
$ printf 'docs/*\n' > .gitignore
$ git check-ignore -v --no-index docs/getting-started.md docs/build-app/troubleshooting.md
.gitignore:1:docs/*	docs/getting-started.md
.gitignore:1:docs/*	docs/build-app/troubleshooting.md
# Git ignores the nested file too, because docs/* matches the directory docs/build-app.
# CODEOWNERS documentation: docs/* does not match docs/build-app/troubleshooting.md.
```
<!-- /snippet -->

```text
Observed behavior : git check-ignore says docs/* matches docs/build-app/troubleshooting.md.
                    GitHub's CODEOWNERS documentation says it does not.
Git state         : none involved; this is pattern matching on path strings.
Mechanism         : gitignore patterns are applied to each directory on the way down. docs/*
                    matches the directory docs/build-app, and everything below an excluded
                    directory is excluded. CODEOWNERS assigns owners to files, one path at a time.
Root cause        : Two matchers with a shared pattern language and different jobs: one prunes
                    directory walks, the other labels files.
Why Git does this : Skipping an ignored directory without reading it is what makes status fast.
Correct fix       : Do not test CODEOWNERS with check-ignore. Reason from the documented rules,
                    then confirm on GitHub (section 19.11).
Prevention        : To own a whole subtree write the directory form, /docs/ , not docs/* .
```

The three documented exceptions all work in Git, which is why a pattern that "works locally" can do nothing in CODEOWNERS. Negation, for one:

<!-- snippet: ch18/codeowners-vs-gitignore/05-negation -->
```text
# Documented as unsupported in CODEOWNERS: ! negation. In gitignore it works:
$ printf '*.yaml\n!config/routing.yaml\n' > .gitignore
$ git check-ignore -v --no-index config/routing.yaml deploy/values.yaml
.gitignore:2:!config/routing.yaml	config/routing.yaml
.gitignore:1:*.yaml	deploy/values.yaml
```
<!-- /snippet -->

Case sensitivity is the last difference. Git on a Mac usually ignores case in ignore patterns, because `git init` sets `core.ignoreCase` on a case-insensitive file system. GitHub never does:

<!-- snippet: ch18/codeowners-vs-gitignore/08-case -->
```text
# CODEOWNERS paths are always case sensitive. Git depends on core.ignoreCase, which git init
# switches on when the file system ignores case, as the default macOS file system does:
$ printf '/docs/\n' > .gitignore
$ git -c core.ignoreCase=false check-ignore -v --no-index Docs/a.md
[exit status: 1]
$ git -c core.ignoreCase=true check-ignore -v --no-index Docs/a.md
.gitignore:1:/docs/	Docs/a.md
[exit status: 0]
```
<!-- /snippet -->

| | gitignore (Git) | CODEOWNERS (GitHub, documented) |
|---|---|---|
| Last matching pattern decides | yes, among patterns that reach the file | yes |
| A matched directory ends the search | yes | no: owners are assigned per file |
| `docs/*` covers nested files | yes, through the matched subdirectory | no |
| `!` negation | yes | no |
| `[ ]` ranges | yes | no |
| `\#` to start a pattern with `#` | yes | no |
| Case | follows `core.ignoreCase` | always case sensitive |

## 19.6 Why the file only requests reviews until a rule requires them

**In one sentence.** Without a rule, a code owner is a suggested reviewer whom the author may ignore; with the code-owner option of the pull request rule, the merge is blocked until one owner of every changed path approves.

**Precisely.** In a ruleset the option is "Require review from code owners" inside "Require a pull request before merging" (REST: `require_code_owner_review`). With it, "any pull request that modifies content with a code owner must be approved by that code owner before the pull request can be merged". Then the detail that weakens many designs: "if code has multiple owners, an approval from *any* of the code owners will be sufficient" ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-a-pull-request-before-merging)). Two teams on one line means either team, not both.

| Situation | What happens |
|---|---|
| No rule | owners are requested as reviewers; the pull request can merge without them |
| Rule with code owner review | every changed path that has an owner needs an approval from one of its owners |
| A changed path has no owner | the code-owner requirement asks nothing for that path |
| The pull request is a draft | owners are not requested until it is marked ready |
| The owner is the author | authors cannot approve their own pull requests (Chapter 17, section 17.4), so another owner of that path must; an inference from two documented rules, which Lab 23.2 lets you observe |
| The merger is a bypass actor | the rule does not bind them (Chapter 18, section 18.5) |

That row is a reason to list a team, not one person, as owner.

## 19.7 The base branch decides

**In one sentence.** A pull request is judged by the CODEOWNERS file on its base branch, so a pull request that edits CODEOWNERS is reviewed under the old file.

**Precisely.** "To trigger review requests, pull requests use the version of `CODEOWNERS` from the base branch of the pull request." For a pull request from a fork into upstream, that is upstream's file. In a stack, CODEOWNERS is "evaluated from the stack base" ([stacked pull requests](https://docs.github.com/en/pull-requests/reference/stacked-pull-requests)).

**See it.** Your branch changes four paths, one of them the CODEOWNERS file, from which it removes the docs line:

<!-- snippet: ch18/codeowners-base/03-changed-paths -->
```text
# The paths this pull request changes (three dots, as on the Files changed tab):
$ git diff --name-only origin/main...HEAD
.github/CODEOWNERS
config/routing.yaml
docs/README.md
docs/runbooks/escalation.md
```
<!-- /snippet -->

<!-- snippet: ch18/codeowners-base/04-pr-edits-the-file -->
```text
# The pull request also edits CODEOWNERS. On its own branch the docs line is gone:
$ git diff origin/main...HEAD -- .github/CODEOWNERS
diff --git a/.github/CODEOWNERS b/.github/CODEOWNERS
index a5e3975..6478d74 100644
--- a/.github/CODEOWNERS
+++ b/.github/CODEOWNERS
@@ -9,7 +9,6 @@
 *.yaml                  @example-org/platform @example-org/sre
 
 # Documentation: files directly in docs/.
-docs/*                  @example-org/docs
 
 # The files that decide who must review, and what automation runs.
 /.github/               @example-org/repo-admins
# Review requests come from the base version, which still has it:
$ git show origin/main:.github/CODEOWNERS | grep -n "^docs"
12:docs/*                  @example-org/docs
[exit status: 0]
$ git show HEAD:.github/CODEOWNERS | grep -n "^docs"
[exit status: 1]
```
<!-- /snippet -->

The base version still has `docs/*`, so the docs team is requested for `docs/README.md` although your branch deleted their line. You cannot remove a reviewer in the pull request that needs them. For the same reason a fix to CODEOWNERS takes effect one merge later than people expect.

## 19.8 Protecting CODEOWNERS and the workflows directory

**In one sentence.** The file that names the reviewers, and the directory that defines what automation runs, need owners themselves, or anyone with write access can change both in one pull request.

GitHub's advice: "To protect a repository fully against unauthorized changes, you also need to define an owner for the CODEOWNERS file itself. The most secure method is to define a CODEOWNERS file in the `.github` directory of the repository and define the repository owner as the owner of either the CODEOWNERS file (`/.github/CODEOWNERS @owner_username`) or the whole directory (`/.github/ @owner_username`)."

Owning the whole `.github/` directory, as the last line of the sample file does, also covers `.github/workflows/`. A workflow file decides what runs with the repository's token and secrets, so a change to it is a change to your deployment and security posture (Chapter 21A: GitHub Actions security). Three conditions make the protection real: the line must come last, so that no later pattern such as `*.yaml` takes workflow files away; the code-owner option must be required by a rule on the default branch; and the owning team must hold explicit write access.

## 19.9 Monorepo patterns

**In one sentence.** In a monorepo the file is the map of the organization, and its order has to follow the rule "general first, specific last".

```text
# 1. Default: somebody always owns a new directory.
*                               @example-org/platform

# 2. One block per component, anchored at the root.
/services/router/               @example-org/routing
/services/billing/              @example-org/billing
/libs/eval/                     @example-org/ml-eval

# 3. Cross-cutting file types that must override the components.
/services/**/migrations/        @example-org/data
**/Dockerfile                   @example-org/platform

# 4. Last: the files that control review and automation.
/.github/                       @example-org/repo-admins
```

Use the directory form (`/services/router/`) for subtrees; `dir/*` covers one level only. Anchor component paths with a leading slash, or `router/` also matches a directory of that name inside another component. Prefer teams to people, so that ownership survives holidays and departures. The patterns with `**` follow the gitignore rules and are not among GitHub's documented examples except `**/logs`: confirm them with the instruments of section 19.11.

What the file cannot express: "both teams must approve", "two members of this team", or "everyone except this directory". The first two belong to the rule in the next section. The third has only the documented workaround of an owner-less line.

## 19.10 The newer "required reviewers" rule

**In one sentence.** Since February 2026 a ruleset can require approvals from named teams for file patterns, with a count per team, which covers the cases CODEOWNERS cannot express.

**Precisely.** In the pull request rule, "you can require review or approval from specific teams when a pull request changes certain files or directories. You can specify up to 15 different teams, and for each team you can require a certain number of approvals." Counts run from 0 to 10; zero adds the team "for visibility". The team "must have write permissions (or higher)". The rule "is not available on user-owned repositories as they do not contain teams" ([available rules, required reviewers](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#required-reviewers)). It became generally available on 17 February 2026, and GitHub positions it with care: it "augments CODEOWNERS files but doesn't replace them. CODEOWNERS files remain the best way to manage ownership, support individuals as reviewers, and request reviews even when not required" ([changelog](https://github.blog/changelog/2026-02-17-required-reviewer-rule-is-now-generally-available/)).

| | CODEOWNERS | Required reviewers rule |
|---|---|---|
| Lives in | a file in the repository, reviewed like code | a ruleset, edited by administrators |
| Owners | users, teams, emails | teams only |
| Several owners | any one suffices | each listed team has its own required count |
| Negation | no | documented with `!` |
| Applies across repositories | one file per repository and branch | an organization ruleset can cover many |
| Visible to contributors | in the tree, and by hovering over a file | on the rules page |
| Takes effect | when on the base branch | when the ruleset is active |

Chapter 18, section 18.7 records an unresolved point: the documentation page and the REST schema describe the pattern syntax of this rule differently. Test before you depend on it.

## 19.11 Finding out what GitHub thinks

**In one sentence.** Three documented instruments tell you how GitHub read the file: error highlighting on the file's page, the owner shown for each file, and a REST endpoint that lists errors.

- "When you navigate to the CODEOWNERS file in your repository, you can see any errors highlighted."
- When you browse to a file, hovering over the shield icon shows "a tool tip with codeownership details", from the file "for whichever branch in whichever repository you're looking at".
- "A list of errors in a repository's CODEOWNERS file is also accessible via the API": `GET /repos/{owner}/{repo}/codeowners/errors`, with an optional `ref` ([REST: list CODEOWNERS errors](https://docs.github.com/en/rest/repos/repos#list-codeowners-errors)).

```bash
gh api repos/ORG/REPO/codeowners/errors
gh api --method GET repos/ORG/REPO/codeowners/errors -f ref=my-branch
gh pr view 12 --json reviewRequests
```

Each error has a line, a column, a kind, a message and sometimes a suggestion (same page). The CLI has no dedicated command for linting CODEOWNERS; the Phase 0 report looked for one. The commands above use documented endpoints and were not executed here.

The second command is how you test an edit before it merges: ask for the errors of the file as it is on your branch.

## 19.12 What can go wrong: common mistakes

| Mistake | Symptom | Diagnosis | Fix |
|---|---|---|---|
| No rule requires code owner review | owners are requested and ignored | the `/rules` page shows no such option for the branch | add the option to the pull request rule |
| A general pattern after a specific one | the wrong team is requested | read the file bottom-up for the path | move general lines to the top |
| A team without explicit write access, or a secret team | nobody is requested; the errors endpoint reports the line | `gh api .../codeowners/errors` | grant the team write access; make it visible |
| A user or team name misspelled | as above | as above | correct the name |
| Owners of one pattern on two lines | only the later line counts | read the file | one line per pattern |
| `!`, `[ ]` or `\#` in a pattern | the line does not do what it does in `.gitignore` | section 19.5 | rewrite with supported forms or an owner-less line |
| `docs/*` meant as "everything under docs" | nested files fall to the default owner | section 19.5 | `/docs/` |
| Wrong case in a path | no match | compare with `git ls-files` | match the case in the repository |
| Two CODEOWNERS files | the edited one is not the used one | section 19.3 | keep one, in `.github/` |
| The fix is on a branch, not on the base | old owners are still requested | section 19.7 | merge the fix first |
| CODEOWNERS itself has no owner | anyone with write access can rewrite it | read the last lines | own `/.github/` |
| A sole owner | they cannot approve their own change | section 19.6 | own by team |

## 19.13 When not to use it, and dangerous edge cases

- **Do not use it as a notification list.** Every pattern is a review request on every matching pull request. One busy person as owner of `*` becomes the bottleneck of the repository.
- **Do not treat it as access control.** It decides who is asked, and with a rule who must approve. It does not stop anyone with write access from pushing to an unprotected branch.
- **"Any one owner" is not "all owners".** If a change needs two teams, CODEOWNERS on one line does not give you that.
- **Bypass actors and indirect merges** go around it, like every review requirement (Chapter 17, section 17.13; Chapter 18, section 18.5).

## 19.14 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git show <base>:.github/CODEOWNERS`, `git diff --name-only <base>...HEAD`, `git cat-file -e` | 🟢 SAFE | nothing | not needed | not needed |
| `git check-ignore -v --no-index`; `gh api repos/ORG/REPO/codeowners/errors` | 🟢 SAFE | nothing; the first answers a different question (19.5) | not needed | not needed |
| Editing `CODEOWNERS` in a pull request | 🟡 CAUTION | who is requested, and under a rule who can block, from the next merge on | the errors endpoint with `ref` | revert the commit |
| Removing the owner of `/.github/` | 🔴 DANGEROUS | lets any writer change reviewers and workflows without owner review. Destroys no data; removes a control | review the diff of the file | restore the line; audit what merged in between |

## 19.15 Version notes

| Topic | Older behavior | Current behavior | Since | Recommended |
|---|---|---|---|---|
| Reviewers by path | CODEOWNERS only | plus the required reviewers rule with per-team counts | 17 Feb 2026 | CODEOWNERS for ownership; the rule where counts or several teams are needed |
| Dependabot reviewers | the `reviewers` option in `dependabot.yml` | removed; code owners are used ([changelog](https://github.blog/changelog/2025-08-08-dependabot-reviewers-configuration-option-is-replaced-by-code-owners/)) | 8 Aug 2025 | own dependency manifests in CODEOWNERS |
| Stacks | not applicable | CODEOWNERS evaluated from the stack base (preview) | 30 Jul 2026 | expect the base's file |

## 19.16 Practice: pattern exercises

Use the sample file of section 19.4. For each path, name the line that decides and the owners. Reason from the documented rules of section 19.5; do not use `git check-ignore`. Answers are in [the Module 23 answers](../solutions/m23-lab-answers.md).

1. `router/classify.py`
2. `router/priority.py`
3. `router/rules/eu.yaml`
4. `config/routing.yaml`
5. `docs/README.md`
6. `docs/runbooks/escalation.md`
7. `Docs/guide.md`
8. `.github/workflows/ci.yaml`
9. `README.md`
10. The team wants `docs/runbooks/` owned by `@example-org/on-call` and everything else under `docs/` by `@example-org/docs`. Write the lines and say where in the file they go.
11. Someone appends `*.py @example-org/python-guild` as the last line "so the guild sees all Python". Which existing owners lose which paths?
12. The line `/.github/ @example-org/repo-admins` is moved to the top of the file. Who owns `.github/workflows/ci.yaml` now?

Then do [Lab 23.2](../lab-manual/m23-governance.md), which proves enforcement with a second account.

## 19.17 Interview questions

1. What does a CODEOWNERS file do when no rule refers to it?
2. In which locations is the file looked up, in which order, and from which branch is it read for a given pull request?
3. Explain "last match wins" with an example where a later, more general pattern takes a path away from a specific team.
4. Name the gitignore features that do not work in CODEOWNERS, and one behavior that differs although the syntax is accepted.
5. A team is listed as owner and is never requested. Give three documented causes.
6. A path has two owning teams on one line and code owner review is required. Whose approval is needed?
7. Why can a pull request not remove its own required reviewer by editing CODEOWNERS?
8. How do you protect the CODEOWNERS file and the workflows directory, and which three conditions make that protection real?
9. When would you use the required reviewers rule instead of, or together with, CODEOWNERS?
10. How do you find out what GitHub thinks of your CODEOWNERS file before merging a change to it?

## 19.18 Sources

**Primary sources** (docs.github.com and the GitHub Changelog; read on 1 and 2 October 2026)

- [About code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners): locations, syntax, the example file, size limit, write-access requirement, forks, branch protection.
- [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-a-pull-request-before-merging): code owner review and the required reviewers sub-option.
- [REST API: list CODEOWNERS errors](https://docs.github.com/en/rest/repos/repos#list-codeowners-errors).
- [Changelog, 17 February 2026: required reviewer rule generally available](https://github.blog/changelog/2026-02-17-required-reviewer-rule-is-now-generally-available/).
- [Stacked pull requests (reference)](https://docs.github.com/en/pull-requests/reference/stacked-pull-requests).
- Git 2.55: [gitignore pattern format](https://git-scm.com/docs/gitignore#_pattern_format) (`git help ignore`), `git help check-ignore`.

**Secondary sources**

- The Phase 0 report of this course, section 2 ("CODEOWNERS requests reviews; only a rule makes them mandatory"), and its notes on the GitHub platform, section 3.

**Videos**

- The Phase 0 report lists no verified video that teaches CODEOWNERS; its survey of popular beginner courses found that none covers it.

**Further reading**

- [Chapter 17: Pull Requests](ch17-pull-requests.md), sections 17.3 to 17.5; [Chapter 18: Branch Protection and Rulesets](ch18-branch-protection.md), sections 18.5 and 18.7; [Chapter 4: The Working Tree](ch04-working-tree.md), for `.gitignore` itself.
