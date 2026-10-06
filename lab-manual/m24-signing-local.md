# Module 24 labs, local part: Commit signing and verification

> **Baseline.** Git 2.55.0 and OpenSSH 10.2 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch14b/`. Read [Chapter 14B: Configuration, Aliases, Tags and Signing](../textbook/ch14b-config-tags-signing.md), sections 14B.15 to 14B.18, first. The GitHub side of this module (what the platform displays, vigilant mode, required signatures) is in a separate lab file, `m24-signing-github.md`.

## How to run these labs

Each lab has a setup script that builds its starting state in the hands-on sandbox, and replay scripts that ran the lab and produced the transcripts below. From the course root:

```bash
bash labs/ch14b/setup-24-1-ssh-signing.sh      # build the starting state (run again to start over)
labs/shell m24-1                               # open the isolated lab shell in that sandbox
labs/run ch14b/lab-24-1-ssh-signing            # optional: replay the lab and print its transcript
```

**Keys in these labs.** You generate throwaway Ed25519 keys *inside the sandbox*, without a passphrase. They are for these labs only. Your real keys in `~/.ssh` are not read, not listed and not changed, and no agent is used: the first step of each lab unsets `SSH_AUTH_SOCK` in the lab shell, so `ssh-keygen` cannot reach an agent and works from the key files alone. A real signing key has a passphrase and lives in an agent or a hardware token (Chapter 16).

**Volatile transcripts.** A replay that generates keys produces different keys, signatures and object IDs on every run; `labs/verify-all.sh` marks such a replay `VOLATILE` and only checks that it runs. Your output will differ from the book in the same places: fingerprints (`SHA256:...`), signature blocks, and every ID of a signed object. Everything else should match.

Differences between your terminal and the transcripts:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command.
- Lines that start with `#` are notes from a script, not output of Git.
- `$LAB` is the lab root. The replays ran in `$LAB/ch14b/lab-24-<k>-...`; your sandbox is `$LAB/hands-on/m24-<k>`.
- Commits you create carry the real time, not the lab clock of 7 September 2026.

| Lab | Topic | Sandbox | Replay |
|---|---|---|---|
| 24.1 | SSH signing locally | `m24-1` | `ch14b/lab-24-1-ssh-signing` (volatile) |
| 24.2 | A spoofed-author commit | `m24-2` | `ch14b/lab-24-2-spoofed-author`, `ch14b/lab-24-2-spoofed-author-volatile` |

Answers to the Questions of every lab are in [solutions/m24-local-lab-answers.md](../solutions/m24-local-lab-answers.md). Write your own answers first.

## Lab 24.1: SSH signing locally

### Objective

Sign commits and a tag with an SSH key and verify them locally: create a key, configure Git, read the signature inside the objects, watch verification fail until you state whom you trust, and make signing the default. Then rotate the key the wrong way, see last year's history lose its verification, and rotate it the right way.

### Prerequisites

- Chapter 14B, sections 14B.15 to 14B.17.
- Chapter 6, section 6.11, for the `gpgsig` header.
- Lab 5.1, for the first step that moves `HOME` and the global configuration into the sandbox.

### Setup

```bash
bash labs/ch14b/setup-24-1-ssh-signing.sh
labs/shell m24-1
```

The sandbox contains `home/.gitconfig` and the repository `home/work/inference-gateway` with three unsigned commits.

### Commands

Step 1. Enter the sandbox's home, cut the shell off from any agent, and create a key pair there.

```bash
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
unset SSH_AUTH_SOCK
mkdir ~/keys
ssh-keygen -q -t ed25519 -N '' -C 'you@example.com signing key 2026' -f ~/keys/signing_2026
ssh-keygen -l -f ~/keys/signing_2026.pub
```

Step 2. Tell Git to sign with SSH and with this key, sign one commit, and read the object.

```bash
git config set --global gpg.format ssh
git config set --global user.signingKey ~/keys/signing_2026.pub
cd ~/work/inference-gateway
printf 'burst: 20\n' >> config/limits.yaml
git commit -q -S -am "Allow short bursts"
git cat-file -p HEAD
```

