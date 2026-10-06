# Incident 2: a force push to the wrong branch — solution

> Read this only after your own attempt at [`incidents/02-force-push-wrong-branch`](../incidents/02-force-push-wrong-branch/SYMPTOMS.md). Transcripts are real output from `labs/incidents/solve-02-force-push-wrong-branch.sh`. Layers: the cause is Git configuration in one clone; the missing control is a GitHub rule.

## 1. Symptoms

`main` on the server ends with a commit titled "WIP ... tests still red". A merged commit by Ravi is no longer in the log of `main`. Asha says she pushed only her own branch after an amend. Your clone reports that it is up to date.

## 2. Evidence

<!-- snippet: incidents/solve-02-force-push-wrong-branch/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ git log --oneline -3
ca03e42 Close the input file after loading
27215c8 Reject rows without a timestamp
f273cd3 Add row validation
# The status is a statement about the last contact with the server. Ask the server:
$ git ls-remote origin
b4554be04054a80a74009ade9d329d2d820c8c5c	HEAD
b4554be04054a80a74009ade9d329d2d820c8c5c	refs/heads/main
```
<!-- /snippet -->

`git status` compares `main` with `origin/main`, your clone's memory of the server from the last fetch. `git ls-remote` asks the server itself, and the server's `main` is a commit your clone has never seen.

<!-- snippet: incidents/solve-02-force-push-wrong-branch/02-fetch -->
```text
$ git fetch
From ../server
 + ca03e42...b4554be main       -> origin/main  (forced update)
$ git status -sb
## main...origin/main [ahead 2, behind 2]
$ git reflog show origin/main
b4554be refs/remotes/origin/main@{0}: fetch: forced-update
ca03e42 refs/remotes/origin/main@{1}: update by push
27215c8 refs/remotes/origin/main@{2}: pull: fast-forward
f273cd3 refs/remotes/origin/main@{3}: update by push
```
<!-- /snippet -->

`+` and `(forced update)` mean that the new value of the ref is not a descendant of the old one. The reflog of `origin/main` now holds both values: `@{0}` after the event and `@{1}` before it.

<!-- snippet: incidents/solve-02-force-push-wrong-branch/03-what-changed -->
```text
# What the server lost:
$ git log --format='%h %an: %s' origin/main..'origin/main@{1}'
ca03e42 Lab User: Close the input file after loading
27215c8 Ravi Menon: Reject rows without a timestamp
# What the server gained:
$ git log --format='%h %an: %s' 'origin/main@{1}'..origin/main
b4554be Asha Rao: WIP config flag and readable dedupe, tests still red
a801616 Asha Rao: WIP dedupe by id
# Is my copy of the old value the newest one? Compare with Ravi, who has not fetched:
$ git -C ../ravi rev-parse --short origin/main
27215c8
$ git merge-base --is-ancestor 27215c8 'origin/main@{1}'
[exit status: 0]
```
<!-- /snippet -->

## 3. Hypotheses

| # | Hypothesis | Test | Result |
|---|---|---|---|
| 1 | Somebody merged Asha's branch into `main` | A merge commit, or her commits on top of Ravi's | No: the two reviewed commits are gone, not followed |
| 2 | Somebody reset `main` and force-pushed it on purpose | The pusher's reflog for `main` | Asha's local `main` never moved |
| 3 | Asha's push of `feature/dedupe` updated `main` on the server | The upstream of her branch and `push.default` | Confirmed below |

## 4. Diagnostic commands

<!-- snippet: incidents/solve-02-force-push-wrong-branch/04-cause -->
```text
# Why did a push from feature/dedupe move main? Look at the clone that pushed.
$ git -C ../asha branch -vv
* feature/dedupe b4554be [origin/main] WIP config flag and readable dedupe, tests still red
  main           f273cd3 [origin/main: behind 2] Add row validation
$ git -C ../asha config get --show-origin push.default
file:.git/config	upstream
$ git -C ../asha reflog show origin/main
b4554be refs/remotes/origin/main@{0}: update by push
```
<!-- /snippet -->

Three lines carry the whole cause. `[origin/main]` after `feature/dedupe`: the branch was created with `git switch -c feature/dedupe origin/main`, and starting a branch from a remote-tracking branch makes that branch its upstream. `push.default = upstream`: a bare `git push` then updates the upstream branch, whatever its name. And the reflog of her `origin/main` records the push.

## 5. Root cause

```text
Observed behavior : "git push --force" on feature/dedupe replaced main on the server
Git state         : feature/dedupe had origin/main as upstream; push.default was "upstream"; main on the server was unprotected
Mechanism         : with push.default=upstream, "git push" pushes the current branch to its upstream branch; --force removed the fast-forward check
Root cause        : a push whose destination was decided by configuration, combined with --force, on a server that accepts forced updates of main
Why Git does this : "upstream" is a legal push mode; the default "simple" would have refused because the names differ
Correct fix       : give Asha's commits their own branch on the server, then restore main to its previous commit with an explicit lease
Prevention        : block force pushes on main (a ruleset); push.default=simple; create branches with --no-track; say where you push
```

Each of the three conditions was needed. The default `push.default`, `simple`, refuses to push when the upstream branch has a different name ([Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md), section 12.5). Without `--force` the server would have rejected the push as not fast-forward. With a rule that blocks force pushes the server would have rejected it regardless.

## 6. Safe recovery

Before anything moves, make sure the old value is the newest one. Your `origin/main@{1}` is `ca03e42`; Ravi's clone, which has not fetched, knows `27215c8`, and that is an ancestor of yours (exit status 0 above). Your copy is complete.

<!-- snippet: incidents/solve-02-force-push-wrong-branch/05-preserve -->
```text
$ git branch rescue/main-before-force 'origin/main@{1}'
# Asha's two commits exist on the server only as the tip of main. Give them their own branch first:
$ git push origin origin/main:refs/heads/feature/dedupe
To ../server.git
 * [new branch]      origin/main -> feature/dedupe
