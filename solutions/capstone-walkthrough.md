# Capstone walkthrough: the model solution for all eight stages

> Read a stage here only after your own deliverables for that stage are written. A diagnosis you have read cannot be made again.
>
> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Every transcript is real output from the replay scripts in `labs/capstone/`. The commit IDs are the ones `capstone/setup.sh --stage N` produces. Commits that you made yourself in `labs/shell` have other IDs, because that shell uses the real clock. GitHub-side steps are described from the textbook and the documentation it cites; nothing here was captured from GitHub.

This file is one route through each stage. The checks accept others. What a reviewer compares with your work is the structure: evidence before action, at least three hypotheses, state preserved before it moves, the lowest-risk fix with the alternatives named, verification with the commands that showed the problem, and two messages that a team and a CTO can use. Each stage below follows the ten-part format of [Chapter 30](../textbook/ch30-incident-response.md), section 30.4.

## 0. The repository you inherit

`capstone/setup.sh --stage 0` builds the company repository with no incident applied.

<!-- snippet: capstone/end-to-end/01-company -->
```text
$ cd you
$ git log --oneline --graph --decorate origin/main
* 7db3ddf (HEAD -> main, tag: v1.3.0, origin/main, origin/HEAD) Raise the embedding weight to 0.8 (#11)
* f9ae37f Count keyword hits case-insensitively (#10)
* bae705c Pin CI to Python 3.13 (#9)
* 5ce3510 Simplify keyword scoring (#8)
*   d449cc0 Merge pull request #7 from feature/queue-priorities
|\  
| * 8ae1cbe Document the routing table
| * 10e9455 Give every queue a priority
|/  
* ba48a7a (tag: v1.2.0) Document the scoring formula (#6)
* 1cf6842 Route unknown intents to a human agent (#5)
* f99edab (tag: v1.1.0) Add the release workflow (#4)
*   fcace69 Merge pull request #3 from feature/eval-set
|\  
| * cff59d0 Add the offline evaluation script
| * 772f844 Add the evaluation set pointer
|/  
* 7a239de (tag: v1.0.0) Add the intent-to-queue routing table (#2)
* bfa8a15 Add CODEOWNERS and the CI workflow (#1)
* eeded2a Add unit tests and the test script
* f84d4a2 Initial service skeleton
$ git tag -n1
v1.0.0          intent-router 1.0.0
v1.1.0          intent-router 1.1.0
v1.2.0          intent-router 1.2.0
v1.3.0          intent-router 1.3.0
$ ../pr list
#12  open    clean     feature/low-confidence-penalty -> main   Halve the score when keyword and embedding disagree
#13  open    clean     feature/tenant-weights -> main   Add per-tenant embedding weights
$ git ls-files
.github/CODEOWNERS
.github/workflows/ci.yml
.github/workflows/release.yml
.gitignore
README.md
data/.gitignore
data/eval-messages.jsonl.dvc
router/__init__.py
router/classify.py
router/keywords.py
router/routes.yaml
router/scoring.py
scripts/evaluate.py
scripts/test.sh
scripts/version.sh
tests/test_classify.py
tests/test_scoring.py
$ cd ..
```
<!-- /snippet -->

Read three things off this transcript before stage 1. The first-parent history of `main` is one line per pull request, with two exceptions at the bottom from before the rule existed. Two pull requests, #3 and #7, were merged with a merge commit and show their commits; the others are squash merges, one commit each. And the four releases are annotated tags on `main`.

```text
  Mon 7 Sep            Tue 8            Wed 9           Thu 10                 Fri 11
  o---o---#1---#2------#3---#4----------#5---#6---------#7---#8---#9-----------#10---#11      main
              |             |                |                                        |
            v1.0.0        v1.1.0           v1.2.0                                   v1.3.0
                                                                                      |\
                                                                                      | o   feature/low-confidence-penalty  (#12, yours)
                                                                                       \
                                                                                        o   feature/tenant-weights           (#13, Kabir's)
```

---

## Stage 1: a bug reaches production

**Symptoms.** Since the deployment of `v1.3.0` at 09:00 the billing queue receives keyword-stuffed messages that went to human triage under `v1.2.0`. One logged message: 12 keyword hits, embedding score 0.10, routed to `billing_refund`. The engineer on call suspects pull request #11 and has opened #14, which reverts it.

**Evidence.** Your clone is clean and equal to the server. The release contains five pull requests.

<!-- snippet: capstone/stage-01-bug-in-production/01-observe -->
```text
$ cd you
$ git status -sb
## main...origin/main
$ git fetch
From ../server
 * [new branch]      fix/revert-embed-weight -> origin/fix/revert-embed-weight
$ git log --oneline --decorate v1.2.0..origin/main
7db3ddf (HEAD -> main, tag: v1.3.0, origin/main, origin/HEAD) Raise the embedding weight to 0.8 (#11)
f9ae37f Count keyword hits case-insensitively (#10)
bae705c Pin CI to Python 3.13 (#9)
5ce3510 Simplify keyword scoring (#8)
d449cc0 Merge pull request #7 from feature/queue-priorities
8ae1cbe Document the routing table
10e9455 Give every queue a priority
$ ../pr list
#12  open    clean     feature/low-confidence-penalty -> main   Halve the score when keyword and embedding disagree
#13  open    clean     feature/tenant-weights -> main   Add per-tenant embedding weights
#14  open    clean     fix/revert-embed-weight -> main   Revert "Raise the embedding weight to 0.8 (#11)"
```
<!-- /snippet -->

`v1.2.0..origin/main` lists seven commits, because the merge commit of #7 brings its two commits with it. Three open pull requests; #14 is the proposed revert.

**Hypotheses.** Written before any of them was tested.

| # | Hypothesis | Prediction | Separating command |
|---|---|---|---|
| H1 | #11 (embedding weight 0.7 to 0.8) changed the blend enough to push the message over the threshold | The sample routes to a human agent on the branch that reverts #11 | Run the sample on `origin/fix/revert-embed-weight` |
| H2 | Another change of the release altered one of the two input scores | The sample fails on a commit before #11 | `git bisect` between the two tags |
| H3 | Nothing in the repository changed the result: a configuration or data difference in production | The sample routes correctly on a clean checkout of `v1.3.0` | Run the sample on `v1.3.0` |

A weight of 0.8 gives the keyword score less influence than 0.7 did, not more, so H1 is weak before any command is run. That is a reason to test it first: it is cheap, and a teammate is about to act on it.

**Diagnostic commands.** First a reproduction, and the proof that it gives the right answer on both known ends.

<!-- snippet: capstone/stage-01-bug-in-production/02-reproduce -->
```text
# The sample from the alert as a script. It lives outside the repository, so that no
# checkout can change it. Exit status 0 means the message went to a human agent.
# First prove the script on both ends: it must fail on v1.3.0 and pass on v1.2.0.
$ cat ../repro.py
import sys
from router.classify import classify
from router.keywords import keyword_score

routed = classify([("billing_refund", keyword_score(12), 0.10)])
print("routed to", routed)
sys.exit(0 if routed == "human_agent" else 1)
$ PYTHONPATH=. python3 -B ../repro.py
routed to billing_refund
[exit status: 1]
$ git switch --quiet --detach v1.2.0
$ PYTHONPATH=. python3 -B ../repro.py
routed to human_agent
[exit status: 0]
```
<!-- /snippet -->

Fails on `v1.3.0`, passes on `v1.2.0`: H3 is refuted, and the script is fit to drive a bisect. `PYTHONPATH=.` matters. Python puts the directory of the script on its import path, not the current directory, so without it the script fails with `ModuleNotFoundError` on every commit, and `git bisect run` reads every non-zero status between 1 and 127 (except 125) as "bad" ([Chapter 14A](../textbook/ch14a-history-investigation.md), section 14A.21). In the first draft of this solution exactly that happened: every commit was "bad", and the bisect ended on the oldest commit of the range. A reproduction that was not proved on the good end produces a confident answer and no warning.

<!-- snippet: capstone/stage-01-bug-in-production/03-test-the-suspect -->
```text
# Hypothesis of the engineer on call: pull request #11. Her branch reverts it. Test it.
$ git log --oneline -1 origin/fix/revert-embed-weight
618ac9c Revert "Raise the embedding weight to 0.8 (#11)"
$ git switch --quiet --detach origin/fix/revert-embed-weight
$ PYTHONPATH=. python3 -B ../repro.py
routed to billing_refund
[exit status: 1]
$ git switch --quiet main
```
<!-- /snippet -->

With #11 reverted the sample still goes to the billing queue. H1 is refuted. Merging #14 would have shipped a second release with the fault in it and an evaluated improvement removed.

<!-- snippet: capstone/stage-01-bug-in-production/04-bisect -->
```text
$ git bisect start v1.3.0 v1.2.0
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[d449cc0bc741adb5cc2b9f4db98712a8d18e26fe] Merge pull request #7 from feature/queue-priorities
$ git bisect run env PYTHONPATH=. python3 -B ../repro.py
running 'env' 'PYTHONPATH=.' 'python3' '-B' '../repro.py'
routed to human_agent
Bisecting: 1 revision left to test after this (roughly 1 step)
[bae705c121122e495e3a886870b2c223454d1e77] Pin CI to Python 3.13 (#9)
running 'env' 'PYTHONPATH=.' 'python3' '-B' '../repro.py'
routed to billing_refund
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[5ce3510e855abf419575ed46b43351cfe6455f76] Simplify keyword scoring (#8)
running 'env' 'PYTHONPATH=.' 'python3' '-B' '../repro.py'
routed to billing_refund
5ce3510e855abf419575ed46b43351cfe6455f76 is the first 'bad' commit
commit 5ce3510e855abf419575ed46b43351cfe6455f76
Author: Kabir Sethi <kabir@example.com>
Date:   Thu Sep 10 10:22:00 2026 +0530

    Simplify keyword scoring (#8)
    
    * Rename KEYWORD_CAP to CAP
    * Simplify keyword_score
    * Shorten the keyword docstrings

 router/keywords.py | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)
bisect found first 'bad' commit
```
<!-- /snippet -->

Three steps: the merge of #7 is good, #9 is bad, #8 is bad. The first bad commit is `5ce3510`, "Simplify keyword scoring (#8)". `git bisect log` is the record for the evidence log, and `git bisect reset` returns to `main`:

<!-- snippet: capstone/stage-01-bug-in-production/05-bisect-end -->
```text
$ git bisect log
# bad: [7db3ddf2a99c3440810a0beb2bdd48d6bb0874d7] Raise the embedding weight to 0.8 (#11)
# good: [ba48a7a7ecaad16698745408b1c5c10dec7bf354] Document the scoring formula (#6)
git bisect start 'v1.3.0' 'v1.2.0'
# good: [d449cc0bc741adb5cc2b9f4db98712a8d18e26fe] Merge pull request #7 from feature/queue-priorities
git bisect good d449cc0bc741adb5cc2b9f4db98712a8d18e26fe
# bad: [bae705c121122e495e3a886870b2c223454d1e77] Pin CI to Python 3.13 (#9)
git bisect bad bae705c121122e495e3a886870b2c223454d1e77
# bad: [5ce3510e855abf419575ed46b43351cfe6455f76] Simplify keyword scoring (#8)
git bisect bad 5ce3510e855abf419575ed46b43351cfe6455f76
# first 'bad' commit: [5ce3510e855abf419575ed46b43351cfe6455f76] Simplify keyword scoring (#8)
$ git bisect reset
Previous HEAD position was 5ce3510 Simplify keyword scoring (#8)
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```
<!-- /snippet -->

A second, independent line of evidence, from the file instead of from behavior:

<!-- snippet: capstone/stage-01-bug-in-production/06-blame -->
```text
$ git show --stat --format='%h %an, committed by %cn%n%s' 5ce3510
5ce3510 Kabir Sethi, committed by Nandini Iyer
Simplify keyword scoring (#8)

 router/keywords.py | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)
$ git blame -s -L '/^def keyword_score/,+3' v1.3.0 -- router/keywords.py
^f84d4a2 12) def keyword_score(hits):
5ce3510e 13)     """Map a hit count to a score: hits per cap."""
5ce3510e 14)     return hits / CAP
$ git blame -s -L '/^def keyword_score/,+3' v1.2.0 -- router/keywords.py
^f84d4a2 12) def keyword_score(hits):
^f84d4a2 13)     """Map a hit count to a score in [0, 1]. Five or more hits count as full evidence."""
^f84d4a2 14)     return min(hits, KEYWORD_CAP) / KEYWORD_CAP
```
<!-- /snippet -->

In `v1.2.0` line 14 reads `min(hits, KEYWORD_CAP) / KEYWORD_CAP`; in `v1.3.0` it reads `hits / CAP` and is attributed to `5ce3510`. Twelve hits now score 2.4 where the design says at most 1. Bisect and blame agree. Note the author and the committer: the pull request's author wrote it, the tech lead merged it.

The squash commit bundles three commits. They are not on `main`, and they are not gone:

<!-- snippet: capstone/stage-01-bug-in-production/07-inside-the-squash -->
```text
# A squash merge is one commit on main. The commits it was made of are still on the
# server, under the pull request ref.
$ git fetch origin refs/pull/8/head
From ../server
 * branch            refs/pull/8/head -> FETCH_HEAD
$ git log --oneline v1.2.0..FETCH_HEAD
146865e Shorten the keyword docstrings
ba54d91 Simplify keyword_score
be0ab67 Rename KEYWORD_CAP to CAP
d449cc0 Merge pull request #7 from feature/queue-priorities
8ae1cbe Document the routing table
10e9455 Give every queue a priority
$ git show --format='%h %s' ba54d91
ba54d91 Simplify keyword_score

diff --git a/router/keywords.py b/router/keywords.py
index 3e318a1..85307fa 100644
--- a/router/keywords.py
+++ b/router/keywords.py
@@ -11,4 +11,4 @@ def count_hits(text, keywords):
 
 def keyword_score(hits):
     """Map a hit count to a score in [0, 1]. Five or more hits count as full evidence."""
-    return min(hits, CAP) / CAP
+    return hits / CAP
```
<!-- /snippet -->

The server keeps the head of every pull request under `refs/pull/<number>/head` ([Chapter 17](../textbook/ch17-pull-requests.md), section 17.2). One of the three commits, `ba54d91`, is a one-line change, and that line is the fault. This is the cost of a squash merge that section 17.9 describes: on `main` the smallest unit that bisect and revert can address is the whole pull request.

**Root cause.**

```text
Observed behavior : keyword-stuffed messages are routed to the billing queue since v1.3.0
Git state         : v1.3.0 contains 5ce3510 (squash of pull request #8); router/keywords.py line 14 is
                    "return hits / CAP"; in v1.2.0 it was "return min(hits, KEYWORD_CAP) / KEYWORD_CAP"
Mechanism         : without the cap, keyword_score exceeds 1 for more than five hits, and the blend
                    crosses the routing threshold on keyword evidence alone
Root cause        : a refactoring removed a bound that no test covered; the tests exercised 0, 2 and 5 hits
Why Git does this : Git recorded what was merged. Nothing here is Git misbehaving. The squash merge made
                    the one-line cause invisible inside a commit titled "Simplify keyword scoring"
Correct fix       : revert 5ce3510 on main through a pull request; add the missing test; release v1.3.1
Prevention        : a test for the bound; review of "refactoring" pull requests commit by commit
```

Layer: the project's code and its tests. Contributing conditions: a pull request described as a simplification, squash-merged, so the behavior change had no commit of its own on `main`; no test above five hits; a release cut directly after the last merge.

**Safe recovery.**

| Option | Result | Verdict |
|---|---|---|
| Merge #14 (revert #11) | The fault stays; an evaluated change is lost | Rejected by evidence |
| Roll production back to `v1.2.0` | Removes the fault and four unrelated changes; `main` still has the fault | A valid first move for operations while the fix is prepared; not the fix |
| Fix forward: restore `min()` by hand | One line; also correct | Acceptable. Slower to review under pressure than a revert, and the constant was renamed in the same pull request |
| Revert `5ce3510` | Restores the exact reviewed state of the file; the message names what is undone | Chosen |

The revert applies cleanly although #10 changed the same file later, because #10 touched other lines:

<!-- snippet: capstone/stage-01-bug-in-production/08-revert -->
```text
$ git switch -c fix/keyword-score-cap origin/main
Switched to a new branch 'fix/keyword-score-cap'
branch 'fix/keyword-score-cap' set up to track 'origin/main'.
$ git revert --no-edit 5ce3510
Auto-merging router/keywords.py
[fix/keyword-score-cap 3dba0d1] Revert "Simplify keyword scoring (#8)"
 Date: Mon Sep 14 10:32:00 2026 +0530
 1 file changed, 4 insertions(+), 4 deletions(-)
$ git show --stat --format=%B HEAD
Revert "Simplify keyword scoring (#8)"

This reverts commit 5ce3510e855abf419575ed46b43351cfe6455f76.


 router/keywords.py | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)
$ PYTHONPATH=. python3 -B ../repro.py
routed to human_agent
[exit status: 0]
$ bash scripts/test.sh
OK
```
<!-- /snippet -->

`git revert` 🟡 adds a commit; it rewrites nothing. A revert without the test that would have caught the fault invites the same pull request back, so the branch gets a second commit, and the test is proved against the faulty file before it is trusted:

<!-- snippet: capstone/stage-01-bug-in-production/09-regression-test -->
```text
# (edit tests/test_scoring.py: a test that fails on the faulty version)
$ git diff
diff --git a/tests/test_scoring.py b/tests/test_scoring.py
index e12dc49..2035243 100644
--- a/tests/test_scoring.py
+++ b/tests/test_scoring.py
@@ -18,3 +18,6 @@ class ScoringTest(unittest.TestCase):
 
     def test_blend_weights_the_embedding(self):
         self.assertAlmostEqual(blend(0.0, 0.4), EMBED_WEIGHT * 0.4)
+
+    def test_keyword_score_never_exceeds_one(self):
+        self.assertEqual(keyword_score(12), 1.0)
$ bash scripts/test.sh
OK
$ git commit -q -am 'Test that the keyword score never exceeds 1'
# Does the new test catch the fault? Run it against the faulty file, then put the file back.
$ git restore --source=v1.3.0 -- router/keywords.py
$ bash scripts/test.sh
FAIL: test_keyword_score_never_exceeds_one
FAILED
[exit status: 1]
$ git restore --source=HEAD -- router/keywords.py
$ git status -sb
## fix/keyword-score-cap...origin/main [ahead 2]
```
<!-- /snippet -->

`git restore --source=v1.3.0 -- router/keywords.py` 🟡 overwrites one working-tree file with the faulty version; the second `git restore` puts the committed version back. The test fails on the fault and passes on the fix.

<!-- snippet: capstone/stage-01-bug-in-production/10-pull-request -->
```text
$ git push -u origin fix/keyword-score-cap
To ../server.git
 * [new branch]      fix/keyword-score-cap -> fix/keyword-score-cap
branch 'fix/keyword-score-cap' set up to track 'origin/fix/keyword-score-cap'.
$ ../pr open fix/keyword-score-cap --title 'Restore the cap on the keyword score'
Opened pull request #15: Restore the cap on the keyword score (fix/keyword-score-cap -> main)
$ ../pr view 15
#15 Restore the cap on the keyword score
state: open   fix/keyword-score-cap -> main   author: Lab User
merge check: clean
Commits:
  0b0c8dc Lab User: Test that the keyword score never exceeds 1
  3dba0d1 Lab User: Revert "Simplify keyword scoring (#8)"
Files changed:
 router/keywords.py    | 8 ++++----
 tests/test_scoring.py | 3 +++
 2 files changed, 7 insertions(+), 4 deletions(-)
$ ../pr merge 15 --merge
Merged pull request #15 into main as 47fb459 (merge). Deleted the branch fix/keyword-score-cap on the server.
$ ../pr close 14
Closed pull request #14 without merging. The branch fix/revert-embed-weight still exists.
```
<!-- /snippet -->

The pull request is merged with a merge commit, not squashed, so that the revert stays a commit of its own on `main` with its "This reverts commit" line. #14 is closed with a comment that gives the evidence: the sample still fails on its branch.

<!-- snippet: capstone/stage-01-bug-in-production/11-release -->
```text
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git pull --ff-only
From ../server
   7db3ddf..47fb459  main       -> origin/main
Updating 7db3ddf..47fb459
Fast-forward
 router/keywords.py    | 8 ++++----
 tests/test_scoring.py | 3 +++
 2 files changed, 7 insertions(+), 4 deletions(-)
$ git tag -a v1.3.1 -m 'intent-router 1.3.1: restore the cap on the keyword score'
$ git push origin v1.3.1
To ../server.git
 * [new tag]         v1.3.1 -> v1.3.1
$ git log --oneline --graph --decorate v1.3.0..v1.3.1
* 47fb459 (HEAD -> main, tag: v1.3.1, origin/main, origin/HEAD) Merge pull request #15 from fix/keyword-score-cap
* 0b0c8dc (origin/fix/keyword-score-cap, fix/keyword-score-cap) Test that the keyword score never exceeds 1
* 3dba0d1 Revert "Simplify keyword scoring (#8)"
```
<!-- /snippet -->

**Verification.** On the tag, not on a working tree that happens to be at the same commit:

<!-- snippet: capstone/stage-01-bug-in-production/12-verify -->
```text
$ git switch --quiet --detach v1.3.1
$ PYTHONPATH=. python3 -B ../repro.py
routed to human_agent
[exit status: 0]
$ bash scripts/test.sh
OK
$ git diff --stat v1.3.0 v1.3.1
 router/keywords.py    | 8 ++++----
 tests/test_scoring.py | 3 +++
 2 files changed, 7 insertions(+), 4 deletions(-)
$ git switch --quiet main
$ git fetch --prune
From ../server
 - [deleted]         (none)     -> origin/fix/keyword-score-cap
$ git branch -d fix/keyword-score-cap
Deleted branch fix/keyword-score-cap (was 0b0c8dc).
$ cd ..
$ capstone/stage-01-bug-in-production/check.sh
Checking capstone stage 1
  ok    main on the server still contains the release v1.3.0 (history was not rewritten)
  ok    the keyword-stuffed sample message goes to a human agent again on main
  ok    the test suite passes on main
  ok    the change that introduced the fault is undone by a revert commit that names it
  ok    the embedding weight is still 0.8 on main (an unrelated change was not reverted)
  ok    keyword hits are still counted case-insensitively on main
  ok    everything on main since v1.3.0 arrived through a pull request
  ok    the tag v1.3.1 exists on the server
  ok    v1.3.1 is an annotated tag
  ok    v1.3.1 is on main and later than v1.3.0
  ok    the sample message goes to a human agent in v1.3.1
  ok    the embedding weight is 0.8 in v1.3.1
  ok    no bisect, revert or merge is left in progress in you/
PASS: the Git state of stage 1 is as required. The written deliverables are judged separately.
[exit status: 0]
```
<!-- /snippet -->

The sample routes to a human agent in `v1.3.1`, the tests pass, and `v1.3.1` differs from `v1.3.0` in two files: the reverted one and the test. **Not verified here:** that the release workflow built `v1.3.1` and that production runs it (the deployment log), and that the billing backlog drains (the queue monitor).

**Prevention.** A regression test for the bound, now in the repository (automation; owner: ML team). A line in the pull request template: "Does this change behavior? If a pull request is titled refactor or simplify, the answer must be no, and a reviewer reads it commit by commit" (review step). For releases: run the offline evaluation in `scripts/evaluate.py` on the release candidate with a sample of production messages, not only on the pull request that changed a weight (automation; owner: platform team).

**Communication.** To the team:

```text
v1.3.1 is tagged and contains the fix for the billing flood. Cause: #8 removed the cap on the keyword
score (hits / CAP instead of min(hits, CAP) / CAP), so more than five hits scored above 1. Found by
bisect between v1.2.0 and v1.3.0, confirmed by blame. #15 reverts #8 and adds a test for the cap.
#14 (revert of #11) is closed: the sample still fails on that branch, #11 is not involved.
Nothing to do in your clones beyond "git pull". Kabir: the rename KEYWORD_CAP -> CAP is reverted too;
if you still want it, a new pull request with the cap kept is welcome.
```

To the CTO:

```text
Subject: [Resolved] intent-router: spam routed to the billing queue after release 1.3.0 (SEV 2, customer-facing delay)

What happened   From 09:00 IST (deployment of 1.3.0) until the deployment of 1.3.1, messages that repeat a
                keyword many times were routed to the billing desk instead of human triage. The billing
                backlog reached 412 messages. No message was lost; billing customers waited longer.
Root cause      A code simplification in release 1.3.0 removed an upper bound on one of the two routing
                scores. No test covered the bound. This is a defect in our code, not in Git or GitHub.
What was done   The change was identified by binary search over the release and reverted. Release 1.3.1
                contains the revert and a test. Verified: the logged sample is routed correctly in 1.3.1
                and the test suite passes on the tag. Not yet verified: the backlog trend after deployment.
Prevention      The missing test exists now. Release candidates will be evaluated on sampled production
                messages before tagging. Owner: platform team. Date: before release 1.4.0.
```

SEV 2 on the scale of section 30.3: wrong behavior reached production and customers, caught within hours, nothing unrecoverable.

**Postmortem.** The point to carry into it: the first proposed fix was a revert of the most recent change, chosen by recency. It was one command away from being merged. What stopped it was a rule ("show me how you know"), not luck.

---

## Stage 2: a merge conflict between two feature branches

**Symptoms.** Pull request #13 (per-tenant weights) is merged. Your #12 (disagreement penalty) conflicted with it. A teammate merged `main` into your branch on his machine, resolved the conflicts, pushed, and reports green tests and a mergeable pull request.

**Evidence.**

<!-- snippet: capstone/stage-02-merge-conflict/01-observe -->
```text
$ cd you
$ git fetch
From ../server
   47fb459..95f8c85  main       -> origin/main
   a7a411b..4870ce0  feature/low-confidence-penalty -> origin/feature/low-confidence-penalty
$ ../pr list
#12  open    clean     feature/low-confidence-penalty -> main   Halve the score when keyword and embedding disagree
$ ../pr view 12
#12 Halve the score when keyword and embedding disagree
state: open   feature/low-confidence-penalty -> main   author: Lab User
merge check: clean
Commits:
  4870ce0 Kabir Sethi: Merge remote-tracking branch 'origin/main' into feature/low-confidence-penalty
  a7a411b Lab User: Halve the score when keyword and embedding disagree
Files changed:
```
<!-- /snippet -->

The decisive line is the last one, and it is empty. "Files changed" lists nothing. A pull request with two commits and no changed files would add nothing to `main` ([Chapter 17](../textbook/ch17-pull-requests.md), section 17.3: the file view is `base...head`).

<!-- snippet: capstone/stage-02-merge-conflict/02-graph -->
```text
$ git log --oneline --graph origin/main origin/feature/low-confidence-penalty -7
*   4870ce0 Merge remote-tracking branch 'origin/main' into feature/low-confidence-penalty
|\  
| * 95f8c85 Add per-tenant embedding weights (#13)
| *   47fb459 Merge pull request #15 from fix/keyword-score-cap
| |\  
| | * 0b0c8dc Test that the keyword score never exceeds 1
| | * 3dba0d1 Revert "Simplify keyword scoring (#8)"
| |/  
* / a7a411b Halve the score when keyword and embedding disagree
|/  
* 7db3ddf Raise the embedding weight to 0.8 (#11)
$ git diff --stat origin/main origin/feature/low-confidence-penalty
$ git grep -c DISAGREEMENT origin/main -- router
[exit status: 1]
$ git log --oneline -1 feature/low-confidence-penalty
a7a411b Halve the score when keyword and embedding disagree
```
<!-- /snippet -->

`git diff --stat origin/main origin/feature/low-confidence-penalty` prints nothing: the tip of your branch has the same tree as `main`. Your local branch still stands at your own commit, `a7a411b`, which is the copy of your work that nothing has touched.

**Hypotheses.**

| # | Hypothesis | Prediction | Separating command |
|---|---|---|---|
| H1 | The merge was resolved by taking one side for whole files | `--remerge-diff` shows your side of each conflict removed | `git show --remerge-diff <merge>` |
| H2 | #13 already contained your change, so nothing is left to add | The penalty code exists on `main` | `git grep DISAGREEMENT origin/main` |
| H3 | The display is stale; the branch does contain the penalty | `git diff origin/main origin/<branch>` shows it | The diff above |

H3 is refuted by the empty diff. H2 takes one `git grep`, which finds nothing. H1:

**Diagnostic commands.**

<!-- snippet: capstone/stage-02-merge-conflict/03-what-the-merge-did -->
```text
# A merge commit records a result. --remerge-diff repeats the merge and shows what the
# person who resolved it changed, compared with what Git produced on its own.
$ git show --remerge-diff --format='%h %an: %s' origin/feature/low-confidence-penalty -- router/scoring.py
4870ce0 Kabir Sethi: Merge remote-tracking branch 'origin/main' into feature/low-confidence-penalty

diff --git a/router/scoring.py b/router/scoring.py
remerge CONFLICT (content): Merge conflict in router/scoring.py
index c593ac8..bc421cb 100644
--- a/router/scoring.py
+++ b/router/scoring.py
@@ -1,21 +1,10 @@
 """Blend the keyword score and the embedding score of one candidate intent."""
 
 EMBED_WEIGHT = 0.8
-<<<<<<< a7a411b (Halve the score when keyword and embedding disagree)
-DISAGREEMENT = 0.6
-=======
 TENANT_EMBED_WEIGHT = {"acme-retail": 0.6}
->>>>>>> 95f8c85 (Add per-tenant embedding weights (#13))
 
 
 def blend(keyword_score, embed_score, tenant=None):
     """Both inputs are in [0, 1]; so is the result."""
-<<<<<<< a7a411b (Halve the score when keyword and embedding disagree)
-    score = (1 - EMBED_WEIGHT) * keyword_score + EMBED_WEIGHT * embed_score
-    if abs(keyword_score - embed_score) > DISAGREEMENT:
-        score *= 0.5  # the two signals disagree: trust neither
-    return score
-=======
     weight = TENANT_EMBED_WEIGHT.get(tenant, EMBED_WEIGHT)
     return (1 - weight) * keyword_score + weight * embed_score
->>>>>>> 95f8c85 (Add per-tenant embedding weights (#13))
```
<!-- /snippet -->

`git show --remerge-diff` repeats the merge in memory and shows the difference between what Git produced, conflict markers included, and what was committed ([Chapter 8](../textbook/ch08-merge.md), section 8.16). Both conflict regions were resolved by deleting your side. H1 is confirmed. Why are the tests green?

<!-- snippet: capstone/stage-02-merge-conflict/04-tests-lie -->
```text
$ git switch feature/low-confidence-penalty
Switched to branch 'feature/low-confidence-penalty'
Your branch is behind 'origin/feature/low-confidence-penalty' by 5 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)
$ git pull --ff-only
Updating a7a411b..4870ce0
Fast-forward
 router/classify.py    |  4 ++--
 router/keywords.py    |  8 ++++----
 router/scoring.py     | 10 ++++------
 tests/test_scoring.py |  5 ++---
 tests/test_tenant.py  | 14 ++++++++++++++
 5 files changed, 26 insertions(+), 15 deletions(-)
 create mode 100644 tests/test_tenant.py
$ bash scripts/test.sh
OK
# Green, although the penalty is gone. Compare the test file with my commit:
$ git diff a7a411b HEAD -- tests/test_scoring.py
diff --git a/tests/test_scoring.py b/tests/test_scoring.py
index 3d1f007..2035243 100644
--- a/tests/test_scoring.py
+++ b/tests/test_scoring.py
@@ -19,6 +19,5 @@ class ScoringTest(unittest.TestCase):
     def test_blend_weights_the_embedding(self):
         self.assertAlmostEqual(blend(0.0, 0.4), EMBED_WEIGHT * 0.4)
 
-    def test_disagreement_halves_the_score(self):
-        self.assertAlmostEqual(blend(1.0, 0.0), (1 - EMBED_WEIGHT) / 2)
-        self.assertAlmostEqual(blend(0.9, 0.5), (1 - EMBED_WEIGHT) * 0.9 + EMBED_WEIGHT * 0.5)
+    def test_keyword_score_never_exceeds_one(self):
+        self.assertEqual(keyword_score(12), 1.0)
```
<!-- /snippet -->

The test file was taken from `main` as well, so the one test that would have failed is gone, together with the code it tested. Green tests are evidence about the tests that exist.

**Root cause.**

```text
Observed behavior : pull request #12 is mergeable, its checks are green, and it changes no file
Git state         : merge commit 4870ce0 on the branch has the tree of main; parents a7a411b and 95f8c85
Mechanism         : at both conflicts the whole file was taken from main ("theirs"), for the code and for
                    its test; a merge commit records the result, whatever the result is
Root cause        : a conflict resolved by choosing a side instead of combining two intentions, by someone
                    who did not write one of the sides
Why Git does this : Git stops at a conflict because it cannot know the intent. It accepts any resolution
Correct fix       : apply the penalty again on top of the per-tenant weight, keep the tests of both changes
Prevention        : the author resolves conflicts in their own branch; reviewers read a merge with --remerge-diff
```

Layer: Git carried out a person's decision. GitHub displayed the result correctly: an empty file list is the truth.

**Safe recovery.**

| Option | Result | Verdict |
|---|---|---|
| Merge #12 as it is | `main` unchanged, the pull request closed as merged, the feature silently missing | Rejected |
| Reset the branch to `a7a411b`, redo the merge, force-push | A clean branch; discards a teammate's pushed commit and needs a forced push | Acceptable on your own branch with a lease, after telling him |
| One forward commit on top of the bad merge | No rewrite, no forced push; the branch history shows what happened; the pull request is squash-merged anyway | Chosen |

The forward commit is your original commit applied again. This time the conflict is read. `merge.conflictStyle=zdiff3` adds the common ancestor to each conflict ([Chapter 8](../textbook/ch08-merge.md), section 8.9):

<!-- snippet: capstone/stage-02-merge-conflict/05-redo -->
```text
# Forward, without rewriting the branch: apply my commit again on top of the bad merge.
# This time the conflict is resolved by reading it.
$ git config set merge.conflictStyle zdiff3
$ git cherry-pick a7a411b
Auto-merging router/scoring.py
CONFLICT (content): Merge conflict in router/scoring.py
Auto-merging tests/test_scoring.py
CONFLICT (content): Merge conflict in tests/test_scoring.py
error: could not apply a7a411b... Halve the score when keyword and embedding disagree
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
$ git status -sb
## feature/low-confidence-penalty...origin/feature/low-confidence-penalty
UU router/scoring.py
UU tests/test_scoring.py
```
<!-- /snippet -->

<!-- snippet: capstone/stage-02-merge-conflict/06-conflict -->
```text
$ git diff router/scoring.py
diff --cc router/scoring.py
index bc421cb,203f98b..0000000
--- a/router/scoring.py
+++ b/router/scoring.py
@@@ -1,10 -1,12 +1,24 @@@
  """Blend the keyword score and the embedding score of one candidate intent."""
  
  EMBED_WEIGHT = 0.8
++<<<<<<< HEAD
 +TENANT_EMBED_WEIGHT = {"acme-retail": 0.6}
++||||||| parent of a7a411b (Halve the score when keyword and embedding disagree)
++=======
+ DISAGREEMENT = 0.6
++>>>>>>> a7a411b (Halve the score when keyword and embedding disagree)
  
  
 -def blend(keyword_score, embed_score):
 +def blend(keyword_score, embed_score, tenant=None):
      """Both inputs are in [0, 1]; so is the result."""
++<<<<<<< HEAD
 +    weight = TENANT_EMBED_WEIGHT.get(tenant, EMBED_WEIGHT)
 +    return (1 - weight) * keyword_score + weight * embed_score
++||||||| parent of a7a411b (Halve the score when keyword and embedding disagree)
++    return (1 - EMBED_WEIGHT) * keyword_score + EMBED_WEIGHT * embed_score
++=======
+     score = (1 - EMBED_WEIGHT) * keyword_score + EMBED_WEIGHT * embed_score
+     if abs(keyword_score - embed_score) > DISAGREEMENT:
+         score *= 0.5  # the two signals disagree: trust neither
+     return score
++>>>>>>> a7a411b (Halve the score when keyword and embedding disagree)
```
<!-- /snippet -->

Two regions. In the first, each side added one constant after `EMBED_WEIGHT`, and the base section is empty: both are wanted. In the second, the base is one `return` line; `HEAD` replaced the fixed weight by a per-tenant `weight`, and your commit turned the `return` into a `score` with a penalty. The two intentions are independent, so the resolution computes the score with `weight` and then applies the penalty. Notice what is outside the markers: the signature already has `tenant=None`, merged without a conflict. Taking "your side" of the second region whole would keep `EMBED_WEIGHT` in the formula and ignore the tenant, in a function that accepts one.

<!-- snippet: capstone/stage-02-merge-conflict/07-resolve -->
```text
# (edit router/scoring.py: both constants; the signature and the weight from main;
#  my penalty applied to the score that is computed with that weight)
# (edit tests/test_scoring.py: keep both new tests, and add one for the combination)
$ git diff router/scoring.py
diff --cc router/scoring.py
index bc421cb,203f98b..0000000
--- a/router/scoring.py
+++ b/router/scoring.py
@@@ -1,10 -1,12 +1,14 @@@
  """Blend the keyword score and the embedding score of one candidate intent."""
  
  EMBED_WEIGHT = 0.8
 +TENANT_EMBED_WEIGHT = {"acme-retail": 0.6}
+ DISAGREEMENT = 0.6
  
  
 -def blend(keyword_score, embed_score):
 +def blend(keyword_score, embed_score, tenant=None):
      """Both inputs are in [0, 1]; so is the result."""
 -    score = (1 - EMBED_WEIGHT) * keyword_score + EMBED_WEIGHT * embed_score
 +    weight = TENANT_EMBED_WEIGHT.get(tenant, EMBED_WEIGHT)
-     return (1 - weight) * keyword_score + weight * embed_score
++    score = (1 - weight) * keyword_score + weight * embed_score
+     if abs(keyword_score - embed_score) > DISAGREEMENT:
+         score *= 0.5  # the two signals disagree: trust neither
+     return score
$ grep -n 'def test_' tests/test_scoring.py
8:    def test_count_hits(self):
11:    def test_keyword_score_grows_with_hits(self):
16:    def test_blend_of_equal_scores(self):
19:    def test_blend_weights_the_embedding(self):
22:    def test_keyword_score_never_exceeds_one(self):
25:    def test_disagreement_halves_the_score(self):
29:    def test_penalty_uses_the_tenant_weight(self):
$ grep -c '^[<=>|]\{7\}' router/scoring.py tests/test_scoring.py
router/scoring.py:0
tests/test_scoring.py:0
[exit status: 1]
```
<!-- /snippet -->

The combined diff shows a resolution that differs from both parents in one line, the `score` line, which is what "combining" means. The test file keeps both tests and gains one for the combination. The `grep` for conflict markers exits with status 1: none left.

<!-- snippet: capstone/stage-02-merge-conflict/08-conclude -->
```text
$ bash scripts/test.sh
OK
$ git add router/scoring.py tests/test_scoring.py
$ git commit -q -m 'Restore the disagreement penalty that the merge dropped' -m 'The merge of main into this branch took the version of main for all of router/scoring.py and tests/test_scoring.py. This commit applies the penalty again, on the per-tenant weight, and keeps the tests of both changes.'
$ git status -sb
## feature/low-confidence-penalty...origin/feature/low-confidence-penalty [ahead 1]
$ git log --oneline --graph -4
* d9d428d Restore the disagreement penalty that the merge dropped
*   4870ce0 Merge remote-tracking branch 'origin/main' into feature/low-confidence-penalty
|\  
| * 95f8c85 Add per-tenant embedding weights (#13)
| *   47fb459 Merge pull request #15 from fix/keyword-score-cap
| |\  
```
<!-- /snippet -->

**Verification.**

<!-- snippet: capstone/stage-02-merge-conflict/09-verify -->
```text
# What the pull request will show now, and that it is my change and nothing else:
$ git diff --stat origin/main...HEAD
 router/scoring.py     | 6 +++++-
 tests/test_scoring.py | 7 +++++++
 2 files changed, 12 insertions(+), 1 deletion(-)
# Default weight, a tenant with its own weight, and that tenant without disagreement:
$ PYTHONPATH=. python3 -B -c 'from router.scoring import blend; print(round(blend(1.0, 0.0), 3), round(blend(1.0, 0.0, "acme-retail"), 3), round(blend(0.0, 0.5, "acme-retail"), 3))'
0.1 0.2 0.3
```
<!-- /snippet -->

The pull request now changes two files. Behavior: 0.1 for full disagreement at the default weight (half of 0.2), 0.2 for the same message of the tenant with weight 0.6 (half of 0.4), and 0.3 for that tenant without disagreement. All three match the design.

<!-- snippet: capstone/stage-02-merge-conflict/10-publish -->
```text
$ git push
To ../server.git
   4870ce0..d9d428d  feature/low-confidence-penalty -> feature/low-confidence-penalty
$ ../pr view 12
#12 Halve the score when keyword and embedding disagree
state: open   feature/low-confidence-penalty -> main   author: Lab User
merge check: clean
Commits:
  d9d428d Lab User: Restore the disagreement penalty that the merge dropped
  4870ce0 Kabir Sethi: Merge remote-tracking branch 'origin/main' into feature/low-confidence-penalty
  a7a411b Lab User: Halve the score when keyword and embedding disagree
Files changed:
 router/scoring.py     | 6 +++++-
 tests/test_scoring.py | 7 +++++++
 2 files changed, 12 insertions(+), 1 deletion(-)
$ ../pr merge 12 --squash
Merged pull request #12 into main as e3e624d (squash). Deleted the branch feature/low-confidence-penalty on the server.
```
<!-- /snippet -->

An ordinary push: the branch only moved forward. After the merge:

<!-- snippet: capstone/stage-02-merge-conflict/11-after -->
```text
$ git switch main
Switched to branch 'main'
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)
$ git pull --ff-only
From ../server
   95f8c85..e3e624d  main       -> origin/main
Updating 47fb459..e3e624d
Fast-forward
 router/classify.py    |  4 ++--
 router/scoring.py     | 10 ++++++++--
 tests/test_scoring.py |  7 +++++++
 tests/test_tenant.py  | 14 ++++++++++++++
 4 files changed, 31 insertions(+), 4 deletions(-)
 create mode 100644 tests/test_tenant.py
$ bash scripts/test.sh
OK
$ git branch -D feature/low-confidence-penalty
Deleted branch feature/low-confidence-penalty (was d9d428d).
$ git fetch --prune
From ../server
 - [deleted]         (none)     -> origin/feature/low-confidence-penalty
 - [deleted]         (none)     -> origin/feature/tenant-weights
$ git config unset merge.conflictStyle
$ cd ..
$ capstone/stage-02-merge-conflict/check.sh
Checking capstone stage 2
  ok    main on the server still contains v1.3.1 (history was not rewritten)
  ok    the per-tenant weights are on main, once
  ok    pull request #12 (feature/low-confidence-penalty) is merged
  ok    the test suite passes on main
  ok    the test of the per-tenant weight is on main
  ok    the test of the disagreement penalty is on main
  ok    tests/test_scoring.py has more tests on main than in v1.3.1 (no test was dropped in a merge)
  ok    on main a tenant with its own weight gets that weight
  ok    on main the score is halved when the two signals disagree
  ok    on main both rules hold together for a tenant with its own weight
  ok    classify passes the tenant on to the blend
  ok    everything on main since v1.3.1 arrived through a pull request
  ok    no merge, cherry-pick or rebase is left in progress in you/
PASS: the Git state of stage 2 is as required. The written deliverables are judged separately.
[exit status: 0]
```
<!-- /snippet -->

