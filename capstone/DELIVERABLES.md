# Capstone deliverables

What you hand in, per stage and at the end. The check scripts verify the Git state you reached. Everything on this page is what they cannot verify: whether you knew why.

Keep one directory outside the sandbox, for example `~/capstone-notes/`, with one file per stage (`stage-01.md` to `stage-08.md`) and one `postmortem.md`. Write each stage file before you apply the next stage. A write-up produced a week later from memory is a different and weaker document.

## 1. The seven items of every stage

Each stage file has these seven headings, in this order. Together they are the ten-part incident format of [Chapter 30](../textbook/ch30-incident-response.md), section 30.4, grouped the way you would hand it to a reviewer; section 4 below maps one onto the other.

### 1. Evidence log

A chronological list of what you ran and what it told you, written while you work.

- One line per step: the clone it ran in, the command, the one fact you took from its output.
- The symptom first, in one sentence, with no interpretation: what was observed, by whom, since when.
- **At least three hypotheses**, written before any of them is tested, each as a mechanism plus a prediction, with the one command that would separate it from the others ([Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.2). Then the result of each command.
- Every claim in the briefing that you tested, marked confirmed or refuted, with the command.
- The moment you first changed state, marked clearly. Everything above that line must be read-only or add refs only.

Paste real output, trimmed to the lines that matter. Do not retype it.

### 2. Root cause

The seven-line root-cause box of [Chapter 1](../textbook/ch01-fundamentals.md), section 1.10:

```text
Observed behavior : ...
Git state         : ...
Mechanism         : ...
Root cause        : ...
Why Git does this : ...
Correct fix       : ...
Prevention        : ...
```

Two additions. Name the **layer** of the cause: Git, a Git configuration value, GitHub, GitHub Actions, a team convention. And separate the root cause from the **contributing conditions**: what made the action look right, and which control was missing.

No person's name appears in this item.

### 3. Recovery

- What you preserved before changing anything, by name (`rescue/...` branches, tags, copies).
- The options you considered, at least two, with the reason for rejecting each one you rejected. A table of three rows is enough.
- The commands you ran, in order, each with its risk label (🟢 🟡 🔴) and, for every 🔴 command, how you previewed it and how it could have been undone.
- Every step that is not Git and not yours to perform (revoking a credential, a request to GitHub Support, a ruleset change), with who performs it.
- Where you used your administrator access to `server.git`: the equivalent on GitHub, and its limits.

### 4. Verification

- The commands that showed the problem, run again, with their output now.
- The project's tests, run on the commit that will be used: the tag, the merge result, the branch tip. Not on your working tree by coincidence.
- The result of the stage's `check.sh`.
- A list headed **Not verified**, which is never empty in a local simulation. For each entry: why it cannot be verified here, and who verifies it in real life.

### 5. Prevention

One control per contributing condition, chosen from the top of the strength ladder of [Chapter 30](../textbook/ch30-incident-response.md), section 30.20, downward: a rule the server enforces, an automated check, a safe client default, a review step, a habit. For each control: its type (prevent, detect, recover), its owner by role, what legitimate work it will block and the path for that case, and how you would know it works.

"Be more careful" is not a control. If you write a GitHub setting, name it as the textbook does and cite the section.

### 6. Message to the team

What you would post in the team channel. Under 150 words. It must contain:

- which branch, tag or clone is affected, and what people must **not** do until further notice, if anything;
- the exact commands each affected person runs in their clone, with the order;
- what was lost, if anything, stated plainly;
- no blame and no lecture.

For stages where a message must go out *before* the recovery (stabilise first), hand in both messages with their times.

### 7. Message to the CTO

The four-part summary of [Chapter 30](../textbook/ch30-incident-response.md), section 30.15, on one screen:

```text
Subject: [Resolved | Ongoing] <system>: <what happened> (SEV n, <customer impact>)

What happened   ...
Root cause      ...
What was done   ...   Verified: ...   Not yet verified: ...
Prevention      ...   Owner: ...   Date: ...
```

Impact first, in business terms. Times with a time zone. No commands. No names. A severity from the scale of section 30.3, with one sentence saying why that level. If the CTO asked a direct question in the briefing, answer it in the first two lines.

## 2. Stage-specific additions

| Stage | In addition to the seven items |
|---|---|
| 1 | The reproduction you used to judge a commit good or bad, and the proof that it gives the right answer on both known ends before you relied on it. Your decision on the other open pull request, in two sentences |
| 2 | What the pull request would have added to `main` before your repair, as a command and its output. The conflict as Git presented it to you, and your resolution, hunk by hunk |
| 3 | The order of all actions with the non-Git ones included. The full list of refs, in every repository, that reached the file. An answer to the squash-merge question |
| 4 | The paper answers to the first questions of the investigation order (workflow, event, commit checked out) written before the local reproduction. One sentence on what the local reproduction does not prove |
| 5 | A two-column list: recovered, with the mechanism that kept it; not recoverable, with the reason Git has no copy |
| 6 | The copies of the branch that existed, per repository, each with its commit, and which one you used and why. The GitHub instrument that corresponds to your recovery |
| 7 | One line for each of the eleven steps of section 30.16. The proof, made before publishing, that the repair changed no content |
| 8 | The answer to "what exactly does 1.3.2 contain" as a diff summary. The answer to "is it a regression". The command by which someone verifies next month that the fix is on `main` |

## 3. The final postmortem

After stage 8, write **one** blameless postmortem, in the template of [Chapter 30](../textbook/ch30-incident-response.md), section 30.19, for the incident of your choice among stages 1, 3 and 7. Two to three pages.

```markdown
# Postmortem: <one-line title>            Severity: SEV n        Status: draft | reviewed | actions closed
## Summary
## Impact
## Timeline
## Detection
## Root cause
## Contributing conditions
## Recovery
## What went well
## What went badly
## Actions
## Evidence
```

Requirements beyond the template:

- The timeline gives every time a source: a reflog entry, a tag, a commit date, a line of the briefing. Times that you infer are marked as inferred.
- Apply the test of section 30.19: replace every name by a role. The document must still explain the incident.
- "What went badly" includes at least one thing that you did, or nearly did, during the recovery.
- Every action has a control, a type, an owner by role, a date and "how we will know it works".

Then add a closing section of at most one page, **Across the eight stages**: which two or three controls would have prevented or shortened the most incidents of the fortnight, in priority order, with the cost of each. This is the page a CTO reads to decide what to change.

## 4. How the seven items map to the ten-part format

| Ten-part format (section 30.4) | Where it goes |
|---|---|
| Symptoms | 1 Evidence log, first line |
| Evidence | 1 Evidence log |
| Hypotheses | 1 Evidence log |
| Diagnostic commands | 1 Evidence log |
| Root cause | 2 Root cause |
| Safe recovery | 3 Recovery |
| Verification | 4 Verification |
| Prevention | 5 Prevention |
| Communication | 6 Message to the team, 7 Message to the CTO |
| Postmortem | The final postmortem, for one stage |

## 5. Before you hand in

- [ ] Eight stage files, each with the seven headings and the stage-specific addition.
- [ ] Every stage's `check.sh` output, pasted, ending in `PASS`.
- [ ] Every evidence log shows at least three hypotheses that were written before they were tested.
- [ ] Every stage has a non-empty "Not verified" list.
- [ ] No root cause and no CTO message contains a person's name.
- [ ] Every forced push in your logs names the value it expected, and every 🔴 command has its preview and its undo.
- [ ] One postmortem with the closing section.
- [ ] A note of every time you rebuilt the sandbox with `capstone/setup.sh --stage N`, and why.
