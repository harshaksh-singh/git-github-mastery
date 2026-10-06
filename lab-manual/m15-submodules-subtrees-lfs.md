# Module 15 labs: Submodules, subtrees and Git LFS

> **Baseline.** Git 2.55.0 and git-lfs 3.7.1 on macOS. Every "Expected output" block is real output from a replay script in `labs/ch23/` (Labs 15.1 and 15.2) or `labs/ch22/` (Labs 15.3 and 15.4).

Labs 15.1 and 15.2 belong to [Chapter 23: Submodules and subtrees](../textbook/ch23-submodules.md). Labs 15.3 and 15.4 belong to [Chapter 22: Git LFS](../textbook/ch22-git-lfs.md). The general rules for labs are in the [lab manual README](README.md).

## How the labs of this module work

Each lab has a setup script, which builds the starting state for you to work in by hand, and one or two replay scripts, which run the whole lab and print the transcript:

```bash
bash labs/ch23/setup-15-1-submodule-breaks.sh    # builds the starting repositories for Lab 15.1
labs/shell m15-1                                 # opens the isolated lab shell in that sandbox
cd doc-qa                                        # the setup script prints this line for you
```

```bash
labs/run ch23/lab-15-1-submodule-breaks          # replays the whole lab and prints the transcript
```

Four things hold for all four labs.

- **Everything is local.** The "servers" are bare repositories in the directory `remotes/` of the sandbox, reached through a file path. Nothing in this module talks to GitHub.
- **Commit IDs.** Commits that exist when you enter a sandbox have the IDs printed here, because the setup scripts pin the clock. Commits that you create get other IDs, with one exception that Lab 15.4 explains.
- **You play two people.** Ravi's clone is a second directory in the same sandbox. You `cd` into it and type his commands; the author name stays yours, which does not matter for these labs.
- **Lines such as `[exit status: 128]`** are printed by the replay. By hand, run `echo $?` after the command.

Two replays are marked volatile by `labs/verify-all.sh`, which means that their output is allowed to differ between runs, and each lab says in which lines.

## Lab 15.1: A submodule that breaks for a teammate

### Objective

Change a library that your service uses as a submodule, publish the change correctly once, then publish it incorrectly, and investigate the failure from the teammate's side: read the error, prove where the missing commit is, repair it, and install the guard that refuses the mistake.

### Prerequisites

Chapter 23, sections 23.2 to 23.8. You should be able to say what a gitlink is and why a submodule's HEAD is detached after `git submodule update`.

### Setup

```bash
bash labs/ch23/setup-15-1-submodule-breaks.sh
labs/shell m15-1
cd doc-qa
```

The sandbox holds two shared repositories, `remotes/doc-qa.git` (a document question-answering service) and `remotes/textsplit.git` (a text-chunking library), and three clones: `doc-qa` is yours, `ravi-doc-qa` is Ravi's, `asha-textsplit` belongs to the library's maintainer. `doc-qa` uses the library as a submodule at `vendor/textsplit`. Both clones of the service are in sync with the remote.

### Commands

Look at the three parts of the submodule, and at the state of the library checkout:

```bash
cat .gitmodules
git ls-tree HEAD vendor/
git submodule status
git -C vendor/textsplit status --short --branch
```

Before you go on, write down two predictions. When you commit inside `vendor/textsplit`, what will `git status --short` say in `doc-qa`? And if you then push `doc-qa` only, at which command will Ravi notice, and with what kind of message?

Change the library inside the submodule. Append this function to `vendor/textsplit/splitter.py`, after two empty lines:

```text
def split_lines(text):
    """One chunk per non-empty line."""
    return [line for line in text.splitlines() if line.strip()]
```

```bash
cd vendor/textsplit
git switch main
# edit splitter.py as described
git commit -am "Add line splitter"
cd ../..
```

Record the new library commit in the service, and publish both repositories with one command:

```bash
git status --short
git diff --submodule=log
git commit -am "Use the line splitter from textsplit"
git push --recurse-submodules=on-demand origin main
```

Now be Ravi:

```bash
cd ../ravi-doc-qa
git pull
git submodule update
git submodule status
```

### Expected output

<!-- snippet: ch23/lab-15-1-submodule-breaks/01-start -->
```text
$ cat .gitmodules
[submodule "vendor/textsplit"]
	path = vendor/textsplit
	url = ../textsplit.git
$ git ls-tree HEAD vendor/
160000 commit e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4	vendor/textsplit
$ git submodule status
 e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4 vendor/textsplit (v0.1.0-1-ge216665)
$ git -C vendor/textsplit status --short --branch
## main...origin/main
```
<!-- /snippet -->

The tree entry has mode `160000` and type `commit`: a gitlink. The submodule sits on its branch `main` in your clone because the setup added it with `git submodule add`, which leaves a branch checked out; in Ravi's clone it has a detached HEAD.

<!-- snippet: ch23/lab-15-1-submodule-breaks/02-library-change -->
```text
$ cd vendor/textsplit
$ git switch main
Already on 'main'
Your branch is up to date with 'origin/main'.
# Edit splitter.py: add the function split_lines. Then:
$ git commit -am "Add line splitter"
[main b6e1e3a] Add line splitter
 1 file changed, 5 insertions(+)
$ cd ../..
```
<!-- /snippet -->

<!-- snippet: ch23/lab-15-1-submodule-breaks/03-pointer -->
```text
$ git status --short
 M vendor/textsplit
$ git diff --submodule=log
Submodule vendor/textsplit e216665..b6e1e3a:
  > Add line splitter
$ git commit -am "Use the line splitter from textsplit"
[main 235f4b8] Use the line splitter from textsplit
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

`git status` reports the submodule path as modified although no file of `doc-qa` changed: the commit checked out in `vendor/textsplit` is no longer the commit that the index records. `--submodule=log` shows the movement as a range of library commits. The commit's "1 insertion(+), 1 deletion(-)" is the replacement of one commit ID by another.

<!-- snippet: ch23/lab-15-1-submodule-breaks/04-push-both -->
```text
$ git push --recurse-submodules=on-demand origin main
Pushing submodule 'vendor/textsplit'
To $LAB/ch23/lab-15-1-submodule-breaks/remotes/textsplit.git
   e216665..b6e1e3a  main -> main
To $LAB/ch23/lab-15-1-submodule-breaks/remotes/doc-qa.git
   907dbd3..235f4b8  main -> main
```
<!-- /snippet -->

The library was pushed first, then the service. The order is the point of the option.

<!-- snippet: ch23/lab-15-1-submodule-breaks/05-teammate-ok -->
```text
$ cd ../ravi-doc-qa
$ git pull
From $LAB/ch23/lab-15-1-submodule-breaks/remotes/doc-qa
   907dbd3..235f4b8  main       -> origin/main
Fetching submodule vendor/textsplit
From $LAB/ch23/lab-15-1-submodule-breaks/remotes/textsplit
   e216665..b6e1e3a  main       -> origin/main
Updating 907dbd3..235f4b8
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git submodule update
Submodule path 'vendor/textsplit': checked out 'b6e1e3a947692bab325b03374ac8e2ebd2269f35'
$ git submodule status
 b6e1e3a947692bab325b03374ac8e2ebd2269f35 vendor/textsplit (v0.1.0-2-gb6e1e3a)
