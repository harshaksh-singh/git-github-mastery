# V120: SSH: key pairs, the agent, ~/.ssh/config, host keys, and testing the connection

- **Part.** 5: GitHub
- **Module.** 20
- **Planned minutes.** 26
- **Prerequisites.** V118
- **Textbook sections.** [Chapter 16](../../textbook/ch16-authentication.md), sections 16.8 to 16.12
- **Demo scripts.** `labs/ch16/ssh-keys.sh`, `labs/ch16/ssh-config.sh`, `labs/ch16/known-hosts.sh`; GitHub-side walkthrough of Lab 20.1

## HOOK

**[ON SCREEN]** `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` … `Host key verification failed.`

Picture a build machine restored from a disk image made in 2022. This morning it fetches from GitHub for the first time since then, and stops. The message says the remote host identification has changed, and ends with "Host key verification failed." A search result offers a one-line fix: switch the check off.

Your CTO asks: is someone intercepting our connection, or did GitHub change something? And what do we never do?

There are exactly two explanations, a published key rotation or an attack, and a fixed way to decide between them. And the one-line fix is the thing you never do: it makes the error disappear by removing the check. Hold on to that build machine. You'll repair it properly before the end.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. The last two videos covered HTTPS, where a secret travels: a token. SSH works on a different principle, and this video covers it end to end in five steps. The key pair. The agent that holds it. The configuration file that decides which key goes to which host. The host key, which is the server proving itself to you. And the test that tells you who the server thinks you are.

Three replays from `labs/ch16`. `ssh-keys.sh` generates a throwaway key inside the sandbox. It's volatile, so the key and its fingerprints differ on every run and won't match the book. `ssh-config.sh` and `known-hosts.sh` are deterministic. None of the replays reaches an agent or the network. Then the walkthrough of Lab 20.1 in the normal shell.

Labels from the chapter's table. `ssh -G`, `ssh-add -l`, `ssh-keygen -l` and `ssh-keygen -F` are 🟢 SAFE. `ssh -T git@github.com` is 🟢, and on first contact may add a line to `known_hosts` after asking you. `ssh-keygen -t ed25519` is 🟡 CAUTION: it creates two files and overwrites an existing key only after asking. `ssh-add` is 🟡. `ssh-keygen -R` is 🟡: it removes a host's lines from `known_hosts`, keeping a `.old` copy. And `StrictHostKeyChecking no` is 🔴 DANGEROUS.

## LEARNING OBJECTIVES

After this video you can:

- Generate a key pair and say what each half is for and where it goes.
- Explain what the agent holds and what the passphrase protects.
- Write a `~/.ssh/config` entry with a host alias and show what SSH resolves it to.
- Verify GitHub's host key against the published fingerprints and handle a changed key.
- Test the connection and use SSH over port 443.

## CONCEPT

In one sentence: with SSH you prove who you are by signing a challenge with a private key that never leaves your machine. GitHub holds only the public key.

**[ANIMATION]** stores: id=keys boxes=~/.ssh:your_machine|the_agent:a_background_process|*GitHub:your_account rows=1:A:id__ed25519:_private_key@hl|1:A:id__ed25519.pub|2:C:your_public_key@ok|3:A:a_passphrase_encrypts_the_file@ref|4:B:the_key,_decrypted,_in_memory arrows=2:A2>C1:uploaded|4:A1>B1:ssh-add title=The_private_key_never_leaves at_1=22 at_2=42 at_3=5 at_4=58

**[ANIMATION]** step: 2

The key pair. `ssh-keygen -t ed25519 -C "your_email@example.com"` is the command GitHub documents. It writes two files: the private key, and a `.pub` file with one line, type, key and comment, that you upload to your account. For hardware security keys the types are `ed25519-sk` and `ecdsa-sk`. When you add a key to GitHub you choose whether it's an authentication key or a signing key. To use one key for both, you upload it twice. And GitHub deletes SSH keys that haven't been used for a year.

A fingerprint is a hash of the public key, short enough to compare by eye.

