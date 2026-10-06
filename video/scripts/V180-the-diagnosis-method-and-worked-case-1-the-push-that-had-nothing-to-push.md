# V180: The diagnosis method, and worked case 1: the push that had nothing to push

- **Part.** 9, Production debugging and incident response
- **Module.** 35
- **Planned minutes.** 26
- **Prerequisites.** V005, V053, V169
- **Textbook sections.** [Chapter 29](../../textbook/ch29-production-troubleshooting.md), sections 29.1 to 29.3
- **Demo scripts.** `labs/ch29/case-unfinished-rebase.sh` (snippets `01-symptom` to `18-verify`)

## HOOK

**[ON SCREEN]** "I added two commits to my pull request this week. The pull request does not show them. I pushed again and Git says there is nothing to push."

A developer says this on a Thursday. A commit is a saved snapshot of the project, a pull request is a proposal on GitHub to merge a branch of commits, and a push asks the server to move its branch to your commits. The obvious reactions are all changes: push with force, pull, rebase, or the classic, delete the clone and start again. Any of them could destroy two days of work, because nobody yet knows where those two commits are.

Chapter 29 opens with the fact that shapes this whole part of the course: most damage is done after the incident, by the first repair attempt. The original problem in a Git repository is rarely destructive. The second command, typed before the state was understood, is what removes the uncommitted change or rewrites the published branch. So where are those two commits? Today we find them without changing a thing.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is Part 9, production debugging and incident response. Every earlier part gave you mechanisms. This part gives you the method that selects the right one when all you have is a sentence from a colleague.

You met the root-cause framework in video 4 and the ten-command diagnosis in video 5, when you knew very little Git. Today you apply the same framework end to end with everything you've learned since. The case turns on a mechanism from video 53: what a rebase does internally, where HEAD is during it, and when the branch ref moves. A rebase copies a branch's commits onto a new base. HEAD is Git's note of where you are. And a ref is a name that points at a commit, as a branch does.

A CTO doesn't ask "which command fixes this". The questions are: what happened, how do you know, what will the fix change, and how do we stop it from happening again. The method is built to answer those four.

One rule for this video. At a marked point I stop and ask you for three hypotheses. Pause there and write them down before you watch the test.

## LEARNING OBJECTIVES

After this video you can:

1. State the method: symptom, state, evidence, hypotheses, test, root cause, lowest-risk fix, verification, prevention.
2. Restate a colleague's report as a symptom without interpretation.
3. Run the ten-command diagnosis on a repository in an unknown state and say what each output rules out.
4. Write three hypotheses and the read-only command that separates them.
5. Explain why no state-changing command is run before the root cause is named.

## CONCEPT

**Three facts shape the method.**

One: most damage is done by the first repair attempt. Git keeps unreachable commits, the ones no name leads to, for weeks. So the original problem is usually recoverable until somebody acts.

Two: a symptom names no layer. "CI is red" says that the automated checks failed. It may be a Git fact: the commit lacks a file. Or a GitHub fact: the check ran on the merge ref, which names GitHub's test merge of the pull request. Or a GitHub Actions fact: the image of the runner, the machine that runs the job, changed. Evidence decides, not the wording of the complaint.

Three: experience doesn't protect you. The textbook cites a study of Git questions on Stack Exchange: in 2020, 40.0 percent of the people asking Git-command questions had been registered for more than five years, against 21.2 percent of all askers. A fixed procedure is what replaces confidence.

**The method, in one sentence.** Diagnosis is a read-only search for the one fact about the state that explains the symptom, followed by the smallest change that repairs that fact.

**Precisely.** The eleven steps of the framework fall into three phases with different permissions. Phase 1 is read-only: symptom, observe, collect evidence, understand state, form hypotheses, test hypotheses, identify the root cause. It uses only commands with the green label. Phase 2 preserves: it adds refs and files and removes nothing. Phase 3 is the first moment a ref moves or a file is overwritten: select the lowest-risk fix, execute, verify, prevent.

That ordering answers the fifth objective. No state-changing command is run before the root cause is named, because until then you don't know which state is evidence and which state is the only copy of somebody's work. The one kind of change that's allowed earlier is the kind that only adds.

