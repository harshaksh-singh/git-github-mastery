# References

> **Baseline.** Sources as cited on 1 October 2026 for Git 2.55.0 (2.56.0 where a chapter says so) and for GitHub. This file is the "Sources" section of every chapter, collected in the order of the modules. No source was added: every link, date, caveat and video below stands in a chapter, and the chapters took them from the [Phase 0 research report](../reports/Git%20and%20GitHub%20mastery%20research.md), its research notes, the local manual pages, or official pages fetched while the chapter was written.

## How to use this list

- **Primary sources** are the Git manual pages and source, GitHub's documentation and changelog, and the tools' own repositories. When a chapter and a primary source disagree, the primary source for your version wins: on your machine, `git help <command>` is the manual of the Git you run.
- **Secondary sources** are books, blog posts and surveys. Each carries the caveat its chapter gave it (age, sample, vendor interest).
- **Videos** are optional and come only from the tables of the Phase 0 report. The assessments there rest on captions and chapter lists, not on full viewing, and several videos predate `git switch` and `git restore` or assume a branch called `master`; the note beside each video says so.
- **Further reading** points to other chapters and to deeper material.

GitHub-side facts carry dates because the platform changes: before you rely on a limit, a price, a plan gate or a label, open the linked page. The re-verification calendar is section 10 of the [roadmap](../curriculum/Git%20and%20GitHub%20mastery%20roadmap.md).

## Module index

| Modules | Chapters |
|---|---|
| Modules 0 and 1: what Git is, the mental model | [Chapter 1: Fundamentals](../textbook/ch01-fundamentals.md), [Chapter 2: The Mental Model](../textbook/ch02-mental-model.md) |
| Module 2: working tree, index, HEAD | [Chapter 4: The Working Tree](../textbook/ch04-working-tree.md), [Chapter 5: The Index](../textbook/ch05-index.md) |
| Module 3: commits | [Chapter 6: Commits](../textbook/ch06-commits.md) |
| Module 4: refs, branches, HEAD | [Chapter 7: Branches](../textbook/ch07-branches.md) |
| Modules 5, 13 and 24 (local part): configuration, tags and versions, signing | [Chapter 14B: Configuration, Aliases, Tags and Signing](../textbook/ch14b-config-tags-signing.md) |
| Module 6: merge | [Chapter 8: Merge](../textbook/ch08-merge.md) |
| Module 7: remotes | [Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md) |
| Module 8: undo | [Chapter 11: Reset, Revert, Restore](../textbook/ch11-reset-revert-restore.md) |
| Module 9: rebase | [Chapter 9: Rebase](../textbook/ch09-rebase.md) |
| Module 10: cherry-pick and ranges | [Chapter 10: Cherry-pick](../textbook/ch10-cherry-pick.md) |
| Modules 10 (ranges) and 11: history forensics | [Chapter 14A: History investigation](../textbook/ch14a-history-investigation.md) |
| Module 12: recovery | [Chapter 13: Recovery](../textbook/ch13-recovery.md) |
| Module 14: hooks, rerere, attributes, worktrees | [Chapter 14C: Stash Internals, Rerere, Attributes, Hooks](../textbook/ch14c-stash-rerere-attributes-hooks.md), [Chapter 25: Worktrees](../textbook/ch25-worktrees.md) |
| Module 15: submodules, subtrees, LFS | [Chapter 22: Git LFS](../textbook/ch22-git-lfs.md), [Chapter 23: Submodules and Subtrees](../textbook/ch23-submodules.md) |
| Modules 16 and 17: the object database, the index, refs and the Git directory | [Chapter 3: Git Internals](../textbook/ch03-git-internals.md) |
| Modules 16 and 18: maintenance, transfer and scale | [Chapter 26: Performance](../textbook/ch26-performance.md), [Chapter 24: Monorepos](../textbook/ch24-monorepos.md) |
| Modules 19 and 25: the GitHub platform, the CLI and the API | [Chapter 15: GitHub](../textbook/ch15-github.md) |
| Module 20: authentication and SSH | [Chapter 16: Authentication](../textbook/ch16-authentication.md) |
| Modules 21 and 22: pull requests, forks, merge methods, releases | [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md) |
| Module 23: governance | [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md), [Chapter 19: CODEOWNERS](../textbook/ch19-codeowners.md) |
| Module 26: Actions fundamentals | [Chapter 20A: GitHub Actions Fundamentals](../textbook/ch20a-actions-fundamentals.md) |
| Modules 27 and 28: build, package, deliver; runners and debugging CI | [Chapter 20B: GitHub Actions: delivery, runners, cost and debugging](../textbook/ch20b-actions-delivery-debugging.md) |
| Module 29: Actions security | [Chapter 21A: GitHub Actions security](../textbook/ch21a-actions-security.md) |
| Modules 24 (GitHub part), 30 and 31: repository security and secret-leak response | [Chapter 21B: Repository security, identity, the Git client, and secret-leak response](../textbook/ch21b-repository-security-incident-response.md) |
| Modules 32 and 34: branching and release strategy, practices and design review | [Chapter 27: Open source and team workflows](../textbook/ch27-open-source-team-workflows.md) |
| Module 33: AI/ML workflows | [Chapter 28: AI/ML workflows](../textbook/ch28-ai-ml-workflows.md) |
| Module 35: the diagnosis method | [Chapter 29: Production Troubleshooting](../textbook/ch29-production-troubleshooting.md) |
| Modules 36 to 38: incident drills, communication and postmortems | [Chapter 30: Incident Response](../textbook/ch30-incident-response.md) |
| Module 42: the frontier | [Chapter 14D: The Frontier](../textbook/ch14d-frontier.md) |

## Modules 0 and 1: what Git is, the mental model

### Chapter 1: Fundamentals

From section 1.19 of [Chapter 1: Fundamentals](../textbook/ch01-fundamentals.md).

#### Primary sources


