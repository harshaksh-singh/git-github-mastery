# V171: Branch names as conventions, GitHub Flow, Git Flow and its author's 2020 note, GitLab Flow, trunk-based development and release branches

- **Part.** 8, Professional practice
- **Module.** 32
- **Planned minutes.** 24
- **Prerequisites.** V036, V082, V170
- **Textbook sections.** [Chapter 27](../../textbook/ch27-open-source-team-workflows.md), sections 27.5 to 27.8
- **Demo scripts.** `labs/ch27/git-flow.sh` (snippets `01-release-branch`, `02-hotfix`, `03-graph`, `04-what-ships`)

## HOOK

**[ON SCREEN]** "A new engineering manager wants to standardize on Git Flow for our continuously deployed service, because it is the industry standard."

Your team deploys its hosted service several times a day from `main`. The new manager's last company used `develop`, release branches and hotfix branches, and the proposal arrives as a slide with the well-known diagram. You have to answer in a meeting, and "I prefer trunk-based development" is an opinion, not an answer.

By the end of this video you can say what Git Flow prescribes, commit by commit, what its own author wrote about it in 2020, and what each of the other models assumes about how software is delivered. None of them is a standard. Each is an answer to a delivery situation. Keep the words "industry standard" in mind. The author of that diagram has a comment on them.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Three words first. A commit is one saved snapshot of the project. A branch is a name that points at a commit and moves forward as you commit. A tag is a name that isn't expected to move.

In video 170 the workflow involved two servers. Today everything is inside one repository, and the subject is which branches exist and how commits travel between them.

Chapter 27 reduces the subject to one sentence: a branching strategy is nothing but an agreement about which refs exist, who may move them, and in which direction commits travel between them. You know from video 36 what `--no-ff` does and what first-parent history is: `--no-ff` makes a merge commit even where a fast-forward was possible, and first-parent history follows only the first parent of each merge. You know from video 82 that a release is a tag and that `git describe` and tag ranges answer "what did we ship".

We go through five things: branch names, GitHub Flow, Git Flow with a replayed history, the 2020 note, and then GitLab Flow, trunk-based development, release branches and Microsoft's Release Flow, each as a graph.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Explain why `main`, `develop`, `feature/*`, `hotfix/*` and `release/*` are conventions and what gives a name force.
2. Describe GitHub Flow and what it assumes about deployment.
3. Describe Git Flow and state what its author wrote about it in 2020.
4. Describe trunk-based development and release branches.
5. Draw the graph each model produces for one release and one hotfix.

## CONCEPT

**Branch names are conventions, not laws.** `main`, `develop`, `feature/*`, `bugfix/*`, `hotfix/*` and `release/*` are names that people agreed on. Git gives none of them a meaning.

To Git, `refs/heads/release/1.4` is a ref whose name happens to contain a slash. The slash matters in exactly two technical ways. It lets patterns select groups of branches: `git branch --list 'release/*'`, a ruleset target such as `release/**`, a workflow filter such as `branches: ['release/**']`. And in the files backend it makes `release` a directory, so a branch named `release` and a branch named `release/1.4` can't both exist.

**[ON SCREEN]** The table of section 27.5.

| Name | Usual meaning | What gives it force |
|---|---|---|
| `main` | the integration branch; the default branch | the repository's default-branch setting; a ruleset |
| `develop` | Git Flow's integration branch, with `main` reserved for released code | only the team's agreement |
| `feature/<topic>` | work in progress on one change | nothing; often a naming rule |
| `bugfix/<topic>` | a fix that is not urgent, taking the normal path | nothing |
| `hotfix/<topic>` | an urgent fix to something already released | nothing in Git; sometimes a faster review rule |
| `release/<version>` | the line from which one version and its patches are tagged | a ruleset; deployment workflows that trigger on the pattern |

Read the right-hand column. Force comes from three places: a platform setting, a rule with a pattern, which GitHub calls a ruleset, or automation that triggers on a pattern. Everything else is habit. The lab configuration sets `init.defaultBranch=main`. Unconfigured Git 2.55 still creates `master`. Neither name does anything the other does not.