**Understand state.** It means being able to fill in this table for the repository in front of you. Each cell has a command that answers it.

**[ON SCREEN]** The table of section 29.2.

| Place | Question | Command |
|---|---|---|
| Working tree | Which files differ from the index? Which are untracked or ignored? | `git status`, `git diff`, `git status --ignored` |
| Index | What would the next commit record? Are there conflict stages? | `git diff --cached`, `git ls-files -s`, `git ls-files -u` |
| HEAD | A branch, or a raw commit ID? Is an operation in progress? | `git status`, `cat .git/HEAD`, `git symbolic-ref HEAD` |
| Refs | Where does each branch, tag and remote-tracking branch point, and what is each upstream? | `git branch -vv`, `git for-each-ref` |
| History of the refs | How did they get there? | `git reflog`, `git reflog show <branch>` |
| The server | What does it hold now, as opposed to at the last fetch? | `git ls-remote origin` |
| GitHub | What did the platform record: pushes, rule evaluations, checks? | Section 29.8 |

Three of those words, in plain terms. The working tree is the files you edit. The index is the proposed next commit. A remote-tracking branch records where the server's branch was at your last fetch.

**Hypotheses.** A hypothesis is a mechanism plus a prediction: "if the branch was reset, the branch reflog has a `reset: moving to` entry". The reflog is Git's local list of the values a ref has had. Write at least three hypotheses before testing any. With one hypothesis you look for confirmation. With three you look for the command whose output separates them.

**Restating the report.** The developer's sentence contains an interpretation: "I added two commits to my pull request branch." The symptom without interpretation is: two commits that the developer made aren't shown on the pull request, and `git push origin <branch>` prints "Everything up-to-date". Whether they were added to the branch is exactly what isn't known.

In production, ask the reporter for three things: the exact text on the screen, the last three commands they remember, and whether anything was done since. The scrollback often contains the commit ID you'll need.

## MENTAL MODEL

The textbook's analogy is an accident investigator. The investigator secures the site, records everything, reconstructs the sequence, and only then states a cause. Nobody tows the vehicles away first to see whether the road works again.

The analogy breaks in one useful way: a repository can be copied in seconds, so you can rehearse the repair on the copy. No accident site offers that.

Carry one more picture for "Everything up-to-date". It's a statement about one ref: the local branch and the server's branch of that name point at the same commit. It isn't a statement about your work. A push sends a ref. If the ref didn't move, there's nothing to send, wherever your commits are.

## DIAGRAM

**[DIAGRAM]** First, the three phases of section 29.2. Build the left column step by step, then the middle, then the right. Mark the boundary between the first and the second phase heavily.

```text
  PHASE 1: READ-ONLY                      PHASE 2: PRESERVE        PHASE 3: CHANGE
  ------------------------------------    ---------------------    ---------------------------
  SYMPTOM                                 record the output        SELECT LOWEST-RISK FIX
  OBSERVE            git status           backup ref               EXECUTE  (preview, one step)
  COLLECT EVIDENCE   the ten commands     copy of the repository   VERIFY   (same commands)
  UNDERSTAND STATE   five places          bundle                   PREVENT
  FORM HYPOTHESES    at least three
  TEST HYPOTHESES    one command each     (adds refs and files;    (moves refs, rewrites files,
  IDENTIFY ROOT CAUSE  name the layer      destroys nothing)        talks to the server)
```

**[DIAGRAM]** Later, after the evidence has been collected, the state diagram of section 29.3. Two boxes: the clone and the server. Draw the server first; it is the smaller picture.

```text
  scoring-api (your clone)                                         server.git
 +-----------------------------------------------------------+    +--------------------------------+
 |              9fbe4d7---96a7b55---075407e   (HEAD, no name) |    |                                |
 |             /                                             |    |                                |
 |   8bd6e7d--4b30d7e   main, origin/main                    |    |  8bd6e7d--4b30d7e   main       |
 |        \                                                  |    |       \                        |
 |         60d09a1--cd8451c--4a03014  feature/latency-budget |    |        60d09a1--cd8451c--      |
 |                                    origin/feature/...     |    |          4a03014  feature/...  |
 |   .git/rebase-merge/   1 done, 2 to do                    |    |                                |
 +-----------------------------------------------------------+    +--------------------------------+
```

