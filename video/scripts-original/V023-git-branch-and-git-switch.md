# V023: git branch and git switch

- **Part.** 1: Foundations
- **Module.** 4
- **Planned minutes.** 22
- **Prerequisites.** V022
- **Textbook sections.** [Chapter 7: Branches](../../textbook/ch07-branches.md), sections 7.5 and 7.6
- **Demo scripts.** `labs/ch07/branch-commands.sh`, `labs/ch07/switch-commands.sh`

## HOOK

**[ON SCREEN]** `error: the branch 'feature/f1' is not fully merged`

An engineer merges a feature branch into `main`, sees the merge in the log, and runs `git branch -d` to clean up. Git refuses: "not fully merged". They check again. The branch is merged into `main`. Git still refuses.

So they do what the hint suggests, and use capital `-D`.

**[PAUSE]**

Git was right, and the engineer deleted a branch with one commit that existed nowhere else under a name. The rule behind `-d` is not about `main`. It is about the upstream. If you do not know the rule, you will read a correct warning as a bug, and override it. This video gives you the rule, and with it every `git branch` and `git switch` operation with its risk label.

## INTRODUCTION

You know that a branch is a ref and that HEAD names one. This video is the working vocabulary on top of those facts.

`git branch` lists refs under `refs/heads/`, creates one at a commit, deletes one, renames one, or moves one. It never touches the working tree. `git switch` changes which branch HEAD names, and updates the index and the working tree. For each operation I will say what moves and how risky it is, and for the red one I will answer the five questions first.

## LEARNING OBJECTIVES

After this video you can:

1. List, create, rename, delete and force-move branches, and state the risk label of each.
2. Explain the rule by which `git branch -d` refuses a deletion.
3. Switch branches with and without local changes, and predict when Git refuses.
4. Translate between `git switch` and the older `git checkout` forms.

## CONCEPT

**Listing.** `git branch` lists local branches. `-v` adds the tip and its title and, for branches with an upstream, how far they are ahead or behind it. `-vv` names the upstream. `-r` lists `refs/remotes/`, the remote-tracking branches, and `-a` both namespaces.

**Merged, not merged, contains.** `--merged` lists "branches whose tips are reachable from" the named commit, HEAD by default, and `--no-merged` the others. `--contains <commit>` turns the question around: which branches reach this commit?

**Deleting.** `git branch -d` is 🟡 CAUTION: it deletes the ref after checking merge status. `git branch -D` is 🔴 DANGEROUS: it deletes regardless. Both delete the branch's reflog with it.

**[ON SCREEN]** `git branch -D`: the five questions.

What it changes: it deletes the ref and its reflog, with no merge check. What it can destroy: the branch reflog, and the only name of commits that were never checked out. How to preview: `git log --oneline main..<branch>` lists the commits that only this branch reaches. How to recover: `git branch <name> <id>` while the objects exist; the ID is in the deletion message, "was" followed by the ID, and the HEAD reflog still lists the commit if it was ever checked out. When it is appropriate: for a branch whose commits you have decided to abandon, or that you know to be squash-merged.

**The `-d` rule.** The manual: "The branch must be fully merged in its upstream branch, or in HEAD if no upstream was set". So the rule is about the upstream, not about `main`. That gives two cases that surprise people. A branch that is not merged into HEAD, but is pushed and equal to its upstream: `-d` deletes it, with a warning. And a branch that is merged into HEAD, but has one commit that its upstream lacks: `-d` refuses. Read both messages before reaching for `-D`.

**Renaming and forcing.** `git branch -m` is 🟡 CAUTION: it renames the ref, its reflog and its configuration section in one step, and logs the rename. The upstream still points at the old name on the remote, because renaming a local branch changes nothing on the remote. `git branch -f` is 🟡 CAUTION: without `-f`, `git branch` refuses to change an existing branch; with it, the ref moves, and the reflog records the reset, so the old position is one entry away. A branch that is checked out in a worktree cannot be force-moved at all; `git reset` is the command for that.

**`git switch`.** In one sentence: `git switch` changes which branch HEAD names and updates the index and the working tree to that branch's commit, refusing when a local change would be lost. It is 🟢 SAFE.

