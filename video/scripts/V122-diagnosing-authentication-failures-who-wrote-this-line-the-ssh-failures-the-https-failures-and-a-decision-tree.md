# V122: Diagnosing authentication failures: who wrote this line, the SSH failures, the HTTPS failures, and a decision tree

- **Part.** 5: GitHub
- **Module.** 20
- **Planned minutes.** 24
- **Prerequisites.** V119, V121
- **Textbook sections.** [Chapter 16](../../textbook/ch16-authentication.md), sections 16.17 to 16.20 (with 16.21 to 16.23)
- **Demo scripts.** `labs/ch16/failure-anatomy.sh`, `labs/ch16/lab-20-3-failures.sh`; GitHub-side walkthrough of Lab 20.3

## HOOK

**[ON SCREEN]** Left: a terminal, `remote: Repository not found.` Right: a browser showing the repository.

The deploy job, the automated run that ships your code, says "Repository not found". Your CTO turns the laptop around: "I am looking at the repository in my browser. Which of the two is wrong?"

Neither is wrong. The job's credential, its proof of identity, can't see the repository, and GitHub answers "not found" on purpose. The browser is signed in as a different identity.

A ticket for this incident usually quotes one line: "fatal: Could not read from remote repository." That line never contains the cause. Today you learn to read the whole stack of lines, to say which program wrote each, and to walk from the text to the root cause without guessing. Keep the CTO's laptop in mind. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video closes the authentication module. Authentication establishes which account a connection belongs to. Authorization, a separate step, decides what that account may do. Four videos gave you the mechanisms: the three questions, the credential helper protocol, tokens, SSH with its configuration and host keys, and identities for people and machines. Now we use all of it in one direction: from an error message backwards.

The method has one first step, attribution: which program printed this line? Then two tables, the SSH failures and the HTTPS failures, one for each transport, each way Git reaches GitHub. And a decision tree that puts them in order.

**[ANIMATION]** sandbox: steps=room,inside,outside name=The_offline_replays inside=local_stand-ins,no_network,no_SSH_agent real=your_keys,your_known__hosts_file,your_stored_credentials title=Failures_on_purpose,_safely

The replays reproduce the failures inside the lab, against local stand-ins, with no network: `labs/ch16/failure-anatomy.sh` and the replay of Lab 20.3. Your real setup stays outside. Then the walkthrough of Lab 20.3, Part B, in the normal shell, which reproduces three failures against your own practice repository without changing your working setup.

**[ANIMATION]** end

The diagnostic commands in this video are 🟢 SAFE: `git remote -v`, `ssh -G`, `ssh-add -l`, `ssh -T`, `gh auth status`. One reminder from the chapter's table: `gh auth token` and `gh auth status --show-token` are 🔴 DANGEROUS, because they print a live token, the string that stands for your account, to the terminal and its scrollback. They are not part of any diagnosis here.

## LEARNING OBJECTIVES

After this video you can:

- Say for an error line whether Git, SSH, the helper or GitHub wrote it.
- Tell `Permission denied (publickey)` from `Permission to OWNER/REPO denied to USER` and say what has been proved in each case.
- Diagnose `Repository not found`, `Host key verification failed`, and `Could not read from remote repository`.
- Diagnose a 403 where Git never asks for a credential.
- Walk the decision tree from the error text to the root cause.

## CONCEPT

An authentication error on your screen is a short stack of lines written by different programs. Reading it starts with attributing each line.

**[ON SCREEN]** The attribution table of section 16.17.

Lines that begin with `ssh:` are written by your `ssh` client, the program that opens the connection. So are `Permission denied (publickey)`, "Host key verification failed." and the warning that the remote host identification has changed. They mean the SSH connection or authentication failed before Git's protocol started.

Lines that begin with `remote:` over HTTPS are written by GitHub's server and passed through. Over SSH, so are lines such as the SSH key audit error. The server knows something and tells you: repository not found, permission denied to a named user, a rule.

"fatal: Could not read from remote repository." and the two lines after it are written by Git. They mean the other side closed the connection. This line never contains the cause.

"fatal: Authentication failed for", "fatal: repository ... not found" and "The requested URL returned error" with a number are written by Git's HTTPS code, for the HTTP statuses 401, 404, or another status.

