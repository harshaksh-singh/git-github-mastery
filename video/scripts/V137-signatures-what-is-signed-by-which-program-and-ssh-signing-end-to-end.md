# V137: Signatures: what is signed, by which program, and SSH signing end to end

- **Part.** 5: GitHub
- **Module.** 24
- **Planned minutes.** 22
- **Prerequisites.** V021, V120
- **Textbook sections.** [Chapter 14B](../../textbook/ch14b-config-tags-signing.md), sections 14B.15 and 14B.16; [Chapter 6](../../textbook/ch06-commits.md), section 6.11
- **Demo scripts.** `labs/ch06/signed-header.sh`, `labs/ch14b/signing-backends.sh`, `labs/ch14b/ssh-signing.sh` (volatile: keys, signatures and IDs differ on every run)

## HOOK

**[ON SCREEN]** One line: "Who made this commit?"

Your CTO points at a commit on `main` that raised a rate limit in production and asks who made it. A commit is one saved snapshot of the project, with a note of who saved it. You read the author line. The CTO asks the next question: how do you know that line is true? Say your answer out loud.

**[PAUSE]**

**[ANIMATION]** cards: id=who question=How_do_you_know_the_author_line_is_true? cards=an_unsigned_commit:anyone_with_push_access|a_signed_commit:a_precise_and_limited_statement_about_a_key at_1=3 at_2=28

For an unsigned commit the honest answer, in the textbook's words, is "anyone with push access". A signature changes the answer, but only to a precise and limited statement about a key. This video shows what's signed, which program signs it, and how to set up and verify SSH signing on your own machine without GitHub being involved at all. Keep that second question. Its exact answer comes at the end.

## INTRODUCTION

**[ANIMATION]** end

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You know the commit object from Part 1: a tree, which is the snapshot of the files, then parents, author, committer and message. You know SSH keys from the authentication videos: a private key that never leaves your machine, and a public key that you hand out. This video joins the two.

There are three parts. First the header itself: where a signature is stored in a commit and in a tag. Second, the program: Git does no cryptography, so you'll see exactly what it asks of an external program for each of the three formats. Third, SSH signing end to end: a key, three settings, a signed commit, a verification that fails for an instructive reason, the allowed-signers file that repairs it, signing by default, a signed tag, and the error messages for a key that can't be used.

Everything here is Git, not GitHub. What GitHub displays for a signature is the subject of video 139.

A note on the transcripts. Two of the three demos, `signed-header` and `ssh-signing`, create a fresh key pair inside the sandbox, so they're volatile: the key, the signatures and the commit IDs on your machine will differ from the ones on screen.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- say which bytes of a commit a signature covers and where the signature is stored;
- name the three signing formats Git supports and the program each uses;
- configure SSH signing and sign a commit and a tag;
- verify a signature locally with an allowed-signers file;
- explain the difference between "good signature" and "trusted signer".

## CONCEPT

**[ON SCREEN]** Lower third: Git.

**In one sentence.** A Git signature is a detached cryptographic signature over the bytes of one commit or one annotated tag, produced by an external program and stored inside that object.

**[ANIMATION]** stores: id=sig boxes=signing_program:outside_Git|the_commit_object:as_stored|commit_ID:the_hash_of_the_whole_object rows=1:B:tree_<tree_ID>|1:B:parent_<parent_ID>|1:B:author|1:B:committer|3:B:gpgsig_<signature>@hl|1:B:message|2:A:signs_these_bytes|4:C:signature_included@hl arrows=2:B>A:without_gpgsig|3:A1>B5:signature|4:B>C:hashed mono=on title=Where_a_signature_lives at_1=5 at_2=20 at_3=32

**[ANIMATION]** step: 3

**Precisely.** Git computes the object without a signature, hands those bytes to a signing program, and embeds the result. In a commit the result is the `gpgsig` header. In a tag it is a block appended to the message. That means an annotated tag, which is an object of its own. Since the signature is part of the object, it's covered by the object ID, the hash that names the object.

