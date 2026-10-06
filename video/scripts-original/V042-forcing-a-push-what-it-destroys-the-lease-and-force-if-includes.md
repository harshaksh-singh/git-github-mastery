# V042: Forcing a push: what it destroys, the lease, and --force-if-includes

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 7, Remote operations
- **Planned minutes:** 24
- **Prerequisites:** V041
- **Textbook sections:** [Chapter 12](../../textbook/ch12-remote-operations.md), section 12.8
- **Demo scripts:** `labs/ch12/force-push.sh`, `labs/ch12/lease-forms.sh`

## HOOK

**[ON SCREEN]** "Someone force-pushed with the 'safe' option. A colleague's commit still disappeared."

The CTO's question, word for word from the chapter: "Someone force-pushed with the 'safe' option, `--force-with-lease`, and a colleague's commit still disappeared from the shared branch. How, and where is that commit now?"

The short answer: the lease was satisfied by a fetch that nobody looked at, and the commit still sits in places you can name. The long answer is this video. You will build the losing sequence step by step, watch the guard pass when it should have refused, and then find the commit in three different places.

## INTRODUCTION

In the last video a push was refused because it was not a fast-forward, and the fix was to integrate. But sometimes you do not want to integrate. You rebased your own pull request branch. You squashed two work-in-progress commits. The server's history is the old one and you want it replaced.

That is what force is for. It is also the one push that can remove other people's commits from a branch, including commits you have never seen.

So today has three layers. Plain `--force` and what it destroys. `--force-with-lease`, what it compares, and the exact sequence that defeats it. And the two stronger forms that survive that sequence. Then you cross to the teammate's clone and see what the rewrite does there, because the damage has a second act that surprises people even more than the first.

## LEARNING OBJECTIVES

**[ON SCREEN]** The four objectives.

After this video you can:

- Explain what a forced push does to the server's ref and to teammates' commits.
- Explain what `--force-with-lease` checks, and construct the sequence in which it fails to protect.
- Explain what `--force-if-includes` adds.
- Find the overwritten commits afterwards and say who still has them.

## CONCEPT

Recall the seven steps of a push. Step 2 was the client rule: an existing branch may only be fast-forwarded. A forced push tells step 2 to skip the fast-forward test. The server's ref is set to your commit, and whatever it named before is no longer reachable from that ref.

`git push --force` 🔴 DANGEROUS; also `-f`, or a plus sign before one refspec. This is the first dangerous command of the video, so the five answers come before anything is run.

**[ON SCREEN]** The five answers, one at a time.

What it changes: the ref on the server, and your remote-tracking ref.

What it can destroy: every commit on the server's branch that is not in your history, including commits you have never seen. A default bare server has no reflog, so it keeps no pointer to them.

How to preview: `git fetch`, then `git log --oneline HEAD..origin/<branch>` lists exactly the commits that would be dropped. `git push --dry-run --force` prints the server's current commit ID to the left of the three dots.

How to recover: the old tip survives in any clone that had it, a teammate's branch or the reflog of anybody's remote-tracking ref, and, until the server's garbage collection removes it, as an unreachable object on the server. Push it back.

When it is appropriate: on a branch that only you use, such as your own pull request branch after a rebase, or in a coordinated history rewrite. Then use a lease.

Now the lease. `--force-with-lease` means: force only if the server is where I think it is. The bare form says "overwrite only if the server's branch still equals my remote-tracking ref".

And there is the weakness, in the definition. The lease does not compare the server with what you have seen. It compares the server with your remote-tracking ref. Anything that moves that ref renews the lease: an editor's auto-fetch, a scheduled job, or you in another terminal.

`--force-if-includes` adds a second condition: the tip of the remote-tracking ref must be reachable from some entry in the reflog of your local branch, meaning your branch contained that commit at some time. The setting `push.useForceIfIncludes=true` turns it on for every lease.

And the explicit form, `--force-with-lease=<ref>:<expect>`, ignores the remote-tracking ref and compares the server with a commit you name.

**[ON SCREEN]** The table of forms.

```text
Form                                        The server's ref must equal                   Defeated by a background fetch
------------------------------------------  --------------------------------------------  ------------------------------
--force, -f, +<refspec>                     nothing is checked                            not applicable
--force-with-lease                          your remote-tracking ref, for every ref       yes
                                            pushed
--force-with-lease=<ref>                    your remote-tracking ref, for that ref        yes
--force-with-lease=<ref>:<expect>           the commit you name; empty means "absent"     no
--force-with-lease[=<ref>]                  your remote-tracking ref, whose tip must      no
  plus --force-if-includes                  also have been in your branch at some time
```

