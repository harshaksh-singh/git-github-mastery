# Script batches

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. The entries are in [video-curriculum.md](video-curriculum.md).

The 201 videos (4478 planned minutes) are split into six batches for six script writers. Each batch is a run of contiguous video numbers, and the cuts were placed so that the largest batch is as small as possible in planned minutes. A writer therefore owns a continuous stretch of the course and can keep its running examples consistent.

## Rules for every batch

1. Read sections 1 and 2 of the curriculum and the whole [authoring style guide](../authoring/STYLE_GUIDE.md) first. Both are binding.
2. Read the listed chapters in full, not only the cited sections: a script has to know what the neighbouring sections say in order not to contradict them.
3. Run `labs/verify-all.sh <dir>` for every demo directory of the batch before quoting a transcript, and quote transcript lines only from `labs/<dir>/out/<name>/`.
4. A script shows no command that the named demo scripts do not contain, and states no fact that the cited sections do not state. GitHub-side segments are screen walkthroughs of the learner's own practice repository; no GitHub output was captured by the authors.
5. The first video of a batch may rely on videos of an earlier batch. The prerequisites of each entry say which; read those entries too.
6. Hand back, with the scripts: the planned and the scripted minutes per video, every place where an entry could not be followed and why, and every statement that could not be confirmed in the cited sections.

## Summary

| Batch | Videos | Count | Minutes | Share of total | Parts |
|---|---|---|---|---|---|
| 1 | V001 to V033 | 33 | 730 | 16.3% | 0, 1, 2 |
| 2 | V034 to V066 | 33 | 754 | 16.8% | 2, 3 |
| 3 | V067 to V099 | 33 | 746 | 16.7% | 3, 4 |
| 4 | V100 to V133 | 34 | 752 | 16.8% | 4, 5 |
| 5 | V134 to V166 | 33 | 746 | 16.7% | 5, 6, 7 |
| 6 | V167 to V201 | 35 | 750 | 16.7% | 7, 8, 9, 10, 11 |

## Batch 1: V001 to V033

33 videos, 730 minutes. Modules 0, 1, 2, 3, 4, 5, 6.

**Textbook chapters to read in full before writing:**

- [Chapter 1: Fundamentals](../textbook/ch01-fundamentals.md)
- [Chapter 2: The Mental Model](../textbook/ch02-mental-model.md)
- [Chapter 4: The Working Tree](../textbook/ch04-working-tree.md)
- [Chapter 5: The Index](../textbook/ch05-index.md)
- [Chapter 6: Commits](../textbook/ch06-commits.md)
- [Chapter 7: Branches](../textbook/ch07-branches.md)
- [Chapter 8: Merge](../textbook/ch08-merge.md)
- [Chapter 14B: Configuration, Aliases, Tags and Signing](../textbook/ch14b-config-tags-signing.md)

**Demo directories used:** `labs/ch00/`, `labs/ch01/`, `labs/ch02/`, `labs/ch04/`, `labs/ch05/`, `labs/ch06/`, `labs/ch07/`, `labs/ch08/`, `labs/ch14b/`, `labs/ref/`

