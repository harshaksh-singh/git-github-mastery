# Capstone evaluation

How the capstone is judged. The outcome is one of two statements: **demonstrates senior-level mastery**, or **not yet**. There is no grade in between, because the question the capstone answers has no in-between: would a CTO hand this person a repository incident and leave the room.

The evaluator is a reviewer who reads your deliverables next to the walkthrough, or you, a day after finishing, with the same documents. Self-evaluation works only if you score from what is on the page and not from what you remember meaning.

## 1. What is evaluated

Three sources, and nothing else.

| Source | What it shows |
|---|---|
| The eight `check.sh` results | That the required Git state was reached |
| The stage files ([`DELIVERABLES.md`](DELIVERABLES.md), seven items each) | How it was reached, and whether it was understood |
| The final postmortem | Whether the understanding carries to system level |

A passing check is the entry condition for scoring a stage, not a score. A stage whose check does not pass scores level 1 in every dimension it feeds.

## 2. The four-level scale

Every dimension is scored once per stage in which it applies, on this scale.

| Level | Name | Meaning |
|---|---|---|
| 1 | Not demonstrated | Absent, wrong, or arrived at without evidence |
| 2 | Developing | The right result with gaps: a step taken on a guess, a mechanism named and not shown, a risk not seen |
| 3 | Proficient | Correct, evidenced and safe. A senior colleague would accept the work without redoing it |
| 4 | Senior | Proficient, and in addition: the alternatives are weighed, the limits of the evidence are stated, the layer is named, and the result is turned into a control |

Level 3 is the standard. Level 4 is what distinguishes someone who can lead the incident from someone who can resolve it.

## 3. The seven dimensions

For each dimension: what it means, where the evidence is, and what each level looks like on the page. Score what you can point at.

### 3.1 Git knowledge

Correct use and correct explanation of Git's model: objects, refs, the three trees, reachability, reflogs, merge bases, ranges. Evidence: item 2 (root cause) of every stage; the commands in items 1 and 3.

| Level | Observable evidence |
|---|---|
| 1 | Commands copied without a stated purpose. Causes described as "Git lost it", "Git got confused". Branches treated as containers of commits |
| 2 | The right commands. The mechanism is named ("the branch was reset") and the state behind it is not shown. `A..B` and `A...B` used interchangeably. Recovery works and the write-up cannot say why the objects were still there |
| 3 | Every root-cause box states the Git state with refs and commit IDs from the log. Ranges are chosen deliberately. Reflog entries are read from the bottom up and quoted. The difference between a commit being unreachable and being gone is used correctly in stages 3, 5 and 6 |
| 4 | Level 3, and the write-up predicts before it runs: what a pull would do in stage 7, why a patch comparison misreports the backport in stage 8, why a squash merge would not remove the file in stage 3. Surprises in real output are noticed and explained |

### 3.2 GitHub knowledge

Knowing which behavior belongs to the platform, what the platform records, and what the sandbox could not show. Evidence: the "equivalent on GitHub" notes in item 3; item 5 (prevention); the "Not verified" lists.

| Level | Observable evidence |
|---|---|
| 1 | Git and GitHub are not distinguished. Prevention items name settings that do not exist |
| 2 | The pull request is understood as a branch comparison. Rules are proposed in general terms ("protect the branch") |
| 3 | The layer is labelled in every stage. Pull request refs and the test merge are used correctly in stages 4 and 6. Controls are named as the textbook names them (a ruleset that blocks force pushes and deletions, required status checks, push protection, CODEOWNERS review) with the chapter section |
| 4 | Level 3, and the limits are stated: what push protection would not have caught in stage 3, what Restore branch can and cannot restore in stage 6, what a re-run does and does not pick up in stage 4, which facts only the Activity view, the pull request timeline or the audit log could confirm. Plan gates and bypass paths are considered |

### 3.3 Debugging ability

The quality of the diagnosis: hypotheses, the commands that separate them, and the discipline of not acting before the cause is known. Evidence: item 1 (evidence log).