Step 3. Verify it. Predict the result before you run the commands.

```bash
git verify-commit HEAD
git log -1 --format='%h  %G?  %s'
```

Step 4. State whom you trust, and verify again.

```bash
printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ~/keys/signing_2026.pub)" > ~/allowed_signers
git config set --global gpg.ssh.allowedSignersFile ~/allowed_signers
git verify-commit HEAD
git log -2 --format='%h  %G?  %GS  %s'
```

Step 5. Sign by default, and sign a tag.

```bash
git config set --global commit.gpgSign true
git config set --global tag.gpgSign true
printf 'retry_after_seconds: 2\n' >> config/limits.yaml
git commit -q -am "Tell clients when to retry"
git tag -m "inference-gateway 1.0.0" v1.0.0
git cat-file -p v1.0.0
git verify-tag v1.0.0
git log -3 --format='%h  %G?  %GS  %s'
```

### Expected output

This replay is volatile: your fingerprints, signature blocks and the IDs of signed objects differ.

<!-- snippet: ch14b/lab-24-1-ssh-signing/01-enter -->
```text
$ export HOME="$PWD/home"
$ export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
$ unset SSH_AUTH_SOCK
$ mkdir ~/keys
$ ssh-keygen -q -t ed25519 -N '' -C 'you@example.com signing key 2026' -f ~/keys/signing_2026
$ ssh-keygen -l -f ~/keys/signing_2026.pub
256 SHA256:pQrUnrY63MhWWsoUImllHsxZESF47B19KMMrFNt8KTQ you@example.com signing key 2026 (ED25519)
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-24-1-ssh-signing/02-configure-and-sign -->
```text
$ git config set --global gpg.format ssh
$ git config set --global user.signingKey ~/keys/signing_2026.pub
$ cd ~/work/inference-gateway
$ printf 'burst: 20\n' >> config/limits.yaml
$ git commit -q -S -am "Allow short bursts"
$ git cat-file -p HEAD
tree c84890b7f7cbb711c04b9a7fb78410beb5897d9b
parent eb112a5c44b0b2092c4ef2cae6e75b16da000f73
author Lab User <you@example.com> 1788756360 +0530
committer Lab User <you@example.com> 1788756360 +0530
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAglE2DofMoRbhHGUJl8wa+JauLrY
 wSOXVYa7O7xEJYQR0AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQEMtX5BOf2UM354XR14setAAQEDsnW8cumPzTQZqyreYNU59mdL/9wR+GvQdoyAyOj
 CCrDwMpooANhWAytHoewE=
 -----END SSH SIGNATURE-----

Allow short bursts
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-24-1-ssh-signing/03-verify-fails -->
```text
$ git verify-commit HEAD
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
[exit status: 1]
$ git log -1 --format='%h  %G?  %s'
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
567ad57  N  Allow short bursts
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-24-1-ssh-signing/04-allowed-signers -->
```text
$ printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ~/keys/signing_2026.pub)" > ~/allowed_signers
$ git config set --global gpg.ssh.allowedSignersFile ~/allowed_signers
$ git verify-commit HEAD
Good "git" signature for you@example.com with ED25519 key SHA256:pQrUnrY63MhWWsoUImllHsxZESF47B19KMMrFNt8KTQ
[exit status: 0]
$ git log -2 --format='%h  %G?  %GS  %s'
567ad57  G  you@example.com  Allow short bursts
eb112a5  N    Add rate limits
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-24-1-ssh-signing/05-default-and-tag -->
```text
$ git config set --global commit.gpgSign true
$ git config set --global tag.gpgSign true
$ printf 'retry_after_seconds: 2\n' >> config/limits.yaml
$ git commit -q -am "Tell clients when to retry"
$ git tag -m "inference-gateway 1.0.0" v1.0.0
$ git cat-file -p v1.0.0
object ac8816174042ec33379f3d8f76cc9c642d75febe
type commit
tag v1.0.0
tagger Lab User <you@example.com> 1788757080 +0530

inference-gateway 1.0.0
-----BEGIN SSH SIGNATURE-----
U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAglE2DofMoRbhHGUJl8wa+JauLrY
wSOXVYa7O7xEJYQR0AAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
AAAAQFEc7OBQEXs/egCRg/7Lu66H/hQNdOkCjXyn5E6DniUGhC2+aSPrd+sCnvQoztkQOK
oLyqz/ApH7SKDk4+kpRAo=
-----END SSH SIGNATURE-----
$ git verify-tag v1.0.0
Good "git" signature for you@example.com with ED25519 key SHA256:pQrUnrY63MhWWsoUImllHsxZESF47B19KMMrFNt8KTQ
[exit status: 0]
$ git log -3 --format='%h  %G?  %GS  %s'
ac88161  G  you@example.com  Tell clients when to retry
567ad57  G  you@example.com  Allow short bursts
eb112a5  N    Add rate limits
```
<!-- /snippet -->

