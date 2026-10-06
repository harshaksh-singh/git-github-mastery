# V174: Practices with their reasons, anti-patterns with their root causes, code review, and commit message conventions

- **Part.** 8, Professional practice
- **Module.** 34
- **Planned minutes.** 26
- **Prerequisites.** V028, V090, V173
- **Textbook sections.** [Chapter 27](../../textbook/ch27-open-source-team-workflows.md), sections 27.15 to 27.21; [`reference/professional-git-configuration.md`](../../reference/professional-git-configuration.md)
- **Demo scripts.** `labs/ch27/practices.sh`, `labs/ch27/lab-34-1-design-review-evidence.sh`, `labs/ref/professional-config.sh`

## HOOK

**[ON SCREEN]** "Why do we require small commits? It slows people down."

A deadline is close, and a senior engineer proposes to suspend three team rules for two weeks: small commits, the required check, and the ban on force pushes to shared branches. Somebody answers "those are best practices". That answer loses the argument, because it gives no reason, and a rule without a reason is the first thing to go under pressure.

The textbook puts it in one line: a practice you can't justify is a superstition, and it will be dropped under pressure. Today each practice gets its mechanism, and each anti-pattern gets the wrong mental model that produces it. Hold on to the question on screen. One revert, in one line of output, will answer it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video closes the chapter on team workflows. It has four parts: practices with their reasons, anti-patterns with their root causes, code review as a practice, and commit message conventions. Then it returns to something you started in video 28 and extended with your hook proposal in video 90: your configuration worksheet. Today you finalize it.

Nothing here needs a new mechanism. Every reason is a fact from an earlier part of the course: what a commit is, what a ref is, what a merge brings, what a push checks. As a reminder: a commit is one saved snapshot of the project with a message. A ref is a name that points at a commit, such as a branch. A merge brings in every commit reachable from the other side. And a push asks the server to move its ref. The work of this video is to connect each rule to the fact that pays for it.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Give the mechanism behind each practice: small commits, meaningful messages, protected `main`, required checks, no force push on shared branches.
2. Give the root cause behind each anti-pattern the section lists.
3. Show with a transcript what a small commit buys at revert time.
4. Query commit messages as data: by trailer, by type, by issue.
5. Finalize a personal and a team configuration from the worksheet of Module 5.

## CONCEPT

**Practices, each with its reason.** Read this table as two columns: what breaks without the practice is the mirror image of the reason.

**[ON SCREEN]** The table of section 27.15, one row at a time.

| Practice | The reason, in terms of mechanism |
|---|---|
| Small commits, one logical change each | a commit is the unit of `revert`, `cherry-pick`, `bisect` and review; a commit that does three things can only be undone, ported or blamed as three things |
| Meaningful messages | the message is the only part of a commit that records why; the diff already records what |
| A protected main branch | a ref anyone can move is a ref anyone can break or rewind; a rule turns "we agreed not to" into "the server refuses" |
| Review before merge | a second reader catches what the author's model of the change hides, and spreads knowledge of the code |
| Required CI checks | a check that is not required is advice; and a check must run on the merged result to mean anything about `main` |
| No secrets in Git | history is copied to every clone and fork and cannot be recalled; deleting the file adds a commit and removes nothing |
| `--force-with-lease`, never bare `--force` | a bare force sets the server's ref with no check; a lease makes the push conditional on the ref being where you last saw it |
| Signed commits and tags where identity matters | author and committer fields are text that anyone can set; a signature is evidence that a key holder made the object |
| A branch naming scheme | rules, workflow triggers and cleanup scripts select branches by pattern |
| Rebase private branches | rebasing rewrites commit IDs; on a branch nobody else has, nobody else can be holding the old IDs |
| No history rewriting on shared branches | everyone who fetched the old commits now has a history that diverges from the server, and the next careless merge brings the removed commits back |
| Inspect before you merge | a merge brings every commit reachable from the other side, not only the ones you had in mind |