Quick quiz. You sign a commit that already exists. Does its ID, A, stay the same, or B, change? Your answer?

**[PAUSE]**

**[ANIMATION]** step: 4

B, it changes. Signing an existing commit means writing a new commit, with a new ID. And you can't attach a signature to history after the fact without rewriting that history. Both come up in interviews.

**[ANIMATION]** cards: id=ss cards=-S:signs_with_a_key|-s:adds_the_Signed-off-by_text_to_the_message title=One_letter,_two_meanings at_1=35 at_2=55

Don't confuse two options that differ only in the case of one letter. Capital `-S` signs with a key. Lower-case `-s` adds the `Signed-off-by` text to the message. One is cryptography. The other is a line of text anyone can type.

**[ANIMATION]** end

**Which program.** The setting `gpg.format` chooses.

**[ON SCREEN]** The table of section 14B.15.

With `openpgp`, the default, the program is `gpg`. The key is chosen by `user.signingKey`, or else by the committer identity. Trust is decided by your GnuPG keyring and its trust levels.

With `x509`, available since Git 2.19, the program is `gpgsm`. The key is chosen the same way, and trust is decided by the certificate chain.

With `ssh`, available since Git 2.34, the program is `ssh-keygen`. The key is `user.signingKey`, which is a key file, or a literal key with an agent, or else the command in `gpg.ssh.defaultKeyCommand`. And trust is decided by one plain text file: the file named by `gpg.ssh.allowedSignersFile`.

Each program can be replaced through `gpg.<format>.program`. The demonstration uses that to show you the arguments without starting any real signing program.

The rest of the course uses SSH signing, for two reasons the textbook gives: you already have SSH keys, and the trust file is plain text. OpenPGP and X.509 signing aren't run in the labs, because both would start an agent process.

**[ANIMATION]** stores: id=trust boxes=signing:needs_one_key|verifying:needs_a_statement_of_whom_you_trust rows=1:A:user.signingKey|2:B:gpg.ssh.allowedSignersFile|3:B:find_this_key_in_my_list_of_allowed_signers|4:B:no_list:_Git_does_not_start_ssh-keygen@bad|5:B:one_line:_principal,_options,_public_key@hl title=Two_different_needs at_1=20 at_2=28 at_3=60 at_4=80

**[ANIMATION]** step: 4

**Signing and verifying need different things.** This is the idea that the whole second half of the demonstration rests on. Signing needs one key. Verifying needs a statement of whom you trust. An SSH key has no owner written into it and there's no web of trust. So with SSH, verification means: find this key in my list of allowed signers. Without a list, Git doesn't start `ssh-keygen` at all.

**[ANIMATION]** step: 5

An allowed-signers line has three parts. First a principal, which by convention is an email address. Then optional options. Then a public key. The option `namespaces="git"` restricts the key to Git signatures.

**[ANIMATION]** cards: id=letters cards=G:a_good_signature|B:a_bad_signature|U:good,_validity_unknown|N:no_signature|X,_Y,_R,_E:not_produced_by_the_SSH_demos dim=5 title=One_result_letter_per_commit at_1=22 at_2=55 at_3=2 at_4=40 at_5=70

**[ANIMATION]** step: 2

**The result letters.** For scripts, the format placeholder `%G?` gives one letter. `G` is a good signature: the key is in the allowed-signers file and valid at the signature's time. `B` is a bad signature: the object was altered after signing, or the key is listed in the revocation file.

**[ANIMATION]** step: 5

`U` is a good signature with unknown validity: the key isn't in the file, or outside its validity window. `N` is no signature, and it's also printed, with an error, when no allowed-signers file is configured. The manual lists `X`, `Y`, `R` and `E` as well. The SSH demos of the chapter don't produce them.

## MENTAL MODEL

**[ANIMATION]** graph: id=seal A-B-C main; HEAD=none => + mark:signed:C; name:sealed; say:One_signature,_on_the_newest_commit => + range:A,B,C:covered; name:covers; say:The_signed_bytes_include_the_tree_ID_and_the_parent_IDs

