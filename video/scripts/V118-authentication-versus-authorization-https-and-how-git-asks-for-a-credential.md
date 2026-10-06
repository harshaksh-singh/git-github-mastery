# V118: Authentication versus authorization, HTTPS, and how Git asks for a credential

- **Part.** 5: GitHub
- **Module.** 20
- **Planned minutes.** 24
- **Prerequisites.** V027, V115
- **Textbook sections.** [Chapter 16](../../textbook/ch16-authentication.md), sections 16.1 to 16.5
- **Demo scripts.** `labs/ch16/credential-protocol.sh`, `labs/ch16/credential-scope.sh`; GitHub-side walkthrough of Lab 20.2

## HOOK

**[ON SCREEN]** "Access granted Monday. Wednesday: 403. Git never asks."

You gave Ravi write access to the work repository on Monday. On Wednesday his push, the upload of his commits, still fails with 403, and Git never asks him for anything. No prompt, no chance to type a different credential. Your CTO asks: why?

**[ANIMATION]** flow: id=wed actors=Git,the_keychain,*GitHub msgs=1>2:get|2>1:a_credential_for_another_account|1>3:push_with_that_credential|3>1:403:fail|2>2:not_erased|1>3:the_same_credential,_every_time:fail boundary=2 zones=his_machine,the_network title=Wednesday:_403,_and_Git_never_asks at_1=3 at_2=15 at_3=35 at_4=42 at_5=55 at_6=68

**[ANIMATION]** step: 6

Because his keychain, the Mac's password store, holds a credential for another account. A 403 doesn't make Git discard it, so Git keeps sending it. Granting access to his work account changed nothing, because that account never arrives at the server.

To see that in five minutes and not five hours, you need to know exactly what Git does between "the server wants authentication" and "the token is stored". Keep Ravi's Wednesday in mind. You'll solve it before the end.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the first of five videos on authentication, Chapter 16. The whole chapter rests on three questions, asked in this order.

**[ON SCREEN]** The three questions of section 16.1.

Which transport and which server? That's decided by the remote URL, after rewrites, and the evidence is `git remote -v`. Which credential does the client present? Decided by Git's credential helpers for HTTPS, and by `ssh`, its configuration and the agent for SSH. And: who does the server say you are, and what may that identity do? Decided by GitHub.

A failure is always in exactly one of the three. Commands copied from a search result usually change a different one.

Today: the distinction between authentication and authorization, the HTTPS transport, and the credential helper protocol. The replays, `credential-protocol.sh` and `credential-scope.sh`, use a stand-in helper and no real credential. Every token on screen is a fake string from the lab. Then a walkthrough of Lab 20.2 in the normal shell. I never show a token, and neither should you.

Labels from the chapter's table: `git credential fill` and `gh auth status` are 🟢 SAFE, though `fill` prints a secret on your screen. `git config set --global credential...`, `gh auth setup-git` and `gh auth login` are 🟡 CAUTION: they change which credential answers, for every repository. `git credential reject` is 🟡: it deletes a stored credential.

## LEARNING OBJECTIVES

After this video you can:

- Separate "who are you" from "what may you do" in an error message.
- Describe what Git does from the server's 401 to the stored token, naming the helper operations.
- Find out which credential helper answers for a host and where the token lives.
- Scope a helper to one host or one path.
- Read a credential trace.

## CONCEPT

In one sentence: authentication establishes which account a connection belongs to, and authorization decides what that account may do to this repository.

Git has no accounts and no passwords. It delegates the connection to a transport. Over HTTPS, Git speaks HTTP and attaches a username and a secret obtained from a credential helper or a prompt. For GitHub the secret is a token, a string that stands for an account with a subset of its rights. Over SSH, Git starts the `ssh` program, which proves possession of a private key. Git never sees the key.

**[ANIMATION]** gates: id=two packet=a_connection gates=authentication:pass:a_token_or_a_key:which_account_is_this?|authorization:pass:roles_and_rules:what_may_it_do_to_this_repository? title=Two_checks,_in_this_order at_1=5 at_2=50

**[ANIMATION]** step: 2

The server maps the token or key to an account, which is authentication. Then it evaluates roles, token permissions and organization rules for the repository, which is authorization.

