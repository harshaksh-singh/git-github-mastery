# Chapter 21B: Repository security, identity, the Git client, and secret-leak response

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch21b/`. Every secret in this chapter is a dummy such as `DUMMY-KEY-not-a-real-secret-12345`, spelled so that no scanner pattern matches it. GitHub Actions security is Chapter 21A; the incident drills are Chapter 30.

## 21B.1 Why this matters

A CTO asks four questions after a security scare, and none of them is about a command.

1. "A key was in the repository. We deleted it. Are we safe?"
2. "This commit says Asha wrote it. Did she?"
3. "An intern cloned a repository from a paper's footnote. What could that have run on the laptop?"
4. "If one token leaks, what can the holder reach, and how would we know?"

Each question has a wrong answer that sounds reasonable. Deleting a file adds a commit and removes nothing. An author name is text. A clone is safe and an unpacked archive is not. A token's reach depends on its type, and most teams cannot say which type their automation uses.

This chapter gives the mechanisms behind the right answers, at three layers that you must keep apart: Git on your machine (what runs, what a commit claims, what history contains), GitHub (what is displayed, scanned, blocked and retained), and the issuer of a credential (whether a leaked secret still works).

The third layer is the one tutorials leave out, and it is where incidents are decided: a secret is harmless from the moment its issuer revokes it, and dangerous until then, whatever you do to the repository.

## 21B.2 The Git client: what a clone runs, and what it does not

**In one sentence.** Cloning a repository copies its objects and refs and nothing that Git would execute, so cloning and reading is generally safe; running Git inside a `.git` directory that somebody else wrote is not.

**Analogy.** A clone is a photocopy of a book: you get every page, and none of the previous owner's sticky notes that say "when you open this, also call this number". An unpacked archive that contains `.git` is the previous owner's own copy, sticky notes included, and Git follows them. The analogy breaks in one place: the pages can still contain code that you later choose to run (a `Makefile`, a notebook). Git protects you from Git running something, not from yourself running the project.

**Precisely.** Two kinds of file under `.git` can make Git execute a program: hooks (`.git/hooks/*`, or wherever `core.hooksPath` points) and configuration (`.git/config`, where an alias beginning with `!`, `core.pager`, `core.editor`, `core.fsmonitor`, `core.sshCommand`, a credential helper, a filter driver and several other settings name commands). Git's manual states the rule in its SECURITY section: configuration and hooks are not copied by `git clone`, so cloning a remote repository with untrusted content and inspecting it with `git log` is generally safe; running Git commands in a `.git` directory, or the working tree around it, that came from an untrusted source is not, and the documented way to get a clean copy of such a directory is `git clone --no-local` (`git help git`, section SECURITY).

**Inside `.git`.** A clone creates a new `.git` from the template directory of your own Git installation. Its `hooks/` holds only the inactive `*.sample` files, and its `config` holds what `git clone` writes: the repository format, the `origin` remote and the branch's upstream. From the source it receives objects (in a pack) and refs. Nothing else crosses.

**See it.** A repository prepared by somebody else contains a `post-checkout` hook and an alias that runs a shell command. Both are harmless here: the hook appends a line to a log file, and the alias prints a sentence.

<!-- snippet: ch21b/client-safety/01-what-the-author-has -->
```text
$ cat vendor-tool/.git/hooks/post-checkout
#!/bin/sh
echo "post-checkout hook ran as $(basename "$PWD")" >> "$(git rev-parse --git-dir)/hook-ran.log"
$ git -C vendor-tool config get alias.st
!echo alias from the repository config ran
```
<!-- /snippet -->

Clone it, then look for either in the clone. `--no-local` forces the normal transport even for a path on the same disk, which is what the manual prescribes for untrusted sources.

<!-- snippet: ch21b/client-safety/02-clone-copies-neither -->
```text
$ git clone -q --no-local vendor-tool cloned
$ ls cloned/.git/hooks | grep -v '\.sample$' | wc -l
       0
$ git -C cloned config get alias.st
[exit status: 1]
$ git -C cloned switch -q -c try
$ ls cloned/.git | grep hook-ran || echo "no hook ran"
no hook ran
```
<!-- /snippet -->

The clone has no active hook, no alias, and switching branches ran nothing. Now receive the same repository the other way, as a directory copy, which is what unpacking a `.zip` or `.tar.gz` that includes `.git` gives you:

<!-- snippet: ch21b/client-safety/03-unpacked-copy-runs-both -->
```text
# The same repository received as an archive: every file under .git arrives as written.
$ cp -R vendor-tool unpacked
$ cd unpacked
$ git st
alias from the repository config ran
$ git switch -q -c try
$ cat .git/hook-ran.log
post-checkout hook ran as unpacked
$ cd ..
```
<!-- /snippet -->

`git st` ran the author's shell command, and `git switch` ran the author's hook. With a hostile archive those would have been any program, running as you, with your SSH agent and cloud credentials in reach.

**Picture.**

```text
  source repository                 git clone                    your clone
 +--------------------+                                     +---------------------+
 | objects, refs      | ---- pack + ref advertisement ----> | objects, refs       |
 | .git/config        |      (not copied)                   | config: written by  |
 | .git/hooks/*       |      (not copied)                   |   your git clone    |
 +--------------------+                                     | hooks: *.sample only|
                                                            +---------------------+

  source repository                 cp -R, unzip, tar x          "unpacked" copy
 +--------------------+                                     +---------------------+
 | objects, refs      | ---- every file as written -------> | objects, refs       |
 | .git/config        | ----------------------------------> | the author's config |
 | .git/hooks/*       | ----------------------------------> | the author's hooks  |
 +--------------------+                                     +---------------------+
```

**In production.** An ML team receives a "reproduction package" for a paper as a tarball that contains a full repository. A shell prompt that shows the branch name runs `git status` as soon as someone changes into the directory, and `git status` consults `core.fsmonitor` from the package's own `.git/config`. The safe procedure is the manual's: `git clone --no-local package clean`, and work in `clean`.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git clone <url>` | created from the tip of the remote's default branch | created | created, points at the default branch | created | fresh `config` and sample hooks from your installation; `refs/remotes/origin/*`; the pack | unchanged (read only) | unchanged |

## 21B.3 The three client guards: `safe.directory`, `safe.bareRepository`, `protocol.file.allow`

Git added three standing defenses in 2022 ([safe configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/safe.adoc), [protocol configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/protocol.adoc)). Each closes one way of getting you to run Git inside configuration that you did not write.

### `safe.directory`: a repository owned by another user

**In one sentence.** Git refuses to read the configuration of a repository whose directory is owned by a different operating-system user, unless you have listed that directory as safe.

**Precisely.** Git discovers a repository by walking up from the current directory. On a shared machine another user can create `/tmp/.git` or `/scratch/.git`, and without this check any Git command you run below that directory would load their configuration and hooks. The check compares the owner of the repository directory with the user running Git. `safe.directory` lists exceptions; it is multi-valued, accepts `/path/*` for everything under a directory and `*` to switch the check off, and is honored only in protected configuration (system, global and command scope), so that a repository cannot declare itself safe (`git help config`, `safe.directory`).

**See it.** The sandbox cannot change file ownership without `sudo`, so this transcript uses `GIT_TEST_ASSUME_DIFFERENT_OWNER=1`, the variable Git's own test suite uses to simulate a foreign owner. The real message appears in containers and CI, where the checkout is often owned by another user ID.

<!-- snippet: ch21b/client-safety/04-dubious-ownership -->
```text
# GIT_TEST_ASSUME_DIFFERENT_OWNER=1 makes Git treat the repository as owned by another user.
$ GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C unpacked status -sb
fatal: detected dubious ownership in repository at '$LAB/ch21b/client-safety/unpacked'
To add an exception for this directory, call:

	git config --global --add safe.directory $LAB/ch21b/client-safety/unpacked
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch21b/client-safety/05-safe-directory -->
```text
$ git config set --global --append safe.directory "$PWD/unpacked"
$ GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C unpacked status -sb
## try
[exit status: 0]
# The setting is honoured only in protected configuration. In the repository itself it is ignored:
$ git config unset --global safe.directory
$ git -C unpacked config set safe.directory '*'
$ GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C unpacked status -sb 2>&1 | head -1
fatal: detected dubious ownership in repository at '$LAB/ch21b/client-safety/unpacked'
```
<!-- /snippet -->

The last three lines are the important ones: writing `safe.directory = *` into the repository's own configuration changes nothing, because that file is exactly what Git declined to trust.

> **Outdated advice.** Answers from 2022 tell you to run `git config --global --add safe.directory '*'` to make the message go away. That switches the protection off for every repository on the machine. List the one directory, or fix the ownership.

### `safe.bareRepository`: a bare repository hidden in a working tree

**In one sentence.** With `safe.bareRepository=explicit`, Git uses a bare repository only when you name it with `--git-dir` or `GIT_DIR`, never because you happened to be inside one.

**Precisely.** A bare repository is a directory with `HEAD`, `objects/`, `refs/` and `config`, and it does not need to be called `.git`. A project can therefore contain one as ordinary tracked files in a subdirectory. A clone does copy it, because to Git those are ordinary files. If you then change into that subdirectory and run any Git command, Git discovers the embedded bare repository and reads its `config`. The default in Git 2.x is `all`; `explicit` will be the default in Git 3.0 (`git help config`, `safe.bareRepository`).

<!-- snippet: ch21b/client-safety/06-bare-repository -->
```text
$ git -C embedded.git log --oneline
418a3a1 Add tool
$ git config set --global safe.bareRepository explicit
$ git -C embedded.git log --oneline
fatal: cannot use bare repository '$LAB/ch21b/client-safety/embedded.git' (safe.bareRepository is 'explicit')
[exit status: 128]
$ git --git-dir=embedded.git log --oneline
418a3a1 Add tool
$ git config unset --global safe.bareRepository
```
<!-- /snippet -->

If you do not work inside bare repositories by hand, set `explicit` globally now. The labs in this course inspect the bare "server" with `git -C server.git ...`, which is why the lab configuration leaves the default in place.

### `protocol.file.allow`: clones that you did not ask for

**In one sentence.** Since 2022 the `file` transport defaults to the policy `user`: you may use it directly, and commands that start a clone on their own, such as submodule initialization, may not.

**Precisely.** `protocol.<name>.allow` is `always`, `never` or `user`. The safe network protocols default to `always`, `ext` to `never`, and everything else, `file` included, to `user`, which permits a transport only when `GIT_PROTOCOL_FROM_USER` is unset or 1 (`git help config`, `protocol.allow`). Git sets that variable to 0 when it clones a submodule. The risk it closes: a `.gitmodules` file that names a local path makes a recursive clone read from a directory on your disk that the attacker chose.

<!-- snippet: ch21b/client-safety/07-file-protocol -->
```text
$ cd app
$ git submodule add ../vendor-tool vendor/tool
Cloning into '$LAB/ch21b/client-safety/app/vendor/tool'...
fatal: transport 'file' not allowed
fatal: clone of '$LAB/ch21b/client-safety/vendor-tool' into submodule path '$LAB/ch21b/client-safety/app/vendor/tool' failed
[exit status: 128]
$ git config get protocol.file.allow
[exit status: 1]
$ git -c protocol.file.allow=always submodule add -q ../vendor-tool vendor/tool
$ git submodule status | cut -c1-9,42-
 418a3a1f vendor/tool (heads/main)
```
<!-- /snippet -->

The one-off `-c protocol.file.allow=always` is correct for a local experiment such as this one. Setting it globally removes the guard. Leave the default.



## 21B.4 Recursive clones, hooks, and repositories that look popular

**The recurring vulnerability is the recursive clone.** The statement "cloning is safe" has had exceptions, and they share a shape: a repository with submodules, cloned with `--recurse-submodules`, tricks Git into writing a file where a hook is expected and then running it.

| CVE | Severity, fixed in | Mechanism in one line | Source |
|---|---|---|---|
| CVE-2024-32002 | critical; 2.45.1 and backports, May 2024 | on a case-insensitive filesystem with symbolic links, a submodule could write a hook into `.git/` that ran during the clone | [advisory](https://github.com/git/git/security/advisories/GHSA-8h77-4q3w-gfgv) |
| CVE-2025-48384 | high; 2.50.1 and backports, July 2025 | a trailing carriage return in a submodule path checked content out to an unintended location where a hook could run | [advisory](https://github.com/git/git/security/advisories/GHSA-vwqx-4fm8-6qc9) |
| CVE-2025-48385 | 2.50.1 and backports | bundle URIs, which are not enabled by default | [advisory](https://github.com/git/git/security/advisories/GHSA-m98c-vgpc-9655) |
| CVE-2024-52005 | default changed in core Git 2.55 | unfiltered terminal escape sequences sent by a remote | [advisory](https://github.com/git/git/security/advisories/GHSA-7jjc-gg6m-3329) |

macOS meets the first row's conditions: its default filesystem is case-insensitive and supports symbolic links. Release 2.45.2 reverted part of the hardening of 2.45.1 because it had broken Git LFS ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.45.2.adoc)). No core-Git advisory was published in 2026 up to 1 October; Git for Windows published several Windows-specific ones ([advisories](https://github.com/git-for-windows/git/security/advisories)). Your 2.55.0 contains every published core fix, and so does Apple's 2.50.1. The advisory for CVE-2025-48384 names the standing workaround: do not recursively clone submodules of untrusted repositories.

**Hooks.** `githooks(5)` documents 28 hooks, six of which run on the receiving side of a push. Client-side hooks live in `$GIT_DIR/hooks` unless `core.hooksPath` redirects them, are not cloned, and `pre-commit` and `commit-msg` are skipped by `--no-verify` ([githooks](https://github.com/git/git/blob/v2.56.0/Documentation/githooks.adoc)). Since Git 2.54 hooks can also be declared in configuration, including global and system configuration, so the question "why did a hook run?" is now answered with `git hook list --show-scope <event>` ([git-hook](https://github.com/git/git/blob/v2.56.0/Documentation/git-hook.adoc)). A client-side hook is therefore not a control: the person it is meant to stop can skip it (section 21B.12).

**Fake popularity.** For an engineer who clones research code weekly, the ecosystem is a larger risk than the client. Researchers documented a network of more than 3,000 GitHub accounts that distributed malware through repositories made to look popular ([Check Point](https://research.checkpoint.com/2024/stargazers-ghost-network/)), hundreds of fake project repositories that stole about 5 BTC ([Kaspersky](https://www.kaspersky.com/about/press-releases/kaspersky-exposes-hidden-malware-on-github-stealing-personal-data-and-485000-in-bitcoin)), and about six million suspected fake stars ([arXiv](https://arxiv.org/abs/2412.13459)). Stars, forks and a polished README are not evidence of legitimacy.

A rule set that follows from sections 21B.2 to 21B.4:

1. Clone; do not unpack somebody else's `.git`. If you must, `git clone --no-local` it first.
2. Treat `git clone --recurse-submodules` of an untrusted repository as running its code. Clone without submodules, read `.gitmodules`, then decide.
3. Set `safe.bareRepository=explicit`. Leave `protocol.file.allow` alone. Never set `safe.directory=*` on a workstation.
4. Cloning is the safe part. `pip install -e .`, `make` and a notebook's first cell run the project's code. Read before you run, or run in a container without your credentials.

## 21B.5 Identity: author fields are assertions

**In one sentence.** The author and committer of a commit are two lines of text that the person running Git supplies, and neither Git nor a push checks them against anything.

**Analogy.** The return address on an envelope. The postal service delivers the letter whatever you write there. A signature is the wax seal: it proves which seal pressed the wax, and it still says nothing about what the letter asks you to do.

**Precisely.** `git commit` takes the author from `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL`, or from `--author`, or from `user.name` and `user.email`, and the committer from the `GIT_COMMITTER_*` variables or the same configuration. Those strings become the `author` and `committer` headers of the commit object and are covered by the commit ID. The transport authenticates the *pusher* (Chapter 16). It does not compare the pusher with the names inside the commits being pushed, and it could not: pushing other people's commits is what a merge, a rebase and a cherry-pick do every day.

**See it.** In a billing service, the lab user makes a commit that claims Asha as both author and committer:

<!-- snippet: ch21b/identity-assertion/01-assert-anything -->
```text
$ printf 'RATE = 0.0\n' > tax.py
$ GIT_AUTHOR_NAME='Asha Rao' GIT_AUTHOR_EMAIL=asha@example.com GIT_COMMITTER_NAME='Asha Rao' GIT_COMMITTER_EMAIL=asha@example.com git commit -q -am 'Set tax rate to zero'
$ git log --format='%h author=%an <%ae>  committer=%cn <%ce>  signature=%G?'
42f5693 author=Asha Rao <asha@example.com>  committer=Asha Rao <asha@example.com>  signature=N
be06446 author=Lab User <you@example.com>  committer=Lab User <you@example.com>  signature=N
```
<!-- /snippet -->

`%G?` prints `N`: no signature. Nothing else distinguishes this commit from one Asha made. The object is unremarkable:

<!-- snippet: ch21b/identity-assertion/02-the-object -->
```text
$ git cat-file -p HEAD
tree 11b14212895ed45f1584d7ddb52f93c7e9727b61
parent be06446cd1b687a100823496b6bedd9ea544b35c
author Asha Rao <asha@example.com> 1788755700 +0530
committer Asha Rao <asha@example.com> 1788755700 +0530

Set tax rate to zero
```
<!-- /snippet -->

[Chapter 14B, section 14B.18](ch14b-config-tags-signing.md) continues this locally: the forged commit next to a signed one, and what `git verify-commit` and an allowed-signers file report. This chapter takes the platform side.

> **GitHub, not Git.** GitHub attributes a commit to an account by matching the email address in the commit with the addresses on accounts ([why are my commits linked to the wrong user](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/troubleshooting-commits/why-are-my-commits-linked-to-the-wrong-user)). The avatar and the profile link beside a commit are therefore a lookup of a string that the committer chose. Anyone with push access can make a commit display as a colleague, or as any public figure whose email is known ([demonstration](https://www.gruntwork.io/blog/how-to-spoof-any-user-on-github-and-what-to-do-to-prevent-it)).

Four separate questions hide behind "who made this commit", and they have four separate answers:

| Question | Answered by | Layer | Can it be forged by someone with push access? |
|---|---|---|---|
| Who is displayed? | email matching | GitHub | yes |
| Who pushed it? | the authenticated credential, recorded in the Activity view and audit log | GitHub | no, but a stolen credential pushes as its owner |
| Who signed it? | a signature verified against a key | Git locally, GitHub for display | only with the private key |
| What is enforced? | a rule that rejects unsigned or unverified commits | GitHub | no |

**In production.** A reviewer approves a pull request because "the last three commits are from the platform lead". A compromised contributor account authored them under her email. Displayed identity is not evidence; the audit log's pusher and a required signature are.

## 21B.6 Signatures on GitHub: the verification states

**In one sentence.** GitHub checks each commit's signature against keys registered on accounts and shows the result as a badge; without vigilant mode an unsigned commit gets no badge at all.

**Precisely.** GitHub verifies GPG, SSH and S/MIME signatures. A cryptographically verifiable signature is marked "Verified" or "Partially verified"; a signature that cannot be verified is "Unverified"; an unsigned commit shows no status by default ([about commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)). For SSH, the public key must be added to the account as a *signing* key, which is a separate registration from an authentication key even when it is the same key file:

```bash
gh ssh-key add ~/.ssh/id_ed25519_signing.pub --type signing --title "laptop signing key"
```

**Vigilant mode** changes what silence means. With "Flag unsigned commits as unverified" enabled in your account's SSH and GPG keys settings, the states become ([displaying verification statuses](https://docs.github.com/en/authentication/managing-commit-signature-verification/displaying-verification-statuses-for-all-of-your-commits)):

| State | Without vigilant mode | With vigilant mode enabled by the person the commit names |
|---|---|---|
| Verified | signed, and the signature verifies | signed and verified, and the committer is the only author who has enabled vigilant mode |
| Partially verified | not shown | signed and verified, but the commit has an author who is not the committer and who has enabled vigilant mode |
| Unverified | signed, but the signature could not be verified | also any *unsigned* commit attributed to that person |
| no badge | not signed | does not occur for that person's commits |

Vigilant mode is the cheap defense against the forgery of section 21B.5: once Asha enables it, the commit that claims her name without her key is displayed as "Unverified" instead of looking like all her other unsigned commits. Enable it only after you sign on every machine you commit from, or your own work is flagged.

**Persistent verification records.** Since 10 December 2024, once GitHub has verified a signature the commit stays verified within its repository network: a record is stored with the commit, cannot be edited, and persists when the key is later rotated, revoked or expired, or the contributor leaves the organization. GitHub does not re-verify old commits when a key's state changes; the time of verification is exposed as `verified_at` in the REST API ([persistent verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification#persistent-commit-signature-verification), [changelog](https://github.blog/changelog/2024-12-10-persistent-commit-signature-verification-is-generally-available/)). Rotating a key no longer turns years of history "Unverified". But revoking a *stolen* key does not un-verify what an attacker signed with it: you find those commits by date and by the audit log, not by the badge.

**Commits that GitHub signs.** Commits you make in the web interface are signed by GitHub with its own key, which you can check locally against `https://github.com/web-flow.gpg`; that includes the merge commit of "Create a merge commit" and the single commit of "Squash and merge" ([about commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)). That badge says GitHub created the commit on behalf of a signed-in user, not that the user's key was involved. Dependabot signs its commits by default, and the Copilot cloud agent has signed its commits since 3 April 2026 ([changelog](https://github.blog/changelog/2026-04-03-copilot-cloud-agent-signs-its-commits/)).

**Why "Rebase and merge" yields unsigned commits.** A rebase creates new commits with new parents and a new committer (Chapter 9). A signature covers the commit's content including its parents, so the original signatures cannot be carried over, and GitHub does not have your private key to make new ones. The documentation states the result: the commits are created without signature verification ([signature verification for rebase and merge](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification#signature-verification-for-rebase-and-merge)). A history rewrite strips signatures for the same reason (section 21B.16).

**The require-signed-commits rule.** Display is not enforcement. The ruleset rule "Require signed commits" means contributors and bots can push only commits that are signed and verified; under rulesets GitHub checks only the commits that are not reachable from other branches ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-signed-commits)). The rule therefore makes "Rebase and merge" unusable on the protected branch, while squash and merge commits pass because GitHub signs them (Chapter 18).

> **Unverified.** Sigstore's keyless `gitsign` signs with short-lived certificates tied to an OIDC identity, and its README says GitHub does not display those commits as verified ([gitsign](https://github.com/sigstore/gitsign)). The Phase 0 report could not re-verify this, or GitHub's support for SSH certificates in verification, against a 2026 primary source.

## 21B.7 What a signature does not prove

A verified signature proves one thing: the holder of a particular private key created this exact commit object. It does not prove that the change is correct, reviewed, or benign, or that the key holder is who you think, or that the person had not been turned or impersonated socially.

The xz-utils backdoor of 2024 is the case to remember. It was introduced by a contributor who had earned commit rights over more than two years of useful work, and the build script that activated it was present only in the release tarball, not in the Git repository ([timeline](https://research.swtch.com/xz-timeline)). Every commit could have carried a perfect signature. Signing would have changed nothing, for two reasons that generalize:

- **The signer was authorized.** Signatures authenticate; they do not judge. Review, and limits on what one maintainer can ship alone, are the controls for a trusted insider.
- **The artifact was not the repository.** What users ran was a tarball. A signature on commits says nothing about a release archive, a wheel or a container image built somewhere else. That gap is closed by build provenance and artifact attestations, which belong to the Actions chapters.

Signing removes cheap impersonation and anchors the audit trail. It is one layer.

## 21B.8 Credentials: what a stolen one can reach

Chapter 16 explains how each credential type authenticates. The incident question is different: if it leaks, what can it reach, and for how long?

| Credential | Reach if stolen | Lifetime | Source |
|---|---|---|---|
| Actions `GITHUB_TOKEN` | the workflow's repository, within the job's `permissions` | the job | [credential types](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/github-credential-types) |
| GitHub App installation token | the installation's repositories and permissions | one hour | same |
| GitHub App private key | mints installation tokens for every installation of the app | **never expires** | [GitGuardian](https://blog.gitguardian.com/github-app-private-keys-leaked/) |
| Fine-grained personal access token | one owner, optionally selected repositories, per-permission | configurable | credential types |
| Deploy key | one repository, read or read-write | long-lived | credential types |
| Personal SSH key | everything the account can reach over SSH | long-lived | credential types |
| Classic personal access token | every repository and organization its owner can reach, by scope | long-lived | credential types |

Two automatic protections exist and both are narrow: GitHub revokes its own tokens when they are pushed to a public repository or gist, and removes tokens unused for a year ([token expiration and revocation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation)). The App private key is the row people forget. Of 4,802 leaked GitHub App private keys tested in September 2026, 474 still authenticated, 44 of them with organization admin access ([GitGuardian](https://blog.gitguardian.com/github-app-private-keys-leaked/)). Short-lived installation tokens are only as safe as the long-lived key that mints them.

**A hierarchy for automation.** The Phase 0 report derives this order from the facts above; it is an inference, not a GitHub statement:

1. OIDC-issued cloud tokens, and the job-scoped `GITHUB_TOKEN`, wherever the work happens inside a workflow.
2. GitHub App installation tokens, with the App's private key in a secrets manager.
3. Fine-grained personal access tokens with an expiry and organization approval.
4. Deploy keys, for read access to a single repository.
5. Classic tokens and shared machine users: last, and with a written reason.

**Real compromises abuse tokens, sessions and laptops, not Git.**

| Case | What happened | Lesson |
|---|---|---|
| Heroku and Travis CI OAuth tokens, April 2022 ([GitHub Blog](https://github.blog/news-insights/company-news/security-alert-stolen-oauth-user-tokens/)) | stolen OAuth tokens issued to two integrators were used to clone private repositories of dozens of organizations | a third party's token store is part of your attack surface; review authorized OAuth apps |
| CircleCI, December 2022 ([incident report](https://circleci.com/blog/jan-4-2023-incident-report/)) | malware on an engineer's laptop stole an already authenticated session, bypassing two-factor authentication; all customers were told to rotate their secrets | two-factor authentication protects the login, not the session that follows it |
| GitHub, May 2026 ([GitHub Blog](https://github.blog/security/investigating-unauthorized-access-to-githubs-internal-repositories/)) | a poisoned third-party VS Code extension on an employee device led to exfiltration of GitHub-internal repositories; GitHub rotated critical secrets, including the GitHub Enterprise Server signing key | editor extensions run with the developer's access; device security is repository security |

For the third case, attribution to a named group and details of the extension come from vendor reports; GitHub's post names neither, and one vendor gives the detection date as 19 May where GitHub says 18 May.

**Token forensics.** After a suspected compromise the question is "what did this token do?". GitHub's audit log can be searched by token without storing the token itself: compute its SHA-256 and search for the hash ([identifying audit log events performed by an access token](https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/reviewing-audit-logs-for-your-enterprise/identifying-audit-log-events-performed-by-an-access-token)).

```bash
# The token is read from a variable, never typed on the command line or pasted into chat.
printf '%s' "$LEAKED_TOKEN" | openssl dgst -sha256 -binary | base64
# then search the audit log for:   hashed_token:"<the value printed above>"
```

The documented form is `echo -n TOKEN | openssl dgst -sha256 -binary | base64`; the `printf` variant hashes the same bytes and keeps the token out of your shell history. Two limits decide whether this works on the day. A search by token hash returns no Git events, in the interface or through the REST API: clones, fetches and pushes made with the token have to be identified in an export of Git events data ([identifying events performed by an access token](https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/reviewing-audit-logs-for-your-enterprise/identifying-audit-log-events-performed-by-an-access-token)). And the retention differs: the organization audit log covers 180 days, while Git events are an Enterprise Cloud feature that the audit log retains for seven days ([organization audit log](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization), [enterprise audit log](https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/security-and-compliance/audit-log-for-an-enterprise); [Chapter 13](ch13-recovery.md), section 13.15). To answer "was the repository cloned with this token?" months later, streaming or export must be set up before the incident.

## 21B.9 Secrets in repositories: the scale

The numbers below are why this chapter exists, and each comes with its source.

- GitGuardian counted 28,649,024 new secrets on public GitHub in 2025, up 34%, the largest single-year jump it has recorded. 1,275,105 of them were tied to AI services, up 81%. 24,008 unique secrets sat in MCP configuration files. Commits co-authored by Claude Code leaked secrets at roughly twice the baseline rate. 64% of the secrets confirmed valid in 2022 were still valid when retested. Internal repositories were about six times more likely than public ones to contain a hardcoded secret ([State of Secrets Sprawl 2026](https://www.gitguardian.com/state-of-secrets-sprawl-report-2026)).
- GitHub detected more than one million leaked secrets on public repositories in the first eight weeks of 2024 ([GitHub Blog](https://github.blog/news-insights/product-news/keeping-secrets-out-of-public-repositories/)).
- A scan of AI companies found that 65% of the Forbes AI 50 companies with a GitHub footprint had leaked verified secrets ([SecurityWeek](https://www.securityweek.com/many-forbes-ai-50-companies-leak-secrets-on-github/)).

"Still valid years later" means that detection without revocation achieves nothing. "Internal repositories are worse" means that privacy is being used as a substitute for hygiene. And the AI-service growth is your field: an LLM key is created in a browser tab, pasted into a notebook or a `.env`, and committed by `git add -A` or by an agent that stages everything it touched.

## 21B.10 Why deleting, force-pushing and making it private do not remove a secret

**In one sentence.** A commit is a permanent snapshot, so a later commit that deletes a file leaves every earlier snapshot intact, and moving or hiding refs changes who can easily find the old snapshot, not whether it exists.

**Analogy.** Publishing a correction in tomorrow's newspaper does not recall yesterday's edition from the people who bought it. Withdrawing yesterday's edition from your own archive (a force push) does not recall it either. The analogy breaks for *unpushed* commits: an edition that never left the building can be pulped (section 21B.12).

**Precisely.** Three operations are commonly mistaken for removal:

| What people do | What it changes | Where the secret still is |
|---|---|---|
| Commit a deletion | adds a new commit whose tree lacks the file | in every commit between the one that added it and the deletion; reachable from the branch, from tags, from other branches |
| Amend or reset, then force-push | moves a ref to different commits | in the old commits, which stay in the server's object database, in every clone and fork that fetched them, and on GitHub in cached views and through pull requests that reference them |
| Make the repository private, or delete it | changes who may read through the normal interface | in every clone and fork made while it was public; in the fork network |

GitHub states the second row itself: after a rewrite and force push, the old commits can still be accessible in clones and forks, directly by commit ID in cached views, and through pull requests that reference them ([removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)). It states the third row too: Git data pushed to any repository in a fork network may be accessed from any other repository in that network, even after a fork is deleted ([forks reference](https://docs.github.com/en/pull-requests/reference/forks#important-security-considerations)). Researchers showed in 2024 that this is exploitable at scale, finding 40 valid API keys in commits from deleted forks of three commonly forked repositories ([Truffle Security](https://trufflesecurity.com/blog/anyone-can-access-deleted-and-private-repo-data-github)), and in 2025 that commits orphaned by force pushes can be enumerated from public event archives and scanned, which yielded thousands of secrets including a GitHub token with admin access to all repositories of the Istio project ([Truffle Security guest post](https://trufflesecurity.com/blog/guest-post-how-i-scanned-all-of-github-s-oops-commits-for-leaked-secrets)).

**See it.** The fixture for the rest of the chapter is `ragdesk`, a retrieval-augmented helpdesk service with a bare `server.git` and two teammates' clones. Four commits back, `git add -A` swept a local `.env` into the commit "Add staging settings":

<!-- snippet: ch21b/find-secret/01-the-leak -->
```text
$ cd ragdesk
$ git log --oneline --decorate
d4b8762 (HEAD -> main, origin/main) Document setup in README
b509fe3 Add request timeout
64b9b89 (tag: v0.2.0) Add retry with backoff
0805fd8 Add staging settings
987a49d (tag: v0.1.0) Add evaluation harness
6388058 Add LLM client
0c55276 Add answer prompt template
dfd59fd Add BM25 retriever
$ cat .env
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
LLM_BASE_URL=https://llm.example.com
```
<!-- /snippet -->

The usual first reaction is to stop tracking the file (🟡 `git rm --cached` changes the index and leaves the working tree file alone), ignore it, and commit:

<!-- snippet: ch21b/find-secret/02-delete-is-not-removal -->
```text
$ git rm --cached -q .env
$ printf '.env\n' > .gitignore
$ git add .gitignore && git commit -q -m 'Stop tracking .env and ignore it'
$ git ls-files
.gitignore
README.md
eval.py
llm_client.py
prompts/answer.txt
retriever.py
settings.yaml
$ git grep -n DUMMY-KEY
[exit status: 1]
# The tip is clean. The commit that added the file still has it:
$ git show HEAD~4:.env
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
LLM_BASE_URL=https://llm.example.com
```
<!-- /snippet -->

`git grep` on the tip finds nothing and exits with status 1. `git show HEAD~4:.env` prints the key. After the push, the server agrees on both counts: the tip of `main` is clean, and the tag `v0.2.0`, which points into the affected range, still serves the file to anyone who fetches it.

<!-- snippet: ch21b/find-secret/08-server-still-has-it -->
```text
$ git push -q origin main
$ git -C ../server.git grep -c DUMMY-KEY main
[exit status: 1]
$ git -C ../server.git grep -n 'DUMMY-KEY' v0.2.0 -- .env
v0.2.0:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
```
<!-- /snippet -->

**Inside `.git`.** The deletion commit `d42d1a1` has a tree without `.env`. Its parent `d4b8762` has a tree with it, and so do `b509fe3`, `64b9b89` and `0805fd8` on `main` and `7fae871` on Asha's branch. All of those trees name the same blob, `e523d04`, the content of `.env`. The blob exists once in the object database and is reachable from five commits. Nothing in a new commit can change an old one, because a commit's ID is the hash of its content (Chapter 3).

```text
Observed behavior : the key is gone from the files, and a scanner still reports it
Git state         : tip tree has no .env; commits 0805fd8..d4b8762 have trees that contain blob e523d04
Mechanism         : "git rm" changes the next snapshot; earlier snapshots are immutable objects
Root cause        : the secret was pushed, so it exists in every repository that fetched those commits
Why Git does this : history that could be edited in place could not be verified by its hash
Correct fix       : revoke the key at its issuer; then decide whether a history rewrite is warranted (21B.14)
Prevention        : keep secrets out of the working tree's tracked paths; block them at commit and at push (21B.12)
```

> **Root cause.** "Private", "deleted" and "force-pushed" change discoverability, not accessibility. The exposure window starts at the first push and does not end at deletion.

## 21B.11 Finding a secret in history with built-in commands

You need three commands, and you need to know what each one cannot see.

**`git log -S<string>`**, the pickaxe, lists commits in which the *number of occurrences* of the string changed, which means the commits that added it and the commits that removed it. Without `--all` it walks only the current branch.

<!-- snippet: ch21b/find-secret/03-pickaxe -->
```text
$ git log --oneline -S'DUMMY-KEY-not-a-real-secret' -- .env
d42d1a1 Stop tracking .env and ignore it
0805fd8 Add staging settings
$ git log --oneline --all -S'DUMMY-KEY-not-a-real-secret'
d42d1a1 Stop tracking .env and ignore it
0805fd8 Add staging settings
```
<!-- /snippet -->

Two commits: the one that introduced the key and the one that deleted it. Add `-p` to see the lines, and `--diff-filter=A` to keep only commits that added a file, which is the introduction:

<!-- snippet: ch21b/find-secret/04-pickaxe-patch -->
```text
$ git log -p --format='commit %h%nAuthor: %an <%ae>%nDate:   %ad%n%n    %s' -S'DUMMY-KEY-not-a-real-secret' --diff-filter=A
commit 0805fd8
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:10:00 2026 +0530

    Add staging settings

diff --git a/.env b/.env
new file mode 100644
index 0000000..e523d04
--- /dev/null
+++ b/.env
@@ -0,0 +1,2 @@
+LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
+LLM_BASE_URL=https://llm.example.com
```
<!-- /snippet -->

That one transcript answers four assessment questions: which commit, who, when, and which file.

**`git log -G<regex>`** lists commits whose diff has an added or removed line matching a regular expression. Use it when you know the shape of a secret and not its value, and with `--all` to cover every ref:

<!-- snippet: ch21b/find-secret/05-regex -->
```text
$ git log --oneline --all -G'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'
d42d1a1 Stop tracking .env and ignore it
54093fe Add rerank debugging notebook
0805fd8 Add staging settings
$ git log --oneline --all --name-only --format='%h %s' -G'Bearer [A-Za-z0-9-]+'
54093fe Add rerank debugging notebook

notebooks/rerank-debug.ipynb
```
<!-- /snippet -->

The regular expression found a second leak that nobody had reported: a bearer token captured in the output cell of a notebook on a branch that was pushed and never merged. Notebook outputs leak secrets that the author never typed (Chapter 28 covers stripping outputs).

**`git grep <pattern> $(git rev-list --all)`** searches the *content of every commit's tree*, not the diffs. It answers "in which snapshots is the secret present?", which is the exposure, where the pickaxe answers "where did it enter and leave?".

<!-- snippet: ch21b/find-secret/06-grep-all-commits -->
```text
$ git grep -n 'DUMMY-KEY' $(git rev-list --all) | cut -c1-9,41-
d4b876277:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
7fae87198:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
b509fe363:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
64b9b890c:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
0805fd8e8:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345

# Which files, in how many commits:
$ git grep -l -E 'DUMMY-(KEY|TOKEN)' $(git rev-list --all) | cut -d: -f2 | sort | uniq -c
   5 .env
   1 notebooks/rerank-debug.ipynb
```
<!-- /snippet -->

Five snapshots contain the key (the first column is the commit, shortened by `cut`). On a large repository the argument list becomes too long for one command; pipe instead: `git rev-list --all | xargs git grep -l <pattern>`.

Finally, turn the commit into scope: which branches and tags contain it?

<!-- snippet: ch21b/find-secret/07-which-refs -->
```text
$ first=$(git log --all --format=%H --diff-filter=A -- .env)
$ git log --oneline -1 $first
0805fd8 Add staging settings
$ git branch -a --contains $first
* main
  remotes/origin/feature/streaming
  remotes/origin/main
$ git tag --contains $first
v0.2.0
```
<!-- /snippet -->

| Command | Finds | Does not see |
|---|---|---|
| `git grep <p>` | the pattern in the current working tree's tracked files | anything in history |
| `git log -S<s>` | commits that added or removed the string on the current branch | other branches without `--all`; a secret that was moved within a file |
| `git log --all -G<re>` | commits on any ref whose diff touches a matching line | commits no ref reaches |
| `git grep <p> $(git rev-list --all)` | every snapshot on any ref that contains the pattern | commits no ref reaches; binary and compressed files |
| the same with `--all --reflog` | also commits reachable only from reflogs, such as amended ones | unreachable objects without reflog entries; other people's clones |

Lab 30.3 runs all five rows. Built-in commands need you to know the pattern; a dedicated scanner knows hundreds and can test candidates against the issuer. Use the built-ins during an incident to establish scope, and a scanner for coverage.

## 21B.12 Secret scanning and push protection, and what they do not cover

> **GitHub, not Git.** Everything in this section up to the local analogue is platform behavior, described from the linked documentation. Nothing here was run against GitHub.

**Secret scanning** scans the entire Git history on all branches, plus issues, pull requests, discussions and wikis. It runs for free on public repositories; organization-owned private and internal repositories need GitHub Secret Protection, which costs $19 per active committer per month and is sold on Team and Enterprise plans ([secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning), [price list](https://github.com/security/plans)).

**Push protection** blocks a push that contains a recognized secret before it reaches the repository. It comes in two forms ([about push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection)):

| | Push protection for users | Push protection for repositories |
|---|---|---|
| Default | on, since 29 February 2024 | off |
| Requires | nothing; GitHub.com only | GitHub Secret Protection (free on public repositories) |
| Protects | your pushes to **public** repositories | every push to that repository, by anyone |
| Bypass leaves an alert | no, unless repository protection is also on | yes |

It covers command-line pushes, commits made in the web interface, file uploads, REST API requests and, on public repositories, interactions through the GitHub MCP server. By default anyone with write access can bypass a block by choosing a reason: "It's used in tests" and "It's a false positive" create a closed alert, "I'll fix it later" an open one; the bypass is written to the audit log and emailed to administrators. Delegated bypass, part of Secret Protection for organization-owned repositories, restricts who may bypass and puts other contributors' requests through a review that expires after seven days ([delegated bypass](https://docs.github.com/en/code-security/concepts/secret-security/delegated-bypass)).

**What it does not cover.** GitHub's default protection is narrower than most engineers assume:

- User push protection guards only pushes to public repositories. A private repository without Secret Protection has no push-time check at all.
- It blocks high-confidence provider patterns. Generic secrets such as passwords and connection strings are not blocked; AI-detected passwords are explicitly excluded from push protection ([changelog](https://github.blog/changelog/2024-10-21-copilot-secret-scanning-for-generic-passwords-is-generally-available/)).
- A block is a prompt, not a wall, unless delegated bypass is configured.
- Coverage differs by provider, in three independent columns:

| Credential type | Provider notified for public leaks | Blocked by push protection | Validity check |
|---|---|---|---|
| OpenAI API key; Anthropic API key; Hugging Face user access token; xAI, Groq, OpenRouter, Replicate, Databricks tokens | Yes | Yes | Yes |
| Google API key | Yes | **No** | Yes |
| Google Gemini API key | **No** | **No** | User alert only |
| Mistral AI, Cohere, DeepSeek, Pinecone | **No** | Yes | Yes |
| Perplexity, LangSmith, Weights & Biases API keys | **No** | Yes | No |
| PyPI API token; npm access token; GitHub personal access tokens | Yes | Yes | Yes (not listed for PyPI) |

Source: GitHub's supported-pattern data as read for the Phase 0 report on 1 October 2026 ([supported patterns](https://docs.github.com/en/code-security/secret-scanning/introduction/supported-secret-scanning-patterns)). The list changes; re-read it for the providers you use. Partner notification does not guarantee revocation. GitHub revokes its own leaked tokens; Anthropic documents automatic deactivation of keys found in public GitHub repositories ([Anthropic](https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure)); Hugging Face lets anyone invalidate a leaked token through a revocation endpoint ([Hugging Face](https://huggingface.co/docs/hub/en/security-tokens)); but an xAI key flagged on 2 March 2025 stayed valid until 30 April 2025 ([Krebs on Security](https://krebsonsecurity.com/2025/05/xai-dev-leaks-api-key-for-private-spacex-tesla-llms/)).

> **Unverified.** Whether OpenAI disables API keys it finds on the public internet could not be confirmed from a primary page for the Phase 0 report. How Hugging Face and OpenAI handle partner notifications from GitHub is not documented in the pages read.

### The local analogue: a push-time check in plain Git

> **Git, not GitHub.** What follows is a `pre-receive` hook on a bare repository that you control. It reproduces the *behavior* of a push-time check so that you can see it; it is not how GitHub implements push protection.

A `pre-receive` hook runs on the receiving side before any ref is updated and rejects the whole push by exiting non-zero. This one scans every commit that the push would introduce:

<!-- snippet: ch21b/push-guard/01-install-server-hook -->
```text
$ cat kit/pre-receive
#!/bin/sh
# Server-side guard: refuse a push if any commit it introduces contains a secret pattern.
pattern='DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'
while read old new ref; do
  case "$new" in *[!0]*) ;; *) continue ;; esac          # a deletion: nothing to scan
  for c in $(git rev-list "$new" --not --all); do
    if git grep -q -E "$pattern" "$c"; then
      echo "push declined: $ref: commit $(git rev-parse --short "$c") contains a secret pattern"
      exit 1
    fi
  done
done
$ cp kit/pre-receive server.git/hooks/pre-receive
```
<!-- /snippet -->

A commit with a `.env` is declined, and nothing reaches the server:

<!-- snippet: ch21b/push-guard/02-push-blocked -->
```text
$ cd triage
$ printf 'LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345\n' > .env
$ git add -A && git commit -q -m 'Add local settings'
$ git push 2>&1
remote: push declined: refs/heads/main: commit 49384d9 contains a secret pattern        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

Now the instructive part. The developer deletes the file in a second commit and pushes again:

<!-- snippet: ch21b/push-guard/03-deleting-does-not-unblock -->
```text
$ git rm -q .env && git commit -q -m 'Remove .env'
$ git log --oneline origin/main..main
8546eb9 Remove .env
49384d9 Add local settings
$ git push 2>&1
remote: push declined: refs/heads/main: commit 49384d9 contains a secret pattern        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

Still declined, and for the reason of section 21B.10: the push would deliver commit `49384d9`, whose snapshot contains the key, whatever a later commit does. GitHub's push protection behaves the same way and for the same reason: the secret has to be removed from the commit that introduced it. Because nothing has been pushed, that is cheap: replace the unpushed commits.

<!-- snippet: ch21b/push-guard/04-rewrite-unpushed-commits -->
```text
# Nothing was pushed, so the two commits can be replaced. This is the cheap moment.
$ git reset -q --soft origin/main
$ git status -s
$ printf '.env\n' > .gitignore && git add .gitignore && git commit -q -m 'Ignore .env'
$ git push 2>&1
To ../server.git
   c3cf659..5584d4f  main -> main
[exit status: 0]
$ git -C ../server.git log --oneline main
5584d4f Ignore .env
c3cf659 Add ticket router
```
<!-- /snippet -->

Before the first push is the one moment at which rewriting history fully removes a secret. A push-time block exists to keep you there.

A client-side `pre-commit` hook catches the mistake one step earlier, and can be skipped by the person it is meant to stop:

<!-- snippet: ch21b/push-guard/05-client-hook -->
```text
$ cat ../kit/pre-commit
#!/bin/sh
# Client-side guard: refuse a commit whose staged additions match a secret pattern.
if git diff --cached -U0 | grep -E '^\+.*DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' > /dev/null; then
  echo "pre-commit: a staged line matches a secret pattern; commit refused" >&2
  exit 1
fi
$ cp ../kit/pre-commit .git/hooks/pre-commit
$ printf 'token: DUMMY-TOKEN-not-a-real-secret-67890\n' > debug.yaml
$ git add debug.yaml
$ git commit -m 'Add debug settings'
pre-commit: a staged line matches a secret pattern; commit refused
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch21b/push-guard/06-client-hook-bypassed -->
```text
$ git commit -q --no-verify -m 'Add debug settings'
[exit status: 0]
$ git log --oneline -1
4be6dc6 Add debug settings
# The client hook is advice. The server hook is enforcement:
$ git push 2>&1
remote: push declined: refs/heads/main: commit 4be6dc6 contains a secret pattern        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

Local hooks are advice; a server-side check is enforcement. On GitHub the corresponding enforcement points are push protection, push rulesets and required checks (Chapter 18).

**Scanners.** As of 1 October 2026 ([TruffleHog](https://github.com/trufflesecurity/trufflehog/blob/main/README.md), [gitleaks](https://github.com/gitleaks/gitleaks/blob/master/README.md), [Betterleaks](https://github.com/betterleaks/betterleaks), [detect-secrets](https://github.com/Yelp/detect-secrets), [git-secrets](https://github.com/awslabs/git-secrets)):

- TruffleHog (v3.97.9, AGPL-3.0) verifies candidates against provider APIs and can enumerate deleted and hidden commits.
- gitleaks (v8.30.1) declares itself feature-complete, with security patches only; its author moved to Betterleaks (v1.9.0, MIT), whose governance and detection-quality claims come from one news article and are not independently verified.
- detect-secrets' last release is 1.5.0 of May 2024; git-secrets has no tagged releases.

None is installed here, so none is demonstrated. Run your choice in two places: as a pre-commit hook for fast feedback, and in CI over the full history, where it cannot be skipped.

## 21B.13 Dependabot, code scanning, and a way to report vulnerabilities

These are the remaining layers of a repository's baseline. All are GitHub features, described from the documentation.

**Dependabot** is three features that share a name ([Dependabot alerts](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-alerts), [security updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-security-updates), [version updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates)):

| Feature | What it does | Enabled by | Limits worth knowing |
|---|---|---|---|
| Alerts | tells you a dependency on the default branch has a known vulnerability | repository or organization settings; needs the dependency graph | only advisories reviewed by GitHub raise alerts; archived repositories are not scanned; for Actions, alerts exist only for actions referenced by semantic version, not by commit SHA |
| Security updates | opens a pull request that raises a vulnerable dependency to the minimum patched version | settings; needs alerts | grouped per ecosystem if you enable grouping |
| Version updates | opens pull requests to keep dependencies current, vulnerable or not | committing `.github/dependabot.yml` | since 14 July 2026 a default cooldown of 3 days applies to version updates and not to security updates ([changelog](https://github.blog/changelog/2026-07-14-dependabot-version-updates-introduce-default-package-cooldown/)) |

All three are free on every plan. Note the trade-off with Chapter 21A's advice to pin actions by SHA: pinned actions get no Dependabot *alerts*, so version updates must move the pins.

A configuration for a Python service with a Dockerfile and workflows. It is assembled from keys documented in the [options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference), which requires `version: 2`, `updates`, and for each entry `package-ecosystem`, `directory` or `directories`, and `schedule.interval`; for GitHub Actions the documented directory value is `/`. It was parse-checked locally and not run on GitHub.

<!-- snippet: ch21b/lab-30-2-dependabot/01-file -->
```text
$ cat .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "uv"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      python-minor-and-patch:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 7
```
<!-- /snippet -->

Two things older configurations get wrong: the `reviewers` option was removed on 8 August 2025 in favor of CODEOWNERS, and the comment commands such as `@dependabot merge` stopped working on 27 January 2026 ([reviewers](https://github.blog/changelog/2025-08-08-dependabot-reviewers-configuration-option-is-replaced-by-code-owners/), [comment commands](https://github.blog/changelog/2026-01-27-changes-to-github-dependabot-pull-request-comment-commands/)). Without explicit configuration at most five version-update pull requests stay open at once; security updates do not count toward that limit.

**Code scanning** analyzes code for vulnerabilities and coding errors with CodeQL or third-party tools that upload SARIF. It runs on GitHub Actions and consumes minutes; it is free on public repositories and needs GitHub Code Security ($30 per active committer per month) on private ones. GitHub recommends default setup, which requires Actions to be enabled and the repository to be public or licensed ([code scanning](https://docs.github.com/en/code-security/concepts/code-scanning/code-scanning), [default setup](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/configure-code-scanning/configure-code-scanning)). One documented surprise: if a repository with default setup sees no pushes and no pull requests for six months, the weekly scheduled scan is disabled. Code scanning does not find secrets or vulnerable dependencies; those are the features above.

**A security policy and private vulnerability reporting.** A `SECURITY.md` file states which versions you support and how to report a problem; an organization can provide a default through its `.github` repository ([security policy](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/add-security-policy)). Private vulnerability reporting is a separate feature that administrators of public repositories can enable; it adds a "Report a vulnerability" button on the Advisories page, and the report lands in a private draft advisory ([reporting privately](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately)). The reason to do both is in section 21B.15: a researcher who found a government contractor's leaked credentials could not find a way to report them and went to the press.

## 21B.14 Responding to a leaked secret: six steps, in this order

The order matters more than the tools. The names of the phases follow common incident-response practice; the Phase 0 report did not check them against a cited standard, and legal notification duties are outside this course.

| Step | What the sources prescribe | Evidence of what goes wrong otherwise |
|---|---|---|
| 1. Contain | **Revoke or rotate the credential first.** That alone may be sufficient, and a history rewrite may not be warranted ([GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository), [OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)) | an xAI key valid about two months after the first alert; a contractor's AWS keys valid 48 hours after the repository was taken down ([Krebs on Security](https://krebsonsecurity.com/2026/05/cisa-admin-leaked-aws-govcloud-keys-on-github/)); the Internet Archive breached a second time through tokens it had not rotated ([BleepingComputer](https://www.bleepingcomputer.com/news/security/internet-archive-breached-again-through-stolen-access-tokens/)) |
| 2. Assess | Identify the secret, its owner and what it can reach; check validity status and exposure labels; review GitHub audit logs and the provider's logs for use; include forks, deleted forks and force-pushed commits in scope ([remediation guide](https://docs.github.com/en/code-security/tutorials/remediate-leaked-secrets/remediating-a-leaked-secret)) | an affected company declined to say whether logs showed third-party use of an exposed token ([TechCrunch](https://techcrunch.com/2024/01/26/mercedez-benz-token-exposed-source-code-github/)) |
| 3. Eradicate | Remove the secret from current code; rewrite history only where warranted, with git-filter-repo 2.47 or later, then force-push, then a GitHub Support request. Support assists only where rotation cannot mitigate the risk ([GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)) | after a supply-chain compromise the scope is every credential reachable from the affected runtime ([CISA](https://www.cisa.gov/news-events/alerts/2025/03/18/supply-chain-compromise-third-party-tj-actionschanged-files-cve-2025-30066-and-reviewdogaction)) |
| 4. Recover | Update dependent services with the new credential; if history was rewritten, have collaborators re-clone and re-enable force-push protection; close the alert as revoked and document | partial rotation produced a second breach (Internet Archive) |
| 5. Communicate | Track internally; tell collaborators exactly what to do with their clones; keep a reachable disclosure contact such as `SECURITY.md` | a researcher could not find a way to report a contractor's leak and went to the press ([Cybersecurity Dive](https://www.cybersecuritydive.com/news/cisa-github-passwords-leak-contractor-report/824953/)); concealment turned Uber's 2016 breach into a regulatory case ([FTC](https://www.ftc.gov/news-events/news/press-releases/2018/04/uber-agrees-expanded-settlement-ftc-related-privacy-security-claims)) |
| 6. Prevent | Push protection; pre-commit and CI scanning; secrets out of code; short-lived credentials through OIDC; least privilege; staging named files and reviewing `git diff --cached` instead of `git add .`; scheduled rotation | hardcoded long-lived keys recur in every case of section 21B.15 |

**Why containment comes first.** The repository is not where the damage happens. The damage happens at the issuer, where the key is accepted. Until revocation the key works for whoever copied it, and revocation is the only step that is complete: it works against clones, forks, caches and screenshots alike. GitHub's own guidance says the same: rotate immediately; removing the secret from history is time-consuming and often unnecessary once the credential is revoked ([secret scanning](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning#secret-scanning-alerts-and-remediation)).

**What assessment has to produce.** Five facts, written down: which secret and what it can reach; the first commit that contains it and when that commit was first pushed; which refs contain it (section 21B.11 gives the commands); who could read it (repository visibility, forks, collaborators, CI logs); and whether it was used, from the *provider's* logs. Git answers the second and third. Only the issuer answers the last.

**When a history rewrite is warranted.** Rewrite when the data stays harmful after rotation or cannot be rotated: personal data, customer records, proprietary model weights, a private key whose public half is pinned in devices, a secret whose revocation takes weeks. Do not rewrite by reflex for an API key that was revoked within the hour: the rewrite costs every collaborator their clone, invalidates every recorded commit ID, strips signatures, and cannot recall copies that already exist. Record the decision and its reason.

## 21B.15 Case studies

Each row is from the Phase 0 report with its source. The root-cause column repeats one pattern: a long-lived, over-scoped credential written where it should never have been.

| Case | What was exposed and for how long | Root cause | Lesson |
|---|---|---|---|
| Uber, 2016 ([FTC](https://www.ftc.gov/business-guidance/blog/2018/04/ftc-addresses-ubers-undisclosed-data-breach-new-proposed-order)) | a cloud access key in a private GitHub repository; intruders downloaded tens of millions of records in a month | plaintext key in source code; reused passwords; no multi-factor requirement on GitHub accounts | a private repository is only as private as its weakest member account |
| Toyota, 2022 ([BleepingComputer](https://www.bleepingcomputer.com/news/security/toyota-discloses-data-leak-after-access-key-exposed-on-github/)) | a data-server access key public from December 2017 to September 2022; 296,019 customers potentially exposed | a subcontractor published internal code with a hardcoded key | keys that never expire turn one mistake into a five-year exposure |
| Samsung, 2022 ([GitGuardian](https://blog.gitguardian.com/samsung-and-nvidia-are-the-latest-companies-to-involuntarily-go-open-source-potentially-leaking-company-secrets/)) | 6,695 secrets inside stolen source code | thousands of credentials hardcoded in private code | assume source code will leak |
| Microsoft AI research, 2020 to 2023 ([Wiz](https://www.wiz.io/blog/38-terabytes-of-private-data-accidentally-exposed-by-microsoft-ai-researchers)) | a storage URL in a public model repository granted full control of an account holding 38 TB | an over-scoped, long-lived sharing token committed to the repository | a data-sharing URL is a credential; share weights through read-only, expiring mechanisms |
| Hugging Face tokens, 2023 ([TechTarget](https://www.techtarget.com/searchsecurity/news/366562216/Exposed-Hugging-Face-API-tokens-jeopardized-GenAI-models)) | 1,681 valid tokens giving access to 723 organizations, 655 with write permission | tokens committed to code | a model-hub write token is a supply-chain credential |
| Mercedes-Benz, 2024 ([TechCrunch](https://techcrunch.com/2024/01/26/mercedez-benz-token-exposed-source-code-github/)) | an employee token public for about four months gave unrestricted access to the company's GitHub Enterprise Server | broad, long-lived token in a public repository | one over-scoped token equals the whole code estate |
| The New York Times, 2024 ([BleepingComputer](https://www.bleepingcomputer.com/news/security/new-york-times-source-code-stolen-using-exposed-github-token/)) | a 273 GB archive of repositories leaked five months after a GitHub credential was exposed | exposed token with organization-wide read access | least-privilege, expiring tokens bound the damage |
| xAI, 2025 ([Krebs on Security](https://krebsonsecurity.com/2025/05/xai-dev-leaks-api-key-for-private-spacex-tesla-llms/)) | an LLM API key with access to at least 60 private and fine-tuned models, valid two months after the first alert | key hardcoded and pushed; alert sent only to an individual | an alert in one inbox is not an incident process |
| CISA contractor, 2025 to 2026 ([Krebs on Security](https://krebsonsecurity.com/2026/05/cisa-admin-leaked-aws-govcloud-keys-on-github/)) | administrative cloud credentials and plaintext passwords in a public repository for six months | work material copied to a personal public repository with secret detection deliberately disabled | controls an individual can switch off need organizational backstops and a leak playbook |

The report flags these details as partially confirmed, so quote them as the cited articles do: the Mercedes-Benz day-level timeline; the New York Times archive size (273 GB in the cited article, often rounded to 270 GB); the Internet Archive user count; Samsung's own confirmation; Toyota's original notice. The report found no verified 2026 incident caused specifically by a key in a public Jupyter notebook: notebooks are documented as a leak mechanism, not through a named breach.

**For an LLM engineer:** an LLM API key reaches more than a bill (the xAI key reached private and fine-tuned models); a link that shares weights or data is a credential with a scope and a lifetime; and a model-hub token with write permission lets its holder replace what your users download.

## 21B.16 History rewriting as an operation

**In one sentence.** A whole-history rewrite replaces the first affected commit and every descendant with new commits that have new IDs, and the command is the smallest part of the work.

**Analogy.** Recalling a printed book to remove one page: you can reprint every copy in your warehouse, but each reader's copy stays as it was until that reader exchanges it, the page numbers after the removed page all change, every citation by page number now points at the wrong place, and one reader who lends an old copy to the library puts the page back on the shelf.

**Precisely: what git-filter-repo does and requires.** The recommended tool is [git-filter-repo](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt), a separate program that is not part of Git. From its manual and from GitHub's procedure ([removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)):

- It refuses to run outside a fresh clone unless forced with `--force`, because the rewrite is irreversible: by default it ends with an immediate pruning of reflogs and old objects.
- `--sensitive-data-removal` exists since version 2.47. It fetches all refs first and gathers the extra information needed to clean up other copies.
- It records its work in `.git/filter-repo/`: `commit-map` (old and new ID of every commit), `ref-map`, `changed-refs` and `first-changed-commits`.
- Commits get new IDs, so signatures on commits and tags cannot remain valid and are removed; signed tags become annotated tags.
- By default a full rewrite removes the `origin` remote, as a forcing function against pushing by reflex.

GitHub's documented sequence, shown without output because git-filter-repo is not installed here and nothing in this course contacts GitHub:

```bash
# 1. Install the tool (GitHub's page gives this command for macOS). You need version 2.47 or later.
brew install git-filter-repo

# 2. A fresh clone, never your working clone.
git clone https://github.com/YOUR-USERNAME/YOUR-REPOSITORY
cd YOUR-REPOSITORY

# 3a. Remove a file from every commit ...
git-filter-repo --sensitive-data-removal --invert-paths --path PATH-TO-YOUR-FILE-WITH-SENSITIVE-DATA

# 3b. ... or replace strings listed in a file (one expression per line; by default each is
#     literal text and is replaced by ***REMOVED***; "regex:" and "glob:" prefixes exist).
git-filter-repo --sensitive-data-removal --replace-text ../passwords.txt

# 4. How many pull requests are affected? Support will ask.
grep -c '^refs/pull/.*/head$' .git/filter-repo/changed-refs

