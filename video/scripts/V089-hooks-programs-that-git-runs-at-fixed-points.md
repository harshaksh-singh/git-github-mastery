# V089: Hooks: programs that Git runs at fixed points

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 14, Worktrees, attributes, hooks, stash internals, rerere
- **Planned minutes.** 24
- **Prerequisites.** V021, V055
- **Textbook sections.** [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md), sections 14C.9 and 14C.10
- **Demo scripts.** `labs/ch14c/hook-tour.sh`, `labs/ch14c/hook-pre-commit.sh`, `labs/ch14c/hook-pre-rebase.sh`, `labs/ch14c/hook-deps.sh`, `labs/ch14c/lab-14-2-commit-msg-hook.sh`, `labs/ch14c/lab-14-3-pre-push-guard.sh`

## HOOK

**[ON SCREEN]** "We have a pre-commit hook that blocks secrets. A secret is on `main`. Whose fault is that?"

A team wrote a hook: a program that Git runs by itself at a fixed point of a command. It works. Stage a private key, run `git commit` to save a snapshot, and the commit is refused. And yet a key is in the history of `main`.

**[ANIMATION]** cards: id=how question=A_pre-commit_hook_blocks_secrets._A_secret_is_on_main._How? cards=A_rebase_or_a_revert_made_the_commit:on_Git_2.55_they_don't_run_pre-commit|The_hook_checked_the_disk:not_the_index|The_clone_never_had_the_hook|One_extra_option:--no-verify numbered=on

How did it get there? Several ways, and none of them needs bad intent. The commit was made by a rebase or a revert, which on Git 2.55 don't run `pre-commit`. Or the author deleted the file from disk and committed again, and a hook that checks the disk instead of the index was satisfied. Or the author's clone never had the hook installed. Or the author typed one extra option: `--no-verify`.

**[ANIMATION]** end

Before you can answer "whose fault", you need to know exactly which hooks run for which command, in which order, and which of them can stop anything. That's today. The answer for the CTO is the next video. Hold on to that word, index.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Hooks belong to the local side of the line this chapter keeps drawing: the hooks folder inside the dot git folder never travels with clone, fetch or push. You've used the things hooks attach to: commit, merge, rebase, checkout, push. Today you watch Git call a program at each of those points.

First the tour, with one tracing script installed under many names. Then the worked hooks: a `pre-commit` that checks the index, Git's list of what goes into the next commit. A `commit-msg` that enforces a convention, a `pre-push` guard, two informational hooks, and a `pre-rebase` that refuses to rewrite published commits.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- name the hooks that run for a commit, a checkout, a merge, a rebase and a push, in order;
- say which hooks can stop an operation and which only observe;
- write a `pre-commit` hook that checks the index and not the working tree;
- write a `commit-msg` hook and a `pre-push` guard;
- explain why a hook that depends on tools must check for them.

## CONCEPT

**[ANIMATION]** hooks: id=commit packet=git_commit gates=pre-commit:pass:can_stop:skipped_by_--no-verify|prepare-commit-msg:pass:can_stop:NOT_skipped_by_--no-verify|commit-msg:pass:can_stop:skipped_by_--no-verify|post-commit:done:observes:the_commit_is_already_written title=git_commit:_each_hook_is_a_gate

**[ANIMATION]** step: commit.4

In one sentence: a hook is an executable file with a fixed name in the hooks directory, or, since Git 2.54, a command named in configuration, that Git runs at a defined point of a command, passing information as arguments and standard input. For some hooks, a non-zero exit status means "stop". The exit status is the number a program returns when it ends, and zero means success.

**[ANIMATION]** say: 28 hook names, in the hooks directory, each an executable file

Now precisely. The hooks manual lists 28 hook names. Git looks for them in `$GIT_DIR/hooks`, or in the directory named by `core.hooksPath`, and ignores files without the executable bit. A hook runs at the top of the working tree, the directory of files you edit, with `GIT_DIR` and related variables exported. `git init` copies inactive samples from the template directory.

**[ON SCREEN]** The client-side rows of the table in section 14C.9 that this video demonstrates.

