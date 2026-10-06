# Security guide: Git and GitHub

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026, from the Phase 0 report and the official pages linked here. This guide is operational: checklists and runbooks. The mechanisms, transcripts and case studies are in [Chapter 21B](../textbook/ch21b-repository-security-incident-response.md) and, for GitHub Actions, in Chapter 21A. Every `gh` command below was checked against `gh <command> --help`; none was run against GitHub. User-interface paths are quoted from the documentation and change over time.

## 1. How to use this guide

| You need to | Go to |
|---|---|
| Set up a new repository so that a mistake is caught early | section 2 |
| Decide the defaults for an organization | section 3 |
| Review or write a workflow | sections 4 and 9 |
| Decide which credential an automation gets | section 5 |
| Respond: a secret was committed | section 6 |
| Respond: a token, key or account may be compromised | section 7 |
| Respond: an action you use was compromised, or a workflow you did not write appeared | section 8 |
| Work on an LLM application, notebooks, or agents in CI | section 10 |
| Harden your own machine's Git | section 11 |

Three rules sit above every checklist. They are the conclusions of Chapter 21B, and each runbook applies them.

1. **Rotate first.** A leaked credential is dangerous until its issuer revokes it and harmless afterwards. Nothing you do to a repository changes that.
2. **Treat every pushed commit as published.** Deleting, force-pushing and making a repository private change who finds the data easily, not whether it exists.
3. **Display is not evidence.** An author name, an avatar and a star count are text and numbers that other people control. Evidence is a verified signature, the authenticated pusher in a log, and the issuer's audit trail.

Each item below carries a label for the layer it belongs to: **[Git]** is a setting on a machine, **[GitHub]** a platform setting, **[Process]** something people do.

## 2. Repository hardening checklist

