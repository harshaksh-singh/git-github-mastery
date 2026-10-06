# V064: Naming commits and sets of commits: revisions, A..B and A...B for git log and for git diff

- **Part:** 3, Investigation, recovery and power tools
- **Module:** 10, Cherry-pick and ranges
- **Planned minutes:** 24
- **Prerequisites:** V025, V063
- **Textbook sections:** [Chapter 14A](../../textbook/ch14a-history-investigation.md), sections 14A.2, 14A.7 and 14A.8 (hook from section 14A.1)
- **Demo scripts:** `labs/ch14a/revisions.sh`, `labs/ch14a/ranges.sh`, `labs/ch14a/diff-endpoints.sh`

## HOOK

**[ON SCREEN]** "A reviewer says the pull request deletes a setting that the pull request never touched. What were they looking at?"

The author is certain: the branch adds a report writer and never opened the config file. The reviewer is equally certain: there is a red line in the diff, a setting called `NIGHTLY_PASS_MARK`, removed.

The reviewer ran `git diff main feat/report`. The pull request page shows something else. Both are diffs of "the branch against main". They differ by one dot, and that dot decides which two snapshots are compared.

The same two characters also appear in `git log`, where they mean something different again. Today you sort that out for good.

## INTRODUCTION

For twenty videos you have been typing things like `main..HEAD`, `HEAD~2`, `@{u}`, `ORIG_HEAD`, `feat/x@{1}`. This video collects them into a system, because every investigation command in the next module takes them as arguments.

Three parts. First, naming one commit: by ancestry, by reflog entry, by upstream, by message search, by path. Second, naming sets of commits: what `A..B` and `A...B` select in `git log`. Third, what `git diff` does with the same text, which is not the same thing, and which of the two forms a pull request shows.

The method for all the range exercises today is the same: draw the graph, shade the commits you expect, then run the command.

The project is `scorekit`, a small library that scores model answers against reference answers. Its history was prepared for the investigation chapter and you will use it through the whole next module.

## LEARNING OBJECTIVES

**[ON SCREEN]** The five objectives.

After this video you can:

- Name a commit by ancestry, by reflog entry, by upstream, by message search and by path.
- State what `A..B` and `A...B` select in `git log`.
- State what `A..B` and `A...B` compare in `git diff`, and why the dots mean something else there.
- Choose the diff form that matches what a pull request shows.
- Predict log and diff output from a drawn graph.

## CONCEPT

**Naming one commit.**

**[ON SCREEN]** The revision table of section 14A.7.

```text
Form                                 Names                                                           Read from
-----------------------------------  --------------------------------------------------------------  ---------------
<rev>~<n>                            the n-th ancestor, following first parents only                  the graph
<rev>^, <rev>^<n>                    the first parent, the n-th parent                                the graph
<ref>@{<n>}                          the value that ref had n updates ago                             your reflog
<ref>@{<date>}                       the value that ref had at that time in this repository           your reflog
@{u}, <branch>@{upstream}            the remote-tracking branch the branch is set to follow           configuration
:/<text>                             the youngest commit, reachable from any ref, whose message       all refs
                                     matches the regular expression
<rev>^{/<text>}                      the youngest such commit reachable from <rev>                    the graph
<rev>^{}, ^{commit}, ^{tree}         the object after peeling tags; the commit; its tree              objects
<rev>:<path>                         the blob or tree at that path in that revision                   objects
:<path>, :<n>:<path>                 the index entry for the path, at stage 0 or stage n              the index
```

Read the third column. It tells you how far to trust each name. Names read from the graph and from objects mean the same in every clone. Names read from your reflog mean something only in your repository. `@{u}` depends on your configuration.

**Naming sets of commits.** In one sentence: a range is a set of commits defined by reachability: everything you can reach from the included tips, minus everything you can reach from the excluded ones.

For history-walking commands, one revision means "this commit and all its ancestors", and several revisions mean the union. A leading caret excludes a commit and its ancestors. The dotted forms are shorthands.

**[ON SCREEN]** The range table of section 14A.8.

