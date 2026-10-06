# V194: Gate briefing: Production debugging

- **Part.** 9, Production debugging and incident response
- **Module.** 38 (before Gate 9)
- **Planned minutes.** 10
- **Prerequisites.** V193
- **Textbook sections.** [Chapter 29](../../textbook/ch29-production-troubleshooting.md), sections 29.2 and 29.7; [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.2 and 30.15; the rules in [`assessments/README.md`](../../assessments/README.md)
- **Demo scripts.** `labs/ch29/preserve-evidence.sh` (snippets `01-record`, `02-backup-ref`)

## HOOK

**[ON SCREEN]** "Ten minutes into an incident the CTO asks for a status, and you have no root cause yet. What do you say?"

There are two bad answers. One is silence, or "we are looking into it". The other is a guess, delivered as a cause. Gate 9 is built to find out whether you have a third answer, and whether your hands do the right thing while you give it: evidence first, a way back before any change, and no command that could destroy work where a safer one exists.

## INTRODUCTION

This is a briefing. It teaches nothing new and shows no gate item. It tells you what Gate 9 covers, how its hands-on part is scored, and how to prepare. The gate file is not opened in this video, and you do not open it before you sit the gate.

Gate 9 is the last of the nine gates. It closes Level 9 and with it the part of the course that teaches. What comes after it is assessment.

## LEARNING OBJECTIVES

After this video you can:

1. State what Gate 9 covers and its threshold of 90.
2. Explain what is scored in the hands-on part: end state, safety of the path, explanation, the summary and the control.
3. Prepare by repeating incidents from freshly generated sandboxes without the solutions.
4. Give a status when no root cause is known yet.

## CONCEPT

**What the gate covers.** Gate 9 is taken after Module 38. It covers the diagnosis method, the ten incidents, and communication and postmortems: Chapters 29 and 30. You pass at 90 points of 100, with at least 70 percent in every part.

**The four parts.** As in every gate: Concepts, 30 points, six written questions that each require a mechanism, closed book and without a terminal. Prediction, 20 points, four items, without a terminal. Hands-on diagnosis, 30 points. Oral interview, 20 points, six questions asked one at a time, each with a follow-up, without notes.

**The hands-on part.** For Gate 9 it is a repository that a script builds in a broken state, with a report that is incomplete and partly wrong. You know this form from the ten incidents. From the course root you run the generator of variant A, which prints the path of the sandbox; you open the lab shell there and read the symptoms. You do not read the generator, which is the answer to "what happened", or the check script, which lists the end state line by line. You keep a log of every command. When you think you are done, you run the check.

**How it is scored.** The points are split three ways.

**[ON SCREEN]** From the assessments README.

- **End state.** The check script inspects the sandbox with read-only commands and prints one line per condition, then `PASS` or `NOT YET`. Each failed line costs one point.
- **Safety of the path.** Your command log is read: evidence before change, a way back before each rewrite, no command that could destroy uncommitted or shared work where a safer one exists. A correct end state reached through `git reset --hard`, a forced push or a re-clone can still fail this row.
- **Explanation.** What the symptoms file asks you to write: root causes in the form of the seven-line root-cause box, and, in Gate 9, the summary for the CTO and the control.

Read the second item twice. A state-changing command before the root cause is established costs more here than anywhere else in the course. The gate does not only ask whether you can repair the repository. It asks whether a colleague could trust you with theirs.

**A status without a root cause.** From V193: a status without a root cause is still a status. Say "I do not know yet" early, with the time of the next update. Separate what you observed from what you infer. And remember when the first message goes out: as soon as you know which branch people must leave alone, long before you know the cause.

**After a miss.** Remediation and a different variant, not the answers. You receive your score sheet, restudy with the remediation map, wait at least two days, and retake the whole gate; the hands-on part is then variant B, with a different project, a different state and different faults.

## MENTAL MODEL

Think of a driving test. The examiner does not only check whether you arrive. The examiner watches the mirrors, the signals, the speed at the crossing. A candidate who arrives at the destination after running a red light has failed, and nobody finds that unfair.

The command log is the examiner's view of your mirrors. It shows whether you looked, with read-only commands, before you moved; whether you set an anchor before each rewrite; and whether you chose the lower rung of the ladder when one was available.

Where the picture breaks: in a driving test nobody asks you to explain the engine. Here a third of the hands-on points is explanation: the root cause with its layer, the summary, the control.

## DIAGRAM

**[DIAGRAM]** The incident loop of section 30.2, redrawn with the four scored elements written beside the stages where they are earned.

```text
   1 stabilise --> 2 preserve --> 3 diagnose --> 4 recover --> 5 verify --> 6 communicate --> 7 prevent
        |               🟢             🟢          🟡 / 🔴         🟢              ^
        +--------------------- first message to the team ------------------------+

   scored:
     safety of the path ....... stages 2, 3 and 4: evidence before change, an anchor before each rewrite,
                                the lowest rung that repairs
     end state ................ stages 4 and 5: what check.sh reads when you are done
     explanation .............. stage 3: the root-cause box, with its layer
     summary and control ...... stages 6 and 7: four parts for the CTO; a control with its enforcing layer
```

Say what the drawing shows: no stage is unscored, and the two stages people skip under pressure, preserve and communicate, each carry points.

## LIVE TERMINAL DEMO

**[TERMINAL]** A warm-up, not a gate item. Replay `labs/run ch29/preserve-evidence` and show its first two snippets: the two acts that should precede any repair. Both are 🟢 SAFE. Before them, in any unknown repository, come the three read-only looks you know by heart: `git status`, `git reflog`, and `git ls-remote origin` for what the server holds.

**Record.** Predict what the file will be good for an hour later.

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

The output of the opening commands is in a file, including reflog lines that later commands will push down. The two uncommitted edits are saved as patches. An hour later this file is your timeline's source and the first page of your explanation.

**Anchor.**

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

Two refs, one second each. In a command log these two snippets are what "a way back before each rewrite" looks like. If your log for a drill does not contain their equivalent before the first state-changing command, repeat the drill.

**[ON SCREEN]** The gate rules from the assessments README: finish the modules first; one sitting, parts in order; do not read `generate.sh` or `check.sh`; keep a log of every command; the examiner scores with the answer key, which you do not open. Part 4 needs a second person or the tutor; if you rehearse alone, record yourself and score the recording the next day.

## COMMON MISTAKES

1. **Preparing by rereading solutions.** Root cause: the gate measures diagnosis from an incomplete report, and reading trains recognition, not diagnosis.
2. **Repairing first and explaining afterwards.** Root cause: the log then shows state-changing commands before the root cause, which fails the safety row whatever the end state.
3. **Reaching the end state by the shortest route.** Root cause: a hard reset, a forced push or a re-clone can produce a passing check and still destroy evidence or work that a safer command would have kept.
4. **Believing the report.** Root cause: the report is incomplete and partly wrong by design, and a diagnosis built on its interpretation inherits its errors.
5. **Giving a guess as a status.** Root cause: "I do not know yet, next update at a stated time" feels weak, although it is the only status that stays true.

## PRODUCTION EXAMPLE

Two engineers are asked to repair the same broken branch in a hiring exercise. Both end with a passing state. The first one's shell history begins with `git reset --hard origin/main`, followed by a cherry-pick from memory and a forced push. The second one's begins with `git status`, the reflog, and `git ls-remote origin`; then an evidence file and a rescue branch; then three hypotheses in a comment; then one additive fix and the same commands again.

The reviewer asks both the same follow-up: "A colleague had an uncommitted change in that clone. Is it still there?" The second engineer answers from the evidence file. The first cannot know. The team hires the second, and the reviewer's note says why in one line: the end states were equal, and only one of the two could be given a production repository.

Gate 9 scores the same difference, with the same instrument: your log.

## PRACTICE EXERCISE

Regenerate Incident 2, [`incidents/02-force-push-wrong-branch`](../../incidents/02-force-push-wrong-branch/SYMPTOMS.md), Incident 5, [`incidents/05-rebased-shared-branch`](../../incidents/05-rebased-shared-branch/SYMPTOMS.md), and Incident 6, [`incidents/06-pr-500-changes`](../../incidents/06-pr-500-changes/SYMPTOMS.md), and repeat them against the clock, without notes and without the solutions.

Before each, predict how long the read-only phase will take you and write the time down. Keep a command log. Afterwards, mark in the log the first state-changing command and check three things: was the root cause written down before it, was there an anchor before it, and was a lower rung available. Then write the four-part summary and one control with its enforcing layer.

When the three are done: take Gate 9, [`assessments/gate-9-production-debugging.md`](../../assessments/gate-9-production-debugging.md), in one sitting, with the parts in order.

## INTERVIEW QUESTION

**[ON SCREEN]** Q469: "Ten minutes into an incident the CTO asks for a status, and you have no root cause yet. What do you say?"

Answer aloud, and time it: the answer should take well under a minute. A strong answer has the shape of a status and the honesty of its content. It says what is affected and what is being done to stop it from spreading. It separates what has been observed from what is suspected. It says plainly that the cause is not known yet, and it commits to the time of the next update. It does not fill the gap with a guess, and it does not go silent. If you can also say what the CTO should not do or decide yet, you have given them something to act on.

## RECAP

- Gate 9 covers the diagnosis method, the ten incidents, communication and postmortems, and is passed at 90 with at least 70 percent in every part.
- Its hands-on part is a generated repository with a report that is incomplete and partly wrong; the generator and the check script are not read.
- The hands-on points are split between end state, safety of the path, and explanation, which here includes the summary for the CTO and the control.
- A state-changing command before the root cause is established costs more here than anywhere else in the course.
- A status without a root cause is still a status: what is known, what is being done, "I do not know yet", and the time of the next update.

## HOMEWORK

Before the gate, answer the "Interview questions" sections of Chapters 29 and 30 aloud, one at a time, without notes, each with a follow-up you invent yourself. Record the session if you rehearse alone, and score it the next day. After the gate, Part 10 begins: the interview series, the final knowledge test and the capstone.
