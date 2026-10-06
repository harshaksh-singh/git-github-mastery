# Solutions, Modules 19 to 25: GitHub

> **Baseline.** Git 2.55.0, OpenSSH 10.2 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Every transcript is real output of a script in `labs/ex3/`; in transcripts `$LAB` stands for the lab root. Nothing was run against GitHub. Every statement about what GitHub does is taken from the textbook section cited beside it, which carries the link to GitHub's documentation. Where the textbook marks a point as unverified or as an inference, this file says so too.

Questions are in [the exercise file](../exercises/m19-m25-github.md). Each solution has four parts: the solution, the reasoning, the common mistakes, and the expert approach.

---

## Module 19

### Solution 19.1: Git data or GitHub object?

**Solution.**

| # | Item | Layer | Read it with | Arrives with `git clone`? |
|---|---|---|---|---|
| 1 | Annotated tag `v1.2.0` | Git: a tag object and a ref | `git cat-file -p v1.2.0` | yes |
| 2 | Release notes | GitHub object that points at a tag name | `gh release view v1.2.0` | no; only the tag |
| 3 | `.github/CODEOWNERS` | Git data that GitHub interprets | `git show main:.github/CODEOWNERS` | yes |
| 4 | Approving review | GitHub object | `gh pr view 7 --json reviews` | no |
| 5 | `refs/pull/7/head` | a Git ref that GitHub creates on the server, read-only | `git ls-remote origin 'refs/pull/*'` | no: outside the default refspec |
| 6 | Default branch setting | GitHub object | `gh repo view --json defaultBranchRef` | no; the clone sees only its effect, the branch it checks out |
| 7 | `Fixes #41` | text in a commit object that GitHub interprets | `git log --grep='Fixes #41'` | yes, with the commit |
| 8 | Star | GitHub object | `gh repo view --json stargazerCount` | no |
| 9 | Actions secret | GitHub object | `gh secret list` (names only) | no |
| 10 | Wiki | Git, in a second repository `OWNER/REPO.wiki.git` | `git clone` of that URL | no: a separate clone |
| 11 | Ruleset | GitHub object | `gh ruleset list`, `gh ruleset view` | no |
| 12 | Deploy key | GitHub object | `gh repo deploy-key list` | no |

A mirror takes refs and objects: items 1, 3, 5 and 7. The pull request ref arrives as a bare ref with no pull request behind it. Items 2, 4, 6, 8, 9, 11 and 12 stay behind and must be exported through the API or re-created by hand; secrets have to be entered again from wherever they are kept. The wiki is a second repository and needs its own mirror.

**Reasoning.** The test is the one in Chapter 15, section 15.2: does it live in refs and objects, which travel with `clone`, `fetch` and `push`, or in GitHub's database, which only the web interface, `gh` and the API reach? Files under `.github/` and closing keywords are the third case: Git data that the platform reads.

**Common mistakes.** Calling a release "a tag with notes": they are two objects made by two programs (section 15.12). Calling `refs/pull/7/head` a GitHub object: it is a real ref and can be fetched by name. Assuming a wiki is part of the repository because it has a tab there.

**Expert approach.** Before a migration, write the inventory as a table like this one and attach one command to every row, so that each classification is proved and not remembered. Lab 19.2 builds that inventory. Reference: Chapter 15, sections 15.2, 15.10 and 15.12.

### Solution 19.2: Settings on purpose

**Solution.** Each `gh repo edit` changes a repository setting in GitHub's database. Nothing in your clone changes: no object, no ref, no line of `.git/config`. After the third edit the merge box offers squash merging only. The default branch is in the JSON field `defaultBranchRef`; the three merge settings are `mergeCommitAllowed`, `squashMergeAllowed` and `rebaseMergeAllowed`, and the others you set are `deleteBranchOnMerge` and `hasWikiEnabled` (`gh repo view --help`, JSON FIELDS).

A teammate whose pull request merged still has two refs of their own: the remote-tracking branch, removed by `git fetch --prune`, and the local branch, removed by `git branch -d` or, after a squash merge, `-D` once they have verified that nothing is lost (Chapter 17, section 17.9). A `git push --mirror` to another host carries none of these settings.

**Reasoning.** Settings are GitHub objects (Chapter 15, section 15.5): "none of them is in a clone, and none of them is restored by pushing a mirror". Automatic deletion of head branches deletes a ref on the server; the same section's production note counts "one setting, three kinds of ref, three owners".

**Common mistakes.** Expecting `git status` or `git remote show origin` to reveal a setting. Disabling merge commits without telling the team, which changes what `git branch -d` says after every merge. Running `gh repo edit` in a clone with two remotes without checking `gh repo set-default --view` first.

**Expert approach.** Set these once, on purpose, and record the intended values in `CONTRIBUTING.md` or in infrastructure code, because the only history a setting has is the audit log. The flags used here were checked against `gh repo edit --help` of 2.88.1; the commands were not run by the author. Reference: Chapter 15, sections 15.5 and 15.16.

### Solution 19.3: Effective access

**Solution.**

