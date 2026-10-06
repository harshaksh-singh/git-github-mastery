# Module 38 labs: communication, postmortems and the senior standard

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Every "Expected output" block is real output from a replay script in `labs/incidents/`. Read [Chapter 30: Incident Response](../textbook/ch30-incident-response.md), sections 30.15 to 30.20, first. Do Modules 36 and 37 before this one: these labs reuse their incidents.

## How these labs work

Modules 36 and 37 trained the diagnosis and the repair. This module trains what surrounds them: establishing a timeline from evidence, writing for a CTO, writing a postmortem that changes the system, and doing the three scenarios of the senior standard without the book and against a clock.

| Lab | What you produce | Uses |
|---|---|---|
| 38.1 | A sourced timeline and a four-part CTO summary | incident 4 |
| 38.2 | A blameless postmortem with ranked controls | an incident of your choice |
| 38.3 | The eleven-step recovery, timed, closed book | incident 5 |
| 38.4 | A secret-leak response: the order, the record, the Git part, timed | incident 3 |
| 38.5 | The Actions investigation order on paper, and optionally a real run on GitHub | incident 7 |

The written products of this module are what an interviewer or a CTO sees. Keep them: you will reuse the templates.

Lab 38.5 has an optional GitHub-side part. **GitHub-side steps run in your normal shell, not in `labs/shell`:** the lab shell switches off the system configuration, where your credential helper is configured, so it cannot authenticate to GitHub. Results on GitHub are described from the documentation and were not run by the author.

Answers and model texts are in [solutions/m38-lab-answers.md](../solutions/m38-lab-answers.md). Write your own first.

## Lab 38.1: A timeline and a CTO summary

### Objective

Reconstruct the timeline of incident 4 from reflogs, a tag and commit metadata, with a source for every line, and write the four-part summary of Chapter 30, section 30.15.

### Prerequisites

- Lab 37.2 completed.
- Chapter 30, sections 30.3 and 30.15.

### Setup

```bash
incidents/04-production-history-rewritten/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/04-production-history-rewritten"
```

### Commands

Every reflog can print its entries with dates. Collect the events from each clone; do not recover anything.

```bash
cd you
git fetch
git for-each-ref --format='%(refname:short)  %(taggerdate:iso)  %(taggername)  %(subject)' refs/tags
git -C ../ravi reflog show --date=iso production
git -C ../ravi reflog show --date=iso origin/production
git -C ../asha reflog show --date=iso production
git -C ../asha reflog show --date=iso origin/production
git reflog show --date=iso origin/production
```

Then write: (1) a timeline table with the columns time, event, source; (2) the four-part summary, at most 150 words; (3) the severity, with one sentence of justification.

### Expected output

<!-- snippet: incidents/lab-38-1-timeline/01-deployment -->
```text
$ cd you
$ git fetch
From ../server
 + 3277739...4fae70f production -> origin/production  (forced update)
$ git for-each-ref --format='%(refname:short)  %(taggerdate:iso)  %(taggername)  %(subject)' refs/tags
deploy-2026-09-07  2026-09-07 10:14:00 +0530  Lab User  Deployed to production by the release job
$ git log -1 --format='%h  %cd  %s' --date=iso 'deploy-2026-09-07^{commit}'
3277739  2026-09-07 10:13:00 +0530  Log the invoice id on failure
```
<!-- /snippet -->

<!-- snippet: incidents/lab-38-1-timeline/02-rewrite -->
```text
# When was the branch rewritten, and when was the rewrite published?
$ git -C ../ravi reflog show --date=iso production
f2783aa production@{2026-09-07 10:26:00 +0530}: commit (amend): Tax calculation, formatting and logging
7fb64db production@{2026-09-07 10:25:00 +0530}: rebase (finish): refs/heads/production onto f46af3da39ea0c36cdbaef0b34e16f4407a78eb6
3277739 production@{2026-09-07 10:24:00 +0530}: branch: Created from refs/remotes/origin/production
$ git -C ../ravi reflog show --date=iso origin/production
f2783aa refs/remotes/origin/production@{2026-09-07 10:27:00 +0530}: update by push
```
<!-- /snippet -->

