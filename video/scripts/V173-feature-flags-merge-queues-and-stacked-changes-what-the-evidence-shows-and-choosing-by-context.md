# V173: Feature flags, merge queues and stacked changes, what the evidence shows, and choosing by context

- **Part.** 8, Professional practice
- **Module.** 32
- **Planned minutes.** 20
- **Prerequisites.** V126, V129, V172
- **Textbook sections.** [Chapter 27](../../textbook/ch27-open-source-team-workflows.md), sections 27.11 to 27.14
- **Demo scripts.** `labs/ch27/lab-32-1-two-strategies.sh` (snippets `04-flow-result`, `07-rb-result`, `08-compare`)

## HOOK

**[ON SCREEN]** "Somebody on the team says the research proves trunk-based development is best. Does it?"

The sentence is said in a planning meeting, with confidence, and a reorganization of the team's workflow is about to be decided on it. If you agree, you have endorsed a claim the research doesn't make. If you answer "that is only a survey", you have dismissed evidence that does say something useful.

The honest answer has three parts: what was measured, how, and what it doesn't show. And it ends with a variable the team can act on. Keep that variable in mind. You'll have it word for word before the end.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. One reminder first: a branch is a named line of work, and a merge brings one line into another. Video 171 described the models and video 172 ran two of them. Two questions are left. First: what do teams use so that one long-lived branch stays workable, when features take weeks and many people merge every day? That's feature flags, merge queues and stacked changes. You met the queue in video 129 and the stack in video 126 as GitHub mechanisms. Here they're placed in the strategy discussion. Second: how do you choose, and what may you claim when you recommend?

This video has no new commands. Its terminal segment is short and has one purpose: to show the kind of evidence a recommendation can point at. The rest is a decision table, used live on one described team.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Explain what a feature flag separates and what it costs.
2. Say what a merge queue guarantees that "require branches to be up to date" does not.
3. State what the DORA research shows about trunk-based development, how it was measured, and what it does not show.
4. Recommend a workflow for a described team and state the evidence for and against.
5. Say it to a CTO in four sentences.

## CONCEPT

**Feature flags.** A feature flag is a condition in the code that keeps unfinished or unreleased behavior switched off, so that the code can be merged long before the feature is released.

**[ANIMATION]** graph: [Long-lived branch] *1-*2-*3-*4-*5-*6-M main; *1-*7-*8-*9-*10-*11-*12-M; HEAD=none; note:*10:feature/batch-api:_3_weeks,_one_big_merge || [Behind a flag] *1-b1-*2-b2-*3-b3-*4 main; HEAD=none; note:b2:b1_to_b3:_small_merged_pieces,_switched_off_until_release layout=rows id=flag dy=90

A flag replaces a long-lived branch with a short-lived condition. Instead of keeping `feature/batch-api` unmerged for three weeks, you merge it in small pieces behind `if flags.enabled("batch_api")`, and `main` contains the code from the first day. In other words, a flag separates deployment from release. Deployment is the code reaching production. Release is the behavior being switched on for users.

**[ANIMATION]** cards: question=Pete_Hodgson's_taxonomy_of_feature_toggles cards=release_toggles:ship_incomplete_code_dark|experiment_toggles|ops_toggles|permission_toggles at_2=30 at_3=38 at_4=46

Pete Hodgson's taxonomy distinguishes release toggles, which ship incomplete code dark, experiment toggles, ops toggles and permission toggles. They differ in how long they live and how dynamically they change. And the taxonomy names the cost: added complexity, combinations to test, and "toggle debt" when flags aren't removed. Microsoft describes flags as what lets its developers avoid long-running feature branches and separate deployment from exposure.

**[ANIMATION]** end

Remember the "extra failure mode" of GitHub Flow in video 172's table: a half-finished feature on `main` blocks an urgent release. A flag is what removes it. A half-finished feature on `main` doesn't block a release if it's dark.

**[ANIMATION]** cards: question=When_not_to_use_a_flag cards=Unfinished_code_ships_inside_the_product:Fowler's_caveat:_it_demands_strong_automated_tests|A_change_that_cannot_be_made_conditional:a_schema_migration,_a_dependency_upgrade|A_flag_that_guards_a_security_boundary:must_fail_closed|A_flag_is_configuration:version_control,_or_a_system_with_its_own_audit_trail

