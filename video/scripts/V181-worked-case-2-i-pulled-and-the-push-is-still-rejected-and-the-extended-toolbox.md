# V181: Worked case 2: "I pulled, and the push is still rejected", and the extended toolbox

- **Part.** 9, Production debugging and incident response
- **Module.** 35
- **Planned minutes.** 24
- **Prerequisites.** V040, V180
- **Textbook sections.** [Chapter 29](../../textbook/ch29-production-troubleshooting.md), sections 29.4 and 29.5
- **Demo scripts.** `labs/ch29/case-wrong-upstream.sh` (snippets `01-symptom` to `12-prevent`)

## HOOK

**[ON SCREEN]** "My push is rejected. Git tells me to pull. I pull, Git says everything is up to date, and the push is rejected again."

The developer has done exactly what the error message told them to do, twice. A push asks the server to move its branch to your commits, your saved snapshots. A pull fetches a branch from the server and integrates it into yours. Their conclusion is reasonable: the server is broken, or somebody has locked the branch, or Git is confused and needs `--force`, which overwrites the server's branch.

All three explanations are plausible. All three are wrong. And the third one, acted upon, deletes a teammate's commit from the server. The actual cause is one line of configuration that has been in the repository since the branch was created, and Git has been reporting it in brackets the whole time. Watch for those brackets. You'll read them yourself.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the second worked case of the diagnosis method. It's shorter on purpose: once the ritual of video 180 is a habit, you read the same outputs faster. The mechanism behind the case is from video 40: a pull integrates the configured upstream, and a push goes where `push.default` and the branch name say. The upstream is the branch on the server that a local branch is compared with and pulls from. Those are two separate pieces of configuration, and nothing forces them to name the same branch.

The second subject is the extended toolbox. The ten commands are the fixed opening. The toolbox holds the commands you reach for when you test a hypothesis: for each kind of question, the command that answers it without changing state.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Diagnose a push that stays rejected after a successful pull.
2. Read upstream configuration as evidence and find the mismatch.
3. Use the extended toolbox: refs, graph, remote and object commands beyond the ten.
4. Fix the cause, not the symptom, and add the prevention.
5. Explain why the developer's own explanation was plausible and wrong.

## CONCEPT

**Why this failure exists.** A remote-tracking branch, such as `origin/main`, is your clone's record of where a server's branch was at your last fetch. When you create a branch from a remote-tracking branch, Git records that remote-tracking branch as the new branch's upstream. `git switch -c <name> origin/main` records `origin/main`, because the starting point is a remote-tracking branch and `branch.autoSetupMerge` is true by default. That behavior is right for a local copy of a remote branch, such as `git switch -c main origin/main`. Git can't know that this time the starting point was meant only as a base.

**What follows.** `git pull` without arguments integrates the upstream. `git push origin <name>` targets the server branch `<name>`. Pull and push address different branches. When the two differ, pulling can succeed forever without making the push a fast-forward, a move of the server's branch straight ahead to a descendant.

**Reading the two rejections.** The words in parentheses are evidence, and they differ.

The first rejection says `(fetch first)`: the server's branch has an object this clone has never seen. The second says `(non-fast-forward)`: now the clone has the server's commit and can see that the local branch doesn't contain it. Between them, the pull printed a line beginning with `* [new branch]`: this clone learned of the server's branch for the first time. So the pull fetched the commit and didn't integrate it.

And both rejections read `! [rejected]`. That line is written by the local Git before any rule on the server is consulted. A rule on the server would read `! [remote rejected]`, with `remote:` lines.

**Why the developer's explanation was plausible.** Every message they saw was true. "Use git pull before pushing again" is correct advice for a branch whose upstream is the branch it's pushed to. "Already up to date" was true of the upstream. Nothing on the screen said that the two commands were talking about different branches, unless you read the brackets.

**The extended toolbox.** All of these are 🟢. Each row names the question it answers.

**[ON SCREEN]** The table of section 29.5.