**[ANIMATION]** step: sealed

**Analogy.** A seal pressed onto one page of a ledger. Because each page cites earlier pages by numbers computed from their content, the seal vouches for the whole history behind it.

**[ANIMATION]** step: covers

Follow that through. The signed bytes include the tree ID, so the seal covers every file. They include the parent IDs, so the seal covers every ancestor. One signature on the newest commit vouches for the content of everything it is built on.

**[ANIMATION]** say: A_signature_is_evidence_about_a_key,_not_about_whose_hand_held_it

The analogy breaks where it matters most, and the textbook says so in one sentence: the seal says which ring was used, not whose hand held it. A signature is evidence about a key. Whether that key was in the hand of the person named in the author line is a different question, and no cryptography answers it.

**[ANIMATION]** step: trust.5

**[ANIMATION]** say: Good_signature:_mathematics._Trusted_signer:_your_decision

So keep two phrases apart. "Good signature" is mathematics: these bytes were signed by this key. "Trusted signer" is your decision: this key is on my list, for this principal. In the demonstration you'll see the same object go from "no signature" to "good signature" without a single byte of the repository changing. What changed was your statement of trust.

## DIAGRAM

**[DIAGRAM]** Draw the commit object first, line by line, as `git cat-file -p` prints it. Then box the `gpgsig` header. Then draw the bracket over everything else, and say: these are the bytes handed to the signing program.

```text
   the commit object, as stored
   +--------------------------------------------------+
   | tree      <tree ID>                              | --+
   | parent    <parent ID>                            |   |
   | author    name <email> date                      |   |  signed bytes:
   | committer name <email> date                      |   |  the object WITHOUT gpgsig
   +--------------------------------------------------+   |
   | gpgsig -----BEGIN SSH SIGNATURE-----             |   |
   |  (continuation lines start with a space)         |   |  <- the signature itself
   |  -----END SSH SIGNATURE-----                     |   |     is not among them
   +--------------------------------------------------+   |
   |                                                  |   |
   | message                                          | --+
   +--------------------------------------------------+
        the whole object, signature included, is hashed  ->  commit ID
```

Two layers. The bracket marks the signed bytes: the object without `gpgsig`. The outer box is what the commit ID is computed from, and the signature is inside it. That's why adding one changes the ID.

**[DIAGRAM]** Two layers. The bracket: what the key vouches for. The outer box: what the commit ID is computed from. The signature is inside the outer box, which is why adding one changes the ID.

**[ON SCREEN]** The root-cause box of section 14B.16, one line at a time. Observed behavior: `git log --show-signature` prints "No signature", and `%G?` prints N, for a commit that visibly has a gpgsig header. Git state: the commit is signed; `gpg.ssh.allowedSignersFile` is not set. Mechanism: SSH verification means "find this key in my list of allowed signers"; without a list Git does not start ssh-keygen at all and reports no result. Root cause: signing needs one key; verifying needs a statement of whom you trust. Why Git does this: an SSH key has no owner written into it and no web of trust; the manual says trust is "fully" when the key is in the file and "undefined" otherwise. Correct fix: create the allowed-signers file and point `gpg.ssh.allowedSignersFile` at it. Prevention: distribute the file with the signing setup; a team can keep it in the repository.

Read the root-cause line: signing needs one key; verifying needs a statement of whom you trust.

## LIVE TERMINAL DEMO

**[TERMINAL]** Three replays. Start with `labs/run ch06/signed-header`. It is volatile: a throwaway key is created in the sandbox.

**Step 1: the header.**

```bash
git commit -q -S -m "Describe the project"
git cat-file -p HEAD
```

`git commit -S` is 🟢 SAFE: it adds an object and moves your branch as any commit does. Predict: where in the object will the signature be? Say it out loud.

**[PAUSE]**