When not to force at all: on a branch that someone else pushes to, unless you have told them. And never as a routine undo on `main`. The textbook marks that as outdated advice: tutorials that teach "`git reset --hard`, then `git push -f`" teach the one habit in this chapter that loses other people's work. Undo published commits with `git revert`.

## MENTAL MODEL

**[ON SCREEN]** "Compare-and-swap. But who did the reading?"

The textbook's model for the lease is the compare-and-swap of optimistic locking: "set the branch to my commit only if it still has the value I last read".

It breaks at the word "I". Your Git does the reading, and a fetch that you never looked at refreshes the value. In a database, you read a row, you compute, you write back with the old value as a condition. Here, something else can re-read the row on your behalf, silently, between your computing and your writing, and the condition then holds for a value you never used.

So keep two things apart that feel like one: what my clone has fetched, and what I have seen or integrated. A remote-tracking ref records the first. Only your branch's own history records the second, and that is exactly what `--force-if-includes` consults.

## DIAGRAM

**[DIAGRAM]** New diagram: a three-column timeline. Reveal one row at a time, top to bottom, and keep the server column in the middle.

```text
  step   you                                server: feature/prompt-cache      Asha
  ----   --------------------------------   ------------------------------   -----------------------------
   1     squash locally -> 1a1fa49          12cdd3d                           has 12cdd3d
         origin/... still 12cdd3d
   2                                        833bc8a   <--------------------   pushes "Add cache test"
   3     push --force-with-lease            833bc8a
         REJECTED (stale info):
         origin/... 12cdd3d != 833bc8a
   4     background fetch:                  833bc8a
         origin/... moves to 833bc8a
         (you never read 833bc8a)
   5     push --force-with-lease            1a1fa49                           her commit is no longer
         ACCEPTED: origin/... == server                                       on the server's branch
   6                                        833bc8a: unreachable object,      833bc8a: still on her
                                            no reflog                         local branch
```

Row 3 is the lease working. Row 4 is nobody doing anything wrong. Row 5 is the same command as row 3 with the opposite result.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch12/force-push`. The branch is `feature/prompt-cache`, shared between you and Asha.

**Step 1: the rewrite.** You squash two published commits into one, after marking the old tip with a branch.

<!-- snippet: ch12/force-push/01-rewrite -->
```text
$ git log --oneline --decorate -3
12cdd3d (HEAD -> feature/prompt-cache, origin/feature/prompt-cache) wip: ttl
bdbe39f Add prompt cache
510ee94 (origin/main, origin/HEAD, main) Add retrieval config
$ git branch backup/prompt-cache
$ git reset --soft HEAD~2
$ git commit -q -m "Add prompt cache with TTL"
$ git log --oneline --graph --decorate --all -4
* 1a1fa49 (HEAD -> feature/prompt-cache) Add prompt cache with TTL
| * 12cdd3d (origin/feature/prompt-cache, backup/prompt-cache) wip: ttl
| * bdbe39f Add prompt cache
|/  
* 510ee94 (origin/main, origin/HEAD, main) Add retrieval config
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache [ahead 1, behind 2]
```
<!-- /snippet -->

The graph shows your new commit `1a1fa49` beside the old pair, with `backup/prompt-cache` on the old tip. Status: ahead 1, behind 2. That is what a rewrite looks like to Git: divergence.

**Step 2: the lease holds.** Meanwhile Asha pushes a test commit on top of the old history. You try to publish. Predict.

**[PAUSE]**

<!-- snippet: ch12/force-push/02-lease-holds -->
```text
# Asha, in her clone: git push   (her test commit lands on top of "wip: ttl")
$ git push --force-with-lease
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> feature/prompt-cache (stale info)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git rev-parse --short origin/feature/prompt-cache
12cdd3d
$ git ls-remote origin feature/prompt-cache
833bc8ad64cffe287b9e4280a0c93cb6537d625b	refs/heads/feature/prompt-cache
```
<!-- /snippet -->

`! [rejected] ... (stale info)`. Your remote-tracking ref says `12cdd3d`; the server has the commit that starts `833bc8a`. The word is `rejected`, without "remote": your own Git decided, from the advertisement. Asha's commit is safe.

**Step 3: something fetches.**

<!-- snippet: ch12/force-push/03-background-fetch -->
```text
# What an editor or a scheduled job does behind your back:
$ git fetch
From ../../server/support-bot
   12cdd3d..833bc8a  feature/prompt-cache -> origin/feature/prompt-cache
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache [ahead 1, behind 3]
```
<!-- /snippet -->

Your remote-tracking ref now equals the server. You have not looked at Asha's commit, but the lease cannot know that.

**Step 4: the two stronger forms.** Predict whether each of these passes.

**[PAUSE]**

<!-- snippet: ch12/force-push/04-guards -->
```text
$ git push --force-with-lease --force-if-includes
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> feature/prompt-cache (remote ref updated since checkout)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout. If you want to integrate the
hint: remote changes, use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git push --force-with-lease=feature/prompt-cache:backup/prompt-cache
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> feature/prompt-cache (stale info)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