<!-- snippet: incidents/lab-38-1-timeline/03-adoption -->
```text
# When did a second clone adopt the rewrite, and when did new work land on it?
$ git -C ../asha reflog show --date=iso production
4fae70f production@{2026-09-07 10:30:00 +0530}: commit: Add invoice PDF footer
f2783aa production@{2026-09-07 10:29:00 +0530}: reset: moving to origin/production
3277739 production@{2026-09-07 10:20:00 +0530}: branch: Created from refs/remotes/origin/production
$ git -C ../asha reflog show --date=iso origin/production
4fae70f refs/remotes/origin/production@{2026-09-07 10:31:00 +0530}: update by push
f2783aa refs/remotes/origin/production@{2026-09-07 10:28:00 +0530}: fetch: forced-update
```
<!-- /snippet -->

<!-- snippet: incidents/lab-38-1-timeline/04-detection -->
```text
# When did this clone first see it? (In real life: the time of the alert.)
$ git reflog show --date=iso origin/production
4fae70f refs/remotes/origin/production@{2026-09-07 10:33:00 +0530}: fetch: forced-update
3277739 refs/remotes/origin/production@{2026-09-07 10:15:00 +0530}: update by push
```
<!-- /snippet -->

The dates are those of the fixed lab clock, so your sandbox prints the same times.

### What happened internally

A reflog line stores the old ID, the new ID, the identity, a timestamp and a message; `--date=iso` prints the timestamp in place of the index. Each clone timestamps what **it** did or saw: `update by push` is the moment that clone pushed, `fetch: forced-update` the moment that clone learned of a change. No clone knows when the server changed except the one that changed it.

### Checkpoint

Your timeline has at least seven lines, from the deployment tag to the detection, and every line names the clone and the reflog (or the tag) it comes from. You can state the window between the publication of the rewrite and its detection in minutes.

### Failure scenario

Write a second version of the summary the way it is often written under pressure: start with the commands that were run, name the person, and end with "we will be more careful". Then mark every sentence a CTO cannot use for a decision.

### Recovery

Rewrite it with the four parts in order: impact first, the root cause with its layer, the recovery with its verification and what is not yet verified, the control with an owner and a date. Replace the name by a role.

### Verification

Give both versions to someone who was not involved, or read them aloud after an hour. From the good version alone, three questions can be answered: were customers affected, is it over, what changes.

### Questions

1. Which single reflog entry dates the moment the rewritten history reached the server, and in whose clone is it?
2. Why is your own clone's `fetch: forced-update` time not the time of the incident?
3. The server kept no reflog. What would you have on GitHub in addition to the clones?
4. Which sentence of your summary states something you inferred and did not observe? How did you mark it?
5. Why is the severity of this incident not lowered by the fact that nothing was deployed?

## Lab 38.2: A blameless postmortem

### Objective

Write a complete postmortem for one incident from Module 36 or 37 with the template of Chapter 30, section 30.19, and turn its root cause into ranked controls as in section 30.20.

### Prerequisites

- The incident solved, with your notes from the drill.
- Chapter 30, sections 30.19 and 30.20.

### Setup

Choose incident 2, 4, 6 or 9: each has a missing control on more than one layer. Regenerate it if you need to re-read evidence:

```bash
incidents/09-misunderstood-conflict/generate.sh
```

### Commands

No Git commands beyond the read-only ones you need for the timeline. Fill in every heading of the template. For the "Actions" table, list at least four candidate controls and assign each a strength from 1 (the server refuses) to 5 (training), then mark the one you would implement first.

### Expected output

A document of one to two pages. Its root-cause section is the seven-line box of Chapter 1, section 1.10. Its timeline has a source column. Its actions have an owner, a date and a line "how we will know it works". The model in the answers file is for incident 9; compare structure, not wording.

### What happened internally

A postmortem moves the explanation from a person's action to the conditions that allowed it. The same evidence supports both stories; only the second names something that can be changed.

### Checkpoint

Apply the role test of section 30.19: replace every name by a role. The document must still explain the incident.

