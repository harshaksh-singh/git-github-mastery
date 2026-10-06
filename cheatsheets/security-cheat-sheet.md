# Security cheat sheet

> **Baseline.** Git 2.55.0; GitHub CLI 2.88.1 (flags checked with `gh <command> --help`); GitHub facts as of 1 October 2026. Nothing here was run against GitHub. 🟢 SAFE reads · 🟡 CAUTION changes something recoverable · 🔴 DANGEROUS can destroy or expose. The numbers in brackets are textbook sections: Chapter 16 (authentication), 14B (signing), 21A (Actions security), 21B (repository security and leak response).

This sheet is the one-look version. The checklists and the three runbooks (a committed secret, a compromised credential, a compromised action) are in the [security guide](../guides/security-guide.md). Every 🟡 and 🔴 command with its five answers is in [command safety](../reference/command-safety.md).

## 1. Three sentences to keep

1. **A leaked secret is fixed at the issuer, not in Git.** Revoke or rotate first; deleting the file, force-pushing or making the repository private does not remove a secret, because a commit is a permanent snapshot and every clone, fork and cached view may hold it (21B.10, 21B.14).
2. **Identity in a commit is text.** Author and committer are two lines that the person running Git supplies; neither Git nor a push checks them. A signature proves that a key holder signed those bytes, and nothing about who wrote the change or whether it is good (14B.17, 21B.5, 21B.7).
3. **A local control is feedback; only a server-side control is enforcement.** Hooks, ignore rules and attributes can be skipped or missing; rulesets, push protection and required checks cannot be skipped by the author (14C.13, 28.10).

## 2. Credentials: what each one is and how far a leak reaches

| Credential | Prefix | Lifetime | Reaches | Revoke | Section |
|---|---|---|---|---|---|
| Personal access token (classic) | `ghp_` | Long-lived; no expiry required | By scope, across every repository and organization the user can reach | Delete the token in the account's settings | 16.6 |
| Fine-grained personal access token | `github_pat_` | Configurable, up to one year or none | One owner, optionally selected repositories, per-permission read or write | As above | 16.6 |
| OAuth app token (what `gh auth login` produces) | `gho_` | Long-lived; expiring tokens are the default for new apps since 14 August 2026 | By scope | Revoke the app's authorization; `gh auth login` again | 16.6 |
| GitHub App installation token | `ghs_` | 1 hour | The repositories and permissions of the installation | Expires; fix the installation | 16.6, 16.14 |
| `GITHUB_TOKEN` in a workflow | (an installation token) | The job | One repository, limited by `permissions` | Ends with the job | 21A.3 |
| SSH key | none | Until deleted; GitHub deletes one unused for a year | Whatever the account can reach | `gh ssh-key delete` 🔴, or the web interface | 16.8 |
| Deploy key | none | No expiry | One repository; read-only unless write access is allowed | Delete it on the repository 🔴 | 16.14 |

Over HTTPS, GitHub accepts a token where HTTP expects a password, and nothing else (16.3). A token never goes into a URL, a file or a command line (16.7).

## 3. Authentication diagnosis

Read the first word of the error: it says who wrote the line (16.17). `ssh:` and `Permission denied (publickey)` come from your `ssh` client; `remote:` comes from GitHub's server; `fatal: Could not read from remote repository.` is Git reporting that the other side closed the connection and never contains the cause.

| Command | Purpose | Example | Risk | Common mistake | Recovery |
|---|---|---|---|---|---|
| `git remote -v` | Which protocol and which host the remote uses (16.17) | `git remote -v` | 🟢 | Debugging SSH when the remote is HTTPS | Not needed |
| `ssh -T git@github.com` | Which account the SSH key authenticates as (16.12) | `ssh -T git@github.com` | 🟢 | Accepting a new host key without comparing the fingerprint | `ssh-keygen -R github.com` 🟡 |
| `ssh -vT git@github.com` | Which keys are offered, in which order (16.18) | `ssh -vT git@github.com` | 🟢 | Reading only the last line | Not needed |
| `ssh -G <host>` | The configuration `ssh` would use, without connecting (16.10) | `ssh -G github.com` | 🟢 | Forgetting that Git hands `ssh` the host name from the URL, alias included | Not needed |
| `ssh-add -l` | The keys the agent holds (16.9) | `ssh-add -l` | 🟢 | The wrong account's key is offered first and accepted | `IdentitiesOnly yes` with the right `IdentityFile` |
| `ssh-keygen -l -F github.com` | The host key you have remembered (16.11) | `ssh-keygen -l -F github.com` | 🟢 | Fixing `Host key verification failed.` by switching the check off 🔴 | Compare with the published fingerprints; if no announcement explains a change, do not connect |
| `git config get --show-origin --all credential.helper` | Which helpers answer, and from which file (16.5) | as shown | 🟢 | Several helpers per host: Git never asks and keeps failing with 403 | Reset the helper list for the host, or delete the keychain entry |
| `git credential fill` | What a helper would return; it prints the secret on your screen (16.4) | `printf 'protocol=https\nhost=github.com\n\n' \| git credential fill` | 🟢 | Running it in a shared or recorded terminal | Revoke the token if it was exposed |
| `gh auth status` | Which account and token `gh` uses (16.5) | `gh auth status` | 🟢 | `--show-token` 🔴, which prints a live token | Revoke the token |
| `gh auth setup-git` | Makes `gh` the credential helper for Git (16.5) | `gh auth setup-git` | 🟡 | `gh` works and `git push` over HTTPS does not, because Git has another helper | `git config unset` the helper line |
| `git config set --global transfer.credentialsInUrl die` | Git refuses a URL that contains a credential (16.7) | as shown | 🟡 | With `die`, `git remote set-url` cannot replace the bad URL | `git config set remote.origin.url <clean URL>`; revoke the token |