### What happened internally

- `ssh-keygen` wrote two files, `keys/signing_2026` (private) and `keys/signing_2026.pub`. Nothing was added to an agent.
- `git commit -S` built the commit object without a signature, ran `ssh-keygen -Y sign -n git -f <key>` on those bytes, and stored the result in the commit as a `gpgsig` header between the `committer` line and the message. The commit ID is the hash of the object *including* that header.
- The first `git verify-commit` did not check the signature at all. For SSH signatures Git needs a list of keys you trust; without `gpg.ssh.allowedSignersFile` it prints an error, and `%G?` reports `N` although the header is there.
- With the file in place, verification ran in two steps: `ssh-keygen -Y find-principals` looked the signing key up in the file and found the principal `you@example.com`; `ssh-keygen -Y verify` checked the signature for that principal in the namespace `git`. `%G?` became `G`, `%GS` printed the principal.
- `commit.gpgSign=true` made the second commit signed without `-S`. `tag.gpgSign=true` turned the tag created with `-m` into a signed tag: a tag object whose message is followed by the signature block.
- The first commit of the lab, made by the setup script, is unsigned and stays unsigned: `N`.

### Checkpoint

- `git cat-file -p HEAD` shows a `gpgsig` header; `git cat-file -p v1.0.0` ends with a signature block.
- `git verify-commit HEAD` and `git verify-tag v1.0.0` both exit with 0.
- `git log -3 --format='%G?'` prints `G`, `G`, `N`.

### Failure scenario

A year later you rotate the key. You generate a new one, point Git at it, and *replace* your line in the allowed-signers file:

```bash
ssh-keygen -q -t ed25519 -N '' -C 'you@example.com signing key 2027' -f ~/keys/signing_2027
git config set --global user.signingKey ~/keys/signing_2027.pub
printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ~/keys/signing_2027.pub)" > ~/allowed_signers
git commit -q --allow-empty -m "Trigger the nightly evaluation"
git log -4 --format='%h  %G?  %GS  %s'
git verify-tag v1.0.0
```

<!-- snippet: ch14b/lab-24-1-ssh-signing/06-failure -->
```text
# New year, new key. The old line in allowed_signers is replaced by the new one.
$ ssh-keygen -q -t ed25519 -N '' -C 'you@example.com signing key 2027' -f ~/keys/signing_2027
$ git config set --global user.signingKey ~/keys/signing_2027.pub
$ printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ~/keys/signing_2027.pub)" > ~/allowed_signers
$ git commit -q --allow-empty -m "Trigger the nightly evaluation"
$ git log -4 --format='%h  %G?  %GS  %s'
d49fa6b  G  you@example.com  Trigger the nightly evaluation
ac88161  U    Tell clients when to retry
567ad57  U    Allow short bursts
eb112a5  N    Add rate limits
$ git verify-tag v1.0.0
Good "git" signature with ED25519 key SHA256:pQrUnrY63MhWWsoUImllHsxZESF47B19KMMrFNt8KTQ
No principal matched.
[exit status: 1]
```
<!-- /snippet -->

