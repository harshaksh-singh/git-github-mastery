# Git and GitHub Deep Mastery: Phase 1 roadmap

**PHASE 1 — COMPLETE ROADMAP · built on the Phase 0 research report · baseline date 1 October 2026**

This roadmap is the structure of the whole program: 43 modules in 12 levels, nine mastery gates, a final test, a capstone, and fifteen deliverables. Every version-sensitive statement in it comes from the Phase 0 report ([Git and GitHub mastery research](../reports/Git%20and%20GitHub%20mastery%20research.md)), which carries the sources. Every Git command and flag named below was checked against the man pages of the Git 2.55.0 installed on your Mac on 1 October 2026. Anything that needs Git 2.56 is marked.

---

## 1. Where this roadmap sits in the program

You asked for a strict order: research, verify, structure, teach, practise, assess, correct, finalize, and only then video. The program follows it.

```text
Phase 0  Research and verify              DONE  1 Oct 2026   (15-section report, ~38,000 words, sources linked)
Phase 1  Structure                        DONE  1 Oct 2026   (this roadmap)
Phase 2  Teach -> practise -> assess      Modules 0 to 34    (eight mastery gates)
Phase 3  Production simulation            Modules 35 to 42   (ninth gate, final test, capstone, frontier)
Phase 4  Finalize the written course      textbook, lab manual, references, playbooks, guides
Phase 5  Video curriculum and scripts     starts only after Phase 4 is final
```

The written deliverables are not written at the end from memory. Each module, once you pass it, produces its textbook chapter, its lab-manual entry, and its cheat-sheet rows. Phase 4 assembles and edits material that has already been taught, tested on your machine, and corrected.

---

## 2. What the research changed in this plan

These are the design decisions that differ from a typical Git course, each tied to a verified finding.

| Decision | Verified reason (Phase 0 report section) |
|---|---|
| The data model is taught first, before the everyday commands | Ten popular beginner resources skip the index, conflict stages and reflog; polls show only 10% of practising developers are fully confident about HEAD (sections 11, 12) |
| `git switch` and `git restore` are the primary commands; `git checkout` is taught for reading other people's scripts | Both lost the experimental label in Git 2.51; the Git project has recorded that `checkout` will not be removed (section 1) |
| No lab hard-codes `master`, `main`, 40-character IDs, or files under `.git/refs` | Unconfigured Git 2.x still creates `master`; Git 3.0 plans `main`, SHA-256 and reftable as defaults for new repositories (section 1) |
| Recovery windows are taught with their exceptions | Deleting a branch deletes its reflog; bare repositories keep no reflogs; automatic maintenance is the geometric strategy since 2.54, with unchanged expiry values (sections 1, 13) |
| Rulesets are taught first, classic branch protection second | GitHub named rulesets the recommended mechanism on 7 July 2026; classic rules have no sunset date and still layer with rulesets (section 2) |
| Fine-grained tokens first, with their documented gaps | Generally available since 18 March 2025; cannot be used for Packages or for contributing to public repositories where you are not a member (section 2) |
| Actions examples use current action majors pinned to full commit SHAs, re-verified on the day of the lesson | GitHub's own docs examples lag the releases; Node 24 is the only JavaScript runtime since 23 September 2026 (sections 2, 5) |
| `pull_request_target` is taught as a security topic, not a convenience | Root cause of the Nx, Trivy and TanStack compromises; blocked by default in public repositories from 2 November 2026 (section 14) |
| GitHub governance labs use public repositories in a free organization | Rulesets and environment reviewers are available on Free only for public repositories (section 2) |
| Secret-leak response is taught as "rotate first" | GitHub's official procedure; force-pushed commits stay reachable in forks, clones, cached views and pull-request refs (section 14) |
| Videos are optional companions, never the source of truth | No single video covers the path; assessments rest on captions, not full viewing (sections 7 to 10) |

---

## 3. How every module runs

### 3.1 The ten-step loop

Every module follows the loop you specified. I do not move on because a command worked. I move on when you can explain why it worked.

```text
 1 Teach        simple explanation -> analogy -> technical explanation -> internal mechanics
 2 Demonstrate  live commands on your machine, with the .git state inspected before and after
 3 Lab          you perform it; 11-part lab format (section 5)
 4 Exercises    Levels 1 to 5; you attempt first, answers come after
 5 Test         concept questions and command or output prediction
 6 Correct      I show the precise gap, the better answer, and a harder follow-up
 7 Interview    strict CTO-style oral questions, one at a time, no fake praise
 8 Homework     spaced-repetition tasks and one reading from a primary source
 9 Track        weak areas go into the tracker (section 12) and return in later modules
10 Gate         levels end with a mastery gate; below threshold means remediation, not progression
```

### 3.2 The explanation lens

For every important concept I cover the twenty points you listed: what it is, why it exists, the problem it solves, what happens internally, in the working tree, in the index, inside `.git`, to refs, to HEAD, to history, on the remote, on GitHub, what can go wrong, how to diagnose it, how to fix it, how to prevent it, when not to use it, dangerous edge cases, production implications, and a practical example.

### 3.3 Exercise levels

| Level | Name | What you get |
|---|---|---|
| 1 | Beginner | Full instructions to follow |
| 2 | Intermediate | The goal and limited hints |
| 3 | Advanced | A situation to diagnose on your own |
| 4 | Senior | Symptoms only, in a repository I generate in a broken state |
| 5 | Production incident | Incomplete and partly misleading evidence; you must find the root cause and choose the lowest-risk fix |

Answers are never shown before you attempt. After your attempt you get the solution, the reasoning, the common mistakes, and the expert approach.

### 3.4 Interview mode and debugging mode

- **Interview mode** runs at the end of every module. One question at a time. I wait for your answer and grade it on correctness, depth, terminology, reasoning, practical understanding, and production awareness.
- **Debugging mode** runs from Level 3 onward. I give a symptom, for example "the developer committed yesterday and the branch no longer contains the commit", and ask what you would inspect first. I answer only with the output your chosen command would produce.

### 3.5 Command risk labels

| Label | Meaning | Examples |
|---|---|---|
| 🟢 SAFE | Reads state or adds new objects; nothing is lost | `git status`, `git log`, `git fetch`, `git reflog`, `git commit` |
| 🟡 CAUTION | Moves refs or rewrites local history; recoverable through reflog if you know how | `git reset --soft`, `git rebase`, `git commit --amend` |
| 🔴 DANGEROUS | Can destroy uncommitted work, remote history, or the safety net itself | `git reset --hard`, `git clean -fd`, `git push --force` and its conditional forms `--force-with-lease` and `--force-if-includes`, `git filter-repo`, `git reflog expire --expire=now --all`, `git gc --prune=now` |

Before any 🔴 command I explain what it changes, what it can destroy, how to preview it, how to recover, and when it is appropriate.

### 3.6 The root-cause framework

Introduced in Module 0 and used for every problem in the program.

```text
SYMPTOM -> OBSERVE -> COLLECT EVIDENCE -> UNDERSTAND STATE -> FORM HYPOTHESES -> TEST HYPOTHESES
        -> IDENTIFY ROOT CAUSE -> SELECT LOWEST-RISK FIX -> EXECUTE -> VERIFY -> PREVENT
```

Every unexpected behavior is explained in the same shape: observed behavior, Git state, underlying mechanism, root cause, why Git behaves this way, correct fix, prevention. Each explanation names the layer that acted: a Git default, a GitHub rule, or an Actions default.

### 3.7 The verification rule

- For every version-sensitive fact I re-check the live primary source on the day we cover it, and I show you the evidence.
- Every command I ask you to run has been run or checked against the man page on your Git version first.
- Stable fundamentals, current Git behavior, current GitHub behavior, version-specific behavior, and outdated behavior are labelled separately, as in the Phase 0 report.
- If I cannot verify something, I say so.

---

## 4. Mastery gates

These are your thresholds, placed where the material completes.

| Gate | Threshold | Taken after | Covers |
|---|---|---|---|
| Fundamentals | 85% | Module 5 | Data model, three trees, commits, refs, HEAD, configuration |
| Branching | 90% | Module 7 | Branches as refs, divergence, ancestry, upstream tracking, remote-tracking refs, fetch, pull, push |
| Merge and rebase | 90% | Module 10 | Three-way merge, conflicts and stages, undo choices, rebase, cherry-pick, range notation |
| Recovery | 90% | Module 15 | Forensics, reflog, fsck, every disaster lab, what cannot be recovered |
| Internals | 85% | Module 18 | Object database, packfiles, index format, ref storage, transfer and scale |
| GitHub | 85% | Module 25 | Platform model, authentication, pull requests, merge methods, rulesets, CODEOWNERS, signing, CLI |
| Actions | 85% | Module 28 | Workflow model, the first eleven workflows, runners, CI debugging |
| Security | 90% | Module 31 | Actions security, repository security, secret-leak response |
| Production debugging | 90% | Module 38 | Diagnosis method, the ten incidents, communication and postmortems |

