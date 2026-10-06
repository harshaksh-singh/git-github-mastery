# V121: Two identities on one machine, credentials for machines, single sign-on, and the SSH changes of 14 October 2026 and 13 January 2027

- **Part.** 5: GitHub
- **Module.** 20
- **Planned minutes.** 20
- **Prerequisites.** V028, V120
- **Textbook sections.** [Chapter 16](../../textbook/ch16-authentication.md), sections 16.13 to 16.16
- **Demo scripts.** `labs/ch16/two-identities.sh`, `labs/ch16/lab-20-4-two-identities.sh`

## HOOK

**[ON SCREEN]** "The engineer who wrote the nightly sync left in June. What does the job authenticate as today?"

Your CTO asks that question on an ordinary morning, and the room goes quiet, because nobody knows.

There are two possible answers and both are bad. If the engineer's account was removed from the organization, the job is already failing and somebody will notice soon. If the account is still a member, the job works, with a former employee's access, through a token that appears in nobody's inventory.

The right answer would have been: "as an app that nobody can leave". This video is about making identities deliberate: yours, when you have two of them on one laptop, and a machine's, when the machine must outlive the people who set it up.

## INTRODUCTION

Four sections of Chapter 16, each short.

First, two GitHub identities on one machine, a personal and a work account, configured so that the directory a repository lives in decides everything. This is the demonstration of the video: `labs/ch16/two-identities.sh`, and the replay of the optional Lab 20.4. The replays use a stand-in for `ssh` and reach no network.

Second, credentials for machines: deploy keys, GitHub Apps, OAuth apps, as the section compares them.

Third, what SAML single sign-on and mandatory two-factor authentication add.

Fourth, the SSH changes of 14 October 2026 and 13 January 2027. A note on that last part: these dates come after the baseline of the textbook, which is 1 October 2026. I quote them from section 16.16, and the production notes require that they are re-verified against GitHub's changelog on the day of recording.

There is no GitHub walkthrough in this video. The commands shown set global Git configuration inside the sandbox; on your own machine, `git config set --global` is 🟡 CAUTION because it applies to every repository.

## LEARNING OBJECTIVES

After this video you can:

- Configure a personal and a work identity so that each repository uses the right key and the right commit address.
- Prove from a repository which identity a push will use.
- Choose between a deploy key, a GitHub App and an OAuth app for a machine, as the section compares them.
- Say what single sign-on authorization and mandatory two-factor authentication add.
- State what changes for SSH users on the two dates and who is affected.

## CONCEPT

Two identities. In one sentence: give each account its own key and its own `ssh` host alias, and let the directory a repository lives in choose the alias and the commit email.

Why is this needed at all? Recall the three independent identities from V118: the commit identity, the authentication identity and the signing identity. With two accounts on one laptop, each of them can be wrong separately. A commit can go to the employer's repository under your personal email. A push to your personal repository can be authenticated as the work account.

GitHub's guide for several accounts gives two building blocks: `Host` aliases with `IdentityFile` and `IdentitiesOnly`, which you saw in the last video, and `url.<alias>.insteadOf`, which sends URLs through an alias. Combined with `includeIf`, which you met in the configuration videos, one file holds everything that makes a repository a work repository: the email, and the URL rewrite. Both kinds of repository keep the canonical URL, `git@github.com:OWNER/REPO.git`. Inside the work directory, the include applies and the effective URL goes through the alias.

Over HTTPS the equivalent is one credential per account: `credential.https://github.com.username` inside the include, or `useHttpPath`. The GitHub CLI holds several accounts per host and `gh auth switch` changes the active one. That switch is global, not per directory, which is the reason to prefer SSH aliases when you work in both identities on the same day.

The failure mode of the design: a work repository cloned outside the work directory escapes a rule keyed on the directory. Lab 20.4 breaks the setup that way and repairs it with an `includeIf` keyed on the remote URL.