### Failure scenario

Take your "Contributing conditions" section and rewrite it as a blame statement ("X should have known that ..."). Write down which pieces of evidence from the drill you would **not** have obtained if the people involved had expected that sentence.

### Recovery

Restore the blameless version. For each piece of evidence on your list, add to "What went well" the behavior that made it available (a developer who stopped and asked, a reflog nobody cleaned up, a report made voluntarily).

### Verification

Every action in the table answers: which layer refuses or detects, who owns it, by when, and how it is tested. No action reads "be careful", "remember" or "communicate better".

### Questions

1. Why is "blameless" a requirement for the quality of evidence and not only a matter of courtesy?
2. For your incident, what is the strongest available control and why is it stronger than the second one on your list?
3. What legitimate work does your strongest control block, and what is the path for that case?
4. Which item of your postmortem is a detection control, and what does it not detect?
5. How will you know in three months that the action was effective?

## Lab 38.3: Senior standard 1, against the clock: the rebased and force-pushed branch

### Objective

Perform the eleven steps of Chapter 30, section 30.16 on a freshly generated incident 5 in 30 minutes, without the book, with a written line for every step.

### Prerequisites

- Lab 36.5 completed at least a day earlier.
- The eleven steps by heart: inspect the state, inspect refs, inspect the reflog, identify the old branch state, understand what changed, preserve recoverable references, determine the safest recovery, restore the correct history, update the pull request safely, explain what happened, prevent recurrence.

### Setup

```bash
incidents/05-rebased-shared-branch/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/05-rebased-shared-branch"
```

Close the book and the solution. Start a timer.

### Commands

Yours. For each of the eleven steps write one line before you type: what you expect to learn or change, and the risk label of the command. Steps 1 to 6 must not move a ref.

### Expected output

Step 1, the pull request as it is:

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

Step 9, the pull request after the repair:

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

Your new commit IDs differ from these, because your rebase runs with the real clock.

### What happened internally

Steps 1 to 5 read three reflog files and the object database. Step 6 writes two refs. Step 8 moves one local branch twice. Step 9 replaces one ref on the server, on the condition that it still has the value you examined.

### Checkpoint

At the end of step 6, before any ref has moved, you can say aloud: the three IDs, what each one is, and which option you rejected and why.

### Failure scenario

Repeat the drill up to step 8. Before step 9, play the teammate: in `asha/`, run `git pull --ff-only`, commit a small change on the branch and push it. Then do step 9 in `you/` with the ID you examined earlier.

<!-- snippet: incidents/lab-38-3-lease/01-lease-refuses -->
```text
# Meanwhile Asha updates her clone, commits and pushes:
$ cd asha
$ git pull -q --ff-only
$ git commit -q -m 'Report how many entries were warmed'
$ git push -q
# Step 9 in your clone, with the ID you examined:
$ cd ../you
$ git push --force-with-lease=feature/online-serving:6e7ebbd origin feature/online-serving
To ../server.git
 ! [rejected]        feature/online-serving -> feature/online-serving (stale info)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

`(stale info)`: the server's branch is no longer the commit you examined, so the lease refuses. That is the lease working. Now make the wrong move and remove the obstacle:

<!-- snippet: incidents/lab-38-3-lease/02-failure -->
```text
# The tempting move: the lease is "in the way".
$ git push --force origin feature/online-serving
To ../server.git
 + cfee272...5366874 feature/online-serving -> feature/online-serving (forced update)
$ git log --oneline origin/main..origin/feature/online-serving
5366874 Decode batched values
7debded Add batched online lookup
d4fd03c Add cache warm-up job
5e57ed9 Decode online values
c8d1712 Add online lookup
```
<!-- /snippet -->

Five clean commits, and the teammate's commit is gone from the server.

### Recovery

<!-- snippet: incidents/lab-38-3-lease/03-recovery -->
```text
# Her commit is no longer on the server. Her clone has it, and the standard instruction finds it:
$ cd ../asha
$ git fetch
From ../server
 + cfee272...5366874 feature/online-serving -> origin/feature/online-serving  (forced update)
