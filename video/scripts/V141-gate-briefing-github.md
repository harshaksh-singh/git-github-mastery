# V141: Gate briefing: GitHub

- **Part.** 5: GitHub
- **Module.** 25
- **Planned minutes.** 10
- **Prerequisites.** V122, V129, V130, V136, V139, V140
- **Textbook sections.** [Chapter 17](../../textbook/ch17-pull-requests.md), section 17.3; [Chapter 18](../../textbook/ch18-branch-protection.md), section 18.17; the rules in [`assessments/README.md`](../../assessments/README.md)
- **Demo scripts.** `labs/ch17/pr-anatomy.sh` (snippets `commit-list`, `merge-base`, `three-dot`, `two-dot`)

## HOOK

**[ON SCREEN]** One line: "The pull request is green and approved, and GitHub will not merge it. Explain."

That's the kind of sentence Gate 6 is built from. A gate is the assessment that closes a part of this course. You'll have no browser, no repository on GitHub and no `gh` beyond its help text. You'll have configuration files, a described situation and real Git evidence. The answer that earns the points says, for every fact, which layer it belongs to. Keep that sentence. It gets answered in two columns.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a briefing, not a lesson. It tells you what Gate 6 covers, how it's taken, how its hands-on part differs from the gates you've sat so far, and how to prepare. It doesn't open the gate file or the case files, and you shouldn't either. The assessment rules say it directly: a gate that has been read is a gate that has been taken.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- state what Gate 6 covers and its threshold of 85;
- explain how the hands-on part differs: three cases on paper;
- name the layer, Git or GitHub, of every fact in an answer;
- prepare with the procedures: the authentication decision tree, pull request anatomy, and "why can't I merge".

## CONCEPT

**What the gate covers.** Gate 6 is taken after Module 25. It covers the platform model, authentication, pull requests, merge methods, rulesets, CODEOWNERS, signing and the CLI. It passes at 85.

**[ANIMATION]** walk: id=parts columns=part,points,how rows=Concepts:30:six_written_questions,_closed_book,_no_terminal|Prediction:20:four_items,_no_terminal|Hands-on_diagnosis:30:-|Oral_interview:20:six_questions,_each_with_a_follow-up,_spoken mono=off title=100_points_in_four_parts at_1=18 at_2=45 at_3=58 at_4=68

**The four parts.** Like every gate it has 100 points in four parts with fixed weights. Concepts: 30 points, six written questions, closed book, no terminal. Each requires a mechanism. Prediction: 20 points, four items, no terminal. Hands-on diagnosis: 30 points. Oral interview: 20 points, six questions asked one at a time, each with a follow-up, spoken, without notes.

**[ANIMATION]** end

**The pass rule.** The threshold overall, and at least 70 percent in every part: 21 of 30 in Concepts, 14 of 20 in Prediction, 21 of 30 in Hands-on, 14 of 20 in Oral.

Quick quiz. Your total is 88, and your Prediction part is 13 of 20. A, a pass. B, a miss. Your answer?

**[PAUSE]**

**[ANIMATION]** cards: id=miss question=A_pass_or_a_miss? cards=total_88:above_the_threshold_of_85|Prediction_13_of_20:one_part_below_70_percent,_it_needs_14 marks=1:ok,2:bad at_1=8 at_2=40 at_marks=60

B, a miss. A total above the threshold with one part below 70 percent is a miss, and Prediction needs 14.

**[ANIMATION]** stores: id=desks boxes=gates_1_to_5:hands-on_in_the_lab_shell|gates_6_to_8:hands-on_on_paper rows=1:A:a_script_built_a_broken_repository|1:A:you_repaired_it|2:B:three_cases_on_paper|2:B:configuration_files|2:B:described_situations|2:B:real_Git_evidence title=Part_3_changes at_1=8 at_2=58

**What is different in Part 3.** In gates 1 to 5 a script built a broken repository and you repaired it in the lab shell. Gates 6 to 8 can't work that way, because GitHub's behavior can't be captured in the lab. So Part 3 is three cases on paper, built from configuration files, described situations and real Git evidence.

**[ANIMATION]** end

**[ON SCREEN]** The rule for paper cases from `assessments/README.md`.