Credentials for machines. A job that runs without you needs an identity that is not you.

**[ON SCREEN]** The table of section 16.14.

A deploy key: an SSH key attached to one repository, not to a person. Read-only unless "Allow write access" is chosen. No expiry. It cannot be reused for a second repository, usually has no passphrase, and keeps working after the person who added it leaves. And from the chapter's edge cases: a deploy key with write access can do what an admin collaborator can do in that repository, according to GitHub's page. Treat it like a password to the repository.

A GitHub App installation token: scoped to the repositories and permissions of the installation, one hour, not tied to a user, consuming no seat. It is GitHub's stated preference for integrations.

A GitHub App user token: what both the app and the user may do; eight hours, with a refresh token of six months.

An OAuth app token: the scopes granted by the user, across everything that user can reach. An OAuth app that only needs to read still asks for the broad `repo` scope.

A machine user with a token or key: a user account for automation. It occupies a seat, and somebody has to own its password and second factor.

And `GITHUB_TOKEN`: the workflow's repository, for the job.

The choice, as the section puts it: a server that needs several repositories with deploy keys needs one alias per repository. At that point an app is the better tool: one installation, short-lived tokens, and a permission list that an auditor can read.

Two-factor authentication. Since March 2023 GitHub requires everyone who contributes code on GitHub.com to enable it; accounts are enrolled in groups with a 45-day window. It protects the browser sign-in. Tokens and SSH keys are used without a second factor, which is why they must be guarded and, where possible, short-lived.

SAML single sign-on is an Enterprise Cloud feature. In an organization that uses it, a credential must be authorized for that organization in addition to being valid. A classic token is authorized after creation, per organization; a fine-grained token during creation; an SSH key per organization. Deploy keys, installation tokens and `GITHUB_TOKEN` need no authorization. An owner can revoke the authorization, and a revoked SSH key cannot be authorized again: a new key is needed. Through the REST API, an unauthorized classic token gets 404 or 403, and a 403 carries an `X-GitHub-SSO` header with the URL to authorize it.

One caveat the textbook marks unverified: the text Git shows when an SSH key or token is not authorized for single sign-on is not quoted in any documentation page the course found. The documented, citable behaviour is the REST header.

The SSH changes, announced on 22 September 2026. Every date in this list lies after the course baseline of 1 October 2026, so this is what GitHub announced, not what the course observed. Check the changelog on the day you watch this.

**[ON SCREEN]** The table of section 16.16.

14 October 2026, as announced: RSA keys uploaded after this date must be at least 3072 bits, for authentication and for signing, and a post-quantum key exchange is to be enabled. Affected: anyone adding a new RSA key.

4 November and 9 December 2026, as announced: brownouts of the two removals that follow. Affected: very old SSH clients, temporarily.

13 January 2027, as announced: the `ssh-rsa` signature type, which is RSA with SHA-1, and one older key exchange are to be removed. Affected: clients that cannot sign RSA with SHA-2, meaning OpenSSH older than 7.2 and old embedded libraries.

Three points prevent wrong conclusions. The signature type `ssh-rsa` is not the key type `ssh-rsa`: an existing RSA key keeps working as long as the client signs with `rsa-sha2-256` or `rsa-sha2-512`, which current clients choose by themselves. Ed25519 and ECDSA keys are not affected at all. And HTTPS remotes are not affected.

What to check: `ssh -V` for the client version, and `ssh-keygen -l -f` on a public key for its type and size. The machines to worry about are not laptops but old build agents, appliances and libraries inside tools.

And the caveat, unverified in the book: the announcement does not state a minimum size for RSA keys that are already uploaded, and GitHub publishes no single list of supported key types.

## MENTAL MODEL

Think of two wallets, one personal and one from your employer, and a rule about which wallet you carry: the one that belongs to the building you are in. Each wallet holds a key card, which is the SSH key, and a business card, which is the commit email. You never choose per transaction; the building decides.