And "fatal: could not read Username for" is written by Git: no helper answered and prompting was impossible. A helper is the program that stores your username and token.

**[ANIMATION]** cards: id=quiz question=Permission_denied_(publickey):_what_has_the_server_done? cards=A,_refused_your_account_this_repository|B,_matched_no_account_at_all marks=2:ok

**[ANIMATION]** step: 2

Now the SSH failures. Quick quiz: `Permission denied (publickey)`: has the server, A, refused your account this repository, or B, matched no account at all? Your answer?

**[PAUSE]**

**[ANIMATION]** step: marks

B. `Permission denied (publickey)`: the server rejected the connection.

**[ANIMATION]** flow: id=sshfail actors=your_ssh_client,*authentication,authorization subs=opens_the_connection,which_account?,what_may_it_do? msgs=1>2:the_keys_offered|2>1:Permission_denied_(publickey):fail|2>3:a_key_matched_an_account:ok|3>1:Permission_to_OWNER/REPO_denied_to_USER:fail|3>1:Repository_not_found:fail|1>1:Host_key_verification_failed.:fail|1>1:connect_error_on_port_22:fail zones=your_machine,the_server boundary=1 at_1=4 at_2=22 at_4=25 title=The_SSH_failures:_who_refuses,_and_where

**[ANIMATION]** step: 2

None of the keys offered, the key pairs that prove who you are, belongs to an account, or no key was offered, or the user is not `git`. Almost everyone picks A at first, so say it precisely. It does not mean "you lack permission on the repository". The server hasn't looked at the repository yet. It means the server could not attach your connection to any account. Nothing has been proved about who you are.

**[ANIMATION]** step: 4

`Permission to OWNER/REPO denied to USER`: the server again, and now something has been proved. The key authenticated as an account that has no access here, or as a deploy key of another repository. A deploy key is an SSH key attached to one repository, not to a person. The message names who you are. Authentication succeeded. Authorization failed.

**[ANIMATION]** step: 5

"Repository not found" over SSH is the same deliberate answer as over HTTPS. `ssh -T git@github.com` names the account.

**[ANIMATION]** step: 6

"Host key verification failed." comes from your client. The server's host key, its proof of who it is, differs from the one `ssh` remembers in `known_hosts`. If no announcement explains it, do not connect.

**[ANIMATION]** step: 7

A connect error on port 22, refused or timed out, is your client reporting the network. Try port 443.

