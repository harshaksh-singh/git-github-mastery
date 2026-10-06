# V183: Preserving evidence before acting, and GitHub-side evidence

- **Part.** 9, Production debugging and incident response
- **Module.** 35
- **Planned minutes.** 22
- **Prerequisites.** V079, V182
- **Textbook sections.** [Chapter 29](../../textbook/ch29-production-troubleshooting.md), sections 29.7 and 29.8, with the edge cases of section 29.13
- **Demo scripts.** `labs/ch29/preserve-evidence.sh` (snippets `01-record` to `07-from-copy`), `labs/ch29/lab-35-3-preserve-then-fix.sh` (snippets `01-handover`, `02-diagnose`, `03-preserve`); GitHub side described from section 29.8

## HOOK

**[ON SCREEN]** "`main` moved backwards on Friday evening. Who did it, when, from which commit to which, and did a rule allow it?"

Four questions, and your clone can answer about half of one of them. Your clone knows two commit IDs, if it happened to fetch before and after. It does not know who pushed. The author field of a commit does not say either: anyone can set it.

And there is a second problem. The person who noticed on Friday evening tried three repairs before calling you. Each repair moved refs and pushed reflog lines down, and one of them ran a cleanup. The evidence you need is partly gone, and it was destroyed by the investigation.

## INTRODUCTION

This is the second phase of the method: preserve. In V180 it was one command, a rescue branch. Today you learn the four layers of preservation, what each holds and what each misses, and you watch a repository being destroyed on purpose and brought back from each layer. That demonstration is the argument: a backup made first turns a destructive mistake into a recoverable one.

The second half is about evidence that is not in any clone. GitHub records what reached the server, who was authenticated when it arrived, and which rules were evaluated. Nothing in that half is part of Git, and nothing in it was run for this course. It is described from GitHub's documentation as the textbook read it on 1 October 2026.

From V079 you know backup refs and bundles as prevention. Here they are steps of a procedure, with an order.

## LEARNING OBJECTIVES

After this video you can:

1. Preserve a repository's state with a backup ref, a copy and a bundle, and say what each keeps and misses.
2. Show that a backup made first turns a destructive mistake into a recoverable one.
3. Name the diagnostic commands that are not strictly read-only.
4. List the GitHub-side sources of evidence the section names and what each records.
5. Say where the timeline of a server-side branch comes from.

## CONCEPT

**In one sentence.** Before the first state-changing command, put what you might need later somewhere that the fix cannot reach.

**Precisely: four layers.** Each holds more than the previous one and costs more.

**[ON SCREEN]** The table of section 29.7.

| Layer | Command | Holds | Does not hold |
|---|---|---|---|
| The recorded output | redirect the ten commands to a file; `git diff > file.patch` | What you saw, including reflog lines that later commands will push down; uncommitted changes as patches | Objects |
| A backup ref 🟢 | `git branch rescue/<what> <id>` or `git update-ref refs/backup/<name> <id>` | One commit and everything it reaches, kept from garbage collection for as long as the ref exists | Reflogs, the index, uncommitted files, operation state |
| A copy of the repository 🟢 | `cp -Rp . ../evidence/<name>-copy` | Everything: objects, refs, reflogs, index, working tree, stashes, hooks, configuration, operation state | Nothing local. It does not hold what only the server has |
| A bundle 🟢 | `git bundle create <file> --all` | Every ref and HEAD with all objects they reach, in one file that can be verified, moved and fetched from | Reflogs, unreachable objects, the index, uncommitted files, configuration, hooks |

A ref under `refs/backup/` is not shown by `git branch`; a branch under `rescue/` is, which is better when a colleague continues the work. Both keep the commit alive.

None of the four layers changes the working tree, the index, HEAD or any existing ref. A backup ref adds one ref. The copy and the bundle are written outside the repository.

**Which layer when.** A ref is about to move: a backup ref, always. Uncommitted work or an operation in progress is involved: a copy of the whole directory. The disk is suspect or the evidence must leave the machine: a bundle, stored elsewhere. Someone else will ask what happened: the recorded output.

**One warning about the copy.** A copy of a repository contains everything the repository contains, including credentials in `.git/config` URLs and any secret in history. Treat it with the same care, and delete it when the incident is closed.

**Diagnostic commands that are not strictly read-only.** Section 29.13 names three.

`git fsck --lost-found` writes files under `.git/lost-found/`.

`git fetch` moves remote-tracking refs, and with `fetch.prune=true` or `--prune` it deletes those whose server branch is gone, together with their reflogs: the last local record of a deleted branch. Use `git ls-remote` when you must not change anything.

