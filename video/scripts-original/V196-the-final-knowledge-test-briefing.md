# V196: The final knowledge test: briefing

- **Part.** 10, Senior engineer: assessment
- **Module.** 40
- **Planned minutes.** 12
- **Prerequisites.** V195
- **Textbook sections.** The whole book is the test's subject; this briefing cites only the rules: the opening and the section "How the test is taken" of [`assessments/final-test.md`](../../assessments/final-test.md)
- **Demo scripts.** `labs/incidents/lab-36-1-hard-reset.sh` (snippet `01-failure` only)

## HOOK

**[ON SCREEN]** "A senior engineer with ten years of Git says that a fixed diagnosis ritual is for juniors."

The final test of this course has a rule that answers that engineer. In every debugging and incident item, a state-changing command given before the root cause is established loses half of the item's points, whatever follows. A brilliant fix, reached by the right instinct, after the wrong first move, is worth half.

The test measures the standard the course was built for: given a state or a symptom, you name the mechanism, show the evidence, choose the lowest-risk fix, verify it, and say what prevents a repeat. Recalling a command earns little.

## INTRODUCTION

This is a briefing for the final knowledge test, taken in Module 40 after the ninth mastery gate. It covers the whole book, Chapters 1 to 30. I show you the rules and nothing else: the page of the test file that says how the test is taken, up to and not including Section 1. No item of the test appears in this video.

Four things: the structure, the rules, the sittings and the pass rule. Then how to prepare between sittings, and when the answer key comes into your hands.

## LEARNING OBJECTIVES

After this video you can:

1. State the structure of the final test: eighteen sections, eight item types, six sittings.
2. State the pass rule.
3. Explain the rule that a state-changing command before the root cause costs half an item.
4. Plan the six sittings and the revision before each.
5. Use the answer key only as the retake procedure allows.

## CONCEPT

**The structure.** The test has 250 items in eighteen sections. The sections are the eighteen areas of the question bank, from Fundamentals to the CTO interview. There are eight types of item.

**[ON SCREEN]** The table from "How the test is taken".

| Item type | Count | Points each | How it is answered | Minutes each |
|---|---|---|---|---|
| Multiple choice | 86 | 1 | One letter. Closed book, no terminal | 1.5 |
| Command prediction | 24 | 3 | Write the output you expect, as literally as you can, and one sentence of mechanism. No terminal | 4 |
| Diagram | 16 | 3 | Draw the commit graph with every ref and HEAD, or answer the questions about the graph shown. No terminal | 5 |
| Output interpretation | 20 | 4 | A real transcript is shown. Explain what happened, line by line where it matters, and what you would do next. No terminal | 6 |
| Debugging | 42 | 4 | A situation is described. Give at least two hypotheses, the read-only command that separates them, the root cause with its layer, the fix and the prevention | 6 |
| Practical lab | 9 | 10 | A generated repository and a task card. Work in the lab shell; a `check.sh` verifies the end state | 30 |
| Incident response | 12 | 8 | Written response in the seven stages of the incident loop, ending with the four-part summary | 15 |
| Oral | 41 | 4 | Spoken to an examiner, or recorded. Two to three minutes per answer, no notes, no terminal | 4 |
| **Total** | **250** | **804** | | **about 21.5 hours** |

Look at where the points are. Multiple choice is 86 items and 86 points of 804. The debugging items alone are 168 points, the oral items 164, the incident responses 96, the practical labs 90. The test is weighted toward explaining, diagnosing and doing.

**The rules.** Six, from the test file.

One. Closed book, except in the practical labs, where `git help <command>` and the manual pages are allowed and the textbook is not.

Two. Where an item says "no terminal", a terminal is a failed item. The prediction items are worthless if you run them. They measure whether the model in your head produces the output; a terminal measures nothing about you.

Three. In prediction items you write `<id>` where an abbreviated commit ID would appear. Lines that start with a hash sign in a transcript are comments that describe hidden setup or what a person did.

Four. In debugging and incident items, a state-changing command given before the root cause is established loses half of the item's points, whatever follows. The read-only phase is the first thing that is marked.

Five. GitHub-side items are answered from what you know of the documented behavior. Nothing in the test requires a GitHub account or a network connection.

Six. The practical labs follow the generator protocol of the incident drills: run the generator, open the lab shell at the path it prints, work, then run the check from the course root. Running the generator again rebuilds the lab from nothing. A lab counts when its check prints `PASS` and the hand-in listed on its task card is complete: 6 points for the end state, 4 for the hand-in.

