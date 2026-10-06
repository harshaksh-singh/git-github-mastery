# V119: Tokens: fine-grained, classic, what a prefix tells you, and why a token never goes into a URL

- **Part.** 5: GitHub
- **Module.** 20
- **Planned minutes.** 16
- **Prerequisites.** V118
- **Textbook sections.** [Chapter 16](../../textbook/ch16-authentication.md), sections 16.6 and 16.7
- **Demo scripts.** `labs/ch16/token-in-url.sh`

## HOOK

**[ON SCREEN]** A CI log line: `origin  https://bot:…@github.com/…` — pasted into a ticket.

A CI job prints its remotes for debugging. Someone copies the output into a ticket to ask why the fetch is slow. In the middle of the line, between "https://" and "@github.com", is a classic token with the `repo` scope. It was created two years ago "for the changelog bot" by an engineer who has since left.

Your CTO asks two things. How far does this token reach? And how did a secret end up in the output of `git remote -v`?

The first answer is in the token's prefix. The second is that somebody followed a tutorial and wrote the token into the remote URL, which works, and that is the problem.

## INTRODUCTION

In the last video the secret over HTTPS was "a token", handed to Git by a helper. Now we look at the token itself: what kinds exist, what each can reach, how long each lives, and what the first characters tell you during an incident. Then one rule with a demonstration: a token never goes into a URL.

One replay, `labs/ch16/token-in-url.sh`. The token in the script is a made-up string, `FAKE-TOKEN-not-a-real-credential`. There is no GitHub walkthrough in this video: token pages must not be recorded.

The label for the practice we are about to demonstrate comes from the chapter's safety table: writing a token into a URL, a file or a command line is 🔴 DANGEROUS. It publishes the secret to logs, history and backups; there is no preview; and the recovery is to revoke it, because cleaning is not enough.

## LEARNING OBJECTIVES

After this video you can:

- Compare fine-grained and classic tokens by scope and lifetime, as the section gives them.
- Say when a documented gap forces a classic token.
- Name the places a token in a remote URL ends up.
- Find and repair a remote URL that contains a credential.

## CONCEPT

In one sentence: a token is a string that stands for an account with a subset of its rights; the prefix says what kind it is, and the kind decides how far a leak reaches.

**[ON SCREEN]** The table of section 16.6: credential, prefix, lifetime, belongs to, reaches.

A personal access token, classic. Prefix `ghp_`. Long-lived; no expiry required. It belongs to a user and reaches by scope, such as `repo` or `read:org`, across every repository and organization the user can reach.

A fine-grained personal access token. Prefix `github_pat_`. Its lifetime is configurable, up to one year or none. It belongs to a user and reaches one owner, a user or one organization, optionally selected repositories, with per-permission read or write.

An OAuth app token. Prefix `gho_`. It belongs to a user, through an app, and reaches by scope. `gh auth login` produces one. Expiring tokens are the default for new OAuth apps since 14 August 2026.

A GitHub App user token. Prefix `ghu_`. Eight hours, with a refresh token, prefix `ghr_`, of six months.

A GitHub App installation token. Prefix `ghs_`. One hour. It belongs to an app installation and reaches the repositories and permissions of that installation. The `GITHUB_TOKEN` in a workflow is an installation token that lives for the job and reaches one repository.

So during an incident, the prefix is your first fact. `ghp_` means a person's access, everywhere that person can go, possibly for ever. `ghs_` means one hour of one installation.

GitHub recommends fine-grained tokens over classic ones "whenever possible". They have been generally available since 18 March 2025. By default an organization owner must approve one before it can reach the organization's resources; until then it can read only public resources. An account can hold at most 50 of them.

The documented gaps decide when a classic token is still needed. A fine-grained token cannot contribute to public repositories where you are not a member, or act for you as an outside collaborator. It cannot reach several organizations at once. It cannot access Packages, including `docker login ghcr.io`. And it cannot call the Checks API, or a few other REST endpoints. For open-source contribution that rules fine-grained tokens out, and the answer there is the browser login of `gh` or an SSH key, not a classic token typed into a prompt.

Expiry and revocation. A token found in a public repository or gist is revoked automatically. Personal and OAuth tokens unused for a year are removed. Anyone who holds a leaked token value can submit it to an unauthenticated revocation API. And organizations can restrict each token type and set a maximum lifetime.

A version note for people who write tooling: newly minted installation tokens, including the Actions `GITHUB_TOKEN`, use a format of about 520 characters, in a staged rollout from 27 April 2026. Older code assumed 40 characters. Never validate a token by length or pattern in your own code.

Now the rule. A URL of the form `https://USER:TOKEN@github.com/OWNER/REPO.git` works, which is the problem. Why is it a problem? The URL is configuration, and configuration is not a secret store. The token is then in a plain text file inside the repository directory. It is printed by `git remote -v` and by `git config list`, which people paste into tickets and CI logs. And it is copied by every backup of that directory. That is four places: the file `.git/config`, the output of two everyday commands, the logs and tickets that output is pasted into, and backups.

Git can be told to refuse such URLs. `transfer.credentialsInUrl` takes `allow`, which is the default, `warn` or `die`. The setting exists since Git 2.37, and it covers `remote.<name>.url` and not `pushurl`. The recommendation is `git config set --global transfer.credentialsInUrl die`.

The recovery has two halves, and people forget the second. Clean the URL. And revoke the token. Erasing is not revoking: removing a token from a URL, from the keychain or from a file leaves the token valid. Only GitHub can revoke it.