**[ANIMATION]** cards: id=ids question=Three_independent_identities cards=Commit_identity:user.name_and_user.email,_checked_by_nobody|Authentication_identity:the_account_a_token_or_SSH_key_belongs_to,_checked_by_GitHub|Signing_identity:the_key_that_signed_a_commit_or_tag at_1=14 at_2=42 at_3=86

**[ANIMATION]** step: 3

Three identities are involved in everyday work, and they're independent. The commit identity: the author and committer name and email written into commits, set by `user.name` and `user.email`, checked by nobody. It's an assertion. The authentication identity: the GitHub account that a token or SSH key belongs to, checked by GitHub on every connection. The signing identity: the key that signed a commit or tag. You can push commits written by anyone, as any account that has Write, signed by any key or none. "It says Asha in the log" is not evidence of who pushed.

**[ANIMATION]** end

HTTPS. In one sentence: over HTTPS, GitHub accepts a token in the place where HTTP expects a password, and nothing else. GitHub has not accepted account passwords for Git since the thirteenth of August 2021. Git still calls the secret a password, because to Git it is one: the prompt reads "Password for", and you'll see it. In practice nobody should type a token: the GitHub CLI or Git Credential Manager obtains one through the browser and hands it to Git.

One caveat the textbook marks unverified: the exact text GitHub's server sends when a password is used is not quoted in any GitHub documentation the course could find. Recognize the situation by Git's own last line, `fatal: Authentication failed for` and the URL, which is in Git's source.

**[ANIMATION]** flow: id=ask actors=Git,credential_helper,*the_server msgs=1>3:request_without_a_credential|3>1:401,_authentication_required|1>2:get_(protocol,_host)|2>1:username_and_token|1>3:request_with_the_credential|3>1:accepted:ok|1>2:store boundary=2 zones=your_machine,the_network title=How_Git_asks_for_a_credential at_1=18 at_2=30 at_3=22 at_4=50 at_5=80 at_6=40 at_7=55

**[ANIMATION]** step: 2

Now the protocol. In one sentence: when a server demands authentication, Git asks each configured credential helper in turn, then falls back to prompting, and afterwards tells the helpers whether the credential worked.

**[ANIMATION]** step: 5

A helper is a program that Git runs with one argument, `get`, `store` or `erase`, and a description of the request on standard input as `key=value` lines: `protocol`, `host`, and optionally `path` and `username`. `git credential fill`, `approve` and `reject` drive the same machinery by hand, so the whole exchange can be watched without a server.

**[ANIMATION]** end

Quick quiz, before the table. Git sends a stored credential, and the server answers 403. What does Git tell the helper: store, erase, or nothing? Say it out loud.

**[PAUSE]**

**[ON SCREEN]** The state table of section 16.4.

A request needs a credential: the helper's store is read, `get`. The server accepted it: the store is written, `store`. The server answered 401: the entry is removed, `erase`. The server answered 403 or 404: the store is unchanged. So the quiz answer is nothing. If you said erase, you expected Git to tidy up, and that's a reasonable thing to expect. That last row is from Git's source: the reject is called for a 401 with a credential that was sent, and for nothing else on this path. In all four rows the working tree, the index, HEAD, the refs and the Git configuration are unchanged.

Which helper answers? `credential.helper` is a list. Git asks each helper in order and stops at the first that returns a username and a password. An empty value resets the list, which is how a later configuration file discards helpers set by an earlier one. `credential.<URL>.helper` and `credential.<URL>.username` apply only to matching URLs, and `credential.useHttpPath` makes the repository path part of the lookup. By default a credential is per host, not per repository.

**[ON SCREEN]** The helpers on a Mac.

`osxkeychain` ships with Git on macOS and keeps the secret in the login keychain. It stores whatever you typed. The GitHub CLI configures itself as a helper for `https://github.com`, and keeps its token in the system credential store, or in a plain text file if none is available. Git Credential Manager, value `manager`, obtains tokens through the browser and is installed separately. `store` writes a plain text file. The manual calls it discouraged, so don't use it. `cache` keeps the secret in the memory of a background process and isn't used in this course, because it starts a daemon.

Inside `.git`: nothing. A credential is never stored in the repository unless you put it there. The helper list is configuration, usually at system or global scope.

**[ANIMATION]** sandbox: steps=room,inside,outside real=the_system_configuration,the_osxkeychain_helper inside=system_configuration:_off,no_credential_helper title=Why_GitHub_labs_run_in_your_normal_shell