```
<!-- /snippet -->

Ravi's `git pull` fetched the library as well ("Fetching submodule vendor/textsplit") and moved his `main`. It did not check out the new library commit; `git submodule update` did.

### What happened internally

Your commit in `vendor/textsplit` went into the library's own repository, which lives in `doc-qa/.git/modules/vendor/textsplit`, and moved that repository's `main`. Nothing in `doc-qa` changed until you ran `git commit -am` there: that staged and committed a new gitlink, so the root tree of the new service commit has an entry `160000 commit` with the library commit's ID. The service's object database does not contain that library commit, only its ID. `git push --recurse-submodules=on-demand` looked at the gitlinks that the outgoing service commits introduce, ran a push inside each affected submodule, and pushed the service afterwards. On Ravi's side, `git pull` saw that the fetched commits change a gitlink and fetched inside `.git/modules/vendor/textsplit`; `git submodule update` then set the submodule's HEAD, detached, to the recorded commit.

### Checkpoint

In `ravi-doc-qa`, `git submodule status` prints the ID of your "Add line splitter" commit with a leading space (no `+` and no `-`), and `git status --short --branch` prints the branch line only.

### Failure scenario

Go back to your clone and make a second library change. Append to `vendor/textsplit/splitter.py`, after two empty lines:

```text
def split_paragraphs(text):
    """One chunk per paragraph."""
    return [p for p in text.split("\n\n") if p.strip()]
```

This time, publish the way people publish when they think of `vendor/textsplit` as a directory of their repository:

```bash
cd ../doc-qa
# edit vendor/textsplit/splitter.py as described
git -C vendor/textsplit commit -am "Add paragraph splitter"
git commit -am "Use the paragraph splitter from textsplit"
git push origin main
```

<!-- snippet: ch23/lab-15-1-submodule-breaks/06-failure -->
```text
$ cd ../doc-qa
# A second library change. Edit vendor/textsplit/splitter.py: add split_paragraphs. Then:
$ git -C vendor/textsplit commit -am "Add paragraph splitter"
[main 1acf1c3] Add paragraph splitter
 1 file changed, 5 insertions(+)
$ git commit -am "Use the paragraph splitter from textsplit"
[main 08ffafb] Use the paragraph splitter from textsplit
 1 file changed, 1 insertion(+), 1 deletion(-)
# The mistake: only the superproject is pushed.
$ git push origin main
To $LAB/ch23/lab-15-1-submodule-breaks/remotes/doc-qa.git
   235f4b8..08ffafb  main -> main
```
<!-- /snippet -->

The push succeeded and printed no warning. Be Ravi again:

```bash
cd ../ravi-doc-qa
git pull
git status --short --branch
```

<!-- snippet: ch23/lab-15-1-submodule-breaks/07-teammate-broken -->
```text
$ cd ../ravi-doc-qa
$ git pull
From $LAB/ch23/lab-15-1-submodule-breaks/remotes/doc-qa
   235f4b8..08ffafb  main       -> origin/main
Fetching submodule vendor/textsplit
fatal: git upload-pack: not our ref 1acf1c37d09b3b17e0c8e1ea209c35bc141e9dbc
fatal: remote error: upload-pack: not our ref 1acf1c37d09b3b17e0c8e1ea209c35bc141e9dbc
Errors during submodule fetch:
	vendor/textsplit
[exit status: 1]
$ git status --short --branch
## main...origin/main [behind 1]
```
<!-- /snippet -->

The pull fetched the service, tried to fetch the library commit that the new service commit records, and was refused: `not our ref`. It stopped before the merge, so Ravi's `main` is one commit behind `origin/main`. The two `fatal` lines report the same refusal from two processes, the client and the `git upload-pack` that serves a path remote on your own machine. They can appear in either order, which is why this replay is volatile; over HTTPS or SSH you would see the `remote error` line only.

Diagnose it as Ravi. Which commit does the service want, and what does the library's remote have?

```bash
git ls-tree origin/main vendor/
git ls-remote --heads ../remotes/textsplit.git
```

<!-- snippet: ch23/lab-15-1-submodule-breaks/08-diagnose -->
```text
$ git ls-tree origin/main vendor/
160000 commit 1acf1c37d09b3b17e0c8e1ea209c35bc141e9dbc	vendor/textsplit
$ git ls-remote --heads ../remotes/textsplit.git
b6e1e3a947692bab325b03374ac8e2ebd2269f35	refs/heads/main
```
<!-- /snippet -->

The recorded commit and the tip of the library's only branch are different commits. Use the abbreviated ID from your own `git ls-tree` output in the next two commands (the replay's is `1acf1c3`): does Ravi's copy of the library have the commit, and who does?

```bash
git -C vendor/textsplit cat-file -t <id>
git -C ../doc-qa/vendor/textsplit branch --all --contains <id>
```

<!-- snippet: ch23/lab-15-1-submodule-breaks/09-diagnose-where -->
```text
$ git -C vendor/textsplit cat-file -t 1acf1c3
fatal: Not a valid object name 1acf1c3
[exit status: 128]
$ git -C ../doc-qa/vendor/textsplit branch --all --contains 1acf1c3
* main
```
<!-- /snippet -->

The commit exists in one place: the library repository inside your clone, on its local `main`, and on no remote-tracking branch. On a real team the last command is a message to the author of the service commit, because you cannot look into a colleague's clone.

```text
Observed behavior : git pull in the service fails with "not our ref <id>" while fetching a submodule.
Git state         : origin/main of the service records a gitlink to a library commit that no ref
                    of the library's remote reaches.
Mechanism         : A push of the superproject sends the gitlink, which is an ID. It does not send
                    the commit that the ID names; that commit lives in another repository.
Root cause        : The superproject was pushed before the submodule.
Why Git does this : Superproject and submodule are separate repositories with separate remotes
                    and permissions. Without push.recurseSubmodules, a push looks at one of them.
Correct fix       : The author pushes the library commit. Nothing in the superproject changes.
Prevention        : push.recurseSubmodules=check, and CI that clones recursively from scratch.
```

### Recovery

The fix is made by the person who has the commit. Push the library from your clone, then be Ravi:

```bash
cd ../doc-qa
git -C vendor/textsplit push origin main
cd ../ravi-doc-qa
git pull
git -c protocol.file.allow=always submodule update
```

<!-- snippet: ch23/lab-15-1-submodule-breaks/10-recovery -->
```text
$ cd ../doc-qa
$ git -C vendor/textsplit push origin main
To $LAB/ch23/lab-15-1-submodule-breaks/remotes/textsplit.git
   b6e1e3a..1acf1c3  main -> main
$ cd ../ravi-doc-qa
$ git pull
Updating 235f4b8..08ffafb
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git -c protocol.file.allow=always submodule update
From $LAB/ch23/lab-15-1-submodule-breaks/remotes/textsplit
   b6e1e3a..1acf1c3  main       -> origin/main
Submodule path 'vendor/textsplit': checked out '1acf1c37d09b3b17e0c8e1ea209c35bc141e9dbc'
```
<!-- /snippet -->

This `git pull` did not print "Fetching submodule": the service commits had been fetched by the failed pull, so nothing new arrived that would trigger a fetch in the library. The fetch was therefore left to `git submodule update`, and a fetch that `git submodule update` starts over the `file` transport is refused unless `protocol.file.allow` permits it (section 23.4). Without the option the command fails with `fatal: transport 'file' not allowed`; try it first if you want to see that. With a remote over HTTPS or SSH the option is never needed.

Now install the guard in your clone and repeat the mistake:

```bash
cd ../doc-qa
git config set push.recurseSubmodules check
printf '\n# next: sentence splitter\n' >> vendor/textsplit/splitter.py
git -C vendor/textsplit commit -am "Note the next splitter"
git commit -am "Record the newest textsplit"
git push origin main
```

<!-- snippet: ch23/lab-15-1-submodule-breaks/11-prevention -->
```text
$ cd ../doc-qa
$ git config set push.recurseSubmodules check
$ git -C vendor/textsplit commit -am "Note the next splitter"
[main 9aa195f] Note the next splitter
 1 file changed, 2 insertions(+)
$ git commit -am "Record the newest textsplit"
[main 4e8667f] Record the newest textsplit
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push origin main
The following submodule paths contain changes that can
not be found on any remote:
  vendor/textsplit

Please try

	git push --recurse-submodules=on-demand