$ git cherry -v origin/feature/online-serving feature/online-serving
+ be7fb7a56b83749158f537ff0bee349541ce09b5 Add online lookup
+ 8f79c4202b0823ed1b04cf7745b70954e9fcd554 Decode online values
+ 4967e71e446d83bc9c71b6ecb2b7fd6914bb6553 Add cache warm-up job
- af1f6de0a8d4796085edf1d3742e08f2132dbade Add batched online lookup
- 57b597270111c4042d1fc8182815e4bcded25138 Decode batched values
+ cfee272e6dafec360ef02e4e803b4c153eaf711a Report how many entries were warmed
$ git branch rescue/mine
$ git reset --keep origin/feature/online-serving
$ git cherry-pick rescue/mine
[feature/online-serving 37646e5] Report how many entries were warmed
 Date: Mon Sep 7 10:38:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 store/warm_metrics.py
$ git push
To ../server.git
   5366874..37646e5  feature/online-serving -> feature/online-serving
$ git log --oneline origin/main..origin/feature/online-serving
37646e5 Report how many entries were warmed
5366874 Decode batched values
7debded Add batched online lookup
d4fd03c Add cache warm-up job
5e57ed9 Decode online values
c8d1712 Add online lookup
$ git branch -D rescue/mine
Deleted branch rescue/mine (was cfee272).
```
<!-- /snippet -->

Read the `git cherry -v` output with care. It shows four `+` lines, and only the last is new work. The first three are the old copies of the rebased commits, which her branch still holds through the merge; their rebased equivalents are ancestors of both sides, and `git cherry` compares only against commits that the upstream has and the branch lacks. The instruction "any `+` line: stop and ask" is the right one for exactly this reason: a person has to read the subjects.

The right step 9 after a refused lease is to fetch, examine what arrived, integrate it, and push with a lease on the new value.

### Verification

`incidents/05-rebased-shared-branch/check.sh` exits 0 within the time limit, and your notes have eleven lines.

### Questions

1. Which of the eleven steps did you want to skip, and what would you have missed?
2. At which step does the first ref move, and which steps make that move safe?
3. Why does step 9 name an explicit ID in the lease?
4. Say step 10 in three sentences, without a name and without a command.
5. Which step would be different on GitHub with a ruleset that blocks force pushes on the branch?

## Lab 38.4: Senior standard 2, against the clock: a committed secret

### Objective

Run the complete response to incident 3: state the order, keep the incident record, do the Git part in 40 minutes, and write the two messages.

### Prerequisites

- Lab 37.5 completed at least a day earlier.
- Chapter 30, section 30.17; [Chapter 21B](../textbook/ch21b-repository-security-incident-response.md), section 21B.14.

### Setup

```bash
incidents/03-committed-secret/generate.sh
labs/shell "$HOME/git-mastery-labs/incidents/03-committed-secret"
```

Open an empty file `incident-record.md` outside the sandbox. Start a timer.

### Commands

Yours. The first entry in the record is a time and the words `credential revoked at the issuer by <role>`, written before the first Git command. In the sandbox that entry is an act of imagination; in real life it is the step on which everything depends. Then: scope, decision on the rewrite with its reason, rewrite, publication, dependent branch, server, clones.

### Expected output

The decisive moment of the drill, after the forced push: the server still serves the old commit.

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

At the end the check prints seventeen `ok` lines and the note that it sees Git state only.

### What happened internally

A force push changed one file under `refs/heads/` on the server. The commit, tree and blob objects stayed in its object database until `git gc --prune=now` deleted them. In each clone the same objects are kept alive by reflog entries, which is why the clones need the two destructive commands or a fresh clone.

### Checkpoint

Before the rewrite, the record has the five assessment facts of section 30.17, and the decision "rewrite: yes or no" with a reason that would still make sense to a reader in six months.

### Failure scenario

Do the Git part first and "rotate" last. Measure the minutes between the start of the drill and your rotation entry. That number is the additional exposure your ordering caused, and in a real incident it is added to the time the secret had already been public.

### Recovery

Repeat with the correct order. The Git part takes the same time; the exposure after detection drops to the time you need to reach the issuer's console.

### Verification

`incidents/03-committed-secret/check.sh` exits 0. The record contains: the rotation entry first; the exposure window with its source (the reflog line of the first push); the list of refs; the rewrite decision; the instruction sent to the team; the open item `issuer's access log reviewed by <role>`.