**[ANIMATION]** end

Quick quiz. What gives the name `develop` its force? A, Git itself. B, a platform setting. C, only the team's agreement. Your answer?

**[PAUSE]**

C, only the team's agreement. That was the second row of the table.

The convention earns its keep when rules are attached to it. "Nobody pushes to `release/**` except through a pull request with two approvals" is one ruleset with one pattern, and it works only if every release branch is named that way. A name that carries the author, such as `asha/rerun`, says the branch is private and may be rebased.

Try it now, for thirty seconds. In any repository you have, type `git branch --list 'release/*'`. It only reads. It lists the branches whose names match the pattern. I'll wait.

**[PAUSE]**

If it printed nothing, no branch of yours matches. That's the point of a naming pattern: a branch outside the pattern is outside the rule.

**[ANIMATION]** graph: *1-*2-M1 main; ^*2-*4-*5-M1; HEAD=main; note:*5:feature/streaming; say:One_long-lived_branch,_short_branches_off_it; name:one => + M1-M2 main; M1-*6-*7-M2; note:*7:feature/tenant-limits; M2 tag:v1.4.0; say:Merge,_tag,_deploy; name:two => + M2-M3 main; note:M3:feature/batch-api_merged; say:off; name:three => + M3-*3-M4 main; ^*3-*8-M4; note:*8:hotfix/suspended-tenant; M4 tag:v1.4.1; say:A_hotfix_is_one_more_short_branch; name:hotfix => + range:M3,*3,*8,M4:between_the_two_tags; say:off; name:between title=GitHub_Flow id=ghf dy=95 dx=170 at_between=50

**[ANIMATION]** step: ghf.one

**GitHub Flow.** One long-lived branch that is always deployable, short branches off it, a pull request for each, and deployment right after the merge. Deployable means that it can go into service for users at any moment, and a pull request is GitHub's object for proposing and reviewing a merge.

**[ANIMATION]** step: ghf.three

GitHub's documentation describes six steps: create a branch, make changes, create a pull request, address review comments, merge, delete the branch. Scott Chacon's 2011 essay, where the name comes from, adds the rules that give it its character: anything on the main branch is deployable, and you deploy immediately after merging. He also gives the reason GitHub didn't use Git Flow: GitHub deployed many times a day, while Git Flow is organised around releases. Martin Fowler's reading is that the model assumes a single production version, so release branches and hotfix branches disappear: a hotfix is one more short branch.

**[ANIMATION]** step: ghf.hotfix

What it assumes: that there is one live version, that `main` can be deployed at any commit, and that a broken deployment is repaired by rolling forward or back quickly. Microsoft's description of its own practice records where the strict form stops scaling: when a repository completes more than 200 pull requests a day, deploying each one before or after merge turns into a queue, so Microsoft batches deployments into sprint releases instead.

What it doesn't say: how long a feature branch may live, or what to do when a customer can't take the newest version. The next video shows that consequence with a real history.

**[ANIMATION]** flow: actors=feature,develop,release,*main,hotfix subs=-,integration,stabilization,released_code,- msgs=1>2:merge_--no-ff|2>3:cut_from_develop|3>4:merge,_tag|3>2:merge_back|4>5:cut_from_main|5>4:merge,_tag|5>2:merge title=Git_Flow,_as_Driessen_published_it_in_2010 id=gf

**[ANIMATION]** step: gf.actors

**Git Flow.** Two long-lived branches, `main` for released code and `develop` for integration, plus three kinds of supporting branch: feature, release and hotfix.

**[ANIMATION]** step: gf.7

Vincent Driessen published "A successful Git branching model" on the fifth of January 2010. Feature branches start from and merge into `develop`, with `--no-ff` so that each feature stays visible as a unit. A release branch is cut from `develop`, receives only stabilization commits, and is merged into `main`, and tagged, and back into `develop`. A hotfix branch is cut from `main`, and is merged into `main`, and tagged, and into `develop`.