or cd to the path and use

	git push

to push them to a remote.

fatal: Aborting.
fatal: the remote end hung up unexpectedly
[exit status: 128]
```
<!-- /snippet -->

The push is refused before anything is sent, and the message names both ways out. `git config set` needs Git 2.46 or later; the older spelling is `git config push.recurseSubmodules check`.

### Verification

Publish correctly, and check from Ravi's side that both repositories are in step:

```bash
git push --recurse-submodules=on-demand origin main
cd ../ravi-doc-qa
git pull
git submodule update
git submodule status
git status --short --branch
```

<!-- snippet: ch23/lab-15-1-submodule-breaks/12-verification -->
```text
$ git push --recurse-submodules=on-demand origin main
Pushing submodule 'vendor/textsplit'
To $LAB/ch23/lab-15-1-submodule-breaks/remotes/textsplit.git
   1acf1c3..9aa195f  main -> main
To $LAB/ch23/lab-15-1-submodule-breaks/remotes/doc-qa.git
   08ffafb..4e8667f  main -> main
$ cd ../ravi-doc-qa
$ git pull
From $LAB/ch23/lab-15-1-submodule-breaks/remotes/doc-qa
   08ffafb..4e8667f  main       -> origin/main
Fetching submodule vendor/textsplit
From $LAB/ch23/lab-15-1-submodule-breaks/remotes/textsplit
   1acf1c3..9aa195f  main       -> origin/main
Updating 08ffafb..4e8667f
Fast-forward
 vendor/textsplit | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git submodule update
Submodule path 'vendor/textsplit': checked out '9aa195fba1426252cdcb9cfa8e43e92732c66c95'
$ git submodule status
 9aa195fba1426252cdcb9cfa8e43e92732c66c95 vendor/textsplit (v0.1.0-4-g9aa195f)
$ git status --short --branch
## main...origin/main
```
<!-- /snippet -->

`git submodule status` shows the newest library commit without a `+`, and the status of the service is clean and level with `origin/main`.

### Questions

1. Compare your two predictions with what happened. At which of your commands could Git have warned you, and why did it not?
2. Name the three places that together make up a submodule, and say which of them a commit of the superproject records.
3. After the failed pull, `git status --short --branch` in Ravi's clone said `[behind 1]`. What had the pull done and what had it not done? What would `git merge origin/main` have produced at that moment?
4. In the recovery, why did `git submodule update` need `-c protocol.file.allow=always`, when the same command had worked without it in the first part of the lab?
5. `push.recurseSubmodules=check` is a setting in your clone. Name two situations in which it does not protect the team, and one control that covers both.
6. Suppose you had no permission to push to `textsplit`. What are your options for the service commit that you have already pushed, and which of them rewrites nothing?

## Lab 15.2: The same dependency as a subtree

### Objective

Vendor the same library into the same service with `git subtree`, see what a teammate receives, update to a new upstream release, run into the standard subtree failure and repair it, and extract a local change to the library as a branch that the library's maintainer can review.

### Prerequisites

Chapter 23, sections 23.13 and 23.14, and Lab 15.1, so that you can compare. From [Chapter 8](../textbook/ch08-merge.md): what a merge base is.

### Setup

```bash
bash labs/ch23/setup-15-2-subtree.sh
labs/shell m15-2
cd doc-qa
```

The same two shared repositories as in Lab 15.1, and this time `doc-qa` has no dependency on the library yet. Asha, the library's maintainer, has release 0.2.0 committed and tagged in her clone `asha-textsplit` and has not pushed it; you will publish it for her in the middle of the lab.

`git subtree` is a script from Git's `contrib` directory. Most distributions of Git install it, this machine's Git 2.55.0 included; if `git subtree -h` prints a usage text, you have it.

### Commands

Before you start, write down a prediction: after `git subtree add`, what will `git ls-tree HEAD vendor/` print for `vendor/textsplit`, and what will Ravi have to run after `git clone` to get the library's files?

Add the library, squashed, and look at the history that the command made:

```bash
git subtree add --prefix=vendor/textsplit ../remotes/textsplit.git main --squash
git log --graph --format="%h %an: %s"
```

Inspect what is in the tree, and where the upstream version is recorded:

```bash
git ls-tree HEAD vendor/
git ls-files vendor
git log -1 --format=%B HEAD^2
ls -A
```

Publish, and clone as Ravi with a plain `git clone`:

```bash
git push origin main
git clone ../remotes/doc-qa.git ../ravi-doc-qa
ls ../ravi-doc-qa/vendor/textsplit
git -C ../ravi-doc-qa status --short --branch
```

Play Asha and publish the library's release 0.2.0:

```bash
git -C ../asha-textsplit push origin main --tags
```

### Expected output

<!-- snippet: ch23/lab-15-2-subtree/01-add -->
```text
$ git subtree add --prefix=vendor/textsplit ../remotes/textsplit.git main --squash
git fetch ../remotes/textsplit.git main
From ../remotes/textsplit
 * branch            main       -> FETCH_HEAD
Added dir 'vendor/textsplit'
$ git log --graph --format="%h %an: %s"
*   ba19583 Lab User: Merge commit '65b9504fd6ea6ebab1b7c6297fc083d5d5caa280' as 'vendor/textsplit'
|\  
| * 65b9504 Lab User: Squashed 'vendor/textsplit/' content from commit e216665
* bf78eb9 Lab User: Add keyword answerer
* 1d93b09 Lab User: Add document loader
```
<!-- /snippet -->

Two commits were added. `65b9504` has no parent: it is a root commit whose tree is the library's content at upstream commit `e216665`. `ba19583` is a merge of that root commit into your history, placing the content under `vendor/textsplit`. By hand, these two commits get other IDs.

<!-- snippet: ch23/lab-15-2-subtree/02-inspect -->
```text
$ git ls-tree HEAD vendor/
040000 tree bb3d20df131c55a48b035cace5cd1812d87d5332	vendor/textsplit
$ git ls-files vendor
vendor/textsplit/README.md
vendor/textsplit/splitter.py
$ git log -1 --format=%B HEAD^2
Squashed 'vendor/textsplit/' content from commit e216665

git-subtree-dir: vendor/textsplit
git-subtree-split: e2166657d4daa7b174a5fb83da9e2f8ecca2c9e4

$ ls -A
.git
answer.py
ingest.py
README.md
vendor
```
<!-- /snippet -->

Mode `040000`, type `tree`: an ordinary directory, and the library's files are ordinary entries of your index. There is no `.gitmodules`. The only record of where the content came from is the pair of trailer lines in the squash commit's message.

<!-- snippet: ch23/lab-15-2-subtree/03-teammate -->
```text
$ git push origin main
To $LAB/ch23/lab-15-2-subtree/remotes/doc-qa.git
   bf78eb9..ba19583  main -> main
$ git clone ../remotes/doc-qa.git ../ravi-doc-qa
Cloning into '../ravi-doc-qa'...
done.
$ ls ../ravi-doc-qa/vendor/textsplit
README.md
splitter.py
$ git -C ../ravi-doc-qa status --short --branch
## main...origin/main
```
<!-- /snippet -->

Ravi ran nothing after `git clone`, and no `protocol.file.allow` was involved: the library's files are part of the service's own commits.

<!-- snippet: ch23/lab-15-2-subtree/04-upstream-release -->
```text
# Play Asha: publish textsplit 0.2.0.
$ git -C ../asha-textsplit push origin main --tags
To $LAB/ch23/lab-15-2-subtree/remotes/textsplit.git
   e216665..2cb6684  main -> main
 * [new tag]         v0.2.0 -> v0.2.0