Inside `.git`: nothing. Keys live under `~/.ssh`, and which key is offered is decided by `ssh`, unless `core.sshCommand` or `GIT_SSH_COMMAND` says otherwise.

**[ANIMATION]** step: 4

The agent. A passphrase encrypts the private key file, so that a copy of the file is useless without it. But a passphrase that must be typed for every fetch gets removed within a week. The agent is the remedy: a background process that holds decrypted keys in memory and signs on request, so that `ssh` never needs the passphrase again during the session and no program reads the private key file.

**[ANIMATION]** walk: id=states columns=state,exit_status,note rows=a_list_of_keys:0:-|The_agent_has_no_identities.:1:-|no_agent_can_be_reached:2:under_sudo,_in_cron,_in_containers title=ssh-add_-l:_three_states at_1=24 at_2=30 at_3=38

**[ANIMATION]** step: 3

`ssh-add PATH` gives a key to the agent. `ssh-add -l` lists the keys it holds, and its exit status distinguishes three states. 0 with a list. 1 with "The agent has no identities." And 2 when no agent can be reached. macOS provides an agent for your login session. GitHub's guide adds a `Host github.com` block with `AddKeysToAgent yes` and `UseKeychain yes`, and `ssh-add --apple-use-keychain`, which stores the passphrase in the login keychain so that the agent can load the key after a restart. `UseKeychain` exists only in Apple's build of OpenSSH.

Try it now, thirty seconds, in your normal shell. Run `ssh-add -l` and decide which of the three states you're in: a list, no identities, or no agent. I'll wait.

**[PAUSE]**

Whichever you got, you now know what your agent holds. That's the first thing to check when SSH surprises you.

You meet the third state, no agent, under `sudo`, in `cron` jobs and in containers: they don't inherit `SSH_AUTH_SOCK`, the variable that tells `ssh` where the agent is.

**[ANIMATION]** end

One warning: agent forwarding lets a remote machine use your local agent. The manual says it "should be enabled with caution": whoever controls that machine can use your identity while you are connected.

Quick quiz. When you connect to GitHub over SSH, which user name does `ssh` send: your account name, your email address, or `git`? Say it out loud.

**[PAUSE]**

The configuration file. In one sentence: `~/.ssh/config` maps the host name that Git hands to `ssh` onto a real host, a user, a port and a key, and `ssh -G` prints the result of that mapping without connecting.

The file is a list of `Host` blocks. For each setting, the first value obtained wins, so specific blocks go first and `Host *` defaults go last. The keywords that matter for GitHub. `Host` is the name or pattern that appears in a URL: `github.com`, or an alias of your own. `HostName` is the real host. `User` is always `git`, and that's the quiz answer. `IdentityFile` is a private key to offer. `IdentitiesOnly yes` means offer only the configured files, even if the agent holds more keys. Your GitHub account name appears nowhere. GitHub identifies you by which key was accepted.

Git's part is small: it splits the URL and runs `ssh` with what it found. Git doesn't read `~/.ssh/config`.

**[ANIMATION]** hash: differs=byte left=the_key_GitHub_presents right=the_key_in_known__hosts lines=github.com_ED25519,the_published_key alt=a_different_key ids=+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU,8UpYeYa2V/LbESZNhPkXZY4AOtNVNIYX1YezLa3mHbw fn=SHA256 same=The_same_key_gives_the_same_fingerprint diff=A_different_key_under_the_same_name:_another_fingerprint title=The_host_key_check

Host keys. In one sentence: before you prove who you are, the server proves who it is with its host key, and `ssh` compares that key with the one it remembered in `~/.ssh/known_hosts`.

**[ANIMATION]** step: same

Without this check, anyone on the network path could pose as GitHub, accept your connection and relay it. On the first connection `ssh` shows the server key's fingerprint and asks whether to continue. Your answer is the whole security of the scheme, so compare it with the fingerprints GitHub publishes. GitHub also publishes the three `known_hosts` lines, so you can install them and never be asked.

**[ANIMATION]** step: different

