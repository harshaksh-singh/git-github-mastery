# The ten incidents

Ten repositories, each built in a broken state by a script. You get the report a colleague would give you, incomplete and partly wrong, and you have to find out what happened, repair it with the lowest-risk change, and prove that the repair worked. [Chapter 30: Incident Response](../textbook/ch30-incident-response.md) teaches the method. Modules 36 and 37 of the lab manual run the incidents as drills.

| # | Directory | The report says | Module |
|---|---|---|---|
| 1 | [`01-hard-reset`](01-hard-reset/SYMPTOMS.md) | "I think `git pull` ate my work" | 36 |
| 2 | [`02-force-push-wrong-branch`](02-force-push-wrong-branch/SYMPTOMS.md) | "The top commit on `main` says WIP" | 37 |
| 3 | [`03-committed-secret`](03-committed-secret/SYMPTOMS.md) | "I deleted the file, so the branch is clean now" | 37 |
| 4 | [`04-production-history-rewritten`](04-production-history-rewritten/SYMPTOMS.md) | "The deployed commit is not an ancestor of `production`" | 37 |
| 5 | [`05-rebased-shared-branch`](05-rebased-shared-branch/SYMPTOMS.md) | "Every commit is in the pull request twice" | 36 |
| 6 | [`06-pr-500-changes`](06-pr-500-changes/SYMPTOMS.md) | "I pushed one commit and the pull request shows 500 files" | 37 |
| 7 | [`07-ci-passes-locally`](07-ci-passes-locally/SYMPTOMS.md) | "It passes on my Mac, it must be a flaky runner" | 37 |
| 8 | [`08-branch-disappeared`](08-branch-disappeared/SYMPTOMS.md) | "My branch has disappeared" | 36 |
| 9 | [`09-misunderstood-conflict`](09-misunderstood-conflict/SYMPTOMS.md) | "My fix is in the log and not in the file" | 36 |
| 10 | [`10-commit-local-not-remote`](10-commit-local-not-remote/SYMPTOMS.md) | "It is pushed. GitHub must be caching" | 36 |

## What is in each directory

| File | What it is | When to read it |
|---|---|---|
| `SYMPTOMS.md` | What the people involved reported, in their words | First |
| `generate.sh` | Builds the sandbox. It is also the full answer to "what happened" | After your attempt |
| `check.sh` | Verifies your recovery with read-only commands; exit status 0 means recovered | When you think you are done |
| `evidence/` (incident 7 only) | The workflow file and a description of the failed run, constructed for the exercise | With `SYMPTOMS.md` |

The worked solutions are in [`solutions/`](../solutions/) as `incident-NN-slug.md`. Read a solution only after an attempt. The value of a drill is the diagnosis you make without help; once you have read the cause, that drill cannot be repeated.

## How to run an incident

All commands are typed in the course root.

```bash
incidents/01-hard-reset/generate.sh        # builds the sandbox and prints its path
labs/shell "<the path it printed>"         # a shell with the isolated lab configuration
```

The sandbox is `$GIT_MASTERY_LABS/incidents/<name>` (`~/git-mastery-labs/incidents/<name>` by default). Every sandbox has the same layout:

```text
  server.git     a bare repository: the server, the part GitHub plays in real life
  you/           your clone
  asha/  ravi/   your teammates' clones, each with its own user.name and user.email
```

You are allowed to look into and work in every clone, the way you would sit down at a colleague's machine during an incident. `git -C ../ravi <command>` runs a command in Ravi's clone without leaving yours. You are also the administrator of `server.git`.

Running `generate.sh` again deletes the sandbox and builds it afresh. Do that whenever a repair went wrong: an incident sandbox is the one place where a destructive mistake costs nothing.

## How to solve one

1. Read `SYMPTOMS.md`. Write down the symptom in one sentence without interpretation.
2. Collect evidence with read-only commands only: the ten-command diagnosis of [Chapter 1](../textbook/ch01-fundamentals.md), section 1.11, in each clone that matters, plus `git ls-remote origin` for the server.
3. Write at least three hypotheses and the command that would tell them apart. Run those commands.
4. Preserve before you change: `git branch rescue/<what> <commit ID>`.
5. Choose the fix that destroys least. Run it one command at a time.
6. Verify with the commands that showed the problem.
7. Write the four lines a CTO needs: what happened, the root cause with its layer, what was done and how it was verified, what prevents a repeat.

## How to check

```bash
incidents/01-hard-reset/check.sh           # checks the sandbox in the default place
incidents/01-hard-reset/check.sh <path>    # checks a sandbox somewhere else
```

The check prints one line per condition and ends with `PASS` (exit status 0) or `NOT YET` (exit status 1). On a freshly generated incident every check script fails; that is tested. A check verifies the state you were asked to reach, not the route you took. It cannot verify the parts of an incident that are not Git state, such as rotating a credential or telling the team: those are in the solution files.

## Two things that differ from real life

- **The clock.** A generator runs with the fixed lab clock, so the commit IDs in your sandbox equal the IDs printed in the solutions and in Chapter 30. Commits that you create in `labs/shell` use the real clock and get other IDs.
- **The server.** A bare repository has no Activity view, no pull requests, no rulesets and no Support desk. Where an incident depends on one of those, the solution says what the GitHub-side step is, described from GitHub's documentation.

## For maintainers

`labs/incidents/solve-NN-slug.sh` replays each solution: it sources the generator, asserts that `check.sh` fails, runs the diagnosis and recovery, and asserts that `check.sh` passes. The scripts `labs/incidents/lab-36-*.sh`, `lab-37-*.sh` and `lab-38-*.sh` replay the failure scenarios of the lab manual the same way. `labs/verify-all.sh incidents` re-runs all of them and compares the output with the transcripts printed in the book. Shared helpers are in `incidents/lib/` and `labs/incidents/replay-lib.bash`.
