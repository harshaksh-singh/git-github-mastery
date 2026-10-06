# Chapter 18: Branch Protection and Rulesets

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026, with the quoted documentation pages re-read on 2 October 2026. Transcripts are real output from `labs/ch18/`. No ruleset in this chapter was created on GitHub by the author: every statement about what GitHub enforces or displays comes from its documentation or changelog and carries the link. Plan gates and user-interface labels change; re-check them on the day you rely on them.

## 18.1 Why this matters

Three sentences you will hear from a CTO after an incident:

1. "`main` is protected. How did a force push get through?"
2. "The pull request has two approvals and every check is green. Why is the merge button grey?"
3. "Who is allowed to skip our rules, and would we know if they did?"

[Chapter 17](ch17-pull-requests.md) ended with a list of controls that are only advisory: a "changes requested" review, a red check, a CODEOWNERS file. This chapter is about the layer that makes them binding. On GitHub in 2026 that layer has two mechanisms that coexist, **rulesets** and **classic branch protection rules**, and most "why can't I merge" tickets come from not knowing that both are evaluated.

The chapter teaches rulesets first, because GitHub now says so: "Rulesets are the recommended way to protect your branches" ([changelog, 7 July 2026](https://github.blog/changelog/2026-07-07-restrict-who-can-dismiss-reviews-in-rulesets/)). Classic rules follow in section 18.14, with what still differs.

## 18.2 What a rule is: a check on a ref update

**In one sentence.** A rule is a condition that GitHub evaluates on its server before it lets a ref move, and neither your client nor your `--force` flag has a say in it.

**Analogy.** A bank teller will move money between accounts for anyone with the right card, but checks each transfer against the account's conditions first: two signatures above a limit, no withdrawals from a frozen account. The card is your write permission. The conditions are the rules. The analogy breaks in one place: on GitHub the conditions are published, and anyone who can read the repository can read them.

**Precisely.** Every change to a repository on a server is a ref update: a ref name, the old object ID, the new one. A push proposes ref updates. A merge button is GitHub performing one. [Chapter 12](ch12-remote-operations.md), section 12.7 showed the plain-Git hook that sees each proposal first, `pre-receive`. Five ruleset rules are predicates on those three values:

| Ruleset rule | The question it asks about (old, new, ref) |
|---|---|
| Restrict creations | is the old ID all zeros? |
| Restrict deletions | is the new ID all zeros? |
| Block force pushes | is old *not* an ancestor of new? |
| Require linear history | does `old..new` contain a commit with two parents? |
| Restrict updates | are both IDs non-zero, that is, does an existing ref move? |

The remaining rules (a pull request, approvals, status checks, signatures) ask about GitHub objects attached to the new commits. They need the platform's database, which is why plain Git cannot imitate them.

**See it.** A bare repository plays the server. A hook of my own imitates the five rules; it is not GitHub's implementation.

<!-- snippet: ch18/ref-updates/01-the-rules -->
```text
$ cat rules/pre-receive
#!/bin/sh
# pre-receive: the server runs this before any ref moves.
# Standard input has one line per proposed ref update: <old id> <new id> <ref name>
zero=0000000000000000000000000000000000000000
status=0
while read old new ref; do
  case "$ref" in
    refs/heads/main)                      # target of the branch rules
      if [ "$new" = "$zero" ]; then
        echo "rule 'restrict deletions': $ref may not be deleted"; status=1; continue
      fi
      [ "$old" = "$zero" ] && continue    # creation: nothing to compare with
      if ! git merge-base --is-ancestor "$old" "$new"; then
        echo "rule 'block force pushes': the update would remove commits from $ref"; status=1
      fi
      if [ -n "$(git rev-list --merges "$old..$new")" ]; then
        echo "rule 'require linear history': the update adds a merge commit to $ref"; status=1
      fi ;;
    refs/tags/v*)                         # target of the tag rules
      if [ "$new" = "$zero" ]; then
        echo "rule 'restrict deletions': $ref may not be deleted"; status=1
      elif [ "$old" != "$zero" ]; then
        echo "rule 'restrict updates': $ref already exists and may not move"; status=1
      fi ;;
  esac
done
exit $status
```
<!-- /snippet -->

Once the hook is executable, a fast-forward still goes through:

<!-- snippet: ch18/ref-updates/03-fast-forward-allowed -->
```text
$ printf '# Changelog\n\n## 1.1 (unreleased)\n' > CHANGELOG.md && git add CHANGELOG.md
$ git commit -q -m "Open the changelog for 1.1"
$ git push origin main
To ../../server/ticket-router.git
   4e1f5fe..810dc2f  main -> main
```
<!-- /snippet -->

A rewritten `main` does not:

<!-- snippet: ch18/ref-updates/04-force-push -->
```text
$ git commit -q --amend -m "Open the changelog for 1.1.0"
$ git push --force origin main
remote: rule 'block force pushes': the update would remove commits from refs/heads/main        
To ../../server/ticket-router.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git push --force-with-lease origin main
remote: rule 'block force pushes': the update would remove commits from refs/heads/main        
To ../../server/ticket-router.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git reset -q --hard origin/main
```
<!-- /snippet -->

Read the two rejections. `! [remote rejected]` means the server said no, as opposed to `! [rejected]`, which is your own Git refusing. `--force-with-lease` fared no better than `--force`: both only switch off *client* checks. Deletion is a ref update too:

<!-- snippet: ch18/ref-updates/05-delete -->
```text
$ git push origin --delete main
remote: rule 'restrict deletions': refs/heads/main may not be deleted        
To ../../server/ticket-router.git
 ! [remote rejected] main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
```
<!-- /snippet -->

The linear-history rule ties this chapter to the merge methods of Chapter 17, section 17.8:

<!-- snippet: ch18/ref-updates/06-merge-commit -->
```text
# A merge commit, the result of the "Create a merge commit" method, pushed to main:
$ git merge -q --no-ff -m "Merge pull request #1 from feature/priority-routing" feature/priority-routing
$ git push origin main
remote: rule 'require linear history': the update adds a merge commit to refs/heads/main        
To ../../server/ticket-router.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git reset -q --hard origin/main
# The squash method produces one ordinary commit, which the rule accepts:
$ git merge -q --squash feature/priority-routing
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git commit -q -m "Route high-priority tickets to an escalations queue (#1)"
$ git push origin main
To ../../server/ticket-router.git
   810dc2f..8c7e96f  main -> main
```
<!-- /snippet -->

The merge commit is refused; the squash commit, an ordinary one-parent commit, is accepted. That is the whole content of GitHub's sentence that under this rule "any pull requests merged into the branch or tag must use a squash merge or a rebase merge" ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-linear-history)).

**Picture.**

```text
  your clone                                   the server (GitHub)
  git push origin main      ---- proposes --->  (old, new, refs/heads/main)
                                                      |
                                                      v
                                          every ACTIVE ruleset that targets the ref
                                          + the classic rule that matches the branch
                                                      |
                                    all rules pass    |    one rule fails
                                  ref moves  <--------+-------->  ! [remote rejected]
                                                                  (bypass actors excepted)
```

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| A push rejected by a rule | unchanged | unchanged | unchanged | unchanged | remote-tracking branch unchanged | no ref moves | Rule Insights records the failed evaluation |
| Creating or activating a ruleset 🟡 | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged; no ref moves | later ref updates and merges are evaluated against it |

**In production.** Asked "how did a force push get through", check in this order: was the ruleset Active at that time, did it target that branch name, was the actor on a bypass list, and was the rule in the ruleset at all. Sections 18.3 to 18.5 are those four questions.

## 18.3 Rulesets: targets and enforcement status

**In one sentence.** A ruleset is a named list of rules with a target (which refs), an enforcement status (on or off) and a bypass list (who is excepted).

**Precisely.** "You can have up to 75 rulesets per repository, and 75 organization-wide rulesets" ([about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)). There are three kinds, chosen when you create one ([creating rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository)):

| Kind | Targets | Typical use |
|---|---|---|
| Branch ruleset | branches by name pattern, or "the default branch" | protect `main` and release branches |
| Tag ruleset | tags by name pattern | make release tags immutable (18.12) |
| Push ruleset | every push to the repository and its fork network | block file paths, extensions and sizes (18.12) |

**Target patterns.** Branch and tag targets use `fnmatch` syntax. GitHub names the exact function: "Because GitHub uses the `File::FNM_PATHNAME` flag for the `File.fnmatch` syntax, the `*` wildcard does not match directory separators (`/`). For example, `qa/*` will match all branches beginning with `qa/` and containing a single slash, but will not match `qa/foo/bar`. You can include any number of slashes after `qa` with `qa/**/*`" (same page). That is a Ruby function, and macOS ships a Ruby, so the documented behavior can be run. The script calls `File.fnmatch(pattern, name, File::FNM_PATHNAME)` for each name:

<!-- snippet: ch18/fnmatch-targets/02-star-stops-at-slash -->
```text
$ /usr/bin/ruby match.rb "qa/*" qa/login qa/login/retry qa
qa/*           qa/login               match
qa/*           qa/login/retry         -
qa/*           qa                     -
$ /usr/bin/ruby match.rb "qa/**/*" qa/login qa/login/retry qa/a/b/c
qa/**/*        qa/login               match
qa/**/*        qa/login/retry         match
qa/**/*        qa/a/b/c               match
```
<!-- /snippet -->

<!-- snippet: ch18/fnmatch-targets/03-common-targets -->
```text
$ /usr/bin/ruby match.rb "release/*" release/1.0 release/1.0/hotfix releases/1.0
release/*      release/1.0            match
release/*      release/1.0/hotfix     -
release/*      releases/1.0           -
$ /usr/bin/ruby match.rb "*feature*" feature-x my-feature feature/x team/feature/x
*feature*      feature-x              match
*feature*      my-feature             match
*feature*      feature/x              -
*feature*      team/feature/x         -
$ /usr/bin/ruby match.rb "**/*" main feature/x a/b/c
**/*           main                   match
**/*           feature/x              match
**/*           a/b/c                  match
$ /usr/bin/ruby match.rb "*" main feature/x
*              main                   match
*              feature/x              -
```
<!-- /snippet -->

Three results deserve attention. `release/*` does not cover `release/1.0/hotfix`. `*feature*` does not cover `feature/x`, although the documentation uses that very pattern as an example of "any branches matching", because `*` stops at the slash. And `*` alone matches no branch that has a slash in its name. A pattern that silently fails to match leaves a branch unprotected, with nothing to tell you. Section 18.16 shows how to ask GitHub which rules apply to a given branch name.

Backslash quoting, `[^...]` and extended globs are documented as unsupported. In the REST API two special targets exist, `~DEFAULT_BRANCH` and `~ALL` ([REST: rules](https://docs.github.com/en/rest/repos/rules#create-a-repository-ruleset)). Prefer the first for `main`: it follows a renamed default branch.

**Enforcement status.** The documentation for Free, Pro and Team lists two: **Active**, "your ruleset will be enforced upon creation", and **Disabled**. The Enterprise Cloud documentation adds **Evaluate**: "your ruleset will not be enforced, but you will be able to monitor which actions would or would not violate rules on the 'Rule Insights' page" ([Enterprise view](https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)). The REST schema says the same in a parenthesis: "evaluate is only available with GitHub Enterprise". In the hook imitation the executable bit plays this part:

<!-- snippet: ch18/ref-updates/09-disabled-again -->
```text
# Enforcement status "disabled": the same force push goes through.
$ chmod -x ../../server/ticket-router.git/hooks/pre-receive
$ git push --force origin v1.0.0
hint: The 'hooks/pre-receive' hook was ignored because it's not set as executable.
hint: You can disable this warning with `git config set advice.ignoredHook false`.
To ../../server/ticket-router.git
 + 13ad80e...d68a79d v1.0.0 -> v1.0.0 (forced update)
```
<!-- /snippet -->

A disabled ruleset protects nothing and still looks reassuring in a settings page. Disabling is how rulesets get "temporarily" switched off during an incident and forgotten.

> **Unverified.** Whether Evaluate mode is available to Team-plan organization rulesets is not stated; it appears only in the Enterprise Cloud documentation (flag carried from the Phase 0 report).

## 18.4 Layering: every applicable rule applies

**In one sentence.** Rulesets have no priority order: all active rulesets that target a ref, and the classic rule that matches it, are added together, and for each rule the strictest version wins.

**Precisely.** "A ruleset does not have a priority. Instead, if multiple rulesets target the same branch or tag in a repository, the rules in each of these rulesets are aggregated. If the same rule is defined in different ways across the aggregated rulesets, the most restrictive version of the rule applies. As well as layering with each other, rulesets also layer with protection rules targeting the same branch or tag" ([about rulesets, rule layering](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets#about-rule-layering)).

GitHub's own example: a ruleset requires signed commits and three reviews; a classic rule on the same branch requires linear history and two reviews. Result: signed commits, linear history, and three reviews.

```text
  organization ruleset   : block force pushes, 1 approval
  repository ruleset A   : signed commits, 3 approvals
  repository ruleset B   : required check "ci"
  classic rule on main   : linear history, 2 approvals
  ---------------------------------------------------------------------------
  what a merge into main must satisfy: no force push, signed commits, "ci" green,
                                       linear history, 3 approvals
```

Two consequences. First, **you cannot loosen a branch by editing one layer.** Lab 23.1 reproduces this with two plain-Git layers: the hook is disabled and the force push is still refused, by `receive.denyNonFastForwards`. Second, a repository ruleset can add to an organization ruleset and never subtract: "creating a new ruleset can make the rules targeting a branch or tag more restrictive, but never less restrictive" ([organization rulesets](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization)).

**Forks.** "Forks do not inherit branch or tag rulesets from their upstream repositories", but they "*do* inherit push rulesets from their root repository" (same page). A contributor's fork of your protected repository is unprotected, which is fine: the rules guard your refs, not theirs.

## 18.5 Bypass and exempt actors

**In one sentence.** A ruleset applies to everyone, administrators included, except the actors on its bypass list.

**Precisely.** Eligible for a repository ruleset's bypass list are "Repository admins, organization owners, and enterprise owners", "the maintain or write role, or custom repository roles based on the write role", "Teams, excluding secret teams", "GitHub Apps" and "Dependabot" ([granting bypass permissions](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository#granting-bypass-permissions-for-your-branch-or-tag-ruleset)). Individual users have been eligible since 7 May 2026 ([changelog](https://github.blog/changelog/2026-05-07-repository-rulesets-user-bypass-and-branch-renaming/)). Each entry has a mode; the REST schema names the three ([REST: rules](https://docs.github.com/en/rest/repos/rules#create-a-repository-ruleset)):

| Mode | What the actor may do | Trace |
|---|---|---|
| `always` | push directly and merge despite the rules | a bypass is recorded |
| `pull_request` ("For pull requests only") | must open a pull request, and may then merge it despite unmet rules | "a clear trail of their changes in the pull request and audit log" |
| `exempt` | the rules are not run for this actor | none: "a bypass audit entry will not be created" |

The exempt mode arrived on 10 September 2025. GitHub contrasts it with a standard bypass, "a 'break glass' action that requires an explicit actor bypass and generates prominent audit signals", whereas "an exemption silently skips enforcement" ([changelog](https://github.blog/changelog/2025-09-10-github-ruleset-exemptions-and-repository-insights-updates/)).

This answers question 3 of section 18.1. With an empty bypass list nobody can skip the rules, including the repository's administrators. With `pull_request` bypass you would know. With `exempt` you would not.

> **GitHub, not Git.** The Maintain role's documented right to "push to protected branches" carries the remark "Doesn't apply to rulesets as these have a different bypass model" ([repository roles](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization#permissions-for-each-role)). Under rulesets, roles grant nothing by themselves; only the bypass list does.

**In production.** Keep the bypass list short and made of roles or teams, not people. Prefer `pull_request` mode for humans, so that an emergency merge still leaves a pull request. Reserve `always` for the one automation that must push (a release bot), and give that automation its own GitHub App identity so that the entry names a thing you can audit.

## 18.6 The rules and their sub-options

**In one sentence.** A branch or tag ruleset can contain about a dozen kinds of rule; four of them (pull request, status checks, signed commits, linear history) cause nearly all blocked merges.

The catalogue, from [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets) and its [Enterprise Cloud view](https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets). The last column is the `type` in the REST API ([REST: rules](https://docs.github.com/en/rest/repos/rules#create-a-repository-ruleset)).

| Rule | What it enforces, and its sub-options | REST `type` |
|---|---|---|
| Restrict creations | only bypass actors may create matching refs | `creation` |
| Restrict updates | only bypass actors may push to matching refs | `update` |
| Restrict deletions | only bypass actors may delete matching refs. "This rule is selected by default." | `deletion` |
| Block force pushes | "This rule is enabled by default." Side effect: the default branch cannot be changed or renamed without bypass rights | `non_fast_forward` |
| Require linear history | no merge commits on the target; the repository must allow squash or rebase merging first | `required_linear_history` |
| Require a pull request before merging | "The pull request doesn't necessarily have to be approved, but it must be opened." Sub-options: number of approvals; dismiss stale approvals; code owner review; restrict who can dismiss reviews; approval of the most recent reviewable push; resolved conversations; allowed merge methods; required reviewers by path; extra approval for unattributed Copilot pull requests (preview) | `pull_request` |
| Require status checks to pass | a list of check names; "strict" (branch up to date) or "loose"; optional expected source app per check | `required_status_checks` |
| Require signed commits | only signed and verified commits may be pushed to the target (18.10) | `required_signatures` |
| Require deployments to succeed | named environments must have deployed the change first | `required_deployments` |
| Require merge queue | merges go through a queue (Chapter 17, section 17.11); documented only in the Enterprise Cloud view; not available in organization-level rulesets | `merge_queue` |
| Require code scanning results; code quality results; restrict code coverage (preview); require secret scanning alerts are resolved (preview) | block the merge on findings, on analysis still running, or on a missing tool. Chapter 21B: Repository security | `code_scanning`, `code_quality`, `code_coverage` |
| Automatically request Copilot code review | requests a review; it does not block | `copilot_code_review` |
| Require workflows to pass | organization or enterprise level; Enterprise Cloud view. Chapter 20B | `workflows` |
| Metadata restrictions | Enterprise plan: patterns for commit messages, author and committer email, branch and tag names | `commit_message_pattern` and four more |

> **Unverified.** The REST name of the secret-scanning rule is given as `require_secret_scanning_alert_resolution` in the [changelog of 9 September 2026](https://github.blog/changelog/2026-09-09-block-pull-requests-with-exposed-secrets-from-merging/); the REST schema page read for this chapter does not list it yet.

A new ruleset therefore starts with two rules already selected: restrict deletions and block force pushes. Everything else is a decision. The next five sections take the rules that need explaining.

## 18.7 Required reviews

**In one sentence.** The pull request rule turns Chapter 17's advisory reviews into a gate, and each sub-option closes one specific loophole.

| Sub-option (REST parameter) | Loophole it closes | Cost or caveat |
|---|---|---|
| Required approvals (`required_approving_review_count`) | merging without a second person | approvals count only from people with write permission; authors cannot approve their own pull request |
| Dismiss stale approvals (`dismiss_stale_reviews_on_push`) | commits pushed after the approval | re-approval after every change of the diff, including "Update branch" and a moved merge base (Chapter 17, section 17.5) |
| Approval of the most recent reviewable push (`require_last_push_approval`) | the last pusher approving their own addition | weaker than dismissal; GitHub: "it is safer to dismiss stale reviews" |
| Review from code owners (`require_code_owner_review`) | changes to owned paths without their owner | any one listed owner suffices ([Chapter 19](ch19-codeowners.md)) |
| Restrict who can dismiss reviews (`dismissal_restriction`) | someone with write access dismissing a blocking review | available in rulesets since 7 July 2026 |
| Resolved conversations (`required_review_thread_resolution`) | merging over open questions (18.9) | the author can resolve threads too |
| Allowed merge methods (`allowed_merge_methods`) | history written in a form the team rejected | conflicts with repository settings block the merge |
| Required reviewers (`required_reviewers`) | paths that need a specific team, with a count | teams only; organization repositories only |

Three rules of evaluation that the documentation states and people miss ([pull request rule](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-a-pull-request-before-merging)):

- **A request for changes now blocks.** "If someone chooses the **Request changes** option in a review, then that person must approve the pull request before the pull request can be merged." If that person is unavailable, "anyone with write permissions for the repository can dismiss the blocking review", unless dismissal is restricted.
- **Twin pull requests block each other.** "Collaborators cannot merge the pull request if there are other open pull requests that have a head branch pointing to the same commit with pending or rejected reviews."
- **Method conflicts block.** "If the repository has disabled a merge method and the ruleset required a different method, the merge will be blocked." A ruleset that allows only `squash` in a repository where squash merging is switched off leaves no way to merge.

**Required reviewers** is the newest sub-option, generally available since 17 February 2026: up to 15 teams, each with file patterns and a required number of approvals from 0 to 10, where zero means "the team will be added for visibility" ([changelog](https://github.blog/changelog/2026-02-17-required-reviewer-rule-is-now-generally-available/)). It "is not available on user-owned repositories as they do not contain teams". Chapter 19, section 19.10 compares it with CODEOWNERS.

> **Unverified.** The documentation page describes the file patterns of required reviewers as "the same as a standard `.gitignore` file", with `!` negation. The REST schema says "File patterns use fnmatch syntax" and still labels the parameter beta. The two descriptions do not agree; test a pattern before relying on it.

## 18.8 Required status checks and their traps

**In one sentence.** The rule holds a list of check *names*; a merge is allowed when the newest commit has a passing result under every name, from whoever reported it.

**Strict or loose.** "Strict" means the checkbox **Require branches to be up to date before merging** is selected: "The topic branch **must** be up to date with the base branch before merging. This is the default behavior." Loose: fewer builds, and "status checks may fail after you merge your branch if there are incompatible changes with the base branch" ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-status-checks-to-pass-before-merging)). "Up to date" is a question about ancestry that you can ask locally:

<!-- snippet: ch18/merge-preflight/02-up-to-date -->
```text
# Rule: require branches to be up to date. Is the tip of the base an ancestor of the head?
$ git merge-base --is-ancestor origin/main HEAD
[exit status: 1]
# Commits only main has (left), commits only the branch has (right):
$ git rev-list --left-right --count origin/main...HEAD
1	3
```
<!-- /snippet -->

Exit status 1: the tip of `main` is not an ancestor of the branch. One commit on `main` is missing from it.

**The traps.** All are documented in [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [Troubleshooting rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/troubleshooting-rules) and [Skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs).

| Trap | What the documentation says | Consequence |
|---|---|---|
| A skipped *workflow* | "If a workflow is skipped due to path filtering, branch filtering or a commit message, then checks associated with that workflow will remain in a 'Pending' state." | the pull request waits forever ("Waiting for status to be reported") |
| A skipped *job* | "A job that is skipped will report its status as 'Success'." A job skipped because a job it `needs` failed "may not block merging" | a required check can be green without having run |
| Path filters | the documented example: a workflow with `paths: 'scripts/**'` and a required `build` job; a pull request that only touches the root is blocked | "Avoid requiring workflows that can be skipped." |
| `[skip ci]` in the head commit | the workflow does not run for `push` and `pull_request` | required checks stay pending; push a commit without the instruction |
| The seven-day rule | "A required status check must have completed successfully in the chosen repository during the past seven days" | a check name cannot be picked in the settings until it has run recently |
| The newest commit | "Required checks must pass on the latest commit SHA. Checks from earlier commits don't satisfy the requirement." | every push and every "Update branch" starts over |
| Same name twice | "If a check and a commit status have the same name, both must pass" | name collisions between tools block merges |
| The wrong event | checks from workflow jobs count only for runs triggered by `push`, `pull_request`, `pull_request_review`, `pull_request_target`, `deployment`, `deployment_status` | a green `workflow_dispatch` run on the branch satisfies nothing |
| Merge queue | queue groups trigger `merge_group`, a separate event | without that trigger the check is never reported |
| The wrong source | a check can be pinned to an expected GitHub App: "Required status check \"build\" was not set by the expected GitHub App." | protects against the next row |
| Anyone can report | "Any person or integration with write permissions to a repository can set the state of any status check" | an unpinned required check can be satisfied by an API call (Lab 23.3 does it) |

**Check names.** The name to require depends on what produced the check: for a workflow job it "is `<job name>`"; for a job in a reusable workflow, "`<job name> / <reusable job name>`"; and "required status checks do not take workflow, matrix, or event trigger types into account". The classic-protection page adds: "make sure that job names are unique across all workflows", because the same job name in two workflows gives "ambiguous status check results".

> **Unverified.** The exact check name that a matrix job reports is not stated on these pages (flag carried from the Phase 0 report). Do not guess it: read the names from a real run with `gh pr checks`, or from the merge box, and require what you read.

**The robust pattern**, an inference from the rows above and not a documented recipe: let the workflow start on every pull request, decide inside the workflow which jobs do real work, and require one final job that depends on the others, runs always, and fails if any of them failed or was cancelled. One stable name, never skipped at workflow level. Chapter 20B: Delivery, runners, cost and debugging builds it.

## 18.9 Conversation resolution

**In one sentence.** With this option, every review thread on the pull request must be marked resolved before the merge.

In a ruleset it is part of the pull request rule: "you can require all comments on the pull request to be resolved before it can be merged". In classic protection it is a separate setting, "Require conversation resolution before merging", which is why it is the one setting the conversion tool does not map one to one (18.14).

The control is weaker than it sounds. Resolving a thread is a click, and the author may do it: "You can resolve a conversation in a pull request if you opened the pull request or if you have write access to the repository" ([commenting on a pull request](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/commenting-on-a-pull-request)). The rule ensures that every thread was *acknowledged*, not that it was *addressed*. Pair it with a team convention: the reviewer who opened a thread resolves it.

## 18.10 Signed commits and the merge methods

**In one sentence.** The rule accepts only commits with a verified signature on the target, and it is evaluated against the commits a pull request introduces, not only against the commit the merge creates.

**Precisely.** "Contributors and bots can only push commits that have been signed and verified." Then the part that surprises teams: "When GitHub evaluates whether a pull request can be merged, it creates a test merge commit ... GitHub checks the commits introduced by this test merge, including commits from the head branch. As a result, unsigned commits on the head branch can block a squash merge, even though GitHub would sign the final squash commit" ([signed commits rule](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-signed-commits)).

| Merge method | What lands | Under "Require signed commits" |
|---|---|---|
| Merge commit | your commits and a merge commit signed by GitHub | works if every commit on the head branch is signed and verified |
| Squash | one commit signed by GitHub | the result would pass, but unsigned commits on the head branch block the merge anyway |
| Rebase | new copies of your commits, "without commit signature verification" | cannot satisfy the rule; documented workaround: "rebase and merge locally, and then push" |

The local check for the first two rows:

<!-- snippet: ch18/merge-preflight/05-signatures -->
```text
# Rule: signed commits. %G? prints N for a commit without a signature:
$ git log --format="%h %G? %s" origin/main..HEAD
16d4788 N Fix the name of the escalations queue
12ae95d N Route high-priority tickets to escalation
44c1e7b N Add priority scoring
```
<!-- /snippet -->

`N` means no signature. [Chapter 14B](ch14b-config-tags-signing.md), sections 14B.15 to 14B.17 set up signing; `G` in this column is a good signature *by your local trust settings*, which is not the same as "Verified" on GitHub, where the public key must be registered with the account. The documented repair for an unsigned commit already pushed: "rebase the commit to include a verified signature, then force push". With vigilant mode enabled, commits that GitHub marks "Partially verified" are permitted.

One more documented difference: when a branch is *created*, rulesets "check only the commits that aren't accessible from other branches", whereas classic protection does "not verify signed commits unless you restrict pushes that create matching branches".

**When not to use it.** The rule proves that someone holding a registered key made each commit. It does not prove the commit is good, and it costs every contributor and every bot a key. Server-side rebases (the rebase button, "Rebase stack") become unusable. Decide whether the audit value on your branch is worth that. Chapter 21B treats signing as one control among several.

## 18.11 Linear history, force pushes and deletions

**Linear history.** Section 18.2 showed the predicate. Two details. First, the rule constrains what lands on the target, not the shape of the pull request branch: a branch that contains "Merge main into ..." commits is fine if it is squash-merged, because one ordinary commit lands. Second, GitHub requires the repository to "allow squash merging or rebase merging" before the rule can be enabled. The local measure:

<!-- snippet: ch18/merge-preflight/08-bring-up-to-date -->
```text
# Fix for "not up to date", variant 1: merge the base into the branch.
$ git merge -q origin/main
$ git merge-base --is-ancestor origin/main HEAD
[exit status: 0]
$ git rev-list --left-right --count origin/main...HEAD
0	4
$ git rev-list --count --merges origin/main..HEAD
1
```
<!-- /snippet -->

After merging `main` in, the branch is up to date and carries one merge commit. Under the linear rule this pull request can still be squash-merged. Under the merge-commit method the rule would refuse it.

**Block force pushes.** GitHub's reasons, in one paragraph of the rules page: commits "that other collaborators have based their work on may be removed", which "may lead to merge conflicts or corrupted pull requests", and force pushing "can also be used to delete branches or point a branch to commits that were not approved in a pull request". The last clause is the security argument: without this rule, a required pull request can be undone after the fact. And: "Enabling force pushes will not override any other rules."

**Restrict deletions** is what keeps `main` and release branches from being deleted by a mistyped `git push origin --delete`. Deleting a branch destroys no commits by itself, but it removes the name everything else depends on, and every open pull request against it.

## 18.12 Tag rulesets and push rulesets

**Tag rulesets.** A release tag that moves is a supply-chain problem (Chapter 14B, section 14B.11). The hook imitation shows the two rules that prevent it:

<!-- snippet: ch18/ref-updates/08-tags -->
```text
$ git tag -a v1.0.0 -m "ticket-router 1.0.0" main~1
$ git push origin v1.0.0
To ../../server/ticket-router.git
 * [new tag]         v1.0.0 -> v1.0.0
# Moving a published tag, the supply-chain mistake of Chapter 14B:
$ git tag -f -a v1.0.0 -m "ticket-router 1.0.0" main
Updated tag 'v1.0.0' (was 13ad80e)
$ git push --force origin v1.0.0
remote: rule 'restrict updates': refs/tags/v1.0.0 already exists and may not move        
To ../../server/ticket-router.git
 ! [remote rejected] v1.0.0 -> v1.0.0 (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git push origin --delete v1.0.0
remote: rule 'restrict deletions': refs/tags/v1.0.0 may not be deleted        
To ../../server/ticket-router.git
 ! [remote rejected] v1.0.0 (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
```
<!-- /snippet -->

On GitHub that is a tag ruleset targeting `v*` with restrict updates, restrict deletions and block force pushes. Creation stays open, so a release can still be tagged; add restrict creations with a bypass entry for the release automation if only it may tag.

> **Outdated advice.** "Tag protection rules" under the repository settings were retired on 30 August 2024 and migrated to tag rulesets ([sunset notice](https://github.blog/changelog/2024-05-29-sunset-notice-tag-protections/)). A second, different mechanism is the immutable release, which locks the tag of a published release (Chapter 15: GitHub).

**Push rulesets.** "With push rulesets, you can block pushes to a private or internal repository and that repository's entire fork network based on file extensions, file path lengths, file and folder paths, and file sizes. Push rules do not require any branch targeting because they apply to every push to the repository" ([about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets#push-rulesets)).

| Push rule | Documented detail |
|---|---|
| Restrict file paths | `fnmatch` patterns; at most 200 entries of up to 200 characters; "allowed exceptions" in preview since 25 August 2026 |
| Restrict file path length | a character limit |
| Restrict file extensions | at most 200 entries |
| Restrict file size | a limit in megabytes; it "does not apply to Git Large File Storage" |

Also documented: at most 1,000 ref updates per push, and the rules apply to the REST endpoints that create blobs, trees and file contents as well. For an ML team the obvious uses are "no `*.ckpt`, `*.safetensors` or `*.parquet` in Git" and a size ceiling well below GitHub's hard 100 MiB, so that large files go to Git LFS or to object storage (Chapter 22: Git LFS).

**Plan gate.** Push rulesets need the Team plan and a private or internal repository. You cannot practise them in a public repository on a Free organization.

## 18.13 Organization-level and enterprise-level rulesets

**In one sentence.** An organization ruleset is one ruleset that targets many repositories, selected by name pattern, by custom property, or by a filter.

**Precisely.** Organization rulesets are available on Team and Enterprise plans since 16 June 2025 ([changelog](https://github.blog/changelog/2025-06-16-organization-rulesets-now-available-for-github-team-plans/)). Repositories are targeted as "All repositories", "Only selected repositories", "Repositories matching a name", or, since 24 June 2025 and by default, "Repositories matching a filter" such as `visibility:private props.team:infra` ([changelog](https://github.blog/changelog/2025-06-24-filter-based-ruleset-targeting/)). Only organization owners can edit them. Repository administrators can add stricter repository rulesets and cannot weaken the organization's (18.4). Enterprise-level rulesets, generally available since 24 March 2025, add one more layer on Enterprise Cloud.

> **Unverified.** One sentence of About rulesets still says organization rulesets need the Enterprise plan. The June 2025 changelog and the organization article say Team. The Phase 0 report records this as a conflict inside GitHub's documentation and prefers the later sources.

**The control chain at scale** (an inference from the documented pieces, not one documented procedure): define repository custom properties such as `tier`; target organization rulesets by property; roll out in Evaluate mode where the plan has it; read Rule Insights; switch to Active with a narrow bypass list; watch the audit log. Chapter 15 covers custom properties and the audit log.

**What a Free organization gets.** No organization-level rulesets. Repository rulesets in each public repository, which is what the labs use.

## 18.14 Classic branch protection, and where it still differs

**In one sentence.** A classic branch protection rule is the older mechanism: one rule per branch-name pattern, visible to administrators, with its own bypass behavior, still supported and still evaluated alongside rulesets.

> **Version note.** Older behavior: classic rules were the only way to protect a branch. Current behavior: rulesets are the recommended mechanism, and a **Convert to ruleset** control migrates one classic rule at a time ([changelog](https://github.blog/changelog/2026-08-11-automatically-migrate-branch-protection-rules-to-repository-rulesets/)). Since: 7 July 2026 for the recommendation, 11 August 2026 for the conversion tool; no end date for classic rules has been announced. Recommended: new protection as rulesets; when you inherit a repository, look for classic rules first.

**Where the two differ** ([about protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), [about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)):

| | Classic branch protection rule | Ruleset |
|---|---|---|
| How many apply to one branch | "Only a single branch protection rule can apply at a time" | all that target it, aggregated |
| Who can see it | people with admin access | "Anyone with read access to a repository can view its active rulesets" |
| Switching off | delete the rule | change the enforcement status |
| Administrators | not bound by default: restrictions "don't apply to people with admin permissions" unless **Do not allow bypassing the above settings** is selected | bound, unless on the bypass list |
| Scope | branches of one repository | branches, tags, pushes; repository, organization, enterprise |
| Conversation resolution | a setting of its own | inside the pull request rule |
| Restrict who can push | a setting, with a list of people, teams and apps | "Restrict updates" plus a bypass list |
| Lock branch (read-only), with "Allow fork syncing" | a setting | no rule of that name |
| Signed commits when a branch is created | not verified unless matching-branch creation is restricted | commits not reachable from other branches are checked |
| Rejection message seen by Git | `remote: error: GH006: Protected branch update failed for refs/heads/main.` | not documented on the pages read |

The fourth row is the classic answer to "how did a force push get through": the pusher was an administrator, and the bypass setting was left at its default. Under classic rules the audit log records an administrator's override; the Phase 0 report names the event `protected_branch.policy_override`.

**Conversion.** The tool converts one classic rule at a time and "generates one or more rulesets that preserve the original rule's behavior". The new ruleset is Active at once. If you keep the classic rule, "an **Active** ruleset is enforced alongside it, so changes must satisfy both". The conversion "covers all branch protection types with the exception of the 'Require conversation resolution before merging' setting" ([converting branch protections](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/converting-branch-protections-to-rulesets)).

> **Unverified.** How the classic "Lock branch" setting maps onto ruleset rules is not spelled out in the documentation (flag carried from the Phase 0 report). The report infers "Restrict updates" plus bypass settings.

## 18.15 Plan gates: what you can practise

Plan gates are the facts most likely to have changed by the time you read this. Each row is from a "Who can use this feature?" box or a changelog entry, read on 1 October 2026.

| Feature | Where it is available |
|---|---|
| Repository rulesets; classic branch protection | public repositories on GitHub Free and Free for organizations; public and private on Pro, Team, Enterprise Cloud |
| Organization-level rulesets | Team and Enterprise (conflict noted in 18.13) |
| Enterprise-level rulesets; Evaluate status; metadata restrictions; ruleset history (180 days) | Enterprise Cloud documentation only |
| Push rulesets | Team plan, private or internal repositories |
| Merge queue | public repositories owned by an organization; private ones on Enterprise Cloud |
| Required reviewers by team | organization-owned repositories (teams are required) |
| Rule Insights dashboard | Team and Enterprise Cloud |
| Auto-merge | public repositories on Free; public and private on paid plans |

For you this means: **a public repository in a free practice organization**. There you can create branch and tag rulesets, bypass lists, required reviews, required checks and code owner review. A private repository on a free plan accepts none of it, which is why the labs are public. Evaluate mode, push rulesets and organization rulesets are taught from the documentation.

## 18.16 Seeing and managing rules: `/rules`, `gh ruleset`, `gh api`

**Seeing.** "Anyone with read access to the repository can view the active rulesets." Three documented places: the Rulesets page reached from the branch list, the merge box "if there are rules blocking the merging of a pull request", and "by adding the `/rules` slug to the repository's URL", for example `https://github.com/github/docs/rules` ([managing rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository#viewing-rulesets-for-a-repository)). Classic rules are not on that page; they are under the repository settings, **Branches**, for administrators.

**`gh ruleset` is read-only.** Its help says so: "These commands allow you to view information about them." Three subcommands exist in 2.88.1:

```bash
gh ruleset list                       # rulesets of the current repository, including inherited ones
gh ruleset list --org ORG             # organization rulesets (needs the admin:org scope)
gh ruleset view 123456                # one ruleset by ID; --web opens it in the browser
gh ruleset check main                 # every rule that applies to a branch name
gh ruleset check release/2.0          # the branch "does not need to exist"
gh ruleset check --default
```

`gh ruleset check` is the answer to the silent-pattern problem of section 18.3: ask which rules would apply to a branch name before you trust a pattern.

**Creating and changing go through the REST API** ([REST: rules](https://docs.github.com/en/rest/repos/rules)):

```bash
gh api repos/ORG/REPO/rulesets                               # list
gh api --method POST repos/ORG/REPO/rulesets --input ruleset.json     # create
gh api repos/ORG/REPO/rulesets/123456                        # read one, as JSON
gh api --method PUT repos/ORG/REPO/rulesets/123456 --input ruleset.json
gh api --method PUT repos/ORG/REPO/rulesets/123456 -f enforcement=disabled
gh api --method DELETE repos/ORG/REPO/rulesets/123456
gh api repos/ORG/REPO/rules/branches/main                    # active rules for one branch
gh api repos/ORG/REPO/rulesets/rule-suites                   # evaluations: passed, failed, bypassed
gh api repos/ORG/REPO/branches/main/protection               # the classic rule, if any
```

`gh api --help` itself shows a ruleset body passed with `--input`. The endpoints are the documented ones; none of these commands was executed here. "Get rules for a branch" returns "all active rules that apply to the specified branch", from every level, and leaves out rulesets that are disabled or in evaluate mode. To prevent leaking information, `bypass_actors` is returned only to callers with write access to the ruleset.

Rulesets can be exported and imported as JSON in the web interface (**New ruleset**, then **Import a ruleset**), and GitHub maintains ready-made ones in [`github/ruleset-recipes`](https://github.com/github/ruleset-recipes). Keeping the JSON in a repository gives you review and history for the rules themselves. The bypass list is excluded from the Enterprise history export, so record it separately.

**Rule Insights** lists ref updates that passed, failed or bypassed rulesets, and the `rule-suites` endpoint returns the same data. It is the evidence for "would we know if someone skipped the rules", with the exception of exempt actors (18.5).

## 18.17 "Why can't I merge?": a procedure

**In one sentence.** Work from the outside in: what the merge box says, which rules apply to the base branch from every layer, then one local Git question per rule.

1. **Read the merge box and the CLI's view.** `gh pr view N --json mergeable,mergeStateStatus,reviewDecision` and `gh pr checks N --required`. The values come from the GraphQL API: `mergeable` is `MERGEABLE`, `CONFLICTING` or `UNKNOWN` (not computed yet: ask again); `mergeStateStatus` is one of `BEHIND` ("the head ref is out of date"), `BLOCKED`, `DIRTY` ("the merge commit cannot be cleanly created"), `DRAFT`, `UNSTABLE` ("mergeable with non-passing commit status"), `CLEAN`, `HAS_HOOKS`, `UNKNOWN` ([GraphQL reference](https://docs.github.com/en/graphql/reference/pulls)). `BLOCKED` says a rule is unmet and not which one; the remaining steps find it.
2. **List every rule on the base branch.** `gh ruleset check <base>` or the `/rules` page, then the classic rule under Settings, Branches (administrators) or `gh api repos/ORG/REPO/branches/<base>/protection`. Remember the organization level.
3. **Conflicts.** `git fetch`, then `git merge-tree --write-tree --name-only origin/<base> HEAD`. Exit status 1 names the files (Chapter 17, section 17.7).

<!-- snippet: ch18/merge-preflight/03-conflicts -->
```text
# Mergeability: does the test merge succeed?
$ git merge-tree --write-tree --name-only origin/main HEAD
beff5a60b5d7f4a2b93e41130391fc485f5970e0
[exit status: 0]
```
<!-- /snippet -->

4. **Up to date** (strict checks): `git merge-base --is-ancestor origin/<base> HEAD`. If not, update the branch, then expect the checks to run again and stale approvals to be dismissed.
5. **Checks.** For each required name: is there a result on the *newest* commit? Pending forever means a skipped workflow, a wrong name, or a wrong event (18.8). `gh pr checks N --required` shows what GitHub is waiting for.
6. **Reviews.** Count approvals from people with write access given after the last change of the diff. Look for an outstanding "changes requested", a missing code owner (Chapter 19), an approval by the last pusher, unresolved threads, a twin pull request on the same commit.
7. **Commits.** Which commits would land, and do they satisfy the commit-level rules?

<!-- snippet: ch18/merge-preflight/04-commits -->
```text
# The commits a rule inspects: those the pull request introduces.
$ git log --format="%h parents=%p" origin/main..HEAD
16d4788 parents=12ae95d
12ae95d parents=44c1e7b
44c1e7b parents=9a383e5
# Rule: linear history. Merge commits among them:
$ git rev-list --count --merges origin/main..HEAD
0
```
<!-- /snippet -->

Signatures (`%G?`, section 18.10), merge commits (linear history), and under Enterprise metadata rules the author and committer addresses.

8. **Method.** Is the method you chose allowed by the ruleset *and* enabled in the repository settings?
9. **You.** Are you allowed to merge at all (write permission), and is the pull request still a draft?

If everything passes and the button is still grey, a rule you cannot see is the likely cause: an organization or enterprise ruleset, or a classic rule visible only to administrators. Ask an administrator for the output of step 2.

**The mirror case, "why could they merge?"**: a bypass actor, an administrator under a classic rule without the bypass restriction, `gh pr merge --admin`, a disabled ruleset, a pattern that does not match the branch, or an indirect merge (Chapter 17, section 17.13).

## 18.18 A worked design: protecting a production branch

**Context.** `inventory-api` deploys from `main` on every merge. Six engineers, pull requests of a few hundred lines, CI of about eight minutes, an ML platform team that owns the deployment workflow. The team has decided on squash merges. This is one defensible design for that context, with what each choice costs. Another team should make other choices.

The ruleset, as a file for the REST API. It is assembled from the documented schema and syntax-checked; it has not been sent to GitHub by the author.

```json
{
  "name": "main: production branch",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "bypass_actors": [],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_linear_history" },
    { "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": true,
        "required_review_thread_resolution": true,
        "allowed_merge_methods": ["squash"] } },
    { "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [ { "context": "ci" } ] } }
  ]
}
```

The file is in the course as `labs/ch18/rulesets/main-production.json`.

| Choice | Why here | What it costs | When to choose otherwise |
|---|---|---|---|
| Target `~DEFAULT_BRANCH` | survives a rename; no pattern to get wrong | protects one branch only | add a second ruleset for `release/**/*` |
| Deletions and force pushes blocked | `main` is deployed; its history is an audit record | a bad merge is undone by a revert, never by a reset | never, on a deployed branch |
| Linear history and squash only | one commit per pull request; trivial reverts | reviewed commit IDs are not the commit on `main`; per-commit history is lost (Chapter 17, section 17.9) | merge commits if the reviewed IDs must be the deployed ones |
| One approval, stale approvals dismissed | nothing lands unseen; six people cannot afford two reviewers per change | re-approval after each update | two approvals for regulated code |
| Approval of the last push | covers a reviewer who pushes a fix and approves it | occasionally a second reviewer is needed | drop it for a team of two |
| Code owner review | the deployment workflow and CODEOWNERS have named owners (Chapter 19) | owners become a bottleneck if the file is too broad | no CODEOWNERS file yet |
| Conversations resolved | no merge over an open question | weak (18.9) | high-volume repositories where threads are used for chatter |
| One required check, strict | the tested commit includes current `main`; one stable name (18.8) | with eight-minute CI and a few merges a day, some waiting | a merge queue when updates start to race |
| Empty bypass list | administrators follow the same path | an emergency needs a deliberate edit of the ruleset, which is recorded | add the repository admin role in `pull_request` mode if an on-call engineer must be able to merge at night |
| No signed-commit rule | squash commits are signed by GitHub anyway; requiring signatures on head branches would block contributors without keys (18.10) | commit authorship on branches is unverified | add it where provenance of every commit is a requirement |

Two things the ruleset does not do, and what covers them. It does not protect release tags: that is a tag ruleset (18.12). It does not stop a required check from being reported by anyone with write access: pin the check to its GitHub App with `integration_id` once CI runs as Actions (18.8).

**Rolling it out.** Create it Disabled, run `gh ruleset check main` and read the result, open a test pull request, then switch to Active. On Enterprise Cloud, Evaluate mode does this properly. Lab 23.1 walks through it on your practice repository.

## 18.19 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A force push or deletion reached a "protected" branch | Rule Insights and the audit log; was the ruleset Active, did the pattern match, was the actor a bypass or exempt actor, or an administrator under a classic rule | restore the ref ([Chapter 13](ch13-recovery.md), Chapter 30: Incident response); close the gap | empty or `pull_request`-mode bypass lists; `gh ruleset check <branch>` after every change |
| A required check is "Waiting for status to be reported" forever | the workflow was skipped by a path or branch filter or `[skip ci]`; or the name is wrong; or the run used a non-counting event | run the workflow always and gate inside it; require the real name | one aggregate job as the required check |
| Merge blocked although approved | the approval was dismissed as stale, or given by the last pusher, or a code owner is missing, or another reviewer requested changes | re-approve; see section 18.17, step 6 | explain the review settings in `CONTRIBUTING.md` |
| "Relaxed the ruleset, still blocked" | a second ruleset, an organization ruleset, or a classic rule also applies | list every layer (18.16) | one place for each rule; convert classic rules |
| Squash merge blocked under "signed commits" | unsigned commits on the head branch | rebase with signing and force-push, or a bypass actor merges | tell contributors before enabling the rule |
| No merge method works | the ruleset allows only a method that the repository has disabled | enable the method in the repository settings | change both in the same pull request to your infrastructure code |
| Default branch cannot be renamed | "Block force pushes" on it, and you are not a bypass actor | add a temporary bypass | plan renames |
| A new branch pattern is unprotected | `*` does not cross `/` (18.3) | `**/*` forms; re-check with `gh ruleset check` | test patterns before relying on them |
| Push rejected with `GH006` | a classic rule | follow it: open a pull request | know which branches are protected |

## 18.20 When not to use it, and dangerous edge cases

- **Rules are not review.** A ruleset proves that a process ran. It does not prove that anyone understood the change.
- **A solo or two-person repository** can lock itself out: required approvals with nobody else to approve, and an empty bypass list. Start with "pull request required, zero approvals", which still gives you checks and a record.
- **Exempt actors leave no trace.** Use the mode only for automation whose every action is logged elsewhere.
- **Required checks without a pinned source** can be satisfied by anyone with write access.
- **Strict checks on a busy branch** create a race to merge. That is the signal for a merge queue, not for switching to loose checks without thought.
- **A disabled ruleset is invisible on the `/rules` page**, which shows active ones. An incident review must look at the settings page and at the ruleset history where the plan has it.
- **Rules guard refs, not objects.** A rejected push moved no ref. It is not a secret-removal tool and not a data-loss-prevention system; for metadata rules GitHub documents that rejected commits still enter the repository as retrievable, unreachable objects.
- **Preview rules** (coverage thresholds, secret-scanning resolution, the Copilot approval setting) can change without notice.

## 18.21 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `gh ruleset list`, `view`, `check`; `gh api repos/ORG/REPO/rulesets` (GET); the `/rules` page | 🟢 SAFE | nothing | not needed | not needed |
| `git merge-base --is-ancestor`, `git rev-list --merges`, `git log --format='%G?'`, `git merge-tree --write-tree` | 🟢 SAFE | nothing | not needed | not needed |
| `gh api --method POST repos/ORG/REPO/rulesets --input file.json` | 🔴 DANGEROUS | creates a ruleset; if Active, it binds everyone at once, you included. It destroys nothing; the label is the one [Chapter 15](ch15-github.md), section 15.22 gives every `gh api` call that is not a `GET`, because the call does whatever the endpoint and the JSON say, with all your permissions. Appropriate for rules kept as reviewed JSON | create it with `"enforcement": "disabled"`, then `gh ruleset check` | set `enforcement` to `disabled`, or delete the ruleset |
| `gh api --method PUT .../rulesets/ID` | 🔴 DANGEROUS | replaces settings of a ruleset. What it can destroy: the previous settings, which exist nowhere else unless you saved the JSON (ruleset history exists only on Enterprise). Appropriate for a reviewed change to a rule | `gh api .../rulesets/ID` first and keep the JSON | PUT the saved JSON back |
| `gh api --method DELETE .../rulesets/ID` | 🔴 DANGEROUS | removes the protection for every ref it targeted, immediately. What it can destroy: nothing directly; it makes force pushes and deletions possible | save the JSON first | re-create from the saved JSON; ruleset history exists only on Enterprise |
| `gh pr merge --admin`, a bypass merge | 🔴 DANGEROUS | writes to a protected branch without the required reviews or checks | `gh pr checks --required` | `gh pr revert`; record why |
| `git push --force` to a branch whose protection was just removed | 🔴 DANGEROUS | removes commits from a shared branch | `git log origin/<branch>..<branch>` and the reverse | Chapter 13, Chapter 30 |

For the two deletion and bypass rows: they are appropriate in a planned migration or a declared emergency, by a named person, with the reason written down where the audit will find it.

## 18.22 Version notes

| Topic | Older behavior | Current behavior | Since | Recommended |
|---|---|---|---|---|
| Recommended mechanism | classic branch protection | rulesets; conversion tool | 7 Jul and 11 Aug 2026 | rulesets; check both layers |
| Tag protection rules | a repository setting | retired; tag rulesets | 30 Aug 2024 | tag rulesets |
| Organization rulesets | Enterprise only | Team and Enterprise | 16 Jun 2025 | re-verify plan gates |
| Merge method per branch | repository-wide setting only | `allowed_merge_methods` in the pull request rule ([changelog](https://github.blog/changelog/2025-03-24-enterprise-custom-properties-enterprise-rulesets-and-pull-request-merge-method-rule-are-all-now-generally-available/)) | 24 Mar 2025 | enforce the method where it matters |
| Bypass | role, team or app; always or pull requests only | plus the silent `exempt` mode; plus individual users | 10 Sep 2025; 7 May 2026 | prefer `pull_request` mode |
| Reviewers by path | CODEOWNERS only | required reviewers rule, per-team counts | 17 Feb 2026 | Chapter 19 |
| Who may dismiss reviews | classic rules only | also in rulesets | 7 Jul 2026 | restrict on audited branches |
| Import, export, history | none | JSON import and export; history on Enterprise ([changelog](https://github.blog/changelog/2025-02-13-repositories-ruleset-history-import-and-export-are-generally-available/)) | 13 Feb 2025 | keep ruleset JSON under version control |
| Push rule exceptions | none | allowed exceptions for paths and sizes (preview) | 25 Aug 2026 | preview: do not depend on it |

## 18.23 Practice

- [Module 23 labs](../lab-manual/m23-governance.md): Lab 23.1, a ruleset on the default branch (with a local rehearsal on a bare server); Lab 23.3, three blocked merges to diagnose. Lab 23.2 belongs to [Chapter 19](ch19-codeowners.md).
- Replay the transcripts: `labs/run ch18/ref-updates`, `labs/run ch18/fnmatch-targets`, `labs/run ch18/merge-preflight`.
- Read the rules of a public repository you use, by adding `/rules` to its address. Explain each rule to yourself in terms of section 18.2.

## 18.24 Interview questions

1. What is a rule, mechanically? Which rules can be decided from the old ID, the new ID and the ref name alone, and which need platform data?
2. Two rulesets and a classic rule target `main` with different numbers of required approvals. How many approvals are required, and why?
3. `main` was force-pushed although a ruleset blocks force pushes. List the ways that can happen and the evidence for each.
4. What are the three bypass modes, and what trace does each leave?
5. A required check stays pending forever on documentation-only pull requests. Explain the cause and design a fix that keeps the path optimization.
6. Why can a squash merge be blocked by "Require signed commits" although GitHub signs the squash commit?
7. Compare "dismiss stale approvals" with "approval of the most recent reviewable push". Which attack does each stop?
8. Your ruleset targets `release/*`. Is `release/2.0/hotfix` protected? How do you check without creating the branch?
9. What can you not practise on a Free plan, and how would you learn it anyway?
10. Classic rule versus ruleset: name four behavioral differences that matter during an incident.
11. Walk through your procedure when a developer says "everything is green and I still cannot merge".
12. Design the protection of a branch that deploys to production for a team of six. Defend each rule and name its cost.

## 18.25 Sources

**Primary sources** (docs.github.com and the GitHub Changelog; read on 1 and 2 October 2026)

- Rulesets: [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets) and its [Enterprise Cloud view](https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets), [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets), [Creating rulesets for a repository](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository), [Managing rulesets for a repository](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository), [Troubleshooting rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/troubleshooting-rules), [Converting branch protections to rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/converting-branch-protections-to-rulesets), [Creating rulesets for repositories in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization)
- Classic protection: [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- Checks: [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [Status checks](https://docs.github.com/en/pull-requests/reference/status-checks), [Skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs)
- API and CLI: [REST API endpoints for rules](https://docs.github.com/en/rest/repos/rules), [rule suites](https://docs.github.com/en/rest/repos/rule-suites), [branch protection](https://docs.github.com/en/rest/branches/branch-protection); `gh ruleset --help` and `gh api --help` (2.88.1, local); [gh ruleset manual](https://cli.github.com/manual/gh_ruleset)
- Roles: [Repository roles for an organization](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization)
- Changelog entries are linked where they are used.
- Ruby's [`File.fnmatch`](https://ruby-doc.org/core-2.5.1/File.html#method-c-fnmatch), the function GitHub's documentation links to; Git 2.55: `git help hooks` (`pre-receive`), `git help config` (`receive.denyNonFastForwards`).

**Secondary sources**

- The Phase 0 report of this course, sections 2, 3, 4 and 13, and its notes on the GitHub platform.
- [`github/ruleset-recipes`](https://github.com/github/ruleset-recipes): GitHub's importable example rulesets.

**Videos** (from the Phase 0 report, with its caveats)

- ["Introduction to GitHub Actions - Part 6 - Repository Rulesets"](https://www.youtube.com/watch?v=ZTbM-h9RZOo), Mickey Gousset, 6 December 2024, 15 minutes: a ruleset that requires a status check, the bypass list, rulesets versus classic rules. Current; slow and careful.
- ["Securely building GitHub on GitHub"](https://www.youtube.com/watch?v=eig5tJUl688), GitHub Universe 2024, 41 minutes: rulesets, Rule Insights, Evaluate mode and bypass lists at scale. Predates the 2025 and 2026 ruleset additions.

**Further reading**

- [Chapter 12: Remote Operations](ch12-remote-operations.md), section 12.7 (server-side rules in plain Git); [Chapter 14B](ch14b-config-tags-signing.md), sections 14B.11 and 14B.15 to 14B.17; [Chapter 17: Pull Requests](ch17-pull-requests.md), sections 17.5, 17.8 and 17.11.
