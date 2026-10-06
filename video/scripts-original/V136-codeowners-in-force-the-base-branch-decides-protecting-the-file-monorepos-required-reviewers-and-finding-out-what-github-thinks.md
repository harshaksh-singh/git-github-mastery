# V136: CODEOWNERS in force: the base branch decides, protecting the file, monorepos, required reviewers, and finding out what GitHub thinks

- **Part.** 5: GitHub
- **Module.** 23
- **Planned minutes.** 22
- **Prerequisites.** V135
- **Textbook sections.** [Chapter 19](../../textbook/ch19-codeowners.md), sections 19.7 to 19.14
- **Demo scripts.** `labs/ch18/codeowners-base.sh`, `labs/ch18/lab-23-2-codeowners.sh`, then a screen walkthrough of Lab 23.2 in [`lab-manual/m23-governance.md`](../../lab-manual/m23-governance.md)

## HOOK

**[ON SCREEN]** A pull request with four changed files. One of them is `.github/CODEOWNERS`, and the diff removes one line.

A developer wants a documentation change merged today, and the docs team is slow. So the same pull request also deletes the docs team's line from CODEOWNERS. The reasoning: if the team is no longer an owner, the team is no longer required.

Does that work? If it did, every required reviewer could be removed by the person who needs the review. In this video you see why it does not work, which Git command tells you so before you open the pull request, and what you have to configure so that the file that names the reviewers is itself protected.

## INTRODUCTION

In the last video you learned what a CODEOWNERS file says: patterns, owners, last match wins. This video is about the file in force. Five topics, in the order of sections 19.7 to 19.11. Which version of the file applies to a pull request. How you protect the file itself and the workflows directory. How to lay out ownership in a monorepo. The newer "required reviewers" rule and when it complements CODEOWNERS. And three documented instruments that tell you how GitHub read your file.

The local demonstration answers every question that a clone can answer. The enforcement itself happens on GitHub, and you will prove it in Lab 23.2 with a second account.

## LEARNING OBJECTIVES

After this video you can:

- say from which branch the CODEOWNERS file is read for a pull request and why that matters;
- explain why a pull request cannot remove its own required reviewer by editing the file;
- protect CODEOWNERS and the workflows directory and name the conditions that make the protection real;
- lay out ownership for a monorepo and decide when the "required reviewers" rule replaces or complements CODEOWNERS;
- check the file for errors before merging a change to it.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub.

**The base branch decides. In one sentence:** a pull request is judged by the CODEOWNERS file on its base branch, so a pull request that edits CODEOWNERS is reviewed under the old file.

The documentation: "To trigger review requests, pull requests use the version of `CODEOWNERS` from the base branch of the pull request." For a pull request from a fork into upstream, that is upstream's file. In a stack of pull requests, CODEOWNERS is, in the documentation's words, "evaluated from the stack base".

Why is it designed like this? Because the alternative has no security value. The head branch is written by the person asking for the merge. If their copy of the file decided, the control would be in the hands of the person it is meant to check. The base branch is the state everyone already agreed to.

There is a second consequence that people meet more often than the first: a fix to CODEOWNERS takes effect one merge later than they expect. The pull request that carries the fix is still judged under the old file.

**Protecting the file. In one sentence:** the file that names the reviewers, and the directory that defines what automation runs, need owners themselves, or anyone with write access can change both in one pull request.

GitHub's advice, quoted in the textbook: "To protect a repository fully against unauthorized changes, you also need to define an owner for the CODEOWNERS file itself." The most secure method, according to the documentation, is to keep the file in the `.github` directory and to define an owner either for the file or for the whole directory.

Owning the whole `.github/` directory also covers `.github/workflows/`. A workflow file decides what runs with the repository's token and secrets, so a change to it is a change to your deployment and security posture. Part 7 of this course is about that.

Three conditions make the protection real. The line must come last, so that no later pattern such as `*.yaml` takes workflow files away. The code-owner option must be required by a rule on the default branch. And the owning team must hold explicit write access. If one of the three is missing, you have a line in a file and no control.

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

Use the directory form for subtrees, because `dir/*` covers one level only. Anchor component paths with a leading slash, or `router/` also matches a directory of that name inside another component. Prefer teams to people, so that ownership survives holidays and departures. And one caveat that the textbook attaches to block three: the patterns with two stars follow the gitignore rules and are not among GitHub's documented examples, except `**/logs`. Confirm them with the instruments at the end of this section.

What the file cannot express: "both teams must approve", "two members of this team", or "everyone except this directory". The first two belong to the next rule. The third has only the documented workaround of an owner-less line.

**The required reviewers rule. In one sentence:** since February 2026 a ruleset can require approvals from named teams for file patterns, with a count per team, which covers the cases CODEOWNERS cannot express.

