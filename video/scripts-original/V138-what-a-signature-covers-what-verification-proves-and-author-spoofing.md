# V138: What a signature covers, what verification proves, and author spoofing

- **Part.** 5: GitHub
- **Modules.** 24 and 30
- **Planned minutes.** 24
- **Prerequisites.** V020, V137
- **Textbook sections.** [Chapter 14B](../../textbook/ch14b-config-tags-signing.md), sections 14B.17 to 14B.21; [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md), section 21B.5
- **Demo scripts.** `labs/ch21b/identity-assertion.sh`, `labs/ch14b/spoof-author.sh`, `labs/ch14b/signature-scope.sh` (volatile), `labs/ch14b/spoof-signed.sh` (volatile)

## HOOK

**[ON SCREEN]** One line from section 21B.5: "the last three commits are from the platform lead".

A reviewer approves a pull request for that reason. The three commits carry her name and her address. A compromised contributor account authored them under her email. The reviewer looked at a displayed identity and took it for evidence.

In the next twenty-four minutes you will forge an author yourself, in the sandbox, push the forgery to a server that accepts it without comment, and then find out exactly which check catches an unsigned forgery, which check catches a signed one, and which popular check catches neither.

This is a defensive video. You need to see how little it takes, so that you stop trusting the author line and know what to trust instead.

## INTRODUCTION

In the last video you signed a commit and verified it. You learned that a good signature is a fact about a key. This video draws the boundary of that fact from both sides.

First, identity without signatures: the author and committer lines are assertions, and neither Git nor a push checks them. Second, what a signature covers: every byte in the object, and nothing outside it. Not the refs, not later rewrites, not the push. Third, the forgery again in a repository where everyone signs, and the difference between verifying a signature and enforcing a policy.

The scripts `signature-scope` and `spoof-signed` generate fresh keys, so they are volatile: your IDs and key fingerprints differ from the ones on screen. The other two are deterministic, and their IDs equal the book's.

## LEARNING OBJECTIVES

After this video you can:

- show that anyone can commit under any author name and address, and that a server accepts it;
- list what a signature does not cover: refs, later rewrites, the push;
- explain what happens to signatures in a rebase;
- tell an unsigned forgery from a signed forgery and say which check catches each;
- enforce a signature policy at merge time with `--verify-signatures`, and say what that option does not check.

## CONCEPT

**[ON SCREEN]** Lower third: Git.

**Identity. In one sentence:** the author and committer of a commit are two lines of text that the person running Git supplies, and neither Git nor a push checks them against anything.

**Precisely.** `git commit` takes the author from the environment variables `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL`, or from `--author`, or from `user.name` and `user.email`. It takes the committer from the `GIT_COMMITTER` variables or the same configuration. Those strings become the `author` and `committer` headers of the commit object and are covered by the commit ID.

The transport authenticates the pusher. It does not compare the pusher with the names inside the commits being pushed, and the textbook adds that it could not: pushing other people's commits is what a merge, a rebase and a cherry-pick do every day. There is no bug here to fix. The design requires it.

Not every use of another person's name is a forgery. `--author` changes one field and leaves you as committer, which is how a patch from someone else is honestly recorded. The forgery is the claim of both fields, and to Git the two cases are the same operation.

**What a signature covers.** Everything in the object. Tree, parents, author, committer, dates and message are all signed bytes. Through the tree and parent IDs, a signature vouches for every file and every ancestor.

**What it does not cover.** Nothing outside the object. Three things matter most.

Refs are not signed. Which branch or tag name points at the object is not part of the object. A signed commit stays validly signed on any branch, in any repository. Anyone who can push can serve your signed tag object under another name. The object still says its original tag name inside, which is why a careful verifier compares that name with the one it asked for.

Rewrites are not covered. Amend, rebase and cherry-pick write new commits. The new commits are signed only if the person running the command signs, and then with their key, not the original author's.

The push is not covered. Who pushed is known only to the server's logs.