# 5. Force-push every ref.
git push --force --mirror origin
```

> **Unverified.** Whether git-filter-repo keeps the `origin` remote when `--sensitive-data-removal` is used was not tested for the Phase 0 report: GitHub's instructions push to `origin` afterwards, and the manual says a default full rewrite removes it. If the push fails for a missing remote, the manual's remedy is `git remote add origin <url>`.

Before pushing, the manual's verification is `git log --all --name-status -- <file>` and `git log -S"<string>" --all -p --`: both must print nothing.

**What makes it an operation.** Around those five commands:

| Fact | Consequence |
|---|---|
| Other contributors must stop work during the cleanup | announce a freeze; work pushed during the rewrite is discarded or forces a restart |
| All refs, tags included, must be force-pushed | rules that block force pushes and tag updates must be switched off temporarily, and back on afterwards |
| Every descendant commit ID changes | review comments on open pull requests detach; diffs of closed ones break; every recorded ID is stale |
| Signatures are removed, also on commits that predate the removed data | a "require signed commits" rule now rejects the rewritten history unless bypassed |
| Orphaned LFS objects are not removed by the rewrite | they are purged separately |
| Pull request refs, forks and other clones keep the old history | sections 21B.18 and 21B.19 |

For an ML team the changed IDs have a specific cost: every experiment record, model card and deployment manifest that stored an old commit ID now points at a commit that no longer exists on the remote. The `commit-map` file belongs in the incident record so that old IDs can be translated.

> **Outdated advice.** Older guides use `git filter-branch` or the BFG Repo-Cleaner. Git's own manual says of `git filter-branch` that its "use is not recommended" and points to git-filter-repo (`git help filter-branch`, section WARNING). GitHub's current page documents git-filter-repo only.

## 21B.17 The mechanics, seen locally

git-filter-repo is not installed in the lab, and the course installs nothing. The transcripts in this section and the next use `git filter-branch`, **only because it ships with Git**. It is not the recommended tool. It suffices to show four mechanics that are the same whichever tool rewrites: descendants get new IDs, tags must be rewritten too, old objects remain until pruned, and the server keeps them after the push.

Start from a fresh mirror clone, which has every ref of the server as a local ref, and note the commit that introduced the file:

<!-- snippet: ch21b/rewrite-mechanics/01-fresh-mirror-clone -->
```text
$ git clone -q --mirror server.git cleanup.git
$ cd cleanup.git
$ git for-each-ref --format="%(objectname:short) %(objecttype) %(refname)"
7fae871 commit refs/heads/feature/streaming
d4b8762 commit refs/heads/main
b4a2514 tag refs/tags/v0.1.0
c38ee42 tag refs/tags/v0.2.0
$ git log --oneline main
d4b8762 Document setup in README
b509fe3 Add request timeout
64b9b89 Add retry with backoff
0805fd8 Add staging settings
987a49d Add evaluation harness
6388058 Add LLM client
0c55276 Add answer prompt template
dfd59fd Add BM25 retriever
$ first=$(git log --format=%h --diff-filter=A main -- .env); echo $first
0805fd8
```
<!-- /snippet -->

**Mistake first: rewriting the branches and forgetting the tags.** 🔴 A history filter replaces commits on every ref it is given; run it only in a clone you can throw away.

<!-- snippet: ch21b/rewrite-mechanics/02-branches-only -->
```text
# First attempt: rewrite the branches and forget the tags.
$ FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --index-filter 'git rm --cached --ignore-unmatch -q .env' -- --branches > ../filter-1.log 2>&1
$ grep -v 'seconds passed' ../filter-1.log
Ref 'refs/heads/feature/streaming' was rewritten
Ref 'refs/heads/main' was rewritten
$ git grep -l DUMMY-KEY $(git rev-list --branches) | wc -l
       0
