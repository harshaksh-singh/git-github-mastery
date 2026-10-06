# Exercise 7.10: what was reported

**Project:** `embed-gateway`. Releases are built from `release/2.4`. **Sandbox:** `server.git` (the company's Git server), the clones `you/`, `asha/` and `ravi/`, and one more bare repository that you will come across. Two weeks ago the project moved from the old Git host to `server.git`; everybody ran the platform team's migration script in their clones.

The release job, in the release channel:

> Built and deployed `release/2.4` at "Prepare changelog for 2.4.1". Smoke test failed: an embedding request with 300 texts was rejected by the provider (the limit is 96 per request).

Asha, who cut the release:

> The changelog says 2.4.1 splits requests into batches of 96, because Ravi told me yesterday that the hotfix was pushed. I pulled `release/2.4` before I wrote the changelog and there was no new commit on it. I assumed it had gone in earlier. I pushed my changelog commit with a plain `git push` and it was accepted without any complaint.

Ravi:

> It was pushed. The push printed `release/2.4 -> release/2.4` and afterwards `git status` said my branch was up to date with `origin/release/2.4`. This morning I ran `git fetch` and it printed a line with `(forced update)` for `origin/release/2.4`, and now `git status` says I have diverged. So somebody force-pushed the release branch and wiped my commit, and the only other person who pushed there is Asha. Forced pushes to release branches are forbidden for exactly this reason.

You know that `server.git` is a bare repository without reflogs, so the server cannot tell you who updated what.

What you are asked for: find out where Ravi's commit went and whether anybody forced anything; show the evidence for each claim above, true or false; get the hotfix onto `release/2.4` on the server on top of Asha's commit, without a forced push; and leave Ravi's clone in a state in which this cannot happen again.

When you think you are done, run `exercises/gen/m07-hotfix-not-deployed/check.sh` from the course root.
