# V193: The incident summary a CTO needs, blameless postmortems, and turning a root cause into a control

- **Part.** 9, Production debugging and incident response
- **Module.** 38
- **Planned minutes.** 22
- **Prerequisites.** V192
- **Textbook sections.** [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.15 and 30.19 to 30.23
- **Demo scripts.** `labs/incidents/lab-38-1-timeline.sh` (snippets `01-deployment`, `02-rewrite`, `03-adoption`, `04-detection`)

## HOOK

**[ON SCREEN]** "Is it over? And will it happen again?"

The repository is repaired. The check script would pass. You are tired, and the CTO stops you in the corridor with those two questions. You begin to explain the interactive rebase, the todo list, the lease. After thirty seconds the CTO interrupts: "I did not ask what you typed."

A CTO reads an incident summary to decide three things: whether customers or outsiders are affected, whether anything is still at risk, and whether to spend money or attention on prevention. Commands do not help with any of them.

## INTRODUCTION

The last nine videos were about the repository. This one is about what remains when the repository is fine: the summary, the postmortem and the control. The textbook calls these the parts that are not Git, and they are the parts by which other people judge whether the incident was handled.

Three subjects. The four-part summary, and the one thing that must never be claimed in its third part. The blameless postmortem, with a template, and the reason why "blameless" is a technical requirement and not a courtesy. And the step from a root cause to a control, with a ranking of controls by strength.

There are no new commands. The terminal segment builds a timeline, because a summary and a postmortem are only as good as the timeline under them, and every line of a timeline needs a source.

## LEARNING OBJECTIVES

After this video you can:

1. Write the four-part incident summary and say what must never be claimed in its third part.
2. Build a timeline in which every line names the source of its fact.
3. Write a blameless postmortem with the template.
4. Turn a root cause into a control and classify it as prevent, detect or recover.
5. Say how you know a control works.

## CONCEPT

**The summary.** Four parts, in this order, fitting on one screen.

**[ON SCREEN]** The table of section 30.15.

| Part | The question it answers | Rules |
|---|---|---|
| 1. What happened | What was affected, for how long, with what impact | Impact first, in business terms. Times with a time zone. No names |
| 2. Root cause | Which mechanism, on which layer | One sentence, with the layer named: a Git default, a GitHub rule that was missing, a GitHub Actions default |
| 3. What was done, and how it was verified | Is it over | The recovery in one sentence, and the check that proves it. State what is **not** yet verified |
| 4. Prevention | Will it recur | The control, its owner, its date. A control, not a promise to be careful |

The third part carries the rule of this video: never write that something was verified unless you ran the check. And state what is not yet verified. A summary that claims more than was checked fails at the first follow-up question, and after that nothing else in it is believed.

**Five habits make a summary trustworthy.** Separate what you observed from what you infer, and say which is which. Give every time and every ID a source: the reflog entry, the tag, the log line. Say "I do not know yet" early, with the time of the next update. Never write that something was verified unless you ran the check. And send a first, short version before the recovery, as soon as the team knows what to leave alone: silence during an incident is read as "it is worse than they say".

A status without a root cause is still a status. The same four parts, one sentence each, are the spoken answer when the CTO asks in a corridor.

**The postmortem, in one sentence.** A postmortem is a written record of an incident that explains how the system allowed it, so that the system can be changed; "blameless" means it treats every person's action as reasonable given what they knew.

**Why blameless is a technical requirement.** The evidence in the last nine videos came from people: Ravi's reflog, Asha's account of the reset, a developer saying "I committed a password". People who expect blame run `git gc`, re-clone, or stay silent, and the evidence is gone. The textbook cites Google's SRE book, as a secondary source, for the principle of assuming that everyone involved "had good intentions and did the right thing with the information they had". The useful question is never "who ran the command" but "why did running it look right, and why did nothing stop it".

**The test.** Replace every name by a role. If the document still explains the incident, it is about the system. "Ravi force-pushed production" explains nothing. "The production branch accepted a forced update from any member with write access" names something that can be changed.

Write the postmortem within days, while reflogs and memories exist. Have the people involved review the timeline. An action without an owner and a date is a wish. A postmortem whose only action is "be more careful" has not found the cause.

**From root cause to control.** A control is something that still works when the person is new, tired or in a hurry. Controls differ in strength, and the order of the table is the order in which to look for one.

**[ON SCREEN]** The table of section 30.20.

| Strength | Kind of control | Example from the incidents | Why it ranks here |
|---|---|---|---|
| 1 | The server refuses | A ruleset that blocks force pushes on `main` and `production` (incidents 2, 4) | Applies to every client and tool, whatever their configuration |
| 2 | Automation checks | The release job's ancestry test (4); a regression test (9); push protection (3) | Runs every time, but only on what it was written to see |
| 3 | A safe default on the client | `push.default=simple`, `pull.rebase=true`, an ignore rule in the template (2, 5, 3) | Works until someone has another configuration |
| 4 | A step in a checklist or review | `--remerge-diff` for merges (9); read the commit list (6); ancestry of promised fixes (10) | Depends on the reviewer doing it |
| 5 | Training and habit | `git restore` instead of `reset --hard` (1); a new branch after a merge (8) | Decays, and does not reach new people |

**Four questions take you from root cause to control.** Which layer could have refused the action: the platform, the pipeline, the client, a reviewer? What is the strongest control available on that layer and on your plan, since some ruleset features are plan-gated? What will the control block that is legitimate, and what is the path for that case? And how will you know it works: a ruleset's insights, a test that fails when the fix is removed, an attempt in a sandbox.

**Prevent, detect, recover.** The template's action table asks for the type of each control. A ruleset that refuses a forced push prevents. The release job's ancestry test detects: the rewrite had already happened, and the job noticed before deployment. A backup ref, a deployment tag that names the running commit, or a clone that has not fetched is what lets you recover. A good set of actions has at least a prevent and a detect, because every prevention has a bypass.

Prefer one strong control to five weak ones. For the rewritten production branch the list could have ten items. The one that matters is a checkbox on the server. "Engineers will take more care" is not a control.

**When not to use any of this.** Do not run an incident process for a SEV 4. One person's local reset needs ten minutes of help and one note, not a channel and a document.

## MENTAL MODEL

For the summary, think of a pilot's announcement after turbulence. It has four sentences: what happened, why, that the aircraft is fine and how the crew knows, and what will be done differently for the rest of the flight. Nobody in the cabin wants the control inputs. And a pilot who says "everything is checked" before the check is done has spent the passengers' trust for the rest of the flight.

Where the picture breaks: passengers cannot act on what they hear. A CTO can and will: the fourth sentence is a request for a decision, with an owner and a date in it.

For blamelessness, think of the next incident. The person who caused this one holds the evidence for it, and will be near the next one too. Whatever happens to them now decides whether the next reflog is pasted into the channel or quietly collected.

For controls, the ranking is a ladder again, and this time you climb as high as you can. V184's ladder said: take the lowest rung that repairs. This one says: take the highest rung that prevents.

## DIAGRAM

**[DIAGRAM]** The summary form of section 30.15, written for the rewritten production branch. Show it as a slide and read it part by part.

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

Point at four things. The subject line carries status, severity and impact. The root cause names both layers: "Git allows this; our GitHub rules did not block it". The third part has the words "Not yet verified". And there is no name anywhere.

**[DIAGRAM]** The postmortem template of section 30.19, as a second slide.

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

Three lines carry most of the weight. The timeline has a third column: the source of the fact. "Contributing conditions" is where blamelessness is done: what made the action look right. And the last column of "Actions": how we will know it works.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run incidents/lab-38-1-timeline`. The sandbox is the rewritten production branch of V189. We build its timeline. Every command is 🟢 SAFE except the one fetch, which moves a remote-tracking ref and records the old value in its reflog. For each line of the timeline we write three things: the time with its zone, the event, and the source.

**The deployment.** When was the running commit deployed, and which commit is it?

```bash
git fetch
git for-each-ref --format='%(refname:short)  %(taggerdate:iso)  %(taggername)  %(subject)' refs/tags
git log -1 --format='%h  %cd  %s' --date=iso 'deploy-2026-09-07^{commit}'
```

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

Timeline line one: 10:14, plus 05:30, the release job tagged `3277739` as deployed. Source: the annotated tag, its tagger date and its message. The tag is a witness that no later rewrite could alter.

**The rewrite.** When was the branch rewritten, and when was the rewrite published? Predict which clone's reflogs can answer.

```bash
git -C ../ravi reflog show --date=iso production
git -C ../ravi reflog show --date=iso origin/production
```

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

Two more lines. 10:25: a rebase of `production` finished in one clone; 10:26: the result was amended. Source: that clone's branch reflog. 10:27: the rewritten branch was pushed. Source: that clone's reflog of the remote-tracking branch, "update by push". In the document these lines say "a rebase finished in a developer's clone", not a name.

**The adoption.** When did a second clone adopt the rewrite, and when did new work land on it?

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

10:28: a second clone fetched and saw a forced update. 10:29: its branch was reset to the server's. 10:30: a new commit was made on top. 10:31: that commit was pushed. Four lines, four sources, from two reflogs of the second clone.

**The detection.**

<!-- snippet: incidents/lab-38-1-timeline/04-detection -->
```text
# When did this clone first see it? (In real life: the time of the alert.)
$ git reflog show --date=iso origin/production
4fae70f refs/remotes/origin/production@{2026-09-07 10:33:00 +0530}: fetch: forced-update
3277739 refs/remotes/origin/production@{2026-09-07 10:15:00 +0530}: update by push
```
<!-- /snippet -->

10:33: our own clone first saw the forced update. In real life the detection line is the time of the alert: here, the release job's refusal.

**[PAUSE]** Now read the timeline as the postmortem would. From 10:27 to the restore, the server's branch pointed at a rewritten history: that is the window of the summary's first part. Between the publication at 10:27 and the detection, six minutes passed, and in those six minutes a second clone adopted the rewrite and shipped on top of it. That interval is the "Detection" section, and it is the argument for the control: the earlier the server refuses, the shorter this list.

Notice what the sandbox let us do that real life does not. We read two colleagues' reflogs directly. In real life you ask a colleague to run `git reflog show --date=iso origin/production` and paste it. Whether they do depends on what happened to the last person who pasted one.

**[ON SCREEN]** From this timeline to the control, with the four questions. Which layer could have refused? The platform: the push at 10:27 was a forced update of a production branch. The strongest control there: a ruleset that blocks force pushes, with an empty bypass list. What legitimate action does it block, and what is the path for it? A deliberate history repair, like the restore in V189; the path is a recorded, temporary change of the rule by its owner. How will we know it works? The ruleset's insights, and one attempt in a sandbox. Type: prevent. And the detect control already exists and worked: the release job's ancestry test.

## COMMON MISTAKES

1. **Answering the CTO with commands.** Root cause: the summary is written from the engineer's experience of the incident instead of from the three decisions its reader has to make.
2. **Writing "verified" for something that was inferred.** Root cause: the check was not run, and the claim was made to make the incident sound closed.
3. **A timeline without sources.** Root cause: times were taken from memory or chat, so they cannot be reconciled when two accounts differ.
4. **A postmortem that names a person as the cause.** Root cause: it explains who acted instead of why the action looked right and why nothing stopped it, so it changes nothing in the system and teaches people to hide evidence.
5. **"We will be more careful" as the action.** Root cause: no layer was identified that could have refused the action, so there is nothing that still works when someone is new, tired or in a hurry.

## PRODUCTION EXAMPLE

After the rewritten production branch of a billing service has been restored, the engineer who led the recovery writes the summary before she goes home. It is the slide you saw: four parts, one screen, with one sentence that says what is not yet verified, the CI caches, and when it will be.

The postmortem follows within three days. She builds the timeline from two colleagues' reflogs, which they paste without hesitation, because the first sentence she said to them on the day was "nobody is in trouble; I need your reflogs before you fetch again". Under "Contributing conditions" she writes what made the clean-up look right: the branch had accumulated fixup commits, the developer had been told to keep history tidy, and nothing distinguished `production` from any other branch at the moment of the push. Under "What went well": an ancestry check in the release job that somebody added two years earlier.

The action table has two rows. A ruleset on `production`, type prevent, owner the platform team, active the same day, verified by an attempted forced push in a test repository with the same ruleset. And an alert on the release job's refusal, type detect, so that the next refusal reaches a person in minutes. She resists adding eight more rows.

## PRACTICE EXERCISE

Do Lab 38.1, "A timeline and a CTO summary", in [`lab-manual/m38-communication-postmortems.md`](../../lab-manual/m38-communication-postmortems.md).

Before you run a command, list the events you expect the timeline to contain and, for each, predict which repository's reflog or which tag will be its source. Then build the timeline with a source on every line. Write the four-part summary on one screen, mark each statement in the third part as observed or inferred, and include one sentence that begins "Not yet verified". Then say the four parts aloud, one sentence each, in under a minute.

The challenge is Lab 38.2, "A blameless postmortem", in the same file. Apply the test: replace every name by a role and read it again.

## INTERVIEW QUESTION

**[ON SCREEN]** Q377: "What are the four parts of an incident summary for a CTO, and what must never be claimed in the third?"

Answer aloud, in under two minutes. A strong answer gives the four parts in order and, for each, the question it answers for the reader, not only its title. It gives the rules that make each part usable: impact first and in business terms, the layer named in the root cause, an owner and a date in the prevention. For the third part it states the rule and its positive counterpart: what you do write when a check has not been run yet. If you add when the first version of a summary is sent, and why, you have shown that you understand it as a tool during the incident and not as paperwork after it.

## RECAP

- The summary has four parts: what happened, the root cause with its layer, what was done and how it was verified, and what prevents a repeat.
- Never write "verified" for a check that was not run, and always state what is not yet verified.
- Every line of a timeline carries its source: a reflog entry, a tag, a log line, a message.
- A postmortem is blameless so that it explains the system and so that people keep handing over evidence; replace names by roles to test it.
- A control is ranked by what enforces it, from "the server refuses" down to habit, and it comes with an owner, a date and a way to know that it works.

## HOMEWORK

Read sections 30.15 and 30.19 to 30.23, and do the Practice section, 30.25. Then finalize your copy of [`playbooks/disaster-recovery-playbook.md`](../../playbooks/disaster-recovery-playbook.md) with your own notes from the ten incidents: for each, the decisive evidence and the one control you would ask for. The next video is the briefing for Gate 9.