| Level | Observable evidence |
|---|---|
| 1 | The first explanation offered in the briefing is acted on. No hypotheses. The fix is the diagnosis |
| 2 | One hypothesis, confirmed. The briefing's claims are neither tested nor challenged. The log was reconstructed afterwards |
| 3 | Three or more hypotheses per stage, each with a separating command and its result. Every claim in the briefing is marked confirmed or refuted. The reproduction is proved on both known ends before it is trusted (stage 1). Read-only until the cause is stated |
| 4 | Level 3, and the log shows economy and independence: the cheapest decisive command first, a second line of evidence for the conclusion (a reflog and a parent list; a bisect and a blame), evidence taken from more than one clone, and an explicit statement of what would have changed the conclusion |

### 3.4 Production judgment

Choosing what to do, in which order, at what risk, under pressure from people who want it faster. Evidence: the options table in item 3; the answers to the shortcuts proposed in the briefings; severity in item 7.

| Level | Observable evidence |
|---|---|
| 1 | A shortcut from a briefing is taken: the wrong pull request merged in stage 1, an administrator merge in stage 4, `main` tagged in stage 8. Or `main` is rewritten |
| 2 | The right route, without the comparison. Severity is missing or is argued from who caused it. Scope creep: features added while fixing |
| 3 | At least two options per stage with reasons for rejection. The smallest change that removes the cause is chosen. Severity is set from what could have happened in the window. Releases contain what they are said to contain, shown with a diff |
| 4 | Level 3, and trade-offs are argued on both sides where they are real: revert against fix-forward in stage 1; rewrite against rotate-only in stage 3; repair against squash in stage 7; the direction of the fix in stage 8. The order of actions reflects who is blocked and what is at risk, and a first message goes out before the recovery where stabilising requires it |

### 3.5 Security awareness

Treating credentials, history rewrites, forced pushes and pipeline permissions as security matters. Evidence: all of stage 3; the forced pushes of stages 3 and 7; the workflow reading in stage 4; prevention items throughout.