A changed host key has two explanations. One: a published rotation. GitHub replaced its RSA host key on the twenty-fourth of March 2023, after the private key was briefly exposed in a public repository. The ECDSA and Ed25519 keys didn't change. Two: someone is in the path. How do you decide? GitHub states that a host key change "will be announced on the GitHub Blog". So you find the announcement first, and you compare the fingerprint with the published ones. Only then do you remove the old lines with `ssh-keygen -R github.com` and install the published lines.

**[ANIMATION]** end

The 🔴 item: `StrictHostKeyChecking no`, and deleting `known_hosts` wholesale. What it changes: `ssh` stops verifying the server. What it can destroy: the guarantee that you're talking to GitHub, and with it the confidentiality of everything you push. There's no preview and no recovery for a connection already intercepted. It isn't appropriate. On a CI runner, the machine that runs an automated job, install the published lines instead.

Testing. `ssh -T git@github.com` authenticates and runs nothing. GitHub's documented answer is "Hi USERNAME! You've successfully authenticated, but GitHub does not provide shell access.", and the command exits with status 1, which is expected. The name in the greeting is the answer to "who does the server say I am", and it is the first thing to read when a repository is "not found". `ssh -vT` adds the client's reasoning: which configuration files were read, which host and port were contacted, which keys were offered.

Some networks block port 22. GitHub accepts SSH on port 443 of a different host name, `ssh.github.com`. GitHub's page notes that the first connection asks about the host key again, under that other name, and that this is not available on GitHub Enterprise Server. The textbook did not verify the host-key behaviour beyond that page.

## MENTAL MODEL

The textbook's analogy: a signet ring and its wax impression. You give everyone a sample impression, the public key. Only the ring, the private key, can make a new one, and anyone can compare.

The analogy breaks because a wax seal can be copied from a sample, and a private key can't be derived from the public key.

**[ANIMATION]** flow: id=proofs actors=your_ssh,*GitHub msgs=2>1:a_signature_made_with_the_host_key|1>1:checked_against_known__hosts|1>2:a_challenge_signed_with_your_private_key|2>2:checked_against_the_public_keys_of_accounts|2>1:the_account_found_=_who_you_are:ok title=An_SSH_connection_is_two_proofs at_1=28 at_2=38 at_3=52 at_4=60 at_5=68

**[ANIMATION]** step: 5

Add the second ring to the picture: the server has one too. An SSH connection is two proofs. First the server shows its impression and you compare it with the sample in `known_hosts`. Then you show yours and the server compares it with the samples in your account. The hook of this video is the first proof failing. Most "permission denied" problems are the second.

## DIAGRAM

**[DIAGRAM]** Client on the left, server on the right. What stays, what is registered, what crosses.

```text
   your machine                                              GitHub
  +-----------------------------+                    +------------------------------+
  | ~/.ssh/id_ed25519           |                    | host key (private half)      |
  |   private key: never leaves |                    |                              |
  | agent: holds it decrypted   |                    | your account:                |
  | ~/.ssh/id_ed25519.pub       | -- uploaded once ->|   your public key            |
  | ~/.ssh/known_hosts          |                    |                              |
  |   GitHub's public host key  |                    |                              |
  +-----------------------------+                    +------------------------------+
        1. server proves itself:   <---- signature made with the host key ----
           checked against known_hosts
        2. you prove yourself:     ---- challenge signed with your private key --->
           checked against the public keys of accounts;  the account found = who you are
```

On the left, the private key stays, and the agent holds it decrypted. The public half was uploaded once and is attached to your account on the right. On the left again, `known_hosts` holds GitHub's public host key.

Two arrows cross. First from right to left: the server proves itself, and your `ssh` checks that against `known_hosts`. Then from left to right: a challenge signed with your private key. Nothing secret travels in either direction.

**[DIAGRAM]** And the path from a remote URL to a key, from section 16.10.

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

Four layers. Git splits the URL. `ssh` applies its configuration. The host key is checked. And GitHub authenticates, then authorizes.

## LIVE TERMINAL DEMO

**[TERMINAL]** A throwaway key in the sandbox. This replay is volatile: your key and fingerprints will differ from mine and from the book. It has no passphrase at first only because a transcript cannot type one.