| Question | Command |
|---|---|
| Branch, upstream and counts in one line | `git status -sb` |
| Every ref with its upstream and distance | `git for-each-ref --format='%(refname) %(objectname:short) %(upstream:short) %(upstream:track)'` |
| What is my upstream; where would a push go | `git rev-parse --abbrev-ref @{upstream}`, `@{push}` |
| How far apart are two commits | `git rev-list --left-right --count A...B` |
| Where two histories split | `git merge-base A B` |
| Which branches or tags contain a commit | `git branch -a --contains <id>`, `git tag --contains <id>` |
| Is the same change present under another ID | `git cherry -v <upstream> <branch>`, `git range-diff` |
| What the server holds right now | `git ls-remote origin` |
| When and how a ref moved | `git reflog show --date=iso <ref>` |
| What the index holds, with stages | `git ls-files -s`, `git ls-files -u` |
| Why a path is ignored | `git check-ignore -v <path>`, `git status --ignored` |
| Where one setting comes from | `git config get --show-origin --show-scope --all <key>` |
| Would a merge conflict, without touching anything | `git merge-tree --write-tree --name-only A B` |
| Is the object store intact; what is unreachable | `git fsck`, `git fsck --lost-found` (the second writes files under `.git/lost-found/`) |
| Stashes and other worktrees that hold work | `git stash list`, `git worktree list` |
| What Git executes and sends | `GIT_TRACE=1`, `GIT_TRACE2_EVENT`, `GIT_CURL_VERBOSE=1`, `ssh -v` |

Organize it in your head by the kind of question: refs, graph, remote, objects, index, configuration, and what Git is doing. The `git config get` subcommand needs Git 2.46 or later.

**Local data or the server.** `git ls-remote` and `git remote show origin` contact the server. The other commands answer from local data, which is as old as the last fetch.

**Git, not GitHub: the status of `git fetch`.** `git fetch` is the one command of the opening that changes something: it moves remote-tracking refs and adds objects. It never touches your branches, the index, which is the proposed next commit, or the working tree, the files you edit. And each remote-tracking ref has a reflog, a list of the values it has had. So a fetch is treated as part of evidence collection. Record `git rev-parse origin/main` first if the stale value is itself evidence, as it is after a suspected force push.

## MENTAL MODEL

A picture helps. Picture a branch with two addresses written on it. One says where its deliveries come from: the upstream, used by `git pull`, `git status` and a bare `git rebase`. The other says where its parcels go: the push destination. For most branches the two addresses are the same, and you forget that there are two.

In this case the "from" address is `main` on the server and the "to" address is the feature branch on the server. The developer keeps collecting deliveries from one building and trying to hand parcels in at another, and the second building keeps saying: you haven't picked up what is waiting here.

Where the picture breaks: a postal address is fixed by whoever wrote it, and here nobody wrote it. Git filled in the "from" address on its own when the branch was created, from the starting point.

The lesson for the method: configuration is state. The ten commands include the configuration for this reason, and `git branch -vv` prints the upstream in brackets on every line.

Try it now. Thirty seconds. In the lab shell, or in any repository you have, run `git branch -vv`, which only reads. For each branch, say out loud what stands in the brackets.

**[PAUSE]**

Each pair of brackets names that branch's upstream, its "from" address. If one names a branch you don't push to, you've found today's cause in your own repository, before it cost you anything.

## DIAGRAM

**[DIAGRAM]** The diagram of section 29.4. Draw `main` first, then the two lines that leave it. Label the upper line with its upstream. Then add the arrow that says where the push goes.

```text
                 3d6663d---2defa92   feature/batch-size (HEAD)      upstream: origin/main
                /
  bafe874---ce76024   main, origin/main
                \
                 56bb8e4   origin/feature/batch-size                <- git push origin feature/batch-size goes here
```

Two lines of work leave `ce76024`: two local commits, and one commit by a teammate on the server's branch of the same name. The pull looks at the top right label. The push looks at the bottom arrow.

**[ON SCREEN]** The root-cause box of section 29.4, after the test.

