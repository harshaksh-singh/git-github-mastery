# Chapter 27: Open source and team workflows

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch27/`.

## 27.1 Why this matters

Four questions a CTO can ask, none of which is about a command:

1. "We ship one hosted version today. Next quarter two enterprise customers will run our gateway on their own hardware and stay a version behind. Does our branching model survive that?"
2. "A hotfix went out as 1.4.1. Why did 1.5.0 ship the same bug again?"
3. "Somebody on the team says the research proves trunk-based development is best. Does it?"
4. "Our pull request to an open-source dependency has been ignored for three weeks. What did we do wrong?"

Every answer in this chapter comes from two facts you already have. A branch is a ref that names a commit ([Chapter 7: Branches](ch07-branches.md)), so a "branching strategy" is nothing but an agreement about which refs exist, who may move them, and in which direction commits travel between them. And a release is a tag that names a commit ([Chapter 14B: Configuration, tags and signing](ch14b-config-tags-signing.md)), so "what did we ship" is always a question you can put to the commit graph.

The second question has a precise answer: the fix was committed on the release branch and never reached `main`, and nobody ran the one-line check that would have listed it (section 27.10). The third: no, and section 27.13 says what the research does show. The first and the fourth are decisions, and the chapter gives you the vocabulary and the evidence for them.

The demos use one project, `promptgate`: a gateway between product teams and LLM providers that routes requests to a model, enforces per-tenant limits and streams answers back. 

A note on layers. Branches, tags, merges and cherry-picks are Git. Forks, pull requests, merge queues, rulesets and releases are GitHub. A workflow is a convention that people hold.

## 27.2 The fork workflow, end to end

**In one sentence.** In the fork workflow you never push to the project's repository: you push to a server-side copy that you own, and you ask the project to take your commits through a pull request.

**Analogy.** A journal submission. You do not edit the journal; you send a manuscript, reviewers ask for changes, you send a revision, and an editor decides. The analogy breaks at storage: on GitHub your copy and the journal's share one object store (a fork network), so what you push to your fork can be reached from the upstream repository by commit ID, as [Chapter 17: Pull requests](ch17-pull-requests.md), section 17.15 documents.

**Precisely.** Three repositories are involved and each has its own refs:

| Repository | Remote name in your clone | You can | You use it to |
|---|---|---|---|
| The project (upstream) | `upstream` | fetch | learn what the project's `main` is now |
| Your fork | `origin` | fetch and push | publish branches for pull requests |
| Your clone | none: it is the local repository | everything | do the work |

The mechanics of two remotes, `remote.pushDefault` and `@{push}` were built in [Chapter 12: Remote operations](ch12-remote-operations.md), section 12.10, and the platform side (the `refs/pull/N/head` ref, what a maintainer can push to, what a workflow run from a fork may see) in Chapter 17, section 17.15.

**Picture.**

```text
    upstream: the project                              origin: your fork
  +---------------------------+   (1) fork           +---------------------------+
  | main                      | -------------------> | main                      |
  | refs/pull/57/head  <------+--- (5) pull request  | fix/suspended-tenant      |
  +---------------------------+                      +---------------------------+
        |           ^                                      |              ^
        | (3) fetch | (8) merge, by a maintainer           | (2) clone    | (4) push
        v           |                                      v              |
  +----------------------------------------------------------------------------+
  | your clone:   main    fix/suspended-tenant    upstream/main    origin/main  |
  |   (6) review asks for changes  ->  (7) commit and push again to origin      |
  +----------------------------------------------------------------------------+
```

**The ten steps.** Steps 1, 5, 6 and 8 happen on GitHub and are given from the documentation ([forks reference](https://docs.github.com/en/pull-requests/reference/forks), [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow)); the commands were checked with `gh <command> --help` and are not run here.

```bash
# 1. Fork on GitHub, and 2. clone the fork. gh does both, and names the remotes origin and upstream.
gh repo fork example-org/promptgate --clone
cd promptgate

# 3. Start from the project's current main, not from your fork's copy of it.
git fetch upstream
git switch -c fix/suspended-tenant upstream/main

# ... edit, test ...
git commit -am "Fix limit 0 being treated as unlimited"

# 4. Publish the branch on your fork.
git push -u origin fix/suspended-tenant

# 5. Open the pull request against the upstream repository.
gh pr create --repo example-org/promptgate --base main --fill

# 6 and 7. Review asks for changes: commit and push again. The pull request follows the branch.
git commit -am "Test that a limit of 0 blocks the tenant"
git push

# 8. A maintainer merges. 9. Bring main up to date. 10. Delete the branch in both places.
```

**See it.** No network is available in the lab, so two bare repositories play the two servers: `upstream/promptgate.git` is the project, maintained by Asha, and `fork/promptgate.git` is your fork. `git clone --bare` is used in the fixture where GitHub would fork.

<!-- snippet: ch27/fork-sync/01-clone-fork -->
```text
# fork/promptgate.git plays your fork on the platform. Clone it, then name the upstream:
$ git clone -q fork/promptgate.git you/promptgate
$ cd you/promptgate
$ git remote add upstream ../../upstream/promptgate.git
$ git fetch -q upstream
$ git remote -v
origin	../../fork/promptgate.git (fetch)
origin	../../fork/promptgate.git (push)
upstream	../../upstream/promptgate.git (fetch)
upstream	../../upstream/promptgate.git (push)
$ git branch -a -vv
* main                  4ebb785 [origin/main] Add gateway with tenant limits
  remotes/origin/HEAD   -> origin/main
  remotes/origin/main   4ebb785 Add gateway with tenant limits
  remotes/upstream/HEAD -> upstream/main
  remotes/upstream/main 4ebb785 Add gateway with tenant limits
```
<!-- /snippet -->

Four refs name one commit, `4ebb785`. `origin/main` is your clone's record of the fork and `upstream/main` its record of the project. They will drift apart.

<!-- snippet: ch27/fork-sync/02-branch-commit-push -->
```text
$ git switch -c fix/suspended-tenant upstream/main
Switched to a new branch 'fix/suspended-tenant'
branch 'fix/suspended-tenant' set up to track 'upstream/main'.
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git push -u origin fix/suspended-tenant
To ../../fork/promptgate.git
 * [new branch]      fix/suspended-tenant -> fix/suspended-tenant
