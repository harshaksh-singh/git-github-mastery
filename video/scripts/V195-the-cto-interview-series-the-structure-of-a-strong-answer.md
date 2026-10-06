# V195: The CTO interview series: the structure of a strong answer

- **Part.** 10, Senior engineer: assessment
- **Module.** 39
- **Planned minutes.** 18
- **Prerequisites.** V194
- **Textbook sections.** [Chapter 29](../../textbook/ch29-production-troubleshooting.md), section 29.4 (the case used as an example); [`interview/interview-mode-protocol.md`](../../interview/interview-mode-protocol.md); [`interview/senior-engineer-interview-guide.md`](../../interview/senior-engineer-interview-guide.md), sections 2 and 3
- **Demo scripts.** `labs/ch29/case-wrong-upstream.sh` (snippets `01-symptom`, `02-evidence`, `08-test`, `09-fix`, `11-verify`, `12-prevent`)

## HOOK

**[ON SCREEN]** "`git status` says the branch is up to date with `origin/main`, and a colleague pushed ten minutes ago. Is Git wrong?"

You know the answer. You've known it since Part 2. Now say it aloud, to a person who is waiting, without a terminal, in under two minutes, and then take the follow-up question.

Most engineers who can fix this in thirty seconds at a keyboard can't explain it in two minutes at a table. They narrate commands. They say "the branch on GitHub" when they mean a ref in their own clone, a ref being a name that holds a commit ID. They end with "so, yes, it is a bit weird". An interviewer, and a CTO, hears all three. I won't answer the question on screen in this video, and that's deliberate. By the end you'll know where its model answer is, and what to do first.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is Part 10. Its four videos teach nothing new. They prepare the three final assessments of the course: the CTO interview series, the final knowledge test and the capstone. They explain the rules and the standard.

This video is about speaking. Since the first module you've answered one bank question per video aloud. Module 39 turns that into full interviews: twenty questions in sixty minutes, across at least ten areas. To pass them you need a structure that your answers fall into without effort, and you need to know how a session is run and graded, so that you can run one alone.

The answers file isn't shown in this video. It's opened only after you've answered aloud.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. State how an interview session is run and graded.
2. Structure an answer in five parts: state, mechanism, evidence, fix, prevention.
3. Answer a question aloud in two minutes without notes or a terminal and then take the follow-up.
4. Tell a weak answer from a strong one on the same question.
5. Run a session alone with a recording.

## CONCEPT

**What a session is.** An oral session is a strict CTO asking one question at a time and waiting for the answer. It tests whether you can explain a mechanism aloud, under mild pressure, without a terminal. Two people take part. The interviewer holds the answers file. The candidate holds nothing.

**The material.** The question bank has 482 questions in eighteen areas, at four levels: foundational, working engineer, senior and principal. Every question has a harder follow-up. The follow-up is what a CTO asks when the first answer was correct.

**The formats.**

**[ON SCREEN]** From the protocol.

| Format | Questions | Time | Drawn from |
|---|---|---|---|
| Module interview | 6 to 8 | 20 minutes | The areas the module covers |
| Area interview | 10 | 30 minutes | One area of the bank |
| Full CTO interview | 20 | 60 minutes | At least ten areas, always including Recovery, Security and Production incidents |
| Debugging round | 2 or 3 symptoms | 30 minutes | The symptom catalog, the ten incidents and their generated repositories |

Four formats. The longest is the full CTO interview: twenty questions in sixty minutes, from at least ten areas.

**The rules during a session.** Eight, from the protocol. One question at a time. No terminal, no notes, no textbook, though a sheet of paper for drawing a commit graph is allowed and encouraged. Two minutes for the answer, one minute for the follow-up: a long answer is a weak answer. The candidate may ask one clarifying question about the situation. "I do not know" is an acceptable answer and is graded as such. A confident wrong mechanism is graded lower than an honest gap, because it's more dangerous in an incident.

No praise, no hints, no leading: the interviewer says "Noted" and grades. No trivia: if you have the mechanism right and can't recall an exact flag spelling or version number, nothing is deducted on correctness. And layer discipline. The layers are Git, GitHub and GitHub Actions, and an answer that attributes GitHub behavior to Git, or the reverse, loses the correctness point for that claim, even when the described effect is right.

**The grading.** Each first answer is graded on six dimensions, 0 to 2 points each, 12 in total.