```text
Observed behavior : push rejected; git pull says "Already up to date"; push rejected again.
Git state         : feature/batch-size is 2 ahead of origin/main and 2 ahead, 1 behind
                    origin/feature/batch-size. branch.feature/batch-size.merge = refs/heads/main.
Mechanism         : git switch -c <name> origin/main records origin/main as the upstream, because
                    the starting point is a remote-tracking branch (branch.autoSetupMerge=true).
                    git pull without arguments integrates the upstream. git push origin <name>
                    targets the server branch <name>. Pull and push address different branches.
Root cause        : The upstream of the local branch is not the branch it is pushed to.
Why Git does this : Tracking the starting point is right for a local copy of a remote branch
                    (git switch -c main origin/main). Git cannot know that this time the
                    starting point was meant only as a base.
Correct fix       : Point the upstream at origin/feature/batch-size, replay the two unpublished
                    commits on top of it, push. No force.
Prevention        : Create feature branches with --no-track, or from the local main. Read the
                    brackets in git branch -vv before the first push.
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch29/case-wrong-upstream`. The repository is `embed-jobs`, a batch job that computes embeddings.

**The symptom.**

```bash
git push origin feature/batch-size
git pull
git push origin feature/batch-size
```

<!-- snippet: ch29/case-wrong-upstream/01-symptom -->
```text
$ git push origin feature/batch-size
To ../server.git
 ! [rejected]        feature/batch-size -> feature/batch-size (fetch first)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git pull
From ../server
 * [new branch]      feature/batch-size -> origin/feature/batch-size
Already up to date.
$ git push origin feature/batch-size
To ../server.git
 ! [rejected]        feature/batch-size -> feature/batch-size (non-fast-forward)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

Read the three parts as in the concept section: `(fetch first)`, then `* [new branch]` with "Already up to date", then `(non-fast-forward)`. Three different statements, and the reporter heard one: rejected.

**Evidence.** 🟢 SAFE throughout. Predict: what will the second line of `git status` compare the branch with? Say it out loud.

**[PAUSE]**

```bash
git status
git branch -vv
git log --graph --decorate --oneline --all
```

<!-- snippet: ch29/case-wrong-upstream/02-evidence -->
```text
$ git status
On branch feature/batch-size
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
$ git branch -vv
* feature/batch-size 2defa92 [origin/main: ahead 2] Read batch size from the command line
  main               ce76024 [origin/main] Write vectors to the daily bucket
