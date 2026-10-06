# V198: Capstone debrief: reading your own work against the evaluation

- **Part.** 10, Senior engineer: assessment
- **Module.** 41
- **Planned minutes.** 20
- **Prerequisites.** V197
- **Textbook sections.** [Chapter 29](../../textbook/ch29-production-troubleshooting.md), sections 29.2, 29.9 and 29.10; [Chapter 30](../../textbook/ch30-incident-response.md), sections 30.15, 30.19 and 30.20; [`capstone/EVALUATION.md`](../../capstone/EVALUATION.md)
- **Demo scripts.** The eight model replays `labs/capstone/stage-01-bug-in-production.sh` to `labs/capstone/stage-08-hotfix-and-backport.sh` (one or two snippets each), and `labs/capstone/end-to-end.sh` (snippets `02-stages`, `03-final-state`)

## HOOK

**[ON SCREEN]** "All eight checks pass. Am I done?"

Your eight check scripts print `PASS`. Eight stage files and a postmortem are in your notes directory. And the evaluation says, in its first section: a passing check is the entry condition for scoring a stage, not a score.

**[ANIMATION]** stores: id=saw boxes=the_check_saw|the_check_did_not_see rows=1:A:the_Git_state_you_reached@ok|2:B:whether_your_first_command_changed_anything|3:B:three_hypotheses_or_one|4:B:whether_the_forced_push_named_what_it_expected|5:B:a_claim_to_the_CTO_that_you_never_checked title=PASS_is_the_entry_condition,_not_a_score at_1=2 at_2=10 at_3=18 at_4=25 at_5=34

The check saw the Git state you reached. It didn't see whether your first command changed anything, whether you had three hypotheses or one, whether the forced push named what it expected, or whether your message to the CTO claimed something you never checked. Today you read your own work the way a reviewer would. That's harder than doing the work was. Hold on to the question on screen. You'll answer it yourself before the end.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video is watched only after all eight stages of the capstone are handed in. If a stage is still open, or its deliverables aren't written, please stop here.

**[PAUSE]**

The model replays are shown from this point on, and a retake after watching them is scored differently: the evaluation caps debugging ability for a stage at level 3 once its walkthrough has been read.

The debrief has one rule, taken from the evaluator's notes: the model solution is one route. A different route that is evidenced, safe and verified scores the same. So you don't compare your commands with the model's for sameness. You compare them for safety. For each stage I show one or two moments of the model replay, the moments on which the stage turns, and you look for the corresponding moment in your own evidence log.

Before each stage's replay you fill in your own scores for that stage. Score what you can point at.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Score your own deliverables on the seven dimensions with the four-level scale.
2. Compare your recovery path with the model path for safety, not for sameness.
3. Find the stage where your evidence log was thinnest and say what you would collect now.
4. Name the control each stage should have left behind.
5. State what you would do differently in a real incident tomorrow.

## CONCEPT

**What is evaluated.** Three sources, and nothing else: the eight check results, the stage files with their seven items each, and the final postmortem.

**The scale.** Every dimension is scored once per stage in which it applies.

**[ON SCREEN]** From the evaluation.

| Level | Name | Meaning |
|---|---|---|
| 1 | Not demonstrated | Absent, wrong, or arrived at without evidence |
| 2 | Developing | The right result with gaps: a step taken on a guess, a mechanism named and not shown, a risk not seen |
| 3 | Proficient | Correct, evidenced and safe. A senior colleague would accept the work without redoing it |
| 4 | Senior | Proficient, and in addition: the alternatives are weighed, the limits of the evidence are stated, the layer is named, and the result is turned into a control |

Level 3 is the standard. Level 4 is what distinguishes someone who can lead the incident from someone who can resolve it.

**[ANIMATION]** walk: id=dims columns=dimension,where_its_evidence_is rows=Git_knowledge:the_root-cause_item;_the_commands_in_the_evidence_log_and_the_recovery|GitHub_knowledge:the_"equivalent_on_GitHub"_notes,_the_prevention_item,_the_"Not_verified"_lists|Debugging_ability:the_evidence_log|Production_judgment:the_options_table,_your_answers_to_the_shortcuts,_the_severity|Security_awareness:the_leaked-secret_stage,_every_forced_push,_the_workflow_reading|Recovery_skills:|Engineering_communication:the_two_messages_of_every_stage_and_the_postmortem mono=off title=Seven_dimensions,_and_where_their_evidence_is

**The seven dimensions, and where their evidence is.** Git knowledge: the root-cause item of every stage and the commands in the evidence log and the recovery. GitHub knowledge: the "equivalent on GitHub" notes, the prevention item and the "Not verified" lists. Debugging ability: the evidence log. Production judgment: the options table, your answers to the shortcuts proposed in the briefings, and the severity. Security awareness: all of the leaked-secret stage, every forced push, the workflow reading. Recovery skills. Engineering communication: the two messages of every stage and the postmortem.

