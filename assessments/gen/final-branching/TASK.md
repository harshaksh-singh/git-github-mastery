# Final-test lab "branching": two commits without a branch

**Sandbox.** `assessments/gen/final-branching/generate.sh` builds the repository `driftwatch` and prints its path. Work in `labs/shell "<that path>"`, inside `driftwatch`.

**The situation.** Yesterday you checked out the release `v0.3.0` to reproduce a customer problem, fixed it on the spot in two commits, and went back to `main`. This morning `git log` on `main` does not show the two commits, and `git branch` shows no branch that has them. The team's naming rule asks for the branch name `fix/window-size`. When you try to create a branch with that name, Git refuses.

**The task.**

1. Find the two commits.
2. Put them, with their existing commit IDs, on a branch named `fix/window-size` that starts at the release `v0.3.0`.
3. Find out why Git refuses the name, and remove the obstacle without losing any commit.

**The end state that is checked.**

- `fix/window-size` points at the second of your two commits, and its grandparent is the commit of `v0.3.0`.
- `main` and the tag `v0.3.0` have not moved.
- No branch named `fix` exists, and the commit it pointed at is still reachable from `main`.
- HEAD is on `fix/window-size`, and `git status` is clean.

**Check.** `assessments/gen/final-branching/check.sh` from the course root.

**Hand in** with the check result: the command that showed you where the two commits were, and two sentences on why Git refused the branch name.
