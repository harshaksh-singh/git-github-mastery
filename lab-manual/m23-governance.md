# Module 23 labs: Governance: rulesets, branch protection, and CODEOWNERS

> **Baseline.** Git 2.55.0 on macOS; GitHub CLI 2.88.1; GitHub facts as of 1 October 2026. Read [Chapter 18](../textbook/ch18-branch-protection.md) and [Chapter 19](../textbook/ch19-codeowners.md) first. Every transcript under "Expected output" is real output of a replay script in `labs/ch18/`. Nothing in this file was run against GitHub. The ruleset files in `labs/ch18/rulesets/` were assembled from the documented REST schema and checked to be valid JSON; they were not sent to GitHub by the author. What GitHub shows is described from its documentation, with the link, and you record what you actually see.

## How these labs work

Each lab has a local Part A in the lab shell, which shows the part of the topic that plain Git can show, and a Part B on GitHub.

> **Run Part B in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub.

Part B uses the public repository `ticket-router-lab` in your practice organization, from "One-time preparation" in the [Module 21 labs](m21-pull-requests-forks.md). It must be public and owned by the organization: on a Free plan, rulesets and code owners work only in public repositories, and teams and merge queues need an organization ([Chapter 18](../textbook/ch18-branch-protection.md), section 18.15). Set these in each new terminal:

```bash
ORG=your-practice-org
ME=your-username
COURSE=/path/to/this/course          # the directory that contains labs/ and textbook/
cd ~/git-mastery-labs/hands-on/m21-github/ticket-router-lab
```

In transcripts, a line `[exit status: N]` is added by the replay tool. In your own shell, `echo $?` right after a command prints the same number.

## Lab 23.1: A ruleset on the default branch

### Objective

Protect a default branch and watch each rule refuse a ref update: first on a bare server with a hook that imitates five rules, then with a real ruleset created through the REST API. Meet the layering of two protections, and the cost of switching one off.

### Prerequisites

Chapter 18, sections 18.2 to 18.6 and 18.16. Chapter 12, section 12.7.

### Setup

**Part A.**

```bash
bash labs/ch18/setup-23-1-server-rules.sh
labs/shell m23-1
```

An unprotected bare server, your clone with `main` up to date and the branch `feature/priority-routing`, and the file `rules/pre-receive`, which is the hook printed in Chapter 18, section 18.2. It is not installed.

**Part B.** The starter repository on GitHub. No ruleset exists yet.

### Commands

**Part A, in the lab shell.**

```bash
# 1. Observe: no hook installed, no built-in restriction
ls server/ticket-router.git/hooks | grep -vc sample
git -C server/ticket-router.git config get receive.denyNonFastForwards
cd you/ticket-router
git log --oneline -2 origin/main

# 2. Unprotected: a force push that drops the newest commit of main is accepted. Then put it back.
git push --force origin main~1:main
git ls-remote origin main
git push origin main

# 3. Install the rules and make them active
cp ../../rules/pre-receive ../../server/ticket-router.git/hooks/pre-receive
chmod +x ../../server/ticket-router.git/hooks/pre-receive

# 4. Three ref updates that the rules refuse
git push --force origin main~1:main
git push origin --delete main
git merge -q --no-ff -m "Merge pull request #1 from feature/priority-routing" feature/priority-routing
git push origin main
git reset -q --hard origin/main

# 5. One that they allow: a squash commit
git merge -q --squash feature/priority-routing
git commit -q -m "Route high-priority tickets to an escalations queue (#1)"
git push origin main
```

`git reset --hard` in step 4 discards the local merge commit. It is appropriate here because the working tree is clean and the commit is the one you want gone; [Chapter 11](../textbook/ch11-reset-revert-restore.md) covers the command.

**Part B, in your normal shell.**

```bash
# 1. Create the ruleset from the course file, then read it back
cat "$COURSE/labs/ch18/rulesets/lab-23-1-main.json"
gh api --method POST "repos/$ORG/ticket-router-lab/rulesets" --input "$COURSE/labs/ch18/rulesets/lab-23-1-main.json"
gh ruleset list
gh ruleset check main
gh ruleset check main --web

# 2. A direct push and a force push to main
git switch main && git pull --ff-only
git commit --allow-empty -m "Direct push attempt"
git push origin main
git reset --hard origin/main
git push --force origin main~1:main

# 3. The allowed way: a pull request, merged by squash
git switch -c docs/rules-lab main
printf '\nThe default branch is protected by a ruleset.\n' >> README.md
git commit -am "Note the ruleset in the README"
git push -u origin docs/rules-lab
gh pr create --base main --title "Note the ruleset" --body "Lab 23.1"
gh pr merge --merge
gh pr merge --squash --delete-branch
```

