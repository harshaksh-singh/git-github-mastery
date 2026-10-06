# Capstone: eight incidents at Tessaly

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Everything runs locally in the lab sandbox. The company, the people, the product and every alert are fictional and were constructed for this course.

This is the last piece of work in the course. You join a small team for eight working days. On each day something goes wrong in or around the team's repository, and you are the person who is asked to sort it out. Nobody tells you the cause. What you are told is what a teammate, a manager or an alert would tell you: incomplete, sometimes wrong, never the mechanism.

The capstone applies the method of [Chapter 29: Production Troubleshooting](../textbook/ch29-production-troubleshooting.md) and the incident loop of [Chapter 30: Incident Response](../textbook/ch30-incident-response.md). It adds nothing new to learn. It tests whether you can use what you learned when the situation does not announce which chapter it belongs to, when the states of earlier days are still in the repository, and when you have to write down what you did for people who were not there.

## 1. The company and the product

**Tessaly** sells a customer-support platform. One of its backend services is **`intent-router`**: it receives a customer message, decides which *intent* the message has (`billing_refund`, `order_status`, `account_access`), and routes it to the queue of the desk that handles that intent. A message that fits no intent well enough goes to a human triage agent.

The decision uses two signals per candidate intent, both between 0 and 1:

- a **keyword score**: how many of the intent's keywords occur in the message (`router/keywords.py`);
- an **embedding score**: the similarity between the message and the intent's examples, computed by a separate embedding service.

`router/scoring.py` blends the two, and `router/classify.py` picks the best intent above a threshold. The code is small on purpose. You will read all of it within minutes, and no stage requires more Python than a three-line change.

## 2. The team

| Person | Role | Clone | What to expect |
|---|---|---|---|
| You | Backend engineer, three months in the team | `you/` | Identity `Lab User <you@example.com>` |
| Nandini Iyer | Tech lead; reviews and merges most pull requests; owns releases | `nandini/` | Precise, asks for evidence, will not bypass a rule on a guess |
| Kabir Sethi | ML engineer; owns scoring and the embedding client | `kabir/` | Fast, helpful, sometimes helps before asking |
| Tanvi Desai | Platform engineer; owns CI and deployment; on call this fortnight | `tanvi/` | Under time pressure; proposes the quickest route |
| Leela Varma | CTO | none | Reads your summaries; asks about customers, risk and recurrence |

The people are written to be reasonable. Each action that causes an incident looked right to the person who took it. Your postmortems are expected to show why ([Chapter 30](../textbook/ch30-incident-response.md), section 30.19).

## 3. The sandbox

`capstone/setup.sh` builds everything under `$GIT_MASTERY_LABS/capstone/intent-router` (`~/git-mastery-labs/capstone/intent-router` by default):

```text
  server.git     a bare repository: the server, the part GitHub plays in real life
  pr             a script that plays the pull-request side of GitHub (section 6)
  you/           your clone
  nandini/  kabir/  tanvi/     your teammates' clones, each with its own user.name and user.email
  evidence/      files that a stage writes for you: an alert, a run report, a pasted script
  home/          the isolated Git configuration of the sandbox
```

You are allowed to look into and work in every clone, the way you would sit down at a colleague's machine during an incident, unless a briefing says that a person is away. `git -C ../tanvi <command>` runs a command in Tanvi's clone without leaving yours. You are also the administrator of `server.git`; where you use that power, your write-up must say what the equivalent step on GitHub is and who could perform it.

Nothing touches a network, your real Git configuration, or anything outside the lab root.

## 4. The repository

```text
  README.md
  .gitignore
  .github/CODEOWNERS                 who must review which path
  .github/workflows/ci.yml           tests on every pull request and on pushes to main and release/**
  .github/workflows/release.yml      builds the archive when a tag v* is pushed
  router/__init__.py
  router/keywords.py                 keyword hits and the keyword score
  router/scoring.py                  the blend of keyword score and embedding score
  router/classify.py                 picks the intent
  router/routes.yaml                 intent -> queue and priority
  scripts/test.sh                    runs the unit tests; prints OK or the failing tests
  scripts/evaluate.py                offline evaluation against the evaluation set
  scripts/version.sh                 "git describe" for the release archive
  data/eval-messages.jsonl.dvc       a pointer file: hash, size and name of the evaluation set
  data/.gitignore                    keeps the evaluation set itself out of Git
  tests/test_scoring.py  tests/test_classify.py
```

