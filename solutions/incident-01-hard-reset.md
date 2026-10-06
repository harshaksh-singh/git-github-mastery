# Incident 1: an accidental `git reset --hard` — solution

> Read this only after your own attempt at [`incidents/01-hard-reset`](../incidents/01-hard-reset/SYMPTOMS.md). Transcripts are real output from `labs/incidents/solve-01-hard-reset.sh`. Layer: everything in this incident is Git, on one laptop.

## 1. Symptoms

Ravi reports that three or four commits of Friday's work are missing from `git log`, that he suspects `git pull`, that he "reset to what is on the server", that the branch was never pushed, that a new file was "added", that an edit to the routing configuration was in progress, and that he has committed once more since.

Without interpretation: commits that existed on `feature/escalation-rules` are no longer reachable from it.

## 2. Evidence

<!-- snippet: incidents/solve-01-hard-reset/01-observe -->
```text
$ cd ravi
$ git status -sb
## feature/escalation-rules
$ git branch -vv
* feature/escalation-rules 4e4c0b7 Mention escalation in the README
  main                     44fa655 [origin/main: behind 1] Add README
$ git log --oneline --graph --all
* 4e4c0b7 Mention escalation in the README
* 2876d93 Document how to run the tests
* 44fa655 Add README
* 43fb607 Add ticket classifier
```
<!-- /snippet -->

The branch has no upstream (the status line shows no `...origin/`), so "what is on the server" for this branch does not exist. The branch tip sits directly on the two commits of `main`. The escalation commits are in no branch.

<!-- snippet: incidents/solve-01-hard-reset/02-reflog -->
```text
$ git reflog show feature/escalation-rules
4e4c0b7 feature/escalation-rules@{0}: commit: Mention escalation in the README
2876d93 feature/escalation-rules@{1}: reset: moving to origin/main
0322a16 feature/escalation-rules@{2}: commit: Never escalate spam
a26c697 feature/escalation-rules@{3}: commit: Route escalated tickets to the on-call queue
95d110d feature/escalation-rules@{4}: commit: Add escalation predicate
44fa655 feature/escalation-rules@{5}: branch: Created from HEAD
# Ravi suspects "git pull". Does the HEAD reflog record a pull at all?
$ git reflog | grep -c pull
0
[exit status: 1]
```
<!-- /snippet -->

## 3. Hypotheses

| # | Hypothesis | What would distinguish it |
|---|---|---|
| 1 | `git pull` rewrote the branch | A `pull` line in the reflog. There is none: `grep -c` prints 0 |
| 2 | The commits were made on another branch or in detached HEAD | `commit:` lines in the reflog of another ref. They are in the reflog of this branch |
| 3 | A reset moved the branch to a commit that does not contain them | A `reset: moving to` line in the branch reflog. Present at `@{1}` |
| 4 | The commits were never made | No `commit:` lines. Three are present, `@{2}` to `@{4}` |

## 4. Diagnostic commands

`git status -sb`, `git branch -vv`, `git log --oneline --graph --all`, `git reflog show <branch>`. All four are 🟢. The branch reflog is the instrument that decides: it lists every value the branch ever had, with the command that set it ([Chapter 13: Recovery](../textbook/ch13-recovery.md), section 13.3).

## 5. Root cause

```text
Observed behavior : three commits, one staged file and one unstaged edit are gone after "a reset to the server"
Git state         : feature/escalation-rules had no upstream; origin/main was one commit ahead of where the branch started
Mechanism         : "git reset --hard origin/main" set the branch ref to origin/main and overwrote index and working tree to match
Root cause        : the reset named origin/main, which is not "this branch on the server" (no such branch existed), as its target
Why Git does this : reset moves the current branch to whatever commit you name; it does not check that the name relates to the branch
Correct fix       : anchor the old tip from the branch reflog, copy the three commits onto the current tip, restore the staged blob
Prevention        : discard an edit with "git restore <file>"; never use reset --hard to discard one file; push feature branches early
```

Ravi wanted to throw away one half-done edit. The command for that is `git restore rules/routing.yaml`, which touches one file. `git reset --hard <commit>` does three things: it moves the branch, replaces the index, and overwrites the working tree ([Chapter 11: Reset, Revert, Restore](../textbook/ch11-reset-revert-restore.md), sections 11.4 and 11.5).

## 6. Safe recovery

Three kinds of work were lost, and they sit on three different layers.

| What | Layer | Recoverable? |
|---|---|---|
| Three commits | Committed: reachable from the branch reflog | Yes, completely |
| `rules/priority.yaml`, staged with `git add`, never committed | A blob in the object database, referenced by nothing | Yes, as content without a file name |
| The edit to `rules/routing.yaml`, never staged | Only ever in the working tree | No. Git never had it |

First anchor, then inspect. A branch costs nothing and stops any expiry.

<!-- snippet: incidents/solve-01-hard-reset/03-anchor -->
```text
$ git branch rescue/before-reset 'feature/escalation-rules@{2}'
$ git log --oneline origin/main..rescue/before-reset
0322a16 Never escalate spam
a26c697 Route escalated tickets to the on-call queue
95d110d Add escalation predicate
$ git diff --stat origin/main...rescue/before-reset
 rules/routing.yaml | 1 +
 triage/escalate.py | 4 ++++
 2 files changed, 5 insertions(+)
```
<!-- /snippet -->

