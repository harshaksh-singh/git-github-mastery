# Chapter 29: Production Troubleshooting

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch29/`.

## 29.1 Why this matters

A CTO does not ask "which command fixes this". The questions are: what happened, how do you know, what will the fix change, and how do we stop it from happening again. Every earlier chapter gave you one mechanism. This chapter is the method that selects the right one when all you have is a sentence from a colleague: "my commits are gone", "the push is rejected".

Three facts shape the method.

1. **Most damage is done after the incident, by the first repair attempt.** The original problem in a Git repository is rarely destructive: Git keeps unreachable commits for weeks ([Chapter 13](ch13-recovery.md), section 13.4). The second command, typed before the state was understood, is what removes the uncommitted change or rewrites the published branch.
2. **A symptom names no layer.** "CI is red" may be a Git fact (the commit lacks a file), a GitHub fact (the check ran on the merge ref) or a GitHub Actions fact (the runner image changed). Evidence decides, not the wording of the complaint.
3. **Experience does not protect you.** In 2020, 40.0% of the people asking Git-command questions on Stack Exchange had been registered for more than five years, against 21.2% of all askers ([author preprint](https://cs.nju.edu.cn/changxu/1_publications/22/TOSEM22.pdf)). A fixed procedure is what replaces confidence.

This chapter does not repeat the mechanisms. It applies the root-cause framework of [Chapter 1](ch01-fundamentals.md), section 1.10 to two new cases, reads interrupted operations from `git status` and `.git`, preserves evidence, lists what GitHub records, and ends with a symptom catalog that points to the chapter of each mechanism. The field version is the [troubleshooting playbook](../playbooks/troubleshooting-playbook.md).

## 29.2 The method

**In one sentence.** Diagnosis is a read-only search for the one fact about the state that explains the symptom, followed by the smallest change that repairs that fact.

**Analogy.** An accident investigator secures the site, records everything, reconstructs the sequence, and only then states a cause. The analogy breaks in one useful way: a repository can be copied in seconds, so you can rehearse the repair on the copy.

**Precisely.** The eleven steps of section 1.10 fall into three phases with different permissions.

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

Phase 1 uses only 🟢 commands. Phase 2 adds refs and files and removes nothing. Phase 3 is the first moment a ref moves or a file is overwritten.

"Understand state" means being able to fill in this table for the repository in front of you. Each cell has a command that answers it.

| Place | Question | Command |
|---|---|---|
| Working tree | Which files differ from the index? Which are untracked or ignored? | `git status`, `git diff`, `git status --ignored` |
| Index | What would the next commit record? Are there conflict stages? | `git diff --cached`, `git ls-files -s`, `git ls-files -u` |
| HEAD | A branch, or a raw commit ID? Is an operation in progress? | `git status`, `cat .git/HEAD`, `git symbolic-ref HEAD` |
| Refs | Where does each branch, tag and remote-tracking branch point, and what is each upstream? | `git branch -vv`, `git for-each-ref` |
| History of the refs | How did they get there? | `git reflog`, `git reflog show <branch>` |
| The server | What does it hold now, as opposed to at the last fetch? | `git ls-remote origin` |
| GitHub | What did the platform record: pushes, rule evaluations, checks? | Section 29.8 |

A hypothesis is a mechanism plus a prediction: "if the branch was reset, the branch reflog has a `reset: moving to` entry". Write at least three before testing any. With one hypothesis you look for confirmation; with three you look for the command whose output separates them.

**In production.** Ask the reporter for the exact text on the screen, the last three commands they remember, and whether anything was done since. The scrollback often contains the commit ID you will need ([Chapter 13](ch13-recovery.md), section 13.7).

## 29.3 Worked case 1: the push that had nothing to push

The repository is `scoring-api`, a service that scores feature vectors with a ranking model. A bare repository on disk plays the server. The script is `labs/ch29/case-unfinished-rebase.sh`.

**SYMPTOM.** A developer reports: "I added two commits to my pull request branch `feature/latency-budget` this week. The pull request does not show them. I pushed again and Git says there is nothing to push."

<!-- snippet: ch29/case-unfinished-rebase/01-symptom -->
```text
$ git push origin feature/latency-budget
Everything up-to-date
```
<!-- /snippet -->

"Everything up-to-date" is a statement about one ref: the local and the server's `feature/latency-budget` name the same commit. It says nothing about where the two new commits are.

**OBSERVE and COLLECT EVIDENCE.** The ten commands, in order. For each: what it reveals, and what to look for.

**1. `git status`.** Look at the first line before anything else. It names the current branch, or says that HEAD is detached, or names an operation in progress.

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

The first line is not "On branch". A rebase of `feature/latency-budget` onto `4b30d7e` was started and never finished: one command done, two remaining. The working tree is clean, so nothing uncommitted is at stake.

**2. `git branch -vv`.** Look for the star, for the upstream in brackets, and for `ahead`, `behind` and `gone`.

<!-- snippet: ch29/case-unfinished-rebase/03-branch -->
```text
$ git branch -vv
* (no branch, rebasing feature/latency-budget) 075407e Log budget violations
  feature/latency-budget                       4a03014 [origin/feature/latency-budget] Document latency budget
  main                                         4b30d7e [origin/main] Raise worker count to 8
```
<!-- /snippet -->

The star is on `(no branch, rebasing feature/latency-budget)`. The branch `feature/latency-budget` still points at `4a03014`, with no `ahead`: it equals its upstream. HEAD is on `075407e`, a commit that no branch names.

**3. `git remote -v`.** Look for more than one remote, and for fetch and push URLs that differ.

<!-- snippet: ch29/case-unfinished-rebase/04-remote -->
```text
$ git remote -v
origin	../server.git (fetch)
origin	../server.git (push)
```
<!-- /snippet -->

One remote, one URL.

**4. `git log --graph --decorate --oneline --all`.** Look for where each name sits, and for commits with no name beside them.

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

Two lines of history leave `8bd6e7d`. The lower one is the published branch, ending at `4a03014`. The upper one starts at `4b30d7e` on `main` and holds a second "Add latency budget to config" followed by the two commits the developer is looking for. Only `HEAD` decorates it.

**5. `git reflog`.** Read it from the bottom up: it is the sequence of events. Look for `rebase`, `reset`, `checkout` and `commit (amend)` entries.

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

`HEAD@{3}` is `rebase (start): checkout main`. There is no `rebase (finish)` line above it. The three entries above the start are plain `commit` entries: one for the conflict resolution, two for new work.

**6. `git rev-parse`.** Use it to turn the names of the previous outputs into exact IDs, and to ask whether HEAD is a branch.

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

The local branch and its remote-tracking branch are the same object, which is why the push had nothing to send. `--abbrev-ref HEAD` prints `HEAD`, and `git symbolic-ref HEAD` fails: HEAD holds a commit ID, not the name of a branch.

**7. `git show --stat HEAD`.** Look at the author, the date and the list of files: is this the commit the reporter means?

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

**8 and 9. `git diff` and `git diff --cached`.** Look for work that exists in no commit. It is the work that a wrong fix destroys without a trace.

<!-- snippet: ch29/case-unfinished-rebase/09-diff -->
```text
$ git diff
$ git diff --cached
```
<!-- /snippet -->

Both are empty. Everything of value here is committed.

**10. `git config list --show-origin --show-scope`.** Look for the `branch.<name>.remote` and `branch.<name>.merge` pairs, for `pull.*`, `push.*` and `rebase.*` settings, and for the scope each one comes from.

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

The upstream of `feature/latency-budget` is the branch of the same name on `origin`. No setting changes the behavior of push or rebase.

**11. `git ls-files`.** Look for the files the reporter talks about: are they tracked at the current commit?

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

`app/metrics.py` and `app/audit.py`, the files of the two new commits, are in the index. The work exists.

**UNDERSTAND STATE.**

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

**FORM HYPOTHESES and TEST HYPOTHESES.**

| Hypothesis | Evidence that would confirm it | Result |
|---|---|---|
| H1: the commits were made on another branch | `git branch -a --contains HEAD` lists a branch | Rejected: it lists only the detached HEAD |
| H2: a rebase stopped; HEAD is detached; the commits were made on the detached HEAD; the branch ref does not move until the rebase finishes | `.git/rebase-merge/` exists and names the branch; the commits are in `feature/latency-budget..HEAD` | Confirmed |
| H3: the commits were pushed and the pull request page is stale | `git ls-remote` shows a newer ID than the local branch | Rejected: the server holds `4a03014` |
| H4: the push went to another repository | A second remote, or a push URL that differs | Rejected by output 3 |

A rebase keeps its state in a directory, and the directory answers H2 without interpretation:

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

`head-name` is the branch that will be moved when the rebase ends, `orig-head` is where it was when the rebase began, `onto` is the new base, `done` and `git-rebase-todo` are the two halves of the plan. The branch ref is updated in one step at the end ([Chapter 9](ch09-rebase.md), section 9.4).

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

**IDENTIFY ROOT CAUSE.**

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

The layer is Git. GitHub displayed the branch it was given.

**PRESERVE.** Before any change, give the unnamed commits a name. `git branch` 🟢 adds one ref and touches nothing else; section 29.7 adds the heavier layers.

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

**SELECT LOWEST-RISK FIX.**

| Option | What it changes | Risk | Verdict |
|---|---|---|---|
| A. `git rebase --continue`, then `git push --force-with-lease` | Finishes the replay: the branch gets six new commit IDs on top of `main` | 🟡 then 🔴: rewrites a published branch with an open pull request; review comments become outdated ([Chapter 17](ch17-pull-requests.md), section 17.12); two more picks may conflict | Rejected for now. It is a valid choice only if the team rebases pull request branches, and then as a separate, announced step |
| B. `git rebase --abort` and nothing else | Returns HEAD and the branch to `4a03014` | 🔴 for the new work: the three commits lose their only anchor and live in the reflog alone | Rejected |
| C. Anchor, abort, `git cherry-pick` the two new commits, push | Two new commits on top of the published branch | 🟡: only adds; the push is a fast-forward | Chosen |

Option C does not bring `main` into the branch. That is a separate decision ([Chapter 9](ch09-rebase.md), section 9.18); `rescue/latency-wip` keeps the conflict resolution for it.

**EXECUTE.** One change at a time. `git rebase --abort` 🟡 resets the index and the working tree to the original branch tip, so it is run only because outputs 8 and 9 were empty.

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

`git cherry-pick` 🟡 created `c54eb8c` and `30e8fe4`: the same changes as `96a7b55` and `075407e` with a different parent, and therefore different IDs ([Chapter 10](ch10-cherry-pick.md), section 10.3). Preview the push, then push:

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

`4a03014..30e8fe4` with two dots is a fast-forward. A forced update would print a plus sign and three dots.

**VERIFY.** Run the commands that showed the problem and check that each output changed for the predicted reason.

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

The first line of `git status` is "On branch". HEAD, the remote-tracking branch and the server agree on `30e8fe4`. `git cherry -v HEAD rescue/latency-wip` compares by patch: the minus sign marks the two rescued commits as present on the branch in equivalent form; the plus sign marks the commit of `main` and the conflict resolution `9fbe4d7`, which were deliberately left out. No rebase directory remains.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git rebase --abort` 🟡 | Reset to the original branch tip; uncommitted changes to tracked files are discarded | Reset | Re-attached to the branch named in `head-name` | Left at `orig-head` | `.git/rebase-merge/` removed; reflog entry `rebase (abort)` | unchanged | unchanged |
| `git cherry-pick <a> <b>` 🟡 | Updated | Updated | Moves with the branch | Advances by two new commits | Reflog entries; `CHERRY_PICK_HEAD` and `.git/sequencer/` during a conflict | unchanged | unchanged |

