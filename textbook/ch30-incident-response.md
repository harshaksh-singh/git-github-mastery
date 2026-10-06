# Chapter 30: Incident Response

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/incidents/`. GitHub-side steps are described from GitHub's documentation, with links, and were not run.

## 30.1 Why this matters

At some point a message like this arrives: "`main` is broken, the release is in an hour, and nobody knows what happened." The CTO does not want a command. The CTO wants four answers: what happened, how you know, what you changed and how you proved it worked, and why it will not happen again. [Chapter 29: Production Troubleshooting](ch29-production-troubleshooting.md) gave you the method for one repository and one symptom. An incident adds three things the method alone does not cover: other people (whose clones hold evidence and who keep working while you investigate), time pressure (which makes the destructive shortcut attractive), and an audience that has to decide something on the basis of what you tell them.

This chapter has four parts. Sections 30.2 to 30.4 define an incident, a severity scale and the ten practice incidents. Sections 30.5 to 30.14 work through the ten incidents, each built by a script under `incidents/` so that you can attempt it before you read the answer. Sections 30.15 to 30.20 cover the parts that are not Git: the summary for a CTO, the three scenarios that define the senior standard, postmortems, and controls. The remaining sections are the reference tables.

No new Git mechanism is taught here. Every recovery uses techniques from earlier chapters, mostly [Chapter 13: Recovery](ch13-recovery.md), [Chapter 12: Remote Operations](ch12-remote-operations.md) and [Chapter 9: Rebase](ch09-rebase.md). What is new is the order in which you apply them when the report is wrong, the clock is running, and three clones disagree.

## 30.2 An incident, and the loop that handles one

**In one sentence.** An incident is a problem in shared state (a shared branch, a published history, a credential, a pipeline) that other people depend on while you are still working out what it is.

**Analogy.** A ward doctor follows a fixed sequence with an unstable patient: stabilise, record, diagnose, treat, confirm, hand over. The sequence exists because under pressure people skip to treatment. The analogy breaks in two places, both in your favor. A repository can be copied in seconds, so a treatment can be rehearsed on a copy. And Git almost never destroys committed work by itself, so "stabilise" usually means stopping people, not stopping a process.

**Precisely.** The loop has seven stages. It is the root-cause framework of [Chapter 1](ch01-fundamentals.md), section 1.10, with the stages that only exist when other people are involved.

| Stage | What you do | Typical commands | Risk |
|---|---|---|---|
| 1. Stabilise | Stop the damage from spreading: ask people to stop pushing and pulling the affected branch; revoke a leaked credential | none in Git; a message, a provider console | none |
| 2. Preserve | Give every state you may need a name before anything moves | `git branch rescue/<what> <id>`, `git fetch`, a copy of a clone | 🟢 |
| 3. Diagnose | Evidence, at least three hypotheses, one distinguishing command each | `git status -sb`, `git reflog show <ref>`, `git ls-remote`, `git range-diff`, `git log --graph` | 🟢 |
| 4. Recover | The change that destroys least and is simplest to undo | `git cherry-pick`, `git merge`, `git reset --keep`, `git push --force-with-lease=<ref>:<expect>` | 🟡, sometimes 🔴 |
| 5. Verify | Re-run the commands that showed the problem; run the check the affected system runs | `git merge-base --is-ancestor`, `git diff --stat`, `git ls-remote` | 🟢 |
| 6. Communicate | Tell the team what to do with their clones; tell the CTO the four answers | none | none |
| 7. Prevent | Turn the root cause into a control, and write the postmortem | a ruleset, a configuration default, a test, a checklist line | none |

Two rules hold the loop together. Stages 2 and 3 use only commands that add refs or read state. And stage 6 starts early: a first message goes out as soon as you know which branch people must leave alone, long before you know the cause.

**Inside `.git`.** In an incident the evidence is spread over several repositories, and each kind lives in a specific place.

| Evidence | Where it lives | Read it with | Lifetime |
|---|---|---|---|
| Every value a local branch had | `.git/logs/refs/heads/<branch>` in that clone | `git reflog show <branch>` | 90 days; 30 for entries no longer reachable; gone when the branch is deleted |
| Every commit HEAD was on | `.git/logs/HEAD` | `git reflog` | same; survives branch deletion |
| What the server's branch was at each fetch or push **from this clone** | `.git/logs/refs/remotes/origin/<branch>` | `git reflog show origin/<branch>` | same; gone when the ref is pruned |
| What the server holds now | the server | `git ls-remote origin` | current value only |
| Staged content that was never committed | a dangling blob in `.git/objects` | `git fsck --lost-found` | two weeks after it becomes unreachable, once maintenance runs |
| Who pushed what, and force pushes | GitHub, not Git | the Activity view, `PushEvent` records, the audit log | see section 30.6 |

The retention periods are Git's defaults ([Chapter 13](ch13-recovery.md), section 13.4); the lab configuration switches reflog expiry off. A bare repository, which is what a server holds, keeps no reflog unless `core.logAllRefUpdates` is set. So the history of a server-side branch exists only as the sum of what the clones remember, plus whatever the hosting platform records. That is why "preserve" includes asking colleagues not to run `git fetch --prune`, `git gc` or a re-clone until you have read their reflogs.

**See it.** Sections 30.5 to 30.14 are this loop run ten times, with real transcripts. The shortest complete example is incident 2 in section 30.6: one message, one fetch, two reflogs, two pushes.

**Picture.**

```text
   report            evidence in three places                         one shared state
  --------          --------------------------                       ------------------
  "main is    -->   your clone     reflog of origin/main   ---+
   broken"          Asha's clone   reflog of her branch    ---+-->   server.git : refs/heads/main
                    Ravi's clone   has not fetched yet     ---+        (no reflog of its own)
                    GitHub         Activity view, audit log

   1 stabilise --> 2 preserve --> 3 diagnose --> 4 recover --> 5 verify --> 6 communicate --> 7 prevent
        |               🟢             🟢          🟡 / 🔴         🟢              ^
        +--------------------- first message to the team ------------------------+
```

**In production.** An ML platform team deploys an inference service from the branch `production`. The deploy job refuses to run. Stage 1 is one sentence in the channel: "Nobody pushes to or resets `production` until I say so." Everything after that is incident 4 in section 30.8.

## 30.3 Severity

Severity decides who is told and how fast, not how interesting the Git problem is. The scale below is a working scale for repository incidents, to be adapted to your organisation's own. It asks three questions: which state was affected, could wrong code or a secret have reached users or outsiders, and is anything unrecoverable.

| Level | Definition | Examples from this chapter | Who is told, when |
|---|---|---|---|
| SEV 1 | A secret that unlocks production was exposed, or wrong code reached production, or shared history is unrecoverable | A live credential pushed anywhere (incident 3 before rotation); a rewritten production branch that was deployed | CTO and security at once; updates on a fixed rhythm |
| SEV 2 | A shared default or release branch held wrong content, or a merged fix was silently lost; caught before or shortly after release | Incidents 2, 4 and 9 | Engineering lead at once; CTO in the summary |
| SEV 3 | A team is blocked or a pull request is unreviewable; no wrong content on a protected branch | Incidents 5, 6, 7 and 10 | The team; lead on request |
| SEV 4 | One person's local work | Incidents 1 and 8 | The person; nobody else unless a habit needs changing |

Three rules for using a scale. Assign the level on what could have happened in the window, not only on what did: incident 4 shipped nothing and is still SEV 2, because the only thing between the rewritten branch and production was one check. Raise the level the moment a secret is involved; lowering it later costs nothing. And never let severity depend on who caused the incident.

## 30.4 The ten incidents, and how to run them

Each incident is a directory under [`incidents/`](../incidents/README.md) with a generator, a symptom report and a check script. The generator builds a bare repository `server.git` in the role of the server and clones named `you`, `asha` and `ravi`.

```bash
incidents/02-force-push-wrong-branch/generate.sh     # prints the path of the sandbox
labs/shell "<that path>"                             # work in it; read SYMPTOMS.md first
incidents/02-force-push-wrong-branch/check.sh        # exit status 0 when the recovery is complete
```

The generator runs with the fixed lab clock, so the commit IDs in your sandbox are the IDs printed in this chapter. Attempt an incident before you read its section: a diagnosis you have read cannot be made again.

| # | Incident | Mechanism | Layer of the cause | Decisive evidence | Recovery | Control |
|---|---|---|---|---|---|---|
| 1 | Accidental `git reset --hard` | A branch ref moved; index and working tree overwritten | Git | Branch reflog; `git fsck --lost-found` | Anchor, `cherry-pick`, restore the blob | `git restore`, `reset --keep`, push early |
| 2 | Force push to the wrong branch | `push.default=upstream` plus `--force` | Git configuration; no GitHub rule | Reflog of `origin/main`; `git branch -vv` in the pushing clone | New branch for the stray commits; restore with an explicit lease | Block force pushes on `main` |
| 3 | Committed secret | A deletion adds a snapshot and removes none | Git; issuer; GitHub retention | `git log --all -- <path>`; `git branch -r --contains` | Rotate first; rewrite; prune everywhere | Ignore rule, push protection |
| 4 | Production history rewritten | Interactive rebase plus `--force`; one commit dropped | Git; no GitHub rule | The deploy tag; tree diff of old and new tip | Restore, carry the newer commit over, realign clones | Ruleset on the production branch |
| 5 | Shared branch rebased | A merge pull joined the old and the rebased series | Git | The two reflogs; `git range-diff` | Replay only the unpublished commits onto the rebased tip | `pull.rebase`, agreement before a rewrite |
| 6 | Pull request shows 500 changes | Another branch merged into the head branch | Git; GitHub displays it | `git log --merges main..head` | Rebuild the head without the merge | Update only from the base |
| 7 | CI passes locally, fails on Actions | Shallow clone without tags | GitHub Actions (a checkout default) | The failed step's one line; a depth-1 clone | `fetch-depth: 0` | Review tools with their inputs |
| 8 | Branch appears to have disappeared | Squash merge, head branch deleted, prune, `-D` | GitHub; Git | HEAD reflog; tree diff against `main` | Anchor; cherry-pick the unmerged commit | New branch after every merge |
| 9 | Misunderstood merge conflict | `--ours` for a whole file | Git | `git show --remerge-diff` | One forward commit | Resolve hunks; review merges |
| 10 | Commit local, not remote | Two remotes; `origin` is a fork | Git | `git remote -v`; `git ls-remote` | Publish to the team repository; fix the upstream | One meaning of `origin` |

Sections 30.5 to 30.14 use the same ten headings for every incident: symptoms, evidence, hypotheses, diagnostic commands, root cause, safe recovery, verification, prevention, communication, postmortem. The complete transcripts, with every step, are in `solutions/incident-NN-<slug>.md`. Incidents 3, 5 and 7 are the three scenarios of the senior standard; their sections here are summaries, and sections 30.16 to 30.18 work through them in full.

## 30.5 Incident 1: a developer runs `git reset --hard` by accident

**Symptoms.** Ravi: "I think `git pull` ate my work." Three or four commits of Friday are missing from `git log`; he "reset to what is on the server"; a new file had been added; an edit was in progress; he has committed once since. (`incidents/01-hard-reset`)

**Evidence.** `git status -sb` prints `## feature/escalation-rules` with no upstream, so there is no "this branch on the server". The branch reflog is the record:

<!-- snippet: incidents/solve-01-hard-reset/02-reflog -->
```text
$ git reflog show feature/escalation-rules
4e4c0b7 feature/escalation-rules@{0}: commit: Mention escalation in the README
2876d93 feature/escalation-rules@{1}: reset: moving to origin/main
0322a16 feature/escalation-rules@{2}: commit: Never escalate spam
a26c697 feature/escalation-rules@{3}: commit: Route escalated tickets to the on-call queue
95d110d feature/escalation-rules@{4}: commit: Add escalation predicate
44fa655 feature/escalation-rules@{5}: branch: Created from HEAD
# Ravi suspects "git pull". Does the HEAD reflog record a pull at all?
$ git reflog | grep -c pull
0
[exit status: 1]
```
<!-- /snippet -->

**Hypotheses.** (1) A pull rewrote the branch: no `pull` line exists, the count is 0. (2) The commits were made elsewhere: no, three `commit:` lines are in this branch's reflog. (3) A reset moved the branch away from them: `@{1}` says `reset: moving to origin/main`.

**Diagnostic commands.** `git status -sb`, `git branch -vv`, `git reflog show <branch>`, then `git fsck --lost-found` for content that was staged and never committed.

**Root cause.** Ravi wanted to discard one edit and used a command that moves the branch, replaces the index and overwrites the working tree. `origin/main` was not his branch's counterpart; no counterpart existed. Layer: Git, one laptop.

**Safe recovery.** The lost work sits on three layers with three different answers.

| What | Where Git has it | Recoverable |
|---|---|---|
| Three commits | reachable from the branch reflog, `@{2}` | yes |
| `rules/priority.yaml`, staged, never committed | a dangling blob | yes, as content without a name |
| The unstaged edit to `rules/routing.yaml` | nowhere | no |

Anchor first with `git branch rescue/before-reset 'feature/escalation-rules@{2}'`. Moving the branch back to `0322a16` would discard the commit made after the reset, so the three commits are added on top instead: `git cherry-pick origin/main..rescue/before-reset` 🟡. The staged file comes from the object database:

<!-- snippet: incidents/solve-01-hard-reset/04-staged -->
```text
$ git fsck --lost-found
dangling blob 959c2056cb4f78bc321cf5bcf50cf2bf42d049bd
$ ls .git/lost-found/other
959c2056cb4f78bc321cf5bcf50cf2bf42d049bd
$ git cat-file -p 959c205
outage: 1
billing: 2
how-to: 3
```
<!-- /snippet -->

`git cat-file -p 959c205 > rules/priority.yaml` writes it back. A blob has no file name; the name was in the index entry that the reset removed.

**Verification.** `git range-diff origin/main rescue/before-reset HEAD` shows three `=` pairs: each copy carries the same change as its original. The rescue branch is deleted only after that.

**Prevention.** `git restore <path>` discards an edit to one file. `git reset --keep` moves a branch and refuses to overwrite local changes ([Chapter 11: Reset, Revert, Restore](ch11-reset-revert-restore.md), section 11.6). A branch pushed on its first day has a second copy.

**Communication.** To Ravi: what is back (three commits, one file as untracked content), what is not (the unstaged edit, which Git never stored), and that `git pull` was not involved. Nobody else needs a message. SEV 4.

**Postmortem.** One line in the team notes: `reset --hard` is not "undo". The unrecoverable part was the part that was never given to Git.

## 30.6 Incident 2: a developer force-pushes to the wrong branch

**Symptoms.** `main` on the server ends in "WIP ... tests still red"; a merged commit is gone from its log. Asha pushed "only my branch" after an amend. Your `git status` says up to date. (`incidents/02-force-push-wrong-branch`)

**Evidence.** `git status` reports on `origin/main`, your clone's memory. `git ls-remote origin` asks the server, and the server's `main` is a commit your clone has never seen. After a fetch:

<!-- snippet: incidents/solve-02-force-push-wrong-branch/02-fetch -->
```text
$ git fetch
From ../server
 + ca03e42...b4554be main       -> origin/main  (forced update)
$ git status -sb
## main...origin/main [ahead 2, behind 2]
$ git reflog show origin/main
b4554be refs/remotes/origin/main@{0}: fetch: forced-update
ca03e42 refs/remotes/origin/main@{1}: update by push
27215c8 refs/remotes/origin/main@{2}: pull: fast-forward
f273cd3 refs/remotes/origin/main@{3}: update by push
```
<!-- /snippet -->