```bash
labs/run ch16/ssh-keys
```

```bash
ssh-keygen -q -t ed25519 -N '' -C 'you@example.com laptop 2026' -f ~/.ssh/id_ed25519_personal
cd ~/.ssh && stat -f '%Sp  %N' id_ed25519_personal id_ed25519_personal.pub && cd ~
```

<!-- snippet: ch16/ssh-keys/01-generate -->
```text
$ ssh-keygen -q -t ed25519 -N '' -C 'you@example.com laptop 2026' -f ~/.ssh/id_ed25519_personal
$ cd ~/.ssh && stat -f '%Sp  %N' id_ed25519_personal id_ed25519_personal.pub && cd ~
-rw-------  id_ed25519_personal
-rw-r--r--  id_ed25519_personal.pub
```
<!-- /snippet -->

Two files. The private file is readable by its owner only, and `ssh` ignores a private key file that others can access.

```bash
cat ~/.ssh/id_ed25519_personal.pub
ssh-keygen -l -f ~/.ssh/id_ed25519_personal.pub
ssh-keygen -l -E md5 -f ~/.ssh/id_ed25519_personal.pub
```

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

The public half: one line of type, key and comment. Below it the fingerprint in the SHA256 form, which is the form GitHub lists in your account, and in the older MD5 form with colons that some tools still print.

```bash
head -1 ~/.ssh/id_ed25519_personal
ssh-keygen -y -f ~/.ssh/id_ed25519_personal
```

Suppose you lose the `.pub` file. What have you lost? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch16/ssh-keys/03-private-half -->
```text
$ head -1 ~/.ssh/id_ed25519_personal
-----BEGIN OPENSSH PRIVATE KEY-----
$ ssh-keygen -y -f ~/.ssh/id_ed25519_personal
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8GlpVWYok0FGT/hmYU56d4Hw4gnMrujJRDYhk8ZDvu you@example.com laptop 2026
```
<!-- /snippet -->

Nothing: `ssh-keygen -y` recomputes the public key from the private one.

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

A passphrase is set, and a wrong guess fails: "incorrect passphrase supplied to decrypt private key". On your machine `ssh-keygen` asks for the passphrase interactively. It never belongs on a command line. The replay does it only because it can't type.

**[TERMINAL]** The configuration file. `ssh` finds its files through the account's home directory and not through `$HOME`, so every command here names the sandbox file with `-F`. On your machine you omit `-F`.

```bash
labs/run ch16/ssh-config
```

```bash
cat ~/.ssh/config
```

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

**[ANIMATION]** match: id=cfg header=~/.ssh/config rules=Host_github.com:id__ed25519__personal|Host_github-work:id__ed25519__work|Host_github-443:ssh.github.com,_port_443|Host_*:AddKeysToAgent_yes paths=github.com:1+4|github-work:2+4|github-443:3+4 wins=first at_2=12

**[ANIMATION]** step: rules

Four blocks: a personal identity for `github.com`, a work identity behind the alias `github-work`, the port-443 fallback, and the defaults last.

```bash
ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly|addkeystoagent) '
ssh -T -F ~/.ssh/config -G github-work | grep -E '^(hostname|user|port|identityfile|identitiesonly|addkeystoagent) '
```

The alias `github-work`. Which host will `ssh` connect to, and with which key? Make your prediction.

**[PAUSE]**

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

**[ANIMATION]** step: cfg.2

The same host, `github.com`, as a different key holder. Nothing was contacted: `-G` evaluates the `Host` blocks, prints the settings, and exits.

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

**[ANIMATION]** step: cfg.3

The port-443 block resolves to `ssh.github.com`, port 443.

<!-- snippet: ch16/ssh-config/05-user-in-url -->
```text
# A user written in the command or in the URL beats "User git" in the file:
$ ssh -T -F ~/.ssh/config -G asha-rao@github.com | grep -E '^(hostname|user) '
user asha-rao
hostname github.com
```
<!-- /snippet -->

A user written in the command or in the URL beats `User git` in the file. That's how a well-meant `USERNAME@github.com` breaks a working setup.

