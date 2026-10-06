# Final-test lab "fork": a contribution made on the wrong branch

**Sandbox.** `assessments/gen/final-fork/generate.sh` builds `upstream.git` (the open-source project), `fork.git` (your fork, the part GitHub plays) and your clone `you/` of the project `spanlog`, and prints the path. Work in `labs/shell "<that path>"`, inside `you`. You have no push access to `upstream.git`; do not write to it.

**The situation.** You forked the project, cloned your fork, made two commits directly on `main` and pushed them to the fork. Then you read `CONTRIBUTING.md`: pull requests must come from a topic branch that starts at the project's current `main`, and the `main` of a fork is expected to be identical to the project's. The project has gained two commits since you forked.

**The task.** Reach the state from which a correct pull request can be opened.

- Your clone knows the project as the remote `upstream`.
- `main` in your fork and in your clone is identical to the project's `main`.
- Your two commits are on the branch `fix/utc-timestamps`, which starts at the project's current `main`, exists in your fork, and is the upstream of your local branch of the same name.
- One of the steps rewrites a published branch. Say which, why it is acceptable here, and use the safest form of the command.

**Check.** `assessments/gen/final-fork/check.sh` from the course root.

**Hand in** with the check result: the commands in the order you ran them, each with its risk label, and what you would have done differently if somebody else had already based work on your fork's `main`.
