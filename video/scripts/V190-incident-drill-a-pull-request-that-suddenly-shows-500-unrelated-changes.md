# V190: Incident drill: a pull request that suddenly shows 500 unrelated changes

- **Part.** 9, Production debugging and incident response
- **Module.** 37
- **Planned minutes.** 18
- **Prerequisites.** V125, V189
- **Textbook sections.** [Chapter 30](../../textbook/ch30-incident-response.md), section 30.10
- **Demo scripts.** `labs/incidents/solve-06-pr-500-changes.sh` (snippets `01-pull-request-view` to `08-verify`), `labs/incidents/lab-37-3-pr-500-changes.sh` (snippet `02-consequence`)

## HOOK

**[ON SCREEN]** "I pushed one commit and the pull request shows 500 files."

Ravi's pull request had three commits and two files, and it was approved. A commit is one saved snapshot of the project, and a pull request is GitHub's proposal to merge a branch of commits into another branch, its base. He pushed one small commit. Now the page shows more than five hundred files and commits by a colleague who never touched his branch. He suspects that somebody rewrote `main`, or that somebody changed the base of his pull request.

And one detail that he mentions last, as if it were good news: the approval still stands. Is that good news? Hold that question.

**[ANIMATION]** cards: id=quiz question=Which_record_would_test_a_rewritten_main? cards=A:the_reflog_of_origin/main|B:the_pull_request_page|C:git_status marks=1:ok title=Quick_quiz at_1=45 at_2=75 at_3=82

**[ANIMATION]** step: 3

Quick quiz, before any cause is named. Which record would test Ravi's first suspect, a rewritten `main`? A, the reflog of `origin/main`, Git's local record of where the server's `main` has been. B, the pull request page. C, `git status`. Your answer?

**[PAUSE]**

**[ANIMATION]** step: marks

A. A rewrite would stand in that reflog as a forced update. Whether one does, we find out later.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a debrief of Incident 6, [`incidents/06-pr-500-changes`](../../incidents/06-pr-500-changes/SYMPTOMS.md). You must have generated and attempted it, with your hypotheses written down before you tested them. Have you? If you haven't, stop the video here.

**[PAUSE]**

The cause is named in the next section.

From video 125 you know what a pull request page computes: a commit list, which is everything reachable from the head and not from the base, and a diff, which is the three-dot comparison from the merge base to the head. The head is the branch that offers the commits, and the merge base is the most recent commit both branches contain. So when the page changes dramatically, one of three things moved: the head, the base, or the merge base between them. The incident is an exercise in finding out which, with Git commands on the developer's machine, and then repairing the branch without closing the pull request.

In the lab the pull request is simulated as `main..head` and `main...head`, which is what GitHub computes.

## LEARNING OBJECTIVES

After this video you can:

1. List the mechanisms that make a small pull request show hundreds of files.
2. Name the Git command that tests each mechanism on the developer's machine.
3. Attribute the extra changes to the commit that brought them in.
4. Rebuild the branch so that the pull request shows only its own change.
5. Explain the consequence of leaving it as it is.

## CONCEPT

**[ANIMATION]** cards: id=cand cards=the_wrong_base_branch|the_head_branch_reused_after_a_squash_merge|the_branch_rebased_or_force-pushed,_or_its_base_rewritten|every_line_changed:line_endings_or_a_formatter|a_lock_file_or_generated_file|a_merge_of_the_wrong_branch_into_the_head numbered=on title=A_pull_request_shows_hundreds_of_changes at_1=48 at_2=54 at_3=62 at_4=74 at_5=82 at_6=86

**The candidates.** The page shows a three-dot diff: either an endpoint or the merge base isn't what the author thinks. The catalog of video 184 lists the mechanisms for "a pull request shows hundreds of changes". The wrong base branch. The head branch reused after a squash merge. The branch rebased or force-pushed, or its base rewritten. Every line changed, by line endings or a formatter. A lock file or generated file. And a merge of the wrong branch into the head.

