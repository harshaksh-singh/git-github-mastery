# GitHub CLI cheat sheet

GitHub CLI 2.88.1; flags checked with `gh <command> --help`; no command here was run against GitHub. Legend: 🟢 SAFE reads state or only adds objects · 🟡 CAUTION changes state that you can set back if you know how (on GitHub: settings, objects that notify people, runs) · 🔴 DANGEROUS can destroy remote history or the safety net itself (on GitHub: objects that no clone contains, and tokens printed to a screen). The placeholders in capitals (ORG/REPO, N, TAG, RUN_ID, ID, NAME, FILE) are yours to fill.

Layer: `gh` is a GitHub client, not Git. It calls the REST and GraphQL APIs with a stored token and runs `git` where a task needs both (15.16). The number in brackets after each purpose is the textbook section; concepts are in the [GitHub reference](../reference/github-reference.md).

Three rules for every table below (15.16):

- **Which repository.** Inside a clone `gh` picks it from your remotes; override with `-R OWNER/REPO` or `GH_REPO`.
- **Which token.** `GH_TOKEN` in the environment takes precedence over the stored login.
- **Scripts.** Use `--json FIELDS` with `--jq`, and test exit codes: 0 success, 1 failure, 2 cancelled, 4 authentication required; `gh pr checks` adds 8 for pending checks. `gh help formatting`, `gh help exit-codes` and `gh help environment` 🟢 print the details.

## Authentication

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `gh auth login` | Browser flow; stores a token in the system credential store and can configure Git (16.5) | `gh auth login` | 🟡 | Putting a token on a command line or in a URL, where shell history and logs record it (16.7) | Revoke that token; pass one on standard input: `gh auth login --with-token < FILE` |
| `gh auth status` | Per host: active account, where the token is stored, its scopes; exits 1 on a problem (16.5) | `gh auth status` | 🟢 | Debugging "Repository not found" or a 403 without first asking which account the server sees (16.19) | not needed |
| `gh auth setup-git` | Makes `gh` the Git credential helper for the host, in the global configuration (16.5) | `gh auth setup-git` | 🟡 | "`gh` works, `git push` over HTTPS does not": Git is not using `gh`'s token (16.21) | Preview with `git config get --show-origin --all credential.helper`; set the previous value or `git config unset` |
| `gh auth switch` | Changes the active account of a host (16.13) | `gh auth switch` | 🟡 | Expecting a per-directory identity: the switch is global | Switch back; for two identities on one day prefer SSH host aliases (16.13) |
| `gh auth refresh` | Adds a scope to the stored token (15.10) | `gh auth refresh -s project` | 🟡 | Running `gh project` without the `project` scope | Run the refresh, then repeat the command |
| `gh auth logout` | Removes the stored token locally (16.22) | `gh auth logout` | 🟡 | Taking it for revocation: the help says it "does not revoke authentication tokens" | `gh auth login` again; only GitHub can revoke a token |
| `gh auth token`, `gh auth status --show-token` | Print the live token (16.23) | `gh auth token` | 🔴 | Printing a live token into terminal scrollback | Revoke the token |