Now the same file with a `Host *` block moved to the top, containing a default user and an old key. What does `github.com` resolve to? Say it out loud.

**[PAUSE]**

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

```bash
git remote add origin git@github-work:acme-pay/billing-api.git
GIT_SSH_COMMAND=~/lab-bin/fake-ssh git fetch origin
```

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

A stand-in for `ssh` prints the arguments Git gives it and exits. Git passed the alias `github-work` untouched. Git doesn't know that the alias means `github.com`.

**[TERMINAL]** Host keys, with no connection at all.

```bash
labs/run ch16/known-hosts
```

<!-- snippet: ch16/known-hosts/01-published-lines -->
```text
$ cut -c1-78 ~/github-known-hosts.txt
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9o
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTY
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt
```
<!-- /snippet -->

```bash
ssh-keygen -l -f ~/github-known-hosts.txt
```

<!-- snippet: ch16/known-hosts/02-fingerprints -->
```text
$ ssh-keygen -l -f ~/github-known-hosts.txt
256 SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU github.com (ED25519)
256 SHA256:p2QAMXNIC1TJYWeIOttrVc98/R1BUFWu3/LiyKgUfQM github.com (ECDSA)
3072 SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s github.com (RSA)
```
<!-- /snippet -->

The three lines GitHub publishes, copied for the course on the second of October 2026, and their fingerprints computed locally. Compare these three with the table in section 16.11 and with GitHub's page on the day you record.

```bash
cp ~/github-known-hosts.txt ~/.ssh/known_hosts
ssh-keygen -l -F github.com -f ~/.ssh/known_hosts
ssh-keygen -l -F ssh.github.com -f ~/.ssh/known_hosts
```

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

`ssh-keygen -F` answers "what do I have on file for this host". Three entries for `github.com`, and none for `ssh.github.com`, which is a different name.

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

A different key filed under the name `github.com`: what a stale or forged entry looks like. It looks like any other line. Only the fingerprint gives it away.

**[ANIMATION]** replay: hash

Here's that check as a picture. On the left, the key GitHub presents, and its fingerprint.

**[ANIMATION]** step: same

On the right, the key on file. A fingerprint is a hash of the key, so the same key gives the same fingerprint.

**[ANIMATION]** step: different

With the stale line on file, the two no longer match, and a connection to the real GitHub fails with "Host key verification failed." That's the check working.

```bash
ssh-keygen -R github.com -f ~/.ssh/known_hosts
cat ~/github-known-hosts.txt >> ~/.ssh/known_hosts
ssh-keygen -l -F github.com -f ~/.ssh/known_hosts | grep -c SHA256
```

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

The repair: remove the lines for the host, which keeps a `.old` copy, then add the published ones.

**[ON SCREEN]** GitHub walkthrough, Lab 20.1 Part B, in the normal shell. The interface changes; GitHub's guide, which the lab links, is the reference. No output is shown, and no key material is shown.

```bash
ls -al ~/.ssh
ssh-keygen -t ed25519 -C "your_email@example.com"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
ssh-add -l
ssh -G git@github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
gh ssh-key add ~/.ssh/id_ed25519.pub --title "MacBook 2026" --type authentication
gh ssh-key list
ssh -T git@github.com
ssh-keygen -l -F github.com
git ls-remote git@github.com:YOUR-ORG/practice-repo.git
```

Narrate each step by what it changes. `ssh-keygen` asks for a file and a passphrase and writes two files under `~/.ssh`. If `id_ed25519` already exists, choose another file name. Between the second and third commands the lab has you add the `Host github.com` block to `~/.ssh/config` with your editor. `ssh-add` gives the key to the agent and the passphrase to the keychain. `gh ssh-key add` attaches the public key to your account. If it refuses for a missing scope, the lab gives the web form: in your settings, the page for SSH and GPG keys, a new key of type "authentication". On the first `ssh -T`, stop at the fingerprint prompt and compare before you answer. The documentation says the greeting names your account and the exit status is 1.

## COMMON MISTAKES

Five mistakes to watch for.