```
<!-- /snippet -->

### What happened internally

`git subtree add --squash` fetched the library's `main` into `FETCH_HEAD`, created a parentless commit that holds the library's tree and the trailers `git-subtree-dir` and `git-subtree-split`, and merged that commit into `main` with the library's tree placed at the prefix. The blobs of the library's files are now objects of your repository, reachable from your commits, and they travel with every push and clone of the service. The library's own commits are not reachable from your `main`: with `--squash` their content arrives and their history does not. Nothing was written to the configuration, and no file or directory in `.git` knows that `vendor/textsplit` is special.

### Checkpoint

`git log --oneline | wc -l` prints 4. `ls ../ravi-doc-qa/vendor/textsplit` lists `README.md` and `splitter.py`. `git ls-remote --tags ../remotes/textsplit.git` lists `v0.2.0`.

### Failure scenario

Update the vendored copy to the new release, and forget the option that you used when you added it:

```bash
git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main
git status --short --branch
```

<!-- snippet: ch23/lab-15-2-subtree/05-failure -->
```text
# Update the vendored copy, and forget --squash:
$ git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main
From ../remotes/textsplit
 * branch            main       -> FETCH_HEAD
fatal: refusing to merge unrelated histories
[exit status: 128]
$ git status --short --branch
## main...origin/main
```
<!-- /snippet -->

The pull is refused and nothing changed: no merge is in progress, and the branch is where it was. Without `--squash`, `git subtree pull` asks for a merge of the library's real commit `2cb6684` into your branch. Your history contains a snapshot of the library's content and none of the library's commits, so the two histories have no common ancestor, and `git merge` refuses such a merge unless it is told otherwise.

### Recovery

Repeat the pull with the option:

```bash
git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main --squash
git log --graph --format="%h %an: %s"
```

<!-- snippet: ch23/lab-15-2-subtree/06-recovery -->
```text
$ git subtree pull --prefix=vendor/textsplit ../remotes/textsplit.git main --squash
From ../remotes/textsplit
 * branch            main       -> FETCH_HEAD
Merge made by the 'ort' strategy.
 vendor/textsplit/splitter.py | 2 ++
 1 file changed, 2 insertions(+)
$ git log --graph --format="%h %an: %s"
*   27fdaf3 Lab User: Merge commit '4059f31e1f05cfa2bdeaa3414929aee3ea447857'
|\  
| * 4059f31 Lab User: Squashed 'vendor/textsplit/' changes from e216665..2cb6684
* | ba19583 Lab User: Merge commit '65b9504fd6ea6ebab1b7c6297fc083d5d5caa280' as 'vendor/textsplit'
|\| 
| * 65b9504 Lab User: Squashed 'vendor/textsplit/' content from commit e216665
* bf78eb9 Lab User: Add keyword answerer
* 1d93b09 Lab User: Add document loader
```
<!-- /snippet -->

A second squash commit, `4059f31`, whose parent is the first one, and a merge of it. The side line of squash commits is the subtree's private history of upstream versions.

Do not "repair" the refused pull with `--allow-unrelated-histories` by hand. A plain merge knows nothing about the prefix: tried in this sandbox, it put `splitter.py` into the root of the service and stopped with an add/add conflict in `README.md`.

### Verification

Confirm that the update brought exactly the upstream change, and that the recorded upstream version moved:

```bash
git diff --stat HEAD^1 HEAD
grep -n "overlap must" vendor/textsplit/splitter.py
git log -1 --format=%B HEAD^2
```

<!-- snippet: ch23/lab-15-2-subtree/07-verification -->
```text
$ git diff --stat HEAD^1 HEAD
 vendor/textsplit/splitter.py | 2 ++
 1 file changed, 2 insertions(+)
$ grep -n "overlap must" vendor/textsplit/splitter.py
4:        raise ValueError("overlap must be smaller than size")
$ git log -1 --format=%B HEAD^2
Squashed 'vendor/textsplit/' changes from e216665..2cb6684

2cb6684 Reject an overlap that is not smaller than the chunk size

git-subtree-dir: vendor/textsplit
git-subtree-split: 2cb66842c7f852fd0ff2d14b0fcf9bb0e94428f9
```
<!-- /snippet -->

Then make a change to the vendored library in the service's repository and extract it for upstream. Append the function `split_paragraphs` from Lab 15.1 to `vendor/textsplit/splitter.py`, and:

```bash
git commit -am "Add paragraph splitter to the vendored textsplit"
git subtree split --quiet --prefix=vendor/textsplit -b textsplit-export
git log --graph --format="%h %an: %s" textsplit-export
git push ../remotes/textsplit.git textsplit-export:refs/heads/docqa/paragraphs
```

<!-- snippet: ch23/lab-15-2-subtree/08-contribute-back -->
```text
# Edit vendor/textsplit/splitter.py: add split_paragraphs. Then:
$ git commit -am "Add paragraph splitter to the vendored textsplit"
[main 91943ec] Add paragraph splitter to the vendored textsplit
 1 file changed, 5 insertions(+)
$ git subtree split --quiet --prefix=vendor/textsplit -b textsplit-export
84d2435f495177f2ef14a41107a020c633dc4884
$ git log --graph --format="%h %an: %s" textsplit-export
* 84d2435 Lab User: Add paragraph splitter to the vendored textsplit
* 2cb6684 Asha Rao: Reject an overlap that is not smaller than the chunk size
* e216665 Asha Rao: Add overlap between neighbouring chunks
* ceaafe1 Asha Rao: Add fixed-size splitter
$ git push ../remotes/textsplit.git textsplit-export:refs/heads/docqa/paragraphs
To ../remotes/textsplit.git
 * [new branch]      textsplit-export -> docqa/paragraphs
```
<!-- /snippet -->

The branch `textsplit-export` has your commit on top, with paths relative to the library's root, and below it the upstream commits `2cb6684`, `e216665` and `ceaafe1` with their original IDs and Asha as their author. Your top commit has another ID by hand; the three below it must match. The push created a branch in the library's repository that Asha can review and merge like any other contribution.

### Questions

1. Compare your prediction with the output of `git ls-tree` and with what Ravi had to do. State the difference to Lab 15.1 in terms of objects: which repository's object database holds the library's blobs in each lab?
2. Where is the upstream version of the vendored library recorded, and what would break if someone edited that commit message during a history rewrite?
3. Explain `refusing to merge unrelated histories` for the pull without `--squash`. Which commit was Git asked to merge, and why is there no merge base?
4. `git subtree split` produced a branch whose lower three commits have upstream's own IDs. How can a command that synthesizes history arrive at existing commit IDs?
5. Ravi edits `vendor/textsplit/splitter.py` and `answer.py` in one commit. What does this cost later, for `split` and for review, and which rule for the team follows?
6. For each of these situations choose submodule, subtree, or a package manager, and give the deciding reason: (a) a tokenizer library released on a package index, used by six services; (b) a shared protobuf schema repository that three teams change weekly and that must be pinned exactly; (c) a small upstream script collection that you patch locally and that your CI must build without extra credentials.

## Lab 15.3: Inspect an LFS pointer

### Objective

Track a model file with Git LFS and establish, with your own commands, what Git stores (a pointer), what LFS stores (the content, named by its SHA-256), and what the clean and smudge filters do. Then commit a second binary before its pattern is tracked, find out why tracking it afterwards changes nothing in history, and repair the unpushed commits. Finish by pushing and by cloning as a machine without the LFS filter.

### Prerequisites

Chapter 22, sections 22.2 to 22.7. From [Chapter 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md): what a clean filter and a smudge filter are. git-lfs must be installed (`git lfs version`; this course was run with 3.7.1).

### Setup

```bash
bash labs/ch22/setup-15-3-lfs-pointer.sh
labs/shell m15-3
cd transcriber
```

The project is `transcriber`, a speech-to-text service with a shared repository in `../remotes/transcriber.git`. One commit of code is pushed. The working tree holds two new binary files that are not added yet: the acoustic model `models/acoustic.onnx` (1,200,000 bytes) and a sample recording `samples/hello.wav` (48,000 bytes). Both are deterministic stand-ins that do not compress, which is how real weights behave.

The lab shell's global configuration has no LFS filter, and the lab keeps it that way: you install LFS with `git lfs install --local`, which writes to the configuration of this one repository. Do not run `git lfs install` without `--local` in a lab.

### Commands

Look at the starting state and take the fingerprint of the model:

```bash
git status --short
wc -c models/acoustic.onnx samples/hello.wav
shasum -a 256 models/acoustic.onnx
```

Before you go on, write down a prediction: after you commit the model with LFS, how many bytes will `git cat-file -s HEAD:models/acoustic.onnx` report, and how many will `wc -c models/acoustic.onnx` report?

Install the filter for this repository, track the pattern, and commit the model together with `.gitattributes`:

```bash
git lfs install --local
git lfs track "*.onnx"
cat .gitattributes
git add .gitattributes models/acoustic.onnx
git commit -m "Add acoustic model v1, tracked with Git LFS"
```

Inspect what Git stored and what LFS stored:

```bash
git cat-file -p HEAD:models/acoustic.onnx
git cat-file -s HEAD:models/acoustic.onnx
wc -c models/acoustic.onnx
find .git/lfs/objects -type f
git lfs ls-files
```

Run the two filters by hand:

```bash
git lfs clean < models/acoustic.onnx
git cat-file -p HEAD:models/acoustic.onnx | git lfs smudge | shasum -a 256
```

### Expected output

<!-- snippet: ch22/lab-15-3-lfs-pointer/01-start -->
```text
$ git status --short
?? models/acoustic.onnx
?? samples/
$ wc -c models/acoustic.onnx samples/hello.wav
 1200000 models/acoustic.onnx
   48000 samples/hello.wav
 1248000 total