**When not to use one.** Fowler's caveat is that with flags the unfinished code ships inside the product, so the approach demands strong automated tests to keep the main line healthy. A flag is the wrong tool for a change that can't be made conditional, such as a schema migration or a dependency upgrade. A flag that guards a security boundary must fail closed. And a flag is configuration: configuration that changes behavior belongs in version control or in a system with its own audit trail.

**[ANIMATION]** graph: A-B main; ^B-?change_1; B-?change_2; HEAD=none; pass:?change_1; pass:?change_2; say:Each_passed_its_checks_against_an_older_main; name:apart => + B-?main_with_change_1-?main_with_changes_1_and_2; pass:?main_with_change_1; pass:?main_with_changes_1_and_2; say:The_queue_runs_the_checks_on_temporary_branches,_in_order; name:queue => + ?main_with_changes_1_and_2 main; say:What_is_merged_was_tested_in_the_combination_in_which_it_lands; name:lands title=A_merge_queue dx=330 id=queue at_apart=25

**[ANIMATION]** step: queue.apart

**Merge queues.** A pull request is GitHub's object for proposing a merge, and its checks are the automated tests that run on it. Two pull requests can each pass their checks against an older `main` and break `main` together. Requiring every branch to be up to date before merging fixes that, and creates a race, because every merge makes every other pull request stale.

**[ANIMATION]** step: queue.lands

A merge queue runs the required checks on temporary branches that contain the base plus the queued changes, in order, and merges what passes. That's the guarantee the up-to-date rule doesn't give without the race: what is merged was tested in the combination in which it lands. On GitHub those checks run on the `merge_group` event, and the merge method is fixed by the queue instead of being chosen per pull request.

**[ANIMATION]** cards: question=The_published_experience_comes_from_large_repositories cards=GitHub_reports:average_wait_to_ship_down_33_percent|Shopify_described:CI_on_a_predicted_post-merge_branch;_failures_ejected|Five_pull_requests_a_day:the_correctness_guarantee_and_little_else

The published experience comes from large repositories. GitHub reports about 2,500 pull requests a month from more than 500 engineers landing through its own queue, with the average wait to ship down 33 percent. Shopify described running CI on a predicted post-merge branch and ejecting failures to keep its main branch green. Those numbers describe those companies. A team that merges five pull requests a day gets the correctness guarantee and little else.

**[ANIMATION]** graph: *1 main; *1-a1-a2 pr/1-schema; a2-b1 pr/2-endpoint; b1-c1-c2 pr/3-client; HEAD=none; note:a2:base:_main; note:b1:base:_pr/1-schema; note:c2:base:_pr/2-endpoint title=A_stack_of_three_pull_requests id=stack dy=110 at_state_1=15

**Stacked changes.** A stack is a chain of small changes, each reviewed separately and each based on the one below. The practice comes from tools with per-commit review, such as Phabricator at Facebook and chained changelists at Google. The stated benefits are an unblocked author and small reviews. The stated costs are the rebasing skill and tooling it needs, and little gain for a small team. GitHub's native stacked pull requests have been in public preview since the thirtieth of July 2026.

**[ANIMATION]** end

Neither a queue nor a stack is a branching strategy. A merge queue makes any model with pre-merge checks safer at volume, and stacks make short-lived branches practical for a change too large for one review.

**What the evidence shows.** The research associates short-lived branches and small batches with better delivery performance. It doesn't rank named workflows, and it doesn't establish cause.

**[ANIMATION]** cards: question=DORA,_research_of_2016_and_2017:_higher_delivery_performance_is_associated_with cards=three_or_fewer_active_branches|merging_to_trunk_at_least_daily|no_code_freezes_or_integration_phases at_1=45 at_2=55 at_3=62

DORA is a research programme on software delivery, and its findings come from surveys. DORA defines trunk-based development as each developer dividing work into small batches and merging into the trunk at least once a day. Its capability page reports, from research conducted in 2016 and 2017, that higher delivery performance is associated with three or fewer active branches, merging to trunk at least daily, and no code freezes or integration phases. It lists heavyweight, slow code review and skipping automated tests before commit as pitfalls. A companion capability says that working in small batches predicts delivery and organizational performance.

