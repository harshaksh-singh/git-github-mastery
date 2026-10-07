# V040: Upstream branches, push.default, and git pull as fetch plus one integration step

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 7, Remote operations
- **Planned minutes:** 26
- **Prerequisites:** V030, V039
- **Textbook sections:** [Chapter 12](../../textbook/ch12-remote-operations.md), sections 12.5 and 12.6
- **Demo scripts:** `labs/ch12/upstream-config.sh`, `labs/ch12/pull-anatomy.sh`, `labs/ch12/pull-matrix.sh`

## HOOK

**[ON SCREEN]** `fatal: Need to specify how to reconcile divergent branches.`

An engineer runs `git pull` on Monday morning and gets this line, with a wall of hints above it and exit status 128. They post in the team channel: "pull is broken, is the server down?"

The server is fine. The network transfer succeeded. Something in their repository did change, and something did not. If you can say which is which, and name the three possible answers and what each does to history, you are answering one of this course's interview questions, and that line stops looking like an error. Hold on to the question: what changed, and what did not?

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Two topics today, and they belong together because the second one reads the first.

The first is the upstream of a branch: two lines of configuration that tell `status` what to compare with, `pull` what to integrate, and, under the default setting, `push` where to go. Remember that a remote is your repository's name for another repository, and that `origin/main` records where the server's `main` was at your last fetch. You will set an upstream in three different ways and watch a bare `git push` refuse for two different reasons.

The second is `git pull`. You already know both of its halves: fetch, from the last video, which downloads commits and never moves your own branches, and merge, from the module before, which joins another history into your branch. Today you watch them run one after the other, see where the seam is, and learn what decides whether the second half is a fast-forward, a merge, a rebase, or a refusal.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The four objectives.

After this video you can:

- Explain what `branch.<name>.remote` and `branch.<name>.merge` record, and set an upstream three ways.
- Predict where a plain `git push` goes under `push.default=simple`.
- Describe `git pull` as fetch followed by merge or rebase.
- Explain the "divergent branches" error and the three configurations that answer it.

## CONCEPT

**[ANIMATION]** walk: id=up columns=two_lines_in_.git/config,what_it_names rows=branch.<name>.remote:a_remote|branch.<name>.merge:a_ref_on_that_remote,_such_as_refs/heads/main|<branch>@{upstream}:the_remote-tracking_branch_that_records_it title=The_upstream_of_a_branch marks=2.2:hl at_1=70 at_2=25 at_3=80

**[ANIMATION]** step: 1

**The upstream.** In one sentence: the upstream of a local branch is the branch on a remote that `status` compares it with and that `pull` integrates from. It's two lines of configuration.

**[ANIMATION]** say: One_line_names_the_remote._What_does_the_other_one_hold?

Quick quiz. One of those two lines names the remote. Does the other one hold, A, `origin/main`, your remote-tracking ref, or B, `refs/heads/main`, the server's own name for the branch? Your answer?

**[PAUSE]**

**[ANIMATION]** step: 3

It's B. Precisely: `branch.<name>.remote` names a remote. `branch.<name>.merge` names a ref on that remote, such as `refs/heads/main`. Note what kind of name that is: the server's name, not your remote-tracking ref. If you picked A, you're in good company. The shorthand `<branch>@{upstream}`, short `@{u}`, resolves the pair to the remote-tracking branch that records it.

**[ANIMATION]** cards: question=Three_commands_read_the_upstream cards=git_status_and_git_branch_-vv:the_ahead_and_behind_counts|git_pull:what_to_integrate|git_push:where_to_push,_under_the_default_push.default at_1=12 at_2=50 at_3=72

**[ANIMATION]** step: 3

Three commands read it. `git status` and `git branch -vv` use it for the ahead and behind counts. `git pull` uses it for what to integrate. `git push` uses it for where to push under the default `push.default`.

**[ANIMATION]** step: up.3

Inside `.git`: only `.git/config`. An upstream is not a ref and not an object.

**[ANIMATION]** end

**`push.default`** decides what a bare `git push`, with no remote and no refspec, updates. There are five values, and the demo runs all of them from one branch. The default since Git 2.0 is `simple`.