| No. | Title | Module | Min |
|---|---|---|---|
| V001 | How this course works: the book, the lab sandbox and the fixed clock | 0 | 16 |
| V002 | What version control solves, and Git the tool versus GitHub the platform | 0, 1 | 18 |
| V003 | A first repository, read file by file | 0 | 22 |
| V004 | The root-cause framework | 0 | 16 |
| V005 | The ten-command diagnosis | 0 | 22 |
| V006 | Worked example: the fix that was committed and did not ship | 0 | 20 |
| V007 | Snapshots, not diffs, and content addressing | 1 | 24 |
| V008 | The four object types, and a commit built by hand | 1 | 26 |
| V009 | The commit graph, reachability, refs and HEAD | 1 | 24 |
| V010 | Three trees, two views of a commit, and the wrong mental models | 1 | 20 |
| V011 | The working tree, three categories of file, and the anatomy of git status | 2 | 22 |
| V012 | Ignore rules and the already-tracked trap | 2 | 24 |
| V013 | git restore, git mv, git rm, and why Git records no renames | 2 | 22 |
| V014 | File modes, empty directories, the case-insensitive filesystem, line endings, and git clean | 2 | 26 |
| V015 | The index: the proposed next commit, and what git add writes | 2 | 22 |
| V016 | Three diffs, partial staging with git add -p, and intent to add | 2 | 26 |
| V017 | Staging deletions and renames, the scope of git add, and unstaging three ways | 2 | 26 |
| V018 | Reading the index: git ls-files, the two bits that are not an ignore mechanism, the stat cache, and the lock | 2 | 24 |
| V019 | What a commit is, how git commit creates it, and the commit ID | 3 | 24 |
| V020 | Author and committer, two dates, and parents | 3 | 22 |
| V021 | Amend, empty commits, trailers, messages and atomic commits | 3 | 26 |
| V022 | A branch is a ref, HEAD is a symbolic ref, and what a commit does to the current branch | 4 | 22 |
| V023 | git branch and git switch | 4 | 22 |
| V024 | Detached HEAD | 4 | 20 |
| V025 | Divergence, ancestry, and why Git has no parent-branch concept | 4 | 22 |
| V026 | Lightweight tags, branch names, and stale branches | 4 | 22 |
| V027 | Configuration: scopes, precedence, and reading and writing settings | 5 | 22 |
| V028 | Conditional includes, the settings to decide deliberately, aliases, and environment variables for diagnosis | 5 | 26 |
| V029 | Gate briefing: Fundamentals | 5 | 10 |
| V030 | Divergence, the merge base, and fast-forward | 6 | 20 |
| V031 | The true merge: three inputs, one rule table, and criss-cross histories | 6 | 24 |
| V032 | Strategies, strategy options, and exactly why conflicts occur | 6 | 22 |
| V033 | Anatomy of a conflict: working tree, index and .git, and the conflict styles | 6 | 26 |

## Batch 2: V034 to V066

33 videos, 754 minutes. Modules 6, 7, 8, 9, 10, 11.

**Textbook chapters to read in full before writing:**

- [Chapter 7: Branches](../textbook/ch07-branches.md)
- [Chapter 8: Merge](../textbook/ch08-merge.md)
- [Chapter 9: Rebase](../textbook/ch09-rebase.md)
- [Chapter 10: Cherry-pick](../textbook/ch10-cherry-pick.md)
- [Chapter 11: Reset, Revert, Restore](../textbook/ch11-reset-revert-restore.md)
- [Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md)
- [Chapter 14A: History investigation](../textbook/ch14a-history-investigation.md)

**Demo directories used:** `labs/ch08/`, `labs/ch09/`, `labs/ch10/`, `labs/ch11/`, `labs/ch12/`, `labs/ch14a/`