The lower line in the clone equals the server. The upper line exists only in the clone, and only HEAD names it.

**[ON SCREEN]** The root-cause box of section 29.3, shown after the test.

```text
Observed behavior : git push prints "Everything up-to-date"; two commits are missing from the pull request.
Git state         : HEAD is detached at 075407e. .git/rebase-merge exists: 1 of 3 picks done.
                    refs/heads/feature/latency-budget = origin/feature/latency-budget = 4a03014.
Mechanism         : git rebase detaches HEAD, replays commits on it, and moves the branch ref only
                    when the last pick succeeds. The rebase stopped at a conflict. The conflict was
                    resolved with git commit, and git rebase --continue was never run. Later
                    commits extended the detached HEAD. git push <remote> <branch> sends the ref,
                    and the ref had not moved.
Root cause        : An unfinished rebase. The developer worked for days inside it.
Why Git does this : Moving the branch only at the end is what makes git rebase --abort possible:
                    the original branch stays intact until the whole replay has succeeded.
Correct fix       : Anchor the detached commits, abort the rebase, add the two new commits to the
                    published branch, push. Nothing published is rewritten.
Prevention        : Read the first line of git status before committing and before pushing.
                    Show the Git state in the shell prompt.
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch29/case-unfinished-rebase`. The repository is `scoring-api`, a service that scores feature vectors with a ranking model. A bare repository on disk plays the server. Everything until the marked point is 🟢 SAFE: read-only.

**The symptom.**

```bash
git push origin feature/latency-budget
```

<!-- snippet: ch29/case-unfinished-rebase/01-symptom -->
```text
$ git push origin feature/latency-budget
Everything up-to-date
```
<!-- /snippet -->

"Everything up-to-date": the local and the server's `feature/latency-budget` name the same commit. It says nothing about where the two new commits are.

**Command 1: `git status`.** Look at the first line before anything else. It names the current branch, or says that HEAD is detached, meaning it holds a commit ID instead of a branch name, or names an operation in progress. Predict the first line. Say it out loud.

**[PAUSE]**

<!-- snippet: ch29/case-unfinished-rebase/02-status -->
```text
$ git status
interactive rebase in progress; onto 4b30d7e
Last command done (1 command done):
   pick 60d09a1 # Add latency budget to config
Next commands to do (2 remaining commands):
   pick cd8451c # Enforce latency budget in scorer
   pick 4a03014 # Document latency budget
  (use "git rebase --edit-todo" to view and edit)
You are currently editing a commit while rebasing branch 'feature/latency-budget' on '4b30d7e'.
  (use "git commit --amend" to amend the current commit)
  (use "git rebase --continue" once you are satisfied with your changes)

nothing to commit, working tree clean
```
<!-- /snippet -->

The first line isn't "On branch". A rebase of `feature/latency-budget` onto `4b30d7e` was started and never finished: one command done, two remaining. The working tree is clean, so nothing uncommitted is at stake.

**Command 2: `git branch -vv`.** Look for the star, for the upstream in brackets, and for `ahead`, `behind` and `gone`. The upstream is the server branch that a local branch is compared with.

<!-- snippet: ch29/case-unfinished-rebase/03-branch -->
```text
$ git branch -vv
* (no branch, rebasing feature/latency-budget) 075407e Log budget violations
  feature/latency-budget                       4a03014 [origin/feature/latency-budget] Document latency budget
  main                                         4b30d7e [origin/main] Raise worker count to 8
```
<!-- /snippet -->

The star is on "no branch, rebasing". The branch `feature/latency-budget` still points at `4a03014`, with no `ahead`: it equals its upstream. HEAD is on `075407e`, a commit that no branch names.

**Command 3: `git remote -v`.** A remote is a name for another repository. Look for more than one remote, and for fetch and push URLs that differ.

<!-- snippet: ch29/case-unfinished-rebase/04-remote -->
```text
$ git remote -v
origin	../server.git (fetch)
origin	../server.git (push)
```
<!-- /snippet -->

One remote, one URL. That rules out a push to another repository.