**How a gate is scored**

| Component | Weight | Form |
|---|---|---|
| Concepts | 30% | Written questions that require mechanism, not definitions |
| Prediction | 20% | Given a graph or a state and a command, predict the output and the new state |
| Hands-on diagnosis | 30% | A generated broken repository; graded on end state, safety of the path, and your explanation |
| Oral interview | 20% | CTO-style questions, one at a time |

A pass needs the threshold overall and at least 70% in every component. A miss leads to targeted remediation on the weak areas and a different variant of the gate. I do not hand out the answers to a failed gate.

---

## 5. Lab environment

### 5.1 Design

| Element | Design | Why |
|---|---|---|
| Course home | One persistent folder that you choose, for example `~/git-mastery`, with `labs/`, `notes/` and `deliverables/` | The current session workspace is temporary |
| Config isolation | Labs run with the `GIT_CONFIG_GLOBAL` environment variable pointing at a lab config file | Experiments never touch your real `~/.gitconfig`; defaults can be studied in a clean state |
| Local "server" | Bare repositories on disk act as remotes; extra clones act as teammates | Remote and force-push labs need no network and are safe to break |
| Generated incident repositories | A script builds a repository in a broken state; you receive symptoms only | Level 4 and Level 5 exercises need evidence you did not create yourself |
| GitHub side | A free GitHub organization with public practice repositories, created by you | Rulesets, CODEOWNERS enforcement and environment reviewers work on public repositories on the Free plan |
| Plan-gated features | Evaluate mode, metadata restrictions, push rulesets, merge queue on private repositories | Taught from documentation and labelled as not practised |

You create accounts, organizations, tokens and keys yourself. I never enter credentials or create accounts for you.

### 5.2 The lab format

Every lab contains: Objective, Prerequisites, Setup, Commands, Expected output, What happened internally, Checkpoint, Failure scenario, Recovery, Verification, Questions.

### 5.3 Your toolchain today

Read from your machine on 1 October 2026.

| Tool | Installed | Needed for | Action |
|---|---|---|---|
| Git, Homebrew, first on `PATH` | 2.55.0 | Everything | Optional upgrade to 2.56.0; only four demos need it |
| Git, Apple, `/usr/bin/git` | 2.50.1 | Awareness only | None; know that two Gits exist |
| GitHub CLI | 2.88.1 | Levels 5 to 7 | Upgrade in Module 0; latest is 2.102.0 with six security-fix releases since yours |
| git-lfs | 3.7.1 | Module 15 | Optional; latest is 3.8.0 |
| `scalar`, `git subtree` | Present | Modules 15, 18 | None |
| git-filter-repo | Not installed | Module 31 | Install in Module 31 |
| GnuPG, OpenSSH 10.2 | Present | Modules 20, 24 | None |
| Python 3.14.6, uv 0.11.26, Docker | Present | Levels 6 and 8 | None |
| pre-commit | Not installed | Modules 14, 33 | Install in Module 14 |
| Java JDK | Not installed | Workflow 5 | Optional; the Java workflow runs on GitHub's runners |

---

## 6. The learning path at a glance

```text
Level 0   Orientation ............................ Module 0
   |
Level 1   BEGINNER: foundations .................. Modules 1-5     GATE  Fundamentals       85%
   |
Level 2   INTERMEDIATE: integration .............. Modules 6-10    GATES Branching          90%
   |                                                                     Merge and rebase   90%
Level 3   ADVANCED: investigation and recovery ... Modules 11-15   GATE  Recovery           90%
   |
Level 4   GIT INTERNALS .......................... Modules 16-18   GATE  Internals          85%
   |
Level 5   GITHUB ................................. Modules 19-25   GATE  GitHub             85%
   |
Level 6   CI/CD with GitHub Actions .............. Modules 26-28   GATE  Actions            85%
   |
Level 7   SECURITY ............................... Modules 29-31   GATE  Security           90%
   |
Level 8   PROFESSIONAL PRACTICE .................. Modules 32-34   Design review
   |
Level 9   PRODUCTION DEBUGGING and
          INCIDENT RESPONSE ...................... Modules 35-38   GATE  Production debug   90%
   |
Level 10  SENIOR ENGINEER: assessment ............ Modules 39-41   Final test, capstone
   |
Level 11  EXPERT: the frontier ................... Module 42
```

A note on order. Your ladder puts Git internals after the advanced level, and Level 4 honors that for the storage layer: packfiles, the index file format, ref backends, and the wire protocol. The object model itself cannot wait that long, because every explanation in Levels 1 to 3 depends on it. Module 1 therefore teaches blobs, trees, commits and refs by building a commit by hand.

| Level | Modules | Estimated effort | Outcome |
|---|---|---|---|
| 0 | 0 | 1 to 2 h | A safe lab and a working method |
| 1 | 1 to 5 | 15 to 20 h | You can predict what any basic command does to the working tree, the index, HEAD and `.git` |
| 2 | 6 to 10 | 22 to 28 h | You can explain any merge, rebase, pull, push or undo from the commit graph |
| 3 | 11 to 15 | 20 to 25 h | You can investigate history and recover from every common disaster |
| 4 | 16 to 18 | 10 to 14 h | You can explain how Git stores, packs, transfers and maintains data |
| 5 | 19 to 25 | 20 to 26 h | You can run and govern a repository on GitHub and explain what the platform does to your Git data |
| 6 | 26 to 28 | 14 to 18 h | You can write, debug and reason about workflows |
| 7 | 29 to 31 | 12 to 16 h | You can secure workflows and repositories and lead a secret-leak response |
| 8 | 32 to 34 | 9 to 12 h | You can choose and defend a team workflow, including for AI/ML repositories |
| 9 | 35 to 38 | 14 to 18 h | You can diagnose production incidents from incomplete evidence and communicate them |
| 10 | 39 to 41 | 12 to 16 h | You have been tested at CTO level and have run a full production simulation |
| 11 | 42 | 3 to 5 h | You can follow where Git is going and read its primary sources unaided |

The effort figures are estimates, about 150 to 200 hours in total. They are not commitments, and gates decide the pace.

---

## 7. Module-by-module roadmap

Each module lists what you will be able to do, the topics, the labs, the primary sources, an optional video, and the parts of your brief it covers. "§" numbers refer to the numbered sections of your master prompt. "Ch." numbers refer to the 35-chapter textbook outline you specified.

### LEVEL 0: Orientation

#### Module 0: Lab setup and working method

