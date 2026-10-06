# Exercise 14.9: what was reported

**Project:** `redactor`. **Sandbox:** one repository, `redactor/`, on the branch `feature/names`. Generate it with `exercises/gen/m14-redactor/generate.sh`.

Your own notes from this morning:

> Yesterday a customer on 2.1.0 reported personal data in the logs. I did not want to disturb my feature branch, so I added a second working tree next to the repository, `../redactor-hotfix`, checked out at the release tag, and fixed two things there: ten-digit phone numbers and IBANs. Two commits. I was also halfway into a third pattern, for card numbers, which I had not committed.
>
> This morning the directory was in my way and `git worktree remove` refused, so I added `--force`.
>
> Now I cannot find the two commits. `git branch -a` has no branch for them. `git log --all` does not show them. `git reflog` shows nothing from yesterday afternoon except my feature branch. `git worktree list` shows one working tree.

What you are asked for:

1. Find the two commits and put them on a new branch named `hotfix/pii-patterns` that starts at `v2.1.0`. They must be the original commits.
2. Leave `feature/names` and its working tree as they are.
3. Say what happened to the third, uncommitted pattern, and why the HEAD reflog you looked at could not help.

When you think you are done, run `exercises/gen/m14-redactor/check.sh` from the course root.