**[ANIMATION]** cards: id=quiz question=The_right_result,_one_hypothesis,_confirmed,_and_a_log_written_up_afterwards cards=A,_level_2|B,_level_3|C,_level_4 marks=1:ok at_1=60 at_2=70 at_3=80

**[ANIMATION]** step: 3

Quick quiz. A stage file reaches the right result with one hypothesis, confirmed, and a log written up afterwards. Is that A, level 2, B, level 3, or C, level 4? Your answer?

**[PAUSE]**

**[ANIMATION]** step: marks

**What separates level 2 from level 3, in every dimension.** The answer is A. At level 2 the result is right and something is asserted that isn't shown. At level 3 it's on the page. The evaluation's wording for debugging at level 2 is exact: one hypothesis, confirmed. The briefing's claims neither tested nor challenged. The log reconstructed afterwards.

**[ANIMATION]** cards: id=four question=Level_4,_senior cards=predicts_before_it_runs|a_second_line_of_evidence|trade-offs_on_both_sides,_where_they_are_real|states_the_limits|turns_the_result_into_a_control

**What level 4 looks like.** The write-up predicts before it runs. It gives a second line of evidence for its conclusion. It argues trade-offs on both sides where they are real. It states the limits: what a control would not have caught, what an instrument can and cannot restore. And it turns the result into a control.

**[ANIMATION]** cards: id=final numbered=on question="Demonstrates_senior-level_mastery"_requires_all_of_these cards=All_eight_checks_pass:on_a_sandbox_worked_through_in_order|No_disqualifying_finding|Every_dimension_score_is_3_or_higher:the_median_of_its_stage_levels,_rounded_down|Every_floor_is_3_or_higher:the_lowest_level_among_the_primary_stages|At_least_three_dimension_scores_are_4:with_production_judgment_or_debugging_ability|The_postmortem_is_at_level_3_or_higher:and_has_its_closing_section

**[ANIMATION]** step: 3

**The final judgment.** "Demonstrates senior-level mastery" requires all of the following. All eight checks pass, on a sandbox worked through in order. No disqualifying finding. Every dimension score is 3 or higher, where the dimension score is the median of its stage levels, rounded down. The median is the middle value when the levels are put in order.

**[ANIMATION]** step: 5

Every floor is 3 or higher, where the floor is the lowest level among the dimension's primary stages: a senior engineer doesn't have a category of incident that goes badly. At least three dimension scores are 4, and they include production judgment or debugging ability.

**[ANIMATION]** step: 6

And the postmortem is at level 3 or higher and has its closing section.

Otherwise the outcome is "not yet", and it comes with a list: each condition that failed, the stage and item where the evidence was missing, and what to restudy.

**[ANIMATION]** end

**How to score yourself.** The evaluation allows self-evaluation under one condition: you score a day after finishing, from what is on the page and not from what you remember meaning. If the evidence for a level isn't written down, the level wasn't demonstrated, however likely it is that you knew.

**[ANIMATION]** cards: id=quick question=The_quickest_read_of_a_stage_file cards=the_"Not_verified"_list|the_options_table|the_number_of_hypotheses

**The quickest read.** The evaluator's notes say where to look first in a stage file: the "Not verified" list, the options table, and the number of hypotheses. Their absence is almost always level 2.

## MENTAL MODEL

A picture helps. Think of yourself as the reviewer of a colleague's incident report, where the colleague happens to be you, a week ago. A reviewer can't ask the author what they meant. The page is all there is.

That isn't an artificial rule. It's exactly the position of the CTO who reads your summary, of the auditor who reads your postmortem a year later, and of the engineer who inherits the repository and wonders why a branch was force-pushed on a Tuesday.

Where the model breaks: a real reviewer has no stake. You do, and the pull is always upward: "I knew that, I did not write it down." The scale has an answer for that sentence. It is level 2.

**[ANIMATION]** cards: id=rope question=In_a_log,_the_rope_is cards=an_anchor_before_a_rewrite|a_lease_on_a_forced_push:it_names_the_value_the_push_expects_on_the_server|a_read-only_phase_before_the_first_change at_1=55 at_2=65 at_3=88

The second model is for the comparison with the replay: two climbers on different routes up the same face. You don't ask whether they used the same holds. You ask whether each was roped in before every exposed move. In a log, the rope is an anchor before a rewrite, a lease on a forced push, which names the value the push expects on the server, and a read-only phase before the first change.

## DIAGRAM

**[DIAGRAM]** The scoring sheet of the evaluation: eight stages against seven dimensions, to be filled in by you. P marks a primary stage for that dimension, PM the postmortem.

