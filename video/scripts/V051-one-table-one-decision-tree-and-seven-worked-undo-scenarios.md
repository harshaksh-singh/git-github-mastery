# V051: One table, one decision tree, and seven worked undo scenarios

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 8, Undoing changes
- **Planned minutes:** 18
- **Prerequisites:** V049, V050
- **Textbook sections:** [Chapter 11](../../textbook/ch11-reset-revert-restore.md), sections 11.12 and 11.13
- **Demo scripts:** `labs/ch11/scenarios.sh`

## HOOK

**[ON SCREEN]** A chat message: "how do I undo this??"

Someone on your team sends you that message, with a screenshot of a terminal. They're a little stressed, and they want one command.

You now know five undo commands and a dozen forms of them. The risk is that you answer with the first one that fits. A senior answer doesn't start with a command. It starts with a question: "Has anyone else got that commit?" Then one command, with its risk stated. Hold on to that question. By scenario seven it should come out before you think.

This video trains exactly that reflex, seven times.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the consolidation video of the undo module. There's no new mechanism in it. Everything was taught in the last five videos: restore, reset and its modes, amend, revert, reverting a merge, clean and stash.

What is new is that it all goes onto one page. One table that says, for each command, what happens to HEAD, the branch, the index, the working tree and history. One decision tree that leads from "what do you want to undo" to a command. And then seven situations, in a clone whose `origin` is a bare repository on disk, a repository with no working tree that plays the server. So "pushed" is a real state and not a story.

The format for the scenarios: you see the situation, you choose, and only then you see the command. Pause the video each time. Choosing is the exercise.

## LEARNING OBJECTIVES

**[ON SCREEN]** The four objectives.

After this video you can:

- Choose the lowest-risk undo for a described situation, and state its effect on HEAD, the branch, the index, the working tree and history.
- Justify the choice by whether the history is shared.
- Carry out seven standard scenarios and verify the end state.
- Name the choice that would have been wrong, and why.

## CONCEPT

**[ON SCREEN]** The table of section 11.12, built up in three groups: the resets, the restores, then amend and revert.

In this table, "HEAD" is the commit that HEAD resolves to, "Branch" is the ref of the current branch, and "History" is the set of commits reachable from that branch.

```text
Command                                  HEAD                    Branch               Index             Working tree                         History
---------------------------------------  ----------------------  -------------------  ----------------  -----------------------------------  ---------------------------------
git reset --soft <commit>                moves to <commit>       set to <commit>      unchanged         unchanged                            commits after <commit> leave the
                                                                                                                                             branch; the reflog keeps them
git reset --mixed <commit> (default)     moves to <commit>       set to <commit>      matches <commit>  unchanged                            as above
git reset --hard <commit>                moves to <commit>       set to <commit>      matches <commit>  matches <commit>; uncommitted        as above
                                                                                                        changes destroyed
git reset --keep <commit>                moves to <commit>       set to <commit>      matches <commit>  local changes carried across;        as above
                                                                                                        refuses if they overlap
git reset --merge <commit>               moves to <commit>       set to <commit>      matches <commit>  unstaged carried across, staged      as above
                                                                                                        discarded
git reset -- <path>                      unchanged               unchanged            <path> from HEAD  unchanged                            unchanged
git restore <path>                       unchanged               unchanged            unchanged         <path> from the index                unchanged
git restore --staged <path>              unchanged               unchanged            <path> from HEAD  unchanged                            unchanged
git restore --source=<commit> <path>     unchanged               unchanged            unchanged         <path> from <commit>                 unchanged
git restore --staged --worktree <path>   unchanged               unchanged            <path> from HEAD  <path> from HEAD                     unchanged
git commit --amend                       moves to a new commit   set to the new       unchanged         unchanged                            the last commit is replaced by a
                                                                 commit                                                                      new one with the same parent
git revert <commit>                      moves to a new commit   advanced by one      matches the new   inverse change applied               one commit added, none removed
                                                                 commit               commit
```

Don't try to memorize twelve rows. Learn how to read the table.

Read the Branch column first. There are three words in it. "Set to" means the branch can lose commits: private history only. "Advanced" and "unchanged" are safe on a branch that other people have.

Then read the Working tree column for the word "destroyed" and the phrase "from the index" or "from a commit". Those are the rows where content that no object holds can be overwritten.

