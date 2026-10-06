# V045: Gate briefing: Branching

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 7, Remote operations (briefing before Gate 2)
- **Planned minutes:** 10
- **Prerequisites:** V026, V044
- **Textbook sections:** [Chapter 7](../../textbook/ch07-branches.md), section 7.8; [Chapter 12](../../textbook/ch12-remote-operations.md), sections 12.4 and 12.7; gate rules in [`assessments/README.md`](../../assessments/README.md)
- **Demo scripts:** `labs/ch12/fetch-anatomy.sh` (warm-up only)

## HOOK

**[ON SCREEN]** "Is your branch up to date?"

One question decides more points in Gate 2 than any other: "what does the server have?" There are two ways to answer it. One reads a ref, a name such as a branch that holds a commit ID, in your own clone, your copy of the repository. The other asks the server, the repository the team shares. Today you watch both answers, one wrong and one right, and you fix the habit before the gate tests it. Which is your habit today? The demo checks it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a gate briefing, not a lesson. A gate is the examination that ends a block of the course. The briefing explains what Gate 2 covers, how it's scored, and how to prepare. It shows no gate item, and the gate file isn't opened on screen. The rule from the assessments file applies: a gate that has been read is a gate that has been taken.

You take Gate 2 after Module 7. If you've done the labs of Modules 6 and 7 by hand, you've already practised everything it asks.

## LEARNING OBJECTIVES

**[ON SCREEN]** The four objectives.

After this briefing you can:

- State what Gate 2 covers and its threshold of 90.
- Explain why the threshold is higher than for Gate 1.
- Prepare the prediction part by drawing graphs with local and remote-tracking refs.
- Run the hands-on part with the ritual first and the server asked directly.

## CONCEPT

**[ON SCREEN]** The Gate 2 row of the table in `assessments/README.md`.

Gate 2, Branching. Pass at 90. Taken after Module 7. It covers branches as refs, divergence, ancestry, upstream tracking, remote-tracking refs, fetch, pull and push.

**[ANIMATION]** walk: columns=part,points,at_least rows=Concepts:30:21|Prediction:20:14|Hands-on_diagnosis:30:21|Oral_interview:20:14 mono=off title=Gate_2:_100_points_in_four_parts

**[ANIMATION]** step: 4

The structure is the same as Gate 1: 100 points in four parts. Concepts, 30 points: six written questions, closed book, no terminal, and each answer needs a mechanism. Prediction, 20 points: four items, no terminal, and object IDs aren't asked for. Hands-on diagnosis, 30 points, in a repository that a script builds in a broken state, with a report that's incomplete and partly wrong. Oral interview, 20 points: six questions, each with a follow-up.

**[ANIMATION]** say: To_pass:_90_overall,_and_at_least_70_percent_in_every_part

The pass rule: the threshold overall, and at least 70 percent in every part. That is 21 of 30, 14 of 20, 21 of 30 and 14 of 20. A total above 90 with one part below 70 percent is a miss.

**[ANIMATION]** end

Why 90 here, and 85 for Gate 1? The assessments file gives the numbers, and the roadmap fixed them. Think of it this way. Up to Gate 1, every command you ran affected one repository, yours. From this block on, commands reach a repository that other people share, and an error with `push` isn't private. So the gate asks for more, and in the hands-on part it scores the safety of your path, not only the end state.

**[ANIMATION]** cards: question=Hands-on_diagnosis:_30_points,_split_three_ways cards=The_end_state:check.sh_inspects_it|The_safety_of_the_path:read_from_your_command_log|The_explanation:written_as_root-cause_boxes numbered=on at_1=8 at_2=24 at_3=38

The hands-on points are split three ways. The end state, which `check.sh` inspects. The safety of the path, read from your command log. And the explanation, written as root-cause boxes. The file says it plainly: a correct end state reached through `git reset --hard`, a forced push or a re-clone can still fail the safety row.

**[ANIMATION]** end

And the two typical ways to lose points in this gate. First, trusting a remote-tracking ref, your clone's record of where a server branch was, as if it were the server. Second, repairing with force where an integration was possible.

## MENTAL MODEL

**[ON SCREEN]** "For every ref in the problem: which repository does it live in?"

One sentence to take into the room. For every ref in a problem, say which repository it lives in before you say anything else.

**[ANIMATION]** remotes: ids=510ee94,ef22149 start=1 steps=setup,teammate-push,fetch title=Three_repositories,_four_refs

`main` in your clone, `origin/main` in your clone, `main` on the server, `main` in a teammate's clone. Four refs, three repositories, and two of the four are in the same `.git`.

