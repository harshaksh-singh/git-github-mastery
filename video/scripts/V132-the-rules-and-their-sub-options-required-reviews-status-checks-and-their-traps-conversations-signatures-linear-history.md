# V132: The rules and their sub-options: required reviews, status checks and their traps, conversations, signatures, linear history

- **Part.** 5: GitHub
- **Module.** 23
- **Planned minutes.** 28
- **Prerequisites.** V124, V128, V131
- **Textbook sections.** [Chapter 18](../../textbook/ch18-branch-protection.md), sections 18.6 to 18.11
- **Demo scripts.** `labs/ch18/merge-preflight.sh`; GitHub-side walkthrough of Lab 23.3

## HOOK

**[ON SCREEN]** A one-line documentation fix. "build — Expected — Waiting for status to be reported." Day three.

A pull request fixes a typo in the README. It has an approval. It has been open for three days, because one required check, a test result the rules demand under the name `build`, says "Expected, waiting for status to be reported". Nobody can find a failed run. Nobody can find any run.

Your CTO asks: what is broken?

**[ANIMATION]** ci: id=hookci pull_request result=skipped file=off job=off runner=off skip_text=a_path_filter:_a_documentation-only_change_does_not_match steps=event,workflow,result title=A_workflow_that_never_starts_never_reports

Nothing in Git, and nothing in the workflow, the file that tells GitHub which jobs to run. The workflow has a path filter, so for a documentation-only change it never starts. A workflow that never starts never reports. And the rule on `main` does not ask "did CI fail?" It asks "is there a passing result under the name `build` on the newest commit?" There is not, and there never will be.

That is the most common of about ten documented traps of one rule. This video goes through the rules that cause nearly all blocked merges, with the local command that predicts each verdict. And the README pull request gets its fix before we finish.

**[ANIMATION]** end

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video a rule was a condition on a ref update, a ruleset was a list of rules with a target, a status and a bypass list, and layers added up. Now we open the list.

A branch or tag ruleset can contain about a dozen kinds of rule. Four of them, pull request, status checks, signed commits and linear history, cause nearly all blocked merges. Sections 18.6 to 18.11 take those, and two smaller ones: conversation resolution, and force pushes and deletions.

The demonstration is a local pre-flight: `labs/ch18/merge-preflight.sh`. It asks Git the questions that can be decided from Git data alone, before you ever open the merge box. Every command in it reads state and is 🟢 SAFE, except its last step, `git merge`, which is 🟡 CAUTION. Then a walkthrough of Lab 23.3 on the platform. That lab creates and edits rulesets with `gh api` calls that are not `GET`. The chapter labels those 🔴 DANGEROUS, for the reason given in the last video: the call does whatever the endpoint and the JSON say, with all your permissions.

## LEARNING OBJECTIVES

After this video you can:

- List the rules a ruleset offers and the sub-options of required reviews.
- Explain why a required check can stay pending forever and design the fix.
- Say what "require branches to be up to date" tests.
- Explain why a merge method can be blocked by "Require signed commits" and which merge methods a linear-history rule allows.
- Run the local pre-flight that predicts each rule's verdict.

## CONCEPT

**[ON SCREEN]** The catalogue of section 18.6.

The catalogue, quickly. Restrict creations, restrict updates, restrict deletions: only bypass actors may create, push to, or delete matching refs. Block force pushes. Require linear history. Require a pull request before merging. Require status checks to pass. Require signed commits. Require deployments to succeed. Require merge queue, documented only in the Enterprise Cloud view. Rules for code scanning and related results. Automatically request Copilot code review, which requests and does not block. Require workflows to pass, at organization or enterprise level. And metadata restrictions, on the Enterprise plan: patterns for commit messages, author and committer email, and branch and tag names.

A new ruleset starts with two rules already selected: restrict deletions and block force pushes. Everything else is a decision.