| Hook | Run by | Arguments | Standard input | Stops? | Skipped by |
|---|---|---|---|---|---|
| `pre-commit` | `git commit`, before the message is obtained | none | none | yes | `--no-verify` |
| `prepare-commit-msg` | `git commit`, after the default message is prepared | message file, source, commit ID | none | yes | nothing |
| `commit-msg` | `git commit`, `git merge` | message file | none | yes | `--no-verify` |
| `post-commit` | `git commit` | none | none | no | nothing |
| `pre-merge-commit` | `git merge`, after a clean automatic merge | none | none | yes | `--no-verify` |
| `post-merge` | `git merge` and so `git pull`, after success | squash flag | none | no | nothing |
| `pre-rebase` | `git rebase` | upstream, branch (absent for the current one) | none | yes | `--no-verify` |
| `post-rewrite` | `git commit --amend`, `git rebase` | `amend` or `rebase` | per commit: old ID, new ID | no | nothing |
| `post-checkout` | `git switch`, `git checkout`, `git restore` from a commit, `git clone`, `git worktree add` | old HEAD, new HEAD, flag (1 branch, 0 file) | none | no; its status becomes the command's | nothing |
| `pre-push` | `git push`, before anything is sent | remote name, URL | per ref: local ref, local ID, remote ref, remote ID | yes | `--no-verify` |

For each hook, four facts matter: which command runs it, what it receives as arguments and on standard input, whether a non-zero exit stops the command, and what skips it.

**[ANIMATION]** hooks: id=push packet=git_push gates=pre-push:pass:can_stop:skipped_by_--no-verify|pre-receive:pass:can_stop:the_whole_push,_once_per_push|update:pass:can_stop:one_ref,_once_per_pushed_ref|post-receive:done:observes|post-update:done:observes zones=your_clone,the_other_repository_(git_receive-pack) split=1 title=git_push:_two_sides_of_a_boundary

On the server side, `git receive-pack` runs `pre-receive` once per push before any ref is updated, `update` once per pushed ref, and `post-receive` and `post-update` afterwards. A ref is a name such as a branch. Nothing on the client skips those hooks. An all-zero object ID in these inputs means "does not exist": the ref is being created, on the old side, or deleted, on the new side.

**[ANIMATION]** end

Three design rules for hooks you write.

**[ANIMATION]** trees: state=3,2,1 versions=last_commit,staged,on_disk steps=setup,commit history=off title=Rule_one:_a_commit_is_made_from_the_index say_setup=What_is_on_disk_can_differ_from_what_is_staged say_commit=The_commit_takes_what_is_staged,_not_what_is_on_disk

Rule one. A commit is made from the index, so a `pre-commit` hook reads the index, not the files on disk. That means `git diff --cached` for content, and `git cat-file -s` on the staged path for sizes.

**[ANIMATION]** end

Rule two. A "pre" hook that can stop should be fast. The textbook's sentence is: use client-side hooks for fast feedback to the person at the keyboard, and keep them fast, or people learn the bypass.

Rule three. A hook is a program on a machine you don't control. If it needs a tool, it must check that the tool is there, and decide what a missing tool means. The same care goes for its exit status. A `post-checkout` hook can't undo a switch, but its exit status becomes the status of the command, so a failing hook breaks scripts that test `git switch`.

And when should you not rely on a hook? Whenever the check must hold for everyone. A hook that "checks every commit" checks the commits made by `git commit` and `git merge`. That's the subject of the next video.

## MENTAL MODEL

**[ANIMATION]** replay: push

The textbook's analogy: tripwires in your own workshop. You place them. They do nothing in a colleague's workshop. And you can step over them.

The analogy fits client-side hooks. It breaks for server-side ones, which sit at the door that every delivery must pass.

Keep the two kinds apart for the rest of the course. A tripwire gives fast feedback to the person in the workshop. A check at the door is the only thing that inspects every delivery.

## DIAGRAM

**[DIAGRAM]** Two timelines with each hook as a gate. Mark each gate "can stop" or "observes".

```text
  git commit
  ---[pre-commit]------[prepare-commit-msg]------[commit-msg]------ commit object written ------[post-commit]--->
      can stop          can stop                  can stop                                       observes
      skipped by        NOT skipped by            skipped by
      --no-verify       --no-verify               --no-verify

  git push                                             |   the other repository (git receive-pack)
  ---[pre-push]----------- objects and refs sent ------|---[pre-receive]----[update]---- refs updated ----[post-receive]--[post-update]
      can stop                                         |    can stop the     can stop                      observe
      skipped by --no-verify                           |    whole push       one ref
      reads one line per ref on standard input         |    nothing on the client skips these
```