`git status` may rewrite the index to refresh cached stat data. In a repository you must not touch at all, use `git --no-optional-locks status`, which the Git manual documents for background tools.

**GitHub-side evidence, in one sentence.** Your clone records what you did; GitHub records what reached the server, who was authenticated when it arrived, and which rules were evaluated.

**GitHub, not Git.** Nothing in this part is part of Git. Git's reflogs are local and are not shared with remotes, and GitHub exposes no server-side reflog. So the timeline of a server-side branch does not come from Git at all. It comes from the sources below. None of the commands was executed here, and user-interface labels change.

**[ON SCREEN]** Five sources, from section 29.8.

| Source | What it records | Reach and limits | Who can read it |
|---|---|---|---|
| **Activity view** of a repository | pushes, merges, force pushes and branch changes, associated with commits and authenticated users; filters for branch, activity type, user and time period; "Compare changes" on each entry | The before and after commit of each ref update. Retention is not stated in the page | Not stated in the page |
| **Pull request timeline** | The events of one pull request in order, including `committed`, `head_ref_force_pushed`, `head_ref_deleted`, `head_ref_restored` and `base_ref_changed`. A closed pull request offers "Restore branch" for a deleted head branch | One pull request. The head commits stay fetchable through `refs/pull/N/head` | Anyone who can read the pull request |
| **Events API** | `PushEvent` with `ref`, `before` and `head` | up to 300 events, only those created within the past 30 days; latency anywhere from 30 seconds to 6 hours; since 7 October 2025 push events no longer carry commit summaries | Anyone who can read the repository |
| **Rule Insights** | Every ref update evaluated by a ruleset: passed, failed or bypassed, and what would have happened in Evaluate mode | Rulesets only, not classic branch protection. An exempt actor skips enforcement without the signals a bypass generates. The insights dashboard is for Team and Enterprise Cloud plans | Repository administrators |
| **Audit log** | Organization: events of the last 180 days, for owners, exportable. Enterprise: also Git events such as `git.push`, retained for seven days and available only via the REST API, audit log streaming, or JSON/CSV exports | Organization and enterprise accounts only. A personal repository has no audit log of this kind | Organization owners; enterprise owners |

**[ON SCREEN]** The commands that read these sources, shown without output.

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

The activity endpoint is documented with the activity types `push`, `force_push`, `branch_creation`, `branch_deletion`, `pr_merge` and `merge_queue_merge`, and items that carry `before`, `after`, `ref`, `timestamp` and `actor`.

**How the two sides combine.** Git evidence answers "what is the state and which local command produced it". GitHub evidence answers "which authenticated account moved the server's ref, when, from which commit to which, and did a rule allow it".

**[ON SCREEN]** Unverified. Two flags travel with these facts.

A "restore" action inside the Activity view: only filtering and "Compare changes" are documented there. The access requirement and the retention period of the Activity view are not stated in the documentation that was read.

How long GitHub keeps commits that no ref reaches: no retention period is published. The recovery recipe, find the old ID, then create a ref at it through the references API, is an inference from documented endpoints, not a documented procedure, and nothing guarantees that it succeeds.

And one consequence: GitHub-side evidence expires. Thirty days for events, seven days for enterprise Git events. Export it on the first day.

## MENTAL MODEL

The textbook's analogy: a database administrator takes a snapshot before a migration. The analogy breaks only in cost: a backup ref takes one second, so time never justifies skipping it.

For the four layers, think of what each would let you rebuild after the worst afternoon. The recorded output lets you tell the story. The backup ref lets you get the commits back. The bundle lets you get the commits back on another machine. The copy lets you get the afternoon back: the uncommitted edits, the reflog, the operation in progress.

For the two kinds of evidence, think of a building. Your clone is your own notebook of what you carried in and out. GitHub is the log at the front desk: who badged in, at what time, which door, and whether a guard waved them through. Neither replaces the other. And the front desk does not keep its log forever.

## DIAGRAM

**[DIAGRAM]** A new drawing: three ways to preserve, as three boxes, each listing what it keeps and what it misses. The recorded output is the line above them.