```text
Dimension                    Stage levels (1 to 8, P = primary, PM = postmortem)      Median   Floor (primary)
Git knowledge                1:_  2:_P 3:_  4:_  5:_P 6:_  7:_P 8:_                   ___      ___
GitHub knowledge             2:_  3:_  4:_P 6:_P 7:_  8:_                             ___      ___
Debugging ability            1:_P 2:_  4:_P 5:_  6:_P 7:_                             ___      ___
Production judgment          1:_P 3:_  4:_  7:_  8:_P                                 ___      ___
Security awareness           3:_P 4:_  7:_                                            ___      ___
Recovery skills              2:_  3:_  5:_P 6:_  7:_P 8:_                             ___      ___
Engineering communication    1:_  2:_  3:_P 4:_  5:_  6:_  7:_  8:_P PM:_P            ___      ___
```

Read the sheet by columns before you fill it in. Try it now, with the sheet on screen. Thirty seconds. Find stage 3 and stage 7 in every row. For each, count how many dimensions it feeds, and for how many it's primary. Say the numbers out loud.

**[PAUSE]**

Stage 3 feeds six dimensions and is primary for two. Stage 7 feeds all seven and is primary for two. A weak stage 3 or 7 shows up everywhere. And read the last column: the floor is why one bad day in a primary stage decides the outcome.

## LIVE TERMINAL DEMO

**[TERMINAL]** For each stage: first score it on your own sheet, then watch. Each model replay is run with `labs/run capstone/<stage name>`. I show the moment on which the stage turns and say what to look for in your own log. The commands in these snippets are from the model route; yours may differ.

Into the lab, eight times. Before each replay, score that stage on your own sheet. Do stage 1 now, and say your level for debugging ability out loud.

**[PAUSE]**

**Stage 1, a bug in production.** Primary for debugging ability and production judgment. The briefing came with a suspect and with a ready-made revert. The model's third step tests the suspect before believing it.

<!-- snippet: capstone/stage-01-bug-in-production/03-test-the-suspect -->
```text
# Hypothesis of the engineer on call: pull request #11. Her branch reverts it. Test it.
$ git log --oneline -1 origin/fix/revert-embed-weight
618ac9c Revert "Raise the embedding weight to 0.8 (#11)"
$ git switch --quiet --detach origin/fix/revert-embed-weight
$ PYTHONPATH=. python3 -B ../repro.py
routed to billing_refund
[exit status: 1]
$ git switch --quiet main
```
<!-- /snippet -->

With the proposed revert checked out, the reproduction still routes the message to the wrong queue. The hypothesis of the engineer on call is refuted with one run. Then a bisect, Git's binary search over commits, between the two releases:

<!-- snippet: capstone/stage-01-bug-in-production/05-bisect-end -->
```text
$ git bisect log
# bad: [7db3ddf2a99c3440810a0beb2bdd48d6bb0874d7] Raise the embedding weight to 0.8 (#11)
# good: [ba48a7a7ecaad16698745408b1c5c10dec7bf354] Document the scoring formula (#6)
git bisect start 'v1.3.0' 'v1.2.0'
# good: [d449cc0bc741adb5cc2b9f4db98712a8d18e26fe] Merge pull request #7 from feature/queue-priorities
git bisect good d449cc0bc741adb5cc2b9f4db98712a8d18e26fe
# bad: [bae705c121122e495e3a886870b2c223454d1e77] Pin CI to Python 3.13 (#9)
git bisect bad bae705c121122e495e3a886870b2c223454d1e77
# bad: [5ce3510e855abf419575ed46b43351cfe6455f76] Simplify keyword scoring (#8)
git bisect bad 5ce3510e855abf419575ed46b43351cfe6455f76
# first 'bad' commit: [5ce3510e855abf419575ed46b43351cfe6455f76] Simplify keyword scoring (#8)
$ git bisect reset
Previous HEAD position was 5ce3510 Simplify keyword scoring (#8)
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```
<!-- /snippet -->

The first bad commit is `5ce3510`, another pull request.

**[ANIMATION]** graph: id=bisect1 ba48a7a-d449cc0-5ce3510-bae705c-*-7db3ddf; ba48a7a v1.2.0; 7db3ddf v1.3.0; HEAD=none; good:ba48a7a; bad:7db3ddf; cmd:git_bisect_start_v1.3.0_v1.2.0 => + good:d449cc0 => + bad:bae705c => + bad:5ce3510; first_bad:5ce3510; say:The_first_bad_commit_is_another_pull_request title=Both_known_ends,_then_the_halving

Look in your own log for two things. Did you prove your reproduction on both known ends, the good release and the bad one, before you relied on it? And did you test the claim in the briefing, or act on it? Merging the speculative revert is one of the shortcuts the evaluation lists as disqualifying.

**[ANIMATION]** end

