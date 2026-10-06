# V185: An incident and the loop that handles one, severity, and how to run the ten incidents

- **Part.** 9, Production debugging and incident response
- **Module.** 36
- **Planned minutes.** 16
- **Prerequisites.** V184
- **Textbook sections.** [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.1 to 30.4; [`incidents/README.md`](../../incidents/README.md)
- **Demo scripts.** `labs/incidents/lab-36-1-hard-reset.sh` (named only; no snippet is shown before the learner's attempt)

## HOOK

**[ON SCREEN]** "`main` is broken, the release is in an hour, and nobody knows what happened."

At some point a message like this arrives. The CTO who receives it does not want a command. The CTO wants four answers: what happened, how you know, what you changed and how you proved it worked, and why it will not happen again.

You have a method for one repository and one symptom. An incident adds three things the method alone does not cover: other people, whose clones hold evidence and who keep working while you investigate; time pressure, which makes the destructive shortcut attractive; and an audience that has to decide something on the basis of what you tell them.

## INTRODUCTION

This video opens the incident drills. No new Git mechanism is taught in this chapter. Every recovery uses techniques you already have. What is new is the order in which you apply them when the report is wrong, the clock is running, and three clones disagree.

Three things today. The loop that handles an incident, in seven stages. A severity scale and three rules for using it. And the practical part: how the ten incidents are built, how you generate one, enter it and check your recovery.

Then one rule that governs every remaining video of this part. Each incident video has a pause point. You generate the incident and attempt it before you watch the debrief. A drill whose cause you have seen cannot be repeated.

## LEARNING OBJECTIVES

After this video you can:

1. Name the stages of the incident loop in order.
2. Rate the severity of a Git or GitHub incident and defend the rating.
3. Generate an incident sandbox, enter it and check a recovery.
4. Follow the ten-part format for a drill.
5. Explain why the solution is read only after an attempt.

## CONCEPT

**An incident, in one sentence.** An incident is a problem in shared state, a shared branch, a published history, a credential, a pipeline, that other people depend on while you are still working out what it is.

**The loop.** Seven stages. It is the root-cause framework with the stages that only exist when other people are involved.

**[ON SCREEN]** The table of section 30.2, one row at a time.

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

**Where the evidence lives.** In an incident the evidence is spread over several repositories, and each kind lives in a specific place.

| Evidence | Where it lives | Read it with | Lifetime |
|---|---|---|---|
| Every value a local branch had | `.git/logs/refs/heads/<branch>` in that clone | `git reflog show <branch>` | 90 days; 30 for entries no longer reachable; gone when the branch is deleted |
| Every commit HEAD was on | `.git/logs/HEAD` | `git reflog` | same; survives branch deletion |
| What the server's branch was at each fetch or push from this clone | `.git/logs/refs/remotes/origin/<branch>` | `git reflog show origin/<branch>` | same; gone when the ref is pruned |
| What the server holds now | the server | `git ls-remote origin` | current value only |
| Staged content that was never committed | a dangling blob in `.git/objects` | `git fsck --lost-found` | two weeks after it becomes unreachable, once maintenance runs |
| Who pushed what, and force pushes | GitHub, not Git | the Activity view, `PushEvent` records, the audit log | see V183 |

The retention periods are Git's defaults; the lab configuration switches reflog expiry off. And one fact decides how you treat colleagues' clones: a bare repository, which is what a server holds, keeps no reflog unless `core.logAllRefUpdates` is set. So the history of a server-side branch exists only as the sum of what the clones remember, plus whatever the hosting platform records. That is why "preserve" includes asking colleagues not to run `git fetch --prune`, `git gc` or a re-clone until you have read their reflogs.

**Severity.** Severity decides who is told and how fast, not how interesting the Git problem is. The textbook's scale is a working scale for repository incidents, to be adapted to your organisation's own. It asks three questions: which state was affected, could wrong code or a secret have reached users or outsiders, and is anything unrecoverable.

| Level | Definition | Who is told, when |
|---|---|---|
| SEV 1 | A secret that unlocks production was exposed, or wrong code reached production, or shared history is unrecoverable | CTO and security at once; updates on a fixed rhythm |
| SEV 2 | A shared default or release branch held wrong content, or a merged fix was silently lost; caught before or shortly after release | Engineering lead at once; CTO in the summary |
| SEV 3 | A team is blocked or a pull request is unreviewable; no wrong content on a protected branch | The team; lead on request |
| SEV 4 | One person's local work | The person; nobody else unless a habit needs changing |

Three rules for using a scale. Assign the level on what could have happened in the window, not only on what did. Raise the level the moment a secret is involved; lowering it later costs nothing. And never let severity depend on who caused the incident.

The first rule is the one people resist. The textbook's example is a rewritten production branch that shipped nothing and is still SEV 2, because the only thing between the rewritten branch and production was one check.

**The ten incidents.** Each is a directory under `incidents/` with three files.

| File | What it is | When to read it |
|---|---|---|
| `SYMPTOMS.md` | What the people involved reported, in their words | First |
| `generate.sh` | Builds the sandbox. It is also the full answer to "what happened" | After your attempt |
| `check.sh` | Verifies your recovery with read-only commands; exit status 0 means recovered | When you think you are done |

The report is incomplete and partly wrong, as real reports are. The generator is the answer and is read last.

**The ten-part format.** The textbook uses the same ten headings for every incident, and so should your notes: symptoms, evidence, hypotheses, diagnostic commands, root cause, safe recovery, verification, prevention, communication, postmortem.

**Why the solution comes last.** The value of a drill is the diagnosis you make without help. Once you have read the cause, that drill cannot be repeated. A diagnosis you have read cannot be made again.

## MENTAL MODEL

The textbook's analogy is a ward doctor with an unstable patient. The doctor follows a fixed sequence: stabilise, record, diagnose, treat, confirm, hand over. The sequence exists because under pressure people skip to treatment.

The analogy breaks in two places, both in your favor. A repository can be copied in seconds, so a treatment can be rehearsed on a copy. And Git almost never destroys committed work by itself, so "stabilise" usually means stopping people, not stopping a process.

That second point changes what the first minute looks like. In most Git incidents the first act is a sentence, not a command: "Nobody pushes to or resets this branch until I say so." The textbook's production example is exactly that: an ML platform team deploys an inference service from a branch called `production`, the deploy job refuses to run, and stage 1 is one sentence in the channel.

## DIAGRAM

**[DIAGRAM]** The diagram of section 30.2. Start on the left with the report. In the middle, draw the places where evidence is, one line per clone and one for the platform. On the right, the one shared state they all point at. Then the seven stages underneath, with their risk labels, and last the arrow that runs from stage 1 to stage 6.

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

Point at "has not fetched yet". A clone that has not fetched is a witness: it still holds the server's old state. Point at "no reflog of its own". And trace the long arrow at the bottom: communication starts at stage 1.

## LIVE TERMINAL DEMO

**[ON SCREEN]** Open [`incidents/README.md`](../../incidents/README.md) and read its table: ten incidents, each with the sentence the report says. "I think `git pull` ate my work." "The top commit on `main` says WIP." "It is pushed. GitHub must be caching." Each sentence is what a colleague believes. None is a diagnosis.

**How to run one.** All commands are typed in the course root.

```bash
incidents/01-hard-reset/generate.sh        # builds the sandbox and prints its path
labs/shell "<the path it printed>"         # a shell with the isolated lab configuration
```

Every sandbox has the same layout.

```text
  server.git     a bare repository: the server, the part GitHub plays in real life
  you/           your clone
  asha/  ravi/   your teammates' clones, each with its own user.name and user.email
```

You are allowed to look into and work in every clone, the way you would sit down at a colleague's machine during an incident. `git -C ../ravi <command>` runs a command in Ravi's clone without leaving yours. You are also the administrator of `server.git`. Two read-only commands to orient yourself in any sandbox are `git ls-remote origin`, for what the server holds, and `git branch`, in each clone.

The generator runs with the fixed lab clock, so the commit IDs in your sandbox equal the IDs printed in the solutions and in Chapter 30. Commits that you create in the lab shell use the real clock and get other IDs. Running the generator again deletes the sandbox and builds it afresh. Do that whenever a repair went wrong: an incident sandbox is the one place where a destructive mistake costs nothing.

**How to solve one.** Seven steps, from the README: read the symptoms and write the symptom in one sentence without interpretation; collect evidence with read-only commands only, in each clone that matters; write at least three hypotheses and the command that tells them apart; preserve before you change; choose the fix that destroys least and run it one command at a time; verify with the commands that showed the problem; and write the four lines a CTO needs.

**How to check.**

```bash
incidents/01-hard-reset/check.sh           # checks the sandbox in the default place
```

The check prints one line per condition and ends with `PASS`, exit status 0, or `NOT YET`, exit status 1. A check verifies the state you were asked to reach, not the route you took. It cannot verify the parts of an incident that are not Git state, such as rotating a credential or telling the team.

**[TERMINAL]** No transcript here, on purpose. Incident 1 is the one you attempt after this video, and every snippet of its replay, `labs/run incidents/lab-36-1-hard-reset`, shows part of the answer. So you get the symptom and the form of a failing check in words, and nothing else.

The symptom is the report: Ravi's `git log` no longer lists the commits he made on Friday, and he thinks `git pull` ate them. That is what a colleague believes. It is not a diagnosis.

A failing check has this shape. The script prints one line per condition, each beginning with `ok` or `FAIL`, and it ends with `NOT YET`, the number of failed checks and exit status 1. Each `FAIL` line names something the recovery was supposed to keep or restore.

**[PAUSE]** Stop here. Do not run the replay of Incident 1 and do not open its solution. Generate the incident and find out from the repository what happened. That is your exercise before the next video.

Two things differ from real life, and the README says so. The clock, as explained. And the server: a bare repository has no Activity view, no pull requests, no rulesets and no Support desk. Where an incident depends on one of those, the solution says what the GitHub-side step is, described from GitHub's documentation.

## COMMON MISTAKES

1. **Skipping to recovery.** Root cause: under time pressure the destructive shortcut looks like progress, and the loop exists to delay it until the state is known and preserved.
2. **Waiting for the root cause before the first message.** Root cause: communication is treated as the end of the loop, when the team needs to know at once which branch to leave alone.
3. **Rating severity by what happened to happen.** Root cause: the window is ignored; the level depends on what could have reached users or outsiders while the state was wrong.
4. **Letting colleagues "clean up" their clones.** Root cause: a server keeps no reflog, so the history of a server-side branch exists only in the clones, and a pruning fetch, a `git gc` or a re-clone deletes it.
5. **Reading the generator or the solution first.** Root cause: the drill trains diagnosis from an incomplete report, and a cause that has been read cannot be diagnosed again.

## PRODUCTION EXAMPLE

An ML platform team deploys an inference service from the branch `production`. On a Tuesday the deploy job refuses to run, with a message that the deployed commit is not an ancestor of the branch.

The engineer on call does three things in the first five minutes, and none of them is a repair. Stage 1: one sentence in the channel, "Nobody pushes to or resets `production` until I say so." Stage 2: she asks two colleagues not to fetch, prune or re-clone, because their clones are the witnesses, and she anchors the commits she can already name. Stage 6, early: a first status to the lead, with the level. She rates it SEV 2 although nothing was deployed, and says why: the only thing between the rewritten branch and production was one check.

The diagnosis, the recovery and the verification come after that, in that order. The lead later says that the first sentence was the most valuable act of the incident: while it stood, nobody added a second problem to the first.

## PRACTICE EXERCISE

Generate Incident 1, [`incidents/01-hard-reset`](../../incidents/01-hard-reset/SYMPTOMS.md), and work on it for thirty minutes without help before the next video.

Before you run anything in the sandbox, write the symptom in one sentence without the reporter's interpretation, and predict which of the evidence locations of today's table will matter. Keep a log of every command. Use the ten headings. Run `check.sh` when you think you are done. Do not open the generator, the solution file or Chapter 30, section 30.5.

The challenge: generate Incident 8, [`incidents/08-branch-disappeared`](../../incidents/08-branch-disappeared/SYMPTOMS.md), as well, and attempt it before the next video. The next video begins with a pause point for both.

## INTERVIEW QUESTION

**[ON SCREEN]** Q391: "An incident on the production branch deployed nothing and no customer was affected. The CTO asks why you rated it SEV 2 and wants the root cause in two sentences that tell a non-specialist where the fix belongs. What do you say?"

Answer aloud. The question has two halves and a constraint. For the rating, a strong answer states the rule it applied and the fact that satisfies it: what stood between the wrong state and production during the window. For the root cause, two sentences, in words a non-specialist can follow, that name the layer, so that the listener knows whether the fix belongs in a person's habits, in a client setting or in a rule on the platform. Practise the two sentences until they contain no Git term that needs explaining. The constraint is the point: an answer that takes five sentences has not been prepared.

## RECAP

- An incident is a problem in shared state that others depend on while you are still working out what it is.
- The loop: stabilise, preserve, diagnose, recover, verify, communicate, prevent; stages 2 and 3 only add refs or read state, and the first message goes out at stage 1.
- A server keeps no reflog, so colleagues' clones are evidence and must not be pruned, collected or re-cloned.
- Severity is rated on what could have happened in the window, is raised at once when a secret is involved, and never depends on who caused it.
- Each incident has a report, a generator and a check; the generator and the solution are read after the attempt.

## HOMEWORK

Read sections 30.1 to 30.4. Then do the two attempts: Incident 1 for thirty minutes, and Incident 8 if you take the challenge. Bring your command logs and your four lines for the CTO to the next video.