branch 'fix/suspended-tenant' set up to track 'origin/fix/suspended-tenant'.
```
<!-- /snippet -->

Read the two "set up to track" lines. `git switch -c <branch> upstream/main` made `upstream/main` the upstream of the new branch, which is the right base for comparison. `git push -u origin` then replaced it with `origin/fix/suspended-tenant`, which is the right destination for pushes. After this command `git status` compares you with your fork, not with the project. Compare with the project explicitly: `git log --oneline upstream/main..HEAD`.

**Inside `.git`.** Nothing is new. `refs/remotes/upstream/*` and `refs/remotes/origin/*` are two sets of remote-tracking refs filled by two fetch refspecs in `.git/config`. The pull request does not exist in your repository at all.

| Step | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git fetch upstream` | unchanged | unchanged | unchanged | unchanged | `refs/remotes/upstream/*` move; `FETCH_HEAD` written | unchanged | unchanged |
| `git switch -c fix/... upstream/main` | files of `upstream/main` | matches it | symbolic ref to the new branch | created at `upstream/main` | `branch.<name>.remote` and `.merge` written | unchanged | unchanged |
| `git push -u origin fix/...` | unchanged | unchanged | unchanged | unchanged | `refs/remotes/origin/fix/...` created; upstream configuration rewritten | the fork gains a branch | the fork shows the branch; no pull request yet |
| `gh pr create` | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged | a pull request object and `refs/pull/N/head` in upstream |

**In production.** Forks are not only for open source: an organization that employs contractors who must not have write access uses the same triangle internally. The cost is that secrets are withheld from workflows triggered by pull requests from forks, which matters for LLM evaluation jobs ([Chapter 28: AI/ML workflows](ch28-ai-ml-workflows.md), section 28.11).

## 27.3 When upstream moves: three ways to sync the fork, two ways to update the branch

**In one sentence.** Your fork's `main` is a copy that nothing updates for you, and your feature branch is based on a commit that is getting older; bringing each up to date is a separate operation.

**Precisely.** There are two different things to keep current, and people mix them up:

- **The fork's default branch.** It should be an exact copy of the project's `main`. If you never commit on it, updating it is always a fast-forward.
- **Your feature branch.** It contains your commits on top of an old upstream commit. Updating it means either replaying your commits on the new tip (rebase) or merging the new tip into the branch.

GitHub documents three ways to do the first ([syncing a fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork)). Two run on the server and are described from the documentation; the third is plain Git and is run below.

| Way | Where it runs | What it does | What it leaves for you |
|---|---|---|---|
| The **Sync fork** control on the fork's page (label from the documentation; the interface changes) | GitHub | updates the fork's branch from upstream | your clone is now behind `origin`: `git pull --ff-only` |
| `gh repo sync <owner>/<fork>` | GitHub, through the API | fast-forwards the fork's default branch from its parent; `--force` hard-resets it instead | the same |
| `git fetch upstream`, fast-forward, `git push origin main` | your clone | moves your local `main`, then the fork's | nothing: the clone is already current |

`gh repo sync` without an argument updates the local repository instead: the destination is the argument (`gh repo sync --help`).

**See it.** While your pull request waits, Asha merges somebody else's work into the project:

<!-- snippet: ch27/fork-sync/03-upstream-moved -->
```text
# While your pull request waits for review, the maintainer merges other work:
$ git fetch upstream
From ../../upstream/promptgate
   4ebb785..7de9633  main       -> upstream/main
$ git rev-list --left-right --count upstream/main...origin/main
1	0
$ git log --oneline --graph --all
* 7de9633 Stream tokens to the client
| * a83a713 Fix limit 0 being treated as unlimited
|/  
* 4ebb785 Add gateway with tenant limits
```
<!-- /snippet -->

`1	0`: one commit on the left side (`upstream/main`) that the right side (`origin/main`) lacks, and none the other way. That second zero is what makes the sync safe. The way with plain Git:

<!-- snippet: ch27/fork-sync/04-sync-main -->
```text
# Bring the main branch of the fork up to date. Your local main is only a relay:
$ git switch -q main
$ git merge --ff-only upstream/main
Updating 4ebb785..7de9633
Fast-forward
 gateway/stream.py | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 gateway/stream.py
$ git push origin main
To ../../fork/promptgate.git
   4ebb785..7de9633  main -> main
$ git rev-list --left-right --count upstream/main...origin/main
0	0
```
<!-- /snippet -->

`--ff-only` is the guard. If you had committed on `main` by mistake, the merge would stop instead of creating a merge commit that exists only in your fork and that every later pull request would carry.

Now the feature branch. **Way 1, rebase:**

<!-- snippet: ch27/fork-sync/05-update-by-rebase -->
```text
# Update the feature branch, way 1: replay it on the new upstream tip.
$ git switch -q fix/suspended-tenant
$ git rebase upstream/main
Rebasing (1/1)
Successfully rebased and updated refs/heads/fix/suspended-tenant.
$ git push
To ../../fork/promptgate.git
 ! [rejected]        fix/suspended-tenant -> fix/suspended-tenant (non-fast-forward)
error: failed to push some refs to '../../fork/promptgate.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease --force-if-includes
To ../../fork/promptgate.git
 + a83a713...3560caf fix/suspended-tenant -> fix/suspended-tenant (forced update)
$ git log --oneline --graph --all
* 3560caf Fix limit 0 being treated as unlimited
* 7de9633 Stream tokens to the client
* 4ebb785 Add gateway with tenant limits
```
<!-- /snippet -->

The rebase replaced commit `a83a713` with `3560caf`: same change, new parent, new ID ([Chapter 9: Rebase](ch09-rebase.md)). The fork still had the old commit, so the plain push was rejected as a non-fast-forward, and the push that succeeded was a forced one. 🔴 DANGEROUS: `git push --force-with-lease --force-if-includes`. What it changes: the branch on the fork, to a commit that does not descend from the old one. What it can destroy: commits on that server branch that are not in your clone, for example a fix a maintainer pushed to your pull request branch. Preview: `git fetch origin`, then `git log HEAD..origin/fix/suspended-tenant` lists what would be dropped. Recovery: push the old tip back from any clone that still has it; your own old tip is in the branch reflog. When it is appropriate: on a branch that only you push to, after a rebase. The lease makes the push succeed only if the fork's branch is where your clone last saw it, and `--force-if-includes` only if you have integrated what you last saw; Chapter 12, section 12.8 explains both conditions and how a background fetch defeats the first.

**Way 2, merge:**

<!-- snippet: ch27/fork-sync/06-update-by-merge -->
```text
# Upstream moved again. Way 2: merge upstream into the branch. No commit is rewritten,
# so a plain push is enough:
$ git fetch -q upstream
$ git merge -m "Merge upstream main into fix/suspended-tenant" upstream/main
Merge made by the 'ort' strategy.
 gateway/fallback.py | 5 +++++
 1 file changed, 5 insertions(+)
 create mode 100644 gateway/fallback.py
$ git push
To ../../fork/promptgate.git
   3560caf..44d750c  fix/suspended-tenant -> fix/suspended-tenant
$ git log --oneline --graph fix/suspended-tenant
*   44d750c Merge upstream main into fix/suspended-tenant
|\  
| * bb1ddd2 Fall back to a second model on timeout
* | 3560caf Fix limit 0 being treated as unlimited
|/  
* 7de9633 Stream tokens to the client
* 4ebb785 Add gateway with tenant limits
```
<!-- /snippet -->

No commit changed its ID, so the push is an ordinary fast-forward. The price is the merge commit `44d750c` in the middle of your branch.

| | Rebase onto `upstream/main` | Merge `upstream/main` into the branch |
|---|---|---|
| Your commit IDs | change | stay |
| Push | forced | plain |
| Branch history | linear, reads as if written today | has "merge upstream" commits |
| Review comments already made | may lose their anchor; the reviewer needs `git range-diff` to see what changed (Chapter 9, section 9.14) | stay attached |
| Conflicts | resolved once per replayed commit | resolved once, in the merge |

Which to use is the project's decision: read its contribution guide. Where it is silent, rebase freely until review starts and add commits afterwards, because a reviewer who has read a commit should be able to trust that it has not changed.

**The review round, and the squash merge.** The reviewer asks for a test. You add a commit, push, and the pull request updates because it follows the branch:

<!-- snippet: ch27/fork-sync/07-review-round -->
```text
# The reviewer asks for a test. Changes after review start are added, not rewritten:
$ mkdir -p tests && printf 'from gateway.limits import LIMITS, allowed\n\n\ndef test_suspended():\n    LIMITS["acme"] = 0\n    assert not allowed("acme", 0)\n' > tests/test_limits.py
$ git add tests && git commit -q -m "Test that a limit of 0 blocks the tenant"
$ git push
To ../../fork/promptgate.git
   44d750c..147ed67  fix/suspended-tenant -> fix/suspended-tenant
$ git log --oneline upstream/main..HEAD
147ed67 Test that a limit of 0 blocks the tenant
44d750c Merge upstream main into fix/suspended-tenant
3560caf Fix limit 0 being treated as unlimited
```
<!-- /snippet -->

Then the maintainer squash-merges. The lab imitates the merge button with `git merge --squash` in Asha's clone; GitHub documents the result as one new commit on the base branch ([merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github)).

<!-- snippet: ch27/fork-sync/08-after-squash-merge -->
```text
# The maintainer squash-merges the pull request. Upstream main has one new commit:
$ git fetch upstream
From ../../upstream/promptgate
   bb1ddd2..16e9e75  main       -> upstream/main
$ git log --oneline -2 upstream/main
16e9e75 Fix limit 0 being treated as unlimited (#57)
bb1ddd2 Fall back to a second model on timeout
$ git switch -q main && git merge -q --ff-only upstream/main && git push -q origin main
# Your commits are not ancestors of main: the squash made one new commit with a new ID.
$ git merge-base --is-ancestor fix/suspended-tenant main
[exit status: 1]
# Compare content instead. No output means main has everything the branch has:
$ git diff --stat main fix/suspended-tenant
$ git branch -d fix/suspended-tenant
warning: deleting branch 'fix/suspended-tenant' that has been merged to
         'refs/remotes/origin/fix/suspended-tenant', but not yet merged to HEAD
Deleted branch fix/suspended-tenant (was 147ed67).
$ git push origin --delete fix/suspended-tenant
To ../../fork/promptgate.git
 - [deleted]         fix/suspended-tenant
```
<!-- /snippet -->

```text
Observed behavior : after a squash merge, "is my branch merged?" gets three different answers.
Git state         : upstream main has one new commit, 16e9e75. Your branch tip is 147ed67.
                    147ed67 is not an ancestor of 16e9e75.
Mechanism         : "merged" in Git means "reachable from". git merge-base --is-ancestor and
                    git branch --merged both test reachability, and a squash creates a commit
                    with one parent and no link to your commits.
Root cause        : the merge method discarded the ancestry and kept the content.
Why Git does this : a commit's parents are part of its ID. Git cannot record "these commits were
                    folded into that one" without a second parent, and a second parent is
                    exactly what a squash omits.
Correct fix       : test content, not ancestry: an empty "git diff main <branch>" here, or the
                    merge-tree comparison of Lab 34.1 when main has moved further.
Prevention        : delete the branch right after the merge, on the fork and locally, and never
                    reuse it. Chapter 17, section 17.12 shows what reuse does to the next pull request.
```

One line of that transcript contradicts a rule you may have read: `git branch -d` deleted a branch that was not merged into `main`, with a warning. The manual explains it: `-d` requires the branch to be "fully merged in its upstream branch, or in `HEAD` if no upstream was set". The upstream here is `origin/fix/suspended-tenant`, which has every commit. On a branch that was never pushed with `-u`, the same command refuses, and that is the case older tutorials describe.

## 27.4 Etiquette, and the maintainer's side

**In one sentence.** A maintainer's scarce resource is attention, and every convention of open-source contribution is a way of spending less of it per accepted change.

**Before you write code.**

- **Read the contribution guide.** GitHub shows a repository's `CONTRIBUTING` file when someone opens an issue or pull request, and since 7 August 2025 in the repository's tab bar and sidebar ([setting guidelines for contributors](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors), [changelog](https://github.blog/changelog/2025-08-07-contributing-guidelines-now-visible-in-repository-tab-and-sidebar/)). It tells you the branch to target, the merge method, the test command, the commit message convention and whether a sign-off or a contributor agreement is required. Its templates are part of the same contract ([templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)).
- **Issue first for anything large.** A pull request nobody asked for forces the maintainer to choose between reviewing work that does not fit the roadmap and rejecting work somebody spent a week on. An issue costs both sides ten minutes.

**When you open the pull request.**

- **One logical change.** Martin Fowler's catalogue of branching patterns notes that open-source maintainers integrate work from occasional contributors they do not yet know, which is why pre-merge review of a self-contained branch fits open source so well ([Patterns for Managing Source Code Branches](https://martinfowler.com/articles/branching-patterns.html)). A small, self-contained change is one a stranger can evaluate.
- **Say what you tested.** For an ML change: which evaluation set, which metric, which commit.
- **Leave "allow edits by maintainers" on** for a fork you own; it lets a maintainer push a small fix to your branch instead of asking for another round (Chapter 17, section 17.15).
- **Expect checks to behave differently.** Workflows on a pull request from a fork run without the project's secrets, and in a public repository the default is that first-time contributors need a maintainer's approval before workflows run ([Actions settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#controlling-changes-from-forks-to-workflows-in-public-repositories)). A red check that needs a secret is not your bug; say so in the pull request instead of pushing guesses.

**While it is in review.**

- Answer every comment, and do not force-push over a review in progress unless the project asks for it.
- Do not open a second pull request because the first is quiet. Ask once, after a reasonable wait, in the place the project names.

**The maintainer's side.** The same economics apply in reverse, and most of the tools are platform features covered elsewhere in this book:

| Maintainer need | Tool | Where |
|---|---|---|
| Tell contributors the rules once | `CONTRIBUTING.md`, templates, [default community health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file) | this section |
| Never run untrusted code with secrets | `pull_request` instead of `pull_request_target`; approval for outside contributors | Chapter 21A: GitHub Actions security |
| Route review to the right people | `CODEOWNERS` | [Chapter 19: CODEOWNERS](ch19-codeowners.md) |
| Keep `main` releasable | required checks, required review, merge queue | [Chapter 18: Branch protection and rulesets](ch18-branch-protection.md) |
| Keep credit when squashing | read the proposed squash message before confirming; who GitHub records as author and co-authors is flagged as unverified in Chapter 17 | Chapter 17, section 17.8 |

## 27.5 Branch names are conventions, not laws

**In one sentence.** `main`, `develop`, `feature/*`, `bugfix/*`, `hotfix/*` and `release/*` are names that people agreed on; Git gives none of them a meaning.

**Precisely.** To Git, `refs/heads/release/1.4` is a ref whose name happens to contain a slash. The slash matters in exactly two technical ways. It lets patterns select groups of branches (`git branch --list 'release/*'`, a ruleset target such as `release/**`, a workflow filter such as `branches: ['release/**']`). And, in the files backend, it makes `release` a directory, so a branch named `release` and a branch named `release/1.4` cannot both exist ([Chapter 7: Branches](ch07-branches.md)).

| Name | Usual meaning | What gives it force |
|---|---|---|
| `main` | the integration branch; the default branch | the repository's default-branch setting; a ruleset |
| `develop` | Git Flow's integration branch, with `main` reserved for released code | only the team's agreement |
| `feature/<topic>` | work in progress on one change | nothing; often a naming rule |
| `bugfix/<topic>` | a fix that is not urgent, taking the normal path | nothing |
| `hotfix/<topic>` | an urgent fix to something already released | nothing in Git; sometimes a faster review rule |
| `release/<version>` | the line from which one version and its patches are tagged | a ruleset; deployment workflows that trigger on the pattern |

The lab configuration sets `init.defaultBranch=main`; unconfigured Git 2.55 still creates `master`. Neither name does anything the other does not.

**In production.** The convention earns its keep when rules are attached to it. "Nobody pushes to `release/**` except through a pull request with two approvals" is one ruleset with one pattern, and it works only if every release branch is named that way. A name that carries the author (`asha/rerun`) says the branch is private and may be rebased. Choose a scheme, write it in `CONTRIBUTING.md`, and enforce the parts that matter with a ruleset ([Chapter 18: Branch protection and rulesets](ch18-branch-protection.md)).

## 27.6 GitHub Flow

**In one sentence.** One long-lived branch that is always deployable, short branches off it, a pull request for each, and deployment right after the merge.

**Precisely.** GitHub's documentation describes six steps: create a branch, make changes, create a pull request, address review comments, merge, delete the branch ([GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow)). Scott Chacon's 2011 essay, where the name comes from, adds the rules that give it its character: anything on the main branch is deployable, and you deploy immediately after merging; he also gives the reason GitHub did not use Git Flow, which is that GitHub deployed many times a day while Git Flow is organised around releases ([GitHub Flow](https://scottchacon.com/2011/08/31/github-flow/)). Fowler's reading is that the model assumes a single production version, so release branches and hotfix branches disappear: a hotfix is one more short branch ([Fowler](https://martinfowler.com/articles/branching-patterns.html)).

**Picture.**

```text
              o---o   feature/streaming            o   hotfix/suspended-tenant
             /     \                              / \
    ---o----o-------M1------M2------M3-----------o---M4---   main      (HEAD -> main)
                     \     /  ^      ^                ^
                      o---o   |      |                |
              feature/tenant-limits  |                tag v1.4.1, deploy
                              |      feature/batch-api merged
                              tag v1.4.0, deploy
```

**What it assumes.** That there is one live version, that `main` can be deployed at any commit, and that a broken deployment is repaired by rolling forward or back quickly. Microsoft's description of its own practice records where the strict form stops scaling: when a repository completes more than 200 pull requests a day, deploying each one before or after merge turns into a queue, so Microsoft batches deployments into sprint releases instead ([How Microsoft develops with DevOps](https://learn.microsoft.com/en-us/devops/develop/how-microsoft-develops-devops)).

**What it does not say.** How long a feature branch may live, or what to do when a customer cannot take the newest version. Section 27.9 shows the consequence with a real history.

## 27.7 Git Flow, and its author's 2020 note

**In one sentence.** Two long-lived branches, `main` for released code and `develop` for integration, plus three kinds of supporting branch: feature, release and hotfix.

**Precisely.** Vincent Driessen published "A successful Git branching model" on 5 January 2010. Feature branches start from and merge into `develop`, with `--no-ff` so that each feature stays visible as a unit. A release branch is cut from `develop`, receives only stabilization commits, and is merged into `main` (and tagged) and back into `develop`. A hotfix branch is cut from `main`, and is merged into `main` (and tagged) and into `develop` ([nvie.com](https://nvie.com/posts/a-successful-git-branching-model/)).

**See it.** The same project and the same changes as in the other demos, arranged as Git Flow prescribes:

<!-- snippet: ch27/git-flow/03-graph -->
```text
$ git log --oneline --graph --decorate --all
*   24124ab (HEAD -> develop) Merge hotfix/1.4.1 into develop
|\  
* \   f2b87da Merge pull request #43 from feature/batch-api
|\ \  
| * | b713222 Add batch endpoint
|/ /  
* |   989ca76 Merge release/1.4.0 back into develop
|\ \  
| | | *   a3de55c (tag: v1.4.1, main) Hotfix 1.4.1
| | | |\  
| | | |/  
| | |/|   
| | * | 1607dca Fix limit 0 being treated as unlimited
| | |/  
| | *   2a0387c (tag: v1.4.0) Release 1.4.0
| | |\  
| | |/  
| |/|   
| * | 7237206 Bump version to 1.4.0
|/ /  
* |   7d9c521 Merge pull request #42 from feature/tenant-limits
|\ \  
| * | c3cc79e Read tenant limits with a default
| |/  
* |   e27adc8 Merge pull request #41 from feature/streaming
|\ \  
| |/  
|/|   
| * 39a039a Stream tokens to the client
|/  
* b6e2f58 (tag: v1.3.0) Add per-tenant rate limits
* 9df3d07 Add gateway skeleton
```
<!-- /snippet -->

Find the hotfix commit `1607dca`. It has two children: the merge `a3de55c` on `main`, tagged `v1.4.1`, and the merge `24124ab` on `develop`. That double merge is the model's answer to "how does a fix reach both lines", and it is a merge-upward answer (section 27.10).

<!-- snippet: ch27/git-flow/04-what-ships -->
```text
$ git log --oneline --no-merges v1.4.0..v1.4.1
1607dca Fix limit 0 being treated as unlimited
$ git log --oneline --first-parent main
a3de55c Hotfix 1.4.1
2a0387c Release 1.4.0
b6e2f58 Add per-tenant rate limits
9df3d07 Add gateway skeleton
$ git rev-list --count --merges v1.3.0..develop
6
$ git branch --contains v1.4.1^2
* develop
  main
```
<!-- /snippet -->

The patch release contains the fix and nothing else, because `main` receives only releases and hotfixes. `git log --first-parent main` is a release log, one line per release. And the history between `v1.3.0` and `develop` contains six merge commits for three features, one release and one hotfix.

**The 2020 note.** On 5 March 2020 the author added a "note of reflection" at the top of the article. The report summarizes it this way: the model was conceived for explicitly versioned software that may need several versions supported in the wild; a team doing continuous delivery of a web application should adopt a simpler workflow such as GitHub Flow; and readers should weigh their own context, because no model is a cure-all ([nvie.com](https://nvie.com/posts/a-successful-git-branching-model/)). Fowler adds that Git Flow says nothing about how long feature branches live, and Atlassian's tutorial now labels Gitflow a legacy workflow ([Atlassian](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)).

> **Outdated advice.** "Use Git Flow" as a default for every project. The author of the model restricts it to explicitly versioned software with several supported versions. For a continuously deployed service it adds a second long-lived branch and two merges per release, and the tags already record what was released.

**When it still fits.** Installed software, firmware, SDKs and libraries with several maintained versions, and organizations where a release is a scheduled, audited event. Even there, the part that does the work is the release branch, which you can have without `develop` (section 27.8).

## 27.8 GitLab Flow, trunk-based development, release branches and Release Flow

All four keep one integration branch and differ in what, if anything, sits downstream of it.

**GitLab Flow.** GitLab defines it as a simplified strategy that works directly with `main` and adds, where needed, a production branch, environment branches such as staging and production, or release branches for software shipped in versions ([What is GitLab Flow?](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/)). Among its eleven published rules are: fix bugs in `main` first and release branches second; releases are based on tags; pushed commits are never rebased ([best practices](https://about.gitlab.com/topics/version-control/what-are-gitlab-flow-best-practices/)).

```text
    ---o---o---o---o---o---o   main          every merge deploys to staging
                \       \
    -------------M-------M     production    a merge from main deploys to production
```

> **Unverified.** GitLab's original 2014 "GitLab Flow" document is no longer reachable on docs.gitlab.com; the phrase "upstream first" for its fix direction was read only through a mirror, according to the research notes. The two pages linked above are current.

**Trunk-based development.** Developers integrate into one branch, the trunk, and avoid other long-lived development branches. Very small teams may commit straight to the trunk; larger teams use short-lived feature branches, which should last no more than a couple of days, belong to one developer or a pair, and be deleted after the merge; long-running changes are handled with feature flags and branch by abstraction instead of long branches ([trunkbaseddevelopment.com](https://trunkbaseddevelopment.com/), [short-lived feature branches](https://trunkbaseddevelopment.com/short-lived-feature-branches/)). Fowler treats it as close to a synonym for continuous integration. The difference from GitHub Flow is one of degree, not of kind: both have one long-lived branch, and trunk-based development adds a limit on branch lifetime and, in its strictest form, drops the pre-merge review gate.

```text
    ---o---o---o---o---o---o---o---o---   main (trunk)
        \_/     \_/ \_/         \_/        branches that live hours to two days
```

**Release branches.** A release branch is cut from the trunk shortly before a release, receives only fixes, and is the place the release and its patches are tagged. The trunk-based development site states the rules: cut late; the branch may start from a commit older than the trunk's head; it is never merged back; it is deleted when the version is no longer supported; bugs are reproduced and fixed on the trunk first and cherry-picked to the release branch ([branch for release](https://trunkbaseddevelopment.com/branch-for-release/)).

```text
    ---o---o---o---o---F---o---o---   main          F = the fix, made on main first
                \       \
                 o-------F'           release/1.4   F' = cherry-pick of F
                 ^       ^
              v1.4.0   v1.4.1
```

**Microsoft's Release Flow.** Short-lived topic branches are merged to `main` through pull requests with branch policies. At the end of each three-week sprint a release branch is created, named for the sprint (the document's example is `releases/M129`), and deployed in rings. A hotfix is made in `main` first and then cherry-picked to the release branch through its own pull request. Release branches never merge back to `main`, and the old one is abandoned after the next sprint ships ([How Microsoft develops with DevOps](https://learn.microsoft.com/en-us/devops/develop/how-microsoft-develops-devops)).

```text
    ---o---o---o---o---o---F---o---o---o---   main
            \               \       \
             o               F'      o        releases/M129, then releases/M130
          releases/M128   (hotfix cherry-picked to M129)
```

Release Flow is trunk-based development plus a release branch per sprint plus the "fix on main first" rule. The names differ more than the graphs do.

## 27.9 One release and one hotfix, under two strategies

**In one sentence.** The same three features and the same one-line fix produce two different answers to "what does the patch release contain", and the difference is where the release tag lives.

The scenario: `promptgate` 1.3.0 is released. Two pull requests are merged, and 1.4.0 is released. A third pull request, a batch endpoint, is merged afterwards. Then production reports that suspended tenants, whose limit is 0, are not blocked, and a fix must ship as 1.4.1.

**Strategy A: GitHub Flow, releases are tags on `main`.**

<!-- snippet: ch27/github-flow/03-hotfix -->
```text
# Production reports that suspended tenants (limit 0) are not blocked.
$ git switch -c hotfix/suspended-tenant main
Switched to a new branch 'hotfix/suspended-tenant'
$ git diff
diff --git a/gateway/limits.py b/gateway/limits.py
index bf5d3ec..18f6e2c 100644
--- a/gateway/limits.py
+++ b/gateway/limits.py
@@ -2,5 +2,5 @@ LIMITS = {"default": 60}
 
 
 def allowed(tenant, used):
-    limit = LIMITS.get(tenant) or LIMITS["default"]
+    limit = LIMITS.get(tenant, LIMITS["default"])
     return used < limit
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git switch -q main
$ git merge --no-ff -m "Merge pull request #44 from hotfix/suspended-tenant" hotfix/suspended-tenant
Merge made by the 'ort' strategy.
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git branch -d hotfix/suspended-tenant
Deleted branch hotfix/suspended-tenant (was 9a75273).
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
```
<!-- /snippet -->

The bug is the `or`: a limit of `0` is falsy in Python, so the suspended tenant silently got the default limit. The fix is one line. Now the history, and the question that matters:

<!-- snippet: ch27/github-flow/04-graph -->
```text
$ git log --oneline --graph --decorate
*   c1702e7 (HEAD -> main, tag: v1.4.1) Merge pull request #44 from hotfix/suspended-tenant
|\  
| * 9a75273 Fix limit 0 being treated as unlimited
|/  
*   a1351be Merge pull request #43 from feature/batch-api
|\  
| * 5928b76 Add batch endpoint
|/  
*   518d961 (tag: v1.4.0) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
* |   a7ccb4b Merge pull request #41 from feature/streaming
|\ \  
| |/  
|/|   
| * b00109d Stream tokens to the client
|/  
* b6e2f58 (tag: v1.3.0) Add per-tenant rate limits
* 9df3d07 Add gateway skeleton
```
<!-- /snippet -->

<!-- snippet: ch27/github-flow/05-what-ships -->
```text
# What does a customer get when moving from v1.4.0 to v1.4.1?
$ git log --oneline --no-merges v1.4.0..v1.4.1
9a75273 Fix limit 0 being treated as unlimited
5928b76 Add batch endpoint
$ git diff --stat v1.4.0 v1.4.1
 gateway/batch.py  | 2 ++
 gateway/limits.py | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git branch --list
* main
```
<!-- /snippet -->

Version 1.4.1 contains the fix **and the batch endpoint**. Under GitHub Flow that is by design: `main` is what you ship, and everything merged since the last tag ships with the next one. For a hosted service with one live version this is fine, and usually desirable. For a customer who pinned 1.4 and expects a patch release to contain only fixes, it is a breach of what the version number promised ([Semantic Versioning](https://semver.org/) reserves the third number for backward-compatible bug fixes).

**Strategy B: a release branch, fix on `main` first, cherry-pick down.**

<!-- snippet: ch27/release-branch/04-backport -->
```text
# Then the one commit is copied to the release branch and released from there:
$ git switch -q release/1.4
$ git cherry-pick -x bc59804
[release/1.4 996796d] Fix limit 0 being treated as unlimited
 Date: Mon Sep 7 10:24:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
$ git log -1 --format=%B
Fix limit 0 being treated as unlimited

(cherry picked from commit bc5980493f22fc60a53dcc923eb9941b88e13284)
```
<!-- /snippet -->

🟡 CAUTION: `git cherry-pick -x <commit>` creates a new commit on the current branch with the same change as `<commit>` and moves the branch to it. The `-x` adds the "(cherry picked from commit ...)" line, which is the only durable record that `996796d` on the release branch and `bc59804` on `main` are the same fix. [Chapter 10: Cherry-pick](ch10-cherry-pick.md) explains the three-way merge behind the command.

<!-- snippet: ch27/release-branch/05-graph -->
```text
$ git log --oneline --graph --decorate --all
* 996796d (HEAD -> release/1.4, tag: v1.4.1) Fix limit 0 being treated as unlimited
| *   956fbb2 (main) Merge pull request #44 from hotfix/suspended-tenant
| |\  
| | * bc59804 Fix limit 0 being treated as unlimited
| |/  
| * e6db0b4 Merge pull request #43 from feature/batch-api
|/| 
| * 7a47553 Add batch endpoint
|/  
*   518d961 (tag: v1.4.0) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
* |   a7ccb4b Merge pull request #41 from feature/streaming
|\ \  
| |/  
|/|   
| * b00109d Stream tokens to the client
|/  
* b6e2f58 (tag: v1.3.0) Add per-tenant rate limits
* 9df3d07 Add gateway skeleton
```
<!-- /snippet -->

<!-- snippet: ch27/release-branch/06-what-ships -->
```text
# What does a customer get when moving from v1.4.0 to v1.4.1?
$ git log --oneline --no-merges v1.4.0..v1.4.1
996796d Fix limit 0 being treated as unlimited
$ git diff --stat v1.4.0 v1.4.1
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

Version 1.4.1 contains the fix and nothing else. The batch endpoint will ship in 1.5.0.

**Inside `.git`.** Strategy A created two tag objects and moved `refs/heads/main`. Strategy B created the same two tags, one extra ref `refs/heads/release/1.4`, and one extra commit object. A "release" in both is `refs/tags/v1.4.1` naming an annotated tag object that names a commit.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git switch -c release/1.4 main` | unchanged | unchanged | symbolic ref to `release/1.4` | new ref at the commit of `main` | reflog for the new branch | unchanged until pushed | unchanged until pushed |
| `git tag -a v1.4.0 -m ...` | unchanged | unchanged | unchanged | unchanged | a tag object and `refs/tags/v1.4.0` | unchanged until `git push origin v1.4.0` | no tag and no release until pushed |
| `git cherry-pick -x <fix>` | the fix applied | matches the new commit | unchanged (still symbolic) | moves to the new commit | new commit object; reflog entries; `CHERRY_PICK_HEAD` only if it stops on a conflict | unchanged until pushed | unchanged until pushed |
| `git push origin release/1.4 v1.4.1` | unchanged | unchanged | unchanged | unchanged | `refs/remotes/origin/release/1.4` updated | branch and tag created or moved | the tag appears; a release object exists only if you create one (`gh release create`) |

**The comparison.**

| Question | A: GitHub Flow with tags | B: release branch |
|---|---|---|
| Long-lived refs | `main` | `main` and one `release/x.y` per supported version |
| Contents of a patch release | everything merged to `main` since the previous tag | only what was picked onto the release branch |
| Commits per fix | one | two (one per line), linked by patch ID and the `-x` line |
| Can you patch 1.4 after 1.5 exists? | no: there is no line for 1.4 to stand on, short of creating a branch at the old tag | yes |
| Extra failure mode | a half-finished feature on `main` blocks an urgent release unless it is behind a flag | a fix that reaches one line and not the other (section 27.10) |
| CI cost | one branch | every supported release branch needs its own pipeline |

Strategy A can become strategy B on the day it is needed: `git switch -c release/1.4 v1.4.0` creates the missing line at the tag, after the fact. That is an argument for starting with the simpler model and adding release branches when a second live version appears.

> **GitHub, not Git.** A GitHub release is an object layered on a Git tag. Creating one in the web interface or with `gh release create` can create the tag on the server, and your clone does not have it until you fetch tags. With immutable releases enabled, the tag and its assets are locked and the tag name cannot be reused ([about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases), [immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)).

## 27.10 Which way does a fix travel?

**In one sentence.** There are two legitimate conventions and they are opposites: commit the fix on the oldest branch that needs it and merge upward, or commit it on `main` first and cherry-pick it down.

**Analogy.** A textbook in print in two editions. You can correct the older edition and let the correction flow into the newer one, or correct the current manuscript and copy the correction by hand into the older edition. The analogy breaks because Git can do the first mechanically (a merge) only while the newer line still contains the older one as an ancestor.

**Precisely.**

- **Merge upward.** The Git project's own workflow document states it: "Always commit your fixes to the oldest supported branch that requires them. Then (periodically) merge the integration branches upwards into each other." (`git help workflows`, also at [gitworkflows](https://git-scm.com/docs/gitworkflows)). The fix is one commit with one ID, and the merge commit is, in that document's words, a "promise" that everything from the older branch is included in the newer one.
- **Fix on main first, cherry-pick down.** The trunk-based development site, Google's published practice, Microsoft's Release Flow and GitLab's rules all prescribe this. The stated reason is the failure it prevents: a fix made on the release branch can be forgotten on the trunk, and the next release then regresses ([branch for release](https://trunkbaseddevelopment.com/branch-for-release/)).

**See it: merge upward.** The starting state is the same in all three parts of this demo: `release/1.4` at the 1.4.0 tag, and `main` one feature ahead.

<!-- snippet: ch27/fix-direction/02-merge-upward -->
```text
# Convention A: commit the fix on the oldest branch that needs it...
$ git switch -q release/1.4
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
# ...then merge that branch upward into main:
$ git switch -q main
$ git merge -m "Merge branch release/1.4 into main" release/1.4
Merge made by the 'ort' strategy.
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --decorate --all -6
*   1a91aff (HEAD -> main) Merge branch release/1.4 into main
|\  
| * 64610e3 (tag: v1.4.1, release/1.4) Fix limit 0 being treated as unlimited
* |   a1351be Merge pull request #43 from feature/batch-api
|\ \  
| |/  
|/|   
| * 5928b76 Add batch endpoint
|/  
*   518d961 (tag: v1.4.0) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
```
<!-- /snippet -->

<!-- snippet: ch27/fix-direction/03-one-commit -->
```text
# One commit, one ID, contained in both lines:
$ git branch --contains v1.4.1
* main
  release/1.4
$ git log --oneline main..release/1.4
# Empty: everything on the release branch is in main. That is an invariant you can test:
$ git merge-base --is-ancestor release/1.4 main
[exit status: 0]
```
<!-- /snippet -->

One commit, `64610e3`, contained in both branches. The invariant "the release branch is an ancestor of `main`" holds, and `git merge-base --is-ancestor release/1.4 main` tests it with an exit status that a CI job can check.

**See it: fix on main, cherry-pick down.**

<!-- snippet: ch27/fix-direction/04-pick-down -->
```text
$ cd ../pick-down
# Convention B: commit the fix on main first...
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git switch -q release/1.4
# ...then copy it down to the release branch:
$ git cherry-pick -x main
[release/1.4 a2d7a91] Fix limit 0 being treated as unlimited
 Date: Mon Sep 7 10:36:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
$ git log --oneline --graph --decorate --all -6
* a2d7a91 (HEAD -> release/1.4, tag: v1.4.1) Fix limit 0 being treated as unlimited
| * d9474f7 (main) Fix limit 0 being treated as unlimited
| * a1351be Merge pull request #43 from feature/batch-api
|/| 
| * 5928b76 Add batch endpoint
|/  
*   518d961 (tag: v1.4.0) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
```
<!-- /snippet -->

<!-- snippet: ch27/fix-direction/05-two-commits -->
```text
# Two commits, two IDs. The release branch is never merged into main:
$ git merge-base --is-ancestor release/1.4 main
[exit status: 1]
# The check that replaces the ancestry test compares patches, not IDs:
$ git log --oneline --cherry-pick --right-only --no-merges main...release/1.4
# Empty: every change on the release branch has an equivalent on main.
```
<!-- /snippet -->

Two commits, `d9474f7` and `a2d7a91`. The ancestry test fails by design, because the release branch is never merged back. What replaces it is a comparison of patches: `git log --cherry-pick --right-only main...release/1.4` lists the commits on the release branch that have no equivalent change on `main`. The manual describes `--cherry-pick` as omitting "any commit that introduces the same change as another commit on the 'other side'" of a symmetric difference. Git decides "the same change" by patch ID, a hash of the diff without line numbers and whitespace ([Chapter 10](ch10-cherry-pick.md)).

**See it: the failure both conventions exist to prevent.**

<!-- snippet: ch27/fix-direction/06-forgotten -->
```text
$ cd ../forgotten
# The failure both conventions exist to prevent: a fix made only on the release branch.
$ git switch -q release/1.4
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
# Weeks later release 1.5 is cut from main:
$ git switch -q main
$ git tag -a v1.5.0 -m "promptgate 1.5.0"
$ git show v1.5.0:gateway/limits.py | grep "limit ="
    limit = LIMITS.get(tenant) or LIMITS["default"]
$ git show v1.4.1:gateway/limits.py | grep "limit ="
    limit = LIMITS.get(tenant, LIMITS["default"])
```
<!-- /snippet -->

<!-- snippet: ch27/fix-direction/07-detect -->
```text
# v1.5.0 ships the bug that v1.4.1 fixed. Either check finds it before the tag:
$ git merge-base --is-ancestor release/1.4 main
[exit status: 1]
$ git log --oneline --cherry-pick --right-only --no-merges main...release/1.4
70188ed Fix limit 0 being treated as unlimited
```
<!-- /snippet -->

```text
Observed behavior : v1.5.0 ships a bug that v1.4.1 fixed.
Git state         : commit 70188ed is reachable from release/1.4 and from tag v1.4.1 only.
                    main and v1.5.0 do not contain it and contain no commit with the same patch.
Mechanism         : a commit on one branch is on another branch only if somebody merges or
                    cherry-picks it. Nothing in Git propagates a fix between branches.
Root cause        : the fix was committed on the release branch, and the step that carries it
                    to main (a merge upward, or a port) was a human step that nobody took.
Why Git does this : branches are independent refs. "This fix belongs everywhere" is knowledge
                    held by the team, not by the repository.
Correct fix       : port the commit to main (git cherry-pick -x 70188ed, or merge release/1.4
                    into main if your convention is merge-upward), then release 1.5.1. Do not
                    move the v1.5.0 tag: people already have it.
Prevention        : make the check a release gate. Either "release/x is an ancestor of main"
                    (merge-upward), or "git log --cherry-pick --right-only main...release/x is
                    empty" (pick-down). Both are one command with a testable result.
```

**The trade-off, stated plainly.**

| | Merge upward | Fix on main, pick down |
|---|---|---|
| Identity of the fix | one commit, one ID | one commit per line; linked by patch ID and the `-x` line |
| "Is the fix in release X?" | `git branch --contains <id>` answers for every line | must search by patch or by message on each line |
| What a forgotten step causes | the fix is missing from `main` until the next upward merge, which brings it along with everything else | nothing dangerous if the pick is forgotten: the old release lacks a fix it never had |
| Extra baggage | merging the release branch upward brings **everything** on it, including version bumps and release-only changes, which then conflict or must be neutralized | the patch-ID check breaks when the port needed conflict resolution, because the diffs then differ |
| Fits | projects with several maintained lines and maintainers who curate merges (Git itself) | trunk-based teams with late-cut, short-lived release branches |

Two limits of the checks. A cherry-pick that needed a conflict resolution has a different patch ID, so `--cherry-pick` reports it as missing although a human ported it; the `-x` line is then the evidence. And an upward merge resolved by discarding the release branch's side satisfies the ancestry test while the fix is absent; `git log --remerge-diff` shows what the resolver changed ([Chapter 8: Merge](ch08-merge.md)).

**In production.** Pick one direction and write it down. Here is one repository in which the first fix was picked down and a second fix, on the next line of the same function, is then merged upward:

<!-- snippet: ch27/mixed-directions/02-merge-upward-conflicts -->
```text
# ...and somebody carries it to main by merging the release branch upward:
$ git switch -q main
$ git merge release/1.4
Auto-merging gateway/limits.py
CONFLICT (content): Merge conflict in gateway/limits.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git diff
diff --cc gateway/limits.py
index 18f6e2c,ca849ed..0000000
--- a/gateway/limits.py
+++ b/gateway/limits.py
@@@ -3,4 -3,4 +3,8 @@@ LIMITS = {"default": 60
  
  def allowed(tenant, used):
      limit = LIMITS.get(tenant, LIMITS["default"])
++<<<<<<< HEAD
 +    return used < limit
++=======
+     return max(used, 0) < limit
++>>>>>>> release/1.4
$ git merge --abort
```
<!-- /snippet -->

The upward merge brought the picked copy of the first fix with it. Relative to the merge base, `main` changed one line and the release branch changed that line identically plus its neighbour, so the two changes overlap. Git dropped the identical line from the conflict and left the neighbouring line for a human, although `main` never touched it. A repository that mixes the directions satisfies neither check of this section and pays for it in conflicts like this one.

## 27.11 Feature flags

**In one sentence.** A feature flag is a condition in the code that keeps unfinished or unreleased behavior switched off, so that the code can be merged long before the feature is released.

**Analogy.** A new wing of a building, built and inspected behind a locked door: part of the building from day one, open to the public later. The analogy breaks because both sides of the door run in the same production process, so a mistake behind the door can still bring the building down.

**Precisely.** A flag replaces a long-lived branch with a short-lived condition. Instead of keeping `feature/batch-api` unmerged for three weeks, you merge it in small pieces behind `if flags.enabled("batch_api")`, and `main` contains the code from the first day. Pete Hodgson's taxonomy distinguishes release toggles (ship incomplete code dark), experiment toggles, ops toggles and permission toggles, which differ in how long they live and how dynamically they change, and it names the cost: added complexity, combinations to test, and "toggle debt" when flags are not removed ([Feature Toggles](https://martinfowler.com/articles/feature-toggles.html)). Microsoft describes flags as what lets its developers avoid long-running feature branches and separate deployment from exposure.

**What it changes in Git.** Compare the two graphs. With the flag, the feature never exists as a diverged line, so it never needs a large merge and never blocks a release:

```text
  Long-lived branch:    ---o---o---o---o---o---o---M---   main
                            \                     /
                             o---o---o---o---o---o       feature/batch-api (3 weeks, one big merge)

  Behind a flag:        ---o---b1--o---b2--o---b3--o---   main     b1..b3 = small merged pieces,
                                                                    switched off until release
```

This is what removes the "extra failure mode" of GitHub Flow in the table of section 27.9: a half-finished feature on `main` does not block an urgent release if it is dark.

**When not to use one.** Fowler's caveat is that with flags the unfinished code ships inside the product, so the approach demands strong automated tests to keep the main line healthy. A flag is the wrong tool for a change that cannot be made conditional (a schema migration, a dependency upgrade), and a flag that guards a security boundary must fail closed. A flag is configuration, and configuration that changes behavior belongs in version control or in a system with its own audit trail; DORA's version-control capability lists configuration among the things to keep under version control ([DORA: version control](https://dora.dev/capabilities/version-control/)).

**In production.** For an LLM application the natural flags are the model name, the prompt version and the retrieval settings. A new prompt can then be merged and evaluated on a fraction of traffic before it becomes the default, and "which prompt answered this ticket" becomes a question about a flag value at a time, not only about a commit (Chapter 28, section 28.7).

## 27.12 Merge queues and stacked changes

**In one sentence.** A merge queue and a stack attack the two costs of reviewing before merging: a busy base branch that keeps invalidating finished work, and an author who is blocked while a large change waits for review.

**Merge queues.** Two pull requests can each pass their checks against an older `main` and break `main` together; requiring every branch to be up to date before merging fixes that and creates a race, because every merge makes every other pull request stale. A merge queue runs the required checks on temporary branches that contain the base plus the queued changes, in order, and merges what passes. On GitHub those checks run on the `merge_group` event, and the merge method is fixed by the queue instead of being chosen per pull request. [Chapter 17: Pull requests](ch17-pull-requests.md), section 17.11 reproduces the mechanism with plain Git. The published experience comes from large repositories: GitHub reports about 2,500 pull requests a month from more than 500 engineers landing through its own queue, with the average wait to ship down 33% ([GitHub Blog](https://github.blog/engineering/engineering-principles/how-github-uses-merge-queue-to-ship-hundreds-of-changes-every-day/)), and Shopify described running CI on a predicted post-merge branch and ejecting failures to keep its main branch green ([Shopify Engineering](https://shopify.engineering/successfully-merging-work-1000-developers)). Those numbers describe those companies; a team that merges five pull requests a day gets the correctness guarantee and little else.

**Stacked changes.** A stack is a chain of small changes, each reviewed separately and each based on the one below. The practice comes from tools with per-commit review, such as Phabricator at Facebook and chained changelists at Google ([Jackson Gabbard](https://jg.gg/2018/09/29/stacked-diffs-versus-pull-requests/), [The Pragmatic Engineer](https://newsletter.pragmaticengineer.com/p/stacked-diffs)). The stated benefits are an unblocked author and small reviews; the stated costs are the rebasing skill and tooling it needs, and little gain for a small team. GitHub's native stacked pull requests have been in public preview since 30 July 2026 ([changelog](https://github.blog/changelog/2026-07-30-stacked-pull-requests-are-now-in-public-preview/)). Chapter 17, section 17.14 shows the plain-Git mechanics.

```text
    main ---o
             \
              a1---a2          pr/1-schema       (base: main)
                    \
                     b1        pr/2-endpoint     (base: pr/1-schema)
                      \
                       c1---c2 pr/3-client       (base: pr/2-endpoint)
```

Neither is a branching strategy. A merge queue makes any model with pre-merge checks safer at volume, and stacks make short-lived branches practical for a change too large for one review.

## 27.13 What the evidence shows, and what it does not

**In one sentence.** The research associates short-lived branches and small batches with better delivery performance; it does not rank named workflows, and it does not establish cause.

**What DORA reports.** DORA defines trunk-based development as each developer dividing work into small batches and merging into the trunk at least once a day. Its capability page reports, from research conducted in 2016 and 2017, that higher delivery performance is associated with three or fewer active branches, merging to trunk at least daily, and no code freezes or integration phases; it lists heavyweight, slow code review and skipping automated tests before commit as pitfalls ([DORA: trunk-based development](https://dora.dev/capabilities/trunk-based-development/)). A companion capability says that working in small batches predicts delivery and organizational performance ([DORA: working in small batches](https://dora.dev/capabilities/working-in-small-batches/)).

**What that evidence is.**

| Property of the evidence | Consequence for how you may cite it |
|---|---|
| Survey-based: respondents describe their own practices and outcomes | it measures reported practice, not observed repositories |
| Correlational | "is associated with" and "predicts", in the statistical sense the authors use; not "causes" |
| Expressed in branch lifetime, number of active branches and batch size | it says nothing about "Git Flow" or "GitHub Flow" by name; a GitHub Flow team with one-day branches satisfies it, and a nominally trunk-based team with week-long branches does not |
| The branch findings date from 2016 and 2017 | later reports were not read for this course: the research notes record that the 2024 and 2025 report PDFs were not read and that no numeric effect sizes were captured |

> **Unverified.** Any specific number for how much trunk-based development improves delivery performance. The notes behind this course contain none, and you should not quote one from memory.

**What other sources add.** Fowler, who accepts this research, still lists real advantages of feature branching: a feature can be assessed as a unit, code enters the product only when complete, and it suits teams that cannot yet keep a main line healthy and open-source projects with occasional contributors who are not yet trusted ([Fowler](https://martinfowler.com/articles/branching-patterns.html)). An interview-and-survey study of Brazilian developers published in 2025 concludes that trunk-based workflows suit fast-paced projects with experienced, smaller teams, and branch-based workflows suit less experienced and larger teams despite their management overhead ([arXiv 2507.08943](https://arxiv.org/abs/2507.08943)); it is one study of one population. The company case studies come from organizations with very large investments in CI, flags and tooling, and Google and Meta do not use stock Git for their main repositories, so they support the principle more than any Git command sequence. DORA's recent reports describe AI as an amplifier of an organization's existing strengths and weaknesses and keep small batches and version control among the capabilities that matter ([DORA 2025 report](https://dora.dev/research/2025/dora-report/)).

**How to say it to a CTO.** "The research does not prove that trunk-based development is best. It shows that teams reporting short-lived branches and small batches also report better delivery performance. The variable we can act on is how long our branches live and how large our changes are, under whatever name we give the model."

## 27.14 Choosing by context

No strategy is best. The reputable sources tie the choice to context, and two questions come before all others: **how many versions are live at once**, and **how often do you release**.

| Context | What it pushes you toward | Why | What to watch |
|---|---|---|---|
| One live version, deployed continuously (a hosted service) | one long-lived branch: GitHub Flow or trunk-based development | there is nothing for a release branch to hold | branch lifetime; flags for unfinished work; fast rollback |
| One live version, released on a schedule (weekly, per sprint) | trunk plus a late-cut release branch per release (Release Flow) | the branch isolates stabilization without freezing `main` | fix direction; retire old release branches |
| Several supported versions (SDK, on-premises product, mobile app with old versions in the field) | long-lived `release/x.y` branches; Git Flow is one historical arrangement of them | each supported version needs a line to receive fixes | the port check of section 27.10 as a release gate; CI per supported line |
| Small, experienced team with strong automated tests | shorter branches, lighter pre-merge gates | the cost of a bad merge is low and quickly repaired | do not drop review silently: decide it |
| Large team, or many less experienced contributors | feature branches with required review and checks; a merge queue at volume | pre-merge gates protect a main line the team cannot yet keep healthy by habit | review latency becoming the bottleneck |
| Open source with outside contributors | fork workflow, pull requests, maintainers merge | contributors are not yet trusted with write access | secrets and `pull_request_target` (Chapter 21A) |
| Regulated environment (segregation of duties, audit trail, change approval) | protected branches with required review by someone other than the author, signed tags for releases, release branches where a release is an audited event | the audit asks who approved what and what exactly shipped | make bypasses visible: rulesets and Rule Insights ([Chapter 18](ch18-branch-protection.md)); compliance comes from enforced, logged rules, not from the name of the model |
| Model or prompt releases that must be reproducible | tags on the exact commit, plus the data and model versions recorded with it | "which code produced this model" must have one answer | Chapter 28, section 28.7 |

The rows combine: a regulated company with a hosted product and an on-premises edition is in three rows at once. Changing the model later is cheap in Git (branches are refs) and expensive in habits, pipelines and rulesets, so start with the simplest model that answers the two questions and add a branch only when you can name the version or the audit requirement that needs it.

## 27.15 Practices, each with its reason

A practice you cannot justify is a superstition, and it will be dropped under pressure. Each row gives the mechanism that makes the practice worth its cost.

| Practice | The reason, in terms of mechanism | Where it is taught |
|---|---|---|
| Small commits, one logical change each | a commit is the unit of `revert`, `cherry-pick`, `bisect` and review; a commit that does three things can only be undone, ported or blamed as three things | this section; [Chapter 6](ch06-commits.md), [Chapter 14A](ch14a-history-investigation.md) |
| Meaningful messages | the message is the only part of a commit that records why; the diff already records what | section 27.18 |
| A protected main branch | a ref anyone can move is a ref anyone can break or rewind; a rule turns "we agreed not to" into "the server refuses" | [Chapter 18](ch18-branch-protection.md) |
| Review before merge | a second reader catches what the author's model of the change hides, and spreads knowledge of the code | section 27.17 |
| Required CI checks | a check that is not required is advice; and a check must run on the merged result to mean anything about `main` | Chapter 17, sections 17.6 and 17.11 |
| No secrets in Git | history is copied to every clone and fork and cannot be recalled; deleting the file adds a commit and removes nothing | Chapter 21B: Repository security; Chapter 28, section 28.14 |
| `--force-with-lease`, never bare `--force` | a bare force sets the server's ref with no check; a lease makes the push conditional on the ref being where you last saw it | [Chapter 12](ch12-remote-operations.md), section 12.8 |
| Signed commits and tags where identity matters | author and committer fields are text that anyone can set; a signature is evidence that a key holder made the object | [Chapter 14B](ch14b-config-tags-signing.md) |
| A branch naming scheme | rules, workflow triggers and cleanup scripts select branches by pattern | section 27.5 |
| Rebase private branches | rebasing rewrites commit IDs; on a branch nobody else has, nobody else can be holding the old IDs | [Chapter 9](ch09-rebase.md) |
| No history rewriting on shared branches | everyone who fetched the old commits now has a history that diverges from the server, and the next careless merge brings the removed commits back | Chapter 9; Chapter 12, section 12.8 |
| Inspect before you merge | a merge brings every commit reachable from the other side, not only the ones you had in mind | this section |

**See it: inspect before merging.** Three commands answer "what would this merge bring, and will it merge cleanly", and none of them changes anything:

<!-- snippet: ch27/practices/01-inspect -->
```text
# Before merging feature/fallback: which commits would arrive, and what do they change?
$ git log --oneline main..feature/fallback
dd57a51 chore: raise default limit for load test
4ea69d0 feat(router): fall back when the primary model is unhealthy
8df1ca6 feat(router): add fallback table
$ git diff --stat main...feature/fallback
 gateway/fallback.py | 5 +++++
 gateway/limits.py   | 2 +-
 gateway/router.py   | 7 +++++--
 3 files changed, 11 insertions(+), 3 deletions(-)
# Would it merge cleanly? Ask without touching the working tree, the index or any ref:
$ git merge-tree --write-tree --name-only main feature/fallback
4a26aedd8171757262dc58e3a1d20dbaf20c118b
[exit status: 0]
```
<!-- /snippet -->

The two-dot `git log` lists the commits you would gain. The three-dot `git diff` shows the change since the merge base, which is what a pull request shows (Chapter 17, section 17.3). `git merge-tree --write-tree` merges in memory and prints the ID of the resulting tree; exit status 0 means no conflicts. The first list contains a surprise: a commit that raises a limit "for load test".

**See it: why small commits pay.** Suppose it was merged anyway, with a merge commit that preserves the three commits:

<!-- snippet: ch27/practices/03-revert-one -->
```text
# The load-test limit reached production. Because it is a commit of its own, it can be
# undone alone, and the fallback feature stays:
$ git revert --no-edit dd57a51
[main f3624e2] Revert "chore: raise default limit for load test"
 Date: Mon Sep 7 10:17:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --stat --format="%h %s" HEAD
f3624e2 Revert "chore: raise default limit for load test"

 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ grep default gateway/limits.py
LIMITS = {"default": 60}
    return used < LIMITS.get(tenant, LIMITS["default"])
```
<!-- /snippet -->

🟡 CAUTION: `git revert` adds a commit, which moves the branch, and removes nothing ([Chapter 11: Reset, revert, restore](ch11-reset-revert-restore.md)). One commit undone, one file touched, the feature intact. Now the same branch merged as one squashed commit:

<!-- snippet: ch27/practices/04-revert-squashed -->
```text
# The same branch as one squashed commit (rebuilt here from the same content):
$ git show --stat --format="%h %s" HEAD
9a0bfe3 Add model fallback (#51)

 gateway/fallback.py | 5 +++++
 gateway/limits.py   | 2 +-
 gateway/router.py   | 7 +++++--
 3 files changed, 11 insertions(+), 3 deletions(-)
# Reverting it removes the feature together with the mistake:
$ git revert --no-edit HEAD
[main 108204a] Revert "Add model fallback (#51)"
 Date: Mon Sep 7 10:25:00 2026 +0530
 3 files changed, 3 insertions(+), 11 deletions(-)
 delete mode 100644 gateway/fallback.py
$ git show --stat --format="%h %s" HEAD
108204a Revert "Add model fallback (#51)"

 gateway/fallback.py | 5 -----
 gateway/limits.py   | 2 +-
 gateway/router.py   | 7 ++-----
 3 files changed, 3 insertions(+), 11 deletions(-)
```
<!-- /snippet -->

The only revert available removes the fallback feature together with the mistake. Squash merging is a legitimate choice, and this is its price: the unit of undo becomes the pull request. The practice that follows is not "never squash" but "keep pull requests as small as the commits you would have wanted".

## 27.16 Anti-patterns, each with its root cause

An anti-pattern is rarely stupidity. Each one below is the reasonable result of a wrong mental model, and the model is what you correct.

| Anti-pattern | Root cause: the model behind it | What it costs | The correction |
|---|---|---|---|
| Giant commits | "a commit is a save point for my day", not a unit of change | review that cannot be done; `bisect` that ends on 2,000 lines; reverts that take the good with the bad | stage by hunk (`git add -p`, [Chapter 5](ch05-index.md)); one logical change per commit |
| Committed secrets | "the repository is private", or "I will delete it in the next commit" | every clone and fork has it; deletion adds a commit; on GitHub the old commits stay reachable by ID | rotate first, then clean up (Chapter 21B); push protection |
| Committed generated files | "everything needed to run should be in the repository", confusing sources with outputs | conflicts on every merge; diffs nobody reads; a repository that grows with each build | ignore outputs; commit the inputs and the lock file (Chapter 28, section 28.9) |
| Rebasing shared branches | "rebase tidies history", without the fact that it creates new commits | colleagues' branches now contain both versions; duplicated commits after their next merge | rebase only what nobody else has; merge on shared branches |
| Blind force-push | "the push was rejected, so force it": the rejection is read as an obstacle and not as information | colleagues' commits removed from the server | read the rejection; fetch; `--force-with-lease --force-if-includes`; forbid force pushes on shared branches by rule |
| Meaningless messages (`wip`, `fix`, `update`) | "the diff explains itself" | history that cannot be searched; nobody knows why a line exists | section 27.18 |
| `git reset --hard` without understanding state | "reset means undo" | uncommitted work destroyed; the reflog records commits, so it cannot bring back work that was never committed | know the three trees ([Chapter 11](ch11-reset-revert-restore.md)); `git stash` or commit first |
| Merging without inspecting history | "merging a branch brings my change", not "everything reachable from it" | unrelated or unreviewed commits arrive on `main` | section 27.15: `git log A..B` before every merge |
| Ignoring CI | "it is flaky", or "it passed locally" | a broken main line; red becomes normal, and a real failure hides in it | make checks required; fix or delete flaky tests; know why CI differs from your machine (Chapter 20B) |
| Outdated authentication | a tutorial from before 13 August 2021, when GitHub stopped accepting account passwords for Git operations; or one long-lived token with full scope shared by a team | pushes that fail; or a leaked token that reaches everything | [Chapter 16: Authentication](ch16-authentication.md) |
| Huge binaries in Git | "Git stores my project", without the fact that every clone carries every version of every file | slow clones for everyone, forever; hard limits on the server | pointers and external storage ([Chapter 22: Git LFS](ch22-git-lfs.md); Chapter 28, section 28.6) |
| Treating GitHub as Git | "it is on GitHub, so it is backed up and it is the truth" | surprise when a force push removes work, when a pull request is not in the clone, or when a ruleset blocks a valid Git operation | label the layer: which behavior is Git's, which is the platform's ([Chapter 15: GitHub](ch15-github.md)) |

`riskscore`, the repository of Lab 34.1, contains several of these on purpose, and the lab finds each of them from the command line: an anti-pattern you can measure is one you can put in front of a CTO.

## 27.17 Code review as a practice

**In one sentence.** Review is where a team's knowledge of its code is exchanged; finding defects is the smaller part of its value, and a review that takes days costs more than it finds.

The mechanics of review on GitHub are in Chapter 17, and its section 17.17 lists what an author and a reviewer should do with them. This section adds the practice around them.

**Size decides everything else.** Every technique in this chapter that shortens branches (flags, stacks, small commits) is also a review technique.

**Speed is part of quality.** DORA lists heavyweight and slow review as a pitfall (section 27.13). A change that waits two days makes its author start something else. Agree on a time to first response.

**Say what kind of comment it is:** blocking, a question, or a preference. Rouan Wilsenach's "Ship / Show / Ask" lets the author choose per change whether to merge directly, to open a pull request and merge without waiting, or to wait for discussion; it presupposes trust, good CI and feature flags ([Ship / Show / Ask](https://martinfowler.com/articles/ship-show-ask.html)).

**Review the right things.** A human reviewer's attention is best spent on what a machine cannot check: whether the change does what the issue asked, whether it is in the right place, what it does on failure, what it does to data. Formatting and import order belong to a tool. In an ML repository add three questions: which data and which evaluation support the claim in the description, whether a prompt or configuration change was evaluated or only edited, and whether the pull request changes anything under `.github/workflows/`, a lock file or a `Dockerfile`, which deserve a second reader.

**What review does not replace.** Tests, required checks and rules. "Request changes" does not block a merge, and `CODEOWNERS` does not enforce review, unless a ruleset says so ([Chapter 18](ch18-branch-protection.md), [Chapter 19](ch19-codeowners.md)).

## 27.18 Commit message conventions

**In one sentence.** The subject line says what the commit does, the body says why, and trailers carry facts that tools read.

**Precisely.** Git itself imposes one piece of structure: the first line, up to the first blank line, is the subject, which is what `git log --oneline`, `git shortlog` and `git format-patch` use. Everything else is convention. The most cited one is Chris Beams's seven rules: separate subject from body with a blank line; limit the subject to about 50 characters; capitalize it; do not end it with a period; use the imperative mood; wrap the body at 72 characters; use the body to explain what and why, not how ([How to Write a Git Commit Message](https://cbea.ms/git-commit/)).

**Conventional Commits.** Conventional Commits 1.0.0 adds a machine-readable prefix: `<type>[optional scope]: <description>`, with an optional body and footers. `fix` corresponds to a PATCH release in Semantic Versioning, `feat` to a MINOR one, and a `BREAKING CHANGE` footer (or a `!` after the type) to a MAJOR one; other types such as `docs` or `chore` are allowed ([specification](https://www.conventionalcommits.org/en/v1.0.0/)). The point is that release tooling can compute the next version number and a changelog from the history.

<!-- snippet: ch27/practices/05-messages-as-data -->
```text
$ git log --format="%h %s" v1.3.0..HEAD
108204a Revert "Add model fallback (#51)"
9a0bfe3 Add model fallback (#51)
f09559c docs: say how to run the tests
# With a convention, the history answers questions:
$ git log --oneline --grep="^feat" v1.3.0..feature/fallback
4ea69d0 feat(router): fall back when the primary model is unhealthy
8df1ca6 feat(router): add fallback table
$ git log --format="%s" v1.3.0..feature/fallback | sed "s/[(:].*//" | sort | uniq -c
   1 chore
   2 feat
