# Gate 6: GitHub

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026, as the textbook cites them. Nothing in this gate was run against GitHub, and no GitHub output is shown. The transcripts in part 2 are real output of `labs/gates/g6-predict.sh`: plain Git doing what the platform does. This file contains no answers. The answer key is for the examiner; do not open it before the gate is scored, and not at all if you failed and will take variant B.

**Taken after** Module 25. **Covers** the platform model, authentication, pull requests, merge methods, rulesets, CODEOWNERS, signing and the CLI: Chapters [15](../textbook/ch15-github.md), [16](../textbook/ch16-authentication.md), [17](../textbook/ch17-pull-requests.md), [18](../textbook/ch18-branch-protection.md), [19](../textbook/ch19-codeowners.md), and the signing sections of [14B](../textbook/ch14b-config-tags-signing.md) and [21B](../textbook/ch21b-repository-security-incident-response.md).

**Pass rule.** 85 points or more out of 100, and at least 70% in every part. How a gate is taken, timed and scored is in the [README](README.md).

| Part | Points | Minimum to pass the part | Time |
|---|---|---|---|
| 1 Concepts | 30 | 21 | 45 minutes, closed book |
| 2 Prediction | 20 | 14 | 25 minutes, no terminal |
| 3 Hands-on diagnosis | 30 | 21 | 60 minutes, on paper |
| 4 Oral interview | 20 | 14 | 20 minutes, spoken, no terminal |

**Label the layer.** In every answer of this gate, say for each statement whether it is about Git, about GitHub, or about GitHub Actions. An answer that attributes a GitHub rule to Git, or the reverse, loses the point of that statement.

---

## Part 1: Concepts (30 points)

Six questions, 5 points each. Answer in writing, in five to ten sentences.

### C1 (5 points)

Your company wants to know what it would still have if it left GitHub tomorrow with nothing but `git clone --mirror` of every repository. Sort these into "Git data that the mirror contains", "Git data that GitHub wrote and the mirror contains" and "GitHub objects that no Git command copies": an annotated tag; the release notes attached to that tag; the commits of a merged pull request; the review comments on it; `refs/pull/88/head`; the file `.github/CODEOWNERS`; a ruleset; an issue. Then say what "this pull request is merged" means in terms of Git data.

### C2 (5 points)

Explain the difference between authentication and authorization using this message: a deploy job prints "Repository not found" for a repository that exists. What has the server established when it sends that answer, why does it not say "forbidden", and what are four different root causes? Give the command that tells you who the server thinks you are, once for HTTPS and once for SSH.

### C3 (5 points)

State exactly which Git comparison the "Commits" tab and the "Files changed" tab of a pull request show. A pull request that should contain one commit lists four, three of which were merged last week through another pull request, by squash. Explain why with the merge base, and give the repair as one Git command. Why does GitHub not notice by itself that those three commits "are already in `main`"?

### C4 (5 points)

For each of GitHub's three merge methods, say which commits exist on `main` afterwards, what happens to the commit IDs that were reviewed, who is the committer, and whether the result carries a verified signature. Then give one consequence of each method for a later `git bisect` and for a later revert of the whole change.

### C5 (5 points)

A repository's default branch is targeted by an organization ruleset, a repository ruleset and an old classic branch protection rule. Explain how GitHub combines them and which wins when two of them set the same rule differently. Who is exempt, and how does that differ between rulesets and classic rules? Then explain why a required status check is "a name, not a workflow", and give three ways in which that causes a pull request to wait forever or to be merged without the check having run.

### C6 (5 points)

A team adds a `CODEOWNERS` file and is surprised twice: owners are requested and their approval is not needed, and a file under `docs/guides/` is assigned to the wrong team although a line `docs/* @acme/docs` exists. Explain both. Include: where GitHub looks for the file and which copy counts for a given pull request, how a path is matched when several lines match, two documented differences from `.gitignore` matching, and what an owner must have for the line to be valid.

---

## Part 2: Prediction (20 points)

Four items, 5 points each. No terminal. The setups use plain Git to do what GitHub does on its server. Write the output you expect and one sentence of mechanism for each prediction.

### P1 (5 points)

<!-- snippet: gates/g6-predict/p1-setup -->
```text
# main plays the base branch on GitHub. The last two commands do what "Squash and merge" does.
$ git init -q billing
$ cd billing
$ printf 'rate: 1\n' > plan.yaml && git add . && git commit -q -m 'Add plan'
$ git switch -q -c feature/proration
$ printf 'def prorate(days):\n    return days / 30\n' > prorate.py && git add . && git commit -q -m 'Add proration'
$ printf 'def prorate(days, month=30):\n    return days / month\n' > prorate.py && git commit -q -am 'Use the real month length'
$ printf 'rate: 1\nprorate: true\n' > plan.yaml && git commit -q -am 'Enable proration in the plan'
$ git switch -q main
$ git merge -q --squash feature/proration
Squash commit -- not updating HEAD
$ git commit -q -m "Add proration (#12)"
```
<!-- /snippet -->