```text
Form                          Selects for git log and git rev-list                    What git diff does with the same text
----------------------------  ------------------------------------------------------  ---------------------------------------
B                             B and every ancestor of B                               compares the working tree with B
^A B, B --not A, A..B         reachable from B and not from A                         compares the trees of A and B
A...B                         reachable from A or B, not from both                    compares the merge base with B
A^!                           A alone: A minus all its parents                        compares A's parent with A
A^@                           all parents of A, and their ancestors                   (used as git diff A A^@ for a merge)
A^-                           A^1..A: A and, if A is a merge, everything the          compares A's first parent with A
                              merge brought in
--all, --branches, --tags,    every ref of that kind as a starting tip                not applicable
--remotes
```

An omitted side means HEAD: `origin/main..` is `origin/main..HEAD`.

**Diff.** In one sentence: `git diff` 🟢 SAFE compares exactly two snapshots, and every form of the command differs only in which two it picks.

```text
Form                          Left side                             Right side        Reads the graph?
----------------------------  ------------------------------------  ----------------  ---------------------------
git diff A B                  tree of A                             tree of B         no
git diff A..B                 tree of A                             tree of B         no: a synonym of A B
git diff A...B                tree of the merge base of A and B     tree of B         yes, to find the merge base
git diff --merge-base A B     the same as A...B                                       yes
```

The manual is blunt about the dots: "diff is about comparing two endpoints, not ranges", and the range notations do not mean a range as defined in the section on specifying ranges. The textbook adds that the two meanings are among the most common misreadings of Git.

So, the two sentences to keep. In `git log`, two dots mean "reachable from B and not from A", and three dots mean the symmetric difference. In `git diff`, two dots compare the two endpoints, and three dots compare the merge base with B.

Inside `.git`, none of this writes anything. Every command in this video is 🟢 SAFE.

## MENTAL MODEL

**[ON SCREEN]** "Colour green from B. Colour red from A. Red wins."

The textbook's analogy for ranges: colour every commit reachable from B green, then colour every commit reachable from A red, red winning. `A..B` is what stays green.

The picture breaks if you think of "between": a range is not an interval on a line, and with merges in the graph the green set can contain commits made long before A.

For diff, the analogy is two photographs. A diff is the comparison of two photographs. It is not the film between them: whatever happened in between, and in which order, is invisible. It breaks at one form. `A...B` chooses its first photograph by consulting the commit graph, so the same two branch names can give a different diff next week, after one of them has moved or been merged.

One sentence joins the two: log selects commits, diff selects two trees. If you catch yourself asking "which commits does this diff cover", you have mixed the models.

## DIAGRAM

**[DIAGRAM]** One graph, used for both halves. Draw it once. For each line below it, shade the commits it selects, or circle the two trees it compares.