Two columns, two questions. Is the branch allowed to lose commits? Can I afford to lose what is on disk?

Try it now, thirty seconds. Find the row for `git revert`, and read its Branch cell out loud. Safe on a branch that other people have, or not?

**[PAUSE]**

"Advanced by one". So yes, it's safe: the branch only moves forward.

**[ANIMATION]** decide: nodes=q1:What_do_you_want_to_undo?|u:restore,_stash_or_clean|q2:Can_anyone_else_already_have_them?|n:private_history:_rewriting_is_allowed|y:shared_history:_add_commits edges=q1>u:changes|q1>q2:commits|q2>n:NO|q2>y:YES title=The_undo_decision_tree id=tree

**[ANIMATION]** step: tree.level-3

Now the decision tree, which is today's diagram. It asks three questions in order. What do you want to undo: uncommitted changes, or commits? If commits: can anyone else already have them? And then: which of them, and do you want to keep the changes?

**[ANIMATION]** say: How_to_answer_it:_git_fetch,_then_git_branch_-r_--contains_<commit>

Notice where the publication question sits. It isn't asked for uncommitted changes, because nobody else can have those. It's the first thing asked for commits, and the tree tells you how to answer it: `git fetch`, then `git branch -r --contains <commit>`.

## MENTAL MODEL

**[ON SCREEN]** "A question about publication, then one command with a stated risk."

**[ANIMATION]** step: tree.level-3

**[ANIMATION]** say: Triage:_the_same_questions,_always_in_the_same_order

A picture helps. Think of a triage nurse. Triage isn't treatment. It's two or three questions, always the same, always in the same order, that sort a case into the right room. The treatment in each room is something you already know how to do.

**[ANIMATION]** gates: gates=git_status_-sb:done:-:what_is_uncommitted,_and_are_you_ahead?|git_fetch:done:-:refresh_what_you_know|git_branch_-r_--contains:done:-:what_is_shared? result=then_the_tree title=Before_the_tree:_the_facts id=facts at_1=58 at_2=76 at_3=82 at_result=86

**[ANIMATION]** step: facts.result

The decision tree is triage for undo. Where it breaks as a picture: a nurse can look at the patient, while you often can't see the state from a chat message. So before the tree, you need the facts. `git status -sb` for what is uncommitted, and whether you're ahead. A fetch, and `git branch -r --contains`, for what is shared.

**[ANIMATION]** cards: question=Say_the_risk_out_loud_with_the_command cards=This_one_has_no_way_back.|This_one_keeps_your_changes_staged.|This_one_needs_no_force. at_1=45 at_2=60 at_3=75 id=risk

**[ANIMATION]** step: risk.3

And keep one more habit from the whole module: say the risk out loud with the command. "This one has no way back." "This one keeps your changes staged." "This one needs no force." A command without its risk is half an answer.

## DIAGRAM

**[DIAGRAM]** Build the tree top-down. First the root question and its two branches. Then the five leaves for uncommitted changes, marking the three that have no way back. Then the publication question, the NO side, and last the YES side.

```text
What do you want to undo?
|
+-- Changes that are not committed
|     |
|     +-- staged, and the edit should stay ......... git restore --staged <path>
|     +-- an unstaged edit, to be discarded ........ git diff <path>, then git restore <path>     (no way back)
|     +-- some hunks of a file ..................... git restore -p <path>                        (no way back)
|     +-- everything, possibly wanted later ........ git stash push -u -m "<why>"
|     +-- untracked files .......................... git clean -n [-d], then the same with -f     (no way back)
|
+-- Commits
      |
      +-- Can anyone else already have them?   git fetch; git branch -r --contains <commit>
            |
            +-- NO: private history, rewriting is allowed
            |     +-- last commit: content or message ...... git commit --amend
            |     +-- last commits: keep the changes ....... git reset --soft <commit>   (staged)
            |     |                                          git reset <commit>          (unstaged)
            |     +-- last commits: drop the changes ....... git reset --keep <commit>   (--hard only on a clean tree)
            |     +-- a merge made a moment ago ............ git reset --merge ORIG_HEAD
            |     +-- a commit further back ................ git rebase -i               (Chapter 9, Rebase)
            |
            +-- YES: shared history, add commits
                  +-- one commit ........................... git revert <commit>
                  +-- several commits ...................... git revert -n <A>..<B>, then git commit
                  +-- a merge .............................. git revert -m 1 <merge>, and plan the re-merge (11.9)
                  +-- one file back to an old version ...... git restore --source=<commit> <path>, then git commit
```