### Expected output

**Part A.**

<!-- snippet: ch18/lab-23-1-server-rules/01-observe -->
```text
# Hooks installed on the server (files that are not samples), and the built-in setting:
$ ls server/ticket-router.git/hooks | grep -vc sample
0
$ git -C server/ticket-router.git config get receive.denyNonFastForwards
[exit status: 1]
$ cd you/ticket-router
$ git log --oneline -2 origin/main
9aa221a Raise the confidence threshold to 0.7
9a383e5 Add classifier test
```
<!-- /snippet -->

<!-- snippet: ch18/lab-23-1-server-rules/02-unprotected -->
```text
# No rules yet. A force push that drops the newest commit of main is accepted:
$ git push --force origin main~1:main
To ../../server/ticket-router.git
 + 9aa221a...9a383e5 main~1 -> main (forced update)
$ git ls-remote origin main
9a383e547a1c8840f3c5c7b23bfab6120f366ed0	refs/heads/main
# Put it back (a fast-forward):
$ git push origin main
To ../../server/ticket-router.git
   9a383e5..9aa221a  main -> main
```
<!-- /snippet -->

Without rules, anyone who can push can remove commits from `main`.

<!-- snippet: ch18/lab-23-1-server-rules/03-activate -->
```text
$ cp ../../rules/pre-receive ../../server/ticket-router.git/hooks/pre-receive
$ chmod +x ../../server/ticket-router.git/hooks/pre-receive
```
<!-- /snippet -->

<!-- snippet: ch18/lab-23-1-server-rules/04-rules-reject -->
```text
$ git push --force origin main~1:main
remote: rule 'block force pushes': the update would remove commits from refs/heads/main        
To ../../server/ticket-router.git
 ! [remote rejected] main~1 -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git push origin --delete main
remote: rule 'restrict deletions': refs/heads/main may not be deleted        
To ../../server/ticket-router.git
 ! [remote rejected] main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git merge -q --no-ff -m "Merge pull request #1 from feature/priority-routing" feature/priority-routing
$ git push origin main
remote: rule 'require linear history': the update adds a merge commit to refs/heads/main        
To ../../server/ticket-router.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git reset -q --hard origin/main
```
<!-- /snippet -->

<!-- snippet: ch18/lab-23-1-server-rules/05-allowed -->
```text
$ git merge -q --squash feature/priority-routing
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git commit -q -m "Route high-priority tickets to an escalations queue (#1)"
$ git push origin main
To ../../server/ticket-router.git
   9aa221a..410e927  main -> main
```
<!-- /snippet -->

**Part B, described from the documentation (not captured).**

- The ruleset contains four rules: restrict deletions, block force pushes, require linear history, and require a pull request with zero approvals and squash as the only allowed merge method. Its bypass list is empty, so it binds you too, although you own the organization ([Chapter 18](../textbook/ch18-branch-protection.md), section 18.5).
- `gh ruleset check main` shows "rules that would apply to a given branch", from every level (`gh ruleset check --help`). `--web` opens the branch rules page. The same information is at `https://github.com/ORG/ticket-router-lab/rules` for anyone who can read the repository ([managing rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository#viewing-rulesets-for-a-repository), read 2 October 2026).
- The direct push must be refused, because the pull request rule requires "that all changes to the target branch be associated with a pull request", and the force push because of "Block force pushes" ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)). Git reports a server-side refusal as `! [remote rejected]` with `remote:` lines from the server. The wording of GitHub's lines for rulesets is not in the documentation pages read for this course, so it is not printed here. Copy it into your notes.
- `gh pr merge --merge` must be refused: the ruleset allows only squash, and linear history forbids merge commits. `gh pr merge --squash` must succeed with zero approvals.

### What happened internally

In Part A the server ran `hooks/pre-receive` before moving any ref and gave it one line per proposed update: old ID, new ID, ref name. The force push failed the ancestry test (`old` is not an ancestor of `new`). The deletion had an all-zero new ID. The merge commit was found by `git rev-list --merges old..new`. The squash commit passed all three tests. Your client's `--force` changed nothing, because the decision was the server's.

In Part B GitHub evaluates the same proposals against its rulesets, and adds the questions that need its database: is there a pull request for these commits, and which merge method is being used.

### Checkpoint

<!-- snippet: ch18/lab-23-1-server-rules/06-checkpoint -->
```text
$ git ls-remote origin
410e927769d1b0d0ed922a62932cd5895fa44799	HEAD
16d4788572b31e17e4c3104a1d9861a5ce2c47ea	refs/heads/feature/priority-routing
410e927769d1b0d0ed922a62932cd5895fa44799	refs/heads/main
$ git log --oneline -2 origin/main
410e927 Route high-priority tickets to an escalations queue (#1)
9aa221a Raise the confidence threshold to 0.7
```
<!-- /snippet -->