```text
                    a8e8550---f37a7d8---a10f9a1   feat/report
                   /
  ...---ca7e2b7---2652768---e376e5b               main
        (merge base)

  main..feat/report    = { a8e8550, f37a7d8, a10f9a1 }                    what the branch has that main lacks
  feat/report..main    = { 2652768, e376e5b }                             what main has that the branch lacks
  main...feat/report   = { 2652768, e376e5b, a8e8550, f37a7d8, a10f9a1 }  both of the above

  git diff main..feat/report    compares the trees of e376e5b and a10f9a1   (two tips)
  git diff main...feat/report   compares the trees of ca7e2b7 and a10f9a1   (merge base and right tip)
  git diff feat/report...main   compares the trees of ca7e2b7 and e376e5b   (merge base and the other tip)
```

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch14a/revisions`.

**Part 1: naming one commit.**

<!-- snippet: ch14a/revisions/01-ancestors -->
```text
$ git show -s --format='%h %s' HEAD HEAD~1 HEAD~2 HEAD^
fd9fa62 Start the 0.3 cycle
e376e5b Mention the nightly run in the README
2652768 Add a separate pass mark for the nightly set
```
<!-- /snippet -->

`HEAD~1`, `HEAD~2`, and `HEAD^`, which is the same commit as `HEAD~1`. The difference between the tilde and the caret shows on merges. `8657273` is a merge commit. Predict which of `^1`, `~1` and `^2` name the same commit.

**[PAUSE]**

<!-- snippet: ch14a/revisions/01b-merge-parents -->
```text
# 8657273 is the merge of feat/text-utils. ^1 and ^2 choose a parent; ~1 always follows the first parent.
$ git rev-parse 8657273^1 8657273~1 8657273^2 8657273^2~1
389337aa37f6f099b27867f23fdf426b5c0307bd
389337aa37f6f099b27867f23fdf426b5c0307bd
c0d33a57b14ce8f345d5cf625ec8500fd30d85a5
dd70d9e494fe1312ef1f62b858ada29744f9edbe
$ git show -s --format='%h %s' 8657273^1 8657273^2 8657273^2~1
389337a Raise the pass mark to 0.75
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
```
<!-- /snippet -->

`^1` and `~1` are the same commit, the first parent, which is the branch that was merged into. `^2` is the tip of the branch that was merged in, and `^2~1` walks one step back on that side. The caret chooses among parents; the tilde walks generations along first parents.

<!-- snippet: ch14a/revisions/02-reflog -->
```text
$ git show -s --format='%h %s' 'HEAD@{1}' 'main@{2}'
e376e5b Mention the nightly run in the README
2652768 Add a separate pass mark for the nightly set
$ git show -s --format='%h %cd %s' --date=format:'%a %H:%M' 'main@{yesterday}'
d9d075d Mon 12:31 Remove the experimental BLEU scorer
```
<!-- /snippet -->

The reflog forms read your local reflog and nothing else. `main@{yesterday}` does not mean "the commit made yesterday". It means "what `main` pointed at in this clone 24 hours ago", here a commit from Monday 12:31, because the lab clock stands at Tuesday shortly before 13:00. On a teammate's machine, or in a fresh clone whose reflog starts today, the same expression gives a different answer or a warning. Use reflog forms to investigate your own repository; use dates with `git log --since` to investigate the project.

<!-- snippet: ch14a/revisions/03-upstream -->
```text
$ git rev-parse --abbrev-ref @{u}
origin/main
$ git show -s --format='%h %s' @{u}
e376e5b Mention the nightly run in the README
$ git log --oneline @{u}..
fd9fa62 Start the 0.3 cycle
```
<!-- /snippet -->

`@{u}` resolves through the upstream configuration; `@{u}..` is then "my commits that the remote-tracking branch does not have".

<!-- snippet: ch14a/revisions/04-search -->
```text
$ git show -s --format='%h %s' ':/Reformat sources'
9c8df98 Reformat sources: four-space indent, double quotes
$ git show -s --format='%h %s' 'v0.2.0^{/pass mark}'
389337a Raise the pass mark to 0.75
$ git show -s --format='%h %s' ':/nightly run'
e376e5b Mention the nightly run in the README
```
<!-- /snippet -->

Searching by message. `:/nightly run` matches two commits in this repository, the original on `feat/report` and its copy on `main`. The rule "youngest, from any ref" picked the copy. `<rev>^{/<text>}` restricts the search to the ancestors of one revision and is the form to use in scripts.

<!-- snippet: ch14a/revisions/05-peel -->
```text
$ git cat-file -t v0.1.0
tag
$ git rev-parse v0.1.0 v0.1.0^{} v0.1.0^{commit} v0.1.0^{tree}
2b135670afee8cdfbb883de84523a5c97a25d914
682bc717015f0ab43b873d1df1ac9da0ba01c393
682bc717015f0ab43b873d1df1ac9da0ba01c393
2d7515ae10f361f36e63b9496cd27f732f656c01
$ git rev-parse v0.1.0^0
682bc717015f0ab43b873d1df1ac9da0ba01c393
```
<!-- /snippet -->

An annotated tag is an object of its own, so the tag name and the commit it marks have different IDs: the first line is the tag object, the second and third are the commit, the fourth is its tree. `^{}` peels. You need the suffix when you compare IDs, as in "is the tag still on the commit we deployed".

<!-- snippet: ch14a/revisions/06-paths -->
```text
$ git rev-parse main:scorekit/config.py v0.1.0:scorekit/config.py :scorekit/config.py
12c95c24c2ec9a14f3b6770dc3cf21994a1fd054
c22ffa6cffb75db7b502a54f0e0d158689414374
12c95c24c2ec9a14f3b6770dc3cf21994a1fd054
$ git show v0.1.0:scorekit/config.py
# Thresholds used by the runner.
PASS_MARK = 0.7
$ git cat-file -t main:scorekit
tree
```
<!-- /snippet -->

Paths select inside a revision: a blob in `main`, the same path in `v0.1.0`, and with a leading colon alone, the index entry. `git show v0.1.0:scorekit/config.py` prints a file from a release without any checkout.

<!-- snippet: ch14a/revisions/07-not-a-commit -->
```text
$ git rev-parse --verify --quiet v0.1.0:run_eval.py
[exit status: 1]
$ git log --oneline -1 v0.3.0
fatal: ambiguous argument 'v0.3.0': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
```
<!-- /snippet -->

And when a name resolves to nothing, Git says so: a path that did not exist at that revision, a tag that does not exist.

**Part 2: ranges in `git log`.** `labs/run ch14a/ranges`. Use the diagram. For `main..feat/report`: shade.

**[PAUSE]**

<!-- snippet: ch14a/ranges/01-two-dots -->
```text
$ git log --oneline main..feat/report
a10f9a1 Write a report when --report <path> is given
f37a7d8 Mention the nightly run in the README
a8e8550 Add per-row report writer
$ git log --oneline ^main feat/report
a10f9a1 Write a report when --report <path> is given
f37a7d8 Mention the nightly run in the README
a8e8550 Add per-row report writer
$ git log --oneline feat/report --not main
a10f9a1 Write a report when --report <path> is given
f37a7d8 Mention the nightly run in the README
a8e8550 Add per-row report writer
```
<!-- /snippet -->

Three commits, and three spellings of the same set: two dots, a leading caret, and `--not`.

<!-- snippet: ch14a/ranges/02-other-way -->
```text
$ git log --oneline feat/report..main
e376e5b Mention the nightly run in the README
2652768 Add a separate pass mark for the nightly set
```
<!-- /snippet -->

The mirror image: two commits. Now three dots. Shade first.

**[PAUSE]**

<!-- snippet: ch14a/ranges/03-three-dots -->
```text
$ git log --oneline main...feat/report
e376e5b Mention the nightly run in the README
2652768 Add a separate pass mark for the nightly set
a10f9a1 Write a report when --report <path> is given
f37a7d8 Mention the nightly run in the README
a8e8550 Add per-row report writer
$ git log --oneline --left-right main...feat/report
< e376e5b Mention the nightly run in the README
< 2652768 Add a separate pass mark for the nightly set
> a10f9a1 Write a report when --report <path> is given
> f37a7d8 Mention the nightly run in the README
> a8e8550 Add per-row report writer
$ git log --oneline --graph --boundary main...feat/report
* e376e5b Mention the nightly run in the README
* 2652768 Add a separate pass mark for the nightly set
| * a10f9a1 Write a report when --report <path> is given
| * f37a7d8 Mention the nightly run in the README
| * a8e8550 Add per-row report writer
|/  
o ca7e2b7 Fail fast on an empty reference
```
<!-- /snippet -->

Five commits: the union of the two. `--left-right` says which side each commit is on, and `--boundary` adds the commit where the walk stopped, marked with an `o`: the merge base, `ca7e2b7`.

<!-- snippet: ch14a/ranges/05-parents -->
```text
$ git rev-parse 8657273^@
389337aa37f6f099b27867f23fdf426b5c0307bd
c0d33a57b14ce8f345d5cf625ec8500fd30d85a5
$ git log --oneline 8657273^!
8657273 Merge branch 'feat/text-utils'
$ git log --oneline 8657273^-
8657273 Merge branch 'feat/text-utils'
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
$ git log --oneline 8657273^1..8657273
8657273 Merge branch 'feat/text-utils'
c0d33a5 Add a tokens helper and use it in the metrics
dd70d9e Move normalize into scorekit/text.py
```
<!-- /snippet -->

The parent shorthands, on the merge commit. `^@` is both parents. `^!` is the commit alone. And `8657273^-` is the answer to "what did this merge bring in": the merge itself and the two commits of the side branch.

<!-- snippet: ch14a/ranges/06-one-commit-diff -->
```text
$ git diff --stat ec4fad7^!
 scorekit/metrics.py | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)