$ git shortlog -sn v1.3.0..feature/fallback
     3	Lab User
```
<!-- /snippet -->

`--grep="^feat"` and the `sort | uniq -c` pipeline work only because the prefix is regular. `Add model fallback (#51)` is a GitHub-style squash subject, with the pull request number as the link back to the discussion.

**Trailers.** Lines of the form `Key: value` at the end of the message are trailers: `Co-authored-by`, `Signed-off-by` (added by `git commit -s`), `Reviewed-by`, or an issue reference. `git interpret-trailers` parses them, and `git log --format='%(trailers:key=Co-authored-by)'` prints them.

**What the convention cannot do.** It does not make a message true. `fix: typo` on a commit that changes a rate limit passes every commit-message linter. A convention is enforced the same way as any other local check: a `commit-msg` hook for fast feedback ([Chapter 14C](ch14c-stash-rerere-attributes-hooks.md), section 14C.10), and a required check or the squash-merge title for the guarantee.

## 27.19 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A new release ships a bug an older patch release fixed | `git log --oneline --cherry-pick --right-only --no-merges main...release/x.y` lists the unported fix | port it to `main`, release a new patch; do not move the tag | the port check as a release gate (section 27.10) |
| A patch release contains a feature nobody announced | `git log --oneline --no-merges vA..vB` | none after the fact; say so in the release notes | a release branch, or flags for unfinished work |
| The fork's `main` cannot be fast-forwarded | `git rev-list --left-right --count upstream/main...origin/main` shows a second number above zero | move the stray commits to a branch, then reset the fork's `main` to upstream | never commit on the fork's `main`; `--ff-only` |
| "Is this branch merged?" gives contradictory answers | the branch was squash-merged: ancestry is gone, content is present | compare content: `git diff`, or `git merge-tree` against the tree of `main` (Lab 34.1) | delete branches at merge time |
| A revert removed more than intended | the pull request was squashed; the unit of undo is the whole pull request | revert, then re-apply the wanted part as a new commit | smaller pull requests |
| A pull request from a fork has red checks the author cannot fix | the workflow needs secrets, which forks do not get | a maintainer runs the privileged part after review | split workflows: untrusted build and test, trusted evaluation (Chapter 28, section 28.11) |

## 27.20 When not to use it, and dangerous edge cases

- **Do not adopt a model by name.** "We do Git Flow" tells nobody how long branches live or which way fixes travel. Write down the refs, the rules and the fix direction.
- **Do not cherry-pick between two long-lived branches as a routine way of integrating.** Occasional ports are fine. Routine picking in both directions leaves two histories that no check can reconcile.
- **A moved tag is worse than a wrong tag.** Clones do not replace a tag they already have unless forced ([Chapter 14B](ch14b-config-tags-signing.md)), so half your users keep the old meaning. Release a new patch version instead.
- **`gh repo sync --force` hard-resets the fork's branch.** If you committed there, those commits become unreachable on the fork. Preview with the `rev-list --left-right --count` command of section 27.3.
- **Feature flags that never die.** A flag whose both paths are still in the code a year later is an untested branch living inside `main`.
- **Merge queues change what your workflows must listen to.** A required check that does not run on `merge_group` never reports, and the queue stalls (Chapter 17, section 17.11).

## 27.21 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git log A..B`, `git log --cherry-pick --right-only A...B`, `git cherry`, `git diff A...B`, `git merge-base --is-ancestor`, `git merge-tree --write-tree` | 🟢 SAFE | nothing (`merge-tree` adds unreferenced objects) | not needed | not needed |
| `git tag -a <name>` | 🟢 SAFE | adds a tag object and a ref | `git tag --list` | `git tag -d <name>` before it is pushed |
| `git cherry-pick -x <commit>` | 🟡 CAUTION | adds a commit to the current branch, which moves it; updates index and working tree | `git show <commit>` | `git reset --keep HEAD^` before pushing; `git revert` after |
| `git revert <commit>` | 🟡 CAUTION | adds a commit, which moves the branch; updates index and working tree | `git show <commit>` | revert the revert |
| `git merge --ff-only upstream/main`, `git merge --no-ff <branch>`, `git merge <release branch>` | 🟡 CAUTION | moves the current branch; updates index and working tree | `git log HEAD..<other>`; `git merge-tree --write-tree` | `git reset --keep ORIG_HEAD` before pushing |
| `git rebase upstream/main` | 🟡 CAUTION | replaces the branch's commits with new ones | `git log upstream/main..HEAD` | `git reset --keep ORIG_HEAD`, or the branch reflog |
| `git branch -d <branch>` | 🟡 CAUTION | deletes a ref and its reflog, after a merge check against the upstream or HEAD | `git branch -vv` | `git branch <name> <id>` from the ID it prints |
| `git push origin --delete <branch>` | 🔴 DANGEROUS | deletes a ref on the server | `git ls-remote origin` | push the commit again from a clone that has it |
| `git push --force-with-lease --force-if-includes` | 🔴 DANGEROUS | replaces a server branch if it is where you last saw it | `git fetch`; `git log HEAD..@{u}` | section 27.3; Chapter 12, section 12.8 |
| `gh repo sync --force` | 🔴 DANGEROUS | hard-resets a branch of the fork to its parent | `git rev-list --left-right --count upstream/main...origin/main` | push the old commits back from a clone that has them |

## 27.22 Version notes

> **Version note.** Older behavior: a push forced with a lease could still discard work fetched in the background. Current behavior: `--force-if-includes` additionally checks that you integrated what you last fetched. Since: Git 2.30. Recommended: use both options together.

> **Version note.** Older behavior: testing a merge meant performing it and aborting. Current behavior: `git merge-tree --write-tree` merges without touching the working tree, the index or any ref. Since: Git 2.38. Recommended: use it in scripts and release gates.

> **Version note.** Older behavior: stacked and dependent pull requests were maintained by hand or with third-party tools. Current behavior: native stacked pull requests on GitHub, in public preview. Since: 30 July 2026. Recommended: learn the plain-Git mechanics in Chapter 17 first.

> **Version note.** Older behavior: Git Flow presented as a general default. Current behavior: its author's note restricts it to explicitly versioned software with several supported versions. Since: 5 March 2020. Recommended: choose by the table in section 27.14.

> **Unverified.** The release that introduced `%(ahead-behind:<ref>)` in `git for-each-ref`, used in Lab 34.1, was not confirmed for this chapter ([Chapter 7](ch07-branches.md) carries the same flag). It runs on Git 2.55.

## 27.23 Practice

- [Lab 32.1](../lab-manual/m32-branching-release-strategy.md): one release and one hotfix under two strategies, a fix forgotten on `main`, and its repair.
- [Lab 34.1](../lab-manual/m34-practices-design-review.md): the Level 8 design review. Measure a company's repository, then design and defend its branching model, governance, CI and security policy.
- Revisit Lab 7.5 in the [Module 7 labs](../lab-manual/m07-remotes.md) for the mechanics of the triangular setup, and the Module 21 labs for pull requests from forks.
- Run the demos: `labs/run ch27/fix-direction`, `labs/run ch27/git-flow`, `labs/run ch27/fork-sync`.

## 27.24 Interview questions

1. Your company ships one hosted version today and will support two on-premises versions next year. What changes in your branching model, and on which day do you change it?
2. A patch release went out without a fix that the previous patch release contained. Walk through how you find the cause from the repository alone, and what you add to the release process afterwards.
3. State the two conventions for the direction of a fix. For each, give the invariant you can test and one way the test can mislead you.
4. A colleague says the DORA research proves trunk-based development is best. What does it show, how was it measured, and what would you say instead?
5. Under GitHub Flow, a customer asks for a release that contains only a security fix. What do you tell them, and what would you have needed to have in place?
6. After a squash merge, `git branch --merged` does not list your branch. Why, and how do you establish that its work is on `main`?
7. What does a merge queue guarantee that "require branches to be up to date" does not, and what does it cost?
8. Give the mechanism behind three of your team's practices: why small commits, why no force push on shared branches, why inspect before merging.
9. You maintain an open-source project and receive a 3,000-line pull request from a stranger. What do you do, and what in your repository should have prevented it?
10. Your fork's `main` is two commits ahead of and forty behind upstream. How did that happen, and how do you repair it without losing the two commits?

## 27.25 Sources

**Primary sources**

- Git 2.55 manual pages: `git help workflows` ([gitworkflows](https://git-scm.com/docs/gitworkflows)), `git help cherry-pick`, `git help rev-list` (`--cherry-pick`, `--left-right`), `git help branch`, `git help merge-tree`, `git help for-each-ref`.
- GitHub Docs: [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow), [Forks](https://docs.github.com/en/pull-requests/reference/forks), [Syncing a fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork), [About merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github), [Managing a merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue), [Setting guidelines for repository contributors](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors), [About releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).
- GitHub CLI 2.88.1, local help: `gh repo fork --help`, `gh repo sync --help`, `gh pr create --help`.
- The authors of the models: Vincent Driessen, [A successful Git branching model](https://nvie.com/posts/a-successful-git-branching-model/) with the 2020 note; Scott Chacon, [GitHub Flow](https://scottchacon.com/2011/08/31/github-flow/); GitLab, [What is GitLab Flow?](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/); [trunkbaseddevelopment.com](https://trunkbaseddevelopment.com/); Microsoft, [How Microsoft develops with DevOps](https://learn.microsoft.com/en-us/devops/develop/how-microsoft-develops-devops).
- DORA capability pages: [trunk-based development](https://dora.dev/capabilities/trunk-based-development/), [working in small batches](https://dora.dev/capabilities/working-in-small-batches/), [version control](https://dora.dev/capabilities/version-control/).
- Conventions: [How to Write a Git Commit Message](https://cbea.ms/git-commit/), [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/), [Semantic Versioning 2.0.0](https://semver.org/), [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).

**Secondary sources**

- The Phase 0 report of this course, sections 6, 12 and 13, and section 6 of its notes on books, documentation and misconceptions.
- Martin Fowler, [Patterns for Managing Source Code Branches](https://martinfowler.com/articles/branching-patterns.html); Pete Hodgson, [Feature Toggles](https://martinfowler.com/articles/feature-toggles.html); Rouan Wilsenach, [Ship / Show / Ask](https://martinfowler.com/articles/ship-show-ask.html).
- Lopes, Accioly, Borba and Menezes, interview-and-survey study of branching workflows, [arXiv 2507.08943](https://arxiv.org/abs/2507.08943).
- Vendor and company material, linked where used, each describing its own environment: GitHub and Shopify on merge queues, Atlassian on Gitflow.

**Videos** (from the report's tables, with its caveats)

- [3 Git Workflows Every Developer Should Know](https://www.youtube.com/watch?v=GQQqf-C2ha4), TechWorld with Nana, 13 January 2026, 32 minutes: a neutral comparison of Git Flow, GitHub Flow and trunk-based development. Caveat: it has a sponsored segment.
- [Continuous Integration vs Feature Branch Workflow](https://www.youtube.com/watch?v=v4Ijkq6Myfc), Dave Farley, 6 January 2021, 18 minutes: the argued case for trunk. Caveat: deliberately one-sided advocacy; watch it after the first, and with section 27.13 beside you.
- [Implementing a Strong Code-Review Culture](https://www.youtube.com/watch?v=PJjmw9TRB7s), Derek Prior, RailsConf 2015, 38 minutes: review as teaching and context-giving. Tool-independent and still valid.

**Further reading**

- Jackson Gabbard, [Stacked Diffs Versus Pull Requests](https://jg.gg/2018/09/29/stacked-diffs-versus-pull-requests/), and Gergely Orosz, [Stacked Diffs](https://newsletter.pragmaticengineer.com/p/stacked-diffs).
- *Accelerate* (Forsgren, Humble, Kim, 2018), the book-length statement of the DORA research.
- [Chapter 28: AI/ML workflows](ch28-ai-ml-workflows.md) applies this chapter to repositories that also hold notebooks, data pointers and evaluation runs.