The new commit is `G`. Everything signed with the old key has dropped to `U`, and the release tag no longer verifies: "Good signature ... No principal matched". Nothing in the repository changed. The file that says whom you trust did.

### Recovery

A rotation adds a key. The old key stays in the file for as long as its signatures should verify:

```bash
printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ~/keys/signing_2026.pub)" >> ~/allowed_signers
cut -d" " -f1-3 ~/allowed_signers
git log -4 --format='%h  %G?  %GS  %GK'
git verify-tag v1.0.0
```

<!-- snippet: ch14b/lab-24-1-ssh-signing/07-recovery -->
```text
# A rotation adds a key. The old key stays listed, or everything it signed stops verifying.
$ printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ~/keys/signing_2026.pub)" >> ~/allowed_signers
$ cut -d" " -f1-3 ~/allowed_signers
you@example.com namespaces="git" ssh-ed25519
you@example.com namespaces="git" ssh-ed25519
$ git log -4 --format='%h  %G?  %GS  %GK'
d49fa6b  G  you@example.com  SHA256:Wzb1Hskic2g2rUhNoAf1XZ3TVsbKb6RFcM7SXlGdqxI
ac88161  G  you@example.com  SHA256:pQrUnrY63MhWWsoUImllHsxZESF47B19KMMrFNt8KTQ
567ad57  G  you@example.com  SHA256:pQrUnrY63MhWWsoUImllHsxZESF47B19KMMrFNt8KTQ
eb112a5  N    
$ git verify-tag v1.0.0
Good "git" signature for you@example.com with ED25519 key SHA256:pQrUnrY63MhWWsoUImllHsxZESF47B19KMMrFNt8KTQ
[exit status: 0]
```
<!-- /snippet -->

`%GK` shows which key signed which commit: the newest with the 2027 key, the two older ones with the 2026 key, all for the same principal. In a real rotation you would also give the old key a `valid-before` date and the new key a `valid-after` date; Chapter 14B, section 14B.17, shows that, and shows why those dates do not protect against a stolen key (Question 4).

### Verification

```bash
git config get --global --all --show-names --regexp "^(gpg|commit\.gpgsign|tag\.gpgsign|user\.signingkey)"
git log --format='%G?' | sort | uniq -c | sed 's/^ *//'
git cat-file -p HEAD | grep -c 'BEGIN SSH SIGNATURE'
```

<!-- snippet: ch14b/lab-24-1-ssh-signing/08-verify -->
```text
$ git config get --global --all --show-names --regexp "^(gpg|commit\.gpgsign|tag\.gpgsign|user\.signingkey)"
user.signingkey $LAB/ch14b/lab-24-1-ssh-signing/home/keys/signing_2027.pub
gpg.format ssh
gpg.ssh.allowedsignersfile $LAB/ch14b/lab-24-1-ssh-signing/home/allowed_signers
commit.gpgsign true
tag.gpgsign true
$ git log --format='%G?' | sort | uniq -c | sed 's/^ *//'
3 G
3 N
$ git cat-file -p HEAD | grep -c 'BEGIN SSH SIGNATURE'
1
```
<!-- /snippet -->

Three signed commits that verify, three unsigned commits from before you had a key, and a configuration you can read line by line.

### Questions

1. In step 3 the commit was signed, yet `%G?` printed `N` and `git log --show-signature` would have said "No signature". What was missing, and why can Git not verify an SSH signature without it?
2. What bytes did `ssh-keygen` sign in step 2? If you amended that commit's message now, what would happen to the signature, and whose signature would the new commit carry?
3. `user.signingKey` names the `.pub` file. How did signing work without an agent, and what would the error be if the private key file were missing?
4. The recovery kept both keys in the file without dates. Suppose you add `valid-before` to the old key, set to the day of the rotation. Which signatures does that keep valid, and why does it not stop someone who has stolen the old key from producing commits that verify?
5. After this lab, three commits are `N`. Would you sign them retroactively? What would that involve, and what would it do to their IDs?
6. `git config get gpg.format` prints `ssh`, yet the options are called `commit.gpgSign` and `tag.gpgSign`, and the header is `gpgsig`. What does that tell you about reading older documentation and scripts?