The rule reads: these gates run nothing on GitHub. No GitHub output appears anywhere in them. And the only `gh` invocation you need is `gh` with a command and `--help`. For the paper cases the gate file gives the points per case.

**[ANIMATION]** stores: id=cols boxes=Git_says:a_fact|GitHub_says:a_decision rows=1:A:"The_branch_is_behind"|2:A:you_can_prove_it_with_a_command|3:B:"The_merge_is_blocked_because_the_branch_is_behind"|4:B:made_by_a_rule_that_someone_configured title=Say_both_halves,_and_which_is_which at_1=32 at_2=45 at_3=55 at_4=72

**The layer rule.** An answer that doesn't say which layer acted loses points. This is the habit the whole of Part 5 was meant to build. "The branch is behind" is a Git fact. You can prove it with a command. "The merge is blocked because the branch is behind" is a GitHub decision, made by a rule that someone configured. Say both halves, and say which is which.

## MENTAL MODEL

**[ANIMATION]** stores: id=sheet boxes=Git_says:what_a_clone_can_show|GitHub_says:platform_state_or_a_platform_decision rows=1:A:ancestry|1:A:the_merge_base|1:A:the_commits_a_pull_request_introduces|1:A:the_paths_it_changes|1:A:a_signature_header|1:A:which_version_of_a_file_is_on_which_branch|2:B:which_rules_apply|2:B:the_review_decision|2:B:required_checks,_and_a_result_for_the_newest_commit|2:B:which_CODEOWNERS_file_is_read|2:B:what_a_badge_displays|2:B:which_merge_methods_are_allowed title=One_form_for_every_case

**[ANIMATION]** step: boxes

Use one form for every case: two columns.

**[ANIMATION]** step: 1

On the left, "Git says". Everything here is something a clone can show: ancestry, the merge base, the commits a pull request introduces, the paths it changes, whether a commit has a signature header, which version of a file exists on which branch.

**[ANIMATION]** step: 2

On the right, "GitHub says". Everything here is platform state or a platform decision: which rules apply, the review decision, which checks are required and whether a result exists for the newest commit, which CODEOWNERS file is read, what a badge displays, which merge methods are allowed.

**[ANIMATION]** end

Try it now, thirty seconds, on paper. Two columns, four facts: the merge base, the review decision, the changed paths, the required checks.

**[PAUSE]**

**[ANIMATION]** step: sheet.2

The merge base and the changed paths go on the left: a clone can show them. The review decision and the required checks go on the right: platform state.

**[ANIMATION]** say: The_finding:_one_sentence_that_connects_a_line_on_the_left_to_a_line_on_the_right

Then the finding: one sentence that connects a line on the left to a line on the right.

**[ANIMATION]** say: Stale_approval:_a_platform_concept_defined_by_a_Git_event._Write_it_across_both_columns

Where this form falls short: some facts need both columns to state at all. "Stale approval" is a platform concept defined by a Git event, a push that changed the diff. Write those across both columns and say so.

**[ANIMATION]** cards: id=procs cards=the_authentication_decision_tree:a_refused_connection_or_a_refused_push|the_anatomy_of_a_pull_request:unexpected_commits_or_an_unexpected_diff|the_nine_steps_of_why_can't_I_merge:from_video_134 numbered=on title=Three_procedures_give_you_the_rows at_1=14 at_2=42 at_3=75

Three procedures from this part give you the rows. The authentication decision tree, for any case that starts with a refused connection or a refused push. The anatomy of a pull request, for any case about unexpected commits or an unexpected diff. And the nine steps of "why can't I merge" from video 134.

## DIAGRAM

**[ANIMATION]** stores: id=case boxes=Git_says:evidence_from_a_clone|GitHub_says:rules_and_platform_state|finding:one_line_from_each_column rows=1:A:the_pull_request_introduces_3_commits|1:A:origin/main_is_NOT_an_ancestor_of_the_head@hl|1:A:the_test_merge_is_clean|1:A:0_merge_commits_among_the_3|2:B:the_ruleset_on_the_default_branch_requires_one_status_check,_strict_(up_to_date)@hl|2:B:the_check_result_exists_for_the_head_commit|2:B:linear_history_is_required:_satisfied|3:C:the_strict_policy_(GitHub)_is_unmet_because_the_base_moved_(Git)@hl|4:C:repair:_updating_the_branch_creates_a_new_head_commit|4:C:the_check_must_report_again|4:C:a_stale_approval_can_be_dismissed title=Approved,_green,_and_it_cannot_be_merged at_1=2 at_2=14 at_3=36 at_4=78

