# V136: CODEOWNERS in force: the base branch decides, protecting the file, monorepos, required reviewers, and finding out what GitHub thinks

- **Part.** 5: GitHub
- **Module.** 23
- **Planned minutes.** 22
- **Prerequisites.** V135
- **Textbook sections.** [Chapter 19](../../textbook/ch19-codeowners.md), sections 19.7 to 19.14
- **Demo scripts.** `labs/ch18/codeowners-base.sh`, `labs/ch18/lab-23-2-codeowners.sh`, then a screen walkthrough of Lab 23.2 in [`lab-manual/m23-governance.md`](../../lab-manual/m23-governance.md)

## HOOK

**[ON SCREEN]** A pull request with four changed files. One of them is `.github/CODEOWNERS`, and the diff removes one line.

A developer wants a documentation change merged today, and the docs team is slow. So the same pull request also deletes the docs team's line from CODEOWNERS, the file that maps path patterns to the users and teams whom GitHub asks for review. The reasoning: if the team is no longer an owner, the team is no longer required. Does that work? Say yes or no, out loud.

**[PAUSE]**

No. If it did, every required reviewer could be removed by the person who needs the review. In this video you see why it doesn't work, which Git command tells you so before you open the pull request, and what you have to configure so that the file that names the reviewers is itself protected. Watch for the moment in the terminal where that deleted line is still there.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you learned what a CODEOWNERS file says: patterns, owners, last match wins. This video is about the file in force. Five topics, in the order of sections 19.7 to 19.11. Which version of the file applies to a pull request. How you protect the file itself and the workflows directory. How to lay out ownership in a monorepo, one repository that holds many projects. The newer "required reviewers" rule and when it complements CODEOWNERS. And three documented instruments that tell you how GitHub read your file.

The local demonstration answers every question that a clone can answer. The enforcement itself happens on GitHub, and you'll prove it in Lab 23.2 with a second account.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- say from which branch the CODEOWNERS file is read for a pull request and why that matters;
- explain why a pull request cannot remove its own required reviewer by editing the file;
- protect CODEOWNERS and the workflows directory and name the conditions that make the protection real;
- lay out ownership for a monorepo and decide when the "required reviewers" rule replaces or complements CODEOWNERS;
- check the file for errors before merging a change to it.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub.

**The base branch decides. In one sentence:** a pull request is judged by the CODEOWNERS file on its base branch, so a pull request that edits CODEOWNERS is reviewed under the old file.

**[ANIMATION]** stores: id=two boxes=base_branch:the_state_everyone_already_agreed_to|head_branch:written_by_the_person_asking_for_the_merge rows=1:A:CODEOWNERS|2:B:CODEOWNERS,_edited@hl|3:A:review_requests_use_this_version@ok|4:B:the_edit_applies_one_merge_later@dim arrows=3:B>A:pull_request title=Which_copy_decides? at_1=8 at_2=30 at_3=55

**[ANIMATION]** step: 3

Two words first. The base branch is the branch a pull request asks to merge into, and the head branch holds the commits it offers. The documentation: "To trigger review requests, pull requests use the version of `CODEOWNERS` from the base branch of the pull request." For a pull request from a fork, a second repository on GitHub connected to the one it was made from, into upstream, that's upstream's file. In a stack of pull requests, where each targets the branch of the one below, CODEOWNERS is, in the documentation's words, "evaluated from the stack base".

Why is it designed like this? Because the alternative has no security value. The head branch is written by the person asking for the merge. If their copy of the file decided, the control would be in the hands of the person it's meant to check. The base branch is the state everyone already agreed to.

**[ANIMATION]** step: 4

There's a second consequence that people meet more often than the first: a fix to CODEOWNERS takes effect one merge later than they expect. The pull request that carries the fix is still judged under the old file.

**[ANIMATION]** end

**Protecting the file. In one sentence:** the file that names the reviewers, and the directory that defines what automation runs, need owners themselves, or anyone with write access can change both in one pull request.

GitHub's advice, quoted in the textbook: "To protect a repository fully against unauthorized changes, you also need to define an owner for the CODEOWNERS file itself." The most secure method, according to the documentation, is to keep the file in the `.github` directory and to define an owner either for the file or for the whole directory.

