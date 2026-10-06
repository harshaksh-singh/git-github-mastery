# Interview-mode protocol

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. This file defines how an oral session is run and graded. Questions come from the [CTO question bank](cto-question-bank.md); model answers are in the [answers file](cto-question-bank-answers.md), which the candidate does not open during a session.

## 1. What a session is

An oral session is a strict CTO asking one question at a time and waiting for the answer. It tests whether you can explain a mechanism aloud, under mild pressure, without a terminal. It runs at the end of every module, as the oral part of every mastery gate, and as a series of full interviews in Module 39 ([roadmap](../curriculum/Git%20and%20GitHub%20mastery%20roadmap.md), sections 3.4 and 7).

Two people take part: the interviewer (the instructor, a colleague, or you with a recorder, section 7) and the candidate. The interviewer holds the answers file. The candidate holds nothing.

## 2. Session formats

| Format | Questions | Time | Drawn from |
|---|---|---|---|
| Module interview | 6 to 8 | 20 minutes | The areas the module covers |
| Area interview | 10 | 30 minutes | One area of the bank |
| Full CTO interview | 20 | 60 minutes | At least ten areas, always including Recovery, Security and Production incidents |
| Debugging round | 2 or 3 symptoms | 30 minutes | Section 6 |

Level mix for ten questions: two foundational, three working engineer, three senior, two principal. For other lengths keep the same proportions. Start with a foundational question from the area and climb. A candidate who fails two foundational questions in one area stops that area: the result is "restudy the chapter", and senior questions on top of a broken foundation measure nothing.

## 3. Rules during the session

1. **One question at a time.** The interviewer reads the question as written, once, and waits. No second question is asked until the first is graded.
2. **No terminal, no notes, no textbook.** A sheet of paper for drawing a commit graph is allowed and encouraged.
3. **Two minutes for the answer, one minute for the follow-up.** The interviewer stops an answer at three minutes. A long answer is a weak answer: the model answers are at most 180 words.
4. **The candidate may ask one clarifying question** about the situation ("has the branch been pushed?"). The interviewer answers it factually. Asking is not penalised; a good clarifying question earns credit under reasoning.
5. **"I do not know" is an acceptable answer** and is graded as such. A confident wrong mechanism is graded lower than an honest gap, because it is more dangerous in an incident.
6. **No praise, no hints, no leading.** The interviewer acknowledges an answer with "Noted" and grades it. The interviewer does not nod the candidate toward a term.
7. **No trivia.** If the candidate has the mechanism right and cannot recall an exact flag spelling or version number, the interviewer does not deduct on correctness. A deduction on terminology is allowed only when the missing term is one of the listed key terms.
8. **Layer discipline.** An answer that attributes GitHub behavior to Git, or the reverse, loses the correctness point for that claim, even when the described effect is right.

## 4. After each answer

The interviewer does these four things, in this order, and nothing else.

1. **Grade** the answer on the six dimensions of section 5 and write the numbers down.
2. **If the answer was weak** (below 8 of 12, or 0 on correctness): state the precise gap in one or two sentences, then read the model answer aloud. Do not soften the gap.
3. **Ask the follow-up.** It is asked after every answer, strong or weak. After a weak answer it is asked once the gap has been explained, so that the candidate applies the correction at once.
4. **Grade the follow-up** on the four-point scale of section 5, and record the question number for the tracker (section 8).

## 5. Grading

Each first answer is graded on six dimensions, 0 to 2 points each, 12 in total.

| Dimension | 0 | 1 | 2 |
|---|---|---|---|
| Correctness | A stated mechanism is wrong, or the wrong layer is named | Right in outline; one inexact or unsupported claim | Every claim is right and agrees with the textbook |
| Depth | Describes what a command does | Explains the mechanism | Explains the mechanism in terms of objects, refs, the index or the platform rule, and says why the tool is designed that way |
| Terminology | Vague words ("the code", "the history got messed up") | Mostly exact; one or two loose terms | Exact terms throughout, including at least half of the listed key terms |
| Reasoning | An assertion | A causal chain from state to symptom | The chain, plus the evidence that would confirm it or the hypothesis it rules out |
| Practical understanding | No command or procedure | Names the right commands | Names them in a safe order: read-only first, preview, then change, then verify |
| Production awareness | Treats it as one person's problem | Mentions the effect on teammates, CI or the server | States the risk, the lowest-risk fix, and a control that prevents recurrence |

**The correctness gate.** If correctness is 0, the whole answer scores 0. Fluent terminology on top of a wrong mechanism earns nothing.

The follow-up is graded 0 to 3: 0 for wrong or no answer; 1 for a partial answer; 2 for a correct answer; 3 for a correct answer that covers what the "strong reply" line in the answers file names. Each question is therefore worth 15 points.

**Session result.**

| Result | Condition |
|---|---|
| Pass | At least 85% of the available points (90% when the session covers Recovery, Security or Production incidents), and no answer with correctness 0 on a question about a 🔴 operation: one that can destroy uncommitted work, rewrite published history, or expose a credential |
| Remediate | Anything else. The interviewer lists the questions below 9 of 15 with their textbook references. Those sections are restudied and a different set of questions from the same areas is asked in the next session |

When a session is the oral part of a mastery gate, the gate's own point table and pass rule replace this section; the conduct rules of sections 3 and 4 still apply.

## 6. The debugging round

A debugging round tests the method of [Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.2, not recall.

1. The interviewer states a symptom in one sentence, as a colleague would report it. Sources: the symptom catalog of Chapter 29, section 29.11, the ten incidents of [Chapter 30](../textbook/ch30-incident-response.md), and the generated repositories under [`incidents/`](../incidents/README.md).
2. The candidate says what they would inspect first, and why.
3. The interviewer answers **only with the output that command would produce**. No interpretation, no hint about the next command.
4. This repeats until the candidate states the root cause in the seven-line form of [Chapter 1](../textbook/ch01-fundamentals.md), section 1.10, proposes a fix, and says how to verify it.

Grade each of these 0 to 2, for 12 points per symptom: stayed read-only until the cause was named; formed at least three hypotheses before testing one; named the layer of the cause (Git, GitHub or GitHub Actions); preserved state before changing anything; chose the lowest rung of the risk ladder of Chapter 29, section 29.9 that repairs the cause; verified with the commands that had shown the problem. A state-changing command proposed before the cause is known ends the symptom with 0 for the first item, and the interviewer says which work that command could have destroyed.

## 7. Running a session alone

1. Draw the question numbers before you start, by level mix, without reading the questions.
2. Read one question, start a recorder, answer aloud within two minutes, stop the recorder.
3. Answer the follow-up the same way.
4. Only then open the answers file. Listen to the recording and grade what you said, not what you meant. Tick each key term you used.
5. Write the gap in one sentence before moving on.

Do not reuse a question whose model answer you read less than a week ago for grading purposes: you would be grading memory of the text.

## 8. After the session

- Every question below 9 of 15 goes into the weak-area tracker (roadmap, section 12) with its number, area and textbook reference.
- A tracked question returns in the next session and once more at least a week later. It leaves the tracker after two consecutive scores of 12 or more.
- Three tracked questions in one area mean the area is restudied from the textbook before any further interview on it.
- The [senior-engineer interview guide](senior-engineer-interview-guide.md) has the self-assessment rubric in full, worked answers at three quality levels, and a four-week plan built on this protocol.