**Command 4: the graph.** Look for where each name sits, and for commits with no name beside them.

```bash
git log --graph --decorate --oneline --all
```

<!-- snippet: ch29/case-unfinished-rebase/05-log -->
```text
$ git log --graph --decorate --oneline --all
* 075407e (HEAD) Log budget violations
* 96a7b55 Add p95 latency metric
* 9fbe4d7 Add latency budget to config
* 4b30d7e (origin/main, main) Raise worker count to 8
| * 4a03014 (origin/feature/latency-budget, feature/latency-budget) Document latency budget
| * cd8451c Enforce latency budget in scorer
| * 60d09a1 Add latency budget to config
|/  
* 8bd6e7d Add request schema
* 05ba901 Add scoring service skeleton
```
<!-- /snippet -->

Two lines of history leave `8bd6e7d`. The lower one is the published branch, ending at `4a03014`.

**[ANIMATION]** graph: 05ba901-8bd6e7d-4b30d7e-9fbe4d7-96a7b55-075407e; 4b30d7e main origin/main; 8bd6e7d-60d09a1-cd8451c-4a03014 feature/latency-budget origin/feature/latency-budget; HEAD=075407e title=The_clone,_before_any_change

The upper one starts at `4b30d7e` on `main` and holds a second "Add latency budget to config", followed by the two commits the developer is looking for. Only `HEAD` decorates it.

**Command 5: `git reflog`.** Read it from the bottom up: it's the sequence of events.

<!-- snippet: ch29/case-unfinished-rebase/06-reflog -->
```text
$ git reflog
075407e HEAD@{0}: commit: Log budget violations
96a7b55 HEAD@{1}: commit: Add p95 latency metric
9fbe4d7 HEAD@{2}: commit: Add latency budget to config
4b30d7e HEAD@{3}: rebase (start): checkout main
4a03014 HEAD@{4}: checkout: moving from main to feature/latency-budget
4b30d7e HEAD@{5}: commit: Raise worker count to 8
8bd6e7d HEAD@{6}: checkout: moving from feature/latency-budget to main
4a03014 HEAD@{7}: commit: Document latency budget
cd8451c HEAD@{8}: commit: Enforce latency budget in scorer
60d09a1 HEAD@{9}: commit: Add latency budget to config
8bd6e7d HEAD@{10}: checkout: moving from main to feature/latency-budget
8bd6e7d HEAD@{11}: commit: Add request schema
05ba901 HEAD@{12}: commit (initial): Add scoring service skeleton
```
<!-- /snippet -->

`HEAD@{3}` is "rebase (start): checkout main". There's no "rebase (finish)" line above it. The three entries above the start are plain `commit` entries: one for the conflict resolution, two for new work.

**Command 6: `git rev-parse`.** Turn names into exact IDs, and ask whether HEAD is a branch.

```bash
git rev-parse HEAD feature/latency-budget origin/feature/latency-budget
git rev-parse --abbrev-ref HEAD
git symbolic-ref HEAD
```

<!-- snippet: ch29/case-unfinished-rebase/07-rev-parse -->
```text
$ git rev-parse HEAD feature/latency-budget origin/feature/latency-budget
075407e71d9b34006eccefd0d2072bfb51d2850b
4a030148e74b6b4394d1056737434790a34ae612
4a030148e74b6b4394d1056737434790a34ae612
$ git rev-parse --abbrev-ref HEAD
HEAD
$ git symbolic-ref HEAD
fatal: ref HEAD is not a symbolic ref
[exit status: 128]
```
<!-- /snippet -->

The local branch and its remote-tracking branch are the same object, which is why the push had nothing to send. `git symbolic-ref HEAD` fails: HEAD holds a commit ID, not the name of a branch.

**Command 7: `git show --stat HEAD`.** Is this the commit the reporter means?

<!-- snippet: ch29/case-unfinished-rebase/08-show -->
```text
$ git show --stat HEAD
commit 075407e71d9b34006eccefd0d2072bfb51d2850b
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:21:00 2026 +0530

    Log budget violations

 app/audit.py | 7 +++++++
 1 file changed, 7 insertions(+)
```
<!-- /snippet -->