$ git diff --stat ec4fad7~1 ec4fad7
 scorekit/metrics.py | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)
```
<!-- /snippet -->

For an ordinary commit, `A^!` gives `git diff` the pair that `git show` uses.

<!-- snippet: ch14a/ranges/07-empty-range -->
```text
$ git log --oneline main..v0.2.0
$ git merge-base --is-ancestor v0.2.0 main && echo "v0.2.0 is an ancestor of main"
v0.2.0 is an ancestor of main
```
<!-- /snippet -->

An empty `A..B` means B is an ancestor of A, which is the test `git merge-base --is-ancestor` performs.

<!-- snippet: ch14a/ranges/04-several -->
```text
# Everything that is on some branch and not yet in main, in one query:
$ git log --oneline --branches --not main
a10f9a1 Write a report when --report <path> is given
f37a7d8 Mention the nightly run in the README
a8e8550 Add per-row report writer
2f2883f Report ROUGE-L in the runner
80ee55f Add ROUGE-L F-measure
1cbe38a Add longest-common-subsequence helper
$ git rev-list --count v0.1.0..main
20
```
<!-- /snippet -->

And one query lists all unmerged work in a repository: `--branches --not main`. Look at the last three lines of that list. `feat/rouge-l` appears although its content is on `main`: it was squash-merged, and a squash creates a new commit that has no parent link to the branch. The graph knows ancestry, not content. You have met that sentence in four different videos now.

**Part 3: the same dots in `git diff`.** `labs/run ch14a/diff-endpoints`.

<!-- snippet: ch14a/diff-endpoints/01-graph -->
```text
$ git log --graph --oneline --decorate -6 main feat/report
* e376e5b (HEAD -> main) Mention the nightly run in the README
* 2652768 Add a separate pass mark for the nightly set
| * a10f9a1 (feat/report) Write a report when --report <path> is given
| * f37a7d8 Mention the nightly run in the README
| * a8e8550 Add per-row report writer
|/  
* ca7e2b7 Fail fast on an empty reference
$ git merge-base main feat/report
ca7e2b7fcc44f8d5a494107b68440c3d4ec23b55
```
<!-- /snippet -->

The graph of the diagram. The branch has three commits of its own, `main` has two, and the merge base is `ca7e2b7`. Two endpoints, with and without the two dots:

<!-- snippet: ch14a/diff-endpoints/02-two-endpoints -->
```text
$ git diff --stat main feat/report
 scorekit/config.py | 1 -
 scorekit/report.py | 7 +++++++
 scorekit/runner.py | 3 +++
 3 files changed, 10 insertions(+), 1 deletion(-)