Work through this when you create a repository, and again when you inherit one. "Free" and "paid" refer to the plan gates in the Phase 0 report: on a public repository the scanning features are free; on a private repository secret scanning and repository push protection need GitHub Secret Protection ($19 per active committer per month), and code scanning needs GitHub Code Security ($30), both sold on Team and Enterprise plans ([price list](https://github.com/security/plans), [security features](https://docs.github.com/en/code-security/getting-started/github-security-features)).

### 2.1 Before the first commit

- [ ] **[Git]** A `.gitignore` that names `.env`, `.env.*` (with an exception for `.env.example`), key files (`*.pem`, `*.key`), local credential files of the tools you use, and notebook checkpoints. Ignoring a file that is already tracked does nothing: untrack it with `git rm --cached <file>`.
- [ ] **[Git]** A committed `.env.example` with variable names and no values, so that nobody needs to pass a real `.env` around.
- [ ] **[Process]** Stage named paths and read the staged diff. `git add -A` and `git add .` are how a `.env` gets committed.

```bash
git add src/ tests/ pyproject.toml
git diff --cached --stat
git diff --cached
```

- [ ] **[Git]** A secret scanner as a pre-commit hook for fast feedback. A client-side hook is advice: `git commit --no-verify` skips it. It never replaces the server-side items below.

### 2.2 Secret scanning and push protection

- [ ] **[GitHub]** Secret scanning enabled. Public repositories: free and automatic. It scans the whole history on all branches, plus issues, pull requests, discussions and wikis ([secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning)).
- [ ] **[GitHub]** Push protection for the repository enabled. It is off by default and is the only form that protects a private repository and that records a bypass ([push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection)).

```bash
gh repo edit OWNER/REPO --enable-secret-scanning --enable-secret-scanning-push-protection
```

- [ ] **[GitHub]** Your own account's "Push protection for yourself" left on (the default since 29 February 2024). It guards only your pushes to public repositories.
- [ ] **[Process]** Know the gaps: generic passwords and connection strings are not blocked; several providers are not covered in one or more of the three columns (notified, blocked, validity-checked); a block can be bypassed with a reason unless delegated bypass is configured. Read the coverage table in Chapter 21B, section 21B.12, for the providers you use.
- [ ] **[GitHub]** A scanner in CI over the full history on every pull request, because CI cannot be skipped with `--no-verify`.

### 2.3 Branches, tags and review

- [ ] **[GitHub]** A ruleset on the default branch: require a pull request, required status checks, block force pushes, block deletion ([Chapter 18](../textbook/ch18-branch-protection.md)).
- [ ] **[GitHub]** A ruleset on release tags (`v*`): block updates and deletions. A moved tag is how a release, or an action, is repointed.
- [ ] **[GitHub]** `CODEOWNERS` placed in `.github/`, with owners for `.github/workflows/` and for the CODEOWNERS file itself, and "require review from code owners" switched on ([code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners#codeowners-and-branch-protection), [Chapter 19](../textbook/ch19-codeowners.md)).
- [ ] **[GitHub]** Decide on "Require signed commits". If you enable it, "Rebase and merge" stops working on that branch, because GitHub creates those commits without a signature; squash and merge commits are signed by GitHub.

```bash
gh ruleset list --repo OWNER/REPO
```

### 2.4 Dependencies and code

- [ ] **[GitHub]** Dependency graph, Dependabot alerts and Dependabot security updates enabled (free on every plan).
- [ ] **[GitHub]** `.github/dependabot.yml` for version updates of each ecosystem in the repository, including `github-actions`. Lab 30.2 has a checked example. Do not copy old files: the `reviewers` option was removed on 8 August 2025.
- [ ] **[GitHub]** Code scanning with CodeQL default setup. Know that the weekly scheduled scan is disabled after six months without pushes or pull requests ([default setup](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/configure-code-scanning/configure-code-scanning)).
- [ ] **[Process]** Lock files committed; container base images pinned by digest where reproducibility matters (Chapter 28).

### 2.5 A way to tell you

- [ ] **[GitHub]** `SECURITY.md` with supported versions and a reporting address that someone reads ([security policy](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/add-security-policy)).
- [ ] **[GitHub]** Private vulnerability reporting enabled on public repositories. It is a separate feature from `SECURITY.md` ([reporting privately](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately)).

### 2.6 Access

- [ ] **[GitHub]** Collaborators through teams, with the lowest role that works. Write access is access to every Actions secret of the repository, because a writer can edit a workflow ([secure use](https://docs.github.com/en/actions/reference/security/secure-use#use-secrets-for-sensitive-information)).
- [ ] **[GitHub]** Deploy keys reviewed: each one is long-lived and outlives the person who added it.

```bash
gh repo deploy-key list --repo OWNER/REPO
gh secret list --repo OWNER/REPO
```

- [ ] **[Process]** An inventory line for the repository: which secrets it holds, which credentials can push to it, who owns each.

## 3. Organization baseline

A repository checklist depends on every maintainer remembering it. An organization baseline makes the important items defaults. Plan gates are from the Phase 0 report, section 2; verify them for your plan before you promise a control.

| Area | Baseline | Why | Source |
|---|---|---|---|
| Accounts | two-factor authentication required for all members; SSO where the plan has it | account takeover by password is the cheapest attack; note that a stolen session bypasses the second factor | Chapter 16 |
| Tokens | fine-grained tokens preferred; an organization policy that requires approval and limits lifetime; classic tokens restricted | a classic token reaches every repository its owner can reach | [token policy](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization) |
| Automation identity | GitHub Apps for integrations; the App's private key in a secrets manager and on a rotation schedule | installation tokens last one hour, the private key never expires | [credential types](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/github-credential-types) |
| Rulesets | organization-level rulesets for default branches and release tags; repository rulesets may be stricter, never looser | defaults that a new repository inherits | [Chapter 18](../textbook/ch18-branch-protection.md) |
| Push rulesets | block file paths and extensions that should never be pushed (`.env`, `*.pem`), where the plan allows | applies across the fork network | Chapter 18 |
| Secret Protection | enabled by security configuration on every repository; delegated bypass so that a block is not a prompt | closes the private-repository gap and the self-service bypass | [delegated bypass](https://docs.github.com/en/code-security/concepts/secret-security/delegated-bypass) |
| Actions | default `GITHUB_TOKEN` permission read-only; allowed-actions policy; required SHA pinning | section 4 | Chapter 21A |
| Audit log | streamed or exported; Git events included | the organization log covers 180 days; Git events (Enterprise Cloud) are retained for seven days, are not shown in the interface, and are not returned by a token-hash search | [audit log](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization) |
| Reporting | a default `SECURITY.md` in the organization's `.github` repository | a finder needs somewhere to go | [security policy](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/add-security-policy) |
| Monitoring | scanning of public GitHub for the organization's secrets, including employees' and contractors' personal accounts | in the report's cases detection came from outsiders almost every time | Chapter 21B, section 21B.20 |
| People | offboarding removes the member, their tokens' organization access, their deploy keys, and transfers their App and secret ownership | a job that runs as a former employee is in nobody's inventory | Chapter 16, section 16.14 |

Two baseline items are about existing state, not settings:

- **Old organizations kept old defaults.** The read-only default for the Actions `GITHUB_TOKEN` applies to repositories and organizations created since February 2023; existing ones were not changed ([GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token)). Check, do not assume.
- **Internal is not safe.** GitGuardian found internal repositories about six times more likely than public ones to contain a hardcoded secret ([State of Secrets Sprawl 2026](https://www.gitguardian.com/state-of-secrets-sprawl-report-2026)). Run a history scan across private repositories once, and budget time for what it finds.

## 4. Actions hardening checklist

Chapter 21A explains each item with a vulnerable and a fixed workflow, and `workflows/12-secure.yml` is the worked example. This is the checklist form. The facts are from the Phase 0 report, section 14.

### 4.1 Every workflow

- [ ] Top-level `permissions:` with `contents: read`, and per-job additions only where a job needs them. Once any scope is named, every unnamed scope is none ([permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions)).
- [ ] CI for pull requests uses `pull_request`. Fork pull requests then get a read-only token and no secrets, which is the design, not a bug to work around.
- [ ] No `pull_request_target`, `workflow_run` or `issue_comment` workflow checks out and runs code from the pull request. That combination is the "pwn request" ([guidance](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)).
- [ ] No `${{ }}` expression containing attacker-controlled text (titles, bodies, branch names, file names, commit messages) inside a `run:` script. Pass the value through `env:` and use the shell variable ([script injections](https://docs.github.com/en/actions/concepts/security/script-injections)).
- [ ] Every third-party action pinned to a full-length commit SHA with the version as a comment; Dependabot keeps the pins current ([secure use](https://docs.github.com/en/actions/reference/security/secure-use#using-third-party-actions)).
- [ ] `persist-credentials: false` on checkout where the job does not push.
- [ ] No remote script piped into a shell. A script fetched at run time is the same risk class as a mutable tag.

### 4.2 Jobs that hold secrets or publish

- [ ] Cloud access through OIDC (`id-token: write`), with a trust policy that constrains the token's subject to the repository and the branch or environment ([OIDC](https://docs.github.com/en/actions/reference/security/oidc)).
- [ ] Deployment secrets scoped to environments with required reviewers, not repository-wide.
- [ ] Release and deploy jobs declare `cache-mode: read` or `none`. Caches are not confidential and not verified ([dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching#cache-access-for-low-trust-workflow-triggers)).
- [ ] A job that runs untrusted code holds no secret. Log masking is not a boundary: the technique that recurs in the 2025 and 2026 incidents reads secrets from the runner's memory.

### 4.3 Runners and policy

- [ ] No self-hosted runner on a public repository, or only ephemeral ones with approval for all outside contributors ([hardening](https://docs.github.com/en/actions/reference/security/secure-use#hardening-for-self-hosted-runners)).
- [ ] Organization policy: allowed actions restricted; SHA pinning required (enforceable since August 2025).
- [ ] The approval setting for fork pull requests is stricter than the default, which gates only first-time contributors.
- [ ] Static analysis of workflow files in CI: CodeQL's workflow analysis is in default setup; zizmor and actionlint are third-party tools ([zizmor](https://docs.zizmor.sh/audits/), [actionlint](https://github.com/rhysd/actionlint/blob/main/README.md)).
- [ ] You know the date 2 November 2026: from then the default workflow execution protection blocks `pull_request_target` in public repositories unless a maintainer allows it ([changelog](https://github.blog/changelog/2026-09-17-workflow-execution-protections-in-github-actions-generally-available/)).

## 5. Token hygiene rules

Ten rules. Each has its reason, because a rule without a reason is the first to be dropped under deadline.

1. **Choose the narrowest credential that does the job.** In order: OIDC or the job-scoped `GITHUB_TOKEN`; a GitHub App installation token; a fine-grained personal access token with expiry; a deploy key for single-repository read access; a classic token or machine user last, with a written reason. *Reason:* reach and lifetime are the blast radius.
2. **Every long-lived credential has an owner, an expiry and an inventory line.** *Reason:* 64% of secrets confirmed valid in 2022 were still valid when GitGuardian retested them.
3. **A token never goes into a URL, a command line, a commit, an issue, a chat message or a prompt to an AI assistant.** *Reason:* each of those is stored somewhere you do not control: `.git/config`, shell history, process lists, logs, vendor systems (Chapter 16, section 16.7).
4. **Secrets reach programs through the environment or a secrets manager, read at start-up.** *Reason:* a value that is never written to a tracked path cannot be committed.
5. **Set a secret from standard input or a file, not as an argument.**

```bash
gh secret set LLM_API_KEY --repo OWNER/REPO < key.txt        # reads the value from standard input
gh secret set LLM_API_KEY --env production --repo OWNER/REPO < key.txt
```

6. **One secret per consumer.** Staging and production, CI and the evaluation job, each engineer: separate keys. *Reason:* you can revoke one without an outage, and the provider's log tells you which one was used.
7. **Rotate on a schedule, and on every departure and every incident.** *Reason:* rotation that is routine is fast when it is urgent.
8. **Rotate everything a compromised runtime could read, together.** *Reason:* partial, staged rotation is the root cause of the Internet Archive's second breach and of the Trivy follow-on compromise in the report.
9. **Review what is authorized, twice a year.** Personal access tokens, SSH keys, authorized OAuth apps, installed GitHub Apps, deploy keys.

```bash
gh auth status
gh ssh-key list
gh gpg-key list
gh repo deploy-key list --repo OWNER/REPO
```

10. **Know how you would investigate before you need to.** The audit log is searched by `hashed_token`, a token's Git events need an export and are retained for seven days, and the organization log covers 180 days (section 7).

## 6. Runbook: a secret was committed

**Trigger.** A secret scanning alert, a push protection bypass, a scanner in CI, a provider's email, a colleague's message, or your own eyes.

**First move.** Revoke or rotate at the issuer. Not `git rm`. Not a force push.

Keep a timeline from the first minute: who noticed, when, what was done. You will need it for step 5 and for the postmortem.

### Step 1. Contain

| Do | Detail |
|---|---|
| Identify the issuer and the owner of the secret | the prefix, the variable name and the file usually tell you; if the owner cannot be found in ten minutes, escalate, do not wait |
| Revoke or rotate it in the issuer's console | issue the replacement as a *new* secret; do not "regenerate" in a way that leaves the old one valid for a grace period unless you chose that knowingly |
| Confirm the old value no longer works | from the issuer's status, not by assumption. Partner notification from GitHub does not guarantee revocation: an xAI key stayed valid about two months after the first alert |
| If the secret is a GitHub token | GitHub revokes its own tokens pushed to public repositories; still revoke it yourself and go to section 7 |

Do not paste the secret into a ticket, a chat or an AI assistant while doing this. Refer to it by issuer, name and last four characters.

### Step 2. Assess

Establish five facts. The Git commands are from Chapter 21B, section 21B.11; run them in a current clone.

```bash
# 1. Where did it enter, who committed it, when?
git log --all -p -S'<a distinctive part of the secret>' --diff-filter=A

# 2. In which snapshots is it present?
git grep -l '<pattern>' $(git rev-list --all)

# 3. Which branches and tags contain the introducing commit?
git branch -a --contains <commit>
git tag --contains <commit>

# 4. Are there other secrets of the same shape?
git log --all --oneline -G'<regular expression for the shape>'
```

| Fact | Source |
|---|---|
| What the secret can reach | the issuer's console: scopes, roles, resources |
| First commit, author, date; first push | Git (above); your clone's reflog of the remote-tracking branch; on GitHub the Activity view |
| Which refs contain it | Git (above). Include tags, unmerged branches and pull request branches |
| Who could read it | repository visibility and its history of visibility; collaborators; forks, deleted forks included; CI logs; clones |
| Whether it was used | the **issuer's** audit log for the exposure window; GitHub's audit log if it is a GitHub credential (section 7) |

With secret scanning, the alert shows the validity status and whether the secret is publicly exposed or found in several places ([remediation guide](https://docs.github.com/en/code-security/tutorials/remediate-leaked-secrets/remediating-a-leaked-secret)). Treat "used: unknown" as "used" when you decide what else to rotate.

### Step 3. Eradicate

1. Remove the secret from the current code and stop tracking the file. Commit and push normally.

```bash
git rm --cached .env
printf '.env\n' >> .gitignore
git add .gitignore
git commit -m "Stop tracking .env"
```

2. Decide whether to rewrite history. Write the decision and its reason into the incident record.

| Rewrite | Do not rewrite |
|---|---|
| the data stays harmful after rotation, or cannot be rotated: personal data, customer records, proprietary weights, a key that devices pin | a credential that is revoked, with provider logs that show no use |
| a compliance obligation requires removal | a public repository, in the belief that removal un-publishes |
| nothing was pushed yet (then it is a local rebase or reset, not an operation) | before containment is complete |

3. If you rewrite, run it as an operation. The commands are GitHub's documented sequence ([removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)); git-filter-repo must be version 2.47 or later.

- [ ] Announce a freeze: nobody pushes until told. Name the time it starts.
- [ ] Note which rulesets block force pushes and tag updates; switch them off for the push and schedule switching them back on.
- [ ] In a **fresh clone**:

```bash
git clone https://github.com/OWNER/REPO
cd REPO
git-filter-repo --sensitive-data-removal --invert-paths --path PATH-TO-THE-FILE
# or, for strings inside files that must stay:
git-filter-repo --sensitive-data-removal --replace-text ../expressions.txt
```

- [ ] Verify before pushing. Both commands must print nothing:

```bash
git log --all --name-status -- PATH-TO-THE-FILE
git log -S'<a distinctive part of the secret>' --all -p --
```

- [ ] Save `.git/filter-repo/commit-map` and `first-changed-commits` with the incident record. Count affected pull requests:

```bash
grep -c '^refs/pull/.*/head$' .git/filter-repo/changed-refs
```

- [ ] Force-push all refs. `--mirror` also deletes remote refs that the clone lacks, which is why the freeze comes first.

```bash
git push --force --mirror origin
```

- [ ] Contact GitHub Support with the owner and repository name, the number of affected pull requests and the first changed commit or commits; mention orphaned LFS objects if the tool reported them. Support removes only sensitive data, and only where it determines that rotating credentials cannot mitigate the risk.
- [ ] Ask fork owners to delete or clean their forks. GitHub cannot give you their contact details.
- [ ] Switch the rulesets back on.

### Step 4. Recover

- [ ] Deploy the new secret to every consumer: CI secrets, environments, running services, colleagues' local files. Search for other places the old one was stored:

```bash
gh search code '<variable name>' --owner OWNER
gh secret list --repo OWNER/REPO
```

- [ ] If history was rewritten: every collaborator deletes their clone and clones again. Where that is impossible, per clone, from the git-filter-repo manual:

```bash
git tag -l | xargs git tag -d
git fetch --prune --tags
git rebase --onto origin/main <old-upstream-tip> <branch>      # rebase, never merge
git reflog expire --expire=now --all
git gc --prune=now
git cat-file -t <first-changed-commit>                         # must fail
```

The expiry step discards that clone's reflogs and stashes; save work first. Nobody re-runs the filter command themselves.

- [ ] Re-scan the server a day later and a week later. A stale clone that pulls and pushes merges the old history back with an ordinary fast-forward push (Chapter 21B, section 21B.18).
- [ ] Translate stored commit IDs (experiment records, model cards, deployment manifests) with the commit map.
- [ ] Close the secret scanning alert as revoked.

### Step 5. Communicate

To collaborators, at the freeze and again at the end. Give instructions, not background:

```text
Subject: ACTION REQUIRED: re-clone OWNER/REPO before you push anything

What happened: a credential was committed to OWNER/REPO on <date>. It was revoked at <time>.
What we did:   history was rewritten to remove it. Commit IDs from <first changed commit> on have changed.
What you do:   1. Do not pull. Do not push from your existing clone.
               2. Save unpushed work:  git format-patch origin/main   (or note the branch names)
               3. Delete the clone and clone again.
               4. Re-apply your work on the new history. Rebase or apply patches. Never merge an old branch.
Why:           a pull followed by a push from an old clone puts the credential back.
Questions:     <name>, <channel>
```

To leadership: what was exposed, for how long, what it could reach, whether the issuer's logs show use, what was rotated, what is still open, and what changes. To affected third parties and regulators as your obligations require; that decision belongs to legal and security leadership, and concealment is what turned Uber's 2016 breach into a regulatory case.

### Step 6. Prevent

Pick the control that would have stopped *this* leak at the earliest point, and one backstop behind it.

| The leak got through because | Control |
|---|---|
| `.env` was not ignored; `git add -A` | `.gitignore`; staging named paths; reviewing `git diff --cached` |
| nothing checked at commit time | a scanner as a pre-commit hook |
| the local hook was skipped or absent | push protection on the repository; a scanner in CI |
| the secret type is not a supported pattern | a custom pattern (Secret Protection) or a CI scanner with your own rules |
| the key was long-lived and broad | OIDC or short-lived tokens; one key per consumer; least privilege |
| the alert reached one inbox | alerts routed to a team with an on-call owner |

**Verification of the whole runbook.** The old secret is rejected by its issuer. The issuer's log was read for the exposure window. A full-history scan of the server is clean. Every consumer runs on the new secret. The incident record holds the timeline, the rewrite decision and, if applicable, the commit map.

**What not to do.** Do not start with Git. Do not make the repository private and call it contained. Do not rewrite a public repository's history as a substitute for rotation. Do not let colleagues "fix" their clones with `git pull`.

## 7. Runbook: a token, key or account may be compromised

**Trigger.** A GitHub credential appeared somewhere it should not; commits, pushes, workflow changes or new deploy keys that nobody recognizes; a login notification from an unknown location; malware found on a developer machine; a third party you authorized reports a breach.

**First move.** Revoke the credential or lock the account. Investigation comes second, and needs the token's hash, so compute that before you destroy your only copy.

### Step 1. Contain

```bash
# Hash the token for the audit-log search BEFORE revoking, if you still have its value.
# The value is read from a variable; it never appears on the command line.
printf '%s' "$LEAKED_TOKEN" | openssl dgst -sha256 -binary | base64
```

- [ ] Revoke the token, or remove the SSH key or deploy key, in GitHub's settings. For a GitHub App, rotate the private key and revoke installation tokens.
- [ ] For an account: change the password, review and regenerate second-factor recovery codes, sign out other sessions, and review the account's keys, tokens and authorized applications. An organization owner can remove the member while this happens.
- [ ] For a compromised machine: assume every credential readable on it is stolen, including browser sessions, which bypass the second factor (the CircleCI case). Rotate from a different machine.

### Step 2. Assess

| Question | Where to look |
|---|---|
| What could the credential reach? | its type and scopes (Chapter 21B, section 21B.8) |
| What did it do? | the audit log, searched for `hashed_token:"<hash>"` ([documentation](https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/reviewing-audit-logs-for-your-enterprise/identifying-audit-log-events-performed-by-an-access-token)) |
| Were repositories cloned or pushed? | Git events are excluded from interface and API searches and need an export |
| What changed in repositories? | the Activity view per repository; new or changed files under `.github/workflows/`; new branches and tags; new deploy keys, webhooks and secrets |
| Were commits forged? | commits displayed under a colleague's name without a verified signature; compare the displayed author with the pusher |

```bash
git log --all --since='<start of window>' --format='%h %G? %an <%ae> | %cn | %s'
git log --all --since='<start of window>' --name-status -- .github/workflows/
gh repo deploy-key list --repo OWNER/REPO
gh run list --repo OWNER/REPO --limit 50
```

`%G?` prints `N` for an unsigned commit and `G` for a good signature that your local configuration can verify (Chapter 14B). On GitHub, remember persistent verification: commits signed with a stolen key before you revoked it keep their "Verified" badge.

### Step 3. Eradicate

- [ ] Revert or remove what the intruder changed. Prefer `git revert` on shared branches so that the change and its reversal are both on record (Chapter 11).
- [ ] Remove workflows, runners, deploy keys, webhooks, collaborators and OAuth authorizations that you did not create.
- [ ] Rotate every secret the credential could read. A token with write access to a repository could read all its Actions secrets by adding a workflow; treat them all as exposed (section 8).

### Step 4. Recover, communicate, prevent

- [ ] Issue replacement credentials one level narrower than before, following section 5, rule 1.
- [ ] Tell the people whose names were used, the owners of affected repositories and, where secrets of third parties were reachable, those third parties.
- [ ] Prevent: mandatory two-factor authentication; fine-grained tokens with approval and expiry; vigilant mode for people whose names carry weight in review; "require signed commits" on protected branches; audit-log streaming; device hygiene, including a review of editor extensions (GitHub's May 2026 incident began with one).

**Verification.** The old credential is rejected. The audit-log search for its hash was run, including an export for Git events, and the results are attached to the incident record. Every change made in the window is accounted for as legitimate or reverted.

## 8. Runbook: a compromised action or a malicious workflow

**Trigger.** An advisory for an action or tool your workflows use; a tag of a third-party action that now points at a different commit; a workflow file you did not write; unexpected workflow runs, new self-hosted runners, or new repositories; secrets visible in logs.

**First move.** Stop the workflows from running. Then scope by time.

### Step 1. Contain

```bash
gh workflow list --repo OWNER/REPO --all
gh workflow disable <workflow-name-or-id> --repo OWNER/REPO
gh run list --repo OWNER/REPO --status in_progress
gh run cancel <run-id> --repo OWNER/REPO
```

- [ ] If a third-party action is compromised: disable every workflow that references it, in every repository. Find them:

```bash
gh search code 'uses: OWNER/ACTION' --owner YOUR-ORG
```

- [ ] If a malicious workflow was pushed: remove it from every branch it is on, not only the default branch, and treat the pushing credential as compromised (section 7).
- [ ] Remove self-hosted runners that you did not register.

### Step 2. Assess

- [ ] Establish the exposure window from the advisory. Where sources disagree, use the widest window: for the tj-actions incident of March 2025 the report records a conflict between CISA's window and the GitHub advisory's, and recommends CISA's for audits.
- [ ] List the runs in the window and the commit each used:

```bash
gh run list --repo OWNER/REPO --created YYYY-MM-DD --limit 200     # repeat for each day of the window
```

- [ ] For each such run, list what the job could read: repository and organization secrets, environment secrets, the `GITHUB_TOKEN` with its permissions, an OIDC token if `id-token: write` was set, and caches it could write.
- [ ] Check whether the workflow was pinned. In the tj-actions case only workflows pinned to a commit SHA were unaffected by the moved tags.
- [ ] If logs are public, assume anything printed to them was read.

### Step 3. Eradicate and recover

- [ ] Rotate **every** secret that any affected job could read, together. The scope after a supply-chain compromise is every credential reachable from the affected runtime ([CISA](https://www.cisa.gov/news-events/alerts/2025/03/18/supply-chain-compromise-third-party-tj-actionschanged-files-cve-2025-30066-and-reviewdogaction)).
- [ ] Delete caches that affected jobs could have written, so that a later privileged job does not restore poisoned content:

```bash
gh cache list --repo OWNER/REPO
gh cache delete --all --repo OWNER/REPO
```

- [ ] Review what the affected jobs published in the window: packages, container images, releases. Yank or replace artifacts you cannot vouch for, and tell their consumers.
- [ ] Replace the action reference with a commit SHA that you have reviewed, or remove the action.
- [ ] Re-enable workflows one at a time after the review of section 9.

### Step 4. Prevent

SHA pinning with Dependabot updates; an allowed-actions policy; code-owner review of `.github/workflows/`; read-only default token; no secrets in jobs that run untrusted code; monitoring for new workflows, runners and repositories. Pinning protects against moved tags. It does not protect against a malicious commit that you pin deliberately, or against unpinned actions nested inside a composite action.

**Verification.** No run in the window is unexamined. Every secret readable in the window was rotated and the old values are rejected. Caches are cleared. Published artifacts from the window are vouched for or withdrawn.

## 9. Review checklist for workflow changes

Use this on any pull request that touches `.github/workflows/`, an action's `action.yml`, or a script that a workflow runs. A reviewer who cannot answer a question asks it in the review.

**Trigger and trust**

- [ ] Which events trigger it, and can someone outside the organization cause one (a fork pull request, an issue, a comment)?
- [ ] Does it use `pull_request_target`, `workflow_run` or `issue_comment`? If so, does any step check out, build, install or execute code from the pull request? That is a blocker.
- [ ] Does any `run:` block contain `${{ github.event... }}`, `${{ github.head_ref }}` or another value an outsider controls? Require `env:` indirection.

**Privilege**

- [ ] Is there a top-level `permissions:` block, and is every write scope justified by a step that needs it?
- [ ] Which secrets does each job receive? Could the job do its work with fewer, or with an environment-scoped secret, or with OIDC?
- [ ] Does a job that handles untrusted input also hold a secret or a write token? Split it.

**Supply chain**

- [ ] Is every `uses:` pinned to a full commit SHA with a version comment? Is a new action from a source you have looked at?
- [ ] Does any step download and execute something at run time (`curl ... | sh`, an unpinned installer, `latest`)?
- [ ] Are container images referenced by digest where the job is privileged?

**State and runners**

- [ ] Can a low-trust run write a cache that a privileged run restores? What is the `cache-mode` of release jobs?
- [ ] Which runner does it use? A self-hosted runner on a public repository is a blocker without ephemeral runners and approval.
- [ ] Does `checkout` keep credentials (`persist-credentials`) in a job that does not push?

**Change control**

- [ ] Did a code owner for `.github/workflows/` approve?
- [ ] Does the change also touch CODEOWNERS, rulesets-as-code or `dependabot.yml`? Review those as privilege changes.
- [ ] Is an AI agent involved (section 10)? What can it read, what can it write, and whose text does it read?

## 10. AI and LLM projects

Your field has its own failure modes. Each item is tied to a finding in the Phase 0 report.

### 10.1 Keys

- [ ] **An LLM key is a data-access credential, not a billing detail.** The xAI key of 2025 reached at least 60 private and fine-tuned models.
- [ ] **One key per consumer, each with a spend cap where the provider offers one:** local development, CI evaluation, staging, production, each agent.
- [ ] **Know your providers' coverage.** In GitHub's pattern data as read on 1 October 2026, OpenAI, Anthropic and Hugging Face tokens are partner-notified, blocked by push protection and validity-checked; a Google Gemini API key is none of the first two; Mistral, Cohere, DeepSeek and Pinecone are blocked but not partner-notified; Perplexity, LangSmith and Weights & Biases keys are blocked with no validity check. Re-read the [supported patterns](https://docs.github.com/en/code-security/secret-scanning/introduction/supported-secret-scanning-patterns) list for your stack.
- [ ] **Model-hub tokens with write permission are supply-chain credentials.** Use read tokens to pull, and a separate, narrowly held token to publish. Hugging Face lets anyone invalidate a leaked token through a revocation endpoint ([Hugging Face](https://huggingface.co/docs/hub/en/security-tokens)).
- [ ] **A sharing link is a credential.** A storage URL with a long-lived, full-control token exposed 38 TB in the Microsoft AI research case. Share weights and datasets through read-only, expiring mechanisms.
- [ ] **MCP and tool configuration files hold secrets.** GitGuardian counted 24,008 unique secrets in MCP configuration files in 2025. Keep such files out of the repository or keep the secrets out of the files.

### 10.2 Notebooks

- [ ] Outputs are part of the file. A cell that prints a client object, request headers or an environment dump commits the secret although nobody typed it. Strip outputs before commit (Chapter 28 shows a clean filter).
- [ ] Scan notebooks in history with a regular expression, on every ref: `git log --all -G'<shape>' -- '*.ipynb'`.
- [ ] Never paste a key into a cell "for a minute". Read it from the environment in the first cell.

### 10.3 Coding agents on your machine

- [ ] Review what an agent staged before it commits: the report notes that commits co-authored by one coding agent leaked secrets at roughly twice the baseline rate. `git diff --cached` applies to its work as to yours.
- [ ] Do not give an agent a shell in which `.env` files, cloud credentials and your SSH agent are all readable unless the task needs them.
- [ ] Treat repository content as untrusted input to the agent: a README or an issue can contain instructions aimed at it.

### 10.4 Agents and evaluations in CI

- [ ] An agent in a workflow gets a dedicated, low-privilege, spend-capped key, and no write token unless the job requires one.
- [ ] It does not run automatically on untrusted contributions. Text in pull request titles, issue bodies and comments has been used to steer agents into revealing CI secrets; the report's sources for the April 2026 research are secondary reporting.
- [ ] LLM evaluations that need a paid key cannot run on fork pull requests under the `pull_request` trigger, because forks receive no secrets. Do not switch to `pull_request_target` to make them run. Run them after review, on a maintainer's push or an approved environment.
- [ ] Self-hosted GPU runners are persistent machines with data and credentials. The PyTorch case in the report was reached through a pull request. Use ephemeral runners and approval for all outside contributors.
- [ ] Datasets, prompts and evaluation fixtures pulled at run time are inputs to a privileged job. Pin them by hash or revision.

## 11. Workstation baseline for Git

```bash
git config set --global safe.bareRepository explicit
git config get --show-origin protocol.file.allow      # expect no output: leave the default
git config get --show-origin --all safe.directory     # expect single directories, never '*'
git hook list --show-scope post-checkout              # inside a repository: which hooks would run, and from where
```

- [ ] Clone; do not unpack an archive that contains `.git`. If you have one, `git clone --no-local <dir> <clean>` and work in the clean copy.
- [ ] Do not `--recurse-submodules` an untrusted repository. Clone, read `.gitmodules`, then decide.
- [ ] Keep Git current. Releases 2.45.1 and 2.50.1 fixed code execution during recursive clones.
- [ ] Sign commits (Chapter 14B), register the key on GitHub as a signing key, and only then enable vigilant mode.
- [ ] Cloning is the safe part. Installing, building and opening a notebook run the project's code.

## 12. Evidence sources at a glance

| Question | Source | Limit |
|---|---|---|
| What is in history? | `git log --all -S`, `-G`; `git grep` over `git rev-list --all` | only what your clone has fetched |
| What did my clone see the server do? | reflog of `origin/<branch>` | local to that clone |
| Who pushed, force-pushed, deleted a branch? | GitHub Activity view | per repository; access requirements not stated in the documentation read |
| What did a token do? | audit log, `hashed_token` search | 180 days at organization level; a token's Git events need an export, within seven days unless streamed |
| Was a secret used? | the issuer's audit log | varies by provider; the report compiled no provider-by-provider table |
| Which secrets exist in the repository? | secret scanning alerts | supported patterns only; private repositories need Secret Protection |
| What ran in CI, on which commit? | `gh run list`, `gh run view` | log retention applies |

## 13. Sources

- GitHub Docs, fetched 2 October 2026: [removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository); [remediating a leaked secret](https://docs.github.com/en/code-security/tutorials/remediate-leaked-secrets/remediating-a-leaked-secret); [about push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection); [Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference).
- [git-filter-repo manual](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt), fetched 2 October 2026.
- The Phase 0 report, sections 2, 12, 13 and 14, with the links carried into each item above.
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html).
- Git 2.55 manual pages: `git help git` (SECURITY), `git help config`, `git help hook`.