**[ANIMATION]** cards: question=The_note_of_reflection_of_5_March_2020,_as_the_course's_research_report_summarizes_it numbered=on cards=Conceived_for_explicitly_versioned_software:that_may_need_several_versions_supported_in_the_wild|Continuous_delivery_of_a_web_application:adopt_a_simpler_workflow_such_as_GitHub_Flow|Weigh_your_own_context:no_model_is_a_cure-all at_2=45 at_3=65

**The 2020 note.** On the fifth of March 2020 the author added a "note of reflection" at the top of the article. I give it as the course's research report summarizes it, not as a quotation, in three points. First, the model was conceived for explicitly versioned software that may need several versions supported in the wild. Second, a team doing continuous delivery of a web application should adopt a simpler workflow such as GitHub Flow. Third, readers should weigh their own context, because no model is a cure-all. Fowler adds that Git Flow says nothing about how long feature branches live, and Atlassian's tutorial now labels Gitflow a legacy workflow.

**[ON SCREEN]** Outdated advice.

"Use Git Flow" as a default for every project. The author of the model restricts it to explicitly versioned software with several supported versions. For a continuously deployed service it adds a second long-lived branch and two merges per release, and the tags already record what was released. That's the author's comment on "the industry standard" from the opening.

**When it still fits.** Installed software, firmware, SDKs and libraries with several maintained versions, and organizations where a release is a scheduled, audited event. Even there, the part that does the work is the release branch, which you can have without `develop`.

**[ANIMATION]** graph: *1-*2-*3-*4-*5-*6 main; ...-M-M′ production; *3-M; *5-M′; HEAD=none; note:*6:every_merge_deploys_to_staging; note:M′:a_merge_from_main_deploys_to_production title=GitLab_Flow_with_a_production_branch id=gl

**GitLab Flow.** GitLab defines it as a simplified strategy that works directly with `main` and adds, where needed, a production branch, environment branches such as staging and production, or release branches for software shipped in versions. Three of its eleven published rules: fix bugs in `main` first and release branches second, base releases on tags, and never rebase pushed commits.

**[ON SCREEN]** Unverified.

GitLab's original 2014 "GitLab Flow" document is no longer reachable on docs.gitlab.com. The phrase "upstream first" for its fix direction was read only through a mirror, according to the research notes of this course. The two current pages the textbook links are the source for what I said.

**[ANIMATION]** graph: *1-*2-*3-*4-*5-*6-*7 main; *1-*8-*2; *3-*9-*4; *4-*10-*5; *6-*11-*7; HEAD=none; note:*10:branches_that_live_hours_to_two_days title=Trunk-based_development:_main_is_the_trunk id=tbd dy=55 dx=200

**Trunk-based development.** Developers integrate into one branch, the trunk, and avoid other long-lived development branches. Very small teams may commit straight to the trunk. Larger teams use short-lived feature branches, which should last no more than a couple of days, belong to one developer or a pair, and be deleted after the merge. Long-running changes are handled with feature flags and a technique called branch by abstraction, instead of long branches. A feature flag is a condition in the code that keeps unfinished behavior switched off. Fowler treats it as close to a synonym for continuous integration.

**[ANIMATION]** end

The difference from GitHub Flow is one of degree, not of kind. Both have one long-lived branch. Trunk-based development adds a limit on branch lifetime and, in its strictest form, drops the pre-merge review gate.

**[ANIMATION]** graph: *1-*2-*3-*4-F-*5-*6 main; *3-*7-F′ release/1.4; *7 tag:v1.4.0; F′ tag:v1.4.1; HEAD=none; note:F:the_fix,_made_on_main_first; note:F′:cherry-pick_of_F title=A_release_branch,_with_the_fix_made_on_main_first id=rel

