# V179: Design review briefing: branching model, governance, CI and security policy for a described company

- **Part.** 8, Professional practice
- **Module.** 34 (the Level 8 design review)
- **Planned minutes.** 12
- **Prerequisites.** V134, V161, V174, V178
- **Textbook sections.** [Chapter 27](../../textbook/ch27-open-source-team-workflows.md), sections 27.14 and 27.20; [Chapter 28](../../textbook/ch28-ai-ml-workflows.md); the brief, deliverable and rubric in [`lab-manual/m34-practices-design-review.md`](../../lab-manual/m34-practices-design-review.md)
- **Demo scripts.** `labs/ch27/lab-34-1-design-review-evidence.sh` (snippets `01-branches`, `02-releases`, `03-fix-direction`, `04-integration`, `09-verify`)

## HOOK

**[ON SCREEN]** "Which branching model do you follow?"

An auditor asks that question, and most teams answer with a name. A branching model is a team's agreement about its branches: its names for lines of commits, the saved snapshots of a project.

**[ANIMATION]** cards: question=Which_branching_model_do_you_follow? cards=how_long_branches_live|which_way_fixes_travel|who_may_move_which_ref|what_was_in_the_last_patch_release title=The_name_tells_the_auditor_nothing at_1=12 at_2=24 at_3=34 at_4=50

The name tells the auditor nothing: not how long branches live, not which way fixes travel, not who may move which ref, meaning a branch or a tag, not what was in the last patch release. The chapter's advice is blunt: don't adopt a model by name. Write down the refs, the rules and the fix direction.

**[ANIMATION]** end

Level 8 ends by asking you to do exactly that for a whole company, and then to defend it against five people who each want something different. So what do you tell the auditor instead?

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Every earlier level ended with a gate. This one ends with a design review, because the skill of Level 8 can't be checked by a repository in a broken state. You're given a company and its repository, the project's stored history. You measure it, design the company's branching model, governance, CI and security policy, write the design down, and defend it against objections. CI means automated checks on each change.

This briefing tells you what is asked, how it's judged, how the evidence is gathered, and how to structure a design. It shows no model design. There's none: the lab file says so, and so does its answer file. A design is judged against a rubric, a scoring sheet, and two different designs can both pass.

## LEARNING OBJECTIVES

After this video you can:

1. State what the design review asks for and how it is judged.
2. Collect the evidence a design needs from an existing repository with read-only commands.
3. Structure a design as decisions, each with its reason, its cost and the control that enforces it.
4. Defend a design against objections without retreating to "best practice".

## CONCEPT

**[ANIMATION]** cards: id=parts cards=Evidence|Branching_and_release_model|Governance|CI_design|Security_policy|Reproducibility:of_model_releases|Migration numbered=on title=Seven_parts,_in_this_order at_1=42 at_2=50 at_3=60 at_4=66 at_5=72 at_6=79 at_7=86

**[ANIMATION]** step: 7

**What is asked.** A design document of at most four pages, plus an evidence table. It has seven parts, in this order. Evidence. Branching and release model. Governance. CI design. Security policy. Reproducibility of model releases. And migration.

Two requirements run through all seven. For every control, you state the layer that enforces it: a convention, a local hook, a CI check, a GitHub rule, or a contractual or human process. And for every factual claim about GitHub, whether a feature, a plan requirement or a default, you cite the chapter of the book or the documentation page. If you don't know whether a plan includes a feature, you say so and say how you would find out.

**[ANIMATION]** end

**How it is judged.** One hundred points, pass at 70 or more, with no automatic failure.

**[ON SCREEN]** The parts and their points, from the lab's rubric.

| Part | Points |
|---|---|
| Evidence | 15 |
| Branching and release model | 20 |
| Governance | 15 |
| CI design | 15 |
| Security policy | 15 |
| Reproducibility | 10 |
| Migration | 10 |