| | `chunker` | `ranker-service` | `billing-export` |
|---|---|---|---|
| Meera | Write (child team inherits the parent's grant) | Maintain (direct grant beats Triage and Read) | Read (base permission) |
| Jonas | Write | Read (a parent team does not inherit from its child) | Read |
| Tariq | Write | none | none |
| Dana | Admin | Admin | Admin |

2. Everyone with Write or more on `chunker`: Meera, Jonas, Tariq and Dana.
3. Meera and Dana. Jonas can submit a review with Read, but only a review from someone with Write counts toward a requirement.
4. Dana only: managing rulesets is an Admin action.
5. A deploy key whose private half he holds. GitHub's roles page warns that it works "even if they're later removed from the organization". Look with `gh repo deploy-key list` on each repository he worked on, and rotate what such a key could read.
6. Either set the base permission to none and grant every repository through teams, or keep the base permission and make contractors outside collaborators, whom base permissions do not reach. Setting it to none takes away Jonas's Read on `ranker-service` and `billing-export`; his Write on `chunker` stays, because it comes from his team.

**Reasoning.** Effective access is the highest of the base permission, team grants including those inherited from parent teams, direct grants, and admin through ownership; an outside collaborator has direct grants only. Grants only add, and nothing subtracts (Chapter 15, section 15.4). The Phase 0 report marks this combined rule as an inference from several documentation pages, not one sentence GitHub publishes.

**Common mistakes.** Forgetting the base permission, which is the "why can she clone all forty" question. Reading team nesting upwards. Thinking Write is harmless: Write can create Actions secrets and edit workflow files, which is enough to run code with the repository's secrets.

**Expert approach.** Draw the table of section 15.4 for the person in question: one row per source of access, one column per repository, the maximum at the bottom. Then check the credentials that are not membership at all: deploy keys and tokens. Reference: Chapter 15, sections 15.4 and 15.20.

### Solution 19.4: What a clone receives, and where a keyword travels

**Solution.**

<!-- snippet: ex3/x19-keyword-and-refs/02-fresh-clone -->
```text
$ git clone -q server/chunker.git fresh
$ cd fresh
$ git for-each-ref --format="%(refname)"
refs/heads/main
refs/remotes/origin/HEAD
refs/remotes/origin/main
refs/remotes/origin/release/1.2
$ git ls-remote origin
062a65248c02af15ffc71a7cdf6b17fc272d7631	HEAD
062a65248c02af15ffc71a7cdf6b17fc272d7631	refs/heads/main
333e1766e457254787a107a09c5f60d73987abf3	refs/heads/release/1.2
24b1d51faee3370c331b716861c5f00ed03bcc25	refs/pull/7/head
```
<!-- /snippet -->

- a. Four refs: the local `main`, `origin/HEAD`, `origin/main` and `origin/release/1.2`.
- b. Four lines. `refs/pull/7/head` is advertised by the server and is not in the clone: the default refspec fetches `refs/heads/*` only. (`HEAD` is how the clone learned which branch to check out.)

<!-- snippet: ex3/x19-keyword-and-refs/03-keyword -->
```text
$ git log --all --format="%h %s" --grep="Fixes #41"
062a652 Return no chunks for empty text
24b1d51 Return no chunks for empty text
$ git log --format="%h %s" origin/release/1.2 -3
333e176 Merge pull request #7 from fix/empty-doc
24b1d51 Return no chunks for empty text
6258ae5 Add splitter test
$ git log --format="%h %s" origin/main -2
062a652 Return no chunks for empty text
6258ae5 Add splitter test
```
<!-- /snippet -->

- c. Two commits: `24b1d51`, your original, which `release/1.2` reaches through the merge commit `333e176`, and `062a652`, the cherry-picked copy on `main`. Same message, different IDs.

<!-- snippet: ex3/x19-keyword-and-refs/04-pull-ref -->
```text
$ git fetch -q origin pull/7/head:pr-7
$ git log --oneline -1 pr-7
24b1d51 Return no chunks for empty text
$ git branch -a --contains pr-7
  pr-7
  remotes/origin/release/1.2
```
<!-- /snippet -->

- d. `pr-7` and `origin/release/1.2`. Not `main`: the commit on `main` is a copy.
- e. At step 3. Step 1 does not close it: an issue closes at merge time, not when a pull request opens, and keywords in a pull request description are interpreted only when the pull request targets the default branch, so no link was even made. Step 2 does not close it: the base was `release/1.2`. Step 3 does: a commit whose message contains the keyword reached the default branch. The copy made by `git cherry-pick` carries the same words. Step 4 changes nothing for the issue. This is described from the documentation quoted in Chapter 15, section 15.8; it was not observed on GitHub.

**Reasoning.** To Git, `Fixes #41` is text in a commit object, so it travels with every copy of the message. To GitHub, the same text is an instruction with two rules: descriptions count only against the default branch, and commit messages act when the commit arrives there.

**Common mistakes.** Expecting the release-branch pull request to close the issue. Being surprised later that a routine cherry-pick or forward-port closed an issue that somebody had deliberately kept open. Believing that deleting `fix/empty-doc` removed your commit from the server: `refs/pull/7/head` still names it.

**Expert approach.** Teams that ship from release branches decide how issues close and write it into `CONTRIBUTING.md`. When an issue closes unexpectedly, search for the keyword across all refs, as the transcript does, and look at which copy reached the default branch. Reference: Chapter 15, sections 15.2 and 15.8; Chapter 17, section 17.2.

### Solution 19.5: The fork that was deleted

**Solution.**

1. Yes, as far as the documentation tells you. Repositories in a fork network share Git data, and commits pushed to any repository in the network "can be accessible from other repositories in that network, including the upstream repository", "even after a fork is deleted". Anyone who knows the commit ID can ask for it through the URL of `northwind-ml/chunker`. The ID is in a scrollback, and the Phase 0 report found no documented retention period for unreachable commits.
2. The forks reference, quoted in Chapter 15, section 15.7; Chapter 21B, section 21B.10 gives the same rule with the published research on deleted forks.
3. Rotate the password first: that is the only action that makes the leaked value harmless. Then decide whether a removal request to GitHub Support is worth making. Then write the postmortem. Making the repository private is not on the list of useful actions.
4. Making it private erases stars and watchers and detaches public forks, which stay public. It changes no Git object and takes back nothing that was cloned or forked (section 15.5).
5. Push protection, which blocks a recognized secret at push time, and a secret store, so that the password is never in a file that Git can see.

**Reasoning.** A fork has its own refs and shares the object store. Deleting refs, or the fork, changes which names list a commit, not whether the object can be fetched. The chapter's model with Git namespaces shows the same property in plain Git, and the namespaces manual warns that they "are not effective for read access control".

**Common mistakes.** "It was never in our repository" treats a repository as its list of branches. Spending the first hour on removal while the password still works. Believing the exposure window was the hour until deletion: it began at the push and ends at rotation.

**Expert approach.** Ask one question first: is the credential still valid? Everything else is cleanup. Reference: Chapter 15, sections 15.5 and 15.7; Chapter 21B, sections 21B.10 and 21B.14.

### Solution 19.6: Health files and the issue chooser

**Solution.**

1. `.github/CONTRIBUTING.md`. GitHub looks in `.github/`, then the repository root, then `docs/`, and uses the first it finds.
2. The chooser with the bug form and no blank issue. A user with Write still sees the blank issue: `blank_issues_enabled: false` removes it for the Read and Triage roles only.
3. A form is missing when GitHub considers it invalid, or when it is not on the default branch. Here it is the second: issue templates are read from the default branch, and `feature.yml` is on an unmerged branch.
4. GitHub uses the organization's `SECURITY.md`: a public repository named `.github` supplies default health files for every repository of the account that lacks its own. It does not supply a license.

**Reasoning.** Health files are tracked files with well-known names (Chapter 15, section 15.13). GitHub reads them from the default branch, so they take effect at merge time, like CODEOWNERS.

**Common mistakes.** Editing the root file and wondering why nothing changes, because the one in `.github/` wins. Testing a form on a branch. Treating `blank_issues_enabled: false` as a guarantee for every user.

**Expert approach.** Keep one copy of each health file, in `.github/`, delete the others, and review forms like code: only GitHub validates a form, so the first real test is after the merge. Reference: Chapter 15, sections 15.13 and 15.20.

### Solution 19.7: "We made it private, so we are fine"

**Solution.**

1. Whether the key has been revoked at its issuer. At 11:30 it has not. The incident is not contained.
2. Changing a repository from public to private erases its stars and watchers. It is a documented side effect of the 09:25 action, not evidence of compromise.
3. Public forks stay public when their parent becomes private, detached into a network of their own. Their owners still have every commit, including the one with the key. So does everybody who cloned during three weeks.
4. The deploy key is not part of the leak. It is a finding: a credential that outlived the person who created it, which nobody has in an inventory.
5. For example: "A cloud storage key was public in `ranker-service` for three weeks. It is still valid; we are revoking it and issuing a new one within the hour, then reviewing the storage access logs for that period. Making the repository private and deleting the file did not remove the exposure; we will enable push protection and move the key into the secret store."

**Reasoning.** The deletion commit at 09:40 adds a snapshot without the file and leaves the earlier snapshots intact; the visibility change alters who may read through the normal interface. Neither changes whether a copied key works (Chapter 21B, section 21B.10; Chapter 15, section 15.5). The only layer that can end the incident is the issuer of the credential.

**Common mistakes.** Treating "private", "deleted" and "the file is gone" as containment. Chasing the star count. Postponing rotation because "it is no longer reachable", which no one can know after three weeks in public.

**Expert approach.** Revoke first, then assess exposure from the issuer's access logs, then decide whether a history rewrite is worth its cost, then prevent. The visibility change may have been unnecessary, and it had costs of its own (stars, detached forks, features that depend on the plan). Reference: Chapter 15, sections 15.4 and 15.5; Chapter 21B, sections 21B.10 and 21B.14.

---

## Module 20

### Solution 20.1: Who wrote this line?

**Solution.**

| # | Written by | Question it answers |
|---|---|---|
| 1 `Permission denied (publickey)` | your `ssh` client, reporting that the server accepted none of the keys offered | which credential the client presented: no account matched it |
| 2 `fatal: Could not read from remote repository.` | Git | none: the other side closed the connection, and this line never contains the cause |
| 3 `Host key verification failed.` | your `ssh` client | which server: the key the server presented differs from `known_hosts` |
| 4 `fatal: Authentication failed for ...` | Git's HTTPS code, on HTTP status 401 | which credential: it was rejected outright |
| 5 `fatal: could not read Username ...` | Git | which credential: no helper answered and no prompt was possible |
| 6 `Permission to ... denied to USER` | GitHub's server | who the server says you are: you authenticated as USER, and USER has no access here |
| 7 `ERROR: We're doing an SSH key audit.` | GitHub's server | who you are and what that identity may do: the key is unverified and must be approved or removed |

The sentence for the ticket: "Please paste the whole output. That line is Git saying that the other program gave up; the cause is in the line above it, and if there is no line above, run `ssh -vT git@github.com` and paste that."

**Reasoning.** An authentication error is a short stack of lines written by different programs. Line 1 is the one people misread: it does not mean you lack permission on the repository. The server has not looked at the repository yet; it could not attach the connection to any account (Chapter 16, section 16.18).

**Common mistakes.** Reading Git's two-line hint under line 2 as a diagnosis. Treating lines 1 and 6 as the same problem: the first is "no account", the second is "the wrong account".

**Expert approach.** Attribute every line, then ask the chapter's three questions in order: transport and server, credential presented, identity and its rights. Reference: Chapter 16, sections 16.1, 16.17, 16.18 and 16.19.

### Solution 20.2: Pick the credential

**Solution.**

| Job | Credential | Lifetime | Reach if stolen | Wrong choice |
|---|---|---|---|---|
| 1 Nightly job, three repositories, opens pull requests | GitHub App installation token | 1 hour | the repositories and permissions of the installation | an engineer's classic token with `repo`: every repository that person can reach, and the job dies or lingers with the person |
| 2 `docker login ghcr.io` | personal access token (classic), with the narrowest package scope | long-lived; give it an expiry | by scope, across everything you can reach | a fine-grained token: it cannot access Packages |
| 3 Your contributions to someone else's public repository | the browser login of `gh`, or an SSH key | the OAuth token is long-lived; the key lasts until deleted (GitHub deletes one unused for a year) | what your account can reach | a fine-grained token: it cannot contribute to public repositories where you are not a member; a classic token typed at a prompt is not the answer either |
| 4 Workflow commenting on its own repository | the job's `GITHUB_TOKEN`, with the one write permission it needs | the job | one repository | a personal token stored as a secret |
| 5 Server pulling one repository | a read-only deploy key | no expiry | one repository, read-only | your personal SSH key copied to the server, or agent forwarding |

**Reasoning.** The token type decides how far a leak reaches (Chapter 16, section 16.6; Chapter 21B, section 21B.8). Three documented gaps of fine-grained tokens drive rows 2 and 3. For machines, the rule is an identity that is not a person (section 16.14).

**Common mistakes.** One classic token for everything. Assuming "fine-grained" is always possible. Forgetting that a deploy key has no expiry and, with write access, can do what an admin collaborator can do in that repository (section 16.22). For row 1, one deploy key cannot serve three repositories: a key cannot be reused for a second repository.

**Expert approach.** Rank candidates by blast radius and lifetime, then pick the narrowest that can do the job: job token, installation token, fine-grained token, deploy key, and classic tokens last, with a written reason. The chapter labels that order an inference of the Phase 0 report. Reference: Chapter 15, section 15.11; Chapter 16, sections 16.6 and 16.14; Chapter 21B, section 21B.8.

### Solution 20.3: 403, and Git never asks

**Solution.**

1. `personalstore`. `credential.helper` is a list; a helper configured for a URL is added to the general ones, Git asks each in order and stops at the first that returns a username and a password. The general entry comes first.

<!-- snippet: ex3/x20-auth-evidence/a-diagnosis -->
```text
$ printf 'protocol=https\nhost=github.com\n\n' | git credential fill
protocol=https
host=github.com
username=lab-user-personal
password=FAKE-TOKEN-not-a-real-credential
$ printf 'protocol=https\nhost=github.com\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o "trace: run_command: '.*"
trace: run_command: 'git credential-personalstore get'
```
<!-- /snippet -->

2. A helper answered, so there is nothing to ask. The server replied 403: a valid account without permission. Git erases a stored credential only after a 401, so the same credential is sent on every push. Access was granted to the work account, and that account never arrives at the server.
3. `git credential fill` with `protocol=https` and `host=github.com` on standard input shows which username comes back, and `GIT_TRACE=1` names the program that answered. On a real machine add `gh auth status`. (`fill` prints the secret on your screen: do not paste its output.)
4. Reset the list for the host, then add the helper you want. The first value must be the empty one:

<!-- snippet: ex3/x20-auth-evidence/a-fix -->
```text
$ git config unset --global credential.https://github.com.helper
$ git config set --global --append credential.https://github.com.helper ''
$ git config set --global --append credential.https://github.com.helper workstore
$ printf 'protocol=https\nhost=github.com\n\n' | git credential fill
protocol=https
host=github.com
username=lab-user-northwind
password=FAKE-TOKEN-not-a-real-credential
```
<!-- /snippet -->

5. Git's last line would have been `fatal: Authentication failed for ...` (status 401), and Git would have told the helper to erase the credential, so the next attempt would prompt or ask the next helper.

**Reasoning.** The failure is in the second of the three questions: which credential the client presents. The helper order decides it, and 403 keeps it in place (Chapter 16, sections 16.4 and 16.5). The reset-then-add pattern is what `gh auth setup-git` writes, according to the CLI source the chapter cites; here somebody added the per-host line by hand without the reset.

**Common mistakes.** Asking the administrator to grant access again. Reinstalling tools. Deleting the keychain entry without changing the configuration, after which the first successful login stores a credential again and the order decides again.

**Expert approach.** Never reason about "my credential"; ask which helper answers for this host and print it. One helper per host, set on purpose. Reference: Chapter 16, sections 16.4, 16.5, 16.19 and 16.21.

### Solution 20.4: `Permission denied (publickey)`

**Solution.**

1. Nothing. The server has not looked at the repository. It could not attach the connection to any account.
2. `identityfile ~/.ssh/id_ed25519_work` names a file that the listing of `~/.ssh` does not contain, and `identitiesonly yes` tells `ssh` to offer only the configured files, even if an agent holds other keys. Together: no key is offered.
3. `ssh -vT git@github.com`. It shows which configuration files were read, which identity files exist and which keys were offered. Expect to see that the configured file is missing and that no key was offered. This follows from the configuration; it was not run against GitHub here.
4. If the key in `~/.ssh/id_ed25519` is the one on your account (compare `ssh-keygen -l -f ~/.ssh/id_ed25519.pub` with the fingerprints your account lists), point the configuration at it:

<!-- snippet: ex3/x20-auth-evidence/b-fix -->
```text
$ sed 's/id_ed25519_work/id_ed25519/' ~/.ssh/config > ~/.ssh/config.new && mv ~/.ssh/config.new ~/.ssh/config
$ ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
user git
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_ed25519
```
<!-- /snippet -->

   If the configuration was copied from an old machine and the key was, correctly, not copied with it, create a new key on this laptop and upload its public half. One key per machine.
5. Under `sudo`, Git and `ssh` run as root: another configuration, another key set, no `SSH_AUTH_SOCK`. It cannot find a key that your own user does not have, and it leaves root-owned files in `.git`.

**Reasoning.** The remote URL is right (`git@`, the right host). The fault is in what the client presents, and `ssh -G` shows it without a connection: it prints the configured identity file whether or not the file exists, which is why the directory listing is the second half of the evidence (Chapter 16, sections 16.10 and 16.18).

**Common mistakes.** Uploading the public key again. Asking for repository access. Removing `IdentitiesOnly`, which hides the wrong path by letting the agent offer whatever it holds, and on a two-account machine lets the wrong account be accepted.

**Expert approach.** `git remote -v`, then `ssh -G HOST` filtered to user, host name, identity files and `identitiesonly`, then `ssh-add -l`, then `ssh -vT`. Four commands, in that order, before any change. Reference: Chapter 16, sections 16.9, 16.10, 16.18 and 16.20.

### Solution 20.5: The push works, the address is wrong

**Solution.**

1. An include is read at the place where its line stands. The work file is read first, then the `[user]` section that follows it in `~/.gitconfig`, and for a single-valued key the last value read wins. `url.<base>.insteadOf` is set only in the work file, so nothing overrides it.

<!-- snippet: ex3/x20-auth-evidence/c-diagnosis -->
```text
$ git config get --show-origin --all user.email
file:$LAB/ex3/x20-auth-evidence/home/.gitconfig-work	lab.user@northwind.example
file:$LAB/ex3/x20-auth-evidence/home/.gitconfig	lab-user@personal.example
$ git config get --show-origin --all url.git@github-work:.insteadOf
file:$LAB/ex3/x20-auth-evidence/home/.gitconfig-work	git@github.com:
```
<!-- /snippet -->

2. `git config get --show-origin --all user.email`: the work address first, the personal one last. Last wins.
3. The commit identity (wrong: personal address), the authentication identity (right: the alias selects the work key), and the signing identity (not involved). They are independent, which is why the push gave no hint.
4. Move the conditional include to the end of the file:

<!-- snippet: ex3/x20-auth-evidence/c-fix -->
```text
# Move the conditional include to the end of the file, so that it is read last.
$ { sed '1,2d' ~/.gitconfig; sed -n '1,2p' ~/.gitconfig; } > ~/.gitconfig.new && mv ~/.gitconfig.new ~/.gitconfig
$ git config get --show-origin user.email
file:$LAB/ex3/x20-auth-evidence/home/.gitconfig-work	lab.user@northwind.example
$ printf 'Owner: ranking team\n' > OWNERS.md && git add OWNERS.md && git commit -q -m 'Add owners file'
$ git log -2 --format='%an <%ae>  %s'
Lab User <lab.user@northwind.example>  Add owners file
Lab User <lab-user@personal.example>  Add README
```
<!-- /snippet -->

   The commits already pushed to shared branches stay as they are. Rewriting published history to change an address replaces every commit ID after the first rewritten commit and needs a force push to branches other people build on; an address in old commits does not justify that. Tell your manager the cause and the date from which commits are correct. Unpushed commits on a private branch can be redone.

**Reasoning.** Chapter 14B, section 14B.4 lists five ways a conditional include silently does not apply; this is "order". The chapter's rule: keep conditional includes at the end of the file. Chapter 16, section 16.2 explains why a correct push says nothing about the commit identity.

**Common mistakes.** Concluding that the `includeIf` pattern does not match, although the rewritten URL proves that it does. Checking with `git config get --global user.email`, which switches include processing off and shows only one value. Setting `user.email` in the repository's own configuration, which fixes one repository and leaves the rule broken for the next clone.

**Expert approach.** Ask Git where a value comes from before changing anything: `--show-origin --all`. Then fix the rule and not the instance. Reference: Chapter 14B, section 14B.4; Chapter 16, sections 16.2 and 16.13.

### Solution 20.6: Three faults, no connection

**Solution.** The model session, replayed by `labs/run ex3/x20-three-faults`. First, read the state without changing it:

<!-- snippet: ex3/x20-three-faults/01-first-step -->
```text
$ export HOME="$PWD/home" GIT_CONFIG_GLOBAL="$PWD/home/.gitconfig"
$ cd ~/work/chunker
$ git remote -v
origin	git@github.com:northwind-ml/chunker.git (fetch)
origin	git@github.com:northwind-ml/chunker.git (push)
$ git remote get-url origin
git@github.com:northwind-ml/chunker.git
$ git config get --show-origin --all user.email
file:$LAB/ex3/x20-three-faults/home/.gitconfig	lab-user@personal.example
$ git log -1 --format='%an <%ae>  %s'
Lab User <lab-user@personal.example>  Add README
# The URL is not rewritten, so ssh would be started for github.com. What would it use?
$ ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
user deploy
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_rsa_ci
identityfile ~/.ssh/id_ed25519_personal
```
<!-- /snippet -->

The effective URL equals the stored one, so the include does not apply: no rewrite, no work address. The connection would therefore be made for `github.com`, and for that host `ssh` would log in as `deploy`. GitHub requires the user `git`, so the server matches no account: `Permission denied (publickey)`.

**Fault 1: the include pattern lacks its trailing slash.**

<!-- snippet: ex3/x20-three-faults/02-fault-1 -->
```text
$ git config list --global | grep -i includeif
includeif.gitdir:~/work.path=~/.gitconfig-work
$ cat ~/.gitconfig-work
[user]
	email = lab.user@northwind.example
[url "git@github-work:"]
	insteadOf = git@github.com:
# The pattern has no trailing slash, so it matches only a repository whose .git is ~/work itself.
$ git config unset --global 'includeIf.gitdir:~/work.path'
$ git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
$ git config get --show-origin --all user.email
file:$LAB/ex3/x20-three-faults/home/.gitconfig	lab-user@personal.example
file:$LAB/ex3/x20-three-faults/home/.gitconfig-work	lab.user@northwind.example
$ git remote get-url origin
git@github-work:northwind-ml/chunker.git
```
<!-- /snippet -->

**Fault 2: a `Host github*` block at the top of `~/.ssh/config`.** For each setting the first value obtained wins, and the pattern matches both `github.com` and `github-work`.

<!-- snippet: ex3/x20-three-faults/03-fault-2 -->
```text
$ ssh -T -F ~/.ssh/config -G github-work | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
user deploy
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_rsa_ci
identityfile ~/.ssh/id_ed25519_work
$ head -4 ~/.ssh/config
# Added by the CI bootstrap script
Host github*
  User deploy
  IdentityFile ~/.ssh/id_rsa_ci
# First value obtained wins: "User deploy" and the CI key come from the Host github* block on top.
$ { sed '1,5d' ~/.ssh/config; printf '\n'; sed -n '1,4p' ~/.ssh/config; } > ~/.ssh/config.new && mv ~/.ssh/config.new ~/.ssh/config && chmod 600 ~/.ssh/config
$ ssh -T -F ~/.ssh/config -G github-work | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
user git
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_ed25519_work
identityfile ~/.ssh/id_rsa_ci
```
<!-- /snippet -->

**Fault 3: the alias names a key file that does not exist.**

<!-- snippet: ex3/x20-three-faults/04-fault-3 -->
```text
$ ls ~/.ssh
config
id_ed25519_northwind
id_ed25519_northwind.pub
id_ed25519_personal
id_ed25519_personal.pub
# The alias names id_ed25519_work. The key on disk is id_ed25519_northwind.
$ sed 's/id_ed25519_work/id_ed25519_northwind/' ~/.ssh/config > ~/.ssh/config.new && mv ~/.ssh/config.new ~/.ssh/config && chmod 600 ~/.ssh/config
```
<!-- /snippet -->

<!-- snippet: ex3/x20-three-faults/05-verify -->
```text
$ ssh -T -F ~/.ssh/config -G github-work | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
user git
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_ed25519_northwind
identityfile ~/.ssh/id_rsa_ci
$ ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
user git
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_ed25519_personal
identityfile ~/.ssh/id_rsa_ci
$ git remote get-url origin
git@github-work:northwind-ml/chunker.git
$ git config get user.email
lab.user@northwind.example
```
<!-- /snippet -->

After repairing only the order of the blocks, the unrewritten URL would go to `github.com` with the personal key, GitHub would authenticate the personal account, and the server would answer that the repository was not found: its deliberate answer for an identity without access (section 16.19). After repairing faults 1 and 2 only, the error would again be `Permission denied (publickey)`, written by `ssh`, this time because no key is offered.

**Reasoning.** One symptom, three causes in two programs. Git decides the URL (`includeIf`, `insteadOf`); `ssh` decides the user and the key. `git remote get-url` and `ssh -G` print each decision without a connection.

**Common mistakes.** Stopping after the first fault. Fixing the visible symptom by editing the remote URL to use the alias by hand, which leaves the include broken and the email wrong. Leaving the CI block in the file: after the move, `id_rsa_ci` is still listed as a second identity file for every `github*` host, as the last transcript shows. It is harmless only because the file does not exist. If this machine is not a CI agent, delete the block.

**Expert approach.** Check each layer with its own instrument and predict the error that each remaining fault would produce before you fix it. A prediction that comes true is the proof that you understood the mechanism; a repair that works is not. Reference: Chapter 14B, section 14B.4; Chapter 16, sections 16.10, 16.13, 16.18 and 16.19.

### Solution 20.7: The nightly sync says "not found"

**Solution.**

1. The job authenticates with a personal token of an account that was removed from the organization last Wednesday; the token is still valid, but its account can no longer see the repository. The decisive evidence is the pair of dates: removed on Wednesday, failing since the next nightly run.
2. For a private repository and a credential without access, GitHub answers 404 and not 403, "to avoid confirming the existence of private repositories" (Chapter 16, section 16.19; Chapter 15, section 15.17). Git turns the 404 into `repository ... not found`.
3. The rename is irrelevant: the URL already has the new name. The rerun from the laptop used the teammate's own credential, so it proved that the repository and the network are fine and said nothing about the job's identity. The status page reports GitHub's health, not your authorization.
4. Tonight: a read-only deploy key on `feature-store`, created for this job and stored on the analytics host. It authenticates as the repository's key, not as a person, and reaches one repository. Next week: a GitHub App installation, which authenticates as the app with one-hour tokens and a permission list an auditor can read. Not acceptable even for one night: a teammate's personal token, or re-adding the former employee.
5. From June until last Wednesday the job ran with the access of someone who had left the company, through a classic token that reaches everything its owner can reach and that appeared in nobody's inventory. The access review found the account, not the token.

**Reasoning.** This is the chapter's fourth CTO question (section 16.1) and the production note of section 16.14: a job runs as whoever created its credential. A failure that starts on a date is explained by what changed on that date.

**Common mistakes.** Debugging the network. Treating "not found" as a statement about the repository. Fixing it by pasting another person's token into the same file, which reproduces the incident with a later date.

**Expert approach.** Ask "who does the server say this job is?" before anything else, and answer it from the credential's owner, not from the script. Then replace personal credentials in automation as a class, not one at a time. Reference: Chapter 16, sections 16.1, 16.6, 16.14 and 16.19.

### Solution 20.8: The SSH calendar

**Solution.**

| Machine | Affected? | Why | Check |
|---|---|---|---|
| A | No, according to the announcement | the 3072-bit minimum applies to RSA keys uploaded after 14 October 2026; OpenSSH 10.2 signs RSA with SHA-2, so the removal of the `ssh-rsa` signature type on 13 January 2027 does not touch it | `ssh -V`; `ssh-keygen -l -f ~/.ssh/KEY.pub` |
| B | Yes, on 13 January 2027, and during the brownouts of 4 November and 9 December 2026 | clients older than OpenSSH 7.2 cannot sign RSA with SHA-2; the key size is not the problem | `ssh -V` |
| C | Yes, from 14 October 2026 | a new RSA upload must have at least 3072 bits | create an Ed25519 key instead, which is what GitHub documents |
| D | No | Ed25519 and ECDSA keys are not affected | `ssh-keygen -l -f` on the public key |
| E | No | HTTPS remotes are not affected | `git remote -v` |

The unverified statement: the announcement does not give a minimum size for RSA keys that are already uploaded. For machine A the honest message is "nothing in the announcement affects you; replace the 2048-bit key with an Ed25519 key at your next convenience, because the announcement is silent about old small keys".

**Reasoning.** The signature type `ssh-rsa` (RSA with SHA-1) is not the key type `ssh-rsa`. An existing RSA key keeps working as long as the client signs with `rsa-sha2-256` or `rsa-sha2-512`, which current clients choose by themselves (Chapter 16, section 16.16).

**Common mistakes.** "RSA keys stop working in January." Worrying about laptops: the machines at risk are old build agents, appliances and libraries embedded in tools. Upgrading the key on machine B and leaving the client, which changes nothing about the signature type.

**Expert approach.** Inventory by client version first, key type second. Schedule the test for a brownout date so that the failure appears on a day you chose. Reference: Chapter 16, section 16.16, and the roadmap's re-verification calendar.

---

## Module 21

### Solution 21.1: A draft, a range, and the head ref

**Solution.** The fetch is `git fetch origin pull/N/head:pr-check`, with your pull request's number for N; `pull/N/head` is shorthand for `refs/pull/N/head`.

| Command | Git data on the server | GitHub object |
|---|---|---|
| `git push -u origin docs/exercise-21-1` | the branch ref and your commit | none |
| `gh pr create --draft --fill` | `refs/pull/N/head` and, when the merge is clean, a test merge commit | the pull request |
| `gh pr ready` | none | the draft flag; code owners are now requested |
| `gh pr close --delete-branch` | the branch ref is deleted | the state becomes closed |

`pr-check` and your branch name the same commit because the head ref points at the head of the pull request. A plain `git fetch` never brought it, because the default refspec covers `refs/heads/*` only. A draft cannot be merged, and code owners are not requested until it is marked ready. After the close, the commit is still on the server under `refs/pull/N/head`, which nobody can delete or rewrite with Git.

**Reasoning.** Opening a pull request moves no branch. It creates a GitHub object and a little Git data in the base repository (Chapter 17, section 17.2). The two range commands print in advance what the page will compute: `base..head` for the Commits tab, `base...head` for Files changed (section 17.3).

**Common mistakes.** Opening the pull request first and reading the range afterwards. Believing that closing and deleting unpublishes the commit. Expecting `gh pr create --dry-run` to be free of side effects: the help text says it may still push.

**Expert approach.** `git fetch`, `git log --oneline origin/main..HEAD`, `git diff --stat origin/main...HEAD`, every time, before `gh pr create`. Anything pushed to a pull request is published for good. None of the `gh` commands was run by the author; the flags are those of 2.88.1. Reference: Chapter 17, sections 17.2 to 17.4 and 17.16.

### Solution 21.2: Is it still approved?

**Solution.**

1. Under A: after step 1 yes. After step 2 no: the diff changed, so R's approval is dismissed as stale. After step 3 yes. After step 4 no: **Update branch** is one of the documented causes of dismissal. After step 5 still no; an event of that kind can itself dismiss an approval (see 5). After step 6 yes: S approved after the last change of the diff, and option A does not ask who pushed.
2. Under B: after step 2 the most recent push needs an approval from someone other than the author, who made it; S's approval in step 3 is one. After step 6, S is the last person to push, so S's own approval is not enough: someone other than S must approve.
3. GitHub: "it is safer to dismiss stale reviews." Option B is the compromise for large pull requests with many reviewers: earlier approvals are not thrown away at every update.
4. After step 2: approve, then push, then merge lands a commit nobody reviewed. The documentation calls this a pull request being "hijacked".
5. Yes. The approval is attached to the state of the diff, and the documented causes of a change include "because a related pull request is merged into the target branch"; approvals "will be dismissed as stale if the merge base introduces new changes after the review was submitted".

**Reasoning.** An approval is a claim about a diff at a point in time. A dismisses the claim whenever the diff changes; B asks only that the latest push has an approver who is not its pusher (Chapter 17, section 17.5; Chapter 18, section 18.7). The exact bookkeeping of earlier approvals under B across several pushes is not spelled out in the chapter, which is why question 2 asks only about the two cases the documentation states.

**Common mistakes.** Thinking either option is the default: both are optional. Treating **Update branch** as harmless under A. Under B, counting a reviewer's approval of a commit they pushed themselves.

**Expert approach.** Name the cost when you propose A: a re-review after every update, rebases included. Then pair it with small pull requests, so that a re-review is cheap. Reference: Chapter 17, section 17.5; Chapter 18, section 18.7.

### Solution 21.3: A stack, and a squash underneath it

**Solution.**

<!-- snippet: ex3/x21-stack-predict/02-ranges -->
```text
$ git log --oneline origin/main..feature/overlap-tests
acbec10 Test that overlap repeats characters
281f566 Reject an overlap that is not smaller than the size
5b7fd29 Add overlap parameter
$ git log --oneline feature/overlap..feature/overlap-tests
acbec10 Test that overlap repeats characters
$ git diff --stat origin/main...feature/overlap-tests
 chunker/split.py    | 9 ++++++---
 tests/test_split.py | 4 ++++
 2 files changed, 10 insertions(+), 3 deletions(-)
$ git diff --stat origin/main..feature/overlap-tests
 chunker/split.py     | 9 ++++++---
 config/chunking.yaml | 2 +-
 tests/test_split.py  | 4 ++++
 3 files changed, 11 insertions(+), 4 deletions(-)
```
<!-- /snippet -->

- a. Three with base `main`; one with base `feature/overlap`.
- b. The three-dot diff names `chunker/split.py` and `tests/test_split.py`. The two-dot diff adds `config/chunking.yaml` and claims that your branch reverts the chunk size, because it compares the two tips and `main` changed that file after you branched.

<!-- snippet: ex3/x21-stack-predict/03-after-squash -->
```text
$ git fetch --prune
From ../../server/chunker
 - [deleted]         (none)     -> origin/feature/overlap
   dad6e83..6d3c3e7  main       -> origin/main
$ git log --oneline -2 origin/main
6d3c3e7 Add overlap to the splitter (#11)
dad6e83 Double the default chunk size
$ git merge-base origin/main feature/overlap-tests
6258ae58f09df0c7a5d3223696e2c5571055981a
$ git log --oneline origin/main..feature/overlap-tests
acbec10 Test that overlap repeats characters
281f566 Reject an overlap that is not smaller than the size
5b7fd29 Add overlap parameter
$ git diff --stat origin/main...feature/overlap-tests
 chunker/split.py    | 9 ++++++---
 tests/test_split.py | 4 ++++
 2 files changed, 10 insertions(+), 3 deletions(-)
$ git merge-tree --write-tree --name-only origin/main feature/overlap-tests
34ad3cae8224f2849427353fa10c60eb14cc3e30
[exit status: 0]
```
<!-- /snippet -->

- c. `6258ae5`, the original fork point. The squash commit `6d3c3e7` has one parent and no link to your branch, so the merge base did not move.
- d. Still three commits and two files, two of the commits being the ones that were "already merged".
- e. No conflict: exit status 0. Since the merge base, both sides made the *same* change to `chunker/split.py`: `main` through the squash commit, your branch through the two original commits. A change that both sides made is taken once. The chapter's squash-then-reuse example conflicts because its follow-up commit changed the file again, so the two sides differed; here the upper layer touches only the test file.

<!-- snippet: ex3/x21-stack-predict/04-repair -->
```text
$ git rebase --onto origin/main feature/overlap feature/overlap-tests
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/overlap-tests.
$ git log --oneline origin/main..feature/overlap-tests
2651b08 Test that overlap repeats characters
$ git diff --stat origin/main...feature/overlap-tests
 tests/test_split.py | 4 ++++
 1 file changed, 4 insertions(+)
$ git push --force-with-lease
To ../../server/chunker.git
 + acbec10...2651b08 feature/overlap-tests -> feature/overlap-tests (forced update)
```
<!-- /snippet -->

- f. `git rebase --onto origin/main feature/overlap feature/overlap-tests`: take the commits that are on the upper branch and not on the lower one, and replay them on `main`. The branch was rewritten, so the push must be `--force-with-lease`. If the local `feature/overlap` were gone, the ID of its old tip, `281f566`, would serve as the second argument.

**Reasoning.** A pull request shows `base..head` and `base...head`, both anchored at the merge base. The merge base comes from parent links only, and a squash commit records none to the branch (Chapter 17, sections 17.3, 17.12 and 17.14). Whether the test merge conflicts is a separate, three-way question, answered by the rule table of Chapter 8, section 8.4.

**Common mistakes.** Expecting a conflict whenever both sides touched a file. Using a plain `git rebase origin/main`, which replays all three commits and relies on Git to notice duplicates. Concluding "no conflict, so nothing to fix": a squash merge of the unrepaired pull request would produce the right tree, but its page shows three commits and two files to a reviewer who should see one of each.

**Expert approach.** After the bottom of a stack is squash-merged, transplant the next layer at once with `--onto`, and say so on the pull request, because the force push makes review comments outdated. GitHub's stack feature, in public preview, does this rebase for you; without it GitHub only retargets. Reference: Chapter 8, section 8.4; Chapter 17, sections 17.12 and 17.14.

### Solution 21.4: Three small mysteries

**Solution.**

1. The pull request has a merge conflict. With a conflict there is no test merge, and "Workflows will not run on `pull_request` activity if the pull request has a merge conflict". Chapter 17, section 17.2.
2. No rule requires a pull request. Without a ruleset or classic rule with that option, **Request changes** "is purely informational and will not prevent merging". Chapter 17, section 17.4.
3. The script read `mergeable` while it was `null`. `null` means GitHub has started a background job to compute mergeability; the script must ask again. Chapter 17, section 17.6.

**Reasoning.** All three are cases of reading a GitHub state as something it is not: "no run" as "CI is broken", a review verdict as a lock, "not computed yet" as "no".

**Common mistakes.** For 1, re-running workflows or editing their triggers. For 2, blaming the author; the control was never binding. For 3, treating a three-valued field as a boolean.

**Expert approach.** For a pull request without runs, check conflicts first with `git merge-tree --write-tree --name-only origin/main <head>`; it is the cheapest test and the most common cause. For scripts, read `mergeStateStatus` and `mergeable` together and treat `UNKNOWN` or `null` as "wait" (Chapter 18, section 18.17). Reference: Chapter 17, sections 17.2, 17.4, 17.6 and 17.19.

### Solution 21.5: The fork that cannot be synced

**Solution.**

1. With `A...B`, `--left-right --count` prints the number of commits reachable only from the left side, then only from the right side. `3` commits are on `upstream/main` and not on the fork's `main`; `2` commits are on the fork's `main` and not on upstream.
2. Commits made on the fork's default branch: a `git commit` before switching to a new branch, or a feature branch merged into the fork's own `main`.
3. `gh repo sync` fast-forwards the fork's branch to its parent's. With two commits of its own, the fork's `main` cannot be fast-forwarded, so a plain sync cannot do it. With `--force` the branches "will be synced using a hard reset": 🔴 the two commits disappear from the fork's `main`. They can be recovered only from a clone that still has them.
4. Assuming the local `main` equals `origin/main` and the working tree is clean:

```bash
git switch main
git branch rescue/fork-main            # 🟢 the two commits now have a second name
git reset --hard upstream/main         # 🔴 moves main and overwrites the working tree; nothing is lost, the rescue branch holds the commits
git push --force-with-lease origin main    # 🔴 a forced push: your own fork's main, replaced only if it is where you last saw it
git switch rescue/fork-main
git rebase upstream/main               # 🟡 the two commits, replayed on current upstream
git push -u origin rescue/fork-main    # 🟢 a normal branch, from which you open the pull request
```

5. Never commit on the fork's default branch. Branch from `upstream/main` after a fetch. One branch per pull request, deleted after the merge.

**Reasoning.** The fork's `main` is meant to be a copy of upstream's. Once it has commits of its own it can only be merged or reset, never fast-forwarded (Chapter 17, section 17.15; Chapter 15, section 15.7). The numbers and the commands were not produced by a script for this exercise; Lab 21.1 has you make this mistake and recover with a real transcript.

**Common mistakes.** Running `gh repo sync --force` first and looking for the commits afterwards. Merging `upstream/main` into the fork's `main`, which leaves the fork permanently different from upstream and puts a merge commit into every later pull request.

**Expert approach.** Give the commits a name before any reset, and preview with `git log upstream/main..origin/main`. Reference: Chapter 12, section 12.10; Chapter 15, section 15.7; Chapter 17, sections 17.15 and 17.21.

### Solution 21.6: Five commits for a two-commit fix

**Solution.** Replayed by `labs/run ex3/x21-foreign-commits`.

<!-- snippet: ex3/x21-foreign-commits/01-evidence -->
```text
$ git status -sb
## fix/unicode-split...origin/fix/unicode-split
$ git fetch
From ../../server/chunker
 + 0a98038...bcb61f8 feature/semantic-split -> origin/feature/semantic-split  (forced update)
   6258ae5..d533f59  main                   -> origin/main
$ git log --format='%h %an: %s' origin/main..HEAD
ff0f3ff Lab User: Test splitting text with multi-byte characters
33d0dae Lab User: Count characters, not bytes, when splitting
0a98038 Ravi Menon: WIP tune thresholds
84dcfdc Ravi Menon: Split on sentence boundaries
0f5e63d Ravi Menon: Add sentence boundary detection
$ git diff --stat origin/main...HEAD
 chunker/semantic.py   | 11 +++++++++++
 chunker/sentences.py  |  7 +++++++
 chunker/split.py      |  5 +++--
 config/chunking.yaml  |  3 ++-
 tests/test_unicode.py |  5 +++++
 5 files changed, 28 insertions(+), 3 deletions(-)
```
<!-- /snippet -->

The fetch reports a forced update of `origin/feature/semantic-split`: Ravi rewrote his branch. Your range contains three commits by Ravi under your two.

<!-- snippet: ex3/x21-foreign-commits/02-whose -->
```text
$ git merge-base origin/main HEAD
6258ae58f09df0c7a5d3223696e2c5571055981a
$ git log --format='%h %an: %s' origin/main..origin/feature/semantic-split
bcb61f8 Ravi Menon: Split on sentence boundaries
3683815 Ravi Menon: Add sentence boundary detection
$ git cherry -v origin/feature/semantic-split HEAD
- 0f5e63d05f017ecf20f680f915fcefe2cd12810c Add sentence boundary detection
+ 84dcfdc887064e21cd2dc7eb8b5367d5463d54cc Split on sentence boundaries
+ 0a98038d867f4a3676fea6e59092538278dd15cd WIP tune thresholds
+ 33d0dae2b48367064360814859b07bdaa27ccb6e Count characters, not bytes, when splitting
+ ff0f3ff3cc23316cf32516407191fc9ca182794b Test splitting text with multi-byte characters
```
<!-- /snippet -->

Your branch was cut from Ravi's branch as it was then. Ravi has since squashed his WIP commit into the one before it and rebased onto the new `main`: his branch now has two commits with new IDs, `3683815` and `bcb61f8`. `git cherry` marks `0f5e63d` with `-`: a commit with the same patch exists on Ravi's branch. The next two are marked `+`, because after the squash no single commit of his matches either of them.

<!-- snippet: ex3/x21-foreign-commits/03-repair -->
```text
$ git log --format='%h %an: %s' --author='Lab User' origin/main..HEAD
ff0f3ff Lab User: Test splitting text with multi-byte characters
33d0dae Lab User: Count characters, not bytes, when splitting
$ git rebase --onto origin/main HEAD~2
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/fix/unicode-split.
$ git log --format='%h %an: %s' origin/main..HEAD
bc97ef1 Lab User: Test splitting text with multi-byte characters
df2ecb4 Lab User: Count characters, not bytes, when splitting
$ git diff --stat origin/main...HEAD
 chunker/split.py      | 5 +++--
 tests/test_unicode.py | 5 +++++
 2 files changed, 8 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

`git rebase --onto origin/main HEAD~2` 🟡 replays the last two commits on `main`. Naming the last foreign commit, `0a98038`, instead of `HEAD~2` is the same command.

<!-- snippet: ex3/x21-foreign-commits/04-publish -->
```text
$ git merge-tree --write-tree --name-only origin/main HEAD
8db66b5493f925c7d118f53d1ac226faf4a7618e
[exit status: 0]
$ git push --force-with-lease
To ../../server/chunker.git
 + ff0f3ff...bc97ef1 fix/unicode-split -> fix/unicode-split (forced update)
$ git status -sb
## fix/unicode-split...origin/fix/unicode-split
```
<!-- /snippet -->

**Reasoning.** The base of the pull request is right; the branch started in the wrong place. So `base..head` lists everything between `main` and your tip, including the old copies of Ravi's commits. Those old copies were on no branch of Ravi's any more; your branch, and `refs/pull/23/head` on the server, kept them reachable. Changing the base would not help: no branch on the server contains exactly those three old commits. This is the fifth documented cause combined with the second (Chapter 17, section 17.12): a rewritten branch underneath, and a fork point that was not the base.

**Common mistakes.** `git rebase origin/main`, which replays all five commits. `git rebase origin/feature/semantic-split`, which makes the pull request depend on Ravi's unmerged work again. A plain `git push --force`. Forgetting to fetch first, and so repairing against a stale `origin/main`.

**Expert approach.** Identify your own commits by author and by range, transplant exactly those, then verify three things before publishing: the range, the three-dot diff, and the test merge. On GitHub the pull request's head ref follows the branch after the push, and review comments on the replaced commits become outdated, so leave a comment that says what you did. The prevention is to branch from `origin/main` after a fetch, and never from whatever happens to be checked out. Reference: Chapter 9 (`--onto`); Chapter 17, sections 17.12 and 17.19.

### Solution 21.7: Green on the pull request, red on main

**Solution.**

1. The test merge of pull request 312 as it was at 11:15: a commit whose parents were the head of 312 and the tip of `main` at that time, which did not contain 310.
2. Two changes that are each correct and incompatible together: 310 renamed a parameter, 312 added a new call with the old name in a new file. Git saw no conflict because the two changes touch different lines of different files; a three-way merge compares text, not meaning. The ruleset does not require branches to be up to date, so nothing made 312 run its checks against a `main` that contained 310.
3. Two commands on a clone of `main`: `git grep -n 'def reserve' main` shows the new parameter name, and `git grep -n 'reserve(qty' main` shows a caller that still uses the old one. A failure that follows from the text of two files fails every time. Re-running the job cannot help.
4. Revert pull request 312 on `main` (`gh pr revert 312` creates the reverting pull request). That returns `main` to the state after 310, which the 13:52 run on `main` tested. Second choice: fix forward by changing the keyword in the new call. It is one line, but it creates a state nobody has tested yet, under time pressure; do it as the follow-up that re-lands 312.
5. Strict required checks ("up to date before merging"): every merge makes the other open pull requests out of date, so each needs an update and another CI run. A merge queue: CI runs on the exact commit that will become the new tip, at the price of one run per group, some latency per merge, a `merge_group` trigger in the workflow, and its plan gate. For a few merges a day, strict checks cost less.

**Reasoning.** CI on a `pull_request` event tests the merged result with `main` as it was when the test merge was made, and since February 2026 that commit is regenerated only on a push to the branch, a change of the merge base, or after 12 hours (Chapter 17, section 17.2). Under a loose policy, "green" means "green against an older `main`" (Chapter 18, section 18.8). The situation is a described one; the two `git grep` commands are standard and were not run against this fictional repository.

**Common mistakes.** Accepting "flaky" without asking for evidence. Re-running until green. Reverting 310, the older and wider change, which other work may already build on. Looking for a merge conflict that never existed.

**Expert approach.** State what CI tested, in terms of commits, before discussing the test. Then restore a known-good state by the most mechanical means, and move the design discussion (strict checks or a queue) to after the incident. Reference: Chapter 8, section 8.15; Chapter 17, sections 17.2, 17.11 and 17.19; Chapter 18, section 18.8.

---

## Module 22

### Solution 22.1: The three buttons from memory

**Solution.**

| | Create a merge commit | Squash and merge | Rebase and merge |
|---|---|---|---|
| New commits on the base | one merge commit, plus your commits under their own IDs | one | one per original commit |
| Original commit IDs on the base? | yes | no | no: it "always ... creates new commit SHAs" |
| Committer of what lands | your commits unchanged; the merge commit is committed by GitHub | GitHub | always updated |
| Signed? | your commits keep their signatures; the merge commit is signed by GitHub | signed by GitHub | not signed |
| Linear history rule | not allowed | allowed | allowed, at most 100 commits |
| Documented loss | none | when changes were made and who authored the squashed commits | commits that were empty to begin with are dropped |

Unverified: who is recorded as the *author* of a squash commit, and whether other contributors become `Co-authored-by` trailers, is not stated on the documentation pages the chapter read. Lab 22.1 has you read a real one.

**Reasoning.** All three produce the same tree on the base. They differ in what history says about how the code got there, and every later tool works on those commits and no others (Chapter 17, sections 17.8 and 17.9).

**Common mistakes.** "Rebase and merge keeps my commits": it keeps their content and authorship, under new IDs, even when no rebase seemed necessary. "Squash loses nothing": it loses the per-commit record.

**Expert approach.** Ask what must be provable later (the reviewed commit ID, a signature, a bisectable step, a one-command revert) and choose the method that preserves it. Reference: Chapter 17, sections 17.8 and 17.9.

### Solution 22.2: Which button was pressed?

**Solution.**

1. X is rebase and merge: three commits with the original subjects and author, new IDs, Asha as committer, no merge commit. Y is squash and merge: one new commit, one parent, the pull request number in its subject. Z is a merge commit: `6b21010` has two parents and the original IDs `5b7fd29`, `8743f96` and `39301d4` are on `main`.
2. The committer: on GitHub the squash commit and the merge commit are committed by GitHub, and rebase and merge "always updates the committer information". And signatures: GitHub signs the merge commit and the squash commit; nothing here is signed.

<!-- snippet: ex3/x22-which-method/05-ancestry -->
```text
$ git -C X merge-base --is-ancestor 39301d4 main
[exit status: 1]
$ git -C Y merge-base --is-ancestor 39301d4 main
[exit status: 1]
$ git -C Z merge-base --is-ancestor 39301d4 main
[exit status: 0]
$ git -C X rev-parse main^{tree} && git -C Y rev-parse main^{tree} && git -C Z rev-parse main^{tree}
34ad3cae8224f2849427353fa10c60eb14cc3e30
34ad3cae8224f2849427353fa10c60eb14cc3e30
34ad3cae8224f2849427353fa10c60eb14cc3e30
```
<!-- /snippet -->

3. X: 1. Y: 1. Z: 0. Only the merge commit made your head commit an ancestor of `main`.
4. Yes: `34ad3ca` three times. The method does not change what the code is after the merge.

<!-- snippet: ex3/x22-which-method/07-revert -->
```text
$ git -C X revert --no-edit main~3..main
[main 89d024e] Revert "Reject an overlap that is not smaller than the size"
 Date: Mon Sep 7 10:32:00 2026 +0530
 1 file changed, 2 deletions(-)
[main e5edaf2] Revert "Test that overlap repeats characters"
 Date: Mon Sep 7 10:32:00 2026 +0530
 1 file changed, 4 deletions(-)
[main 8f73250] Revert "Add overlap parameter"
 Date: Mon Sep 7 10:32:00 2026 +0530
 1 file changed, 3 insertions(+), 4 deletions(-)
$ git -C Y revert --no-edit main
[main 18cae7c] Revert "Add overlap to the splitter (#12)"
 Date: Mon Sep 7 10:33:00 2026 +0530
 2 files changed, 3 insertions(+), 10 deletions(-)
$ git -C Z revert --no-edit -m 1 main
[main bfffa35] Revert "Merge pull request #12 from feature/overlap"
 Date: Mon Sep 7 10:34:00 2026 +0530
 2 files changed, 3 insertions(+), 10 deletions(-)
$ git -C X rev-parse main^{tree} && git -C Y rev-parse main^{tree} && git -C Z rev-parse main^{tree}
9c3c63101fd8ce13fd89015ae964cf0b6895c7af
9c3c63101fd8ce13fd89015ae964cf0b6895c7af
9c3c63101fd8ce13fd89015ae964cf0b6895c7af
$ git -C X rev-parse main~3^{tree}
34ad3cae8224f2849427353fa10c60eb14cc3e30
```
<!-- /snippet -->

5. X: `git revert --no-edit main~3..main`, one revert per commit, and nothing in the history marks where the pull request began. Y: `git revert main`. Z: `git revert -m 1 main`, which carries the trap: merging the branch again later brings nothing back until you revert the revert. After the reverts the three trees are equal again (`9c3c631`).
6. X and Z. In both, `main` contains the first two commits of the pull request as separate states that CI never tested alone, and `git bisect` can stop on them. In Z, `git bisect start --first-parent` treats the merged pull request as one step. In X no option helps: every commit has to pass on its own. Y has neither the problem nor the granularity.

**Reasoning.** Read the parents, the IDs, the author and the committer, in that order. Ancestry is the fact behind most later surprises: `git branch -d` refusing, a pull request listing old commits again, an audit that cannot find the reviewed ID (Chapter 17, section 17.9).

**Common mistakes.** Calling X a fast-forward of the original commits: compare the IDs. Reverting Z without `-m 1`. Assuming a different history means a different tree.

**Expert approach.** `git log --graph --format='%h %p | %an | %cn | %s'` on the base branch answers "which method" for any repository in one command. On GitHub the committer column alone often decides it. Reference: Chapter 8, section 8.18; Chapter 14A, section 14A.22; Chapter 17, sections 17.8 and 17.9.

### Solution 22.3: The queue that never finishes

**Solution.**

1. On the commits of the queue's temporary branches, which begin with `gh-readonly-queue/main`. GitHub creates them: each groups the pull request with the latest `main` and the pull requests ahead of it, and they "contain a different `sha` from the pull request".
2. The workflow starts on a push to `main` and on `pull_request`. Queue branches trigger their own event, `merge_group`. Without that trigger no run starts for them, the required check `ci` is never reported, and the documentation says what follows: "The merge will fail as the required status check will not be reported."
3. Add one line under `on:`:

```yaml
on:
  push:
    branches: [main]
  pull_request:
  merge_group:
```

4. The queue. With a merge queue "you no longer get to choose the merge method".
5. When there are only a few merges a day. A queue adds a CI run per group and latency per merge; strict required checks cost less, at the price of updating pull requests that have gone out of date. Also check the plan gate: public repositories owned by an organization, or private ones on Enterprise Cloud.

**Reasoning.** A required check is a name that must be reported on a specific commit. The queue changes which commit that is (Chapter 17, section 17.11; Chapter 18, section 18.8, the "Merge queue" row). The workflow file is teaching material and was parse-checked, not run.

**Common mistakes.** Re-running the pull request's own checks, which are green and irrelevant to the queue's commit. Adding the queue branches to `push: branches:`, which is not the documented trigger.

**Expert approach.** Add `merge_group` to every workflow that reports a required check in the same change that enables the queue, and test with one pull request before announcing it. Reference: Chapter 17, section 17.11.

### Solution 22.4: A merge method for three teams

**Solution.**

| Team | Method | Gives up | Must match |
|---|---|---|---|
| A | Create a merge commit | a linear history; `main` shows every commit of every branch | the repository allows merge commits; no linear-history rule; every commit on a head branch must be signed and verified, or the signed-commits rule blocks the merge |
| B | Squash and merge | the per-commit record and the reviewed commit IDs | only squash enabled (repository setting or `allowed_merge_methods`); automatic deletion of head branches, so that nobody reuses a squashed branch |
| C | Rebase and merge fits three wishes | the reviewed commit IDs; at most 100 commits per pull request | rebase merging enabled; linear-history rule |

For team C the fourth wish breaks it. Commits made by **Rebase and merge** are created "without commit signature verification": GitHub writes modified commits and does not have the contributors' private keys. A signed-commits rule on `main` therefore makes that button unusable. The documented workaround is "to rebase and merge locally, and then push", which means a maintainer with the right to push to `main` signs the rebased commits with the maintainer's own key. The alternatives are to drop the rule on `main`, or to squash and lose the per-commit history that the team wanted.

**Reasoning.** Only a merge commit keeps the reviewed IDs, which is the literal reading of team A's audit rule. Squash turns a messy branch into one revertible unit. Rebase gives linear, per-commit history and cannot be signed by the platform (Chapter 17, sections 17.8, 17.9 and 17.20; Chapter 18, section 18.10).

**Common mistakes.** Choosing one method for a whole company. Enabling a signed-commits rule without checking which merge buttons survive it. For team A, forgetting that unsigned commits on a head branch also block a squash merge.

**Expert approach.** Write the requirement as a sentence somebody could audit, then test each method against it. State the cost in the same sentence as the recommendation. Reference: Chapter 17, sections 17.8, 17.9 and 17.20; Chapter 18, sections 18.10 and 18.11.

### Solution 22.5: The release that does not contain its fix

**Solution.** Replayed by `labs/run ex3/x22-release-drift`.

<!-- snippet: ex3/x22-release-drift/01-evidence -->
```text
$ git fetch
From ../../server/chunker
   6258ae5..f906661  main       -> origin/main
 * [new tag]         v0.9.0     -> v0.9.0
$ git for-each-ref --format="%(refname:short) %(objecttype) %(*objecttype)" refs/tags
v0.8.0 tag commit
v0.9.0 commit 
$ git log --oneline --decorate -5 origin/main
f906661 (origin/main, origin/HEAD) Double the default chunk size
8864ccc Reject an overlap that is not smaller than the size
e3977e2 (tag: v0.9.0) Add overlap parameter
6258ae5 (HEAD -> main, tag: v0.8.0) Add splitter test
e636524 Add chunking config
```
<!-- /snippet -->

`v0.8.0` is a tag object that points at a commit. `v0.9.0` is a bare ref to a commit: a lightweight tag. Nobody on the team ran `git tag`; the release was created for a tag that did not exist, and the platform created the tag at the tip of the default branch at that moment.

<!-- snippet: ex3/x22-release-drift/02-what-the-tag-names -->
```text
$ git cat-file -t v0.8.0
tag
$ git cat-file -t v0.9.0
commit
$ git log --oneline v0.9.0..origin/main
f906661 Double the default chunk size
8864ccc Reject an overlap that is not smaller than the size
$ git tag --contains 8864ccc
$ git grep -n "overlap must be smaller" v0.9.0 -- chunker/split.py
[exit status: 1]
```
<!-- /snippet -->

The tag names `e3977e2`. The fix, `8864ccc`, was merged afterwards: it is in `v0.9.0..origin/main`, no tag contains it, and the file at `v0.9.0` has no such check. The release notes describe a commit that the tag does not include.

<!-- snippet: ex3/x22-release-drift/03-describe -->
```text
$ git describe origin/main
v0.8.0-3-gf906661
$ git describe --tags origin/main
v0.9.0-2-gf906661
$ git describe v0.9.0
v0.8.0-1-ge3977e2
```
<!-- /snippet -->

`git describe` uses annotated tags unless `--tags` is given, so the build machine sees `v0.8.0` as the nearest tag.

<!-- snippet: ex3/x22-release-drift/04-correct -->
```text
# A published tag does not move. A new annotated tag names the commit that has the fix.
$ git tag -a v0.9.1 -m 'chunker 0.9.1: reject an overlap that is not smaller than the size' 8864ccc
$ git push origin v0.9.1
To ../../server/chunker.git
 * [new tag]         v0.9.1 -> v0.9.1
$ git ls-remote --tags origin
4d9c3171a7bbba36bdc15f0ed9e207b3a7129f73	refs/tags/v0.8.0
6258ae58f09df0c7a5d3223696e2c5571055981a	refs/tags/v0.8.0^{}
e3977e26fc5a84c42fe19c269acf27278d432306	refs/tags/v0.9.0
722c900943b34917c67b3fef3d60089769662f37	refs/tags/v0.9.1
8864ccc37d0394a7f4b18d6e0d9c96a04cafe699	refs/tags/v0.9.1^{}
$ git describe 8864ccc
v0.9.1
$ git describe origin/main
v0.9.1-1-gf906661
```
<!-- /snippet -->

The GitHub half, written and not run:

```bash
gh release create v0.9.1 --verify-tag --title "v0.9.1" --notes "Rejects an overlap that is not smaller than the chunk size."
gh release edit v0.9.0 --notes "Does not contain the overlap check. Use v0.9.1."
```

**Reasoning.** A tag is Git data; a release is a GitHub object that points at a tag name, and creating a release can create the tag (Chapter 15, section 15.12). The published `v0.9.0` must not move: customers and caches have fetched it, and a tag that moves is a supply-chain problem (Chapter 14B, section 14B.11). A new annotated tag under a new name is the low-risk correction. It names the fix commit, not the tip of `main`, because the tip also contains "Double the default chunk size", a behavior change that nobody decided to release.

**Common mistakes.** `git tag -f v0.9.0` and a forced push of the tag. Deleting the release with `--cleanup-tag`. Tagging `origin/main` without reading what else it contains. Telling the build machine to use `--tags` and stopping there, which fixes the label and not the content.

**Expert approach.** Create and push the annotated tag first, then the release with `--verify-tag`, which turns a missing tag into an error. Restrict who may create `v*` tags with a tag ruleset, and use immutable releases for anything you ship. The chapter marks one point as unverified: that a tag created through the release interface is lightweight is an inference from the CLI help, which Lab 25.1 has you check. Reference: Chapter 14B, sections 14B.8, 14B.11 and 14B.12; Chapter 15, section 15.12; Chapter 18, section 18.12.

### Solution 22.6: Auto-merge did what it was told

**Solution.**

1. No rule was broken. Auto-merge merges "after all required reviews and status checks pass": one approval existed and was not dismissed, and `ci` was green on the latest commit. Whether a commit pushed after the approval lands unreviewed is decided by the stale-approval settings, not by auto-merge.
2. "Auto-merge is disabled if someone without write permissions pushes new changes to the head branch or switches the base branch."
3. The option "is shown only on pull requests that cannot be merged immediately". With no rule there is no unmet requirement and nothing to wait for. (It must also be enabled for the repository.)
4. `--match-head-commit` merges only if the head is the given commit. It is the terminal's answer to the hijack problem: you state which commit you mean.

**Reasoning.** Auto-merge is a stored instruction that waits for *required* things only (Chapter 17, section 17.10). It adds no review requirement of its own.

**Common mistakes.** Blaming auto-merge for a missing review setting. Enabling auto-merge on a deploying branch before deciding about stale approvals. Expecting it to wait for optional checks.

**Expert approach.** Decide the stale-approval settings first, then allow auto-merge. Reference: Chapter 17, sections 17.5, 17.10 and 17.16.

### Solution 22.7: "The approved commit is not on main"

**Solution.**

1. No. The repository allows only squash merging. A squash merge creates one new commit with one parent: the content arrives, the approved commit does not, and `--is-ancestor` exits with 1 by design.
2. From `refs/pull/12/head` in the base repository. The namespace is read-only: nobody can rewrite or delete it with Git, and it outlives the head branch.
3. Rebuild the test merge and compare trees:

<!-- snippet: ex3/x22-which-method/06-audit -->
```text
# History Y: was the approved head commit what landed? Rebuild the test merge and compare trees.
$ git -C Y merge-tree --write-tree 461e56e~1 39301d4
34ad3cae8224f2849427353fa10c60eb14cc3e30
$ git -C Y rev-parse 461e56e^{tree}
34ad3cae8224f2849427353fa10c60eb14cc3e30
$ git -C Y diff --stat 39301d4 461e56e
 config/chunking.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

   Merging the approved head `39301d4` into the parent of the squash commit gives the tree `34ad3ca`, which is the tree of `461e56e`. The only difference between the approved head and what landed is the change that `main` already had. This proves that the content that landed is the approved head merged with `main` as it was. It does not prove who approved, or that the approval was given for that head and not for an earlier one: that comes from the review record and from settings such as dismissal of stale approvals.
4. Not as configured. Under squash and rebase, commit IDs are not stable evidence; only the merge-commit method satisfies "the reviewed commit is the deployed commit" literally. The team would give up its linear, one-commit-per-change history, or it negotiates the wording of the rule to "content equality, shown by the tree comparison".
5. The author of the squash commit. Locally it is Asha because she ran `git commit`. For GitHub the chapter marks the author of a squash commit as unverified in the documentation; the committer of what lands is GitHub.

**Reasoning.** Squash transfers content without ancestry (Chapter 17, sections 17.8 and 17.9). The evidence chain an auditor can follow is: pull request, head ref, tree equality, review record.

**Common mistakes.** Suspecting a force push because an ID is missing. Comparing the tree of the head commit with the tree of the squash commit directly: they differ whenever `main` had moved, which is the normal case. Promising an auditor ID equality in a squash-only repository.

**Expert approach.** Know before the audit which statement your merge method can support, and keep the pull request number in every squash commit's subject, as the `(#12)` here does: it is the only link from `main` back to the review. Reference: Chapter 17, sections 17.2, 17.8, 17.9 and 17.20.

---

## Module 23

### Solution 23.1: Five predicates

**Solution.**

| # | Push | Result |
|---|---|---|
| 1 | fast-forward of `main` by an ordinary commit | accepted |
| 2 | `main` gains a merge commit | rejected by require linear history: `old..new` contains a commit with two parents |
| 3 | amended `main`, forced | rejected by block force pushes: the old tip is not an ancestor of the new one |
| 4 | delete `main` | rejected by restrict deletions: the new ID is all zeros |
| 5 | create `v2.0.0` | accepted: the tag ruleset has no restrict creations rule |
| 6 | move `v1.9.0` | rejected by restrict updates (an existing ref moves) and, when the old commit is not an ancestor of the new one, by block force pushes |
| 7 | new branch `feature/x` | accepted: no ruleset targets it |

`! [remote rejected]` means the server said no. `! [rejected]` is your own Git refusing before anything was sent, for example a non-fast-forward without a force option. `--force-with-lease`, like `--force`, only switches off client checks; the rule is evaluated on the server, which neither flag reaches.

**Reasoning.** Every push proposes ref updates: a ref name, the old object ID, the new one. These five rules are predicates on those three values, which is why a plain `pre-receive` hook can imitate them (Chapter 18, section 18.2). The other rules ask about GitHub objects and need the platform.

**Common mistakes.** Expecting case 3 to be rejected by the linear-history rule: the amended commit has one parent. Expecting case 5 to be rejected "because tags are protected": creation is open unless you restrict it. Thinking a force flag can override a server rule.

**Expert approach.** Translate any proposed rule into "which (old, new, ref) triples does it refuse?" before enabling it. Lab 23.1 has a hook that does exactly this, with real transcripts. Reference: Chapter 18, sections 18.2, 18.11 and 18.12.

### Solution 23.2: Which branches does the pattern cover?

**Solution.**

<!-- snippet: ex3/x23-fnmatch/02-answers -->
```text
$ /usr/bin/ruby match.rb 'release/*' main release/2.4 release/2.4/hotfix-812 releases hotfix-812 hotfix/812 dependabot/uv/main-1f2e
release/*        main                         -
release/*        release/2.4                  match
release/*        release/2.4/hotfix-812       -
release/*        releases                     -
release/*        hotfix-812                   -
release/*        hotfix/812                   -
release/*        dependabot/uv/main-1f2e      -
$ /usr/bin/ruby match.rb 'release/**/*' main release/2.4 release/2.4/hotfix-812 releases hotfix-812 hotfix/812 dependabot/uv/main-1f2e
release/**/*     main                         -
release/**/*     release/2.4                  match
release/**/*     release/2.4/hotfix-812       match
release/**/*     releases                     -
release/**/*     hotfix-812                   -
release/**/*     hotfix/812                   -
release/**/*     dependabot/uv/main-1f2e      -
$ /usr/bin/ruby match.rb 'hotfix*' main release/2.4 release/2.4/hotfix-812 releases hotfix-812 hotfix/812 dependabot/uv/main-1f2e
hotfix*          main                         -
hotfix*          release/2.4                  -
hotfix*          release/2.4/hotfix-812       -
hotfix*          releases                     -
hotfix*          hotfix-812                   match
hotfix*          hotfix/812                   -
hotfix*          dependabot/uv/main-1f2e      -
$ /usr/bin/ruby match.rb '*' main release/2.4 release/2.4/hotfix-812 releases hotfix-812 hotfix/812 dependabot/uv/main-1f2e
*                main                         match
*                release/2.4                  -
*                release/2.4/hotfix-812       -
*                releases                     match
*                hotfix-812                   match
*                hotfix/812                   -
*                dependabot/uv/main-1f2e      -
$ /usr/bin/ruby match.rb '**/*' main release/2.4 release/2.4/hotfix-812 releases hotfix-812 hotfix/812 dependabot/uv/main-1f2e
**/*             main                         match
**/*             release/2.4                  match
**/*             release/2.4/hotfix-812       match
**/*             releases                     match
**/*             hotfix-812                   match
**/*             hotfix/812                   match
**/*             dependabot/uv/main-1f2e      match
$ /usr/bin/ruby match.rb '*/*' main release/2.4 release/2.4/hotfix-812 releases hotfix-812 hotfix/812 dependabot/uv/main-1f2e
*/*              main                         -
*/*              release/2.4                  match
*/*              release/2.4/hotfix-812       -
*/*              releases                     -
*/*              hotfix-812                   -
*/*              hotfix/812                   match
*/*              dependabot/uv/main-1f2e      -
```
<!-- /snippet -->

1. `release/2.4/hotfix-812`. Nothing tells them: a pattern that does not match leaves the branch unprotected without any message. `release/**/*` covers both levels.
2. `**/*` for every branch; `*` alone matches no branch with a slash in its name. For the default branch the REST API has the special target `~DEFAULT_BRANCH`, which follows a renamed default branch; a second special target, `~ALL`, also exists.
3. `gh ruleset check <branch>`. According to its help text the branch does not need to exist, so you can test a name before anybody creates it.

**Reasoning.** GitHub names the function and the flag. With `FNM_PATHNAME`, `*` does not match a directory separator, and `**/` matches any number of directories (Chapter 18, section 18.3). The transcript calls that function with the Ruby that macOS ships; no Git is involved.

**Common mistakes.** Reading `*` as "anything", as in a shell without path semantics. Assuming `hotfix*` covers `hotfix/812`. Trusting a pattern because the settings page accepted it.

**Expert approach.** After every change to a target, run `gh ruleset check` for one name that must match and one that must not. Reference: Chapter 18, sections 18.3 and 18.16.

### Solution 23.3: Review this ruleset

**Solution.**

| # | Problem | Consequence | Change | Section |
|---|---|---|---|---|
| 1 | Target `release/*` | `release/2.4/hotfix-812` is unprotected | `release/**/*`, then `gh ruleset check` | 18.3 |
| 2 | Only `squash` is allowed, and the repository has squash merging switched off | "the merge will be blocked": no method works | enable squash merging, or allow a method the repository offers | 18.7 |
| 3 | Two approvals in a team of two | authors cannot approve their own pull requests, so two approvals can never be reached: a lock-out | one approval | 17.4, 18.20 |
| 4 | Neither stale-approval option is on | approve, push one more commit, merge: an unreviewed commit lands | `dismiss_stale_reviews_on_push: true` | 17.5, 18.7 |
| 5 | Code owner review is required, but `release/2.4` was cut before `CODEOWNERS` existed | owners are read from the base branch; a path with no owner requires nothing | add the file to the release branches | 19.3, 19.6, 19.7 |
| 6 | The required check `build` comes from a workflow with a `paths:` filter | a pull request outside `chunker/**` never gets the check; it stays pending | start the workflow on every pull request and gate inside it; require one job that always reports | 18.8 |
| 7 | No `deletion` rule | a release branch can be deleted by anyone with Write | add restrict deletions | 18.6, 18.11 |
| 8 | Loose status checks | `build` can be green against an older release branch | strict, on a low-traffic branch | 18.8 |
| 9 | The check has no expected source | anyone with write access can report a status named `build` | pin the check to its GitHub App | 18.8 |

Problems 2 and 3 each block every merge on their own. The team has probably not merged a release pull request since the ruleset was activated, or somebody is on a bypass list.

2. No. `bypass_actors` is returned only to callers with write access to the ruleset. With read access its absence says nothing about the list.
3. Under a ruleset it is false: a ruleset applies to everyone, administrators included, except the actors on its bypass list. The administrator can edit or disable the ruleset, which is a deliberate and recorded act. Under a classic rule it was true by default: restrictions do not apply to people with admin permissions unless "Do not allow bypassing the above settings" is selected.

**Reasoning.** Read a ruleset in four passes: which refs (target), who is excepted (bypass), which rules, and how each rule meets the repository's other settings. The parameter names are those of Chapter 18, sections 18.7 and 18.18. The form of a named-branch target in the REST schema is not shown in the textbook, which is why the exercise states the target in words.

**Common mistakes.** Reviewing the rules and not the target. Missing interactions with repository settings and with files on the base branch. Reading a missing key in an API response as an empty list.

**Expert approach.** For every rule ask "what would have to be true in this repository for this rule to be satisfiable, and by whom?". Then open one test pull request against a release branch before trusting the ruleset. Reference: Chapter 18, sections 18.3 to 18.8, 18.14, 18.16 and 18.20; Chapter 19, sections 19.3 and 19.6.

### Solution 23.4: Layers

**Solution.**

1. From the three layers that are in force: no force pushes; a pull request with 2 approvals (the most restrictive of 1, 2 and 1) and code owner review; the check `ci`, strict; linear history. Not signed commits: ruleset B is disabled and protects nothing.
2. No force pushes (organization), a pull request with 1 approval, code owner review if the administrator left it in A, and linear history (classic rule). The administrator could not touch the organization ruleset: only organization owners can edit it, and a repository ruleset can add to it and never subtract. The administrator could have deleted the classic rule.
3. The two active rulesets, on the `/rules` page, the Rulesets page and with `gh ruleset list` or `gh ruleset check main`. Not ruleset B: a disabled ruleset is not on the `/rules` page. Not the classic rule: it is visible to people with admin access.
4. **Rebase and merge** cannot satisfy the rule, because its commits are created without signature verification. Merge commits were already excluded by the linear-history rule. That leaves squash, and squash merges are blocked for every pull request whose head branch contains an unsigned commit.
5. The organization ruleset and ruleset A bind them: a ruleset applies to administrators unless they are on its bypass list. The classic rule does not, because its bypass setting is at the default. The direct push is rejected by the pull request rules of the rulesets.

**Reasoning.** "A ruleset does not have a priority." All active rulesets that target a ref, and the classic rule that matches it, are aggregated, and for each rule the most restrictive version applies (Chapter 18, section 18.4).

**Common mistakes.** Looking for the ruleset that "wins". Loosening one layer and concluding the platform is broken. Forgetting the classic rule because it is on a different settings page. Treating a disabled ruleset as partly effective.

**Expert approach.** List every layer before changing any: `gh ruleset check <branch>`, the `/rules` page, then the classic rule through an administrator or `gh api repos/ORG/REPO/branches/<branch>/protection`. Keep each rule in one place. Reference: Chapter 18, sections 18.4, 18.5, 18.10, 18.14 and 18.16.

### Solution 23.5: Eight paths, one CODEOWNERS file

**Solution.**

1. Last matching line decides:

| Path | Deciding line | Requested |
|---|---|---|
| `.github/workflows/deploy.yaml` | `*.yaml` | platform |
| `services/ranker/api.py` | the second `/services/ranker/` line | SRE only |
| `services/ranker/config/prod.yaml` | `*.yaml` | platform |
| `libs/eval/metrics/bleu.py` | `*` | platform |
| `libs/eval/fixtures/gold.jsonl` | `*` | platform |
| `docs/runbook.md` | `*` | platform |
| `infra/terraform/main.tf` | `/infra/terraform/` with no owner | nobody: the line removes ownership |
| `services/billing/invoice.py` | `/services/billing/` | nobody: the team lacks write access of its own, so no code owner is assigned |

2. The faults:
   - `/.github/` is the first line and `*` follows it. `*` matches everything and is later, so the administrators own nothing. General patterns go first.
   - `*.yaml` is a general pattern in last place: it takes every YAML file, including the workflows and the ranker's configuration, away from the specific owners.
   - Two lines for `/services/ranker/`. Owners of one pattern go on one line; otherwise only the later line counts.
   - `/libs/eval/*` covers files directly in that directory, not nested ones. The directory form is `/libs/eval/`.
   - `!` negation does not work in CODEOWNERS.
   - `/Docs/` does not match `docs/`: paths are case sensitive.
   - `@northwind-ml/billing` has no write access as a team. Members' access through the base permission does not count.
   - `/infra/terraform/` has no owner, so any user with write access can approve changes there. For infrastructure code that is more likely an accident than a decision.
   - As a result, `CODEOWNERS` itself and `.github/workflows/` are unowned or owned by the wrong team.
3. One rewrite:

```text
# General first.
*                             @northwind-ml/platform

# Components.
/services/ranker/             @northwind-ml/ranking @northwind-ml/sre
/services/billing/            @northwind-ml/billing
/libs/eval/                   @northwind-ml/ml-eval
/libs/eval/fixtures/          @northwind-ml/data
/docs/                        @northwind-ml/docs
/infra/terraform/             @northwind-ml/platform

# Last: the files that control review and automation.
/.github/                     @northwind-ml/repo-admins
```

   Grant `@northwind-ml/billing` the Write role as a team, or its line stays without effect. The `*.yaml` line is gone: it had the same owner as `*` and only did damage. With two teams on the ranker line, an approval from either one suffices; "both must approve" needs the required reviewers rule.
4. The pull request is judged by the file on its base branch, the old one. It changes `.github/CODEOWNERS`, which the old file gives to the platform team through `*`. So the platform team approves, if a rule requires code owner review at all.
5. `gh api --method GET repos/ORG/REPO/codeowners/errors -f ref=my-branch`, which lists the errors of the file as it is on the branch. The command uses a documented endpoint and was not run here.

**Reasoning.** For each path GitHub takes the last line whose pattern matches. The patterns follow most gitignore rules, with documented exceptions, and owners need explicit write access (Chapter 19, sections 19.4 and 19.5). GitHub's matcher cannot be run locally, so these answers are reasoned from the documented rules; the chapter explains why `git check-ignore` would give a different answer for `dir/*`.

**Common mistakes.** Reading the file top-down and stopping at the first match. Believing a longer pattern is "more specific" and therefore wins. Expecting your edit of the file to apply to the pull request that carries it.

**Expert approach.** Read the file bottom-up for the path in question. After a change, confirm with the errors endpoint and by looking at the owner GitHub shows for two or three real files. Reference: Chapter 19, sections 19.3 to 19.8, 19.11 and 19.12.

### Solution 23.6: Four pull requests that will not merge

**Solution.**

1. Required status check never reported. The workflow was skipped by its path filter, and checks of a skipped workflow stay pending. Confirm with `gh pr checks N --required` and `git diff --name-only origin/main...HEAD`. The durable repair is to let the workflow start on every pull request and decide inside it which jobs do work, with one job that always reports. Note that the pull request that changes the workflow file is outside the filter too, and the bypass list is empty: it can land only together with a change that the filter matches, or after a deliberate, recorded edit of the ruleset.
2. Approval of the most recent push. Asha pushed last, so her approval cannot be the one this option asks for, and Ravi, as author, cannot approve. A third person must review. Confirm with `gh pr view N --json reviewDecision,latestReviews`.
3. Code owner review. The only owner of `/scripts/` is the author, and authors cannot approve their own pull requests; Ravi's approval counts toward the number and is not a code owner's. The chapter marks this as an inference from two documented rules, which Lab 23.2 lets you observe. Unblock it by having another person open the pull request, so that Asha can approve as owner. Then make a team the owner.
4. Strict status checks. The branch no longer contains the tip of `main`, so it is not up to date, although its own check is green.

The local test for case 4 is `git merge-base --is-ancestor origin/main HEAD` after a fetch: exit status 1 means "not up to date". **Update branch** creates a new head commit, so `ci` must pass again on it, and the approval is dismissed as stale because the diff changed.

**Reasoning.** `BLOCKED` says a rule is unmet, not which one. Work from the rules to the cause: checks on the newest commit, reviews after the last change, owners of each changed path, ancestry (Chapter 18, section 18.17).

**Common mistakes.** Re-running workflows in case 1: there is no run to re-run. Asking Asha to approve again in case 2. Adding more non-owner approvals in case 3. In case 4, reading a green check as "ready".

**Expert approach.** Use the nine steps of section 18.17 as a checklist, with one local Git question per rule, before you ask an administrator. Reference: Chapter 17, sections 17.4 and 17.5; Chapter 18, sections 18.7, 18.8 and 18.17; Chapter 19, section 19.6.

### Solution 23.7: Protect a monorepo

**Solution.** One defensible design. Others pass the rubric too.

| Ruleset | Target | Rules | Bypass |
|---|---|---|---|
| `main` (branch) | `~DEFAULT_BRANCH` | restrict deletions; block force pushes; linear history; pull request with 1 approval, stale approvals dismissed, code owner review, squash only; one required check `ci` | the repository admin role in `pull_request` mode, for an on-call merge that still leaves a pull request |
| release branches (branch) | `release/**/*` | restrict deletions; block force pushes; pull request with 1 approval and code owner review; `ci`, strict | empty |
| release tags (tag) | `v*` | restrict creations, updates and deletions; block force pushes | the release bot's GitHub App, mode `always` |
| large files (push) | the whole repository and its fork network | restrict file size; restrict extensions such as `*.ckpt`, `*.safetensors`, `*.parquet` | empty |

- **Strict or loose on `main`.** With twelve-minute CI and thirty merges a day, strict checks produce the race the team already complains about. A merge queue would solve it, but in a private repository it needs Enterprise Cloud. On the Team plan the choice is: loose checks, a `main` workflow on every merge, and a fast revert policy; or strict checks with auto-merge and the waiting. State which you chose and its cost.
- **CODEOWNERS.** Teams, not people; general lines first; `/.github/` last, owned by the repository administrators; every owning team holds Write as a team.
- **Dependabot.** Not on a bypass list. Its pull requests pass the same checks and review.
- **Rollout.** Evaluate mode belongs to Enterprise Cloud. Create each ruleset Disabled, read `gh ruleset check` for one branch that must match and one that must not, open a test pull request, then switch to Active.
- **Deliberately not done.** No signed-commit rule (it costs every contributor and bot a key and blocks squash merges of branches with unsigned commits). No `exempt` bypass entries (they leave no trace). No individual people on bypass lists.

**Rubric** (2 points each, 20 in total):

1. Uses `~DEFAULT_BRANCH` or a tested pattern, and a `**` form for release branches.
2. Protects tags separately, with a bypass entry for the bot that is an app, not a person.
3. Blocks deletions and force pushes on every deployed branch.
4. Chooses a merge method and names what it gives up.
5. Requires one stable check name and addresses skipped workflows.
6. Makes an explicit strict-or-loose decision from the numbers given, and notices the merge queue's plan gate.
7. Closes the approve-then-push loophole, or says why not.
8. Keeps bypass lists short, made of roles, teams or apps, with a mode for every entry.
9. Describes a rollout that tests before enforcing.
10. States costs, and at least two things the design does not do.

**Reasoning.** Each element answers one incident class from Chapters 17 to 19; the plan gates decide what is available (Chapter 18, section 18.15).

**Common mistakes.** Copying the worked design of section 18.18 without its context (six engineers, a few merges a day). Proposing a merge queue or Evaluate mode on a plan that does not have them. Protecting `main` and forgetting tags, although production deploys from tags.

**Expert approach.** Start from what must never happen (a moved release tag, a rewritten `main`, an unreviewed deploy), map each to one rule, then remove every rule that maps to nothing. Reference: Chapter 18, sections 18.3 to 18.8, 18.12, 18.13, 18.15 and 18.18; Chapter 19, sections 19.8 and 19.9.

### Solution 23.8: "Main is protected. How did a force push get through?"

**Solution.**

1. The ruleset did not apply. Its targets are `main-*` and `release/*`; `main-*` needs the characters `main-` and does not match the name `main`. The classic rule did apply to `main` and forbids force pushes, but it did not bind this actor: under classic protection, restrictions do not apply to people with admin permissions unless "Do not allow bypassing the above settings" is selected.
2. `main` was protected only by a classic rule that administrators are exempt from by default, because the ruleset meant to protect it has a target pattern that does not match; an administrator then force-pushed a local `main` that lacked the four newest commits.
3. `--force-with-lease` checks that the server's ref is where your remote-tracking branch last saw it. That is a statement about `origin/main`, not about what your local branch contains. If the administrator, or an editor in the background, had fetched after 16:40, `origin/main` matched the server and the lease held, while the local `main` still did not contain the four merges. `--force-if-includes` adds the missing condition.
4. Nothing supports it. The audit log names the administrator as the actor of a `protected_branch.policy_override`, and the administrator describes running the command. To close the question, read the audit log entry for the credential that pushed, and ask the administrator whether the time and machine match.
5. Tonight: create an active branch ruleset on `~DEFAULT_BRANCH` with block force pushes and restrict deletions and an empty bypass list, then run `gh ruleset check main`; or, as a stopgap, select the bypass restriction on the classic rule. Verify that the restored `main` contains the four merges. This week: correct the targets of "protect main" (`~DEFAULT_BRANCH`, `release/**/*`); convert the classic rule so that each rule lives in one place; set `push.useForceIfIncludes` in the team's configuration and agree that shared branches are never force-pushed.
6. Not without first editing or disabling the ruleset, or adding themselves to its bypass list, each of which is a deliberate change of settings. A bypass in `always` or `pull_request` mode is recorded; an `exempt` entry is not, which is why you do not add one.

**Reasoning.** The chapter's four questions for exactly this incident: was the ruleset active, did it target that branch name, was the actor a bypass actor or an administrator under a classic rule, and was the rule in the ruleset at all (Chapter 18, sections 18.2, 18.3, 18.5 and 18.14). The event name `protected_branch.policy_override` is from the Phase 0 report, as the chapter says.

**Common mistakes.** Stopping at "there is an active ruleset". Reading "`--force-with-lease` is the safe one" as "cannot remove commits". Reaching for the dramatic explanation, a stolen token, when a default setting explains everything.

**Expert approach.** Evidence first, in the order target, enforcement, actor, rule. Then close both gaps, the pattern and the classic default, because either alone would have allowed it. Reference: Chapter 12, section 12.8; Chapter 18, sections 18.3, 18.5, 18.14, 18.16 and 18.19.

---

## Module 24

### Solution 24.1: Covered or not covered?

**Solution.** Covered: 1, 2, 3, 4, 5 and 9. Everything inside the object is signed bytes: tree, parents, author, committer, dates and message, and through the tree and parent IDs every file and every ancestor. Not covered: 6, 7, 8 and 10.

What someone with push access and no private key can still do: put your signed commit on any branch, in any repository or fork (6, 7); present it as reviewed or unreviewed, since reviews live in GitHub's database (8); and serve your signed tag object under another ref name, for example as `v9.9.9` while the object inside says `tag v1.0.0` (10), which is why a careful verifier compares the name in the object with the name it asked for. They cannot change a file, the message or a parent without the signature turning bad.

Two of the covered items need a caution. Author (3) and dates (4) are covered as bytes, but they remain the signer's own claims: a signature does not prove that the author line names the signer, or when the commit was made.

**Reasoning.** A signature is computed over the bytes of one object and stored inside it. Refs are not objects (Chapter 14B, sections 14B.15 and 14B.17).

**Common mistakes.** "Signed, therefore on the right branch." "Signed, therefore written by the person in the author field." "Signed, therefore reviewed."

**Expert approach.** Ask separately: has the object changed, which key signed it, do I trust that key for that person, and does the object belong where I found it? Only the first two are answered by the signature. Reference: Chapter 14B, sections 14B.15 to 14B.18.

### Solution 24.2: Five commits, five claims

**Solution.** The transcripts are from a volatile demo: keys and IDs differ on every run, the letters do not.

<!-- snippet: ex3/x24-signature-predict/02-states -->
```text
$ git log --reverse --format='%G?  author=%ae  signer=%GS  %s' main..feature/retry
G  author=you@example.com  signer=you@example.com  c1 add retry config
N  author=you@example.com  signer=  c2 raise retries
U  author=ravi@example.com  signer=  c3 raise retries again (Ravi, his key)
G  author=asha@example.com  signer=you@example.com  c4 written by you, author field says Asha
G  author=asha@example.com  signer=asha@example.com  c5 lower retries (Asha, her key)
```
<!-- /snippet -->

1. c1 `G`, signer you. c2 `N`. c3 `U`: the signature is mathematically good, but Ravi's key is not in the allowed-signers file, so nobody you trust is attached to it and there is no signer to print. c4 `G`, signer you, although the author field says Asha. c5 `G`, signer Asha.

<!-- snippet: ex3/x24-signature-predict/03-verify-commit -->
```text
$ git verify-commit feature/retry~2 2>&1 | cut -c1-36
Good "git" signature with ED25519 ke
No principal matched.
$ git verify-commit feature/retry~2 > /dev/null 2>&1
[exit status: 1]
$ git verify-commit feature/retry~1 > /dev/null 2>&1
[exit status: 0]
$ git verify-commit feature/retry~3 > /dev/null 2>&1
[exit status: 1]
```
<!-- /snippet -->

2. c2: 1. c3: 1, with the message that no principal matched. c4: 0. That is the surprise: Git verifies a signature against the list of trusted keys and does not compare the signer with the author line.

<!-- snippet: ex3/x24-signature-predict/04-merge -->
```text
$ git switch -q -c integration main
$ git merge --verify-signatures --no-ff -m "Merge feature/retry" feature/retry > /dev/null 2>&1
[exit status: 0]
$ git log --format='%G?  %s' -6
N  Merge feature/retry
G  c5 lower retries (Asha, her key)
G  c4 written by you, author field says Asha
U  c3 raise retries again (Ravi, his key)
N  c2 raise retries
G  c1 add retry config
```
<!-- /snippet -->

3. It succeeds. `--verify-signatures` checks the tip commit of the side branch, c5, and brings c2 (`N`) and c3 (`U`) along underneath. The merge commit itself is `N`, because nothing told Git to sign it.

<!-- snippet: ex3/x24-signature-predict/05-rebase -->
```text
# main gains one commit, then you rebase feature/retry onto it: first plainly, then with -S.
$ git switch -q main && printf '# chunker\n' > README.md && git add README.md && git commit -q -S -m 'Add README'
$ git switch -q feature/retry
$ git rebase -q main
$ git log --reverse --format='%G?  author=%ae  signer=%GS  %s' main..feature/retry
N  author=you@example.com  signer=  c1 add retry config
N  author=you@example.com  signer=  c2 raise retries
N  author=ravi@example.com  signer=  c3 raise retries again (Ravi, his key)
N  author=asha@example.com  signer=  c4 written by you, author field says Asha
N  author=asha@example.com  signer=  c5 lower retries (Asha, her key)
$ git rebase -q --force-rebase -S main
$ git log --reverse --format='%G?  author=%ae  signer=%GS  %s' main..feature/retry
G  author=you@example.com  signer=you@example.com  c1 add retry config
G  author=you@example.com  signer=you@example.com  c2 raise retries
G  author=ravi@example.com  signer=you@example.com  c3 raise retries again (Ravi, his key)
G  author=asha@example.com  signer=you@example.com  c4 written by you, author field says Asha
G  author=asha@example.com  signer=you@example.com  c5 lower retries (Asha, her key)
```
<!-- /snippet -->

4. `N` five times. A rebase writes new commits, and a signature cannot be carried over to a new object.
5. `G` five times, each signed by you, including the commits whose author is Asha or Ravi. A rewritten commit is signed only if the person running the command signs, and then with that person's key.
6. The signature on c4 proved that the holder of your key created that exact object. A policy check that compares the signer's principal with the author's address catches it (the one-line check of section 14B.18); on GitHub, Asha's vigilant mode makes it visible.

**Reasoning.** `%G?` reports a signature's state under *your* trust settings; `%GS` reports the principal the key is listed for. Neither says anything about the author field (Chapter 14B, sections 14B.16 to 14B.18).

**Common mistakes.** Reading `U` as "bad". Reading `G` as "the author signed". Believing `git merge --verify-signatures` verifies a branch. Expecting signatures to survive a rebase, a cherry-pick or an amend.

**Expert approach.** Print signer and author side by side for a range and compare them mechanically. Decide whether rebased history is allowed on signed branches, and by whom, before you require signatures. Reference: Chapter 14B, sections 14B.16, 14B.17 and 14B.18.

### Solution 24.3: What would GitHub display?

**Solution.** By the table of Chapter 21B, section 21B.6:

| Commit | Display | Why |
|---|---|---|
| c1 | Verified | signed by your registered signing key |
| c2 | no badge | unsigned, and you have not enabled vigilant mode |
| c3 | Unverified | signed, but the signature cannot be verified: Ravi's key is on no account |
| c4 | Partially verified | signed and verified for the committer (you), but the commit has an author who is not the committer and who has enabled vigilant mode |
| c5 | Verified | signed by Asha's registered key; she is author and committer |

1. c2 becomes Unverified: with vigilant mode, any unsigned commit attributed to you is flagged.
2. It tells the reviewer that a verified key signed the commit and that the person named as author, who signs her work, did not sign it. Without Asha's vigilant mode it would have shown Verified, beside her name.
3. No. A signing key is a separate registration, even for the same key file: `gh ssh-key add ~/.ssh/id_ed25519_signing.pub --type signing --title "laptop signing key"`.
4. Lab 24.3 pushes commits of these kinds to your practice repository.

**Reasoning.** GitHub verifies against keys registered on accounts and attributes commits by matching email addresses. Without vigilant mode, silence means nothing: an unsigned forgery looks like every other unsigned commit (Chapter 21B, sections 21B.5 and 21B.6). This is a prediction from documentation; nothing here was pushed to GitHub.

**Common mistakes.** Expecting "Unverified" on every unsigned commit. Assuming an authentication key verifies signatures. Enabling vigilant mode before signing on every machine, which flags your own work.

**Expert approach.** Treat the badge as a display of one fact, which key signed, and enable vigilant mode on every account that signs, because it is the cheap defense against impersonation. Reference: Chapter 21B, sections 21B.5 and 21B.6.

### Solution 24.4: Four questions from a team that has just required signatures

**Solution.**

1. When GitHub evaluates whether the pull request can merge, it checks the commits introduced by the test merge, "including commits from the head branch". Unsigned commits on the head branch block a squash merge even though GitHub would sign the final squash commit. Repair: rebase the commits with signing and force-push the branch. Chapter 18, section 18.10.
2. **Rebase and merge** creates its commits "without commit signature verification": GitHub writes modified commits and does not hold the contributors' private keys. The documented workaround is to rebase and merge locally and push, which requires someone who is allowed to push to `main` and who signs with their own key. Chapter 17, section 17.8; Chapter 18, section 18.10.
3. No. Since 10 December 2024 GitHub keeps a persistent verification record: once verified, a commit stays verified in its repository network when the key is later rotated, revoked or expired. Chapter 21B, section 21B.6. Local verification is a different matter: it depends on the allowed-signers file of whoever verifies (Chapter 14B, section 14B.17).
4. No, and for the same reason. GitHub does not re-verify old commits when a key's state changes, so commits that were verified when they were pushed stay Verified. Find them by date and by the audit log; the time of verification is exposed as `verified_at` in the REST API. Chapter 21B, section 21B.6.

**Reasoning.** The rule is evaluated on what a pull request introduces, the badge records a verification at one moment, and neither is recomputed when keys change.

**Common mistakes.** Enabling the rule without telling contributors, then discovering it through blocked pull requests. Treating persistent verification as a weakness to be worked around: it is what makes key rotation safe. Hunting for a thief's commits by badge.

**Expert approach.** Before enabling the rule, list which merge buttons survive it and who signs what; after a key theft, scope by time window and by pusher. Reference: Chapter 17, section 17.8; Chapter 18, section 18.10; Chapter 21B, sections 21B.6 and 21B.7.

### Solution 24.5: A signing policy for a team of eight

**Solution.** A model policy, in outline.

- **Format.** SSH signing (`gpg.format ssh`): everybody already has SSH keys and the trust file is plain text.
- **Keys.** One signing key per person and machine, with a passphrase, held in an agent or on a hardware key. Never copied between machines, never shared.
- **Local trust.** One allowed-signers file in the repository, reviewed like code, one line per key with `namespaces="git"`; `gpg.ssh.allowedSignersFile` points at it. Validity windows record when a key was in use.
- **GitHub.** Every public key is registered on its owner's account as a signing key. Everybody enables vigilant mode after signing works on all their machines.
- **Rule on `main`.** Either require signed commits, accepting that **Rebase and merge** becomes unusable and that unsigned commits on a head branch block squash merges; or do not require them and rely on review plus vigilant mode. State the choice and its cost.
- **Bots.** Dependabot signs its commits by default. The release bot acts as a GitHub App; what it creates through the platform is treated like any other change and goes through review.
- **Rotation and loss.** Rotation: add the new key, close the old key's validity window, keep the old line so that old signatures still verify locally. Lost laptop: remove the key from the account, add it to the revocation file, and review what was pushed with it since the loss by date and audit log.
- **Not claimed.** A signature does not show that a change is correct or reviewed, that the author field names the signer, or when the commit was made.

**Rubric** (2 points each, 16 in total): format chosen with a reason; private keys never shared and protected; a stated source of local trust; signing-key registration and vigilant mode; an explicit decision on the rule with its cost in merge methods; bots covered; rotation that keeps old signatures valid and a separate procedure for theft; a statement of what signing does not prove.

**Reasoning.** Signing needs one key; verifying needs a statement of whom you trust. Validity windows let you rotate without invalidating history, and they do not protect against a stolen key, because the thief chooses the commit date; the revocation file does, at the price of failing the honest signatures too (Chapter 14B, section 14B.17).

**Common mistakes.** One team key. Requiring signatures and forgetting the merge buttons. Rotating by deleting the old line from the trust file, which turns last year's history unverifiable locally. Presenting signing as proof of authorship or quality.

**Expert approach.** Write the policy around the questions an incident will ask: which key, whose, since when, and what did it sign? Reference: Chapter 14B, sections 14B.15 to 14B.18; Chapter 18, section 18.10; Chapter 21B, sections 21B.6 and 21B.7.

### Solution 24.6: Verified, and she was on a plane

**Solution.**

1. That GitHub created the commit. The chapter: commits made in the web interface are signed by GitHub with its own key, and that badge "says GitHub created the commit on behalf of a signed-in user, not that the user's key was involved".
2. Best fit: her session, or a token that acts as her, was used to create the commit on GitHub's side. It explains the web-flow signature, her name and avatar, and it has a candidate source in the OAuth app with the `repo` scope. A stolen signing key does not fit: the signature is not hers, and the key was on a switched-off laptop behind a passphrase. A local forgery by a colleague does not fit either: it would be unsigned, or signed with the colleague's key, not with GitHub's. One caution: the chapter states the GitHub signature for commits made in the web interface; whether a commit created through the API with an app's token carries it is not stated there, so let the audit log decide between session and token.
3. The record of the push on GitHub's side: the audit log and the repository's activity view record the authenticated account and, for a token, which token, with the server's own time. They do not depend on the dates written into the commit.
4. In this order: stop the export or revert the commit, which stops the data flow; revoke the OAuth app's authorization and her sessions and tokens, which stops the attacker; search the audit log for everything else that credential did; rotate what the export job and that account could reach; inform the people affected.
5. A ruleset on `main` that requires a pull request with an approval, so that no single account can change the branch alone, whatever interface it uses; and a review of authorized third-party apps with broad scopes. Signing alone would have changed nothing: the commit was signed and Verified, and a signed-commits rule accepts commits that GitHub signs.

**Reasoning.** Four questions hide in "who made this commit": who is displayed, who pushed, who signed, what is enforced. Here the display and the signature both point at GitHub acting for her account, so the investigation moves to who controlled the account (Chapter 21B, sections 21B.5 to 21B.8). Two-factor authentication protects the login, not a token or a session that already exists.

**Common mistakes.** "Verified, so it is hers." Arguing about commit timestamps instead of reading the server's record. Rotating her signing key, which was never involved. Leaving the OAuth app authorized while investigating.

**Expert approach.** Read the signature's key before the badge, then go to the audit log. Contain first, attribute second. Reference: Chapter 16, section 16.2; Chapter 21B, sections 21B.5 to 21B.8.

---

## Module 25

### Solution 25.1: Ask the CLI, not the browser

**Solution.** None of the seven commands changes anything on GitHub. The two `gh api` calls have no field flags and no `--method`, so they are sent as `GET`. `gh auth status` prints, per host, the active account, where its token is stored and the token's scopes, with the token masked.

- `{owner}` and `{repo}` are filled in from the repository of the current directory, which `gh` picks from your remotes; with a fork there are two candidates and `gh repo set-default` records which one to use. Point one command elsewhere with `-R OWNER/REPO`, or set `GH_REPO`.
- Your token has 5,000 requests per hour. An unauthenticated script has 60 per hour, per IP address, which on a shared runner is shared with every other job.
- `gh ruleset` can list, view and check. Creating and changing rulesets goes through the REST API with `gh api`.

**Reasoning.** `gh` is a client for GitHub's API that knows which repository you are in (Chapter 15, sections 15.16 and 15.17).

**Common mistakes.** Parsing the human-readable output in scripts instead of `--json` with `--jq`. Forgetting that `GH_TOKEN` in the environment takes precedence over the stored login. Running `gh` in a fork's clone without checking which repository it acts on.

**Expert approach.** In every new clone: `gh auth status`, `gh repo set-default --view`. In every script: `--json`, exit statuses, and an explicit repository. The commands were checked against `--help` of 2.88.1 and not run by the author. Reference: Chapter 15, sections 15.16 and 15.17.

### Solution 25.2: Which of these changes something?

**Solution.**

| # | Method | Changes something? | Label |
|---|---|---|---|
| 1 | GET | no | 🟢 |
| 2 | POST | it asks GitHub to create a pull request; the author wanted a filtered list | 🔴 |
| 3 | GET | no | 🟢 |
| 4 | PUT | yes: the ruleset is disabled and protects nothing | 🔴 |
| 5 | POST | no: it is a GraphQL query, a read | 🟢 |
| 6 | GET | no | 🟢 |
| 7 | DELETE | yes: the ruleset is gone | 🔴 |
| 8 | GET | no, but the answer is wrong | 🟢 |

1. Command 2. From the help text: "The default HTTP request method is `GET` normally and `POST` if any parameters were added", and to send parameters as a query string, "use `--method GET`". Command 3 is the corrected form.
2. Lists return 30 items per page, and without `--paginate` you get the first page. For the count, print one line per item across all pages and count the lines: `gh api --paginate repos/{owner}/{repo}/pulls --jq '.[].number' | wc -l`. Or collect the pages with `--paginate --slurp` and flatten them with `jq 'add | length'`, as Exercise 25.3 does offline. Whether `--slurp` can be combined with `--jq` in one `gh` call was not verified for 2.88.1, so pipe to `jq`.
3. POST: fields were added. It changes nothing: the fields are the query and its variables, and the query only reads.
4. It selects the REST API version. Without the header a request gets version `2022-11-28`.

**Reasoning.** The method is decided by the flags, not by your intention, and `gh api` with a writing method acts with all your permissions (Chapter 15, sections 15.17 and 15.22).

**Common mistakes.** Adding `-f` to filter a list. Trusting a count of exactly 30. Believing "POST means write": GraphQL reads are sent that way.

**Expert approach.** In scripts, always state the method and always paginate; run the `GET` before any writing call to the same resource. Reference: Chapter 15, sections 15.17, 15.20 and 15.22; `gh api --help`.

### Solution 25.3: Six filters, offline

**Solution.** One filter per task; yours may differ and still be right if the output matches.

<!-- snippet: ex3/x25-jq/02-a-count -->
```text
$ jq 'add | length' pulls-pages.json
5
```
<!-- /snippet -->

<!-- snippet: ex3/x25-jq/03-b-ready-for-main -->
```text
$ jq -r 'add | .[] | select(.draft | not) | select(.base.ref == "main") | "#\(.number) \(.title)"' pulls-pages.json
#31 Add overlap to the splitter
#34 Count characters, not bytes
#35 Bump the lock file
```
<!-- /snippet -->

<!-- snippet: ex3/x25-jq/04-c-per-base -->
```text
$ jq -c 'add | group_by(.base.ref) | map({base: .[0].base.ref, count: length})' pulls-pages.json
[{"base":"main","count":4},{"base":"release/1.2","count":1}]
```
<!-- /snippet -->

<!-- snippet: ex3/x25-jq/05-d-oldest -->
```text
$ jq -r 'add | sort_by(.created_at) | .[0] | "\(.number) \(.created_at)"' pulls-pages.json
31 2026-09-07T05:10:00Z
```
<!-- /snippet -->

<!-- snippet: ex3/x25-jq/06-e-humans -->
```text
$ jq -r 'add | map(select(.user.login | endswith("[bot]") | not)) | map(.user.login) | unique | .[]' pulls-pages.json
asha-rao
lab-user
ravi-menon
```
<!-- /snippet -->

<!-- snippet: ex3/x25-jq/07-f-inactive-rulesets -->
```text
$ jq -r '.[] | select(.enforcement != "active") | "\(.id) \(.name) \(.enforcement)"' rulesets-list.json
4102 release branches disabled
```
<!-- /snippet -->

The last question:

<!-- snippet: ex3/x25-jq/08-wrong-without-add -->
```text
$ jq -r '.[] | .number' pulls-pages.json
jq: error (at pulls-pages.json:21): Cannot index array with string "number"
[exit status: 5]
```
<!-- /snippet -->

`.[]` iterates over the outer array, whose elements are pages, and a page is an array that has no field `number`. `--slurp` wraps all pages into one outer array; it does not join them. `add` concatenates the pages, and `.[][]` would iterate over both levels.

**Reasoning.** `--jq` takes the `jq` language, so a filter proven on a file works after `--jq` unchanged; with `gh api` no `-r` is needed (Chapter 15, section 15.17). ISO 8601 timestamps in one time zone sort correctly as strings, which is why `sort_by(.created_at)` is enough.

**Common mistakes.** Forgetting the page level. `select(.draft == "false")`, comparing a boolean with a string. Counting with `length` per page.

**Expert approach.** Rehearse every filter against a saved sample before it goes into a script, and look at the shape first (`length`, `map(length)`, one element) as the exercise does. Reference: Chapter 15, section 15.17.

### Solution 25.4: Five scripts that stopped working

**Solution.**

1. No pagination: the API returns 30 items per page. Add `--paginate`.
2. The unauthenticated limit is 60 requests per hour per IP address, and on a shared runner that budget is spent by other jobs. Exceeding a limit returns `403` or `429`. Give the job an identity; do not add a retry loop.
3. `GH_TOKEN` or `GITHUB_TOKEN` is exported in one of the tabs and takes precedence over the stored login. Unset it, and remove it from the shell profile it came from.
4. The token `gh` uses cannot see the repository, and for a private resource GitHub answers `404`, not `403`. The browser session is a different credential. Check `gh auth status`: which account, which token, which scopes; for a fine-grained token, whether this repository is in its selection and the organization approved it.
5. The requested API version is no longer supported; an unsupported version answers `410 Gone`. Send a supported version.

First check: in case 2, the rate limit (`gh api rate_limit`, or the `x-ratelimit-*` headers of the failing response). In case 4, the identity (`gh auth status`).

**Reasoning.** A `403` is not always a permission problem and a `404` is not always a missing resource (Chapter 15, section 15.17; Chapter 16, section 16.19).

**Common mistakes.** Asking for more permissions in case 2. Checking the URL's spelling for an hour in case 4. Removing the version header in case 5, which makes the script depend on the default version of the day.

**Expert approach.** For every failing API call ask in order: who am I, how many requests do I have left, which version did I ask for, and only then, am I allowed? Reference: Chapter 15, sections 15.16, 15.17 and 15.20.

### Solution 25.5: Merge when green, safely

**Solution.** A model fragment. It was checked against `gh pr checks --help` and `gh pr merge --help` of 2.88.1 and not run against GitHub, so treat the handling of unusual cases, such as a pull request with no required checks at all, as untested.

```bash
gh pr checks "$PR" --required --watch --fail-fast
rc=$?
case "$rc" in
  0) ;;                                                              # every required check passed
  8) echo "required checks of #$PR are still pending" >&2; exit 1 ;;
  *) echo "required checks of #$PR did not pass (gh exit status $rc)" >&2; exit 1 ;;
esac
if ! gh pr merge "$PR" --squash --match-head-commit "$REVIEWED"; then
  echo "#$PR was not merged: the head is no longer $REVIEWED, or a rule is unmet" >&2
  exit 1
fi
```

- Exit status 8 means checks are pending (`gh pr checks --help`, "Additional exit codes").
- `--required` limits the wait to the checks that a rule names; an optional check that fails or hangs should not decide the merge.
- `--match-head-commit` merges only if the head is the commit you reviewed, so a commit pushed after your review is not merged by accident.
- `--admin` merges a pull request that does not meet the requirements. A script that uses it has removed the rules it was meant to respect.

**Rubric** (2 points each, 10 in total): waits with `--watch` or a loop on status 8, without `sleep`-and-parse; uses `--required`; tests exit statuses and prints a message for each failure; pins the head commit; contains no `--admin` and no parsing of human-readable output.

**Reasoning.** `gh` documents its exit statuses so that scripts can test them: 0 success, 1 failure, 2 cancelled, 4 authentication required, and 8 for pending checks (Chapter 15, section 15.16).

**Common mistakes.** `gh pr checks | grep -q fail`. Merging by pull request number alone. Looping forever on a check that will never be reported, which is the skipped-workflow trap of Chapter 18, section 18.8: give the wait a timeout in real use.

**Expert approach.** Prefer the platform's own mechanism where it exists: `gh pr merge --auto --squash --match-head-commit` stores the instruction on GitHub and needs no waiting script. Reference: Chapter 15, section 15.16; Chapter 17, sections 17.10 and 17.16.

### Solution 25.6: An identity for a bot

**Solution.**

| | A: team lead's classic token | B: machine user, fine-grained token | C: GitHub App |
|---|---|---|---|
| Authenticates as | the team lead | a user account for automation | the app's installation |
| A leak reaches | every repository and organization the lead can reach, by scope | one organization, the selected repositories, the granted permissions | the installation's repositories and permissions |
| For how long | until someone revokes it | until its expiry | one hour per installation token; the app's private key never expires and must sit in a secrets manager |
| When a person leaves | the job fails, or keeps running with a former employee's access | someone must own the account's password and second factor; it occupies a seat | nothing: it is not tied to a person |
| Can it do the job? | yes, with far more access than needed | not as proposed: read access cannot post a comment | yes |

Recommend C. Webhooks tell the app when a pull request changes, so it does not need to ask; one daily sweep finds the silent ones. For proposal A, polling forty repositories every five minutes is 480 requests an hour before pagination, a tenth of the 5,000 per hour that the lead's token shares with everything else the lead does, spent on asking a question whose answer rarely changes.

**Reasoning.** A webhook reverses the direction of polling. A GitHub App is the identity an integration should have: installed on chosen repositories, with fine-grained permissions and one-hour tokens (Chapter 15, section 15.18; Chapter 16, section 16.14). The chapter also notes that webhook retries and signature validation were not researched, so C needs that homework before it is built.

**Common mistakes.** Choosing A because it works today. Judging B by its token and overlooking the account behind it. Forgetting that C's private key is a long-lived secret: short-lived tokens are only as safe as the key that mints them (Chapter 21B, section 21B.8).

**Expert approach.** Decide identity before code: what does it act as, what can it reach, how long does a leaked credential live, and who notices when its owner leaves? Reference: Chapter 15, sections 15.17 and 15.18; Chapter 16, sections 16.6 and 16.14; Chapter 21B, section 21B.8.
