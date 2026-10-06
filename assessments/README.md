# The nine mastery gates

A gate is an examination at the point where a block of the course is complete. It decides whether you go on. The thresholds and the four parts are those of the [roadmap](../curriculum/Git%20and%20GitHub%20mastery%20roadmap.md), section 4.

| Gate | File | Pass at | Taken after | Covers |
|---|---|---|---|---|
| 1 | [Fundamentals](gate-1-fundamentals.md) | 85 | Module 5 | Data model, three trees, commits, refs, HEAD, configuration |
| 2 | [Branching](gate-2-branching.md) | 90 | Module 7 | Branches as refs, divergence, ancestry, upstream tracking, remote-tracking refs, fetch, pull, push |
| 3 | [Merge and rebase](gate-3-merge-and-rebase.md) | 90 | Module 10 | Three-way merge, conflicts and stages, undo choices, rebase, cherry-pick, range notation |
| 4 | [Recovery](gate-4-recovery.md) | 90 | Module 15 | Forensics, reflog, fsck, the disaster recoveries, what cannot be recovered |
| 5 | [Internals](gate-5-internals.md) | 85 | Module 18 | Object database, packfiles, index format, ref storage, transfer and scale |
| 6 | [GitHub](gate-6-github.md) | 85 | Module 25 | Platform model, authentication, pull requests, merge methods, rulesets, CODEOWNERS, signing, CLI |
| 7 | [Actions](gate-7-actions.md) | 85 | Module 28 | Workflow model, the first eleven workflows, runners, CI debugging |
| 8 | [Security](gate-8-security.md) | 90 | Module 31 | Actions security, repository security, secret-leak response |
| 9 | [Production debugging](gate-9-production-debugging.md) | 90 | Module 38 | Diagnosis method, the ten incidents, communication and postmortems |

## The four parts

Every gate has 100 points in four parts with fixed weights.

| Part | Points | Form | Conditions |
|---|---|---|---|
| 1 Concepts | 30 | Six written questions, 5 points each. Each requires a mechanism: which objects, refs, files or rules are involved and what reads or writes them | Closed book, no terminal |
| 2 Prediction | 20 | Four items, 5 points each. You get the commands that built a state and predict the output of further commands and the new state | No terminal. Object IDs are not asked for |
| 3 Hands-on diagnosis | 30 | Gates 1 to 5 and 9: a repository that a script builds in a broken state, with a report that is incomplete and partly wrong. Gates 6 to 8: three cases on paper, built from configuration files, workflow files, described situations and real Git evidence | Lab shell for gates 1 to 5 and 9; paper for gates 6 to 8 |
| 4 Oral interview | 20 | Six questions asked one at a time, each with a follow-up: four at 3 points, two at 4 points | Spoken, no terminal, no notes |

**Pass rule.** The threshold of the gate overall, and at least 70% in every part: 21 of 30 in Concepts, 14 of 20 in Prediction, 21 of 30 in Hands-on, 14 of 20 in Oral. A total above the threshold with one part below 70% is a miss.

## How a gate is taken

1. **Before.** Finish the modules the gate covers, with their labs and exercises. Do not open the gate file to "see what is in it": a gate that has been read is a gate that has been taken.
2. **One sitting, parts in order.** Each gate file gives the time for each part. Parts 1 and 2 are written on paper or in a plain text file, without Git and without the textbook.
3. **Part 3, generated repositories (gates 1 to 5 and 9).** From the course root, run the generator of variant A; it prints the path of the sandbox. Open the lab shell there and read `SYMPTOMS.md`. Do not read `generate.sh`, which is the answer to "what happened", or `check.sh`, which lists the end state line by line. Keep a log of every command. When you think you are done, run `check.sh`.

   ```bash
   assessments/gen/gate-1-fundamentals/variant-a/generate.sh      # prints the sandbox path
   labs/shell "<the path it printed>"
   assessments/gen/gate-1-fundamentals/variant-a/check.sh         # PASS, or NOT YET with one line per condition
   ```

   The sandbox is `$GIT_MASTERY_LABS/gates/<name>` (`~/git-mastery-labs/gates/<name>` by default). Running the generator again deletes it and builds it afresh. A generator runs with the fixed lab clock, so the commit IDs in your sandbox equal the IDs in the answer key; commits that you make in the lab shell use the real clock and get other IDs.