Owning the whole `.github/` directory also covers `.github/workflows/`. A workflow file, the YAML file that tells GitHub Actions what to run, decides what runs with the repository's token and secrets, so a change to it is a change to your deployment and security posture. Part 7 of this course is about that.

**[ANIMATION]** cards: id=cond question=When_is_the_line_/.github/_a_real_control? cards=the_line_comes_last:no_later_pattern_such_as_*.yaml|a_rule_requires_owner_review:on_the_default_branch|the_owning_team:holds_explicit_write_access marks=1:ok,2:ok,3:ok at_1=8 at_2=42 at_3=64 at_marks=80

Three conditions make the protection real. The line must come last, so that no later pattern such as `*.yaml` takes workflow files away. The code-owner option must be required by a rule on the default branch. And the owning team must hold explicit write access. If one of the three is missing, you have a line in a file and no control.

**[ANIMATION]** end

**Monorepos. In one sentence:** in a monorepo the file is the map of the organization, and its order has to follow the rule "general first, specific last".

**[ON SCREEN]** The four-block layout of section 19.9.

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

Four blocks. A default, so that somebody always owns a new directory. One block per component, anchored at the root. Then the cross-cutting file types that must override the components. And last, the files that control review and automation.

Use the directory form for subtrees, because `dir/*` covers one level only. Anchor component paths with a leading slash, or `router/` also matches a directory of that name inside another component. Prefer teams to people, so that ownership survives holidays and departures. And one caveat that the textbook attaches to block three: the patterns with two stars follow the gitignore rules and aren't among GitHub's documented examples, except `**/logs`. Confirm them with the instruments at the end of this section.

Quick quiz. You need both the routing team and the data team to approve one path. Where does that requirement go? A, both teams on one CODEOWNERS line. B, a different rule. Your answer?

**[PAUSE]**

B, a different rule. What the file can't express: "both teams must approve", "two members of this team", or "everyone except this directory". The first two belong to the next rule. The third has only the documented workaround of an owner-less line.

**The required reviewers rule. In one sentence:** since February 2026 a ruleset can require approvals from named teams for file patterns, with a count per team, which covers the cases CODEOWNERS can't express.

**[ANIMATION]** cards: id=rr cards=up_to_15_teams|0_to_10_approvals_per_team:zero_adds_the_team_for_visibility|write_permissions_or_higher|not_on_user-owned_repositories:they_contain_no_teams|generally_available:17_February_2026|augments_CODEOWNERS:does_not_replace_it title=The_required_reviewers_rule,_as_documented at_1=8 at_2=24 at_3=42 at_4=52 at_5=68 at_6=84

The documentation: you can specify up to 15 different teams, and for each team a number of required approvals. Counts run from 0 to 10. Zero adds the team "for visibility". The team must have write permissions or higher. The rule isn't available on user-owned repositories, because they don't contain teams. It became generally available on the seventeenth of February 2026. And GitHub positions it with care: it "augments CODEOWNERS files but doesn't replace them".

**[ANIMATION]** walk: id=cmp columns=question,CODEOWNERS,required_reviewers_rule rows=lives_in:a_file_in_the_repository:a_ruleset|accepts:users,_teams,_emails:teams_only|several_owners:any_one_suffices:a_count_per_team|covers:one_repository_and_branch:many_repositories|takes_effect:on_the_base_branch:when_the_ruleset_is_active mono=off title=Two_ways_to_require_a_reviewer at_1=3 at_2=27 at_3=40 at_4=63 at_5=80

**[ANIMATION]** step: 5

Compare the two. CODEOWNERS lives in a file in the repository and is reviewed like code. The rule lives in a ruleset and is edited by administrators. CODEOWNERS accepts users, teams and emails. The rule accepts teams only. With several owners in CODEOWNERS any one suffices. In the rule each listed team has its own required count. CODEOWNERS is one file per repository and branch. An organization ruleset can cover many repositories. CODEOWNERS takes effect when it's on the base branch. The rule takes effect when the ruleset is active.

**[ANIMATION]** say: Unresolved:_the_documentation_page_and_the_REST_schema_describe_the_pattern_syntax_differently

One caveat stays attached. Chapter 18, section 18.7 records an unresolved point: the documentation page and the REST schema describe the pattern syntax of this rule differently. Test before you depend on it.