`git switch <branch>` points HEAD at the branch, then makes the index and working tree match its tip. `-c <new>` creates the branch first; the manual calls it "the transactional equivalent" of `git branch` followed by `git switch`. `-C` resets an existing branch like `git branch -f`, and is 🟡 CAUTION. `--detach` points HEAD at a commit instead of a branch. `-` means `@{-1}`, the previously checked-out branch or commit. `--orphan <new>` creates an unborn branch and removes all tracked files from the working tree, so the next commit starts a disconnected history.

**Local changes.** Switching does not require a clean working tree. A change in a file that is identical on both branches is carried along. A change in a file that differs is refused. Then you commit, stash, or use `--merge`. A version note from the textbook on that last option: since Git 2.55, `git switch -m` saves the local changes in a stash and reapplies them; the recommendation is to commit or stash yourself, and to use `--merge` when you understand the stash it may leave behind.

**`git checkout`.** It does the same jobs with older spellings. Learn them to read other people's scripts; write `switch` and `restore` yourself. `git checkout <name>` guesses whether you mean a branch or a path, which is the ambiguity the two newer commands remove. One difference in behavior: `switch --orphan` empties the working tree, while `checkout --orphan` keeps the files and stages them. The version note: `git switch` and `git restore` exist since Git 2.23 and are no longer labelled experimental from Git 2.51; `git checkout` still does all of the jobs and is not scheduled for removal.

**The one red switch.** `git switch --discard-changes`, also `-f`, is 🔴 DANGEROUS. It changes the index and working tree to the target and destroys uncommitted edits in the files it touches, with no preview beyond `git status` and no recovery for content that was never staged. It is appropriate only when you have decided to throw the edits away. It is not run in this video.

## MENTAL MODEL

Sort every command in this video by one question: does it only move a name, or does it also change files?

`git branch` only moves names. It never touches the working tree. Its risk is that a name was the only way to find some commits.

`git switch` moves HEAD and changes files. Its design is to refuse whenever changing a file would lose an edit, which is why it is green.

The model's limit is the pair of exceptions: `-D`, which removes a name and the journal that could have brought it back; and `--discard-changes`, which tells switch to stop refusing.

## DIAGRAM

**[DIAGRAM]** The state table for `git switch`, with the columns of the textbook's state tables. Rows appear as each form is demonstrated.

```text
 command                       working tree                 index            HEAD                       current branch ref
 ----------------------------  ---------------------------  ---------------  -------------------------  -------------------
 git switch <branch>           files that differ between    updated to the   ref: refs/heads/<branch>   unchanged
                               the two tips are replaced;   target tip
                               other local edits stay
 git switch -c <new>           as above, relative to the    as above         ref: refs/heads/<new>      unchanged
                               start point
 git switch --detach <commit>  as above                     as above         the commit ID              no current branch
 git switch --orphan <new>     tracked files removed        emptied          ref: refs/heads/<new>      unborn: no ref yet
```

In every row, the "current branch ref" column says "unchanged" or "none". A switch moves HEAD. It never moves a branch. The other columns of the textbook's table are the same for all rows: a `checkout:` line in the HEAD reflog; remote and GitHub unchanged.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch07/branch-commands.sh`.

```bash
labs/run ch07/branch-commands
```

A clone with five local branches, three of which have been pushed. The remote is a bare repository on disk.

<!-- snippet: ch07/branch-commands/01-list -->
```text
$ git branch
  docs/metrics
  feature/f1
  fix/typo-readme
* main
  spike/judge-cache
$ git branch -v
  docs/metrics      a8a1b5f Document the metrics
  feature/f1        de7c39b [ahead 1] F1: handle empty reference
  fix/typo-readme   6a04691 Fix grammar in README
* main              55144fd [ahead 4] Merge branch 'docs/metrics'
  spike/judge-cache 44483e6 Spike: cache judge responses
$ git branch -vv
  docs/metrics      a8a1b5f Document the metrics
  feature/f1        de7c39b [origin/feature/f1: ahead 1] F1: handle empty reference
  fix/typo-readme   6a04691 [origin/fix/typo-readme] Fix grammar in README
* main              55144fd [origin/main: ahead 4] Merge branch 'docs/metrics'
  spike/judge-cache 44483e6 Spike: cache judge responses
```
<!-- /snippet -->