**[ANIMATION]** walk: id=tests columns=mechanism,local_test rows=a_rewritten_main:the_reflog_of_origin/main,_and_the_merge_base|a_force-pushed_head:the_reflog_of_the_pushing_clone|a_merge:git_log_--merges_over_the_pull_request's_range|reformatting:git_diff_--ignore-cr-at-eol_--stat_against_the_plain_diff|a_wrong_base:the_range_from_each_candidate_base title=Each_has_a_local_test at_1=8 at_2=30 at_3=48 at_4=62 at_5=85

Each has a local test. A rewritten `main`: the reflog of `origin/main` and the merge base. A force-pushed head: the reflog of the pushing clone. A merge: `git log --merges` over the pull request's range. Reformatting: `git diff --ignore-cr-at-eol --stat` against the plain diff. A wrong base: the range from each candidate base.

**[ANIMATION]** end

**The root cause here.** A topic branch, a branch for one piece of work, was aimed at `main` and updated from `develop`, an unreleased long-running branch. A merge makes every commit of the merged branch an ancestor of the result, and a pull request lists everything reachable from the head and not from the base. Layer: Git. GitHub displayed the branch correctly.

**Why "one small commit" felt true.** `git log --first-parent` shows the branch as Ravi experienced it: his commits and one merge. A merge commit has two parents, and the five hundred files came in through the second parent of that merge.

**[ANIMATION]** cards: id=revert question=git_revert_-m_1_of_the_merge:_wrong_here,_for_two_reasons cards=the_commits_of_develop_stay_ancestors_of_the_branch:so_the_commit_list_stays_long|once_merged,_main_has_those_commits_and_a_commit_that_undoes_them:so_the_later_release_of_develop_brings_nothing numbered=on title=A_reverted_merge_isn't_a_removed_merge at_1=38 at_2=55

**The tempting fix, and why it is wrong.** `git revert -m 1` of the merge commit, which adds a commit that undoes the merge: no forced push, and the diff shrinks. It's wrong here for two reasons. The commits of `develop` stay ancestors of the branch, so the commit list stays long. And once this branch is merged, `main` contains those commits together with a commit that undoes them, so the later release of `develop` brings nothing: the re-merge problem. The textbook's sentence for it: a reverted merge isn't a removed merge.

**[ANIMATION]** end

**The repair.** The branch has one author, so it's rebuilt: anchor the current tip, replay what came after the merge onto the merge's first parent, and publish with a lease, a forced push that's refused if the server's branch has moved.

**[ANIMATION]** bars: bars=approved_on:2|standing_on:504 unit=files title=The_approval at_1=45 at_2=55

**GitHub, not Git: the approval.** Whether an approval survives a push depends on the rules: "dismiss stale pull request approvals" removes it when the diff changes. Here an approval given to two files stood on 504. Treat it as void and review again. So that detail from the opening wasn't good news.

**[ANIMATION]** end

**Severity.** SEV 3. Nothing was merged. The near miss is the standing approval, not the file count.

## MENTAL MODEL

**[ANIMATION]** graph: *1-A-B topic; *1 main; *1-X-Y-Z develop; HEAD=topic => + B-M topic; Z-M; note:M:a_door; range:X,Y,Z:walks_in_with_it; say:Everything_behind_the_second_parent_walks_in => + M-R topic; note:R:a_revert; say:A_revert_changes_the_content_back_and_leaves_the_ancestry_in_place id=door at_state_2=62

**[ANIMATION]** step: state-2

Picture the pull request as the answer to one question: "what would arrive in the base if this were merged now?" Everything the head can reach and the base can't. A merge commit is a door: whatever is behind its second parent walks in with it.

Ravi opened a door to `develop` to get one thing he wanted from it. Everything else on `develop` came through the same door, and the page showed it faithfully.

**[ANIMATION]** step: state-3

Where the picture breaks: you can close a door, and you can't un-open a merge by adding a commit. A revert changes the content back and leaves the ancestry in place. Only a branch that never contained the merge is a branch without the door, which is why the repair is a rebuild.

**[ANIMATION]** end

For the method, one habit: read the commit list, not only the files. The files said "something large changed". The commit list, with its authors, said what.