**[ANIMATION]** remotes: solo branch=main ids=95671d3,510ee94,ef22149 note=the_bare_server title=git_pull_is_two_steps steps=setup,teammate-push,fetch,pull say_teammate_push=The_server's_main_moves_to_ef22149._Your_clone_has_not_asked. cmd_fetch=git_pull say_fetch=First_half,_the_fetch:_origin/main_moves_to_ef22149 say_pull=Second_half,_one_integration_step:_here_a_fast-forward id=six

**[ANIMATION]** step: teammate-push

**Pull.** In one sentence: `git pull` 🟡 CAUTION is `git fetch` followed by one integration of the fetched upstream into the current branch: a fast-forward, a merge or a rebase. When the two branches have diverged, Git makes you say which.

**[ANIMATION]** step: fetch

Precisely. Step 1 runs `git fetch` with the same arguments, so remote-tracking refs and `FETCH_HEAD` are updated.

**[ANIMATION]** step: pull

Step 2 integrates the `FETCH_HEAD` line that is marked for merging. If your branch is an ancestor of it, the branch is fast-forwarded, as on screen. If it is an ancestor of your branch, there is nothing to do. If neither is true the branches have diverged, and `pull.rebase`, `pull.ff` or a flag must select the method.

Inside `.git`: everything a fetch changes, then everything a merge or a rebase changes. The branch ref, the reflogs, whose entries begin with `pull`, `ORIG_HEAD`, the index and the working tree.

**[ANIMATION]** walk: columns=Git_version,an_unconfigured_pull_on_diverged_branches rows=before_2.27:merges_silently|2.27_to_2.33.0:merges_with_a_warning|since_2.33.1_and_2.34.0:fetches,_prints_the_hint_and_stops marks=1.2:bad,3.2:ok mono=off title=The_failure_mode_is_the_older_behavior at_1=62 at_2=75 at_3=86

**[ANIMATION]** step: 3

When not to pull? On a machine that should never create commits. And the failure mode is not the fatal message. That message is Git behaving well. The failure mode is the older behavior, which the textbook's version note records. Before Git 2.27 an unconfigured pull on diverged branches merged silently. From 2.27 to 2.33.0 it merged with a warning. Since Git 2.33.1 and 2.34.0 it fetches, prints the hint and stops.

## MENTAL MODEL

**[ON SCREEN]** "pull = fetch + exactly one integration step."

A picture helps. For the upstream, the textbook's analogy is a default correspondent printed on a letter template, so that `pull` and `push` need no address. It breaks because incoming and outgoing mail can have different defaults: `@{upstream}` and `@{push}` are two questions. With one remote they have the same answer. A later video shows a setup where they don't.

For pull, the analogy is "collect the mail and file it" as a single instruction. It breaks when filing needs a decision: if both sides have new commits there are two legitimate ways to combine them, they produce different histories, and pull will not choose for you.

**[ANIMATION]** step: six.pull

So read every pull output as two outputs glued together. Find the seam. Above it is the fetch, which cannot hurt you. Below it is a local integration, which is a merge or a rebase that you already know how to reason about, and how to undo.

## DIAGRAM

Try it now. Thirty seconds, on paper. You and Asha each added one commit on top of `ef22149`: yours is `c498de8`, hers is `527a708`. Draw that, then what a merge adds, then what a rebase leaves. How many new commits does each create? Say it out loud.

**[PAUSE]**

**[ANIMATION]** graph: [after the fetch half] ef22149-c498de8 main; ^ef22149-527a708 origin/main; HEAD=main; name:input || [git pull --no-rebase] || [git pull --rebase] => || [git pull --no-rebase] ef22149-c498de8-7044e06 main; ^ef22149-527a708 origin/main; 527a708-7044e06; HEAD=main; name:merge || => || || [git pull --rebase] ef22149-527a708-45eec24 main; 527a708 origin/main; ^ef22149-c498de8; reflog:c498de8; HEAD=main; name:rebase title=Same_input,_three_outcomes id=three

**[DIAGRAM]** Three panels, built left to right. First the diverged state after the fetch half. Then the same state integrated by merge. Then by rebase. Last, the caption for `--ff-only`.