**The automatic failures.** Five, whatever the points. Read them as the five things this part of the course taught you not to do.

- Claiming that research proves one branching strategy is best, or citing a number for it.
- A policy whose only enforcement is a local hook or a convention, presented as a control.
- Treating a commit that deletes a secret, a force push, or making a repository private as removal of the secret.
- Inventing a GitHub feature, default or plan requirement, or a Git command or option.
- A design that cannot produce a patch release for a customer containing only fixes.

**[ANIMATION]** cards: id=quiz question=A_policy_enforced_only_by_a_local_hook cards=A:a_finished_control|B:an_automatic_failure marks=2:ok title=Quick_quiz at_1=60 at_2=75

**[ANIMATION]** step: 2

Quick quiz. A policy is enforced only by a local hook, a script Git runs on one person's own machine. A, a finished control, or B, an automatic failure?

**[PAUSE]**

**[ANIMATION]** step: marks

B, the second on that list. A hook isn't cloned, so the person it controls can step over it.

**[ANIMATION]** cards: id=five cards=A_developer:finds_the_model_too_heavy|A_release_manager:an_urgent_fix_for_one_customer|A_security_reviewer|An_auditor|The_CTO:cost_and_evidence title=Objections_from_five_directions at_1=30 at_2=46 at_3=64 at_4=72 at_5=80

**The defence.** After you submit, the assessor raises objections, one at a time, from five directions. A developer who finds the model too heavy. A release manager with an urgent fix for one customer. A security reviewer. An auditor. And the CTO, asking about cost and about evidence.

**[ANIMATION]** cards: id=answers cards=defend|amend|concede marks=1:ok,2:ok title=Three_answers_to_an_objection at_1=8 at_2=18 at_3=24 at_marks=40

For each objection you may defend the design, amend it, or concede. A reasoned amendment scores as well as a successful defence. What costs points is changing the design without saying what the change breaks, or defending a control you can't say how to enforce.

**[ANIMATION]** cards: id=decision cards=The_decision|The_reason:a_measurement,_a_mechanism_or_a_source|The_cost|Enforced_by:the_layer_that_enforces_it numbered=on marks=4:ring title=One_decision,_four_lines at_1=18 at_2=28 at_3=62 at_4=70

**[ANIMATION]** step: 4

**How to structure a decision.** Each decision in your design has the same four lines. The decision. The reason, which is a measurement you made, a mechanism you can explain, or a source you can cite. The cost. And the layer that enforces it. A decision whose "enforced by" line reads "people will remember" isn't finished.

Try it now, on paper. Thirty seconds. Write those four lines for one rule you would want on a shared project. Read the last line out loud.

**[PAUSE]**

**[ANIMATION]** step: marks

A layer, such as a CI check, can be tested. "People will remember" can't, so that's the line to work on.

## MENTAL MODEL

**[ANIMATION]** stores: id=bridge boxes=a_claim_with_support:it_holds|a_claim_without:nothing_underneath rows=1:A:an_objection_arrives@hl|2:A:a_reason@ok|2:A:an_enforcing_layer@ok|3:B:an_objection_arrives@hl|3:B:"that_is_best_practice"@ghost title=An_objection_is_a_load_on_one_member at_1=50 at_2=65 at_3=82

**[ANIMATION]** step: 3

Think of the design as a set of load-bearing claims, like the members of a bridge. Each claim carries something: a patch release that contains only fixes, a secret that can't arrive, a model that can be named five years later. An objection in the defence is a load applied to one member. If the member has a reason and an enforcing layer, it holds. If it rests on "that is best practice", it has nothing underneath it.

Where the picture breaks: a bridge member that fails is a defect, and in the defence a member you replace isn't. You're allowed, and scored well, for amending a decision under a good objection, provided you say what the amendment breaks elsewhere.