| Level | Observable evidence |
|---|---|
| 1 | In stage 3 the first action is a Git command, or the deletion commit is accepted as a fix. A bare `--force` anywhere |
| 2 | Revocation is mentioned and not placed first. The rewrite is done and the remaining copies (pull request refs, the tag, clones, reflogs, the server's unreachable objects) are only partly found |
| 3 | Revoke first, stated with the reason. Every ref in every repository that reached the file is listed from evidence. Objects are removed everywhere and the GitHub equivalent of each step is named. Every forced push carries an explicit expectation. The dummy secret is not copied into the deliverables |
| 4 | Level 3, and the exposure is reasoned about as an outsider would exploit it: the window with its source, who could read it, what cannot be recalled (clones, forks, caches), why "private" and "staging" limit and do not end the exposure. The decision to rewrite is argued, not assumed. The workflow files are read for their permissions and pins when they are in front of you |

### 3.6 Recovery skills

Getting state back without making anything worse. Evidence: item 3 (preserve, commands, risk labels) and item 4 (verification).

| Level | Observable evidence |
|---|---|
| 1 | A recovery that needed a sandbox rebuild because an earlier step destroyed what a later step needed, without recognising why. Work reported as lost that Git still held |
| 2 | The state is recovered. Nothing was named before it was moved. Verification is "it looks right". The unrecoverable part is not identified |
| 3 | Every recovery starts with rescue refs. 🔴 commands are previewed. Verification re-runs the commands that showed the problem and runs the tests on the commit that will be used. Recovered and unrecoverable are listed separately with the mechanism for each (stage 5) |
| 4 | Level 3, and the repair is proved before it is published: a range-diff and a tree comparison in stage 7, a comparison of the backport with its original in stage 8. The recovery is the one that leaves teammates the smallest task, and their commands were run in their clones |

### 3.7 Engineering communication

Writing that a team can act on and a CTO can decide from. Evidence: items 6 and 7 of every stage; the postmortem.

| Level | Observable evidence |
|---|---|
| 1 | Messages are a narrative of commands, or assign blame, or are missing |
| 2 | Correct and too long, or correct and vague: teammates are told to "re-sync". The CTO message explains Git. Things are called verified that were not checked |
| 3 | The team message gives the exact commands per person. The CTO message has the four parts, impact first, a severity with its reason, times with a zone, no names and no commands. "Not yet verified" is stated. The postmortem passes the replace-names-by-roles test |
| 4 | Level 3, and the writing is calibrated: observed and inferred are separated, every time and ID in the postmortem has a source, the CTO's direct questions are answered in the first lines, and the closing page ranks controls by what they would have prevented across the fortnight |

## 4. Which stage feeds which dimension

Score a dimension only in the stages marked. Stages marked **P** are the primary evidence for that dimension.

| Dimension | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Git knowledge | • | **P** | • | • | **P** | • | **P** | • |
| GitHub knowledge |  | • | • | **P** |  | **P** | • | • |
| Debugging ability | **P** | • |  | **P** | • | **P** | • |  |
| Production judgment | **P** |  | • | • |  |  | • | **P** |
| Security awareness |  |  | **P** | • |  |  | • |  |
| Recovery skills |  | • | • |  | **P** | • | **P** | • |
| Engineering communication | • | • | **P** | • | • | • | • | **P** |

The postmortem is scored once, under engineering communication, and counts as a primary stage.

## 5. The scoring sheet

For each dimension, write the level of each marked stage, then:

- the **dimension score** is the median of its stage levels, rounded down;
- the **floor** is the lowest level among its primary stages.

```text
Dimension                    Stage levels (1 to 8, P = primary, PM = postmortem)      Median   Floor (primary)
Git knowledge                1:_  2:_P 3:_  4:_  5:_P 6:_  7:_P 8:_                   ___      ___
GitHub knowledge             2:_  3:_  4:_P 6:_P 7:_  8:_                             ___      ___
Debugging ability            1:_P 2:_  4:_P 5:_  6:_P 7:_                             ___      ___
Production judgment          1:_P 3:_  4:_  7:_  8:_P                                 ___      ___
Security awareness           3:_P 4:_  7:_                                            ___      ___
Recovery skills              2:_  3:_  5:_P 6:_  7:_P 8:_                             ___      ___
Engineering communication    1:_  2:_  3:_P 4:_  5:_  6:_  7:_  8:_P PM:_P            ___      ___
```

## 6. Disqualifying findings

Any one of these makes the outcome "not yet", whatever the scores. Each is something that, in production, turns an incident into a larger one.

| # | Finding | Why it disqualifies |
|---|---|---|
| D1 | `main` on the server was rewritten or pushed to directly, in any stage | The one shared history that everyone builds on |
| D2 | A bare `git push --force`, to a branch or a tag | Overwrites what you have not examined ([Chapter 12](../textbook/ch12-remote-operations.md), section 12.8) |
| D3 | In stage 3, any Git action is placed before revoking the credential, or the write-up declares the branch clean because the file is deleted at the tip | The order is the lesson ([Chapter 30](../textbook/ch30-incident-response.md), section 30.17) |
| D4 | A shortcut that ships unverified or unreviewed content: the speculative revert merged in stage 1, a merge over the red check in stage 4, `main` tagged as the patch release in stage 8 | Wrong code in production with a green record |
| D5 | Something is reported as verified that was not checked, or a GitHub-side result is described as observed | A summary that cannot be trusted is worse than none ([Chapter 30](../textbook/ch30-incident-response.md), section 30.15) |
| D6 | A teammate's work was destroyed during a recovery and this was not detected by your own verification | The recovery became the incident |
| D7 | A deliverable assigns the cause to a person | Blame removes the evidence next time (section 30.19) |

A finding you made yourself, reported in your own deliverable and repaired ("I pushed with `--force` here; this is what it could have overwritten; this is what I should have typed") is scored under the relevant dimension at level 2 for that stage and is not disqualifying. Detecting your own error is part of the standard.

## 7. The final judgment

**Demonstrates senior-level mastery** requires all of the following.

1. **All eight checks pass**, on a sandbox that you worked through in order. A stage retaken with `capstone/setup.sh --stage N` counts; a stage skipped by building the next one does not.
2. **No disqualifying finding** from section 6.
3. **Every dimension score is 3 or higher.**
4. **Every floor is 3 or higher**: no primary stage at level 1 or 2 in its dimension. A senior engineer does not have a category of incident that goes badly.
5. **At least three dimension scores are 4**, and they include **production judgment** or **debugging ability**. Level 3 everywhere is a reliable engineer. The capstone asks for more than that in the places where an incident is led.
6. **The postmortem is at level 3 or higher** and has the closing section.

Otherwise the outcome is **not yet**, and it comes with a list: each condition that failed, the stage and item where the evidence was missing, and what to restudy.

| What fell short | Restudy | Then |
|---|---|---|
| Git knowledge, stages 2, 5 or 7 | [Chapter 8](../textbook/ch08-merge.md), sections 8.10 and 8.16; [Chapter 13](../textbook/ch13-recovery.md), sections 13.6 to 13.9; [Chapter 9](../textbook/ch09-rebase.md), section 9.15 | Retake the stage |
| GitHub knowledge, stages 4 or 6 | [Chapter 17](../textbook/ch17-pull-requests.md), sections 17.2 and 17.3; [Chapter 20A](../textbook/ch20a-actions-fundamentals.md), section 20A.8; [Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.8 | Retake the stage |
| Debugging ability | [Chapter 29](../textbook/ch29-production-troubleshooting.md), sections 29.2 to 29.7; [Chapter 14A](../textbook/ch14a-history-investigation.md), sections 14A.19 to 14A.21 | Two incidents from [`incidents/`](../incidents/README.md) you have not done, then retake |
| Production judgment | [Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.9; [Chapter 27](../textbook/ch27-open-source-team-workflows.md), section 27.10; [Chapter 30](../textbook/ch30-incident-response.md), section 30.3 | Rewrite the options tables of stages 1 and 8, then retake the weaker one |
| Security awareness | [Chapter 21B](../textbook/ch21b-repository-security-incident-response.md), sections 21B.14 and 21B.16; [Chapter 12](../textbook/ch12-remote-operations.md), section 12.8 | Retake stage 3 |
| Recovery skills | [Chapter 13](../textbook/ch13-recovery.md), section 13.7; [Chapter 30](../textbook/ch30-incident-response.md), sections 30.5 and 30.16 | Retake stages 5 and 7 |
| Engineering communication | [Chapter 30](../textbook/ch30-incident-response.md), sections 30.15 and 30.19 | Rewrite the two messages of three stages and the postmortem; no sandbox work needed |

A retake of a stage is a new attempt in a rebuilt sandbox with new deliverables for that stage. The earlier attempt stays in your notes. Having read the walkthrough for a stage does not bar a retake, but it changes what the retake shows: score debugging ability for that stage at no more than level 3.

## 8. Notes for the evaluator

- **Score from the page.** If the evidence for a level is not written down, the level was not demonstrated, however likely it is that the person knew.
- **The model solution is one route.** The walkthrough rebuilds a branch with a cherry-pick where a careful learner may redo a merge; it restores a branch from a pull request ref where another finds the same commit elsewhere. A different route that is evidenced, safe and verified scores the same. The checks were written to accept such routes.
- **Different commit IDs are expected.** The learner's own commits are made with the real clock. Compare structure and content, not IDs.
- **Look for what is not there.** The quickest read of a stage file is the "Not verified" list, the options table and the number of hypotheses. Their absence is almost always level 2.
- **Rebuilds.** A rebuild of the sandbox that the learner noted and explained is information, not a penalty in itself. Score the stage on the final attempt, and score recovery skills for that stage at no more than level 3 if the rebuild was needed because a state was not preserved.
