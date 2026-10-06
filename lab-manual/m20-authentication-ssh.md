# Module 20 labs: Authentication and SSH

> **Baseline.** Git 2.55.0, OpenSSH 10.2 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Read [Chapter 16](../textbook/ch16-authentication.md) first; each lab names the sections it uses. Answers to the questions are in [the solutions](../solutions/m20-lab-answers.md); write your own first.

## How these labs work

Every lab has two parts.

- **Part A is a local rehearsal in the lab shell** (`labs/shell`). It contacts nothing, uses throwaway keys and a toy credential helper, and has a replay script in `labs/ch16/`, so its "Expected output" is real.
- **Part B contacts GitHub and runs in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where macOS usually configures the credential helper, so it cannot authenticate to GitHub. Nothing in Part B could be run or captured while this book was written: expected results are described from the linked documentation, and the text says so.

Rules for both parts:

- You create keys and tokens yourself. **No step asks you to paste a token into a command, a URL or a file**, and you should refuse any instruction, here or elsewhere, that does.
- Part A never touches your real `~/.ssh`, your keychain or your Git configuration. Its first step points `HOME` and `GIT_CONFIG_GLOBAL` at a per-lab directory. One trap is part of the lesson: **`ssh` does not use `$HOME`**. It finds `~/.ssh` through your account's real home directory. That is why every `ssh` command in Part A names its file with `-F`, and every `ssh-keygen` command with `-f`. In Part B you leave `-F` out.
- In Part A, `-T` on `ssh -G` only keeps `ssh` from mentioning a terminal in the recorded transcript. You may omit it.
- The fake secret in Part A is spelled `FAKE-TOKEN-not-a-real-credential` so that nobody, and no scanner, can mistake it for a real one.

Start a lab over by running its setup script again.

## Lab 20.1: SSH setup and verification

### Objective

Create an Ed25519 key with a passphrase, load it into the agent, register the public half with GitHub, verify GitHub's host key by fingerprint, and prove from the terminal which user, host and key a connection will use.

### Prerequisites

Chapter 16, sections 16.8 to 16.12. For Part B: a GitHub account, and the practice repository from Lab 19.1.

### Setup

```bash
bash labs/ch16/setup-20-1-ssh-setup.sh
labs/shell m20-1
```

The sandbox has an empty home directory with an `.ssh` directory, and `github-known-hosts.txt`, the three `known_hosts` lines that GitHub publishes (copied on 2 October 2026).

### Commands

Part A, lab shell:

```bash
# 1. A home directory for this lab only
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
cd ~

# 2. A throwaway key pair. No passphrase here, only because the replay cannot type one.
ssh-keygen -q -t ed25519 -N '' -C 'rehearsal key, never uploaded' -f ~/.ssh/id_ed25519_rehearsal
cd ~/.ssh && stat -f '%Sp  %N' id_ed25519_rehearsal id_ed25519_rehearsal.pub && cd ~
cat ~/.ssh/id_ed25519_rehearsal.pub
ssh-keygen -l -f ~/.ssh/id_ed25519_rehearsal.pub

# 3. A configuration file, and what ssh makes of it
printf 'Host github.com\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_rehearsal\n  IdentitiesOnly yes\n\nHost *\n  AddKeysToAgent yes\n' > ~/.ssh/config
chmod 600 ~/.ssh/config
ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '

# 4. GitHub's host keys, checked by fingerprint
cp ~/github-known-hosts.txt ~/.ssh/known_hosts
ssh-keygen -l -f ~/.ssh/known_hosts
```

