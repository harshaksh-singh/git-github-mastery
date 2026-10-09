# V004: The root-cause framework

- **Part.** 0: Orientation
- **Module.** 0
- **Planned minutes.** 16
- **Prerequisites.** V003
- **Textbook sections.** [Chapter 1: Fundamentals](../../textbook/ch01-fundamentals.md), section 1.10 (with the transcript of section 1.13 used as the report)
- **Demo scripts.** `labs/ch01/pitfalls.sh` (snippet `03-nothing-staged`)

## HOOK

**[ON SCREEN]** Two lines side by side: "CI fails with a timeout" and "the commit is broken".

Two engineers report the same incident. One writes: "CI fails with a timeout." The other writes: "The commit is broken." CI is the automated system that builds and tests every change.

One of those sentences is a symptom, and the other is a guess. Which is which? Say it out loud.

**[PAUSE]**

The first sentence is the symptom. It says what was observed, without interpretation. The second sentence is already a guess. It names a culprit before anybody has looked at the state of the repository.

Most damage in Git incidents is done by a command typed before the state was understood. And that command usually follows from a sentence like the second one. This video gives you a fixed procedure that keeps guesses out of your hands until the evidence is in. Hold on to that guess. Its close cousin turns up later, in a colleague's report.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair.

**[ANIMATION]** trees: setup, edit, add, commit file=README.md names=Working_tree,Index,Repository

**[ANIMATION]** step: setup

You've seen where a file can be: working tree, index, repository. A quick reminder: the working tree is the files you edit, the index is the list of what the next commit will contain, and the repository holds the recorded commits.

**[ANIMATION]** end

Now you get the method that this course uses for every problem, from a missing file to a rewritten shared branch. It has eleven steps and one fixed way to write down the result, a box of seven lines. From here on, every investigation in every video ends with that box. So learn it now, while the examples are small.

We'll run exactly one Git command in this video, and it's one you already know: `git status`. The point is the method, not the command.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. List the steps of the root-cause framework in order.
2. Separate a symptom from a hypothesis for a given report.
3. Write a seven-line root-cause box for a behavior that has been shown.
4. Explain why every step up to naming the root cause is read-only.

## CONCEPT

Every problem in this course is handled in the same eleven steps.

**[ON SCREEN]** The eleven steps appear one at a time as they are named.

**Symptom.** Write down what was observed, without interpretation. "CI fails with a timeout" is a symptom. "The commit is broken" is already a guess.

**Observe.** Look before you touch. Start with `git status`.

**Collect evidence.** Run the diagnosis ritual and keep the output. The ritual is ten commands, and it's the subject of the next video.

**Understand state.** State what the working tree, the index, HEAD, the branches and the remote contain. The remote is the name your repository has for another repository, usually the copy on the server. Say it in words. If you can't say it, you don't have it yet.

**Form hypotheses.** List every mechanism that could produce the symptom from that state. A hypothesis is a possible explanation. Note the plural. One hypothesis is a belief, not an analysis.

**Test hypotheses.** For each one, name the command whose output would differ if it were true, and run it.

**Identify root cause.** Name the mechanism that survived, and the layer it belongs to: Git, GitHub or GitHub Actions. The layer is part of every root cause. Remember "the merge is blocked" from video 2: three layers, three unrelated fixes.

**Select lowest-risk fix.** List the possible fixes with their risk labels. Choose the one that destroys least and is simplest to undo.

**Execute.** Preview, then run, one change at a time.

**Verify.** Repeat the commands that showed the problem. The evidence must have changed, and for the reason you predicted.

**Prevent.** Change a habit, a setting or a rule so that the problem cannot recur silently.

**Two rules make the framework safe.**

The first rule: everything up to and including "identify root cause" is read-only. Seven steps, and not one of them changes the repository. The reason is the sentence from the hook: most damage in Git incidents is done by a command typed before the state was understood. If you haven't changed anything, you can't have made it worse, and the evidence you collected is still the evidence.

The second rule: every explanation ends in the same seven-line box, so that a reader can check whether it is complete.

**[ON SCREEN]** The seven lines, one at a time.

Observed behavior: what was seen. Git state: what the working tree, index, HEAD, refs and remote held. Mechanism: what Git does with that state. Root cause: the one fact that, had it been different, would have prevented the symptom. Why Git does this: the design reason. Correct fix: the lowest-risk change that repairs the state. Prevention: what stops a silent recurrence.