`spike/judge-cache` has no upstream, so its line shows no relationship.

<!-- snippet: ch07/branch-commands/02-remotes -->
```text
$ git branch -r
  origin/feature/f1
  origin/fix/typo-readme
  origin/main
$ git branch -a
  docs/metrics
  feature/f1
  fix/typo-readme
* main
  spike/judge-cache
  remotes/origin/feature/f1
  remotes/origin/fix/typo-readme
  remotes/origin/main
```
<!-- /snippet -->

<!-- snippet: ch07/branch-commands/03-merged -->
```text
$ git log --oneline --graph --all
*   55144fd Merge branch 'docs/metrics'
|\  
| * a8a1b5f Document the metrics
|/  
* de7c39b F1: handle empty reference
* 35581b1 Add F1 metric
| * 44483e6 Spike: cache judge responses
|/  
| * 6a04691 Fix grammar in README
|/  
* d1e8f22 Add exact-match metric
* faf3622 Add README
$ git branch --merged
  docs/metrics
  feature/f1
* main
$ git branch --no-merged
  fix/typo-readme
  spike/judge-cache
$ git branch --contains origin/feature/f1
  docs/metrics
  feature/f1
* main
```
<!-- /snippet -->

`docs/metrics` and `feature/f1` are merged: `main` reaches their tips, one through a merge commit and one by fast-forward. `fix/typo-readme` and `spike/judge-cache` have commits that `main` does not reach.

Now the prediction for this video. Four branches: `docs/metrics`, `spike/judge-cache`, `fix/typo-readme`, `feature/f1`. For each, will `git branch -d` 🟡 CAUTION delete it or refuse? Use what you know: which are merged into HEAD, which have an upstream, and the state of that upstream.

**[PAUSE]**

<!-- snippet: ch07/branch-commands/04-delete -->
```text
$ git branch -d docs/metrics
Deleted branch docs/metrics (was a8a1b5f).
$ git branch -d spike/judge-cache
error: the branch 'spike/judge-cache' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D spike/judge-cache'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git branch -D spike/judge-cache
Deleted branch spike/judge-cache (was 44483e6).
$ git reflog show spike/judge-cache
fatal: ambiguous argument 'spike/judge-cache': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[exit status: 128]
$ git branch spike/judge-cache 44483e6
$ git reflog show spike/judge-cache
44483e6 spike/judge-cache@{0}: branch: Created from 44483e6
```
<!-- /snippet -->

`docs/metrics`: deleted. `spike/judge-cache`: refused, not fully merged, and it has no upstream. Then `-D` 🔴 DANGEROUS, with the five questions answered: after it, the branch's own reflog is gone. The commit itself still exists, and the "was" ID in the deletion message is what you need to recreate the branch.

<!-- snippet: ch07/branch-commands/05-upstream-rule -->
```text
$ git branch -d fix/typo-readme
warning: deleting branch 'fix/typo-readme' that has been merged to
         'refs/remotes/origin/fix/typo-readme', but not yet merged to HEAD
Deleted branch fix/typo-readme (was 6a04691).
$ git branch -d feature/f1
warning: not deleting branch 'feature/f1' that is not yet merged to
         'refs/remotes/origin/feature/f1', even though it is merged to HEAD
error: the branch 'feature/f1' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/f1'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
```
<!-- /snippet -->

The two surprising cases. `fix/typo-readme` is not merged into HEAD, but it is pushed and equal to its upstream, so `-d` deletes it with a warning. `feature/f1` is merged into HEAD, but it has one commit that its upstream lacks, so `-d` refuses. That second message is the one from the hook. Read it word by word: "not yet merged to" the upstream, "even though it is merged to HEAD".

