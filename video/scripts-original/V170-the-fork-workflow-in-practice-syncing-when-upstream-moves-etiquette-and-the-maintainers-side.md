# V170: The fork workflow in practice: syncing when upstream moves, etiquette, and the maintainer's side

- **Part.** 8, Professional practice
- **Module.** 34, with Module 21
- **Planned minutes.** 24
- **Prerequisites.** V058, V127, V169
- **Textbook sections.** [Chapter 27](../../textbook/ch27-open-source-team-workflows.md), sections 27.1 to 27.4
- **Demo scripts.** `labs/ch27/fork-sync.sh` (snippets `01-clone-fork` to `08-after-squash-merge`); GitHub side: screen walkthrough following Lab 21.1 in [`lab-manual/m21-pull-requests-forks.md`](../../lab-manual/m21-pull-requests-forks.md)

## HOOK

**[ON SCREEN]** "Our pull request to an open-source dependency has been ignored for three weeks. What did we do wrong?"

A team that depends on an open-source gateway finds a bug, fixes it in an afternoon and opens a pull request. Three weeks later nothing has happened. Meanwhile the project's `main` has moved, the pull request shows a conflict, and the engineer's fork says it is "two commits ahead, forty behind". Nobody on the team can say how the fork got ahead of a project they never had write access to.

Both problems have causes you can name. One is in the commit graph. The other is in how the pull request spends a maintainer's attention.

## INTRODUCTION

Welcome to Part 8, professional practice. Parts 1 to 7 gave you mechanisms. This part is about agreements between people, and the claim of Chapter 27 is that every such agreement can be read off two facts you already have: a branch is a ref that names a commit, and a release is a tag that names a commit.

In V127 you carried one change through the fork workflow. Today the project does not stand still while you wait. Upstream moves, twice. You sync the fork's `main`, update your branch once by rebase and once by merge, answer a review round, and see what a squash merge does to the question "is my branch merged?". Then we change sides and look at the same pull request from the maintainer's chair.

A note on layers, which the chapter makes at its start: branches, tags, merges and rebases are **Git**. Forks, pull requests and the merge button are **GitHub**. A workflow is a convention that people hold.

## LEARNING OBJECTIVES

After this video you can:

1. Set up the three repositories and two remotes of the fork workflow from the command line.
2. Sync a fork's default branch in three ways and update a topic branch in two, and say what each does to history.
3. Repair a fork whose `main` has stray commits without losing them.
4. Respond to a review round on a rebased branch so that the reviewer can see what changed.
5. Apply the etiquette of section 27.4 as contributor and as maintainer.

## CONCEPT

**Why the fork workflow exists.** A project cannot give write access to everyone who might send a fix. So you never push to the project's repository. You push to a server-side copy that you own, and you ask the project to take your commits through a pull request.

**What it is, precisely.** Three repositories, each with its own refs.

| Repository | Remote name in your clone | You can | You use it to |
|---|---|---|---|
| The project (upstream) | `upstream` | fetch | learn what the project's `main` is now |
| Your fork | `origin` | fetch and push | publish branches for pull requests |
| Your clone | none: it is the local repository | everything | do the work |

**[ON SCREEN]** The ten steps as section 27.2 lists them. Steps 1, 5, 6 and 8 happen on GitHub; the commands are shown without output.

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

**Inside `.git`.** Nothing is new. `refs/remotes/upstream/*` and `refs/remotes/origin/*` are two sets of remote-tracking refs, filled by two fetch refspecs in `.git/config`. The pull request does not exist in your repository at all.

**When upstream moves.** There are two different things to keep current, and people mix them up.

The first is the fork's default branch. It should be an exact copy of the project's `main`. If you never commit on it, updating it is always a fast-forward. That is the rule to remember from today: never commit on the fork's `main`. It should only ever fast-forward to upstream.

The second is your feature branch. It contains your commits on top of an old upstream commit. Updating it means either replaying your commits on the new tip, which is a rebase, or merging the new tip into the branch.

GitHub documents three ways to do the first. Two run on the server and are described from the documentation. The third is plain Git, and we run it.

| Way | Where it runs | What it does | What it leaves for you |
|---|---|---|---|
| The **Sync fork** control on the fork's page (label from the documentation; the interface changes) | GitHub | updates the fork's branch from upstream | your clone is now behind `origin`: `git pull --ff-only` |
| `gh repo sync <owner>/<fork>` | GitHub, through the API | fast-forwards the fork's default branch from its parent; `--force` hard-resets it instead | the same |
| `git fetch upstream`, fast-forward, `git push origin main` | your clone | moves your local `main`, then the fork's | nothing: the clone is already current |