<!-- snippet: ch06/signed-header/01-gpgsig -->
```text
$ git commit -q -S -m "Describe the project"
$ git cat-file -p HEAD
tree 5dca3a6e589a5d9b648e2563ac9c17bee742e961
parent 150744516440fbc2cc4197e81141ce63d5fa7cb2
author Lab User <you@example.com> 1788755880 +0530
committer Lab User <you@example.com> 1788755880 +0530
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgeAvXs1QLvASH7oyGmTC81lgOeA
 6h9gfo2suPhirxoDgAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQMMcYH0dg+LhdIIe0rd3ubk6j0JVijcMdpjwjHWVTTO8y+/dNh80pVbiWWOPlTtXcO
 T8VhfAj9d5XxVa0EFx6gU=
 -----END SSH SIGNATURE-----

Describe the project
```
<!-- /snippet -->

Between the committer line and the message. The header is named `gpgsig` whatever the format. Here its content is an SSH signature. Continuation lines begin with a space.

**Step 2: what Git asks of the program.** Replay `labs/run ch14b/signing-backends`.

```bash
cat ~/lab-bin/show-args
git config get gpg.format
```

<!-- snippet: ch14b/signing-backends/01-stand-in -->
```text
$ cat ~/lab-bin/show-args
#!/bin/sh
# Stand-in for a signing program: show the arguments, sign nothing.
echo "signing program called with: $*" | sed "s|/[^ ]*/\.git_signing_buffer_tmp[A-Za-z0-9]*|<file with the payload>|" >&2
exit 1
$ git config get gpg.format
[exit status: 1]
```
<!-- /snippet -->

The stand-in prints its arguments and exits with an error. It signs nothing. And `gpg.format` isn't set, so the default applies: OpenPGP.

```bash
git -c gpg.program=~/lab-bin/show-args commit -S --allow-empty -m "Signed with OpenPGP"
```

No `user.signingKey` is configured. How will Git tell the program which key to use? Make your prediction.

**[PAUSE]**

<!-- snippet: ch14b/signing-backends/02-openpgp -->
```text
$ git -c gpg.program=~/lab-bin/show-args commit -S --allow-empty -m "Signed with OpenPGP"
error: gpg failed to sign the data:
signing program called with: --status-fd=2 -bsau Lab User <you@example.com>

fatal: failed to write commit object
[exit status: 128]
```
<!-- /snippet -->

Read the arguments: the key was selected by the committer identity. And read the first line, because you'll meet it in real life: "gpg failed to sign the data". That's the generic message for "the signing program returned an error". No key for that identity, an agent that can't ask for the passphrase, a wrong `gpg.program`: all produce it. The commit wasn't written.

<!-- snippet: ch14b/signing-backends/03-x509 -->
```text
$ git -c gpg.format=x509 -c gpg.x509.program=~/lab-bin/show-args commit -S --allow-empty -m "Signed with X.509"
error: gpg failed to sign the data:
signing program called with: --status-fd=2 -bsau Lab User <you@example.com>

fatal: failed to write commit object
[exit status: 128]
```
<!-- /snippet -->

X.509: another program setting, the same arguments.

```bash
git -c gpg.format=ssh -c gpg.ssh.program=~/lab-bin/show-args commit -S --allow-empty -m "Signed with SSH"
```

The SSH format, and still no signing key configured. Will Git fall back to the committer identity again? Say yes or no.

**[PAUSE]**

<!-- snippet: ch14b/signing-backends/04-ssh -->
```text
$ git -c gpg.format=ssh -c gpg.ssh.program=~/lab-bin/show-args commit -S --allow-empty -m "Signed with SSH"
fatal: either user.signingkey or gpg.ssh.defaultKeyCommand needs to be configured
[exit status: 128]
$ git -c gpg.format=ssh -c gpg.ssh.program=~/lab-bin/show-args -c user.signingKey=~/keys/signing_key.pub commit -S --allow-empty -m "Signed with SSH"
error: signing program called with: -Y sign -n git -f $LAB/ch14b/signing-backends/home/keys/signing_key.pub <file with the payload>

fatal: failed to write commit object
[exit status: 128]
```
<!-- /snippet -->

It won't. The SSH backend has no default key. With a key, Git runs `ssh-keygen -Y sign` with the namespace `git`, and passes the payload as a file.