## Lab 24.2: A spoofed-author commit

### Objective

Create commits that claim another person as their author and get them accepted by the server, to see for yourself that author and committer are assertions. Then repeat the forgery in a team that signs, find out what signing changes and what it does not, and write the check that Git does not perform for you.

### Prerequisites

- Chapter 14B, sections 14B.17 and 14B.18.
- Chapter 6, section 6.5, for author and committer.
- Lab 24.1.

### Setup

```bash
bash labs/ch14b/setup-24-2-spoofed-author.sh
labs/shell m24-2
```

The sandbox contains a bare repository `server/inference-gateway.git` and two clones, `you/inference-gateway` and `asha/inference-gateway`. Asha has pushed one genuine commit, "Add health endpoint", and you have pulled it. In Asha's clone, `user.name` and `user.email` are set locally. This lab does not change the global configuration, so there is no `HOME` step.

### Commands

Step 1. The honest starting point.

```bash
cd you/inference-gateway
git log -2 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
```

Step 2. One option changes the author.

```bash
printf 'requests_per_minute: 6000\n' > config/limits.yaml
git commit -q -am "Raise the rate limit" --author="Asha Rao <asha@example.com>"
git log -1 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
```

Step 3. Two configuration values change both fields.

```bash
printf 'requests_per_minute: 60000\n' > config/limits.yaml
git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Raise the rate limit again"
git log -3 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
```

Step 4. Compare her genuine commit with your second forgery, header by header, and ask Git about signatures.

```bash
git cat-file -p HEAD~2 | sed -n "/^author/,/^committer/p"
git cat-file -p HEAD | sed -n "/^author/,/^committer/p"
git log -3 --format='%h  %G?  %an'
```

Step 5. Push, and look at the history from Asha's side.

```bash
git push
cd ../../asha/inference-gateway
git pull -q
git shortlog -sne HEAD
git log -2 --format='%h  %an <%ae>  %s'
```

### Expected output

<!-- snippet: ch14b/lab-24-2-spoofed-author/01-start -->
```text
$ cd you/inference-gateway
$ git log -2 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
39f0449  author=Asha Rao <asha@example.com>  committer=Asha Rao <asha@example.com>  Add health endpoint
d20ef7a  author=Lab User <you@example.com>  committer=Lab User <you@example.com>  Add rate limits
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-24-2-spoofed-author/02-author-flag -->
```text
$ printf 'requests_per_minute: 6000\n' > config/limits.yaml
$ git commit -q -am "Raise the rate limit" --author="Asha Rao <asha@example.com>"
$ git log -1 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
08545cf  author=Asha Rao <asha@example.com>  committer=Lab User <you@example.com>  Raise the rate limit
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-24-2-spoofed-author/03-both-fields -->
```text
$ printf 'requests_per_minute: 60000\n' > config/limits.yaml
$ git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Raise the rate limit again"
$ git log -3 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
8cbd8fd  author=Asha Rao <asha@example.com>  committer=Asha Rao <asha@example.com>  Raise the rate limit again
08545cf  author=Asha Rao <asha@example.com>  committer=Lab User <you@example.com>  Raise the rate limit
39f0449  author=Asha Rao <asha@example.com>  committer=Asha Rao <asha@example.com>  Add health endpoint
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-24-2-spoofed-author/04-compare -->
```text
$ git cat-file -p HEAD~2 | sed -n "/^author/,/^committer/p"
author Asha Rao <asha@example.com> 1788756000 +0530
committer Asha Rao <asha@example.com> 1788756000 +0530
$ git cat-file -p HEAD | sed -n "/^author/,/^committer/p"
author Asha Rao <asha@example.com> 1788756540 +0530
committer Asha Rao <asha@example.com> 1788756540 +0530
$ git log -3 --format='%h  %G?  %an'
8cbd8fd  N  Asha Rao
08545cf  N  Asha Rao
39f0449  N  Asha Rao
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-24-2-spoofed-author/05-push -->
```text
$ git push
To ../../server/inference-gateway.git
   39f0449..8cbd8fd  main -> main
$ cd ../../asha/inference-gateway
$ git pull -q
$ git shortlog -sne HEAD
     3	Asha Rao <asha@example.com>
     3	Lab User <you@example.com>
$ git log -2 --format='%h  %an <%ae>  %s'
8cbd8fd  Asha Rao <asha@example.com>  Raise the rate limit again
08545cf  Asha Rao <asha@example.com>  Raise the rate limit
```
<!-- /snippet -->