```text
  first: record the output of the ten commands, and git diff as patches   (the story; no objects)

  +--------------------------+  +--------------------------+  +--------------------------+
  | BACKUP REF               |  | COPY OF THE REPOSITORY   |  | BUNDLE                   |
  | git branch rescue/x <id> |  | cp -Rp . ../evidence/... |  | git bundle create --all  |
  |                          |  |                          |  |                          |
  | keeps:                   |  | keeps:                   |  | keeps:                   |
  |   one commit and all it  |  |   everything local:      |  |   every ref and HEAD and |
  |   reaches, safe from gc  |  |   objects, refs, reflogs,|  |   all they reach, in one |
  |                          |  |   index, working tree,   |  |   verifiable file        |
  | misses:                  |  |   stashes, hooks, config,|  |                          |
  |   reflogs, the index,    |  |   operation state        |  | misses:                  |
  |   uncommitted files,     |  |                          |  |   reflogs, unreachable   |
  |   operation state        |  | misses:                  |  |   objects, the index,    |
  |                          |  |   what only the server   |  |   uncommitted files,     |
  |                          |  |   has                    |  |   config, hooks          |
  +--------------------------+  +--------------------------+  +--------------------------+
        one second                   seconds, on this disk         one file, can leave the machine
```

Draw the order with an arrow under the boxes: anchor first, bundle second. A bundle holds what refs and HEAD reach at the moment it is made. A commit that only a reflog knows is not in it.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch29/preserve-evidence`. It uses the repository of V180, the unfinished rebase, with two additions: one staged and one unstaged edit. So this time uncommitted work is at stake.

**Step 1: record.** 🟢 SAFE: writes files outside the repository.

```bash
mkdir ../evidence
{ git status; git branch -vv; git log --graph --decorate --oneline --all; git reflog; } > ../evidence/state.txt 2>&1
git diff > ../evidence/unstaged.patch
git diff --cached > ../evidence/staged.patch
git status --short
```

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

Two edits: `README.md` unstaged, `config/service.yaml` staged. The output of the opening commands is in a file, and each edit is saved as a patch.

**Step 2: backup refs.** 🟢 SAFE: each command adds one ref.

```bash
git branch rescue/latency-wip HEAD
git update-ref refs/backup/latency-budget feature/latency-budget
git for-each-ref refs/heads/rescue refs/backup
```

<!-- snippet: ch29/preserve-evidence/02-backup-ref -->
```text
$ git branch rescue/latency-wip HEAD
$ git update-ref refs/backup/latency-budget feature/latency-budget
$ git for-each-ref refs/heads/rescue refs/backup
4a030148e74b6b4394d1056737434790a34ae612 commit	refs/backup/latency-budget
075407e71d9b34006eccefd0d2072bfb51d2850b commit	refs/heads/rescue/latency-wip
```
<!-- /snippet -->

One anchor on the detached HEAD, `075407e`, and one on the published branch tip, `4a03014`.

**Step 3: a copy.** 🟢 SAFE. Predict: will the copy know that a rebase is in progress?

```bash
cp -Rp . ../evidence/scoring-api-copy
git -C ../evidence/scoring-api-copy status | head -4
git -C ../evidence/scoring-api-copy status --short
git -C ../evidence/scoring-api-copy reflog -3
```

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

The copy is a complete repository: the same rebase in progress, the same staged and unstaged files, the same reflog. The `-p` keeps modification times, which spares Git a re-read of every file.

**Step 4: a bundle.** 🟢 SAFE.

```bash
git bundle create ../evidence/scoring-api.bundle --all
git bundle verify ../evidence/scoring-api.bundle
```

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

Seven refs, among them the backup refs created a moment ago and the detached `HEAD`. That is why the anchor came first.

**Step 5: the worst afternoon.** The script now does on purpose what a panicked sequence of "fixes" does by accident. Do not run this on a repository you need.

🔴 DANGEROUS: `git reflog expire --expire=now --all` followed by `git gc --prune=now`. The five answers. What it changes: it deletes the reflogs and every unreachable object. What it can destroy: the safety net itself. Preview: `git fsck --unreachable` lists what would go. Recovery: none. When appropriate: only for purging sensitive data from a clone after the secret has been rotated. The other commands of the sequence: `git rebase --abort` is 🟡 and resets the index and the working tree; `git branch -D` and `git update-ref -d` delete the anchors.

```bash
git rebase --abort
git branch -D rescue/latency-wip
git update-ref -d refs/backup/latency-budget
git reflog expire --expire=now --all
git gc --quiet --prune=now
git cat-file -t 075407e
git status --short
```

Predict the last two outputs.

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

**[PAUSE]** `git rebase --abort` printed nothing, and the last command shows that the staged and the unstaged edit are gone with it. With the anchors deleted, the reflogs emptied and the objects pruned, `075407e` is no longer an object in this repository. This is the point of no return of Chapter 13, reached in five commands.

**Step 6: back from the bundle.**

```bash
git fetch ../evidence/scoring-api.bundle 'refs/heads/rescue/*:refs/heads/rescue/*'
git log --oneline -3 rescue/latency-wip
git reflog show rescue/latency-wip
```

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

**Step 7: back from the copy.** Predict what the copy still has that the bundle did not.

```bash
cd ../evidence/scoring-api-copy
git status --short
git reflog -3
cat .git/rebase-merge/head-name
git diff --cached --stat
```

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

**[TERMINAL]** Now the same phase inside a real task. Replay `labs/run ch29/lab-35-3-preserve-then-fix`, the first three snippets. The fix is the next video and your lab.

**The handover.**

<!-- snippet: ch29/lab-35-3-preserve-then-fix/01-handover -->
```text
$ cat guardrail.HANDOVER.txt
Handover note:
"Backporting the blocklist and the token limit to release/1.4 for tonight.
Got a conflict in guard.yaml. On 1.4 the threshold must stay 0.50; the limit
becomes 128. I fixed the file by hand and then had to leave. Please finish."
$ cd guardrail
$ git status
On branch release/1.4
You are currently cherry-picking commit e0631de.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   guard.yaml

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

