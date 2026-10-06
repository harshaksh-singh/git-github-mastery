# V128: The three merge methods: merge commit, squash and merge, rebase and merge

- **Part.** 5: GitHub
- **Module.** 22
- **Planned minutes.** 24
- **Prerequisites.** V036, V052, V124
- **Textbook sections.** [Chapter 17](../../textbook/ch17-pull-requests.md), section 17.8
- **Demo scripts.** `labs/ch17/merge-methods.sh`, `labs/ch17/rebase-deviations.sh`; GitHub-side walkthrough of Lab 22.1

## HOOK

**[ON SCREEN]** "Which commit did the reviewer approve?" — and a commit ID on `main` that appears in no pull request.

An audit asks a plain question about a release: which commit did the reviewer approve? The engineer opens the pull request and reads the ID of its last commit. Then she looks for that ID on `main`. It is not there. The commit on `main` has the same change, a different ID, and a committer that is not a person on the team.

Your CTO asks: where did the reviewed commit go?

**[ANIMATION]** graph: id=hook *1-*2-?same_change main; *1-*3-?the_reviewed_commit special:the-pull-request-ref; HEAD=none; say:The_reviewed_commit_never_reached_main dx=250 pace=quick

Nowhere. It is still in the repository, under the pull request's ref. It never reached `main`, because of which button was pressed at merge time. This video is about the three buttons and what each one writes. Keep the audit question in mind: one bit answers it, and you'll measure that bit in the demo.

**[ANIMATION]** end

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video opens Module 22. In the pull request videos, the end of the lifecycle was one word, "merged", and I said it was the only transition that writes to a branch. Now we look at what it writes.

GitHub offers three merge methods: create a merge commit, squash and merge, rebase and merge. All three are server-side operations of GitHub. All three give the base branch, the branch the pull request merges into, the same content. They differ in what the history says about how the content got there, and that difference decides what you can prove later.

Two replays. `labs/ch17/merge-methods.sh` performs the three local commands that correspond to the buttons, in three copies of one repository. Asha merges. Two differences from GitHub are visible in the replay, and I will point at them: the committer here is Asha, where GitHub records itself, and nothing here is signed. The author of a commit is whoever wrote the change. The committer is whoever created the commit object. `labs/ch17/rebase-deviations.sh` shows how the rebase button differs from a local `git rebase`. Then the walkthrough of Lab 22.1.

Labels: `git merge --no-ff`, `git merge --squash` and `git rebase` are 🟡 CAUTION: they move or rewrite the current branch. The three merge buttons are 🟡 as well: they write to the base branch.

## LEARNING OBJECTIVES

After this video you can:

- Say for each method what lands on the base branch and which commit IDs are new.
- Say who the author and the committer of the resulting commits are.
- Show that the three results have the same tree and different ancestry.
- Explain what the contributor's local branch looks like after each method.
- Explain why "rebase and merge" differs from a local `git rebase`.

## CONCEPT

In one sentence: the three merge buttons write three different histories for the same content: a merge commit that keeps your commits, one new commit that replaces them, or new copies of your commits in a straight line.

**[ON SCREEN]** The table of section 17.8, column by column.

Create a merge commit, a commit with two parents. The documented mechanics: "all commits from the feature branch are added to the base branch in a merge commit ... using the `--no-ff` option". New commits on the base: one merge commit. Your original commit IDs on the base: preserved. Your commits are unchanged, and the merge commit is committed by GitHub. Your commits keep their signatures, and the merge commit is signed by GitHub. The documented loss: none.

Squash and merge. "The pull request's commits are squashed into a single commit", then merged "using the fast-forward option". New commits on the base: one. Your original commit IDs: not present. It is committed by GitHub, and GitHub signs the final squash commit. The documented loss, in GitHub's words: "You lose information about when specific changes were originally made and who authored the squashed commits."

Rebase and merge. Commits "are added onto the base branch individually without a merge commit". New commits on the base: one per original commit. Your original IDs: not present. The method "always ... creates new commit SHAs". It "always updates the committer information". Signature on what lands: none. The commits are added "without commit signature verification". And originally empty commits are dropped.