**[ANIMATION]** layers: layers=a_habit|a_client_setting|a_server_rule|a_review|a_pipeline probe=a_control_in_your_design title=The_layers,_from_video_177 at_1=26 at_2=32 at_3=38 at_4=45 at_5=50

The second model is the one from video 177: the layers. A habit, a client setting, a server rule, a review, a pipeline. For every control in your design, be able to point at its layer and say who can step over it and how that would be seen afterwards.

## DIAGRAM

**[DIAGRAM]** A new drawing: a one-page design sheet with four blocks, and under each block three lines. It is a form to fill in, shown empty.

```text
  +------------------------------------+------------------------------------+
  | BRANCHING AND RELEASES             | GOVERNANCE                         |
  |   decision    : ................   |   decision    : ................   |
  |   reason      : ................   |   reason      : ................   |
  |   enforced by : ................   |   enforced by : ................   |
  +------------------------------------+------------------------------------+
  | CI                                 | SECURITY                           |
  |   decision    : ................   |   decision    : ................   |
  |   reason      : ................   |   reason      : ................   |
  |   enforced by : ................   |   enforced by : ................   |
  +------------------------------------+------------------------------------+

  reason      = a measurement, a mechanism, or a cited source
  enforced by = convention | local hook | CI check | GitHub rule | human or contractual process
```

The sheet is the skeleton of one decision per block. A real design has several decisions per block, and the lab's deliverable adds reproducibility and migration. Use the sheet to test each decision before you write prose around it. The blocks stay empty in this video.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch27/lab-34-1-design-review-evidence`. The repository, `riskscore`, is generated by a script with fixed dates, so every number is reproducible and your IDs match the book. Every command is 🟢 SAFE: the evidence part changes nothing. We read what each command measures. Tying each measurement to a statement of the brief is your work.

**Step 1: which branches exist, how old are they, how far from `main`?**

```bash
git for-each-ref --sort=committerdate --format='%(committerdate:short) %(ahead-behind:main) %(refname:short)' refs/heads
git branch --no-merged main
```

Before the output: what would you expect this to look like for a team that deploys several times a week?

<!-- snippet: ch27/lab-34-1-design-review-evidence/01-branches -->
```text
$ git for-each-ref --sort=committerdate --format='%(committerdate:short) %(ahead-behind:main) %(refname:short)' refs/heads
2026-05-04 0 2 release/2.1
2026-05-18 1 5 release/2.0
2026-05-19 9 2 feature/big-refactor
2026-06-02 2 2 feature/calibration
2026-08-17 6 2 develop
2026-08-24 0 0 main
$ git branch --no-merged main
  develop
  feature/big-refactor
  feature/calibration
  release/2.0
```
<!-- /snippet -->

Three columns per branch: the date of its last commit, ahead and behind relative to `main`, the name. Ahead and behind count commits one side has and the other lacks. This is a measurement of branch lifetime, the variable that video 173 said you can act on.

**Step 2: what was released, and from where?**

```bash
git for-each-ref --sort=creatordate --format='%(creatordate:short) %(refname:short) %(*objectname:short)' refs/tags
git log --oneline --graph --decorate --simplify-by-decoration --all
```

<!-- snippet: ch27/lab-34-1-design-review-evidence/02-releases -->
```text
$ git for-each-ref --sort=creatordate --format='%(creatordate:short) %(refname:short) %(*objectname:short)' refs/tags
2026-03-20 v2.0.0 e1b64b9
2026-05-04 v2.1.0 628aa42
2026-05-18 v2.0.1 f1e338f
$ git log --oneline --graph --decorate --simplify-by-decoration --all
* a5b7c19 (HEAD -> main) Update README.md
| * cd79546 (develop) Rework explanation ordering
|/  
| * 5ab6aee (feature/calibration) Document calibration
|/  
| * 92bcd50 (feature/big-refactor) refactor step 9
|/  
* 628aa42 (tag: v2.1.0, release/2.1) Merge develop for 2.1
| * f1e338f (tag: v2.0.1, release/2.0) fix
|/  
* e1b64b9 (tag: v2.0.0) model moved to bucket
* e9658fa initial
```
<!-- /snippet -->

