# GitHub reference

> **Baseline.** GitHub facts as of 1 October 2026, compiled from the textbook and not re-fetched. Nothing here was run against GitHub. Limits, plan gates, dates and labels change: re-read the linked page before you rely on a number.

This file is a lookup table for what Chapters 15 to 21B teach about the GitHub layer. Every row names the section it comes from. A section number identifies its chapter: 15.x is [Chapter 15](../textbook/ch15-github.md), 16.x [Chapter 16](../textbook/ch16-authentication.md), 17.x [Chapter 17](../textbook/ch17-pull-requests.md), 18.x [Chapter 18](../textbook/ch18-branch-protection.md), 19.x [Chapter 19](../textbook/ch19-codeowners.md), 20A.x [Chapter 20A](../textbook/ch20a-actions-fundamentals.md), 20B.x [Chapter 20B](../textbook/ch20b-actions-delivery-debugging.md), 21A.x [Chapter 21A](../textbook/ch21a-actions-security.md), 21B.x [Chapter 21B](../textbook/ch21b-repository-security-incident-response.md), 22.x [Chapter 22](../textbook/ch22-git-lfs.md). "Unverified" is carried from the chapter that marked it.

## 1. Git versus GitHub

A repository on GitHub is a Git repository, which a clone copies completely, surrounded by records in GitHub's database, which Git cannot copy (15.2).

| Thing | Layer | Arrives with `git clone`? | Section |
|---|---|---|---|
| Commits, trees, file contents, annotated tag objects; branches and tags; author, committer, message, signature | Git | yes (branches as remote-tracking branches) | 15.2 |
| `README`, `LICENSE`, `.github/` (issue forms, templates, `CODEOWNERS`, workflow files); `Fixes #12` in a message | Git data that GitHub interprets | yes | 15.2 |
| `refs/pull/N/head`, `refs/pull/N/merge` | Git refs that GitHub writes, read-only for you | no: outside the default refspec | 15.2, 17.2 |
| Pull request (title, description, reviews, comments, checks, merge state); issue, label, milestone, project, discussion | GitHub | no | 15.2 |
| Release (title, notes, assets, draft, pre-release and latest flags) | GitHub; points at a tag | the tag yes, the release no | 15.2, 15.12 |
| "Verified" badge; which account a commit is attributed to | GitHub | no | 15.2, 21B.6 |
| Fork relationship, stars, watchers | GitHub | no | 15.2 |
| Roles, teams, rulesets, classic branch protection, secrets, variables, webhooks, deploy keys, settings | GitHub | no | 15.2 |
| Wiki | Git, in a second repository `OWNER/REPO.wiki.git` | no: a separate clone | 15.2, 15.10 |
| Workflow runs, logs, artifacts, caches; packages and images | GitHub Actions; GitHub Packages | no | 15.2 |
| Large files tracked with Git LFS | pointer files are Git; contents are in LFS storage | pointers yes | 15.2, 22.11 |

Three identities are independent: the commit identity (`user.name`, `user.email`: an assertion nobody checks), the authentication identity (the account behind a token or SSH key), and the signing identity (`user.signingKey`) (16.2).

## 2. Repository concepts