**[ON SCREEN]** What that evidence is: the table of section 27.13.

| Property of the evidence | Consequence for how you may cite it |
|---|---|
| Survey-based: respondents describe their own practices and outcomes | it measures reported practice, not observed repositories |
| Correlational | "is associated with" and "predicts", in the statistical sense the authors use; not "causes" |
| Expressed in branch lifetime, number of active branches and batch size | it says nothing about "Git Flow" or "GitHub Flow" by name; a GitHub Flow team with one-day branches satisfies it, and a nominally trunk-based team with week-long branches does not |
| The branch findings date from 2016 and 2017 | later reports were not read for this course: the research notes record that the 2024 and 2025 report PDFs were not read and that no numeric effect sizes were captured |

Read the left column: survey-based, correlational, expressed in branch lifetime and batch size, and dating from 2016 and 2017.

**[ON SCREEN]** Unverified.

Any specific number for how much trunk-based development improves delivery performance. The notes behind this course contain none, and you shouldn't quote one from memory.

Quick quiz. The research says "is associated with". Which sentence may you say in the meeting? A, trunk-based development causes better delivery. B, teams that report short-lived branches and small batches also report better delivery performance. C, Git Flow performs worst. Your answer?

**[PAUSE]**

B. Sentence A claims a cause, and the research is correlational. Sentence C names a workflow, and the research ranks none.

**[ANIMATION]** cards: question=What_other_sources_add cards=Fowler:real_advantages_of_feature_branching|A_2025_study_of_Brazilian_developers:one_study_of_one_population|Company_case_studies:very_large_investments_in_CI,_flags_and_tooling|DORA's_recent_reports:AI_as_an_amplifier;_small_batches_still_matter

**What other sources add.** Fowler, who accepts this research, still lists real advantages of feature branching: a feature can be assessed as a unit, code enters the product only when complete, and it suits teams that can't yet keep a main line healthy and open-source projects with occasional contributors who aren't yet trusted. An interview-and-survey study of Brazilian developers published in 2025 concludes that trunk-based workflows suit fast-paced projects with experienced, smaller teams, and branch-based workflows suit less experienced and larger teams despite their management overhead. It's one study of one population. The company case studies come from organizations with very large investments in CI, flags and tooling, and Google and Meta don't use stock Git for their main repositories, so they support the principle more than any Git command sequence. DORA's recent reports describe AI as an amplifier of an organization's existing strengths and weaknesses, and keep small batches and version control among the capabilities that matter.

**[ANIMATION]** end

**How to say it to a CTO.** The textbook's wording: "The research does not prove that trunk-based development is best. It shows that teams reporting short-lived branches and small batches also report better delivery performance. The variable we can act on is how long our branches live and how large our changes are, under whatever name we give the model." There's the variable from the opening: branch lifetime and change size.

**Choosing by context.** No strategy is best. The reputable sources tie the choice to context, and two questions come before all others: how many versions are live at once, and how often do you release.

Try it now, on paper, for thirty seconds. Think of a project you know, and write two answers. How many versions are live at once? How often do you release? I'll wait.

**[PAUSE]**

Keep that paper. Those two answers choose your first rows in the decision table that is coming up, and more than one row is normal.

## MENTAL MODEL

Three pictures, one for each topic. For flags, the textbook's analogy is a new wing of a building, built and inspected behind a locked door: part of the building from day one, open to the public later. The analogy breaks because both sides of the door run in the same production process, so a mistake behind the door can still bring the building down.

**[ANIMATION]** walk: columns=rung,what_the_source_lets_you_say rows=lowest:these_companies_describe_doing_this|above_it:teams_that_report_this_practice_also_report_that_outcome|top:this_practice_causes_that_outcome,_by_this_much marks=3.2:bad,2.2:ok mono=off title=A_ladder_of_evidence

