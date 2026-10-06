# Module 34 lab answers: the Level 8 design review

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Part 1 answers the "Questions" of [Lab 34.1](../lab-manual/m34-practices-design-review.md), which are about the evidence. Part 2 is for the assessor. Commit IDs, dates and counts are those of the replay script `labs/ch27/lab-34-1-design-review-evidence.sh`, and the setup script produces the same ones.

There is no model design in this file. A design is graded against the rubric in the lab manual, and the notes in Part 2 describe how to test a design, not what it must look like.

## Part 1: Answers to the questions about the evidence

1. **The four incidents and the measurements.**

   | Reported incident | Measurement | Proof or lead? |
   |---|---|---|
   | A fix shipped in a patch release is missing from the next minor release | step 3: `f1e338f` (`fix`, Ravi Menon, 2026-05-18) is on `release/2.0`, tagged `v2.0.1`, and has no patch-equivalent commit on `main`. `release/2.1` is 0 ahead of `main`, so it has nothing `main` lacks and therefore does not have the fix either | proof that the change is absent from `main` and from the 2.1 line as a patch; a lead as to why (no port step, no gate) |
   | A metric could not be reproduced from its commit | none. Nothing in the repository records a run. `models/` is ignored; no pointer, lock file or run record exists | a lead only: the absence of any recorded identifier. The cause must be established from the tracker or the people (Chapter 28, section 28.7 lists the candidates) |
   | An environment file in history | step 5: `a2b5f8b` (`wip`, 2026-03-03) added `.env`; it was removed a day later and is not in `git ls-files` | proof that it is in history. Whether its contents are live credentials, and whether they were rotated, is not in the repository |
   | A first clone "took forever" | step 5: one blob of 2,097,152 bytes, `models/risk-v1.ckpt`, added by `adc77d4` and later deleted from the tree | proof of the mechanism in the reduced repository (every clone downloads a deleted checkpoint). The size of the effect in the real repository is not measured here |

2. **`develop`: six ahead, two behind, merge base on 2026-05-04.** `develop` has six commits that `main` lacks, the newest dated 2026-08-17, and the two lines last shared a commit on 4 May: about three and a half months of work has not been integrated. The "two behind" says that `main` received commits directly in that time (the calibration squash and a README change), so `develop` is not the only way into `main`. The team has a second long-lived branch without the discipline that would give it a purpose. The numbers do not tell you how large the eventual merge conflict is, whether anything is deployed from `develop`, whether CI runs on it, or why it exists; a count of commits says nothing about their size.

3. **What the two results of step 3 prove.** For `release/2.0`: there is a commit reachable from the release branch and not from `main` for which no commit on `main`'s side introduces the same diff. For `release/2.1`: no such commit exists, and here that is trivially true because the branch has no commits of its own. An empty result can be wrong in at least two ways. The equivalent change may exist on `main` and have been reverted there later: the patch-equivalent commit is still found, the check stays silent, and the fix is absent from the current tree. And `--no-merges` hides changes that were made inside a merge commit's conflict resolution. (The opposite error also exists: a port that needed manual conflict resolution has a different patch ID and is reported as missing.)

4. **The 2 MiB blob.** It is in the commit that added it, `adc77d4`, and in every later commit up to the one that removed the file; those commits are ancestors of every branch and tag, so the blob is reachable from all of them. Every clone of the repository has a copy, and so does every fork and CI checkout that is not shallow. `.gitignore` now lists `models/`, which prevents the next accidental `git add` and does nothing about the blob in history. Removing it means rewriting history for every branch and tag, with the coordination that requires.

5. **Ten times `N`.** None of the ten commits on `main` carries a signature. That establishes nothing about who wrote them, in either direction: the author and committer fields are text that whoever made the commit could set freely. A `G` would establish that the commit object was signed with a key that the verifying machine trusts, so the holder of that key made, or at least signed, that exact content. It would still not establish that the key belongs to the named person unless somebody verified that, that the change was reviewed or is correct, or that the signer wrote the code and did not only commit it. [Chapter 14B](../textbook/ch14b-config-tags-signing.md) and Chapter 21B separate these claims.