$ git log --graph --decorate --oneline --all
* 56bb8e4 (origin/feature/batch-size) Add batch_size to the job config
| * 2defa92 (HEAD -> feature/batch-size) Read batch size from the command line
| * 3d6663d Embed in batches
|/  
* ce76024 (origin/main, origin/HEAD, main) Write vectors to the daily bucket
* bafe874 Add embedding job
```
<!-- /snippet -->

"Your branch is ahead of 'origin/main' by 2 commits." Not ahead of `origin/feature/batch-size`. The brackets in `git branch -vv` say the same. There are the brackets from the opening.

**[ANIMATION]** graph: bafe874-ce76024 main origin/main; ce76024-3d6663d-2defa92 feature/batch-size; ce76024-56bb8e4 origin/feature/batch-size; HEAD=feature/batch-size => bafe874-ce76024 main origin/main; ce76024-3d6663d-2defa92 backup/batch-size-before-rebase; ce76024-56bb8e4-097fe6f-aca1b2f feature/batch-size; 56bb8e4 origin/feature/batch-size; HEAD=feature/batch-size title=Two_lines_of_work_leave_ce76024

**[ANIMATION]** step: state-1

The graph shows the teammate's commit `56bb8e4` on the server's branch, beside the two local commits.

```bash
git config list --show-origin --show-scope | grep -E "(branch|remote)[.]"
git reflog -4
```

<!-- snippet: ch29/case-wrong-upstream/03-evidence-config -->
```text
$ git config list --show-origin --show-scope | grep -E "(branch|remote)[.]"
local	file:.git/config	remote.origin.url=../server.git
local	file:.git/config	remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
local	file:.git/config	branch.main.remote=origin
local	file:.git/config	branch.main.merge=refs/heads/main
local	file:.git/config	branch.feature/batch-size.remote=origin
local	file:.git/config	branch.feature/batch-size.merge=refs/heads/main
$ git reflog -4
2defa92 HEAD@{0}: commit: Read batch size from the command line
3d6663d HEAD@{1}: commit: Embed in batches
ce76024 HEAD@{2}: checkout: moving from main to feature/batch-size
ce76024 HEAD@{3}: clone: from $LAB/ch29/case-wrong-upstream/server.git
```
<!-- /snippet -->

The configuration holds the cause in one line. Find it before I read it.

**[PAUSE]**

It's the last `branch` line. The `merge` setting of `feature/batch-size` is `refs/heads/main`. And the reflog shows how the branch began: a checkout moving from `main`, right after the clone.

**The toolbox, on this repository, before the fix.** First question: which refs exist, and what do they follow?

```bash
git status -sb
git for-each-ref --format='%(refname) %(objectname:short) %(upstream:short) %(upstream:track)'
git rev-parse --abbrev-ref @{upstream}
git rev-parse --abbrev-ref @{push}
```

<!-- snippet: ch29/case-wrong-upstream/04-toolbox-refs -->
```text
$ git status -sb
## feature/batch-size...origin/main [ahead 2]
$ git for-each-ref --format='%(refname) %(objectname:short) %(upstream:short) %(upstream:track)'
refs/heads/feature/batch-size 2defa92 origin/main [ahead 2]
refs/heads/main ce76024 origin/main 
refs/remotes/origin/HEAD ce76024  
refs/remotes/origin/feature/batch-size 56bb8e4  
refs/remotes/origin/main ce76024  
$ git rev-parse --abbrev-ref @{upstream}
origin/main
$ git rev-parse --abbrev-ref @{push}
fatal: cannot resolve 'simple' push to a single destination
[exit status: 128]
```
<!-- /snippet -->

The `for-each-ref` line prints the whole ref table in a form that can be compared across machines. The last command fails, and the failure is evidence: with `push.default=simple`, a branch whose upstream has another name has no single push destination, so `@{push}` can't be resolved.

Second question: how do the two branches relate?

```bash
git merge-base HEAD origin/feature/batch-size
git rev-list --left-right --count HEAD...origin/feature/batch-size
git log --oneline --left-right HEAD...origin/feature/batch-size
git branch -a --contains origin/feature/batch-size
```

<!-- snippet: ch29/case-wrong-upstream/05-toolbox-graph -->
```text
$ git merge-base HEAD origin/feature/batch-size
ce760245c837e01a35b747b62b701ae9d5cb1593
$ git rev-list --left-right --count HEAD...origin/feature/batch-size
2	1
$ git log --oneline --left-right HEAD...origin/feature/batch-size
> 56bb8e4 Add batch_size to the job config
< 2defa92 Read batch size from the command line
< 3d6663d Embed in batches
$ git branch -a --contains origin/feature/batch-size
  remotes/origin/feature/batch-size
```
<!-- /snippet -->

Two and one: two commits only on the left side, HEAD, and one only on the right. The angle brackets mark the sides commit by commit.

Third question: what does the server hold, and when did this clone learn it?

```bash
git ls-remote origin
git reflog show --date=iso origin/feature/batch-size
git remote show origin
```

<!-- snippet: ch29/case-wrong-upstream/06-toolbox-remote -->
```text
$ git ls-remote origin
ce760245c837e01a35b747b62b701ae9d5cb1593	HEAD
56bb8e470535998cc128a14369042cc79c693292	refs/heads/feature/batch-size
ce760245c837e01a35b747b62b701ae9d5cb1593	refs/heads/main
$ git reflog show --date=iso origin/feature/batch-size
56bb8e4 refs/remotes/origin/feature/batch-size@{2026-09-07 10:18:00 +0530}: pull: storing head
$ git remote show origin
* remote origin
  Fetch URL: ../server.git
  Push  URL: ../server.git
  HEAD branch: main
  Remote branches:
    feature/batch-size tracked
    main               tracked
  Local branches configured for 'git pull':
    feature/batch-size merges with remote main
    main               merges with remote main
  Local refs configured for 'git push':
    feature/batch-size pushes to feature/batch-size (local out of date)
    main               pushes to main               (up to date)