$ git grep -l DUMMY-KEY $(git rev-list --all) | cut -c1-9,41-
d4b876277:.env
7fae87198:.env
b509fe363:.env
64b9b890c:.env
0805fd8e8:.env
$ git tag --contains $first
v0.2.0
```
<!-- /snippet -->

The branches are clean, and a scan over `--all` still finds five snapshots with the key. The tag `v0.2.0` points at the old commit `64b9b89`, and a tag keeps its commit and all of that commit's ancestors alive. Anyone who fetches the tag fetches the secret. (`--all` also includes the backup refs that `filter-branch` wrote under `refs/original/`.)

**All refs, with tags following their commits.**

<!-- snippet: ch21b/rewrite-mechanics/03-all-refs -->
```text
# Second attempt: every ref, and --tag-name-filter cat so that tags follow their commits.
$ FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --index-filter 'git rm --cached --ignore-unmatch -q .env' --tag-name-filter cat -- --all > ../filter-2.log 2>&1
$ grep -v 'seconds passed' ../filter-2.log
WARNING: Ref 'refs/heads/feature/streaming' is unchanged
WARNING: Ref 'refs/heads/main' is unchanged
WARNING: Ref 'refs/tags/v0.1.0' is unchanged
Ref 'refs/tags/v0.2.0' was rewritten
v0.1.0 -> v0.1.0 (987a49db5aa45d6cb1e4b10024438f21b8e28444 -> 987a49db5aa45d6cb1e4b10024438f21b8e28444)
v0.2.0 -> v0.2.0 (64b9b890cf46c6a921380d722eaf0b33d790bb9a -> 66a99cccb3cd6ac483eccafadf8c4804770799ea)
```
<!-- /snippet -->

The branches are reported "unchanged" because the first run already rewrote them. `v0.1.0` is unchanged because it points before the leak. `v0.2.0` now points at `66a99cc`.

**Every descendant has a new ID; ancestors keep theirs.**

<!-- snippet: ch21b/rewrite-mechanics/04-new-ids -->
```text
# old ID, new ID, subject (newest first)
$ paste ../before.txt ../after.txt | while read o n; do printf '%s  %s  %s\n' $o $n "$(git log -1 --format=%s $n)"; done
d4b8762  c8ce738  Document setup in README
b509fe3  51e2d95  Add request timeout
64b9b89  66a99cc  Add retry with backoff
0805fd8  0ac4257  Add staging settings
987a49d  987a49d  Add evaluation harness
6388058  6388058  Add LLM client
0c55276  0c55276  Add answer prompt template
dfd59fd  dfd59fd  Add BM25 retriever
```
<!-- /snippet -->

`0805fd8` became `0ac4257` because its tree changed: `.env` is no longer in it. `64b9b89`, `b509fe3` and `d4b8762` changed for two reasons. A commit is a full snapshot, so `.env` was in the tree of every commit from the leak onward, and each of those trees is a different tree without it. And each commit records its parent's ID, and the parent changed. The second reason is enough by itself: a commit whose tree stayed identical would still get a new ID once its parent has one. What these three commits introduce, their diff against the parent, is the same as before. The four commits below the leak are byte-for-byte the same objects. This table is what git-filter-repo writes to `commit-map`.

```text
 before                                              v0.2.0
                                                       |
  dfd59fd--0c55276--6388058--987a49d--0805fd8--64b9b89--b509fe3--d4b8762   main
                                |     (.env added)          \
                              v0.1.0                         7fae871       feature/streaming

 after                                               v0.2.0
                                                       |
  dfd59fd--0c55276--6388058--987a49d--0ac4257--66a99cc--51e2d95--c8ce738   main
                                |     (no .env)             \
                              v0.1.0                         ba9f0e0       feature/streaming

  shared, unchanged: dfd59fd .. 987a49d        replaced: everything from the first changed commit on
