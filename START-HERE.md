# Git and GitHub Deep Mastery — start here

> **Baseline.** Git 2.55.0 on macOS; GitHub CLI 2.88.1; GitHub facts as of 1 October 2026.

## What this course is

A complete course in Git and GitHub for a working software engineer in AI/ML. Its goal is not a list of commands. It is the ability to sit with a CTO, investigate a Git or GitHub problem from first principles, explain the root cause, choose the lowest-risk fix, verify it, and prevent it from happening again.

Everything in this folder is the course, and all of it is written. Three properties hold throughout:

- **Local Git output is real.** Every transcript was produced by a script under `labs/` on Git 2.55.0 and placed in the text by a tool. You can replay each one and compare.
- **GitHub behavior is described, not captured.** Nothing in the course was run against GitHub with anyone's credentials. What GitHub does is described from its documentation as of 1 October 2026, with the link beside it. The interface may have changed since.
- **Git and GitHub are kept apart.** Wherever the two can be confused, the text says which layer a behavior belongs to.

The course has 43 modules (0 to 42) in twelve levels, and nine mastery gates. The [roadmap](curriculum/Git%20and%20GitHub%20mastery%20roadmap.md) is the plan; this page is the map of the files.

## How to start

1. Open a terminal in this folder.
2. Read [Chapter 1: Fundamentals](textbook/ch01-fundamentals.md), sections 1.6 to 1.9.
3. Do **Module 0**: [lab-manual/m00-lab-setup.md](lab-manual/m00-lab-setup.md). It takes about an hour, checks your toolchain, and sets up the sandbox that makes every later lab safe to break.
4. Go on with Module 1 and follow the reading order below. Each module runs the same way: read the chapter sections, do the labs by hand, answer the lab questions, do the exercises, and only then open the solutions.

## How to run labs

All three commands are run from this folder.

```bash
labs/shell m06
```

opens an isolated lab shell in the hands-on sandbox of Module 6. Your real Git configuration is never read or written there. The clock is real in this shell, so your commit IDs differ from the book.

```bash
labs/run ch08/lab-06-2-edit-edit-conflict
```

replays one demo or lab with a fixed identity and a fixed clock, so the output equals the transcript in the book, commit IDs included.

```bash
labs/verify-all.sh
```

re-runs every demo and lab and compares the output with the stored transcripts. Every line should say PASS. Give it a directory name (`labs/verify-all.sh ch08`) to check one chapter.

**Where sandboxes go.** The file `tools/.labroot` currently points sandboxes at a temporary folder. Delete that file to use the default, `~/git-mastery-labs`; the environment variable `GIT_MASTERY_LABS` overrides both. In transcripts, `$LAB` stands for this lab root.

**GitHub-side labs** run in your normal shell, not in `labs/shell`, and each one says so at its top. They cannot be replayed locally.

[lab-manual/README.md](lab-manual/README.md) explains the eleven parts of every lab and the rules for working through them.

## The rule about solutions and answer keys

Solutions and answer keys are read only after an attempt.

- Write your own answer to a lab question or an exercise before you open the file in `solutions/`.
- Do not open a gate file to see what is in it: a gate that has been read has been taken.
- The files in `answer-keys/` are for the examiner. You do not open a key before the gate or the final test is scored.
- In the generated hands-on tasks, `generate.sh` is the answer to "what happened" and `check.sh` lists the end state. Read `SYMPTOMS.md` and nothing else.
- In interview practice, answer aloud first, then answer the follow-up, and only then read the model answer.

## How gates work

A gate is an examination at the end of a block of modules. It decides whether you go on.