Try it now. Thirty seconds, read-only. In any repository you have, run `git log --merges --oneline -5`. Each line is a door. Say out loud which branch walked in through one.

**[PAUSE]**

A merge's subject usually names the branch that came in, as "Merge branch 'develop'" does here. That reading found today's cause.

## DIAGRAM

**[ANIMATION]** cards: id=sofar question=What_we_know_so_far:_what_the_page_shows cards=yesterday:three_commits,_two_files,_approved|today:more_than_five_hundred_files,_and_commits_by_a_colleague|and:the_approval_still_stands title=Before_the_demo pace=quick

**[DIAGRAM]** A new drawing: the pull request's two endpoints and merge base on the graph, before and after the rebuild. IDs are from the transcript.

```text
  before

    main (base, and merge base) ---bdb4a59---6d230a6---f94e7f0---461c3ea---5dc3109   feature/snippet-highlight (head)
              \                                               /   (merge of develop)
               796fd96---5f0c2ae---069daa8-------------------+    develop
               (fixture generator, 500 golden fixtures, tokenizer)

    commit list  main..head  : 5 of Ravi's (one a merge) + 3 of Asha's
    diff         main...head : 504 files

  after

    main (base, and merge base) ---bdb4a59---6d230a6---f94e7f0---1981450   feature/snippet-highlight (head)

               796fd96---5f0c2ae---069daa8    develop  (untouched, no longer reachable from the head)

    commit list  main..head  : 4 commits
    diff         main...head : 2 files
```

Before the demo, what we know so far is what the page shows: yesterday three commits and two files, today more than five hundred files. The graph of the branch, before and after the rebuild, is drawn in the demo.

## LIVE TERMINAL DEMO

From here on the screen shows the solution. Is your own command log beside you?

**[PAUSE]**

Then compare as we go.

**[TERMINAL]** Replay `labs/run incidents/solve-06-pr-500-changes`. We start in our own clone, as a reviewer would. Everything until the rebuild is 🟢 SAFE.

**What the pull request shows.**

```bash
git fetch
git log --format='%h %an: %s' origin/main..origin/feature/snippet-highlight
git diff --shortstat origin/main...origin/feature/snippet-highlight
git diff --dirstat=files,5 origin/main...origin/feature/snippet-highlight
```

<!-- snippet: incidents/solve-06-pr-500-changes/01-pull-request-view -->
```text
$ cd you
$ git fetch
From ../server
 * [new branch]      develop    -> origin/develop
 * [new branch]      feature/snippet-highlight -> origin/feature/snippet-highlight
# The commit list of the pull request, and the size of its diff:
$ git log --format='%h %an: %s' origin/main..origin/feature/snippet-highlight
5dc3109 Ravi Menon: Highlight every query term
461c3ea Ravi Menon: Merge branch 'develop' of ../server into feature/snippet-highlight
f94e7f0 Ravi Menon: Escape HTML in snippets
6d230a6 Ravi Menon: Test snippet highlighting
bdb4a59 Ravi Menon: Add snippet highlighting
069daa8 Asha Rao: Switch the tokenizer to ICU word breaking
5f0c2ae Asha Rao: Regenerate golden fixtures
796fd96 Asha Rao: Add golden fixture generator
$ git diff --shortstat origin/main...origin/feature/snippet-highlight
 504 files changed, 517 insertions(+), 1 deletion(-)
$ git diff --dirstat=files,5 origin/main...origin/feature/snippet-highlight
  99.2% tests/golden/
```
<!-- /snippet -->

Eight commits, three of them by Asha. 504 files. And one line that already narrows it: 99.2 percent of the changed files are under `tests/golden/`. Read the commit list with the authors: one subject begins with "Merge branch 'develop'".

**Hypotheses, tested one at a time.**