**Root cause versus mechanism.** These two lines are the ones people merge, so separate them now. The mechanism is what Git does with a given state. It's general: it would be true in any repository in that state. The root cause is one fact about this case: the fact that, had it been different, would have prevented the symptom. The mechanism is a rule. The root cause is the particular thing that met the rule. If the two still blur, that's normal. You'll see the difference in the demo.

**When not to use it.** The framework describes what you can learn from a repository. The textbook is explicit about the limit of its evidence step: the ten commands describe one clone. They say nothing certain about the server until you fetch, and nothing at all about GitHub objects such as pull requests, rulesets and check results. When the root cause is in another layer, the framework still applies, but the evidence has to come from that layer.

## MENTAL MODEL

Think of the framework as a line drawn across a page. Above the line you only read. Below the line you write.

Above the line are the seven steps from symptom to root cause. Below it are four: select the fix, execute, verify, prevent. You cross the line once, deliberately, with a named root cause in your hand.

The model breaks in one honest place, and the next video takes it up: "read-only" describes what you intend, not everything that every command does on disk. `git status` can refresh cached file information in the index file and write the file back. That never changes history. It matters when you investigate a damaged repository, and there the textbook's advice is to work on a copy.

## DIAGRAM

**[DIAGRAM]** The framework as the textbook prints it.

```text
SYMPTOM -> OBSERVE -> COLLECT EVIDENCE -> UNDERSTAND STATE -> FORM HYPOTHESES -> TEST HYPOTHESES
        -> IDENTIFY ROOT CAUSE -> SELECT LOWEST-RISK FIX -> EXECUTE -> VERIFY -> PREVENT
```

Here's the whole method on one page.

**[DIAGRAM]** The same eleven steps as a vertical flow. Draw the steps top to bottom, then draw the horizontal line last.

```text
   SYMPTOM
      |
   OBSERVE
      |
   COLLECT EVIDENCE
      |
   UNDERSTAND STATE
      |
   FORM HYPOTHESES
      |
   TEST HYPOTHESES
      |
   IDENTIFY ROOT CAUSE
  ------------------------------------  read-only above this line
   SELECT LOWEST-RISK FIX
      |
   EXECUTE
      |
   VERIFY
      |
   PREVENT
```

The same eleven steps, top to bottom. One line is drawn under "identify root cause": read-only above this line.

**[DIAGRAM]** The root-cause box of section 1.10, one line at a time.

```text
Observed behavior : what was seen
Git state         : what the working tree, index, HEAD, refs and remote held
Mechanism         : what Git does with that state
Root cause        : the one fact that, had it been different, would have prevented the symptom
Why Git does this : the design reason
Correct fix       : the lowest-risk change that repairs the state
Prevention        : what stops a silent recurrence
```