| No. | Title | Module | Min |
|---|---|---|---|
| V034 | The resolution workflow: abort, continue, quit, and restoring one side | 6 | 24 |
| V035 | Conflict types beyond content: renames, modify/delete, add/add, binary, directories | 6 | 26 |
| V036 | Controlling the result: --ff-only, --no-ff, --squash, the merge commit, first-parent history and octopus merges | 6 | 24 |
| V037 | Clean for Git, wrong for humans: auditing a merge, and git merge-tree | 6 | 26 |
| V038 | What a remote is, and git clone step by step | 7 | 24 |
| V039 | git fetch: which refs move | 7 | 20 |
| V040 | Upstream branches, push.default, and git pull as fetch plus one integration step | 7 | 26 |
| V041 | git push: asking another repository to move its refs | 7 | 28 |
| V042 | Forcing a push: what it destroys, the lease, and --force-if-includes | 7 | 24 |
| V043 | More than one remote, pruning, and branches whose upstream is gone | 7 | 24 |
| V044 | Refspecs in depth, transports, and two diagnoses from first principles | 7 | 26 |
| V045 | Gate briefing: Branching | 7 | 10 |
| V046 | The undo map and git restore | 8 | 20 |
| V047 | git reset: the three modes, why --hard is dangerous, and the resets that check first | 8 | 28 |
| V048 | git revert: a new commit that applies the inverse change | 8 | 20 |
| V049 | Reverting a merge, and the re-merge problem | 8 | 22 |
| V050 | git clean, and stash: uncommitted work parked as commits | 8 | 24 |
| V051 | One table, one decision tree, and seven worked undo scenarios | 8 | 18 |
| V052 | What a rebase is, and why every rebased commit has a new ID | 9 | 18 |
| V053 | What rebase does internally: the state directory, HEAD, and the special refs | 9 | 20 |
| V054 | Choosing what moves and where it lands: upstream, --onto, --keep-base, --root | 9 | 24 |
| V055 | Interactive rebase: reword, edit, squash, fixup, drop, reorder, exec, break | 9 | 28 |
| V056 | Fixup commits, --autosquash, --autostash, stacked branches with --update-refs, and --rebase-merges | 9 | 28 |
| V057 | Conflicts during a rebase: who is "ours", the ways out, and commits that are already upstream | 9 | 26 |
| V058 | git pull --rebase, and reviewing a rebase with git range-diff | 9 | 20 |
| V059 | Rebasing a branch that other people use, and recovering from a bad rebase | 9 | 24 |
| V060 | Publishing a rebased branch, rebase or merge, and the rebase configuration | 9 | 26 |
| V061 | What cherry-pick does: a three-way merge that makes a new commit | 10 | 24 |
| V062 | CHERRY_PICK_HEAD, the sequencer, conflicts, and picks that are already there | 10 | 24 |
| V063 | The backport workflow, duplicate commits, and revert as the inverse | 10 | 22 |
| V064 | Naming commits and sets of commits: revisions, A..B and A...B for git log and for git diff | 10 | 24 |
| V065 | Gate briefing: Merge and rebase | 10 | 10 |
| V066 | Reading a diff: summaries, filters, computed renames, whitespace and algorithms | 11 | 22 |

## Batch 3: V067 to V099

33 videos, 746 minutes. Modules 11, 12, 13, 14, 15, 16, 17, 33.

**Textbook chapters to read in full before writing:**

- [Chapter 3: Git Internals](../textbook/ch03-git-internals.md)
- [Chapter 13: Recovery](../textbook/ch13-recovery.md)
- [Chapter 14A: History investigation](../textbook/ch14a-history-investigation.md)
- [Chapter 14B: Configuration, Aliases, Tags and Signing](../textbook/ch14b-config-tags-signing.md)
- [Chapter 14C: Stash Internals, Rerere, Attributes, Hooks](../textbook/ch14c-stash-rerere-attributes-hooks.md)
- [Chapter 22: Git LFS](../textbook/ch22-git-lfs.md)
- [Chapter 23: Submodules and Subtrees](../textbook/ch23-submodules.md)
- [Chapter 25: Worktrees](../textbook/ch25-worktrees.md)

**Demo directories used:** `labs/ch03/`, `labs/ch13/`, `labs/ch14a/`, `labs/ch14b/`, `labs/ch14c/`, `labs/ch22/`, `labs/ch23/`, `labs/ch25/`

