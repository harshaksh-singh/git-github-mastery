# V134: Seeing and managing rules, "why can't I merge?", and a worked design for a production branch

- **Part.** 5: GitHub
- **Module.** 23
- **Planned minutes.** 24
- **Prerequisites.** V133
- **Textbook sections.** [Chapter 18](../../textbook/ch18-branch-protection.md), sections 18.16 to 18.21
- **Demo scripts.** `labs/ch18/lab-23-3-preflight.sh` (up to its checkpoint), then a screen walkthrough of Lab 23.3 in [`lab-manual/m23-governance.md`](../../lab-manual/m23-governance.md)

## HOOK

**[ON SCREEN]** A pull request page. Every check is green. One approval. The merge button is grey.

A developer writes in the team channel: "Everything is green and I still cannot merge." Three people answer with three guesses. One says to push an empty commit. One says to ask an administrator. One says to wait. Which of the three would you follow? Say it out loud.

**[PAUSE]**

**[ANIMATION]** cards: id=guess question=Everything_is_green_and_I_still_cannot_merge cards=push_an_empty_commit|ask_an_administrator|wait|which_rules_apply_to_this_branch?|which_Git_fact_does_each_rule_look_at? marks=1:dim,2:dim,3:dim,4:ring,5:ring at_1=0 at_2=4 at_3=8 at_4=26 at_5=34 at_marks=42

Whichever you chose, notice what's missing. None of them asked the two questions that end the discussion in five minutes: which rules apply to this branch, and which Git fact does each rule look at. In this video you learn where the rules are visible, how to ask Git the questions the rules ask, and how to defend a set of rules for a branch that deploys to production. Keep that grey button in mind. It gets its answer in nine steps.

## INTRODUCTION

**[ANIMATION]** end

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last videos you learned what a rule is: a check on a ref update, evaluated by GitHub and not by Git. A ref is a name, such as a branch or a tag, that holds the ID of a commit. A ruleset is a named list of rules with a target, an enforcement status and a bypass list. You know that rulesets layer, that every applicable rule applies, and that a classic branch protection rule, the older mechanism, can sit beside a ruleset.

This video turns that knowledge into a working procedure, in three parts. First, how you see the rules: the rules page, the `gh ruleset` commands, and the REST API. Second, the nine-step procedure of section 18.17 for a blocked merge, and its mirror case, "why could they merge?". A pull request is GitHub's proposal to merge a head branch into a base branch. Third, a worked design: one ruleset for a production branch, with the reason for each rule and what each rule costs.

The local demonstration replays the first half of Lab 23.3 in the lab sandbox. The second half is a walkthrough on your own practice repository.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- find every rule that applies to a branch from the `/rules` page and from the command line;
- explain why `gh ruleset` is read-only and how rulesets are changed through the API;
- follow the procedure for "everything is green and I still cannot merge";
- diagnose three blocked merges on the practice repository;
- defend each rule of the worked production-branch design and name its cost.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub.

Start with why. A blocked merge is a refusal by GitHub to update a ref. The refusal has a cause, the cause is one specific rule, and that rule looks at one specific thing. If you guess, you change things that weren't the cause. And on a branch where a new push dismisses earlier approvals as stale, every extra push costs you a review. So the order is evidence first: which rules apply, which one says no, and to what.

**[ANIMATION]** cards: id=see question=Anyone_with_read_access_can_view_the_active_rulesets cards=the_Rulesets_page:from_the_branch_list|the_merge_box:rules_that_block_the_merge|/rules:added_to_the_repository_address|classic_branch_protection_rules ask=4 marks=4:lock at_1=36 at_2=50 at_3=80 at_4=25 at_marks=3

**[ANIMATION]** step: 3

**Seeing the rules.** The textbook quotes the documentation: "Anyone with read access to the repository can view the active rulesets." There are three documented places. The first is the Rulesets page that you reach from the branch list. The second is the merge box of a pull request, the panel with the merge button, which shows rules, in the words of the documentation, "if there are rules blocking the merging of a pull request". The third is the address of the repository with the slug `/rules` added.

**[ANIMATION]** step: 4