For evidence, hold a ladder with three rungs. On the lowest rung: "these companies describe doing this." Above it: "teams that report this practice also report that outcome." On the top rung, which this research doesn't reach: "this practice causes that outcome, by this much." When you cite, say which rung you're standing on. Stop at the rung the source reached.

**[ANIMATION]** end

For the choice, think of the decision table as a set of pressures, not a lookup. A team is usually in several rows at once, and the rows push in different directions. The design is what you get when you name each pressure and the control that answers it.

## DIAGRAM

**[ANIMATION]** step: flag.state-1

**[DIAGRAM]** The diagram of section 27.11. Draw the long-lived branch first: three weeks of commits off `main`, one big merge at the end. Then the same work behind a flag: three small pieces, each merged into `main` as it is finished.

```text
  Long-lived branch:    ---o---o---o---o---o---o---M---   main
                            \                     /
                             o---o---o---o---o---o       feature/batch-api (3 weeks, one big merge)

  Behind a flag:        ---o---b1--o---b2--o---b3--o---   main     b1..b3 = small merged pieces,
                                                                    switched off until release
```

With the flag, the feature never exists as a diverged line, so it never needs a large merge and never blocks a release.

**[ANIMATION]** step: stack.state-1

**[DIAGRAM]** The diagram of section 27.12: a stack of three pull requests. Draw from the bottom: each one names the one below as its base.

```text
    main ---o
             \
              a1---a2          pr/1-schema       (base: main)
                    \
                     b1        pr/2-endpoint     (base: pr/1-schema)
                      \
                       c1---c2 pr/3-client       (base: pr/2-endpoint)
```

And the stack of three pull requests: each one names the one below as its base.

**[ON SCREEN]** The table of section 27.14. It stays on screen for the rest of the video.

| Context | What it pushes you toward | Why | What to watch |
|---|---|---|---|
| One live version, deployed continuously (a hosted service) | one long-lived branch: GitHub Flow or trunk-based development | there is nothing for a release branch to hold | branch lifetime; flags for unfinished work; fast rollback |
| One live version, released on a schedule (weekly, per sprint) | trunk plus a late-cut release branch per release (Release Flow) | the branch isolates stabilization without freezing `main` | fix direction; retire old release branches |
| Several supported versions (SDK, on-premises product, mobile app with old versions in the field) | long-lived `release/x.y` branches; Git Flow is one historical arrangement of them | each supported version needs a line to receive fixes | the port check of section 27.10 as a release gate; CI per supported line |
| Small, experienced team with strong automated tests | shorter branches, lighter pre-merge gates | the cost of a bad merge is low and quickly repaired | do not drop review silently: decide it |
| Large team, or many less experienced contributors | feature branches with required review and checks; a merge queue at volume | pre-merge gates protect a main line the team cannot yet keep healthy by habit | review latency becoming the bottleneck |
| Open source with outside contributors | fork workflow, pull requests, maintainers merge | contributors are not yet trusted with write access | secrets and `pull_request_target` |
| Regulated environment (segregation of duties, audit trail, change approval) | protected branches with required review by someone other than the author, signed tags for releases, release branches where a release is an audited event | the audit asks who approved what and what exactly shipped | make bypasses visible: rulesets and Rule Insights; compliance comes from enforced, logged rules, not from the name of the model |
| Model or prompt releases that must be reproducible | tags on the exact commit, plus the data and model versions recorded with it | "which code produced this model" must have one answer | Chapter 28, section 28.7 |

And the decision table of section 27.14.