## Repositories

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `gh repo view` | Reads repository fields (15.2, 15.5) | `gh repo view --json defaultBranchRef` | 🟢 | Parsing human-readable output in a script (15.21) | not needed |
| `gh repo clone` | Clones; for a fork it also adds the remote `upstream` (15.7) | `gh repo clone OWNER/REPO` | 🟢 | Taking the `upstream` remote for the fork relationship, which is a GitHub object | Delete the clone |
| `gh repo create` | Creates the repository, adds the remote and pushes (15.16) | `gh repo create ORG/REPO --public --source=. --remote=origin --push` | 🟡 | Not checking `--public` or `--private`: what reached a public repository is published (15.22) | `gh repo delete` |
| `gh repo fork` | Creates a fork; with `--clone`, a clone whose remotes are the fork and its parent (15.7, 27.2) | `gh repo fork OWNER/REPO --clone` | 🟡 | Committing on the fork's default branch, which then cannot be synced (17.19) | Move the commits to a branch; delete the fork |
| `gh repo set-default` | Records which repository `gh` queries in a clone with two candidates (15.16) | `gh repo set-default OWNER/REPO` | 🟡 | `gh` acts on the wrong one of fork and upstream (15.20) | `gh repo set-default --view`, then set it, or pass `-R` |
| `gh repo edit` | Changes settings: features, merge methods, default branch, forking, auto-merge (15.5, 17.10) | `gh repo edit --delete-branch-on-merge` | 🟡 | Forgetting that your clone still needs `git fetch --prune` after branches are deleted on merge (15.5) | Set the previous value |
| `gh repo sync` | Fast-forwards a fork's branch from its parent; without an argument it updates the local repository instead (15.7, 27.3) | `gh repo sync OWNER/FORK` | 🟡 | Naming no destination and updating the wrong side | Preview with `git log HEAD..upstream/main` |
| `gh repo sync --force` | Hard-resets the destination branch to its source (15.7, 17.15) | `gh repo sync OWNER/FORK --force` | 🔴 | Using it as the first move when the fork cannot be fast-forwarded: commits on the fork's branch are discarded | Push the old commits back from a clone that still has them; preview with `git log upstream/main..origin/main` after a fetch |
| `gh repo edit --visibility` | Changes visibility; also needs `--accept-visibility-change-consequences` (15.5) | `gh repo edit --visibility VISIBILITY --accept-visibility-change-consequences` | 🔴 | Expecting "private" to take back what was cloned or forked while public | Visibility can be changed back; its side effects (stars, watchers, detached forks) cannot |
| `gh repo archive`, `gh repo rename`, `gh repo delete` | Change the repository's writability, URL or existence (15.22) | `gh repo archive OWNER/REPO` | 🔴 | Not asking who depends on the URL | A deleted repository: restore within 90 days unless its fork network is not empty |
| `gh repo deploy-key list` | Lists deploy keys, which are not membership (15.20) | `gh repo deploy-key list` | 🟢 | Offboarding a person and leaving the keys they created | Remove the key; rotate what it could read |

## Issues and labels

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `gh issue create` | Opens an issue (15.16) | `gh issue create --title "TITLE" --body "BODY" --label bug` | 🟡 | Forgetting that it notifies people (15.22) | Close it; notifications are not recalled |
| `gh issue list`, `gh issue view` | Read issues (15.8) | `gh issue list` | 🟢 | Forgetting that issue endpoints also return pull requests (15.8) | not needed |
| `gh issue close` | Closes an issue by hand (15.8) | `gh issue close N` | 🟡 | Expecting `Fixes #N` to close it when the pull request targets a branch other than the default branch | Close by hand; document how issues close on release branches |
| `gh issue develop` | Creates a branch linked to issue N and switches to it (15.8) | `gh issue develop N --checkout` | 🟡 | Looking for type or parent flags: `gh issue create --type` and `--parent` arrived in 2.94.0 | not stated in the textbook |
| `gh label list` | Lists labels (15.9) | `gh label list` | 🟢 | Treating a milestone named `v0.3.0` as a tag or a release | not needed |
| `gh label create`, `gh label clone` | Create a label; copy a label set from another repository (15.9) | `gh label clone ORG/REPO` | 🟡 | Looking for a milestone command: 2.88.1 has none; use `gh api repos/{owner}/{repo}/milestones` | Delete the labels |

## Pull requests