Asha's genuine commit `39f0449` was made by the setup script and matches your sandbox. Your two forgeries have other IDs than the ones printed, because they carry the real time.

### What happened internally

- `--author` replaced the `author` line of one commit; the `committer` line still came from your configuration. This is the legitimate way to record somebody else's patch, and it leaves a trace: two different names.
- `-c user.name=... -c user.email=...` replaced the identity for one invocation, so both lines name Asha. The resulting object has the same kinds of lines, in the same format, as her genuine commit. No field records which machine, account or key produced it.
- `%G?` is `N` for all three commits: none is signed, so Git has no evidence about any of them.
- `git push` sent the objects and moved `refs/heads/main` on the server. Plain Git has no rule that connects the pusher with the committer line; the server stored the commits as they are.
- Asha's `git shortlog` now attributes three commits to her. Two of them she has never seen.

### Checkpoint

- `git log -3 --format='%an'` in either clone prints `Asha Rao` three times.
- The `author` and `committer` lines of your second forgery differ from those of her genuine commit only in the timestamps.

### Failure scenario

The team reacts: "everyone signs from now on". Keys are created, an allowed-signers file lists both people, and each clone includes a shared settings file. (Volatile from here: keys, signatures and the IDs of signed commits differ on every run.)

```bash
cd ../..
unset SSH_AUTH_SOCK
mkdir keys
ssh-keygen -q -t ed25519 -N '' -C 'you@example.com' -f keys/you
ssh-keygen -q -t ed25519 -N '' -C 'asha@example.com' -f keys/asha
printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 keys/you.pub)" > allowed_signers
printf 'asha@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 keys/asha.pub)" >> allowed_signers
cut -d" " -f1-3 allowed_signers
printf '[gpg]\n\tformat = ssh\n[gpg "ssh"]\n\tallowedSignersFile = %s/allowed_signers\n[commit]\n\tgpgSign = true\n' "$PWD" > team-signing.inc
for p in you asha; do git -C $p/inference-gateway config set include.path "$PWD/team-signing.inc"; git -C $p/inference-gateway config set user.signingKey "$PWD/keys/$p.pub"; done
```

<!-- snippet: ch14b/lab-24-2-spoofed-author-volatile/01-keys -->
```text
$ unset SSH_AUTH_SOCK
$ mkdir keys
$ ssh-keygen -q -t ed25519 -N '' -C 'you@example.com' -f keys/you
$ ssh-keygen -q -t ed25519 -N '' -C 'asha@example.com' -f keys/asha
$ printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 keys/you.pub)" > allowed_signers
$ printf 'asha@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 keys/asha.pub)" >> allowed_signers
$ cut -d" " -f1-3 allowed_signers
you@example.com namespaces="git" ssh-ed25519
asha@example.com namespaces="git" ssh-ed25519
```
<!-- /snippet -->

Asha makes a genuine, signed commit:

```bash
cd asha/inference-gateway
printf 'def ready():\n    return True\n' > gateway/ready.py
git add gateway/ready.py
git commit -q -m "Add readiness endpoint"
git push -q
git log -1 --format='%h  %G?  author=%ae  signer=%GS  %s'
```