Each row is a context, what it pushes you toward, why, and what to watch.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch27/lab-32-1-two-strategies`. This is the lab replay of V172's exercise: the same work, done under two strategies in two repositories. We look only at the three result snippets. All commands are 🟢 SAFE; they read history.

Into the lab, briefly. It's the work of video 172 again, done under two strategies in two repositories, and every command only reads history.

**Step 1: the result under GitHub Flow.**

```bash
git log --oneline --graph --decorate -6
git log --oneline --no-merges v1.4.0..v1.4.1
```

<!-- snippet: ch27/lab-32-1-two-strategies/04-flow-result -->
```text
$ git log --oneline --graph --decorate -6
*   d4b2c19 (HEAD -> main, tag: v1.4.1) Merge pull request #44 from hotfix/suspended-tenant
|\  
| * fde1267 Fix limit 0 being treated as unlimited
|/  
*   4c206ca Merge pull request #43 from feature/batch-api
|\  
| * 98cc48f Add batch endpoint
|/  
*   518d961 (tag: v1.4.0) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
$ git log --oneline --no-merges v1.4.0..v1.4.1
fde1267 Fix limit 0 being treated as unlimited
98cc48f Add batch endpoint
```
<!-- /snippet -->

Two commits between the tags: the fix and the batch endpoint.

**Step 2: the result with a release branch.** Predict the last line before it appears. Say it out loud.

**[PAUSE]**

<!-- snippet: ch27/lab-32-1-two-strategies/07-rb-result -->
```text
$ git log --oneline --graph --decorate --all -8
* 8444832 (HEAD -> release/1.4, tag: v1.4.1) Fix limit 0 being treated as unlimited
| *   16db603 (main) Merge pull request #44 from hotfix/suspended-tenant
| |\  
| | * c73fb72 Fix limit 0 being treated as unlimited
| |/  
| * 45c76bf Merge pull request #43 from feature/batch-api
|/| 
| * 98cc48f Add batch endpoint
|/  
*   518d961 (tag: v1.4.0) Merge pull request #42 from feature/tenant-limits
|\  
| * 4806775 Read tenant limits with a default
* |   a7ccb4b Merge pull request #41 from feature/streaming
|\ \  
| |/  
|/|   
$ git log --oneline --no-merges v1.4.0..v1.4.1
8444832 Fix limit 0 being treated as unlimited
```
<!-- /snippet -->

One commit between the tags.

**Step 3: the same question asked of both repositories.**

```bash
git -C ../../github-flow/promptgate diff --stat v1.4.0 v1.4.1
git diff --stat v1.4.0 v1.4.1
git -C ../../github-flow/promptgate for-each-ref --format="%(refname:short)" refs/heads
git for-each-ref --format="%(refname:short)" refs/heads
```

<!-- snippet: ch27/lab-32-1-two-strategies/08-compare -->
```text
# The same question asked of both repositories: what changed between the two releases?
$ git -C ../../github-flow/promptgate diff --stat v1.4.0 v1.4.1
 gateway/batch.py  | 2 ++
 gateway/limits.py | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git diff --stat v1.4.0 v1.4.1
 gateway/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