**Stage 2, a merge conflict.** Primary for Git knowledge. A colleague had resolved "your conflicts" and the pull request said clean.

<!-- snippet: capstone/stage-02-merge-conflict/03-what-the-merge-did -->
```text
# A merge commit records a result. --remerge-diff repeats the merge and shows what the
# person who resolved it changed, compared with what Git produced on its own.
$ git show --remerge-diff --format='%h %an: %s' origin/feature/low-confidence-penalty -- router/scoring.py
4870ce0 Kabir Sethi: Merge remote-tracking branch 'origin/main' into feature/low-confidence-penalty

diff --git a/router/scoring.py b/router/scoring.py
remerge CONFLICT (content): Merge conflict in router/scoring.py
index c593ac8..bc421cb 100644
--- a/router/scoring.py
+++ b/router/scoring.py
@@ -1,21 +1,10 @@
 """Blend the keyword score and the embedding score of one candidate intent."""
 
 EMBED_WEIGHT = 0.8
-<<<<<<< a7a411b (Halve the score when keyword and embedding disagree)
-DISAGREEMENT = 0.6
-=======
 TENANT_EMBED_WEIGHT = {"acme-retail": 0.6}
->>>>>>> 95f8c85 (Add per-tenant embedding weights (#13))
 
 
 def blend(keyword_score, embed_score, tenant=None):
     """Both inputs are in [0, 1]; so is the result."""
-<<<<<<< a7a411b (Halve the score when keyword and embedding disagree)
-    score = (1 - EMBED_WEIGHT) * keyword_score + EMBED_WEIGHT * embed_score
-    if abs(keyword_score - embed_score) > DISAGREEMENT:
-        score *= 0.5  # the two signals disagree: trust neither
-    return score
-=======
     weight = TENANT_EMBED_WEIGHT.get(tenant, EMBED_WEIGHT)
     return (1 - weight) * keyword_score + weight * embed_score
->>>>>>> 95f8c85 (Add per-tenant embedding weights (#13))
```
<!-- /snippet -->

`git show --remerge-diff` on the merge that the colleague made. That option repeats the merge and shows what the person who resolved it changed. Both conflict regions were resolved for one side, and the lines of your own change are the ones removed. You've seen this shape in Incident 9. In your log: how did you find out what the merge did? A level 3 answer shows the state, with this command or another that proves the same thing. A level 2 answer says "the merge was wrong" and redoes it.

**Stage 3, a leaked secret.** Primary for security awareness and engineering communication.

<!-- snippet: capstone/stage-03-leaked-secret/03-not-clean -->
```text
# The tip has no such file. The history under the tip has, and a squash merge of the pull
# request would not change that: the pull request ref keeps the original commits.
$ git cat-file -e origin/feature/embedding-client:deploy/staging.env
fatal: path 'deploy/staging.env' does not exist in 'origin/feature/embedding-client'
[exit status: 128]
$ git log --oneline origin/main..refs/remotes/origin/feature/embedding-client
014b193 Retry the embedding call once on timeout
415fe84 Remove the staging env file
2b9051b Cache embeddings by message hash
c354cbf Add the embedding service client
$ git ls-remote origin refs/pull/16/head
014b19352ef2285b6cf698b146f932c0e960e645	refs/pull/16/head
```
<!-- /snippet -->

The tip has no such file. The history under the tip has, and the pull request ref keeps the original commits: a squash merge wouldn't change that. In your stage file, check the order first: is the first action the revocation, stated with its reason, before any Git command? Then the scope: did you list every ref in every repository that reached the file, including the pull request ref and anything else that named those commits? And one more line of the evaluation: the dummy secret isn't copied into the deliverables.

**Stage 4, failed CI.** Primary for GitHub knowledge and debugging ability. "It passes on my machine; it must be the Python version."

<!-- snippet: capstone/stage-04-failed-ci/04-which-commit -->
```text
# Which commit did the run test? The report names it. Compare it with the branch:
$ git rev-parse origin/feature/batch-endpoint
58931e96232e182cdb0a5a955ae24f8f975bc9e1
$ git ls-remote origin 'refs/pull/17/*'
58931e96232e182cdb0a5a955ae24f8f975bc9e1	refs/pull/17/head
530a3b37db24b6bd8b28e19f42323c273dd6b017	refs/pull/17/merge
```
<!-- /snippet -->

Which commit did the run test? The pull request has two refs, and they hold different IDs: the head, and the test merge, the commit that merges the head into the current base.