<!-- snippet: incidents/solve-06-pr-500-changes/02-hypotheses -->
```text
# Hypothesis 1: main was rewritten or moved. Its history in my clone:
$ git reflog show origin/main
88eab01 refs/remotes/origin/main@{0}: update by push
$ git merge-base origin/main origin/feature/snippet-highlight
88eab017330e48da73bb6cc625a59fc9daaa61b9
$ git rev-parse origin/main
88eab017330e48da73bb6cc625a59fc9daaa61b9
# Hypothesis 2: the branch was force-pushed. The pushing clone recorded its pushes:
$ git -C ../ravi reflog show origin/feature/snippet-highlight
5dc3109 refs/remotes/origin/feature/snippet-highlight@{0}: update by push
f94e7f0 refs/remotes/origin/feature/snippet-highlight@{1}: update by push
```
<!-- /snippet -->

Was `main` rewritten? The reflog of `origin/main` and the merge base say no. Was the head branch force-pushed? The pushing clone's reflog shows ordinary pushes. Two of Ravi's own suspects are ruled out with read-only commands.

**Hypothesis 3: another branch was merged into the head branch.** Predict what `git log --merges` over the pull request's range will list.

```bash
git log --merges --format='%h %an: %s%n        parents: %p' origin/main..origin/feature/snippet-highlight
git log --oneline --graph origin/main..origin/feature/snippet-highlight
```

<!-- snippet: incidents/solve-06-pr-500-changes/03-merge -->
```text
# Hypothesis 3: another branch was merged into the head branch.
$ git log --merges --format='%h %an: %s%n        parents: %p' origin/main..origin/feature/snippet-highlight
461c3ea Ravi Menon: Merge branch 'develop' of ../server into feature/snippet-highlight
        parents: f94e7f0 069daa8
$ git log --oneline --graph origin/main..origin/feature/snippet-highlight
* 5dc3109 Highlight every query term
*   461c3ea Merge branch 'develop' of ../server into feature/snippet-highlight
|\  
| * 069daa8 Switch the tokenizer to ICU word breaking
| * 5f0c2ae Regenerate golden fixtures
| * 796fd96 Add golden fixture generator
* f94e7f0 Escape HTML in snippets
* 6d230a6 Test snippet highlighting
* bdb4a59 Add snippet highlighting
```
<!-- /snippet -->

One merge commit, `461c3ea`, by Ravi, with the tip of `develop`, `069daa8`, as its second parent. The graph shows the three commits that came in through it.

**Attribution: which commit brought the files?**

<!-- snippet: incidents/solve-06-pr-500-changes/04-attribution -->
```text
# What the merge alone brought in, and what the branch looks like without its second parent:
$ git diff --shortstat 461c3ea^1 461c3ea
 502 files changed, 508 insertions(+), 1 deletion(-)
$ git log --oneline --first-parent origin/main..origin/feature/snippet-highlight
5dc3109 Highlight every query term
461c3ea Merge branch 'develop' of ../server into feature/snippet-highlight
f94e7f0 Escape HTML in snippets
6d230a6 Test snippet highlighting
bdb4a59 Add snippet highlighting
$ git branch -r --contains 461c3ea^2
  origin/develop
  origin/feature/snippet-highlight
$ git -C ../ravi reflog -4
5dc3109 HEAD@{0}: commit: Highlight every query term
461c3ea HEAD@{1}: pull --no-rebase origin develop: Merge made by the 'ort' strategy.
f94e7f0 HEAD@{2}: commit: Escape HTML in snippets
6d230a6 HEAD@{3}: commit: Test snippet highlighting
```
<!-- /snippet -->

The file count belongs to the commits behind the second parent, and Ravi's reflog names the command that made the merge: a pull of `develop` without rebase. Now say the root cause in one sentence, with its layer.

**[PAUSE]**

Root cause, with its layer: Git. A topic branch aimed at `main` was updated from `develop`. GitHub displayed the branch correctly.