`main` on the server is the squash commit. In Part B: `gh pr list --state merged` shows your pull request, and `git log --oneline -1 origin/main` after a fetch shows one new commit whose title ends in the pull request number.

### Failure scenario

Two protection layers, and an attempt to get around one of them. First a second, older protection is switched on for the server. Then somebody disables the "ruleset" to force-push.

```bash
git -C ../../server/ticket-router.git config set receive.denyNonFastForwards true
chmod -x ../../server/ticket-router.git/hooks/pre-receive
git push --force origin main~1:main
```

<!-- snippet: ch18/lab-23-1-server-rules/07-failure -->
```text
# An older protection, of another kind, is also switched on for this server:
$ git -C ../../server/ticket-router.git config set receive.denyNonFastForwards true
# Somebody wants the squash commit gone and disables the ruleset to force-push:
$ chmod -x ../../server/ticket-router.git/hooks/pre-receive
$ git push --force origin main~1:main
hint: The 'hooks/pre-receive' hook was ignored because it's not set as executable.
hint: You can disable this warning with `git config set advice.ignoredHook false`.
remote: error: denying non-fast-forward refs/heads/main (you should pull first)        
To ../../server/ticket-router.git
 ! [remote rejected] main~1 -> main (non-fast-forward)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
```
<!-- /snippet -->

The hook is off (Git even says so) and the push is still refused, by the other layer, with another message. This is Chapter 18, section 18.4 in miniature: all applicable protections apply, and relaxing one does not relax the branch. On GitHub the two layers are rulesets and a classic branch protection rule, or a repository ruleset and an organization ruleset.

In Part B, reproduce the dangerous half: disable the ruleset, push directly, and notice that nothing stops you.

```bash
ID=$(gh api "repos/$ORG/ticket-router-lab/rulesets" --jq '.[] | select(.name=="lab-23-1 main") | .id')
sed 's/"enforcement": "active"/"enforcement": "disabled"/' "$COURSE/labs/ch18/rulesets/lab-23-1-main.json" \
  | gh api --method PUT "repos/$ORG/ticket-router-lab/rulesets/$ID" --input -
gh ruleset check main
git switch main && git pull --ff-only
git commit --allow-empty -m "Pushed while the ruleset was disabled"
git push origin main
```

A disabled ruleset "will not be enforced" ([about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)), so the push should go through, and `gh ruleset check main` should list no rule from it.

### Recovery

**Part A.** Find out which layers are in force, restore the one that was switched off, and undo the change the way a protected branch allows: forward, with a revert.

```bash
test -x ../../server/ticket-router.git/hooks/pre-receive && echo "hook: active" || echo "hook: disabled"
git -C ../../server/ticket-router.git config get --show-origin receive.denyNonFastForwards
chmod +x ../../server/ticket-router.git/hooks/pre-receive
git revert --no-edit HEAD
git push origin main
```

<!-- snippet: ch18/lab-23-1-server-rules/08-diagnose -->
```text
# Two layers. Which ones are in force?
$ test -x ../../server/ticket-router.git/hooks/pre-receive && echo "hook: active" || echo "hook: disabled"
hook: disabled
$ git -C ../../server/ticket-router.git config get --show-origin receive.denyNonFastForwards
file:config	true
```
<!-- /snippet -->

<!-- snippet: ch18/lab-23-1-server-rules/09-recovery -->
```text
# Put the ruleset back, and undo the change the way a protected branch allows: forward.
$ chmod +x ../../server/ticket-router.git/hooks/pre-receive
$ git revert --no-edit HEAD
[main 4a4611c] Revert "Route high-priority tickets to an escalations queue (#1)"
 Date: Mon Sep 7 10:48:00 2026 +0530
 2 files changed, 1 insertion(+), 11 deletions(-)
 delete mode 100644 router/priority.py
$ git push origin main
To ../../server/ticket-router.git
   410e927..4a4611c  main -> main
```
<!-- /snippet -->

**Part B.** Put the ruleset back:

```bash
gh api --method PUT "repos/$ORG/ticket-router-lab/rulesets/$ID" --input "$COURSE/labs/ch18/rulesets/lab-23-1-main.json"
gh ruleset check main
```

The commit you pushed while the ruleset was disabled stays on `main`. Nothing on the `/rules` page records that it bypassed review. On paid plans Rule Insights and the audit log are where you would look for the change of enforcement status.

### Verification

```bash
git log --oneline -3 origin/main
test -x ../../server/ticket-router.git/hooks/pre-receive && echo "hook: active" || echo "hook: disabled"
git push --force origin main~1:main
git status -sb
```

