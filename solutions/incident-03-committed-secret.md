# Incident 3: a committed secret — solution

> Read this only after your own attempt at [`incidents/03-committed-secret`](../incidents/03-committed-secret/SYMPTOMS.md). Transcripts are real output from `labs/incidents/solve-03-committed-secret.sh`. The string `lab-fixture-not-a-real-password` is a dummy made for this course. Layers: the leak is Git; containment happens at the credential's issuer; what the host keeps is GitHub.

## 1. Symptoms

Ravi committed `.env` with an SMTP password on his feature branch, pushed, deleted the file in a later commit, pushed again, and believes the branch is clean. He would like no noise.

## 2. The order of work

The response has six steps and the first is not a Git command ([Chapter 21B: Repository Security and Secret-Leak Response](../textbook/ch21b-repository-security-incident-response.md), section 21B.14; Phase 0 report, section 14).

| Step | In this incident | Where |
|---|---|---|
| 1. Contain | **Revoke or rotate the SMTP password now**, before any `git` command | The mail provider's console. Not replayable here |
| 2. Assess | Which commits, which refs, since when, who could read it, was it used | Git for the first three; the provider's logs for the last |
| 3. Eradicate | Remove it from current code; rewrite history if warranted | Git, below |
| 4. Recover | Deploy the new credential; realign every clone | The service's secret store; each clone |
| 5. Communicate | Tell the team what to do with their clones; record the incident | Channel, incident record |
| 6. Prevent | `.gitignore`, staging by name, push protection, scanning | Repository and GitHub settings |

Rotation comes first because the damage happens where the password is accepted, not where it is stored. Once the password is revoked, every copy of the commit is harmless, including the copies you cannot reach. GitHub's own guidance says that revoking or rotating may be sufficient and that a history rewrite may not be warranted ([removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)).

## 3. Evidence and scope

<!-- snippet: incidents/solve-03-committed-secret/01-find -->
```text
$ cd you
$ git fetch
From ../server
 * [new branch]      feature/digest-template -> origin/feature/digest-template
 * [new branch]      feature/email-digest    -> origin/feature/email-digest
# Every commit, on any branch, that added or removed the file:
$ git log --all --format='%h %an: %s' -- .env
c5d0303 Ravi Menon: Remove env file
76aa6c4 Ravi Menon: Add SMTP sender
```
<!-- /snippet -->

<!-- snippet: incidents/solve-03-committed-secret/02-scope -->
```text
# Which branches on the server can reach the commit that added it?
$ git branch -r --contains 76aa6c4
  origin/feature/digest-template
  origin/feature/email-digest
# In how many snapshots is the file present?
$ git grep -c SMTP_PASSWORD $(git rev-list --all) -- .env
fdd903cc43054ab432ffc9a7e35df247b713aded:.env:1
76aa6c4fe4793ad6b99759e54fe9b57cea95fc3d:.env:1
# Since when has it been on the server? The pushing clone recorded it:
$ git -C ../ravi reflog show --date=iso origin/feature/email-digest
bb4230f refs/remotes/origin/feature/email-digest@{2026-09-07 10:24:00 +0530}: update by push
fdd903c refs/remotes/origin/feature/email-digest@{2026-09-07 10:19:00 +0530}: update by push
# Is the branch "clean now"? The tip has no .env. The history under the tip has:
$ git cat-file -e origin/feature/email-digest:.env
fatal: path '.env' does not exist in 'origin/feature/email-digest'
[exit status: 128]
$ git show 76aa6c4:.env
SMTP_HOST=smtp.example.com
SMTP_USER=digest@example.com
SMTP_PASSWORD=lab-fixture-not-a-real-password
```
<!-- /snippet -->

Four facts for the incident record. The file was added in `76aa6c4`. It is present in two snapshots, `76aa6c4` and `fdd903c`. Two branches on the server reach it: Ravi's, and Asha's `feature/digest-template`, which she started from his. It reached the server with the push recorded at 10:19, and the push at 10:24 carried the deletion. "The branch is clean now" is true of the tip and false of the history: `git show 76aa6c4:.env` prints the password from any clone.

## 4. Hypotheses