**Key lifetime and revocation.** An allowed-signers entry can carry `valid-after` and `valid-before`. Git passes the committer date of the object as the time to check against. And the committer date is whatever the committer says. So validity windows let you rotate keys without invalidating old signatures, which is what the manual offers them for. They do not protect against a stolen key, because the thief chooses the date. For a stolen key there is the revocation file, `gpg.ssh.revocationFile`. A revoked key fails for every date, including all the honest signatures made before the theft. That is the price.

**Verification is not policy.** `git verify-commit` verifies a signature against the list of trusted keys. It does not compare the signer with the author line. That comparison is a policy, and you have to run it. And `git merge --verify-signatures` is not that policy either: the manual says it verifies "the tip commit of the side branch". One commit.

**When not to rely on it.** From section 14B.20: a signature is evidence about a key. A passphrase-less key on a laptop, a key copied into CI, or a shared team key reduce "signed by Asha" to "signed by something that had Asha's file".

## MENTAL MODEL

**Analogy,** from section 21B.5. The author line is the return address on an envelope. The postal service delivers the letter whatever you write there. A signature is the wax seal: it proves which seal pressed the wax, and it still says nothing about what the letter asks you to do.

Where it breaks: a wax seal sits on the outside and you can look at it without opening anything. A Git signature is inside the object and covers the return address too. So a signed commit does protect its author line against later change by a third party. What it cannot do is make the author line true at the moment of signing. The signer wrote both.

The textbook separates four questions that hide behind "who made this commit".

**[ON SCREEN]** The four-row table of section 21B.5.

Who is displayed? Answered by email matching, on GitHub. Forgeable by someone with push access: yes.

Who pushed it? Answered by the authenticated credential, recorded in the Activity view and the audit log, on GitHub. Forgeable: no, but a stolen credential pushes as its owner.

Who signed it? Answered by a signature verified against a key; Git locally, GitHub for display. Forgeable: only with the private key.

What is enforced? Answered by a rule that rejects unsigned or unverified commits, on GitHub. Forgeable: no.

When someone asks you "who made this commit", answer with those four, in that order, and say which layer gives each answer.

## DIAGRAM

**[DIAGRAM]** The picture of section 14B.17. Draw the left box first and fill it line by line from a commit object. Then draw the arrow down to the signature. Only then draw the right box, and ask the viewer to name its lines before you write them.

```text
   signed bytes (the commit without gpgsig)             not signed
   +--------------------------------------------+      +---------------------------------+
   | tree      -> every file, by hash           |      | refs: which branch or tag name  |
   | parent(s) -> all earlier history, by hash  |      | which repository, which fork    |
   | author    name <email> date                |      | who pushed it, and when         |
   | committer name <email> date                |      | reviews, CI results, approvals  |
   | message                                    |      | whether the author line is true |
   +--------------------------------------------+      +---------------------------------+
        |  ssh-keygen -Y sign -n git
        v
   gpgsig header (commit)  or  block after the message (tag)
```

**[DIAGRAM]** Read the last line of the right box twice. The author line is inside the signed bytes, and whether it is true is outside them. Both statements hold at once.

**[ON SCREEN]** The two-column table that follows the picture. A verified signature proves: the object has not changed since it was signed; someone with access to the private key signed it; the key is one that you, or your platform, have decided to trust for that principal. It does not prove: that the change is correct, reviewed or harmless; which person signed, if the key was shared, stolen or left unlocked; that the author and committer lines name the signer; when it was signed, because the dates are the signer's claim; that it belongs on this branch or in this release.

## LIVE TERMINAL DEMO

**[TERMINAL]** Four replays. Start with `labs/run ch21b/identity-assertion`, a billing service.

**Step 1: assert anything.**

```bash
GIT_AUTHOR_NAME='Asha Rao' GIT_AUTHOR_EMAIL=asha@example.com GIT_COMMITTER_NAME='Asha Rao' GIT_COMMITTER_EMAIL=asha@example.com git commit -q -am 'Set tax rate to zero'
```

`git commit` adds an object and moves the branch. **[PAUSE]** Four environment variables. Will Git ask for anything, warn about anything, or record anything that says the lab user made this commit?