**Release branches.** A release branch is cut from the trunk shortly before a release, receives only fixes, and is the place the release and its patches are tagged. The trunk-based development site states the rules: cut late. The branch may start from a commit older than the trunk's head. It's never merged back. It's deleted when the version is no longer supported. And bugs are reproduced and fixed on the trunk first and cherry-picked to the release branch. A cherry-pick copies one commit's change onto another branch as a new commit with a new ID.

**[ANIMATION]** graph: *1-*2-*3-*4-*5-F-*6-*7-*8 main; *3-*9 releases/M128; *5-F′ releases/M129; *7-*10 releases/M130; HEAD=none; note:F′:hotfix_cherry-picked_to_M129 title=Microsoft's_Release_Flow id=rf dy=90

**Microsoft's Release Flow.** Short-lived topic branches are merged to `main` through pull requests with branch policies. At the end of each three-week sprint a release branch is created, named for the sprint. The document's example is `releases/M129`. It's deployed in rings. A hotfix is made in `main` first and then cherry-picked to the release branch through its own pull request. Release branches never merge back to `main`, and the old one is abandoned after the next sprint ships. Release Flow is trunk-based development plus a release branch per sprint plus the "fix on main first" rule. The names differ more than the graphs do.

## MENTAL MODEL

**[ANIMATION]** end

Now one question that sorts them all. All of these models keep one integration branch. They differ in what, if anything, sits downstream of it, and in which direction a fix travels.

**[ANIMATION]** decide: nodes=q:How_many_versions_are_alive_at_once?|a:nothing_downstream_of_main|b:something_has_to_name_each_live_version|a1:between_GitHub_Flow_and_trunk-based_development|b1:a_release_branch|b2:in_Git_Flow,_the_pair_main_and_develop edges=q>a:one|q>b:more_than_one|a>a1:|b>b1:|b>b2: path=q,b,b1 id=sort

**[ANIMATION]** step: sort.level-3

Use this as the sorting question: **how many versions are alive at once?** If the answer is one, there's nothing downstream of `main`, and you're somewhere between GitHub Flow and trunk-based development. If the answer is more than one, something has to name each live version, and that something is a release branch or, in Git Flow, the pair of `main` and `develop`.

**[ANIMATION]** end

A way to picture it: a river and its canals. The integration branch is the river. A release branch is a canal cut from the river at one point, with its own slower water. The models differ in whether canals exist and whether water is ever pumped from a canal back into the river.

**[ANIMATION]** step: rel.state-1

Where the picture breaks: water mixes, and commits do not. A fix that is cherry-picked into a canal is a second commit with a second ID, and Git records no link between the two. The next video is about that.

## DIAGRAM

**[ANIMATION]** step: ghf.between

**[DIAGRAM]** First, GitHub Flow, the diagram of section 27.6. Draw `main` as one line. Add three short feature branches that leave and return. Mark two tags on `main`, and the hotfix as one more short branch.

```text
              o---o   feature/streaming            o   hotfix/suspended-tenant
             /     \                              / \
    ---o----o-------M1------M2------M3-----------o---M4---   main      (HEAD -> main)
                     \     /  ^      ^                ^
                      o---o   |      |                |
              feature/tenant-limits  |                tag v1.4.1, deploy
                              |      feature/batch-api merged
                              tag v1.4.0, deploy
```

A question for you: what is between the two tags on `main`? The hotfix, and also the merge M3. Hold that thought for video 172.

**[ANIMATION]** step: gl.state-1

**[DIAGRAM]** Now the four diagrams of section 27.8, one at a time. GitLab Flow with a production branch:

```text
    ---o---o---o---o---o---o   main          every merge deploys to staging
                \       \
    -------------M-------M     production    a merge from main deploys to production
```

Now the four diagrams of section 27.8 again. GitLab Flow with a production branch: every merge deploys to staging, and a merge from `main` deploys to production.

**[ANIMATION]** step: tbd.state-1

```text
    ---o---o---o---o---o---o---o---o---   main (trunk)
        \_/     \_/ \_/         \_/        branches that live hours to two days
```

Trunk-based development: branches that live hours to two days.