All from section 17.16 unless another section is named.

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `gh pr create` | Opens a pull request; may first push the branch. From a fork, `--repo ORG/REPO` names the upstream repository (27.2) | `gh pr create --base main --title "TITLE" --body "Fixes #N"` | 🟡 | Omitting `--base`: the default branch is used, and the pull request lists commits you did not write (17.12) | `gh pr edit N --base BRANCH`, or `gh pr close N` |
| `gh pr create --draft --fill` | Title and body from the commits; opens as a draft | `gh pr create --draft --fill` | 🟡 | Expecting code owners to be requested on a draft (17.4) | `gh pr ready N` |
| `gh pr create --dry-run` | Prints what would be created | `gh pr create --dry-run` | 🟡 | Assuming nothing happens: it "may still push" | not stated in the textbook |
| `gh pr status`, `gh pr list`, `gh pr view`, `gh pr diff` | Read pull requests | `gh pr view N --json mergeable,mergeStateStatus,reviewDecision` | 🟢 | Treating `mergeable` `UNKNOWN` as "not mergeable": it is not computed yet, ask again (18.17) | not needed |
| `gh pr checks` | Shows checks; exit status 8 while pending (17.16, 20B.14) | `gh pr checks N --required` | 🟢 | Waiting for a required check that a skipped workflow will never report (18.8) | not needed |
| `gh pr checkout` | Creates a local branch for the head of pull request N; does the `refs/pull/N/head` fetch for you (17.2) | `gh pr checkout N` | 🟢 | Running it on fork code inside a privileged workflow job (21A.5) | Delete the local branch |
| `gh pr review` | Submits a review | `gh pr review N --approve` | 🟡 | Approving your own pull request: GitHub does not allow it (17.4) | A review can be dismissed with a comment (17.5) |
| `gh pr ready` | Draft to ready; `--undo` goes back | `gh pr ready N` | 🟡 | Marking ready before you want code owners requested (17.4) | `gh pr ready N --undo` |
| `gh pr edit --base` | Changes the base branch | `gh pr edit N --base main` | 🟡 | Forgetting that a base change can dismiss approvals (17.21) | Change the base back |
| `gh pr update-branch` | Merges the base into the head; `--rebase` rebases | `gh pr update-branch N` | 🟡 | Continuing locally without pulling: the head branch on GitHub moved and yours did not (17.7) | `git pull` before you continue |
| `gh pr merge` | Merges with the chosen method | `gh pr merge N --squash --delete-branch` | 🟡 | Merging a head that changed after the approval | `gh pr revert N`; prevent with `--match-head-commit "$(git rev-parse HEAD)"` |
| `gh pr merge --auto` | Stores the instruction to merge when requirements are met; `--disable-auto` withdraws it (17.10) | `gh pr merge N --auto --squash` | 🟡 | Enabling it where nothing is required: there is nothing to wait for | `gh pr merge N --disable-auto` |
| `gh pr merge --admin` | Merges without the required reviews and checks; bypasses a merge queue (17.11, 18.21) | `gh pr merge N --admin` | 🔴 | Using it outside a documented emergency | `gh pr revert N`; record the reason. Preview: `gh pr checks N --required` |
| `gh pr close` | Closes without merging | `gh pr close N --comment "Superseded by #M" --delete-branch` | 🟡 | Believing the commits are gone: they stay under `refs/pull/N/head` (17.2) | not stated in the textbook |
| `gh pr revert` | Opens a new pull request that reverts the merge (17.9) | `gh pr revert N` | 🟡 | Re-merging the branch after reverting a merge commit: nothing comes back until you revert the revert (17.9) | Revert the revert |

## Releases

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `gh release list`, `gh release view` | Read releases (15.2) | `gh release view TAG` | 🟢 | Looking for a release in a clone: only the tag is Git data | not needed |
| `gh release download` | Downloads assets (15.22) | `gh release download TAG` | 🟢 | not stated in the textbook | Delete the files |
| `gh release create --verify-tag` | Creates a release on an existing tag; refuses if the tag does not exist (15.12) | `gh release create TAG --verify-tag --generate-notes --draft` | 🟡 | Publishing before the assets are attached; for immutable releases the order is draft, assets, publish | Close or delete; notifications are not recalled |
| `gh release create` without `--verify-tag` | May create the tag on the default branch, or from `--target`, and start tag workflows (15.12) | `gh release create TAG` | 🔴 | A typo in the version variable creates a tag nobody intended | Delete release and tag; consumers may have fetched it. Preview: `git ls-remote --tags origin TAG` |
| `gh release delete --cleanup-tag` | Deletes the release and its tag; without the flag the tag stays (15.12) | `gh release delete TAG --cleanup-tag` | 🔴 | Removing a published version's name | Re-create from the recorded commit ID. Preview: `gh release view TAG` |
| `gh release verify` | Checks the attestation of an immutable release (15.12) | `gh release verify TAG` | 🟢 | not stated in the textbook | not needed |
| `gh attestation verify` | Checks an artifact attestation (15.11) | `gh attestation verify --help` | 🟢 | Expecting attestations for private repositories outside Enterprise Cloud | not needed |

## Rulesets and the API