<!-- snippet: capstone/stage-04-failed-ci/05-reproduce -->
```text
# The runner fetched refs/pull/N/merge. So can I:
$ git fetch origin refs/pull/17/merge
From ../server
 * branch            refs/pull/17/merge -> FETCH_HEAD
$ git log -1 --format='%h %an: %s%nparents: %p' FETCH_HEAD
530a3b3 GitHub: Merge 58931e96232e182cdb0a5a955ae24f8f975bc9e1 into 3c4f762348eeaf0524415753aa0e013cc9961fd2
parents: 3c4f762 58931e9
$ git switch --quiet --detach FETCH_HEAD
$ bash scripts/test.sh
ERROR: test_batch
FAILED
[exit status: 1]
$ PYTHONPATH=. python3 -B -c "import router.batch" 2>&1 | tail -n 1 | cut -d"(" -f1
ImportError: cannot import name 'FALLBACK' from 'router.classify' 
```
<!-- /snippet -->

The model fetches the merge ref and runs the tests on it. They fail locally, with a message that names a symbol another pull request changed on `main`.

**[ANIMATION]** graph: id=pull17 ...-3c4f762-530a3b3 special:refs/pull/17/merge; ^...older-58931e9-530a3b3; 58931e9 special:refs/pull/17/head; HEAD=none; note:3c4f762:the_current_base => + pass:58931e9; fail:530a3b3; say:The_head_passes,_the_test_merge_does_not title=One_pull_request,_two_refs dx=300

Both statements of the briefing were true: the head passes, the merge doesn't. In your log: did you answer the first questions of the investigation order on paper, workflow, event, commit checked out, before you reproduced anything? And in your "Not verified" list: did you write what a local reproduction doesn't prove?

**[ANIMATION]** end

**Stage 5, lost work.** Primary for Git knowledge and recovery skills.

<!-- snippet: capstone/stage-05-lost-work/07-not-recoverable -->
```text
# Two things were never given to Git: an edit to README.md that was not staged, and
# the notes file that was never added. Git has no object for either.
$ ls notes
ls: notes: No such file or directory
[exit status: 1]
$ git diff --stat HEAD -- README.md
$ git log --all --oneline -S'histogram of blended scores'
```
<!-- /snippet -->

This is the model stating what is gone: an unstaged edit and a file that was never added. Git has no object for either, and three commands show it. The stage's deliverable asks for a two-column list. Recovered, with the mechanism that kept it. Not recoverable, with the reason Git has no copy. Check that your list has the second column, and that your message to the colleague says it plainly.

**Stage 6, a deleted branch.** Primary for GitHub knowledge and debugging ability.

<!-- snippet: capstone/stage-06-deleted-branch/02-what-the-clones-have -->
```text
# My clone has a remote-tracking branch from my last fetch. I do not fetch with --prune
# now: that would delete the one copy of the name I have.
$ git log --oneline origin/main..origin/feature/multilingual-intents
3167a88 Add Tamil keyword lists
dcdc06b Add Hindi keyword lists
# Nandini saw three commits in the pull request. This is two.
$ git -C ../tanvi branch -r --list 'origin/feature/*'
  origin/feature/embedding-latency-log
  origin/feature/routing-metrics
$ git -C ../nandini branch -r --list 'origin/feature/*'
  origin/feature/batch-endpoint
  origin/feature/embedding-latency-log
```
<!-- /snippet -->

The model looks at what each clone still has, and deliberately doesn't fetch with pruning: that would delete the one copy of the name it has. Its own remote-tracking branch, its record of the server's branch, shows two commits. The tech lead had seen three.

<!-- snippet: capstone/stage-06-deleted-branch/05-find-the-tip -->
```text
$ git ls-remote origin 'refs/pull/21/*'
d3ed8df5df48877a2f9d1b06da1e3042d8f30323	refs/pull/21/head
$ git fetch origin refs/pull/21/head
From ../server
 * branch            refs/pull/21/head -> FETCH_HEAD
$ git log --oneline origin/main..FETCH_HEAD
d3ed8df Pick the keyword lists by detected language
3167a88 Add Tamil keyword lists
dcdc06b Add Hindi keyword lists
$ git log --oneline origin/feature/multilingual-intents..FETCH_HEAD
d3ed8df Pick the keyword lists by detected language
```
<!-- /snippet -->

The pull request ref holds a third commit, `d3ed8df`, that no clone's branch had. The model restores from there.

**[ANIMATION]** graph: id=pull21 ...-dcdc06b-3167a88-d3ed8df special:refs/pull/21/head; 3167a88 origin/feature/multilingual-intents; HEAD=none; note:d3ed8df:no_clone's_branch_had_it title=The_copies_that_existed dx=300

You may have found the tip elsewhere, and that scores the same if it is evidenced. What the deliverable asks is the list of copies that existed, per repository, each with its commit, which one you used and why, and the GitHub instrument that corresponds to your recovery, with its limit.

**[ANIMATION]** end

**Stage 7, a broken pull request.** Primary for Git knowledge and recovery skills. This is the senior standard of video 188 with three people instead of two.