<!-- snippet: ch07/branch-commands/06-rename -->
```text
$ git branch -m feature/f1 feature/f1-metric
$ git branch -vv
  feature/f1-metric de7c39b [origin/feature/f1: ahead 1] F1: handle empty reference
* main              55144fd [origin/main: ahead 4] Merge branch 'docs/metrics'
  spike/judge-cache 44483e6 Spike: cache judge responses
$ git config get branch.feature/f1-metric.merge
refs/heads/feature/f1
$ git reflog show feature/f1-metric
de7c39b feature/f1-metric@{0}: Branch: renamed refs/heads/feature/f1 to refs/heads/feature/f1-metric
de7c39b feature/f1-metric@{1}: commit: F1: handle empty reference
35581b1 feature/f1-metric@{2}: commit: Add F1 metric
d1e8f22 feature/f1-metric@{3}: branch: Created from HEAD
```
<!-- /snippet -->

`git branch -m` 🟡 CAUTION. The configuration still names the old branch on the remote as the upstream.

<!-- snippet: ch07/branch-commands/07-force -->
```text
$ git branch release/0.2 main
$ git branch release/0.2 main~1
fatal: a branch named 'release/0.2' already exists
[exit status: 128]
$ git branch -f release/0.2 main~1
$ git reflog show release/0.2
de7c39b release/0.2@{0}: branch: Reset to main~1
55144fd release/0.2@{1}: branch: Created from main
$ git branch -f main main~1
fatal: cannot force update the branch 'main' used by worktree at '$LAB/ch07/branch-commands/evalkit'
[exit status: 128]
```
<!-- /snippet -->

`git branch -f` 🟡 CAUTION. The reflog records `Reset to main~1`.

**[TERMINAL]** Caption bar: `labs/ch07/switch-commands.sh`.

```bash
labs/run ch07/switch-commands
```

`git switch` 🟢 SAFE.

<!-- snippet: ch07/switch-commands/01-create -->
```text
$ git switch -c feature/retry
Switched to a new branch 'feature/retry'
$ git switch -c feature/retry
fatal: a branch named 'feature/retry' already exists
[exit status: 128]
$ git switch main
Switched to branch 'main'
$ git switch -C feature/retry main~1
Switched to and reset branch 'feature/retry'
$ git reflog show feature/retry
b01a3f1 feature/retry@{0}: branch: Reset to main~1
2daf400 feature/retry@{1}: branch: Created from HEAD
```
<!-- /snippet -->

<!-- snippet: ch07/switch-commands/02-previous -->
```text
$ git switch main
Switched to branch 'main'
$ git switch -
Switched to branch 'feature/retry'
$ git switch -
Switched to branch 'main'
$ git rev-parse --abbrev-ref '@{-1}'
feature/retry
```
<!-- /snippet -->

<!-- snippet: ch07/switch-commands/03-detach -->
```text
$ git switch v0.1.0
fatal: a branch is expected, got tag 'v0.1.0'
hint: If you want to detach HEAD at the commit, try again with the --detach option.
[exit status: 128]
$ git switch --detach v0.1.0
HEAD is now at b01a3f1 Add exact-match metric
$ git switch -
Previous HEAD position was b01a3f1 Add exact-match metric
Switched to branch 'main'
```
<!-- /snippet -->

`git switch` wants a branch, and refuses a tag, with a hint. `--detach` is the explicit way to stand on a commit that is not a branch tip.

<!-- snippet: ch07/switch-commands/04-checkout-equivalents -->
```text
$ git checkout -b feature/cache
Switched to a new branch 'feature/cache'
$ git checkout main
Switched to branch 'main'
$ git checkout -B feature/cache main~1
Switched to and reset branch 'feature/cache'
$ git checkout -
Switched to branch 'main'
$ git checkout --detach
HEAD is now at 2daf400 Add batch runner
$ git checkout main
Switched to branch 'main'
```
<!-- /snippet -->

The older spellings, once: `checkout -b` for `switch -c`, `checkout -B` for `switch -C`, `checkout -` for `switch -`.

<!-- snippet: ch07/switch-commands/05-orphan -->
```text
$ git switch --orphan gh-pages
Switched to a new branch 'gh-pages'
$ cat .git/HEAD
ref: refs/heads/gh-pages
$ git status --short
$ ls -A
.git
$ git switch main
Switched to branch 'main'
$ git branch --list gh-pages
$ git checkout --orphan docs-site
Switched to a new branch 'docs-site'
$ git status --short
A  README.md
A  configs/eval.yaml
A  evalkit/metrics.py
A  evalkit/runner.py
$ git switch main
Switched to branch 'main'
```
<!-- /snippet -->