| No. | Title | Module | Min |
|---|---|---|---|
| V067 | git log is a graph query: selection, filters, graph shape and output formats | 11 | 24 |
| V068 | Set questions, git grep, and the retirement of git whatchanged | 11 | 20 |
| V069 | The history of one file: --follow, the pickaxe, line history, and deleted files | 11 | 28 |
| V070 | git blame: what a row asserts, reformatting commits, moved code, and a method for finding the origin of a bug | 11 | 26 |
| V071 | git bisect: binary search over commits | 11 | 20 |
| V072 | git bisect run, the exit-code protocol, custom terms, replay, --first-parent, and the pitfalls | 11 | 22 |
| V073 | What Git keeps: four layers of protection, and the reflog | 12 | 22 |
| V074 | Retention and its exceptions, ORIG_HEAD, and git fsck as a search tool | 12 | 26 |
| V075 | The recovery method, and recovering commits I: a hard reset, a deleted branch, a deleted commit | 12 | 26 |
| V076 | Recovering commits II: a wrong rebase, a bad merge, the wrong branch, detached HEAD, a wrong cherry-pick | 12 | 28 |
| V077 | Recovering uncommitted work, and recovering from the remote side | 12 | 24 |
| V078 | A damaged repository, and what cannot be recovered | 12 | 20 |
| V079 | The point of no return, prevention with backup refs and bundles, and what GitHub adds | 12 | 22 |
| V080 | Tags: three kinds, two mechanisms, listing, and how tags travel | 13 | 22 |
| V081 | Why a published tag must not move | 13 | 18 |
| V082 | git describe, Semantic Versioning, and release branches on the Git side | 13 | 22 |
| V083 | Linked worktrees: what they are, what is shared, and one branch per worktree | 14 | 20 |
| V084 | Worktrees in use: the hotfix during a rebase, reviewing a branch, the life cycle, and the pitfalls | 14 | 24 |
| V085 | Stash internals: a stash entry is a small commit graph | 14 | 16 |
| V086 | Rerere: resolve a conflict once | 14 | 24 |
| V087 | .gitattributes: per-path settings that travel, and line endings | 14 | 20 |
| V088 | Diff drivers, merge drivers, and clean and smudge filters | 14 | 26 |
| V089 | Hooks: programs that Git runs at fixed points | 14 | 24 |
| V090 | --no-verify, core.hooksPath, sharing hooks, hook security, and why hooks cannot enforce policy | 14 | 22 |
| V091 | Submodules: a gitlink, .gitmodules, and what a teammate receives | 15 | 24 |
| V092 | Submodules in motion: the detached HEAD, moving the pointer, the stale submodule and the silent rollback | 15 | 24 |
| V093 | Submodule failures: push order, dirty submodules, pointer conflicts, removal, URL changes, and CI | 15 | 28 |
| V094 | Subtrees, and choosing between a submodule, a subtree and a package manager | 15 | 20 |
| V095 | Git LFS: why it exists, the pointer file, the two filters, and tracking | 15 | 22 |
| V096 | Git LFS day to day: status, pushing, cloning without the client, and the local store | 15 | 24 |
| V097 | git lfs migrate, the common LFS errors, GitHub's limits and billing, and when LFS is the wrong tool | 15, 33 | 26 |
| V098 | Gate briefing: Recovery | 15 | 10 |
| V099 | The .git directory file by file, and the loose object format | 16, 17 | 22 |

## Batch 4: V100 to V133

34 videos, 752 minutes. Modules 16, 17, 18, 19, 20, 21, 22, 23, 34, 42.

**Textbook chapters to read in full before writing:**

- [Chapter 3: Git Internals](../textbook/ch03-git-internals.md)
- [Chapter 15: GitHub](../textbook/ch15-github.md)
- [Chapter 16: Authentication](../textbook/ch16-authentication.md)
- [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md)
- [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md)
- [Chapter 24: Monorepos](../textbook/ch24-monorepos.md)
- [Chapter 26: Performance](../textbook/ch26-performance.md)

**Demo directories used:** `labs/ch03/`, `labs/ch15/`, `labs/ch16/`, `labs/ch17/`, `labs/ch18/`, `labs/ch24/`, `labs/ch26/`

