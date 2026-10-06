# Glossary

> **Baseline.** Git 2.55.0; GitHub terms as of 1 October 2026. 293 terms, each defined in one to three sentences in the textbook's own words and checked against `git help glossary` where Git defines the term. The last column is where the term is taught.

Use it in three ways. Look a word up when a chapter, an error message or a colleague uses it. Read one letter before a mastery gate and say each definition aloud before you read it. When two definitions seem to say the same thing (a branch and a tag, an upstream and a remote-tracking branch, a release and a tag), read both: the difference is usually the lesson.

The **Layer** column says whose term it is, because GitHub is not Git:

| Layer | Meaning |
|---|---|
| Git | A term of Git itself: it means the same against any server |
| GitHub | A term of the GitHub platform, not of Git: no clone contains the thing it names |
| Actions | A term of GitHub Actions |
| LFS | A term of Git LFS, a separate program |
| Course | A term of practice or of this course's method, defined in the chapter named |

Terminology follows the textbook: commit ID or object ID (not "SHA" alone), the index (also called the staging area), working tree (not working directory), remote-tracking branch, upstream branch, HEAD in capitals.


## Symbols and notation

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| `A...B` (three dots) | Git | In `git log`: commits reachable from either side and not from both. In `git diff`: the diff from the merge base of A and B to B, which is what a pull request's "Files changed" tab shows. | [Chapter 14A, section 14A.2](../textbook/ch14a-history-investigation.md) |
| `A..B` (two dots, in `git log`) | Git | The set of commits reachable from B and not from A. In `git diff` the same spelling compares the two tips, which is a different operation. | [Chapter 14A, section 14A.8](../textbook/ch14a-history-investigation.md) |
| `--` (double dash) | Git | Separates revisions and options from paths on a command line: everything after it is a path. | [Chapter 14A, section 14A.7](../textbook/ch14a-history-investigation.md) |
| `--force-if-includes` | Git | A condition on a forced push (Git 2.30): the server's tip must be reachable from a reflog entry of your branch, that is, you integrated what you are about to overwrite. | [Chapter 12, section 12.8](../textbook/ch12-remote-operations.md) |
| `--force-with-lease` | Git | A forced push that succeeds only if the server's ref still has the expected value: by default your remote-tracking ref, or a value you name. | [Chapter 12, section 12.8](../textbook/ch12-remote-operations.md) |
| `HEAD~<n>`, `<rev>^<n>` | Git | `~<n>` follows the first parent n times; `^<n>` selects the n-th parent of a merge commit. | [Chapter 14A, section 14A.7](../textbook/ch14a-history-investigation.md) |
| `+` in a refspec | Git | Allows a non-fast-forward update of the destination ref: a forced update for that refspec. | [Chapter 12, section 12.12](../textbook/ch12-remote-operations.md) |
| `:<n>:<path>` | Git | The index entry of a path at stage n: 1 the base, 2 "ours", 3 "theirs" during a conflict; stage 0 is the normal entry. | [Chapter 5, section 5.13](../textbook/ch05-index.md) |
| `<ref>@{<n>}`, `<ref>@{<time>}` | Git | The value a ref had n changes ago, or at a time, read from its reflog. It exists only in the clone whose reflog recorded it. | [Chapter 13, section 13.3](../textbook/ch13-recovery.md) |
| `<rev>:<path>` | Git | The blob or tree at a path in the tree of a revision, for example `HEAD~1:config/limits.yaml`. | [Chapter 3, section 3.6](../textbook/ch03-git-internals.md) |
| `<rev>^{commit}`, `<rev>^{tree}` | Git | Peels a name to the object of the given type, for example from an annotated tag to its commit, or from a commit to its tree. | [Chapter 3, section 3.6](../textbook/ch03-git-internals.md) |
| `--update-refs` | Git | A rebase option (Git 2.38) that moves every local branch pointing at one of the replayed commits, not only the branch you are on. | [Chapter 9, section 9.9](../textbook/ch09-rebase.md) |
| `@{u}`, `@{upstream}` | Git | The upstream branch of the current branch; `@{push}` is where a push would go. | [Chapter 12, section 12.5](../textbook/ch12-remote-operations.md) |