Quick quiz, from the last video. Are classic branch protection rules on that page too? A, yes, for anyone with read access. B, no. Your answer?

**[PAUSE]**

**[ANIMATION]** step: marks

B. Classic branch protection rules aren't on that page. They're under the repository settings, Branches, and only administrators see them. Keep that sentence in mind, because it explains a whole class of "I cannot see why".

**[ANIMATION]** end

**The command line.** The GitHub CLI is a client for GitHub's API, the interface that programs use to talk to GitHub, and its command is `gh`. It has a `gh ruleset` family, and that family is read-only. Its own help says: "These commands allow you to view information about them." In version 2.88.1 there are three subcommands: `list`, `view` and `check`.

**[ON SCREEN]** The six commands of section 18.16.

```bash
gh ruleset list                       # rulesets of the current repository, including inherited ones
gh ruleset list --org ORG             # organization rulesets (needs the admin:org scope)
gh ruleset view 123456                # one ruleset by ID; --web opens it in the browser
gh ruleset check main                 # every rule that applies to a branch name
gh ruleset check release/2.0          # the branch "does not need to exist"
gh ruleset check --default
```

All of these are 🟢 SAFE: they change nothing. The one to remember is `gh ruleset check`. You give it a branch name, the branch doesn't need to exist, and it lists every rule that would apply. That's the answer to the silent-pattern problem of section 18.3: you ask which rules apply to a name before you trust a pattern.

**Changing rules.** Creating and changing a ruleset goes through the REST API, with `gh api`. The ruleset travels as JSON, a text format for structured data. The textbook lists the documented endpoints, the addresses of the API, and says that none of them was executed by the authors.

```bash
gh api repos/ORG/REPO/rulesets                               # list
gh api --method POST repos/ORG/REPO/rulesets --input ruleset.json     # create
gh api repos/ORG/REPO/rulesets/123456                        # read one, as JSON
gh api --method PUT repos/ORG/REPO/rulesets/123456 --input ruleset.json
gh api --method DELETE repos/ORG/REPO/rulesets/123456
gh api repos/ORG/REPO/rules/branches/main                    # active rules for one branch
gh api repos/ORG/REPO/rulesets/rule-suites                   # evaluations: passed, failed, bypassed
gh api repos/ORG/REPO/branches/main/protection               # the classic rule, if any
```

The read calls are 🟢 SAFE. Every call with `POST`, `PUT` or `DELETE` is 🔴 DANGEROUS. Here are the five answers for the three of them. What they change: a `POST` creates a ruleset, and if it's Active it binds everyone at once, you included. A `PUT` replaces the settings of a ruleset. A `DELETE` removes the protection for every ref the ruleset targeted, immediately.

**[ANIMATION]** walk: id=calls columns=call,what_it_changes,what_it_can_destroy rows=POST:creates_a_ruleset:nothing|PUT:replaces_the_settings:the_previous_settings|DELETE:removes_the_protection:nothing_directly marks=2.3:bad,3.3:wait mono=off title=Three_calls_that_write at_1=4 at_2=44 at_3=80

**[ANIMATION]** step: 3

What they can destroy: the `POST` destroys nothing, and carries the label because, as Chapter 15 says, the call does whatever the endpoint and the JSON say, with all your permissions. The `PUT` destroys the previous settings, which exist nowhere else unless you saved the JSON, because ruleset history exists only on Enterprise. The `DELETE` destroys nothing directly. It makes force pushes and deletions possible.

**[ANIMATION]** say: Before_a_PUT_or_a_DELETE:_read_the_ruleset_with_a_GET_and_keep_the_JSON

How to preview: create with enforcement disabled and run `gh ruleset check`. Before a `PUT` or a `DELETE`, read the ruleset with a `GET` and keep the JSON. How to recover: set enforcement to disabled, `PUT` the saved JSON back, or re-create from the saved JSON. When it's appropriate: for rules kept as reviewed JSON, and for a deletion, in a planned migration or a declared emergency, by a named person, with the reason written where the audit will find it.

**[ANIMATION]** end

Two details about the read endpoints. "Get rules for a branch" returns, in the documentation's words, "all active rules that apply to the specified branch", from every level, and it leaves out rulesets that are disabled or in evaluate mode. And the `bypass_actors` field is returned only to callers with write access to the ruleset.