The documentation: you can specify up to 15 different teams, and for each team a number of required approvals. Counts run from 0 to 10; zero adds the team "for visibility". The team must have write permissions or higher. The rule is not available on user-owned repositories, because they do not contain teams. It became generally available on 17 February 2026. And GitHub positions it with care: it "augments CODEOWNERS files but doesn't replace them".

Compare the two. CODEOWNERS lives in a file in the repository and is reviewed like code; the rule lives in a ruleset and is edited by administrators. CODEOWNERS accepts users, teams and emails; the rule accepts teams only. With several owners in CODEOWNERS any one suffices; in the rule each listed team has its own required count. CODEOWNERS is one file per repository and branch; an organization ruleset can cover many repositories. CODEOWNERS takes effect when it is on the base branch; the rule takes effect when the ruleset is active.

One caveat stays attached. Chapter 18, section 18.7 records an unresolved point: the documentation page and the REST schema describe the pattern syntax of this rule differently. Test before you depend on it.

**Finding out what GitHub thinks.** Three documented instruments. First: when you navigate to the CODEOWNERS file in your repository, errors are highlighted. Second: when you browse to a file, hovering over the shield icon shows a tool tip with code ownership details, for the branch you are looking at. Third: a REST endpoint lists the errors of the file, with an optional `ref`.

```bash
gh api repos/ORG/REPO/codeowners/errors
gh api --method GET repos/ORG/REPO/codeowners/errors -f ref=my-branch
gh pr view 12 --json reviewRequests
```

All three are 🟢 SAFE: they read. They use documented endpoints and were not executed by the authors. Each error has a line, a column, a kind, a message and sometimes a suggestion. The CLI has no dedicated command for linting CODEOWNERS. The second command is the one to make a habit: it asks for the errors of the file as it is on your branch, before the change merges.

## MENTAL MODEL

Hold two copies of the file in your head, one on each branch, and ask of every question: which copy answers it?

The directory analogy from the last video extends to this. A visitor to the building is announced according to the directory that hangs in the lobby today. A visitor who brings a corrected directory under the arm is still announced by the old one. The new one is hung up only after someone who is listed on the old one has let it in.

The analogy breaks where it did before: this directory is read top to bottom and the last line that fits wins. And it breaks in a second place. A lobby directory is one object. Here there is one file per branch, and a release branch can legitimately have different owners from `main`.

When the copy on the base branch is the control, the control has three ways to fail without anyone editing it in bad faith: a later line takes the protected path away, the rule that makes owner review required is missing or does not target the branch, or the owner has no explicit write access. And it has two ways to be bypassed that no file can prevent: a bypass actor, and an indirect merge. Those were covered in Chapter 17, section 17.13, and Chapter 18, section 18.5.

## DIAGRAM

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