The same reasoning excludes every other place where a token ends up in plain sight: a command line, because `ps` and shell history record it; an environment file under version control; a `.netrc` in a home directory that is backed up. Hand a token to a program on standard input, and let a helper keep it.

## MENTAL MODEL

Think of a token as a copy of your office key card that opens only some doors and stops working at a set time. Two questions size up a lost card: which doors, and until when. The prefix answers "which kind of card", and the kind answers both questions.

The model breaks in one place that matters: a lost key card has to be found by someone who walks to your building. A token works from anywhere, the moment it is read. So "it was only in a log for an hour" is not a mitigating fact. The only fact that ends the exposure is revocation.

And a URL is not a pocket. It is a label on the outside of the box, read by every tool that handles the box.

## DIAGRAM

**[ON SCREEN]** The root-cause box of section 16.7. It describes a surprise you will meet while repairing.

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

**[DIAGRAM]** And where the token travels once it is in the URL.

```text
   https://USER:TOKEN@github.com/OWNER/REPO.git
                 |
                 v
   .git/config  (remote.origin.url, plain text)
        |              |                     |
        v              v                     v
   git remote -v   git config list      a copy or backup of the directory
        |              |
        v              v
   CI logs, tickets, chat, screen shares
```

One line of configuration, and three ways out of it. Two of them are commands that nobody thinks of as printing secrets.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch16/token-in-url
```

What an old tutorial tells you to do. The token here is fake.

```bash
git remote set-url origin https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git
git remote -v
grep url .git/config
git config list --show-scope | grep url
```

**[PAUSE]** Three commands that read configuration. In how many of them will the token appear?

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

In all three. Twice in `git remote -v`, once in the file, once in `git config list`, where `--show-scope` tells you it is local: it is in this repository's own configuration.

```bash
printf 'url=%s\n\n' "$(git remote get-url origin)" | git credential fill
```

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

Git itself treats the URL as a credential: it splits out the username and the password. That is why the URL works.

Now tell Git to refuse.

```bash
git config set --global transfer.credentialsInUrl die
git fetch origin
git push origin main
```

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

"Uses plaintext credentials", for fetch and for push. Notice that Git redacts the secret in its own message.

The repair.

```bash
git remote set-url origin https://github.com/acme-pay/billing-api.git
```

**[PAUSE]** With `die` in force, we run the command that would fix the URL. Does it work?

```bash
git config set remote.origin.url https://github.com/acme-pay/billing-api.git
git remote -v
```

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

`git remote set-url` refuses, with the same message: it reads the remote's configuration before changing it. The way through is to write the key directly with `git config set remote.origin.url`. The URL is now clean.

And the last line of the transcript is the one to read aloud: the token is still compromised. It sat in a file and on a screen. Revoke it.

## COMMON MISTAKES

1. Putting a token into the remote URL because a tutorial does. Root cause: the URL is stored in `.git/config` and printed by `git remote -v` and `git config list`; the textbook notes that the technique is wrong in any year.
2. Cleaning the URL and considering the incident closed. Root cause: erasing is not revoking; the token stays valid until GitHub revokes it.
3. Using a classic token with `repo` scope for a bot. Root cause: a classic token reaches every repository and organization its creator can, so the blast radius is a person.
4. Choosing a fine-grained token for `docker login ghcr.io`. Root cause: Packages is one of the documented gaps of fine-grained tokens.
5. Validating tokens in code by length or pattern. Root cause: formats change; installation tokens moved to a format of about 520 characters.

## PRODUCTION EXAMPLE

The changelog bot from the hook. The prefix in the ticket is `ghp_`: a classic token. With `repo` scope it can read and write every private repository its creator can, in every organization. When it leaks through a log, the blast radius is a person, not a bot. And since the person has left, nobody was watching it.

The response, in order: revoke the token; clean the URL in the job's checkout with `git config set remote.origin.url`; set `transfer.credentialsInUrl` to `die` on the build machines; and find the other places the same token was used. Then replace the design. The same job with an installation token leaks one hour of access to one repository. That is the difference the table in this video describes, measured in an incident.

## PRACTICE EXERCISE

Do Exercise 20.2, "Pick the credential", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). For each situation, decide on the credential type before you look anything up, and write down the two properties that decided it: what it reaches, and how long it lives.

The challenge is Exercise 20.7, "The nightly sync says 'not found'", in the same file.

## INTERVIEW QUESTION

Question 310 of the CTO question bank:

> "Why must a token never be written into a remote URL? Name four places where it then appears, and the Git setting that refuses such URLs."

A strong answer starts with where a remote URL is stored and who reads it. It lists four concrete places, names the setting with its three values and the version it needs, and mentions the repair surprise. It finishes with the step that cleaning does not replace.

## RECAP

You should now be able to say:

- The prefix identifies the kind of token, and the kind decides reach and lifetime.
- A classic token reaches everything its user can; a fine-grained token reaches one owner with chosen permissions; an installation token lives one hour.
- Fine-grained tokens have documented gaps, among them public repositories where you are not a member, several organizations at once, and Packages.
- A token in a URL lands in `.git/config`, in `git remote -v`, in `git config list`, and from there in logs and backups.
- `transfer.credentialsInUrl=die` refuses such URLs; the repair is to clean the URL and revoke the token.

## HOMEWORK

Read sections 16.6 and 16.7 of [Chapter 16](../../textbook/ch16-authentication.md).