**[ANIMATION]** flow: id=httpsfail actors=Git,credential_helper,*the_server subs=its_HTTPS_code,stores_username_and_token,GitHub msgs=1>2:get|2>1:username_+_token|1>3:the_request_with_the_credential|3>1:404_Repository_not_found:fail|3>1:401_Authentication_failed:fail|1>2:erase|3>1:403_knows_who_you_are,_refuses:fail|1>1:no_erase_(from_Git's_source) boundary=2 zones=your_machine,the_network at_8=55 title=The_HTTPS_failures:_three_answers_to_one_request

**[ANIMATION]** step: actors

Now the HTTPS failures.

**[ANIMATION]** step: 4

"Repository not found" in a `remote:` line, then Git's "not found": the server answers 404 when the repository doesn't exist, or when the credential has no access to it.

**[ANIMATION]** step: 6

"Authentication failed" is a 401. The credential was rejected outright: a revoked or expired token, a password, a typo. Git then tells the helper to erase it.

**[ANIMATION]** step: 8

"The requested URL returned error: 403": the server knows who you are and refuses. No write permission, a classic token without the needed scope or without single sign-on authorization, an organization policy, or a rate limit. Git does not erase the credential. So this is the 403 where Git never asks: a stored credential for another account answers every time.

**[ANIMATION]** end

"Could not read Username ... terminal prompts disabled": no helper answered, and there is no terminal: CI, cron, the lab shell.

And "uses plaintext credentials": the setting from the tokens video.

One caveat the textbook marks unverified: no GitHub documentation page explains HTTP 403 on `git push` specifically. The list of causes combines the cloning-errors page, the token documentation and the REST guide. And the statement that Git keeps the credential after a 403 is from Git's source, and was not observed against GitHub in the course.

Why does GitHub answer "not found" for something that exists? In the words of its REST troubleshooting guide: "To avoid confirming the existence of private repositories". A 403 would tell a stranger that the name is taken.

## MENTAL MODEL

**[ANIMATION]** flow: id=relay actors=your_client,*the_front_door,the_repository_rules subs=ssh_or_Git's_HTTP_code,decides_who_you_are,decides_what_you_may_do msgs=1>1:a_refusal_in_its_own_voice:fail|2>1:a_refusal_in_its_own_voice:fail|3>1:a_refusal_in_its_own_voice:fail|2>1:"not_found":fail|3>1:"not_found":fail|1>2:ssh_-T_or_gh_auth_status|2>1:who_it_thinks_you_are:ok title=A_relay_of_three_messengers

**[ANIMATION]** step: 3

A picture helps. Think of a relay of three messengers between you and the repository. Your client program, `ssh` or Git's HTTP code. The server's front door, which decides who you are. And the server's repository rules, which decide what you may do. Each messenger can come back with a refusal, and each speaks in its own voice.

**[ANIMATION]** say: The last line is Git reporting an empty-handed messenger: read upwards

The last line on your screen is usually Git reporting that a messenger came back empty-handed. That's why you read upwards.

**[ANIMATION]** step: 7

The model breaks in one place, on purpose: the front door and the repository rules sometimes give the same answer, "not found", so that a stranger learns nothing. When you see that answer, you don't try to guess which of the two refused. You ask the front door directly who it thinks you are: `ssh -T`, or `gh auth status`.

**[ANIMATION]** end

## DIAGRAM

**[DIAGRAM]** The decision tree of section 16.20. Build it in three passes: the root, the SSH branch, the HTTPS branch.

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

The root is the first of the three questions: which transport? `git remote get-url origin` answers it.

Try it now, thirty seconds: run it in any repository of yours. SSH or HTTPS? I'll wait.

**[PAUSE]**

Starting with git and an at sign, or with ssh: SSH. Starting with https: HTTPS.

**[ANIMATION]** gates: id=sshbranch packet=an_SSH_connection gates=network:pass:-:if_not:_an_ssh:_line|host_key:pass:-:if_not:_Host_key_verification_failed|your_identity:pass:-:if_not:_Permission_denied_(publickey)|authorization:pass:-:if_not:_denied_to_USER,_or_not_found zones=your_client,the_server split=2 title=The_SSH_branch,_outside_in

The SSH branch goes outside in. Network first: is there an `ssh:` line? Then the server's identity: the host key. Then your identity: `Permission denied (publickey)` means no account matched, and three commands show why. Then authorization: a named user, or "not found", means you were authenticated as someone. `ssh -T` tells you as whom.

**[ANIMATION]** gates: id=httpsbranch packet=an_HTTPS_request gates=a_credential_at_all:pass:-:if_not:_could_not_read_Username|the_credential_accepted:pass:-:if_not:_Authentication_failed_(401)|allowed:pass:-:if_not:_not_found_(404)_or_403 title=The_HTTPS_branch,_the_same_order

The HTTPS branch has the same order. No credential at all. A rejected credential, 401. Then 404 or 403: authenticated, or anonymous, and not allowed. Two commands: which helper answered, and which account.

**[ANIMATION]** end

And the last line, for both: does the same identity work in the browser, or with `gh repo view`? That's the CTO's laptop from the hook, used correctly.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch16/failure-anatomy
```

```bash
ssh-add -l
```

<!-- snippet: ch16/failure-anatomy/01-no-ssh-agent -->
```text
$ ssh-add -l
Could not open a connection to your authentication agent.
[exit status: 2]
```
<!-- /snippet -->

Exit status 2: no agent can be reached. The agent is a background process that holds your decrypted keys. The replays run without one. On your machine you meet this under `sudo`, in `cron` and in containers.

Nothing listens on port 1 of this machine, so the next failure is a real `ssh` error without any network.

```bash
ssh -T -F ~/.ssh/config-offline -p 1 git@127.0.0.1
GIT_SSH_COMMAND='ssh -F ~/.ssh/config-offline' git ls-remote ssh://git@127.0.0.1:1/acme-pay/billing-api.git
```

**[PAUSE]** The same failing connection, once alone and once under Git. Which lines will the second output add, and who writes them?

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

Alone, `ssh` reports the cause in one line. Under Git, the same line is followed by Git's three-line trailer. The cause is the line above the trailer.

```bash
GIT_SSH_COMMAND=~/lab-bin/fake-ssh git ls-remote git@github.com:acme-pay/billing-api.git
```

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

A stand-in for `ssh` that prints its arguments and exits. The same trailer.

```bash
GIT_SSH_COMMAND=~/lab-bin/silent-ssh git ls-remote git@github.com:acme-pay/billing-api.git
```

**[PAUSE]** This stand-in exits with status 255 and prints nothing. What is left on the screen?

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

Only the trailer. When `ssh` is silent, there is no line above.

```bash
git ls-remote ~/no-such-repository.git
```

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

A local path that does not exist: Git's own check writes the cause, and then the same trailer.

<!-- snippet: ch16/failure-anatomy/06-no-program -->
```text
$ GIT_SSH_COMMAND=~/lab-bin/no-such-ssh git ls-remote git@github.com:acme-pay/billing-api.git
fatal: cannot exec '$LAB/ch16/failure-anatomy/home/lab-bin/no-such-ssh': No such file or directory
fatal: cannot exec '$LAB/ch16/failure-anatomy/home/lab-bin/no-such-ssh': No such file or directory
fatal: unable to fork
[exit status: 128]
```
<!-- /snippet -->

And a configured `ssh` program that does not exist: "cannot exec". No trailer this time: Git could not start anything.

**[ON SCREEN]** The root-cause box of section 16.17.

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

**[TERMINAL]** The lab replay collects evidence for each failure without a network.

```bash
labs/run ch16/lab-20-3-failures
```

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

A wrong user in the URL. The stand-in shows that Git hands `lab-user@github.com` to `ssh`, and `ssh -G` confirms the user. On GitHub that is `Permission denied (publickey)`, because all connections must be made as `git`.

<!-- snippet: ch16/lab-20-3-failures/04-no-key-offered -->
```text
$ ssh -T -F none -o IdentityAgent=none -o IdentityFile=none -G git@github.com | grep -E '^(user|hostname|identityagent|identityfile) '
user git
hostname github.com
identityagent none
identityfile none
```
<!-- /snippet -->

A command line that offers no key at all: no agent, no identity file. `-G` shows it without connecting. This is the form Part B uses against GitHub.

**[ON SCREEN]** The root-cause box of section 16.19.

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

**[ON SCREEN]** GitHub walkthrough, Lab 20.3 Part B, in the normal shell. None of these commands changes your configuration, your keys, your `known_hosts` or your stored credentials. No output is shown; the documentation pages the lab links describe what GitHub answers.

Failure 1: no key is offered.

```bash
ssh -T -F none -o IdentityAgent=none -o IdentityFile=none git@github.com
echo "exit status: $?"
GIT_SSH_COMMAND='ssh -F none -o IdentityAgent=none -o IdentityFile=none' git ls-remote git@github.com:YOUR-ORG/practice-repo.git
```

Before you run it, predict both outputs and what they prove about you. Say it out loud. I'll wait.

**[PAUSE]**

The first is `ssh` alone. The second adds Git's trailer. Proved about your identity: nothing.

Failure 2: a stale host key, in a scratch `known_hosts` file. Run this from the course folder.

```bash
mkdir -p ~/git-mastery/scratch-hostkey
printf 'github.com %s\n' "$(cut -d' ' -f1,2 labs/ch16/stale-host-key.pub)" > ~/git-mastery/scratch-hostkey/known_hosts
ssh -T -o UserKnownHostsFile="$HOME/git-mastery/scratch-hostkey/known_hosts" -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=yes git@github.com
echo "exit status: $?"
```

Your real `known_hosts` is not touched: the command names a scratch file. Predict who writes the message: your client. That's the check working.

Failure 3: a wrong credential for a repository that does not exist, then the right credential.

```bash
git -c credential.helper= -c credential.https://github.com.helper= \
    -c credential.helper='!f() { test "$1" = get && printf "username=YOUR-USER\npassword=not-a-token\n"; }; f' \
    ls-remote https://github.com/YOUR-ORG/no-such-repo.git
git ls-remote https://github.com/YOUR-ORG/no-such-repo.git
gh repo view YOUR-ORG/no-such-repo
```

The first command uses the one-command reset from video 118, so your stored credential is neither read nor erased. Predict the status for each: a rejected credential, then a valid credential for a name that does not exist. Compare the two messages and decide which of them tells you anything about the repository.

## COMMON MISTAKES

Five mistakes to watch for.

1. Quoting only "Could not read from remote repository" in a ticket. Root cause: Git writes that line when the other program exits; the cause is in the line above it.
2. Reading `Permission denied (publickey)` as missing repository access. Root cause: the server could not attach the connection to any account; it has not looked at the repository.
3. Concluding from "Repository not found" that the URL is wrong. Root cause: the server gives the same answer when the credential has no access, to avoid confirming that private repositories exist.
4. Re-entering credentials after a 403. Root cause: Git does not erase a stored credential on 403, so the same wrong account answers again without a prompt.
5. Changing SSH settings to fix an HTTPS remote, or the reverse. Root cause: the first question, which transport, was skipped.

## PRODUCTION EXAMPLE

**[ANIMATION]** decide: id=tree nodes=q1:Which_transport?|s:the_SSH_branch|h2:could_not_read_Username?|a2:no_helper,_no_terminal|h3:Authentication_failed_(401)?|a3:credential_rejected|h4:not_found_(404)_or_403?|a4:which_helper?_which_account? edges=q1>s:ssh|q1>h2:https|h2>a2:yes|h2>h3:no|h3>a3:yes|h3>h4:no|h4>a4:yes path=q1,h2,h3,h4,a4 title=The_deploy_job,_walked_down_the_tree

Now, out of the lab. The deploy job from the hook, walked down the tree. Step 1: `git remote get-url origin` in the job's checkout prints an HTTPS URL. HTTPS branch. The full error has a `remote:` line, "Repository not found", then Git's "not found": a 404. Step 4h: which helper answered, and which account? The trace shows the helper. The job's token turns out to be a fine-grained token, the kind that can be limited to selected repositories, created for another repository of the same organization. The repository in question is not in its selection. The server authenticated the token and answered as if the repository did not exist.

The CTO's browser was right too: his account can see it. The last line of the tree would have caught the difference at once: the job's identity does not work with `gh repo view`, and his does.

**[ANIMATION]** end

The fix is in the token's repository selection, or better, an app installation that includes the repository. The team's prevention is the one in the box: one identity per host or alias, chosen by configuration and not by habit. And a rule for tickets: quote the whole error.

## PRACTICE EXERCISE

Your turn. Do Lab 20.3, "Three failures, reproduced and diagnosed", in [`lab-manual/m20-authentication-ssh.md`](../../lab-manual/m20-authentication-ssh.md). For each failure, before you produce it, write down three things: the exact error text you expect, which program will write each line, and what will have been proved about your identity when you see it.

The challenge is Exercise 20.6, "Three faults, no connection", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 232 of the CTO question bank:

> "What is the difference between `Permission denied (publickey)` and `Permission to OWNER/REPO denied to USER`? What has the server established in each case?"

**[PAUSE]**

Answer out loud. A strong answer says for each message which check failed, authentication or authorization, and therefore what the server knows about you at that moment. It names the commands that produce the evidence in each case and the different fixes that follow. It does not use the word "permission" for the first message without correcting it.

## RECAP

Let's land this.

You should now be able to say:

- Attribute every line first: `ssh:` lines are the client, `remote:` lines are the server, and Git's trailer never contains the cause.
- `Permission denied (publickey)` means no account matched; a message naming a user means you were authenticated and not authorized.
- "Repository not found" is also what a credential without access receives.
- A 401 erases the stored credential; a 403 does not, so Git keeps sending the wrong account without asking.
- The decision tree starts with the transport and ends with one question: does the same identity work elsewhere?

## HOMEWORK

Read sections 16.17 to 16.23 of [Chapter 16](../../textbook/ch16-authentication.md) and do the Practice section 16.25.

You can now name the program behind every error line. Practise with Lab 20.3. Next: what GitHub creates when a pull request opens. Until then, look at the state first and type second. See you in the next one.
