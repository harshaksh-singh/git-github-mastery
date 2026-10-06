# V139: Signatures on GitHub: the verification states and what "Verified" does not prove

- **Part.** 5: GitHub
- **Module.** 24
- **Planned minutes.** 18
- **Prerequisites.** V128, V138
- **Textbook sections.** [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md), sections 21B.6 and 21B.7
- **Demo scripts.** `labs/ch21b/lab-24-3-verification-states.sh`, then a screen walkthrough of Lab 24.3 in [`lab-manual/m24-signing-github.md`](../../lab-manual/m24-signing-github.md)

## HOOK

**[ON SCREEN]** A commit list. Some commits carry a green "Verified" label. Most carry nothing.

A security reviewer asks your team: "Your commits are verified, so you know who wrote the code that runs in production, correct?"

There are two things wrong with that sentence, and a third that is wrong with the commit list. The badge is a statement about a key and an account, not about who typed the change. The commits with no badge are not "fine"; they are unsigned, and by default GitHub is silent about them. And one of the most common ways to merge a pull request produces commits that are not signed by their author at all.

## INTRODUCTION

In the last two videos everything was Git: a signature in an object, verified on your machine against a file you control. This video crosses to the platform.

**[ON SCREEN]** Lower third: GitHub.

The badge next to a commit is GitHub's judgment about a signature and an account. GitHub runs its own verification, against keys registered on accounts, and shows the result. You will learn the states it can show, what vigilant mode changes, what persistent verification records are, which commits GitHub signs itself, why "rebase and merge" yields unsigned commits, and what the "require signed commits" rule enforces. And then the limits, with the case the textbook uses for them.

The local replay builds three commits and shows what Git recorded. What GitHub displays for them is described from the documentation; you observe it yourself in Lab 24.3.

## LEARNING OBJECTIVES

After this video you can:

- name the verification states GitHub displays and what produces each;
- say what vigilant mode and persistent verification records change, as the section states them;
- say which commits GitHub signs itself;
- explain why "rebase and merge" produces commits that are not signed by the author;
- state three things a "Verified" badge does not establish.

## CONCEPT

**In one sentence.** GitHub checks each commit's signature against keys registered on accounts and shows the result as a badge; without vigilant mode an unsigned commit gets no badge at all.

**Precisely.** GitHub verifies GPG, SSH and S/MIME signatures. A cryptographically verifiable signature is marked "Verified" or "Partially verified". A signature that cannot be verified is "Unverified". An unsigned commit shows no status by default.

For SSH there is a detail that catches people on the first day. The public key must be added to the account as a signing key. That is a separate registration from an authentication key, even when it is the same key file.

```bash
gh ssh-key add ~/.ssh/id_ed25519_signing.pub --type signing --title "laptop signing key"
```

The command is shown as the textbook shows it, without output. It changes your account, so it is yours to run, in your normal shell.

**Vigilant mode** changes what silence means. The setting is called "Flag unsigned commits as unverified" and lives in your account's SSH and GPG keys settings.

**[ON SCREEN]** The four-row table of section 21B.6.

Without vigilant mode: "Verified" means signed, and the signature verifies. "Partially verified" is not shown. "Unverified" means signed, but the signature could not be verified. No badge means not signed.

With vigilant mode enabled by the person the commit names: "Verified" means signed and verified, and the committer is the only author who has enabled vigilant mode. "Partially verified" means signed and verified, but the commit has an author who is not the committer and who has enabled vigilant mode. "Unverified" now also covers any unsigned commit attributed to that person. And "no badge" does not occur for that person's commits.

The textbook calls vigilant mode the cheap defense against the forgery of the last video. Once Asha enables it, the commit that claims her name without her key is displayed as "Unverified", instead of looking like all her other unsigned commits. One condition: enable it only after you sign on every machine you commit from, or your own work is flagged.

**Persistent verification records.** Since 10 December 2024, once GitHub has verified a signature, the commit stays verified within its repository network. A record is stored with the commit. It cannot be edited, and it persists when the key is later rotated, revoked or expired, or when the contributor leaves the organization. GitHub does not re-verify old commits when a key's state changes. The time of verification is exposed as `verified_at` in the REST API.

Two consequences, one good and one to remember in an incident. Rotating a key no longer turns years of history "Unverified". But revoking a stolen key does not un-verify what an attacker signed with it. You find those commits by date and by the audit log, not by the badge.

**Commits that GitHub signs.** Commits you make in the web interface are signed by GitHub with its own key. That includes the merge commit of "Create a merge commit" and the single commit of "Squash and merge". The textbook is exact about what that badge means: GitHub created the commit on behalf of a signed-in user. It does not mean that the user's key was involved. Dependabot signs its commits by default, and the Copilot cloud agent has signed its commits since 3 April 2026.