**[ANIMATION]** step: teammate-push

`origin/main` is a dated photograph of the server's `main`. It was accurate when it was taken. Now a teammate pushes, and in your clone nothing moves. The photograph doesn't update itself, and looking at it harder doesn't help.

**[ANIMATION]** graph: *1-*2-*3 A; *2-*4-*5 B; HEAD=none; say:Diverged:_neither_tip_is_an_ancestor_of_the_other => + note:*2:merge_base; say:Ahead_and_behind_are_counted_from_the_merge_base => + range:*4,*5:A..B; say:A..B:_reachable_from_B_but_not_from_A; name:reachable

For ancestry questions, use section 7.8 of the textbook. Two branches have diverged when neither tip is an ancestor of the other. Ahead and behind are counted from the merge base. And `A..B` is everything reachable from B but not from A. State the base every time: "3 commits ahead" is meaningless until you say ahead of what.

## DIAGRAM

**[DIAGRAM]** New diagram. Draw the three boxes, each with its own `main`. Then, inside your clone, draw `origin/main` with a date stamp, and a dotted line to the server's `main`.

```text
  your clone                        server                      teammate's clone
  +----------------------------+    +--------------------+      +----------------------------+
  | refs/heads/main            |    | refs/heads/main    |      | refs/heads/main            |
  |                            |    |        ^           |      |                            |
  | refs/remotes/origin/main . | . .|. . . . :           |      | refs/remotes/origin/main   |
  |   [photograph, taken at    |    |                    |      |   [their photograph,       |
  |    your last fetch]        |    |                    |      |    their last fetch]       |
  +----------------------------+    +--------------------+      +----------------------------+

  moved by you          moved by Git when it talks      moved by whoever pushes there
  (commit, merge, ...)  to the remote (fetch, pull,
                        a successful push)
```

In the prediction part, draw this before you answer. Put every ref of the item into one of the boxes. Most wrong predictions come from a ref drawn in the wrong box.

**[ANIMATION]** cards: question=Four_refs,_three_boxes._Which_box_holds_two? cards=your_clone|the_server|a_teammate's_clone marks=1:ok id=boxes

**[ANIMATION]** step: boxes.3

Try it now, thirty seconds, on paper. Draw the three boxes and place those four refs. Which box holds two? Say it out loud.

**[PAUSE]**

**[ANIMATION]** step: boxes.marks

Your clone: `main` and `origin/main`. The name tempts you to draw `origin/main` on the server. It lives in your clone.

## LIVE TERMINAL DEMO

**[TERMINAL]** Warm-up only: `labs/run ch12/fetch-anatomy`, first four snippets. You have seen it in V039. Watch it now as an examiner would.

The question is "what does the server have?" First answer:

```bash
git status
git show-ref --abbrev
```

<!-- snippet: ch12/fetch-anatomy/01-stale-status -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
$ git show-ref --abbrev
510ee94 refs/heads/main
510ee94 refs/remotes/origin/HEAD
510ee94 refs/remotes/origin/main
```
<!-- /snippet -->

"Up to date with 'origin/main'." Both refs at `510ee94`, both in this clone. This answered a different question. Now predict: is the server's `main` at `510ee94` too? Say it out loud. I'll wait.

**[PAUSE]**

Second answer:

```bash
git ls-remote origin
```

<!-- snippet: ch12/fetch-anatomy/02-ls-remote -->
```text
$ git ls-remote origin
ef22149d97a296904ccbf984cf520a1fc387e195	HEAD
698e2261b0e2c60654fc059c6016c8d743a05571	refs/heads/feature/reranker
ef22149d97a296904ccbf984cf520a1fc387e195	refs/heads/main
effd2621f6264b45f395c4ba776533482d6f466b	refs/tags/v0.1.0
ef22149d97a296904ccbf984cf520a1fc387e195	refs/tags/v0.1.0^{}
```
<!-- /snippet -->

The server's `main` begins with `ef22149`. That's the answer to the question that was asked, and asking the server is the habit to build.

Quick quiz. `git fetch` is next. Which refs in your clone move? A, your `main`. B, only remote-tracking refs. C, both. Your answer?

**[PAUSE]**

B. `git fetch` 🟢 SAFE moves only remote-tracking refs. Watch it, and then the status again.

<!-- snippet: ch12/fetch-anatomy/03-fetch -->
```text
$ git fetch
From ../../server/support-bot
   510ee94..ef22149  main             -> origin/main
 * [new branch]      feature/reranker -> origin/feature/reranker
 * [new tag]         v0.1.0           -> v0.1.0