| Gate | File | Pass at | Taken after |
|---|---|---|---|
| 1 Fundamentals | [assessments/gate-1-fundamentals.md](assessments/gate-1-fundamentals.md) | 85 | Module 5 |
| 2 Branching | [assessments/gate-2-branching.md](assessments/gate-2-branching.md) | 90 | Module 7 |
| 3 Merge and rebase | [assessments/gate-3-merge-and-rebase.md](assessments/gate-3-merge-and-rebase.md) | 90 | Module 10 |
| 4 Recovery | [assessments/gate-4-recovery.md](assessments/gate-4-recovery.md) | 90 | Module 15 |
| 5 Internals | [assessments/gate-5-internals.md](assessments/gate-5-internals.md) | 85 | Module 18 |
| 6 GitHub | [assessments/gate-6-github.md](assessments/gate-6-github.md) | 85 | Module 25 |
| 7 Actions | [assessments/gate-7-actions.md](assessments/gate-7-actions.md) | 85 | Module 28 |
| 8 Security | [assessments/gate-8-security.md](assessments/gate-8-security.md) | 90 | Module 31 |
| 9 Production debugging | [assessments/gate-9-production-debugging.md](assessments/gate-9-production-debugging.md) | 90 | Module 38 |

Every gate has 100 points in four parts: concepts (30), prediction (20), hands-on diagnosis (30) and an oral interview (20). You pass with the threshold of the gate overall **and** at least 70% in every part. The hands-on part of gates 1 to 5 and 9 is a repository that a script builds in a broken state; gates 6 to 8 use cases on paper and run nothing on GitHub. A miss leads to the remediation map at the end of the gate file and to a retake with variant B after at least two days. It does not lead to the answers. [assessments/README.md](assessments/README.md) has the full procedure.

After the ninth gate come the [final test](assessments/final-test.md) (Module 40), the [capstone](capstone/README.md) (Module 41) and the oral series from the [question bank](interview/cto-question-bank.md) (Module 39).

## The textbook, in reading order

Thirty-five chapter files. The order below is the order of the modules, which is not the order of the chapter numbers.