Three things in this layout deserve a sentence each.

- **The data pointer.** The evaluation set (48 MB of labelled messages) is not in Git. `data/eval-messages.jsonl.dvc` is a small text file in the format DVC uses: the hash, the size and the path of the real file, which lives in object storage. Git versions the pointer; the data tool fetches the data. [Chapter 28](../textbook/ch28-ai-ml-workflows.md) explains why. No stage requires the data.
- **CODEOWNERS.** `/router/scoring.py` and `/router/keywords.py` belong to `@tessaly/ml`, `/.github/` and `/scripts/` to `@tessaly/platform`, everything else to `@tessaly/intent-router`. On GitHub a ruleset would require a review from the owners; in the sandbox the file is something you read to decide whom to tell.
- **The workflows.** Both reference actions by full commit SHA with the version as a comment, taken from [`workflows/ACTION_PINS.md`](../workflows/ACTION_PINS.md); both set `permissions: contents: read`; the checkout steps set `persist-credentials: false`. They were written from documented syntax and parse as YAML. They were never executed on GitHub, and the sandbox cannot execute them. Stage 4 gives you a constructed description of a run instead.

`bash scripts/test.sh` needs `python3` and nothing else. It prints one line per failing test and a last line, `OK` or `FAILED`.

## 5. Branching and release conventions

The team works trunk-based ([Chapter 27](../textbook/ch27-open-source-team-workflows.md), section 27.8).

| Convention | Rule |
|---|---|
| `main` | Always releasable in principle. Nobody pushes to it. Every change arrives through a pull request. Nobody rewrites it |
| Feature branches | `feature/<topic>`, `fix/<topic>`, `chore/<topic>`, `docs/<topic>`; short-lived; pushed early |
| Merge method | Squash by default: one commit on `main` per pull request, titled `<title> (#<number>)`. A merge commit (`Merge pull request #<number> from <branch>`) when the individual commits should stay visible, for example a revert next to its test |
| After a merge | The server deletes the head branch |
| Releases | An **annotated** tag `vMAJOR.MINOR.PATCH` on the released commit, created by whoever ships it and pushed with `git push origin <tag>`. The release workflow refuses a tag that is not annotated |
| Maintenance lines | `release/MAJOR.MINOR`, created at the release tag the first time a released version needs a fix that `main` cannot deliver |
| Direction of fixes | A fix lands on `main` first and is copied to the maintenance line with `git cherry-pick -x` ([Chapter 10](../textbook/ch10-cherry-pick.md), section 10.9; [Chapter 27](../textbook/ch27-open-source-team-workflows.md), section 27.10) |
| Shared feature branches | Allowed. Whoever rewrites one announces it first |
| Staging deployments | The deploy script marks the deployed commit with a lightweight tag `staging/<date>` |

> **GitHub, not Git.** "Nobody pushes to `main`" is a rule that only a platform can enforce (a ruleset, [Chapter 18](../textbook/ch18-branch-protection.md)). A bare repository accepts any push from anyone who can write to it. In the sandbox the rule is a convention, and the check scripts verify that you kept it: every commit on the first-parent history of `main` must have been created by `../pr merge`.

## 6. Pull requests in the sandbox

GitHub is not Git, and a bare repository has no pull requests. The script `pr` in the sandbox root keeps the few facts the simulation needs, with plain Git: one small text file per pull request next to `server.git`, and the two refs that [Chapter 17](../textbook/ch17-pull-requests.md), section 17.2 describes, `refs/pull/<number>/head` and, when head and base merge without conflict, `refs/pull/<number>/merge`. A `post-receive` hook in `server.git` runs `pr sync` after every push, so the refs follow the branches as they do on GitHub. `receive.hideRefs` keeps clients from pushing to `refs/pull/`.

Run it from any clone as `../pr`:

```bash
../pr list                         # open pull requests; --all includes merged and closed ones
../pr view 12                      # title, state, the commits (base..head), the changed files (base...head)
../pr open feature/x               # after pushing the branch; --base <branch> and --title '<title>' are optional
../pr merge 12                     # squash merge; --merge for a merge commit. Deletes the head branch on the server
../pr close 12                     # close without merging
../pr reopen 12                    # only when the head branch exists again
```

What it imitates and what it does not:

| Behavior | In the sandbox | On GitHub |
|---|---|---|
| A pull request gets its number when it is opened | yes | yes |
| `refs/pull/N/head` follows the head branch; `refs/pull/N/merge` is a test merge of head into base | yes, rebuilt after every push | yes; the test merge is rebuilt on a push, when the merge base changes, or when it is older than 12 hours ([Chapter 20A](../textbook/ch20a-actions-fundamentals.md), section 20A.8) |
| A pull request with conflicts cannot be merged and has no merge ref | yes | yes |
| Deleting the head branch closes the pull request | yes, and `refs/pull/N/head` keeps the last head commit | the pull request is closed, and a closed pull request offers **Restore branch** ([Chapter 30](../textbook/ch30-incident-response.md), section 30.12) |
| Who is recorded on a merge | the person who runs `../pr merge` is the committer; a squash commit has the first commit's author as its author | the committer of a web merge is GitHub; who becomes the author of a squash commit is not stated in the documentation ([Chapter 17](../textbook/ch17-pull-requests.md), section 17.8) |
| Reviews, approvals, required checks, rulesets, the Activity view, the audit log | not simulated | yes |

These are plain Git commands chosen to produce the documented result. GitHub does not publish the commands it runs. Where a stage depends on something in the last row, the briefing gives you a constructed piece of evidence, and your write-up names the real instrument.

## 7. The history you inherit

`capstone/setup.sh --stage 0` builds the repository with no incident applied. Look at it once before you start; you will be expected to know your way around.

The first-parent history of `main`, from Monday 7 to Friday 11 September 2026: two direct commits by the tech lead from before the pull-request rule, then pull requests #1 to #11, nine of them squash merges and two merge commits, and four annotated tags, `v1.0.0` to `v1.3.0`. Two feature branches have open pull requests: #12 (yours) and #13 (Kabir's). The walkthrough prints this history as a real transcript.

The lab clock makes every run of `setup.sh` produce the same commit IDs. The incidents then happen on fixed days:

| Stage | Day (2026) | Directory | What the briefing says |
|---|---|---|---|
| 1 | Mon 14 Sep | [`stage-01-bug-in-production`](stage-01-bug-in-production/BRIEFING.md) | "The billing queue is flooded with junk since the release" |
| 2 | Tue 15 Sep | [`stage-02-merge-conflict`](stage-02-merge-conflict/BRIEFING.md) | "I resolved your conflicts for you, press the button" |
| 3 | Wed 16 Sep | [`stage-03-leaked-secret`](stage-03-leaked-secret/BRIEFING.md) | "I deleted the file, so the branch is clean now" |
| 4 | Thu 17 Sep | [`stage-04-failed-ci`](stage-04-failed-ci/BRIEFING.md) | "It passes on my machine; it must be the Python version" |
| 5 | Fri 18 Sep | [`stage-05-lost-work`](stage-05-lost-work/BRIEFING.md) | "I fetched, and my three commits were gone" |
| 6 | Tue 22 Sep, morning | [`stage-06-deleted-branch`](stage-06-deleted-branch/BRIEFING.md) | "The branch for Thursday's demo is not in the list" |
| 7 | Tue 22 Sep | [`stage-07-broken-pull-request`](stage-07-broken-pull-request/BRIEFING.md) | "The pull request shows every commit twice" |
| 8 | Wed 23 Sep | [`stage-08-hotfix-and-backport`](stage-08-hotfix-and-backport/BRIEFING.md) | "Production returns errors, and `main` is not signed off" |

## 8. How to run the simulation

All commands are typed in the course root.

```bash
capstone/setup.sh                                  # builds the sandbox with stage 1 applied; prints its path
labs/shell "<the path it printed>/you"             # a shell with the isolated lab configuration
```

Then, for each stage:

1. Read the stage's `BRIEFING.md`. Read nothing else in the stage directory.
2. Work in the sandbox. Keep your evidence log as you go ([`DELIVERABLES.md`](DELIVERABLES.md)).
3. Run the stage's check from the course root: `capstone/stage-NN-<slug>/check.sh`. It prints one line per condition and ends with `PASS` (exit status 0) or `NOT YET` (exit status 1).
4. Write the stage's deliverables before you go on. The check sees Git state. It cannot see whether you understood what you did.
5. Apply the next stage: `capstone/stage-NN-<slug>/inject.sh`. It refuses to run until the previous check passes.