On the first line, three gates can stop a commit and `--no-verify` opens two of them. On the second line, the vertical bar is the boundary between your clone and the other repository. Everything left of it is yours to skip. Everything right of it isn't.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14c/hook-tour`.

```bash
ls .git/hooks
```

<!-- snippet: ch14c/hook-tour/01-samples -->
```text
$ ls .git/hooks
applypatch-msg.sample
commit-msg.sample
fsmonitor-watchman.sample
post-update.sample
pre-applypatch.sample
pre-commit.sample
pre-merge-commit.sample
pre-push.sample
pre-rebase.sample
pre-receive.sample
prepare-commit-msg.sample
push-to-checkout.sample
sendemail-validate.sample
update.sample
```
<!-- /snippet -->

Samples, all with the suffix `.sample`, all inactive. Now one tracing script is installed under ten client-side names and four server-side names.

```bash
cat .git/hooks/pre-commit
```

<!-- snippet: ch14c/hook-tour/02-install -->
```text
$ cat .git/hooks/pre-commit
#!/bin/sh
# Installed under many hook names: print the name, the arguments and the standard input.
name=$(basename "$0")
echo "[$name] args: $*"
case "$name" in
  pre-push|pre-receive|post-receive|post-rewrite) sed "s/^/[$name] stdin: /" ;;
esac
exit 0
# The same script under every client-side name of interest, and four names on the server:
$ cd .git/hooks && for h in prepare-commit-msg commit-msg post-commit pre-merge-commit post-merge post-checkout pre-rebase post-rewrite pre-push; do cp pre-commit $h; done; cd ../..
$ for h in pre-receive update post-receive post-update; do cp .git/hooks/pre-commit ../server.git/hooks/$h; done
$ chmod +x .git/hooks/* ../server.git/hooks/*
```
<!-- /snippet -->

It prints its own name, its arguments and, for some hooks, its standard input, and exits with 0. Your first prediction: how many hooks does a plain `git commit -m` run, and in which order? Say it out loud. I'll wait.

**[PAUSE]**

```bash
git commit -m "Add router"
```

<!-- snippet: ch14c/hook-tour/03-commit -->
```text
$ printf 'def route(request):\n    return upstream(request)\n' > router.py && git add router.py
$ git commit -m "Add router"
[pre-commit] args: 
[prepare-commit-msg] args: .git/COMMIT_EDITMSG message
[commit-msg] args: .git/COMMIT_EDITMSG
[post-commit] args: 
[main (root-commit) 3f5eb96] Add router
 1 file changed, 2 insertions(+)
 create mode 100644 router.py
```
<!-- /snippet -->

Four, in this order: `pre-commit`, `prepare-commit-msg`, `commit-msg`, `post-commit`. `prepare-commit-msg` received the message file and the word "message": it learned that the message came from `-m`.

```bash
git commit --amend -m "Add request router"
```

<!-- snippet: ch14c/hook-tour/04-amend -->
```text
$ git commit --amend -m "Add request router"
[pre-commit] args: 
[prepare-commit-msg] args: .git/COMMIT_EDITMSG message
[commit-msg] args: .git/COMMIT_EDITMSG
[post-commit] args: 
[post-rewrite] args: amend
[post-rewrite] stdin: 3f5eb9642223832c879d35738acfdecb6e70042d 9533ef0c056b35d8b7869ef013c63c330b112994
[main 9533ef0] Add request router
 Date: Mon Sep 7 10:12:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 router.py
```
<!-- /snippet -->

The same four, and then `post-rewrite` with the argument `amend`, and on standard input the old commit ID and the new one.

**[ANIMATION]** graph: 3f5eb96 main; HEAD=main => 9533ef0 main; HEAD=main; reflog:3f5eb96 title=An_amend_writes_a_new_commit at_state_1=12 at_state_2=38

**[ANIMATION]** step: state-2

Two IDs, because an amend writes a new commit that takes the place of the old one.

```bash
git switch -c feature/timeouts
git switch main
git restore --source=feature/timeouts limits.yaml
```

<!-- snippet: ch14c/hook-tour/05-checkout -->
```text
$ git switch -c feature/timeouts
Switched to a new branch 'feature/timeouts'
[post-checkout] args: 9533ef0c056b35d8b7869ef013c63c330b112994 9533ef0c056b35d8b7869ef013c63c330b112994 1
$ git switch main
Switched to branch 'main'
[post-checkout] args: a9d0f65fdda8978f82efaaee132e7ecd93270647 9533ef0c056b35d8b7869ef013c63c330b112994 1
# Restoring a file from a commit is a "file checkout": the last argument is 0.
$ git restore --source=feature/timeouts limits.yaml
[post-checkout] args: 9533ef0c056b35d8b7869ef013c63c330b112994 9533ef0c056b35d8b7869ef013c63c330b112994 0
```
<!-- /snippet -->