| Step | Chapter | What it gives you | Modules |
|---|---|---|---|
| 1 | [1: Fundamentals](textbook/ch01-fundamentals.md) | What version control is for, the toolchain, the lab, the risk labels, the root-cause box | 0 |
| 2 | [2: The Mental Model](textbook/ch02-mental-model.md) | Blobs, trees, commits and refs, by building a commit by hand | 1 |
| 3 | [4: The Working Tree](textbook/ch04-working-tree.md) | Tracked, untracked and ignored files; restore, clean and what they destroy | 2 |
| 4 | [5: The Index](textbook/ch05-index.md) | The staging area as a file: entries, stages, flag bits, the lock | 2, 17 |
| 5 | [6: Commits](textbook/ch06-commits.md) | A commit as a snapshot plus metadata; identity, dates, messages, amend | 3 |
| 6 | [7: Branches](textbook/ch07-branches.md) | A branch is a ref; HEAD, detached HEAD, ancestry, stale branches | 4 |
| 7 | [14B: Configuration, Aliases, Tags and Signing](textbook/ch14b-config-tags-signing.md) | Configuration scopes, the settings to decide deliberately, tags, signatures | 5, 13, 24 |
| 8 | [8: Merge](textbook/ch08-merge.md) | Merge bases, fast-forward, three-way merge, conflicts and their stages | 6 |
| 9 | [12: Remote Operations](textbook/ch12-remote-operations.md) | Remotes, remote-tracking branches, fetch, pull, push, forced pushes | 7 |
| 10 | [11: Reset, Revert, Restore](textbook/ch11-reset-revert-restore.md) | The undo commands, each defined by the places it writes to | 8 |
| 11 | [9: Rebase](textbook/ch09-rebase.md) | Replaying commits; interactive rebase; publishing a rebased branch | 9 |
| 12 | [10: Cherry-pick](textbook/ch10-cherry-pick.md) | Copying a change between branches; backports; revert as the inverse | 10 |
| 13 | [14A: History investigation](textbook/ch14a-history-investigation.md) | Range notation, log, blame, pickaxe, bisect | 10, 11 |
| 14 | [13: Recovery](textbook/ch13-recovery.md) | The reflog, `git fsck`, the disaster recoveries, and what cannot be recovered | 12 |
| 15 | [14C: Stash Internals, Rerere, Attributes, Hooks](textbook/ch14c-stash-rerere-attributes-hooks.md) | What a stash is made of; recorded resolutions; attributes; hooks | 14 |
| 16 | [25: Worktrees](textbook/ch25-worktrees.md) | Several working trees on one repository | 14 |
| 17 | [23: Submodules and Subtrees](textbook/ch23-submodules.md) | Two ways to carry another project inside yours | 15 |
| 18 | [22: Git LFS](textbook/ch22-git-lfs.md) | Pointer files, filters, storage, limits and cost | 15 |
| 19 | [3: Git Internals](textbook/ch03-git-internals.md) | The object database, packfiles, ref storage, the files of `.git` | 16, 17 |
| 20 | [26: Performance](textbook/ch26-performance.md) | Maintenance, packing, partial and shallow clones, transfer | 16, 18 |
| 21 | [24: Monorepos](textbook/ch24-monorepos.md) | Sparse checkout and the tools for very large repositories | 18 |
| 22 | [15: GitHub](textbook/ch15-github.md) | The platform model: what is Git data and what is a GitHub object; the CLI and the APIs | 19, 25 |
| 23 | [16: Authentication](textbook/ch16-authentication.md) | Tokens, SSH keys, GitHub Apps, credential helpers | 20 |
| 24 | [17: Pull Requests](textbook/ch17-pull-requests.md) | What a pull request is in Git terms; forks; the three merge methods | 21, 22 |
| 25 | [18: Branch Protection and Rulesets](textbook/ch18-branch-protection.md) | Rulesets, classic protection, required checks and their traps | 23 |
| 26 | [19: CODEOWNERS](textbook/ch19-codeowners.md) | Ownership rules and how review requests follow from them | 23 |
| 27 | [20A: GitHub Actions Fundamentals](textbook/ch20a-actions-fundamentals.md) | Workflows, events, jobs, steps, contexts, artifacts, caches | 26 |
| 28 | [20B: GitHub Actions: delivery, runners, cost and debugging](textbook/ch20b-actions-delivery-debugging.md) | Environments, deployment, reusable workflows, runners, debugging a failed run | 27, 28 |
| 29 | [21A: GitHub Actions security](textbook/ch21a-actions-security.md) | The job token, privileged triggers, script injection, pinning actions | 29 |
| 30 | [21B: Repository security, identity, the Git client, and secret-leak response](textbook/ch21b-repository-security-incident-response.md) | Signing and verification, secret scanning, push protection, responding to a leaked secret | 24, 30, 31 |
| 31 | [27: Open source and team workflows](textbook/ch27-open-source-team-workflows.md) | Branching and release strategies, contributing through forks, team practices | 32, 34 |
| 32 | [28: AI/ML workflows](textbook/ch28-ai-ml-workflows.md) | Data, models, notebooks and experiments beside a Git repository | 33 |
| 33 | [29: Production Troubleshooting](textbook/ch29-production-troubleshooting.md) | The diagnosis method: evidence first, the lowest-risk fix, verification | 35 |
| 34 | [30: Incident Response](textbook/ch30-incident-response.md) | The incident loop, the ten incidents, communication and postmortems | 36, 37, 38 |
| 35 | [14D: The Frontier](textbook/ch14d-frontier.md) | Where Git is going, and how to read its primary sources | 42 |

## Every deliverable