4. **Part 3, paper cases (gates 6 to 8).** Open `CASES.md` of variant A and the files beside it. These gates run nothing on GitHub: no GitHub output appears anywhere in them, and the only `gh` invocation you need is `gh <command> --help`. The workflow files in these directories are teaching material with faults on purpose. Never copy them into a repository, and never run them.
5. **Part 4** needs a second person or the tutor, who asks each question, waits for the answer, asks the follow-up, and scores with the answer key. If you rehearse alone, record yourself and score the recording the next day. The [interview protocol](../interview/interview-mode-protocol.md) describes how an oral session is run.
6. **Scoring.** The examiner scores with the answer key in `answer-keys/`. You do not open the key yourself before the gate is scored. Enter the points in the score sheet at the end of the gate file.

## How the hands-on part is scored

For the generated repositories the points are split three ways, as the roadmap prescribes: the end state, the safety of the path, and the explanation.

- **End state.** `check.sh` inspects the sandbox with read-only commands and prints one line per condition, then `PASS` (exit status 0) or `NOT YET` (exit status 1). On a freshly generated sandbox every check script fails; that is tested. Each failed line costs one point.
- **Safety of the path.** Your command log is read: evidence before change, a way back before each rewrite, no command that could destroy uncommitted or shared work where a safer one exists. A correct end state reached through `git reset --hard`, a forced push or a re-clone can still fail this row.
- **Explanation.** What `SYMPTOMS.md` asks you to write: root causes in the form of the root-cause box of [Chapter 1](../textbook/ch01-fundamentals.md), section 1.10, and, in Gate 9, the summary for the CTO and the control.

For the paper cases the gate file gives the points per case.

## After a miss

A miss leads to remediation and a different variant. It does not lead to the answers.

1. The examiner gives you your score sheet and nothing from the answer key.
2. Use the **remediation map** at the end of the gate file: for every item on which you lost more than a third of the points, restudy the listed sections and redo the labs of the listed module.
3. Retake the whole gate after at least two days. Parts 1, 2 and 4 are asked again; the examiner varies the follow-ups and may ask you to explain an answer you got right. Part 3 is taken with **variant B**, which has a different project, a different state and different faults.
4. A second miss on the same gate means the block has to be studied again from its first module, with the exercises at Levels 3 to 5, before a third attempt.

## Files

| Path | What it is |
|---|---|
| `assessments/gate-N-<name>.md` | The gate: questions, score sheet, remediation map. No answers |
| `assessments/gen/gate-N-<name>/variant-a/`, `variant-b/` | Part 3. Gates 1 to 5 and 9: `generate.sh`, `SYMPTOMS.md`, `check.sh`. Gates 6 to 8: `CASES.md` and the case files |
| `assessments/gen/lib/` | Helpers shared by the generators and the check scripts |
| `answer-keys/gate-N-<name>.md` | For the examiner: model answers, marking guidance with partial credit, common wrong answers, textbook references, and the real outputs of every prediction item and every model solution |
| `labs/gates/` | The scripts behind every transcript: `gN-predict.sh` for part 2, `gN-evidence.sh` for the Git evidence in the paper cases, `solve-gN-a.sh` and `solve-gN-b.sh` for the model solutions |

## For maintainers

Every transcript in the gates and the keys is placed by `tools/inject.py` from a script that was run. `solve-gN-<variant>.sh` sources the generator, asserts that `check.sh` fails on the fresh state, replays the model solution and asserts that `check.sh` passes; a replay whose final check fails exits with a non-zero status.

```bash
tools/build-demos.sh gates                                         # run every script, regenerate labs/gates/out/
python3 tools/inject.py assessments/*.md assessments/gen/*/*/*.md answer-keys/gate-*.md
labs/verify-all.sh gates                                           # must print PASS for every script
GIT_MASTERY_LABS="$(mktemp -d)" labs/verify-all.sh gates           # the same with a fresh lab root
```

The gates use project names that no chapter, lab, exercise or incident uses: `tokmeter`, `shardmap`, `rerank-api`, `ingestd`, `chunker`, `quota-svc`, `modelcard-gen`, `latency-probe`, `corpus-sync`, `shardlog`, `storefront-api` and `cart-svc`. A new variant needs a new name.