**[ANIMATION]** graph: 88eab01-bdb4a59-6d230a6-f94e7f0-461c3ea-5dc3109 feature/snippet-highlight; 88eab01 main origin/main; 88eab01-796fd96-5f0c2ae-069daa8 origin/develop; 069daa8-461c3ea; HEAD=feature/snippet-highlight; say:8_commits_in_main..head,_504_files_in_main...head => 88eab01-bdb4a59-6d230a6-f94e7f0-461c3ea-5dc3109 rescue/with-develop; 88eab01 main origin/main; 88eab01-796fd96-5f0c2ae-069daa8 origin/develop; 069daa8-461c3ea; ^f94e7f0-1981450 feature/snippet-highlight; HEAD=feature/snippet-highlight; say:4_commits_in_main..head,_2_files_in_main...head title=A_branch_that_never_contained_the_merge id=rebuild

**[ANIMATION]** step: state-1

Here's the branch as a graph. Neither the base nor the merge base moved. The head grew a second line of ancestors.

**[ANIMATION]** end

**Rebuild, in Ravi's clone.** 🟢 for the anchor. 🟡 CAUTION: `git rebase --onto` replaces the commits after the merge with new ones. The two arguments: the merge's first parent as the new base, and the merge itself as the boundary.

```bash
git status -sb
git branch rescue/with-develop
git rebase --onto 461c3ea^1 461c3ea
git log --oneline --graph main..feature/snippet-highlight
```

<!-- snippet: incidents/solve-06-pr-500-changes/05-rebuild -->
```text
$ cd ../ravi
$ git status -sb
## feature/snippet-highlight...origin/feature/snippet-highlight
$ git branch rescue/with-develop
$ git rebase --onto 461c3ea^1 461c3ea
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/snippet-highlight.
$ git log --oneline --graph main..feature/snippet-highlight
* 1981450 Highlight every query term
* f94e7f0 Escape HTML in snippets
* 6d230a6 Test snippet highlighting
* bdb4a59 Add snippet highlighting
```
<!-- /snippet -->

**[ANIMATION]** step: rebuild.state-2

One commit replayed. Four commits in a line, no merge. The last one is now `1981450`: a new ID, because its parent changed.

**Check the result before publishing.**

```bash
git range-diff 461c3ea..rescue/with-develop 461c3ea^1..feature/snippet-highlight
git diff --shortstat main...feature/snippet-highlight
git merge-base --is-ancestor origin/develop feature/snippet-highlight
```

<!-- snippet: incidents/solve-06-pr-500-changes/06-check-result -->
```text
$ git range-diff 461c3ea..rescue/with-develop 461c3ea^1..feature/snippet-highlight
1:  5dc3109 = 1:  1981450 Highlight every query term
$ git diff --shortstat main...feature/snippet-highlight
 2 files changed, 9 insertions(+)
$ git merge-base --is-ancestor origin/develop feature/snippet-highlight
[exit status: 1]
```
<!-- /snippet -->

The replayed commit carries the same change as the original: one pair with an equals sign. Two files. And `develop` is no longer an ancestor of the branch: exit status 1, which here is the result you want.

**Publish.** 🔴 DANGEROUS: `git push --force-with-lease --force-if-includes`. What it changes: the server's topic branch, to a commit that doesn't descend from the old one. What it can destroy: commits on that server branch that aren't in this clone. Preview: `git fetch`, then look at what the server's branch has that you lack. Recovery: the old tip is anchored as `rescue/with-develop`. When appropriate: for a topic branch with one author, as here.

<!-- snippet: incidents/solve-06-pr-500-changes/07-publish -->
```text
$ git push --force-with-lease --force-if-includes
To ../server.git
 + 5dc3109...1981450 feature/snippet-highlight -> feature/snippet-highlight (forced update)
```
<!-- /snippet -->

**Verify, from the reviewer's clone.**