Three of these rows answer the hook. Small commits: because the commit is the unit of undo, of porting, of bisect and of review. Revert undoes one commit with a new commit, cherry-pick copies one commit to another branch, and bisect searches history for the commit that broke something. No force push on shared branches: you watched in video 168 what the next careless merge does. Required checks: a check that isn't required is advice.

**Anti-patterns, each with its root cause.** An anti-pattern is rarely stupidity. Each one is the reasonable result of a wrong mental model, and the model is what you correct.

**[ON SCREEN]** The table of section 27.16.

| Anti-pattern | Root cause: the model behind it | The correction |
|---|---|---|
| Giant commits | "a commit is a save point for my day", not a unit of change | stage by hunk (`git add -p`); one logical change per commit |
| Committed secrets | "the repository is private", or "I will delete it in the next commit" | rotate first, then clean up; push protection |
| Committed generated files | "everything needed to run should be in the repository", confusing sources with outputs | ignore outputs; commit the inputs and the lock file |
| Rebasing shared branches | "rebase tidies history", without the fact that it creates new commits | rebase only what nobody else has; merge on shared branches |
| Blind force-push | "the push was rejected, so force it": the rejection is read as an obstacle and not as information | read the rejection; fetch; `--force-with-lease --force-if-includes`; forbid force pushes on shared branches by rule |
| Meaningless messages (`wip`, `fix`, `update`) | "the diff explains itself" | a message convention |
| `git reset --hard` without understanding state | "reset means undo" | know the three trees; `git stash` or commit first |
| Merging without inspecting history | "merging a branch brings my change", not "everything reachable from it" | `git log A..B` before every merge |
| Ignoring CI | "it is flaky", or "it passed locally" | make checks required; fix or delete flaky tests; know why CI differs from your machine |
| Outdated authentication | a tutorial from before 13 August 2021, when GitHub stopped accepting account passwords for Git operations; or one long-lived token with full scope shared by a team | Chapter 16 |
| Huge binaries in Git | "Git stores my project", without the fact that every clone carries every version of every file | pointers and external storage |
| Treating GitHub as Git | "it is on GitHub, so it is backed up and it is the truth" | label the layer: which behavior is Git's, which is the platform's |

The teaching point is in the middle column. When a colleague force-pushes blindly, the correction is not "do not do that". It's the missing fact: a rejection is information about the server's ref.

**Code review as a practice.** Review is where a team's knowledge of its code is exchanged. Finding defects is the smaller part of its value, and a review that takes days costs more than it finds.

Four points from section 27.17. Size decides everything else: every technique that shortens branches, flags, stacks and small commits, is also a review technique. Speed is part of quality: DORA lists heavyweight and slow review as a pitfall, and a change that waits two days makes its author start something else, so agree on a time to first response. Say what kind of comment it is: blocking, a question, or a preference. Rouan Wilsenach's "Ship / Show / Ask" lets the author choose per change whether to merge directly, to open a pull request and merge without waiting, or to wait for discussion. It presupposes trust, good CI and feature flags.

And review the right things. A human reviewer's attention is best spent on what a machine can't check: whether the change does what the issue asked, whether it is in the right place, what it does on failure, what it does to data. Formatting and import order belong to a tool. In an ML repository add three questions. Which data and which evaluation support the claim in the description? Was a prompt or configuration change evaluated, or only edited? And does the pull request change anything under `.github/workflows/`, a lock file or a `Dockerfile`, which deserve a second reader?

Quick quiz. A reviewer clicks "Request changes" on a pull request. Does that alone block the merge? A, yes. B, no. Your answer?

**[PAUSE]**

B, and here is why.

What review doesn't replace: tests, required checks and rules. "Request changes" doesn't block a merge, and `CODEOWNERS` doesn't enforce review, unless a ruleset says so.

**Commit message conventions.** The subject line says what the commit does, the body says why, and trailers carry facts that tools read.

Git itself imposes one piece of structure: the first line, up to the first blank line, is the subject, which is what `git log --oneline`, `git shortlog` and `git format-patch` use. Everything else is convention. The most cited one is Chris Beams's seven rules: separate subject from body with a blank line. Limit the subject to about 50 characters. Capitalize it. Don't end it with a period. Use the imperative mood. Wrap the body at 72 characters. Use the body to explain what and why, not how.