```
<!-- /snippet -->

The second command is the important one. Asha's two commits are reachable on the server only through `main`. Restoring `main` first would leave them reachable from nothing on the server. Creating `feature/dedupe` there is purely additive.

<!-- snippet: incidents/solve-02-force-push-wrong-branch/06-restore -->
```text
$ git push --force-with-lease=main:b4554be origin rescue/main-before-force:main
To ../server.git
 + b4554be...ca03e42 rescue/main-before-force -> main (forced update)
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

This is a second forced update, and it is justified: the commits being removed from `main` are unreviewed work that now lives on its own branch, and nobody has built on them. `--force-with-lease=main:b4554be` makes the push conditional: it succeeds only if `main` on the server is still `b4554be`. If anyone had pushed to `main` in the meantime, the push would be rejected and you would look again. Had someone already built on the bad tip, the choice would be different: revert the two commits instead of removing them.

Then the cause, in the clone that has it:

<!-- snippet: incidents/solve-02-force-push-wrong-branch/07-fix-cause -->
```text
$ cd ../asha
$ git fetch
From ../server
 + b4554be...ca03e42 main           -> origin/main  (forced update)
 * [new branch]      feature/dedupe -> origin/feature/dedupe
$ git branch --set-upstream-to=origin/feature/dedupe feature/dedupe
branch 'feature/dedupe' set up to track 'origin/feature/dedupe'.
$ git config unset push.default
$ git status -sb
## feature/dedupe...origin/feature/dedupe
$ git branch -vv
* feature/dedupe b4554be [origin/feature/dedupe] WIP config flag and readable dedupe, tests still red
  main           f273cd3 [origin/main: behind 2] Add row validation
```
<!-- /snippet -->

## 7. Verification

<!-- snippet: incidents/solve-02-force-push-wrong-branch/08-verify -->
```text
$ cd ../you
$ git ls-remote origin
ca03e42e9a0a5df9443021ab8b91f1a8364a77ac	HEAD
b4554be04054a80a74009ade9d329d2d820c8c5c	refs/heads/feature/dedupe
ca03e42e9a0a5df9443021ab8b91f1a8364a77ac	refs/heads/main
$ git log --oneline --graph origin/main origin/feature/dedupe
* b4554be WIP config flag and readable dedupe, tests still red
* a801616 WIP dedupe by id
| * ca03e42 Close the input file after loading
| * 27215c8 Reject rows without a timestamp
|/  
* f273cd3 Add row validation
* 61ac39c Add loader
$ git branch -d rescue/main-before-force
Deleted branch rescue/main-before-force (was ca03e42).
$ cd ..
$ incidents/02-force-push-wrong-branch/check.sh
Checking incident 02-force-push-wrong-branch
  ok    main on the server has "Add loader"
  ok    main on the server has "Add row validation"
  ok    main on the server has "Reject rows without a timestamp"
  ok    main on the server has "Close the input file after loading"
  ok    main on the server has no WIP commit
  ok    the server has a branch feature/dedupe
  ok    feature/dedupe on the server has "WIP dedupe by id"
  ok    feature/dedupe on the server has the amended commit
  ok    in asha/, the upstream of feature/dedupe is no longer origin/main (now: origin/feature/dedupe)
  ok    in asha/, push.default is unset (simple)
PASS: the recovery of incident 02-force-push-wrong-branch is complete.
[exit status: 0]
```
<!-- /snippet -->

`main` on the server has the four reviewed commits; `feature/dedupe` holds Asha's two; the graph shows them as siblings from `f273cd3`.

## 8. Prevention

> **GitHub, not Git.** A ruleset on the default branch with "Block force pushes" would have rejected the push; the rule is enabled by default in a new ruleset ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#block-force-pushes)). [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md) covers the design. On GitHub the old value of `main` could also be read from the repository's [Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository), which lists force pushes with the user.

- Leave `push.default` at `simple`. Audit with `git config get --show-origin push.default`.
- Create topic branches with `git switch -c <name> --no-track origin/main`, or from local `main`.
- Force only with a lease and a named destination: `git push --force-with-lease origin feature/dedupe`.

## 9. Communication

To the team, at once: "`main` was overwritten by a forced push at HH:MM and restored at HH:MM to `ca03e42`. If you fetched in between, your `origin/main` moved twice; run `git fetch` and check `git status -sb`. If `main` shows `ahead`, stop and ask. Do not pull, do not push `main` until then. Asha's work is safe on `feature/dedupe`."

To the CTO: "For NN minutes `main` pointed at unreviewed work. Two merged commits were off the branch and are back; nothing was lost. Cause: a push setting in one clone sent a forced push to `main`, and the server allowed it. We are enabling the rule that blocks force pushes on `main` today."

## 10. Postmortem

- **Severity:** high for a shared default branch (anything deploying from `main` would have shipped unreviewed code), short duration.
- **Timeline source:** the reflogs of `origin/main` in three clones. The bare server has no reflog.
- **What went well:** detected by a failing nightly job within minutes; one clone held the complete old value.
- **What went badly:** the server had no rule; the output `(forced update)` was read as normal.
- **Actions:** ruleset on `main` (owner: platform, today); team note on `push.default`; add "read the `To` and `->` lines of every push" to the review checklist.