```text
  diverged, after the fetch half:          --no-rebase (merge):                --rebase:

        c498de8    main (HEAD)                   c498de8---7044e06  main       ef22149---527a708---45eec24  main
       /                                        /         /                              origin/main
  ef22149---527a708  origin/main           ef22149---527a708  origin/main      (45eec24 replaces c498de8)

  --ff-only: refuses, nothing moves
```

**[ANIMATION]** step: input

Same input, three outcomes. Here's the input, after the fetch half: your `main` has `c498de8`, `origin/main` has `527a708`, and both grow from `ef22149`.

**[ANIMATION]** step: merge

The merge keeps `c498de8` and adds a commit with two parents, `7044e06`.

**[ANIMATION]** step: rebase

The rebase replaces `c498de8` with a new commit, `45eec24`, on top of `origin/main`. So each answer creates one new commit, of two very different kinds. And `--ff-only` refuses.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch12/upstream-config`.

**Part 1: no upstream.** A push asks the server to move one of its refs to a commit of yours. You create a branch, commit, and run a bare `git push` 🟡 CAUTION. Predict. Say it out loud.

**[PAUSE]**

<!-- snippet: ch12/upstream-config/01-no-upstream -->
```text
$ git switch -c feature/eval-harness
Switched to a new branch 'feature/eval-harness'
$ git branch -vv
* feature/eval-harness b83418c Add eval harness entry point
  main                 510ee94 [origin/main] Add retrieval config
$ git push
fatal: The current branch feature/eval-harness has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin feature/eval-harness

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.

[exit status: 128]
```
<!-- /snippet -->

`git branch -vv` shows `main` with `[origin/main]` in brackets and the new branch with nothing. The push refuses to guess, exit status 128, and tells you two ways forward.

<!-- snippet: ch12/upstream-config/02-push-u -->
```text
$ git push -u origin feature/eval-harness
To ../../server/support-bot.git
 * [new branch]      feature/eval-harness -> feature/eval-harness
branch 'feature/eval-harness' set up to track 'origin/feature/eval-harness'.
$ git config get --all --show-names --regexp "^branch\.feature/eval-harness\."
branch.feature/eval-harness.remote origin
branch.feature/eval-harness.merge refs/heads/feature/eval-harness
$ git branch -vv
* feature/eval-harness b83418c [origin/feature/eval-harness] Add eval harness entry point
  main                 510ee94 [origin/main] Add retrieval config
```
<!-- /snippet -->

`-u`, long form `--set-upstream`, pushes and then writes the two keys. Look at the value of `merge`: `refs/heads/feature/eval-harness`, the name of the branch on the remote.

<!-- snippet: ch12/upstream-config/03-shorthands -->
```text
$ git rev-parse --abbrev-ref @{upstream}
origin/feature/eval-harness
$ git rev-parse --symbolic-full-name @{u} @{push}
refs/remotes/origin/feature/eval-harness
refs/remotes/origin/feature/eval-harness
$ git log --oneline @{u}..
fc5bd70 Add first eval case
$ git status -sb
## feature/eval-harness...origin/feature/eval-harness [ahead 1]
```
<!-- /snippet -->

`@{u}` resolves to the remote-tracking ref. `@{push}` is where `git push` would send the branch. With one remote it's the same ref. `git log @{u}..` lists what you have not pushed, and `git log ..@{u}` lists what you have fetched and not integrated. Those two are worth an alias in your head.

**Part 2: the other ways an upstream appears.**

<!-- snippet: ch12/upstream-config/04-guess -->
```text
$ git switch feature/reranker
Switched to a new branch 'feature/reranker'
branch 'feature/reranker' set up to track 'origin/feature/reranker'.
$ git config get --all --show-names --regexp "^branch\.feature/reranker\."
branch.feature/reranker.remote origin
branch.feature/reranker.merge refs/heads/feature/reranker
```
<!-- /snippet -->

Switching to a name that exists only as a remote-tracking branch creates the local branch with its upstream. That is the guess from the clone video.

<!-- snippet: ch12/upstream-config/05-branch-u -->
```text
$ git switch -c docs/runbook main
Switched to a new branch 'docs/runbook'
$ git rev-parse --abbrev-ref @{u}
fatal: no upstream configured for branch 'docs/runbook'
[exit status: 128]
$ git branch -u origin/main
branch 'docs/runbook' set up to track 'origin/main'.
$ git status -sb
## docs/runbook...origin/main
$ git branch --unset-upstream
$ git status -sb
## docs/runbook
```
<!-- /snippet -->

`git branch -u` 🟡 sets an upstream for an existing branch without pushing, and `--unset-upstream` removes it. Watch `git status -sb`: with an upstream, the line has three dots and a second name. Without one, only the branch.

<!-- snippet: ch12/upstream-config/06-auto-setup-remote -->
```text
$ git config set push.autoSetupRemote true
$ git push
To ../../server/support-bot.git
 * [new branch]      docs/runbook -> docs/runbook