<!-- snippet: ch21b/identity-assertion/01-assert-anything -->
```text
$ printf 'RATE = 0.0\n' > tax.py
$ GIT_AUTHOR_NAME='Asha Rao' GIT_AUTHOR_EMAIL=asha@example.com GIT_COMMITTER_NAME='Asha Rao' GIT_COMMITTER_EMAIL=asha@example.com git commit -q -am 'Set tax rate to zero'
$ git log --format='%h author=%an <%ae>  committer=%cn <%ce>  signature=%G?'
42f5693 author=Asha Rao <asha@example.com>  committer=Asha Rao <asha@example.com>  signature=N
be06446 author=Lab User <you@example.com>  committer=Lab User <you@example.com>  signature=N
```
<!-- /snippet -->

Commit `42f5693`: author Asha, committer Asha, signature `N`. Nothing else distinguishes this commit from one Asha made.

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

The object is unremarkable. Tree, parent, two lines of text, a message.

**Step 2: the same on a shared repository.** Replay `labs/run ch14b/spoof-author`, an inference gateway with a server.

<!-- snippet: ch14b/spoof-author/01-real -->
```text
$ git log -2 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
39f0449  author=Asha Rao <asha@example.com>  committer=Asha Rao <asha@example.com>  Add health endpoint
d20ef7a  author=Lab User <you@example.com>  committer=Lab User <you@example.com>  Add rate limits
```
<!-- /snippet -->

Asha has one genuine commit, `39f0449`.

```bash
git commit -q -am "Raise the rate limit" --author="Asha Rao <asha@example.com>"
```

<!-- snippet: ch14b/spoof-author/02-author-flag -->
```text
$ printf 'requests_per_minute: 6000\n' > config/limits.yaml
$ git commit -q -am "Raise the rate limit" --author="Asha Rao <asha@example.com>"
$ git log -1 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
fee79f6  author=Asha Rao <asha@example.com>  committer=Lab User <you@example.com>  Raise the rate limit
```
<!-- /snippet -->

`--author` changed one field. You are still the committer. This is the honest form.

```bash
git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Raise the rate limit again"
```

<!-- snippet: ch14b/spoof-author/03-full-impersonation -->
```text
$ printf 'requests_per_minute: 60000\n' > config/limits.yaml
$ git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Raise the rate limit again"
$ git log -3 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
6e10a38  author=Asha Rao <asha@example.com>  committer=Asha Rao <asha@example.com>  Raise the rate limit again
fee79f6  author=Asha Rao <asha@example.com>  committer=Lab User <you@example.com>  Raise the rate limit
39f0449  author=Asha Rao <asha@example.com>  committer=Asha Rao <asha@example.com>  Add health endpoint
```
<!-- /snippet -->

Two configuration values on the command line, and commit `6e10a38` claims both fields.

**[PAUSE]** Now compare her real commit and the forgery header by header. Which field will tell them apart?

<!-- snippet: ch14b/spoof-author/04-objects-compared -->
```text
# Her real commit and your forgery, header by header (tree, parent and dates differ, as for any two commits):
$ git cat-file -p HEAD~2 | sed -n "/^author/,/^committer/p"
author Asha Rao <asha@example.com> 1788756000 +0530
committer Asha Rao <asha@example.com> 1788756000 +0530
$ git cat-file -p HEAD | sed -n "/^author/,/^committer/p"
author Asha Rao <asha@example.com> 1788756480 +0530
committer Asha Rao <asha@example.com> 1788756480 +0530
```
<!-- /snippet -->

None. Only the timestamps differ, as for any two commits.

```bash
git push
git shortlog -sne HEAD
```

`git push` is 🟡 CAUTION: it changes refs on the server, and published commits are not taken back. **[PAUSE]** The pusher is the lab user. The commits say Asha. Will the server refuse?

<!-- snippet: ch14b/spoof-author/05-server-accepts -->
```text
$ git push
To ../../server/inference-gateway.git
   39f0449..6e10a38  main -> main
$ git -C ../../server/inference-gateway.git log -3 --format='%h  %an <%ae>  %s'
6e10a38  Asha Rao <asha@example.com>  Raise the rate limit again
fee79f6  Asha Rao <asha@example.com>  Raise the rate limit
39f0449  Asha Rao <asha@example.com>  Add health endpoint
$ git shortlog -sne HEAD
     3	Asha Rao <asha@example.com>
     3	Lab User <you@example.com>
```
<!-- /snippet -->