**[DIAGRAM]** The arrow goes from the pull request to the left box. The right box becomes the left box only by merging, and merging needs the owners that the left box names.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch18/codeowners-base`. Every command here reads: `git cat-file`, `git show`, `git diff`. All 🟢 SAFE.

The situation: the repository `ticket-router`. You are on a branch that changes four paths. One of them is the CODEOWNERS file.

**Step 1: which file, on which branch.**

```bash
for p in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do git cat-file -e origin/main:$p 2>/dev/null && echo "exists on main: $p"; done
git cat-file -s origin/main:.github/CODEOWNERS
```

Notice what the command asks about: `origin/main`, not your working tree. That is the whole lesson in one argument.

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

**[PAUSE]** Four paths. For each, which line of the base version decides? Write the four line numbers down before you continue. One hint from the last video: `docs/*` covers one level.

**Step 4: the pull request edits the file.**

```bash
git diff origin/main...HEAD -- .github/CODEOWNERS
git show origin/main:.github/CODEOWNERS | grep -n "^docs"
git show HEAD:.github/CODEOWNERS | grep -n "^docs"
```

**[PAUSE]** The diff removes the docs line. Which of the two `grep` commands will find a line, and which will exit with status 1?

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

The base version still has the line, at line 12. The head version does not; `grep` exits with 1. Review requests come from the base version. So the docs team is requested for `docs/README.md` although your branch deleted their line. You cannot remove a reviewer in the pull request that needs them.

And look at what else this pull request changes: `.github/CODEOWNERS` itself. Under the base version, who owns that path? The last line. So the repository administrators are requested too.

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

One deletion in the file on your branch, and it does not decide this pull request.

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

**[PAUSE]** Look at the first three lines of the result. Git names line 2, the star, for `config/routing.yaml`, for `docs/README.md` and for the runbook. Is that what GitHub is documented to do?

It is not, and the recovery snippet isolates why.

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

With a catch-all line followed by `*.yaml`, Git names line 2 for `routing.yaml` at the top level and line 1 for `config/routing.yaml`. Git decided the second path at the directory `config/`, which the first line already matches. That is the directory-first behavior of gitignore, and CODEOWNERS is documented to assign owners per file. So the shortcut gives wrong owners with complete confidence. Reason from the documented rules and confirm on GitHub.

**[ON SCREEN]** Lower third: GitHub. Screen walkthrough.

Part B of Lab 23.2, on your practice repository, in your normal shell. The interface changes; the lab text and the linked documentation are the reference. No GitHub output was captured by the authors. You need a second account or a teammate.

The lab has five stages. You give the second account write access. You add a CODEOWNERS file through a pull request, and before merging you ask the errors endpoint about the file on your branch. You add a second ruleset that requires code owner review; that is a `gh api` call with `POST`, which Chapter 18 labels 🔴 DANGEROUS, and whose five answers you heard in V134: create, read back with `gh ruleset check main`, and disable or delete to recover. Then you open a pull request that touches `/router/`, which the second account owns.

```bash
gh pr view --json reviewRequests,reviewDecision
gh pr merge --squash
```

On screen, name the controls by function. In the pull request, find the list of requested reviewers and see whether the owner is in it. Find the merge box and read what it says is missing. The merge attempt is expected to be refused. Then the second account approves, and you read the review decision again and merge. What you have then proved: a code owner's approval is required when a rule says so, and the base branch's file decides.

## COMMON MISTAKES

1. **Expecting an edit to CODEOWNERS to apply to the pull request that makes it.** Root cause: review requests use the version of the file on the base branch.
2. **Leaving CODEOWNERS itself without an owner.** Root cause: the file is an ordinary tracked file, so anyone with write access can rewrite it unless a line owns `/.github/` and a rule requires owner review.
3. **Placing the `/.github/` line anywhere but last.** Root cause: a later pattern such as `*.yaml` matches workflow files and replaces the owners.
4. **Listing one person as sole owner.** Root cause: authors cannot approve their own pull requests, so the owner's own changes have nobody who can satisfy the requirement.
5. **Testing the file with `git check-ignore`.** Root cause: Git's matcher stops at a matched directory, and CODEOWNERS assigns owners per file.

## PRODUCTION EXAMPLE

A team that serves models keeps its deployment workflow in `.github/workflows/`. CODEOWNERS gives `/.github/` to the platform team, and the file has had that line for a year. A change to the deployment workflow merges with one approval from a product engineer.

Work through the three conditions. Is the line last? Someone appended a `*.yaml` line for the SRE team three months ago, and the workflow file is a YAML file, so SRE became its owner. Does a rule require code owner review on the default branch? Check the rules page. Does the owning team have explicit write access? Ask the errors endpoint. In this case the first condition failed, and the errors endpoint has nothing to report, because nothing in the file is invalid. The file says exactly what its last matching line says.

The repair is to move the `/.github/` line to the end. And remember the timing: the pull request that moves it is judged by the file on `main`, so it needs the approval of whoever owns `.github/CODEOWNERS` under the current, wrong order.

## PRACTICE EXERCISE

Do Lab 23.2, "CODEOWNERS enforcement with a second account", in [`lab-manual/m23-governance.md`](../../lab-manual/m23-governance.md). Part A runs in `labs/shell`; the IDs there differ from the ones in this video. Part B runs in your normal shell.

In Part A, after the four observation steps, stop and predict on paper, for each of the four changed paths: which line decides, and which owners are requested. In Part B, before each merge attempt, predict whether GitHub will allow it and what the merge box will name as missing.

The challenge is Exercise 23.8, ""Main is protected. How did a force push get through?"", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q254: "Why can a pull request not remove its own required reviewer by editing CODEOWNERS?"

A strong answer names the rule and its source: which version of the file GitHub uses, and that this is GitHub's behavior and not Git's. It explains the design reason, not only the fact. It shows the local evidence you would look at, with the branch named in each command. It adds the consequence in the other direction, for a legitimate fix to the file. And it says what must also be true for the control to hold: who owns the file itself, and which rule makes that ownership binding.

## RECAP

You should now be able to say:

- A pull request is judged by the CODEOWNERS file on its base branch; an edit takes effect one merge later.
- The file and the workflows directory need an owner, and that protection is real only if the line is last, a rule requires owner review, and the owning team has explicit write access.
- In a monorepo: default first, components next, cross-cutting patterns after them, `/.github/` last.
- CODEOWNERS means "any one owner"; where several teams or counts are needed, the required reviewers rule complements it.
- The errors endpoint with a `ref` tests an edit before it merges.

## HOMEWORK

Read sections 19.7 to 19.14 of [Chapter 19](../../textbook/ch19-codeowners.md).
