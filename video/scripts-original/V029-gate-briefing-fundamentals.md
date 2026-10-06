# V029: Gate briefing: Fundamentals

- **Part.** 1: Foundations
- **Module.** 5 (briefing for Gate 1)
- **Planned minutes.** 10
- **Prerequisites.** V006, V028
- **Textbook sections.** [`assessments/README.md`](../../assessments/README.md) ("The four parts", "How a gate is taken", "How the hands-on part is scored", "After a miss"); [Chapter 1: Fundamentals](../../textbook/ch01-fundamentals.md), sections 1.10 and 1.11
- **Demo scripts.** `labs/ch01/diagnosis.sh` (snippets `01-status`, `02-branch`, `04-log`, `05-reflog`)

## HOOK

**[ON SCREEN]** "A correct end state reached through `git reset --hard`, a forced push or a re-clone can still fail."

Here is a sentence from the rules of the examination you are about to take: a correct end state, reached through `git reset --hard`, a forced push or a re-clone, can still fail.

Read that again. You can repair the repository, pass the check script, and lose points for how you got there.

**[PAUSE]**

That is the difference between knowing commands and what this course is for. A CTO does not only ask "is it fixed?". They ask "how do you know, and what did you risk on the way?". Gate 1 asks the same. This briefing tells you what it covers, how it is taken, and how it is scored. It shows you no item of the gate.

## INTRODUCTION

You have finished Part 1: the data model, the three trees, commits, refs, HEAD and configuration. Between you and Part 2 stands Gate 1, Fundamentals.

A gate is an examination at the point where a block of the course is complete. It decides whether you go on. In the next ten minutes: the four parts and their weights, the pass rule, how the gate is taken, how to prepare for each part, and what happens after a miss.

One rule before anything else, in the words of the assessment guide: do not open the gate file to "see what is in it". A gate that has been read is a gate that has been taken. I will not open it on screen either.

## LEARNING OBJECTIVES

After this video you can:

1. State what Gate 1 covers, its four parts, their weights and the pass rule.
2. Prepare for each part with the right material.
3. Run a hands-on gate without reading the generator or the check script first.
4. Use the remediation map after a miss.

## CONCEPT

**What Gate 1 covers.** The data model, the three trees, commits, refs, HEAD, and configuration. It is taken after Module 5. It passes at 85.

**The four parts.** Every gate has 100 points in four parts with fixed weights.

**[ON SCREEN]** The table "The four parts" from the assessment guide.

Part 1, Concepts: 30 points. Six written questions, 5 points each. Each requires a mechanism: which objects, refs, files or rules are involved, and what reads or writes them. Closed book, no terminal.

Part 2, Prediction: 20 points. Four items, 5 points each. You get the commands that built a state, and you predict the output of further commands and the new state. No terminal. Object IDs are not asked for.

Part 3, Hands-on diagnosis: 30 points. A repository that a script builds in a broken state, with a report that is incomplete and partly wrong. You work in the lab shell.

Part 4, Oral interview: 20 points. Six questions asked one at a time, each with a follow-up. Spoken, no terminal, no notes.

**The pass rule.** The threshold of the gate overall, 85 for this one, and at least 70% in every part: 21 of 30 in Concepts, 14 of 20 in Prediction, 21 of 30 in Hands-on, 14 of 20 in Oral. A total above the threshold with one part below 70% is a miss.

**How the gate is taken.** One sitting, parts in order. The gate file gives the time for each part. Parts 1 and 2 are written on paper or in a plain text file, without Git and without the textbook.

For Part 3, from the course root, you run the generator of variant A. It prints the path of the sandbox. You open the lab shell there, and read `SYMPTOMS.md`. You do not read `generate.sh`, which is the answer to "what happened". You do not read `check.sh`, which lists the end state line by line. You keep a log of every command. When you think you are done, you run `check.sh`, which prints `PASS`, or `NOT YET` with one line per condition.

The generator runs with the fixed lab clock, so the commit IDs in your sandbox equal the IDs in the answer key. Commits that you make in the lab shell use the real clock and get other IDs. You know why, from V001.

Part 4 needs a second person or the tutor, who asks each question, waits for the answer, asks the follow-up, and scores with the answer key. If you rehearse alone, record yourself and score the recording the next day.