**[ANIMATION]** cards: id=instr cards=the_CODEOWNERS_file_page:errors_are_highlighted|the_shield_icon_on_a_file:ownership_details_for_the_branch_you_look_at|a_REST_endpoint:lists_the_errors_of_the_file,_with_an_optional_ref numbered=on title=Three_documented_instruments at_1=10 at_2=37 at_3=72

**Finding out what GitHub thinks.** Three documented instruments. First: when you navigate to the CODEOWNERS file in your repository, errors are highlighted. Second: when you browse to a file, hovering over the shield icon shows a tool tip with code ownership details, for the branch you're looking at. Third: a REST endpoint, an address of GitHub's API, lists the errors of the file, with an optional `ref`.

```bash
gh api repos/ORG/REPO/codeowners/errors
gh api --method GET repos/ORG/REPO/codeowners/errors -f ref=my-branch
gh pr view 12 --json reviewRequests
```

All three are 🟢 SAFE: they read. They use documented endpoints and weren't executed by the authors. Each error has a line, a column, a kind, a message and sometimes a suggestion. The CLI has no dedicated command for linting CODEOWNERS. The second command is the one to make a habit: it asks for the errors of the file as it is on your branch, before the change merges.

## MENTAL MODEL

**[ANIMATION]** step: two.4

Hold two copies of the file in your head, one on each branch, and ask of every question: which copy answers it?

**[ANIMATION]** say: Announced_by_the_directory_in_the_lobby_today:_the_copy_on_the_base_branch

The directory analogy from the last video extends to this. A visitor to the building is announced according to the directory that hangs in the lobby today. A visitor who brings a corrected directory under the arm is still announced by the old one. The new one is hung up only after someone who is listed on the old one has let it in.

**[ANIMATION]** end

The analogy breaks where it did before: this directory is read top to bottom and the last line that fits wins. And it breaks in a second place. A lobby directory is one object. Here there's one file per branch, and a release branch can legitimately have different owners from `main`.

**[ANIMATION]** step: cond.marks

**[ANIMATION]** say: Three_ways_to_fail,_and_two_ways_around_it:_a_bypass_actor,_an_indirect_merge

When the copy on the base branch is the control, the control has three ways to fail without anyone editing it in bad faith: a later line takes the protected path away, the rule that makes owner review required is missing or doesn't target the branch, or the owner has no explicit write access. And it has two ways to be bypassed that no file can prevent: a bypass actor, and an indirect merge. Those were covered in Chapter 17, section 17.13, and Chapter 18, section 18.5.