> **Version note.** The SSH changes of 14 October 2026 and 13 January 2027 are in Chapter 16, section 16.16; check your key types against that section before those dates.

## 4. Signing

| Item | What to know | Section |
|---|---|---|
| What is signed | The bytes of one commit or one annotated tag; the signature is stored inside that object | 14B.15 |
| SSH signing setup | `git config set --global gpg.format ssh`; `git config set --global user.signingKey <public key file>`; `git config set --global gpg.ssh.allowedSignersFile <file>`; then `commit.gpgSign` and `tag.gpgSign` (SSH format: Git 2.34 or later) | 14B.16 |
| Sign | `git commit -S`, `git tag -s <name>`; with `commit.gpgSign=true` every commit, and `--no-gpg-sign` opts one out | 14B.16 |
| Verify locally 🟢 | `git verify-commit <commit>`, `git verify-tag <tag>`, `git log --show-signature`, `git log --format='%h %G? %GS %s'` | 14B.16 |
| Common mistake | Verifying SSH signatures without an allowed-signers file: a signed commit shows `No signature`. Replacing the old key in that file at rotation: old commits turn from `G` to `U`; rotation adds, never replaces | 14B.19 |
| What a signature does not prove | That the named author wrote the change; that the signer was authorized to ship it; anything about a release archive, a wheel or a container image built elsewhere | 14B.17, 21B.7 |
| GitHub's badge (GitHub, not Git) | Verified, Partially verified, Unverified, or no badge; without vigilant mode an unsigned commit gets no badge at all. Commits made in the web interface, including merge-commit and squash merges, are signed by GitHub with its own key | 21B.6 |
| Requiring signatures | The ruleset rule is evaluated against the commits a pull request introduces, not only the merge commit; see the merge-method consequences in Chapter 18 | 18.10 |

The configuration block for signing is in the [professional configuration](../reference/professional-git-configuration.md), section 7.

## 5. The Git client on your machine

| Setting or habit | What it protects against | Command | Risk | Section |
|---|---|---|---|---|
| Clone, never unpack | A `.git` directory somebody else wrote can carry hooks and configuration that run programs with your permissions | `git clone --no-local <dir> <new>` for a directory you were given | 🟢 | 21B.2 |
| `safe.directory` | Git refuses a repository owned by another operating-system user (`detected dubious ownership`) | `git config set --global --append safe.directory <dir>` after reading `<dir>/.git/config` and `<dir>/.git/hooks` | 🟡 | 21B.3 |
| `safe.bareRepository=explicit` | A bare repository hidden inside a working tree | `git config set --global safe.bareRepository explicit` | 🟡 | 21B.3, 14D.4 |
| `protocol.file.allow` (default `user`) | Commands that start a clone on their own over the `file` transport, such as submodule initialization | Leave the default; `-c protocol.file.allow=always` on single commands in local test setups | 🟢 | 21B.3, 23.4 |
| `transfer.credentialsInUrl=die` | A token stored in `.git/config` through a URL | See section 3 | 🟡 | 16.7 |
| Hooks and `core.hooksPath` | Programs that run on your machine at commit and push | `git hook list --show-scope <event>` | 🟢 | 14C.12 |
| Stage by name | Committing a secret with `git add .` | `git diff --cached` before every commit | 🟢 | 21B.14 |

## 6. Actions hardening

The full checklist is section 4 of the [security guide](../guides/security-guide.md), and the review checklist for workflow pull requests is Chapter 21A, section 21A.19. Pins are in [`ACTION_PINS.md`](../workflows/ACTION_PINS.md); a secure-by-default example is [`12-secure.yml`](../workflows/12-secure.yml).