Rulesets can be exported and imported as JSON in the web interface. Keeping that JSON in a repository gives you review and history for the rules themselves. The bypass list is excluded from the Enterprise history export, so you record it separately.

**Rule Insights** lists ref updates that passed, failed or bypassed rulesets, and the `rule-suites` endpoint returns the same data. It's your evidence for the question "would we know if someone skipped the rules", with one exception: exempt actors, from section 18.5, leave no entry.

## MENTAL MODEL

**In one sentence**, in the textbook's words: work from the outside in. What the merge box says, which rules apply to the base branch from every layer, then one local Git question per rule.

**[ANIMATION]** stores: id=lanes boxes=ask_GitHub:platform_state|ask_Git:facts_of_the_commit_graph rows=1:A:reviews|1:A:checks|1:A:conversations|1:A:allowed_merge_methods|1:A:bypass|2:B:is_the_branch_behind?|2:B:does_the_test_merge_conflict?|2:B:are_there_merge_commits?|2:B:are_the_commits_signed?|3:B:a_clone_contains_no_rulesets@bad title=Two_lanes at_1=9 at_2=37

**[ANIMATION]** step: 2

Think of it as two lanes. In one lane you ask GitHub about platform state: reviews, checks, conversations, the allowed merge methods, bypass. In the other lane you ask Git about facts of the commit graph: is the branch behind, does the test merge conflict, are there merge commits, are the commits signed. Many rules are a platform decision about a Git fact, and the Git fact you can compute yourself, offline, in a clone.

**[ANIMATION]** step: 3

The model breaks in one place, and you should say so when you explain it. Git can tell you whether a fact holds. Git can't tell you whether a rule exists. A clone contains no rulesets. So the Git lane never replaces the first two steps.

**[ANIMATION]** end

Try it now, thirty seconds, on paper. Draw two columns, "ask GitHub" and "ask Git". Sort these four into them: reviews, conflicts, required checks, merge commits. Say your answer out loud.

**[PAUSE]**

**[ANIMATION]** say: Reviews_and_required_checks:_ask_GitHub._Conflicts_and_merge_commits:_ask_Git

Reviews and required checks go under GitHub: they're platform state. Conflicts and merge commits go under Git: they're facts of the commit graph, and you can compute them offline, in a clone, your own copy of the repository.

**[ANIMATION]** stores: id=nine boxes=ask_GitHub:platform_state|ask_Git:in_a_clone,_after_git_fetch rows=1:A:1_merge_box,_gh_pr_view,_gh_pr_checks|2:A:2_every_rule_on_the_base_branch|3:B:3_conflicts:_git_merge-tree|4:B:4_up_to_date:_git_merge-base|5:A:5_checks:_a_result_on_the_newest_commit?|6:A:6_reviews:_approvals_after_the_last_change|7:B:7_commits:_git_log,_git_rev-list|8:A:8_method:_allowed_AND_enabled|9:A:9_you:_write_permission,_not_a_draft arrows=3:A2>B1:a_Git_fact|7:A4>B3:a_Git_fact title=Nine_steps_for_a_blocked_merge

**[ANIMATION]** step: boxes

Here are the nine steps.

**[ANIMATION]** step: 1

One: read the merge box and the CLI's view. `gh pr view` with the JSON fields `mergeable`, `mergeStateStatus` and `reviewDecision`, and `gh pr checks` with `--required`. `mergeable` is `MERGEABLE`, `CONFLICTING` or `UNKNOWN`, and `UNKNOWN` means not computed yet: ask again. `mergeStateStatus` has values such as `BEHIND`, `BLOCKED`, `DIRTY`, `DRAFT`, `UNSTABLE` and `CLEAN`. `BLOCKED` says that a rule is unmet. It doesn't say which one. The remaining steps find it.

**[ANIMATION]** step: 2

Two: list every rule on the base branch. `gh ruleset check` with the base branch name, or the `/rules` page, then the classic rule, then remember the organization level.

**[ANIMATION]** step: 3

Three: conflicts. Fetch, then `git merge-tree --write-tree --name-only`. Exit status 1 names the files.