<!-- snippet: ch14b/signing-backends/05-bad-format -->
```text
$ git -c gpg.format=pgp commit -S --allow-empty -m "Signed with?"
error: invalid value for 'gpg.format': 'pgp'
fatal: unable to parse 'gpg.format' from command-line config
[exit status: 128]
$ git log --oneline -1
eb112a5 Add rate limits
```
<!-- /snippet -->

A misspelled format is refused before anything else happens, and the last commit is still the old one.

**Step 3: SSH signing end to end.** Replay `labs/run ch14b/ssh-signing`. Volatile again.

```bash
mkdir ~/keys
ssh-keygen -q -t ed25519 -N '' -C 'you@example.com signing key 2026' -f ~/keys/signing_key
```

<!-- snippet: ch14b/ssh-signing/01-key -->
```text
$ mkdir ~/keys
$ ssh-keygen -q -t ed25519 -N '' -C 'you@example.com signing key 2026' -f ~/keys/signing_key
$ ls ~/keys
signing_key
signing_key.pub
$ cat ~/keys/signing_key.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeZ8qdHWOUuKtL/yAKkDk4n+e6oo2sO2JTJ8lmdYFDE you@example.com signing key 2026
$ ssh-keygen -l -f ~/keys/signing_key.pub
256 SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs you@example.com signing key 2026 (ED25519)
```
<!-- /snippet -->

A key pair without a passphrase, inside the sandbox. Say this aloud: this is a lab key. A real signing key has a passphrase and lives in an agent or a hardware token.

```bash
git config set --global gpg.format ssh
git config set --global user.signingKey ~/keys/signing_key.pub
```

`git config set` is 🟡 CAUTION: it changes one configuration file, which has no history. In the lab, "global" is the sandbox's isolated configuration, never your own.

<!-- snippet: ch14b/ssh-signing/02-configure -->
```text
$ git config set --global gpg.format ssh
$ git config set --global user.signingKey ~/keys/signing_key.pub
$ git config get --all --show-names --regexp "^(gpg|user\.signingkey)"
user.signingkey $LAB/ch14b/ssh-signing/home/keys/signing_key.pub
gpg.format ssh
```
<!-- /snippet -->

Look at the file name: `user.signingKey` names the public key file. `ssh-keygen` finds the private key beside it, or in an agent.

<!-- snippet: ch14b/ssh-signing/03-sign-a-commit -->
```text
$ printf 'burst: 20\n' >> config/limits.yaml
$ git commit -q -S -am "Allow short bursts"
$ git cat-file -p HEAD
tree c84890b7f7cbb711c04b9a7fb78410beb5897d9b
parent eb112a5c44b0b2092c4ef2cae6e75b16da000f73
author Lab User <you@example.com> 1788756300 +0530
committer Lab User <you@example.com> 1788756300 +0530
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg95nyp0dY5S4q0v/IAqQOTif57q
 ijaw7YlMnyWZ1gUMQAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQJMccrn4Dmj2cHUPAHhz39NlMtXXlS2u+/lOewunSjVhvREL3WkYdp/G0PrihonpvT
 +ZHT0fNnmCm7pVB7KlHQ4=
 -----END SSH SIGNATURE-----

Allow short bursts
```
<!-- /snippet -->

A signed commit, read as an object. The same header as in step 1.

```bash
git verify-commit HEAD
git log -1 --show-signature --format="%h %s"
git log -1 --format='%h  %G?  %s'
```

You signed this commit thirty seconds ago with your own key. What will `git verify-commit` say? Say it out loud.

**[PAUSE]**

<!-- snippet: ch14b/ssh-signing/04-verify-without-trust -->
```text
$ git verify-commit HEAD
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
[exit status: 1]
$ git log -1 --show-signature --format="%h %s"
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
No signature
f215ce4 Allow short bursts
$ git log -1 --format='%h  %G?  %s'
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
f215ce4  N  Allow short bursts
```
<!-- /snippet -->