The model breaks exactly where the lab breaks it: a work meeting held in a café. A repository cloned outside the work directory is in no building, and the rule keyed on the directory picks the personal wallet. That is why the lab ends with a rule keyed on the remote URL, on what the repository is, not on where it sits.

For machines the model is simpler: a machine should carry a card issued to the machine.

## DIAGRAM

**[DIAGRAM]** One table. Two rows, four columns.

```text
               host alias        key                          commit address               where configured
  personal     github.com        ~/.ssh/id_ed25519_personal   lab-user@personal.example    ~/.gitconfig (global)
                                                                                           ~/.ssh/config: Host github.com
  work         github-work       ~/.ssh/id_ed25519_work       lab.user@acme-pay.example    ~/.gitconfig-work, included by
               (-> github.com)                                                             includeIf.gitdir:~/work/
                                                                                           ~/.ssh/config: Host github-work

  stored URL in both:   git@github.com:OWNER/REPO.git
  effective URL, work:  git@github-work:OWNER/REPO.git      (url."git@github-work:".insteadOf = git@github.com:)
```

Read the personal row: plain `github.com`, the personal key, the personal address, all from the global configuration and the first block of the SSH configuration.

Read the work row: the alias `github-work`, which resolves to the same host with the work key; the work address; and the last column says where both come from. One included file sets the address and rewrites the URL. The SSH configuration maps the alias to the key.