Accepted. The server's own log shows three commits by Asha, and `git shortlog` credits her with three. Git has no rule that the pusher must be the committer.

<!-- snippet: ch14b/spoof-author/06-what-is-signed -->
```text
$ git log -3 --format='%h  %G?  %an  %s'
6e10a38  N  Asha Rao  Raise the rate limit again
fee79f6  N  Asha Rao  Raise the rate limit
39f0449  N  Asha Rao  Add health endpoint
```
<!-- /snippet -->

And all three are `N`. With no signatures anywhere, her real commit and the two others are equally unprovable.

**Step 3: the scope of a signature.** Replay `labs/run ch14b/signature-scope`. Volatile.

```bash
git cat-file commit HEAD | sed 's/short bursts/unlimited bursts/' | git hash-object -t commit -w --stdin > ../forged-id
git verify-commit "$(cat ../forged-id)"
```

`git hash-object -w` is 🟢: it adds one object. The command copies a signed commit, changes one word of the message, and keeps the signature. **[PAUSE]** What does verification say about the copy?

<!-- snippet: ch14b/signature-scope/01-tamper -->
```text
$ git log -1 --format='%h  %G?  %GS  %s'
b389204  G  you@example.com  Allow short bursts
# Write a second commit object: same headers, same signature, one word of the message changed.
$ git cat-file commit HEAD | sed 's/short bursts/unlimited bursts/' | git hash-object -t commit -w --stdin > ../forged-id
$ git cat-file -p "$(cat ../forged-id)" | tail -1
Allow unlimited bursts
$ git verify-commit "$(cat ../forged-id)"
Could not verify signature.
Signature verification failed: incorrect signature
[exit status: 1]
$ git log -1 --format='%G?  %s' "$(cat ../forged-id)"
B  Allow unlimited bursts
```
<!-- /snippet -->

"Incorrect signature", exit status 1, letter `B`. The copy has another ID and a bad signature. Everything in the object is covered.

```bash
git branch hotfix/anything HEAD
git update-ref refs/tags/v9.9.9 "$(git rev-parse v1.0.0)"
git verify-tag v9.9.9
```

`git branch` is 🟢 SAFE, `git update-ref` is 🟡 CAUTION: it writes a ref. **[PAUSE]** A second tag name pointing at the signed tag object of `v1.0.0`. Does `git verify-tag v9.9.9` succeed?

<!-- snippet: ch14b/signature-scope/02-refs-are-not-signed -->
```text
# The signature is inside the object. Which refs point at the object is not part of it.
$ git branch hotfix/anything HEAD
$ git log -1 --format='%G?  %D' hotfix/anything
G  HEAD -> main, tag: v1.0.0, hotfix/anything
$ git update-ref refs/tags/v9.9.9 "$(git rev-parse v1.0.0)"
$ git verify-tag v9.9.9
Good "git" signature for you@example.com with ED25519 key SHA256:IBY0fLOBtdFj0fbHvPhR5Di74E0PfNUAA+UYVYfgHgw
[exit status: 0]
$ git cat-file -p v9.9.9 | sed -n 1,3p
object b3892048e77c43a09f64eedfeccc408eeb532e3a
type commit
tag v1.0.0
$ git tag -d v9.9.9
Deleted tag 'v9.9.9' (was 849e258)
```
<!-- /snippet -->

It succeeds: a good signature, exit status 0. Then look inside the object: the third line still says `tag v1.0.0`. The name you asked for and the name in the signed bytes differ, and only you can notice that. The script deletes the extra tag again; `git tag -d` is 🟡 CAUTION, a deleted tag has no reflog.

```bash
git commit -q --amend --allow-empty --no-gpg-sign -m "Trigger the nightly evaluation run"
git rebase -q --no-gpg-sign --force-rebase HEAD~2
git rebase -q --gpg-sign --force-rebase HEAD~2
```