`git branch -D` is needed because a squash commit is not a descendant of the branch ([Chapter 30](../textbook/ch30-incident-response.md), section 30.12). **Not verified here:** the CI run on the new head of the pull request.

**Prevention.** A convention with a reason: the author of a branch resolves its conflicts, or is in the room (team convention). A review step: when a pull request contains a merge commit that had conflicts, the reviewer runs `git show --remerge-diff` on it (checklist). And the cheapest check of all, usable by anyone before pressing the button: does "Files changed" show what the title promises.

**Communication.** To the team, addressed to the teammate without blame:

```text
#12 is merged, with both changes working together (tests for each and for the combination).
Kabir: thanks for unblocking it. One thing to know: the merge you pushed took main's version of
scoring.py and test_scoring.py as whole files, so the penalty and its test were gone and the pull
request had an empty diff. "git show --remerge-diff <merge>" shows it in one screen. I added a commit
on top instead of rewriting the branch. Next time ping me and we resolve it together in ten minutes.
Your clone: "git switch main && git pull", then delete your local feature/low-confidence-penalty.
```

To the CTO:

```text
Subject: [Resolved] intent-router: a reviewed feature was nearly dropped during a merge (SEV 3, no customer impact)

What happened   While two pull requests that change the same file were being combined, one of the two
                features was removed together with its test. The pull request still showed green checks.
                It was noticed before merging; nothing wrong reached main.
Root cause      A merge conflict was resolved by taking one version of each file whole. Git records
                whatever resolution it is given, and the tests passed because the affected test was
                removed with the code.
What was done   The feature was re-applied on top of the other change and tests for the combination were
                added. Verified locally on the merged result. Not yet verified: the CI run on main.
Prevention      Authors resolve conflicts in their own branches; reviewers inspect conflict resolutions
                with a dedicated command. Owner: tech lead. Effective now.
```

**Postmortem.** Had the button been pressed, this would be incident 9 of Chapter 30 with a worse property: no trace on `main` at all. The reportable fact is that the last line of defence was a person reading an empty list.

---

## Stage 3: a leaked dummy secret in pushed history

The six steps of [Chapter 21B](../textbook/ch21b-repository-security-incident-response.md), section 21B.14 and [Chapter 30](../textbook/ch30-incident-response.md), section 30.17 give the order: contain, assess, eradicate, recover, communicate, prevent. The ten parts below follow that order.

**Symptoms.** A teammate reports that an environment file with a token went into the first commit of his feature branch, that he deleted it in a later commit and pushed, and that "the branch is clean now". Another teammate built on his branch and deployed it to staging. The tech lead proposes a squash merge.

**Before any Git command: contain.** The first action is a message, and it is not about Git: "Kabir, revoke the staging token at the provider now and issue a new one; tell me when the old one is rejected. Everyone: do not fetch, pull, merge or base work on `feature/embedding-client` or anything built on it until I say so." Revocation works against every copy, including the ones you cannot reach. Every `git` command typed before it is time in which the token still works. The sandbox cannot show this step, and the check cannot see it.

**Evidence.**

<!-- snippet: capstone/stage-03-leaked-secret/01-find -->
```text
$ cd you
$ git fetch
From ../server
 * [new branch]      feature/embedding-client -> origin/feature/embedding-client
 * [new branch]      feature/embedding-latency-log -> origin/feature/embedding-latency-log
 * [new tag]         staging/2026-09-16 -> staging/2026-09-16
$ git log --all --oneline -- deploy/staging.env
415fe84 Remove the staging env file
c354cbf Add the embedding service client
$ git show c354cbf:deploy/staging.env
EMBED_API_URL=https://embeddings.staging.tessaly.example/v1
EMBED_API_TOKEN=capstone-dummy-token-not-a-real-secret
EMBED_TIMEOUT_SECONDS=2
```
<!-- /snippet -->

`git log --all -- <path>` finds the commit that added the file and the commit that deleted it. `git show c354cbf:deploy/staging.env` prints the file from history: a deletion adds a snapshot without the file and removes no earlier snapshot.

**Hypotheses.** Each claim in the report is one.

| # | Claim | Prediction if true | Separating command |
|---|---|---|---|
| H1 | "The branch is clean now" | No commit reachable from the branch contains the file | `git log <branch> -- deploy/staging.env` |
| H2 | "It is only on my feature branch" | Exactly one ref reaches the adding commit | `git for-each-ref --contains <commit>` on the server |
| H3 | "A squash merge leaves the old commits behind" | After a squash merge no ref reaches them | Look at what a pull request ref holds |
| H4 | It reached `main` or a release | The adding commit is an ancestor of `origin/main` | `git merge-base --is-ancestor` |

**Diagnostic commands.**

<!-- snippet: capstone/stage-03-leaked-secret/02-scope -->
```text
# Which refs in my clone reach the commit that added the file?
$ git branch -r --contains c354cbf
  origin/feature/embedding-client
  origin/feature/embedding-latency-log
$ git tag --contains c354cbf
staging/2026-09-16
# The server has refs that a clone does not fetch. As its administrator, ask it directly:
$ git -C ../server.git for-each-ref --contains c354cbf --format='%(refname)'
refs/heads/feature/embedding-client
refs/heads/feature/embedding-latency-log
refs/pull/16/head
refs/pull/16/merge
refs/tags/staging/2026-09-16
# Is it in main or in a release?
$ git merge-base --is-ancestor c354cbf origin/main
[exit status: 1]
# Since when has the server had it? The pushing clone recorded the time:
$ git -C ../kabir reflog show --date=iso origin/feature/embedding-client
014b193 refs/remotes/origin/feature/embedding-client@{2026-09-16 10:22:00 +0530}: update by push
2b9051b refs/remotes/origin/feature/embedding-client@{2026-09-16 10:07:00 +0530}: update by push
```
<!-- /snippet -->

H2 is refuted five times over. Your clone shows two branches and a tag. The server has two more refs that a clone never fetches by default: `refs/pull/16/head` and the test merge `refs/pull/16/merge`. H4 is refuted, which is the one piece of good news: `main` and the releases are clean, so no shared history has to be rewritten. The reflog of the pushing clone gives the start of the exposure: the server has had the commit since the push at 10:07.

<!-- snippet: capstone/stage-03-leaked-secret/03-not-clean -->
```text
# The tip has no such file. The history under the tip has, and a squash merge of the pull
# request would not change that: the pull request ref keeps the original commits.
$ git cat-file -e origin/feature/embedding-client:deploy/staging.env
fatal: path 'deploy/staging.env' does not exist in 'origin/feature/embedding-client'
[exit status: 128]
$ git log --oneline origin/main..refs/remotes/origin/feature/embedding-client
014b193 Retry the embedding call once on timeout
415fe84 Remove the staging env file
2b9051b Cache embeddings by message hash
c354cbf Add the embedding service client
$ git ls-remote origin refs/pull/16/head
014b19352ef2285b6cf698b146f932c0e960e645	refs/pull/16/head
```
<!-- /snippet -->

H1: the tip has no such file, and the history under the tip has four commits of which the first contains it. H3: the pull request ref names the head of the branch, with all four commits under it. A squash merge writes one new commit to `main` and leaves `refs/pull/16/head`, the dependent branch and the tag exactly where they are. The proposal would have made `main` look clean while the server kept serving the file to anyone who asked for those refs.

**Root cause.**

```text
Observed behavior : a file with a credential is in pushed history; the tip of the branch does not show it
Git state         : c354cbf adds deploy/staging.env; 415fe84 deletes it; five refs on the server and three
                    kinds of ref in the clones reach c354cbf
Mechanism         : a commit is a snapshot; a later commit that lacks a file removes nothing from earlier
                    snapshots; every ref that reaches a commit keeps all of its ancestors alive
Root cause        : an unignored environment file in the working tree was staged with the rest of a directory
Why Git does this : history is append-only by design; that property is what makes it trustworthy
Correct fix       : revoke first; rewrite the unmerged histories; move the tag; prune the objects everywhere
Prevention        : an ignore rule; staging by name; push protection for recognised formats; short-lived tokens
```

Layers: Git stores it; the issuer accepts it; the hosting platform may keep it. Contributing conditions: no ignore rule for `deploy/*.env`; a branch that others built on within minutes; a deploy script that tags whatever it deploys.

**Safe recovery.** The decision to rewrite is a decision, not a reflex.

| Option | Result | Verdict |
|---|---|---|
| Revoke only, no rewrite | Sufficient against use of the token. The file stays in history and reaches `main` when the pull request is merged with a merge commit | Defensible for a busy `main`. Here the history is small and unmerged, so the rewrite is cheap |
| Squash-merge the pull request | `main` looks clean; five refs still reach the file | Rejected: hides the problem |
| Rewrite the two unmerged branches, move the tag, prune | The file is in no reachable history and in no object store you control | Chosen |

git-filter-repo, the documented tool for a whole repository, is not installed, and one short branch does not need it ([Chapter 30](../textbook/ch30-incident-response.md), section 30.17). No rescue branch is created in this stage: a rescue ref would keep exactly the commits that have to go. The safety net for the rewrite is the reflog, until the last step removes it on purpose.

In the author's clone, with the author:

<!-- snippet: capstone/stage-03-leaked-secret/04-rewrite -->
```text
$ cd ../kabir
$ git status -sb
## feature/embedding-client...origin/feature/embedding-client
$ git rebase -i main
--- todo list as Git opened it (comment lines removed) ---
pick c354cbf # Add the embedding service client
pick 2b9051b # Cache embeddings by message hash
pick 415fe84 # Remove the staging env file
pick 014b193 # Retry the embedding call once on timeout
--- todo list as saved ---
edit c354cbf # Add the embedding service client
pick 2b9051b # Cache embeddings by message hash
drop 415fe84 # Remove the staging env file
pick 014b193 # Retry the embedding call once on timeout
Rebasing (1/4)
Stopped at c354cbf...  # Add the embedding service client
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
```
<!-- /snippet -->

<!-- snippet: capstone/stage-03-leaked-secret/05-amend -->
```text
$ git rm --cached deploy/staging.env
rm 'deploy/staging.env'
$ printf 'deploy/*.env\n' >> .gitignore
$ git add .gitignore
$ git commit --amend --no-edit
[detached HEAD 94131df] Add the embedding service client
 Date: Wed Sep 16 10:05:00 2026 +0530
 2 files changed, 16 insertions(+)
 create mode 100644 router/embed_client.py
$ git rebase --continue
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/feature/embedding-client.
```
<!-- /snippet -->

`git rebase -i` 🟡 stops at the adding commit. `git rm --cached` takes the file out of the commit and leaves it in the working tree, where the new ignore rule covers it: the author keeps a local environment file, and it can no longer be staged by accident. The commit that deleted the file is dropped, because there is nothing left for it to delete.

<!-- snippet: capstone/stage-03-leaked-secret/06-check-rewrite -->
```text
$ git log --oneline main..feature/embedding-client
462d248 Retry the embedding call once on timeout
55d66dd Cache embeddings by message hash
94131df Add the embedding service client
$ git log --oneline feature/embedding-client -- deploy/staging.env
$ git range-diff 'feature/embedding-client@{u}'...feature/embedding-client
1:  c354cbf ! 1:  94131df Add the embedding service client
    @@ Metadata
      ## Commit message ##
         Add the embedding service client
     
    - ## deploy/staging.env (new) ##
    + ## .gitignore ##
     @@
    -+EMBED_API_URL=https://embeddings.staging.tessaly.example/v1
    -+EMBED_API_TOKEN=capstone-dummy-token-not-a-real-secret
    -+EMBED_TIMEOUT_SECONDS=2
    + __pycache__/
    + *.pyc
    + .venv/
    ++deploy/*.env
     
      ## router/embed_client.py (new) ##
     @@
2:  2b9051b = 2:  55d66dd Cache embeddings by message hash
3:  415fe84 < -:  ------- Remove the staging env file
4:  014b193 = 3:  462d248 Retry the embedding call once on timeout
$ git status -sb --ignored
## feature/embedding-client...origin/feature/embedding-client [ahead 3, behind 4]
!! deploy/
```
<!-- /snippet -->

`git range-diff` is the proof that the rewrite did what was intended and nothing more: commit 1 lost the file and gained an ignore rule (`!`), commits 2 and 4 are unchanged (`=`), commit 3 is gone (`<`). `!! deploy/` in the status is the ignored local file.

<!-- snippet: capstone/stage-03-leaked-secret/07-publish -->
```text
$ git push --force-with-lease --force-if-includes
To ../server.git
 + 014b193...462d248 feature/embedding-client -> feature/embedding-client (forced update)
```
<!-- /snippet -->

🔴 A forced push. `--force-with-lease --force-if-includes` refuses if the server's branch is not what this clone last saw, or if what it last saw was never part of the local branch ([Chapter 12](../textbook/ch12-remote-operations.md), section 12.8). It can destroy commits that someone pushed in between; the team was told to stay off the branch in the first message. The pull request follows its head branch, so `refs/pull/16/head` moved with it.

The dependent branch is transplanted, not merged: a merge or a plain pull would bring the old commits back.

<!-- snippet: capstone/stage-03-leaked-secret/08-dependent-branch -->
```text
$ cd ../tanvi
$ git fetch
From ../server
 + 2b9051b...462d248 feature/embedding-client -> origin/feature/embedding-client  (forced update)
$ git log --oneline --graph origin/feature/embedding-client feature/embedding-latency-log -6
* 462d248 Retry the embedding call once on timeout
* 55d66dd Cache embeddings by message hash
* 94131df Add the embedding service client
| * 7d464f0 Log the latency of embedding calls
| * 2b9051b Cache embeddings by message hash
| * c354cbf Add the embedding service client
|/  
$ git rebase --onto 55d66dd 2b9051b feature/embedding-latency-log
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/embedding-latency-log.
$ git log --oneline main..feature/embedding-latency-log
b34f15c Log the latency of embedding calls
55d66dd Cache embeddings by message hash
94131df Add the embedding service client
$ git push --force-with-lease --force-if-includes
To ../server.git
 + 7d464f0...b34f15c feature/embedding-latency-log -> feature/embedding-latency-log (forced update)
```
<!-- /snippet -->

`git rebase --onto 55d66dd 2b9051b` replays what lies after the old "Cache embeddings" commit onto the new one: one commit.

<!-- snippet: capstone/stage-03-leaked-secret/09-tag -->
```text
# A tag is a ref too. It still names the old commit, and a tag does not move on its own.
$ git rev-parse --short staging/2026-09-16
2b9051b
$ git tag -f staging/2026-09-16 55d66dd
Updated tag 'staging/2026-09-16' (was 2b9051b)
$ git push --force-with-lease=refs/tags/staging/2026-09-16:2b9051b origin refs/tags/staging/2026-09-16
To ../server.git
 + 2b9051b...55d66dd staging/2026-09-16 -> staging/2026-09-16 (forced update)
$ git switch --quiet main
```
<!-- /snippet -->

A tag does not move when the branch it was made from is rewritten. Moving a published tag is normally forbidden ([Chapter 14B](../textbook/ch14b-config-tags-signing.md), section 14B.11); a deployment marker that points at a commit with a credential is the exception, and the team is told. A lease works for a tag as it does for a branch: the push names the old commit as the value it expects on the server, and would be refused if someone had moved the tag in the meantime.

<!-- snippet: capstone/stage-03-leaked-secret/10-server-still-has-it -->
```text
$ cd ../you
$ git -C ../server.git for-each-ref --contains c354cbf --format='%(refname)'
# No ref on the server reaches the old commits now. The objects are still there:
$ git -C ../server.git cat-file -t c354cbf
commit
$ git -C ../server.git show c354cbf:deploy/staging.env | grep -c TOKEN
1
```
<!-- /snippet -->

No ref reaches the old commits, and the server still answers for them by ID. A forced push moves refs. It deletes no object.

<!-- snippet: capstone/stage-03-leaked-secret/11-server-prune -->
```text
# You are the administrator of this server. On GitHub this step is a request to GitHub Support.
$ git -C ../server.git gc --prune=now
$ git -C ../server.git cat-file -t c354cbf
fatal: Not a valid object name c354cbf
[exit status: 128]
```
<!-- /snippet -->

> **GitHub, not Git.** You cannot run `git gc` on GitHub. The equivalent is a request to GitHub Support, who need the first changed commit and the number of affected pull requests and who assist only where rotation cannot mitigate the risk. GitHub states that old commits can otherwise stay reachable by ID in cached views, in forks and through pull requests ([removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository), described from the documentation as in section 30.17). In the sandbox the pull request ref followed the branch; whether every reference GitHub keeps for a pull request does the same is not something this simulation can show.

<!-- snippet: capstone/stage-03-leaked-secret/12-clones -->
```text
# Every clone that fetched the branch or the tag still has the old commits: under
# remote-tracking refs and tags until it fetches, and in its reflogs after that.
$ git -C ../nandini tag --contains c354cbf
staging/2026-09-16
$ for c in you nandini kabir tanvi; do git -C ../$c fetch --quiet --prune --force --tags; done
$ git -C ../nandini for-each-ref --contains c354cbf
$ git -C ../nandini cat-file -t c354cbf
commit
$ for c in you nandini kabir tanvi; do git -C ../$c reflog expire --expire=now --all && git -C ../$c gc --quiet --prune=now; done
$ git -C ../nandini cat-file -t c354cbf
fatal: Not a valid object name c354cbf
[exit status: 128]
```
<!-- /snippet -->

The tech lead's clone never had the branch checked out and still held the commit, under a remote-tracking ref and a tag. `git fetch --prune --force --tags` updates the moved tag and the rewritten branches; after it no ref reaches the commit and the object is still there, kept by reflogs. 🔴 `git reflog expire --expire=now --all && git gc --prune=now` removes it and with it that clone's entire safety net: every reflog entry, for every branch. It is run once, deliberately, in each clone, after checking that nothing unpushed depends on a reflog.

**Verification.**

<!-- snippet: capstone/stage-03-leaked-secret/13-verify -->
```text
$ git log --all --oneline -- deploy/staging.env
$ git log --oneline --graph origin/main~1..origin/feature/embedding-client origin/feature/embedding-latency-log
* b34f15c Log the latency of embedding calls
| * 462d248 Retry the embedding call once on timeout
|/  
* 55d66dd Cache embeddings by message hash
* 94131df Add the embedding service client
* e3e624d Halve the score when keyword and embedding disagree (#12)
$ ../pr view 16
#16 Add the embedding service client
state: open   feature/embedding-client -> main   author: Kabir Sethi
merge check: clean
Commits:
  462d248 Kabir Sethi: Retry the embedding call once on timeout
  55d66dd Kabir Sethi: Cache embeddings by message hash
  94131df Kabir Sethi: Add the embedding service client
Files changed:
 .gitignore             |  1 +
 router/embed_cache.py  | 13 +++++++++++++
 router/embed_client.py | 20 ++++++++++++++++++++
 3 files changed, 34 insertions(+)
$ git -C ../kabir status -sb --ignored
## feature/embedding-client...origin/feature/embedding-client
!! deploy/
$ cd ..
$ capstone/stage-03-leaked-secret/check.sh
Checking capstone stage 3
  ok    the server still has feature/embedding-client
  ok    the server still has feature/embedding-latency-log
  ok    "Add the embedding service client" is on feature/embedding-client
  ok    "Cache embeddings by message hash" is on feature/embedding-client
  ok    "Retry the embedding call once on timeout" is on feature/embedding-client
  ok    "Log the latency of embedding calls" is on feature/embedding-latency-log
  ok    feature/embedding-latency-log still builds on the embedding client
  ok    the client retries on timeout on feature/embedding-client
  ok    main was not rewritten
  ok    no commit reachable from any ref on the server (branches, tags, pull request refs) contains the secret
  ok    the server no longer stores the blob at all
  ok    an ignore rule on feature/embedding-client covers deploy/staging.env
  ok    no commit reachable from a ref in you/ contains the secret
  ok    you/ no longer stores the blob (reflogs expired and pruned, or re-cloned)
  ok    no rebase is left in progress in you/
  ok    no commit reachable from a ref in nandini/ contains the secret
  ok    nandini/ no longer stores the blob (reflogs expired and pruned, or re-cloned)
  ok    no rebase is left in progress in nandini/
  ok    no commit reachable from a ref in kabir/ contains the secret
  ok    kabir/ no longer stores the blob (reflogs expired and pruned, or re-cloned)
  ok    no rebase is left in progress in kabir/
  ok    no commit reachable from a ref in tanvi/ contains the secret
  ok    tanvi/ no longer stores the blob (reflogs expired and pruned, or re-cloned)
  ok    no rebase is left in progress in tanvi/
  note  Git state only. If the credential was not revoked first, the incident is still open.
PASS: the Git state of stage 3 is as required. The written deliverables are judged separately.
[exit status: 0]
```
<!-- /snippet -->

No commit in any ref touches the path; the pull request shows three commits and an ignore rule; the author's local file is ignored. The check adds what a person would not do by hand: it searches every commit reachable from every ref of the server and of all four clones for the string, and asks each object store for the blob. **Not verified here, and decisive:** that the old token is rejected by the provider; what the provider's access log shows between 10:07 and the revocation; whether anyone outside the four clones fetched in that window.

**Prevention.** `deploy/*.env` is ignored, in the branch that will be merged (client default that travels with the repository). Staging by name and reading `git diff --cached` before committing (habit). Push protection (server): it blocks recognised token formats and would not have caught this free-form value, which is a reason to prefer tokens in a recognisable format from providers that support it (section 30.17). Short-lived staging tokens (limits the window whatever happens in Git). And the deploy script takes its configuration from the secret store, not from a file next to the code.