```

**The old objects are still there.** A rewrite adds new objects and moves refs. It deletes nothing by itself.

<!-- snippet: ch21b/rewrite-mechanics/05-old-objects-remain -->
```text
$ git for-each-ref --format="%(objectname:short) %(refname)" refs/original
64b9b89 refs/original/refs/tags/v0.2.0
$ git cat-file -t $first
commit
$ git show $first:.env
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
LLM_BASE_URL=https://llm.example.com
```
<!-- /snippet -->

Removing them takes three deliberate steps: delete the backup refs, expire the reflogs, prune.

<!-- snippet: ch21b/rewrite-mechanics/06-prune -->
```text
$ git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
$ git reflog expire --expire=now --all
$ git gc -q --prune=now
$ git cat-file -t $first
fatal: Not a valid object name 0805fd8
[exit status: 128]
$ git grep -l DUMMY-KEY $(git rev-list --all) | wc -l
       0
$ git fsck --no-progress
```
<!-- /snippet -->

git-filter-repo performs this pruning for you at the end of its run, which is why it insists on a fresh clone. 🔴 `git reflog expire --expire=now --all` followed by `git gc --prune=now` destroys the local safety net of Chapter 13: after it, nothing that was only reachable from a reflog can be recovered. In a throwaway mirror clone that is the intention. In your working clone it also discards every stash.

**The force push moves the server's refs, and only the refs.** 🔴 `git push --force --mirror` overwrites every ref on the remote and deletes those the clone lacks (section 21B.23).

<!-- snippet: ch21b/rewrite-mechanics/07-force-push -->
```text
$ git push --force --mirror origin 2>&1
To $LAB/ch21b/rewrite-mechanics/server.git
 + 7fae871...ba9f0e0 feature/streaming -> feature/streaming (forced update)
 + d4b8762...c8ce738 main -> main (forced update)
 + c38ee42...17124a2 v0.2.0 -> v0.2.0 (forced update)
