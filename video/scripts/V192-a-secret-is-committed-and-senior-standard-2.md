# V192: A secret is committed, and senior standard 2

- **Part.** 9, Production debugging and incident response
- **Module.** 37, with Module 38
- **Planned minutes.** 22
- **Prerequisites.** V168, V191
- **Textbook sections.** [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.7 and 30.17
- **Demo scripts.** `labs/incidents/solve-03-committed-secret.sh` (snippets `01-find` to `11-verify`)

## HOOK

**[ON SCREEN]** "I deleted the file, so the branch is clean now. It was only my branch, and the repository is private."

Ravi committed an environment file with a password. A commit is one saved snapshot of the project, and a push sends commits to the team's server. He pushed, noticed, deleted the file in a later commit and pushed again. Then he did the one thing in this story that deserves protection: he told someone.

**[ANIMATION]** cards: id=claims question=Three_claims,_none_tested cards=The_branch_is_clean.|It_was_only_his_branch.|The_repository_is_private. ask=1,2,3 marks=1:bad,2:bad,3:bad at_marks=85

**[ANIMATION]** step: 3

His message contains three claims. The branch is clean. It was only his branch. The repository is private. Each claim is a hypothesis, and none of the three has been tested. And while you're reading his message, the password still works. Hold on to those three claims. Each one meets its evidence before the end.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a debrief of Incident 3, [`incidents/03-committed-secret`](../../incidents/03-committed-secret/SYMPTOMS.md). You need to have generated and attempted it, against the clock, and written your message to the team. If you haven't, please stop the video here.

**[PAUSE]**

You know the procedure. Video 166 gave you the six steps, and videos 167 and 168 the mechanics of a rewrite and of the stale clone. This drill is the second scenario of the senior standard, and what it adds is the shape of a real team's repository: a second branch that a colleague based on the first, time pressure, and clones that hold the old objects. A branch is a name for a line of commits, and a clone is one person's copy of the repository. The secret in the sandbox is a dummy string made for the drill, and it says so in its own text.

One thing this video can't show, and neither can any check script: the first step. It isn't a Git command.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Answer "I deleted the file, so the branch is clean" with evidence.
2. Run the response in order and say what must never be claimed before it is verified.
3. Scope the exposure: first commit, first push, refs, tags, dependent branches.
4. Carry out the rewrite where it is warranted and verify every clone.
5. Write the message to the team that says exactly what to do with their clones.

## CONCEPT

**[ANIMATION]** gates: id=order gates=1_Contain:done:at_the_provider:revoke_or_rotate_first|2_Assess:done:-:five_facts_for_the_record|3_Eradicate:done:-:remove,_and_decide_whether_to_rewrite|4_Recover:done:-:deploy_the_new_credential,_remove_the_old_objects|5_Communicate:done:-:the_team_and_the_CTO|6_Prevent:done:-:an_ignore_rule,_push_protection title=The_order_is_fixed at_5=10

**[ANIMATION]** step: setup

**The order is fixed, and its first step is not Git.** Contain, assess, eradicate, recover, communicate, prevent.

**[ANIMATION]** step: 1

**1. Contain: revoke or rotate the credential first.** Revoking cancels the credential, and rotating replaces it with a new one. The damage happens where the secret is accepted, and automated scanners copy fast. Revocation works against every copy, including the ones you can't reach. GitHub's documentation says that revoking or rotating may be sufficient and that a history rewrite may not be warranted. And the sentence to remember under pressure: every `git` command typed before this step is time in which the key still works.

**[ANIMATION]** step: 2

**2. Assess.** Five facts for the record. Which secret, and what it can reach. The first commit, and the time of the first push. Which refs contain it, a ref being a name that points at a commit, such as a branch or a tag. Who could read it. And whether it was used. Git answers the middle three. Whether it was used is answered only by the issuer's logs.

**[ANIMATION]** step: claims.3

Now the three claims of the report. Before the evidence, give your own verdict on each. True or false? Say it out loud.

**[PAUSE]**

**[ANIMATION]** step: claims.marks

The three claims, against the evidence. "The branch is clean now": a deletion removes nothing from history. The tip, the newest commit of the branch, has no file, and the history under the tip has. "It was only my branch": `--contains` decides, and here two branches on the server reach the commit, because a colleague based her work on his. "The repository is private": that limits the audience and doesn't end the exposure. Each claim was a hypothesis, and each is false. That's the opening, answered.

**[ANIMATION]** step: order.3

**3. Eradicate.** Remove the secret from current code, and decide whether to rewrite history. Rewrite when the data stays harmful after rotation, or when the affected history is small and unmerged, as here. Don't rewrite by reflex for a revoked key on a busy `main`: a rewrite costs every collaborator their clone, changes every recorded commit ID and removes signatures.

**[ANIMATION]** graph: id=server 963298b-cb446bd-76aa6c4-fdd903c-c5d0303-bb4230f-668b910 feature/digest-template; bb4230f feature/email-digest; 963298b main; HEAD=main => + cb446bd-8d98701-bd86515-4397ba9 feature/email-digest; say:After_the_forced_push:_new_commits_with_new_IDs => + 4397ba9-10f97d4 feature/digest-template; ghost:76aa6c4,fdd903c,c5d0303,bb4230f,668b910; say:No_branch_reaches_the_old_commits,_and_they_still_exist => + gone:76aa6c4,fdd903c,c5d0303,bb4230f,668b910; cmd:git_gc_--prune=now; say:Pruned_on_the_server; name:pruned title=The_branches_on_the_server

**[ANIMATION]** step: state-1

The documented tool for a whole repository is git-filter-repo 2.47 or later with `--sensitive-data-removal`. It isn't installed here, and one short, unmerged branch needs only an interactive rebase that edits the adding commit and drops the deleting one. A rebase copies commits, and the interactive form lets you edit the list of copies first.

**[ANIMATION]** step: state-2

After the forced push, the rewritten branch is a new row of commits with new IDs, and the colleague's branch still stands on the old ones. A merge or a plain pull from a stale clone brings the old commits back. That was video 168.

**[ANIMATION]** step: state-3

So every branch built on the old commits is transplanted with `git rebase --onto <new> <old> <branch>`.

**[ANIMATION]** step: state-3

**4. Recover.** Deploy the new credential. Then remove the old objects, which a force push doesn't do: in the picture they're dashed, because no branch reaches them, and they still exist.

**[ANIMATION]** step: pruned

In the sandbox you administer the server and run `git gc --prune=now` there. On GitHub that's a request to Support, who need the first changed commit and the number of affected pull requests and who assist only where rotation cannot mitigate the risk. GitHub states that old commits can otherwise stay reachable by ID in cached views, in forks and through pull requests. Each clone keeps the objects through its reflogs until it is re-cloned or its reflogs are expired and its objects pruned.

**[ANIMATION]** step: order.5

**5. Communicate.** The team is told which branches were rewritten and exactly what to do with a clone that fetched them. The CTO is told the exposure window, what the credential could reach, what the issuer's logs show, and that rotation is complete. Concealment is the one choice that makes a leak worse.

**[ANIMATION]** step: order.6

**6. Prevent.** An ignore rule in the project template. Staging by name and reading `git diff --cached`. Push protection, which blocks recognised token formats and not free-form passwords. And short-lived credentials.

**[ANIMATION]** walk: id=never columns=claim,a_statement_about,verified_when rows="Gone":every_repository:no_ref_reaches_it,_and_the_object_no_longer_exists|"Safe":the_issuer:the_old_password_is_rejected mono=off title=Never_claimed_before_it_is_verified

**What must never be claimed before it is verified.** That the secret is gone, and that it is safe. "Gone" is a statement about every repository: no ref reaches a commit with the file, and the object no longer exists, on the server and in each clone. "Safe" is a statement about the issuer: the old password is rejected. Verification of the step that matters is in the provider's console.

**[ANIMATION]** layers: id=cause probe=.env,_staged_by_git_add_. layers=Git:stores_it|the_issuer:accepts_it|GitHub:may_keep_it title=The_root_cause,_in_three_layers

**The root cause.** An unignored file with a secret in the working tree, staged by `git add .`. Layers, three of them. Git stores it. The issuer accepts it. GitHub may keep it.

**[ANIMATION]** end

**Severity.** SEV 1 until rotation is confirmed. Raise the level the moment a secret is involved. Lowering it later costs nothing.

## MENTAL MODEL

**[ANIMATION]** stores: id=key boxes=the_notice_board|the_people_who_copied_it|the_door rows=1:A:a_photograph_of_the_house_key|1:B:copies_of_the_photograph|2:A:taken_down,_the_history_rewrite@ok|2:B:the_copies_stay@bad|3:C:the_lock_is_changed,_the_rotation@ok|3:B:a_picture_of_a_key_that_opens_nothing@dim arrows=1:A1>B1:copied title=The_photographed_key

A picture helps. Think of a house key that was photographed and posted on a notice board. Taking the photograph down is the history rewrite. It's worth doing, and it does nothing about the people who already copied the photograph. Changing the lock is the rotation. After the lock is changed, every copy of the photograph is a picture of a key that opens nothing.

**[ANIMATION]** end

So the order follows from one question, and it's your quiz. Which step works against copies you can't reach: A, taking the photograph down, or B, changing the lock? Your answer?

**[PAUSE]**

B. Only the lock.

**[ANIMATION]** cards: id=places question=A_notice_board_is_one_place._A_Git_repository_is_many. cards=the_server|every_clone_that_fetched|every_branch_built_on_top|on_GitHub,_views_and_refs:only_Support_can_clear

Where the picture breaks: a notice board is one place. A Git repository is many. The photograph is on the server, in every clone that fetched, in every branch built on top, and on GitHub in views and refs that only Support can clear. That's why "taken down" has to be verified per repository.

**[ANIMATION]** end

And the model for the message to the team: write it for the colleague who will read only the commands. If the message says "please be careful with your clones", they will run `git pull`.

## DIAGRAM

**[DIAGRAM]** A new drawing: the six response steps, with the Git commands under the steps that have any, and "at the provider" under the step that has none.

```text
  1 CONTAIN        2 ASSESS              3 ERADICATE             4 RECOVER               5 COMMUNICATE     6 PREVENT
  -------------    ------------------    --------------------    --------------------    --------------    ----------------
  at the           git log --all         remove from current     deploy the new          team: which       ignore rule in
  provider:          -- <path>           code                    credential              branches, and     the template
  revoke or        git branch -r                                 (at the provider)       the exact
  rotate             --contains <id>     where warranted:                                commands for      stage by name;
                   git show <id>:<path>  rewrite the affected    server: prune           their clones      git diff --cached
  (no Git          reflog of the         branches; force-push    (your server: git gc
   command)        pushing clone, for    with a lease; rebase    --prune=now; GitHub:    CTO: window,      push protection
                   the first push        --onto every            Support)                reach, provider   (token formats,
                                         dependent branch                                logs, rotation    not free-form
                   at the provider:                              every clone: expire     complete          passwords)
                   was it used?                                  reflogs and prune,
                                                                 or re-clone                               short-lived
                                                                                                           credentials
```

Point at the first column: no Git command. Point at the last line of the second column: also at the provider. The two questions a CTO cares about most, "does it still work" and "was it used", are both answered outside Git.

## LIVE TERMINAL DEMO

Into the lab. From here on the screen shows the solution. Before the first command, say it aloud as you would in the incident channel: the password has been rotated at the provider, and the old one is rejected.

**[PAUSE]**

In the sandbox there's no provider. In a real incident nothing below starts until that sentence is true.

**[TERMINAL]** Replay `labs/run incidents/solve-03-committed-secret`.

**Find.** 🟢 SAFE.

```bash
git fetch
git log --all --format='%h %an: %s' -- .env
```

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

Two commits on any branch touched the file: `76aa6c4` added it, `c5d0303` removed it. The fetch also shows two new branches. Remember the second one.

Try it now, in any repository of your own. Thirty seconds, and it's read-only: `git log --all --oneline -- .env`. Predict first: does it print anything?

**[PAUSE]**

No output means that no commit on any ref of that clone touches the path. And if it printed commits, you know the order: the first step is at the provider.

**Scope.** Predict: how many branches on the server reach the adding commit? Say it out loud.

**[PAUSE]**

```bash
git branch -r --contains 76aa6c4
git grep -c SMTP_PASSWORD $(git rev-list --all) -- .env
git -C ../ravi reflog show --date=iso origin/feature/email-digest
git cat-file -e origin/feature/email-digest:.env
git show 76aa6c4:.env
```

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

Each line answers one claim. Two branches reach the commit: "only my branch" is false, because Asha's `feature/digest-template` is built on his. Two snapshots contain the file. The pushing clone's reflog, its local list of the values a ref has had, says with dates since when the server has had it: the first push at 10:19. And the last two commands are the answer to "the branch is clean now": the tip has no `.env`, and the history under the tip prints the password.

**Rewrite, in Ravi's clone.** The affected history is small and unmerged, so an interactive rebase is the smaller tool. 🟡 CAUTION: `git rebase -i` replaces the branch's commits with new ones. The old tip stays in the reflog and on the server until the push.

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

One practical detail first: the local `.env` is untracked now, and the rebase will check out a commit that contains a file of that name. Git refuses to overwrite an untracked file, so the local copy is moved out of the repository.

**[ANIMATION]** todo: todo=pick:cb446bd:Add_digest_builder|pick:76aa6c4:Add_SMTP_sender|pick:fdd903c:Sort_digest_events_by_time|pick:c5d0303:Remove_env_file|pick:bb4230f:Schedule_the_digest_hourly edit=pick:cb446bd:Add_digest_builder|edit:76aa6c4:Add_SMTP_sender|pick:fdd903c:Sort_digest_events_by_time|pick:bb4230f:Schedule_the_digest_hourly

Then the todo list: `edit` on the commit that added the file, `drop` on the commit that removed it. The rebase stops at the adding commit.

```bash
git rm --cached .env
printf '.env\n' >> .gitignore
git add .gitignore
git commit --amend --no-edit
git rebase --continue
```

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

The commit is amended so that it never contained the file and adds the ignore rule instead. Then the remaining picks replay.

**Check the rewrite before publishing.**

```bash
git log --oneline main..feature/email-digest
git log --oneline feature/email-digest -- .env
git range-diff 'feature/email-digest@{u}'...feature/email-digest
git status -sb --ignored
```

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

Four commits instead of five. The log for the path is empty. `git range-diff`, which pairs each old commit with its new counterpart, shows the whole operation. The first pair is marked with an exclamation mark, changed, and the inner diff shows the `.env` lines gone and the ignore rule added. Two pairs are equal. And the deleting commit has no counterpart. The local file is now ignored.

**Publish.** 🔴 DANGEROUS: a forced push. What it changes: the server's branch, to the rewritten series. What it can destroy: commits on that branch that are not in this clone. Preview: `git fetch`, then compare. Recovery: the old tip is in this clone's reflog. When appropriate: here, on an unmerged branch, after the team has been told.

<!-- snippet: incidents/solve-03-committed-secret/06-publish -->
```text
$ git push --force-with-lease --force-if-includes
To ../server.git
 + bb4230f...4397ba9 feature/email-digest -> feature/email-digest (forced update)
```
<!-- /snippet -->

**The dependent branch.** Asha's branch still stands on the old commits. If she merges or pulls, the secret is back. In her clone: 🟡 CAUTION, a rebase with `--onto`.

```bash
git fetch
git rebase --onto origin/feature/email-digest 'origin/feature/email-digest@{1}' feature/digest-template
git log --oneline main..feature/digest-template
git push --force-with-lease --force-if-includes
```

Predict: what is the second argument, and where does it come from? Say it out loud.

**[PAUSE]**

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

The new base is the rewritten branch. The old base is the previous value of the remote-tracking branch, her clone's record of the server's branch, read from its reflog: the entry before the forced update. Only her own commit is replayed, and her branch is pushed with a lease.

Quick quiz before the next command. Both branches are rewritten and pushed. Is the old commit A, gone from the server, or B, still stored there? Your answer?

**[PAUSE]**

**The server still has it.**

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

B. No ref on the server reaches the old commits now. The object is still there, and `git show` still prints the password. This is the moment at which nobody may say "it is gone".

<!-- snippet: incidents/solve-03-committed-secret/09-server-prune -->
```text
# You are the administrator of this server. On GitHub this step is a request to GitHub Support.
$ git -C ../server.git gc --prune=now
$ git -C ../server.git cat-file -t 76aa6c4
fatal: Not a valid object name 76aa6c4
[exit status: 128]
```
<!-- /snippet -->

You are the administrator of this server. On GitHub this step is a request to GitHub Support.

**The clones.** 🔴 DANGEROUS: `git reflog expire --expire=now --all` followed by `git gc --prune=now` destroys that clone's entire safety net: every commit and stash that only a reflog was keeping. There is no preview that makes it safe and no undo. It is appropriate only here: purging sensitive data from a clone after rotation, and after each owner has saved their work.

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

Before: `git cat-file -t` still answers `commit` in a clone. Every clone that ever fetched the branch keeps the objects through its reflogs. After: "Not a valid object name".

**Verify.**

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

No commit on any ref touches the path. The graph is one line: Asha's commit on top of the rewritten branch. The check goes through the server and all three clones, for refs and for the blob itself, the object that holds the file's bytes.

Now read the last line of the check before `PASS`. Read it out loud.

**[PAUSE]**

"Git state only. If the credential was not revoked or rotated first, the incident is still open." The check script can't see the provider. Neither can Git.

**The message to the team.** It names the two rewritten branches and gives commands, not advice. Don't pull or merge these branches. Fetch. If you have work on either, replay only your own commits with `git rebase --onto` from the old tip. Then expire and prune, or re-clone. And check that asking for the type of the adding commit fails. Compare it with the message you wrote before the debrief.

**The postmortem line.** Blameless and specific: the developer reported it himself. That behavior is the one to protect.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Starting with Git.** Root cause: the damage happens where the secret is accepted, so every command typed before revocation is time in which the key still works.
2. **Accepting "only my branch".** Root cause: reachability decides, and a colleague's branch built on the commit reaches it too; `git branch -r --contains` shows it.
3. **Saying "it is gone" after the forced push.** Root cause: a forced push moves refs; the objects remain on the server and in every clone until they are pruned.
4. **Rewriting the branch and forgetting the branch built on it.** Root cause: the dependent branch still descends from the old commits, and its next push or merge returns them.
5. **Writing a message that says "be careful".** Root cause: without exact commands a colleague does what they do every morning, and a plain pull merges the old history back.

## PRODUCTION EXAMPLE

**[ANIMATION]** replay: order

**[ANIMATION]** step: 2

Now, out of the lab. A notification service's developer commits an environment file with the SMTP password to a feature branch, pushes, deletes it in the next commit and reports it within the hour. The lead thanks him before anything else, and asks one question: has it been rotated? It hasn't. The next ten minutes are spent in the mail provider's console, not in a terminal. The old password is rejected, and the provider's logs show no use from an unknown address.

**[ANIMATION]** step: 4

Only then the repository. Two branches reach the commit, because a colleague started her template work from his branch that morning. The history is short and unmerged, so the lead decides for a rewrite and records the reason. The developer edits the one commit, the colleague's branch is transplanted with `--onto`, both are pushed with a lease, and the Support request for the unreachable objects and cached views is filed with the first changed commit.

**[ANIMATION]** step: 6

The summary to the CTO has the facts the CTO needs: the exposure window from the first push to rotation, what the credential could reach, what the provider's logs show, and that rotation is complete. The prevention is three lines: `.env` in the project template's ignore file, staging by name, and push protection, with its limit stated: it blocks recognised token formats, not free-form passwords.

## PRACTICE EXERCISE

Your turn. Do Lab 37.5, "A secret is committed (incident 3)", in [`lab-manual/m37-incident-drills-platform.md`](../../lab-manual/m37-incident-drills-platform.md), from a freshly generated sandbox.

Before any Git command, write the first step and who performs it. Then write the five facts of the assessment as five empty lines and fill them as you go, marking which ones Git can answer. Before the forced push, list every branch that depends on the old commits and the command for each. Before you prune a clone, write down what else in that clone the prune will destroy.

The challenge is Lab 38.4, "Senior standard 2, against the clock: a committed secret", in [`lab-manual/m38-communication-postmortems.md`](../../lab-manual/m38-communication-postmortems.md). Time it, and hand your message to a colleague to follow literally.

## INTERVIEW QUESTION

**[ON SCREEN]** Q382: "A colleague says "I deleted the file with the key and pushed, so we are fine". Give the order of the response and say what the deletion did and did not do."

Read the question, then answer out loud.

**[PAUSE]**

A strong answer deals with the deletion in terms of objects and refs: what a commit that removes a file adds to the repository, and what it leaves reachable. It then gives the response in order and explains why the first step comes first with a reason about copies, not about policy. For the Git steps it says what scoping has to establish, including branches other than the author's. It says when a rewrite is warranted and what it costs. And it states plainly which two claims are not made until they are verified, and where each is verified. Begin, as a senior engineer would, by acknowledging that the colleague reported it.

## RECAP

Let's land this. Say each line in your own words.

- The response is contain, assess, eradicate, recover, communicate, prevent, and the first step is at the provider.
- A deletion adds a commit and removes nothing; `--contains` shows every ref that reaches the adding commit, including dependent branches.
- A rewrite is warranted when the data stays harmful after rotation or the affected history is small and unmerged; each dependent branch is then transplanted with `--onto`.
- A forced push leaves the objects on the server and in every clone; they are pruned per repository, and on GitHub by Support.
- "Gone" and "safe" are claimed only after verification: in every repository for the first, at the provider for the second.

## HOMEWORK

Read sections 30.7 and 30.17. Rewrite your message to the team after the debrief so that a colleague who reads only the commands cannot return the secret.

Today you tested three comfortable claims against evidence, and you kept the first step first. Next time is about what you say after an incident: the summary a CTO needs, blameless postmortems, and turning a root cause into a control. Until then, look at the state first and type second. See you in the next one.