**[DIAGRAM]** Draw the empty sheet first. Fill the left column from evidence, then the right column from the configuration, then the finding. The example is a blocked pull request of the kind you diagnosed in Lab 23.3.

```text
  Case: the pull request is approved, checks are green, and it cannot be merged.

  Git says (evidence from a clone)              GitHub says (rules and platform state)
  -------------------------------------------   ---------------------------------------------
  the pull request introduces 3 commits         the ruleset on the default branch requires
  origin/main is NOT an ancestor of the head      one status check, strict (up to date)
  the test merge is clean                       the check result exists for the head commit
  0 merge commits among the 3                   linear history is required: satisfied

  Finding: the strict policy (GitHub) is unmet because the base moved (Git).
  Consequence of the repair: updating the branch creates a new head commit, so the
  check must report again and a stale approval can be dismissed (GitHub).
```

Here's the opening sentence, answered. The finding joins one line from each column: the strict policy, GitHub, is unmet because the base moved, Git.

**[DIAGRAM]** Notice the last two lines. A complete answer does not stop at the cause. It says what the repair costs, in the layer where the cost arises.

## LIVE TERMINAL DEMO

**[TERMINAL]** A warm-up: Git evidence of the kind the paper cases contain. Replay with `labs/run ch17/pr-anatomy`. Every command reads; `git fetch`, which the replay starts with, is 🟢 SAFE. The IDs equal the book's.

**Step 1: the commit list.**

```bash
git log --oneline origin/main..feature/priority-routing
git rev-list --count origin/main..feature/priority-routing
```

Which tab of a pull request does this range correspond to? Say it out loud.

**[PAUSE]**

<!-- snippet: ch17/pr-anatomy/02-commit-list -->
```text
# The "Commits" tab: commits reachable from the head branch and not from the base branch.
$ git log --oneline origin/main..feature/priority-routing
16d4788 Fix the name of the escalations queue
12ae95d Route high-priority tickets to escalation
44c1e7b Add priority scoring
$ git rev-list --count origin/main..feature/priority-routing
3
```
<!-- /snippet -->

The Commits tab: the commits reachable from the head branch and not from the base branch. Three of them, with `16d4788` at the tip.

**Step 2: the merge base.**

```bash
git merge-base origin/main feature/priority-routing
```

<!-- snippet: ch17/pr-anatomy/03-merge-base -->
```text
$ git merge-base origin/main feature/priority-routing
9a383e547a1c8840f3c5c7b23bfab6120f366ed0
$ git log --oneline -1 $(git merge-base origin/main feature/priority-routing)
9a383e5 Add classifier test
```
<!-- /snippet -->

`9a383e5`, "Add classifier test". Write the merge base down in every case that involves a diff. Half the surprises of Chapter 17 are a merge base that isn't where the author thinks it is.

**Step 3: three dots.**

```bash
git diff --stat origin/main...feature/priority-routing
```

<!-- snippet: ch17/pr-anatomy/04-three-dot -->
```text
# The "Files changed" tab: merge base compared with the head. Three dots.
$ git diff --stat origin/main...feature/priority-routing
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

The Files changed tab: the merge base compared with the head. Two files.

**Step 4: two dots.**

```bash
git diff --stat origin/main..feature/priority-routing
```

**[ANIMATION]** graph: id=dots ...3-9a383e5-?1_commit origin/main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing; HEAD=none; note:9a383e5:merge_base; range:44c1e7b,12ae95d,16d4788:the_Commits_tab; cmd:git_diff_--stat_origin/main..feature/priority-routing pace=quick

`main` has one commit that the branch doesn't have. How many files will the two-dot form list, and in which direction will that commit's change appear? Make your prediction.

**[PAUSE]**

<!-- snippet: ch17/pr-anatomy/05-two-dot -->
```text
# Two dots compare the two tips. The newer commit on main appears, reversed.
$ git diff --stat origin/main..feature/priority-routing
 config/routing.yaml | 2 +-
 router/classify.py  | 6 +++++-
 router/priority.py  | 6 ++++++
 3 files changed, 12 insertions(+), 2 deletions(-)