$ shasum -a 256 models/acoustic.onnx
02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de  models/acoustic.onnx
```
<!-- /snippet -->

<!-- snippet: ch22/lab-15-3-lfs-pointer/02-install-track -->
```text
$ git lfs install --local
Updated Git hooks.
Git LFS initialized.
$ git lfs track "*.onnx"
Tracking "*.onnx"
$ cat .gitattributes
*.onnx filter=lfs diff=lfs merge=lfs -text
```
<!-- /snippet -->

`git lfs track` wrote one line to `.gitattributes` and did nothing else. The line is what makes Git call the filter named `lfs` for matching paths; `git lfs install --local` is what defined that filter in `.git/config` and installed four hooks.

<!-- snippet: ch22/lab-15-3-lfs-pointer/03-commit -->
```text
$ git add .gitattributes models/acoustic.onnx
$ git commit -m "Add acoustic model v1, tracked with Git LFS"
[main 1124f58] Add acoustic model v1, tracked with Git LFS
 2 files changed, 4 insertions(+)
 create mode 100644 .gitattributes
 create mode 100644 models/acoustic.onnx
```
<!-- /snippet -->

"4 insertions(+)" for a binary of 1.2 MB and a one-line attributes file: Git counted the three lines of the pointer.

<!-- snippet: ch22/lab-15-3-lfs-pointer/04-pointer -->
```text
$ git cat-file -p HEAD:models/acoustic.onnx
version https://git-lfs.github.com/spec/v1
oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
size 1200000
$ git cat-file -s HEAD:models/acoustic.onnx
132
$ wc -c models/acoustic.onnx
 1200000 models/acoustic.onnx
$ find .git/lfs/objects -type f
.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
$ git lfs ls-files
0269885262 * models/acoustic.onnx
```
<!-- /snippet -->

The blob in the commit is 132 bytes of text. Its `oid` is the SHA-256 that `shasum` printed in the first step, and the content is a file of that name under `.git/lfs/objects/`. The working tree file is the full model. In `git lfs ls-files`, the `*` says that the working tree file holds content; a `-` would say that it holds a pointer.

<!-- snippet: ch22/lab-15-3-lfs-pointer/05-filters-by-hand -->
```text
# The clean filter, run by hand: content in, pointer out.
$ git lfs clean < models/acoustic.onnx
version https://git-lfs.github.com/spec/v1
oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
size 1200000
# The smudge filter, run by hand: pointer in, content out.
$ git cat-file -p HEAD:models/acoustic.onnx | git lfs smudge | shasum -a 256
02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de  -
```
<!-- /snippet -->

Clean turns content into a pointer; smudge turns a pointer into content, and the content it produced has the fingerprint you started with.

### What happened internally

`git add models/acoustic.onnx` looked up the path's attributes, found `filter=lfs`, and piped the file through the clean filter. The filter computed the SHA-256 of the content, copied the content to `.git/lfs/objects/02/69/<oid>`, and returned the pointer text; Git hashed and stored the pointer as an ordinary blob and put that blob's ID into the index. The commit, its trees and the index know the pointer only. The LFS store is not part of Git's object database: `git fsck`, `git gc` and a plain `git push` do not look at it. On checkout the path goes through the smudge filter, which reads a pointer and writes the content from the local store, or downloads it first. Pushing LFS content is the job of the `pre-push` hook that `git lfs install` wrote.

### Checkpoint

`git cat-file -s HEAD:models/acoustic.onnx` prints 132. `git lfs ls-files` prints one line, with `*`. The `oid` line of the pointer equals your `shasum` output.

### Failure scenario

Commit the recording the ordinary way, and remember LFS one commit too late:

```bash
git add samples/hello.wav
git commit -m "Add a sample recording"
git lfs track "*.wav"
git add .gitattributes
git commit -m "Track WAV files with Git LFS"
git lfs ls-files
git cat-file -s HEAD:samples/hello.wav
git status --short
```

<!-- snippet: ch22/lab-15-3-lfs-pointer/06-failure -->
```text
$ git add samples/hello.wav
$ git commit -m "Add a sample recording"
[main 9f11a9f] Add a sample recording
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 samples/hello.wav
# Too late, you remember that recordings should be in LFS as well:
$ git lfs track "*.wav"
Tracking "*.wav"
$ git add .gitattributes
$ git commit -m "Track WAV files with Git LFS"
[main 59bae00] Track WAV files with Git LFS
 1 file changed, 1 insertion(+)
$ git lfs ls-files
0269885262 * models/acoustic.onnx
$ git cat-file -s HEAD:samples/hello.wav
48000
$ git status --short
 M samples/hello.wav