Predict:

1. The number of commits on `main`, and the number of parents of its newest commit.
2. The output of `git diff --stat main feature/proration`.
3. The output of `git branch --merged main`, and the number of commits in `main..feature/proration`.
4. Whether `git branch -d feature/proration` deletes the branch, and the three characters that `git cherry main feature/proration | cut -c1` prints, one per line.

### P2 (5 points)

<!-- snippet: gates/g6-predict/p2-setup -->
```text
# Two branches, the second built on the first. The first is squash-merged; the second is not touched.
$ git init -q router
$ cd router
$ printf 'routes: []\n' > routes.yaml && git add . && git commit -q -m 'Add routes file'
$ git switch -q -c feature/priority
$ printf 'P = 1\n' > priority.py && git add . && git commit -q -m 'Add priority'
$ printf 'P = 2\n' > priority.py && git commit -q -am 'Raise priority'
$ git switch -q -c feature/escalation
$ printf 'E = True\n' > escalation.py && git add . && git commit -q -m 'Add escalation'
$ git switch -q main
$ git merge -q --squash feature/priority && git commit -q -m "Add priority (#7)"
Squash commit -- not updating HEAD
```
<!-- /snippet -->

A pull request from `feature/escalation` into `main` is opened now. Predict:

1. The commits its "Commits" tab would list: the output of `git log --format=%s main..feature/escalation`.
2. The files its "Files changed" tab would list: the output of `git diff --stat main...feature/escalation`.
3. The subject of the merge base of `main` and `feature/escalation`.

Then:

<!-- snippet: gates/g6-predict/p2-setup-b -->
```text
$ git rebase -q --onto main feature/priority feature/escalation
```
<!-- /snippet -->

4. Predict both outputs again.

### P3 (5 points)

<!-- snippet: gates/g6-predict/p3-setup -->
```text
# The patterns are written into a .gitignore file so that the matcher of Git can be asked.
$ git init -q patterns
$ cd patterns
$ printf '*\ndocs/*\n*.tf\n/services/billing/\n' > .gitignore
$ cat -n .gitignore
     1	*
     2	docs/*
     3	*.tf
     4	/services/billing/
```
<!-- /snippet -->

`git check-ignore -v --no-index <paths>` prints, for each path, the line of the file whose pattern decides. It is run for these five paths: `docs/index.md`, `docs/api/auth.md`, `infra/prod.tf`, `services/billing/api/handler.py`, `README.md`.

1. Predict the line number that Git prints for each of the five paths. (3 points)
2. The same four patterns are now the patterns of a `CODEOWNERS` file, in the same order. According to GitHub's documented rules, which line decides for each of the five paths? Name the paths for which the answer differs from Git's, and the reason. (2 points)

### P4 (5 points)

No signing is configured. The identity in the configuration is `Lab User <you@example.com>`.

<!-- snippet: gates/g6-predict/p4-setup -->
```text
$ git init -q ledger
$ cd ledger
$ git commit -q --allow-empty --author='Asha Rao <asha@example.com>' -m 'Approve the ledger migration'
```
<!-- /snippet -->

Predict:

1. The author, the committer, and the character that `%G?` prints for this commit.
2. The exit status of `git verify-commit HEAD`.
3. From the textbook, not from a run: after this commit is pushed, what does GitHub show next to it if Asha has not enabled vigilant mode, and what if she has? What does either display prove about who made the commit?

---

## Part 3: Hands-on diagnosis (30 points)

On paper: three cases built from configuration files and described situations. Variant A is the first attempt; variant B is for a retake and is not to be opened before.

| | Variant A | Variant B (retake) |
|---|---|---|
| The cases | [`variant-a/CASES.md`](gen/gate-6-github/variant-a/CASES.md) | [`variant-b/CASES.md`](gen/gate-6-github/variant-b/CASES.md) |
| The files | `assessments/gen/gate-6-github/variant-a/` | `assessments/gen/gate-6-github/variant-b/` |

| Case | Points | Graded on |
|---|---|---|
| 1 Why the merge is blocked | 12 | each blocking condition found, attributed to the right rule and layer, with the smallest change that satisfies it; the question at the end answered |
| 2 CODEOWNERS | 9 | the deciding line and the owners for each path; the defects of the file with consequence and correction |
| 3 Authentication | 9 | what the server established; the root cause with its evidence line; two corrections with verification; the alternatives ruled in or out |