<!-- snippet: ch14b/lab-24-2-spoofed-author-volatile/02-team-signs -->
```text
# Shared signing settings in one file that each clone includes; the key is per person.
$ printf '[gpg]\n\tformat = ssh\n[gpg "ssh"]\n\tallowedSignersFile = %s/allowed_signers\n[commit]\n\tgpgSign = true\n' "$PWD" > team-signing.inc
$ for p in you asha; do git -C $p/inference-gateway config set include.path "$PWD/team-signing.inc"; git -C $p/inference-gateway config set user.signingKey "$PWD/keys/$p.pub"; done
$ cd asha/inference-gateway
$ printf 'def ready():\n    return True\n' > gateway/ready.py
$ git add gateway/ready.py
$ git commit -q -m "Add readiness endpoint"
$ git push -q
$ git log -1 --format='%h  %G?  author=%ae  signer=%GS  %s'
2c72086  G  author=asha@example.com  signer=asha@example.com  Add readiness endpoint
```
<!-- /snippet -->

Now you forge again. You do not have Asha's private key, so you cannot sign as her. Your own configuration signs for you:

```bash
cd ../../you/inference-gateway
git pull -q
printf 'requests_per_minute: 600000\n' > config/limits.yaml
git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Remove the rate limit in practice"
git verify-commit HEAD
git log -4 --format='%h  %G?  author=%ae  signer=%GS  %s'
```

<!-- snippet: ch14b/lab-24-2-spoofed-author-volatile/03-failure -->
```text
# Back in your clone. You still cannot sign as Asha, but you can sign as yourself.
$ cd ../../you/inference-gateway
$ git pull -q
$ printf 'requests_per_minute: 600000\n' > config/limits.yaml
$ git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Remove the rate limit in practice"
$ git verify-commit HEAD
Good "git" signature for you@example.com with ED25519 key SHA256:mC+mxkrNRStf64Pbapbbo8F52npbH9yS7JyhLszNJLo
[exit status: 0]
$ git log -4 --format='%h  %G?  author=%ae  signer=%GS  %s'
1d8b72e  G  author=asha@example.com  signer=you@example.com  Remove the rate limit in practice
2c72086  G  author=asha@example.com  signer=asha@example.com  Add readiness endpoint
bd16587  N  author=asha@example.com  signer=  Raise the rate limit again
00a76c4  N  author=asha@example.com  signer=  Raise the rate limit
```
<!-- /snippet -->

`git verify-commit` reports a good signature and exits with 0. The commit claims Asha as author and committer and is signed by *your* key. "Everyone signs" did not stop the forgery; it produced a forgery with a green check.

### Recovery

First, make the missing comparison: a commit passes only if it has a good signature *and* the signer is the author.

```bash
git log -4 --format='%h %G? %ae %GS' | awk '{ ok = ($2 == "G" && $3 == $4) ? "ok  " : "FAIL"; print ok, $0 }'
```

<!-- snippet: ch14b/lab-24-2-spoofed-author-volatile/04-policy-check -->
```text
$ git log -4 --format='%h %G? %ae %GS' | awk '{ ok = ($2 == "G" && $3 == $4) ? "ok  " : "FAIL"; print ok, $0 }'
FAIL 1d8b72e G asha@example.com you@example.com
ok   2c72086 G asha@example.com asha@example.com
FAIL bd16587 N asha@example.com 
FAIL 00a76c4 N asha@example.com 
```
<!-- /snippet -->

Second, do not mistake `git merge --verify-signatures` for that check:

```bash
git switch -q -c integration HEAD~3
git merge --verify-signatures --ff-only main~2
git merge --verify-signatures --ff-only main
git log -4 --format='%h  %G?  author=%ae  signer=%GS'
```