**[ANIMATION]** step: rel.state-1

```text
    ---o---o---o---o---F---o---o---   main          F = the fix, made on main first
                \       \
                 o-------F'           release/1.4   F' = cherry-pick of F
                 ^       ^
              v1.4.0   v1.4.1
```

A release branch, with the fix made on `main` first, and its cherry-pick on the branch.

**[ANIMATION]** step: rf.state-1

```text
    ---o---o---o---o---o---F---o---o---o---   main
            \               \       \
             o               F'      o        releases/M129, then releases/M130
          releases/M128   (hotfix cherry-picked to M129)
```

Microsoft's Release Flow: the hotfix is cherry-picked to M129.

**[ANIMATION]** graph: [a branch per version] *1-*2-*3-*4-F-*5-*6 main; *3-*7-F′ release/1.4; HEAD=none || [a branch per sprint] *1-*2-*3-*4-*5-F-*6-*7-*8 main; *3-*9 releases/M128; *5-F′ releases/M129; *7-*10 releases/M130; HEAD=none layout=rows title=The_same_graph dy=80

Put the last two side by side: it's the same graph, with a branch per version in one and a branch per sprint in the other.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch27/git-flow`. The project is `promptgate` again, with the same changes as in the other demos of the chapter, arranged as Git Flow prescribes. Two features have been merged into `develop`, each with `--no-ff`; a third is merged after the release.

Into the lab. The project is the gateway `promptgate`, arranged as Git Flow prescribes: features are merged into `develop`, each with `--no-ff`.

**Step 1: the release branch.** 🟡 CAUTION: `git merge` moves the current branch. `--no-ff` always creates a merge commit.

```bash
git switch -c release/1.4.0 develop
printf '1.4.0\n' > VERSION
git commit -q -am "Bump version to 1.4.0"
git switch -q main
git merge --no-ff -m "Release 1.4.0" release/1.4.0
git tag -a v1.4.0 -m "promptgate 1.4.0"
git switch -q develop
git merge --no-ff -m "Merge release/1.4.0 back into develop" release/1.4.0
git branch -d release/1.4.0
```

Predict: how many merge commits does one release create, and on which branches? Say it out loud.

**[PAUSE]**

<!-- snippet: ch27/git-flow/01-release-branch -->
```text
# Features were merged into develop, not main. A release branch stabilizes them:
$ git switch -c release/1.4.0 develop
Switched to a new branch 'release/1.4.0'
$ printf '1.4.0\n' > VERSION
$ git commit -q -am "Bump version to 1.4.0"
$ git switch -q main
$ git merge --no-ff -m "Release 1.4.0" release/1.4.0
Merge made by the 'ort' strategy.
 VERSION           | 2 +-
 gateway/limits.py | 3 ++-
 gateway/stream.py | 3 +++
 3 files changed, 6 insertions(+), 2 deletions(-)
 create mode 100644 gateway/stream.py
$ git tag -a v1.4.0 -m "promptgate 1.4.0"
# The release branch is merged back so that develop has the version bump too:
$ git switch -q develop
$ git merge --no-ff -m "Merge release/1.4.0 back into develop" release/1.4.0
Merge made by the 'ort' strategy.
 VERSION | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git branch -d release/1.4.0
Deleted branch release/1.4.0 (was 7237206).
```
<!-- /snippet -->

Two: one on `main`, which is tagged, and one on `develop`, so that `develop` has the version bump too. The release branch is then deleted. Its tip `7237206` stays reachable through both merges.

**Step 2: the hotfix.** It starts from `main`, which is what production runs, not from `develop`.

```bash
git switch -c hotfix/1.4.1 main
git commit -q -am "Fix limit 0 being treated as unlimited"
git switch -q main
git merge --no-ff -m "Hotfix 1.4.1" hotfix/1.4.1
git tag -a v1.4.1 -m "promptgate 1.4.1"
git switch -q develop
git merge --no-ff -m "Merge hotfix/1.4.1 into develop" hotfix/1.4.1
git branch -d hotfix/1.4.1
```

