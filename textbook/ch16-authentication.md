# Chapter 16: Authentication

> **Baseline.** Git 2.55.0, OpenSSH 10.2 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026, re-read on docs.github.com on 2 October 2026 where a link is given. Transcripts are real output from `labs/ch16/`. Nothing in this chapter connected to GitHub, read the keychain, an SSH agent, `~/.ssh` or the real Git configuration: every demo runs in a sandbox with a toy credential helper, throwaway keys, and `ssh -G`, which prints configuration without connecting. What GitHub's servers answer is described from the linked documentation.

## 16.1 Why this matters

Four questions a CTO can ask the morning after:

1. "The deploy job says `Repository not found`. I am looking at the repository in my browser. Which of the two is wrong?"
2. "The new laptop asked for a password on `git push`. She typed the right one. Why was it refused?"
3. "We gave Ravi write access on Monday. On Wednesday his push still fails with 403, and Git never asks him for anything. Why?"
4. "The engineer who wrote the nightly sync left in June. What does the job authenticate as today?"

Neither is wrong: the job's credential cannot see the repository, and GitHub answers "not found" on purpose (section 16.19). GitHub has not accepted account passwords for Git since 13 August 2021 (section 16.3). His keychain holds a credential for another account; a 403 does not make Git discard it, so Git keeps sending it (section 16.5). And the job runs as whoever created its token or key, which is why the answer should be "as an app that nobody can leave" (section 16.14).

Every one of these is diagnosed with the same three questions, asked in this order:

| Question | Decided by | Evidence |
|---|---|---|
| Which transport and which server? | the remote URL, after rewrites | `git remote -v`, `git remote get-url origin` |
| Which credential does the client present? | Git's credential helpers for HTTPS; `ssh`, its configuration and the agent for SSH | `GIT_TRACE=1`, `git config get --show-origin --all credential.helper`, `ssh -G`, `ssh-add -l` |
| Who does the server say you are, and what may that identity do? | GitHub: the account behind the credential, its roles, token permissions, SSO authorization | `ssh -T git@github.com`, `gh auth status`, the repository's access settings |

A failure is always in exactly one of the three. Commands copied from a search result usually change a different one.

## 16.2 Authentication versus authorization

**In one sentence.** Authentication establishes which account a connection belongs to; authorization decides what that account may do to this repository.

**Analogy.** A badge reader and a door list. The reader checks that the badge is real and whose it is. The list on each door says which badge holders may enter. The analogy breaks because GitHub often gives the same answer to both failures: an unknown badge and a known badge without access can both get "there is no such door", so the error text alone does not tell you which check failed.

**Precisely.** Git has no accounts and no passwords. It delegates the connection to a transport ([Chapter 12](ch12-remote-operations.md), section 12.13):

- Over **HTTPS**, Git speaks HTTP and attaches a username and a secret obtained from a credential helper or a prompt. For GitHub the secret is a token.
- Over **SSH**, Git starts the `ssh` program, which proves possession of a private key. Git never sees the key.

The server maps the token or key to an account (authentication) and then evaluates roles, token permissions and organization rules for the repository (authorization, [Chapter 15](ch15-github.md), section 15.4).

Three identities are involved in everyday work, and they are independent of each other:

| Identity | What it is | Set by | Checked by |
|---|---|---|---|
| Commit identity | the author and committer name and email written into commits | `user.name`, `user.email` | nobody: it is an assertion ([Chapter 14B](ch14b-config-tags-signing.md), section 14B.18) |
| Authentication identity | the GitHub account that a token or SSH key belongs to | the credential that the transport presents | GitHub, on every connection |
| Signing identity | the key that signed a commit or tag | `user.signingKey` | whoever verifies the signature ([Chapter 21B](ch21b-repository-security-incident-response.md)) |

You can push commits written by anyone, as any account that has Write, signed by any key or none. "It says Asha in the log" is not evidence of who pushed.

**In production.** A push to the release branch is traced. `git log` names the author, which proves nothing. The push itself was authenticated: the organization's audit log and the repository's activity view record the account, and for a token the audit log records which token ([Chapter 21B](ch21b-repository-security-incident-response.md)). Keep the two questions apart: who wrote the commit, and who moved the ref.

## 16.3 HTTPS: a token, never a password

**In one sentence.** Over HTTPS, GitHub accepts a token in the place where HTTP expects a password, and nothing else.

