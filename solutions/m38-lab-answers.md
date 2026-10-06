# Module 38 lab answers: communication, postmortems and the senior standard

> Read these after you have written your own texts and answers. The model texts show structure. Yours will differ in wording and should not differ in what they can be checked against.

## Lab 38.1: A timeline and a CTO summary

**Model timeline** (times from the fixed lab clock, 7 September 2026, +05:30).

| Time | Event | Source |
|---|---|---|
| 10:13 | Commit `3277739` created: the tip that was deployed | commit date of `deploy-2026-09-07^{commit}` |
| 10:14 | Deployment tagged `deploy-2026-09-07` by the release job | tagger date of the tag |
| 10:25 to 10:26 | `production` rewritten locally: rebase finished, then amended to `f2783aa` | `ravi/`: reflog of `production` |
| 10:27 | Rewritten history published to the server | `ravi/`: reflog of `origin/production`, "update by push" |
| 10:28 | A second clone learns of the rewrite | `asha/`: reflog of `origin/production`, "fetch: forced-update" |
| 10:29 | The second clone adopts it | `asha/`: reflog of `production`, "reset: moving to origin/production" |
| 10:30 to 10:31 | New commit `4fae70f` created and pushed on the rewritten history | `asha/`: both reflogs |
| 10:33 | The rewrite is first seen by the investigating clone | `you/`: reflog of `origin/production`, "fetch: forced-update" |

**Model summary.** See Chapter 30, section 30.15, which uses this incident. Severity: SEV 2, because a shared release branch held a history with a dropped fix, and one automated check stood between it and production.

1. `refs/remotes/origin/production@{2026-09-07 10:27:00 +0530}: update by push` in `ravi/`. Only the clone that pushed knows when the server changed.
2. It is the time your clone fetched. The server had changed six minutes earlier; a clone that fetches once a day would show a time hours later.
3. The repository's Activity view (force pushes with the user and a comparison), `PushEvent` records with `before` and `head` IDs for 30 days, and, in an enterprise, `git.push` audit events for seven days (Phase 0 report, section 13).
4. Typically the sentence about why the commit was dropped ("a line of the todo list was deleted"): the reflog shows a rebase with two fixups, and the dropped commit is inferred from the tree difference. Mark it with "from the evidence we infer".
5. Severity rates what could have happened in the window. Nothing was deployed only because the release job checks ancestry; a team without that check would have shipped the regression.

## Lab 38.2: A blameless postmortem

**Model, for incident 9** (abridged to the parts that carry the structure).

```text
Postmortem: merged overload fix lost in a later merge              Severity: SEV 2

Summary        A fix for unbounded token buckets was merged to main and later removed by a conflict
               resolution inside a merge commit on a feature branch. The overload recurred. The fix
               was restored with one commit. A regression test and a review step for merges were added.
Impact         API overload on <date>, <duration>. Same defect as the incident of <date>.
Timeline       <time>  fix commits bfd1f07 and 8a11540 merged to main          source: git log main
               <time>  main merged into the feature branch as d7497e2          source: committer date
               <time>  pull request merged as fb67f49                          source: committer date
               <time>  overload                                                source: alert
               <time>  loss located with git show --remerge-diff d7497e2       source: investigation notes
Detection      By the outage. No control detected the loss in the days between.
Root cause     (seven-line box) ... Root cause: the conflict was resolved by taking the current branch's
               whole file; "ours" was understood as "the team's version".
Contributing   The resolution was inside a merge commit, which the pull request diff does not show.
conditions     No test covered the cap. "ours" and "theirs" name positions and read like ownership.
What went well Both developers answered questions about what they had done at once and in detail.
Actions        1  Regression test for the cap        automation, strength 2   owner: <role>  date
               2  --remerge-diff in the review        checklist, strength 4    owner: <role>  date
                  checklist for merges from base
               3  merge.conflictStyle zdiff3 in the   client default, 3        owner: <role>  date
                  team setup script
               4  Session on ours and theirs          training, strength 5     owner: <role>  date
               How we will know: action 1 fails when the fix commit is reverted on a test branch.
```

1. The evidence came from people: reflogs they did not clean up, and accounts they gave freely. People who expect blame re-clone, tidy up or stay silent, and the timeline cannot be built.
2. For incident 9 a server-side rule cannot see a bad resolution, so the strongest available control is automation: a test that fails when the behavior is lost. It runs on every push, whoever resolves the conflict; a checklist item depends on the reviewer.
3. A regression test blocks an intentional change of the cap until the test is changed with it. The path is to change the test in the same pull request, visibly.
4. The review of merge commits with `--remerge-diff`. It detects resolutions that differ from the mechanical merge; it does not detect a semantically wrong resolution that looks reasonable, or a clean merge that is wrong for humans.
5. By a test of the control itself: revert the fix on a scratch branch and see the pipeline fail; and by a count of merges reviewed with the new step.

## Lab 38.3: Senior standard 1, against the clock

1. Most people want to skip step 2 (refs) and step 5 (what changed). Without step 2 you may repair a stale view; without step 5 you do not know that the rebase was lossless, and you cannot justify keeping the rebased series.
2. At step 8 (`git reset --keep`). Steps 4 and 6 make it safe: every commit that matters has an ID in your notes and a rescue branch.
3. The condition must be the value you examined in steps 1 to 5. If the server's branch changed since, your analysis no longer describes it, and the push must fail so that you look again.
4. For example: "The shared branch was rebased while unpublished work existed on the old version. A merge pull joined both versions and was pushed, so the pull request listed every commit twice. The branch was rebuilt with each change once; no content changed."
5. Step 9. The forced update would be rejected by the rule. The options are a bypass for pull requests only, a temporary relaxation recorded in the incident, or a new branch and a new pull request.

## Lab 38.4: Senior standard 2, against the clock

1. Revocation or rotation at the issuer ends it. Deleting the file, rewriting history, force-pushing, making the repository private and pruning reduce who can find the secret, and how.
2. The oldest "update by push" line in the pushing clone's reflog of the remote-tracking branch: `2026-09-07 10:19:00 +0530`. The commit date is when the commit was made locally; exposure starts when it leaves the machine.
3. "Do not merge, pull or push that branch. Either delete the clone and clone again, or: `git fetch`, rebase your own commits onto the new branch with `git rebase --onto origin/<branch> <old tip> <your branch>`, and tell me, so that we expire the old objects in your clone together."
4. What the credential can reach; whether it was used in the window, from the issuer's logs; and who had read access to the repository, its forks and its CI logs.
5. An ignore rule for `.env` together with staging by name would have stopped it. Push protection would not: it recognises provider token formats, and a free-form password matches none.

## Lab 38.5: Senior standard 3

1. The early areas decide whether the later ones matter. If the wrong workflow file or the wrong commit ran, the log of the failed step describes a situation you are not trying to fix. Logs are detailed, and without that context they mislead.
2. Did a commit touch the workflow, the lock file or the code between the last green and the first red run? Does the failure reproduce on a re-run of the last green commit? Did anything outside change in that window: a runner image label, an action behind a moving tag, a secret, a cache?
3. The original commit, the original ref and the original actor's privileges. The cause here is in the workflow file of that commit, so every re-run repeats it.
4. From its own list of unsupported functionality: `concurrency`, job `permissions`, `environment` and OIDC ([act: unsupported functionality](https://nektosact.com/not_supported.html)). So it cannot reproduce security or deployment behavior.
5. "The cause is identified and removed in the files on the fix branch. It is not yet confirmed by a run. I will report when the run on the pull request has finished."