**[ANIMATION]** step: 4

Four: up to date, for strict checks. Strict means the tested commit must include the current base branch. `git merge-base --is-ancestor` with the base and your HEAD. If the base isn't an ancestor, you update the branch, and then you expect the checks to run again and stale approvals to be dismissed.

**[ANIMATION]** step: 5

Five: checks. For each required name, is there a result on the newest commit? Pending forever means a skipped workflow, a wrong name, or a wrong event.

**[ANIMATION]** step: 6

Six: reviews. Count approvals from people with write access given after the last change of the diff. Look for an outstanding "changes requested", a missing code owner, an approval by the last pusher, unresolved threads, a twin pull request on the same commit.

**[ANIMATION]** step: 7

Seven: commits. Which commits would land, and do they satisfy the commit-level rules: signatures, merge commits under linear history, and under Enterprise metadata rules the author and committer addresses.

**[ANIMATION]** step: 8

Eight: method. Is the method you chose allowed by the ruleset and also enabled in the repository settings?

**[ANIMATION]** step: 9

Nine: you. Do you have write permission, and is the pull request still a draft?

**[ANIMATION]** say: Still_grey?_A_rule_you_cannot_see:_organization,_enterprise,_or_classic

If everything passes and the button is still grey, a rule you can't see is the likely cause: an organization or enterprise ruleset, or a classic rule visible only to administrators. Ask an administrator for the output of step two.

## DIAGRAM

**[DIAGRAM]** Build the two lanes from left to right. Draw step 1 and step 2 first, in the GitHub lane, and say that nothing in the Git lane is worth running before you know which rules exist. Then add the Git lane one box at a time, each under the rule it answers.

```text
  ask GitHub                                              ask Git (in a clone, after git fetch)
  ----------                                              -------------------------------------
  1 merge box, gh pr view --json, gh pr checks --required
        |
  2 every rule on the base branch:
    gh ruleset check <base>, /rules, classic rule, organization
        |
        +------------------------------------------->  3 conflicts:   git merge-tree --write-tree --name-only
        |                                              4 up to date:  git merge-base --is-ancestor
  5 checks: a result on the NEWEST commit?
  6 reviews: approvals after the last change,
    code owner, last pusher, threads
        |
        +------------------------------------------->  7 commits:     git log origin/<base>..HEAD
        |                                                             git rev-list --count --merges
  8 method: allowed by the ruleset AND enabled in settings
  9 you: write permission; not a draft
        |
  still grey?  a rule you cannot see: organization, enterprise, or classic
```

The nine steps as one picture: GitHub's questions on the left, Git's on the right.

**[DIAGRAM]** Point at the two arrows. Each arrow is a moment where the platform's decision rests on a fact you can compute yourself.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch18/lab-23-3-preflight`. The caption bar shows the script name and the snippet name. The lab clock is fixed, so the commit IDs on your screen equal the ones in the book.

Into the lab. The situation: a repository called `ticket-router` on a local bare server, a repository with no working tree that plays the server in this demo. Three branches are open as if they were pull requests: `feature/priority-routing`, which is yours, and `fix/threshold` and `docs/queues`, which are Ravi's. Your local `main` is one commit behind the server.

**Step 1.** Read the tool before you trust it, then fetch.

```bash
cat preflight.sh
cd you/ticket-router
git fetch
```

`git fetch` is 🟢 SAFE: it adds objects and moves remote-tracking refs. Before the output appears, read the script aloud. It asks four questions about a branch, each with one command you know: how many commits the pull request introduces, whether `origin/main` is an ancestor of the branch, whether a test merge is clean, and how many merge commits are among the introduced commits.

<!-- snippet: ch18/lab-23-3-preflight/01-observe -->
```text
$ cat preflight.sh
#!/bin/sh
# usage: sh preflight.sh <branch>     (run inside a clone, after git fetch)
b="origin/$1"
echo "== $1 -> main"
echo "commits in the pull request: $(git rev-list --count origin/main..$b)"
if git merge-base --is-ancestor origin/main "$b"; then echo "up to date with main: yes"; else echo "up to date with main: no"; fi
if git merge-tree --write-tree origin/main "$b" > /dev/null; then echo "test merge: clean"; else echo "test merge: conflict"; fi
echo "merge commits among them: $(git rev-list --count --merges origin/main..$b)"
$ cd you/ticket-router
$ git fetch
From ../../server/ticket-router
 * [new branch]      docs/queues   -> origin/docs/queues
 * [new branch]      fix/threshold -> origin/fix/threshold
   9a383e5..9aa221a  main          -> origin/main
```
<!-- /snippet -->