| Dimension | 0 | 2 |
|---|---|---|
| Correctness | A stated mechanism is wrong, or the wrong layer is named | Every claim is right and agrees with the textbook |
| Depth | Describes what a command does | Explains the mechanism in terms of objects, refs, the index or the platform rule, and says why the tool is designed that way |
| Terminology | Vague words | Exact terms throughout |
| Reasoning | An assertion | A causal chain, plus the evidence that would confirm it or the hypothesis it rules out |
| Practical understanding | No command or procedure | The right commands in a safe order: read-only first, preview, then change, then verify |
| Production awareness | Treats it as one person's problem | States the risk, the lowest-risk fix, and a control that prevents recurrence |

Quick quiz. An answer uses exact terms, fluently, on top of a wrong mechanism. Does it earn A, most of the points, or B, none? Your answer?

**[PAUSE]**

B, none. The correctness gate: if correctness is 0, the whole answer scores 0. Fluent terminology on top of a wrong mechanism earns nothing. The follow-up is graded 0 to 3, so each question is worth 15 points. A session is passed at 85 percent of the available points, 90 percent when it covers Recovery, Security or Production incidents, and with no answer scoring 0 on correctness for a question about a red-label operation.

**The structure of a strong answer.** Five parts, in this order. Not every question needs all five at the same length, but none may contradict another, and the first two are never optional.

**[ON SCREEN]** From section 3 of the guide.

| Part | The question it answers | Typical opening |
|---|---|---|
| **State** | What do the working tree, the index, HEAD, the refs and the server hold? | "A branch is a ref: a name that holds one commit ID." |
| **Mechanism** | What does Git, GitHub or GitHub Actions do with that state, and why is it designed so? | "A commit names its parent by ID, so a new parent means a new ID for every commit after it." |
| **Evidence** | Which read-only command shows it? What would the output look like if I were wrong? | "`git reflog show main` has a reset entry if the branch was moved." |
| **Fix** | What is the lowest-risk change that repairs the state, and what does it touch? | "Anchor the old tip with a branch first; nothing is rewritten." |
| **Prevention** | Which habit, setting or rule stops a silent recurrence, and on which layer? | "A ruleset that blocks force pushes; a client setting is weaker." |

This is the seven-line root-cause box, arranged for speech. Evidence is added because an interviewer can't see your terminal.

**How the five parts scale.** For a definition question, State and Mechanism are the answer, Evidence is one command, and Fix and Prevention shrink to one sentence about the mistake the definition prevents. For an incident question, State and Evidence come first and take most of the time, because you don't yet know the mechanism. For a design question, Prevention is the answer, and the other four are the justification.

**Three rules for the first sentence.** Answer the question that was asked: "why" starts with "because". Name the object or ref that the answer turns on. Name the layer if two are possible.

**One rule for the last sentence.** End on the control or the limit, not on a summary.

**Weak against strong, on the same question.** The guide names three behaviors that lose an interview faster than a wrong fact. Reaching for a command before describing the state: "I would run `git reset --hard`" as a first sentence tells the interviewer how you behave in an incident. Certainty without evidence: "it must be a force push", where the stronger sentence is "three mechanisms produce this; the branch reflog separates them". And blaming the tool: an answer that ends in "weird" has reached neither the mechanism nor the design reason.

And three behaviors mark a senior answer even when a detail is missing. First, saying which layer acted. Second, saying what you would check before you believe your own explanation. Third, saying "I do not know that; here is how I would find out", followed by a command that would in fact find out.

**Running a session alone.** Draw the question numbers before you start, by level mix, without reading the questions. Read one question, start a recorder, answer aloud within two minutes, stop the recorder. Answer the follow-up the same way. Only then open the answers file. Listen to the recording and grade what you said, not what you meant. Write the gap in one sentence before moving on. And don't reuse a question whose model answer you read less than a week ago: you would be grading memory of the text.

## MENTAL MODEL

A picture helps. Think of the five parts as the five paragraphs of a very short incident report, read aloud. Here is where things stand. Here is why. Here is how I know. Here is what I would change. Here is what stops it next time. A listener who hears those five in that order can interrupt at any point and still have something true.

Compare the other order, the one people fall into. Here is what I would type. And then this. And then it works. A listener who interrupts that answer after ten seconds has a command and no reason to trust it.

Where the model breaks: a written report can be reread, and a spoken answer can't. So the spoken answer needs what a report doesn't: a first sentence that already contains the answer, and a last sentence that the listener will remember, which is why it ends on the control or the limit.

Try it now, on paper. Thirty seconds. Write the five parts in order, from memory, and say them out loud.

**[PAUSE]**

State, mechanism, evidence, fix, prevention.