**[ANIMATION]** walk: id=subs columns=sub-option,the_loophole_it_closes rows=required_approvals:merging_without_a_second_person|dismiss_stale_approvals:commits_pushed_after_the_approval|approval_of_the_most_recent_push:the_last_pusher_approving_their_own_addition|review_from_code_owners:owned_paths_changed_without_their_owner|restrict_who_can_dismiss_reviews:dismissing_a_blocking_review|resolved_conversations:merging_over_open_questions|allowed_merge_methods:history_in_a_form_the_team_rejected|required_reviewers:paths_that_need_a_specific_team mono=off at_8=25 title=Each_sub-option_closes_one_loophole

**[ANIMATION]** step: header

Required reviews. In one sentence: the pull request rule turns the advisory reviews of the pull request chapter into a gate, and each sub-option closes one specific loophole. Note first what the rule itself says: "The pull request doesn't necessarily have to be approved, but it must be opened."

**[ANIMATION]** step: 3

The sub-options, each with the loophole it closes. Required approvals: merging without a second person. Approvals count only from people with write permission. Dismiss stale approvals: commits pushed after the approval. Approval of the most recent reviewable push: the last pusher approving their own addition. It is weaker than dismissal.

**[ANIMATION]** step: 6

Review from code owners: changes to owned paths without their owner, and any one listed owner suffices. Restrict who can dismiss reviews: someone with write access dismissing a blocking review. It is in rulesets since the seventh of July 2026. Resolved conversations: merging over open questions.

**[ANIMATION]** step: 8

Allowed merge methods: history written in a form the team rejected. Required reviewers: paths that need a specific team, with a count. Teams only, organization repositories only, generally available since the seventeenth of February 2026.

Three rules of evaluation that the documentation states and people miss. Under this rule, a request for changes now blocks: that person must approve before the merge, or someone with write permission dismisses the review, unless dismissal is restricted. Twin pull requests block each other: you cannot merge if another open pull request has a head branch pointing to the same commit with pending or rejected reviews. And method conflicts block: a ruleset that allows only squash, in a repository where squash merging is switched off, leaves no way to merge.

**[ANIMATION]** end

One caveat marked unverified: the documentation describes the file patterns of required reviewers as `.gitignore`-like, while the REST schema says fnmatch. The two do not agree. Test a pattern before relying on it.

**[ANIMATION]** cards: id=lookup question=A_merge_is_allowed_when_the_rule_finds cards=every_listed_check_name|a_passing_result_under_it|on_the_newest_commit|from_whoever_reported_it marks=1:ring,3:ring,4:ring

**[ANIMATION]** step: 4

Required status checks. In one sentence: the rule holds a list of check names. A merge is allowed when the newest commit has a passing result under every name, from whoever reported it.

**[ANIMATION]** step: marks

Read that sentence again, because every trap is inside it. Names. The newest commit. Whoever reported it.

Quick quiz, with the hook in mind. A path filter keeps the workflow from starting. What does the required check show? A: success. B: failure. C: pending, for ever. Your answer?

**[PAUSE]**

**[ANIMATION]** step: hookci.result

C. Nothing ran, so nothing reported, and the rule keeps waiting for a name.

**[ANIMATION]** merge: three-way origin/main into feature/priority-routing common=9a383e5 main_only=44c1e7b,12ae95d,16d4788 feature_only=1 cmd_merge=git_merge_-q_origin/main title=Is_the_branch_up_to_date? id=uptodate

**[ANIMATION]** step: setup

Strict or loose. "Strict" means "Require branches to be up to date before merging" is selected: the topic branch must be up to date with the base branch. Loose means fewer builds, and checks may fail after you merge. "Up to date" is a question about ancestry: is the tip of the base an ancestor of the head? You can ask Git that. In the picture the answer is no: `main` has one commit the branch lacks.

**[ON SCREEN]** The traps table of section 18.8.