<!-- snippet: ch18/lab-23-1-server-rules/10-verification -->
```text
$ git log --oneline -3 origin/main
4a4611c Revert "Route high-priority tickets to an escalations queue (#1)"
410e927 Route high-priority tickets to an escalations queue (#1)
9aa221a Raise the confidence threshold to 0.7
$ test -x ../../server/ticket-router.git/hooks/pre-receive && echo "hook: active" || echo "hook: disabled"
hook: active
$ git push --force origin main~1:main
remote: rule 'block force pushes': the update would remove commits from refs/heads/main        
To ../../server/ticket-router.git
 ! [remote rejected] main~1 -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

In Part B: `gh ruleset check main` lists the four rules again, and `git push origin main` with a new empty commit is refused (then `git reset --hard origin/main`).

### Questions

1. Which of the three refused pushes in Part A could a client-side option have turned into an accepted one? Why not?
2. The hook saw three values per ref update. For each rule in the hook, say which values it used.
3. Why did the squash commit pass the linear-history rule and the merge commit not, although both carry the same content?
4. In the failure scenario the message changed from `pre-receive hook declined` to `non-fast-forward`. What does that tell you?
5. Part B: you own the organization. Why was your direct push refused, and what in the ruleset would have to change to allow it? Which bypass mode would you choose for an on-call engineer, and why?
6. Part B: the ruleset requires a pull request with zero approvals. What does that still give a one-person repository?
7. What evidence remains of the push you made while the ruleset was disabled?

## Lab 23.2: CODEOWNERS enforcement with a second account

### Objective

Read everything about a code-owner decision that the repository itself contains. Then prove on GitHub, with a second account, that a code owner's approval is required when a rule says so, that another person's approval does not replace it, and that the base branch's file decides.

### Prerequisites

Chapter 19, all sections. Chapter 18, section 18.7. A second GitHub account or a teammate, for Part B.

### Setup

**Part A.**

```bash
bash labs/ch18/setup-23-2-codeowners.sh
labs/shell m23-2
```

`main` has `.github/CODEOWNERS` and an older `docs/CODEOWNERS`. Your branch `docs/escalation-runbook` changes four paths, one of them the CODEOWNERS file.

**Part B.** The starter repository on GitHub, with the ruleset of Lab 23.1 active. Set `SECOND=the-other-account`.

### Commands

**Part A, in the lab shell.**

```bash
# 1. Observe
cd you/ticket-router
git status -sb
git log --oneline origin/main..HEAD

# 2. Which CODEOWNERS file exists on the base branch? (documented order: .github/, root, docs/)
for p in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do git cat-file -e origin/main:$p 2>/dev/null && echo "exists on main: $p"; done

# 3. The base version, non-comment lines with their line numbers
git show origin/main:.github/CODEOWNERS | grep -n "^[^#]"

# 4. The paths this pull request changes
git diff --name-only origin/main...HEAD
```

Now stop and predict, on paper, for each of the four paths: which line decides, and which owners are requested. Use the rules of Chapter 19, section 19.5. Then check your answer in the solutions file.

**Part B, in your normal shell.**

```bash
SECOND=the-other-account

# 1. Give the second account write access. It must accept the invitation (notification or email).
gh api --method PUT "repos/$ORG/ticket-router-lab/collaborators/$SECOND" -f permission=push

# 2. Add CODEOWNERS through a pull request, and ask GitHub for syntax errors before merging
git switch main && git pull --ff-only
git switch -c chore/codeowners
mkdir -p .github
printf '# Lab 23.2\n*            @%s @%s\n/router/     @%s\n/.github/    @%s @%s\n' "$ME" "$SECOND" "$SECOND" "$ME" "$SECOND" > .github/CODEOWNERS
cat .github/CODEOWNERS
git add .github/CODEOWNERS && git commit -m "Add CODEOWNERS"
git push -u origin chore/codeowners
gh api --method GET "repos/$ORG/ticket-router-lab/codeowners/errors" -f ref=chore/codeowners
gh pr create --base main --title "Add CODEOWNERS" --body "Lab 23.2"
gh pr merge --squash --delete-branch

# 3. Require code owner review: a second ruleset on the same branch
gh api --method POST "repos/$ORG/ticket-router-lab/rulesets" --input "$COURSE/labs/ch18/rulesets/lab-23-2-codeowners.json"
gh ruleset check main

# 4. A pull request by you that touches /router/
git switch main && git pull --ff-only
git switch -c feature/vip-queue
sed -i '' 's/"general"\]/"general", "vip"]/' router/classify.py
git commit -am "Add a vip queue"
git push -u origin feature/vip-queue
gh pr create --base main --title "Add a vip queue" --body "Lab 23.2"
gh pr view --json reviewRequests,reviewDecision
gh pr merge --squash