Look at the last line of the fetch output. `origin/main`, your clone's record of the server's `main`, moved from `9a383e5` to `9aa221a`. Every answer from here on is about the server's `main`, not about your local `main`.

**Step 2.** Run the script for each branch.

```bash
sh ../../preflight.sh feature/priority-routing
sh ../../preflight.sh fix/threshold
sh ../../preflight.sh docs/queues
```

Predict first. The main branch requires linear history, which means no commit with two parents, and strict, up-to-date checks. For each branch, which line of the report would make GitHub refuse? Say it out loud.

**[PAUSE]**

<!-- snippet: ch18/lab-23-3-preflight/02-preflight -->
```text
$ sh ../../preflight.sh feature/priority-routing
== feature/priority-routing -> main
commits in the pull request: 3
up to date with main: no
test merge: clean
merge commits among them: 0
$ sh ../../preflight.sh fix/threshold
== fix/threshold -> main
commits in the pull request: 1
up to date with main: no
test merge: conflict
merge commits among them: 0
$ sh ../../preflight.sh docs/queues
== docs/queues -> main
commits in the pull request: 2
up to date with main: yes
test merge: clean
merge commits among them: 1
```
<!-- /snippet -->

Read it one branch at a time. Your branch: three commits, a clean test merge, no merge commits, and "up to date with main: no". Under a strict status check policy that one line blocks it. Ravi's `fix/threshold`: not up to date, and the test merge reports a conflict. `docs/queues`: up to date, clean, and one merge commit among its two commits. Under a linear history rule that's the line that matters.

**[ANIMATION]** walk: id=report columns=branch,commits,up_to_date,test_merge,merge_commits rows=feature/priority-routing:3:no:clean:0|fix/threshold:1:no:conflict:0|docs/queues:2:yes:clean:1 marks=1.3:bad,2.3:bad,2.4:bad,3.5:bad title=Three_branches,_three_different_answers pace=quick

Three branches, three different answers, and no browser has been opened.

**[ANIMATION]** say: Step_3:_the_details_for_the_two_that_aren't_yours

**Step 3.** Get the details for the two that aren't yours.

```bash
git merge-tree --write-tree --name-only origin/main origin/fix/threshold
git log --oneline --graph origin/main..origin/docs/queues
```

What will the first command print besides a tree ID? Make your prediction.

**[PAUSE]**

<!-- snippet: ch18/lab-23-3-preflight/03-details -->
```text
$ git merge-tree --write-tree --name-only origin/main origin/fix/threshold
338b4c977614aa8150cf3cd62cccc9e602b65770
config/routing.yaml

Auto-merging config/routing.yaml
CONFLICT (content): Merge conflict in config/routing.yaml
$ git log --oneline --graph origin/main..origin/docs/queues
* 9042b9e Merge main into docs/queues
* 4e570dc List the queues in the README
```
<!-- /snippet -->

The first command wrote a tree, `338b4c9`, and named the conflicted file: `config/routing.yaml`. A tree is Git's object for one directory listing. Nothing in your working tree or index changed. `merge-tree` works on objects only.

**[ANIMATION]** graph: id=dq ...3-9a383e5-9aa221a origin/main; ^9a383e5-4e570dc-9042b9e origin/docs/queues; 9aa221a-9042b9e; HEAD=none; note:4e570dc:List_the_queues_in_the_README; note:9042b9e:Merge_main_into_docs/queues; say:git_log_--oneline_--graph_origin/main..origin/docs/queues => + mark:merge_commit:9042b9e; name:verdict; say:Up_to_date_with_main:_yes._Merge_commits_among_them:_1 dx=250 at_state_1=18

**[ANIMATION]** step: state-1