$ git diff --stat main..feat/report
 scorekit/config.py | 1 -
 scorekit/report.py | 7 +++++++
 scorekit/runner.py | 3 +++
 3 files changed, 10 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

Identical. Three files, and one of them is `scorekit/config.py` with a deletion. Now three dots. Predict which files are listed.

**[PAUSE]**

<!-- snippet: ch14a/diff-endpoints/03-three-dots -->
```text
$ git diff --stat main...feat/report
 README.md          | 2 ++
 scorekit/report.py | 7 +++++++
 scorekit/runner.py | 3 +++
 3 files changed, 12 insertions(+)
$ git diff --stat $(git merge-base main feat/report) feat/report
 README.md          | 2 ++
 scorekit/report.py | 7 +++++++
 scorekit/runner.py | 3 +++
 3 files changed, 12 insertions(+)
```
<!-- /snippet -->

`config.py` is gone from the list, and `README.md` has appeared. The second command spells the same comparison out with `git merge-base`. The two results disagree about two files, and each disagreement is worth reading.

<!-- snippet: ch14a/diff-endpoints/04-config -->
```text
# Two endpoints: the line that main added after the fork shows up as a deletion.
$ git diff main feat/report -- scorekit/config.py
diff --git a/scorekit/config.py b/scorekit/config.py
index 12c95c2..5efef40 100644
--- a/scorekit/config.py
+++ b/scorekit/config.py
@@ -1,3 +1,2 @@
 # Thresholds used by the runner.
 PASS_MARK = 0.75
-NIGHTLY_PASS_MARK = 0.6
# Three dots: the branch never touched the file.
$ git diff main...feat/report -- scorekit/config.py
```
<!-- /snippet -->

