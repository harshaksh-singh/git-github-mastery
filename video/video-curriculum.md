# Video curriculum: Git and GitHub Deep Mastery

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. This file is the plan for the video course: 201 videos, 4478 minutes (about 75 hours). It contains no scripts. Script writers work from the entries in section 6, in the batches of [script-batches.md](script-batches.md).

## 1. Course overview

### 1.1 What the video course is

The videos accompany the finished written course. They do not replace it and they add no facts to it. Each video takes one cluster of concepts from the textbook and teaches it the way a professor who is also a Staff Engineer would at a whiteboard and a terminal: why the thing exists, what it is, how it works inside `.git` or on GitHub, when to use it, when not to, how it fails, and how to recover. A video that only shows which command to type has failed its purpose.

The sequence follows the [roadmap](../curriculum/Git%20and%20GitHub%20mastery%20roadmap.md): 43 modules (0 to 42) in 12 levels, with nine mastery gates. The videos are grouped into twelve parts, one per level. A short gate briefing stands before each of the nine gates, and a design-review briefing closes Level 8, where the roadmap sets a design review in place of a gate.

### 1.2 Audience

One viewer: a working Software Engineer in AI/ML (LLM applications, model evaluation, data pipelines, Python, Java, backend services, Docker, CI/CD, open source) on a Mac with Git 2.55.0. The goal is not to know commands. It is to sit with a CTO, investigate a Git or GitHub problem from first principles, explain the root cause, choose the lowest-risk fix, verify it, and prevent recurrence. Examples come from backend and AI/ML teams, as they do in the textbook.

### 1.3 Prerequisites

- Comfort in a terminal: changing directories, reading files, running a script.
- A Mac with Git 2.55.0 and the course folder. Part 0 verifies the toolchain and builds the lab sandbox; nothing else has to be installed before V001.
- For Parts 5 to 7, a GitHub account, a free practice organization and public practice repositories that the learner creates in Part 5. The course never asks for credentials to be typed into a script.
- No earlier Git knowledge is assumed. Learners with years of Git use still start at V001, because Parts 0 and 1 replace the usual mental models with the object model that every later explanation depends on.

### 1.4 How a video relates to the textbook, the labs, the exercises and the gates

| Material | Where | Role next to a video |
|---|---|---|
| Textbook | [`textbook/`](../textbook/) | The source of every statement. Each video cites the sections it teaches. Read them before or directly after watching; the video is the lecture, the chapter is the reference |
| Demos and lab replays | `labs/<dir>/<name>.sh`, transcripts in `labs/<dir>/out/<name>/` | The only source of terminal output shown on screen. Every demonstration names its scripts exactly |
| Lab manual | [`lab-manual/`](../lab-manual/README.md) | The "Practical exercise" of most videos: the learner types the lab by hand in `labs/shell` after watching |
| Exercises | [`exercises/`](../exercises/) | Levels 1 to 5 per module. Practical exercises use Levels 1 to 3; challenges use Levels 3 to 5 |
| Incidents | [`incidents/`](../incidents/README.md) | Ten generated broken repositories. Used as challenges from Part 2 on and as the subject of Part 9 |
| Capstone | [`capstone/`](../capstone/README.md) | Eight stages at a fictional company. Used as challenges late in the course and as the subject of Part 10 |
| Question bank | [`interview/cto-question-bank.md`](../interview/cto-question-bank.md) | One question per video, quoted with its number. The learner answers aloud before opening the answers file |
| Gates | [`assessments/`](../assessments/README.md) | Nine examinations. A gate briefing explains scope, rules and preparation. It never shows a gate item |

The order inside one study unit is fixed: watch the video, read the cited sections, do the practical exercise by hand, answer the interview question aloud, do the homework, and only then attempt the challenge. Answers to labs, exercises and questions are in separate files and are opened after an attempt, never before. The videos keep that rule: no video shows the solution of a lab's "Questions" part, of an exercise, of an incident, of a gate or of a capstone stage. Where a demonstration replays a lab or an incident, it stops before the part the learner has to work out, or the entry says that the video is to be watched after the attempt.

### 1.5 The twelve fields of an entry

| Field | Content |
|---|---|
| Title | The title on screen |
| Learning objectives | Three to five things the learner can do afterwards, each of which can be checked |
| Prerequisites | Earlier videos, by number |
| Concepts | What the lecture has to explain, in the textbook's terms |
| Commands | Commands shown on screen. Only commands that the cited textbook sections teach |
| Demonstration | The scripts under `labs/` to replay, and what to point at in their output. For GitHub: the lab the screen walkthrough follows |
| Diagrams | The diagram of a textbook section to redraw, or a short description of a new one |
| Practical exercise | One lab or exercise, by number |
| Challenge | A harder exercise, an incident or a capstone stage |
| Interview question | One question from the bank, with its number |
| Homework | Reading, repetition or writing between this video and the next |
| Expected outcome | What the learner can now do or explain that was out of reach before |

## 2. Production notes common to all videos

### 2.1 Accuracy rules

The [authoring style guide](../authoring/STYLE_GUIDE.md) binds the videos as it binds the book. For scripts and recordings this means:

1. **Every on-screen command comes from a named demo script.** A demonstration is the replay of one or more scripts under `labs/`, named in the entry. The presenter does not improvise commands. If a script writer needs a command that no script contains, the request goes back to the textbook authors; the command is not typed live.
2. **Terminal output is never typed, edited or reconstructed.** What is shown is the transcript in `labs/<dir>/out/<name>/`, which `labs/verify-all.sh` compares with a fresh run. Run `labs/verify-all.sh <dir>` on the recording machine on the recording day; every line has to say PASS, or VOLATILE for the scripts whose names end in `-volatile`. For a volatile script (fresh keys, a local LFS server), say on screen that the IDs differ on every run.
3. **Commit IDs are read from the screen, not from memory.** Because replays use the fixed clock, the IDs in the recording equal the IDs in the book. Say so once per part, since learners compare.
4. **Label the layer.** Say whether a behavior belongs to Git, to GitHub or to GitHub Actions whenever confusion is possible, and show the lower-third label of section 2.4.
5. **No new facts.** A version, date, default, limit, price, plan gate, interface label or action version is said only if the cited section says it, in the cited section's words. Features of Git 2.56 are mentioned as "added in Git 2.56, not run here", as the textbook does.
6. **GitHub is not captured.** The authors captured no GitHub output. GitHub-side demonstrations are screen walkthroughs of the learner's own practice repository, following the named lab. Each such segment opens with the reminder that the interface changes and that the lab's text and the linked documentation are the reference. Never show a real token, key, private repository or another person's account. GitHub-side labs run in the learner's normal shell and not in `labs/shell`, because the lab shell switches off the system configuration where the credential helper lives.
7. **Terminology** follows section 9 of the style guide: commit ID or object ID, the index (also called the staging area), working tree, ref, remote-tracking branch, upstream branch, fast-forward, merge base, reflog, HEAD in capitals, `main` as the example default branch. `git switch` and `git restore` are preferred; the `git checkout` equivalent is shown once where the cited section shows it.

### 2.2 Terminal setup

| Item | Setting |
|---|---|
| Replays (what is recorded) | `labs/run <dir>/<name>` from the course root. Fixed identity, fixed clock, isolated configuration. The sandbox stays in `$LAB/<dir>/<name>` for inspection after the replay |
| Hands-on segments | `labs/shell mNN` opens an isolated shell in `$LAB/hands-on/mNN`. The clock is real there, so IDs differ from the book. Use it on screen only to show the learner where the practical exercise is typed, and say that the IDs will differ |
| Incident and capstone sandboxes | Built by their `generate.sh` or `setup.sh`, entered with `labs/shell "<path>"` |
| The fixed clock | Starts Monday 7 September 2026, 10:00 +05:30, and advances one minute per command. The sandbox sets `gc.reflogExpire=never` and `gc.reflogExpireUnreachable=never`. V001 explains why; later videos only remind |
| Never on screen | The presenter's real `~/.gitconfig`, real remotes, real credentials. The lab environment never reads or writes them |
| Pace | A replay prints faster than a viewer reads. Record the replay, then step through the transcript snippet by snippet in the edit, holding each snippet long enough to read aloud the lines the entry names |
| Shell prompt | The transcripts print `$ ` before each command and `$LAB` for the lab root. Keep that form; do not show a decorated personal prompt |

### 2.3 Font and layout

These are production conventions of this video course, chosen for legibility. They are not Git facts.

- Resolution 1920 by 1080. A monospaced font for terminal and code at a size that leaves at most 100 columns and 30 rows visible, so that a transcript snippet of about 40 lines is shown in two halves and never shrunk.
- Dark terminal background with high-contrast text. No transparency, no background image.
- Three layouts only: **terminal** (full screen, with the script name `labs/<dir>/<name>.sh` and the snippet name in a caption bar at the top), **diagram** (full screen), and **split** (diagram on the left, terminal on the right) for the moments where a command changes the picture.
- Diagrams are redrawn from the textbook's ASCII diagrams with the same orientation: time flows left to right, refs are labels beside commits, HEAD is always drawn, the three trees are three boxes side by side, and each repository of a remote setup is its own box. When a diagram illustrates a transcript, it carries the abbreviated commit IDs of that transcript.
- State tables (working tree, index, HEAD, current branch ref, other refs and files in `.git`, remote, GitHub) are shown as a table after every state-changing command that the cited section gives a table for.
- A root-cause box is shown in the seven-line form of section 1.10 of the textbook, one line at a time.

### 2.4 Risk-label colors and layer labels

The first time a state-changing command appears in a video, its risk label appears beside it and stays for the whole segment. The colors are the textbook's three labels and nothing else on screen uses them.

| Label | Color on screen | Meaning (textbook section 1.8) |
|---|---|---|
| 🟢 SAFE | Green | Reads state or only adds objects |
| 🟡 CAUTION | Amber | Moves refs or rewrites local history; recoverable through the reflog if you know how |
| 🔴 DANGEROUS | Red | Can destroy uncommitted work, remote history, or the safety net itself |

Before any 🔴 command the presenter answers the five questions aloud: what it changes, what it can destroy, how to preview it, how to recover, when it is appropriate. The command is not run on screen until the five answers have been given.

A lower-third label names the acting layer in neutral colors: **Git**, **GitHub**, **GitHub Actions**. It is shown whenever the narration crosses from one layer to another.

### 2.5 The shape of every video

| Segment | Share of the running time | Content |
|---|---|---|
| The question | 5% | The production question from the chapter's "Why this matters" section, asked the way a CTO would ask it |
| The model | 30% | The concept ladder of the textbook: in one sentence, analogy and where it breaks, precisely, inside `.git` |
| The demonstration | 35% | The named scripts, snippet by snippet, with a prediction asked before each revealing command |
| Failure and recovery | 20% | What can go wrong, how to diagnose it, how to fix it, how to prevent it; when not to use the technique |
| Close | 10% | The practical exercise, the interview question read aloud without an answer, the homework |

Prediction before output is the teaching device of the whole course: the presenter states the state, asks what the next command will print and change, pauses, and only then shows the output.

### 2.6 What a script writer receives and returns

A script writer receives one batch of entries, the cited chapters, and the transcripts of the named scripts. The script quotes transcript lines from `labs/<dir>/out/<name>/` by snippet name and adds no terminal output of its own. The estimated minutes are plans; a script may move by a fifth in either direction, and a video that would exceed 30 minutes is split at a concept boundary and reported back.

## 3. Master table

201 videos, 4478 minutes (about 75 hours).

| No. | Title | Part | Module | Textbook sections | Min |
|---|---|---|---|---|---|
| V001 | How this course works: the book, the lab sandbox and the fixed clock | 0 | 0 | [Ch. 1](../textbook/ch01-fundamentals.md) 1.1, 1.7, 1.8 | 16 |
| V002 | What version control solves, and Git the tool versus GitHub the platform | 0 | 0, 1 | [Ch. 1](../textbook/ch01-fundamentals.md) 1.2, 1.3, 1.4, 1.5, 1.6 | 18 |
| V003 | A first repository, read file by file | 0 | 0 | [Ch. 1](../textbook/ch01-fundamentals.md) 1.9 | 22 |
| V004 | The root-cause framework | 0 | 0 | [Ch. 1](../textbook/ch01-fundamentals.md) 1.10, 1.13 | 16 |
| V005 | The ten-command diagnosis | 0 | 0 | [Ch. 1](../textbook/ch01-fundamentals.md) 1.11 | 22 |
| V006 | Worked example: the fix that was committed and did not ship | 0 | 0 | [Ch. 1](../textbook/ch01-fundamentals.md) 1.12, 1.13, 1.14 | 20 |
| V007 | Snapshots, not diffs, and content addressing | 1 | 1 | [Ch. 2](../textbook/ch02-mental-model.md) 2.2, 2.3, 2.4 | 24 |
| V008 | The four object types, and a commit built by hand | 1 | 1 | [Ch. 2](../textbook/ch02-mental-model.md) 2.5, 2.6 | 26 |
| V009 | The commit graph, reachability, refs and HEAD | 1 | 1 | [Ch. 2](../textbook/ch02-mental-model.md) 2.7, 2.8, 2.13 | 24 |
| V010 | Three trees, two views of a commit, and the wrong mental models | 1 | 1 | [Ch. 2](../textbook/ch02-mental-model.md) 2.9, 2.10, 2.11, 2.12 | 20 |
| V011 | The working tree, three categories of file, and the anatomy of git status | 1 | 2 | [Ch. 4](../textbook/ch04-working-tree.md) 4.2, 4.3, 4.4 | 22 |
| V012 | Ignore rules and the already-tracked trap | 1 | 2 | [Ch. 4](../textbook/ch04-working-tree.md) 4.5, 4.6 | 24 |
| V013 | git restore, git mv, git rm, and why Git records no renames | 1 | 2 | [Ch. 4](../textbook/ch04-working-tree.md) 4.7, 4.8, 4.9 | 22 |
| V014 | File modes, empty directories, the case-insensitive filesystem, line endings, and git clean | 1 | 2 | [Ch. 4](../textbook/ch04-working-tree.md) 4.10, 4.11, 4.12, 4.13, 4.14 | 26 |
| V015 | The index: the proposed next commit, and what git add writes | 1 | 2 | [Ch. 5](../textbook/ch05-index.md) 5.2, 5.3 | 22 |
| V016 | Three diffs, partial staging with git add -p, and intent to add | 1 | 2 | [Ch. 5](../textbook/ch05-index.md) 5.4, 5.5, 5.6 | 26 |
| V017 | Staging deletions and renames, the scope of git add, and unstaging three ways | 1 | 2 | [Ch. 5](../textbook/ch05-index.md) 5.7, 5.8, 5.9, 5.10 | 26 |
| V018 | Reading the index: git ls-files, the two bits that are not an ignore mechanism, the stat cache, and the lock | 1 | 2 | [Ch. 5](../textbook/ch05-index.md) 5.11, 5.12, 5.13, 5.14, 5.15 | 24 |
| V019 | What a commit is, how git commit creates it, and the commit ID | 1 | 3 | [Ch. 6](../textbook/ch06-commits.md) 6.2, 6.3, 6.4 | 24 |
| V020 | Author and committer, two dates, and parents | 1 | 3 | [Ch. 6](../textbook/ch06-commits.md) 6.5, 6.6, 6.13 | 22 |
| V021 | Amend, empty commits, trailers, messages and atomic commits | 1 | 3 | [Ch. 6](../textbook/ch06-commits.md) 6.7, 6.8, 6.9, 6.10, 6.11, 6.12, 6.13 | 26 |
| V022 | A branch is a ref, HEAD is a symbolic ref, and what a commit does to the current branch | 1 | 4 | [Ch. 7](../textbook/ch07-branches.md) 7.2, 7.3, 7.4 | 22 |
| V023 | git branch and git switch | 1 | 4 | [Ch. 7](../textbook/ch07-branches.md) 7.5, 7.6 | 22 |
| V024 | Detached HEAD | 1 | 4 | [Ch. 7](../textbook/ch07-branches.md) 7.7 | 20 |
| V025 | Divergence, ancestry, and why Git has no parent-branch concept | 1 | 4 | [Ch. 7](../textbook/ch07-branches.md) 7.8, 7.9, 7.10 | 22 |
| V026 | Lightweight tags, branch names, and stale branches | 1 | 4 | [Ch. 7](../textbook/ch07-branches.md) 7.11, 7.12, 7.13, 7.14, 7.15 | 22 |
| V027 | Configuration: scopes, precedence, and reading and writing settings | 1 | 5 | [Ch. 14B](../textbook/ch14b-config-tags-signing.md) 14B.2, 14B.3 | 22 |
| V028 | Conditional includes, the settings to decide deliberately, aliases, and environment variables for diagnosis | 1 | 5 | [Ch. 14B](../textbook/ch14b-config-tags-signing.md) 14B.4, 14B.5, 14B.6, 14B.7 | 26 |
| V029 | Gate briefing: Fundamentals | 1 | 5 | [Ch. 1](../textbook/ch01-fundamentals.md) 1.10, 1.11; [Ch. 2](../textbook/ch02-mental-model.md) 2.11 | 10 |
| V030 | Divergence, the merge base, and fast-forward | 2 | 6 | [Ch. 8](../textbook/ch08-merge.md) 8.2, 8.3 | 20 |
| V031 | The true merge: three inputs, one rule table, and criss-cross histories | 2 | 6 | [Ch. 8](../textbook/ch08-merge.md) 8.4, 8.5 | 24 |
| V032 | Strategies, strategy options, and exactly why conflicts occur | 2 | 6 | [Ch. 8](../textbook/ch08-merge.md) 8.6, 8.7 | 22 |
| V033 | Anatomy of a conflict: working tree, index and .git, and the conflict styles | 2 | 6 | [Ch. 8](../textbook/ch08-merge.md) 8.8, 8.9 | 26 |
| V034 | The resolution workflow: abort, continue, quit, and restoring one side | 2 | 6 | [Ch. 8](../textbook/ch08-merge.md) 8.10, 8.19 | 24 |
| V035 | Conflict types beyond content: renames, modify/delete, add/add, binary, directories | 2 | 6 | [Ch. 8](../textbook/ch08-merge.md) 8.11 | 26 |
| V036 | Controlling the result: --ff-only, --no-ff, --squash, the merge commit, first-parent history and octopus merges | 2 | 6 | [Ch. 8](../textbook/ch08-merge.md) 8.12, 8.13, 8.14 | 24 |
| V037 | Clean for Git, wrong for humans: auditing a merge, and git merge-tree | 2 | 6 | [Ch. 8](../textbook/ch08-merge.md) 8.15, 8.16, 8.17, 8.18 | 26 |
| V038 | What a remote is, and git clone step by step | 2 | 7 | [Ch. 12](../textbook/ch12-remote-operations.md) 12.2, 12.3 | 24 |
| V039 | git fetch: which refs move | 2 | 7 | [Ch. 12](../textbook/ch12-remote-operations.md) 12.4 | 20 |
| V040 | Upstream branches, push.default, and git pull as fetch plus one integration step | 2 | 7 | [Ch. 12](../textbook/ch12-remote-operations.md) 12.5, 12.6 | 26 |
| V041 | git push: asking another repository to move its refs | 2 | 7 | [Ch. 12](../textbook/ch12-remote-operations.md) 12.7, 12.9 | 28 |
| V042 | Forcing a push: what it destroys, the lease, and --force-if-includes | 2 | 7 | [Ch. 12](../textbook/ch12-remote-operations.md) 12.8 | 24 |
| V043 | More than one remote, pruning, and branches whose upstream is gone | 2 | 7 | [Ch. 12](../textbook/ch12-remote-operations.md) 12.10, 12.11, 12.16 | 24 |
| V044 | Refspecs in depth, transports, and two diagnoses from first principles | 2 | 7 | [Ch. 12](../textbook/ch12-remote-operations.md) 12.12, 12.13, 12.14 | 26 |
| V045 | Gate briefing: Branching | 2 | 7 | [Ch. 7](../textbook/ch07-branches.md) 7.8; [Ch. 12](../textbook/ch12-remote-operations.md) 12.4, 12.7 | 10 |
| V046 | The undo map and git restore | 2 | 8 | [Ch. 11](../textbook/ch11-reset-revert-restore.md) 11.2, 11.3 | 20 |
| V047 | git reset: the three modes, why --hard is dangerous, and the resets that check first | 2 | 8 | [Ch. 11](../textbook/ch11-reset-revert-restore.md) 11.4, 11.5, 11.6, 11.7 | 28 |
| V048 | git revert: a new commit that applies the inverse change | 2 | 8 | [Ch. 11](../textbook/ch11-reset-revert-restore.md) 11.8 | 20 |
| V049 | Reverting a merge, and the re-merge problem | 2 | 8 | [Ch. 11](../textbook/ch11-reset-revert-restore.md) 11.9 | 22 |
| V050 | git clean, and stash: uncommitted work parked as commits | 2 | 8 | [Ch. 11](../textbook/ch11-reset-revert-restore.md) 11.10, 11.11 | 24 |
| V051 | One table, one decision tree, and seven worked undo scenarios | 2 | 8 | [Ch. 11](../textbook/ch11-reset-revert-restore.md) 11.12, 11.13 | 18 |
| V052 | What a rebase is, and why every rebased commit has a new ID | 2 | 9 | [Ch. 9](../textbook/ch09-rebase.md) 9.2, 9.3 | 18 |
| V053 | What rebase does internally: the state directory, HEAD, and the special refs | 2 | 9 | [Ch. 9](../textbook/ch09-rebase.md) 9.4 | 20 |
| V054 | Choosing what moves and where it lands: upstream, --onto, --keep-base, --root | 2 | 9 | [Ch. 9](../textbook/ch09-rebase.md) 9.5 | 24 |
| V055 | Interactive rebase: reword, edit, squash, fixup, drop, reorder, exec, break | 2 | 9 | [Ch. 9](../textbook/ch09-rebase.md) 9.6 | 28 |
| V056 | Fixup commits, --autosquash, --autostash, stacked branches with --update-refs, and --rebase-merges | 2 | 9 | [Ch. 9](../textbook/ch09-rebase.md) 9.7, 9.8, 9.9, 9.10 | 28 |
| V057 | Conflicts during a rebase: who is "ours", the ways out, and commits that are already upstream | 2 | 9 | [Ch. 9](../textbook/ch09-rebase.md) 9.11, 9.12 | 26 |
| V058 | git pull --rebase, and reviewing a rebase with git range-diff | 2 | 9 | [Ch. 9](../textbook/ch09-rebase.md) 9.13, 9.14 | 20 |
| V059 | Rebasing a branch that other people use, and recovering from a bad rebase | 2 | 9 | [Ch. 9](../textbook/ch09-rebase.md) 9.15, 9.16 | 24 |
| V060 | Publishing a rebased branch, rebase or merge, and the rebase configuration | 2 | 9 | [Ch. 9](../textbook/ch09-rebase.md) 9.17, 9.18, 9.19, 9.20 | 26 |
| V061 | What cherry-pick does: a three-way merge that makes a new commit | 2 | 10 | [Ch. 10](../textbook/ch10-cherry-pick.md) 10.2, 10.3, 10.4, 10.5 | 24 |
| V062 | CHERRY_PICK_HEAD, the sequencer, conflicts, and picks that are already there | 2 | 10 | [Ch. 10](../textbook/ch10-cherry-pick.md) 10.6, 10.7, 10.8 | 24 |
| V063 | The backport workflow, duplicate commits, and revert as the inverse | 2 | 10 | [Ch. 10](../textbook/ch10-cherry-pick.md) 10.9, 10.10, 10.11 | 22 |
| V064 | Naming commits and sets of commits: revisions, A..B and A...B for git log and for git diff | 2 | 10 | [Ch. 14A](../textbook/ch14a-history-investigation.md) 14A.2, 14A.7, 14A.8 | 24 |
| V065 | Gate briefing: Merge and rebase | 2 | 10 | [Ch. 8](../textbook/ch08-merge.md) 8.4; [Ch. 9](../textbook/ch09-rebase.md) 9.4, 9.11; [Ch. 10](../textbook/ch10-cherry-pick.md) 10.7; [Ch. 11](../textbook/ch11-reset-revert-restore.md) 11.12 | 10 |
| V066 | Reading a diff: summaries, filters, computed renames, whitespace and algorithms | 3 | 11 | [Ch. 14A](../textbook/ch14a-history-investigation.md) 14A.3, 14A.4, 14A.5, 14A.6 | 22 |
| V067 | git log is a graph query: selection, filters, graph shape and output formats | 3 | 11 | [Ch. 14A](../textbook/ch14a-history-investigation.md) 14A.1, 14A.9, 14A.15 | 24 |
| V068 | Set questions, git grep, and the retirement of git whatchanged | 3 | 11 | [Ch. 14A](../textbook/ch14a-history-investigation.md) 14A.14, 14A.23, 14A.24 | 20 |
| V069 | The history of one file: --follow, the pickaxe, line history, and deleted files | 3 | 11 | [Ch. 14A](../textbook/ch14a-history-investigation.md) 14A.10, 14A.11, 14A.12, 14A.13 | 28 |
| V070 | git blame: what a row asserts, reformatting commits, moved code, and a method for finding the origin of a bug | 3 | 11 | [Ch. 14A](../textbook/ch14a-history-investigation.md) 14A.16, 14A.17, 14A.18, 14A.19 | 26 |
| V071 | git bisect: binary search over commits | 3 | 11 | [Ch. 14A](../textbook/ch14a-history-investigation.md) 14A.20 | 20 |
| V072 | git bisect run, the exit-code protocol, custom terms, replay, --first-parent, and the pitfalls | 3 | 11 | [Ch. 14A](../textbook/ch14a-history-investigation.md) 14A.21, 14A.22 | 22 |
| V073 | What Git keeps: four layers of protection, and the reflog | 3 | 12 | [Ch. 13](../textbook/ch13-recovery.md) 13.2, 13.3 | 22 |
| V074 | Retention and its exceptions, ORIG_HEAD, and git fsck as a search tool | 3 | 12 | [Ch. 13](../textbook/ch13-recovery.md) 13.4, 13.5, 13.6 | 26 |
| V075 | The recovery method, and recovering commits I: a hard reset, a deleted branch, a deleted commit | 3 | 12 | [Ch. 13](../textbook/ch13-recovery.md) 13.7, 13.8 | 26 |
| V076 | Recovering commits II: a wrong rebase, a bad merge, the wrong branch, detached HEAD, a wrong cherry-pick | 3 | 12 | [Ch. 13](../textbook/ch13-recovery.md) 13.8 | 28 |
| V077 | Recovering uncommitted work, and recovering from the remote side | 3 | 12 | [Ch. 13](../textbook/ch13-recovery.md) 13.9, 13.10 | 24 |
| V078 | A damaged repository, and what cannot be recovered | 3 | 12 | [Ch. 13](../textbook/ch13-recovery.md) 13.11, 13.12 | 20 |
| V079 | The point of no return, prevention with backup refs and bundles, and what GitHub adds | 3 | 12 | [Ch. 13](../textbook/ch13-recovery.md) 13.13, 13.14, 13.15 | 22 |
| V080 | Tags: three kinds, two mechanisms, listing, and how tags travel | 3 | 13 | [Ch. 14B](../textbook/ch14b-config-tags-signing.md) 14B.8, 14B.9, 14B.10 | 22 |
| V081 | Why a published tag must not move | 3 | 13 | [Ch. 14B](../textbook/ch14b-config-tags-signing.md) 14B.11 | 18 |
| V082 | git describe, Semantic Versioning, and release branches on the Git side | 3 | 13 | [Ch. 14B](../textbook/ch14b-config-tags-signing.md) 14B.12, 14B.13, 14B.14 | 22 |
| V083 | Linked worktrees: what they are, what is shared, and one branch per worktree | 3 | 14 | [Ch. 25](../textbook/ch25-worktrees.md) 25.2, 25.3, 25.4 | 20 |
| V084 | Worktrees in use: the hotfix during a rebase, reviewing a branch, the life cycle, and the pitfalls | 3 | 14 | [Ch. 25](../textbook/ch25-worktrees.md) 25.5, 25.6, 25.7 | 24 |
| V085 | Stash internals: a stash entry is a small commit graph | 3 | 14 | [Ch. 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md) 14C.2 | 16 |
| V086 | Rerere: resolve a conflict once | 3 | 14 | [Ch. 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md) 14C.3 | 24 |
| V087 | .gitattributes: per-path settings that travel, and line endings | 3 | 14 | [Ch. 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md) 14C.4, 14C.5 | 20 |
| V088 | Diff drivers, merge drivers, and clean and smudge filters | 3 | 14 | [Ch. 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md) 14C.6, 14C.7, 14C.8 | 26 |
| V089 | Hooks: programs that Git runs at fixed points | 3 | 14 | [Ch. 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md) 14C.9, 14C.10 | 24 |
| V090 | --no-verify, core.hooksPath, sharing hooks, hook security, and why hooks cannot enforce policy | 3 | 14 | [Ch. 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md) 14C.11, 14C.12, 14C.13 | 22 |
| V091 | Submodules: a gitlink, .gitmodules, and what a teammate receives | 3 | 15 | [Ch. 23](../textbook/ch23-submodules.md) 23.2, 23.3, 23.4 | 24 |
| V092 | Submodules in motion: the detached HEAD, moving the pointer, the stale submodule and the silent rollback | 3 | 15 | [Ch. 23](../textbook/ch23-submodules.md) 23.5, 23.6, 23.7 | 24 |
| V093 | Submodule failures: push order, dirty submodules, pointer conflicts, removal, URL changes, and CI | 3 | 15 | [Ch. 23](../textbook/ch23-submodules.md) 23.8, 23.9, 23.10, 23.11, 23.12 | 28 |
| V094 | Subtrees, and choosing between a submodule, a subtree and a package manager | 3 | 15 | [Ch. 23](../textbook/ch23-submodules.md) 23.13, 23.14 | 20 |
| V095 | Git LFS: why it exists, the pointer file, the two filters, and tracking | 3 | 15 | [Ch. 22](../textbook/ch22-git-lfs.md) 22.2, 22.3, 22.4 | 22 |
| V096 | Git LFS day to day: status, pushing, cloning without the client, and the local store | 3 | 15 | [Ch. 22](../textbook/ch22-git-lfs.md) 22.5, 22.6, 22.7, 22.8 | 24 |
| V097 | git lfs migrate, the common LFS errors, GitHub's limits and billing, and when LFS is the wrong tool | 3 | 15, 33 | [Ch. 22](../textbook/ch22-git-lfs.md) 22.9, 22.10, 22.11, 22.13 | 26 |
| V098 | Gate briefing: Recovery | 3 | 15 | [Ch. 13](../textbook/ch13-recovery.md) 13.6, 13.7, 13.12 | 10 |
| V099 | The .git directory file by file, and the loose object format | 4 | 16, 17 | [Ch. 3](../textbook/ch03-git-internals.md) 3.2, 3.3 | 22 |
| V100 | The four object types in full, and reading objects with cat-file, ls-tree and show | 4 | 16 | [Ch. 3](../textbook/ch03-git-internals.md) 3.4, 3.5 | 22 |
| V101 | Turning names into IDs: git rev-parse | 4 | 17 | [Ch. 3](../textbook/ch03-git-internals.md) 3.6 | 14 |
| V102 | Packfiles, pack indexes and delta compression | 4 | 16 | [Ch. 3](../textbook/ch03-git-internals.md) 3.7 | 24 |
| V103 | Reachability, git fsck, and where Git checks its hashes | 4 | 16 | [Ch. 3](../textbook/ch03-git-internals.md) 3.8 | 22 |
| V104 | What makes a repository slow, git gc versus git maintenance, geometric repacking, and cruft packs | 4 | 16 | [Ch. 26](../textbook/ch26-performance.md) 26.2, 26.3, 26.4, 26.5 | 26 |
| V105 | Refs in depth: loose refs, packed-refs, symbolic refs, root refs, and reflog storage | 4 | 17 | [Ch. 3](../textbook/ch03-git-internals.md) 3.9, 3.10, 3.11 | 24 |
| V106 | The index file as a data structure | 4 | 17 | [Ch. 3](../textbook/ch03-git-internals.md) 3.12 | 20 |
| V107 | The reftable backend, and SHA-1 with collision detection versus SHA-256 | 4 | 17, 42 | [Ch. 3](../textbook/ch03-git-internals.md) 3.13, 3.14 | 22 |
| V108 | The commit-graph, the multi-pack-index, reachability bitmaps, and the working-tree accelerators | 4 | 18 | [Ch. 26](../textbook/ch26-performance.md) 26.6, 26.7, 26.8, 26.9 | 22 |
| V109 | The fetch conversation, shallow clones, partial clones, and choosing a clone | 4 | 18 | [Ch. 26](../textbook/ch26-performance.md) 26.10, 26.11, 26.12, 26.13 | 28 |
| V110 | Bundles, and when each scale feature matters | 4 | 18 | [Ch. 26](../textbook/ch26-performance.md) 26.14, 26.15 | 16 |
| V111 | Monorepo versus polyrepo, and sparse-checkout in cone mode | 4 | 18 | [Ch. 24](../textbook/ch24-monorepos.md) 24.2, 24.3, 24.4 | 20 |
| V112 | Living in a sparse checkout, and the sparse index | 4 | 18 | [Ch. 24](../textbook/ch24-monorepos.md) 24.5, 24.6 | 20 |
| V113 | Partial clone plus sparse-checkout, what scalar clone configures, and ownership, CI and releases in a monorepo | 4 | 18 | [Ch. 24](../textbook/ch24-monorepos.md) 24.7, 24.8, 24.9, 24.10, 24.11 | 24 |
| V114 | Gate briefing: Internals | 4 | 18 | [Ch. 3](../textbook/ch03-git-internals.md) 3.2, 3.5, 3.7, 3.8, 3.9; [Ch. 26](../textbook/ch26-performance.md) 26.3 | 10 |
| V115 | Git data and GitHub objects, accounts, roles, and the settings that matter | 5 | 19 | [Ch. 15](../textbook/ch15-github.md) 15.2, 15.3, 15.4, 15.5 | 24 |
| V116 | Forks and the fork network | 5 | 19 | [Ch. 15](../textbook/ch15-github.md) 15.6, 15.7 | 20 |
| V117 | Issues, Projects, Discussions, Packages, templates, health files, a professional layout, and limits | 5 | 19 | [Ch. 15](../textbook/ch15-github.md) 15.8, 15.9, 15.10, 15.11, 15.13, 15.14, 15.15, 15.19 | 26 |
| V118 | Authentication versus authorization, HTTPS, and how Git asks for a credential | 5 | 20 | [Ch. 16](../textbook/ch16-authentication.md) 16.2, 16.3, 16.4, 16.5 | 24 |
| V119 | Tokens: fine-grained, classic, what a prefix tells you, and why a token never goes into a URL | 5 | 20 | [Ch. 16](../textbook/ch16-authentication.md) 16.6, 16.7 | 16 |
| V120 | SSH: key pairs, the agent, ~/.ssh/config, host keys, and testing the connection | 5 | 20 | [Ch. 16](../textbook/ch16-authentication.md) 16.8, 16.9, 16.10, 16.11, 16.12 | 26 |
| V121 | Two identities on one machine, credentials for machines, single sign-on, and the SSH changes of 14 October 2026 and 13 January 2027 | 5 | 20 | [Ch. 16](../textbook/ch16-authentication.md) 16.13, 16.14, 16.15, 16.16 | 20 |
| V122 | Diagnosing authentication failures: who wrote this line, the SSH failures, the HTTPS failures, and a decision tree | 5 | 20 | [Ch. 16](../textbook/ch16-authentication.md) 16.17, 16.18, 16.19, 16.20 | 24 |
| V123 | What GitHub creates when a pull request opens, and what a pull request shows | 5 | 21 | [Ch. 17](../textbook/ch17-pull-requests.md) 17.2, 17.3 | 26 |
| V124 | The pull request lifecycle: draft, review, stale approvals, checks, mergeability, and conflicts | 5 | 21 | [Ch. 17](../textbook/ch17-pull-requests.md) 17.4, 17.5, 17.6, 17.7, 17.16 | 24 |
| V125 | Why a pull request shows unexpected commits or a huge diff | 5 | 21 | [Ch. 17](../textbook/ch17-pull-requests.md) 17.12 | 26 |
| V126 | Indirect merges and stacked pull requests | 5 | 21 | [Ch. 17](../textbook/ch17-pull-requests.md) 17.13, 17.14 | 20 |
| V127 | The fork workflow end to end, review practice, and display limits | 5 | 21, 34 | [Ch. 17](../textbook/ch17-pull-requests.md) 17.15, 17.17, 17.18 | 22 |
| V128 | The three merge methods: merge commit, squash and merge, rebase and merge | 5 | 22 | [Ch. 17](../textbook/ch17-pull-requests.md) 17.8 | 24 |
| V129 | What the merge method means later: bisect, blame, revert and traceability; auto-merge; the merge queue | 5 | 22 | [Ch. 17](../textbook/ch17-pull-requests.md) 17.9, 17.10, 17.11 | 24 |
| V130 | A Git tag versus a GitHub Release | 5 | 22 | [Ch. 15](../textbook/ch15-github.md) 15.12 | 18 |
| V131 | What a rule is, rulesets, layering, and bypass | 5 | 23 | [Ch. 18](../textbook/ch18-branch-protection.md) 18.2, 18.3, 18.4, 18.5 | 26 |
| V132 | The rules and their sub-options: required reviews, status checks and their traps, conversations, signatures, linear history | 5 | 23 | [Ch. 18](../textbook/ch18-branch-protection.md) 18.6, 18.7, 18.8, 18.9, 18.10, 18.11 | 28 |
| V133 | Tag rulesets, push rulesets, organization-level rulesets, classic branch protection, and plan gates | 5 | 23 | [Ch. 18](../textbook/ch18-branch-protection.md) 18.12, 18.13, 18.14, 18.15 | 20 |
| V134 | Seeing and managing rules, "why can't I merge?", and a worked design for a production branch | 5 | 23 | [Ch. 18](../textbook/ch18-branch-protection.md) 18.16, 18.17, 18.18 | 24 |
| V135 | CODEOWNERS: what it is, where it lives, syntax, and last match wins | 5 | 23 | [Ch. 19](../textbook/ch19-codeowners.md) 19.2, 19.3, 19.4, 19.5, 19.6 | 22 |
| V136 | CODEOWNERS in force: the base branch decides, protecting the file, monorepos, required reviewers, and finding out what GitHub thinks | 5 | 23 | [Ch. 19](../textbook/ch19-codeowners.md) 19.7, 19.8, 19.9, 19.10, 19.11, 19.12 | 22 |
| V137 | Signatures: what is signed, by which program, and SSH signing end to end | 5 | 24 | [Ch. 14B](../textbook/ch14b-config-tags-signing.md) 14B.15, 14B.16; [Ch. 6](../textbook/ch06-commits.md) 6.11 | 22 |
| V138 | What a signature covers, what verification proves, and author spoofing | 5 | 24, 30 | [Ch. 14B](../textbook/ch14b-config-tags-signing.md) 14B.17, 14B.18; [Ch. 21B](../textbook/ch21b-repository-security-incident-response.md) 21B.5 | 24 |
| V139 | Signatures on GitHub: the verification states and what "Verified" does not prove | 5 | 24 | [Ch. 21B](../textbook/ch21b-repository-security-incident-response.md) 21B.6, 21B.7 | 18 |
| V140 | The GitHub CLI, gh pr, gh api, the REST API and GraphQL, rate limits, webhooks and GitHub Apps | 5 | 25 | [Ch. 15](../textbook/ch15-github.md) 15.16, 15.17, 15.18; [Ch. 17](../textbook/ch17-pull-requests.md) 17.16 | 26 |
| V141 | Gate briefing: GitHub | 5 | 25 | [Ch. 15](../textbook/ch15-github.md) 15.2; [Ch. 17](../textbook/ch17-pull-requests.md) 17.3; [Ch. 18](../textbook/ch18-branch-protection.md) 18.17 | 10 |
| V142 | The Actions model, and YAML read carefully | 6 | 26 | [Ch. 20A](../textbook/ch20a-actions-fundamentals.md) 20A.2, 20A.3 | 22 |
| V143 | Events and filters, contexts and expressions, and env, vars and secrets | 6 | 26 | [Ch. 20A](../textbook/ch20a-actions-fundamentals.md) 20A.4, 20A.5, 20A.6 | 24 |
| V144 | Shells, and passing data between steps and jobs | 6 | 26 | [Ch. 20A](../textbook/ch20a-actions-fundamentals.md) 20A.7 | 18 |
| V145 | What actions/checkout does by default: one commit, no tags, and the merge ref | 6 | 26 | [Ch. 20A](../textbook/ch20a-actions-fundamentals.md) 20A.8 | 24 |
| V146 | Controlling jobs, matrix strategies, dependency caching, and artifacts | 6 | 26 | [Ch. 20A](../textbook/ch20a-actions-fundamentals.md) 20A.9, 20A.10, 20A.11, 20A.12 | 26 |
| V147 | Workflows 1 to 5, line by line: tests, lint, build, Python with uv, Java with Maven | 6 | 26 | [Ch. 20A](../textbook/ch20a-actions-fundamentals.md) 20A.13 | 28 |
| V148 | Workflows 6, 7 and 10, action versions and the Node 24 runtime, and the syntax added in 2025 and 2026 | 6 | 26, 27 | [Ch. 20A](../textbook/ch20a-actions-fundamentals.md) 20A.13, 20A.14, 20A.15 | 24 |
| V149 | Environments, deploying to staging, and promotion to production behind an approval | 6 | 27 | [Ch. 20B](../textbook/ch20b-actions-delivery-debugging.md) 20B.2, 20B.3, 20B.4 | 28 |
| V150 | Concurrency groups, reusable workflows, composite actions and container actions | 6 | 27 | [Ch. 20B](../textbook/ch20b-actions-delivery-debugging.md) 20B.5, 20B.6 | 24 |
| V151 | Publishing a container image, and release automation in outline | 6 | 27 | [Ch. 20B](../textbook/ch20b-actions-delivery-debugging.md) 20B.7 | 16 |
| V152 | Runners, limits and billing, and the investigation order for a failing workflow | 6 | 28 | [Ch. 20B](../textbook/ch20b-actions-delivery-debugging.md) 20B.8, 20B.9, 20B.10, 20B.11 | 26 |
| V153 | "Passes locally, fails on GitHub Actions": the documented causes | 6 | 28 | [Ch. 20B](../textbook/ch20b-actions-delivery-debugging.md) 20B.12 | 24 |
| V154 | Required checks that stay pending, the debugging instruments, linting, and what a local emulator cannot reproduce | 6 | 28 | [Ch. 20B](../textbook/ch20b-actions-delivery-debugging.md) 20B.13, 20B.14, 20B.15 | 24 |
| V155 | Gate briefing: Actions | 6 | 28 | [Ch. 20A](../textbook/ch20a-actions-fundamentals.md) 20A.8; [Ch. 20B](../textbook/ch20b-actions-delivery-debugging.md) 20B.11 | 10 |
| V156 | The Actions security model in five parts, the job token, and permissions | 7 | 29 | [Ch. 21A](../textbook/ch21a-actions-security.md) 21A.2, 21A.3 | 22 |
| V157 | Fork pull requests, the approval gate, and privileged triggers | 7 | 29 | [Ch. 21A](../textbook/ch21a-actions-security.md) 21A.4, 21A.5 | 26 |
| V158 | Script injection through untrusted event fields | 7 | 29 | [Ch. 21A](../textbook/ch21a-actions-security.md) 21A.6 | 20 |
| V159 | Third-party actions, mutable tags, commit pinning, and organization policies | 7 | 29 | [Ch. 21A](../textbook/ch21a-actions-security.md) 21A.7, 21A.8 | 22 |
| V160 | Secrets and why masking is not a boundary, OIDC federation, caches and artifacts as untrusted input, self-hosted runners, and environment protection | 7 | 29 | [Ch. 21A](../textbook/ch21a-actions-security.md) 21A.9, 21A.10, 21A.11, 21A.12, 21A.13 | 28 |
| V161 | Static analysis of workflows, the platform changes of 2025 and 2026, workflow 12, AI agents in workflows, and a review checklist | 7 | 29 | [Ch. 21A](../textbook/ch21a-actions-security.md) 21A.14, 21A.15, 21A.16, 21A.17, 21A.19 | 26 |
| V162 | Case studies in Actions security: what happened, root cause, lesson | 7 | 29 | [Ch. 21A](../textbook/ch21a-actions-security.md) 21A.7, 21A.18 | 20 |
| V163 | The Git client: what a clone runs, the three guards, and recursive clones | 7 | 30 | [Ch. 21B](../textbook/ch21b-repository-security-incident-response.md) 21B.2, 21B.3, 21B.4 | 22 |
| V164 | Credentials and what a stolen one can reach, and why deleting, force-pushing and going private do not remove a secret | 7 | 30 | [Ch. 21B](../textbook/ch21b-repository-security-incident-response.md) 21B.8, 21B.9, 21B.10, 21B.11 | 26 |
| V165 | Secret scanning and push protection and what they do not cover, Dependabot, code scanning, and a way to report vulnerabilities | 7 | 30 | [Ch. 21B](../textbook/ch21b-repository-security-incident-response.md) 21B.12, 21B.13 | 24 |
| V166 | Responding to a leaked secret: six steps in this order, and the case studies | 7 | 31 | [Ch. 21B](../textbook/ch21b-repository-security-incident-response.md) 21B.14, 21B.15 | 24 |
| V167 | History rewriting as an operation, and its mechanics seen locally | 7 | 31 | [Ch. 21B](../textbook/ch21b-repository-security-incident-response.md) 21B.16, 21B.17 | 28 |
| V168 | The stale clone that pushes the secret back, the GitHub side of a rewrite, and the controls that limit blast radius | 7 | 31 | [Ch. 21B](../textbook/ch21b-repository-security-incident-response.md) 21B.18, 21B.19, 21B.20 | 22 |
| V169 | Gate briefing: Security | 7 | 31 | [Ch. 21A](../textbook/ch21a-actions-security.md) 21A.2; [Ch. 21B](../textbook/ch21b-repository-security-incident-response.md) 21B.11, 21B.14 | 10 |
| V170 | The fork workflow in practice: syncing when upstream moves, etiquette, and the maintainer's side | 8 | 34, 21 | [Ch. 27](../textbook/ch27-open-source-team-workflows.md) 27.2, 27.3, 27.4 | 24 |
| V171 | Branch names as conventions, GitHub Flow, Git Flow and its author's 2020 note, GitLab Flow, trunk-based development and release branches | 8 | 32 | [Ch. 27](../textbook/ch27-open-source-team-workflows.md) 27.5, 27.6, 27.7, 27.8 | 24 |
| V172 | One release and one hotfix under two strategies, and which way a fix travels | 8 | 32 | [Ch. 27](../textbook/ch27-open-source-team-workflows.md) 27.9, 27.10 | 26 |
| V173 | Feature flags, merge queues and stacked changes, what the evidence shows, and choosing by context | 8 | 32 | [Ch. 27](../textbook/ch27-open-source-team-workflows.md) 27.11, 27.12, 27.13, 27.14 | 20 |
| V174 | Practices with their reasons, anti-patterns with their root causes, code review, and commit message conventions | 8 | 34 | [Ch. 27](../textbook/ch27-open-source-team-workflows.md) 27.15, 27.16, 27.17, 27.18 | 26 |
| V175 | What belongs in Git, notebooks, and a clean filter that strips outputs | 8 | 33 | [Ch. 28](../textbook/ch28-ai-ml-workflows.md) 28.2, 28.3, 28.4, 28.5 | 26 |
| V176 | Data and model versioning by reference, and reproducibility: the commit alone does not identify what ran | 8 | 33 | [Ch. 28](../textbook/ch28-ai-ml-workflows.md) 28.6, 28.7, 28.8 | 26 |
| V177 | .gitignore and .gitattributes for ML projects, pre-commit backed by CI, and a professional AI project repository | 8 | 33 | [Ch. 28](../textbook/ch28-ai-ml-workflows.md) 28.9, 28.10, 28.12 | 24 |
| V178 | CI for ML projects, LLM evaluations and the fork model, model-serving repositories, secrets, and AI coding agents | 8 | 33 | [Ch. 28](../textbook/ch28-ai-ml-workflows.md) 28.11, 28.13, 28.14, 28.15 | 22 |
| V179 | Design review briefing: branching model, governance, CI and security policy for a described company | 8 | 34 | [Ch. 18](../textbook/ch18-branch-protection.md) 18.18; [Ch. 27](../textbook/ch27-open-source-team-workflows.md) 27.14 | 12 |
| V180 | The diagnosis method, and worked case 1: the push that had nothing to push | 9 | 35 | [Ch. 29](../textbook/ch29-production-troubleshooting.md) 29.2, 29.3 | 26 |
| V181 | Worked case 2: "I pulled, and the push is still rejected", and the extended toolbox | 9 | 35 | [Ch. 29](../textbook/ch29-production-troubleshooting.md) 29.4, 29.5 | 24 |
| V182 | Operations in progress: what git status and .git tell you | 9 | 35 | [Ch. 29](../textbook/ch29-production-troubleshooting.md) 29.6 | 22 |
| V183 | Preserving evidence before acting, and GitHub-side evidence | 9 | 35 | [Ch. 29](../textbook/ch29-production-troubleshooting.md) 29.7, 29.8 | 22 |
| V184 | Choosing the lowest-risk fix, verification, and the symptom catalog | 9 | 35 | [Ch. 29](../textbook/ch29-production-troubleshooting.md) 29.9, 29.10, 29.11 | 18 |
| V185 | An incident and the loop that handles one, severity, and how to run the ten incidents | 9 | 36 | [Ch. 30](../textbook/ch30-incident-response.md) 30.2, 30.3, 30.4 | 16 |
| V186 | Incident drills: an accidental hard reset, and a branch that appears to have disappeared | 9 | 36 | [Ch. 30](../textbook/ch30-incident-response.md) 30.5, 30.12 | 24 |
| V187 | Incident drills: a commit that exists locally but not remotely, and a misunderstood merge conflict | 9 | 36 | [Ch. 30](../textbook/ch30-incident-response.md) 30.14, 30.13 | 24 |
| V188 | A developer rebases a shared branch, and senior standard 1: the branch was rebased and force-pushed and the pull request is broken | 9 | 36, 38 | [Ch. 30](../textbook/ch30-incident-response.md) 30.9, 30.16 | 26 |
| V189 | Incident drills: a force push to the wrong branch, and rewritten production history | 9 | 37 | [Ch. 30](../textbook/ch30-incident-response.md) 30.6, 30.8 | 26 |
| V190 | Incident drill: a pull request that suddenly shows 500 unrelated changes | 9 | 37 | [Ch. 30](../textbook/ch30-incident-response.md) 30.10 | 18 |
| V191 | CI works locally but fails on GitHub Actions, and senior standard 3: GitHub Actions suddenly fails | 9 | 37, 38 | [Ch. 30](../textbook/ch30-incident-response.md) 30.11, 30.18 | 22 |
| V192 | A secret is committed, and senior standard 2 | 9 | 37, 38 | [Ch. 30](../textbook/ch30-incident-response.md) 30.7, 30.17 | 22 |
| V193 | The incident summary a CTO needs, blameless postmortems, and turning a root cause into a control | 9 | 38 | [Ch. 30](../textbook/ch30-incident-response.md) 30.15, 30.19, 30.20 | 22 |
| V194 | Gate briefing: Production debugging | 9 | 38 | [Ch. 29](../textbook/ch29-production-troubleshooting.md) 29.2, 29.7; [Ch. 30](../textbook/ch30-incident-response.md) 30.2, 30.15 | 10 |
| V195 | The CTO interview series: the structure of a strong answer | 10 | 39 | [Ch. 1](../textbook/ch01-fundamentals.md) 1.10; [Ch. 29](../textbook/ch29-production-troubleshooting.md) 29.4 | 18 |
| V196 | The final knowledge test: briefing | 10 | 40 | [Ch. 30](../textbook/ch30-incident-response.md) 30.2, 30.15 | 12 |
| V197 | The capstone: eight incidents at a fictional company | 10 | 41 | [Ch. 29](../textbook/ch29-production-troubleshooting.md) 29.2; [Ch. 30](../textbook/ch30-incident-response.md) 30.2, 30.19 | 16 |
| V198 | Capstone debrief: reading your own work against the evaluation | 10 | 41 | [Ch. 29](../textbook/ch29-production-troubleshooting.md) 29.9, 29.10; [Ch. 30](../textbook/ch30-incident-response.md) 30.20 | 20 |
| V199 | The road to Git 3.0, the planned defaults and removals, opting in today, and SHA-256 and reftable repositories locally | 11 | 42 | [Ch. 14D](../textbook/ch14d-frontier.md) 14D.2, 14D.3, 14D.4, 14D.5 | 24 |
| V200 | git history, git replay, git last-modified and git repo | 11 | 42 | [Ch. 14D](../textbook/ch14d-frontier.md) 14D.6, 14D.7, 14D.8; [Ch. 9](../textbook/ch09-rebase.md) 9.20 | 24 |
| V201 | Rust in Git, stacked workflows and Git-compatible tools, reading release notes and the GitHub Changelog, and the patch-based workflow of the Git project | 11 | 42 | [Ch. 14D](../textbook/ch14d-frontier.md) 14D.9, 14D.10, 14D.11 | 24 |

## 4. Part summary

| Part | Roadmap level | Videos | Count | Minutes |
|---|---|---|---|---|
| 0: Orientation | Level 0 (Module 0) | V001 to V006 | 6 | 114 |
| 1: Foundations | Level 1 (Modules 1 to 5), then the Fundamentals gate | V007 to V029 | 23 | 524 |
| 2: Integration and collaboration mechanics | Level 2 (Modules 6 to 10), with the Branching gate after Module 7 and the Merge and rebase gate after Module 10 | V030 to V065 | 36 | 824 |
| 3: Investigation, recovery and power tools | Level 3 (Modules 11 to 15), then the Recovery gate | V066 to V098 | 33 | 746 |
| 4: Git internals | Level 4 (Modules 16 to 18), then the Internals gate | V099 to V114 | 16 | 336 |
| 5: GitHub | Level 5 (Modules 19 to 25), then the GitHub gate | V115 to V141 | 27 | 606 |
| 6: CI/CD with GitHub Actions | Level 6 (Modules 26 to 28), then the Actions gate | V142 to V155 | 14 | 318 |
| 7: Security | Level 7 (Modules 29 to 31), then the Security gate | V156 to V169 | 14 | 320 |
| 8: Professional practice | Level 8 (Modules 32 to 34), then the design review | V170 to V179 | 10 | 230 |
| 9: Production debugging and incident response | Level 9 (Modules 35 to 38), then the Production debugging gate | V180 to V194 | 15 | 322 |
| 10: Senior engineer: assessment | Level 10 (Modules 39 to 41) | V195 to V198 | 4 | 66 |
| 11: Expert: the frontier | Level 11 (Module 42) | V199 to V201 | 3 | 72 |

## 5. Module coverage

Every module of the roadmap, 0 to 42, with the videos that teach it.

| Module | Name | Videos | Minutes |
|---|---|---|---|
| 0 | Lab setup and working method | V001, V002, V003, V004, V005, V006 | 114 |
| 1 | What Git actually is | V002, V007, V008, V009, V010 | 112 |
| 2 | Working tree, index, and HEAD | V011, V012, V013, V014, V015, V016, V017, V018 | 192 |
| 3 | Commits | V019, V020, V021 | 72 |
| 4 | Refs, branches, HEAD, and detached HEAD | V022, V023, V024, V025, V026 | 108 |
| 5 | Configuration, identity, and a professional setup | V027, V028, V029 | 58 |
| 6 | Divergence and merge | V030, V031, V032, V033, V034, V035, V036, V037 | 192 |
| 7 | Remotes, fetch, pull, and push | V038, V039, V040, V041, V042, V043, V044, V045 | 182 |
| 8 | Undo: restore, reset, revert, clean, and stash | V046, V047, V048, V049, V050, V051 | 132 |
| 9 | Rebase | V052, V053, V054, V055, V056, V057, V058, V059, V060 | 214 |
| 10 | Cherry-pick and range notation | V061, V062, V063, V064, V065 | 104 |
| 11 | History investigation and forensics | V066, V067, V068, V069, V070, V071, V072 | 162 |
| 12 | Recovery and disaster recovery | V073, V074, V075, V076, V077, V078, V079 | 168 |
| 13 | Tags, versions, and release mechanics in Git | V080, V081, V082 | 62 |
| 14 | Worktrees, stash internals, rerere, attributes, and hooks | V083, V084, V085, V086, V087, V088, V089, V090 | 176 |
| 15 | Submodules, subtrees, and Git LFS | V091, V092, V093, V094, V095, V096, V097, V098 | 178 |
| 16 | The object database: loose objects, packfiles, and maintenance | V099, V100, V102, V103, V104 | 116 |
| 17 | The index file, ref storage, and the `.git` directory | V099, V101, V105, V106, V107 | 102 |
| 18 | Transfer, scale, and performance | V108, V109, V110, V111, V112, V113, V114 | 140 |
| 19 | GitHub the platform | V115, V116, V117 | 70 |
| 20 | Authentication and SSH | V118, V119, V120, V121, V122 | 110 |
| 21 | Pull requests, review, and the fork workflow | V123, V124, V125, V126, V127, V170 | 142 |
| 22 | Merge methods, merge queue, and releases on GitHub | V128, V129, V130 | 66 |
| 23 | Governance: rulesets, branch protection, and CODEOWNERS | V131, V132, V133, V134, V135, V136 | 142 |
| 24 | Commit signing and verification | V137, V138, V139 | 64 |
| 25 | GitHub CLI and API | V140, V141 | 36 |
| 26 | Actions fundamentals | V142, V143, V144, V145, V146, V147, V148 | 166 |
| 27 | Build, package, and deliver | V148, V149, V150, V151 | 92 |
| 28 | Runners, cost, and debugging CI | V152, V153, V154, V155 | 84 |
| 29 | GitHub Actions security | V156, V157, V158, V159, V160, V161, V162 | 164 |
| 30 | Repository and supply-chain security | V138, V163, V164, V165 | 96 |
| 31 | Secret-leak response and history rewriting as an operation | V166, V167, V168, V169 | 84 |
| 32 | Branching and release strategy | V171, V172, V173 | 70 |
| 33 | AI/ML engineering workflows | V097, V175, V176, V177, V178 | 124 |
| 34 | Practices, anti-patterns, and open-source etiquette | V127, V170, V174, V179 | 84 |
| 35 | The diagnosis method | V180, V181, V182, V183, V184 | 112 |
| 36 | Incident drills, local and history | V185, V186, V187, V188 | 90 |
| 37 | Incident drills, remote, platform, CI, and security | V189, V190, V191, V192 | 88 |
| 38 | Communication, postmortems, and the senior standard | V188, V191, V192, V193, V194 | 102 |
| 39 | The CTO interview series | V195 | 18 |
| 40 | The final knowledge test | V196 | 12 |
| 41 | The capstone production simulation | V197, V198 | 36 |
| 42 | Where Git is going, and reading primary sources unaided | V107, V199, V200, V201 | 94 |

## 6. The videos

## Part 0: Orientation

Roadmap Level 0 (Module 0). 6 videos build the lab, the working method and the two habits every later video relies on: the root-cause framework and the ten-command diagnosis. There is no gate after this part.

### V001: How this course works: the book, the lab sandbox and the fixed clock

- **Title.** How this course works: the book, the lab sandbox and the fixed clock
- **Learning objectives.** After this video the learner can:
  - State the goal of the course in one sentence: diagnose from first principles, choose the lowest-risk fix, verify, prevent
  - Open an isolated lab shell with `labs/shell`, replay a demo with `labs/run`, and check a chapter with `labs/verify-all.sh`
  - Explain why the lab configuration is isolated and name the variable that redirects the global configuration file
  - Explain why replays pin the clock and why the sandbox sets the two `gc.reflogExpire` settings to `never`
  - Give the meaning of the three risk labels and the five questions asked before a dangerous command
- **Prerequisites.** None.
- **Concepts.** The question a CTO asks is never "which command". The ladder each concept is taught on. Transcripts are real output inserted by a tool. `labs/shell`, `labs/run`, `labs/verify-all.sh`. `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_NOSYSTEM`, `GIT_CEILING_DIRECTORIES`. The lab clock (Monday 7 September 2026, 10:00 +05:30, one minute per command) and why a commit ID depends on time. The root-cause box about which clock `git fsck` and reflog expiry read. Risk labels describe the worst case. GitHub-side material cannot be replayed locally.
- **Commands.** `labs/shell m00`; `labs/run ch01/first-repo`; `labs/verify-all.sh ch01`; `git config list --show-origin --show-scope`
- **Demonstration.** Replay `labs/ch00/smoke-test.sh` to show that the sandbox works, then `labs/ch01/sandbox.sh` (snippets `env`, `config`, `clock`). In `env`, read the `GIT_` variables one by one against the table of section 1.7. In `config`, point at the scope and origin columns and at the alias landing in the sandbox file, not in the presenter's own file. In `clock`, point at the author and committer dates and say that the commit ID on screen equals the one in the book.
- **Diagrams.** New: one box "your Mac" containing two smaller boxes, "your real `~/.gitconfig` (never read, never written)" and "`$LAB`: sandbox configuration, hands-on directories, one directory per replay", with arrows from `labs/shell` and `labs/run` into the second box only. Then the root-cause box of section 1.7 shown line by line.
- **Practical exercise.** Lab 0.1 ("Verify the toolchain and build the sandbox") in [`lab-manual/m00-lab-setup.md`](../lab-manual/m00-lab-setup.md)
- **Challenge.** Without the book open, write the table of the three risk labels with two example commands each and the five questions for a dangerous command. Then check it against section 1.8.
- **Interview question.** Q15: "The same commands typed at two different times produce different commit IDs. Why? What did the lab environment pin to prevent it, and what did it not need to pin?"
- **Homework.** Read sections 1.1, 1.7 and 1.8. Run `labs/verify-all.sh ch01` and keep the output. Read [`lab-manual/README.md`](../lab-manual/README.md).
- **Expected outcome.** The learner has a working sandbox, knows that nothing in the course touches the real Git configuration, and can say why the IDs on screen equal the IDs in the book.

### V002: What version control solves, and Git the tool versus GitHub the platform

- **Title.** What version control solves, and Git the tool versus GitHub the platform
- **Learning objectives.** After this video the learner can:
  - Describe the problem that version control solves without naming a product
  - Contrast a centralized with a distributed system by what each clone holds
  - Name Git's design goals as the textbook lists them
  - Say for a given feature whether it belongs to Git the tool or to GitHub the platform
  - State which of the two Gits on the Mac a command runs and how to find out
- **Prerequisites.** V001
- **Concepts.** The problem: many people, many versions, one history that can be trusted. Centralized versus distributed: every clone is a full repository. Git's design goals. Git is a program and a data format; GitHub is a hosting platform that stores Git repositories and adds its own objects. The two Gits on a Mac and why the version matters for every transcript.
- **Commands.** `which -a git`; `git --version`; `git version --build-options`
- **Demonstration.** Replay `labs/ch01/lab-00-1-toolchain.sh`. Use snippets `which` and `build-options`: point at the two paths that provide `git`, at the version each prints, and at the `default-hash` and `SHA-1` lines of the build options. Say that every transcript in the course comes from Git 2.55.0.
- **Diagrams.** Redraw the diagram of section 1.3: one server with thin clients on the left, full repositories on every machine on the right. New: a two-column table "Git" and "GitHub" filled live from the table of section 1.5.
- **Practical exercise.** Exercise 1.2 (Level 1, "Git or GitHub?") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Take five things from a repository page of a project you use and decide for each whether a `git clone` would carry it. Keep the list; V115 returns to it with proof.
- **Interview question.** Q1: "Why can `git log` work without a network connection while `git push` cannot? What does your answer imply about backups?"
- **Homework.** Read sections 1.2 to 1.6. Note the output of the three version commands on your machine.
- **Expected outcome.** The learner stops saying "GitHub" when they mean Git, and can explain why work continues without a network.

### V003: A first repository, read file by file

- **Title.** A first repository, read file by file
- **Learning objectives.** After this video the learner can:
  - Predict which files appear under `.git` after `git init`, after `git add` and after `git commit`
  - Read the output of `git status` in the four states of the guided repository
  - Show that a commit moved the branch ref and that HEAD still names the branch
  - Count the objects a first and a second commit create
- **Prerequisites.** V002
- **Concepts.** `git init` creates a directory, not a server connection. Untracked, staged, committed: one file followed through three places. What `git add` writes and what `git commit` writes. The ref that moved. The objects themselves are opened in V007, which starts from this same commit.
- **Commands.** `git init`; `git status`; `git add`; `git commit -m`; `git log --oneline`; `git diff`
- **Demonstration.** Replay `labs/ch01/first-repo.sh` (snippets `init`, `untracked`, `add`, `commit`, `after-commit`, `second-commit`, `ref-moved`) in order. Before `add`, ask what will change under `.git`; before `commit`, ask the same. In `ref-moved`, point at the content of the branch file before and after. Then replay `labs/ch01/lab-00-2-empty-git-dir.sh` and read each file of the empty `.git` aloud.
- **Diagrams.** Redraw the diagram of section 1.9. Add a new strip of three boxes (working tree, index, repository) and move one file across it as the replay advances.
- **Practical exercise.** Lab 0.2 ("Read every file in an empty `.git`") in [`lab-manual/m00-lab-setup.md`](../lab-manual/m00-lab-setup.md)
- **Challenge.** Exercise 1.4 (Level 2, "how many objects?") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q14: "What makes a directory a Git repository? Which files in a fresh `.git` can you delete without breaking it?"
- **Homework.** Read section 1.9. Repeat the guided repository by hand in `labs/shell m00` and compare your object count with the book; explain why your IDs differ.
- **Expected outcome.** The learner has seen every file that a first commit creates and no longer treats `.git` as opaque.

### V004: The root-cause framework

- **Title.** The root-cause framework
- **Learning objectives.** After this video the learner can:
  - List the steps of the root-cause framework in order
  - Separate a symptom from a hypothesis for a given report
  - Write a seven-line root-cause box for a behavior that has been shown
  - Explain why every step up to naming the root cause is read-only
- **Prerequisites.** V003
- **Concepts.** Symptom, state, evidence, hypotheses, test, root cause, fix, verification, prevention. One hypothesis is a belief. The seven-line box: observed behavior, Git state, mechanism, root cause, why Git does this, correct fix, prevention. Root cause versus mechanism. The layer (Git, GitHub, GitHub Actions) is part of every root cause.
- **Commands.** `git status`
- **Demonstration.** Replay `labs/ch01/pitfalls.sh` (snippets `nothing-staged`). Treat the output as a report from a colleague and fill the seven lines of a root-cause box on screen from what the transcript shows, without running anything else.
- **Diagrams.** Show the root-cause box of section 1.10 line by line, then the framework as a new vertical flow of eleven steps with a horizontal line under "root cause" labelled "read-only above this line".
- **Practical exercise.** Exercise 1.3 (Level 1, "the diagnosis ritual on a small state") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Take the last Git problem you solved by searching for a command. Write its root-cause box. Mark each line you cannot fill; those lines are what the course will teach.
- **Interview question.** Q467: "Every explanation in this course ends in the same seven-line form. What are the seven lines, and how does "root cause" differ from "mechanism"?"
- **Homework.** Read section 1.10. Learn the seven lines by heart; every later video ends an investigation with them.
- **Expected outcome.** The learner has a fixed form for explaining any surprising behavior and uses it instead of a command list.

### V005: The ten-command diagnosis

- **Title.** The ten-command diagnosis
- **Learning objectives.** After this video the learner can:
  - Run the ten-command diagnosis in order from memory
  - Say for each command which question about the repository it answers
  - Explain why the ritual is run before any state-changing command
  - Name the commands of the ritual that can write to disk and why that is harmless
- **Prerequisites.** V004
- **Concepts.** State before hypothesis. Each command answers one question: where am I, what do the branches track, which remotes, what does the graph look like, what happened recently, what does this name resolve to, what is in this commit, what is unstaged, what is staged, which configuration is in force, what does the index hold.
- **Commands.** `git status`; `git branch -vv`; `git remote -v`; `git log --graph --decorate --oneline --all`; `git reflog`; `git rev-parse`; `git show`; `git diff`; `git diff --cached`; `git config list --show-origin --show-scope`; `git ls-files`
- **Demonstration.** Replay `labs/ch01/diagnosis.sh` (snippets `status`, `branch`, `remote`, `log`, `reflog`, `rev-parse`, `show`, `diff`, `config`, `ls-files`). For each snippet, state the question first, then show the output, then say what it rules out.
- **Diagrams.** New: a table with three columns, "command", "question it answers", "place it reads" (working tree, index, refs, reflog, objects, configuration), filled in as the replay advances.
- **Practical exercise.** Lab 35.1 ("The ten-command diagnosis on three repositories") in [`lab-manual/m35-diagnosis-method.md`](../lab-manual/m35-diagnosis-method.md) is the full drill later in the course; for now do Exercise 1.3 (Level 1, "the diagnosis ritual on a small state") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md) again from memory and time it.
- **Challenge.** Exercise 1.9 (Level 4, ""git log says there are no commits"") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q40: "The course's ten-command diagnosis ritual is meant to be read-only. Which of its commands can write to disk, and why does that matter when you investigate a damaged repository?"
- **Homework.** Read section 1.11. Write the eleven commands on a card and run them on three repositories of your own without changing anything.
- **Expected outcome.** The learner starts every investigation with the same read-only commands and can say what each one told them.

### V006: Worked example: the fix that was committed and did not ship

- **Title.** Worked example: the fix that was committed and did not ship
- **Learning objectives.** After this video the learner can:
  - Apply the framework to the report "the fix is committed" and find where it is not
  - List the places where "committed" can be true or false
  - Recognize four first-day pitfalls from their output
  - Decide when a guided method is the wrong tool
- **Prerequisites.** V005
- **Concepts.** The worked example of section 1.12: a symptom, the ritual, three hypotheses, the test that separates them, the root cause, the fix and its verification. What can go wrong on the first day: an unconfigured `git init`, a command outside a repository, nothing staged, a repository inside a repository.
- **Commands.** `git status`; `git log --oneline`; `git branch -vv`; `git rm --cached`
- **Demonstration.** Replay `labs/ch01/diagnosis.sh` (snippets `test`, `fix`, `verify`) for the worked example, then `labs/ch01/pitfalls.sh` (snippets `unconfigured-init`, `not-a-repository`, `embedded-repository`, `embedded-undo`). In each pitfall, read the message Git prints word by word; most of them name the cause.
- **Diagrams.** Redraw the diagram of section 1.12 and show the root-cause box of section 1.12.
- **Practical exercise.** Exercise 1.9 (Level 4, ""git log says there are no commits"") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Exercise 1.8 (Level 3, "the object that no history shows") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q11: "A colleague says "the fix is committed". List the distinct places where that statement can be true or false, and the command that checks each."
- **Homework.** Read sections 1.12 to 1.15. Do the Practice section 1.17.
- **Expected outcome.** The learner has followed one complete investigation from report to prevention and can repeat its shape.

## Part 1: Foundations

Roadmap Level 1 (Modules 1 to 5), then the Fundamentals gate. 23 videos build the data model: objects, refs, HEAD, the three trees, commits, branches and configuration. Every explanation in later parts is given in these terms. The part ends with the briefing for Gate 1.

### V007: Snapshots, not diffs, and content addressing

- **Title.** Snapshots, not diffs, and content addressing
- **Learning objectives.** After this video the learner can:
  - Open the first commit of the guided repository and name the object behind the commit, its tree and its files
  - Show with object IDs that two commits share the blob of an unchanged file
  - Explain why a diff is computed on demand and is stored nowhere
  - Predict whether the same content gets the same object ID in two unrelated repositories, and say why
- **Prerequisites.** V003
- **Concepts.** A commit records the whole project as a tree of blobs; unchanged files are the same object, referenced again. A diff is the comparison of two snapshots, made when asked for. Content addressing: the object ID is a hash of the type, the size and the content, so identical content has one ID everywhere and any change gives another. What content addressing gives: integrity, deduplication, cheap comparison.
- **Commands.** `git cat-file -t`; `git cat-file -p`; `git hash-object`
- **Demonstration.** Replay `labs/ch02/snapshots.sh` (snippets `first-commit`, `second-commit`, `all-objects`, `no-diff-inside`, `diff-on-demand`): in `second-commit`, point at the blob ID that is the same in both trees; in `no-diff-inside`, show that no object contains a diff. Then `labs/ch02/content-ids.sh` (snippets `no-repository`, `two-repositories`, `trees`): the same file hashed outside any repository and in two repositories prints one ID.
- **Diagrams.** Redraw the diagram of section 2.3: two commits, two trees, and one blob that both trees point at. New: a function box "type + size + content -> object ID" with two inputs differing in one byte.
- **Practical exercise.** Lab 1.2 ("Snapshots share unchanged blobs") in [`lab-manual/m01-what-git-is.md`](../lab-manual/m01-what-git-is.md)
- **Challenge.** Exercise 1.7 (Level 3, "the same files, two different commit IDs") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q16: "A commit changes one file out of 5,000, three directories deep. How many objects does it create, and of which types?"
- **Homework.** Read sections 2.1 to 2.4. Do Lab 1.3 ("Same content, same ID, in two repositories") in [`lab-manual/m01-what-git-is.md`](../lab-manual/m01-what-git-is.md).
- **Expected outcome.** The learner can refute "Git stores diffs" with two commands and explains object IDs as a function of content.

### V008: The four object types, and a commit built by hand

- **Title.** The four object types, and a commit built by hand
- **Learning objectives.** After this video the learner can:
  - Name the four object types and say what each contains and what it points at
  - Read a tree entry: mode, type, object ID, name
  - Build a commit with plumbing only, without `git add` or `git commit`
  - Explain which step of the hand-built commit corresponds to which porcelain command
- **Prerequisites.** V007
- **Concepts.** Blob: content only, no name. Tree: names, modes and IDs of blobs and trees. Commit: one tree, zero or more parents, author, committer, message. Annotated tag: an object that names another object. File names live in trees, which is why a rename costs no new blob. The hand-built commit: `hash-object -w` writes the blob, `update-index` registers it, `write-tree` writes the tree, `commit-tree` writes the commit, `update-ref` makes it reachable.
- **Commands.** `git hash-object -w`; `git update-index --add --cacheinfo`; `git write-tree`; `git commit-tree`; `git update-ref`; `git cat-file -t`; `git cat-file -p`; `git ls-tree`
- **Demonstration.** Replay `labs/ch02/object-types.sh` (snippets `inventory`, `commit`, `tree`, `blob`, `tag`), opening one object of each type. Then `labs/ch02/commit-by-hand.sh` (snippets `blob`, `index`, `tree`, `commit`, `ref`, `working-tree`): ask before each step which object or file will appear; in `working-tree`, point out that the working tree is still empty although the commit exists.
- **Diagrams.** Redraw the diagram of section 2.5: commit -> tree -> blobs, with the tag object above. New: a five-step ladder for the hand-built commit with the porcelain command beside each rung.
- **Practical exercise.** Lab 1.1 ("Build a commit by hand") in [`lab-manual/m01-what-git-is.md`](../lab-manual/m01-what-git-is.md)
- **Challenge.** Exercise 1.8 (Level 3, "the object that no history shows") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q66: "What are a blob, a tree and a commit object?"
- **Homework.** Read sections 2.5 and 2.6. Repeat Lab 1.1 ("Build a commit by hand") in [`lab-manual/m01-what-git-is.md`](../lab-manual/m01-what-git-is.md) a second time from memory, with a different file name and message.
- **Expected outcome.** The learner has made a commit without porcelain and can no longer think of `git commit` as an indivisible act.

### V009: The commit graph, reachability, refs and HEAD

- **Title.** The commit graph, reachability, refs and HEAD
- **Learning objectives.** After this video the learner can:
  - Draw the commit graph of a small history from its parent pointers
  - Define reachable and decide for a given commit whether a ref reaches it
  - Show that a branch is a file holding one commit ID and that HEAD names a branch
  - Rescue a commit that no ref reaches by giving it a name
- **Prerequisites.** V008
- **Concepts.** Parent pointers go backwards, so history is a directed acyclic graph read from the tips. Reachability: what a ref can reach by following parents. An unreachable commit still exists as an object. Refs are names for commit IDs; HEAD normally holds the name of a branch. A commit moves the branch that HEAD names. A ref written under the wrong name is still a ref.
- **Commands.** `git log --graph --decorate --oneline --all`; `git rev-parse`; `git branch`; `git switch`; `git switch --detach`; `git symbolic-ref`; `git for-each-ref`; `git merge-base --is-ancestor`
- **Demonstration.** Replay `labs/ch02/graph.sh` (snippets `graph`, `parents`, `reachable`, `unreachable`, `rescued`) and stop at `unreachable` to ask where the commit is now. Then `labs/ch02/refs-head.sh` (snippets `files`, `new-branch`, `commit-moves-branch`, `checkout-equivalent`, `detached`), reading the ref files on screen. Close with `labs/ch02/update-ref-trap.sh` (snippets `stray-ref`, `find-and-remove`).
- **Diagrams.** Redraw the diagram of section 2.7 and the diagram of section 2.8. In the second, animate one commit: the branch label moves, HEAD stays attached to the label.
- **Practical exercise.** Exercise 1.6 (Level 2, "two branches and a tag") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Exercise 1.9 (Level 4, ""git log says there are no commits"") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q19: "Define "reachable". Why is a commit that no ref can reach still in the repository, and for how long by default?"
- **Homework.** Read sections 2.7 and 2.8. Draw the graph of Lab 1.1 ("Build a commit by hand") in [`lab-manual/m01-what-git-is.md`](../lab-manual/m01-what-git-is.md) and of the guided repository on paper, with refs and HEAD.
- **Expected outcome.** The learner reads "branch", "HEAD" and "reachable" as statements about refs and parent pointers.

### V010: Three trees, two views of a commit, and the wrong mental models

- **Title.** Three trees, two views of a commit, and the wrong mental models
- **Learning objectives.** After this video the learner can:
  - Name the three trees and say which command compares which pair
  - Explain how a commit can be read as a snapshot and as a change without contradiction
  - Refute four common wrong models of Git with a transcript each
  - Say which parts of a repository travel to the server on a push and which never do
- **Prerequisites.** V009
- **Concepts.** HEAD's tree, the index, the working tree: a preview of Part 1's next block. A commit is a snapshot; "the change of a commit" is its difference from its parent, which is what cherry-pick and revert use. Wrong models: Git stores diffs, a branch is a copy, a commit belongs to a branch, GitHub is Git. The map of what lives where: laptop, server, clone.
- **Commands.** `git status`; `git diff`; `git diff --cached`; `git show`; `git cherry-pick`
- **Demonstration.** Replay `labs/ch02/three-trees.sh` (snippets `three-versions`, `status`, `two-diffs`), then `labs/ch02/two-views.sh` (snippets `before`, `cherry-pick`, `snapshots-differ`, `change-is-the-same`): the copied commit has another ID and another tree and the same change. Close with `labs/ch02/what-travels.sh` (snippets `laptop`, `server`, `clone`): list what the clone did not receive.
- **Diagrams.** Redraw the diagram of section 2.9, the diagram of section 2.10 and the diagram of section 2.12.
- **Practical exercise.** Exercise 1.1 (Level 1, "one commit, three object types") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Exercise 1.5 (Level 2, "add twice, commit once") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q21: "Which parts of `.git` reach the server when you push, and which never do? What does GitHub hold that no clone contains?"
- **Homework.** Read sections 2.9 to 2.15 and do the Practice section 2.17.
- **Expected outcome.** The learner holds one model that explains staging, history and remotes, and recognizes the wrong models when colleagues use them.

### V011: The working tree, three categories of file, and the anatomy of git status

- **Title.** The working tree, three categories of file, and the anatomy of git status
- **Learning objectives.** After this video the learner can:
  - Define the working tree and say what a bare repository lacks
  - Classify a path as tracked, untracked or ignored from the index and the ignore rules
  - Explain `git status` as two comparisons and read the two columns of the short format
  - Choose the status format that a script should parse
- **Prerequisites.** V010
- **Concepts.** The working tree is a checkout of one commit plus your edits; it can be rebuilt from the repository, the reverse is not true. Tracked means "in the index". `git status` compares HEAD with the index and the index with the working tree. Short format: left column index, right column working tree. `--porcelain` is the stable format for scripts.
- **Commands.** `git status`; `git status --short`; `git status --porcelain`; `git status --ignored`; `git ls-files`; `git rev-parse --show-toplevel`
- **Demonstration.** Replay `labs/ch04/worktree-basics.sh` (snippets `where`, `bare`, `rebuild`), `labs/ch04/three-categories.sh` (snippets `status`, `status-ignored`, `ls-files`, `transitions`) and `labs/ch04/status-anatomy.sh` (snippets `long`, `short`, `two-comparisons`, `porcelain`, `untracked-modes`). In `two-comparisons`, cover the output and have the viewer predict both columns for each file.
- **Diagrams.** Redraw the diagram of section 4.2, the diagram of section 4.3 and the diagram of section 4.4.
- **Practical exercise.** Exercise 2.1 (Level 1, "every short status code, made on purpose") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Exercise 2.9 (Level 4, ""Git does not see my edits"") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q5: "Define tracked, untracked and ignored in terms of the index. Can a path be tracked and ignored at the same time?"
- **Homework.** Read sections 4.1 to 4.4.
- **Expected outcome.** The learner reads any `git status` output as a statement about three trees.

### V012: Ignore rules and the already-tracked trap

- **Title.** Ignore rules and the already-tracked trap
- **Learning objectives.** After this video the learner can:
  - List the sources of ignore patterns in precedence order
  - Find the rule that ignores a given path with one command
  - Explain why adding a tracked file to `.gitignore` changes nothing, and fix it
  - State what the fix does not do to history and to teammates' working trees
- **Prerequisites.** V011
- **Concepts.** Pattern syntax: anchoring, directories, negation and its limit. Sources: `.gitignore` files, `.git/info/exclude`, the personal excludes file. Ignore rules apply to untracked files only. The trap: a tracked file stays tracked. `git rm --cached` removes it from the index, keeps it on disk, and the next commit deletes it for everyone else. Ignored files are treated as expendable.
- **Commands.** `git check-ignore -v`; `git rm --cached`; `git add -f`
- **Demonstration.** Replay `labs/ch04/gitignore-patterns.sh` (snippets `file`, `check-ignore`, `status`, `negation-limit`, `nested`, `personal`, `precedence`, `force`), then `labs/ch04/ignore-tracked-trap.sh` (snippets `the-mistake`, `ignore-does-nothing`, `diagnose`, `fix`, `now-ignored`, `history-still-has-it`, `teammate`, `ignored-is-expendable`). Stop at `history-still-has-it` and at `teammate`: these two snippets are the production lesson.
- **Diagrams.** Show the root-cause box of section 4.6. New: a decision path "is the path in the index? yes: ignore rules are not consulted".
- **Practical exercise.** Lab 2.3 ("The `.gitignore` trap and its fix") in [`lab-manual/m02-working-tree-index-head.md`](../lab-manual/m02-working-tree-index-head.md)
- **Challenge.** Exercise 2.5 (Level 2, "a negated pattern that does not work") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q45: "A developer added `config/secrets.yaml` to `.gitignore` and it is still in every new commit. Walk through your diagnosis commands, the fix, and the two things the fix does not solve."
- **Homework.** Read sections 4.5 and 4.6. Do Exercise 2.2 (Level 1, "which rule ignores which path") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md).
- **Expected outcome.** The learner diagnoses any "it is in .gitignore and still committed" report in three commands and knows the cost of the fix.

### V013: git restore, git mv, git rm, and why Git records no renames

- **Title.** git restore, git mv, git rm, and why Git records no renames
- **Learning objectives.** After this video the learner can:
  - Say where `git restore <path>` takes its content from and what it overwrites without a way back
  - Restore a path from HEAD or from an older commit
  - Show that `git mv` equals a manual move plus staging
  - Prove that a commit contains no rename record and explain the similarity score
- **Prerequisites.** V012
- **Concepts.** `git restore` copies from the index to the working tree by default; `--source` chooses a commit. An overwritten unstaged edit is in no object. `git mv` and `git rm` are conveniences over the index. Renames are detected when a diff is computed, from similarity of content; nothing about a rename is stored.
- **Commands.** `git restore`; `git restore --source`; `git mv`; `git rm`; `git log --oneline --follow`; `git diff --name-status`
- **Demonstration.** Replay `labs/ch04/restore-paths.sh` (snippets `from-index`, `from-head`, `deleted-file`, `older-commit`, `checkout-equivalent`, `what-survives`), then `labs/ch04/mv-rm-renames.sh` (snippets `git-mv`, `same-as-manual`, `commit-has-no-rename`, `detected-on-demand`, `rename-and-edit`, `follow`, `git-rm`). In `commit-has-no-rename`, open the tree objects.
- **Diagrams.** New: two trees side by side, old name and new name pointing at one blob, with the caption "the rename is the reader's inference".
- **Practical exercise.** Exercise 2.6 (Level 2, "a move and an edit, as two commits") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Exercise 2.7 (Level 3, ""git restore ." did not throw everything away") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q47: "Prove to me that Git does not store renames. Then explain what `R087` in a diff means and name two features that depend on it."
- **Homework.** Read sections 4.7 to 4.9.
- **Expected outcome.** The learner treats `git restore` on the working tree as destructive and explains rename detection as computation.

### V014: File modes, empty directories, the case-insensitive filesystem, line endings, and git clean

- **Title.** File modes, empty directories, the case-insensitive filesystem, line endings, and git clean
- **Learning objectives.** After this video the learner can:
  - State what Git records about file permissions and set the executable bit in the index
  - Explain why Git cannot track an empty directory
  - Reproduce and repair a case-only rename on a case-insensitive filesystem
  - Preview and run `git clean` with the narrowest scope that does the job
- **Prerequisites.** V013
- **Concepts.** Git stores one permission bit and symbolic links as blobs. Directories exist only as paths of files. macOS's default filesystem is case-insensitive: two names that differ only in case are one file locally and two on Linux. Line endings in brief; attributes are taught later. `git clean` deletes untracked files, which no object holds: preview first, always.
- **Commands.** `git update-index --chmod=+x`; `git ls-files --stage`; `git mv`; `git clean -n`; `git clean -fd`; `git clean -fdx`
- **Demonstration.** Replay `labs/ch04/modes-symlinks.sh` (snippets `executable-bit`, `only-the-x-bit`, `chmod-in-index`, `symlink`), `labs/ch04/empty-directories.sh` (snippets `invisible`, `placeholder`, `last-file-leaves`), `labs/ch04/case-insensitive.sh` (snippets `probe`, `invisible-rename`, `git-mv`, `collision-made-on-linux`, `clone-on-mac`, `detect-and-fix`), `labs/ch04/line-endings.sh` (snippets `eol`, `whole-file-diff`) and `labs/ch04/clean.sh` (snippets `start`, `refuses`, `dry-runs`, `exclude`, `clean-fd`, `clean-fdx`, `nested-repository`). Before `clean-fd`, answer the five questions for a dangerous command aloud.
- **Diagrams.** Show the root-cause box of section 4.12. New: one tree with `Utils.py` and `utils.py` as two entries, and the single file a Mac checkout produces.
- **Practical exercise.** Exercise 2.1 (Level 1, "every short status code, made on purpose") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md) repeated with an executable script and a case-only rename added to the states you make.
- **Challenge.** Exercise 2.9 (Level 4, ""Git does not see my edits"") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q48: "A Python module imports fine on macOS and fails on the Linux CI runner after someone renamed it. What happened inside Git, and how do you prevent a recurrence?"
- **Homework.** Read sections 4.10 to 4.17 and do the Practice section 4.19.
- **Expected outcome.** The learner predicts the filesystem-dependent failures that reach CI and never runs `git clean` without a dry run.

### V015: The index: the proposed next commit, and what git add writes

- **Title.** The index: the proposed next commit, and what git add writes
- **Learning objectives.** After this video the learner can:
  - Describe the index as a flat list of paths with blob IDs and prove it equals HEAD's tree when nothing is staged
  - Name the two things `git add` writes
  - Show that staging is a snapshot of the file at the moment of `git add`
  - Explain what remains in the repository after a staged file is unstaged
- **Prerequisites.** V008, V011
- **Concepts.** The index is one file that holds the next commit's tree in flat form. `git add` writes a blob and an index entry. Editing after `git add` leaves the staged version unchanged. A blob written by `git add` stays in the object store after unstaging until maintenance removes it; a push does not send it.
- **Commands.** `git ls-files --stage`; `git add`; `git write-tree`; `git cat-file -p`; `git restore --staged`
- **Demonstration.** Replay `labs/ch05/index-is-snapshot.sh` (snippets `flat-list`, `file-header`, `index-equals-head`, `stage-one-file`, `commit-takes-that-tree`), `labs/ch05/add-writes.sh` (snippets `before-add`, `add`, `add-is-a-snapshot`, `same-content-same-blob`) and `labs/ch05/add-leaves-a-blob.sh` (snippets `add-then-unstage`, `the-blob-is-still-there`, `a-push-does-not-send-it`).
- **Diagrams.** Redraw the diagram of section 5.2.
- **Practical exercise.** Lab 2.1 ("The three-trees prediction table") in [`lab-manual/m02-working-tree-index-head.md`](../lab-manual/m02-working-tree-index-head.md)
- **Challenge.** Exercise 2.4 (Level 2, "what does the commit contain?") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q27: "What exactly does `git add` write, and what remains of it after `git restore --staged`? Does a push send it?"
- **Homework.** Read sections 5.1 to 5.3.
- **Expected outcome.** The learner can say exactly what the next commit will contain before making it.

### V016: Three diffs, partial staging with git add -p, and intent to add

- **Title.** Three diffs, partial staging with git add -p, and intent to add
- **Learning objectives.** After this video the learner can:
  - Say which two trees each of `git diff`, `git diff --cached` and `git diff HEAD` compares
  - Stage part of a file with `git add -p`, including a hunk that cannot be split
  - Explain the risk of a partially staged commit and the check that removes it
  - Make an untracked file visible to `git diff` with `git add -N`
- **Prerequisites.** V015
- **Concepts.** Three comparisons over three trees; two of them can cancel out. `git add -p`: hunks, `s` to split, `e` to edit. A partially staged commit records a tree that never existed in the working tree, so it was never tested. Intent-to-add: an index entry without content.
- **Commands.** `git diff`; `git diff --cached`; `git diff HEAD`; `git add -p`; `git add -N`; `git checkout-index`
- **Demonstration.** Replay `labs/ch05/three-diffs.sh` (snippets `state`, `diff`, `diff-cached`, `diff-head`, `cancel-out`), `labs/ch05/add-patch.sh` (snippets `the-diff`, `help`, `split-and-choose`, `result`, `export-the-proposed-commit`, `commit-and-continue`), `labs/ch05/add-patch-edit.sh` (snippets `cannot-split`, `edit`, `result`) and `labs/ch05/intent-to-add.sh` (snippets `untracked-is-invisible-to-diff`, `add-n`, `now-diff-sees-it`, `index-version`). In `export-the-proposed-commit`, say why testing the staged tree is the point.
- **Diagrams.** Redraw the diagram of section 5.4: three boxes and three labelled arrows.
- **Practical exercise.** Lab 2.2 ("Partial staging") in [`lab-manual/m02-working-tree-index-head.md`](../lab-manual/m02-working-tree-index-head.md)
- **Challenge.** Exercise 2.8 (Level 3, "the commit that took more than was staged") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q51: "You staged half of a file with `git add -p`, using `e` where `s` was not offered. Why is that commit riskier than a normal one, what can `e` get wrong, and how do you test what you are about to commit?"
- **Homework.** Read sections 5.4 to 5.6. Do Exercise 2.3 (Level 1, "three diffs, three comparisons") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md).
- **Expected outcome.** The learner makes atomic commits from a mixed working tree and knows what was and was not tested.

### V017: Staging deletions and renames, the scope of git add, and unstaging three ways

- **Title.** Staging deletions and renames, the scope of git add, and unstaging three ways
- **Learning objectives.** After this video the learner can:
  - Stage a deletion, a rename and a binary change and read each in `git status`
  - Predict what `git add .`, `git add -u` and `git add -A` stage from a given directory
  - Choose between `git restore --staged`, `git reset <path>` and `git rm --cached` for a given path
  - Explain how `git commit -a` and `git commit <path>` bypass what was staged
- **Prerequisites.** V016
- **Concepts.** Deletions and renames in the index. The scope options differ in untracked files and in the directory they start from. Unstaging: two commands restore the entry from HEAD, one removes the entry, and the difference shows on a path HEAD lacks. Two commit forms that take content from the working tree and not from the index.
- **Commands.** `git add -u`; `git add -A`; `git add .`; `git restore --staged`; `git reset`; `git rm --cached`; `git commit -a`; `git commit --dry-run`
- **Demonstration.** Replay `labs/ch05/stage-deletions-renames-binary.sh` (snippets `deletion`, `rename`, `binary`, `binary-change`), `labs/ch05/add-scope.sh` (snippets `state`, `dot`, `update`, `all`, `no-all`), `labs/ch05/unstage-three-ways.sh` (snippets `setup`, `restore-staged`, `reset-path`, `rm-cached`, `rm-cached-guard`, `unborn-branch`) and `labs/ch05/commit-shortcuts.sh` (snippets `commit-a`, `commit-path`, `commit-path-overrides-partial-staging`, `include`, `untracked-path`, `dry-run`).
- **Diagrams.** Show the root-cause box of section 5.9. New: a three-row table (path in HEAD, path new, unborn branch) against the three unstage commands.
- **Practical exercise.** Lab 2.4 ("Unstage three ways and compare the results") in [`lab-manual/m02-working-tree-index-head.md`](../lab-manual/m02-working-tree-index-head.md)
- **Challenge.** Exercise 2.8 (Level 3, "the commit that took more than was staged") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q28: "Compare `git restore --staged`, `git reset <path>` and `git rm --cached` for a path that HEAD has, for a path that HEAD lacks, and in a repository without commits."
- **Homework.** Read sections 5.7 to 5.10.
- **Expected outcome.** The learner picks the unstage command by its effect on the index entry and no longer loses partial staging to `git commit -a`.

### V018: Reading the index: git ls-files, the two bits that are not an ignore mechanism, the stat cache, and the lock

- **Title.** Reading the index: git ls-files, the two bits that are not an ignore mechanism, the stat cache, and the lock
- **Learning objectives.** After this video the learner can:
  - List index entries, untracked files and ignored files with `git ls-files`
  - Explain why `--assume-unchanged` and `--skip-worktree` are not ways to ignore local changes
  - Name the three stages an index entry has during a conflict
  - Explain a false "modified" from the cached stat data and repair it
  - Diagnose a stale `index.lock` and rebuild a corrupt index
- **Prerequisites.** V017
- **Concepts.** `git ls-files` is the scripting view of the index. Two per-entry bits are promises to Git about performance and sparse checkouts; both break in documented ways. Stages 1, 2 and 3 as a preview of Part 2. The index caches file metadata to avoid rereading content; a copy of the repository invalidates it. The index is rebuilt from HEAD; what is lost is the staging.
- **Commands.** `git ls-files --stage`; `git ls-files --others --exclude-standard`; `git update-index --assume-unchanged`; `git update-index --skip-worktree`; `git ls-files -v`; `git update-index --refresh`; `git diff-index --quiet HEAD`; `git reset`
- **Demonstration.** Replay `labs/ch05/ls-files-tour.sh` (snippets `cached-and-stage`, `against-working-tree`, `others`, `ignored-needs-c-or-o`, `tags`, `scripting`), `labs/ch05/assume-skip.sh` (snippets `assume-unchanged`, `assume-unchanged-breaks`, `skip-worktree`, `skip-worktree-breaks`, `find-and-clear`, `the-arrangement-that-works`), `labs/ch05/conflict-stages.sh` (snippets `conflict`, `read-the-stages`), `labs/ch05/stat-cache.sh` (snippets `entry`, `touch`, `refresh`, `real-change`), `labs/ch05/dirty-check-in-scripts.sh` (snippets `false-positive`, `refresh-first`) and `labs/ch05/index-lock-and-rebuild.sh` (snippets `lock`, `corrupt`, `rebuild`, `what-was-lost`).
- **Diagrams.** Show the root-cause box of section 5.12. New: one index entry drawn as a record with fields path, mode, blob ID, stage, flags and cached stat data.
- **Practical exercise.** Exercise 2.4 (Level 2, "what does the commit contain?") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Exercise 2.9 (Level 4, ""Git does not see my edits"") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q63: "Why are `--assume-unchanged` and `--skip-worktree` not ways to ignore local changes? What do you recommend to a team that needs per-developer settings?"
- **Homework.** Read sections 5.11 to 5.18 and do the Practice section 5.20.
- **Expected outcome.** The learner can inspect and repair the index and gives a correct answer to "how do I ignore my local change to a tracked file".

### V019: What a commit is, how git commit creates it, and the commit ID

- **Title.** What a commit is, how git commit creates it, and the commit ID
- **Learning objectives.** After this video the learner can:
  - Read every field of a commit object
  - List what `git commit` writes under `.git` and what it leaves untouched
  - Compute why a change to any field gives another commit ID
  - State what a commit ID guarantees and what it does not
- **Prerequisites.** V008, V015
- **Concepts.** A commit is a small text object: tree, parents, author, committer, message. `git commit` writes trees from the index, writes the commit, moves the current branch and appends to reflogs. The ID is a hash over all of it, parents included, so an ID fixes the whole history behind it. It says nothing about who really wrote the commit.
- **Commands.** `git commit`; `git cat-file -p`; `git write-tree`; `git commit-tree`; `git hash-object`
- **Demonstration.** Replay `labs/ch06/commit-anatomy.sh` (snippets `root-commit`, `object`, `step-by-step`, `what-moved`, `show-fuller`, `show-raw`), `labs/ch06/inside-git.sh` (snippets `add-writes-the-blob`, `commit-writes-trees-and-commit`, `files-touched`) and `labs/ch06/commit-id.sh` (snippets `hash-by-hand`, `same-inputs`, `one-field-changes`). In `one-field-changes`, change one field at a time and read the new ID.
- **Diagrams.** Redraw the diagram of section 6.2. Show the root-cause box of section 6.4.
- **Practical exercise.** Exercise 3.1 (Level 1, "read a commit field by field") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Exercise 3.7 (Level 3, "one ahead, one behind, and nobody else pushed") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q8: "What exactly does `git commit` write inside `.git`, and what does it leave untouched?"
- **Homework.** Read sections 6.1 to 6.4. Do Lab 3.2 ("Change only the committer date and watch the ID change") in [`lab-manual/m03-commits.md`](../lab-manual/m03-commits.md).
- **Expected outcome.** The learner explains immutability of commits from the hash and stops saying that a commit was "changed".

### V020: Author and committer, two dates, and parents

- **Title.** Author and committer, two dates, and parents
- **Learning objectives.** After this video the learner can:
  - Distinguish author from committer and name three operations that make them differ
  - Say which date `git log` prints and which date `--since` filters on
  - Diagnose a commit made with the wrong identity and fix the cause
  - Navigate parents of a merge with `^` and `~`
- **Prerequisites.** V019
- **Concepts.** Author: who wrote the change and when. Committer: who created this commit object and when. Cherry-pick, amend and rebase keep the author and renew the committer. Date filters use the committer date. Root commits have no parent, merge commits have several; `^2` selects a parent, `~2` walks first parents.
- **Commands.** `git log -1 --format=fuller`; `git commit --author`; `git commit --amend --no-edit --reset-author`; `git log --oneline --since`; `git log --oneline --first-parent`; `git log --oneline --graph`; `git rev-list --max-parents=0`
- **Demonstration.** Replay `labs/ch06/author-committer.sh` (snippets `cherry-pick`, `author-option`, `dates`, `who`, `amend`), `labs/ch06/date-filters.sh` (snippets `which-date-is-shown`, `which-date-is-filtered`), `labs/ch06/identity.sh` (snippets `wrong-email`, `diagnose`, `fix`, `no-guessing`) and `labs/ch06/parents.sh` (snippets `root`, `merge`, `navigate`, `two-diffs`, `log-basics`).
- **Diagrams.** Redraw the diagram of section 6.6. New: a merge commit with `HEAD^1`, `HEAD^2`, `HEAD~1`, `HEAD~2` written on the commits they name.
- **Practical exercise.** Exercise 3.2 (Level 1, "author and committer") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Exercise 3.8 (Level 3, "the commit that `--author` does not find") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q32: "Explain author and committer with three operations that make them differ. Which date does `git log` print, and which one does `--since` use?"
- **Homework.** Read sections 6.5 and 6.6. Do Exercise 3.3 (Level 1, "zero, one and two parents") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md) and Exercise 3.5 (Level 2, "which date is shown, which date filters?") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md).
- **Expected outcome.** The learner reads dates and identities in a log correctly and addresses any ancestor of a merge.

### V021: Amend, empty commits, trailers, messages and atomic commits

- **Title.** Amend, empty commits, trailers, messages and atomic commits
- **Learning objectives.** After this video the learner can:
  - Show that `git commit --amend` creates a new commit and find the old one
  - Predict what happens when an amended commit had already been pushed
  - Write trailers that Git recognizes and query them
  - Split work into atomic commits and justify the split by what a revert would do
  - Say where a signature is stored in a commit object
- **Prerequisites.** V020
- **Concepts.** Amend builds a new commit with the same parent; the old one becomes unreachable from the branch and stays in the reflog. Amending a pushed commit makes the branches diverge. `--allow-empty`. Trailers: position and form rules. Title line and body, and where tools use the title. An atomic commit is one that can be reverted alone. Signatures and attribution: a preview of Part 5.
- **Commands.** `git commit --amend`; `git reflog`; `git commit --allow-empty`; `git interpret-trailers`; `git log --format`; `git commit -s`; `git revert`; `git format-patch`
- **Demonstration.** Replay `labs/ch06/amend.sh` (snippets `mistake`, `amend`, `two-objects`, `reachability`, `keep-it`), `labs/ch06/amend-pushed.sh` (snippets `diverged`, `push-rejected`), `labs/ch06/empty-commit.sh` (snippets `allow-empty`), `labs/ch06/trailers.sh` (snippets `write`, `read`, `rules`), `labs/ch06/message-craft.sh` (snippets `message`, `where-the-title-is-used`, `format-patch`), `labs/ch06/atomic.sh` (snippets `two-commits`, `revert-one`) and `labs/ch06/signed-header.sh` (snippets `gpgsig`).
- **Diagrams.** Redraw the diagram of section 6.7: the old commit and the amended commit as siblings under one parent, with the branch label on the new one.
- **Practical exercise.** Lab 3.1 ("Amend a commit and find the old one") in [`lab-manual/m03-commits.md`](../lab-manual/m03-commits.md)
- **Challenge.** Exercise 3.9 (Level 4, "a commit made on the meeting-room laptop") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q33: "After `git commit --amend`, where is the old commit, how long does it stay, and how do you get it back?"
- **Homework.** Read sections 6.7 to 6.15 and do the Practice section 6.17, including Lab 3.3 ("Trailers") in [`lab-manual/m03-commits.md`](../lab-manual/m03-commits.md).
- **Expected outcome.** The learner amends only unpublished commits, knows where the old commit went, and writes commits that can be reverted one by one.

### V022: A branch is a ref, HEAD is a symbolic ref, and what a commit does to the current branch

- **Title.** A branch is a ref, HEAD is a symbolic ref, and what a commit does to the current branch
- **Learning objectives.** After this video the learner can:
  - Define a branch in one sentence without "copy" and prove the sentence from `.git`
  - Create, read and delete a branch with plumbing and compare with porcelain
  - Describe the three contents of `.git/HEAD`: on a branch, detached, unborn
  - Trace the two ref writes of one commit
- **Prerequisites.** V009, V019
- **Concepts.** A branch is a ref under `refs/heads/` that holds one commit ID. Creating one writes about forty bytes; nothing is copied. Refs may be loose files or packed, so plumbing is the reliable reader. HEAD is a symbolic ref. A commit updates the branch HEAD names and leaves HEAD's content alone.
- **Commands.** `git branch`; `git update-ref`; `git rev-parse`; `git symbolic-ref HEAD`; `git for-each-ref`; `git pack-refs --all`; `git update-ref -d`
- **Demonstration.** Replay `labs/ch07/branch-is-a-ref.sh` (snippets `porcelain`, `what-was-written`, `plumbing`, `by-hand`, `packed`), `labs/ch07/head-symref.sh` (snippets `read`, `unborn`, `head-only`) and `labs/ch07/commit-moves-branch.sh` (snippets `before`, `commit`, `after`). In `packed`, show that the loose file is gone and the branch still resolves.
- **Diagrams.** Redraw the diagram of section 7.2 and the diagram of section 7.4.
- **Practical exercise.** Lab 4.1 ("Refs by hand") in [`lab-manual/m04-refs-branches-head.md`](../lab-manual/m04-refs-branches-head.md)
- **Challenge.** Exercise 4.6 (Level 2, "from which branch was it created?") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q93: "What exactly is a branch? Define it in one sentence that mentions neither "copy" nor "line of development", and prove the definition with two commands."
- **Homework.** Read sections 7.1 to 7.4. Do Exercise 4.1 (Level 1, "a branch, and the file behind each step") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md) and Exercise 4.2 (Level 1, "HEAD follows you") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md).
- **Expected outcome.** The learner answers "what is a branch" at interview standard and never reads ref files directly in a script.

### V023: git branch and git switch

- **Title.** git branch and git switch
- **Learning objectives.** After this video the learner can:
  - List, create, rename, delete and force-move branches and state the risk label of each
  - Explain the rule by which `git branch -d` refuses a deletion
  - Switch branches with and without local changes and predict when Git refuses
  - Translate between `git switch` and the older `git checkout` forms
- **Prerequisites.** V022
- **Concepts.** `git branch` subcommands as ref operations. `-d` checks whether the branch is merged into its upstream or into HEAD; `-D` does not check. `git switch` updates HEAD, the index and the working tree; local changes are carried when they do not conflict and block the switch when they do. `git checkout` did three jobs; `switch` and `restore` split them.
- **Commands.** `git branch -vv`; `git branch -d`; `git branch -D`; `git branch -m`; `git branch -f`; `git branch --merged`; `git switch`; `git switch -c`; `git switch -`; `git switch --detach`; `git checkout`; `git switch --orphan`
- **Demonstration.** Replay `labs/ch07/branch-commands.sh` (snippets `list`, `remotes`, `merged`, `delete`, `upstream-rule`, `rename`, `force`) and `labs/ch07/switch-commands.sh` (snippets `create`, `previous`, `detach`, `checkout-equivalents`, `orphan`, `local-changes`). Before `delete`, predict which of the branches `-d` will refuse.
- **Diagrams.** New: a state table for `git switch <branch>` with the columns of the textbook's state tables.
- **Practical exercise.** Exercise 4.5 (Level 2, "which branches may be deleted?") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Challenge.** Exercise 4.7 (Level 3, "one switch carries the edit, the next one refuses") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q107: "Explain the `git branch -d` rule in terms of the upstream. Give one case where `-d` deletes a branch that `main` does not contain, and one where it refuses a branch that `main` does contain."
- **Homework.** Read sections 7.5 and 7.6.
- **Expected outcome.** The learner manages branches knowing which commands only move a name and which can make commits unreachable.

### V024: Detached HEAD

- **Title.** Detached HEAD
- **Learning objectives.** After this video the learner can:
  - Explain detached HEAD as HEAD holding a commit ID in place of a branch name
  - List the ordinary operations that detach HEAD
  - Make commits while detached and keep them before leaving
  - Recover commits left behind after switching away
- **Prerequisites.** V023
- **Concepts.** Detached HEAD is a normal state, used by Git itself during rebase and bisect and when checking out a tag or a remote-tracking branch. Commits made there are reachable only through HEAD; once HEAD moves, only the reflog names them. Keeping the work is one command: create a branch.
- **Commands.** `git switch --detach`; `git switch -c`; `git branch`; `git reflog`; `git log --oneline --graph --all`
- **Demonstration.** Replay `labs/ch07/detached-head.sh` (snippets `enter`, `no-current-branch`, `commit`, `leave`, `keep`, `remote-and-bisect`, `rebase`) and `labs/ch07/detached-ways.sh` (snippets `by-commit`, `clone-at-a-tag`, `worktree-from-a-tag`). At `leave`, read Git's warning aloud: it prints the command that saves the work.
- **Diagrams.** Redraw the diagram of section 7.7: HEAD pointing at a commit directly, a new commit above it with no branch label.
- **Practical exercise.** Lab 4.2 ("Detached HEAD rescue") in [`lab-manual/m04-refs-branches-head.md`](../lab-manual/m04-refs-branches-head.md)
- **Challenge.** Exercise 4.4 (Level 2, "a commit made while HEAD was detached") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q98: "A colleague's two days of commits are "gone" after she checked out a tag and later switched back to `main`. Walk through the recovery and explain why it works."
- **Homework.** Read section 7.7.
- **Expected outcome.** The learner works in detached HEAD on purpose and rescues commits left there without help.

### V025: Divergence, ancestry, and why Git has no parent-branch concept

- **Title.** Divergence, ancestry, and why Git has no parent-branch concept
- **Learning objectives.** After this video the learner can:
  - Compute the merge base of two branches and count how far each is ahead
  - Test whether one commit is an ancestor of another
  - Explain why Git cannot say which branch a branch was created from
  - Read `ahead` and `behind` against a remote-tracking branch as a statement about the last fetch
- **Prerequisites.** V024
- **Concepts.** Two branches diverge when each has commits the other lacks. The merge base. `--is-ancestor` as the yes-or-no test behind fast-forward and "merged". A branch stores one commit ID and no origin; any tool that shows a "parent branch" is guessing or storing it elsewhere. Remote-tracking branches and upstream as a preview of the remotes block.
- **Commands.** `git merge-base`; `git rev-list --left-right --count`; `git merge-base --is-ancestor`; `git log --oneline --graph --all`; `git branch -vv`; `git status -sb`
- **Demonstration.** Replay `labs/ch07/divergence.sh` (snippets `graph`, `merge-base`, `count`, `ancestor`, `diff-dots`), `labs/ch07/no-parent-branch.sh` (snippets `created-from`, `which-branch`, `you-choose-the-base`), `labs/ch07/base-guess.sh` (snippets `guess`) and `labs/ch07/upstream-preview.sh` (snippets `refs`, `upstream`, `last-known-state`, `setting-upstream`).
- **Diagrams.** Redraw the diagram of section 7.8.
- **Practical exercise.** Lab 4.4 ("Counting divergence") in [`lab-manual/m04-refs-branches-head.md`](../lab-manual/m04-refs-branches-head.md)
- **Challenge.** Exercise 4.6 (Level 2, "from which branch was it created?") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q108: "Does Git know which branch a branch was created from? What is the closest it can offer, and why is a pull request's base branch not the same thing?"
- **Homework.** Read sections 7.8 to 7.10.
- **Expected outcome.** The learner describes the relation of any two branches with three numbers and a merge base.

### V026: Lightweight tags, branch names, and stale branches

- **Title.** Lightweight tags, branch names, and stale branches
- **Learning objectives.** After this video the learner can:
  - Show that a lightweight tag is a ref that does not move when you commit
  - Explain why `feature` and `feature/x` cannot both exist and what breaks for teammates
  - Find branches that are merged, gone or old, and decide which may be deleted
  - Recognize a commit made on the wrong branch as two ref writes and plan the repair
- **Prerequisites.** V025
- **Concepts.** Tags as refs under `refs/tags/`; no reflog for tags. Ref names are paths, so a name cannot be a file and a directory at once; on a case-insensitive filesystem two names can collide. Naming conventions are conventions. Stale branches: merged, upstream gone, squash-merged. `git branch --delete-merged` is a Git 2.56 addition, not run here.
- **Commands.** `git tag`; `git rev-parse`; `git branch --merged`; `git branch --no-merged`; `git for-each-ref --sort=committerdate`; `git branch -vv`; `git branch -d`
- **Demonstration.** Replay `labs/ch07/lightweight-tags.sh` (snippets `a-ref`, `does-not-move`, `annotated-contrast`, `no-reflog`, `ambiguous`), `labs/ch07/ref-name-conflict.sh` (snippets `conflict`, `not-only-files`, `other-direction`, `invalid-names`, `full-name-trap`), `labs/ch07/case-trap.sh` (snippets `wrong-case`, `commit`, `fix`, `two-names`), `labs/ch07/stale-branches.sh` (snippets `by-date`, `merged`, `gone`, `squash-merged`, `git-2-56`) and `labs/ch07/wrong-branch.sh` (snippets `symptom`, `two-ref-writes`, `what-moved`).
- **Diagrams.** Show the root-cause box of section 7.12.
- **Practical exercise.** Lab 4.3 ("The `feature` versus `feature/x` conflict") in [`lab-manual/m04-refs-branches-head.md`](../lab-manual/m04-refs-branches-head.md)
- **Challenge.** Exercise 4.9 (Level 4, "three commits on the wrong branch") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q109: "Why does `git fetch` fail on every clone after someone pushes `feature/login`, and what is the one-command fix?"
- **Homework.** Read sections 7.11 to 7.16 and do the Practice section 7.18. Do Exercise 4.3 (Level 1, "a lightweight tag is a ref that does not move") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md) and Exercise 4.8 (Level 3, "the deploy script that picks the wrong commit") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md).
- **Expected outcome.** The learner cleans up branches from evidence and explains ref-name failures from how refs are stored.

### V027: Configuration: scopes, precedence, and reading and writing settings

- **Title.** Configuration: scopes, precedence, and reading and writing settings
- **Learning objectives.** After this video the learner can:
  - Name the configuration scopes and say which value wins when several set one key
  - Show the origin and scope of every setting in force with one command
  - Read, set and unset a key with the `git config` subcommands and state the Git version they need
  - Explain what an unknown key and a broken file do
- **Prerequisites.** V001, V019
- **Concepts.** System, global, local, worktree, command line and environment: later sources override earlier ones. `git config list --show-origin --show-scope` answers "where does this come from". The `get`, `set`, `unset` subcommands need Git 2.46 or later; the older option forms still appear in scripts. Typed values and multi-valued keys.
- **Commands.** `git config list --show-scope --show-origin`; `git config get`; `git config set`; `git config unset`; `git config get --all`; `git config --get`; `git -c`
- **Demonstration.** Replay `labs/ch14b/scopes.sh` (snippets `list`, `files`, `two-scopes`, `command-scope`, `worktree-scope`, `xdg`, `system`, `outside`, `environment`) and `labs/ch14b/config-commands.sh` (snippets `set-get-unset`, `legacy`, `file-syntax`, `types`, `multi-valued`, `search`, `sections`, `edit`, `unknown-key`, `broken-file`).
- **Diagrams.** Redraw the diagram of section 14B.2: the scopes as layers with an arrow marked "last one wins".
- **Practical exercise.** Lab 5.1 ("Scopes and origins") in [`lab-manual/m05-configuration.md`](../lab-manual/m05-configuration.md)
- **Challenge.** Exercise 5.4 (Level 2, "four sources for one identity") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q10: "A setting is in the system, global and local files with three different values, and an environment variable also exists for it. Which wins, and which single command shows you?"
- **Homework.** Read sections 14B.1 to 14B.3. Do Exercise 5.1 (Level 1, "one key in the local file") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md) to Exercise 5.3 (Level 1, "typed values") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md).
- **Expected outcome.** The learner can say for any setting where it comes from and which file to change.

### V028: Conditional includes, the settings to decide deliberately, aliases, and environment variables for diagnosis

- **Title.** Conditional includes, the settings to decide deliberately, aliases, and environment variables for diagnosis
- **Learning objectives.** After this video the learner can:
  - Configure two identities with `includeIf` and prove which one a repository uses
  - Give four reasons why a conditional include does not take effect
  - Justify a pull, push, fetch, merge, rebase, diff and rerere setting by its downside
  - Write an alias, including a shell alias with arguments, and trace what it runs
  - Trace a Git command with environment variables
- **Prerequisites.** V027
- **Concepts.** `include` and `includeIf` with `gitdir:` and `hasconfig:` conditions; position in the file decides precedence. Settings are decisions with costs; some are personal and some belong to a team. Aliases are expanded by Git; a shell alias runs from the top of the repository. `GIT_TRACE` and related variables show what Git runs.
- **Commands.** `git config get --show-origin user.email`; `git config list --global --includes --show-origin`; `git config set --global alias.lg`; `GIT_TRACE=1 git`; `GIT_TRACE_SETUP=1 git`; `GIT_SSH_COMMAND`
- **Demonstration.** Replay `labs/ch14b/includes.sh` (snippets `before`, `include-if`, `effect`, `commits`, `no-slash`, `order`, `not-in-a-repository`, `missing-file`, `hasconfig`, `team-file`), `labs/ch14b/settings.sh` (snippets `default-branch`, `autocorrect`, `diff-myers`, `diff-histogram`), `labs/ch14b/aliases.sh` (snippets `define`, `st-lg-last`, `unstage`, `amend`, `trace`, `arguments`, `shell-alias`, `shell-alias-arguments`, `no-override`, `file`) and `labs/ch14b/diagnose-env.sh` (snippets `trace`, `trace-setup`, `trace-to-file`, `ssh-command`). Then show `labs/ref/professional-config.sh` as the course's reference configuration.
- **Diagrams.** Redraw the diagram of section 14B.4.
- **Practical exercise.** Lab 5.2 ("Two identities with `includeIf`") in [`lab-manual/m05-configuration.md`](../lab-manual/m05-configuration.md)
- **Challenge.** Exercise 5.9 (Level 4, "two work repositories, two wrong addresses") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md)
- **Interview question.** Q57: "Your `includeIf` rule for `~/work/` exists, yet a work repository commits with your personal address. Give four causes and the command that distinguishes them."
- **Homework.** Read sections 14B.4 to 14B.7. Do Lab 5.3 ("Aliases") in [`lab-manual/m05-configuration.md`](../lab-manual/m05-configuration.md), then fill in the worksheet of Lab 5.4 ("Your deliberate configuration (a worksheet)") in [`lab-manual/m05-configuration.md`](../lab-manual/m05-configuration.md) and keep it; V174 revisits it.
- **Expected outcome.** The learner owns a configuration in which every line has a stated reason.

### V029: Gate briefing: Fundamentals

- **Title.** Gate briefing: Fundamentals
- **Learning objectives.** After this video the learner can:
  - State what Gate 1 covers, its four parts, their weights and the pass rule
  - Prepare for each part with the right material
  - Run a hands-on gate without reading the generator or the check script first
  - Use the remediation map after a miss
- **Prerequisites.** V006, V028
- **Concepts.** Gate 1 covers the data model, the three trees, commits, refs, HEAD and configuration. Pass at 85 overall with at least 70% in each of the four parts: concepts, prediction, hands-on diagnosis, oral interview. The hands-on repository is generated in a broken state with a report that is incomplete and partly wrong. A gate that has been read is a gate that has been taken. A miss leads to remediation and variant B, not to the answers.
- **Commands.** `git status`; `git branch -vv`; `git log --graph --decorate --oneline --all`; `git reflog`
- **Demonstration.** Replay `labs/ch01/diagnosis.sh` (snippets `status`, `branch`, `log`, `reflog`) as the warm-up: the hands-on part starts with this ritual. Show the table of the four parts and the "How a gate is taken" steps from [`assessments/README.md`](../assessments/README.md). Do not open the gate file on screen.
- **Diagrams.** New: a bar of 100 points split 30, 20, 30, 20 with the 70% line marked in each part and the 85 line on the total.
- **Practical exercise.** Redo Exercise 1.9 (Level 4, ""git log says there are no commits"") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md), Exercise 2.9 (Level 4, ""Git does not see my edits"") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md), Exercise 3.9 (Level 4, "a commit made on the meeting-room laptop") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md), Exercise 4.9 (Level 4, "three commits on the wrong branch") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md) and Exercise 5.9 (Level 4, "two work repositories, two wrong addresses") in [`exercises/m01-m05-foundations.md`](../exercises/m01-m05-foundations.md), the Level 4 exercises of Modules 1 to 5, without notes.
- **Challenge.** Take Gate 1: [`assessments/gate-1-fundamentals.md`](../assessments/gate-1-fundamentals.md).
- **Interview question.** Q3: "What is HEAD? Explain what the file contains, the difference between the symbolic and the detached form, and what moves it."
- **Homework.** Before the gate: answer the "Interview questions" sections of Chapters 1, 2, 4, 5, 6, 7 and 14B aloud, following [`interview/interview-mode-protocol.md`](../interview/interview-mode-protocol.md).
- **Expected outcome.** The learner sits Gate 1 knowing the rules, and after a miss knows exactly what to restudy.

## Part 2: Integration and collaboration mechanics

Roadmap Level 2 (Modules 6 to 10), with the Branching gate after Module 7 and the Merge and rebase gate after Module 10. 36 videos explain every merge, fetch, pull, push, undo, rebase and cherry-pick from the commit graph. Two gate briefings stand where the roadmap places the gates.

### V030: Divergence, the merge base, and fast-forward

- **Title.** Divergence, the merge base, and fast-forward
- **Learning objectives.** After this video the learner can:
  - Find the merge base of two commits and explain why it is the third input of a merge
  - Predict from the graph whether `git merge` will fast-forward
  - List what a fast-forward changes in `.git` and what it does not create
  - Explain "Already up to date" from ancestry
- **Prerequisites.** V025
- **Concepts.** A merge combines two histories that share an ancestor. The merge base is the best common ancestor. If the current branch is an ancestor of the other, the merge is a fast-forward: one ref moves, no object is written. If the other is an ancestor of the current branch, there is nothing to do.
- **Commands.** `git merge-base`; `git merge`; `git log --oneline --graph --all`; `git rev-list --left-right --count`
- **Demonstration.** Replay `labs/ch08/merge-base.sh` (snippets `merge-base`, `three-dot-diff`) and `labs/ch08/ff-or-true-merge.sh` (snippets `before`, `fast-forward`, `diverged`, `true-merge`, `merge-commit`, `up-to-date`). Before each `git merge`, ask "fast-forward, true merge, or nothing" and have the viewer answer from the graph.
- **Diagrams.** Redraw the diagram of section 8.2 and the diagram of section 8.3.
- **Practical exercise.** Lab 6.1 ("Predict fast-forward or three-way") in [`lab-manual/m06-merge.md`](../lab-manual/m06-merge.md)
- **Challenge.** Exercise 6.7 (Level 3, ""Already up to date", and the change is not there") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q123: "`git merge feature` printed "Fast-forward". What changed in `.git`, and what did not?"
- **Homework.** Read sections 8.1 to 8.3. Do Exercise 6.1 (Level 1, "a fast-forward, then a merge commit") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner predicts the kind of merge before running it and reads "Fast-forward" as "a ref moved".

### V031: The true merge: three inputs, one rule table, and criss-cross histories

- **Title.** The true merge: three inputs, one rule table, and criss-cross histories
- **Learning objectives.** After this video the learner can:
  - State the three-way rule for one path as a table of base, ours and theirs
  - Say which rows of the table are decided without reading file content
  - Explain why a change made on both sides and reverted on one comes back
  - Explain how two commits can have more than one merge base and what the default strategy does then
- **Prerequisites.** V030
- **Concepts.** The merge looks at three trees. Per path: unchanged on one side takes the other side; changed identically takes that; changed differently needs a content merge. The merge does not look at the commits in between, only at the three endpoints. Criss-cross histories have several merge bases; `ort` merges them into a virtual base first.
- **Commands.** `git merge`; `git merge-base --all`; `git ls-tree`; `git diff`; `git show`
- **Demonstration.** Replay `labs/ch08/three-way-rules.sh` (snippets `three-inputs`, `merge`, `result`, `content-merge`) and read the result path by path against the rule table. Then `labs/ch08/merge-base.sh` (snippets `crisscross`, `three-answers`, `virtual-base`, `diff3-nested`) for the criss-cross case.
- **Diagrams.** Redraw the diagram of section 8.4 and the diagram of section 8.5; show the root-cause box of section 8.5.
- **Practical exercise.** Exercise 6.2 (Level 1, "the merge base and the rule table") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Challenge.** Exercise 6.6 (Level 2, "which of three changes conflicts?") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q125: "What happens during a three-way merge?"
- **Homework.** Read sections 8.4 and 8.5. Draw the three trees for Exercise 6.2 (Level 1, "the merge base and the rule table") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md) before you run it.
- **Expected outcome.** The learner explains any merge result path by path from three inputs and stops expecting Git to "replay" the branch.

### V032: Strategies, strategy options, and exactly why conflicts occur

- **Title.** Strategies, strategy options, and exactly why conflicts occur
- **Learning objectives.** After this video the learner can:
  - Distinguish a merge strategy from a strategy option
  - Compare `-X ours`, `-X theirs` and `-s ours` by content and by ancestry
  - State the exact condition under which two edits to one file conflict
  - Predict for a pair of edits whether they conflict
- **Prerequisites.** V031
- **Concepts.** `ort` is the default strategy. `-X ours` and `-X theirs` decide conflicting hunks only; `-s ours` discards the other side's content entirely and still records the merge. There is no `-s theirs`. A conflict occurs when both sides changed the same region relative to the base, or regions that touch; edits on different lines far enough apart merge.
- **Commands.** `git merge -X ours`; `git merge -X theirs`; `git merge -s ours`; `git merge -X ignore-space-change`
- **Demonstration.** Replay `labs/ch08/strategy-options.sh` (snippets `what-differs`, `x-ours`, `x-theirs`, `s-ours`, `no-s-theirs`, `whitespace-conflict`, `ignore-space-change`). Then `labs/ch08/why-conflicts.sh` (snippets `different-regions`, `same-line`, `same-change`, `adjacent-lines`, `one-line-apart`); predict each of the five before showing it.
- **Diagrams.** Show the root-cause box of section 8.6 and the root-cause box of section 8.7. New: a file drawn as numbered lines with the two sides' changed regions shaded; overlap or contact means conflict.
- **Practical exercise.** Exercise 6.6 (Level 2, "which of three changes conflicts?") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Challenge.** Exercise 6.10 (Level 5, "the weekly sync that conflicts more every week") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q127: "Two branches changed different lines of one file and the merge still conflicted. Give the exact condition under which that happens."
- **Homework.** Read sections 8.6 and 8.7.
- **Expected outcome.** The learner knows that `-s ours` and `-X ours` are different tools and can predict a conflict from two diffs.

### V033: Anatomy of a conflict: working tree, index and .git, and the conflict styles

- **Title.** Anatomy of a conflict: working tree, index and .git, and the conflict styles
- **Learning objectives.** After this video the learner can:
  - List everything Git writes when a merge stops at a conflict
  - Read stages 1, 2 and 3 of a path without touching the working tree
  - Read conflict markers in the `merge`, `diff3` and `zdiff3` styles
  - Explain which commands are blocked while the merge is in progress
- **Prerequisites.** V018, V032
- **Concepts.** A stopped merge leaves markers in the working tree, three index entries for each conflicted path, and `MERGE_HEAD`, `MERGE_MSG` and related files in `.git`. Stage 1 is the base, 2 is ours, 3 is theirs; `:1:path`, `:2:path`, `:3:path` name them. `zdiff3` shows the base and moves common lines out of the conflict.
- **Commands.** `git merge`; `git status`; `git ls-files -u`; `git ls-files -s`; `git show`; `git diff`; `merge.conflictStyle`
- **Demonstration.** Replay `labs/ch08/conflict-anatomy.sh` (snippets `merge`, `status`, `markers`, `stages`, `read-stages`, `gitdir`, `diff`, `log-merge`, `blocked`, `resolve`, `add`, `continue`, `result`), one snippet at a time. Then `labs/ch08/conflict-styles.sh` (snippets `merge-style`, `diff3`, `zdiff3`, `config`): the same conflict three times.
- **Diagrams.** Redraw the diagram of section 8.8 and the diagram of section 8.9.
- **Practical exercise.** Lab 6.2 ("An edit-against-edit conflict, resolved by reading the stages") in [`lab-manual/m06-merge.md`](../lab-manual/m06-merge.md)
- **Challenge.** Exercise 6.8 (Level 3, "conflict markers in `main`") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q128: "During a conflict, what are index stages 1, 2 and 3? How do you read "their" version of a file without touching the working tree?"
- **Homework.** Read sections 8.8 and 8.9. Do Exercise 6.3 (Level 1, "one conflict, step by step") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner resolves a conflict by reading the three stages and never by guessing from markers alone.

### V034: The resolution workflow: abort, continue, quit, and restoring one side

- **Title.** The resolution workflow: abort, continue, quit, and restoring one side
- **Learning objectives.** After this video the learner can:
  - Run the checks that tell whether a merge can start
  - Resolve a conflict path by path and conclude the merge
  - Take one side of a path and explain what else that discards
  - Choose between `--abort`, `--continue` and `--quit` and state what each leaves behind
  - Bring back the conflicted state of a path that was resolved wrongly
- **Prerequisites.** V033
- **Concepts.** Before merging: a clean state or a known one. Resolve, stage, continue. `git checkout --ours` and `--theirs` (or `git restore --ours`, `--theirs`) take a whole file, including the other side's non-conflicting changes in it. `--abort` returns to the state before the merge when that state was clean; `--quit` forgets the merge and leaves the files. `git checkout --merge` (or `git restore --merge`) recreates the conflict.
- **Commands.** `git merge --abort`; `git merge --continue`; `git merge --quit`; `git restore --ours`; `git restore --theirs`; `git checkout --ours`; `git checkout --theirs`; `git checkout --merge`; `git restore --merge`; `git log --oneline --left-right --merge`; `git merge --autostash`
- **Demonstration.** Replay `labs/ch08/pre-merge-checks.sh` (snippets `staged-change`, `leftover-markers`, `merge-in-progress`, `untracked-file`, `unrelated-histories`), `labs/ch08/abort-continue-quit.sh` (snippets `continue-too-early`, `abort`, `nothing-in-progress`, `quit`, `after-quit`, `quit-cleanup`, `dirty-tree`, `autostash`), `labs/ch08/autostash-continue.sh` (snippets `stopped`, `concluded`) and `labs/ch08/restore-sides.sh` (snippets `ours`, `theirs`, `merge`, `checkout`, `unresolve`).
- **Diagrams.** New: a flow from "merge stops" to three exits (continue, abort, quit) with the state each exit leaves, drawn as three small three-tree strips.
- **Practical exercise.** Lab 6.7 ("Abort and retry with `zdiff3`") in [`lab-manual/m06-merge.md`](../lab-manual/m06-merge.md)
- **Challenge.** Exercise 6.9 (Level 4, "a merge that somebody else left half done") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q136: "`git merge --abort` is supposed to return you to the state before the merge. An engineer ran it during a conflicted merge and lost an uncommitted edit that predated the merge. How did the safety net fail, can the edit be recovered, and what do you tell the team?"
- **Homework.** Read section 8.10. Repeat Lab 6.2 ("An edit-against-edit conflict, resolved by reading the stages") in [`lab-manual/m06-merge.md`](../lab-manual/m06-merge.md) and resolve it a second time by taking one side, then list what you lost.
- **Expected outcome.** The learner can leave any stopped merge in a known state and knows the price of "take theirs".

### V035: Conflict types beyond content: renames, modify/delete, add/add, binary, directories

- **Title.** Conflict types beyond content: renames, modify/delete, add/add, binary, directories
- **Learning objectives.** After this video the learner can:
  - Name the conflict type from the line `git status` prints
  - Resolve a rename against an edit and explain the role of the similarity threshold
  - Resolve a modify/delete conflict in either direction from the stages that exist
  - Resolve a conflict in a binary file by choosing a version
  - Explain a directory-rename conflict and the setting that controls its detection
- **Prerequisites.** V034
- **Concepts.** Not every conflict has markers. Rename/edit merges cleanly when rename detection succeeds; rename/rename and rename/delete do not. Modify/delete leaves two stages and a file. Add/add has no base. Binary files have no content merge. A directory renamed on one side and a new file added inside it on the other.
- **Commands.** `git status`; `git ls-files -u`; `git rm`; `git add`; `git checkout --theirs`; `git merge -X`; `merge.directoryRenames`
- **Demonstration.** Replay `labs/ch08/conflict-rename.sh` (snippets `rename-edit`, `rename-rename`, `rename-rename-resolve`, `rename-delete`, `below-threshold`, `find-renames`), `labs/ch08/conflict-modify-delete.sh` (snippets `merge`, `stages`, `restore-vs-checkout`, `deleted-by-us`, `resolve-delete`), `labs/ch08/conflict-add-add.sh` (snippets `merge`, `file`), `labs/ch08/conflict-binary.sh` (snippets `merge`, `which-version`, `resolve`), `labs/ch08/conflict-directory-rename.sh` (snippets `merge`, `resolve`, `config`) and `labs/ch08/conflict-file-directory.sh` (snippets `merge`). For each, read the `git status` line first and name the type.
- **Diagrams.** Show the root-cause box of section 8.11. New: a table "type, stages present, markers yes or no, resolving command".
- **Practical exercise.** Lab 6.3 ("Rename against edit") in [`lab-manual/m06-merge.md`](../lab-manual/m06-merge.md)
- **Challenge.** Lab 6.4 ("Modify against delete") in [`lab-manual/m06-merge.md`](../lab-manual/m06-merge.md)
- **Interview question.** Q124: "State the three-way rule for a single path as a table of base, ours and theirs. Which rows never read file content?"
- **Homework.** Read section 8.11. Keep the table of conflict types; Part 9 uses it.
- **Expected outcome.** The learner is not stopped by a conflict that has no markers.

### V036: Controlling the result: --ff-only, --no-ff, --squash, the merge commit, first-parent history and octopus merges

- **Title.** Controlling the result: --ff-only, --no-ff, --squash, the merge commit, first-parent history and octopus merges
- **Learning objectives.** After this video the learner can:
  - Choose between `--ff-only`, `--no-ff`, `--no-commit` and `--squash` for a stated goal
  - Explain what a squash merge leaves behind and why the branch cannot be reused safely
  - Read a merge commit: two parents, and a diff against each
  - Explain what `--first-parent` shows and why the order of parents matters
  - Say when an octopus merge is possible
- **Prerequisites.** V034
- **Concepts.** `--ff-only` refuses anything but a fast-forward. `--no-ff` always records a merge commit. `--squash` stages the combined change and records no ancestry: Git does not know the branch was merged. A merge commit's first parent is the branch you were on. First-parent history reads `main` as a sequence of integrations. An octopus merge has more than two parents and is refused on conflict.
- **Commands.** `git merge --ff-only`; `git merge --no-ff`; `git merge --no-commit`; `git merge --squash`; `git log --first-parent`; `git show`; `git cat-file -p`; `merge.ff`
- **Demonstration.** Replay `labs/ch08/merge-flags.sh` (snippets `no-ff`, `no-commit-fast-forwards`, `no-commit`, `ff-only`, `squash`, `squash-commit`, `squash-then-reuse`, `merge-ff-config`); stop at `squash-then-reuse`. Then `labs/ch08/merge-commit-anatomy.sh` (snippets `object`, `parents`, `first-parent`, `diff-per-parent`, `flip`) and `labs/ch08/octopus.sh` (snippets `merge`, `commit`, `conflict`).
- **Diagrams.** Redraw the diagrams of sections 8.12 and 8.13 (the diagram of section 8.12, the diagram of section 8.13); show the root-cause box of section 8.12.
- **Practical exercise.** Exercise 6.5 (Level 2, "what a squash leaves behind") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Challenge.** Exercise 6.4 (Level 2, "two merges") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q131: "Compare `git merge -X ours`, `git merge -s ours` and `git merge --squash` in terms of content and ancestry."
- **Homework.** Read sections 8.12 to 8.14.
- **Expected outcome.** The learner chooses merge options by the history they produce and predicts the squash-then-reuse trap.

### V037: Clean for Git, wrong for humans: auditing a merge, and git merge-tree

- **Title.** Clean for Git, wrong for humans: auditing a merge, and git merge-tree
- **Learning objectives.** After this video the learner can:
  - Explain why two green branches can merge without conflict into a broken result
  - Show what a merge resolution changed with `--remerge-diff`
  - Say what `git show` displays for a merge commit and what it hides
  - Compute a merge without a working tree with `git merge-tree`
  - Name the follow-up topics: rerere, reverting a merge, and `git add --resolved` in Git 2.56
- **Prerequisites.** V036
- **Concepts.** Git merges text, not meaning: a rename on one side and a new caller on the other touch different lines. Only a test run on the merge result can find it. `git log -p` shows nothing for merges by default; `--remerge-diff` redoes the merge and shows how the recorded result differs. `git merge-tree --write-tree` is how a server can test mergeability. `git add --resolved` is a Git 2.56 addition, not run here.
- **Commands.** `git show --remerge-diff`; `git log --merges --remerge-diff`; `git show --first-parent`; `git show`; `git merge-tree --write-tree`; `git merge-base`
- **Demonstration.** Replay `labs/ch08/clean-but-wrong.sh` (snippets `both-merge-cleanly`, `check-fails`, `parents-pass`, `no-path-in-common`, `fix`), `labs/ch08/audit-merge.sh` (snippets `log-p-is-blind`, `show-combined`, `remerge-diff`, `first-parent`), `labs/ch08/merge-tree.sh` (snippets `bare`, `clean`, `commit`, `conflict`, `conflict-tree`, `quiet`), and as pointers `labs/ch08/revert-one-side.sh` (snippets `history`, `merge`, `three-inputs`) and `labs/ch08/revert-merge-preview.sh` (snippets `revert`, `remerge`).
- **Diagrams.** Show the root-cause box of section 8.15. New: two branches each with a green check, a merge commit with a red cross, and the caption "tested: neither parent's tree".
- **Practical exercise.** Lab 6.5 ("A clean merge that breaks the build") in [`lab-manual/m06-merge.md`](../lab-manual/m06-merge.md)
- **Challenge.** Incident 9, [`incidents/09-misunderstood-conflict`](../incidents/09-misunderstood-conflict/SYMPTOMS.md)
- **Interview question.** Q122: "Why can Git merge two files incorrectly from a human perspective?"
- **Homework.** Read sections 8.15 to 8.21 and do the Practice section 8.23, including Lab 6.6 ("Audit merges with `--remerge-diff`") in [`lab-manual/m06-merge.md`](../lab-manual/m06-merge.md).
- **Expected outcome.** The learner reviews merges as changes in their own right and explains to a manager why "no conflicts" is not "correct".

### V038: What a remote is, and git clone step by step

- **Title.** What a remote is, and git clone step by step
- **Learning objectives.** After this video the learner can:
  - Describe a remote as a name, URLs and refspecs in the configuration
  - Take `git clone` apart into the commands it performs
  - Explain where `origin/main` is stored and what `origin/HEAD` is
  - Compare a normal clone, a bare clone and a mirror clone by their refs
- **Prerequisites.** V025
- **Concepts.** A remote is configuration, not a connection. `git clone` is init, remote add, fetch, and a checkout of the remote's default branch with upstream set. Remote-tracking branches live under `refs/remotes/`. `--bare` has no working tree; `--mirror` also copies every ref and keeps them identical on fetch.
- **Commands.** `git clone`; `git remote -v`; `git remote add`; `git fetch`; `git config get --all --show-names --regexp`; `git show-ref --abbrev`; `git clone --bare`; `git clone --mirror`; `git remote set-head`
- **Demonstration.** Replay `labs/ch12/remote-anatomy.sh` (snippets `clone`, `refs`, `branches`, `bare`, `relative-url`), `labs/ch12/clone-by-hand.sh` (snippets `init-remote`, `fetch`, `switch`), `labs/ch12/clone-options.sh` (snippets `origin-branch`, `bare`, `mirror`, `tag`, `single-branch`), `labs/ch12/mirror-refresh.sh` (snippets `bare-does-not-follow`, `mirror-follows`, `mirror-prunes`) and `labs/ch12/origin-head.sh` (snippets `symref`, `stale`, `dangling`, `created-by-fetch`).
- **Diagrams.** Redraw the diagram of section 12.2: each repository its own box, with the refs each holds.
- **Practical exercise.** Lab 7.1 ("A bare server and two clones, watching every ref") in [`lab-manual/m07-remotes.md`](../lab-manual/m07-remotes.md)
- **Challenge.** Exercise 7.7 (Level 3, "the branch that this clone cannot see") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q210: "Take `git clone` apart into separate commands. What does `--mirror` add to `--bare`, and why does the difference matter for a backup?"
- **Homework.** Read sections 12.1 to 12.3. Do Exercise 7.1 (Level 1, "what a clone writes down about its remote") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner sees a clone as two repositories with separate refs and can rebuild a remote's configuration by hand.

### V039: git fetch: which refs move

- **Title.** git fetch: which refs move
- **Learning objectives.** After this video the learner can:
  - State exactly what `git fetch` writes and what it never touches
  - Explain why "up to date with origin/main" describes the last fetch
  - Ask the server for its refs without fetching
  - Inspect what a fetch brought before integrating it
- **Prerequisites.** V038
- **Concepts.** Fetch downloads objects and moves remote-tracking branches; it writes `FETCH_HEAD`; it does not touch local branches, the index or the working tree. `git status` compares local refs with remote-tracking refs and does not contact the server. `git ls-remote` does. Tags that point into fetched history come along; an existing tag is not replaced.
- **Commands.** `git fetch`; `git ls-remote`; `git status -sb`; `git log --oneline`; `git reflog show`; `git fetch --tags`; `git merge --ff-only`
- **Demonstration.** Replay `labs/ch12/fetch-anatomy.sh` (snippets `stale-status`, `ls-remote`, `fetch`, `after`, `graph`, `reflog`, `integrate`, `fetch-one-branch`, `fetch-url`, `quiet-fetch`) and `labs/ch12/fetch-tags.sh` (snippets `moved-tag`, `fetch-tags`, `force`). At `stale-status`, ask whether the branch is up to date; then show `ls-remote`.
- **Diagrams.** Redraw the diagram of section 12.4; show the root-cause box of section 12.4.
- **Practical exercise.** Exercise 7.2 (Level 1, "fetch first, look, then integrate") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Challenge.** Exercise 7.9 (Level 4, "a clone that has not talked to the server for a week") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q215: "State exactly what `git fetch` writes in your repository and what it never touches. Then name three things engineers expect a plain fetch to update that it does not."
- **Homework.** Read section 12.4. Do Exercise 7.4 (Level 2, "what the clone knows before and after a fetch") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md) and Exercise 7.6 (Level 2, "which refs does a fetch move?") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner fetches before trusting any statement about the server and never fears that a fetch changes local work.

### V040: Upstream branches, push.default, and git pull as fetch plus one integration step

- **Title.** Upstream branches, push.default, and git pull as fetch plus one integration step
- **Learning objectives.** After this video the learner can:
  - Explain what `branch.<name>.remote` and `branch.<name>.merge` record and set an upstream three ways
  - Predict where a plain `git push` goes under `push.default=simple`
  - Describe `git pull` as fetch followed by merge or rebase
  - Explain the "divergent branches" error and the three configurations that answer it
- **Prerequisites.** V030, V039
- **Concepts.** The upstream of a branch is two configuration values. `push.default` decides what a bare `git push` does; `push.autoSetupRemote` sets the upstream on first push. `git pull` runs a fetch and then one integration step chosen by `pull.rebase` and `pull.ff`; when the branches have diverged and nothing is configured, Git stops and asks.
- **Commands.** `git branch -vv`; `git push -u`; `git branch -u`; `git switch -c`; `push.autoSetupRemote`; `git pull`; `git pull --ff-only`; `git pull --rebase`; `git pull --no-rebase`; `pull.rebase`; `pull.ff`
- **Demonstration.** Replay `labs/ch12/upstream-config.sh` (snippets `no-upstream`, `push-u`, `shorthands`, `guess`, `branch-u`, `auto-setup-remote`, `simple-name-mismatch`, `push-default-dry-runs`), `labs/ch12/pull-anatomy.sh` (snippets `fast-forward`, `diverged`, `after-fatal`, `ff-only`, `merge`, `back-to-diverged`, `rebase`, `config`) and `labs/ch12/pull-matrix.sh` (snippets `config-only`, `flags`).
- **Diagrams.** Redraw the diagram of section 12.6: the same diverged state integrated by merge and by rebase, side by side.
- **Practical exercise.** Lab 7.3 ("The diverged pull error and the three configurations") in [`lab-manual/m07-remotes.md`](../lab-manual/m07-remotes.md)
- **Challenge.** Exercise 7.5 (Level 2, "the same pull, by merge and by rebase") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q205: "A pull stopped with "Need to specify how to reconcile divergent branches". What changed in the repository and what did not? Give the three answers and their effect on history."
- **Homework.** Read sections 12.5 and 12.6.
- **Expected outcome.** The learner configures pull deliberately and explains every pull as two steps.

### V041: git push: asking another repository to move its refs

- **Title.** git push: asking another repository to move its refs
- **Learning objectives.** After this video the learner can:
  - Describe a push as a request that the receiving repository may refuse
  - Tell `rejected (fetch first)` from `rejected (non-fast-forward)` and fix each
  - Push and delete branches and tags and predict which refs travel
  - Explain "Everything up-to-date" when the commit is not on the server
  - Explain why Git refuses a push into a checked-out branch
- **Prerequisites.** V040
- **Concepts.** Push sends objects and asks for ref updates; the default rule on the receiving side is fast-forward only. Two rejection messages name two different states of knowledge. Tags are not pushed unless named. `--atomic` makes several ref updates all-or-nothing. Pushing from a detached HEAD or with a wrong refspec pushes nothing. A non-bare repository refuses a push to its current branch by default. On a plain Git server, `receive.*` settings and a `pre-receive` hook are what stands in the place of GitHub's rules.
- **Commands.** `git push`; `git push origin`; `git push origin --delete`; `git push --follow-tags`; `git push --atomic`; `git push --dry-run`; `git fetch`; `git ls-remote --branches`; `receive.denyCurrentBranch`; `receive.denyNonFastForwards`; `receive.denyDeletes`
- **Demonstration.** Replay `labs/ch12/push-rejections.sh` (snippets `fetch-first`, `non-fast-forward`, `wire`, `integrate-and-push`), `labs/ch12/push-refs.sh` (snippets `delete-branch`, `tags-are-not-pushed`, `push-tags`, `tag-update-rejected`, `atomic`, `not-atomic`), `labs/ch12/push-errors.sh` (snippets `src-refspec`, `unborn`, `detached`, `no-such-remote`), `labs/ch12/server-rules.sh` (snippets `deny-non-fast-forwards`, `deny-deletes`, `pre-receive`) and `labs/ch12/push-non-bare.sh` (snippets `refused`, `other-branch`, `update-instead`, `dirty-target`).
- **Diagrams.** Redraw the diagram of section 12.7.
- **Practical exercise.** Lab 7.2 ("A rejected push, then fetch and integrate by merge and by rebase") in [`lab-manual/m07-remotes.md`](../lab-manual/m07-remotes.md)
- **Challenge.** Exercise 7.10 (Level 5, "the hotfix that was pushed and is not on the server") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q206: "Two engineers in the same situation got `rejected (fetch first)` and `rejected (non-fast-forward)`. Explain the difference and who made each decision. How is `remote rejected` different?"
- **Homework.** Read sections 12.7 and 12.9. Do Exercise 7.3 (Level 1, "publish a branch, then delete it on the server") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md) and Exercise 7.8 (Level 3, "a push that the other side refuses") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner reads a push rejection as information about two graphs and fixes it without force.

### V042: Forcing a push: what it destroys, the lease, and --force-if-includes

- **Title.** Forcing a push: what it destroys, the lease, and --force-if-includes
- **Learning objectives.** After this video the learner can:
  - Explain what a forced push does to the server's ref and to teammates' commits
  - Explain what `--force-with-lease` checks and construct the sequence in which it fails to protect
  - Explain what `--force-if-includes` adds
  - Find the overwritten commits afterwards and say who still has them
- **Prerequisites.** V041
- **Concepts.** A forced push replaces the server's ref regardless of ancestry; commits only that ref reached become unreachable on the server. The lease compares the server's ref with your remote-tracking ref, so anything that updates the remote-tracking ref without your reading it, such as a background fetch, defeats it. `--force-if-includes` also requires that the remote tip is in your reflog. The explicit lease form names the expected ID.
- **Commands.** `git push --force`; `git push --force-with-lease`; `git push --force-with-lease --force-if-includes`; `push.useForceIfIncludes`; `git reflog`; `git fetch`
- **Demonstration.** Replay `labs/ch12/force-push.sh` (snippets `rewrite`, `lease-holds`, `background-fetch`, `guards`, `lease-defeated`, `what-is-left`, `teammate-fetch`, `pull-rebase-drops`, `recover`) and `labs/ch12/lease-forms.sh` (snippets `one-ref`, `must-not-exist`, `plain-force`, `where-it-survives`, `fetch-by-id`). Before the first forced push, give the five answers for a dangerous command.
- **Diagrams.** Show both root-cause boxes of section 12.8 (the root-cause box of section 12.8). New: a three-column timeline (you, server, teammate) for the sequence in which the bare lease passes and a teammate's commit is lost.
- **Practical exercise.** Lab 7.4 ("When `--force-with-lease` saves you and when it does not") in [`lab-manual/m07-remotes.md`](../lab-manual/m07-remotes.md)
- **Challenge.** Incident 2, [`incidents/02-force-push-wrong-branch`](../incidents/02-force-push-wrong-branch/SYMPTOMS.md)
- **Interview question.** Q203: "Why does `--force-with-lease` exist?"
- **Homework.** Read section 12.8. Write the lease-defeating sequence from memory as a timeline.
- **Expected outcome.** The learner force-pushes only their own branches, with both guards, and can explain to a teammate where an overwritten commit still exists.

### V043: More than one remote, pruning, and branches whose upstream is gone

- **Title.** More than one remote, pruning, and branches whose upstream is gone
- **Learning objectives.** After this video the learner can:
  - Configure `origin` and `upstream` for a fork and say which one each command uses
  - Set separate fetch and push URLs and rename or remove a remote
  - Explain what pruning deletes and what it never deletes
  - Explain how a branch deleted on the server comes back, and prevent it
- **Prerequisites.** V040
- **Concepts.** A triangular setup fetches from one repository and pushes to another: `remote.pushDefault` or per-branch settings decide. Remote-tracking branches are not removed when the server's branch is deleted unless you prune. `[gone]` marks a local branch whose upstream no longer exists. A stale clone that pushes all its branches recreates deleted ones.
- **Commands.** `git remote add upstream`; `git remote set-url --push`; `git remote rename`; `git remote remove`; `remote.pushDefault`; `git fetch --prune`; `git remote prune`; `git remote show origin`; `git branch -vv`; `fetch.prune`
- **Demonstration.** Replay `labs/ch12/fork-triangular.sh` (snippets `fork-and-clone`, `refs`, `triangular-config`, `two-comparisons`, `rebase-and-republish`, `sync-fork-main`), `labs/ch12/push-destination.sh` (snippets `push-default-remote`, `current`, `per-branch`), `labs/ch12/remote-urls.sh` (snippets `push-url`, `two-push-urls`, `instead-of`, `remote-group`, `rename`, `remove`), `labs/ch12/prune-gone.sh` (snippets `stale`, `remote-show`, `fetch-blocked`, `prune`, `gone`, `zombie`, `cleanup`, `fetch-prune-config`) and `labs/ch12/prune-forgets.sh` (snippets `last-name`, `rescue`).
- **Diagrams.** Redraw the diagram of section 12.10: upstream, fork and clone as three boxes with fetch and push arrows.
- **Practical exercise.** Lab 7.5 ("Upstream configuration and a triangular fork simulation") in [`lab-manual/m07-remotes.md`](../lab-manual/m07-remotes.md)
- **Challenge.** Incident 8, [`incidents/08-branch-disappeared`](../incidents/08-branch-disappeared/SYMPTOMS.md)
- **Interview question.** Q214: "A branch that was deleted a month ago is back on the server, and nobody intended it. How did it happen, and what do you change?"
- **Homework.** Read sections 12.10 and 12.11. Do Lab 7.6 ("Prune and "gone" branches") in [`lab-manual/m07-remotes.md`](../lab-manual/m07-remotes.md).
- **Expected outcome.** The learner runs a fork setup with correct defaults and keeps remote-tracking branches truthful.

### V044: Refspecs in depth, transports, and two diagnoses from first principles

- **Title.** Refspecs in depth, transports, and two diagnoses from first principles
- **Learning objectives.** After this video the learner can:
  - Read and write a fetch refspec and a push refspec, including `+` and a negative refspec
  - Widen a narrow clone so that a missing branch becomes fetchable
  - Name the transports and trace which programs a fetch and a push run
  - Diagnose "the push pushed nothing" and "the branch exists on the server and this clone cannot see it"
- **Prerequisites.** V042, V043
- **Concepts.** A refspec maps source refs to destination refs. A single-branch or CI clone has a narrow fetch refspec, which is why other branches are invisible. Transports: local path, `file`, HTTPS, SSH; a bundle is a transport in a file. On the wire a fetch runs `upload-pack` and a push runs `receive-pack`.
- **Commands.** `git config get --all remote.origin.fetch`; `git remote set-branches`; `git fetch origin`; `git push origin HEAD`; `git ls-remote`; `git bundle create`; `GIT_TRACE=1 git fetch`
- **Demonstration.** Replay `labs/ch12/refspec-surgery.sh` (snippets `narrow-clone`, `widen`, `plus`, `negative`, `pull-request-refs`, `push-refspecs`), `labs/ch12/transports.sh` (snippets `url-forms`, `bundle-create`, `bundle-clone`), `labs/ch12/transport-trace.sh` (snippets `fetch`, `push`, `programs`), and `labs/ch12/diagnose.sh` (snippets `the-push-that-pushed-nothing`, `where-is-the-commit`, `ask-the-server`, `fix`, `ambiguous-name`, `rebuild-remote-tracking`).
- **Diagrams.** Show the root-cause box of section 12.14. New: a refspec drawn as `+<source>:<destination>` with each part labelled and one ref traced through it.
- **Practical exercise.** Lab 7.7 ("Refspec surgery") in [`lab-manual/m07-remotes.md`](../lab-manual/m07-remotes.md)
- **Challenge.** Incident 10, [`incidents/10-commit-local-not-remote`](../incidents/10-commit-local-not-remote/SYMPTOMS.md)
- **Interview question.** Q216: "In a CI workspace `git switch release/2.3` fails with an invalid reference although the branch exists on the server, and on a laptop a fetch rejects the update of a remote-tracking ref as a non-fast-forward. Diagnose both from what a refspec is."
- **Homework.** Read sections 12.12 to 12.17 and do the Practice section 12.19.
- **Expected outcome.** The learner can explain any "branch not found" or "nothing pushed" report from refspecs and proves the server's state with `git ls-remote`.

### V045: Gate briefing: Branching

- **Title.** Gate briefing: Branching
- **Learning objectives.** After this video the learner can:
  - State what Gate 2 covers and its threshold of 90
  - Explain why the threshold is higher than for Gate 1
  - Prepare the prediction part by drawing graphs with local and remote-tracking refs
  - Run the hands-on part with the ritual first and the server asked directly
- **Prerequisites.** V026, V044
- **Concepts.** Gate 2 covers branches as refs, divergence, ancestry, upstream tracking, remote-tracking refs, fetch, pull and push. Pass at 90 overall and at least 70% in each part. The typical loss of points is trusting a remote-tracking ref as if it were the server, and repairing with force where an integration was possible; the safety of the path is scored.
- **Commands.** `git branch -vv`; `git ls-remote`; `git fetch`; `git log --oneline --graph --decorate --all`
- **Demonstration.** Replay `labs/ch12/fetch-anatomy.sh` (snippets `stale-status`, `ls-remote`, `fetch`, `after`) as the warm-up: the same question, "what does the server have", answered wrongly by `status` and rightly by `ls-remote`. Show the gate rules from [`assessments/README.md`](../assessments/README.md). Do not open the gate file on screen.
- **Diagrams.** New: three boxes (your clone, the server, a teammate's clone), each with its own `main`, and your clone's `origin/main` drawn as a dated photograph of the server's `main`.
- **Practical exercise.** Redo Exercise 6.9 (Level 4, "a merge that somebody else left half done") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md), Exercise 7.9 (Level 4, "a clone that has not talked to the server for a week") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md) and Exercise 7.10 (Level 5, "the hotfix that was pushed and is not on the server") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md) without notes.
- **Challenge.** Take Gate 2: [`assessments/gate-2-branching.md`](../assessments/gate-2-branching.md).
- **Interview question.** Q92: "What is the difference between HEAD, a branch and a remote-tracking branch?"
- **Homework.** Before the gate: answer the "Interview questions" sections of Chapters 7, 8 and 12 aloud.
- **Expected outcome.** The learner sits Gate 2 able to state, for every ref in a problem, which repository it lives in.

### V046: The undo map and git restore

- **Title.** The undo map and git restore
- **Learning objectives.** After this video the learner can:
  - Name the four places an undo can act on and the one question that decides between rewriting and adding
  - Say for each form of `git restore` where the content comes from and where it goes
  - Restore a path from an older commit into the index, the working tree, or both
  - State which forms of `git restore` destroy work that no object holds
- **Prerequisites.** V017, V045
- **Concepts.** Four places: the working tree, the index, the local branch, the shared history. The deciding question: has anyone else got this commit? `git restore` copies a stored version over files or index entries and never moves a ref. `--staged` reads HEAD and writes the index; the default reads the index and writes the working tree; `--source` changes what is read.
- **Commands.** `git restore`; `git restore --staged`; `git restore --source=HEAD~2`; `git restore --source=HEAD~2 --staged --worktree`; `git restore -p`
- **Demonstration.** Replay `labs/ch11/restore-variants.sh` (snippets `before`, `worktree`, `staged`, `reset-path`, `staged-worktree`, `source`, `source-staged-worktree`, `checkout-equivalent`, `patch`, `patch-result`). Before each variant, fill a three-tree strip with the version each tree will hold afterwards, then compare with the output.
- **Diagrams.** Redraw the diagram of section 11.2. New: one arrow per `git restore` form across the three-tree strip.
- **Practical exercise.** Lab 8.4 ("Restore variants") in [`lab-manual/m08-undo.md`](../lab-manual/m08-undo.md)
- **Challenge.** Exercise 8.7 (Level 3, "the commit that came back") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q170: "A colleague asks for "the undo command". Name the five commands that Git offers for undoing work, and say which of working tree, index, branch ref and history each one writes."
- **Homework.** Read sections 11.1 to 11.3.
- **Expected outcome.** The learner asks "published or not" before any undo and uses `git restore` knowing which direction content flows.

### V047: git reset: the three modes, why --hard is dangerous, and the resets that check first

- **Title.** git reset: the three modes, why --hard is dangerous, and the resets that check first
- **Learning objectives.** After this video the learner can:
  - Predict the working tree, the index and the branch after `--soft`, `--mixed` and `--hard`
  - Sort work into committed, staged and never staged, and say what a hard reset leaves recoverable for each
  - Preview a hard reset and set a way back before running it
  - Choose `--keep` over `--hard` and explain what `--merge` protects
  - Describe `git commit --amend` as a soft reset followed by a commit
- **Prerequisites.** V046
- **Concepts.** Reset moves the current branch; the mode decides how far the change spreads: branch only, branch and index, or all three. Commits left behind stay reachable from the reflog. Work that was staged still has blobs. Work that was never staged has no object and is gone. `--keep` refuses when it would overwrite local changes. `ORIG_HEAD` is one slot that several commands write.
- **Commands.** `git reset --soft`; `git reset --mixed`; `git reset --hard`; `git reset --keep`; `git reset --merge`; `git reflog`; `git fsck --lost-found`; `git commit --amend`
- **Demonstration.** Replay `labs/ch11/reset-modes.sh` (snippets `before`, `soft`, `mixed`, `hard`, `inside-git`, `orig-head`), `labs/ch11/orig-head-slot.sh` (snippets `merge-then-stash`, `reflog-has-it`), `labs/ch11/reset-hard-preview.sh` (snippets `preview`, `safety-net`, `nothing-was-lost`), `labs/ch11/reset-hard-proofs.sh` (snippets `three-kinds-of-work`, `reset-hard`, `committed-work`, `staged-work`, `never-staged-work`, `untracked-overwritten`), `labs/ch11/reset-keep-merge.sh` (snippets `state`, `keep`, `merge`, `hard`, `keep-refuses`) and `labs/ch11/amend-is-soft-reset.sh` (snippets `amend`, `by-hand`, `undo-the-amend`). Give the five answers for a dangerous command before `reset-hard`.
- **Diagrams.** Redraw the diagram of section 11.4; show the root-cause box of section 11.5.
- **Practical exercise.** Lab 8.1 ("The reset prediction table") in [`lab-manual/m08-undo.md`](../lab-manual/m08-undo.md)
- **Challenge.** Exercise 8.8 (Level 3, "what a hard reset took and what it left") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q171: "HEAD, the index and the working tree hold three different versions of one file. What does each hold after `git reset --soft HEAD~1`, after `--mixed` and after `--hard`, and what does `git status -s` print?"
- **Homework.** Read sections 11.4 to 11.7. Do Exercise 8.4 (Level 2, "`reset --keep`, twice") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md) and Exercise 8.6 (Level 2, "after a hard reset") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner can say before a reset exactly what will survive it and where.

### V048: git revert: a new commit that applies the inverse change

- **Title.** git revert: a new commit that applies the inverse change
- **Learning objectives.** After this video the learner can:
  - Describe a revert as a three-way merge and name its base, ours and theirs
  - Revert one commit, a range, and several commits as one
  - Explain why reverting an old commit can conflict
  - Leave a stopped revert sequence in a known state
- **Prerequisites.** V010, V047
- **Concepts.** Revert adds a commit; nothing is rewritten, so it is the undo for published history. Base is the commit being reverted, theirs is its parent. `-n` stages without committing. A sequence can stop halfway; `--continue`, `--skip`, `--abort` and `--quit` are the exits. `-m` on `git revert` is not a message option.
- **Commands.** `git revert`; `git revert --no-edit`; `git revert -n`; `git revert --continue`; `git revert --abort`; `git revert --skip`; `git revert --quit`
- **Demonstration.** Replay `labs/ch11/revert-basics.sh` (snippets `revert`, `the-new-commit`, `inside-git`, `already-reverted`, `m-is-not-a-message`, `dirty-tree`, `range`, `no-commit`, `conflict`, `conflict-state`, `resolve`) and `labs/ch11/revert-sequence.sh` (snippets `stops-halfway`, `sequencer-state`, `abort`, `quit`, `skip`).
- **Diagrams.** Redraw the diagram of section 11.8.
- **Practical exercise.** Lab 8.2 ("Revert a pushed commit") in [`lab-manual/m08-undo.md`](../lab-manual/m08-undo.md)
- **Challenge.** Exercise 8.5 (Level 2, "revert a range") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q180: "Describe `git revert` as a three-way merge: what are base, ours and theirs? Use the answer to explain why reverting an old commit can conflict."
- **Homework.** Read section 11.8. Do Exercise 8.2 (Level 1, "revert a commit that is not the last one") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner undoes published commits without rewriting and explains a revert conflict from its three inputs.

### V049: Reverting a merge, and the re-merge problem

- **Title.** Reverting a merge, and the re-merge problem
- **Learning objectives.** After this video the learner can:
  - Revert a merge commit with `-m 1` and say what that choice means
  - Explain why merging the repaired branch again brings only the new commits
  - Repair the situation by reverting the revert or by recreating the branch
  - Contrast the behavior after a squash merge
- **Prerequisites.** V036, V048
- **Concepts.** A reverted merge is still an ancestor: its commits remain "already merged". A later merge of the same branch therefore brings only what was added since. Two repairs: revert the revert, or give the old commits new IDs so that Git sees them as new. After a squash merge there is no ancestry, so a re-merge brings everything.
- **Commands.** `git revert -m`; `git revert --no-edit -m`; `git merge`; `git merge-base`; `git rebase --no-ff`; `git log --oneline --graph`
- **Demonstration.** Replay `labs/ch11/revert-merge.sh` (snippets `merge`, `revert-needs-m`, `revert-message`, `remerge-brings-nothing`, `remerge-brings-only-the-fix`, `revert-the-revert`, `final-graph`), `labs/ch11/revert-merge-rebuild.sh` (snippets `plain-rebase-leaves-the-work-out`, `recreate-the-branch`, `merge-brings-everything`) and `labs/ch11/revert-squash-remerge.sh` (snippets `squash-then-revert`, `remerge-brings-everything`). Ask for a prediction at `remerge-brings-nothing`.
- **Diagrams.** Redraw the diagram of section 11.9; show the root-cause box of section 11.9.
- **Practical exercise.** Lab 8.3 ("Revert a merge, then re-merge") in [`lab-manual/m08-undo.md`](../lab-manual/m08-undo.md)
- **Challenge.** Exercise 8.10 (Level 5, "a feature that was merged twice and is half missing") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q182: "You reverted a merge with `-m 1` last week. Today the fixed branch was merged again and the feature is incomplete. Explain the mechanism with the merge base and give two correct procedures. What would `-m 2` have undone, and why does a squash merge not show the problem?"
- **Homework.** Read section 11.9.
- **Expected outcome.** The learner can take a merged feature out of `main` and bring it back complete.

### V050: git clean, and stash: uncommitted work parked as commits

- **Title.** git clean, and stash: uncommitted work parked as commits
- **Learning objectives.** After this video the learner can:
  - Preview and run `git clean` and state why it has no undo
  - Park and restore work with stash, including untracked files and the staged state
  - Resolve a conflict from `git stash pop` and explain why the entry was kept
  - Recover a dropped stash entry by its ID
  - Give three reasons to prefer a commit on a branch to a stash
- **Prerequisites.** V047
- **Concepts.** `git clean` removes untracked files; Git holds no copy. A stash entry is a commit with parents; `pop` is `apply` plus `drop`, and the drop is skipped on conflict. `--index` restores the staged state. `-u` includes untracked files. A dropped entry is an unreachable commit until maintenance removes it.
- **Commands.** `git clean -n`; `git clean -n -d`; `git clean -f -d`; `git stash push -m`; `git stash list`; `git stash show -p`; `git stash apply`; `git stash pop`; `git stash pop --index`; `git stash drop`; `git stash branch`; `git stash push --staged -m`; `git stash push --keep-index -m`
- **Demonstration.** Replay `labs/ch11/clean.sh` (snippets `status`, `refuses-without-force`, `dry-runs`, `clean`, `gone-for-good`), `labs/ch11/stash-basics.sh` (snippets `push`, `show`, `apply`, `pop-index`, `include-untracked`, `staged-only`, `keep-index`, `pathspec`) and `labs/ch11/stash-conflict.sh` (snippets `stash-then-hotfix`, `pop-conflict`, `conflict-state`, `resolve-and-drop`, `back-out-and-branch`, `dropped-entry-by-id`). The script `labs/ch11/stash-untracked-trap.sh` (snippets `refused-but-not-untouched`, `half-applied`, `compare-then-drop`) belongs to the lab; show it last.
- **Diagrams.** Redraw the diagram of section 11.11.
- **Practical exercise.** Lab 8.6 ("Stash and a pop conflict") in [`lab-manual/m08-undo.md`](../lab-manual/m08-undo.md)
- **Challenge.** Lab 8.5 ("Clean safely") in [`lab-manual/m08-undo.md`](../lab-manual/m08-undo.md)
- **Interview question.** Q177: "What is inside a stash entry and where is it stored? What happens when `git stash pop` conflicts? Give three reasons not to use the stash for long-term storage."
- **Homework.** Read sections 11.10 and 11.11. Do Exercise 8.3 (Level 1, "park an edit and bring it back") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner uses stash for minutes, not days, and never runs `git clean` without a dry run.

### V051: One table, one decision tree, and seven worked undo scenarios

- **Title.** One table, one decision tree, and seven worked undo scenarios
- **Learning objectives.** After this video the learner can:
  - Choose the lowest-risk undo for a described situation and state its effect on HEAD, the branch, the index, the working tree and history
  - Justify the choice by whether the history is shared
  - Carry out seven standard scenarios and verify the end state
  - Name the choice that would have been wrong and why
- **Prerequisites.** V049, V050
- **Concepts.** The comparison table of restore, reset, revert, clean and stash. The decision tree: what do you want to undo, where is it, has it been published. Seven scenarios from "undo the last unpushed commit" to "undo a pushed merge".
- **Commands.** `git reset --soft`; `git revert`; `git restore --staged`; `git restore`; `git reset --merge`; `git revert -m`
- **Demonstration.** Replay `labs/ch11/scenarios.sh` (snippets `s1-undo-last-unpushed-commit`, `s2-pushed-bad-commit`, `s3-remove-file-from-last-commit`, `s4-unstage`, `s5-discard-local-changes`, `s6-undo-unpushed-merge`, `s7-undo-pushed-merge`). For each scenario show only the situation first, let the viewer choose, then show the command.
- **Diagrams.** Redraw the diagram of section 11.12: the decision tree.
- **Practical exercise.** Lab 8.7 ("Scenario cards") in [`lab-manual/m08-undo.md`](../lab-manual/m08-undo.md)
- **Challenge.** Exercise 8.9 (Level 4, "one bad commit that is public, one mixed commit that is not") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q181: "A bad commit is on `main` and the team has pulled it. Compare "revert and push" with "reset and force-push": what does each do to the server, to the teammates' clones and to CI?"
- **Homework.** Read sections 11.12 to 11.16 and do the Practice section 11.18. Do Exercise 8.1 (Level 1, "take a commit back and make it again") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner answers "how do I undo this" with a question about publication and one command with a stated risk.

### V052: What a rebase is, and why every rebased commit has a new ID

- **Title.** What a rebase is, and why every rebased commit has a new ID
- **Learning objectives.** After this video the learner can:
  - Describe a rebase as copying commits onto a new base and moving the branch
  - Explain from the commit object why each copy has a new ID even with an identical diff
  - Show where the original commits are after the rebase
  - Perform a rebase by hand with `git switch --detach`, `git cherry-pick` and a branch move
- **Prerequisites.** V019, V030, V045
- **Concepts.** Rebase does not move commits; it writes new ones whose parent, committer and usually tree differ, then points the branch at the last copy. The originals are unreachable from the branch and remain in the reflog. The patch ID of each copy equals that of its original, which is how Git recognizes "the same change".
- **Commands.** `git rebase`; `git switch --detach`; `git cherry-pick`; `git switch -C`; `git patch-id`
- **Demonstration.** Replay `labs/ch09/rebase-basic.sh` (snippets `before`, `rebase`, `after`, `objects`, `patch-id`, `reflog`, `nothing-to-do`) and `labs/ch09/rebase-by-hand.sh` (snippets `detach-and-replay`, `before-the-branch-moves`, `move-the-branch`, `compare-with-rebase`). In `objects`, put an original and its copy side by side and mark the fields that differ.
- **Diagrams.** Redraw the diagram of section 9.2.
- **Practical exercise.** Exercise 9.1 (Level 1, "a plain rebase, before and after") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Challenge.** Exercise 9.4 (Level 2, "the old commits and the new ones") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q143: "Why does a rebase change commit hashes: why does every rebased commit have a new ID even when its diff is identical? Which fields of the commit object changed, and which did not?"
- **Homework.** Read sections 9.1 to 9.3.
- **Expected outcome.** The learner says "rebase copies" and can show the originals after any rebase.

### V053: What rebase does internally: the state directory, HEAD, and the special refs

- **Title.** What rebase does internally: the state directory, HEAD, and the special refs
- **Learning objectives.** After this video the learner can:
  - Say where HEAD, the branch ref, `ORIG_HEAD` and `REBASE_HEAD` point while a rebase is stopped
  - Read the files of `.git/rebase-merge` to learn what is done and what remains
  - Explain when the branch ref moves and what that means for commits made during the stop
  - Contrast the merge backend with the apply backend
- **Prerequisites.** V024, V052
- **Concepts.** During a rebase HEAD is detached and walks the new commits; the branch ref moves only at the end. The state directory holds the todo list, the done list and the original head. `--abort` uses it to return. The apply backend works from patches and behaves differently on conflict.
- **Commands.** `git rebase`; `git rebase --abort`; `git rebase --apply`; `git status`; `git reflog show`; `git rev-parse`
- **Demonstration.** Replay `labs/ch09/rebase-internals.sh` (snippets `before`, `stop`, `head`, `state-dir`, `state-files`, `special-refs`, `status`, `abort`) and `labs/ch09/apply-backend.sh` (snippets `apply-stops`, `state`, `abort`). At `stop`, ask where the branch points; most viewers will be wrong.
- **Diagrams.** Redraw the two diagrams of section 9.4 (the diagram of section 9.4): the graph during the stop, with HEAD detached and the branch label still on the old tip.
- **Practical exercise.** Exercise 9.3 (Level 1, "a conflict, a look around, and the way back") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Challenge.** Exercise 9.7 (Level 3, "a rebase that stopped at an `exec` line") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q147: "A rebase is stopped at a conflict. Where do the branch ref, HEAD, `ORIG_HEAD` and `REBASE_HEAD` point? What does that imply for `--abort`?"
- **Homework.** Read section 9.4.
- **Expected outcome.** The learner can look at a stopped rebase and say what state every ref is in.

### V054: Choosing what moves and where it lands: upstream, --onto, --keep-base, --root

- **Title.** Choosing what moves and where it lands: upstream, --onto, --keep-base, --root
- **Learning objectives.** After this video the learner can:
  - State which commits `git rebase <upstream>` selects and where it puts them
  - Use `git rebase --onto` with three arguments to cut a range and to move a branch sideways
  - Explain why a plain rebase of a stacked branch replays commits that are not yours
  - Use `--keep-base` to rewrite a branch without moving it, and `--root` to rewrite from the first commit
- **Prerequisites.** V053
- **Concepts.** Two questions in every rebase: which commits (those reachable from the branch and not from the upstream) and onto what. `--onto` separates the two. After the branch below was squash-merged or rebased, the upstream argument must name the old base. `--keep-base` keeps the merge base as the new base.
- **Commands.** `git rebase`; `git rebase --onto`; `git rebase --autosquash --keep-base`; `git rebase -i --root`; `git merge-base`; `git rebase --abort`
- **Demonstration.** Replay `labs/ch09/rebase-forms.sh` (snippets `two-arguments`, `no-upstream`), `labs/ch09/onto-cut.sh` (snippets `before`, `onto`, `check`), `labs/ch09/onto-sideways.sh` (snippets `before`, `onto`, `check`), `labs/ch09/onto-stacked.sh` (snippets `before`, `which-commits`, `plain-rebase-conflicts`, `onto`), `labs/ch09/keep-base.sh` (snippets `before`, `keep-base`, `after`) and `labs/ch09/rebase-root.sh` (snippets `before`, `root`, `after`).
- **Diagrams.** Redraw the diagram of section 9.5; show the root-cause box of section 9.5. Label the three arguments of `--onto` on the graph: new base, old base, tip.
- **Practical exercise.** Lab 9.2 ("Transplant a branch with `--onto`") in [`lab-manual/m09-rebase.md`](../lab-manual/m09-rebase.md)
- **Challenge.** Exercise 9.9 (Level 4, "the morning rebase that replays somebody else's commits") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q154: "`git rebase main` on a feature branch conflicts in a file the branch never touched. Give two different root causes and the command that fixes each."
- **Homework.** Read section 9.5. Do Exercise 9.5 (Level 2, "a commit that `main` already has") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner writes the `--onto` form for any transplant from a drawn graph.

### V055: Interactive rebase: reword, edit, squash, fixup, drop, reorder, exec, break

- **Title.** Interactive rebase: reword, edit, squash, fixup, drop, reorder, exec, break
- **Learning objectives.** After this video the learner can:
  - Read and edit a todo list and predict the resulting history
  - Reword, squash, fix up, drop and reorder commits
  - Stop at a commit with `edit` and split it into two
  - Run a test after every commit with `exec` and recover when it fails
  - Explain why `ORIG_HEAD` may not point at the pre-rebase tip afterwards
- **Prerequisites.** V054
- **Concepts.** The todo list is a program that the rebase runs top to bottom. `squash` combines messages, `fixup` discards the later one. `edit` stops after applying a commit; splitting is a reset followed by several commits. `exec` runs a command and stops on a non-zero status. `break` stops without a commit. Commands run during a stop can overwrite `ORIG_HEAD`.
- **Commands.** `git rebase -i`; `git rebase --continue`; `git rebase --edit-todo`; `git rebase -i --exec`; `git rebase --exec`; `git reset`; `git commit --amend`; `git reflog show`
- **Demonstration.** Replay `labs/ch09/interactive-basics.sh` (snippets `messy`, `list`, `reword`, `fixup`, `reorder`, `squash`, `drop`, `result`), `labs/ch09/squash-message.sh` (snippets `squash-buffer`, `result`), `labs/ch09/interactive-edit.sh` (snippets `before`, `edit-stops`, `split`, `continue`, `orig-head-moved`), `labs/ch09/interactive-exec.sh` (snippets `setup`, `exec-stops`, `where`, `fix-and-continue`), `labs/ch09/interactive-exec-lines.sh` (snippets `exec-lines`, `where`, `abort`) and `labs/ch09/interactive-break.sh` (snippets `break`, `look-around`, `edit-list`, `continue`). Say once that the replays edit the todo list with a scripted editor, so that the edit itself is visible in the transcript.
- **Diagrams.** New: a todo list on the left and the resulting graph on the right, redrawn for each operation.
- **Practical exercise.** Lab 9.1 ("Clean up a messy branch") in [`lab-manual/m09-rebase.md`](../lab-manual/m09-rebase.md)
- **Challenge.** Exercise 9.7 (Level 3, "a rebase that stopped at an `exec` line") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q403: "During a rebase, when does the branch ref move, and what follows from that for commits made while the rebase is stopped?"
- **Homework.** Read section 9.6. Repeat Lab 9.1 ("Clean up a messy branch") in [`lab-manual/m09-rebase.md`](../lab-manual/m09-rebase.md) until the result takes one pass.
- **Expected outcome.** The learner cleans a branch before review and can stop, inspect and continue a rebase at will.

### V056: Fixup commits, --autosquash, --autostash, stacked branches with --update-refs, and --rebase-merges

- **Title.** Fixup commits, --autosquash, --autostash, stacked branches with --update-refs, and --rebase-merges
- **Learning objectives.** After this video the learner can:
  - Record a correction as a fixup commit and fold it in with `--autosquash`
  - Explain where local changes are while a rebase with `--autostash` is stopped
  - Rebase a stack of branches in one operation with `--update-refs` and publish it
  - Keep merge commits through a rebase with `--rebase-merges` and say what replaced `--preserve-merges`
- **Prerequisites.** V055
- **Concepts.** `git commit --fixup` writes a commit whose title marks its target; `--autosquash` reorders the todo list. Autostash parks local changes in a stash entry and reapplies them at the end; after `--quit` they are still in the stash. `--update-refs` moves every branch that points into the rebased range. A plain rebase flattens merges; `--rebase-merges` recreates them; `--preserve-merges` was removed.
- **Commands.** `git commit --fixup`; `git commit --squash`; `git rebase -i --autosquash`; `git rebase --autosquash`; `git rebase --autostash`; `git stash list`; `git rebase --update-refs`; `git rebase -i --rebase-merges`; `rebase.autoSquash`; `rebase.autoStash`; `rebase.updateRefs`
- **Demonstration.** Replay `labs/ch09/autosquash.sh` (snippets `before`, `fixup-commit`, `squash-commit`, `amend-commit`, `log`, `autosquash`, `after`, `non-interactive`, `config`), `labs/ch09/autosquash-config.sh` (snippets `config-and-plain-rebase`, `interactive-honours-it`), `labs/ch09/autostash.sh` (snippets `dirty`, `autostash`, `conflict-setup`, `conflict-state`, `config`), `labs/ch09/autostash-stopped.sh` (snippets `stopped`, `where-is-it`, `abort`, `quit`), `labs/ch09/update-refs.sh` (snippets `before`, `without`, `undo`, `with`, `after`, `backup-trap`, `config`), `labs/ch09/update-refs-push.sh` (snippets `before`, `rebase`, `push-the-stack`, `after`) and `labs/ch09/rebase-merges.sh` (snippets `before`, `flattened`, `undo`, `rebase-merges`, `after`, `preserve-merges`).
- **Diagrams.** Redraw the diagram of section 9.9: three stacked branches before and after, with and without `--update-refs`.
- **Practical exercise.** Lab 9.3 ("Autosquash fixups") in [`lab-manual/m09-rebase.md`](../lab-manual/m09-rebase.md)
- **Challenge.** Lab 9.7 ("`--update-refs` on stacked branches") in [`lab-manual/m09-rebase.md`](../lab-manual/m09-rebase.md)
- **Interview question.** Q158: "What do `--update-refs` and `--rebase-merges` each add to a plain rebase, and what does each still leave for you to do?"
- **Homework.** Read sections 9.7 to 9.10. Do Exercise 9.2 (Level 1, "fold a fix into the commit it belongs to") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md) and Exercise 9.6 (Level 2, "a merge inside the branch") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner maintains a stack of dependent branches without rebasing each one by hand.

### V057: Conflicts during a rebase: who is "ours", the ways out, and commits that are already upstream

- **Title.** Conflicts during a rebase: who is "ours", the ways out, and commits that are already upstream
- **Learning objectives.** After this video the learner can:
  - Name the base, ours and theirs of each step of a rebase and explain why the sides appear swapped
  - Inspect the commit being applied and resolve its conflict
  - Describe two ways a rebase conflict loses work without any error
  - Choose between `--continue`, `--skip`, `--abort` and `--quit`
  - Predict which commits a rebase drops because the upstream already has the change
- **Prerequisites.** V033, V056
- **Concepts.** Each step is a cherry-pick: ours is the new base plus the copies so far, theirs is your commit. `--ours` therefore takes the upstream's version. Amending during a stop folds your resolution into the previous commit. Commits whose patch ID is already upstream are dropped; a squash-merged branch is not recognized and conflicts.
- **Commands.** `git status`; `git ls-files -u`; `git restore --ours`; `git restore --theirs`; `git rebase --continue`; `git rebase --skip`; `git rebase --quit`; `git rebase -X`; `git cherry -v`; `git log --oneline --left-right --cherry-mark`; `git rebase --reapply-cherry-picks`
- **Demonstration.** Replay `labs/ch09/rebase-conflict.sh` (snippets `markers`, `stages`, `who-is-who`, `as-a-merge`, `resolve`, `continue`, `strategy-option`), `labs/ch09/conflict-inspect.sh` (snippets `show-current-patch`, `bookkeeping`, `continue-too-early`, `second-rebase`, `abort`), `labs/ch09/conflict-traps.sh` (snippets `ours-trap`, `ours-result`, `amend-trap`, `amend-result`), `labs/ch09/conflict-exits.sh` (snippets `skip`, `quit`, `after-quit`), `labs/ch09/upstream-picked.sh` (snippets `before`, `predict`, `rebase`, `reapply`) and `labs/ch09/upstream-squashed.sh` (snippets `before`, `rebase`, `interactive-stops`).
- **Diagrams.** Show the root-cause box of section 9.11. New: the same conflict drawn twice, as a merge and as a rebase step, with "ours" and "theirs" written on the commits.
- **Practical exercise.** Lab 9.4 ("A conflict in a rebase, and who is "ours"") in [`lab-manual/m09-rebase.md`](../lab-manual/m09-rebase.md)
- **Challenge.** Exercise 9.8 (Level 3, "the same conflict at every commit") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q148: "During a rebase, what do `--ours` and `--theirs` refer to, and why? Give one concrete way this loses work without any error message."
- **Homework.** Read sections 9.11 and 9.12.
- **Expected outcome.** The learner never takes "ours" in a rebase by reflex and predicts which commits will vanish as already applied.

### V058: git pull --rebase, and reviewing a rebase with git range-diff

- **Title.** git pull --rebase, and reviewing a rebase with git range-diff
- **Learning objectives.** After this video the learner can:
  - Explain `git pull --rebase` as fetch followed by a rebase onto the upstream
  - Compare the old and the new version of a branch with `git range-diff`
  - Read the `=`, `!`, `<` and `>` markers
  - Show a reviewer what changed in a force-pushed branch
- **Prerequisites.** V040, V057
- **Concepts.** Pull with rebase keeps local commits on top and writes no merge commit. `git range-diff` pairs commits of two ranges by similarity and shows a diff of diffs: the only honest answer to "what changed since I approved". The creation factor decides how readily commits are paired.
- **Commands.** `git pull --rebase`; `pull.rebase`; `git range-diff`; `git range-diff --creation-factor=90`; `git fetch`
- **Demonstration.** Replay `labs/ch09/pull-rebase.sh` (snippets `diverged`, `pull-refuses`, `pull-rebase`, `push`, `config`), `labs/ch09/range-diff.sh` (snippets `rebase`, `range-diff`, `other-spellings`, `tree-diff`), `labs/ch09/range-diff-review.sh` (snippets `fetch`, `range-diff`) and `labs/ch09/range-diff-context.sh` (snippets `unpaired`, `paired`).
- **Diagrams.** New: two columns of commits, old range and new range, with pairing lines and one marker per pair.
- **Practical exercise.** Exercise 9.4 (Level 2, "the old commits and the new ones") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Challenge.** Exercise 9.10 (Level 5, ""rebased onto main, no functional change"") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q149: "The reviewer approved three commits; after your rebase there are still three with the same titles. How do you show what changed, and how does the reviewer do it without access to your clone?"
- **Homework.** Read sections 9.13 and 9.14.
- **Expected outcome.** The learner reviews a rebased branch from evidence and no longer trusts "rebased, no functional change".

### V059: Rebasing a branch that other people use, and recovering from a bad rebase

- **Title.** Rebasing a branch that other people use, and recovering from a bad rebase
- **Learning objectives.** After this video the learner can:
  - Explain how a teammate ends up with every commit twice after a shared branch was rebased
  - Repair the teammate's branch without losing their own commit
  - Recover the pre-rebase state through `ORIG_HEAD` and through the reflog, and say when the first fails
  - State the rule about published history as a consequence, not as a slogan
- **Prerequisites.** V058
- **Concepts.** The teammate's branch still contains the originals; merging the rewritten branch joins two copies of each change. The repair replays only the teammate's own commits onto the new tip. `ORIG_HEAD` is overwritten by later commands; the branch reflog is not. A backup branch before a risky rebase costs nothing.
- **Commands.** `git rebase`; `git push --force-with-lease`; `git fetch`; `git merge`; `git rebase --onto`; `git reflog show`; `git reset --hard`; `git branch`
- **Demonstration.** Replay `labs/ch09/shared-rebase.sh` (snippets `you-rebase`, `you-push`, `asha-before`, `asha-fetch`, `asha-merges`, `duplicates`, `repair`) and `labs/ch09/recover.sh` (snippets `bad-rebase`, `orig-head`, `orig-head-overwritten`, `reflog`, `rescue`, `head-reflog`).
- **Diagrams.** Redraw the diagram of section 9.15: your clone, the server and the teammate's clone before and after.
- **Practical exercise.** Lab 9.5 ("Break a branch on purpose and recover it") in [`lab-manual/m09-rebase.md`](../lab-manual/m09-rebase.md)
- **Challenge.** Lab 9.6 ("Rebase a shared branch and watch a teammate's history duplicate") in [`lab-manual/m09-rebase.md`](../lab-manual/m09-rebase.md)
- **Interview question.** Q155: "You force-pushed a rebased branch. A teammate now has every commit twice. Explain how that happened, how they repair it, and what you would have done differently."
- **Homework.** Read sections 9.15 and 9.16.
- **Expected outcome.** The learner can undo any rebase and can repair a colleague's clone after someone else's.

### V060: Publishing a rebased branch, rebase or merge, and the rebase configuration

- **Title.** Publishing a rebased branch, rebase or merge, and the rebase configuration
- **Learning objectives.** After this video the learner can:
  - Publish a rebased branch with a lease and `--force-if-includes` and explain each guard
  - Describe the damage a bare `--force` does and how the teammate recovers
  - Argue for a merge and for a rebase of the same integration
  - Justify each rebase setting you enable
  - Say what `git replay` and `git history` are, as pointers to Part 11
- **Prerequisites.** V042, V059
- **Concepts.** After a rebase the server's branch is not an ancestor, so a plain push is rejected: that rejection is the safety check. The lease, the background fetch that defeats it, the explicit form. Merge and rebase reach the same content with different histories: what each costs for bisect, for review and for the people who share the branch.
- **Commands.** `git push`; `git push --force-with-lease`; `git push --force-with-lease --force-if-includes`; `git push --force-with-lease --dry-run`; `git merge-base --fork-point`; `git pull --rebase`; `push.useForceIfIncludes`; `rebase.autoSquash`
- **Demonstration.** Replay `labs/ch09/force-push.sh` (snippets `rebase`, `plain-push`, `lease`, `background-fetch`, `if-includes`, `integrate`, `result`), `labs/ch09/force-lease-explicit.sh` (snippets `record-and-rebase`, `fetch-then-push`, `bare-lease-would-pass`), `labs/ch09/force-damage.sh` (snippets `server-before`, `force`, `server-after`, `asha-pulls`, `why`, `asha-recovers`) and `labs/ch09/merge-vs-rebase.sh` (snippets `merge`, `rebase`, `same-content`, `snapshots`, `first-parent`, `who-contains-the-originals`). Close with `labs/ch09/replay-pointer.sh` (snippets `replay`) as the pointer of section 9.20.
- **Diagrams.** Show the root-cause box of section 9.17. New: one diverged pair of branches integrated by merge and by rebase, drawn one above the other with the same final tree ID.
- **Practical exercise.** Exercise 9.9 (Level 4, "the morning rebase that replays somebody else's commits") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Challenge.** Incident 5, [`incidents/05-rebased-shared-branch`](../incidents/05-rebased-shared-branch/SYMPTOMS.md)
- **Interview question.** Q156: "Compare `--force`, `--force-with-lease`, and `--force-with-lease --force-if-includes`. Describe a sequence of events in which the second overwrites a colleague's commit and the third refuses."
- **Homework.** Read sections 9.17 to 9.23 and do the Practice section 9.25.
- **Expected outcome.** The learner has a defensible personal rule for rebasing and force-pushing and can state it to a team.

### V061: What cherry-pick does: a three-way merge that makes a new commit

- **Title.** What cherry-pick does: a three-way merge that makes a new commit
- **Learning objectives.** After this video the learner can:
  - Name the base, ours and theirs of a cherry-pick
  - Explain why the copy has a new ID and which fields it shares with the original
  - Use `-x`, `-e`, `-n` and, for a merge commit, `-m`
  - Pick several commits and a range and state the order in which they are applied
  - Explain why "cherry-pick applies a patch" is imprecise
- **Prerequisites.** V031, V052
- **Concepts.** Cherry-pick merges with the picked commit's parent as base, HEAD as ours and the picked commit as theirs. The result is a new commit with the original's author and message and a new committer, parent and tree. `-x` records the original ID in the message. `-n` stages without committing and loses the link to the original.
- **Commands.** `git cherry-pick`; `git cherry-pick -e -x`; `git cherry-pick -n`; `git cherry-pick -m`; `git format-patch -1 --stdout`; `git merge-tree --write-tree`
- **Demonstration.** Replay `labs/ch10/pick-three-way.sh` (snippets `before`, `the-change`, `as-a-patch`, `predict`, `pick`, `objects`, `after`), `labs/ch10/pick-dirty.sh` (snippets `unrelated-edit`, `edit-in-the-way`, `staged-change`), `labs/ch10/pick-options.sh` (snippets `edit`, `no-commit`, `no-commit-author`) and `labs/ch10/pick-merge.sh` (snippets `before`, `refused`, `mainline`).
- **Diagrams.** Redraw the diagram of section 10.2.
- **Practical exercise.** Exercise 10.1 (Level 1, "one commit, copied to another branch") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Challenge.** Exercise 10.8 (Level 3, "a clean pick that does not work") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q144: "Why does cherry-pick create a new commit?"
- **Homework.** Read sections 10.1 to 10.5. Do Exercise 10.3 (Level 1, "two commits picked as one") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md) and Exercise 10.5 (Level 2, "which commits does a range pick?") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner predicts the result of a pick from three trees and records provenance with `-x`.

### V062: CHERRY_PICK_HEAD, the sequencer, conflicts, and picks that are already there

- **Title.** CHERRY_PICK_HEAD, the sequencer, conflicts, and picks that are already there
- **Learning objectives.** After this video the learner can:
  - Read the state of a stopped cherry-pick from `git status` and `.git`
  - Choose between `--continue`, `--skip`, `--abort` and `--quit` and say where the branch is after each
  - Explain where stage 1 of a cherry-pick conflict comes from
  - Handle a pick that became empty with `--empty`
  - Compare a stopped range pick with a stopped rebase
- **Prerequisites.** V033, V061
- **Concepts.** `CHERRY_PICK_HEAD` names the commit being applied; the sequencer directory holds the rest of a range. Unlike a rebase, HEAD stays on the branch and the commits picked so far are already on it. Stage 1 is the picked commit's parent, which can show lines your branch never had. A pick whose change is already present becomes empty.
- **Commands.** `git cherry-pick --continue`; `git cherry-pick --skip`; `git cherry-pick --abort`; `git cherry-pick --quit`; `git status`; `git ls-files -u`; `git cherry-pick --empty=drop`; `git cherry-pick --empty=keep`
- **Demonstration.** Replay `labs/ch10/pick-sequence.sh` (snippets `before`, `range-stops`, `state`, `status`, `abort`, `skip`, `quit`, `continue`), `labs/ch10/pick-conflict.sh` (snippets `conflict`, `markers`, `stages`, `where-stage-1-comes-from`, `resolve`, `result`), `labs/ch10/pick-finish.sh` (snippets `prepared-message`, `continue`, `commit-no-edit`, `commit-m`) and `labs/ch10/pick-empty.sh` (snippets `stop`, `skip`, `drop`, `keep`, `old-name`).
- **Diagrams.** New: the graph during a stopped range pick, with the branch label already advanced over the finished picks, beside the graph of a stopped rebase from V053.
- **Practical exercise.** Lab 10.2 ("A cherry-pick conflict") in [`lab-manual/m10-cherry-pick-ranges.md`](../lab-manual/m10-cherry-pick-ranges.md)
- **Challenge.** Exercise 10.9 (Level 4, "a backport that stopped at its second commit") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q153: "Compare the state after a stopped cherry-pick of a range with the state after a stopped rebase. Where is HEAD, and what has happened to the branch?"
- **Homework.** Read sections 10.6 to 10.8. Do Exercise 10.7 (Level 3, ""The previous cherry-pick is now empty"") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner can take over a half-finished backport and bring it to a known end.

### V063: The backport workflow, duplicate commits, and revert as the inverse

- **Title.** The backport workflow, duplicate commits, and revert as the inverse
- **Learning objectives.** After this video the learner can:
  - Backport a fix to a release branch and leave an audit trail
  - Establish in three ways whether a release branch contains a fix
  - Find duplicate commits between two branches with `git cherry` and `--cherry-mark`
  - Explain what happens to duplicates when the two branches are later merged
  - Relate revert to cherry-pick as the same operation with base and theirs exchanged
- **Prerequisites.** V048, V062
- **Concepts.** A backport is a cherry-pick onto a release branch, with `-x`. Ancestry does not know about copies: `--contains` on the original says no. Patch IDs pair unchanged copies; adapted copies need the recorded line. Merging branches that exchanged picks puts each change in history twice.
- **Commands.** `git cherry-pick -x`; `git branch --contains`; `git log --all --oneline --grep`; `git cherry -v`; `git log --oneline --left-right --cherry-mark`; `git log --oneline --left-right --cherry-pick`; `git revert`
- **Demonstration.** Replay `labs/ch10/backport.sh` (snippets `pick-x`, `audit-by-id`, `audit-by-trailer`, `audit-by-patch`), `labs/ch10/duplicates.sh` (snippets `graph`, `cherry`, `cherry-mark`, `cherry-pick`, `patch-id`, `merge`, `twice-in-history`) and `labs/ch10/revert-inverse.sh` (snippets `before`, `predict`, `revert`, `after`).
- **Diagrams.** New: `main` and a release branch with one fix on each, joined by a dashed line labelled "same patch ID, no ancestry".
- **Practical exercise.** Lab 10.1 ("Backport a fix with `-x`") in [`lab-manual/m10-cherry-pick-ranges.md`](../lab-manual/m10-cherry-pick-ranges.md)
- **Challenge.** Exercise 10.10 (Level 5, ""the fix is in the release" and "the fix was never backported"") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q159: "A fix was backported with `-x`. Give three ways to establish that the release branch contains it, and say which of them can give a wrong answer and why."
- **Homework.** Read sections 10.9 to 10.14 and do the Practice section 10.16, including Lab 10.3 ("Detect duplicates with `git cherry`") in [`lab-manual/m10-cherry-pick-ranges.md`](../lab-manual/m10-cherry-pick-ranges.md). Do Exercise 10.6 (Level 2, "backport, then merge the release back") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner answers "is the fix in the release" with evidence that survives adapted backports.

### V064: Naming commits and sets of commits: revisions, A..B and A...B for git log and for git diff

- **Title.** Naming commits and sets of commits: revisions, A..B and A...B for git log and for git diff
- **Learning objectives.** After this video the learner can:
  - Name a commit by ancestry, by reflog entry, by upstream, by message search and by path
  - State what `A..B` and `A...B` select in `git log`
  - State what `A..B` and `A...B` compare in `git diff`, and why the dots mean something else there
  - Choose the diff form that matches what a pull request shows
  - Predict log and diff output from a drawn graph
- **Prerequisites.** V025, V063
- **Concepts.** Revision syntax: `~`, `^`, `@{n}`, `@{upstream}`, `:/text`, `rev:path`, `^{}`. In `git log`, two dots mean "reachable from B and not from A" and three dots mean the symmetric difference. In `git diff`, two dots compare the two endpoints and three dots compare the merge base with B. A pull request shows the three-dot diff.
- **Commands.** `git rev-parse`; `git log --oneline`; `git log --oneline --left-right`; `git diff --stat`; `git merge-base`; `git rev-list --count`; `git merge-base --is-ancestor`
- **Demonstration.** Replay `labs/ch14a/revisions.sh` (snippets `ancestors`, `merge-parents`, `reflog`, `upstream`, `search`, `peel`, `paths`, `not-a-commit`), `labs/ch14a/ranges.sh` (snippets `two-dots`, `other-way`, `three-dots`, `several`, `parents`, `one-commit-diff`, `empty-range`) and `labs/ch14a/diff-endpoints.sh` (snippets `graph`, `two-endpoints`, `three-dots`, `config`, `readme`, `other-direction`, `trees-and-blobs`). For every range, shade the selected commits on the graph before showing the output.
- **Diagrams.** Redraw the diagram of section 14A.2 and the diagram of section 14A.8; show the root-cause box of section 14A.2.
- **Practical exercise.** Lab 10.4 ("Predict two-dot and three-dot output for `git log` and for `git diff`") in [`lab-manual/m10-range-notation.md`](../lab-manual/m10-range-notation.md)
- **Challenge.** Exercise 10.4 (Level 2, "ranges on a history with a merge") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q394: "What is the difference between `..` and `...`, in `git log` and in `git diff`?"
- **Homework.** Read sections 14A.1, 14A.2, 14A.7 and 14A.8. Do Exercise 10.2 (Level 1, "names for commits") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md).
- **Expected outcome.** The learner reads and writes range expressions without trial and error and explains the pull request diff.

### V065: Gate briefing: Merge and rebase

- **Title.** Gate briefing: Merge and rebase
- **Learning objectives.** After this video the learner can:
  - State what Gate 3 covers and its threshold of 90
  - Prepare the prediction part by naming base, ours and theirs for merge, rebase, cherry-pick and revert
  - Run the hands-on part by first reading which operation is in progress
  - Use the undo decision tree under time pressure
- **Prerequisites.** V051, V060, V064
- **Concepts.** Gate 3 covers the three-way merge, conflicts and stages, undo choices, rebase, cherry-pick and range notation. One table carries most of the gate: for each of merge, rebase step, cherry-pick and revert, which commit is the base, which is ours, which is theirs. The hands-on repository is in the middle of something; a correct end state reached by a destructive path loses the safety points.
- **Commands.** `git status`; `git ls-files -u`; `git merge-base`; `git reflog`
- **Demonstration.** Replay `labs/ch09/rebase-conflict.sh` (snippets `who-is-who`, `as-a-merge`) and `labs/ch10/pick-conflict.sh` (snippets `where-stage-1-comes-from`) as the warm-up for the base, ours, theirs table. Show the gate rules from [`assessments/README.md`](../assessments/README.md). Do not open the gate file on screen.
- **Diagrams.** New: a four-row table (merge, rebase step, cherry-pick, revert) with the columns base, ours, theirs, filled in live.
- **Practical exercise.** Redo Exercise 6.10 (Level 5, "the weekly sync that conflicts more every week") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md), Exercise 8.10 (Level 5, "a feature that was merged twice and is half missing") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md), Exercise 9.10 (Level 5, ""rebased onto main, no functional change"") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md) and Exercise 10.10 (Level 5, ""the fix is in the release" and "the fix was never backported"") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md), the Level 5 exercises of the block.
- **Challenge.** Take Gate 3: [`assessments/gate-3-merge-and-rebase.md`](../assessments/gate-3-merge-and-rebase.md).
- **Interview question.** Q100: "`git log main..feature` and `git diff main..feature`: how do the two dots differ in meaning? Which one do you want for a review?"
- **Homework.** Before the gate: answer the "Interview questions" sections of Chapters 8, 9, 10 and 11 aloud.
- **Expected outcome.** The learner sits Gate 3 able to explain every integration and every undo from the graph.

## Part 3: Investigation, recovery and power tools

Roadmap Level 3 (Modules 11 to 15), then the Recovery gate. 33 videos: history as evidence, every standard disaster and its recovery, tags and versions, worktrees, stash internals, rerere, attributes, hooks, submodules, subtrees and Git LFS.

### V066: Reading a diff: summaries, filters, computed renames, whitespace and algorithms

- **Title.** Reading a diff: summaries, filters, computed renames, whitespace and algorithms
- **Learning objectives.** After this video the learner can:
  - Summarize a diff by files, by status and by counts, and filter it by kind of change
  - Explain a rename score and change the detection threshold
  - Separate real changes from whitespace and reformatting noise
  - Compare two diff algorithms on the same change
  - Find whitespace errors and leftover conflict markers before committing
- **Prerequisites.** V013, V064
- **Concepts.** `--stat`, `--name-only`, `--name-status` and `--diff-filter` answer "what changed" before "how". Renames and copies are computed by `-M` and `-C` from similarity; a rewrite defeats detection. `-w` and `--word-diff` read through reformatting. The same change can be displayed differently by `myers` and `histogram`; the content is the same. `git diff --check`.
- **Commands.** `git diff --stat`; `git diff --name-only`; `git diff --name-status`; `git diff --name-status --diff-filter=D`; `git diff --name-status -M`; `git diff --name-status --no-renames`; `git diff --word-diff`; `git diff --diff-algorithm=histogram`; `git diff --check`; `git diff --cached --check`
- **Demonstration.** Replay `labs/ch14a/diff-summaries.sh` (snippets `stat`, `names`, `numstat`, `filter`, `pathspec`), `labs/ch14a/diff-renames.sh` (snippets `default`, `no-renames`, `threshold`, `patch`, `stat`, `copies`, `rewrite`), `labs/ch14a/diff-words-whitespace.sh` (snippets `reformat-stat`, `reformat-w`, `line-diff`, `word-diff`), `labs/ch14a/diff-algorithms.sh` (snippets `myers`, `histogram`, `counts`, `config`) and `labs/ch14a/diff-check.sh` (snippets `check`, `staged`, `range`).
- **Diagrams.** New: one moved-and-edited file shown three ways: as delete plus add, as a rename with its score, and as a word diff.
- **Practical exercise.** Exercise 11.1 (Level 1, "Four questions for the log") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 11.7 (Level 3, ""I only moved it"") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q399: "Git stores no renames. Name three commands whose output depends on rename detection, and describe a commit that defeats it."
- **Homework.** Read sections 14A.3 to 14A.6.
- **Expected outcome.** The learner reads a large diff from the outside in and is not misled by reformatting or by a rename score.

### V067: git log is a graph query: selection, filters, graph shape and output formats

- **Title.** git log is a graph query: selection, filters, graph shape and output formats
- **Learning objectives.** After this video the learner can:
  - Describe a `git log` invocation as "start points, exclusions, filters, format"
  - Filter history by author, message, date and path and say which date is compared
  - Show integrations only with `--first-parent` and merges only with `--merges`
  - Produce a custom one-line format and a per-author summary
  - Explain why a date filter can omit commits from the named day
- **Prerequisites.** V020, V066
- **Concepts.** `git log` walks the graph from the given tips and prints what passes the filters. Path filters simplify history. `--since` and `--until` compare committer dates with a time of day. `--first-parent` follows the mainline. Pretty formats and trailers; `git shortlog` groups by author and must be given a revision in scripts.
- **Commands.** `git log --graph --oneline`; `git log --oneline --first-parent`; `git log --oneline --merges`; `git log --oneline --author`; `git log --oneline --grep`; `git log --oneline --since`; `git log --oneline --`; `git log --format`; `git shortlog -sn`; `git shortlog --no-merges`
- **Demonstration.** Replay `labs/ch14a/history-tour.sh` (snippets `symptom`, `graph`, `who-when`), `labs/ch14a/log-graph.sh` (snippets `graph-range`, `first-parent`, `merges`, `decoration`), `labs/ch14a/log-filters.sh` (snippets `author`, `grep`, `dates`, `time-of-day`, `committer-date`, `paths`, `stat-patch`) and `labs/ch14a/log-formats.sh` (snippets `format`, `fuller`, `trailers`, `shortlog`, `shortlog-release`, `shortlog-stdin`). Stop at `time-of-day`: the snippet that explains missing commits.
- **Diagrams.** Show the root-cause box of section 14A.9. New: a graph with the walked commits shaded for three invocations.
- **Practical exercise.** Exercise 11.6 (Level 2, "Release notes from history") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 11.10 (Level 4, ""It is fixed in 2.3"") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q411: "`git log --since=2026-09-10` omitted commits from the morning of that day. Explain the cause and state how you would write the query in an incident report."
- **Homework.** Read sections 14A.9 and 14A.15.
- **Expected outcome.** The learner composes a log query for any "who, when, what" question and trusts its dates for the right reason.

### V068: Set questions, git grep, and the retirement of git whatchanged

- **Title.** Set questions, git grep, and the retirement of git whatchanged
- **Learning objectives.** After this video the learner can:
  - Show what each of two branches has that the other lacks, with copies paired
  - Find the merge that brought a commit into a branch with `--ancestry-path`
  - Search commits that only the reflog still reaches
  - Search tracked content now and in older revisions with `git grep`
  - Replace `git whatchanged` in an old script
- **Prerequisites.** V063, V067
- **Concepts.** `--left-right` with three dots marks the side of each commit; `--cherry-pick` and `--cherry-mark` use patch IDs. `--ancestry-path` restricts to the chain between two commits. `--reflog` and `-g` reach commits no branch names. `git grep` searches the index, a tree or many revisions, with function context. `git whatchanged` is deprecated and refuses to run without an explicit option.
- **Commands.** `git log --oneline --left-right`; `git log --oneline --left-right --cherry-pick`; `git log --oneline --ancestry-path`; `git log --oneline --merges --ancestry-path`; `git log --oneline -g`; `git grep -n`; `git grep -c`; `git grep -W`; `git grep -l`
- **Demonstration.** Replay `labs/ch14a/log-sets.sh` (snippets `left-right`, `plain-range`, `ancestry-path`, `which-merge`, `reflog`), `labs/ch14a/grep.sh` (snippets `basic`, `function`, `revision`, `boolean`, `untracked`, `many-revisions`) and `labs/ch14a/whatchanged.sh` (snippets `refuses`, `replacement`, `last-modified`).
- **Diagrams.** New: two diverged branches with `<` and `>` on the commits and `=` on a cherry-picked pair; then the ancestry path between a fix and `main` shaded.
- **Practical exercise.** Exercise 11.4 (Level 2, "Ranges on a diverged branch") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 11.8 (Level 3, ""Git lost my commit"") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q401: "You found the commit that introduced a bug. Which commands tell you which releases and which open branches contain it?"
- **Homework.** Read sections 14A.14, 14A.23 and 14A.24.
- **Expected outcome.** The learner answers "which releases and branches contain this commit, and how did it get there" from the graph.

### V069: The history of one file: --follow, the pickaxe, line history, and deleted files

- **Title.** The history of one file: --follow, the pickaxe, line history, and deleted files
- **Learning objectives.** After this video the learner can:
  - Follow one file across a rename and state the limits of `--follow`
  - Choose between `-S` and `-G` and construct a commit that only one of them reports
  - Trace the history of a function or a line range with `git log -L`
  - Find the commit that deleted a file and restore the file from its parent
  - Find a file that exists only on another branch
- **Prerequisites.** V067
- **Concepts.** `--follow` works for one path and uses rename detection. `-S` counts occurrences of a string and reports commits where the count changed; `-G` matches added or removed lines against a regular expression, so a move within a file shows under `-G` only. `-L` follows a range backwards through history. A deleted file is restored from the parent of the deleting commit.
- **Commands.** `git log --oneline --follow --`; `git log --oneline -S`; `git log --oneline -G`; `git log --oneline -L`; `git log --oneline -s -L`; `git log --diff-filter=D --name-status`; `git log --oneline --all --`; `git restore --source`
- **Demonstration.** Replay `labs/ch14a/log-follow.sh` (snippets `without`, `follow`, `names`, `old-names`, `one-path`), `labs/ch14a/log-pickaxe.sh` (snippets `S`, `G`, `why`, `reformat`, `lower`, `regex`, `with-patch`, `scope`), `labs/ch14a/log-line-history.sh` (snippets `function-commits`, `compare`, `one-line`, `function-patch`, `errors`) and `labs/ch14a/log-deleted.sh` (snippets `deletions`, `path-history`, `why`, `content`, `wrong-commit`, `restore`, `other-branch`).
- **Diagrams.** New: a table with one row per commit and two columns, "reported by -S" and "reported by -G", for add, remove, move and edit of the searched string.
- **Practical exercise.** Lab 11.2 ("Find when a string was removed, with `-S` and then with `-G`") in [`lab-manual/m11-history-forensics.md`](../lab-manual/m11-history-forensics.md)
- **Challenge.** Lab 11.7 ("Line history with `git log -L`") in [`lab-manual/m11-history-forensics.md`](../lab-manual/m11-history-forensics.md)
- **Interview question.** Q400: "Explain `-S` and `-G` to a colleague, with one commit that the first misses and the second reports, and one case where `-G` is noise."
- **Homework.** Read sections 14A.10 to 14A.13. Do Lab 11.1 ("Trace a line across a rename") in [`lab-manual/m11-history-forensics.md`](../lab-manual/m11-history-forensics.md) and Lab 11.3 ("Find a deleted file") in [`lab-manual/m11-history-forensics.md`](../lab-manual/m11-history-forensics.md); then Exercise 11.2 (Level 1, "The pickaxe, twice") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md) and Exercise 11.5 (Level 2, "A file that is gone") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md).
- **Expected outcome.** The learner finds when and why any line, string or file changed or disappeared.

### V070: git blame: what a row asserts, reformatting commits, moved code, and a method for finding the origin of a bug

- **Title.** git blame: what a row asserts, reformatting commits, moved code, and a method for finding the origin of a bug
- **Learning objectives.** After this video the learner can:
  - State precisely what one row of `git blame` asserts
  - Look through a reformatting commit with `-w`, `--ignore-rev` and an ignore-revs file
  - Follow moved and copied code with `-M` and `-C`
  - Explain what blame shows after a squash merge
  - Apply the seven-step method from symptom to blast radius
- **Prerequisites.** V069
- **Concepts.** A blame row names the last commit that changed the line as it stands, not the author of the logic. Whitespace-only and formatter commits hide the origin unless ignored. `-C` looks in other files. After a squash merge every line of the feature is attributed to the squash commit. The method: locate, look through the formatter, read the commit, confirm, test both sides, measure the blast radius.
- **Commands.** `git blame`; `git blame -s -L`; `git blame --date=short -w -L`; `git blame --date=short --ignore-rev`; `git blame -s --ignore-revs-file`; `git blame -s -M`; `git blame -s -C`; `git blame -s --first-parent -L`; `blame.ignoreRevsFile`
- **Demonstration.** Replay `labs/ch14a/blame-basics.sh` (snippets `file`, `lines`, `porcelain`, `older-revision`, `boundary`, `not-shown`), `labs/ch14a/blame-reformat.sh` (snippets `plain`, `w`, `ignore-rev`, `file`, `config`, `short-id`, `missing-file`, `optional`), `labs/ch14a/blame-moves.sh` (snippets `rename`, `moved-between-files`, `threshold`, `copy`, `squash`, `squash-who`, `move-within-file`, `first-parent`) and `labs/ch14a/find-origin.sh` (snippets `symptom`, `locate`, `through-the-formatter`, `read`, `confirm`, `test-both-sides`, `blast-radius`).
- **Diagrams.** Redraw the diagram of section 14A.16.
- **Practical exercise.** Lab 11.6 ("Blame through a reformatting commit with an ignore-revs file") in [`lab-manual/m11-history-forensics.md`](../lab-manual/m11-history-forensics.md)
- **Challenge.** Exercise 11.3 (Level 1, "Blame, and one step further back") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q395: "What exactly does a row of `git blame` assert? Give three situations in which the named author did not write the logic on that line."
- **Homework.** Read sections 14A.16 to 14A.19.
- **Expected outcome.** The learner uses blame as a pointer to a commit to read, never as a verdict on a person.

### V071: git bisect: binary search over commits

- **Title.** git bisect: binary search over commits
- **Learning objectives.** After this video the learner can:
  - Explain why a bisection over n commits needs about log2(n) tests and what it assumes
  - Run a manual bisection with a good and a bad commit
  - Skip a commit that cannot be tested and read what Git reports then
  - Read the bisect state from its refs and its log, and end the session cleanly
- **Prerequisites.** V024, V067
- **Concepts.** Bisect assumes one transition from good to bad along the tested range. Each step checks out a commit in detached HEAD. `skip` handles commits that do not build. The state lives in refs under `refs/bisect/` and in `.git`; `git bisect reset` returns to the starting branch.
- **Commands.** `git bisect start`; `git bisect bad`; `git bisect good`; `git bisect skip`; `git bisect log`; `git bisect reset`; `git rev-list --count`
- **Demonstration.** Replay `labs/ch14a/bisect-manual.sh` (snippets `start`, `status`, `untestable`, `bad`, `good`, `narrowing`, `found`, `state`, `log`, `reset`). Before `found`, ask how many more steps are needed.
- **Diagrams.** New: a row of commits with the tested ones numbered in the order bisect chose them and the range halving each time.
- **Practical exercise.** Lab 11.4 ("A manual bisect") in [`lab-manual/m11-history-forensics.md`](../lab-manual/m11-history-forensics.md)
- **Challenge.** Exercise 11.9 (Level 4, "The regression among commits that cannot be tested") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q409: "A regression appeared somewhere in 4,000 commits. How many tests does a bisection need, what does it assume about the history, and how do you check that assumption when the result looks wrong?"
- **Homework.** Read section 14A.20.
- **Expected outcome.** The learner finds a regression in a long range by search, not by reading.

### V072: git bisect run, the exit-code protocol, custom terms, replay, --first-parent, and the pitfalls

- **Title.** git bisect run, the exit-code protocol, custom terms, replay, --first-parent, and the pitfalls
- **Learning objectives.** After this video the learner can:
  - Write a test script whose exit status follows the bisect protocol
  - Automate a bisection with `git bisect run`
  - Use custom terms for a search that is not about good and bad
  - Save and replay a bisect log
  - Explain what it means when bisect names a merge commit and when `--first-parent` helps
- **Prerequisites.** V071
- **Concepts.** Exit status 0 is good, 125 is "cannot test", 1 to 127 except 125 is bad, anything above aborts. The script must live outside the tree being tested or be copied out first. A dirty tree and a wrong-way-round start are the common failures. `--first-parent` finds the integration that introduced the change.
- **Commands.** `git bisect run`; `git bisect start --term-old`; `git bisect terms`; `git bisect log`; `git bisect replay`; `git bisect start --first-parent`; `git bisect reset`
- **Demonstration.** Replay `labs/ch14a/bisect-run.sh` (snippets `script`, `run`, `log`, `one-liner`, `bad-exit-code`, `missing-script`, `dirty-tree`) and `labs/ch14a/bisect-terms.sh` (snippets `terms`, `run`, `save-log`, `replay`, `good-bad-mixed`, `first-parent`, `wrong-way-round`). In `script`, read the exit statuses aloud.
- **Diagrams.** New: a small table of exit statuses and their meaning to `git bisect run`.
- **Practical exercise.** Lab 11.5 ("An automated `git bisect run`") in [`lab-manual/m11-history-forensics.md`](../lab-manual/m11-history-forensics.md)
- **Challenge.** Exercise 11.11 (Level 5, "Retrieval quality dropped on Friday") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q410: "Bisect reports a merge commit as the first bad commit, and both parents are good. What does that tell you, and what do you look at next?"
- **Homework.** Read sections 14A.21, 14A.22 and 14A.25 to 14A.27. Do the Practice section 14A.29.
- **Expected outcome.** The learner hands a regression hunt to a script and can defend its result.

### V073: What Git keeps: four layers of protection, and the reflog

- **Title.** What Git keeps: four layers of protection, and the reflog
- **Learning objectives.** After this video the learner can:
  - Name the four layers that protect work and what each holds
  - Read a reflog entry: old ID, new ID, selector, action
  - Tell the HEAD reflog from a branch reflog and choose the right one for an incident
  - Use `@{n}` and time selectors, and explain why the reflog is local
  - Explain how an unreachable commit survives a maintenance run
- **Prerequisites.** V009, V047
- **Concepts.** Layers: refs, reflogs, unreachable objects not yet pruned, and other repositories. A reflog is a per-ref local log of every value the ref had. HEAD's reflog records every move, a branch reflog only that branch's. Reflogs are never pushed or cloned. Objects named by a reflog count as reachable for garbage collection.
- **Commands.** `git reflog`; `git reflog show`; `git log -g`; `git reflog --date=iso`; `git rev-parse`; `git diff --stat`; `git reflog list`
- **Demonstration.** Replay `labs/ch13/reflog-anatomy.sh` (snippets `make-history`, `head-reflog`, `branch-reflogs`, `selectors`, `time`, `log-g`, `on-disk`) and from `labs/ch13/gc-ladder.sh` the snippet `reflog-protects`.
- **Diagrams.** Redraw the diagram of section 13.2 and the diagram of section 13.3.
- **Practical exercise.** Exercise 12.1 (Level 1, "Read a reflog before you need it") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 12.4 (Level 2, "What the reflog will say") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q185: "How does the reflog help?"
- **Homework.** Read sections 13.1 to 13.3.
- **Expected outcome.** The learner reads the reflog as a timeline and knows it exists only where the work was done.

### V074: Retention and its exceptions, ORIG_HEAD, and git fsck as a search tool

- **Title.** Retention and its exceptions, ORIG_HEAD, and git fsck as a search tool
- **Learning objectives.** After this video the learner can:
  - State the default retention periods and which event starts each
  - Name the situations in which no reflog exists or it is deleted at once
  - Say which four commands write `ORIG_HEAD` and why it is one slot
  - Find lost commits with `git fsck` and explain `--no-reflogs`
  - Triage a list of dangling commits to the one that matters
- **Prerequisites.** V073
- **Concepts.** Defaults from the manual: 90 days for reflog entries, 30 days for entries of unreachable commits, two weeks of grace for unreachable objects; the lab configuration overrides the first two. Exceptions: a deleted branch loses its reflog, bare repositories keep none by default, a dropped stash. Expiry is demonstrated only with `--expire=now`. `ORIG_HEAD` is overwritten by the next command that uses it. `git fsck` treats reflog entries as roots unless told otherwise; dangling means unreachable and not referenced by another unreachable object.
- **Commands.** `git reflog expire --expire-unreachable=now`; `git reflog expire --dry-run --verbose --expire-unreachable=now`; `git reflog exists`; `git fsck`; `git fsck --unreachable`; `git fsck --no-reflogs`; `git fsck --no-reflogs --lost-found`; `git branch -D`; `git stash list`
- **Demonstration.** Replay `labs/ch13/reflog-retention.sh` (snippets `which-entries`, `after-expiry`, `delete-and-drop`, `stash`, `stash-after-expire`, `stash-rescue`, `bare`, `bare-with-reflog`), `labs/ch13/orig-head.sh` (snippets `not-written`, `reset`, `merge`, `rebase`, `stale`) and `labs/ch13/fsck-find.sh` (snippets `with-reflogs`, `no-reflogs`, `triage`, `lost-found`, `anchor`). Say once that the replays use explicit cut-offs because relative ones would depend on the recording date.
- **Diagrams.** Show the two root-cause boxes and the diagram of section 13.4 (the root-cause box of section 13.4, the diagram of section 13.4); redraw the diagram of section 13.6.
- **Practical exercise.** Exercise 12.3 (Level 1, "`git fsck` as a search tool") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 12.6 (Level 2, "Reset, commit, rescue, rebase") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q192: "State the default retention periods, say which event starts each period, and explain why "30 days plus two weeks" is not a guarantee."
- **Homework.** Read sections 13.4 to 13.6. Do Exercise 12.2 (Level 1, "A backup ref, and the one slot of `ORIG_HEAD`") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md).
- **Expected outcome.** The learner can say how long each safety net lasts and where it has holes.

### V075: The recovery method, and recovering commits I: a hard reset, a deleted branch, a deleted commit

- **Title.** The recovery method, and recovering commits I: a hard reset, a deleted branch, a deleted commit
- **Learning objectives.** After this video the learner can:
  - Ask the three questions that come before any recovery command
  - Recover the commits lost to `git reset --hard`
  - Recreate a deleted branch at its last tip, with and without its reflog
  - Bring back a commit dropped from history
  - Anchor every recovered commit with a ref before doing anything else
- **Prerequisites.** V074
- **Concepts.** The method: stop, do not run maintenance, find the ID, anchor it with a branch, then repair. A hard reset leaves the old tip in the branch reflog. A deleted branch has lost its own reflog; HEAD's reflog or `git fsck` still knows the tip. A dropped commit is a commit that no ref reaches.
- **Commands.** `git reflog show`; `git branch`; `git reset --hard`; `git fsck`; `git log --oneline --graph --all`; `git cherry-pick`
- **Demonstration.** Replay `labs/ch13/lab-12-1-hard-reset.sh`, `labs/ch13/lab-12-2-deleted-branch.sh` and `labs/ch13/lab-12-3-deleted-commit.sh`. For each: read the symptom, ask the three questions, show the evidence command, then the anchor, then the repair. These three are the guided pass; the learner repeats them from symptoms only in the labs.
- **Diagrams.** Redraw the diagram of section 13.7: the recovery method as a flow.
- **Practical exercise.** Lab 12.1 ("An accidental hard reset") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md)
- **Challenge.** Lab 12.2 ("A deleted branch") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md)
- **Interview question.** Q188: "Someone lost work. Which three questions do you ask before you type anything, and what does each answer rule in or out?"
- **Homework.** Read sections 13.7 and the first three recoveries of 13.8. Do Lab 12.3 ("A deleted commit") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md).
- **Expected outcome.** The learner recovers "lost" commits calmly and in the same order every time.

### V076: Recovering commits II: a wrong rebase, a bad merge, the wrong branch, detached HEAD, a wrong cherry-pick

- **Title.** Recovering commits II: a wrong rebase, a bad merge, the wrong branch, detached HEAD, a wrong cherry-pick
- **Learning objectives.** After this video the learner can:
  - Return a branch to its state before a rebase when `ORIG_HEAD` is stale
  - Undo a merge that was not pushed and one that was
  - Move commits made on the wrong branch to the right one
  - Rescue commits left in detached HEAD
  - Remove a wrong cherry-pick without touching the commits around it
- **Prerequisites.** V059, V075
- **Concepts.** Each case is the same method with a different ref to consult: the branch reflog entry before "rebase (start)", the first parent of the merge, the reflog of the branch that received the commits, HEAD's reflog for detached work. Published or not decides between reset and revert.
- **Commands.** `git reflog show`; `git reset --hard`; `git reset --keep`; `git revert -m`; `git branch`; `git cherry-pick`
- **Demonstration.** Replay `labs/ch13/lab-12-4-wrong-rebase.sh`, `labs/ch13/lab-12-5-bad-merge.sh`, `labs/ch13/lab-12-6-wrong-branch.sh`, `labs/ch13/lab-12-7-detached-head.sh` and `labs/ch13/lab-12-9-wrong-cherry-pick.sh`. Show both root-cause boxes of section 13.8 after the cases they explain.
- **Diagrams.** Show the root-cause box of section 13.8. New: one small before-and-after graph per case, five in a row.
- **Practical exercise.** Lab 12.4 ("A wrong rebase") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md)
- **Challenge.** Lab 12.6 ("Commits on the wrong branch") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md)
- **Interview question.** Q194: "`git reset --hard ORIG_HEAD` restored the wrong state. Explain the mechanism and the correct procedure."
- **Homework.** Read the rest of section 13.8. Do Lab 12.5 ("A bad merge") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md), Lab 12.7 ("Lost work in detached HEAD") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md) and Lab 12.9 ("A wrong cherry-pick") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md).
- **Expected outcome.** The learner has recovered from every local history disaster at least once, guided.

### V077: Recovering uncommitted work, and recovering from the remote side

- **Title.** Recovering uncommitted work, and recovering from the remote side
- **Learning objectives.** After this video the learner can:
  - State which uncommitted work has an object and which has none
  - Recover a staged file wiped by a hard reset from a dangling blob
  - Recover a cleared stash entry
  - Repair broken remote-tracking state
  - Restore commits overwritten by someone's forced push from your own clone
- **Prerequisites.** V042, V076
- **Concepts.** Staged content is a blob without a name; `git fsck --lost-found` writes such blobs to files. A stash entry is a commit and can be stored again by ID. Remote-tracking refs can be deleted and refetched without loss. After a forced push, the old tip is in your remote-tracking branch's reflog until the next expiry, and in any clone that has not fetched.
- **Commands.** `git fsck --lost-found`; `git fsck --unreachable`; `git stash list`; `git stash store -m`; `git stash show -p`; `git update-ref -d`; `git fetch`; `git reflog show`; `git ls-remote`; `git push`
- **Demonstration.** Replay `labs/ch13/lab-12-8-overwritten-changes.sh`, `labs/ch13/lab-12-10-remote-tracking.sh` and `labs/ch13/lab-12-11-force-push.sh`.
- **Diagrams.** New: a two-column table "kind of work" against "does an object exist, and what still names it" for committed, stashed, staged, unstaged and untracked work.
- **Practical exercise.** Lab 12.8 ("Overwritten changes and a cleared stash") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md)
- **Challenge.** Lab 12.11 ("A force push, seen from the local side") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md)
- **Interview question.** Q191: "A file was staged and then wiped by `git reset --hard`. What exactly can you get back, how, and what is gone? Why?"
- **Homework.** Read sections 13.9 and 13.10. Do Lab 12.10 ("Broken remote-tracking state, and a corrupt index") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md). Do Exercise 12.5 (Level 2, "One file from a commit that only the reflog knows") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md) and Exercise 12.7 (Level 3, "A rejected push after "a small addition"") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md).
- **Expected outcome.** The learner knows before searching whether a piece of lost work can exist at all.

### V078: A damaged repository, and what cannot be recovered

- **Title.** A damaged repository, and what cannot be recovered
- **Learning objectives.** After this video the learner can:
  - Recognize object corruption from the messages of ordinary commands and of `git fsck`
  - Explain why `git fetch` does not replace a corrupt object and what does
  - Repair a repository with one missing object from another clone
  - List what Git cannot recover and give the reason for each
- **Prerequisites.** V077
- **Concepts.** Corruption shows as `missing` or `corrupt` objects. A fetch asks only for objects the repository believes it lacks. Repair: take the object from another repository, or refetch everything. Not recoverable: edits never staged, untracked files removed, objects already pruned, reflogs that never existed.
- **Commands.** `git fsck`; `git fetch --refetch`; `git reset`; `git log --oneline --stat`
- **Demonstration.** Replay `labs/ch13/corruption.sh` (snippets `damage`, `symptoms`, `fsck`, `fetch-does-not-help`, `repair-one-object`, `refetch`).
- **Diagrams.** New: the table of section 13.12 as a two-column slide, "lost for good" and "why Git never had it or no longer has it".
- **Practical exercise.** Exercise 12.8 (Level 3, "The backup that will not clone") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 12.12 (Level 5, "Power loss in the middle of a commit") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q196: "`git fsck` reports `missing tree`. Why does `git fetch` not repair it, and what does?"
- **Homework.** Read sections 13.11 and 13.12. Write the CTO statement that Q199 of the question bank asks for.
- **Expected outcome.** The learner can state the limits of recovery without hedging.

### V079: The point of no return, prevention with backup refs and bundles, and what GitHub adds

- **Title.** The point of no return, prevention with backup refs and bundles, and what GitHub adds
- **Learning objectives.** After this video the learner can:
  - Describe the sequence that destroys the safety net and when it is appropriate
  - Show each step from "reflog protects it" to "pruned"
  - Protect work before a risky operation with a backup ref
  - Create, verify and use a bundle as an offline backup
  - Say which evidence GitHub keeps on the server side, as the cited section states it
- **Prerequisites.** V078
- **Concepts.** `git reflog expire --expire=now --all` followed by `git gc --prune=now` removes what the reflog protected. It is the documented way to make data unrecoverable locally, for example after a secret was committed and never pushed. A backup ref is one command and makes any rewrite reversible. A bundle is a repository in a file. GitHub, not Git: the server-side instruments of section 13.15.
- **Commands.** `git reflog expire --expire=now --all`; `git gc --prune=now`; `git prune -n`; `git count-objects -v`; `git branch`; `git bundle create`; `git bundle verify`; `git bundle list-heads`; `git range-diff`
- **Demonstration.** Replay `labs/ch13/gc-ladder.sh` (snippets `reflog-protects`, `preview`, `cruft-pack`, `prune-now`), then `labs/ch13/lab-12-12-point-of-no-return.sh`, then `labs/ch13/backup-and-bundle.sh` (snippets `backup-ref`, `compare-and-restore`, `bundle-create`, `bundle-use`). Give the five answers for a dangerous command before `prune-now`.
- **Diagrams.** Redraw the diagram of section 13.13: the ladder from reachable to pruned, with the command that takes each step down.
- **Practical exercise.** Lab 12.12 ("Prove the point of no return") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md)
- **Challenge.** Exercise 12.11 (Level 5, "Deleted, then cleaned up") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q197: "Describe precisely what `git reflog expire --expire=now --all` followed by `git gc --prune=now` does, when it is appropriate, and what can still bring a commit back afterwards."
- **Homework.** Read sections 13.13 to 13.18 and do the Practice section 13.20. Read [`playbooks/disaster-recovery-playbook.md`](../playbooks/disaster-recovery-playbook.md) and [`cheatsheets/emergency-recovery-one-page.md`](../cheatsheets/emergency-recovery-one-page.md).
- **Expected outcome.** The learner sets a way back before every rewrite and knows the one sequence after which nothing helps.

### V080: Tags: three kinds, two mechanisms, listing, and how tags travel

- **Title.** Tags: three kinds, two mechanisms, listing, and how tags travel
- **Learning objectives.** After this video the learner can:
  - Describe the refs and objects created by a lightweight, an annotated and a signed tag
  - Peel a tag to its commit with `^{}`
  - List tags in version order and filter them by what they contain
  - Explain which tags a fetch and a push carry
  - Delete a tag and say why other clones keep it
- **Prerequisites.** V008, V026
- **Concepts.** A lightweight tag is a ref to a commit. An annotated tag is an object with tagger, date and message, and a ref to that object. A signed tag is an annotated tag with a signature. Tags follow fetched history automatically; pushes send them only when asked. Deleting a tag on the server does not delete it elsewhere.
- **Commands.** `git tag`; `git tag -a`; `git tag -m`; `git show-ref --tags --dereference`; `git cat-file -t`; `git tag --sort=version:refname`; `git tag --contains`; `git tag --points-at`; `git push --follow-tags`; `git ls-remote --tags`; `git tag -d`; `git fetch --prune --prune-tags`
- **Demonstration.** Replay `labs/ch14b/tag-kinds.sh` (snippets `lightweight`, `annotated`, `peel`, `show`, `older-commit`, `not-a-commit`, `names`), `labs/ch14b/tag-listing.sh` (snippets `default-order`, `version-sort`, `configured`, `filters`, `formats`) and `labs/ch14b/tag-push.sh` (snippets `not-pushed`, `push-one`, `follow-tags`, `colleague-fetches`, `delete`, `other-clones-keep-it`).
- **Diagrams.** Redraw the diagram of section 14B.8: ref -> tag object -> commit beside ref -> commit.
- **Practical exercise.** Lab 13.1 ("Three kinds of tag") in [`lab-manual/m13-tags-versions.md`](../lab-manual/m13-tags-versions.md)
- **Challenge.** Exercise 13.5 (Level 2, "What a tag name resolves to") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q94: "Describe the objects and refs created by `git tag v1`, `git tag -a v1` and `git tag -s v1`. What does `v1^{}` resolve to in each case?"
- **Homework.** Read sections 14B.8 to 14B.10. Do Exercise 13.1 (Level 1, "Two kinds of tag, counted in objects") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md) to Exercise 13.3 (Level 1, "Which tags travel") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md).
- **Expected outcome.** The learner tags releases with annotated tags and knows exactly who has which tag.

### V081: Why a published tag must not move

- **Title.** Why a published tag must not move
- **Learning objectives.** After this video the learner can:
  - Reproduce a moved tag between two clones and say who has which version
  - Explain why `git fetch` keeps the old tag and what `--force` changes
  - Detect the disagreement by comparing local tags with the server
  - Repair it with the lowest-risk action and say why a new version number is that action
  - Name the server-side settings that refuse a tag update on a plain Git server
- **Prerequisites.** V039, V080
- **Concepts.** Fetch does not replace an existing tag. After a force-moved tag, old clones, new clones and CI caches disagree silently about what a version is. The low-risk repair is a new tag with a new name. Prevention is on the server.
- **Commands.** `git tag -f -a`; `git push --force`; `git fetch --tags`; `git fetch --tags --force`; `git ls-remote`; `git log --oneline --decorate`
- **Demonstration.** Replay `labs/ch14b/moved-tag.sh` (snippets `released`, `move`, `asha`, `fresh-clone`, `detect`, `repair`, `ci-still-wrong`, `server-settings`, `update-hook`). At `asha`, ask what her clone reports for the version.
- **Diagrams.** Show the root-cause box of section 14B.11. New: three boxes (releaser, old clone, fresh clone) each with the commit their tag names.
- **Practical exercise.** Lab 13.2 ("A moved tag between two clones") in [`lab-manual/m13-tags-versions.md`](../lab-manual/m13-tags-versions.md)
- **Challenge.** Exercise 13.9 (Level 4, "Two builds of 1.4.0") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q113: "A release tag was force-moved yesterday. Who has which version of it today, how do you find out, and what is the lowest-risk repair?"
- **Homework.** Read section 14B.11. Do Exercise 13.7 (Level 3, "The version that will not move") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md).
- **Expected outcome.** The learner treats a published tag as immutable and can prove a disagreement between clones.

### V082: git describe, Semantic Versioning, and release branches on the Git side

- **Title.** git describe, Semantic Versioning, and release branches on the Git side
- **Learning objectives.** After this video the learner can:
  - Read every part of a `git describe` string
  - Explain why describe fails or prints a different answer in a shallow clone
  - State the Semantic Versioning rules the section gives
  - Cut a release branch from a tag, backport a fix, and tag a patch release
  - Answer "which releases contain this fix" with tags
- **Prerequisites.** V063, V081
- **Concepts.** `git describe` names a commit by the nearest annotated tag reachable from it, the number of commits since, and the abbreviated ID. Without the tag's history it cannot count. Version numbers encode compatibility promises. A release branch receives only fixes; each patch release is a tag on it.
- **Commands.** `git describe`; `git describe --tags`; `git describe --always`; `git describe --dirty`; `git describe --tags --match`; `git fetch --unshallow`; `git tag --contains`; `git tag --merged`; `git cherry-pick -x`; `git log --oneline --cherry-pick --right-only`
- **Demonstration.** Replay `labs/ch14b/describe.sh` (snippets `no-tags`, `on-the-tag`, `after-the-tag`, `options`, `dirty`, `which-tags`, `contains`), `labs/ch14b/describe-shallow.sh` (snippets `full-clone`, `shallow`, `tags-without-history`, `unshallow`) and `labs/ch14b/release-branch.sh` (snippets `branch-from-tag`, `backport`, `two-lines`, `what-contains-the-fix`, `next-minor`).
- **Diagrams.** Show the root-cause box of section 14B.12. New: a describe string split into its three parts with an arrow from each to the graph.
- **Practical exercise.** Lab 13.3 ("Describe and versions") in [`lab-manual/m13-tags-versions.md`](../lab-manual/m13-tags-versions.md)
- **Challenge.** Exercise 13.6 (Level 2, "A patch release from a release branch") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q102: "`git describe` prints `v1.0.0-2-gc053f0d` on a laptop and fails in CI. Explain every part of the string and the failure."
- **Homework.** Read sections 14B.12 to 14B.14. Do Exercise 13.4 (Level 2, "What `git describe` prints") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md) and Exercise 13.8 (Level 3, "One name, two refs") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md).
- **Expected outcome.** The learner derives versions from history and explains the classic "works locally, fails in CI" of `git describe`.

### V083: Linked worktrees: what they are, what is shared, and one branch per worktree

- **Title.** Linked worktrees: what they are, what is shared, and one branch per worktree
- **Learning objectives.** After this video the learner can:
  - Say what `git worktree add` creates in the new directory and in the repository
  - List what worktrees share and what each has for itself
  - Find the real location of a per-worktree file with `git rev-parse --git-path`
  - Explain why Git refuses to check out one branch in two worktrees and what forcing it breaks
- **Prerequisites.** V023
- **Concepts.** A linked worktree is a second working tree with its own HEAD and index on one object store and one set of branches. `.git` in a linked worktree is a file pointing into the repository. A branch checked out twice would be moved by one worktree under the other's index.
- **Commands.** `git worktree add`; `git worktree list`; `git rev-parse --git-path`; `git worktree add --detach`; `git worktree add --force`; `git branch -f`
- **Demonstration.** Replay `labs/ch25/worktree-basics.sh` (snippets `add`, `link-files`, `git-path`, `shared-objects`, `separate-state`, `other-heads`) and `labs/ch25/worktree-one-branch.sh` (snippets `refused`, `branch-protection`, `detached`, `forced`, `forced-explained`, `forced-repair`).
- **Diagrams.** Redraw the diagram of section 25.2; show the root-cause box of section 25.4.
- **Practical exercise.** Exercise 14.1 (Level 1, "A second working tree for a hotfix") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 14.9 (Level 4, "Two fixes in a worktree that no longer exists") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q95: "What exactly does `git worktree add` create on disk, in the new directory and in the repository?"
- **Homework.** Read sections 25.1 to 25.4.
- **Expected outcome.** The learner understands a worktree as a second HEAD and index, not as a second clone.

### V084: Worktrees in use: the hotfix during a rebase, reviewing a branch, the life cycle, and the pitfalls

- **Title.** Worktrees in use: the hotfix during a rebase, reviewing a branch, the life cycle, and the pitfalls
- **Learning objectives.** After this video the learner can:
  - Make an urgent fix in a second worktree while a rebase is stopped in the first
  - Review a colleague's branch without disturbing your own work
  - Add, list, remove, lock, move, prune and repair worktrees
  - Explain three surprises that come from sharing: the stash, the configuration, ignored files
  - Decide when a separate clone is the better tool
- **Prerequisites.** V053, V083
- **Concepts.** A worktree is the alternative to aborting or stashing. Life cycle commands keep the repository's list of worktrees in step with the directories; deleting a directory by hand leaves an entry for `prune`. The stash list and most configuration are shared; per-worktree configuration exists and must be enabled.
- **Commands.** `git worktree add -b`; `git worktree add --detach`; `git worktree remove`; `git worktree lock --reason`; `git worktree move`; `git worktree prune --verbose`; `git worktree repair`; `git worktree list --porcelain`; `git stash list`; `git config set`
- **Demonstration.** Replay `labs/ch25/worktree-hotfix.sh` (snippets `stuck`, `add`, `fix`, `back`), `labs/ch25/worktree-review.sh` (snippets `fetch`, `detached-review`, `with-a-branch`), `labs/ch25/worktree-lifecycle.sh` (snippets `add-forms`, `list`, `remove`, `lock`, `move`, `deleted-by-hand`, `moved-by-hand`, `main-moved`) and `labs/ch25/worktree-shared-pitfalls.sh` (snippets `ignored-files`, `stash-shared`, `config-shared`, `config-per-worktree`, `gc-keeps-other-worktrees`).
- **Diagrams.** New: one repository box with three worktree boxes around it; shared items inside the repository box, per-worktree items inside each worktree box.
- **Practical exercise.** Lab 14.1 ("A hotfix in a second worktree while a rebase is in progress") in [`lab-manual/m14-worktrees.md`](../lab-manual/m14-worktrees.md)
- **Challenge.** Exercise 14.9 (Level 4, "Two fixes in a worktree that no longer exists") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q114: "A rebase has stopped at a conflict and an urgent fix is needed on `main`. Compare three options: abort the rebase, a second clone, a worktree."
- **Homework.** Read sections 25.5 to 25.10 and do the Practice section 25.12.
- **Expected outcome.** The learner reaches for a worktree when interrupted and cleans up worktrees correctly.

### V085: Stash internals: a stash entry is a small commit graph

- **Title.** Stash internals: a stash entry is a small commit graph
- **Learning objectives.** After this video the learner can:
  - Draw the commits of a stash entry made with and without untracked files
  - Say which tree holds the staged state and which the unstaged state
  - Show that the stash list is the reflog of one ref
  - Create a stash commit without touching the list, and store it
  - Recover a dropped entry by ID
- **Prerequisites.** V019, V050
- **Concepts.** A stash entry is a merge commit whose parents are HEAD, a commit of the index, and optionally a commit of the untracked files. `refs/stash` points at the newest entry; older entries exist only in that ref's reflog. `git stash create` and `git stash store` are the plumbing.
- **Commands.** `git stash push -m`; `git log --graph`; `git show -s --format=raw`; `git ls-tree -r`; `git stash show -p`; `git stash show --only-untracked`; `git stash create`; `git stash store -m`; `git stash drop`; `git stash export --to-ref`
- **Demonstration.** Replay `labs/ch14c/stash-anatomy.sh` (snippets `push`, `graph`, `commit-object`, `trees`, `show`, `ref-and-reflog`, `create-store`, `drop`, `export`, `import`).
- **Diagrams.** Redraw the diagram of section 14C.2.
- **Practical exercise.** Lab 14.6 ("Stash anatomy") in [`lab-manual/m14-hooks-rerere-attributes.md`](../lab-manual/m14-hooks-rerere-attributes.md)
- **Challenge.** Exercise 14.4 (Level 2, "The shape of a stash entry") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q178: "Draw the commits of a stash entry made with `git stash push -u`. Which tree holds the staged change, which the unstaged one, and what does `git stash show -p` compare?"
- **Homework.** Read section 14C.2.
- **Expected outcome.** The learner explains every stash behavior from its commits and no longer fears losing a stash entry.

### V086: Rerere: resolve a conflict once

- **Title.** Rerere: resolve a conflict once
- **Learning objectives.** After this video the learner can:
  - Say what rerere records and at which moment
  - Show a recorded resolution being replayed in a later merge and in a rebase
  - Forget a wrong recorded resolution and record a correct one
  - Explain why a replayed resolution still has to be reviewed and tested
  - Explain the lock failure on Git 2.55 and the setting that prevents it
- **Prerequisites.** V057, V085
- **Concepts.** Rerere stores the conflicted preimage and the resolved postimage keyed by the conflict's content. The same conflict later is resolved in the working tree; staging it is a separate setting. A wrong resolution is replayed as faithfully as a right one. On Git 2.55, automatic maintenance runs a `rerere-gc` task that can collide with a running rebase; `maintenance.rerere-gc.auto=0` avoids it.
- **Commands.** `rerere.enabled`; `git rerere status`; `git rerere diff`; `git rerere remaining`; `git rerere forget`; `git restore --merge`; `git rebase --continue`; `rerere.autoUpdate`; `maintenance.rerere-gc.auto`
- **Demonstration.** Replay `labs/ch14c/rerere-merge.sh` (snippets `first-conflict`, `recorded`, `resolve`, `throw-away`, `real-merge`, `state`, `finish`), `labs/ch14c/rerere-rebase.sh` (snippets `rebase`, `continue`, `autoupdate`), `labs/ch14c/rerere-wrong.sh` (snippets `replayed`, `forget`, `record-again`), `labs/ch14c/rerere-lock.sh` (snippets `locked`, `recover`) and `labs/ch14c/rerere-lock-race.sh` (snippets `counts`).
- **Diagrams.** Show the root-cause box of section 14C.3. New: a store drawn as pairs "conflict -> resolution" with one merge writing a pair and a later rebase reading it.
- **Practical exercise.** Lab 14.5 ("Rerere, resolve once") in [`lab-manual/m14-hooks-rerere-attributes.md`](../lab-manual/m14-hooks-rerere-attributes.md)
- **Challenge.** Exercise 14.8 (Level 3, "A resolution that nobody typed") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q129: "What does rerere record, and when? Why does a resolution recorded in a merge also serve a rebase in the other direction?"
- **Homework.** Read section 14C.3.
- **Expected outcome.** The learner enables rerere for long-lived branches knowingly and can correct what it recorded.

### V087: .gitattributes: per-path settings that travel, and line endings

- **Title.** .gitattributes: per-path settings that travel, and line endings
- **Learning objectives.** After this video the learner can:
  - Say which attribute applies to a path and from which file it comes
  - Explain "the attribute travels, the driver does not"
  - Normalize line endings in a repository with `text` and `eol` and predict what the next `git status` shows
  - Renormalize existing files in one commit
  - Explain what `core.autocrlf` cannot do that attributes do
- **Prerequisites.** V012, V014
- **Concepts.** `.gitattributes` is committed and applies to everyone; the programs it names are configured per clone. `text=auto` normalizes on the way in; `eol` fixes the working-tree form. Adding normalization to an old repository shows files as modified until they are renormalized. `export-ignore` for archives.
- **Commands.** `git check-attr`; `git check-attr -a --`; `git ls-files --eol`; `git add --renormalize`; `git archive --format=tar`; `core.autocrlf`
- **Demonstration.** Replay `labs/ch14c/attr-basics.sh` (snippets `files`, `check-attr`, `precedence`, `export-ignore`) and `labs/ch14c/attr-eol.sh` (snippets `before`, `autocrlf`, `attributes`, `after`, `fresh-checkout`).
- **Diagrams.** New: one file's bytes in three places (repository, index view, working tree) with LF and CRLF marked, before and after the attribute.
- **Practical exercise.** Exercise 14.2 (Level 1, "Attributes that travel with the repository") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 14.5 (Level 2, "A changelog that conflicts on every merge") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q58: "Your team adds `* text=auto` to a five-year-old repository. What does the next `git status` show, what does `git add --renormalize .` do, and how do you protect open branches and `git blame`?"
- **Homework.** Read sections 14C.4 and 14C.5.
- **Expected outcome.** The learner fixes line-ending problems at the repository level, once, for the whole team.

### V088: Diff drivers, merge drivers, and clean and smudge filters

- **Title.** Diff drivers, merge drivers, and clean and smudge filters
- **Learning objectives.** After this video the learner can:
  - Make a binary or generated format diffable with a `textconv` driver
  - Choose `merge=union`, `-merge` or a custom merge driver for a file and state the risk of each
  - Write a clean and smudge filter pair and show what is stored and what is checked out
  - Explain what a clone receives of a filter and what `required` changes
  - Name where this mechanism is used later in the course
- **Prerequisites.** V087
- **Concepts.** A diff driver changes what is displayed, never what is stored. `merge=union` keeps both sides' lines and can produce a wrong file without a conflict. A clean filter rewrites content on the way into the index; a smudge filter on the way out. The clone gets the attribute and not the filter definition. Git LFS and notebook stripping are built on this.
- **Commands.** `git check-attr`; `git diff --no-textconv --stat`; `git config set`; `git ls-files -u`; `git add --renormalize`; `git cat-file -p`; `git clone`
- **Demonstration.** Replay `labs/ch14c/attr-diff.sh` (snippets `raw-diff`, `attribute-only`, `driver`, `scope`, `funcname`), `labs/ch14c/attr-merge.sh` (snippets `two-conflicts`, `attributes`, `driver`, `unset`) and `labs/ch14c/attr-filter.sh` (snippets `before`, `define`, `renormalize`, `rerun`, `clone`).
- **Diagrams.** Redraw the diagram of section 14C.8: working tree -> clean -> index and repository; repository -> smudge -> working tree.
- **Practical exercise.** Lab 14.4 ("A clean and smudge filter") in [`lab-manual/m14-hooks-rerere-attributes.md`](../lab-manual/m14-hooks-rerere-attributes.md)
- **Challenge.** Exercise 14.5 (Level 2, "A changelog that conflicts on every merge") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q59: "Explain "the attribute travels, the driver does not" for a diff driver, a merge driver and a required filter."
- **Homework.** Read sections 14C.6 to 14C.8.
- **Expected outcome.** The learner can add a filter or driver to a repository and say what teammates must configure for it to work.

### V089: Hooks: programs that Git runs at fixed points

- **Title.** Hooks: programs that Git runs at fixed points
- **Learning objectives.** After this video the learner can:
  - Name the hooks that run for a commit, a checkout, a merge, a rebase and a push, in order
  - Say which hooks can stop an operation and which only observe
  - Write a `pre-commit` hook that checks the index and not the working tree
  - Write a `commit-msg` hook and a `pre-push` guard
  - Explain why a hook that depends on tools must check for them
- **Prerequisites.** V021, V055
- **Concepts.** A hook is an executable file that Git runs at a defined point with defined arguments and standard input. Exit status non-zero from a "pre" hook stops the operation. `pre-commit` must look at the staged content. `pre-push` receives the refs being pushed. `pre-rebase` can refuse to rebase published branches.
- **Commands.** `git commit`; `git commit --amend -m`; `git commit --no-verify -m`; `git rebase`; `git rebase --no-verify`; `git push`; `git restore --staged`
- **Demonstration.** Replay `labs/ch14c/hook-tour.sh` (snippets `samples`, `install`, `commit`, `amend`, `checkout`, `merge`, `rebase`, `push`, `no-verify`), `labs/ch14c/hook-pre-commit.sh` (snippets `hook`, `blocked`, `index-not-disk`, `no-verify`), `labs/ch14c/hook-pre-rebase.sh` (snippets `hook`, `local-branch`, `published-branch`, `no-verify`) and `labs/ch14c/hook-deps.sh` (snippets `hooks`, `checkout`, `pull`, `exit-status`). Then `labs/ch14c/lab-14-2-commit-msg-hook.sh` and `labs/ch14c/lab-14-3-pre-push-guard.sh` as the two worked hooks.
- **Diagrams.** New: a timeline of `git commit` and of `git push` with each hook as a gate, marked "can stop" or "observes".
- **Practical exercise.** Lab 14.2 ("A commit-msg hook") in [`lab-manual/m14-hooks-rerere-attributes.md`](../lab-manual/m14-hooks-rerere-attributes.md)
- **Challenge.** Lab 14.3 ("A pre-push guard") in [`lab-manual/m14-hooks-rerere-attributes.md`](../lab-manual/m14-hooks-rerere-attributes.md)
- **Interview question.** Q424: "Which hooks run for `git commit`, in which order, and which does `--no-verify` skip? Which commit-creating commands run none of the checking hooks?"
- **Homework.** Read sections 14C.9 and 14C.10. Do Exercise 14.3 (Level 1, "A pre-commit hook, and its limit") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md) and Exercise 14.6 (Level 2, "Which hooks run") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md).
- **Expected outcome.** The learner writes hooks that check the right content and knows the order in which they fire.

### V090: --no-verify, core.hooksPath, sharing hooks, hook security, and why hooks cannot enforce policy

- **Title.** --no-verify, core.hooksPath, sharing hooks, hook security, and why hooks cannot enforce policy
- **Learning objectives.** After this video the learner can:
  - Explain why hooks are not cloned
  - Share hooks through `core.hooksPath` and through hooks defined in configuration, and give the cost of each
  - Run a hook by name with `git hook run`
  - Show what an unpacked archive of a repository can execute that a clone cannot
  - State what enforces policy when a client-side hook does not
- **Prerequisites.** V089
- **Concepts.** A clone never receives executable hooks: that is a security property. `core.hooksPath` points Git at a tracked directory; configuration-defined hooks exist since Git 2.54. `--no-verify` skips client-side checks, and several commands run no commit hooks at all. An archive that contains `.git` carries hooks and configuration. Policy needs the server or CI.
- **Commands.** `git commit --no-verify`; `core.hooksPath`; `git config set`; `git hook run`; `git clone`; `git config list --local --show-origin`
- **Demonstration.** Replay `labs/ch14c/hooks-sharing.sh` (snippets `not-cloned`, `hookspath`, `config-hooks`, `switches`, `hook-run`) and `labs/ch14c/hook-untrusted.sh` (snippets `archive`, `what-ran`, `clone`). Return to the `failure` part of `labs/ch14c/lab-14-3-pre-push-guard.sh` for the bypass.
- **Diagrams.** New: three layers (client hook, server-side check, CI) with "can be skipped by the author" marked on the first only.
- **Practical exercise.** Exercise 14.7 (Level 3, ""The hook works on my machine"") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Write a one-page proposal for your team: which checks run as hooks, which in CI, which as server rules, with the reason for each placement. Keep it for V174.
- **Interview question.** Q451: "Why are hooks not cloned? Describe three ways to share them and the security cost of each."
- **Homework.** Read sections 14C.11 to 14C.16 and do the Practice section 14C.18.
- **Expected outcome.** The learner uses hooks as a convenience and places enforcement where it cannot be bypassed.

### V091: Submodules: a gitlink, .gitmodules, and what a teammate receives

- **Title.** Submodules: a gitlink, .gitmodules, and what a teammate receives
- **Learning objectives.** After this video the learner can:
  - Say what a superproject stores about a submodule and where each piece is
  - Read a gitlink entry in a tree and explain why `git cat-file` cannot show its target
  - Take a plain clone through `init` and `update` and say what each writes
  - Explain why a recursive clone of an untrusted repository is a security decision
- **Prerequisites.** V008, V038
- **Concepts.** A submodule is a commit ID recorded in the superproject's tree with mode 160000, a URL in `.gitmodules`, and a separate repository under `.git/modules`. The superproject does not contain the submodule's objects. `init` copies the URL into local configuration; `update` clones and checks out the recorded commit. `protocol.file.allow` and why the lab sets it.
- **Commands.** `git submodule add`; `git submodule status`; `git ls-tree`; `git ls-files --stage`; `git config list --local`; `git submodule init`; `git submodule update`; `git clone --recurse-submodules`; `protocol.file.allow`
- **Demonstration.** Replay `labs/ch23/submodule-add.sh` (snippets `blocked`, `add`, `gitmodules`, `gitlink`, `modules-dir`, `diff`, `commit`, `not-our-object`) and `labs/ch23/submodule-clone.sh` (snippets `plain-clone`, `init`, `update`, `detached`, `recursive-refused`, `policy`, `recursive`).
- **Diagrams.** Redraw the diagram of section 23.2.
- **Practical exercise.** Exercise 15.1 (Level 1, "Add a submodule and read what was recorded") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 15.7 (Level 3, "An empty directory on the build machine") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q421: "What exactly does a superproject store about a submodule, and what does it not store? Where is each piece?"
- **Homework.** Read sections 23.1 to 23.4.
- **Expected outcome.** The learner describes a submodule as a pinned commit ID and can bring a fresh clone to a working state.

### V092: Submodules in motion: the detached HEAD, moving the pointer, the stale submodule and the silent rollback

- **Title.** Submodules in motion: the detached HEAD, moving the pointer, the stale submodule and the silent rollback
- **Learning objectives.** After this video the learner can:
  - Explain why HEAD is detached in a submodule after `update` and why that is correct
  - Commit inside a submodule without losing the commit
  - Move the recorded pointer and read the change in `git status` and `git diff --submodule`
  - Explain how a teammate's stale submodule leads to a commit that rolls the pointer back
  - Configure a clone so that pulls keep submodules in step
- **Prerequisites.** V024, V091
- **Concepts.** `update` checks out the exact recorded commit, which no branch need name. Work in the submodule needs a branch there. Moving the pointer is a commit in the superproject. After a pull, the submodule directory stays at the old commit unless updated; `git commit -a` then records the old ID again. `submodule.recurse`.
- **Commands.** `git submodule update`; `git submodule update --remote`; `git submodule status`; `git diff --submodule=log`; `git switch --detach`; `git pull`; `submodule.recurse`
- **Demonstration.** Replay `labs/ch23/submodule-detached.sh` (snippets `commit-on-detached`, `update-moves-head`, `rescue`, `work-on-a-branch`), `labs/ch23/submodule-update.sh` (snippets `remote`, `status-diff`, `commit-pointer`, `teammate-pull`, `teammate-stale`, `accidental-rollback`, `repair`) and `labs/ch23/submodule-recurse.sh` (snippets `two-steps`, `switch-without`, `recurse`).
- **Diagrams.** Show the root-cause box of section 23.7. New: superproject commit, recorded ID and submodule HEAD as three values in a row, compared after each command.
- **Practical exercise.** Lab 15.1 ("A submodule that breaks for a teammate") in [`lab-manual/m15-submodules-subtrees-lfs.md`](../lab-manual/m15-submodules-subtrees-lfs.md)
- **Challenge.** Exercise 15.4 (Level 2, "The first character of `git submodule status`") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q428: "Why is HEAD detached in a submodule after `git submodule update`? When does that lose work, and how do you get it back?"
- **Homework.** Read sections 23.5 to 23.7.
- **Expected outcome.** The learner keeps the three values (recorded, checked out, upstream) apart and spots a rollback in review.

### V093: Submodule failures: push order, dirty submodules, pointer conflicts, removal, URL changes, and CI

- **Title.** Submodule failures: push order, dirty submodules, pointer conflicts, removal, URL changes, and CI
- **Learning objectives.** After this video the learner can:
  - Diagnose `not our ref` and prevent it with a push guard
  - Handle a dirty submodule when switching branches
  - Resolve a conflict between two recorded pointers and say when Git resolves it alone
  - Remove a submodule completely and re-add one and propagate a changed URL to existing clones
  - State what a CI checkout needs for submodules, as the section gives it
- **Prerequisites.** V092
- **Concepts.** Pushing the superproject before the submodule publishes a pointer to a commit nobody can fetch. `push.recurseSubmodules=check` or `on-demand`. A pointer conflict is a conflict between two commit IDs; Git fast-forwards when one contains the other. Removal has three places to clean. `git submodule sync` copies a changed URL.
- **Commands.** `git push --recurse-submodules=check`; `git push --recurse-submodules=on-demand`; `git submodule foreach`; `git submodule update --force`; `git diff --submodule=diff`; `git ls-files --unmerged`; `git submodule deinit`; `git rm`; `git submodule set-url`; `git submodule sync`
- **Demonstration.** Replay `labs/ch23/submodule-push-order.sh` (snippets `local-library-commit`, `guard`, `mistake`, `teammate`, `diagnose`, `not-here`, `fix`, `on-demand`, `config`), `labs/ch23/submodule-dirty.sh` (snippets `dirty`, `diff`, `commit-a`, `foreach`, `discard`), `labs/ch23/submodule-switch.sh` (snippets `stray-directory`, `back`, `recurse`), `labs/ch23/submodule-conflict.sh` (snippets `two-pointers`, `conflict`, `stages`, `library-merges`, `resolve`, `ancestor-case`), `labs/ch23/submodule-remove.sh` (snippets `deinit`, `reinit`, `rm`, `commit`, `leftovers`, `readd-refused`, `complete-removal`, `old-commits`) and `labs/ch23/submodule-url.sh` (snippets `set-url`, `teammate-stale-url`, `sync`).
- **Diagrams.** New: a table of failures with columns symptom, the value that disagrees, fix, prevention.
- **Practical exercise.** Exercise 15.4 (Level 2, "The first character of `git submodule status`") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 15.9 (Level 4, "It works on your machine") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q440: "A teammate's pull fails with `not our ref`. Give the root cause, the three commands that prove it, the fix, and the setting that prevents it."
- **Homework.** Read sections 23.8 to 23.12.
- **Expected outcome.** The learner diagnoses the standard submodule failures from one `git submodule status` line.

### V094: Subtrees, and choosing between a submodule, a subtree and a package manager

- **Title.** Subtrees, and choosing between a submodule, a subtree and a package manager
- **Learning objectives.** After this video the learner can:
  - Add a dependency as a subtree and show what the superproject's history then contains
  - Pull an upstream release into the subtree and contribute a local change back
  - Explain how `git subtree split` can reproduce upstream commit IDs
  - Decide between submodule, subtree and package manager for a described dependency
- **Prerequisites.** V036, V093
- **Concepts.** A subtree copies the dependency's files into your own tree and history; a teammate needs nothing extra. Updates are merges into a prefix. `split` extracts the prefix's history. The decision table of section 23.14: who changes the dependency, how often, and what a fresh clone must do.
- **Commands.** `git subtree add --prefix`; `git subtree pull --prefix`; `git subtree split`; `git subtree push`; `git ls-tree`; `git log --graph`
- **Demonstration.** Replay `labs/ch23/subtree.sh` (snippets `add`, `what-it-is`, `teammate`, `pull`, `pull-message`, `local-change`, `split`, `push`).
- **Diagrams.** New: the same dependency drawn twice: as a gitlink pointing out of the superproject, and as a directory of ordinary blobs inside it.
- **Practical exercise.** Lab 15.2 ("The same dependency as a subtree") in [`lab-manual/m15-submodules-subtrees-lfs.md`](../lab-manual/m15-submodules-subtrees-lfs.md)
- **Challenge.** Exercise 15.5 (Level 2, "Two subtree operations") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q454: "Submodule, subtree, package manager: decide for (a) an internal protocol-definition repository used by eight services, (b) a 300-line utility copied from an open-source project, (c) a tokenizer library published on a package index."
- **Homework.** Read sections 23.13 to 23.17 and do the Practice section 23.19. Do Exercise 15.3 (Level 1, "The same library as a subtree") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md).
- **Expected outcome.** The learner recommends a dependency mechanism with reasons and knows the cost of each.

### V095: Git LFS: why it exists, the pointer file, the two filters, and tracking

- **Title.** Git LFS: why it exists, the pointer file, the two filters, and tracking
- **Learning objectives.** After this video the learner can:
  - Explain what large binary files do to every clone and why deleting them later does not help
  - Say what Git stores for an LFS-tracked path and what LFS stores, and where each is
  - Read a pointer file
  - Explain which two Git mechanisms LFS uses and which parts travel with a clone
  - State what `git lfs track` does not do for files already committed
- **Prerequisites.** V088
- **Concepts.** Every version of a binary is a full object in every clone, forever. LFS replaces the content by a small pointer through a clean filter and restores it through a smudge filter; a `pre-push` hook uploads the content. The `.gitattributes` line travels; the filter configuration is installed per machine. Tracking affects files added afterwards.
- **Commands.** `git lfs install --local`; `git lfs track`; `git lfs ls-files`; `git lfs pointer`; `git check-attr`; `git cat-file -s`; `git lfs version`
- **Demonstration.** Replay `labs/ch22/why-lfs.sh` (snippets `three-versions`, `clone-gets-all`, `delete-does-not-help`) and `labs/ch22/lfs-pointer.sh` (snippets `install`, `track`, `commit`, `pointer`, `local-store`, `new-version`, `hook`).
- **Diagrams.** Redraw the diagram of section 22.3.
- **Practical exercise.** Lab 15.3 ("Inspect an LFS pointer") in [`lab-manual/m15-submodules-subtrees-lfs.md`](../lab-manual/m15-submodules-subtrees-lfs.md)
- **Challenge.** Exercise 15.6 (Level 2, "Tracked too late") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q355: "What does Git store for an LFS-tracked path, what does LFS store, and where is each on your machine and on the remote?"
- **Homework.** Read sections 22.1 to 22.4. Do Exercise 15.2 (Level 1, "A first LFS pointer") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md).
- **Expected outcome.** The learner explains LFS as a filter pair plus a second store and can read what Git itself holds.

### V096: Git LFS day to day: status, pushing, cloning without the client, and the local store

- **Title.** Git LFS day to day: status, pushing, cloning without the client, and the local store
- **Learning objectives.** After this video the learner can:
  - Read `git lfs status` and say what a push will upload
  - Say where LFS objects go on push and how the endpoint is derived
  - Recognize a clone made without the client by the size of its files and repair it
  - Fetch on demand and skip the smudge filter for speed
  - Explain how `git lfs prune` decides what to delete and when that is unsafe
- **Prerequisites.** V041, V095
- **Concepts.** Two stores travel separately: Git objects by Git, LFS objects by the LFS client. Without the client a checkout holds pointer files. `git lfs fetch` and `git lfs checkout` are the two halves of `git lfs pull`. The local store can be pruned of objects that are on the remote and not needed by recent checkouts; Git's reflog does not protect LFS content.
- **Commands.** `git lfs status`; `git lfs env`; `git lfs fetch`; `git lfs checkout`; `git lfs pull`; `git lfs ls-files --size`; `git lfs prune --dry-run --verbose`; `git lfs prune --verify-remote`; `git lfs fetch --all`; `git lfs fsck`
- **Demonstration.** Replay `labs/ch22/lfs-push-volatile.sh` (snippets `endpoint`, `push`, `remote-store`) and say on screen that this script is volatile, so its IDs differ on every run. Then `labs/ch22/lfs-clone.sh` (snippets `clone-without-client`, `what-is-missing`, `install-fetch-checkout`, `smudge-on-demand`, `skip-smudge`), `labs/ch22/lfs-prune.sh` (snippets `store`, `prune`, `fetch-again`, `unpushed-is-kept`) and `labs/ch22/lfs-lock.sh` (snippets `lock-needs-a-server`).
- **Diagrams.** New: laptop and server, each drawn with two stores (Git objects, LFS objects) and separate arrows for each kind of transfer.
- **Practical exercise.** Exercise 15.8 (Level 3, "A model file of 131 bytes") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Challenge.** Exercise 15.9 (Level 4, "It works on your machine") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q360: "A CI job fails because a model file is 132 bytes. Give the root cause, two diagnostics, and the fix for GitHub Actions."
- **Homework.** Read sections 22.5 to 22.8.
- **Expected outcome.** The learner diagnoses "the model file is 130 bytes" at sight and manages the local LFS store safely.

### V097: git lfs migrate, the common LFS errors, GitHub's limits and billing, and when LFS is the wrong tool

- **Title.** git lfs migrate, the common LFS errors, GitHub's limits and billing, and when LFS is the wrong tool
- **Learning objectives.** After this video the learner can:
  - Say what `git lfs migrate import` does to commit IDs, the working tree and the size of `.git`
  - Plan a migration of a shared repository as a history rewrite
  - Diagnose three LFS errors from their messages: a missing object, a file that should have been a pointer, a file tracked too late
  - State GitHub's file limits and the LFS billing model as the cited section gives them
  - Decide when LFS is the wrong tool and name the alternative the section gives
- **Prerequisites.** V052, V096
- **Concepts.** `migrate import` rewrites history so that old versions become pointers: every commit ID after the first affected commit changes, with all the consequences of a rewrite. The old objects remain until pruned. Error anatomy. GitHub, not Git: limits and metered billing from section 22.11. When not to use LFS.
- **Commands.** `git lfs migrate`; `git lfs ls-files`; `git lfs fsck --pointers`; `git add --renormalize`; `git lfs push --all`; `git rev-list --objects --all`; `git reflog expire --expire=now --all`; `git gc --quiet --prune=now`
- **Demonstration.** Replay `labs/ch22/lfs-migrate.sh` (snippets `info`, `import`, `what-changed`, `working-tree`, `old-objects`), `labs/ch22/lfs-error-not-pointer.sh` (snippets `commit-without-filter`, `symptom`, `diagnose`, `fix`), `labs/ch22/lfs-error-tracked-late.sh` (snippets `added-first`, `symptom`, `fix-forward`, `history-still-has-it`) and, marked as volatile on screen, `labs/ch22/lfs-error-missing-object-volatile.sh` (snippets `pull-fails`, `smudge-fails`, `diagnose`, `fix`) and `labs/ch22/lfs-migrate-export-volatile.sh` (snippets `before`, `export`, `after`).
- **Diagrams.** Show the root-cause box of section 22.9. New: a history before and after `migrate import`, with the changed commit IDs marked from the first affected commit on.
- **Practical exercise.** Lab 15.4 ("Migrate an already-committed large file") in [`lab-manual/m15-submodules-subtrees-lfs.md`](../lab-manual/m15-submodules-subtrees-lfs.md)
- **Challenge.** Exercise 15.9 (Level 4, "It works on your machine") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q368: "What does `git lfs migrate import` do to commit IDs, to the working tree, and to the size of `.git`? What is the default scope, and what does `--everything` add?"
- **Homework.** Read sections 22.9 to 22.14 and do the Practice section 22.16.
- **Expected outcome.** The learner treats an LFS migration as the history rewrite it is and knows when to keep large files out of Git altogether.

### V098: Gate briefing: Recovery

- **Title.** Gate briefing: Recovery
- **Learning objectives.** After this video the learner can:
  - State what Gate 4 covers and its threshold of 90
  - Recite the recovery method and apply it before touching a broken repository
  - Say for each kind of lost work whether an object can exist
  - Prepare the oral part with the limits of each safety net
- **Prerequisites.** V072, V079, V097
- **Concepts.** Gate 4 covers forensics, the reflog, `git fsck`, the disaster recoveries and what cannot be recovered. The hands-on repository has lost something; the first destructive command typed in haste is what fails candidates. Anchor first. The gate also asks for the honest answer when recovery is impossible.
- **Commands.** `git reflog show`; `git fsck --no-reflogs --lost-found`; `git branch`
- **Demonstration.** Replay `labs/ch13/fsck-find.sh` (snippets `with-reflogs`, `no-reflogs`, `triage`, `anchor`) as the warm-up: find, triage, anchor. Show the gate rules from [`assessments/README.md`](../assessments/README.md). Do not open the gate file on screen.
- **Diagrams.** Redraw the diagram of section 13.7 once more, and beside it the table of what cannot be recovered.
- **Practical exercise.** Redo Lab 12.1 ("An accidental hard reset") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md) to Lab 12.12 ("Prove the point of no return") in [`lab-manual/m12-recovery.md`](../lab-manual/m12-recovery.md) from symptoms only, as the roadmap's second pass, without the lab text.
- **Challenge.** Take Gate 4: [`assessments/gate-4-recovery.md`](../assessments/gate-4-recovery.md).
- **Interview question.** Q199: "Your CTO wants a short, defensible statement of what Git cannot recover, so that the team stops treating the reflog as a backup. What is on that list, and what single principle produces every line of it?"
- **Homework.** Before the gate: answer the "Interview questions" sections of Chapters 13, 14A, 14B, 14C, 22, 23 and 25 aloud.
- **Expected outcome.** The learner sits Gate 4 with a fixed recovery order and no reflex for destructive commands.

## Part 4: Git internals

Roadmap Level 4 (Modules 16 to 18), then the Internals gate. 16 videos on the storage layer: object files, packfiles, maintenance, ref storage, the index file, reftable, SHA-256, the structures that make large repositories fast, and the kinds of clone.

### V099: The .git directory file by file, and the loose object format

- **Title.** The .git directory file by file, and the loose object format
- **Learning objectives.** After this video the learner can:
  - Name every entry of a fresh `.git` directory and say what reads or writes it
  - Say which files of `.git` can be deleted without breaking the repository
  - Describe the bytes of a loose object: header, content, compression
  - Compute a blob's object ID by hand and explain why the compression level does not matter
  - Find the file that holds a given object
- **Prerequisites.** V003, V008
- **Concepts.** `HEAD`, `config`, `objects/`, `refs/`, `index`, `logs/`, `hooks/`, `info/`, and what appears after the first commit. A loose object is the zlib-compressed bytes of "type, space, size, NUL, content"; the ID is the hash of the uncompressed bytes; the file path is the ID split after two characters.
- **Commands.** `git init`; `git count-objects`; `git hash-object`; `git hash-object -w`; `git cat-file -s`; `git cat-file -t`; `git cat-file -p`
- **Demonstration.** Replay `labs/ch03/gitdir-tour.sh` (snippets `init`, `init-contents`, `first-commit`, `new-files`) and `labs/ch03/loose-object.sh` (snippets `write`, `inflate`, `read-back`, `status`). In `inflate`, read the header bytes aloud.
- **Diagrams.** Redraw the diagram of section 3.3: the bytes of one loose object, labelled.
- **Practical exercise.** Exercise 16.1 (Level 1, "An object ID by hand") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Challenge.** Exercise 17.9 (Level 4, ""Not a git repository"") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q68: "Compute the object ID of a blob by hand. Which bytes are hashed, and why does the compression level not matter?"
- **Homework.** Read sections 3.1 to 3.3. Repeat Lab 0.2 ("Read every file in an empty `.git`") in [`lab-manual/m00-lab-setup.md`](../lab-manual/m00-lab-setup.md) and name every file from memory.
- **Expected outcome.** The learner can open any file under `.git` and say what it is for.

### V100: The four object types in full, and reading objects with cat-file, ls-tree and show

- **Title.** The four object types in full, and reading objects with cat-file, ls-tree and show
- **Learning objectives.** After this video the learner can:
  - Read the raw form of a tree entry and list the modes Git uses
  - Explain why changing a message three commits back changes the ID of HEAD
  - Read an annotated tag object
  - List every object of a repository with its type and size
  - Walk from a commit to the bytes of one file with plumbing only
- **Prerequisites.** V099
- **Concepts.** Tree entries: mode, name, binary ID; modes for file, executable, symbolic link, directory and gitlink. A commit's ID covers its parents' IDs, so a change propagates to every descendant. `git cat-file` in batch mode is the scripting interface to the object store; `git ls-tree` reads trees; `git show` is porcelain over both.
- **Commands.** `git cat-file -p`; `git cat-file -s`; `git cat-file -e`; `git cat-file --batch-all-objects --batch-check`; `git ls-tree`; `git ls-tree -r`; `git ls-tree -l`; `git rev-list --objects --all`; `git show --no-patch --format=raw`
- **Demonstration.** Replay `labs/ch03/object-types.sh` (snippets `tree-modes`, `tree-raw`, `commit`, `commit-id`, `tag`, `encoding`) and `labs/ch03/read-objects.sh` (snippets `cat-file`, `batch-check`, `batch-all-objects`, `ls-tree`, `show`).
- **Diagrams.** Redraw the diagram of section 3.4.
- **Practical exercise.** Exercise 16.2 (Level 1, "From a commit to the bytes of a file") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Challenge.** Exercise 16.4 (Level 2, "Count the objects") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q72: "What does a commit ID commit you to? Explain why changing a commit message three commits back changes the ID of `HEAD`."
- **Homework.** Read sections 3.4 and 3.5.
- **Expected outcome.** The learner reads the object store with plumbing and explains why history is tamper-evident.

### V101: Turning names into IDs: git rev-parse

- **Title.** Turning names into IDs: git rev-parse
- **Learning objectives.** After this video the learner can:
  - Resolve any revision expression to an object ID and verify that it names a commit
  - Ask a repository for its directory, its top level and its formats from a script
  - Explain the order in which Git resolves an ambiguous short name
  - Say why a tool should store full IDs and not abbreviations
- **Prerequisites.** V064, V100
- **Concepts.** `git rev-parse` is the resolver behind every command that takes a revision. `--verify` for scripts. `--git-dir`, `--show-toplevel`, `--git-path`, `--show-object-format`, `--show-ref-format` answer questions about the repository without reading its files. Abbreviations are unique only today.
- **Commands.** `git rev-parse --verify`; `git rev-parse --short`; `git rev-parse --abbrev-ref`; `git rev-parse --symbolic-full-name`; `git rev-parse --git-dir`; `git rev-parse --git-path`; `git rev-parse --show-object-format --show-ref-format`
- **Demonstration.** Replay `labs/ch03/rev-parse.sh` (snippets `revisions`, `names`, `repository`, `errors`).
- **Diagrams.** Redraw the diagram of section 3.6; show the root-cause box of section 3.6.
- **Practical exercise.** Exercise 17.5 (Level 2, "What `git rev-parse` answers") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Challenge.** Exercise 16.8 (Level 3, "Scripts that read `.git` by hand") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q54: "Our deploy tool stores abbreviated IDs. What can go wrong, and what should it store?"
- **Homework.** Read section 3.6.
- **Expected outcome.** The learner writes scripts that ask Git for names and paths and never guess them.

### V102: Packfiles, pack indexes and delta compression

- **Title.** Packfiles, pack indexes and delta compression
- **Learning objectives.** After this video the learner can:
  - Explain how a pack stores many objects and why that does not change the snapshot model
  - Watch loose objects become a pack and count both
  - Read a `git verify-pack -v` listing and follow a delta chain to its base
  - Say which version of the lab's file is stored whole and how the listing shows it
  - Say what the pack index is for
- **Prerequisites.** V007, V100
- **Concepts.** A packfile holds many objects in one file; similar objects are stored as deltas against a base. A delta is a storage detail: every object still has its full content when read. Which objects are compared is a heuristic of `git pack-objects`. The `.idx` file maps IDs to offsets. `git gc` and maintenance create packs; new objects start loose.
- **Commands.** `git count-objects -v`; `git gc`; `git verify-pack -v`; `git show-index`; `git cat-file -p`
- **Demonstration.** Replay `labs/ch03/packfiles.sh` (snippets `loose`, `gc`, `verify-pack`, `snapshots-intact`, `loose-again`) and `labs/ch03/pack-anatomy.sh` (snippets `pack-file`, `pack-index`). Then the lab replays `labs/ch03/lab-16-1-loose-to-pack.sh` and `labs/ch03/lab-16-2-delta-chain.sh` up to their checkpoints.
- **Diagrams.** Redraw the diagram of section 3.7.
- **Practical exercise.** Lab 16.1 ("Watch loose objects become a pack") in [`lab-manual/m16-object-database.md`](../lab-manual/m16-object-database.md)
- **Challenge.** Lab 16.2 ("Read a pack listing and find a delta chain") in [`lab-manual/m16-object-database.md`](../lab-manual/m16-object-database.md)
- **Interview question.** Q77: "We have six versions of a 16 MB file. What does the pack contain, which version is stored whole, and what happens when a byte in that version is damaged?"
- **Homework.** Read section 3.7. Do Exercise 16.3 (Level 1, "Loose objects become a pack") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md).
- **Expected outcome.** The learner reconciles "Git stores snapshots" with "the repository is small" and can read a pack listing.

### V103: Reachability, git fsck, and where Git checks its hashes

- **Title.** Reachability, git fsck, and where Git checks its hashes
- **Learning objectives.** After this video the learner can:
  - Define reachable as Git's maintenance uses it and list the roots
  - Tell a dangling object from an unreachable one in `git fsck` output
  - Decide whether a `dangling commit` line means anything is at risk
  - Explain why a corrupt object can pass local commands and fail a clone
  - Explain the `git fsck` rule about future-dated reflog entries and the Git version it came with
- **Prerequisites.** V073, V102
- **Concepts.** The starting points of `git fsck` are the index, all refs, all reflogs, and HEAD. `git fsck` checks connectivity and object integrity. Most commands do not rehash what they read; transfer does. The reflog rule exists in Git 2.53.0 and later and is why the lab clock is in the past.
- **Commands.** `git fsck`; `git fsck --no-reflogs`; `git fsck --no-reflogs --unreachable`; `git hash-object`; `git clone --quiet --no-local`
- **Demonstration.** Replay `labs/ch03/fsck-reachability.sh` (snippets `healthy`, `dangling-blob`, `unreachable`, `reflog-still-holds-it`), `labs/ch03/object-integrity.sh` (snippets `tamper`, `detect`, `repair`) and `labs/ch03/fsck-reflog-clock.sh` (snippets `script`, `fsck`, `gc-keeps-it`).
- **Diagrams.** Redraw the diagram of section 3.8; show the root-cause box of section 3.8.
- **Practical exercise.** Exercise 16.7 (Level 3, "Which `git fsck` lines matter") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Challenge.** Exercise 16.9 (Level 4, "Removed from history, and still there") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q78: "`git fsck` says `dangling commit`. Walk me through what you check before you decide whether anything is at risk."
- **Homework.** Read section 3.8. Do Exercise 16.5 (Level 2, "What `git gc` does with unreachable objects") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md).
- **Expected outcome.** The learner reads `git fsck` output without alarm and knows what counts as a root.

### V104: What makes a repository slow, git gc versus git maintenance, geometric repacking, and cruft packs

- **Title.** What makes a repository slow, git gc versus git maintenance, geometric repacking, and cruft packs
- **Learning objectives.** After this video the learner can:
  - Name the dimensions along which a repository grows and the command that each slows
  - Say what runs when a commit triggers automatic maintenance on Git 2.55
  - Trace one maintenance run task by task
  - Explain geometric repacking with three packs of given sizes
  - Explain what a cruft pack holds and when unreachable objects are finally deleted
- **Prerequisites.** V103
- **Concepts.** Many commits, many refs, large trees, large blobs: different costs. `git maintenance` runs tasks; the geometric strategy is the default since Git 2.54 and repacks only when pack sizes fall out of a geometric progression. `git gc` does a full repack. Unreachable objects are collected into a cruft pack and expire later. The course never runs `git maintenance start`.
- **Commands.** `git count-objects -v`; `git maintenance run`; `git maintenance run --task=gc`; `git maintenance is-needed --auto`; `git gc --prune=now`; `git fsck --unreachable`; `git rev-list --count --all`; `git reflog expire --expire=now --all`
- **Demonstration.** Replay `labs/ch26/scale-dimensions.sh` (snippets `dimensions`, `largest`, `status-work`), `labs/ch26/maintenance-trace.sh` (snippets `trigger`, `needed`, `trace`, `after`, `second-run`, `progression`, `gc-task`, `incremental-tasks`) and `labs/ch26/cruft-packs.sh` (snippets `make-garbage`, `geometric-keeps`, `gc-cruft`, `prune`).
- **Diagrams.** New: three packs as bars of 500, 30 and 30 objects, and the bars after the next geometric run.
- **Practical exercise.** Lab 16.3 ("Trace what a maintenance run does") in [`lab-manual/m16-maintenance.md`](../lab-manual/m16-maintenance.md)
- **Challenge.** Exercise 16.6 (Level 2, "The largest blobs in history") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q82: "What does Git 2.55 run when a commit triggers automatic maintenance? How does that differ from `git gc`, and what does each delete?"
- **Homework.** Read sections 26.1 to 26.5.
- **Expected outcome.** The learner knows what Git does in the background after a commit and when unreachable work really disappears.

### V105: Refs in depth: loose refs, packed-refs, symbolic refs, root refs, and reflog storage

- **Title.** Refs in depth: loose refs, packed-refs, symbolic refs, root refs, and reflog storage
- **Learning objectives.** After this video the learner can:
  - Explain why a branch may have no file under `refs/heads/` and still exist
  - Create, update, verify and delete refs with plumbing, with a reflog message
  - Name the root refs and the pseudorefs and say which command writes each
  - Say which of them protect objects from garbage collection
  - Say where reflogs are stored and when a ref has none
- **Prerequisites.** V022, V103
- **Concepts.** Loose refs are files; `packed-refs` holds many in one file; a loose ref overrides a packed entry. A script that reads ref files breaks on packing and on reftable. `HEAD`, `ORIG_HEAD`, `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `REBASE_HEAD`, `FETCH_HEAD`: the glossary's use of "pseudoref" was narrowed in Git 2.46. Reflogs live under `logs/` in the files backend.
- **Commands.** `git for-each-ref`; `git pack-refs --all`; `git show-ref --verify`; `git show-ref --exists`; `git update-ref -m`; `git update-ref -d`; `git symbolic-ref`; `git symbolic-ref --short`; `git for-each-ref --include-root-refs`; `git reflog exists`
- **Demonstration.** Replay `labs/ch03/refs-storage.sh` (snippets `loose-refs`, `list`, `update-ref`, `symbolic-ref`, `reflog-files`, `packed-refs`) and `labs/ch03/root-refs.sh` (snippets `fetch-head`, `merge-head`, `root-refs`, `not-a-starting-point`). Then `labs/ch03/lab-17-3-special-refs-tour.sh` up to its checkpoint.
- **Diagrams.** Show the root-cause box of section 3.9. New: a ref lookup drawn as "loose file? else packed-refs line? else not found".
- **Practical exercise.** Lab 17.3 ("A tour of every special ref and file") in [`lab-manual/m17-index-refs-gitdir.md`](../lab-manual/m17-index-refs-gitdir.md)
- **Challenge.** Exercise 17.7 (Level 3, "A branch that Git ignores") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q81: "A release script reads `.git/refs/heads/main` and checks that the content is forty hexadecimal digits. It has worked for years and now fails in two repositories with two different errors. Explain both root causes at the storage level, and state the rule that prevents this class of failure."
- **Homework.** Read sections 3.9 to 3.11. Do Exercise 17.2 (Level 1, "Loose refs and packed refs") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md) and Exercise 17.3 (Level 1, "Refs by plumbing") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md).
- **Expected outcome.** The learner uses format-independent plumbing for refs and can name every special ref an operation leaves behind.

### V106: The index file as a data structure

- **Title.** The index file as a data structure
- **Learning objectives.** After this video the learner can:
  - List the fields of an index entry
  - Explain why every file shows as modified after a repository is copied, and repair it with one command
  - Read flags and stage numbers in `git ls-files --debug` and `--stage` output
  - Say what the index version changes
  - Create a commit without using the index
- **Prerequisites.** V018, V105
- **Concepts.** The index is a sorted list of entries with path, mode, object ID, stage, flags and cached file metadata, plus extensions. Git trusts the cached metadata to skip reading files; a copy changes the metadata and not the content. Index versions differ in path compression.
- **Commands.** `git ls-files --stage`; `git ls-files --debug`; `git ls-files --unmerged`; `git diff-files`; `git update-index --show-index-version`; `git update-index --index-version`; `git add --intent-to-add`
- **Demonstration.** Replay `labs/ch03/index-file.sh` (snippets `stage`, `read-index`, `stat-cache`, `copied-repository`, `flags`, `stages`, `resolve`, `version-4`) and `labs/ch03/index-debug.sh` (snippets `debug`). Then `labs/ch03/lab-17-1-index-structure.sh` up to its checkpoint; the companion script `labs/ch03/lab-17-1-index-stat-volatile.sh` is volatile and is not replayed on screen.
- **Diagrams.** New: the index drawn as a header, a table of entries with one row expanded into its fields, and a tail of extensions.
- **Practical exercise.** Lab 17.1 ("Read the index as a data structure") in [`lab-manual/m17-index-refs-gitdir.md`](../lab-manual/m17-index-refs-gitdir.md)
- **Challenge.** Exercise 17.8 (Level 3, "An edit that Git does not see") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q74: "Someone copied a repository with `cp -R` and now every file is "modified". Explain the mechanism and the one-command fix."
- **Homework.** Read section 3.12. Do Exercise 17.1 (Level 1, "The index as a table") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md), Exercise 17.4 (Level 2, "The index during a conflict") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md) and Exercise 17.6 (Level 2, "A commit without the index") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md).
- **Expected outcome.** The learner explains index anomalies from the entry format.

### V107: The reftable backend, and SHA-1 with collision detection versus SHA-256

- **Title.** The reftable backend, and SHA-1 with collision detection versus SHA-256
- **Learning objectives.** After this video the learner can:
  - Create a repository with the reftable backend and show what replaces the ref files
  - Show that ref plumbing gives the same answers in both backends
  - Say what breaks when tools read `.git/refs` directly
  - Create a SHA-256 repository and state why it cannot exchange objects with a SHA-1 repository
  - State what Git 3.0 plans for new repositories, as the section gives it
- **Prerequisites.** V105
- **Concepts.** Reftable stores refs and reflogs in binary tables with atomic updates; available since Git 2.45. `git rev-parse --show-ref-format`. Git's SHA-1 detects known collision attacks. SHA-256 repositories use 64-digit IDs and are a separate object format. The planned defaults for new repositories in Git 3.0.
- **Commands.** `git init --ref-format=reftable`; `git rev-parse --show-ref-format`; `git for-each-ref`; `git pack-refs --all`; `git init --object-format=sha256`; `git rev-parse --show-object-format`; `git version --build-options`
- **Demonstration.** Replay `labs/ch03/reftable.sh` (snippets `init`, `stubs`, `tables`, `same-answers`, `root-refs`, `names`, `git-3-preview`) and `labs/ch03/sha256.sh` (snippets `build`, `init`, `ids`, `no-interop`, `forty-hex`). Then `labs/ch03/lab-17-2-files-vs-reftable.sh` up to its checkpoint.
- **Diagrams.** New: two `.git` directory listings side by side, files backend and reftable, with the differing entries marked.
- **Practical exercise.** Lab 17.2 ("The `files` backend versus reftable") in [`lab-manual/m17-index-refs-gitdir.md`](../lab-manual/m17-index-refs-gitdir.md)
- **Challenge.** Exercise 16.8 (Level 3, "Scripts that read `.git` by hand") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q86: "When would you migrate a repository to reftable, what breaks if you do it carelessly, and what stays the same?"
- **Homework.** Read sections 3.13 to 3.17 and do the Practice section 3.19.
- **Expected outcome.** The learner is ready for repositories that are not in the format old scripts assume.

### V108: The commit-graph, the multi-pack-index, reachability bitmaps, and the working-tree accelerators

- **Title.** The commit-graph, the multi-pack-index, reachability bitmaps, and the working-tree accelerators
- **Learning objectives.** After this video the learner can:
  - Say which two kinds of data a commit-graph file holds and which commands each helps
  - Write a commit-graph and observe the effect on a history query
  - Explain what a stale commit-graph does and when Git ignores the file
  - Say what a multi-pack-index and a bitmap are for and why bitmaps are mainly a server feature
  - Name the two features that speed up `git status` in a large working tree
- **Prerequisites.** V104
- **Concepts.** The commit-graph stores parents, generation numbers and changed-path filters, so walks and path-limited logs avoid opening commits and trees. It is a cache: stale is slower, not wrong. The multi-pack-index indexes many packs at once. Bitmaps record what each commit reaches. The untracked cache and the file-system monitor reduce working-tree scanning; the daemon is not started in this course.
- **Commands.** `git commit-graph write`; `git commit-graph verify`; `git log --oneline --`; `git rev-list --count`; `git multi-pack-index write`; `git rev-list --count --objects --all`
- **Demonstration.** Replay `labs/ch26/commit-graph.sh` (snippets `without`, `write`, `with`, `stale-and-split`, `switched-off`) and `labs/ch26/midx-bitmaps.sh` (snippets `several-packs`, `midx`, `bitmap-on-server`, `what-a-bitmap-saves`). Use snippet `fsmonitor-off` of `labs/ch26/scale-dimensions.sh` for the working-tree part. The replays show counts of work, not seconds, because timings are not reproducible.
- **Diagrams.** New: a commit walk drawn twice: opening every commit object, and reading one commit-graph file.
- **Practical exercise.** Lab 16.4 ("Write and verify a commit-graph") in [`lab-manual/m16-maintenance.md`](../lab-manual/m16-maintenance.md)
- **Challenge.** Exercise 18.6 (Level 2, "History without content") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q84: "What two kinds of data does a commit-graph hold, and which commands does each help? What happens when the file is stale, and when it is damaged?"
- **Homework.** Read sections 26.6 to 26.9.
- **Expected outcome.** The learner can name the cache that serves each slow command and knows that none of them changes results.

### V109: The fetch conversation, shallow clones, partial clones, and choosing a clone

- **Title.** The fetch conversation, shallow clones, partial clones, and choosing a clone
- **Learning objectives.** After this video the learner can:
  - Describe a fetch as a conversation of wants and haves and say where `--depth` and `--filter` enter it
  - Say what a shallow, a blobless, a treeless and a single-branch clone each hold
  - Name the commands that give wrong or failing answers in a shallow clone
  - Explain on-demand fetching in a partial clone and what fails offline
  - Choose a clone shape for a developer, for CI and for a one-off build
- **Prerequisites.** V039, V108
- **Concepts.** The client says what it wants and what it has; the server sends a pack of the difference. Shallow cuts history at a depth: `describe`, `blame`, `merge-base` and counts are affected. Partial clone omits objects and fetches them from the promisor remote when a command needs them. `--single-branch` narrows the refspec.
- **Commands.** `git clone --depth`; `git clone --filter=blob:none`; `git clone --filter=tree:0`; `git clone --single-branch`; `git rev-parse --is-shallow-repository`; `git fetch --deepen`; `git fetch --unshallow`; `git rev-list --objects --all --missing=print`; `git backfill`; `git ls-remote`
- **Demonstration.** Replay `labs/ch26/fetch-conversation.sh` (snippets `capabilities`, `full-clone`, `shallow-and-partial`, `incremental`), `labs/ch26/shallow-limits.sh` (snippets `inside`, `wrong-answers`, `deepen`, `unshallow`), `labs/ch26/partial-clone.sh` (snippets `promisor`, `on-demand`, `one-by-one`, `backfill`, `consolidate`, `offline`) and `labs/ch26/clone-shapes.sh` (snippets `full`, `single-branch`, `shallow`, `blobless`, `treeless`, `filter-ignored`).
- **Diagrams.** Show the root-cause box of section 26.11. New: one history drawn four times with the objects each clone shape holds shaded.
- **Practical exercise.** Lab 18.1 ("Clone one repository three ways and compare what arrived") in [`lab-manual/m18-transfer-scale.md`](../lab-manual/m18-transfer-scale.md)
- **Challenge.** Exercise 18.7 (Level 3, "A merge base that is not there") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q448: "Compare shallow, blobless and treeless clones: what each holds, what each answers correctly, and what each costs later."
- **Homework.** Read sections 26.10 to 26.13. Do Exercise 18.1 (Level 1, "A shallow clone, and what it lacks") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md), Exercise 18.2 (Level 1, "A blobless clone fetches on demand") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md), Exercise 18.4 (Level 2, "A clone of depth 2") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md) and Exercise 18.5 (Level 2, "A single-branch clone") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md).
- **Expected outcome.** The learner picks a clone shape by the questions the clone must answer.

### V110: Bundles, and when each scale feature matters

- **Title.** Bundles, and when each scale feature matters
- **Learning objectives.** After this video the learner can:
  - Create a full and an incremental bundle and read a bundle's header
  - Explain what a prerequisite is and what happens when one shipment is lost
  - Clone from a bundle and continue from the network
  - Say for a repository of a given size which scale features are worth enabling
- **Prerequisites.** V079, V109
- **Concepts.** A bundle is a packfile with a list of refs and prerequisites. An incremental bundle applies only where its prerequisites exist. `--bundle-uri` seeds a clone. The table of section 26.15: most repositories need none of this; the features matter at specific sizes.
- **Commands.** `git bundle create`; `git bundle verify`; `git clone -q --bundle-uri`; `git fetch`
- **Demonstration.** Replay `labs/ch26/bundles.sh` (snippets `full-and-incremental`, `header`, `prerequisite`, `bundle-uri`). Then `labs/ch26/lab-18-3-bundle-round-trip.sh` up to its checkpoint.
- **Diagrams.** New: two sites with no network between them and a file carried across, with the prerequisite commit marked on both sides.
- **Practical exercise.** Lab 18.3 ("A bundle round trip") in [`lab-manual/m18-transfer-scale.md`](../lab-manual/m18-transfer-scale.md)
- **Challenge.** Exercise 18.9 (Level 4, "The clone that believes it is up to date") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q450: "How do you ship weekly updates to a site with no network route to the server? What goes wrong if one shipment is lost?"
- **Homework.** Read sections 26.14 to 26.18 and do the Practice section 26.20.
- **Expected outcome.** The learner moves history without a network and resists enabling scale features a repository does not need.

### V111: Monorepo versus polyrepo, and sparse-checkout in cone mode

- **Title.** Monorepo versus polyrepo, and sparse-checkout in cone mode
- **Learning objectives.** After this video the learner can:
  - State the trade-offs of one repository against many as the section lists them
  - Say what Git has to carry in a monorepo
  - Explain a cone-mode sparse checkout in terms of the index: what is on disk, in the index and in HEAD
  - Set, widen and disable a cone
  - Explain the label "experimental" that the documentation still carries
- **Prerequisites.** V018, V109
- **Concepts.** Monorepo and polyrepo are organizational choices with different costs. Sparse-checkout limits the working tree; the index and HEAD still describe the whole tree, so commits are complete. Cone mode selects directories. Files outside the cone carry the skip-worktree bit.
- **Commands.** `git sparse-checkout init --cone`; `git sparse-checkout set`; `git sparse-checkout add`; `git sparse-checkout list`; `git sparse-checkout disable`; `git ls-files -t`
- **Demonstration.** Replay `labs/ch24/sparse-cone.sh` (snippets `full`, `init`, `inside`, `set`, `patterns`, `add`, `disable`).
- **Diagrams.** Redraw the diagram of section 24.4.
- **Practical exercise.** Lab 18.2 ("Cone-mode sparse-checkout") in [`lab-manual/m18-transfer-scale.md`](../lab-manual/m18-transfer-scale.md)
- **Challenge.** Exercise 18.8 (Level 3, "A file that is not on disk") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q423: "Explain a cone-mode sparse checkout in terms of the index. What is on disk, in the index, in `HEAD`?"
- **Homework.** Read sections 24.1 to 24.4. Do Exercise 18.3 (Level 1, "Cone-mode sparse checkout") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md).
- **Expected outcome.** The learner works in part of a large repository and knows the commit still covers all of it.

### V112: Living in a sparse checkout, and the sparse index

- **Title.** Living in a sparse checkout, and the sparse index
- **Learning objectives.** After this video the learner can:
  - Predict what search, status and add do for paths outside the cone
  - Explain what happens to untracked and ignored files when a cone is narrowed
  - Clean leftovers after narrowing a cone, with a dry run first
  - Say what the sparse index changes, why only in cone mode, and what makes a command expand it
- **Prerequisites.** V111
- **Concepts.** Commands that read the working tree see only the cone; commands that read the index or history see everything. `git grep` needs `--cached` to search outside. Narrowing a cone removes tracked files; a directory that still holds untracked files is left in place with a warning, and ignored files are lost. The sparse index stores one tree entry for a directory outside the cone.
- **Commands.** `git grep -l`; `git grep -l --cached`; `git add --sparse`; `git sparse-checkout reapply`; `git sparse-checkout clean --dry-run`; `git sparse-checkout clean -f`; `git sparse-checkout set --sparse-index`; `git ls-files --sparse`
- **Demonstration.** Replay `labs/ch24/sparse-behaviour.sh` (snippets `reads`, `status-work`, `add-outside`, `add-sparse`, `untracked-blocks`, `clean`, `ignored-lost`) and `labs/ch24/sparse-index.sh` (snippets `full-index`, `enable`, `entries`, `same-tree`, `counted`, `expand`, `back`).
- **Diagrams.** Show the root-cause box of section 24.5. New: an index with thousands of entries collapsing into a few tree entries.
- **Practical exercise.** Exercise 18.8 (Level 3, "A file that is not on disk") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Challenge.** Exercise 18.9 (Level 4, "The clone that believes it is up to date") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q431: "What happens to untracked and to ignored files when a cone is narrowed?"
- **Homework.** Read sections 24.5 and 24.6.
- **Expected outcome.** The learner explains the surprises of a sparse checkout from "the working tree is partial, the index is not".

### V113: Partial clone plus sparse-checkout, what scalar clone configures, and ownership, CI and releases in a monorepo

- **Title.** Partial clone plus sparse-checkout, what scalar clone configures, and ownership, CI and releases in a monorepo
- **Learning objectives.** After this video the learner can:
  - Combine a blobless clone with a cone and say what is fetched when
  - List what `scalar clone` sets up and which parts live outside the repository
  - Compute affected projects correctly and explain why the naive form fails in shallow and partial CI clones
  - Tag and describe releases of several projects in one repository
  - Say how CODEOWNERS is used at this scale, as a pointer to Part 5
- **Prerequisites.** V080, V112
- **Concepts.** Blobless plus cone fetches blobs only for the cone. `scalar clone` is a preset of clone options, configuration and background maintenance; the lab builds the same clone by hand and registers nothing. Affected projects come from a three-dot diff against the base, which needs the merge base to be present. Project-prefixed tags and `git describe --match`.
- **Commands.** `git clone --filter=blob:none --sparse`; `git sparse-checkout set`; `git backfill --sparse`; `git maintenance run --task=prefetch --task=commit-graph`; `git diff --name-only`; `git merge-base`; `git describe --match`; `git tag -l`
- **Demonstration.** Replay `labs/ch24/sparse-partial.sh` (snippets `clone`, `config`, `widen`, `history-in-cone`, `settings`, `maintenance`), `labs/ch24/affected-projects.sh` (snippets `three-dot`, `shallow-ci`, `blobless-ci`) and `labs/ch24/project-tags.sh` (snippets `tags`, `describe`, `changelog`). Then `labs/ch24/lab-18-4-scalar-by-hand.sh` up to its checkpoint.
- **Diagrams.** Show the root-cause box of section 24.9. New: a monorepo tree with three projects, a change in one, and the set of jobs that must run.
- **Practical exercise.** Lab 18.4 ("The clone that `scalar clone` builds, made by hand") in [`lab-manual/m18-transfer-scale.md`](../lab-manual/m18-transfer-scale.md)
- **Challenge.** Exercise 18.9 (Level 4, "The clone that believes it is up to date") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md)
- **Interview question.** Q446: "Our CI computes affected projects with `git diff main..HEAD`. What is wrong, and why does the fix fail in a shallow clone?"
- **Homework.** Read sections 24.7 to 24.14 and do the Practice section 24.16.
- **Expected outcome.** The learner can onboard an engineer to a large repository and write CI that selects work correctly.

### V114: Gate briefing: Internals

- **Title.** Gate briefing: Internals
- **Learning objectives.** After this video the learner can:
  - State what Gate 5 covers and its threshold of 85
  - Prepare by explaining each storage structure as "what it stores, what reads it, what happens when it is stale or missing"
  - Run the hands-on part with plumbing that works in every format
  - Explain maintenance and reachability under questioning
- **Prerequisites.** V107, V110, V113
- **Concepts.** Gate 5 covers the object database, packfiles, the index format, ref storage, transfer and scale. The questions ask for mechanisms: which file, which reader, which failure. Reading `.git/refs` by hand in the hands-on part is the typical mistake.
- **Commands.** `git cat-file --batch-all-objects --batch-check`; `git for-each-ref`; `git count-objects -v`; `git fsck`
- **Demonstration.** Replay `labs/ch03/packfiles.sh` (snippets `loose`, `gc`, `verify-pack`, `snapshots-intact`) as the warm-up. Show the gate rules from [`assessments/README.md`](../assessments/README.md). Do not open the gate file on screen.
- **Diagrams.** New: one slide with five boxes (objects, packs, refs, index, caches) and under each the plumbing command that reads it.
- **Practical exercise.** Redo Exercise 16.9 (Level 4, "Removed from history, and still there") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md), Exercise 17.9 (Level 4, ""Not a git repository"") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md) and Exercise 18.9 (Level 4, "The clone that believes it is up to date") in [`exercises/m16-m18-internals.md`](../exercises/m16-m18-internals.md), the Level 4 exercises of Modules 16 to 18.
- **Challenge.** Take Gate 5: [`assessments/gate-5-internals.md`](../assessments/gate-5-internals.md).
- **Interview question.** Q65: "How does Git store data?"
- **Homework.** Before the gate: answer the "Interview questions" sections of Chapters 3, 24 and 26 aloud.
- **Expected outcome.** The learner sits Gate 5 able to explain how Git stores, packs, transfers and maintains data.

## Part 5: GitHub

Roadmap Level 5 (Modules 19 to 25), then the GitHub gate. 27 videos on the platform: what is Git data and what is a GitHub object, authentication, pull requests, merge methods, rulesets, CODEOWNERS, signing and the command-line interface. Local scripts show the Git side of every mechanism; the GitHub side is a screen walkthrough of the learner's own practice repository.

### V115: Git data and GitHub objects, accounts, roles, and the settings that matter

- **Title.** Git data and GitHub objects, accounts, roles, and the settings that matter
- **Learning objectives.** After this video the learner can:
  - Decide for any item on a repository page whether it is Git data or a GitHub object, and prove it from a clone
  - Say what a mirror clone carries and what it leaves on the platform
  - Distinguish personal accounts, organizations and enterprise accounts
  - Compute a member's effective access from base permission, team roles and direct grants
  - Name the repository settings the section singles out and what each changes
- **Prerequisites.** V002, V038, V114
- **Concepts.** Git data: commits, trees, blobs, tags, branches. GitHub objects: pull requests, issues, reviews, rules, releases, permissions. Files such as templates and CODEOWNERS are Git data that the platform interprets. Five repository roles; the highest grant wins. Visibility. GitHub, not Git, for everything on the settings pages.
- **Commands.** `git clone --mirror`; `git for-each-ref`; `git ls-files`; `git log --all --oneline --grep`; `gh repo view`
- **Demonstration.** Replay `labs/ch15/git-vs-github.sh` (snippets `clone`, `platform-files`, `message`, `mirror`) and the lab replay `labs/ch15/lab-19-2-inventory.sh`. Then: Screen walkthrough of the learner's own practice repository, following Lab 19.2 ("An inventory of Git data and GitHub objects") in [`lab-manual/m19-github-platform.md`](../lab-manual/m19-github-platform.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors. Walk the repository page from top to bottom and sort each element into one of the two columns.
- **Diagrams.** Redraw the diagram of section 15.2 and the diagram of section 15.4.
- **Practical exercise.** Lab 19.2 ("An inventory of Git data and GitHub objects") in [`lab-manual/m19-github-platform.md`](../lab-manual/m19-github-platform.md)
- **Challenge.** Exercise 19.3 (Level 2, "Effective access") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q219: "Take ten things on a repository's page on GitHub. For each, is it Git data or a GitHub object, and how do you prove it from a terminal?"
- **Homework.** Read sections 15.1 to 15.5. Do Exercise 19.1 (Level 1, "Git data or GitHub object?") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md) and Exercise 19.2 (Level 1, "Settings on purpose") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md). Return to the five-item list from V002 and prove each entry.
- **Expected outcome.** The learner knows during an incident which facts a clone can prove and which only the platform holds.

### V116: Forks and the fork network

- **Title.** Forks and the fork network
- **Learning objectives.** After this video the learner can:
  - Describe a fork as a separate repository that shares object storage with its network
  - Show locally that a commit pushed to a fork can be reached by ID through the upstream
  - Say what deleting a fork or a branch does and does not remove
  - Explain what stars and watchers are and are not evidence of
- **Prerequisites.** V043, V115
- **Concepts.** A fork has its own refs and permissions; the network shares Git data, which is documented behavior. A commit pushed anywhere in the network can remain addressable by its ID after the branch or fork is gone. The security consequence for leaked credentials and for deleted work.
- **Commands.** `git clone`; `git push`; `git ls-remote`; `git branch -a`; `git add -f`
- **Demonstration.** Replay `labs/ch15/fork-network.sh` (snippets `upstream`, `fork`, `clone-fork`, `push-to-fork`, `two-views`, `by-id-through-upstream`, `delete-fork`, `prune`); the script models the shared storage with local repositories. Then: Screen walkthrough of the learner's own practice repository, following Lab 21.1 ("A full fork and pull request cycle") in [`lab-manual/m21-pull-requests-forks.md`](../lab-manual/m21-pull-requests-forks.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, only the step that creates the fork, to show where the fork relation is displayed.
- **Diagrams.** Redraw the diagram of section 15.7.
- **Practical exercise.** Exercise 19.4 (Level 2, "What a clone receives, and where a keyword travels") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Challenge.** Exercise 19.5 (Level 3, "The fork that was deleted") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q241: "A commit with a credential was pushed to a fork of your public repository, and the fork was deleted. What is still true, what does GitHub document, and what do you do first?"
- **Homework.** Read sections 15.6 and 15.7.
- **Expected outcome.** The learner never treats "the fork was deleted" as "the commit is gone".

### V117: Issues, Projects, Discussions, Packages, templates, health files, a professional layout, and limits

- **Title.** Issues, Projects, Discussions, Packages, templates, health files, a professional layout, and limits
- **Learning objectives.** After this video the learner can:
  - Explain how a closing keyword links a commit or pull request to an issue and three reasons it does not close one
  - Say what Projects, Discussions, wikis and Packages are for, as the sections describe them
  - Create issue forms, a pull request template and the community health files
  - Justify each file of the professional repository layout
  - State the repository limits the section lists and find the commit that added a large file
- **Prerequisites.** V115
- **Concepts.** Issues with sub-issues and issue types, labels, milestones. The keyword is text in Git data; the closing is a platform action with conditions. Templates and health files are tracked files in fixed locations. The layout of section 15.14, file by file. Size limits from section 15.15. Organization governance in brief.
- **Commands.** `git ls-files`; `git check-ignore -v`; `git rev-list --objects --all`; `git log --oneline --diff-filter=A --`; `gh issue`
- **Demonstration.** Replay `labs/ch15/repo-layout.sh` (snippets `tracked-files`, `issue-form`, `chooser-and-pr-template`, `ignored-secret`, `tests`) and `labs/ch15/large-objects.sh` (snippets `gone`, `still-in-history`, `which-commit`). Then: Screen walkthrough of the learner's own practice repository, following Lab 19.1 ("The practice organization and a repository with health files") in [`lab-manual/m19-github-platform.md`](../lab-manual/m19-github-platform.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors. Show the issue chooser and the pull request template taking effect after the push.
- **Diagrams.** New: the repository tree of section 15.14 with one line of purpose beside each file.
- **Practical exercise.** Lab 19.1 ("The practice organization and a repository with health files") in [`lab-manual/m19-github-platform.md`](../lab-manual/m19-github-platform.md)
- **Challenge.** Exercise 19.7 (Level 5, ""We made it private, so we are fine"") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q228: "A pull request said "Fixes #812" and the issue is still open after the merge. Give three causes and how to tell them apart."
- **Homework.** Read sections 15.8 to 15.11, 15.13 to 15.15 and 15.19. Do Exercise 19.6 (Level 2, "Health files and the issue chooser") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md).
- **Expected outcome.** The learner has a practice organization and a practice repository that later GitHub videos use.

### V118: Authentication versus authorization, HTTPS, and how Git asks for a credential

- **Title.** Authentication versus authorization, HTTPS, and how Git asks for a credential
- **Learning objectives.** After this video the learner can:
  - Separate "who are you" from "what may you do" in an error message
  - Describe what Git does from the server's 401 to the stored token, naming the helper operations
  - Find out which credential helper answers for a host and where the token lives
  - Scope a helper to one host or one path
  - Read a credential trace
- **Prerequisites.** V027, V115
- **Concepts.** Authentication proves identity; authorization decides access; "Repository not found" can be either. Over HTTPS the secret is a token. Git asks helpers in order with `get`, and tells them `store` or `erase` afterwards. The helper is configuration, often in the system file, which is why the lab shell cannot authenticate to GitHub.
- **Commands.** `git config get --show-origin --all credential.helper`; `git credential fill`; `git credential approve`; `git credential reject`; `GIT_TRACE=1`; `gh auth status`; `gh auth login`; `gh auth setup-git`
- **Demonstration.** Replay `labs/ch16/credential-protocol.sh` (snippets `no-helper`, `askpass`, `helper-source`, `configure`, `approve`, `fill`, `trace`, `reject`, `log`) and `labs/ch16/credential-scope.sh` (snippets `list`, `per-host`, `one-command`, `username-and-path`); the scripts use a stand-in helper and no real credential. Then: Screen walkthrough of the learner's own practice repository, following Lab 20.2 ("HTTPS through the GitHub CLI, and the helper behind it") in [`lab-manual/m20-authentication-ssh.md`](../lab-manual/m20-authentication-ssh.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, in the normal shell and not in `labs/shell`. Never show a token.
- **Diagrams.** New: a sequence diagram Git -> server (401) -> helper `get` -> server -> helper `store`.
- **Practical exercise.** Lab 20.2 ("HTTPS through the GitHub CLI, and the helper behind it") in [`lab-manual/m20-authentication-ssh.md`](../lab-manual/m20-authentication-ssh.md)
- **Challenge.** Exercise 20.3 (Level 3, "403, and Git never asks") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q244: "Describe what Git does, step by step, from "the server answers 401" to "the token is stored", naming the helper operations. What happens differently on a 403, and what is the consequence?"
- **Homework.** Read sections 16.1 to 16.5. Do Exercise 20.1 (Level 1, "Who wrote this line?") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md).
- **Expected outcome.** The learner can say which program supplied a credential and from which configuration line.

### V119: Tokens: fine-grained, classic, what a prefix tells you, and why a token never goes into a URL

- **Title.** Tokens: fine-grained, classic, what a prefix tells you, and why a token never goes into a URL
- **Learning objectives.** After this video the learner can:
  - Compare fine-grained and classic tokens by scope and lifetime, as the section gives them
  - Say when a documented gap forces a classic token
  - Name the places a token in a remote URL ends up
  - Find and repair a remote URL that contains a credential
- **Prerequisites.** V118
- **Concepts.** Token kinds and what their prefixes identify. Least privilege and expiry. A token written into a URL is stored in the repository configuration, shown by `git remote -v`, copied with the directory and printed in logs. The repair is to remove it from the URL and revoke the token.
- **Commands.** `git remote -v`; `git remote set-url`; `git config list --show-scope`
- **Demonstration.** Replay `labs/ch16/token-in-url.sh` (snippets `stored`, `git-reads-it`, `refuse`, `repair`); the token in the script is a made-up string. No GitHub walkthrough: token pages must not be recorded.
- **Diagrams.** Show the root-cause box of section 16.7.
- **Practical exercise.** Exercise 20.2 (Level 2, "Pick the credential") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Challenge.** Exercise 20.7 (Level 5, "The nightly sync says "not found"") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q310: "Why must a token never be written into a remote URL? Name four places where it then appears, and the Git setting that refuses such URLs."
- **Homework.** Read sections 16.6 and 16.7.
- **Expected outcome.** The learner issues the narrowest token that works and never embeds one in a URL.

### V120: SSH: key pairs, the agent, ~/.ssh/config, host keys, and testing the connection

- **Title.** SSH: key pairs, the agent, ~/.ssh/config, host keys, and testing the connection
- **Learning objectives.** After this video the learner can:
  - Generate a key pair and say what each half is for and where it goes
  - Explain what the agent holds and what the passphrase protects
  - Write a `~/.ssh/config` entry with a host alias and show what SSH resolves it to
  - Verify GitHub's host key against the published fingerprints and handle a changed key
  - Test the connection and use SSH over port 443
- **Prerequisites.** V118
- **Concepts.** SSH proves possession of a private key; nothing secret travels. The agent keeps decrypted keys in memory. `ssh -G` prints the effective configuration for a host. `known_hosts` pins the server's identity; a mismatch is either a published key rotation or an attack, and the published fingerprints decide. Git runs `ssh` and can be told which command to run.
- **Commands.** `ssh-keygen -t`; `ssh-keygen -l -f`; `ssh-keygen -y -f`; `ssh -G`; `ssh -T`; `ssh-keygen -R`; `ssh-keygen -l -F`; `gh ssh-key add`; `GIT_SSH_COMMAND`
- **Demonstration.** Replay `labs/ch16/ssh-keys.sh` (snippets `generate`, `public-half`, `private-half`, `passphrase`), `labs/ch16/ssh-config.sh` (snippets `config`, `github`, `alias`, `port-443`, `user-in-url`, `order`, `what-git-runs`) and `labs/ch16/known-hosts.sh` (snippets `published-lines`, `fingerprints`, `find`, `stale`, `remove`); keys are generated inside the sandbox and the replays never reach an agent or the network. Then: Screen walkthrough of the learner's own practice repository, following Lab 20.1 ("SSH setup and verification") in [`lab-manual/m20-authentication-ssh.md`](../lab-manual/m20-authentication-ssh.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, in the normal shell.
- **Diagrams.** New: client and server with the private key staying on the left, the public key registered on the right, and a signed challenge crossing.
- **Practical exercise.** Lab 20.1 ("SSH setup and verification") in [`lab-manual/m20-authentication-ssh.md`](../lab-manual/m20-authentication-ssh.md)
- **Challenge.** Exercise 20.4 (Level 3, "`Permission denied (publickey)`") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q233: "`ssh` reports that GitHub's host key has changed. What are the two explanations, how do you decide between them, and what do you never do?"
- **Homework.** Read sections 16.8 to 16.12.
- **Expected outcome.** The learner sets up SSH access knowing what each file does and verifies a host key instead of accepting it.

### V121: Two identities on one machine, credentials for machines, single sign-on, and the SSH changes of 14 October 2026 and 13 January 2027

- **Title.** Two identities on one machine, credentials for machines, single sign-on, and the SSH changes of 14 October 2026 and 13 January 2027
- **Learning objectives.** After this video the learner can:
  - Configure a personal and a work identity so that each repository uses the right key and the right commit address
  - Prove from a repository which identity a push will use
  - Choose between a deploy key, a GitHub App and an OAuth app for a machine, as the section compares them
  - Say what single sign-on authorization and mandatory two-factor authentication add
  - State what changes for SSH users on the two dates and who is affected
- **Prerequisites.** V028, V120
- **Concepts.** Three identities must agree: the commit identity, the authenticating key or token, and the account. Host aliases select the key; `includeIf` selects the address. Machine credentials and their scope. The dated SSH changes are quoted from section 16.16 and re-verified on the day of recording.
- **Commands.** `git config get --show-origin`; `git remote get-url`; `git ls-remote`
- **Demonstration.** Replay `labs/ch16/two-identities.sh` (snippets `global`, `personal`, `work`, `ssh-side`, `commit-identity`) and the lab replay `labs/ch16/lab-20-4-two-identities.sh`. No GitHub walkthrough is required; the optional lab is done in the normal shell.
- **Diagrams.** New: a table with rows "personal" and "work" and columns "host alias", "key", "commit address", "where configured".
- **Practical exercise.** Lab 20.4 ("Two identities on one machine (optional)") in [`lab-manual/m20-authentication-ssh.md`](../lab-manual/m20-authentication-ssh.md)
- **Challenge.** Exercise 20.5 (Level 3, "The push works, the address is wrong") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q246: "A developer has a personal and a work GitHub account on one laptop. Design the setup, and say how you would prove from the terminal which account a given repository will use."
- **Homework.** Read sections 16.13 to 16.16. Do Exercise 20.8 (Level 2, "The SSH calendar") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md).
- **Expected outcome.** The learner runs two accounts on one laptop without cross-contamination and knows the dated changes that affect SSH.

### V122: Diagnosing authentication failures: who wrote this line, the SSH failures, the HTTPS failures, and a decision tree

- **Title.** Diagnosing authentication failures: who wrote this line, the SSH failures, the HTTPS failures, and a decision tree
- **Learning objectives.** After this video the learner can:
  - Say for an error line whether Git, SSH, the helper or GitHub wrote it
  - Tell `Permission denied (publickey)` from `Permission to OWNER/REPO denied to USER` and say what has been proved in each case
  - Diagnose `Repository not found`, `Host key verification failed`, and `Could not read from remote repository`
  - Diagnose a 403 where Git never asks for a credential
  - Walk the decision tree from the error text to the root cause
- **Prerequisites.** V119, V121
- **Concepts.** The first step is attribution: which program printed the message. SSH failures: no key offered, wrong key, wrong account, host key. HTTPS failures: no credential, wrong credential, right credential without access, single sign-on not authorized. "Not found" hides existence from callers without access.
- **Commands.** `ssh -T`; `ssh -v`; `git ls-remote`; `GIT_TRACE=1`; `git remote -v`; `gh auth status`
- **Demonstration.** Replay `labs/ch16/failure-anatomy.sh` (snippets `no-ssh-agent`, `refused`, `standin`, `silent`, `local-path`, `no-program`) and the lab replay `labs/ch16/lab-20-3-failures.sh`; the scripts reproduce the failures against local stand-ins. Then: Screen walkthrough of the learner's own practice repository, following Lab 20.3 ("Three failures, reproduced and diagnosed") in [`lab-manual/m20-authentication-ssh.md`](../lab-manual/m20-authentication-ssh.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, in the normal shell, reproducing each failure against the learner's own practice repository.
- **Diagrams.** Redraw the diagram of section 16.20: the decision tree. Show the root-cause box of section 16.17 and the root-cause box of section 16.19.
- **Practical exercise.** Lab 20.3 ("Three failures, reproduced and diagnosed") in [`lab-manual/m20-authentication-ssh.md`](../lab-manual/m20-authentication-ssh.md)
- **Challenge.** Exercise 20.6 (Level 4, "Three faults, no connection") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q232: "What is the difference between `Permission denied (publickey)` and `Permission to OWNER/REPO denied to USER`? What has the server established in each case?"
- **Homework.** Read sections 16.17 to 16.23 and do the Practice section 16.25.
- **Expected outcome.** The learner goes from an authentication error to its cause in a fixed order and without copying commands.

### V123: What GitHub creates when a pull request opens, and what a pull request shows

- **Title.** What GitHub creates when a pull request opens, and what a pull request shows
- **Learning objectives.** After this video the learner can:
  - List what GitHub creates when a pull request is opened and which parts are Git data
  - Fetch a pull request's head with plain Git
  - Explain the test merge commit, when it is regenerated and what it means when it is absent
  - Explain why the commit list is a two-dot range and the diff a three-dot comparison
  - Construct a case where the two differ and say how merging the base into the branch changes each
- **Prerequisites.** V037, V064, V115
- **Concepts.** A pull request is a GitHub object over two refs. GitHub keeps `refs/pull/<n>/head` and, when the merge is clean, a test merge ref in the base repository; the regeneration rules date from 19 February 2026 as the section states. The pull request cannot be pushed to through those refs. Commits: `base..head`. Files changed: `base...head`.
- **Commands.** `git ls-remote`; `git fetch origin`; `git merge-tree --write-tree`; `git merge-base`; `git diff --stat`; `git log --oneline --graph`; `git rev-list --count`
- **Demonstration.** Replay `labs/ch17/pr-refs.sh` (snippets `server-opens-pr`, `client-sees`, `fetch-head`, `read-only`, `test-merge`, `neither-branch-moved`, `ci-checks-out-merge`, `stale-merge-ref`, `conflict-no-merge-ref`, `head-outlives-branch`) and `labs/ch17/pr-anatomy.sh` (snippets `two-branches`, `commit-list`, `merge-base`, `three-dot`, `two-dot`, `equivalence`, `merge-main-in`); a local bare repository plays the server. Then: Screen walkthrough of the learner's own practice repository, following Lab 21.1 ("A full fork and pull request cycle") in [`lab-manual/m21-pull-requests-forks.md`](../lab-manual/m21-pull-requests-forks.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** Redraw the diagram of section 17.2 and the diagram of section 17.3.
- **Practical exercise.** Lab 21.1 ("A full fork and pull request cycle") in [`lab-manual/m21-pull-requests-forks.md`](../lab-manual/m21-pull-requests-forks.md)
- **Challenge.** Exercise 21.4 (Level 3, "Three small mysteries") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q262: "What exactly does GitHub create when a pull request is opened? Which parts are Git data, and in which repository do they live?"
- **Homework.** Read sections 17.1 to 17.3. Do Exercise 21.1 (Level 1, "A draft, a range, and the head ref") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md).
- **Expected outcome.** The learner can reproduce everything a pull request page shows with Git commands.

### V124: The pull request lifecycle: draft, review, stale approvals, checks, mergeability, and conflicts

- **Title.** The pull request lifecycle: draft, review, stale approvals, checks, mergeability, and conflicts
- **Learning objectives.** After this video the learner can:
  - Describe the states of a pull request from draft to merged or closed
  - Explain what a push does to an existing approval under each of the two settings
  - Tell checks from status checks and say what "mergeable" takes into account
  - Resolve a pull request conflict by merging the base in or by rebasing, and say what each does to the review
  - Show that both resolutions produce the same diff
- **Prerequisites.** V123
- **Concepts.** Draft, ready, review requested, approved, changes requested, merged, closed. "Dismiss stale approvals" and "approval of the most recent reviewable push" answer different attacks. Mergeability combines conflicts, required checks and rules. A conflict is resolved in the branch; rebasing rewrites what reviewers saw.
- **Commands.** `git merge-tree --write-tree --name-only`; `git merge`; `git rebase`; `git rebase --continue`; `git push --force-with-lease`; `gh pr ready`; `gh pr review`; `gh pr checks`
- **Demonstration.** Replay `labs/ch17/pr-conflict.sh` (snippets `conflict`, `merge-base-in`, `after-merge`, `rebase`, `after-rebase`, `same-diff`). Then: Screen walkthrough of the learner's own practice repository, following Lab 21.1 ("A full fork and pull request cycle") in [`lab-manual/m21-pull-requests-forks.md`](../lab-manual/m21-pull-requests-forks.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, the review part, with a second account or a teammate. Show the timeline of the pull request after a push that follows an approval.
- **Diagrams.** New: the lifecycle as a state diagram with the event that causes each transition.
- **Practical exercise.** Exercise 21.2 (Level 2, "Is it still approved?") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Challenge.** Exercise 21.7 (Level 5, "Green on the pull request, red on main") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q270: "A reviewer approved, the author pushed another commit, and the pull request merged. Which two settings address this, and what does each cost?"
- **Homework.** Read sections 17.4 to 17.7.
- **Expected outcome.** The learner can say what an approval covers at any moment in a pull request's life.

### V125: Why a pull request shows unexpected commits or a huge diff

- **Title.** Why a pull request shows unexpected commits or a huge diff
- **Learning objectives.** After this video the learner can:
  - Give the documented causes of a pull request with many unrelated commits or files
  - Diagnose a pull request opened against the wrong base and fix it by changing the base or by transplanting the branch
  - Explain why a branch reused after a squash merge lists its old commits again and may conflict
  - Repair the reused branch with `git rebase --onto`
  - Name the Git command that tests each cause
- **Prerequisites.** V036, V054, V124
- **Concepts.** The page shows `base..head` and `base...head`: every surprise is a surprise about one of the two endpoints or the merge base. Wrong base branch. Branch created from another feature branch. Squash merge followed by reuse: the base has the content and not the commits. A rewritten base.
- **Commands.** `git log --oneline --graph`; `git merge-base`; `git diff --stat`; `git rebase --onto`; `git push --force-with-lease`; `git merge-tree --write-tree --name-only`; `gh pr edit`
- **Demonstration.** Replay `labs/ch17/wrong-base.sh` (snippets `situation`, `pr-against-release`, `diagnose`, `fix-a-change-base`, `fix-b-transplant`, `republish`) and `labs/ch17/squash-reuse.sh` (snippets `after-squash`, `keep-working`, `pr2-commits`, `pr2-test-merge`, `why`, `fix-rebase-onto`, `plain-rebase`, `merge-main`, `prevention`). Then: Screen walkthrough of the learner's own practice repository, following Lab 21.2 ("A pull request against the wrong base") in [`lab-manual/m21-pull-requests-forks.md`](../lab-manual/m21-pull-requests-forks.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** Show the root-cause box of section 17.12. New: the squash-then-reuse graph with the squash commit on `main` and the old commits still under the branch.
- **Practical exercise.** Lab 21.2 ("A pull request against the wrong base") in [`lab-manual/m21-pull-requests-forks.md`](../lab-manual/m21-pull-requests-forks.md)
- **Challenge.** Lab 21.3 ("The squash-then-reuse problem") in [`lab-manual/m21-pull-requests-forks.md`](../lab-manual/m21-pull-requests-forks.md)
- **Interview question.** Q263: "Why can a pull request show unexpected commits?"
- **Homework.** Read section 17.12. Do Exercise 21.6 (Level 4, "Five commits for a two-commit fix") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md).
- **Expected outcome.** The learner explains any surprising pull request from two endpoints and a merge base, and fixes it without closing it.

### V126: Indirect merges and stacked pull requests

- **Title.** Indirect merges and stacked pull requests
- **Learning objectives.** After this video the learner can:
  - Explain how a pull request can show as merged although nobody pressed merge on it
  - Build a stack of two pull requests and say what each one's base decides
  - Restack after a review fix in the lower layer
  - Predict the state of the upper pull request when the lower one is squash-merged and its branch deleted, and repair it
  - State the status of GitHub's stacked pull requests feature as the section gives it
- **Prerequisites.** V056, V125
- **Concepts.** A pull request is marked merged when its head commit becomes reachable from the base, however it got there. In a stack, each pull request's base is the branch below. A squash of the bottom layer breaks ancestry for the layers above. Stacked pull requests on GitHub are in public preview since 30 July 2026, as the section states.
- **Commands.** `git rebase --onto`; `git rebase`; `git push -q --force-with-lease`; `git merge-base --is-ancestor`; `git log --oneline --graph`
- **Demonstration.** Replay `labs/ch17/stacked.sh` (snippets `stack`, `base-decides`, `linear`, `review-fix-below`, `restack`, `bottom-squashed`, `restack-on-main`, `indirect-merge`). GitHub side: describe from section 17.14 only; the preview interface is not walked through.
- **Diagrams.** New: a two-layer stack before and after the bottom layer is squash-merged, with the upper pull request's base and merge base marked.
- **Practical exercise.** Exercise 21.3 (Level 2, "A stack, and a squash underneath it") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Challenge.** Exercise 21.6 (Level 4, "Five commits for a two-commit fix") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q277: "The bottom pull request of a two-layer stack is squash-merged and its branch is deleted. What state is the upper pull request in, what does GitHub do by itself, and would you let a release process depend on stacked pull requests?"
- **Homework.** Read sections 17.13 and 17.14.
- **Expected outcome.** The learner can run a small stack by hand and knows what a squash does to it.

### V127: The fork workflow end to end, review practice, and display limits

- **Title.** The fork workflow end to end, review practice, and display limits
- **Learning objectives.** After this video the learner can:
  - Name the three repositories of the fork workflow and the remotes in the contributor's clone
  - Take a change from upstream to fork to branch to pull request and back
  - Fetch and check out a contributor's pull request as a maintainer, and push to it when allowed
  - Keep the fork's default branch in sync without merge commits
  - Apply the review practices of section 17.17 to a pull request
- **Prerequisites.** V043, V116, V126
- **Concepts.** Upstream, fork, clone. Branch from `upstream/main`, push to `origin`, open the pull request against upstream. Maintainers reach the head through the pull request ref. Syncing is a fast-forward of the fork's `main`. Review practice: size, description, what the reviewer checks. Display limits of large pull requests.
- **Commands.** `git remote -v`; `git fetch upstream`; `git switch -c`; `git push -u`; `git merge --ff-only`; `git rev-list --left-right --count`; `gh pr checkout`; `gh repo sync`
- **Demonstration.** Replay `labs/ch17/fork-workflow.sh` (snippets `remotes`, `branch-from-upstream`, `pr-ref-upstream`, `maintainer-checks-out`, `maintainer-edits`, `you-pull`, `merge`, `sync`, `clean-up`). Then: Screen walkthrough of the learner's own practice repository, following Lab 21.1 ("A full fork and pull request cycle") in [`lab-manual/m21-pull-requests-forks.md`](../lab-manual/m21-pull-requests-forks.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, the complete cycle.
- **Diagrams.** Redraw the diagram of section 17.15.
- **Practical exercise.** Lab 21.1 ("A full fork and pull request cycle") in [`lab-manual/m21-pull-requests-forks.md`](../lab-manual/m21-pull-requests-forks.md), the complete cycle with a second account or a teammate.
- **Challenge.** Exercise 21.5 (Level 3, "The fork that cannot be synced") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q266: "Your fork's `main` cannot be fast-forwarded to upstream. What happened, how do you keep the stray work, and why is `gh repo sync --force` the wrong first move?"
- **Homework.** Read sections 17.15, 17.17 and 17.18.
- **Expected outcome.** The learner contributes through a fork without polluting its default branch and reviews with a method.

### V128: The three merge methods: merge commit, squash and merge, rebase and merge

- **Title.** The three merge methods: merge commit, squash and merge, rebase and merge
- **Learning objectives.** After this video the learner can:
  - Say for each method what lands on the base branch and which commit IDs are new
  - Say who the author and the committer of the resulting commits are
  - Show that the three results have the same tree and different ancestry
  - Explain what the contributor's local branch looks like after each method
  - Explain why "rebase and merge" differs from a local `git rebase`
- **Prerequisites.** V036, V052, V124
- **Concepts.** Merge commit: the branch's commits plus one merge commit; originals keep their IDs. Squash: one new commit, no ancestry to the branch. Rebase and merge: new copies of each commit, always rewritten. Only the first leaves the reviewed commits on the base branch under their IDs.
- **Commands.** `git merge --no-ff -m`; `git merge --squash`; `git rebase --no-ff`; `git merge --ff-only`; `git log --graph`
- **Demonstration.** Replay `labs/ch17/merge-methods.sh` (snippets `before`, `merge-commit`, `squash`, `rebase`, `what-main-gained`, `same-tree`, `first-parent`, `ancestry`) and `labs/ch17/rebase-deviations.sh` (snippets `already-on-top`, `force-new-commits`, `drop-empty`). Then: Screen walkthrough of the learner's own practice repository, following Lab 22.1 ("The three merge methods compared") in [`lab-manual/m22-merge-methods-releases.md`](../lab-manual/m22-merge-methods-releases.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, with three practice repositories or three pull requests.
- **Diagrams.** Redraw the diagram of section 17.8: one pull request, three resulting graphs.
- **Practical exercise.** Lab 22.1 ("The three merge methods compared") in [`lab-manual/m22-merge-methods-releases.md`](../lab-manual/m22-merge-methods-releases.md)
- **Challenge.** Exercise 22.2 (Level 2, "Which button was pressed?") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q275: "Compare the three merge methods for a team that requires signed commits on `main` and must show an auditor that the reviewed commit is the deployed commit."
- **Homework.** Read section 17.8. Do Exercise 22.1 (Level 1, "The three buttons from memory") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md).
- **Expected outcome.** The learner can look at a history and say which button was pressed.

### V129: What the merge method means later: bisect, blame, revert and traceability; auto-merge; the merge queue

- **Title.** What the merge method means later: bisect, blame, revert and traceability; auto-merge; the merge queue
- **Learning objectives.** After this video the learner can:
  - Compare the three methods for bisect, blame and revert
  - Say whether `git branch -d` accepts the local branch after each method and why
  - Revert a merged pull request under each method
  - Explain what auto-merge waits for and what it does not check
  - Explain what a merge queue tests that a pull request run does not, and why a required check can stay unreported on queue entries
- **Prerequisites.** V049, V070, V071, V128
- **Concepts.** Squash gives coarse bisect and blame steps and an easy revert; merge commits keep fine steps and need `-m` to revert; rebase and merge keeps steps and loses the grouping. Untested intermediate states. Auto-merge merges when requirements are met. The queue builds a temporary branch of base plus queued changes and tests that; workflows need the `merge_group` event.
- **Commands.** `git revert --no-edit`; `git revert --no-edit -m`; `git branch -d`; `git cherry -v`; `git pull --ff-only --prune`; `git log --oneline --first-parent`; `gh pr merge`
- **Demonstration.** Replay `labs/ch17/merge-methods.sh` (snippets `untested-states`, `blame`, `you-update-merge`, `you-update-squash`, `you-update-rebase`, `safe-to-delete`, `revert-merge`, `revert-squash`) and `labs/ch17/merge-queue.sh` (snippets `three-prs`, `queue-builds`, `different-ids`, `entry-fails`, `land`). GitHub side: describe auto-merge and the queue from sections 17.10 and 17.11, including the availability conditions and the statement the section marks as unverified; the queue is not walked through.
- **Diagrams.** Show the root-cause box of section 17.9. New: a queue of three entries, each tested on top of the ones before it, with the second failing.
- **Practical exercise.** Exercise 22.4 (Level 3, "A merge method for three teams") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Challenge.** Exercise 22.7 (Level 5, ""The approved commit is not on main"") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q271: "What does a merge queue test that a `pull_request` workflow does not? Why can a required check stay unreported forever on a queue?"
- **Homework.** Read sections 17.9 to 17.11. Do Exercise 22.3 (Level 2, "The queue that never finishes") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md) and Exercise 22.6 (Level 3, "Auto-merge did what it was told") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md).
- **Expected outcome.** The learner chooses a merge method for a team from its later costs and can explain a merge queue.

### V130: A Git tag versus a GitHub Release

- **Title.** A Git tag versus a GitHub Release
- **Learning objectives.** After this video the learner can:
  - Separate the tag, which is Git data, from the Release, which is a GitHub object
  - Explain how creating a release can create a tag on the server, and of which kind
  - Explain why `git describe` and the release page can disagree
  - Cut a release from an annotated tag that was pushed first
  - Say what an immutable release adds, as the section states it
- **Prerequisites.** V080, V082, V115
- **Concepts.** A Release points at a tag and adds notes and assets. If the tag does not exist, creating the release creates a lightweight tag at the target commit, which nobody chose locally. Pushing an annotated tag first avoids that. Immutable releases. Release notes.
- **Commands.** `git tag -a`; `git push origin`; `git ls-remote --tags`; `git for-each-ref`; `git describe`; `git describe --tags`; `gh release create`
- **Demonstration.** Replay `labs/ch15/tag-vs-release.sh` (snippets `annotated`, `server-side-tag`, `fetch`, `two-kinds`, `describe`) and the lab replay `labs/ch17/lab-22-2-annotated-tag-release.sh`. Then: Screen walkthrough of the learner's own practice repository, following Lab 22.2 ("A release from an annotated tag") in [`lab-manual/m22-merge-methods-releases.md`](../lab-manual/m22-merge-methods-releases.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** Show the root-cause box of section 15.12. New: a commit with two tags, one drawn through a tag object and one directly, and the Release as a box on the platform side pointing at a tag name.
- **Practical exercise.** Lab 22.2 ("A release from an annotated tag") in [`lab-manual/m22-merge-methods-releases.md`](../lab-manual/m22-merge-methods-releases.md)
- **Challenge.** Exercise 22.5 (Level 4, "The release that does not contain its fix") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q227: "Explain a Git tag versus a GitHub Release. How can a release point at a commit nobody chose, and what prevents it?"
- **Homework.** Read section 15.12.
- **Expected outcome.** The learner releases from annotated tags and can explain a version mismatch between Git and the release page.

### V131: What a rule is, rulesets, layering, and bypass

- **Title.** What a rule is, rulesets, layering, and bypass
- **Learning objectives.** After this video the learner can:
  - Describe a rule as a check on a ref update and say which rules need only the old ID, the new ID and the ref name
  - Reproduce force-push, deletion and merge-commit rules on a local server with a hook
  - Say what a ruleset targets and what its three enforcement statuses do
  - Compute the effective requirement when several rulesets and a classic rule apply
  - Distinguish bypass from exemption and say what trace each leaves
- **Prerequisites.** V041, V115
- **Concepts.** Every push asks the server to move refs; a rule is a predicate on that request. Rulesets: targets by pattern, enforcement active, evaluate or disabled. Layering: every applicable rule applies and the strictest combination holds. Bypass actors and modes. GitHub, not Git: the rules live on the platform; the local hook is a model of the mechanism.
- **Commands.** `git push`; `git push --force`; `git push --force-with-lease`; `git merge -q --squash`
- **Demonstration.** Replay `labs/ch18/ref-updates.sh` (snippets `the-rules`, `install`, `fast-forward-allowed`, `force-push`, `delete`, `merge-commit`, `other-branches`, `tags`, `disabled-again`) and `labs/ch18/fnmatch-targets.sh` (snippets `script`, `star-stops-at-slash`, `common-targets`, `tags`). Then: Screen walkthrough of the learner's own practice repository, following Lab 23.1 ("A ruleset on the default branch") in [`lab-manual/m23-governance.md`](../lab-manual/m23-governance.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** Redraw the diagram of section 18.2 and the diagram of section 18.4.
- **Practical exercise.** Lab 23.1 ("A ruleset on the default branch") in [`lab-manual/m23-governance.md`](../lab-manual/m23-governance.md)
- **Challenge.** Exercise 23.4 (Level 3, "Layers") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q221: "What is a rule, mechanically? Which rules can be decided from the old ID, the new ID and the ref name alone, and which need platform data?"
- **Homework.** Read sections 18.1 to 18.5. Do Exercise 23.1 (Level 1, "Five predicates") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md) and Exercise 23.2 (Level 2, "Which branches does the pattern cover?") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md).
- **Expected outcome.** The learner sees branch protection as predicates on ref updates and can compute what applies to a given branch.

### V132: The rules and their sub-options: required reviews, status checks and their traps, conversations, signatures, linear history

- **Title.** The rules and their sub-options: required reviews, status checks and their traps, conversations, signatures, linear history
- **Learning objectives.** After this video the learner can:
  - List the rules a ruleset offers and the sub-options of required reviews
  - Explain why a required check can stay pending forever and design the fix
  - Say what "require branches to be up to date" tests
  - Explain why a merge method can be blocked by "Require signed commits" and which merge methods a linear-history rule allows
  - Run the local pre-flight that predicts each rule's verdict
- **Prerequisites.** V124, V128, V131
- **Concepts.** Required reviews: count, stale dismissal, code owner review, last-push approval. Required status checks are matched by name; a workflow skipped by a path filter never reports, a skipped job reports success. Conversation resolution. Signed commits and what each merge method signs. Linear history forbids merge commits.
- **Commands.** `git merge-base --is-ancestor`; `git rev-list --left-right --count`
- **Demonstration.** Replay `labs/ch18/merge-preflight.sh` (snippets `fetch`, `up-to-date`, `conflicts`, `commits`, `signatures`, `metadata`, `paths`, `bring-up-to-date`). Then: Screen walkthrough of the learner's own practice repository, following Lab 23.3 ("Three blocked merges to diagnose") in [`lab-manual/m23-governance.md`](../lab-manual/m23-governance.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** New: a table of rules against "decided from Git data alone" or "needs platform state", with the pre-flight command for the first kind.
- **Practical exercise.** Exercise 23.3 (Level 3, "Review this ruleset") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Challenge.** Exercise 23.6 (Level 3, "Four pull requests that will not merge") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q249: "A required check stays pending forever on documentation-only pull requests. Explain the cause and design a fix that keeps the path optimization."
- **Homework.** Read sections 18.6 to 18.11.
- **Expected outcome.** The learner configures required reviews and checks without creating a branch that can never merge.

### V133: Tag rulesets, push rulesets, organization-level rulesets, classic branch protection, and plan gates

- **Title.** Tag rulesets, push rulesets, organization-level rulesets, classic branch protection, and plan gates
- **Learning objectives.** After this video the learner can:
  - Protect release tags with a tag ruleset and test a target pattern before relying on it
  - Say what a push ruleset restricts
  - Say what organization-level rulesets add
  - Name the differences between classic branch protection and rulesets that matter during an incident
  - Say what cannot be practised on a Free plan and how to learn it anyway
- **Prerequisites.** V081, V132
- **Concepts.** Tag rulesets stop moved and deleted tags on the server. Patterns use fnmatch: `*` does not cross a slash. Organization and enterprise rulesets apply across repositories. Classic protection still exists and layers with rulesets. Plan gates from section 18.15.
- **Commands.** `git push --force`
- **Demonstration.** Replay `labs/ch18/ref-updates.sh` (snippets `the-rules`, `tags`, `disabled-again`); the pattern rules were shown in V131. GitHub side: Screen walkthrough of the learner's own practice repository, following Lab 23.1 ("A ruleset on the default branch") in [`lab-manual/m23-governance.md`](../lab-manual/m23-governance.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors for where rulesets are managed. The tag ruleset itself is created on the practice repository as section 18.12 describes; push rulesets and organization rulesets are taught from the documentation, as section 18.15 says.
- **Diagrams.** New: a pattern-matching table: target patterns down the side, ref names across, a mark where they match.
- **Practical exercise.** Exercise 23.2 (Level 2, "Which branches does the pattern cover?") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Challenge.** Exercise 23.8 (Level 5, ""Main is protected. How did a force push get through?"") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q252: "Classic rule versus ruleset: name four behavioral differences that matter during an incident."
- **Homework.** Read sections 18.12 to 18.15.
- **Expected outcome.** The learner protects tags as well as branches and knows which protections their plan provides.

### V134: Seeing and managing rules, "why can't I merge?", and a worked design for a production branch

- **Title.** Seeing and managing rules, "why can't I merge?", and a worked design for a production branch
- **Learning objectives.** After this video the learner can:
  - Find every rule that applies to a branch from the `/rules` page and from the command line
  - Explain why `gh ruleset` is read-only and how rulesets are changed through the API
  - Follow the procedure for "everything is green and I still cannot merge"
  - Diagnose three blocked merges on the practice repository
  - Defend each rule of the worked production-branch design and name its cost
- **Prerequisites.** V133
- **Concepts.** Evidence first: which rules apply, which one says no, to what. The procedure of section 18.17 moves from Git facts (behind, conflicts, unsigned, merge commits) to platform state (reviews, checks, conversations, bypass). The worked design of section 18.18.
- **Commands.** `gh ruleset list`; `gh ruleset view`; `gh ruleset check`; `gh api`; `git merge-tree --write-tree --name-only`; `git rev-list --count --merges`
- **Demonstration.** Replay the lab replay `labs/ch18/lab-23-3-preflight.sh` up to its checkpoint. Then: Screen walkthrough of the learner's own practice repository, following Lab 23.3 ("Three blocked merges to diagnose") in [`lab-manual/m23-governance.md`](../lab-manual/m23-governance.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, opening the rules page of the practice repository for each blocked case.
- **Diagrams.** New: the procedure of section 18.17 as a flow with two lanes, "ask Git" and "ask GitHub".
- **Practical exercise.** Lab 23.3 ("Three blocked merges to diagnose") in [`lab-manual/m23-governance.md`](../lab-manual/m23-governance.md)
- **Challenge.** Exercise 23.7 (Level 3, "Protect a monorepo") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q253: "Walk through your procedure when a developer says "everything is green and I still cannot merge"."
- **Homework.** Read sections 18.16 to 18.21 and do the Practice section 18.23.
- **Expected outcome.** The learner debugs a blocked merge across every rule layer and can design protection for a production branch.

### V135: CODEOWNERS: what it is, where it lives, syntax, and last match wins

- **Title.** CODEOWNERS: what it is, where it lives, syntax, and last match wins
- **Learning objectives.** After this video the learner can:
  - Say what a CODEOWNERS file does when no rule refers to it
  - List the locations where the file is looked up and which one counts
  - Write patterns and predict the owner of a path under "last match wins"
  - Name the gitignore features that do not work in CODEOWNERS
  - Explain why an owner needs write access
- **Prerequisites.** V012, V134
- **Concepts.** CODEOWNERS requests reviews; a rule makes them required. Lookup order of the three locations. One line per pattern; the last matching line decides and replaces earlier owners. No negation, no character ranges; some accepted syntax behaves differently from gitignore.
- **Commands.** `git check-ignore -v --no-index`
- **Demonstration.** Replay `labs/ch18/codeowners-vs-gitignore.sh` (snippets `last-match-wins`, `anchoring`, `directory-capture`, `docs-star`, `negation`, `range`, `hash`, `case`) and `labs/ch18/codeowners-base.sh` (snippets `which-file`). Then: Screen walkthrough of the learner's own practice repository, following Lab 23.2 ("CODEOWNERS enforcement with a second account") in [`lab-manual/m23-governance.md`](../lab-manual/m23-governance.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** Show the root-cause box of section 19.5. New: a CODEOWNERS file on the left, eight paths on the right, and an arrow from each path to the last line that matches it.
- **Practical exercise.** Exercise 23.5 (Level 2, "Eight paths, one CODEOWNERS file") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Challenge.** Exercise 23.7 (Level 3, "Protect a monorepo") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q237: "Explain "last match wins" in CODEOWNERS with an example where a later, more general pattern takes a path away from a specific team."
- **Homework.** Read sections 19.1 to 19.6. Do the pattern exercises of section 19.16.
- **Expected outcome.** The learner writes a CODEOWNERS file whose effect can be predicted line by line.

### V136: CODEOWNERS in force: the base branch decides, protecting the file, monorepos, required reviewers, and finding out what GitHub thinks

- **Title.** CODEOWNERS in force: the base branch decides, protecting the file, monorepos, required reviewers, and finding out what GitHub thinks
- **Learning objectives.** After this video the learner can:
  - Say from which branch the CODEOWNERS file is read for a pull request and why that matters
  - Explain why a pull request cannot remove its own required reviewer by editing the file
  - Protect CODEOWNERS and the workflows directory and name the conditions that make the protection real
  - Lay out ownership for a monorepo and decide when the "required reviewers" rule replaces or complements CODEOWNERS
  - Check the file for errors before merging a change to it
- **Prerequisites.** V135
- **Concepts.** The base branch's version of the file applies. Ownership of the file itself and of `.github/workflows/`. Monorepo patterns. The newer required-reviewers rule. Three documented causes of a team that is never requested.
- **Commands.** `git diff --name-only`; `git show`; `gh api`; `gh pr view`
- **Demonstration.** Replay `labs/ch18/codeowners-base.sh` (snippets `which-file`, `base-version`, `changed-paths`, `pr-edits-the-file`) and the lab replay `labs/ch18/lab-23-2-codeowners.sh`. Then: Screen walkthrough of the learner's own practice repository, following Lab 23.2 ("CODEOWNERS enforcement with a second account") in [`lab-manual/m23-governance.md`](../lab-manual/m23-governance.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, proving enforcement with a second account.
- **Diagrams.** New: base branch and head branch each with its own CODEOWNERS file, and an arrow from the pull request to the base branch's copy.
- **Practical exercise.** Lab 23.2 ("CODEOWNERS enforcement with a second account") in [`lab-manual/m23-governance.md`](../lab-manual/m23-governance.md)
- **Challenge.** Exercise 23.8 (Level 5, ""Main is protected. How did a force push get through?"") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q254: "Why can a pull request not remove its own required reviewer by editing CODEOWNERS?"
- **Homework.** Read sections 19.7 to 19.14.
- **Expected outcome.** The learner makes code ownership enforceable and cannot be surprised by which version of the file applies.

### V137: Signatures: what is signed, by which program, and SSH signing end to end

- **Title.** Signatures: what is signed, by which program, and SSH signing end to end
- **Learning objectives.** After this video the learner can:
  - Say which bytes of a commit a signature covers and where the signature is stored
  - Name the three signing formats Git supports and the program each uses
  - Configure SSH signing and sign a commit and a tag
  - Verify a signature locally with an allowed-signers file
  - Explain the difference between "good signature" and "trusted signer"
- **Prerequisites.** V021, V120
- **Concepts.** A signature is a header in the commit object over the rest of the object. `gpg.format` selects OpenPGP, X.509 or SSH. Verification needs a list of who may sign as whom: the allowed-signers file. A signature that verifies against an unknown key proves only that someone holds that key. The lab keys are generated in the sandbox; the scripts that need fresh keys are volatile.
- **Commands.** `gpg.format`; `user.signingKey`; `commit.gpgSign`; `tag.gpgSign`; `gpg.ssh.allowedSignersFile`; `git commit -S`; `git log -1 --show-signature`; `git verify-commit`; `git tag -v`; `git verify-tag`; `ssh-keygen -q -t`
- **Demonstration.** Replay `labs/ch14b/signing-backends.sh` (snippets `stand-in`, `openpgp`, `x509`, `ssh`, `bad-format`) and `labs/ch14b/ssh-signing.sh` (snippets `key`, `configure`, `sign-a-commit`, `verify-without-trust`, `allowed-signers`, `placeholders`, `sign-by-default`, `signed-tag`, `mechanism`, `key-problems`); also show `labs/ch06/signed-header.sh` (snippets `gpgsig`) for the header itself.
- **Diagrams.** Show the root-cause box of section 14B.16. New: a commit object with the `gpgsig` header boxed and a bracket over the bytes it covers.
- **Practical exercise.** Lab 24.1 ("SSH signing locally") in [`lab-manual/m24-signing-local.md`](../lab-manual/m24-signing-local.md)
- **Challenge.** Exercise 24.1 (Level 1, "Covered or not covered?") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q34: "What is the difference between `git commit -s` and `git commit -S`? Where does each leave its mark in the object?"
- **Homework.** Read sections 14B.15 and 14B.16.
- **Expected outcome.** The learner signs commits with an SSH key and can verify them without GitHub.

### V138: What a signature covers, what verification proves, and author spoofing

- **Title.** What a signature covers, what verification proves, and author spoofing
- **Learning objectives.** After this video the learner can:
  - Show that anyone can commit under any author name and address, and that a server accepts it
  - List what a signature does not cover: refs, later rewrites, the push
  - Explain what happens to signatures in a rebase
  - Tell an unsigned forgery from a signed forgery and say which check catches each
  - Enforce a signature policy at merge time with `--verify-signatures`
- **Prerequisites.** V020, V137
- **Concepts.** Author and committer fields are assertions. A signature binds a key to the content of one commit object. Refs are not signed, so a signed commit can be put on any branch. Rewriting creates new objects and drops or replaces signatures. Key lifetime and revocation.
- **Commands.** `git log -1 --format`; `git verify-commit`; `git merge --verify-signatures --ff-only`; `git shortlog -sne`; `git cat-file`
- **Demonstration.** Replay `labs/ch14b/spoof-author.sh` (snippets `real`, `author-flag`, `full-impersonation`, `objects-compared`, `server-accepts`, `what-is-signed`), `labs/ch14b/signature-scope.sh` (snippets `tamper`, `refs-are-not-signed`, `rewrites-drop-signatures`, `unknown-key`, `key-lifetime`, `revocation`), `labs/ch14b/spoof-signed.sh` (snippets `allowed-signers`, `unsigned-forgery`, `signed-forgery`, `policy-check`, `merge-verify`) and `labs/ch21b/identity-assertion.sh` (snippets `assert-anything`, `the-object`).
- **Diagrams.** Redraw the diagram of section 14B.17.
- **Practical exercise.** Lab 24.2 ("A spoofed-author commit") in [`lab-manual/m24-signing-local.md`](../lab-manual/m24-signing-local.md)
- **Challenge.** Exercise 24.2 (Level 2, "Five commits, five claims") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q309: "What bytes does a commit signature cover? Name three things about a commit that it does not establish."
- **Homework.** Read sections 14B.17 to 14B.21 and section 21B.5. Do the Practice section 14B.23.
- **Expected outcome.** The learner can explain exactly what a signature proves and demonstrate author spoofing safely.

### V139: Signatures on GitHub: the verification states and what "Verified" does not prove

- **Title.** Signatures on GitHub: the verification states and what "Verified" does not prove
- **Learning objectives.** After this video the learner can:
  - Name the verification states GitHub displays and what produces each
  - Say what vigilant mode and persistent verification records change, as the section states them
  - Say which commits GitHub signs itself
  - Explain why "rebase and merge" produces commits that are not signed by the author
  - State three things a "Verified" badge does not establish
- **Prerequisites.** V128, V138
- **Concepts.** GitHub, not Git: the badge is the platform's judgment about a signature and an account. Verified, Partially verified, Unverified. Commits made in the web interface and by squash merges are signed by GitHub. A badge says a key registered to an account signed the object; it does not say who typed the change or who pushed it.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay the lab replay `labs/ch21b/lab-24-3-verification-states.sh`, which builds the three commits locally and shows what Git recorded for each. Then: Screen walkthrough of the learner's own practice repository, following Lab 24.3 ("What GitHub shows for unsigned, signed and forged commits") in [`lab-manual/m24-signing-github.md`](../lab-manual/m24-signing-github.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, pushing the three commits to the practice repository and reading the badge of each.
- **Diagrams.** New: three commits (unsigned, signed, forged author) with the Git facts on top and the badge GitHub is documented to show underneath.
- **Practical exercise.** Lab 24.3 ("What GitHub shows for unsigned, signed and forged commits") in [`lab-manual/m24-signing-github.md`](../lab-manual/m24-signing-github.md)
- **Challenge.** Exercise 24.6 (Level 5, "Verified, and she was on a plane") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q315: "A commit on `main` shows your tech lead's avatar and she says she did not write it. What does GitHub's display prove, what evidence do you look at, and which controls would have prevented or flagged it?"
- **Homework.** Read sections 21B.6 and 21B.7. Do Exercise 24.3 (Level 2, "What would GitHub display?") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md) and Exercise 24.4 (Level 3, "Four questions from a team that has just required signatures") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md).
- **Expected outcome.** The learner reads a verification badge precisely and can explain it to someone who takes it for proof of authorship.

### V140: The GitHub CLI, gh pr, gh api, the REST API and GraphQL, rate limits, webhooks and GitHub Apps

- **Title.** The GitHub CLI, gh pr, gh api, the REST API and GraphQL, rate limits, webhooks and GitHub Apps
- **Learning objectives.** After this video the learner can:
  - Drive a complete feature cycle from the terminal with `gh`
  - Say which `gh` commands change state and which only read
  - Query pull request and ruleset data with `gh api` and shape the result with a jq filter
  - Explain REST API versioning, pagination and rate limits as the section gives them
  - Say when an integration should be a GitHub App
- **Prerequisites.** V127, V134
- **Concepts.** `gh` is a client of the API with the user's credentials. `gh pr` covers create, view, checks, review, merge. `gh api` reaches every endpoint; the default method changes when fields are passed, and results are paginated. The version header. GraphQL at concept level. Webhooks and Apps as the integration model. Local replays show only `--help` output and jq on stored examples; no GitHub output was captured.
- **Commands.** `gh --help`; `gh pr create`; `gh pr view`; `gh pr checks`; `gh pr merge`; `gh pr checkout`; `gh api`; `gh api --help`; `gh api graphql -f`; `gh ruleset --help`
- **Demonstration.** Replay `labs/ch15/gh-help.sh` (snippets `families`, `release-create`, `api-flags`, `ruleset`) and `labs/ch15/jq-rehearsal.sh` (snippets `one-field`, `several-fields`, `select`, `reshape`), then the lab replays `labs/ch15/lab-25-1-feature-cycle.sh` and `labs/ch15/lab-25-2-api-queries.sh`. Then: Screen walkthrough of the learner's own practice repository, following Lab 25.1 ("A full feature cycle with `gh`") in [`lab-manual/m25-github-cli-api.md`](../lab-manual/m25-github-cli-api.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, in the normal shell.
- **Diagrams.** New: `gh`, the browser and a GitHub App drawn as three clients of one API, each with the credential it uses.
- **Practical exercise.** Lab 25.1 ("A full feature cycle with `gh`") in [`lab-manual/m25-github-cli-api.md`](../lab-manual/m25-github-cli-api.md)
- **Challenge.** Exercise 25.4 (Level 3, "Five scripts that stopped working") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q230: "A script using `gh api` returns 30 results everywhere, and once created an issue by accident. Explain both."
- **Homework.** Read sections 15.16 to 15.18, 15.20 to 15.22 and 17.16. Do Lab 25.2 ("Queries with `gh api`") in [`lab-manual/m25-github-cli-api.md`](../lab-manual/m25-github-cli-api.md); then Exercise 25.1 (Level 1, "Ask the CLI, not the browser") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md) to Exercise 25.3 (Level 2, "Six filters, offline") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md). Read [`cheatsheets/github-cli-cheat-sheet.md`](../cheatsheets/github-cli-cheat-sheet.md).
- **Expected outcome.** The learner runs the pull request and review loop without a browser and reaches anything else through the API.

### V141: Gate briefing: GitHub

- **Title.** Gate briefing: GitHub
- **Learning objectives.** After this video the learner can:
  - State what Gate 6 covers and its threshold of 85
  - Explain how the hands-on part differs: three cases on paper
  - Name the layer (Git, GitHub) of every fact in an answer
  - Prepare with the procedures: authentication decision tree, pull request anatomy, "why can't I merge"
- **Prerequisites.** V122, V129, V130, V136, V139, V140
- **Concepts.** Gate 6 covers the platform model, authentication, pull requests, merge methods, rulesets, CODEOWNERS, signing and the CLI. Part 3 is on paper: configuration files, described situations and real Git evidence. Nothing is run on GitHub and no GitHub output appears. An answer that does not say which layer acted loses points.
- **Commands.** `git ls-remote`; `git merge-base`; `git diff --stat`
- **Demonstration.** Replay `labs/ch17/pr-anatomy.sh` (snippets `commit-list`, `merge-base`, `three-dot`, `two-dot`) as the warm-up: Git evidence of the kind the paper cases contain. Show the rules for paper cases from [`assessments/README.md`](../assessments/README.md). Do not open the gate file or the case files on screen.
- **Diagrams.** New: a two-column sheet "Git says" and "GitHub says" for one blocked pull request, as the form an answer should take.
- **Practical exercise.** Redo Exercise 20.6 (Level 4, "Three faults, no connection") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md), Exercise 21.6 (Level 4, "Five commits for a two-commit fix") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md) and Exercise 22.5 (Level 4, "The release that does not contain its fix") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md), the Level 4 exercises of the block, and Exercise 23.8 (Level 5, ""Main is protected. How did a force push get through?"") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md) and Exercise 24.6 (Level 5, "Verified, and she was on a plane") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md) at Level 5.
- **Challenge.** Take Gate 6: [`assessments/gate-6-github.md`](../assessments/gate-6-github.md).
- **Interview question.** Q259: "A required status check is green on a pull request. What does that prove, and what does it not prove?"
- **Homework.** Before the gate: answer the "Interview questions" sections of Chapters 15 to 19 aloud. Read [`reference/github-reference.md`](../reference/github-reference.md).
- **Expected outcome.** The learner sits Gate 6 able to explain what the platform does to Git data and who can do what.

## Part 6: CI/CD with GitHub Actions

Roadmap Level 6 (Modules 26 to 28), then the Actions gate. 14 videos on reading, writing and debugging workflows. The textbook's workflows were parse-checked and never run on GitHub by the authors; the videos say so, show the Git side with local replays in which a bare repository stands in for GitHub, and show the platform side as a walkthrough of the learner's own practice repository.

### V142: The Actions model, and YAML read carefully

- **Title.** The Actions model, and YAML read carefully
- **Learning objectives.** After this video the learner can:
  - Define workflow, event, job, step, action, runner and shell and say which contains which
  - Read a workflow file in a fixed order to predict when it runs, where, and with what
  - Name the YAML features that change the meaning of a workflow without an error
  - Explain why the key `on` needs care and what a tab does
  - Say what was and was not verified about the course's workflow files
- **Prerequisites.** V115, V141
- **Concepts.** A workflow is a file in `.github/workflows/` on a branch; an event starts a run; a run has jobs; a job runs on one runner and has steps; a step is a shell command or an action. YAML: scalars that become booleans or numbers, block scalars, anchors, indentation. GitHub Actions, not Git, for all of it. The course's workflows pin actions to full commit IDs listed in [`workflows/ACTION_PINS.md`](../workflows/ACTION_PINS.md).
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay `labs/ch20a/yaml-reading.sh` (snippets `scalars`, `on-key`, `anchors`, `block-scalars`, `tab`); the script parses YAML locally and runs nothing on GitHub. Then read [`workflows/01-tests.yml`](../workflows/01-tests.yml) line by line on screen. Then: Screen walkthrough of the learner's own practice repository, following Lab 26.1 ("Workflow 1, run the tests") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** New: nested boxes workflow > run > job > step, with "runner" beside the job and "event" as the arrow that starts the run.
- **Practical exercise.** Lab 26.1 ("Workflow 1, run the tests") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md)
- **Challenge.** Exercise 26.3 (Level 2, "Six things the author did not mean") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q296: "You inherit a repository with twelve workflow files. In what order do you read one of them to predict when it runs, where, with what code, and with what permissions?"
- **Homework.** Read sections 20A.1 to 20A.3. Do Exercise 26.1 (Level 1, "True or false, with the reason") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner reads a workflow file in a fixed order and is not caught by YAML typing.

### V143: Events and filters, contexts and expressions, and env, vars and secrets

- **Title.** Events and filters, contexts and expressions, and env, vars and secrets
- **Learning objectives.** After this video the learner can:
  - Say for `push`, `pull_request`, `schedule` and `workflow_dispatch` which commit the run refers to and from which branch the workflow file is read
  - Predict whether a branch or path filter starts a workflow for a given change
  - Explain how changed paths are computed for a pull request and for a push
  - Read an expression and say when it is evaluated
  - Distinguish `env`, `vars` and `secrets` by where they are defined and who can read them
- **Prerequisites.** V064, V142
- **Concepts.** Each event carries a ref and a commit. Filters decide whether a run is created at all, which matters for required checks. Path filters use a three-dot diff for pull requests and a two-dot diff for pushes. Contexts are data available to expressions; expressions are evaluated before the shell sees the script. Variables are configuration; secrets are not passed to every run.
- **Commands.** `git diff --name-only`
- **Demonstration.** Replay `labs/ch20a/path-filter.sh` (snippets `pull-request`, `two-dots-would-mislead`, `push`) and the lab replay `labs/ch20a/lab-26-5-path-filter.sh`. Then: Screen walkthrough of the learner's own practice repository, following Lab 26.2 ("Workflow 2, linting") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, to see which pushes start the lint workflow [`workflows/02-lint.yml`](../workflows/02-lint.yml).
- **Diagrams.** New: a table of the four events against "commit", "ref", "workflow file read from".
- **Practical exercise.** Lab 26.2 ("Workflow 2, linting") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md)
- **Challenge.** Exercise 26.4 (Level 2, "Will the path filter start the workflow?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q292: "For each of `push`, `pull_request`, `schedule` and `workflow_dispatch`: which commit does the run refer to, and from which commit is the workflow file read?"
- **Homework.** Read sections 20A.4 to 20A.6. Do Exercise 26.2 (Level 2, "Which commit, which ref, which file?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner predicts whether and on what a workflow will run before pushing.

### V144: Shells, and passing data between steps and jobs

- **Title.** Shells, and passing data between steps and jobs
- **Learning objectives.** After this video the learner can:
  - State the default shell and its options for a `run` step on a Linux runner
  - Explain why a pipeline with a failing first command can leave a step green, and fix it
  - Explain why a variable set in one step is gone in the next
  - Pass a value to a later step and to a later job through `GITHUB_OUTPUT` and job outputs
  - Recognize the deprecated command the section names
- **Prerequisites.** V143
- **Concepts.** Each `run` step is a new shell process started with documented options; without `pipefail` a pipeline's status is its last command's. State passes through files the runner provides: `GITHUB_OUTPUT`, `GITHUB_ENV`. Job outputs are declared and consumed through `needs`. Files do not pass between jobs; artifacts do.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay `labs/ch20a/step-shell.sh` (snippets `pipefail`, `new-process-per-step`, `github-output`, `deprecated-set-output`); the script reproduces the runner's shell invocation locally. Then: Screen walkthrough of the learner's own practice repository, following Lab 26.3 ("Workflow 3, build the application") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, reading the shell line at the top of a step's log in [`workflows/03-build.yml`](../workflows/03-build.yml).
- **Diagrams.** New: three steps as three separate shell processes with a file `GITHUB_OUTPUT` passed along underneath.
- **Practical exercise.** Exercise 26.5 (Level 2, "Two shells, three scripts") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Challenge.** Exercise 28.2 (Level 3, "The nightly evaluation that never fails") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q284: "A job is green although `pytest | tee report.txt` had failing tests. Give the exact shell command line the runner used, and two ways to fix it."
- **Homework.** Read section 20A.7.
- **Expected outcome.** The learner knows what shell runs their script and never trusts a green step that pipes into `tee`.

### V145: What actions/checkout does by default: one commit, no tags, and the merge ref

- **Title.** What actions/checkout does by default: one commit, no tags, and the merge ref
- **Learning objectives.** After this video the learner can:
  - Say what the runner's repository contains after a default checkout
  - Name three commands or tools that give wrong results there and the minimal fix for each
  - Explain which commit a `pull_request` run checks out and why it is not in your clone
  - Reproduce the runner's checkout locally with a shallow fetch
  - Decide when full history is worth its cost
- **Prerequisites.** V082, V109, V123, V144
- **Concepts.** By default the action fetches one commit with no tags and leaves HEAD detached. `git describe`, changelogs, blame and merge-base need more. On `pull_request` the checked-out commit is GitHub's test merge of the head into the base, so CI tests a commit the author never had. Fetch depth and tags are options of the action.
- **Commands.** `git clone --depth`; `git fetch --depth`; `git fetch --unshallow --tags`; `git describe --tags`; `git rev-parse`; `git log --oneline --decorate`; `git merge-base`; `git ls-remote`
- **Demonstration.** Replay `labs/ch20a/shallow-checkout.sh` (snippets `full-clone`, `runner-clone`, `describe-fails`, `tags-are-not-enough`, `full-history`) and `labs/ch20a/merge-ref.sh` (snippets `your-branch`, `server-refs`, `runner-checkout`, `what-is-checked-out`, `tests-on-the-merge`, `not-in-your-clone`); a bare repository stands in for GitHub. Then the lab replay `labs/ch20a/lab-26-3-describe.sh`.
- **Diagrams.** Show both root-cause boxes of section 20A.8 (the root-cause box of section 20A.8). New: your branch, `main`, and the test merge commit that only the server has.
- **Practical exercise.** Lab 26.3 ("Workflow 3, build the application") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md)
- **Challenge.** Exercise 28.5 (Level 4, "Green here, red in a fresh clone") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q283: "What does `actions/checkout` put on the runner by default? Name three tools or commands that give wrong results there, and say whether each fails or lies."
- **Homework.** Read section 20A.8.
- **Expected outcome.** The learner can say exactly which commit CI tested and why history-dependent tools fail there.

### V146: Controlling jobs, matrix strategies, dependency caching, and artifacts

- **Title.** Controlling jobs, matrix strategies, dependency caching, and artifacts
- **Learning objectives.** After this video the learner can:
  - Order jobs with `needs` and predict what `if`, `timeout-minutes` and `continue-on-error` do to the run's result
  - Count the jobs of a matrix with `include` and `exclude`
  - Design a cache key and say what happens on a miss and on a stale hit
  - Distinguish a cache from an artifact by purpose, scope, lifetime and trust
  - Carry one build from a build job to a later job
- **Prerequisites.** V145
- **Concepts.** A job skipped by its `if` reports success for its check; a job that needs a failed or skipped job is skipped in turn unless its own `if` says otherwise. A matrix expands into jobs, each with its own name, which matters for required checks. A cache is a speed-up keyed by content, shared within scope rules; a wrong key gives stale dependencies. An artifact is the output of a run, kept for a retention period.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay the lab replays `labs/ch20a/lab-26-4-cache-key.sh` (snippets `key`, `key-changes`) and `labs/ch20a/lab-26-7-artifact.sh` (snippets `deploy`, `failures`); they compute keys and digests locally. Then: Screen walkthrough of the learner's own practice repository, following Lab 26.8 ("Workflow 10, matrix testing") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, running the matrix workflow [`workflows/10-matrix.yml`](../workflows/10-matrix.yml) and counting the jobs before opening the run.
- **Diagrams.** Show the root-cause box of section 20A.11. New: a matrix drawn as a grid with excluded cells crossed out and included cells added.
- **Practical exercise.** Lab 26.4 ("Workflow 4, Python tests with uv and caching") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md)
- **Challenge.** Exercise 26.6 (Level 3, "Caches and artifacts") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q281: "What is the difference between a cache and an artifact in purpose, scope, lifetime and trust? Which one may a release job consume?"
- **Homework.** Read sections 20A.9 to 20A.12. Do Lab 26.8 ("Workflow 10, matrix testing") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md).
- **Expected outcome.** The learner uses caches and artifacts for what each is for and can predict the job list of a matrix.

### V147: Workflows 1 to 5, line by line: tests, lint, build, Python with uv, Java with Maven

- **Title.** Workflows 1 to 5, line by line: tests, lint, build, Python with uv, Java with Maven
- **Learning objectives.** After this video the learner can:
  - Explain every line of the first five workflows
  - Say for each which event starts it, what is checked out and which permissions the token has
  - Predict the outcome of each before running it and compare with the run
  - Break each on purpose and diagnose from the log
  - State what the authors did and did not verify about these files
- **Prerequisites.** V146
- **Concepts.** The files are in `workflows/`: each declares `permissions` at the top and pins every action to a full commit ID. They were parse-checked and assembled from documentation and never run on GitHub by the authors: a failure for a reason the authors could not test is material for diagnosis. The lab's five movements: add, predict, run, read, break.
- **Commands.** `git describe`; `git rev-parse --is-shallow-repository`; `uv sync --locked`; `uv run pytest`; `uv run ruff`
- **Demonstration.** Read [`workflows/01-tests.yml`](../workflows/01-tests.yml), [`workflows/02-lint.yml`](../workflows/02-lint.yml), [`workflows/03-build.yml`](../workflows/03-build.yml), [`workflows/04-python-tests.yml`](../workflows/04-python-tests.yml) and [`workflows/05-java-tests.yml`](../workflows/05-java-tests.yml) on screen in the order of section 20A.13. Replay the lab replays `labs/ch20a/lab-26-1-first-workflow.sh` (snippets `create`, `break`, `recover`) and `labs/ch20a/lab-26-2-lint-branch.sh` (snippets `branch`). Then: Screen walkthrough of the learner's own practice repository, following Lab 26.1 ("Workflow 1, run the tests") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, Screen walkthrough of the learner's own practice repository, following Lab 26.4 ("Workflow 4, Python tests with uv and caching") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors and Screen walkthrough of the learner's own practice repository, following Lab 26.5 ("Workflow 5, Java tests with Maven") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** New: one workflow file with four coloured brackets: trigger, permissions, environment setup, the commands that are the actual check.
- **Practical exercise.** Lab 26.5 ("Workflow 5, Java tests with Maven") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md)
- **Challenge.** Exercise 26.3 (Level 2, "Six things the author did not mean") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q302: "An executive says: "The pipeline is green, so the tests passed and the change is safe to merge." Explain in plain terms the distinct ways a green result on GitHub Actions can be false evidence, and the organization-wide controls you would set."
- **Homework.** Read the first five workflows of section 20A.13. Do Lab 26.2 ("Workflow 2, linting") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md) to Lab 26.4 ("Workflow 4, Python tests with uv and caching") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md) if not done. Do Exercise 26.7 (Level 1, "Read a run from the terminal") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner has five working pipelines in a practice repository and can defend every line of them.

### V148: Workflows 6, 7 and 10, action versions and the Node 24 runtime, and the syntax added in 2025 and 2026

- **Title.** Workflows 6, 7 and 10, action versions and the Node 24 runtime, and the syntax added in 2025 and 2026
- **Learning objectives.** After this video the learner can:
  - Explain every line of the image, artifact and matrix workflows
  - Say which tags the image workflow gives an image and what each identifies
  - Explain why actions are pinned by a 40-character commit ID and how the pin is kept current
  - State what the Node 24 change means for old action versions, as the section gives it
  - Name the syntax additions of 2025 and 2026 that the section lists
- **Prerequisites.** V147
- **Concepts.** Workflow 6 builds and pushes an image to the GitHub container registry; workflow 7 creates an artifact and consumes it; workflow 10 is the matrix. Action versions are re-verified on the day of each lesson: say so on screen and read the versions from [`workflows/ACTION_PINS.md`](../workflows/ACTION_PINS.md), not from memory.
- **Commands.** `git describe`; `git status --short --branch`
- **Demonstration.** Read [`workflows/06-docker-image.yml`](../workflows/06-docker-image.yml), [`workflows/07-artifact.yml`](../workflows/07-artifact.yml) and [`workflows/10-matrix.yml`](../workflows/10-matrix.yml) on screen. Replay the lab replays `labs/ch20a/lab-26-6-image-tags.sh` (snippets `inputs`) and `labs/ch20a/lab-26-7-artifact.sh` (snippets `deploy`, `failures`). Then: Screen walkthrough of the learner's own practice repository, following Lab 26.6 ("Workflow 6, build and push a container image") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors and Screen walkthrough of the learner's own practice repository, following Lab 26.7 ("Workflow 7, create an artifact and consume it") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** New: one image with its tags drawn as labels, each with an arrow to what it names: a commit, a branch tip that moves, a version.
- **Practical exercise.** Lab 26.6 ("Workflow 6, build and push a container image") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md)
- **Challenge.** Lab 26.7 ("Workflow 7, create an artifact and consume it") in [`lab-manual/m26-actions-fundamentals.md`](../lab-manual/m26-actions-fundamentals.md)
- **Interview question.** Q294: "Why would you pin `actions/checkout` in a workflow by a 40-character commit ID, and what does the Node 24 change of September 2026 mean for a file that says `@v4`?"
- **Homework.** Read the rest of section 20A.13 and sections 20A.14 to 20A.18. Do the Practice section 20A.20.
- **Expected outcome.** The learner can build and hand over an image and an artifact and keeps action pins current deliberately.

### V149: Environments, deploying to staging, and promotion to production behind an approval

- **Title.** Environments, deploying to staging, and promotion to production behind an approval
- **Learning objectives.** After this video the learner can:
  - List what must be configured on GitHub, outside the workflow file, for `environment:` to protect anything
  - Explain required reviewers, deployment branch rules and environment secrets
  - Explain workflow 8 line by line and say which commit range a deployment contains
  - Explain workflow 9 and what "the bytes that were tested are the bytes that ship" requires
  - Guard a deployment against going backwards
- **Prerequisites.** V148
- **Concepts.** An environment is a GitHub object with protection rules and its own secrets; naming one in a job that does not exist creates an unprotected one. Staging deploys what was built once; production promotes the same artifact after approval. The deployed range is a Git question: which commits are between the last deployed commit and this one, and is the new one a descendant.
- **Commands.** `gh secret set`; `gh variable set`; `gh secret list --env`; `gh api`; `git merge-base --is-ancestor`; `git log --oneline`; `git archive`
- **Demonstration.** Read [`workflows/08-deploy-staging.yml`](../workflows/08-deploy-staging.yml) and [`workflows/09-environments.yml`](../workflows/09-environments.yml) on screen. Replay the lab replays `labs/ch20b/lab-27-2-artifact-digest.sh` (snippets `same-bytes`, `failure`, `recovery`), `labs/ch20b/lab-27-3-deploy-range.sh` (snippets `range`, `failure`, `recovery`) and `labs/ch20b/lab-27-4-promotion.sh` (snippets `waiting`, `failure`, `recovery`). Then: Screen walkthrough of the learner's own practice repository, following Lab 27.3 ("Deploy to staging (workflow 8)") in [`lab-manual/m27-build-package-deliver.md`](../lab-manual/m27-build-package-deliver.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors and Screen walkthrough of the learner's own practice repository, following Lab 27.4 ("Staging, then production behind an approval (workflow 9)") in [`lab-manual/m27-build-package-deliver.md`](../lab-manual/m27-build-package-deliver.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors. Never show a real secret value.
- **Diagrams.** Redraw the diagram of section 20B.2; show the root-cause box of section 20B.4.
- **Practical exercise.** Lab 27.3 ("Deploy to staging (workflow 8)") in [`lab-manual/m27-build-package-deliver.md`](../lab-manual/m27-build-package-deliver.md)
- **Challenge.** Exercise 27.2 (Level 3, "A deployment with five flaws") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q303: "A job names `environment: production`. List everything that must be true on GitHub, outside the workflow file, for that to be a real gate."
- **Homework.** Read sections 20B.1 to 20B.4. Do Lab 27.4 ("Staging, then production behind an approval (workflow 9)") in [`lab-manual/m27-build-package-deliver.md`](../lab-manual/m27-build-package-deliver.md); then Exercise 27.1 (Level 1, "An environment, read back") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md) and Exercise 27.4 (Level 3, "A guard against going backwards") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner can take a change from commit to a gated staging and production deployment and say what protects each step.

### V150: Concurrency groups, reusable workflows, composite actions and container actions

- **Title.** Concurrency groups, reusable workflows, composite actions and container actions
- **Learning objectives.** After this video the learner can:
  - Predict which of several queued runs deploy under a concurrency group, with and without cancellation
  - Choose between a reusable workflow, a composite action and a container action
  - Explain what each choice does to the names of required checks
  - Say why a caller cannot pass an environment secret to a reusable workflow and where it must be read
  - Explain which version of a reusable workflow a caller runs
- **Prerequisites.** V149
- **Concepts.** By default a concurrency group has at most one run in progress and one pending; a newly queued run cancels the one already pending. `cancel-in-progress` and `queue` change that. Reuse: a reusable workflow is a whole job graph called with `uses` at job level; a composite action is a sequence of steps; a container action runs in an image. The ref after `@` decides which version runs.
- **Commands.** `git grep -n`; `git diff --stat`
- **Demonstration.** Read [`workflows/11-caller.yml`](../workflows/11-caller.yml) and [`workflows/11-reusable-workflow.yml`](../workflows/11-reusable-workflow.yml) on screen. Replay the lab replay `labs/ch20b/lab-27-5-reusable-ref.sh` (snippets `two-versions`, `failure`, `recovery`). Then: Screen walkthrough of the learner's own practice repository, following Lab 27.5 ("A reusable workflow and its caller (workflow 11)") in [`lab-manual/m27-build-package-deliver.md`](../lab-manual/m27-build-package-deliver.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** Redraw the diagram of section 20B.5: three runs arriving at one group, one running, one pending, one cancelled.
- **Practical exercise.** Lab 27.5 ("A reusable workflow and its caller (workflow 11)") in [`lab-manual/m27-build-package-deliver.md`](../lab-manual/m27-build-package-deliver.md)
- **Challenge.** Exercise 27.5 (Level 3, "Four reusable-workflow surprises") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q286: "Three merges land on `main` within five minutes and the deploy workflow uses `concurrency: production`. Which runs deploy, and why?"
- **Homework.** Read sections 20B.5 and 20B.6. Do Exercise 27.3 (Level 2, "Three pushes in ten minutes") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner serializes deployments correctly and shares workflow logic without breaking required checks.

### V151: Publishing a container image, and release automation in outline

- **Title.** Publishing a container image, and release automation in outline
- **Learning objectives.** After this video the learner can:
  - Make a container image identify the commit it was built from
  - Explain why a release created by the workflow's own token triggers no further workflow
  - Derive the version of a release from a tag in CI and say what the checkout needs for that
  - Outline release automation as the section gives it
- **Prerequisites.** V130, V150
- **Concepts.** An image is identified by its digest, not by a tag; deploy by digest and record digest and commit together. Events caused by the job token do not start new workflow runs, with narrow exceptions. A tag-driven release needs the tag and enough history for `git describe`.
- **Commands.** `git describe --tags --match`; `git status --short`; `gh release create`
- **Demonstration.** Replay the lab replay `labs/ch20b/lab-27-1-image-identity.sh` (snippets `identity`, `failure`, `recovery`). Then: Screen walkthrough of the learner's own practice repository, following Lab 27.1 ("A container image that identifies its commit (workflow 6)") in [`lab-manual/m27-build-package-deliver.md`](../lab-manual/m27-build-package-deliver.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** New: commit -> build -> image digest -> deployment, with the commit ID written on every arrow.
- **Practical exercise.** Lab 27.1 ("A container image that identifies its commit (workflow 6)") in [`lab-manual/m27-build-package-deliver.md`](../lab-manual/m27-build-package-deliver.md)
- **Challenge.** Exercise 27.6 (Level 3, "The release that triggers nothing") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q305: "Design the path from a merge on `main` to production for a backend service such that the bytes that were tested are the bytes that are deployed, no test or build code runs in a job that holds a deployment credential, and two production deployments never overlap. Defend each decision."
- **Homework.** Read section 20B.7. Do Lab 27.2 ("One build, carried between jobs (workflow 7)") in [`lab-manual/m27-build-package-deliver.md`](../lab-manual/m27-build-package-deliver.md).
- **Expected outcome.** The learner can answer "which commit is running in production" from the artifact itself.

### V152: Runners, limits and billing, and the investigation order for a failing workflow

- **Title.** Runners, limits and billing, and the investigation order for a failing workflow
- **Learning objectives.** After this video the learner can:
  - Say what a GitHub-hosted runner is and why a `-latest` label is a moving target
  - State the risks of self-hosted runners and what "ephemeral" changes
  - State the limits and the billing model as the section gives them
  - Recite the investigation order: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency
  - Explain why the log is not the first thing to read
- **Prerequisites.** V151
- **Concepts.** A hosted runner is a fresh virtual machine from an image that changes. A self-hosted runner persists unless made ephemeral and runs whatever a workflow tells it. Limits and prices are quoted from section 20B.10 and re-verified on the recording day. The investigation order starts with "did the right workflow run on the right commit for the right event" because most failures are decided before the first log line.
- **Commands.** `gh run list --workflow`; `gh run view`; `gh workflow view`; `gh run download`; `gh cache list --key`; `git rev-parse`
- **Demonstration.** Replay the lab replay `labs/ch20b/lab-28-2-merge-ref.sh` (snippets `local`, `graph`, `merge-commit`, `failure`, `recovery`, `verify`): the investigation order applied to a run that tested another commit than the author's. Then: Screen walkthrough of the learner's own practice repository, following Lab 28.2 ("The investigation order, applied to a failing run") in [`lab-manual/m28-runners-debugging-ci.md`](../lab-manual/m28-runners-debugging-ci.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** New: the twelve-step investigation order as a vertical list with the question each step answers.
- **Practical exercise.** Lab 28.2 ("The investigation order, applied to a failing run") in [`lab-manual/m28-runners-debugging-ci.md`](../lab-manual/m28-runners-debugging-ci.md)
- **Challenge.** Exercise 28.4 (Level 2, "What does this pipeline cost?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q290: "In which order do you investigate a failed run, and why is the log not first?"
- **Homework.** Read sections 20B.8 to 20B.11. Do Exercise 28.1 (Level 1, "Where in the order?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner investigates a failed run in a fixed order and reads the log only after knowing what ran.

### V153: "Passes locally, fails on GitHub Actions": the documented causes

- **Title.** "Passes locally, fails on GitHub Actions": the documented causes
- **Learning objectives.** After this video the learner can:
  - List the documented causes of a test that passes on a Mac and fails on the runner
  - Prove a case-sensitivity cause with Git alone
  - Prove a line-ending cause with `git ls-files --eol` and fix it with attributes
  - Prove a shallow-clone cause and give the minimal fix
  - Explain why "same commit" is not the same input
- **Prerequisites.** V014, V087, V145, V152
- **Concepts.** The runner differs in filesystem, operating system, tool versions, history depth, tags, environment and, on pull requests, in the commit itself. Each cause has a Git-side test that needs no rerun of the workflow.
- **Commands.** `git ls-files`; `git mv`; `git ls-files --eol`; `git add --renormalize`; `git clone --quiet --depth`; `git describe --tags --match`; `git fetch --quiet --unshallow --tags`; `git rev-parse --is-shallow-repository`
- **Demonstration.** Replay `labs/ch20b/case-clash.sh` (snippets `works-here`, `what-linux-sees`, `fix`, `two-names`), `labs/ch20b/line-endings.sh` (snippets `symptom`, `eol`, `fix`, `working-tree`) and `labs/ch20b/shallow-describe.sh` (snippets `laptop`, `runner`, `tags-without-history`, `full-history`). For each, state the symptom as the developer would report it, then the one command that proves the cause.
- **Diagrams.** Show the root-cause box of section 20B.12. New: a two-column table "your Mac" and "the runner" for filesystem, checkout depth, tags, the commit tested and the shell.
- **Practical exercise.** Lab 28.1 ("Six broken workflows") in [`lab-manual/m28-runners-debugging-ci.md`](../lab-manual/m28-runners-debugging-ci.md)
- **Challenge.** Incident 7, [`incidents/07-ci-passes-locally`](../incidents/07-ci-passes-locally/SYMPTOMS.md)
- **Interview question.** Q301: "A test passes on a Mac and fails on `ubuntu-24.04` with a file-not-found error. How do you prove the cause with Git alone?"
- **Homework.** Read section 20B.12. Do Exercise 28.6 (Level 3, "The machine changed, the code did not") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner proves the cause of an environment-dependent failure before changing the workflow.

### V154: Required checks that stay pending, the debugging instruments, linting, and what a local emulator cannot reproduce

- **Title.** Required checks that stay pending, the debugging instruments, linting, and what a local emulator cannot reproduce
- **Learning objectives.** After this video the learner can:
  - Give the causes of a required check that waits forever and the design that avoids each
  - Diagnose six broken workflows, each with a different documented root cause
  - Use the instruments: failed-step logs, rerun with debug logging, watch, cache listing
  - Say exactly what `gh run rerun` re-runs and why that is dangerous for a deployment
  - Say what a linter finds before a push and what a local emulator cannot tell you
- **Prerequisites.** V132, V153
- **Concepts.** A check is required by name; a workflow that was filtered out never reports that name. Fixes: no path filter on the required workflow and a decision inside the job, or an aggregate job. A rerun uses the same commit and the same workflow file as the original run. Linting catches syntax and some expression errors; an emulator has no real token, environments, caches or runner image.
- **Commands.** `gh pr checks`; `gh run view`; `gh run rerun`; `gh run rerun --debug`; `gh run watch`; `gh cache list --key`; `gh workflow run`; `git diff --name-only`
- **Demonstration.** Replay the lab replay `labs/ch20b/lab-28-1-broken-workflows.sh` (snippets `shallow`, `paths`, `refs`, `cache-key`, `failure`, `recovery`); the six files are in `workflows/broken/` and are teaching material with faults on purpose. Then: Screen walkthrough of the learner's own practice repository, following Lab 28.1 ("Six broken workflows") in [`lab-manual/m28-runners-debugging-ci.md`](../lab-manual/m28-runners-debugging-ci.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, adding one broken workflow at a time to the practice repository.
- **Diagrams.** New: a pull request with a required check named X and two workflows, one that reports X and one filtered out, showing why the check stays "expected".
- **Practical exercise.** Lab 28.1 ("Six broken workflows") in [`lab-manual/m28-runners-debugging-ci.md`](../lab-manual/m28-runners-debugging-ci.md)
- **Challenge.** Exercise 28.7 (Level 5, "Every pull request is waiting") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q300: "A pull request shows "waiting for status to be reported" and no run exists. Name three causes and the design that avoids all of them."
- **Homework.** Read sections 20B.13 to 20B.18 and do the Practice section 20B.20. Do Exercise 28.3 (Level 3, "A required check that cannot be red") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md). Read [`guides/github-actions-guide.md`](../guides/github-actions-guide.md) and [`cheatsheets/github-actions-cheat-sheet.md`](../cheatsheets/github-actions-cheat-sheet.md).
- **Expected outcome.** The learner can unblock a stuck pull request and debug a failed run with the right instrument.

### V155: Gate briefing: Actions

- **Title.** Gate briefing: Actions
- **Learning objectives.** After this video the learner can:
  - State what Gate 7 covers and its threshold of 85
  - Explain the paper format of the hands-on part and the rule never to copy or run its workflow files
  - Prepare with the reading order for a workflow and the investigation order for a failure
  - Answer every question with the commit, the ref, the event and the permissions
- **Prerequisites.** V154
- **Concepts.** Gate 7 covers the workflow model, the first eleven workflows, runners and CI debugging. Part 3 is three cases on paper built from workflow files, described runs and real Git evidence; the workflow files there have faults on purpose. A strong answer names which commit was tested.
- **Commands.** `git rev-parse`; `git merge-base`; `git log --oneline --decorate`
- **Demonstration.** Replay `labs/ch20a/merge-ref.sh` (snippets `runner-checkout`, `what-is-checked-out`, `tests-on-the-merge`) as the warm-up. Show the rules for paper cases from [`assessments/README.md`](../assessments/README.md). Do not open the gate file or the case files on screen.
- **Diagrams.** New: a four-line answer frame: event, ref and commit, permissions, runner; then the finding.
- **Practical exercise.** Redo Exercise 26.6 (Level 3, "Caches and artifacts") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md), Exercise 27.2 (Level 3, "A deployment with five flaws") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md), Exercise 28.5 (Level 4, "Green here, red in a fresh clone") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md) and Exercise 28.7 (Level 5, "Every pull request is waiting") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Challenge.** Take Gate 7: [`assessments/gate-7-actions.md`](../assessments/gate-7-actions.md).
- **Interview question.** Q297: "A pull request's required checks went green yesterday afternoon. Since then `main` has received several merges, nothing was pushed to the pull request, and this morning an engineer re-ran the checks and they are green again. What exactly has been proven, and what closes the gap before merging?"
- **Homework.** Before the gate: answer the "Interview questions" sections of Chapters 20A and 20B aloud.
- **Expected outcome.** The learner sits Gate 7 able to read any workflow and reason about a failed run without access to it.

## Part 7: Security

Roadmap Level 7 (Modules 29 to 31), then the Security gate. 14 videos on GitHub Actions security, repository and supply-chain security, and the response to a committed secret. Attack mechanisms are taught from published post-mortems and from local models; nothing is run against a repository the learner does not own, and the vulnerable workflow files of the course are never executed.

### V156: The Actions security model in five parts, the job token, and permissions

- **Title.** The Actions security model in five parts, the job token, and permissions
- **Learning objectives.** After this video the learner can:
  - Describe the security model of a workflow run in the five parts the section names
  - Say what the job token can do when a workflow has no `permissions` key and what that depends on
  - Write least-privilege `permissions` for a job
  - Inventory the triggers, permissions, actions and secrets of a set of workflow files with local commands
- **Prerequisites.** V119, V155
- **Concepts.** Whose code runs, with which token, on which runner, with which secrets, started by whom. The `GITHUB_TOKEN` is created per job and expires with it; its default scope depends on a repository or organization setting. `permissions` at workflow or job level narrows it; naming one scope sets the others to none.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay the lab replay `labs/ch21a/lab-29-1-inventory.sh` (snippets `files`, `triggers`, `permissions`, `uses`, `secrets-and-tokens`); it reads the five files in `workflows/vulnerable/`, which are teaching material with faults on purpose and are never executed. Then: Screen walkthrough of the learner's own practice repository, following Lab 29.1 ("Find and fix five planted weaknesses") in [`lab-manual/m29-actions-security.md`](../lab-manual/m29-actions-security.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, only the step that inspects the default token setting of the practice repository.
- **Diagrams.** Redraw the diagram of section 21A.2.
- **Practical exercise.** Exercise 29.1 (Level 1, "Whose code, whose text, what can it reach?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Challenge.** Exercise 29.5 (Level 2, "What can this token do?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q306: "A workflow has no `permissions` key. What can its token do, and what does the answer depend on?"
- **Homework.** Read sections 21A.1 to 21A.3.
- **Expected outcome.** The learner can state, for any job, what its token may do and why.

### V157: Fork pull requests, the approval gate, and privileged triggers

- **Title.** Fork pull requests, the approval gate, and privileged triggers
- **Learning objectives.** After this video the learner can:
  - Explain why a fork pull request under `pull_request` gets no secrets and a read-only token, and what remains exposed
  - Say what the approval gate for first-time contributors does
  - Explain what `pull_request_target` and `workflow_run` change: whose workflow file, which token, which secrets
  - Name the step that turns a privileged trigger into a vulnerability
  - State when `pull_request_target` is the right trigger and what changes on 2 November 2026, as the section gives it
- **Prerequisites.** V116, V123, V156
- **Concepts.** `pull_request` from a fork runs the fork's code with reduced privilege. `pull_request_target` runs the base branch's workflow with the base repository's token and secrets; checking out and running the pull request's code inside it hands those to an outsider. `workflow_run` inherits privilege from its position, not from the triggering run.
- **Commands.** `gh pr checkout`
- **Demonstration.** Replay the lab replay `labs/ch21a/lab-29-1-inventory.sh` (snippets `triggers`, `narrow-scan`, `wide-scan`, `run-blocks`), reading the trigger and checkout lines of the vulnerable files together. No GitHub walkthrough: the mechanism is described from section 21A.5 and its sources, not reproduced.
- **Diagrams.** New: two lanes, `pull_request` and `pull_request_target`, each showing whose workflow file runs, which commit is checked out by default, which token and which secrets.
- **Practical exercise.** Lab 29.1 ("Find and fix five planted weaknesses") in [`lab-manual/m29-actions-security.md`](../lab-manual/m29-actions-security.md)
- **Challenge.** Exercise 29.2 (Level 3, "The comment workflow") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q312: "Explain a "pwn request" without using the word. Which step completes the vulnerability?"
- **Homework.** Read sections 21A.4 and 21A.5.
- **Expected outcome.** The learner can review a privileged trigger and say precisely which line would make it exploitable.

### V158: Script injection through untrusted event fields

- **Title.** Script injection through untrusted event fields
- **Learning objectives.** After this video the learner can:
  - Explain why `${{ }}` inside `run:` is code generation and not variable passing
  - List event fields an outsider controls
  - Fix an injection by passing the value through `env` and explain why the same value is then harmless
  - Find candidate injections in a set of workflows with a local search
  - Write the review comment a security engineer would write
- **Prerequisites.** V144, V157
- **Concepts.** An expression is substituted into the script text before the shell starts, so a pull request title becomes part of the program. Through `env` the value arrives as data in a variable and the shell never parses it as code. Titles, branch names, comment bodies and commit messages are attacker-controlled.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay the lab replay `labs/ch21a/lab-29-1-fixes.sh` (snippets `stat`, `diff-v1`, `diff-v2`, `diff-v3`, `diff-v4`, `diff-v5`, `verify-patterns`, `verify-scope`, `commit`), stopping at the diff that moves an expression from `run:` to `env:`.
- **Diagrams.** Redraw the diagram of section 21A.6; show the root-cause box of section 21A.6.
- **Practical exercise.** Lab 29.1 ("Find and fix five planted weaknesses") in [`lab-manual/m29-actions-security.md`](../lab-manual/m29-actions-security.md)
- **Challenge.** Exercise 29.3 (Level 3, "The release workflow") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q279: "Explain the difference between `run: echo "${{ github.event.pull_request.title }}"` and passing the title through `env`. When is each evaluated, and by what?"
- **Homework.** Read section 21A.6.
- **Expected outcome.** The learner spots an injectable expression at review speed and knows the one-line fix.

### V159: Third-party actions, mutable tags, commit pinning, and organization policies

- **Title.** Third-party actions, mutable tags, commit pinning, and organization policies
- **Learning objectives.** After this video the learner can:
  - Explain what `uses: owner/action@v4` trusts
  - Show locally that a tag can be moved to another commit without any change in the workflow that names it
  - Pin an action to a full commit ID and keep the pin current
  - Name three things pinning does not protect against
  - Say what organization policies for allowed actions can enforce
- **Prerequisites.** V081, V158
- **Concepts.** An action reference is resolved at run time. A tag is a movable ref under the action author's control or an attacker's; a full commit ID is content-addressed. Pins need updating, which Dependabot can do. Pinning does not vouch for the pinned code, its own dependencies or its downloads.
- **Commands.** `git ls-remote --tags`; `git push --force`; `git ls-remote`
- **Demonstration.** Replay `labs/ch21a/mutable-tag.sh` (snippets `resolve`, `move`, `after`); a local repository plays the action's repository. Then show how [`workflows/12-secure.yml`](../workflows/12-secure.yml) and [`workflows/ACTION_PINS.md`](../workflows/ACTION_PINS.md) record each pin with its version.
- **Diagrams.** New: a workflow line `uses: ...@v4` with an arrow to a tag, and the tag's arrow moving from one commit to another while the line stays the same.
- **Practical exercise.** Exercise 29.5 (Level 2, "What can this token do?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Challenge.** Exercise 29.8 (Level 5, "A workflow nobody wrote") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q321: "Your team pins every action to a commit. Name three things that this does not protect against."
- **Homework.** Read sections 21A.7 and 21A.8.
- **Expected outcome.** The learner pins actions by commit ID and can explain what that does and does not buy.

### V160: Secrets and why masking is not a boundary, OIDC federation, caches and artifacts as untrusted input, self-hosted runners, and environment protection

- **Title.** Secrets and why masking is not a boundary, OIDC federation, caches and artifacts as untrusted input, self-hosted runners, and environment protection
- **Learning objectives.** After this video the learner can:
  - Say who can read a repository, environment and organization secret and when
  - Explain why log masking does not protect a secret
  - Explain what `id-token: write` grants and where the access decision is made
  - Explain how a cache or an artifact written by a less trusted run can reach a privileged one
  - State why self-hosted runners and public repositories are a dangerous combination
- **Prerequisites.** V149, V159
- **Concepts.** Any step of a job that receives a secret can exfiltrate it; masking only edits log lines. OIDC replaces stored cloud keys by a short-lived token whose claims the cloud provider checks against a trust policy, so the policy's conditions are the control. Caches are shared across runs by scope rules. A persistent self-hosted runner keeps whatever a job left. Environment protection puts the gate in front of the job.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay the lab replay `labs/ch21a/lab-29-2-controls.sh` (snippets `baseline`, `break`, `detect`, `recover`), which removes controls from the secure workflow one at a time and shows which check notices. Then: Screen walkthrough of the learner's own practice repository, following Lab 29.2 ("Justify every control of workflow 12") in [`lab-manual/m29-actions-security.md`](../lab-manual/m29-actions-security.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** New: a job with a secret, three steps, and an arrow from the third step to "anywhere on the network"; beside it the OIDC exchange: runner token -> cloud provider -> trust policy -> short-lived credential.
- **Practical exercise.** Lab 29.2 ("Justify every control of workflow 12") in [`lab-manual/m29-actions-security.md`](../lab-manual/m29-actions-security.md)
- **Challenge.** Exercise 29.6 (Level 3, "Who can assume the role?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q313: "What does `id-token: write` grant, and where is the access decision made?"
- **Homework.** Read sections 21A.9 to 21A.13.
- **Expected outcome.** The learner designs secret access by exposure, prefers federation to stored keys, and treats caches and artifacts as input.

### V161: Static analysis of workflows, the platform changes of 2025 and 2026, workflow 12, AI agents in workflows, and a review checklist

- **Title.** Static analysis of workflows, the platform changes of 2025 and 2026, workflow 12, AI agents in workflows, and a review checklist
- **Learning objectives.** After this video the learner can:
  - Say what static analysis of workflows finds and what it cannot
  - State the platform changes of 2025 and 2026 that the section lists
  - Justify every control of workflow 12
  - State the risks of an AI agent inside a workflow as the section gives them
  - Review a pull request that changes workflows with the checklist
- **Prerequisites.** V160
- **Concepts.** Workflow 12 is the secure-by-default template: least-privilege permissions, pinned actions, no untrusted interpolation, no privileged trigger, timeouts. An agent in a workflow reads attacker-controlled text and holds a token. The checklist of section 21A.19 turns the module into review practice.
- **Commands.** `gh pr checkout`
- **Demonstration.** Replay `labs/ch21a/workflow-audit.sh` (snippets `trigger-permissions`, `uses`, `expressions`, `secrets`) on [`workflows/12-secure.yml`](../workflows/12-secure.yml), then the lab replay `labs/ch21a/lab-29-3-review.sh` (snippets `overview`, `diff-ci`, `diff-release`, `added-lines`, `wrong-base`). Then: Screen walkthrough of the learner's own practice repository, following Lab 29.3 ("Review a pull request that changes workflows") in [`lab-manual/m29-actions-security.md`](../lab-manual/m29-actions-security.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors.
- **Diagrams.** New: workflow 12 with each control bracketed and labelled with the attack class it answers.
- **Practical exercise.** Lab 29.3 ("Review a pull request that changes workflows") in [`lab-manual/m29-actions-security.md`](../lab-manual/m29-actions-security.md)
- **Challenge.** Exercise 29.7 (Level 3, "Benchmark scores on fork pull requests") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q319: "How do you secure GitHub Actions?"
- **Homework.** Read sections 21A.14 to 21A.17 and 21A.19 to 21A.22. Do the Practice section 21A.24.
- **Expected outcome.** The learner writes workflows that are secure by default and reviews others' workflows with a checklist.

### V162: Case studies in Actions security: what happened, root cause, lesson

- **Title.** Case studies in Actions security: what happened, root cause, lesson
- **Learning objectives.** After this video the learner can:
  - Retell each case of the section as what happened, root cause and lesson, with its flags
  - Assign each case to one of the recurring patterns
  - Name the control from this part that would have broken each chain
  - Trace how a fork pull request led to a publish without any stored credential being stolen
  - Quote dates and figures only as the cited sources give them
- **Prerequisites.** V161
- **Concepts.** The table of section 21A.18: tj-actions, Nx, GhostAction, Shai-Hulud, PyTorch runners and Ultralytics, Trivy and LiteLLM, TanStack, Codecov. Three recurring patterns: mutable references repointed after a credential theft; a privileged trigger that ran or interpolated outsider input; stolen tokens used to push workflows. No attack detail beyond the published summaries is reproduced.
- **Commands.** `git ls-remote --tags`
- **Demonstration.** Replay `labs/ch21a/mutable-tag.sh` (snippets `move`, `after`) once more as the local model of the first pattern. Everything else is a walk through the table of section 21A.18 with its source links on screen; read the "Flags" column aloud for every row.
- **Diagrams.** New: a three-column chart, one column per recurring pattern, with the cases placed under the patterns they show.
- **Practical exercise.** Exercise 29.2 (Level 3, "The comment workflow") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Challenge.** Exercise 29.8 (Level 5, "A workflow nobody wrote") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q332: "In the TanStack incident no credential was stolen from storage. Walk through how a fork pull request led to a publish, and name the control that would have broken each link."
- **Homework.** Read section 21A.18 and follow two of its source links to the published post-mortems. Read [`guides/security-guide.md`](../guides/security-guide.md).
- **Expected outcome.** The learner argues for each control with a real incident and without embellishing it.

### V163: The Git client: what a clone runs, the three guards, and recursive clones

- **Title.** The Git client: what a clone runs, the three guards, and recursive clones
- **Learning objectives.** After this video the learner can:
  - Explain why cloning an untrusted repository is generally safe and unpacking an archive of one is not
  - Explain "dubious ownership" and what `safe.directory` does and should not be set to
  - Say what `safe.bareRepository=explicit` refuses and which attack it answers
  - Explain `protocol.file.allow` and the risk of a recursive clone of an untrusted repository
  - Say what stars and popularity do and do not prove
- **Prerequisites.** V090, V091
- **Concepts.** A clone copies objects and refs, not hooks or local configuration; an unpacked copy of a working repository brings both. Git refuses to act in a repository owned by another user unless told it is safe. Embedded bare repositories. Submodule URLs are attacker-chosen input.
- **Commands.** `git clone --no-local`; `git config set --global --append`; `git config unset --global`; `git submodule add`
- **Demonstration.** Replay `labs/ch21b/client-safety.sh` (snippets `what-the-author-has`, `clone-copies-neither`, `unpacked-copy-runs-both`, `dubious-ownership`, `safe-directory`, `bare-repository`, `file-protocol`).
- **Diagrams.** Redraw the diagram of section 21B.2.
- **Practical exercise.** Exercise 30.1 (Level 1, "What could that have run?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Challenge.** Exercise 30.7 (Level 5, "The reproduction package") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q308: "Explain why `git clone` of an untrusted repository is generally safe and why unpacking a tarball of the same repository is not. Name the files involved."
- **Homework.** Read sections 21B.2 to 21B.4.
- **Expected outcome.** The learner handles untrusted repositories and archives with the right amount of suspicion.

### V164: Credentials and what a stolen one can reach, and why deleting, force-pushing and going private do not remove a secret

- **Title.** Credentials and what a stolen one can reach, and why deleting, force-pushing and going private do not remove a secret
- **Learning objectives.** After this video the learner can:
  - Rank credential types by what a thief can reach with each
  - Explain why a secret deleted in a later commit is still in the repository
  - Say where a force-pushed-away commit can still be found
  - Find a secret in every ref of a repository with built-in commands
  - Say which refs and tags contain the secret
- **Prerequisites.** V069, V116, V163
- **Concepts.** The credential hierarchy from a job-scoped token to a classic token with broad scopes. Deletion adds a commit; the old blob stays reachable. A forced push leaves the commit in clones, forks, pull request refs and cached views. Making a repository private changes who can read from now on. The pickaxe, `git grep` over all commits, `--contains`.
- **Commands.** `git log --oneline --all -S`; `git log --all -G`; `git grep -n`; `git rev-list --all`; `git branch -a --contains`; `git tag --contains`; `git rm --cached`
- **Demonstration.** Replay `labs/ch21b/find-secret.sh` (snippets `the-leak`, `delete-is-not-removal`, `pickaxe`, `pickaxe-patch`, `regex`, `grep-all-commits`, `which-refs`, `server-still-has-it`); the secret in the script is a dummy string made for the lab.
- **Diagrams.** Show the root-cause box of section 21B.10. New: one leaked commit and every place a copy may live: server ref, old pull request ref, a fork, two clones, a CI log.
- **Practical exercise.** Lab 30.3 ("Scan a full history for planted secrets") in [`lab-manual/m30-repository-security.md`](../lab-manual/m30-repository-security.md)
- **Challenge.** Exercise 30.5 (Level 3, "Six leaked credentials") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q327: "Rank the credentials an automation could use to push to a repository by blast radius, and justify the order."
- **Homework.** Read sections 21B.8 to 21B.11. Do Exercise 31.1 (Level 1, "Three things that are not removal") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner stops saying "I removed it" about a secret and can measure where it is.

### V165: Secret scanning and push protection and what they do not cover, Dependabot, code scanning, and a way to report vulnerabilities

- **Title.** Secret scanning and push protection and what they do not cover, Dependabot, code scanning, and a way to report vulnerabilities
- **Learning objectives.** After this video the learner can:
  - Say what secret scanning and push protection do and name kinds of leak they do not stop
  - Model a push-time check locally and show why deleting the file does not unblock the push
  - Remove a secret from unpushed commits so that the push is accepted
  - Write a Dependabot configuration for a Python project, Docker and Actions
  - Say what code scanning and private vulnerability reporting add
- **Prerequisites.** V089, V164
- **Concepts.** Push protection inspects pushed commits for known patterns and blocks the push; the fix is to rewrite the unpushed commits, not to add a deleting commit. It does not know unknown formats or secrets that reach the repository another way. Dependabot: alerts, security updates, version updates. A security policy file gives reporters a contact.
- **Commands.** `git grep -q -E`; `git diff --cached`; `git reset -q --soft`; `git rm -q`
- **Demonstration.** Replay `labs/ch21b/push-guard.sh` (snippets `install-server-hook`, `push-blocked`, `deleting-does-not-unblock`, `rewrite-unpushed-commits`, `client-hook`, `client-hook-bypassed`); a server-side hook on a local bare repository models the mechanism and is not GitHub's implementation. Then the lab replays `labs/ch21b/lab-30-1-push-check.sh` and `labs/ch21b/lab-30-2-dependabot.sh` (snippets `file`, `parse`). Then: Screen walkthrough of the learner's own practice repository, following Lab 30.1 ("Push protection, and what a push-time check catches") in [`lab-manual/m30-repository-security.md`](../lab-manual/m30-repository-security.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, with the dummy pattern the lab prescribes and never a real credential.
- **Diagrams.** New: a push of three commits with the secret in the first; a new deleting commit on top still fails, the rewritten series passes.
- **Practical exercise.** Lab 30.1 ("Push protection, and what a push-time check catches") in [`lab-manual/m30-repository-security.md`](../lab-manual/m30-repository-security.md)
- **Challenge.** Exercise 30.6 (Level 3, "A baseline for a new ML repository") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q316: "Push protection is enabled for all your users. Name three kinds of leak it will not stop."
- **Homework.** Read sections 21B.12 and 21B.13. Do Lab 30.2 ("A Dependabot configuration") in [`lab-manual/m30-repository-security.md`](../lab-manual/m30-repository-security.md); then Exercise 30.3 (Level 2, "Blocked or not?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md) and Exercise 30.4 (Level 1, "The baseline of a public repository") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner sets up layered defences for a repository and knows what each layer misses.

### V166: Responding to a leaked secret: six steps in this order, and the case studies

- **Title.** Responding to a leaked secret: six steps in this order, and the case studies
- **Learning objectives.** After this video the learner can:
  - Recite the six steps in order: contain, assess, eradicate, recover, communicate, prevent
  - Explain why revocation comes first and why it may be sufficient
  - Produce the five facts of an assessment and say which of them Git can answer
  - Decide whether a history rewrite is warranted
  - Retell two case studies as exposure, root cause and lesson, quoting figures as the cited sources give them
- **Prerequisites.** V165
- **Concepts.** The damage happens at the issuer, where the key is accepted; revocation is the only step that works against every copy. Assessment: which secret and its reach, first commit and first push, which refs, who could read, whether it was used according to the provider's logs. The case table of section 21B.15 and its note on partially confirmed details.
- **Commands.** `git diff --cached`
- **Demonstration.** Replay the lab replay `labs/ch21b/lab-31-1-tabletop.sh` (snippets `confirm`, `contain`, `assess`), stopping before the eradication steps, which the next two videos teach.
- **Diagrams.** New: the six steps as a horizontal track with "the key stops working here" marked at step 1 and "Git can answer" marked on two of the five assessment facts.
- **Practical exercise.** Exercise 31.2 (Level 2, "Fix the order") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Challenge.** Exercise 31.3 (Level 2, "Rewrite or not?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q324: "How do you investigate a leaked secret?"
- **Homework.** Read sections 21B.14 and 21B.15. Read [`cheatsheets/security-cheat-sheet.md`](../cheatsheets/security-cheat-sheet.md).
- **Expected outcome.** The learner leads the first hour of a secret leak in the right order.

### V167: History rewriting as an operation, and its mechanics seen locally

- **Title.** History rewriting as an operation, and its mechanics seen locally
- **Learning objectives.** After this video the learner can:
  - Say what a whole-history rewrite replaces and why the command is the smallest part of the work
  - State what git-filter-repo requires and records, as the section gives it from the tool's manual
  - Follow the mechanics locally: fresh mirror clone, all refs, new IDs, old objects that remain, pruning, the forced push
  - Explain what happens to signatures and to open pull requests
  - List the costs that decide against a rewrite
- **Prerequisites.** V052, V079, V166
- **Concepts.** The first affected commit and every descendant get new IDs. git-filter-repo is a separate program and is not installed in the lab; GitHub's documented sequence is shown without output. The local replay shows the same mechanics with a built-in command so that the effects on refs and objects can be seen; it does not recommend that command. One statement about the `origin` remote is marked unverified in the section and is said so on screen.
- **Commands.** `git clone -q --mirror`; `git for-each-ref`; `git push --force --mirror`; `git gc --prune`; `git reflog expire --expire`; `git log --all --name-status --`; `git cat-file -t`
- **Demonstration.** Replay `labs/ch21b/rewrite-mechanics.sh` (snippets `fresh-mirror-clone`, `branches-only`, `all-refs`, `new-ids`, `old-objects-remain`, `prune`, `force-push`, `server-keeps-old-objects`). Give the five answers for a dangerous command before `force-push`. Show GitHub's documented sequence from section 21B.16 as a slide, without output.
- **Diagrams.** Redraw the diagram of section 21B.17.
- **Practical exercise.** Lab 31.1 ("The tabletop: a committed secret, from report to prevention") in [`lab-manual/m31-secret-leak-response.md`](../lab-manual/m31-secret-leak-response.md)
- **Challenge.** Exercise 31.5 (Level 4, "How far did it get?") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q336: "When is a history rewrite the wrong response to a leaked secret? What does it cost?"
- **Homework.** Read sections 21B.16 and 21B.17. Do Exercise 31.4 (Level 3, "Review this runbook") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner can plan a history rewrite as an operation with owners, order and verification, and can argue when not to do it.

### V168: The stale clone that pushes the secret back, the GitHub side of a rewrite, and the controls that limit blast radius

- **Title.** The stale clone that pushes the secret back, the GitHub side of a rewrite, and the controls that limit blast radius
- **Learning objectives.** After this video the learner can:
  - Reconstruct from the commit graph how a secret returns after a rewrite without any forced push
  - Tell collaborators exactly what to do with their clones
  - Explain what happens to a stale clone under `git pull --rebase` and under a plain pull
  - Say what remains on GitHub after the forced push and what a Support request covers, as the section gives it
  - Name the governance controls that limit how far a leaked credential reaches
- **Prerequisites.** V059, V167
- **Concepts.** A clone that still has the old history merges or rebases it back and pushes it as ordinary new commits. Recovery of a clone: re-clone, or reset to the new history and carry over only one's own commits with `--onto`. GitHub, not Git: pull request refs, forks and cached views. Controls: rules on the default branch, least-privilege tokens, short-lived credentials.
- **Commands.** `git pull --rebase`; `git pull --no-rebase`; `git rebase --onto`; `git rebase --abort`; `git fetch --prune --tags`; `git log --oneline --graph`
- **Demonstration.** Replay `labs/ch21b/rewrite-mechanics.sh` (snippets `stale-clone`, `secret-is-back`) and `labs/ch21b/stale-clone-rebase.sh` (snippets `pull-rebase-first-contact`, `fetch-then-rebase`, `onto-old-base`). Then the rest of the lab replay `labs/ch21b/lab-31-1-tabletop.sh`, from `eradicate-tip` to the end.
- **Diagrams.** Redraw the diagram of section 21B.18; show the root-cause box of section 21B.18.
- **Practical exercise.** Lab 31.1 ("The tabletop: a committed secret, from report to prevention") in [`lab-manual/m31-secret-leak-response.md`](../lab-manual/m31-secret-leak-response.md), complete, as a tabletop with a dummy secret.
- **Challenge.** Incident 3, [`incidents/03-committed-secret`](../incidents/03-committed-secret/SYMPTOMS.md)
- **Interview question.** Q335: "A day after a history rewrite the secret is back on `main` and nobody force-pushed. Reconstruct what happened from the commit graph, and describe the fix for the server and for the clone."
- **Homework.** Read sections 21B.18 to 21B.23 and do the Practice section 21B.25. Do Exercise 31.6 (Level 3, "The secret came back") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md).
- **Expected outcome.** The learner closes a secret-leak response without the secret coming back.

### V169: Gate briefing: Security

- **Title.** Gate briefing: Security
- **Learning objectives.** After this video the learner can:
  - State what Gate 8 covers and its threshold of 90
  - Explain the paper format and the rule never to copy or run its workflow files
  - Prepare the two procedures: the workflow review checklist and the six-step leak response
  - Answer with blast radius: what could this credential or this job reach
- **Prerequisites.** V162, V168
- **Concepts.** Gate 8 covers Actions security, repository security and secret-leak response. Part 3 is on paper. Order is scored: an answer that rewrites history before revoking loses the points for the case, whatever else it gets right.
- **Commands.** `git log --oneline --all -S`; `git grep -n`
- **Demonstration.** Replay `labs/ch21b/find-secret.sh` (snippets `pickaxe`, `which-refs`) as the warm-up. Show the rules for paper cases from [`assessments/README.md`](../assessments/README.md). Do not open the gate file or the case files on screen.
- **Diagrams.** New: one slide with two lists side by side: the review checklist headings and the six response steps.
- **Practical exercise.** Redo Exercise 29.8 (Level 5, "A workflow nobody wrote") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md), Exercise 30.7 (Level 5, "The reproduction package") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md) and Exercise 31.7 (Level 5, "Lead the response") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md), the Level 5 exercises of the block.
- **Challenge.** Take Gate 8: [`assessments/gate-8-security.md`](../assessments/gate-8-security.md).
- **Interview question.** Q334: "You may enable one organization-level control today. Which one, and why?"
- **Homework.** Before the gate: answer the "Interview questions" sections of Chapters 21A and 21B aloud.
- **Expected outcome.** The learner sits Gate 8 able to review a workflow for the known vulnerability classes and to lead a leak response.

## Part 8: Professional practice

Roadmap Level 8 (Modules 32 to 34), then the design review. 10 videos on the fork workflow as practised in open source, branching and release strategy, the reasons behind team practices, and AI/ML repositories. The level ends with a design review in place of a gate.

### V170: The fork workflow in practice: syncing when upstream moves, etiquette, and the maintainer's side

- **Title.** The fork workflow in practice: syncing when upstream moves, etiquette, and the maintainer's side
- **Learning objectives.** After this video the learner can:
  - Set up the three repositories and two remotes of the fork workflow from the command line
  - Sync a fork's default branch in three ways and update a topic branch in two, and say what each does to history
  - Repair a fork whose `main` has stray commits without losing them
  - Respond to a review round on a rebased branch so that the reviewer can see what changed
  - Apply the etiquette of section 27.4 as contributor and as maintainer
- **Prerequisites.** V058, V127, V169
- **Concepts.** Never commit on the fork's `main`: it should only ever fast-forward to upstream. Update a pull request branch by rebase or by merge according to the project's convention. After a squash merge upstream, the local branch is not "merged" by ancestry. Read CONTRIBUTING first, open an issue first, keep pull requests small: maintainers' time is the scarce resource.
- **Commands.** `gh repo fork`; `git remote add`; `git merge --ff-only`; `git pull --ff-only`; `git rebase`; `git push --force-with-lease --force-if-includes`; `git range-diff`; `git rev-list --left-right --count`; `gh repo sync`; `git branch --merged`
- **Demonstration.** Replay `labs/ch27/fork-sync.sh` (snippets `clone-fork`, `branch-commit-push`, `upstream-moved`, `sync-main`, `update-by-rebase`, `update-by-merge`, `review-round`, `after-squash-merge`). GitHub side: Screen walkthrough of the learner's own practice repository, following Lab 21.1 ("A full fork and pull request cycle") in [`lab-manual/m21-pull-requests-forks.md`](../lab-manual/m21-pull-requests-forks.md). The GitHub interface changes, so narrate what the learner sees and name each control by its function; no GitHub output was captured by the authors, repeated once with the roles exchanged, so that the learner is the maintainer.
- **Diagrams.** Redraw the diagram of section 27.2; show the root-cause box of section 27.3.
- **Practical exercise.** Exercise 21.5 (Level 3, "The fork that cannot be synced") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Challenge.** Exercise 34.6 (Level 5, "The contributor who was never answered") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Interview question.** Q344: "Your fork's `main` is two commits ahead of and forty behind upstream. How did that happen, and how do you repair it without losing the two commits?"
- **Homework.** Read sections 27.1 to 27.4. Read the CONTRIBUTING file of one project you use and note what it asks before a first pull request.
- **Expected outcome.** The learner contributes to an open-source project without creating work for its maintainers.

### V171: Branch names as conventions, GitHub Flow, Git Flow and its author's 2020 note, GitLab Flow, trunk-based development and release branches

- **Title.** Branch names as conventions, GitHub Flow, Git Flow and its author's 2020 note, GitLab Flow, trunk-based development and release branches
- **Learning objectives.** After this video the learner can:
  - Explain why `main`, `develop`, `feature/*`, `hotfix/*` and `release/*` are conventions and what gives a name force
  - Describe GitHub Flow and what it assumes about deployment
  - Describe Git Flow and state what its author wrote about it in 2020
  - Describe trunk-based development and release branches
  - Draw the graph each model produces for one release and one hotfix
- **Prerequisites.** V036, V082, V170
- **Concepts.** Git gives no meaning to a branch name; rules, automation and habit do. GitHub Flow: one long-lived branch, short branches, deploy from `main`. Git Flow: `develop`, release and hotfix branches, merges in two directions; its author's 2020 note restricts where it fits. Trunk-based development: very short branches or none, release branches cut from trunk.
- **Commands.** `git log --oneline --graph --decorate --all`
- **Demonstration.** Replay `labs/ch27/git-flow.sh` (snippets `release-branch`, `hotfix`, `graph`, `what-ships`). Draw the other models from the four diagrams of section 27.8.
- **Diagrams.** Redraw the diagram of section 27.6 and the diagrams of section 27.8 (the diagram of section 27.8).
- **Practical exercise.** Exercise 32.1 (Level 1, "Names and what gives them force") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Challenge.** Exercise 32.2 (Level 2, "Six teams, which model?") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Interview question.** Q350: "A new engineering manager wants to standardize on Git Flow for your continuously deployed hosted service because it is "the industry standard". What does Git Flow prescribe, what does its own author say about it, and what do you propose instead?"
- **Homework.** Read sections 27.5 to 27.8. Read `git help workflows` as the section recommends.
- **Expected outcome.** The learner can describe the common models precisely and no longer treats any of them as a standard.

### V172: One release and one hotfix under two strategies, and which way a fix travels

- **Title.** One release and one hotfix under two strategies, and which way a fix travels
- **Learning objectives.** After this video the learner can:
  - Run one release and one hotfix under GitHub Flow and under a release-branch strategy and compare the histories
  - Say what ships in each case and prove it from tags
  - State the two conventions for the direction of a fix and the invariant each lets you test
  - Detect a fix that was forgotten on one line of development
  - Explain what goes wrong when both directions are mixed in one repository
- **Prerequisites.** V063, V171
- **Concepts.** Under GitHub Flow a hotfix is the next deployment of `main`. With release branches a fix must exist on two lines. Convention one: fix on the oldest supported branch and merge upward; the invariant is that each release branch is an ancestor of the next. Convention two: fix on `main` and backport with `-x`; the invariant is checked through patch IDs and recorded trailers.
- **Commands.** `git cherry-pick -x`; `git merge --no-ff -m`; `git merge-base --is-ancestor`; `git log --oneline --cherry-pick --right-only --no-merges`; `git branch --contains`; `git log --oneline --graph --decorate --all`
- **Demonstration.** Replay `labs/ch27/github-flow.sh` (snippets `release`, `main-moves-on`, `hotfix`, `graph`, `what-ships`), `labs/ch27/release-branch.sh` (snippets `cut`, `main-moves-on`, `fix-on-main`, `backport`, `graph`, `what-ships`, `where-is-the-fix`), `labs/ch27/fix-direction.sh` (snippets `start`, `merge-upward`, `one-commit`, `pick-down`, `two-commits`, `forgotten`, `detect`) and `labs/ch27/mixed-directions.sh` (snippets `second-fix-on-release`, `merge-upward-conflicts`).
- **Diagrams.** Show the root-cause box of section 27.10. New: two release lines and `main`, drawn twice: with upward merges, and with downward picks joined by dashed "same change" lines.
- **Practical exercise.** Lab 32.1 ("One release and one hotfix under two strategies") in [`lab-manual/m32-branching-release-strategy.md`](../lab-manual/m32-branching-release-strategy.md)
- **Challenge.** Exercise 32.5 (Level 4, "Which fix is missing?") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Interview question.** Q346: "State the two conventions for the direction of a fix. For each, give the invariant you can test and one way the test can mislead you."
- **Homework.** Read sections 27.9 and 27.10. Do Exercise 32.3 (Level 2, "What does the patch release contain?") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md) and Exercise 32.4 (Level 3, "Two directions, one repository") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md).
- **Expected outcome.** The learner can run a release and a hotfix under either strategy and test that no fix is missing.

### V173: Feature flags, merge queues and stacked changes, what the evidence shows, and choosing by context

- **Title.** Feature flags, merge queues and stacked changes, what the evidence shows, and choosing by context
- **Learning objectives.** After this video the learner can:
  - Explain what a feature flag separates and what it costs
  - Say what a merge queue guarantees that "require branches to be up to date" does not
  - State what the DORA research shows about trunk-based development, how it was measured, and what it does not show
  - Recommend a workflow for a described team and state the evidence for and against
  - Say it to a CTO in four sentences
- **Prerequisites.** V126, V129, V172
- **Concepts.** A flag separates deployment from release and adds states to test and flags to remove. Queues and stacks address integration at scale. Evidence: correlation from surveys is not a controlled comparison; say what is known and stop there. Choice by context: how the product is delivered, how many versions are supported, team size, regulation.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay the lab replay `labs/ch27/lab-32-1-two-strategies.sh` (snippets `flow-result`, `rb-result`, `compare`) as the evidence a recommendation can point at: the same work, two histories. The rest of the video is the decision table of section 27.14.
- **Diagrams.** Redraw the diagram of section 27.11 and the diagram of section 27.12. New: the table of section 27.14 with one described team placed in it live.
- **Practical exercise.** Exercise 32.2 (Level 2, "Six teams, which model?") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Challenge.** Exercise 32.7 (Level 5, "The regression in 3.0") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Interview question.** Q340: "A colleague says the DORA research proves trunk-based development is best. What does it show, how was it measured, and what would you say instead?"
- **Homework.** Read sections 27.11 to 27.14. Do Exercise 32.6 (Level 3, "Say it to a CTO") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md).
- **Expected outcome.** The learner recommends a branching strategy from a team's context and is honest about what the research does not prove.

### V174: Practices with their reasons, anti-patterns with their root causes, code review, and commit message conventions

- **Title.** Practices with their reasons, anti-patterns with their root causes, code review, and commit message conventions
- **Learning objectives.** After this video the learner can:
  - Give the mechanism behind each practice: small commits, meaningful messages, protected `main`, required checks, no force push on shared branches
  - Give the root cause behind each anti-pattern the section lists
  - Show with a transcript what a small commit buys at revert time
  - Query commit messages as data: by trailer, by type, by issue
  - Finalize a personal and a team configuration from the worksheet of Module 5
- **Prerequisites.** V028, V090, V173
- **Concepts.** A practice without its reason is a ritual and is dropped under pressure. Small commits make revert, bisect and review cheap. Messages are a database if they follow a convention; Conventional Commits and trailers. Review as a practice: what the reviewer checks and what automation should check.
- **Commands.** `git revert --no-edit`; `git merge-tree --write-tree --name-only`; `git log --oneline --grep`; `git log --format`; `git interpret-trailers`; `git shortlog -sn`; `git format-patch`
- **Demonstration.** Replay `labs/ch27/practices.sh` (snippets `inspect`, `merge`, `revert-one`, `revert-squashed`, `messages-as-data`), then the lab replay `labs/ch27/lab-34-1-design-review-evidence.sh` (snippets `branches`, `releases`, `fix-direction`, `integration`, `history-content`, `people-and-messages`, `squash-trap`, `content-check`). Show `labs/ref/professional-config.sh` again and compare it with the worksheet from V028 and the proposal from V090.
- **Diagrams.** New: a two-column table "practice" and "what breaks without it", filled from section 27.15, and a second table "anti-pattern" and "root cause" from section 27.16.
- **Practical exercise.** Exercise 34.1 (Level 1, "The reason behind the rule") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Challenge.** Exercise 34.4 (Level 3, "Review these four pull requests") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Interview question.** Q343: "Give the mechanism behind three of your team's practices: why small commits, why no force push on shared branches, why inspect before merging."
- **Homework.** Read sections 27.15 to 27.21 and do the Practice section 27.23. Do Exercise 34.2 (Level 2, "Anti-patterns and the model behind them") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md) and Exercise 34.3 (Level 2, "Messages as data") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md). Read [`reference/professional-git-configuration.md`](../reference/professional-git-configuration.md).
- **Expected outcome.** The learner can give the reason for every practice they follow and has a finished professional configuration.

### V175: What belongs in Git, notebooks, and a clean filter that strips outputs

- **Title.** What belongs in Git, notebooks, and a clean filter that strips outputs
- **Learning objectives.** After this video the learner can:
  - Decide for a file in an ML project whether it belongs in Git, is referenced from Git, or is ignored
  - Explain what a notebook file stores and why a rerun changes it without any edit
  - Show how a notebook leaks a secret or data through its outputs
  - Install a clean filter that strips outputs, mark it `required`, and verify it in CI
  - Say what nbdime, jupytext and ReviewNB add to the filter, as the section describes them
- **Prerequisites.** V088, V174
- **Concepts.** Source, configuration and lock files belong in Git; data, weights and outputs are referenced. A notebook is JSON holding code, outputs and execution counters, so diffs and merges are noisy and outputs can contain secrets. A clean filter stores the stripped form; the filter is per clone, so CI has to check that nothing unstripped arrived.
- **Commands.** `git diff --stat`; `git grep -n`; `git check-attr filter --`; `git add --renormalize`; `git cat-file -p`; `git status --short`
- **Demonstration.** Replay `labs/ch28/notebook-problem.sh` (snippets `anatomy`, `rerun`, `secret`, `merge`) and `labs/ch28/notebook-filter.sh` (snippets `the-filter`, `configure`, `add`, `rerun`, `real-change`, `required`, `clone`, `verify-in-ci`); the filter in the script is a small stand-in written for the lab, not one of the named tools.
- **Diagrams.** Show the root-cause box of section 28.3. New: a notebook cell as JSON with the three parts marked: source (keep), outputs (strip), execution count (strip).
- **Practical exercise.** Exercise 33.3 (Level 2, "The notebook that nobody edited") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Challenge.** Exercise 33.1 (Level 1, "In Git, or referenced from Git?") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Interview question.** Q362: "Your team "uses nbstripout", and a notebook with outputs is on `main`. How did it get there, and what do you change?"
- **Homework.** Read sections 28.1 to 28.5.
- **Expected outcome.** The learner keeps notebooks reviewable and free of outputs, and knows the filter is not a control until CI checks it.

### V176: Data and model versioning by reference, and reproducibility: the commit alone does not identify what ran

- **Title.** Data and model versioning by reference, and reproducibility: the commit alone does not identify what ran
- **Learning objectives.** After this video the learner can:
  - Version a dataset by committing a pointer and keeping the bytes elsewhere
  - Say what Git LFS, DVC and a hand-made pointer have in common and where they differ
  - List what a run record must contain besides the commit ID
  - Detect a dirty or untracked state at run time and record it
  - Reproduce a past result from its recorded identifiers
- **Prerequisites.** V097, V175
- **Concepts.** Git holds the reference; another system holds the bytes; the pointer's hash ties them together, and the store is the thing that can be lost. A commit ID does not identify a run when the tree was dirty, a file was untracked, dependencies floated, or the data moved. Lock files, container digests, resolved configuration.
- **Commands.** `git status --porcelain`; `git describe --always --dirty --tags`; `git rev-parse`; `git status --short --ignored`
- **Demonstration.** Replay `labs/ch28/data-pointer.sh` (snippets `add`, `new-version`, `store`, `time-travel`, `clone`, `store-is-the-risk`) and `labs/ch28/run-record.sh` (snippets `function`, `clean`, `run`, `dirty`, `same-commit`, `untracked`); the pointer mechanism in the script is a stand-in written for the lab. Then the lab replay `labs/ch28/lab-33-3-reproduce-result.sh` (snippets `today`, `read-record`, `worktree`, `rerun`).
- **Diagrams.** Redraw the diagram of section 28.6; show the root-cause box of section 28.7.
- **Practical exercise.** Lab 33.2 ("Version a dataset by reference") in [`lab-manual/m33-ai-ml-workflows.md`](../lab-manual/m33-ai-ml-workflows.md)
- **Challenge.** Exercise 33.7 (Level 5, "The number in the paper cannot be reproduced") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Interview question.** Q370: "A run in the tracker names a commit. You check it out and get a different metric. List every cause you can think of, in the order you would test them, and the evidence for each."
- **Homework.** Read sections 28.6 to 28.8. Do Lab 33.3 ("Reproduce a past result from its recorded identifiers") in [`lab-manual/m33-ai-ml-workflows.md`](../lab-manual/m33-ai-ml-workflows.md); then Exercise 33.4 (Level 3, "Three runs, one commit ID") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md) and Exercise 33.5 (Level 3, "The pointer and the file disagree") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md).
- **Expected outcome.** The learner can make any reported number reproducible and can say exactly why an old one is not.

### V177: .gitignore and .gitattributes for ML projects, pre-commit backed by CI, and a professional AI project repository

- **Title.** .gitignore and .gitattributes for ML projects, pre-commit backed by CI, and a professional AI project repository
- **Learning objectives.** After this video the learner can:
  - Write the ignore and attribute rules of an ML project and find which rule decides a path
  - Fix a checkpoint that is tracked although its pattern is ignored, and say what the fix leaves in history
  - Explain what a local pre-commit hook guarantees and three ways a commit bypasses it
  - Back every hook with a CI check
  - Build the professional AI project repository of section 28.12 from an empty folder
- **Prerequisites.** V012, V090, V176
- **Concepts.** Rules first, files second: add the ignore file before the first data file exists. The already-tracked trap applies to weights. The pre-commit framework manages hooks per clone; `--no-verify`, a fresh clone and a web edit all bypass them, so CI runs the same checks. The layout of section 28.12.
- **Commands.** `git check-ignore -v`; `git check-attr -a`; `git rm --cached`; `git ls-files`; `git status --short --ignored`; `git rev-list --objects --all`; `git commit -q --no-verify -m`
- **Demonstration.** Replay `labs/ch28/ml-ignore.sh` (snippets `which-rule`, `status`, `tracked-before-rule`, `untrack`), `labs/ch28/hooks-vs-ci.sh` (snippets `hook-blocks`, `no-verify`, `clone-has-no-hook`, `ci`) and `labs/ch28/project-skeleton.sh` (snippets `tracked`, `history`, `ignored`, `pointers`, `attributes`, `ignore-file`, `clone-setup`).
- **Diagrams.** Redraw the diagram of section 28.12.
- **Practical exercise.** Lab 33.1 ("Build a professional AI project repository from an empty folder") in [`lab-manual/m33-ai-ml-workflows.md`](../lab-manual/m33-ai-ml-workflows.md)
- **Challenge.** Exercise 33.2 (Level 2, "Eight paths and one ignore file") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Interview question.** Q364: "What does a local pre-commit hook guarantee? Name three ways a commit reaches the server without passing it, and the control for each."
- **Homework.** Read sections 28.9, 28.10 and 28.12.
- **Expected outcome.** The learner sets up an ML repository in which large files, outputs and secrets stay out by construction.

### V178: CI for ML projects, LLM evaluations and the fork model, model-serving repositories, secrets, and AI coding agents

- **Title.** CI for ML projects, LLM evaluations and the fork model, model-serving repositories, secrets, and AI coding agents
- **Learning objectives.** After this video the learner can:
  - Design CI for a Python ML project with a matrix and caches
  - Explain why LLM evaluations on fork pull requests collide with the fork security model and name the safe design
  - Make the case for and against self-hosted GPU runners
  - Say what a model-serving repository records about the model it serves
  - State which controls still hold when an AI coding agent opens pull requests
- **Prerequisites.** V157, V160, V177
- **Concepts.** Evaluations need a provider key, which is a secret; fork pull requests get no secrets; the dangerous workaround is a privileged trigger that runs the fork's code. GPU runners are persistent machines that execute pull request code. A serving repository pins the model by an immutable identifier. Secrets in AI repositories: provider keys, hub tokens, shared links. An agent is a contributor: rules, reviews and checks apply to it as to a person.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay the lab replay `labs/ch28/lab-33-1-ai-project-repo.sh` (snippets `checks`, `eval`, `serving`, `result`). Read [`exercises/workflows/x29-gpu-eval.yml`](../exercises/workflows/x29-gpu-eval.yml) on screen as a workflow to criticize; it is an exercise file with faults on purpose and is never run.
- **Diagrams.** Redraw the diagram of section 28.11.
- **Practical exercise.** Exercise 33.6 (Level 3, "Evaluate prompts in CI") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Challenge.** Exercise 29.7 (Level 3, "Benchmark scores on fork pull requests") in [`exercises/m26-m31-actions-security.md`](../exercises/m26-m31-actions-security.md)
- **Interview question.** Q374: "An open-source LLM project wants evaluations on pull requests from forks. Describe the collision, the dangerous workaround, and two designs you would defend."
- **Homework.** Read sections 28.11 and 28.13 to 28.18. Do the Practice section 28.20.
- **Expected outcome.** The learner can run evaluations in CI without opening the repository's secrets to outsiders.

### V179: Design review briefing: branching model, governance, CI and security policy for a described company

- **Title.** Design review briefing: branching model, governance, CI and security policy for a described company
- **Learning objectives.** After this video the learner can:
  - State what the design review asks for and how it is judged
  - Collect the evidence a design needs from an existing repository with read-only commands
  - Structure a design as decisions, each with its reason, its cost and the control that enforces it
  - Defend a design against objections without retreating to "best practice"
- **Prerequisites.** V134, V161, V174, V178
- **Concepts.** Level 8 ends with a design review in place of a gate: the learner designs the branching model, governance, CI and security policy for a described company and defends it. Each decision names the layer that enforces it: a habit, a client setting, a server rule, a review, a pipeline.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay the lab replay `labs/ch27/lab-34-1-design-review-evidence.sh` (snippets `branches`, `releases`, `fix-direction`, `integration`, `verify`) to show how the evidence for a design is gathered. Do not show a model design.
- **Diagrams.** New: a one-page design sheet with four blocks (branching, governance, CI, security) and under each three lines: decision, reason, enforced by.
- **Practical exercise.** Lab 34.1 ("The design review") in [`lab-manual/m34-practices-design-review.md`](../lab-manual/m34-practices-design-review.md)
- **Challenge.** Exercise 34.5 (Level 3, "The design review") in [`exercises/m32-m34-practice.md`](../exercises/m32-m34-practice.md)
- **Interview question.** Q353: "Design the branching and governance model for a regulated company that runs a continuously deployed hosted product and also sells an on-premises edition whose customers stay a version behind. What do you write down, and what do you tell an auditor who asks which branching model you follow?"
- **Homework.** Write the design for Lab 34.1 ("The design review") in [`lab-manual/m34-practices-design-review.md`](../lab-manual/m34-practices-design-review.md) in full and have a colleague or the tutor raise three objections. Read [`reference/command-safety.md`](../reference/command-safety.md).
- **Expected outcome.** The learner can design and defend a team's Git and GitHub setup as a whole.

## Part 9: Production debugging and incident response

Roadmap Level 9 (Modules 35 to 38), then the Production debugging gate. 15 videos: the diagnosis method on worked cases, the ten incidents, the three senior standards, and communication. Every incident video has a pause point: the learner generates the incident and attempts it before the debrief, because a drill whose cause has been seen cannot be repeated.

### V180: The diagnosis method, and worked case 1: the push that had nothing to push

- **Title.** The diagnosis method, and worked case 1: the push that had nothing to push
- **Learning objectives.** After this video the learner can:
  - State the method: symptom, state, evidence, hypotheses, test, root cause, lowest-risk fix, verification, prevention
  - Restate a colleague's report as a symptom without interpretation
  - Run the ten-command diagnosis on a repository in an unknown state and say what each output rules out
  - Write three hypotheses and the read-only command that separates them
  - Explain why no state-changing command is run before the root cause is named
- **Prerequisites.** V005, V053, V169
- **Concepts.** The method is the framework of Part 0 applied end to end with everything learned since. Worked case 1: a push that reports nothing to push while the work is not on the server. The evidence is read from status, refs, the reflog and the state files of an operation that was never finished.
- **Commands.** `git status`; `git branch -vv`; `git remote -v`; `git log --graph --decorate --oneline --all`; `git reflog`; `git rev-parse`; `git ls-remote origin`; `git push --dry-run`; `git rebase --abort`; `git cherry-pick`
- **Demonstration.** Replay `labs/ch29/case-unfinished-rebase.sh` (snippets `symptom`, `status`, `branch`, `remote`, `log`, `reflog`, `rev-parse`, `show`, `diff`, `config`, `ls-files`, `state-files`, `test`, `preserve`, `abort`, `pick`, `push`, `verify`). Stop after `state-files` and ask for three hypotheses before `test`.
- **Diagrams.** Redraw the diagram of section 29.2 and the diagram of section 29.3; show the root-cause box of section 29.3.
- **Practical exercise.** Lab 35.1 ("The ten-command diagnosis on three repositories") in [`lab-manual/m35-diagnosis-method.md`](../lab-manual/m35-diagnosis-method.md)
- **Challenge.** Incident 10, [`incidents/10-commit-local-not-remote`](../incidents/10-commit-local-not-remote/SYMPTOMS.md)
- **Interview question.** Q465: "In the root-cause framework every step up to and including naming the root cause is read-only. Why is that rule there, and what is the one kind of change that is allowed before the fix?"
- **Homework.** Read sections 29.1 to 29.3. Read [`playbooks/troubleshooting-playbook.md`](../playbooks/troubleshooting-playbook.md).
- **Expected outcome.** The learner takes any report and produces evidence and hypotheses before touching anything.

### V181: Worked case 2: "I pulled, and the push is still rejected", and the extended toolbox

- **Title.** Worked case 2: "I pulled, and the push is still rejected", and the extended toolbox
- **Learning objectives.** After this video the learner can:
  - Diagnose a push that stays rejected after a successful pull
  - Read upstream configuration as evidence and find the mismatch
  - Use the extended toolbox: refs, graph, remote and object commands beyond the ten
  - Fix the cause, not the symptom, and add the prevention
  - Explain why the developer's own explanation was plausible and wrong
- **Prerequisites.** V040, V180
- **Concepts.** A pull integrates the configured upstream; a push goes where `push.default` and the branch name say. When the two differ, pulling can succeed forever without making the push a fast-forward. The toolbox of section 29.5: for each kind of question, the command that answers it without changing state.
- **Commands.** `git config get --show-origin --show-scope --all`; `git for-each-ref --format`; `git ls-remote origin`; `git rev-list --left-right --count`; `git merge-tree --write-tree --name-only`; `git range-diff`; `git branch --set-upstream-to`; `git push --dry-run`
- **Demonstration.** Replay `labs/ch29/case-wrong-upstream.sh` (snippets `symptom`, `evidence`, `evidence-config`, `toolbox-refs`, `toolbox-graph`, `toolbox-remote`, `toolbox-objects`, `test`, `fix`, `push`, `verify`, `prevent`).
- **Diagrams.** Redraw the diagram of section 29.4; show the root-cause box of section 29.4.
- **Practical exercise.** Lab 35.1 ("The ten-command diagnosis on three repositories") in [`lab-manual/m35-diagnosis-method.md`](../lab-manual/m35-diagnosis-method.md), the second and third repository.
- **Challenge.** Exercise 7.10 (Level 5, "the hotfix that was pushed and is not on the server") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q412: "A push is rejected, `git pull` says "Already up to date", and the push is rejected again. Explain the mechanism and the lowest-risk fix."
- **Homework.** Read sections 29.4 and 29.5.
- **Expected outcome.** The learner reads configuration as evidence and owns a toolbox of read-only commands for every kind of question.

### V182: Operations in progress: what git status and .git tell you

- **Title.** Operations in progress: what git status and .git tell you
- **Learning objectives.** After this video the learner can:
  - Tell from `.git` alone whether a merge, a rebase, a cherry-pick, a revert or a bisect is in progress
  - Say for each which refs and files exist and where HEAD is
  - Name the ways out of each operation and what each leaves behind
  - Explain what commands refuse to run in each state and why
  - Take over a repository that somebody else left in the middle of something
- **Prerequisites.** V062, V071, V181
- **Concepts.** Each operation leaves a signature: `MERGE_HEAD`; `rebase-merge/` or `rebase-apply/`; `CHERRY_PICK_HEAD` and `sequencer/`; `REVERT_HEAD`; `BISECT_LOG` and refs under `refs/bisect/`. `git status` reads the same files. One question separates them. The exits: continue, skip, abort, quit.
- **Commands.** `git status`; `git merge --abort`; `git rebase --abort`; `git rebase --quit`; `git cherry-pick --abort`; `git cherry-pick --quit`; `git revert --abort`; `git bisect reset`; `git for-each-ref refs/bisect`; `git ls-files -u`
- **Demonstration.** Replay `labs/ch29/ops-in-progress.sh` (snippets `clean`, `merge-status`, `merge-files`, `rebase-status`, `rebase-files`, `pick-status`, `pick-files`, `revert-status`, `revert-files`, `bisect-status`, `bisect-files`, `one-question`, `refusals`, `ways-out`). For each operation show the files first and let the viewer name the operation.
- **Diagrams.** New: a table with one row per operation and columns "file or directory that proves it", "where HEAD is", "exits".
- **Practical exercise.** Lab 35.2 ("Five operations in progress, read from `.git` alone") in [`lab-manual/m35-diagnosis-method.md`](../lab-manual/m35-diagnosis-method.md)
- **Challenge.** Exercise 6.9 (Level 4, "a merge that somebody else left half done") in [`exercises/m06-m10-integration.md`](../exercises/m06-m10-integration.md)
- **Interview question.** Q397: "Without running `git status`, how do you tell from the `.git` directory whether a merge, a rebase, a cherry-pick, a revert or a bisect is in progress? Name the files."
- **Homework.** Read section 29.6.
- **Expected outcome.** The learner identifies an interrupted operation in seconds and leaves it deliberately.

### V183: Preserving evidence before acting, and GitHub-side evidence

- **Title.** Preserving evidence before acting, and GitHub-side evidence
- **Learning objectives.** After this video the learner can:
  - Preserve a repository's state with a backup ref, a copy and a bundle, and say what each keeps and misses
  - Show that a backup made first turns a destructive mistake into a recoverable one
  - Name the diagnostic commands that are not strictly read-only
  - List the GitHub-side sources of evidence the section names and what each records
  - Say where the timeline of a server-side branch comes from
- **Prerequisites.** V079, V182
- **Concepts.** Before any change: record the IDs, anchor them with refs, and for serious cases copy or bundle. A copy keeps reflogs and uncommitted work; a bundle keeps reachable history only. GitHub, not Git: the Activity view, pull request timelines, the Events API, rule insights and the audit log, each as section 29.8 describes it.
- **Commands.** `git update-ref`; `git bundle create`; `git bundle verify`; `git reflog show`; `git for-each-ref`; `git gc --prune`; `gh api`; `gh pr view`; `gh ruleset check`
- **Demonstration.** Replay `labs/ch29/preserve-evidence.sh` (snippets `record`, `backup-ref`, `copy`, `bundle`, `destroy`, `from-bundle`, `from-copy`). Then the lab replay `labs/ch29/lab-35-3-preserve-then-fix.sh` (snippets `handover`, `diagnose`, `preserve`). GitHub side: describe the instruments from section 29.8; open the Activity view of the practice repository only to show where it is, with the reminder that the interface changes and nothing was captured by the authors.
- **Diagrams.** New: three ways to preserve drawn as three boxes, each listing "keeps" and "misses".
- **Practical exercise.** Lab 35.3 ("Preserve evidence, then fix") in [`lab-manual/m35-diagnosis-method.md`](../lab-manual/m35-diagnosis-method.md)
- **Challenge.** Exercise 12.9 (Level 4, "A branch that looks like `main`") in [`exercises/m11-m15-investigation-recovery.md`](../exercises/m11-m15-investigation-recovery.md)
- **Interview question.** Q405: "Compare a backup ref, a copy of the repository and a bundle: what does each preserve, and what does each miss?"
- **Homework.** Read sections 29.7 and 29.8.
- **Expected outcome.** The learner never repairs a repository of which no copy of the evidence exists.

### V184: Choosing the lowest-risk fix, verification, and the symptom catalog

- **Title.** Choosing the lowest-risk fix, verification, and the symptom catalog
- **Learning objectives.** After this video the learner can:
  - Rank candidate fixes by what each can destroy and whom it affects
  - State the four checks that make up a verification
  - Give an example where the first check passes and a later one fails
  - Use the symptom catalog to go from an error message to candidate causes
  - Turn a finished case into a line of the team's checklist
- **Prerequisites.** V051, V183
- **Concepts.** Risk order: read-only, then additive (a new commit, a new ref), then local rewrites with a backup, then shared rewrites. Verification is done with the commands that showed the problem, on every repository that showed it, and includes the thing the user wanted. The catalog of section 29.11 maps symptoms to chapters.
- **Commands.** `git revert`; `git reset --keep`; `git push --force-with-lease`; `git ls-remote origin`; `git merge-base --is-ancestor`
- **Demonstration.** Replay the lab replay `labs/ch29/lab-35-3-preserve-then-fix.sh` (snippets `fix`, `verify`, `failure`, `recovery`, `verification`).
- **Diagrams.** Redraw the diagram of section 29.9: the ladder of fixes from least to most destructive.
- **Practical exercise.** Lab 35.3 ("Preserve evidence, then fix") in [`lab-manual/m35-diagnosis-method.md`](../lab-manual/m35-diagnosis-method.md), the second half.
- **Challenge.** Take three entries of the symptom catalog in section 29.11 at random and say, without the book, the first three read-only commands for each.
- **Interview question.** Q413: "Rank these fixes by risk and justify the order: `git revert`, `git reset --hard` followed by a force push, `git reset --keep`, `git cherry-pick`, a new branch."
- **Homework.** Read sections 29.9 to 29.14 and do the Practice section 29.16.
- **Expected outcome.** The learner chooses the fix that destroys least and proves that it worked.

### V185: An incident and the loop that handles one, severity, and how to run the ten incidents

- **Title.** An incident and the loop that handles one, severity, and how to run the ten incidents
- **Learning objectives.** After this video the learner can:
  - Name the stages of the incident loop in order
  - Rate the severity of a Git or GitHub incident and defend the rating
  - Generate an incident sandbox, enter it and check a recovery
  - Follow the ten-part format for a drill
  - Explain why the solution is read only after an attempt
- **Prerequisites.** V184
- **Concepts.** Stabilise, preserve, diagnose, recover, verify, communicate, prevent. Severity is about what could have happened in the window, not only what did. Each incident directory has a report, a generator and a check script; the generator is the answer and is read last. The sandbox has a bare server and several clones, and the learner may sit at any colleague's clone.
- **Commands.** `git ls-remote origin`; `git branch`
- **Demonstration.** Show [`incidents/README.md`](../incidents/README.md). Replay only the `failure` snippet of `labs/incidents/lab-36-1-hard-reset.sh` (snippets `failure`) to show what a drill's "Failure scenario" looks like; stop there.
- **Diagrams.** Redraw the diagram of section 30.2.
- **Practical exercise.** Generate Incident 1, [`incidents/01-hard-reset`](../incidents/01-hard-reset/SYMPTOMS.md) and work on it for thirty minutes without help before the next video.
- **Challenge.** Generate Incident 8, [`incidents/08-branch-disappeared`](../incidents/08-branch-disappeared/SYMPTOMS.md) as well and attempt it before the next video.
- **Interview question.** Q391: "An incident on the production branch deployed nothing and no customer was affected. The CTO asks why you rated it SEV 2 and wants the root cause in two sentences that tell a non-specialist where the fix belongs. What do you say?"
- **Homework.** Read sections 30.1 to 30.4.
- **Expected outcome.** The learner knows how to run a drill and why its value lies in the unaided attempt.

### V186: Incident drills: an accidental hard reset, and a branch that appears to have disappeared

- **Title.** Incident drills: an accidental hard reset, and a branch that appears to have disappeared
- **Learning objectives.** After this video the learner can:
  - Establish what a hard reset destroyed and what the reflog and dangling blobs still hold
  - Recover the committed and the staged work and state honestly what is gone
  - Classify a "disappeared" branch: deleted locally, pruned remote-tracking ref, never pushed, renamed
  - Find the tip, anchor it and restore the branch
  - Write the summary and the prevention for both
- **Prerequisites.** V043, V075, V185
- **Concepts.** Incident 1: the report blames `git pull`; the reflog shows a reset. Committed work is in the reflog, staged work is in dangling blobs, unstaged work is gone. Incident 8: "disappeared" is a symptom with several mechanisms; the reflog of HEAD and other clones decide which.
- **Commands.** `git reflog show`; `git fsck --lost-found`; `git reset --keep`; `git cat-file -p`; `git cherry -v`; `git cherry-pick`; `git branch`
- **Demonstration.** Pause point first: the learner must have attempted Incident 1, [`incidents/01-hard-reset`](../incidents/01-hard-reset/SYMPTOMS.md) and Incident 8, [`incidents/08-branch-disappeared`](../incidents/08-branch-disappeared/SYMPTOMS.md). Then replay `labs/incidents/solve-01-hard-reset.sh` (snippets `observe`, `reflog`, `anchor`, `staged`, `recover`, `verify`, `cleanup`) and `labs/incidents/solve-08-branch-disappeared.sh` (snippets `observe`, `reflog`, `why-gone`, `classify`, `anchor`, `recover`, `verify`).
- **Diagrams.** New: for each incident a timeline strip built from reflog entries, with the destructive moment marked.
- **Practical exercise.** Lab 36.1 ("An accidental `git reset --hard` (incident 1)") in [`lab-manual/m36-incident-drills-local.md`](../lab-manual/m36-incident-drills-local.md)
- **Challenge.** Lab 36.2 ("A branch appears to have disappeared (incident 8)") in [`lab-manual/m36-incident-drills-local.md`](../lab-manual/m36-incident-drills-local.md)
- **Interview question.** Q396: "A developer says "my commits are gone". Which commands do you run before you touch anything, in which order, and what does each tell you?"
- **Homework.** Read sections 30.5 and 30.12. Compare your own attempt with [`solutions/incident-01-hard-reset.md`](../solutions/incident-01-hard-reset.md) only now.
- **Expected outcome.** The learner has handled two "lost work" incidents from report to prevention.

### V187: Incident drills: a commit that exists locally but not remotely, and a misunderstood merge conflict

- **Title.** Incident drills: a commit that exists locally but not remotely, and a misunderstood merge conflict
- **Learning objectives.** After this video the learner can:
  - Give the states that produce "Everything up-to-date" while the commit is not on the server
  - Prove which server and which ref a push went to
  - Explain how a fix can be in `git log` and not in the file
  - Show what a merge resolution discarded with `--remerge-diff` and `--full-history`
  - Repair both with additive changes
- **Prerequisites.** V037, V044, V186
- **Concepts.** Incident 10: the developer is right that they pushed, to another remote or another ref. Incident 9: a conflict resolved by taking one side dropped the other side's change; path-limited log hides the merge that did it because of history simplification.
- **Commands.** `git ls-remote origin`; `git remote -v`; `git branch --set-upstream-to`; `git merge-base --is-ancestor`; `git log --oneline --full-history --`; `git show --remerge-diff`; `git checkout --ours`
- **Demonstration.** Pause point first: the learner must have attempted Incident 10, [`incidents/10-commit-local-not-remote`](../incidents/10-commit-local-not-remote/SYMPTOMS.md) and Incident 9, [`incidents/09-misunderstood-conflict`](../incidents/09-misunderstood-conflict/SYMPTOMS.md). Then replay `labs/incidents/solve-10-commit-local-not-remote.sh` (snippets `ravi-is-right`, `which-server`, `team-repository`, `publish`, `land`, `repair-clone`, `verify`) and `labs/incidents/solve-09-misunderstood-conflict.sh` (snippets `observe`, `commits-are-there`, `log-hides-them`, `graph`, `audit`, `confirm`, `fix`, `verify`, `land`).
- **Diagrams.** New: two remotes and one clone for incident 10; a merge commit with a discarded side for incident 9.
- **Practical exercise.** Lab 36.3 ("A commit exists locally but not remotely (incident 10)") in [`lab-manual/m36-incident-drills-local.md`](../lab-manual/m36-incident-drills-local.md)
- **Challenge.** Lab 36.4 ("A merge conflict is misunderstood (incident 9)") in [`lab-manual/m36-incident-drills-local.md`](../lab-manual/m36-incident-drills-local.md)
- **Interview question.** Q402: "`git push` prints "Everything up-to-date" and the commit is not on the server. Give three states that produce this and the command that separates them."
- **Homework.** Read sections 30.13 and 30.14.
- **Expected outcome.** The learner settles "it is pushed" and "my fix is gone" with evidence that both parties accept.

### V188: A developer rebases a shared branch, and senior standard 1: the branch was rebased and force-pushed and the pull request is broken

- **Title.** A developer rebases a shared branch, and senior standard 1: the branch was rebased and force-pushed and the pull request is broken
- **Learning objectives.** After this video the learner can:
  - Recognize a pull request in which every commit appears twice
  - Reconstruct from refs and reflogs who rewrote what and when
  - Preserve every clone's state before rebuilding
  - Rebuild the branch so that each change is present once and nobody's work is lost
  - Carry out the eleven steps of the senior standard, from inspecting state to preventing recurrence
- **Prerequisites.** V059, V125, V187
- **Concepts.** A rewritten shared branch meets a teammate's clone that still has the originals; a merge or a pull joins both. The senior standard is the complete response in eleven steps: inspect the state, inspect refs, inspect the reflog, identify the old branch state, understand what changed, preserve recoverable references, determine the safest recovery, restore the correct history, update the pull request safely, explain what happened, prevent recurrence. Steps 1 to 6 change nothing.
- **Commands.** `git for-each-ref`; `git reflog show`; `git range-diff`; `git rebase --onto`; `git reset --keep`; `git push --force-with-lease`; `git pull --rebase`; `gh pr view`; `gh pr diff`
- **Demonstration.** Pause point first: the learner must have attempted Incident 5, [`incidents/05-rebased-shared-branch`](../incidents/05-rebased-shared-branch/SYMPTOMS.md). Then replay `labs/incidents/solve-05-rebased-shared-branch.sh` (snippets `state`, `pull-request-view`, `refs`, `reflog`, `old-state`, `what-changed`, `preserve`, `rebuild`, `check-result`, `publish`, `teammate`, `prevent`) and `labs/incidents/lab-38-3-lease.sh` (snippets `lease-refuses`, `failure`, `recovery`).
- **Diagrams.** New: the eleven steps as a numbered column, each with the command that performs it and the evidence it produces.
- **Practical exercise.** Lab 36.5 ("A developer rebases a shared branch (incident 5)") in [`lab-manual/m36-incident-drills-local.md`](../lab-manual/m36-incident-drills-local.md)
- **Challenge.** Lab 38.3 ("Senior standard 1, against the clock: the rebased and force-pushed branch") in [`lab-manual/m38-communication-postmortems.md`](../lab-manual/m38-communication-postmortems.md)
- **Interview question.** Q378: "A pull request shows the same changed files as yesterday and three times as many commits. What happened, and which two comparisons explain why the views differ?"
- **Homework.** Read sections 30.9 and 30.16.
- **Expected outcome.** The learner can lead the recovery of a rewritten shared branch against the clock.

### V189: Incident drills: a force push to the wrong branch, and rewritten production history

- **Title.** Incident drills: a force push to the wrong branch, and rewritten production history
- **Learning objectives.** After this video the learner can:
  - Find out what a forced push replaced and who still has the old commits
  - Check two things before restoring: what has been built on the new tip, and who has fetched it
  - Restore the branch without losing a legitimate commit made after the rewrite
  - Realign teammates' clones
  - Walk from the root cause to controls on several layers
- **Prerequisites.** V042, V131, V188
- **Concepts.** Incident 2: a bare `git push --force` from the wrong branch. Incident 4: the deployed commit is no longer an ancestor of the production branch. Witnesses are the clones that have not fetched and the remote-tracking reflogs. The restoring push is itself a rewrite and needs a lease and a backup. GitHub, not Git: the rule that would have refused the push.
- **Commands.** `git ls-remote origin`; `git reflog show`; `git merge-base --is-ancestor`; `git cherry -v`; `git push --force-with-lease`; `git reset --keep`; `git revert`; `git branch --no-track`
- **Demonstration.** Pause point first: the learner must have attempted Incident 2, [`incidents/02-force-push-wrong-branch`](../incidents/02-force-push-wrong-branch/SYMPTOMS.md) and Incident 4, [`incidents/04-production-history-rewritten`](../incidents/04-production-history-rewritten/SYMPTOMS.md). Then replay `labs/incidents/solve-02-force-push-wrong-branch.sh` (snippets `observe`, `fetch`, `what-changed`, `cause`, `preserve`, `restore`, `fix-cause`, `verify`) and `labs/incidents/solve-04-production-history-rewritten.sh` (snippets `observe`, `witnesses`, `what-changed`, `tree-diff`, `how`, `restore`, `realign`, `verify`).
- **Diagrams.** New: the server's branch before and after, the witnesses' clones, and the legitimate commit made after the rewrite that the restore must keep.
- **Practical exercise.** Lab 37.1 ("A force push to the wrong branch (incident 2)") in [`lab-manual/m37-incident-drills-platform.md`](../lab-manual/m37-incident-drills-platform.md)
- **Challenge.** Lab 37.2 ("Production branch history is rewritten (incident 4)") in [`lab-manual/m37-incident-drills-platform.md`](../lab-manual/m37-incident-drills-platform.md)
- **Interview question.** Q381: "`main` was force-pushed ten minutes ago. Before you restore it, which two things do you check, and what does the restoring command look like?"
- **Homework.** Read sections 30.6 and 30.8.
- **Expected outcome.** The learner restores a rewritten shared branch without making the recovery the second incident.

### V190: Incident drill: a pull request that suddenly shows 500 unrelated changes

- **Title.** Incident drill: a pull request that suddenly shows 500 unrelated changes
- **Learning objectives.** After this video the learner can:
  - List the mechanisms that make a small pull request show hundreds of files
  - Name the Git command that tests each mechanism on the developer's machine
  - Attribute the extra changes to the commit that brought them in
  - Rebuild the branch so that the pull request shows only its own change
  - Explain the consequence of leaving it as it is
- **Prerequisites.** V125, V189
- **Concepts.** The page shows a three-dot diff: either an endpoint or the merge base is not what the author thinks. Candidates: wrong base, a merge of the wrong branch, a rewritten base, a reformatting commit. The evidence is the graph and `git diff --stat` in both forms.
- **Commands.** `git diff --stat`; `git diff --shortstat`; `git log --oneline --graph`; `git merge-base --is-ancestor`; `git rebase --onto`; `git push --force-with-lease --force-if-includes`
- **Demonstration.** Pause point first: the learner must have attempted Incident 6, [`incidents/06-pr-500-changes`](../incidents/06-pr-500-changes/SYMPTOMS.md). Then replay `labs/incidents/solve-06-pr-500-changes.sh` (snippets `pull-request-view`, `hypotheses`, `merge`, `attribution`, `rebuild`, `check-result`, `publish`, `verify`) and the `consequence` snippet of `labs/incidents/lab-37-3-pr-500-changes.sh` (snippets `consequence`).
- **Diagrams.** New: the pull request's two endpoints and merge base on the graph, before and after the rebuild.
- **Practical exercise.** Lab 37.3 ("A pull request suddenly shows 500 unrelated changes (incident 6)") in [`lab-manual/m37-incident-drills-platform.md`](../lab-manual/m37-incident-drills-platform.md)
- **Challenge.** Exercise 21.7 (Level 5, "Green on the pull request, red on main") in [`exercises/m19-m25-github.md`](../exercises/m19-m25-github.md)
- **Interview question.** Q414: "A pull request shows 400 changed files for a two-line change. List four mechanisms and the Git command that tests each one locally."
- **Homework.** Read section 30.10.
- **Expected outcome.** The learner explains an inflated pull request in one sentence and repairs it without closing it.

### V191: CI works locally but fails on GitHub Actions, and senior standard 3: GitHub Actions suddenly fails

- **Title.** CI works locally but fails on GitHub Actions, and senior standard 3: GitHub Actions suddenly fails
- **Learning objectives.** After this video the learner can:
  - Refuse "flaky runner" as a diagnosis until the investigation order has been followed
  - Establish which commit the run tested and what the runner's repository contained
  - Reproduce the runner's view locally with Git alone
  - Fix the cause and predict what the next run will test
  - Handle "nothing changed and CI fails" by listing what can change without a commit
- **Prerequisites.** V153, V154, V190
- **Concepts.** Incident 7 comes with a workflow file and a described run constructed for the exercise; nothing was captured from GitHub. The evidence is on the Git side: clone depth, tags, the merge ref, case and line endings. Senior standard 3: "suddenly" is a claim to test first. Either something in the repository changed (the workflow, the lock file, the code) or something outside it did (a runner image, an action behind a moving tag, a secret, a cache).
- **Commands.** `git describe`; `git clone --quiet --depth`; `git rev-parse --is-shallow-repository`; `git tag --list`; `gh run list --workflow`; `gh run view`; `gh run rerun`
- **Demonstration.** Pause point first: the learner must have attempted Incident 7, [`incidents/07-ci-passes-locally`](../incidents/07-ci-passes-locally/SYMPTOMS.md). Then replay `labs/incidents/solve-07-ci-passes-locally.sh` (snippets `local`, `workflow`, `runner-clone`, `remedy-proof`, `second-failure`, `fix`, `publish`).
- **Diagrams.** New: a list "what changed?" with two columns, "visible in `git log`" and "not visible in `git log`", filled from section 30.18.
- **Practical exercise.** Lab 37.4 ("CI works locally but fails on GitHub Actions (incident 7)") in [`lab-manual/m37-incident-drills-platform.md`](../lab-manual/m37-incident-drills-platform.md)
- **Challenge.** Lab 38.5 ("Senior standard 3: GitHub Actions suddenly fails") in [`lab-manual/m38-communication-postmortems.md`](../lab-manual/m38-communication-postmortems.md)
- **Interview question.** Q282: "A pull request's CI fails and the author says "it passes on my machine, same commit". What do you check first, and why can both be right?"
- **Homework.** Read sections 30.11 and 30.18.
- **Expected outcome.** The learner diagnoses a CI failure from evidence and has a checklist for failures that arrive without a commit.

### V192: A secret is committed, and senior standard 2

- **Title.** A secret is committed, and senior standard 2
- **Learning objectives.** After this video the learner can:
  - Answer "I deleted the file, so the branch is clean" with evidence
  - Run the response in order and say what must never be claimed before it is verified
  - Scope the exposure: first commit, first push, refs, tags, dependent branches
  - Carry out the rewrite where it is warranted and verify every clone
  - Write the message to the team that says exactly what to do with their clones
- **Prerequisites.** V168, V191
- **Concepts.** The first act is revocation at the issuer, which Git cannot do. Then scope with history searches and `--contains`, eradicate, publish every rewritten ref, prune the server, repair the clones, and prevent. The senior standard adds time pressure, a dependent branch, a tag, and a teammate whose clone would push the secret back.
- **Commands.** `git log --all --`; `git branch -r --contains`; `git diff --cached`; `git push --force-with-lease --force-if-includes`; `git rebase --onto`; `git range-diff`; `git gc --prune`
- **Demonstration.** Pause point first: the learner must have attempted Incident 3, [`incidents/03-committed-secret`](../incidents/03-committed-secret/SYMPTOMS.md). Then replay `labs/incidents/solve-03-committed-secret.sh` (snippets `find`, `scope`, `rewrite`, `amend`, `check-rewrite`, `publish`, `dependent-branch`, `server-still-has-it`, `server-prune`, `clones`, `verify`); the secret is a dummy string made for the drill.
- **Diagrams.** New: the six response steps with the Git commands under the steps that have any, and "at the provider" under the step that has none.
- **Practical exercise.** Lab 37.5 ("A secret is committed (incident 3)") in [`lab-manual/m37-incident-drills-platform.md`](../lab-manual/m37-incident-drills-platform.md)
- **Challenge.** Lab 38.4 ("Senior standard 2, against the clock: a committed secret") in [`lab-manual/m38-communication-postmortems.md`](../lab-manual/m38-communication-postmortems.md)
- **Interview question.** Q382: "A colleague says "I deleted the file with the key and pushed, so we are fine". Give the order of the response and say what the deletion did and did not do."
- **Homework.** Read sections 30.7 and 30.17.
- **Expected outcome.** The learner can lead a secret-leak response on a real team's repository shape, in order, against the clock.

### V193: The incident summary a CTO needs, blameless postmortems, and turning a root cause into a control

- **Title.** The incident summary a CTO needs, blameless postmortems, and turning a root cause into a control
- **Learning objectives.** After this video the learner can:
  - Write the four-part incident summary and say what must never be claimed in its third part
  - Build a timeline in which every line names the source of its fact
  - Write a blameless postmortem with the template
  - Turn a root cause into a control and classify it as prevent, detect or recover
  - Say how you know a control works
- **Prerequisites.** V192
- **Concepts.** The summary: what happened, the root cause with its layer, what was done and how it was verified, what prevents a repeat. A status without a root cause is still a status. Blameless means the document explains why the action looked right to the person who took it; that is also what keeps the evidence coming. "Engineers will take more care" is not a control.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay `labs/incidents/lab-38-1-timeline.sh` (snippets `deployment`, `rewrite`, `adoption`, `detection`): a timeline assembled from reflog entries, tags and log lines, each with its source.
- **Diagrams.** Show the summary form of section 30.15 (the diagram of section 30.15) and the postmortem template of section 30.19 as slides.
- **Practical exercise.** Lab 38.1 ("A timeline and a CTO summary") in [`lab-manual/m38-communication-postmortems.md`](../lab-manual/m38-communication-postmortems.md)
- **Challenge.** Lab 38.2 ("A blameless postmortem") in [`lab-manual/m38-communication-postmortems.md`](../lab-manual/m38-communication-postmortems.md)
- **Interview question.** Q377: "What are the four parts of an incident summary for a CTO, and what must never be claimed in the third?"
- **Homework.** Read sections 30.15, 30.19 to 30.23 and do the Practice section 30.25. Finalize your copy of [`playbooks/disaster-recovery-playbook.md`](../playbooks/disaster-recovery-playbook.md) with your own notes.
- **Expected outcome.** The learner communicates an incident so that a CTO can decide, and leaves a control behind.

### V194: Gate briefing: Production debugging

- **Title.** Gate briefing: Production debugging
- **Learning objectives.** After this video the learner can:
  - State what Gate 9 covers and its threshold of 90
  - Explain what is scored in the hands-on part: end state, safety of the path, explanation, the summary and the control
  - Prepare by repeating incidents from freshly generated sandboxes without the solutions
  - Give a status when no root cause is known yet
- **Prerequisites.** V193
- **Concepts.** Gate 9 covers the diagnosis method, the ten incidents, communication and postmortems. The hands-on part is a generated repository with a report that is incomplete and partly wrong; the command log is read. A state-changing command before the root cause is established costs more here than anywhere else in the course.
- **Commands.** `git status`; `git reflog`; `git ls-remote origin`
- **Demonstration.** Replay `labs/ch29/preserve-evidence.sh` (snippets `record`, `backup-ref`) as the warm-up: the two commands that should precede any repair. Show the gate rules from [`assessments/README.md`](../assessments/README.md). Do not open the gate file on screen.
- **Diagrams.** Redraw the diagram of section 30.2 with the four scored elements written beside the stages where they are earned.
- **Practical exercise.** Regenerate Incident 2, [`incidents/02-force-push-wrong-branch`](../incidents/02-force-push-wrong-branch/SYMPTOMS.md), Incident 5, [`incidents/05-rebased-shared-branch`](../incidents/05-rebased-shared-branch/SYMPTOMS.md) and Incident 6, [`incidents/06-pr-500-changes`](../incidents/06-pr-500-changes/SYMPTOMS.md) and repeat them against the clock, without notes.
- **Challenge.** Take Gate 9: [`assessments/gate-9-production-debugging.md`](../assessments/gate-9-production-debugging.md).
- **Interview question.** Q469: "Ten minutes into an incident the CTO asks for a status, and you have no root cause yet. What do you say?"
- **Homework.** Before the gate: answer the "Interview questions" sections of Chapters 29 and 30 aloud.
- **Expected outcome.** The learner sits Gate 9 able to diagnose from incomplete evidence and to communicate the result.

## Part 10: Senior engineer: assessment

Roadmap Level 10 (Modules 39 to 41). 4 videos that prepare the three final assessments: the CTO interview series, the final knowledge test and the capstone. They teach nothing new; they explain the rules and the standard.

### V195: The CTO interview series: the structure of a strong answer

- **Title.** The CTO interview series: the structure of a strong answer
- **Learning objectives.** After this video the learner can:
  - State how an interview session is run and graded
  - Structure an answer in five parts: state, mechanism, evidence, fix, prevention
  - Answer a question aloud in two minutes without notes or a terminal and then take the follow-up
  - Tell a weak answer from a strong one on the same question
  - Run a session alone with a recording
- **Prerequisites.** V194
- **Concepts.** One question at a time, spoken. The follow-up is what a CTO asks when the first answer was correct. Layer discipline: Git, GitHub, GitHub Actions. The question bank has 482 questions in eighteen areas at four levels; the answers file is opened only after answering aloud. The senior-engineer guide works twenty answers at three quality levels.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay `labs/ch29/case-wrong-upstream.sh` (snippets `symptom`, `evidence`, `test`, `fix`, `verify`, `prevent`) and narrate it as a five-part answer: this is the shape an oral answer takes when it is backed by a real case. Show [`interview/interview-mode-protocol.md`](../interview/interview-mode-protocol.md) and section 3 of [`interview/senior-engineer-interview-guide.md`](../interview/senior-engineer-interview-guide.md); do not show the answers file.
- **Diagrams.** New: the five parts of an answer as a bar with a time budget on each.
- **Practical exercise.** Run one session of ten questions from [`interview/cto-question-bank.md`](../interview/cto-question-bank.md), areas 1 to 8, by the protocol, recorded.
- **Challenge.** Run the debugging round of the protocol with a colleague as interviewer, on areas 15 and 16.
- **Interview question.** Q464: "A CTO does not ask "which command fixes this". Which four questions does a CTO ask about a repository problem, and which of them can a command answer?"
- **Homework.** Work through the twenty worked answers of the guide: answer each aloud first, then read the three quality levels.
- **Expected outcome.** The learner answers at interview standard: mechanism first, evidence named, layer stated.

### V196: The final knowledge test: briefing

- **Title.** The final knowledge test: briefing
- **Learning objectives.** After this video the learner can:
  - State the structure of the final test: eighteen sections, eight item types, six sittings
  - State the pass rule
  - Explain the rule that a state-changing command before the root cause costs half an item
  - Plan the six sittings and the revision before each
  - Use the answer key only as the retake procedure allows
- **Prerequisites.** V195
- **Concepts.** The test has 250 items over the eighteen areas of the question bank: multiple choice, command prediction, diagram, output interpretation, debugging, practical lab, incident response, oral. Pass at 85% overall, at least 70% in every section, and at least seven of nine practical labs. Prediction items are worthless if run. Nothing in the test needs a GitHub account or a network connection.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Nothing from the test is shown beyond its rules. Show the "How the test is taken" section of [`assessments/final-test.md`](../assessments/final-test.md) and stop before Section 1. To show the form a practical lab takes, replay only the `failure` snippet of `labs/incidents/lab-36-1-hard-reset.sh` (snippets `failure`): a generated repository, a task, and a check script that verifies the end state.
- **Diagrams.** New: a table of the six sittings with their sections and time budgets.
- **Practical exercise.** Revise with [`revision/revision-checklist.md`](../revision/revision-checklist.md) and [`cheatsheets/git-cheat-sheet.md`](../cheatsheets/git-cheat-sheet.md), then take sitting 1.
- **Challenge.** Take the whole final test: [`assessments/final-test.md`](../assessments/final-test.md).
- **Interview question.** Q476: "A senior engineer with ten years of Git says that a fixed diagnosis ritual is for juniors. Respond."
- **Homework.** Between sittings, restudy only what the previous sitting showed to be weak; do not read ahead in the test.
- **Expected outcome.** The learner takes the final test under its rules and knows what a pass requires.

### V197: The capstone: eight incidents at a fictional company

- **Title.** The capstone: eight incidents at a fictional company
- **Learning objectives.** After this video the learner can:
  - Describe the company, the team, the repository and the sandbox of the capstone
  - State the seven items every stage must deliver
  - State the seven dimensions on which the work is evaluated and the disqualifying findings
  - Set up the sandbox and receive the first stage
  - Explain how the pull-request side of GitHub is played locally
- **Prerequisites.** V196
- **Concepts.** Eight stages arrive one at a time: a bug in production, a merge conflict, a leaked secret, failed CI, lost work, a deleted branch, a broken pull request, a hotfix and backport. Nobody names the cause. States of earlier days remain in the repository. Everything runs locally; where administrator power over the bare server is used, the write-up must say what the equivalent step on GitHub is. The company, the people and every alert are fictional.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Show [`capstone/README.md`](../capstone/README.md), [`capstone/DELIVERABLES.md`](../capstone/DELIVERABLES.md) and [`capstone/EVALUATION.md`](../capstone/EVALUATION.md). Replay only the `company` snippet of `labs/capstone/end-to-end.sh` (snippets `company`). Do not show any stage's model replay.
- **Diagrams.** New: the sandbox layout (server, the `pr` script, four clones, evidence directory) and the eight stages as a calendar of eight working days.
- **Practical exercise.** Run `capstone/setup.sh` and read the briefing of the first stage: Capstone stage 1, [`capstone/stage-01-bug-in-production`](../capstone/stage-01-bug-in-production/BRIEFING.md).
- **Challenge.** Complete all eight stages, Capstone stage 1, [`capstone/stage-01-bug-in-production`](../capstone/stage-01-bug-in-production/BRIEFING.md) to Capstone stage 8, [`capstone/stage-08-hotfix-and-backport`](../capstone/stage-08-hotfix-and-backport/BRIEFING.md), each with its seven deliverables, and write the final postmortem.
- **Interview question.** Q393: "A recovery on a shared branch can itself become the second incident. Name the ways the recovery fails under time pressure, how each is noticed, and the guard against each."
- **Homework.** Work one stage per sitting. Hand in each stage's deliverables before starting the next.
- **Expected outcome.** The learner starts the capstone knowing what is expected and how it will be judged.

### V198: Capstone debrief: reading your own work against the evaluation

- **Title.** Capstone debrief: reading your own work against the evaluation
- **Learning objectives.** After this video the learner can:
  - Score your own deliverables on the seven dimensions with the four-level scale
  - Compare your recovery path with the model path for safety, not for sameness
  - Find the stage where your evidence log was thinnest and say what you would collect now
  - Name the control each stage should have left behind
  - State what you would do differently in a real incident tomorrow
- **Prerequisites.** V197
- **Concepts.** This video is watched only after all eight stages are handed in. A different path that is equally safe and fully verified is a full answer. The debrief looks for the same things as the evaluation: evidence before change, a way back before a rewrite, the layer named, verification, communication, a control.
- **Commands.** None new; this video applies commands from its prerequisites.
- **Demonstration.** Replay the model replays one stage at a time and compare each with the learner's own log: `labs/capstone/stage-01-bug-in-production.sh`, `labs/capstone/stage-02-merge-conflict.sh`, `labs/capstone/stage-03-leaked-secret.sh`, `labs/capstone/stage-04-failed-ci.sh`, `labs/capstone/stage-05-lost-work.sh`, `labs/capstone/stage-06-deleted-branch.sh`, `labs/capstone/stage-07-broken-pull-request.sh` and `labs/capstone/stage-08-hotfix-and-backport.sh`. Close with `labs/capstone/end-to-end.sh` (snippets `stages`, `final-state`).
- **Diagrams.** New: the scoring sheet of the evaluation as a grid of eight stages against seven dimensions, to be filled in by the learner.
- **Practical exercise.** Fill in the scoring sheet of [`capstone/EVALUATION.md`](../capstone/EVALUATION.md) for your own work before watching each stage's replay.
- **Challenge.** Rewrite the weakest of your eight CTO messages so that it meets section 30.15, and the final postmortem so that it meets section 30.19.
- **Interview question.** Q480: "Several incidents in this course trace back to a default. Name three, give the layer of each, and say whether you would change the default or add a control around it."
- **Homework.** Enter what the capstone showed in the weak-area tracker of section 12 of the roadmap, [`curriculum/Git and GitHub mastery roadmap.md`](../curriculum/Git%20and%20GitHub%20mastery%20roadmap.md), and plan the restudy with [`revision/revision-checklist.md`](../revision/revision-checklist.md).
- **Expected outcome.** The learner can judge their own incident handling by a senior standard.

## Part 11: Expert: the frontier

Roadmap Level 11 (Module 42). 3 videos on where Git is going and on reading primary sources unaided. Features that need Git 2.56 are named as such and not run.

### V199: The road to Git 3.0, the planned defaults and removals, opting in today, and SHA-256 and reftable repositories locally

- **Title.** The road to Git 3.0, the planned defaults and removals, opting in today, and SHA-256 and reftable repositories locally
- **Learning objectives.** After this video the learner can:
  - State what Git 3.0 plans to change, for which repositories, and what is officially said about its date
  - Name the configuration keys that choose the planned defaults ahead of time and say where you would set them
  - Create a repository with the planned formats today and convert the ref format of an existing one
  - Say what `safe.bareRepository=explicit` refuses and allows
  - Say what would have to be true before a hosted team repository can use SHA-256
- **Prerequisites.** V107, V198
- **Concepts.** The plan is in the BreakingChanges document: new defaults for new repositories, and removals. Existing repositories keep working. Opting in early finds the scripts that read `.git` by hand. SHA-256 and reftable work locally; hosting support is the open question the section describes.
- **Commands.** `git version --build-options`; `git config set --global`; `git init -q --object-format`; `git refs migrate --ref-format`; `git refs list`; `git rev-parse --git-dir --is-bare-repository`
- **Demonstration.** Replay `labs/ch14d/git3-optin.sh` (snippets `build`, `today`, `opt-in`, `new-repositories-only`, `opt-out`, `removals`), `labs/ch14d/safe-bare.sh` (snippets `explicit`, `still-works`, `embedded`, `refused`) and the lab replay `labs/ch14d/lab-42-1-sha256-reftable.sh` (snippets `today`, `future`, `convert`, `migrate`).
- **Diagrams.** Redraw the diagram of section 14D.2.
- **Practical exercise.** Lab 42.1 ("SHA-256 and reftable repositories") in [`lab-manual/m42-frontier.md`](../lab-manual/m42-frontier.md)
- **Challenge.** Opt in to the planned defaults in a sandbox configuration and run your own team's Git scripts there; list what breaks and why.
- **Interview question.** Q425: "What will Git 3.0 change, for which repositories, and what is the official statement about its date? Which parts of the schedule come from secondary sources?"
- **Homework.** Read sections 14D.1 to 14D.5.
- **Expected outcome.** The learner knows what the next major version changes for their team and has tested it ahead of time.

### V200: git history, git replay, git last-modified and git repo

- **Title.** git history, git replay, git last-modified and git repo
- **Learning objectives.** After this video the learner can:
  - Reword, fix up and split a commit with `git history` and say which branches move
  - Compare `git history reword` with an interactive rebase: working tree, hooks, merges, conflicts
  - Explain why a server needs `git replay` and what `--ref-action=print` gives it
  - Use `git last-modified` and `git repo info` and `git repo structure` to inspect a repository
  - State which of these commands are experimental and which part is a Git 2.56 addition
- **Prerequisites.** V055, V199
- **Concepts.** `git history` performs single-purpose rewrites without checking anything out and updates the branches that contain the commit. `git replay` replays commits onto a new base without a working tree and prints or applies ref updates. Both are marked experimental. `git history drop` is a Git 2.56 addition, not run here.
- **Commands.** `git history reword`; `git history reword --dry-run`; `git history fixup`; `git history split`; `git replay --onto`; `git replay --advance`; `git replay --ref-action`; `git update-ref --stdin`; `git last-modified`; `git repo info`; `git repo structure`
- **Demonstration.** Replay `labs/ch14d/history.sh` (snippets `help`, `reword`, `reflogs`, `dry-run`, `fixup`, `split`, `after-split`, `no-hooks`, `limits`), `labs/ch14d/replay.sh` (snippets `bare`, `print`, `advance`, `revert`), `labs/ch14d/inspect.sh` (snippets `last-modified`, `compare`, `repo-info`, `repo-structure`) and `labs/ch09/replay-conflict.sh` (snippets `conflict`).
- **Diagrams.** New: the same reword done by interactive rebase and by `git history`, with the working tree drawn as touched in the first and untouched in the second.
- **Practical exercise.** Lab 42.2 ("`git history reword`") in [`lab-manual/m42-frontier.md`](../lab-manual/m42-frontier.md)
- **Challenge.** In a sandbox, rebuild Lab 9.1 with `git history` where it applies and note which steps still need an interactive rebase.
- **Interview question.** Q437: "Compare `git history reword` with `git rebase -i` and `reword`: working tree, hooks, which branches move, merges, conflicts."
- **Homework.** Read sections 14D.6 to 14D.8 and section 9.20.
- **Expected outcome.** The learner can use the new history tools where they fit and explain their limits.

### V201: Rust in Git, stacked workflows and Git-compatible tools, reading release notes and the GitHub Changelog, and the patch-based workflow of the Git project

- **Title.** Rust in Git, stacked workflows and Git-compatible tools, reading release notes and the GitHub Changelog, and the patch-based workflow of the Git project
- **Learning objectives.** After this video the learner can:
  - Say what the build option about Rust tells you and what the BreakingChanges document promises
  - Read a release's notes in a fixed order and decide what it changes for a team
  - Follow the GitHub Changelog for dated platform changes
  - Create a patch series with a cover letter, apply it with `git am`, and explain why author and committer then differ
  - Send a second version of a series and show what changed with `git range-diff`
- **Prerequisites.** V021, V200
- **Concepts.** Primary sources: the release notes, BreakingChanges, the manual pages, the GitHub Changelog. The Git project is developed by patches on a mailing list: `format-patch`, `am`, versions of a series, `range-diff`. A patch file is a commit in mail form.
- **Commands.** `git format-patch`; `git format-patch --cover-letter --base`; `git am`; `git format-patch -v`; `git range-diff`; `git patch-id --stable`
- **Demonstration.** Replay `labs/ch14d/release-notes.sh` (snippets `where`, `sections`, `search`, `breaking-changes`) and `labs/ch14d/patch-series.sh` (snippets `format-patch`, `patch-file`, `cover-letter`, `am`, `same-change-new-id`, `v2`, `v2-series`), then the lab replay `labs/ch14d/lab-42-3-format-patch-am.sh` (snippets `format-patch`, `read`, `am`, `compare`).
- **Diagrams.** New: a patch file with its parts labelled: from line, author, date, subject, message, diffstat, diff; and which parts become the commit.
- **Practical exercise.** Lab 42.3 ("A format-patch and am round trip") in [`lab-manual/m42-frontier.md`](../lab-manual/m42-frontier.md)
- **Challenge.** Read the release notes of the Git version after the one installed and write, for your team, one paragraph: what changes, whom it affects, what to do.
- **Interview question.** Q439: "How do you find out whether a behavior change in a new Git release affects your team? Which documents do you read, in which order?"
- **Homework.** Read sections 14D.9 to 14D.14 and do the Practice section 14D.16. Read [`reference/references.md`](../reference/references.md).
- **Expected outcome.** The learner follows Git's development from primary sources and no longer depends on tutorials to learn what changed.