```
<!-- /snippet -->

`git remote show origin` states the mismatch in words: the branch "merges with remote main" and "pushes to feature/batch-size (local out of date)".

Fourth question: what are the objects, and is the store sound?

```bash
git cat-file -t origin/feature/batch-size
git cat-file -p origin/feature/batch-size
git ls-files -s
git fsck
```

<!-- snippet: ch29/case-wrong-upstream/07-toolbox-objects -->
```text
$ git cat-file -t origin/feature/batch-size
commit
$ git cat-file -p origin/feature/batch-size
tree 8b9ee09eac8e63d3b492c654c9f33c6bbcc90b05
parent ce760245c837e01a35b747b62b701ae9d5cb1593
author Asha Rao <asha@example.com> 1788756300 +0530
committer Asha Rao <asha@example.com> 1788756300 +0530

Add batch_size to the job config
$ git ls-files -s
100644 9accc2a36e60234641f858e850d8bc79803512b6 0	jobs/cli.py
100644 091be6421117d3bd69e94e6003f3df9f6043edd7 0	jobs/config.yaml
100644 7295e475b1773f2ed2340186366c638bdde4b92d 0	jobs/embed.py
$ git fsck
```
<!-- /snippet -->

The server's tip is a commit by another author, with `ce76024` as its parent: a teammate's work, based on `main`. The index has three entries, all at stage 0: no conflict is in progress. `git fsck`, which checks the object store, prints nothing.

**Hypotheses and test.** The textbook's four. One: the server's branch has a commit the local branch lacks, and `git pull` integrates a different branch. Two: a rule on the server rejects the push. Three: someone rewrote the server's branch. Four: the pull failed.

```bash
git log --oneline HEAD..origin/feature/batch-size
git config get branch.feature/batch-size.merge
git reflog show origin/feature/batch-size
git merge-tree --write-tree --name-only HEAD origin/feature/batch-size
```

<!-- snippet: ch29/case-wrong-upstream/08-test -->
```text
# H1: the server branch has a commit that the local branch lacks.
$ git log --oneline HEAD..origin/feature/batch-size
56bb8e4 Add batch_size to the job config
# H1: and git pull integrates another branch.
$ git config get branch.feature/batch-size.merge
refs/heads/main
# H3: was the server branch rewritten? Its remote-tracking reflog has one entry, a first fetch.
$ git reflog show origin/feature/batch-size
56bb8e4 refs/remotes/origin/feature/batch-size@{0}: pull: storing head
# Would the two lines of work conflict? A test merge that touches nothing:
$ git merge-tree --write-tree --name-only HEAD origin/feature/batch-size
e2386b3e50aabb629564655df6e66d79d2d11040
[exit status: 0]
```
<!-- /snippet -->

The first hypothesis is confirmed by the first two commands. A rewrite is rejected: the remote-tracking reflog has one entry, a first fetch, and a forced update would have printed a plus sign. A server rule is rejected by the wording of the rejection. And the last command is a test merge: it writes a tree object and touches neither the index nor the working tree. Exit status 0 with no file names means the two lines of work combine without conflict. Show the root-cause box.

**Select the lowest-risk fix.**

| Option | Risk | Verdict |
|---|---|---|
| `git push --force origin feature/batch-size` | 🔴 replaces the server's branch and discards the teammate's commit `56bb8e4` | Rejected. A rejected push is information, not an obstacle |
| `git pull origin feature/batch-size` | 🟡 a one-off integration; stops with "Need to specify how to reconcile divergent branches" unless a mode is given; leaves the wrong upstream in place, so the problem returns | Rejected: treats the state, not the cause |
| Set the upstream, then `git rebase` onto it, then `git push` | 🟡 rewrites two commits that exist nowhere else; adds to the server's branch | Chosen |

Rebasing, which replaces commits with copies on a new base, is acceptable here because the two commits are unpublished: no other repository has them.

**Execute.** A backup ref first, then the configuration change, then the rebase. 🟡 CAUTION: `git rebase` without arguments uses the upstream and replaces the local commits with new ones.

```bash
git branch backup/batch-size-before-rebase
git branch --set-upstream-to=origin/feature/batch-size
git status -sb
git rebase
git log --graph --oneline -4
```

Quick quiz. What will `git status -sb` print right after the upstream change, before the rebase? A, ahead 2. B, ahead 2 and behind 1. C, up to date. Your answer?

**[PAUSE]**

<!-- snippet: ch29/case-wrong-upstream/09-fix -->
```text
$ git branch backup/batch-size-before-rebase
$ git branch --set-upstream-to=origin/feature/batch-size
branch 'feature/batch-size' set up to track 'origin/feature/batch-size'.
$ git status -sb
## feature/batch-size...origin/feature/batch-size [ahead 2, behind 1]
$ git rebase
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/batch-size.
$ git log --graph --oneline -4
* aca1b2f Read batch size from the command line
* 097fe6f Embed in batches
* 56bb8e4 Add batch_size to the job config
* ce76024 Write vectors to the daily bucket
```
<!-- /snippet -->

B. After the upstream change, `git status -sb` already tells the truth: ahead 2, behind 1. No object moved. Only the comparison did.

**[ANIMATION]** step: state-2

Then the rebase puts the two commits on top of the teammate's. The copies have new IDs, `097fe6f` and `aca1b2f`, and the backup branch still names the originals.

```bash
git push --dry-run
git push
```

<!-- snippet: ch29/case-wrong-upstream/10-push -->
```text
$ git push --dry-run
To ../server.git
   56bb8e4..aca1b2f  feature/batch-size -> feature/batch-size