**[ANIMATION]** stores: id=copies boxes=base_branch:main|pull_request:changed_paths|head_branch:docs/escalation-runbook rows=1:A:*_@example-org/platform|1:A:...|1:A:docs/*_@example-org/docs@hl|1:A:/.github/_@example-org/repo-admins|2:C:*_@example-org/platform|2:C:...|2:C:(docs_line_removed)@bad|2:C:/.github/_@example-org/repo-admins|3:B:.github/CODEOWNERS|3:B:config/routing.yaml|3:B:docs/README.md|3:B:docs/runbooks/escalation.md arrows=3:C>B:|4:B>A:asks mono=off title=.github/CODEOWNERS,_two_copies say_4=Review_requests_come_from_THIS_copy:_the_base_branch at_1=28 at_2=40 at_3=52

**[ANIMATION]** step: 3

Before the next picture, a prediction. Two copies of the file, one on the base branch and one on the head branch, with a pull request between them. From which copy do the review requests come? Say it out loud.

**[PAUSE]**

## DIAGRAM

**[ANIMATION]** step: copies.4

**[DIAGRAM]** Draw the base branch first with its file. Then the head branch with its edited copy. Then the pull request between them. Last, the arrow, and ask the viewer where it points before you draw it.

```text
  base branch: main                                 head branch: docs/escalation-runbook
  +----------------------------------------+        +----------------------------------------+
  | .github/CODEOWNERS                     |        | .github/CODEOWNERS                     |
  |   *          @example-org/platform     |        |   *          @example-org/platform     |
  |   ...                                  |        |   ...                                  |
  |   docs/*     @example-org/docs         |        |   (docs line removed)                  |
  |   /.github/  @example-org/repo-admins  |        |   /.github/  @example-org/repo-admins  |
  +----------------------------------------+        +----------------------------------------+
            ^                                                        |
            |  review requests come from THIS copy                   |
            |                                                        |
            +------------------  pull request  <---------------------+
                                 changed paths:
                                   .github/CODEOWNERS
                                   config/routing.yaml
                                   docs/README.md
                                   docs/runbooks/escalation.md
```

The arrow goes to the left box, the base branch. The right box becomes the left box only by merging, and merging needs the owners that the left box names.

**[DIAGRAM]** The arrow goes from the pull request to the left box. The right box becomes the left box only by merging, and merging needs the owners that the left box names.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch18/codeowners-base`. Every command here reads: `git cat-file`, `git show`, `git diff`. All 🟢 SAFE.

Into the lab. The situation: the repository `ticket-router`. You're on a branch that changes four paths. One of them is the CODEOWNERS file.

**Step 1: which file, on which branch.**

```bash
for p in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do git cat-file -e origin/main:$p 2>/dev/null && echo "exists on main: $p"; done
git cat-file -s origin/main:.github/CODEOWNERS
```

Notice what the command asks about: `origin/main`, not your working tree. That's the whole lesson in one argument.

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

Two files exist on `main`. The documented order makes the one in `.github/` the one that counts.

**Step 2: read the base version.**

```bash
git show origin/main:.github/CODEOWNERS
```

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

Read it as you learned in the last video: general first. The last line gives the whole `.github/` directory to the repository administrators. Check the first of the three conditions: is it the last line? It is.

**Step 3: the changed paths.**

```bash
git diff --name-only origin/main...HEAD
```

Three dots, as on the Files changed tab of a pull request: the changes since the merge base.

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

Try it now, thirty seconds, on paper. Four paths. For each, which line of the base version decides? Write the four lines down before you continue. One hint from the last video: `docs/*` covers one level.

**[PAUSE]**

**Step 4: the pull request edits the file.**

```bash
git diff origin/main...HEAD -- .github/CODEOWNERS
git show origin/main:.github/CODEOWNERS | grep -n "^docs"
git show HEAD:.github/CODEOWNERS | grep -n "^docs"
```

The diff removes the docs line. Which of the two `grep` commands will find a line, and which will exit with status 1? Say it out loud.

**[PAUSE]**

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

The base version still has the line, at line 12. The head version doesn't. `grep` exits with 1. Review requests come from the base version. So the docs team is requested for `docs/README.md` although your branch deleted their line. That's the opening question, answered: you can't remove a reviewer in the pull request that needs them.

**[ANIMATION]** say: Under_the_base_version_the_last_line_owns_.github/CODEOWNERS:_repo-admins_are_requested_too

And look at what else this pull request changes: `.github/CODEOWNERS` itself. Under the base version, who owns that path? The last line. So the repository administrators are requested too.

**[ANIMATION]** end

**Step 5: the lab replay.** Replay `labs/run ch18/lab-23-2-codeowners`. It asks the same questions in the order of the lab, and then walks into a trap on purpose.

<!-- snippet: ch18/lab-23-2-codeowners/03-base-version -->
```text
$ git show origin/main:.github/CODEOWNERS | grep -n "^[^#]"
2:*                       @example-org/platform
5:/router/                @example-org/routing
6:/router/priority.py     @example-org/routing @example-org/on-call
9:*.yaml                  @example-org/platform @example-org/sre
12:docs/*                  @example-org/docs
15:/.github/               @example-org/repo-admins
```
<!-- /snippet -->

The non-comment lines with their line numbers: this is the form in which you reason about "last match".

**[ANIMATION]** match: id=four header=.github/CODEOWNERS rules=*:platform|/router/:routing|/router/priority.py:routing,_on-call|*.yaml:platform,_sre|docs/*:docs|/.github/:repo-admins numbers=2,5,6,9,12,15 paths=.github/CODEOWNERS:1+6|config/routing.yaml:1+4|docs/README.md:1+5|docs/runbooks/escalation.md:1 wins=last title=The_base_version_on_origin/main:_owners_are_teams_of_@example-org at_rules=0 at_1=10 at_2=28 at_3=47 at_4=64

Now check your paper. `.github/CODEOWNERS`: line 15. `config/routing.yaml`: line 9, platform and SRE. `docs/README.md`: line 12, the docs team. And `docs/runbooks/escalation.md`: line 2 only, the platform team, because `docs/*` doesn't match nested files.

<!-- snippet: ch18/lab-23-2-codeowners/05-checkpoint -->
```text
# The version on your branch differs. It does not decide this pull request:
$ git diff --stat origin/main...HEAD -- .github/CODEOWNERS
 .github/CODEOWNERS | 1 -
 1 file changed, 1 deletion(-)
$ git show HEAD:.github/CODEOWNERS | grep -n "^docs"
[exit status: 1]
```
<!-- /snippet -->

One deletion in the file on your branch, and it doesn't decide this pull request.

Now the failure scenario of the lab. The shortcut is tempting: strip the owners from the file and let Git match the patterns as if they were ignore rules.

<!-- snippet: ch18/lab-23-2-codeowners/06-failure -->
```text
# The shortcut: strip the owners and let Git match the patterns as if they were ignore rules.
$ git show origin/main:.github/CODEOWNERS | sed -E 's/[[:space:]]+@.*//' > ../patterns
$ git -c core.excludesFile=../patterns check-ignore -v --no-index config/routing.yaml docs/README.md docs/runbooks/escalation.md .github/CODEOWNERS
../patterns:2:*	config/routing.yaml
../patterns:2:*	docs/README.md
../patterns:2:*	docs/runbooks/escalation.md
../patterns:15:/.github/	.github/CODEOWNERS
```
<!-- /snippet -->

Look at the first three lines of the result. Git names line 2, the star, for `config/routing.yaml`, for `docs/README.md` and for the runbook. Is that what GitHub is documented to do? Compare with your paper.

**[PAUSE]**

It isn't, and the recovery snippet isolates why.

<!-- snippet: ch18/lab-23-2-codeowners/07-recovery -->
```text
# Isolate the mechanism. A catch-all line followed by *.yaml, asked about two paths:
$ printf '*\n*.yaml\n' > ../two
$ git -c core.excludesFile=../two check-ignore -v --no-index routing.yaml config/routing.yaml
../two:2:*.yaml	routing.yaml
../two:1:*	config/routing.yaml
# Git decided config/routing.yaml at the directory config/, which line 1 matches.
# And docs/* on a nested file, which the CODEOWNERS documentation says it does not match:
$ printf 'docs/*\n' > ../two
$ git -c core.excludesFile=../two check-ignore -v --no-index docs/runbooks/escalation.md
../two:1:docs/*	docs/runbooks/escalation.md
$ rm ../two ../patterns
```
<!-- /snippet -->

With a catch-all line followed by `*.yaml`, Git names line 2 for `routing.yaml` at the top level and line 1 for `config/routing.yaml`. Git decided the second path at the directory `config/`, which the first line already matches. That's the directory-first behavior of gitignore, and CODEOWNERS is documented to assign owners per file. So the shortcut gives wrong owners with complete confidence. Reason from the documented rules and confirm on GitHub.

**[ON SCREEN]** Lower third: GitHub. Screen walkthrough.

**Part B of Lab 23.2, on your practice repository, in your normal shell.** The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors. You need a second account or a teammate.

The lab has five stages. You give the second account write access. You add a CODEOWNERS file through a pull request, and before merging you ask the errors endpoint about the file on your branch. You add a second ruleset that requires code owner review. That's a `gh api` call with `POST`, which Chapter 18 labels 🔴 DANGEROUS, and whose five answers you heard in video 134: create, read back with `gh ruleset check main`, and disable or delete to recover. Then you open a pull request that touches `/router/`, which the second account owns.

```bash
gh pr view --json reviewRequests,reviewDecision
gh pr merge --squash
```

On your screen, know the controls by their function. In the pull request, find the list of requested reviewers and see whether the owner is in it. Find the merge box and read what it says is missing. The merge attempt is expected to be refused. Then the second account approves, and you read the review decision again and merge. What you have then proved: a code owner's approval is required when a rule says so, and the base branch's file decides.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Expecting an edit to CODEOWNERS to apply to the pull request that makes it.** Root cause: review requests use the version of the file on the base branch.
2. **Leaving CODEOWNERS itself without an owner.** Root cause: the file is an ordinary tracked file, so anyone with write access can rewrite it unless a line owns `/.github/` and a rule requires owner review.
3. **Placing the `/.github/` line anywhere but last.** Root cause: a later pattern such as `*.yaml` matches workflow files and replaces the owners.
4. **Listing one person as sole owner.** Root cause: authors cannot approve their own pull requests, so the owner's own changes have nobody who can satisfy the requirement.
5. **Testing the file with `git check-ignore`.** Root cause: Git's matcher stops at a matched directory, and CODEOWNERS assigns owners per file.

## PRODUCTION EXAMPLE

Now, out of the lab. A team that serves models keeps its deployment workflow in `.github/workflows/`. CODEOWNERS gives `/.github/` to the platform team, and the file has had that line for a year. A change to the deployment workflow merges with one approval from a product engineer.

**[ANIMATION]** cards: id=cond2 question=A_workflow_change_merged_with_one_approval._Which_condition_failed? cards=the_line_comes_last:no_later_pattern_such_as_*.yaml|a_rule_requires_owner_review:on_the_default_branch|the_owning_team:holds_explicit_write_access marks=1:bad at_1=6 at_2=2 at_3=24 at_marks=48

**[ANIMATION]** step: 1

Work through the three conditions. Is the line last? Someone appended a `*.yaml` line for the SRE team three months ago, and the workflow file is a YAML file, so SRE became its owner.

**[ANIMATION]** step: marks

Does a rule require code owner review on the default branch? Check the rules page. Does the owning team have explicit write access? Ask the errors endpoint. In this case the first condition failed, and the errors endpoint has nothing to report, because nothing in the file is invalid. The file says exactly what its last matching line says.

The repair is to move the `/.github/` line to the end. And remember the timing: the pull request that moves it is judged by the file on `main`, so it needs the approval of whoever owns `.github/CODEOWNERS` under the current, wrong order.

## PRACTICE EXERCISE

**[ANIMATION]** end

Your turn. Do Lab 23.2, "CODEOWNERS enforcement with a second account", in [`lab-manual/m23-governance.md`](../../lab-manual/m23-governance.md). Part A runs in `labs/shell`. The IDs there differ from the ones in this video. Part B runs in your normal shell.

In Part A, after the four observation steps, stop and predict on paper, for each of the four changed paths: which line decides, and which owners are requested. In Part B, before each merge attempt, predict whether GitHub will allow it and what the merge box will name as missing.

The challenge is Exercise 23.8, ""Main is protected. How did a force push get through?"", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q254: "Why can a pull request not remove its own required reviewer by editing CODEOWNERS?"

**[PAUSE]**

Answer out loud first. A strong answer names the rule and its source: which version of the file GitHub uses, and that this is GitHub's behavior and not Git's. It explains the design reason, not only the fact. It shows the local evidence you would look at, with the branch named in each command. It adds the consequence in the other direction, for a legitimate fix to the file. And it says what must also be true for the control to hold: who owns the file itself, and which rule makes that ownership binding.

## RECAP

**[ANIMATION]** step: copies.4

**[ANIMATION]** say: Review_requests_come_from_THIS_copy:_the_base_branch

Let's land this. The developer from the opening deleted a line and removed nobody, because the copy on the base branch decides.

You should now be able to say:

- A pull request is judged by the CODEOWNERS file on its base branch; an edit takes effect one merge later.
- The file and the workflows directory need an owner, and that protection is real only if the line is last, a rule requires owner review, and the owning team has explicit write access.
- In a monorepo: default first, components next, cross-cutting patterns after them, `/.github/` last.
- CODEOWNERS means "any one owner"; where several teams or counts are needed, the required reviewers rule complements it.
- The errors endpoint with a `ref` tests an edit before it merges.

## HOMEWORK

Read sections 19.7 to 19.14 of [Chapter 19](../../textbook/ch19-codeowners.md).

Today you asked a clone which CODEOWNERS file counts, and you saw why the file can't be edited around. Before the next video, ask a repository of yours which CODEOWNERS file exists on `origin/main`. Next time: signatures. What is signed, by which program, and SSH signing end to end. Until then, look at the state first and type second. See you in the next one.