**Why "Rebase and merge" yields unsigned commits.** You can derive this from what you already know. A rebase creates new commits with new parents and a new committer. A signature covers the commit's content including its parents, so the original signatures cannot be carried over. And GitHub does not have your private key to make new ones. The documentation states the result: the commits are created without signature verification.

**The require-signed-commits rule.** Display is not enforcement. The ruleset rule "Require signed commits" means contributors and bots can push only commits that are signed and verified. Under rulesets GitHub checks only the commits that are not reachable from other branches. Put that together with the previous paragraph: the rule makes "Rebase and merge" unusable on the protected branch, while squash and merge commits pass, because GitHub signs them.

**[ON SCREEN]** Callout: Unverified.

One caveat that the textbook marks as unverified, and so do I. Sigstore's keyless `gitsign` signs with short-lived certificates tied to an OIDC identity, and its README says GitHub does not display those commits as verified. The Phase 0 report could not re-verify this, or GitHub's support for SSH certificates in verification, against a 2026 primary source.

## MENTAL MODEL

Keep the wax seal from the last video: the seal proves which seal pressed the wax. GitHub adds a registry to that picture. The registry says which account has registered which seal. The badge is the registry's answer to one question: is the seal on this object one that the named account registered?

Where the model breaks: a registry suggests that the answer is looked up fresh each time. It is not. With persistent verification records the answer is written down once, at the time of verification, and kept. And for commits made in the web interface the seal is GitHub's own, not the user's.

Section 21B.7 states the limit in one sentence. A verified signature proves one thing: the holder of a particular private key created this exact commit object. It does not prove that the change is correct, reviewed or benign. It does not prove that the key holder is who you think. It does not prove that the person had not been turned or impersonated socially.

The case to remember is the xz-utils backdoor of 2024. It was introduced by a contributor who had earned commit rights over more than two years of useful work, and the build script that activated it was present only in the release tarball, not in the Git repository. Every commit could have carried a perfect signature. Signing would have changed nothing, for two reasons that generalize.

First, the signer was authorized. Signatures authenticate; they do not judge. Review, and limits on what one maintainer can ship alone, are the controls for a trusted insider.

Second, the artifact was not the repository. What users ran was a tarball. A signature on commits says nothing about a release archive, a wheel or a container image built somewhere else. That gap is closed by build provenance and artifact attestations, which belong to the Actions chapters.

The textbook's summary: signing removes cheap impersonation and anchors the audit trail. It is one layer.

## DIAGRAM

**[DIAGRAM]** Three columns, one per commit. Fill the top half first: the Git facts, which you can compute in a clone. Then the bottom half: what the documentation says GitHub displays. Ask the viewer to fill the bottom row for vigilant mode before you write it.

```text
                     commit 1                  commit 2                    commit 3
                     your own, unsigned        your own, signed            author is a colleague,
                                                                           unsigned, pushed by you
  Git says   ------------------------------------------------------------------------------------
  author             you                       you                         the colleague
  gpgsig header      none                      present                     none
  %G?                N                         depends on YOUR             N
                                               allowed-signers file

  GitHub is documented to display  --------------------------------------------------------------
  default            no badge                  Verified, if the key is     no badge
                                               registered on your account
                                               as a signing key
  the named person   Unverified                Verified                    Unverified
  has enabled        (you enabled it)                                      (if the colleague
  vigilant mode                                                            enabled it)
```