And that explains a rule of this course: `labs/shell` and the replays switch off the system configuration, where macOS installations of Git usually configure `osxkeychain`. That's why the labs that contact GitHub run in your normal shell. In the lab, Git finds no helper. In your normal shell, it finds whichever one is configured.

## MENTAL MODEL

Two analogies from the textbook.

**[ANIMATION]** step: two.2

For the distinction: a badge reader and a door list. The reader checks that the badge is real and whose it is. The list on each door says which badge holders may enter. The analogy breaks because GitHub often gives the same answer to both failures: an unknown badge and a known badge without access can both get "there is no such door". The error text alone doesn't tell you which check failed.

**[ANIMATION]** step: ask.7

For the protocol: a receptionist with a key cabinet. Asked for a key, the receptionist looks in the cabinet: `get`. If the visitor had to bring their own key and it opened the door, it's hung in the cabinet: `store`. If a key from the cabinet didn't open the door, it's thrown away: `erase`. The analogy breaks at the last step: the receptionist throws a key away only when the door says "wrong key", 401, not when it says "you may not enter", 403.

**[ANIMATION]** step: wed.6

That break is the hook. It's Ravi's Wednesday.

## DIAGRAM

**[DIAGRAM]** A sequence, top to bottom. Three columns: Git, the helper, the server.

```text
   Git                              credential helper                 server (GitHub)
    |                                                                    |
    |------------------- request without a credential ------------------>|
    |<------------------ 401: authentication required -------------------|
    |                                                                    |
    |-- get (protocol, host) ----------->|                               |
    |<-- username, password (a token) ---|      (none stored: Git prompts, or fails where
    |                                    |       prompts are disabled)   |
    |------------------- request with the credential ------------------->|
    |                                                                    |
    |   200  -> store  ------------------>|   kept for next time         |
    |   401  -> erase  ------------------>|   removed; Git asks again next time
    |   403 / 404 -> (nothing)            |   the helper's store is unchanged
```

Git sends a request, and the server demands authentication. Git asks the helper: `get`, with the protocol and the host. The helper answers with a username and a password, which for GitHub is a token. Git repeats the request with it.

Then three outcomes. Accepted: Git tells the helper `store`. A 401, wrong credential: Git tells the helper `erase`, and next time it will ask again. A 403 or a 404: Git tells the helper nothing. The wrong account stays in the cabinet and answers every later request.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch16/credential-protocol
```

No helper is configured in the sandbox, and the lab forbids terminal prompts, as a CI job, an automated build, does.

```bash
git config get --show-origin --all credential.helper
printf 'protocol=https\nhost=github.com\n\n' | git credential fill
```

<!-- snippet: ch16/credential-protocol/01-no-helper -->
```text
$ git config get --show-origin --all credential.helper
[exit status: 1]
$ printf 'protocol=https\nhost=github.com\n\n' | git credential fill
fatal: could not read Username for 'https://github.com': terminal prompts disabled
[exit status: 128]
```
<!-- /snippet -->

"Could not read Username ... terminal prompts disabled". This is the error of every CI job that reaches a private repository without a credential.

```bash
printf 'protocol=https\nhost=github.com\n\n' | GIT_ASKPASS=~/lab-bin/askpass git credential fill
```

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

A stand-in for the person at the keyboard shows what Git would ask: two prompts, a username and a "password".

<!-- snippet: ch16/credential-protocol/03-helper-source -->
```text
$ cat ~/lab-bin/git-credential-labstore
#!/bin/sh
# git-credential-labstore: a toy credential helper for the lab. Do not use it for real secrets.
# Git runs it as "git credential-labstore <operation>" and writes key=value lines on its stdin.
store="$HOME/.labstore-credentials"
input=$(cat)
printf '%s %-5s <- %s\n' "labstore" "$1" "$(printf '%s' "$input" | sed 's/^password=.*/password=<hidden>/' | tr '\n' ' ')" >> "$HOME/helper.log"
case "$1" in
  get)   [ -f "$store" ] && cat "$store" ;;
  store) printf '%s\n' "$input" | grep -E '^(username|password)=' > "$store" ;;
  erase) rm -f "$store" ;;