`post-checkout` receives the previous HEAD, meaning where you were, the new HEAD and a flag. Creating a branch doesn't change the commit, so both IDs are equal. Restoring a file from a commit is a "file checkout": the flag is 0.

```bash
git merge feature/timeouts
```

<!-- snippet: ch14c/hook-tour/06-merge -->
```text
$ git merge feature/timeouts
[pre-merge-commit] args: 
[prepare-commit-msg] args: .git/MERGE_MSG merge
[commit-msg] args: .git/MERGE_MSG
Merge made by the 'ort' strategy.
 limits.yaml | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 limits.yaml
[post-merge] args: 0
```
<!-- /snippet -->

A merge runs `pre-merge-commit` in place of `pre-commit`, and `post-merge` at the end.

Now a rebase that replays one commit, which means it makes a copy with a new ID. Do `pre-commit` and `commit-msg` run for the replayed commit? Predict. I'll wait.

**[PAUSE]**

```bash
git rebase main
```

<!-- snippet: ch14c/hook-tour/07-rebase -->
```text
$ git rebase main
[pre-rebase] args: main
[post-checkout] args: 76794b68b300e425c07a0027a44a530b5df0129b 12328180f791c3157820266ae1969bc1189457a4 1
Rebasing (1/1)
[prepare-commit-msg] args: .git/COMMIT_EDITMSG message
[post-commit] args: 
[post-rewrite] args: rebase
[post-rewrite] stdin: 76794b68b300e425c07a0027a44a530b5df0129b 927de69e6948cd33c8e970e5ddb2af33f79a99a9
Successfully rebased and updated refs/heads/feature/retries.
```
<!-- /snippet -->

They don't. `pre-rebase` ran once and `post-rewrite` once.

**[ANIMATION]** stores: id=ran boxes=git_commit:four_hooks|git_rebase:the_replayed_commit|git_commit_--no-verify:the_extra_option rows=1:A:pre-commit|1:A:prepare-commit-msg|1:A:commit-msg|1:A:post-commit|2:B:pre-commit_did_not_run@dim|2:B:prepare-commit-msg@ok|2:B:commit-msg_did_not_run@dim|2:B:post-commit@ok|3:C:pre-commit_skipped@dim|3:C:prepare-commit-msg@ok|3:C:commit-msg_skipped@dim|3:C:post-commit@ok mono=on title=Which_hooks_ran

**[ANIMATION]** step: ran.2

For the replayed commit, `prepare-commit-msg` and `post-commit` ran. `pre-commit` and `commit-msg` didn't. If you expected them to run, that's normal. The textbook adds that `git revert`, which adds a commit that undoes another, behaves the same on Git 2.55. This is the first answer to our opening question.

```bash
git push origin main
```

<!-- snippet: ch14c/hook-tour/08-push -->
```text
$ git push origin main
[pre-push] args: origin ../server.git
[pre-push] stdin: refs/heads/main 12328180f791c3157820266ae1969bc1189457a4 refs/heads/main 0000000000000000000000000000000000000000
remote: [pre-receive] args:         
remote: [pre-receive] stdin: 0000000000000000000000000000000000000000 12328180f791c3157820266ae1969bc1189457a4 refs/heads/main        
remote: [update] args: refs/heads/main 0000000000000000000000000000000000000000 12328180f791c3157820266ae1969bc1189457a4        
remote: [post-receive] args:         
remote: [post-receive] stdin: 0000000000000000000000000000000000000000 12328180f791c3157820266ae1969bc1189457a4 refs/heads/main        
remote: [post-update] args: refs/heads/main        
To ../server.git
 * [new branch]      main -> main
```
<!-- /snippet -->

`pre-push` ran in your clone, with the remote name and URL as arguments and one line for the ref on standard input. The remote ID is all zeros because the branch is new there.

**[ANIMATION]** step: push.5

The lines that start with "remote:" were printed by hooks in the other repository and sent back: `pre-receive`, `update`, `post-receive`, `post-update`.

**[ANIMATION]** end