6. **Two branches, one habit.** `feature/calibration` was squash-merged: its two commits were replaced on `main` by one new commit, `350f29e`, so ancestry says "unmerged" and content says "done". The branch was then left behind, which is how such branches accumulate. `feature/big-refactor` is nine commits on top of `v2.1.0` and has real open work. Under a squash habit it will land as one commit that contains nine refactoring steps, so the unit of review, of `revert` and of `bisect` becomes the whole refactoring ([Chapter 27](../textbook/ch27-open-source-team-workflows.md), section 27.15). It cannot be merged in parts and then continued on the same branch, because after a squash the branch's own commits are not ancestors of `main` (Chapter 17, section 17.12). And it edits `score/model.py`, the file the unported fix on `release/2.0` also edits, so porting the fix and finishing the refactoring will meet in that file.

7. **Questions no Git command answers.** Who approved a change: reviews and approvals are GitHub objects, in the pull request and the audit log. Which rules protect which branch and who can bypass them: the repository's and organization's rulesets and Rule Insights. What CI ran on which commit, with which credentials, on which runner: the Actions configuration and run history. Which model version produced a given score: the serving system's logs and the model registry. Which data a model was trained on: the data store and the run records. Which bank runs which version: deployment records and contracts. Whether the credentials in the old `.env` were rotated: the provider. An evidence table that says "not answerable from the repository; ask X" in these rows is stronger than one that guesses.

## Part 2: Notes for the assessor

Do not show this part to the candidate before the design is submitted.

### Reference values for the evidence part

The candidate's numbers must match these, because the repository is deterministic.

| Measurement | Value |
|---|---|
| Branches by last commit | `release/2.1` 2026-05-04 (0 ahead, 2 behind); `release/2.0` 2026-05-18 (1, 5); `feature/big-refactor` 2026-05-19 (9, 2); `feature/calibration` 2026-06-02 (2, 2); `develop` 2026-08-17 (6, 2); `main` 2026-08-24 |
| Tags | `v2.0.0` 2026-03-20, `v2.1.0` 2026-05-04, `v2.0.1` 2026-05-18 |
| Unported fix | `f1e338f` on `release/2.0` |
| `main` | 1 merge commit, 9 others; 8 first-parent entries |
| History content | blob of 2,097,152 bytes at `models/risk-v1.ckpt` (`adc77d4`); `.env` added by `a2b5f8b` |
| Short subjects | `add model`, `fix`, `initial`, `wip` |
| Signatures on `main` | none (10 times `N`) |
| Content test | `feature/calibration` is already on `main`; `develop`, `feature/big-refactor`, `release/2.0` are open work |

A candidate who reports `feature/calibration` as abandoned work has not done the failure scenario. A candidate who reports numbers that are not in this table invented them.

### How to read a design

Grade against the rubric, not against a design you would have written. Designs that pass differ in real ways: with or without a `develop` branch, with release branches cut at the tag or at a stabilization point, with fixes merged upward or picked down, with one repository or several. What they share is that each choice is derived from the brief and can be tested. Apply these tests to whatever the candidate submits.

1. **The bank test.** "Bank A runs 2.0 and needs one fix today. Show me the commands and the resulting graph." The design must produce a release that contains that fix and nothing else, and must say how the fix reaches every newer line. A design without a line for each supported version fails here, and that is an automatic failure in the rubric.
2. **The forgotten-port test.** "Which command, run by which job, on which event, fails if a fix is on a release line and not on `main`?" Accept either invariant of Chapter 27, section 27.10. Do not accept "the team will remember".
3. **The layer test.** For three controls of your choosing, ask where each is enforced and how it is bypassed. A control that lives in a local hook or a convention must be described as such. Ask what the AI agent's Git client does with the pre-commit configuration.
4. **The fork and runner test.** "A contractor's pull request changes a test file. Which secrets can that code reach, and on which machine does it run?" The shared GPU workstation registered as a runner is the planted hazard in the brief; a design that leaves it reachable from pull requests has not addressed it.
5. **The reproducibility test.** "In 2029 an auditor names a score from 2026. Walk from the score to the model version, to the commit, to the data, to the approval." Listen for dirty state, the data store's retention, and where the approval is recorded. "The commit ID" alone is the no-marks answer.
6. **The history test.** "What do you do about the environment file, in order?" Rotation comes first. Then ask what a history rewrite costs this company: two banks with pinned versions, tags, open branches, forks, contractors' clones.
7. **The evidence test.** "You propose shorter-lived branches. What supports that?" Accept: the DORA capability findings described as survey-based and correlational, expressed in branch lifetime and batch size, together with the candidate's own measurement of `develop`. Reject: "research proves trunk-based development is best", or any effect size.
8. **The plan test.** For every GitHub feature the design relies on, ask for its source and its plan requirement. The brief puts the company on the Team plan on purpose. The candidate should either cite the plan requirement from Chapter 18 or the documentation, or say that it must be checked. An invented plan gate is an automatic failure; "I do not know, and I would check the pricing and documentation pages" is a full answer.
9. **The migration test.** "It is week three; the hosted API needs a release today and half your rules are in place. What happens?" The plan must have an order in which each step leaves the system shippable.