- **You will be able to:** work in an isolated lab, state which Git and which GitHub CLI you are running, and apply the root-cause framework and the ten-command diagnosis as a habit.
- **Topics:** the two Gits on your Mac; upgrading the GitHub CLI and its opt-out telemetry setting introduced in 2.91.0; the optional Git 2.56 upgrade; the course folder; `GIT_CONFIG_GLOBAL` isolation; the practice organization on GitHub; risk labels; the root-cause framework; the diagnosis ritual `git status`, `git branch -vv`, `git remote -v`, `git log --graph --decorate --oneline --all`, `git reflog`, `git rev-parse`, `git show`, `git diff`, `git diff --cached`, `git config list --show-origin --show-scope`, `git ls-files`.
- **Lab 0:** verify versions, build the sandbox, create an empty repository, and read every file in its `.git` directory.
- **Primary sources:** [git(1)](https://git-scm.com/docs/git), [gitrepository-layout](https://git-scm.com/docs/gitrepository-layout).
- **Covers:** §45, §46, §50, §55.

### LEVEL 1: Beginner — foundations

Optional first pass, only if you want a refresher before Module 1: ["Learn Git & GitHub for Beginners (2026)"](https://www.youtube.com/watch?v=h2a3Kw-I_Ec) by Coder Coder in English, or ["Git Tutorial for Beginners: Learn Git in One Video"](https://www.youtube.com/watch?v=AB3J8ufDYHQ) by CodeWithHarry in Hindi. The second teaches no reset, revert or reflog, and it first calls a branch a copy before correcting itself to a pointer.

#### Module 1: What Git actually is

- **You will be able to:** explain Git as a content-addressed object store plus named references, and build a commit by hand without `git add` or `git commit`.
- **Topics:** snapshots, not diffs; blob, tree, commit and annotated tag objects; object IDs as hashes of content; the commit graph as a directed acyclic graph; parent pointers and reachability; references as names for commit IDs; where the working tree, the index and the repository live; Git the tool versus GitHub the platform.
- **Labs:** create a blob with `git hash-object -w`; register it with `git update-index --add --cacheinfo`; write a tree with `git write-tree`; create a commit with `git commit-tree`; point a branch at it with `git update-ref`; inspect each step with `git cat-file -t` and `git cat-file -p` and `git ls-tree`.
- **Primary sources:** [gitdatamodel](https://git-scm.com/docs/gitdatamodel), available on your machine as `git help datamodel`; [gitglossary](https://git-scm.com/docs/gitglossary); [Pro Git chapter 10](https://git-scm.com/book/en/v2).
- **Video (optional):** [MIT Missing Semester 2026, Lecture 5](https://www.youtube.com/watch?v=9K8lB61dl3Y) with its [notes](https://missing.csail.mit.edu/2026/version-control/); then [Git Internals by John Britton](https://www.youtube.com/watch?v=lG90LZotrpo). In Hindi, [Chai aur Code's course](https://www.youtube.com/watch?v=q8EevlEpQ2A) from 55:16.
- **Covers:** §6 first pass, §63, §64. Ch. 1, 2, 3.

#### Module 2: Working tree, index, and HEAD

- **You will be able to:** predict the content of all three trees after any staging command, and explain `git status` as two comparisons.
- **Topics:** tracked, untracked and ignored files; what `git add` writes, a blob and an index entry; `git diff` versus `git diff --cached` versus `git diff HEAD`; partial staging with `git add -p`; intent-to-add with `git add -N`; staging deletions; why Git does not record renames; binary files; `git restore` versus `git restore --staged`; `git rm --cached`; ignore rules and the already-tracked trap; reading the index with `git ls-files --stage`.
- **Labs:** a predict-then-verify table of working tree, index and HEAD after each command; the `.gitignore` trap and its fix.
- **Primary sources:** [git-add](https://git-scm.com/docs/git-add), [git-restore](https://git-scm.com/docs/git-restore), [git-status](https://git-scm.com/docs/git-status), [git-diff](https://git-scm.com/docs/git-diff), [gitignore](https://git-scm.com/docs/gitignore).
- **Covers:** §7, §18 first part. Ch. 4, 5.

#### Module 3: Commits

- **You will be able to:** read a commit at the object level and explain why any change to content, parent, author, committer, time or message yields a different ID.
- **Topics:** tree, parents, author versus committer, both timestamps, message and trailers; root commits; merge commits and multiple parents; `git commit --amend` creates a new commit; empty commits with `--allow-empty`; commit message craft; `git show --format=fuller`; `git log` basics.
- **Labs:** amend a commit and find the old one; change only the committer date and watch the ID change; write a commit with trailers.
- **Primary sources:** [git-commit](https://git-scm.com/docs/git-commit), [git-show](https://git-scm.com/docs/git-show), [git-cat-file](https://git-scm.com/docs/git-cat-file).
- **Covers:** §8, §19 basics. Ch. 6.

#### Module 4: Refs, branches, HEAD, and detached HEAD

- **You will be able to:** explain a branch as a reference to a commit, explain HEAD as a symbolic reference, and work in detached HEAD without losing commits.
- **Topics:** creating, moving and deleting a branch as writing and deleting a ref; HEAD normally points to a branch; detached HEAD, why it happens, why it is not an error, and how to keep the work; lightweight tags as refs; `git switch`, `git switch -c`, `git switch --detach`, `git branch`, `git rev-parse`, `git symbolic-ref`, `git for-each-ref`; first contact with `git reflog`; branch naming conventions; stale branches. `git branch --delete-merged` is shown as a Git 2.56 addition.
- **Labs:** read and write refs with plumbing and compare with porcelain; detach HEAD, commit, switch away, then rescue the commit.
- **Primary sources:** [git-branch](https://git-scm.com/docs/git-branch), [git-switch](https://git-scm.com/docs/git-switch), [git-symbolic-ref](https://git-scm.com/docs/git-symbolic-ref), [gitrevisions](https://git-scm.com/docs/gitrevisions).
- **Video (optional):** [Telusko, "Git For Beginners"](https://www.youtube.com/watch?v=vwj89i2FmG0), which asks whether a branch copies the project and explains why it does not.
- **Covers:** §9, §17, §22 first pass. Ch. 7.

#### Module 5: Configuration, identity, and a professional setup

- **You will be able to:** say where every setting comes from and justify each line of your own configuration.
- **Topics:** system, global, local and worktree scopes; `git config list --show-origin --show-scope`; the `git config get`, `set` and `unset` subcommands, which need Git 2.46 or later; include files and `includeIf`; identity; `init.defaultBranch`; pull, push, fetch, merge, rebase, diff and rerere settings considered one at a time with their downside and whether each is personal or team-specific; credential helper overview; aliases verified on your machine: `st`, `lg`, `last`, `unstage`, `amend`.
- **Labs:** build your configuration deliberately; write an alias set you can explain line by line.
- **Primary sources:** [git-config](https://git-scm.com/docs/git-config), [gitcredentials](https://git-scm.com/docs/gitcredentials).
- **Covers:** §23, §24, §57 first pass. Ch. 14.

**GATE: Fundamentals, 85%.**

### LEVEL 2: Intermediate — integration and collaboration mechanics

Optional hands-on backbone for Levels 2 and 3: ["Git and GitHub - Full Course"](https://www.youtube.com/watch?v=rH3zE7VlIMs) by ThePrimeagen for Boot.dev, with chapters on branching at 49:19, merge at 1:03:27, rebase at 1:17:01, reset at 1:36:16, remotes at 1:54:18, reflog at 2:32:14 and bisect at 3:54:53.

#### Module 6: Divergence and merge

- **You will be able to:** find the merge base of any two commits, predict whether a merge fast-forwards, and resolve a conflict by reading the three index stages.
- **Topics:** divergence and ancestry; `git merge-base`; fast-forward versus three-way merge; the `ort` strategy, default since 2.34; merge commits; `--no-ff`, `--ff-only`, `--squash`; why conflicts occur; conflict markers; index stages 1, 2 and 3 and the `:1:path` syntax; `merge.conflictStyle` and `zdiff3`; the exact meaning of ours and theirs; `-X ours` versus `-s ours`; `git merge --abort` and `--continue`; octopus merges; merges that are clean for Git and wrong for humans; auditing a resolution with `git log --remerge-diff`; rerere introduced. `git add --resolved` is shown as a Git 2.56 addition.
- **Labs:** four conflict scenarios: edit against edit, rename against edit, delete against modify, and a clean merge that breaks the build.
- **Primary sources:** [git-merge](https://git-scm.com/docs/git-merge), [git-merge-base](https://git-scm.com/docs/git-merge-base), [gitrevisions](https://git-scm.com/docs/gitrevisions).
- **Video (optional):** [David Mahler, "Branching and Merging"](https://www.youtube.com/watch?v=FyAAIHHClqI).
- **Covers:** §9, §10. Ch. 7, 8.

#### Module 7: Remotes, fetch, pull, and push

- **You will be able to:** explain exactly which refs move on fetch, pull and push, and why "up to date" only describes your last fetch.
- **Topics:** a remote as a name, URLs and refspecs; `git clone` step by step; remote-tracking refs as the last-known state of the remote; `git fetch` and `FETCH_HEAD`; `git pull` as fetch plus a configured integration step; `pull.rebase` and `pull.ff`; the fatal error on diverged branches, in place since 2.33.1 and 2.34; `git push`, the fast-forward rule, `push.default`, upstream configuration, `push.autoSetupRemote`; `fetch.prune`; fetch and push refspecs; multiple remotes, `origin` and `upstream`; separate fetch and push URLs; remote rename and removal; `git ls-remote`; `git branch -vv`.
- **Labs:** a bare repository as the server and two clones as teammates; watch every ref before and after each operation; reproduce and resolve a rejected push.
- **Primary sources:** [git-fetch](https://git-scm.com/docs/git-fetch), [git-pull](https://git-scm.com/docs/git-pull), [git-push](https://git-scm.com/docs/git-push), [git-remote](https://git-scm.com/docs/git-remote).
- **Video (optional):** [David Mahler, "Introduction to Git - Remotes"](https://www.youtube.com/watch?v=Gg4bLk8cGNo).
- **Covers:** §14, §15. Ch. 12.

**GATE: Branching, 90%.**

#### Module 8: Undo: restore, reset, revert, clean, and stash

- **You will be able to:** choose the lowest-risk undo for any situation and state its effect on HEAD, the branch, the index, the working tree and history.
- **Topics:** the comparison table you asked for; `git reset --soft`, `--mixed` and `--hard`; why `--hard` is dangerous, since work that was never staged or committed has no object; `git revert` as a new commit; reverting a merge with `-m`; `git restore --source`; `git clean -n` before `git clean -fd`; stash as commits; private history versus shared history as the deciding question.
- **Labs:** scenario cards; for each, pick an undo, justify it, perform it, and verify the state.
- **Primary sources:** [git-reset](https://git-scm.com/docs/git-reset), [git-revert](https://git-scm.com/docs/git-revert), [git-restore](https://git-scm.com/docs/git-restore), [git-clean](https://git-scm.com/docs/git-clean), [git-stash](https://git-scm.com/docs/git-stash).
- **Video (optional):** [Tobias Günther, "How to Undo Mistakes With Git Using the Command Line"](https://www.youtube.com/watch?v=lX9hsdsAeTk). In Hindi, [ProCodrr episode 6](https://www.youtube.com/watch?v=qF8CHHnWqXE).
- **Covers:** §12. Ch. 11.

#### Module 9: Rebase

- **You will be able to:** explain why rebase changes commit IDs, perform every interactive operation, recover from a bad rebase, and update a remote branch safely afterwards.
- **Topics:** rebase as replaying commits onto a new base as new commits; `git rebase --onto` with three arguments; interactive rebase: reword, edit, squash, fixup, drop, reorder and exec; `git commit --fixup` with `--autosquash`; `--update-refs`; `--rebase-merges`, the replacement for the removed `--preserve-merges`; conflicts during a rebase and why ours and theirs are swapped; `--abort`, `--continue` and `--skip`; reviewing a rebase with `git range-diff`; the rule about published history; `git push --force-with-lease --force-if-includes` and the documented way a background fetch defeats the bare lease; `git pull --rebase`.
- **Labs:** clean up a messy branch; move a branch with `--onto`; break a branch on purpose with a bad rebase and recover it through `ORIG_HEAD` and the reflog.
- **Primary sources:** [git-rebase](https://git-scm.com/docs/git-rebase), [git-range-diff](https://git-scm.com/docs/git-range-diff), [git-push](https://git-scm.com/docs/git-push).
- **Video (optional):** [Philomatics, "git rebase - Why, When & How to fix conflicts"](https://www.youtube.com/watch?v=DkWDHzmMvyg); [Tobias Günther, "Advanced Git Tutorial"](https://www.youtube.com/watch?v=qsTthZi23VE).
- **Covers:** §11, §55 in part. Ch. 9.

#### Module 10: Cherry-pick and range notation

- **You will be able to:** explain cherry-pick as a three-way merge, predict duplicate commits, and read `A..B` and `A...B` correctly for both `git log` and `git diff`.
- **Topics:** what cherry-pick does and why it creates a new commit with a new ID; `-x`; ranges; `--abort`, `--continue`, `--skip`; conflicts; backports and hotfixes; when not to use it; two-dot and three-dot notation drawn on commit graphs; why a pull request shows a three-dot diff.
- **Labs:** backport a fix to a release branch; predict log and diff output from drawn graphs before running the commands.
- **Primary sources:** [git-cherry-pick](https://git-scm.com/docs/git-cherry-pick), [gitrevisions](https://git-scm.com/docs/gitrevisions), [git-diff](https://git-scm.com/docs/git-diff).
- **Covers:** §13, §18. Ch. 10.

**GATE: Merge and rebase, 90%.**

### LEVEL 3: Advanced — investigation, recovery, and power tools

#### Module 11: History investigation and forensics

- **You will be able to:** answer "when, where and why did this change" for any line, and find the commit that introduced a regression by binary search.
- **Topics:** `git log` as a graph query: `--graph`, `--oneline`, `--decorate`, `--all`, `--first-parent`, `--stat`, `-p`, `--follow`, `-S` versus `-G`, `-L`, `--reflog`; revision selection; what `git blame` tells you and what it does not; `-w`, `-M`, `-C`; `--ignore-rev` and `--ignore-revs-file`; `git bisect start`, `bad`, `good`, `skip`, `reset`; automated `git bisect run`; `git grep`; `git shortlog`. The `--reset-when-found` option of `git bisect` is listed in the Git 2.56 release notes; its exact usage is confirmed from the 2.56 man page if you upgrade.
- **Labs:** forensic exercises on a prepared repository: trace a line across a rename; find when a string was removed; identify a regression with an automated bisect.
- **Primary sources:** [git-log](https://git-scm.com/docs/git-log), [git-blame](https://git-scm.com/docs/git-blame), [git-bisect](https://git-scm.com/docs/git-bisect).
- **Video (optional):** [Tekin Süleyman, "Branch in Time"](https://www.youtube.com/watch?v=8OOTVxKDwe0).
- **Covers:** §19, §20, §21. Ch. 14.

#### Module 12: Recovery and disaster recovery

- **You will be able to:** recover from every listed disaster, and state precisely what cannot be recovered and why.
- **Topics:** reachability; the HEAD reflog and per-branch reflogs; retention: 90 days, 30 days for unreachable entries, and a two-week prune grace period; the exceptions: a deleted branch loses its reflog, bare repositories keep none by default, a dropped stash; `ORIG_HEAD`; `git fsck --lost-found`, dangling and unreachable objects; `git reflog expire` and `git gc --prune=now` as the documented way to destroy the safety net; repository corruption basics.
- **Disaster labs, each done twice, first guided and then from symptoms only:** accidental hard reset; deleted branch; deleted commit; wrong rebase; bad merge; commit on the wrong branch; lost work in detached HEAD; overwritten changes; wrong cherry-pick; broken remote-tracking state; a force push seen from the local side; dangling objects.
- **Primary sources:** [git-reflog](https://git-scm.com/docs/git-reflog), [git-fsck](https://git-scm.com/docs/git-fsck), [git-gc](https://git-scm.com/docs/git-gc), [gitfaq](https://git-scm.com/docs/gitfaq).
- **Video (optional):** [System Crafters, "How to Rescue Your Commits with Git Reflog"](https://www.youtube.com/watch?v=K7-wrGpnqUM). In Hindi, [Chai aur Code's deleted-branch scenario](https://www.youtube.com/watch?v=jXoOEfpgzF4).
- **Produces:** first versions of the disaster-recovery playbook and the one-page emergency cheat sheet.
- **Covers:** §16, §17. Ch. 13.

#### Module 13: Tags, versions, and release mechanics in Git

- **You will be able to:** explain the three kinds of tag at the object level and derive a version from history.
- **Topics:** lightweight, annotated and signed tags; tag objects; why tags should not move and what breaks when one does; how tags are fetched and pushed; `git describe`; semantic versioning; release branches on the Git side.
- **Labs:** create all three kinds; inspect a tag object; reproduce a moved-tag problem between two clones.
- **Primary sources:** [git-tag](https://git-scm.com/docs/git-tag), [git-describe](https://git-scm.com/docs/git-describe), [Semantic Versioning 2.0.0](https://semver.org/).
- **Covers:** §22 Git side. Ch. 14.

#### Module 14: Worktrees, stash internals, rerere, attributes, and hooks

- **You will be able to:** use several working trees on one repository, automate conflict reuse, and write hooks while knowing why they cannot enforce policy.
- **Topics:** `git worktree add`, `list`, `remove` and how working trees share one object store; stash internals; rerere in practice; `.gitattributes`: line endings, diff and merge drivers, clean and smudge filters; hooks: `pre-commit`, `commit-msg`, `post-commit`, `pre-push`, `post-checkout`, `post-merge`, `pre-rebase`, and the server-side hooks; `core.hooksPath`; hooks defined in configuration since Git 2.54; hook security; the pre-commit framework.
- **Labs:** a hotfix in a second worktree while a rebase is in progress in the first; a `commit-msg` hook; a `pre-push` guard; a filter demonstration.
- **Primary sources:** [git-worktree](https://git-scm.com/docs/git-worktree), [git-rerere](https://git-scm.com/docs/git-rerere), [gitattributes](https://git-scm.com/docs/gitattributes), [githooks](https://git-scm.com/docs/githooks).
- **Video (optional):** Scott Chacon, ["So You Think You Know Git"](https://www.youtube.com/watch?v=aolI_Rz0ZqY) and [Part 2](https://www.youtube.com/watch?v=Md44rcw13k4).
- **Covers:** §25, §41. Ch. 14, 25.

#### Module 15: Submodules, subtrees, and Git LFS

- **You will be able to:** explain a submodule as a recorded commit ID, diagnose the standard submodule failures, and decide when LFS is the wrong tool.
- **Topics:** gitlinks and `.gitmodules`; initialization, update and recursion; the detached state after update; common failures and CI consequences; subtrees as an alternative; why LFS exists; pointer files and filters; tracking; clone behavior without the client; `git lfs migrate`; GitHub's file limits and metered LFS billing; the security note on recursive clones of untrusted repositories.
- **Labs:** a superproject with a submodule that breaks for a teammate; the same dependency as a subtree; an LFS-tracked binary inspected as a pointer.
- **Primary sources:** [git-submodule](https://git-scm.com/docs/git-submodule), [gitsubmodules](https://git-scm.com/docs/gitsubmodules), [Pro Git: Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules), [About Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage).
- **Covers:** §38, §39. Ch. 22, 23.

**GATE: Recovery, 90%.**

### LEVEL 4: Git internals

#### Module 16: The object database: loose objects, packfiles, and maintenance

- **You will be able to:** explain how Git stores a million objects efficiently without changing the snapshot model, and what maintenance does to unreachable objects.
- **Topics:** loose objects and compression; packfiles and pack indexes; delta compression as a storage detail; `git count-objects -v`, `git verify-pack -v`, `git cat-file --batch-check --batch-all-objects`; repacking; cruft packs; `git gc` versus `git maintenance` and the geometric strategy, default since 2.54; garbage collection and reachability.
- **Labs:** watch loose objects become a pack; read a pack listing and find a delta chain; trace what a maintenance run does.
- **Primary sources:** [gitformat-pack](https://git-scm.com/docs/gitformat-pack), [git-maintenance](https://git-scm.com/docs/git-maintenance), [git-gc](https://git-scm.com/docs/git-gc), [GitHub Blog: Git's database internals, part I](https://github.blog/open-source/git/gits-database-internals-i-packed-object-store/).
- **Video (optional):** [Derrick Stolee, "Git Internals: a Database Perspective"](https://www.youtube.com/watch?v=YdstUWcg5j4).
- **Covers:** §6, §42. Ch. 3, 26.

#### Module 17: The index file, ref storage, and the `.git` directory

- **You will be able to:** read the index as a data structure, explain loose refs, packed refs and reftable, and name every special file under `.git`.
- **Topics:** index entries, cached file metadata, flags, stage numbers and extensions; loose refs and `packed-refs`; the reftable backend, available since 2.45; reflog storage; `HEAD`, `ORIG_HEAD`, `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `REBASE_HEAD`, `FETCH_HEAD`, and the glossary's narrowed use of "pseudoref" since 2.46; SHA-1 with collision detection versus SHA-256; what Git 3.0 plans to change for new repositories.
- **Labs:** inspect one repository in the files format and one created with `git init --ref-format=reftable`; show why format-independent plumbing is the safe habit.
- **Primary sources:** [gitformat-index](https://git-scm.com/docs/gitformat-index), [gitrepository-layout](https://git-scm.com/docs/gitrepository-layout), [reftable](https://git-scm.com/docs/reftable), [BreakingChanges](https://git-scm.com/docs/BreakingChanges).
- **Covers:** §6, §7. Ch. 3, 5.

#### Module 18: Transfer, scale, and performance

- **You will be able to:** choose between shallow clone, partial clone and sparse-checkout for a given situation, and explain what makes a large repository slow.
- **Topics:** the fetch and push conversation at concept level; shallow clones and their limits; partial clone with `--filter=blob:none`; `git sparse-checkout` in cone mode, still labelled experimental in the 2.56 documentation; `scalar`; commit-graph, multi-pack-index, reachability bitmaps and the filesystem monitor; bundles; monorepo trade-offs and when these features matter in real companies.
- **Labs:** clone one repository three ways and compare what arrived; measure a history query with and without a commit-graph.
- **Primary sources:** [partial-clone](https://git-scm.com/docs/partial-clone), [git-sparse-checkout](https://git-scm.com/docs/git-sparse-checkout), [scalar](https://git-scm.com/docs/scalar), [GitHub Blog: partial clone and shallow clone](https://github.blog/open-source/git/get-up-to-speed-with-partial-clone-and-shallow-clone/).
- **Video (optional):** [Derrick Stolee, "Git at Scale for Everyone"](https://www.youtube.com/watch?v=USLB1gwl1vA).
- **Optional project:** [Write yourself a Git](https://wyag.thb.lt/).
- **Covers:** §40, §42. Ch. 24, 26.

**GATE: Internals, 85%.**

### LEVEL 5: GitHub

From this level on, every GitHub fact is re-checked against docs.github.com and the GitHub Changelog on the day of the lesson. GitHub changes on a scale of months.

#### Module 19: GitHub the platform

- **You will be able to:** say for any feature whether it is Git data or a GitHub object, and explain who can do what in a repository.
- **Topics:** what GitHub adds on top of Git; personal accounts, organizations and enterprise accounts; teams, members, outside collaborators; the five repository roles; repository settings; forks and the fork network, including the documented fact that a network shares Git data; stars and watchers; Issues with sub-issues and issue types; Projects; Discussions; wikis; Packages and the container registry; Releases; templates and community health files; a professional repository layout explained file by file.
- **Labs:** create the practice organization and a public practice repository with README, LICENSE, CONTRIBUTING, SECURITY, issue and pull request templates.
- **Primary sources:** [repository roles](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization), [forks reference](https://docs.github.com/en/pull-requests/reference/forks), [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow).
- **Covers:** §27, §49. Ch. 15.

#### Module 20: Authentication and SSH

- **You will be able to:** diagnose any authentication or authorization failure from its error text to its root cause, without copying commands blindly.
- **Topics:** authentication versus authorization; HTTPS with tokens; fine-grained tokens and their documented gaps; classic tokens where a gap forces them; credential helpers, the GitHub CLI and Git Credential Manager; why a token must never be written into a remote URL; SSH key pairs, `ssh-agent`, `known_hosts` and host key verification; GitHub's host keys; `~/.ssh/config` and host aliases; two GitHub identities on one machine with `includeIf`; GitHub Apps and OAuth apps at concept level; deploy keys; single sign-on authorization; the error table: `Permission denied (publickey)`, `Repository not found`, 401, 403, `Host key verification failed`, `Could not read from remote repository`. The SSH changes dated 14 October 2026 and 13 January 2027 are covered.
- **Labs:** set up SSH and HTTPS access and verify each; reproduce three failures on purpose and diagnose them; an optional two-identity setup.
- **Primary sources:** [managing personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens), [generating an SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent), [Permission denied (publickey)](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-denied-publickey), [troubleshooting cloning errors](https://docs.github.com/en/repositories/creating-and-managing-repositories/troubleshooting-cloning-errors), [credential types](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/github-credential-types).
- **Covers:** §28, §29. Ch. 16.

#### Module 21: Pull requests, review, and the fork workflow

- **You will be able to:** explain what GitHub creates when a pull request opens, and why a pull request can show unexpected commits.
- **Topics:** a pull request as a GitHub object built on hidden refs; fetching a pull request head with plain Git; the test merge commit and its regeneration rules since 19 February 2026; the three-dot diff; the lifecycle: draft, review, approval, requested changes, comments, suggestions, stale approvals and dismissal; checks and mergeability; the fork workflow from upstream to fork to clone to branch to pull request; keeping a fork in sync; the documented causes of a pull request with hundreds of unrelated changes; stacked pull requests, in public preview since 30 July 2026.
- **Labs:** a full fork-and-pull-request cycle with a second account or a teammate; reproduce and fix a pull request opened against the wrong base; reproduce the squash-then-reuse-the-branch problem.
- **Primary sources:** [pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests), [forks reference](https://docs.github.com/en/pull-requests/reference/forks), [stacked pull requests](https://docs.github.com/en/pull-requests/reference/stacked-pull-requests).
- **Video (optional):** pull request chapters, 40:44 to 47:14, of [GitHub's beginner guide](https://www.youtube.com/watch?v=NUELGzIHT-I). No verified video teaches GitHub code review end to end in the 2026 interface.
- **Covers:** §30, §31. Ch. 17, 27.

#### Module 22: Merge methods, merge queue, and releases on GitHub

- **You will be able to:** choose a merge method for a team and defend the trade-offs, and explain a Git tag versus a GitHub Release.
- **Topics:** merge commit, squash and merge, rebase and merge: what lands, which commit IDs change, who the committer is, and what is signed; consequences for bisect, blame, revert and traceability; auto-merge; merge queue and the `merge_group` event; a tag as Git data versus a release as a GitHub object; how creating a release can create a tag; immutable releases; release notes and automation.
- **Labs:** merge the same pull request three ways in three repositories and compare the resulting graphs; cut a release from an annotated tag.
- **Primary sources:** [merge methods](https://docs.github.com/en/pull-requests/reference/pull-request-merges), [merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue), [about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases), [immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases).
- **Covers:** §22 GitHub side, §32. Ch. 17.

#### Module 23: Governance: rulesets, branch protection, and CODEOWNERS

- **You will be able to:** design the protection for a production branch, and debug "why can't I merge" across every rule layer.
- **Topics:** rulesets first: targets, rules, enforcement status, layering, bypass and exempt actors; classic branch protection and how it layers with rulesets; required reviews and their sub-options; required status checks and the skipped-check traps; conversation resolution; signed commits; linear history; force-push and deletion restrictions; tag rulesets; organization-level rulesets; CODEOWNERS syntax, file locations, last-match-wins, unsupported patterns, the write-access requirement, monorepo usage, and why the file only requests reviews until a rule requires them; plan gates.
- **Labs:** protect the practice repository's default branch with a ruleset; add CODEOWNERS and prove enforcement with a second account; reproduce three blocked-merge cases and diagnose them from the `/rules` page.
- **Primary sources:** [about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets), [available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets), [about protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), [about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners), [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks).
- **Video (optional):** [Mickey Gousset on repository rulesets](https://www.youtube.com/watch?v=ZTbM-h9RZOo); [GitHub Universe 2024, "Securely building GitHub on GitHub"](https://www.youtube.com/watch?v=eig5tJUl688), which predates the 2025 and 2026 ruleset additions.
- **Covers:** §33, §34. Ch. 18, 19.

#### Module 24: Commit signing and verification

- **You will be able to:** sign commits and tags, verify them locally, and explain what a "Verified" badge does and does not prove.
- **Topics:** the trust model; author fields as assertions and the spoofing problem; OpenPGP, SSH and X.509 signing in Git; `gpg.format`, `user.signingKey`, `commit.gpgSign`, `tag.gpgSign`, `gpg.ssh.allowedSignersFile`; where a signature lives in a commit object; GitHub's Verified, Partially verified and Unverified states; vigilant mode; persistent verification records; commits signed by GitHub in the web interface; why rebase-and-merge produces unsigned commits; key management.
- **Labs:** SSH signing end to end; local verification with an allowed-signers file; a spoofed-author commit on a practice repository and what GitHub shows.
- **Primary sources:** [commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification), [gitformat-signature](https://git-scm.com/docs/gitformat-signature), [git-config](https://git-scm.com/docs/git-config).
- **Video (optional):** [Git Merge 2022 workshop on SSH commit signing](https://www.youtube.com/watch?v=uhy_ojFqLg0).
- **Covers:** §26. Ch. 21.

#### Module 25: GitHub CLI and API

- **You will be able to:** drive the whole pull request and CI loop from the terminal and reach anything else through the API.
- **Topics:** `gh auth`, `gh repo`, `gh issue`, `gh pr`, `gh run`, `gh workflow`, `gh release`, `gh secret`, `gh variable`, `gh ruleset`, `gh cache`, `gh attestation`, `gh api`; why `gh ruleset` is read-only and rulesets are automated through the API; REST API versioning with the `X-GitHub-Api-Version` header; GraphQL at concept level; rate limits; webhooks and GitHub Apps as the integration model.
- **Labs:** a complete feature cycle with `gh` only; query pull request and ruleset data with `gh api`.
- **Primary sources:** [GitHub CLI manual](https://cli.github.com/manual/gh), [API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions).
- **Covers:** §37. Ch. 15, 33.

**GATE: GitHub, 85%.**

### LEVEL 6: CI/CD with GitHub Actions

Action versions and runner labels are re-verified on the day of each lesson. Workflows pin actions to full commit SHAs from the first example.

#### Module 26: Actions fundamentals

- **You will be able to:** read any workflow file and predict when it runs, where, with what code checked out, and with what permissions.
- **Topics:** workflow, event, trigger, job, step, action, runner, shell; YAML read carefully; event filters; contexts and expressions; `env`, variables and secrets; outputs through `GITHUB_OUTPUT`; what `actions/checkout` does by default, including one commit, no tags, and the merge ref on pull request events; default shells; job dependencies; matrix strategies.
- **Workflows built:** 1 run tests; 2 run linting; 3 build the application; 4 Python tests with uv; 5 Java tests; 10 matrix testing.
- **Primary sources:** [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts).
- **Video (optional):** [DevOps Directive, "Complete GitHub Actions Course"](https://www.youtube.com/watch?v=Xwpi0ITkL3U), which predates the Node 24-only runtime and `actions/checkout` v7 and never mentions rulesets. In Hindi, [CODERS NEVER QUIT](https://www.youtube.com/watch?v=ookIfjc8dW0).
- **Covers:** §35 first part. Ch. 20.

#### Module 27: Build, package, and deliver

- **You will be able to:** take a change from commit to a gated staging deployment with reusable building blocks.
- **Topics:** dependency caching, cache keys and scope; artifacts and retention; building and pushing a container image to the GitHub container registry; environments, required reviewers and deployment branch rules; concurrency groups; reusable workflows; composite actions; container actions; release automation.
- **Workflows built:** 6 build a Docker image; 7 create an artifact; 8 deploy to staging; 9 use environments; 11 a reusable workflow.
- **Primary sources:** [dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching), [deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments), [limits](https://docs.github.com/en/actions/reference/limits).
- **Covers:** §35 second part. Ch. 20.

#### Module 28: Runners, cost, and debugging CI

- **You will be able to:** investigate a failing workflow in a fixed order: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency.
- **Topics:** GitHub-hosted runner images and moving `-latest` labels; self-hosted runners, ephemeral runners and their risks; limits and billing; the documented causes of "passes locally, fails on GitHub Actions"; required checks that stay pending; debug logging; `gh run view --log-failed`, `gh run rerun`, `gh run watch`; linting workflows before pushing; what a local runner emulator cannot reproduce.
- **Labs:** six broken workflows to diagnose, each with a different documented root cause.
- **Primary sources:** [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [enable debug logging](https://docs.github.com/en/actions/how-tos/monitor-workflows/enable-debug-logging), [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks).
- **Covers:** §35 third part, §75 third scenario. Ch. 20, 29.

**GATE: Actions, 85%.**

### LEVEL 7: Security

#### Module 29: GitHub Actions security

- **You will be able to:** review a workflow for the known vulnerability classes and write one that is secure by default.
- **Topics:** the `GITHUB_TOKEN` and least-privilege `permissions`; the fork pull request model; `pull_request_target` and `workflow_run` risks; script injection through untrusted event fields and the environment-variable mitigation; third-party actions, mutable tags and SHA pinning with Dependabot updates; organization policies for allowed actions; OIDC federation instead of stored cloud keys; cache trust; self-hosted runner exposure; environment protection; static analysis of workflows; the platform changes of 2025 and 2026. Case studies with their post-mortems: tj-actions, Nx, GhostAction, Trivy and LiteLLM, TanStack.
- **Workflow built:** 12 a secure workflow.
- **Labs:** find and fix five planted vulnerabilities in a practice repository; write the pull request review comments a security engineer would write.
- **Primary sources:** [secure use reference](https://docs.github.com/en/actions/reference/security/secure-use), [securely using pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target), [script injections](https://docs.github.com/en/actions/concepts/security/script-injections), [GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token), [OIDC reference](https://docs.github.com/en/actions/reference/security/oidc).
- **Video (optional), in this order:** [Adnan Khan, "The dark side of GitHub Actions"](https://www.youtube.com/watch?v=76NEylOsOS0); [Niek Palm, "Weaponizing and Hardening GitHub Actions"](https://www.youtube.com/watch?v=19l6sLyR3zo); [the tj-actions incident talk from BSides PDX 2025](https://www.youtube.com/watch?v=FxHIaRwc9c4).
- **Covers:** §36. Ch. 20, 21.

#### Module 30: Repository and supply-chain security

- **You will be able to:** set up layered defenses for a repository and explain the blast radius of each credential type.
- **Topics:** secret scanning and push protection, and what they do not cover; Dependabot alerts, security updates and version updates; code scanning; security policies and private vulnerability reporting; the credential hierarchy from job-scoped tokens to classic tokens; least privilege; two-factor authentication; compromised accounts; malicious commits and author spoofing; the Git client: untrusted repositories, recursive clones, `safe.directory`, `safe.bareRepository`; malicious repositories and fake popularity.
- **Labs:** enable and test push protection on the practice repository with a dummy pattern; configure Dependabot for pip or uv, Docker and Actions; a local secret scan of full history.
- **Primary sources:** [GitHub security features](https://docs.github.com/en/code-security/getting-started/github-security-features), [about secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning), [about push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection), [Git security advisories](https://github.com/git/git/security/advisories).
- **Video (optional):** [Abhishek Veeramalla, "DevSecOps for Git and GitHub"](https://www.youtube.com/watch?v=Gd-AiV--LHs).
- **Covers:** §43. Ch. 21.

#### Module 31: Secret-leak response and history rewriting as an operation

- **You will be able to:** lead the response to a committed secret from first report to postmortem.
- **Topics:** why deleting the file is not enough; why force-pushing is not enough: clones, forks, cached views and pull request refs; rotate or revoke first; assessing exposure; when a history rewrite is warranted; `git filter-repo` as an operation: fresh clone, what it rewrites, the commit map, lost signatures, force-pushing all refs, open pull requests, forks, re-cloning, and the stale clone that pushes the secret back; the GitHub Support request; prevention.
- **Labs:** a full tabletop on a practice repository with a dummy secret: contain, assess, eradicate, recover, communicate, prevent.
- **Primary sources:** [removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository), [remediating a leaked secret](https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection/remediating-a-leaked-secret), [git-filter-repo manual](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt).
- **Video (optional):** [Elijah Newren on git-filter-repo](https://www.youtube.com/watch?v=KXPmiKfNlZE).
- **Covers:** §43, §75 second scenario. Ch. 21, 30.

**GATE: Security, 90%.**

### LEVEL 8: Professional practice

#### Module 32: Branching and release strategy

- **You will be able to:** recommend a workflow for a described team and state what evidence supports it and what does not.
- **Topics:** GitHub Flow, Git Flow with its author's 2020 restriction, trunk-based development, release branches, feature branches, hotfix flow; `main`, `develop`, `feature/*`, `bugfix/*`, `hotfix/*`, `release/*` as conventions and not laws; the two opposite conventions for the direction of fixes; feature flags; merge queues and stacked changes; what the DORA research does and does not show.
- **Labs:** simulate a company repository through one release and one hotfix under two different strategies and compare the histories.
- **Primary sources:** [gitworkflows](https://git-scm.com/docs/gitworkflows), [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow), [A successful Git branching model, with the 2020 note](https://nvie.com/posts/a-successful-git-branching-model/), [trunkbaseddevelopment.com](https://trunkbaseddevelopment.com/), [Patterns for Managing Source Code Branches](https://martinfowler.com/articles/branching-patterns.html), [DORA on trunk-based development](https://dora.dev/capabilities/trunk-based-development/).
- **Video (optional):** [TechWorld with Nana, "3 Git Workflows"](https://www.youtube.com/watch?v=GQQqf-C2ha4), paired with [Dave Farley's argued case for trunk](https://www.youtube.com/watch?v=v4Ijkq6Myfc), which is deliberate advocacy.
- **Covers:** §47. Ch. 27.

#### Module 33: AI/ML engineering workflows

- **You will be able to:** structure an AI or ML repository so that experiments are reproducible, large files stay out of Git, and notebooks and secrets do not leak.
- **Topics:** what belongs in Git and what does not; notebooks as JSON with outputs: nbstripout, nbdime, jupytext; data and model versioning: Git LFS, DVC, the Hugging Face Hub, model registries; reproducibility: commit ID plus dirty state, lock files, container digests, resolved configuration, data and model versions; `.gitignore` and `.gitattributes` for ML; pre-commit hooks backed by CI; CI for Python projects; LLM evaluations in CI and why they collide with the fork model; self-hosted GPU runners; model-serving repositories and Docker; Java and backend notes; AI coding agents as participants.
- **Labs:** build a professional AI project repository from an empty folder; version a dataset by reference; prove a past result can be reproduced from its recorded identifiers.
- **Primary sources:** [nbstripout](https://github.com/kynan/nbstripout/blob/main/README.md), [nbdime](https://nbdime.readthedocs.io/en/latest/), [jupytext](https://github.com/jupytext/jupytext/blob/main/README.md), [DVC documentation](https://doc.dvc.org/start), [pre-commit](https://pre-commit.com/), [uv with GitHub Actions](https://docs.astral.sh/uv/guides/integration/github/), [Cookiecutter Data Science](https://github.com/drivendataorg/cookiecutter-data-science/blob/master/README.md).
- **Video (optional):** in Hindi, [Vikash Das on data versioning with DVC](https://www.youtube.com/watch?v=PPrPuxqWc7E); [CampusX's MLOps walkthrough](https://www.youtube.com/watch?v=eCjuoqUy8Is) as a concept map only.
- **Covers:** §38, §48, §49, §70. Ch. 22, 28.

#### Module 34: Practices, anti-patterns, and open-source etiquette

- **You will be able to:** give the reason behind every practice you follow and the root cause behind every anti-pattern you reject.
- **Topics:** small commits, meaningful messages, protected main branch, review, required checks, no secrets in Git, safe force-pushing, signed commits, branch naming, rebasing private branches only; the anti-patterns you listed, each with its root cause; code review as a practice; contributing to open source: reading CONTRIBUTING, issue first, small pull requests, maintainers' time; your professional configuration, revisited and finalized.
- **Primary sources:** [How to Write a Git Commit Message](https://cbea.ms/git-commit/), [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).
- **Video (optional):** [Derek Prior, "Implementing a Strong Code-Review Culture"](https://www.youtube.com/watch?v=PJjmw9TRB7s).
- **Assessment:** a design review. You design the branching model, governance, CI and security policy for a described company and defend it against my objections.
- **Covers:** §57, §58, §59. Ch. 27, 29.

### LEVEL 9: Production debugging and incident response

#### Module 35: The diagnosis method

- **You will be able to:** take any Git or GitHub symptom and produce evidence, hypotheses and a lowest-risk fix without running a single state-changing command first.
- **Topics:** the root-cause framework applied end to end; the ten-command diagnosis; local evidence: status, refs, reflogs, the object store; GitHub-side evidence: the Activity view, pull request timelines, the Events API, rule insights, the audit log; choosing the lowest-risk fix; preserving evidence before acting, for example with a backup ref; verification; the reusable troubleshooting checklist.
- **Primary sources:** [Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository), plus the man pages from Levels 1 to 4.
- **Produces:** the troubleshooting playbook.
- **Covers:** §45, §46, §54, §65. Ch. 29.

#### Module 36: Incident drills, local and history

- **Incidents:** 1 an accidental `git reset --hard`; 8 a branch that appears to have disappeared; 10 a commit that exists locally but not remotely; 9 a misunderstood merge conflict; 5 a developer who rebased a shared branch.
- **Format for each:** symptoms, evidence, hypotheses, diagnostic commands, root cause, safe recovery, verification, prevention, communication to the team and the CTO, postmortem.
- **Covers:** §44. Ch. 29, 30.

#### Module 37: Incident drills, remote, platform, CI, and security

- **Incidents:** 2 a force push to the wrong branch; 4 a rewritten production branch; 6 a pull request that suddenly shows 500 unrelated changes; 7 CI that passes locally and fails on GitHub Actions; 3 a committed secret.
- **Format:** as in Module 36.
- **Covers:** §44. Ch. 29, 30.

#### Module 38: Communication, postmortems, and the senior standard

- **You will be able to:** handle the three scenarios you named as the final standard: a branch that was rebased and force-pushed with a broken pull request, a committed secret, and GitHub Actions that suddenly fails.
- **Topics:** writing the incident summary a CTO needs; blameless postmortems; turning a root cause into a control; the eleven-step recovery of the rebased and force-pushed pull request, from inspecting state to preventing recurrence.
- **Produces:** final versions of the disaster-recovery playbook and the emergency cheat sheet.
- **Covers:** §75. Ch. 30.

**GATE: Production debugging, 90%.**

### LEVEL 10: Senior engineer — assessment

#### Module 39: The CTO interview series

- Strict oral interviews across all domains, one question at a time, with harder follow-ups on weak answers. The question bank grows from the first module and reaches several hundred questions here.
- **Covers:** §52, §53. Ch. 31.

#### Module 40: The final knowledge test

- Eighteen sections: fundamentals, internals, branching, merge, rebase, undo, recovery, remote workflows, GitHub, pull requests, Actions, security, open source, AI/ML workflows, production incidents, debugging, architecture, CTO interview.
- Item types: multiple choice, command prediction, debugging, diagrams, output interpretation, practical labs, incident response, oral questions. The answer key is a separate document that you receive after you submit.
- **Covers:** §68. Ch. 31.

#### Module 41: The capstone production simulation

- A fictional company repository with a main branch, several developers, feature branches, pull requests, CI, CODEOWNERS, protection rules and release tags. Incidents arrive one at a time: a bug, a merge conflict, a leaked secret, failed CI, an accidental reset, a deleted branch, a rebase problem, a production hotfix.
- You are evaluated on Git knowledge, GitHub knowledge, debugging ability, production judgment, security awareness, recovery skills and engineering communication.
- **Covers:** §69. Ch. 32.

### LEVEL 11: Expert — the frontier

#### Module 42: Where Git is going, and reading primary sources unaided

- **You will be able to:** follow a Git release from its notes and decide what it changes for your team.
- **Topics:** the path to Git 3.0 through 2.98 and 2.99; SHA-256 repositories and hosting support; reftable as a default; Rust in Git; the experimental `git history` and `git replay`, with `git history drop` as a Git 2.56 addition; stacked workflows; Git-compatible tools worth knowing by name; how to read release notes, the BreakingChanges document and the GitHub Changelog; contributing upstream.
- **Primary sources:** [BreakingChanges](https://git-scm.com/docs/BreakingChanges), [hash-function-transition](https://git-scm.com/docs/hash-function-transition), [the release notes directory](https://github.com/git/git/tree/master/Documentation/RelNotes), [the GitHub Changelog](https://github.blog/changelog/).
- **Video (optional):** [Patrick Steinhardt on the reftable backend](https://www.youtube.com/watch?v=TqHYOGCJkS8); [Emily Shaffer, "SHA-256 at a Hyperscaler"](https://www.youtube.com/watch?v=eJJp0RE7cd4); [Edward Thomson, "You Don't Know Git"](https://www.youtube.com/watch?v=DZI0Zl-1JqQ).
- **Covers:** §66. Ch. 14, 35.

---

## 8. Coverage map: your brief to the modules

Every content section of your master prompt has a home. Sections that describe method rather than content are listed at the end.

| Your section | Topic | Modules |
|---|---|---|
| §6 | Git internals and the object model | 1, 16, 17 |
| §7 | The index and staging area | 2, 17 |
| §8 | Commits | 3 |
| §9 | Branches | 4, 6, 7 |
| §10 | Merge | 6 |
| §11 | Rebase | 9 |
| §12 | Reset, revert, restore | 8 |
| §13 | Cherry-pick | 10 |
| §14 | Fetch, pull, push | 7 |
| §15 | Remotes | 7 |
| §16 | Recovery and disaster recovery | 12 |
| §17 | Detached HEAD | 4, 12 |
| §18 | Diff and range notation | 2, 10 |
| §19 | Log | 3, 11 |
| §20 | Blame | 11 |
| §21 | Bisect | 11 |
| §22 | Tags and releases | 4, 13, 22 |
| §23 | Configuration | 5 |
| §24 | Aliases | 5 |
| §25 | Hooks | 14 |
| §26 | Signing | 24 |
| §27 | GitHub from zero to advanced | 19 |
| §28 | GitHub authentication | 20 |
| §29 | SSH | 20 |
| §30 | Fork workflow | 21 |
| §31 | Pull requests | 21 |
| §32 | GitHub merge strategies | 22 |
| §33 | Branch protection and rulesets | 23 |
| §34 | CODEOWNERS | 23 |
| §35 | GitHub Actions, complete course | 26, 27, 28 |
| §36 | GitHub Actions security | 29 |
| §37 | GitHub CLI | 25, and used from Module 19 on |
| §38 | Git LFS | 15, 33 |
| §39 | Submodules and subtrees | 15 |
| §40 | Monorepos | 18, with CODEOWNERS in 23 and CI in 28 |
| §41 | Worktrees | 14 |
| §42 | Performance | 16, 18 |
| §43 | Git security | 30, 31 |
| §44 | Real production incidents 1 to 10 | 36, 37 |
| §45 | Root-cause analysis framework | 0, 35 |
| §46 | Git state diagnostics | 0, 35 |
| §47 | Real software-engineering workflow | 32 |
| §48 | AI/ML engineering workflow | 33 |
| §49 | Repository structure | 19, 33 |
| §50 | Practical lab environment | 0, and every module |
| §52, §53 | CTO questions and interview mode | Every module, then 39 |
| §54 | Debugging mode | Levels 3 and 9 |
| §55 | Command safety | 0, and at every dangerous command |
| §56 | Command cheat sheet | Built per module; final in Phase 4 |
| §57 | Professional configuration | 5, finalized in 34 |
| §58, §59 | Best practices and anti-patterns | 34 |
| §60 | Video research | Phase 0 report, sections 7 to 10 |
| §61, §73, §74 | Video curriculum and scripts | Phase 5 |
| §68 | Final knowledge test | 40 |
| §69 | Capstone | 41 |
| §70 | Personalized software-engineer track | 33, and examples throughout |
| §71, §72 | Textbook | Phase 4, assembled from module chapters |
| §75 | The senior-engineer standard | 28, 31, 38 |

Method sections applied throughout: §2 to §5 on research, currency, the no-hallucination policy and the teaching lens; §51 exercise levels; §62 to §67 on style, diagrams, root-cause explanations, version awareness and sources; §76 to §79 on pace, interactivity and mastery gates.

---

## 9. Deliverables schedule

| # | Deliverable | Built from | First version | Final |
|---|---|---|---|---|
| 1 | Complete Git and GitHub textbook, 35 chapters | One chapter per passed module | After Module 1 | Phase 4 |
| 2 | Practical lab manual | Each lab, written up after you complete it | After Module 0 | Phase 4 |
| 3 | Git command reference | Cheat-sheet rows per module: command, purpose, example, risk, common mistake, recovery | After Level 1 | After Level 4 |
| 4 | GitHub command and reference guide | Levels 5 and 6 | After Module 25 | Phase 4 |
| 5 | Git troubleshooting playbook | Module 35 and the incident drills | After Module 35 | After Level 9 |
| 6 | Git disaster-recovery playbook | Module 12 and the incident drills | After Module 12 | After Module 38 |
| 7 | GitHub Actions guide, with the twelve workflows | Level 6 and Module 29 | After Module 28 | After Level 7 |
| 8 | Git and GitHub security guide | Level 7 | After Module 31 | Phase 4 |
| 9 | Senior software engineer interview guide | Module interviews and Module 39 | After Level 2 | After Module 39 |
| 10 | CTO-level interview question bank | Grows every module to several hundred questions | After Module 1 | After Module 39 |
| 11 | Complete capstone project | Module 41 | Module 41 | Module 41 |
| 12 | Video course curriculum | The finalized written course | Phase 5 | Phase 5 |
| 13 | Video scripts, one per video in the thirteen-part format you specified | The finalized written course | Phase 5 | Phase 5 |
| 14 | Revision checklist | One page per gate | After the first gate | Phase 4 |
| 15 | One-page emergency Git recovery cheat sheet | Module 12 | After Module 12 | After Module 38 |

The final textbook can be exported as a PDF in Phase 4.

---

## 10. Re-verification calendar

Facts in the Phase 0 report expire on known dates. I re-check each one before the module that depends on it.

| When | What changes | Layer | Affects |
|---|---|---|---|
| 14 Oct 2026 | Newly uploaded RSA SSH keys must be at least 3072 bits | GitHub | Module 20 |
| 19 Oct to 19 Nov 2026 | `ubuntu-latest` migrates from Ubuntu 24.04 to 26.04 | Actions | Modules 26 to 28 |
| 28 and 29 Oct 2026 | GitHub Universe 2026 | GitHub | Levels 5 to 7 |
| 2 Nov 2026 | Default rule blocks `pull_request_target` in public repositories without their own policy; `macos-14` images retired | Actions | Module 29 |
| 4 Nov and 9 Dec 2026 | Brownouts for SHA-1 `ssh-rsa` signatures | GitHub | Module 20 |
| Near the end of 2026 | Git 2.98; the month comes only from secondary sources | Git | Modules 17, 42 |
| 13 Jan 2027 | SHA-1 `ssh-rsa` signatures removed | GitHub | Module 20 |
| 17 Apr 2027 | `ubuntu-22.04` images retired | Actions | Module 28 |
| Spring 2027, secondary sources only | Git 2.99 and 3.0 | Git | Modules 17, 42 |

Open items from the report that I re-check before the textbook states them: GitHub's SHA-256 repository support, the retention of unreachable commits on GitHub, and the dates of the Git 3.0 transition. The core video picks were assessed from captions and chapter lists, not full viewing, so treat the first minutes of each as a check of your own.

---

## 11. Pacing

| If you study | The program takes roughly |
|---|---|
| 5 hours a week | 7 to 9 months |
| 10 hours a week | 4 to 5 months |
| 15 hours a week | 10 to 13 weeks |

These follow from the 150 to 200 hour estimate. Gates, not the calendar, decide when you advance. A module is a unit of understanding, not a session. A long module such as merge, rebase or recovery usually takes several sittings.

---

## 12. Progress and weak-area tracker

Updated after every module and gate.

| Gate | Threshold | Score | Date | Status |
|---|---|---|---|---|
| Fundamentals | 85% | | | Not started |
| Branching | 90% | | | Not started |
| Merge and rebase | 90% | | | Not started |
| Recovery | 90% | | | Not started |
| Internals | 85% | | | Not started |
| GitHub | 85% | | | Not started |
| Actions | 85% | | | Not started |
| Security | 90% | | | Not started |
| Production debugging | 90% | | | Not started |

| Weak area | First seen in | Evidence | Revisit in | Resolved |
|---|---|---|---|---|
| None recorded yet | | | | |

---

## 13. How to begin

Say **"Start Module 0"** to set up the lab first, which I recommend, or **"Start Module 1"** to go straight to the data model. Module 0 takes about an hour and makes every later lab safe to break.