Two rows connect to the rules of the last three videos of this batch. Under a linear history rule, the merge commit method is not allowed. Squash and rebase are, and rebase and merge is limited to 100 commits.

Why can rebase and merge not be signed? In GitHub's words: "GitHub creates a modified commit ... GitHub didn't truly create this commit, and can't therefore sign it as a generic system user. GitHub doesn't have access to the committer's private signing keys." The documented workaround is "to rebase and merge locally, and then push". You saw the mechanism in the signing videos: a rewritten commit keeps its author and loses its signature.

One caveat the textbook marks unverified: who is recorded as the author of a squash commit, and whether other contributors become `Co-authored-by` trailers, is not stated on the live documentation pages. Lab 22.1 has you read the real commit and record what you find.

**[ANIMATION]** graph: 9a383e5-9aa221a main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing refs/pull/1/head; HEAD=main => 9aa221a-4c53f2e main; 16d4788-4c53f2e; 16d4788 feature/priority-routing refs/pull/1/head; HEAD=main title=Create_a_merge_commit

**[ANIMATION]** step: state-1

Now the sentence to remember, in bold in the book, with our branch on screen: the merge method does not change what the code is after the merge. It changes what the history says about how the code got there.

Quick quiz, with the audit from the hook. Which button leaves the commit the reviewer approved on `main`, under its own ID? A: merge commit. B: squash. C: rebase. Your answer?

**[PAUSE]**

**[ANIMATION]** step: state-2

A. Only the merge commit method leaves the reviewed commits on the base branch under their IDs. For you as contributor: your local branch is an ancestor of `main`, so Git knows it is merged.

**[ANIMATION]** graph: 9a383e5-9aa221a main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing refs/pull/1/head; HEAD=main => 9aa221a-da48bba main; 16d4788 feature/priority-routing refs/pull/1/head; HEAD=main => da48bba main; 16d4788 refs/pull/1/head; HEAD=main title=Squash_and_merge

**[ANIMATION]** step: state-2

After a squash, `main` now has one new commit, and your original commits are not part of its history.

**[ANIMATION]** step: state-3

Once the head branch is deleted, they are on no branch. They are still under `refs/pull/N/head`.

**[ANIMATION]** graph: 9a383e5-9aa221a main; 9a383e5-44c1e7b-12ae95d-16d4788 feature/priority-routing refs/pull/1/head; HEAD=main => 9aa221a-dbb1f36-2303f3a-ec49c9c main; 16d4788 feature/priority-routing refs/pull/1/head; HEAD=main title=Rebase_and_merge

**[ANIMATION]** step: state-2

After a rebase, the label `main` now sits on three new copies, and the same holds for your originals. For the contributor, after a squash or a rebase the local branch is not an ancestor of `main`, and `git branch -d` will say "not fully merged". That is expected under those methods, and the next video shows how to verify before deleting.

How does the rebase button differ from a local rebase? GitHub's rebase and merge "deviates slightly from `git rebase`". It always updates the committer information and creates new commit IDs, whereas `git rebase` does not change anything when the branch already sits on top of the base. And it drops commits that were empty to begin with, whereas `git rebase` keeps originally empty commits by default. So after "Rebase and merge" the commits on `main` are never the commits you pushed, even when no rebase seemed necessary.

**[ANIMATION]** end

Who chooses? A repository's settings decide which methods are offered, and a ruleset can restrict them per branch. With a merge queue, "you no longer get to choose the merge method, as this is controlled by the queue".

## MENTAL MODEL

**[ANIMATION]** walk: id=filing columns=filing,staple_with_a_cover_note,one_clean_page,every_page_retyped rows=the_method:merge_commit:squash:rebase|new_commits_on_main:1:1:3|keeps_the_three_originals:yes:no:no marks=2.2:hl,2.3:hl,2.4:hl,3.2:ok,3.3:bad,3.4:bad mono=off at_1=20 title=Three_ways_to_file_a_report

**[ANIMATION]** step: 1