Read the tree top-down. The root question has two branches: changes that aren't committed, and commits.

Under uncommitted changes there are five leaves, and three of them are marked "no way back".

Under commits, the publication question comes first. NO leads to the commands that rewrite. YES leads to the commands that add.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch11/scenarios`. One clone, with a bare `origin` on disk. For each scenario: the situation, your choice, then the transcript. One note on the order: the demo ran scenario 3 before scenario 2, which is why scenario 2's log shows the commits of scenario 3.

**Scenario 1.** You made a commit a minute ago, and you want it back as staged changes. `git status -sb` says `[ahead 1]`. Which branch of the tree, and which command? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch11/scenarios/s1-undo-last-unpushed-commit -->
```text
$ git status -sb
## main...origin/main [ahead 1]
$ git branch -r --contains HEAD
$ git reset --soft HEAD~1
$ git status -sb
## main...origin/main
M  rank.py
$ git log --oneline -1
fc2e2d8 Record baseline metrics
```
<!-- /snippet -->

`ahead 1`, and `git branch -r --contains HEAD` prints nothing: no remote-tracking branch contains the commit. Private history. `git reset --soft HEAD~1` 🟡 takes the commit off the branch and leaves its change staged.

**[ANIMATION]** graph: fc2e2d8-?your_commit main; fc2e2d8 origin/main; HEAD=main => + fc2e2d8 main; reflog:?your_commit; cmd:git_reset_--soft_HEAD~1; say:Private_history:_the_reset_takes_the_commit_off_the_branch; name:reset title=Scenario_1 id=s1

**[ANIMATION]** step: s1.reset

The variations: `git reset HEAD~1` to get the change back unstaged, and `git reset --keep HEAD~1` to drop it. The wrong choice here would have been a revert. It works, and it leaves two commits of noise in a history nobody else has seen.

**Scenario 2.** A commit that disabled retries is on `main`. Choose.

**[PAUSE]**

<!-- snippet: ch11/scenarios/s2-pushed-bad-commit -->
```text
$ git log --oneline
377247a Ignore local .env files
90e7514 Retry BM25 scoring with backoff
fc2e2d8 Record baseline metrics
c6f2cfd Disable retries
91788a6 Add BM25 ranker and serving config
$ git branch -r --contains c6f2cfd
  origin/main
$ git revert --no-edit c6f2cfd
[main 20cf7b0] Revert "Disable retries"
 Date: Mon Sep 7 10:27:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status -sb
## main...origin/main [ahead 1]
$ git push
To $LAB/ch11/scenarios/server.git
   377247a..20cf7b0  main -> main
```
<!-- /snippet -->

`git branch -r --contains c6f2cfd` prints `origin/main`: shared history. `git revert` 🟡, then an ordinary push, accepted as a fast-forward. The wrong choice is a reset and a forced push, and the interview question at the end asks you to say why in three places.

**[ANIMATION]** graph: 91788a6-c6f2cfd-fc2e2d8-90e7514-377247a main origin/main; HEAD=main; name:graph => 377247a-20cf7b0 main; 377247a origin/main; HEAD=main; name:adds => 20cf7b0 main origin/main; HEAD=main; name:push title=Shared_history:_correct_by_adding id=s2

**[ANIMATION]** step: s2.push

The same thing as a graph. The revert adds one commit, `20cf7b0`, and the push moves `origin/main` forward to it. No label went backwards.

**Scenario 3.** A `.env` file went in with `git add .`. The commit isn't pushed. You want the commit without the file, and the file kept on disk. Choose.

**[PAUSE]**

<!-- snippet: ch11/scenarios/s3-remove-file-from-last-commit -->
```text
$ git show --stat --format="%h %s" HEAD
ccecf13 Retry BM25 scoring with backoff

 .env    | 1 +
 rank.py | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git rm --cached .env
rm '.env'
$ git commit --amend --no-edit
[main 90e7514] Retry BM25 scoring with backoff
 Date: Mon Sep 7 10:17:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git show --stat --format="%h %s" HEAD