## A

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| action | Actions | A packaged, reusable step that a workflow calls with `uses: owner/repo@ref`; it downloads and runs someone else's code inside your job. | [Chapter 20A, section 20A.2](../textbook/ch20a-actions-fundamentals.md) |
| `actions/checkout` | Actions | The action that fetches the repository onto the runner: by default one commit, without tags, for the ref of the event, with a detached HEAD on `pull_request` events. | [Chapter 20A, section 20A.8](../textbook/ch20a-actions-fundamentals.md) |
| Activity view | GitHub | A page of a repository that lists pushes, force pushes, merges, branch creations and deletions, with the user and a comparison. Described from the documentation. | [Chapter 13, section 13.15](../textbook/ch13-recovery.md) |
| ahead, behind | Git | Counts of commits that one branch has and the other lacks, counted from their merge base; `git status -sb` shows them for a branch and its upstream. | [Chapter 7, section 7.8](../textbook/ch07-branches.md) |
| alias | Git | A configuration value under `alias.<name>` that Git substitutes for `<name>` when it is the first word of a command line, appending any further arguments. A value that starts with `!` is a shell command. | [Chapter 14B, section 14B.6](../textbook/ch14b-config-tags-signing.md) |
| allowed-signers file | Git | The file named by `gpg.ssh.allowedSignersFile` that maps identities to SSH public keys; without it Git cannot verify SSH signatures. | [Chapter 14B, section 14B.16](../textbook/ch14b-config-tags-signing.md) |
| amend | Git | `git commit --amend` writes a new commit that takes the place of the current one: same parent, new tree and message as you choose, new ID. | [Chapter 6, section 6.7](../textbook/ch06-commits.md) |
| annotated tag | Git | A tag ref that points at a tag object, which names the tagged object and records who tagged it, when and why. `git describe` uses annotated tags by default. | [Chapter 14B, section 14B.8](../textbook/ch14b-config-tags-signing.md) |
| approval | GitHub | A review state attached to the diff as it was when the reviewer approved; settings decide whether a later push dismisses it. | [Chapter 17, section 17.5](../textbook/ch17-pull-requests.md) |
| artifact | Actions | A set of files that a job uploads to GitHub, stored with the run, downloadable by later jobs or by people, and expiring after a retention period. | [Chapter 20A, section 20A.12](../textbook/ch20a-actions-fundamentals.md) |
| assume-unchanged bit | Git | A flag on an index entry that tells Git not to examine the working tree file. It is a performance promise, not a way to keep private edits to a tracked file. | [Chapter 5, section 5.12](../textbook/ch05-index.md) |
| attribute | Git | A named property attached to paths by a `.gitattributes` file, consulted whenever Git converts, compares, merges or archives a file. | [Chapter 14C, section 14C.4](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| audit log | GitHub | An organization's record of events; the organization audit log covers 180 days. Git events such as pushes are restricted as Chapter 21B, section 21B.8 describes. | [Chapter 15, section 15.19](../textbook/ch15-github.md) |
| authentication | GitHub | Establishing which account a connection belongs to. Authorization, a separate step, decides what that account may do to this repository. | [Chapter 16, section 16.2](../textbook/ch16-authentication.md) |
| author | Git | The person who wrote the change, recorded in a commit with a name, an email address, a time and a time-zone offset. It is text supplied by whoever creates the commit. | [Chapter 6, section 6.5](../textbook/ch06-commits.md) |
| auto-merge | GitHub | A stored instruction on a pull request: merge with this method as soon as every requirement is met. | [Chapter 17, section 17.10](../textbook/ch17-pull-requests.md) |
| `AUTO_MERGE` | Git | A tree written during a conflicted merge that holds the automatic result with conflict markers; `git diff AUTO_MERGE` shows what your resolution changed. | [Chapter 8, section 8.8](../textbook/ch08-merge.md) |
| autosquash | Git | `git rebase --autosquash` reads the subjects of `fixup!`, `squash!` and `amend!` commits and arranges the todo list so that each lands on its target. | [Chapter 9, section 9.7](../textbook/ch09-rebase.md) |
| autostash | Git | `--autostash` puts uncommitted changes into a stash commit before a rebase or merge and applies it to the result; the final apply can conflict. | [Chapter 9, section 9.8](../textbook/ch09-rebase.md) |

## B

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| backport | Git | A fix that lands on the development line first and is then copied to a maintenance line with `git cherry-pick -x`, so that the copy says where it came from. | [Chapter 10, section 10.9](../textbook/ch10-cherry-pick.md) |
| bare repository | Git | A repository with no working tree, whose directory is itself the Git directory; the server in every demo is one. | [Chapter 12, section 12.2](../textbook/ch12-remote-operations.md) |
| base branch | GitHub | The branch a pull request asks to merge into; the head branch holds the commits offered. | [Chapter 17, section 17.2](../textbook/ch17-pull-requests.md) |
| bisect | Git | `git bisect` finds the commit that changed a property by checking out a commit in the middle of the suspects, asking for a verdict, and halving the suspects until one is left. | [Chapter 14A, section 14A.20](../textbook/ch14a-history-investigation.md) |
| bitmap | Git | A file that stores, for selected commits, one bit per object in the pack saying whether that commit reaches it, so that a server can answer which objects a client needs without walking the graph. | [Chapter 26, section 26.8](../textbook/ch26-performance.md) |
| blame | Git | `git blame` annotates every line of a file, as it is in one revision, with the commit that last changed that line. It names the last change, not the cause. | [Chapter 14A, section 14A.16](../textbook/ch14a-history-investigation.md) |
| blob | Git | The object type that holds the bytes of one file, and nothing else: no name, no mode. | [Chapter 3, section 3.4](../textbook/ch03-git-internals.md) |
| blobless clone | Git | A partial clone made with `--filter=blob:none`: all commits and trees, file contents fetched when a command needs them. | [Chapter 26, section 26.12](../textbook/ch26-performance.md) |
| branch | Git | A ref under `refs/heads/` that holds the ID of one commit, the tip; it moves forward when you commit on it. The branch's history is whatever that commit reaches through its parents. | [Chapter 7, section 7.2](../textbook/ch07-branches.md) |
| branch protection rule (classic) | GitHub | The older rule mechanism: one rule per branch-name pattern, visible to administrators, with its own bypass behavior, still supported and still evaluated alongside rulesets. | [Chapter 18, section 18.14](../textbook/ch18-branch-protection.md) |
| bundle | Git | A file that holds a pack and the refs that go with it; an incremental bundle names commits the receiver must already have. | [Chapter 26, section 26.14](../textbook/ch26-performance.md) |
| bypass list | GitHub | The actors a ruleset excepts. A ruleset applies to everyone, administrators included, except the actors on its bypass list. | [Chapter 18, section 18.5](../textbook/ch18-branch-protection.md) |

## C

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| cache (Actions) | Actions | A directory stored under a key so that a later run with the same key can restore it; an optimization that may be absent, and untrusted input for a release job. | [Chapter 20A, section 20A.11](../textbook/ch20a-actions-fundamentals.md) |
| cache (Git) | Git | An old name for the index, still visible in options such as `--cached`. See index. | — |
| case-insensitive filesystem trap | Git | Git treats `Config.py` and `config.py` as two paths while the default macOS filesystem treats them as one file; `core.ignoreCase` reconciles the two and hides case-only renames. | [Chapter 4, section 4.12](../textbook/ch04-working-tree.md) |
| check, status check | GitHub | A result reported for a commit by a workflow or an external service. A required status check is a rule that holds a list of check names which must pass on the newest commit. | [Chapter 17, section 17.6](../textbook/ch17-pull-requests.md) |
| checkout | Git | Writing a commit's files into the working tree and the index. `git checkout` is the older command that both switched branches and restored files; `git switch` and `git restore` (Git 2.23) do the two jobs separately. | [Chapter 7, section 7.6](../textbook/ch07-branches.md) |
| cherry-pick | Git | `git cherry-pick <commit>` takes the difference between a commit and its parent, merges it into the current branch with a three-way merge, and commits the result as a new commit with a new ID. | [Chapter 10, section 10.2](../textbook/ch10-cherry-pick.md) |
| `CHERRY_PICK_HEAD` | Git | The root ref that names the commit being picked while a cherry-pick is stopped; a sequence of several picks also has `.git/sequencer/`. | [Chapter 10, section 10.6](../textbook/ch10-cherry-pick.md) |
| clean filter | Git | The command of a filter driver that rewrites a file's content on its way from the working tree into the repository, at `git add`. | [Chapter 14C, section 14C.8](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| clone | Git | A new repository created by `git clone`: the source registered as the remote `origin`, everything the default refspec covers fetched, and one branch checked out. | [Chapter 12, section 12.3](../textbook/ch12-remote-operations.md) |
| code owner | GitHub | A user or team that a `CODEOWNERS` line assigns to a path pattern; a suggested reviewer unless a rule requires the owner's approval. | [Chapter 19, section 19.6](../textbook/ch19-codeowners.md) |
| code scanning | GitHub | Analysis of code for vulnerabilities and coding errors with CodeQL or third-party tools that upload SARIF; free on public repositories, licensed on private ones as section 21B.13 states. | [Chapter 21B, section 21B.13](../textbook/ch21b-repository-security-incident-response.md) |
| `CODEOWNERS` | GitHub | A text file in the repository that maps path patterns to users and teams, which GitHub uses to request reviews automatically and, if a rule says so, to require them. It is read from the base branch of the pull request. | [Chapter 19, section 19.2](../textbook/ch19-codeowners.md) |
| commit | Git | An immutable object that names one complete snapshot of the project (a tree), the commit or commits it was built on, who wrote the change and when, who created the commit and when, and a message. It records a state, not a change. | [Chapter 6, section 6.2](../textbook/ch06-commits.md) |
| commit graph (history) | Git | The graph formed because every commit names its parents; "the history of X" is everything reachable from X by following those links. Not the same thing as the commit-graph file. | [Chapter 2, section 2.7](../textbook/ch02-mental-model.md) |
| commit ID | Git | The hash of the commit object; one ID names the snapshot, the metadata and, through the parent IDs, the whole history behind the commit. | [Chapter 6, section 6.4](../textbook/ch06-commits.md) |
| commit-graph | Git | A derived file that stores, for every commit, its parents, root tree, date and generation, and optionally a summary of changed paths, so that history walks stop decompressing commit objects. | [Chapter 26, section 26.6](../textbook/ch26-performance.md) |
| committer | Git | The person who created this commit object, recorded with name, email, time and offset; it differs from the author after a rebase, a cherry-pick or an amend by someone else. | [Chapter 6, section 6.5](../textbook/ch06-commits.md) |
| community health files | GitHub | Tracked files with well-known names (such as `CONTRIBUTING.md` or `SECURITY.md`) that GitHub finds and uses to guide the people who interact with a repository. | [Chapter 15, section 15.13](../textbook/ch15-github.md) |
| composite action | Actions | An action defined in `action.yml` with `runs.using: "composite"` that replaces several steps inside a job and runs on the caller's runner. | [Chapter 20B, section 20B.6](../textbook/ch20b-actions-delivery-debugging.md) |
| concurrency group | Actions | A name; GitHub lets at most one run or job with that name execute at a time and decides what happens to the others. | [Chapter 20B, section 20B.5](../textbook/ch20b-actions-delivery-debugging.md) |
| conditional include | Git | `includeIf.<condition>.path`: reads another configuration file only when a condition about the current repository is true, for example `gitdir:~/work/`. | [Chapter 14B, section 14B.4](../textbook/ch14b-config-tags-signing.md) |
| cone mode | Git | The default mode of sparse-checkout, in which you name directories and Git includes them recursively plus the files of their parent directories. | [Chapter 24, section 24.4](../textbook/ch24-monorepos.md) |
| configuration scope | Git | One of the places a setting is read from: system, global, local, worktree, and the command line; when a key appears more than once the value read last wins. | [Chapter 14B, section 14B.2](../textbook/ch14b-config-tags-signing.md) |
| conflict | Git | The state in which a merge cannot decide the content of a path: both sides changed the same lines, or lines with no unchanged line between them, and did not make the identical change. | [Chapter 8, section 8.7](../textbook/ch08-merge.md) |
| conflict markers | Git | The `<<<<<<<`, `=======` and `>>>>>>>` lines that Git writes into a working tree file to delimit the competing versions of a conflicting region. | [Chapter 8, section 8.8](../textbook/ch08-merge.md) |
| conflict style | Git | How much of the three versions is written between the markers: `merge` shows ours and theirs, `diff3` adds the base, `zdiff3` (Git 2.35) adds the base and moves shared edge lines out of the block. | [Chapter 8, section 8.9](../textbook/ch08-merge.md) |
| content addressing | Git | Naming an object by a hash of its type and content, so that identical content has the identical ID in every repository. | [Chapter 2, section 2.4](../textbook/ch02-mental-model.md) |
| context | Actions | A named object of facts about a run (`github`, `matrix`, `steps`, `secrets` and others), read in expressions. | [Chapter 20A, section 20A.5](../textbook/ch20a-actions-fundamentals.md) |
| credential helper | Git | A program named by `credential.helper` that stores and returns the username and token for HTTPS remotes; Git asks each configured helper in turn before prompting. | [Chapter 16, section 16.4](../textbook/ch16-authentication.md) |
| criss-cross merge | Git | A history in which two branches have each merged the other, so that they have two best common ancestors; Git merges those ancestors first and uses the result as the base. | [Chapter 8, section 8.5](../textbook/ch08-merge.md) |
| cruft pack | Git | A pack that holds only unreachable objects, with a companion file recording when each was last touched, so that garbage can wait out its grace period. | [Chapter 26, section 26.5](../textbook/ch26-performance.md) |

## D

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| dangling object | Git | An unreachable object that no other object refers to: the tip of lost history, or a blob that lost its index entry. `git fsck` reports it as information, not as damage. | [Chapter 13, section 13.6](../textbook/ch13-recovery.md) |
| default branch | GitHub | The branch a repository presents first and that clones check out; several workflow events use the workflow file on it. In Git, the name of the first branch comes from `init.defaultBranch`. | [Chapter 15, section 15.5](../textbook/ch15-github.md) |
| delta | Git | The storage of an object inside a pack as a difference from a similar object. It is a compression detail: a commit still records a full snapshot. | [Chapter 3, section 3.7](../textbook/ch03-git-internals.md) |
| Dependabot | GitHub | Three features that share a name: alerts about vulnerable dependencies, security updates, and version updates. | [Chapter 21B, section 21B.13](../textbook/ch21b-repository-security-incident-response.md) |
| deploy key | GitHub | An SSH key attached to one repository, not to a person; read-only unless write access is allowed, with no expiry. | [Chapter 16, section 16.14](../textbook/ch16-authentication.md) |
| detached HEAD | Git | The state in which HEAD holds a commit ID instead of a branch name; Git works normally, and new commits advance HEAD itself rather than any branch. | [Chapter 7, section 7.7](../textbook/ch07-branches.md) |
| diff driver | Git | A configuration section, selected by the `diff` attribute, that tells Git how to show changes to a path; `textconv` converts a file to text before diffing. | [Chapter 14C, section 14C.6](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| directory (in Git) | Git | Not tracked as such: a directory exists in a commit only because a file path passes through it. | [Chapter 4, section 4.11](../textbook/ch04-working-tree.md) |
| distributed version control | Git | A system in which every developer's copy contains the history, and "the server" is one more copy that the team agrees to treat as the meeting point. | [Chapter 1, section 1.3](../textbook/ch01-fundamentals.md) |
| divergence | Git | Two branches have diverged when neither tip is an ancestor of the other. | [Chapter 7, section 7.8](../textbook/ch07-branches.md) |
| draft pull request | GitHub | A pull request state that signals work in progress before "ready for review"; a state in GitHub's data, not in Git. | [Chapter 17, section 17.4](../textbook/ch17-pull-requests.md) |
| DVC | Course | One of the data-versioning tools of Chapter 28: Git holds a small file that names the data by checksum and another store holds the bytes. Not installed in the lab; its commands are given from its documentation. | [Chapter 28, section 28.6](../textbook/ch28-ai-ml-workflows.md) |

## E

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| empty commit | Git | A commit that has the same tree as its parent: a point in history with a message and no change. | [Chapter 6, section 6.8](../textbook/ch06-commits.md) |
| enforcement status | GitHub | Whether a ruleset is enforced. The documentation for Free, Pro and Team lists Active and Disabled; the Enterprise Cloud documentation adds Evaluate. | [Chapter 18, section 18.3](../textbook/ch18-branch-protection.md) |
| enterprise | GitHub | A container above organizations in GitHub's account model; several features named in the chapters are gated to Enterprise Cloud. | [Chapter 15, section 15.3](../textbook/ch15-github.md) |
| environment | Actions | A named GitHub object that a job can reference, holding protection rules the job must pass before it starts and secrets and variables it can read only after that. | [Chapter 20B, section 20B.2](../textbook/ch20b-actions-delivery-debugging.md) |
| event | Actions | What starts a workflow run (`push`, `pull_request`, `schedule`, `workflow_dispatch` and others); each event fixes which commit and ref the run is about and which copy of the workflow file is used. | [Chapter 20A, section 20A.4](../textbook/ch20a-actions-fundamentals.md) |
| expression | Actions | A formula written `${{ ... }}` over contexts that GitHub Actions replaces with its value before the step starts; with attacker-controlled values this is script injection. | [Chapter 20A, section 20A.5](../textbook/ch20a-actions-fundamentals.md) |

## F

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| fast-forward | Git | A merge in which the current commit is an ancestor of the commit merged: Git moves the branch ref to that commit and creates no new object. | [Chapter 8, section 8.3](../textbook/ch08-merge.md) |
| feature flag | Course | A condition in the code that keeps unfinished or unreleased behavior switched off, so that the code can be merged long before the feature is released. | [Chapter 27, section 27.11](../textbook/ch27-open-source-team-workflows.md) |
| fetch | Git | `git fetch` asks a remote where its refs point, downloads the objects you lack, and moves your remote-tracking refs; it never moves a local branch, the index or the working tree. | [Chapter 12, section 12.4](../textbook/ch12-remote-operations.md) |
| `FETCH_HEAD` | Git | A pseudoref written by every fetch that lists what was fetched; one of the two names the glossary still calls pseudorefs. | [Chapter 3, section 3.10](../textbook/ch03-git-internals.md) |
| file mode | Git | What Git records about a file besides content: its type (regular, symbolic link, gitlink) and whether it is executable. | [Chapter 4, section 4.10](../textbook/ch04-working-tree.md) |
| file-system monitor | Git | A daemon (`core.fsmonitor`) that tells Git which paths changed since the last command, replacing the scan of the working tree by a question. | [Chapter 26, section 26.9](../textbook/ch26-performance.md) |
| filter driver | Git | A pair of commands selected by the `filter` attribute: `clean` on the way into the repository, `smudge` on the way into the working tree. Git LFS is one. | [Chapter 14C, section 14C.8](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| fine-grained personal access token | GitHub | A token (prefix `github_pat_`) limited to one owner, optionally to selected repositories, with per-permission read or write. | [Chapter 16, section 16.6](../textbook/ch16-authentication.md) |
| first-parent history | Git | The history obtained by following only the first parent of each merge commit: the commits the receiving branch itself went through. | [Chapter 8, section 8.13](../textbook/ch08-merge.md) |
| fixup commit | Git | A correction recorded as a commit of its own whose subject (`fixup! <subject>`) names the earlier commit it belongs to. | [Chapter 9, section 9.7](../textbook/ch09-rebase.md) |
| force push | Git | A push that sets the server's ref to a commit that is not a descendant of its current value, removing commits from that branch on the server. | [Chapter 12, section 12.8](../textbook/ch12-remote-operations.md) |
| fork | GitHub | A second repository on GitHub with its own refs, settings and permissions, connected to the repository it was made from, and storing its Git data together with it. Git has no such concept. | [Chapter 15, section 15.7](../textbook/ch15-github.md) |
| fork network | GitHub | A repository and all its forks, whose Git data is stored together; an object pushed to one member can be reachable by ID through another. | [Chapter 15, section 15.7](../textbook/ch15-github.md) |
| four layers of protection | Course | Refs, reflogs, the grace period, and other repositories: a recovery is always a move from a lower layer back to the first one. | [Chapter 13, section 13.2](../textbook/ch13-recovery.md) |
| `fsck` | Git | `git fsck` verifies that everything reachable is present and well-formed, and lists what nothing reaches. | [Chapter 3, section 3.8](../textbook/ch03-git-internals.md) |

## G

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| garbage collection | Git | Packing objects and refs, expiring reflog entries by age, and deleting unreachable objects older than the grace period: `git gc`, and the tasks of `git maintenance`. | [Chapter 26, section 26.3](../textbook/ch26-performance.md) |
| geometric repacking | Git | Keeping packs in a sequence where each is at least twice as large as the next, by merging only the small ones; the default automatic maintenance strategy since Git 2.54. | [Chapter 26, section 26.4](../textbook/ch26-performance.md) |
| Git | Git | A program on your machine that stores history in a `.git` directory. It knows nothing about accounts, pull requests or rules. | [Chapter 1, section 1.5](../textbook/ch01-fundamentals.md) |
| Git Flow | Course | A branching model with two long-lived branches, `main` for released code and `develop` for integration, plus feature, release and hotfix branches. The names are conventions; Git gives none of them a meaning. | [Chapter 27, section 27.7](../textbook/ch27-open-source-team-workflows.md) |
| Git LFS | LFS | A separate program that replaces large files in commits by pointer files through a clean and a smudge filter and keeps the content in an LFS object store. | [Chapter 22, section 22.3](../textbook/ch22-git-lfs.md) |
| `.git` directory | Git | The repository: an object database, names for objects, a log of how those names moved, one staging file, and settings. The files next to it are a working tree that Git can rebuild from it. | [Chapter 3, section 3.2](../textbook/ch03-git-internals.md) |
| `.gitattributes` | Git | A versioned file that attaches attributes to paths; it reaches every clone, while the programs that some attributes name are defined in each clone's configuration. | [Chapter 14C, section 14C.4](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| GitHub | GitHub | A hosted service that stores Git repositories and surrounds them with its own objects: accounts, permissions, pull requests, reviews, rulesets and workflows. | [Chapter 1, section 1.5](../textbook/ch01-fundamentals.md) |
| GitHub App | GitHub | An integration that acts with its own identity; its installation token (prefix `ghs_`) lasts 1 hour and reaches the repositories and permissions of the installation. | [Chapter 16, section 16.14](../textbook/ch16-authentication.md) |
| GitHub CLI (`gh`) | GitHub | A client for GitHub's API that knows which repository you are in. Version 2.88.1 is installed here. | [Chapter 15, section 15.16](../textbook/ch15-github.md) |
| GitHub Flow | Course | One long-lived branch that is always deployable, short branches off it, a pull request for each, and deployment right after the merge. | [Chapter 27, section 27.6](../textbook/ch27-open-source-team-workflows.md) |
| GitHub-hosted runner | Actions | A fresh virtual machine, built from a published image, that runs one job and is then destroyed. | [Chapter 20B, section 20B.8](../textbook/ch20b-actions-delivery-debugging.md) |
| `GITHUB_TOKEN` | Actions | The short-lived installation token every job gets for the repository that contains the workflow; the `permissions` key decides what it may do. | [Chapter 21A, section 21A.3](../textbook/ch21a-actions-security.md) |
| `.gitignore` | Git | A file of ignore patterns. It affects only untracked paths: a file that is already tracked stays tracked. | [Chapter 4, section 4.5](../textbook/ch04-working-tree.md) |
| gitlink | Git | A tree entry of mode 160000 that records the ID of a commit in another repository: what a superproject stores for a submodule. | [Chapter 23, section 23.2](../textbook/ch23-submodules.md) |
| `.gitmodules` | Git | The versioned file in a superproject that records each submodule's path and URL. | [Chapter 23, section 23.2](../textbook/ch23-submodules.md) |
| grace period | Git | The time an unreachable object is kept before a collection may delete it: two weeks by default (`gc.pruneExpire`). | [Chapter 13, section 13.4](../textbook/ch13-recovery.md) |

## H

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| head branch | GitHub | The branch whose commits a pull request offers to the base branch. | [Chapter 17, section 17.2](../textbook/ch17-pull-requests.md) |
| `HEAD` | Git | The ref that says where you are: normally a symbolic ref that names the current branch, and in detached state a direct reference to a commit. | [Chapter 7, section 7.3](../textbook/ch07-branches.md) |
| hook | Git | An executable file with a fixed name in the hooks directory (or, since Git 2.54, a command named in configuration) that Git runs at a defined point of a command. Hooks are local, are not cloned, and cannot enforce policy. | [Chapter 14C, section 14C.9](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| host key | GitHub | The key with which an SSH server proves who it is; `ssh` compares it with the one remembered in `~/.ssh/known_hosts`. | [Chapter 16, section 16.11](../textbook/ch16-authentication.md) |
| hotfix | Course | A fix made for a released version; under release branches it is committed on `main` first and cherry-picked down, or on the oldest branch and merged upward. | [Chapter 27, section 27.10](../textbook/ch27-open-source-team-workflows.md) |
| hunk | Git | One contiguous block of changed lines in a diff, with its context; `git add -p` stages hunk by hunk. | [Chapter 5, section 5.5](../textbook/ch05-index.md) |

## I

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| ignored file | Git | A path that has no index entry and matches an ignore pattern. Ignored is the opposite of tracked, so no pattern can ignore a tracked file. | [Chapter 4, section 4.3](../textbook/ch04-working-tree.md) |
| incident | Course | A problem in shared state (a shared branch, a published history, a credential, a pipeline) that other people depend on while you are still working out what it is. | [Chapter 30, section 30.2](../textbook/ch30-incident-response.md) |
| index | Git | One binary file, `.git/index`, that records for every tracked path a mode, a blob ID, a stage number and cached `stat` data. It is the proposed next commit, also called the staging area. | [Chapter 5, section 5.2](../textbook/ch05-index.md) |
| indirect merge | GitHub | A pull request that GitHub marks as merged because its head commits became reachable from its base branch by another route. | [Chapter 17, section 17.13](../textbook/ch17-pull-requests.md) |
| intent-to-add | Git | `git add -N <path>` gives a new file an index entry without staging its content, so that index-against-working-tree comparisons stop overlooking it. | [Chapter 5, section 5.6](../textbook/ch05-index.md) |
| interactive rebase | Git | `git rebase -i`: Git shows the todo list before executing it, and you may edit, reorder, extend or shorten it. | [Chapter 9, section 9.6](../textbook/ch09-rebase.md) |
| issue | GitHub | A numbered record in GitHub's database for a unit of work or a report, which since 2025 can have a type, a parent, children and dependencies. | [Chapter 15, section 15.8](../textbook/ch15-github.md) |

## J

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| job | Actions | A list of steps that run in order on one fresh runner; jobs of a workflow run in parallel unless `needs` orders them. | [Chapter 20A, section 20A.2](../textbook/ch20a-actions-fundamentals.md) |

## K

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| `known_hosts` | GitHub | The file `~/.ssh/known_hosts` in which `ssh` remembers server host keys. Deleting it wholesale removes the check. | [Chapter 16, section 16.11](../textbook/ch16-authentication.md) |

## L

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| label | GitHub | A GitHub tag on issues and pull requests, stored in GitHub's database; `gh label clone` copies a label set between repositories. | [Chapter 15, section 15.9](../textbook/ch15-github.md) |
| lease | Git | The expected value of the server's ref in `--force-with-lease`. Without an explicit value it is your remote-tracking ref, which a background fetch can update without your looking. | [Chapter 12, section 12.8](../textbook/ch12-remote-operations.md) |
| lightweight tag | Git | A ref under `refs/tags/` that names an object directly: no tag object, no tagger, no message. | [Chapter 7, section 7.11](../textbook/ch07-branches.md) |
| line-ending normalization | Git | A path with the `text` attribute is stored with LF endings in the repository whatever its endings are on disk; `* text=auto` lets Git decide per file which files are text. | [Chapter 14C, section 14C.5](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| linear history | GitHub | As a rule ("Require linear history"): GitHub rejects an update that adds a commit with two parents to the ref. | [Chapter 18, section 18.11](../textbook/ch18-branch-protection.md) |
| linked worktree | Git | An additional working tree created by `git worktree add`: the same objects and refs as the main worktree, with a HEAD and an index of its own. | [Chapter 25, section 25.2](../textbook/ch25-worktrees.md) |
| loose object | Git | One compressed file whose content is a short header, a NUL byte and the data, and whose file name is the hash of those bytes. | [Chapter 3, section 3.3](../textbook/ch03-git-internals.md) |
| loose ref | Git | A ref stored as a small file under `refs/` in the default `files` format; the same ref may also be a line in `packed-refs`. | [Chapter 3, section 3.9](../textbook/ch03-git-internals.md) |

## M

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| machine user | GitHub | A user account for automation: it occupies a seat, and somebody has to own its password and second factor. | [Chapter 16, section 16.14](../textbook/ch16-authentication.md) |
| `main` | Git | The example default branch of this course, set through `init.defaultBranch`; unconfigured Git 2.55 still creates `master`. A name by convention only. | [Chapter 1, section 1.9](../textbook/ch01-fundamentals.md) |
| maintenance | Git | `git maintenance` runs a configurable set of tasks (`gc`, `commit-graph`, `prefetch`, `loose-objects`, `incremental-repack` and others); since Git 2.54 the maintenance Git starts on its own no longer runs `git gc`. | [Chapter 26, section 26.3](../textbook/ch26-performance.md) |
| master | Git | The name unconfigured Git still gives the first branch. See `main`. | — |
| matrix | Actions | A strategy that turns one job definition into one job per combination of the values you list, each with its own runner and `matrix` context. | [Chapter 20A, section 20A.10](../textbook/ch20a-actions-fundamentals.md) |
| merge | Git | Joining another history into the current branch: by fast-forward, or by a three-way merge of the two tips against their merge base, recorded as a commit with two parents. | [Chapter 8, section 8.4](../textbook/ch08-merge.md) |
| merge base | Git | The best common ancestor of two commits: the most recent commit that both histories contain, and the third input of every merge. | [Chapter 8, section 8.2](../textbook/ch08-merge.md) |
| merge commit | Git | An ordinary commit object with more than one `parent` line; the order of those lines records which branch received the merge. | [Chapter 8, section 8.13](../textbook/ch08-merge.md) |
| merge driver | Git | The file-level merge chosen by the `merge` attribute for a path: the normal text merge, a refusal (`-merge`), the built-in `union` driver, or a program you define. | [Chapter 14C, section 14C.7](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| merge method | GitHub | One of the three merge buttons: a merge commit that keeps your commits, a squash that replaces them by one new commit, or a rebase that puts new copies of your commits in a straight line. | [Chapter 17, section 17.8](../textbook/ch17-pull-requests.md) |
| merge queue | GitHub | A mechanism that merges pull requests one group at a time and runs the required checks on the exact commit that will become the new tip of the base branch; workflows must listen to the `merge_group` event. | [Chapter 17, section 17.11](../textbook/ch17-pull-requests.md) |
| merge strategy | Git | The algorithm that turns the inputs of a merge into a result tree, selected with `-s`. `ort` is the default since Git 2.34. | [Chapter 8, section 8.6](../textbook/ch08-merge.md) |
| `MERGE_HEAD` | Git | The pseudoref that names the commit being merged while a merge is in progress; it is what makes the next commit a merge commit. | [Chapter 8, section 8.8](../textbook/ch08-merge.md) |
| milestone | GitHub | A GitHub object that groups issues and pull requests toward a date and shows a completion percentage. It is not a Git tag and not a release. | [Chapter 15, section 15.9](../textbook/ch15-github.md) |
| monorepo | Course | A repository that keeps many separately deployed projects together so that one commit can change all of them; a polyrepo layout gives each project its own history, access rules and release cadence. | [Chapter 24, section 24.2](../textbook/ch24-monorepos.md) |
| multi-pack-index | Git | One sorted index over the objects of many packs, so that finding an object costs one lookup however many packs there are. | [Chapter 26, section 26.7](../textbook/ch26-performance.md) |

## N

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| non-fast-forward | Git | A ref update in which the new value is not a descendant of the old one. A normal push refuses it. | [Chapter 12, section 12.7](../textbook/ch12-remote-operations.md) |

## O

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| OAuth app token | GitHub | A token (prefix `gho_`) granted to an app on behalf of a user, by scope; `gh auth login` produces one. | [Chapter 16, section 16.6](../textbook/ch16-authentication.md) |
| object | Git | A unit of Git's storage, named by the hash of its type and content. There are four types: blob, tree, commit and tag. | [Chapter 2, section 2.5](../textbook/ch02-mental-model.md) |
| object database | Git | The store of all objects under `.git/objects`, as loose files and packs. | [Chapter 3, section 3.2](../textbook/ch03-git-internals.md) |
| object ID | Git | The hash that names an object: 40 hex digits with SHA-1, the default, and 64 with SHA-256. Never assume the length. | [Chapter 2, section 2.4](../textbook/ch02-mental-model.md) |
| octopus merge | Git | A single merge commit with three or more parents, made by a separate strategy that refuses any conflict. | [Chapter 8, section 8.14](../textbook/ch08-merge.md) |
| OIDC federation | Actions | In place of a stored cloud key, the job asks GitHub for a signed statement of what it is, and the cloud exchanges it for a credential valid for that job only. | [Chapter 21A, section 21A.10](../textbook/ch21a-actions-security.md) |
| organization | GitHub | A container that owns repositories and decides who may do what; people sign in to user accounts. | [Chapter 15, section 15.3](../textbook/ch15-github.md) |
| `ORIG_HEAD` | Git | One file holding the commit HEAD pointed at before the last "drastic" command (`git am`, `git merge`, `git rebase`, `git reset`; also `git pull` and `git stash push`). It has one slot and no reflog: use it only as the very next command. | [Chapter 13, section 13.5](../textbook/ch13-recovery.md) |
| `origin` | Git | The name `git clone` gives the remote it cloned from. A convention, not a keyword. | [Chapter 12, section 12.3](../textbook/ch12-remote-operations.md) |
| "ours" and "theirs" | Git | The two sides of a three-way merge: stage 2 and stage 3. In a merge, "ours" is your branch. During a rebase "ours" is the new base plus the copies made so far and "theirs" is your own commit. | [Chapter 9, section 9.11](../textbook/ch09-rebase.md) |

## P

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| pack index | Git | The `.idx` file beside a packfile that finds any object in it by ID. Derived data: `git index-pack` rebuilds it. | [Chapter 3, section 3.7](../textbook/ch03-git-internals.md) |
| packed-refs | Git | One file that holds many refs as lines, written by `git pack-refs`; a loose file for the same ref takes precedence. | [Chapter 3, section 3.9](../textbook/ch03-git-internals.md) |
| packfile | Git | One file that stores many objects and may store an object as a delta from a similar object. None of this changes what an object is. | [Chapter 3, section 3.7](../textbook/ch03-git-internals.md) |
| parent (of a commit) | Git | A commit named in another commit's `parent` line; these lines are the only links in the history graph. | [Chapter 6, section 6.6](../textbook/ch06-commits.md) |
| partial clone | Git | A clone that has all of the history's structure and leaves out objects of a chosen kind, which a promisor remote has promised to deliver when a command needs them. | [Chapter 26, section 26.12](../textbook/ch26-performance.md) |
| patch ID | Git | A hash of a change's diff, ignoring line numbers and whitespace, by which `git cherry`, `git log --cherry-mark` and rebase recognize the same change under another commit ID. | [Chapter 10, section 10.10](../textbook/ch10-cherry-pick.md) |
| pathspec | Git | A pattern that limits a command to paths; `.` means this directory and below. | [Chapter 5, section 5.8](../textbook/ch05-index.md) |
| `permissions` (workflow key) | Actions | The key that decides what the job's `GITHUB_TOKEN` may do; least privilege is declared here. | [Chapter 21A, section 21A.3](../textbook/ch21a-actions-security.md) |
| personal access token (classic) | GitHub | A token (prefix `ghp_`) that reaches, by scope, every repository and organization the user can reach; long-lived, no expiry required. | [Chapter 16, section 16.6](../textbook/ch16-authentication.md) |
| pickaxe | Git | `git log -S<string>` finds commits that changed how many times a string occurs; `-G<regex>` finds commits whose patch has an added or removed line matching a pattern. | [Chapter 14A, section 14A.11](../textbook/ch14a-history-investigation.md) |
| pinning (an action) | Actions | Writing `uses: owner/repo@<full commit ID>`: only a full commit ID guarantees that the code is the code you reviewed, because tags can move. | [Chapter 21A, section 21A.7](../textbook/ch21a-actions-security.md) |
| plumbing | Git | Commands with stable output that do one low-level operation each (`git hash-object`, `git update-ref`); porcelain commands such as `git add` and `git commit` are built from them. | [Chapter 2, section 2.6](../textbook/ch02-mental-model.md) |
| pointer file | LFS | The three-line blob that Git stores for an LFS-tracked path: the specification version, the SHA-256 of the real content, and its size. | [Chapter 22, section 22.3](../textbook/ch22-git-lfs.md) |
| porcelain | Git | The user-facing commands, such as `git add` and `git commit`, as opposed to plumbing. | [Chapter 2, section 2.6](../textbook/ch02-mental-model.md) |
| postmortem | Course | A written record of an incident that explains how the system allowed it, so that the system can be changed; "blameless" means every person's action is treated as reasonable given what they knew. | [Chapter 30, section 30.19](../textbook/ch30-incident-response.md) |
| private vulnerability reporting | GitHub | A way for outsiders to report a security problem to maintainers without a public issue; a `SECURITY.md` file states how to report. | [Chapter 21B, section 21B.13](../textbook/ch21b-repository-security-incident-response.md) |
| promisor remote | Git | The remote that has promised to deliver the objects a partial clone left out. | [Chapter 26, section 26.12](../textbook/ch26-performance.md) |
| protocol version 2 | Git | The wire protocol that is the default since Git 2.26; the server no longer lists every ref first. | [Chapter 12, section 12.13](../textbook/ch12-remote-operations.md) |
| prune | Git | To delete: unreachable objects (`git prune`, `git gc --prune=<date>`), stale remote-tracking refs (`git fetch --prune`), or entries of missing worktrees (`git worktree prune`). | [Chapter 13, section 13.13](../textbook/ch13-recovery.md) |
| pseudoref | Git | Since Git 2.46 only `FETCH_HEAD` and `MERGE_HEAD`: files that look like refs and are not refs in the strict sense. `ORIG_HEAD`, `CHERRY_PICK_HEAD` and the others are root refs. | [Chapter 3, section 3.10](../textbook/ch03-git-internals.md) |
| pull | Git | `git pull` is `git fetch` followed by one integration of the fetched upstream into the current branch: a fast-forward, a merge or a rebase. | [Chapter 12, section 12.6](../textbook/ch12-remote-operations.md) |
| pull request | GitHub | A GitHub object that proposes merging a head branch into a base branch. Opening one moves no branch; it creates `refs/pull/N/head` and, when the merge is clean, a test merge commit at `refs/pull/N/merge`. | [Chapter 17, section 17.2](../textbook/ch17-pull-requests.md) |
| `pull_request_target` | Actions | An event that runs the workflow from the default branch, with the repository's token and secrets, in response to a pull request; safe only as long as it never executes the pull request's code. | [Chapter 21A, section 21A.5](../textbook/ch21a-actions-security.md) |
| push | Git | `git push` asks a remote to make some of its refs point at commits of yours and sends the objects it lacks; each ref succeeds only if both your Git and the remote accept the update. | [Chapter 12, section 12.7](../textbook/ch12-remote-operations.md) |
| push protection | GitHub | A secret-scanning feature that blocks a push containing a recognized secret before it reaches the repository. | [Chapter 21B, section 21B.12](../textbook/ch21b-repository-security-incident-response.md) |
| "pwn request" | Actions | The attack on a workflow with a privileged trigger such as `pull_request_target` that checks out and executes the code of an untrusted pull request. | [Chapter 21A, section 21A.5](../textbook/ch21a-actions-security.md) |

## R

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| range | Git | A set of commits defined by reachability: everything reachable from the included tips, minus everything reachable from the excluded ones. | [Chapter 14A, section 14A.8](../textbook/ch14a-history-investigation.md) |
| range-diff | Git | `git range-diff` compares two versions of a series of commits by pairing each old commit with its new counterpart. | [Chapter 9, section 9.14](../textbook/ch09-rebase.md) |
| reachability | Git | An object is reachable if you can arrive at it from a starting point (a ref, the index, a reflog entry) by following the IDs stored inside objects. | [Chapter 3, section 3.8](../textbook/ch03-git-internals.md) |
| rebase | Git | `git rebase <upstream>` creates a copy of each commit your branch has and the upstream lacks, on top of the upstream, and then points your branch at the last copy. Every copy has a new ID. | [Chapter 9, section 9.2](../textbook/ch09-rebase.md) |
| `REBASE_HEAD` | Git | The root ref that names the commit being replayed while a rebase is stopped. | [Chapter 9, section 9.11](../textbook/ch09-rebase.md) |
| ref | Git | A name that holds an object ID or the name of another ref: branches, tags, remote-tracking branches, HEAD. | [Chapter 3, section 3.9](../textbook/ch03-git-internals.md) |
| reflog | Git | A local, append-only list of the values a ref has had, with the time, the person and the command behind each change. Entries expire after 90 days, or 30 when unreachable, by default. | [Chapter 13, section 13.3](../textbook/ch13-recovery.md) |
| `refs/pull/N/head`, `refs/pull/N/merge` | GitHub | Read-only refs GitHub creates in the base repository for pull request N: the head commit, and the test merge commit when the merge is clean. | [Chapter 17, section 17.2](../textbook/ch17-pull-requests.md) |
| refspec | Git | `[+]<source>:<destination>`: the rule that decides which refs a fetch or a push touches; the source is on the sending side. | [Chapter 12, section 12.12](../textbook/ch12-remote-operations.md) |
| reftable | Git | A ref storage format that keeps refs and reflogs in binary tables under `.git/reftable/`; available since Git 2.45 and planned as the default for new repositories in Git 3.0. | [Chapter 3, section 3.13](../textbook/ch03-git-internals.md) |
| release | GitHub | A GitHub record that points at a tag name and adds a title, notes, files and flags. The tag is Git's; the release is not. | [Chapter 15, section 15.12](../textbook/ch15-github.md) |
| release branch | Course | A branch cut from the trunk shortly before a release, which receives only fixes and is where the release and its patches are tagged. | [Chapter 27, section 27.8](../textbook/ch27-open-source-team-workflows.md) |
| remote | Git | A name in your repository's configuration that stands for another repository: its URL, and the rules for copying refs between that repository and yours. | [Chapter 12, section 12.2](../textbook/ch12-remote-operations.md) |
| remote-tracking branch | Git | A ref in your own repository, such as `origin/main`, that records the last position of a branch in another repository as of your last fetch or push. | [Chapter 7, section 7.10](../textbook/ch07-branches.md) |
| rename detection | Git | A commit does not record renames; `git diff` and `git log` conclude that a path was renamed when one path disappeared, another appeared, and their contents are similar enough. | [Chapter 4, section 4.9](../textbook/ch04-working-tree.md) |
| repository | Git | The `.git` directory: objects, refs, reflogs, the index and configuration. On GitHub, a Git repository surrounded by records in GitHub's database that Git cannot copy. | [Chapter 3, section 3.2](../textbook/ch03-git-internals.md) |
| required review | GitHub | The pull request rule that turns advisory reviews into a gate: a number of approvals, with sub-options that each close one loophole. | [Chapter 18, section 18.7](../textbook/ch18-branch-protection.md) |
| rerere | Git | "Reuse recorded resolution": with `rerere.enabled`, Git records the text of every conflict together with your resolution and writes it again when the same conflict text appears. | [Chapter 14C, section 14C.3](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| rescue branch | Course | A branch such as `rescue/<what>` created on a lost or endangered commit before anything else moves: a named commit cannot expire. | [Chapter 13, section 13.7](../textbook/ch13-recovery.md) |
| reset | Git | `git reset <commit>` makes the current branch point at `<commit>`; the mode decides whether the index (`--mixed`) and the working tree (`--hard`) are rewritten to match. | [Chapter 11, section 11.4](../textbook/ch11-reset-revert-restore.md) |
| restore | Git | `git restore` copies a stored version of the named paths into the working tree, into the index, or into both, and moves no ref. | [Chapter 11, section 11.3](../textbook/ch11-reset-revert-restore.md) |
| reusable workflow | Actions | A workflow file with `on: workflow_call` that another workflow calls as if it were a single job. | [Chapter 20B, section 20B.6](../textbook/ch20b-actions-delivery-debugging.md) |
| revert | Git | `git revert <commit>` adds a commit whose change is the opposite of what `<commit>` changed, and removes nothing. | [Chapter 11, section 11.8](../textbook/ch11-reset-revert-restore.md) |
| review | GitHub | A claim about a specific diff at a specific commit: a comment, an approval or a request for changes. | [Chapter 17, section 17.17](../textbook/ch17-pull-requests.md) |
| risk labels | Course | 🟢 SAFE reads state or only adds objects; 🟡 CAUTION moves refs or rewrites local history; 🔴 DANGEROUS can destroy uncommitted work, remote history, or the safety net itself. | [Chapter 1, section 1.8](../textbook/ch01-fundamentals.md) |
| role | GitHub | A named level of access to a repository. In an organization, what a person can do is the highest of every grant that reaches them. | [Chapter 15, section 15.4](../textbook/ch15-github.md) |
| root commit | Git | A commit without a `parent` line. | [Chapter 6, section 6.6](../textbook/ch06-commits.md) |
| root ref | Git | A ref that lives directly in the repository directory, with a name in capital letters such as `HEAD`, `ORIG_HEAD`, `CHERRY_PICK_HEAD` or `REBASE_HEAD`. | [Chapter 3, section 3.10](../textbook/ch03-git-internals.md) |
| root-cause framework | Course | The seven-line box this course uses for surprising behavior: observed behavior, Git state, mechanism, root cause, why Git does this, correct fix, prevention. | [Chapter 1, section 1.10](../textbook/ch01-fundamentals.md) |
| ruleset | GitHub | A named list of rules with a target (which refs), an enforcement status and a bypass list. All active rulesets that target a ref are added together, and for each rule the strictest version wins. | [Chapter 18, section 18.3](../textbook/ch18-branch-protection.md) |
| runner | Actions | The machine that runs one job: GitHub-hosted, or self-hosted on a machine you operate. | [Chapter 20A, section 20A.2](../textbook/ch20a-actions-fundamentals.md) |

## S

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| `safe.bareRepository` | Git | A setting: with `explicit`, Git uses a bare repository only when you name it with `--git-dir` or `GIT_DIR`. Planned as the default in Git 3.0. | [Chapter 21B, section 21B.3](../textbook/ch21b-repository-security-incident-response.md) |
| `safe.directory` | Git | The list of directories Git trusts although a different operating-system user owns them; without an entry Git refuses to read such a repository's configuration. | [Chapter 21B, section 21B.3](../textbook/ch21b-repository-security-incident-response.md) |
| Scalar | Git | `scalar`, a command shipped with Git since 2.38 that sets up a blobless, sparse clone together with settings and scheduled maintenance. | [Chapter 24, section 24.7](../textbook/ch24-monorepos.md) |
| script injection | Actions | An expression in `${{ }}` is replaced by its value in the text of a script before the shell starts, so a value an outsider controls becomes part of your program. | [Chapter 21A, section 21A.6](../textbook/ch21a-actions-security.md) |
| secret (Actions) | Actions | An encrypted value stored in GitHub settings and read through the `secrets` context; it is as exposed as the least trustworthy code in any job that receives it, and masking is not a boundary. | [Chapter 21A, section 21A.9](../textbook/ch21a-actions-security.md) |
| secret scanning | GitHub | A GitHub feature that scans the entire Git history on all branches, plus issues, pull requests, discussions and wikis, for recognized secrets; free on public repositories. | [Chapter 21B, section 21B.12](../textbook/ch21b-repository-security-incident-response.md) |
| self-hosted runner | Actions | The runner program on a machine you operate, which asks GitHub for jobs and runs them with whatever access that machine has; it keeps state between jobs unless made ephemeral. | [Chapter 20B, section 20B.9](../textbook/ch20b-actions-delivery-debugging.md) |
| Semantic Versioning | Course | The version scheme `MAJOR.MINOR.PATCH` of the 2.0.0 specification, used for the tag names in this course. | [Chapter 14B, section 14B.13](../textbook/ch14b-config-tags-signing.md) |
| sequencer | Git | The state under `.git/sequencer/` that holds the rest of the plan when a cherry-pick or revert of several commits has stopped. | [Chapter 10, section 10.6](../textbook/ch10-cherry-pick.md) |
| SHA-1, SHA-256 | Git | The two object formats. SHA-1 with collision detection is the default; SHA-256 repositories (supported since Git 2.42) cannot exchange objects with SHA-1 repositories, and a repository on GitHub stays SHA-1. | [Chapter 3, section 3.14](../textbook/ch03-git-internals.md) |
| shallow clone | Git | A clone that contains the commits within a given distance of the requested tips and a file, `.git/shallow`, that tells Git to pretend the history ends there. | [Chapter 26, section 26.11](../textbook/ch26-performance.md) |
| sign-off | Git | The `Signed-off-by:` trailer added by `git commit -s`. It is a line of text, not a cryptographic signature. | [Chapter 6, section 6.9](../textbook/ch06-commits.md) |
| signature | Git | A detached cryptographic signature over the bytes of one commit or one annotated tag, produced by an external program and stored inside that object. It proves that a key holder signed, not who wrote the change. | [Chapter 14B, section 14B.15](../textbook/ch14b-config-tags-signing.md) |
| skip-worktree bit | Git | A flag on an index entry that tells Git not to write or examine the working tree file; sparse-checkout uses it for paths outside the cone. | [Chapter 5, section 5.12](../textbook/ch05-index.md) |
| smudge filter | Git | The command of a filter driver that rewrites content on its way from the repository into the working tree, at checkout. | [Chapter 14C, section 14C.8](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| snapshot | Git | The complete state of every tracked file at one moment, recorded by a commit as the ID of one tree. Git stores snapshots, not diffs. | [Chapter 2, section 2.3](../textbook/ch02-mental-model.md) |
| sparse index | Git | An index in which all entries of a directory outside the cone are replaced by one entry naming that directory's tree. | [Chapter 24, section 24.6](../textbook/ch24-monorepos.md) |
| sparse-checkout | Git | A working tree that holds only chosen directories, while the repository, its history and its index still contain every file. | [Chapter 24, section 24.4](../textbook/ch24-monorepos.md) |
| squash | Git | Combining several commits into one: in an interactive rebase, with `git merge --squash`, or with GitHub's "Squash and merge", each of which creates a new commit. | [Chapter 8, section 8.12](../textbook/ch08-merge.md) |
| SSH key | GitHub | A key pair with which you prove who you are by signing a challenge; the private key never leaves your machine and GitHub holds only the public key. | [Chapter 16, section 16.8](../textbook/ch16-authentication.md) |
| SSO (SAML single sign-on) | GitHub | An Enterprise Cloud feature: in an organization that uses it, a credential must be authorized for that organization in addition to being valid. | [Chapter 16, section 16.15](../textbook/ch16-authentication.md) |
| stacked pull requests | GitHub | A chain of pull requests in one repository in which each targets the branch of the one below, so that a large change is reviewed as small layers. | [Chapter 17, section 17.14](../textbook/ch17-pull-requests.md) |
| stage (number) | Git | The slot of an index entry: 0 normally; during a conflict 1 holds the base, 2 "ours" and 3 "theirs". | [Chapter 5, section 5.13](../textbook/ch05-index.md) |
| staging area | Git | Another name for the index. See index. | — |
| stale branch | Git | A ref that nobody needs any more; Git offers three tests for it (age, reachability from `main`, a deleted upstream), each with a blind spot. | [Chapter 7, section 7.13](../textbook/ch07-branches.md) |
| stash | Git | `git stash push` records the index and the working tree as commits that only `refs/stash` reaches, then resets both to HEAD. The stash list is the reflog of `refs/stash`. | [Chapter 11, section 11.11](../textbook/ch11-reset-revert-restore.md) |
| stat data | Git | The size and timestamps an index entry remembers from when Git last saw the file match it, so that "has this file changed?" normally costs one `lstat` call. | [Chapter 5, section 5.14](../textbook/ch05-index.md) |
| step | Actions | One entry of a job: a shell command (`run`) or an action (`uses`). Every `run` step is a new shell process. | [Chapter 20A, section 20A.2](../textbook/ch20a-actions-fundamentals.md) |
| strategy option | Git | An option passed with `-X` that adjusts how one merge strategy behaves, for example `-X ours`, which silently takes one side of every conflicting hunk. | [Chapter 8, section 8.6](../textbook/ch08-merge.md) |
| submodule | Git | Another repository checked out in a subdirectory of yours, of which your repository records exactly one thing in its history: the ID of the commit that should be checked out there. | [Chapter 23, section 23.2](../textbook/ch23-submodules.md) |
| subtree | Git | `git subtree` copies another project's files into a subdirectory as ordinary tracked files and records in commit messages where they came from. | [Chapter 23, section 23.13](../textbook/ch23-submodules.md) |
| superproject | Git | The repository that contains a submodule. | [Chapter 23, section 23.2](../textbook/ch23-submodules.md) |
| symbolic ref | Git | A ref that holds the name of another ref instead of an object ID; HEAD is normally one. | [Chapter 3, section 3.9](../textbook/ch03-git-internals.md) |

## T

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| tag | Git | A ref under `refs/tags/` that is not expected to move; lightweight or annotated. Every clone keeps its own copy and never updates it by itself. | [Chapter 14B, section 14B.8](../textbook/ch14b-config-tags-signing.md) |
| tag object | Git | The fourth object type: a named, dated pointer to another object with a tagger and a message, optionally signed. | [Chapter 3, section 3.4](../textbook/ch03-git-internals.md) |
| team | GitHub | A group of organization members that can be granted a role on repositories and named as a code owner or required reviewer. | [Chapter 15, section 15.4](../textbook/ch15-github.md) |
| ten-command diagnosis | Course | The fixed, read-only sequence of ten commands with which every investigation in this course opens. | [Chapter 1, section 1.11](../textbook/ch01-fundamentals.md) |
| test merge commit | GitHub | The commit at `refs/pull/N/merge` that GitHub computes when a pull request merges cleanly; `actions/checkout` checks it out on `pull_request` events. | [Chapter 17, section 17.2](../textbook/ch17-pull-requests.md) |
| textconv | Git | A diff driver setting that names a program converting a file to text before Git diffs it. | [Chapter 14C, section 14C.6](../textbook/ch14c-stash-rerere-attributes-hooks.md) |
| three trees | Git | The three places a version of a file can be at the same time: the commit that HEAD names, the index, and the working tree. | [Chapter 2, section 2.9](../textbook/ch02-mental-model.md) |
| three-way merge | Git | Combining two versions against their common base, path by path and then line by line: a change made on one side only is taken, and overlapping different changes conflict. | [Chapter 8, section 8.4](../textbook/ch08-merge.md) |
| tip | Git | The commit a branch ref currently holds. | [Chapter 7, section 7.2](../textbook/ch07-branches.md) |
| todo list | Git | The list of instructions (`pick`, `reword`, `edit`, `squash`, `fixup`, `drop`, `exec` and others) that a rebase executes from top to bottom. | [Chapter 9, section 9.6](../textbook/ch09-rebase.md) |
| token | GitHub | A string that stands for an account with a subset of its rights; the prefix says what kind it is, and the kind decides how far a leak reaches. Over HTTPS, GitHub accepts a token where HTTP expects a password, and nothing else. | [Chapter 16, section 16.6](../textbook/ch16-authentication.md) |
| tracked file | Git | A path that has an index entry. | [Chapter 4, section 4.3](../textbook/ch04-working-tree.md) |
| tracking branch | Git | Loose usage for either a remote-tracking branch or a local branch that has an upstream. See remote-tracking branch and upstream. | — |
| trailer | Git | A `Key: value` line in the last paragraph of a commit message, placed where Git and other tools can find and parse it. | [Chapter 6, section 6.9](../textbook/ch06-commits.md) |
| tree | Git | The object type that holds one directory listing: for each entry a mode, a name and the ID of a blob or another tree. | [Chapter 3, section 3.4](../textbook/ch03-git-internals.md) |
| trunk-based development | Course | Developers integrate into one branch, the trunk, and avoid other long-lived development branches; larger teams use short-lived feature branches. | [Chapter 27, section 27.8](../textbook/ch27-open-source-team-workflows.md) |
| two-factor authentication | GitHub | Required by GitHub since March 2023 for everyone who contributes code on GitHub.com. | [Chapter 16, section 16.15](../textbook/ch16-authentication.md) |

## U

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| unborn branch | Git | The branch HEAD names in a new repository before the first commit: the name exists in HEAD, the ref does not. | [Chapter 7, section 7.3](../textbook/ch07-branches.md) |
| unreachable object | Git | An object that no ref, no reflog entry and the index do not reach. It stays in the object database until a collection deletes it after the grace period. | [Chapter 13, section 13.2](../textbook/ch13-recovery.md) |
| untracked cache | Git | A cache (`core.untrackedCache`) that remembers which directories contained no untracked files. | [Chapter 26, section 26.9](../textbook/ch26-performance.md) |
| untracked file | Git | A path in the working tree that has no index entry and matches no ignore pattern. | [Chapter 4, section 4.3](../textbook/ch04-working-tree.md) |
| upstream (branch) | Git | The branch on a remote that `git status` compares a local branch with and that `git pull` integrates from; two lines of configuration. | [Chapter 12, section 12.5](../textbook/ch12-remote-operations.md) |
| upstream (repository) | GitHub | In the fork workflow, the project's repository from which a fork was made, by convention the remote named `upstream`. | [Chapter 27, section 27.2](../textbook/ch27-open-source-team-workflows.md) |

## V

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| variable (Actions) | Actions | A plain value stored in GitHub settings and read through the `vars` context; unlike a secret it is neither encrypted nor masked. | [Chapter 20A, section 20A.6](../textbook/ch20a-actions-fundamentals.md) |
| version control system | Git | A system that records successive states of a set of files so that you can recall any state, compare any two, and see who recorded each one, when, and why. | [Chapter 1, section 1.2](../textbook/ch01-fundamentals.md) |
| vigilant mode | GitHub | The account setting "Flag unsigned commits as unverified": with it, unsigned commits that name you are marked; without it an unsigned commit gets no badge at all. | [Chapter 21B, section 21B.6](../textbook/ch21b-repository-security-incident-response.md) |
| visibility | GitHub | Who can read a repository at all: public or private; internal repositories need Enterprise Cloud. | [Chapter 15, section 15.5](../textbook/ch15-github.md) |

## W

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| webhook | GitHub | A registration of a URL and events on a repository, an organization or a GitHub App: GitHub sends an HTTP request with a JSON payload when one occurs. | [Chapter 15, section 15.18](../textbook/ch15-github.md) |
| workflow | Actions | A YAML file under `.github/workflows/` that says "when this event happens, run these jobs". | [Chapter 20A, section 20A.2](../textbook/ch20a-actions-fundamentals.md) |
| `workflow_dispatch` | Actions | The event that starts a run by hand, from the web interface or with `gh workflow run`. | [Chapter 20A, section 20A.4](../textbook/ch20a-actions-fundamentals.md) |
| working tree | Git | The directory of ordinary files that you edit, build and run: one checked-out version of the project, plus whatever else is lying in that directory. | [Chapter 4, section 4.2](../textbook/ch04-working-tree.md) |
| worktree | Git | A working tree together with its own HEAD and index; a repository has one main worktree and any number of linked worktrees. A branch can be checked out in at most one. | [Chapter 25, section 25.2](../textbook/ch25-worktrees.md) |

## Z

| Term | Layer | Definition | Taught in |
|---|---|---|---|
| zdiff3 | Git | See conflict style. | — |

## See also

- [Git command reference](git-command-reference.md): every command taught, with the forms, a mistake and the recovery.
- [GitHub reference](github-reference.md): limits, roles, rule types, merge methods, token types, events.
- [Command safety](command-safety.md): every 🟡 and 🔴 command.
- [References](references.md): the sources behind the chapters, including [gitglossary](https://git-scm.com/docs/gitglossary), on your machine as `git help glossary`.
