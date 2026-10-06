# Module 24 labs, GitHub part: Verification states

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Read [Chapter 21B](../textbook/ch21b-repository-security-incident-response.md), sections 21B.5 to 21B.7, first, after [Chapter 14B](../textbook/ch14b-config-tags-signing.md), sections 14B.15 to 14B.18. The local labs of this module, 24.1 and 24.2, are in [m24-signing-local.md](m24-signing-local.md). The transcripts under "Expected output" are real output of `labs/ch21b/lab-24-3-verification-states.sh`. Nothing in this file was run against GitHub: what GitHub displays is described from its documentation, with the link, and you record what you actually see.

## How this lab works

Lab 24.3 has a local Part A in the lab shell and a Part B on GitHub.

```bash
bash labs/ch21b/setup-24-3-verification-states.sh    # build the starting state (run again to start over)
labs/shell m24-3                                     # open the isolated lab shell in that sandbox
labs/run ch21b/lab-24-3-verification-states          # optional: replay Part A and print its transcript
```

> **Run Part B in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub.

Part B uses the public practice repository `YOUR-ORG/practice-repo` and your clone `~/git-mastery/practice-repo` from the [Module 19 labs](m19-github-platform.md). It uses **your own** signing key, which you created and protect yourself (Chapter 16); the course never reads it. The forged commit in Part B claims an address at `example.com`, which belongs to nobody. Do not put a real person's name or address on a commit you push.

In transcripts, a line `[exit status: N]` is added by the replay tool; by hand, run `echo $?`. Answers to the Questions are in [solutions/m24-github-lab-answers.md](../solutions/m24-github-lab-answers.md).

## Lab 24.3: What GitHub shows for unsigned, signed and forged commits

### Objective

Make three commits whose identity claims differ, predict what Git records and what GitHub displays for each, then push them and compare. Switch vigilant mode on and see which badges change. Learn to read a commit's verification through the REST API.

### Prerequisites

- Lab 24.1 and Lab 24.2 (local signing; the forged commit seen locally).
- For Part B: a signing key of your own configured in your normal Git configuration (`gpg.format`, `user.signingKey`), and a `user.email` that is verified on your GitHub account.

### Setup

```bash
bash labs/ch21b/setup-24-3-verification-states.sh
labs/shell m24-3
cd signing-states
```

### Commands

**Part A, in the lab shell.** Three unsigned commits: yours; one whose author is a claim; one whose author and committer are both claims.

```bash
printf 'states\n' > notes.md && git add notes.md
git commit -q -m 'A: my commit, unsigned'
printf 'author claim\n' >> notes.md
git commit -q -a --author='Asha Rao <asha@example.com>' -m 'B: author is a claim; committer is me'
printf 'both claims\n' >> notes.md
GIT_COMMITTER_NAME='Asha Rao' GIT_COMMITTER_EMAIL=asha@example.com git commit -q -a --author='Asha Rao <asha@example.com>' -m 'C: author and committer are claims'
```

```bash
git log --reverse --format='%h %s%n        author=%ae committer=%ce signature=%G?'
git cat-file -p HEAD | sed -n "1,4p"
git verify-commit HEAD
```

**Part B, in your normal shell.** Register your public key as a *signing* key if you have not done so. It is a separate registration from the authentication key, even for the same file.

```bash
gh ssh-key list
gh ssh-key add ~/.ssh/YOUR-SIGNING-KEY.pub --type signing --title "signing key"
```

If `gh` refuses for lack of permission, add the key in the browser: the documentation places SSH signing keys under your account settings, "SSH and GPG keys" ([about commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)).

Make three empty commits on a branch and push them:

```bash
cd ~/git-mastery/practice-repo
git switch -c lab-24-3
git config get user.email
git -c commit.gpgSign=false commit --allow-empty -m "24.3 A: unsigned"
git commit -S --allow-empty -m "24.3 B: signed"
git -c commit.gpgSign=false commit --allow-empty --author='Nobody Example <nobody@example.com>' -m "24.3 C: author is a claim"
git log --format='%h %G? %an | %cn | %s' -3
git push -u origin lab-24-3
```