**PREVENT.** Make a stopped operation visible where people look. Git ships a prompt script, `git-prompt.sh`, whose `__git_ps1` function prints the branch and the operation in progress (for example `|REBASE 1/3`). On this Mac, Homebrew's Git installs it as `/opt/homebrew/etc/bash_completion.d/git-prompt.sh`. The habit that needs no tool: the first line of `git status` before every commit and every push.

## 29.4 Worked case 2: "I pulled, and the push is still rejected"

The repository is `embed-jobs`, a batch job that computes embeddings. The script is `labs/ch29/case-wrong-upstream.sh`. The case is shorter on purpose: once the ritual is a habit, you read the same outputs faster.

**SYMPTOM.** "My push is rejected. Git tells me to pull. I pull, Git says everything is up to date, and the push is rejected again."

<!-- snippet: ch29/case-wrong-upstream/01-symptom -->
```text
$ git push origin feature/batch-size
To ../server.git
 ! [rejected]        feature/batch-size -> feature/batch-size (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git pull
From ../server
 * [new branch]      feature/batch-size -> origin/feature/batch-size
Already up to date.
$ git push origin feature/batch-size
To ../server.git
 ! [rejected]        feature/batch-size -> feature/batch-size (non-fast-forward)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

The first rejection says `(fetch first)`: the server's branch has an object this clone has never seen. The pull prints `* [new branch] feature/batch-size -> origin/feature/batch-size`: this clone learns of the server's branch for the first time, and then says "Already up to date". The second rejection says `(non-fast-forward)`: now the clone has the server's commit and can see that the local branch does not contain it. The pull fetched the commit and did not integrate it.

**COLLECT EVIDENCE.**

<!-- snippet: ch29/case-wrong-upstream/02-evidence -->
```text
$ git status
On branch feature/batch-size
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
$ git branch -vv
* feature/batch-size 2defa92 [origin/main: ahead 2] Read batch size from the command line
  main               ce76024 [origin/main] Write vectors to the daily bucket
$ git log --graph --decorate --oneline --all
* 56bb8e4 (origin/feature/batch-size) Add batch_size to the job config
| * 2defa92 (HEAD -> feature/batch-size) Read batch size from the command line
| * 3d6663d Embed in batches
|/  
* ce76024 (origin/main, origin/HEAD, main) Write vectors to the daily bucket
* bafe874 Add embedding job
```
<!-- /snippet -->

<!-- snippet: ch29/case-wrong-upstream/03-evidence-config -->
```text
$ git config list --show-origin --show-scope | grep -E "(branch|remote)[.]"
local	file:.git/config	remote.origin.url=../server.git
local	file:.git/config	remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
local	file:.git/config	branch.main.remote=origin
local	file:.git/config	branch.main.merge=refs/heads/main
local	file:.git/config	branch.feature/batch-size.remote=origin
local	file:.git/config	branch.feature/batch-size.merge=refs/heads/main
$ git reflog -4
2defa92 HEAD@{0}: commit: Read batch size from the command line
3d6663d HEAD@{1}: commit: Embed in batches
ce76024 HEAD@{2}: checkout: moving from main to feature/batch-size
ce76024 HEAD@{3}: clone: from $LAB/ch29/case-wrong-upstream/server.git
```
<!-- /snippet -->

**UNDERSTAND STATE.** The status line compares the branch with `origin/main`, not with `origin/feature/batch-size`. `git branch -vv` shows the same in brackets. The configuration holds the cause in one line: `branch.feature/batch-size.merge=refs/heads/main`. The graph shows two lines of work leaving `ce76024`: two local commits, and one commit by a teammate on the server's branch of the same name.

```text
                 3d6663d---2defa92   feature/batch-size (HEAD)      upstream: origin/main
                /
  bafe874---ce76024   main, origin/main
                \
                 56bb8e4   origin/feature/batch-size                <- git push origin feature/batch-size goes here
```

**FORM HYPOTHESES and TEST HYPOTHESES.**

| Hypothesis | Evidence that would confirm it | Result |
|---|---|---|
| H1: the server's branch has a commit the local branch lacks, and `git pull` integrates a different branch | `HEAD..origin/feature/batch-size` is not empty; `branch.<name>.merge` names another branch | Confirmed |
| H2: a rule on the server rejects the push | The line would read `! [remote rejected]` with `remote:` lines ([Chapter 12](ch12-remote-operations.md), section 12.15) | Rejected: `! [rejected]` is written by the local Git before any rule is consulted |
| H3: someone rewrote the server's branch | The fetch would print `+ ... (forced update)`; the reflog of the remote-tracking branch would show the old tip | Rejected: one reflog entry, a first fetch |
| H4: the pull failed | An error from `git pull` | Rejected: it succeeded, on another branch |

<!-- snippet: ch29/case-wrong-upstream/08-test -->
```text
# H1: the server branch has a commit that the local branch lacks.
$ git log --oneline HEAD..origin/feature/batch-size
56bb8e4 Add batch_size to the job config
# H1: and git pull integrates another branch.
$ git config get branch.feature/batch-size.merge
refs/heads/main
# H3: was the server branch rewritten? Its remote-tracking reflog has one entry, a first fetch.
$ git reflog show origin/feature/batch-size
56bb8e4 refs/remotes/origin/feature/batch-size@{0}: pull: storing head
# Would the two lines of work conflict? A test merge that touches nothing:
$ git merge-tree --write-tree --name-only HEAD origin/feature/batch-size
e2386b3e50aabb629564655df6e66d79d2d11040
[exit status: 0]
```
<!-- /snippet -->

The last command is a test merge with `git merge-tree` 🟢 ([Chapter 8](ch08-merge.md), section 8.17). It writes a tree object and touches neither the index nor the working tree. Exit status 0 with no file names means the two lines of work combine without conflict.

**IDENTIFY ROOT CAUSE.**

```text
Observed behavior : push rejected; git pull says "Already up to date"; push rejected again.
Git state         : feature/batch-size is 2 ahead of origin/main and 2 ahead, 1 behind
                    origin/feature/batch-size. branch.feature/batch-size.merge = refs/heads/main.
Mechanism         : git switch -c <name> origin/main records origin/main as the upstream, because
                    the starting point is a remote-tracking branch (branch.autoSetupMerge=true).
                    git pull without arguments integrates the upstream. git push origin <name>
                    targets the server branch <name>. Pull and push address different branches.
Root cause        : The upstream of the local branch is not the branch it is pushed to.
Why Git does this : Tracking the starting point is right for a local copy of a remote branch
                    (git switch -c main origin/main). Git cannot know that this time the
                    starting point was meant only as a base.
Correct fix       : Point the upstream at origin/feature/batch-size, replay the two unpublished
                    commits on top of it, push. No force.
Prevention        : Create feature branches with --no-track, or from the local main. Read the
                    brackets in git branch -vv before the first push.
```

**SELECT LOWEST-RISK FIX.**

| Option | Risk | Verdict |
|---|---|---|
| `git push --force origin feature/batch-size` | 🔴 replaces the server's branch and discards the teammate's commit `56bb8e4` ([Chapter 12](ch12-remote-operations.md), section 12.8) | Rejected. A rejected push is information, not an obstacle |
| `git pull origin feature/batch-size` | 🟡 a one-off integration; stops with "Need to specify how to reconcile divergent branches" unless a mode is given; leaves the wrong upstream in place, so the problem returns | Rejected: treats the state, not the cause |
| Set the upstream, then `git rebase` onto it, then `git push` | 🟡 rewrites two commits that exist nowhere else; adds to the server's branch | Chosen |

Rebasing is acceptable here because the two commits are unpublished: no other repository has them ([Chapter 9](ch09-rebase.md), section 9.15).

**EXECUTE.** A backup ref first; then the configuration change; then the rebase. `git rebase` without arguments uses the upstream.

<!-- snippet: ch29/case-wrong-upstream/09-fix -->
```text
$ git branch backup/batch-size-before-rebase
$ git branch --set-upstream-to=origin/feature/batch-size
branch 'feature/batch-size' set up to track 'origin/feature/batch-size'.
$ git status -sb
## feature/batch-size...origin/feature/batch-size [ahead 2, behind 1]
$ git rebase
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/batch-size.
$ git log --graph --oneline -4
* aca1b2f Read batch size from the command line
* 097fe6f Embed in batches
* 56bb8e4 Add batch_size to the job config
* ce76024 Write vectors to the daily bucket
```
<!-- /snippet -->

After the upstream change, `git status -sb` already tells the truth: `[ahead 2, behind 1]`. No object moved; only the comparison did.

<!-- snippet: ch29/case-wrong-upstream/10-push -->
```text
$ git push --dry-run
To ../server.git
   56bb8e4..aca1b2f  feature/batch-size -> feature/batch-size
$ git push
To ../server.git
   56bb8e4..aca1b2f  feature/batch-size -> feature/batch-size
```
<!-- /snippet -->

**VERIFY.**

<!-- snippet: ch29/case-wrong-upstream/11-verify -->
```text
$ git status
On branch feature/batch-size
Your branch is up to date with 'origin/feature/batch-size'.

nothing to commit, working tree clean
$ git branch -vv
  backup/batch-size-before-rebase 2defa92 Read batch size from the command line
* feature/batch-size              aca1b2f [origin/feature/batch-size] Read batch size from the command line
  main                            ce76024 [origin/main] Write vectors to the daily bucket
$ git rev-parse HEAD @{upstream}
aca1b2fe23a5fed73fb916e3c34ed1ba7095dec0
aca1b2fe23a5fed73fb916e3c34ed1ba7095dec0
$ git ls-remote origin feature/batch-size
aca1b2fe23a5fed73fb916e3c34ed1ba7095dec0	refs/heads/feature/batch-size
$ git range-diff origin/main backup/batch-size-before-rebase HEAD
-:  ------- > 1:  56bb8e4 Add batch_size to the job config
1:  3d6663d = 2:  097fe6f Embed in batches
2:  2defa92 = 3:  aca1b2f Read batch size from the command line
$ git pull
Already up to date.
```
<!-- /snippet -->

The brackets name the right branch, HEAD equals the upstream and the server, and `git range-diff` ([Chapter 9](ch09-rebase.md), section 9.14) shows the two commits carried over unchanged (`=`) on top of one new commit. `git pull` says "Already up to date" again, this time about the branch you push to.

**PREVENT.**

<!-- snippet: ch29/case-wrong-upstream/12-prevent -->
```text
$ git branch -D backup/batch-size-before-rebase
Deleted branch backup/batch-size-before-rebase (was 2defa92).
# A new branch from origin/main that does not take origin/main as its upstream:
$ git switch -c feature/shard-output --no-track origin/main
Switched to a new branch 'feature/shard-output'
$ git branch -vv
  feature/batch-size   aca1b2f [origin/feature/batch-size] Read batch size from the command line