The traps, all documented. A skipped workflow: "If a workflow is skipped due to path filtering, branch filtering or a commit message, then checks associated with that workflow will remain in a 'Pending' state." The pull request waits for ever. A skipped job: "A job that is skipped will report its status as 'Success'." A required check can be green without having run. `[skip ci]` in the head commit: the workflow does not run, and required checks stay pending. The seven-day rule: a check name cannot be picked in the settings until it has completed successfully in the repository during the past seven days. The newest commit: every push and every "Update branch" starts over. The same name twice: if a check and a commit status have the same name, both must pass. The wrong event: checks from workflow jobs count only for runs triggered by a listed set of events. A green manual run on the branch satisfies nothing. The merge queue: its groups trigger a separate event. The wrong source: a check can be pinned to an expected GitHub App. And the row that makes pinning matter: "Any person or integration with write permissions to a repository can set the state of any status check." An unpinned required check can be satisfied by an API call.

Check names: for a workflow job the name is the job name, and required status checks do not take workflow, matrix or event trigger types into account. So make job names unique across all workflows. One caveat marked unverified: the exact check name a matrix job reports is not stated on these pages. Do not guess it. Read the names from a real run with `gh pr checks`, or from the merge box, and require what you read.

**[ANIMATION]** run: id=fix event=pull_request jobs=code-changed|build:code-changed|test:code-changed|final:build+test title=The_robust_pattern:_an_inference,_not_a_documented_recipe

The fix for the hook. The textbook calls it the robust pattern and is explicit that it is an inference from the documented rows, not a documented recipe. Let the workflow start on every pull request. Decide inside the workflow which jobs do real work. And require one final job that depends on the others, runs always, and fails if any of them failed or was cancelled. One stable name, never skipped at workflow level. The path optimization survives, as conditions on jobs.

**[ANIMATION]** end

Conversation resolution. Every review thread must be marked resolved before the merge. The control is weaker than it sounds: resolving a thread is a click, and the author may do it. The rule ensures that every thread was acknowledged, not that it was addressed.

**[ANIMATION]** walk: id=signed columns=merge_method,under_"Require_signed_commits" rows=merge_commit:works_if_every_head_commit_is_signed_and_verified|squash:blocked_by_unsigned_commits_on_the_head_branch|rebase:cannot_satisfy_the_rule marks=1.2:ok,2.2:bad,3.2:bad mono=off at_1=38 at_2=55 at_3=78 title=The_rule_looks_at_the_commits_the_pull_request_introduces

**[ANIMATION]** step: header

Signed commits. In one sentence: the rule accepts only commits with a verified signature on the target, and it is evaluated against the commits a pull request introduces, not only against the commit the merge creates.

**[ANIMATION]** step: 3

The part that surprises teams, in GitHub's words: "unsigned commits on the head branch can block a squash merge, even though GitHub would sign the final squash commit". So, method by method. Merge commit: works if every commit on the head branch is signed and verified. Squash: the result would pass, but unsigned commits on the head branch block the merge anyway. Rebase: cannot satisfy the rule. The documented workaround is to rebase and merge locally, and then push.

When not to use it: the rule proves that someone holding a registered key made each commit. It does not prove the commit is good, and it costs every contributor and every bot a key.

**[ANIMATION]** step: uptodate.merge

Linear history. The rule constrains what lands on the target, not the shape of the pull request branch. A branch that contains "Merge main into" commits, like this one with its new commit of two parents, is fine if it is squash-merged, because one ordinary commit lands. Under this rule the merge-commit method is not allowed.

**[ANIMATION]** end

Block force pushes, with GitHub's security argument: force pushing can "point a branch to commits that were not approved in a pull request". Without this rule, a required pull request can be undone after the fact. And restrict deletions keeps `main` and release branches from being deleted by a mistyped push.

## MENTAL MODEL

Think of the merge box as a form with one line per rule, and of each line as a question with a yes or no answer. The mistake people make is to read the form as a description of their work: "CI passed", "it was reviewed". The form does not describe work. Each line is a lookup. Is there a passing result under this name on this commit ID? Is there an approval that is still attached to the current diff? Does every commit in this range carry a verified signature?