| Concept | What the textbook states | Section and source |
|---|---|---|
| Account types | Personal (Free or Pro; owner plus collaborators), organization (Free, Team, Enterprise Cloud; five repository roles, teams), enterprise (owns organizations) | 15.3, [types of accounts](https://docs.github.com/en/get-started/learning-about-github/types-of-github-accounts) |
| Visibility | Public, private, or internal (organizations owned by an enterprise). Organization owners can read every repository | 15.5, [about repositories](https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories#about-repository-visibility) |
| Public to private | Stars and watchers are erased; public forks stay public, detached into their own network | 15.5, [setting repository visibility](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility) |
| Private to public | Code, complete history, and Actions history and logs become readable; push rulesets are disabled; private forks stay private, detached; stars and watchers are erased | 15.5, same page |
| Default branch | What clones check out, pull requests target, and closing keywords act on | 15.5 |
| Fork | A second repository with its own refs, settings and permissions. Forks of public repositories are public, of private ones private | 15.7, [forks](https://docs.github.com/en/pull-requests/reference/forks) |
| Fork network | "Repositories in the network share Git data": a commit pushed to any member can be reachable from the others, "even after a fork is deleted" | 15.7, same page |
| Forks and rules | Branch and tag rulesets are not inherited by forks; push rulesets apply to the whole network | 15.7, 18.4 |
| Archived | Issues, pull requests, code, releases and settings become read-only | 15.5, [archiving](https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories) |
| Deleted | Restorable within 90 days, unless its fork network is not empty. Deleting a private repository deletes its private forks; deleting a public one makes an active public fork the new upstream | 15.7, [restoring a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/restoring-a-deleted-repository) |
| Transferred | Keeps Git data, issues, pull requests, wiki, stars and watchers; webhooks, secrets and deploy keys stay attached | 15.3, [transferring a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository) |
| Issue | A numbered database record. To the REST API "every pull request is an issue, but not every issue is a pull request" | 15.8, [REST reference](https://docs.github.com/en/rest/issues/issues) |
| Closing keywords | `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved` plus `#N` or `OWNER/REPO#N`. In a pull request description they act only when the pull request targets the default branch; the issue closes at merge time | 15.8, 17.4, [linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue) |
| Release | A GitHub record on a tag name. Creating a release can create the tag, from the default branch unless a target is given | 15.12, [create a release](https://docs.github.com/en/rest/releases/releases#create-a-release) |
| Immutable release | Generally available since 28 October 2025: the tag is locked to its commit, assets cannot change, the tag name can never be reused, and a signed attestation is generated | 15.12, [immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) |
| `refs/pull/N/head` | A ref in the base repository for the head commit of pull request N. It survives deletion of the head branch; nobody can rewrite or delete it with Git | 17.2, [checking out pull requests locally](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/checking-out-pull-requests-locally) |
| `refs/pull/N/merge` | The test merge commit, created "when possible". Regenerated on push, on merge-base change, or when older than 12 hours (since 19 February 2026) | 17.2, 17.22, [pull requests reference](https://docs.github.com/en/pull-requests/reference/pull-requests#pull-request-refs-and-merge-branches) |
| `gh-readonly-queue/BASE/...` | Temporary branches a merge queue creates; they "contain a different `sha` from the pull request" | 17.11, [managing a merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue) |

> **Unverified.** GitHub documents no retention period for unreachable commits (15.7, 21B.19).

## 3. Limits and numbers

### Repositories, pushes and pull requests

| Limit | Value | Kind | Section and source |
|---|---|---|---|
| One file in a push | warning above 50 MiB; blocked above 100 MiB. Applies to every object the push sends, including files deleted in later commits | enforced | 15.15, [large files](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github) |
| One file added in the browser | 25 MiB | enforced | 15.15, same page |
| One push | 2 GB | enforced | 15.15, [repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits) |
| Repository size | "ideally less than 1 GB, and less than 5 GB is strongly recommended"; 10 GB on disk as recommended maximum (two pages that differ, both read on 2 October 2026) | recommended | 15.15, both pages above |
| Entries in one directory; directory depth; branches | 3,000; 50; 5,000 | recommended | 15.15, repository limits |
| Open pull requests against one branch; merge rate | 1,000; 1 merged pull request per minute | recommended | 17.18, repository limits |
| Pull request diff | 20,000 loadable lines or 1 MB; 300 files (25 for renderable files such as images) | display | 15.15, 17.18, repository limits |
| One file's diff | 20,000 loadable lines or 500 KB; 400 lines and 20 KB load automatically | display | 17.18, repository limits |
| Commits listed in a pull request or comparison | 250 | display | 15.15, 17.18, repository limits |
| "Rebase and merge" | 100 commits | enforced | 15.15, 17.8, [rebase limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits#rebase-limits) |
| Repositories per organization or account | 100,000 | enforced | 15.15, repository limits |
| Release assets | 1,000 per release, each under 2 GiB | enforced | 15.15, [about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases) |
| Git LFS, one file | 2 GB on Free and Pro, 4 GB on Team, 5 GB on Enterprise Cloud | enforced | 22.11, [about Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage) |
| Git LFS, included per month | 10 GiB of storage and of bandwidth on Free and Pro; 250 GiB of each on Team and Enterprise Cloud. Prices are not given in the textbook (Unverified, 22.11) | metered | 22.11 |
| Wiki | soft limit of 5,000 files | recommended | 15.10, [about wikis](https://docs.github.com/en/communities/documenting-your-project-with-wikis/about-wikis) |
| Sub-issues; issue types; dependencies | 100 per parent, eight levels; 25 types per organization; 50 links per relationship type | enforced | 15.8 |
| Projects | 50 fields; 50,000 items since April 2025 | enforced | 15.10, [about Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects) |
| Watched repositories | 10,000 per account | enforced | 15.6 |
| Custom repository roles | up to 20, Enterprise Cloud only | plan gate | 15.4 |

### Rules, review and accounts

| Limit | Value | Section and source |
|---|---|---|
| Rulesets | 75 per repository, 75 organization-wide | 18.3, [about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets) |
| Push rule entries | at most 200 file-path entries of up to 200 characters; at most 200 extensions; at most 1,000 ref updates per push | 18.12, same page |
| Required reviewers rule | up to 15 teams; 0 to 10 approvals per team | 18.7, [changelog](https://github.blog/changelog/2026-02-17-required-reviewer-rule-is-now-generally-available/) |
| Required status check | must have completed successfully in the repository during the past seven days to be selectable | 18.8, [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks) |
| Ruleset history | 180 days, Enterprise Cloud documentation only | 18.15 |
| `CODEOWNERS` file | under 3 MB; a larger file "will not be loaded" | 19.3, [about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) |
| Delegated bypass request (push protection) | review expires after seven days | 21B.12, [delegated bypass](https://docs.github.com/en/code-security/concepts/secret-security/delegated-bypass) |
| Organization audit log | 180 days; Git events (Enterprise Cloud) are retained seven days and read through the REST API, an export or streaming, and a token-hash search does not return them | 13.15, 15.19, 21B.8, [audit log](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization) |
| Fine-grained tokens | at most 50 per account | 16.6 |
| Unused credentials | personal and OAuth tokens unused for a year are removed; SSH keys unused for a year are deleted | 16.6, 16.8, [token expiration and revocation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation) |
| Dependabot version updates | at most five open pull requests without explicit configuration; default cooldown of 3 days since 14 July 2026 | 21B.13 |

### REST API rate limits

| Caller | Primary limit | Section and source |
|---|---|---|
| No authentication | 60 requests per hour, per IP address | 15.17, [rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api) |
| An authenticated user | 5,000 requests per hour | 15.17, same page |
| A GitHub App installation | 5,000 per hour at minimum; 15,000 on Enterprise Cloud organizations | 15.17, same page |
| `GITHUB_TOKEN` in a workflow | 1,000 requests per hour per repository | 15.17, same page |

Secondary limits: at most 100 concurrent requests, and a points budget per minute. Exceeding a limit returns `403` or `429`, so a `403` is not always a permission problem (15.17).

### GitHub Actions

From 20B.10 and [Actions limits](https://docs.github.com/en/actions/reference/limits) unless another section is named.

| Limit | Value |
|---|---|
| Job on a GitHub-hosted runner | 6 hours (`timeout-minutes` defaults to 360); the job token "can live for a maximum of 6 hours" (21A.3) |
| Job on a self-hosted runner | fails after 24 hours in the queue; may run for up to five days (20B.9) |
| `ubuntu-slim` job | 15 minutes (20B.8) |
| Workflow run, including waiting for approval | 35 days |
| Environment approval; wait timer | fails after 30 days without approval; timer 1 to 43,200 minutes (20B.2) |
| Environment reviewers; protection rules | up to six users or teams; at most six rules enabled per environment (20B.2) |
| Matrix | 256 jobs per run |
| Re-runs | 50 per workflow run, within 30 days of the first run ([changelog](https://github.blog/changelog/2026-04-10-actions-workflows-are-limited-to-50-reruns/)) |
| Reusable workflows | 10 levels; 50 unique called workflows per file |
| Concurrent jobs on standard runners | Free 20, Pro 40, Team 60, Enterprise 500; macOS 5 (50 on Enterprise) |
| `workflow_dispatch` inputs; `schedule` | up to 25 inputs; shortest interval 5 minutes; disabled after 60 days without activity in a public repository (20A.4) |
| Path filter evaluation | a push of more than 1,000 commits always runs; beyond 3,000 changed files only the first 3,000 are matched (20A.4) |
| Cache | 10 GB per repository without charge; entries unused for 7 days are evicted; key at most 512 characters (20A.11) |
| Artifacts and logs | 90 days by default, `retention-days` 1 to 90; 500 artifacts per job (20A.12) |
| Checks, workflow runs and statuses | follow the same retention setting since 1 October 2026 ([changelog](https://github.blog/changelog/2026-08-27-actions-retention-will-cover-checks-workflow-runs-and-statuses/)) |

> **Unverified.** The status-checks page still says checks are kept 400 days; the Phase 0 report records the conflict and follows the changelog (17.6, 20A.19). How Windows and macOS minutes consume included minutes is not stated on any 2026 page: do not quote a multiplier (20B.10).

Prices, included minutes and runner labels are in section 20B.8 and 20B.10 and in the [GitHub Actions guide](../guides/github-actions-guide.md).

## 4. Roles and permissions

**Personal repository.** Two levels: the owner and collaborators (15.3, [personal repositories](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/repository-access-and-collaboration/permission-levels-for-a-personal-account-repository)). No teams, so team-based features (required reviewers by team, issue types and fields) do not exist there (15.8, 18.7).

**Organization repository.** Five roles (15.4, [repository roles](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization#permissions-for-each-role)):

| Action | Read | Triage | Write | Maintain | Admin |
|---|---|---|---|---|---|
| Clone, fork, open issues, comment, submit a review | yes | yes | yes | yes | yes |
| Apply labels, close and assign any issue or pull request, request reviews | no | yes | yes | yes | yes |
| Push, merge a pull request, create labels and milestones | no | no | yes | yes | yes |
| Give an approval that counts toward required reviews; act as a code owner | no | no | yes | yes | yes |
| Create and edit releases; create and edit Actions secrets and variables | no | no | yes | yes | yes |
| Configure pull request merges, edit the description, manage topics | no | no | no | yes | yes |
| Push to protected branches (classic protection only) | no | no | no | yes | yes |
| Manage rulesets and branch protection; change visibility; manage access, webhooks and deploy keys; rename the default branch; archive, transfer, delete | no | no | no | no | yes |

| Term | Meaning | Section |
|---|---|---|
| Owner | A member with complete administrative access, and admin on every repository; GitHub advises at least two | 15.4 |
| Team | A group of members; nested teams inherit the parent's access; outside collaborators cannot be on a team | 15.4 |
| Outside collaborator | Not a member; direct grants only; base permissions do not apply | 15.4 |
| Base permission | A role every member has on every repository; can be set to none | 15.4 |
| Effective access | The highest of base permission, team grants, direct grants and ownership. The Phase 0 report marks this combined rule as an inference, not a sentence GitHub publishes | 15.4 |

Facts that decide arguments: Write is enough to edit workflow files and so to run code with the repository's secrets (15.4, 21A.9); under rulesets a role grants no bypass by itself, only the bypass list does (18.5); a deploy key keeps working after the person who added it leaves (15.4, 16.14).

## 5. Authentication and token types

Authentication establishes which account a connection belongs to; authorization decides what that account may do (16.2). Git has no accounts: over HTTPS it attaches a secret from a credential helper, over SSH it starts `ssh` (16.2).

| Transport | What GitHub accepts | Section and source |
|---|---|---|
| HTTPS | A token in the password position. Account passwords have been refused since 13 August 2021 | 16.3, [GitHub Blog](https://github.blog/security/application-security/token-authentication-requirements-for-git-operations/) |
| SSH | A key pair; `ssh-keygen -t ed25519` is the documented command. A key is registered as an authentication key or a signing key; for both, upload it twice | 16.8, [adding a key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) |
| SSH over port 443 | `ssh -T -p 443 git@ssh.github.com` | 16.12, [SSH over the HTTPS port](https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port) |
| `git://`, DSA keys | Removed on 15 March 2022 | 16.3 |

Credential types (16.6, 16.14, 21B.8; [credential types](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/github-credential-types), [token formats](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github#githubs-token-formats)):

| Credential | Prefix | Lifetime | Reaches |
|---|---|---|---|
| Personal access token (classic) | `ghp_` | long-lived; no expiry required | by scope, across every repository and organization the user can reach |
| Fine-grained personal access token | `github_pat_` | configurable, up to one year or none | one owner, optionally selected repositories, per-permission read or write |
| OAuth app token (`gh auth login` produces one) | `gho_` | long-lived; expiring by default for new apps since 14 August 2026 | by scope |
| GitHub App user token | `ghu_` | 8 hours; `ghr_` refresh token of 6 months | the app's permissions, limited by the user's |
| GitHub App installation token | `ghs_` | 1 hour | the repositories and permissions of the installation |
| GitHub App private key | none | never expires | mints installation tokens for every installation of the app (21B.8) |
| `GITHUB_TOKEN` in a workflow | an installation token | the job | the workflow's repository, within the job's `permissions` |
| Deploy key | none | no expiry | one repository; read-only unless write access is chosen; not tied to a person |
| Personal SSH key | none | until deleted; GitHub deletes one unused for a year | everything the account can reach over SSH |
| OIDC token from GitHub Actions | none | exchanged for a cloud credential "only valid for a single job" | what the cloud's trust policy grants (21A.10) |

- **Fine-grained gaps (16.6).** A fine-grained token cannot contribute to public repositories where you are not a member, reach several organizations at once, access Packages (including `docker login ghcr.io`), or call the Checks API. Generally available since 18 March 2025; by default an organization owner must approve one.
- **Token format (16.6).** Installation tokens, including `GITHUB_TOKEN`, use a format of about 520 characters in a staged rollout from 27 April 2026 ([changelog](https://github.blog/changelog/2026-04-24-notice-about-upcoming-new-format-for-github-app-installation-tokens/)). Never validate a token by length or pattern.
- **SAML single sign-on (16.15).** Enterprise Cloud. A classic token and an SSH key must be authorized per organization; deploy keys, installation tokens and `GITHUB_TOKEN` need no authorization. A `403` from the REST API carries an `X-GitHub-SSO` header.
- **Two-factor authentication (16.15).** Required since March 2023 for everyone who contributes code on GitHub.com. Tokens and SSH keys are used without a second factor.
- **OIDC (21A.10).** The job needs `id-token: write`. The issuer is `https://token.actions.githubusercontent.com`. Repositories created after 15 July 2026 use an immutable default subject that includes owner ID and repository ID ([changelog](https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/)).
- **SSH changes (16.16).** RSA keys uploaded after 14 October 2026 must be at least 3072 bits; on 13 January 2027 the `ssh-rsa` signature type (RSA with SHA-1) is removed ([changelog](https://github.blog/changelog/2026-09-22-security-improvements-for-ssh/)). Ed25519 and ECDSA keys and HTTPS remotes are not affected.

> **Unverified.** The server's exact text when a password is used (16.3), the text Git shows when a credential lacks SSO authorization (16.15), and a minimum size for RSA keys that are already uploaded (16.16) are not documented.

Order of preference for automation, an inference of the Phase 0 report (21B.8): OIDC and the job token; App installation tokens; fine-grained tokens with expiry; deploy keys; classic tokens and machine users last.

## 6. Pull requests

| Topic | What the textbook states | Section and source |
|---|---|---|
| "Commits" tab | `git log base..head` (two dots) | 17.3 |
| "Files changed" tab | `git diff base...head` (three dots: from the merge base to the head). "Pull requests on GitHub show a three-dot diff" | 17.3, [branches reference](https://docs.github.com/en/pull-requests/reference/branches#three-dot-and-two-dot-git-diff-comparisons) |
| Pinned base | The base is the commit the base branch referenced when the pull request was opened; a compare page follows the current tips | 17.2, [changing the base branch](https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/changing-the-base-branch-of-a-pull-request) |
| Draft | Cannot be merged; code owners are not requested until it is marked ready. Available in every repository since 1 May 2025 | 17.4, [changelog](https://github.blog/changelog/2025-05-01-draft-pull-requests-are-now-available-in-all-repositories/) |
| Review: Comment | Feedback without a verdict; never blocks | 17.4, [pull request reviews](https://docs.github.com/en/pull-requests/reference/pull-request-reviews) |
| Review: Approve | Counts toward required approvals only from people with write permission. Authors cannot approve their own pull requests | 17.4, 18.7 |
| Review: Request changes | "Purely informational" unless a rule requires a pull request; then the same reviewer must approve, or the review must be dismissed | 17.4, 18.7 |
| Dismiss stale approvals | The approval is dismissed when the diff changes: a push, **Update branch**, or a moved merge base | 17.5 |
| Approval of the most recent reviewable push | Someone other than the last pusher must approve; stale reviews are not dismissed. GitHub: "it is safer to dismiss stale reviews" | 17.5 |
| Checks and commit statuses | Both attach to a commit ID. "Required checks must pass on the latest commit SHA" | 17.6, [troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks) |
| `mergeable` | REST: true, false or null (not computed yet: ask again). GraphQL: `MERGEABLE`, `CONFLICTING`, `UNKNOWN` | 17.6, 18.17 |
| `mergeStateStatus` | `BEHIND`, `BLOCKED`, `DIRTY`, `DRAFT`, `UNSTABLE`, `CLEAN`, `HAS_HOOKS`, `UNKNOWN` | 18.17 |
| Auto-merge | A stored instruction to merge when every required review and check passes. Disabled when someone without write permission pushes to the head branch or switches the base branch. Public repositories on Free; public and private on paid plans | 17.10, [managing auto-merge](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-auto-merge-for-pull-requests-in-your-repository) |
| Merge queue | Runs required checks on the commit that will become the new tip; the queue fixes the merge method; workflows must listen to `merge_group`. Public repositories owned by an organization, or private ones on Enterprise Cloud | 17.11, [managing a merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue) |
| Indirect merge | A pull request is marked `merged` when its head commits become reachable from the base by any route, "even if branch protection rules on that pull request were not satisfied" | 17.13, [indirect merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges#indirect-merges) |

> **Unverified.** Whether a Free or Team organization can enable the merge queue through a ruleset rule, or only through a classic rule, could not be confirmed (17.11).

## 7. Merge methods

From 17.8 and [about merge methods](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github). The Git layer equivalents are `git merge --no-ff`, `git merge --squash` plus a commit, and `git rebase` plus a fast-forward (17.8). The merge method does not change the resulting tree; it changes what history says.

| | Create a merge commit | Squash and merge | Rebase and merge |
|---|---|---|---|
| New commits on the base | one merge commit | one commit | one per original commit |
| Your original commit IDs on the base | preserved | not present | not present: "always ... creates new commit SHAs", even when no rebase seemed necessary |
| Committer of what lands | your commits unchanged; the merge commit is committed by GitHub | GitHub | "always updates the committer information" |
| Signature on what lands | yours kept; the merge commit is signed by GitHub | signed by GitHub | none: added "without commit signature verification" |
| Under "Require signed commits" (18.10) | works if every head commit is signed and verified | unsigned head commits block the merge anyway | cannot satisfy the rule; rebase locally and push |
| Under "Require linear history" | not allowed | allowed | allowed, at most 100 commits |
| Documented loss | none | when changes were made and who authored the squashed commits | originally empty commits are dropped |
| `git branch -d` on the local branch, after the head branch was deleted and pruned (17.9) | deletes | refuses: "not fully merged" | refuses: "not fully merged" |
| Bisect granularity (17.9) | commit, or pull request with `--first-parent` | pull request | commit |
| Revert (17.9) | one command with `-m 1`, plus the re-merge trap | one command | one per commit |

After squash and rebase your original commits are on no branch and stay reachable under `refs/pull/N/head` (17.8). Before `git branch -D` 🔴, verify with the tree comparison of section 17.9.

> **Unverified.** Who is recorded as the author of a squash commit, and whether other contributors become `Co-authored-by` trailers, is not stated on the live documentation pages (17.8).

## 8. Rulesets and branch protection

A rule is a check on a ref update (18.2). A ruleset is a named list of rules with a target, an enforcement status and a bypass list (18.3).

| Kind | Targets | Section |
|---|---|---|
| Branch ruleset | branches by `fnmatch` pattern, or the default branch (`~DEFAULT_BRANCH`, `~ALL` in the REST API) | 18.3 |
| Tag ruleset | tags by pattern | 18.3, 18.12 |
| Push ruleset | every push to a private or internal repository and its fork network: file paths, path length, extensions, file size (not Git LFS) | 18.12 |

`*` does not match `/`: `release/*` does not cover `release/1.0/hotfix`, and `*` alone matches no branch with a slash; use `**/*` forms (18.3).

| Rule | REST `type` | Notes (18.6, [available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)) |
|---|---|---|
| Restrict creations | `creation` | only bypass actors may create matching refs |
| Restrict updates | `update` | only bypass actors may push to matching refs |
| Restrict deletions | `deletion` | selected by default |
| Block force pushes | `non_fast_forward` | enabled by default |
| Require linear history | `required_linear_history` | the repository must allow squash or rebase merging |
| Require a pull request before merging | `pull_request` | sub-options: approvals, dismiss stale approvals, code owner review, restrict dismissals, most recent push approval, resolved conversations, allowed merge methods, required reviewers by path |
| Require status checks to pass | `required_status_checks` | check names; strict (branch up to date) or loose; optional expected source app |
| Require signed commits | `required_signatures` | section 7 |
| Require deployments to succeed | `required_deployments` | named environments |
| Require merge queue | `merge_queue` | Enterprise Cloud view only; not in organization rulesets |
| Code scanning, code quality, code coverage (preview) | `code_scanning`, `code_quality`, `code_coverage` | block on findings |
| Require workflows to pass | `workflows` | organization or enterprise level; Enterprise Cloud view |
| Metadata restrictions | `commit_message_pattern` and four more | Enterprise plan |

> **Unverified.** The REST name of the secret-scanning rule, the exact check name a matrix job reports, and the pattern syntax of required reviewers (the documentation and the REST schema disagree) (18.6, 18.7, 18.8).

| Topic | What the textbook states | Section |
|---|---|---|
| Enforcement status | **Active** or **Disabled**; **Evaluate** only in the Enterprise Cloud documentation | 18.3 |
| Layering | No priority: all active rulesets and the matching classic rule are aggregated, and "the most restrictive version of the rule applies" | 18.4 |
| Bypass modes | `always`; `pull_request` (must open a pull request, leaves a trail); `exempt` (rules not run, no audit entry; since 10 September 2025) | 18.5 |
| Who can be a bypass actor | Admins and owners, the maintain or write role, teams (not secret teams), GitHub Apps, Dependabot; individual users since 7 May 2026 | 18.5 |
| Required-check traps | A skipped workflow stays "Pending"; a skipped job reports "Success"; only `push`, `pull_request`, `pull_request_review`, `pull_request_target`, `deployment`, `deployment_status` runs count; anyone with write access can set a status unless the source app is pinned | 18.8 |
| Seeing rules | Anyone with read access: the `/rules` page, the merge box, `gh ruleset check` | 18.16 |

Classic branch protection versus rulesets (18.14, [about protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)):

| | Classic rule | Ruleset |
|---|---|---|
| How many apply to one branch | one | all that target it, aggregated |
| Who can see it | people with admin access | anyone with read access |
| Administrators | not bound unless **Do not allow bypassing the above settings** is selected | bound, unless on the bypass list |
| Scope | branches of one repository | branches, tags, pushes; repository, organization, enterprise |
| Rejection message seen by Git | `remote: error: GH006: Protected branch update failed for refs/heads/main.` | not documented on the pages read |

Rulesets are the recommended mechanism since 7 July 2026; **Convert to ruleset** exists since 11 August 2026 and does not convert "Require conversation resolution before merging" (18.14). Tag protection rules were retired on 30 August 2024 (18.12).

Plan gates, read on 1 October 2026 (18.15):

| Feature | Where it is available |
|---|---|
| Repository rulesets; classic branch protection | public repositories on Free; public and private on Pro, Team, Enterprise Cloud |
| Organization-level rulesets | Team and Enterprise since 16 June 2025 (Unverified: one documentation sentence still says Enterprise; 18.13) |
| Enterprise-level rulesets; Evaluate status; metadata restrictions; ruleset history | Enterprise Cloud documentation only |
| Push rulesets | Team plan, private or internal repositories |
| Rule Insights dashboard | Team and Enterprise Cloud |
| Required reviewers by team | organization-owned repositories |

## 9. CODEOWNERS

From [about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) as taught in Chapter 19. The file is Git data; reading it, matching paths and requesting reviewers is GitHub; blocking a merge needs a rule (19.2).

| Topic | Rule | Section |
|---|---|---|
| Locations | `.github/`, then the repository root, then `docs/`; the first file found is used | 19.3 |
| Which version | The file on the base branch of the pull request, so an edit to `CODEOWNERS` is reviewed under the old file | 19.7 |
| Precedence | The last matching pattern wins: general patterns first, specific ones last | 19.5 |
| Owners | `@username` or `@org/team-name` (an account email works "in most cases"); several owners go on one line | 19.4 |
| No owner after a pattern | Removes ownership for those paths | 19.4 |
| Invalid line | Skipped; the rest of the file still applies | 19.4 |
| Case | Paths are case sensitive | 19.4 |
| Unlike gitignore | `!` negation, `[ ]` ranges and `\#` escaping do not work | 19.5 |
| Owner access | A user or team must have write permission; a team must be visible and hold write access itself. Otherwise no owner is assigned, silently | 19.4 |
| Without a rule | Owners are requested as reviewers; the pull request can merge without them | 19.6 |
| With "Require review from code owners" | Every changed path that has an owner needs an approval from any one of its owners | 19.6, 18.7 |
| Does not enforce | "Both teams must approve", a count per team, or anything for a bypass actor or a path without an owner | 19.6, 19.9 |
| Required reviewers rule | Generally available since 17 February 2026: teams only, a count per team, organization repositories only; it "augments CODEOWNERS files but doesn't replace them" | 19.10 |
| Protecting the file | Give `/.github/` an owner on the last line; that also covers `.github/workflows/` | 19.8 |
| Diagnosis | Error highlighting on the file's page; `GET /repos/{owner}/{repo}/codeowners/errors` with an optional `ref` | 19.11, [REST: list CODEOWNERS errors](https://docs.github.com/en/rest/repos/repos#list-codeowners-errors) |

Availability: public repositories on GitHub Free and Free for organizations; public and private on paid plans (19.2).

## 10. GitHub Actions events and what they check out

Layer: GitHub Actions. Values from 20A.4 and the [events reference](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows).

| Event | `GITHUB_SHA` | `GITHUB_REF` | Notes |
|---|---|---|---|
| `push` | tip commit pushed to the ref | the updated ref | runs for any branch, including workflows not merged into the default branch |
| `pull_request` | last merge commit on the `GITHUB_REF` branch (the test merge) | `refs/pull/N/merge` | does not run while the pull request has a merge conflict |
| `pull_request_target` | not in the table of 20A.4 | not in the table of 20A.4 | the workflow file always comes from the default branch, since 8 December 2025 (21A.5) |
| `workflow_dispatch` | last commit on the chosen branch or tag | that branch or tag | only if the workflow file exists on the default branch |
| `schedule` | last commit on the default branch | the default branch | uses the file on the default branch (20B.11) |
| `workflow_run` | last commit on the default branch | the default branch | only if the file exists on the default branch |
| `workflow_call` | same as the caller | same as the caller | makes the workflow reusable (20B.6) |
| `merge_group` | the commit of the merge group | the ref of the merge group | required checks must listen to it |
| `release` | last commit in the tagged release | `refs/tags/<tag_name>` | subscribe to `published` to cover stable and pre-releases |

What `actions/checkout` does by default (20A.8, [README](https://github.com/actions/checkout/blob/v7.0.1/README.md) at v7.0.1): it fetches one commit (`fetch-depth: 1`) without tags (`fetch-tags: false`) for the ref of the event; on `pull_request` that is `refs/pull/N/merge` with a detached HEAD; `lfs` and `submodules` are `false`; `persist-credentials` is `true`. To record the commit a contributor pushed, use `github.event.pull_request.head.sha` (17.2).

| Trigger | Whose code and workflow | Job token | Secrets | Section |
|---|---|---|---|---|
| `pull_request` from a fork (and Dependabot pull requests) | the contributor's | read-only | not passed, except `GITHUB_TOKEN` | 21A.4 |
| `pull_request_target` | the default branch's workflow; a checkout without `ref` takes the default branch | "read/write repository permission, even when it is triggered from a public fork" | repository and organization secrets | 21A.5 |
| `workflow_run` | the file on the default branch | not stated in the textbook | can read secrets even when the first workflow could not | 20A.4, 21A.5 |

- The approval gate for first-time contributors applies to `pull_request`; workflows on privileged triggers "will always run, regardless of approval settings" (21A.4).
- `actions/checkout` v7 (18 June 2026) refuses to fetch a fork pull request's head or merge ref under `pull_request_target`, and under `workflow_run` started by a pull request event, unless `allow-unsafe-pr-checkout: true`. It does not stop `git fetch` or `gh pr checkout` in a `run` step (21A.5, [changelog](https://github.blog/changelog/2026-06-18-safer-pull_request_target-defaults-for-github-actions-checkout/)).
- From 2 November 2026 a default rule disables `pull_request_target` in affected public repositories unless a maintainer allows it (21A.8, [changelog](https://github.blog/changelog/2026-09-17-workflow-execution-protections-in-github-actions-generally-available/)).
- Events created with the job token do not start new workflow runs, except `workflow_dispatch`, `repository_dispatch`, and pull request events, which wait for approval since 11 June 2026 (20A.4).
- A workflow without a `permissions` key gets the repository default: read-only for repositories created since 2 February 2023, possibly read-write for older ones. Naming any permission sets the unnamed ones to `none` (21A.3).
- Cache scope: a run restores caches of its own branch and the default branch; a pull request run also from its base branch. Since 26 June 2026 low-trust triggers get read-only access to the default branch's caches (20A.11, 21A.11).
- Path filters use a three-dot diff for pull requests and a two-dot diff for pushes (20A.4).

Workflow syntax is in the [GitHub Actions cheat sheet](../cheatsheets/github-actions-cheat-sheet.md) and the [GitHub Actions guide](../guides/github-actions-guide.md); pinned action versions are in [ACTION_PINS.md](../workflows/ACTION_PINS.md).

## 11. Repository security features

Layer: GitHub. From Chapter 21B; nothing was run against GitHub.

| Feature | What it does | Plan gate | Section and source |
|---|---|---|---|
| Secret scanning | Scans the entire history on all branches, plus issues, pull requests, discussions and wikis | free on public repositories; organization-owned private and internal ones need GitHub Secret Protection ($19 per active committer per month, Team and Enterprise) | 21B.12, [secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning) |
| Push protection for users | Blocks your pushes of recognized secrets to public repositories; on by default since 29 February 2024 | none; GitHub.com only | 21B.12, [about push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection) |
| Push protection for repositories | Blocks every push to that repository; a bypass leaves an alert. Off by default | GitHub Secret Protection (free on public repositories) | 21B.12, same page |
| Delegated bypass | Restricts who may bypass a push-protection block | Secret Protection, organization-owned repositories | 21B.12 |
| Dependabot alerts, security updates, version updates | Alerts for known vulnerabilities on the default branch; pull requests to the minimum patched version; pull requests to stay current (`.github/dependabot.yml`) | free on every plan | 21B.13, [Dependabot alerts](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-alerts) |
| Code scanning | CodeQL or SARIF uploads; runs on Actions and consumes minutes | free on public repositories; GitHub Code Security ($30 per active committer per month) on private ones | 21B.13, [code scanning](https://docs.github.com/en/code-security/concepts/code-scanning/code-scanning) |
| Security policy | `SECURITY.md`; an organization default through its `.github` repository | not stated | 21B.13 |
| Private vulnerability reporting | A "Report a vulnerability" button; the report lands in a private draft advisory | administrators of public repositories can enable it | 21B.13, [reporting privately](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately) |
| Signature verification | "Verified", "Partially verified", "Unverified", or no badge; vigilant mode flags unsigned commits. Verification records persist since 10 December 2024 | not stated | 21B.6 |
| Audit log | Who did what in the organization, 180 days; searchable by a token's SHA-256 hash | all plans; streaming and Git events on Enterprise Cloud | 15.19, 21B.8 |
| Artifact attestations | A signed claim about which run built an artifact | public repositories on every plan; private ones only on Enterprise Cloud | 15.11 |

What push protection does not cover (21B.12): private repositories without Secret Protection; generic secrets such as passwords and connection strings; and by default a block is a prompt that anyone with write access can bypass with a reason. Provider coverage differs per credential type; the table is in section 21B.12.

What deleting does not remove (21B.10, 21B.19): a later commit, a force push, or making the repository private leaves the secret in old commits, pull request refs, forks and clones. Revoke or rotate first (21B.14). The checklists are in the [security cheat sheet](../cheatsheets/security-cheat-sheet.md) and the [security guide](../guides/security-guide.md).

> **Unverified.** How long GitHub retains unreachable commits, and a turnaround time for Support (21B.19); whether GitHub displays `gitsign` commits as verified (21B.6).

## 12. Where to go next

| You need | Go to |
|---|---|
| The `gh` commands for everything above | [GitHub CLI cheat sheet](../cheatsheets/github-cli-cheat-sheet.md) |
| Workflow syntax and the runbook for a failing workflow | [GitHub Actions cheat sheet](../cheatsheets/github-actions-cheat-sheet.md), [GitHub Actions guide](../guides/github-actions-guide.md) |
| Security checklists and incident steps | [security cheat sheet](../cheatsheets/security-cheat-sheet.md), [security guide](../guides/security-guide.md) |
| "Why can't I merge?", rejected pushes, authentication failures | [troubleshooting playbook](../playbooks/troubleshooting-playbook.md); sections 18.17, 16.18 to 16.20 |
| A force-pushed or deleted branch | [disaster-recovery playbook](../playbooks/disaster-recovery-playbook.md), [emergency recovery](../cheatsheets/emergency-recovery-one-page.md) |
| Every 🔴 and 🟡 command | [command safety](command-safety.md) |
| The Git commands | [Git command reference](git-command-reference.md), [Git cheat sheet](../cheatsheets/git-cheat-sheet.md) |
| Terms, sources and revision | [glossary](glossary.md), [references](references.md), [revision checklist](../revision/revision-checklist.md) |
