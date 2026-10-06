# Final-test lab "merge": two green branches, one red main

**Sandbox.** `assessments/gen/final-merge/generate.sh` builds `server.git` and the clones `you/`, `asha/` and `ravi/` of the project `answerbank`, and prints the path. Work in `labs/shell "<that path>"`, inside `you`.

**The situation.** This morning you merged two pull requests into `main`, one after the other, and pushed. Each branch had passed the smoke test (`sh tests/smoke.sh`). Neither merge reported a conflict. The smoke test now fails on `main`. Asha says her branch was green. Ravi says his branch was green. Both are right.

**The task.**

1. Show, with commands, which two changes collide and why Git reported no conflict.
2. Repair `main` so that the smoke test passes and both features remain. `main` is published: nothing that is on the server may be rewritten or removed.
3. Push.

**The end state that is checked.**

- `main` on the server still contains both merge commits and has at least one new commit.
- The smoke test passes on the server's `main`; the test script itself is unchanged.
- The renamed function and the bulk export are both still there.
- Your `main` equals the server's `main`, and your clone is clean.

**Check.** `assessments/gen/final-merge/check.sh` from the course root.

**Hand in** with the check result: the root cause in one sentence that names the layer, and the control that would have caught this before it reached `main`.