branch 'docs/runbook' set up to track 'origin/docs/runbook'.
$ git branch -vv
* docs/runbook         9416de1 [origin/docs/runbook] Start the runbook
  feature/eval-harness fc5bd70 [origin/feature/eval-harness: ahead 1] Add first eval case
  feature/reranker     336d5ee [origin/feature/reranker] Add reranker stub
  main                 510ee94 [origin/main] Add retrieval config
```
<!-- /snippet -->

With `push.autoSetupRemote=true`, a bare push of a branch that has no upstream creates the branch on the server and sets the upstream.

**[ON SCREEN]** The table "the ways an upstream comes to exist".

```text
Command                                             Upstream is set
--------------------------------------------------  --------------------------------------------------
git clone                                           for the initial branch
git switch <name> (guess),                          when the start point is a remote-tracking branch
git switch -c <new> <remote>/<branch>               (branch.autoSetupMerge, default true)
git push -u <remote> <branch>                       after a successful push
git branch -u <remote>/<branch>                     explicitly, no transfer
git push with push.autoSetupRemote=true             on the first push of a branch that has none
```

**Part 3: `push.default`.** You create `latency-fix` from `origin/main`, commit, and push. Predict: the branch has an upstream this time. Does the push go through?

**[PAUSE]**

<!-- snippet: ch12/upstream-config/07-simple-name-mismatch -->
```text
$ git switch -c latency-fix origin/main
Switched to a new branch 'latency-fix'
branch 'latency-fix' set up to track 'origin/main'.
$ git branch -vv
  docs/runbook         9416de1 [origin/docs/runbook] Start the runbook
  feature/eval-harness fc5bd70 [origin/feature/eval-harness: ahead 1] Add first eval case
  feature/reranker     336d5ee [origin/feature/reranker] Add reranker stub
* latency-fix          70d0911 [origin/main: ahead 1] Set request timeout
  main                 510ee94 [origin/main] Add retrieval config
$ git push
fatal: The upstream branch of your current branch does not match
the name of your current branch.  To push to the upstream branch
on the remote, use

    git push origin HEAD:main

To push to the branch of the same name on the remote, use

    git push origin HEAD

To choose either option permanently, see push.default in 'git help config'.

To avoid automatically configuring an upstream branch when its name
won't match the local branch, see option 'simple' of branch.autoSetupMerge
in 'git help config'.

[exit status: 128]
```
<!-- /snippet -->

It refuses again, for a different reason. `latency-fix` was created from `origin/main`, so automatic setup made `origin/main` its upstream. Under the default, `simple`, Git refuses to push when the upstream's name differs from the branch's name: it cannot know whether you mean "update `main`" or "publish `latency-fix`".

The other values each answer that question. `-c push.default=<value>` with `--dry-run` shows them without changing anything.

<!-- snippet: ch12/upstream-config/08-push-default-dry-runs -->
```text
$ git -c push.default=upstream push --dry-run
To ../../server/support-bot.git
   510ee94..70d0911  latency-fix -> main
$ git -c push.default=current push --dry-run
To ../../server/support-bot.git
 * [new branch]      latency-fix -> latency-fix
$ git -c push.default=nothing push --dry-run
fatal: You didn't specify any refspecs to push, and push.default is "nothing".
[exit status: 128]
$ git -c push.default=matching push --dry-run
To ../../server/support-bot.git
   b83418c..fc5bd70  feature/eval-harness -> feature/eval-harness