The textbook's analogy: three ways to file a report written in drafts. Staple the drafts into the folder with a cover note: that is the merge commit. Retype one clean page: that is squash. Retype every draft in order: that is rebase. The folder's content is the same. What you can prove later about the drafts is not.

Try it now, thirty seconds, on paper. Three columns: staple, one clean page, every page retyped. Under each, write how many new commits `main` gets from a branch of three. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: 3

One, one, and three. And only the first column keeps the three originals as well.

The analogy breaks because retyped pages in Git are new objects with new IDs, and every tool that tracked the old IDs has lost them.

Hold on to the word "retyped". Two of the three methods retype. Anything attached to the original pages by their ID does not follow: a reviewer's approval, a check result, a signature, your local branch's ancestry.

**[ANIMATION]** end

## DIAGRAM

**[DIAGRAM]** One pull request, three resulting graphs, side by side.

```text
  Create a merge commit                 Squash and merge              Rebase and merge
  ...9a383e5---9aa221a-------4c53f2e    ...9aa221a---da48bba          ...9aa221a---dbb1f36---2303f3a---ec49c9c
            \               /
             44c1e7b--12ae95d--16d4788   (44c1e7b, 12ae95d, 16d4788    (44c1e7b, 12ae95d, 16d4788
                                          stay on the old branch,       stay on the old branch,
                                          not on main)                  not on main)
  main keeps your IDs and adds one      main gets one new commit      main gets three new commits
```

On the left, the merge commit. Your three commits, `44c1e7b`, `12ae95d` and `16d4788`, are part of `main`'s history, and one new commit, `4c53f2e`, ties them in with two parents.

In the middle, squash. `main` gains one commit, `da48bba`, with one parent. Your three commits are in brackets underneath: they stay on the old branch, not on `main`.

On the right, rebase. `main` gains three commits in a straight line, with three new IDs. Your three originals are, again, not on `main`.

Now look for `16d4788`, the commit the reviewer approved, in each picture. It is on `main` in the first one only.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch17/merge-methods
```

The same starting point in all three copies.

```bash
cd merge/asha
git log --graph --format="%h %an: %s" main origin/feature/priority-routing
```

<!-- snippet: ch17/merge-methods/01-before -->
```text
# The same starting point in all three copies. Asha is the maintainer.
$ cd merge/asha
$ git log --graph --format="%h %an: %s" main origin/feature/priority-routing
* 9aa221a Asha Rao: Raise the confidence threshold to 0.7
| * 16d4788 Lab User: Fix the name of the escalations queue
| * 12ae95d Lab User: Route high-priority tickets to escalation
| * 44c1e7b Lab User: Add priority scoring
|/  
* 9a383e5 Asha Rao: Add classifier test
* f3e7ca9 Asha Rao: Add routing config
* 53e7f57 Asha Rao: Add keyword classifier
* fbbcc8d Asha Rao: Add README
```
<!-- /snippet -->

Your branch has three commits, and `main` has moved on by one.

Method 1.

```bash
git merge --no-ff -m "Merge pull request #1 from feature/priority-routing" origin/feature/priority-routing
git push -q origin main
git log --graph --format="%h %an / %cn: %s" -6
```

<!-- snippet: ch17/merge-methods/02-merge-commit -->
```text
# Method 1, "Create a merge commit":
$ git merge --no-ff -m "Merge pull request #1 from feature/priority-routing" origin/feature/priority-routing
Merge made by the 'ort' strategy.
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
 create mode 100644 router/priority.py