`git commit --amend` and `git rebase` are 🟡 CAUTION: they replace commits with new ones; the reflog has the old ones. **[PAUSE]** Two signed commits. After an amend without signing, then a rebase without signing, then a rebase with signing: write down the three pairs of letters you expect.

<!-- snippet: ch14b/signature-scope/03-rewrites-drop-signatures -->
```text
$ git commit -q --allow-empty -m "Trigger the nightly evaluation"
$ git log -2 --format='%h  %G?  %s'
65bce98  G  Trigger the nightly evaluation
b389204  G  Allow short bursts
$ git commit -q --amend --allow-empty --no-gpg-sign -m "Trigger the nightly evaluation run"
$ git log -2 --format='%h  %G?  %s'
2bc6aa4  N  Trigger the nightly evaluation run
b389204  G  Allow short bursts
$ git rebase -q --no-gpg-sign --force-rebase HEAD~2
$ git log -2 --format='%h  %G?  %s'
93c3833  N  Trigger the nightly evaluation run
14656b3  N  Allow short bursts
$ git rebase -q --gpg-sign --force-rebase HEAD~2
$ git log -2 --format='%h  %G?  %s'
7129bbb  G  Trigger the nightly evaluation run
acc22ee  G  Allow short bursts
```
<!-- /snippet -->

`G G`, then `N G`, then `N N`, then `G G` again, and every rewritten commit has a new ID. The last pair is signed by whoever ran the rebase. If that had been a colleague rebasing your branch, the signatures would now be theirs.

**[ON SCREEN]** Lower third: GitHub. The same logic runs on the platform. According to GitHub's documentation, merge and squash commits made in the web interface are signed by GitHub, and commits produced by "rebase and merge" are not signed at all. V139 returns to this.

**[ON SCREEN]** Lower third: Git.

<!-- snippet: ch14b/signature-scope/04-unknown-key -->
```text
$ git -c user.signingKey=~/keys/stranger.pub commit -q --allow-empty -m "Bump the model default"
$ git verify-commit HEAD
Good "git" signature with ED25519 key SHA256:dvbzrGKgxrd5uBx6kt8ux+C+H3qGogE5fD3p/a8CHZA
No principal matched.
[exit status: 1]
$ git log -1 --format='%h  %G?  signer=%GS  trust=%GT  %s'
81b4414  U  signer=  trust=undefined  Bump the model default
```
<!-- /snippet -->

A commit signed with a stranger's key. The mathematics is fine: "Good signature". The answer is still a failure: "No principal matched", exit status 1, letter `U`. Nobody you trust is attached to that key.

<!-- snippet: ch14b/signature-scope/05-key-lifetime -->
```text
# The lab clock says 7 September 2026. Give the key a validity window that ended on 31 August.
$ printf 'you@example.com namespaces="git",valid-before="20260831" %s\n' "$(cut -d' ' -f1,2 ~/keys/you_2026.pub)" > ~/allowed_signers
$ git verify-commit HEAD~1
Good "git" signature with ED25519 key SHA256:IBY0fLOBtdFj0fbHvPhR5Di74E0PfNUAA+UYVYfgHgw
$LAB/ch14b/signature-scope/home/allowed_signers:1: key has expired: verify time 2026-09-07T10:30:00 > valid-before 2026-08-31T00:00:00

No principal matched.
[exit status: 1]
# The verify time is the committer date, and the committer date is whatever the committer says.
$ GIT_COMMITTER_DATE='2026-08-30T12:00:00+05:30' git commit -q --allow-empty -m 'Rotate the staging credentials'
$ git verify-commit HEAD
Good "git" signature for you@example.com with ED25519 key SHA256:IBY0fLOBtdFj0fbHvPhR5Di74E0PfNUAA+UYVYfgHgw
[exit status: 0]
$ git log -1 --format='%h  %G?  committed %cs  %s'
8c7d0a6  G  committed 2026-08-30  Rotate the staging credentials
```
<!-- /snippet -->

The key's window ended on 31 August and the lab clock says 7 September, so the commit is rejected: "key has expired". Then one environment variable, `GIT_COMMITTER_DATE`, set to 30 August, and a commit made now verifies as good. The verify time is the committer date, and the committer chooses it.