### Questions

1. What ends the exposure, and what only reduces discoverability?
2. Which reflog line gives the start of the exposure window, and why is the commit date not the right time?
3. What exactly do you tell a teammate who fetched the branch this morning?
4. Which three facts does the CTO need that Git cannot provide?
5. Which control would have stopped this particular string, and which widely recommended control would not have?

## Lab 38.5: Senior standard 3: GitHub Actions suddenly fails

### Objective

Apply the fixed investigation order to a failing workflow from the evidence alone, in 15 minutes, and optionally confirm the diagnosis with a real run in your practice organization.

### Prerequisites

- Lab 37.4 completed.
- Chapter 30, section 30.18; [Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md), sections 20B.11, 20B.14 and 20B.15.

### Setup

```bash
incidents/07-ci-passes-locally/generate.sh
```

Print or open `incidents/07-ci-passes-locally/evidence/ci.yml` and `RUN-REPORT.md`. The run report is constructed for the exercise.

### Commands

On paper, from memory, the twelve areas in order: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency. For each: the question, the answer from the evidence, the verdict. Then the commands you would run on GitHub, written down, not run:

```bash
gh run list --workflow ci.yml --branch main --limit 20
gh run view <run-id> --json event,headBranch,headSha,workflowName
gh run view <run-id> --log-failed
```

Then reproduce the runner's clone with Git, as in Lab 37.4.

### Expected output

The reproduction that confirms the paper diagnosis:

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

### What happened internally

The checkout step created a repository with one commit object's history and no tag refs. `git describe` walks parent links from HEAD and looks for commits that a tag names; it found neither parents nor tags.

### Checkpoint

Your table reaches a verdict for all twelve areas, and at least eight of them are answered without any log.

### Failure scenario

Optional, on GitHub, in your normal shell. Publish the sandbox repository to your practice organization and watch the workflow fail for real. These commands create a private repository under your account; the results are described from the documentation and were not run by the author.

```bash
cd "$HOME/git-mastery-labs/incidents/07-ci-passes-locally/you"
gh repo create <your-practice-org>/eval-reports-drill --private --source . --remote github --push
git push github v1.4.0
gh run list --workflow ci.yml --limit 1
gh run view <run-id> --log-failed
```

Per the documentation the push to `main` starts the workflow `CI`, and the step "Compute version" fails, because the checkout fetched one commit and no tags ([checkout README](https://github.com/actions/checkout/blob/v7.0.1/README.md)). Compare the real log line with the run report.

### Recovery

Make the two fixes of Lab 37.4 on a branch, push it and open a pull request:

```bash
git switch -c fix/ci-checkout
# edit .github/workflows/ci.yml (fetch-depth: 0) and reports/render.py (the template name as tracked)
git commit -a -m "Fetch full history and tags in CI; fix template name case"
git push -u github fix/ci-checkout
gh pr create --fill --base main --head fix/ci-checkout
gh run watch
```

If you fix only the checkout, you can observe whether the second defect appears. The Phase 0 report could not confirm from official documentation that hosted runners' filesystems are case-sensitive; this run settles it for the runner you used.

### Verification

On paper: your verdict matches the solution of incident 7. On GitHub: `gh run list --workflow ci.yml --branch fix/ci-checkout --limit 1` shows a completed, successful run. Delete the practice repository afterwards if you do not need it.

### Questions

1. Why does the order start with "workflow" and "event" and put "logs" ninth?
2. Which three questions separate "something in the repository changed" from "something outside changed"?
3. What does a re-run reuse, and why can a re-run therefore not fix this failure?
4. Name two things a local emulator of Actions cannot reproduce, according to its own documentation.
5. What is the honest status report between "fix pushed" and "run green"?