$ git push -q origin main
$ git log --graph --format="%h %an / %cn: %s" -6
*   4c53f2e Asha Rao / Asha Rao: Merge pull request #1 from feature/priority-routing
|\  
| * 16d4788 Lab User / Lab User: Fix the name of the escalations queue
| * 12ae95d Lab User / Lab User: Route high-priority tickets to escalation
| * 44c1e7b Lab User / Lab User: Add priority scoring
* | 9aa221a Asha Rao / Asha Rao: Raise the confidence threshold to 0.7
|/  
* 9a383e5 Asha Rao / Asha Rao: Add classifier test
```
<!-- /snippet -->

Method 2.

```bash
cd ../../squash/asha
git merge --squash origin/feature/priority-routing
git commit -q -m "Route high-priority tickets to an escalations queue (#1)"
git push -q origin main
git log --graph --format="%h %an / %cn: %s" -3
```

<!-- snippet: ch17/merge-methods/03-squash -->
```text
# Method 2, "Squash and merge":
$ cd ../../squash/asha
$ git merge --squash origin/feature/priority-routing
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git commit -q -m "Route high-priority tickets to an escalations queue (#1)"
$ git push -q origin main
$ git log --graph --format="%h %an / %cn: %s" -3
* da48bba Asha Rao / Asha Rao: Route high-priority tickets to an escalations queue (#1)
* 9aa221a Asha Rao / Asha Rao: Raise the confidence threshold to 0.7
* 9a383e5 Asha Rao / Asha Rao: Add classifier test
$ git show --stat --format="%h parents: %p" HEAD
da48bba parents: 9aa221a

 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

`git merge --squash` stops before committing and says so: "Squash commit -- not updating HEAD". The ordinary commit that follows has one parent.

Method 3.

```bash
cd ../../rebase/asha
git switch -q -c pr-1 origin/feature/priority-routing
git rebase main
git switch -q main
git merge --ff-only pr-1
```

<!-- snippet: ch17/merge-methods/04-rebase -->
```text
# Method 3, "Rebase and merge":
$ cd ../../rebase/asha
$ git switch -q -c pr-1 origin/feature/priority-routing
$ git rebase main
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/pr-1.
$ git switch -q main
$ git merge --ff-only pr-1
Updating 9aa221a..ec49c9c
Fast-forward
 router/classify.py | 6 +++++-
 router/priority.py | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)
 create mode 100644 router/priority.py
$ git push -q origin main
$ git log --graph --format="%h %an / %cn: %s" -5
* ec49c9c Lab User / Asha Rao: Fix the name of the escalations queue
* 2303f3a Lab User / Asha Rao: Route high-priority tickets to escalation
* dbb1f36 Lab User / Asha Rao: Add priority scoring
* 9aa221a Asha Rao / Asha Rao: Raise the confidence threshold to 0.7
* 9a383e5 Asha Rao / Asha Rao: Add classifier test
```
<!-- /snippet -->

A rebase of the pull request's commits onto `main`, then a fast-forward.

**[PAUSE]** Before the comparison: for each copy, how many commits did `main` gain, and how many of them have IDs that you, the contributor, already know?

<!-- snippet: ch17/merge-methods/05-what-main-gained -->
```text
# The feature commits as you wrote them:
$ git -C merge/you log --format="%h author=%an committer=%cn %s" main..feature/priority-routing
16d4788 author=Lab User committer=Lab User Fix the name of the escalations queue
12ae95d author=Lab User committer=Lab User Route high-priority tickets to escalation
44c1e7b author=Lab User committer=Lab User Add priority scoring
# What main gained in each copy (main@{1} is where main was before):
$ git -C merge/asha log --format="%h author=%an committer=%cn %s" main@{1}..main
4c53f2e author=Asha Rao committer=Asha Rao Merge pull request #1 from feature/priority-routing
16d4788 author=Lab User committer=Lab User Fix the name of the escalations queue
12ae95d author=Lab User committer=Lab User Route high-priority tickets to escalation
44c1e7b author=Lab User committer=Lab User Add priority scoring
$ git -C squash/asha log --format="%h author=%an committer=%cn %s" main@{1}..main
da48bba author=Asha Rao committer=Asha Rao Route high-priority tickets to an escalations queue (#1)
$ git -C rebase/asha log --format="%h author=%an committer=%cn %s" main@{1}..main
ec49c9c author=Lab User committer=Asha Rao Fix the name of the escalations queue
2303f3a author=Lab User committer=Asha Rao Route high-priority tickets to escalation
dbb1f36 author=Lab User committer=Asha Rao Add priority scoring
```
<!-- /snippet -->

Merge: four commits, three of them yours under their own IDs, plus `4c53f2e`. Squash: one commit, `da48bba`, and none of yours. Rebase: three commits with you as author and Asha as committer, and three new IDs. Read the author and committer columns: in the rebase copy they differ. On GitHub, the committer of the squash commit, of the rebased commits and of the merge commit is GitHub. Here it is Asha. That is the first difference between this replay and the platform. The second: nothing here is signed.

```bash
git -C merge/asha rev-parse main^{tree}
git -C squash/asha rev-parse main^{tree}
git -C rebase/asha rev-parse main^{tree}
```

**[PAUSE]** Three different histories. Will the three tree IDs be equal?

<!-- snippet: ch17/merge-methods/06-same-tree -->
```text
# Three histories, one result: the tree of main is identical.
$ git -C merge/asha rev-parse main^{tree}
beff5a60b5d7f4a2b93e41130391fc485f5970e0
$ git -C squash/asha rev-parse main^{tree}
beff5a60b5d7f4a2b93e41130391fc485f5970e0
$ git -C rebase/asha rev-parse main^{tree}
beff5a60b5d7f4a2b93e41130391fc485f5970e0
```
<!-- /snippet -->

Identical: `beff5a6` in all three copies. The tree is the snapshot itself, the full listing of files. It is also the tree of the test merge from video 123. The code is the same. The history is not.

<!-- snippet: ch17/merge-methods/07-first-parent -->
```text
# What "git log --first-parent" shows on main:
$ git -C merge/asha log --first-parent --oneline -3 main
4c53f2e Merge pull request #1 from feature/priority-routing
9aa221a Raise the confidence threshold to 0.7
9a383e5 Add classifier test
$ git -C squash/asha log --first-parent --oneline -3 main
da48bba Route high-priority tickets to an escalations queue (#1)
9aa221a Raise the confidence threshold to 0.7
9a383e5 Add classifier test
$ git -C rebase/asha log --first-parent --oneline -5 main
ec49c9c Fix the name of the escalations queue
2303f3a Route high-priority tickets to escalation
dbb1f36 Add priority scoring
9aa221a Raise the confidence threshold to 0.7
9a383e5 Add classifier test
```
<!-- /snippet -->

What `git log --first-parent` shows on `main`: one line per pull request for merge and for squash, one line per commit for rebase. Now the audit bit. Is your original head commit an ancestor of `main`? Predict the three exit statuses. Say them out loud.

**[PAUSE]**

```bash
git -C merge/asha merge-base --is-ancestor origin/feature/priority-routing main
git -C squash/asha merge-base --is-ancestor origin/feature/priority-routing main
git -C rebase/asha merge-base --is-ancestor origin/feature/priority-routing main
```

<!-- snippet: ch17/merge-methods/08-ancestry -->
```text
# Is your original head commit an ancestor of main?
$ git -C merge/asha merge-base --is-ancestor origin/feature/priority-routing main
[exit status: 0]
$ git -C squash/asha merge-base --is-ancestor origin/feature/priority-routing main
[exit status: 1]
$ git -C rebase/asha merge-base --is-ancestor origin/feature/priority-routing main
[exit status: 1]
```
<!-- /snippet -->

Exit status 0 for the merge commit, 1 for squash, 1 for rebase. That one bit is the answer to the audit question from the hook, and it is what `git branch -d` tests.

**[TERMINAL]** The two deviations of the rebase button.

```bash
labs/run ch17/rebase-deviations
```

A branch that already sits on top of `main`, with one empty commit.

```bash
git switch -q -c pr-1 origin/feature/priority-routing
git log --format="%h author=%an committer=%cn %s" main..pr-1
git rebase main
```

**[PAUSE]** Nothing has landed on `main` since the branch was created. What does a local `git rebase main` do to the four commits?

<!-- snippet: ch17/rebase-deviations/01-already-on-top -->
```text
# Asha, the maintainer. Nothing has landed on main since the branch was created:
$ git switch -q -c pr-1 origin/feature/priority-routing
$ git log --format="%h author=%an committer=%cn %s" main..pr-1
a4deec5 author=Lab User committer=Lab User Trigger CI again
9dcfb58 author=Lab User committer=Lab User Fix the name of the escalations queue
02820ea author=Lab User committer=Lab User Route high-priority tickets to escalation
3807b29 author=Lab User committer=Lab User Add priority scoring
$ git rebase main
Current branch pr-1 is up to date.
$ git log --format="%h author=%an committer=%cn %s" main..pr-1
a4deec5 author=Lab User committer=Lab User Trigger CI again
9dcfb58 author=Lab User committer=Lab User Fix the name of the escalations queue
02820ea author=Lab User committer=Lab User Route high-priority tickets to escalation
3807b29 author=Lab User committer=Lab User Add priority scoring
```
<!-- /snippet -->

Nothing: "Current branch pr-1 is up to date." Same IDs, same committer.

```bash
git rebase --no-ff main
git log --format="%h author=%an committer=%cn %s" main..pr-1
```

<!-- snippet: ch17/rebase-deviations/02-force-new-commits -->
```text
# What the documentation describes for the button: always new commits, new committer.
$ git rebase --no-ff main
Current branch pr-1 is up to date, rebase forced.
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/pr-1.
$ git log --format="%h author=%an committer=%cn %s" main..pr-1
123f252 author=Lab User committer=Asha Rao Trigger CI again
49f7387 author=Lab User committer=Asha Rao Fix the name of the escalations queue
9895c44 author=Lab User committer=Asha Rao Route high-priority tickets to escalation
216a2d1 author=Lab User committer=Asha Rao Add priority scoring
```
<!-- /snippet -->

To imitate the button you must force new commits: `--no-ff`. Four new IDs, and the committer is now Asha.

```bash
git rebase --no-ff --no-keep-empty main
```

<!-- snippet: ch17/rebase-deviations/03-drop-empty -->
```text
# And originally empty commits are dropped:
$ git rebase --no-ff --no-keep-empty main
Current branch pr-1 is up to date, rebase forced.
Rebasing (1/3)
Rebasing (2/3)
Rebasing (3/3)
Successfully rebased and updated refs/heads/pr-1.
$ git log --format="%h author=%an committer=%cn %s" main..pr-1
57537fc author=Lab User committer=Asha Rao Fix the name of the escalations queue
05bb2a6 author=Lab User committer=Asha Rao Route high-priority tickets to escalation
6da6459 author=Lab User committer=Asha Rao Add priority scoring
```
<!-- /snippet -->

And with `--no-keep-empty`, the empty commit "Trigger CI again" is gone: three commits. Those two options together are what the documentation describes for the button.

**[ON SCREEN]** The state table: any of the three merge buttons leaves your clone unchanged until you fetch. The base branch on the remote gains your commits and a merge commit, or one new commit, or new copies of your commits. After squash and rebase your original commits are on no branch, still under `refs/pull/N/head`. On GitHub, the pull request becomes merged, and the head branch is deleted if the repository setting or the option says so.

**[ON SCREEN]** GitHub walkthrough, Lab 22.1 Part B, on the starter repository with all three merge methods enabled, using three pull requests. The interface changes; the documentation pages cited in section 17.8 are the reference. No output is shown.

Open three small pull requests and merge each with a different method from the merge box. The control that performs the merge has a menu that offers the enabled methods. After each merge, fetch and read the facts from your terminal, with the commands of the replay:

```bash
git fetch
git log --graph --format="%h %an / %cn: %s" -6 origin/main
git log -1 --format=fuller origin/main
git merge-base --is-ancestor pr-head-commit origin/main; echo "exit status: $?"
```

Replace `pr-head-commit` with the ID of the pull request's last commit, read from your own branch. For each merge, record four things: how many commits `main` gained, whether your IDs are among them, who the committer is, and whether the commit shows as verified on the page. For the squash commit, also record who the author is and whether there are `Co-authored-by` trailers: that is the item the documentation does not state, and your observation is the evidence.

## COMMON MISTAKES

Five mistakes to watch for.

1. Looking for the reviewed commit ID on `main` after a squash or rebase merge. Root cause: both methods create new commits; the originals stay under `refs/pull/N/head`, on no branch.
2. Requiring signed commits and offering "Rebase and merge". Root cause: GitHub cannot sign the rewritten commits, so they land without signature verification.
3. Concluding from `git branch -d` saying "not fully merged" that the merge failed. Root cause: after squash or rebase the local branch is not an ancestor of `main`, although its content is there.
4. Assuming "Rebase and merge" keeps commits unchanged when the branch is already up to date. Root cause: the button always creates new commit IDs and updates the committer.
5. Judging the methods by the resulting code. Root cause: the tree of `main` is identical under all three; they differ in ancestry and identity.

## PRODUCTION EXAMPLE

Now, out of the lab. A payments team has two requirements on `main`: commits must be signed, and an auditor must be able to see that the reviewed commit is the deployed commit.

**[ANIMATION]** walk: id=audit columns=method,commits_must_be_signed,reviewed_commit_=_deployed_commit rows=Rebase_and_merge:no_signature_on_what_lands:-|Squash_and_merge:GitHub_signs_the_squash_commit:a_new_commit,_not_the_reviewed_one|Create_a_merge_commit:signatures_kept,_merge_signed_by_GitHub:reviewed_commits_on_main marks=1.2:bad,1.3:dim,2.2:ok,2.3:bad,3.2:ok,3.3:ok pick=3 mono=off at_1=8 at_2=22 at_3=68 title=Two_requirements,_three_methods

**[ANIMATION]** step: 3

Walk the three methods against the two requirements. Rebase and merge fails the first: what lands has no signature. Squash and merge passes the first, because GitHub signs the squash commit, and fails the second literally: the commit on `main` is not the commit that was reviewed. The link between them is the pull request, a GitHub object, plus the pull request ref. The merge commit method passes both: the reviewed commits are on `main` under their IDs with their own signatures, and the merge commit is signed by GitHub.

**[ANIMATION]** step: pick

The chapter's edge cases put it in one line: if compliance needs "the reviewed commit is the deployed commit", only the merge-commit method satisfies it literally. The team allows only that method on `main`, in the repository settings, and accepts the cost: a non-linear history, and merge commits in the log.

## PRACTICE EXERCISE

Your turn. Do Lab 22.1, "The three merge methods compared", in [`lab-manual/m22-merge-methods-releases.md`](../../lab-manual/m22-merge-methods-releases.md). Part A runs in the lab shell, where you play the maintainer in three copies. Before the comparison step, fill in a table by hand: for each method, the number of commits `main` gains, the number of merge commits, whether the tree IDs will be equal, and whether your head commit will be an ancestor of `main`. Then do Part B on GitHub and record the committer and the signature state.

The challenge is Exercise 22.2, "Which button was pressed?", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 275 of the CTO question bank:

> "Compare the three merge methods for a team that requires signed commits on `main` and must show an auditor that the reviewed commit is the deployed commit."

**[PAUSE]**

Answer out loud. A strong answer takes the two requirements one at a time and tests each method against each, with the documented reason for every failure. It distinguishes "the same content" from "the same commit". It ends with a recommendation, the setting that enforces it, and the cost the team accepts.

## RECAP

Let's land this. Same code under all three buttons, three different histories, and you can now say what each history lets you prove.

You should now be able to say:

- A merge commit keeps your commits and their IDs and adds one commit with two parents.
- A squash puts one new commit on the base, with no ancestry to your branch.
- Rebase and merge puts new copies of each commit on the base, always with new IDs and a new committer, and without signatures.
- The tree of the base branch is the same under all three; only the merge commit method makes the reviewed head an ancestor of the base.
- The button's rebase always rewrites and drops empty commits; a local rebase onto an ancestor changes nothing.

## HOMEWORK

Read section 17.8 of [Chapter 17](../../textbook/ch17-pull-requests.md). Do Exercise 22.1, "The three buttons from memory", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

That's the merge button, taken apart. Practise with Lab 22.1. Next: what the merge method means later, for bisect, blame and revert. Until then, look at the state first and type second. See you in the next one.