Try it now, on paper, thirty seconds. Write the four commit hooks in order, then cross out the ones you predict `--no-verify` skips.

**[PAUSE]**

```bash
git commit --no-verify --allow-empty -m "Skip the checks"
```

<!-- snippet: ch14c/hook-tour/09-no-verify -->
```text
$ git commit --no-verify --allow-empty -m "Skip the checks"
[prepare-commit-msg] args: .git/COMMIT_EDITMSG message
[post-commit] args: 
[main cc3cbfb] Skip the checks
```
<!-- /snippet -->

Check your paper. `--no-verify` skipped `pre-commit` and `commit-msg`.

**[ANIMATION]** step: ran.3

`prepare-commit-msg` and `post-commit` still ran. Of these two, `prepare-commit-msg` can still stop a commit by exiting non-zero, with or without `--no-verify`. The textbook confirmed that by a run on Git 2.55.0.

**[TERMINAL]** Replay `labs/run ch14c/hook-pre-commit`. The first worked hook.

```bash
cat .git/hooks/pre-commit
```

<!-- snippet: ch14c/hook-pre-commit/01-hook -->
```text
$ cat .git/hooks/pre-commit
#!/bin/sh
# pre-commit: look at what is STAGED (the index), not at the files on disk.
# Refuse a commit that adds a private key or a file larger than 500 kB.
fail=0

if git diff --cached -U0 | grep -q '^+.*-----BEGIN [A-Z ]*PRIVATE KEY-----'; then
  echo "pre-commit: a private key is staged. Unstage it and rotate the key." >&2
  fail=1
fi

limit=512000
for path in $(git diff --cached --name-only --diff-filter=AM); do
  size=$(git cat-file -s ":$path")
  if [ "$size" -gt "$limit" ]; then
    echo "pre-commit: $path is $size bytes (limit $limit). Use Git LFS or a data store." >&2
    fail=1
  fi
done

exit $fail
$ chmod +x .git/hooks/pre-commit
```
<!-- /snippet -->

This hook looks at what is staged: `git diff --cached` for a private-key header, and the size of each staged file. Now a deploy key and a 600 kilobyte checkpoint are staged together with a real change.

```bash
git add .
git commit -m "Log runs to the tracker"
```

<!-- snippet: ch14c/hook-pre-commit/02-blocked -->
```text
# A deploy key and a 600 kB checkpoint are staged together with a real change:
$ printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-key\n-----END OPENSSH PRIVATE KEY-----\n' > deploy_key
$ head -c 600000 /dev/zero > checkpoint.pt
$ printf 'import torch\nimport wandb\n' > train.py
$ git add .
$ git commit -m "Log runs to the tracker"
pre-commit: a private key is staged. Unstage it and rotate the key.
pre-commit: checkpoint.pt is 600000 bytes (limit 512000). Use Git LFS or a data store.
[exit status: 1]
$ git log --oneline
8d50bdb Add training script
```
<!-- /snippet -->

Two messages on standard error, exit status 1, no commit. Now the developer deletes the two files from disk and tries again. Quick quiz: does the commit go through now, or is it refused again? Say it out loud.

**[PAUSE]**

```bash
rm deploy_key checkpoint.pt
git commit -m "Log runs to the tracker"
git restore --staged deploy_key checkpoint.pt
git commit -m "Log runs to the tracker"
```

<!-- snippet: ch14c/hook-pre-commit/03-index-not-disk -->
```text
# The hook reads the index. Deleting the files on disk is not enough:
$ rm deploy_key checkpoint.pt
$ git commit -m "Log runs to the tracker"
pre-commit: a private key is staged. Unstage it and rotate the key.
pre-commit: checkpoint.pt is 600000 bytes (limit 512000). Use Git LFS or a data store.
[exit status: 1]
$ git restore --staged deploy_key checkpoint.pt
$ git commit -m "Log runs to the tracker"
[main 6053c0f] Log runs to the tracker
 1 file changed, 1 insertion(+)
[exit status: 0]
```
<!-- /snippet -->

Refused again. The hook reads the index, and the files are still staged. Only after `git restore --staged` does the commit go through.

**[ANIMATION]** trees: file=deploy_key chips=deleted,still_staged,not_committed commits=8d50bdb,6053c0f steps=setup title=Where_a_pre-commit_hook_must_look say_setup=The_commit_is_made_from_the_index,_not_from_the_disk

