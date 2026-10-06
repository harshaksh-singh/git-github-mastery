# V194: Gate briefing: Production debugging

- **Part.** 9, Production debugging and incident response
- **Module.** 38 (before Gate 9)
- **Planned minutes.** 10
- **Prerequisites.** V193
- **Textbook sections.** [Chapter 29](../../textbook/ch29-production-troubleshooting.md), sections 29.2 and 29.7; [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.2 and 30.15; the rules in [`assessments/README.md`](../../assessments/README.md)
- **Demo scripts.** `labs/ch29/preserve-evidence.sh` (snippets `01-record`, `02-backup-ref`)

## HOOK

**[ON SCREEN]** "Ten minutes into an incident the CTO asks for a status, and you have no root cause yet. What do you say?"

There are two bad answers. One is silence, or "we are looking into it". The other is a guess, delivered as a cause.

**[ANIMATION]** cards: id=answers question=Ten_minutes_in,_and_no_root_cause_yet cards=silence,_or_"we_are_looking_into_it"|a_guess,_delivered_as_a_cause|a_third_answer ask=3 marks=1:bad,2:bad at_1=0 at_2=5 at_3=10 at_marks=22

Gate 9, the last of the course's graded checkpoints, is built to find out whether you have a third answer, and whether your hands do the right thing while you give it: evidence first, a way back before any change, and no command that could destroy work where a safer one exists. Hold on to that third answer. It's coming.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a briefing. It teaches nothing new and shows no gate item. It tells you what Gate 9 covers, how its hands-on part is scored, and how to prepare. The gate file isn't opened in this video, and you don't open it before you sit the gate.

Gate 9 is the last of the nine gates. It closes Level 9 and with it the part of the course that teaches. What comes after it is assessment.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. State what Gate 9 covers and its threshold of 90.
2. Explain what is scored in the hands-on part: end state, safety of the path, explanation, the summary and the control.
3. Prepare by repeating incidents from freshly generated sandboxes without the solutions.
4. Give a status when no root cause is known yet.

## CONCEPT

**What the gate covers.** Gate 9 is taken after Module 38. It covers the diagnosis method, the ten incidents, and communication and postmortems: Chapters 29 and 30. You pass at 90 points of 100, with at least 70 percent in every part.

**[ANIMATION]** bars: id=points bars=Concepts:30|Prediction:20|Hands-on_diagnosis:30|Oral_interview:20 unit=points max=30 title=100_points,_four_parts

**The four parts.** As in every gate: Concepts, 30 points, six written questions that each require a mechanism, closed book and without a terminal. Prediction, 20 points, four items, without a terminal. Hands-on diagnosis, 30 points. Oral interview, 20 points, six questions asked one at a time, each with a follow-up, without notes.

**[ANIMATION]** stores: id=hands boxes=the_sandbox:built_in_a_broken_state|you_read|you_do_not_read rows=1:B:the_symptoms|1:B:a_report,_incomplete_and_partly_wrong|2:C:the_generator,_the_answer_to_"what_happened"@bad|2:C:the_check_script,_the_end_state_line_by_line@bad|3:A:a_log_of_every_command@hl|3:A:when_you_think_you_are_done,_run_the_check title=The_hands-on_part

**The hands-on part.** For Gate 9 it's a repository that a script builds in a broken state, with a report that is incomplete and partly wrong. You know this form from the ten incidents. From the course root you run the generator of variant A, which prints the path of the sandbox. You open the lab shell there and read the symptoms. You don't read the generator, which is the answer to "what happened", or the check script, which lists the end state line by line. You keep a log of every command. When you think you're done, you run the check.

**[ANIMATION]** cards: id=quiz question=The_right_end_state,_reached_with_a_hard_reset_and_a_forced_push cards=A,_full_marks|B,_points_at_risk marks=2:ok at_1=60 at_2=72

**[ANIMATION]** step: 2

Quick quiz. Your sandbox ends in exactly the right state, reached with a hard reset and a forced push. A, full marks, or B, points at risk? Your answer?

**[PAUSE]**

**How it is scored.** The points are split three ways.

**[ON SCREEN]** From the assessments README.

- **End state.** The check script inspects the sandbox with read-only commands and prints one line per condition, then `PASS` or `NOT YET`. Each failed line costs one point.
- **Safety of the path.** Your command log is read: evidence before change, a way back before each rewrite, no command that could destroy uncommitted or shared work where a safer one exists. A correct end state reached through `git reset --hard`, a forced push or a re-clone can still fail this row.
- **Explanation.** What the symptoms file asks you to write: root causes in the form of the seven-line root-cause box, and, in Gate 9, the summary for the CTO and the control.

**[ANIMATION]** walk: id=scored columns=row,what_is_read rows=End_state:the_sandbox,_by_the_check_script|Safety_of_the_path:your_command_log|Explanation:the_root-cause_box,_the_summary_for_the_CTO,_the_control pick=2 mono=off title=The_points_are_split_three_ways at_1=3 at_2=6 at_3=9 at_pick=14

The answer was B, so read the second item twice. A state-changing command before the root cause is established costs more here than anywhere else in the course. The gate doesn't only ask whether you can repair the repository. It asks whether a colleague could trust you with theirs.

**[ANIMATION]** cards: id=status question=A_status_without_a_root_cause_is_still_a_status cards=Say_"I_do_not_know_yet"_early:with_the_time_of_the_next_update|Separate_what_you_observed_from_what_you_infer|The_first_message_goes_out:as_soon_as_you_know_which_branch_people_must_leave_alone numbered=on

**A status without a root cause.** Here's the third answer from the opening. From video 193: a status without a root cause is still a status. Say "I do not know yet" early, with the time of the next update. Separate what you observed from what you infer. And remember when the first message goes out: as soon as you know which branch people must leave alone, long before you know the cause.

**[ANIMATION]** gates: id=miss gates=your_score_sheet:done|restudy:done:-:with_the_remediation_map|wait:done:-:at_least_two_days|retake_the_whole_gate:done:-:the_hands-on_part_is_variant_B title=After_a_miss

**After a miss.** Remediation and a different variant, not the answers. You receive your score sheet, restudy with the remediation map, wait at least two days, and retake the whole gate. The hands-on part is then variant B, with a different project, a different state and different faults.

## MENTAL MODEL

A picture helps. Think of a driving test. The examiner doesn't only check whether you arrive. The examiner watches the mirrors, the signals, the speed at the crossing. A candidate who arrives at the destination after running a red light has failed, and nobody finds that unfair.

**[ANIMATION]** cards: id=log question=The_command_log_shows cards=whether_you_looked_before_you_moved:with_read-only_commands|whether_you_set_an_anchor_before_each_rewrite:a_named_commit_to_return_to|whether_you_chose_the_lower_rung:when_one_was_available

The command log is the examiner's view of your mirrors. It shows whether you looked, with read-only commands, before you moved. It shows whether you set an anchor, a named commit to return to, before each rewrite. And it shows whether you chose the lower rung of the ladder when one was available.

**[ANIMATION]** end

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

Before I say what the drawing shows: which two stages do people skip under pressure? Say it out loud.

**[PAUSE]**

Preserve and communicate, and each carries points. No stage is unscored.

## LIVE TERMINAL DEMO

**[TERMINAL]** A warm-up, not a gate item. Replay `labs/run ch29/preserve-evidence` and show its first two snippets: the two acts that should precede any repair. Both are 🟢 SAFE. Before them, in any unknown repository, come the three read-only looks you know by heart: `git status`, `git reflog`, and `git ls-remote origin` for what the server holds.

Into the lab, for a warm-up, not a gate item. Before any repair come three read-only looks: `git status`, `git reflog`, and `git ls-remote origin` for what the server holds. Try it now, in a repository of your own that has a remote. Thirty seconds. All three only read, and the third one contacts your remote to do it. Say out loud what each one told you.

**[PAUSE]**

Three looks, and nothing changed: the state now, where HEAD has been, and what the server holds.

**Record.** Predict what the file will be good for an hour later. Say it out loud.

**[PAUSE]**

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

Two refs, one second each. A ref is a name that points at a commit.

**[ANIMATION]** graph: id=anchor *-...2-4a03014 feature/latency-budget; *-...3-075407e; HEAD=075407e => + 075407e rescue/latency-wip; cmd:git_branch_rescue/latency-wip_HEAD => + 4a03014 special:refs/backup/latency-budget; cmd:git_update-ref_refs/backup/latency-budget_feature/latency-budget title=A_way_back_before_each_rewrite dx=260

In a command log these two snippets are what "a way back before each rewrite" looks like. If your log for a drill doesn't contain their equivalent before the first state-changing command, repeat the drill.

**[ON SCREEN]** The gate rules from the assessments README: finish the modules first; one sitting, parts in order; do not read `generate.sh` or `check.sh`; keep a log of every command; the examiner scores with the answer key, which you do not open. Part 4 needs a second person or the tutor; if you rehearse alone, record yourself and score the recording the next day.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Preparing by rereading solutions.** Root cause: the gate measures diagnosis from an incomplete report, and reading trains recognition, not diagnosis.
2. **Repairing first and explaining afterwards.** Root cause: the log then shows state-changing commands before the root cause, which fails the safety row whatever the end state.
3. **Reaching the end state by the shortest route.** Root cause: a hard reset, a forced push or a re-clone can produce a passing check and still destroy evidence or work that a safer command would have kept.
4. **Believing the report.** Root cause: the report is incomplete and partly wrong by design, and a diagnosis built on its interpretation inherits its errors.
5. **Giving a guess as a status.** Root cause: "I do not know yet, next update at a stated time" feels weak, although it is the only status that stays true.

## PRODUCTION EXAMPLE

**[ANIMATION]** walk: id=two columns=,the_first_engineer,the_second_engineer rows=begins_with:git_reset_--hard_origin/main:git_status,_the_reflog,_git_ls-remote_origin|then:a_cherry-pick_from_memory,_a_forced_push:an_evidence_file,_a_rescue_branch,_three_hypotheses,_one_additive_fix|the_end_state:passing:passing|"Is_the_uncommitted_change_still_there?":cannot_know:answers_from_the_evidence_file marks=3.2:ok,3.3:ok,4.2:bad,4.3:ok mono=off title=Two_logs,_one_end_state

**[ANIMATION]** step: 3

Now, out of the lab. Two engineers are asked to repair the same broken branch in a hiring exercise. Both end with a passing state. The first one's shell history begins with `git reset --hard origin/main`, followed by a cherry-pick from memory and a forced push. The second one's begins with `git status`, the reflog, and `git ls-remote origin`. Then an evidence file and a rescue branch. Then three hypotheses in a comment. Then one additive fix and the same commands again.

**[ANIMATION]** step: 4

The reviewer asks both the same follow-up: "A colleague had an uncommitted change in that clone. Is it still there?" The second engineer answers from the evidence file. The first cannot know. The team hires the second, and the reviewer's note says why in one line: the end states were equal, and only one of the two could be given a production repository.

Gate 9 scores the same difference, with the same instrument: your log.

## PRACTICE EXERCISE

Your turn. Regenerate Incident 2, [`incidents/02-force-push-wrong-branch`](../../incidents/02-force-push-wrong-branch/SYMPTOMS.md), Incident 5, [`incidents/05-rebased-shared-branch`](../../incidents/05-rebased-shared-branch/SYMPTOMS.md), and Incident 6, [`incidents/06-pr-500-changes`](../../incidents/06-pr-500-changes/SYMPTOMS.md), and repeat them against the clock, without notes and without the solutions.

Before each, predict how long the read-only phase will take you and write the time down. Keep a command log. Afterwards, mark in the log the first state-changing command and check three things: was the root cause written down before it, was there an anchor before it, and was a lower rung available. Then write the four-part summary and one control with its enforcing layer.

When the three are done: take Gate 9, [`assessments/gate-9-production-debugging.md`](../../assessments/gate-9-production-debugging.md), in one sitting, with the parts in order.

## INTERVIEW QUESTION

**[ON SCREEN]** Q469: "Ten minutes into an incident the CTO asks for a status, and you have no root cause yet. What do you say?"

Read the question, then answer out loud, and time it.

**[PAUSE]**

The answer should take well under a minute. A strong answer has the shape of a status and the honesty of its content. It says what is affected and what is being done to stop it from spreading. It separates what has been observed from what is suspected. It says plainly that the cause isn't known yet, and it commits to the time of the next update. It doesn't fill the gap with a guess, and it doesn't go silent. If you can also say what the CTO should not do or decide yet, you've given them something to act on.

## RECAP

Let's land this.

- Gate 9 covers the diagnosis method, the ten incidents, communication and postmortems, and is passed at 90 with at least 70 percent in every part.
- Its hands-on part is a generated repository with a report that is incomplete and partly wrong; the generator and the check script are not read.
- The hands-on points are split between end state, safety of the path, and explanation, which here includes the summary for the CTO and the control.
- A state-changing command before the root cause is established costs more here than anywhere else in the course.
- A status without a root cause is still a status: what is known, what is being done, "I do not know yet", and the time of the next update.

## HOMEWORK

Before the gate, answer the "Interview questions" sections of Chapters 29 and 30 aloud, one at a time, without notes, each with a follow-up you invent yourself. Record the session if you rehearse alone, and score it the next day. After the gate, Part 10 begins: the interview series, the final knowledge test and the capstone.

You know what the gate looks at: your hands, and your honesty. Practise the three drills first. Next time: the CTO interview series, and the structure of a strong answer. Until then, look at the state first and type second. See you in the next one.
