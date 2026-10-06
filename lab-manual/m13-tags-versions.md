# Module 13 labs: Tags, versions, and release mechanics in Git

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch14b/`. Read [Chapter 14B: Configuration, Aliases, Tags and Signing](../textbook/ch14b-config-tags-signing.md), sections 14B.8 to 14B.14, first.

## How to run these labs

Each lab has a setup script that builds its starting state in the hands-on sandbox, and a replay script that ran the whole lab with a fixed clock and produced the transcripts below. From the course root:

```bash
bash labs/ch14b/setup-13-1-three-tags.sh       # build the starting state (run again to start over)
labs/shell m13-1                               # open the isolated lab shell in that sandbox
labs/run ch14b/lab-13-1-three-tags             # optional: replay the lab and print its transcript
```

**Which IDs will match the book.** The setup scripts create their commits and tags with the same fixed clock as the replays, so everything that exists when you enter a sandbox has the ID printed here. A commit or an annotated tag that you create yourself contains the real time and therefore gets another ID. A lightweight tag has no ID of its own.

**The lab clock.** Replays and setup scripts use a fixed clock in the past (7 September 2026), and the lab configuration sets `gc.reflogExpire` and `gc.reflogExpireUnreachable` to `never` (Git's defaults are 90 and 30 days; Chapter 1, section 1.7). No lab here runs `git gc`, so nothing expires.

Differences between your terminal and the transcripts:

- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command.
- Lines that start with `#` are notes from a script, not output of Git.
- `$LAB` is the lab root. The replays ran in `$LAB/ch14b/lab-13-<k>-...`; your sandbox is `$LAB/hands-on/m13-<k>`.
- Lab 13.1 has a second, *volatile* replay for its signed tag: it generates a fresh key on every run, so its key fingerprint, signature and tag ID differ each time, and yours will differ too.

| Lab | Topic | Sandbox | Replay |
|---|---|---|---|
| 13.1 | Three kinds of tag | `m13-1` | `ch14b/lab-13-1-three-tags`, `ch14b/lab-13-1-three-tags-volatile` |
| 13.2 | A moved tag between two clones | `m13-2` | `ch14b/lab-13-2-moved-tag` |
| 13.3 | Describe and versions | `m13-3` | `ch14b/lab-13-3-describe-versions` |

Answers to the Questions of every lab are in [solutions/m13-lab-answers.md](../solutions/m13-lab-answers.md). Write your own answers first.

## Lab 13.1: Three kinds of tag

### Objective

Create a lightweight, an annotated and a signed tag, and show at the object level what each one is: which refs and which objects exist, and what each ref points at. Then tag the wrong commit, and move the tag while that is still allowed.

### Prerequisites

- Chapter 14B, sections 14B.8 and 14B.16.
- Chapter 7, section 7.11 (lightweight tags as refs), and Chapter 3 for `git cat-file`.

### Setup

```bash
bash labs/ch14b/setup-13-1-three-tags.sh
labs/shell m13-1
```

The sandbox contains the repository `inference-gateway` with three commits and no tags.

### Commands

Step 1. A lightweight tag. Predict the type that `git cat-file -t` prints.

```bash
cd inference-gateway
git log --oneline
git tag staging-ok
cat .git/refs/tags/staging-ok
git cat-file -t staging-ok
```

Step 2. An annotated tag. Predict what the ref file contains now.

```bash
git tag -a v1.0.0 -m "inference-gateway 1.0.0" -m "First release with rate limits."
cat .git/refs/tags/v1.0.0
git cat-file -t v1.0.0
git cat-file -p v1.0.0
```

Step 3. Peel the tag, and compare the two tags as refs.

```bash
git rev-parse v1.0.0 'v1.0.0^{commit}' 'v1.0.0^{tree}'
git show-ref --tags --dereference
git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(objectname:short) -> %(*objecttype) %(*objectname:short)'
git describe
git describe --tags
```

Step 4. A signed tag, on the commit before the release. The key is created inside the sandbox, without a passphrase, and `SSH_AUTH_SOCK` is unset in this shell so that `ssh-keygen` cannot consult an agent. The settings go into this repository's own configuration.

```bash
unset SSH_AUTH_SOCK
mkdir ../keys
ssh-keygen -q -t ed25519 -N '' -C 'release signing key (lab)' -f ../keys/release_key
git config set gpg.format ssh
git config set user.signingKey "$PWD/../keys/release_key.pub"
git tag -s v0.9.0 -m "inference-gateway 0.9.0 (preview)" HEAD~1
git cat-file -t v0.9.0
git cat-file -p v0.9.0
```

Step 5. Verify it. The first attempt fails for a reason worth reading.