esac
exit 0
```
<!-- /snippet -->

The lab's helper, a short shell script. Read its `case` statement: `get` prints what is stored, `store` writes it, `erase` deletes it. It also logs every call with the password hidden. Do not use it for real secrets.

```bash
git config set --global credential.helper labstore
git config get --show-scope --all credential.helper
printf 'protocol=https\nhost=github.com\n\n' | git credential fill
cat ~/helper.log
```

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

Git asked the helper, `get`. The helper had nothing. So Git fell through to the prompt that the lab forbids.

```bash
printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=FAKE-TOKEN-not-a-real-credential\n\n' | git credential approve
cat ~/.labstore-credentials
```

<!-- snippet: ch16/credential-protocol/05-approve -->
```text
# What Git does after a server accepted a credential that you typed:
$ printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=FAKE-TOKEN-not-a-real-credential\n\n' | git credential approve
$ cat ~/.labstore-credentials
username=lab-user
password=FAKE-TOKEN-not-a-real-credential
```
<!-- /snippet -->

What Git does after a server accepted a credential that you typed: `approve`, and the helper stores it.

```bash
printf 'protocol=https\nhost=github.com\n\n' | git credential fill
printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
```

The second request names a repository path. Will the answer be specific to that repository? Say it out loud. I'll wait.

**[PAUSE]**

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

The same credential. The path was dropped: by default a credential is per host.

```bash
printf 'protocol=https\nhost=github.com\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o 'trace: run_command.*'
```

<!-- snippet: ch16/credential-protocol/07-trace -->
```text
$ printf 'protocol=https\nhost=github.com\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o 'trace: run_command.*'
trace: run_command: 'git credential-labstore get'
trace: run_command: git-credential-labstore get
```
<!-- /snippet -->

`GIT_TRACE=1` names the program that answered. This line is the evidence for the second of the three questions.

```bash
printf 'protocol=https\nhost=github.com\nusername=lab-user\npassword=FAKE-TOKEN-not-a-real-credential\n\n' | git credential reject
cat ~/.labstore-credentials
```

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

What Git does after a 401: `reject`, and the stored credential is gone.

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

**[ANIMATION]** step: ask.7

The log is the protocol: `get` before a request, `store` after success, `erase` after a rejected credential.

**[TERMINAL]** Which helper answers.

```bash
labs/run ch16/credential-scope
```

```bash
git config set --global credential.helper labstore
git config set --global --append credential.helper workstore
printf 'protocol=https\nhost=github.com\n\n' | git credential fill
cat ~/helper.log
```

Two helpers, two stored accounts. Which account answers, and is the second helper asked at all? Make your prediction.

**[PAUSE]**

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

The first helper answered and the second was never asked. Order is the whole rule.

```bash
git config set --global --append credential.https://github.com.helper ''
git config set --global --append credential.https://github.com.helper workstore
```

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

An empty value resets the list for that host, and what follows it replaces every helper configured before. Now `github.com` gets the work account and another host still gets the personal one.

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

The same reset for a single command, with `-c`: no stored credential is read, changed or erased.

```bash
git config set --global credential.https://github.com.username work-user
git config set --global credential.https://github.com.useHttpPath true
printf 'url=https://github.com/acme-pay/billing-api.git\n\n' | git credential fill
```

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

With `useHttpPath`, the helper receives `path=`, so it can keep one credential per repository. With a fixed `username`, it is asked for that account.

**[ON SCREEN]** GitHub walkthrough, Lab 20.2 Part B, in the normal shell and not in `labs/shell`. The interface changes; the lab text and the documentation are the reference. No output is shown, and the screen recording stops before any command that could print a secret.

```bash
gh auth status
git config get --show-origin --all credential.helper
git config get --show-origin --all credential.https://github.com.helper
```

According to its help text, `gh auth status` prints, per host, the active account, where its token is stored and the token's scopes, with the token masked. The two `git config` commands tell you which helpers are configured and in which file. If the second prints nothing, `gh auth setup-git` configures the GitHub CLI as the helper for `github.com`. The textbook read what it writes from the CLI's source and did not run it: first an empty value, to cut off helpers configured elsewhere, then the `gh auth git-credential` helper. It is the reset-then-add pattern you saw a minute ago.

Try it now, thirty seconds, in your normal shell, not the lab shell. Run the first `git config` line and read two things: which helper, and which file names it. I'll wait.

**[PAUSE]**

Whatever it printed, you now know which program answers for you.

```bash
cd ~/git-mastery/practice-repo
git remote get-url origin
GIT_TRACE=1 git push --dry-run origin main 2>&1 | grep -o 'run_command.*'
printf 'protocol=https\nhost=github.com\n\n' | git credential fill | sed 's/^password=.*/password=<hidden>/'
```

The dry-run push sends nothing and shows which program Git runs when a credential is needed. The last command shows which account answers. The `sed` hides the secret before it reaches your screen. Never run it without the `sed` while sharing a screen.

## COMMON MISTAKES

Five mistakes to watch for.

1. Granting access and expecting a failing push to start working. Root cause: a stored credential for another account answers, and a 403 does not erase it.
2. Typing the account password at Git's "Password" prompt. Root cause: GitHub accepts only a token there, since 13 August 2021.
3. Treating the author in `git log` as the person who pushed. Root cause: the commit identity is an unchecked assertion; the authentication identity is separate.
4. Adding a helper and seeing the old account still answer. Root cause: Git stops at the first helper that returns a credential; reset the list for the host with an empty value.
5. Running a GitHub command inside `labs/shell` and getting "could not read Username". Root cause: the lab shell switches off the system configuration, where the helper is configured.

## PRODUCTION EXAMPLE

**[ANIMATION]** walk: id=ravi columns=question,evidence,Wednesday rows=Which_transport_and_server?:git_remote_-v:HTTPS_on_github.com|Which_credential?:GIT__TRACE=1,_gh_auth_status:his_personal_account|Who,_and_what_may_it_do?:the_server:a_valid_account_without_permission,_403 marks=1.3:ok,2.3:bad,3.3:hl mono=off pick=2 title=Three_questions,_in_this_order at_1=16 at_2=35 at_3=80

**[ANIMATION]** step: 3

Now, out of the lab. Ravi's Wednesday, worked through the three questions. Transport and server: `git remote -v` shows an HTTPS URL on `github.com`. Fine. Which credential does the client present? `GIT_TRACE=1` on a dry-run push names the helper, and `gh auth status` names the account. It's his personal account: he once cloned a personal project over HTTPS, and the keychain stored it. Who does the server say he is? A valid account without permission: 403.

**[ANIMATION]** step: pick

So the failure is in the second question, and the fix is there too: make the right account answer for that host, by resetting the helper list for `github.com` or deleting the keychain entry. Nothing on GitHub needed to change after Monday. The prevention, from the chapter's table: one helper per host, set on purpose.

## PRACTICE EXERCISE

Your turn. Do Lab 20.2, "HTTPS through the GitHub CLI, and the helper behind it", in [`lab-manual/m20-authentication-ssh.md`](../../lab-manual/m20-authentication-ssh.md). Part A runs in the lab shell with the toy helpers, and Part B runs in your normal shell. Before each `git credential fill`, predict whether it will print a credential or fail, and what line the helper log will gain. In Part B, predict which file configures your helper before you ask.

The challenge is Exercise 20.3, "403, and Git never asks", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 244 of the CTO question bank:

> "Describe what Git does, step by step, from "the server answers 401" to "the token is stored", naming the helper operations. What happens differently on a 403, and what is the consequence?"

**[PAUSE]**

**[ANIMATION]** step: ask.7

Answer out loud. A strong answer walks the sequence in order and uses the three operation names correctly. It says where the prompt fits in when no helper answers. For the 403 it states precisely what Git doesn't do, and derives the symptom that a user sees days later. It ends with the evidence you would collect and the fix.

## RECAP

Let's land this.

You should now be able to say:

- Authentication is which account; authorization is what that account may do; the error text can be the same for both.
- Over HTTPS the secret is a token, and Git obtains it from a list of credential helpers, asked in order.
- Git calls `get` before a request, `store` after success and `erase` after a 401; after a 403 or 404 it changes nothing.
- `GIT_TRACE=1` shows which helper ran; `gh auth status` shows which account.
- A helper can be scoped to a host, a username or a path, and an empty value resets the list.

## HOMEWORK

Read sections 16.1 to 16.5 of [Chapter 16](../../textbook/ch16-authentication.md). Do Exercise 20.1, "Who wrote this line?", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

**[ANIMATION]** step: ask.7

Today you followed a credential from the server's 401 into the store, and you solved Ravi's Wednesday with three questions. If the three operation names still blur, replay the log once more. Next time: tokens, what a prefix tells you, and why a token never goes into a URL. Until then, look at the state first and type second. See you in the next one.