And the box, one line at a time: observed behavior, Git state, mechanism, root cause, why Git does this, correct fix, prevention.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch01/pitfalls.sh`, snippet `03-nothing-staged`.

Now a real case. Treat what follows as a report from a colleague. They send you this piece of terminal and one sentence: "Git is not saving my commit."

```bash
labs/run ch01/pitfalls
```

<!-- snippet: ch01/pitfalls/03-nothing-staged -->
```text
$ echo 'Evaluation harness.' >> README.md
$ git commit -m "Describe the project"
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[exit status: 1]
```
<!-- /snippet -->

We run nothing else. We fill the seven lines from what this transcript shows. Try it now: pause, and write the first two lines yourself, observed behavior and Git state. Thirty seconds, then compare your answer with mine.

**[PAUSE]**

**[ON SCREEN]** Split: the transcript on the right, an empty seven-line box on the left, filled one line at a time.

**Observed behavior.** First strip the interpretation from the report. "Git is not saving my commit" is a guess about Git, a cousin of "the commit is broken". What was seen? `git commit -m "Describe the project"` printed a status listing instead of a commit line, and ended with exit status 1, the number a command reports when it finishes. No commit was made.

**[ANIMATION]** step: edit

**Git state.** Read it off the output. On branch `main`. `README.md` is modified, under the heading "Changes not staged for commit". The last line says "no changes added to commit". So after the edit, the working tree holds the new line, and the index doesn't.

**[ANIMATION]** end

**[ANIMATION]** step: edit

**Mechanism.** What does Git do with that state? You know this from video 3: `git commit` records the index. An index that equals the last commit gives it nothing to record, so it prints the status and refuses.

**[ANIMATION]** end

**[ANIMATION]** step: edit

**Root cause.** The one fact that, had it been different, would have prevented the symptom: the change to `README.md` was never added to the index.

Compare those two lines. The mechanism would hold in any repository. The root cause is about this file in this repository. That's the difference.

**Why Git does this.** The design reason: the index exists so that you choose what a commit contains. A commit is what was staged, not what is on disk.

**[ANIMATION]** step: commit

**Correct fix.** The lowest-risk change. Git prints it in the transcript: `use "git add <file>..." to update what will be committed`. Add the path, then commit again. Both commands are 🟢 SAFE: they only add.

**Prevention.** Read `git status` before each commit, and read `git diff --cached` as the text of what you're about to record.

**[PAUSE]**

**Notice what did the work.** We didn't search for the error message. We read the output that Git printed, and most of the box was in it: the state in the heading, and the fix in the hint. The textbook's wording for this failure is short: exit status 1 and no commit. The change is in the working tree, and the index was never updated.

**One more observation about the layer.** Which layer acted: Git, GitHub, or GitHub Actions? Say it out loud.

**[PAUSE]**

Git. Not GitHub, and not Actions. Nothing in this report left the laptop.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Writing a guess in the symptom line.** Root cause: the reporter interpreted before observing; "the commit is broken" names a culprit, while "CI fails with a timeout" names what was seen.
2. **Stopping at one hypothesis.** Root cause: one hypothesis is a belief, not an analysis; with nothing to compare it against, no test can reject it.
3. **Running a fix before the root cause is named.** Root cause: the read-only rule was skipped, and a state-changing command destroyed or altered the evidence.
4. **Writing the mechanism twice and calling one copy the root cause.** Root cause: the two lines were not separated; the mechanism is the general rule, the root cause is the one fact of this case.
5. **Leaving out the layer.** Root cause: the symptom looked the same in Git, GitHub and GitHub Actions, and the explanation never said which one acted.

## PRODUCTION EXAMPLE

Now, out of the lab. An ML platform team has a nightly job that publishes evaluation results, and one morning the published numbers are a day old. The first message in the incident channel says "the pipeline is broken". Quick quiz, two options: symptom, or guess? Say it out loud.

**[PAUSE]**

A guess. It names a culprit and reports nothing that was seen. The engineer who takes the incident rewrites it as a symptom: "The results page shows yesterday's run; last night's job reported success." Then she lists mechanisms instead of picking one, and for each she names the command or the page whose output would differ if it were true, and which layer it belongs to: Git, GitHub or GitHub Actions. She changes nothing until one mechanism is left. Her write-up is seven lines long, and the reviewer can check it line by line. That's the whole value of a fixed form: a missing line is visible.

## PRACTICE EXERCISE

Your turn. Do Exercise 1.3, Level 1, "the diagnosis ritual on a small state", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

Before you run each command of the exercise, predict what it will print for the state you built, and which place it reads: working tree, index, HEAD, refs, configuration or remote. Write the prediction down first.

## INTERVIEW QUESTION

Q467: "Every explanation in this course ends in the same seven-line form. What are the seven lines, and how does "root cause" differ from "mechanism"?"

**[PAUSE]**

Answer out loud, from memory. A strong answer gives the seven lines in order without hesitation, and then distinguishes the two lines with an example of its own, not with a definition recited twice. If you can take one small failure and show a mechanism line that would be true in any repository beside a root-cause line that is true only of this one, you have it.

## RECAP

Let's land this. You should now be able to say: a symptom is what was observed, without interpretation. The framework has eleven steps, from symptom to prevention, and everything up to and including the root cause is read-only. I form more than one hypothesis and name the command that would separate them. I write the result in seven lines: observed behavior, Git state, mechanism, root cause, why Git does this, correct fix, prevention. And the root cause names its layer.

## HOMEWORK

- Read section 1.10 of [Chapter 1](../../textbook/ch01-fundamentals.md).
- Learn the seven lines by heart; every later video ends an investigation with them.
- Challenge: take the last Git problem you solved by searching for a command. Write its root-cause box. Mark each line you cannot fill; those lines are what the course will teach.

Today you got a method that works on a calm day and on a bad one. Learn the seven lines before the next video. Next time: the ten-command diagnosis. Until then, look at the state first and type second. See you in the next one.