* feature/shard-output ce76024 Write vectors to the daily bucket
  main                 ce76024 [origin/main] Write vectors to the daily bucket
$ git push
fatal: The current branch feature/shard-output has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin feature/shard-output

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.

[exit status: 128]
```
<!-- /snippet -->

With `--no-track` the new branch has no upstream, and the first `git push` stops and asks; `push.autoSetupRemote=true` makes that push create the upstream under the branch's own name. The manual for Git 2.55 also documents `branch.autoSetupMerge=simple`: automatic setup "only when the starting point is a remote-tracking branch and the new branch has the same name as the remote branch".

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git rebase` (onto the upstream) 🟡 | Updated to the rebased tip | Updated | Detached during the replay, re-attached at the end | Set to the last replayed commit | `ORIG_HEAD` written; reflog entries; `.git/rebase-merge/` during the operation | unchanged | unchanged |

## 29.5 The extended toolbox

The ten commands are the fixed opening. The commands below are the ones you reach for when testing a hypothesis. All are 🟢. Each row names the question it answers and the chapter that teaches it.

| Question | Command | Chapter |
|---|---|---|
| Branch, upstream and counts in one line | `git status -sb` | [4](ch04-working-tree.md), 4.4 |
| Every ref with its upstream and distance | `git for-each-ref --format='%(refname) %(objectname:short) %(upstream:short) %(upstream:track)'` | [3](ch03-git-internals.md), 3.9 |
| What is my upstream; where would a push go | `git rev-parse --abbrev-ref @{upstream}`, `@{push}` | [12](ch12-remote-operations.md), 12.5 |
| How far apart are two commits | `git rev-list --left-right --count A...B` | [7](ch07-branches.md), 7.8 |
| Where two histories split | `git merge-base A B` | [8](ch08-merge.md), 8.2 |
| Which branches or tags contain a commit | `git branch -a --contains <id>`, `git tag --contains <id>` | [12](ch12-remote-operations.md), 12.14 |
| Is the same change present under another ID | `git cherry -v <upstream> <branch>`, `git range-diff` | [10](ch10-cherry-pick.md), 10.10; [9](ch09-rebase.md), 9.14 |
| What the server holds right now | `git ls-remote origin` | [12](ch12-remote-operations.md), 12.14 |
| When and how a ref moved | `git reflog show --date=iso <ref>` | [13](ch13-recovery.md), 13.3 |
| What the index holds, with stages | `git ls-files -s`, `git ls-files -u` | [5](ch05-index.md), 5.11, 5.13 |
| Why a path is ignored | `git check-ignore -v <path>`, `git status --ignored` | [4](ch04-working-tree.md), 4.5 |
| Where one setting comes from | `git config get --show-origin --show-scope --all <key>` | [14B](ch14b-config-tags-signing.md), 14B.3 |
| Would a merge conflict, without touching anything | `git merge-tree --write-tree --name-only A B` | [8](ch08-merge.md), 8.17 |
| Is the object store intact; what is unreachable | `git fsck`, `git fsck --lost-found` (the second writes files under `.git/lost-found/`) | [13](ch13-recovery.md), 13.6 |
| Stashes and other worktrees that hold work | `git stash list`, `git worktree list` | [11](ch11-reset-revert-restore.md), 11.11; [25](ch25-worktrees.md), 25.2 |
| What Git executes and sends | `GIT_TRACE=1`, `GIT_TRACE2_EVENT`, `GIT_CURL_VERBOSE=1`, `ssh -v` | [14B](ch14b-config-tags-signing.md), 14B.7; [16](ch16-authentication.md), 16.17 |

**See it.** Four of them on the repository of case 2, before the fix. The questions are "which refs exist and what do they follow" and "how do the two branches relate".

<!-- snippet: ch29/case-wrong-upstream/04-toolbox-refs -->
```text
$ git status -sb
## feature/batch-size...origin/main [ahead 2]
$ git for-each-ref --format='%(refname) %(objectname:short) %(upstream:short) %(upstream:track)'
refs/heads/feature/batch-size 2defa92 origin/main [ahead 2]
refs/heads/main ce76024 origin/main 
refs/remotes/origin/HEAD ce76024  
refs/remotes/origin/feature/batch-size 56bb8e4  
refs/remotes/origin/main ce76024  
$ git rev-parse --abbrev-ref @{upstream}
origin/main
$ git rev-parse --abbrev-ref @{push}
fatal: cannot resolve 'simple' push to a single destination
[exit status: 128]
```
<!-- /snippet -->

The `for-each-ref` line prints the whole ref table in a form that can be compared across machines. The last command fails, and the failure is evidence: with `push.default=simple`, a branch whose upstream has another name has no single push destination, so `@{push}` cannot be resolved. The same condition makes a bare `git push` stop with the message shown in [Chapter 12](ch12-remote-operations.md), section 12.5.

<!-- snippet: ch29/case-wrong-upstream/05-toolbox-graph -->
```text
$ git merge-base HEAD origin/feature/batch-size
ce760245c837e01a35b747b62b701ae9d5cb1593
$ git rev-list --left-right --count HEAD...origin/feature/batch-size
2	1
$ git log --oneline --left-right HEAD...origin/feature/batch-size
> 56bb8e4 Add batch_size to the job config
< 2defa92 Read batch size from the command line
< 3d6663d Embed in batches
$ git branch -a --contains origin/feature/batch-size
  remotes/origin/feature/batch-size
```
<!-- /snippet -->

`2	1` reads: two commits only on the left side (HEAD), one only on the right. `<` and `>` mark the sides commit by commit.

<!-- snippet: ch29/case-wrong-upstream/06-toolbox-remote -->
```text
$ git ls-remote origin
ce760245c837e01a35b747b62b701ae9d5cb1593	HEAD
56bb8e470535998cc128a14369042cc79c693292	refs/heads/feature/batch-size
ce760245c837e01a35b747b62b701ae9d5cb1593	refs/heads/main
$ git reflog show --date=iso origin/feature/batch-size
56bb8e4 refs/remotes/origin/feature/batch-size@{2026-09-07 10:18:00 +0530}: pull: storing head
$ git remote show origin
* remote origin
  Fetch URL: ../server.git
  Push  URL: ../server.git
  HEAD branch: main
  Remote branches:
    feature/batch-size tracked
    main               tracked
  Local branches configured for 'git pull':
    feature/batch-size merges with remote main
    main               merges with remote main
  Local refs configured for 'git push':
    feature/batch-size pushes to feature/batch-size (local out of date)
    main               pushes to main               (up to date)
```
<!-- /snippet -->

`git ls-remote` and `git remote show origin` contact the server; the other commands in this section answer from local data, which is as old as the last fetch. `git remote show origin` states the mismatch in words: the branch "merges with remote main" and "pushes to feature/batch-size (local out of date)".

> **Git, not GitHub.** `git fetch` is the one command of the opening that changes something: it moves remote-tracking refs and adds objects. It never touches your branches, index or working tree, and each remote-tracking ref has a reflog, so it is treated as part of evidence collection. Record `git rev-parse origin/main` first if the stale value is itself evidence, as it is after a suspected force push ([Chapter 13](ch13-recovery.md), section 13.10).

## 29.6 Operations in progress: what `git status` and `.git` tell you

**In one sentence.** Merge, rebase, cherry-pick, revert and bisect can stop half-way, and each leaves named files in `.git` that say which operation it is, where it started, and what remains.

**Analogy.** A surgeon's instrument count: the list on the wall says what is still inside. The analogy breaks because Git's list is also the undo record. The same files that describe the operation are what `--abort` reads to restore the starting point.

**Precisely.** Git has no process that "is" a rebase. An operation in progress is nothing but files: a pseudoref such as `MERGE_HEAD` that holds a commit ID, and for multi-step operations a directory with a todo list ([Chapter 3](ch03-git-internals.md), section 3.10). `git status` reads those files and prints its first lines from them. Three consequences follow. A stopped operation survives a reboot and can be weeks old. Deleting the files by hand ends the operation without undoing it. And you can diagnose a repository you were handed by listing `.git`.

**See it.** The script is `labs/ch29/ops-in-progress.sh`. It builds the same small repository six times, an output guard for an LLM service, and stops a different operation in five of them. A repository at rest first, as the reference:

<!-- snippet: ch29/ops-in-progress/01-clean -->
```text
$ cd clean
$ git log --graph --oneline --all
* 9f0e328 Add README
* 19b52fd Raise guard threshold to 0.65
| * 6f503d0 Lower max_tokens to 128
| * 7c39cc7 Add blocklist
| * 5c28c34 Raise guard threshold to 0.80
|/  
* e432e9d Count tokens, not characters
* b039fd7 Add output guard
$ git status
On branch main
nothing to commit, working tree clean
$ ls .git
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
objects
refs
$ cat .git/HEAD
ref: refs/heads/main
```
<!-- /snippet -->

`.git/HEAD` contains `ref: refs/heads/main`. Any file in capitals that is not in this listing is a sign of activity. (`ORIG_HEAD` and `FETCH_HEAD` are records of past commands, not of an operation in progress.)

**Merge.**

<!-- snippet: ch29/ops-in-progress/02-merge-status -->
```text
$ cd ../merging
$ git status
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Changes to be committed:
	new file:   blocklist.py

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml
```
<!-- /snippet -->

`git status` does not print the word "merging". It says "You have unmerged paths" and offers `git merge --abort`; after the last conflict is staged, the text becomes "All conflicts fixed but you are still merging".

<!-- snippet: ch29/ops-in-progress/03-merge-files -->
```text
$ ls .git
AUTO_MERGE
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
MERGE_HEAD
MERGE_MODE
MERGE_MSG
objects
ORIG_HEAD
refs
$ cat .git/MERGE_HEAD
a469d78723e151187e6d8cefe905e898fa0e1495
$ cat .git/MERGE_MODE
$ cat .git/MERGE_MSG
Merge branch 'feature/strict-guard'

# Conflicts:
#	guard.yaml
$ cat .git/ORIG_HEAD
3e2ce98834b9eccea6b02a664d0dfc63c75e0e4b
$ git ls-files -u
100644 248eaf478810ec8dbbcac312051603ba86b05f30 1	guard.yaml
100644 ea5b34d7cbddccfdf80d8ac18aa35c90353b7249 2	guard.yaml
100644 07eef246dd9ec18304b69ded66e99c7edf039bf0 3	guard.yaml
```
<!-- /snippet -->