`gh ruleset` is read-only: rulesets are created and changed through `gh api` (15.16, 18.16).

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `gh ruleset list` | Rulesets of the repository, including inherited ones; `--org ORG` for an organization (18.16) | `gh ruleset list` | 🟢 | Stopping there: a classic rule is read with `gh api repos/ORG/REPO/branches/BRANCH/protection` (18.17) | not needed |
| `gh ruleset view` | One ruleset by ID; `--web` opens the browser (18.16) | `gh ruleset view ID` | 🟢 | not stated in the textbook | not needed |
| `gh ruleset check` | Every rule that applies to a branch name; the branch need not exist (18.16) | `gh ruleset check release/2.0` | 🟢 | Trusting a pattern such as `release/*` without asking: `*` does not cross `/` (18.3) | not needed |
| `gh api` (GET) | Reads any REST endpoint; fills `{owner}`, `{repo}`, `{branch}` (15.17) | `gh api repos/{owner}/{repo}/rulesets` | 🟢 | Getting exactly 30 items: no pagination. Reading `404` as "does not exist": for a token without access it means "not for you" | Add `--paginate`; use a credential with access |
| `gh api -X GET ... -f` | Sends parameters with a GET (15.17, 19.11) | `gh api --method GET repos/ORG/REPO/codeowners/errors -f ref=BRANCH` | 🟢 | Adding `-f` or `-F` without `-X GET`: the method becomes POST and can create something (15.20) | Add `-X GET` |
| `gh api rate_limit` | Shows where you stand against the rate limits (15.17) | `gh api rate_limit` | 🟢 | Reading every `403` as a permission problem | not needed |
| `gh api -H` | Pins the REST API version (15.17) | `gh api -H 'X-GitHub-Api-Version: 2026-03-10' repos/{owner}/{repo}/pulls --paginate` | 🟢 | Assuming a newer version: without the header a request gets `2022-11-28` | Add the header |
| `gh api graphql` | Calls the GraphQL API (15.17) | `gh api graphql -f query='QUERY'` | 🟢 for a `query`, which only reads although it is sent as a `POST`; 🔴 for a `mutation`, by the rule of 15.22 | Assuming every feature exists in both APIs | A query: not needed. A mutation: depends on the field; often none |
| `gh api --method POST` | Creates, for example a ruleset from a JSON file (18.16) | `gh api --method POST repos/ORG/REPO/rulesets --input FILE` | 🔴 | Creating a ruleset Active: it binds everyone at once, you included | Set `enforcement` to `disabled`, or delete the ruleset; create it disabled and run `gh ruleset check` first |
| `gh api --method PUT` | Replaces a ruleset's or an environment's settings (18.16, 20B.2) | `gh api --method PUT repos/ORG/REPO/rulesets/ID --input FILE` | 🔴 | Not saving the current JSON first | PUT the saved JSON back |
| `gh api --method DELETE` | Deletes, for example a ruleset (18.16) | `gh api --method DELETE repos/ORG/REPO/rulesets/ID` | 🔴 | Removing the protection of every targeted ref at once | Re-create from the saved JSON; ruleset history exists only on Enterprise |
| `gh api .../git/refs -f` | Creates a branch at a commit ID GitHub still has, after a force push (13.15, 30.6) | `gh api repos/OWNER/REPO/git/refs -f ref=refs/heads/recovered -f sha=COMMIT_ID` | 🔴 | Relying on it: the combined procedure is Unverified, and GitHub's own advice is to have a collaborator push the commit | Delete the ref you created |

Read-only evidence endpoints taught in 18.16 and 29.8, all 🟢: `repos/ORG/REPO/rules/branches/main`, `repos/ORG/REPO/rulesets/rule-suites`, `repos/ORG/REPO/branches/main/protection`, `repos/OWNER/REPO/events`, `repos/OWNER/REPO/issues/N/timeline --paginate`, `"repos/OWNER/REPO/activity?activity_type=force_push&ref=refs/heads/main"`.