The tags, names that aren't expected to move, with their dates and the commits they name, and a graph reduced to the decorated commits. Look at where each tag sits relative to the branches.

**Step 3: is there a fix on a release branch that `main` never received?**

```bash
git log --format="%h %ad %an: %s" --date=short --cherry-pick --right-only --no-merges main...release/2.0
git log --format="%h %ad %an: %s" --date=short --cherry-pick --right-only --no-merges main...release/2.1
```

Predict, from video 172, what an empty result means and what a printed line means. Say it out loud.

**[PAUSE]**

<!-- snippet: ch27/lab-34-1-design-review-evidence/03-fix-direction -->
```text
# Is there a fix on a release branch that main never received?
$ git log --format="%h %ad %an: %s" --date=short --cherry-pick --right-only --no-merges main...release/2.0
f1e338f 2026-05-18 Ravi Menon: fix
$ git log --format="%h %ad %an: %s" --date=short --cherry-pick --right-only --no-merges main...release/2.1
```
<!-- /snippet -->

The command lists commits on the release branch with no equivalent change on `main`. Empty means none. One command prints a line and one prints nothing. Remember also the limit of this check, because the rubric asks for the limits of each measurement.

**Step 4: how does work reach `main`?**

<!-- snippet: ch27/lab-34-1-design-review-evidence/04-integration -->
```text
$ git rev-list --count --merges main
1
$ git rev-list --count --no-merges main
9
$ git log --format="%ad %s" --date=short --first-parent main
2026-08-24 Update README.md
2026-06-03 Add calibration (#88)
2026-05-04 Merge develop for 2.1
2026-03-12 model moved to bucket
2026-03-10 add model
2026-03-04 remove env file
2026-03-03 wip
2026-03-02 initial
$ git rev-list --count main..develop
6
$ git log -1 --format="%ad" --date=short "$(git merge-base main develop)"
2026-05-04
```
<!-- /snippet -->

Merge commits, which have more than one parent, against ordinary commits. Then the first-parent log with dates, and the distance and the age of the split between `main` and `develop`.

**Step 5: separate finished work from open work.**

<!-- snippet: ch27/lab-34-1-design-review-evidence/09-verify -->
```text
# The same test on every unmerged branch separates finished work from open work:
$ for b in $(git branch --no-merged main --format="%(refname:short)"); do if [ "$(git merge-tree --write-tree main "$b")" = "$(git rev-parse "main^{tree}")" ]; then echo "content already on main: $b"; else echo "open work:               $b"; fi; done
open work:               develop
open work:               feature/big-refactor
content already on main: feature/calibration
open work:               release/2.0
$ git diff --stat main...feature/big-refactor
 score/model.py | 9 +++++++++
 1 file changed, 9 insertions(+)
```
<!-- /snippet -->

This is the content check of video 174 applied to every unmerged branch. It exists because the commit-based checks mislead after a squash merge, which combines several commits into one new commit. In the lab you meet that as the failure scenario, and you correct your evidence table afterwards.

Stop here. Numbers, and no conclusion. Whose work is the conclusion?

**[PAUSE]**

Yours. The replay contains more measurements: the content of the history, people and messages. You run those yourself. And no conclusion is drawn on screen: what these numbers mean for the company in the brief is the first fifteen points of the review.

## COMMON MISTAKES

1. **Starting with the name of a model.** Root cause: a name states neither the refs, nor the rules, nor the fix direction, so nothing in the design can be tested.
2. **Asserting facts about the repository without a command.** Root cause: the evidence part is scored on measurements tied to statements of the brief, and an impression cannot be checked.
3. **Presenting a hook or a convention as a control.** Root cause: the enforcing layer is one the controlled person can step over, which the rubric treats as an automatic failure.
4. **Amending the design under pressure without stating the consequence.** Root cause: each decision carries a load elsewhere in the design, and a silent change leaves that load unsupported.
5. **Filling a gap with an invented feature or plan requirement.** Root cause: the claim was not checked against the book or the documentation, and "I do not know, and here is how I would find out" was available and scores better.