`MERGE_HEAD` is the commit being merged in; it becomes the second parent. `MERGE_MSG` is the prepared message. `ORIG_HEAD` is the tip before the merge. `AUTO_MERGE` is a tree with the conflict markers as Git wrote them. HEAD is still attached to `main`. The index holds three stages for `guard.yaml` ([Chapter 5](ch05-index.md), section 5.13).

**Rebase.**

<!-- snippet: ch29/ops-in-progress/04-rebase-status -->
```text
$ cd ../rebasing
$ git status
interactive rebase in progress; onto 65032d6
Last command done (1 command done):
   pick 93eab48 # Raise guard threshold to 0.80
Next commands to do (2 remaining commands):
   pick bbb4ee3 # Add blocklist
   pick 7aaefa2 # Lower max_tokens to 128
  (use "git rebase --edit-todo" to view and edit)
You are currently rebasing branch 'feature/strict-guard' on '65032d6'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

<!-- snippet: ch29/ops-in-progress/05-rebase-files -->
```text
$ ls .git
AUTO_MERGE
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
MERGE_MSG
objects
ORIG_HEAD
REBASE_HEAD
rebase-merge
refs
$ cat .git/HEAD
65032d66238b96ad4cde8f0540fa079fdc81db17
$ cat .git/REBASE_HEAD
93eab48d915310771a87dde80923ef6b9dac5f19
$ cat .git/rebase-merge/head-name
refs/heads/feature/strict-guard
$ cat .git/rebase-merge/onto
65032d66238b96ad4cde8f0540fa079fdc81db17
$ cat .git/rebase-merge/orig-head
7aaefa26c2cece48f6e468ddf7c5487f381121ca
$ cat .git/rebase-merge/msgnum .git/rebase-merge/end
1
3
$ cat .git/rebase-merge/git-rebase-todo
pick bbb4ee363e9d43a807c1ef1409e1f503f0904373 # Add blocklist
pick 7aaefa26c2cece48f6e468ddf7c5487f381121ca # Lower max_tokens to 128
```
<!-- /snippet -->

HEAD is a raw commit ID. `REBASE_HEAD` is the commit whose replay stopped. `rebase-merge/head-name` is the branch that will be moved at the end, `orig-head` its tip at the start, `onto` the new base, `msgnum` and `end` the position (1 of 3), `git-rebase-todo` the remaining picks. The older apply backend uses a directory `rebase-apply` with the same role ([Chapter 9](ch09-rebase.md), section 9.4).

**Cherry-pick.**

<!-- snippet: ch29/ops-in-progress/06-pick-status -->
```text
$ cd ../picking
$ git status
On branch main
You are currently cherry-picking commit a19fbd4.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

<!-- snippet: ch29/ops-in-progress/07-pick-files -->
```text
$ ls .git
AUTO_MERGE
CHERRY_PICK_HEAD
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
MERGE_MSG
objects
refs
sequencer
$ cat .git/CHERRY_PICK_HEAD
a19fbd43d80f8f8214d7c1ba1bcd2b486660a821
$ ls .git/sequencer
abort-safety
head
todo
$ cat .git/sequencer/head
a2ba40c745eeaae544b12a748b049ae496e1a449
$ cat .git/sequencer/todo
pick a19fbd4 Raise guard threshold to 0.80
pick f559020 Add blocklist
pick c036209 Lower max_tokens to 128
```
<!-- /snippet -->

`CHERRY_PICK_HEAD` is the commit being applied. HEAD stays on the branch. The `sequencer` directory exists because several commits were requested: `head` is where the branch was before the first pick, and `todo` lists the current pick first and then those not yet applied. A cherry-pick of a single commit has no `sequencer` directory ([Chapter 10](ch10-cherry-pick.md), section 10.6).

**Revert.**

<!-- snippet: ch29/ops-in-progress/08-revert-status -->
```text
$ cd ../reverting
$ git status
On branch feature/strict-guard
You are currently reverting commit e3f95f7.
  (fix conflicts and run "git revert --continue")
  (use "git revert --skip" to skip this patch)
  (use "git revert --abort" to cancel the revert operation)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

<!-- snippet: ch29/ops-in-progress/09-revert-files -->
```text
$ ls .git
AUTO_MERGE
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
MERGE_MSG
objects
refs
REVERT_HEAD
$ cat .git/REVERT_HEAD
e3f95f738e757958ffb420c74a4472a591051e58
$ cat .git/MERGE_MSG
Revert "Raise guard threshold to 0.80"

This reverts commit e3f95f738e757958ffb420c74a4472a591051e58.

# Conflicts:
#	guard.yaml
```
<!-- /snippet -->

`REVERT_HEAD` is the commit being undone; the rest is the same machinery as cherry-pick with the roles of base and "theirs" exchanged ([Chapter 10](ch10-cherry-pick.md), section 10.11).

**Bisect.**

<!-- snippet: ch29/ops-in-progress/10-bisect-status -->
```text
$ cd ../bisecting
$ git status
HEAD detached at 71a6bc1
You are currently bisecting, started from branch 'feature/strict-guard'.
  (use "git bisect reset" to get back to the original branch)