A note from a colleague: a backport to a release branch, a conflict resolved by hand, and "please finish". The note contains intent that no Git command can show: on this release line the threshold must stay 0.50, and the limit becomes 128. `git status` confirms a cherry-pick in progress with one unmerged path.

**The diagnosis.**

<!-- snippet: ch29/lab-35-3-preserve-then-fix/02-diagnose -->
```text
$ git log --graph --decorate --oneline --all
* 5c011a9 (HEAD -> release/1.4) Add blocklist
* 329817a Allow 512 tokens on the 1.4 line
| * f9e40d6 (main) Block the word secret
| * e0631de Lower max_tokens to 128
| * b24fd62 Add blocklist
| * 73ef788 Raise guard threshold to 0.65
|/  
* b039fd7 Add output guard
$ cat .git/CHERRY_PICK_HEAD
e0631de25fbc27decbe5c84018d24bdf95f12aa2
$ cat .git/sequencer/todo
pick e0631de Lower max_tokens to 128
pick f9e40d6 Block the word secret
$ git ls-files -u
100644 ea5b34d7cbddccfdf80d8ac18aa35c90353b7249 1	guard.yaml
100644 383f082880d9887c5a67715cf7c9fba0f9bce715 2	guard.yaml
100644 47a6e5c84e76259832497409533332fd12f8d066 3	guard.yaml
$ git diff
diff --cc guard.yaml
index 383f082,47a6e5c..0000000
--- a/guard.yaml
+++ b/guard.yaml
@@@ -1,2 -1,2 +1,2 @@@
 -threshold: 0.65
 +threshold: 0.50
- max_tokens: 512
+ max_tokens: 128
```
<!-- /snippet -->

`CHERRY_PICK_HEAD`, a sequencer todo with two picks, three stages for `guard.yaml`, and a combined diff that shows the colleague's hand-made resolution in the working tree. That resolution exists in no object. Ask the viewer: which layer of preservation would keep it?

**The preservation.**

```bash
mkdir ../evidence
{ git status; git log --graph --decorate --oneline --all; git reflog; git diff; } > ../evidence/state.txt 2>&1
git branch rescue/backport-partial HEAD
cp -Rp . ../evidence/guardrail-copy
cp -Rp . ../rehearsal
git bundle create ../evidence/guardrail.bundle --all
git bundle verify ../evidence/guardrail.bundle
```

<!-- snippet: ch29/lab-35-3-preserve-then-fix/03-preserve -->
```text
$ mkdir ../evidence
$ { git status; git log --graph --decorate --oneline --all; git reflog; git diff; } > ../evidence/state.txt 2>&1
$ git branch rescue/backport-partial HEAD
$ cp -Rp . ../evidence/guardrail-copy
$ cp -Rp . ../rehearsal
$ git bundle create ../evidence/guardrail.bundle --all
$ git bundle verify ../evidence/guardrail.bundle
../evidence/guardrail.bundle is okay
The bundle contains these 4 refs:
f9e40d623e77c7f311cf07e75d14016adff35ae5 refs/heads/main
5c011a9e9d1248da21f080d2613a4bb38655ed67 refs/heads/release/1.4
5c011a9e9d1248da21f080d2613a4bb38655ed67 refs/heads/rescue/backport-partial
5c011a9e9d1248da21f080d2613a4bb38655ed67 HEAD
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
```
<!-- /snippet -->