**[DIAGRAM]** Look at commit 1 and commit 3 in the default row. They look the same: no badge. That is the problem vigilant mode addresses, and it is switched on by the person who is named, not by the repository.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21b/lab-24-3-verification-states`. This is Git, in the sandbox. The IDs equal the book's.

**Step 1: three commits with three identity claims.**

```bash
git commit -q -m 'A: my commit, unsigned'
git commit -q -a --author='Asha Rao <asha@example.com>' -m 'B: author is a claim; committer is me'
GIT_COMMITTER_NAME='Asha Rao' GIT_COMMITTER_EMAIL=asha@example.com git commit -q -a --author='Asha Rao <asha@example.com>' -m 'C: author and committer are claims'
```

`git commit` adds an object and moves the branch. Commit A is the lab user's. In B, the author is a claim and the committer is the lab user. In C, both fields are claims.

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

**Step 2: what Git recorded.**

```bash
git log --reverse --format='%h %s%n        author=%ae committer=%ce signature=%G?'
```

**[PAUSE]** Predict the three lines: author address, committer address, and signature letter for A, B and C.

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

`fd9016a`, `c00065f` and `0b4e72d`. Three different combinations of addresses, and the same letter three times: `N`. Git recorded exactly what it was told.

**Step 3: there is nothing to verify.**

```bash
git cat-file -p HEAD | sed -n "1,4p"
git verify-commit HEAD
```

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

Four header lines, no `gpgsig`. `git verify-commit` prints nothing and exits with 1. Now connect this to the platform. By email matching, GitHub would attribute commit C to whichever account owns Asha's address. With no signature, the documented default is no badge. So C would look like any other unsigned commit of hers.

**Step 4: the lab's failure scenario.** Signing is switched on before a key is configured.

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

`git config set` is 🟡 CAUTION: it changes a configuration file. The commit fails with the message you met in V137, and the two lines after it are the important ones: the last commit is still `0b4e72d`, and the change is still in the working tree. Nothing was lost. The lab's recovery section shows the way out; do it yourself.

**[ON SCREEN]** Lower third: GitHub. Screen walkthrough.

Part B of Lab 24.3, on your own practice repository, in your normal shell. The interface changes; the lab text and the linked documentation are the reference. No GitHub output was captured by the authors. Never show a real key or token on screen.

You need a signing key in your normal Git configuration and an address that is verified on your account. You register the public key as a signing key. Then the lab has you make three empty commits on a branch: one unsigned, one signed, and one unsigned whose author is a made-up person at `example.com`. You look at them locally first:

```bash
git log --format='%h %G? %an | %cn | %s' -3
git push -u origin lab-24-3
```

`git push` is 🟡 CAUTION. Before you open the browser, write down what you expect beside each of the three commits.

Then open the commit list of the branch. For each commit, find the place where a verification badge would be, and note whether there is one and what it says. Open the badge of the signed commit and read what GitHub tells you about the key. The lab also reads the same information through the REST API, as two fields: whether the commit is verified, and a reason.

Then switch on vigilant mode in your account settings, as the documentation describes, reload the commit list, and note every badge again. The comparison between your two lists is the result of the lab.

## COMMON MISTAKES

1. **Reading "no badge" as "nothing wrong".** Root cause: without vigilant mode an unsigned commit shows no status, so a forged unsigned commit looks like every other unsigned commit.
2. **Registering a key for authentication and expecting "Verified".** Root cause: a signing key is a separate registration, even for the same key file.
3. **Requiring signed commits and keeping "Rebase and merge".** Root cause: a rebase creates new commits, the old signatures cannot be carried over, and GitHub has no private key of yours to sign the new ones.
4. **Revoking a stolen key and trusting the badges afterwards.** Root cause: verification records persist, and GitHub does not re-verify old commits when a key's state changes.
5. **Taking "Verified" on a squash commit as the author's signature.** Root cause: commits made in the web interface are signed by GitHub with its own key, on behalf of a signed-in user.

## PRODUCTION EXAMPLE

An ML platform team turns on the "require signed commits" rule for `main` after an audit. The repository allows squash merges and rebase merges. On Monday, squash merges work as before. A developer who prefers "rebase and merge" finds the method unusable on `main`. Another, working from a fresh laptop without a signing key, cannot get a pull request merged with the commits as they are.

Nothing is broken. The rule checks the commits that are not reachable from other branches, squash commits pass because GitHub signs them, and rebase-merge commits are documented to be created without signature verification. The team's decision is then explicit: squash only on that branch, signing set up on every machine before the rule goes live, and one sentence in the contributing guide that says what the badge on a squash commit means and what it does not.

## PRACTICE EXERCISE

Do Lab 24.3, "What GitHub shows for unsigned, signed and forged commits", in [`lab-manual/m24-signing-github.md`](../../lab-manual/m24-signing-github.md). Part A runs in `labs/shell`; Part B in your normal shell on your practice repository.

Predict first, on paper: for each of the three commits you push, what Git records, what GitHub displays by default, and what GitHub displays after you enable vigilant mode. Then compare.

The challenge is Exercise 24.6, "Verified, and she was on a plane", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q315: "A commit on `main` shows your tech lead's avatar and she says she did not write it. What does GitHub's display prove, what evidence do you look at, and which controls would have prevented or flagged it?"

A strong answer takes the three parts in order and labels the layer each time. For the display: say what mechanism produces an avatar and what that mechanism checks. For the evidence: use the four questions from V138, and say where each answer is recorded. For the controls: separate what flags from what prevents, and say who has to switch each one on. The follow-up adds a "Verified" badge to the commit; answer with the one thing a verified signature proves and the things from section 21B.7 that it still does not.

## RECAP

You should now be able to say:

- The badge is GitHub's judgment about a signature and a key registered on an account; an unsigned commit shows no badge unless the named person has enabled vigilant mode.
- A verification record persists after key rotation and after revocation; a stolen key's commits are found by date and audit log.
- GitHub signs web-interface commits, including merge commits and squash commits, with its own key.
- "Rebase and merge" creates commits without signature verification, so it cannot be used under a require-signed-commits rule.
- "Verified" does not say the change is correct or reviewed, that the key holder is who you think, or that the released artifact came from this repository.

## HOMEWORK

Read sections 21B.6 and 21B.7 of [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md). Do Exercise 24.3, "What would GitHub display?", and Exercise 24.4, "Four questions from a team that has just required signatures", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).