One trap in the middle row: `gh repo sync` without an argument updates the local repository instead. The destination is the argument.

**Rebase or merge for the branch.** Which to use is the project's decision: read its contribution guide. Where it is silent, the textbook's rule is: rebase freely until review starts and add commits afterwards, because a reviewer who has read a commit should be able to trust that it has not changed.

**Etiquette, in one sentence.** A maintainer's scarce resource is attention, and every convention of open-source contribution is a way of spending less of it per accepted change.

Before you write code: read the contribution guide. It tells you the branch to target, the merge method, the test command, the commit message convention and whether a sign-off or a contributor agreement is required. GitHub shows a repository's `CONTRIBUTING` file when someone opens an issue or pull request, and since 7 August 2025 in the repository's tab bar and sidebar. And open an issue first for anything large. A pull request nobody asked for forces the maintainer to choose between reviewing work that does not fit the roadmap and rejecting work somebody spent a week on. An issue costs both sides ten minutes.

When you open the pull request: one logical change, because a small, self-contained change is one a stranger can evaluate. Say what you tested; for an ML change, which evaluation set, which metric, which commit. Leave "allow edits by maintainers" on for a fork you own. And expect checks to behave differently: workflows on a pull request from a fork run without the project's secrets, and in a public repository the default is that first-time contributors need a maintainer's approval before workflows run. A red check that needs a secret is not your bug. Say so in the pull request instead of pushing guesses.

While it is in review: answer every comment, and do not force-push over a review in progress unless the project asks for it. Do not open a second pull request because the first is quiet. Ask once, after a reasonable wait, in the place the project names.

**The maintainer's side.** The same economics in reverse.

| Maintainer need | Tool |
|---|---|
| Tell contributors the rules once | `CONTRIBUTING.md`, templates, default community health files |
| Never run untrusted code with secrets | `pull_request` instead of `pull_request_target`; approval for outside contributors |
| Route review to the right people | `CODEOWNERS` |
| Keep `main` releasable | required checks, required review, merge queue |
| Keep credit when squashing | read the proposed squash message before confirming; who GitHub records as author and co-authors is flagged as unverified in Chapter 17 |

## MENTAL MODEL

The textbook's analogy is a journal submission. You do not edit the journal. You send a manuscript, reviewers ask for changes, you send a revision, and an editor decides.

The analogy carries the etiquette well. A manuscript on a topic the journal did not ask for, three times the usual length, with no statement of method, waits. So does a pull request.

It breaks at storage. On GitHub your copy and the journal's share one object store, a fork network, so what you push to your fork can be reached from the upstream repository by commit ID. A manuscript in your drawer is private; a commit on your public fork is not.

For the Git side, hold this picture: your local `main` is only a relay. It carries commits from `upstream/main` to `origin/main` and never contributes one of its own. The moment it has a commit of its own, the relay is broken, and every later pull request branch that starts from it carries that commit along.

## DIAGRAM

**[DIAGRAM]** Three boxes. Upstream top left, your fork top right, your clone across the bottom. Add the arrows in the order of their numbers.

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

Say, while drawing: no arrow goes from your clone up into the left box. You fetch from upstream; you never push to it. The pull request's ref, `refs/pull/57/head`, lives in the upstream repository, although the commits arrived through your fork.