<!-- snippet: capstone/stage-07-broken-pull-request/10-check-result -->
```text
$ git range-diff 9d7793f..rescue/my-work 362bf08..feature/vip-escalation~1
1:  1d05422 = 1:  ee6e113 Test the VIP escalation
2:  8bd0113 = 2:  91a0fc1 Escalate VIP messages without any intent as well
$ git range-diff fa2c06d~1..fa2c06d feature/vip-escalation~1..feature/vip-escalation
1:  fa2c06d = 1:  66dc07e Document the VIP escalation
# Content: the new tip must equal what a merge of the server state and my work would give.
$ git merge-tree --write-tree rescue/server-state rescue/my-work
ed2b2114d5a3b9fd71b387ff653b4be9c24c7d06
$ git rev-parse 'feature/vip-escalation^{tree}'
ed2b2114d5a3b9fd71b387ff653b4be9c24c7d06
$ bash scripts/test.sh
OK
```
<!-- /snippet -->

Before publishing, the model proves two things. Every replayed commit pairs with its original under `git range-diff`, which compares two versions of a series of commits. And the tree of the rebuilt branch equals the tree that a merge of the server's state and your own work would give: two equal IDs, and the tests pass on it. In your stage file: is there one line for each of the eleven steps? Is the proof that the repair changed no content made before the push? And does your forced push name what it expects? A bare `--force` here is a disqualifying finding.

**Stage 8, a hotfix and backport.** Primary for production judgment and engineering communication. The proposal in the briefing was to merge the fix and tag `main`.

<!-- snippet: capstone/stage-08-hotfix-and-backport/03-why-not-main -->
```text
# The proposal is to merge the fix and tag main. What would that release?
$ git diff --shortstat v1.3.1 origin/main
 15 files changed, 149 insertions(+), 9 deletions(-)
$ git diff --stat v1.3.1 origin/main -- router | tail -n 12
 router/batch.py        | 10 ++++++++++
 router/classify.py     | 14 ++++++++++----
 router/embed_cache.py  | 13 +++++++++++++
 router/embed_client.py | 20 ++++++++++++++++++++
 router/lang.py         |  8 ++++++++
 router/scoring.py      | 10 ++++++++--
 router/vip.py          | 14 ++++++++++++++
 7 files changed, 83 insertions(+), 6 deletions(-)
```
<!-- /snippet -->

What would that release? Fifteen files differ between the last release and `main`, seven of them in the router package. A patch release tagged on `main` would ship all of it. That's video 172 as a decision under pressure.

<!-- snippet: capstone/stage-08-hotfix-and-backport/10-compare -->
```text
# The backport next to the original. By default range-diff does not pair two commits
# whose diffs differ this much; --creation-factor=100 makes it pair them and show how.
$ git range-diff b360489~1..b360489 HEAD~1..HEAD
1:  b360489 < -:  ------- Treat a missing embedding score as 0 (#24)
-:  ------- > 1:  6e291e5 Treat a missing embedding score as 0 (#24)
$ git range-diff --creation-factor=100 b360489~1..b360489 HEAD~1..HEAD
1:  b360489 ! 1:  6e291e5 Treat a missing embedding score as 0 (#24)
    @@ Metadata
      ## Commit message ##
         Treat a missing embedding score as 0 (#24)
     
    +    (cherry picked from commit b3604896a20d1db6d1ed9f4d4dc90a418c0673b5)
    +
      ## router/classify.py ##
    -@@ router/classify.py: def classify(candidates, tenant=None):
    +@@ router/classify.py: def classify(candidates):
          """candidates: (intent, keyword_score, embed_score) tuples. Returns the intent to route to."""
    -     best, best_score = fallback_for(tenant), THRESHOLD
    +     best, best_score = FALLBACK, THRESHOLD
          for intent, kw, emb in candidates:
     +        if emb is None:
     +            emb = 0.0  # the embedding service timed out: decide on the keywords alone
    -         score = blend(kw, emb, tenant)
    +         score = blend(kw, emb)
              if score > best_score:
                  best, best_score = intent, score
     
      ## tests/test_classify.py ##
     @@ tests/test_classify.py: class ClassifyTest(unittest.TestCase):
    -     def test_a_tenant_can_have_its_own_fallback(self):
    -         self.assertEqual(fallback_for("acme-retail"), "store_support")
    -         self.assertEqual(classify([("billing_refund", 0.2, 0.1)], "acme-retail"), "store_support")
    + 
    +     def test_weak_evidence_goes_to_a_human(self):
    +         self.assertEqual(classify([("billing_refund", 0.2, 0.1)]), FALLBACK)
     +
     +    def test_a_missing_embedding_score_counts_as_zero(self):
     +        self.assertEqual(classify([("billing_refund", 1.0, None)]), "human_agent")
```
<!-- /snippet -->