```bash
git verify-tag v0.9.0
printf 'release@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ../keys/release_key.pub)" > ../allowed_signers
git config set gpg.ssh.allowedSignersFile "$PWD/../allowed_signers"
git verify-tag v0.9.0
git verify-tag v1.0.0
```

Step 6. The three kinds side by side.

```bash
for t in staging-ok v1.0.0 v0.9.0; do printf "%-11s %-7s signature blocks: " $t $(git cat-file -t $t); git cat-file -p $t | grep -c "BEGIN SSH SIGNATURE"; done
git tag -v v0.9.0
```

### Expected output

Steps 1 to 3 (deterministic):

<!-- snippet: ch14b/lab-13-1-three-tags/01-lightweight -->
```text
$ cd inference-gateway
$ git log --oneline
eb112a5 Add rate limits
516c4c3 Add model router
37da450 Add README
$ git tag staging-ok
$ cat .git/refs/tags/staging-ok
eb112a5c44b0b2092c4ef2cae6e75b16da000f73
$ git cat-file -t staging-ok
commit
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-1-three-tags/02-annotated -->
```text
$ git tag -a v1.0.0 -m "inference-gateway 1.0.0" -m "First release with rate limits."
$ cat .git/refs/tags/v1.0.0
b69624883fa40e51cbbf4c4baf49365ba1caa02e
$ git cat-file -t v1.0.0
tag
$ git cat-file -p v1.0.0
object eb112a5c44b0b2092c4ef2cae6e75b16da000f73
type commit
tag v1.0.0
tagger Lab User <you@example.com> 1788756060 +0530

inference-gateway 1.0.0

First release with rate limits.
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-1-three-tags/03-peel -->
```text
$ git rev-parse v1.0.0 'v1.0.0^{commit}' 'v1.0.0^{tree}'
b69624883fa40e51cbbf4c4baf49365ba1caa02e
eb112a5c44b0b2092c4ef2cae6e75b16da000f73
406c0291b052f665e4581982583c94937f169d80
$ git show-ref --tags --dereference
eb112a5c44b0b2092c4ef2cae6e75b16da000f73 refs/tags/staging-ok
b69624883fa40e51cbbf4c4baf49365ba1caa02e refs/tags/v1.0.0
eb112a5c44b0b2092c4ef2cae6e75b16da000f73 refs/tags/v1.0.0^{}
$ git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(objectname:short) -> %(*objecttype) %(*objectname:short)'
staging-ok commit eb112a5 ->  
v1.0.0 tag b696248 -> commit eb112a5
$ git describe
v1.0.0
$ git describe --tags
v1.0.0
```
<!-- /snippet -->

Your tag object has another ID than the one printed here, because its `tagger` line contains the real time. The commit and tree IDs match.

Steps 4 to 6 (volatile: the key, the signature and the ID of the signed tag differ on every run):

<!-- snippet: ch14b/lab-13-1-three-tags-volatile/01-key -->
```text
$ unset SSH_AUTH_SOCK
$ mkdir ../keys
$ ssh-keygen -q -t ed25519 -N '' -C 'release signing key (lab)' -f ../keys/release_key
$ git config set gpg.format ssh
$ git config set user.signingKey "$PWD/../keys/release_key.pub"
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-1-three-tags-volatile/02-signed-tag -->
```text
$ git tag -s v0.9.0 -m "inference-gateway 0.9.0 (preview)" HEAD~1
$ git cat-file -t v0.9.0
tag
$ git cat-file -p v0.9.0
object 516c4c33925ffe289283884822624368051acf49
type commit
tag v0.9.0
tagger Lab User <you@example.com> 1788756180 +0530

inference-gateway 0.9.0 (preview)
-----BEGIN SSH SIGNATURE-----
U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgFUyGXgs/GVUkIguqKUfT7HMQVS
xog+viHRI0oJiWZjoAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
AAAAQL6w98YpCsjqRUhbUiRjo+G1As4F9n+9ZgpcPxT08gbcJchWB9R4oEsls0mgPHjWeD
uRxK/0YMUAivkprZlGKgg=
-----END SSH SIGNATURE-----
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-1-three-tags-volatile/03-verify -->
```text
$ git verify-tag v0.9.0
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
[exit status: 1]
$ printf 'release@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ../keys/release_key.pub)" > ../allowed_signers
$ git config set gpg.ssh.allowedSignersFile "$PWD/../allowed_signers"
$ git verify-tag v0.9.0
Good "git" signature for release@example.com with ED25519 key SHA256:f/9PtgYgWnMweCs1ZhqX6glhCEupKpCUOmCPr+8RKLQ
[exit status: 0]
$ git verify-tag v1.0.0
error: no signature found
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-1-three-tags-volatile/04-three-kinds -->
```text
$ for t in staging-ok v1.0.0 v0.9.0; do printf "%-11s %-7s signature blocks: " $t $(git cat-file -t $t); git cat-file -p $t | grep -c "BEGIN SSH SIGNATURE"; done
staging-ok  commit  signature blocks: 0
v1.0.0      tag     signature blocks: 0
v0.9.0      tag     signature blocks: 1
$ git tag -v v0.9.0
Good "git" signature for release@example.com with ED25519 key SHA256:f/9PtgYgWnMweCs1ZhqX6glhCEupKpCUOmCPr+8RKLQ
object 516c4c33925ffe289283884822624368051acf49
type commit
tag v0.9.0
tagger Lab User <you@example.com> 1788756180 +0530