| Deliverable | Path | What it is |
|---|---|---|
| Textbook | [textbook/](textbook/) | The 35 chapter files listed above |
| Lab manual | [lab-manual/](lab-manual/), starting with [README.md](lab-manual/README.md) | Lab files `mNN-<topic>.md` for Modules 0 to 38 and 42 (four modules have two files); every lab has the same eleven parts. Modules 39 to 41 are the interview series, the final test and the capstone |
| Runnable labs and demos | `labs/` | The scripts behind every transcript, with `labs/shell`, `labs/run` and `labs/verify-all.sh` |
| Solutions | [solutions/](solutions/) | Lab answers (`mNN-lab-answers.md`), exercise solutions (`exercises-mNN-mNN.md`), incident solutions (`incident-NN-<name>.md`) and the [capstone walkthrough](solutions/capstone-walkthrough.md). Read after an attempt |
| Exercises | [exercises/](exercises/) | Seven sets, from [Modules 1 to 5](exercises/m01-m05-foundations.md) to [Modules 32 to 34](exercises/m32-m34-practice.md); generators for hands-on tasks in `exercises/gen/`; workflow files to review in [exercises/workflows/](exercises/workflows/README.md) |
| Assessments | [assessments/](assessments/), starting with [README.md](assessments/README.md) | The nine gates and the [final test](assessments/final-test.md); generators and paper cases in `assessments/gen/` |
| Answer keys | [answer-keys/](answer-keys/) | One key per gate and [the key of the final test](answer-keys/final-test-answers.md). For the examiner |
| Incidents | [incidents/](incidents/), starting with [README.md](incidents/README.md) | Ten repositories, each built in a broken state by a script, with the report a colleague would give you |
| Capstone | [capstone/](capstone/), starting with [README.md](capstone/README.md) | Eight incidents at one fictional company; [DELIVERABLES.md](capstone/DELIVERABLES.md) says what you hand in and [EVALUATION.md](capstone/EVALUATION.md) how it is judged |
| Interview material | [interview/](interview/) | The [CTO question bank](interview/cto-question-bank.md) and its [answers](interview/cto-question-bank-answers.md), the [senior-engineer interview guide](interview/senior-engineer-interview-guide.md) and the [interview-mode protocol](interview/interview-mode-protocol.md) |
| Guides | [guides/](guides/) | The [GitHub Actions guide](guides/github-actions-guide.md) and the [security guide](guides/security-guide.md) |
| Playbooks | [playbooks/](playbooks/) | The [troubleshooting playbook](playbooks/troubleshooting-playbook.md) and the [disaster-recovery playbook](playbooks/disaster-recovery-playbook.md) |
| Reference | [reference/](reference/) | The [Git command reference](reference/git-command-reference.md), [command safety](reference/command-safety.md), the [GitHub reference](reference/github-reference.md), a [professional Git configuration](reference/professional-git-configuration.md), the [glossary](reference/glossary.md) and the [list of sources](reference/references.md) |
| Cheat sheets | [cheatsheets/](cheatsheets/) | [Git](cheatsheets/git-cheat-sheet.md), [GitHub CLI](cheatsheets/github-cli-cheat-sheet.md), [GitHub Actions](cheatsheets/github-actions-cheat-sheet.md), [security](cheatsheets/security-cheat-sheet.md) and the [emergency recovery page](cheatsheets/emergency-recovery-one-page.md) |
| Revision checklist | [revision/revision-checklist.md](revision/revision-checklist.md) | One page per mastery gate: what to explain, predict and redo before you take it |
| Workflows | [workflows/](workflows/) | Twelve numbered workflow files with a caller for the reusable one, the [action pins](workflows/ACTION_PINS.md), and two sets that are faulty on purpose for the labs: `workflows/broken/` and `workflows/vulnerable/`. Never copy the faulty ones into a repository you care about |
| Sample project | [sample-project/](sample-project/), starting with [README.md](sample-project/README.md) | `inventory-api`, the small Python and Java project that the Actions labs build, test and package |
| Research report (Phase 0) | [reports/Git and GitHub mastery research.md](reports/Git%20and%20GitHub%20mastery%20research.md) | The sourced research behind every version-sensitive fact in the course |
| Roadmap (Phase 1) | [curriculum/Git and GitHub mastery roadmap.md](curriculum/Git%20and%20GitHub%20mastery%20roadmap.md) | The 43 modules, the twelve levels, the nine gates, pacing and the progress tracker |

## When something is on fire

Three pages are written to be used under pressure, in this order: the [emergency recovery page](cheatsheets/emergency-recovery-one-page.md), the [disaster-recovery playbook](playbooks/disaster-recovery-playbook.md), and [command safety](reference/command-safety.md) before any command that carries a 🔴 label.

## Video course

| What | Where |
|---|---|
| Curriculum, 201 videos | [video/video-curriculum.md](video/video-curriculum.md) |
| Narration scripts, one per video | `video/scripts/` |
| Thumbnails, one per video | `video/thumbnails/` |
| YouTube titles and descriptions | [video/youtube-metadata.md](video/youtube-metadata.md) |
| Slides, recording page and video builder | `video/production/`, guide in [video/production/README.md](video/production/README.md) |

To make a video, record your voice with `video/production/make.sh record V001`, then build it with `video/production/make.sh build V001`. The finished MP4, subtitles and chapter timestamps land in `video/production/out/`. Encoding needs `ffmpeg`.