On disk, `deploy_key` is gone. In the index it's still staged. A hook that had looked at the disk would have let the key into the commit. That's the index, paid off. Know the limits of this hook, though: file names without spaces only, one secret pattern, and one option removes it.

```bash
git add deploy_key
git commit --no-verify -m "Add deploy key"
git show --stat --format=%s HEAD
```

<!-- snippet: ch14c/hook-pre-commit/04-no-verify -->
```text
$ printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-key\n-----END OPENSSH PRIVATE KEY-----\n' > deploy_key
$ git add deploy_key
$ git commit --no-verify -m "Add deploy key"
[main 86a145d] Add deploy key
 1 file changed, 3 insertions(+)
 create mode 100644 deploy_key
[exit status: 0]
$ git show --stat --format=%s HEAD
Add deploy key

 deploy_key | 3 +++
 1 file changed, 3 insertions(+)
```
<!-- /snippet -->

Exit status 0. The key is committed.

**[TERMINAL]** Replay `labs/run ch14c/lab-14-2-commit-msg-hook`. A `commit-msg` hook receives the name of the file that holds the proposed message, and may edit or refuse it.

```bash
git commit -am "updated scorer"
git status -s
git log --oneline -1
```

<!-- snippet: ch14c/lab-14-2-commit-msg-hook/02-refuse-and-accept -->
```text
$ printf 'def exact(pred, gold):\n    return pred.strip() == gold.strip()\n' > metrics.py
$ git commit -am "updated scorer"
commit-msg: the subject must look like 'fix(scorer): handle empty labels'
commit-msg: got: updated scorer
[exit status: 1]
$ git status -s
 M metrics.py
$ git log --oneline -1
1b79baa docs: describe the metrics module
$ git commit -am "fix(metrics): ignore surrounding whitespace"
[main 6757929] fix(metrics): ignore surrounding whitespace
 1 file changed, 1 insertion(+), 1 deletion(-)
[exit status: 0]
```
<!-- /snippet -->

Refused, with the expected form and the subject it got. Then look at `git status -s`: the change shows as unstaged. `git commit -a` stages into a temporary index and discards it when the commit fails. The lab also shows the classic defect of such hooks. They refuse the subjects that Git writes itself, "Merge branch" and "fixup!", and a merge then stops half-way.

**[TERMINAL]** Replay `labs/run ch14c/lab-14-3-pre-push-guard`. Standard input has one line per ref. This hook refuses to delete `main`, to rewrite it, and to push commits whose subject starts with WIP, fixup! or squash! to it.

```bash
git switch -q main
git merge -q --ff-only feature/limits
git push origin main
git status -sb
```

<!-- snippet: ch14c/lab-14-3-pre-push-guard/03-main-refused -->
```text
$ git switch -q main
$ git merge -q --ff-only feature/limits
$ git push origin main
pre-push: unfinished commits must not reach main:
  6378124 WIP: per-tenant limits, quota still undecided
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git status -sb
## main...origin/main [ahead 2]
```
<!-- /snippet -->

The push is refused before anything is sent, and the hook names the unfinished commit. `main` is still two ahead.

**[TERMINAL]** Replay `labs/run ch14c/hook-deps`. Two hooks that cannot stop anything: they tell the developer what changed.

```bash
cat .git/hooks/post-checkout
cat .git/hooks/post-merge
```

<!-- snippet: ch14c/hook-deps/01-hooks -->
```text
$ cat .git/hooks/post-checkout
#!/bin/sh
# post-checkout <old-HEAD> <new-HEAD> <flag>: flag 1 is a branch checkout, 0 a file checkout.
# Tell the developer when the dependency lock file differs between the two commits.
[ "$3" = 1 ] || exit 0
if ! git diff --quiet "$1" "$2" -- requirements.lock; then
  echo "post-checkout: requirements.lock changed. Run: pip install -r requirements.lock"
fi
$ cat .git/hooks/post-merge
#!/bin/sh
# post-merge <squash-flag>: runs after a merge that succeeded, which includes "git pull".
# ORIG_HEAD is the commit the branch was on before the merge.
if ! git diff --quiet ORIG_HEAD HEAD -- requirements.lock; then
  echo "post-merge: requirements.lock changed. Run: pip install -r requirements.lock"
fi
```
<!-- /snippet -->

The hook uses its three arguments: it exits at once for a file checkout, and compares the lock file between the old and the new HEAD.

```bash
git switch feature/tracing
git switch main
git restore --source=feature/tracing app.py
```

