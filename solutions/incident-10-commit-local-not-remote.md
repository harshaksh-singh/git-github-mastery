# Incident 10: a commit exists locally but not remotely — solution

> Read this only after your own attempt at [`incidents/10-commit-local-not-remote`](../incidents/10-commit-local-not-remote/SYMPTOMS.md). Transcripts are real output from `labs/incidents/solve-10-commit-local-not-remote.sh`. Layers: remotes and upstreams are Git; a fork is a GitHub object that Git sees as one more repository.

## 1. Symptoms

The release candidate lacks the NaN fix. Ravi sees the commit at the top of `git log`, `git status` reports "up to date with `origin/main`", and his push printed `main -> main`. Asha cannot find the commit in the team repository.

## 2. Evidence

<!-- snippet: incidents/solve-10-commit-local-not-remote/01-ravi-is-right -->
```text
$ cd ravi
$ git status -sb
## main...origin/main
$ git log --oneline -2
f3bb790 Guard against NaN in score aggregation
133c159 Add accuracy panel
$ git branch -r --contains HEAD
  origin/HEAD -> origin/main
  origin/main
```
<!-- /snippet -->

Everything Ravi said is confirmed. The commit is on `main`, `main` equals `origin/main`, and `origin/main` contains it.

"A commit is on the server" is a statement with a hidden parameter: which server, and which branch on it. A commit can be in three kinds of place: a local branch, a remote-tracking branch (your clone's memory of one remote), and a branch in a remote repository. `git status` speaks about the second.

## 3. Hypotheses

| # | Hypothesis | Test | Result |
|---|---|---|---|
| 1 | The commit was never pushed (rejected push went unnoticed) | `git status -sb` would show `ahead 1` | Not ahead |
| 2 | It was pushed to another branch | `git branch -r --contains HEAD` | It is on `origin/main` |
| 3 | It was made in detached HEAD or on another local branch | `git branch --contains HEAD` | It is on `main` |
| 4 | `origin` is not the repository the team means | `git remote -v` | Confirmed |
| 5 | GitHub shows stale data | `git ls-remote` against the team repository | The server itself lacks it |

[Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md), section 12.14 diagnoses the same symptom with cause 2. The method is the same; the cause here is 4.

## 4. Diagnostic commands

<!-- snippet: incidents/solve-10-commit-local-not-remote/02-which-server -->
```text
$ git remote -v
origin	../ravi-fork.git (fetch)
origin	../ravi-fork.git (push)
upstream	../server.git (fetch)
upstream	../server.git (push)
$ git branch -vv
* main f3bb790 [origin/main] Guard against NaN in score aggregation
$ git reflog show origin/main
f3bb790 refs/remotes/origin/main@{0}: update by push
# Ask each server directly, without relying on any remote-tracking ref:
$ git ls-remote origin main
f3bb79056b4293f31ae8479851be75b1f71339a6	refs/heads/main
$ git ls-remote upstream main
ebd3afc65730975fcbd60abdc9302003fe8e5843	refs/heads/main
```
<!-- /snippet -->

Two remotes. `origin` is `ravi-fork.git`, a fork Ravi made before he had write access to the team repository; `upstream` is `server.git`, the team repository. `main` follows `origin/main`. `git ls-remote` asks each server directly, bypassing every remote-tracking ref: the fork has `f3bb790`, the team repository has `ebd3afc`.

<!-- snippet: incidents/solve-10-commit-local-not-remote/03-team-repository -->
```text
$ git fetch upstream
From ../server
   133c159..ebd3afc  main       -> upstream/main
$ git log --oneline --graph main upstream/main
* f3bb790 Guard against NaN in score aggregation
| * ebd3afc Show p95 latency on the dashboard
|/  
* 133c159 Add accuracy panel
* 6e16f60 Add score aggregation
$ git log --format='%h %an: %s' main..upstream/main
ebd3afc Lab User: Show p95 latency on the dashboard
```
<!-- /snippet -->

After `git fetch upstream` the full picture is visible: the fix and the team's newest commit are siblings. Even a push to the right repository would have been rejected as not fast-forward.

## 5. Root cause

```text
Observed behavior : a commit reported as pushed is absent from the team repository
Git state         : the clone has two remotes; main's upstream is origin/main; origin is a personal fork
Mechanism         : "git push" with no arguments pushes the current branch to its upstream's remote: the fork
Root cause        : "origin" in this clone is not the repository the rest of the team calls origin
Why Git does this : a remote name is a local alias; Git attaches no meaning to "origin" beyond what the clone configured
Correct fix       : publish the commit to the team repository on top of its current main; point main's upstream at it
Prevention        : one meaning of "origin" per team; read the "To" line of every push; verify with ls-remote, not with status
```

## 6. Safe recovery

The team repository has moved, so the fix goes on top of its current `main`, on a branch, as a pull request would require.

<!-- snippet: incidents/solve-10-commit-local-not-remote/04-publish -->
```text
$ git switch -c fix/nan-aggregation
Switched to a new branch 'fix/nan-aggregation'
$ git rebase upstream/main
Rebasing (1/1)
Successfully rebased and updated refs/heads/fix/nan-aggregation.
$ git push -u upstream fix/nan-aggregation
To ../server.git
 * [new branch]      fix/nan-aggregation -> fix/nan-aggregation
branch 'fix/nan-aggregation' set up to track 'upstream/fix/nan-aggregation'.
# What the pull request into main of the team repository would show:
$ git log --oneline upstream/main..upstream/fix/nan-aggregation
d676c20 Guard against NaN in score aggregation
$ git diff --stat upstream/main...upstream/fix/nan-aggregation
 dashboard/aggregate.py | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

The rebase gives the fix a new ID, `d676c20`, with `ebd3afc` as its parent. The pull request view shows one commit and one file.

<!-- snippet: incidents/solve-10-commit-local-not-remote/05-land -->
```text
# The merge of the pull request, simulated as a fast-forward of main on the server:
$ git push upstream fix/nan-aggregation:main
To ../server.git
   ebd3afc..d676c20  fix/nan-aggregation -> main
```
<!-- /snippet -->

> **GitHub, not Git.** On GitHub this step is the merge of the pull request, subject to the rules of `main`. A direct push to a protected `main` would be rejected.

Now the clone, so that the next push goes where Ravi believes it goes:

<!-- snippet: incidents/solve-10-commit-local-not-remote/06-repair-clone -->
```text
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git branch --set-upstream-to=upstream/main main
branch 'main' set up to track 'upstream/main'.
$ git status -sb
## main...upstream/main [ahead 1, behind 2]
# Is anything on my main that the team repository lacks? "-" means it has an equivalent.
$ git cherry -v upstream/main main
- f3bb79056b4293f31ae8479851be75b1f71339a6 Guard against NaN in score aggregation
$ git reset --keep upstream/main
$ git config set remote.pushDefault upstream
$ git branch -vv
  fix/nan-aggregation d676c20 [upstream/fix/nan-aggregation] Guard against NaN in score aggregation
* main                d676c20 [upstream/main] Guard against NaN in score aggregation
```
<!-- /snippet -->

`git cherry -v upstream/main main` prints `-` for the old copy of the fix: the team repository has an equivalent change, so moving `main` loses nothing. `git reset --keep` moves it. `remote.pushDefault = upstream` makes pushes go to the team repository even for branches without an upstream.

## 7. Verification

<!-- snippet: incidents/solve-10-commit-local-not-remote/07-verify -->
```text
$ git ls-remote upstream
d676c206fb0baceaeede6d7fc44a7f94379d26b1	HEAD
d676c206fb0baceaeede6d7fc44a7f94379d26b1	refs/heads/fix/nan-aggregation
d676c206fb0baceaeede6d7fc44a7f94379d26b1	refs/heads/main
$ git log --oneline upstream/main
d676c20 Guard against NaN in score aggregation
ebd3afc Show p95 latency on the dashboard
133c159 Add accuracy panel
6e16f60 Add score aggregation
$ git branch -d fix/nan-aggregation
Deleted branch fix/nan-aggregation (was d676c20).
$ cd ..
$ incidents/10-commit-local-not-remote/check.sh
Checking incident 10-commit-local-not-remote
  ok    main of the team repository has "Add score aggregation" exactly once
  ok    main of the team repository has "Add accuracy panel" exactly once
  ok    main of the team repository has "Show p95 latency on the dashboard" exactly once
  ok    main of the team repository has "Guard against NaN in score aggregation" exactly once
  ok    dashboard/aggregate.py on main filters NaN
  ok    dashboard/panels.py on main still shows p95 latency
  ok    in ravi/, main follows upstream/main (the team repository)
  ok    main in ravi/ equals main of the team repository
PASS: the recovery of incident 10-commit-local-not-remote is complete.
[exit status: 0]
```
<!-- /snippet -->

The team repository's `main` contains both commits, each once. The fork still holds the old copy `f3bb790` on its own `main`; it is harmless, and Ravi can update or delete the fork.

## 8. Prevention

- After a push, the proof is one of: the `To <url>` line of the push output, `git ls-remote <remote> <branch>`, or the commit's page in the team repository. `git status` proves nothing about a server.
- In a fork workflow, name the remotes for what they are and set the defaults once: fetch from the team repository, push to the fork, and open pull requests ([Chapter 12](../textbook/ch12-remote-operations.md), section 12.10; [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md), section 17.15). Without a fork workflow, remove the fork remote.
- A release checklist verifies that a named commit is an ancestor of the release tip: `git merge-base --is-ancestor <commit> origin/main`.

## 9. Communication

To Ravi and Asha: "Every command Ravi quoted was true. His `origin` is his old fork, so the fix was pushed there. It is now on `main` of the team repository as `d676c20`, on top of the p95 change. Ravi's `main` now follows the team repository. Asha: rebuild the release candidate from `d676c20` or later."

To the CTO: "The fix was finished on time and pushed to the wrong repository; the release candidate was built without it. Found by the release manager before release. Corrected in [duration]. We are adding an ancestry check for promised fixes to the release checklist."

## 10. Postmortem

- **Severity:** medium. A release candidate lacked a promised fix; caught before release.
- **What went well:** the release manager checked for a specific commit instead of trusting "it is pushed".
- **Why it made sense:** all local signals were green, and "GitHub is caching" is an explanation that asks nothing of the person offering it.
- **Actions:** the ancestry check in the release checklist; a one-time audit, `git remote -v` in every team member's clone; the handbook states what `origin` means for this team.