| Rule | Why | How to check | Section |
|---|---|---|---|
| Top-level `permissions`, starting from `contents: read`; more only on the job that needs it | Every job gets a token for the repository; the key decides what it may do | `grep -n 'permissions' .github/workflows/*.yml` | 21A.3 |
| Pin every action to a full commit ID | A tag can be moved by whoever controls the action's repository | `grep -n 'uses:' .github/workflows/*.yml` 🟢 | 21A.7 |
| No untrusted `${{ }}` value inside the text of `run`; pass it through `env` | The expression is replaced in the script text before the shell starts: script injection | Read every `run` block for `github.event.` | 21A.6 |
| No `pull_request_target` or `workflow_run` that checks out or executes pull request code | They run with your token and secrets in response to a stranger's pull request (the "pwn request") | Read the checkout `ref` of such workflows | 21A.5 |
| Design pull request CI to need no secrets | Fork runs get a read-only token and no secrets | Run the job from a fork | 21A.4 |
| `persist-credentials: false` on checkout unless a step must push | The job token otherwise stays in `.git/config` for later steps | Read the checkout step | 21A.16 |
| OIDC in place of stored cloud keys | The cloud issues a credential valid for that job only | The trust policy names repository, ref or environment | 21A.10 |
| Deployment secrets in a protected environment | A human decision or a branch condition stands between the job and the secret | The environment exists and has the rules you think it has | 21A.13 |
| Treat caches and artifacts as untrusted input | Whoever can write the cache entry your release job restores controls that job | Release jobs build without restoring shared caches | 21A.11 |
| No self-hosted runner for a public repository; ephemeral runners | The runner is your machine on your network and keeps state between jobs | Runner settings | 21A.12 |
| An owner for `/.github/` in `CODEOWNERS` | Otherwise any writer changes workflows and reviewers in one pull request | `git show <base>:.github/CODEOWNERS` 🟢 | 19.8 |

> **Version note.** Platform changes with dates, including the handling of `pull_request_target` in public repositories after 2 November 2026, are in Chapter 21A, section 21A.15.

## 7. Repository security features (GitHub, not Git)

| Feature | What it does | Plan gate, as the chapter states it | Section |
|---|---|---|---|
| Secret scanning | Scans the entire Git history on all branches, plus issues, pull requests, discussions and wikis | Free on public repositories; organization-owned private and internal repositories need GitHub Secret Protection | 21B.12 |
| Push protection | Blocks a push that contains a recognized secret before it reaches the repository | See 21B.12 for the two forms | 21B.12 |
| Dependabot | Alerts, security updates and version updates: three features that share a name | See 21B.13 | 21B.13 |
| Code scanning | Analyzes code with CodeQL or tools that upload SARIF; runs on Actions and consumes minutes | Free on public repositories; private ones need GitHub Code Security | 21B.13 |
| `SECURITY.md` and private vulnerability reporting | Says how to report a problem, and gives reporters a private channel | See 21B.13 | 21B.13 |
| Rulesets | Server-side conditions on ref updates: reviews, checks, signatures, no force push, no deletion | Chapter 18, section 18.15 | 18.3 |

Prices, limits and the full plan matrix are in the [GitHub reference](../reference/github-reference.md), sections 3 and 11, with their sources.

## 8. A secret was committed: the six steps, in this order

The order is the lesson (21B.14). The commands for each step, with output from a sandbox, are in Chapter 21B, sections 21B.11 and 21B.17, and the runbook is section 6 of the [security guide](../guides/security-guide.md).

| Step | What to do | Commands | Risk | Section |
|---|---|---|---|---|
| 1. Contain | Revoke or rotate the credential first. That alone may be sufficient | At the issuer, not in Git | none in Git | 21B.14 |
| 2. Assess | Identify the secret, its owner and what it can reach; find every commit and ref that holds it; include forks and force-pushed commits | `git log --oneline --all -S'<string>'`; `git log --oneline --all -G'<regex>'`; `git grep -n '<pattern>' $(git rev-list --all)` | 🟢 | 21B.11 |
| 3. Eradicate | Remove the secret from current code; rewrite history only where warranted | Unpushed: `git reset --soft @{u}` 🟡 and recommit, or an interactive rebase 🟡. Published: a history filter in a fresh clone 🔴 (git-filter-repo 2.47 or later, not installed here), `git push --force --mirror origin` 🔴 after a freeze, then a GitHub Support request | 🟡 to 🔴 | 21B.16, 21B.17, 21B.19 |
| 4. Recover | Update dependent services with the new credential; collaborators re-clone; in stale clones `git reflog expire --expire=now --all` and `git gc --prune=now` 🔴 after their owners saved their work; re-enable force-push protection | as named | 🔴 | 21B.18 |
| 5. Communicate | Tell collaborators exactly what to do with their clones; keep a reachable disclosure contact such as `SECURITY.md` | none | none | 21B.14 |
| 6. Prevent | Push protection; pre-commit and CI scanning; short-lived credentials through OIDC; `git diff --cached` in place of `git add .` | Section 5 and section 6 above | 🟢 | 21B.14 |

Two mistakes that undo the work: rewriting the branches and forgetting the tags, and a stale clone that pushes the secret back to `main` after the cleanup (21B.17, 21B.18).

## 9. When it is already an incident

- Local recovery, one page: [emergency recovery](emergency-recovery-one-page.md).
- Procedures: [disaster-recovery playbook](../playbooks/disaster-recovery-playbook.md) and Chapter 30.
- Compromised token, key, account or action: sections 7 and 8 of the [security guide](../guides/security-guide.md).