inference-gateway 0.9.0 (preview)
```
<!-- /snippet -->

### What happened internally

- `git tag staging-ok` wrote one file, `.git/refs/tags/staging-ok`, containing the ID of the commit. No object was created.
- `git tag -a v1.0.0` wrote a tag object (lines `object`, `type`, `tag`, `tagger`, then the message) and a ref file containing the ID of *that object*. `v1.0.0^{commit}` follows the `object` line to the commit; `git show-ref --dereference` prints the peeled ID on a second line ending in `^{}`.
- `git describe` printed `v1.0.0` both with and without `--tags`: for an exact match Git prefers the annotated tag over the lightweight one on the same commit.
- `git tag -s v0.9.0 ... HEAD~1` built the same kind of tag object, handed its text to `ssh-keygen -Y sign`, and appended the signature block to the message. The object type is still `tag`.
- The first `git verify-tag` failed without checking anything: no allowed-signers file was configured. After you created one, the same object verified. `v1.0.0` reports "no signature found": it is annotated, not signed.
- No reflog was written for any tag, and HEAD, the index and the working tree were never involved.

### Checkpoint

- `git cat-file -t staging-ok` prints `commit`; for `v1.0.0` and `v0.9.0` it prints `tag`.
- `git rev-parse 'v1.0.0^{commit}' staging-ok` prints the same ID twice.
- `git verify-tag v0.9.0` exits with 0; `git verify-tag v1.0.0` exits with 1.

### Failure scenario

The next release is tagged in a hurry. The tip of `main` is unfinished work, and the tag lands on it:

```bash
printf 'burst: 20\n' >> config/limits.yaml
git commit -q -am "Allow short bursts"
printf 'experimental: true\n' >> config/limits.yaml
git commit -q -am "WIP: experiment flag"
git tag -a v1.1.0 -m "inference-gateway 1.1.0"
git log --oneline --decorate -3
```

<!-- snippet: ch14b/lab-13-1-three-tags/04-failure -->
```text
# The next release is tagged in a hurry, one commit too far: the tip is unfinished work.
$ printf 'burst: 20\n' >> config/limits.yaml
$ git commit -q -am "Allow short bursts"
$ printf 'experimental: true\n' >> config/limits.yaml
$ git commit -q -am "WIP: experiment flag"
$ git tag -a v1.1.0 -m "inference-gateway 1.1.0"
$ git log --oneline --decorate -3
e30f488 (HEAD -> main, tag: v1.1.0) WIP: experiment flag
43b0eff Allow short bursts
eb112a5 (tag: v1.0.0, tag: staging-ok) Add rate limits
```
<!-- /snippet -->

`v1.1.0` names the WIP commit. (In the replay, an annotated tag stands in for your signed `v0.9.0`; the listings are the same.)

### Recovery

The tag has not been pushed, so nobody else can have it, and replacing it is legitimate. Write down the ID of the tag object first: tags have no reflog.

```bash
git rev-parse --short v1.1.0
git tag -a v1.1.0 -m "inference-gateway 1.1.0" HEAD~1
git tag -f -a v1.1.0 -m "inference-gateway 1.1.0" HEAD~1
git log --oneline --decorate -3
```

<!-- snippet: ch14b/lab-13-1-three-tags/05-recovery -->
```text
# The tag was never pushed, so it may be replaced. Note the old tag object ID first.
$ git rev-parse --short v1.1.0
e9a5be7
$ git tag -a v1.1.0 -m "inference-gateway 1.1.0" HEAD~1
fatal: tag 'v1.1.0' already exists
[exit status: 128]
$ git tag -f -a v1.1.0 -m "inference-gateway 1.1.0" HEAD~1
Updated tag 'v1.1.0' (was e9a5be7)
$ git log --oneline --decorate -3
e30f488 (HEAD -> main) WIP: experiment flag
43b0eff (tag: v1.1.0) Allow short bursts
eb112a5 (tag: v1.0.0, tag: staging-ok) Add rate limits
```
<!-- /snippet -->

Without `-f` Git refuses. With it, Git prints the ID the tag had before, which is your only record of the old tag object.

### Verification

```bash
git tag -n1
git rev-parse --short 'v1.1.0^{commit}' && git rev-parse --short HEAD~1
git fsck --no-reflogs
git reflog show refs/tags/v1.1.0
```

<!-- snippet: ch14b/lab-13-1-three-tags/06-verify -->
```text
$ git tag -n1
staging-ok      Add rate limits
v0.9.0          inference-gateway 0.9.0 (preview)
v1.0.0          inference-gateway 1.0.0
v1.1.0          inference-gateway 1.1.0
$ git rev-parse --short 'v1.1.0^{commit}' && git rev-parse --short HEAD~1
43b0eff
43b0eff
$ git fsck --no-reflogs
dangling tag e9a5be7e3bba7474db9dba0801692ac1fd8fc948
$ git reflog show refs/tags/v1.1.0
[exit status: 0]
```
<!-- /snippet -->

The tag is on the right commit. The replaced tag object still exists as a dangling object, and the reflog command prints nothing.

### Questions

1. After step 2, how many refs and how many objects had the two tags added to the repository, in total?
2. `cat .git/refs/tags/v1.0.0` did not print the commit ID. What did it print, and which two commands in the lab turn it into the commit ID?
3. The signed tag and the annotated tag are both of type `tag`. What exactly is different between the two objects, and what did Git need from you before it would call the signature "Good"?
4. In the recovery, why was it acceptable to use `git tag -f`? State the condition precisely, and say what you would have done if the condition had not held.
5. `git fsck --no-reflogs` reported a dangling tag. What is it, why does `git reflog` not know about it, and how long can you count on it being there?

## Lab 13.2: A moved tag between two clones

### Objective

Reproduce the incident in which a published release tag is moved: watch three clones disagree about what `v1.2.0` is, detect the disagreement from any of them, see why the popular quick fix makes things worse, find the original tag object again without a reflog, and repair the release properly.

### Prerequisites

- Chapter 14B, sections 14B.10 and 14B.11.
- Chapter 12, section 12.4, for how `git fetch` treats tags.

### Setup

```bash
bash labs/ch14b/setup-13-2-moved-tag.sh
labs/shell m13-2
```

The sandbox contains a bare repository `server/inference-gateway.git` and two clones, `you/inference-gateway` and `asha/inference-gateway`. The annotated tag `v1.2.0` is on the server and in both clones. In Asha's clone, `user.name` and `user.email` are set locally, so commands you run there act as Asha.

### Commands

Step 1. The published state, seen from your clone, from the server and from Asha's clone.

```bash
cd you/inference-gateway
git log --oneline --decorate
git ls-remote --tags origin
git -C ../../asha/inference-gateway show-ref --tags --dereference
```

Step 2. A bug is fixed on `main`, and you "correct" the release by moving the tag. Notice each refusal.

```bash
printf 'requests_per_minute: 60\nmax_tokens: 4096\n' > config/limits.yaml
git commit -q -am "Fix max_tokens limit"
git push -q
git tag -f -a v1.2.0 -m "inference-gateway 1.2.0"
git push origin v1.2.0
git push --force origin v1.2.0
```

Step 3. Asha updates. Predict where her `v1.2.0` is afterwards.

```bash
cd ../../asha/inference-gateway
git pull -q
git log --oneline --decorate -2
git show v1.2.0:config/limits.yaml
```

Step 4. A build machine clones now.

```bash
cd ../..
git clone -q server/inference-gateway.git ci/inference-gateway
git -C ci/inference-gateway log --oneline --decorate -2
git -C ci/inference-gateway show v1.2.0:config/limits.yaml
```

Step 5. Detect the disagreement from Asha's clone.

```bash
cd asha/inference-gateway
git ls-remote origin 'refs/tags/v1.2.0^{}'
git rev-parse 'v1.2.0^{commit}'
git fetch --tags
```

### Expected output

<!-- snippet: ch14b/lab-13-2-moved-tag/01-published -->
```text
$ cd you/inference-gateway
$ git log --oneline --decorate
d20ef7a (HEAD -> main, tag: v1.2.0, origin/main, origin/HEAD) Add rate limits
73c05d1 Add model router
dfbc830 Add README
$ git ls-remote --tags origin
5b231b5f068120dabb9fbf2ab18bb2c3ea07ded5	refs/tags/v1.2.0
d20ef7a61e04035281b8b38ed0d78ee612252220	refs/tags/v1.2.0^{}
$ git -C ../../asha/inference-gateway show-ref --tags --dereference
5b231b5f068120dabb9fbf2ab18bb2c3ea07ded5 refs/tags/v1.2.0
d20ef7a61e04035281b8b38ed0d78ee612252220 refs/tags/v1.2.0^{}
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-2-moved-tag/02-move -->
```text
$ printf 'requests_per_minute: 60\nmax_tokens: 4096\n' > config/limits.yaml
$ git commit -q -am "Fix max_tokens limit"
$ git push -q
$ git tag -f -a v1.2.0 -m "inference-gateway 1.2.0"
Updated tag 'v1.2.0' (was 5b231b5)
$ git push origin v1.2.0
To ../../server/inference-gateway.git
 ! [rejected]        v1.2.0 -> v1.2.0 (already exists)
error: failed to push some refs to '../../server/inference-gateway.git'
hint: Updates were rejected because the tag already exists in the remote.
[exit status: 1]
$ git push --force origin v1.2.0
To ../../server/inference-gateway.git
 + 5b231b5...7a2a5f1 v1.2.0 -> v1.2.0 (forced update)
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-2-moved-tag/03-asha -->
```text
$ cd ../../asha/inference-gateway
$ git pull -q
$ git log --oneline --decorate -2
2d3e2a0 (HEAD -> main, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a (tag: v1.2.0) Add rate limits
$ git show v1.2.0:config/limits.yaml
requests_per_minute: 60
max_tokens: 2048
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-2-moved-tag/04-fresh-clone -->
```text
$ cd ../..
$ git clone -q server/inference-gateway.git ci/inference-gateway
$ git -C ci/inference-gateway log --oneline --decorate -2
2d3e2a0 (HEAD -> main, tag: v1.2.0, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a Add rate limits
$ git -C ci/inference-gateway show v1.2.0:config/limits.yaml
requests_per_minute: 60
max_tokens: 4096
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-2-moved-tag/05-detect -->
```text
$ cd asha/inference-gateway
$ git ls-remote origin 'refs/tags/v1.2.0^{}'
2d3e2a0e948978b7cda3b12f797c3ac2f554def0	refs/tags/v1.2.0^{}
$ git rev-parse 'v1.2.0^{commit}'
d20ef7a61e04035281b8b38ed0d78ee612252220
$ git fetch --tags
From ../../server/inference-gateway
 ! [rejected] v1.2.0     -> v1.2.0  (would clobber existing tag)
[exit status: 1]
```
<!-- /snippet -->

The commit `d20ef7a` and the original tag object `5b231b5` were made by the setup script and match your sandbox. The fix commit and the moved tag object are yours and have other IDs.

### What happened internally

- `git tag -f -a v1.2.0` created a *new* tag object that names the fix commit and rewrote your `refs/tags/v1.2.0`. The old tag object `5b231b5` stayed in your object database with nothing pointing at it.
- `git push origin v1.2.0` was rejected by your own Git: the server already has a ref of that name with another value, and tags are not updated without force. `git push --force` told the server to replace its ref.
- Asha's `git pull` fetched `main` and fast-forwarded. It did not touch `refs/tags/v1.2.0`: a fetch creates tags you lack and never changes one you have. Her tag still names the original tag object and, through it, `d20ef7a`.
- The fresh clone copied the server's refs as they are now, so its `v1.2.0` names the fix commit.
- `git ls-remote origin 'refs/tags/v1.2.0^{}'` asked the server for the peeled value of the tag; `git rev-parse 'v1.2.0^{commit}'` is the same question asked locally. Two answers, one name. `git fetch --tags` asks for all tags explicitly and therefore notices: "would clobber existing tag".

### Checkpoint

- In Asha's clone `git show v1.2.0:config/limits.yaml` prints `max_tokens: 2048`; in the `ci` clone it prints `max_tokens: 4096`.
- `git fetch --tags` in Asha's clone exits with status 1.

### Failure scenario

Somebody posts the "fix" in the team chat: force the tags. Asha runs it:

```bash
git fetch --tags --force
git log --oneline --decorate -2
git reflog show refs/tags/v1.2.0
```

<!-- snippet: ch14b/lab-13-2-moved-tag/06-failure -->
```text
# The quick "fix" that gets passed around in chat: force the tags.
$ git fetch --tags --force
From ../../server/inference-gateway
 t [tag update]      v1.2.0     -> v1.2.0
$ git log --oneline --decorate -2
2d3e2a0 (HEAD -> main, tag: v1.2.0, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a Add rate limits
$ git reflog show refs/tags/v1.2.0
[exit status: 0]
```
<!-- /snippet -->

Now all three clones agree, on the *wrong* tag: `v1.2.0` everywhere names code that was never released as 1.2.0. And Asha's clone was the last place where the original tag was still a ref. The reflog command prints nothing: tags have no reflog.

### Recovery

The original tag object was not deleted; it lost its name. `git fsck` lists objects that nothing refers to:

```bash
git fsck --no-reflogs
git fsck --no-reflogs | sed -n "s/^dangling tag //p" > ../../original-tag-id
git cat-file -p "$(cat ../../original-tag-id)"
```

<!-- snippet: ch14b/lab-13-2-moved-tag/07-find-the-original -->
```text
# No reflog for a tag. But the old tag object is still in this clone, unreferenced.
$ git fsck --no-reflogs
dangling tag 5b231b5f068120dabb9fbf2ab18bb2c3ea07ded5
$ git fsck --no-reflogs | sed -n "s/^dangling tag //p" > ../../original-tag-id
$ git cat-file -p "$(cat ../../original-tag-id)"
object d20ef7a61e04035281b8b38ed0d78ee612252220
type commit
tag v1.2.0
tagger Lab User <you@example.com> 1788756000 +0530

inference-gateway 1.2.0
```
<!-- /snippet -->

It is the tag object of the real 1.2.0: name `v1.2.0`, commit `d20ef7a`, the original tagger line. Put it back on the server, bring every clone in line, and release the fix under a new name:

```bash
git push --force origin "$(cat ../../original-tag-id):refs/tags/v1.2.0"
git fetch --tags --force
cd ../../you/inference-gateway
git fetch --tags --force
git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"
git push origin v1.2.1
git -C ../../ci/inference-gateway fetch -q --tags --force
git -C ../../asha/inference-gateway fetch -q
```

<!-- snippet: ch14b/lab-13-2-moved-tag/08-recovery -->
```text
$ git push --force origin "$(cat ../../original-tag-id):refs/tags/v1.2.0"
To ../../server/inference-gateway.git
 + 7a2a5f1...5b231b5 5b231b5f068120dabb9fbf2ab18bb2c3ea07ded5 -> v1.2.0 (forced update)
$ git fetch --tags --force
From ../../server/inference-gateway
 t [tag update]      v1.2.0     -> v1.2.0
$ cd ../../you/inference-gateway
$ git fetch --tags --force
From ../../server/inference-gateway
 t [tag update]      v1.2.0     -> v1.2.0
$ git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"
$ git push origin v1.2.1
To ../../server/inference-gateway.git
 * [new tag]         v1.2.1 -> v1.2.1
$ git -C ../../ci/inference-gateway fetch -q --tags --force
$ git -C ../../asha/inference-gateway fetch -q
```
<!-- /snippet -->

The refspec `<object-id>:refs/tags/v1.2.0` pushes an object that has no local name to a named ref on the server. The two `--force` fetches are needed because each of those clones holds the moved tag and would otherwise keep it.

### Verification

```bash
git ls-remote --tags origin
cd ../..
for c in you asha ci; do echo "$c:"; git -C $c/inference-gateway show-ref --tags --dereference --abbrev | grep "{}"; done
git -C you/inference-gateway log --oneline --decorate -2
```

<!-- snippet: ch14b/lab-13-2-moved-tag/09-verify -->
```text
$ git ls-remote --tags origin
5b231b5f068120dabb9fbf2ab18bb2c3ea07ded5	refs/tags/v1.2.0
d20ef7a61e04035281b8b38ed0d78ee612252220	refs/tags/v1.2.0^{}
3875c516e0a71a7706aee67cee20b5e66f5d66b5	refs/tags/v1.2.1
2d3e2a0e948978b7cda3b12f797c3ac2f554def0	refs/tags/v1.2.1^{}
$ cd ../..
$ for c in you asha ci; do echo "$c:"; git -C $c/inference-gateway show-ref --tags --dereference --abbrev | grep "{}"; done
you:
d20ef7a refs/tags/v1.2.0^{}
2d3e2a0 refs/tags/v1.2.1^{}
asha:
d20ef7a refs/tags/v1.2.0^{}
2d3e2a0 refs/tags/v1.2.1^{}
ci:
d20ef7a refs/tags/v1.2.0^{}
2d3e2a0 refs/tags/v1.2.1^{}
$ git -C you/inference-gateway log --oneline --decorate -2
2d3e2a0 (HEAD -> main, tag: v1.2.1, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a (tag: v1.2.0) Add rate limits
```
<!-- /snippet -->

The server and all three clones agree: `v1.2.0` peels to `d20ef7a`, and `v1.2.1` to the fix commit.

### Questions

1. After step 2, list the value of `refs/tags/v1.2.0` (as "original tag object" or "moved tag object") in each of the four repositories: server, yours, Asha's, and the `ci` clone made in step 4.
2. Asha ran `git pull` and got the fix on `main`, but her tag did not move. Which rule of `git fetch` is responsible, and why is that rule a protection and not a defect?
3. In the failure scenario the clones ended up consistent. Why is that state worse than the inconsistent one before it?
4. The recovery found the original tag with `git fsck`. Name two other places where its ID could have been found, and one circumstance under which `git fsck` would have found nothing.
5. Which server-side control would have stopped this incident at step 2? Would `receive.denyNonFastForwards` on a plain Git server have been enough? (Chapter 14B, section 14B.11.)

## Lab 13.3: Describe and versions

### Objective

Derive version strings from history with `git describe`, cut a release branch from a tag, backport a fix and publish a patch release, and explain what `git describe` says on each line of development. Then meet the checkout in which `git describe` has nothing to go on, and repair it.

### Prerequisites

- Chapter 14B, sections 14B.9 and 14B.12 to 14B.14.
- Chapter 10 for `git cherry-pick -x` and `git cherry`.

### Setup

```bash
bash labs/ch14b/setup-13-3-describe-versions.sh
labs/shell m13-3
```

The sandbox contains the repository `inference-gateway`: the annotated tag `v1.2.0` on the third commit, three more commits on `main` (the middle one is a bug fix), and a lightweight tag `on-staging`.

### Commands

Step 1. Describe the tip. Before each command, predict the output.

```bash
cd inference-gateway
git log --oneline --decorate
git describe
git describe --tags
git describe --long v1.2.0
git describe --abbrev=0
git log --oneline "$(git describe --abbrev=0)..HEAD"
```

Step 2. A modified working tree.

```bash
printf '# local hack\n' >> gateway/batch.py
git describe --dirty
git restore gateway/batch.py
git describe --dirty
```

Step 3. A release branch from the tag, the fix copied onto it, and a patch release.

```bash
git switch -c release/1.2 v1.2.0
git cherry-pick -x main~1
git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"
git log --graph --oneline --decorate --all
```

Step 4. What each line says about itself.

```bash
git describe release/1.2
git describe main
git tag --merged main
git cherry -v release/1.2 main
```

Step 5. The next minor release, with a release candidate first, and the order of the tags.

```bash
git switch -q main
git tag -a v1.3.0-rc.1 -m "inference-gateway 1.3.0, release candidate 1"
git commit -q --allow-empty -m "Update changelog for 1.3.0"
git tag -a v1.3.0 -m "inference-gateway 1.3.0"
git tag --list "v*" --sort=version:refname
git -c versionsort.suffix=-rc tag --list "v*" --sort=version:refname
git commit -q --allow-empty -m "Start 1.4 development"
git describe
```

### Expected output

<!-- snippet: ch14b/lab-13-3-describe-versions/01-describe -->
```text
$ cd inference-gateway
$ git log --oneline --decorate
b520c09 (HEAD -> main) Add batch endpoint
362b359 (tag: on-staging) Fix max_tokens limit
27d1fb6 Add streaming responses
eb112a5 (tag: v1.2.0) Add rate limits
516c4c3 Add model router
37da450 Add README
$ git describe
v1.2.0-3-gb520c09
$ git describe --tags
on-staging-1-gb520c09
$ git describe --long v1.2.0
v1.2.0-0-geb112a5
$ git describe --abbrev=0
v1.2.0
$ git log --oneline "$(git describe --abbrev=0)..HEAD"
b520c09 Add batch endpoint
362b359 Fix max_tokens limit
27d1fb6 Add streaming responses
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-3-describe-versions/02-dirty -->
```text
$ printf '# local hack\n' >> gateway/batch.py
$ git describe --dirty
v1.2.0-3-gb520c09-dirty
$ git restore gateway/batch.py
$ git describe --dirty
v1.2.0-3-gb520c09
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-3-describe-versions/03-release-branch -->
```text
$ git switch -c release/1.2 v1.2.0
Switched to a new branch 'release/1.2'
$ git cherry-pick -x main~1
[release/1.2 f1d5273] Fix max_tokens limit
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"
$ git log --graph --oneline --decorate --all
* f1d5273 (HEAD -> release/1.2, tag: v1.2.1) Fix max_tokens limit
| * b520c09 (main) Add batch endpoint
| * 362b359 (tag: on-staging) Fix max_tokens limit
| * 27d1fb6 Add streaming responses
|/  
* eb112a5 (tag: v1.2.0) Add rate limits
* 516c4c3 Add model router
* 37da450 Add README
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-3-describe-versions/04-two-lines -->
```text
$ git describe release/1.2
v1.2.1
$ git describe main
v1.2.0-3-gb520c09
$ git tag --merged main
on-staging
v1.2.0
$ git cherry -v release/1.2 main
+ 27d1fb6a67cdb41e87d5771c3e10310823ee0dcb Add streaming responses
- 362b3592d29ea9c07389c0782fd46c24269b6a3f Fix max_tokens limit
+ b520c0914edcb3c22084a44676660b8f6f987bfb Add batch endpoint
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-13-3-describe-versions/05-next-minor -->
```text
$ git switch -q main
$ git tag -a v1.3.0-rc.1 -m "inference-gateway 1.3.0, release candidate 1"
$ git commit -q --allow-empty -m "Update changelog for 1.3.0"
$ git tag -a v1.3.0 -m "inference-gateway 1.3.0"
$ git tag --list "v*" --sort=version:refname
v1.2.0
v1.2.1
v1.3.0
v1.3.0-rc.1
$ git -c versionsort.suffix=-rc tag --list "v*" --sort=version:refname
v1.2.0
v1.2.1
v1.3.0-rc.1
v1.3.0
$ git commit -q --allow-empty -m "Start 1.4 development"
$ git describe
v1.3.0-1-g3196266
```
<!-- /snippet -->

Everything up to step 2 matches your sandbox exactly. From the cherry-pick on, the commits and tags you create have other IDs, so the `-g<id>` suffixes of your `git describe` output differ; the tag names and counts are the same.

### What happened internally

- `git describe` walked back from HEAD, found the annotated tag `v1.2.0` three commits away, and printed tag, count and abbreviated ID. With `--tags` the lightweight tag `on-staging`, one commit away, was nearer and won.
- `--dirty` compared the working tree with HEAD and appended `-dirty` while they differed. No ref or object changed.
- `git switch -c release/1.2 v1.2.0` created a branch ref at the commit the tag peels to. `git cherry-pick -x main~1` wrote a new commit on that branch with the same change, a new ID, and a line in its message naming the commit it was copied from.
- `git tag -a v1.2.1` wrote a tag object naming the copy. That tag is reachable from `release/1.2` only, so `git describe main` still counts from `v1.2.0` and `git tag --merged main` does not list `v1.2.1`.
- `git cherry -v release/1.2 main` compared the *changes*, not the IDs: `-` marks a commit of `main` whose change already exists on the release branch, `+` one that does not.
- `--sort=version:refname` compares numeric components as numbers; `versionsort.suffix=-rc` declares that a name with `-rc` sorts before the same name without it.

### Checkpoint

- `git describe release/1.2` prints `v1.2.1`.
- `git describe` on `main` prints `v1.3.0-1-g` followed by an abbreviated ID.
- The second tag listing ends with `v1.3.0-rc.1` and then `v1.3.0`.

### Failure scenario

A build machine checks the project out the cheap way, one commit and nothing else, and the build asks for its version:

```bash
cd ..
git clone -q --depth 1 "file://$PWD/inference-gateway" build
cd build
git log --oneline
git tag
git describe
git describe --always
```

<!-- snippet: ch14b/lab-13-3-describe-versions/06-failure -->
```text
# A build machine checks the project out the cheap way: one commit, no tags.
$ cd ..
$ git clone -q --depth 1 "file://$PWD/inference-gateway" build
$ cd build
$ git log --oneline
3196266 Start 1.4 development
$ git tag
$ git describe
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git describe --always
3196266
```
<!-- /snippet -->

One commit, no tags, and `git describe` fails. `--always` falls back to the bare commit ID, which is a name but not a version.

### Recovery

Turn the shallow clone into a complete one and ask again:

```bash
git rev-parse --is-shallow-repository
git fetch -q --unshallow
git rev-parse --is-shallow-repository
git describe
```

<!-- snippet: ch14b/lab-13-3-describe-versions/07-recovery -->
```text
$ git rev-parse --is-shallow-repository
true
$ git fetch -q --unshallow
$ git rev-parse --is-shallow-repository
false
$ git describe
v1.3.0-1-g3196266
```
<!-- /snippet -->

`git fetch --unshallow` fetched the missing history, and with it the tags that point into that history.

### Verification

```bash
git tag --list "v*" --sort=version:refname
git branch -r
git -C ../inference-gateway describe release/1.2
```

<!-- snippet: ch14b/lab-13-3-describe-versions/08-verify -->
```text
$ git tag --list "v*" --sort=version:refname
v1.2.0
v1.3.0
v1.3.0-rc.1
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git -C ../inference-gateway describe release/1.2
v1.2.1
```
<!-- /snippet -->

The build clone can describe `main`. It still has no `v1.2.1` and no `origin/release/1.2` (Question 5).

### Questions

1. Take the string that `git describe` printed in step 1 apart: what is each of its three components, and which other command in that step prints the middle one?
2. `git describe --tags` named `on-staging` and plain `git describe` did not. Why does Git make that distinction by default?
3. After step 3, 1.2.1 has been released, yet `git describe main` still starts with `v1.2.0`. Explain it from the commit graph. Is that a defect in the versioning of `main`?
4. In `git cherry -v release/1.2 main`, one line starts with `-`. What does it mean, and why can the question "is the fix in release 1.2?" not be answered with `git branch --contains` or `git tag --contains`?
5. After the recovery the build clone has `v1.2.0`, `v1.3.0-rc.1` and `v1.3.0` but not `v1.2.1`. Why? Which option of `git clone` caused it, and what would you fetch to get that tag?
6. Is `v1.3.0-1-g3196266` a valid Semantic Versioning 2.0.0 version of a build that comes *after* 1.3.0? Use the precedence rules to answer.