**Communication.** First message, before the rewrite:

```text
A staging credential was committed on feature/embedding-client this morning. It is being revoked now.
Until I say so: do not fetch, pull, merge or branch from feature/embedding-client,
feature/embedding-latency-log or the tag staging/2026-09-16. Do not run git gc. If you have fetched
since 10:07 today, tell me.
```

Second message, after the recovery:

```text
Done. feature/embedding-client and feature/embedding-latency-log were rewritten without the file; the
tag staging/2026-09-16 was moved to the corresponding new commit; the old objects are pruned on the server.
In every clone, once:   git fetch --prune --force --tags
Then, if you had fetched the old state:   git reflog expire --expire=now --all && git gc --prune=now
The second command deletes all your reflogs. Push anything unpushed first.
Never merge or pull an old copy of those branches: that brings the commits back.
Thank you, Kabir, for reporting it within the hour.
```

To the CTO:

```text
Subject: [Contained] intent-router: staging credential committed to a feature branch (SEV 1 until rotation confirmed)

What happened   A file with the token of the staging embedding service was pushed to our private repository
                at 10:07 IST on 16 September. It was on a feature branch, a branch built on it, a staging
                tag and the pull request. It never reached main or a release. Everyone with read access
                to the repository could have read it. The token gives access to the staging embedding
                service only.
Root cause      An environment file was not excluded from version control and was committed with other
                files. Deleting it in a later commit did not remove it from history.
What was done   The token was revoked and replaced first. The affected histories were rewritten, the old
                data removed from the server and from the four known clones. Verified: no reference in any
                of the five repositories reaches the file. Not yet verified: the provider's access log for
                the exposure window; that no other clone exists. On GitHub the server-side removal is a
                request to GitHub Support and would not be immediate.
Prevention      Environment files are now ignored in the repository. Proposed: staging tokens with a
                lifetime of hours, and deployment configuration from the secret store. Owner: platform
                team. Date: this sprint.
```

SEV 1 until the revocation is confirmed, because a credential is involved (section 30.3); lowered afterwards.

**Postmortem.** Section 9 of this file is the full postmortem for this stage.

---

## Stage 4: a failed CI run

This stage is a diagnosis on paper. The two evidence files are constructed; the Git-side cause is reproduced with plain Git.

**Symptoms.** A small pull request, one new module and one test, passes on its author's machine and fails in the `test` job on every attempt. The author suspects the Python version or a cache and asks for an administrator merge.

**Evidence.** The fixed investigation order of [Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md), section 20B.11, as far as the paper goes:

<!-- snippet: capstone/stage-04-failed-ci/01-report -->
```text
$ cd you
$ sed -n '/^## Log excerpts/,/^## Other/p' ../evidence/stage-04/RUN-REPORT.md
## Log excerpts

The lines are paraphrased. The two Git commands have the shape that Chapter 20A, section 20A.8
reproduces with plain Git.

Check out the repository:

    git fetch --no-tags --depth=1 origin +refs/pull/17/merge:refs/remotes/pull/17/merge
    git checkout --detach refs/remotes/pull/17/merge
    HEAD is now at 530a3b3 Merge 58931e96232e182cdb0a5a955ae24f8f975bc9e1 into 3c4f762348eeaf0524415753aa0e013cc9961fd2

Set up Python:

    Python 3.13 installed and put on the PATH

Show what was checked out:

    530a3b37db24b6bd8b28e19f42323c273dd6b017 Merge 58931e96232e182cdb0a5a955ae24f8f975bc9e1 into 3c4f762348eeaf0524415753aa0e013cc9961fd2

Run the tests:

    ERROR: test_batch
    FAILED
    Process completed with exit code 1.

## Other facts about the run
```
<!-- /snippet -->

<!-- snippet: capstone/stage-04-failed-ci/02-workflow -->
```text
$ grep -n -A3 'actions/checkout' ../evidence/stage-04/ci.yml
23:        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
24-        with:
25-          persist-credentials: false
26-
$ grep -n -B1 -A3 '^on:' ../evidence/stage-04/ci.yml
3-
4:on:
5-  push:
6-    branches: [main, "release/**"]
7-  pull_request:
$ git fetch
From ../server
   e3e624d..3c4f762  main                   -> origin/main
 * [new branch]      feature/batch-endpoint -> origin/feature/batch-endpoint
$ git log --oneline -2 origin/main -- .github/workflows/ci.yml
bae705c Pin CI to Python 3.13 (#9)
bfa8a15 Add CODEOWNERS and the CI workflow (#1)
```
<!-- /snippet -->

| # | Area | Answer from the two files |
|---|---|---|
| 1 | Workflow | `ci.yml`, last changed in #9, weeks ago. Not a workflow change |
| 2 | Event | `pull_request`. The checkout step has no `ref:` input, so it uses the event's ref |
| 2 | Commit checked out | `530a3b3`, whose subject is "Merge `58931e9…` into `3c4f762…`". It is not the head commit of the pull request |
| 3 | Permissions | `contents: read`; nothing in the failing step needs more |
| 4 | Runner | `ubuntu-24.04`, a fixed label |
| 7 | Secrets | none used |
| 8 | Action versions | both pinned by commit SHA |
| 9 | Logs | one test module fails to load: `ERROR: test_batch` |

The answer is in area 2. The job did not test the branch. On a `pull_request` event `actions/checkout` checks out the test merge of the head into the base, `refs/pull/N/merge` ([Chapter 20A](../textbook/ch20a-actions-fundamentals.md), section 20A.8).

**Hypotheses.**

| # | Hypothesis | Prediction | Separating evidence |
|---|---|---|---|
| H1 | Python 3.13 on the runner behaves differently | The failure is in code that depends on the version | The failing unit is an import, and the same commit fails on the local Python |
| H2 | A stale cache | The workflow restores a cache | `ci.yml` has no cache step |
| H3 | The run tested a commit that contains more than the branch | The checked-out commit has two parents, one of them `main` | The report's "Merge ... into ..." line; `git ls-remote` |
| H4 | A flaky runner | A re-run sometimes passes | Three attempts, same step, same error |

H2 is refuted by the workflow file alone. H4 is refuted by the report, and by a fact about re-runs: a re-run reuses the original commit and ref, so it can never pick up a different result from the same inputs ([Chapter 30](../textbook/ch30-incident-response.md), section 30.18).

**Diagnostic commands.** In the author's clone the claim holds:

<!-- snippet: capstone/stage-04-failed-ci/03-locally -->
```text
# The author says it passes locally. In her clone, on her branch, it does:
$ git -C ../tanvi status -sb
## feature/batch-endpoint...origin/feature/batch-endpoint
$ git -C ../tanvi log --oneline -2
58931e9 Add batch classification
d71e996 Add the embedding service client (#16)
$ bash ../tanvi/scripts/test.sh
OK
```
<!-- /snippet -->

<!-- snippet: capstone/stage-04-failed-ci/04-which-commit -->
```text
# Which commit did the run test? The report names it. Compare it with the branch:
$ git rev-parse origin/feature/batch-endpoint
58931e96232e182cdb0a5a955ae24f8f975bc9e1
$ git ls-remote origin 'refs/pull/17/*'
58931e96232e182cdb0a5a955ae24f8f975bc9e1	refs/pull/17/head
530a3b37db24b6bd8b28e19f42323c273dd6b017	refs/pull/17/merge
```
<!-- /snippet -->

The head of the pull request is `58931e9`, the branch tip. The commit the run tested is the other ref.

<!-- snippet: capstone/stage-04-failed-ci/05-reproduce -->
```text
# The runner fetched refs/pull/N/merge. So can I:
$ git fetch origin refs/pull/17/merge
From ../server
 * branch            refs/pull/17/merge -> FETCH_HEAD
$ git log -1 --format='%h %an: %s%nparents: %p' FETCH_HEAD
530a3b3 GitHub: Merge 58931e96232e182cdb0a5a955ae24f8f975bc9e1 into 3c4f762348eeaf0524415753aa0e013cc9961fd2
parents: 3c4f762 58931e9
$ git switch --quiet --detach FETCH_HEAD
$ bash scripts/test.sh
ERROR: test_batch
FAILED
[exit status: 1]
$ PYTHONPATH=. python3 -B -c "import router.batch" 2>&1 | tail -n 1 | cut -d"(" -f1
ImportError: cannot import name 'FALLBACK' from 'router.classify' 
```
<!-- /snippet -->

The same failure, on a laptop, with the local Python: H1 is refuted and H3 is confirmed. The commit was created by the platform, with `main` as its first parent and the branch as its second. The underlying error is an import of a name that `router.classify` no longer has.

<!-- snippet: capstone/stage-04-failed-ci/06-cause -->
```text
# The second parent is the branch, the first is main. What does main have that the
# branch was not written against?
$ git log --oneline origin/feature/batch-endpoint..origin/main
3c4f762 Make the fallback intent configurable per tenant (#18)
$ git log --oneline -S'FALLBACK = ' origin/feature/batch-endpoint..origin/main -- router/classify.py
3c4f762 Make the fallback intent configurable per tenant (#18)
$ git diff --stat origin/feature/batch-endpoint...origin/main
 router/classify.py     | 10 ++++++++--
 tests/test_classify.py |  8 ++++++--
 tests/test_tenant.py   |  2 +-
 3 files changed, 15 insertions(+), 5 deletions(-)
$ git diff --stat origin/main...origin/feature/batch-endpoint
 router/batch.py     | 9 +++++++++
 tests/test_batch.py | 9 +++++++++
 2 files changed, 18 insertions(+)
$ git switch --quiet main
```
<!-- /snippet -->

`main` gained #18 after the branch was created. #18 replaced the constant `FALLBACK` by a function; the branch's new module imports the constant. The two three-dot diffs show why Git merged them without a word: the two sides changed disjoint sets of files.

**Root cause.**

```text
Observed behavior : tests pass on the branch and fail in CI on the pull request, on every attempt
Git state         : refs/pull/17/merge = 530a3b3, parents 3c4f762 (main) and 58931e9 (branch head)
Mechanism         : a pull_request run checks out the test merge; main removed a name that the branch's
                    new file imports; different files, so the merge is clean and the result is broken
Root cause        : the branch was tested locally against an older main than the one it will be merged into
Why Git does this : a merge combines text. It has no knowledge of imports (Chapter 8, section 8.15)
Correct fix       : bring main into the branch, adapt the new module, test the merge result
Prevention        : read which commit a job checked out before reading its log; update before asking for review
```

Layers: GitHub Actions chose the commit (a documented default); Git produced a clean merge; the incompatibility is in the code. CI did its job. The red check was correct.

**Safe recovery.**

| Option | Result | Verdict |
|---|---|---|
| Administrator merge over the red check | `main` cannot be imported in the batch module; the next release is broken | Rejected. The check is red for the reason checks exist |
| Re-run again | Same commit, same result | Rejected: not a diagnosis |
| Check out the head commit in CI instead of the merge | Green, and tests something that will never be on `main` | Rejected |
| Merge `main` into the branch and adapt the module | The branch contains what it will meet; no rewrite of a teammate's branch | Chosen |
| Rebase the branch onto `main` | Same content, linear; rewrites a branch that is another person's and is open for review | Equally valid if the author agrees; needs a forced push |

<!-- snippet: capstone/stage-04-failed-ci/07-fix -->
```text
$ git switch feature/batch-endpoint
Switched to a new branch 'feature/batch-endpoint'
branch 'feature/batch-endpoint' set up to track 'origin/feature/batch-endpoint'.
$ git merge --no-edit origin/main
Merge made by the 'ort' strategy.
 router/classify.py     | 10 ++++++++--
 tests/test_classify.py |  8 ++++++--
 tests/test_tenant.py   |  2 +-
 3 files changed, 15 insertions(+), 5 deletions(-)
$ bash scripts/test.sh
ERROR: test_batch
FAILED
[exit status: 1]
# (edit router/batch.py: ask classify.py for the fallback intent of the tenant)
$ git diff
diff --git a/router/batch.py b/router/batch.py
index 4acfdab..2a721e7 100644
--- a/router/batch.py
+++ b/router/batch.py
@@ -1,9 +1,10 @@
 """Classify a batch of messages in one call."""
 
-from router.classify import FALLBACK, classify
+from router.classify import classify, fallback_for
 
 
 def classify_batch(batch, tenant=None):
     """batch: one candidate list per message. Returns the intents and how many fell back."""
+    fallback = fallback_for(tenant)
     intents = [classify(candidates, tenant) for candidates in batch]
-    return intents, sum(1 for intent in intents if intent == FALLBACK)
+    return intents, sum(1 for intent in intents if intent == fallback)
```
<!-- /snippet -->

After `git merge origin/main` the failure is local, without any CI. The repair asks `classify.py` for the fallback of the tenant, which is also the correct behavior: comparing with the default would have miscounted for a tenant with its own fallback.

<!-- snippet: capstone/stage-04-failed-ci/08-test-and-push -->
```text
# (edit tests/test_batch.py: one more test, for a tenant with its own fallback intent)
$ bash scripts/test.sh
OK
$ git commit -q -am 'Use the fallback intent of the tenant in the batch count'
$ git push
To ../server.git
   58931e9..02c6fc5  feature/batch-endpoint -> feature/batch-endpoint
```
<!-- /snippet -->

**Verification.** The commit that matters is the one CI will test, so test that one:

<!-- snippet: capstone/stage-04-failed-ci/09-what-ci-will-test -->
```text
# The push made the server build a new test merge. Test exactly that commit:
$ git ls-remote origin 'refs/pull/17/*'
02c6fc59b4292f266149abe4050d07af46f1cf87	refs/pull/17/head
dd6a33e494b5e4911a7e98c9670a38dcdc24084e	refs/pull/17/merge
$ git fetch --quiet origin refs/pull/17/merge
$ git switch --quiet --detach FETCH_HEAD
$ bash scripts/test.sh
OK
$ git switch --quiet feature/batch-endpoint
```
<!-- /snippet -->

The push made the server rebuild the test merge (a new ID under `refs/pull/17/merge`), and the project's tests pass on it.

<!-- snippet: capstone/stage-04-failed-ci/10-merge -->
```text
$ ../pr view 17
#17 Add batch classification
state: open   feature/batch-endpoint -> main   author: Tanvi Desai
merge check: clean
Commits:
  02c6fc5 Lab User: Use the fallback intent of the tenant in the batch count
  d904fed Lab User: Merge remote-tracking branch 'origin/main' into feature/batch-endpoint
  58931e9 Tanvi Desai: Add batch classification
Files changed:
 router/batch.py     | 10 ++++++++++
 tests/test_batch.py | 12 ++++++++++++
 2 files changed, 22 insertions(+)
$ ../pr merge 17 --squash
Merged pull request #17 into main as 1b63d64 (squash). Deleted the branch feature/batch-endpoint on the server.
$ git switch main
Switched to branch 'main'
Your branch is behind 'origin/main' by 2 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)
$ git pull --ff-only
From ../server
   3c4f762..1b63d64  main       -> origin/main
Updating e3e624d..1b63d64
Fast-forward
 .gitignore             |  1 +
 router/batch.py        | 10 ++++++++++
 router/classify.py     | 10 ++++++++--
 router/embed_cache.py  | 13 +++++++++++++
 router/embed_client.py | 20 ++++++++++++++++++++
 tests/test_batch.py    | 12 ++++++++++++
 tests/test_classify.py |  8 ++++++--
 tests/test_tenant.py   |  2 +-
 8 files changed, 71 insertions(+), 5 deletions(-)
 create mode 100644 router/batch.py
 create mode 100644 router/embed_cache.py
 create mode 100644 router/embed_client.py
 create mode 100644 tests/test_batch.py
$ git branch -D feature/batch-endpoint
Deleted branch feature/batch-endpoint (was 02c6fc5).
$ git fetch --prune
From ../server
 - [deleted]         (none)     -> origin/feature/batch-endpoint
 - [deleted]         (none)     -> origin/feature/embedding-client
```
<!-- /snippet -->

<!-- snippet: capstone/stage-04-failed-ci/11-teammate -->
```text
# What Tanvi runs in her clone. Her branch is merged; her local copy lacks my two commits.
$ cd ../tanvi
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git pull --ff-only --prune
From ../server
 - [deleted]         (none)     -> origin/feature/batch-endpoint
 - [deleted]         (none)     -> origin/feature/embedding-client
   d71e996..1b63d64  main       -> origin/main
Updating d71e996..1b63d64
Fast-forward
 router/batch.py        | 10 ++++++++++
 router/classify.py     | 10 ++++++++--
 tests/test_batch.py    | 12 ++++++++++++
 tests/test_classify.py |  8 ++++++--
 tests/test_tenant.py   |  2 +-
 5 files changed, 37 insertions(+), 5 deletions(-)
 create mode 100644 router/batch.py
 create mode 100644 tests/test_batch.py
$ git branch -D feature/batch-endpoint
Deleted branch feature/batch-endpoint (was 58931e9).
$ bash scripts/test.sh
OK
$ cd ..
$ capstone/stage-04-failed-ci/check.sh
Checking capstone stage 4
  ok    main was not rewritten
  ok    pull request #17 (feature/batch-endpoint) is merged
  ok    router/batch.py is on main
  ok    the test of the batch entry point is on main
  ok    the test suite passes on main
  ok    the change that was merged before this pull request is still on main, unchanged in behavior
  ok    on main a batch reports the intents and counts the fallbacks
  ok    on main a batch counts the fallbacks of a tenant correctly as well
  ok    everything on main since v1.3.1 arrived through a pull request
  ok    no merge or rebase is left in progress in you/
  ok    no merge or rebase is left in progress in tanvi/
PASS: the Git state of stage 4 is as required. The written deliverables are judged separately.
[exit status: 0]
```
<!-- /snippet -->

**Not verified here:** the run on GitHub. The honest status after the push is "cause removed and reproduced locally on the new test merge; confirmed when the `pull_request` run on the new head is green". In the sandbox the merge was made at that point; on GitHub you wait for the check.

**Prevention.** The workflow already prints the checked-out commit in its own step; the habit is to read that line first (checklist). A ruleset option that requires branches to be up to date before merging makes the platform refuse a pull request whose head has not seen the current base; a merge queue tests each pull request on top of the ones ahead of it ([Chapter 18](../textbook/ch18-branch-protection.md), section 18.8; [Chapter 17](../textbook/ch17-pull-requests.md), section 17.11). Both cost CI time, and for a team of four the first is the proportionate one.

**Communication.** To the team:

```text
#17 is merged. CI was right: on a pull request the test job runs on GitHub's test merge of the branch
into main (refs/pull/17/merge), and main had #18, which replaced FALLBACK by fallback_for(). The batch
module imported FALLBACK. Passing locally and failing in CI were both correct, for different commits.
I merged main into the branch and changed batch.py to use fallback_for(tenant); one more test added.
Tanvi: git switch main && git pull --ff-only --prune, then delete your local feature/batch-endpoint.
For everyone: the first line to read in a failed pull request run is "Show what was checked out".
```

To the CTO (through the tech lead; this is SEV 3 and would normally stop there):

```text
Subject: [Resolved] intent-router: pull request blocked by a failing check (SEV 3, no customer impact)

What happened   A pull request needed for today's demo failed its tests on GitHub while passing on the
                author's machine. A request to merge it over the failing check was declined.
Root cause      The check tests the result of merging the pull request into the current main. Another
                change merged earlier had removed something the new code used. GitHub Actions and Git
                behaved as documented; the two changes were incompatible.
What was done   The pull request was updated to work with the current main and merged after the merged
                result passed the tests locally. Not yet verified here: the run on GitHub itself.
Prevention      Proposed: require pull requests to be up to date with main before merging. Owner: tech
                lead. Cost: one extra CI run per pull request.
```

**Postmortem.** The interesting question is not the import. It is why "merge it as an administrator" was a natural request an hour before a demo, and whether the ruleset allows it. If the tech lead is on the bypass list ([Chapter 18](../textbook/ch18-branch-protection.md), section 18.5), the only control was her judgment.

---

## Stage 5: an accidental `git reset --hard` on unpushed work

**Symptoms.** A teammate's three unpushed commits "disappeared after a fetch". She also had a new file that she had added and not committed, an untracked notes file, and an unfinished edit to the README. She believes she was on a feature branch, and that Wednesday's clean-up emptied the reflog.

**Evidence.** At her machine, read-only.

<!-- snippet: capstone/stage-05-lost-work/01-observe -->
```text
# At Tanvi's machine, with her. Nothing is changed until the evidence is read.
$ cd tanvi
$ git status -sb
## feature/routing-metrics
$ git branch -vv
  feature/embedding-latency-log b34f15c [origin/feature/embedding-latency-log] Log the latency of embedding calls
* feature/routing-metrics       1876f06 Document the batch entry point (#19)
  fix/revert-embed-weight       618ac9c [origin/fix/revert-embed-weight] Revert "Raise the embedding weight to 0.8 (#11)"
  main                          1876f06 [origin/main] Document the batch entry point (#19)
$ git log --oneline -3
1876f06 Document the batch entry point (#19)
1b63d64 Add batch classification (#17)
3c4f762 Make the fallback intent configurable per tenant (#18)
```
<!-- /snippet -->

She is on `feature/routing-metrics`, which has no upstream and points at the same commit as `main`. Nothing here shows her work.

**Hypotheses.**

| # | Hypothesis | Prediction | Separating command |
|---|---|---|---|
| H1 | `git fetch` overwrote her commits | A fetch entry in a branch reflog at the moment they vanish | `git reflog show main` |
| H2 | A rebase dropped them | `rebase` entries in the HEAD reflog | `git reflog \| grep -c rebase` |
| H3 | A reset moved the branch she was on | A `reset: moving to` entry directly above her commits | `git reflog show <branch>` |
| H4 | The commits were on another branch than she thinks | The commit entries are in the reflog of `main` | The same command |
| H5 | The reflog is empty since Wednesday | `git reflog` shows nothing older than today | `git reflog` |