An error, exit status 1, "No signature", and the letter `N`, for a commit that visibly has a `gpgsig` header. This is the root-cause box from the diagram section. Git was never told whom to trust, so it didn't verify at all.

```bash
printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ~/keys/signing_key.pub)" > ~/allowed_signers
git config set --global gpg.ssh.allowedSignersFile ~/allowed_signers
git verify-commit HEAD
```

<!-- snippet: ch14b/ssh-signing/05-allowed-signers -->
```text
$ printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ~/keys/signing_key.pub)" > ~/allowed_signers
$ cat ~/allowed_signers
you@example.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeZ8qdHWOUuKtL/yAKkDk4n+e6oo2sO2JTJ8lmdYFDE
$ git config set --global gpg.ssh.allowedSignersFile ~/allowed_signers
$ git verify-commit HEAD
Good "git" signature for you@example.com with ED25519 key SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
[exit status: 0]
$ git log -2 --show-signature --format="%h %an: %s"
Good "git" signature for you@example.com with ED25519 key SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
f215ce4 Lab User: Allow short bursts
eb112a5 Lab User: Add rate limits
```
<!-- /snippet -->

One line in a text file: principal, namespace option, public key. Now the same object verifies: a good "git" signature for that principal, exit status 0. Nothing in the repository changed. And in the two-commit log, only the newer commit carries a signature line. The older one was never signed.

<!-- snippet: ch14b/ssh-signing/06-placeholders -->
```text
$ git log -2 --format='%h  %G?  signer=%GS  trust=%GT  %s'
f215ce4  G  signer=you@example.com  trust=fully  Allow short bursts
eb112a5  N  signer=  trust=undefined  Add rate limits
$ git log -1 --format='%GK'
SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
```
<!-- /snippet -->

The placeholders for scripts: `%G?` for the result letter, `%GS` for the signer, `%GT` for the trust level, `%GK` for the key.

Try it now, thirty seconds, in a repository of your own. Run `git log -3 --format='%h %G? %s'`. It only reads. Which letters do you get?

**[PAUSE]**

**[ANIMATION]** step: letters.5

With no signing configured, it's most often `N` three times: no signature, or, with an error line above it, a signature that Git couldn't check without an allowed-signers file. Any other letter is in the list you heard earlier.

```bash
git config set --global commit.gpgSign true
git config set --global tag.gpgSign true
```

<!-- snippet: ch14b/ssh-signing/07-sign-by-default -->
```text
$ git config set --global commit.gpgSign true
$ git config set --global tag.gpgSign true
$ printf 'retry_after_seconds: 2\n' >> config/limits.yaml
$ git commit -q -am "Tell clients when to retry"
$ git commit -q --no-gpg-sign --allow-empty -m "Trigger the nightly evaluation"
$ git log -4 --format='%h  %G?  %GS  %s'
e32a07f  N    Trigger the nightly evaluation
9d47104  G  you@example.com  Tell clients when to retry
f215ce4  G  you@example.com  Allow short bursts
eb112a5  N    Add rate limits
```
<!-- /snippet -->

With `commit.gpgSign` true, every commit is signed without `-S`. `--no-gpg-sign` opts one commit out, and the log shows it with `N`.

**[ANIMATION]** graph: id=log ...2-eb112a5-f215ce4-9d47104-e32a07f main; HEAD=main; mark:N:eb112a5,e32a07f; mark:G:f215ce4,9d47104; say:The_result_letters_of_git_log_-4 pace=quick

`tag.gpgSign` is true. The next command creates a tag with `-m` only. What kind of tag will it be? Make your prediction.

**[PAUSE]**