90e7514 Retry BM25 scoring with backoff

 rank.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status -s
?? .env
```
<!-- /snippet -->

`git rm --cached` removes the index entry and keeps the file, and `git commit --amend` 🟡 replaces the commit: `ccecf13` becomes `90e7514`, with one file in its stat instead of two. The file is now untracked, so it goes into `.gitignore` next.

**[ANIMATION]** graph: fc2e2d8-ccecf13 main; HEAD=main => fc2e2d8-90e7514 main; fc2e2d8-ccecf13; HEAD=main; reflog:ccecf13; name:old-commit title=An_amend_replaces_the_commit id=s3

**[ANIMATION]** step: s3.old-commit

Two cautions from the textbook. The old commit `ccecf13` still contains the file and stays in your reflog, which is harmless for a commit that never left your machine. And if a commit with a real secret was ever pushed, amending isn't the fix: rotate the secret.

**Scenario 4.** `rank.py` is staged and shouldn't be part of the next commit. The edit should stay. Quick quiz. A, `git restore rank.py`. B, `git restore --staged rank.py`. C, `git reset --hard`. Your answer?

**[PAUSE]**

<!-- snippet: ch11/scenarios/s4-unstage -->
```text
$ git status -s
M  rank.py
 M serve.yaml
?? probe_output.txt
$ git restore --staged rank.py
$ git status -s
 M rank.py
 M serve.yaml
?? probe_output.txt
```
<!-- /snippet -->

B. `git restore --staged` 🟡. The index entry goes back to HEAD's version and the file keeps the edit: the `M` moves from the first status column to the second. The wrong choice is `git restore rank.py` without `--staged`, which would have discarded nothing here but, with further unstaged edits on top, would destroy them.

**Scenario 5.** You want to discard all local changes: two edited tracked files and an untracked output file. Choose, and say the risk.

**[PAUSE]**

<!-- snippet: ch11/scenarios/s5-discard-local-changes -->
```text
$ git restore rank.py serve.yaml
$ git status -s
?? probe_output.txt
$ git clean -n
Would remove probe_output.txt
$ git clean -f
Removing probe_output.txt
$ git status -s
```
<!-- /snippet -->

Tracked files: read `git diff`, then `git restore` 🔴. Untracked files: `git clean -n`, then `-f` 🔴. Neither step can be taken back, and the five answers for both were given in their own videos. When in doubt, `git stash push -u` does the same job and keeps the content.

**Scenario 6.** You merged `feature/reranker` a moment ago. It isn't pushed, and it was a mistake. You also have an unrelated, uncommitted edit to `metrics.txt` that you want to keep. Choose.

**[PAUSE]**

<!-- snippet: ch11/scenarios/s6-undo-unpushed-merge -->
```text
$ git merge feature/reranker
Merge made by the 'ort' strategy.
 rerank.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 rerank.py
$ git status -sb
## main...origin/main [ahead 2]
 M metrics.txt
$ git reset --merge ORIG_HEAD
$ git status -sb
## main...origin/main
 M metrics.txt
$ git log --oneline -1
20cf7b0 Revert "Disable retries"
```
<!-- /snippet -->

`git reset --merge ORIG_HEAD` 🔴, dangerous through staged work only, puts the branch back on the commit before the merge and keeps the edit to `metrics.txt`: status goes from `[ahead 2]` to level, and the ` M` line is still there. If anything has overwritten `ORIG_HEAD` since the merge, take the commit from the reflog. The wrong choice is `--hard`, which would have taken `metrics.txt` with it.

**Scenario 7.** The same merge, but pushed. Choose, and say what else you have to do besides running the command.

**[PAUSE]**

<!-- snippet: ch11/scenarios/s7-undo-pushed-merge -->
```text
$ git log --oneline --graph -4
*   5777a43 Merge branch 'feature/reranker'
|\  
| * ecf26a5 Add cross-encoder reranker
* | 20cf7b0 Revert "Disable retries"
* | 377247a Ignore local .env files
$ git branch -r --contains HEAD
  origin/main
$ git revert --no-edit -m 1 HEAD
[main 0dd3130] Revert "Merge branch 'feature/reranker'"
 Date: Mon Sep 7 10:50:00 2026 +0530
 1 file changed, 2 deletions(-)
 delete mode 100644 rerank.py