1. Silencing a host key error with `StrictHostKeyChecking no`. Root cause: the error is the check working; switching it off removes the only proof that the server is GitHub.
2. Writing your account name into the URL, as in `USERNAME@github.com`. Root cause: all connections are made as the user `git`; a user in the URL overrides the configuration.
3. Putting `Host *` defaults at the top of `~/.ssh/config`. Root cause: for each setting the first value obtained wins.
4. Expecting SSH to work under `sudo`, in `cron` or in a container because it works in your terminal. Root cause: those environments do not inherit `SSH_AUTH_SOCK`, so no agent can be reached.
5. Copying one private key to several machines. Root cause: a lost machine then forces revocation everywhere at once; one key per machine limits that to one deletion.

## PRODUCTION EXAMPLE

**[ANIMATION]** decide: id=changed nodes=q1:Does_the_fingerprint_match_one_that_GitHub_publishes?|a:A_published_rotation:_install_the_published_lines|b:Someone_may_be_in_the_path:_off_the_network,_hand_it_to_security edges=q1>a:yes|q1>b:no path=q1,a title=The_host_key_has_changed at_level_1=12 at_level_2=45 at_path=78

**[ANIMATION]** step: path

Now, out of the lab. The build machine from the hook. The engineer doesn't touch the configuration first. She reads the fingerprint in the error, opens GitHub's page of published fingerprints from another machine, and searches the GitHub Blog for an announcement. The machine's `known_hosts` was written in 2022. It holds the RSA host key that GitHub replaced on the twenty-fourth of March 2023. The published RSA fingerprint matches what the server now presents. Explanation one: a rotation, announced. She runs `ssh-keygen -R github.com` and installs the three published lines.

Had the fingerprint matched nothing GitHub publishes, the machine would have been taken off that network and the incident handed to security.

**[ANIMATION]** step: cfg.3

A second habit from the same team: a support ticket that says "SSH is broken since yesterday" gets one request before anything else, the output of `ssh -G github.com` filtered to host name, user, port and identity files. It shows a corporate tool that prepended a `Host *` block, an alias that someone shadowed, or a port override, in less time than reading `ssh -v`.

## PRACTICE EXERCISE

Your turn. Do Lab 20.1, "SSH setup and verification", in [`lab-manual/m20-authentication-ssh.md`](../../lab-manual/m20-authentication-ssh.md). Part A is a rehearsal in the lab shell with a throwaway key, and Part B is the real setup in your normal shell. Before each `ssh -G`, predict the host name, the user and the identity file. Before your first connection, have the published fingerprints open.

The challenge is Exercise 20.4, "`Permission denied (publickey)`", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 233 of the CTO question bank:

> "`ssh` reports that GitHub's host key has changed. What are the two explanations, how do you decide between them, and what do you never do?"

**[PAUSE]**

Answer out loud. A strong answer names both explanations without ranking one as "probably", and bases the decision on evidence from outside the affected connection. It knows the documented rotation and its date as an example. It gives the repair commands in order, and it's unambiguous about the forbidden shortcut and why it's forbidden.

## RECAP

Let's land this.

You should now be able to say:

- The private key never leaves the machine; GitHub holds the public key; a fingerprint is a hash of the public key.
- The agent holds decrypted keys in memory; the passphrase protects the file on disk.
- `~/.ssh/config` maps a host or alias to a host name, user `git`, port and key, first value wins; `ssh -G` prints the result without connecting.
- A host key mismatch is a published rotation or an attack; the published fingerprints decide; the check is never switched off.
- `ssh -T git@github.com` tells you which account the server sees; `ssh.github.com` on port 443 is the fallback when port 22 is blocked.

## HOMEWORK

Read sections 16.8 to 16.12 of [Chapter 16](../../textbook/ch16-authentication.md).

**[ANIMATION]** step: proofs.5

Today you followed an SSH connection through both proofs, and you repaired a host key error without switching the check off. That's a lot of moving parts, so if one of the five steps still blurs, replay its demo. Next time: two identities on one machine, credentials for machines, and single sign-on. Until then, look at the state first and type second. See you in the next one.