A list of blocking conditions that is longer than the truth loses points as well: each condition that does not block, presented as one that does, costs one point. The cases contain at least one setting that looks like a block and is not.

---

## Part 4: Oral interview (20 points)

Six questions, asked one at a time by the examiner, who then asks the follow-up. Answer aloud in one to two minutes each. O1 to O4 are worth 3 points each, O5 and O6 are worth 4 points each.

### O1 (3 points)

Is a pull request part of Git? *Follow-up:* which Git data does GitHub write into the repository when a pull request is opened, and how would you fetch a colleague's pull request without their fork as a remote?

### O2 (3 points)

Why can a pull request show commits that the author did not make in it? *Follow-up:* the author fixes it by merging `main` into the branch. Does that help, and what would you have done?

### O3 (3 points)

Which merge method would you set for the default branch of a service that is deployed from `main`, and what do you give up? *Follow-up:* six weeks later one merged feature has to be removed. What is the command under each method?

### O4 (3 points)

What does the "Verified" badge on a commit prove? *Follow-up:* a commit that names your CTO as author and has no badge changes a payment limit. What do you conclude, and what do you check?

### O5 (4 points)

A developer says: "I am an administrator and the merge button is grey." Walk me through your procedure. *Follow-up:* the only unmet item is a required check that has said "Expected" for an hour. Give me three different causes.

### O6 (4 points)

A CI job in repository A has to read repository B of the same organization. Which credential do you give it, and which ones do you rule out and why? *Follow-up:* someone once solved this with a classic token inside the remote URL. What is the exposure, and what has to happen now?

---

## Score sheet

| Item | Max | Score | | Item | Max | Score |
|---|---|---|---|---|---|---|
| C1 | 5 | | | P1 | 5 | |
| C2 | 5 | | | P2 | 5 | |
| C3 | 5 | | | P3 | 5 | |
| C4 | 5 | | | P4 | 5 | |
| C5 | 5 | | | **Prediction** | **20** | |
| C6 | 5 | | | H case 1 | 12 | |
| **Concepts** | **30** | | | H case 2 | 9 | |
| O1 to O4 | 12 | | | H case 3 | 9 | |
| O5, O6 | 8 | | | **Hands-on** | **30** | |
| **Oral** | **20** | | | **Total** | **100** | |

Pass: total 85 or more, Concepts 21 or more, Prediction 14 or more, Hands-on 21 or more, Oral 14 or more.

## Remediation map

After scoring, restudy the sections of every item on which you lost more than a third of the points, redo the labs of that module on your practice repository, and take the gate again with variant B of the hands-on part.

| Item | Restudy | Lab module |
|---|---|---|
| C1 | Chapter 15, sections 15.2 and 15.12; Chapter 17, sections 17.2 and 17.13 | 19, 21 |
| C2 | Chapter 16, sections 16.2, 16.17 and 16.19 | 20 |
| C3 | Chapter 17, sections 17.3 and 17.12 | 21 |
| C4 | Chapter 17, sections 17.8 and 17.9; Chapter 18, section 18.10 | 22 |
| C5 | Chapter 18, sections 18.4, 18.5, 18.8 and 18.14 | 23 |
| C6 | Chapter 19, sections 19.3 to 19.7 and 19.12 | 23 |
| P1 | Chapter 17, sections 17.8 and 17.9; Chapter 8, section 8.12 | 22 |
| P2 | Chapter 17, sections 17.3, 17.12 and 17.14 | 21 |
| P3 | Chapter 19, section 19.5 | 23 |
| P4 | Chapter 14B, section 14B.18; Chapter 21B, sections 21B.5 to 21B.7 | 24 |
| Case 1 | Chapter 18, sections 18.4 to 18.11, 18.14 and 18.17; Chapter 17, section 17.5 | 23 |
| Case 2 | Chapter 19, sections 19.3 to 19.8 and 19.12 | 23 |
| Case 3 | Chapter 16, sections 16.4, 16.5, 16.10, 16.13 and 16.17 to 16.20 | 20 |
| O1 | Chapter 15, section 15.2; Chapter 17, section 17.2 | 19, 21 |
| O2 | Chapter 17, section 17.12 | 21 |
| O3 | Chapter 17, sections 17.8 and 17.9 | 22 |
| O4 | Chapter 21B, sections 21B.5 to 21B.7; Chapter 14B, section 14B.17 | 24 |
| O5 | Chapter 18, sections 18.5, 18.8 and 18.17 | 23 |
| O6 | Chapter 16, sections 16.6, 16.7 and 16.14 | 20 |