# And: which long-lived refs does each strategy leave behind?
$ git -C ../../github-flow/promptgate for-each-ref --format="%(refname:short)" refs/heads
main
$ git for-each-ref --format="%(refname:short)" refs/heads
main
release/1.4
```
<!-- /snippet -->

This is the form of evidence to bring to a strategy discussion.

**[ANIMATION]** walk: columns=,GitHub_Flow,release_branch rows=files_changed_by_the_patch_release:two:one|long-lived_refs:one:two mono=off title=Evidence_anyone_in_the_room_can_run

Not "release branches are cleaner", but: under this model the patch release changes two files, under that one a single file. This model leaves one long-lived ref, that one leaves two. Each line is a command anyone in the room can run.

**[ON SCREEN]** The decision table, with one team placed in it live.

Take this description: a company of forty engineers that runs a hosted LLM gateway, deployed continuously, and from next quarter also ships an on-premises edition to two customers who stay one version behind. It's subject to an audit that asks who approved each production change. Before we go down the table, predict: which rows apply to this team? Say them out loud.

**[PAUSE]**

**[ANIMATION]** walk: columns=row,context,pushes_toward rows=one:one_live_version,_deployed_continuously:one_long-lived_branch,_flags_for_unfinished_work|three:several_supported_versions:release/x.y_branches,_the_port_check_as_a_release_gate|seven:a_regulated_environment:review_by_someone_other_than_the_author,_signed_tags mono=off title=One_team,_three_rows_at_once id=team

**[ANIMATION]** step: team.3

Now down the rows. Row one applies: one live hosted version, deployed continuously, so one long-lived branch and flags for unfinished work. Row three applies from next quarter: several supported versions, so `release/x.y` branches, a fix direction that is written down, and the port check as a release gate. Row seven applies: a regulated environment, so required review by someone other than the author, signed tags, and bypasses made visible.

Three rows at once, and the textbook says so: the rows combine. We won't resolve it into a named model here. The design itself is the subject of Lab 34.1 and of video 179, and you write it yourself. What you take from here is the method: name the rows, and for each row say what it pushes toward, why, and what to watch.

**[ANIMATION]** end

One more sentence from the section, for the day somebody asks whether the choice is final. Changing the model later is cheap in Git, because branches are refs, and expensive in habits, pipelines and rulesets. So start with the simplest model that answers the two questions, and add a branch only when you can name the version or the audit requirement that needs it.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Citing DORA as proof that a named workflow is best.** Root cause: the research is survey-based and correlational and is expressed in branch lifetime and batch size, not in workflow names.
2. **Quoting an effect size from memory.** Root cause: the source material behind this course contains no such number, so any figure is unsupported.
3. **Never removing flags.** Root cause: each flag adds states to test, and a flag without an owner and an end date becomes permanent configuration, which the taxonomy calls toggle debt.
4. **Adopting a merge queue for its throughput numbers.** Root cause: the published numbers describe very large repositories; a small team gets the correctness guarantee and little else.
5. **Calling a queue or a stack a branching strategy.** Root cause: both are techniques for integrating and reviewing under any model with pre-merge checks; they do not decide which long-lived branches exist.

## PRODUCTION EXAMPLE

Now, out of the lab. An LLM application team wants to change the default prompt of its support assistant. The change touches the prompt template, the retrieval settings and the evaluation thresholds, and the work will take three weeks. The old way was a long-lived branch and a merge that nobody wanted to review.

The team merges the work in small pieces behind a flag. The natural flags for an LLM application are the model name, the prompt version and the retrieval settings. The new prompt is merged, then evaluated on a fraction of traffic before it becomes the default. Two consequences follow, and the lead states both in the design note. First, "which prompt answered this ticket" is now a question about a flag value at a time, not only about a commit, so the flag value is recorded with each answer. Second, the flag has an owner and a removal date, and the evaluation suite runs with the flag on and with it off until then.

## PRACTICE EXERCISE

Your turn. Do Exercise 32.2, Level 2, "Six teams, which model?", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

For each team, before you name anything, write down your answers to the two questions: how many versions are live at once, and how often do they release. Then predict which rows of the table apply, and only then make a recommendation, with one sentence of evidence for it and one sentence against it. The solutions are in a separate file. Open them after you have written all six.

The challenge is Exercise 32.7, Level 5, "The regression in 3.0", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q340: "A colleague says the DORA research proves trunk-based development is best. What does it show, how was it measured, and what would you say instead?"

**[PAUSE]**

Answer out loud. A strong answer keeps the three parts of the question apart. For "what does it show", it states the association in the terms the research uses: which practices, which outcome. For "how was it measured", it names the method and the years, and draws the consequence for the verb you're allowed to use. For "what would you say instead", it gives a sentence a CTO can act on, with a variable the team controls. It neither overstates the evidence nor dismisses it, and it doesn't invent a number.

## RECAP

Let's land this, in your own words.

- A feature flag separates deployment from release; it costs added states to test and flags that must be removed.
- A merge queue tests each change in the combination in which it will land, which the up-to-date requirement achieves only with a race.
- The DORA findings are survey-based and correlational and are about branch lifetime and batch size; they rank no named workflow and establish no cause.
- The two first questions for any strategy are how many versions are live at once and how often you release; the rows of the decision table combine.
- Start with the simplest model that answers the two questions, and add a branch only when you can name the version or the audit requirement that needs it.

## HOMEWORK

Read sections 27.11 to 27.14. Then do Exercise 32.6, Level 3, "Say it to a CTO", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md): four sentences, spoken, recorded, and compared with the section the next day.

Today you learned to say exactly what the evidence supports, and to stop there. That's a rare skill in a planning meeting, and it's yours now. Say your four sentences out loud once. The next video gives the reason behind each team practice and the root cause behind each anti-pattern, with code review and commit message conventions. Until then, look at the state first and type second. See you in the next one.