Both refuse. With `--force-if-includes`: "remote ref updated since checkout". Your branch never contained `833bc8a`. With the explicit form, the server is compared with the backup branch at the commit you rewrote, and it differs: stale info.

**Step 5: the bare lease.** Same command as step 2. Predict.

**[PAUSE]**

<!-- snippet: ch12/force-push/05-lease-defeated -->
```text
$ git push --force-with-lease
To ../../server/support-bot.git
 + 833bc8a...1a1fa49 feature/prompt-cache -> feature/prompt-cache (forced update)
[exit status: 0]
$ git ls-remote origin feature/prompt-cache
1a1fa4964ca5cb5de17112e84ab62441aeac53fd	refs/heads/feature/prompt-cache
```
<!-- /snippet -->

`+ 833bc8a...1a1fa49 (forced update)`, exit status 0. Asha's commit is no longer on the server's branch.

**[ON SCREEN]** The first root-cause box of section 12.8.

```text
Observed behavior : git push --force-with-lease overwrote a teammate's commit that I had never looked at.
Git state         : refs/remotes/origin/feature/prompt-cache had been moved to the teammate's commit
                    by a fetch; my local branch did not contain that commit.
Mechanism         : the lease compares the server's ref with my remote-tracking ref. After the fetch
                    they were equal, so the condition "nothing changed since I looked" was true.
Root cause        : a remote-tracking ref records what my clone has fetched, not what I have seen or
                    integrated. Any fetch renews the lease.
Why Git does this : the remote-tracking ref is the only record Git has of "the state I based my work on",
                    and the manual says so and calls the forms without an explicit value experimental.
Correct fix       : restore the overwritten commit (below); nothing can be un-pushed.
Prevention        : --force-with-lease together with --force-if-includes (or push.useForceIfIncludes=true),
                    or the explicit --force-with-lease=<ref>:<commit>; and never rewrite a branch
                    that someone else pushes to without telling them.
```

**Step 6: where is the commit now?**

<!-- snippet: ch12/force-push/06-what-is-left -->
```text
$ git reflog show origin/feature/prompt-cache
1a1fa49 refs/remotes/origin/feature/prompt-cache@{0}: update by push
833bc8a refs/remotes/origin/feature/prompt-cache@{1}: fetch: fast-forward
12cdd3d refs/remotes/origin/feature/prompt-cache@{2}: update by push
$ ls ../../server/support-bot.git/logs
ls: ../../server/support-bot.git/logs: No such file or directory
[exit status: 1]
$ git -C ../../server/support-bot.git fsck --unreachable --no-reflogs | grep commit
unreachable commit 833bc8ad64cffe287b9e4280a0c93cb6537d625b
unreachable commit 12cdd3d76a43de79f4cbd643a62ead3eb6d44dec
unreachable commit bdbe39fab454ec59484b2f16d05ff952de9cd6e6
```
<!-- /snippet -->

Place one: your own clone. The background fetch recorded it, and `origin/feature/prompt-cache@{1}` names it. Place two: the server's object database, as an unreachable commit. The server has no `logs` directory at all, so no pointer, only the object.

**Step 7: the teammate's clone.** Asha fetches.

<!-- snippet: ch12/force-push/07-teammate-fetch -->
```text
$ cd ../../asha/support-bot
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache
$ git fetch
From ../../server/support-bot
 + 833bc8a...1a1fa49 feature/prompt-cache -> origin/feature/prompt-cache  (forced update)
$ git status -sb
## feature/prompt-cache...origin/feature/prompt-cache [ahead 3, behind 1]
$ git log --oneline --graph --decorate --all -5
* 1a1fa49 (origin/feature/prompt-cache) Add prompt cache with TTL
| * 833bc8a (HEAD -> feature/prompt-cache) Add cache test
| * 12cdd3d wip: ttl
| * bdbe39f Add prompt cache
|/  
* 510ee94 (origin/main, origin/HEAD, main) Add retrieval config
```
<!-- /snippet -->

