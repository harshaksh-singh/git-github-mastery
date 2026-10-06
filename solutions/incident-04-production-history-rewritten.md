# Incident 4: the production branch was rewritten — solution

> Read this only after your own attempt at [`incidents/04-production-history-rewritten`](../incidents/04-production-history-rewritten/SYMPTOMS.md). Transcripts are real output from `labs/incidents/solve-04-production-history-rewritten.sh`. Layers: the rewrite is Git; the release job's refusal is the team's tooling; the missing control is a GitHub rule.

## 1. Symptoms

The release job refuses to deploy because the tagged, running commit is not an ancestor of `production`. Asha saw "diverged" with no local commits, reset to the server on advice, and shipped a commit. Ravi "tidied" the history and says the code is the same. A finance ticket reports tax amounts with too many decimals on a build from the tip.

## 2. Evidence

<!-- snippet: incidents/solve-04-production-history-rewritten/01-observe -->
```text
$ cd you
$ git fetch
From ../server
 + 3277739...4fae70f production -> origin/production  (forced update)
$ git branch -vv
* main       905f1ab [origin/main] Add README
  production 3277739 [origin/production: ahead 4, behind 2] Log the invoice id on failure
$ git log --oneline --graph production origin/production
* 4fae70f Add invoice PDF footer
* f2783aa Tax calculation, formatting and logging
| * 3277739 Log the invoice id on failure
| * 45e5eb3 Add currency formatting
| * 1d8b2fc Round tax to two decimals
| * c644065 Add tax calculation
|/  
* f46af3d Add invoice totals
* 905f1ab Add README
```
<!-- /snippet -->

Your `production` has four commits that the server's branch lacks, and the server's branch has two that yours lacks. You made no local commits, so the server's branch was replaced.

<!-- snippet: incidents/solve-04-production-history-rewritten/02-witnesses -->
```text
# Three independent records of the old tip: my branch, the reflog of origin/production, the tag.
$ git rev-parse production 'origin/production@{1}' 'deploy-2026-09-07^{commit}'
3277739ce8e6fd4a425fdae7a124985414b5dd36
3277739ce8e6fd4a425fdae7a124985414b5dd36
3277739ce8e6fd4a425fdae7a124985414b5dd36
$ git merge-base --is-ancestor deploy-2026-09-07 origin/production
[exit status: 1]
$ git log --format='%h %an, committed by %cn: %s' production..origin/production
4fae70f Asha Rao, committed by Asha Rao: Add invoice PDF footer
f2783aa Lab User, committed by Ravi Menon: Tax calculation, formatting and logging
```
<!-- /snippet -->

Three independent records agree on the old tip `3277739`: your local branch, the reflog of `origin/production`, and the annotated tag that the release job created. A tag is the strongest of the three: it lives on the server and nobody's fetch can move it. The last command shows who did what: the squashed commit keeps the original author (`Lab User`) and names Ravi as committer. In a rewritten history the author field does not tell you who rewrote it; the committer field and the reflogs do.

## 3. Hypotheses

| # | Hypothesis | Test | Result |
|---|---|---|---|
| 1 | The tag was moved or recreated | The tag still resolves to the tip everybody had | Tag unchanged |
| 2 | `production` was reset to an older commit | New commits would be ancestors of the old tip | No: two new commits with new IDs |
| 3 | `production` was rewritten: same content, new commits | Tree comparison of old and new tip | Rewritten, and the content is **not** the same |

## 4. Diagnostic commands

<!-- snippet: incidents/solve-04-production-history-rewritten/03-what-changed -->
```text
$ git range-diff production...origin/production
1:  c644065 < -:  ------- Add tax calculation
2:  1d8b2fc < -:  ------- Round tax to two decimals
3:  45e5eb3 < -:  ------- Add currency formatting
4:  3277739 < -:  ------- Log the invoice id on failure
-:  ------- > 1:  f2783aa Tax calculation, formatting and logging
-:  ------- > 2:  4fae70f Add invoice PDF footer
```
<!-- /snippet -->

`git range-diff` finds no pairs: four commits were replaced by one, and a folded commit matches none of its parts. The count of commits cannot answer the question "is it the same code". A tree comparison can:

<!-- snippet: incidents/solve-04-production-history-rewritten/04-tree-diff -->
```text
# "Same code, fewer commits" is a claim about trees. Compare the trees:
$ git diff --stat production origin/production
 billing/pdf.py | 2 ++
 billing/tax.py | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git diff production origin/production -- billing/tax.py
diff --git a/billing/tax.py b/billing/tax.py
index 66a2912..0fce8dc 100644
--- a/billing/tax.py
+++ b/billing/tax.py
@@ -1,2 +1,2 @@
 def tax(amount, rate):
-    return round(amount * rate, 2)
+    return amount * rate
```
<!-- /snippet -->

The rewritten branch differs from the deployed one in two files. `billing/pdf.py` is Asha's new commit. `billing/tax.py` lost the rounding: the commit "Round tax to two decimals" was dropped during the "cosmetic" rewrite. That is the finance ticket.

<!-- snippet: incidents/solve-04-production-history-rewritten/05-how -->
```text
$ git -C ../ravi reflog show production
f2783aa production@{0}: commit (amend): Tax calculation, formatting and logging
7fb64db production@{1}: rebase (finish): refs/heads/production onto f46af3da39ea0c36cdbaef0b34e16f4407a78eb6
3277739 production@{2}: branch: Created from refs/remotes/origin/production
$ git -C ../ravi reflog | grep rebase
7fb64db HEAD@{1}: rebase (finish): returning to refs/heads/production
7fb64db HEAD@{2}: rebase (fixup): Add tax calculation
6d37632 HEAD@{3}: rebase (fixup): # This is a combination of 2 commits.
c644065 HEAD@{4}: rebase (start): checkout production~4
```
<!-- /snippet -->

Ravi's reflog shows an interactive rebase from `production~4` with two fixups and an amend. One line of the todo list was deleted; in an interactive rebase a deleted line is a dropped commit ([Chapter 9: Rebase](../textbook/ch09-rebase.md), section 9.6).

## 5. Root cause

```text
Observed behavior : the deployed commit is not an ancestor of production; a shipped fix is missing from the tip
Git state         : production on the server was replaced by a two-commit history that does not contain 3277739
Mechanism         : interactive rebase created new commits and dropped one; "git push --force" replaced the server's ref
Root cause        : a branch that deployment records refer to by commit ID accepted a forced update
Why Git does this : a rewritten commit is a new object with a new ID; --force tells the server to skip the ancestry check
Correct fix       : restore the recorded history, carry the one commit shipped since onto it, realign every clone
Prevention        : block force pushes and require pull requests on production; treat the ancestry check as a release gate
```

The second failure is advice: "reset to the server" taught Asha's clone to accept the rewrite, after which her push made the rewritten history look legitimate.

## 6. Safe recovery

Two routes exist.

| Route | What it does | Cost |
|---|---|---|
| Keep the rewritten history, add the rounding fix again | No further forced update | The deployed tag is never an ancestor of the branch again; every stored commit ID (deploy log, tickets, bisect results) points off-branch; all other clones stay diverged |
| Restore the old history, add Asha's commit | One more forced update, with a lease | Two clones that adopted the rewrite must realign; one commit gets a new ID |

For a branch whose commit IDs are recorded elsewhere, restore. Only one commit was built on the rewrite and its author is at hand.

<!-- snippet: incidents/solve-04-production-history-rewritten/06-restore -->
```text
$ git branch --no-track rescue/production-rewritten origin/production
$ git switch production
Switched to branch 'production'
Your branch and 'origin/production' have diverged,
and have 4 and 2 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)
# One commit was shipped on top of the rewritten history. Copy it onto the real history:
$ git cherry-pick origin/production
[production a323df1] Add invoice PDF footer
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:30:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 billing/pdf.py
$ git log --oneline main..production
a323df1 Add invoice PDF footer
3277739 Log the invoice id on failure
45e5eb3 Add currency formatting
1d8b2fc Round tax to two decimals
c644065 Add tax calculation
f46af3d Add invoice totals
$ git push --force-with-lease=production:4fae70f origin production
To ../server.git
 + 4fae70f...a323df1 production -> production (forced update)
```
<!-- /snippet -->

The rescue branch here anchors the rewritten state, not the old one: the old tip already has three anchors, and the state about to be removed from the server is the one that needs a name. `git cherry-pick origin/production` copies Asha's commit onto the real history as `a323df1`. The lease names the exact value the server must still have.

Every clone that adopted the rewrite is now ahead of and behind the server. Before a clone moves, prove that nothing of its own would be lost:

<!-- snippet: incidents/solve-04-production-history-rewritten/07-realign -->
```text
$ cd ../asha
$ git fetch
From ../server
 + 4fae70f...a323df1 production -> origin/production  (forced update)
$ git status -sb
## production...origin/production [ahead 2, behind 5]
# Is anything of mine missing from the server? "-" means the server has an equivalent change.
$ git cherry -v origin/production production
+ f2783aa72335f59cef8731e0d5ed00dda990cd72 Tax calculation, formatting and logging
- 4fae70f86a56f9c739bd55c2e9830f4fba9145da Add invoice PDF footer
$ git reset --keep origin/production
$ cd ../ravi
$ git fetch
From ../server
 + f2783aa...a323df1 production -> origin/production  (forced update)
$ git cherry -v origin/production production
+ f2783aa72335f59cef8731e0d5ed00dda990cd72 Tax calculation, formatting and logging
$ git reset --keep origin/production
```
<!-- /snippet -->

`git cherry -v <upstream> <branch>` marks with `-` a local commit whose change the upstream already has, and with `+` one it does not. In Asha's clone the footer is `-` (the server has the copy) and the squashed commit is `+`, which is the commit being retired on purpose. `git reset --keep` then moves the branch and would refuse if uncommitted changes were in the way.

## 7. Verification

<!-- snippet: incidents/solve-04-production-history-rewritten/08-verify -->
```text
$ cd ../you
$ git merge-base --is-ancestor deploy-2026-09-07 origin/production
[exit status: 0]
$ git show origin/production:billing/tax.py
def tax(amount, rate):
    return round(amount * rate, 2)
$ git diff --stat rescue/production-rewritten origin/production
 billing/tax.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git branch -D rescue/production-rewritten
Deleted branch rescue/production-rewritten (was 4fae70f).
$ cd ..
$ incidents/04-production-history-rewritten/check.sh
Checking incident 04-production-history-rewritten
  ok    production on the server has "Add invoice totals"
  ok    production on the server has "Add tax calculation"
  ok    production on the server has "Round tax to two decimals"
  ok    production on the server has "Add currency formatting"
  ok    production on the server has "Log the invoice id on failure"
  ok    production on the server has "Add invoice PDF footer"
  ok    the squashed commit is no longer on production
  ok    the deployed tag is an ancestor of production again
  ok    billing/tax.py on production rounds to two decimals
  ok    billing/pdf.py is on production
  ok    production in you/ equals production on the server
  ok    production in asha/ equals production on the server
  ok    production in ravi/ equals production on the server
PASS: the recovery of incident 04-production-history-rewritten is complete.
[exit status: 0]
```
<!-- /snippet -->

The tag is an ancestor again (exit status 0), the rounding is back, and the only difference between the rewritten state and the restored one is that rounding line. The release job's check is exactly `git merge-base --is-ancestor <deployed> <branch>`; run it yourself before telling anyone the branch is fixed.

## 8. Prevention

> **GitHub, not Git.** Rules for a production branch: block force pushes, restrict deletions, require a pull request, and keep the bypass list empty or "for pull requests only" so that even a bypass leaves a trail in Rule Insights ([managing rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository#viewing-insights-for-rulesets)). [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md), section 18.18 works through this design.

- Published history is tidied before it is published, on a topic branch, never afterwards.
- "Your branch has diverged" on a branch where you made no commits means the server's history was replaced. The response is to stop and ask, not to reset.
- Keep the release job's ancestry check. It was the control that worked.

## 9. Communication

To the team: "`production` was rewritten this morning and has been restored. Its tip is `a323df1`. In your clone: `git fetch`, then `git cherry -v origin/production production`. If every line starts with `-`, or the only `+` line is 'Tax calculation, formatting and logging', run `git reset --keep origin/production`. Any other `+` line: stop and ask."

To the CTO: "No bad code reached production: the release job refused to deploy. The branch was rewritten by a history clean-up that also dropped the tax-rounding fix; staging builds from the tip showed it. The branch is restored, the fix is present, and one change shipped in between was preserved. The server accepted a forced update of the production branch; that rule is being switched on today."

## 10. Postmortem

- **Severity:** high potential (a regression in billing would have shipped), no customer impact.
- **Detection:** an automated gate, within one deployment attempt.
- **What went badly:** a second engineer was advised to reset; a customer-facing regression was reported through a ticket nobody linked.
- **Why it made sense at the time:** tidying commits is encouraged on topic branches, and nothing distinguished `production` technically from a topic branch.
- **Actions:** ruleset on `production`; a line in the handbook on "diverged with no local commits"; record the deployed commit ID in the ticket template so that incidents can be correlated.