$ git push
To ../server.git
   56bb8e4..aca1b2f  feature/batch-size -> feature/batch-size
```
<!-- /snippet -->

Two dots, no plus sign: a fast-forward of the server's branch.

**Verify.**

<!-- snippet: ch29/case-wrong-upstream/11-verify -->
```text
$ git status
On branch feature/batch-size
Your branch is up to date with 'origin/feature/batch-size'.

nothing to commit, working tree clean
$ git branch -vv
  backup/batch-size-before-rebase 2defa92 Read batch size from the command line
* feature/batch-size              aca1b2f [origin/feature/batch-size] Read batch size from the command line
  main                            ce76024 [origin/main] Write vectors to the daily bucket
$ git rev-parse HEAD @{upstream}
aca1b2fe23a5fed73fb916e3c34ed1ba7095dec0
aca1b2fe23a5fed73fb916e3c34ed1ba7095dec0
$ git ls-remote origin feature/batch-size
aca1b2fe23a5fed73fb916e3c34ed1ba7095dec0	refs/heads/feature/batch-size
$ git range-diff origin/main backup/batch-size-before-rebase HEAD
-:  ------- > 1:  56bb8e4 Add batch_size to the job config
1:  3d6663d = 2:  097fe6f Embed in batches
2:  2defa92 = 3:  aca1b2f Read batch size from the command line
$ git pull
Already up to date.
```
<!-- /snippet -->

The brackets name the right branch. HEAD equals the upstream and the server. `git range-diff` shows the two commits carried over unchanged, marked with an equals sign, on top of one new commit. And `git pull` says "Already up to date" again, this time about the branch you push to.

**Prevent.**

```bash
git branch -D backup/batch-size-before-rebase
git switch -c feature/shard-output --no-track origin/main
git branch -vv
git push
```

🔴 DANGEROUS: `git branch -D`, the label Chapter 30 gives it. What it changes: it deletes a ref without a merge check. What it can destroy: the branch reflog, and the only name of unmerged commits. Preview: `git log <target>..<branch>` and a diff against the target. Recovery: the HEAD reflog, until it expires. The command also prints the ID the branch had. When appropriate: here, after the verification, because the backup has done its job.

<!-- snippet: ch29/case-wrong-upstream/12-prevent -->
```text
$ git branch -D backup/batch-size-before-rebase
Deleted branch backup/batch-size-before-rebase (was 2defa92).
# A new branch from origin/main that does not take origin/main as its upstream:
$ git switch -c feature/shard-output --no-track origin/main
Switched to a new branch 'feature/shard-output'
$ git branch -vv
  feature/batch-size   aca1b2f [origin/feature/batch-size] Read batch size from the command line
* feature/shard-output ce76024 Write vectors to the daily bucket
  main                 ce76024 [origin/main] Write vectors to the daily bucket
$ git push
fatal: The current branch feature/shard-output has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin feature/shard-output

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.