**[ANIMATION]** stores: id=halves boxes=*Git_data:ancestry,_parents,_signatures,_paths|platform_records:what_only_GitHub_knows rows=1:A:branch_up_to_date|1:A:linear_history|1:B:required_approvals|1:B:conversation_resolution|2:B:status_checks:_yes,_no,_or_no_answer_yet@hl title=Sort_each_rule_into_one_of_two_halves

**[ANIMATION]** step: boxes

Half of those lookups you can do yourself, because their inputs are Git data: ancestry, parents, signatures, paths. The other half need the platform's records. Sorting each rule into one of the two halves is the skill of this video.

Try it now, thirty seconds, on paper. Two columns: Git data, and platform records. Sort these four: up to date, required approvals, linear history, conversation resolution. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: 1

Up to date and linear history are Git data. Approvals and conversations live in the platform's records.

**[ANIMATION]** step: 2

The model breaks for one rule: status checks. There the lookup has a third outcome besides yes and no: no answer yet. And "no answer yet" can last for ever.

**[ANIMATION]** end

## DIAGRAM

**[DIAGRAM]** Rules against what decides them, with the pre-flight command for the first kind.

```text
  rule                                   decided from             local pre-flight
  -------------------------------------  -----------------------  ---------------------------------------------
  branch up to date ("strict" checks)    Git data alone           git merge-base --is-ancestor origin/main HEAD
                                                                  git rev-list --left-right --count origin/main...HEAD
  mergeable (no conflict)                Git data alone           git merge-tree --write-tree --name-only origin/main HEAD
  linear history                         Git data alone           git rev-list --count --merges origin/main..HEAD
  signed commits                         Git data + GitHub keys   git log --format="%h %G? %s" origin/main..HEAD
  metadata restrictions (Enterprise)     Git data alone           git log --format="%h author=%ae committer=%ce" origin/main..HEAD
  code owners, reviewers by path,        Git data (the paths)     git diff --name-only origin/main...HEAD
    path filters                           + platform state
  required approvals, stale dismissal    platform state           (none: read the pull request)
  required status checks: results        platform state           (none: gh pr checks)
  conversation resolution                platform state           (none: read the pull request)
```

The top four rows are decided from Git data, and each has a command. Signatures need one qualification: your local verdict uses your local trust settings. "Verified" on GitHub needs the public key registered with the account.

The row for paths is a hybrid: Git gives you the list of changed paths, and the platform decides what that list triggers: which owners, which reviewers, and, for the hook, which workflows start.

