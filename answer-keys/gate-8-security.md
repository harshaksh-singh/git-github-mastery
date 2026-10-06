# Answer key, Gate 8: Security

> **For the examiner.** This file holds the model answers, the marking guidance and the real outputs for [Gate 8](../assessments/gate-8-security.md). A learner who has failed the gate does not get this file: they get the remediation map in the gate file and variant B. The transcripts are real output of `labs/gates/g8-predict.sh` and `labs/gates/g8-evidence.sh` on Git 2.55.0; every "secret" in them is an obvious dummy. Nothing was run on GitHub. Every statement about GitHub is taken from the textbook section named in the reference line, which cites GitHub's documentation.

**Marking, in general.** This gate is defensive. Award points for the weakness, its mechanism, the repair and the prevention. Award nothing for an attack, and deduct the item if an answer contains a working one. In every incident item the order of actions is part of the answer: a response that cleans history before the credential is revoked earns at most half.

---

## Part 1: Concepts

### C1 (5 points)

**Model answer.** For every job GitHub Actions creates a short-lived installation token, `GITHUB_TOKEN`, for the repository that contains the workflow; it is valid for the job. What it may do is decided by the `permissions` key at workflow or job level; a scope that is not listed is `none`. Without any `permissions` key the token gets the repository's or organization's default, which is one of two settings: read and write for all scopes, or read for contents and packages only. The default is read-only for repositories, organizations and enterprises created since 2 February 2023; older ones keep the permissive default until someone changes it. So every workflow starts with a top-level `permissions:` block that is read-only (`contents: read`), and each job that needs to write adds exactly the scope it needs. That makes the file's behavior independent of a setting that the reader cannot see. For a `pull_request` run from a fork the token is read-only whatever the file says, secrets other than the token are not passed, and whether the run starts at all is a separate approval setting for outside contributors.

**Marking.** 1 point: what the token is and its scope and lifetime. 1 point: the `permissions` key, unlisted means none. 1 point: the default and the date. 1 point: read-only at the top, write per job. 1 point: fork runs.

**Common wrong answers.** "The token is my personal token." "The default is read-only" without the condition. "Fork pull requests get the secrets if the workflow asks for them."

**Reference.** Chapter 21A, sections 21A.3 and 21A.4.

### C2 (5 points)

**Model answer.** `pull_request_target` runs the workflow file from the base repository's default branch, not the contributor's version, with the base repository's token and secrets, in response to a pull request that a stranger can open. As long as the job works on metadata only (labels, comments), the stranger controls nothing that executes. It becomes a "pwn request" when the job checks out the pull request's head and then runs anything from it: a build, a test, an install script, a `Makefile`. The stranger's code then runs with the privileged token and the secrets. `workflow_run` and `issue_comment` have the same property when they fetch and run a fork's code. Safe designs: (1) keep `pull_request_target` for the privileged action and never check out or run pull request code, with the narrowest permissions; (2) split the work: an unprivileged `pull_request` workflow builds and tests the fork's code and uploads a result as an artifact, and a privileged `workflow_run` workflow downloads that artifact, treats it as untrusted data, and comments. Since `actions/checkout` v7 (18 June 2026, back-ported in July) the action refuses to fetch a fork pull request's head or merge ref under `pull_request_target`, and under `workflow_run` started by a pull request event, unless `allow-unsafe-pr-checkout: true` is set; the name is meant to be found in review.

**Marking.** 1 point: which file, token and secrets. 1 point: what makes it unsafe. 1 point: two other triggers. 1 point: the two designs. 1 point: the checkout change.

**Common wrong answers.** "`pull_request_target` runs the fork's workflow." "It is safe because the workflow file is ours." "Use it so that forks get secrets."

**Reference.** Chapter 21A, sections 21A.4 and 21A.5.

### C3 (5 points)