Compare the three fingerprints with the table in Chapter 16, section 16.11, or with [GitHub's page](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints).

Part B, normal shell. Follow GitHub's guide ([generating a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)); these are its commands:

```bash
# 1. Do you already have keys? If id_ed25519 exists, choose another file name in step 2.
ls -al ~/.ssh

# 2. A key with a passphrase. ssh-keygen asks for the file and the passphrase.
ssh-keygen -t ed25519 -C "your_email@example.com"

# 3. Add this block to ~/.ssh/config with your editor (create the file if it does not exist):
#      Host github.com
#        AddKeysToAgent yes
#        UseKeychain yes
#        IdentityFile ~/.ssh/id_ed25519

# 4. Load the key into the agent and store the passphrase in the keychain
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
ssh-add -l

# 5. What will ssh do for git@github.com?
ssh -G git@github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '

# 6. Register the public key with your account
gh ssh-key add ~/.ssh/id_ed25519.pub --title "MacBook 2026" --type authentication
gh ssh-key list

# 7. Connect. On the first connection, compare the fingerprint BEFORE you answer yes.
ssh -T git@github.com
echo "exit status: $?"
ssh-keygen -l -F github.com

# 8. Git over SSH, without changing the practice repository's remote
git ls-remote git@github.com:YOUR-ORG/practice-repo.git
```

If `gh ssh-key add` refuses because your login lacks a permission scope, use the web form instead: profile picture, **Settings**, **SSH and GPG keys** in the "Access" section, **New SSH key**, key type "authentication" ([adding a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)).

### Expected output

Part A, from the replay `labs/ch16/lab-20-1-ssh-setup.sh`. It is **volatile**: your key and its fingerprint differ from the book's on every run. GitHub's fingerprints in step 4 do not.

<!-- snippet: ch16/lab-20-1-ssh-setup/01-enter -->
```text
$ export HOME="$PWD/home"
$ export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
$ cd ~
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-1-ssh-setup/02-key -->
```text
$ ssh-keygen -q -t ed25519 -N '' -C 'rehearsal key, never uploaded' -f ~/.ssh/id_ed25519_rehearsal
$ cd ~/.ssh && stat -f '%Sp  %N' id_ed25519_rehearsal id_ed25519_rehearsal.pub && cd ~
-rw-------  id_ed25519_rehearsal
-rw-r--r--  id_ed25519_rehearsal.pub
$ cat ~/.ssh/id_ed25519_rehearsal.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGykotsz3keVOsPTTQGlccwdsAyh+3WezDt0yd2RpMLR rehearsal key, never uploaded
$ ssh-keygen -l -f ~/.ssh/id_ed25519_rehearsal.pub
256 SHA256:IxQ1wY4PgaXHd9w6ztScZmyGGY4rqnPripPjd/u6ges rehearsal key, never uploaded (ED25519)
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-1-ssh-setup/03-config -->
```text
$ printf 'Host github.com\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_rehearsal\n  IdentitiesOnly yes\n\nHost *\n  AddKeysToAgent yes\n' > ~/.ssh/config
$ chmod 600 ~/.ssh/config
$ ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
user git
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_ed25519_rehearsal
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-1-ssh-setup/04-host-keys -->
```text
$ cp ~/github-known-hosts.txt ~/.ssh/known_hosts
$ ssh-keygen -l -f ~/.ssh/known_hosts
256 SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU github.com (ED25519)
256 SHA256:p2QAMXNIC1TJYWeIOttrVc98/R1BUFWu3/LiyKgUfQM github.com (ECDSA)
3072 SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s github.com (RSA)
```
<!-- /snippet -->

Part B, described from GitHub's documentation and not captured:

- `ssh-keygen` prompts for a file and twice for a passphrase, then reports where it saved the key.
- `ssh-add -l` prints one line per loaded key: size, SHA256 fingerprint, comment, type.
- `ssh -G git@github.com` prints `user git`, `hostname github.com`, `port 22` and your key as an `identityfile` line, possibly followed by other identity files from blocks you already had. The user comes from the command line here, as it does from a `git@github.com:...` URL.
- On the first connection `ssh` says that the authenticity of the host cannot be established and shows a fingerprint. For an Ed25519 host key it must be `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`. Then: `Hi YOUR-USER! You've successfully authenticated, but GitHub does not provide shell access.` The exit status is 1; GitHub's page says so ([testing your SSH connection](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)).
- `git ls-remote` prints the refs of the practice repository, as in Lab 19.1.

### What happened internally

- `ssh-keygen` wrote a private key file, mode `-rw-------`, and a public key file with one line: type, key, comment. The fingerprint is a hash of the public key.
- `ssh -G` evaluated the `Host` blocks for the name `github.com` and printed the resulting settings. It opened no connection and read no key file.
- The three published `known_hosts` lines hash to the three published fingerprints. That is a property of the keys, which is why the check works offline.
- In Part B, `ssh-add` gave the decrypted key to the agent and stored the passphrase in the keychain. `gh ssh-key add` made an API request that attached the public key to your account. Nothing was written to any repository.
- `ssh -T` connected to `github.com` port 22, checked the server's key against `known_hosts` (adding it after your confirmation), offered your key, and GitHub mapped that key to your account. No repository was involved: the greeting is pure authentication.

### Checkpoint

Part A:

```bash
ssh -T -F ~/.ssh/config -G git@github.com | grep -E '^(hostname|user|port) '
ssh-keygen -l -F github.com -f ~/.ssh/known_hosts | grep -c SHA256
```

<!-- snippet: ch16/lab-20-1-ssh-setup/05-checkpoint -->
```text
$ ssh -T -F ~/.ssh/config -G git@github.com | grep -E '^(hostname|user|port) '
user git
hostname github.com
port 22
$ ssh-keygen -l -F github.com -f ~/.ssh/known_hosts | grep -c SHA256
3
```
<!-- /snippet -->

Part B: `ssh -T git@github.com` greets you by your GitHub user name, and `ssh-keygen -l -F github.com` shows the published fingerprint.

### Failure scenario

Part A. A "helpful" defaults block arrives at the top of the file, as a corporate setup script or a copied snippet would add it:

```bash
printf 'Host *\n  User %s\n  IdentityFile ~/.ssh/id_rsa\n\n' labuser | cat - ~/.ssh/config > ~/.ssh/config-broken
ssh -T -F ~/.ssh/config-broken -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
```

<!-- snippet: ch16/lab-20-1-ssh-setup/06-failure -->
```text
$ printf 'Host *\n  User %s\n  IdentityFile ~/.ssh/id_rsa\n\n' labuser | cat - ~/.ssh/config > ~/.ssh/config-broken
$ ssh -T -F ~/.ssh/config-broken -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
user labuser
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_rsa
identityfile ~/.ssh/id_ed25519_rehearsal
```
<!-- /snippet -->

The user is no longer `git`, and a key that does not exist is offered first. Against GitHub this configuration ends in `Permission denied (publickey)`: GitHub's page states that connecting with any user other than `git` fails ([Permission denied (publickey)](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-denied-publickey)).

### Recovery

For each setting the first value obtained wins, so defaults belong at the end. Remove the block from the top:

```bash
sed '1,4d' ~/.ssh/config-broken > ~/.ssh/config-fixed
diff ~/.ssh/config ~/.ssh/config-fixed && echo identical
ssh -T -F ~/.ssh/config-fixed -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
```

<!-- snippet: ch16/lab-20-1-ssh-setup/07-recovery -->
```text
$ sed '1,4d' ~/.ssh/config-broken > ~/.ssh/config-fixed
$ diff ~/.ssh/config ~/.ssh/config-fixed && echo identical
identical
$ ssh -T -F ~/.ssh/config-fixed -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
user git
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_ed25519_rehearsal
```
<!-- /snippet -->

### Verification

Part A:

```bash
ssh-add -l
ssh -T -F ~/.ssh/config -G github.com | grep -E '^(user|identityfile) '
```

<!-- snippet: ch16/lab-20-1-ssh-setup/08-verification -->
```text
$ ssh-add -l
Could not open a connection to your authentication agent.
[exit status: 2]
$ ssh -T -F ~/.ssh/config -G github.com | grep -E '^(user|identityfile) '
user git
identityfile ~/.ssh/id_ed25519_rehearsal
```
<!-- /snippet -->

Neither the replay nor the lab shell has an agent: both unset `SSH_AUTH_SOCK`, so `ssh-add -l` exits with status 2. That is the state of a `cron` job or a `sudo` shell, and worth recognizing.

Part B: `ssh -T git@github.com` and `git ls-remote git@github.com:YOUR-ORG/practice-repo.git` both succeed in a new terminal window, without asking for the passphrase.

### Questions

1. Which of the two key files did GitHub receive, and what could someone do who obtained only that file?
2. `ssh -G github.com` printed `user git`. Where did that value come from, and where would it come from with GitHub's own four-line `Host` block?
3. In the failure scenario both `IdentityFile` lines are listed, but only one `User`. Why the difference?
4. You verified GitHub's host keys without a connection. What exactly did you compare with what, and why is that enough?
5. `ssh -T git@github.com` exits with status 1 after greeting you. Is that an error? What does the greeting prove, and what does it not prove about the practice repository?
6. What does the agent hold, what does the keychain hold, and what does a thief get who copies `~/.ssh` from a backup?
7. Why does Part A pass `-F` to every `ssh` command even though `HOME` was changed?

## Lab 20.2: HTTPS through the GitHub CLI, and the helper behind it

### Objective

Watch the credential helper protocol with a toy helper, then find out which helper answers for `github.com` on your machine, where it is configured, and which account it presents.

### Prerequisites

Chapter 16, sections 16.3 to 16.5. For Part B: Lab 19.1.

### Setup

```bash
bash labs/ch16/setup-20-2-https-helper.sh
labs/shell m20-2
```

The sandbox has two toy helpers, `git-credential-labstore` and `git-credential-workstore`, in `home/lab-bin`, and a repository `home/work/billing-api` with an HTTPS remote. Read the helper first: `cat home/lab-bin/git-credential-labstore`.

### Commands

Part A, lab shell:

```bash
# 1. Enter the sandbox. GIT_TERMINAL_PROMPT=0 makes Git fail where it would prompt, as in CI.
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" PATH="$HOME/lab-bin:$PATH"
export GIT_TERMINAL_PROMPT=0
cd ~/work/billing-api
git remote -v

# 2. No helper
git config get --show-origin --all credential.helper
printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill

# 3. A helper that has nothing stored yet
git config set --global credential.helper labstore
printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
cat ~/helper.log

# 4. What Git does after a successful request, and the next request
printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=FAKE-TOKEN-not-a-real-credential\n\n' | git credential approve
printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill

# 5. Which program answered?
printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o 'trace: run_command.*'
```

Part B, normal shell:

```bash
# 1. Who is gh logged in as, and with which scopes?
gh auth status

# 2. Which helpers are configured, and in which file?
git config get --show-origin --all credential.helper
git config get --show-origin --all credential.https://github.com.helper

# 3. If the second command printed nothing, let gh configure itself as the helper for github.com
gh auth setup-git
git config get --show-origin --all credential.https://github.com.helper

# 4. Which program does Git run when a credential is needed? A push needs one; --dry-run sends nothing.
#    This step needs an https:// remote. If yours begins with git@, skip to step 5.
cd ~/git-mastery/practice-repo
git remote get-url origin
GIT_TRACE=1 git push --dry-run origin main 2>&1 | grep -o 'run_command.*'

# 5. Which account answers? The sed hides the secret before it reaches your screen.
printf 'protocol=https\nhost=github.com\n\n' | git credential fill | sed 's/^password=.*/password=<hidden>/'
```

### Expected output

Part A, from the replay `labs/ch16/lab-20-2-https-helper.sh`:

<!-- snippet: ch16/lab-20-2-https-helper/01-enter -->
```text
$ export HOME="$PWD/home"
$ export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" PATH="$HOME/lab-bin:$PATH"
$ export GIT_TERMINAL_PROMPT=0
$ cd ~/work/billing-api
$ git remote -v
origin	https://github.com/acme-pay/billing-api.git (fetch)
origin	https://github.com/acme-pay/billing-api.git (push)
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-2-https-helper/02-no-helper -->
```text
$ git config get --show-origin --all credential.helper
[exit status: 1]
$ printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
fatal: could not read Username for 'https://github.com': terminal prompts disabled
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-2-https-helper/03-configure -->
```text
$ git config set --global credential.helper labstore
$ printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
fatal: could not read Username for 'https://github.com': terminal prompts disabled
[exit status: 128]
$ cat ~/helper.log
labstore get   <- protocol=https host=github.com
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-2-https-helper/04-approve-fill -->
```text
$ printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=FAKE-TOKEN-not-a-real-credential\n\n' | git credential approve
$ printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
protocol=https
host=github.com
username=lab-user
password=FAKE-TOKEN-not-a-real-credential
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-2-https-helper/05-trace -->
```text
$ printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o 'trace: run_command.*'
trace: run_command: 'git credential-labstore get'
trace: run_command: git-credential-labstore get
```
<!-- /snippet -->

Part B, described and not captured:

- `gh auth status` prints, for `github.com`, the account you are logged in as, where the token is stored, the Git protocol setting, and the token's scopes, with the token masked (`gh auth status --help`).
- The two `git config get` commands print one line per configured helper with the file it comes from. On a Mac you may see `osxkeychain`, set in a system-level file. After `gh auth setup-git` the second command prints an empty value followed by a line that begins with `!` and ends in `gh auth git-credential`, from your global configuration; that is what the CLI's source writes ([helper_config.go](https://github.com/cli/cli/blob/v2.88.1/pkg/cmd/auth/shared/gitcredentials/helper_config.go)).
- The trace prints `run_command` lines; the one that mentions `credential` names the helper that was asked. The dry run then reports what it would push, or that everything is up to date.
- `git credential fill` prints `protocol`, `host`, a `username` line and `password=<hidden>`. Read the username: it tells you which identity the helper presents.

### What happened internally

- `git credential fill` ran each configured helper with `get`. With no helper, Git wanted to prompt, and `GIT_TERMINAL_PROMPT=0` turned that into `could not read Username`.
- `approve` ran the helper with `store`; the helper wrote the username and secret into its file. The next `fill` got them back from `get` and never needed a prompt.
- Git reduced the URL to protocol and host before asking: the helper's log shows no `path=`. One credential serves every repository on the host.
- In Part B, `gh auth setup-git` changed your global Git configuration and nothing else. The token did not move: it stays where `gh auth login` stored it, and Git obtains it by running `gh` each time.

### Checkpoint

Part A:

```bash
cat ~/helper.log
```

<!-- snippet: ch16/lab-20-2-https-helper/06-checkpoint -->
```text
$ cat ~/helper.log
labstore get   <- protocol=https host=github.com
labstore store <- protocol=https host=github.com username=lab-user password=<hidden>
labstore get   <- protocol=https host=github.com
labstore get   <- protocol=https host=github.com
```
<!-- /snippet -->

Four lines: a `get` that found nothing, the `store`, and two `get` calls that were answered. Part B: you can say which file configures the helper for `github.com` on your machine, and which account it presents.

### Failure scenario

Part A. A second account. Its helper is configured after the first one:

```bash
printf 'username=work-user\npassword=FAKE-TOKEN-not-a-real-credential\n' > ~/.workstore-credentials
git config set --global --append credential.helper workstore
printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o "trace: run_command: '.*"
```

<!-- snippet: ch16/lab-20-2-https-helper/07-failure -->
```text
# A second helper holds the work account. It is configured after the first one.
$ printf 'username=work-user\npassword=FAKE-TOKEN-not-a-real-credential\n' > ~/.workstore-credentials
$ git config set --global --append credential.helper workstore
$ printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
protocol=https
host=github.com
username=lab-user
password=FAKE-TOKEN-not-a-real-credential
$ printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o "trace: run_command: '.*"
trace: run_command: 'git credential-labstore get'
```
<!-- /snippet -->

This is a work repository, and the personal account answers. The first helper in the list had a credential for the host, so Git never asked the second. Against GitHub the result would be "Repository not found" or a 403, and neither makes Git discard the credential.

### Recovery

Make the right helper answer for this host: reset the list for `https://github.com`, then name the helper.

```bash
git config set --global --append credential.https://github.com.helper ''
git config set --global --append credential.https://github.com.helper workstore
printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o "trace: run_command: '.*"
```

<!-- snippet: ch16/lab-20-2-https-helper/08-recovery -->
```text
$ git config set --global --append credential.https://github.com.helper ''
$ git config set --global --append credential.https://github.com.helper workstore
$ printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
protocol=https
host=github.com
username=work-user
password=FAKE-TOKEN-not-a-real-credential
$ printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o "trace: run_command: '.*"
trace: run_command: 'git credential-workstore get'
```
<!-- /snippet -->

### Verification

```bash
git config get --show-scope --all credential.helper
git config get --show-scope --all credential.https://github.com.helper
printf 'protocol=https\nhost=github.com\nusername=work-user\npassword=FAKE-TOKEN-not-a-real-credential\n\n' | git credential reject
cat ~/.workstore-credentials
cat ~/.labstore-credentials
```

<!-- snippet: ch16/lab-20-2-https-helper/09-verification -->
```text
$ git config get --show-scope --all credential.helper
global	labstore
global	workstore
$ git config get --show-scope --all credential.https://github.com.helper
global	
global	workstore
$ printf 'protocol=https\nhost=github.com\nusername=work-user\npassword=FAKE-TOKEN-not-a-real-credential\n\n' | git credential reject
$ cat ~/.workstore-credentials
cat: $LAB/ch16/lab-20-2-https-helper/home/.workstore-credentials: No such file or directory
[exit status: 1]
$ cat ~/.labstore-credentials
username=lab-user
password=FAKE-TOKEN-not-a-real-credential
```
<!-- /snippet -->

The `reject` went to the helper that answers for the host and erased its credential. The other helper's credential is untouched.

### Questions

1. Put the three helper operations in the order Git uses them for a first successful push, and for a push with a revoked token.
2. In step 3 of Part A the helper was configured and `fill` still failed. Why, and what does the log prove?
3. The helper's log never shows a `path=` attribute. What follows for a machine that works with two accounts on `github.com`, and which two settings change it?
4. In the failure scenario, why was the second helper never asked? Which evidence showed it?
5. Why does the recovery need the empty value before `workstore`? What would the list for `github.com` be without it?
6. On your machine, which file configures the helper for `github.com`, and which scope is that file? Why does the lab shell not see it?
7. A server answers 403 to a stored credential. What does Git do to the stored credential, and how do you know?

## Lab 20.3: Three failures, reproduced and diagnosed

### Objective

Produce `Permission denied (publickey)`, `Host key verification failed` and an HTTPS authentication failure on purpose, without changing your working setup, and for each one name the layer that failed and the evidence.

### Prerequisites

Chapter 16, sections 16.5, 16.7, 16.10, 16.11 and 16.17 to 16.20. Labs 20.1 and 20.2.

### Setup

```bash
bash labs/ch16/setup-20-3-failures.sh
labs/shell m20-3
```

The sandbox has a repository `home/work/billing-api` with an SSH remote, a stand-in for `ssh` in `home/lab-bin/fake-ssh` that prints its arguments and exits, GitHub's published `known_hosts` lines, a stale host key in `home/stale-host-key.pub`, and the toy helper with one stored credential.

### Commands

Part A, lab shell. Collect the evidence for each failure without a network:

```bash
# 1. Enter
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" PATH="$HOME/lab-bin:$PATH"
export GIT_TERMINAL_PROMPT=0
cd ~/work/billing-api

# 2. Who would connect? Git hands user and host to ssh.
git remote get-url origin
GIT_SSH_COMMAND=~/lab-bin/fake-ssh git fetch origin

# 3. A wrong user in the URL
git remote set-url origin ssh://lab-user@github.com/acme-pay/billing-api.git
GIT_SSH_COMMAND=~/lab-bin/fake-ssh git fetch origin 2>&1 | head -1
ssh -T -F none -G lab-user@github.com | grep '^user '
git remote set-url origin git@github.com:acme-pay/billing-api.git

# 4. A command line that offers no key at all
ssh -T -F none -o IdentityAgent=none -o IdentityFile=none -G git@github.com | grep -E '^(user|hostname|identityagent|identityfile) '

# 5. Host keys: the good entry, a stale entry, and the repair
ssh-keygen -l -F github.com -f ~/.ssh/known_hosts | grep ED25519
printf 'github.com %s\n' "$(cut -d' ' -f1,2 ~/stale-host-key.pub)" > ~/.ssh/known_hosts-stale
ssh-keygen -l -F github.com -f ~/.ssh/known_hosts-stale
ssh -T -F none -o UserKnownHostsFile="$HOME/.ssh/known_hosts-stale" -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=yes -G git@github.com | grep -E '^(userknownhostsfile|globalknownhostsfile|stricthostkeychecking) '
ssh-keygen -R github.com -f ~/.ssh/known_hosts-stale
cat ~/github-known-hosts.txt >> ~/.ssh/known_hosts-stale
ssh-keygen -l -F github.com -f ~/.ssh/known_hosts-stale | grep ED25519

# 6. A wrong HTTPS credential for one command, with the stored one left alone
printf 'protocol=https\nhost=github.com\n\n' | git credential fill
printf 'protocol=https\nhost=github.com\n\n' | git -c credential.helper= -c credential.https://github.com.helper= -c credential.helper='!f() { test "$1" = get && printf "username=lab-user\npassword=not-a-token\n"; }; f' credential fill
printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=not-a-token\n\n' | git -c credential.helper= -c credential.https://github.com.helper= -c credential.helper='!f() { test "$1" = get && printf "username=lab-user\npassword=not-a-token\n"; }; f' credential reject
```

Part B, normal shell. The same three failures against GitHub. None of these commands changes your configuration, your keys, your `known_hosts` or your stored credentials. Run the second one from the course folder.

```bash
# Failure 1: no key is offered
ssh -T -F none -o IdentityAgent=none -o IdentityFile=none git@github.com
echo "exit status: $?"
GIT_SSH_COMMAND='ssh -F none -o IdentityAgent=none -o IdentityFile=none' git ls-remote git@github.com:YOUR-ORG/practice-repo.git

# Failure 2: a stale host key, in a scratch known_hosts file
mkdir -p ~/git-mastery/scratch-hostkey
printf 'github.com %s\n' "$(cut -d' ' -f1,2 labs/ch16/stale-host-key.pub)" > ~/git-mastery/scratch-hostkey/known_hosts
ssh -T -o UserKnownHostsFile="$HOME/git-mastery/scratch-hostkey/known_hosts" -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=yes git@github.com
echo "exit status: $?"

# Failure 3: a wrong credential for a repository that does not exist, then the right credential
git -c credential.helper= -c credential.https://github.com.helper= \
    -c credential.helper='!f() { test "$1" = get && printf "username=YOUR-USER\npassword=not-a-token\n"; }; f' \
    ls-remote https://github.com/YOUR-ORG/no-such-repo.git
git ls-remote https://github.com/YOUR-ORG/no-such-repo.git
gh repo view YOUR-ORG/no-such-repo
```

After each failure, before reading on, write down: which program wrote each line, which of the three questions of section 16.1 failed, and one command that would confirm it.

### Expected output

Part A, from the replay `labs/ch16/lab-20-3-failures.sh`:

<!-- snippet: ch16/lab-20-3-failures/02-who-connects -->
```text
$ git remote get-url origin
git@github.com:acme-pay/billing-api.git
$ GIT_SSH_COMMAND=~/lab-bin/fake-ssh git fetch origin
ssh was asked to run: git@github.com git-upload-pack 'acme-pay/billing-api.git'
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-3-failures/03-wrong-user -->
```text
$ git remote set-url origin ssh://lab-user@github.com/acme-pay/billing-api.git
$ GIT_SSH_COMMAND=~/lab-bin/fake-ssh git fetch origin 2>&1 | head -1
ssh was asked to run: lab-user@github.com git-upload-pack '/acme-pay/billing-api.git'
$ ssh -T -F none -G lab-user@github.com | grep '^user '
user lab-user
$ git remote set-url origin git@github.com:acme-pay/billing-api.git
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-3-failures/04-no-key-offered -->
```text
$ ssh -T -F none -o IdentityAgent=none -o IdentityFile=none -G git@github.com | grep -E '^(user|hostname|identityagent|identityfile) '
user git
hostname github.com
identityagent none
identityfile none
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-3-failures/05-host-key-good -->
```text
$ ssh-keygen -l -F github.com -f ~/.ssh/known_hosts | grep ED25519
github.com ED25519 SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-3-failures/06-host-key-stale -->
```text
$ printf 'github.com %s\n' "$(cut -d' ' -f1,2 ~/stale-host-key.pub)" > ~/.ssh/known_hosts-stale
$ ssh-keygen -l -F github.com -f ~/.ssh/known_hosts-stale
# Host github.com found: line 1 
github.com ED25519 SHA256:8UpYeYa2V/LbESZNhPkXZY4AOtNVNIYX1YezLa3mHbw
$ ssh -T -F none -o UserKnownHostsFile="$HOME/.ssh/known_hosts-stale" -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=yes -G git@github.com | grep -E '^(userknownhostsfile|globalknownhostsfile|stricthostkeychecking) '
stricthostkeychecking true
globalknownhostsfile /dev/null
userknownhostsfile $LAB/ch16/lab-20-3-failures/home/.ssh/known_hosts-stale
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-3-failures/07-host-key-repair -->
```text
$ ssh-keygen -R github.com -f ~/.ssh/known_hosts-stale
# Host github.com found: line 1
$LAB/ch16/lab-20-3-failures/home/.ssh/known_hosts-stale updated.
Original contents retained as $LAB/ch16/lab-20-3-failures/home/.ssh/known_hosts-stale.old
$ cat ~/github-known-hosts.txt >> ~/.ssh/known_hosts-stale
$ ssh-keygen -l -F github.com -f ~/.ssh/known_hosts-stale | grep ED25519
github.com ED25519 SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-3-failures/08-wrong-credential -->
```text
$ printf 'protocol=https\nhost=github.com\n\n' | git credential fill
protocol=https
host=github.com
username=lab-user
password=FAKE-TOKEN-not-a-real-credential
$ printf 'protocol=https\nhost=github.com\n\n' | git -c credential.helper= -c credential.https://github.com.helper= -c credential.helper='!f() { test "$1" = get && printf "username=lab-user\npassword=not-a-token\n"; }; f' credential fill
protocol=https
host=github.com
username=lab-user
password=not-a-token
$ printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=not-a-token\n\n' | git -c credential.helper= -c credential.https://github.com.helper= -c credential.helper='!f() { test "$1" = get && printf "username=lab-user\npassword=not-a-token\n"; }; f' credential reject
```
<!-- /snippet -->

Part B, described from the documentation and not captured:

- **Failure 1.** `ssh` prints a line ending in `Permission denied (publickey).` and exits with status 255. Under Git the same line is followed by `fatal: Could not read from remote repository.` and its two-line hint. The server rejected the connection because no key was offered ([Permission denied (publickey)](https://docs.github.com/en/authentication/troubleshooting-ssh/error-permission-denied-publickey)).
- **Failure 2.** `ssh` refuses to continue, and the last line is `Host key verification failed.`: the server presented a key that does not match the one on file ([Host key verification failed](https://docs.github.com/en/authentication/troubleshooting-ssh/error-host-key-verification-failed)). With a mismatching entry, OpenSSH prints a boxed warning that the remote host identification has changed first; the 2023 announcement of GitHub's RSA key rotation shows that warning ([GitHub Blog](https://github.blog/news-insights/company-news/we-updated-our-rsa-ssh-host-key/)). Your real `known_hosts` was not consulted and not changed.
- **Failure 3.** With the wrong credential, Git ends with `fatal: Authentication failed for 'https://github.com/YOUR-ORG/no-such-repo.git/'`, the message Git prints for HTTP 401 ([remote-curl.c](https://github.com/git/git/blob/v2.55.0/remote-curl.c)), preceded by a `remote:` line whose wording is not documented. With your real credential, the same URL gives a `remote:` line saying the repository was not found and `fatal: repository '...' not found`, Git's message for HTTP 404 ([troubleshooting cloning errors](https://docs.github.com/en/repositories/creating-and-managing-repositories/troubleshooting-cloning-errors#error-repository-not-found)). `gh repo view` reports that it could not find the repository, in gh's words.

If your results differ, the differences are evidence too: write them down and compare with section 16.19.

### What happened internally

- **Part A, steps 2 and 3.** Git parsed the URL into user, host and path and started the `ssh` program with them. The user came from the URL. `ssh -G` confirmed that a user given on the command line wins.
- **Step 4.** `-F none` ignores every configuration file, `IdentityFile=none` loads no key file, `IdentityAgent=none` asks no agent. The effective configuration shows a connection that can authenticate as nobody.
- **Step 5.** A `known_hosts` line is a host name and a public key. The stale line has a different key and therefore a different fingerprint. `ssh-keygen -R` removed the host's lines and kept a `.old` copy.
- **Step 6.** `-c credential.helper=` and `-c credential.https://github.com.helper=` emptied both helper lists for one command; the inline helper answered `get` and ignored `erase`. The stored credential was neither read nor erased: the helper log has a single line.
- **Part B.** In failure 1 the SSH server ended the connection during authentication. In failure 2 your client ended it before authentication. In failure 3 the server answered 401, then 404, to two different credentials for the same URL: "who are you" failed first, "may you see this" second.

### Checkpoint

Part A:

```bash
cat ~/helper.log
cat ~/.labstore-credentials
```

<!-- snippet: ch16/lab-20-3-failures/09-checkpoint -->
```text
$ cat ~/helper.log
labstore get   <- protocol=https host=github.com
$ cat ~/.labstore-credentials
username=lab-user
password=FAKE-TOKEN-not-a-real-credential
```
<!-- /snippet -->

One `get`, from the first `fill`, and the stored credential is intact. Part B: `ssh -T git@github.com` and `git ls-remote origin` in the practice repository still work exactly as before the lab.

### Failure scenario

Part A. The fix that every search result offers for an HTTPS failure. The token is fake.

```bash
git remote set-url origin https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git
git remote -v
grep -c FAKE-TOKEN .git/config
```

<!-- snippet: ch16/lab-20-3-failures/10-failure -->
```text
# The tempting fix for any HTTPS failure. The token is fake.
$ git remote set-url origin https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git
$ git remote -v
origin	https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git (fetch)
origin	https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git (push)
$ grep -c FAKE-TOKEN .git/config
1
```
<!-- /snippet -->

It would work, and the secret is now in a plain text file and on your screen.

### Recovery

Clean the URL, then make Git refuse such URLs, and see what the refusal looks like:

```bash
git remote set-url origin https://github.com/acme-pay/billing-api.git
git config set --global transfer.credentialsInUrl die
git remote set-url origin https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git
git fetch origin
git config set remote.origin.url git@github.com:acme-pay/billing-api.git
```

<!-- snippet: ch16/lab-20-3-failures/11-recovery -->
```text
$ git remote set-url origin https://github.com/acme-pay/billing-api.git
$ git config set --global transfer.credentialsInUrl die
$ git remote set-url origin https://lab-user:FAKE-TOKEN-not-a-real-credential@github.com/acme-pay/billing-api.git
$ git fetch origin
fatal: URL 'https://lab-user:<redacted>@github.com/acme-pay/billing-api.git' uses plaintext credentials
[exit status: 128]
$ git config set remote.origin.url git@github.com:acme-pay/billing-api.git
```
<!-- /snippet -->

`git remote set-url` could still write the bad URL, and every command that then reads the remote refuses. The last command repairs it by writing the configuration key directly, because with `die` in force `git remote set-url` itself would refuse to read the remote. With a real token, the recovery has one more step that no command here performs: revoke the token.

### Verification

```bash
git remote -v
grep -c FAKE-TOKEN .git/config
git config get --show-scope transfer.credentialsInUrl
```

<!-- snippet: ch16/lab-20-3-failures/12-verification -->
```text
$ git remote -v
origin	git@github.com:acme-pay/billing-api.git (fetch)
origin	git@github.com:acme-pay/billing-api.git (push)
$ grep -c FAKE-TOKEN .git/config
0
[exit status: 1]
$ git config get --show-scope transfer.credentialsInUrl
global	die
```
<!-- /snippet -->

In Part B, remove the scratch file: `rm -r ~/git-mastery/scratch-hostkey`. Consider setting `transfer.credentialsInUrl` to `die` in your real global configuration.

### Questions

1. For each of the three failures in Part B, name the program that wrote the decisive line and the layer that failed: transport, client credential, or server decision.
2. `Permission denied (publickey)` and "Repository not found" can both be caused by using the wrong account. What has the server established in one case that it has not in the other?
3. The same URL produced "Authentication failed" and then "not found". Which HTTP status belongs to each, and what does Git do to a stored credential in each case?
4. Why did failure 3 not damage your stored credential, although Git erases rejected credentials?
5. In failure 2, what would `StrictHostKeyChecking=no` have done, and why is that never the fix?
6. A colleague's push ends with "Could not read from remote repository" and nothing above it. What do you ask them to run, and why?
7. After the recovery, the token is no longer in `.git/config`. Is the incident over? Where else can the string be?

## Lab 20.4: Two identities on one machine (optional)

### Objective

Make the directory of a repository choose the commit email, the remote URL and the SSH key together, and prove from the terminal which identity each repository would use, without connecting.

### Prerequisites

Chapter 16, sections 16.2, 16.10 and 16.13. Chapter 14B, section 14B.4, on `includeIf`. Part B needs a second GitHub account that you are entitled to use, for example a work account; skip Part B otherwise.

### Setup

```bash
bash labs/ch16/setup-20-4-two-identities.sh
labs/shell m20-4
```

The sandbox has `home/personal/notes-app` and `home/work/billing-api`, both with `git@github.com:...` remotes, and the `fake-ssh` stand-in.

### Commands

Part A, lab shell:

```bash
# 1. Enter
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" PATH="$HOME/lab-bin:$PATH"
cd ~

# 2. Two host aliases
printf 'Host github.com\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_personal\n  IdentitiesOnly yes\n\nHost github-work\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_work\n  IdentitiesOnly yes\n' > ~/.ssh/config
ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|identityfile) '
ssh -T -F ~/.ssh/config -G github-work | grep -E '^(hostname|user|identityfile) '

# 3. The personal identity as default; the work identity for everything under ~/work/
git config set --global user.email lab-user@personal.example
git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
printf '[user]\n\temail = lab.user@acme-pay.example\n[url "git@github-work:"]\n\tinsteadOf = git@github.com:\n' > ~/.gitconfig-work

# 4. Evidence, personal repository
cd ~/personal/notes-app
git config get --show-origin user.email
git remote get-url origin
GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1

# 5. Evidence, work repository
cd ~/work/billing-api
git config get --show-origin user.email
git remote get-url origin
GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
```

Part B, normal shell, only with a second account. Follow GitHub's guide ([managing multiple accounts](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-your-personal-account/managing-multiple-accounts)): generate a second key with its own file name, add it to the second account, add a `Host` alias with `HostName github.com`, `IdentityFile` and `IdentitiesOnly yes` to your real `~/.ssh/config`, and create the include file as in step 3 with your real directory and addresses. Then collect the same evidence as in steps 4 and 5, without `GIT_SSH_COMMAND`, and test both identities:

```bash
ssh -T git@github.com
ssh -T git@github-work
```

Each must greet a different account.

### Expected output

Part A, from the replay `labs/ch16/lab-20-4-two-identities.sh`:

<!-- snippet: ch16/lab-20-4-two-identities/02-ssh-config -->
```text
$ printf 'Host github.com\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_personal\n  IdentitiesOnly yes\n\nHost github-work\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_work\n  IdentitiesOnly yes\n' > ~/.ssh/config
$ ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|identityfile) '
user git
hostname github.com
identityfile ~/.ssh/id_ed25519_personal
$ ssh -T -F ~/.ssh/config -G github-work | grep -E '^(hostname|user|identityfile) '
user git
hostname github.com
identityfile ~/.ssh/id_ed25519_work
```
<!-- /snippet -->

<!-- snippet: ch16/lab-20-4-two-identities/04-personal -->
```text
$ cd ~/personal/notes-app
$ git config get --show-origin user.email
file:$LAB/ch16/lab-20-4-two-identities/home/.gitconfig	lab-user@personal.example
$ git remote get-url origin
git@github.com:lab-user/notes-app.git
$ GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
ssh was asked to run: git@github.com git-upload-pack 'lab-user/notes-app.git'
```
<!-- /snippet -->

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

Part B, described from GitHub's guide: `ssh -T git@github.com` greets your personal user name and `ssh -T git@github-work` greets the other account.

### What happened internally

- `includeIf "gitdir:~/work/"` made Git read `~/.gitconfig-work` for repositories whose `.git` directory lies under `~/work/`. That file set `user.email` and a URL rewrite.
- `url."git@github-work:".insteadOf` did not change `.git/config`: the stored URL still says `github.com`. It changed the URL at the moment of use, which `git remote get-url` shows.
- Git then started `ssh` for the host `github-work`. Only `ssh` knows that the alias means `github.com` with another key.
- Three identities moved together because one file sets two of them and selects the third: commit email, effective URL, and through the alias the key.

### Checkpoint

In the work repository `git config get --show-origin user.email` names `.gitconfig-work` as the origin, and `git remote get-url origin` begins with `git@github-work:`. In the personal repository neither is true.

### Failure scenario

Part A. A second work repository, created in the wrong place:

```bash
mkdir -p ~/Downloads && cd ~/Downloads
git init -q ledger-export && cd ledger-export
git remote add origin git@github.com:acme-pay/ledger-export.git
git config get --show-origin user.email
git remote get-url origin
GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
```

<!-- snippet: ch16/lab-20-4-two-identities/06-failure -->
```text
# A second work repository, created in the wrong place:
$ mkdir -p ~/Downloads && cd ~/Downloads
$ git init -q ledger-export && cd ledger-export
$ git remote add origin git@github.com:acme-pay/ledger-export.git
$ git config get --show-origin user.email
file:$LAB/ch16/lab-20-4-two-identities/home/.gitconfig	lab-user@personal.example
$ git remote get-url origin
git@github.com:acme-pay/ledger-export.git
$ GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
ssh was asked to run: git@github.com git-upload-pack 'acme-pay/ledger-export.git'
```
<!-- /snippet -->

Personal email, personal key. Commits would carry the wrong address, and a push would be authenticated as the personal account, which GitHub would answer with "not found" or a permission error naming that user.

### Recovery

Key the include on the remote URL as well, so that the location on disk no longer matters:

```bash
git config set --global 'includeIf.hasconfig:remote.*.url:git@github.com:acme-pay/**.path' '~/.gitconfig-work'
git config get --show-origin user.email
git remote get-url origin
GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
```

<!-- snippet: ch16/lab-20-4-two-identities/07-recovery -->
```text
$ git config set --global 'includeIf.hasconfig:remote.*.url:git@github.com:acme-pay/**.path' '~/.gitconfig-work'
$ git config get --show-origin user.email
file:$LAB/ch16/lab-20-4-two-identities/home/.gitconfig-work	lab.user@acme-pay.example
$ git remote get-url origin
git@github-work:acme-pay/ledger-export.git
$ GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote origin 2>&1 | head -1
ssh was asked to run: git@github-work git-upload-pack 'acme-pay/ledger-export.git'
```
<!-- /snippet -->

### Verification

```bash
cd ~/personal/notes-app && git config get user.email && git remote get-url origin
cd ~/work/billing-api && git config get user.email && git remote get-url origin
cd ~/Downloads/ledger-export && git config get user.email && git remote get-url origin
```

<!-- snippet: ch16/lab-20-4-two-identities/08-verification -->
```text
$ cd ~/personal/notes-app && git config get user.email && git remote get-url origin
lab-user@personal.example
git@github.com:lab-user/notes-app.git
$ cd ~/work/billing-api && git config get user.email && git remote get-url origin
lab.user@acme-pay.example
git@github-work:acme-pay/billing-api.git
$ cd ~/Downloads/ledger-export && git config get user.email && git remote get-url origin
lab.user@acme-pay.example
git@github-work:acme-pay/ledger-export.git
```
<!-- /snippet -->

### Questions

1. Which three identities does this setup align, and which program enforces each?
2. `git config get remote.origin.url` and `git remote get-url origin` disagree in the work repository. Which one does `ssh` receive, and why is the difference useful?
3. In the failure scenario, list every consequence of the wrong location: for the next commit, and for the next push.
4. The recovery matches on the configured URL `git@github.com:acme-pay/**`. Would it still match if someone had cloned with the alias URL `git@github-work:acme-pay/ledger-export.git`? What would you add?
5. Why does each `Host` block set `IdentitiesOnly yes`? Describe the failure without it when an agent holds both keys.
6. How would you get the same separation over HTTPS, and why is `gh auth switch` not equivalent to this setup?