- [git(1)](https://git-scm.com/docs/git): description, environment variables, `--no-optional-locks`.
- [gitrepository-layout](https://git-scm.com/docs/gitrepository-layout): every file in `.git`.
- [gitglossary](https://git-scm.com/docs/gitglossary): bare repository, unborn branch, plumbing, porcelain.
- [gitdatamodel](https://git-scm.com/docs/gitdatamodel): the official data model page, on your machine as `git help datamodel`.
- [git-init](https://git-scm.com/docs/git-init), [git-status](https://git-scm.com/docs/git-status), [git-config](https://git-scm.com/docs/git-config), [git-rev-parse](https://git-scm.com/docs/git-rev-parse), [git-ls-files](https://git-scm.com/docs/git-ls-files), [git-rm](https://git-scm.com/docs/git-rm).
- Git source at the v2.55.0 tag: [builtin/rm.c](https://github.com/git/git/blob/v2.55.0/builtin/rm.c), [submodule.c](https://github.com/git/git/blob/v2.55.0/submodule.c) and [builtin/fsck.c](https://github.com/git/git/blob/v2.55.0/builtin/fsck.c), read for the two root-cause notes in sections 1.7 and 1.13.
- Pro Git, second edition: [About Version Control](https://git-scm.com/book/en/v2/Getting-Started-About-Version-Control), [A Short History of Git](https://git-scm.com/book/en/v2/Getting-Started-A-Short-History-of-Git), [What is Git?](https://git-scm.com/book/en/v2/Getting-Started-What-is-Git%3F). The book is hosted on the official site and has been frozen since May 2024, so its command style is older than this chapter's.
- GitHub: [changelog entry on CLI telemetry](https://github.blog/changelog/2026-04-22-github-cli-opt-out-usage-telemetry/), [gh environment variables](https://cli.github.com/manual/gh_help_environment).

#### Secondary sources


- [Phase 0 research report](../reports/Git%20and%20GitHub%20mastery%20research.md), sections 1, 2, 4 and 12: versions, dates, the two Gits, and the Git and GitHub layers, each with a link to its primary source.

#### Videos


The report assessed these from captions and chapter lists, not by full viewing.

- ["Learn Git & GitHub for Beginners (2026) Tutorial"](https://www.youtube.com/watch?v=h2a3Kw-I_Ec), Coder Coder, 56 minutes, 28 June 2026. Current commands, including `git switch` and `git restore`. Beginner scope only.
- ["Git Tutorial for Beginners: Learn Git in One Video"](https://www.youtube.com/watch?v=AB3J8ufDYHQ), CodeWithHarry, Hindi, 2 hours 32 minutes, 12 July 2026. Current commands. It teaches no reset, revert or reflog, uses a local `master`, and first calls a branch a copy before correcting that to a pointer.
- ["Tech Talk: Linus Torvalds on git"](https://www.youtube.com/watch?v=4XpnKHJAok8), 2007, and ["Two decades of Git"](https://www.youtube.com/watch?v=sCr_gb8rdEI), 2025. Design intent and history. Polemical; his 2025 remark that the SHA-256 work was needless churn is his opinion, not the project's position.

#### Further reading


- [gittutorial](https://git-scm.com/docs/gittutorial) and [giteveryday](https://git-scm.com/docs/giteveryday), also available as `git help tutorial` and `git help everyday`.
- [The Git User's Manual](https://git-scm.com/docs/user-manual).

### Chapter 2: The Mental Model

From section 2.19 of [Chapter 2: The Mental Model](../textbook/ch02-mental-model.md).

#### Primary sources


- [gitdatamodel](https://git-scm.com/docs/gitdatamodel): objects, refs, the index and reflogs; on your machine as `git help datamodel`.
- [gitglossary](https://git-scm.com/docs/gitglossary): DAG, reachable, dangling object, HEAD, ref, symref.
- [gitrevisions](https://git-scm.com/docs/gitrevisions): `<rev>^{tree}`, `<rev>:<path>`, `:<path>`, and the lookup order of a short ref name.
- Manual pages: [git-hash-object](https://git-scm.com/docs/git-hash-object), [git-update-index](https://git-scm.com/docs/git-update-index), [git-write-tree](https://git-scm.com/docs/git-write-tree), [git-commit-tree](https://git-scm.com/docs/git-commit-tree), [git-update-ref](https://git-scm.com/docs/git-update-ref), [git-cat-file](https://git-scm.com/docs/git-cat-file), [git-ls-tree](https://git-scm.com/docs/git-ls-tree), [git-fsck](https://git-scm.com/docs/git-fsck), [git-patch-id](https://git-scm.com/docs/git-patch-id), [git-cherry-pick](https://git-scm.com/docs/git-cherry-pick).
- Git source at the v2.55.0 tag: [refs.c](https://github.com/git/git/blob/v2.55.0/refs.c), read for the root-cause box in section 2.13.
- Pro Git, second edition, chapter 10: [Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects), [Git References](https://git-scm.com/book/en/v2/Git-Internals-Git-References). Frozen since May 2024; the object model is current, the commands use `master` and `git checkout`.
- GitHub Docs: [pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests), [removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository).

#### Secondary sources


- [Phase 0 research report](../reports/Git%20and%20GitHub%20mastery%20research.md): section 12 for the misconceptions, sections 1 and 4 for versions.
- Julia Evans: [how cherry-pick and revert work](https://jvns.ca/blog/2023/11/10/how-cherry-pick-and-revert-work/), [branches: intuition and reality](https://jvns.ca/blog/2023/11/23/branches-intuition-reality/), [confusing Git terminology](https://jvns.ca/blog/2023/11/01/confusing-git-terminology/), [poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/). The polls are self-selected samples: direction, not population figures.

#### Videos


The report assessed these from caption searches, chapter lists and descriptions, not by full viewing.

- ["Lecture 5: Version Control and Git"](https://www.youtube.com/watch?v=9K8lB61dl3Y), MIT Missing Semester 2026, 1 hour 10 minutes, 19 February 2026, with [notes and exercises](https://missing.csail.mit.edu/2026/version-control/). The data model before the commands. SHA-1 only; the demo starts on `master`; nothing on GitHub.
- ["Git Internals by John Britton of GitHub - CS50 Tech Talk"](https://www.youtube.com/watch?v=lG90LZotrpo), 58 minutes, 11 April 2018. Blobs, trees, commits, hashing, refs as files. Correct and clear; `master`, `git checkout`, SHA-1 only.
- ["Complete git and Github course in Hindi"](https://www.youtube.com/watch?v=q8EevlEpQ2A), Chai aur Code, Hindi, 2 hours 55 minutes, 8 June 2024, from 55:16. Commit, tree and blob by name; HEAD as a pointer to the current branch. Local `master`; no revert, restore or cherry-pick.

#### Further reading


- [gitcore-tutorial](https://git-scm.com/docs/gitcore-tutorial), the Git project's own walk through the plumbing, and [The Git User's Manual](https://git-scm.com/docs/user-manual).


## Module 2: working tree, index, HEAD

### Chapter 4: The Working Tree

From section 4.21 of [Chapter 4: The Working Tree](../textbook/ch04-working-tree.md).

#### Primary sources


- [git-status](https://git-scm.com/docs/git-status), [gitignore](https://git-scm.com/docs/gitignore), [git-check-ignore](https://git-scm.com/docs/git-check-ignore), [git-restore](https://git-scm.com/docs/git-restore), [git-rm](https://git-scm.com/docs/git-rm), [git-mv](https://git-scm.com/docs/git-mv), [git-clean](https://git-scm.com/docs/git-clean), [git-ls-files](https://git-scm.com/docs/git-ls-files), [git-checkout](https://git-scm.com/docs/git-checkout), [git-diff](https://git-scm.com/docs/git-diff), [git-config](https://git-scm.com/docs/git-config). The local copies (`git help -m <command>`) are the Git 2.55.0 text that the transcripts were checked against.
- [gitfaq](https://git-scm.com/docs/gitfaq): "I asked Git to ignore various files, yet they are still tracked" and "Why do I have a file that's always modified?".
- [gitglossary](https://git-scm.com/docs/gitglossary) and [gitattributes](https://git-scm.com/docs/gitattributes).
- [Git User's Manual](https://github.com/git/git/blob/v2.56.0/Documentation/user-manual.adoc): renames are not recorded; only the executable bit is.
- Release notes: [2.23.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.23.0.adoc), [2.51.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc), and 1.8.2 and 1.8.5 as shipped with Git 2.55.0 (`Documentation/RelNotes/` in the Git source tree).

#### Secondary sources


- Pro Git, [Recording Changes to the Repository](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository). Caveat: its status transcripts mix the current `git restore --staged` hint with the older `git reset HEAD <file>` hint.
- GitHub Docs, [Ignoring files](https://docs.github.com/en/get-started/git-basics/ignoring-files), and the [github/gitignore](https://github.com/github/gitignore) template collection.
- GitHub Docs, [Removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository), for what a committed secret requires beyond `git rm --cached`.
- Perez De Rosso and Jackson, [Purposes, Concepts, Misfits, and a Redesign of Git](https://spderosso.github.io/oopsla16.pdf) (OOPSLA 2016): file tracking, untracking a file, file rename and empty directory are four of its seven "operational misfits".
- The Phase 0 report of this course, sections 4, 12 and 15, for the Stack Overflow figures and the ML ignore list.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- [Git Tutorial for Beginners: Learn Git in One Video](https://www.youtube.com/watch?v=AB3J8ufDYHQ), CodeWithHarry, Hindi, 12 July 2026: covers staging, ignoring files and tracking empty directories with `git restore --staged`. Caveats from the report: no reset, revert or reflog; local `master`; an early "branch is a copy" phrase that the video corrects later.
- [How to Undo Mistakes With Git Using the Command Line](https://www.youtube.com/watch?v=lX9hsdsAeTk), Tobias Günther for freeCodeCamp, 24 November 2020: `git restore`, including `-p`. Caveat: `master` naming.

#### Further reading


- [git-update-index](https://git-scm.com/docs/git-update-index), section "Untracked cache", and the "Untracked files and performance" section of git-status, for why status is slow in very large working trees. Chapter 26 (Performance) continues from there.

### Chapter 5: The Index

From section 5.22 of [Chapter 5: The Index](../textbook/ch05-index.md).

#### Primary sources


- [git-add](https://git-scm.com/docs/git-add), [git-diff](https://git-scm.com/docs/git-diff), [git-commit](https://git-scm.com/docs/git-commit), [git-restore](https://git-scm.com/docs/git-restore), [git-reset](https://git-scm.com/docs/git-reset), [git-rm](https://git-scm.com/docs/git-rm), [git-ls-files](https://git-scm.com/docs/git-ls-files), [git-update-index](https://git-scm.com/docs/git-update-index), [git-checkout-index](https://git-scm.com/docs/git-checkout-index), [git-write-tree](https://git-scm.com/docs/git-write-tree), [git-diff-files](https://git-scm.com/docs/git-diff-files), [git-status](https://git-scm.com/docs/git-status). The local copies (`git help -m <command>`) are the Git 2.55.0 text used for the transcripts.
- [gitdatamodel](https://git-scm.com/docs/gitdatamodel), [gitformat-index](https://git-scm.com/docs/gitformat-index), [gitrevisions](https://git-scm.com/docs/gitrevisions) and [gitfaq](https://git-scm.com/docs/gitfaq) ("How do I ignore changes to a tracked file?").
- [racy-git](https://github.com/git/git/blob/v2.56.0/Documentation/technical/racy-git.adoc): the cached stat data and its one known weakness. [lockfile.h](https://github.com/git/git/blob/v2.56.0/lockfile.h): the lock-file protocol.
- Release notes [2.0.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.0.0.adoc), [1.6.1](https://github.com/git/git/blob/master/Documentation/RelNotes/1.6.1.adoc), [2.11.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.11.0.adoc), [2.19.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.19.0.adoc); 1.5.4 and 2.38.0 as shipped with Git 2.55.0.

#### Secondary sources


- Pro Git, [Interactive Staging](https://git-scm.com/book/en/v2/Git-Tools-Interactive-Staging). Caveat: its prompt and its `git stash save --patch` come from an older Git.
- Pro Git, [Reset Demystified](https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified): the three trees, with the index as "your proposed next commit". Caveat: it says "working directory" for the working tree.
- The Phase 0 report of this course, sections 11 and 12: the Stack Overflow figure and the survey of ten beginner resources (outline-based; transcripts were not reviewed).

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- [Lecture 5: Version Control and Git](https://www.youtube.com/watch?v=9K8lB61dl3Y), MIT Missing Semester 2026: the staging area as part of the data model; the [notes](https://missing.csail.mit.edu/2026/version-control/) list `add -p`. Caveats: describes object IDs as SHA-1 only; the demo starts on `master`.
- [Git for Professionals](https://www.youtube.com/watch?v=Uszj_k0DGsg), Tobias Günther for freeCodeCamp, September 2021: commit craft with `git add -p`. Caveat: 2021 interface.

#### Further reading


- [git-sparse-checkout](https://git-scm.com/docs/git-sparse-checkout), the feature that the skip-worktree bit was built for.


## Module 3: commits

### Chapter 6: Commits

From section 6.19 of [Chapter 6: Commits](../textbook/ch06-commits.md).

#### Primary sources


- [git-commit](https://git-scm.com/docs/git-commit), [git-show](https://git-scm.com/docs/git-show), [git-log](https://git-scm.com/docs/git-log), [git-cat-file](https://git-scm.com/docs/git-cat-file), [git-commit-tree](https://git-scm.com/docs/git-commit-tree), [git-interpret-trailers](https://git-scm.com/docs/git-interpret-trailers), [git-shortlog](https://git-scm.com/docs/git-shortlog), [git-var](https://git-scm.com/docs/git-var), [git-am](https://git-scm.com/docs/git-am), [git-gc](https://git-scm.com/docs/git-gc), [githooks](https://git-scm.com/docs/githooks). The local copies (`git help -m <command>`) are the Git 2.55.0 text that the transcripts were checked against.
- [gitdatamodel](https://git-scm.com/docs/gitdatamodel), [gitrevisions](https://git-scm.com/docs/gitrevisions), [gitformat-signature](https://git-scm.com/docs/gitformat-signature).
- The Git project's [SubmittingPatches](https://github.com/git/git/blob/v2.56.0/Documentation/SubmittingPatches): separate commits, the message, sign-off and trailers. [trailer.c at 2.55.0](https://github.com/git/git/blob/v2.55.0/trailer.c) for the trailers Git generates.
- Release notes [2.29](https://github.com/git/git/blob/master/Documentation/RelNotes/2.29.0.adoc), [2.32](https://github.com/git/git/blob/master/Documentation/RelNotes/2.32.0.adoc) and [2.56](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).
- GitHub Docs: [troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits), [creating a commit with multiple authors](https://docs.github.com/en/pull-requests/how-tos/commit-changes/creating-a-commit-with-multiple-authors), [setting your commit email address](https://docs.github.com/en/account-and-profile/how-tos/email-preferences/setting-your-commit-email-address), [about commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification).

#### Secondary sources


- Pro Git, [Git Internals: Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects) and the commit guidelines in [Contributing to a Project](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project). Caveat: both use `master`.
- Chris Beams, [How to Write a Git Commit Message](https://cbea.ms/git-commit/) (2014): the widely quoted seven rules.
- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/), a title convention whose footers follow the trailer format.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- [Lecture 5: Version Control and Git](https://www.youtube.com/watch?v=9K8lB61dl3Y), MIT Missing Semester 2026: snapshots, history as a graph, content-addressed objects. Caveats: describes object IDs as SHA-1 only; the demo starts on `master`.
- [RubyConf 2018 - Branch in Time](https://www.youtube.com/watch?v=8OOTVxKDwe0), Tekin Süleyman: why history quality matters, told as one story. Nothing in it depends on a Git version.
- [How to Undo Mistakes With Git Using the Command Line](https://www.youtube.com/watch?v=lX9hsdsAeTk), Tobias Günther for freeCodeCamp, 2020: includes amend. Caveat: `master` naming.

#### Further reading


- [Chapter 9](../textbook/ch09-rebase.md), section 9.3, and [Chapter 10](../textbook/ch10-cherry-pick.md), section 10.3: the "new object, new ID" rule applied to rebase and cherry-pick.


## Module 4: refs, branches, HEAD

### Chapter 7: Branches

From section 7.20 of [Chapter 7: Branches](../textbook/ch07-branches.md).

#### Primary sources


- [git-branch](https://git-scm.com/docs/git-branch), [git-switch](https://git-scm.com/docs/git-switch), [git-checkout](https://git-scm.com/docs/git-checkout) ("Detached HEAD"), [git-symbolic-ref](https://git-scm.com/docs/git-symbolic-ref), [git-update-ref](https://git-scm.com/docs/git-update-ref), [git-for-each-ref](https://git-scm.com/docs/git-for-each-ref), [git-rev-parse](https://git-scm.com/docs/git-rev-parse), [git-merge-base](https://git-scm.com/docs/git-merge-base), [git-rev-list](https://git-scm.com/docs/git-rev-list), [git-tag](https://git-scm.com/docs/git-tag), [git-check-ref-format](https://git-scm.com/docs/git-check-ref-format), [git-pack-refs](https://git-scm.com/docs/git-pack-refs), [git-merge-tree](https://git-scm.com/docs/git-merge-tree), [git-fetch](https://git-scm.com/docs/git-fetch), [git-clone](https://git-scm.com/docs/git-clone), [git-worktree](https://git-scm.com/docs/git-worktree), [git-submodule](https://git-scm.com/docs/git-submodule), [git-config](https://git-scm.com/docs/git-config). The local copies (`git help -m <command>`) are the Git 2.55.0 text that the transcripts were checked against.
- [gitrevisions](https://git-scm.com/docs/gitrevisions), [gitglossary](https://git-scm.com/docs/gitglossary), [gitdatamodel](https://git-scm.com/docs/gitdatamodel).
- Git source at 2.55.0, [wt-status.c](https://github.com/git/git/blob/v2.55.0/wt-status.c), for how `git status` chooses "detached at", "detached from" and "Not currently on any branch".
- [git-branch at 2.56.0](https://github.com/git/git/blob/v2.56.0/Documentation/git-branch.adoc) and release notes [2.22](https://github.com/git/git/blob/master/Documentation/RelNotes/2.22.0.adoc), [2.23](https://github.com/git/git/blob/master/Documentation/RelNotes/2.23.0.adoc), [2.47](https://github.com/git/git/blob/master/Documentation/RelNotes/2.47.0.adoc), [2.51](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc), [2.55](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc), [2.56](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).
- GitHub Docs: [pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests), [events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows).

#### Secondary sources


- Pro Git, [Branches in a Nutshell](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell) and [Git References](https://git-scm.com/book/en/v2/Git-Internals-Git-References). Caveats: `master` throughout, and branch switching with `git checkout`.
- Julia Evans, [git branches: intuition & reality](https://jvns.ca/blog/2023/11/23/branches-intuition-reality/) and [how HEAD works in git](https://jvns.ca/blog/2024/03/08/how-head-works-in-git/); the [2024 poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/) quoted in section 7.1.
- The Phase 0 report of this course, sections 1 and 12, for the reftable rationale and the misconception table.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- [Git Internals by John Britton of GitHub - CS50 Tech Talk](https://www.youtube.com/watch?v=lG90LZotrpo), 2018: refs as files holding an ID, branches as pointers. Caveats: `master` and `checkout`; SHA-1 only.
- [Git For Beginners](https://www.youtube.com/watch?v=vwj89i2FmG0), Telusko, 2023: asks whether a branch copies the project and explains why it does not. Caveat: no undo or rebase.
- [Intern DELETED a Git Branch!](https://www.youtube.com/watch?v=jXoOEfpgzF4), Chai aur Code, Hindi, 2026: recovering a deleted branch through the reflog. Caveat: a single scenario.

> **Outdated advice.** Several popular tutorials introduce a branch as a copy of the project and HEAD as the latest commit; the report lists [Apna College's 2023 tutorial](https://www.youtube.com/watch?v=Ez8F0nW6S-w) among them. Both statements fail the transcripts of sections 7.2 and 7.3.

#### Further reading


- [Chapter 8](../textbook/ch08-merge.md), section 8.2, for merge bases with more than one candidate; [Chapter 12](../textbook/ch12-remote-operations.md) for everything about `origin/`; [Chapter 13](../textbook/ch13-recovery.md) for the reflog as a recovery tool.


## Modules 5, 13 and 24 (local part): configuration, tags and versions, signing

### Chapter 14B: Configuration, Aliases, Tags and Signing

From section 14B.25 of [Chapter 14B: Configuration, Aliases, Tags and Signing](../textbook/ch14b-config-tags-signing.md).

#### Primary sources


- [git-config](https://git-scm.com/docs/git-config), [git](https://git-scm.com/docs/git), [git-var](https://git-scm.com/docs/git-var), [gitcredentials](https://git-scm.com/docs/gitcredentials). The local copies (`git help -m <command>`) are the Git 2.55.0 text the transcripts were checked against.
- [git-tag](https://git-scm.com/docs/git-tag) (including "On Re-tagging"), [git-describe](https://git-scm.com/docs/git-describe), [git-for-each-ref](https://git-scm.com/docs/git-for-each-ref), [git-check-ref-format](https://git-scm.com/docs/git-check-ref-format), [git-push](https://git-scm.com/docs/git-push), [git-fetch](https://git-scm.com/docs/git-fetch), [gitworkflows](https://git-scm.com/docs/gitworkflows), [githooks](https://git-scm.com/docs/githooks).
- [gitformat-signature](https://git-scm.com/docs/gitformat-signature), [git-verify-commit](https://git-scm.com/docs/git-verify-commit), [git-verify-tag](https://git-scm.com/docs/git-verify-tag), [git-log](https://git-scm.com/docs/git-log) (pretty formats), [git-merge](https://git-scm.com/docs/git-merge), the [gpg configuration reference](https://github.com/git/git/blob/v2.56.0/Documentation/config/gpg.adoc), and [ssh-keygen(1)](https://man.openbsd.org/ssh-keygen), "ALLOWED SIGNERS".
- Git source at 2.55.0, read for behavior the manual does not state: [receive-pack.c](https://github.com/git/git/blob/v2.55.0/builtin/receive-pack.c) (the `receive.deny*` settings apply to `refs/heads/` only), [http.c](https://github.com/git/git/blob/v2.55.0/http.c) (`GIT_CURL_VERBOSE`), [editor.c](https://github.com/git/git/blob/v2.55.0/editor.c) (`VISUAL` and dumb terminals).
- Release notes [2.34](https://github.com/git/git/blob/master/Documentation/RelNotes/2.34.0.adoc), [2.45](https://github.com/git/git/blob/master/Documentation/RelNotes/2.45.0.adoc), [2.46](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc), [2.49](https://github.com/git/git/blob/master/Documentation/RelNotes/2.49.0.adoc), [2.54](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc), [2.56](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).
- [Semantic Versioning 2.0.0](https://semver.org/).
- GitHub Docs: [about commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification), [telling Git about your signing key](https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key), [about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases), [associating text editors with Git](https://docs.github.com/en/get-started/git-basics/associating-text-editors-with-git).

#### Secondary sources


- Pro Git: [Git Configuration](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration), [Git Aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases), [Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging), [Signing Your Work](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work), [Environment Variables](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables). Caveats: legacy `git config` syntax, GPG only, `master`.
- Julia Evans, [Popular git config options](https://jvns.ca/blog/2024/02/16/popular-git-config-options/) (2024): a crowd-sourced list that overlaps the table in section 14B.5.
- Taylor Blau, [Highlights from Git 2.34](https://github.blog/open-source/git/highlights-from-git-2-34/): the introduction of SSH signing.
- Russ Cox, [the xz attack timeline](https://research.swtch.com/xz-timeline); Gruntwork, [How to spoof any user on GitHub](https://www.gruntwork.io/blog/how-to-spoof-any-user-on-github-and-what-to-do-to-prevent-it).

#### Videos

(optional; assessments in the Phase 0 report rest on captions and chapter lists, not on full viewing)


- [So You Think You Know Git - FOSDEM 2024](https://www.youtube.com/watch?v=aolI_Rz0ZqY), Scott Chacon, 47 minutes: `includeIf` at 08:23, SSH signing and the "Verified" badge from 19:00. Caveats: a survey, not a deep dive; about one minute of product pitch.
- [Simplify signing Git commits and tags with SSH keys](https://www.youtube.com/watch?v=uhy_ojFqLg0), Andy Feller, Git Merge 2022 workshop, 56 minutes. Caveat: assessed from automatic captions and the description.
- [Tag, You're Leaked: Surviving the tj-actions Supply Chain Attack](https://www.youtube.com/watch?v=FxHIaRwc9c4), BSides PDX 2025, 24 minutes: what a moved tag costs at scale.

#### Further reading


- The "DISCUSSION" section of git-tag(1): three short essays on re-tagging, tag following and backdating.


## Module 6: merge

### Chapter 8: Merge

From section 8.25 of [Chapter 8: Merge](../textbook/ch08-merge.md).

#### Primary sources


- [git-merge](https://git-scm.com/docs/git-merge), [git-merge-base](https://git-scm.com/docs/git-merge-base), [git-merge-tree](https://git-scm.com/docs/git-merge-tree), [git-merge-file](https://git-scm.com/docs/git-merge-file), [git-read-tree](https://git-scm.com/docs/git-read-tree), [gitrevisions](https://git-scm.com/docs/gitrevisions), [git-status](https://git-scm.com/docs/git-status), [git-restore](https://git-scm.com/docs/git-restore), [git-checkout](https://git-scm.com/docs/git-checkout), [git-log](https://git-scm.com/docs/git-log), [git-diff](https://git-scm.com/docs/git-diff), [git-revert](https://git-scm.com/docs/git-revert), [git-rerere](https://git-scm.com/docs/git-rerere), [gitattributes](https://git-scm.com/docs/gitattributes), [gitglossary](https://git-scm.com/docs/gitglossary), [gitfaq](https://git-scm.com/docs/gitfaq). The local copies (`git help -m <command>`) are the Git 2.55.0 text that every quotation and transcript was checked against.
- Git source and documentation at fixed tags: [merge strategies](https://github.com/git/git/blob/v2.56.0/Documentation/merge-strategies.adoc), [merge configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/merge.adoc), [git-add at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/git-add.adoc), [builtin/merge.c at 2.55](https://github.com/git/git/blob/v2.55.0/builtin/merge.c).
- Release notes: [2.34](https://github.com/git/git/blob/master/Documentation/RelNotes/2.34.0.adoc), [2.35](https://github.com/git/git/blob/master/Documentation/RelNotes/2.35.0.adoc), [2.36](https://github.com/git/git/blob/master/Documentation/RelNotes/2.36.0.adoc), [2.38](https://github.com/git/git/blob/master/Documentation/RelNotes/2.38.0.adoc), [2.50](https://github.com/git/git/blob/master/Documentation/RelNotes/2.50.0.adoc), [2.56](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).
- GitHub: [Pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges), [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request), [changelog of 12 September 2022](https://github.blog/changelog/2022-09-12-merge-commits-now-created-using-the-merge-ort-strategy/), [Scaling merge-ort across GitHub](https://github.blog/engineering/infrastructure/scaling-merge-ort-across-github/) (27 July 2023).

#### Secondary sources


- Pro Git, [Basic Branching and Merging](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging) and [Advanced Merging](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging). Caveat: see the "Outdated advice" note in section 8.22.
- Julia Evans, [Git poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/) (2024). Self-selected samples.
- [nbdime](https://nbdime.readthedocs.io/en/latest/) documentation, for notebook diffs and merges.
- The Phase 0 report of this course, sections 1, 4, 12 and 13.

#### Videos

(optional; the assessments in the Phase 0 report rest on captions and chapter lists, not on full viewing)


- David Mahler, ["Branching and Merging"](https://www.youtube.com/watch?v=FyAAIHHClqI) (29 min, 2017). Fast-forward against three-way merges drawn on the commit graph. Conceptually excellent; uses `master` and the commands that predate `git restore`.
- ThePrimeagen for Boot.dev, ["Git and GitHub - Full Course"](https://www.youtube.com/watch?v=rH3zE7VlIMs) (2024): merge from 1:03:27, merge conflicts from 2:41:25. Current commands; a digressive commentary style.
- Elijah Newren, the author of `ort`, at Git Merge [2022](https://www.youtube.com/watch?v=omGgXdXCt_8) and [2025](https://www.youtube.com/watch?v=0JSsxRcs-aE): the merge backend and `--remerge-diff`. Contributor level; watch after this chapter.

#### Further reading


- [Chapter 9](../textbook/ch09-rebase.md) for the other way to integrate, [Chapter 11](../textbook/ch11-reset-revert-restore.md) for undoing merges, Chapter 14C for rerere and merge drivers, Chapter 17 for merge methods on GitHub.


## Module 7: remotes

### Chapter 12: Remote Operations

From section 12.21 of [Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md).

#### Primary sources


- [git-clone](https://git-scm.com/docs/git-clone), [git-fetch](https://git-scm.com/docs/git-fetch), [git-pull](https://git-scm.com/docs/git-pull), [git-push](https://git-scm.com/docs/git-push), [git-remote](https://git-scm.com/docs/git-remote), [git-ls-remote](https://git-scm.com/docs/git-ls-remote), [git-branch](https://git-scm.com/docs/git-branch), [git-merge-base](https://git-scm.com/docs/git-merge-base) (fork point), [git-receive-pack](https://git-scm.com/docs/git-receive-pack), [git-bundle](https://git-scm.com/docs/git-bundle), [git-url-parse](https://git-scm.com/docs/git-url-parse), [gitrevisions](https://git-scm.com/docs/gitrevisions), [gitglossary](https://git-scm.com/docs/gitglossary), [gitdatamodel](https://git-scm.com/docs/gitdatamodel). The local copies (`git help -m <command>`) are the Git 2.55.0 text that every flag in this chapter was checked against.
- [gitprotocol-v2](https://git-scm.com/docs/gitprotocol-v2) and [gitprotocol-pack](https://git-scm.com/docs/gitprotocol-pack): the fetch and push conversations of section 12.13, including "wants can be anything".
- Configuration reference at 2.56: [push](https://github.com/git/git/blob/v2.56.0/Documentation/config/push.adoc), [pull](https://github.com/git/git/blob/v2.56.0/Documentation/config/pull.adoc), [fetch](https://github.com/git/git/blob/v2.56.0/Documentation/config/fetch.adoc), [core](https://github.com/git/git/blob/v2.56.0/Documentation/config/core.adoc).
- Release notes: [1.8.3](https://github.com/git/git/blob/master/Documentation/RelNotes/1.8.3.adoc), [1.8.4](https://github.com/git/git/blob/master/Documentation/RelNotes/1.8.4.adoc), [1.8.5](https://github.com/git/git/blob/master/Documentation/RelNotes/1.8.5.adoc), [2.0.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.0.0.adoc), [2.4.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.4.0.adoc), [2.5.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.5.0.adoc), [2.20.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.20.0.adoc), [2.26.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.26.0.adoc), [2.29.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.29.0.adoc), [2.34.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.34.0.adoc), [2.48.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.48.0.adoc), [2.54.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc), [2.55.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc). Homebrew installs the same files under `share/doc/git-doc/RelNotes/`.

#### Secondary sources


- Pro Git: [Working with Remotes](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes), [Remote Branches](https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches), [The Refspec](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec), [Transfer Protocols](https://git-scm.com/book/en/v2/Git-Internals-Transfer-Protocols). Caveats: `master` and `git checkout` throughout; the first still says that `git pull` only warns when `pull.rebase` is unset, which was true from 2.27 to 2.33.0; the last does not mention protocol version 2.
- GitHub Docs: [About remote repositories](https://docs.github.com/en/get-started/git-basics/about-remote-repositories), [Forks](https://docs.github.com/en/pull-requests/reference/forks), [Syncing a fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork), [Checking out pull requests locally](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/checking-out-pull-requests-locally), [Renaming a branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/renaming-a-branch), [Troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone).
- Julia Evans, [Confusing git terminology](https://jvns.ca/blog/2023/11/01/confusing-git-terminology/), cited by the Phase 0 report for what "Your branch is up to date with 'origin/main'" does and does not say.
- The Phase 0 report of this course, sections 1, 4, 12 and 13, for the dated defaults, the misconception table and the force-push safety facts.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- [Introduction to Git - Remotes](https://www.youtube.com/watch?v=Gg4bLk8cGNo), David Mahler, 31 minutes, 27 March 2018: clone, fetch versus pull and tracking branches drawn on the commit graph. Caveat: `master` throughout.
- [Git and GitHub - Full Course](https://www.youtube.com/watch?v=rH3zE7VlIMs), ThePrimeagen for Boot.dev, 12 November 2024: the chapter on remotes and GitHub starts at 1:54:18, followed by forks. Caveat: digressive style.
- [Complete Git and GitHub Tutorial](https://www.youtube.com/watch?v=apGV9Kg7ics), Kunal Kushwaha, 1 August 2021: fork, upstream remote, keeping a fork in sync. Caveats from the report: recorded days before password removal, uses a plain force push, mixes `master` and `main`, and could not be transcript-audited.

#### Further reading


- [gitprotocol-http](https://git-scm.com/docs/gitprotocol-http), for what "smart HTTP" does with the conversation of section 12.13.
- [git-maintenance](https://github.com/git/git/blob/v2.56.0/Documentation/git-maintenance.adoc), task `prefetch`: Git's own scheduled fetch writes to `refs/prefetch/` so that it does not move remote-tracking branches, and therefore does not renew a lease.
- Chapter 13 (Recovery) for reflogs and `git fsck`, Chapter 26 (Performance) for shallow and partial clones and bundle URIs, and Chapter 30 (Incident response) for the force-push drill.


## Module 8: undo

### Chapter 11: Reset, Revert, Restore

From section 11.20 of [Chapter 11: Reset, Revert, Restore](../textbook/ch11-reset-revert-restore.md).

#### Primary sources


- [git-reset](https://git-scm.com/docs/git-reset) (with the tables in its "Discussion" section), [git-revert](https://git-scm.com/docs/git-revert), [git-restore](https://git-scm.com/docs/git-restore), [git-clean](https://git-scm.com/docs/git-clean), [git-stash](https://git-scm.com/docs/git-stash), [git-commit](https://git-scm.com/docs/git-commit), [git-rebase](https://git-scm.com/docs/git-rebase), [git-fsck](https://git-scm.com/docs/git-fsck), [git-config](https://git-scm.com/docs/git-config), [gitrevisions](https://git-scm.com/docs/gitrevisions) and [git(1)](https://git-scm.com/docs/git). The transcripts were checked against the local Git 2.55.0 copies (`git help -m <command>`).
- [How to revert a faulty merge](https://github.com/git/git/blob/v2.56.0/Documentation/howto/revert-a-faulty-merge.adoc), the how-to that the revert manual points to.
- [gitfaq](https://git-scm.com/docs/gitfaq), the entries on undoing a change that is already in the main branch and on a change reverted on one of two branches.
- Release notes [2.23.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.23.0.adoc), [2.35.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.35.0.adoc), [2.43.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.43.0.adoc), [2.51.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc), and 1.7.1 as shipped with Git 2.55.0 (directory `RelNotes` under the path that `git --html-path` prints).
- GitHub Docs: [Reverting a pull request](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/reverting-a-pull-request) and [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#block-force-pushes); GitHub CLI manual, [gh pr revert](https://cli.github.com/manual/gh_pr_revert).

#### Secondary sources


- Julia Evans, [How git cherry-pick and revert use 3-way merge](https://jvns.ca/blog/2023/11/10/how-cherry-pick-and-revert-work/).
- Pro Git, [Reset Demystified](https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified). Caveat: it contrasts `reset` with `git checkout` and does not mention `git restore`.
- Pro Git, [Undoing Things](https://git-scm.com/book/en/v2/Git-Basics-Undoing-Things) (old and new spellings side by side) and [Stashing and Cleaning](https://git-scm.com/book/en/v2/Git-Tools-Stashing-and-Cleaning). Caveat: the stash chapter mostly uses bare `git stash` and does not cover `--staged`.
- The Phase 0 report of this course, sections 4, 12 and 13, for the Stack Overflow figures and the retention defaults.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- [How to Undo Mistakes With Git Using the Command Line](https://www.youtube.com/watch?v=lX9hsdsAeTk), Tobias Günther for freeCodeCamp, 55 minutes, 24 November 2020: `git restore` including `-p`, amend, revert, reset, reflog recovery from 24:02. Caveat: `master` naming.
- [Revert and Reset Commits Like a Pro](https://www.youtube.com/watch?v=qF8CHHnWqXE), ProCodrr episode 6, Hindi, 56 minutes, March 2023: reset versus revert, with reflog recovery of a hard-reset commit. Caveat: `master`.

#### Further reading


- [Oh Shit, Git!?!](https://ohshitgit.com/), a short scenario list. Caveat: it uses the `checkout` and `reset` spellings.


## Module 9: rebase

### Chapter 9: Rebase

From section 9.27 of [Chapter 9: Rebase](../textbook/ch09-rebase.md).

#### Primary sources


- [git-rebase](https://git-scm.com/docs/git-rebase), including its sections "Behavioral differences", "Recovering from upstream rebase" and "Rebasing merges"; [git-range-diff](https://git-scm.com/docs/git-range-diff); [git-push](https://git-scm.com/docs/git-push); [git-pull](https://git-scm.com/docs/git-pull); [git-commit](https://git-scm.com/docs/git-commit) for `--fixup` and `--squash`; [git-cherry](https://git-scm.com/docs/git-cherry); [git-patch-id](https://git-scm.com/docs/git-patch-id); [gitrevisions](https://git-scm.com/docs/gitrevisions) for `ORIG_HEAD` and `REBASE_HEAD`; [gitglossary](https://git-scm.com/docs/gitglossary); [githooks](https://git-scm.com/docs/githooks). The local copies (`git help -m <command>`) are the Git 2.55.0 text that the transcripts were checked against.
- [git-replay](https://git-scm.com/docs/git-replay) and [git-history](https://git-scm.com/docs/git-history); the pages on git-scm.com describe 2.56.
- Release notes: [2.26.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.26.0.adoc), [2.34.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.34.0.adoc), [2.38.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.38.0.adoc), [2.44.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.44.0.adoc), [2.46.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc), [2.54.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc).
- GitHub Docs: [about merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github), [pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges), [available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).

#### Secondary sources


- Pro Git, [Rebasing](https://git-scm.com/book/en/v2/Git-Branching-Rebasing) and [Rewriting History](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History). Caveats: `master` throughout, and `git checkout` in the first; neither mentions `--update-refs`, `--force-with-lease` or `git range-diff`; the second still demonstrates `git filter-branch`, with a warning.
- Julia Evans, [git rebase: what can go wrong?](https://jvns.ca/blog/2023/11/06/rebasing-what-can-go-wrong-/), [Confusing git terminology](https://jvns.ca/blog/2023/11/01/confusing-git-terminology/) and [Some Git poll results](https://jvns.ca/blog/2024/03/28/git-poll-results/). The polls are self-selected samples.
- [git rebase in depth](https://git-rebase.io/), a sandbox walkthrough. Its author and year could not be confirmed from the page, and it does not cover `exec`.
- The Phase 0 report of this course, sections 1, 4, 12 and 13.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- Philomatics, ["git rebase - Why, When & How to fix conflicts"](https://www.youtube.com/watch?v=DkWDHzmMvyg), 10 minutes, June 2024. Current; short and opinionated.
- Tobias Günther for freeCodeCamp, ["Advanced Git Tutorial"](https://www.youtube.com/watch?v=qsTthZi23VE), 34 minutes, November 2021. Interactive rebase and cherry-pick; mixes `master` and `main` and uses some `checkout`.
- Scott Chacon, ["So You Think You Know Git Part 2"](https://www.youtube.com/watch?v=Md44rcw13k4), 23 minutes, March 2024. Fixup commits and `--update-refs` for stacked branches.
- Colt Steele, ["Git Rebase Vs. Merge"](https://www.youtube.com/watch?v=7Mh259hfxJg), 20 minutes, March 2021. Uses `git switch`; `master` naming.

#### Further reading


- [Chapter 10](../textbook/ch10-cherry-pick.md) for the single replay that a rebase repeats; [Chapter 12](../textbook/ch12-remote-operations.md) for push and pull; [Chapter 13](../textbook/ch13-recovery.md) for reflogs and retention; [Chapter 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md) for rerere.


## Module 10: cherry-pick and ranges

### Chapter 10: Cherry-pick

From section 10.18 of [Chapter 10: Cherry-pick](../textbook/ch10-cherry-pick.md).

#### Primary sources


- [git-cherry-pick](https://git-scm.com/docs/git-cherry-pick), [git-cherry](https://git-scm.com/docs/git-cherry), [git-patch-id](https://git-scm.com/docs/git-patch-id), [git-revert](https://git-scm.com/docs/git-revert), [gitrevisions](https://git-scm.com/docs/gitrevisions), [gitworkflows](https://git-scm.com/docs/gitworkflows), [git-commit](https://git-scm.com/docs/git-commit). The local copies (`git help -m <command>`) are the Git 2.55.0 text that the transcripts were checked against; the `--cherry-mark`, `--cherry-pick` and `--left-right` options are described in `git help -m log`.
- Release notes: [2.45.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.45.0.adoc), [2.46.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc), [2.56.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).

#### Secondary sources


- Julia Evans, [How git cherry-pick and revert use 3-way merge](https://jvns.ca/blog/2023/11/10/how-cherry-pick-and-revert-work/), the clearest short account of the base used by each.
- Derrick Stolee, [Commits are snapshots, not diffs](https://github.blog/open-source/git/commits-are-snapshots-not-diffs/) (GitHub Blog, 2020), on how cherry-pick and rebase replay changes although commits store snapshots.
- [Branch for release](https://trunkbaseddevelopment.com/branch-for-release/) on trunkbaseddevelopment.com and Microsoft's [Release Flow](https://learn.microsoft.com/en-us/devops/develop/how-microsoft-develops-devops), for the "fix on the main line, then cherry-pick" convention.
- The Phase 0 report of this course, sections 1, 4, 12 and 13.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- Tobias Günther for freeCodeCamp, ["Advanced Git Tutorial"](https://www.youtube.com/watch?v=qsTthZi23VE), 34 minutes, November 2021. Includes cherry-picking; mixes `master` and `main`.
- ProCodrr, [episode 9 on cherry-pick](https://www.youtube.com/watch?v=XmrpeP_s7p8), 8 minutes, March 2023, in Hindi. Mostly current; `master` naming.

#### Further reading


- [Chapter 9](../textbook/ch09-rebase.md), where the same replay runs once per commit; [Chapter 11](../textbook/ch11-reset-revert-restore.md) for revert; [Chapter 14A](../textbook/ch14a-history-investigation.md) for range notation and `git log` as a query language.


## Modules 10 (ranges) and 11: history forensics

### Chapter 14A: History investigation

From section 14A.31 of [Chapter 14A: History investigation](../textbook/ch14a-history-investigation.md).

#### Primary sources


- [git-diff](https://git-scm.com/docs/git-diff), [gitrevisions](https://git-scm.com/docs/gitrevisions), [git-log](https://git-scm.com/docs/git-log), [gitdiffcore](https://git-scm.com/docs/gitdiffcore), [git-blame](https://git-scm.com/docs/git-blame), [git-bisect](https://git-scm.com/docs/git-bisect), [git-grep](https://git-scm.com/docs/git-grep), [git-shortlog](https://git-scm.com/docs/git-shortlog), [git-describe](https://git-scm.com/docs/git-describe), [git-config](https://git-scm.com/docs/git-config). The local copies (`git help -m <command>`) are the Git 2.55.0 text that every option in this chapter was checked against.
- Christian Couder, [Fighting regressions with git bisect](https://git-scm.com/docs/git-bisect-lk2009), distributed with Git: the bisection and skip algorithms. The step estimate is in [bisect.c at v2.55.0](https://github.com/git/git/blob/v2.55.0/bisect.c).
- Release notes: [2.51.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc), [2.52.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.52.0.adoc), [2.53.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.53.0.adoc), [2.56.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc); [BreakingChanges](https://github.com/git/git/blob/v2.56.0/Documentation/BreakingChanges.adoc); [git-whatchanged](https://github.com/git/git/blob/v2.56.0/Documentation/git-whatchanged.adoc); [git-last-modified](https://github.com/git/git/blob/v2.56.0/Documentation/git-last-modified.adoc); [merge strategies](https://github.com/git/git/blob/v2.56.0/Documentation/merge-strategies.adoc).
- GitHub Docs, described and not run here: [three-dot and two-dot comparisons](https://docs.github.com/en/pull-requests/reference/branches#three-dot-and-two-dot-git-diff-comparisons); [ignore commits in the blame view](https://docs.github.com/en/repositories/working-with-files/using-files/viewing-and-understanding-files#ignore-commits-in-the-blame-view).

#### Secondary sources


- The Phase 0 report of this course, sections 1, 4 and 12: the deprecation table, and the two meanings of the dots among commonly misunderstood topics.
- Julia Evans, [Confusing git terminology](https://jvns.ca/blog/2023/11/01/confusing-git-terminology/), cited by the report for several of those misunderstandings.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- Tekin Süleyman, ["RubyConf 2018 - Branch in Time"](https://www.youtube.com/watch?v=8OOTVxKDwe0), 27 minutes, December 2018. Why history quality matters, told through `git blame`, `git log -S`, interactive rebase and `--force-with-lease`. Nothing in it depends on a Git version.
- ThePrimeagen for Boot.dev, ["Git and GitHub - Full Course"](https://www.youtube.com/watch?v=rH3zE7VlIMs), November 2024; the bisect chapter starts at 3:54:53. Current; digressive commentary style.
- glich.stream, ["Chad level git: advanced concepts (2025)"](https://www.youtube.com/watch?v=cYD3krz5L2g), 1 hour 14 minutes, January 2025. Includes bisect, hands-on.

#### Further reading


- Pro Git, part "Git Tools": [Revision Selection](https://git-scm.com/book/en/v2/Git-Tools-Revision-Selection), [Searching](https://git-scm.com/book/en/v2/Git-Tools-Searching) and [Debugging with Git](https://git-scm.com/book/en/v2/Git-Tools-Debugging-with-Git).
- [Chapter 5](../textbook/ch05-index.md) for the three everyday diffs; [Chapter 7](../textbook/ch07-branches.md) for counting divergence; [Chapter 8](../textbook/ch08-merge.md) for `--remerge-diff`; [Chapter 9](../textbook/ch09-rebase.md) for `git range-diff`; [Chapter 10](../textbook/ch10-cherry-pick.md) for patch IDs; [Chapter 13](../textbook/ch13-recovery.md) for the reflog as a recovery tool.


## Module 12: recovery

### Chapter 13: Recovery

From section 13.22 of [Chapter 13: Recovery](../textbook/ch13-recovery.md).

#### Primary sources


- [git-reflog](https://git-scm.com/docs/git-reflog), [git-fsck](https://git-scm.com/docs/git-fsck), [git-gc](https://git-scm.com/docs/git-gc) (with its NOTES section), [git-prune](https://git-scm.com/docs/git-prune), [git-bundle](https://git-scm.com/docs/git-bundle), [git-stash](https://git-scm.com/docs/git-stash) (the recovery recipe in EXAMPLES), [git-branch](https://git-scm.com/docs/git-branch), [git-fetch](https://git-scm.com/docs/git-fetch), [gitrevisions](https://git-scm.com/docs/gitrevisions), [git-maintenance](https://git-scm.com/docs/git-maintenance), [git-pack-objects](https://git-scm.com/docs/git-pack-objects), [git-unpack-objects](https://git-scm.com/docs/git-unpack-objects), [gitfaq](https://git-scm.com/docs/gitfaq).
- Configuration reference at the 2.56.0 tag: [gc](https://github.com/git/git/blob/v2.56.0/Documentation/config/gc.adoc), [core](https://github.com/git/git/blob/v2.56.0/Documentation/config/core.adoc), [maintenance](https://github.com/git/git/blob/v2.56.0/Documentation/config/maintenance.adoc).
- Git source at the 2.55.0 tag: [reflog.c](https://github.com/git/git/blob/v2.55.0/reflog.c) (the expiry rules and the stash exemption), [builtin/stash.c](https://github.com/git/git/blob/v2.55.0/builtin/stash.c).
- [How to recover a corrupted blob object](https://github.com/git/git/blob/v2.56.0/Documentation/howto/recover-corrupted-blob-object.adoc), a how-to in Git's documentation, written in 2007; its method is unchanged.
- [Release notes of Git 2.36](https://github.com/git/git/blob/master/Documentation/RelNotes/2.36.0.adoc) for `git fetch --refetch`.
- GitHub Docs: [Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository), [deleting and restoring branches in a pull request](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request), [events API](https://docs.github.com/en/rest/activity/events), [create a reference](https://docs.github.com/en/rest/git/refs#create-a-reference), [troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone).

#### Secondary sources


- Pro Git, [Maintenance and Data Recovery](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery). Caveats: it gives "around 7,000" loose objects as the automatic threshold where the configuration reference says 6700, and it predates cruft packs.
- The Phase 0 report of this course, sections 1, 12 and 13, for the retention defaults, the traced maintenance run and the GitHub instruments.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- [How to Rescue Your Commits with Git Reflog](https://www.youtube.com/watch?v=K7-wrGpnqUM), System Crafters, 14 minutes, November 2024: a deleted branch, commits in detached HEAD, a rebase mistake. Caveat: `master` and `checkout`.
- [Intern DELETED a Git Branch!](https://www.youtube.com/watch?v=jXoOEfpgzF4), Chai aur Code, Hindi, 9 minutes, 4 March 2026: a deleted branch recovered through the reflog. A single scenario.
- [The BIGGEST Git Mistake Every Intern Makes](https://www.youtube.com/watch?v=xZNQitQo5KI), Chai aur Code, Hindi, 14 minutes, 4 March 2026: commits on the wrong branch, moved with cherry-pick and reset. A single scenario.

#### Further reading


- Chapter 30: Incident Response, for the same accidents at team scale, and the disaster-recovery playbook that grows out of the method of section 13.7.


## Module 14: hooks, rerere, attributes, worktrees

### Chapter 14C: Stash Internals, Rerere, Attributes, Hooks

From section 14C.20 of [Chapter 14C: Stash Internals, Rerere, Attributes, Hooks](../textbook/ch14c-stash-rerere-attributes-hooks.md).

#### Primary sources


- [git-stash](https://git-scm.com/docs/git-stash), [git-rerere](https://git-scm.com/docs/git-rerere), [gitattributes](https://git-scm.com/docs/gitattributes), [git-check-attr](https://git-scm.com/docs/git-check-attr), [git-archive](https://git-scm.com/docs/git-archive), [git-add](https://git-scm.com/docs/git-add), [git-restore](https://git-scm.com/docs/git-restore), [githooks](https://git-scm.com/docs/githooks), [git-hook](https://git-scm.com/docs/git-hook), [git-receive-pack](https://git-scm.com/docs/git-receive-pack), [git-config](https://git-scm.com/docs/git-config), [git-maintenance](https://git-scm.com/docs/git-maintenance), [gitfaq](https://git-scm.com/docs/gitfaq) and the security section of [git](https://git-scm.com/docs/git). Every command and option in this chapter was checked against the local Git 2.55.0 copies (`git help -m <command>`).
- [Rerere technical notes](https://github.com/git/git/blob/v2.56.0/Documentation/technical/rerere.adoc) for conflict normalization and conflict IDs; [contrib/rerere-train.sh](https://github.com/git/git/blob/v2.56.0/contrib/rerere-train.sh).
- [Maintenance configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/maintenance.adoc) and [hook configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/hook.adoc).
- Release notes [2.51.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc), [2.54.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc) and [2.55.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc).
- GitHub Docs: [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets), [About push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection), [About pre-receive hooks](https://docs.github.com/en/enterprise-server@latest/admin/enforcing-policies/enforcing-policy-with-pre-receive-hooks/about-pre-receive-hooks) (GitHub Enterprise Server).
- [pre-commit](https://pre-commit.com/), the documentation of the framework, with [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks/blob/main/README.md) and [ruff-pre-commit](https://github.com/astral-sh/ruff-pre-commit/blob/main/README.md).

#### Secondary sources


- Pro Git, [Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks), [Git Attributes](https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes) and [Rerere](https://git-scm.com/book/en/v2/Git-Tools-Rerere). Caveat: the second edition predates `git restore`, `git hook` and configuration-defined hooks, and uses `master`.
- The Phase 0 report of this course, sections 1, 4, 14 and 15, for release dates, the hook count, the fail-open argument and the pre-commit facts.
- [nbstripout](https://github.com/kynan/nbstripout), the tool whose idea the notebook filter of section 14C.8 imitates in twelve lines.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- [So You Think You Know Git Part 2](https://www.youtube.com/watch?v=Md44rcw13k4), Scott Chacon, DevWorld 2024, 23 minutes, 20 March 2024: hooks, attributes, smudge and clean filters. Caveat from the report: no depth on hook security.
- [So You Think You Know Git](https://www.youtube.com/watch?v=aolI_Rz0ZqY), Scott Chacon, FOSDEM 2024, 47 minutes, 8 February 2024: rerere among many other settings. Caveat: a survey, with about one minute of product pitch.

#### Further reading


- [Chapter 8](../textbook/ch08-merge.md) for conflicts, [Chapter 9](../textbook/ch09-rebase.md) for rebase, [Chapter 11](../textbook/ch11-reset-revert-restore.md) for the stash commands, [Chapter 13](../textbook/ch13-recovery.md) for unreachable objects, [Chapter 14D](../textbook/ch14d-frontier.md) for `safe.bareRepository`.

### Chapter 25: Worktrees

From section 25.14 of [Chapter 25: Worktrees](../textbook/ch25-worktrees.md).

#### Primary sources


- [git-worktree](https://git-scm.com/docs/git-worktree): commands, the REFS, CONFIGURATION FILE, DETAILS and BUGS sections. The local copy (`git help -m worktree`) is the Git 2.55.0 text that the transcripts were checked against. Source of the current manual: [git-worktree.adoc](https://github.com/git/git/blob/v2.56.0/Documentation/git-worktree.adoc).
- `gc.worktreePruneExpire`, `extensions.worktreeConfig`, `worktree.guessRemote`, `worktree.useRelativePaths`, `checkout.defaultRemote`: `git help -m config`.
- [git-rebase](https://github.com/git/git/blob/v2.56.0/Documentation/git-rebase.adoc) for `--update-refs` and branches checked out in a worktree; [git-refs](https://github.com/git/git/blob/v2.55.0/Documentation/git-refs.adoc) for the migration limitation.
- Release notes: [2.48.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.48.0.adoc), [2.56.0](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).

#### Secondary sources


- The Phase 0 report of this course, section 1 (the table of newer commands and the maintenance defaults) and section 13.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- Scott Chacon, ["So You Think You Know Git Part 2 - DevWorld 2024"](https://www.youtube.com/watch?v=Md44rcw13k4) (23 min, 2024): worktrees among other topics. Current.
- Edward Thomson, ["You Don't Know Git"](https://www.youtube.com/watch?v=DZI0Zl-1JqQ), NDC London 2025 (1 h 02 min): reflog, rerere, worktrees, rebase variants. Current.
- glich.stream, ["Chad level git: advanced concepts (2025)"](https://www.youtube.com/watch?v=cYD3krz5L2g) (1 h 14 min): hands-on, includes worktrees and Git LFS. Current.

#### Further reading


- [gitrepository-layout](https://git-scm.com/docs/gitrepository-layout) for the `worktrees/` directory and the `commondir` and `gitdir` files.


## Module 15: submodules, subtrees, LFS

### Chapter 22: Git LFS

From section 22.18 of [Chapter 22: Git LFS](../textbook/ch22-git-lfs.md).

#### Primary sources


- Git LFS: the [specification](https://github.com/git-lfs/git-lfs/blob/main/docs/spec.md), [server discovery](https://github.com/git-lfs/git-lfs/blob/main/docs/api/server-discovery.md) and [custom transfers](https://github.com/git-lfs/git-lfs/blob/main/docs/custom-transfers.md) in the project's repository, read on 2 October 2026; the help texts of the installed client 3.7.1 (`git lfs <command> --help`), which the transcripts were checked against; [releases](https://github.com/git-lfs/git-lfs/releases).
- GitHub Docs, read on 2 October 2026: [About large files on GitHub](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github), [About Git Large File Storage](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage), [Git LFS billing](https://docs.github.com/en/billing/concepts/product-billing/git-lfs), [Collaboration with Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/collaboration-with-git-large-file-storage), [Removing files from Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/removing-files-from-git-large-file-storage), [Repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits).
- [gitattributes](https://git-scm.com/docs/gitattributes) for filter drivers; `actions/checkout` [action.yml](https://github.com/actions/checkout/blob/v7.0.1/action.yml) at v7.0.1.

#### Secondary sources


- The Phase 0 report of this course: section 2 (the large-files paragraph), section 13 ("Scale, submodules and large files") and section 15 ("Data and model versioning"), with the research notes on AI/ML workflows.

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- glich.stream, ["Chad level git: advanced concepts (2025)"](https://www.youtube.com/watch?v=cYD3krz5L2g) (1 h 14 min): hands-on, includes Git LFS. Current.
- Vikash Das, ["MLOps: Day 4 - Data Versioning using DVC"](https://www.youtube.com/watch?v=PPrPuxqWc7E) (1 h 25 min, 2024, Hindi): why Git alone does not suit data, and DVC beside Git. Mostly current; DVC CLI versions not checked.

#### Further reading


- [Chapter 28](../textbook/ch28-ai-ml-workflows.md) for data and model versioning beyond LFS; [Chapter 26](../textbook/ch26-performance.md) for partial clone, which is Git's own way of not downloading every blob.

### Chapter 23: Submodules and Subtrees

From section 23.21 of [Chapter 23: Submodules and Subtrees](../textbook/ch23-submodules.md).

#### Primary sources


- [git-submodule](https://git-scm.com/docs/git-submodule), [gitsubmodules](https://git-scm.com/docs/gitsubmodules), [gitmodules](https://git-scm.com/docs/gitmodules), [git-push](https://git-scm.com/docs/git-push) (`--recurse-submodules`). The local copies (`git help -m submodule`, `git help -m gitsubmodules`, `git help -m config`) are the Git 2.55.0 text that the transcripts were checked against.
- [git-subtree](https://github.com/git/git/blob/v2.55.0/contrib/subtree/git-subtree.adoc) in Git's `contrib/` directory, read on 2 October 2026; locally, `git subtree -h`.
- [Protocol configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/protocol.adoc); release notes [2.38.1](https://github.com/git/git/blob/master/Documentation/RelNotes/2.38.1.adoc) and [2.30.6](https://github.com/git/git/blob/master/Documentation/RelNotes/2.30.6.adoc).
- Security advisories [GHSA-8h77-4q3w-gfgv](https://github.com/git/git/security/advisories/GHSA-8h77-4q3w-gfgv) (CVE-2024-32002) and [GHSA-vwqx-4fm8-6qc9](https://github.com/git/git/security/advisories/GHSA-vwqx-4fm8-6qc9) (CVE-2025-48384).
- `actions/checkout` [action.yml](https://github.com/actions/checkout/blob/v7.0.1/action.yml) and [README](https://github.com/actions/checkout/blob/v7.0.1/README.md) at v7.0.1, the README read on 2 October 2026.

#### Secondary sources


- Pro Git, [Git Tools: Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules), which documents the failure modes of sections 23.5 to 23.10 from the user's side.
- The Phase 0 report of this course, section 12 (the misconception table), section 13 ("Scale, submodules and large files") and section 14 ("The Git client").

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- Tobias Günther for freeCodeCamp, ["Advanced Git Tutorial"](https://www.youtube.com/watch?v=qsTthZi23VE) (34 min, 2021): includes a submodules segment. Concepts current; mixes `master` and `main` and uses `checkout`.

#### Further reading


- [gitrepository-layout](https://git-scm.com/docs/gitrepository-layout) for `modules/`; [Chapter 24](../textbook/ch24-monorepos.md) for the alternative of one repository.


## Modules 16 and 17: the object database, the index, refs and the Git directory

### Chapter 3: Git Internals

From section 3.21 of [Chapter 3: Git Internals](../textbook/ch03-git-internals.md).

#### Primary sources

The local manual pages for the Git you run: `git help gitformat-loose`, `gitformat-pack`, `gitformat-index`, `gitformat-signature`, `gitrepository-layout`, `gitdatamodel`, `gitglossary`, `gitrevisions`, and the pages of every command used above. Online, at the 2.56.0 tag: [gitdatamodel](https://github.com/git/git/blob/v2.56.0/Documentation/gitdatamodel.adoc), [gitformat-loose](https://github.com/git/git/blob/v2.56.0/Documentation/gitformat-loose.adoc), [gitformat-pack](https://github.com/git/git/blob/v2.56.0/Documentation/gitformat-pack.adoc), [gitformat-index](https://github.com/git/git/blob/v2.56.0/Documentation/gitformat-index.adoc), [gitformat-signature](https://github.com/git/git/blob/v2.56.0/Documentation/gitformat-signature.adoc), [gitrepository-layout](https://github.com/git/git/blob/v2.56.0/Documentation/gitrepository-layout.adoc), [glossary](https://github.com/git/git/blob/v2.56.0/Documentation/glossary-content.adoc), [revisions](https://github.com/git/git/blob/v2.56.0/Documentation/revisions.adoc), [git-refs at 2.55](https://github.com/git/git/blob/v2.55.0/Documentation/git-refs.adoc), [the reftable design](https://github.com/git/git/blob/v2.56.0/Documentation/technical/reftable.adoc), [repository format versions](https://github.com/git/git/blob/v2.56.0/Documentation/technical/repository-version.adoc), [hash-function-transition](https://github.com/git/git/blob/v2.56.0/Documentation/technical/hash-function-transition.adoc), [BreakingChanges](https://github.com/git/git/blob/v2.56.0/Documentation/BreakingChanges.adoc), the release notes for [2.13](https://github.com/git/git/blob/master/Documentation/RelNotes/2.13.0.adoc), [2.29](https://github.com/git/git/blob/master/Documentation/RelNotes/2.29.0.adoc), [2.42](https://github.com/git/git/blob/master/Documentation/RelNotes/2.42.0.adoc), [2.45](https://github.com/git/git/blob/master/Documentation/RelNotes/2.45.0.adoc), [2.46](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc), [2.51](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc) and [2.53](https://github.com/git/git/blob/master/Documentation/RelNotes/2.53.0.adoc), and the commit ["fsck: snapshot default refs before object walk"](https://github.com/git/git/commit/f6b262581a885a11e3e817bf635303e40b640f2a).


#### Secondary sources

Pro Git, chapter 10: [objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects), [packfiles](https://git-scm.com/book/en/v2/Git-Internals-Packfiles) and [maintenance and recovery](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery); frozen since May 2024, so it predates reftable and the glossary change. The GitHub Blog, [Git's database internals, part I](https://github.blog/open-source/git/gits-database-internals-i-packed-object-store/). The Phase 0 report of this course for the hosting facts of section 3.14.


#### Videos

Derrick Stolee, ["Git Internals: a Database Perspective"](https://www.youtube.com/watch?v=YdstUWcg5j4) (Git Merge 2022, 27 min): packfiles and the storage layer; current. John Britton, ["Git Internals"](https://www.youtube.com/watch?v=lG90LZotrpo) (CS50, 2018, 58 min): the object model, correct and clear; `master`, `checkout`, SHA-1 only, almost nothing on packfiles. Patrick Steinhardt, ["Reftable Backend"](https://www.youtube.com/watch?v=TqHYOGCJkS8) (2025, 20 min) and Emily Shaffer, ["SHA-256 at a Hyperscaler"](https://www.youtube.com/watch?v=eJJp0RE7cd4) (Git Merge 2026, 32 min): both assume this chapter's level; the second had almost no views when the report checked it.


#### Further reading

James Coglan, *Building Git*, teaches the formats by reimplementing them; ["Write yourself a Git"](https://wyag.thb.lt/) does the same in Python. Both predate reftable.



## Modules 16 and 18: maintenance, transfer and scale

### Chapter 26: Performance

From section 26.22 of [Chapter 26: Performance](../textbook/ch26-performance.md).

#### Primary sources

The local manual of Git 2.55.0: `git help maintenance`, `gc`, `repack`, `commit-graph`, `multi-pack-index`, `fsmonitor--daemon`, `update-index`, `clone`, `fetch`, `rev-list`, `backfill`, `bundle`, `config`. Online: [git-maintenance](https://git-scm.com/docs/git-maintenance), [git-gc](https://git-scm.com/docs/git-gc), [git-repack](https://git-scm.com/docs/git-repack), [git-commit-graph](https://git-scm.com/docs/git-commit-graph), [gitformat-commit-graph](https://git-scm.com/docs/gitformat-commit-graph), [git-multi-pack-index](https://git-scm.com/docs/git-multi-pack-index), [bitmap-format](https://git-scm.com/docs/bitmap-format), [gitformat-pack](https://git-scm.com/docs/gitformat-pack), [git-fsmonitor--daemon](https://git-scm.com/docs/git-fsmonitor--daemon), [shallow](https://git-scm.com/docs/shallow), [partial-clone](https://git-scm.com/docs/partial-clone), [git-backfill](https://git-scm.com/docs/git-backfill), [git-bundle](https://git-scm.com/docs/git-bundle), [bundle-uri](https://git-scm.com/docs/bundle-uri), [gitprotocol-v2](https://git-scm.com/docs/gitprotocol-v2), [api-trace2](https://git-scm.com/docs/api-trace2). Git source at the 2.55.0 tag: [builtin/gc.c](https://github.com/git/git/blob/v2.55.0/builtin/gc.c) (strategies, tasks and thresholds) and [odb/source-loose.c](https://github.com/git/git/blob/v2.55.0/odb/source-loose.c) (the loose-object estimate).


#### Secondary sources

Derrick Stolee, Git's database internals, GitHub Blog, 2022: [I, the packed object store](https://github.blog/open-source/git/gits-database-internals-i-packed-object-store/), [II, commit history queries](https://github.blog/open-source/git/gits-database-internals-ii-commit-history-queries/), [III, file history queries](https://github.blog/open-source/git/gits-database-internals-iii-file-history-queries/), [IV, distributed synchronization](https://github.blog/open-source/git/gits-database-internals-iv-distributed-synchronization/). [Get up to speed with partial clone and shallow clone](https://github.blog/open-source/git/get-up-to-speed-with-partial-clone-and-shallow-clone/) (2020). Taylor Blau, [Scaling monorepo maintenance](https://github.blog/open-source/git/scaling-monorepo-maintenance/) (2021). Jeff Hostetler, [the file system monitor](https://github.blog/engineering/infrastructure/improve-git-monorepo-performance-with-a-file-system-monitor/) (2022). The practitioner reports of section 26.15: each from the publisher's own environment and date, not comparable with one another. The Phase 0 report of this course, sections 1, 12 and 13.


#### Videos

(optional; assessments from the Phase 0 report). Derrick Stolee, ["Git Internals: a Database Perspective"](https://www.youtube.com/watch?v=YdstUWcg5j4) (Git Merge 2022, 27 min): pack indexes, the multi-pack-index, bitmaps, `git maintenance start`; current, and the best compact talk on this layer. Derrick Stolee, ["Git at Scale for Everyone"](https://www.youtube.com/watch?v=USLB1gwl1vA) (32 min, 2020): partial clone and background maintenance; the Scalar packaging shown is the one of 2020.


#### Further reading

[Chapter 3](../textbook/ch03-git-internals.md), section 3.7, for packs and deltas; [Chapter 13](../textbook/ch13-recovery.md), sections 13.4 and 13.13, for retention; [Chapter 24](../textbook/ch24-monorepos.md) for the working-tree side; [Chapter 29](../textbook/ch29-production-troubleshooting.md) for traces in diagnosis.


### Chapter 24: Monorepos

From section 24.18 of [Chapter 24: Monorepos](../textbook/ch24-monorepos.md).

#### Primary sources

The local manual of Git 2.55.0: `git help sparse-checkout` with its "Internals" sections, `git help scalar`, `git help clone`, `git help backfill`. Online: [git-sparse-checkout](https://git-scm.com/docs/git-sparse-checkout), [scalar](https://git-scm.com/docs/scalar), [git-backfill](https://git-scm.com/docs/git-backfill), [partial-clone](https://git-scm.com/docs/partial-clone), [git-describe](https://git-scm.com/docs/git-describe), the [sparse-index design notes](https://github.com/git/git/blob/v2.55.0/Documentation/technical/sparse-index.adoc) and [scalar.c](https://github.com/git/git/blob/v2.55.0/scalar.c) at the 2.55.0 tag. Potvin and Levenberg, [Why Google Stores Billions of Lines of Code in a Single Repository](https://cacm.acm.org/research/why-google-stores-billions-of-lines-of-code-in-a-single-repository/) (2016; not Git). Engineering at Meta, [Sapling](https://engineering.fb.com/2022/11/15/open-source/sapling-source-control-scalable/) (2022). GitHub Docs as linked in sections 24.8 and 24.9.


#### Secondary sources

GitHub Blog: [sparse-checkout](https://github.blog/open-source/git/bring-your-monorepo-down-to-size-with-sparse-checkout/) (2020), [sparse index](https://github.blog/open-source/git/make-your-monorepo-feel-small-with-gits-sparse-index/) (2021), [The Story of Scalar](https://github.blog/open-source/git/the-story-of-scalar/) (2022), [Git's database internals V](https://github.blog/open-source/git/gits-database-internals-v-scalability/) (2022) on ways to split a repository. [Software Engineering at Google, chapter 16](https://abseil.io/resources/swe-book/html/ch16.html). The practitioner reports linked in section 24.2, each from the publisher's own environment. The Phase 0 report of this course, sections 1, 12 and 13.


#### Videos

(optional; assessments from the Phase 0 report). Derrick Stolee, ["Git at Scale for Everyone"](https://www.youtube.com/watch?v=USLB1gwl1vA) (32 min, 2020): partial clone and a cone-mode demo; concepts current, the Scalar packaging is the one of 2020. Scott Chacon, ["So You Think You Know Git"](https://www.youtube.com/watch?v=aolI_Rz0ZqY) (FOSDEM 2024, 47 min): a survey, with about a minute of product pitch. Stolee's [Scalar talk](https://www.youtube.com/watch?v=8iZqagosc5w) (2021) and ["Scaling Git at Microsoft"](https://www.youtube.com/watch?v=g_MPGU_m01s) (2017) describe superseded designs: history only.


#### Further reading

[Chapter 26](../textbook/ch26-performance.md) for maintenance, the commit-graph and clone shapes; [Chapter 25](../textbook/ch25-worktrees.md) for per-worktree configuration.



## Modules 19 and 25: the GitHub platform, the CLI and the API

### Chapter 15: GitHub

From section 15.26 of [Chapter 15: GitHub](../textbook/ch15-github.md).

#### Primary sources


- GitHub Docs, read on 2 October 2026: [types of accounts](https://docs.github.com/en/get-started/learning-about-github/types-of-github-accounts), [repository roles](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization), [base permissions](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization), [repository visibility](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility), [forks](https://docs.github.com/en/pull-requests/reference/forks), [linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue), [about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases), [immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases), [issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms), [community health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file), [repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits), [large files](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github), [Packages](https://docs.github.com/en/packages/learn-github-packages/introduction-to-github-packages), [API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions), [rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api), [webhooks](https://docs.github.com/en/webhooks/about-webhooks).
- The GitHub CLI: `gh <command> --help` of the installed 2.88.1 for every command and flag in this chapter; the [manual](https://cli.github.com/manual/gh) and [release notes](https://github.com/cli/cli/releases) for newer versions.
- The GitHub Changelog entries linked in the sections.
- Git: [gitnamespaces](https://git-scm.com/docs/gitnamespaces) for the model in section 15.7; [git-describe](https://git-scm.com/docs/git-describe), [git-rev-list](https://git-scm.com/docs/git-rev-list), [git-cat-file](https://git-scm.com/docs/git-cat-file), as installed with Git 2.55.0.

#### Secondary sources


- The Phase 0 report of this course, sections 2, 3, 4 and 12, and its research notes on the GitHub platform: the dated changes, the plan gates and the flags marked unverified here.
- Check Point Research, [Stargazers Ghost Network](https://research.checkpoint.com/2024/stargazers-ghost-network/), cited by the report.

#### Videos

(optional; the report's assessments rest on captions and chapter lists, not on full viewing)


- [The ultimate beginner's guide to GitHub in 2026](https://www.youtube.com/watch?v=NUELGzIHT-I), GitHub, 51 minutes, 22 September 2025. Caveats: mechanics only; compiled from 2024 episodes.
- [Git and GitHub - Full Course](https://www.youtube.com/watch?v=rH3zE7VlIMs), ThePrimeagen for Boot.dev, 12 November 2024: remotes and GitHub from 1:54:18, then forks.
- The report found no verified video on roles, fork networks, releases or the API at this depth.

#### Further reading


- [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow) and [best practices for organizations](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/best-practices-for-organizations).
- Chapter 18 for governance, Chapter 21B for fork networks during a secret leak, Chapter 27 for open-source practice.


## Module 20: authentication and SSH

### Chapter 16: Authentication

From section 16.27 of [Chapter 16: Authentication](../textbook/ch16-authentication.md).

#### Primary sources


- GitHub Docs, read on 2 October 2026: [about authentication](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github), [managing personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens), [credential types](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/github-credential-types), [token expiration and revocation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation), [caching credentials](https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git), [generating an SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent), [testing your SSH connection](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection), [GitHub's SSH key fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints), [SSH over the HTTPS port](https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port), [Permission denied (publickey)](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-denied-publickey), [Host key verification failed](https://docs.github.com/en/authentication/troubleshooting-ssh/error-host-key-verification-failed), [troubleshooting cloning errors](https://docs.github.com/en/repositories/creating-and-managing-repositories/troubleshooting-cloning-errors), [managing multiple accounts](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-your-personal-account/managing-multiple-accounts), [deploy keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys), [single sign-on](https://docs.github.com/en/enterprise-cloud@latest/authentication/authenticating-with-single-sign-on/about-authentication-with-single-sign-on), [mandatory two-factor authentication](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/about-mandatory-two-factor-authentication).
- GitHub Blog and Changelog: [token authentication requirements](https://github.blog/security/application-security/token-authentication-requirements-for-git-operations/), [improving Git protocol security](https://github.blog/security/application-security/improving-git-protocol-security-github/), [the RSA host key](https://github.blog/news-insights/company-news/we-updated-our-rsa-ssh-host-key/), [security improvements for SSH](https://github.blog/changelog/2026-09-22-security-improvements-for-ssh/).
- Git 2.55.0: [gitcredentials](https://git-scm.com/docs/gitcredentials), [git-credential](https://git-scm.com/docs/git-credential), [git-config](https://git-scm.com/docs/git-config) (`credential.*`, `transfer.credentialsInUrl`, `url.<base>.insteadOf`, `includeIf`), as installed (`git help -m <page>`); the source files [http.c](https://github.com/git/git/blob/v2.55.0/http.c) and [remote-curl.c](https://github.com/git/git/blob/v2.55.0/remote-curl.c) for what Git does on 401, 403 and 404.
- OpenSSH as installed (`man ssh`, `man ssh_config`, `man ssh-keygen`, `man ssh-add`); online at [man.openbsd.org](https://man.openbsd.org/ssh_config).
- The GitHub CLI: `gh auth <command> --help` of 2.88.1, and [helper_config.go](https://github.com/cli/cli/blob/v2.88.1/pkg/cmd/auth/shared/gitcredentials/helper_config.go) for what `gh auth setup-git` writes.

#### Secondary sources


- The Phase 0 report of this course, section 2 (authentication, the error table, the flags) and section 4, and its research notes on the GitHub platform, section 4.
- Pro Git, [Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage): the helper protocol with a custom helper. Caveat: predates the GitHub CLI and fine-grained tokens.

#### Videos

(optional; the report's assessments rest on captions and chapter lists, not on full viewing)


- [Git & GitHub Crash Course 2025](https://www.youtube.com/watch?v=vA5TTz6BXhY), Traversy Media, 49 minutes, 13 January 2025: SSH key setup. Caveat: beginner scope.
- [Complete git and Github course in Hindi](https://www.youtube.com/watch?v=q8EevlEpQ2A), Chai aur Code, 8 June 2024: states that passwords no longer work and sets up SSH. Caveat: audited through auto-generated captions.
- No verified video covers credential helpers, token types or authentication diagnosis at this depth.

#### Further reading


- [Authenticating to the REST API](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api) and [troubleshooting the REST API](https://docs.github.com/en/rest/using-the-rest-api/troubleshooting-the-rest-api), for the 401, 403 and 404 rules that Git's HTTPS errors inherit.
- Chapter 21A for the workflow token and OIDC, Chapter 21B for credential blast radius, token forensics and the response to a leaked secret, Chapter 29 for the troubleshooting playbook.


## Modules 21 and 22: pull requests, forks, merge methods, releases

### Chapter 17: Pull Requests

From section 17.25 of [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md).

#### Primary sources

(docs.github.com, the GitHub Changelog and cli.github.com; read on 1 and 2 October 2026)


- Reference pages: [Pull requests](https://docs.github.com/en/pull-requests/reference/pull-requests), [Branches](https://docs.github.com/en/pull-requests/reference/branches), [Pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges), [Pull request reviews](https://docs.github.com/en/pull-requests/reference/pull-request-reviews), [Status checks](https://docs.github.com/en/pull-requests/reference/status-checks), [Merge conflicts](https://docs.github.com/en/pull-requests/reference/merge-conflicts), [Forks](https://docs.github.com/en/pull-requests/reference/forks), [Stacked pull requests](https://docs.github.com/en/pull-requests/reference/stacked-pull-requests)
- How-to pages: [Checking out pull requests locally](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/checking-out-pull-requests-locally), [Merging a pull request](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/merging-a-pull-request), [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [Syncing a fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork); the others are linked where they are quoted.
- Repository pages: [About merge methods on GitHub](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github), [Managing a merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue), [Repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits), [About commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification), [REST API endpoints for pull requests](https://docs.github.com/en/rest/pulls/pulls), [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- Changelog entries, linked where they are used: 19 February 2026 (test merge commits), 30 July 2026 (stacked pull requests), 1 October 2026 (asynchronous merge API).
- GitHub CLI: `gh pr --help` and its subcommands (2.88.1, local); [gh pr manual](https://cli.github.com/manual/gh_pr).
- Git 2.55 manual pages: `git help merge-tree`, `git help rebase`, `git help branch`, `git help cherry`, `git help config` (`receive.hideRefs`); the [gitfaq](https://git-scm.com/docs/gitfaq) entry on squash merges and long-lived branches.

#### Secondary sources


- The Phase 0 report of this course, sections 2, 3, 12 and 13, and its notes on the GitHub platform.
- GitHub Engineering, [Scaling merge-ort across GitHub](https://github.blog/engineering/infrastructure/scaling-merge-ort-across-github/) (2023): why a server needs a merge without a working tree.

#### Videos

(from the Phase 0 report, with its caveats)


- ["The ultimate beginner's guide to GitHub in 2026"](https://www.youtube.com/watch?v=NUELGzIHT-I), GitHub, 22 September 2025: the pull request and merge chapters, 40:44 to 47:14. Mechanics only; compiled from 2024 episodes. The report found no verified video that teaches code review end to end in the 2026 interface.

#### Further reading


- [Chapter 8: Merge](../textbook/ch08-merge.md), sections 8.12, 8.15 and 8.17; [Chapter 9: Rebase](../textbook/ch09-rebase.md), sections 9.9 and 9.14; [Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md), sections 12.8, 12.10 and 12.12; [Chapter 14A: History investigation](../textbook/ch14a-history-investigation.md), sections 14A.2, 14A.8, 14A.18 and 14A.22.
- [Pro Git, "Contributing to a Project"](https://git-scm.com/book/en/v2/GitHub-Contributing-to-a-Project): the fork-and-pull flow at a book's pace; its screenshots predate the current interface.


## Module 23: governance

### Chapter 18: Branch Protection and Rulesets

From section 18.25 of [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md).

#### Primary sources

(docs.github.com and the GitHub Changelog; read on 1 and 2 October 2026)


- Rulesets: [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets) and its [Enterprise Cloud view](https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets), [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets), [Creating rulesets for a repository](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository), [Managing rulesets for a repository](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository), [Troubleshooting rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/troubleshooting-rules), [Converting branch protections to rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/converting-branch-protections-to-rulesets), [Creating rulesets for repositories in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization)
- Classic protection: [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- Checks: [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [Status checks](https://docs.github.com/en/pull-requests/reference/status-checks), [Skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs)
- API and CLI: [REST API endpoints for rules](https://docs.github.com/en/rest/repos/rules), [rule suites](https://docs.github.com/en/rest/repos/rule-suites), [branch protection](https://docs.github.com/en/rest/branches/branch-protection); `gh ruleset --help` and `gh api --help` (2.88.1, local); [gh ruleset manual](https://cli.github.com/manual/gh_ruleset)
- Roles: [Repository roles for an organization](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization)
- Changelog entries are linked where they are used.
- Ruby's [`File.fnmatch`](https://ruby-doc.org/core-2.5.1/File.html#method-c-fnmatch), the function GitHub's documentation links to; Git 2.55: `git help hooks` (`pre-receive`), `git help config` (`receive.denyNonFastForwards`).

#### Secondary sources


- The Phase 0 report of this course, sections 2, 3, 4 and 13, and its notes on the GitHub platform.
- [`github/ruleset-recipes`](https://github.com/github/ruleset-recipes): GitHub's importable example rulesets.

#### Videos

(from the Phase 0 report, with its caveats)


- ["Introduction to GitHub Actions - Part 6 - Repository Rulesets"](https://www.youtube.com/watch?v=ZTbM-h9RZOo), Mickey Gousset, 6 December 2024, 15 minutes: a ruleset that requires a status check, the bypass list, rulesets versus classic rules. Current; slow and careful.
- ["Securely building GitHub on GitHub"](https://www.youtube.com/watch?v=eig5tJUl688), GitHub Universe 2024, 41 minutes: rulesets, Rule Insights, Evaluate mode and bypass lists at scale. Predates the 2025 and 2026 ruleset additions.

#### Further reading


- [Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md), section 12.7 (server-side rules in plain Git); [Chapter 14B](../textbook/ch14b-config-tags-signing.md), sections 14B.11 and 14B.15 to 14B.17; [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md), sections 17.5, 17.8 and 17.11.

### Chapter 19: CODEOWNERS

From section 19.18 of [Chapter 19: CODEOWNERS](../textbook/ch19-codeowners.md).

#### Primary sources

(docs.github.com and the GitHub Changelog; read on 1 and 2 October 2026)


- [About code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners): locations, syntax, the example file, size limit, write-access requirement, forks, branch protection.
- [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-a-pull-request-before-merging): code owner review and the required reviewers sub-option.
- [REST API: list CODEOWNERS errors](https://docs.github.com/en/rest/repos/repos#list-codeowners-errors).
- [Changelog, 17 February 2026: required reviewer rule generally available](https://github.blog/changelog/2026-02-17-required-reviewer-rule-is-now-generally-available/).
- [Stacked pull requests (reference)](https://docs.github.com/en/pull-requests/reference/stacked-pull-requests).
- Git 2.55: [gitignore pattern format](https://git-scm.com/docs/gitignore#_pattern_format) (`git help ignore`), `git help check-ignore`.

#### Secondary sources


- The Phase 0 report of this course, section 2 ("CODEOWNERS requests reviews; only a rule makes them mandatory"), and its notes on the GitHub platform, section 3.

#### Videos


- The Phase 0 report lists no verified video that teaches CODEOWNERS; its survey of popular beginner courses found that none covers it.

#### Further reading


- [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md), sections 17.3 to 17.5; [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md), sections 18.5 and 18.7; [Chapter 4: The Working Tree](../textbook/ch04-working-tree.md), for `.gitignore` itself.


## Module 26: Actions fundamentals

### Chapter 20A: GitHub Actions Fundamentals

From section 20A.22 of [Chapter 20A: GitHub Actions Fundamentals](../textbook/ch20a-actions-fundamentals.md).

#### Primary sources

(docs.github.com, the GitHub Changelog, and each action's repository at the pinned tag; read on 1 and 2 October 2026)


- Reference pages: [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts), [expressions](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions), [variables](https://docs.github.com/en/actions/reference/workflows-and-actions/variables), [secrets](https://docs.github.com/en/actions/reference/security/secrets), [workflow commands](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands), [dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching), [limits](https://docs.github.com/en/actions/reference/limits), [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [reusing workflow configurations](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations).
- Other documentation: [workflow artifacts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts), [GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token), [skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs), [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [publishing a package with Actions](https://docs.github.com/en/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions).
- Action READMEs and `action.yml` files at the pinned versions: [checkout v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md), [setup-python v7.0.0](https://github.com/actions/setup-python/blob/v7.0.0/README.md), [setup-java v6.0.1](https://github.com/actions/setup-java/blob/v6.0.1/README.md), [cache v6.1.0](https://github.com/actions/cache/blob/v6.1.0/README.md), [upload-artifact v7.0.1](https://github.com/actions/upload-artifact/blob/v7.0.1/README.md), [download-artifact v8.0.1](https://github.com/actions/download-artifact/blob/v8.0.1/README.md), [setup-uv v10.2.0](https://github.com/astral-sh/setup-uv/blob/v10.2.0/README.md), [docker/login-action v4.6.0](https://github.com/docker/login-action/blob/v4.6.0/README.md), [docker/metadata-action v6.2.0](https://github.com/docker/metadata-action/blob/v6.2.0/README.md), [docker/build-push-action v7.4.0](https://github.com/docker/build-push-action/blob/v7.4.0/README.md), [docker/setup-buildx-action v4.4.1](https://github.com/docker/setup-buildx-action/blob/v4.4.1/README.md).
- Tool documentation: [uv with GitHub Actions](https://docs.astral.sh/uv/guides/integration/github/), [Docker: cache management with GitHub Actions](https://docs.docker.com/build/ci/github-actions/cache/).
- Changelog entries, linked where they are used.
- Git 2.55 manual pages: `git help clone`, `git help fetch`, `git help describe`, `git help diff`. GitHub CLI 2.88.1: `gh run --help`, `gh workflow --help`, `gh cache --help`.

#### Secondary sources


- The Phase 0 report of this course, sections 2, 3, 4, 12 and 13, and its notes on GitHub Actions, including the flags carried into this chapter as "Unverified".

#### Videos

(from the Phase 0 report, with its caveats)


- ["Complete GitHub Actions Course - From BEGINNER to PRO"](https://www.youtube.com/watch?v=Xwpi0ITkL3U), Sid Palas, DevOps Directive, 3 h 43 min, 24 September 2025. The most complete current free course on workflow mechanics. It predates the Node 24-only runtime and `actions/checkout` v7, says "branch protections" and never mentions rulesets.
- ["GitHub Actions tutorial in Hindi"](https://www.youtube.com/watch?v=ookIfjc8dW0), CODERS NEVER QUIT, 1 h 51 min, 27 September 2024, Hindi. Jobs, expressions, checkout, caching and artifacts. Mostly current in concept; the action versions shown were not checked; no pinning.

#### Further reading


- [Chapter 17: Pull Requests](../textbook/ch17-pull-requests.md), sections 17.2, 17.6 and 17.11; [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md) on required status checks; [Chapter 19: CODEOWNERS](../textbook/ch19-codeowners.md) on protecting the workflows directory; [Chapter 26: Performance](../textbook/ch26-performance.md), section 26.11 on shallow clones; [Chapter 14A: History investigation](../textbook/ch14a-history-investigation.md) on two-dot and three-dot ranges.


## Modules 27 and 28: build, package, deliver; runners and debugging CI

### Chapter 20B: GitHub Actions: delivery, runners, cost and debugging

From section 20B.22 of [Chapter 20B: GitHub Actions: delivery, runners, cost and debugging](../textbook/ch20b-actions-delivery-debugging.md).

#### Primary sources


- GitHub Docs: [deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments), [managing environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments), [control deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments), [reviewing deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments), [REST: deployment environments](https://docs.github.com/en/rest/deployments/environments).
- GitHub Docs: [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [reusing workflow configurations](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations), [reuse workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows), [metadata syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/metadata-syntax), [custom actions](https://docs.github.com/en/actions/concepts/workflows-and-actions/custom-actions).
- GitHub Docs: [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [self-hosted runners](https://docs.github.com/en/actions/reference/runners/self-hosted-runners), [secure use](https://docs.github.com/en/actions/reference/security/secure-use), [limits](https://docs.github.com/en/actions/reference/limits), [billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions), [runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing).
- GitHub Docs: [dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching), [using secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets), [enable debug logging](https://docs.github.com/en/actions/how-tos/monitor-workflows/enable-debug-logging), [re-running workflows and jobs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs), [troubleshooting workflows](https://docs.github.com/en/actions/how-tos/troubleshoot-workflows), [skipping workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs), [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks).
- Action documentation at the pinned versions: [actions/checkout v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md), [actions/cache v6.1.0](https://github.com/actions/cache/blob/v6.1.0/README.md), [actions/upload-artifact v7.0.1](https://github.com/actions/upload-artifact/blob/v7.0.1/README.md), [actions/download-artifact v8.0.1](https://github.com/actions/download-artifact/blob/v8.0.1/README.md), [astral-sh/setup-uv v10.2.0](https://github.com/astral-sh/setup-uv/blob/v10.2.0/README.md).
- GitHub CLI manual: [gh run view](https://cli.github.com/manual/gh_run_view), [gh run rerun](https://cli.github.com/manual/gh_run_rerun), [gh run watch](https://cli.github.com/manual/gh_run_watch), [gh workflow run](https://cli.github.com/manual/gh_workflow_run), and the `--help` output of the installed 2.88.1.
- The local Git manual: `git help describe`, `git help ls-files`, `git help gitattributes`, `git help config` (`core.ignoreCase`).

#### Secondary sources


- [actionlint](https://github.com/rhysd/actionlint/blob/main/README.md) and [act: unsupported functionality](https://nektosact.com/not_supported.html), third-party tools, not installed for this course.
- The GitHub changelog entries linked in the text for each dated change.

#### Videos

(from the Phase 0 report, with its caveats)


- ["Complete GitHub Actions Course - From BEGINNER to PRO"](https://www.youtube.com/watch?v=Xwpi0ITkL3U), Sid Palas, DevOps Directive, 3 h 43 min, 24 September 2025. The most complete current free course; it has sponsor segments, says "branch protections" and never mentions rulesets, and pre-dates Node 24-only runners and `actions/checkout` v7.
- ["Introduction to GitHub Actions - Part 6 - Repository Rulesets"](https://www.youtube.com/watch?v=ZTbM-h9RZOo), Mickey Gousset, 15 min, 6 December 2024. A ruleset that requires a status check.

#### Further reading


- [Chapter 18](../textbook/ch18-branch-protection.md), section 18.8, for required status checks from the ruleset side; [Chapter 21A](../textbook/ch21a-actions-security.md) for the security model of everything in this chapter.


## Module 29: Actions security

### Chapter 21A: GitHub Actions security

From section 21A.26 of [Chapter 21A: GitHub Actions security](../textbook/ch21a-actions-security.md).

#### Primary sources


- GitHub Docs: [secure use reference](https://docs.github.com/en/actions/reference/security/secure-use); [securely using pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target); [script injections](https://docs.github.com/en/actions/concepts/security/script-injections); [GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token); [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax); [OIDC reference](https://docs.github.com/en/actions/reference/security/oidc); [OIDC in AWS](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws); [dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching); [secrets reference](https://docs.github.com/en/actions/reference/security/secrets); [managing GitHub Actions settings for a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository); [about Actions policies](https://docs.github.com/en/actions/concepts/about-actions-policies); [keeping your actions up to date with Dependabot](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot).
- GitHub changelog entries, linked where each change is described (sections 21A.3, 21A.5, 21A.7, 21A.8, 21A.10, 21A.11, 21A.15).
- [actions/checkout README at v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md).
- Advisories and post-mortems: [CISA on tj-actions](https://www.cisa.gov/news-events/alerts/2025/03/18/supply-chain-compromise-third-party-tj-actionschanged-files-cve-2025-30066-and-reviewdogaction); [GHSA-mrrh-fwg8-r2c3](https://github.com/advisories/GHSA-mrrh-fwg8-r2c3); [Nx post-mortem](https://nx.dev/blog/s1ngularity-postmortem); [GHSA-69fq-xp46-6x23](https://github.com/advisories/GHSA-69fq-xp46-6x23); [Aqua incident notice](https://github.com/aquasecurity/trivy/discussions/10425); [TanStack post-mortem](https://tanstack.com/blog/npm-supply-chain-compromise-postmortem); [PyPI on Ultralytics](https://blog.pypi.org/posts/2024-12-11-ultralytics-attack-analysis/); [Codecov security update](https://about.codecov.io/security-update/).

#### Secondary sources


- [GitHub Security Lab: preventing pwn requests](https://securitylab.github.com/resources/github-actions-preventing-pwn-requests/) (2021; parts 2 to 4 of the series were not consulted).
- Vendor and researcher analyses: [Unit 42](https://unit42.paloaltonetworks.com/github-actions-supply-chain-attack/); [GitGuardian on GhostAction](https://blog.gitguardian.com/ghostaction-campaign-3-325-secrets-stolen/); [Wiz on Shai-Hulud 2.0](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack); [Datadog Security Labs](https://securitylabs.datadoghq.com/articles/litellm-compromised-pypi-teampcp-supply-chain-campaign/); [StepSecurity on hackerbot-claw](https://www.stepsecurity.io/blog/hackerbot-claw-github-actions-exploitation); [John Stawinski on PyTorch](https://johnstawinski.com/2024/01/11/playing-with-fire-how-we-executed-a-critical-supply-chain-attack-on-pytorch/).
- Secondary reporting only: [Techzine](https://www.techzine.eu/news/security/140524/ai-agents-on-github-leak-api-keys-via-prompt-injection/); [The Hacker News](https://thehackernews.com/2026/05/github-actions-supply-chain-attack.html).
- Tools: [zizmor audits](https://docs.zizmor.sh/audits/); [actionlint](https://github.com/rhysd/actionlint/blob/main/README.md); [OpenSSF Scorecard checks](https://github.com/ossf/scorecard/blob/main/docs/checks.md).

#### Videos

(from the Phase 0 report, with its caveats)


- [Adnan Khan, "The dark side of GitHub Actions"](https://www.youtube.com/watch?v=76NEylOsOS0), RomHack 2024, 53 min. The vulnerability classes are current; GitHub defaults have changed since.
- [Niek Palm, "Beyond the Commit: Weaponizing and Hardening GitHub Actions"](https://www.youtube.com/watch?v=19l6sLyR3zo), NDC Security 2026, 55 min. The most current defender-oriented talk; it pre-dates the June to September 2026 platform changes.
- ["Tag, You're Leaked: Surviving the tj-actions Supply Chain Attack"](https://www.youtube.com/watch?v=FxHIaRwc9c4), BSides PDX 2025, 24 min. An incident-response case study.

#### Further reading


- [GitHub's 2026 security roadmap for Actions](https://github.blog/news-insights/product-news/whats-coming-to-our-github-actions-2026-security-roadmap/): announced work, not shipped features.
- `workflows/ACTION_PINS.md` in this course: the pins and how to re-verify them.


## Modules 24 (GitHub part), 30 and 31: repository security and secret-leak response

### Chapter 21B: Repository security, identity, the Git client, and secret-leak response

From section 21B.27 of [Chapter 21B: Repository security, identity, the Git client, and secret-leak response](../textbook/ch21b-repository-security-incident-response.md).

#### Primary sources


- Git 2.55 manual pages: `git help git` (SECURITY), `git help config` (`safe.*`, `protocol.*`), `git help filter-branch` (WARNING), `git help hook`, `git help githooks`.
- [Git security advisories](https://github.com/git/git/security/advisories); [safe configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/safe.adoc); [protocol configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/protocol.adoc); [githooks](https://github.com/git/git/blob/v2.56.0/Documentation/githooks.adoc).
- GitHub Docs, fetched 2 October 2026: [removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository); [remediating a leaked secret](https://docs.github.com/en/code-security/tutorials/remediate-leaked-secrets/remediating-a-leaked-secret); [about push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection); [Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference). Through the Phase 0 report: [about secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning); [supported patterns](https://docs.github.com/en/code-security/secret-scanning/introduction/supported-secret-scanning-patterns); [commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification); [credential types](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/github-credential-types); [security features](https://docs.github.com/en/code-security/getting-started/github-security-features).
- [git-filter-repo manual](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt) (fetched 2 October 2026).

#### Secondary sources


- [GitGuardian, State of Secrets Sprawl 2026](https://www.gitguardian.com/state-of-secrets-sprawl-report-2026); [GitGuardian on leaked GitHub App private keys](https://blog.gitguardian.com/github-app-private-keys-leaked/).
- [Russ Cox, timeline of the xz open source attack](https://research.swtch.com/xz-timeline).
- The research, incident reports and articles linked where they are used, in sections 21B.4, 21B.8, 21B.10, 21B.14 and 21B.15.

#### Videos

(from the Phase 0 report, with its caveats)


- ["git-filter-repo for rewriting Git history"](https://www.youtube.com/watch?v=KXPmiKfNlZE), Elijah Newren, Git Merge 2024, 22 min. A contributor talk on what the tool does and how it compares with filter-branch and BFG; not a step-by-step incident tutorial.
- [Git Merge 2022 workshop on SSH commit signing](https://www.youtube.com/watch?v=uhy_ojFqLg0), listed by the roadmap for Module 24.
- ["Day-2: DevSecOps for Git and GitHub"](https://www.youtube.com/watch?v=Gd-AiV--LHs), Abhishek Veeramalla, 46 min, 22 January 2026. Shows a branch ruleset, CODEOWNERS, gitleaks through pre-commit and in Actions, and Dependabot together; no signing, OIDC or action pinning.

#### Further reading


- [Chapter 13: Recovery](../textbook/ch13-recovery.md) for reflogs, pruning and the GitHub-side recovery instruments; [Chapter 14B](../textbook/ch14b-config-tags-signing.md) for local signing; [Chapter 16](../textbook/ch16-authentication.md) for credential mechanics; [Chapter 12](../textbook/ch12-remote-operations.md) for force pushes.


## Modules 32 and 34: branching and release strategy, practices and design review

### Chapter 27: Open source and team workflows

From section 27.25 of [Chapter 27: Open source and team workflows](../textbook/ch27-open-source-team-workflows.md).

#### Primary sources


- Git 2.55 manual pages: `git help workflows` ([gitworkflows](https://git-scm.com/docs/gitworkflows)), `git help cherry-pick`, `git help rev-list` (`--cherry-pick`, `--left-right`), `git help branch`, `git help merge-tree`, `git help for-each-ref`.
- GitHub Docs: [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow), [Forks](https://docs.github.com/en/pull-requests/reference/forks), [Syncing a fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork), [About merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github), [Managing a merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue), [Setting guidelines for repository contributors](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors), [About releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).
- GitHub CLI 2.88.1, local help: `gh repo fork --help`, `gh repo sync --help`, `gh pr create --help`.
- The authors of the models: Vincent Driessen, [A successful Git branching model](https://nvie.com/posts/a-successful-git-branching-model/) with the 2020 note; Scott Chacon, [GitHub Flow](https://scottchacon.com/2011/08/31/github-flow/); GitLab, [What is GitLab Flow?](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/); [trunkbaseddevelopment.com](https://trunkbaseddevelopment.com/); Microsoft, [How Microsoft develops with DevOps](https://learn.microsoft.com/en-us/devops/develop/how-microsoft-develops-devops).
- DORA capability pages: [trunk-based development](https://dora.dev/capabilities/trunk-based-development/), [working in small batches](https://dora.dev/capabilities/working-in-small-batches/), [version control](https://dora.dev/capabilities/version-control/).
- Conventions: [How to Write a Git Commit Message](https://cbea.ms/git-commit/), [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/), [Semantic Versioning 2.0.0](https://semver.org/), [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).

#### Secondary sources


- The Phase 0 report of this course, sections 6, 12 and 13, and section 6 of its notes on books, documentation and misconceptions.
- Martin Fowler, [Patterns for Managing Source Code Branches](https://martinfowler.com/articles/branching-patterns.html); Pete Hodgson, [Feature Toggles](https://martinfowler.com/articles/feature-toggles.html); Rouan Wilsenach, [Ship / Show / Ask](https://martinfowler.com/articles/ship-show-ask.html).
- Lopes, Accioly, Borba and Menezes, interview-and-survey study of branching workflows, [arXiv 2507.08943](https://arxiv.org/abs/2507.08943).
- Vendor and company material, linked where used, each describing its own environment: GitHub and Shopify on merge queues, Atlassian on Gitflow.

#### Videos

(from the report's tables, with its caveats)


- [3 Git Workflows Every Developer Should Know](https://www.youtube.com/watch?v=GQQqf-C2ha4), TechWorld with Nana, 13 January 2026, 32 minutes: a neutral comparison of Git Flow, GitHub Flow and trunk-based development. Caveat: it has a sponsored segment.
- [Continuous Integration vs Feature Branch Workflow](https://www.youtube.com/watch?v=v4Ijkq6Myfc), Dave Farley, 6 January 2021, 18 minutes: the argued case for trunk. Caveat: deliberately one-sided advocacy; watch it after the first, and with section 27.13 beside you.
- [Implementing a Strong Code-Review Culture](https://www.youtube.com/watch?v=PJjmw9TRB7s), Derek Prior, RailsConf 2015, 38 minutes: review as teaching and context-giving. Tool-independent and still valid.

#### Further reading


- Jackson Gabbard, [Stacked Diffs Versus Pull Requests](https://jg.gg/2018/09/29/stacked-diffs-versus-pull-requests/), and Gergely Orosz, [Stacked Diffs](https://newsletter.pragmaticengineer.com/p/stacked-diffs).
- *Accelerate* (Forsgren, Humble, Kim, 2018), the book-length statement of the DORA research.
- [Chapter 28: AI/ML workflows](../textbook/ch28-ai-ml-workflows.md) applies this chapter to repositories that also hold notebooks, data pointers and evaluation runs.


## Module 33: AI/ML workflows

### Chapter 28: AI/ML workflows

From section 28.22 of [Chapter 28: AI/ML workflows](../textbook/ch28-ai-ml-workflows.md).

#### Primary sources


- Git 2.55 manual pages: `git help attributes` (filters, `text`, `merge`), `git help ignore`, `git help check-ignore`, `git help describe`, `git help status` (porcelain format), `git help worktree`, `git help apply`.
- Notebooks: [nbformat](https://nbformat.readthedocs.io/en/latest/format_description.html), [nbstripout](https://github.com/kynan/nbstripout/blob/main/README.md), [nbdime](https://nbdime.readthedocs.io/en/latest/) and its [Git integration](https://nbdime.readthedocs.io/en/latest/vcs.html), [jupytext](https://github.com/jupytext/jupytext/blob/main/README.md), [ReviewNB](https://www.reviewnb.com/), GitHub's [rich notebook diff preview](https://github.blog/changelog/2023-03-01-feature-preview-rich-jupyter-notebook-diffs/).
- Data and models: [About large files on GitHub](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github), [About Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage), [DVC: get started](https://doc.dvc.org/start), [DVC joins lakeFS](https://dvc.org/blog/dvc-joins-lakefs-your-questions-answered/), [lakeFS licence change](https://lakefs.io/blog/lakefs-business-source-license/), [Hugging Face download guide](https://huggingface.co/docs/huggingface_hub/guides/download), [MLflow model registry](https://mlflow.org/docs/latest/ml/model-registry/).
- Reproducibility: [MLflow system tags](https://mlflow.org/docs/latest/ml/tracking/tracking-api/), [W&B code saving](https://docs.coreweave.com/models/app/features/panels/code), [Hydra output directory](https://hydra.cc/docs/tutorials/basic/running_your_app/working_directory/), [uv project layout](https://docs.astral.sh/uv/concepts/projects/layout/) and [locking](https://docs.astral.sh/uv/concepts/projects/sync/), [Docker build best practices](https://docs.docker.com/build/building/best-practices/), [git-describe](https://git-scm.com/docs/git-describe).
- Hooks and CI: [pre-commit](https://pre-commit.com/), [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks/blob/main/README.md), [ruff-pre-commit](https://github.com/astral-sh/ruff-pre-commit/blob/main/README.md), [uv with GitHub Actions](https://docs.astral.sh/uv/guides/integration/github/), [larger runners](https://docs.github.com/en/actions/reference/runners/larger-runners), [push protection](https://docs.github.com/en/code-security/concepts/secret-security/push-protection), [promptfoo GitHub Action](https://www.promptfoo.dev/docs/integrations/github-action/), [DeepEval in CI](https://deepeval.com/docs/evaluation-unit-testing-in-ci-cd).
- Structure, Docker and Java: [Cookiecutter Data Science](https://github.com/drivendataorg/cookiecutter-data-science/blob/master/README.md), [PyPA on src and flat layouts](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/), [Docker build secrets](https://docs.docker.com/build/building/secrets/), [GitHub's Python ignore template](https://github.com/github/gitignore/blob/main/Python.gitignore), [Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html), [Dependabot ecosystems](https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories).

#### Secondary sources


- The Phase 0 report of this course, sections 14 and 15, and its notes on AI/ML workflows and security. Every version, date, licence and status in this chapter comes from there; its flags are carried as "Unverified" callouts.
- GitGuardian, [How to handle secrets in Jupyter notebooks](https://blog.gitguardian.com/how-to-handle-secrets-in-jupyter-notebooks/) and [State of Secrets Sprawl 2026](https://www.gitguardian.com/state-of-secrets-sprawl-report-2026): one vendor's measurements.
- DORA, [2025 report](https://dora.dev/research/2025/dora-report/) and [version control capability](https://dora.dev/capabilities/version-control/).
- StepSecurity and Techzine on agents in workflows, linked in section 28.15.

#### Videos

(from the report's tables, with its caveats)


- [MLOps: Day 4 - Data Versioning using DVC](https://www.youtube.com/watch?v=PPrPuxqWc7E), Vikash Das, in Hindi, 7 August 2024, 1 h 25 min: why Git alone does not suit data, DVC beside Git, an S3 remote, `dvc push` and `dvc pull`. Caveats: DVC CLI versions were not checked; no pipelines or CI.
- [How to build a ML project using MLOps](https://www.youtube.com/watch?v=eCjuoqUy8Is), CampusX, in Hindi, 25 November 2024, 1 h 21 min. Use it as a concept map only: the report notes no workflow YAML, no `dvc push` or `dvc pull`, and no remote storage.

#### Further reading


- [Chapter 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md) for filters, drivers and hooks in full; [Chapter 22](../textbook/ch22-git-lfs.md) for Git LFS; [Chapter 25: Worktrees](../textbook/ch25-worktrees.md) for the worktree used in Lab 33.3.
- [Chapter 27: Open source and team workflows](../textbook/ch27-open-source-team-workflows.md) for branching, release tags and the fork model that section 28.11 collides with.


## Module 35: the diagnosis method

### Chapter 29: Production Troubleshooting

From section 29.18 of [Chapter 29: Production Troubleshooting](../textbook/ch29-production-troubleshooting.md).

#### Primary sources


- The manual pages of Git 2.55.0, read locally with `git help -m <command>`: git-status, git-rebase, git-merge, git-cherry-pick, git-revert, git-bisect, git-bundle, git-update-ref, git-for-each-ref, git-ls-remote, git-merge-tree, git-check-ignore, git-fsck, git-config, gitrevisions, gitrepository-layout.
- `git-prompt.sh` as installed by Homebrew's Git at `/opt/homebrew/etc/bash_completion.d/git-prompt.sh`: the header comments document `__git_ps1`.
- GitHub Docs: [Using the activity view to see changes to a repository](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository); [REST: list repository activities](https://docs.github.com/en/rest/repos/repos#list-repository-activities); [Issue event types](https://docs.github.com/en/rest/using-the-rest-api/issue-event-types); [GitHub event types: PushEvent](https://docs.github.com/en/rest/using-the-rest-api/github-event-types#pushevent); [REST API endpoints for events](https://docs.github.com/en/rest/activity/events); [Viewing insights for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository#viewing-insights-for-rulesets); [Reviewing the audit log for your organization](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization); [Audit log for an enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/security-and-compliance/audit-log-for-an-enterprise); [Deleting and restoring branches in a pull request](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request); [Troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone); [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks).
- GitHub Changelog: [Upcoming changes to GitHub Events API payloads](https://github.blog/changelog/2025-08-08-upcoming-changes-to-github-events-api-payloads/).

#### Secondary sources


- Phase 0 report, sections 12 and 13, and the research notes `github_platform.md`, from which every GitHub-side fact and flag in section 29.8 is taken.
- Yang et al., the ACM TOSEM study of Git-command questions ([author preprint](https://cs.nju.edu.cn/changxu/1_publications/22/TOSEM22.pdf)). The report flags the final volume and article number as not confirmed.

#### Videos

(optional; the assessments in the Phase 0 report rest on captions, not on full viewing)


- [How to Undo Mistakes With Git Using the Command Line](https://www.youtube.com/watch?v=lX9hsdsAeTk), Tobias Günther for freeCodeCamp, 55 minutes, 24 November 2020: restore, amend, revert, reset, recovery with the reflog. Caveat: `master` naming.
- [Lecture 5: Version Control and Git](https://www.youtube.com/watch?v=9K8lB61dl3Y), MIT Missing Semester 2026, 1 hour 10 minutes: the data model before the commands, and the reflog as a safety net.

#### Further reading


- [Chapter 13: Recovery](../textbook/ch13-recovery.md), for every case in which something was lost.
- [Chapter 12: Remote Operations](../textbook/ch12-remote-operations.md), section 12.14, and [Chapter 16: Authentication](../textbook/ch16-authentication.md), sections 16.17 to 16.20, for the two other diagnosis procedures of this book.
- [Chapter 18: Branch Protection and Rulesets](../textbook/ch18-branch-protection.md), section 18.17, "Why can't I merge?".
- The [troubleshooting playbook](../playbooks/troubleshooting-playbook.md).


## Modules 36 to 38: incident drills, communication and postmortems

### Chapter 30: Incident Response

From section 30.27 of [Chapter 30: Incident Response](../textbook/ch30-incident-response.md).

#### Primary sources


- Local manual pages of Git 2.55.0: `git help reflog`, `git help push` (the lease forms), `git help rebase` (`--onto`, `--empty`), `git help cherry`, `git help range-diff`, `git help fsck`, `git help log` (history simplification, `--remerge-diff`), `git help describe`.
- GitHub Docs: [Activity view](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/using-the-activity-view-to-see-changes-to-a-repository); [deleting and restoring branches in a pull request](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request); [Events API](https://docs.github.com/en/rest/activity/events); [create a reference](https://docs.github.com/en/rest/git/refs#create-a-reference); [troubleshooting commits](https://docs.github.com/en/pull-requests/how-tos/commit-changes/troubleshooting-commits#a-commit-exists-on-github-but-not-in-your-local-clone); [available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#block-force-pushes); [removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository); [remediating a leaked secret](https://docs.github.com/en/code-security/tutorials/remediate-leaked-secrets/remediating-a-leaked-secret); [push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection).
- [actions/checkout README, v7.0.1](https://github.com/actions/checkout/blob/v7.0.1/README.md).
- The Phase 0 report, sections 12 to 14, including its unverified flags for the GitHub-side recovery recipe.

#### Secondary sources


- [git-filter-repo manual](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt), for the clean-up of other clones after a rewrite.
- Google, *Site Reliability Engineering*, [Postmortem Culture: Learning from Failure](https://sre.google/sre-book/postmortem-culture/).
- Julia Evans, [what can go wrong with rebasing](https://jvns.ca/blog/2023/11/06/rebasing-what-can-go-wrong-/).
- Truffle Security, [commits orphaned by force pushes](https://trufflesecurity.com/blog/guest-post-how-i-scanned-all-of-github-s-oops-commits-for-leaked-secrets): an observation by researchers, not a statement by GitHub.

#### Videos


- ["Tag, You're Leaked: Surviving the tj-actions Supply Chain Attack"](https://www.youtube.com/watch?v=FxHIaRwc9c4), BSides PDX 2025, 24 minutes. A 72-hour incident response for GitHub Actions; the Phase 0 report calls it the closest thing to a production incident-response case study, and notes that it found no conference talk covering end-to-end Git incident recovery with current tooling.

#### Further reading


- [Chapter 13: Recovery](../textbook/ch13-recovery.md), [Chapter 29: Production Troubleshooting](../textbook/ch29-production-troubleshooting.md), [Chapter 21B: Repository Security and Secret-Leak Response](../textbook/ch21b-repository-security-incident-response.md), [Chapter 20B: Delivery, Runners, Cost and Debugging](../textbook/ch20b-actions-delivery-debugging.md).


## Module 42: the frontier

### Chapter 14D: The Frontier

From section 14D.18 of [Chapter 14D: The Frontier](../textbook/ch14d-frontier.md).

#### Primary sources


- [BreakingChanges](https://git-scm.com/docs/BreakingChanges), read in the copy installed with Git 2.55.0, and the [release notes directory](https://github.com/git/git/tree/master/Documentation/RelNotes).
- [git-init](https://git-scm.com/docs/git-init), [git-config](https://git-scm.com/docs/git-config) (`init.*`, `safe.bareRepository`), [git-refs](https://git-scm.com/docs/git-refs), [hash-function-transition](https://git-scm.com/docs/hash-function-transition), [git-fast-export](https://git-scm.com/docs/git-fast-export), [git-fast-import](https://git-scm.com/docs/git-fast-import).
- [git-history](https://git-scm.com/docs/git-history), [git-replay](https://git-scm.com/docs/git-replay), [git-last-modified](https://git-scm.com/docs/git-last-modified), [git-repo](https://git-scm.com/docs/git-repo); for 2.56-only parts, [git-history at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/git-history.adoc) and [git-replay at 2.56](https://github.com/git/git/blob/v2.56.0/Documentation/git-replay.adoc).
- [git-format-patch](https://git-scm.com/docs/git-format-patch), [git-am](https://git-scm.com/docs/git-am), [git-apply](https://git-scm.com/docs/git-apply), [git-range-diff](https://git-scm.com/docs/git-range-diff), [git-patch-id](https://git-scm.com/docs/git-patch-id), [git-send-email](https://git-scm.com/docs/git-send-email), [SubmittingPatches](https://git-scm.com/docs/SubmittingPatches), [MyFirstContribution](https://git-scm.com/docs/MyFirstContribution), [maintain-git](https://github.com/git/git/blob/v2.56.0/Documentation/howto/maintain-git.adoc).
- The maintainer's message of 28 September 2026, through a [mailing-list mirror](https://ratatoskr.run/git/2026/09/17654892), as cited in the Phase 0 report.
- The [GitHub Changelog](https://github.blog/changelog/), with the entry on [stacked pull requests](https://github.blog/changelog/2026-07-30-stacked-pull-requests-are-now-in-public-preview/); the [Homebrew formula for Git](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/g/git.rb).

#### Secondary sources


- [LWN on the road to 3.0](https://lwn.net/Articles/1094575/) and [GitLab on Git 2.56](https://about.gitlab.com/blog/whats-new-in-git-2-56-0/): the only sources for calendar months. The Phase 0 report records a conflict between LWN's paraphrase and the primary message.
- The Phase 0 report of this course, section 1, with its table of flags.
- [Git Rev News](https://git.github.io/rev_news/); the repositories and documentation of [Jujutsu](https://github.com/jj-vcs/jj), [Sapling](https://sapling-scm.com/docs/introduction/) and [git-branchless](https://github.com/arxanas/git-branchless).

#### Videos

(optional; assessments in the Phase 0 report rest on captions, not on full viewing)


- [Reftable Backend: What it is, where it's headed and why should you care](https://www.youtube.com/watch?v=TqHYOGCJkS8), Patrick Steinhardt, 20 minutes, 3 September 2025. Caveat: assumes knowledge of internals.
- [SHA-256 at a Hyperscaler](https://www.youtube.com/watch?v=eJJp0RE7cd4), Emily Shaffer, Git Merge 2026, 32 minutes, uploaded 1 October 2026. Caveat from the report: almost no views when checked, so there is no secondary quality signal.
- [You Don't Know Git](https://www.youtube.com/watch?v=DZI0Zl-1JqQ), Edward Thomson, NDC London 2025, 1 hour 2 minutes: rerere, the reflog, worktrees and rebase variants.

#### Further reading


- [Chapter 3](../textbook/ch03-git-internals.md) for the formats, [Chapter 9](../textbook/ch09-rebase.md) for rebase, `--update-refs` and `git range-diff`, [Chapter 10](../textbook/ch10-cherry-pick.md) for patch IDs, [Chapter 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md) for hooks and their security.

## The video path as a whole

The chapters cite videos one at a time. The complete, ordered path, with length, date, level, what to learn from each and what is outdated in it, is section 7 of the [Phase 0 research report](../reports/Git%20and%20GitHub%20mastery%20research.md). Its finding is that a complete path exists only by combining about a dozen sources, and that no single video covers the full list of topics.

## See also

[Glossary](glossary.md) · [Git command reference](git-command-reference.md) · [GitHub reference](github-reference.md) · [command safety](command-safety.md)