| No. | Title | Module | Min |
|---|---|---|---|
| V100 | The four object types in full, and reading objects with cat-file, ls-tree and show | 16 | 22 |
| V101 | Turning names into IDs: git rev-parse | 17 | 14 |
| V102 | Packfiles, pack indexes and delta compression | 16 | 24 |
| V103 | Reachability, git fsck, and where Git checks its hashes | 16 | 22 |
| V104 | What makes a repository slow, git gc versus git maintenance, geometric repacking, and cruft packs | 16 | 26 |
| V105 | Refs in depth: loose refs, packed-refs, symbolic refs, root refs, and reflog storage | 17 | 24 |
| V106 | The index file as a data structure | 17 | 20 |
| V107 | The reftable backend, and SHA-1 with collision detection versus SHA-256 | 17, 42 | 22 |
| V108 | The commit-graph, the multi-pack-index, reachability bitmaps, and the working-tree accelerators | 18 | 22 |
| V109 | The fetch conversation, shallow clones, partial clones, and choosing a clone | 18 | 28 |
| V110 | Bundles, and when each scale feature matters | 18 | 16 |
| V111 | Monorepo versus polyrepo, and sparse-checkout in cone mode | 18 | 20 |
| V112 | Living in a sparse checkout, and the sparse index | 18 | 20 |
| V113 | Partial clone plus sparse-checkout, what scalar clone configures, and ownership, CI and releases in a monorepo | 18 | 24 |
| V114 | Gate briefing: Internals | 18 | 10 |
| V115 | Git data and GitHub objects, accounts, roles, and the settings that matter | 19 | 24 |
| V116 | Forks and the fork network | 19 | 20 |
| V117 | Issues, Projects, Discussions, Packages, templates, health files, a professional layout, and limits | 19 | 26 |
| V118 | Authentication versus authorization, HTTPS, and how Git asks for a credential | 20 | 24 |
| V119 | Tokens: fine-grained, classic, what a prefix tells you, and why a token never goes into a URL | 20 | 16 |
| V120 | SSH: key pairs, the agent, ~/.ssh/config, host keys, and testing the connection | 20 | 26 |
| V121 | Two identities on one machine, credentials for machines, single sign-on, and the SSH changes of 14 October 2026 and 13 January 2027 | 20 | 20 |
| V122 | Diagnosing authentication failures: who wrote this line, the SSH failures, the HTTPS failures, and a decision tree | 20 | 24 |
| V123 | What GitHub creates when a pull request opens, and what a pull request shows | 21 | 26 |
| V124 | The pull request lifecycle: draft, review, stale approvals, checks, mergeability, and conflicts | 21 | 24 |
| V125 | Why a pull request shows unexpected commits or a huge diff | 21 | 26 |
| V126 | Indirect merges and stacked pull requests | 21 | 20 |
| V127 | The fork workflow end to end, review practice, and display limits | 21, 34 | 22 |
| V128 | The three merge methods: merge commit, squash and merge, rebase and merge | 22 | 24 |
| V129 | What the merge method means later: bisect, blame, revert and traceability; auto-merge; the merge queue | 22 | 24 |
| V130 | A Git tag versus a GitHub Release | 22 | 18 |
| V131 | What a rule is, rulesets, layering, and bypass | 23 | 26 |
| V132 | The rules and their sub-options: required reviews, status checks and their traps, conversations, signatures, linear history | 23 | 28 |
| V133 | Tag rulesets, push rulesets, organization-level rulesets, classic branch protection, and plan gates | 23 | 20 |

## Batch 5: V134 to V166

33 videos, 746 minutes. Modules 23, 24, 25, 26, 27, 28, 29, 30, 31.

**Textbook chapters to read in full before writing:**

- [Chapter 6: Commits](../textbook/ch06-commits.md)
- [Chapter 14B: Configuration, Aliases, Tags and Signing](../textbook/ch14b-config-tags-signing.md)
- [Chapter 15: GitHub](../textbook/ch15-github.md)
- [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md)
- [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md)
- [Chapter 19: CODEOWNERS](../textbook/ch19-codeowners.md)
- [Chapter 20A: GitHub Actions Fundamentals](../textbook/ch20a-actions-fundamentals.md)
- [Chapter 20B: GitHub Actions: delivery, runners, cost and debugging](../textbook/ch20b-actions-delivery-debugging.md)
- [Chapter 21A: GitHub Actions security](../textbook/ch21a-actions-security.md)
- [Chapter 21B: Repository security, identity, the Git client, and secret-leak response](../textbook/ch21b-repository-security-incident-response.md)

**Demo directories used:** `labs/ch06/`, `labs/ch14b/`, `labs/ch15/`, `labs/ch17/`, `labs/ch18/`, `labs/ch20a/`, `labs/ch20b/`, `labs/ch21a/`, `labs/ch21b/`