```
<!-- /snippet -->

Three symptoms. `git lfs ls-files` does not list the recording. The blob in HEAD is 48,000 bytes: the full content is in Git. And `git status` reports the file as modified although you did not touch it. A tracking line is a rule for future `git add` runs. It does not convert what is committed. The file shows as modified because Git now compares the committed blob with what the clean filter would produce for the working tree file, which is a pointer, and they differ.

### Recovery

Nothing has been pushed, so the commits can be rewritten. `git lfs migrate import` is 🟡 a history rewrite: every commit in scope and every descendant gets a new ID. Its default scope is the unpushed commits of the current branch, which is what you want here. `--yes` answers the command's one prompt, whether changes in the working tree may be overwritten. Here the only "change" is the modification that `git status` reported for a file you did not touch; with real uncommitted work, commit or stash it first, because the option permits its loss:

```bash
git log --oneline
git lfs migrate import --include="*.wav" --yes
git log --oneline
git show HEAD~2:.gitattributes
git lfs checkout
```

<!-- snippet: ch22/lab-15-3-lfs-pointer/07-recovery -->
```text
# Nothing has been pushed, so the two commits can be rewritten.
$ git log --oneline
59bae00 Track WAV files with Git LFS
9f11a9f Add a sample recording
1124f58 Add acoustic model v1, tracked with Git LFS
c66100a Add transcription entry point
$ git lfs migrate import --include="*.wav" --yes
changes in your working copy will be overridden ...
Fetching remote refs: ..., done.
Sorting commits: ..., done.
Rewriting commits: 100% (3/3), done.
Updating refs: ..., done.
Checkout: ..., done.
$ git log --oneline
fb70e1a Track WAV files with Git LFS
62df03d Add a sample recording
a55418e Add acoustic model v1, tracked with Git LFS
c66100a Add transcription entry point
$ git show HEAD~2:.gitattributes
*.onnx filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
$ git lfs checkout
Checking out LFS objects: 100% (2/2), 1.2 MB | 0 B/s, done.
```
<!-- /snippet -->

The pushed commit `c66100a` kept its ID and the three above it were replaced. The migration also wrote the `*.wav` line into `.gitattributes` in the earliest rewritten commit, so that every rewritten commit is consistent with its own attributes. `git lfs migrate` leaves pointers in the working tree; `git lfs checkout` replaces them with content from the local store.

If the commits had been pushed, you would not rewrite. You would fix forward with `git add --renormalize samples/hello.wav` and a new commit, and accept that the 48,000-byte blob stays in history (section 22.10).

### Verification

Check that no commit of `main` reaches a large blob, that both files are whole in the working tree, and that the store is intact:

```bash
git lfs ls-files
git status --short --branch
git rev-list --objects main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep -e onnx -e wav
wc -c models/acoustic.onnx samples/hello.wav
git lfs fsck
```

<!-- snippet: ch22/lab-15-3-lfs-pointer/08-verification -->
```text
$ git lfs ls-files
0269885262 * models/acoustic.onnx
8a2b8ee542 * samples/hello.wav
$ git status --short --branch
## main...origin/main [ahead 3]
$ git rev-list --objects main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep -e onnx -e wav
blob 132 models/acoustic.onnx
blob 130 samples/hello.wav
$ wc -c models/acoustic.onnx samples/hello.wav
 1200000 models/acoustic.onnx
   48000 samples/hello.wav
 1248000 total
$ git lfs fsck
Git LFS fsck OK
```
<!-- /snippet -->

Then publish, and look at both stores of the remote. From here on the expected output comes from a second replay, `labs/ch22/lab-15-3-lfs-pointer-remote-volatile.sh`. It starts from the same content in a single commit, so it prints `41377ac` where you push your three commits. It is volatile for one line: with git-lfs 3.7.1 and a path remote, the progress line "Uploading LFS objects" is sometimes absent.

```bash
git lfs status
git push origin main
git -C ../remotes/transcriber.git cat-file -p main:models/acoustic.onnx
find ../remotes/transcriber.git/lfs/objects -type f | sort
```

<!-- snippet: ch22/lab-15-3-lfs-pointer-remote-volatile/01-push -->
```text
$ git lfs status
On branch main
Objects to be pushed to origin/main:

	models/acoustic.onnx (02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de)
	samples/hello.wav (8a2b8ee542739d00cbc181b19abd5ddf030ffb72901f91bc37aa0816fb52d5de)

Objects to be committed:


Objects not staged for commit:


$ git push origin main
Uploading LFS objects: 100% (2/2), 0 B | 0 B/s, done.
To $LAB/ch22/lab-15-3-lfs-pointer-remote-volatile/remotes/transcriber.git
   c66100a..41377ac  main -> main
```
<!-- /snippet -->

<!-- snippet: ch22/lab-15-3-lfs-pointer-remote-volatile/02-two-stores -->
```text
$ git -C ../remotes/transcriber.git cat-file -p main:models/acoustic.onnx
version https://git-lfs.github.com/spec/v1
oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
size 1200000
$ find ../remotes/transcriber.git/lfs/objects -type f | sort
../remotes/transcriber.git/lfs/objects/02/69/02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
../remotes/transcriber.git/lfs/objects/8a/2b/8a2b8ee542739d00cbc181b19abd5ddf030ffb72901f91bc37aa0816fb52d5de
```
<!-- /snippet -->

The Git side of the remote holds the pointer. The content went to a separate store; for a path remote that is the directory `lfs/objects` inside the bare repository, and for GitHub it is a separate storage service with its own quota (section 22.11).

Last, clone as Ravi. The lab shell has no global LFS filter, so this clone behaves like a clone on a machine without the LFS client:

```bash
git clone ../remotes/transcriber.git ../ravi-transcriber
cd ../ravi-transcriber
cat models/acoustic.onnx
wc -c models/acoustic.onnx samples/hello.wav
git status --short --branch
git lfs install --local
git lfs pull
wc -c models/acoustic.onnx samples/hello.wav
git lfs ls-files
```

<!-- snippet: ch22/lab-15-3-lfs-pointer-remote-volatile/03-clone-without-filter -->
```text
$ git clone ../remotes/transcriber.git ../ravi-transcriber
Cloning into '../ravi-transcriber'...
done.
$ cd ../ravi-transcriber
$ cat models/acoustic.onnx
version https://git-lfs.github.com/spec/v1
oid sha256:02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de
size 1200000
$ wc -c models/acoustic.onnx samples/hello.wav
     132 models/acoustic.onnx
     130 samples/hello.wav
     262 total
$ git status --short --branch
## main...origin/main
```
<!-- /snippet -->

<!-- snippet: ch22/lab-15-3-lfs-pointer-remote-volatile/04-get-content -->
```text
$ git lfs install --local
Updated Git hooks.
Git LFS initialized.
$ git lfs pull
$ wc -c models/acoustic.onnx samples/hello.wav
 1200000 models/acoustic.onnx
   48000 samples/hello.wav
 1248000 total