$ git diff origin/main..feature/priority-routing -- config/routing.yaml
diff --git a/config/routing.yaml b/config/routing.yaml
index b97f8de..a84cfc9 100644
--- a/config/routing.yaml
+++ b/config/routing.yaml
@@ -1,3 +1,3 @@
 model: router-small-v1
-confidence_threshold: 0.7
+confidence_threshold: 0.6
 fallback_queue: general
```
<!-- /snippet -->

Three files. `config/routing.yaml` appears although the pull request never touched it, and the change is reversed: the threshold seems to go from 0.7 back to 0.6. Two dots compare the two tips. If a case shows you a diff with a file the author didn't change, this is your first question: which two commits were compared?

In the gate, evidence like this is printed for you. Your work is to read it and place it in the left column.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Answering with a repair before naming the cause.** Root cause: the case asks which rule refused and which fact it looked at, and a repair without that is a guess.
2. **Not naming the layer.** Root cause: Git computes facts and GitHub applies rules to them, and an answer that merges the two cannot say who must change what.
3. **Reading a two-dot diff as "what the pull request changes".** Root cause: two dots compare the two tips; the pull request shows the merge base compared with the head.
4. **Opening the gate file "to see what is in it".** Root cause: the gate measures what you can do unseen, so reading it spends the attempt.
5. **Treating the workflow and configuration files of a paper case as examples to reuse.** Root cause: the files in the gate directories are teaching material with faults on purpose.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: case.4

**[ANIMATION]** say: Four_lines:_the_clone,_the_rules_page,_the_one_unmet_rule,_what_the_repair_triggers

Now, out of the lab. A backend team's incident channel, on a Friday. A developer reports that a hotfix can't be merged. The engineer on call answers in the two-column form, in four lines: what the clone shows, what the rules page shows, the one rule that's unmet, and what the repair will trigger. The developer updates the branch, waits for the one check, and merges. Nobody asked an administrator to bypass anything.

**[ANIMATION]** say: off

That's what the gate is rehearsing. An answer in that form can be acted on by someone who wasn't in the conversation.

## PRACTICE EXERCISE

**[ANIMATION]** end

Your turn. Redo the Level 4 exercises of the block in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md): Exercise 20.6, "Three faults, no connection". Exercise 21.6, "Five commits for a two-commit fix". And Exercise 22.5, "The release that does not contain its fix". Then the two at Level 5: Exercise 23.8, ""Main is protected. How did a force push get through?"", and Exercise 24.6, "Verified, and she was on a plane".

For each, before you write anything else, draw the two columns and predict which column the decisive fact will be in.

When you're ready, take Gate 6: [`assessments/gate-6-github.md`](../../assessments/gate-6-github.md). One sitting, parts in order.

## INTERVIEW QUESTION

**[ON SCREEN]** Q259: "A required status check is green on a pull request. What does that prove, and what does it not prove?"

**[PAUSE]**

Answer out loud first. A strong answer is exact about the object of the proof: which commit the result is attached to, and what was tested to produce it. Then it lists what lies outside: what has happened to the base since, who is able to report a check of that name, and what a green check says about review. The follow-up is about strict mode on a busy branch: name what it costs, and what the answer is when that cost bites.

## RECAP

Let's land this.

You should now be able to say:

- Gate 6 covers the platform model, authentication, pull requests, merge methods, rulesets, CODEOWNERS, signing and the CLI, and passes at 85 with at least 70 percent in every part.
- Its hands-on part is three cases on paper; nothing runs on GitHub and no GitHub output appears.
- Every fact in an answer carries its layer: "Git says" or "GitHub says".
- The preparation is three procedures: the authentication decision tree, pull request anatomy, and "why can't I merge".

## HOMEWORK

Before the gate: answer the "Interview questions" sections of Chapters 15 to 19 aloud. Read [`reference/github-reference.md`](../../reference/github-reference.md).

You've finished the GitHub part, and you can say which layer stands behind a fact. Practise the two columns once before the gate. Next time, a new part: the Actions model, and YAML read carefully. Until then, look at the state first and type second. See you in the next one.