```
<!-- /snippet -->

`upstream`: `latency-fix -> main`, your commit would go to `main` on the server. `current`: a new branch `latency-fix`. `nothing`: refuses. And `matching`: read that line again. It pushed `feature/eval-harness`, a branch you were not on, and did not push the branch you were on. `matching` was the default before Git 2.0. That line is why the default changed.

**Part 4: pull, the fast-forward case.** `labs/run ch12/pull-anatomy`. No local commits.

<!-- snippet: ch12/pull-anatomy/01-fast-forward -->
```text
$ git pull
From ../../server/support-bot
   510ee94..ef22149  main       -> origin/main
Updating 510ee94..ef22149
Fast-forward
 app/retriever.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git reflog -1
ef22149 HEAD@{0}: pull: Fast-forward
$ git reflog show origin/main -1
ef22149 refs/remotes/origin/main@{0}: pull: fast-forward
```
<!-- /snippet -->

Find the seam. The `From` block is the fetch. `Updating ... Fast-forward` is the merge. Both reflogs say `pull`.

**Part 5: diverged.** Asha has pushed "Raise top_k to 8", and you have committed "Add dev requirements". Status says `[ahead 1]`, which is the stale view.

<!-- snippet: ch12/pull-anatomy/02-diverged -->
```text
# Asha has pushed "Raise top_k to 8"; you have committed "Add dev requirements".
$ git status -sb
## main...origin/main [ahead 1]
$ git pull
From ../../server/support-bot
   ef22149..527a708  main       -> origin/main
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint:
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
[exit status: 128]
```
<!-- /snippet -->

The first two lines are the fetch half, and it worked: `ef22149..527a708  main -> origin/main`. Then the hint and the fatal line. Now the question from the start. Predict: what does `git status -sb` say now, and did your branch move? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch12/pull-anatomy/03-after-fatal -->
```text
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git log --oneline --graph --decorate --all -4
* c498de8 (HEAD -> main) Add dev requirements
| * 527a708 (origin/main, origin/HEAD) Raise top_k to 8
|/  
* ef22149 Implement retrieval
* 510ee94 Add retrieval config
```
<!-- /snippet -->

`[ahead 1, behind 1]`. A pull that ends in this error is not a no-op.

**[ANIMATION]** graph: 510ee94-ef22149-c498de8 main; ef22149-527a708 origin/main origin/HEAD; HEAD=main title=After_the_fatal_message dx=260

Your remote-tracking ref moved, and status now tells the truth. Your branch, index and working tree are untouched. The fatal error is not a network failure and not damage. Git fetched successfully and then declined to pick one of two possible histories on your behalf.

The hint offers three answers. Each one as a flag.

<!-- snippet: ch12/pull-anatomy/04-ff-only -->
```text
$ git pull --ff-only
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
[exit status: 128]
```
<!-- /snippet -->

`--ff-only`, configuration `pull.ff=only`, means "move my branch only when there is nothing to combine". On diverged branches it refuses, with a different message from the unconfigured case.

<!-- snippet: ch12/pull-anatomy/05-merge -->
```text
$ git pull --no-rebase
Merge made by the 'ort' strategy.
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --graph --decorate -5
*   7044e06 (HEAD -> main) Merge branch 'main' of ../../server/support-bot
|\  
| * 527a708 (origin/main, origin/HEAD) Raise top_k to 8
* | c498de8 Add dev requirements
|/  
* ef22149 Implement retrieval
* 510ee94 Add retrieval config
$ git reflog -2
7044e06 HEAD@{0}: pull --no-rebase: Merge made by the 'ort' strategy.
c498de8 HEAD@{1}: commit: Add dev requirements
```
<!-- /snippet -->

`--no-rebase`, configuration `pull.rebase=false`, creates a merge commit with two parents, `7044e06`. Its message contains the URL because pull merges `FETCH_HEAD`, not `origin/main`.

To show the third answer from the same state, the demo takes the merge back. `git reset --hard ORIG_HEAD` 🔴 DANGEROUS. `ORIG_HEAD` holds the commit HEAD pointed at before the pull. The five answers: it moves the branch and overwrites the index and the working tree. It can destroy uncommitted changes. Preview with `git status` and by checking what `ORIG_HEAD` names. Recovery of the commit is through the reflog. Uncommitted changes are not recoverable that way. It is appropriate to take back a pull you did not want, on a clean tree. Chapter 11 has the full treatment.

<!-- snippet: ch12/pull-anatomy/06-back-to-diverged -->
```text
$ git reset --hard ORIG_HEAD
HEAD is now at c498de8 Add dev requirements
$ git status -sb
## main...origin/main [ahead 1, behind 1]
```
<!-- /snippet -->

<!-- snippet: ch12/pull-anatomy/07-rebase -->
```text
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git log --oneline --graph --decorate -4
* 45eec24 (HEAD -> main) Add dev requirements
* 527a708 (origin/main, origin/HEAD) Raise top_k to 8
* ef22149 Implement retrieval
* 510ee94 Add retrieval config
$ git reflog -4
45eec24 HEAD@{0}: pull --rebase (finish): returning to refs/heads/main
45eec24 HEAD@{1}: pull --rebase (pick): Add dev requirements
527a708 HEAD@{2}: pull --rebase (start): checkout 527a708c84be3e9847d2e65528c2d8cb7ce6b863
c498de8 HEAD@{3}: reset: moving to ORIG_HEAD
```
<!-- /snippet -->

`--rebase`, configuration `pull.rebase=true`, re-creates your commit on top of the upstream: `c498de8` became `45eec24`. History stays linear, and the old commit remains reachable from the reflog. Read the reflog from the bottom: start, pick, finish.

**Part 6: which setting wins.** `labs/run ch12/pull-matrix` runs `git pull` from one diverged state under every combination of the two configuration keys.

<!-- snippet: ch12/pull-matrix/02-config-only -->
```text
$ sh ../../try-pull.sh
pull.rebase=unset pull.ff=unset -> fatal: Need to specify how to reconcile divergent branches.
pull.rebase=unset pull.ff=only  -> fatal: Not possible to fast-forward, aborting.
pull.rebase=unset pull.ff=false -> merge commit
pull.rebase=unset pull.ff=true  -> merge commit
pull.rebase=false pull.ff=unset -> merge commit
pull.rebase=false pull.ff=only  -> fatal: Not possible to fast-forward, aborting.
pull.rebase=false pull.ff=false -> merge commit
pull.rebase=false pull.ff=true  -> merge commit
pull.rebase=true  pull.ff=unset -> rebase
pull.rebase=true  pull.ff=only  -> fatal: Not possible to fast-forward, aborting.
pull.rebase=true  pull.ff=false -> rebase
pull.rebase=true  pull.ff=true  -> rebase
```
<!-- /snippet -->

<!-- snippet: ch12/pull-matrix/03-flags -->
```text
$ sh ../../try-pull.sh --rebase | cut -d'>' -f2 | sort | uniq -c
  12  rebase