[exit status: 128]
```
<!-- /snippet -->

With `--no-track` the new branch has no upstream, and the first `git push` stops and asks. `push.autoSetupRemote=true` makes that push create the upstream under the branch's own name. The manual for Git 2.55 also documents `branch.autoSetupMerge=simple`: automatic setup "only when the starting point is a remote-tracking branch and the new branch has the same name as the remote branch".

## COMMON MISTAKES

Five mistakes to watch for.

1. **Forcing the push because pulling "did not help".** Root cause: the rejection is read as an obstacle instead of as information that the server's branch holds a commit the local branch lacks.
2. **Assuming pull and push address the same branch.** Root cause: the upstream and the push destination are separate configuration, and a branch created from a remote-tracking branch takes that branch as its upstream.
3. **Skipping the configuration in the diagnosis.** Root cause: configuration is treated as background, when one `branch.<name>.merge` line is the state that explains the symptom.
4. **Fixing with a one-off `git pull origin <branch>`.** Root cause: it repairs today's divergence and leaves the wrong upstream in place, so the symptom returns.
5. **Blaming a server rule.** Root cause: `! [rejected]` is written by the local Git; a rule on the server produces `! [remote rejected]` with `remote:` lines.

## PRODUCTION EXAMPLE

Now, out of the lab. Two engineers on an embeddings team share a feature branch for a week. One created it and pushed it first. The other created a local branch of the same name from `origin/main` and has been committing happily. On the day she first tries to push, the push is rejected, the pull says there's nothing to do, and a senior colleague walking past says: "force it, it is your branch."

She runs `git branch -vv` instead, and reads the brackets. The upstream is `origin/main`. One toolbox command tells her how far apart the two branches are, and another that they merge without conflict. The fix takes three commands and no force: a backup ref, the upstream, a rebase of two commits that exist nowhere else. Her teammate's commit is still on the server.

In the team's notes she records the cause and the prevention in two lines. Feature branches are created with `--no-track`, or from the local `main`. And `push.autoSetupRemote` is set in the team's recommended configuration, so that the first push creates the upstream under the branch's own name.

## PRACTICE EXERCISE

Your turn. Do the second and third repository of Lab 35.1, "The ten-command diagnosis on three repositories", in [`lab-manual/m35-diagnosis-method.md`](../../lab-manual/m35-diagnosis-method.md).

For each, after the ten commands, name the kind of question you still need answered, refs, graph, remote, objects, index or configuration, and pick the toolbox command for it before you look at the table. Predict its output. Then run it. Name the root cause and its layer before any change.

The challenge is Exercise 7.10, Level 5, "the hotfix that was pushed and is not on the server", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q412: "A push is rejected, `git pull` says "Already up to date", and the push is rejected again. Explain the mechanism and the lowest-risk fix."

**[PAUSE]**

Answer out loud. A strong answer explains why both messages can be true at once, which requires naming the two pieces of configuration that the two commands read. It says how the mismatch typically arises and why Git's default is reasonable. It names the evidence: where the mismatch is visible in ordinary output, and which command prints the setting itself. For the fix, it compares at least two options by what each can destroy, rejects the forced push with a reason, and explains under which condition rewriting the local commits is acceptable. It ends with a prevention that changes how branches are created.

## RECAP

Let's land this.

- `git pull` integrates the configured upstream; `git push origin <name>` targets the server branch of that name; the two can differ.
- A branch created from a remote-tracking branch takes it as its upstream unless `--no-track` is given.
- The words in a rejection are evidence: `(fetch first)`, `(non-fast-forward)`, and `! [rejected]` against `! [remote rejected]`.
- The extended toolbox answers one kind of question per command without changing state; `git ls-remote` and `git remote show` ask the server, the rest answer from local data.
- Fix the cause: set the upstream, replay unpublished commits, push without force.

## HOMEWORK

Read sections 29.4 and 29.5. Then, in a repository of your own, run the `git for-each-ref` line of the toolbox and check that every local branch follows the branch you believe it follows. The next video reads operations in progress from `git status` and from the `.git` directory.

Today a message that sounded like a broken server turned into one line of configuration, and you fixed it without force. Run the brackets check on your own branches before the next video. Until then, look at the state first and type second. See you in the next one.