All four layers, in order: the record, the anchor, the copy, the bundle. And one more copy with a different purpose: `rehearsal`. That is the accident investigator's advantage from V180: a repository can be copied in seconds, so you can rehearse the repair on the copy.

**[ON SCREEN]** GitHub side. Layer label: GitHub.

Open your own practice repository in a browser, in the normal way. The interface changes, the lab's text and the linked documentation are the reference, and nothing was captured by the authors. This is only to show where one instrument is. Find the repository's Activity view, wherever the current interface places it. In it, find by function: the filter for the branch, the filter for the activity type, which the documentation lists as direct pushes, pull request merges, force pushes, branch creations and branch deletions, and on one entry the control that compares the before and after commit. That is all. The documentation does not describe a restore action there, and this course does not claim one.

## COMMON MISTAKES

1. **Skipping preservation because the fix is "quick".** Root cause: the cost of a backup ref is one second, and the cost of a wrong fix without one is work that exists nowhere else.
2. **Making a bundle before anchoring.** Root cause: a bundle holds what refs and HEAD reach; a commit known only to a reflog is not in it.
3. **Relying on a backup ref when uncommitted work is involved.** Root cause: a ref preserves commits; the index, the working tree and operation state are preserved only by a copy.
4. **Running `git gc` or tidying branches during an incident.** Root cause: reflogs and unreachable objects are the evidence, and cleanup removes exactly those.
5. **Looking for "who pushed" in the commit.** Root cause: author and committer are text set by the client; the authenticated account is recorded only on the platform.

## PRODUCTION EXAMPLE

`main` of a model-serving repository moved backwards on Friday evening. The on-call engineer does not start by moving it forward again.

In her own clone, which fetched in the morning and again at night, `git reflog show origin/main` gives the two IDs: where the remote-tracking branch was, and where the forced update put it. She anchors the old ID with a backup ref before anything else and records the output. That is the Git half: the state, and the two commits.

The GitHub half answers the rest. The Activity view filtered by force pushes names the authenticated account and the time. Rule Insights says whether a ruleset evaluated that update and whether the actor bypassed it. The audit log shows whether a rule was edited shortly before. She exports what she finds the same evening, because the sources have different lifetimes and some are short. On Monday she can answer all four questions of the hook, each with its source, and the repair itself, restoring the ref, was done from the anchored ID with a lease.

## PRACTICE EXERCISE

Do Lab 35.3, "Preserve evidence, then fix", in [`lab-manual/m35-diagnosis-method.md`](../../lab-manual/m35-diagnosis-method.md). In this sitting, do it up to and including the preservation.

Before you preserve, write down for this repository what each of the four layers would hold and what it would miss, and in particular where the colleague's hand-made resolution would survive. Then preserve, and check your prediction by looking inside the copy and at the list of refs in the bundle. Leave the fix for after the next video, or attempt it now and compare later.

The challenge is Exercise 12.9, Level 4, "A branch that looks like `main`", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q405: "Compare a backup ref, a copy of the repository and a bundle: what does each preserve, and what does each miss?"

Answer aloud. A strong answer treats the three as layers with increasing reach and cost, and for each gives both lists, kept and missed, in concrete terms: commits, reflogs, the index, uncommitted files, operation state, configuration. It says in which situation each is the right choice, and why the order of two of them matters. It mentions what none of them holds, which is anything that only the server has. A complete answer adds the care a copy needs, because of what a repository can contain besides code.

## RECAP

- Before the first state-changing command, preserve: record the output, anchor with a ref, and for uncommitted work or an open operation copy the whole directory; a bundle when the evidence must leave the machine.
- A backup ref keeps commits; a copy keeps everything local; a bundle keeps what refs and HEAD reach and no reflogs.
- `git fsck --lost-found`, `git fetch`, especially with pruning, and `git status` are not strictly read-only.
- Git records the state and the local commands; GitHub records which account moved a server ref, when, from where to where, and what the rules decided.
- GitHub-side evidence has limits and lifetimes, some facts about it are unverified, and it should be exported on the first day.

## HOMEWORK

Read sections 29.7 and 29.8. Then write, for your own team's main repository, one line per GitHub-side source: can you read it, and how far back does it go for your plan? Where you do not know, write how you would find out. The next video ranks fixes by what they can destroy and defines what "verified" means.