The backport, the copy of the fix on the maintenance line, next to the original. The port needed adaptation to the older code, so by default the comparison doesn't pair the two commits at all. Made to pair them, it shows what was adapted and the "cherry picked from" line. The evaluation's level 4 for Git knowledge names this: the write-up predicts why a patch comparison misreports the backport. Check your stage file for the three answers it asks. What exactly the patch release contains, as a diff summary. Whether it's a regression. And the command by which someone verifies next month that the fix is on `main`.

**[TERMINAL]** Close with `labs/run capstone/end-to-end`: all eight stages in one sandbox.

<!-- snippet: capstone/end-to-end/02-stages -->
```text
stage 1  bug-in-production          check before the solution: NOT YET  after: PASS
stage 2  merge-conflict             check before the solution: NOT YET  after: PASS
stage 3  leaked-secret              check before the solution: NOT YET  after: PASS
stage 4  failed-ci                  check before the solution: NOT YET  after: PASS
stage 5  lost-work                  check before the solution: NOT YET  after: PASS
stage 6  deleted-branch             check before the solution: NOT YET  after: PASS
stage 7  broken-pull-request        check before the solution: NOT YET  after: PASS
stage 8  hotfix-and-backport        check before the solution: NOT YET  after: PASS
```
<!-- /snippet -->

Each check fails before its solution and passes after it. That's the entry condition, eight times. And it answers the question from the opening. Eight passing checks don't mean you're done. They mean your work may now be scored.

<!-- snippet: capstone/end-to-end/03-final-state -->
```text
$ cd you
$ git fetch --quiet --prune
$ git log --oneline --graph --first-parent --decorate v1.3.0..origin/main
* b360489 (HEAD -> main, origin/main, origin/HEAD) Treat a missing embedding score as 0 (#24)
* c99b5eb Merge pull request #22 from feature/vip-escalation
* 52620f1 Give the CI job 15 minutes (#23)
* 2fe3b1c Merge pull request #20 from feature/multilingual-intents
* 1876f06 Document the batch entry point (#19)
* 1b63d64 Add batch classification (#17)
* 3c4f762 Make the fallback intent configurable per tenant (#18)
* d71e996 Add the embedding service client (#16)
* e3e624d Halve the score when keyword and embedding disagree (#12)
* 95f8c85 Add per-tenant embedding weights (#13)
* 47fb459 (tag: v1.3.1) Merge pull request #15 from fix/keyword-score-cap
$ git log --oneline --decorate v1.3.1..origin/release/1.3
36e9769 (tag: v1.3.2, origin/release/1.3, release/1.3) Treat a missing embedding score as 0 (#24) (#25)
$ ../pr list --all | tail -n 12
#14  closed  -         fix/revert-embed-weight -> main   Revert "Raise the embedding weight to 0.8 (#11)"
#15  merged  -         fix/keyword-score-cap -> main   Restore the cap on the keyword score
#16  merged  -         feature/embedding-client -> main   Add the embedding service client
#17  merged  -         feature/batch-endpoint -> main   Add batch classification
#18  merged  -         feature/tenant-fallback -> main   Make the fallback intent configurable per tenant
#19  merged  -         docs/batch -> main   Document the batch entry point
#20  merged  -         feature/multilingual-intents -> main   Language detection groundwork
#21  open    clean     feature/multilingual-intents -> main   Hindi and Tamil intents
#22  merged  -         feature/vip-escalation -> main   Escalate VIP customers
#23  merged  -         chore/ci-timeout -> main   Give the CI job 15 minutes
#24  merged  -         hotfix/embed-none -> main   Treat a missing embedding score as 0
#25  merged  -         backport/embed-none-1.3 -> release/1.3   Treat a missing embedding score as 0 (#24)
$ git tag -n1
staging/2026-09-16 Cache embeddings by message hash
v1.0.0          intent-router 1.0.0
v1.1.0          intent-router 1.1.0
v1.2.0          intent-router 1.2.0
v1.3.0          intent-router 1.3.0
v1.3.1          intent-router 1.3.1: restore the cap on the keyword score
v1.3.2          intent-router 1.3.2: treat a missing embedding score as 0
```
<!-- /snippet -->

The first-parent history of `main` after the fortnight, the line you get by following only the first parent of each merge: every line is a pull request, squash or merge, and nothing was pushed to it directly. The maintenance line `release/1.3` carries one commit, tagged `v1.3.2`. Compare with your own sandbox: `git log --first-parent` on `main`. Your IDs differ for the commits you made. The shape shouldn't surprise you.

Now complete the sheet: medians, rounded down, and floors. Stop the video while you do, and say your outcome out loud.

**[PAUSE]**

**[ANIMATION]** cards: id=three numbered=on question=Three_questions,_in_writing cards=In_which_stage_was_your_evidence_log_thinnest?:and_what_would_you_collect_now?|Which_control_should_each_stage_have_left_behind?:and_on_which_layer?|What_would_you_do_differently_in_a_real_incident_tomorrow?