| # | Claim in the report | Test | Result |
|---|---|---|---|
| 1 | "Deleting the file removed it" | `git show <adding commit>:.env` | False. A deletion is a new snapshot; the old one stays |
| 2 | "It was only on my feature branch" | `git branch -r --contains <adding commit>` | False. Two branches |
| 3 | "Private repository, so no exposure" | Who can read the repository, its forks, its CI logs | Everyone with read access could copy it; exposure started at the first push |
| 4 | "A force push will remove it from the server" | `git cat-file -t` on the server after the force push | False, shown in section 7 |

## 5. Root cause

```text
Observed behavior : a production password is readable in the history of two pushed branches
Git state         : .env was untracked and not ignored; "git add ." staged it; the commit was pushed
Mechanism         : "git add ." stages every untracked file that is not ignored; a later deletion adds a snapshot and removes none
Root cause        : a file holding a secret lived in the working tree without an ignore rule, and was staged by a catch-all command
Why Git does this : Git stores snapshots permanently and by content; history is not edited by later commits
Correct fix       : rotate; then remove the file from the two branches' history; then expire the old objects everywhere
Prevention        : .env in .gitignore; stage by name and read "git diff --cached"; push protection and a pre-commit scanner
```

## 6. Is a rewrite warranted here?

After rotation the string unlocks nothing. Three things still argue for a rewrite in this case: the branches are unmerged and have two users, so the cost is small; the file also discloses a host and an account name; and a branch that will be merged into `main` would carry the file into permanent history. Had the commit already been on `main` of a busy repository, the defensible decision could be to rotate, remove the file in a new commit, and not rewrite. Record the decision and its reason either way.

`git filter-repo` is the tool GitHub's documentation prescribes for a whole-repository rewrite. It is not installed in this course's environment, and for one file on one short unmerged branch an interactive rebase is the smaller tool.

## 7. Recovery

The owner of the branch rewrites it. The commit that added the file is edited so that it never contained it; the commit that deleted the file is dropped because it has nothing left to do.

<!-- snippet: incidents/solve-03-committed-secret/03-rewrite -->
```text
$ cd ../ravi
$ git status -sb
## feature/email-digest...origin/feature/email-digest
?? .env
# The rebase will check out the commit that contains .env. Git refuses to overwrite an
# untracked file of the same name, so the local copy is moved out of the repository first.
$ mv .env ../ravi-local.env
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick cb446bd # Add digest builder
pick 76aa6c4 # Add SMTP sender
pick fdd903c # Sort digest events by time
pick c5d0303 # Remove env file
pick bb4230f # Schedule the digest hourly
--- todo list as saved ---
pick cb446bd # Add digest builder
edit 76aa6c4 # Add SMTP sender
pick fdd903c # Sort digest events by time
drop c5d0303 # Remove env file
pick bb4230f # Schedule the digest hourly
Rebasing (2/5)
Stopped at 76aa6c4...  # Add SMTP sender
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
```
<!-- /snippet -->

Had the untracked `.env` stayed in place, the rebase would have stopped with "untracked working tree files would be overwritten". At the `edit` stop:

<!-- snippet: incidents/solve-03-committed-secret/04-amend -->
```text
$ git rm --cached .env
rm '.env'
$ printf '.env\n' >> .gitignore
$ git add .gitignore
$ git commit --amend --no-edit
[detached HEAD 8d98701] Add SMTP sender
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:17:00 2026 +0530
 2 files changed, 7 insertions(+)
 create mode 100644 notify/smtp.py
$ git rebase --continue
Rebasing (3/5)
Rebasing (4/5)
Rebasing (5/5)
Successfully rebased and updated refs/heads/feature/email-digest.
```
<!-- /snippet -->

`git rm --cached` removes the file from the index and leaves it on disk. The ignore rule goes into the same commit, so that no commit of the branch exists without it.