Read each commit's verification from the REST API, then open the branch in the browser and go to its commit list:

```bash
for c in $(git rev-list --reverse main..lab-24-3); do
  gh api "repos/YOUR-ORG/practice-repo/commits/$c" --jq '[.sha[0:7], .commit.message, .commit.verification.verified, .commit.verification.reason] | @tsv'
done
gh browse --repo YOUR-ORG/practice-repo --branch lab-24-3
```

Now enable vigilant mode: in your account settings under "SSH and GPG keys", the option "Flag unsigned commits as unverified" ([documentation](https://docs.github.com/en/authentication/managing-commit-signature-verification/displaying-verification-statuses-for-all-of-your-commits)). Reload the commit list and note every badge again.

### Expected output

Part A. Git stores whatever it was told, and none of the three commits has a signature (`N`):

<!-- snippet: ch21b/lab-24-3-verification-states/01-three-commits -->
```text
$ cd signing-states
$ printf 'states\n' > notes.md && git add notes.md
$ git commit -q -m 'A: my commit, unsigned'
$ printf 'author claim\n' >> notes.md
$ git commit -q -a --author='Asha Rao <asha@example.com>' -m 'B: author is a claim; committer is me'
$ printf 'both claims\n' >> notes.md
$ GIT_COMMITTER_NAME='Asha Rao' GIT_COMMITTER_EMAIL=asha@example.com git commit -q -a --author='Asha Rao <asha@example.com>' -m 'C: author and committer are claims'
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-24-3-verification-states/02-what-git-recorded -->
```text
$ git log --reverse --format='%h %s%n        author=%ae committer=%ce signature=%G?'
fd9016a A: my commit, unsigned
        author=you@example.com committer=you@example.com signature=N
c00065f B: author is a claim; committer is me
        author=asha@example.com committer=you@example.com signature=N
0b4e72d C: author and committer are claims
        author=asha@example.com committer=asha@example.com signature=N
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-24-3-verification-states/03-no-signature-header -->
```text
$ git cat-file -p HEAD | sed -n "1,4p"
tree da929dc20eae1088f97ec420147a5fd55437f873
parent c00065f051ef6c4da4bd1582157d5d8bcf3aefa9
author Asha Rao <asha@example.com> 1788755940 +0530
committer Asha Rao <asha@example.com> 1788755940 +0530
$ git verify-commit HEAD
[exit status: 1]
```
<!-- /snippet -->

`git verify-commit` prints nothing and exits with status 1: there is no `gpgsig` header to check.

**Part B, described from documentation; not run by the author.** Fill in the last two columns yourself.

| Commit | `verification` in the REST API (documented values) | Badge without vigilant mode (documented) | Badge with vigilant mode (documented) | What you saw |
|---|---|---|---|---|
| A: unsigned, yours | `verified: false`, `reason: unsigned` | none | Unverified | |
| B: signed, yours | `verified: true`, `reason: valid`, when the key is registered as a signing key on your account | Verified | Verified | |
| C: unsigned, author `nobody@example.com`, committer you | `verified: false`, `reason: unsigned` | none | Unverified, because the committer has vigilant mode enabled | |

The `reason` values are from the REST reference, which lists among others `unsigned` ("The object does not include a signature"), `unknown_key` ("The key that made the signature has not been registered with any user's account") and `valid` ([REST: commits](https://docs.github.com/en/rest/commits/commits)). The badge columns are from the two documentation pages linked above. For commit C the author is displayed as plain text without a linked account, because GitHub attributes by matching the email address and no account has that address ([why are my commits linked to the wrong user](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/troubleshooting-commits/why-are-my-commits-linked-to-the-wrong-user)). The fourth documented state, "Partially verified", needs a second account: it is shown for a signed commit whose author is not the committer and has enabled vigilant mode.

### What happened internally

A commit object has an `author` and a `committer` line, filled from the command line, the environment or configuration, and optionally a `gpgsig` header. Git checked none of the names. On GitHub, three independent things then happened to each pushed commit: the email addresses were matched against accounts for display; a signature, if present, was checked against the keys registered on accounts, and the result was stored as a persistent verification record; and your vigilant-mode setting decided whether *absence* of a signature on a commit that names you is displayed as "Unverified". The push itself was authenticated as you for all three commits, whatever the commits claimed.

### Checkpoint

Before you push in Part B, write your prediction for all three commits in both modes. After pushing, explain any difference with the `reason` value.

### Failure scenario

Part A, in the lab shell: switch signing on before a key is configured.

```bash
git config set gpg.format ssh
git config set commit.gpgSign true
printf 'signed?\n' >> notes.md
git commit -a -m 'D: first signed commit'
git log --oneline -1
git status -s
```

<!-- snippet: ch21b/lab-24-3-verification-states/04-failure -->
```text
# Failure scenario: signing is switched on before a key is configured.
$ git config set gpg.format ssh
$ git config set commit.gpgSign true
$ printf 'signed?\n' >> notes.md
$ git commit -a -m 'D: first signed commit' 2>&1
fatal: either user.signingkey or gpg.ssh.defaultKeyCommand needs to be configured
[exit status: 128]
$ git log --oneline -1
0b4e72d C: author and committer are claims
$ git status -s
 M notes.md
```
<!-- /snippet -->

The commit is refused, nothing is lost, and the change is still in the working tree. The Part B version of the same mistake does not fail loudly: a commit signed with a key that is registered on GitHub only for authentication is pushed without complaint and displayed as "Unverified"; the documented `reason` to expect is `unknown_key`. Record what you see if you try it.

### Recovery

```bash
git config get --show-origin commit.gpgSign
git config get user.signingKey
git config unset commit.gpgSign
git commit -q -a -m 'D: unsigned until the signing key is configured'
git log --format='%h %G? %s' -1
```

<!-- snippet: ch21b/lab-24-3-verification-states/05-recovery -->
```text
$ git config get --show-origin commit.gpgSign
file:.git/config	true
$ git config get user.signingKey
[exit status: 1]
# Nothing was committed and the change is still in the working tree. Until the key exists:
$ git config unset commit.gpgSign
$ git commit -q -a -m 'D: unsigned until the signing key is configured'
$ git log --format='%h %G? %s' -1
43219dc N D: unsigned until the signing key is configured
```
<!-- /snippet -->

The lasting fix is to configure the key (Lab 24.1), not to switch signing off. For Part B: register the key with `--type signing`. A commit that GitHub already recorded as verified stays verified, and GitHub does not go back to re-verify earlier commits when the state of a key changes; record whether your earlier "Unverified" commit changes after you register the key.

### Verification

Part A: `git log --format='%h %G?'` prints `N` four times. Part B: the `gh api` loop prints three lines whose third and fourth fields match the table, and the commit list shows the badges you predicted in both modes. Then clean up, and decide deliberately whether vigilant mode stays on: leave it on only if every machine you commit from signs.

```bash
git switch main
git push origin --delete lab-24-3
git branch -D lab-24-3
```

### Questions

1. In Part A, commit C is indistinguishable from a commit Asha made herself. Which piece of evidence, on GitHub, would still show who delivered it?
2. Commit B shows "Verified". State precisely what that proves and two things it does not prove.
3. Why does vigilant mode change the display of commit C although its *author* is not you?
4. Your team enables "Require signed commits" on `main` and merges with "Rebase and merge". What happens, and why?
5. You revoke a signing key that was stolen last week. What happens to the badge on commits the thief signed, and how do you find them?
6. A pull request merged with "Squash and merge" shows "Verified". Whose key signed it?