# 5. The owner approves (as the second account), then you merge
gh auth switch --user "$SECOND"
gh pr review feature/vip-queue --approve
gh auth switch --user "$ME"
gh pr view feature/vip-queue --json reviewDecision
gh pr merge feature/vip-queue --squash --delete-branch
```

`gh auth switch` needs both accounts logged in (`gh auth login` once per account; `gh auth status` lists them). If the second account belongs to a teammate, they run the review command, or approve in the browser.

### Expected output

**Part A.**

<!-- snippet: ch18/lab-23-2-codeowners/01-observe -->
```text
$ cd you/ticket-router
$ git status -sb
## docs/escalation-runbook...origin/docs/escalation-runbook
$ git log --oneline origin/main..HEAD
668860e Drop the docs team from CODEOWNERS
a557f63 Describe the escalation path
```
<!-- /snippet -->

<!-- snippet: ch18/lab-23-2-codeowners/02-which-file -->
```text
$ for p in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do git cat-file -e origin/main:$p 2>/dev/null && echo "exists on main: $p"; done
exists on main: .github/CODEOWNERS
exists on main: docs/CODEOWNERS
```
<!-- /snippet -->

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

<!-- snippet: ch18/lab-23-2-codeowners/04-changed-paths -->
```text
$ git diff --name-only origin/main...HEAD
.github/CODEOWNERS
config/routing.yaml
docs/README.md
docs/runbooks/escalation.md
```
<!-- /snippet -->

**Part B, described from the documentation (not captured).** All quotations are from [about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) and [available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-a-pull-request-before-merging), read 2 October 2026.

- Step 2: the errors endpoint returns an object with an `errors` array ([REST: list CODEOWNERS errors](https://docs.github.com/en/rest/repos/repos#list-codeowners-errors)). It should be empty if both account names are spelled correctly and the second account has accepted the invitation. An owner "that doesn't exist or has insufficient access" is reported here and "will not be assigned".
- Step 3: two rulesets now target `main`. They are aggregated and "the most restrictive version of the rule applies": one approval, with code owner review.
- Step 4: the last pattern that matches `router/classify.py` is `/router/`, so the second account "is automatically requested for review" and appears under `reviewRequests`. `reviewDecision` should be `REVIEW_REQUIRED` ([GraphQL reference](https://docs.github.com/en/graphql/reference/pulls)), and `gh pr merge --squash` should be refused. You cannot approve it yourself: "Pull request authors cannot approve their own pull requests."
- Step 5: after the owner's approval, `reviewDecision` should be `APPROVED` and the merge should succeed.

### What happened internally

Part A used three facts that are all in the repository. Which file: the first of three paths that exists **on the base branch**. What it says: the content of that file at the base commit, not on your branch. Which paths: the three-dot diff of the pull request. From these, the owners follow by the rule "last matching pattern wins".

Part B added the two things the repository does not contain: GitHub requesting the reviewers, and the ruleset refusing the merge until an owner approved.

### Checkpoint

```bash
git diff --stat origin/main...HEAD -- .github/CODEOWNERS
git show HEAD:.github/CODEOWNERS | grep -n "^docs"
```

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

Your branch removed the `docs/*` line (exit status 1: no such line on your branch any more). The docs team is requested all the same, because the base version decides.

### Failure scenario

**Part A: the shortcut.** A colleague suggests testing CODEOWNERS with Git's own matcher: strip the owners, and ask `git check-ignore` which pattern matches each path.

```bash
git show origin/main:.github/CODEOWNERS | sed -E 's/[[:space:]]+@.*//' > ../patterns
git -c core.excludesFile=../patterns check-ignore -v --no-index config/routing.yaml docs/README.md docs/runbooks/escalation.md .github/CODEOWNERS
```

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

Line 2, the catch-all `*`, for three of the four paths. Compare with your prediction: by the documented CODEOWNERS rules, `config/routing.yaml` is decided by `*.yaml` and `docs/README.md` by `docs/*`. The shortcut is wrong for both.

**Part B: the sole owner.** The second account opens a pull request that touches `/router/`, a path it alone owns. You approve it.

```bash
gh auth switch --user "$SECOND"
git switch main && git pull --ff-only
git switch -c feature/vip-comment
printf '# vip tickets are routed by hand for now\n' >> router/classify.py
git commit -am "Explain the vip queue"
git push -u origin feature/vip-comment
gh pr create --base main --title "Explain the vip queue" --body "Lab 23.2, failure scenario"
gh auth switch --user "$ME"
gh pr review feature/vip-comment --approve
gh pr view feature/vip-comment --json reviewDecision,mergeStateStatus
gh pr merge feature/vip-comment --squash
```

The author of a pull request is the account that creates it with `gh pr create`; which account pushed the branch does not matter for this experiment.

By the documented rules the merge should be refused: the changed path has a code owner, the pull request "must be approved by that code owner", the only owner is the author, and authors cannot approve their own pull requests. Your approval is a valid approval and not an owner's approval. The documentation does not describe this combination in one place; record what the merge box and `mergeStateStatus` say.

### Recovery

**Part A.** Isolate why the shortcut fails:

```bash
printf '*\n*.yaml\n' > ../two
git -c core.excludesFile=../two check-ignore -v --no-index routing.yaml config/routing.yaml
printf 'docs/*\n' > ../two
git -c core.excludesFile=../two check-ignore -v --no-index docs/runbooks/escalation.md
rm ../two ../patterns
```

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

Git's ignore rules work on directories first: `config/` is matched by `*`, and Git never looks inside. And `docs/*` matches the directory `docs/runbooks`, so everything below it counts as matched, which the CODEOWNERS documentation explicitly denies for its own matcher. Git's matcher answers a different question. The reliable instruments are the documented rules, the errors endpoint, and the owner that GitHub shows for a file.

**Part B.** Give `/router/` a second owner. The change must reach the base branch before it helps:

```bash
git switch main && git pull --ff-only
git switch -c chore/router-owners
sed -i '' "s|^/router/ .*|/router/     @$SECOND @$ME|" .github/CODEOWNERS
git commit -am "Add a second owner for /router/"
git push -u origin chore/router-owners
gh pr create --base main --title "Add a second owner for /router/" --body "Lab 23.2, recovery"
gh auth switch --user "$SECOND"
gh pr review chore/router-owners --approve
gh auth switch --user "$ME"
gh pr merge chore/router-owners --squash --delete-branch
gh pr view feature/vip-comment --json reviewDecision,mergeStateStatus
```

The CODEOWNERS pull request touches `/.github/`, which both accounts own, so the second account can approve it. After it is merged, the base branch of `feature/vip-comment` names you as an owner of `/router/`. If the earlier approval was dismissed or the branch is now out of date, approve again and update it; then merge. This is the "one merge later" effect of Chapter 19, section 19.7.

### Verification

**Part A.**

<!-- snippet: ch18/lab-23-2-codeowners/08-verification -->
```text
$ git status -sb
## docs/escalation-runbook...origin/docs/escalation-runbook
$ git diff --name-only origin/main...HEAD | grep -c .
4
```
<!-- /snippet -->

**Part B.**

```bash
gh api "repos/$ORG/ticket-router-lab/codeowners/errors"
gh pr list --state merged --limit 5
gh ruleset check main
```

No errors, the pull requests merged, and both rulesets listed. When you are done with the module you may disable the second ruleset as shown in Lab 23.3, so that later labs do not need the second account.

### Questions

1. Part A: for each of the four changed paths, which line of the base file decides, and who is requested? (Answers in the solutions file.)
2. Why is the docs team requested although your branch deleted their line?
3. Why did `git check-ignore` report line 2 for `config/routing.yaml`? State the difference between the two matchers in one sentence.
4. Part B: after step 3 two rulesets target `main`, one with zero and one with one required approval. How many approvals are required, and which sentence of the documentation says so?
5. Part B: in the failure scenario your approval did not make the pull request mergeable. Which two documented rules combine to that result?
6. The recovery changed CODEOWNERS on a branch. At which moment did the change start to count for the blocked pull request?
7. What would have happened in step 2 if the second account had not yet accepted the invitation? Where would you have seen it?

## Lab 23.3: Three blocked merges to diagnose

### Objective

Diagnose three pull requests that cannot be merged, each for a different reason, by working from the rules to the cause instead of guessing. Use the local checks first, then the `/rules` page and the CLI.

### Prerequisites

Chapter 18, sections 18.8 and 18.17. Chapter 17, sections 17.6 and 17.7.

### Setup

**Part A.**

```bash
bash labs/ch18/setup-23-3-preflight.sh
labs/shell m23-3
```

Three branches are open on the server: `feature/priority-routing` (yours), `fix/threshold` and `docs/queues` (Ravi's). The script `preflight.sh` is in the sandbox root. Your local `main` is one commit behind the server.

**Part B.** The starter repository on GitHub with the ruleset of Lab 23.1. If the ruleset of Lab 23.2 is still active, disable it first, so that you can work alone:

```bash
ID2=$(gh api "repos/$ORG/ticket-router-lab/rulesets" --jq '.[] | select(.name=="lab-23-2 code owner review") | .id')
sed 's/"enforcement": "active"/"enforcement": "disabled"/' "$COURSE/labs/ch18/rulesets/lab-23-2-codeowners.json" \
  | gh api --method PUT "repos/$ORG/ticket-router-lab/rulesets/$ID2" --input -
```

### Commands

**Part A, in the lab shell.**

```bash
# 1. The tool, and fresh information
cat preflight.sh
cd you/ticket-router
git fetch

# 2. Three questions per branch
sh ../../preflight.sh feature/priority-routing
sh ../../preflight.sh fix/threshold
sh ../../preflight.sh docs/queues

# 3. Details for the two that are not yours
git merge-tree --write-tree --name-only origin/main origin/fix/threshold
git log --oneline --graph origin/main..origin/docs/queues
```

**Part B, in your normal shell.** A third ruleset adds a required status check named `ci/unit`, strict. Nothing in the repository reports that check.

```bash
gh api --method POST "repos/$ORG/ticket-router-lab/rulesets" --input "$COURSE/labs/ch18/rulesets/lab-23-3-checks.json"
gh ruleset check main

# Case A: a required check that nobody reports
git switch main && git pull --ff-only
git switch -c docs/case-a
printf '\nCase A.\n' >> README.md && git commit -am "Case A"
git push -u origin docs/case-a
gh pr create --base main --title "Case A: a check that never reports" --body "Lab 23.3"
gh pr checks --required
gh pr view --json mergeable,mergeStateStatus,reviewDecision
gh pr merge --squash
# the repair: report the status for the head commit through the API
gh api --method POST "repos/$ORG/ticket-router-lab/statuses/$(git rev-parse HEAD)" \
  -f state=success -f context=ci/unit -f description="Reported by hand in Lab 23.3"
gh pr checks --required
# do not merge case A yet

# Case B: the base moves, and case A is no longer up to date
git switch -c docs/case-b main
printf '# Notes\n' > NOTES.md && git add NOTES.md && git commit -m "Case B"
git push -u origin docs/case-b
gh pr create --base main --title "Case B: moves main" --body "Lab 23.3"
gh api --method POST "repos/$ORG/ticket-router-lab/statuses/$(git rev-parse HEAD)" -f state=success -f context=ci/unit
gh pr merge --squash --delete-branch
gh pr view docs/case-a --json mergeStateStatus
git fetch origin
git merge-base --is-ancestor origin/main docs/case-a; echo "exit status: $?"
gh pr merge docs/case-a --squash
# the repair: update the branch, then the check must be reported again for the NEW head commit
gh pr update-branch docs/case-a
git switch docs/case-a && git pull
gh pr checks --required
gh api --method POST "repos/$ORG/ticket-router-lab/statuses/$(git rev-parse HEAD)" -f state=success -f context=ci/unit
gh pr merge --squash --delete-branch

# Case C: no merge method is left
gh repo edit "$ORG/ticket-router-lab" --enable-squash-merge=false
git switch main && git pull --ff-only
git switch -c docs/case-c
printf '\nCase C.\n' >> README.md && git commit -am "Case C"
git push -u origin docs/case-c
gh pr create --base main --title "Case C: no method allowed" --body "Lab 23.3"
gh api --method POST "repos/$ORG/ticket-router-lab/statuses/$(git rev-parse HEAD)" -f state=success -f context=ci/unit
gh pr merge --squash
gh pr merge --merge
# the repair
gh repo edit "$ORG/ticket-router-lab" --enable-squash-merge
gh pr merge --squash --delete-branch
```

### Expected output

**Part A.**

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

Three branches, three different findings: not up to date; conflict; a merge commit in the range.

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

**Part B, described from the documentation (not captured).** Sources: [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets), [REST: commit statuses](https://docs.github.com/en/rest/commits/statuses#create-a-commit-status), [GraphQL reference](https://docs.github.com/en/graphql/reference/pulls), read 2 October 2026.

- **Case A.** A required check with no result leaves the pull request waiting; the troubleshooting page quotes the merge-box text "Waiting for status to be reported". `gh pr checks --required` exits with status 8 while checks are pending (`gh pr checks --help`). `mergeStateStatus` should be `BLOCKED`. After the API call, the check is satisfied: "Users with push access in a repository can create commit statuses for a given SHA", and a required status check can be a check or a status. This is also the lesson of Chapter 18, section 18.8: an unpinned required check can be reported by anyone with write access.
- **Case B.** After case B is merged, case A's `mergeStateStatus` should be `BEHIND` ("the head ref is out of date"), the local ancestry test prints exit status 1, and the merge is refused because the ruleset is strict: "The topic branch **must** be up to date with the base branch before merging." `gh pr update-branch` merges the base into the head branch on GitHub. That creates a new head commit, and "Required checks must pass on the latest commit SHA", so the check is missing again until you report it for the new commit.
- **Case C.** Squash is disabled in the repository and is the only method the ruleset of Lab 23.1 allows: "if the repository has disabled a merge method and the ruleset required a different method, the merge will be blocked." Both merge commands should fail, for different reasons. Read both messages.

### What happened internally

A blocked merge is always one unmet condition from one layer. Case A was a rule waiting for data that nothing produced. Case B was a rule about ancestry, which `git merge-base --is-ancestor` answers on your machine before GitHub tells you. Case C was a contradiction between two layers, a repository setting and a ruleset, each reasonable alone.

The Part A script asks the questions that need no platform: how many commits, is the base tip an ancestor of the head, does the test merge succeed, and how many merge commits are in the range.

### Checkpoint

In Part B, after the three cases, all three pull requests are merged:

```bash
gh pr list --state merged --limit 5
gh ruleset check main
git switch main && git pull --ff-only && git log --oneline -4
```

In Part A, write down for each of the three branches which rule of Chapter 18 would refuse it, and under which merge method `docs/queues` could still be merged while `main` requires linear history.

### Failure scenario

Repair your own branch in Part A, by habit: merge `main`.

```bash
git switch -q feature/priority-routing
git merge main
git push
sh ../../preflight.sh feature/priority-routing
```

<!-- snippet: ch18/lab-23-3-preflight/04-failure -->
```text
# Repairing your own branch. The habit: merge main.
$ git switch -q feature/priority-routing
$ git merge main
Already up to date.
$ git push
Everything up-to-date
$ sh ../../preflight.sh feature/priority-routing
== feature/priority-routing -> main
commits in the pull request: 3
up to date with main: no
test merge: clean
merge commits among them: 0
```
<!-- /snippet -->

"Already up to date", and the branch is still not up to date with the server's `main`.

### Recovery

```bash
git rev-parse main origin/main
git branch -vv
git merge origin/main
git push
```

<!-- snippet: ch18/lab-23-3-preflight/05-diagnose -->
```text
$ git rev-parse main origin/main
9a383e547a1c8840f3c5c7b23bfab6120f366ed0
9aa221a9fb05716040012e33f1e7c3074f948edc
$ git branch -vv
* feature/priority-routing 16d4788 [origin/feature/priority-routing] Fix the name of the escalations queue
  main                     9a383e5 [origin/main: behind 1] Add classifier test
```
<!-- /snippet -->

Your local `main` is one commit behind `origin/main`. `git merge main` merged a stale ref. The rule on the server is about the server's branch, which your clone knows as `origin/main`.

<!-- snippet: ch18/lab-23-3-preflight/06-recovery -->
```text
$ git merge origin/main
Merge made by the 'ort' strategy.
 config/routing.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
To ../../server/ticket-router.git
   16d4788..c8b4932  feature/priority-routing -> feature/priority-routing
```
<!-- /snippet -->

### Verification

```bash
sh ../../preflight.sh feature/priority-routing
git status -sb
```

<!-- snippet: ch18/lab-23-3-preflight/07-verification -->
```text
$ sh ../../preflight.sh feature/priority-routing
== feature/priority-routing -> main
commits in the pull request: 4
up to date with main: yes
test merge: clean
merge commits among them: 1
$ git status -sb
## feature/priority-routing...origin/feature/priority-routing
```
<!-- /snippet -->

Up to date, clean test merge, four commits of which one is a merge commit. Under squash that merge commit never reaches `main`.

In Part B, tidy up. Disable the check ruleset, or every later pull request in this repository will wait for `ci/unit`:

```bash
ID3=$(gh api "repos/$ORG/ticket-router-lab/rulesets" --jq '.[] | select(.name=="lab-23-3 required check") | .id')
sed 's/"enforcement": "active"/"enforcement": "disabled"/' "$COURSE/labs/ch18/rulesets/lab-23-3-checks.json" \
  | gh api --method PUT "repos/$ORG/ticket-router-lab/rulesets/$ID3" --input -
gh api "repos/$ORG/ticket-router-lab/rulesets" --jq '.[] | "\(.id) \(.enforcement) \(.name)"'
```

### Questions

1. Part A: why did `git merge main` report "Already up to date" while the branch was behind the server? What is the general rule for which ref to merge or rebase onto?
2. `docs/queues` contains a merge commit and `main` requires linear history. Can the pull request be merged? With which method, and why?
3. Case A: who is able to report a required status, according to the documentation, and what setting restricts it?
4. Case B: after `gh pr update-branch`, why was the check missing again although you had reported it?
5. Case C: neither the repository setting nor the ruleset was wrong by itself. How would you prevent such a contradiction in a team?
6. For each of the three cases, which `mergeStateStatus` value did you observe, and which one command gave you the cause most directly?
7. You are told "everything is green and I still cannot merge". List the first three things you check, in order.