That is the hook. `feat/report` never touched `scorekit/config.py`. `main` added a line after the fork. Going from the tree of `main` to the tree of the branch, that line is absent, so the two-endpoint diff prints it as a deletion. The reviewer compared tips and read `main`'s own progress, reversed, as part of the feature. With three dots: no output.

<!-- snippet: ch14a/diff-endpoints/05-readme -->
```text
# The README paragraph was cherry-picked to main. Both tips have it, the merge base does not.
$ git diff --stat main feat/report -- README.md
$ git diff main...feat/report -- README.md
diff --git a/README.md b/README.md
index bfae817..08f9933 100644
--- a/README.md
+++ b/README.md
@@ -5,3 +5,5 @@ Scores model answers against reference answers.
     python3 -m scorekit.runner data/smoke.jsonl
 
 The runner prints one score line and exits with status 1 when exact_match is below the pass mark.
+
+The nightly job runs the same command on data/nightly.jsonl.
```
<!-- /snippet -->

The README paragraph is the opposite case. It was written on the branch and then cherry-picked to `main`. Both tips contain it, so the tips do not differ. The merge base does not contain it, so the three-dot diff shows it as a change of the branch, although `main` already has it.

<!-- snippet: ch14a/diff-endpoints/06-other-direction -->
```text
$ git diff --stat feat/report...main
 README.md          | 2 ++
 scorekit/config.py | 1 +
 2 files changed, 3 insertions(+)
```
<!-- /snippet -->

Swap the operands and the three-dot form compares the merge base with the other tip: what `main` did since the fork.

**[ON SCREEN]** The root-cause box of section 14A.2.

```text
Observed behavior : "git diff main feature" shows a setting being deleted that the feature never touched
Git state         : main gained commits after the branch forked; the feature's tip does not contain them
Mechanism         : A B (and A..B) compare the trees of the two tips, in the direction A to B
Root cause        : what main added after the fork is absent from the feature's tree, so it prints as "-"
Why Git does this : diff takes two endpoints; it does not look at ancestry unless asked (three dots)
Correct fix       : git diff main...feature, or git diff --merge-base main feature
Prevention        : three dots for review; in scripts the explicit --merge-base spelling
```

One more form, useful in forensics: the operands may be trees or blobs, addressed as `<rev>:<path>`.

<!-- snippet: ch14a/diff-endpoints/07-trees-and-blobs -->
```text
$ git diff --stat v0.1.0:scorekit main:scorekit
 __init__.py |  2 +-
 bleu.py     | 15 ---------------
 config.py   |  3 ++-
 metrics.py  | 24 ++++++++++--------------
 rouge.py    | 23 +++++++++++++++++++++++
 runner.py   | 31 +++++++++++++++++++++++--------
 text.py     | 12 ++++++++++++
 7 files changed, 71 insertions(+), 39 deletions(-)
$ git diff v0.1.0:scorekit/config.py main:scorekit/config.py
diff --git a/scorekit/config.py b/scorekit/config.py
index c22ffa6..12c95c2 100644
--- a/scorekit/config.py
+++ b/scorekit/config.py
@@ -1,2 +1,3 @@
 # Thresholds used by the runner.
-PASS_MARK = 0.7
+PASS_MARK = 0.75
+NIGHTLY_PASS_MARK = 0.6
```
<!-- /snippet -->