`git fetch` updates remote-tracking refs and never a local branch or the working tree ([Chapter 12](../textbook/ch12-remote-operations.md), section 12.4), so H1 is wrong by mechanism; it is still tested.

**Diagnostic commands.**

<!-- snippet: capstone/stage-05-lost-work/02-reflog -->
```text
$ git reflog -7
1876f06 HEAD@{0}: checkout: moving from main to feature/routing-metrics
1876f06 HEAD@{1}: reset: moving to origin/main
ab850cb HEAD@{2}: commit: Render the counters as text
a7c4b11 HEAD@{3}: commit: Count fallbacks per tenant
c3fab20 HEAD@{4}: commit: Add routing counters
1b63d64 HEAD@{5}: checkout: moving from main to main
1b63d64 HEAD@{6}: pull --ff-only --prune: Fast-forward
$ git reflog show main
1876f06 main@{0}: reset: moving to origin/main
ab850cb main@{1}: commit: Render the counters as text
a7c4b11 main@{2}: commit: Count fallbacks per tenant
c3fab20 main@{3}: commit: Add routing counters
1b63d64 main@{4}: pull --ff-only --prune: Fast-forward
d71e996 main@{5}: pull --ff-only: Fast-forward
# She suspects the fetch or a rebase. Does the HEAD reflog record a rebase at all?
$ git reflog | grep -c rebase
0
[exit status: 1]
```
<!-- /snippet -->

Read from the bottom. The reflog of `main` records three commits, then `reset: moving to origin/main`. H3 and H4 are confirmed: the commits were made on `main`, and a reset moved `main` away from them. No rebase (the `grep` counts 0), no fetch entry on a local branch. H5 is refuted: `git reflog expire --expire=now` on Wednesday removed the entries that existed on Wednesday; everything done since has been recorded as usual.

**Root cause.**

```text
Observed behavior : three commits, a staged file, an unstaged edit and an untracked file are gone
Git state         : main@{0} is "reset: moving to origin/main"; main@{1} is ab850cb, the last of her commits;
                    feature/routing-metrics was created afterwards at origin/main
Mechanism         : git reset --hard moved the ref of the current branch, and overwrote the index and the
                    working tree with the target commit; git clean -fd deleted the untracked directory
Root cause        : work was committed on local main by mistake, and "get the new main" was done with a
                    command that discards instead of one that integrates
Why Git does this : reset --hard is the command for "make everything equal to this commit"; it does what
                    it says and asks no question
Correct fix       : anchor main@{1}; copy the commits to the feature branch; restore the staged blob
Prevention        : git switch -c before the first commit; git pull --ff-only to update main; push early
```

Layer: Git, used as documented. Contributing conditions: no visible reminder of the current branch; local `main` accepted commits (nothing on a laptop prevents that); the work was a day old and had never been pushed.

**Safe recovery.** Name the state first.

<!-- snippet: capstone/stage-05-lost-work/03-anchor -->
```text
$ git branch rescue/before-reset 'main@{1}'
$ git log --oneline origin/main..rescue/before-reset
ab850cb Render the counters as text
a7c4b11 Count fallbacks per tenant
c3fab20 Add routing counters
$ git diff --stat origin/main...rescue/before-reset
 router/metrics.py     | 18 ++++++++++++++++++
 tests/test_metrics.py | 15 +++++++++++++++
 2 files changed, 33 insertions(+)
```
<!-- /snippet -->

`git branch rescue/before-reset 'main@{1}'` 🟢 adds a ref. From this moment the three commits are reachable again and no maintenance run can remove them.

<!-- snippet: capstone/stage-05-lost-work/04-staged -->
```text
$ git fsck --lost-found
dangling blob 57d4da0e62aed93e86acf60d14a96d6ec5d2d4d3
dangling commit 462d24864793e9743e7a733d087f3013964ea32e
dangling commit 58931e96232e182cdb0a5a955ae24f8f975bc9e1
$ ls .git/lost-found/other
57d4da0e62aed93e86acf60d14a96d6ec5d2d4d3
$ git cat-file -p 57d4da0
groups:
- name: intent-router
  rules:
  - alert: FallbackRateHigh
    expr: rate(fallbacks[10m]) / rate(routed[10m]) > 0.4
    for: 15m
# For comparison, fsck without --lost-found:
$ git fsck
dangling blob 57d4da0e62aed93e86acf60d14a96d6ec5d2d4d3
dangling commit 462d24864793e9743e7a733d087f3013964ea32e
```
<!-- /snippet -->

`git add` wrote the content of the staged file into the object database as a blob. The reset removed the index entry, not the object, and `git fsck --lost-found` finds it as a dangling blob ([Chapter 13](../textbook/ch13-recovery.md), section 13.9). The dangling commits are not part of her loss, and the transcript shows something about the command. `git fsck --lost-found` lists two dangling commits; plain `git fsck`, run directly after it, lists one. The one that only `--lost-found` reports is `58931e9`, the tip of her batch branch, which she deleted locally after its squash merge in stage 4: no ref names it, and her HEAD reflog still does. So in this run `--lost-found` did not count reflog entries as starting points, as if `--no-reflogs` had been given. The manual page of Git 2.55 does not say so; the two outputs do. The commit that both runs report, `462d248`, is the tip of the embedding branch as her clone had fetched it. Its remote-tracking ref was pruned when the server deleted the branch, and a ref's reflog is deleted with the ref, so nothing at all names it. The practical consequence for a recovery: a commit listed by `--lost-found` is not necessarily lost, and her three commits would have been in that list too, had the rescue branch not been created first.

| Option | Result | Verdict |
|---|---|---|
| `git reset --hard main@{1}` on `main` | Commits back, on the wrong branch; `main` diverges from the server again | Rejected |
| Point `feature/routing-metrics` at `ab850cb` | Commits back with their IDs, based on the old `main` | Acceptable |
| Cherry-pick the three commits onto `feature/routing-metrics` | The branch she meant, on the current `main`; the originals stay under the rescue ref until verified | Chosen |

<!-- snippet: capstone/stage-05-lost-work/05-recover -->
```text
# The commits belong on the branch she meant to use, not on main.
$ git cherry-pick origin/main..rescue/before-reset
[feature/routing-metrics c58e52b] Add routing counters
 Date: Fri Sep 18 10:04:00 2026 +0530
 1 file changed, 8 insertions(+)
 create mode 100644 router/metrics.py
[feature/routing-metrics 83b2901] Count fallbacks per tenant
 Date: Fri Sep 18 10:05:00 2026 +0530
 1 file changed, 4 insertions(+), 1 deletion(-)
[feature/routing-metrics da22a64] Render the counters as text
 Date: Fri Sep 18 10:06:00 2026 +0530
 2 files changed, 22 insertions(+)
 create mode 100644 tests/test_metrics.py
$ mkdir -p deploy
$ git cat-file -p 57d4da0 > deploy/alerts.yaml
$ git add -f deploy/alerts.yaml
$ git status -sb
## feature/routing-metrics
A  deploy/alerts.yaml
```
<!-- /snippet -->

`git add -f` because `deploy/` now contains an ignore rule for environment files; `-f` is harmless when the path is not ignored. The file is back in the state she described: added, not committed.

**Verification.**

<!-- snippet: capstone/stage-05-lost-work/06-verify -->
```text
$ git range-diff origin/main rescue/before-reset HEAD
1:  c3fab20 = 1:  c58e52b Add routing counters
2:  a7c4b11 = 2:  83b2901 Count fallbacks per tenant
3:  ab850cb = 3:  da22a64 Render the counters as text
$ bash scripts/test.sh
OK
$ git log --oneline --graph -5
* da22a64 Render the counters as text
* 83b2901 Count fallbacks per tenant
* c58e52b Add routing counters
* 1876f06 Document the batch entry point (#19)
* 1b63d64 Add batch classification (#17)
```
<!-- /snippet -->

Three `=` lines: the copies carry the same changes as the originals. The tests pass with the recovered test file.

<!-- snippet: capstone/stage-05-lost-work/07-not-recoverable -->
```text
# Two things were never given to Git: an edit to README.md that was not staged, and
# the notes file that was never added. Git has no object for either.
$ ls notes
ls: notes: No such file or directory
[exit status: 1]
$ git diff --stat HEAD -- README.md
$ git log --all --oneline -S'histogram of blended scores'
```
<!-- /snippet -->

Two things were never given to Git. The README paragraph was an edit in the working tree, never staged: no blob was written, and `reset --hard` overwrote the file. The notes file was untracked: `git clean -fd` deleted it, and Git never had an object for it ([Chapter 13](../textbook/ch13-recovery.md), section 13.12; [Chapter 11](../textbook/ch11-reset-revert-restore.md), section 11.10). The pickaxe search over all refs for a phrase from the notes finds nothing. What remains outside Git: the editor's local history or undo buffer, and a Time Machine snapshot, if either exists.

<!-- snippet: capstone/stage-05-lost-work/08-publish -->
```text
$ git push -u origin feature/routing-metrics
To ../server.git
 * [new branch]      feature/routing-metrics -> feature/routing-metrics
branch 'feature/routing-metrics' set up to track 'origin/feature/routing-metrics'.
$ git branch -vv
  feature/embedding-latency-log b34f15c [origin/feature/embedding-latency-log] Log the latency of embedding calls
* feature/routing-metrics       da22a64 [origin/feature/routing-metrics] Render the counters as text
  fix/revert-embed-weight       618ac9c [origin/fix/revert-embed-weight] Revert "Raise the embedding weight to 0.8 (#11)"
  main                          1876f06 [origin/main] Document the batch entry point (#19)
  rescue/before-reset           ab850cb Render the counters as text
$ git branch -D rescue/before-reset
Deleted branch rescue/before-reset (was ab850cb).
$ cd ..
$ capstone/stage-05-lost-work/check.sh
Checking capstone stage 5
  ok    the server has the branch feature/routing-metrics (the work is no longer on one laptop only)
  ok    "Add routing counters" is on feature/routing-metrics on the server
  ok    "Count fallbacks per tenant" is on feature/routing-metrics on the server
  ok    "Render the counters as text" is on feature/routing-metrics on the server
  ok    router/metrics.py on feature/routing-metrics has the last version of the counters
  ok    the test suite passes on feature/routing-metrics
  ok    main on the server was not touched by the recovery
  ok    main in tanvi/ equals main on the server
  ok    feature/routing-metrics in tanvi/ equals the branch on the server
  ok    the file that was staged and never committed is back in tanvi/ with its content
  ok    no cherry-pick, merge or rebase is left in progress in tanvi/
PASS: the Git state of stage 5 is as required. The written deliverables are judged separately.
[exit status: 0]
```
<!-- /snippet -->

The branch has an upstream and is on the server. The rescue branch is deleted last, after the range-diff. **Not verified here:** whether her editor or a backup still has the two files Git never saw.

**Prevention.** `git switch -c <branch>` before the first commit, and a shell prompt that shows the current branch (client default). `git pull --ff-only` to update `main`: it refuses when local `main` has commits of its own, which is the moment she would have learned where her work was (client default: `pull.ff=only`). Push a feature branch on the first day; a pushed branch survives everything in this stage (habit, made cheap by `push.autoSetupRemote`). And "discard my half-done edit" is `git restore <path>`, never a reset of the branch.

**Communication.** To the person (this is SEV 4; nobody else needs a message):

```text
Recovered: your three commits (they were on local main, not on a feature branch; the reset moved main
away from them and the reflog of main still named them) and deploy/alerts.yaml (git add had stored its
content). The commits are now on feature/routing-metrics, on top of today's main, pushed. alerts.yaml is
in your working tree, added and not committed, as before.
Not recoverable from Git: the README paragraph (edited, never staged) and notes/metrics-todo.md (never
added; git clean deleted it). Try your editor's local history.
Wednesday's clean-up did not hurt you: it removed old reflog entries, and today's were all there.
Your main equals origin/main again. Nothing else to do.
```

To the CTO: nothing is sent for a SEV 4. If asked in a corridor: "One engineer lost half a day of local work to a reset; we recovered all that had been committed or staged in twenty minutes; two unsaved-to-Git files are gone. The control is a default that refuses the command sequence, and pushing branches on day one."

**Postmortem.** Her account was wrong in three places (the branch, the command, the reflog) and honest in all three. The reflog is the reason the account did not have to be right.

---

## Stage 6: a deleted branch that a teammate needs

**Symptoms.** `feature/multilingual-intents` is not on the server. Its pull request shows as closed. The tech lead reviewed three commits in the browser last night and needs the branch on Thursday. The author is on a flight with his laptop. A teammate ran a clean-up of merged branches this morning and is sure the branch it deleted was merged.

**Evidence.**

<!-- snippet: capstone/stage-06-deleted-branch/01-observe -->
```text
$ cd you
$ git ls-remote origin 'refs/heads/feature/*'
b34f15c5b87e2d6cd7dbac5a827b9c8e63a4769d	refs/heads/feature/embedding-latency-log
da22a64dfd80761c6b65bb8efd6b2eaaf303d3c5	refs/heads/feature/routing-metrics
$ ../pr list --all | tail -n 3
#19  merged  -         docs/batch -> main   Document the batch entry point
#20  merged  -         feature/multilingual-intents -> main   Language detection groundwork
#21  closed  -         feature/multilingual-intents -> main   Hindi and Tamil intents
$ ../pr view 21
#21 Hindi and Tamil intents
state: closed   feature/multilingual-intents -> main   author: Kabir Sethi
head commit when it was closed: d3ed8df
```
<!-- /snippet -->

The server has no such branch. Pull request #20 from the same branch name is merged; #21 is closed, and the stand-in still knows the head commit it had when it was closed. Nothing has been fetched or pruned in your clone yet, on purpose.

<!-- snippet: capstone/stage-06-deleted-branch/02-what-the-clones-have -->
```text
# My clone has a remote-tracking branch from my last fetch. I do not fetch with --prune
# now: that would delete the one copy of the name I have.
$ git log --oneline origin/main..origin/feature/multilingual-intents
3167a88 Add Tamil keyword lists
dcdc06b Add Hindi keyword lists
# Nandini saw three commits in the pull request. This is two.
$ git -C ../tanvi branch -r --list 'origin/feature/*'
  origin/feature/embedding-latency-log
  origin/feature/routing-metrics
$ git -C ../nandini branch -r --list 'origin/feature/*'
  origin/feature/batch-endpoint
  origin/feature/embedding-latency-log
```
<!-- /snippet -->

Your clone has a remote-tracking branch from yesterday evening with two commits. The reviewer saw three. So your copy is real and it is stale. The other two clones have no ref of that name at all. This is the inventory the briefing asks for, and it already rules out the tempting recovery: `git push origin origin/feature/multilingual-intents:refs/heads/feature/multilingual-intents` would restore a branch that lacks its last commit, and everyone would believe the incident closed.

**Hypotheses.**

| # | Hypothesis | Prediction | Separating command |
|---|---|---|---|
| H1 | The branch was fully merged; nothing is lost | Its last tip is an ancestor of `main` | `git merge-base --is-ancestor <tip> origin/main` |
| H2 | The clean-up judged the branch by an old position of it | The script's output names a commit older than the branch's last tip | Read the script and its output |
| H3 | The author deleted it himself before leaving | No deletion in the script's output | The same output |
| H4 | The last commit was never pushed, so three commits never existed on the server | No server-side record of a third commit | `git ls-remote origin 'refs/pull/*'` |

**Diagnostic commands.**

<!-- snippet: capstone/stage-06-deleted-branch/03-cause -->
```text
$ cat ../evidence/stage-06/cleanup-merged-branches.sh
#!/usr/bin/env bash
# Delete branches on the server that are already merged into main.
git fetch origin main
for b in $(git branch -r --merged origin/main | sed 's|^ *origin/||' | grep -Ev '^(main|HEAD|release/)'); do
  echo "merged, deleting: $b ($(git rev-parse --short "origin/$b"))"
  git push origin --delete "$b"
done
$ cat ../evidence/stage-06/cleanup-output.txt
From ../server
 * branch            main       -> FETCH_HEAD
   1876f06..2fe3b1c  main       -> origin/main
merged, deleting: feature/multilingual-intents (bbe770e)
To ../server.git
 - [deleted]         feature/multilingual-intents
```
<!-- /snippet -->

The script refreshes one ref, `origin/main`, and then asks which remote-tracking branches are merged into it. Remote-tracking branches are this clone's memory of the server at its last full fetch ([Chapter 12](../textbook/ch12-remote-operations.md), sections 12.4 and 12.11). The output names the commit the clone remembered for the branch, and H3 is refuted: the script deleted it.

<!-- snippet: capstone/stage-06-deleted-branch/04-test-the-cause -->
```text
# Her clone thought the branch ended at the commit in the output. Is that commit merged?
$ git log --oneline -1 bbe770e
bbe770e Detect Devanagari script as Hindi
$ git merge-base --is-ancestor bbe770e origin/main
[exit status: 0]
$ git log --oneline --merges -1 --ancestry-path bbe770e..origin/main
2fe3b1c Merge pull request #20 from feature/multilingual-intents
# And the branch as I last saw it?
$ git merge-base --is-ancestor origin/feature/multilingual-intents origin/main
[exit status: 1]
```
<!-- /snippet -->

The remembered commit is "Detect Devanagari script as Hindi", the head of pull request #20, and it is an ancestor of `main` through the merge commit of #20. So the teammate's statement is true about the commit her clone knew. The branch as you last saw it is not an ancestor of `main`. H1 is refuted and H2 is confirmed: the branch name was reused after the first pull request was merged, her clone never fetched the new position, and "merged" was computed from the old one.

<!-- snippet: capstone/stage-06-deleted-branch/05-find-the-tip -->
```text
$ git ls-remote origin 'refs/pull/21/*'
d3ed8df5df48877a2f9d1b06da1e3042d8f30323	refs/pull/21/head
$ git fetch origin refs/pull/21/head
From ../server
 * branch            refs/pull/21/head -> FETCH_HEAD
$ git log --oneline origin/main..FETCH_HEAD
d3ed8df Pick the keyword lists by detected language
3167a88 Add Tamil keyword lists
dcdc06b Add Hindi keyword lists
$ git log --oneline origin/feature/multilingual-intents..FETCH_HEAD
d3ed8df Pick the keyword lists by detected language
```
<!-- /snippet -->

The server still has `refs/pull/21/head`. It names a commit with three commits above `main`, one more than your remote-tracking branch. H4 is refuted, and this is the commit the reviewer saw.

**Root cause.**

```text
Observed behavior : a branch with unmerged work was deleted on the server by a clean-up of merged branches
Git state         : in the cleaning clone, origin/feature/multilingual-intents named the head of the merged
                    pull request #20; on the server the branch had been pushed again with three more commits
Mechanism         : "git fetch origin main" updates one remote-tracking ref; "git branch -r --merged" tests
                    this clone's remote-tracking refs, not the server; "git push origin --delete" deletes
                    whatever the server has under that name
Root cause        : a destructive action on the server was decided from a stale local copy of its state
Why Git does this : a remote-tracking ref is a cache, updated only by fetch; a delete names a ref, not a commit
Correct fix       : restore the branch at the commit the server last had; reopen the pull request
Prevention        : fetch --prune before deciding; delete with an expected value; protect branches with open pull requests
```

Layers: Git (the stale ref and the unconditional delete) and a team convention (a branch name reused after its pull request was merged). GitHub closed the pull request because its head branch was gone, which is documented behavior.

**Safe recovery.**

| Source of the commit | What it would restore | Verdict |
|---|---|---|
| Your remote-tracking branch | Two of three commits | Rejected: stale by one push |
| The author's clone | Everything, including anything unpushed | Not available until tomorrow evening |
| `git fsck` in `server.git` for unreachable commits | The right commit, among others | Works in the sandbox; impossible on GitHub |
| `refs/pull/21/head` on the server | Exactly what the pull request showed | Chosen |

<!-- snippet: capstone/stage-06-deleted-branch/06-restore -->
```text
$ git push origin d3ed8df:refs/heads/feature/multilingual-intents
To ../server.git
 * [new branch]      d3ed8df -> feature/multilingual-intents
$ ../pr reopen 21
Reopened pull request #21 (feature/multilingual-intents -> main)
$ ../pr view 21
#21 Hindi and Tamil intents
state: open   feature/multilingual-intents -> main   author: Kabir Sethi
merge check: clean
Commits:
  d3ed8df Kabir Sethi: Pick the keyword lists by detected language
  3167a88 Kabir Sethi: Add Tamil keyword lists
  dcdc06b Kabir Sethi: Add Hindi keyword lists
Files changed:
 router/keywords_hi.py |  6 ++++++
 router/keywords_ta.py |  6 ++++++
 router/lang.py        | 11 +++++++++++
 tests/test_lang.py    | 14 ++++++++++++++
 4 files changed, 37 insertions(+)
```
<!-- /snippet -->

`git push origin <commit>:refs/heads/<branch>` 🟡 creates a ref on the server. It overwrites nothing, because the name does not exist; had someone recreated the branch in the meantime, the push would have been rejected as a non-fast-forward, which is the behavior you want.

> **GitHub, not Git.** On GitHub the instrument is the **Restore branch** button on the closed pull request ([deleting and restoring branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request), [Chapter 30](../textbook/ch30-incident-response.md), section 30.12). It exists only for branches that had a pull request, and it restores what the server had: a commit that was never pushed is not there. The Activity view of the repository records the deletion with the user and the time ([Chapter 13](../textbook/ch13-recovery.md), section 13.15).

> **Unverified.** [Chapter 17](../textbook/ch17-pull-requests.md), section 17.2 shows that the pull request ref outlives the head branch, and quotes GitHub's statement that commits in a pull request are available in the repository. Neither says for how long the ref of a *closed* pull request can be fetched. On GitHub, Restore branch is the documented route; `git fetch origin pull/<number>/head`, the route used here, is the second one to try.