Try it now, for thirty seconds. In any repository of yours, type `git log --oneline --graph -6`. It only reads. For each of the six subjects, ask one question: would a stranger know what this commit does? I'll wait.

**[PAUSE]**

If one of them says `wip` or `fix`, you're in good company. Almost every history has some. And you know the cost now: the message is the only part of a commit that records why.

Conventional Commits 1.0.0 adds a machine-readable prefix: type, optional scope, a colon, a description. `fix` corresponds to a PATCH release in Semantic Versioning, `feat` to a MINOR one, and a `BREAKING CHANGE` footer, or an exclamation mark after the type, to a MAJOR one. Other types such as `docs` or `chore` are allowed. The point is that release tooling can compute the next version number and a changelog from the history.

Trailers are lines of the form `Key: value` at the end of the message: `Co-authored-by`, `Signed-off-by`, which `git commit -s` adds, `Reviewed-by`, or an issue reference. `git interpret-trailers` parses them, and `git log --format='%(trailers:key=Co-authored-by)'` prints them.

**What the convention cannot do.** It doesn't make a message true. `fix: typo` on a commit that changes a rate limit passes every commit-message linter. A convention is enforced the same way as any other local check: a `commit-msg` hook for fast feedback, and a required check or the squash-merge title for the guarantee.

## MENTAL MODEL

A picture helps. Think of each practice as an insurance policy with a named risk. If you can name the risk and the day it pays out, the policy survives a budget discussion. If you cannot, it's cancelled the first time money is short.

Small commits pay out on the day of a revert, a backport or a bisect. A protected `main` pays out on the day somebody's push would have rewound it. The message pays out the day somebody asks why a line exists and the author has left.

Where the picture breaks: an insurance policy costs the same whether or not you understand it, and a practice does not. A team that follows a rule without its reason follows it badly: commits that are small in lines and still mix three changes, messages that satisfy the linter and say nothing.

For anti-patterns, the model is the root-cause box you have used since video 4, applied to people. Observed behavior: the anti-pattern. Root cause: a sentence the person believes. Correct fix: the missing fact.

## DIAGRAM

**[DIAGRAM]** Two new tables, built live. The first has the columns "practice" and "what breaks without it". Fill it from section 27.15 by turning each reason around.

```text
  Practice                           What breaks without it
  ---------------------------------  ---------------------------------------------------------
  small commits                      revert, cherry-pick, bisect and review work on a unit
                                     that does three things at once
  meaningful messages                nothing records why; the diff only records what
  protected main                     anyone can move the ref, so anyone can break or rewind it
  required checks                    the check is advice; red becomes normal
  --force-with-lease                 the server's ref is set with no check at all
  no rewriting of shared branches    old commits come back with the next careless merge
  inspect before merging             commits you did not have in mind arrive on main
```

The second has the columns "anti-pattern" and "root cause", from section 27.16. Write the root cause as the sentence the person believes, in quotation marks.

```text
  Anti-pattern                       Root cause: the model behind it
  ---------------------------------  ---------------------------------------------------------
  giant commits                      "a commit is a save point for my day"
  committed secrets                  "the repository is private"
  rebasing shared branches           "rebase tidies history"
  blind force-push                   "the push was rejected, so force it"
  reset --hard without the state     "reset means undo"
  merging without inspecting         "merging a branch brings my change"
  treating GitHub as Git             "it is on GitHub, so it is backed up and it is the truth"
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch27/practices`. The project is `promptgate`; a branch `feature/fallback` is about to be merged.

Into the lab. The project is `promptgate`, and a branch called `feature/fallback` is about to be merged.

**Step 1: inspect before merging.** Three commands answer "what would this merge bring, and will it merge cleanly", and none of them changes anything. 🟢 SAFE. `git merge-tree` adds unreferenced objects and touches no ref.

```bash
git log --oneline main..feature/fallback
git diff --stat main...feature/fallback
git merge-tree --write-tree --name-only main feature/fallback
```