**[ON SCREEN]** Later, after the squash merge in the demo, the root-cause box of section 27.3.

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

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch27/fork-sync`. No network is available in the lab, so two bare repositories play the two servers: `upstream/promptgate.git` is the project, maintained by Asha, and `fork/promptgate.git` is your fork. The project, `promptgate`, is a gateway between product teams and LLM providers.

**Step 1: clone the fork, name the upstream.** 🟢 SAFE: adding a remote and fetching add refs and objects.

```bash
git clone -q fork/promptgate.git you/promptgate
cd you/promptgate
git remote add upstream ../../upstream/promptgate.git
git fetch -q upstream
git remote -v
git branch -a -vv
```

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

**Step 2: branch from upstream, commit, publish on the fork.** 🟢 SAFE for the new branch and the commit; 🟡 CAUTION for the push, which creates a new branch on your own fork.

```bash
git switch -c fix/suspended-tenant upstream/main
git commit -q -am "Fix limit 0 being treated as unlimited"
git push -u origin fix/suspended-tenant
```

Predict: after these three commands, what is the upstream branch of `fix/suspended-tenant`?

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

Read the two "set up to track" lines. The switch made `upstream/main` the upstream of the new branch, which is the right base for comparison. The push with `-u` then replaced it with `origin/fix/suspended-tenant`, which is the right destination for pushes. After this, `git status` compares you with your fork, not with the project. To compare with the project you ask explicitly: `git log --oneline upstream/main..HEAD`.

**Step 3: upstream moves.**

```bash
git fetch upstream
git rev-list --left-right --count upstream/main...origin/main
git log --oneline --graph --all
```

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

One and zero. One commit on the left side, `upstream/main`, that the right side, `origin/main`, lacks, and none the other way. That second zero is what makes the sync safe. If it were a two, you would be looking at the fork from the hook.

**Step 4: sync the fork's `main` with plain Git.**

```bash
git switch -q main
git merge --ff-only upstream/main
git push origin main
git rev-list --left-right --count upstream/main...origin/main
```

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

`--ff-only` is the guard. If you had committed on `main` by mistake, the merge would stop instead of creating a merge commit that exists only in your fork and that every later pull request would carry. Zero and zero: the relay is in order.

**Step 5: update the branch, way 1, by rebase.** 🟡 CAUTION for `git rebase`: it rewrites local commits. Predict: will a plain `git push` work afterwards?

```bash
git switch -q fix/suspended-tenant
git rebase upstream/main
git push
```

🔴 DANGEROUS: `git push --force-with-lease --force-if-includes`. The five answers before it runs. What it changes: the branch on the fork, to a commit that does not descend from the old one. What it can destroy: commits on that server branch that are not in your clone, for example a fix a maintainer pushed to your pull request branch. Preview: `git fetch origin`, then `git log HEAD..origin/fix/suspended-tenant` lists what would be dropped. Recovery: push the old tip back from any clone that still has it; your own old tip is in the branch reflog. When it is appropriate: on a branch that only you push to, after a rebase.

```bash
git push --force-with-lease --force-if-includes
git log --oneline --graph --all
```

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

The rebase replaced commit `a83a713` with `3560caf`: same change, new parent, new ID. The fork still had the old commit, so the plain push was rejected as a non-fast-forward. The lease makes the forced push succeed only if the fork's branch is where your clone last saw it, and `--force-if-includes` only if you have integrated what you last saw.

**Step 6: upstream moves again. Way 2, by merge.**

```bash
git fetch -q upstream
git merge -m "Merge upstream main into fix/suspended-tenant" upstream/main
git push
git log --oneline --graph fix/suspended-tenant
```

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

**[ON SCREEN]** The comparison table of section 27.3.

| | Rebase onto `upstream/main` | Merge `upstream/main` into the branch |
|---|---|---|
| Your commit IDs | change | stay |
| Push | forced | plain |
| Branch history | linear, reads as if written today | has "merge upstream" commits |
| Review comments already made | may lose their anchor; the reviewer needs `git range-diff` to see what changed | stay attached |
| Conflicts | resolved once per replayed commit | resolved once, in the merge |

Stay on the fourth row. If the project asks you to rebase during review, the reviewer cannot see from the forced push what changed between the two versions. `git range-diff`, from V058, is the tool that compares the old series with the new one. Say in the pull request that you rebased and what changed, so the reviewer does not have to read everything again.

**Step 7: the review round.** The reviewer asks for a test. After review has started, changes are added, not rewritten.

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

A plain push, and the pull request updates because it follows the branch.

**Step 8: the maintainer squash-merges.** The lab imitates the merge button with `git merge --squash` in Asha's clone; GitHub documents the result as one new commit on the base branch. Predict: is your branch tip an ancestor of the new `main`?

```bash
git fetch upstream
git log --oneline -2 upstream/main
git switch -q main && git merge -q --ff-only upstream/main && git push -q origin main
git merge-base --is-ancestor fix/suspended-tenant main
git diff --stat main fix/suspended-tenant
git branch -d fix/suspended-tenant
git push origin --delete fix/suspended-tenant
```

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

**[PAUSE]** Exit status 1: not an ancestor. `git branch --merged` tests the same reachability and would not list the branch. The empty `git diff --stat` is the content test: `main` has everything the branch has. Show the root-cause box now.

One line contradicts a rule you may have read: `git branch -d` deleted a branch that was not merged into `main`, with a warning. The manual explains it: `-d` requires the branch to be "fully merged in its upstream branch, or in `HEAD` if no upstream was set". The upstream here is `origin/fix/suspended-tenant`, which has every commit.

**[ON SCREEN]** GitHub walkthrough. Layer label: GitHub.

Now the same cycle in your own practice repository, following Lab 21.1, Part B. The GitHub interface changes; the lab's text and the linked documentation are the reference, and no GitHub output was captured for this course. Run it in your normal shell, not in `labs/shell`, because the lab shell switches off the system configuration where the credential helper lives.

As the contributor: fork the practice repository and clone the fork, and check with `git remote -v` that two remotes exist. Create the branch from `upstream/main`, commit, push to `origin`, and open the pull request against the upstream repository. On the pull request page, find three things by their function: the base and the head, which name two repositories; the control that allows edits by maintainers; and the list of checks.

Then exchange the roles, so that you are the maintainer. Open the pull request as the owner of the organization. Read it the way section 27.4 says a maintainer does: is it one logical change, does it say what was tested, does it target the branch your contribution guide names? Merge it, and before you confirm a squash, read the proposed commit message. Then go back to the contributor's clone, sync `main` with the fast-forward relay, and delete the branch in both places.

## COMMON MISTAKES

1. **Committing on the fork's `main`.** Root cause: the fork's default branch is treated as a working branch, so it stops being a copy of upstream and can no longer be fast-forwarded.
2. **Starting the topic branch from the fork's `main` instead of `upstream/main`.** Root cause: nothing updates the fork for you, so its `main` is an old commit and the pull request starts behind.
3. **Asking "is it merged?" with an ancestry test after a squash merge.** Root cause: the merge method discarded the ancestry and kept the content.
4. **Force-pushing over a review in progress.** Root cause: the reviewer's comments are anchored to commits that the rebase replaced, so their work has to be redone.
5. **Pushing guesses at a red check on a fork pull request.** Root cause: workflows from forks run without the project's secrets, so a job that needs one fails whatever the code does.

## PRODUCTION EXAMPLE

A model-evaluation team uses an open-source tokenizer library and finds that it miscounts a class of inputs. The engineer reads the project's contribution guide first. It asks for an issue before a pull request, for a rebase onto `main` before review and added commits after, and for a sign-off. She opens an issue with a ten-line reproduction. A maintainer answers the next day and names the function to change.

Her pull request is one commit and one test, and its description says which evaluation set, which metric and which commit she tested against. The check that publishes benchmark results is red, because it needs a secret that fork runs do not get; she says so in the description. When upstream moves, she rebases, pushes with the lease, and writes one line saying that nothing but the base changed. The pull request is merged in four days. The team's earlier attempt, a single large pull request with a refactoring nobody had asked for, is still open.

## PRACTICE EXERCISE

Do Exercise 21.5, Level 3, "The fork that cannot be synced", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

Before you run any command in it, predict what `git rev-list --left-right --count upstream/main...origin/main` will print for a fork whose `main` has stray commits, and what `git merge --ff-only upstream/main` will do in that state. Write down how you would keep the stray commits before you repair the branch. Then do the exercise. Its solution is in a separate file; open it after your attempt.

The challenge is Exercise 34.6, Level 5, "The contributor who was never answered", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q344: "Your fork's `main` is two commits ahead of and forty behind upstream. How did that happen, and how do you repair it without losing the two commits?"

Answer aloud first. A strong answer explains both numbers from the graph: what "ahead" means for a branch that should only relay, and why "behind" is the normal state of a fork nobody synced. It names the read-only command that shows the two counts. It then repairs in an order that cannot lose work: the two commits get a name before `main` is moved. And it says what would have stopped the mistake at the moment it was made, which is one option on one command you saw today.

## RECAP

- The fork workflow has three repositories and two remotes; you fetch from `upstream` and push to `origin`.
- The fork's `main` is a relay that only fast-forwards; `git merge --ff-only upstream/main` is both the sync and the guard.
- A topic branch is updated by rebase, which needs a forced push with a lease, or by merge, which needs a plain push and leaves a merge commit.
- After a squash merge the branch is not merged by ancestry; test content, then delete the branch and never reuse it.
- A maintainer's scarce resource is attention: contribution guide first, issue first, one logical change, say what you tested.

## HOMEWORK

Read sections 27.1 to 27.4. Then read the CONTRIBUTING file of one project you use and note what it asks before a first pull request: the target branch, the merge method, the test command, the message convention, a sign-off or agreement. In the next video, branch names turn out to be conventions, and four branching models are drawn as graphs.
