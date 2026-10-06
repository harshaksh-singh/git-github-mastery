# V141: Gate briefing: GitHub

- **Part.** 5: GitHub
- **Module.** 25
- **Planned minutes.** 10
- **Prerequisites.** V122, V129, V130, V136, V139, V140
- **Textbook sections.** [Chapter 17](../../textbook/ch17-pull-requests.md), section 17.3; [Chapter 18](../../textbook/ch18-branch-protection.md), section 18.17; the rules in [`assessments/README.md`](../../assessments/README.md)
- **Demo scripts.** `labs/ch17/pr-anatomy.sh` (snippets `commit-list`, `merge-base`, `three-dot`, `two-dot`)

## HOOK

**[ON SCREEN]** One line: "The pull request is green and approved, and GitHub will not merge it. Explain."

That is the kind of sentence Gate 6 is built from. You will have no browser, no repository on GitHub and no `gh` beyond its help text. You will have configuration files, a described situation and real Git evidence. The answer that earns the points says, for every fact, which layer it belongs to.

## INTRODUCTION

This is a briefing, not a lesson. It tells you what Gate 6 covers, how it is taken, how its hands-on part differs from the gates you have sat so far, and how to prepare. It does not open the gate file or the case files, and you should not either. The assessment rules say it directly: a gate that has been read is a gate that has been taken.

## LEARNING OBJECTIVES

After this video you can:

- state what Gate 6 covers and its threshold of 85;
- explain how the hands-on part differs: three cases on paper;
- name the layer, Git or GitHub, of every fact in an answer;
- prepare with the procedures: the authentication decision tree, pull request anatomy, and "why can't I merge".

## CONCEPT

**What the gate covers.** Gate 6 is taken after Module 25. It covers the platform model, authentication, pull requests, merge methods, rulesets, CODEOWNERS, signing and the CLI. It passes at 85.

**The four parts.** Like every gate it has 100 points in four parts with fixed weights. Concepts: 30 points, six written questions, closed book, no terminal; each requires a mechanism. Prediction: 20 points, four items, no terminal. Hands-on diagnosis: 30 points. Oral interview: 20 points, six questions asked one at a time, each with a follow-up, spoken, without notes.

**The pass rule.** The threshold overall, and at least 70 percent in every part: 21 of 30 in Concepts, 14 of 20 in Prediction, 21 of 30 in Hands-on, 14 of 20 in Oral. A total above the threshold with one part below 70 percent is a miss.

**What is different in Part 3.** In gates 1 to 5 a script built a broken repository and you repaired it in the lab shell. Gates 6 to 8 cannot work that way, because GitHub's behavior cannot be captured in the lab. So Part 3 is three cases on paper, built from configuration files, described situations and real Git evidence.

**[ON SCREEN]** The rule for paper cases from `assessments/README.md`.

The rule reads: these gates run nothing on GitHub; no GitHub output appears anywhere in them; and the only `gh` invocation you need is `gh` with a command and `--help`. For the paper cases the gate file gives the points per case.

**The layer rule.** An answer that does not say which layer acted loses points. This is the habit the whole of Part 5 was meant to build. "The branch is behind" is a Git fact; you can prove it with a command. "The merge is blocked because the branch is behind" is a GitHub decision, made by a rule that someone configured. Say both halves, and say which is which.

## MENTAL MODEL

Use one form for every case: two columns.

On the left, "Git says". Everything here is something a clone can show: ancestry, the merge base, the commits a pull request introduces, the paths it changes, whether a commit has a signature header, which version of a file exists on which branch.

On the right, "GitHub says". Everything here is platform state or a platform decision: which rules apply, the review decision, which checks are required and whether a result exists for the newest commit, which CODEOWNERS file is read, what a badge displays, which merge methods are allowed.

Then the finding: one sentence that connects a line on the left to a line on the right.

Where this form falls short: some facts need both columns to state at all. "Stale approval" is a platform concept defined by a Git event, a push that changed the diff. Write those across both columns and say so.

Three procedures from this part give you the rows. The authentication decision tree, for any case that starts with a refused connection or a refused push. The anatomy of a pull request, for any case about unexpected commits or an unexpected diff. And the nine steps of "why can't I merge" from V134.