The examiner scores with the answer key. You do not open the key yourself before the gate is scored.

**How the hands-on part is scored.** Three ways. The end state: `check.sh` inspects the sandbox with read-only commands, and each failed line costs one point. The safety of the path: your command log is read for evidence before change, a way back before each rewrite, and no command that could destroy uncommitted or shared work where a safer one exists. And the explanation: what `SYMPTOMS.md` asks you to write, with root causes in the form of the root-cause box of Chapter 1, section 1.10.

**After a miss.** A miss leads to remediation and a different variant. It does not lead to the answers. The examiner gives you your score sheet, and nothing from the answer key. You use the remediation map at the end of the gate file: for every item on which you lost more than a third of the points, you restudy the listed sections and redo the labs of the listed module. You retake the whole gate after at least two days. Parts 1, 2 and 4 are asked again, and the examiner varies the follow-ups. Part 3 is taken with variant B, which has a different project, a different state and different faults. A second miss on the same gate means the block has to be studied again from its first module, with the exercises at Levels 3 to 5, before a third attempt.

## MENTAL MODEL

Think of the gate as a driving test, not a written quiz. The written part checks that you know the rules. The prediction part checks that you can see what will happen before it happens. The hands-on part puts you in traffic, with a passenger who gives you directions that are incomplete and partly wrong. And the oral part asks you to explain what you did and why.

In a driving test, arriving at the destination is not enough. If you ran a red light on the way, you fail. That is the "safety of the path" row.

Where the comparison breaks: here you are allowed, and expected, to stop and look for as long as the read-only commands take. Nobody is behind you. Use that.

## DIAGRAM

**[DIAGRAM]** A bar of 100 points, split 30, 20, 30, 20, with the 70% line marked in each part and the 85 line on the total.

```text
   Part 1 Concepts        Part 2 Prediction   Part 3 Hands-on        Part 4 Oral
   30 points              20 points           30 points              20 points
 +----------------------+--------------+----------------------+--------------+
 |               :      |         :    |               :      |         :    |
 +----------------------+--------------+----------------------+--------------+
                 ^                ^                    ^                ^
            21 of 30         14 of 20             21 of 30         14 of 20      (70% in each part)

 total: 0 ---------------------------------------------------------- 85 ----- 100
                                                                      ^
                                                          pass at 85, and every part at 70%
```

Four segments. In each one, a dotted line at 70%. Under the bar, the total, with the line at 85. Both conditions must hold. Work an example: 30, 20, 20 and 20 make 90, which is above 85; and it is a miss, because 20 of 30 in the hands-on part is below 21.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch01/diagnosis.sh`. On screen: "Warm-up. This is not a gate item."

The hands-on part starts the way every investigation in this course starts: with the ritual from V005. As a warm-up, here are four of its commands on the repository you already know. For each, say the question it answers before the output appears.

```bash
labs/run ch01/diagnosis
```

Where am I, and what is uncommitted?

<!-- snippet: ch01/diagnosis/01-status -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   eval/runner.py

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	run.log

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

Which branches exist, and what do they follow?

<!-- snippet: ch01/diagnosis/02-branch -->
```text
$ git branch -vv
  feature/cache 1c96817 Cache embeddings between runs