<!-- snippet: ch27/git-flow/02-hotfix -->
```text
# A hotfix starts from main (what production runs), not from develop:
$ git switch -c hotfix/1.4.1 main
Switched to a new branch 'hotfix/1.4.1'
$ git commit -q -am "Fix limit 0 being treated as unlimited"
$ git switch -q main
$ git merge --no-ff -m "Hotfix 1.4.1" hotfix/1.4.1
Merge made by the 'ort' strategy.
 VERSION           | 2 +-
 gateway/limits.py | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git tag -a v1.4.1 -m "promptgate 1.4.1"
$ git switch -q develop
$ git merge --no-ff -m "Merge hotfix/1.4.1 into develop" hotfix/1.4.1
Merge made by the 'ort' strategy.
 VERSION           | 2 +-
 gateway/limits.py | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
$ git branch -d hotfix/1.4.1
Deleted branch hotfix/1.4.1 (was 1607dca).
```
<!-- /snippet -->

Again two merges. The fix itself is one commit, `1607dca`.

**Step 3: the graph.** 🟢 SAFE. Predict before it prints: where will you find the hotfix commit, and how many children will it have?

**[PAUSE]**

```bash
git log --oneline --graph --decorate --all
```

<!-- snippet: ch27/git-flow/03-graph -->
```text
$ git log --oneline --graph --decorate --all
*   24124ab (HEAD -> develop) Merge hotfix/1.4.1 into develop
|\  
* \   f2b87da Merge pull request #43 from feature/batch-api
|\ \  
| * | b713222 Add batch endpoint
|/ /  
* |   989ca76 Merge release/1.4.0 back into develop
|\ \  
| | | *   a3de55c (tag: v1.4.1, main) Hotfix 1.4.1
| | | |\  
| | | |/  
| | |/|   
| | * | 1607dca Fix limit 0 being treated as unlimited
| | |/  
| | *   2a0387c (tag: v1.4.0) Release 1.4.0
| | |\  
| | |/  
| |/|   
| * | 7237206 Bump version to 1.4.0
|/ /  
* |   7d9c521 Merge pull request #42 from feature/tenant-limits
|\ \  
| * | c3cc79e Read tenant limits with a default
| |/  
* |   e27adc8 Merge pull request #41 from feature/streaming
|\ \  
| |/  
|/|   
| * 39a039a Stream tokens to the client
|/  
* b6e2f58 (tag: v1.3.0) Add per-tenant rate limits
* 9df3d07 Add gateway skeleton
```
<!-- /snippet -->

Take your time. This graph is hard to read, and that's part of the lesson. Find `1607dca`, and count its children. I'll wait.

**[PAUSE]**

It has two children: the merge `a3de55c` on `main`, tagged `v1.4.1`, and the merge `24124ab` on `develop`. That double merge is the model's answer to "how does a fix reach both lines". It's a merge-upward answer: one commit, one ID, reachable from both branches.

**Step 4: what shipped.**

```bash
git log --oneline --no-merges v1.4.0..v1.4.1
git log --oneline --first-parent main
git rev-list --count --merges v1.3.0..develop
git branch --contains v1.4.1^2
```

<!-- snippet: ch27/git-flow/04-what-ships -->
```text
$ git log --oneline --no-merges v1.4.0..v1.4.1
1607dca Fix limit 0 being treated as unlimited
$ git log --oneline --first-parent main
a3de55c Hotfix 1.4.1
2a0387c Release 1.4.0
b6e2f58 Add per-tenant rate limits
9df3d07 Add gateway skeleton
$ git rev-list --count --merges v1.3.0..develop
6
$ git branch --contains v1.4.1^2
* develop
  main
```
<!-- /snippet -->

Four readings. The patch release contains the fix and nothing else, because `main` receives only releases and hotfixes. `git log --first-parent main` is a release log, one line per release. The history between `v1.3.0` and `develop` contains six merge commits for three features, one release and one hotfix. And the second parent of the hotfix merge, the fix itself, is contained in both `develop` and `main`.