## DIAGRAM

**[DIAGRAM]** A new drawing: the five parts of an answer as one bar of two minutes, with a time budget on each part. The budgets are a production convention of this video, a starting point for practice, not a rule of the protocol. The protocol's rule is the total: two minutes.

```text
  0:00                    0:25                          1:05              1:25              1:45        2:00
   |------- STATE ---------|-------- MECHANISM ----------|--- EVIDENCE ----|------ FIX ------|-- PREVENTION --|
     what the working tree,   what Git, GitHub or Actions   the read-only     the lowest-risk    the habit,
     index, HEAD, refs and    does with that state, and     command, and      change and what    setting or rule,
     server hold              why it is designed so         what would        it touches         and its layer
                                                            prove me wrong

  definition question :  STATE and MECHANISM take most of the bar
  incident question   :  STATE and EVIDENCE come first and take most of the bar
  design question     :  PREVENTION is the answer; the other four justify it
```

Here are the five parts as one bar of two minutes, with a time budget on each. The budgets are a convention of this video, a starting point for practice, not a rule of the protocol. The protocol's rule is the total: two minutes. Then one more line under the bar: the follow-up, one minute.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch29/case-wrong-upstream`, the second worked case of V181, six of its snippets. This time I do not teach the case. I narrate it as a five-part answer to the bank question you met there: a push is rejected, the pull says "Already up to date", and the push is rejected again. This is the shape an oral answer takes when it is backed by a real case. In an interview there is no terminal; the transcript stands for the picture you carry in your head.

Into the lab, with the second worked case of video 181. This time I don't teach the case. I narrate it as a five-part answer.

**The question, as a symptom.**

<!-- snippet: ch29/case-wrong-upstream/01-symptom -->
```text
$ git push origin feature/batch-size
To ../server.git
 ! [rejected]        feature/batch-size -> feature/batch-size (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git pull
From ../server
 * [new branch]      feature/batch-size -> origin/feature/batch-size
Already up to date.
$ git push origin feature/batch-size
To ../server.git
 ! [rejected]        feature/batch-size -> feature/batch-size (non-fast-forward)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

**Part 1, State.** Say it in one or two sentences, with refs and without commands.

<!-- snippet: ch29/case-wrong-upstream/02-evidence -->
```text
$ git status
On branch feature/batch-size
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
$ git branch -vv
* feature/batch-size 2defa92 [origin/main: ahead 2] Read batch size from the command line
  main               ce76024 [origin/main] Write vectors to the daily bucket
$ git log --graph --decorate --oneline --all
* 56bb8e4 (origin/feature/batch-size) Add batch_size to the job config
| * 2defa92 (HEAD -> feature/batch-size) Read batch size from the command line
| * 3d6663d Embed in batches
|/  
* ce76024 (origin/main, origin/HEAD, main) Write vectors to the daily bucket
* bafe874 Add embedding job
```
<!-- /snippet -->

Try it before I do. From the brackets and the graph on this screen, say the state out loud.

**[PAUSE]**

Spoken: "The local branch has two commits that the server's branch of the same name lacks, and the server's branch has one commit that the local branch lacks. The local branch's upstream is `origin/main`, not the branch it is pushed to." Notice what that sentence took from the screen: the brackets and the graph. Nothing else.

**[ANIMATION]** graph: bafe874-ce76024 main origin/main; ce76024-3d6663d-2defa92 feature/batch-size; ^ce76024-56bb8e4 origin/feature/batch-size; HEAD=feature/batch-size title=The_picture_you_carry_in_your_head

**[ANIMATION]** step: state-1

**Part 2, Mechanism.** No snippet. A mechanism is never on a terminal, so what you see is the picture you carry in your head. Spoken: "Pull integrates the configured upstream; a push with a branch name targets the server branch of that name. Here the two are different branches, so the pull has nothing to do and the push is not a fast-forward. Git recorded that upstream because the branch was created from a remote-tracking branch, which is the right default for a local copy of a remote branch."

**[ANIMATION]** end

**Part 3, Evidence.** The read-only commands, and what would prove you wrong.

<!-- snippet: ch29/case-wrong-upstream/08-test -->
```text
# H1: the server branch has a commit that the local branch lacks.
$ git log --oneline HEAD..origin/feature/batch-size
56bb8e4 Add batch_size to the job config
# H1: and git pull integrates another branch.
$ git config get branch.feature/batch-size.merge
refs/heads/main
# H3: was the server branch rewritten? Its remote-tracking reflog has one entry, a first fetch.
$ git reflog show origin/feature/batch-size
56bb8e4 refs/remotes/origin/feature/batch-size@{0}: pull: storing head
# Would the two lines of work conflict? A test merge that touches nothing:
$ git merge-tree --write-tree --name-only HEAD origin/feature/batch-size
e2386b3e50aabb629564655df6e66d79d2d11040
[exit status: 0]
```
<!-- /snippet -->

Spoken: "I would confirm it with the upstream setting of the branch and with the commits the server branch has that mine lacks. If a server rule were the cause, the rejection would say 'remote rejected'; if the branch had been rewritten, the fetch would have reported a forced update." Two commands named, two alternatives ruled out, in two sentences.

**Part 4, Fix.** The lowest-risk change and what it touches.

<!-- snippet: ch29/case-wrong-upstream/09-fix -->
```text
$ git branch backup/batch-size-before-rebase
$ git branch --set-upstream-to=origin/feature/batch-size
branch 'feature/batch-size' set up to track 'origin/feature/batch-size'.
$ git status -sb
## feature/batch-size...origin/feature/batch-size [ahead 2, behind 1]
$ git rebase
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/batch-size.
$ git log --graph --oneline -4
* aca1b2f Read batch size from the command line
* 097fe6f Embed in batches
* 56bb8e4 Add batch_size to the job config
* ce76024 Write vectors to the daily bucket
```
<!-- /snippet -->

Spoken: "After a backup ref, I point the upstream at the right branch and rebase my two commits onto it, which is acceptable because they exist nowhere else. Then a plain push. No force, and the colleague's commit stays."

<!-- snippet: ch29/case-wrong-upstream/11-verify -->
```text
$ git status
On branch feature/batch-size
Your branch is up to date with 'origin/feature/batch-size'.