**Why rule four exists.** It is the first fact of Chapter 29 made into a marking scheme: most damage is done after the incident, by the first repair attempt. The rule does not ask you to be slow. It asks for an order. A fixed opening is what replaces confidence, and the study the textbook cites found that experienced users were strongly represented among those asking Git questions. The ritual is not for juniors. It is for anyone whose repository contains something that exists nowhere else.

**The sittings.** Six, in this order, on separate days.

**The pass rule.** Three conditions, all required. 85 percent of the total: 684 of 804 points. At least 70 percent in every section. And at least seven of the nine practical labs with a passing check.

**After a section below 70 percent.** That section is retaken alone, after the restudy that the answer key names for each item. The labs are retaken by regenerating them.

**The answer key.** The test file contains no answers. You receive the key after you have handed in the whole test. Before that it is not opened, and between sittings you do not read ahead in the test.

## MENTAL MODEL

Think of the test as the course in miniature, folded so that every part shows at once. Each section asks the same five things about a different area: the state, the mechanism, the evidence, the fix, the prevention. The eight item types are eight ways of asking them: choose it, predict it, draw it, read it, diagnose it, do it, lead it, say it.

Where this breaks: a miniature suggests that a quick look is enough. The time budget says otherwise: about twenty-one and a half hours, in six sittings. It is the longest assessment in the course, and it is built so that it cannot be passed by a good memory for commands.

A second picture, for rule four: a surgeon's checklist. Senior surgeons use it. Its value does not come from the surgeon not knowing the steps. It comes from the cases where the surgeon is certain and wrong.

## DIAGRAM

**[DIAGRAM]** A new table: the six sittings with their sections and time budgets, from the test file. The time budget is the sum of the minutes per item, rounded up.

| Sitting | Sections | Items | Points | Time budget |
|---|---|---|---|---|
| 1 | 1 Fundamentals, 2 Git internals, 3 Branching | 44 | 120 | 3 h 15 min |
| 2 | 4 Merge, 5 Rebase, 6 Undo | 44 | 137 | 4 h 15 min |
| 3 | 7 Recovery, 8 Remote workflows, 9 GitHub | 42 | 134 | 4 h |
| 4 | 10 Pull requests, 11 GitHub Actions, 12 Security | 43 | 133 | 3 h 30 min |
| 5 | 13 Open source, 14 AI/ML workflows, 15 Production incidents, 16 Debugging | 50 | 184 | 5 h 30 min |
| 6 | 17 Architecture, 18 CTO interview | 27 | 96 | 2 h |

Point at sitting 5: the heaviest, with the most points. Plan it for a day on which you have nothing else. Then add a column of your own to this table before you start: the date of each sitting, and the revision you will do the day before it.

## LIVE TERMINAL DEMO

**[ON SCREEN]** Open [`assessments/final-test.md`](../../assessments/final-test.md) and show its opening and the section "How the test is taken". Scroll to the horizontal line under the pass rule and stop. Section 1 begins below that line and is not shown.

**[TERMINAL]** One snippet, to show the form a practical lab takes. It is not from the test. Replay `labs/run incidents/lab-36-1-hard-reset` and show only the snippet `failure`, which you saw in V185 and which is Incident 1, a drill you have completed.

The form has three parts: a generated repository, a task, and a check script that verifies the end state with read-only commands. In this snippet somebody chose a recovery that looked right, and then ran the check.

🔴 DANGEROUS: `git reset --hard`. It moves the branch, replaces the index and overwrites the working tree; uncommitted work is destroyed. Preview with `git status` and `git diff`. In the lab it is the tempting move, run on purpose.

<!-- snippet: incidents/lab-36-1-hard-reset/01-failure -->
```text
$ cd ravi
# The tempting move: put the branch back where it was before the accident.
$ git reset --hard 'feature/escalation-rules@{2}'
HEAD is now at 0322a16 Never escalate spam
$ git log --oneline
0322a16 Never escalate spam
a26c697 Route escalated tickets to the on-call queue
95d110d Add escalation predicate
44fa655 Add README
43fb607 Add ticket classifier
$ cd ..
$ incidents/01-hard-reset/check.sh
Checking incident 01-hard-reset
  ok    the commit "Add escalation predicate" is on feature/escalation-rules again
  ok    the commit "Route escalated tickets to the on-call queue" is on feature/escalation-rules again
  ok    the commit "Never escalate spam" is on feature/escalation-rules again
  FAIL  the commit made after the reset is still on the branch
  FAIL  the main commit "Document how to run the tests" appears 0 times on feature/escalation-rules (expected once)
  FAIL  the branch contains the current origin/main
  ok    triage/escalate.py in the last commit has the spam rule
  FAIL  rules/priority.yaml (staged, never committed) is not back in the working tree with its content
  ok    no operation is left in progress
NOT YET: 4 check(s) failed.
[exit status: 1]
```
<!-- /snippet -->