**Verification.**

<!-- snippet: capstone/stage-06-deleted-branch/07-verify -->
```text
$ git fetch
$ git log --oneline origin/main..origin/feature/multilingual-intents
d3ed8df Pick the keyword lists by detected language
3167a88 Add Tamil keyword lists
dcdc06b Add Hindi keyword lists
$ git switch --quiet --detach origin/feature/multilingual-intents
$ bash scripts/test.sh
OK
$ git switch --quiet main
```
<!-- /snippet -->

Three commits above `main`, and the tests pass on the restored tip. **Not verified here:** that the author has nothing newer on his laptop. When he lands, `git fetch` followed by `git status -sb` on the branch tells him: "ahead" means he has unpushed commits, which a plain `git push` publishes, because the restored branch is an ancestor of his.

**Prevention.**

<!-- snippet: capstone/stage-06-deleted-branch/08-prevent -->
```text
# The script, repaired in Tanvi's clone: prune first, so that the list is the server's.
$ cd ../tanvi
$ git branch -r --merged origin/main
  origin/HEAD -> origin/main
  origin/main
$ git fetch --prune
From ../server
 * [new branch]      feature/multilingual-intents -> origin/feature/multilingual-intents
$ git branch -r --merged origin/main
  origin/HEAD -> origin/main
  origin/main
$ cd ..
$ capstone/stage-06-deleted-branch/check.sh
Checking capstone stage 6
  ok    the server has the branch feature/multilingual-intents again
  ok    "Add Hindi keyword lists" is on the branch
  ok    "Add Tamil keyword lists" is on the branch
  ok    "Pick the keyword lists by detected language" is on the branch
  ok    the branch has exactly the three commits that main does not have
  ok    the branch has the last version of router/lang.py
  ok    the test suite passes on the branch
  ok    pull request #21 is open again
  ok    main on the server was not touched by the recovery
PASS: the Git state of stage 6 is as required. The written deliverables are judged separately.
[exit status: 0]
```
<!-- /snippet -->