```
<!-- /snippet -->

<!-- snippet: ch21b/rewrite-mechanics/08-server-keeps-old-objects -->
```text
$ cd ..
$ git -C server.git log --oneline -1 main
c8ce738 Document setup in README
$ git -C server.git grep -l DUMMY-KEY $(git -C server.git rev-list --all) | wc -l
       0
# No ref on the server reaches the old commits any more, and they are still there:
$ git -C server.git cat-file -t $first
commit
$ git -C server.git show $first:.env
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
LLM_BASE_URL=https://llm.example.com
$ git -C server.git fsck --no-progress --unreachable | grep commit
unreachable commit 0805fd8e82dfc4c6a50cb14514d431dbd43df4cd
unreachable commit b509fe3635defadb4fc29d14c01ca2953ca8cd27
unreachable commit d4b876277f85823455b617a02ea443e6e9afd070
unreachable commit 64b9b890cf46c6a921380d722eaf0b33d790bb9a
unreachable commit 7fae8719801ebfc91df813470f8a380ac13184fc
```
<!-- /snippet -->

No ref on the server reaches the secret, the scan over all refs is clean, and `git show` on the server still prints the key from the unreachable commit. A bare repository of your own can be pruned with `git gc --prune=now`. On GitHub you cannot run that; section 21B.19 explains who can.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| history rewrite in the cleanup clone | rewritten to the new tip (none in a mirror clone) | rewritten | unchanged (still names the branch) | moved to the new tip | every affected branch and tag moved; backup refs or `filter-repo/` metadata written; old objects kept until pruned | unchanged | unchanged |
| `git reflog expire --expire=now --all` then `git gc --prune=now` | unchanged | unchanged | unchanged | unchanged | all reflog entries and all unreachable objects deleted | unchanged | unchanged |
| `git push --force --mirror origin` | unchanged | unchanged | unchanged | unchanged | unchanged | every ref set to the local value; refs missing locally are **deleted**; old objects stay as unreachable | branch and tag refs move; pull request refs are refused; cached views and old objects stay until Support acts |

`--mirror` deletes remote refs that the cleanup clone does not have. A branch that a colleague pushed after you cloned is removed by your push. That is the mechanical reason for the freeze.

## 21B.18 The stale clone that pushes the secret back

Asha cloned before the incident and has one local commit. She was not told to stop, or did not read the message. She does what she does every morning:

<!-- snippet: ch21b/rewrite-mechanics/09-stale-clone -->
```text
$ cd asha
$ git log --oneline -3
95f98b0 Add contains metric
d4b8762 Document setup in README
b509fe3 Add request timeout
$ git pull --no-rebase 2>&1
From ../server
 + d4b8762...c8ce738 main              -> origin/main  (forced update)
 + 7fae871...ba9f0e0 feature/streaming -> origin/feature/streaming  (forced update)