## DIAGRAM

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

**[DIAGRAM]** Notice the last two lines. A complete answer does not stop at the cause. It says what the repair costs, in the layer where the cost arises.

## LIVE TERMINAL DEMO

**[TERMINAL]** A warm-up: Git evidence of the kind the paper cases contain. Replay with `labs/run ch17/pr-anatomy`. Every command reads; `git fetch`, which the replay starts with, is 🟢 SAFE. The IDs equal the book's.

**Step 1: the commit list.**

```bash
git log --oneline origin/main..feature/priority-routing
git rev-list --count origin/main..feature/priority-routing
```

**[PAUSE]** Which tab of a pull request does this range correspond to?

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

`9a383e5`, "Add classifier test". Write the merge base down in every case that involves a diff. Half the surprises of Chapter 17 are a merge base that is not where the author thinks it is.

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

**[PAUSE]** `main` has one commit that the branch does not have. How many files will the two-dot form list, and in which direction will that commit's change appear?

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

Three files. `config/routing.yaml` appears although the pull request never touched it, and the change is reversed: the threshold seems to go from 0.7 back to 0.6. Two dots compare the two tips. If a case shows you a diff with a file the author did not change, this is your first question: which two commits were compared?

In the gate, evidence like this is printed for you. Your work is to read it and place it in the left column.

## COMMON MISTAKES

1. **Answering with a repair before naming the cause.** Root cause: the case asks which rule refused and which fact it looked at, and a repair without that is a guess.
2. **Not naming the layer.** Root cause: Git computes facts and GitHub applies rules to them, and an answer that merges the two cannot say who must change what.
3. **Reading a two-dot diff as "what the pull request changes".** Root cause: two dots compare the two tips; the pull request shows the merge base compared with the head.
4. **Opening the gate file "to see what is in it".** Root cause: the gate measures what you can do unseen, so reading it spends the attempt.
5. **Treating the workflow and configuration files of a paper case as examples to reuse.** Root cause: the files in the gate directories are teaching material with faults on purpose.

## PRODUCTION EXAMPLE

A backend team's incident channel, on a Friday. A developer reports that a hotfix cannot be merged. The engineer on call answers in the two-column form, in four lines: what the clone shows, what the rules page shows, the one rule that is unmet, and what the repair will trigger. The developer updates the branch, waits for the one check, and merges. Nobody asked an administrator to bypass anything.

That is what the gate is rehearsing. An answer in that form can be acted on by someone who was not in the conversation.

## PRACTICE EXERCISE

Redo the Level 4 exercises of the block in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md): Exercise 20.6, "Three faults, no connection"; Exercise 21.6, "Five commits for a two-commit fix"; and Exercise 22.5, "The release that does not contain its fix". Then the two at Level 5: Exercise 23.8, ""Main is protected. How did a force push get through?"", and Exercise 24.6, "Verified, and she was on a plane".

For each, before you write anything else, draw the two columns and predict which column the decisive fact will be in.

When you are ready, take Gate 6: [`assessments/gate-6-github.md`](../../assessments/gate-6-github.md). One sitting, parts in order.

## INTERVIEW QUESTION

**[ON SCREEN]** Q259: "A required status check is green on a pull request. What does that prove, and what does it not prove?"

A strong answer is exact about the object of the proof: which commit the result is attached to, and what was tested to produce it. Then it lists what lies outside: what has happened to the base since, who is able to report a check of that name, and what a green check says about review. The follow-up is about strict mode on a busy branch: name what it costs, and what the answer is when that cost bites.

## RECAP

You should now be able to say:

- Gate 6 covers the platform model, authentication, pull requests, merge methods, rulesets, CODEOWNERS, signing and the CLI, and passes at 85 with at least 70 percent in every part.
- Its hands-on part is three cases on paper; nothing runs on GitHub and no GitHub output appears.
- Every fact in an answer carries its layer: "Git says" or "GitHub says".
- The preparation is three procedures: the authentication decision tree, pull request anatomy, and "why can't I merge".

## HOMEWORK

Before the gate: answer the "Interview questions" sections of Chapters 15 to 19 aloud. Read [`reference/github-reference.md`](../../reference/github-reference.md).
