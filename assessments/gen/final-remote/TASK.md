# Final-test lab "remote": pushed, and nobody can fetch it

**Sandbox.** `assessments/gen/final-remote/generate.sh` builds `origin.git` (the team's repository), `staging.git` (the demo environment deploys from its `main`) and the clones `you/` and `asha/` of the project `intentmap`, and prints the path. Work in `labs/shell "<that path>"`, inside `you`.

**The situation.** You created `feature/slot-carryover`, made two commits and ran `git push`. Git reported a new branch. Asha runs `git fetch` and says the branch is not there. You run `git push` again and Git says everything is up to date.

**The task.**

1. Establish with read-only commands where your two commits went, and which setting sent them there. Name the file that holds the setting.
2. Publish the branch in the team's repository, with `origin/feature/slot-carryover` as its upstream.
3. Remove the branch from the place where it does not belong. `main` in both server repositories must not move.
4. Remove the cause, so that a bare `git push` on a new branch can no longer go to the demo environment. The remote `staging` itself stays configured.

**Check.** `assessments/gen/final-remote/check.sh` from the course root.

**Hand in** with the check result: the three settings that decide which remote a bare `git push` uses, in their order of precedence, and the command that shows the push destination of a branch without pushing.