Then answer three questions in writing. In which stage was your evidence log thinnest, and what would you collect now? Which control should each stage have left behind, and on which layer? And what would you do differently in a real incident tomorrow?

## COMMON MISTAKES

Five mistakes to watch for.

1. **Scoring from memory.** Root cause: you remember what you understood, and the evaluator can score only what the page shows.
2. **Comparing commands instead of safety.** Root cause: the model solution is one route, and a different route that is evidenced, safe and verified scores the same.
3. **Treating `PASS` as a score.** Root cause: the check verifies Git state only; hypotheses, options, leases, messages and what was not verified are invisible to it.
4. **Hiding your own error.** Root cause: a mistake you report and repair in your own deliverable scores level 2 for that stage; the same mistake found by the evaluator can disqualify.
5. **Averaging a bad stage away.** Root cause: the floor is the lowest level among a dimension's primary stages, so one primary stage below level 3 decides the outcome.

## PRODUCTION EXAMPLE

Now, out of the lab. A learner scores her capstone a day after finishing. Her checks all pass. Her first pass over the sheet gives her threes and fours.

**[ANIMATION]** replay: quick

Then she applies the quickest read to her own files. In stage 4 her "Not verified" list is empty. In stage 6 she has one hypothesis, confirmed. In stage 7 her forced push is written with a lease and with `--force-if-includes`, on a branch she had examined a moment before, which the rules of the simulation accept. But the proof that the repair changed no content comes after the push in her log, not before. She corrects three scores downward. Debugging ability now has a floor of 2, because stage 6 is a primary stage for it.

**[ANIMATION]** end

The outcome on her own sheet is "not yet", with a list. Debugging ability, stage 6. Restudy the method chapter and the history-investigation sections the evaluation names. Two incidents she hasn't done. Then retake the stage in a rebuilt sandbox with new deliverables. She does that in a week. Her note on the retake says what changed: three hypotheses were on the page before the first test, and one of them, the one she had thought unlikely, was the cause.

## PRACTICE EXERCISE

Your turn. Fill in the scoring sheet of [`capstone/EVALUATION.md`](../../capstone/EVALUATION.md) for your own work, stage by stage, before you watch each stage's replay in this video.

For each cell, predict the level before you open your stage file. Then open the file and point at the evidence for that level. If you can't point at it, lower the level. After each replay, write one line: where your path differed from the model's, and whether your path was as safe, with the reason. Compute medians and floors, and apply the six conditions of the final judgment.

The challenge: rewrite the weakest of your eight CTO messages so that it meets section 30.15, and the final postmortem so that it meets section 30.19. Apply the test: replace every name by a role.

## INTERVIEW QUESTION

**[ON SCREEN]** Q480: "Several incidents in this course trace back to a default. Name three, give the layer of each, and say whether you would change the default or add a control around it."

Read the question, then answer out loud, in two minutes.

**[PAUSE]**

The question has a fixed form: three defaults, and for each a layer and a decision. A strong answer picks three from different layers, so that the answer covers a Git client default, a platform default and a pipeline default, and names each default precisely. For each it says why the default is reasonable in general, which is what makes it a default, and what went wrong in the incident. Then the decision, with its reason: where changing the default is enough, where it's too weak because it lives in one clone, and where the right answer is a control on a stronger layer. End on the limit of that control.

## RECAP

Let's land this.

- The capstone is judged from three sources: the eight checks, the stage files and the postmortem; a passing check is an entry condition, not a score.
- Each dimension is scored per stage on four levels; level 3 means correct, evidenced and safe, and level 4 adds weighed alternatives, stated limits, the layer and a control.
- The outcome needs every dimension score and every floor at 3 or higher, at least three dimensions at 4 including production judgment or debugging ability, and no disqualifying finding.
- A different route that is evidenced, safe and verified scores the same as the model route.
- You score from the page: what is not written down was not demonstrated.

## HOMEWORK

Enter what the capstone showed in the weak-area tracker of section 12 of the roadmap, [`curriculum/Git and GitHub mastery roadmap.md`](../../curriculum/Git%20and%20GitHub%20mastery%20roadmap.md), and plan the restudy with [`revision/revision-checklist.md`](../../revision/revision-checklist.md). If your own sheet says "not yet", take the restudy the evaluation names for the dimension that fell short, and retake that stage in a rebuilt sandbox. Part 11, the last part, looks ahead: where Git is going, and how to read its primary sources without a course.

Today you read your own work the way a reviewer reads it, and that's a skill few engineers ever practise. Whatever your sheet says, you now know exactly what to do next. Next time: the road to Git 3.0, with its planned defaults and removals. Until then, look at the state first and type second. See you in the next one.