Merge made by the 'ort' strategy.
$ git log --oneline --graph -6
*   f7ed5a9 Merge branch 'main' of ../server
|\  
| * c8ce738 Document setup in README
| * 51e2d95 Add request timeout
| * 66a99cc Add retry with backoff
| * 0ac4257 Add staging settings
* | 95f98b0 Add contains metric
$ git push 2>&1
To ../server.git
   c8ce738..f7ed5a9  main -> main
```
<!-- /snippet -->

The fetch reports forced updates. `git pull` then merges the new `origin/main` into her `main`, which still descends from the old history. The merge commit `f7ed5a9` has two parents: the clean tip `c8ce738` and her commit `95f98b0`, whose ancestors include `0805fd8`. Her push is a fast-forward from `c8ce738` to `f7ed5a9`, so the server accepts it without force, and no branch rule that forbids force pushes objects.

<!-- snippet: ch21b/rewrite-mechanics/10-secret-is-back -->
```text
$ cd ..
$ git -C server.git log --oneline -3 main
f7ed5a9 Merge branch 'main' of ../server
95f98b0 Add contains metric
c8ce738 Document setup in README
$ git -C server.git grep -l DUMMY-KEY $(git -C server.git rev-list --all) | wc -l
       6
$ git -C server.git log --oneline -S'DUMMY-KEY' main
0805fd8 Add staging settings
```
<!-- /snippet -->

```text
                 0805fd8--64b9b89--b509fe3--d4b8762--95f98b0
                /        (old history, with .env)            \
  ...--987a49d                                                f7ed5a9   main (on the server again)
                \                                            /
                 0ac4257--66a99cc--51e2d95--c8ce738---------
                         (rewritten history)