A directory compared between a release tag and `main`, and then one file. No checkout is needed.

## COMMON MISTAKES

**[ON SCREEN]** Each mistake with its root cause.

1. **Reviewing a branch with `git diff main feature`.** Root cause: two endpoints compare the two tips, so everything `main` gained after the fork appears reversed, as deletions by the feature.
2. **Reading `A..B` in `git diff` as a range of commits.** Root cause: diff compares two trees; the dots are a spelling of two endpoints, not a set.
3. **Thinking of `A..B` in `git log` as "the commits between A and B".** Root cause: a range is defined by reachability, and with merges it can contain commits older than A.
4. **Using `main@{yesterday}` in a script or in a message to a colleague.** Root cause: reflog forms read the local reflog; the same text names another commit, or nothing, in another clone.
5. **Using `:/text` to find "the" commit.** Root cause: it returns the youngest match reachable from any ref, which may be a copy on another branch; `<rev>^{/text}` restricts the search.

## PRODUCTION EXAMPLE

Three habits from the textbook, for a team that reviews and releases.

Review a branch with three dots: "what does this branch introduce", independent of what the target did meanwhile. Use two endpoints for "how do these two trees differ right now", for example a release tag against the deployed commit.

Before a push, `git log --oneline origin/main..HEAD` is "what am I about to publish". After a fetch, `git log --oneline HEAD..origin/main` is "what will a merge bring me".

And in scripts, write the explicit `--merge-base` spelling instead of three dots, so that the next reader does not have to remember which meaning the dots have here.

**[ON SCREEN]** Layer label: GitHub.

The "Files changed" tab of a pull request shows a three-dot diff, from the merge base to the head of the pull request branch, according to GitHub's documentation. That is why a pull request whose branch is behind its base does not show the base's newer commits as deletions, and why a change that reached the base by another route, as the README paragraph did, still appears in it until the branch is merged with or rebased onto the base.

So the author and the reviewer in the hook were both right about what they saw. They were looking at different pairs of snapshots.

## PRACTICE EXERCISE

Do Lab 10.4, "Predict two-dot and three-dot output for `git log` and for `git diff`", in [`lab-manual/m10-range-notation.md`](../../lab-manual/m10-range-notation.md).

The lab gives you a graph. For each of the four commands, before you run it:

- For the two `git log` forms: shade the selected commits on your drawing and write their subjects.
- For the two `git diff` forms: write which two commits' trees are compared, and list the files you expect in `--stat`.
- Then predict how each of the four outputs changes after the branch is updated from its base.

The challenge is Exercise 10.4, Level 2, "ranges on a history with a merge", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q394: "What is the difference between `..` and `...`, in `git log` and in `git diff`?"

Answer aloud first. There are four cells, and a strong answer fills all four with precise wording: for log, in terms of reachability; for diff, in terms of which two trees. It says why the same notation has two meanings, by saying what kind of thing each command operates on. It gives one practical consequence for review, and names what a pull request page shows. Drawing a small diverged graph while you talk is not a crutch here; it is the fastest way to be exact.

## RECAP

You should now be able to say:

A commit can be named through the graph with `~` and `^`, through my reflog with `@{n}`, through configuration with `@{u}`, by message with `:/text`, and a file inside it with `rev:path`; only the graph and object forms mean the same in every clone. In `git log`, `A..B` is what is reachable from B and not from A, and `A...B` is what is reachable from exactly one of them. In `git diff`, `A..B` compares the two tips and `A...B` compares the merge base with B. For review I use three dots, which is what a pull request shows. A range is a set by reachability, not an interval.

## HOMEWORK

Read sections 14A.1, 14A.2, 14A.7 and 14A.8 of [Chapter 14A](../../textbook/ch14a-history-investigation.md).

Do Exercise 10.2, Level 1, "names for commits", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).