<!-- snippet: ch14b/ssh-signing/08-signed-tag -->
```text
$ git tag -m "inference-gateway 1.0.0" v1.0.0 HEAD~1
$ git cat-file -p v1.0.0
object 9d471046051e8d578b339ee37eb466c71e16b6ec
type commit
tag v1.0.0
tagger Lab User <you@example.com> 1788757380 +0530

inference-gateway 1.0.0
-----BEGIN SSH SIGNATURE-----
U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg95nyp0dY5S4q0v/IAqQOTif57q
ijaw7YlMnyWZ1gUMQAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
AAAAQENhU0YSEgUB1RmZBsnzJdHgXZdddaBvXKoPIFK23QLUTUltL6Gr+o9kyWszNlomBF
apz4b7Ok5FFB+R/+c0swo=
-----END SSH SIGNATURE-----
$ git verify-tag v1.0.0
Good "git" signature for you@example.com with ED25519 key SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
[exit status: 0]
$ git tag -v v1.0.0
Good "git" signature for you@example.com with ED25519 key SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
object 9d471046051e8d578b339ee37eb466c71e16b6ec
type commit
tag v1.0.0
tagger Lab User <you@example.com> 1788757380 +0530

inference-gateway 1.0.0
```
<!-- /snippet -->

A signed tag. `git tag` is 🟢 SAFE: it adds an object and a ref. In a tag the signature follows the message. `git verify-tag` and `git tag -v` both report a good signature. The second also prints the tag's content. All three verification commands exit non-zero on anything but a trusted good signature, so they work in scripts.

<!-- snippet: ch14b/ssh-signing/09-mechanism -->
```text
# Git does no cryptography itself. The programs it starts to sign and to verify:
$ GIT_TRACE=1 git commit -q --allow-empty -m 'Re-run the nightly evaluation' 2>&1 | grep -o 'run_command: ssh-keygen -Y [a-z-]* -n git'
run_command: ssh-keygen -Y sign -n git
$ GIT_TRACE=1 git verify-commit HEAD 2>&1 | grep -o 'run_command: ssh-keygen -Y [a-z-]*'
run_command: ssh-keygen -Y find-principals
run_command: ssh-keygen -Y verify
$ git verify-commit --raw HEAD
Good "git" signature for you@example.com with ED25519 key SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
```
<!-- /snippet -->

With `GIT_TRACE` you see the programs Git starts.

**[ANIMATION]** flow: id=progs actors=Git,ssh-keygen msgs=1>2:-Y_sign_-n_git|1>2:-Y_find-principals|1>2:-Y_verify mono=on title=Git_does_no_cryptography_itself at_1=3 at_2=30 at_3=68

One to sign. Two steps to verify: find which principal the key belongs to, then verify the signature for that principal.

**[ANIMATION]** end

**Step 4: when the key cannot be used.**

<!-- snippet: ch14b/ssh-signing/10-key-problems -->
```text
# Three ways the key can be unusable, and what Git says.
$ mv ~/keys/signing_key ~/keys/signing_key.away
$ git commit -q --allow-empty -m "Sign without the private key"
error: No private key found for public key "$LAB/ch14b/ssh-signing/home/keys/signing_key.pub"?

fatal: failed to write commit object
[exit status: 128]
$ mv ~/keys/signing_key.away ~/keys/signing_key
$ git -c user.signingKey=~/keys/no_such_key.pub commit -q --allow-empty -m "Sign with a wrong path"
error: Couldn't load public key $LAB/ch14b/ssh-signing/home/keys/no_such_key.pub: No such file or directory?

fatal: failed to write commit object
[exit status: 128]
$ git -c user.signingKey="key::$(cut -d" " -f1,2 ~/keys/signing_key.pub)" commit -q --allow-empty -m "Sign with a literal key and no agent"
error: Couldn't get agent socket?

fatal: failed to write commit object
[exit status: 128]
```
<!-- /snippet -->

Three failures, three messages. The private key is missing: "No private key found". The path is wrong: "Couldn't load public key". A literal key with no agent: "Couldn't get agent socket". In each case the commit object isn't written. Remember that `commit.gpgSign` is true in this sandbox: a broken key blocks every commit.

## COMMON MISTAKES

Five mistakes to watch for.

