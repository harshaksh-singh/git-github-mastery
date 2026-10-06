# V169: Gate briefing: Security

- **Part.** 7, Security
- **Module.** 31 (before Gate 8)
- **Planned minutes.** 10
- **Prerequisites.** V162, V168
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), section 21A.19; [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md), sections 21B.11 and 21B.14; the rules in [`assessments/README.md`](../../assessments/README.md)
- **Demo scripts.** `labs/ch21b/find-secret.sh` (snippets `03-pickaxe`, `07-which-refs`)

## HOOK

**[ON SCREEN]** "A key was in the repository. We deleted it. Are we safe?"

That is the first of the four questions a CTO asks after a security scare, and none of the four is about a command. Gate 8 asks you questions of that kind and scores two things that a command cannot show: whether you can say what a credential or a job could reach, and whether you act in the right order. An answer that does the right things in the wrong order fails the case.

## INTRODUCTION

This is a briefing. It teaches nothing new and it shows no gate item. It tells you what Gate 8 covers, how it is taken, which two procedures you need to have ready, and how to prepare. The gate file and the case files are not opened in this video, and you do not open them before you sit the gate: a gate that has been read is a gate that has been taken.

## LEARNING OBJECTIVES

After this video you can:

1. State what Gate 8 covers and its threshold of 90.
2. Explain the paper format and the rule never to copy or run its workflow files.
3. Prepare the two procedures: the workflow review checklist and the six-step leak response.
4. Answer with blast radius: what could this credential or this job reach.

## CONCEPT

**What the gate covers.** Gate 8 is taken after Module 31. It covers Actions security, repository security and secret-leak response: Chapters 21A and 21B. You pass at 90 points of 100.

**How it is built.** Like every gate it has four parts with fixed weights.

| Part | Points | Form | Conditions |
|---|---|---|---|
| 1 Concepts | 30 | Six written questions, each requiring a mechanism | Closed book, no terminal |
| 2 Prediction | 20 | Four items: you get the commands that built a state and predict output and new state | No terminal. Object IDs are not asked for |
| 3 Hands-on diagnosis | 30 | For Gate 8: three cases on paper, built from configuration files, workflow files, described situations and real Git evidence | Paper |
| 4 Oral interview | 20 | Six questions, one at a time, each with a follow-up | Spoken, no terminal, no notes |

The pass rule has two conditions: the threshold overall, and at least 70 percent in every part. That is 21 of 30 in Concepts, 14 of 20 in Prediction, 21 of 30 in the cases, 14 of 20 in the oral part. A total above the threshold with one part below 70 percent is a miss.

**Why Part 3 is on paper.** The gates for GitHub, Actions and Security run nothing on GitHub. No GitHub output appears anywhere in them, and the only `gh` invocation you need is `gh <command> --help`. The workflow files in the case directories are teaching material with faults on purpose. Never copy them into a repository, and never run them. Reading a faulty workflow is the skill being examined; executing one is the mistake the chapter taught you to avoid.

**Order is scored.** In a leak-response case, an answer that rewrites history before revoking loses the points for the case, whatever else it gets right. You know the reason from section 21B.14: the damage happens at the issuer, where the key is accepted, and revocation is the only step that is complete.

**After a miss.** A miss leads to remediation and a different variant, not to the answers. You receive your score sheet, restudy the sections of the remediation map, wait at least two days, and retake the whole gate with variant B in Part 3.

## MENTAL MODEL

Think of the gate as a review board for two documents that you carry in your head.

The first document is a checklist that you lay over any workflow. The second is a sequence that you run on any leak. Neither is recited at the gate. Each is applied to a case you have not seen, and each answer is expected to end in the same kind of sentence: this job, or this credential, could reach the following, and for the following reason.

Where this model breaks: a checklist can be applied line by line, and a leak response cannot. Its steps are ordered because each one changes what the next one finds. That is why the order carries points.

## DIAGRAM

**[DIAGRAM]** One slide, two lists side by side. Left, the headings of the review checklist of section 21A.19. Right, the six response steps of section 21B.14.

```text
  Workflow review checklist (21A.19)        Leak response, in this order (21B.14)
  ----------------------------------        -------------------------------------
   1. Trigger                                1. Contain      (revoke or rotate first)
   2. Checkout                               2. Assess
   3. Permissions                            3. Eradicate    (rewrite only where warranted)
   4. Expressions                            4. Recover
   5. Actions                                5. Communicate
   6. Remote code                            6. Prevent
   7. Secrets
   8. Privileged jobs
   9. Runner
  10. Credentials in Git
  11. Process
```

Build the left list first and say what each heading asks about, in half a sentence: which event starts the job; which code is checked out; what the job token may do; whether an expression lands inside a script; whether each action is pinned; whether code is downloaded and run; where each secret is referenced; under which conditions a publishing job runs; which machine runs it; whether credentials stay in the checkout; and who reviewed the change. Then the right list, and underline the first step.

## LIVE TERMINAL DEMO

**[TERMINAL]** A warm-up, not a gate item. Replay `labs/run ch21b/find-secret`. Assessment, the second response step, needs two facts that only Git can give: the first commit that contains the secret, and which refs contain it. Both commands are 🟢 SAFE: they read history and change nothing.