* main          f29df3b [origin/main] Raise eval timeout to 120s
```
<!-- /snippet -->

What does the history look like, and where does every name point?

<!-- snippet: ch01/diagnosis/04-log -->
```text
$ git log --graph --decorate --oneline --all
* f29df3b (HEAD -> main, origin/main) Raise eval timeout to 120s
| * 1c96817 (feature/cache) Cache embeddings between runs
|/  
* 25fbbb0 Add evaluation runner and config
```
<!-- /snippet -->

What was done in this repository, and in which order?

<!-- snippet: ch01/diagnosis/05-reflog -->
```text
$ git reflog
f29df3b HEAD@{0}: commit: Raise eval timeout to 120s
25fbbb0 HEAD@{1}: checkout: moving from feature/cache to main
1c96817 HEAD@{2}: commit: Cache embeddings between runs
25fbbb0 HEAD@{3}: checkout: moving from main to feature/cache
25fbbb0 HEAD@{4}: commit (initial): Add evaluation runner and config
```
<!-- /snippet -->

After Part 1 of this course, you can read each of these outputs as statements about refs, HEAD, the index and the working tree. `f29df3b` with `HEAD -> main, origin/main`: three names on one commit. The reflog: a local journal, newest first. In the gate, these four commands, and the rest of the ritual, go into your command log before any command that changes state. All four are 🟢 SAFE.

**[ON SCREEN]** The steps of "How a gate is taken" from [`assessments/README.md`](../../assessments/README.md), one at a time, and the three commands of Part 3:

```bash
assessments/gen/gate-1-fundamentals/variant-a/generate.sh      # prints the sandbox path
labs/shell "<the path it printed>"
assessments/gen/gate-1-fundamentals/variant-a/check.sh         # PASS, or NOT YET with one line per condition
```

I show these three lines so that you know the procedure. I do not run them here, and I do not open the gate file, the generator or the check script.

## COMMON MISTAKES

1. **Opening the gate file "to see what is in it".** Root cause: treating the gate as study material; a gate that has been read is a gate that has been taken.
2. **Reading `generate.sh` or `check.sh` during the hands-on part.** Root cause: looking for the answer instead of the evidence; the generator is the answer to "what happened".
3. **Believing the report in `SYMPTOMS.md`.** Root cause: forgetting that the report is incomplete and partly wrong by design; separate the symptom from the guesses in it, as in V004.
4. **Fixing first and investigating afterwards.** Root cause: skipping the read-only half of the framework; the command log is scored for evidence before change.
5. **Counting only the total.** Root cause: overlooking the second half of the pass rule; one part below 70% is a miss whatever the total.

## PRODUCTION EXAMPLE

A new engineer joins an inference team and, in her second week, is handed a repository with the sentence "main is broken, somebody force-pushed, please fix". The sentence is incomplete and partly wrong, as such sentences usually are. An engineer who trusts it re-clones and resets. An engineer who has passed this gate writes down the symptom, runs the ritual, reads the reflog, forms more than one hypothesis, and changes nothing until one is left. The gate's hands-on part is that afternoon, compressed, with a check script instead of a production system. The scoring rows, end state, safety of the path and explanation, are the three things her CTO will ask about.

## PRACTICE EXERCISE

Redo the five Level 4 exercises of Modules 1 to 5 in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md), without notes:

- Exercise 1.9, "git log says there are no commits"
- Exercise 2.9, "Git does not see my edits"
- Exercise 3.9, "a commit made on the meeting-room laptop"
- Exercise 4.9, "three commits on the wrong branch"
- Exercise 5.9, "two work repositories, two wrong addresses"

For each one, before you touch the sandbox, write the symptom without interpretation and at least two hypotheses with the read-only command that separates them. Keep a command log, as you will in the gate, and afterwards read your own log for the three scoring rows.

## INTERVIEW QUESTION

Q3: "What is HEAD? Explain what the file contains, the difference between the symbolic and the detached form, and what moves it."

Answer aloud, standing, without notes; that is the condition of Part 4. A strong answer covers all three clauses of the question in order, uses the terms of V022 and V024, and distinguishes what moves HEAD from what moves the branch that HEAD names. Expect a follow-up: prepare to say what a commit does in each of the two forms.

## RECAP

You should now be able to say: Gate 1 covers the data model, the three trees, commits, refs, HEAD and configuration. It has four parts: concepts for 30 points, prediction for 20, hands-on diagnosis for 30 and an oral interview for 20. I pass with 85 overall and at least 70% in every part. In the hands-on part I read `SYMPTOMS.md` and nothing else, keep a command log, collect evidence before I change anything, and I am scored on the end state, the safety of my path and my explanation. After a miss I get my score sheet and the remediation map, and I retake the gate with variant B after at least two days.

## HOMEWORK

- Before the gate: answer the "Interview questions" sections of Chapters 1, 2, 4, 5, 6, 7 and 14B aloud, following [`interview/interview-mode-protocol.md`](../../interview/interview-mode-protocol.md).
- Then take Gate 1, in one sitting, parts in order. The gate file is in the `assessments` folder; open it only when you sit down to take it.