**Precisely.** "Beginning August 13, 2021, we will no longer accept account passwords when authenticating Git operations", GitHub announced ([GitHub Blog](https://github.blog/security/application-security/token-authentication-requirements-for-git-operations/)). Git still calls the secret a password, because to Git it is one: the prompt reads `Password for 'https://USER@github.com':` (section 16.4 shows it). GitHub's documentation says what to do at that prompt: "enter your personal access token", or better, let a credential helper supply one ([about remote repositories](https://docs.github.com/en/get-started/git-basics/about-remote-repositories#cloning-with-https-urls)). In practice nobody should type a token: the GitHub CLI or Git Credential Manager obtains one through the browser and hands it to Git ([caching credentials](https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git)).

> **Outdated advice.** Any tutorial in which `git push` asks for the GitHub account password and succeeds was recorded before 13 August 2021, or is wrong: the Phase 0 report lists 2023 videos that still state it. The same goes for `git://` URLs and DSA keys, removed on 15 March 2022 ([GitHub Blog](https://github.blog/security/application-security/improving-git-protocol-security-github/)).

> **Unverified.** The exact text that GitHub's server sends when a password is used is not quoted in any GitHub documentation the report could find. User reports show `remote: Invalid username or token. Password authentication is not supported for Git operations.`, and older reports a sentence naming the date 13 August 2021. Recognize the situation by Git's own last line, `fatal: Authentication failed for '<URL>'`, which is in Git's source ([remote-curl.c](https://github.com/git/git/blob/v2.55.0/remote-curl.c)).

Two more facts about the HTTPS path. Anonymous HTTPS works for public repositories, with rate limits that were lowered on 8 May 2025 ([changelog](https://github.blog/changelog/2025-05-08-updated-rate-limits-for-unauthenticated-requests/)). And since 15 September 2026 GitHub refuses SHA-1 in TLS, which only very old clients notice ([changelog](https://github.blog/changelog/2026-09-15-sha-1-in-https-on-github-sunset/)).

## 16.4 How Git asks for a credential

**In one sentence.** When a server demands authentication, Git asks each configured credential helper in turn, then falls back to prompting, and afterwards tells the helpers whether the credential worked.

**Analogy.** A receptionist with a key cabinet. Asked for a key, the receptionist looks in the cabinet (`get`). If the visitor had to bring their own key and it opened the door, it is hung in the cabinet (`store`). If a key from the cabinet did not open the door, it is thrown away (`erase`). The analogy breaks at the last step: the receptionist throws a key away only when the door says "wrong key" (401), not when it says "you may not enter" (403).

**Precisely.** A helper is a program that Git runs with one argument, `get`, `store` or `erase`, and a description of the request on standard input as `key=value` lines: `protocol`, `host`, and optionally `path` and `username` ([gitcredentials](https://git-scm.com/docs/gitcredentials)). `git credential fill`, `approve` and `reject` are the documented way to drive the same machinery by hand ([git-credential](https://git-scm.com/docs/git-credential)), so the whole exchange can be watched without a server.

**See it.** No helper is configured in the sandbox, and the lab forbids terminal prompts, as a CI job does:

<!-- snippet: ch16/credential-protocol/01-no-helper -->
```text
$ git config get --show-origin --all credential.helper
[exit status: 1]
$ printf 'protocol=https\nhost=github.com\n\n' | git credential fill
fatal: could not read Username for 'https://github.com': terminal prompts disabled
[exit status: 128]
```
<!-- /snippet -->

This is the error of every CI job that reaches a private repository without a credential. In a terminal Git would prompt. A stand-in for the person shows what it would ask, through `GIT_ASKPASS`:

<!-- snippet: ch16/credential-protocol/02-askpass -->
```text
# ~/lab-bin/askpass stands in for you at the keyboard: it prints the prompt and answers.
$ printf 'protocol=https\nhost=github.com\n\n' | GIT_ASKPASS=~/lab-bin/askpass git credential fill
Git asked: Username for 'https://github.com': 
Git asked: Password for 'https://lab-user@github.com': 
protocol=https
host=github.com
username=lab-user
password=typed-at-the-prompt
```
<!-- /snippet -->

Two prompts, a username and a "password". Now a helper. The lab's helper is a short shell script, named `git-credential-labstore` so that the configuration value `labstore` finds it; it stores one credential in a plain file and logs every call (Lab 20.2 prints it):

<!-- snippet: ch16/credential-protocol/04-configure -->
```text
$ git config set --global credential.helper labstore
$ git config get --show-scope --all credential.helper
global	labstore
$ printf 'protocol=https\nhost=github.com\n\n' | git credential fill
fatal: could not read Username for 'https://github.com': terminal prompts disabled
[exit status: 128]
$ cat ~/helper.log
labstore get   <- protocol=https host=github.com
```
<!-- /snippet -->

Git asked the helper (`get`), the helper had nothing, and Git fell through to the prompt that the lab forbids. After a successful request Git calls `approve`, here by hand:

<!-- snippet: ch16/credential-protocol/05-approve -->
```text
# What Git does after a server accepted a credential that you typed:
$ printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=FAKE-TOKEN-not-a-real-credential\n\n' | git credential approve
$ cat ~/.labstore-credentials
username=lab-user
password=FAKE-TOKEN-not-a-real-credential
```
<!-- /snippet -->

<!-- snippet: ch16/credential-protocol/06-fill -->
```text
$ printf 'protocol=https\nhost=github.com\n\n' | git credential fill
protocol=https
host=github.com
username=lab-user
password=FAKE-TOKEN-not-a-real-credential
$ printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
protocol=https
host=github.com
username=lab-user
password=FAKE-TOKEN-not-a-real-credential
```
<!-- /snippet -->

The second form gives Git a URL and lets it derive protocol and host. The path was dropped: by default a credential is per host, not per repository (section 16.5). `GIT_TRACE=1` names the program that answered:

<!-- snippet: ch16/credential-protocol/07-trace -->
```text
$ printf 'protocol=https\nhost=github.com\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o 'trace: run_command.*'
trace: run_command: 'git credential-labstore get'
trace: run_command: git-credential-labstore get
```
<!-- /snippet -->

When a server answers 401 to a credential that Git sent, Git calls `reject`:

<!-- snippet: ch16/credential-protocol/08-reject -->
```text
# What Git does after a server answered 401 to a credential it had sent:
$ printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=FAKE-TOKEN-not-a-real-credential\n\n' | git credential reject
$ cat ~/.labstore-credentials
cat: $LAB/ch16/credential-protocol/home/.labstore-credentials: No such file or directory
[exit status: 1]
$ printf 'protocol=https\nhost=github.com\n\n' | git credential fill
fatal: could not read Username for 'https://github.com': terminal prompts disabled
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch16/credential-protocol/09-log -->
```text
$ cat ~/helper.log
labstore get   <- protocol=https host=github.com
labstore store <- protocol=https host=github.com username=lab-user password=<hidden>
labstore get   <- protocol=https host=github.com
labstore get   <- protocol=https host=github.com
labstore get   <- protocol=https host=github.com
labstore erase <- protocol=https host=github.com username=lab-user password=<hidden>
labstore get   <- protocol=https host=github.com
```
<!-- /snippet -->

The log is the protocol: `get` before a request, `store` after success, `erase` after a rejected credential.

**Inside `.git`.** Nothing. A credential is never stored in the repository unless you put it there (section 16.7). The helper list is configuration, usually at system or global scope, and the secret is wherever the helper keeps it.

**State table.**

| Event | Working tree, index, HEAD, refs | Git configuration | Helper's store | Remote | GitHub |
|---|---|---|---|---|---|
| Request needs a credential (`fill`) | unchanged | unchanged | read (`get`) | unchanged | unchanged |
| Server accepted it (`approve`) | unchanged | unchanged | written (`store`) | unchanged | unchanged |
| Server answered 401 (`reject`) | unchanged | unchanged | entry removed (`erase`) | unchanged | unchanged |
| Server answered 403 or 404 | unchanged | unchanged | **unchanged** | unchanged | unchanged |

The last row is from Git's source: `credential_reject` is called for a 401 with a credential that was sent, and for nothing else on this path ([http.c](https://github.com/git/git/blob/v2.55.0/http.c)).

**In production.** The CTO's third question. Ravi once cloned a personal project over HTTPS, and the keychain stored that account. For the work repository GitHub answers 403: a valid account without permission. Git reports the failure and erases nothing, so every later push sends the same credential. Granting access to his work account changed nothing, because that account never arrives at the server. The evidence is `GIT_TRACE=1` (which helper) and `gh auth status` (which account); the fix is to make the right account answer for that host (section 16.5).

## 16.5 Which helper answers, and where the token lives

**Precisely.** `credential.helper` is a list. Git asks each helper in order and stops at the first that returns a username and a password. An empty value resets the list, which is how a later configuration file discards helpers set by an earlier one. `credential.<URL>.helper` and `credential.<URL>.username` apply only to matching URLs, and `credential.useHttpPath` makes the repository path part of the lookup ([gitcredentials](https://git-scm.com/docs/gitcredentials)).

**See it.** Two helpers stand for two stored accounts:

<!-- snippet: ch16/credential-scope/01-list -->
```text
$ git config set --global credential.helper labstore
$ git config set --global --append credential.helper workstore
$ git config get --all credential.helper
labstore
workstore
$ printf 'protocol=https\nhost=github.com\n\n' | git credential fill
protocol=https
host=github.com
username=personal-user
password=FAKE-TOKEN-not-a-real-credential
$ cat ~/helper.log
labstore get   <- protocol=https host=github.com
```
<!-- /snippet -->

The first helper answered and the second was never asked. Order is the whole rule. To make a different helper answer for one host, reset the list for that host:

<!-- snippet: ch16/credential-scope/02-per-host -->
```text
# An empty value resets the list; what follows it replaces every helper configured before.
$ git config set --global --append credential.https://github.com.helper ''
$ git config set --global --append credential.https://github.com.helper workstore
$ cat ~/.gitconfig
[user]
	name = Lab User
	email = you@example.com
[init]
	defaultBranch = main
[gc]
	reflogExpire = never
	reflogExpireUnreachable = never
[credential]
	helper = labstore
	helper = workstore
[credential "https://github.com"]
	helper = 
	helper = workstore
$ printf 'protocol=https\nhost=github.com\n\n' | git credential fill
protocol=https
host=github.com
username=work-user
password=FAKE-TOKEN-not-a-real-credential
$ printf 'protocol=https\nhost=gitlab.example\n\n' | git credential fill
protocol=https
host=gitlab.example
username=personal-user
password=FAKE-TOKEN-not-a-real-credential
$ cat ~/helper.log
workstore get   <- protocol=https host=github.com
labstore get   <- protocol=https host=gitlab.example
```
<!-- /snippet -->

<!-- snippet: ch16/credential-scope/04-username-and-path -->
```text
$ git config set --global credential.https://github.com.username work-user
$ git config set --global credential.https://github.com.useHttpPath true
$ printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
protocol=https
host=github.com
path=acme-pay/billing-api.git
username=work-user
password=FAKE-TOKEN-not-a-real-credential
$ cat ~/helper.log
workstore get   <- protocol=https host=github.com path=acme-pay/billing-api.git username=work-user
```
<!-- /snippet -->

With `useHttpPath`, the helper receives `path=`, so it can keep one credential per repository; with a fixed `username`, it is asked for that account. GitHub's guide for several accounts over HTTPS uses exactly this setting ([managing multiple accounts](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-your-personal-account/managing-multiple-accounts)).

The helpers you will meet on a Mac:

| Helper | Configuration value | Where the secret lives | Notes |
|---|---|---|---|
| `git-credential-osxkeychain` | `osxkeychain` | the macOS login keychain, as an "internet password" for `github.com` | ships with Git on macOS; stores whatever you typed, typically a token you created by hand. GitHub's page recommends SSH or Git Credential Manager instead ([docs](https://docs.github.com/en/get-started/git-basics/updating-credentials-from-the-macos-keychain)) |
| GitHub CLI | `!/path/to/gh auth git-credential`, for `https://github.com` | gh's token in the system credential store; a plain text file if none is available (`gh auth login --help`) | written by `gh auth setup-git`, or by `gh auth login` when you let it authenticate Git |
| Git Credential Manager | `manager` | the keychain | obtains tokens through the browser, handles two-factor authentication; installed separately ([docs](https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git)) |
| `git-credential-store` | `store` | a plain text file | the manual calls it discouraged; do not use it |
| `git-credential-cache` | `cache` | memory of a background process, for a limited time | not used in this course: it starts a daemon |

What `gh auth setup-git` writes was read from the CLI's source at 2.88.1, not run: for each authenticated host it first sets `credential.https://github.com.helper` to the empty value, to cut off helpers configured elsewhere, then adds `!<path to gh> auth git-credential`, in the global configuration, and the same for the gist host ([helper_config.go](https://github.com/cli/cli/blob/v2.88.1/pkg/cmd/auth/shared/gitcredentials/helper_config.go)). It is the reset-then-add pattern of the transcript above. Lab 20.2 has you read the result on your own machine:

```bash
git config get --show-origin --all credential.helper
git config get --show-origin --all credential.https://github.com.helper
gh auth status
```

`gh auth status` prints, per host, the active account, where its token is stored and the token's scopes, with the token masked; it exits with status 1 when an account has a problem (`gh auth status --help`). `gh auth login` runs a browser flow by default and stores the resulting token "securely in the system credential store" (`gh auth login --help`).

> **Git, not GitHub.** `labs/shell` and the replays switch off the system configuration, where macOS installations of Git usually configure `osxkeychain`. That is why the labs that contact GitHub run in your normal shell, and why a command that works there can fail inside the lab shell with "could not read Username".

For one command, the same reset keeps every stored credential out of the picture. Nothing is read, changed or erased:

<!-- snippet: ch16/credential-scope/03-one-command -->
```text
# The same reset for a single command: no stored credential is read, changed or erased.
$ printf 'protocol=https\nhost=github.com\n\n' | git -c credential.helper= -c credential.https://github.com.helper= -c credential.helper='!f() { test "$1" = get && printf "username=nobody\npassword=wrong\n"; }; f' credential fill
protocol=https
host=github.com
username=nobody
password=wrong
$ cat ~/helper.log
cat: $LAB/ch16/credential-scope/home/helper.log: No such file or directory
[exit status: 1]
```
<!-- /snippet -->

Lab 20.3 uses this form to send a wrong credential on purpose without damaging the stored one.

## 16.6 Tokens: fine-grained, classic, and what a prefix tells you

**In one sentence.** A token is a string that stands for an account with a subset of its rights; the prefix says what kind it is, and the kind decides how far a leak reaches.

**Precisely.** GitHub's credential types, from its consolidated reference ([credential types](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/github-credential-types), [token formats](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github#githubs-token-formats)):

| Credential | Prefix | Lifetime | Belongs to | Reaches |
|---|---|---|---|---|
| Personal access token (classic) | `ghp_` | long-lived; no expiry required | a user | by scope (`repo`, `read:org`, ...), across **every** repository and organization the user can reach |
| Fine-grained personal access token | `github_pat_` | configurable, up to one year or none | a user | one owner (a user or one organization), optionally selected repositories, with per-permission read or write |
| OAuth app token | `gho_` | long-lived; expiring tokens are the default for new apps since 14 August 2026 ([changelog](https://github.blog/changelog/2026-08-14-multiple-redirect-uris-and-token-refresh-for-oauth-apps/)) | a user, through an app | by scope; `gh auth login` produces one |
| GitHub App user token | `ghu_` | 8 hours, with a `ghr_` refresh token of 6 months | a user, through an app | the app's permissions, limited by the user's |
| GitHub App installation token | `ghs_` | 1 hour | an app installation | the repositories and permissions of the installation |
| `GITHUB_TOKEN` in a workflow | (an installation token) | the job | a workflow run | one repository ([Chapter 21A](ch21a-actions-security.md)) |
| SSH key, deploy key | none | no expiry date; until deleted, and GitHub deletes a user SSH key that has not been used for a year ([deleted or missing SSH keys](https://docs.github.com/en/authentication/troubleshooting-ssh/deleted-or-missing-ssh-keys)); the documentation states no such automatic deletion for deploy keys | a user; a repository | sections 16.8 and 16.14 |

GitHub recommends fine-grained tokens over classic ones "whenever possible" ([managing tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)). They have been generally available since 18 March 2025, and by default an organization owner must approve one before it can reach the organization's resources; until then it can read only public resources ([changelog](https://github.blog/changelog/2025-03-18-fine-grained-pats-are-now-generally-available/)). An account can hold at most 50 of them.

The documented **gaps** decide when a classic token is still needed. A fine-grained token cannot:

- contribute to public repositories where you are not a member, or act for you as an outside collaborator;
- reach several organizations at once;
- access Packages, including `docker login ghcr.io` ([Chapter 15](ch15-github.md), section 15.11);
- call the Checks API, or a few other REST endpoints.

For open-source contribution that rules fine-grained tokens out, and the browser login of `gh` or an SSH key is the answer, not a classic token typed into a prompt.

Expiry and revocation ([token expiration and revocation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation)): a token found in a public repository or gist is revoked automatically; personal and OAuth tokens unused for a year are removed; and anyone who holds a leaked token value can submit it to an unauthenticated revocation API ([changelog](https://github.blog/changelog/2025-04-29-credential-revocation-api-to-revoke-exposed-pats-is-now-generally-available/)). Organizations can restrict each token type and set a maximum lifetime ([token policy](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization)).

> **Version note.** Older behavior: installation tokens were short opaque strings, and code assumed 40 characters. Current behavior: newly minted installation tokens, including the Actions `GITHUB_TOKEN`, use a format of about 520 characters. Since: staged rollout from 27 April 2026 ([changelog](https://github.blog/changelog/2026-04-24-notice-about-upcoming-new-format-for-github-app-installation-tokens/)). Recommended: never validate a token by length or pattern in your own code.

**In production.** A classic token with `repo` scope sits in a CI variable "for the changelog bot". It can read and write every private repository its creator can, in every organization. When it leaks through a log, the blast radius is a person, not a bot. The same job with an installation token leaks one hour of access to one repository. [Chapter 21B](ch21b-repository-security-incident-response.md) ranks the credentials for automation.

## 16.7 Why a token never goes into a URL

A URL of the form `https://USER:TOKEN@github.com/OWNER/REPO.git` works, which is the problem.

<!-- snippet: ch16/token-in-url/01-stored -->
```text
# What an old tutorial tells you to do. The token here is fake.
$ git remote set-url origin https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git
$ git remote -v
origin	https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git (fetch)
origin	https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git (push)
$ grep url .git/config
	url = https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git
$ git config list --show-scope | grep url
local	remote.origin.url=https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git
```
<!-- /snippet -->

The secret is in a plain text file inside the repository directory, it is printed by `git remote -v` and `git config list`, which people paste into tickets and CI logs, and it is copied by every backup of that directory. Git itself treats the URL as a credential:

<!-- snippet: ch16/token-in-url/02-git-reads-it -->
```text
$ printf 'url=%s\n\n' "$(git remote get-url origin)" | git credential fill
protocol=https
host=github.com
path=acme-pay/billing-api.git
username=lab-user
password=FAKE-TOKEN-not-a-real-credential
```
<!-- /snippet -->

Git can be told to refuse such URLs. `transfer.credentialsInUrl` takes `allow` (the default), `warn` or `die` ([git-config](https://git-scm.com/docs/git-config)):

<!-- snippet: ch16/token-in-url/03-refuse -->
```text
$ git config set --global transfer.credentialsInUrl die
$ git fetch origin
fatal: URL 'https://lab-user:<redacted>@github.com/acme-pay/billing-api.git' uses plaintext credentials
[exit status: 128]
$ git push origin main
fatal: URL 'https://lab-user:<redacted>@github.com/acme-pay/billing-api.git' uses plaintext credentials
[exit status: 128]
```
<!-- /snippet -->

Git redacts the secret in its own message. With `die` in force there is a surprise worth knowing before an incident:

<!-- snippet: ch16/token-in-url/04-repair -->
```text
# With "die" in force, even the command that would repair the URL refuses to read it:
$ git remote set-url origin https://github.com/acme-pay/billing-api.git
fatal: URL 'https://lab-user:<redacted>@github.com/acme-pay/billing-api.git' uses plaintext credentials
[exit status: 128]
$ git config set remote.origin.url https://github.com/acme-pay/billing-api.git
$ git remote -v
origin	https://github.com/acme-pay/billing-api.git (fetch)
origin	https://github.com/acme-pay/billing-api.git (push)
# The URL is clean. The token is still compromised: it sat in a file and on a screen. Revoke it.
```
<!-- /snippet -->

```text
Observed behavior : With transfer.credentialsInUrl=die, "git remote set-url" refuses to replace the bad URL.
Git state         : remote.origin.url contains user:secret@. Nothing else is wrong.
Mechanism         : set-url reads the remote's configuration before changing it, and reading a URL
                    with a plaintext credential is what "die" forbids.
Root cause        : The check sits where remotes are parsed, not where connections are opened.
Why Git does this : So that no command can use such a URL by accident.
Correct fix       : Write the key directly: git config set remote.origin.url <clean URL>.
Prevention        : Set "die" globally before the first bad URL exists, and revoke any token that
                    was ever in a URL. Cleaning the file does not un-leak it.
```

> **Outdated advice.** The Phase 0 report found a 2024 workshop video that writes a classic token into the remote URL, and a 2025 course that shows it while calling it not recommended. Both observations rest on auto-generated captions and should be re-checked before quoting. The technique is wrong in any year.

> **Version note.** Older behavior: no check. Current behavior: `transfer.credentialsInUrl`, covering `remote.<name>.url` and not `pushurl`. Since: Git 2.37 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.37.0.adoc)). Recommended: `git config set --global transfer.credentialsInUrl die`.

The same reasoning excludes every other place where a token ends up in plain sight: a command line (`ps` and shell history record it), an environment file under version control, a `.netrc` in a home directory that is backed up. Hand a token to a program on standard input (`gh auth login --with-token < file`, `gh secret set NAME` with no `--body`), and let a helper keep it.

## 16.8 SSH: a key pair instead of a secret that travels

**In one sentence.** With SSH you prove who you are by signing a challenge with a private key that never leaves your machine; GitHub holds only the public key.

**Analogy.** A signet ring and its wax impression. You give everyone a sample impression (the public key); only the ring (the private key) can make a new one, and anyone can compare. The analogy breaks because a wax seal can be copied from a sample, and a private key cannot be derived from the public key.

**Precisely.** `ssh-keygen -t ed25519 -C "your_email@example.com"` is the command GitHub documents ([generating a key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)). It writes two files: the private key, and a `.pub` file with one line (type, key, comment) that you upload to your account. For hardware security keys the types are `ed25519-sk` and `ecdsa-sk`. When you add a key to GitHub you choose whether it is an **authentication** key or a **signing** key; to use one key for both, you upload it twice ([adding a key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)). GitHub deletes SSH keys that have not been used for a year ([about SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh)).

**See it.** A throwaway key in the sandbox. This demo is volatile: the key and its fingerprints differ on every run. It has no passphrase at first only because a transcript cannot type one.

<!-- snippet: ch16/ssh-keys/01-generate -->
```text
$ ssh-keygen -q -t ed25519 -N '' -C 'you@example.com laptop 2026' -f ~/.ssh/id_ed25519_personal
$ cd ~/.ssh && stat -f '%Sp  %N' id_ed25519_personal id_ed25519_personal.pub && cd ~
-rw-------  id_ed25519_personal
-rw-r--r--  id_ed25519_personal.pub
```
<!-- /snippet -->

The private file is readable by its owner only; `ssh` ignores a private key file that others can access (`man ssh`, section FILES).

<!-- snippet: ch16/ssh-keys/02-public-half -->
```text
$ cat ~/.ssh/id_ed25519_personal.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8GlpVWYok0FGT/hmYU56d4Hw4gnMrujJRDYhk8ZDvu you@example.com laptop 2026
$ ssh-keygen -l -f ~/.ssh/id_ed25519_personal.pub
256 SHA256:OV5JdQEk7wx2wTQatqOVlFtaBWvv+9G9fkq1plvs5ig you@example.com laptop 2026 (ED25519)
$ ssh-keygen -l -E md5 -f ~/.ssh/id_ed25519_personal.pub
256 MD5:29:38:de:ca:c6:b1:c4:64:ba:27:29:0f:a8:35:21:38 you@example.com laptop 2026 (ED25519)
```
<!-- /snippet -->

The **fingerprint** is a hash of the public key, short enough to compare by eye. GitHub's page for auditing your keys has you compare this SHA256 form with what your account lists ([reviewing your SSH keys](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/reviewing-your-ssh-keys)); the MD5 form with colons is the older notation that some tools still print.

<!-- snippet: ch16/ssh-keys/03-private-half -->
```text
$ head -1 ~/.ssh/id_ed25519_personal
-----BEGIN OPENSSH PRIVATE KEY-----
$ ssh-keygen -y -f ~/.ssh/id_ed25519_personal
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8GlpVWYok0FGT/hmYU56d4Hw4gnMrujJRDYhk8ZDvu you@example.com laptop 2026
```
<!-- /snippet -->

The public key can always be recomputed from the private one, so losing the `.pub` file loses nothing. A passphrase encrypts the private file:

<!-- snippet: ch16/ssh-keys/04-passphrase -->
```text
$ ssh-keygen -p -q -P '' -N 'lab passphrase, not a real one' -f ~/.ssh/id_ed25519_personal
Key has comment 'you@example.com laptop 2026'
Your identification has been saved with the new passphrase.
$ ssh-keygen -y -P 'a wrong guess' -f ~/.ssh/id_ed25519_personal
Load key "$LAB/ch16/ssh-keys/home/.ssh/id_ed25519_personal": incorrect passphrase supplied to decrypt private key

[exit status: 255]
$ ssh-keygen -y -P 'lab passphrase, not a real one' -f ~/.ssh/id_ed25519_personal | cut -c1-40
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8G
```
<!-- /snippet -->

A copy of that file is now useless without the passphrase. On your machine `ssh-keygen` asks for the passphrase interactively; it never belongs on a command line.

**Inside `.git`.** Nothing. Keys live under `~/.ssh`, and which key is offered is decided by `ssh` (section 16.10), unless `core.sshCommand` or `GIT_SSH_COMMAND` says otherwise ([Chapter 14B](ch14b-config-tags-signing.md), section 14B.7).

**In production.** One key per machine, with a comment that names the machine and the year. When a laptop is lost you delete one key from the account and every other machine keeps working. A key copied to five machines must be revoked on all five at once, and nobody remembers the fifth.

## 16.9 The agent, the passphrase and the keychain

A passphrase that must be typed for every fetch gets removed within a week. The **agent** is the remedy: a background process that holds decrypted keys in memory and signs on request, so that `ssh` never needs the passphrase again during the session and no program reads the private key file.

- `ssh-add PATH` gives a key to the agent. `ssh-add -l` lists the keys it holds. Its exit status distinguishes three states: 0 with a list; 1 with "The agent has no identities."; 2 when no agent can be reached ([ssh-add](https://man.openbsd.org/ssh-add)).
- macOS provides an agent for your login session through `launchd`. GitHub's guide adds two things: a `Host github.com` block with `AddKeysToAgent yes` and `UseKeychain yes`, and `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`, which stores the passphrase in the login keychain so that the agent can load the key after a restart ([generating a key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)). `UseKeychain` exists only in Apple's build of OpenSSH.
- The replays run without any agent, which produces the third state:

<!-- snippet: ch16/failure-anatomy/01-no-ssh-agent -->
```text
$ ssh-add -l
Could not open a connection to your authentication agent.
[exit status: 2]
```
<!-- /snippet -->

You meet that message under `sudo`, in `cron` jobs and in containers: they do not inherit `SSH_AUTH_SOCK`, the variable that tells `ssh` where the agent is. GitHub's troubleshooting page says the same about `sudo`: it uses a different set of keys ([Permission denied](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-denied-publickey)).

Agent forwarding lets a remote machine use your local agent. The manual says it "should be enabled with caution": whoever controls that machine can use your identity while you are connected (`man ssh_config`, `ForwardAgent`). Prefer a deploy key or an app on the server (section 16.14).

## 16.10 `~/.ssh/config`, host aliases, and `ssh -G`

**In one sentence.** `~/.ssh/config` maps the host name that Git hands to `ssh` onto a real host, a user, a port and a key, and `ssh -G` prints the result of that mapping without connecting.

**Precisely.** The file is a list of `Host` blocks. For each setting, the **first value obtained wins**, so specific blocks go first and `Host *` defaults go last ([ssh_config](https://man.openbsd.org/ssh_config)). The settings that matter for GitHub:

| Keyword | Meaning | For GitHub |
|---|---|---|
| `Host` | the name or pattern you type, or that appears in a URL | `github.com`, or an alias of your own such as `github-work` |
| `HostName` | the real host to connect to | `github.com`, or `ssh.github.com` for port 443 |
| `User` | the login name | always `git`: "all connections, including those for remote URLs, must be made as the 'git' user" ([docs](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-denied-publickey)) |
| `IdentityFile` | a private key to offer; several lines add up | the key registered with the account you mean |
| `IdentitiesOnly yes` | offer only the configured files, even if the agent holds more keys | keeps a key of your other account, which the agent may also offer, from being the one GitHub accepts |
| `AddKeysToAgent`, `UseKeychain` | section 16.9 | |

Your GitHub account name appears nowhere. GitHub identifies you by which key was accepted.

**See it.** The sandbox file has a personal identity for `github.com`, a work identity behind an alias, the port-443 fallback, and defaults at the end. `ssh` finds its files through the account's home directory and not through `$HOME`, so every command names the sandbox file with `-F`; on your machine you omit `-F`. `-T` only keeps `ssh` from mentioning a terminal in a recorded transcript.

<!-- snippet: ch16/ssh-config/01-config -->
```text
$ cat ~/.ssh/config
# Personal account: plain github.com URLs
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes

# Work account: URLs written with the alias, git@github-work:ORG/REPO.git
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes

# Port 22 blocked: SSH over the HTTPS port
Host github-443
  HostName ssh.github.com
  Port 443
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes

# Defaults for every host come last
Host *
  AddKeysToAgent yes
```
<!-- /snippet -->

<!-- snippet: ch16/ssh-config/02-github -->
```text
$ ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly|addkeystoagent) '
user git
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_ed25519_personal
addkeystoagent true
```
<!-- /snippet -->

<!-- snippet: ch16/ssh-config/03-alias -->
```text
$ ssh -T -F ~/.ssh/config -G github-work | grep -E '^(hostname|user|port|identityfile|identitiesonly|addkeystoagent) '
user git
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_ed25519_work
addkeystoagent true
```
<!-- /snippet -->

The alias connects to the same host as a different key holder. Nothing was contacted: `-G` evaluates the `Host` blocks, prints about eighty settings, and exits.

A user written in the command or in the URL wins over the file, which is how a well-meant `USERNAME@github.com` breaks a working setup:

<!-- snippet: ch16/ssh-config/05-user-in-url -->
```text
# A user written in the command or in the URL beats "User git" in the file:
$ ssh -T -F ~/.ssh/config -G asha-rao@github.com | grep -E '^(hostname|user) '
user asha-rao
hostname github.com
```
<!-- /snippet -->

And the order trap. The same file with a `Host *` block moved to the top:

<!-- snippet: ch16/ssh-config/06-order -->
```text
# The same file with the defaults moved to the top, and a default user added to them:
$ head -4 ~/.ssh/config-defaults-first
Host *
  User deploy
  IdentityFile ~/.ssh/id_rsa_old

$ ssh -T -F ~/.ssh/config-defaults-first -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly|addkeystoagent) '
user deploy
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_rsa_old
identityfile ~/.ssh/id_ed25519_personal
addkeystoagent false
```
<!-- /snippet -->

`User deploy` won because it was obtained first, and an old RSA key is now offered before the right one. On GitHub this configuration fails with `Permission denied (publickey)`, and the only place the cause is visible is this output.

Git's part is small. It splits the URL and runs `ssh` with what it found:

<!-- snippet: ch16/ssh-config/07-what-git-runs -->
```text
# ~/lab-bin/fake-ssh prints the arguments Git gives to ssh and exits. No connection is made.
$ cd ~ && git init -q work/billing-api && cd work/billing-api
$ git remote add origin git@github-work:acme-pay/billing-api.git
$ GIT_SSH_COMMAND=~/lab-bin/fake-ssh git fetch origin
ssh was asked to run: git@github-work git-upload-pack 'acme-pay/billing-api.git'
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

Git passed the alias `github-work` untouched. Git does not read `~/.ssh/config` and does not know that the alias means `github.com`.

**Picture.**

```text
  remote.origin.url = git@github-work:acme-pay/billing-api.git
        |                         Git: user "git", host "github-work", path
        v
  ssh git@github-work git-upload-pack 'acme-pay/billing-api.git'
        |                         ssh: ~/.ssh/config, first value wins
        v
  HostName github.com   Port 22   User git   IdentityFile ~/.ssh/id_ed25519_work
        |                         server: host key checked against known_hosts (16.11)
        v
  GitHub: which account has this public key?  may that account do this to acme-pay/billing-api?
```

**In production.** A support ticket says "SSH is broken since yesterday". The first request is one line of output: `ssh -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '`. It shows a corporate tool that prepended a `Host *` block, an alias that someone shadowed, or a port override, in less time than reading `ssh -v`.

## 16.11 Host keys and `known_hosts`

**In one sentence.** Before you prove who you are, the server proves who it is with its host key, and `ssh` compares that key with the one it remembered in `~/.ssh/known_hosts`.

**Precisely.** Without this check, anyone on the network path could pose as GitHub, accept your connection and relay it. On the first connection `ssh` shows the server key's fingerprint and asks whether to continue; your answer is the whole security of the scheme, so compare it with the fingerprints GitHub publishes ([GitHub's SSH key fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)):

| Key type | Fingerprint |
|---|---|
| Ed25519 | `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU` |
| ECDSA | `SHA256:p2QAMXNIC1TJYWeIOttrVc98/R1BUFWu3/LiyKgUfQM` |
| RSA | `SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s` |

The same page publishes the three `known_hosts` lines, so you can install them and never be asked. `labs/ch16/github-known-hosts.txt` is a copy made on 2 October 2026.

**See it.** A fingerprint is computed from the key, so the published lines can be checked against the published fingerprints with no connection at all:

<!-- snippet: ch16/known-hosts/01-published-lines -->
```text
$ cut -c1-78 ~/github-known-hosts.txt
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9o
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTY
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt
```
<!-- /snippet -->

<!-- snippet: ch16/known-hosts/02-fingerprints -->
```text
$ ssh-keygen -l -f ~/github-known-hosts.txt
256 SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU github.com (ED25519)
256 SHA256:p2QAMXNIC1TJYWeIOttrVc98/R1BUFWu3/LiyKgUfQM github.com (ECDSA)
3072 SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s github.com (RSA)
```
<!-- /snippet -->

Three fingerprints, equal to the table. `ssh-keygen -F` answers "what do I have on file for this host":

<!-- snippet: ch16/known-hosts/03-find -->
```text
$ cp ~/github-known-hosts.txt ~/.ssh/known_hosts
$ ssh-keygen -l -F github.com -f ~/.ssh/known_hosts
# Host github.com found: line 1 
github.com ED25519 SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU
# Host github.com found: line 2 
github.com ECDSA SHA256:p2QAMXNIC1TJYWeIOttrVc98/R1BUFWu3/LiyKgUfQM
# Host github.com found: line 3 
github.com RSA SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s
$ ssh-keygen -l -F ssh.github.com -f ~/.ssh/known_hosts
[exit status: 1]
```
<!-- /snippet -->

`ssh.github.com`, the host for port 443, is a different name and has no entry yet, which is why the first connection through port 443 asks again. A stale or forged entry looks like any other line; only the fingerprint gives it away:

<!-- snippet: ch16/known-hosts/04-stale -->
```text
# A different key filed under the name github.com: what a stale or forged entry looks like.
# stale-host-key.pub is a throwaway public key made for this course.
$ printf 'github.com %s\n' "$(cut -d' ' -f1,2 ~/stale-host-key.pub)" > ~/.ssh/known_hosts
$ ssh-keygen -l -F github.com -f ~/.ssh/known_hosts
# Host github.com found: line 1 
github.com ED25519 SHA256:8UpYeYa2V/LbESZNhPkXZY4AOtNVNIYX1YezLa3mHbw
$ ssh-keygen -l -f ~/github-known-hosts.txt | grep ED25519
256 SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU github.com (ED25519)
```
<!-- /snippet -->

With that file, a connection to the real GitHub fails with `Host key verification failed.`, because the server presents a key that differs from the stored one. That is the check working. The repair removes the lines for the host and installs the published ones:

<!-- snippet: ch16/known-hosts/05-remove -->
```text
# The repair: remove the lines for the host, then add the published ones.
$ ssh-keygen -R github.com -f ~/.ssh/known_hosts
# Host github.com found: line 1
$LAB/ch16/known-hosts/home/.ssh/known_hosts updated.
Original contents retained as $LAB/ch16/known-hosts/home/.ssh/known_hosts.old
$ ssh-keygen -l -F github.com -f ~/.ssh/known_hosts
[exit status: 1]
$ cat ~/github-known-hosts.txt >> ~/.ssh/known_hosts
$ ssh-keygen -l -F github.com -f ~/.ssh/known_hosts | grep -c SHA256
3
```
<!-- /snippet -->

> **Version note.** Older behavior: GitHub's RSA host key had the fingerprint that old `known_hosts` files still contain. Current behavior: GitHub replaced its RSA host key on 24 March 2023, after the private key was briefly exposed in a public repository; the ECDSA and Ed25519 keys did not change. Since: 24 March 2023 ([GitHub Blog](https://github.blog/news-insights/company-news/we-updated-our-rsa-ssh-host-key/)). Recommended: on a machine that reports a changed host key, find the announcement first; GitHub states that a host key change "will be announced on the GitHub Blog" ([docs](https://docs.github.com/en/authentication/troubleshooting-ssh/error-host-key-verification-failed)). Then `ssh-keygen -R github.com` and the published lines.

🔴 `StrictHostKeyChecking no`, and deleting `known_hosts` wholesale, make the error disappear by removing the check. On a CI runner, install the published lines instead.

## 16.12 Testing the connection, and SSH over port 443

`ssh -T git@github.com` authenticates and runs nothing. GitHub's documented answer is `Hi USERNAME! You've successfully authenticated, but GitHub does not provide shell access.`, and the command exits with status 1, which is expected ([testing your SSH connection](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)). The name in the greeting is the answer to "who does the server say I am", and it is the first thing to read when a repository is "not found".

`ssh -vT git@github.com` adds the client's reasoning: which configuration files were read, which host and port were contacted, which identity files exist and which keys were offered. GitHub's troubleshooting page walks through that output ([Permission denied](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-denied-publickey)).

Some networks block port 22. GitHub accepts SSH on port 443 of a different host name ([SSH over the HTTPS port](https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port)):

```bash
ssh -T -p 443 git@ssh.github.com        # test
```

and, to route every `github.com` connection that way, a block in `~/.ssh/config`. Its effective configuration, from the sandbox file where it sits behind the alias `github-443`:

<!-- snippet: ch16/ssh-config/04-port-443 -->
```text
$ ssh -T -F ~/.ssh/config -G github-443 | grep -E '^(hostname|user|port|identityfile|identitiesonly|addkeystoagent) '
user git
hostname ssh.github.com
port 443
identitiesonly yes
identityfile ~/.ssh/id_ed25519_personal
addkeystoagent true
```
<!-- /snippet -->

GitHub's page notes that the first connection asks about the host key again, under the name `[ssh.github.com]:443`, and that it is not available on GitHub Enterprise Server. The report did not verify the host-key behavior beyond that page.

**State table.** None of the setup steps of sections 16.5 to 16.12 touches a repository: working tree, index, HEAD, branch refs, other refs and the remote are unchanged in every row. What changes is outside.

| Operation | Working tree, index, HEAD, refs, files in `.git`, remote | Your machine, outside any repository | GitHub |
|---|---|---|---|
| `ssh-keygen -t ed25519` | unchanged | two files under `~/.ssh` | unchanged |
| `ssh-add --apple-use-keychain KEY` | unchanged | the agent holds the key; the keychain holds the passphrase | unchanged |
| `gh ssh-key add KEY.pub`, or the web form | unchanged | unchanged | the public key is attached to your account |
| first `ssh -T git@github.com` | unchanged | a line in `~/.ssh/known_hosts`, after you confirm | unchanged |
| `gh auth login` | unchanged | a token in the system credential store; gh's configuration | an authorization of the GitHub CLI app for your account |
| `gh auth setup-git`, `git config set --global credential...` | unchanged | the global Git configuration | unchanged |

## 16.13 Two GitHub identities on one machine

**In one sentence.** Give each account its own key and its own `ssh` host alias, and let the directory a repository lives in choose the alias and the commit email.

**Precisely.** GitHub's guide for several accounts shows the two building blocks: `Host` aliases with `IdentityFile` and `IdentitiesOnly`, and `url.<alias>.insteadOf` to send an organization's URLs through an alias ([managing multiple accounts](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-your-personal-account/managing-multiple-accounts)). Combined with `includeIf` ([Chapter 14B](ch14b-config-tags-signing.md), section 14B.4), one file holds everything that makes a repository a work repository:

<!-- snippet: ch16/two-identities/01-global -->
```text
$ git config set --global user.name "Lab User"
$ git config set --global user.email lab-user@personal.example
$ git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
$ printf '[user]\n\temail = lab.user@acme-pay.example\n[url "git@github-work:"]\n\tinsteadOf = git@github.com:\n' > ~/.gitconfig-work
$ cat ~/.gitconfig-work
[user]
	email = lab.user@acme-pay.example
[url "git@github-work:"]
	insteadOf = git@github.com:
```
<!-- /snippet -->

Both repositories keep the canonical URL `git@github.com:OWNER/REPO.git`. In a repository under `~/work/`, the include applies:

<!-- snippet: ch16/two-identities/03-work -->
```text
$ cd ~/work/billing-api
$ git config get --show-origin user.email
file:$LAB/ch16/two-identities/home/.gitconfig-work	lab.user@acme-pay.example
$ git config get remote.origin.url
git@github.com:acme-pay/billing-api.git
$ git remote get-url origin
git@github-work:acme-pay/billing-api.git
$ GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
ssh was asked to run: git@github-work git-upload-pack 'acme-pay/billing-api.git'
```
<!-- /snippet -->

The stored URL is unchanged, the effective URL goes through the alias, and Git would start `ssh` for `git@github-work`. The personal repository is untouched:

<!-- snippet: ch16/two-identities/02-personal -->
```text
$ cd ~/personal/notes-app
$ git config get user.email
lab-user@personal.example
$ git config get remote.origin.url
git@github.com:lab-user/notes-app.git
$ git remote get-url origin
git@github.com:lab-user/notes-app.git
$ GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
ssh was asked to run: git@github.com git-upload-pack 'lab-user/notes-app.git'
```
<!-- /snippet -->

<!-- snippet: ch16/two-identities/05-commit-identity -->
```text
$ printf 'Runbook: rotate the payment gateway key every 90 days.\n' > RUNBOOK.md
$ git add RUNBOOK.md && git commit -q -m "Add key rotation runbook"
$ git log -1 --format='%an <%ae>  %s'
Lab User <lab.user@acme-pay.example>  Add key rotation runbook
$ cd ~/personal/notes-app
$ printf 'Ideas for the weekend.\n' > IDEAS.md
$ git add IDEAS.md && git commit -q -m "Add ideas file"
$ git log -1 --format='%an <%ae>  %s'
Lab User <lab-user@personal.example>  Add ideas file
```
<!-- /snippet -->

Three things changed together: the commit email, the URL and, through the alias, the key. They are still three independent identities (section 16.2); the include file is what keeps them aligned.

Over HTTPS the equivalent is one credential per account: `credential.https://github.com.username` inside the include, or `credential.https://github.com.useHttpPath true` (section 16.5). `gh` holds several accounts per host and `gh auth switch` changes the active one (`gh auth switch --help`); that switch is global, not per directory, which is the reason to prefer SSH aliases when you work in both identities on the same day.

**In production.** The failure this prevents: a commit pushed to the employer's repository under the personal email, or a push to the personal repository authenticated as the work account, which GitHub may reject with an error naming the other user ([docs](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-to-userrepo-denied-to-other-user)). A work repository cloned outside `~/work/` escapes a rule keyed on the directory; Lab 20.4 breaks it that way and repairs it with an `includeIf` keyed on the remote URL.

## 16.14 Credentials for machines: deploy keys, GitHub Apps, OAuth apps

A job that runs without you needs an identity that is not you.

| Credential | Scope | Lifetime | What to know |
|---|---|---|---|
| Deploy key | one repository; read-only unless "Allow write access" is chosen | no expiry | an SSH key attached to the repository, not to a person. It cannot be reused for a second repository, usually has no passphrase, and keeps working after the person who added it leaves ([deploy keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys)) |
| GitHub App installation token | the repositories and permissions of the installation | 1 hour | not tied to a user and consumes no seat; GitHub's stated preference for integrations ([apps](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/deciding-when-to-build-a-github-app)) |
| GitHub App user token | what both the app and the user may do | 8 hours, refresh token 6 months | acts on behalf of a person |
| OAuth app token | scopes granted by the user, across everything that user can reach | long-lived, or expiring for apps that use the option of 14 August 2026 | an OAuth app that only needs to read still asks for the broad `repo` scope |
| Machine user with a token or key | whatever the account can reach | as the credential | a user account for automation: it occupies a seat, and somebody has to own its password and second factor |
| `GITHUB_TOKEN` | the workflow's repository | the job | [Chapter 21A](ch21a-actions-security.md) |

A server that needs several repositories with deploy keys uses the alias technique of section 16.10, one alias per repository, as GitHub's page shows. At that point an app is the better tool: one installation, short-lived tokens, and a permission list that an auditor can read.

**In production.** The CTO's fourth question. The nightly sync uses a personal token that the departed engineer created. If the account was removed from the organization, the job is already failing; if the account is still a member, the job works with a former employee's access, and the token appears in nobody's inventory. Replacing it with an app installation, or at least a deploy key, makes the job's identity independent of people. [Chapter 21B](ch21b-repository-security-incident-response.md) covers the audit-log side.

## 16.15 SAML single sign-on and mandatory two-factor authentication

**Two-factor authentication.** Since March 2023 GitHub requires everyone who contributes code on GitHub.com to enable it; accounts are enrolled in groups with a 45-day window ([mandatory 2FA](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/about-mandatory-two-factor-authentication)). It protects the browser sign-in. Tokens and SSH keys are used without a second factor, which is why they must be guarded and, where possible, short-lived. An organization can additionally require two-factor authentication of its members ([Chapter 15](ch15-github.md), section 15.19).

**SAML single sign-on** is an Enterprise Cloud feature. In an organization that uses it, a credential must be **authorized for that organization** in addition to being valid ([about SSO](https://docs.github.com/en/enterprise-cloud@latest/authentication/authenticating-with-single-sign-on/about-authentication-with-single-sign-on)):

- a classic token is authorized after creation, per organization; a fine-grained token during creation; an SSH key per organization. Tokens from apps that you authorize during an active SSO session are authorized automatically. Deploy keys, installation tokens and `GITHUB_TOKEN` need no authorization ([credential types](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/github-credential-types#sso-authorization)).
- An owner can revoke the authorization. A revoked SSH key cannot be authorized again: a new key is needed.
- Through the REST API, an unauthorized classic token gets `404` or `403`, and a `403` carries an `X-GitHub-SSO` header with the URL to authorize it ([REST authentication](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api#personal-access-tokens-and-saml-sso)).

> **Unverified.** The text Git shows when an SSH key or token is not authorized for SSO is not quoted in any documentation page the report found; user reports show an `ERROR:` line naming the organization. The documented, citable behavior is the REST header above.

## 16.16 The SSH changes of 14 October 2026 and 13 January 2027

Announced on 22 September 2026 ([changelog](https://github.blog/changelog/2026-09-22-security-improvements-for-ssh/)), and after this chapter's baseline:

| Date | Change | Who is affected |
|---|---|---|
| 14 October 2026 | RSA keys **uploaded** after this date must be at least 3072 bits, for authentication and for signing. A post-quantum key exchange, `mlkem768x25519-sha256`, is enabled. | anyone adding a new RSA key |
| 4 November and 9 December 2026 | brownouts of the two removals below | very old SSH clients, temporarily |
| 13 January 2027 | the `ssh-rsa` **signature type** (RSA with SHA-1) and the key exchange `diffie-hellman-group-exchange-sha256` are removed | clients that cannot sign RSA with SHA-2: OpenSSH older than 7.2, and old embedded libraries |

Three points prevent wrong conclusions. The signature type `ssh-rsa` is not the key type `ssh-rsa`: an existing RSA key keeps working as long as the client signs with `rsa-sha2-256` or `rsa-sha2-512`, which current clients choose by themselves. Ed25519 and ECDSA keys are not affected at all. And HTTPS remotes are not affected.

What to check: `ssh -V` for the client version (OpenSSH 10.2 here), and `ssh-keygen -l -f ~/.ssh/KEY.pub` for a key's type and size, in the format shown in section 16.8. The machines to worry about are not laptops but old build agents, appliances and libraries inside tools.

> **Unverified.** The announcement does not state a minimum size for RSA keys that are already uploaded, and GitHub publishes no single list of supported key types (report, section 2, flags). The legacy command in GitHub's documentation, `ssh-keygen -t rsa -b 4096`, satisfies the new minimum.

## 16.17 Diagnosis: who wrote this line?

An authentication error on your screen is a short stack of lines written by different programs. Reading it starts with attributing each line.

| Line begins with | Written by | Means |
|---|---|---|
| `ssh:`, `Permission denied (publickey)`, `Host key verification failed.`, `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` | your `ssh` client | the SSH connection or authentication failed before Git's protocol started |
| `remote:` over HTTPS; over SSH, lines such as `ERROR: We're doing an SSH key audit.` | GitHub's server, passed through | the server knows something and tells you: repository not found, permission denied to a named user, a rule |
| `fatal: Could not read from remote repository.` and the two lines after it | Git | the other side closed the connection; this line never contains the cause |
| `fatal: Authentication failed for`, `fatal: repository '...' not found`, `fatal: unable to access '...': The requested URL returned error: NNN` | Git's HTTPS code | HTTP status 401, 404, or another status, in that order ([remote-curl.c](https://github.com/git/git/blob/v2.55.0/remote-curl.c)) |
| `fatal: could not read Username for` | Git | no helper answered and prompting was impossible |

**See it.** Four failures with four different causes. Nothing listens on port 1 of this machine, so the first one is a real `ssh` error without any network:

<!-- snippet: ch16/failure-anatomy/02-refused -->
```text
# Nothing listens on port 1 of this machine, so the connection is refused at once.
$ ssh -T -F ~/.ssh/config-offline -p 1 git@127.0.0.1
ssh: connect to host 127.0.0.1 port 1: Connection refused

[exit status: 255]
$ GIT_SSH_COMMAND='ssh -F ~/.ssh/config-offline' git ls-remote ssh://git@127.0.0.1:1/acme-pay/billing-api.git
ssh: connect to host 127.0.0.1 port 1: Connection refused

fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

Alone, `ssh` reports the cause. Under Git, the same line is followed by Git's three-line trailer. A stand-in for `ssh` that prints its arguments and exits, a second one that exits silently, and a local path that does not exist all end the same way:

<!-- snippet: ch16/failure-anatomy/03-standin -->
```text
$ GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote git@github.com:acme-pay/billing-api.git
ssh was asked to run: git@github.com git-upload-pack 'acme-pay/billing-api.git'
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch16/failure-anatomy/04-silent -->
```text
# ~/lab-bin/silent-ssh exits with status 255 and prints nothing.
$ GIT_SSH_COMMAND=~/lab-bin/silent-ssh git ls-remote git@github.com:acme-pay/billing-api.git
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch16/failure-anatomy/05-local-path -->
```text
$ git ls-remote ~/no-such-repository.git
fatal: '$LAB/ch16/failure-anatomy/home/no-such-repository.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

```text
Observed behavior : "fatal: Could not read from remote repository. Please make sure you have the
                    correct access rights and the repository exists."
Git state         : Unchanged. No ref moved and no object was transferred.
Mechanism         : Git started a program for the other side (ssh, or git-upload-pack for a path)
                    and it exited before the conversation began.
Root cause        : Not in this message. It is in the line above it, written by ssh, by the server
                    or by Git's own check of a local path. When ssh is silent, there is no line.
Why Git does this : Git cannot know why another program gave up. It offers the two most common
                    reasons as a hint, and people read the hint as a diagnosis.
Correct fix       : Read the line above. If there is none, run the transport alone:
                    ssh -vT git@github.com.
Prevention        : Quote the whole error in a ticket, never only the last line.
```

## 16.18 SSH failures, one by one

| Error | Who writes it, and the mechanism | Diagnose | Fix |
|---|---|---|---|
| `Permission denied (publickey)` | the server rejected the connection: none of the keys offered belongs to an account, or no key was offered, or the user is not `git` ([docs](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-denied-publickey)) | `git remote -v` (is the user `git`?); `ssh -G github.com` (which user, which identity files, `identitiesonly`); `ssh-add -l` (is the key loaded, is an agent reachable?); `ssh -vT git@github.com` (which keys were offered) | correct the URL user; point `IdentityFile` at the key that is on your account; load the key into the agent; upload the public key; do not use `sudo` |
| `Permission to OWNER/REPO denied to USER` | the server: the key authenticated as an account, or as a deploy key of another repository, that has no access here ([docs](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-to-userrepo-denied-to-other-user)) | the name in the message; `ssh -T git@github.com`; `ssh -G` for the alias you meant | use the alias or key of the right account (section 16.13); get the role you need |
| `Repository not found` over SSH | the server: section 16.19, the same deliberate answer as over HTTPS | `ssh -T git@github.com` names the account; spelling of `OWNER/REPO` | the right account, access, or URL |
| `Host key verification failed.` | your client: the server's key differs from `known_hosts` ([docs](https://docs.github.com/en/authentication/troubleshooting-ssh/error-host-key-verification-failed)) | `ssh-keygen -l -F github.com`; compare with the published fingerprints; look for an announcement | section 16.11. If no announcement explains it, do not connect |
| `ssh: connect to host github.com port 22: ...` (refused, timed out) | your client: the network | `ssh -vT`; try `ssh -T -p 443 git@ssh.github.com` | SSH over port 443 (section 16.12), or HTTPS |
| `ERROR: We're doing an SSH key audit.` | the server: the key is unverified ([docs](https://docs.github.com/en/authentication/troubleshooting-ssh/error-were-doing-an-ssh-key-audit)) | the message carries the reason and the address of your key settings | approve or remove the key there |
| `fatal: Could not read from remote repository.` | Git: section 16.17 | the line above it | the cause named there |

The first row carries the most confusion. `Permission denied (publickey)` does not mean "you lack permission on the repository". The server has not looked at the repository yet. It means the server could not attach your connection to any account.

## 16.19 HTTPS failures, one by one

| Error | Who writes it, and the mechanism | Diagnose | Fix |
|---|---|---|---|
| `Repository not found` in a `remote:` line, then `fatal: repository '...' not found` | the server answers 404 when the repository does not exist **or the credential has no access to it** ([docs](https://docs.github.com/en/repositories/creating-and-managing-repositories/troubleshooting-cloning-errors#error-repository-not-found)) | `git remote -v` (spelling); `GIT_TRACE=1 git ls-remote origin 2>&1 \| grep run_command` (which helper); `gh auth status` (which account); can that account open the repository in a browser? | the account that has access; for a fine-grained token, the repository in its selection and organization approval; SSO authorization |
| `fatal: Authentication failed for '...'` | 401: the credential was rejected outright: revoked or expired token, a password, a typo. Git then tells the helper to erase it (section 16.4) | `gh auth status`; token expiry in your account settings | `gh auth login`, or a new token through the helper; never in the URL |
| the password-removal message (unverified wording, section 16.3) | the same 401, with a `remote:` line saying that passwords are not supported | you typed, or a helper stored, an account password | a token through a helper, or SSH |
| `The requested URL returned error: 403` | the server knows who you are and refuses: no write permission, a classic token without the needed scope or without SSO authorization, an organization policy, or a rate limit. Git does **not** erase the credential | `gh auth status` (account and scopes); your role on the repository; for the API, the `X-GitHub-SSO` and rate-limit headers | get the permission or authorization; if it is the wrong account, remove or override the stored credential (section 16.5) |
| `fatal: could not read Username for 'https://github.com': terminal prompts disabled` | Git: no helper answered, and there is no terminal (CI, cron, the lab shell) | `git config get --show-origin --all credential.helper` | configure a helper or provide a token through the CI system's mechanism |
| `fatal: URL '...' uses plaintext credentials` | Git: section 16.7 | `git config get remote.origin.url` | clean the URL; revoke the token |

```text
Observed behavior : "Repository not found" for a repository that exists.
Git state         : The remote URL is spelled correctly. Nothing local is wrong.
Mechanism         : The server authenticated the request as an account or token that cannot see
                    the repository, and answered as if it did not exist.
Root cause        : An identity problem: the wrong account's credential answered, a fine-grained
                    token does not include this repository, a credential is not authorized for the
                    organization's SSO, or access was never granted.
Why GitHub does it: "To avoid confirming the existence of private repositories" (REST
                    troubleshooting guide). A 403 would tell a stranger that the name is taken.
Correct fix       : Find out who the server thinks you are (gh auth status, ssh -T), then make the
                    right identity answer, or grant it access.
Prevention        : One identity per host or alias, chosen by configuration and not by habit.
```

> **Unverified.** No GitHub documentation page explains HTTP 403 on `git push` specifically; the cloning-errors page says only that 401 and 403 "usually indicate you have an old version of Git, or you don't have access to the repository" ([docs](https://docs.github.com/en/repositories/creating-and-managing-repositories/troubleshooting-cloning-errors#https-cloning-errors)). The list of causes above combines that page, the token documentation and the REST guide; the statement that Git keeps the credential after a 403 is from Git's source and was not observed against GitHub here.

## 16.20 A decision tree

```text
The command failed. Read ALL the lines, then:

1. git remote get-url origin              Which transport?  ssh (git@... or ssh://)   https://
                                                              |                         |
   SSH -------------------------------------------------------+                         |
   2s. Is there an "ssh:" line (connect, resolve, timeout)?   -> network: try port 443 (16.12)
   3s. "Host key verification failed"?                        -> compare fingerprints (16.11)
   4s. "Permission denied (publickey)"?                       -> no account matched:
         ssh -G HOST | grep -E '^(user|hostname|identityfile|identitiesonly) '
         ssh-add -l          (exit 2: no agent, exit 1: no keys)
         ssh -vT git@HOST    (which keys were offered?)
   5s. "Permission ... denied to USER" or "Repository not found"? -> authenticated as someone:
         ssh -T git@HOST     -> is that the account you meant?  no -> alias or key (16.13)
                                                                yes -> access, SSO (16.15)
   HTTPS -------------------------------------------------------------------------------+
   2h. "could not read Username"?            -> no helper, no terminal (16.5)
   3h. "Authentication failed" (401)?        -> credential rejected: gh auth status, re-login (16.3)
   4h. "not found" (404) or 403?             -> authenticated, or anonymous, and not allowed:
         GIT_TRACE=1 git ls-remote origin 2>&1 | grep run_command      (which helper answered?)
         gh auth status                                                 (which account, which scopes?)
         wrong account -> fix which helper or username answers for this host (16.5)
         right account -> role on the repository, token permissions, SSO (16.6, 16.15)

Last, for both: does the same identity work in the browser or with "gh repo view OWNER/REPO"?
```

`GIT_TRACE=1` shows which programs Git runs. `GIT_TRACE_CURL=1` (or the older `GIT_CURL_VERBOSE=1`) shows the HTTP exchange, including the status code and the `WWW-Authenticate` header; Git redacts the `Authorization` header by default, and you should still read such a trace before pasting it anywhere ([Chapter 14B](ch14b-config-tags-signing.md), section 14B.7).

## 16.21 What can go wrong

Sections 16.17 to 16.20 cover the errors. These are the failures without a clear error:

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| Git never asks for a credential and keeps failing with 403 | a stored credential for another account answers; 403 does not erase it (section 16.4) | reset the helper list for the host, or delete the keychain entry ([docs](https://docs.github.com/en/get-started/git-basics/updating-credentials-from-the-macos-keychain)) | one helper per host, set on purpose |
| `gh` works, `git push` over HTTPS does not | `gh` has a token; Git is not using it: `git config get --show-origin --all credential.https://github.com.helper` | `gh auth setup-git` | let `gh auth login` configure Git |
| `gh` works in one terminal and not in another | `GH_TOKEN` or `GITHUB_TOKEN` is exported in one of them and takes precedence | unset it | no tokens in shell profiles |
| SSH works in the terminal and fails under `sudo`, `cron` or in a container | no `SSH_AUTH_SOCK` there: `ssh-add -l` exits 2 | a deploy key or app for the job; never `sudo git` | machine credentials for machines (section 16.14) |
| The wrong account's key is accepted | the agent offers its other keys too: `ssh -vT`; `ssh -G` shows `identitiesonly no` | `IdentitiesOnly yes` with the right `IdentityFile` | host aliases (section 16.13) |
| A key that worked last year is refused | GitHub deletes keys unused for a year; or an owner revoked its SSO authorization | upload a new key; authorize it | one key per machine, reviewed yearly |
| A token stopped working | it expired, was unused for a year, was found in a public repository and revoked, or the organization changed its token policy | create a new one; find where the old one leaked | expiry dates in a calendar; no tokens in repositories |
| Commits appear under the wrong name on GitHub | commit identity, not authentication (section 16.2) | `git config get --show-origin user.email` | `includeIf` per directory |
| Everything works, and a token is in `.git/config` | section 16.7 | clean the URL and revoke the token | `transfer.credentialsInUrl=die` |

## 16.22 When not to use it, and dangerous edge cases

- **Never paste a token into a command line, a URL, a file under version control, a chat or a ticket.** Standard input and helpers exist for this. The labs never ask you to.
- **Do not fix a host key error by switching the check off.** Section 16.11.
- **Do not copy one private key to several machines, and do not use a key without a passphrase on a laptop.** Passphrase-less keys are for machine identities with a narrow scope, such as a read-only deploy key.
- **Do not use a classic token where a narrower credential works**, and do not use a personal credential for a job that must survive your departure.
- **Do not use `credential-store`.** It writes tokens to a plain file.
- **Do not run `git` with `sudo`.** It changes the key set and the configuration, and leaves root-owned files in `.git`.
- **Erasing is not revoking.** Removing a token from the keychain, from a URL or from a file leaves the token valid. Only GitHub can revoke it: in your settings, by expiry, or through the revocation API.
- **`gh auth logout` is not revoking either.** Its help text says the token is removed locally and "does not revoke authentication tokens".
- **A deploy key with write access can do what an admin collaborator can do in that repository**, according to GitHub's page, and it has no expiry. Treat it like a password to the repository.

## 16.23 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git remote -v`, `git config get --show-origin ...`, `ssh -G`, `ssh-add -l`, `ssh-keygen -l`, `ssh-keygen -F`, `gh auth status`, `git credential fill` | 🟢 SAFE | nothing (`fill` may prompt, and prints a secret on your screen) | not needed | not needed |
| `ssh -T git@github.com`, `ssh -vT ...` | 🟢 SAFE | on first contact, may add a line to `known_hosts` after asking you | compare the fingerprint | `ssh-keygen -R github.com` |
| `ssh-keygen -t ed25519 -f NEW` | 🟡 CAUTION | creates two files; overwrites an existing key only after asking | `ls ~/.ssh` | none for an overwritten private key |
| `ssh-add`, `ssh-add --apple-use-keychain` | 🟡 CAUTION | the agent's key list; a keychain entry | `ssh-add -l` | `ssh-add -d` |
| `ssh-keygen -R HOST` | 🟡 CAUTION | removes a host's lines from `known_hosts`, keeping a `.old` copy | `ssh-keygen -F HOST` | the `.old` file |
| `git config set --global credential...`, `gh auth setup-git`, `gh auth login`, `gh auth switch` | 🟡 CAUTION | which credential answers, for every repository | `git config get --show-origin --all credential.helper` | set the previous value; `git config unset` |
| `git credential reject`, `git credential-osxkeychain erase` | 🟡 CAUTION | deletes a stored credential | `git credential fill` shows what is stored | log in again |
| `gh auth token`, `gh auth status --show-token` | 🔴 DANGEROUS | prints a live token to the terminal and its scrollback | ask whether you need the value at all | revoke the token |
| `gh ssh-key delete`, deleting a token or a deploy key in the web interface | 🔴 DANGEROUS | every machine and job that used it stops | list where it is used | create and distribute a new one |
| Writing a token into a URL, a file or a command line | 🔴 DANGEROUS | publishes the secret to logs, history and backups | none | revoke it; cleaning is not enough |

## 16.24 Version notes

Placed where they are needed: the installation token format (16.6), `transfer.credentialsInUrl` (16.7), GitHub's RSA host key (16.11), and the SSH changes of late 2026 (16.16).

> **Version note.** Older behavior: account passwords over HTTPS; DSA keys; the `git://` protocol. Current behavior: tokens or SSH keys only; Ed25519 recommended. Since: 13 August 2021 for passwords; 15 March 2022 for DSA and `git://` ([GitHub Blog](https://github.blog/security/application-security/improving-git-protocol-security-github/)). Recommended: `gh auth login` or SSH with an Ed25519 key.

> **Version note.** Older behavior: classic tokens were the only personal tokens. Current behavior: fine-grained tokens are generally available and recommended, with the documented gaps of section 16.6. Since: 18 March 2025. Recommended: fine-grained first; classic only where a gap forces it; an app for automation.

> **Version note.** Older behavior: tutorials debug HTTPS with `GIT_CURL_VERBOSE`. Current behavior: `GIT_TRACE_CURL` is the documented variable in Git 2.55 ([Chapter 14B](ch14b-config-tags-signing.md), section 14B.7). Recommended: `GIT_TRACE_CURL=1`, with redaction left on.

## 16.25 Practice

- **Labs 20.1 to 20.4** in the [Module 20 lab manual](../lab-manual/m20-authentication-ssh.md): SSH setup and verification; HTTPS through the GitHub CLI and the helper behind it; three failures reproduced and diagnosed; two identities (optional). Each has a local rehearsal in the lab shell and a part against GitHub in your normal shell.
- Answers: [Module 20](../solutions/m20-lab-answers.md).
- Replay any transcript with `labs/run ch16/<demo>`. Three drills; predict, then run:
  1. `ch16/credential-scope`: configure `credential.https://github.com.helper` with only the empty value. What does `git credential fill` do for `github.com`, and for another host?
  2. `ch16/ssh-config`: add `Port 2222` to the `Host *` block of the sandbox file. Which of the three hosts change port, and why not all?
  3. `ch16/failure-anatomy`: run `git ls-remote` with `GIT_SSH_COMMAND` set to a script of your own that prints one line to standard error and exits 1. Which lines appear, and who wrote each?

## 16.26 Interview questions

1. A deploy job reports "Repository not found" for a repository that exists. Walk through your diagnosis and name the possible root causes.
2. What is the difference between `Permission denied (publickey)` and `Permission to OWNER/REPO denied to USER`? What has the server established in each case?
3. Describe what Git does, step by step, from "the server answers 401" to "the token is stored", naming the helper operations. What happens differently on a 403, and what is the consequence?
4. Why must a token never be written into a remote URL? Name four places where it then appears, and the Git setting that refuses such URLs.
5. Compare a classic token, a fine-grained token, a deploy key and a GitHub App installation token by scope, lifetime, and what happens when the person who created it leaves.
6. A developer has a personal and a work GitHub account on one laptop. Design the setup, and say how you would prove from the terminal which account a given repository will use.
7. `ssh` reports that GitHub's host key has changed. What are the two explanations, how do you decide between them, and what do you never do?
8. Commit identity, authentication identity, signing identity: which of them does GitHub verify on a push, and what does each one prove?
9. What changes for SSH users of GitHub on 14 October 2026 and 13 January 2027? Which clients and keys are affected, and which are not?
10. An engineer pasted a token into a CI log an hour ago and has already deleted the log line. What is the state of the token, and what do you do in which order?

## 16.27 Sources

**Primary sources**

- GitHub Docs, read on 2 October 2026: [about authentication](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github), [managing personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens), [credential types](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/github-credential-types), [token expiration and revocation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation), [caching credentials](https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git), [generating an SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent), [testing your SSH connection](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection), [GitHub's SSH key fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints), [SSH over the HTTPS port](https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port), [Permission denied (publickey)](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-denied-publickey), [Host key verification failed](https://docs.github.com/en/authentication/troubleshooting-ssh/error-host-key-verification-failed), [troubleshooting cloning errors](https://docs.github.com/en/repositories/creating-and-managing-repositories/troubleshooting-cloning-errors), [managing multiple accounts](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-your-personal-account/managing-multiple-accounts), [deploy keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys), [single sign-on](https://docs.github.com/en/enterprise-cloud@latest/authentication/authenticating-with-single-sign-on/about-authentication-with-single-sign-on), [mandatory two-factor authentication](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/about-mandatory-two-factor-authentication).
- GitHub Blog and Changelog: [token authentication requirements](https://github.blog/security/application-security/token-authentication-requirements-for-git-operations/), [improving Git protocol security](https://github.blog/security/application-security/improving-git-protocol-security-github/), [the RSA host key](https://github.blog/news-insights/company-news/we-updated-our-rsa-ssh-host-key/), [security improvements for SSH](https://github.blog/changelog/2026-09-22-security-improvements-for-ssh/).
- Git 2.55.0: [gitcredentials](https://git-scm.com/docs/gitcredentials), [git-credential](https://git-scm.com/docs/git-credential), [git-config](https://git-scm.com/docs/git-config) (`credential.*`, `transfer.credentialsInUrl`, `url.<base>.insteadOf`, `includeIf`), as installed (`git help -m <page>`); the source files [http.c](https://github.com/git/git/blob/v2.55.0/http.c) and [remote-curl.c](https://github.com/git/git/blob/v2.55.0/remote-curl.c) for what Git does on 401, 403 and 404.
- OpenSSH as installed (`man ssh`, `man ssh_config`, `man ssh-keygen`, `man ssh-add`); online at [man.openbsd.org](https://man.openbsd.org/ssh_config).
- The GitHub CLI: `gh auth <command> --help` of 2.88.1, and [helper_config.go](https://github.com/cli/cli/blob/v2.88.1/pkg/cmd/auth/shared/gitcredentials/helper_config.go) for what `gh auth setup-git` writes.

**Secondary sources**

- The Phase 0 report of this course, section 2 (authentication, the error table, the flags) and section 4, and its research notes on the GitHub platform, section 4.
- Pro Git, [Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage): the helper protocol with a custom helper. Caveat: predates the GitHub CLI and fine-grained tokens.

**Videos** (optional; the report's assessments rest on captions and chapter lists, not on full viewing)

- [Git & GitHub Crash Course 2025](https://www.youtube.com/watch?v=vA5TTz6BXhY), Traversy Media, 49 minutes, 13 January 2025: SSH key setup. Caveat: beginner scope.
- [Complete git and Github course in Hindi](https://www.youtube.com/watch?v=q8EevlEpQ2A), Chai aur Code, 8 June 2024: states that passwords no longer work and sets up SSH. Caveat: audited through auto-generated captions.
- No verified video covers credential helpers, token types or authentication diagnosis at this depth.

**Further reading**

- [Authenticating to the REST API](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api) and [troubleshooting the REST API](https://docs.github.com/en/rest/using-the-rest-api/troubleshooting-the-rest-api), for the 401, 403 and 404 rules that Git's HTTPS errors inherit.
- Chapter 21A for the workflow token and OIDC, Chapter 21B for credential blast radius, token forensics and the response to a leaked secret, Chapter 29 for the troubleshooting playbook.