**Commands 8 and 9: `git diff` and `git diff --cached`.** Look for work that exists in no commit. It's the work that a wrong fix destroys without a trace.

<!-- snippet: ch29/case-unfinished-rebase/09-diff -->
```text
$ git diff
$ git diff --cached
```
<!-- /snippet -->

Both empty. Everything of value here is committed. Remember this output: one later step is allowed only because of it.

**Command 10: the configuration, with origin and scope.** Look for the `branch.<name>.remote` and `branch.<name>.merge` pairs, and for `pull`, `push` and `rebase` settings.

<!-- snippet: ch29/case-unfinished-rebase/10-config -->
```text
$ git config list --show-origin --show-scope
global	file:$LAB/ch29/case-unfinished-rebase/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch29/case-unfinished-rebase/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch29/case-unfinished-rebase/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch29/case-unfinished-rebase/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch29/case-unfinished-rebase/home/.gitconfig	gc.reflogexpireunreachable=never
local	file:.git/config	core.repositoryformatversion=0
local	file:.git/config	core.filemode=true
local	file:.git/config	core.bare=false
local	file:.git/config	core.logallrefupdates=true
local	file:.git/config	core.ignorecase=true
local	file:.git/config	core.precomposeunicode=true
local	file:.git/config	remote.origin.url=../server.git
local	file:.git/config	remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
local	file:.git/config	branch.main.remote=origin
local	file:.git/config	branch.main.merge=refs/heads/main
local	file:.git/config	branch.feature/latency-budget.remote=origin
local	file:.git/config	branch.feature/latency-budget.merge=refs/heads/feature/latency-budget
```
<!-- /snippet -->

The upstream of `feature/latency-budget` is the branch of the same name on `origin`. No setting changes the behavior of push or rebase. The two `gc.reflog` lines are the lab configuration.

**And `git ls-files`.** Are the files the reporter talks about tracked at the current commit?

<!-- snippet: ch29/case-unfinished-rebase/11-ls-files -->
```text
$ git ls-files
README.md
app/audit.py
app/metrics.py
app/schema.py
app/score.py
config/service.yaml
```
<!-- /snippet -->

`app/metrics.py` and `app/audit.py`, the files of the two new commits, are in the index. The work exists. Show the state diagram now.

**The state files.** A rebase keeps its state in a directory.

```bash
cat .git/HEAD
ls .git/rebase-merge
cat .git/rebase-merge/head-name
cat .git/rebase-merge/orig-head
cat .git/rebase-merge/onto
cat .git/rebase-merge/done
cat .git/rebase-merge/git-rebase-todo
```

<!-- snippet: ch29/case-unfinished-rebase/12-state-files -->
```text
$ cat .git/HEAD
075407e71d9b34006eccefd0d2072bfb51d2850b
$ ls .git/rebase-merge
author-script
done
drop_redundant_commits
end
git-rebase-todo
git-rebase-todo.backup
head-name
interactive
message
msgnum
no-reschedule-failed-exec
onto
orig-head
patch
stopped-sha
$ cat .git/rebase-merge/head-name
refs/heads/feature/latency-budget
$ cat .git/rebase-merge/orig-head
4a030148e74b6b4394d1056737434790a34ae612
$ cat .git/rebase-merge/onto
4b30d7e307a39954609eb40c2b4c2a1f63c74857
$ cat .git/rebase-merge/done
pick 60d09a1ac0fe504f55aaa293966229a4a3ea7d44 # Add latency budget to config
$ cat .git/rebase-merge/git-rebase-todo
pick cd8451cbbf3435915b50dd0e6db7a492777fbdd9 # Enforce latency budget in scorer
pick 4a030148e74b6b4394d1056737434790a34ae612 # Document latency budget
```
<!-- /snippet -->

`head-name` is the branch that will be moved when the rebase ends. `orig-head` is where it was when the rebase began. `onto` is the new base. `done` and `git-rebase-todo` are the two halves of the plan.

Stop the video here. You have the symptom and every piece of evidence. Write three hypotheses, each as a mechanism plus a prediction, and for each the one read-only command whose output would confirm or reject it. Don't continue until you have three on paper.

**[PAUSE]**