| No. | Title | Module | Min |
|---|---|---|---|
| V134 | Seeing and managing rules, "why can't I merge?", and a worked design for a production branch | 23 | 24 |
| V135 | CODEOWNERS: what it is, where it lives, syntax, and last match wins | 23 | 22 |
| V136 | CODEOWNERS in force: the base branch decides, protecting the file, monorepos, required reviewers, and finding out what GitHub thinks | 23 | 22 |
| V137 | Signatures: what is signed, by which program, and SSH signing end to end | 24 | 22 |
| V138 | What a signature covers, what verification proves, and author spoofing | 24, 30 | 24 |
| V139 | Signatures on GitHub: the verification states and what "Verified" does not prove | 24 | 18 |
| V140 | The GitHub CLI, gh pr, gh api, the REST API and GraphQL, rate limits, webhooks and GitHub Apps | 25 | 26 |
| V141 | Gate briefing: GitHub | 25 | 10 |
| V142 | The Actions model, and YAML read carefully | 26 | 22 |
| V143 | Events and filters, contexts and expressions, and env, vars and secrets | 26 | 24 |
| V144 | Shells, and passing data between steps and jobs | 26 | 18 |
| V145 | What actions/checkout does by default: one commit, no tags, and the merge ref | 26 | 24 |
| V146 | Controlling jobs, matrix strategies, dependency caching, and artifacts | 26 | 26 |
| V147 | Workflows 1 to 5, line by line: tests, lint, build, Python with uv, Java with Maven | 26 | 28 |
| V148 | Workflows 6, 7 and 10, action versions and the Node 24 runtime, and the syntax added in 2025 and 2026 | 26, 27 | 24 |
| V149 | Environments, deploying to staging, and promotion to production behind an approval | 27 | 28 |
| V150 | Concurrency groups, reusable workflows, composite actions and container actions | 27 | 24 |
| V151 | Publishing a container image, and release automation in outline | 27 | 16 |
| V152 | Runners, limits and billing, and the investigation order for a failing workflow | 28 | 26 |
| V153 | "Passes locally, fails on GitHub Actions": the documented causes | 28 | 24 |
| V154 | Required checks that stay pending, the debugging instruments, linting, and what a local emulator cannot reproduce | 28 | 24 |
| V155 | Gate briefing: Actions | 28 | 10 |
| V156 | The Actions security model in five parts, the job token, and permissions | 29 | 22 |
| V157 | Fork pull requests, the approval gate, and privileged triggers | 29 | 26 |
| V158 | Script injection through untrusted event fields | 29 | 20 |
| V159 | Third-party actions, mutable tags, commit pinning, and organization policies | 29 | 22 |
| V160 | Secrets and why masking is not a boundary, OIDC federation, caches and artifacts as untrusted input, self-hosted runners, and environment protection | 29 | 28 |
| V161 | Static analysis of workflows, the platform changes of 2025 and 2026, workflow 12, AI agents in workflows, and a review checklist | 29 | 26 |
| V162 | Case studies in Actions security: what happened, root cause, lesson | 29 | 20 |
| V163 | The Git client: what a clone runs, the three guards, and recursive clones | 30 | 22 |
| V164 | Credentials and what a stolen one can reach, and why deleting, force-pushing and going private do not remove a secret | 30 | 26 |
| V165 | Secret scanning and push protection and what they do not cover, Dependabot, code scanning, and a way to report vulnerabilities | 30 | 24 |
| V166 | Responding to a leaked secret: six steps in this order, and the case studies | 31 | 24 |

## Batch 6: V167 to V201

35 videos, 750 minutes. Modules 21, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42.

**Textbook chapters to read in full before writing:**

- [Chapter 1: Fundamentals](../textbook/ch01-fundamentals.md)
- [Chapter 9: Rebase](../textbook/ch09-rebase.md)
- [Chapter 14D: The Frontier](../textbook/ch14d-frontier.md)
- [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md)
- [Chapter 21A: GitHub Actions security](../textbook/ch21a-actions-security.md)
- [Chapter 21B: Repository security, identity, the Git client, and secret-leak response](../textbook/ch21b-repository-security-incident-response.md)
- [Chapter 27: Open source and team workflows](../textbook/ch27-open-source-team-workflows.md)
- [Chapter 28: AI/ML workflows](../textbook/ch28-ai-ml-workflows.md)
- [Chapter 29: Production Troubleshooting](../textbook/ch29-production-troubleshooting.md)
- [Chapter 30: Incident Response](../textbook/ch30-incident-response.md)