After `git switch --orphan gh-pages`, HEAD names a branch that has no commit, and the working tree is empty. An unborn branch disappears when you leave it, because no ref was ever written.

Now local changes. Two edits: one to `README.md`, which is identical on both branches, and one to `configs/eval.yaml`, which differs between them. Predict which switch succeeds.

**[PAUSE]**

<!-- snippet: ch07/switch-commands/06-local-changes -->
```text
$ printf '\nRun the tests with: python -m pytest\n' >> README.md
$ git switch feature/threshold
Switched to branch 'feature/threshold'
M	README.md
$ git switch main
Switched to branch 'main'
M	README.md
$ printf 'judge_model: judge-v2\nthreshold: 0.5\n' > configs/eval.yaml
$ git switch feature/threshold
error: Your local changes to the following files would be overwritten by checkout:
	configs/eval.yaml
Please commit your changes or stash them before you switch branches.
Aborting
[exit status: 1]
$ git status --short
 M README.md
 M configs/eval.yaml
```
<!-- /snippet -->

The edited `README.md` travelled to the other branch and back, marked `M`. The edit to `configs/eval.yaml` could not, because the two branches have different versions of that file, and the switch would have had to overwrite the edit.

## COMMON MISTAKES

1. **Overriding a `-d` refusal with `-D` without reading the message.** Root cause: `-d` tests the branch against its upstream, or against HEAD when it has no upstream; the message says which test failed.
2. **Believing that `-d` protects everything unmerged.** Root cause: a branch that equals its upstream is deleted with a warning, even if HEAD does not contain it.
3. **Expecting `git branch -m` to rename the branch on the server.** Root cause: renaming a local branch changes nothing on the remote; the upstream configuration still names the old branch.
4. **`git branch -f main <x>` fails with "used by worktree".** Root cause: a checked-out branch cannot be force-moved; that is what `git reset` is for.
5. **`git switch` refuses: local changes would be overwritten.** Root cause: the edited file differs between the two branch tips; commit or stash first.

## PRODUCTION EXAMPLE

A backend team's cleanup script loops over local branches and runs `git branch -D` on every branch that `git branch --merged main` lists, plus, for good measure, every branch older than a month. One engineer loses a spike that was never pushed and never checked out on that machine again: no upstream, no HEAD reflog entry near the top, and the branch reflog deleted with the branch. The safer script uses `-d`, lets Git apply its rule, prints every refusal, and leaves the refused branches to a human, who previews each with `git log --oneline main..<branch>`.

## PRACTICE EXERCISE

Do Exercise 4.5, Level 2, "which branches may be deleted?", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).

For each branch, write "deleted", "deleted with a warning" or "refused" before you run `git branch -d`, and next to it the test you expect Git to apply: against the upstream, or against HEAD.

## INTERVIEW QUESTION

Q107: "Explain the `git branch -d` rule in terms of the upstream. Give one case where `-d` deletes a branch that `main` does not contain, and one where it refuses a branch that `main` does contain."

Answer aloud. A strong answer quotes the rule in one sentence, then constructs the two cases concretely: what was pushed, what was merged, and what Git prints. Finish with what you check before using `-D`.

## RECAP

You should now be able to say: `git branch` only moves names and never touches the working tree. Creating a branch is green; renaming, force-moving and `-d` are amber; `-D` is red, because it deletes the ref and its reflog with no merge check. `-d` requires the branch to be fully merged in its upstream, or in HEAD if it has none. `git switch` moves HEAD and updates index and working tree; it carries local edits to files that are the same on both branches and refuses when a file differs. `git checkout -b`, `-B` and `-` are the older spellings of `switch -c`, `-C` and `-`.

## HOMEWORK

- Read sections 7.5 and 7.6 of [Chapter 7](../../textbook/ch07-branches.md).
- Challenge: Exercise 4.7, Level 3, "one switch carries the edit, the next one refuses", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