Place three: Asha's local branch still has `833bc8a`. And learn this line: a plus sign, three dots, and "(forced update)" in fetch output is the signal that a branch was rewritten under you. She is ahead 3, behind 1. The reflex is `git pull --rebase`. Predict what happens to her commit "Add cache test".

**[PAUSE]**

<!-- snippet: ch12/force-push/08-pull-rebase-drops -->
```text
$ git reflog show origin/feature/prompt-cache
1a1fa49 refs/remotes/origin/feature/prompt-cache@{0}: fetch: forced-update
833bc8a refs/remotes/origin/feature/prompt-cache@{1}: update by push
$ git merge-base --fork-point origin/feature/prompt-cache
833bc8ad64cffe287b9e4280a0c93cb6537d625b
$ git pull --rebase
Successfully rebased and updated refs/heads/feature/prompt-cache.
$ git log --oneline --decorate -3
1a1fa49 (HEAD -> feature/prompt-cache, origin/feature/prompt-cache) Add prompt cache with TTL
510ee94 (origin/main, origin/HEAD, main) Add retrieval config
95671d3 Add retriever skeleton
```
<!-- /snippet -->

"Successfully rebased", no conflict, and her commit is no longer on the branch. Look at the middle command: `git merge-base --fork-point` returns her own pushed commit. Pull with rebase replays only the commits after the fork point, and the fork point is found through the reflog of the remote-tracking ref. So nothing was left to replay.

**[ON SCREEN]** The second root-cause box of section 12.8.

```text
Observed behavior : after a teammate's forced push, git pull --rebase succeeded and my commit vanished
                    from the branch.
Git state         : I had pushed that commit earlier, so the reflog of origin/feature/prompt-cache
                    contains it ("update by push"). The server's branch was then replaced.
Mechanism         : pull --rebase replays only the commits after the fork point, and the fork point is
                    found through the reflog of the remote-tracking ref (git merge-base --fork-point).
                    It was my own pushed commit, so nothing was left to replay.
Root cause        : Git cannot tell "the upstream removed this commit on purpose" from "someone
                    overwrote it by accident". The reflog says only: it was upstream once, it is not now.
Why Git does this : without the rule, everyone downstream of a deliberately rebased branch would
                    re-apply the commits that the upstream had dropped.
Correct fix       : the commit is in my reflog; cherry-pick it onto the new tip and push.
Prevention        : after any "(forced update)" line, look before integrating:
                    git log --oneline --graph HEAD @{u}. Do not pull on a branch that others rewrite.
```

**Step 8: recovery.** `git cherry-pick` 🟡 CAUTION, from her reflog.

<!-- snippet: ch12/force-push/09-recover -->
```text
$ git reflog -4
1a1fa49 HEAD@{0}: pull --rebase (finish): returning to refs/heads/feature/prompt-cache
1a1fa49 HEAD@{1}: pull --rebase (start): checkout 1a1fa4964ca5cb5de17112e84ab62441aeac53fd
833bc8a HEAD@{2}: commit: Add cache test
12cdd3d HEAD@{3}: checkout: moving from main to feature/prompt-cache
$ git cherry-pick HEAD@{2}
[feature/prompt-cache 9074b47] Add cache test
 Date: Mon Sep 7 10:15:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 tests/test_cache.py
$ git push
To ../../server/support-bot.git
   1a1fa49..9074b47  feature/prompt-cache -> feature/prompt-cache
$ git log --oneline --decorate -3
9074b47 (HEAD -> feature/prompt-cache, origin/feature/prompt-cache) Add cache test
1a1fa49 Add prompt cache with TTL
510ee94 (origin/main, origin/HEAD, main) Add retrieval config
```
<!-- /snippet -->

`HEAD@{2}` is "commit: Add cache test". She picks it onto the new tip, it becomes `9074b47`, and an ordinary push publishes it.

**The other forms.** `labs/run ch12/lease-forms`. Two branches were reworded locally; Asha has pushed to `docs/runbook` and you have not fetched.