**Demo directories used:** `labs/capstone/`, `labs/ch09/`, `labs/ch14d/`, `labs/ch21b/`, `labs/ch27/`, `labs/ch28/`, `labs/ch29/`, `labs/incidents/`, `labs/ref/`

| No. | Title | Module | Min |
|---|---|---|---|
| V167 | History rewriting as an operation, and its mechanics seen locally | 31 | 28 |
| V168 | The stale clone that pushes the secret back, the GitHub side of a rewrite, and the controls that limit blast radius | 31 | 22 |
| V169 | Gate briefing: Security | 31 | 10 |
| V170 | The fork workflow in practice: syncing when upstream moves, etiquette, and the maintainer's side | 34, 21 | 24 |
| V171 | Branch names as conventions, GitHub Flow, Git Flow and its author's 2020 note, GitLab Flow, trunk-based development and release branches | 32 | 24 |
| V172 | One release and one hotfix under two strategies, and which way a fix travels | 32 | 26 |
| V173 | Feature flags, merge queues and stacked changes, what the evidence shows, and choosing by context | 32 | 20 |
| V174 | Practices with their reasons, anti-patterns with their root causes, code review, and commit message conventions | 34 | 26 |
| V175 | What belongs in Git, notebooks, and a clean filter that strips outputs | 33 | 26 |
| V176 | Data and model versioning by reference, and reproducibility: the commit alone does not identify what ran | 33 | 26 |
| V177 | .gitignore and .gitattributes for ML projects, pre-commit backed by CI, and a professional AI project repository | 33 | 24 |
| V178 | CI for ML projects, LLM evaluations and the fork model, model-serving repositories, secrets, and AI coding agents | 33 | 22 |
| V179 | Design review briefing: branching model, governance, CI and security policy for a described company | 34 | 12 |
| V180 | The diagnosis method, and worked case 1: the push that had nothing to push | 35 | 26 |
| V181 | Worked case 2: "I pulled, and the push is still rejected", and the extended toolbox | 35 | 24 |
| V182 | Operations in progress: what git status and .git tell you | 35 | 22 |
| V183 | Preserving evidence before acting, and GitHub-side evidence | 35 | 22 |
| V184 | Choosing the lowest-risk fix, verification, and the symptom catalog | 35 | 18 |
| V185 | An incident and the loop that handles one, severity, and how to run the ten incidents | 36 | 16 |
| V186 | Incident drills: an accidental hard reset, and a branch that appears to have disappeared | 36 | 24 |
| V187 | Incident drills: a commit that exists locally but not remotely, and a misunderstood merge conflict | 36 | 24 |
| V188 | A developer rebases a shared branch, and senior standard 1: the branch was rebased and force-pushed and the pull request is broken | 36, 38 | 26 |
| V189 | Incident drills: a force push to the wrong branch, and rewritten production history | 37 | 26 |
| V190 | Incident drill: a pull request that suddenly shows 500 unrelated changes | 37 | 18 |
| V191 | CI works locally but fails on GitHub Actions, and senior standard 3: GitHub Actions suddenly fails | 37, 38 | 22 |
| V192 | A secret is committed, and senior standard 2 | 37, 38 | 22 |
| V193 | The incident summary a CTO needs, blameless postmortems, and turning a root cause into a control | 38 | 22 |
| V194 | Gate briefing: Production debugging | 38 | 10 |
| V195 | The CTO interview series: the structure of a strong answer | 39 | 18 |
| V196 | The final knowledge test: briefing | 40 | 12 |
| V197 | The capstone: eight incidents at a fictional company | 41 | 16 |
| V198 | Capstone debrief: reading your own work against the evaluation | 41 | 20 |
| V199 | The road to Git 3.0, the planned defaults and removals, opting in today, and SHA-256 and reftable repositories locally | 42 | 24 |
| V200 | git history, git replay, git last-modified and git repo | 42 | 24 |
| V201 | Rust in Git, stacked workflows and Git-compatible tools, reading release notes and the GitHub Changelog, and the patch-based workflow of the Git project | 42 | 24 |