The bottom three rows need the platform. No local command predicts an approval.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch18/merge-preflight
```

You are on `feature/priority-routing`, about to ask for a merge into `main`.

```bash
git fetch -q
git status -sb
```

<!-- snippet: ch18/merge-preflight/01-fetch -->
```text
$ git fetch -q
$ git status -sb
## feature/priority-routing...origin/feature/priority-routing
```
<!-- /snippet -->

Fresh information first. Every answer below is about `origin/main` as of this fetch.

```bash
git merge-base --is-ancestor origin/main HEAD
git rev-list --left-right --count origin/main...HEAD
```

**[PAUSE]** The rule is "require branches to be up to date". `main` gained one commit since you branched. What is the exit status of the first command?

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

Exit status 1: the tip of `main` is not an ancestor of the branch. The count says one commit only `main` has, three only the branch has.

**[ANIMATION]** merge: three-way origin/main into feature/priority-routing common=9a383e5 main_only=44c1e7b,12ae95d,16d4788 feature_only=1 cmd_merge=git_merge_-q_origin/main title=Pre-flight:_one_commit_behind,_three_ahead id=preflight

**[ANIMATION]** step: merge-base

Here are those counts as a picture, taken from the commit where the two histories diverged. Under strict checks, this pull request cannot merge yet, however green it is.

```bash
git merge-tree --write-tree --name-only origin/main HEAD
```

<!-- snippet: ch18/merge-preflight/03-conflicts -->
```text
# Mergeability: does the test merge succeed?
$ git merge-tree --write-tree --name-only origin/main HEAD
beff5a60b5d7f4a2b93e41130391fc485f5970e0
[exit status: 0]
```
<!-- /snippet -->

Mergeability: the test merge succeeds, exit status 0. No conflict. Next, linear history. Predict how many merge commits this pull request introduces. Say it out loud.

**[PAUSE]**

```bash
git log --format="%h parents=%p" origin/main..HEAD
git rev-list --count --merges origin/main..HEAD
```

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

The commits a rule inspects are those the pull request introduces: three, each with one parent. Merge commits among them: zero. Linear history is satisfied for any method that lands these commits.

```bash
git log --format="%h %G? %s" origin/main..HEAD
```

**[PAUSE]** The rule is "require signed commits", and the team merges by squash, which GitHub signs. These three commits are unsigned. Can the pull request merge?

<!-- snippet: ch18/merge-preflight/05-signatures -->
```text
# Rule: signed commits. %G? prints N for a commit without a signature:
$ git log --format="%h %G? %s" origin/main..HEAD
16d4788 N Fix the name of the escalations queue
12ae95d N Route high-priority tickets to escalation
44c1e7b N Add priority scoring
```
<!-- /snippet -->

`N` three times: no signature. And no: unsigned commits on the head branch block the squash merge, even though GitHub would sign the squash commit. The documented repair for unsigned commits already pushed is to rebase them to include a verified signature, then force push.

<!-- snippet: ch18/merge-preflight/06-metadata -->
```text
# Rules on commit metadata (Enterprise): author and committer addresses.
$ git log --format="%h author=%ae committer=%ce" origin/main..HEAD
16d4788 author=you@example.com committer=you@example.com
12ae95d author=you@example.com committer=you@example.com
44c1e7b author=you@example.com committer=you@example.com
```
<!-- /snippet -->

Author and committer addresses, for metadata rules on the Enterprise plan.

```bash
git diff --name-only origin/main...HEAD
```

<!-- snippet: ch18/merge-preflight/07-paths -->
```text
# Code owners, required reviewers by path, push rules and path filters all key on changed paths:
$ git diff --name-only origin/main...HEAD
router/classify.py
router/priority.py
```
<!-- /snippet -->

The changed paths, with three dots. Code owners, required reviewers by path, push rules and path filters all key on this list. For the pull request in the hook, this command would print one line, `README.md`, and you could read the workflow's `paths` filter against it and know that the workflow will not start.

Now fix "not up to date", variant 1.

```bash
git merge -q origin/main
git merge-base --is-ancestor origin/main HEAD
git rev-list --left-right --count origin/main...HEAD
git rev-list --count --merges origin/main..HEAD
```

**[PAUSE]** After merging `main` in: is the branch up to date, and what does the merge-commit count say now? Under a linear-history rule, can it still merge?

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

Up to date: exit status 0, and zero commits only `main` has.

**[ANIMATION]** step: preflight.merge

The branch now carries one merge commit. Under the linear rule this pull request can still be squash-merged, because the rule constrains what lands. Under the merge-commit method the rule would refuse it.

**[ON SCREEN]** GitHub walkthrough, Lab 23.3 Part B, in the normal shell, on the lab's starter repository with the ruleset of Lab 23.1. The interface changes; the lab text and GitHub's page on troubleshooting required status checks are the reference. No output is shown.

A third ruleset adds a required status check named `ci/unit`, strict. Nothing in the repository reports that check. It is created from a JSON file of the course. Read the file first, and remember the label on this call.

```bash
gh api --method POST "repos/$ORG/ticket-router-lab/rulesets" --input "$COURSE/labs/ch18/rulesets/lab-23-3-checks.json"
gh ruleset check main
```

Then the lab opens pull requests that cannot merge, each for a different reason, and you diagnose each by working from the rules to the cause. For the first case, a required check that nobody reports, look at the merge box: according to the documentation, the check is listed as expected and waiting for status to be reported. Then use the commands that read state:

```bash
gh pr checks
gh pr checks --required
gh ruleset check main
```

`gh pr checks` lists what has reported on the head commit. `gh ruleset check` lists what the rules require for the branch. The diagnosis is the difference between the two lists: a name that is required and that nothing has reported. The lab also demonstrates the last row of the traps table, that anyone with write permission can set the state of a status check. Do that step only in your own practice repository, as the lab says.

## COMMON MISTAKES

Five mistakes to watch for.

1. Requiring a check from a workflow with a path filter. Root cause: a workflow skipped by a path filter never reports, so its checks stay pending and the requirement cannot be met.
2. Trusting a green required check that came from a skipped job. Root cause: a skipped job reports success.
3. Expecting a squash merge to pass "Require signed commits" because GitHub signs the squash commit. Root cause: the rule is evaluated against the commits the pull request introduces, including unsigned commits on the head branch.
4. Updating the branch and being surprised that checks and approvals start over. Root cause: required checks must pass on the latest commit, and the diff changed.
5. Reading "resolved conversations" as "addressed feedback". Root cause: the pull request author can resolve threads; the rule proves acknowledgement only.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: hookci.result

Now, out of the lab. The README pull request from the hook. The team's CI workflow starts only for changes under `src/` and `tests/`, to save runner minutes on documentation changes. The ruleset on `main` requires the check `build` from that workflow. For three days the two settings contradict each other, and nobody sees it, because each looks correct alone.

**[ANIMATION]** step: fix.jobs

The fix keeps the saving. The workflow now starts on every pull request. A first job computes whether code changed. The build and test jobs run only if it did. They are skipped by a condition otherwise. A final job depends on all of them, runs always, and fails if any job that ran has failed or was cancelled. The ruleset requires that one final job, by its name, and the team pins the check to the expected source app, because an unpinned check can be set by anyone with write permission.

**[ANIMATION]** end

They state in the design note what the textbook states: this pattern is an inference from the documented behaviour of skipped workflows and skipped jobs, not a GitHub recipe. The Actions videos build it.

## PRACTICE EXERCISE

Your turn. Do Exercise 23.3, "Review this ruleset", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). For each rule and sub-option in the ruleset you are given, write down the loophole it closes and the cost it adds, and mark every place where two settings can contradict each other, as the path filter and the required check did.

The challenge is Exercise 23.6, "Four pull requests that will not merge", in the same file. Diagnose each from the rules to the cause, with the pre-flight commands where they apply.

## INTERVIEW QUESTION

Question 249 of the CTO question bank:

> "A required check stays pending forever on documentation-only pull requests. Explain the cause and design a fix that keeps the path optimization."

**[PAUSE]**

Answer out loud. A strong answer states what the rule actually tests, in terms of names and commits, and why "never started" is different from "failed". It distinguishes a skipped workflow from a skipped job, with the status each reports. The design it proposes moves the decision inside the workflow, requires one stable name, and says what protects that name. It is clear about which part is documented and which is a design inference.

## RECAP

Let's land this. A blocked merge is a list of lookups, and you can now run half of them before you open the merge box.

You should now be able to say:

- The pull request rule has sub-options that each close one loophole: approvals, stale dismissal, last-push approval, code owners, dismissal restrictions, conversations, merge methods, reviewers by path.
- Required status checks are matched by name on the newest commit; a skipped workflow stays pending and a skipped job reports success.
- "Up to date" means the tip of the base is an ancestor of the head.
- Signed commits are checked on the commits a pull request introduces; rebase and merge cannot satisfy the rule; linear history forbids merge commits on the target.
- Ancestry, conflicts, merge commits, signatures and paths can be checked locally before you ask for the merge.

## HOMEWORK

Read sections 18.6 to 18.11 of [Chapter 18](../../textbook/ch18-branch-protection.md).

That was the densest list in this module, and you got through it. Practise with Exercise 23.3. Next: tag rulesets, push rulesets, and classic branch protection. Until then, look at the state first and type second. See you in the next one.