<!-- snippet: ch14b/signature-scope/06-revocation -->
```text
$ cut -d' ' -f1,2 ~/keys/you_2026.pub > ~/revoked_keys
$ git config set --global gpg.ssh.revocationFile ~/revoked_keys
$ git verify-commit HEAD
Could not verify signature.
[exit status: 1]
$ git log -1 --format='%h  %G?  %s'
8c7d0a6  B  Rotate the staging credentials
```
<!-- /snippet -->

With the key in the revocation file, the same commit is `B`. For every date.

**Step 4: the forgery where everyone signs.** Replay `labs/run ch14b/spoof-signed`. Volatile.

<!-- snippet: ch14b/spoof-signed/01-allowed-signers -->
```text
$ cut -c1-60 ~/allowed_signers
you@example.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI
asha@example.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZD
$ git log -1 --format='%h  %G?  author=%ae  signer=%GS  %s'
4306257  G  author=asha@example.com  signer=asha@example.com  Add health endpoint
```
<!-- /snippet -->

Two principals in the allowed-signers file, and Asha's genuine commit is signed by her key.

<!-- snippet: ch14b/spoof-signed/02-unsigned-forgery -->
```text
$ printf 'requests_per_minute: 6000\n' > config/limits.yaml
$ git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Raise the rate limit"
$ git log -2 --format='%h  %G?  author=%ae  signer=%GS  %s'
bc6a046  N  author=asha@example.com  signer=  Raise the rate limit
4306257  G  author=asha@example.com  signer=asha@example.com  Add health endpoint
```
<!-- /snippet -->

The unsigned forgery stands out now: `N`, no signer, in a history where her real commit is `G`.

```bash
git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -S -am "Raise the rate limit again"
git verify-commit HEAD
```

**[PAUSE]** You cannot sign as Asha; you do not have her private key. You can sign with your own. The commit claims Asha and is signed by you. What is the exit status of `git verify-commit`?

<!-- snippet: ch14b/spoof-signed/03-signed-forgery -->
```text
# You cannot sign as Asha: you do not have her private key. You can sign with your own.
$ printf 'requests_per_minute: 60000\n' > config/limits.yaml
$ git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -S -am "Raise the rate limit again"
$ git verify-commit HEAD
Good "git" signature for you@example.com with ED25519 key SHA256:XpH8NGlAagHBiC1XlKWmz7zMcGZ2uC4HE68dHGQP3zg
[exit status: 0]
$ git log -3 --format='%h  %G?  author=%ae  signer=%GS  %s'
4687f7f  G  author=asha@example.com  signer=you@example.com  Raise the rate limit again
bc6a046  N  author=asha@example.com  signer=  Raise the rate limit
4306257  G  author=asha@example.com  signer=asha@example.com  Add health endpoint
```
<!-- /snippet -->

Zero. A good signature for `you@example.com`. Git verified a signature against the list of trusted keys, and your key is on the list. It did not compare the signer with the author line. Read the three log lines: author Asha in all three; signer Asha, nobody, and you.

<!-- snippet: ch14b/spoof-signed/04-policy-check -->
```text
# Git verified a signature. It did not compare the signer with the author. A policy check does:
$ git log -3 --format='%h %G? %ae %GS' | awk '{ ok = ($2 == "G" && $3 == $4) ? "ok  " : "FAIL"; print ok, $0 }'
FAIL 4687f7f G asha@example.com you@example.com
FAIL bc6a046 N asha@example.com 
ok   4306257 G asha@example.com asha@example.com
```
<!-- /snippet -->

The policy check is one line of `awk` over four placeholders: the result must be `G` and the author address must equal the signer. Two of three commits fail it.

```bash
git merge --verify-signatures --ff-only main~1
git merge --verify-signatures --ff-only main
```

`git merge` that fast-forwards is 🟡. **[PAUSE]** The first merge target is the unsigned forgery. The second is the signed forgery, with the unsigned one underneath it. Which is refused?