**Model answer.** An expression in `${{ }}` is replaced by its value in the text of the script before the shell starts. The template engine does not know that the result will be parsed by a shell. The title of a pull request is text that whoever opens the pull request chooses, so that text becomes part of the script: the shell receives a program that is partly written by an outsider, and it runs with the job's token and secrets. Outsider-controlled values include the title and body of a pull request or issue, comment bodies, branch names (`github.head_ref`), commit messages and author names and emails. Repair: pass the value through the environment, `env: TITLE: ${{ github.event.pull_request.title }}`, and use `"$TITLE"` in the script. The expression is then evaluated into an environment variable, the script text is constant, and the shell treats the value as data. The same applies to action inputs that are evaluated as code. Tools: CodeQL for workflows (GitHub code scanning), and the third-party linters zizmor (its `template-injection` audit) and actionlint. Review rule: every `${{ }}` inside `run:` is a finding until proven constant.

**Marking.** 1 point: substitution before the shell. 1 point: text becomes program, with the job's privileges. 1 point: four values. 1 point: `env:` and why it works. 1 point: a tool and the review rule.

**Common wrong answers.** "Quote the expression." (The quotes are part of the text the outsider can close.) "Only a problem with `pull_request_target`." (It is worst there; it is a weakness on any trigger whose job holds something of value.)

**Reference.** Chapter 21A, sections 21A.6 (root-cause box) and 21A.14.

### C4 (5 points)

