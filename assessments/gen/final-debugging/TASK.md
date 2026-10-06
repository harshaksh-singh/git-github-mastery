# Final-test lab "debugging": the check that passed at 1.0

**Sandbox.** `assessments/gen/final-debugging/generate.sh` builds the repository `latencylab` and prints its path. Work in `labs/shell "<that path>"`, inside `latencylab`.

**The situation.** `sh check-p95.sh` passed at the tag `v1.0` and fails on `main`. The on-call engineer has already decided who is to blame: "it has to be the commit that raised the timeout". Nobody has verified that.

**The task.**

1. Find the first commit at which the check fails. Use a method that would still work with five hundred commits between the tag and `main`.
2. Show what that commit changed, and say in one sentence why the on-call engineer's suspect is not the first bad commit although it also touches the numbers.
3. Undo the first bad commit on `main` with a new commit whose message names the commit it undoes. Do not rewrite `main`. Every other change, including the raised timeout and the second region, stays in effect.
4. Leave no unfinished operation behind.

**The end state that is checked.**

- `main` contains everything it had, plus a commit that says which commit it reverts; that commit is the first bad one.
- The check passes on `main`; `check-p95.sh` itself is unchanged.
- HEAD is on `main` and `git status` is clean.

**Check.** `assessments/gen/final-debugging/check.sh` from the course root.

**Hand in** with the check result: the number of commits between `v1.0` and `main`, the number of commits your method tested, and the ID and subject of the first bad commit.