<!-- snippet: ch14c/hook-deps/02-checkout -->
```text
$ git switch feature/tracing
Switched to branch 'feature/tracing'
post-checkout: requirements.lock changed. Run: pip install -r requirements.lock
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
post-checkout: requirements.lock changed. Run: pip install -r requirements.lock
# A file checkout calls the hook with flag 0, and the hook stays silent:
$ git restore --source=feature/tracing app.py
```
<!-- /snippet -->

```bash
git pull
```

<!-- snippet: ch14c/hook-deps/03-pull -->
```text
$ git pull
From $LAB/ch14c/hook-deps/server
   8848493..977e90f  main       -> origin/main
Updating 8848493..977e90f
Fast-forward
 requirements.lock | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
post-merge: requirements.lock changed. Run: pip install -r requirements.lock
```
<!-- /snippet -->

The pull was a fast-forward, with no merge commit, and `post-merge` ran all the same. Now the exit status.

```bash
printf '#!/bin/sh\nexit 3\n' > .git/hooks/post-checkout
git switch feature/tracing
git status -sb
```

<!-- snippet: ch14c/hook-deps/04-exit-status -->
```text
# post-checkout cannot undo the switch, but its exit status becomes the exit status of the command:
$ printf '#!/bin/sh\nexit 3\n' > .git/hooks/post-checkout
$ git switch feature/tracing
Switched to branch 'feature/tracing'
[exit status: 1]
$ git status -sb
## feature/tracing
```
<!-- /snippet -->

The hook exited with 3, `git switch` exited with 1, and the branch was switched. Think of a hook that calls a tool which isn't installed on this machine. The command "fails", the switch has happened, and every script that tests the status of `git switch` breaks. That's why a hook that depends on tools must check for them, and exit 0 with a message when they're missing.

**[TERMINAL]** Replay `labs/run ch14c/hook-pre-rebase`.

```bash
cat .git/hooks/pre-rebase
```

<!-- snippet: ch14c/hook-pre-rebase/01-hook -->
```text
$ cat .git/hooks/pre-rebase
#!/bin/sh
# pre-rebase <upstream> [<branch>]: <branch> is absent when the current branch is rebased.
# Refuse to rebase commits that a remote-tracking branch already contains.
upstream=$1
branch=${2:-HEAD}
all=$(git rev-list --count "$upstream..$branch")
unpublished=$(git rev-list --count "$upstream..$branch" --not --remotes)
if [ "$all" != "$unpublished" ]; then
  echo "pre-rebase: $((all - unpublished)) of $all commits are already on a remote." >&2
  echo "pre-rebase: rebasing them rewrites published history (Chapter 9)." >&2
  exit 1
fi
$ git log --oneline --graph --all
* eb2bc26 Add README
| * 6c7937a Add version endpoint
|/  
| * 8cd8387 Add health endpoint
|/  
* 0443504 Add service skeleton
```
<!-- /snippet -->

It counts the commits to be rebased, and the ones among them that no remote-tracking branch contains.

**[ANIMATION]** graph: id=rb 0443504-eb2bc26 main; ^0443504-6c7937a feature/local; 0443504-8cd8387 feature/shared origin/feature/shared; HEAD=main; say:Only_feature/shared_is_on_a_remote => 0443504-eb2bc26 main; ^0443504-6c7937a; ^eb2bc26-?copy_of_6c7937a feature/local; eb2bc26-?copy_of_8cd8387 feature/shared; 0443504-8cd8387 origin/feature/shared; HEAD=feature/shared; reflog:6c7937a; name:after; say:feature/shared:_ahead_2,_behind_1; cmd:git_rebase_--no-verify_main dx=250

**[ANIMATION]** step: rb.state-1

A remote-tracking branch records where a branch was on the server. If the numbers differ, some are published.

