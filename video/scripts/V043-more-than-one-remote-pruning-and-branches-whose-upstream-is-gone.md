# V043: More than one remote, pruning, and branches whose upstream is gone

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 7, Remote operations
- **Planned minutes:** 24
- **Prerequisites:** V040
- **Textbook sections:** [Chapter 12](../../textbook/ch12-remote-operations.md), sections 12.10, 12.11 and 12.16
- **Demo scripts:** `labs/ch12/fork-triangular.sh`, `labs/ch12/push-destination.sh`, `labs/ch12/remote-urls.sh`, `labs/ch12/prune-gone.sh`, `labs/ch12/prune-forgets.sh`

## HOOK

**[ON SCREEN]** `* [new branch]      feature/reranker -> feature/reranker`

A branch that the team merged and deleted a month ago is back on the server. Nobody intended it. It carries old commits, it shows up in the branch list, and by Thursday somebody has built a new feature on top of it.

No one ran a strange command. One engineer switched to an old local branch and typed `git push`. The line on screen is all Git said. To understand how an ordinary push resurrects a deleted branch, you need to know one thing a fetch never does by default. Hold on to that zombie branch. Later you make one yourself.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Two subjects today, joined by a common idea: your clone's picture of other repositories is a set of refs that only you maintain. A remote is your name for another repository, and a remote-tracking ref such as `origin/main` records where one of its branches was at your last fetch.

First, more than one remote. You build a fork in plain Git, with `origin` and `upstream`, and set it up so that you fetch from one repository and push to another. A fork is a second repository on a server, made from the shared one. That setup is called a triangular workflow, and it is where `@{upstream}` and `@{push}` finally give different answers. You also meet the small tools around remote URLs: a separate push URL, URL rewriting, renaming and removing a remote.

Second, pruning. A fetch creates and moves remote-tracking refs, but by default it never deletes one. You will see stale refs block a fetch, see what `gone` means, reproduce the zombie branch from the hook, and then look at the price of pruning automatically.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The four objectives.

After this video you can:

- Configure `origin` and `upstream` for a fork and say which one each command uses.
- Set separate fetch and push URLs, and rename or remove a remote.
- Explain what pruning deletes and what it never deletes.
- Explain how a branch deleted on the server comes back, and prevent it.

## CONCEPT

**More than one remote.** In one sentence: a repository can have any number of remotes, each with its own URL, refspecs and namespace of remote-tracking refs. Nothing connects them except the objects they share.

**[ANIMATION]** graph: 95671d3-510ee94 main origin/main upstream/main; HEAD=main => 95671d3-510ee94 main origin/main upstream/main; 510ee94-5d5414c feature/streaming origin/feature/streaming; HEAD=feature/streaming => 95671d3-510ee94 main origin/main; 510ee94-f11a751 upstream/main; 510ee94-5d5414c feature/streaming origin/feature/streaming; HEAD=feature/streaming => 95671d3-510ee94 main origin/main; 510ee94-f11a751 upstream/main; f11a751-4ce24f2 feature/streaming; 510ee94-5d5414c origin/feature/streaming; HEAD=feature/streaming => 95671d3-510ee94 main origin/main; 510ee94-f11a751 upstream/main; f11a751-4ce24f2 feature/streaming origin/feature/streaming; HEAD=feature/streaming; reflog:5d5414c => 95671d3-510ee94-f11a751 main origin/main upstream/main; f11a751-4ce24f2 feature/streaming origin/feature/streaming; HEAD=main; reflog:5d5414c title=Two_remotes_in_one_clone id=fork

**[ANIMATION]** step: fork.state-1

So adding a remote named `upstream` gives you `refs/remotes/upstream/*` next to `refs/remotes/origin/*`. Two namespaces. If both name the same commit, it is stored once. On screen is today's clone right after that step: `main`, `origin/main` and `upstream/main` are three names for one commit, `510ee94`.

By convention `origin` is the repository you push to and `upstream` is the shared repository you take changes from. That is a convention about names. Git attaches no meaning to either word.

**[ANIMATION]** cards: question=Which_remote_does_a_bare_git_push_use? cards=branch.<name>.pushRemote|remote.pushDefault|branch.<name>.remote|origin numbered=on at_1=45 at_2=55 at_3=64 at_4=72

**[ANIMATION]** step: 4