## Actions

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `gh run list` | Lists runs; `--branch` and `--commit` narrow the list (20B.14, 30.18) | `gh run list --workflow FILE --limit 5` | 🟢 | not stated in the textbook | not needed |
| `gh run view` | Event, branch, commit and jobs of a run; `--log-failed` prints the failed steps only (20B.11, 20B.14) | `gh run view RUN_ID --json event,headBranch,headSha,conclusion,jobs` | 🟢 | Comparing logs before comparing `headSha` with `git rev-parse HEAD` | not needed |
| `gh run watch` | Follows a run; `--exit-status` exits non-zero when it fails (20B.14) | `gh run watch RUN_ID --exit-status` | 🟢 | not stated in the textbook | not needed |
| `gh run download` | Downloads a run's artifacts (20B.11) | `gh run download RUN_ID` | 🟢 | Expecting artifacts after their retention has expired | not needed |
| `gh run rerun` | A new attempt at the original commit and ref; `--failed`, `--debug`, `--job JOB_ID` (20B.14) | `gh run rerun RUN_ID --failed` | 🟡 | Re-running an old deploy run: it deploys the old commit over today's | Start a new run from the current commit |
| `gh run cancel` | Stops a run, possibly mid-deployment (20B.18) | `gh run cancel RUN_ID` | 🟡 | Assuming the target is in a clean state afterwards | Re-run; check the target's state by hand |
| `gh workflow list`, `gh workflow view` | List workflows; show a workflow file at a ref (20B.11, 20B.14) | `gh workflow view FILE --yaml --ref BRANCH` | 🟢 | Reading your branch's file for `schedule`, `issue_comment` or `workflow_run`: those use the default branch's (`workflow_dispatch` uses the file on the ref it is dispatched against) | not needed |
| `gh workflow run` | Starts a run by hand; on a deploy workflow, a deployment (20B.14) | `gh workflow run FILE --ref main` | 🟡 | Expecting it to satisfy a required check, or to work without `on: workflow_dispatch` on the default branch | `gh run cancel RUN_ID`; deploy the previous commit |
| `gh workflow disable` | Disables a workflow (20B.14) | `gh workflow disable "WORKFLOW NAME"` | 🟡 | not stated in the textbook | not stated in the textbook |
| `gh cache list` | Lists caches, by key prefix with `--key` (20B.11) | `gh cache list --key PREFIX` | 🟢 | Expecting a sibling branch's cache to be restorable (20A.11) | not needed |
| `gh cache delete --all` | Removes every cache of the repository (20B.18) | `gh cache delete --all` | 🟡 | Forgetting that every cache of the repository goes, not one branch's | Caches are rebuilt by the next runs, slowly |
| `gh secret set` | Stores a secret; without `--body` it prompts or reads standard input (20B.2) | `gh secret set NAME --env ENVIRONMENT` | 🟡 | Passing the value on the command line; overwriting a value that cannot be read back | Set the previous value again from your secret store |
| `gh secret list` | Lists secret names (20B.2) | `gh secret list --env ENVIRONMENT` | 🟢 | Expecting to read a value | not needed |
| `gh variable set` | Stores a non-secret variable (20B.2) | `gh variable set NAME --env ENVIRONMENT --body "VALUE"` | 🟡 | Overwriting the stored value | Set the previous value again |

Workflow syntax is in the [GitHub Actions cheat sheet](github-actions-cheat-sheet.md); the investigation order for a failing workflow is in the [GitHub Actions guide](../guides/github-actions-guide.md).

## SSH keys and others

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `gh ssh-key add` | Attaches a public key to your account (16.12); `--type signing` registers it for signature verification (21B.6) | `gh ssh-key add KEY.pub --type signing --title "TITLE"` | 🟡 | Expecting an authentication key to verify signatures: a signing key is a separate registration, even for the same file | `gh ssh-key delete` |
| `gh ssh-key delete` | Removes a key from your account (16.23) | `gh ssh-key delete ID` | 🔴 | Not listing where the key is used: every machine and job that used it stops | Create and distribute a new one |

Not in this sheet because 2.88.1 does not have them (15.16): `gh discussion`, `gh skill`, `gh repo read-file`, `gh pr checkout --worktree`, the issue type and parent flags, and the `gh stack` extension (17.14). Named in section 15.16 without an example, and so without a row: `gh repo list`, `license`, `gitignore`; `gh issue edit`, `comment`; `gh label edit`, `delete`; `gh release edit`, `upload`, `verify-asset`; `gh secret delete`; `gh variable get`.

Related: [command safety](../reference/command-safety.md), [Git cheat sheet](git-cheat-sheet.md), [security cheat sheet](security-cheat-sheet.md), [troubleshooting playbook](../playbooks/troubleshooting-playbook.md).