The second command shows why `docs/queues` has a merge commit: `9042b9e`, "Merge main into docs/queues". Ravi brought the branch up to date by merging `main` into it.

**[ANIMATION]** step: verdict

That satisfied the up-to-date rule and broke the linear history rule in the same step. Leave the question of how `docs/queues` could still be merged for the lab's checkpoint.

**[ANIMATION]** end

The replay continues with a failure scenario and a recovery. Stop here. Those belong to your own run of the lab.

**[ON SCREEN]** Lower third: GitHub. Screen walkthrough.

Now the platform side, on your own practice repository, following Part B of Lab 23.3. The GitHub interface changes. The text of the lab and the linked documentation are the reference, and the authors captured no GitHub output. Run this part in your normal shell, not in `labs/shell`, because the lab shell switches off the system configuration where the credential helper lives.

The lab adds a third ruleset that requires a status check named `ci/unit`, strict. Nothing in the repository reports that check.

```bash
gh api --method POST "repos/$ORG/ticket-router-lab/rulesets" --input "$COURSE/labs/ch18/rulesets/lab-23-3-checks.json"
gh ruleset check main
```

This `POST` is the 🔴 DANGEROUS call whose five answers you heard in the concept section. On a practice repository that only you use, it's appropriate.

Open the address of your practice repository with `/rules` added. You should find the rulesets that are active, and for each the rules it contains. Then compare with what `gh ruleset check main` lists.

Case A is a pull request whose required check nobody reports. Open it in the browser and look at the merge box. According to the documentation the box names the rule that blocks the merge. Then ask the CLI:

```bash
gh pr checks --required
gh pr view --json mergeable,mergeStateStatus,reviewDecision
```

Name what you see by its function: the list of required checks GitHub is waiting for, and the merge state. Case B moves `main` while case A is open, so that case A is no longer up to date. The lab has you confirm that with `git merge-base --is-ancestor` before you touch anything. Case C leaves no merge method: the ruleset and the repository settings no longer agree on one. For each case, open the rules page first, name the rule, and only then repair.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Relaxing one ruleset and expecting the block to go away.** Root cause: a second ruleset, an organization ruleset, or a classic rule also applies, and every applicable rule applies.
2. **Waiting for a check that says "Waiting for status to be reported".** Root cause: the workflow was skipped by a path or branch filter or `[skip ci]`, or the required name is wrong, or the run used an event that does not count.
3. **Treating an approval as permanent.** Root cause: the approval was dismissed as stale, or was given by the last pusher, or a code owner is missing, or another reviewer requested changes.
4. **Allowing only one merge method in the ruleset and disabling that method in the repository settings.** Root cause: both layers must permit the method, and they are configured in different places.
5. **Trusting a new branch pattern without testing it.** Root cause: `*` does not cross a slash, so the pattern matches fewer names than you meant; `gh ruleset check` with the branch name shows it.

## PRODUCTION EXAMPLE

**[ON SCREEN]** The ruleset JSON of section 18.18, then the table of choices.

Now, out of the lab. The textbook's worked design is for a service called `inventory-api`. It deploys from `main` on every merge. Six engineers, pull requests of a few hundred lines, and CI, the automated tests that run on each change, of about eight minutes. An ML platform team owns the deployment workflow. The team has decided on squash merges, where each pull request lands as one new commit. The textbook says this is one defensible design for that context, and that another team should make other choices. The ruleset file was assembled from the documented schema and syntax-checked. The author didn't send it to GitHub.

**[ANIMATION]** walk: id=design columns=rule,cost rows=target_~DEFAULT__BRANCH:protects_one_branch_only|no_deletions,_no_force_pushes:undo_by_revert,_never_by_reset|linear_history,_squash_only:reviewed_IDs_are_not_the_commit_on_main|1_approval,_stale_ones_dismissed:re-approval_after_each_update|approval_of_the_last_push:-|code_owner_review:a_bottleneck_if_the_file_is_too_broad|1_required_check,_strict:some_waiting|empty_bypass_list:an_emergency_needs_a_recorded_edit|no_signed-commit_rule:- mono=off title=inventory-api:_each_rule_and_its_cost at_1=12 at_2=55 at_5=33 at_6=58 at_8=45 at_9=70