The staged file: `git add` wrote a blob, the reset removed the index entry, and the blob is now dangling. `git fsck --lost-found` finds it and writes a copy under `.git/lost-found/other/`.

<!-- snippet: incidents/solve-01-hard-reset/04-staged -->
```text
$ git fsck --lost-found
dangling blob 959c2056cb4f78bc321cf5bcf50cf2bf42d049bd
$ ls .git/lost-found/other
959c2056cb4f78bc321cf5bcf50cf2bf42d049bd
$ git cat-file -p 959c205
outage: 1
billing: 2
how-to: 3
```
<!-- /snippet -->

The integration. Moving the branch back to `0322a16` would discard the commit Ravi made after the reset and would put the branch behind `main` again. Adding the three commits on top of the current tip destroys nothing.

<!-- snippet: incidents/solve-01-hard-reset/05-recover -->
```text
$ git cherry-pick origin/main..rescue/before-reset
[feature/escalation-rules 990c316] Add escalation predicate
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:13:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 triage/escalate.py
[feature/escalation-rules faa407c] Route escalated tickets to the on-call queue
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:14:00 2026 +0530
 1 file changed, 1 insertion(+)
[feature/escalation-rules 028bfd1] Never escalate spam
 Author: Ravi Menon <ravi@example.com>
 Date: Mon Sep 7 10:15:00 2026 +0530
 1 file changed, 2 insertions(+)
$ git cat-file -p 959c205 > rules/priority.yaml
$ git status -sb
## feature/escalation-rules
?? rules/priority.yaml
```
<!-- /snippet -->

`git cherry-pick A..B` copies the commits that are in `B` and not in `A`, oldest first. The copies have new IDs; that is harmless here because the originals were never pushed. The blob is written back under its path by hand, because a blob has no name: the name was in the index entry that the reset removed.

## 7. Verification

<!-- snippet: incidents/solve-01-hard-reset/06-verify -->
```text
$ git log --oneline --graph feature/escalation-rules
* 028bfd1 Never escalate spam
* faa407c Route escalated tickets to the on-call queue
* 990c316 Add escalation predicate
* 4e4c0b7 Mention escalation in the README
* 2876d93 Document how to run the tests
* 44fa655 Add README
* 43fb607 Add ticket classifier
$ git range-diff origin/main rescue/before-reset HEAD
-:  ------- > 1:  4e4c0b7 Mention escalation in the README
1:  95d110d = 2:  990c316 Add escalation predicate
2:  a26c697 = 3:  faa407c Route escalated tickets to the on-call queue
3:  0322a16 = 4:  028bfd1 Never escalate spam
$ cat rules/routing.yaml
default_queue: general
escalation_queue: oncall
$ cd ..
$ incidents/01-hard-reset/check.sh
Checking incident 01-hard-reset
  ok    the commit "Add escalation predicate" is on feature/escalation-rules again
  ok    the commit "Route escalated tickets to the on-call queue" is on feature/escalation-rules again
  ok    the commit "Never escalate spam" is on feature/escalation-rules again
  ok    the commit made after the reset is still on the branch
  ok    no commit of main was copied
  ok    the branch contains the current origin/main
  ok    triage/escalate.py in the last commit has the spam rule
  ok    the staged file rules/priority.yaml is back with its content
  ok    no operation is left in progress
PASS: the recovery of incident 01-hard-reset is complete.
[exit status: 0]
```
<!-- /snippet -->

`git range-diff origin/main rescue/before-reset HEAD` compares the old series with the new one. The three `=` lines say that each copied commit has the same change and message as its original. The first line is the commit that only the new series has. `rules/routing.yaml` shows the committed state: the line `escalation_sla_minutes: 15` that Ravi was typing is not there, and no command will bring it back. Only after verification is the rescue branch deleted:

<!-- snippet: incidents/solve-01-hard-reset/07-cleanup -->
```text
$ git -C ravi branch -D rescue/before-reset
Deleted branch rescue/before-reset (was 0322a16).
```
<!-- /snippet -->

## 8. Prevention

- `git restore <path>` to discard changes to a file; `git stash` to park them. `git reset --hard` is 🔴 and is for the case where you want the branch moved and everything uncommitted destroyed.
- `git reset --keep <commit>` when a branch has to move: it refuses if a file with local changes would be overwritten ([Chapter 11](../textbook/ch11-reset-revert-restore.md), section 11.6).
- Push a feature branch on the first day, with `git push -u origin HEAD`. A pushed branch has a second copy and a meaningful `@{upstream}`.
- Commit small and often. A commit is the only thing in this incident that came back whole.

## 9. Communication

To Ravi: "Your three commits are back on the branch, on top of your README commit and the current `main`. `rules/priority.yaml` is back as an untracked file; check it and commit it. Your unfinished change to `rules/routing.yaml` was never staged, so Git never stored it: check your editor's local history, otherwise it has to be retyped. `git pull` was not involved."

To the CTO, only if asked: "One developer lost about ten minutes of uncommitted typing through a local command. Committed work was fully recovered from the local reflog. Nothing reached the server; no customer impact."

## 10. Postmortem

- **Severity:** low. One person, local, no shared ref changed.
- **What went well:** the developer stopped and asked before trying a second fix; the reflog was intact.
- **What went badly:** work continued for one commit after the loss; a branch with a day of work had no remote copy.
- **Contributing condition:** `reset --hard` is widely taught as "undo".
- **Action:** add `git restore` and `git reset --keep` to the team's onboarding page; agree that a branch is pushed on its first day.