So the model delivers what it promises: a clean patch release and a readable release log. The price is on the third line.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Treating a branch name as a control.** Root cause: Git gives no meaning to a name; only a platform setting, a ruleset pattern or automation that triggers on the pattern gives it force.
2. **Adopting Git Flow for a continuously deployed service.** Root cause: the model was conceived for explicitly versioned software with several supported versions, and a service with one live version has nothing for `develop` and release branches to separate.
3. **Calling GitHub Flow and trunk-based development opposites.** Root cause: both have one long-lived branch; the difference is a limit on branch lifetime and, in the strictest form, the pre-merge review gate.
4. **Forgetting the merge back in Git Flow.** Root cause: a release or hotfix lives on two long-lived branches, and the model needs a second merge to carry it to `develop`; nothing in Git reminds you.
5. **Naming a release branch inconsistently.** Root cause: rules and deployment workflows select branches by pattern, so a branch outside the pattern is outside the rule.

## PRODUCTION EXAMPLE

Now, out of the lab. A company runs an LLM gateway as a hosted service and deploys from `main` after every merge. It uses GitHub Flow and has never needed more. Then two enterprise customers sign contracts to run the gateway on their own hardware and to stay one version behind. This is the first question of the chapter: does the branching model survive that?

**[ANIMATION]** step: sort.path

The staff engineer doesn't propose Git Flow. She applies the sorting question. Until now one version was alive. Next quarter there will be three. Something has to name the two older ones, so the team adds release branches, cut from `main` late, named by one pattern, `release/<version>`, with one ruleset on that pattern. `main` stays the only integration branch, and no `develop` is introduced, because the hosted service still deploys from `main` and the tags already record what was released. She writes the scheme into `CONTRIBUTING.md`, including the direction a fix travels, which is the subject of the next video.

## PRACTICE EXERCISE

Your turn. Do Exercise 32.1, Level 1, "Names and what gives them force", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

Before you answer each item, predict in one line what Git itself does with the name in question, and then what, if anything, on the platform or in automation gives it force. Check your answers against the table of section 27.5 only after you have written them all.

The challenge is Exercise 32.2, Level 2, "Six teams, which model?", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q350: "A new engineering manager wants to standardize on Git Flow for your continuously deployed hosted service because it is "the industry standard". What does Git Flow prescribe, what does its own author say about it, and what do you propose instead?"

**[PAUSE]**

Answer out loud. The question has three parts, and a strong answer gives each its own paragraph. The first is a precise description: which long-lived branches, which supporting branches, which merges in which direction, where the tags go. The second reports the author's 2020 note accurately, as a restriction on where the model fits, not as a retraction. The third is a proposal that starts from the team's delivery situation, says what the proposal assumes, and says on which day it would have to change. Do it without contempt for the proposal. The manager's last company may have shipped versioned software.

## RECAP

Let's land this, in your own words.

- A branch name means nothing to Git; a default-branch setting, a ruleset pattern or a workflow filter gives it force.
- GitHub Flow is one always-deployable branch with short branches and deployment after merge, and it assumes one live version.
- Git Flow is `main` plus `develop` plus feature, release and hotfix branches with merges in two directions; its author restricted it in 2020 to explicitly versioned software with several supported versions.
- Trunk-based development limits branch lifetime to a couple of days; release branches are cut late from the trunk, receive only fixes and are never merged back.
- The question that sorts the models is how many versions are alive at once.

## HOMEWORK

Read sections 27.5 to 27.8. Then read `git help workflows`, the Git project's own workflow document, which the chapter cites. Note what it says about the branch on which a fix is committed. You'll need that sentence in the next video, where one release and one hotfix are run under two strategies.

Today you turned five well-known names into five graphs, and you can answer that meeting with reasons instead of a preference. Draw each graph once from memory. Next time: one release and one hotfix under two strategies, and which way a fix travels. Until then, look at the state first and type second. See you in the next one.