$ git push
To $LAB/ch11/scenarios/server.git
   5777a43..0dd3130  main -> main
$ ls
metrics.txt
rank.py
serve.yaml
```
<!-- /snippet -->

`origin/main` contains the merge: shared history. `git revert -m 1` 🟡, push, and write the re-merge plan of section 11.9 into the ticket. The command takes ten seconds. The plan is what prevents next week's incident.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Answering "how do I undo this" with a command before asking about publication.** Root cause: the same intent maps to a rewrite on private history and to an added commit on shared history; the commands are not interchangeable.
2. **Checking publication against a stale clone.** Root cause: `git branch -r --contains` reads remote-tracking branches, which are as old as the last fetch.
3. **Using `git reset --hard` where `--keep` or `--merge ORIG_HEAD` fits.** Root cause: `--hard` rewrites the working tree unconditionally, and unrelated uncommitted edits have no object.
4. **Amending a commit to remove a secret that was already pushed.** Root cause: the old commit still exists on the server and in clones; the secret is exposed and has to be rotated.
5. **Reverting a pushed merge and stopping there.** Root cause: the merge stays in the graph, so the next merge of that branch brings only newer commits unless a re-merge procedure is followed.

## PRODUCTION EXAMPLE

**[ANIMATION]** replay: facts

Now, out of the lab. A platform team for model serving keeps the decision tree in its on-call runbook, on the page titled "Undo". Above the tree are three lines: run `git status -sb`, run `git fetch`, and run `git branch -r --contains` on the commit in question. Below it, one rule in bold: on `main`, the Branch column must say "advanced".

**[ANIMATION]** step: tree.level-3

**[ANIMATION]** say: Three_questions,_answered_from_evidence

During an incident the on-call engineer isn't asked to remember Git. They're asked to follow three questions. The retrospective afterwards doesn't discuss which command was typed. It discusses whether the questions were answered from evidence. That's a team that has turned this module into a control.

## PRACTICE EXERCISE

Your turn. Do Lab 8.7, "Scenario cards", in [`lab-manual/m08-undo.md`](../../lab-manual/m08-undo.md).

For each card, before you touch the keyboard, write three lines:

- Private or shared, and the command output that proves it.
- The command you choose, and its row of the table: HEAD, branch, index, working tree, history.
- The command that would have been wrong, and what it would have cost.

Then run your choice and verify the end state.

The challenge is Exercise 8.9, Level 4, "one bad commit that is public, one mixed commit that is not", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q181: "A bad commit is on `main` and the team has pulled it. Compare "revert and push" with "reset and force-push": what does each do to the server, to the teammates' clones and to CI?"

**[PAUSE]**

**[ANIMATION]** walk: columns=place,revert_and_push,reset_and_force-push rows=the_server:?:?|the_teammates'_clones:?:?|CI:?:? mono=off title=Two_procedures,_three_places id=six

**[ANIMATION]** step: six.3

Answer out loud first. The question gives you its own structure: two procedures, three places. A strong answer fills all six cells and uses the same vocabulary in each: which refs move, in which direction, and what the next ordinary command in that place will then do. It should include what happens when a teammate who still has the old commits pushes next. It closes with what a server-side rule would have said to the second procedure.

## RECAP

**[ANIMATION]** step: tree.level-3

Let's land this. You should now be able to say:

Before I undo a commit I fetch and check whether a remote-tracking branch contains it. In the table I read the Branch column first: "set to" is for private history, "advanced" and "unchanged" are safe on shared branches. Uncommitted changes go through restore, stash or clean, and three of those leaves have no way back. Private commits are rewritten with amend or a reset, `--keep` for dropping and `--merge ORIG_HEAD` for a fresh merge. Shared commits are corrected with a revert, and a reverted merge needs a re-merge plan.

## HOMEWORK

Read sections 11.12 to 11.16 of [Chapter 11](../../textbook/ch11-reset-revert-restore.md) and do the Practice section 11.18.

Do Exercise 8.1, Level 1, "take a commit back and make it again", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Seven times today you asked about publication before you named a command. That's the reflex, and it's yours now. Work through the scenario cards before the next video. Next time, a new module: what a rebase is, and why every rebased commit has a new ID. Until then, look at the state first and type second. See you in the next one.
