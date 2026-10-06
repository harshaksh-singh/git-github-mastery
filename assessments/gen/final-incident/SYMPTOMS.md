# Final-test lab "incident": the bug that was fixed last month

**Sandbox.** `assessments/gen/final-incident/generate.sh` builds `server.git` and the clones `you/` and `ravi/` of the project `tokenbudget`, and prints the path. Work in `labs/shell "<that path>"`, inside `you`. You may look into `ravi/` with `git -C ../ravi <command>`.

## What people report

**Support, 09:10.** "A customer on 1.5.0 gets requests refused when a team has used exactly its token budget. We closed the same ticket in August. It was fixed in 1.4.1."

**Ravi, 09:25.** "It is fixed. I fixed it myself. Search the log for 'exactly reaches the budget', the commit is there. Somebody must have reverted it, or the 1.5.0 build is broken."

**The release manager, 09:40.** "1.5.0 was tagged from `main` on Friday and the tag is in production with three customers. Do not touch that tag."

## Your task

1. Establish with read-only commands whether the fix is in 1.5.0, and whether anything was reverted. Name the refs that contain the fix and the refs that do not.
2. State the root cause in the seven-line form of Chapter 1, section 1.10.
3. Repair with the lowest-risk change: the fix reaches `main` as one new commit that records which commit it was copied from, and that commit is released as the annotated tag `v1.5.1`. Push the branch and the tag.
4. Nothing that is published may move: `v1.5.0`, `v1.4.1` and `release/1.4` keep their values.

## Check

`assessments/gen/final-incident/check.sh` from the course root.

## Hand in

The evidence commands with one line of interpretation each, the root-cause box, and the four lines a CTO needs: what happened, the root cause with its layer, what was done and how it was verified, and the control that prevents a repeat.