nothing to commit, working tree clean
$ git branch -vv
  backup/batch-size-before-rebase 2defa92 Read batch size from the command line
* feature/batch-size              aca1b2f [origin/feature/batch-size] Read batch size from the command line
  main                            ce76024 [origin/main] Write vectors to the daily bucket
$ git rev-parse HEAD @{upstream}
aca1b2fe23a5fed73fb916e3c34ed1ba7095dec0
aca1b2fe23a5fed73fb916e3c34ed1ba7095dec0
$ git ls-remote origin feature/batch-size
aca1b2fe23a5fed73fb916e3c34ed1ba7095dec0	refs/heads/feature/batch-size
$ git range-diff origin/main backup/batch-size-before-rebase HEAD
-:  ------- > 1:  56bb8e4 Add batch_size to the job config
1:  3d6663d = 2:  097fe6f Embed in batches
2:  2defa92 = 3:  aca1b2f Read batch size from the command line
$ git pull
Already up to date.
```
<!-- /snippet -->

One clause of verification belongs in the fix: "and I verify by comparing my tip with what the server reports for the branch."

**Part 5, Prevention.** End on the control.

<!-- snippet: ch29/case-wrong-upstream/12-prevent -->
```text
$ git branch -D backup/batch-size-before-rebase
Deleted branch backup/batch-size-before-rebase (was 2defa92).
# A new branch from origin/main that does not take origin/main as its upstream:
$ git switch -c feature/shard-output --no-track origin/main
Switched to a new branch 'feature/shard-output'
$ git branch -vv
  feature/batch-size   aca1b2f [origin/feature/batch-size] Read batch size from the command line
* feature/shard-output ce76024 Write vectors to the daily bucket
  main                 ce76024 [origin/main] Write vectors to the daily bucket
$ git push
fatal: The current branch feature/shard-output has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin feature/shard-output

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.