**[ANIMATION]** step: 2

Walk through the choices with their costs. The target is `~DEFAULT_BRANCH`, which survives a rename and has no pattern to get wrong. The cost is that it protects one branch only. Deletions and force pushes are blocked, because `main` is deployed and its history is an audit record. The cost is that a bad merge is undone by a revert, never by a reset.

**[ANIMATION]** step: 3

Linear history with squash only gives one commit per pull request and trivial reverts. The cost is that the reviewed commit IDs aren't the commit on `main`.

**[ANIMATION]** step: 6

One approval with stale approvals dismissed means nothing lands unseen. The cost is re-approval after each update. Approval of the last push covers a reviewer who pushes a fix and approves it. Code owner review is on because the deployment workflow has named owners. Owners become a bottleneck if the file is too broad.

**[ANIMATION]** step: 9

One required check, strict, means the tested commit includes current `main`. With eight-minute CI and a few merges a day that costs some waiting, and the textbook names a merge queue as the alternative when updates start to race. The bypass list is empty, so administrators follow the same path, and an emergency needs a deliberate, recorded edit of the ruleset. There's no signed-commit rule, because squash commits are signed by GitHub anyway and requiring signatures on head branches would block contributors without keys.

**[ANIMATION]** end

Then the two things this ruleset doesn't do. It doesn't protect release tags. That's a tag ruleset. And it doesn't stop a required check from being reported by anyone with write access. For that you pin the check to its GitHub App with `integration_id`.

**[ANIMATION]** gates: id=roll gates=Disabled:done|gh_ruleset_check_main:done|a_test_pull_request:done|Active:done title=Rolling_it_out

Rolling it out: create it Disabled, run `gh ruleset check main` and read the result, open a test pull request, then switch to Active.

## PRACTICE EXERCISE

**[ANIMATION]** end

Your turn. Do Lab 23.3, "Three blocked merges to diagnose", in [`lab-manual/m23-governance.md`](../../lab-manual/m23-governance.md). Part A runs in `labs/shell`. The clock is real there, so your commit IDs differ from the ones in this video. Part B runs in your normal shell on your practice repository.

Before you run anything in Part A, write down for each of the three branches which rule of Chapter 18 would refuse it. Before each repair in Part B, write down which rule blocks, and what GitHub will require again after your repair. Then check your prediction against what you see.

The challenge is Exercise 23.7, "Protect a monorepo", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q253: "Walk through your procedure when a developer says "everything is green and I still cannot merge"."

**[PAUSE]**

Answer out loud first. A strong answer has an order, and says why the order is that way. It starts with evidence from the platform, not with a repair. It names every layer where a rule can live, including the ones the developer can't see. For each rule it names the Git fact the rule inspects and the command that computes that fact locally. It mentions what an update of the branch costs under strict checks and stale-approval dismissal. And it's ready for the follow-up, the mirror case: how a colleague was able to merge without meeting the rules. Say which layer acts in every sentence: Git or GitHub.

## RECAP

**[ANIMATION]** step: nine.9

Let's land this. The grey button from the opening has its answer: read the merge box, list every rule from every layer, then ask Git one question per rule.

You should now be able to say:

- Anyone with read access can see the active rulesets on the `/rules` page; classic rules are visible only to administrators, and disabled rulesets are not on that page.
- `gh ruleset` only reads; rulesets are created and changed through the REST API, and every such call that is not a `GET` is labelled dangerous.
- A blocked merge is diagnosed from the outside in: the merge box, every rule from every layer, then one Git question per rule.
- `BLOCKED` says that a rule is unmet, and not which one.
- Every rule in a production ruleset has a cost, and you can name it.

## HOMEWORK

Read sections 18.16 to 18.21 of [Chapter 18](../../textbook/ch18-branch-protection.md) and do the Practice section 18.23.

Today you turned "why can't I merge" from three guesses into one procedure, and you can name what each rule of a production ruleset costs. Practise the four preflight questions on a branch of your own before the next video. Next time: CODEOWNERS, what it is, where it lives, its syntax, and why the last match wins. Until then, look at the state first and type second. See you in the next one.