**Model answer.** `uses: owner/action@v4` names a tag in someone else's repository. A tag is a movable ref: whoever controls that repository, or has compromised it, can point `v4` at different code, and the next run executes it. A full commit ID names one commit object; its content cannot change, so the code that runs next month is the code that was reviewed. Pinning to a full-length commit ID is, in GitHub's words, the only way to use an action as an immutable release. A compromised action can read every secret that the job receives and can use the job's token with whatever permissions it has. A pin does not protect against: code the action downloads at run time, a commit that was already malicious when it was pinned, a pin taken from a fork instead of the action's own repository, or the pin going stale and missing security fixes. Pins do not update themselves, which is the point; Dependabot proposes the updates, with the version as a comment beside the ID. Policies: "Require actions to be pinned to a full-length commit SHA", which makes unpinned workflows fail; the allowed-actions policy (only the owner's actions, or a selected list, with `!` entries to block a specific action or version); and the read-only default for workflow permissions.

**Marking.** 1 point: a tag is mutable. 1 point: a commit ID is immutable. 1 point: what a compromised action reaches. 1 point: two limits of a pin and who updates it. 1 point: two policies.

**Common wrong answers.** "Major version tags are maintained by GitHub and safe." "A pin makes the action trustworthy." "Pinning to a short ID is enough."

**Reference.** Chapter 21A, sections 21A.7 and 21A.8.

### C5 (5 points)

**Model answer.**

| After | Where the credential is | Who can reach it |
|---|---|---|
| the deleting commit is pushed | in the tree of every commit between the adding and the deleting commit; those commits are in the branch's history | anyone who can read the repository: `git log -S`, `git show <old commit>:<path>` |
| the force push back | in commits that are now unreachable from the branch but exist on the server, and are served by commit ID in cached views; in every clone and fork that fetched them; in pull request refs | anyone who has the commit ID or a clone made in the meantime |
| making the repository private | everywhere it was before | everyone who cloned, forked or scraped it while it was public |

A commit is a permanent snapshot: a later commit changes the next snapshot and leaves every earlier one intact, and moving or hiding refs changes who can easily find the old snapshot, not whether it exists. The one action that ends the exposure is to revoke or rotate the credential at its issuer. The window starts at the first push because from that moment copies can exist that the author does not control: fetches, forks, caches. Nothing done to the repository afterwards reaches those copies.

**Marking.** 1 point per row (3). 1 point: revoke or rotate. 1 point: the reason the window does not close.

**Common wrong answers.** "Force-pushing removes it." "Private means safe." "Nobody saw it, it was only there for a minute."

**Reference.** Chapter 21B, section 21B.10 (root-cause box).

### C6 (5 points)

**Model answer.** (1) Contain: revoke or rotate the credential first; that alone may be sufficient. Done later, the secret stays valid while everyone discusses Git. (2) Assess: what the secret is, who owns it, what it reaches; audit logs and the provider's logs for use; forks, deleted forks and force-pushed commits are in scope. Skipped, you do not know whether you have an exposure or a breach. (3) Eradicate: remove it from current code; rewrite history only where warranted, then force-push, then a request to GitHub Support. (4) Recover: update every dependent service with the new credential; after a rewrite, collaborators re-clone and force-push protection goes back on; partial rotation produces a second incident. (5) Communicate: tell collaborators exactly what to do with their clones; keep a disclosure contact. (6) Prevent: push protection, pre-commit and CI scanning, secrets out of code, short-lived credentials through OIDC, least privilege.

A whole-history rewrite replaces the first affected commit and every descendant with new commits that have new IDs. Signatures on rewritten commits and tags cannot stay valid. Open pull requests are based on old commits; tags must be rewritten or recreated; every existing clone holds the old history and can push it back. On GitHub the old objects survive as unreachable commits and cached views, in the read-only `refs/pull/N/head` refs and in forks: Support can collect garbage, remove cached views and dereference pull requests; forks belong to their owners. A rewrite is not warranted when rotation fully mitigates the risk, which for a credential is the normal case; it is for data that cannot be rotated.

**Marking.** 2 points: six steps in order (five in order 1). 1 point: rotation first and why. 1 point: what a rewrite changes. 1 point: what survives on GitHub and when a rewrite is not warranted.

**Common wrong answers.** Starting with the rewrite. "git filter-repo fixes it." "Support will purge it within the hour."

**Reference.** Chapter 21B, sections 21B.14, 21B.16 and 21B.19.

---

## Part 2: Prediction

### P1 (5 points)

<!-- snippet: gates/g8-predict/p1-answer -->
```text
$ git grep -c 'dummy-not-a-real' HEAD
[exit status: 1]
$ git log --format=%s -S'dummy-not-a-real'
Remove secrets from the repository
Add production settings
$ git log --format=%s -- config/prod.env
Remove secrets from the repository
Add production settings
$ for c in $(git rev-list HEAD); do git cat-file -e "$c:config/prod.env" 2>/dev/null && git log -1 --format=%s "$c"; done
Prefix notifications
Add production settings
$ git show HEAD~1:config/prod.env
SMTP_PASSWORD=dummy-not-a-real-password
```
<!-- /snippet -->

The tip no longer contains the string (exit status 1). The pickaxe lists the commit that added it and the commit that removed it. Two commits have the file in their tree: the one that added it and the unrelated commit after it, which is the point: every commit between the add and the delete carries the secret, whatever its subject says. The content is one command away.

**Marking.** 1 point: status 1. 1 point: two subjects from the pickaxe. 2 points: "Prefix notifications" and "Add production settings" (1 point if only the adding commit is named). 1 point: the dummy line is printed.

**Reference.** Chapter 21B, sections 21B.10 and 21B.11.

### P2 (5 points)

<!-- snippet: gates/g8-predict/p2-answer -->
```text
$ git ls-files
.gitattributes
.githooks/pre-commit
$ ls .git/hooks | grep -c -v "\.sample$" || true
0
$ git config get core.hooksPath
[exit status: 1]
$ git config get filter.strip.clean
[exit status: 1]
$ git check-attr filter notebook.ipynb
notebook.ipynb: filter: strip
```
<!-- /snippet -->

A clone receives objects and refs. Tracked files arrive, including the hook script under `.githooks/` and `.gitattributes`. Nothing under `.git` of the source arrives: not the `post-checkout` hook, not `core.hooksPath`, not the filter definition. `.gitattributes` still names the filter `strip`, and since no `filter.strip.clean` is configured in the copy, no program runs: an undefined filter is a no-op. The clone runs nothing of the author's until the user configures it to.

**Marking.** 1 point: the two tracked files. 1 point: zero hooks. 1 point: both settings absent. 2 points: the attribute is set and nothing runs.

**Reference.** Chapter 21B, sections 21B.2 and 21B.4.

### P3 (5 points)

<!-- snippet: gates/g8-predict/p3-answer -->
```text
$ git -C ../server.git log --graph --format=%s main
*   Merge branch 'main' of ../server
|\  
| * Extend app
* | Add notes
* | Extend app
* | Add key file
|/  
* Add app
$ git -C ../server.git log --format=%s -S'dummy-not-a-real' main
Add key file
$ git -C ../server.git cat-file -e main:keys.env
[exit status: 0]
```
<!-- /snippet -->

Asha's clone still had the old history. Her pull merged the rewritten `main` into it; the merge commit has the old tip and the new tip as parents. That merge commit descends from the server's current tip, so her push was a fast-forward and needed no force. The key file is back on `main`, and the old commits are reachable again.

**Marking.** 2 points: the graph with both "Extend app" commits and a merge with two parents. 1 point: "Add key file" is found. 1 point: status 0. 1 point: the fast-forward explanation.

**Reference.** Chapter 21B, sections 21B.17 and 21B.18 (root-cause box).

### P4 (5 points)

<!-- snippet: gates/g8-predict/p4-answer-a -->
```text
$ git push origin main
remote: rejected: refs/heads/main contains a secret pattern        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: gates/g8-predict/p4-answer-b -->
```text
$ git push -q origin main
[exit status: 0]
$ git -C ../server.git log --format=%s -S'dummy-not-a-real' main
Remove environment file
Add environment file
```
<!-- /snippet -->

The guard looks at the tree of the new tip only. The first push is rejected. The follow-up commit removes the file from the tip, the guard finds nothing, and both commits arrive: the secret is in the server's history. A guard has to examine every commit that the push introduces (for an update `git rev-list <old>..<new>`, for a new ref the commits not reachable from existing refs), and the developer has to remove the secret from the commits themselves, by amending or resetting before the push, not by adding a commit on top. The dummy token should be treated as leaked the moment it was committed anywhere it could be copied from.

**Marking.** 1 point: rejected, status 1. 2 points: accepted, status 0. 1 point: both subjects on the server. 1 point: what the guard must examine.

**Reference.** Chapter 21B, section 21B.12.

---

## Part 3: Hands-on diagnosis

### Variant A

#### Case 1 (12 points): 2 points per finding, up to six

In order of severity:

1. **A privileged trigger runs the stranger's code.** `on: pull_request_target`, a checkout with `ref: ${{ github.event.pull_request.head.sha }}`, then `make docs` and `make upload-preview`. The `Makefile` and everything it calls come from the fork and run with the base repository's token and secrets. Repair: do not build fork code in this workflow at all (see the design below).
2. **`allow-unsafe-pr-checkout: true`.** This is the line that should have stopped the reviewer first. `actions/checkout` v7 refuses this checkout by default; the line was added to make the refusal go away, and the documentation says to set it only after confirming that the checked-out code is never executed. Here it is executed two steps later.
3. **`permissions: write-all`.** The token can write to contents, pull requests, packages and more. Repair: top-level `contents: read`; a write scope only on the job that needs it.
4. **The secret is in the workflow-level `env`.** `PREVIEW_BUCKET_KEY` is in the environment of every step: the fork's `make`, and the third-party action. A secret is as exposed as the least trustworthy code in any job that receives it. Repair: reference it in the one step that uploads, in a job behind an environment, or replace it with OIDC.
5. **Script injection.** `${{ github.event.pull_request.title }}` inside `run:`. Repair: pass it through `env:` and use `"$TITLE"`.
6. **An unpinned third-party action.** `some-org/setup-docs-toolchain@v2` is a mutable tag in someone else's repository, running in a job that holds a secret. Repair: a full commit ID from the action's own repository, with the version as a comment; or remove the action.
7. **A self-hosted runner for outside pull requests on a public repository.** The machine persists between jobs and has its own network access. GitHub's guidance is that self-hosted runners should almost never be used for public repositories. Repair: a GitHub-hosted runner, or ephemeral runners.
8. **A cache in a privileged job, under a constant key.** A cache is a shared, unsigned directory; whoever can write an entry under that key controls what a later job restores. Repair: no cache in a job that holds a secret (`cache-mode: none`).
9. **The token stays in the Git configuration** of the checkout (`persist-credentials` is not set to `false`), where the fork's code can read it.

**The safe design (required for full marks on at least one finding).** Two workflows. An unprivileged `pull_request` workflow checks out and builds the documentation of the pull request, on a hosted runner, with a read-only token and no secrets, and uploads the built pages as an artifact. A privileged `workflow_run` workflow, triggered when the first completes, downloads the artifact, treats it as untrusted data (it uploads files; it executes nothing from the artifact), and holds the bucket credential in one step behind an environment.

**Common wrong answers.** "Add an approval step before the build" as the only repair (a maintainer who clicks approve has not read the `Makefile`). "Mask the secret." "Use `pull_request` and pass the secret to forks."

**Reference.** Chapter 21A, sections 21A.3 to 21A.9, 21A.11, 21A.12 and 21A.19.

#### Case 2 (9 points)

1. **The evidence (2 points).** The key is not in the tip of `main`. It is in two commits by the pickaxe (added by "Add deployment settings", removed by "Remove settings file, use the vault"), and in the tree of every commit between them. Refs that reach the adding commit: `main`, `feature/resume`, their remote-tracking counterparts, and the tag `v0.5.0`, whose tree still contains `deploy/settings.env`. `v0.4.0` predates it. Ravi's commit changed the next snapshot and nothing before it. The key is in the repository, and the repository has been public since Monday.
2. **The response (4 points).** In order: (a) the owner of the storage account revokes or rotates the key now; evidence: the old key is refused. This is first because it is the only action that ends the exposure, and it makes most of what follows a matter of hygiene. (b) Assess: the storage provider's access logs for the key since the first push; the repository's audit log; forks and clones since Monday; what the key could reach. (c) Update every service that used the key, from the vault. (d) Decide about history (below). (e) Tell the team what was exposed, since when, and what to do; open or update the incident record. (f) Prevent: push protection and secret scanning on the repository; a scanner in CI and before commit; no settings files with credentials in tracked paths. One point each for (a) first with its reason, (b), (c) plus (e), and (f).
3. **Rewrite or not (2 points).** Against: once the key is rotated the string in history is worthless, and a rewrite costs new IDs for every commit from "Add deployment settings" on, a new `v0.5.0` (a published tag must not move: a rewritten tag is a different release, and anyone who fetched the old one keeps it), invalid signatures, broken open pull requests, and a re-clone by everyone. For: the file also names the storage account, the repository is public, and scanners will keep reporting the string. If the team rewrites: `main`, `feature/resume` and `v0.5.0` must all be rewritten or deleted; the old commits stay on GitHub as unreachable objects, cached views and pull request refs until Support removes them; forks are out of reach.
4. **Elsewhere (1 point).** Clones and forks on other people's machines; CI logs and build artifacts that printed or packaged the settings; scanners' and search engines' caches; the laptop backups of whoever had the file; chat messages in which it was pasted.

**Common wrong answers.** "Ravi is right, it is gone." "Rewrite history now, then rotate." "Delete the tag and nobody has the key."

**Reference.** Chapter 21B, sections 21B.10, 21B.11, 21B.14, 21B.16 and 21B.19; Chapter 14B, section 14B.11.

#### Case 3 (9 points)

- **What happened (3 points).** The reflog of `origin/main` shows your two pushes (the last one the forced update to the clean history, tip "Retry uploads" with a new ID) and then a fetch that was a fast-forward. The new tip is a merge commit by Asha with two parents: her commit "Add README", which sits on the old history, and the clean tip. Her clone still had the old commits. She committed, pulled with a merge, and pushed. The merge commit descends from the clean tip, so for the server it was an ordinary fast-forward: blocking force pushes does not stop it.
- **The risk (1 point).** The key was rotated on Wednesday, so the string that is back on `main` opens nothing. If rotation had been skipped, the secret would be public again. The damage now is that the rewrite is undone, and the scanner is right.
- **Repair (3 points).** In order: freeze pushes to `main`. Set `main` on the server back to the clean tip with `git push --force-with-lease=main:<merge commit>` after temporarily allowing it, then restore the protection. Replay Asha's one commit onto the clean history (`git cherry-pick` of "Add README", or `git rebase --onto` the clean tip from her old base) and push that. Replace Asha's clone by a fresh one, or clean it: reset her branches to the new history and expire the old objects. Her clone must not be brought up to date with `git pull` or `git merge`: merging is what reconnected the old history.
- **Prevention (2 points).** Process: announce the rewrite, freeze, and have every collaborator re-clone or rebase onto the new history before pushing. Server: a check that rejects any push containing the first changed commit of the old history (git-filter-repo records it in `first-changed-commits`) or the secret pattern; on GitHub, push protection for the pattern.

**Common wrong answers.** "Someone force-pushed." "Revert the merge" (the old commits stay reachable). "Asha's commit is lost."

**Reference.** Chapter 21B, sections 21B.17 and 21B.18 (root-cause box).

### Variant B

#### Case 1 (12 points): 2 points per finding, up to six

1. **A privileged workflow executes an artifact from an untrusted run.** `workflow_run` fires when `ci` completes, for every run of `ci`, including runs started by pull requests from forks. The job downloads that run's artifact and runs `sh ./install.sh` from it, with `contents: write`, `packages: write`, an identity token and a cloud key. Artifacts from an untrusted run are untrusted input. Repair: never execute artifact content in a privileged job; and restrict when the job runs.
2. **No condition on what triggered the upstream run.** The job should run only when the upstream run was a `push` to the default branch and concluded with success: in words, "`github.event.workflow_run.event` is `push`, its head branch is `main`, and its conclusion is `success`". Publishing in response to a pull request run is the fault.
3. **Script injection through the branch name.** `${{ github.event.workflow_run.head_branch }}` inside `run:`; a branch name is chosen by whoever opened the pull request. Repair: `env:`.
4. **A long-lived cloud key while an identity token is available.** `id-token: write` lets the job request a signed statement of what it is, which the cloud exchanges for a credential valid for that job only. The workflow grants the permission and then uses a stored key anyway. Repair: OIDC federation with a trust condition on repository, ref and environment; delete the stored key.
5. **Permissions at workflow level, wider than needed.** Every job of the file gets write access to contents and packages and can request an identity token. Repair: `contents: read` at the top; the write scopes and `id-token: write` only on the publishing job.
6. **No environment.** A job that publishes should name an environment with required reviewers or a branch restriction; that is where the human gate belongs, and the environment also holds the cloud trust condition.
7. **A third-party action on a branch.** `some-org/notify-channel@main` runs whatever that branch holds at the time, in the job that has the cloud credential. Repair: pin to a full commit ID, and move the notification to a separate job without secrets.

**Common wrong answers.** "`workflow_run` is safe because the file is on our default branch." "The artifact was built by our CI, so it is ours." "Keep the key and add masking."

**Reference.** Chapter 21A, sections 21A.3, 21A.5 to 21A.7, 21A.9 to 21A.11, 21A.13 and 21A.19.

#### Case 2 (9 points)

1. **The evidence (2 points).** The first search covers the refs a normal clone has: `main` and its remote-tracking refs. `main` holds the squash commit, whose tree has the cleared notebook, so nothing is found. `git ls-remote` shows a third ref on the server, `refs/pull/12/head`. After fetching it, the pickaxe finds both of Asha's original commits: the one that added the key and the one that cleared the output. Only the pull request ref reaches them.
2. **Why "nothing to clean up" does not follow (3 points).** Git: clearing the output made a new snapshot; the first commit still has the key. Git: a squash merge wrote one new commit on `main` from the final tree, so `main` never had the key, true. GitHub: deleting the branch removed one ref; GitHub: the pull request keeps `refs/pull/12/head`, which is read-only for users and keeps the original commits reachable, and the pull request page shows them. Anyone who can read the repository can fetch that ref.
3. **The response (3 points).** Rotate or revoke the API key first: that makes the rest optional for security purposes. Assess its use in the provider's logs. Rewriting `main` achieves nothing: `main` is clean. What remains is on the platform side: the pull request ref and cached views, which only GitHub Support can dereference or delete, and which Support assists with where rotation cannot mitigate the risk. Tell Asha and the reviewers; record it.
4. **Prevention (1 point).** In the repository: a clean filter or pre-commit step that strips notebook outputs, so that outputs never reach a commit. On the platform: push protection, which rejects the push that contains the key.

**Common wrong answers.** "Squash merging removed it." "Delete the pull request ref with `git push --delete`" (it is read-only on GitHub; a bare repository in a lab would allow it, GitHub does not). "Rewrite `main`."

**Reference.** Chapter 21B, sections 21B.10, 21B.11, 21B.14 and 21B.19; Chapter 28, section 28.3.

#### Case 3 (9 points)

- **What is wrong and where it travelled (3 points).** A token is embedded in the remote URL. It is in `.git/config` in plain text, readable by every process and user that can read the clone; `git remote -v` prints it, so it is in terminal scrollback and in any CI log that prints remotes; it is in backups and images of the build server; it may be in shell history from the command that set it; and error messages of older tools print the URL.
- **Response (3 points).** Revoke the token at its issuer first, and issue a new credential for the job by a route that is not a URL. Review the issuer's and the server's logs for use of the token. Then clean the clone. Then look for the same pattern in the other clones on the server (`git config get --show-origin --all remote.origin.url` in each, or a search of the `config` files).
- **The setting and the repair (2 points).** `transfer.credentialsInUrl=die` makes Git refuse to use a URL that contains a plaintext credential. `git remote set-url` reads the remote's configuration before changing it, and reading the bad URL is what the setting forbids, so the repair command itself dies. Write the configuration key directly:

<!-- snippet: gates/g8-evidence/b3-fix -->
```text
$ git config set transfer.credentialsInUrl die
$ git remote set-url origin https://git.example.com/acme/reports.git
fatal: URL 'https://ci-bot:<redacted>@git.example.com/acme/reports.git' uses plaintext credentials
[exit status: 128]
$ git config set remote.origin.url https://git.example.com/acme/reports.git
$ git remote -v
origin	https://git.example.com/acme/reports.git (fetch)
origin	https://git.example.com/acme/reports.git (push)
```
<!-- /snippet -->

- **How the job should authenticate (1 point).** With a credential that belongs to the job and not to a person, scoped to this one repository and short-lived: a GitHub App installation token, or a read-only deploy key; supplied through a credential helper or the environment at run time, never stored in the clone. If it leaks, its scope (one repository, read-only) and its lifetime limit the damage.

**Common wrong answers.** "Change the URL" as the whole answer. "The token is fine, the server is internal." "Put the token into an environment variable and keep the URL form `https://$TOKEN@...`", which writes it into the configuration again.

**Reference.** Chapter 16, sections 16.6, 16.7 (root-cause box) and 16.14.

---

## Part 4: Oral interview

O1 to O4: 3 points for a complete answer with the follow-up, 2 for a correct answer with a weak follow-up, 1 for a list without mechanism. O5 and O6: 4, 3, 2 or 1 on the same scale, the fourth point for the production consequence.

### O1 (3 points)

**Model answer.** A workflow run is a program that GitHub starts for me with a credential for my repository, so its safety depends on who controls its code and its inputs. I go through that in order: triggers (anything with `pull_request_target`, `workflow_run`, `issue_comment`: does outsider-controlled input reach the job, is fork code checked out); the token (`permissions` read-only at the top, write per job); expressions inside `run:`; third-party actions pinned to commit IDs; secrets referenced in the narrowest place, behind environments, replaced by OIDC where possible; caches and artifacts treated as untrusted in privileged jobs; runners; and code owners plus a ruleset for `.github/workflows/`. *Follow-up:* the repository default for workflow permissions to read-only, because it covers every workflow that has no `permissions` key at once; the policy that requires actions to be pinned to a full commit ID (after pinning the existing ones); and a workflow scanner on pull requests, so that the next weakness is found by a machine. Each of the three moves a rule from "every author must remember" to "the platform refuses".

**Weak answer.** "Use secrets and do not print them." **Reference.** Chapter 21A, sections 21A.2, 21A.8, 21A.16 and 21A.19.

### O2 (3 points)

**Model answer.** First I make sure the credential is revoked or rotated; investigation comes second. Then: which string, in which commits (`git log --all -S`), which refs reach them (`git for-each-ref --contains`), including tags and pull request refs; since when it has been on the server and whether the repository was public; what the credential reaches; and the provider's and GitHub's audit logs for use. *Follow-up:* has the credential been rotated, because then the rewrite buys little; can it be rotated at all; which refs and tags are affected; who has clones and forks; are open pull requests and signatures expendable; who will tell every collaborator to re-clone; and is someone ready to file the Support request for cached views and pull request refs. A rewrite within the hour, without a freeze, is how the secret comes back the next morning.

**Weak answer.** "Search the code for the key and delete it." **Reference.** Chapter 21B, sections 21B.11 and 21B.14.

### O3 (3 points)

**Model answer.** "Private" limits who can read the repository today. It does not limit who has a clone, which integrations and tokens can read it, what a compromised developer account or laptop exposes, or what happens when the repository is made public or forked later. A credential in a repository is as exposed as the least protected copy of that repository, and a stolen credential pushes and reads as its owner. *Follow-up:* in a secret store: repository or, better, environment secrets for workflows, a vault for services, nothing in tracked files. A long-lived cloud key in a deployment job is replaced by OIDC federation: the job requests a signed statement of what it is, and the cloud exchanges it for a credential that is valid for that job only, under a trust condition on repository, ref and environment.

**Weak answer.** "Private repositories are encrypted." **Reference.** Chapter 21B, sections 21B.8 and 21B.10; Chapter 21A, sections 21A.9 and 21A.10.

### O4 (3 points)

**Model answer.** Masking replaces registered secret values in log output. It is a courtesy for logs: a value that is transformed (encoded, split, embedded in structured data) is not recognized, and code that holds the secret can send it anywhere without printing it. The boundary is which code receives the secret. *Follow-up:* only the job that deploys, and in it only the step that needs the value. Enforcement: the secret lives in an environment, the job names that environment, and the environment's rules (required reviewers, allowed branches) must pass before the job starts and before the secret is readable. No `secrets: inherit` by habit, no workflow-level `env` for secrets.

**Weak answer.** "GitHub hides secrets, so they cannot leak." **Reference.** Chapter 21A, sections 21A.9 and 21A.13.

### O5 (4 points)

**Model answer.** First hour: stop the bleeding by disabling the action through the allowed-actions policy (a blocking entry) or by pinning every use to a known good commit ID; then find the runs. Which workflows use it (`git grep` across repositories, or code search), which runs executed during the window in which the tags pointed at the bad commit, and what those jobs could reach: their secrets and their token permissions. Every secret that such a job received is treated as leaked and rotated, starting with the ones that reach production; logs of those runs are checked and, if they contain secrets, deleted after evidence is kept. *Follow-up:* pinning to full commit IDs, which makes a moved tag irrelevant; read-only default tokens; secrets scoped to the job that needs them, behind environments; OIDC in place of stored cloud keys, so that there is nothing long-lived to print; and the pinning policy, so that it does not depend on every author. This is the tj-actions/changed-files case of March 2025: tags repointed to a commit that printed secrets.

**Weak answer.** "Update to the fixed version." **Reference.** Chapter 21A, sections 21A.7, 21A.8 and 21A.18.

### O6 (4 points)

**Model answer.** Cloning and reading is generally safe. A clone receives objects and refs; its `.git` is created from my own Git's template, with no active hooks and only the configuration that `git clone` writes. Nothing the author configured executes. The limits: `--recurse-submodules` has been the recurring source of vulnerabilities, so I clone without it, read `.gitmodules`, then decide; and the content can still be code that I later choose to run, such as a `Makefile`, a notebook, or a tracked hooks directory that a README asks me to enable. *Follow-up:* a zip with `.git` inside is the author's own repository directory: their hooks and their configuration, where an alias, a pager, an `fsmonitor` setting, a filter or a credential helper can name a command. Running any Git command inside it can execute what they wrote. I do not run Git in it. I clone from it into a new directory (`git clone` from the unpacked path gives me a fresh `.git`), or read it with `safe.bareRepository=explicit` in place, and I read `.git/config` and `.git/hooks` as text first. In production this is the contractor hand-over and the support ticket with an attached repository.

**Weak answer.** "Yes, Git never runs code." **Reference.** Chapter 21B, sections 21B.2 to 21B.4.