## PRODUCTION EXAMPLE

**[ANIMATION]** cards: id=example cards=The_decision|The_reason:a_measurement,_a_mechanism_or_a_source|The_cost|Enforced_by:the_layer_that_enforces_it numbered=on title=One_decision,_four_lines at_4=30

**[ANIMATION]** step: 1

Now, out of the lab. A staff engineer is asked to propose a new workflow for a company that runs a hosted product and also ships an on-premises edition. In the review meeting a developer objects that release branches are heavy and that the team should tag `main` and nothing more.

**[ANIMATION]** step: 2

She doesn't answer with "release branches are best practice". She answers with a measurement and a mechanism: the on-premises customers take patch releases only, and under tags on `main` the range between two tags contains everything merged since, which she shows with one `git log` between the last two tags of the existing repository.

**[ANIMATION]** step: 4

Then she states the cost of her own proposal, a pipeline per supported line and a port check as a release gate, and offers the amendment she can accept: release branches only for the on-premises minors, cut late, and nothing downstream of `main` for the hosted product. The developer's objection changed the design, the change is written down with what it affects, and the decision now has a reason that survives the next objection.

## PRACTICE EXERCISE

Your turn. Do Lab 34.1, "The design review", in [`lab-manual/m34-practices-design-review.md`](../../lab-manual/m34-practices-design-review.md). Read the brief twice before you open the lab shell.

Before you run any command, write down for each of the four reported problems of the brief which measurement would confirm it and what you predict that measurement will show. Then gather the evidence and compare. Work alone, and write the document before any discussion. The answer file holds the answers to the evidence questions and notes for the assessor. Don't read the assessor notes before you have submitted your design.

The challenge is Exercise 34.5, Level 3, "The design review", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q353: "Design the branching and governance model for a regulated company that runs a continuously deployed hosted product and also sells an on-premises edition whose customers stay a version behind. What do you write down, and what do you tell an auditor who asks which branching model you follow?"

**[PAUSE]**

Answer out loud, in about five minutes. A strong answer starts by placing the company in the decision table: it's in several rows at once, and you name them. It then derives the long-lived refs from the number of live versions and the release rhythm of each product, states one fix direction with the invariant that tests it, and gives the rules per ref pattern with their enforcing layer and their bypass path. For the auditor, it explains why a name isn't an answer and what you show instead: where compliance comes from. That's the auditor from the opening, answered. It claims nothing about research that the research doesn't show.

## RECAP

Let's land this.

- Level 8 ends with a design review: evidence, branching and releases, governance, CI, security, reproducibility, migration.
- Evidence is gathered with read-only commands, and each measurement is tied to a statement of the brief, with its limits.
- Every decision has a reason, a cost and an enforcing layer; a hook or a convention alone is not a control.
- In the defence you may defend, amend or concede; an amendment has to say what it breaks.
- Never claim that research proves a strategy best, never invent a feature, and never present a deletion commit as removal of a secret.

## HOMEWORK

Write the design for Lab 34.1 in full, at most four pages plus the evidence table. Then have a colleague or the tutor raise three objections in strict interview mode: they ask, you answer, no hints before your attempt. Record the objections you couldn't answer. They're your revision list for Level 9. Finally, read [`reference/command-safety.md`](../../reference/command-safety.md) before Part 9 begins, because every incident drill is scored on the safety of the path as well as on the end state.

You can now give every decision a reason, a cost and an enforcing layer. Practise that in the lab. Next time: the diagnosis method, and the push that had nothing to push. Until then, look at the state first and type second. See you in the next one.
