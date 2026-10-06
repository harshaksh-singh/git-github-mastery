# Module 37 lab answers: incident drills, remote, platform, CI and security

> Read these after you have written your own answers. The full worked solution of each incident is in `solutions/incident-NN-<slug>.md`.

## Lab 37.1 (incident 2, [solution](incident-02-force-push-wrong-branch.md))

1. The branch had `origin/main` as its upstream (it was created from `origin/main`); `push.default` was `upstream`, so a bare push went to the upstream branch; and `--force` removed the fast-forward check. A fourth condition is on the server: it accepted a forced update of `main`.
2. Her commits were reachable on the server only through `main`. Once `main` is restored, no server ref reaches them. Her clone still has them, but a server-side copy under its own name costs one additive push and removes the dependency on her machine.
3. The push succeeds only if `main` on the server still equals the given ID. The bare form compares with the remote-tracking branch instead, which any background fetch updates silently; in an incident you want the condition to be the value you examined.
4. If someone had already built on, or deployed from, the bad tip, or if the forced-in commits were legitimate changes that only arrived the wrong way. A revert needs no forced update and every clone can fast-forward.
5. Their fetch printed `(forced update)` twice, or their `main` shows `ahead N, behind M`. Tell them: `git fetch`, then `git status -sb`; if `main` is not ahead, `git pull --ff-only`; if it is ahead, stop and send the output of `git cherry -v origin/main main`.

## Lab 37.2 (incident 4, [solution](incident-04-production-history-rewritten.md))

1. `range-diff` pairs commits by the similarity of their patches. One folded commit matches none of the four it replaced. The real question was about content, and `git diff --stat <old tip> <new tip>` answers it: two files, one of them a lost fix.
2. In the committer field (`%cn`) of the rewritten commit and in the reflog of the clone that rewrote it. Fixups and squashes keep the original author.
3. That the server's history was replaced. They should stop, not pull and not reset, and report it.
4. Keep: no further forced update, nobody has to realign again. Restore: the deployed tag stays an ancestor and every recorded commit ID stays valid. Here the IDs were recorded by the deployment process, and only one commit had been built on the rewrite.
5. `-`: the server already has an equivalent change; the local copy can go. `+`: the server lacks this change. If it is the retired rewrite commit, it can go; if it is real work, anchor it and cherry-pick it after the reset.

## Lab 37.3 (incident 6, [solution](incident-06-pr-500-changes.md))

1. The reflog of `origin/main` has a single entry and the merge base of the pull request equals the tip of `main`; the pushing clone's reflog of `origin/feature/snippet-highlight` shows two entries "update by push" and no forced update.
2. `--first-parent` follows only the branch's own line: his four commits and one merge. From his position the merge was one step, "update my branch"; the three commits of `develop` came in through its second parent.
3. After the pull request was merged, the commits of `develop` were ancestors of `main` (they came in with the feature branch), and the revert that undid their content was too. A merge of `develop` then finds nothing new to merge.
4. `<merge>` is the upstream limit: the commits after the merge are replayed. `<merge>^1` is its first parent, the branch as it was before the pull: the commits are replayed onto it.
5. That it covers a diff of two files that no longer existed in that form. It should be treated as void and renewed after the repair; with dismissal of stale approvals enabled, GitHub does that.

## Lab 37.4 (incident 7, [solution](incident-07-ci-passes-locally.md))

1. Re-runs fail identically, and the failures began with a specific commit (the one that added the step), on `push` and on `pull_request` alike. Flakiness is neither deterministic nor tied to a commit.
2. Workflow: one file, `ci.yml`. Event: `pull_request` and `push`, both failing. Permissions: `contents: read`, enough for the step. Runner: a fixed label. Environment, secrets, artifacts, cache, concurrency: not used. Action versions: both pinned by commit SHA.
3. `git describe` walks from HEAD through parent links until it meets a commit that a tag names. With depth 1 the walk ends at HEAD. Tag refs for commits that HEAD cannot reach do not help: "No tags can describe".
4. The code opens `templates/Summary.md.tmpl`; Git tracks `templates/summary.md.tmpl`. A case-insensitive filesystem opens the file anyway. `git ls-files templates` prints the name as the index stores it, whatever the filesystem tolerates.
5. No. The check is red for a real reason, the same reason on `main`, and it hides a second defect. The docstring waits for the fix; overriding a required check teaches that red is negotiable.

## Lab 37.5 (incident 3, [solution](incident-03-committed-secret.md))

1. Revoke or rotate the credential at its issuer. The damage happens where the secret is accepted; revocation works against every copy, including those you cannot reach, and every Git command before it is time in which the secret still works.
2. Deletion: `git show 76aa6c4:.env` still prints it. Only his branch: `git branch -r --contains 76aa6c4` lists two. Private: everyone with read access, and every clone and CI log, had it from the first push; visibility limits the audience, not the exposure.
3. `git -C ../server.git cat-file -t 76aa6c4` prints `commit`. On GitHub the equivalent is a request to GitHub Support, with the first changed commit and the number of affected pull requests.
4. A merge or pull joins the old commits to the new ones and makes them reachable again; one ordinary push then puts them back on the server. A rebase onto the new branch replays only the teammate's own commits.
5. When the credential is revoked and the data is harmless afterwards, on history that many people share: the rewrite then costs every clone, every recorded commit ID and every signature, and buys nothing that rotation did not.