**The test.** The textbook's four hypotheses. One: the commits were made on another branch. Two: a rebase stopped and the commits were made on the detached HEAD. Three: the commits were pushed and the pull request page is stale. Four: the push went to another repository.

```bash
git log --oneline feature/latency-budget..HEAD
git ls-remote origin
git branch -a --contains HEAD
```

<!-- snippet: ch29/case-unfinished-rebase/13-test -->
```text
# H2: which commits does HEAD have that the branch does not?
$ git log --oneline feature/latency-budget..HEAD
075407e Log budget violations
96a7b55 Add p95 latency metric
9fbe4d7 Add latency budget to config
4b30d7e Raise worker count to 8
# H4: what does the server hold?
$ git ls-remote origin
4b30d7e307a39954609eb40c2b4c2a1f63c74857	HEAD
4a030148e74b6b4394d1056737434790a34ae612	refs/heads/feature/latency-budget
4b30d7e307a39954609eb40c2b4c2a1f63c74857	refs/heads/main
# Where is each new commit reachable from?
$ git branch -a --contains HEAD
* (no branch, rebasing feature/latency-budget)
```
<!-- /snippet -->

The first command lists what HEAD has that the branch doesn't: the two missing commits, the conflict resolution, and the commit of `main`. The server holds `4a03014` for the branch, so nothing newer was pushed. And `--contains HEAD` lists only the detached HEAD: no other branch has the commits. One hypothesis is confirmed and three are rejected. Show the root-cause box. The layer is Git. GitHub displayed the branch it was given. And there are the two commits from the opening: on a detached HEAD, where no branch names them.

**Preserve.** Before any change, give the unnamed commits a name. 🟢 SAFE: `git branch` adds one ref and touches nothing else.

```bash
git branch rescue/latency-wip HEAD
git log --oneline -4 rescue/latency-wip
```

<!-- snippet: ch29/case-unfinished-rebase/14-preserve -->
```text
$ git branch rescue/latency-wip HEAD
$ git log --oneline -4 rescue/latency-wip
075407e Log budget violations
96a7b55 Add p95 latency metric
9fbe4d7 Add latency budget to config
4b30d7e Raise worker count to 8
```
<!-- /snippet -->

**Select the lowest-risk fix.**

**[ON SCREEN]** The options table.

| Option | What it changes | Risk | Verdict |
|---|---|---|---|
| A. `git rebase --continue`, then `git push --force-with-lease` | Finishes the replay: the branch gets six new commit IDs on top of `main` | 🟡 then 🔴: rewrites a published branch with an open pull request; review comments become outdated; two more picks may conflict | Rejected for now. It is a valid choice only if the team rebases pull request branches, and then as a separate, announced step |
| B. `git rebase --abort` and nothing else | Returns HEAD and the branch to `4a03014` | 🔴 for the new work: the three commits lose their only anchor and live in the reflog alone | Rejected |
| C. Anchor, abort, `git cherry-pick` the two new commits, push | Two new commits on top of the published branch | 🟡: only adds; the push is a fast-forward | Chosen |

Option C doesn't bring `main` into the branch. That's a separate decision, and `rescue/latency-wip` keeps the conflict resolution for it.

**Execute, one change at a time.** 🟡 CAUTION: `git rebase --abort` resets the index and the working tree to the original branch tip, so it's run only because outputs 8 and 9 were empty.

```bash
git rebase --abort
git status
git log --oneline -3
```

<!-- snippet: ch29/case-unfinished-rebase/15-abort -->
```text
$ git rebase --abort
$ git status
On branch feature/latency-budget
Your branch is up to date with 'origin/feature/latency-budget'.

nothing to commit, working tree clean
$ git log --oneline -3
4a03014 Document latency budget
cd8451c Enforce latency budget in scorer
60d09a1 Add latency budget to config
```
<!-- /snippet -->

"On branch" again. 🟡 CAUTION: `git cherry-pick` adds commits to the current branch.

```bash
git cherry-pick rescue/latency-wip~1 rescue/latency-wip
git log --oneline origin/feature/latency-budget..HEAD
```