<!-- snippet: ch12/lease-forms/01-one-ref -->
```text
# Both branches were reworded locally. Asha has pushed to docs/runbook; you have not fetched.
$ git branch -vv
  docs/runbook         ca3cabb [origin/docs/runbook: ahead 1, behind 1] Start the on-call runbook
* feature/prompt-cache 886feab [origin/feature/prompt-cache: ahead 1, behind 1] Add prompt cache module
  main                 510ee94 [origin/main] Add retrieval config
$ git config set advice.pushUpdateRejected false
$ git push --force-with-lease=feature/prompt-cache origin feature/prompt-cache docs/runbook
To ../../server/support-bot.git
 + 45de293...886feab feature/prompt-cache -> feature/prompt-cache (forced update)
 ! [rejected]        docs/runbook -> docs/runbook (fetch first)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git ls-remote --branches origin
73f4877fe6ae70fc95aacb4cd751411a277c5f0e	refs/heads/docs/runbook
886feab6db3f48e44fe9bb9310d582ba8d094014	refs/heads/feature/prompt-cache
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/main
```
<!-- /snippet -->

`--force-with-lease=<ref>` leases and forces one ref. Every other ref in the same push follows the normal rules, so `docs/runbook` was rejected. The push was also not atomic: one ref was overwritten and one refused.

<!-- snippet: ch12/lease-forms/02-must-not-exist -->
```text
$ git push --force-with-lease=release/1.0: origin main:refs/heads/release/1.0
To ../../server/support-bot.git
 * [new branch]      main -> release/1.0
$ git push --force-with-lease=release/1.0: origin feature/prompt-cache:refs/heads/release/1.0
To ../../server/support-bot.git
 ! [rejected]        feature/prompt-cache -> release/1.0 (stale info)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

An empty expected value means "the ref must not exist yet": a create-only push. Without the lease, the second command would have been a legal fast-forward of `release/1.0`.

Now plain force, on `docs/runbook`, where you have never fetched Asha's commit.

<!-- snippet: ch12/lease-forms/03-plain-force -->
```text
# What your clone believes the server has, and what the server reports during a dry run:
$ git rev-parse --short origin/docs/runbook
17783a7
$ git push --dry-run --force origin docs/runbook
To ../../server/support-bot.git
 + 73f4877...ca3cabb docs/runbook -> docs/runbook (forced update)
$ git cat-file -t 73f4877
fatal: Not a valid object name 73f4877
[exit status: 128]
$ git push --force origin docs/runbook
To ../../server/support-bot.git
 + 73f4877...ca3cabb docs/runbook -> docs/runbook (forced update)
$ git reflog show origin/docs/runbook
ca3cabb refs/remotes/origin/docs/runbook@{0}: update by push
17783a7 refs/remotes/origin/docs/runbook@{1}: update by push
```
<!-- /snippet -->

Your clone believes the server is at `17783a7`. The dry run prints `73f4877...ca3cabb`: the server is at `73f4877`, and `git cat-file` says your repository has no such object. That is Asha's commit. The forced push replaces it, and the reflog of your remote-tracking ref goes from `17783a7` straight to `ca3cabb`. Your clone never held the commit it destroyed.

<!-- snippet: ch12/lease-forms/04-where-it-survives -->
```text
# The overwritten commit still exists: on the server, unreachable, and in the clone of Asha.
$ git -C ../../server/support-bot.git fsck --unreachable --no-reflogs | grep commit
unreachable commit 45de2936b350e2be1d34e97b160ee2af2d260b6d
unreachable commit 17783a7948f064198be834dfcce16644cba85192
unreachable commit 73f4877fe6ae70fc95aacb4cd751411a277c5f0e
$ git -C ../../asha/support-bot log --oneline -2 docs/runbook
73f4877 Add paging section
17783a7 Start the runbook
```
<!-- /snippet -->

It survives in Asha's clone and, unreachable, on the server. The other two unreachable commits are your own earlier versions, replaced on purpose.

<!-- snippet: ch12/lease-forms/05-fetch-by-id -->
```text
# Asking the server for the overwritten commit by its object ID:
$ git fetch origin 73f4877
fatal: couldn't find remote ref 73f4877
[exit status: 128]
$ git -c protocol.version=0 fetch origin 73f4877fe6ae70fc95aacb4cd751411a277c5f0e
error: Server does not allow request for unadvertised object 73f4877fe6ae70fc95aacb4cd751411a277c5f0e
[exit status: 1]
$ git fetch origin 73f4877fe6ae70fc95aacb4cd751411a277c5f0e
From ../../server/support-bot
 * branch            73f4877fe6ae70fc95aacb4cd751411a277c5f0e -> FETCH_HEAD