<!-- snippet: incidents/solve-06-pr-500-changes/08-verify -->
```text
$ cd ../you
$ git fetch
From ../server
 + 5dc3109...1981450 feature/snippet-highlight -> origin/feature/snippet-highlight  (forced update)
$ git log --format='%h %an: %s' origin/main..origin/feature/snippet-highlight
1981450 Ravi Menon: Highlight every query term
f94e7f0 Ravi Menon: Escape HTML in snippets
6d230a6 Ravi Menon: Test snippet highlighting
bdb4a59 Ravi Menon: Add snippet highlighting
$ git diff --stat origin/main...origin/feature/snippet-highlight
 search/highlight.py     | 7 +++++++
 tests/test_highlight.py | 2 ++
 2 files changed, 9 insertions(+)
$ git -C ../ravi branch -D rescue/with-develop
Deleted branch rescue/with-develop (was 5dc3109).
$ cd ..
$ incidents/06-pr-500-changes/check.sh
Checking incident 06-pr-500-changes
  ok    the server still has the feature branch
  ok    "Add snippet highlighting" is in the pull request exactly once
  ok    "Test snippet highlighting" is in the pull request exactly once
  ok    "Escape HTML in snippets" is in the pull request exactly once
  ok    "Highlight every query term" is in the pull request exactly once
  ok    the pull request lists four commits
  ok    the pull request changes two files
  ok    no commit of develop is reachable from the feature branch
  ok    the feature branch contains no merge commit
  ok    search/highlight.py handles every query term
  ok    develop on the server is untouched
  ok    main on the server is untouched
PASS: the recovery of incident 06-pr-500-changes is complete.
[exit status: 0]
```
<!-- /snippet -->

Four commits, all Ravi's. Two files. The check passes, including two lines about what wasn't touched: `develop` and `main` on the server.

**The consequence of leaving it, or of reverting the merge.** Replay `labs/run incidents/lab-37-3-pr-500-changes` and show the snippet `consequence`. In the lab's failure scenario the merge was reverted instead of removed. Later the pull request is merged into `main`, and then `develop` is released into `main`. Predict what the release merge prints. Say it out loud.

**[PAUSE]**

<!-- snippet: incidents/lab-37-3-pr-500-changes/02-consequence -->
```text
# Later: the pull request is merged into main, and then develop is released into main.
$ git switch -q --detach main
$ git merge -q --no-ff -m 'Merge pull request: snippet highlighting' feature/snippet-highlight
$ git merge -m 'Release develop' origin/develop
Already up to date.
$ ls tests
test_highlight.py
test_tokenize.py
$ git switch -q feature/snippet-highlight
$ cd ..
$ incidents/06-pr-500-changes/check.sh
Checking incident 06-pr-500-changes
  ok    the server still has the feature branch
  ok    "Add snippet highlighting" is in the pull request exactly once
  ok    "Test snippet highlighting" is in the pull request exactly once
  ok    "Escape HTML in snippets" is in the pull request exactly once
  ok    "Highlight every query term" is in the pull request exactly once
  FAIL  the pull request lists 9 commits (expected 4)
  ok    the pull request changes two files
  FAIL  no commit of develop is reachable from the feature branch
  FAIL  the feature branch contains 1 merge commit(s); a reverted merge is not a removed merge
  ok    search/highlight.py handles every query term
  ok    develop on the server is untouched
  ok    main on the server is untouched
NOT YET: 3 check(s) failed.
[exit status: 1]
```
<!-- /snippet -->

"Already up to date." The release of `develop` brings nothing, because its commits are already ancestors of `main`, together with the commit that undid them. The listing of `tests` shows no golden fixtures. An entire release has silently become empty. And the check script says it in one line: a reverted merge isn't a removed merge.

**The messages.** To Ravi: GitHub showed what the branch contained, here is the reflog line, and the last commit has a new ID. To the lead: the near miss is the standing approval, not the file count. Had it been merged, 500 fixtures and an unreleased tokenizer would have reached `main` under an approval for two files.

## COMMON MISTAKES

1. **Blaming the platform or a rewritten `main` first.** Root cause: the page is a computation over the head, the base and the merge base, and the reflogs showed that neither the base nor the head had been rewritten.
2. **Updating a topic branch from a branch other than its base.** Root cause: a merge makes every commit of the merged branch an ancestor of the result, so all of it enters the pull request.
3. **Reverting the merge to shrink the diff.** Root cause: the revert changes content and leaves ancestry, so the commit list stays long and a later merge of the same branch brings nothing.
4. **Reading only the changed files.** Root cause: the commit list, with authors, names the foreign commits directly; the file view only says that something is large.
5. **Letting the old approval stand.** Root cause: the approval was given to a different diff, and whether it is dismissed depends on a rule that may not be enabled.