<!-- snippet: ch29/case-unfinished-rebase/16-pick -->
```text
$ git cherry-pick rescue/latency-wip~1 rescue/latency-wip
[feature/latency-budget c54eb8c] Add p95 latency metric
 Date: Mon Sep 7 10:20:00 2026 +0530
 1 file changed, 3 insertions(+)
 create mode 100644 app/metrics.py
[feature/latency-budget 30e8fe4] Log budget violations
 Date: Mon Sep 7 10:21:00 2026 +0530
 1 file changed, 7 insertions(+)
 create mode 100644 app/audit.py
$ git log --oneline origin/feature/latency-budget..HEAD
30e8fe4 Log budget violations
c54eb8c Add p95 latency metric
```
<!-- /snippet -->

**[ANIMATION]** graph: 05ba901-8bd6e7d-4b30d7e-9fbe4d7-96a7b55-075407e rescue/latency-wip; 4b30d7e main origin/main; 8bd6e7d-60d09a1-cd8451c-4a03014 feature/latency-budget origin/feature/latency-budget; HEAD=feature/latency-budget => 05ba901-8bd6e7d-4b30d7e-9fbe4d7-96a7b55-075407e rescue/latency-wip; 4b30d7e main origin/main; 8bd6e7d-60d09a1-cd8451c-4a03014-c54eb8c-30e8fe4 feature/latency-budget; 4a03014 origin/feature/latency-budget; HEAD=feature/latency-budget title=Two_picks,_two_new_IDs

The picks created `c54eb8c` and `30e8fe4`: the same changes as `96a7b55` and `075407e` with a different parent, and therefore different IDs.

**[ANIMATION]** end

Preview the push, then push. Quick quiz: what will the preview line look like for a fast-forward, where the server's branch only moves ahead? A, two dots between the IDs. B, a plus sign and three dots. Your answer?

**[PAUSE]**

```bash
git push --dry-run origin feature/latency-budget
git push origin feature/latency-budget
```

<!-- snippet: ch29/case-unfinished-rebase/17-push -->
```text
$ git push --dry-run origin feature/latency-budget
To ../server.git
   4a03014..30e8fe4  feature/latency-budget -> feature/latency-budget
$ git push origin feature/latency-budget
To ../server.git
   4a03014..30e8fe4  feature/latency-budget -> feature/latency-budget
```
<!-- /snippet -->

A. Two dots: a fast-forward. A forced update would print a plus sign and three dots.

**Verify.** Run the commands that showed the problem and check that each output changed for the predicted reason.

<!-- snippet: ch29/case-unfinished-rebase/18-verify -->
```text
$ git status
On branch feature/latency-budget
Your branch is up to date with 'origin/feature/latency-budget'.

nothing to commit, working tree clean
$ git rev-parse HEAD origin/feature/latency-budget
30e8fe42deeb7bc3f85ed0183c53b888716f22a6
30e8fe42deeb7bc3f85ed0183c53b888716f22a6
$ git ls-remote origin feature/latency-budget
30e8fe42deeb7bc3f85ed0183c53b888716f22a6	refs/heads/feature/latency-budget
$ git cherry -v HEAD rescue/latency-wip
+ 4b30d7e307a39954609eb40c2b4c2a1f63c74857 Raise worker count to 8
+ 9fbe4d7d5ad2de0af7c53ab650f5128730a19457 Add latency budget to config
- 96a7b550d08f1c63c7d6f57c14c2463a471a390e Add p95 latency metric
- 075407e71d9b34006eccefd0d2072bfb51d2850b Log budget violations
$ ls .git | grep -c rebase
0
```
<!-- /snippet -->

The first line of `git status` is "On branch". HEAD, the remote-tracking branch and the server agree on `30e8fe4`. `git cherry -v` compares by patch, that is, by the change and not by the ID. The minus sign marks the two rescued commits as present on the branch in equivalent form. The plus sign marks the commit of `main` and the conflict resolution `9fbe4d7`, which were deliberately left out. No rebase directory remains.

**Prevent.** Make a stopped operation visible where people look. Git ships a prompt script, `git-prompt.sh`, whose `__git_ps1` function prints the branch and the operation in progress. The habit that needs no tool: the first line of `git status` before every commit and every push.

Try it now. Thirty seconds. In the lab shell, or in any repository you have, run `git status`, which only reads, and say its first line out loud.