1. **"`error: gpg failed to sign the data`" and no idea why.** Root cause: the message only says that the signing program returned an error; the format, the key and the program each have to be checked.
2. **A signed commit shows "No signature".** Root cause: `gpg.ssh.allowedSignersFile` is unset or the file is missing, so Git does not verify at all.
3. **Pointing `user.signingKey` at a path that does not exist, or expecting SSH signing to pick a key by identity.** Root cause: the SSH backend has no default key.
4. **Switching on `commit.gpgSign` and then losing access to the key.** Root cause: with the setting on and no working key, every commit fails, including the one you need during an incident; know `--no-gpg-sign`, and whether your server accepts the result.
5. **Confusing `-s` with `-S`.** Root cause: one adds a text trailer to the message, the other adds a cryptographic header to the object.

## PRODUCTION EXAMPLE

**[ANIMATION]** stores: id=team boxes=your_machine:an_allowed-signers_file|the_repository:one_allowed-signers_file|a_teammate's_machine:an_allowed-signers_file rows=1:A:one_line:_your_own_key|1:C:one_line:_their_own_key|2:B:one_line_per_engineer|2:B:reviewed_like_code|3:B:rotation:_old_key_and_new_key_both_listed@ok arrows=2:A>B:points_here|2:C>B:points_here title=Whose_list_of_allowed_signers? at_1=58 at_2=30 at_3=55

**[ANIMATION]** step: 1

Now, out of the lab. A team that serves an inference gateway decides to sign commits. Each engineer generates a signing key and sets the three settings. On the first day everyone's own commits verify on their own machine and nobody else's do: each person has an allowed-signers file with one line, their own.

**[ANIMATION]** step: 2

The fix is the prevention line of the root-cause box. The team keeps one allowed-signers file in the repository, with one line per engineer, reviewed like code, and each clone points `gpg.ssh.allowedSignersFile` at it. From then on a release script can run `git verify-tag` and trust the exit status.

**[ANIMATION]** step: 3

Then the first key rotation. An engineer replaces their line with the new key, and their old commits turn from `G` to `U`. The textbook's rule: rotation adds, never replaces. Both keys stay listed.

## PRACTICE EXERCISE

**[ANIMATION]** end

Your turn. Do Lab 24.1, "SSH signing locally", in [`lab-manual/m24-signing-local.md`](../../lab-manual/m24-signing-local.md). It runs in `labs/shell` with a key generated in the sandbox. Your key and IDs will differ from the video.

Before you run each verification command, predict the result letter and the exit status. In particular, predict what verification says before the allowed-signers file exists and after.

The challenge is Exercise 24.1, "Covered or not covered?", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q34: "What is the difference between `git commit -s` and `git commit -S`? Where does each leave its mark in the object?"

**[PAUSE]**

Answer out loud first. A strong answer names what each option adds and in which part of the commit object it sits, and says which of the two is evidence of anything and of what. It mentions that the signature is inside the object and what that means for the commit ID. Be ready for the follow-up about signing every commit on a shared branch retroactively: reason from the fact that signing an existing commit writes a new commit, and work out what that does to every descendant and to everyone who has the old history.

## RECAP

**[ANIMATION]** step: who.2

Let's land this. The CTO asked how you know the author line is true. For an unsigned commit, you don't. For a signed one, you know which key signed those bytes, and whether that key is on your list.

You should now be able to say:

- A signature covers the bytes of one commit or tag without the signature, and is stored inside the object: the `gpgsig` header in a commit, a block after the message in a tag.
- Git does no cryptography; `gpg.format` selects `gpg`, `gpgsm` or `ssh-keygen`.
- SSH signing needs `gpg.format`, `user.signingKey` and, for verification, `gpg.ssh.allowedSignersFile`.
- Without an allowed-signers file, a signed commit reports "No signature".
- A good signature is a fact about a key; a trusted signer is your decision about that key.

## HOMEWORK

Read sections 14B.15 and 14B.16 of [Chapter 14B](../../textbook/ch14b-config-tags-signing.md).

Today you signed a commit and a tag, and you watched "No signature" become a good signature by adding one line of trust. Practise on a repository of yours before the next video. Next time: what a signature covers, what verification proves, and author spoofing. Until then, look at the state first and type second. See you in the next one.