The stages are cumulative. Stage 5 happens in a clone whose reflogs you may have expired in stage 3. Stage 8 has to deal with everything that reached `main` in stages 2, 4 and 7. That is the point of doing them in order, in one sandbox.

| File in a stage directory | What it is | When to read it |
|---|---|---|
| `BRIEFING.md` | What you are told and what you are asked for | First |
| `check.sh` | Read-only verification of the Git state the stage must reach | Run it; read it after the stage |
| `inject.sh` | Builds the incident on top of the current state. It is the answer to "what happened" | After the stage |

**To retake or skip a stage:** `capstone/setup.sh --stage N` deletes the sandbox and builds the state at the start of stage N directly: the company repository, then stages 1 to N-1 solved with the model solutions, then the incident of stage N. The result is deterministic, and its commit IDs are the ones printed in [`solutions/capstone-walkthrough.md`](../solutions/capstone-walkthrough.md). Your own solutions will have other IDs for the commits you create, because `labs/shell` uses the real clock.

**If a repair goes wrong:** rebuild with `capstone/setup.sh --stage N` and start the stage again. A sandbox is the one place where a destructive mistake costs nothing. In the evaluation, a rebuild counts as what it would have been in production.

## 9. The rules of the simulation

1. **Evidence before action.** Until you can state the cause, use only commands that read state or add refs ([Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.2). Write at least three hypotheses per stage, with the command that separates them.
2. **Preserve before you change.** Every state you may need gets a name first: `git branch rescue/<what> <commit ID>`.
3. **The lowest-risk fix.** Among the changes that repair the cause, choose the one that destroys least and is simplest to undo, and write down the options you rejected.
4. **`main` is never rewritten, and never pushed to.** Changes reach it through `../pr merge`.
5. **A forced push names what it expects.** `--force-with-lease=<branch>:<commit ID>`, or `--force-with-lease --force-if-includes` on a branch you examined a moment ago. A bare `--force` is a finding against you.
6. **Verify with the commands that showed the problem**, and run the project's tests on the commit that will be used.
7. **Say what you did not verify.** A local sandbox cannot show what a GitHub run, a provider console or a production system would show. Name those steps; do not claim them.
8. **No names in causes.** A cause is a mechanism on a layer (Git, GitHub, GitHub Actions, a team convention), not a person.
9. **The solutions stay closed** until your own deliverables for the stage are written: the walkthrough, the `inject.sh` scripts and the scripts under `labs/capstone/`.

## 10. What you hand in, and how it is judged

[`DELIVERABLES.md`](DELIVERABLES.md) lists what you hand in for each stage (evidence log, root cause, recovery, verification, prevention, a message to the team, a message to the CTO) and the final postmortem. [`EVALUATION.md`](EVALUATION.md) is the rubric: seven dimensions, a four-level scale with observable evidence for each level, and the rule by which the final judgment, "demonstrates senior-level mastery" or "not yet", is reached. The model solution is [`solutions/capstone-walkthrough.md`](../solutions/capstone-walkthrough.md). Read it after your own attempt, stage by stage.

Plan about ten to fourteen hours in total: roughly one hour per stage in the sandbox, half an hour per stage for the write-up, and two hours for the postmortem.

## 11. For maintainers

| File | Purpose |
|---|---|
| `capstone/lib/capstone-lib.bash` | People, clock, clones, the stage list, `cap_build_to` |
| `capstone/lib/base.bash` | The company repository: file contents and the history up to `v1.3.0` |
| `capstone/lib/pr.sh` | The pull-request stand-in; copied to the sandbox as `pr` |
| `capstone/lib/check-lib.bash` | Helpers of the check scripts |
| `labs/capstone/model-NN-<slug>.bash` | The model solution of a stage as a replay body. `setup.sh --stage N` applies the earlier ones silently |
| `labs/capstone/stage-NN-<slug>.sh` | Replay of one stage: builds its start state, asserts that the check fails, plays the model solution with transcript capture, asserts that the check passes |
| `labs/capstone/end-to-end.sh` | All eight stages in one sandbox, with the check before and after each |

Every stage starts at a fixed time on the lab clock, so its commit IDs do not depend on how many commands the earlier stages used. `labs/verify-all.sh capstone` re-runs all replays and compares the output with the transcripts printed in the walkthrough. It takes a few minutes, because each replay builds its start state from the beginning.