[exit status: 128]
```
<!-- /snippet -->

Spoken: "To prevent it, create topic branches without tracking the starting point, and read the brackets in the branch listing before the first push. That is a client habit and a client setting, which is weaker than a server rule, and here no server rule applies."

Now do it yourself. Stop the video, start a recorder, and give the whole answer in two minutes without looking at the screen. Say it out loud.

**[PAUSE]**

Then listen. Count the commands you named: more than four means you were narrating. Check your first sentence: did it describe state? Check your last: did it end on a control or a limit?

**[ON SCREEN]** Two documents, shown and not read out in full. First the protocol, [`interview/interview-mode-protocol.md`](../../interview/interview-mode-protocol.md): its section on what the interviewer does after each answer. Grade; if the answer was weak, state the precise gap and read the model answer; ask the follow-up, which is asked after every answer, strong or weak; grade the follow-up. Then section 3 of the guide, [`interview/senior-engineer-interview-guide.md`](../../interview/senior-engineer-interview-guide.md), with its worked example in the five parts: the question from the hook of this video, answered in about a hundred words. Read that example after you have recorded your own answer to it, not before.

And the question from the opening? Its worked answer is in section 3 of the guide, in the five parts, in about a hundred words. Record your own answer to it first. Then read the example.

One more format to know: the debugging round. The interviewer states a symptom in one sentence. You say what you would inspect first, and why. The interviewer answers only with the output that command would produce. This repeats until you state the root cause in the seven-line form, propose a fix, and say how to verify it. A state-changing command proposed before the cause is known ends the symptom with zero for the first graded item, and the interviewer says which work that command could have destroyed.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Starting with a command.** Root cause: the answer follows the order of doing instead of the order of explaining, so the state and the mechanism never get said.
2. **Naming the wrong layer.** Root cause: "GitHub rejected it" and "Git rejected it" feel interchangeable in speech, and they are different statements with different fixes.
3. **Filling a gap with confidence.** Root cause: "I do not know" feels like failure, although the protocol grades an honest gap above a confident wrong mechanism.
4. **Talking for four minutes.** Root cause: the answer narrates every command of a session instead of the five parts, and the protocol stops it at three minutes.
5. **Grading what you meant.** Root cause: without a recording you remember the answer you intended, not the one you gave.

## PRODUCTION EXAMPLE

Now, out of the lab. A senior engineer is interviewing for a staff role. The interviewer says: "`main` moved backwards overnight. Go." This is the incident walk-through form, and the interviewer plays the repository.

A candidate who has only used Git says: "I would reset it to the last good commit and force-push." The interviewer notes it and asks which commit that is. The candidate doesn't know yet.

The candidate who has practised the five parts says: "First the state: I want the server's current value and the previous one, so I would ask the server directly and read the reflog of the remote-tracking branch in a clone that fetched before and after. Three mechanisms produce this; that reflog separates two of them." The interviewer answers with output. Four exchanges later the candidate states the root cause with its layer, proposes a restore with a lease that names the examined value after two checks, and ends with the rule that would have refused the push, and with what it would cost. The whole exchange takes six minutes, and at no point did the candidate propose a change before knowing the cause.

## PRACTICE EXERCISE

Your turn. Run one session of ten questions from [`interview/cto-question-bank.md`](../../interview/cto-question-bank.md), areas 1 to 8, by the protocol, recorded.

Draw the ten numbers first, by level mix: two foundational, three working engineer, three senior, two principal. Before each answer, predict in one word which of the five parts will carry the answer. Answer within two minutes, then the follow-up within one. Open the answers file only after the tenth recording. Grade what you said on the six dimensions, and write each gap in one sentence. Questions below 9 of 15 go into your weak-area tracker.

The challenge: run the debugging round of the protocol with a colleague as interviewer, on areas 15 and 16.

## INTERVIEW QUESTION

**[ON SCREEN]** Q464: "A CTO does not ask "which command fixes this". Which four questions does a CTO ask about a repository problem, and which of them can a command answer?"

Read the question, then answer out loud, recorded, in two minutes.

**[PAUSE]**

A strong answer gives the four questions in the order a CTO asks them. Then it does what the second half asks, and this is where the answer is won: for each of the four it says whether a command can answer it, partly or wholly, and what else is needed where a command can't. Use the five parts lightly here: this is a question about judgment, so the weight is on the last part. End on a limit, as the rule says: what no command will ever tell you.

## RECAP

Let's land this.

- A session is one question at a time, spoken, two minutes for the answer and one for the follow-up, without a terminal or notes.
- Answers are graded on correctness, depth, terminology, reasoning, practical understanding and production awareness, and a wrong mechanism or layer scores zero for the whole answer.
- A strong answer has five parts in order: state, mechanism, evidence, fix, prevention; the first two are never optional.
- The first sentence answers the question and names the object, ref or layer; the last ends on the control or the limit.
- Alone, you record, answer, then open the answers file, and grade what you said.

## HOMEWORK

Work through the twenty worked answers of the guide, section 4. For each one, answer aloud first, recorded, within two minutes. Then read the three quality levels and place your own answer among them. Write down, for each of the twenty, the one sentence that separates the middle level from the top one.

Today you gave your answers a shape: state, mechanism, evidence, fix, prevention. Record one session before the next video. Next time: the briefing for the final knowledge test. Until then, look at the state first and type second. See you in the next one.