$ sh ../../try-pull.sh --no-rebase | cut -d'>' -f2 | sort | uniq -c
  12  merge commit
$ sh ../../try-pull.sh --ff-only | cut -d'>' -f2 | sort | uniq -c
  12  fatal: Not possible to fast-forward, aborting.
```
<!-- /snippet -->

Three rules, as observed on Git 2.55.0. With nothing set, a diverged pull is fatal. `pull.ff=only` in configuration beats `pull.rebase` in configuration: the row `pull.rebase=true pull.ff=only` refuses. A flag on the command line beats all configuration: each flag gave the same result in all twelve rows.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Reading the "divergent branches" message as a failed pull.** Root cause: the fetch half succeeded and moved `origin/main`; Git stopped before step 2 because two histories are possible and nothing was configured.
2. **Creating a topic branch from `origin/main` and running a bare `git push` with `push.default=upstream`.** Root cause: automatic setup made `origin/main` the upstream, and `upstream` pushes to it.
3. **Thinking `branch.<name>.merge` names `origin/main`.** Root cause: it stores the server's ref name, `refs/heads/main`; `@{u}` is what resolves the pair to the remote-tracking ref.
4. **Setting `pull.rebase=true` and `pull.ff=only` together and expecting a rebase.** Root cause: in configuration, `pull.ff=only` beats `pull.rebase`, as the matrix shows.
5. **Letting a deploy host run a plain `git pull`.** Root cause: on divergence a configured host merges or rebases and so creates a commit that exists nowhere else.

## PRODUCTION EXAMPLE

**[ANIMATION]** walk: id=pd columns=push.default,a_bare_git_push_on_latency-fix rows=simple:refuses,_the_upstream_is_named_main|upstream:latency-fix_->_main|current:a_new_branch_latency-fix|nothing:refuses|matching:pushes_feature/eval-harness_instead marks=1.2:ok,2.2:bad,5.2:bad title=Five_values_of_push.default at_1=20 at_2=45 at_3=60 at_4=70 at_5=80

**[ANIMATION]** step: 5

Now, out of the lab. An ML engineer branches `exp/lr-sweep` from `origin/main` and commits a sweep configuration. If their configuration says `push.default=upstream`, a bare `git push` sends those commits straight to `main`. With `simple` it stops.

**[ANIMATION]** end

The textbook gives two clean setups for topic branches. One: `branch.autoSetupMerge=simple`, which sets an upstream only when the names match, and needs Git 2.37 or later. Two: `git switch -c <name> --no-track origin/main` together with `push.autoSetupRemote`.

And for pull: a deploy host or a CI job should never create commits. Its update step is `git pull --ff-only`, or `git fetch` followed by an explicit checkout of the fetched commit. A host that merges on pull will one day build a commit that exists nowhere else.

**[ANIMATION]** walk: columns=when_you_pull,--rebase,--no-rebase rows=history:stays_linear:one_merge_commit_per_pull|your_commits:replayed_as_new,_untested_commits:exactly_what_you_tested mono=off title=Choosing_the_integration at_1=12 at_2=30

**[ANIMATION]** step: 2

On choosing between the two integrations for yourself. Rebase keeps history linear, but every replayed commit is a new commit that nobody has tested, and local merge commits are flattened unless you use `--rebase=merges`. Merge preserves exactly what you tested and adds one merge commit per pull. The textbook calls a global `pull.ff=only` a defensible default: pull never creates a commit unless you pass `--rebase` or `--no-rebase` at that moment.

## PRACTICE EXERCISE

Your turn. Do Lab 7.3, "The diverged pull error and the three configurations", in [`lab-manual/m07-remotes.md`](../../lab-manual/m07-remotes.md).

Predict before each pull:

- After the fatal message, what does `git status -sb` print, and which refs moved?
- For each of the three answers: how many new commits appear, how many parents does each have, and does any existing commit get a new ID?
- Which entry will be at the top of `git reflog` after each one?

The challenge is Exercise 7.5, Level 2, "the same pull, by merge and by rebase", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q205: "A pull stopped with "Need to specify how to reconcile divergent branches". What changed in the repository and what did not? Give the three answers and their effect on history."

**[PAUSE]**

Answer out loud before you open the answers file. A strong answer splits the pull into its two steps and places the stop exactly at the seam. It lists what moved and what did not in terms of refs, the index and the working tree. It names the three answers by flag and by configuration key, and for each describes the resulting history in one phrase: what is created, what is replaced, what is refused. A senior answer adds which one it would set globally and where it would never let a pull create a commit.

## RECAP

Let's land this. You should now be able to say:

**[ANIMATION]** step: pd.5

The upstream of a branch is two configuration values, a remote and the server's ref name, and `@{u}` resolves them to a remote-tracking branch. Under `push.default=simple`, a bare `git push` goes to the upstream only if its name equals the branch's name. Otherwise it refuses.

**[ANIMATION]** step: three.rebase

`git pull` is a fetch followed by one integration step. When the branches have diverged and nothing is configured, the fetch has already happened and Git stops before integrating. The three answers are fast-forward only, merge and rebase, and a flag on the command line beats configuration.

## HOMEWORK

Read sections 12.5 and 12.6 of [Chapter 12](../../textbook/ch12-remote-operations.md).

Today you found the seam in `git pull`: a fetch that can't hurt you, then one integration step that you choose. That Monday-morning message is Git asking a fair question. Do Lab 7.3 while this is fresh. Next time: `git push`. Until then, look at the state first and type second. See you in the next one.