After `git fetch --prune` the clone's list is the server's list, and the restored branch is not in the merged set. Three controls, strongest first. On the server: a ruleset that restricts deletions for `feature/**`, or at least the habit of deleting branches only through the pull request that merged them (the repository setting "Automatically delete head branches" deletes a pull request's branch after merging, [Chapter 15](../textbook/ch15-github.md), section 15.5; the deletion rule is in [Chapter 18](../textbook/ch18-branch-protection.md), section 18.11). In the script: `git fetch --prune origin` as its first line, and a delete that states what it expects, `git push --force-with-lease=<branch>:<commit> origin --delete <branch>`, so that a branch which moved is not deleted. As a convention: a new branch name after a pull request is merged ([Chapter 30](../textbook/ch30-incident-response.md), section 30.12 makes the same point from the other side).

**Communication.** To the team:

```text
feature/multilingual-intents is back on the server at "Pick the keyword lists by detected language"
(three commits above main), and #21 is open again. Nandini: it is the state you reviewed.
What happened: the branch name was reused after #20 was merged. The clean-up script judged "merged"
from a clone that still remembered the old tip, and deleted the name on the server.
Tanvi: run "git fetch --prune" now; please do not run the script again until it starts with that line.
Kabir, when you land: git fetch, then git status -sb on the branch. If it says "ahead", push. Do not
force anything; the server has exactly what you pushed last.
Nobody else needs to do anything.
```

To the CTO:

```text
Subject: [Resolved] intent-router: a feature branch needed for Thursday's demo was deleted (SEV 3, no customer impact)

What happened   A routine clean-up of merged branches deleted a branch that held three unmerged commits.
                The pull request closed automatically. The branch was restored within the hour from the
                platform's own record of the pull request. No work was lost.
Root cause      The clean-up decided from an outdated local copy of the server's state. Git deletes a
                branch on the server by name, whatever it currently contains.
What was done   The branch was restored at the commit the pull request last showed, and the pull request
                reopened. Verified: the three commits are present and the tests pass. Not yet verified:
                whether the author has newer local work; he is travelling until tomorrow evening.
Prevention      The script now refreshes its view first and deletes conditionally. Proposed: a rule that
                restricts deletion of feature branches on the server. Owner: platform team. This week.
```

**Postmortem.** Two true statements produced a wrong action: "the branch was merged" and "I only delete merged branches". The record should show that the script worked as written, and that its first line fetched one branch.

---

## Stage 7: a rebased and force-pushed shared branch, and a broken pull request

The eleven steps of [Chapter 30](../textbook/ch30-incident-response.md), section 30.16. Steps 1 to 6 change nothing.

**Symptoms.** The pull request "Escalate VIP customers" lists the commits twice, plus a merge commit by the reviewer. One teammate rebased and pushed "with a lease". The reviewer "only pulled, committed and pushed". A third suggests a squash merge. You have one unpushed commit and have not fetched.

**Hypotheses.**

| # | Hypothesis | Prediction | Separating command |
|---|---|---|---|
| H1 | The rebase itself duplicated the commits | The rebased series contains each change twice | `git log` of the rebased tip |
| H2 | A pull without rebase merged the old series with the rebased one | The tip is a merge whose parents are the two series; the pulling clone's reflog says `pull: Merge made` | `git show --format=%p`, the reviewer's reflog |
| H3 | The forced push overwrote a commit that was on the server | A commit that you pushed is not an ancestor of the rebased tip | `git merge-base --is-ancestor` |
| H4 | "A lease cannot overwrite anybody's work" | The pushing clone had not fetched the overwritten commit | The pusher's reflog of the remote-tracking branch |

**Step 1: inspect the state.**

<!-- snippet: capstone/stage-07-broken-pull-request/01-state -->
```text
$ cd you
$ git status -sb
## feature/vip-escalation...origin/feature/vip-escalation [ahead 1]
$ git fetch
From ../server
   1d05422..b2cd1bb  feature/vip-escalation -> origin/feature/vip-escalation
   2fe3b1c..52620f1  main                   -> origin/main
$ git status -sb
## feature/vip-escalation...origin/feature/vip-escalation [ahead 1, behind 5]
$ ../pr view 22
#22 Escalate VIP customers
state: open   feature/vip-escalation -> main   author: Lab User
merge check: clean
Commits:
  b2cd1bb Nandini Iyer: Merge branch 'feature/vip-escalation' of ../server into feature/vip-escalation
  fa2c06d Nandini Iyer: Document the VIP escalation
  362bf08 Kabir Sethi: Escalate VIP messages that would fall back
  78e8fd3 Lab User: Add the VIP customer list
  1d05422 Lab User: Test the VIP escalation
  9d7793f Kabir Sethi: Escalate VIP messages that would fall back
  b337eef Lab User: Add the VIP customer list
Files changed:
 README.md         |  4 ++++
 router/vip.py     | 14 ++++++++++++++
 tests/test_vip.py | 14 ++++++++++++++
 3 files changed, 32 insertions(+)
```
<!-- /snippet -->

Before the fetch your clone says "ahead 1" and nothing looks wrong. After it: ahead 1, behind 5. The pull request lists seven commits and three changed files. Commit list and file view answer different questions ([Chapter 17](../textbook/ch17-pull-requests.md), section 17.3), which is why one person sees a broken pull request and another sees a correct one.

<!-- snippet: capstone/stage-07-broken-pull-request/02-graph -->
```text
$ git log --oneline --graph feature/vip-escalation origin/feature/vip-escalation --not origin/main~1
* 8bd0113 Escalate VIP messages without any intent as well
| *   b2cd1bb Merge branch 'feature/vip-escalation' of ../server into feature/vip-escalation
| |\  
| | * 362bf08 Escalate VIP messages that would fall back
| | * 78e8fd3 Add the VIP customer list
| | * 52620f1 Give the CI job 15 minutes (#23)
| * fa2c06d Document the VIP escalation
|/  
* 1d05422 Test the VIP escalation
* 9d7793f Escalate VIP messages that would fall back
* b337eef Add the VIP customer list
```
<!-- /snippet -->

The graph is the whole incident in eleven lines. At the bottom, the old series: three commits. On the right, the same first two commits again on top of a newer `main`. The reviewer's commit sits on the old series, and a merge joins the two. Your unpushed commit sits on the old series as well.

**Step 2: inspect refs.**

<!-- snippet: capstone/stage-07-broken-pull-request/03-refs -->
```text
$ git for-each-ref --format='%(refname:short) %(objectname:short) %(upstream:track)' refs/heads/feature/vip-escalation refs/remotes/origin/feature/vip-escalation refs/remotes/origin/main
feature/vip-escalation 8bd0113 [ahead 1, behind 5]
origin/feature/vip-escalation b2cd1bb 
origin/main 52620f1 
$ git ls-remote origin feature/vip-escalation
b2cd1bbae0555a76a1cbabe687ae5115e3ba4441	refs/heads/feature/vip-escalation
```
<!-- /snippet -->

The remote-tracking branch and the server agree. This is not a stale view: the seven commits are what the repository contains.

**Step 3: inspect the reflogs.** Yours first.

<!-- snippet: capstone/stage-07-broken-pull-request/04-reflog-mine -->
```text
$ git reflog show origin/feature/vip-escalation
b2cd1bb refs/remotes/origin/feature/vip-escalation@{0}: fetch: fast-forward
1d05422 refs/remotes/origin/feature/vip-escalation@{1}: update by push
9d7793f refs/remotes/origin/feature/vip-escalation@{2}: pull --ff-only: fast-forward
b337eef refs/remotes/origin/feature/vip-escalation@{3}: update by push
$ git reflog show feature/vip-escalation
8bd0113 feature/vip-escalation@{0}: commit: Escalate VIP messages without any intent as well
1d05422 feature/vip-escalation@{1}: commit: Test the VIP escalation
9d7793f feature/vip-escalation@{2}: pull --ff-only: Fast-forward
b337eef feature/vip-escalation@{3}: commit: Add the VIP customer list
2fe3b1c feature/vip-escalation@{4}: branch: Created from HEAD
```
<!-- /snippet -->

Your clone recorded the last step as `fetch: fast-forward`. From where you stand, the server's branch only moved forward, because the merge commit has your last pushed commit among its ancestors. A forced push happened in between, and your clone has no record of it. The evidence is in the other two clones:

<!-- snippet: capstone/stage-07-broken-pull-request/05-reflog-teammates -->
```text
# My clone saw a fast-forward. The other two clones saw more:
$ git -C ../nandini reflog show origin/feature/vip-escalation
b2cd1bb refs/remotes/origin/feature/vip-escalation@{0}: update by push
362bf08 refs/remotes/origin/feature/vip-escalation@{1}: pull: forced-update
1d05422 refs/remotes/origin/feature/vip-escalation@{2}: pull --ff-only: storing head
$ git -C ../nandini reflog show feature/vip-escalation
b2cd1bb feature/vip-escalation@{0}: pull: Merge made by the 'ort' strategy.
fa2c06d feature/vip-escalation@{1}: commit: Document the VIP escalation
1d05422 feature/vip-escalation@{2}: branch: Created from refs/remotes/origin/feature/vip-escalation
$ git -C ../kabir reflog show origin/feature/vip-escalation
362bf08 refs/remotes/origin/feature/vip-escalation@{0}: update by push
1d05422 refs/remotes/origin/feature/vip-escalation@{1}: fetch: fast-forward
9d7793f refs/remotes/origin/feature/vip-escalation@{2}: update by push
b337eef refs/remotes/origin/feature/vip-escalation@{3}: pull --ff-only: storing head
$ git -C ../kabir reflog show feature/vip-escalation
362bf08 feature/vip-escalation@{0}: rebase (finish): refs/heads/feature/vip-escalation onto 52620f1513be8310a4fdb4b3ef8e5110db21b95f
9d7793f feature/vip-escalation@{1}: commit: Escalate VIP messages that would fall back
b337eef feature/vip-escalation@{2}: branch: Created from refs/remotes/origin/feature/vip-escalation
```
<!-- /snippet -->

Read each from the bottom. The reviewer's clone: the branch was created at your tests commit, she committed, and then `pull: Merge made by the 'ort' strategy`, while her remote-tracking branch records `pull: forced-update`. H2 is confirmed. The rebasing clone: `fetch: fast-forward` to your tests commit, then `update by push`; and his local branch went from his own commit straight to `rebase (finish)`. He fetched your commit and never had it in his branch.

**Step 4: identify the old branch state.**

<!-- snippet: capstone/stage-07-broken-pull-request/06-old-state -->
```text
$ git show --no-patch --format='%h parents: %p' origin/feature/vip-escalation
b2cd1bb parents: fa2c06d 362bf08
# The shared tip before the rebase, the rebased tip, the review fix, my unpushed tip:
$ git log --no-walk --format='%h %an: %s' 1d05422 362bf08 fa2c06d 8bd0113
8bd0113 Lab User: Escalate VIP messages without any intent as well
fa2c06d Nandini Iyer: Document the VIP escalation
362bf08 Kabir Sethi: Escalate VIP messages that would fall back
1d05422 Lab User: Test the VIP escalation
```
<!-- /snippet -->

Four commits by name: the shared tip before the rebase (your tests commit), the rebased tip (second parent of the merge), the reviewer's commit (first parent of the merge), and your unpushed tip.

**Step 5: understand what changed.**

<!-- snippet: capstone/stage-07-broken-pull-request/07-what-changed -->
```text
# Are the rebased commits the same changes as the old ones?
$ git range-diff origin/main~1..9d7793f origin/main..362bf08
1:  b337eef = 1:  78e8fd3 Add the VIP customer list
2:  9d7793f = 2:  362bf08 Escalate VIP messages that would fall back
# Did the forced push carry the commit I had pushed before it?
$ git merge-base --is-ancestor 1d05422 362bf08
[exit status: 1]
$ git log --oneline 362bf08..1d05422
1d05422 Test the VIP escalation
9d7793f Escalate VIP messages that would fall back
b337eef Add the VIP customer list
$ git -C ../kabir config get push.useForceIfIncludes
[exit status: 1]
$ git -C ../nandini config get pull.rebase
false
```
<!-- /snippet -->

`git range-diff` pairs the two old commits with the two rebased ones: `=` twice, the same changes under new IDs. H1 is refuted; the rebase duplicated nothing. The next command is the finding that matters: your tests commit is not an ancestor of the rebased tip. H3 is confirmed. The forced push removed a commit from the server that you had pushed. It came back only because the reviewer's merge happened to carry it.

And H4, the claim that a lease cannot overwrite anybody's work: `--force-with-lease` without a value compares the server's ref with the pusher's remote-tracking ref. He had fetched a minute earlier, so the two were equal, and the lease held. It protects against what you have not fetched, not against what you have fetched and not integrated. `--force-if-includes` adds that second condition ([Chapter 12](../textbook/ch12-remote-operations.md), section 12.8); `push.useForceIfIncludes` is not set in his clone. The reviewer's clone has `pull.rebase=false`.

**Step 6: preserve recoverable references.**

<!-- snippet: capstone/stage-07-broken-pull-request/08-preserve -->
```text
$ git branch rescue/server-state origin/feature/vip-escalation
branch 'rescue/server-state' set up to track 'origin/feature/vip-escalation'.
$ git branch rescue/my-work feature/vip-escalation
```
<!-- /snippet -->

One ref for the state on the server, to compare with and to return to; one for the only commit that exists in a single clone.

**Step 7: determine the safest recovery.**

| Option | Result | Verdict |
|---|---|---|
| Squash-merge the pull request as it is | Correct content on `main` in one commit. Your unpushed commit is not in it; three authors become one; the branch stays broken for whoever pulls next | Acceptable only when nothing is unpushed anywhere and the team squashes by rule. Not here |
| `git pull` (merge) and push | A second merge on top of the first; nine commits | Rejected |
| Force the old series back | Undoes the rebase; the branch conflicts with `main` again; the rebasing clone diverges | Rejected: destroys a teammate's work |
| Keep the rebased series; replay only what lies after the old shared history | Five commits, once each, on the current `main`; the rebasing clone can fast-forward | Chosen |

**Step 8: restore the correct history.**

<!-- snippet: capstone/stage-07-broken-pull-request/09-rebuild -->
```text
# Keep the rebased series. Replay what lies after the old shared history: my two commits,
# then the review fix.
$ git rebase --onto 362bf08 9d7793f
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/vip-escalation.
$ git cherry-pick fa2c06d
[feature/vip-escalation 66dc07e] Document the VIP escalation
 Author: Nandini Iyer <nandini@example.com>
 Date: Tue Sep 22 10:33:00 2026 +0530
 1 file changed, 4 insertions(+)
$ git log --oneline --graph origin/main~1..feature/vip-escalation
* 66dc07e Document the VIP escalation
* 91a0fc1 Escalate VIP messages without any intent as well
* ee6e113 Test the VIP escalation
* 362bf08 Escalate VIP messages that would fall back
* 78e8fd3 Add the VIP customer list
* 52620f1 Give the CI job 15 minutes (#23)
```
<!-- /snippet -->

`git rebase --onto <rebased tip> <old second commit>` 🟡 replays what your branch has after the old copy of the second commit, which is your two commits, onto the rebased tip. `git cherry-pick` 🟡 adds the reviewer's commit, with her as its author. Two proofs before anything is published:

<!-- snippet: capstone/stage-07-broken-pull-request/10-check-result -->
```text
$ git range-diff 9d7793f..rescue/my-work 362bf08..feature/vip-escalation~1
1:  1d05422 = 1:  ee6e113 Test the VIP escalation
2:  8bd0113 = 2:  91a0fc1 Escalate VIP messages without any intent as well
$ git range-diff fa2c06d~1..fa2c06d feature/vip-escalation~1..feature/vip-escalation
1:  fa2c06d = 1:  66dc07e Document the VIP escalation
# Content: the new tip must equal what a merge of the server state and my work would give.
$ git merge-tree --write-tree rescue/server-state rescue/my-work
ed2b2114d5a3b9fd71b387ff653b4be9c24c7d06
$ git rev-parse 'feature/vip-escalation^{tree}'
ed2b2114d5a3b9fd71b387ff653b4be9c24c7d06
$ bash scripts/test.sh
OK
```
<!-- /snippet -->

History: every replayed commit pairs with its original as `=`. Content: `git merge-tree --write-tree` computes, without touching anything, the tree that a merge of the server's state with your work would have; the rebuilt tip has the same tree ID ([Chapter 8](../textbook/ch08-merge.md), section 8.17). The repair changes history and no content, and the tests pass.

**Step 9: update the pull request safely.**

<!-- snippet: capstone/stage-07-broken-pull-request/11-publish -->
```text
$ git push --force-with-lease=feature/vip-escalation:b2cd1bb origin feature/vip-escalation
To ../server.git
 + b2cd1bb...66dc07e feature/vip-escalation -> feature/vip-escalation (forced update)
$ ../pr view 22
#22 Escalate VIP customers
state: open   feature/vip-escalation -> main   author: Lab User
merge check: clean
Commits:
  66dc07e Nandini Iyer: Document the VIP escalation
  91a0fc1 Lab User: Escalate VIP messages without any intent as well
  ee6e113 Lab User: Test the VIP escalation
  362bf08 Kabir Sethi: Escalate VIP messages that would fall back
  78e8fd3 Lab User: Add the VIP customer list
Files changed:
 README.md         |  4 ++++
 router/vip.py     | 14 ++++++++++++++
 tests/test_vip.py | 17 +++++++++++++++++
 3 files changed, 35 insertions(+)
```
<!-- /snippet -->

🔴 The lease names the merge commit, the value that was examined. If anyone had pushed since the fetch, the push would be refused. The pull request now lists five commits by three authors.

> **GitHub, not Git.** After a forced push to a head branch, review comments attached to replaced commits are shown as outdated, and an approval is dismissed if the rule "dismiss stale pull request approvals" is on and the diff changed ([Chapter 17](../textbook/ch17-pull-requests.md), sections 17.5 and 17.12). The pull request timeline records `head_ref_force_pushed` events ([Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.8), which on GitHub is the direct evidence for step 3 that the sandbox had to take from two clones' reflogs.

The teammates' clones:

<!-- snippet: capstone/stage-07-broken-pull-request/12-teammates -->
```text
# Nandini stands on the merge. A pull would merge again. Is anything of hers not upstream?
$ cd ../nandini
$ git fetch
From ../server
 + b2cd1bb...66dc07e feature/vip-escalation -> origin/feature/vip-escalation  (forced update)
$ git status -sb
## feature/vip-escalation...origin/feature/vip-escalation [ahead 5, behind 3]
# A first idea: list her commits that have no patch-equivalent upstream.
$ git log --oneline --no-merges --cherry-pick --right-only origin/feature/vip-escalation...feature/vip-escalation
9d7793f Escalate VIP messages that would fall back
b337eef Add the VIP customer list
# Those are the old copies of two commits that range-diff paired with upstream commits.
# A sharper test: if merging her branch into the new one changes nothing, nothing is missing.
$ git merge-tree --write-tree origin/feature/vip-escalation feature/vip-escalation
cd5734380e42ed8cf251b28e613a7b60f83ab548
100644 f9a58a3f3fce321e0ee46aee4e0b46eac85b8562 2	tests/test_vip.py
100644 0536658bfc9e5c7de47bb8963cf07915a4c8d8bf 3	tests/test_vip.py

Auto-merging tests/test_vip.py
CONFLICT (add/add): Merge conflict in tests/test_vip.py
$ git rev-parse 'origin/feature/vip-escalation^{tree}'
ed2b2114d5a3b9fd71b387ff653b4be9c24c7d06
$ git reset --keep origin/feature/vip-escalation
# Kabir stands on the rebased tip, an ancestor of the new one.
$ cd ../kabir
$ git pull --ff-only
From ../server
   362bf08..66dc07e  feature/vip-escalation -> origin/feature/vip-escalation
Updating 362bf08..66dc07e
Fast-forward
 README.md         |  4 ++++
 router/vip.py     |  2 +-
 tests/test_vip.py | 17 +++++++++++++++++
 3 files changed, 22 insertions(+), 1 deletion(-)
 create mode 100644 tests/test_vip.py
```
<!-- /snippet -->

The reviewer's branch stands on the merge: ahead 5, behind 3. A pull would merge again. Before her branch is moved, one question: does it hold anything that the new branch lacks? A merge of her branch into the new one would produce the new one's tree, so the answer is no, and `git reset --keep` 🟡 moves her branch. `--keep` refuses if she has local changes that the move would overwrite. The rebasing clone stands on an ancestor of the new tip, and `git pull --ff-only` is the whole repair.

The transcript starts with a first attempt at that question, `git log --cherry-pick --right-only origin/<branch>...<branch>`, which listed the two old commits as having no equivalent upstream, although `range-diff` had paired them a minute earlier. The reason: with a symmetric difference, `--cherry-pick` compares only the commits that are on one side and not the other, and the rebased copies are on both sides, since her merge contains them. A tree comparison answers the question that was meant.

**Step 10: explain what happened.** Three sentences, no blame: "The branch was rebased onto `main` and pushed with a lease while it had a commit on the server that the rebase did not include; the lease held because that commit had been fetched. A pull in another clone then merged the old series with the rebased one, which brought the commit back and listed everything twice. I rebuilt the branch as the rebased commits plus the three later ones; no content changed, and the review of the diff stays valid."

**Step 11: prevent recurrence.**

<!-- snippet: capstone/stage-07-broken-pull-request/13-prevent -->
```text
$ git config set push.useForceIfIncludes true
$ git -C ../nandini config set pull.ff only
$ git -C ../nandini config unset pull.rebase
$ cd ../you
$ git config set pull.ff only
$ git branch -D rescue/server-state rescue/my-work
Deleted branch rescue/server-state (was b2cd1bb).
Deleted branch rescue/my-work (was 8bd0113).
$ git status -sb
## feature/vip-escalation...origin/feature/vip-escalation
$ cd ..
$ capstone/stage-07-broken-pull-request/check.sh
Checking capstone stage 7
  ok    the server still has the branch feature/vip-escalation
  ok    "Add the VIP customer list" is on the branch exactly once
  ok    "Escalate VIP messages that would fall back" is on the branch exactly once
  ok    "Test the VIP escalation" is on the branch exactly once
  ok    "Document the VIP escalation" is on the branch exactly once
  ok    "Escalate VIP messages without any intent as well" is on the branch exactly once
  ok    the branch has five commits that main does not have
  ok    the branch contains no merge commit
  ok    the branch is based on the current main
  ok    the test suite passes on the branch
  ok    the review commit of the tech lead is in the README
  ok    the change that was only in your clone is in the file
  ok    pull request #22 is open
  ok    the branch in you/ equals the branch on the server
  ok    no rebase, merge or cherry-pick is left in progress in you/
  ok    the branch in nandini/ equals the branch on the server
  ok    no rebase, merge or cherry-pick is left in progress in nandini/
  ok    the branch in kabir/ equals the branch on the server
  ok    no rebase, merge or cherry-pick is left in progress in kabir/
PASS: the Git state of stage 7 is as required. The written deliverables are judged separately.
[exit status: 0]
```
<!-- /snippet -->

`push.useForceIfIncludes=true` makes every `--force-with-lease` also require that the remote-tracking tip was once part of the local branch: his push would have been refused. `pull.ff=only` makes a pull stop when the upstream was rewritten, so that a person decides. Both are client defaults (strength 3 on the ladder of section 30.20) and belong in the team's onboarding configuration. And the agreement that was in the conventions all along: whoever rewrites a shared branch announces it first, with the old tip.

**Root cause.**

```text
Observed behavior : the pull request lists seven commits for five changes, with a merge by the reviewer
Git state         : the tip is a merge of the old series (plus one review commit) with the rebased series;
                    one pushed commit is not an ancestor of the rebased tip
Mechanism         : rebase of a stale local branch; --force-with-lease satisfied by a fresh fetch;
                    pull with pull.rebase=false merged old and new
Root cause        : a shared branch was rewritten from a local branch that did not contain the server's tip,
                    with a safety option that checks what was fetched, not what was integrated
Why Git does this : a lease compares refs; only --force-if-includes compares against the local reflog
Correct fix       : keep the rebased series, replay the later commits onto it, publish with an explicit lease
Prevention        : push.useForceIfIncludes; pull.ff=only; announce rewrites of shared branches
```

Layer: Git and two configuration defaults. GitHub displayed the result faithfully.

**Verification.** The check at the end of the last transcript: five commits, once each, no merge, based on the current `main`, tests passing, three clones equal to the server, the pull request open. **Not verified here:** how GitHub shows earlier review comments after the forced push, and whether an approval was dismissed.

**Communication.** Before the push:

```text
feature/vip-escalation: please do not pull, push or rebase it for the next 20 minutes. I am rebuilding it.
Nothing is lost. I will post the exact command for each of you.
```

After:

```text
feature/vip-escalation is rebuilt: five commits, once each, on today's main. No content changed
(tree identical to the old tip plus my new commit), so the review of the diff stands.
Nandini: git fetch && git reset --keep origin/feature/vip-escalation   (do not pull: it would merge again)
Kabir:   git pull --ff-only
What happened, without blame: the rebase was pushed with a lease right after a fetch, so the lease held
although the rebased branch did not contain my tests commit; then a pull merged old and new.
Two settings prevent both halves: push.useForceIfIncludes=true and pull.ff=only. I have set them in
our three clones; please keep them.
```

To the CTO:

```text
Subject: [Resolved] intent-router: a pull request became unreviewable after a history rewrite (SEV 3, no customer impact)

What happened   A shared feature branch was rewritten while it contained a commit the rewrite did not
                include. For about an hour the pull request listed every change twice and review stopped.
                No code was lost and nothing reached main.
Root cause      Git's safety option for overwriting a branch checks that you have seen the server's latest
                state, not that your work contains it. A second default then merged the old and the new
                version of the branch. Both are Git client settings.
What was done   The branch was rebuilt with every change once. Verified: identical content, tests pass,
                all three developers' copies match the server. Not yet verified: how the earlier review
                comments appear on GitHub.
Prevention      Two client settings, now part of the team's standard configuration. Owner: tech lead.
```

**Postmortem.** The sentence "a lease cannot overwrite anybody's work" was believed by the person who typed it, and it is what most handbooks say. The postmortem's subject is that sentence.

---

## Stage 8: a production hotfix from a release tag, with a backport

**Symptoms.** Production (`v1.3.1`) answers 2.1% of requests with HTTP 500 since 09:42: a `TypeError` in `classify` when a candidate's embedding score is `None`. The provider is timing out. The engineer on call has a fix on a branch from `main` and proposes to tag `main` as `v1.3.2`. The CTO asks whether a rollback is faster and what 1.3.2 would contain.

**Evidence.**

<!-- snippet: capstone/stage-08-hotfix-and-backport/01-observe -->
```text
$ cd you
$ git switch main
Switched to branch 'main'
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)
$ git pull --ff-only --prune
From ../server
 - [deleted]         (none)            -> origin/feature/vip-escalation
   52620f1..c99b5eb  main              -> origin/main
 * [new branch]      hotfix/embed-none -> origin/hotfix/embed-none
Updating 2fe3b1c..c99b5eb
Fast-forward
 .github/workflows/ci.yml |  2 +-
 README.md                |  4 ++++
 router/vip.py            | 14 ++++++++++++++
 tests/test_vip.py        | 17 +++++++++++++++++
 4 files changed, 36 insertions(+), 1 deletion(-)
 create mode 100644 router/vip.py
 create mode 100644 tests/test_vip.py
$ git describe origin/main
v1.3.1-16-gc99b5eb
$ git log --oneline --first-parent v1.3.1..origin/main
c99b5eb Merge pull request #22 from feature/vip-escalation
52620f1 Give the CI job 15 minutes (#23)
2fe3b1c Merge pull request #20 from feature/multilingual-intents
1876f06 Document the batch entry point (#19)
1b63d64 Add batch classification (#17)
3c4f762 Make the fallback intent configurable per tenant (#18)
d71e996 Add the embedding service client (#16)
e3e624d Halve the score when keyword and embedding disagree (#12)
95f8c85 Add per-tenant embedding weights (#13)
$ ../pr list
#21  open    clean     feature/multilingual-intents -> main   Hindi and Tamil intents
#24  open    clean     hotfix/embed-none -> main   Treat a missing embedding score as 0
```
<!-- /snippet -->

`git describe origin/main` answers the CTO's second question in one line: `main` is 16 commits past `v1.3.1` ([Chapter 14B](../textbook/ch14b-config-tags-signing.md), section 14B.12). Nine pull requests, among them the two she named.

**Hypotheses.**

| # | Hypothesis | Prediction | Separating command |
|---|---|---|---|
| H1 | A recent release introduced the fault; a rollback removes it | The sample works on `v1.3.0` | Run it on both tags |
| H2 | The fault has always been in the code; an input changed | The line is attributed to the first commit; the sample fails on every tag | `git blame`, the same sample |
| H3 | The fix for `main` can be released as it is, from `main` | `v1.3.1..main` contains nothing unreleased that matters | `git diff --stat v1.3.1 origin/main` |

**Diagnostic commands.**

<!-- snippet: capstone/stage-08-hotfix-and-backport/02-reproduce -->
```text
# Production runs v1.3.1. The failing input from the alert, on that tag:
$ git switch --quiet --detach v1.3.1
$ PYTHONPATH=. python3 -B -c 'from router.classify import classify; print(classify([("billing_refund", 1.0, None)]))' 2>&1 | tail -n 1
TypeError: unsupported operand type(s) for *: 'float' and 'NoneType'
# Would a rollback to v1.3.0 help? Is this a regression at all?
$ git switch --quiet --detach v1.3.0
$ PYTHONPATH=. python3 -B -c 'from router.classify import classify; print(classify([("billing_refund", 1.0, None)]))' 2>&1 | tail -n 1
TypeError: unsupported operand type(s) for *: 'float' and 'NoneType'
$ git blame -s -L '/for intent, kw, emb/,+1' v1.3.1 -- router/classify.py
^f84d4a2 12)     for intent, kw, emb in candidates:
$ git log --oneline v1.0.0..v1.3.1 -- router/classify.py
1cf6842 Route unknown intents to a human agent (#5)
$ git switch --quiet main
```
<!-- /snippet -->

The same `TypeError` on `v1.3.1` and on `v1.3.0`. The loop line is attributed to the root commit (the `^` marks a boundary commit), and the file changed once between `v1.0.0` and `v1.3.1`, for an unrelated reason. H1 is refuted and H2 confirmed: this is not a regression, there is no commit to revert, and a rollback changes nothing. That is the answer to the CTO's first question.

<!-- snippet: capstone/stage-08-hotfix-and-backport/03-why-not-main -->
```text
# The proposal is to merge the fix and tag main. What would that release?
$ git diff --shortstat v1.3.1 origin/main
 15 files changed, 149 insertions(+), 9 deletions(-)
$ git diff --stat v1.3.1 origin/main -- router | tail -n 12
 router/batch.py        | 10 ++++++++++
 router/classify.py     | 14 ++++++++++----
 router/embed_cache.py  | 13 +++++++++++++
 router/embed_client.py | 20 ++++++++++++++++++++
 router/lang.py         |  8 ++++++++
 router/scoring.py      | 10 ++++++++--
 router/vip.py          | 14 ++++++++++++++
 7 files changed, 83 insertions(+), 6 deletions(-)
```
<!-- /snippet -->

H3 is refuted: tagging `main` would ship fifteen changed files, including per-tenant weights, the VIP escalation, the batch entry point and an embedding client, none of them signed off.

**Root cause.**

```text
Observed behavior : classify raises TypeError for a candidate without an embedding score; 2.1% of requests fail
Git state         : v1.3.1 has "score = blend(kw, emb)" with no guard, unchanged since the first commit;
                    main is 16 commits ahead of v1.3.1 with unreleased features
Mechanism         : the embedding provider times out; the caller passes None; arithmetic on None raises
Root cause        : an unhandled input that became frequent through a change outside the repository
Why Git does this : not a Git fault. Git's part is the question "what exactly will the fix be released with"
Correct fix       : fix on main; copy the fix to a maintenance line cut at v1.3.1; tag v1.3.2 there
Prevention        : a test for the missing score (in the fix); a maintenance line per supported release
```

Layer: the product code, and a release process that had no place for a patch once `main` had moved.

**Safe recovery.**

| Option | Result | Verdict |
|---|---|---|
| Roll back to `v1.3.0` | Same fault, and the stage 1 fault returns | Rejected by evidence |
| Merge the fix and tag `main` as `v1.3.2` | Ships nine unreleased pull requests under a patch number | Rejected |
| Commit the fix on a release branch only | Fast; the fix is missing from `main` until someone remembers, and 1.4.0 regresses | Rejected: the failure the team's rule exists for ([Chapter 27](../textbook/ch27-open-source-team-workflows.md), section 27.10) |
| Fix on `main` through its pull request, then `cherry-pick -x` to `release/1.3` cut at `v1.3.1` | `v1.3.2` = `v1.3.1` plus the fix; the copy names its original | Chosen |

The first half is a review. The fix is small and right for `main`:

<!-- snippet: capstone/stage-08-hotfix-and-backport/04-review-the-fix -->
```text
$ ../pr view 24
#24 Treat a missing embedding score as 0
state: open   hotfix/embed-none -> main   author: Tanvi Desai
merge check: clean
Commits:
  148f631 Tanvi Desai: Treat a missing embedding score as 0
Files changed:
 router/classify.py     | 2 ++
 tests/test_classify.py | 4 ++++
 2 files changed, 6 insertions(+)
$ git diff origin/main...origin/hotfix/embed-none -- router
diff --git a/router/classify.py b/router/classify.py
index ed5a180..eae5037 100644
--- a/router/classify.py
+++ b/router/classify.py
@@ -16,6 +16,8 @@ def classify(candidates, tenant=None):
     """candidates: (intent, keyword_score, embed_score) tuples. Returns the intent to route to."""
     best, best_score = fallback_for(tenant), THRESHOLD
     for intent, kw, emb in candidates:
+        if emb is None:
+            emb = 0.0  # the embedding service timed out: decide on the keywords alone
         score = blend(kw, emb, tenant)
         if score > best_score:
             best, best_score = intent, score
$ git switch --quiet --detach origin/hotfix/embed-none
$ bash scripts/test.sh
OK
$ PYTHONPATH=. python3 -B -c 'from router.classify import classify; print(classify([("billing_refund", 1.0, None)]))' 2>&1 | tail -n 1
human_agent
$ git switch --quiet main
```
<!-- /snippet -->

<!-- snippet: capstone/stage-08-hotfix-and-backport/05-fix-on-main -->
```text
$ ../pr merge 24 --squash
Merged pull request #24 into main as b360489 (squash). Deleted the branch hotfix/embed-none on the server.
$ git pull --ff-only
From ../server
   c99b5eb..b360489  main       -> origin/main
Updating c99b5eb..b360489
Fast-forward
 router/classify.py     | 2 ++
 tests/test_classify.py | 4 ++++
 2 files changed, 6 insertions(+)
$ git log --oneline -1
b360489 Treat a missing embedding score as 0 (#24)
```
<!-- /snippet -->

The maintenance line starts at the tag that production runs, and the backport is prepared on a branch of its own so that it goes through a pull request:

<!-- snippet: capstone/stage-08-hotfix-and-backport/06-release-branch -->
```text
# The maintenance line starts at the tag that production runs.
$ git switch -c release/1.3 v1.3.1
Switched to a new branch 'release/1.3'
$ git push -u origin release/1.3
To ../server.git
 * [new branch]      release/1.3 -> release/1.3
branch 'release/1.3' set up to track 'origin/release/1.3'.
$ git switch -c backport/embed-none-1.3
Switched to a new branch 'backport/embed-none-1.3'
$ git cherry-pick -x b360489
Auto-merging router/classify.py
CONFLICT (content): Merge conflict in router/classify.py
Auto-merging tests/test_classify.py
CONFLICT (content): Merge conflict in tests/test_classify.py
error: could not apply b360489... Treat a missing embedding score as 0 (#24)
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
$ git status -sb
## backport/embed-none-1.3
UU router/classify.py
UU tests/test_classify.py
```
<!-- /snippet -->

The cherry-pick stops with conflicts in both files. The fix was written against a `classify` that has a `tenant` parameter; the release does not have one.

<!-- snippet: capstone/stage-08-hotfix-and-backport/07-conflict -->
```text
$ git diff router/classify.py
diff --cc router/classify.py
index 4bb5074,eae5037..0000000
--- a/router/classify.py
+++ b/router/classify.py
@@@ -3,14 -3,22 +3,20 @@@
  from router.scoring import blend
  
  THRESHOLD = 0.55
 -DEFAULT_FALLBACK = "human_agent"
 -TENANT_FALLBACK = {"acme-retail": "store_support"}
 +FALLBACK = "human_agent"
  
  
 -def fallback_for(tenant=None):
 -    """The intent a message gets when no candidate is good enough."""
 -    return TENANT_FALLBACK.get(tenant, DEFAULT_FALLBACK)
 -
 -
 -def classify(candidates, tenant=None):
 +def classify(candidates):
      """candidates: (intent, keyword_score, embed_score) tuples. Returns the intent to route to."""
 -    best, best_score = fallback_for(tenant), THRESHOLD
 +    best, best_score = FALLBACK, THRESHOLD
      for intent, kw, emb in candidates:
++<<<<<<< HEAD
 +        score = blend(kw, emb)
++=======
+         if emb is None:
+             emb = 0.0  # the embedding service timed out: decide on the keywords alone
+         score = blend(kw, emb, tenant)
++>>>>>>> b360489 (Treat a missing embedding score as 0 (#24))
          if score > best_score:
              best, best_score = intent, score
      return best
```
<!-- /snippet -->

In the combined diff, everything outside the markers that carries a `-` in the first column is `main`'s side that the release does not have and must not get. Inside the markers: the release's call, and the fix with the call as `main` has it. Taking "theirs" would call `blend(kw, emb, tenant)` in a function with no `tenant`: the backport would apply and the release would fail with a `NameError` on the first request ([Chapter 10](../textbook/ch10-cherry-pick.md), section 10.12). The resolution takes the two guard lines and keeps the release's call.

<!-- snippet: capstone/stage-08-hotfix-and-backport/08-resolve -->
```text
# (edit router/classify.py: the guard from the fix, the call as the release has it)
# (edit tests/test_classify.py: the new test only; the tenant test belongs to main)
$ git diff
diff --cc router/classify.py
index 4bb5074,eae5037..0000000
--- a/router/classify.py
+++ b/router/classify.py
@@@ -3,14 -3,22 +3,16 @@@
  from router.scoring import blend
  
  THRESHOLD = 0.55
 -DEFAULT_FALLBACK = "human_agent"
 -TENANT_FALLBACK = {"acme-retail": "store_support"}
 +FALLBACK = "human_agent"
  
  
 -def fallback_for(tenant=None):
 -    """The intent a message gets when no candidate is good enough."""
 -    return TENANT_FALLBACK.get(tenant, DEFAULT_FALLBACK)
 -
 -
 -def classify(candidates, tenant=None):
 +def classify(candidates):
      """candidates: (intent, keyword_score, embed_score) tuples. Returns the intent to route to."""
 -    best, best_score = fallback_for(tenant), THRESHOLD
 +    best, best_score = FALLBACK, THRESHOLD
      for intent, kw, emb in candidates:
+         if emb is None:
+             emb = 0.0  # the embedding service timed out: decide on the keywords alone
 -        score = blend(kw, emb, tenant)
 +        score = blend(kw, emb)
          if score > best_score:
              best, best_score = intent, score
      return best
diff --cc tests/test_classify.py
index 46ab2fd,df4d3e1..0000000
--- a/tests/test_classify.py
+++ b/tests/test_classify.py
@@@ -9,4 -9,12 +9,8 @@@ class ClassifyTest(unittest.TestCase)
          self.assertEqual(classify(candidates), "billing_refund")
  
      def test_weak_evidence_goes_to_a_human(self):
 -        self.assertEqual(classify([("billing_refund", 0.2, 0.1)]), "human_agent")
 -
 -    def test_a_tenant_can_have_its_own_fallback(self):
 -        self.assertEqual(fallback_for("acme-retail"), "store_support")
 -        self.assertEqual(classify([("billing_refund", 0.2, 0.1)], "acme-retail"), "store_support")
 +        self.assertEqual(classify([("billing_refund", 0.2, 0.1)]), FALLBACK)
+ 
+     def test_a_missing_embedding_score_counts_as_zero(self):
+         self.assertEqual(classify([("billing_refund", 1.0, None)]), "human_agent")
+         self.assertEqual(classify([("billing_refund", 1.0, None), ("order_status", 0.8, 0.9)]), "order_status")
```
<!-- /snippet -->

The test file is the second trap. The fix appended its test after a test of `main` that uses `fallback_for`, which the release does not have. The resolution keeps the release's tests and adds the new one only.

<!-- snippet: capstone/stage-08-hotfix-and-backport/09-conclude -->
```text
$ bash scripts/test.sh
OK
$ git add router/classify.py tests/test_classify.py
$ git -c core.editor=true cherry-pick --continue
[backport/embed-none-1.3 6e291e5] Treat a missing embedding score as 0 (#24)
 Author: Tanvi Desai <tanvi@example.com>
 Date: Wed Sep 23 10:32:00 2026 +0530
 2 files changed, 6 insertions(+)
$ git show --stat --format=%B HEAD
Treat a missing embedding score as 0 (#24)

(cherry picked from commit b3604896a20d1db6d1ed9f4d4dc90a418c0673b5)


 router/classify.py     | 2 ++
 tests/test_classify.py | 4 ++++
 2 files changed, 6 insertions(+)
```
<!-- /snippet -->

The tests are run on the release branch before the pick is concluded: "applied" and "works there" are different statements. `-x` appended the line that names the original commit; the author is still the person who wrote the fix. In `labs/shell`, `git cherry-pick --continue` opens the editor with the message; save it unchanged.

<!-- snippet: capstone/stage-08-hotfix-and-backport/10-compare -->
```text
# The backport next to the original. By default range-diff does not pair two commits
# whose diffs differ this much; --creation-factor=100 makes it pair them and show how.
$ git range-diff b360489~1..b360489 HEAD~1..HEAD
1:  b360489 < -:  ------- Treat a missing embedding score as 0 (#24)
-:  ------- > 1:  6e291e5 Treat a missing embedding score as 0 (#24)
$ git range-diff --creation-factor=100 b360489~1..b360489 HEAD~1..HEAD
1:  b360489 ! 1:  6e291e5 Treat a missing embedding score as 0 (#24)
    @@ Metadata
      ## Commit message ##
         Treat a missing embedding score as 0 (#24)
     
    +    (cherry picked from commit b3604896a20d1db6d1ed9f4d4dc90a418c0673b5)
    +
      ## router/classify.py ##
    -@@ router/classify.py: def classify(candidates, tenant=None):
    +@@ router/classify.py: def classify(candidates):
          """candidates: (intent, keyword_score, embed_score) tuples. Returns the intent to route to."""
    -     best, best_score = fallback_for(tenant), THRESHOLD
    +     best, best_score = FALLBACK, THRESHOLD
          for intent, kw, emb in candidates:
     +        if emb is None:
     +            emb = 0.0  # the embedding service timed out: decide on the keywords alone
    -         score = blend(kw, emb, tenant)
    +         score = blend(kw, emb)
              if score > best_score:
                  best, best_score = intent, score
     
      ## tests/test_classify.py ##
     @@ tests/test_classify.py: class ClassifyTest(unittest.TestCase):
    -     def test_a_tenant_can_have_its_own_fallback(self):
    -         self.assertEqual(fallback_for("acme-retail"), "store_support")
    -         self.assertEqual(classify([("billing_refund", 0.2, 0.1)], "acme-retail"), "store_support")
    + 
    +     def test_weak_evidence_goes_to_a_human(self):
    +         self.assertEqual(classify([("billing_refund", 0.2, 0.1)]), FALLBACK)
     +
     +    def test_a_missing_embedding_score_counts_as_zero(self):
     +        self.assertEqual(classify([("billing_refund", 1.0, None)]), "human_agent")
```
<!-- /snippet -->

By default `range-diff` does not pair the two commits: their diffs differ too much in context. With `--creation-factor=100` it pairs them and shows the adaptation line by line: the same two added lines, a different call, a different neighbouring test. This is the review of a backport: not "did it apply" but "what is different from the original, and is each difference intended".

<!-- snippet: capstone/stage-08-hotfix-and-backport/11-publish -->
```text
$ git push -u origin backport/embed-none-1.3
To ../server.git
 * [new branch]      backport/embed-none-1.3 -> backport/embed-none-1.3
branch 'backport/embed-none-1.3' set up to track 'origin/backport/embed-none-1.3'.
$ ../pr open backport/embed-none-1.3 --base release/1.3
Opened pull request #25: Treat a missing embedding score as 0 (#24) (backport/embed-none-1.3 -> release/1.3)
$ ../pr view 25
#25 Treat a missing embedding score as 0 (#24)
state: open   backport/embed-none-1.3 -> release/1.3   author: Tanvi Desai
merge check: clean
Commits:
  6e291e5 Tanvi Desai: Treat a missing embedding score as 0 (#24)
Files changed:
 router/classify.py     | 2 ++
 tests/test_classify.py | 4 ++++
 2 files changed, 6 insertions(+)
$ ../pr merge 25 --squash
Merged pull request #25 into release/1.3 as 36e9769 (squash). Deleted the branch backport/embed-none-1.3 on the server.
$ git switch release/1.3
Switched to branch 'release/1.3'
Your branch is up to date with 'origin/release/1.3'.
$ git pull --ff-only
From ../server
   47fb459..36e9769  release/1.3 -> origin/release/1.3
Updating 47fb459..36e9769
Fast-forward
 router/classify.py     | 2 ++
 tests/test_classify.py | 4 ++++
 2 files changed, 6 insertions(+)
$ git log -1 --format=%B
Treat a missing embedding score as 0 (#24) (#25)

(cherry picked from commit b3604896a20d1db6d1ed9f4d4dc90a418c0673b5)
```
<!-- /snippet -->

The squash merge of a one-commit pull request keeps the commit's message, so the `(cherry picked from commit ...)` line is on `release/1.3`. The head branch `backport/embed-none-1.3` was deleted by the merge; `release/1.3` is a base branch and stays.

<!-- snippet: capstone/stage-08-hotfix-and-backport/12-tag -->
```text
$ bash scripts/test.sh
OK
$ PYTHONPATH=. python3 -B -c 'from router.classify import classify; print(classify([("billing_refund", 1.0, None)]))' 2>&1 | tail -n 1
human_agent
$ git tag -a v1.3.2 -m 'intent-router 1.3.2: treat a missing embedding score as 0'
$ git push origin v1.3.2
To ../server.git
 * [new tag]         v1.3.2 -> v1.3.2
$ git describe
v1.3.2
$ git log --oneline --graph --decorate --simplify-by-decoration v1.3.0..v1.3.2 origin/main -6
* 36e9769 (HEAD -> release/1.3, tag: v1.3.2, origin/release/1.3) Treat a missing embedding score as 0 (#24) (#25)
| * b360489 (origin/main, origin/HEAD, main) Treat a missing embedding score as 0 (#24)
| * 66dc07e (feature/vip-escalation) Document the VIP escalation
|/  
* 47fb459 (tag: v1.3.1) Merge pull request #15 from fix/keyword-score-cap
```
<!-- /snippet -->

An annotated tag on the release branch, as the release workflow requires. The graph shows the two lines: `v1.3.2` one commit after `v1.3.1`, and `main` on its own path.

**Verification.**

<!-- snippet: capstone/stage-08-hotfix-and-backport/13-verify -->
```text
$ git diff --stat v1.3.1 v1.3.2
 router/classify.py     | 2 ++
 tests/test_classify.py | 4 ++++
 2 files changed, 6 insertions(+)
# Is the fix of the release also on main? Patch comparison says no, because the copy was
# adapted. The line that -x wrote says yes.
$ git cherry -v origin/main release/1.3
+ 36e9769dfdd6439d7fd9edc3af6460b377aadba7 Treat a missing embedding score as 0 (#24) (#25)
$ git log -1 --format=%B release/1.3 | grep 'cherry picked'
(cherry picked from commit b3604896a20d1db6d1ed9f4d4dc90a418c0673b5)
$ git merge-base --is-ancestor b3604896a20d1db6d1ed9f4d4dc90a418c0673b5 origin/main
[exit status: 0]
$ git tag --contains b3604896a20d1db6d1ed9f4d4dc90a418c0673b5
$ git tag --contains release/1.3
v1.3.2
```
<!-- /snippet -->

`git diff --stat v1.3.1 v1.3.2` is the answer to "what exactly will 1.3.2 contain": two files, six added lines. The audit question, "is the fix of the release also on `main`", has three answers of different reliability ([Chapter 10](../textbook/ch10-cherry-pick.md), sections 10.9 and 10.10). `git cherry` compares patches and prints `+`, "not on `main`", which is wrong here because the copy was adapted. The `-x` line names the original, and `git merge-base --is-ancestor` confirms that the original is on `main`. And `git tag --contains` shows that no tag contains the original yet: it will ship with 1.4.0. **Not verified here:** that the release workflow built `v1.3.2` (it triggers on the tag; CI on `release/**` is configured in `ci.yml`), that production runs it, and that the error rate fell.

<!-- snippet: capstone/stage-08-hotfix-and-backport/14-cleanup -->
```text
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git branch -D backport/embed-none-1.3
Deleted branch backport/embed-none-1.3 (was 6e291e5).
$ git fetch --prune
From ../server
 - [deleted]         (none)     -> origin/backport/embed-none-1.3
 - [deleted]         (none)     -> origin/hotfix/embed-none
$ git branch -vv
  feature/vip-escalation 66dc07e [origin/feature/vip-escalation: gone] Document the VIP escalation
* main                   b360489 [origin/main] Treat a missing embedding score as 0 (#24)
  release/1.3            36e9769 [origin/release/1.3] Treat a missing embedding score as 0 (#24) (#25)
$ cd ..
$ capstone/stage-08-hotfix-and-backport/check.sh
Checking capstone stage 8
  ok    main was not rewritten
  ok    on main a message without an embedding score is classified, not an error
  ok    the test suite passes on main
  ok    everything on main since v1.3.1 arrived through a pull request
  ok    the tag v1.3.2 exists on the server
  ok    v1.3.2 is an annotated tag
  ok    v1.3.2 is built on v1.3.1
  ok    in v1.3.2 a message without an embedding score is classified, not an error
  ok    the test suite passes on v1.3.2
  ok    v1.3.2 differs from v1.3.1 only in router/classify.py and the tests
  ok    v1.3.2 contains none of the work that is on main and not released
  ok    the server has the branch release/1.3
  ok    release/1.3 contains v1.3.2
  ok    the fix in v1.3.2 names the commit on main that it was copied from
  ok    no cherry-pick, merge or rebase is left in progress in you/
PASS: the Git state of stage 8 is as required. The written deliverables are judged separately.
[exit status: 0]
```
<!-- /snippet -->

**Prevention.** The fix carries its test on both lines. For the process: cut `release/X.Y` when `X.Y.0` is tagged, not when the first patch is needed, and let a ruleset protect `release/**` like `main` ([Chapter 18](../textbook/ch18-branch-protection.md), section 18.18). A check in the release checklist: `git log --oneline vX.Y.(Z-1)..vX.Y.Z` must list only backports, each with a `cherry picked from` line whose commit is an ancestor of `main`. And for the product: the caller's contract ("the embedding score may be `None`") written down where the function is.

**Communication.** To the team:

```text
v1.3.2 is tagged on the new branch release/1.3 and ready to deploy. It is v1.3.1 plus one change:
a missing embedding score counts as 0 (git diff --stat v1.3.1 v1.3.2: 2 files, 6 lines).
The fix is on main as #24 and on release/1.3 as #25, a cherry-pick with -x. It needed adapting:
release/1.3 has no tenant parameter. Tanvi, thank you for the fix and the test; main is not tagged
because it is 16 commits ahead of production.
Not a regression: the line dates from the first commit, and v1.3.0 fails the same way.
release/1.3 now exists for further patches. Fixes go to main first, then cherry-pick -x.
```

To the CTO, answering her two questions first:

```text
Subject: [Fix ready] intent-router: 2.1% of requests failing since 09:42 IST (SEV 2, customer-facing)

Your questions  1. Nothing changed in our code. The fault has been present since the first version; it
                   shows now because the embedding provider began to time out. A rollback to 1.3.0 would
                   fail the same way.
                2. Release 1.3.2 is 1.3.1 plus one two-line fix and its test. It does not contain the
                   tenant weights, the VIP escalation or anything else that is unreleased.
What happened   Since 09:42 IST, requests whose embedding lookup timed out returned an error instead of
                being routed. About 2.1% of requests.
Root cause      Our code did not handle a missing embedding score. A defect in our code, exposed by an
                external change.
What was done   The fix is merged on main and copied to a new maintenance line for 1.3. Verified: the
                failing input is routed correctly in 1.3.2 and all tests pass on the tag. Not yet
                verified: the error rate after deployment.
Prevention      The fix includes a test. A maintenance line now exists for the released version, so the
                next patch does not depend on the state of main. Owner: tech lead.
```

SEV 2: customer-facing errors, bounded, nothing unrecoverable.

**Postmortem.** The fix took minutes. Everything else in this stage was the question of what to release it with, and that question had no prepared answer because the team had never needed a second line.

---

## 9. The model postmortem (stage 3)

```markdown
# Postmortem: staging credential committed to a feature branch      Severity: SEV 1 (lowered to SEV 3 after rotation)      Status: reviewed

## Summary
On 16 September a file containing the token of the staging embedding service was committed and pushed to
a feature branch of intent-router. The cause is in our repository setup: environment files under deploy/
were not excluded from version control (Git layer), and nothing on the client or the server checks for
them. The token was revoked and replaced, the affected histories were rewritten, and the data was removed
from the server and the four known clones. An ignore rule now exists; short-lived tokens are proposed.

## Impact
Readers of the private repository could read a staging token from 10:07 IST until its revocation.
The token gives access to the staging embedding service: no customer data, no production system.
What could have happened in the window: use of the staging service at our cost; nothing beyond it.
Engineering time: about two hours for one engineer, and one interruption each for three others.

## Timeline (IST, 16 September 2026)
| Time | Event | Source |
|---|---|---|
| 10:05 | The file is committed with the first commit of the branch | Author date of the commit |
| 10:07 | First push: the server has the file | Reflog of the remote-tracking branch in the pushing clone |
| between | A second branch is started from the pushed commits; staging is deployed and tagged | Commit dates; the tag |
| 10:22 | Second push, including a commit that deletes the file | Same reflog |
| about 10:40 | The author reports it to a colleague | The message (time inferred from the briefing) |
| after | Token revoked; first message to the team | Provider console; channel (not verifiable from Git) |
| after | Branches rewritten; tag moved; server pruned; clones cleaned | Push output; check result |

## Detection
By the author, by reading his own commit, about fifteen minutes after the first push. No automated check
would have detected it: the token has no recognisable format.

## Root cause
Observed behavior : a credential file is readable in pushed history although the branch tip lacks it
Git state         : one commit adds deploy/staging.env; five server refs and several clone refs reach it
Mechanism         : commits are snapshots; a deletion adds a snapshot and removes none
Root cause        : environment files were not ignored and were staged together with code
Why Git does this : immutable history is the property that makes every other guarantee possible
Correct fix       : revoke; rewrite unmerged history; move the tag; prune server and clones
Prevention        : ignore rule; short-lived tokens; configuration from the secret store

## Contributing conditions
- The deployment kept its configuration in a file next to the code, with a real value in it.
- A whole directory was staged at once.
- The branch was built on and deployed within minutes, which multiplied the refs that reached the commit.
- "Delete it in the next commit" is what most people believe removes a file.

## Recovery
1. Revocation and replacement of the token at the provider (not Git).
2. Read-only assessment: every ref in five repositories that reached the commit; not in main, not in a release.
3. 🟡 Interactive rebase of the feature branch: file removed from the adding commit, ignore rule added,
   deleting commit dropped. Verified with range-diff.
4. 🔴 Forced push with lease and --force-if-includes. 🟡 Dependent branch transplanted with rebase --onto,
   then the same forced push. 🔴 Tag moved with a forced push that names the expected old value.
5. Server: unreachable objects pruned (on GitHub: a request to Support).
6. 🔴 In each clone: fetch --prune --force --tags, then reflog expiry and gc.
Verified: no ref in any of the five repositories reaches the file; the blob is in no object store.

## What went well
- It was reported by the person who did it, within the hour, without being asked.
- It never reached main, so no shared history was rewritten.
- The second refs (pull request, tag, dependent branch) were found before the rewrite, not after.

## What went badly
- A squash merge was proposed as a fix and would have hidden the problem.
- During the recovery the tag was nearly forgotten; it was found by asking the server for every ref
  that contains the commit, not by remembering it.
- Expiring reflogs in four clones removed everyone's local safety net; two days later a colleague
  assumed, wrongly, that this had made her own lost work unrecoverable.

## Actions
| Control | Type | Owner | Date | How we will know it works |
|---|---|---|---|---|
| Ignore rule deploy/*.env in the repository | prevent | ML team | done | git status --ignored lists the file |
| Staging tokens with a lifetime of hours | prevent | platform team | this sprint | a token from yesterday is rejected |
| Deployment configuration from the secret store, no env file | prevent | platform team | next sprint | deploy script has no file input |
| Push protection enabled; provider tokens in a recognised format where offered | detect | platform team | this sprint | a test push of a sample token is blocked |
| Runbook "secret in history": revoke first; list every ref with for-each-ref --contains | recover | tech lead | this week | used in the next drill |

## Evidence
Transcripts of stage 3 in this file; the reflog lines with the two push times; the output of the check.
```

Apply the test of section 30.19 to it: no name occurs, and every sentence still explains something that can be changed.

## 10. Across the eight stages

The closing page of the postmortem asks which few controls would have mattered most. One reading of the fortnight:

| Control | Layer | Stages it prevents or shortens | Cost |
|---|---|---|---|
| A ruleset on `main` and `release/**`: pull request required, required checks with "up to date", no force pushes, no deletions, no bypass for convenience | GitHub | 4 (the administrator merge is not available), 8 (a release line is protected from its first day); it keeps 1, 2 and 7 away from `main` | One extra CI run per pull request; an explicit path for emergencies |
| A standard client configuration: `pull.ff=only`, `push.useForceIfIncludes=true`, `fetch.prune=true`, `merge.conflictStyle=zdiff3`, a prompt that shows the branch | Git | 5, 6, 7 directly; 2 is easier to resolve correctly | A file in the onboarding repository; `fetch.prune` removes stale names that stage 6 happened to benefit from, which is an argument for the server-side rule, not against pruning |
| Push feature branches on the first day | Habit, supported by `push.autoSetupRemote` | 5 entirely; 6 partly | None |
| A release checklist: evaluate the candidate, read `git diff --stat <last tag>`, cut the maintenance line at the tag | Team process | 1, 8 | Fifteen minutes per release |

None of the eight incidents was caused by Git misbehaving. Three were Git doing exactly what a command said (stages 2, 5, 7), two were a stale or incomplete view of another repository (stages 6, 7), one was a platform default that tests more than the author did (stage 4), one was history being permanent (stage 3), and two were ordinary product defects whose handling depended on knowing the history (stages 1, 8). That distribution is typical, and it is why the course spent its time on mechanisms.

## 11. The end-to-end replay

`labs/capstone/end-to-end.sh` plays all eight stages in one sandbox: for each stage it applies the incident, runs the check (which must not pass), applies the model solution, and runs the check again.

<!-- snippet: capstone/end-to-end/02-stages -->
```text
stage 1  bug-in-production          check before the solution: NOT YET  after: PASS
stage 2  merge-conflict             check before the solution: NOT YET  after: PASS
stage 3  leaked-secret              check before the solution: NOT YET  after: PASS
stage 4  failed-ci                  check before the solution: NOT YET  after: PASS
stage 5  lost-work                  check before the solution: NOT YET  after: PASS
stage 6  deleted-branch             check before the solution: NOT YET  after: PASS
stage 7  broken-pull-request        check before the solution: NOT YET  after: PASS
stage 8  hotfix-and-backport        check before the solution: NOT YET  after: PASS
```
<!-- /snippet -->

The repository after the fortnight:

<!-- snippet: capstone/end-to-end/03-final-state -->
```text
$ cd you
$ git fetch --quiet --prune
$ git log --oneline --graph --first-parent --decorate v1.3.0..origin/main
* b360489 (HEAD -> main, origin/main, origin/HEAD) Treat a missing embedding score as 0 (#24)
* c99b5eb Merge pull request #22 from feature/vip-escalation
* 52620f1 Give the CI job 15 minutes (#23)
* 2fe3b1c Merge pull request #20 from feature/multilingual-intents
* 1876f06 Document the batch entry point (#19)
* 1b63d64 Add batch classification (#17)
* 3c4f762 Make the fallback intent configurable per tenant (#18)
* d71e996 Add the embedding service client (#16)
* e3e624d Halve the score when keyword and embedding disagree (#12)
* 95f8c85 Add per-tenant embedding weights (#13)
* 47fb459 (tag: v1.3.1) Merge pull request #15 from fix/keyword-score-cap
$ git log --oneline --decorate v1.3.1..origin/release/1.3
36e9769 (tag: v1.3.2, origin/release/1.3, release/1.3) Treat a missing embedding score as 0 (#24) (#25)
$ ../pr list --all | tail -n 12
#14  closed  -         fix/revert-embed-weight -> main   Revert "Raise the embedding weight to 0.8 (#11)"
#15  merged  -         fix/keyword-score-cap -> main   Restore the cap on the keyword score
#16  merged  -         feature/embedding-client -> main   Add the embedding service client
#17  merged  -         feature/batch-endpoint -> main   Add batch classification
#18  merged  -         feature/tenant-fallback -> main   Make the fallback intent configurable per tenant
#19  merged  -         docs/batch -> main   Document the batch entry point
#20  merged  -         feature/multilingual-intents -> main   Language detection groundwork
#21  open    clean     feature/multilingual-intents -> main   Hindi and Tamil intents
#22  merged  -         feature/vip-escalation -> main   Escalate VIP customers
#23  merged  -         chore/ci-timeout -> main   Give the CI job 15 minutes
#24  merged  -         hotfix/embed-none -> main   Treat a missing embedding score as 0
#25  merged  -         backport/embed-none-1.3 -> release/1.3   Treat a missing embedding score as 0 (#24)
$ git tag -n1
staging/2026-09-16 Cache embeddings by message hash
v1.0.0          intent-router 1.0.0
v1.1.0          intent-router 1.1.0
v1.2.0          intent-router 1.2.0
v1.3.0          intent-router 1.3.0
v1.3.1          intent-router 1.3.1: restore the cap on the keyword score
v1.3.2          intent-router 1.3.2: treat a missing embedding score as 0
```
<!-- /snippet -->

`main` has grown by one line per pull request since `v1.3.0`. `release/1.3` holds one commit beyond `v1.3.1`. One pull request, #21, is still open, waiting for its author to land.