<!-- snippet: ch14b/spoof-signed/05-merge-verify -->
```text
$ git switch -q -c integration main~2
$ git merge --verify-signatures --ff-only main~1
fatal: Commit bc6a046 does not have a GPG signature.
[exit status: 128]
# The option looks at one commit only: the tip of what is being merged.
$ git merge --verify-signatures --ff-only main
Commit 4687f7f has a good GPG signature by you@example.com
Updating 4306257..4687f7f
Fast-forward
 config/limits.yaml | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)
[exit status: 0]
$ git log -3 --format='%h  %G?  author=%ae  signer=%GS'
4687f7f  G  author=asha@example.com  signer=you@example.com
bc6a046  N  author=asha@example.com  signer=
4306257  G  author=asha@example.com  signer=asha@example.com
```
<!-- /snippet -->

The unsigned tip is refused. The signed tip is accepted, and it brings the unsigned commit underneath along. The option looks at one commit: the tip of what is being merged.

## COMMON MISTAKES

1. **Treating the author line or `git shortlog` as evidence of who made a commit.** Root cause: author and committer are text supplied by whoever creates the commit.
2. **Treating exit status 0 of `git verify-commit` as "the author signed this".** Root cause: Git verifies the signature against the trusted keys and never compares the signer with the author line.
3. **Relying on `git merge --verify-signatures` as a history policy.** Root cause: it verifies only the tip commit of the side branch.
4. **Removing an old key from the allowed-signers file at rotation.** Root cause: verification looks the key up in the file, so old commits turn from `G` to `U`; rotation adds, never replaces.
5. **Expecting signatures to survive a rebase, a squash or a history filter.** Root cause: a rewrite writes new objects, signed by the operator's key or by none.

## PRODUCTION EXAMPLE

The CTO's question from the last video, answered properly. A commit on `main` of the inference gateway raised a rate limit tenfold. The author line names Asha. She says she did not make it.

If the commit is unsigned, Git cannot say who made it; the honest answer is "anyone with push access", and the investigation goes to the server's record of who pushed. If the commit is signed, Git can say which key signed it: run the log with `%G?`, the author address and `%GS`. If the signer is not the author, you have a named key and its owner to talk to. Section 14B.19 says how to treat a signed history that contains a commit its named author never made: as an incident.

The textbook then widens the view with the case from the Phase 0 report: the xz-utils backdoor of 2024, introduced by a contributor who had earned commit rights over two years and activated by a script that existed only in the release tarball. Every commit could have been perfectly signed. Provenance is not safety.

## PRACTICE EXERCISE

Do Lab 24.2, "A spoofed-author commit", in [`lab-manual/m24-signing-local.md`](../../lab-manual/m24-signing-local.md), in `labs/shell`. The keys are generated in your sandbox, so your IDs differ.

Before each verification, predict three things and write them down: the letter `%G?` will print, the signer `%GS` will print, and the exit status of `git verify-commit`. Then predict which of your commits a comparison of signer and author would flag.

The challenge is Exercise 24.2, "Five commits, five claims", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q309: "What bytes does a commit signature cover? Name three things about a commit that it does not establish."

A strong answer starts with the object: which bytes go to the signing program, and why the tree and parent IDs extend the coverage to files and ancestors. Then it moves outside the object and names things from the right-hand box of the diagram, with one sentence each on why they are outside. It keeps "the key signed" apart from "the person signed". The follow-up asks how a signed tag can verify under a name it was not created with; answer from what a ref is, and say what a careful verifier compares.

## RECAP

You should now be able to say:

- Author and committer are assertions; Git and the push check them against nothing, and a plain Git server accepts a forged author.
- A signature covers every byte of one object and nothing outside it: not refs, not the push, not later rewrites.
- Amend, rebase and cherry-pick write new commits, signed by the operator or not at all.
- `git verify-commit` answers "did a trusted key sign this", not "did the named author sign this"; comparing signer and author is a policy you run yourself.
- `git merge --verify-signatures` checks only the tip.

## HOMEWORK

Read sections 14B.17 to 14B.21 of [Chapter 14B](../../textbook/ch14b-config-tags-signing.md) and section 21B.5 of [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md). Do the Practice section 14B.23.