A triangular workflow fetches from one repository and pushes to another. Which remote a bare `git push` uses is decided by settings in a fixed order: `branch.<name>.pushRemote`, then `remote.pushDefault`, then `branch.<name>.remote`, then `origin`. Which branch name it uses is decided by `push.default`, from the video before last.

**[ANIMATION]** prune: [Asha's clone] 510ee94 main origin/main; ^510ee94-5176652 feature/reranker origin/feature/reranker; HEAD=main || [origin] 510ee94-52d3c1a main; ^510ee94-5176652; 5176652-52d3c1a; HEAD=none => [Asha's clone] 510ee94-52d3c1a origin/main; 510ee94-5176652 feature/reranker; 5176652-52d3c1a; 510ee94 main; HEAD=main; note:5176652:its_upstream_is_gone; cmd:git_fetch_--prune; name:pruned || => [Asha's clone] 510ee94-52d3c1a origin/main; 510ee94-5176652 feature/reranker; 5176652-52d3c1a; 510ee94 main; HEAD=feature/reranker; cmd:git_push; name:zombie || [origin] 510ee94-52d3c1a main; 510ee94-5176652 feature/reranker; 5176652-52d3c1a; HEAD=none title=A_branch_the_server_deleted id=prune captions=room dx=230

**[ANIMATION]** step: state-1

**Pruning.** In one sentence: a fetch creates and moves remote-tracking refs but by default never deletes one, so branches deleted on the server live on in your clone until you prune.

**[ANIMATION]** say: Three_commands:_git_remote_prune_--dry-run,_git_fetch_--prune,_fetch.prune=true

Three commands. `git remote prune --dry-run <remote>` previews. `git fetch --prune` 🟡 CAUTION deletes remote-tracking refs that no longer exist on the server and then fetches. And `fetch.prune=true` makes every fetch prune.

**[ANIMATION]** say: What_does_git_fetch_--prune_delete_in_this_clone?

Quick quiz. A branch was deleted on the server, and you run `git fetch --prune`. What does it delete in your clone? A, the remote-tracking ref only. B, the remote-tracking ref and your local branch. Your answer?

**[PAUSE]**

**[ANIMATION]** step: prune.pruned

It's A. What pruning deletes: stale remote-tracking refs and their reflogs. What it never touches: local branches, and their upstream settings. A local branch whose upstream ref has been pruned is reported as `gone`.

**[ON SCREEN]** The state table for `git remote prune <remote>`.

```text
Working tree   Index       HEAD        Current branch ref   Other refs and files in .git                 Remote      GitHub
------------   ---------   ---------   ------------------   ------------------------------------------   ---------   ---------
unchanged      unchanged   unchanged   unchanged            stale remote-tracking refs and their         unchanged   unchanged
                                                            reflogs deleted; upstream settings of
                                                            local branches kept
```

When not to prune automatically? Section 12.16 has the sentence: pruning is forgetting. A remote-tracking ref may be the last name that some commits have in your clone. Prune it and its reflog goes with it. If your clones are the team's only safety net, prune deliberately.

## MENTAL MODEL

**[ON SCREEN]** "Fetch adds and moves bookmarks. It does not remove them unless told to."

A picture helps. Go back to the address book from the first video of this module. Each remote is one entry with its own filing drawer. Two remotes, two drawers. A fetch files fresh copies into a drawer and updates the ones already there. It does not go through the drawer and throw out the bookmarks for things the supplier has discontinued. Pruning is that clean-out.

**[ANIMATION]** cards: question=A_stale_remote-tracking_ref_can_be_two_things cards=a_trap:a_local_branch_can_re-create_the_name_with_one_push|a_rescue:the_only_name_your_clone_has_for_deleted_commits at_1=30 at_2=62

**[ANIMATION]** step: 2

Where the picture breaks: in an office, an out-of-date bookmark is clutter. In Git it can be two things at once. It can be a trap, because a local branch that still points at a discontinued name can re-create it with one push. And it can be a rescue, because that stale bookmark may be the only name your clone has for commits that somebody deleted by mistake. The clean-out removes both.

## DIAGRAM

Try it now. Thirty seconds, on paper. Draw three boxes: the shared repository, your clone, and your fork. Add one arrow for fetch and one for push, and write `origin` or `upstream` next to the right box. Then say out loud which box your pushes go to.

**[PAUSE]**

**[DIAGRAM]** Three boxes, top to bottom. Draw the shared repository first, then your clone with the fetch arrow into it, then your fork with the push arrow out of the clone. Label each arrow with the ref shorthand.

```text
        upstream = server/support-bot.git        shared; you fetch from it
              |
              |  git fetch upstream, git pull --rebase         (@{upstream} = upstream/main)
              v
        you/support-bot     feature/streaming
              |
              |  git push                                      (@{push} = origin/feature/streaming)
              v
        origin = forks/you/support-bot.git       yours; a pull request offers this branch to upstream
```

Here's the answer. Changes come in from the top and go out at the bottom, to your fork, `origin`. The pull request, which is a GitHub object and not a Git one, closes the triangle from the bottom box back to the top.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch12/fork-triangular`.

**Part 1: a fork, in plain Git.**

<!-- snippet: ch12/fork-triangular/01-fork-and-clone -->
```text
# The Fork button, in plain Git: a server-side clone.
$ git clone --bare server/support-bot.git forks/you/support-bot.git
Cloning into bare repository 'forks/you/support-bot.git'...
done.
$ git clone forks/you/support-bot.git you/support-bot
Cloning into 'you/support-bot'...
done.
$ cd you/support-bot
$ git remote add upstream ../../server/support-bot.git
$ git fetch upstream
From ../../server/support-bot
 * [new branch]      main       -> upstream/main
$ git remote -v
origin	../../forks/you/support-bot.git (fetch)
origin	../../forks/you/support-bot.git (push)
upstream	../../server/support-bot.git (fetch)
upstream	../../server/support-bot.git (push)
```
<!-- /snippet -->

A server-side bare clone stands in for the Fork button. You clone your fork, add `upstream`, fetch it. `git remote -v` now has four lines.

<!-- snippet: ch12/fork-triangular/02-refs -->
```text
$ git show-ref --abbrev
510ee94 refs/heads/main
510ee94 refs/remotes/origin/HEAD
510ee94 refs/remotes/origin/main
510ee94 refs/remotes/upstream/HEAD
510ee94 refs/remotes/upstream/main
```
<!-- /snippet -->

Two namespaces, `origin/*` and `upstream/*`, each with its own `HEAD`, all naming the same commit.

**[ON SCREEN]** Layer label: GitHub.

Git has no notion of a fork. The Fork button creates a GitHub object: a server-side copy that stays connected to its parent and shares Git data with it in a repository network. To Git it is one more repository with a URL. According to the documentation, `gh repo fork --clone` names your fork `origin` and the parent `upstream`, the convention used here.

**[ANIMATION]** end

**Part 2: the triangle.**

```bash
git config set remote.pushDefault origin
git config set push.default current
git switch -c feature/streaming upstream/main
```

Predict: after one commit and a bare `git push` 🟡, which repository receives the branch? And what do `@{upstream}` and `@{push}` resolve to? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch12/fork-triangular/03-triangular-config -->
```text
$ git config set remote.pushDefault origin
$ git config set push.default current
$ git switch -c feature/streaming upstream/main
Switched to a new branch 'feature/streaming'
branch 'feature/streaming' set up to track 'upstream/main'.
# One commit made here: "Add streaming responses".
$ git push
To ../../forks/you/support-bot.git
 * [new branch]      feature/streaming -> feature/streaming
$ git rev-parse --abbrev-ref @{upstream} @{push}
upstream/main
origin/feature/streaming
$ git config get --all --show-names --regexp "^(remote\.pushdefault|push\.default|branch\.feature)"
remote.pushdefault origin
push.default current
branch.feature/streaming.remote upstream
branch.feature/streaming.merge refs/heads/main
```
<!-- /snippet -->

The push went to the fork.

**[ANIMATION]** step: fork.state-2

`@{upstream}` is `upstream/main`, and `@{push}` is `origin/feature/streaming`. Two different refs. `remote.pushDefault=origin` sends every bare push to your fork, whatever the upstream of the branch is, and the branch tracks `upstream/main`, so `git pull` takes changes from the shared repository.

`labs/run ch12/push-destination` takes the settings one at a time.

<!-- snippet: ch12/push-destination/01-push-default-remote -->
```text
$ git branch -vv
* feature/streaming 08b274c [upstream/main: ahead 1] Add streaming responses
  main              510ee94 [origin/main] Add retrieval config
$ git config set remote.pushDefault origin
$ git push --dry-run
To ../../forks/you/support-bot.git
 * [new branch]      feature/streaming -> feature/streaming
$ git rev-parse --abbrev-ref @{push}
fatal: cannot resolve 'simple' push to a single destination
[exit status: 128]
```
<!-- /snippet -->

With only `remote.pushDefault` set, the push goes to the fork under the branch's own name, but Git 2.55 cannot answer `@{push}` under `push.default=simple`.

<!-- snippet: ch12/push-destination/02-current -->
```text
$ git config set push.default current
$ git push
To ../../forks/you/support-bot.git
 * [new branch]      feature/streaming -> feature/streaming
$ git rev-parse --abbrev-ref @{upstream} @{push}
upstream/main
origin/feature/streaming
$ git for-each-ref --format='%(refname:short): pull from %(upstream:short), push to %(push:short)' refs/heads
feature/streaming: pull from upstream/main, push to origin/feature/streaming
main: pull from origin/main, push to origin/main
```
<!-- /snippet -->

`push.default=current` makes the destination a plain function of the branch name. The `for-each-ref` line is the one to remember in an incident: for every branch, where it pulls from and where it pushes to.

<!-- snippet: ch12/push-destination/03-per-branch -->
```text
$ git config set branch.feature/streaming.pushRemote upstream
$ git push --dry-run
To ../../server/support-bot.git
 * [new branch]      feature/streaming -> feature/streaming
$ git config unset branch.feature/streaming.pushRemote
$ git push --dry-run
Everything up-to-date
```
<!-- /snippet -->

`branch.<name>.pushRemote` overrides the rest for one branch.

Back in the fork demo. The shared repository has moved.

<!-- snippet: ch12/fork-triangular/04-two-comparisons -->
```text
$ git config set status.compareBranches "@{upstream} @{push}"
$ git fetch upstream
From ../../server/support-bot
   510ee94..f11a751  main       -> upstream/main
$ git status
On branch feature/streaming
Your branch and 'upstream/main' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

Your branch is up to date with 'origin/feature/streaming'.

nothing to commit, working tree clean
```
<!-- /snippet -->

`status.compareBranches`, Git 2.54 or later, makes `git status` report both relationships.

**[ANIMATION]** step: fork.state-3

Your branch has diverged from `upstream/main`, which moved to `f11a751`, and it is up to date with `origin/feature/streaming`.

<!-- snippet: ch12/fork-triangular/05-rebase-and-republish -->
```text
$ git pull --rebase
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/streaming.
$ git status -sb
## feature/streaming...upstream/main [ahead 1]
$ git push
To ../../forks/you/support-bot.git
 ! [rejected]        feature/streaming -> feature/streaming (non-fast-forward)
error: failed to push some refs to '../../forks/you/support-bot.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease
To ../../forks/you/support-bot.git
 + 5d5414c...4ce24f2 feature/streaming -> feature/streaming (forced update)
```
<!-- /snippet -->

**[ANIMATION]** step: fork.state-4

After a rebase onto the moved upstream, the branch in your fork still holds the old commit, so the push is not a fast-forward.

**[ANIMATION]** step: fork.state-5

`git push --force-with-lease` 🔴 DANGEROUS, as every forced push. The five answers are in the previous video. This is the legitimate case: a branch that only you push to, with a lease.

<!-- snippet: ch12/fork-triangular/06-sync-fork-main -->
```text
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git merge --ff-only upstream/main
Updating 510ee94..f11a751
Fast-forward
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
To ../../forks/you/support-bot.git
   510ee94..f11a751  main -> main
$ git log --oneline --graph --decorate --all -4
* 4ce24f2 (origin/feature/streaming, feature/streaming) Add streaming responses
* f11a751 (HEAD -> main, upstream/main, upstream/HEAD, origin/main, origin/HEAD) Raise top_k to 8
* 510ee94 Add retrieval config
* 95671d3 Add retriever skeleton
```
<!-- /snippet -->

**[ANIMATION]** step: fork.state-6

Bringing the fork's `main` up to date is a fast-forward from `upstream/main` and a push to `origin`.

**Part 3: URL tools.** `labs/run ch12/remote-urls`.

<!-- snippet: ch12/remote-urls/01-push-url -->
```text
$ git remote add upstream ../../server/support-bot.git
$ git remote set-url --push upstream DISABLED
$ git remote -v
origin	../../server/support-bot.git (fetch)
origin	../../server/support-bot.git (push)
upstream	../../server/support-bot.git (fetch)
upstream	DISABLED (push)
$ git config get --all --show-names --regexp "^remote\.upstream\."
remote.upstream.url ../../server/support-bot.git
remote.upstream.fetch +refs/heads/*:refs/remotes/upstream/*
remote.upstream.pushurl DISABLED
$ git push upstream main
fatal: 'DISABLED' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

`git remote set-url --push` 🟡 gives a remote a separate push URL. Here it is deliberately not a repository: a cheap guard that makes pushing to `upstream` impossible from this clone. The manual warns that a real fetch URL and push URL of one remote must lead to the same repository. For two different places, use two remotes.

<!-- snippet: ch12/remote-urls/02-two-push-urls -->
```text
$ git remote set-url --add --push origin ../../server/support-bot.git
$ git remote set-url --add --push origin ../../backup/support-bot.git
$ git remote -v
origin	../../server/support-bot.git (fetch)
origin	../../server/support-bot.git (push)
origin	../../backup/support-bot.git (push)
upstream	../../server/support-bot.git (fetch)
upstream	DISABLED (push)
$ git push origin main
To ../../server/support-bot.git
   510ee94..c19ab53  main -> main
To ../../backup/support-bot.git
   510ee94..c19ab53  main -> main
```
<!-- /snippet -->

Several push URLs make one push update several repositories, one after the other and not atomically.

<!-- snippet: ch12/remote-urls/03-instead-of -->
```text
$ git config set url.../../server/.insteadOf https://git.example.com/acme/
$ git remote add company https://git.example.com/acme/support-bot.git
$ git config get remote.company.url
https://git.example.com/acme/support-bot.git
$ git remote get-url company
../../server/support-bot.git
$ git ls-remote company main
c19ab53ef3dba868f5f8b8c60d19a9687069f366	refs/heads/main
```
<!-- /snippet -->

`url.<base>.insteadOf` rewrites URLs when they are used. The configuration keeps the URL that was written, and `git remote get-url` shows what will be contacted.

<!-- snippet: ch12/remote-urls/05-rename -->
```text
$ git branch -u company/main
branch 'main' set up to track 'company/main'.
$ git remote rename company canonical
$ git branch -r
  backup/HEAD -> backup/main
  backup/main
  canonical/HEAD -> canonical/main
  canonical/main
  origin/HEAD -> origin/main
  origin/main
$ git config get --all --show-names --regexp "^(remote\.canonical|branch\.main)\."
branch.main.remote canonical
branch.main.merge refs/heads/main
remote.canonical.url https://git.example.com/acme/support-bot.git
remote.canonical.fetch +refs/heads/*:refs/remotes/canonical/*
```
<!-- /snippet -->

<!-- snippet: ch12/remote-urls/06-remove -->
```text
$ git remote remove canonical
$ git branch -r
  backup/HEAD -> backup/main
  backup/main
  origin/HEAD -> origin/main
  origin/main
$ git branch -vv
* main c19ab53 Set request timeout
$ git remote remove canonical
error: No such remote: 'canonical'
[exit status: 2]
```
<!-- /snippet -->

`git remote rename` 🟡 moves the remote-tracking refs and rewrites the configuration, including the upstream of `main`. `git remote remove` 🟡 deletes the remote-tracking refs with their reflogs and removes upstream settings that pointed at the remote: `main` is left with none.

**Part 4: stale refs.** `labs/run ch12/prune-gone`. This runs in Asha's clone. Since she last fetched, `feature/reranker` was merged and deleted on the server, and the team replaced the branch `release` by `release/1.0`.

<!-- snippet: ch12/prune-gone/01-stale -->
```text
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/eval-harness
  origin/feature/reranker
  origin/main
  origin/release
$ git ls-remote --branches origin
edc57ed67d3ef2451ee0ad599a1769c54adc92c5	refs/heads/feature/eval-harness
52d3c1ada36809341bc3fac2af09a619cf85ec00	refs/heads/main
52d3c1ada36809341bc3fac2af09a619cf85ec00	refs/heads/release/1.0
```
<!-- /snippet -->

`git branch -r` reads the stale local view: it still lists `origin/feature/reranker` and `origin/release`. `git ls-remote` reads the server.

<!-- snippet: ch12/prune-gone/02-remote-show -->
```text
$ git remote show origin
* remote origin
  Fetch URL: ../../server/support-bot.git
  Push  URL: ../../server/support-bot.git
  HEAD branch: main
  Remote branches:
    feature/eval-harness                 tracked
    main                                 tracked
    refs/remotes/origin/feature/reranker stale (use 'git remote prune' to remove)
    refs/remotes/origin/release          stale (use 'git remote prune' to remove)
    release/1.0                          new (next fetch will store in remotes/origin)
  Local branches configured for 'git pull':
    feature/eval-harness merges with remote feature/eval-harness
    feature/reranker     merges with remote feature/reranker
    main                 merges with remote main
  Local refs configured for 'git push':
    feature/eval-harness pushes to feature/eval-harness (up to date)
    main                 pushes to main                 (local out of date)
```
<!-- /snippet -->

`git remote show origin` contacts the server and classifies every branch as tracked, stale or new. Now an ordinary fetch. Predict.

**[PAUSE]**

<!-- snippet: ch12/prune-gone/03-fetch-blocked -->
```text
$ git fetch
error: some local refs could not be updated; try running
 'git remote prune origin' to remove any old, conflicting branches
From ../../server/support-bot
   510ee94..52d3c1a  main        -> origin/main
 ! [new branch]      release/1.0 -> origin/release/1.0  (unable to update local ref)
[exit status: 1]
```
<!-- /snippet -->

Exit status 1. A stale ref can block a fetch. `origin/release` still exists, so `origin/release/1.0` cannot be created: one ref name cannot be a directory-like prefix of another, in any ref storage format.

<!-- snippet: ch12/prune-gone/04-prune -->
```text
$ git remote prune --dry-run origin
Pruning origin
URL: ../../server/support-bot.git
 * [would prune] origin/feature/reranker
 * [would prune] origin/release
$ git fetch --prune
From ../../server/support-bot
 - [deleted]         (none)      -> origin/feature/reranker
 - [deleted]         (none)      -> origin/release
 * [new branch]      release/1.0 -> origin/release/1.0
$ git branch -r
  origin/HEAD -> origin/main
  origin/feature/eval-harness
  origin/main
  origin/release/1.0
```
<!-- /snippet -->

The dry run previews. `git fetch --prune` deletes the two stale refs and then creates the new one.

<!-- snippet: ch12/prune-gone/05-gone -->
```text
$ git branch -vv
  feature/eval-harness edc57ed [origin/feature/eval-harness] Add eval harness entry point
  feature/reranker     5176652 [origin/feature/reranker: gone] Add reranker stub
* main                 510ee94 [origin/main: behind 2] Add retrieval config
$ git for-each-ref --format="%(refname:short) %(upstream:track)" refs/heads
feature/eval-harness 
feature/reranker [gone]
main [behind 2]
```
<!-- /snippet -->

Pruning never touches local branches. `feature/reranker` is still there, and its upstream is now reported as `gone`. `%(upstream:track)` gives the same fact to scripts.

**[ANIMATION]** step: prune.pruned

**Part 5: the zombie.** Asha switches to that branch. Predict what `git pull` does and what `git push` does.

**[PAUSE]**

<!-- snippet: ch12/prune-gone/06-zombie -->
```text
$ git switch feature/reranker
Switched to branch 'feature/reranker'
Your branch is based on 'origin/feature/reranker', but the upstream is gone.
  (use "git branch --unset-upstream" to fixup)
$ git pull
Your configuration specifies to merge with the ref 'refs/heads/feature/reranker'
from the remote, but no such ref was fetched.
[exit status: 1]
$ git push
To ../../server/support-bot.git
 * [new branch]      feature/reranker -> feature/reranker
$ git ls-remote --branches origin
edc57ed67d3ef2451ee0ad599a1769c54adc92c5	refs/heads/feature/eval-harness
5176652525c1216c70b16c80ecb9625c8f350595	refs/heads/feature/reranker
52d3c1ada36809341bc3fac2af09a619cf85ec00	refs/heads/main
52d3c1ada36809341bc3fac2af09a619cf85ec00	refs/heads/release/1.0
```
<!-- /snippet -->

`git pull` fails with a clear message. `git push` succeeds and re-creates the branch on the server. That is the hook: a branch that the team merged and deleted is back, with old commits. One ordinary push, and nothing looked wrong.

<!-- snippet: ch12/prune-gone/07-cleanup -->
```text
$ git push origin --delete feature/reranker
To ../../server/support-bot.git
 - [deleted]         feature/reranker
$ git switch main
Switched to branch 'main'
Your branch is behind 'origin/main' by 2 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)
$ git pull --ff-only
Updating 510ee94..52d3c1a
Fast-forward
 app/reranker.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 app/reranker.py
$ git branch -d feature/reranker
Deleted branch feature/reranker (was 5176652).
```
<!-- /snippet -->

Delete it on the server again, 🔴 `git push origin --delete`. Bring `main` up to date. And delete the local branch with `-d`, which refuses if the commits are not merged.

<!-- snippet: ch12/prune-gone/08-fetch-prune-config -->
```text
$ git config set fetch.prune true
# You have deleted feature/eval-harness on the server in the meantime.
$ git fetch
From ../../server/support-bot
 - [deleted]         (none)     -> origin/feature/eval-harness
$ git branch -vv
  feature/eval-harness edc57ed [origin/feature/eval-harness: gone] Add eval harness entry point
* main                 52d3c1a [origin/main] Merge branch feature/reranker
```
<!-- /snippet -->

With `fetch.prune=true` every fetch prunes.

**[ANIMATION]** graph: 95671d3-510ee94 main origin/main; ^510ee94-249e18e-509f067 origin/spike/hybrid-search; HEAD=main => + drop:origin/spike/hybrid-search; ghost:249e18e,509f067; cmd:git_fetch_--prune; name:pruned => 95671d3-510ee94 main origin/main; 510ee94-249e18e-509f067 rescue/hybrid-search; HEAD=main; cmd:git_branch_rescue/hybrid-search_509f067; name:rescued title=Pruning_is_forgetting id=forget dx=260

**[ANIMATION]** step: state-1

**Part 6: the price.** `labs/run ch12/prune-forgets`. Asha has deleted `spike/hybrid-search` on the server. Your clone has not fetched since.

<!-- snippet: ch12/prune-forgets/01-last-name -->
```text
# Asha has deleted spike/hybrid-search on the server. Your clone has not fetched since.
$ git branch -a --contains origin/spike/hybrid-search
  remotes/origin/spike/hybrid-search
$ git log --oneline -2 origin/spike/hybrid-search
509f067 Return the query as a stub result
249e18e Try hybrid search
$ git fetch --prune
From ../../server/support-bot
 - [deleted]         (none)     -> origin/spike/hybrid-search
$ git reflog show origin/spike/hybrid-search 2>&1 | head -1
fatal: ambiguous argument 'origin/spike/hybrid-search': unknown revision or path not in the working tree.
$ git fsck --unreachable | grep commit
unreachable commit 509f0670ffe15a66ea88e923674de467cf3a58ff
unreachable commit 249e18e16ceb304d7eea2d0b42a167965316b737
```
<!-- /snippet -->

Before the prune, your clone still named the two commits, and only the remote-tracking ref contained them. Afterwards the ref is gone, its reflog is gone with it, and `git fsck` lists the commits as unreachable. They stay in the object database until garbage collection, Git's cleanup of objects that nothing reaches, removes them.

<!-- snippet: ch12/prune-forgets/02-rescue -->
```text
$ git fsck --lost-found | grep commit
dangling commit 509f0670ffe15a66ea88e923674de467cf3a58ff
$ git branch rescue/hybrid-search 509f067
$ git log --oneline -2 rescue/hybrid-search
509f067 Return the query as a stub result
249e18e Try hybrid search
```
<!-- /snippet -->

Until then `git fsck --lost-found` can find the tip, `509f067`, and a branch gives it a name again. With `fetch.prune=true` this forgetting happens on every fetch, without a preview.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Pushing from an old local branch whose upstream is `gone`.** Root cause: pruning removes the remote-tracking ref but keeps the local branch and its upstream setting, so a push creates the branch on the server again.
2. **Believing `git branch -r` lists the server's branches.** Root cause: it lists remote-tracking refs in your clone, which a default fetch never deletes.
3. **Pushing a topic branch to the shared repository in a fork setup.** Root cause: without `remote.pushDefault` or `branch.<name>.pushRemote`, a branch created from `upstream/main` has `upstream` as its remote.
4. **Setting `fetch.prune=true` everywhere and counting on clones as a safety net.** Root cause: pruning deletes the ref and its reflog, which may be the last name of commits that were deleted by mistake.
5. **Giving one remote a fetch URL and a push URL that are different repositories.** Root cause: the manual requires both to lead to the same repository; two places need two remotes.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: fork.state-6

Now, out of the lab. You contribute a fix to an open-source evaluation library. Fork, clone, add `upstream`, branch from `upstream/main`, push to `origin`, open the pull request. Inside a company the same triangle appears when a team keeps a patched copy of a vendor repository. The textbook's advice for both: write down which remote is which before the first push.

**[ANIMATION]** step: forget.state-1

On the pruning side, picture a platform team that sets `fetch.prune=true` in every developer's global configuration to keep branch lists short. It works well for months.

**[ANIMATION]** step: forget.pruned

Then someone deletes the wrong branch on the server, a spike that was never merged. Within a day every clone that fetches forgets it. That is acceptable for merged feature branches and costly on that one day.

**[ANIMATION]** cards: cards=git_push_--mirror_and_--prune:delete_refs_on_the_server_that_your_repository_lacks|a_token_in_the_remote_URL:plain_text_in_.git/config,_printed_by_git_remote_-v|a_forced_push:does_not_remove_a_leaked_secret._Rotate_it_first. title=Three_to_remember marks=1:bad,2:bad,3:bad at_1=28 at_2=2 at_3=62

**[ANIMATION]** step: 1

Section 12.16 lists more cases where a technique from this module is the wrong one. Three to remember. `git push --mirror` and `git push --prune` delete refs on the server that your repository lacks. They are migration tools for a mirror clone and 🔴 everywhere else.

**[ANIMATION]** step: 3

A token inside the remote URL stores the secret in plain text in `.git/config`, and `git remote -v` prints it wherever it runs, CI logs included. Use a credential helper. And a forced push is not a way to remove a leaked secret. Rotate the secret first.

## PRACTICE EXERCISE

Your turn. Do Lab 7.5, "Upstream configuration and a triangular fork simulation", in [`lab-manual/m07-remotes.md`](../../lab-manual/m07-remotes.md).

Predict before you type:

- After adding `upstream` and fetching, which refs exist under `refs/remotes/`?
- For the topic branch you create: what will `@{upstream}` and `@{push}` resolve to, and which setting decides each?
- After the shared repository moves and you rebase, will a plain push to your fork be accepted? Why?

The challenge is Incident 8, [`incidents/08-branch-disappeared`](../../incidents/08-branch-disappeared/SYMPTOMS.md). Read the symptoms file only.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q214: "A branch that was deleted a month ago is back on the server, and nobody intended it. How did it happen, and what do you change?"

**[PAUSE]**

Answer out loud first. A strong answer reconstructs the sequence from the three kinds of ref: what the deletion removed, what it left behind in some clone, and which ordinary command turned what was left into a new branch on the server. It says how you would find out which clone did it. Then it separates the changes by layer: what each engineer does in their clone, what can be configured in Git, and what a server-side rule could refuse. It also names the cost of the obvious configuration fix.

## RECAP

Let's land this. You should now be able to say:

**[ANIMATION]** step: fork.state-6

Each remote has its own URL, refspec and namespace of remote-tracking refs. In a triangular setup I fetch from `upstream` and push to `origin`. `branch.<name>.pushRemote`, `remote.pushDefault`, `branch.<name>.remote` and `origin` decide the push remote, in that order.

**[ANIMATION]** step: prune.pruned

A fetch never deletes a remote-tracking ref unless it prunes. Pruning deletes stale remote-tracking refs and their reflogs and leaves local branches alone, marked `gone`.

**[ANIMATION]** step: prune.zombie

A push from such a branch re-creates it on the server. Pruning is also forgetting, so automatic pruning has a price.

## HOMEWORK

Read sections 12.10 and 12.11 of [Chapter 12](../../textbook/ch12-remote-operations.md).

Do Lab 7.6, "Prune and "gone" branches", in [`lab-manual/m07-remotes.md`](../../lab-manual/m07-remotes.md).

Today you kept two remotes apart, and you made a zombie branch on purpose, so you'll recognise one when it turns up. Do Lab 7.5 while this is fresh. Next time: refspecs in depth, transports, and two diagnoses from first principles. Until then, look at the state first and type second. See you in the next one.