**Step 1: the pickaxe.** The repository deleted its `.env` file in a later commit. Predict: how many commits will a search for the string list, and why more than one?

```bash
git log --oneline -S'DUMMY-KEY-not-a-real-secret' -- .env
git log --oneline --all -S'DUMMY-KEY-not-a-real-secret'
```

<!-- snippet: ch21b/find-secret/03-pickaxe -->
```text
$ git log --oneline -S'DUMMY-KEY-not-a-real-secret' -- .env
d42d1a1 Stop tracking .env and ignore it
0805fd8 Add staging settings
$ git log --oneline --all -S'DUMMY-KEY-not-a-real-secret'
d42d1a1 Stop tracking .env and ignore it
0805fd8 Add staging settings
```
<!-- /snippet -->

Two commits: `0805fd8`, which added the string, and `d42d1a1`, which removed it. The pickaxe lists commits that change the number of occurrences, so the deletion is listed too. The deletion did not remove anything from history; it is one more commit on top.

**Step 2: which refs contain the first commit.**

```bash
first=$(git log --all --format=%H --diff-filter=A -- .env)
git log --oneline -1 $first
git branch -a --contains $first
git tag --contains $first
```

<!-- snippet: ch21b/find-secret/07-which-refs -->
```text
$ first=$(git log --all --format=%H --diff-filter=A -- .env)
$ git log --oneline -1 $first
0805fd8 Add staging settings
$ git branch -a --contains $first
* main
  remotes/origin/feature/streaming
  remotes/origin/main
$ git tag --contains $first
v0.2.0
```
<!-- /snippet -->

Point at the tag in the last line. A branch listing alone would have missed it. In a paper case the same evidence is printed for you, and you are asked what it means. The warm-up is to say, for each line of such output, what it rules in and what it rules out.

**[ON SCREEN]** The rules for paper cases, from the assessments README: open the case file of variant A and the files beside it; nothing runs on GitHub; the workflow files have faults on purpose; never copy them into a repository, and never run them.

## COMMON MISTAKES

1. **Opening the gate file "to see what is in it".** Root cause: the gate measures diagnosis of an unseen case, and a case whose content has been seen can no longer measure that.
2. **Answering a leak case with the cleanup first.** Root cause: the answer treats the repository as the place of the damage, when the damage happens at the issuer.
3. **Reviewing a workflow by looking for the one familiar fault.** Root cause: the faults interact, and only a pass over every heading of the checklist shows which input reaches which permission.
4. **Naming a control without its layer.** Root cause: a habit, a client setting, a server rule and a pipeline check fail in different ways, and an answer that does not say which one it means cannot be scored for mechanism.
5. **Passing on the total and missing a part.** Root cause: the pass rule requires 70 percent in each part, so a weak oral part is not compensated by strong written parts.

## PRODUCTION EXAMPLE

A reviewer on an ML platform team receives a pull request that adds an evaluation workflow. She does not start by reading the script. She goes down the checklist: the trigger, and which outsider-controlled input reaches the job; the checkout; the permissions block; expressions inside `run:`; the pins of the actions; the secrets and where they are referenced; the runner. For each finding she writes one sentence of blast radius: what the job token could write, what the provider key could reach. The same week a colleague reports a key in a notebook. She does not open the repository first either. She asks who can revoke the key at the provider, and has it done, and only then runs the two commands of the warm-up. The gate asks for exactly this behavior, on paper.

## PRACTICE EXERCISE

Redo the three Level 5 exercises of the block in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md): Exercise 29.8, "A workflow nobody wrote"; Exercise 30.7, "The reproduction package"; and Exercise 31.7, "Lead the response". Do them closed book and timed. Before each one, predict which headings of the checklist, or which of the six steps, the exercise will turn on, and check your prediction afterwards. Then, and not before, compare with the solutions.

When the three are done: take Gate 8, [`assessments/gate-8-security.md`](../../assessments/gate-8-security.md), in one sitting, with the parts in order.

## INTERVIEW QUESTION

**[ON SCREEN]** Q334: "You may enable one organization-level control today. Which one, and why?"

Answer aloud. There is more than one defensible choice, and the question scores the reasoning. A strong answer names one control and the layer that enforces it, says what it limits in terms of blast radius, and says what it does not cover, so that the listener knows what remains open. It also argues from evidence: the pattern that the case studies of Chapters 21A and 21B repeat. An answer that lists five controls has not answered; the constraint "one" is the point.

## RECAP

- Gate 8 covers Actions security, repository security and secret-leak response, and is passed at 90 with at least 70 percent in every part.
- Its third part is three cases on paper; the workflow files in them are faulty on purpose and are never copied or run.
- You bring two procedures: the eleven headings of the workflow review checklist and the six response steps in order.
- Order is scored: contain first, and rewrite history only where warranted.
- Every answer ends with blast radius: what this credential or this job could reach.

## HOMEWORK

Before the gate, answer the "Interview questions" sections of Chapters 21A and 21B aloud, one question at a time, without notes. Record yourself if you rehearse alone, and score the recording the next day. After the gate, Part 8 begins with the fork workflow as it is practised in open source.