<!-- snippet: incidents/solve-03-committed-secret/05-check-rewrite -->
```text
$ git log --oneline main..feature/email-digest
4397ba9 Schedule the digest hourly
bd86515 Sort digest events by time
8d98701 Add SMTP sender
cb446bd Add digest builder
$ git log --oneline feature/email-digest -- .env
$ git range-diff 'feature/email-digest@{u}'...feature/email-digest
1:  76aa6c4 ! 1:  8d98701 Add SMTP sender
    @@ Metadata
      ## Commit message ##
         Add SMTP sender
     
    - ## .env (new) ##
    + ## .gitignore ##
     @@
    -+SMTP_HOST=smtp.example.com
    -+SMTP_USER=digest@example.com
    -+SMTP_PASSWORD=lab-fixture-not-a-real-password
    + __pycache__/
    ++.env
     
      ## notify/smtp.py (new) ##
     @@
2:  fdd903c = 2:  bd86515 Sort digest events by time
3:  c5d0303 < -:  ------- Remove env file
4:  bb4230f = 3:  4397ba9 Schedule the digest hourly
$ git status -sb --ignored
## feature/email-digest...origin/feature/email-digest [ahead 3, behind 4]
!! .env
```
<!-- /snippet -->

`git range-diff` shows the rewrite commit by commit: the first commit lost `.env` and gained the `.gitignore` line, two commits are unchanged in content (`=`), and the deletion commit is gone (`<`). The file is still on Ravi's disk, now ignored (`!!`).

<!-- snippet: incidents/solve-03-committed-secret/06-publish -->
```text
$ git push --force-with-lease --force-if-includes
To ../server.git
 + bb4230f...4397ba9 feature/email-digest -> feature/email-digest (forced update)
```
<!-- /snippet -->

Asha's branch stands on the old commits. She transplants her one commit onto the rewritten branch. If she merged or pulled instead, she would bring the old commits back.

<!-- snippet: incidents/solve-03-committed-secret/07-dependent-branch -->
```text
$ cd ../asha
$ git fetch
From ../server
 + bb4230f...4397ba9 feature/email-digest -> origin/feature/email-digest  (forced update)
$ git rebase --onto origin/feature/email-digest 'origin/feature/email-digest@{1}' feature/digest-template
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/digest-template.
$ git log --oneline main..feature/digest-template
10f97d4 Add HTML digest template
4397ba9 Schedule the digest hourly
bd86515 Sort digest events by time
8d98701 Add SMTP sender
cb446bd Add digest builder
$ git push --force-with-lease --force-if-includes
To ../server.git
 + 668b910...10f97d4 feature/digest-template -> feature/digest-template (forced update)
```
<!-- /snippet -->

`git rebase --onto <new base> <old base> <branch>` replays the commits after the old base. `origin/feature/email-digest@{1}` is the old base: the value her remote-tracking branch had before the fetch.

Now the claim that a force push removes the data:

<!-- snippet: incidents/solve-03-committed-secret/08-server-still-has-it -->
```text
$ cd ../you
# No ref on the server reaches the old commits now. The objects are still there:
$ git -C ../server.git cat-file -t 76aa6c4
commit
$ git -C ../server.git show 76aa6c4:.env
SMTP_HOST=smtp.example.com
SMTP_USER=digest@example.com
SMTP_PASSWORD=lab-fixture-not-a-real-password
```
<!-- /snippet -->

No ref reaches `76aa6c4`, and the server still serves it to anyone who knows the ID. In the sandbox you are the administrator and can prune:

<!-- snippet: incidents/solve-03-committed-secret/09-server-prune -->
```text
# You are the administrator of this server. On GitHub this step is a request to GitHub Support.
$ git -C ../server.git gc --prune=now
$ git -C ../server.git cat-file -t 76aa6c4
fatal: Not a valid object name 76aa6c4
[exit status: 128]
```
<!-- /snippet -->

> **GitHub, not Git.** You cannot run `git gc` on GitHub. After a rewrite and force push, GitHub states that the old commits can remain reachable in clones and forks, by commit ID in cached views, and through pull requests that reference them; removing them is a request to GitHub Support, quoting the first changed commit and the number of affected pull requests, and Support assists only where rotation cannot mitigate the risk ([removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)). GitHub publishes no retention period for unreachable commits.

Every clone that fetched the branch still has the objects, held by its reflogs:

<!-- snippet: incidents/solve-03-committed-secret/10-clones -->
```text
$ git fetch
From ../server
 + 668b910...10f97d4 feature/digest-template -> origin/feature/digest-template  (forced update)
 + bb4230f...4397ba9 feature/email-digest    -> origin/feature/email-digest  (forced update)
$ git cat-file -t 76aa6c4
commit
# Every clone that ever fetched the branch keeps the objects through its reflogs.
$ for c in you ravi asha; do git -C ../$c reflog expire --expire=now --all && git -C ../$c gc --prune=now; done
$ git cat-file -t 76aa6c4
fatal: Not a valid object name 76aa6c4
[exit status: 128]
```
<!-- /snippet -->

🔴 `git reflog expire --expire=now --all` followed by `git gc --prune=now` destroys the whole safety net of a clone, for every branch, not only for this one. Run it only when the clone has no other unpublished or recently rewritten work. The documented alternative is to delete the clone and clone again ([git-filter-repo manual](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt)).

## 8. Verification

<!-- snippet: incidents/solve-03-committed-secret/11-verify -->
```text
$ git log --all --oneline -- .env
$ git log --oneline --graph --all
* 10f97d4 Add HTML digest template
* 4397ba9 Schedule the digest hourly
* bd86515 Sort digest events by time
* 8d98701 Add SMTP sender
* cb446bd Add digest builder
* 963298b Add README
* 5a2e406 Add notification queue
$ cd ..
$ incidents/03-committed-secret/check.sh
Checking incident 03-committed-secret
  ok    the server still has feature/email-digest
  ok    the server still has feature/digest-template
  ok    feature/email-digest on the server has "Add digest builder"
  ok    feature/email-digest on the server has "Add SMTP sender"
  ok    feature/email-digest on the server has "Sort digest events by time"
  ok    feature/email-digest on the server has "Schedule the digest hourly"
  ok    feature/digest-template on the server has "Add HTML digest template"
  ok    notify/smtp.py is still on feature/email-digest
  ok    no commit reachable from a server ref contains the secret
  ok    the server no longer stores the blob at all
  ok    .gitignore on feature/email-digest lists .env
  ok    no commit reachable from a ref in you/ contains the secret
  ok    you/ no longer stores the blob (reflogs expired and pruned, or re-cloned)
  ok    no commit reachable from a ref in asha/ contains the secret
  ok    asha/ no longer stores the blob (reflogs expired and pruned, or re-cloned)
  ok    no commit reachable from a ref in ravi/ contains the secret
  ok    ravi/ no longer stores the blob (reflogs expired and pruned, or re-cloned)
  note  Git state only. If the credential was not revoked or rotated first, the incident is still open.
PASS: the recovery of incident 03-committed-secret is complete.
[exit status: 0]
```
<!-- /snippet -->

No commit on any ref touches `.env`; the server and all three clones no longer store the blob; both branches keep their work. The check script's last line is the reminder that it sees Git state only.

## 9. Prevention

- `.env` in `.gitignore` from the first commit, and a committed `.env.example` with names and no values.
- `git add <path>` and `git diff --cached` before every commit instead of `git add .`.
- **GitHub:** push protection stops pushes that contain recognised secret formats; for users it has been on by default for public repositories since 29 February 2024, and for private repositories it needs GitHub Secret Protection ([push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection)). It recognises provider token formats. A free-form password like this one matches no pattern, so a scanner is not a substitute for the ignore rule.
- Short-lived credentials where the provider supports them, so that a leaked value expires by itself.

## 10. Communication and postmortem

To Ravi, first: "Thank you for saying so. Rotate the SMTP password now, before anything else; I will handle the Git side with you afterwards."

To the team: "A credential was pushed on `feature/email-digest` at 10:19 and has been rotated. Both digest branches were rewritten. If you fetched either branch today: do not merge or push it; either re-clone, or run `git fetch`, rebase your work onto the new branch, and tell me so that we can clean your clone."

To the CTO: "A production SMTP password was in a private repository for [duration] on two unmerged branches. It was rotated at [time]; the provider's log shows [no use / use from ...] of the old password in that window. History of both branches was rewritten and the old objects removed from the server and all known clones. We are adding the ignore rule to the project template and enabling push protection."

Postmortem points, blameless: the developer reported it himself, which is the behavior to protect; the template repository had no `.env` rule; `git add .` is in the team's README as the way to stage. Severity is decided by what the credential could reach and by the provider's logs, not by how long the Git clean-up took.