Predict: the branch is called "fallback". How many commits do you expect, and what do you expect them to touch? Say it out loud.

**[PAUSE]**

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

The two-dot `git log` lists the commits you would gain. The three-dot `git diff` shows the change since the merge base, which is what a pull request shows. `git merge-tree --write-tree` merges in memory and prints the ID of the resulting tree. Exit status 0 means no conflicts. And the first list contains a surprise: `dd57a51`, a commit that raises a limit "for load test". That's the row "inspect before you merge" in one line of output.

**Step 2: it is merged anyway.** 🟡 CAUTION: a merge moves the current branch.

<!-- snippet: ch27/practices/02-merge -->
```text
$ git merge --no-ff -m "Merge pull request #51 from feature/fallback" feature/fallback
Merge made by the 'ort' strategy.
 gateway/fallback.py | 5 +++++
 gateway/limits.py   | 2 +-
 gateway/router.py   | 7 +++++--
 3 files changed, 11 insertions(+), 3 deletions(-)
 create mode 100644 gateway/fallback.py
$ git log --oneline --graph -6
*   590ed81 Merge pull request #51 from feature/fallback
|\  
| * dd57a51 chore: raise default limit for load test
| * 4ea69d0 feat(router): fall back when the primary model is unhealthy
| * 8df1ca6 feat(router): add fallback table
* | f09559c docs: say how to run the tests
|/  
* b6e2f58 Add per-tenant rate limits
```
<!-- /snippet -->

A merge commit that preserves the three commits.

**[ANIMATION]** merge: three-way feature/fallback into main common=b6e2f58 main_only=f09559c feature_only=8df1ca6,4ea69d0,dd57a51 merge_id=590ed81 cmd_merge=git_merge_--no-ff_feature/fallback title=What_this_merge_brings say_merge=The_merge_590ed81_brings_all_three_commits

Here's that merge as a graph. Three commits sit on the branch, and the merge brings all three: the two you had in mind, and `dd57a51`.

**[ANIMATION]** end

**Step 3: why small commits pay.** The load-test limit reached production. 🟡 CAUTION: `git revert` adds a commit, which moves the branch, and removes nothing.

```bash
git revert --no-edit dd57a51
git show --stat --format="%h %s" HEAD
grep default gateway/limits.py
```

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

One commit undone, one file touched, the feature intact. That's the answer to the question from the opening: this is what small commits buy.

**Step 4: the same branch as one squashed commit.** A squash folds the commits of a branch into one. Predict: what does the only available revert remove? Say it out loud.

**[PAUSE]**

```bash
git show --stat --format="%h %s" HEAD
git revert --no-edit HEAD
git show --stat --format="%h %s" HEAD
```

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

Three files, and `gateway/fallback.py` is deleted. The only revert available removes the fallback feature together with the mistake. Squash merging is a legitimate choice, and this is its price: the unit of undo becomes the pull request. The practice that follows is not "never squash". It is "keep pull requests as small as the commits you would have wanted".

**Step 5: messages as data.**

```bash
git log --format="%h %s" v1.3.0..HEAD
git log --oneline --grep="^feat" v1.3.0..feature/fallback
git log --format="%s" v1.3.0..feature/fallback | sed "s/[(:].*//" | sort | uniq -c
git shortlog -sn v1.3.0..feature/fallback
```

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

`--grep="^feat"` and the `sort | uniq -c` pipeline work only because the prefix is regular. `Add model fallback (#51)` is a GitHub-style squash subject, with the pull request number as the link back to the discussion. Note that `git shortlog` is given a revision range. Without one it reads standard input.

**Step 6: measuring a repository.** Replay `labs/run ch27/lab-34-1-design-review-evidence`. This is the repository of Lab 34.1, `riskscore`, which contains several anti-patterns on purpose. The lab finds each from the command line: an anti-pattern you can measure is one you can put in front of a CTO. We read what each command measures. What it means for a design is your work in the lab. Every command here is 🟢 SAFE.

Branches, by age and by distance from `main`:

<!-- snippet: ch27/lab-34-1-design-review-evidence/01-branches -->
```text
$ git for-each-ref --sort=committerdate --format='%(committerdate:short) %(ahead-behind:main) %(refname:short)' refs/heads
2026-05-04 0 2 release/2.1
2026-05-18 1 5 release/2.0
2026-05-19 9 2 feature/big-refactor
2026-06-02 2 2 feature/calibration
2026-08-17 6 2 develop
2026-08-24 0 0 main
$ git branch --no-merged main
  develop
  feature/big-refactor
  feature/calibration
  release/2.0
```
<!-- /snippet -->

Each line: the date of the last commit, how many commits ahead of and behind `main`, and the name. A version caveat from the textbook: the release that introduced `%(ahead-behind:<ref>)` in `git for-each-ref` wasn't confirmed for the chapter. It runs on Git 2.55.

Releases, and where the tags sit:

<!-- snippet: ch27/lab-34-1-design-review-evidence/02-releases -->
```text
$ git for-each-ref --sort=creatordate --format='%(creatordate:short) %(refname:short) %(*objectname:short)' refs/tags
2026-03-20 v2.0.0 e1b64b9
2026-05-04 v2.1.0 628aa42
2026-05-18 v2.0.1 f1e338f
$ git log --oneline --graph --decorate --simplify-by-decoration --all
* a5b7c19 (HEAD -> main) Update README.md
| * cd79546 (develop) Rework explanation ordering
|/  
| * 5ab6aee (feature/calibration) Document calibration
|/  
| * 92bcd50 (feature/big-refactor) refactor step 9
|/  
* 628aa42 (tag: v2.1.0, release/2.1) Merge develop for 2.1
| * f1e338f (tag: v2.0.1, release/2.0) fix
|/  
* e1b64b9 (tag: v2.0.0) model moved to bucket
* e9658fa initial
```
<!-- /snippet -->

The fix-direction check of video 172, asked of each release branch:

<!-- snippet: ch27/lab-34-1-design-review-evidence/03-fix-direction -->
```text
# Is there a fix on a release branch that main never received?
$ git log --format="%h %ad %an: %s" --date=short --cherry-pick --right-only --no-merges main...release/2.0
f1e338f 2026-05-18 Ravi Menon: fix
$ git log --format="%h %ad %an: %s" --date=short --cherry-pick --right-only --no-merges main...release/2.1
```
<!-- /snippet -->

One of the two commands prints a line. You know what a printed line means.

How integration happens:

<!-- snippet: ch27/lab-34-1-design-review-evidence/04-integration -->
```text
$ git rev-list --count --merges main
1
$ git rev-list --count --no-merges main
9
$ git log --format="%ad %s" --date=short --first-parent main
2026-08-24 Update README.md
2026-06-03 Add calibration (#88)
2026-05-04 Merge develop for 2.1
2026-03-12 model moved to bucket
2026-03-10 add model
2026-03-04 remove env file
2026-03-03 wip
2026-03-02 initial
$ git rev-list --count main..develop
6
$ git log -1 --format="%ad" --date=short "$(git merge-base main develop)"
2026-05-04
```
<!-- /snippet -->

Merges against non-merges on `main`, the first-parent log with dates, and how far `develop` is ahead and since when.

What the history contains:

<!-- snippet: ch27/lab-34-1-design-review-evidence/05-history-content -->
```text
# The largest blobs anywhere in history, and where they were:
$ git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | awk '$1 == "blob"' | sort -k2 -n -r | head -3
blob 2097152 models/risk-v1.ckpt
blob 323 score/model.py
blob 302 score/model.py
$ git log --all --format="%h %ad %s" --date=short --diff-filter=A -- .env models
adc77d4 2026-03-10 add model
a2b5f8b 2026-03-03 wip
$ git ls-files
.gitignore
README.md
score/calibrate.py
score/explain.py
score/features.py
score/model.py
```
<!-- /snippet -->

The largest blobs anywhere in history, and the commits that added certain paths. Compare the first output with the `git ls-files` at the end: something is in history that is no longer in the tree.

People and messages:

<!-- snippet: ch27/lab-34-1-design-review-evidence/06-people-and-messages -->
```text
$ git shortlog -sn --all --no-merges
    17	Asha Rao
     7	Ravi Menon
     3	Lab User
$ git log --all --no-merges --format=%s | awk "length(\$0) < 12" | sort | uniq -c
   1 add model
   1 fix
   1 initial
   1 wip
$ git log --format="%G?" main | sort | uniq -c
  10 N
```
<!-- /snippet -->

Who commits, which subjects are shorter than twelve characters, and the signature status of every commit on `main`.

**Step 7: the squash trap, and the content check.** The lab's failure scenario: you report `feature/calibration` as unmerged, abandoned work.

<!-- snippet: ch27/lab-34-1-design-review-evidence/07-squash-trap -->
```text
# Failure scenario: you report feature/calibration as unmerged, abandoned work.
$ git branch --no-merged main
  develop
  feature/big-refactor
  feature/calibration
  release/2.0
$ git merge-base --is-ancestor feature/calibration main
[exit status: 1]
$ git cherry -v main feature/calibration
+ 8e56b319e582cca1280f9842dd82aaed374b0e90 Add calibration
+ 5ab6aeee470148dda19238cfcd6c4d516900c294 Document calibration
$ git log --oneline -1 --format="%h %ad %s" --date=short main -- score/calibrate.py
350f29e 2026-06-03 Add calibration (#88)
```
<!-- /snippet -->

Three commit-based checks agree that the branch isn't merged. The last command shows a commit on `main` whose subject ends in a pull request number. Predict what a content comparison will say.

**[PAUSE]**

<!-- snippet: ch27/lab-34-1-design-review-evidence/08-content-check -->
```text
# Recovery: the checks above compare commits. Compare content instead.
$ git merge-tree --write-tree main feature/calibration
9daa8833bf087fbcd038397d10033760c1a6f87a
$ git rev-parse "main^{tree}"
9daa8833bf087fbcd038397d10033760c1a6f87a
# Merging the branch would produce exactly the tree main already has: nothing is left to merge.
```
<!-- /snippet -->

Merging the branch would produce exactly the tree `main` already has: the two IDs are equal. Nothing is left to merge. This is the root cause from video 170, seen from the maintainer's side.

**Step 8: your configuration.** Replay `labs/run ref/professional-config` and show the file again.

<!-- snippet: ref/professional-config/01-the-file -->
```text
$ cat ~/.gitconfig
# ~/.gitconfig: personal Git configuration, checked on Git 2.55.0.
# Explained line by line in reference/professional-git-configuration.md.
[user]
	name = Lab User
	email = you@example.com
	useConfigOnly = true # refuse to guess an identity
[init]
	defaultBranch = main # unconfigured Git 2.55 still creates master
[core]
	excludesFile = ~/.config/git/ignore # personal ignore patterns
[pull]
	ff = only # never integrate by accident
[push]
	autoSetupRemote = true # first push sets the upstream
[fetch]
	prune = true # forget branches deleted on the server
[merge]
	conflictStyle = zdiff3 # show the common ancestor in conflicts
[rebase]
	autoSquash = true # fixup! commits find their place
	updateRefs = true # stacked branches move together
	missingCommitsCheck = error # a deleted todo line stops the rebase
[rerere]
	enabled = true # remember conflict resolutions
[maintenance "rerere-gc"]
	auto = 0 # avoid the MERGE_RR.lock race of Git 2.55
[diff]
	algorithm = histogram # moved code reads as a move
	colorMoved = default
[tag]
	sort = version:refname # v1.10.0 after v1.9.0
[help]
	autocorrect = prompt # show the suggestion, run nothing
[safe]
	bareRepository = explicit # the planned Git 3.0 default
[transfer]
	credentialsInUrl = die # refuse a token inside a remote URL
[alias]
	st = status -sb
	lg = log --graph --decorate --oneline --all
	last = log -1 --stat
	unstage = restore --staged --
	amend = commit --amend --no-edit
	pushf = push --force-with-lease --force-if-includes
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work # last, so that it wins inside ~/work/
```
<!-- /snippet -->