$ cat .git/FETCH_HEAD
ef22149d97a296904ccbf984cf520a1fc387e195		branch 'main' of ../../server/support-bot
698e2261b0e2c60654fc059c6016c8d743a05571	not-for-merge	branch 'feature/reranker' of ../../server/support-bot
effd2621f6264b45f395c4ba776533482d6f466b	not-for-merge	tag 'v0.1.0' of ../../server/support-bot
```
<!-- /snippet -->

<!-- snippet: ch12/fetch-anatomy/04-after -->
```text
$ git show-ref --abbrev
510ee94 refs/heads/main
ef22149 refs/remotes/origin/HEAD
698e226 refs/remotes/origin/feature/reranker
ef22149 refs/remotes/origin/main
effd262 refs/tags/v0.1.0
$ git status
On branch main
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
```
<!-- /snippet -->

Behind by one commit. Nothing of yours moved, and now the local view is true.

**[ANIMATION]** step: fetch

As a picture: one label moved, `origin/main`. Your `main` didn't.

**[ON SCREEN]** The "How a gate is taken" steps from `assessments/README.md`.

For the hands-on part, run the generator of variant A, which prints the sandbox path. Open the lab shell there, and read `SYMPTOMS.md`. Don't read `generate.sh` or `check.sh`. Keep a log of every command.

Start with the diagnosis ritual from Chapter 1, as in Gate 1. Then add two commands from this block before you change anything: `git branch -vv` for every branch's upstream, and `git ls-remote` for the server itself. And `git log --oneline --graph --decorate --all` gives you the graph with every ref on it.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each with its root cause.

1. **Answering "what does the server have" from `git status`.** Root cause: `status` compares two local refs and opens no connection.
2. **Fixing a rejected push with `--force`.** Root cause: `rejected` meant the server's tip was not an ancestor of yours; an integration was possible, and the safety of the path is scored.
3. **Changing state before collecting evidence.** Root cause: the command log is read for evidence before change and a way back before each rewrite.
4. **Scoring 92 overall with 13 in Prediction.** Root cause: the pass rule needs 70% in every part.
5. **Opening the gate file "to see what is in it".** Root cause: a gate that has been read is a gate that has been taken.

## PRODUCTION EXAMPLE

**[ANIMATION]** gates: packet=the_commit_to_tag gates=git_fetch:done:the_release_script:it_begins_here|ls-remote_check:pass:the_release_script:refuses_to_continue_unless_equal result=the_tag title=The_release_engineer's_habit at_1=22 at_2=36 at_result=48

Now, out of the lab. The habit this gate checks is the release engineer's habit from video 39: a release script that begins with `git fetch`, and refuses to continue unless the commit it's about to tag equals what `git ls-remote` reports for the server's `main`. And the engineer's habit from video 41: reading whether a refusal says `rejected` or `remote rejected` before doing anything. If you would act that way on a release day, you'll act that way in Part 3.

## PRACTICE EXERCISE

Your turn. Redo three exercises without notes, all in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md):

- Exercise 6.9, Level 4, "a merge that somebody else left half done".
- Exercise 7.9, Level 4, "a clone that has not talked to the server for a week".
- Exercise 7.10, Level 5, "the hotfix that was pushed and is not on the server".

For each, before the first command, draw the three boxes and place every ref. Then write your prediction for the first two commands you intend to run.

When all three go through without notes, take Gate 2: [`assessments/gate-2-branching.md`](../../assessments/gate-2-branching.md). One sitting, parts in order.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q92: "What is the difference between HEAD, a branch and a remote-tracking branch?"

**[PAUSE]**

Answer out loud. A strong answer says, for each of the three, what it is in storage, in which repository it lives, and what moves it. It doesn't use the word "pointer" for all three and stop. The follow-up in an oral part will probe exactly the one you described most vaguely.

## RECAP

**[ANIMATION]** step: fetch

Let's land this. You should now be able to say:

Gate 2 covers branches as refs, divergence, ancestry, upstream tracking, remote-tracking refs, fetch, pull and push. I pass at 90 overall, with at least 70 percent in each of the four parts. In the hands-on part, the end state, the safety of the path and the explanation are scored separately. I place every ref in its repository before I reason about it, and I ask the server directly instead of trusting a remote-tracking ref. After a miss I get the remediation map and variant B, not the answers.

## HOMEWORK

Before the gate: answer the "Interview questions" sections of Chapters 7, 8 and 12 aloud.

You now know what Gate 2 asks, and the habit it tests hardest. Practise before you sit it. Next time: the undo map, and `git restore`. Until then, look at the state first and type second. See you in the next one.