nothing to commit, working tree clean
```
<!-- /snippet -->

<!-- snippet: ch29/ops-in-progress/11-bisect-files -->
```text
$ ls .git
BISECT_ANCESTORS_OK
BISECT_EXPECTED_REV
BISECT_LOG
BISECT_NAMES
BISECT_START
BISECT_TERMS
COMMIT_EDITMSG
config
description
HEAD
hooks
index
info
logs
objects
refs
$ cat .git/HEAD
71a6bc165b04d0be0ad6f1c8310d5d37693a39f9
$ cat .git/BISECT_START
feature/strict-guard
$ cat .git/BISECT_TERMS
bad
good
$ cat .git/BISECT_LOG
# bad: [6ed2fda3394fb715dd93eb1690d7cd51e05deac7] Lower max_tokens to 128
# good: [307506a4f8bc8b31589e49db034dd1b16728206f] Add output guard
git bisect start 'HEAD' 'main~3'
# good: [3164fc1d8b8dbf03fed13bfa4deccd261c8fd254] Raise guard threshold to 0.80
git bisect good 3164fc1d8b8dbf03fed13bfa4deccd261c8fd254
$ git for-each-ref refs/bisect
6ed2fda3394fb715dd93eb1690d7cd51e05deac7 commit	refs/bisect/bad
307506a4f8bc8b31589e49db034dd1b16728206f commit	refs/bisect/good-307506a4f8bc8b31589e49db034dd1b16728206f
3164fc1d8b8dbf03fed13bfa4deccd261c8fd254 commit	refs/bisect/good-3164fc1d8b8dbf03fed13bfa4deccd261c8fd254
```
<!-- /snippet -->

A bisect has no conflict and a clean working tree, which is why it is the operation most often forgotten. HEAD is detached on the commit under test. `BISECT_START` is the branch to return to, `BISECT_LOG` the replayable record, and the marks are refs under `refs/bisect/` ([Chapter 14A](ch14a-history-investigation.md), section 14A.20).

**Picture.** One table to keep:

| Operation | First lines of `git status` | State in `.git` | HEAD | Continue | Leave and restore | Leave and keep the current state |
|---|---|---|---|---|---|---|
| Merge | "You have unmerged paths" or "All conflicts fixed but you are still merging" | `MERGE_HEAD`, `MERGE_MODE`, `MERGE_MSG`, `AUTO_MERGE` | on the branch | `git commit` or `git merge --continue` | `git merge --abort` | `git merge --quit` |
| Rebase | "interactive rebase in progress; onto ..." or "rebase in progress" | `rebase-merge/` or `rebase-apply/`, `REBASE_HEAD` | detached | `git rebase --continue` | `git rebase --abort` | `git rebase --quit` |
| Cherry-pick | "You are currently cherry-picking commit ..." | `CHERRY_PICK_HEAD`; `sequencer/` for several commits | on the branch | `git cherry-pick --continue` | `git cherry-pick --abort` | `git cherry-pick --quit` |
| Revert | "You are currently reverting commit ..." | `REVERT_HEAD`; `sequencer/` for several commits | on the branch | `git revert --continue` | `git revert --abort` | `git revert --quit` |
| Bisect | "You are currently bisecting, started from branch ..." | `BISECT_LOG`, `BISECT_START`, `BISECT_TERMS`, `refs/bisect/*` | detached | `git bisect good` or `bad` | `git bisect reset` | `git bisect reset HEAD` |

All of the "Leave and restore" commands are 🟡: each resets the index and the working tree for tracked files, so uncommitted edits made during the operation are lost. Section 29.7 shows that loss in a transcript.

The same question for six repositories at once:

<!-- snippet: ch29/ops-in-progress/12-one-question -->
```text
# One read-only question for any repository: which state files exist?
$ for d in clean merging rebasing picking reverting bisecting; do echo "== $d"; ls ../$d/.git | grep -E "_HEAD$|rebase-|sequencer|BISECT_LOG"; done
== clean
== merging
MERGE_HEAD
ORIG_HEAD
== rebasing
ORIG_HEAD
REBASE_HEAD
rebase-merge
== picking
CHERRY_PICK_HEAD
sequencer
== reverting
REVERT_HEAD
== bisecting
BISECT_LOG
```
<!-- /snippet -->

**What Git refuses while an operation is open.** These refusals are often the reported symptom:

<!-- snippet: ch29/ops-in-progress/13-refusals -->
```text
$ cd ../merging
$ git switch feature/strict-guard
fatal: cannot switch branch while merging
Consider "git merge --quit" or "git worktree add".
[exit status: 128]
$ git cherry-pick feature/strict-guard~1
error: Cherry-picking is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: cherry-pick failed
[exit status: 128]
$ git merge feature/strict-guard
error: Merging is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
[exit status: 128]
$ cd ../rebasing
$ git rebase main
fatal: It seems that there is already a rebase-merge directory, and
I wonder if you are in the middle of another rebase.  If that is the
case, please try
	git rebase (--continue | --abort | --skip)
If that is not the case, please
	rm -fr ".git/rebase-merge"
and run me again.  I am stopping in case you still have something
valuable there.

[exit status: 128]
```
<!-- /snippet -->

The last message proposes `rm -fr ".git/rebase-merge"`. That deletes the record of where the branch was and what remains to be replayed. It is appropriate only when you have confirmed that no rebase is wanted and have anchored HEAD first. `git rebase --quit` does the same with Git's own bookkeeping.

**The ways out.**

<!-- snippet: ch29/ops-in-progress/14-ways-out -->
```text
$ cd ../merging && git merge --abort && git status -sb && ls .git | grep -c MERGE
## main
0
$ cd ../rebasing && git rebase --abort && git status -sb
## feature/strict-guard
$ cd ../picking && git cherry-pick --abort && git status -sb
## main
$ cd ../reverting && git revert --abort && git status -sb
## feature/strict-guard
$ cd ../bisecting && git bisect reset && git status -sb
Previous HEAD position was 71a6bc1 Add blocklist
Switched to branch 'feature/strict-guard'
## feature/strict-guard
```
<!-- /snippet -->

**In production.** A colleague's laptop is handed over with "Git is broken, it will not let me switch branches". The diagnosis is one `git status`: an earlier `git pull` stopped at a conflict and was left. The decision that follows is not automatic: continue (if the operation was intended and the resolution is known), abort (if nothing done inside it matters), or anchor and then abort (case 1). Ask what was intended before choosing.

## 29.7 Preserving evidence before acting

**In one sentence.** Before the first state-changing command, put what you might need later somewhere that the fix cannot reach.

**Analogy.** A database administrator takes a snapshot before a migration. The analogy breaks only in cost: a backup ref takes one second, so time never justifies skipping it.

**Precisely.** There are four layers. Each holds more than the previous one and costs more.

| Layer | Command | Holds | Does not hold |
|---|---|---|---|
| The recorded output | redirect the ten commands to a file; `git diff > file.patch` | What you saw, including reflog lines that later commands will push down; uncommitted changes as patches | Objects |
| A backup ref 🟢 | `git branch rescue/<what> <id>` or `git update-ref refs/backup/<name> <id>` | One commit and everything it reaches, kept from garbage collection for as long as the ref exists | Reflogs, the index, uncommitted files, operation state |
| A copy of the repository 🟢 | `cp -Rp . ../evidence/<name>-copy` | Everything: objects, refs, reflogs, index, working tree, stashes, hooks, configuration, operation state | Nothing local. It does not hold what only the server has |
| A bundle 🟢 | `git bundle create <file> --all` | Every ref and HEAD with all objects they reach, in one file that can be verified, moved and fetched from | Reflogs, unreachable objects, the index, uncommitted files, configuration, hooks |

A ref under `refs/backup/` is not shown by `git branch`; a branch under `rescue/` is, which is better when a colleague continues the work. Both keep the commit alive.

**See it.** The script is `labs/ch29/preserve-evidence.sh`. It uses the repository of case 1 with two additions that case 1 did not have: one staged and one unstaged edit.

<!-- snippet: ch29/preserve-evidence/01-record -->
```text
$ mkdir ../evidence
$ { git status; git branch -vv; git log --graph --decorate --oneline --all; git reflog; } > ../evidence/state.txt 2>&1
$ git diff > ../evidence/unstaged.patch
$ git diff --cached > ../evidence/staged.patch
$ git status --short
 M README.md
M  config/service.yaml
$ grep -c "" ../evidence/state.txt ../evidence/unstaged.patch ../evidence/staged.patch
../evidence/state.txt:46
../evidence/unstaged.patch:10
../evidence/staged.patch:9
```
<!-- /snippet -->

<!-- snippet: ch29/preserve-evidence/02-backup-ref -->
```text
$ git branch rescue/latency-wip HEAD
$ git update-ref refs/backup/latency-budget feature/latency-budget
$ git for-each-ref refs/heads/rescue refs/backup
4a030148e74b6b4394d1056737434790a34ae612 commit	refs/backup/latency-budget
075407e71d9b34006eccefd0d2072bfb51d2850b commit	refs/heads/rescue/latency-wip
```
<!-- /snippet -->

<!-- snippet: ch29/preserve-evidence/03-copy -->
```text
$ cp -Rp . ../evidence/scoring-api-copy
$ git -C ../evidence/scoring-api-copy status | head -4
interactive rebase in progress; onto 4b30d7e
Last command done (1 command done):
   pick 60d09a1 # Add latency budget to config
Next commands to do (2 remaining commands):
$ git -C ../evidence/scoring-api-copy status --short
 M README.md
M  config/service.yaml
$ git -C ../evidence/scoring-api-copy reflog -3
075407e HEAD@{0}: commit: Log budget violations
96a7b55 HEAD@{1}: commit: Add p95 latency metric
9fbe4d7 HEAD@{2}: commit: Add latency budget to config
```
<!-- /snippet -->

The copy is a complete repository: the same rebase in progress, the same staged and unstaged files, the same reflog. `-p` keeps modification times, which spares Git a re-read of every file ([Chapter 5](ch05-index.md), section 5.14).

<!-- snippet: ch29/preserve-evidence/04-bundle -->
```text
$ git bundle create ../evidence/scoring-api.bundle --all
$ git bundle verify ../evidence/scoring-api.bundle
../evidence/scoring-api.bundle is okay
The bundle contains these 7 refs:
4a030148e74b6b4394d1056737434790a34ae612 refs/backup/latency-budget
4a030148e74b6b4394d1056737434790a34ae612 refs/heads/feature/latency-budget
4b30d7e307a39954609eb40c2b4c2a1f63c74857 refs/heads/main
075407e71d9b34006eccefd0d2072bfb51d2850b refs/heads/rescue/latency-wip
4a030148e74b6b4394d1056737434790a34ae612 refs/remotes/origin/feature/latency-budget
4b30d7e307a39954609eb40c2b4c2a1f63c74857 refs/remotes/origin/main
075407e71d9b34006eccefd0d2072bfb51d2850b HEAD
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
```
<!-- /snippet -->

The bundle lists seven refs, among them the backup refs created a moment ago and the detached `HEAD`. A bundle holds what refs and HEAD reach at the moment it is made. A commit that only a reflog knows is not in it, which is the reason to anchor first and bundle second ([Chapter 26](ch26-performance.md), section 26.14 covers the format).

**Inside `.git`.** Now the proof. The script does on purpose what a panicked sequence of "fixes" does by accident:

<!-- snippet: ch29/preserve-evidence/05-destroy -->
```text
# The worst afternoon: the rebase is aborted, the anchors are deleted, the reflogs are
# emptied and the unreachable objects are pruned. Do not run this on a repository you need.
$ git rebase --abort
$ git branch -D rescue/latency-wip
Deleted branch rescue/latency-wip (was 075407e).
$ git update-ref -d refs/backup/latency-budget
$ git reflog expire --expire=now --all
$ git gc --quiet --prune=now
$ git cat-file -t 075407e
fatal: Not a valid object name 075407e
[exit status: 128]
$ git status --short
```
<!-- /snippet -->

`git rebase --abort` printed nothing, and the last command shows that the staged and the unstaged edit are gone with it. With the anchors deleted, the reflogs emptied and the objects pruned, `075407e` is no longer an object in this repository. This is the point of no return of [Chapter 13](ch13-recovery.md), section 13.13, reached in five commands. 🔴 `git reflog expire --expire=now --all` followed by `git gc --prune=now` removes the safety net itself: it has no preview and no undo, and it is appropriate only for removing sensitive data from a clone after the secret has been rotated.

<!-- snippet: ch29/preserve-evidence/06-from-bundle -->
```text
$ git fetch ../evidence/scoring-api.bundle 'refs/heads/rescue/*:refs/heads/rescue/*'
From ../evidence/scoring-api.bundle
 * [new branch]      rescue/latency-wip -> rescue/latency-wip
$ git log --oneline -3 rescue/latency-wip
075407e Log budget violations
96a7b55 Add p95 latency metric
9fbe4d7 Add latency budget to config
$ git reflog show rescue/latency-wip
075407e rescue/latency-wip@{0}: fetch ../evidence/scoring-api.bundle refs/heads/rescue/*:refs/heads/rescue/*: storing head
```
<!-- /snippet -->

The bundle returns the three commits. The new reflog has one line: the history of how the ref moved is not in a bundle.

<!-- snippet: ch29/preserve-evidence/07-from-copy -->
```text
$ cd ../evidence/scoring-api-copy
$ git status --short
 M README.md
M  config/service.yaml
$ git reflog -3
075407e HEAD@{0}: commit: Log budget violations
96a7b55 HEAD@{1}: commit: Add p95 latency metric
9fbe4d7 HEAD@{2}: commit: Add latency budget to config
$ cat .git/rebase-merge/head-name
refs/heads/feature/latency-budget
$ git diff --cached --stat
 config/service.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

The copy returns everything, including the two uncommitted edits and the rebase state.

None of the four layers changes the working tree, the index, HEAD or any existing ref: a backup ref adds one ref, and the copy and the bundle are written outside the repository.

**In production.** A ref is about to move: a backup ref, always. Uncommitted work or an operation in progress is involved: a copy of the whole directory. The disk is suspect or the evidence must leave the machine: a bundle, stored elsewhere. Someone else will ask what happened: the recorded output.

A copy of a repository contains everything the repository contains, including credentials in `.git/config` URLs and any secret in history. Treat it with the same care, and delete it when the incident is closed.

## 29.8 GitHub-side evidence

**In one sentence.** Your clone records what you did; GitHub records what reached the server, who was authenticated when it arrived, and which rules were evaluated.

> **GitHub, not Git.** Nothing in this section is part of Git. Git's reflogs are local and are not shared with remotes, and GitHub exposes no server-side reflog ([Chapter 13](ch13-recovery.md), section 13.15). Everything below is described from GitHub's documentation as read on 1 October 2026; none of the commands was executed here, and user-interface labels change.

**Precisely.** Five sources, each with a different reach and a different lifetime.

| Source | What it records | Reach and limits | Who can read it |
|---|---|---|---|
| **Activity view** of a repository | "pushes, merges, force pushes, and branch changes", associated "with commits and authenticated users"; filters for branch, activity type (direct pushes, pull request merges, force pushes, branch creations, branch deletions), user and time period; "Compare changes" on each entry ([documentation](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository)) | The before and after commit of each ref update. Retention is not stated in the page | Not stated in the page (flag below) |
| **Pull request timeline** | The events of one pull request in order. The documented event types include `committed`, `head_ref_force_pushed` ("The pull request's HEAD branch was force pushed"), `head_ref_deleted`, `head_ref_restored` and `base_ref_changed` ([issue event types](https://docs.github.com/en/rest/using-the-rest-api/issue-event-types)). A closed pull request offers "Restore branch" for a deleted head branch ([documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request)) | One pull request. The head commits stay fetchable through `refs/pull/N/head` ([Chapter 17](ch17-pull-requests.md), section 17.2) | Anyone who can read the pull request |
| **Events API** | `PushEvent` with `ref`, `before` ("the SHA of the most recent commit on `ref` before the push") and `head` (after the push) ([event types](https://docs.github.com/en/rest/using-the-rest-api/github-event-types#pushevent)) | "up to 300 events", only those "created within the past 30 days"; latency "anywhere from 30s to 6h"; since 7 October 2025 push events no longer carry commit summaries ([events API](https://docs.github.com/en/rest/activity/events), [changelog](https://github.blog/changelog/2025-08-08-upcoming-changes-to-github-events-api-payloads/)) | Anyone who can read the repository |
| **Rule Insights** | Every ref update evaluated by a ruleset: passed, failed or bypassed, and what would have happened in Evaluate mode; the `rule-suites` REST endpoint returns the same data ([documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository#viewing-insights-for-rulesets)) | Rulesets only, not classic branch protection. An exempt actor skips enforcement without the signals a bypass generates ([Chapter 18](ch18-branch-protection.md), section 18.5). The insights dashboard is for Team and Enterprise Cloud plans | Repository administrators |
| **Audit log** | Organization: events of the last 180 days, for owners, exportable. Enterprise: also Git events such as `git.push`, retained for seven days and available "only via the REST API, audit log streaming, or JSON/CSV exports"; `protected_branch.policy_override` when an administrator overrides a classic rule ([organization audit log](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization), [enterprise audit log](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/security-and-compliance/audit-log-for-an-enterprise)) | Organization and enterprise accounts only. A personal repository has no audit log of this kind | Organization owners; enterprise owners |

The commands that read these sources, shown without output:

```bash
# Activity: the documented REST endpoint behind the Activity view
gh api "repos/OWNER/REPO/activity?activity_type=force_push&ref=refs/heads/main"

# One pull request: its state, its head commit, its timeline
gh pr view 42 --json headRefOid,baseRefName,mergeable,mergeStateStatus,statusCheckRollup
gh api repos/OWNER/REPO/issues/42/timeline --paginate

# Events: before and head of recent pushes
gh api repos/OWNER/REPO/events --jq '.[] | select(.type=="PushEvent") | [.created_at, .payload.ref, .payload.before, .payload.head] | @tsv'

# Rules: every evaluation, and what applies to one branch
gh api repos/OWNER/REPO/rulesets/rule-suites
gh ruleset check main

```

The activity endpoint is documented as `GET /repos/{owner}/{repo}/activity` with the `activity_type` values `push`, `force_push`, `branch_creation`, `branch_deletion`, `pr_merge` and `merge_queue_merge`, and items that carry `before`, `after`, `ref`, `timestamp` and `actor` ([REST: repositories](https://docs.github.com/en/rest/repos/repos#list-repository-activities)).

**How the two sides combine.** Git evidence answers "what is the state and which local command produced it". GitHub evidence answers "which authenticated account moved the server's ref, when, from which commit to which, and did a rule allow it". Your clone cannot know who pushed. The author field of a commit does not say either: anyone can set it ([Chapter 14B](ch14b-config-tags-signing.md), section 14B.18).


**The flags that travel with these facts** (from the Phase 0 report, section 13):

> **Unverified.** A "restore" action inside the Activity view: only filtering and "Compare changes" are documented there. The access requirement and the retention period of the Activity view are not stated in the documentation that was read.

> **Unverified.** How long GitHub keeps commits that no ref reaches. No retention period is published. The recovery recipe (find the old ID, then create a ref at it through the references API, [Chapter 13](ch13-recovery.md), section 13.15) is an inference from documented endpoints, not a documented procedure, and nothing guarantees that it succeeds.

**In production.** `main` moved backwards on Friday evening. `git reflog show origin/main` in any clone that fetched before and after gives the two IDs. The Activity view filtered by force pushes names the account and the time. Rule Insights says whether a ruleset evaluated that update and whether the actor bypassed it. The audit log shows whether a rule was edited shortly before.

## 29.9 Choosing the lowest-risk fix

**In one sentence.** List every fix that would repair the root cause, rank them by what each can destroy and how each is undone, and take the one that only adds.

**Precisely.** Rank by five questions, in this order.

1. **Does it destroy uncommitted work?** That work has no object and no reflog. Anything that can remove it (`git reset --hard`, `git restore`, `git clean`, `git stash drop`, every `--abort`) ranks last unless the working tree is clean or copied.
2. **Does it rewrite commits that another repository has?** Rewriting published history turns one person's problem into every clone's problem ([Chapter 9](ch09-rebase.md), section 9.15).
3. **Does it change the server?** A local change is undone locally. A push, a deleted remote branch or a changed rule is seen by others and may start workflows.
4. **Is it undone by one command?** A new commit is undone by a revert; a moved ref by moving it back; a pruned object by nothing.
5. **Can it be previewed?** `--dry-run`, `git merge-tree`, `git diff <target>`, `git log <range>`, or a rehearsal in a copy.

The resulting ladder, from least to most risk:

```text
  1  add a ref                 git branch, git tag, git update-ref               nothing can be lost
  2  add a commit              git commit, git revert, git cherry-pick, merge    undone by a revert or by moving the ref back
  3  move a local ref          git reset --keep, git branch -f, git rebase       undone through the reflog or a backup ref
  4  overwrite the work tree   git reset --hard, git restore, git clean          uncommitted work is unrecoverable
  5  rewrite the server        git push --force-with-lease=<ref>:<expected>      others must repair their clones
  6  remove the safety net     git reflog expire, git gc --prune=now             nothing undoes it
```

Prefer the lowest rung that repairs the cause. In case 1 that was rungs 1 and 2. In case 2 it was rung 3 on commits that existed nowhere else, with rung 1 first.

Three rules of thumb follow from the ladder.

- **On a shared branch, undo with `git revert`, not with `git reset`.** A revert adds a commit; everyone's next pull is a fast-forward ([Chapter 11](ch11-reset-revert-restore.md), section 11.8).
- **When a ref must move back, use `git reset --keep`.** It refuses when a file with local changes would be overwritten, where `--hard` overwrites it ([Chapter 11](ch11-reset-revert-restore.md), section 11.6).
- **When a force push is the correct fix, state the expected old value**: `git push --force-with-lease=<branch>:<expected-id>`. The bare form is defeated by anything that fetches in the background ([Chapter 12](ch12-remote-operations.md), section 12.8).

## 29.10 Verification

**In one sentence.** A fix is verified when the commands that showed the problem now show its absence, for the reason you predicted, in every place the problem existed.

**Precisely.** Four checks, in this order.

1. **The symptom.** Repeat the command or page that showed it: the rejected push succeeds; the pull request lists the expected commits.
2. **The state.** Repeat the diagnosis commands that exposed the cause. The first line of `git status` changed; the brackets in `git branch -vv` changed; `.git` has no state files.
3. **Every copy.** A fix in your clone is not a fix on the server. Compare IDs, not names: `git rev-parse HEAD @{upstream}` and `git ls-remote origin <branch>` must print the same ID. Then the colleague's clone, the pull request, the pipeline run for that exact commit.
4. **Nothing else changed.** `git diff <backup> HEAD` or `git range-diff` shows that the result differs from the preserved state only where intended. `git fsck` reports no damage. `git status` shows no leftovers.

Write the prediction before you run the check: in case 1, "`git cherry` will mark the two new commits with a minus sign and the two others with a plus sign".

Then, and only then, remove what the investigation added: the rescue branch (`git branch -D` prints the ID, which is one more safety line), the evidence directory, the bundle.

**What a pull request needs after a fix** is platform behavior: a push to the head branch reruns workflows and can dismiss approvals; a forced push marks review comments as outdated ([Chapter 17](ch17-pull-requests.md), sections 17.5 and 17.12). Verification includes reading the pull request page again.

## 29.11 The symptom catalog

Twenty-six symptoms; the playbook's compact catalog adds six shorter ones. Each row gives the likely causes in the order worth testing, the commands that separate them, and the chapter and section with the mechanism. Chapters 20A and 20B are the GitHub Actions chapters.

### History and refs

| # | Symptom | Likely causes | Commands that distinguish them | Mechanism |
|---|---|---|---|---|
| 1 | A commit is missing | (a) it is on another branch; (b) it was made on a detached HEAD or inside a stopped operation; (c) a reset, rebase or amend took it off the branch; (d) it was never pushed, or pushed to another branch; (e) it was never made: the change was not staged | `git branch -a --contains <id>`; `git status` (first line); `git reflog`, `git reflog show <branch>`; `git ls-remote origin`; `git log --all --oneline -- <path>` | [13](ch13-recovery.md), 13.7, 13.8; [12](ch12-remote-operations.md), 12.14; section 29.3; [1](ch01-fundamentals.md), 1.12 |
| 2 | A branch disappeared | (a) it exists only as a remote-tracking branch and was never created locally; (b) deleted locally; (c) deleted on the server and removed here by a pruning fetch; (d) renamed; (e) you are in another clone or worktree | `git branch -a`; `git reflog` (search for `moving from <branch>`); `git ls-remote origin`; `git fsck --lost-found`; `git worktree list`; on GitHub the Activity view filtered by branch deletions | [13](ch13-recovery.md), 13.8, 13.15; [12](ch12-remote-operations.md), 12.11; [7](ch07-branches.md), 7.10 |
| 3 | "HEAD detached at ..." | (a) a tag, a commit ID or a remote-tracking branch was checked out; (b) a rebase or bisect is in progress; (c) you are inside a submodule; (d) a CI checkout | `git status`; `cat .git/HEAD`; `ls .git`; `git reflog -5`; `git rev-parse --show-toplevel` | [7](ch07-branches.md), 7.7; section 29.6; [23](ch23-submodules.md), 23.5 |
| 4 | Commits are duplicated: the same subject twice with different IDs | (a) a published branch was rebased and then merged with its old copy; (b) cherry-picked commits were later merged; (c) a pull request was squashed or rebase-merged and the branch reused | `git log --oneline --graph --all`; `git cherry -v <upstream> <branch>`; `git range-diff A...B`; `git log --cherry-mark --left-right A...B` | [9](ch09-rebase.md), 9.3, 9.15; [10](ch10-cherry-pick.md), 10.10; [17](ch17-pull-requests.md), 17.9 |
| 5 | A merge brought nothing: "Already up to date", yet the code is absent | (a) the branch was merged before and the merge was reverted; (b) the commits are ancestors already and a later commit removed the change; (c) merged with `-s ours`; (d) you merged a stale local branch instead of `origin/<branch>` | `git merge-base --is-ancestor <branch> HEAD`; `git log --oneline --merges --grep=Revert`; `git log -S<string> --oneline`; `git rev-parse <branch> origin/<branch>` | [11](ch11-reset-revert-restore.md), 11.9; [8](ch08-merge.md), 8.3, 8.6 |
| 6 | A merge conflict nobody expected | (a) both sides changed adjacent lines; (b) the merge base is older than assumed: squash-merged branch reused, or a criss-cross; (c) one side renamed or reformatted the file; (d) line endings differ; (e) "ours" and "theirs" are exchanged in a rebase | `git merge-base A B`; `git diff A...B --stat`; `git ls-files -u`; `git diff --ignore-cr-at-eol`; `git log --merge --oneline` | [8](ch08-merge.md), 8.7, 8.5, 8.11; [9](ch09-rebase.md), 9.11; [17](ch17-pull-requests.md), 17.12 |
| 7 | Code vanished after a merge and no commit removes it | (a) a conflict was resolved by taking one side; (b) history simplification hides the commit in `git log -- <path>`; (c) a clean merge that is wrong in meaning | `git log --full-history --oneline -- <path>`; `git show --remerge-diff <merge>`; `git log -S<string> --oneline` | [8](ch08-merge.md), 8.15, 8.16; [14A](ch14a-history-investigation.md), 14A.10, 14A.11 |
| 8 | A tag points somewhere else on another machine | (a) the tag was moved on the server after you fetched it: fetch does not update existing tags; (b) a local tag of the same name was never pushed; (c) lightweight on one side, annotated on the other | `git rev-parse <tag>^{commit}`; `git ls-remote --tags origin <tag>`; `git cat-file -t <tag>`; `git for-each-ref refs/tags/<tag>` | [14B](ch14b-config-tags-signing.md), 14B.10, 14B.11; [12](ch12-remote-operations.md), 12.15 |
| 9 | `git branch -d` refuses: "not fully merged", after the pull request was merged | (a) squash or rebase merge created new IDs, so the branch is not an ancestor; (b) the branch has commits made after the merge; (c) the comparison is with the upstream, which is gone | `git cherry -v origin/main <branch>`; `git log --oneline origin/main..<branch>`; `git branch -vv` (`gone`) | [17](ch17-pull-requests.md), 17.9; [7](ch07-branches.md), 7.5 |

### Working tree and index

| # | Symptom | Likely causes | Commands that distinguish them | Mechanism |
|---|---|---|---|---|
| 10 | Git does not recognize a file: it is on disk and `git status` does not list it | (a) an ignore rule in `.gitignore`, `.git/info/exclude` or the global excludes file; (b) it is inside a nested repository; (c) the directory is empty; (d) outside the sparse-checkout cone; (e) you are in another repository | `git check-ignore -v <path>`; `git status --ignored`; `git rev-parse --show-toplevel`; `git ls-files -s <path>` (mode 160000 is a submodule); `git sparse-checkout list` | [4](ch04-working-tree.md), 4.3, 4.5, 4.11; [23](ch23-submodules.md), 23.2; [24](ch24-monorepos.md), 24.4 |
| 11 | A file keeps showing as modified | (a) it is tracked and also listed in `.gitignore`: ignore rules do not apply to tracked files; (b) line-ending conversion; (c) the executable bit; (d) two names that differ only in case; (e) an LFS or other filter; (f) a tool rewrites it | `git ls-files <path>`; `git diff --stat`, `git diff --ignore-cr-at-eol`; `git ls-files --eol <path>`; `git diff --summary` (mode change); `git ls-files` piped to `sort -f` and `uniq -di`; `git check-attr -a -- <path>` | [4](ch04-working-tree.md), 4.6, 4.10, 4.12; [14C](ch14c-stash-rerere-attributes-hooks.md), 14C.5; [22](ch22-git-lfs.md), 22.5 |
| 12 | A change is in the working tree and not in the commit | (a) edited and never staged; (b) staged, then edited again; (c) `git commit <path>` or `-a` bypassed what was staged | `git status`; `git diff`; `git diff --cached`; `git show --stat HEAD` | [1](ch01-fundamentals.md), 1.12; [5](ch05-index.md), 5.4, 5.10 |
| 13 | Uncommitted work vanished | (a) `git reset --hard`, `git restore`, `git checkout -- <path>` or an `--abort`; (b) it is in a stash; (c) `git clean`; (d) another worktree holds it | `git stash list`; `git reflog -10`; `git fsck --lost-found` (staged content survives as blobs); `git worktree list` | [11](ch11-reset-revert-restore.md), 11.5, 11.10; [13](ch13-recovery.md), 13.9, 13.12 |
| 14 | Git refuses to switch, pull, merge or commit: "you need to resolve your current index first", "cannot switch branch while merging" | An operation is in progress | `git status`; `ls .git`; section 29.6 | Section 29.6; [8](ch08-merge.md), 8.10 |

### Remotes, access and identity

| # | Symptom | Likely causes | Commands that distinguish them | Mechanism |
|---|---|---|---|---|
| 15 | A push is rejected | (a) `! [rejected] (fetch first)` or `(non-fast-forward)`: the server's branch has commits you lack; (b) the pull integrates another branch than the push targets; (c) `! [remote rejected]`: a rule, a hook, push protection or a file-size limit, named in the `remote:` lines; (d) no permission | Read the bracket and the reason in the push output; `git fetch`, `git status -sb`; `git branch -vv`; `gh ruleset check <branch>` | [12](ch12-remote-operations.md), 12.7, 12.15; section 29.4; [18](ch18-branch-protection.md), 18.17 |
| 16 | A pull refuses | (a) "Need to specify how to reconcile divergent branches"; (b) "Not possible to fast-forward" with `pull.ff=only`; (c) local changes would be overwritten; (d) no upstream; (e) an operation is in progress; (f) "refusing to merge unrelated histories" | `git status -sb`; `git config get --show-origin --all pull.ff`, `pull.rebase`; `git branch -vv`; `git merge-base HEAD @{upstream}` | [12](ch12-remote-operations.md), 12.6, 12.15; [8](ch08-merge.md), 8.18 |
| 17 | "Everything up-to-date", and the commit is not on the server | (a) the commit is not on the branch that was pushed: detached HEAD, stopped rebase, another branch; (b) the push went to another remote or branch | `git branch -a --contains <id>`; `git status`; `git remote -v`; `git ls-remote origin` | [12](ch12-remote-operations.md), 12.14; section 29.3 |
| 18 | "Already up to date" after a pull, and a teammate's commit is absent | (a) the upstream is another branch; (b) the teammate did not push, or pushed elsewhere; (c) a narrow fetch refspec or single-branch clone | `git branch -vv`; `git ls-remote origin`; `git config get --all remote.origin.fetch` | Section 29.4; [12](ch12-remote-operations.md), 12.4, 12.12 |
| 19 | "Permission denied (publickey)" | (a) no key offered: agent empty, wrong `IdentityFile`; (b) the key belongs to no account; (c) the user in the URL is not `git`; (d) a key of another account answers first | `ssh -T git@github.com`; `ssh -vT git@github.com`; `ssh-add -l`; `ssh -G github.com`; `git remote -v` | [16](ch16-authentication.md), 16.18, 16.9, 16.10 |
| 20 | "Repository not found" for a repository that exists | (a) the credential belongs to an account without access: GitHub answers "not found" for private resources; (b) a typo or a renamed repository; (c) a fine-grained token not granted this repository; (d) SSO authorization missing | `git remote -v`; `gh auth status`; `ssh -T git@github.com`; `git config get --show-origin --all credential.helper` | [16](ch16-authentication.md), 16.19, 16.15 |
| 21 | The commit is attributed to the wrong person, or to nobody, on GitHub | (a) `user.email` comes from an unexpected scope or a conditional include; (b) the address is not registered on the account; (c) the author was set by environment variables | `git log -1 --format='%an <%ae> / %cn <%ce>'`; `git config get --show-origin --show-scope --all user.email` | [14B](ch14b-config-tags-signing.md), 14B.2, 14B.4; [6](ch06-commits.md), 6.5, 6.11 |

### Pull requests, checks and CI

| # | Symptom | Likely causes | Commands that distinguish them | Mechanism |
|---|---|---|---|---|
| 22 | A pull request shows hundreds of changes | (a) the wrong base branch; (b) the head branch was reused after a squash merge; (c) the branch was rebased or force-pushed; (d) every line changed: line endings or a formatter; (e) a lock file or generated file | `git log --oneline <base>..<head>`; `git diff --stat <base>...<head>`; `git merge-base <base> <head>`; `git diff --ignore-cr-at-eol --stat <base>...<head>` | [17](ch17-pull-requests.md), 17.12, 17.3; [14C](ch14c-stash-rerere-attributes-hooks.md), 14C.5 |
| 23 | CI fails only on the pull request and passes on the branch and locally | (a) the pull request run builds `refs/pull/N/merge`, the head merged into the current base, which contains base changes you do not have; (b) secrets are withheld from fork pull requests; (c) a shallow clone without tags; (d) a case-sensitive filesystem on the runner; (e) an untracked or ignored file exists only on your machine | `git fetch origin`, then `git merge-tree --write-tree origin/<base> HEAD`, or merge the base locally and run the tests; `git status --ignored`; `git ls-files`; `gh run view <id> --log-failed` | [17](ch17-pull-requests.md), 17.2, 17.6; Chapters 20A and 20B; [26](ch26-performance.md), 26.11; [4](ch04-working-tree.md), 4.12 |
| 24 | A required check never finishes: it stays pending and blocks the merge | (a) the workflow was skipped by a path filter, a branch filter or `[skip ci]` and never reports; (b) the required name matches no job; (c) the run was triggered by an event that does not count; (d) with a merge queue, the workflow lacks the `merge_group` trigger | `gh pr checks <n> --required`; `gh run list --commit <id>`; compare the required names with the job names | [18](ch18-branch-protection.md), 18.8; [17](ch17-pull-requests.md), 17.11 |

### Submodules, LFS and scale

| # | Symptom | Likely causes | Commands that distinguish them | Mechanism |
|---|---|---|---|---|
| 25 | A submodule is at the wrong commit, or its directory is empty | (a) the superproject moved its pointer and `git submodule update` was not run; (b) not initialized after clone; (c) the pointer names a commit that was never pushed; (d) work was committed on the submodule's detached HEAD | `git submodule status` (prefix `+`, `-`, `U`); `git diff --submodule`; `git ls-tree HEAD <path>`; `git -C <path> status` | [23](ch23-submodules.md), 23.3, 23.5, 23.7, 23.8 |
| 26 | Small text files beginning with `version https://git-lfs.github.com/spec/v1` where data should be | (a) Git LFS is not installed or `git lfs install` was not run, so the smudge filter did not run; (b) the clone skipped the download; (c) the object was never uploaded; (d) the file was committed before the pattern was tracked, or the reverse | `git lfs ls-files`; `git lfs status`; `git lfs env`; `git check-attr filter -- <path>`; `git config get --all filter.lfs.smudge` | [22](ch22-git-lfs.md), 22.3, 22.7, 22.10 |

The pattern across the catalog is the content of this book in one line: nearly every symptom is a difference between two of the places of section 29.2 that someone assumed were equal. The working tree and the commit (12). The branch and HEAD (1, 3, 17). The local branch and its upstream (15, 18). The remote-tracking branch and the server (2, 8). The branch and the merge ref (23). The diagnosis is finding which two.

## 29.12 What can go wrong

The method itself fails in recognisable ways.

| What goes wrong | How to recognise it | Fix | Prevention |
|---|---|---|---|
| A "fix" is typed before the state is known | The reflog shows `reset`, `checkout` or `rebase (abort)` entries made after the report | Stop. Anchor HEAD and every candidate ID, then restart at OBSERVE | The phases of section 29.2: nothing but 🟢 commands until the root cause is written down |
| The diagnosis uses stale remote-tracking refs | `git status` says "up to date" and `git ls-remote origin` shows another ID | `git fetch`, after recording the old value if it is evidence | Treat `origin/<branch>` as "the server at the last fetch" ([Chapter 12](ch12-remote-operations.md), section 12.4) |
| The wrong layer is blamed | "GitHub lost my commits" while `git ls-remote` shows the server never had them | Name the layer in the root-cause box and give the evidence for it | The label "Git, GitHub or Actions" is a required line of every explanation |
| The evidence is destroyed by the investigation | The reflog was expired, a branch was deleted "to tidy up", `git gc` was run | Recover from a copy, a bundle or another clone ([Chapter 13](ch13-recovery.md), section 13.10) | Section 29.7 before phase 3; never run `git gc` or `git prune` during an incident |

## 29.13 When not to use it, and dangerous edge cases

**When not to use the full method.** A message that names its own remedy and whose remedy is 🟢 needs no hypothesis table: "The current branch has no upstream branch" with the command printed beneath it, or a typo in a branch name. Run `git status`, do what the message says, and move on. The full method is for symptoms that contradict what the reporter believes about the state. The opening ritual is never skipped: it takes less than a minute.

**When to stop and escalate instead.** If the evidence shows a credential in history, stop diagnosing and start the secret response: revoke first, investigate second (Chapter 21B). If the repository reports corrupt or missing objects, do not continue working in it: copy it and follow [Chapter 13](ch13-recovery.md), section 13.11. If production is down, restore service first and diagnose afterwards on preserved evidence (Chapter 30).

**Dangerous edge cases.**

- **Diagnostic commands that are not read-only.** `git fsck --lost-found` writes files under `.git/lost-found/`. `git fetch` moves remote-tracking refs, and with `fetch.prune=true` or `--prune` it deletes those whose server branch is gone, together with their reflogs: the last local record of a deleted branch ([Chapter 12](ch12-remote-operations.md), section 12.11). Use `git ls-remote` when you must not change anything. `git status` may rewrite the index to refresh cached stat data; in a repository you must not touch at all, use `git --no-optional-locks status`, which the Git manual documents for background tools.
- **A stopped operation with new commits inside it** (case 1). `--abort` returns the branch and silently discards the commits and any uncommitted edit. `--continue` may be right or wrong. Anchor first; then every choice can be undone.
- **GitHub-side evidence that expires** (section 29.8). Export it on the first day.
- **Deleting state files by hand.** Removing `.git/MERGE_HEAD` or `.git/rebase-merge` ends the bookkeeping, not the operation. Lab 35.2 shows a merge that became an ordinary one-parent commit this way, after which Git still considers the branch unmerged.

## 29.14 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| The ten commands; `git ls-remote`; `git merge-tree --write-tree`; `git fsck`; `cp -Rp`; `git bundle create` | 🟢 SAFE | No ref, index entry or tracked file (section 29.13 lists the small exceptions) | not needed | not needed |
| `git fetch` | 🟢 SAFE | Adds objects; moves remote-tracking refs; with pruning, deletes stale ones | `git fetch --dry-run`; `git ls-remote` | The reflog of each remote-tracking ref, unless the ref was pruned |
| `git branch rescue/x <id>`, `git update-ref refs/backup/x <id>` | 🟢 SAFE | Adds one ref | not needed | `git branch -D`, `git update-ref -d` |
| `git cherry-pick`, `git revert`, `git merge` | 🟡 CAUTION | Add commits to the current branch; update index and working tree | `git merge-tree`; `git log <range>`; `git show <id>` | `git reset --keep ORIG_HEAD` or the branch reflog |
| `git rebase` | 🟡 CAUTION | Replaces commits of the current branch with new ones | `git log <upstream>..HEAD` | `git reset --keep ORIG_HEAD`; a backup ref |
| `git merge --abort` | 🔴 DANGEROUS | Ends the merge; resets index and working tree to HEAD. Destroys every resolution made so far and edits staged during the merge, and the manual warns that uncommitted changes present when the merge started cannot always be reconstructed ([Chapter 8](ch08-merge.md), section 8.21) | `git status`, `git diff --cached --stat` | Staged content: `git fsck --lost-found`. Unstaged resolution edits: none. Appropriate when the merge was a mistake and the PRESERVE step is done |
| `git rebase --abort`, `git cherry-pick --abort`, `git revert --abort`, `git bisect reset` | 🟡 CAUTION | End the operation; reset index and working tree to the starting commit; commits made inside a rebase leave the branch | `git status`, `git diff`, `git log <branch>..HEAD` | Commits: the HEAD reflog or a rescue ref. Uncommitted edits: none |
| `git push` | 🟡 CAUTION | Moves a ref on the server; starts whatever listens for pushes | `git push --dry-run` | A revert commit; moving the ref back needs a force |
| `git reset --hard`, `git restore <path>`, `git clean -f` | 🔴 DANGEROUS | Overwrite or delete working tree files; uncommitted work is destroyed | `git status`, `git diff`, `git clean -n` | None for unstaged content; staged content through `git fsck --lost-found`. Appropriate when the working tree is known to be disposable |
| `git push --force`, `git push --force-with-lease` | 🔴 DANGEROUS | Replaces the server's branch; discards commits others pushed | `git fetch`, then `git log HEAD..origin/<branch>` | Another clone's copy; the old ID from the push output or the Activity view. Appropriate for your own unshared branch, with an explicit expected value |
| `git reflog expire --expire=now --all`, `git gc --prune=now` | 🔴 DANGEROUS | Delete the reflogs and every unreachable object | `git fsck --unreachable` lists what would go | None. Appropriate only for purging sensitive data from a clone after rotation |

## 29.15 Version notes

> **Version note.** Older behavior: `git config --list`, `git config --get <key>`. Current behavior: `git config list`, `git config get`, with the old forms still accepted. Since: Git 2.46. Recommended: the subcommands; on an older Git use the dashed options ([Chapter 14B](ch14b-config-tags-signing.md), section 14B.3).

> **Version note.** Older behavior: `git fsck` treated every reflog entry as a starting point. Current behavior: it skips reflog entries dated later than the real clock. Since: Git 2.53.0 (git/git commit `f6b262581a`; [Chapter 3](ch03-git-internals.md), section 3.8). Recommended: remember it when a machine's clock was wrong during an incident.

> **Version note.** Older behavior: Events API `PushEvent` payloads listed the pushed commits. Current behavior: they carry `before`, `head` and `ref`, without commit summaries. Since: 7 October 2025 ([changelog](https://github.blog/changelog/2025-08-08-upcoming-changes-to-github-events-api-payloads/)). Recommended: take the two IDs from the event and read the commits with Git.

## 29.16 Practice

- Labs 35.1 to 35.3 in the [Module 35 lab manual](../lab-manual/m35-diagnosis-method.md): the ten-command diagnosis on three prepared repositories, five operations in progress read from `.git` alone, and "preserve evidence, then fix". Answers are in the [Module 35 lab answers](../solutions/m35-lab-answers.md).
- Replay the two worked cases with `labs/run ch29/case-unfinished-rebase` and `labs/run ch29/case-wrong-upstream`, then work in the sandboxes they leave behind.
- A drill: after the replay of case 1, `rescue/latency-wip` still holds the conflict resolution. With `git log`, `git cherry` and `git range-diff` only, describe what option A would have published.
- Keep the [troubleshooting playbook](../playbooks/troubleshooting-playbook.md) open during the incident drills of Chapter 30.

## 29.17 Interview questions

1. A developer says "my commits are gone". Which commands do you run before you touch anything, in which order, and what does each tell you?
2. `git push` prints "Everything up-to-date" and the commit is not on the server. Give three states that produce this and the command that separates them.
3. Without running `git status`, how do you tell from the `.git` directory whether a merge, a rebase, a cherry-pick, a revert or a bisect is in progress? Name the files.
4. During a rebase, when does the branch ref move, and what follows from that for commits made while the rebase is stopped?
5. What does `git rebase --abort` do to commits created during the stopped rebase and to uncommitted edits? How do you protect each before running it?
6. Compare a backup ref, a copy of the repository and a bundle: what does each preserve, and what does each miss?
7. A push is rejected, `git pull` says "Already up to date", and the push is rejected again. Explain the mechanism and the lowest-risk fix.
8. `main` on GitHub moved backwards overnight. Which evidence exists on your machine, which on GitHub, how long does each last, and which of them identifies the account that pushed?
9. Rank these fixes by risk and justify the order: `git revert`, `git reset --hard` followed by a force push, `git reset --keep`, `git cherry-pick`, a new branch.
10. What does it mean to verify a fix? Give the four checks and an example where the first passes and the third fails.
11. A pull request shows 400 changed files for a two-line change. List four mechanisms and the Git command that tests each one locally.

## 29.18 Sources

**Primary sources**

- The manual pages of Git 2.55.0, read locally with `git help -m <command>`: git-status, git-rebase, git-merge, git-cherry-pick, git-revert, git-bisect, git-bundle, git-update-ref, git-for-each-ref, git-ls-remote, git-merge-tree, git-check-ignore, git-fsck, git-config, gitrevisions, gitrepository-layout.
- `git-prompt.sh` as installed by Homebrew's Git at `/opt/homebrew/etc/bash_completion.d/git-prompt.sh`: the header comments document `__git_ps1`.
- GitHub Docs: [Using the activity view to see changes to a repository](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository); [REST: list repository activities](https://docs.github.com/en/rest/repos/repos#list-repository-activities); [Issue event types](https://docs.github.com/en/rest/using-the-rest-api/issue-event-types); [GitHub event types: PushEvent](https://docs.github.com/en/rest/using-the-rest-api/github-event-types#pushevent); [REST API endpoints for events](https://docs.github.com/en/rest/activity/events); [Viewing insights for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository#viewing-insights-for-rulesets); [Reviewing the audit log for your organization](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization); [Audit log for an enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/security-and-compliance/audit-log-for-an-enterprise); [Deleting and restoring branches in a pull request](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request); [Troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone); [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks).
- GitHub Changelog: [Upcoming changes to GitHub Events API payloads](https://github.blog/changelog/2025-08-08-upcoming-changes-to-github-events-api-payloads/).

**Secondary sources**

- Phase 0 report, sections 12 and 13, and the research notes `github_platform.md`, from which every GitHub-side fact and flag in section 29.8 is taken.
- Yang et al., the ACM TOSEM study of Git-command questions ([author preprint](https://cs.nju.edu.cn/changxu/1_publications/22/TOSEM22.pdf)). The report flags the final volume and article number as not confirmed.

**Videos** (optional; the assessments in the Phase 0 report rest on captions, not on full viewing)

- [How to Undo Mistakes With Git Using the Command Line](https://www.youtube.com/watch?v=lX9hsdsAeTk), Tobias Günther for freeCodeCamp, 55 minutes, 24 November 2020: restore, amend, revert, reset, recovery with the reflog. Caveat: `master` naming.
- [Lecture 5: Version Control and Git](https://www.youtube.com/watch?v=9K8lB61dl3Y), MIT Missing Semester 2026, 1 hour 10 minutes: the data model before the commands, and the reflog as a safety net.

**Further reading**

- [Chapter 13: Recovery](ch13-recovery.md), for every case in which something was lost.
- [Chapter 12: Remote Operations](ch12-remote-operations.md), section 12.14, and [Chapter 16: Authentication](ch16-authentication.md), sections 16.17 to 16.20, for the two other diagnosis procedures of this book.
- [Chapter 18: Branch Protection and Rulesets](ch18-branch-protection.md), section 18.17, "Why can't I merge?".
- The [troubleshooting playbook](../playbooks/troubleshooting-playbook.md).