## PRODUCTION EXAMPLE

Now, out of the lab. A search team keeps a long-running `develop` branch for a tokenizer migration that regenerates five hundred golden test fixtures. An engineer working on snippet highlighting, on a branch aimed at `main`, needs one helper that exists only on `develop`, and pulls `develop` into his branch to get it.

**[ANIMATION]** gates: id=review gates=the_commit_list:done:-:a_colleague's_name,_a_merge_subject|git_log_--merges:done:-:over_the_pull_request's_range|no_revert:done:-:she_asks_him_not_to_revert_the_merge|the_rebuild:done:-:an_anchor,_one_rebase_--onto,_three_checks,_a_push_with_a_lease title=His_reviewer_doesn't_approve_again at_1=12 at_2=38 at_3=55 at_4=65

His reviewer, the next morning, doesn't approve again. She reads the commit list and sees a colleague's name on three commits and a merge subject that names `develop`. She runs `git log --merges` over the pull request's range in her clone, sends him the one line, and asks him not to revert the merge. They rebuild the branch together: an anchor, one `rebase --onto`, three checks, a push with a lease. The helper he needed is cherry-picked as its own reviewed commit instead.

**[ANIMATION]** cards: id=guide cards=Update_a_topic_branch_from_the_branch_it_will_be_merged_into:and_name_that_branch_in_the_command|Dismiss_stale_approvals_when_the_diff_changes:an_approval_for_two_files_had_stood_on_504 title=Two_lines_in_the_contribution_guide at_1=15 at_2=50

The team adds two lines to its contribution guide. Update a topic branch from the branch it will be merged into, and name that branch in the command. And the repository's ruleset gets the option that dismisses stale approvals when the diff changes, because an approval for two files had stood on five hundred and four.

## PRACTICE EXERCISE

Your turn. Do Lab 37.3, "A pull request suddenly shows 500 unrelated changes (incident 6)", in [`lab-manual/m37-incident-drills-platform.md`](../../lab-manual/m37-incident-drills-platform.md), from a freshly generated sandbox.

Before any command, write four mechanisms that could produce the symptom and the local command that tests each. Before the rebuild, write the two arguments of `git rebase --onto` you'll use and what each stands for, and predict the commit count afterwards. In the lab's failure scenario, predict what the later merge of `develop` will print before you run it.

The challenge is Exercise 21.7, Level 5, "Green on the pull request, red on main", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q414: "A pull request shows 400 changed files for a two-line change. List four mechanisms and the Git command that tests each one locally."

**[PAUSE]**

Answer out loud. The question fixes the form: four mechanisms, four commands. A strong answer begins with what the page computes, so that the four mechanisms follow from it instead of being recited: something about the base, something about the head's ancestry, something about a rewrite, something about content that changed on every line. Each command is one that the developer can run in their own clone, and for each you say what output confirms the mechanism. Add the order in which you would test them and why, and one sentence on which repairs keep the pull request open.

## RECAP

Let's land this.

- A pull request lists everything reachable from the head and not from the base, and shows the diff from the merge base to the head.
- A sudden jump in size means the head, the base or the merge base changed; each candidate has a read-only local test.
- A merge of another branch into the head brings all of that branch's commits into the pull request.
- A reverted merge is not a removed merge: the ancestry stays, and a later merge of that branch brings nothing.
- The repair for a single-author topic branch is a rebuild with `git rebase --onto`, a lease, and a new review.

## HOMEWORK

Read section 30.10. Then generate Incident 7, [`incidents/07-ci-passes-locally`](../../incidents/07-ci-passes-locally/SYMPTOMS.md), read its evidence directory together with the symptoms, and attempt it before the next video.

You can now find why a pull request grew overnight, and rebuild its branch without closing it. Practise the rebuild by hand. Next time, a new report: "It passes on my Mac, it must be a flaky runner". Until then, look at the state first and type second. See you in the next one.