$ git log --oneline -2 FETCH_HEAD
73f4877 Add paging section
17783a7 Start the runbook
```
<!-- /snippet -->

Under protocol version 2, the default, a plain Git server hands out any object it has when asked by full ID; an abbreviation is not accepted, and under protocol version 0 the request is refused. This is a recovery route for as long as the object exists. It is also one reason why a forced push does not remove a leaked secret from a server.

## COMMON MISTAKES

**[ON SCREEN]** Each mistake with its root cause.

1. **Treating `--force-with-lease` as "safe force".** Root cause: the bare lease compares the server with your remote-tracking ref, and any fetch, including one you never looked at, renews it.
2. **Using plain `--force` on a branch you have not fetched.** Root cause: nothing is checked, so commits you have never seen are dropped and your own clone holds no copy.
3. **Running `git pull --rebase` after a "(forced update)" line.** Root cause: the fork point comes from the reflog of the remote-tracking ref, so commits you had already pushed are treated as removed upstream and are not replayed.
4. **Believing a forced push removes a commit from the server.** Root cause: the old commits remain as unreachable objects until garbage collection, and a server may hand them out by full ID.
5. **Looking for the overwritten commit in the server's reflog.** Root cause: `core.logAllRefUpdates` defaults to false in a bare repository, so a plain bare server has none.

## PRODUCTION EXAMPLE

**[ON SCREEN]** The five-step routine.

The textbook gives a routine for rewriting a branch that is already published. One: fetch and read `git status -sb`. Two: mark the old tip, `git branch backup/<name>`. Three: rewrite. Four: push with `--force-with-lease=<name>:backup/<name>`. Five: tell everyone who has the branch what to do next. And set `push.useForceIfIncludes=true` once, for the days you forget the explicit form.

Picture an evaluation team where two people share a long-running experiment branch. One of them rebases it on Friday evening using that routine, minus step five. On Monday the other runs `git pull --rebase` out of habit. It says "Successfully rebased". Their Friday commit is gone from the branch and nothing was red. Step five is not politeness. It is the only control for the second root-cause box.

**[ON SCREEN]** Layer label: GitHub.

On GitHub, according to the documentation, "Block force pushes" is enabled by default in a new ruleset, and classic branch protection rules disable force pushes by default. GitHub offers no reflog that Git can query, but its Activity view lists force pushes and offers a comparison for each entry, and its troubleshooting page gives the plain-Git answer: ask a collaborator who still has the commit to push it to a new branch. The interface changes; the documentation is the reference.

## PRACTICE EXERCISE

Do Lab 7.4, "When `--force-with-lease` saves you and when it does not", in [`lab-manual/m07-remotes.md`](../../lab-manual/m07-remotes.md).

Before each forced push in the lab, write down:

- The value of your remote-tracking ref, and the value you believe the server has.
- Whether your local branch has ever contained the server's tip.
- For each of the three forms, bare lease, lease plus `--force-if-includes`, explicit lease: accepted or rejected, and with which words.

The challenge is Incident 2, [`incidents/02-force-push-wrong-branch`](../../incidents/02-force-push-wrong-branch/SYMPTOMS.md). Read only the symptoms file and work from the repository.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q203: "Why does `--force-with-lease` exist?"

Answer aloud first. A strong answer starts from the problem, what plain force does not check, and states the lease as a condition on two specific refs. It does not stop there: it names the assumption the condition rests on and one ordinary event that breaks it. It then gives the stronger forms and what each compares instead. A senior answer finishes with team practice: on which branches forcing is acceptable at all, and what a server can be configured to refuse.

## RECAP

You should now be able to say:

A forced push skips the fast-forward test and sets the server's ref to my commit; every commit that only the old tip reached becomes unreachable there, and a default bare server keeps no reflog. The bare lease compares the server with my remote-tracking ref, so a fetch I never looked at defeats it. `--force-if-includes` also requires that the remote tip was once in my branch, and the explicit lease names the expected commit. Overwritten commits survive in teammates' clones, in the reflogs of remote-tracking refs, and as unreachable objects on the server. After a "(forced update)" line I look before I integrate, because `pull --rebase` can drop my pushed commits without a conflict.

## HOMEWORK

Read section 12.8 of [Chapter 12](../../textbook/ch12-remote-operations.md).

Then close the book and write the lease-defeating sequence from memory as a timeline with three columns: you, the server, the teammate.