**[PAUSE]**

That line named your branch, or said that HEAD is detached, or named an operation in progress. Whichever it was, you knew it before you typed anything else. That's the whole habit.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Acting on the reporter's interpretation.** Root cause: "I added two commits to my branch" is a belief about the state, and the state is what has not been established.
2. **Reading "Everything up-to-date" as "my work is on the server".** Root cause: the message compares one local ref with one server ref and says nothing about commits that no ref names.
3. **Testing the first hypothesis that comes to mind.** Root cause: with one hypothesis you look for confirmation; only several hypotheses make you look for the output that separates them.
4. **Aborting the rebase first.** Root cause: the abort returns HEAD to the original branch tip, and the commits made on the detached HEAD lose their only anchor.
5. **Finishing the rebase and force-pushing because it is the "natural" continuation.** Root cause: it rewrites a published branch with an open pull request when a fix that only adds commits was available.

## PRODUCTION EXAMPLE

Now, out of the lab. An engineer on a ranking team asks for help on Friday afternoon: the latency work she did this week isn't on her pull request, and the release is cut on Monday. The colleague she asks doesn't touch her keyboard for the first ten minutes. He asks for the exact message, the last commands she remembers, and whether she has tried anything since. She hasn't.

He runs the ten commands and reads the first line of `git status` aloud: a rebase in progress, started on Monday. She remembers the conflict. She had fixed it, committed, and gone on working. He writes down four hypotheses in the incident channel with the command for each, runs three commands, and names the root cause with its layer: Git, an unfinished rebase. GitHub showed what it was given.

Then one branch to anchor the work, the abort, two cherry-picks, a dry-run push, the push, and the same commands again to verify. The pull request shows the two commits. The message he posts afterwards has four lines: what happened, how he knows, what the fix changed, and what the team adds: the shell prompt that shows an operation in progress.

## PRACTICE EXERCISE

Your turn. Do Lab 35.1, "The ten-command diagnosis on three repositories", in [`lab-manual/m35-diagnosis-method.md`](../../lab-manual/m35-diagnosis-method.md). Start with the first repository.

For each repository, write the symptom without interpretation before you run anything. After the ten commands, and before any test, write three hypotheses and the read-only command for each. Run no state-changing command until you have named the root cause and its layer. The lab's questions are answered in a separate file. Attempt them first.

The challenge is Incident 10, [`incidents/10-commit-local-not-remote`](../../incidents/10-commit-local-not-remote/SYMPTOMS.md). Generate it, read only its symptoms, and don't read its generator.

## INTERVIEW QUESTION

**[ON SCREEN]** Q465: "In the root-cause framework every step up to and including naming the root cause is read-only. Why is that rule there, and what is the one kind of change that is allowed before the fix?"

**[PAUSE]**

Answer out loud. A strong answer gives the reason as a mechanism, not as caution in general: say what a repository in an unknown state may contain that exists nowhere else, and which ordinary commands would remove it. It supports the rule with the observation about when damage is done. For the second half, it names the kind of change by its property, what it adds and what it can't remove, and gives examples at more than one weight. If you can add one diagnostic command that's commonly used and isn't strictly read-only, and say why it's still acceptable, you have shown that you know the rule's edge.

## RECAP

Let's land this.

- Diagnosis is a read-only search for the one fact about the state that explains the symptom, followed by the smallest change that repairs it.
- The method has three phases with different permissions: read-only, preserve, change.
- A symptom is restated without the reporter's interpretation, and the layer is named with the root cause.
- At least three hypotheses are written before any is tested, each with the command that separates it from the others.
- "Everything up-to-date" is a statement about one ref; during a rebase HEAD is detached and the branch moves only at the end.

## HOMEWORK

Read sections 29.1 to 29.3. Then read [`playbooks/troubleshooting-playbook.md`](../../playbooks/troubleshooting-playbook.md), the field version of the method. In the next video the developer's own explanation is plausible and wrong: a push that stays rejected after a pull that says "Already up to date".

Today you took one sentence from a colleague to a named root cause, and changed nothing until you understood the state. Practise that on the lab's three repositories. Until then, look at the state first and type second. See you in the next one.