`origin/main@{1}` is the value before the event. `git log origin/main..'origin/main@{1}'` lists what the server lost (two reviewed commits), and the reverse range what it gained (Asha's two WIP commits).

**Hypotheses.** (1) Her branch was merged into `main`: then the reviewed commits would still be there. (2) Someone reset `main` deliberately: no clone's local `main` moved. (3) Her push of `feature/dedupe` went to `main`.

**Diagnostic commands.** Look at the clone that pushed:

<!-- snippet: incidents/solve-02-force-push-wrong-branch/04-cause -->
```text
# Why did a push from feature/dedupe move main? Look at the clone that pushed.
$ git -C ../asha branch -vv
* feature/dedupe b4554be [origin/main] WIP config flag and readable dedupe, tests still red
  main           f273cd3 [origin/main: behind 2] Add row validation
$ git -C ../asha config get --show-origin push.default
file:.git/config	upstream
$ git -C ../asha reflog show origin/main
b4554be refs/remotes/origin/main@{0}: update by push
```
<!-- /snippet -->

**Root cause.** `feature/dedupe` was created from `origin/main` and so has `origin/main` as upstream. With `push.default=upstream`, a bare `git push` updates the upstream branch whatever its name; `--force` removed the fast-forward check; the server accepted a forced update of `main`. The default, `simple`, would have refused ([Chapter 12](ch12-remote-operations.md), section 12.5). Layers: Git configuration in one clone, and a missing GitHub rule.

**Safe recovery.** First confirm that your `origin/main@{1}` is the newest good value: Ravi's unfetched `origin/main` must be its ancestor. Then two pushes in this order.

```bash
git push origin origin/main:refs/heads/feature/dedupe     # 🟢 additive: Asha's commits get their own branch
```

<!-- snippet: incidents/solve-02-force-push-wrong-branch/06-restore -->
```text
$ git push --force-with-lease=main:b4554be origin rescue/main-before-force:main
To ../server.git
 + b4554be...ca03e42 rescue/main-before-force -> main (forced update)
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

🔴 A forced update of `main`. It is appropriate here because the commits being removed are unreviewed, now live on their own branch, and nobody built on them. The lease `main:b4554be` makes it conditional: if anyone pushed to `main` meanwhile, it is refused. Had someone already built on the bad tip, the right move would be `git revert` of the two commits. In Asha's clone: `git branch --set-upstream-to=origin/feature/dedupe feature/dedupe` and `git config unset push.default`.

**Verification.** `git ls-remote origin` shows `main` at `ca03e42` and `feature/dedupe` at `b4554be`.

**Prevention.**

> **GitHub, not Git.** "Block force pushes" in a ruleset on the default branch rejects this push; it is enabled by default in a new ruleset ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#block-force-pushes); [Chapter 18: Branch Protection and Rulesets](ch18-branch-protection.md)). When no clone has the old value, GitHub offers instruments of its own: the repository's [Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository) lists force pushes with the user and a comparison, a `PushEvent` in the [Events API](https://docs.github.com/en/rest/activity/events) carries the `before` ID (last 300 events and 30 days), and the [references API](https://docs.github.com/en/rest/git/refs#create-a-reference) can create a branch at that ID:
>
> ```bash
> gh api repos/OWNER/REPO/git/refs -f ref=refs/heads/recovered -f sha=<commit ID from before the force push>
> ```
>
> **Unverified.** GitHub documents each instrument and not this combined procedure, publishes no retention period for commits that no ref reaches, and documents no "restore" action inside the Activity view (Phase 0 report, section 13). GitHub's own advice is the plain Git route: ask a collaborator who still has the commit to push it ([troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone)).

**Communication.** At once: nobody pulls or pushes `main`. After the restore: `git fetch`, then `git status -sb`; a clone whose `main` shows `ahead` stops and asks. To the CTO: `main` pointed at unreviewed work for a stated number of minutes, nothing was lost, the rule goes on today. SEV 2.

**Postmortem.** The timeline comes from three clones' reflogs of `origin/main`, because the server kept none. The `(forced update)` line was printed and read as normal.

## 30.7 Incident 3: a secret is committed

**Symptoms.** Ravi committed `.env` with a password, pushed, deleted the file in a later commit, pushed again: "the branch is clean now, it was only my branch, the repository is private." (`incidents/03-committed-secret`; the string is a dummy.)

**Evidence.** `git log --all -- .env` finds the adding and the deleting commit; `git branch -r --contains 76aa6c4` lists two branches on the server, because Asha based her work on his.

**Hypotheses.** Each claim in the report is a hypothesis, and each is false: a deletion removes nothing from history; two branches reach the commit; "private" limits the audience and does not end the exposure.

**Diagnostic commands.** `git log --all -- <path>`, `git branch -r --contains <commit>`, `git show <commit>:<path>`, and the pushing clone's `git reflog show --date=iso origin/<branch>` for the time of the first push.

**Root cause.** An unignored file with a secret in the working tree, staged by `git add .`. Layers: Git stores it; the issuer accepts it; GitHub may keep it.

**Safe recovery.** Rotate the credential first, before any Git command. Then assess, rewrite the two unmerged branches, prune the old objects on the server and in every clone. Section 30.17 works through all six steps.

**Verification.** No ref in any repository reaches a commit with the file, and `git cat-file -t 76aa6c4` fails everywhere. Verification of the step that matters is in the provider's console: the old password is rejected.

**Prevention.** `.env` in `.gitignore`; staging by name; push protection for recognised formats.

**Communication.** The team gets exact instructions for their clones; the CTO gets the exposure window and what the provider's logs show. SEV 1 until rotation is confirmed.

**Postmortem.** Blameless and specific: the developer reported it himself. That behavior is the one to protect.

## 30.8 Incident 4: production branch history is rewritten

**Symptoms.** The release job refuses to deploy: the tagged, running commit is not an ancestor of `production`. Asha saw "diverged" without local commits, reset to the server on advice, and shipped a commit on top. Ravi "tidied" history: "same code, fewer commits". A finance ticket reports unrounded tax amounts. (`incidents/04-production-history-rewritten`)

**Evidence.** After `git fetch`, your untouched `production` is `ahead 4, behind 2`: the server's branch was replaced. Three independent witnesses name the old tip:

<!-- snippet: incidents/solve-04-production-history-rewritten/02-witnesses -->
```text
# Three independent records of the old tip: my branch, the reflog of origin/production, the tag.
$ git rev-parse production 'origin/production@{1}' 'deploy-2026-09-07^{commit}'
3277739ce8e6fd4a425fdae7a124985414b5dd36
3277739ce8e6fd4a425fdae7a124985414b5dd36
3277739ce8e6fd4a425fdae7a124985414b5dd36
$ git merge-base --is-ancestor deploy-2026-09-07 origin/production
[exit status: 1]
$ git log --format='%h %an, committed by %cn: %s' production..origin/production
4fae70f Asha Rao, committed by Asha Rao: Add invoice PDF footer
f2783aa Lab User, committed by Ravi Menon: Tax calculation, formatting and logging
```
<!-- /snippet -->

The last line also shows who did what. The folded commit keeps its original author and names Ravi as committer: in rewritten history, read `%cn` and the reflogs, not the author.

**Hypotheses.** (1) The tag was moved: no, it still names the tip every clone had. (2) The branch was reset to an older commit: no, the two new commits are not ancestors of anything old. (3) Rewritten with identical content: rewritten, yes; identical is a claim about trees, and it can be tested.

**Diagnostic commands.**

<!-- snippet: incidents/solve-04-production-history-rewritten/04-tree-diff -->
```text
# "Same code, fewer commits" is a claim about trees. Compare the trees:
$ git diff --stat production origin/production
 billing/pdf.py | 2 ++
 billing/tax.py | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git diff production origin/production -- billing/tax.py
diff --git a/billing/tax.py b/billing/tax.py
index 66a2912..0fce8dc 100644
--- a/billing/tax.py
+++ b/billing/tax.py
@@ -1,2 +1,2 @@
 def tax(amount, rate):
-    return round(amount * rate, 2)
+    return amount * rate
```
<!-- /snippet -->

`billing/pdf.py` is Asha's new commit. `billing/tax.py` lost its rounding: the interactive rebase dropped the commit "Round tax to two decimals" when a line of the todo list was deleted. That is the finance ticket.

**Root cause.** A branch that deployment records refer to by commit ID accepted a forced update. The rewrite created new commits and lost one; `--force` replaced the server's ref; "reset to the server" then made a second clone adopt the rewrite. Layers: Git, and a missing GitHub rule.

**Safe recovery.** Two routes: keep the rewritten history and re-add the fix (no further force, but the deployed tag is never an ancestor again and every recorded ID points off-branch), or restore the old history and carry the one newer commit over. For a branch whose IDs are recorded elsewhere, restore.

```bash
git branch --no-track rescue/production-rewritten origin/production      # 🟢 name the state about to be replaced
git switch production && git cherry-pick origin/production               # 🟡 Asha's commit onto the real history
git push --force-with-lease=production:4fae70f origin production         # 🔴 conditional on the server's current value
```

Each clone that adopted the rewrite then proves that nothing of its own is lost before it moves:

<!-- snippet: incidents/solve-04-production-history-rewritten/07-realign -->
```text
$ cd ../asha
$ git fetch
From ../server
 + 4fae70f...a323df1 production -> origin/production  (forced update)
$ git status -sb
## production...origin/production [ahead 2, behind 5]
# Is anything of mine missing from the server? "-" means the server has an equivalent change.
$ git cherry -v origin/production production
+ f2783aa72335f59cef8731e0d5ed00dda990cd72 Tax calculation, formatting and logging
- 4fae70f86a56f9c739bd55c2e9830f4fba9145da Add invoice PDF footer
$ git reset --keep origin/production
$ cd ../ravi
$ git fetch
From ../server
 + f2783aa...a323df1 production -> origin/production  (forced update)
$ git cherry -v origin/production production
+ f2783aa72335f59cef8731e0d5ed00dda990cd72 Tax calculation, formatting and logging
$ git reset --keep origin/production
```
<!-- /snippet -->

`git cherry -v` marks with `-` a local commit whose change the server already has. The only `+` is the commit being retired on purpose.

**Verification.** `git merge-base --is-ancestor deploy-2026-09-07 origin/production` exits 0: the release job's own test. `git show origin/production:billing/tax.py` has the rounding.

**Prevention.** A ruleset on `production`: block force pushes, restrict deletions, require a pull request, empty bypass list ([Chapter 18](ch18-branch-protection.md), section 18.18). In the handbook: "diverged, and I made no commits" means the server's history was replaced; stop and ask.

**Communication.** To the team: the new tip, and the two commands (`git cherry -v`, then `git reset --keep`) with the rule for any unexpected `+`. To the CTO: nothing bad was deployed because the release job refused; a dropped fix was caught; the missing rule goes on today. SEV 2.

**Postmortem.** The control that worked was an automated ancestry check. The control that was missing was one checkbox. The advice "reset to the server" turned one affected clone into two.

## 30.9 Incident 5: a developer rebases a shared branch

**Symptoms.** A pull request lists nine commits where it should list five; Asha's appear twice; a merge commit nobody intended joins them; the changed files look as before. Asha rebased and force-pushed with a lease. You ran `git pull` and pushed. (`incidents/05-rebased-shared-branch`)

**Evidence.** The commit list `main..head` has nine entries; the diff `main...head` has the same three files as before, because two copies of one change are one change in a tree.

**Hypotheses.** (1) A display problem on GitHub: `git ls-remote` and a local `git log` show the nine commits are real. (2) Someone undid the rebase: the rebased commits are all present. (3) The old series was merged with the rebased one.

**Diagnostic commands.** `git reflog show <branch>` and `git reflog show origin/<branch>` side by side; `git range-diff` between the old and the rebased series; `git config get pull.rebase`.

**Root cause.** Commits that another person had built on were rewritten, and that person's `git pull`, configured to merge, joined both versions. `--force-with-lease` is not at fault: it protects the server's commits, not the unpublished commits in a teammate's clone. Layer: Git.

**Safe recovery.** Keep the rebased series, replay only the unpublished commits onto it, publish with an explicit lease. Section 30.16 does this in the eleven steps.

**Verification.** Five commits, each subject once, no merge commit; the tree is identical to the tree before the repair.

**Prevention.** `pull.rebase true` or `pull.ff only`; a rewrite of a shared branch is announced with the command teammates need.

**Communication.** To Asha: nobody undid the rebase; `git pull --ff-only` brings her up to date. To reviewers: the diff never changed. SEV 3.

**Postmortem.** A pull that printed no error produced a nine-commit history, and it was pushed without a look at the graph.

## 30.10 Incident 6: a pull request suddenly shows 500 unrelated changes

**Symptoms.** Ravi pushed one small commit; his pull request went from three commits and two files to 500+ files and commits by Asha. He suspects a rewritten `main` or a changed base. The approval still stands. (`incidents/06-pr-500-changes`; the pull request is simulated as `main..head` and `main...head`, which is what GitHub computes, [Chapter 17: Pull Requests](ch17-pull-requests.md), section 17.3.)

**Evidence.**

<!-- snippet: incidents/solve-06-pr-500-changes/01-pull-request-view -->
```text
$ cd you
$ git fetch
From ../server
 * [new branch]      develop    -> origin/develop
 * [new branch]      feature/snippet-highlight -> origin/feature/snippet-highlight
# The commit list of the pull request, and the size of its diff:
$ git log --format='%h %an: %s' origin/main..origin/feature/snippet-highlight
5dc3109 Ravi Menon: Highlight every query term
461c3ea Ravi Menon: Merge branch 'develop' of ../server into feature/snippet-highlight
f94e7f0 Ravi Menon: Escape HTML in snippets
6d230a6 Ravi Menon: Test snippet highlighting
bdb4a59 Ravi Menon: Add snippet highlighting
069daa8 Asha Rao: Switch the tokenizer to ICU word breaking
5f0c2ae Asha Rao: Regenerate golden fixtures
796fd96 Asha Rao: Add golden fixture generator
$ git diff --shortstat origin/main...origin/feature/snippet-highlight
 504 files changed, 517 insertions(+), 1 deletion(-)
$ git diff --dirstat=files,5 origin/main...origin/feature/snippet-highlight
  99.2% tests/golden/
```
<!-- /snippet -->

**Hypotheses.** The documented causes of an oversized pull request are listed in Chapter 17, section 17.12. Three fit the report. (1) `main` was rewritten: the reflog of `origin/main` has one entry and the merge base equals the tip of `main`. (2) The head branch was force-pushed: the pushing clone's reflog shows two ordinary pushes. (3) Another branch was merged into the head branch.

**Diagnostic commands.**

<!-- snippet: incidents/solve-06-pr-500-changes/03-merge -->
```text
# Hypothesis 3: another branch was merged into the head branch.
$ git log --merges --format='%h %an: %s%n        parents: %p' origin/main..origin/feature/snippet-highlight
461c3ea Ravi Menon: Merge branch 'develop' of ../server into feature/snippet-highlight
        parents: f94e7f0 069daa8
$ git log --oneline --graph origin/main..origin/feature/snippet-highlight
* 5dc3109 Highlight every query term
*   461c3ea Merge branch 'develop' of ../server into feature/snippet-highlight
|\  
| * 069daa8 Switch the tokenizer to ICU word breaking
| * 5f0c2ae Regenerate golden fixtures
| * 796fd96 Add golden fixture generator
* f94e7f0 Escape HTML in snippets
* 6d230a6 Test snippet highlighting
* bdb4a59 Add snippet highlighting
```
<!-- /snippet -->

The merge commit `461c3ea` has the tip of `develop` as second parent. `git log --first-parent` shows the branch as Ravi experienced it, four commits and a merge, which is why "one small commit" felt true. His reflog names the command: `pull --no-rebase origin develop`.

**Root cause.** A topic branch aimed at `main` was updated from `develop`, an unreleased long-running branch. A merge makes every commit of the merged branch an ancestor of the result, and a pull request lists everything reachable from the head and not from the base. Layer: Git. GitHub displayed the branch correctly.

**Safe recovery.** The tempting fix is `git revert -m 1 461c3ea`: no forced push, and the diff shrinks. It is wrong here. The commits of `develop` stay ancestors of the branch, so the commit list stays long; and once this branch is merged, `main` contains those commits together with a commit that undoes them, so the later release of `develop` brings nothing: the re-merge problem of [Chapter 11](ch11-reset-revert-restore.md), section 11.9. A reverted merge is not a removed merge. The branch has one author, so it is rebuilt:

```bash
git branch rescue/with-develop                       # 🟢 anchor the current tip
git rebase --onto 461c3ea^1 461c3ea                  # 🟡 replay what came after the merge onto its first parent
git push --force-with-lease --force-if-includes      # 🔴 for a topic branch with one author: appropriate
```

**Verification.** `git log origin/main..<head>` lists four commits, `git diff --stat origin/main...<head>` two files, and `git merge-base --is-ancestor origin/develop <head>` exits 1.

**Prevention.** Update a topic branch from the branch it will be merged into, and name that branch in the command. Reviewers read the commit list, not only the files.

> **GitHub, not Git.** Whether an approval survives a push depends on the rules: "dismiss stale pull request approvals" removes it when the diff changes ([Chapter 17](ch17-pull-requests.md), section 17.5). Here an approval given to two files stood on 504. Treat it as void and review again.

**Communication.** To Ravi: GitHub showed what the branch contained; the reflog line; the last commit has a new ID. To the lead: the near miss is the standing approval, not the file count. SEV 3.

**Postmortem.** Nothing was merged. Had it been, 500 fixtures and an unreleased tokenizer would have reached `main` under an approval for two files.

## 30.11 Incident 7: CI works locally but fails on GitHub Actions

**Symptoms.** The step "Compute version" fails on the runner with exit code 128; the script works on every laptop; re-runs fail identically; `main` has been red since the step was added. The reporter suspects a flaky runner and asks for an administrative merge. (`incidents/07-ci-passes-locally`; the run report is constructed for the exercise.)

**Evidence.** The workflow file and the description of the run. The failed step printed one line, and it is a Git message: `fatal: No names found, cannot describe anything.`

**Hypotheses.** (1) Flakiness: excluded, because the failure repeats and began with a commit. (2) The tag is missing on the server: it is there. (3) The runner's clone lacks the tag.

**Diagnostic commands.** The fixed investigation order of section 30.18; then a clone like the runner's, made with Git.

**Root cause.** `actions/checkout` fetches one commit and no tags by default; `git describe` needs history and tags. Layer: GitHub Actions, a documented default.

**Safe recovery.** `fetch-depth: 0` on the checkout step, on a branch, as a pull request. A second defect waits behind the first: a template name whose case differs between the code and the repository.

**Verification.** A green run on the fix branch, observed on GitHub. The files alone prove that the cause was removed, not that the job passes.

**Prevention.** A workflow change that adds a tool is reviewed with the inputs the tool reads. A red default branch is an incident on its first day.

**Communication.** The answer to "merge it anyway" is no, with the reason. SEV 3.

**Postmortem.** Five days of red on `main` hid a second, real defect.

## 30.12 Incident 8: a branch appears to have disappeared

**Symptoms.** Asha's `feature/prompt-versioning` is on neither the server nor her laptop; none of her commit messages are in `git log main`; she is sure everything was pushed; she needs her last commit, the variable validation. Ravi merged her pull request "with the green button". (`incidents/08-branch-disappeared`)

**Evidence.** No ref of that name exists anywhere. The reflog of the branch went with the branch; the reflog of HEAD did not:

<!-- snippet: incidents/solve-08-branch-disappeared/02-reflog -->
```text
# The branch reflog went with the branch. The HEAD reflog is still here:
$ git reflog show feature/prompt-versioning
fatal: ambiguous argument 'feature/prompt-versioning': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
$ git reflog --format='%h %gd %gs'
1a7ca10 HEAD@{0} pull: Fast-forward
c8dbea7 HEAD@{1} checkout: moving from feature/prompt-versioning to main
70df7f7 HEAD@{2} commit: Validate prompt variables before save
ceaa8bc HEAD@{3} commit: Add version history
a93889a HEAD@{4} commit: Load a prompt by version
c12fb6d HEAD@{5} commit: Store every save as a new version
c8dbea7 HEAD@{6} checkout: moving from main to feature/prompt-versioning
c8dbea7 HEAD@{7} clone: from $LAB/incidents/solve-08-branch-disappeared/server.git
```
<!-- /snippet -->

**Hypotheses.** (1) Renamed: no similar branch on the server. (2) Deleted by mistake, work lost. (3) Merged, and the head branch deleted after the merge. (4) "Everything was pushed."

**Diagnostic commands.** `git log -2 --format='%h author %an, committer %cn: %s' main` shows "Add prompt versioning (#42)", author Asha, committer Ravi: the shape of a squash merge, which keeps none of the original messages. Then the question "which work is where":

<!-- snippet: incidents/solve-08-branch-disappeared/04-classify -->
```text
# The last commit made on the lost branch, from the HEAD reflog:
$ git log --oneline main..70df7f7
70df7f7 Validate prompt variables before save
ceaa8bc Add version history
a93889a Load a prompt by version
c12fb6d Store every save as a new version
# Patch IDs cannot see through a squash: every commit looks unmerged.
$ git cherry -v main 70df7f7
+ c12fb6d8347452b8124fe1d59b2f25c589155a6f Store every save as a new version
+ a93889ae2c557817889f98a9629eb7560ad5a984 Load a prompt by version
+ ceaa8bc13e03ca5676baa71d4401845ee3002318 Add version history
+ 70df7f70daac6ced8a343ab10d9509c1e363cf17 Validate prompt variables before save
# Trees can. What does the old tip have that main does not?
$ git diff --stat main 70df7f7
 registry/validate.py | 9 +++++++++
 1 file changed, 9 insertions(+)
$ git diff --stat main 70df7f7~1
```
<!-- /snippet -->

`git cherry` reports all four commits as unmerged, which is misleading: a squashed commit equals none of its parts. Trees are reliable. `main` and the third commit have identical trees; the fourth commit adds one file and was never pushed.

**Root cause.** Four steps, each reasonable alone. GitHub squash-merged the pull request and deleted the head branch. `fetch.prune` removed the remote-tracking ref. Work had continued on the merged branch. `git branch -d` refused, correctly, because squashed commits are not ancestors of `main`, and `-D` overrode the refusal. Layers: GitHub for the first step, Git for the rest.

> **GitHub, not Git.** A closed pull request offers **Restore branch** for its head branch ([deleting and restoring branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request)). It restores what the server had. A commit that was never pushed is not on the server, and Support cannot produce it.

**Safe recovery.**

```bash
git branch rescue/prompt-versioning 70df7f7                 # 🟢 anchor the tip from the HEAD reflog
git switch -c feature/prompt-validation main                # 🟢 a new branch from the current main
git cherry-pick rescue/prompt-versioning                    # 🟡 the one commit that is not merged
git push -u origin feature/prompt-validation
```

Recreating and pushing the old branch would publish three commits whose content is already in `main`: the reused-branch problem of Chapter 17, section 17.12.

**Verification.** `git log origin/main..origin/feature/prompt-validation` lists one commit, and `git diff --stat rescue/prompt-versioning feature/prompt-validation` prints nothing: the new branch has everything the lost one had.

**Prevention.** A new branch after every merge. Before `-D`: `git diff main <branch>`. "Pushed" is read from `git status -sb`, not from memory.

**Communication.** To Asha: nothing was deleted by mistake; three commits are in `main` as one; the fourth survived only in her reflog. SEV 4.

**Postmortem.** The only copy of a day's work was a reflog entry, which by default expires 30 days after its commit becomes unreachable.

## 30.13 Incident 9: a merge conflict is misunderstood

**Symptoms.** Two reviewed fixes by Asha are missing from `limiter/bucket.py` on `main`. Her commits are in `git log main`; there is no revert; `git log -- limiter/bucket.py` does not list them. Ravi resolved a conflict in that file and "kept ours". (`incidents/09-misunderstood-conflict`)

**Evidence.** `git merge-base --is-ancestor <her commit> main` exits 0, and no subject starts with "Revert". The commits are in the history and their effect is not in the file. Only a merge can do that without a diff of its own in the usual views.

**Hypotheses.** (1) Corruption: nothing supports it. (2) A revert: none. (3) A later commit overwrote the lines: none touches the file. (4) A merge resolution discarded her side.

**Diagnostic commands.** First, why her own search found nothing:

<!-- snippet: incidents/solve-09-misunderstood-conflict/03-log-hides-them -->
```text
# The command Asha ran, and the same command without history simplification:
$ git log --oneline -- limiter/bucket.py
f8435ea Look up the rate per tenant
d40b668 Add token bucket limiter
$ git log --oneline --full-history -- limiter/bucket.py
fb67f49 Merge pull request #17 from feature/per-tenant-limits
d7497e2 Merge remote-tracking branch 'origin/main' into feature/per-tenant-limits
8a11540 Halve the default rate after the overload
bfd1f07 Cap the bucket at BURST tokens
f8435ea Look up the rate per tenant
d40b668 Add token bucket limiter
```
<!-- /snippet -->

With a path, `git log` simplifies history: at a merge whose result for the path equals one parent, it follows only that parent. Her commits are on the discarded side, so the default view hides exactly the commits under investigation. Then the audit of the merge:

<!-- snippet: incidents/solve-09-misunderstood-conflict/05-audit -->
```text
# What did the person who made this merge change, compared with what Git would have produced?
$ git show --remerge-diff --format='%h %an: %s' d7497e2
d7497e2 Ravi Menon: Merge remote-tracking branch 'origin/main' into feature/per-tenant-limits

diff --git a/limiter/bucket.py b/limiter/bucket.py
remerge CONFLICT (content): Merge conflict in limiter/bucket.py
index ebfcaa2..771c807 100644
--- a/limiter/bucket.py
+++ b/limiter/bucket.py
@@ -1,8 +1,4 @@
-<<<<<<< f8435ea (Look up the rate per tenant)
 DEFAULT_RATE = 100
-=======
-RATE = 50
->>>>>>> 8a11540 (Halve the default rate after the overload)
 BURST = 200
 
 
@@ -13,5 +9,5 @@ def allow(key, now):
 
 
 def refill(bucket, now, rate):
-    bucket.tokens = min(BURST, bucket.tokens + (now - bucket.ts) * rate)
+    bucket.tokens = bucket.tokens + (now - bucket.ts) * rate
     bucket.ts = now
```
<!-- /snippet -->

`--remerge-diff` re-runs the merge and shows what the human changed relative to Git's mechanical result. The first hunk was a real conflict, resolved for one side. The second hunk had no conflict: Git had merged the cap cleanly, and the recorded merge removes it. A resolution that changes a hunk Git had already merged is the signature of taking one side of the whole file.

**Root cause.** `git checkout --ours limiter/bucket.py`. "Ours" was read as "the team's version". In `git merge X`, ours is the branch you are on, here the feature branch; in a rebase the roles are swapped ([Chapter 8: Merge](ch08-merge.md), section 8.15; [Chapter 9](ch09-rebase.md), section 9.11). Layer: Git. GitHub merged what it was given.

**Safe recovery.** `main` is shared and four commits sit on the faulty merge, so nothing is rewritten and nothing is reverted (a revert of the merge would remove Ravi's feature). One new commit restores both changes, adapted to his rename, and its message names the merge and the two lost commits.

**Verification.** `git diff <Asha's last commit> <fix> -- limiter/bucket.py` shows only Ravi's two intended changes. A correct resolution contains each side's diff completely.

**Prevention.** Resolve hunks, not files. Review a merge with `git show --remerge-diff` before pushing it. A regression test for the cap would have failed on Ravi's branch.

**Communication.** To both: the repository is intact, nobody reverted anything, and why `git log -- <file>` hid it. To the CTO: the outage recurred because a merged fix was removed inside a merge commit, where review could not see it. SEV 2.

**Postmortem.** Detected by an outage, not by a control. The pull request diff could not show the loss, because after the bad merge the branch and the merge base agreed on those lines.

## 30.14 Incident 10: a commit exists locally but not remotely

**Symptoms.** A release candidate lacks a fix. Ravi sees the commit in `git log`, `git status` says up to date with `origin/main`, and the push printed `main -> main`. Asha cannot find it in the team repository. (`incidents/10-commit-local-not-remote`)

**Evidence.** Everything Ravi said is confirmed in his clone. "On the server" has a hidden parameter: which server.

**Hypotheses.** (1) Never pushed: `git status -sb` would show `ahead`. (2) Pushed to another branch. (3) Made in detached HEAD. (4) `origin` is not the repository the team means. (5) GitHub shows stale data.

**Diagnostic commands.**

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

`git ls-remote` asks each server directly and bypasses every remote-tracking ref. The fork has the commit; the team repository does not.

**Root cause.** `origin` in this clone is Ravi's old fork, and `main` follows `origin/main`. A remote name is a local alias. Every local signal was true about the fork. Layer: Git configuration.

**Safe recovery.** The team repository has moved on, so the fix goes on top of its `main`, on a branch, as a pull request requires.

```bash
git fetch upstream
git switch -c fix/nan-aggregation && git rebase upstream/main       # 🟡 one unpublished commit, new ID
git push -u upstream fix/nan-aggregation                            # then the pull request
git switch main && git branch --set-upstream-to=upstream/main main
git cherry -v upstream/main main                                    # "-": the team repository has an equivalent
git reset --keep upstream/main                                      # 🟡 after the merge of the pull request
```

**Verification.** `git ls-remote upstream main`, and `git merge-base --is-ancestor <fix> upstream/main`.

**Prevention.** Proof of a push is the `To <url>` line, `git ls-remote`, or the commit's page in the team repository; never `git status`. A release checklist checks promised fixes by ancestry.

**Communication.** To both: every command Ravi quoted told the truth about another repository. SEV 3.

**Postmortem.** The release manager looked for a specific commit instead of trusting "it is pushed". That check is now a line in the checklist.

## 30.15 The incident summary a CTO needs

A CTO reads the summary to decide three things: whether customers or outsiders are affected, whether anything is still at risk, and whether to spend money or attention on prevention. Commands do not help with any of them. The summary has four parts, in this order, and fits on one screen.

| Part | The question it answers | Rules |
|---|---|---|
| 1. What happened | What was affected, for how long, with what impact | Impact first, in business terms. Times with a time zone. No names |
| 2. Root cause | Which mechanism, on which layer | One sentence, with the layer named: a Git default, a GitHub rule that was missing, a GitHub Actions default |
| 3. What was done, and how it was verified | Is it over | The recovery in one sentence, and the check that proves it. State what is **not** yet verified |
| 4. Prevention | Will it recur | The control, its owner, its date. A control, not a promise to be careful |

Written for incident 4:

```text
Subject: [Resolved] billing-api: production branch history rewritten (SEV 2, no customer impact)

What happened   Between <time> and <time> IST the branch "production" of billing-api pointed at a rewritten
                history. Nothing was deployed from it: the release job refused. A staging build from that
                branch showed unrounded tax amounts.
Root cause      A history clean-up (interactive rebase) on "production" was force-pushed. It replaced four
                commits by one and dropped the tax-rounding fix. Git allows this; our GitHub rules for the
                branch did not block force pushes.
What was done   The recorded history was restored from the deployment tag and the one change shipped in
                between was carried over. Verified: the deployed commit is again an ancestor of the branch
                (the release job's own check), and the rounding fix is in the file. All three known clones
                were realigned. Not yet verified: clones on CI caches; they are rebuilt tonight.
Prevention      A ruleset on "production" (no force pushes, no deletions, pull request required, no bypass).
                Owner: platform team. Active since <time> today.
```

Five habits make such a summary trustworthy. Separate what you observed from what you infer, and say which is which. Give every time and every ID a source: the reflog entry, the tag, the log line. Say "I do not know yet" early, with the time of the next update. Never write that something was verified unless you ran the check. And send a first, short version before the recovery, as soon as the team knows what to leave alone: silence during an incident is read as "it is worse than they say".

The same four parts, one sentence each, are the spoken answer when the CTO asks in a corridor.

## 30.16 Senior standard 1: a branch was rebased and force-pushed, and the pull request is broken

This is incident 5 again, worked in the eleven steps that define the standard. Steps 1 to 6 change nothing.

**Step 1: inspect the state.** Your clone first, then what the pull request shows. `git status -sb` says the branch equals `origin/feature/online-serving`: locally nothing looks wrong.

<!-- snippet: incidents/solve-05-rebased-shared-branch/02-pull-request-view -->
```text
# What a pull request into main lists: the commits, then the changed files.
$ git log --oneline origin/main..origin/feature/online-serving
6e7ebbd Merge branch 'feature/online-serving' of ../server into feature/online-serving
d4fd03c Add cache warm-up job
5e57ed9 Decode online values
c8d1712 Add online lookup
57b5972 Decode batched values
af1f6de Add batched online lookup
4967e71 Add cache warm-up job
8f79c42 Decode online values
be7fb7a Add online lookup
$ git diff --stat origin/main...origin/feature/online-serving
 store/batch.py  | 3 +++
 store/online.py | 3 +++
 store/warm.py   | 4 ++++
 3 files changed, 10 insertions(+)
```
<!-- /snippet -->

Nine commits, with three subjects twice, and the same three files as before. The commit list and the file view answer different questions ([Chapter 17](ch17-pull-requests.md), section 17.3), which is why one reviewer sees a broken pull request and another sees an unchanged one.

**Step 2: inspect refs.** `git for-each-ref refs/heads refs/remotes` for every ref and its value, and `git ls-remote origin` for the server's own answer. The local branch, the remote-tracking branch and the server agree on `6e7ebbd`. So this is not a stale view: the nine commits are what the repository contains.

**Step 3: inspect the reflog.** Two reflogs, read together from the bottom up.

<!-- snippet: incidents/solve-05-rebased-shared-branch/04-reflog -->
```text
$ git reflog show feature/online-serving
6e7ebbd feature/online-serving@{0}: pull: Merge made by the 'ort' strategy.
57b5972 feature/online-serving@{1}: commit: Decode batched values
af1f6de feature/online-serving@{2}: commit: Add batched online lookup
4967e71 feature/online-serving@{3}: pull: Fast-forward
8f79c42 feature/online-serving@{4}: commit: Decode online values
be7fb7a feature/online-serving@{5}: commit: Add online lookup
65cb28c feature/online-serving@{6}: branch: Created from HEAD
$ git reflog show origin/feature/online-serving
6e7ebbd refs/remotes/origin/feature/online-serving@{0}: update by push
d4fd03c refs/remotes/origin/feature/online-serving@{1}: pull: forced-update
4967e71 refs/remotes/origin/feature/online-serving@{2}: pull: fast-forward
8f79c42 refs/remotes/origin/feature/online-serving@{3}: update by push
$ git config get pull.rebase
false
```
<!-- /snippet -->

Your branch: fast-forward to the shared tip, two commits of your own, then `pull: Merge made by the 'ort' strategy`. The remote-tracking branch: `pull: forced-update`. The server's branch was replaced, and your pull, configured with `pull.rebase=false`, merged the replacement with what you had.

**Step 4: identify the old branch state.** Three commits, by name: the shared tip before the rebase, `4967e71` (`feature/online-serving@{3}`); the rebased tip, `d4fd03c` (`origin/feature/online-serving@{1}`); your tip before the pull, `57b5972` (`feature/online-serving@{1}`). The merge commit confirms two of them as its parents: `git show --no-patch --format='%h parents: %p'` prints `57b5972 d4fd03c`.

**Step 5: understand what changed.**

<!-- snippet: incidents/solve-05-rebased-shared-branch/06-what-changed -->
```text
# Are the two copies the same changes? Compare the old series with the rebased series:
$ git range-diff origin/main~1..4967e71 origin/main..d4fd03c
1:  be7fb7a = 1:  c8d1712 Add online lookup
2:  8f79c42 = 2:  5e57ed9 Decode online values
3:  4967e71 = 3:  d4fd03c Add cache warm-up job
$ git log -3 --format='%h  author %ad  committer %cd  %s' --date=format:%H:%M 4967e71
4967e71  author 10:20  committer 10:20  Add cache warm-up job
8f79c42  author 10:11  committer 10:11  Decode online values
be7fb7a  author 10:10  committer 10:10  Add online lookup
$ git log -3 --format='%h  author %ad  committer %cd  %s' --date=format:%H:%M d4fd03c
d4fd03c  author 10:20  committer 10:29  Add cache warm-up job
5e57ed9  author 10:11  committer 10:29  Decode online values
c8d1712  author 10:10  committer 10:29  Add online lookup
```
<!-- /snippet -->

`git range-diff` pairs the old series with the rebased one: three `=` lines, the same changes under new IDs. The dates agree: a rebase keeps the author date and sets a new committer date ([Chapter 9](ch09-rebase.md), section 9.3). The rebase lost nothing and changed nothing in content. The damage is entirely the merge that made both series reachable.

**Step 6: preserve recoverable references.** `git branch rescue/merged-state feature/online-serving` and `git branch rescue/my-work 57b5972`. The first makes the current state restorable and comparable; the second holds the only commits that exist in one clone alone.

**Step 7: determine the safest recovery.**

| Option | Result | Verdict |
|---|---|---|
| Leave it; merge the pull request as it is | Duplicates and a pointless merge enter `main` (unless squashed) | Rejected: history that misleads `bisect` and `blame` |
| Force the old series back | Undoes Asha's rebase; the branch conflicts with `main` again; her clone diverges | Rejected: destroys a teammate's work |
| Keep the rebased series, replay only your two commits onto it | Five commits, once each; Asha's clone can fast-forward | Chosen |

**Step 8: restore the correct history.**

<!-- snippet: incidents/solve-05-rebased-shared-branch/08-rebuild -->
```text
# Back to my tip from before the pull (a local move), then replay only my two commits
# onto the rebased tip.
$ git reset --keep 57b5972
$ git rebase --onto d4fd03c 4967e71
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/online-serving.
$ git log --oneline --graph origin/main~1..feature/online-serving
* 5e4c03f Decode batched values
* 021ec35 Add batched online lookup
* d4fd03c Add cache warm-up job
* 5e57ed9 Decode online values
* c8d1712 Add online lookup
* 8131d29 Lower the TTL to 15 minutes
```
<!-- /snippet -->

`git reset --keep 57b5972` 🟡 is a local move back to your tip before the pull. `git rebase --onto d4fd03c 4967e71` 🟡 replays what lies after the old shared tip, your two commits, onto the rebased tip. Before publishing, two proofs: `git range-diff 4967e71..rescue/my-work d4fd03c..feature/online-serving` pairs both commits with `=`, and `git diff --stat rescue/merged-state feature/online-serving` prints nothing. The repair changed history and no content.

**Step 9: update the pull request safely.** A pull request follows its head branch, so the update is a push to that branch.

<!-- snippet: incidents/solve-05-rebased-shared-branch/10-publish -->
```text
$ git push --force-with-lease=feature/online-serving:6e7ebbd origin feature/online-serving
To ../server.git
 + 6e7ebbd...5e4c03f feature/online-serving -> feature/online-serving (forced update)
$ git log --oneline origin/main..origin/feature/online-serving
5e4c03f Decode batched values
021ec35 Add batched online lookup
d4fd03c Add cache warm-up job
5e57ed9 Decode online values
c8d1712 Add online lookup
$ git diff --stat origin/main...origin/feature/online-serving
 store/batch.py  | 3 +++
 store/online.py | 3 +++
 store/warm.py   | 4 ++++
 3 files changed, 10 insertions(+)
```
<!-- /snippet -->

🔴 The lease names `6e7ebbd`, the value you examined. If a teammate pushed after your fetch, the push is refused and you look again; a bare `--force` would overwrite their work. Tell the teammates before the push, not after.

> **GitHub, not Git.** After a forced push to a head branch, review comments attached to replaced commits are shown as outdated, and an approval is dismissed if the rule "dismiss stale pull request approvals" is on and the diff changed ([Chapter 17](ch17-pull-requests.md), sections 17.5 and 17.12). Here the diff is identical, and the commit list is what changed. Confirm on GitHub with `gh pr view <number> --json commits,changedFiles` and `gh pr diff <number> --name-only`.

Asha's clone stood at the rebased tip, of which the new tip is a descendant. For her, `git pull --ff-only` is the whole repair.

**Step 10: explain what happened.** Three sentences, no blame: "Asha rebased the shared branch onto `main` while I had two unpushed commits on the old version. My `git pull` merged the old and the rebased commits, and I pushed the result, so the pull request listed both. I rebuilt the branch as the rebased commits plus mine; no content changed, and reviews of the diff stay valid."

**Step 11: prevent recurrence.** `git config set pull.rebase true`: when an upstream was rewritten, `git pull --rebase` finds the old fork point in the reflog of the remote-tracking branch and replays only your commits (Chapter 9, sections 9.13 and 9.15). `pull.ff only` is stricter: the pull stops and you decide. And an agreement: whoever rewrites a shared branch announces it first, with the old tip and the command teammates need.

## 30.17 Senior standard 2: a secret was committed

The order is fixed and its first step is not Git: contain, assess, eradicate, recover, communicate, prevent ([Chapter 21B: Repository Security and Secret-Leak Response](ch21b-repository-security-incident-response.md), section 21B.14; Phase 0 report, section 14).

**1. Contain: revoke or rotate the credential first.** The damage happens where the secret is accepted, and automated scanners copy fast. Revocation works against every copy, including the ones you cannot reach. GitHub's documentation says that revoking or rotating may be sufficient and that a history rewrite may not be warranted ([removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)). Every `git` command typed before this step is time in which the key still works.

**2. Assess.** Five facts for the record: which secret and what it can reach; the first commit and the time of the first push; which refs contain it; who could read it; whether it was used. Git answers the middle three:

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

Two branches reach the commit, two snapshots contain the file, and the server has had it since the push at 10:19. Whether it was used is answered only by the issuer's logs.

**3. Eradicate.** Remove the secret from current code, and decide whether to rewrite history. Rewrite when the data stays harmful after rotation or the affected history is small and unmerged, as here. Do not rewrite by reflex for a revoked key on a busy `main`: a rewrite costs every collaborator their clone, changes every recorded commit ID and removes signatures ([Chapter 21B](ch21b-repository-security-incident-response.md), section 21B.16). The documented tool for a whole repository is git-filter-repo 2.47 or later with `--sensitive-data-removal`; it is not installed here, and one short branch needs only an interactive rebase that edits the adding commit and drops the deleting one. `git range-diff` shows the result:

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

After `git push --force-with-lease --force-if-includes`, every branch built on the old commits is transplanted with `git rebase --onto <new> <old> <branch>`. A merge or a plain pull from a stale clone brings the old commits back.

**4. Recover.** Deploy the new credential. Then remove the old objects, which a force push does not do:

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

In the sandbox you administer the server and run `git gc --prune=now` there. On GitHub that is a request to Support, who need the first changed commit and the number of affected pull requests and who assist only where rotation cannot mitigate the risk; GitHub states that old commits can otherwise stay reachable by ID in cached views, in forks and through pull requests (same page). Each clone keeps the objects through its reflogs until it is re-cloned or runs 🔴 `git reflog expire --expire=now --all && git gc --prune=now`, which destroys that clone's entire safety net.

**5. Communicate.** The team is told which branches were rewritten and exactly what to do with a clone that fetched them. The CTO is told the exposure window, what the credential could reach, what the issuer's logs show, and that rotation is complete. Concealment is the one choice that makes a leak worse.

**6. Prevent.** An ignore rule in the project template; staging by name and reading `git diff --cached`; push protection, which blocks recognised token formats and not free-form passwords ([push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection)); short-lived credentials.

## 30.18 Senior standard 3: GitHub Actions suddenly fails

"Suddenly" is a claim to test first. Either something in the repository changed (a commit to the workflow, the lock file, the code) or something outside it did (a runner image, an action behind a moving tag, a secret, a cache). `git log --oneline -- .github/workflows` and the list of recent runs separate the two in a minute:

```bash
gh run list --workflow ci.yml --branch main --limit 20      # where does green turn red?
gh run view <run-id> --json event,headBranch,headSha,workflowName
```

Then the investigation follows a fixed order, from "did the right thing start" to "what did it say" ([Chapter 20B: Delivery, Runners, Cost and Debugging](ch20b-actions-delivery-debugging.md), section 20B.11). An answer early in the list makes the later ones irrelevant.

| # | Area | The question | Typical finding |
|---|---|---|---|
| 1 | Workflow | Which file, from which commit, defined the run? | `schedule` uses the file on the default branch; `workflow_dispatch` uses the file on the ref it was dispatched against, and can be started only if the file exists on the default branch (Chapter 20B, section 20B.11) |
| 2 | Event | What triggered it, and which commit was checked out? | `pull_request` builds the merge ref, not your head commit |
| 3 | Permissions | What could the token do? | Unlisted scopes are `none`; fork and Dependabot runs are read-only |
| 4 | Runner | Which image and size? | A `-latest` label moved; private repositories get smaller runners |
| 5 | Environment | Did the job reference one, and did its rules pass? | Waiting for approval; wrong branch for the environment |
| 6 | Dependencies | Were the same versions installed as locally? | No lock file, or not installed with `--locked` |
| 7 | Secrets | Were they present? | An unset or withheld secret is an empty string, not an error |
| 8 | Action versions | Which commit of each action ran? | An old major on a new Node runtime; a moved tag |
| 9 | Logs | What did the failed step print? | `gh run view <run-id> --log-failed` |
| 10 | Artifacts | Were the expected files produced and passed on? | Wrong name; expired |
| 11 | Cache | What was restored, under which key? | A broad `restore-keys` prefix restored a stale cache |
| 12 | Concurrency | Was the run cancelled or replaced? | Conclusion `cancelled`; a shared group name |

Applied to incident 7: areas 1 to 8 are answered from the workflow file and the run report without a log (one event, read-only token, fixed runner label, no environment, no secrets, both actions pinned by commit SHA). Area 9 gives one line, and it is a Git message. That points at the repository the runner had, and Git can build the same one:

<!-- snippet: incidents/solve-07-ci-passes-locally/03-runner-clone -->
```text
# What the checkout step does by default, reproduced with Git: depth 1 and no tags.
$ git clone --quiet --depth 1 --no-tags "file://$PWD/../server.git" ../runner-checkout
$ cd ../runner-checkout
$ git rev-parse --is-shallow-repository
true
$ git rev-list --count HEAD
1
$ git tag --list
$ bash scripts/version.sh
fatal: No names found, cannot describe anything.
[exit status: 128]
```
<!-- /snippet -->

One commit, no tags, exit status 128. `actions/checkout` fetches a single commit by default, with `fetch-tags` off; `fetch-depth: 0` fetches all history for all branches and tags ([checkout README, v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md)). The step was added without changing the checkout it depends on.

Two habits complete the standard. Look behind the first failure: the job never reached its tests, and `git ls-files` shows a template tracked as `summary.md.tmpl` while the code opens `Summary.md.tmpl`, which works only on a filesystem that ignores case. And refuse the shortcut: a red required check is not overridden by an administrator because the change "is only a docstring". The honest status after the fix is pushed is "cause removed in the files; confirmed when the run on the fix branch is green". Re-run with `gh run rerun <run-id> --failed --debug` only when the log is not enough; a re-run reuses the original commit and ref.

## 30.19 Blameless postmortems, with a template

**In one sentence.** A postmortem is a written record of an incident that explains how the system allowed it, so that the system can be changed; "blameless" means it treats every person's action as reasonable given what they knew.

**Why blameless is a technical requirement.** The evidence in this chapter came from people: Ravi's reflog, Asha's account of the reset, a developer saying "I committed a password". People who expect blame run `git gc`, re-clone, or stay silent, and the evidence is gone. Google's SRE book states the principle as assuming that everyone involved "had good intentions and did the right thing with the information they had" ([Postmortem Culture](https://sre.google/sre-book/postmortem-culture/), a secondary source). The useful question is never "who ran the command" but "why did running it look right, and why did nothing stop it".

**The test.** Replace every name by a role. If the document still explains the incident, it is about the system. "Ravi force-pushed production" explains nothing. "The production branch accepted a forced update from any member with write access" names something that can be changed.

```markdown
# Postmortem: <one-line title>            Severity: SEV n        Status: draft | reviewed | actions closed

## Summary             Four sentences: what happened, root cause with its layer, what was done, what prevents it.
## Impact              Who and what was affected, for how long. What could have happened in the window.
## Timeline            Time (with zone) | event | source of the fact (reflog entry, tag, log line, message)
## Detection           How it was noticed, by whom or what, and how long after it began.
## Root cause          The seven-line root-cause box of Chapter 1, section 1.10.
## Contributing conditions   What made the action look right. Which control was missing or bypassed.
## Recovery            What was done, in order, with risk labels. What was verified, and how.
## What went well      The controls and habits that limited the damage.
## What went badly     Without names.
## Actions             Control | type (prevent, detect, recover) | owner | date | how we will know it works
## Evidence            Transcripts, commit IDs, links. Kept with the document.
```

Write it within days, while reflogs and memories exist. Have the people involved review the timeline. An action without an owner and a date is a wish; a postmortem whose only action is "be more careful" has not found the cause.

## 30.20 Turning a root cause into a control

A control is something that still works when the person is new, tired or in a hurry. Controls differ in strength, and the order below is the order in which to look for one.

| Strength | Kind of control | Example from this chapter | Why it ranks here |
|---|---|---|---|
| 1 | The server refuses | A ruleset that blocks force pushes on `main` and `production` (incidents 2, 4) | Applies to every client and tool, whatever their configuration |
| 2 | Automation checks | The release job's ancestry test (4); a regression test (9); push protection (3) | Runs every time, but only on what it was written to see |
| 3 | A safe default on the client | `push.default=simple`, `pull.rebase=true`, an ignore rule in the template (2, 5, 3) | Works until someone has another configuration |
| 4 | A step in a checklist or review | `--remerge-diff` for merges (9); read the commit list (6); ancestry of promised fixes (10) | Depends on the reviewer doing it |
| 5 | Training and habit | `git restore` instead of `reset --hard` (1); a new branch after a merge (8) | Decays, and does not reach new people |

From root cause to control in four questions. Which layer could have refused the action: the platform, the pipeline, the client, a reviewer? What is the strongest control available on that layer and on your plan (some ruleset features are plan-gated, [Chapter 18](ch18-branch-protection.md), section 18.15)? What will the control block that is legitimate, and what is the path for that case? And how will you know it works: a ruleset's insights, a test that fails when the fix is removed, an attempt in a sandbox.

Prefer one strong control to five weak ones. For incident 4 the list could have ten items; the one that matters is a checkbox on the server.

## 30.21 What can go wrong

| What goes wrong | How you notice | Fix | Prevention |
|---|---|---|---|
| A second "fix" destroys the evidence (`reset --hard`, `gc`, re-clone, `fetch --prune`) | A reflog entry or dangling commit you counted on is missing | Another clone, `git fsck --lost-found`, a backup; often nothing | Stabilise first: ask for no cleanup before reflogs are read |
| The old value is restored from a stale clone | Commits pushed shortly before the incident are missing afterwards | Compare candidates with `git merge-base --is-ancestor`; restore the newest | Collect the old tip from every clone and from tags before choosing |
| A bare `--force` during recovery overwrites a teammate's new push | Their commit is absent from the server | Their clone still has it; push it again | `--force-with-lease=<ref>:<expect>` always, with the value you examined |
| A stale clone pushes removed history back | Old commits or a removed secret reappear after a rewrite | Repeat the clean-up; find the clone | Instructions per clone; rebase, never merge, old branches ([Chapter 21B](ch21b-repository-security-incident-response.md), section 21B.18) |
| A revert is used where a merge had to be removed | A later merge of the same branch "brings nothing" | Revert the revert, or rebuild ([Chapter 11](ch11-reset-revert-restore.md), section 11.9) | Decide revert or rebuild by asking what will be merged later |
| Git clean-up starts before a credential is rotated | The key still works while history is being rewritten | Rotate now | The fixed order of section 30.17 |
| The summary claims more than was checked | A follow-up question has no answer | Correct it in writing | "Verified" only for checks that were run |

## 30.22 When not to use it, and dangerous edge cases

- **Do not run an incident process for a SEV 4.** One person's local reset needs ten minutes of help and one note, not a channel and a document.
- **Do not rewrite when adding suffices.** Incident 9 was repaired with one commit. A rewrite of shared history is a second incident for everyone who has a clone.
- **Do not rewrite history to remove a secret that is already revoked** on a busy default branch, unless the data stays harmful. The cost is certain and the benefit is cosmetic.
- **Reflogs are per clone and expire.** By default an entry for an unreachable commit lasts 30 days, and a deleted branch loses its reflog at once. Evidence that is days old may be hours from deletion on a machine that runs maintenance.
- **A lease is only as good as its expected value.** The bare `--force-with-lease` trusts the remote-tracking branch, which a background fetch in an editor updates silently ([Chapter 12](ch12-remote-operations.md), section 12.8). In an incident, give the expected ID explicitly.
- **`git pull --rebase` after a forced update can drop your own pushed commit.** With no upstream named on the command line, the rebase uses the fork point from the reflog of the remote-tracking branch. A commit you had pushed, and that a force push then removed from the server, counts as old upstream history and is not replayed. The pull prints "Successfully rebased" and the commit is off your branch; `ORIG_HEAD` and the reflog still name it. Lab 36.3 shows it. After a forced update, look first and integrate by hand.
- **`git reflog expire --expire=now --all` with `git gc --prune=now` is the one recovery step that is itself unrecoverable.** It belongs only at the end of a secret clean-up, in a clone with no other unpublished work.
- **GitHub keeps what Git has let go.** A commit removed by a force push may stay retrievable by ID on GitHub; this helps recovery and defeats removal. GitHub publishes no retention period.
- **The sandbox is kinder than production.** In `incidents/` you may read every clone and administer the server. In real life you ask a colleague to run `git reflog show origin/main` and paste it, and the server-side steps go through rules, the Activity view and Support.

## 30.23 Command safety

What the recovery commands of this chapter change:

| Command | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git branch rescue/x <id>` 🟢 | unchanged | unchanged | unchanged | unchanged | new ref and its reflog | unchanged | unchanged |
| `git cherry-pick <range>` 🟡 | updated | updated | moves with the branch | advances by the copied commits | reflogs; `CHERRY_PICK_HEAD` during a conflict | unchanged | unchanged |
| `git reset --keep <id>` 🟡 | updated; refuses to overwrite local changes | updated | moves with the branch | set to `<id>` | `ORIG_HEAD`, reflogs | unchanged | unchanged |
| `git rebase --onto <new> <old>` 🟡 | updated | updated | detached during the run, then back on the branch | set to the last replayed commit | `ORIG_HEAD`, reflogs, `.git/rebase-merge/` during the run | unchanged | unchanged |
| `git push origin <id>:refs/heads/<new>` 🟢 | unchanged | unchanged | unchanged | unchanged | remote-tracking ref created | new branch | a new branch; push rules apply |
| `git push --force-with-lease=<ref>:<expect>` 🔴 | unchanged | unchanged | unchanged | unchanged | remote-tracking ref updated | branch replaced if it still equals `<expect>` | pull requests on that branch follow; rules may reject it |
| `git reflog expire --expire=now --all` then `git gc --prune=now` 🔴 | unchanged | unchanged | unchanged | unchanged | all reflog entries removed; unreachable objects deleted | unchanged | unchanged |

| Command | Label | What it can destroy | Preview | Recovery | When appropriate |
|---|---|---|---|---|---|
| `git push --force-with-lease=<ref>:<expect>` | 🔴 | Commits on the server that only the server and stale clones have | `git log <local>..<expect>` lists what will leave the branch | A clone's reflog of `origin/<ref>`; on GitHub the Activity view | Restoring a known good value; publishing a rewritten topic branch |
| `git push --force` | 🔴 | The same, without any condition | none | the same | Not in an incident |
| `git reset --hard <id>` | 🔴 | Uncommitted changes to tracked files | `git status`, `git diff HEAD` | none for unstaged work | Use `--keep` instead during recovery |
| `git branch -D <branch>` | 🔴 | The branch reflog; the only name of unmerged commits | `git log main..<branch>`, `git diff main <branch>` | HEAD reflog, until it expires | After the diff against the target is empty |
| `git reflog expire --expire=now --all`, `git gc --prune=now` | 🔴 | Every recovery path in that clone | `git fsck --unreachable` lists what would go | none | Final step of a secret clean-up |
| `git rebase --onto`, `git cherry-pick`, `git reset --keep` | 🟡 | Nothing permanently | `git log <old>..HEAD` | `ORIG_HEAD`, the branch reflog | The standard recovery tools |
| `git revert -m 1 <merge>` | 🟡 | Nothing now; a later merge of the same branch is silently empty | `git show --stat <merge>` | revert the revert | Only when the merged branch will never be merged again as it is |

## 30.24 Version notes

> **Version note.** Older behavior: an unconfigured `git pull` on diverged branches merged, silently before Git 2.27 and with a warning after. Current behavior: without `pull.rebase`, `pull.ff` or a command-line choice it stops and asks how to reconcile. Since: Git 2.33.1 and 2.34.0 ([Chapter 12](ch12-remote-operations.md), section 12.6). Recommended: set `pull.rebase true` or `pull.ff only`; incident 5 needed an explicit `pull.rebase=false` to happen.

> **Version note.** `--force-if-includes` exists since Git 2.30 and does nothing when the lease names an explicit expected value. `git show --remerge-diff` exists since Git 2.36. The `git config get|set|unset` subcommands need Git 2.46 or later.

> **Version note.** Git 2.56 adds `git add --resolved`, which stages resolved paths and aborts if conflict markers remain (added in Git 2.56, not run here; Phase 0 report, section 13). It would not have caught incident 9, where no marker was left behind.

> **GitHub, not Git.** All GitHub facts are as of 1 October 2026: rulesets block force pushes by default when created; push protection for users has covered public repositories since 29 February 2024; `actions/checkout` v7.0.1 defaults to `fetch-depth: 1` without tags. Interface labels change; follow the linked pages.

## 30.25 Practice

- [Module 36: incident drills, local and history](../lab-manual/m36-incident-drills-local.md): incidents 1, 8, 10, 9 and 5.
- [Module 37: incident drills, remote, platform, CI and security](../lab-manual/m37-incident-drills-platform.md): incidents 2, 4, 6, 7 and 3.
- [Module 38: communication, postmortems and the senior standard](../lab-manual/m38-communication-postmortems.md): a CTO summary, a postmortem, and the three scenarios against the clock.
- Keep [the disaster-recovery playbook](../playbooks/disaster-recovery-playbook.md) and [the one-page emergency sheet](../cheatsheets/emergency-recovery-one-page.md) at hand; both use only commands verified in this book.

Do every drill before reading its solution in `solutions/`.

## 30.26 Interview questions

1. `main` was force-pushed ten minutes ago. Before you restore it, which two things do you check, and what does the restoring command look like?
2. A colleague says "I deleted the file with the key and pushed, so we are fine". Give the order of the response and say what the deletion did and did not do.
3. Why is `--force-with-lease` not a defense against the situation in which a teammate has unpublished commits on a branch you rebased?
4. A pull request shows the same changed files as yesterday and three times as many commits. What happened, and which two comparisons explain why the views differ?
5. When is `git revert -m 1` the wrong way to take a mistaken merge out of a topic branch?
6. A fix is in `git log main` and not in the file. Which command shows what happened, and why did `git log -- <file>` hide the commits?
7. The server keeps no reflog. Where does the timeline of a server-side branch come from, on plain Git and on GitHub?
8. A job that runs `git describe` fails only on GitHub Actions. Name the default responsible and two remedies.
9. What are the four parts of an incident summary for a CTO, and what must never be claimed in the third?
10. Rank these controls by strength for "nobody force-pushes production": a handbook rule, a client alias, a ruleset, a review checklist. Justify the order.
11. After a squash merge, with the head branch deleted on the server and pruned from your clone, `git branch -d` refuses to delete the merged branch. Why, and what do you check before `-D`?
12. What makes a postmortem blameless in practice, and why does that matter for the evidence?

## 30.27 Sources

**Primary sources**

- Local manual pages of Git 2.55.0: `git help reflog`, `git help push` (the lease forms), `git help rebase` (`--onto`, `--empty`), `git help cherry`, `git help range-diff`, `git help fsck`, `git help log` (history simplification, `--remerge-diff`), `git help describe`.
- GitHub Docs: [Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository); [deleting and restoring branches in a pull request](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request); [Events API](https://docs.github.com/en/rest/activity/events); [create a reference](https://docs.github.com/en/rest/git/refs#create-a-reference); [troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone); [available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#block-force-pushes); [removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository); [remediating a leaked secret](https://docs.github.com/en/code-security/tutorials/remediate-leaked-secrets/remediating-a-leaked-secret); [push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection).
- [actions/checkout README, v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md).
- The Phase 0 report, sections 12 to 14, including its unverified flags for the GitHub-side recovery recipe.

**Secondary sources**

- [git-filter-repo manual](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt), for the clean-up of other clones after a rewrite.
- Google, *Site Reliability Engineering*, [Postmortem Culture: Learning from Failure](https://sre.google/sre-book/postmortem-culture/).
- Julia Evans, [what can go wrong with rebasing](https://jvns.ca/blog/2023/11/06/rebasing-what-can-go-wrong-/).
- Truffle Security, [commits orphaned by force pushes](https://trufflesecurity.com/blog/guest-post-how-i-scanned-all-of-github-s-oops-commits-for-leaked-secrets): an observation by researchers, not a statement by GitHub.

**Videos**

- ["Tag, You're Leaked: Surviving the tj-actions Supply Chain Attack"](https://www.youtube.com/watch?v=FxHIaRwc9c4), BSides PDX 2025, 24 minutes. A 72-hour incident response for GitHub Actions; the Phase 0 report calls it the closest thing to a production incident-response case study, and notes that it found no conference talk covering end-to-end Git incident recovery with current tooling.

**Further reading**

- [Chapter 13: Recovery](ch13-recovery.md), [Chapter 29: Production Troubleshooting](ch29-production-troubleshooting.md), [Chapter 21B: Repository Security and Secret-Leak Response](ch21b-repository-security-incident-response.md), [Chapter 20B: Delivery, Runners, Cost and Debugging](ch20b-actions-delivery-debugging.md).