```

```text
Observed behavior : the day after the cleanup, the scanner reports the same secret on main
Git state         : main is a merge commit with the rewritten tip and a commit from the old history as parents
Mechanism         : a pull in a stale clone merged old and new history; the push was a fast-forward
Root cause        : a clone that still held the old commits was allowed to push
Why Git does this : to Git the two histories are unrelated lines of work that someone chose to merge
Correct fix       : force-push the clean refs again; clean or replace the stale clone; replay only her own commit
Prevention        : freeze and re-clone; rebase onto the new history, never merge; a server-side check that
                    rejects the first changed commit or the secret pattern
```

GitHub's page lists "high risk of recontamination" first among the side effects of a rewrite and gives the rule: collaborators must rebase, not merge, branches created from the old history, because one merge commit can reintroduce some or all of it. The filter-repo manual says the easiest way to clean other clones is to delete and re-clone them. Where that is impossible, it prescribes, per clone:

```bash
git tag -l | xargs git tag -d        # tags are not updated by a normal fetch; delete, then refetch
git fetch --prune --tags
git rebase --onto origin/main <old-upstream-tip> <branch>     # replay only your own commits
git reflog expire --expire=now --all
git gc --prune=now
git cat-file -t <first-changed-commit>                        # must fail
```

The base of that rebase matters. In a clone that has already fetched, `git rebase origin/main` treats every old commit that is missing from the new history as yours and tries to replay it, the commit that added the secret included:

<!-- snippet: ch21b/stale-clone-rebase/02-fetch-then-rebase -->
```text
$ cd asha2
$ git fetch -q 2>&1
$ git rebase origin/main 2>&1 | grep -E "^(CONFLICT|error|Could not)"
CONFLICT (add/add): Merge conflict in settings.yaml
error: could not apply 0805fd8... Add staging settings
Could not apply 0805fd8... # Add staging settings
$ git status -sb | head -1
## HEAD (no branch)
$ git rebase --abort
$ cd ..
```
<!-- /snippet -->

When run for this chapter, `git pull --rebase` as a clone's *first* contact with the rewritten history replayed only the local commit, because the pull still knew the previous value of `origin/main` (`labs/run ch21b/stale-clone-rebase` shows all three variants). That knowledge is gone after a plain fetch or a merge, so the instruction to colleagues is the explicit `--onto` form. Lab 31.1 performs the whole sequence in Asha's clone. The manual adds two warnings: colleagues must not run the same filter command themselves, because identical commands can still produce different commit IDs; and the expiry step drops their reflogs and stash entries.

Few hosting services can ban a specific commit from being pushed again; the filter-repo manual says so, and the Phase 0 notes found no documented built-in control of that kind on GitHub. Push protection (when the secret matches a supported pattern) and a push ruleset that blocks the file path are the nearest platform equivalents. The local analogue is the `pre-receive` hook of section 21B.12, which Lab 31.1 installs and tests against a second stale clone.

## 21B.19 The GitHub side of a rewrite: pull requests, forks, cached views, Support

> **GitHub, not Git.** This section is described from GitHub's page on [removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository). Nothing here was run.

After your force push, four copies remain that you cannot reach with Git:

| Where | Why it survives | Who can remove it |
|---|---|---|
| Unreachable commits in the repository | a force push moves refs; the objects stay, and are served by commit ID in cached views | GitHub Support, by running garbage collection and removing cached views |
| Pull request refs | `refs/pull/N/head` is read-only for you and keeps the old commits reachable | GitHub Support, by dereferencing or deleting the affected pull requests |
| Forks | each fork has its own refs to the old commits, and the fork network shares objects | each fork's owner; GitHub cannot provide their contact information |
| Clones | they are on other people's disks | their owners |

The Support request must contain the repository owner and name, the number of affected pull requests, and the first changed commit or commits from git-filter-repo's output; if the output contained the line about orphaned LFS objects, mention it and attach the named file. Support removes only sensitive data, and only in cases where it determines that rotating the affected credentials cannot mitigate the risk.

> **Unverified.** GitHub publishes neither how long it retains unreachable commits without a Support-initiated garbage collection nor a turnaround time for Support. Researchers who mined force-pushed commits observed that they appear to be kept indefinitely; that is their observation, not a GitHub statement.

The same retention makes the recovery of a force-pushed branch possible in Chapter 13: a force push does not delete.

## 21B.20 Governance controls that limit blast radius

Prevention fails sometimes, so design for the day it does. These controls decide how much one leaked credential can do and whether you can reconstruct what it did. They are GitHub features from the Phase 0 report; the chapters named cover each in depth.

| Control | What it limits | Source |
|---|---|---|
| Fine-grained or App tokens with expiry, and organization approval of tokens | the reach and lifetime of a stolen token | [token policy](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization) |
| Mandatory two-factor authentication and SSO authorization | account takeover by password | Chapter 16 |
| Rulesets on branches, tags and pushes; push rulesets can block file paths, extensions and sizes across the whole fork network | what a compromised contributor can change, and what can be pushed at all | Chapter 18 |
| Code-owner review of `.github/workflows/` and of the CODEOWNERS file itself | silent changes to automation | [code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners#codeowners-and-branch-protection) |
| Audit log, 180 days at organization level, exported or streamed if Git events must be available later (the enterprise log retains them for seven days) | your ability to answer "what did the token do?" | [audit log](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization) |
| The preview ruleset rule that blocks merging a pull request which introduces an open secret alert (9 September 2026; needs Secret Protection) | secrets entering the default branch through review | [changelog](https://github.blog/changelog/2026-09-09-block-pull-requests-with-exposed-secrets-from-merging/) |

These controls reduce blast radius; they do not prevent leaks. The report's observation across the cases is sobering: the worst outcomes involved single credentials with estate-wide read access, and detection came from outsiders in nearly every case. An organization that wants to know first needs its own monitoring of public GitHub, employees' and contractors' personal accounts included.

## 21B.21 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| `fatal: detected dubious ownership in repository` | the repository directory belongs to another user ID (containers, CI, shared volumes) | add that one directory to `safe.directory` in global configuration, or fix ownership | build images so the checkout is owned by the user that runs Git |
| A Git command ran a program you did not expect | `git hook list --show-scope <event>`; `git config list --show-origin` and look for aliases, pagers, `core.fsmonitor`, `core.hooksPath` | remove the setting; if the `.git` came from an archive, stop and `git clone --no-local` it | clone, never unpack; `safe.bareRepository=explicit` |
| A colleague's name is on a commit they did not write | `git log --format='%h %an %cn %G?'`; on GitHub, the pusher in the Activity view or audit log | treat as an incident on the pushing account, not the named one | vigilant mode; require signed commits |
| A scanner reports a secret you deleted | `git log --all -S<secret>`; `git grep <secret> $(git rev-list --all)` | revoke at the issuer; decide on a rewrite | push protection; pre-commit and CI scanning |
| Push blocked for a secret that "is not in the code any more" | `git log --oneline @{u}..` shows an unpushed commit that still contains it | rewrite the unpushed commits (`git reset --soft @{u}` and recommit, or an interactive rebase) | review `git diff --cached` before committing |
| After a rewrite, the scan is still positive | tags or other branches were not rewritten; backup refs under `refs/original/` | rewrite all refs; delete backup refs; scan again | git-filter-repo with `--sensitive-data-removal` in a fresh clone |
| The secret returned to `main` after the cleanup | `git log --merges -1`; a merge whose parents span old and new history | force-push the clean refs again; clean the stale clone | freeze; re-clone; server-side check |
| The mirrored force push fails for `refs/pull/*` | the forge's pull request refs are locked (git-filter-repo manual) | expected; count them for the Support request | none |

## 21B.22 When not to use it, and dangerous edge cases

**Do not rewrite history**

- for a credential that is revoked and whose provider logs show no use. Record the decision and stop.
- on a public repository in the belief that it un-publishes anything.
- before containment.
- in your working clone. The tool prunes reflogs and stashes.
- by having each colleague run the same command. Identical commands can produce different IDs.

**Dangerous edge cases**

- **`git push --force --mirror` deletes.** Every remote ref absent from the cleanup clone is removed. Take the mirror clone after the freeze, not before.
- **Tags are not updated by an ordinary fetch.** A clone that pulled after the rewrite still holds the old `v0.2.0`, and with it the old history. Delete tags and refetch.
- **A deleted fork is not a deleted copy.** Objects in a fork network remain reachable from the other repositories of the network.
- **Rotating one of several credentials.** After a compromise of a runtime (a CI job, a laptop) the scope is every credential that runtime could read, rotated together. Partial rotation is how the Internet Archive was breached twice.
- **The secret in a commit message, a branch name, or a pull request description.** File-path removal does not touch these. `--replace-text` rewrites file contents; text on GitHub (issues, pull request bodies, comments) is edited or deleted on the platform.
- **`.gitignore` after the fact.** Ignoring a tracked file changes nothing; the file stays tracked until `git rm --cached`.

## 21B.23 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git log -S`, `git log -G`, `git grep <p> $(git rev-list --all)` | 🟢 SAFE | nothing | not needed | not needed |
| `git clone --no-local <dir> <new>` | 🟢 SAFE | creates a new repository | not needed | delete the directory |
| `git config set --global safe.bareRepository explicit` | 🟡 CAUTION | global configuration, a file that keeps no history; it changes how later commands treat bare repositories | `git config get --show-origin safe.bareRepository` | `git config unset --global safe.bareRepository` |
| `git config set --global --append safe.directory <dir>` | 🟡 CAUTION | makes Git trust that directory's configuration and hooks | read `<dir>/.git/config` and `<dir>/.git/hooks` first | `git config unset --global --value=<dir> safe.directory` |
| `git rm --cached <file>` | 🟡 CAUTION | removes the file from the index; the working tree copy stays | `git status` | `git restore --staged <file>` |
| `git reset --soft @{u}` | 🟡 CAUTION | moves the branch to the upstream tip; index and working tree keep your changes | `git log @{u}..` | `git reset --soft ORIG_HEAD` |
| `git rebase --onto <new> <old-base>` | 🟡 CAUTION | recreates your commits on the new history | `git log <old-base>..` | `git reset --hard ORIG_HEAD`, or the reflog |
| `git filter-repo ...`, `git filter-branch ...` | 🔴 DANGEROUS | every affected commit and all descendants, on every rewritten ref | git-filter-repo `--dry-run`; run in a fresh clone | the untouched server and other clones, until you push |
| `git reflog expire --expire=now --all` and `git gc --prune=now` | 🔴 DANGEROUS | deletes all reflog entries and all unreachable objects | `git fsck --unreachable --no-reflogs` lists what would go | none locally |
| `git push --force --mirror origin` | 🔴 DANGEROUS | sets every remote ref to the local value and deletes the rest | `git push --dry-run --force --mirror origin` | another clone that still has the old refs; on GitHub, the instruments of Chapter 13 |

For the three 🔴 commands, what the table does not say:

- **A history filter** can destroy signatures and, with a wrong path argument, files you meant to keep. It is appropriate for data that stays harmful after rotation. For an unpushed mistake on a private branch a rebase is the smaller tool.
- **Immediate expiry and prune** can destroy every commit, stash and staged blob that only a reflog, or nothing at all, was keeping. It is appropriate in a cleanup clone, and in a stale clone after its owner has saved their work.
- **A mirrored force push** can destroy branches and tags that exist only on the remote. It is appropriate once, after a freeze, at the end of a verified rewrite. Every other force push uses `--force-with-lease` (Chapter 12).

## 21B.24 Version notes

> **Version note.** Older behavior: Git read the configuration of any repository it discovered, whoever owned it. Current behavior: it refuses when the owner differs, unless `safe.directory` lists the directory. Since: the 2022 security releases. Recommended: list single directories; never `*` on a workstation.

> **Version note.** Older behavior: `safe.bareRepository` defaults to `all`. Current behavior: unchanged in 2.55; `explicit` becomes the default in Git 3.0. Since: the setting was added in 2022. Recommended: set `explicit` now if you do not work inside bare repositories.

> **Version note.** Older behavior: history was rewritten with `git filter-branch` or the BFG Repo-Cleaner. Current behavior: Git's manual recommends against `filter-branch`; GitHub documents git-filter-repo, with `--sensitive-data-removal` in version 2.47 or later. Recommended: git-filter-repo.

> **Version note.** Older behavior: a verified commit could become unverified when its key was revoked or expired. Current behavior: verification records persist. Since: 10 December 2024 on GitHub. Recommended: do not use the badge to find commits made with a stolen key.

The `git config get|set|unset|list` subcommands used in this chapter need Git 2.46 or later; older scripts write `git config --get` and `git config --add`.

## 21B.25 Practice

- [Lab 30.3](../lab-manual/m30-repository-security.md): scan a full history for planted dummy secrets with built-in commands, including the commit that only the reflog still reaches.
- [Lab 30.1 and Lab 30.2](../lab-manual/m30-repository-security.md): push protection on your practice repository, and a Dependabot configuration.
- [Lab 24.3](../lab-manual/m24-signing-github.md): the verification states on GitHub, with the forged commit of section 21B.5.
- [Lab 31.1](../lab-manual/m31-secret-leak-response.md): the tabletop. Do it twice; the second time from the symptom alone.
- The operational checklists and runbooks are in the [security guide](../guides/security-guide.md).
- Chapter 30 turns the committed secret into a timed incident drill; Chapter 21A covers the same questions for GitHub Actions.

## 21B.26 Interview questions

1. A developer says: "I committed an API key, deleted it in the next commit and pushed. We are fine." Walk through exactly where the key still exists, and what you do first.
2. Explain why `git clone` of an untrusted repository is generally safe and why unpacking a tarball of the same repository is not. Name the files involved.
3. A commit on `main` shows your tech lead's avatar and she says she did not write it. What does GitHub's display prove, what evidence do you look at, and which controls would have prevented or flagged it?
4. What changes for a team when "Require signed commits" is enabled and the repository uses "Rebase and merge"? Explain the mechanism.
5. Your signing key was stolen and you revoked it. Which commits still show "Verified", and how do you find the attacker's?
6. Rank the credentials an automation could use to push to a repository by blast radius, and justify the order.
7. You rewrote history to remove a customer data file and force-pushed. List every place the file may still exist and who controls each.
8. A day after a history rewrite the secret is back on `main` and nobody force-pushed. Reconstruct what happened from the commit graph, and describe the fix for the server and for the clone.
9. When is a history rewrite the wrong response to a leaked secret? What does it cost?
10. Push protection is enabled for all your users. Name three kinds of leak it will not stop.

## 21B.27 Sources

**Primary sources**

- Git 2.55 manual pages: `git help git` (SECURITY), `git help config` (`safe.*`, `protocol.*`), `git help filter-branch` (WARNING), `git help hook`, `git help githooks`.
- [Git security advisories](https://github.com/git/git/security/advisories); [safe configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/safe.adoc); [protocol configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/protocol.adoc); [githooks](https://github.com/git/git/blob/v2.56.0/Documentation/githooks.adoc).
- GitHub Docs, fetched 2 October 2026: [removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository); [remediating a leaked secret](https://docs.github.com/en/code-security/tutorials/remediate-leaked-secrets/remediating-a-leaked-secret); [about push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection); [Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference). Through the Phase 0 report: [about secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning); [supported patterns](https://docs.github.com/en/code-security/secret-scanning/introduction/supported-secret-scanning-patterns); [commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification); [credential types](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/github-credential-types); [security features](https://docs.github.com/en/code-security/getting-started/github-security-features).
- [git-filter-repo manual](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt) (fetched 2 October 2026).

**Secondary sources**

- [GitGuardian, State of Secrets Sprawl 2026](https://www.gitguardian.com/state-of-secrets-sprawl-report-2026); [GitGuardian on leaked GitHub App private keys](https://blog.gitguardian.com/github-app-private-keys-leaked/).
- [Russ Cox, timeline of the xz open source attack](https://research.swtch.com/xz-timeline).
- The research, incident reports and articles linked where they are used, in sections 21B.4, 21B.8, 21B.10, 21B.14 and 21B.15.

**Videos** (from the Phase 0 report, with its caveats)

- ["git-filter-repo for rewriting Git history"](https://www.youtube.com/watch?v=KXPmiKfNlZE), Elijah Newren, Git Merge 2024, 22 min. A contributor talk on what the tool does and how it compares with filter-branch and BFG; not a step-by-step incident tutorial.
- [Git Merge 2022 workshop on SSH commit signing](https://www.youtube.com/watch?v=uhy_ojFqLg0), listed by the roadmap for Module 24.
- ["Day-2: DevSecOps for Git and GitHub"](https://www.youtube.com/watch?v=Gd-AiV--LHs), Abhishek Veeramalla, 46 min, 22 January 2026. Shows a branch ruleset, CODEOWNERS, gitleaks through pre-commit and in Actions, and Dependabot together; no signing, OIDC or action pinning.

**Further reading**

- [Chapter 13: Recovery](ch13-recovery.md) for reflogs, pruning and the GitHub-side recovery instruments; [Chapter 14B](ch14b-config-tags-signing.md) for local signing; [Chapter 16](ch16-authentication.md) for credential mechanics; [Chapter 12](ch12-remote-operations.md) for force pushes.