<!-- snippet: ch14c/hook-pre-rebase/02-local-branch -->
```text
$ git switch -q feature/local
$ git rebase main
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/local.
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch14c/hook-pre-rebase/03-published-branch -->
```text
$ git switch -q feature/shared
$ git rebase main
pre-rebase: 1 of 1 commits are already on a remote.
pre-rebase: rebasing them rewrites published history (Chapter 9).
error: The pre-rebase hook refused to rebase.
[exit status: 1]
$ git status -sb
## feature/shared...origin/feature/shared
```
<!-- /snippet -->

The local branch was rebased. The pushed one wasn't: "The pre-rebase hook refused to rebase." And the usual door:

```bash
git rebase --no-verify main
git status -sb
```

<!-- snippet: ch14c/hook-pre-rebase/04-no-verify -->
```text
$ git rebase --no-verify main
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/shared.
[exit status: 0]
$ git status -sb
## feature/shared...origin/feature/shared [ahead 2, behind 1]
```
<!-- /snippet -->

Rebased. The branch is now 2 ahead of and 1 behind its upstream.

**[ANIMATION]** step: rb.after

Here it is as a picture: the state the rebase module warned you about.

## COMMON MISTAKES

Five mistakes to watch for.

1. **A `pre-commit` hook that inspects files on disk.** Root cause: a commit is made from the index; what is staged can differ from what is on disk in both directions.
2. **Believing a `pre-commit` or `commit-msg` hook checks every commit.** Root cause: on Git 2.55 the commits replayed by a rebase, and those made by a revert, run neither.
3. **A `commit-msg` pattern that rejects Git's own subjects.** Root cause: merges and fixup commits have generated subjects, and the hook stops a merge half-way.
4. **A `post-checkout` hook that exits non-zero when a tool is missing.** Root cause: its exit status becomes the status of `git switch` although the switch has happened.
5. **A slow "pre" hook.** Root cause: it runs at every commit for the person at the keyboard; people learn `--no-verify`, and then no check runs at all.

## PRODUCTION EXAMPLE

Now, out of the lab. An ML platform team installs four hooks in its service repositories. A `pre-commit` that checks staged content for key headers and for files above a size limit, with a message that points to Git LFS or the data store. A `commit-msg` hook for the subject convention, which lets through the subjects that Git writes itself. A `post-checkout` and `post-merge` pair that says when the dependency lock file changed, and that exits 0 with a note when the comparison can't be made. And a `pre-push` guard that keeps commits whose subject starts with WIP off `main`.

**[ANIMATION]** replay: push

Every one of them gives feedback in under a second. None of them is described in the team's documentation as a control. The team knows which commits bypass them and that one option skips them, so the same checks run again where every push arrives. That placement is the next video.

## PRACTICE EXERCISE

Your turn. Do Lab 14.2, "A commit-msg hook", in [`lab-manual/m14-hooks-rerere-attributes.md`](../../lab-manual/m14-hooks-rerere-attributes.md).

Before each commit in the lab, predict whether the hook accepts the message, and what `git status -s` shows after a refusal. Before you merge and before you revert, predict which hooks run. The lab's failure scenario stops a merge half-way. Predict the state of the repository at that moment.

The challenge is Lab 14.3, "A pre-push guard", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q424: "Which hooks run for `git commit`, in which order, and which does `--no-verify` skip? Which commit-creating commands run none of the checking hooks?"

**[PAUSE]**

Answer out loud. A strong answer gives four names in order and says for each whether it can stop the commit. It divides them by the `--no-verify` flag, and notices the one hook that can still stop a commit when the flag is given. For the second half it names commands, says which hooks they do run, and is careful about the version. Then it draws the conclusion the question aims at: what a client-side hook can and can't be used for.

## RECAP

**[ANIMATION]** trees: file=deploy_key chips=deleted,still_staged,not_committed commits=8d50bdb,6053c0f steps=setup title=Where_a_pre-commit_hook_must_look say_setup=The_commit_is_made_from_the_index,_not_from_the_disk

Let's land this. One picture to keep: gone from disk, still staged.

You should now be able to say:

- A hook is a program Git runs at a fixed point with defined arguments and standard input; a non-zero exit from some hooks stops the command.
- `git commit` runs `pre-commit`, `prepare-commit-msg`, `commit-msg`, `post-commit`; `--no-verify` skips the first and the third.
- A rebase and a revert create commits without running `pre-commit` or `commit-msg` on Git 2.55.
- A `pre-commit` hook must read the index; a `pre-push` hook reads one line per ref.
- `post-checkout` and `post-merge` observe, and a hook that needs a tool must behave sensibly without it.

## HOMEWORK

Read sections 14C.9 and 14C.10 of [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md). Do Exercise 14.3, Level 1, "A pre-commit hook, and its limit", and Exercise 14.6, Level 2, command prediction, "Which hooks run", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Today you watched Git call a program at every gate, and predicted which gates can stop. Practise with the labs first. Next time: why hooks can't enforce policy. Until then, look at the state first and type second. See you in the next one.