Predict before you read the check: the three commits are back, so why is the result "NOT YET"?

**[PAUSE]** You know the answer from V186. The branch was moved back, so the commit made after the accident left it; the staged file was not restored; and the relation to `main` is wrong. Four failed lines.

That is what a practical lab in the final test looks like from the outside. The check prints one line per condition and ends with `PASS` or `NOT YET`. And the lesson of this snippet is the lesson of rule six: a lab counts when the check passes and the hand-in is complete. Six points for the end state, four for the hand-in. A passing end state without the hand-in is six of ten.

## COMMON MISTAKES

1. **Running a prediction item "to be sure".** Root cause: the item measures the model in your head, and with a terminal it measures nothing, so the rule counts it as failed.
2. **Writing the fix first in a debugging item.** Root cause: the read-only phase is the first thing that is marked, and a state-changing command before the root cause costs half the item.
3. **Aiming at the total.** Root cause: the pass rule also requires 70 percent in every section and seven of nine labs, so one neglected area fails the test.
4. **Reading ahead between sittings.** Root cause: an item that has been read cannot be answered as an unseen item, and the sittings are designed around that.
5. **Treating a passing check as a finished lab.** Root cause: four of a lab's ten points are for the hand-in on its task card.

## PRODUCTION EXAMPLE

An engineer plans the final test the way she would plan a release. Six sittings on six separate days over three weeks. The day before each sitting, a revision of the sections it covers, with the revision checklist and the cheat sheet, closed afterwards. The longest sitting on a Saturday.

After sitting 2 she knows, without any key, that her rebase predictions were slow: she had to reconstruct what `--onto` takes as arguments each time. She does not read ahead. She restudies exactly that, with the chapter and its lab, before sitting 3.

When the whole test is handed in and scored, one section is at 66 percent: remote workflows. The answer key now reaches her, with the restudy named for each item she lost. She does that restudy, retakes the one section alone, and regenerates the one lab whose check had not passed. Nothing else is repeated. Her comment afterwards is about rule four: twice she had caught herself writing a `reset` as the first line of a debugging answer, and both times the read-only commands she wrote instead showed that the reset would have been the wrong fix.

## PRACTICE EXERCISE

Revise with [`revision/revision-checklist.md`](../../revision/revision-checklist.md) and [`cheatsheets/git-cheat-sheet.md`](../../cheatsheets/git-cheat-sheet.md), for the sections of sitting 1: Fundamentals, Git internals, Branching. Then put both away and take sitting 1.

Before you start, predict your score for each of its three sections and write the three numbers down; after the whole test has been scored, compare. During the sitting, obey the item's conditions literally: where it says "no terminal", close the terminal.

The challenge is the whole test: [`assessments/final-test.md`](../../assessments/final-test.md), six sittings, in order, on separate days.

## INTERVIEW QUESTION

**[ON SCREEN]** Q476: "A senior engineer with ten years of Git says that a fixed diagnosis ritual is for juniors. Respond."

Answer aloud, in two minutes. A strong answer does not argue from authority and does not insult the colleague. It gives evidence: what the textbook reports about who asks Git questions, and when in an incident the damage is usually done. It says what the ritual costs, in seconds, and what it protects, in terms of state that exists in one place only. It concedes what is true in the objection: there are cases where the full method is not needed, and you can name them. And it ends on a control, not on a moral: what you would do in a team where one person will not follow the ritual.

## RECAP

- The final test has 250 items in eighteen sections and eight item types, worth 804 points, taken in six sittings on separate days.
- You pass with 85 percent overall, at least 70 percent in every section, and at least seven of nine practical labs passing.
- "No terminal" is literal, and a prediction item that was run is worthless.
- In debugging and incident items a state-changing command before the root cause loses half the item.
- The answer key arrives after the whole test is handed in; a weak section is restudied as the key names and retaken alone.

## HOMEWORK

Between sittings, restudy only what the previous sitting showed to be weak, and do not read ahead in the test. Keep a one-line note after each sitting: the area that cost you the most time, and the chapter section you will reread before the next one.