$ git lfs ls-files
0269885262 * models/acoustic.onnx
8a2b8ee542 * samples/hello.wav
```
<!-- /snippet -->

The clone succeeded, the status is clean, and the "model" is 132 bytes of text. Nothing warned Ravi. After installing the filter, `git lfs pull` downloaded both objects and replaced the pointers.

### Questions

1. Compare your prediction with the two sizes you measured. Which of the two numbers does `git clone` transfer, and which does `git lfs pull` transfer?
2. The `oid` in the pointer is a SHA-256 of the file content. The blob ID that Git gives the pointer is something else. What is hashed in each case, and why does a model that is retrained to identical bytes produce no new LFS object?
3. After `git lfs track "*.wav"` and a commit, `git status` reported `samples/hello.wav` as modified. Explain it from what the clean filter returns.
4. The migration changed the IDs of three commits and left `c66100a` alone. Why exactly those three, although only one of them added a WAV file?
5. A program on Ravi's machine loads `models/acoustic.onnx` after the plain clone. What does it see, what error would you expect from a model loader, and which two commands would you ask Ravi to run first when he reports it?
6. `git lfs fsck` printed "Git LFS fsck OK". What does it check that `git fsck` does not, and what would `git fsck` say about a repository whose LFS store is empty?

## Lab 15.4: Migrate an already-committed large file

### Objective

A model was committed three times as an ordinary blob, and nothing of it has been pushed. Measure what a push would send, move the model to LFS with `git lfs migrate import`, and verify the result. Then widen the migration with `--everything`, see it rewrite a commit that is already on the remote, recover both branches from their reflogs, and migrate the second branch with the correct scope.

### Prerequisites

Chapter 22, sections 22.9 and 22.10, and Lab 15.3. From [Chapter 13](../textbook/ch13-recovery.md): branch reflogs and `git reset --hard <branch>@{n}`.

### Setup

```bash
bash labs/ch22/setup-15-4-lfs-migrate.sh
labs/shell m15-4
cd transcriber
```

The same project as in Lab 15.3, in another state. `origin/main` has one commit of code. Your `main` is four commits ahead: three versions of `models/acoustic.onnx` (1,200,000, then 1,250,000, then 1,300,000 bytes) and one code change. A second local branch, `experiment/quantized`, starts at the second model commit and adds `models/acoustic-int8.onnx` (600,000 bytes). LFS is not installed in the repository and there is no `.gitattributes`.

In this lab the commits that you create by migrating should get the IDs printed here. The migration keeps the author, the committer and both dates of every commit it rewrites, so its result does not depend on the time at which you run it. A hands-on run for this manual, under the real clock, produced the same IDs as the replay.

### Commands

Look at the history and measure what a push of `main` would have to send:

```bash
git log --graph --oneline --decorate --all
git status --short --branch
git rev-list --objects origin/main..main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep blob
git lfs migrate info
```

Before you go on, write down two predictions. Which commits will `git lfs migrate import --include="*.onnx"` rewrite, and which will keep their IDs? And will `.git` be smaller afterwards?

Install LFS for this repository and migrate:

```bash
git lfs install --local
git lfs migrate import --include="*.onnx"
git log --oneline --decorate main
```

Inspect the rewritten branch:

```bash
cat .gitattributes
git rev-list --objects origin/main..main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep blob
git cat-file -p main:models/acoustic.onnx
```

Look at the working tree, and put the content back:

```bash
wc -c models/acoustic.onnx
git lfs checkout
wc -c models/acoustic.onnx
git lfs ls-files --size
git status --short --branch
```

### Expected output

<!-- snippet: ch22/lab-15-4-lfs-migrate/01-start -->
```text
$ git log --graph --oneline --decorate --all
* 6f39d2a (experiment/quantized) Add 8-bit quantized acoustic model
| * 8b13104 (HEAD -> main) Retrain acoustic model with accents (v3)
| * 1ddbfc0 Resample input to 16 kHz
|/  
* 65c2188 Retrain acoustic model on noisy audio (v2)
* f9e56b8 Add acoustic model v1
* c66100a (origin/main) Add transcription entry point
$ git status --short --branch
## main...origin/main [ahead 4]
```
<!-- /snippet -->

<!-- snippet: ch22/lab-15-4-lfs-migrate/02-measure -->
```text
# What a push of main would have to send:
$ git rev-list --objects origin/main..main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep blob
blob 1300000 models/acoustic.onnx
blob 231 transcribe.py
blob 1250000 models/acoustic.onnx
blob 1200000 models/acoustic.onnx
$ git lfs migrate info
Fetching remote refs: ..., done.
Sorting commits: ..., done.
Examining commits: 100% (4/4), done.
*.onnx	3.8 MB	3/3 files	100%
*.py  	429 B 	2/2 files	100%
*.md  	68 B  	1/1 file 	100%
*.txt 	14 B  	1/1 file 	100%
```
<!-- /snippet -->

A push of `main` would send three blobs of 1.2 to 1.3 MB, one for every version: the model does not delta-compress against its predecessor. `migrate info` chose its scope by itself, "Examining commits: 100% (4/4)": the commits of the current branch that are on no remote.

<!-- snippet: ch22/lab-15-4-lfs-migrate/03-import -->
```text
$ git lfs install --local
Updated Git hooks.
Git LFS initialized.
$ git lfs migrate import --include="*.onnx"
Fetching remote refs: ..., done.
Sorting commits: ..., done.
Rewriting commits: 100% (4/4), done.
Updating refs: ..., done.
Checkout: ..., done.
$ git log --oneline --decorate main
d1e8e7d (HEAD -> main) Retrain acoustic model with accents (v3)
654d53c Resample input to 16 kHz
53cb32a Retrain acoustic model on noisy audio (v2)
b1b921b Add acoustic model v1
c66100a (origin/main, origin/HEAD) Add transcription entry point
```
<!-- /snippet -->

Four commits were rewritten and have new IDs. `c66100a`, the commit that is on the remote, kept its ID.

<!-- snippet: ch22/lab-15-4-lfs-migrate/04-inspect -->
```text
$ cat .gitattributes
*.onnx filter=lfs diff=lfs merge=lfs -text
$ git rev-list --objects origin/main..main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep blob
blob 43 .gitattributes
blob 132 models/acoustic.onnx
blob 231 transcribe.py
blob 132 models/acoustic.onnx
blob 132 models/acoustic.onnx
$ git cat-file -p main:models/acoustic.onnx
version https://git-lfs.github.com/spec/v1
oid sha256:ca75f5b31e55e3e1e51533c80135181b6d1ea30a82a2c1ab28ddd120c1a8a4f2
size 1300000
```
<!-- /snippet -->

The migration added `.gitattributes` and replaced each model blob by a pointer of 132 bytes. The pointer in the tip names an object of 1,300,000 bytes, which `git lfs ls-files` abbreviates to `ca75f5b31e`.

<!-- snippet: ch22/lab-15-4-lfs-migrate/05-working-tree -->
```text
$ wc -c models/acoustic.onnx
     132 models/acoustic.onnx
$ git lfs checkout
Checking out LFS objects: 100% (1/1), 1.3 MB | 0 B/s, done.
$ wc -c models/acoustic.onnx
 1300000 models/acoustic.onnx
$ git lfs ls-files --size
ca75f5b31e * models/acoustic.onnx (1.3 MB)
$ git status --short --branch
## main...origin/main [ahead 4]
```
<!-- /snippet -->

After the migration the working tree file is itself a pointer, even with the filter installed. `git lfs checkout` restores the content from the local store. The branch is still four commits ahead: the same number of commits, other commits.

### What happened internally

For each of the four commits in scope, `git lfs migrate import` built a new tree in which every blob at a path matching `*.onnx` is replaced by a pointer blob, copied the original content into `.git/lfs/objects/` under its SHA-256, and wrote a new commit with the new tree, the rewritten parent, and the original message, author, committer and dates. It added the tracking line to `.gitattributes` in the first rewritten commit. Then it moved `refs/heads/main` to the last new commit and wrote a reflog entry, with an empty message, for the move. The old commits and the three large blobs are still in the object database, reachable from the reflogs of `main` and HEAD; the repository on disk is therefore larger than before, because the content now exists twice, once as Git blobs and once in the LFS store. Nothing was sent anywhere: `migrate` never pushes.

### Checkpoint

`git log --oneline origin/main..main | wc -l` prints 4. Every `models/acoustic.onnx` blob in `origin/main..main` has 132 bytes. `wc -c models/acoustic.onnx` prints 1300000.

### Failure scenario

The other branch was not part of the migration. Confirm that, and then reach for the option whose name promises to catch everything:

```bash
git rev-list --objects origin/main..experiment/quantized | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
git lfs migrate import --include="*.onnx" --everything
git status --short --branch
```

<!-- snippet: ch22/lab-15-4-lfs-migrate/06-failure -->
```text
# The other branch was not part of the migration:
$ git rev-list --objects origin/main..experiment/quantized | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
blob 600000 models/acoustic-int8.onnx
blob 1250000 models/acoustic.onnx
blob 1200000 models/acoustic.onnx
# A flag that promises to catch everything looks like the answer:
$ git lfs migrate import --include="*.onnx" --everything
Sorting commits: ..., done.
Rewriting commits: 100% (8/8), done.
Updating refs: ..., done.
Checkout: ..., done.
$ git status --short --branch
## main...origin/main [ahead 5, behind 1]
```
<!-- /snippet -->

"Rewriting commits: 100% (8/8)", and `main` is now five ahead of `origin/main` and one behind. A branch that you have only added commits to cannot be behind its remote unless a commit that the remote has was replaced. Look:

```bash
git log --graph --oneline --decorate --all
git show --stat --format="%h %s" $(git rev-list --max-parents=0 main)
```

<!-- snippet: ch22/lab-15-4-lfs-migrate/07-diagnose -->
```text
$ git log --graph --oneline --decorate --all
* f074e3b (experiment/quantized) Add 8-bit quantized acoustic model
| * ca28864 (HEAD -> main) Retrain acoustic model with accents (v3)
| * 106939f Resample input to 16 kHz
|/  
* c96fc1c Retrain acoustic model on noisy audio (v2)
* 8a8e13b Add acoustic model v1
* e6c7da2 Add transcription entry point
* c66100a (origin/main, origin/HEAD) Add transcription entry point
$ git show --stat --format="%h %s" $(git rev-list --max-parents=0 main)
e6c7da2 Add transcription entry point

 .gitattributes   |  1 +
 README.md        |  3 +++
 models/vocab.txt |  4 ++++
 transcribe.py    | 12 ++++++++++++
 4 files changed, 20 insertions(+)
