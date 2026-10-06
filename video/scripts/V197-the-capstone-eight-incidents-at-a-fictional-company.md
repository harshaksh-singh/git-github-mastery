# V197: The capstone: eight incidents at a fictional company

- **Part.** 10, Senior engineer: assessment
- **Module.** 41
- **Planned minutes.** 16
- **Prerequisites.** V196
- **Textbook sections.** [Chapter 29](../../textbook/ch29-production-troubleshooting.md), section 29.2, and [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.2, 30.15 and 30.19, as applied by [`capstone/README.md`](../../capstone/README.md), [`capstone/DELIVERABLES.md`](../../capstone/DELIVERABLES.md) and [`capstone/EVALUATION.md`](../../capstone/EVALUATION.md)
- **Demo scripts.** `labs/capstone/end-to-end.sh` (snippet `01-company` only)

## HOOK

**[ON SCREEN]** "Would a CTO hand this person a repository incident and leave the room?"

That's the question the capstone answers, and the evaluation says it has no in-between. The outcome is one of two statements: demonstrates senior-level mastery, or not yet. Hold on to that question. You'll soon know what the evaluation reads to answer it.

**[ANIMATION]** stores: id=told boxes=what_you_are_told|what_nobody_tells_you rows=1:A:what_a_teammate,_a_manager_or_an_alert_would_tell_you|2:A:incomplete@dim|2:A:sometimes_wrong@bad|3:B:the_cause@hl|3:B:the_mechanism@hl title=Eight_working_days at_1=45 at_2=75 at_3=88

For eight working days you're a backend engineer at a small company. On each day something goes wrong in or around the team's repository, and you're the person who is asked to sort it out. Nobody tells you the cause. What you're told is what a teammate, a manager or an alert would tell you: incomplete, sometimes wrong, never the mechanism.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the briefing for the capstone, the last piece of work in the course. It adds nothing new to learn. It tests whether you can use what you learned when the situation doesn't announce which chapter it belongs to, when the states of earlier days are still in the repository, and when you have to write down what you did for people who weren't there.

I show you three documents and one transcript: the capstone's README, its list of deliverables, its evaluation, and the history of the repository you inherit. No stage's model replay is shown. The company, the people, the product and every alert are fictional and were constructed for this course. Everything runs locally in the lab sandbox.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Describe the company, the team, the repository and the sandbox of the capstone.
2. State the seven items every stage must deliver.
3. State the seven dimensions on which the work is evaluated and the disqualifying findings.
4. Set up the sandbox and receive the first stage.
5. Explain how the pull-request side of GitHub is played locally.

## CONCEPT

**[ANIMATION]** flow: id=router actors=a_customer_message,*intent-router,the_queue_of_a_desk msgs=1>2:received|2>2:a_keyword_score_and_an_embedding_score|2>2:the_best_intent_above_a_threshold|2>3:routed title=intent-router

**The company and the product.** Tessaly sells a customer-support platform. One of its backend services is `intent-router`: it receives a customer message, decides which intent the message has, and routes it to the queue of the desk that handles that intent. The decision blends two scores per candidate intent, a keyword score and an embedding score, and picks the best intent above a threshold. The code is small on purpose. You'll read all of it within minutes, and no stage requires more Python than a three-line change.

**[ANIMATION]** end

**The team.**

| Person | Role | What to expect |
|---|---|---|
| You | Backend engineer, three months in the team | Your clone is `you/` |
| Nandini Iyer | Tech lead; reviews and merges most pull requests; owns releases | Precise, asks for evidence, will not bypass a rule on a guess |
| Kabir Sethi | ML engineer; owns scoring and the embedding client | Fast, helpful, sometimes helps before asking |
| Tanvi Desai | Platform engineer; owns CI and deployment; on call this fortnight | Under time pressure; proposes the quickest route |
| Leela Varma | CTO | Reads your summaries; asks about customers, risk and recurrence |

The people are written to be reasonable. Each action that causes an incident looked right to the person who took it. Your postmortems are expected to show why.

**[ANIMATION]** cards: id=conv cards=Trunk-based:everyone_integrates_into_main|Nobody_pushes_to_main:changes_arrive_by_pull_request|Squash_merges_by_default:or_a_merge_commit|After_a_merge:the_server_deletes_the_head_branch|Releases_are_annotated_tags|Maintenance_lines,_release/MAJOR.MINOR:created_at_the_release_tag|A_fix_lands_on_main_first:then_git_cherry-pick_-x marks=2:ring

**[ANIMATION]** step: 7

**The conventions.** The team works trunk-based: everyone integrates into one branch, `main`. Nobody pushes to `main`. Every change arrives through a pull request, a proposal to merge one branch into another, and nobody rewrites it. Squash merges by default, where a pull request's commits become one commit, and a merge commit when the individual commits should stay visible. After a merge the server deletes the head branch. Releases are annotated tags. Maintenance lines are named `release/MAJOR.MINOR` and are created at the release tag the first time a released version needs a fix that `main` cannot deliver. A fix lands on `main` first and is copied to the maintenance line with `git cherry-pick -x`.

**[ANIMATION]** step: marks

**GitHub, not Git.** "Nobody pushes to `main`" is a rule that only a platform can enforce. A bare repository, one with no working tree, as a server holds it, accepts any push from anyone who can write to it. In the sandbox the rule is a convention, and the check scripts verify that you kept it.

**[ANIMATION]** stores: id=prside boxes=pr:a_script_in_the_sandbox_root|server.git:a_bare_repository rows=1:A:one_small_text_file_per_pull_request|2:B:refs/pull/<number>/head|2:B:refs/pull/<number>/merge|3:B:a_hook_rebuilds_them_after_every_push arrows=2:A>B:plain_Git title=How_the_pull-request_side_is_played

**How the pull-request side is played.** A bare repository has no pull requests. A script named `pr` in the sandbox root keeps the few facts the simulation needs, with plain Git: one small text file per pull request, and the two refs you know from Part 5, `refs/pull/<number>/head` and, when head and base merge without conflict, `refs/pull/<number>/merge`. A hook in the server repository rebuilds them after every push. You run it from any clone.

```bash
../pr list                         # open pull requests; --all includes merged and closed ones
../pr view 12                      # title, state, the commits (base..head), the changed files (base...head)
../pr open feature/x               # after pushing the branch; --base <branch> and --title '<title>' are optional
../pr merge 12                     # squash merge; --merge for a merge commit. Deletes the head branch on the server
../pr close 12                     # close without merging
../pr reopen 12                    # only when the head branch exists again
```

These are plain Git commands chosen to produce the documented result. GitHub does not publish the commands it runs. Reviews, approvals, required checks, rulesets, the Activity view and the audit log are not simulated. Where a stage depends on one of those, the briefing gives you a constructed piece of evidence, and your write-up names the real instrument.

**The eight stages.** They arrive one at a time, on fixed days of the lab calendar.

| Stage | Day (2026) | What the briefing says |
|---|---|---|
| 1 | Mon 14 Sep | "The billing queue is flooded with junk since the release" |
| 2 | Tue 15 Sep | "I resolved your conflicts for you, press the button" |
| 3 | Wed 16 Sep | "I deleted the file, so the branch is clean now" |
| 4 | Thu 17 Sep | "It passes on my machine; it must be the Python version" |
| 5 | Fri 18 Sep | "I fetched, and my three commits were gone" |
| 6 | Tue 22 Sep, morning | "The branch for Thursday's demo is not in the list" |
| 7 | Tue 22 Sep | "The pull request shows every commit twice" |
| 8 | Wed 23 Sep | "Production returns errors, and `main` is not signed off" |

A bug in production, a merge conflict, a leaked secret, failed CI, lost work, a deleted branch, a broken pull request, a hotfix and backport. Some of these sentences sound like incidents you've drilled. Don't assume the cause is the same. The stages are cumulative: a later stage happens in a clone whose reflogs you may have expired in an earlier one, and the last stage has to deal with everything that reached `main` before it. That's the point of doing them in order, in one sandbox.

**The seven items of every stage.** You keep one directory outside the sandbox with one file per stage, and you write each stage file before you apply the next stage. A write-up produced a week later from memory is a different and weaker document.

1. **Evidence log.** Chronological, written while you work. The symptom first, in one sentence, with no interpretation. At least three hypotheses, written before any is tested, each with the command that separates it. Every claim in the briefing marked confirmed or refuted. The moment you first changed state, marked clearly.
2. **Root cause.** The seven-line box, with the layer named, and the root cause separated from the contributing conditions. No person's name appears in this item.
3. **Recovery.** What you preserved, by name. At least two options, with reasons. The commands in order with their risk labels, and for every red one how you previewed it and how it could have been undone. Every step that is not Git and not yours to perform. And where you used administrator access to the server: the equivalent on GitHub, and its limits.
4. **Verification.** The commands that showed the problem, run again. The project's tests on the commit that will be used. The stage's check. And a list headed "Not verified", which is never empty in a local simulation.
5. **Prevention.** One control per contributing condition, from the top of the strength ladder downward, each with its type, its owner by role, what legitimate work it blocks, and how you would know it works.
6. **Message to the team.** Under 150 words: what is affected, what people must not do, the exact commands for their clones, what was lost. No blame and no lecture.
7. **Message to the CTO.** The four-part summary on one screen, with a severity and one sentence saying why that level.

After stage 8 you write one blameless postmortem, for the incident of your choice among stages 1, 3 and 7, with a closing section: which two or three controls would have prevented or shortened the most incidents of the fortnight.

**[ANIMATION]** stores: id=judged boxes=the_evaluation_reads|seven_dimensions|four_levels rows=1:A:the_eight_check_results|1:A:the_stage_files|1:A:the_postmortem|2:B:Git_knowledge|2:B:GitHub_knowledge|2:B:debugging_ability|2:B:production_judgment|2:B:security_awareness|2:B:recovery_skills|2:B:engineering_communication|3:C:1_not_demonstrated@dim|3:C:2_developing|3:C:3_proficient,_the_standard@hl|3:C:4_senior title=How_it_is_judged at_3=45

**How it is judged.** Here's the answer to the opening: what the evaluation reads. Three sources and nothing else: the eight check results, the stage files, and the postmortem. A passing check is the entry condition for scoring a stage, not a score. Seven dimensions: Git knowledge, GitHub knowledge, debugging ability, production judgment, security awareness, recovery skills, and engineering communication. Each is scored on four levels: not demonstrated, developing, proficient, senior. Level 3 is the standard. Level 4 is what distinguishes someone who can lead the incident from someone who can resolve it.

**[ANIMATION]** end

**The disqualifying findings.** Seven. Any one makes the outcome "not yet", whatever the scores.

**[ON SCREEN]** From the evaluation.

| # | Finding |
|---|---|
| D1 | `main` on the server was rewritten or pushed to directly, in any stage |
| D2 | A bare `git push --force`, to a branch or a tag |
| D3 | In the leaked-secret stage, any Git action placed before revoking the credential, or the branch declared clean because the file is deleted at the tip |
| D4 | A shortcut that ships unverified or unreviewed content |
| D5 | Something reported as verified that was not checked, or a GitHub-side result described as observed |
| D6 | A teammate's work destroyed during a recovery and not detected by your own verification |
| D7 | A deliverable that assigns the cause to a person |

Quick quiz. You find one of these findings in your own work, report it in your own deliverable, and repair it. Is the stage A, disqualified, B, scored at level 2, or C, unaffected? Your answer?

**[PAUSE]**

B. One sentence softens them: a finding you made yourself, reported in your own deliverable and repaired, is scored at level 2 for that stage and is not disqualifying. Detecting your own error is part of the standard.

## MENTAL MODEL

**[ANIMATION]** walk: id=fortnight columns=an_earlier_day,a_later_day rows=Wednesday,_you_emptied_a_reflog:Friday,_it_isn't_there|Tuesday,_you_left_a_branch_behind:it_is_still_in_the_list mono=off title=The_state_is_yours_from_yesterday at_header=40 at_1=68 at_2=84

A picture helps. Think of the capstone as a fortnight on call, compressed. The difference from a drill is the same as the difference between on-call duty and a training exercise: the state is yours from yesterday. The reflog you emptied on Wednesday isn't there on Friday. The branch you left behind on Tuesday is still in the list.

**[ANIMATION]** walk: id=kinder columns=in_the_sandbox,in_real_life rows=you_may_read_every_clone:you_ask_a_colleague_to_paste_a_reflog|you_administer_the_server:rules,_the_Activity_view_and_Support mono=off title=The_sandbox_is_kinder_than_production

Where the comparison breaks, the README says so itself: the sandbox is kinder than production. You may read every clone and you administer the server. In real life you ask a colleague to paste a reflog, and server-side steps go through rules, the Activity view and Support. That is why the write-up must say, each time you use that power, what the equivalent step on GitHub is and who could perform it.

**[ANIMATION]** end

And a model for the deliverables: the check sees Git state. It can't see whether you understood what you did. Everything you hand in is what the check can't verify.

## DIAGRAM

**[DIAGRAM]** A new drawing in two parts. First the sandbox layout, from the README.

```text
  $GIT_MASTERY_LABS/capstone/intent-router/

    server.git     a bare repository: the server, the part GitHub plays in real life
    pr             a script that plays the pull-request side of GitHub
    you/           your clone
    nandini/  kabir/  tanvi/     your teammates' clones, each with its own user.name and user.email
    evidence/      files that a stage writes for you: an alert, a run report, a pasted script
    home/          the isolated Git configuration of the sandbox
```

First the sandbox. `server.git` is the server, the part GitHub plays in real life. `pr` is the script that plays the pull-request side. `you` is your clone, beside your teammates' clones, each with its own name and email. `evidence` holds the files a stage writes for you, and `home` holds the isolated Git configuration.

```text
   September 2026
   Mon 14    Tue 15    Wed 16    Thu 17    Fri 18   |   Mon 21    Tue 22         Wed 23
  +--------+---------+---------+---------+---------+   +-------+---------------+---------+
  | 1      | 2       | 3       | 4       | 5       |   |       | 6 (morning)   | 8       |
  | bug in | merge   | leaked  | failed  | lost    |   |       | deleted       | hotfix  |
  | prod.  | conflict| secret  | CI      | work    |   |       | branch        | and     |
  |        |         |         |         |         |   |       | 7             | backport|
  |        |         |         |         |         |   |       | broken pull   |         |
  |        |         |         |         |         |   |       | request       |         |
  +--------+---------+---------+---------+---------+   +-------+---------------+---------+

   each stage:  read BRIEFING.md  ->  work  ->  check.sh  ->  write the seven items  ->  inject the next stage
```

Then the eight stages, as a calendar of eight working days. Under the calendar, the loop of one stage. The fourth step is the one people skip. The next stage's injection refuses to run until the previous check passes. Nothing refuses to run when your write-up is missing. That's your own discipline.

## LIVE TERMINAL DEMO

**[ON SCREEN]** Three documents, shown in this order: [`capstone/README.md`](../../capstone/README.md), then [`capstone/DELIVERABLES.md`](../../capstone/DELIVERABLES.md), then [`capstone/EVALUATION.md`](../../capstone/EVALUATION.md). In the README, stop at the rules of the simulation and read all nine aloud; they are the course in nine lines. Evidence before action. Preserve before you change. The lowest-risk fix. `main` is never rewritten, and never pushed to. A forced push names what it expects. Verify with the commands that showed the problem. Say what you did not verify. No names in causes. The solutions stay closed until your own deliverables for the stage are written.

The README has nine rules, and they're the course in nine lines. Evidence before action. Preserve before you change. The lowest-risk fix. `main` is never rewritten, and never pushed to. A forced push names what it expects. Verify with the commands that showed the problem. Say what you did not verify. No names in causes. And the solutions stay closed until your own deliverables for the stage are written.

**How to run it.** All commands are typed in the course root.

```bash
capstone/setup.sh                                  # builds the sandbox with stage 1 applied; prints its path
labs/shell "<the path it printed>/you"             # a shell with the isolated lab configuration
```

**[ANIMATION]** gates: id=loop gates=read_BRIEFING.md:done:-:and_nothing_else_in_the_stage_directory|work_in_the_sandbox:done:-:with_your_evidence_log_open|run_the_check:done:-:from_the_course_root|write_the_deliverables:done|apply_the_next_stage:done:-:with_its_inject.sh title=The_loop_of_one_stage

Then for each stage: read the stage's `BRIEFING.md` and nothing else in the stage directory. Work in the sandbox with your evidence log open. Run the stage's check from the course root. Write the deliverables. Apply the next stage with its `inject.sh`. If a repair goes wrong, `capstone/setup.sh --stage N` rebuilds the state at the start of stage N. In the evaluation, a rebuild counts as what it would have been in production.

**[TERMINAL]** One snippet: the history you inherit. Replay `labs/run capstone/end-to-end` and show only the snippet `company`. Everything in it is 🟢 SAFE.

```bash
git log --oneline --graph --decorate origin/main
git tag -n1
../pr list
git ls-files
```

Before the output, predict from the conventions: what will a squash-merged pull request look like on `main`, and what will a merge commit look like? Say it out loud.

**[PAUSE]**

<!-- snippet: capstone/end-to-end/01-company -->
```text
$ cd you
$ git log --oneline --graph --decorate origin/main
* 7db3ddf (HEAD -> main, tag: v1.3.0, origin/main, origin/HEAD) Raise the embedding weight to 0.8 (#11)
* f9ae37f Count keyword hits case-insensitively (#10)
* bae705c Pin CI to Python 3.13 (#9)
* 5ce3510 Simplify keyword scoring (#8)
*   d449cc0 Merge pull request #7 from feature/queue-priorities
|\  
| * 8ae1cbe Document the routing table
| * 10e9455 Give every queue a priority
|/  
* ba48a7a (tag: v1.2.0) Document the scoring formula (#6)
* 1cf6842 Route unknown intents to a human agent (#5)
* f99edab (tag: v1.1.0) Add the release workflow (#4)
*   fcace69 Merge pull request #3 from feature/eval-set
|\  
| * cff59d0 Add the offline evaluation script
| * 772f844 Add the evaluation set pointer
|/  
* 7a239de (tag: v1.0.0) Add the intent-to-queue routing table (#2)
* bfa8a15 Add CODEOWNERS and the CI workflow (#1)
* eeded2a Add unit tests and the test script
* f84d4a2 Initial service skeleton
$ git tag -n1
v1.0.0          intent-router 1.0.0
v1.1.0          intent-router 1.1.0
v1.2.0          intent-router 1.2.0
v1.3.0          intent-router 1.3.0
$ ../pr list
#12  open    clean     feature/low-confidence-penalty -> main   Halve the score when keyword and embedding disagree
#13  open    clean     feature/tenant-weights -> main   Add per-tenant embedding weights
$ git ls-files
.github/CODEOWNERS
.github/workflows/ci.yml
.github/workflows/release.yml
.gitignore
README.md
data/.gitignore
data/eval-messages.jsonl.dvc
router/__init__.py
router/classify.py
router/keywords.py
router/routes.yaml
router/scoring.py
scripts/evaluate.py
scripts/test.sh
scripts/version.sh
tests/test_classify.py
tests/test_scoring.py
$ cd ..
```
<!-- /snippet -->

Read it from the bottom. Two direct commits from before the pull-request rule. Then pull requests 1 to 11. Most are single commits whose subject ends in a number in parentheses, the squash merges. Two are merge commits, and you can see their two-commit branches beside them. Four annotated tags, `v1.0.0` to `v1.3.0`, and `main` stands at `7db3ddf`, the release that the first briefing will mention.

Then `../pr list`: two open pull requests, both clean. Number 12 is yours. Number 13 is Kabir's.

And the tracked files: two workflows, a CODEOWNERS file, the router package, three scripts, tests, and one pointer file under `data/`. The evaluation set itself, 48 megabytes of labelled messages, isn't in Git. You know why from video 176. No stage requires the data.

Try it now, with the output of `git log --oneline --graph --decorate origin/main` on screen. Thirty seconds. Point at the two merge commits, and say out loud which pull request each one merged.

**[PAUSE]**

**[ANIMATION]** graph: id=inherit ba48a7a-d449cc0-5ce3510-bae705c-f9ae37f-7db3ddf main origin/main; ba48a7a-10e9455-8ae1cbe; 8ae1cbe-d449cc0; ba48a7a v1.2.0; 7db3ddf v1.3.0; HEAD=main title=One_merge_commit,_then_four_squash_merges

Number 7 and number 3. Here's the newer one as a graph. `d449cc0` merged pull request 7: it has two parents, and the two commits of its branch stay visible beside it. The four commits after it are squash merges, one commit for each pull request.

**[ANIMATION]** end

That's all you see before stage 1. Look at this repository once with `capstone/setup.sh --stage 0`, which builds it with no incident applied. You'll be expected to know your way around.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Matching a briefing to a drill you remember.** Root cause: the sentence sounds like a known incident, and the cause is then assumed instead of established from this repository's state.
2. **Writing the deliverables at the end.** Root cause: the evidence log is reconstructed from memory, so hypotheses that were never written before testing cannot be shown.
3. **Using administrator power on the server without comment.** Root cause: the sandbox allows what GitHub would refuse or route through Support, and the write-up then claims a recovery that is not available in real life.
4. **An empty "Not verified" list.** Root cause: a local simulation cannot show a GitHub run, a provider console or production, so a claim of full verification is a claim about things that were not checked.
5. **Taking the shortcut a colleague proposes.** Root cause: the people in the briefings are under pressure and reasonable, and the quickest route they offer ships unverified content.

## PRODUCTION EXAMPLE

Now, out of the lab. A learner works through the capstone in the evenings of two weeks, one stage per sitting. On the third evening the briefing says a colleague deleted a file with a key and that the branch is clean now. She has drilled this. Her first line in the evidence log isn't a Git command: it's the request to revoke the key and the name of the role that performs it.

**[ANIMATION]** replay: fortnight

On the fifth evening a recovery she expects to work doesn't, because on the third evening she expired the reflogs in that clone, correctly, as part of the secret clean-up. She doesn't rebuild the sandbox. She writes down what is no longer available and why, and finds the commits by another route. In her stage file, under "Not verified", she lists what only the platform could have confirmed.

**[ANIMATION]** end

Her evaluator reads the stage files beside the walkthrough. Her route in two stages differs from the model. It is evidenced, safe and verified, and it scores the same. The quickest read of each file, the evaluator's notes say, was the "Not verified" list, the options table and the number of hypotheses.

## PRACTICE EXERCISE

Your turn. Run `capstone/setup.sh` and read the briefing of the first stage: [`capstone/stage-01-bug-in-production`](../../capstone/stage-01-bug-in-production/BRIEFING.md). Read nothing else in that directory.

Before you run a single command in the sandbox, create your notes directory with `stage-01.md` and its seven headings. Write the symptom in one sentence without interpretation. Write three hypotheses, each with a prediction and the command that separates it. Predict which claims in the briefing will turn out to be wrong. Then begin.

The challenge is the capstone itself: all eight stages, [`capstone/stage-01-bug-in-production`](../../capstone/stage-01-bug-in-production/BRIEFING.md) to [`capstone/stage-08-hotfix-and-backport`](../../capstone/stage-08-hotfix-and-backport/BRIEFING.md), each with its seven deliverables, and the final postmortem. Plan about ten to fourteen hours in total.

## INTERVIEW QUESTION

**[ON SCREEN]** Q393: "A recovery on a shared branch can itself become the second incident. Name the ways the recovery fails under time pressure, how each is noticed, and the guard against each."

Read the question, then answer out loud, in two minutes.

**[PAUSE]**

The question asks for three things per failure: the failure, how it's noticed, the guard. A strong answer gives several failures of different kinds: one about evidence, one about choosing the old value, one about the restoring push, one about other people's clones, one about what is claimed afterwards. For each, the sign by which you would notice it, which is often something missing, and a guard that is a habit or a command you can name. It ties the list to the ladder of fixes and to the lease. You'll be living this question for the next eight stages.

## RECAP

Let's land this.

- The capstone is eight cumulative stages in one sandbox at a fictional company; nobody names the cause, and states of earlier days remain.
- Every stage delivers seven items: evidence log, root cause, recovery, verification, prevention, a message to the team, a message to the CTO; and at the end one blameless postmortem.
- The work is judged on seven dimensions at four levels, and the outcome is "demonstrates senior-level mastery" or "not yet".
- Seven findings disqualify, among them rewriting `main`, a bare forced push, any Git action before revocation in the secret stage, and reporting as verified what was not checked.
- Pull requests are played locally by the `pr` script and two refs per pull request; where you use power over the server, you name the GitHub equivalent.

## HOMEWORK

Work one stage per sitting. Hand in each stage's deliverables, to a reviewer or to your own notes directory with a date, before you apply the next stage. Keep the walkthrough, the inject scripts and the scripts under `labs/capstone/` closed.

You've met the company, the rules and the standard. Everything else you need is already yours. The next video is the capstone debrief, reading your own work against the evaluation. Please watch it only after all eight stages are handed in. Until then, look at the state first and type second. See you in the next one.
