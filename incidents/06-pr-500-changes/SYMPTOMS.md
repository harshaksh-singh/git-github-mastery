# Incident 6: what was reported

**Project:** `doc-search`. **Sandbox:** `server.git` (the server), `you/`, `asha/`, `ravi/`. There is no GitHub in the sandbox. "The pull request" is the comparison GitHub would show for `feature/snippet-highlight` into `main`: the commit list `main..feature/snippet-highlight` and the diff `main...feature/snippet-highlight`.

Ravi, in the channel:

> GitHub has broken my pull request. Yesterday it was three commits and two files, it had one approval. I pushed ONE small commit this morning (highlight every query term, it touches a single file) and now the pull request says 500+ files changed and lists commits by Asha that have nothing to do with my work. I did not force-push anything, the push went through normally. Did somebody rewrite `main`? Or change the base of my pull request?

Asha:

> I have not touched `main` in days, and I never pushed to Ravi's branch.

The approval on the pull request is still shown, which worries the team lead more than the file count.

What you are asked for: find out where the 500 changes come from, give Ravi his small pull request back in a way that will not cause a second problem when `develop` is released later, and state what a reviewer should conclude about the approval.

When you think you are done, run `incidents/06-pr-500-changes/check.sh` from the course root.