```
<!-- /snippet -->

There are two commits named "Add transcription entry point". `c66100a` is the one on the remote. `e6c7da2` is its rewritten copy and the new root of both local branches: `--everything` put every commit reachable from any ref in scope, the pushed root commit included, and the migration wrote the `.gitattributes` line into the earliest commit in scope. That one added file changed the root commit's ID and with it the ID of every descendant. If you pushed now, Git would reject the push as not a fast-forward, and the "fix" people reach for at that point, a forced push, would replace history that others have.

### Recovery

Nothing was pushed, so the branch reflogs have the way back. The migration's reflog entries have no message; identify the entry you want by its commit ID, which you saw in the first migration's log:

```bash
git reflog main -3
git reflog experiment/quantized -2
git reset --hard "main@{1}"
git branch -f experiment/quantized "experiment/quantized@{1}"
git lfs migrate import --include="*.onnx" experiment/quantized
```

<!-- snippet: ch22/lab-15-4-lfs-migrate/08-recovery -->
```text
$ git reflog main -3
ca28864 main@{0}: 
d1e8e7d main@{1}: 
8b13104 main@{2}: commit: Retrain acoustic model with accents (v3)
$ git reflog experiment/quantized -2
f074e3b experiment/quantized@{0}: 
6f39d2a experiment/quantized@{1}: commit: Add 8-bit quantized acoustic model
$ git reset --hard "main@{1}"
HEAD is now at d1e8e7d Retrain acoustic model with accents (v3)
$ git branch -f experiment/quantized "experiment/quantized@{1}"
$ git lfs migrate import --include="*.onnx" experiment/quantized
Fetching remote refs: ..., done.
Sorting commits: ..., done.
Rewriting commits: 100% (3/3), done.
Updating refs: ..., done.
Checkout: ..., done.
```
<!-- /snippet -->

`main@{1}` is `d1e8e7d`, the result of the first, correct migration; `main@{2}` is the original, unmigrated tip. `experiment/quantized@{1}` is its original tip. 🔴 `git reset --hard` discards uncommitted changes in the working tree and the index; run `git status --short` first and expect no output. 🟡 `git branch -f` moves a branch without asking; it is safe here because the old position stays in the reflog. The last command is the migration that should have been run in the first place: a branch named as an argument puts the unpushed commits of that branch in scope. "Rewriting commits: 100% (3/3)": the two model commits that the branch shares with `main`, and its own commit.

To preview a scope before you rewrite, run `git lfs migrate info` with the same scope arguments and read the commit count. In this sandbox, in the starting state, it examines 5 commits for `main experiment/quantized` and 6 for `--everything`; the sixth is the pushed commit.

### Verification

```bash
git log --graph --oneline --decorate --all
git status --short --branch
git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
git lfs checkout
git lfs ls-files --size
wc -c models/acoustic.onnx
git lfs fsck
```

<!-- snippet: ch22/lab-15-4-lfs-migrate/09-verification -->
```text
$ git log --graph --oneline --decorate --all
* b6b0449 (experiment/quantized) Add 8-bit quantized acoustic model
| * d1e8e7d (HEAD -> main) Retrain acoustic model with accents (v3)
| * 654d53c Resample input to 16 kHz
|/  
* 53cb32a Retrain acoustic model on noisy audio (v2)
* b1b921b Add acoustic model v1
* c66100a (origin/main, origin/HEAD) Add transcription entry point
$ git status --short --branch
## main...origin/main [ahead 4]
$ git rev-list --objects --all | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
blob 131 models/acoustic-int8.onnx
blob 132 models/acoustic.onnx
blob 132 models/acoustic.onnx
blob 132 models/acoustic.onnx
# git lfs checkout   (prints a progress line only if a file still held a pointer)
$ git lfs ls-files --size
ca75f5b31e * models/acoustic.onnx (1.3 MB)
$ wc -c models/acoustic.onnx
 1300000 models/acoustic.onnx
$ git lfs fsck
Git LFS fsck OK
```
<!-- /snippet -->

One root, `c66100a`, with `origin/main` on it. Both branches share the migrated commits `b1b921b` and `53cb32a`: the second migration rewrote the two shared commits again and arrived at the commits that the first migration had made, because the same input gives the same commit ID. Every model blob that any ref reaches is a pointer. (`git lfs checkout` prints a progress line only if a file still held a pointer; the replay runs it silently.)

Finally, push both branches. The expected output comes from the second replay, `labs/ch22/lab-15-4-lfs-migrate-push-volatile.sh`, which is volatile for the progress line "Uploading LFS objects", as in Lab 15.3:

```bash
git lfs status
git push origin main experiment/quantized
git -C ../remotes/transcriber.git rev-list --objects --all | git -C ../remotes/transcriber.git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
find ../remotes/transcriber.git/lfs/objects -type f | wc -l
```

<!-- snippet: ch22/lab-15-4-lfs-migrate-push-volatile/01-push -->
```text
$ git lfs status
On branch main
Objects to be pushed to origin/main:

	models/acoustic.onnx (ca75f5b31e55e3e1e51533c80135181b6d1ea30a82a2c1ab28ddd120c1a8a4f2)
	models/acoustic.onnx (f8719e1ac8fb4d5c1d84bffc340e58ce46e7aba4ee423b2d752d6eb7d0d68a65)
	models/acoustic.onnx (02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de)

Objects to be committed:


Objects not staged for commit:


$ git push origin main experiment/quantized
Uploading LFS objects: 100% (4/4), 0 B | 0 B/s, done.
To $LAB/ch22/lab-15-4-lfs-migrate-push-volatile/remotes/transcriber.git
   c66100a..d1e8e7d  main -> main
 * [new branch]      experiment/quantized -> experiment/quantized
```
<!-- /snippet -->

<!-- snippet: ch22/lab-15-4-lfs-migrate-push-volatile/02-remote -->
```text
$ git -C ../remotes/transcriber.git rev-list --objects --all | git -C ../remotes/transcriber.git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx
blob 131 models/acoustic-int8.onnx
blob 132 models/acoustic.onnx
blob 132 models/acoustic.onnx
blob 132 models/acoustic.onnx
$ find ../remotes/transcriber.git/lfs/objects -type f | wc -l
       4
```
<!-- /snippet -->

The remote's Git side holds four pointer blobs and its LFS store holds four objects: three versions of the model and the quantized one.

### Questions

1. Compare your two predictions with what you saw. Why did `c66100a` keep its ID in the first migration, and why is `.git` not smaller afterwards? What would make it smaller, and what would you lose by doing that?
2. After `--everything`, `git status` said `[ahead 5, behind 1]`. Account for both numbers.
3. The pushed root commit contains no `.onnx` file. Why was it rewritten at all?
4. In the recovery you used `main@{1}` and not `main@{2}`. What is each, and what would the lab's end state have been with `main@{2}`?
5. The second migration reported three rewritten commits, and afterwards both branches shared `53cb32a`, a commit that the first migration had already created. Explain why two separate runs produced the same commit.
6. Suppose the three model commits had been pushed a month ago and five colleagues have clones. Outline the plan, name the step at which it most often fails, and say what LFS does not do for you in that plan.
7. Give two kinds of large files for which you would choose neither a plain commit nor LFS, and name what you would use.