The two lines at the bottom are the trick. The stored URL is canonical in both. Only the effective URL differs.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch16/two-identities
```

```bash
git config set --global user.name "Lab User"
git config set --global user.email lab-user@personal.example
git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
cat ~/.gitconfig-work
```

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

The global identity is the personal one. The include applies to repositories under `~/work/`. The included file has two sections: a different email, and the URL rewrite.

```bash
cd ~/personal/notes-app
git config get user.email
git config get remote.origin.url
git remote get-url origin
GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
```

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

The personal repository: the personal address, and the stored and the effective URL are the same. The stand-in for `ssh` shows that Git would start `ssh` for `git@github.com`.

```bash
cd ~/work/billing-api
git config get --show-origin user.email
git config get remote.origin.url
git remote get-url origin
GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
```

**[PAUSE]** In the work repository, `git config get remote.origin.url` and `git remote get-url origin` are two different questions. Will they print the same URL?

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

They differ. The stored URL is unchanged; the effective URL goes through the alias; and Git would start `ssh` for `git@github-work`. `--show-origin` names the file the address came from: the included one.

These four commands are the proof the second objective asks for. From inside any repository: the address and its origin, the effective URL, and what `ssh` would be asked to run.

<!-- snippet: ch16/two-identities/04-ssh-side -->
```text
$ ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|identityfile|identitiesonly) '
user git
hostname github.com
identitiesonly yes
identityfile ~/.ssh/id_ed25519_personal
$ ssh -T -F ~/.ssh/config -G github-work | grep -E '^(hostname|user|identityfile|identitiesonly) '
user git
hostname github.com
identitiesonly yes
identityfile ~/.ssh/id_ed25519_work
```
<!-- /snippet -->

The SSH side, with `ssh -G` as in the last video: the same host name for both, a different identity file for each, and `identitiesonly yes`.

```bash
printf 'Runbook: rotate the payment gateway key every 90 days.\n' > RUNBOOK.md
git add RUNBOOK.md && git commit -q -m "Add key rotation runbook"
git log -1 --format='%an <%ae>  %s'
```

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

One commit in each repository, each with the right address. Three things changed together: the commit email, the URL and, through the alias, the key. They are still three independent identities. The include file is what keeps them aligned.

**[TERMINAL]** The lab replay builds the same setup step by step.

```bash
labs/run ch16/lab-20-4-two-identities
```

<!-- snippet: ch16/lab-20-4-two-identities/05-work -->
```text
$ cd ~/work/billing-api
$ git config get --show-origin user.email
file:$LAB/ch16/lab-20-4-two-identities/home/.gitconfig-work	lab.user@acme-pay.example
$ git remote get-url origin
git@github-work:acme-pay/billing-api.git
$ GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
ssh was asked to run: git@github-work git-upload-pack 'acme-pay/billing-api.git'
```
<!-- /snippet -->

The same proof in the lab's sandbox. After this step the lab clones a work repository outside `~/work/` and asks you what address and what key it will use. Predict it before you run it; the failure and the recovery are yours.

**[TERMINAL]** For the calendar, two commands on your own machine, in your normal shell. No output is shown, because it is specific to your machine.

```bash
ssh -V
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
```

The first prints the client version; compare it with 7.2. The second prints a key's size and type; for an RSA key you plan to upload after 14 October 2026, the announced minimum size is 3072 bits.

## COMMON MISTAKES

1. Pushing to the employer's repository with the personal email in the commits. Root cause: the commit identity is independent of authentication; nothing checks it unless you configure it per directory.
2. Keying the work identity on the directory and cloning a work repository elsewhere. Root cause: `includeIf.gitdir` matches the location; a rule keyed on the remote URL matches the repository.
3. Running a nightly job with a personal token. Root cause: the job then authenticates as a person, and its access follows that person's membership, not the job's purpose.
4. Concluding that RSA keys stop working on 13 January 2027. Root cause: the announcement removes the signature type `ssh-rsa`, not the key type; current clients sign with SHA-2.
5. Assuming a valid token works in an organization with single sign-on. Root cause: the credential must also be authorized for that organization.

## PRODUCTION EXAMPLE

The nightly sync from the hook. The team finds the job's credential: a classic personal token created by the engineer who left. The account is still a member of the organization, so the job works, and the token appears in nobody's inventory.

They replace it with a GitHub App installed on the two repositories the sync touches, with the permissions the sync needs. The job now obtains an installation token that lives one hour. Nobody's departure changes it, and an auditor can read its permission list. For a job that needed one repository read-only, a deploy key would have been the minimum improvement.

For the calendar, the same team lists machines, not people: every build agent, appliance and tool with an embedded SSH library, with the output of `ssh -V` where there is one. Laptops are not the risk.

## PRACTICE EXERCISE

Do Lab 20.4, "Two identities on one machine (optional)", in [`lab-manual/m20-authentication-ssh.md`](../../lab-manual/m20-authentication-ssh.md). Before each proof command, predict the address, the effective URL and the host that `ssh` would be asked for. Before the failure scenario, predict which of the three will be wrong.

The challenge is Exercise 20.5, "The push works, the address is wrong", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 246 of the CTO question bank:

> "A developer has a personal and a work GitHub account on one laptop. Design the setup, and say how you would prove from the terminal which account a given repository will use."

A strong answer names what must differ between the two accounts and keeps the three identities apart. It gives a design in which nothing is chosen by hand per repository, states where each piece is configured, and names the case the design misses. For the proof it gives commands that read configuration and resolve the connection without making one.

## RECAP

You should now be able to say:

- Each account gets its own key and host alias; an included configuration file sets the commit email and rewrites the URL for work repositories.
- `git config get --show-origin user.email`, `git remote get-url origin` and `ssh -G` prove which identity a repository will use.
- A machine gets a machine credential: a deploy key for one repository, or an app installation with one-hour tokens.
- Two-factor authentication protects the browser sign-in; single sign-on requires each credential to be authorized per organization.
- GitHub announced that from 14 October 2026 new RSA keys need 3072 bits and that on 13 January 2027 the SHA-1 RSA signature type is removed; Ed25519, ECDSA and HTTPS are unaffected. Check the changelog on the day you watch this.

## HOMEWORK

Read sections 16.13 to 16.16 of [Chapter 16](../../textbook/ch16-authentication.md). Do Exercise 20.8, "The SSH calendar", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).