### Objection bank

Raise objections one at a time and wait for the complete answer. A reasoned amendment scores as well as a defence. Probe once after each answer with "how would you know?" or "where is that enforced?".

| From | Objection | A strong response contains |
|---|---|---|
| Developer | "Three approvals and five required checks to fix a typo. I will stop making small pull requests." | a distinction between rules by path or risk; a time-to-first-review target; recognition that slow review is itself a named pitfall for small batches |
| Developer | "Why can I not push to `main`? I have done it for two years and nothing broke." | what "nothing broke" cannot show; the audit requirement in the brief; a bypass path that is logged, not a silent exception |
| Developer | "The hooks are enough. Everybody has them installed." | hooks are per clone and skippable; the agent and the web editor do not run them; the same checks in CI as required checks |
| Release manager | "Bank B needs the fix in two hours and your process takes a day." | an expedited path that still goes through review and checks, with what is shortened and what is never skipped; the port to the other lines as a tracked follow-up with a failing gate |
| Release manager | "Supporting two minor versions with release branches doubles our CI bill." | acknowledgment of the cost; which jobs run on release lines and which do not; when a line is retired |
| Release manager | "We tagged 2.2.0 on the wrong commit. I will move the tag." | why a published tag is not moved; a new patch version; what immutable releases add |
| Security reviewer | "The environment file was deleted in March. Why is this still open?" | deletion adds a commit; clones and forks keep the blob; rotate first; rewrite only if warranted |
| Security reviewer | "Your evaluation job has the provider key. A contractor opens a pull request." | fork and outside-contributor pull requests get no secrets; no `pull_request_target` with untrusted checkout; maintainer-triggered or post-merge evaluation; a dedicated, spend-capped key |
| Security reviewer | "The GPU box is a self-hosted runner on a repository that takes outside pull requests." | ephemeral or isolated runners, runner groups, approval for all outside contributors, or removal of the registration; no long-lived credentials on the host |
| Security reviewer | "You require signed commits. What does that prove?" | a key holder signed the object; it does not prove review or correctness; interaction with squash and rebase merges on GitHub, cited from Chapter 17 or flagged as needing a check |
| Auditor | "Show me who approved the change that put model 2026-Q3 into production." | where approvals live (pull request, audit log, Rule Insights); that this is platform data and not Git data; retention of that data for five years as an open question the candidate names |
| Auditor | "Your developers can approve their own work through a second account or the agent." | a rule that the most recent push must be approved by someone other than its author (Chapter 17, section 17.5); a stated position on automated approvals, with the candidate checking in the documentation whether they count toward a required review instead of asserting it; an honest statement of what the platform can and cannot enforce |
| Auditor | "The training data for 2026-Q1 was deleted from the bucket last month." | the pointer identifies and cannot restore; retention as part of the design; what can still be said about that model |
| CTO | "A colleague says DORA proves trunk-based development is best. Why are you keeping release branches?" | what the research measured and how; that it is about branch lifetime and batch size; that supported versions, not fashion, justify release lines |
| CTO | "What does this cost, and what do we stop doing?" | explicit non-goals; the price of extra CI, of a plan upgrade if one is proposed, of migration time; what is deferred |
| CTO | "How will I know in three months that it worked?" | measurable criteria tied to the brief: time from merge to deploy, age of the oldest unmerged branch, the port check passing on every release line, a reproduced model result, zero unreviewed changes on protected refs |

### Scoring the defence

The defence can move each rubric part up or down by a third of its points. Move a part up when the candidate defends with a mechanism or a source, or amends the design and states what the amendment costs. Move it down when the candidate changes the design without noticing what the change breaks, repeats a claim without support, or defends a control without being able to say where it is enforced. Record the objections that were not answered; they are the candidate's revision list for Level 9.

### Automatic failures in practice

The five automatic failures in the rubric are about habits that make an engineer unsafe in front of a CTO, not about gaps in knowledge. "I do not know whether the Team plan includes that; I would check" is never a failure. Asserting it without a source is. If a candidate states a GitHub fact that you cannot place, ask for the source before you grade it, and check it against the chapter that covers it.