<!-- snippet: ch14b/lab-24-2-spoofed-author-volatile/05-merge-verify -->
```text
$ git switch -q -c integration HEAD~3
$ git merge --verify-signatures --ff-only main~2
fatal: Commit bd16587 does not have a GPG signature.
[exit status: 128]
$ git merge --verify-signatures --ff-only main
Commit 1d8b72e has a good GPG signature by you@example.com
Updating 00a76c4..1d8b72e
Fast-forward
 config/limits.yaml | 2 +-
 gateway/ready.py   | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)
 create mode 100644 gateway/ready.py
[exit status: 0]
$ git log -4 --format='%h  %G?  author=%ae  signer=%GS'
1d8b72e  G  author=asha@example.com  signer=you@example.com
2c72086  G  author=asha@example.com  signer=asha@example.com
bd16587  N  author=asha@example.com  signer=
00a76c4  N  author=asha@example.com  signer=
```
<!-- /snippet -->

It refused a tip without a signature and accepted a signed tip, bringing an unsigned commit and a forged one along. Third, undo the forged changes. They are published, so the history stays, and reverts say what happened:

```bash
git switch -q main
git branch -q -D integration
git revert --no-edit HEAD HEAD~2 HEAD~3
cat config/limits.yaml
git push -q
```

<!-- snippet: ch14b/lab-24-2-spoofed-author-volatile/06-recovery -->
```text
# Published history stays. The forged changes are undone by commits that say so, signed by you.
$ git switch -q main
$ git branch -q -D integration
$ git revert --no-edit HEAD HEAD~2 HEAD~3
[main 968a655] Revert "Remove the rate limit in practice"
 Date: Mon Sep 7 10:47:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
[main a9171c0] Revert "Raise the rate limit again"
 Date: Mon Sep 7 10:47:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
[main 379dbac] Revert "Raise the rate limit"
 Date: Mon Sep 7 10:47:00 2026 +0530
 1 file changed, 2 insertions(+), 1 deletion(-)
$ cat config/limits.yaml
requests_per_minute: 60
max_tokens: 2048
$ git push -q
```
<!-- /snippet -->

### Verification

```bash
git log -7 --format='%h %G? %ae %GS' | awk '{ ok = ($2 == "G" && $3 == $4) ? "ok  " : "FAIL"; print ok, $0 }'
git log -3 --format='%h  %an  %s'
```

<!-- snippet: ch14b/lab-24-2-spoofed-author-volatile/07-verify -->
```text
$ git log -7 --format='%h %G? %ae %GS' | awk '{ ok = ($2 == "G" && $3 == $4) ? "ok  " : "FAIL"; print ok, $0 }'
ok   379dbac G you@example.com you@example.com
ok   a9171c0 G you@example.com you@example.com
ok   968a655 G you@example.com you@example.com
FAIL 1d8b72e G asha@example.com you@example.com
ok   2c72086 G asha@example.com asha@example.com
FAIL bd16587 N asha@example.com 
FAIL 00a76c4 N asha@example.com 
$ git log -3 --format='%h  %an  %s'
379dbac  Lab User  Revert "Raise the rate limit"
a9171c0  Lab User  Revert "Raise the rate limit again"
968a655  Lab User  Revert "Remove the rate limit in practice"
```
<!-- /snippet -->

The three reverts are yours and say so. The three forgeries remain in history and fail the check, which is correct: they are evidence. `config/limits.yaml` is back to its released content.

### Questions

1. After step 3, which fields of your second forgery differ from the fields of a commit Asha would have made herself with the same content at the same second?
2. `--author` and `-c user.name=... -c user.email=...` both put Asha's name into a commit. Which of the two is an honest, everyday operation, and what distinguishes its result?
3. In the failure scenario, `git verify-commit HEAD` exited with 0 for a forged commit. State exactly what that command verified, and what it did not.
4. The policy check compared `%ae` with `%GS`. What must be true of the allowed-signers file for that comparison to mean anything? Who must control that file?
5. `git merge --verify-signatures --ff-only main` succeeded. Which commits did it check? What would a gate have to do to guarantee "every commit on `main` is signed by its author"?
6. The forged commits are still in the history after the recovery. Why were they reverted and not removed? Who, outside this repository, can say which account pushed them?