**[ON SCREEN]** Split: this file on the left; your worksheet from V028 and your hook proposal from V090 on the right.

Go through the file section by section and, for each setting, do what this video did for practices: say the reason. A setting whose reason you can't give goes back on the worksheet with a question mark, not into your configuration. The settings and their trade-offs are those of Chapter 14B, section 14B.5. The reference page adds nothing new. Then separate two lists: what you set for yourself, and what a team should agree on and enforce somewhere other than a personal file.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Defending a rule with "best practice".** Root cause: the mechanism that pays for the rule was never stated, so the rule has no defense when it costs time.
2. **Enforcing the convention and forgetting the truth.** Root cause: a linter checks the form of a message, and form does not make a message true.
3. **Squash-merging large pull requests.** Root cause: the squash makes the pull request the unit of undo, so one mistake can only be reverted together with everything else.
4. **Treating "Request changes" or CODEOWNERS as enforcement.** Root cause: review is a practice; only a ruleset turns it into a condition the server checks.
5. **Reporting a squash-merged branch as abandoned work.** Root cause: commit-based checks test ancestry and patch identity, and a squash keeps the content while discarding both.

## PRODUCTION EXAMPLE

Now, out of the lab. A fraud-model team inherits a scoring repository. The new lead has to tell the CTO what state it is in, and she doesn't want to deliver impressions. She runs the read-only commands of the lab: branch ages and distances, tag positions, the fix-direction check on each release branch, the largest blobs in history, the short subjects, the signature status.

Her report has one line per finding, each with the command that produced it and the practice it relates to. She doesn't write "the history is messy". She writes three things. A fix exists on one release branch with no equivalent on `main`, and she gives the commit ID. One branch reported as unmerged has its content on `main` already and can be deleted. And a file of two megabytes is in history although it is no longer tracked. Each finding ends with a control and the layer that would enforce it. The CTO reads it in five minutes and approves two of the controls the same day, because each came with its reason.

## PRACTICE EXERCISE

Your turn. Do Exercise 34.1, Level 1, "The reason behind the rule", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

For each rule in the exercise, before you write the reason, predict what would break on which day if the rule were dropped. Then write the mechanism in one sentence that names an object, a ref or a check. Compare with the solutions only after you have written all of them.

The challenge is Exercise 34.4, Level 3, "Review these four pull requests", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q343: "Give the mechanism behind three of your team's practices: why small commits, why no force push on shared branches, why inspect before merging."

**[PAUSE]**

Answer out loud. The word that matters is "mechanism". A strong answer gives, for each of the three, a fact about how Git works and the concrete operation that the practice makes cheap or safe. For small commits, name the operations whose unit is the commit. For force pushes, describe the state of a colleague's clone afterwards and what their next ordinary action does. For inspection, say what a merge brings, in terms of reachability, and name the read-only commands. If you can add what each practice costs and when you would relax it, you have answered at the level the question is asked.

## RECAP

Let's land this, in your own words.

- A practice needs its mechanism; without it the practice is dropped under pressure.
- A commit is the unit of revert, cherry-pick, bisect and review, and a squash makes the pull request that unit.
- Each anti-pattern comes from a wrong model, and the correction is the missing fact.
- Review exchanges knowledge; size and speed decide its value; it replaces neither checks nor rules.
- A message convention turns history into data that can be queried, and it cannot make a message true.

## HOMEWORK

Read sections 27.15 to 27.21 and do the Practice section, 27.23. Do Exercise 34.2, Level 2, "Anti-patterns and the model behind them", and Exercise 34.3, Level 2, "Messages as data", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md). Read [`reference/professional-git-configuration.md`](../../reference/professional-git-configuration.md) and finish your personal and team configuration from the worksheet.

Today every rule on your team's list got a reason you can say out loud, and that's what keeps a rule alive under pressure. Finish your worksheet while it is fresh. The next four videos are about AI and ML repositories. Next time: what belongs in Git, notebooks, and a clean filter that strips outputs. Until then, look at the state first and type second. See you in the next one.
