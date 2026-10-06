# Module 14 labs: Hooks, rerere, attributes and stash anatomy

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch14c/`. Read [Chapter 14C: Stash Internals, Rerere, Attributes, Hooks](../textbook/ch14c-stash-rerere-attributes-hooks.md) first. Lab 14.1 (a hotfix in a second worktree) belongs to Chapter 25 and has its own file.

## How to run these labs

Each lab has a setup script that builds its starting state in the hands-on sandbox, and a replay script that runs the whole lab with a fixed clock and produced the transcripts below. From the course root:

```bash
bash labs/ch14c/setup-14-2-commit-msg-hook.sh    # build the starting state (run again to start over)
labs/shell m14-2                                 # open the isolated lab shell in that sandbox
labs/run ch14c/lab-14-2-commit-msg-hook          # optional: replay the whole lab and print its transcript
```

Five things to know:

- **IDs.** Commits that exist when you enter the sandbox have the IDs printed here, because the setup scripts use the fixed lab clock. Commits and stash entries that you create get the real time and other IDs. Blob IDs depend only on content and always match.
- **Exit statuses.** Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command.
- **Hooks stay in the sandbox.** Every hook in these labs is written into a repository under the lab root. Nothing touches the hooks or the configuration of your real repositories.
- **Editors.** `git rebase --continue` after a conflict opens your editor with the commit message: save and close. The replays use an editor that accepts the message as it is.
- **Hook and filter scripts are provided.** The setup scripts place them next to the repository (or track them inside it) so that you do not have to type forty lines without a mistake. Read every line before you install one: that is the lab.

| Lab | Topic | Sandbox | Replay |
|---|---|---|---|
| 14.2 | A commit-msg hook | `m14-2` | `ch14c/lab-14-2-commit-msg-hook` |
| 14.3 | A pre-push guard, and the server-side rule that replaces it | `m14-3` | `ch14c/lab-14-3-pre-push-guard` |
| 14.4 | A clean and smudge filter that stores pointers | `m14-4` | `ch14c/lab-14-4-clean-smudge-filter` |
| 14.5 | Rerere: resolve once | `m14-5` | `ch14c/lab-14-5-rerere-resolve-once` |
| 14.6 | Stash anatomy | `m14-6` | `ch14c/lab-14-6-stash-anatomy` |

Answers to the questions are in [solutions/m14-lab-answers.md](../solutions/m14-lab-answers.md). Write your own first.

## Lab 14.2: A commit-msg hook

### Objective

Install a `commit-msg` hook that enforces a subject convention, watch it refuse and accept, test it without making commits, and learn its two bypasses. Then meet the defect that most hand-written message hooks have, a merge that stops half-way, and repair it.

### Prerequisites

- Chapter 14C, sections 14C.9 to 14C.11.
- Chapter 8 (Merge) for what a merge commit is.

### Setup

```bash
bash labs/ch14c/setup-14-2-commit-msg-hook.sh
labs/shell m14-2
cd evalkit
```

The script builds `evalkit` with `main` and `feat/f1`, one commit each beyond their common start, and a directory `hooks` next to the repository with two files: `commit-msg` and a corrected version `commit-msg.v2`.

### Commands

Step 1. Read the hook, then install it. A hook is a file with the right name and the executable bit.

```bash
git log --oneline --graph --all
cat ../hooks/commit-msg
cp ../hooks/commit-msg .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg
```

Step 2. Predict which of the two commits is accepted, then try both.

```bash
printf 'def exact(pred, gold):\n    return pred.strip() == gold.strip()\n' > metrics.py
git commit -am "updated scorer"
git status -s
git log --oneline -1
git commit -am "fix(metrics): ignore surrounding whitespace"
```

Step 3. The second rule of the hook is a length limit.

```bash
git commit --allow-empty -m "chore: rerun the full evaluation suite after the whitespace fix landed on main"
```

Step 4. Test the hook without committing. `git hook run` calls it the way `git commit` would, with a message file as its argument.

```bash
printf 'wip\n' > ../msg.txt
git hook run commit-msg -- ../msg.txt
printf 'test(metrics): cover empty input\n\nThe scorer crashed on an empty prediction.\n' > ../msg.txt
git hook run commit-msg -- ../msg.txt
```

Step 5. The two ways around it.

```bash
git commit --allow-empty --no-verify -m "wip"
chmod -x .git/hooks/commit-msg
git commit --allow-empty -m "another wip"
chmod +x .git/hooks/commit-msg
git log --oneline -3
```

Step 6. Which commands run this hook at all? Revert the fix.

```bash
git revert --no-edit HEAD~2
git log --oneline -1
```

### Expected output

<!-- snippet: ch14c/lab-14-2-commit-msg-hook/01-install -->
```text
$ cd evalkit
$ git log --oneline --graph --all
* 1b79baa docs: describe the metrics module
| * f9fdfef feat(metrics): add F1
|/  
* 603a01d feat(metrics): add exact match
$ cat ../hooks/commit-msg
#!/bin/sh
# commit-msg <file>: <file> holds the proposed commit message. A non-zero exit refuses the commit.
# Rule: the subject looks like "type(scope): summary" and is at most 72 characters long.
subject=$(sed -n '1p' "$1")
pattern='^(feat|fix|docs|test|refactor|chore)(\([a-z0-9-]+\))?: .+'
if ! printf '%s\n' "$subject" | grep -Eq "$pattern"; then
  echo "commit-msg: the subject must look like 'fix(scorer): handle empty labels'" >&2
  echo "commit-msg: got: $subject" >&2
  exit 1
fi
if [ "${#subject}" -gt 72 ]; then
  echo "commit-msg: the subject has ${#subject} characters, the limit is 72" >&2
  exit 1
fi
$ cp ../hooks/commit-msg .git/hooks/commit-msg
$ chmod +x .git/hooks/commit-msg
```
<!-- /snippet -->

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

<!-- snippet: ch14c/lab-14-2-commit-msg-hook/03-length -->
```text
$ git commit --allow-empty -m "chore: rerun the full evaluation suite after the whitespace fix landed on main"
commit-msg: the subject has 78 characters, the limit is 72
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-2-commit-msg-hook/04-test-without-committing -->
```text
$ printf 'wip\n' > ../msg.txt
$ git hook run commit-msg -- ../msg.txt
commit-msg: the subject must look like 'fix(scorer): handle empty labels'
commit-msg: got: wip
[exit status: 1]
$ printf 'test(metrics): cover empty input\n\nThe scorer crashed on an empty prediction.\n' > ../msg.txt
$ git hook run commit-msg -- ../msg.txt
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-2-commit-msg-hook/05-bypass -->
```text
$ git commit --allow-empty --no-verify -m "wip"
[main 4f0621c] wip
$ chmod -x .git/hooks/commit-msg
$ git commit --allow-empty -m "another wip"
hint: The '.git/hooks/commit-msg' hook was ignored because it's not set as executable.
hint: You can disable this warning with `git config set advice.ignoredHook false`.
[main afd5516] another wip
$ chmod +x .git/hooks/commit-msg
$ git log --oneline -3
afd5516 another wip
4f0621c wip
6757929 fix(metrics): ignore surrounding whitespace
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-2-commit-msg-hook/06-who-runs-it -->
```text
# git revert writes its own subject. On Git 2.55 it does not run the commit-msg hook:
$ git revert --no-edit HEAD~2
[main fc74bcb] Revert "fix(metrics): ignore surrounding whitespace"
 Date: Mon Sep 7 10:28:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline -1
fc74bcb Revert "fix(metrics): ignore surrounding whitespace"
```
<!-- /snippet -->

### What happened internally

- `git commit` wrote the proposed message to `.git/COMMIT_EDITMSG` and ran `.git/hooks/commit-msg .git/COMMIT_EDITMSG` from the top of the working tree. The hook read the first line with `sed`. Its exit status decided: 1 made `git commit` stop before any commit object was written, so `git log -1` still showed the old tip.
- After the refused `git commit -am`, the change is listed as unstaged. `-a` stages into a temporary index, and Git throws that index away when the commit fails.
- `git hook run commit-msg -- <file>` runs the same file with the same argument. Nothing else of `git commit` happens.
- `--no-verify` skipped the hook. Removing the executable bit made Git ignore the file, and Git said so with a hint (`advice.ignoredHook`).
- `git revert` created a commit whose subject starts with `Revert "`, which the pattern does not allow, and the hook was not asked. On Git 2.55 a revert, a cherry-pick and the picks of a rebase make their commits without running `pre-commit` or `commit-msg`.

### Checkpoint

- `git log --oneline -4` shows, from the top: the revert, `another wip`, `wip`, and your `fix(metrics)` commit.
- `.git/hooks/commit-msg` is executable again: `git hook list commit-msg` prints `hook from hookdir`.

### Failure scenario

The team uses fixup commits (Chapter 9, section 9.7) and merges branches locally. Try both with the hook in place.

```bash
git commit --allow-empty --fixup=HEAD~1
git merge feat/f1
git status
git log --oneline -1
```

<!-- snippet: ch14c/lab-14-2-commit-msg-hook/07-failure -->
```text
$ git commit --allow-empty --fixup=HEAD~1
commit-msg: the subject must look like 'fix(scorer): handle empty labels'
commit-msg: got: fixup! another wip
[exit status: 1]
$ git merge feat/f1
commit-msg: the subject must look like 'fix(scorer): handle empty labels'
commit-msg: got: Merge branch 'feat/f1'
Not committing merge; use 'git commit' to complete the merge.
[exit status: 1]
$ git status
On branch main
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

Changes to be committed:
	new file:   f1.py

$ git log --oneline -1
fc74bcb Revert "fix(metrics): ignore surrounding whitespace"
```
<!-- /snippet -->

The fixup commit was refused because its subject is `fixup! ...`. The merge is worse: the merge itself succeeded, the hook refused the message `Merge branch 'feat/f1'`, and Git stopped with `Not committing merge`. You are now in the middle of a merge with everything staged and no commit, in a state that the person who wrote the hook never saw.

### Recovery

The hook must let through the subjects that Git writes itself. Compare the two versions, install the corrected one, and conclude the merge. (You can also make the change by hand: add the four lines that the `diff` shows after the line that sets `subject`.)

```bash
diff ../hooks/commit-msg ../hooks/commit-msg.v2
cp ../hooks/commit-msg.v2 .git/hooks/commit-msg
git commit --no-edit
```

<!-- snippet: ch14c/lab-14-2-commit-msg-hook/08-recovery -->
```text
$ diff ../hooks/commit-msg ../hooks/commit-msg.v2
4a5,8
> # Subjects that Git writes itself are not ours to police.
> case "$subject" in
>   "Merge "*|"Revert \""*|"Reapply \""*|"fixup! "*|"squash! "*|"amend! "*) exit 0 ;;
> esac
$ cp ../hooks/commit-msg.v2 .git/hooks/commit-msg
$ git commit --no-edit
[main 2a3e457] Merge branch 'feat/f1'
```
<!-- /snippet -->

`git commit --no-edit` concluded the merge with the message that was waiting in `.git/MERGE_MSG`. If you had been in a hurry, `git commit --no-edit --no-verify` would have concluded it with the broken hook still in place, and `git merge --abort` would have backed out.

### Verification

```bash
git log --oneline --graph -4
printf 'fixup! feat(metrics): add F1\n' > ../msg.txt
git hook run commit-msg -- ../msg.txt
printf 'quick fix\n' > ../msg.txt
git hook run commit-msg -- ../msg.txt
```

<!-- snippet: ch14c/lab-14-2-commit-msg-hook/09-verification -->
```text
$ git log --oneline --graph -4
*   2a3e457 Merge branch 'feat/f1'
|\  
| * f9fdfef feat(metrics): add F1
* | fc74bcb Revert "fix(metrics): ignore surrounding whitespace"
* | afd5516 another wip
$ printf 'fixup! feat(metrics): add F1\n' > ../msg.txt
$ git hook run commit-msg -- ../msg.txt
[exit status: 0]
$ printf 'quick fix\n' > ../msg.txt
$ git hook run commit-msg -- ../msg.txt
commit-msg: the subject must look like 'fix(scorer): handle empty labels'
commit-msg: got: quick fix
[exit status: 1]
```
<!-- /snippet -->

The merge commit exists, a fixup subject passes (exit status 0), and an ordinary non-conforming subject is still refused.

### Questions

1. Which file does the hook read, who writes it, and what would happen if the hook edited it?
2. After `git commit -am "updated scorer"` was refused, `git status -s` showed ` M metrics.py` and not `M  metrics.py`. Why?
3. The revert in step 6 passed although its subject breaks the rule. What does that tell you about a policy that says "every commit message on `main` follows the convention"?
4. In the failure scenario, what exactly was the state of the repository after `Not committing merge`, and which three commands could have taken you out of it?
5. A teammate clones `evalkit`. Which of your hook's rules apply to their commits? Name two ways to change that and the cost of each.

## Lab 14.3: A pre-push guard

### Objective

Install a `pre-push` hook that protects `main` against deletion, rewrites and unfinished commits. See what it receives on standard input. Then watch the rule being bypassed twice, and enforce it where it cannot be skipped: in a `pre-receive` hook of the repository that plays the server.

### Prerequisites

- Chapter 14C, sections 14C.9, 14C.10 and 14C.13.
- Chapter 12 (Remote Operations) for what a push sends and for non-fast-forward updates.

### Setup

```bash
bash labs/ch14c/setup-14-3-pre-push-guard.sh
labs/shell m14-3
cd gateway
```

The script builds `server.git` (bare, plays origin), your clone `gateway` with a branch `feature/limits` whose second commit is a `WIP:` commit, a teammate's clone `asha` (her identity is configured in it), and `hooks/pre-push` and `hooks/pre-receive`.

### Commands

Step 1. Read the hook. Find the three decisions it makes and the place where it reads standard input. Install it.

```bash
git log --oneline --graph --all
cat ../hooks/pre-push
cp ../hooks/pre-push .git/hooks/pre-push && chmod +x .git/hooks/pre-push
```

Step 2. Push the feature branch. Predict: does the WIP commit stop it?

```bash
git push -u origin feature/limits
```

Step 3. Bring the branch into `main` and push `main`.

```bash
git switch -q main
git merge -q --ff-only feature/limits
git push origin main
git status -sb
```

Step 4. Finish the commit and push again.

```bash
git commit -q --amend -m "Add per-tenant limits"
git log --oneline -3
git push origin main
```

Step 5. Try the two other things the guard forbids.

```bash
git push origin --delete main
git reset -q --hard HEAD~1
git push --force origin main
git reset -q --hard origin/main
```

### Expected output

<!-- snippet: ch14c/lab-14-3-pre-push-guard/01-install -->
```text
$ cd gateway
$ git log --oneline --graph --all
* 6378124 WIP: per-tenant limits, quota still undecided
* 81eee38 Add a burst allowance
* 2a5508c Add request router and rate limits
$ cat ../hooks/pre-push
#!/bin/sh
# pre-push <remote-name> <remote-url>, and one line per ref on standard input:
#   <local-ref> <local-object-ID> <remote-ref> <remote-object-ID>
# Guard for main: no deletion, no rewrite, no unfinished commits.
zero=$(git hash-object --stdin </dev/null | tr '0-9a-f' '0')
status=0
while read -r local_ref local_oid remote_ref remote_oid; do
  [ "$remote_ref" = refs/heads/main ] || continue
  if [ "$local_oid" = "$zero" ]; then
    echo "pre-push: refusing to delete main on $1" >&2
    status=1
    continue
  fi
  if [ "$remote_oid" = "$zero" ]; then
    range=$local_oid
  elif git merge-base --is-ancestor "$remote_oid" "$local_oid"; then
    range="$remote_oid..$local_oid"
  else
    echo "pre-push: this push would rewrite main on $1 (not a fast-forward)" >&2
    status=1
    continue
  fi
  unfinished=$(git log --format='  %h %s' -E --grep='^(WIP|fixup!|squash!)' "$range")
  if [ -n "$unfinished" ]; then
    echo "pre-push: unfinished commits must not reach main:" >&2
    echo "$unfinished" >&2
    status=1
  fi
done
exit $status
$ cp ../hooks/pre-push .git/hooks/pre-push && chmod +x .git/hooks/pre-push
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-3-pre-push-guard/02-feature-branch -->
```text
# A WIP commit on a feature branch is not the business of this hook:
$ git push -u origin feature/limits
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
 * [new branch]      feature/limits -> feature/limits
branch 'feature/limits' set up to track 'origin/feature/limits'.
```
<!-- /snippet -->

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

<!-- snippet: ch14c/lab-14-3-pre-push-guard/04-finish-and-push -->
```text
$ git commit -q --amend -m "Add per-tenant limits"
$ git log --oneline -3
eafde45 Add per-tenant limits
81eee38 Add a burst allowance
2a5508c Add request router and rate limits
$ git push origin main
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
   2a5508c..eafde45  main -> main
[exit status: 0]
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-3-pre-push-guard/05-delete-and-rewrite -->
```text
$ git push origin --delete main
pre-push: refusing to delete main on origin
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git reset -q --hard HEAD~1
$ git push --force origin main
pre-push: this push would rewrite main on origin (not a fast-forward)
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git reset -q --hard origin/main
```
<!-- /snippet -->

### What happened internally

- `git push` contacted the remote, learned the current value of each ref it was about to update, and then ran `.git/hooks/pre-push origin <url>` with one line per ref on standard input: local ref, local commit ID, remote ref, remote commit ID.
- For `feature/limits` the hook's first test (`remote_ref` is not `refs/heads/main`) skipped the line, so the WIP commit went out.
- For `main` the remote ID was an ancestor of the local one (`git merge-base --is-ancestor`), so the range to inspect was `<remote>..<local>`, and `git log --grep` found the WIP subject in it. Exit status 1: Git sent nothing. `git status -sb` still said `ahead 2`.
- A deletion arrives as a line whose local ID is all zeros. The hook computes that value with `git hash-object --stdin </dev/null | tr '0-9a-f' '0'`, which gives 40 zeros in a SHA-1 repository and 64 in a SHA-256 one.
- The forced push was caught by the ancestor test: the remote commit was not an ancestor of what you were about to push.
- Nothing changed on the server in any of the refused pushes. The refusal happened in your clone, before the transfer.

### Checkpoint

- `git log --oneline -3 origin/main` shows `Add per-tenant limits` at the top.
- `git status -sb` prints `## main...origin/main` with nothing after it.

### Failure scenario

The guard exists in one clone. Play Asha, whose clone has no hooks, and then yourself in a hurry.

```bash
cd ../asha
git pull -q
ls .git/hooks | grep -v sample
printf 'def route(request):\n    return upstream(request.model, timeout=10)\n' > router.py
git commit -q -am "WIP: timeout, value to be tuned"
git push origin main
cd ../gateway
git pull -q
git commit -q --allow-empty -m "WIP: placeholder"
git push --no-verify origin main
git log --oneline -3 origin/main
```

<!-- snippet: ch14c/lab-14-3-pre-push-guard/06-failure -->
```text
# Asha works in her own clone. It has no pre-push hook: hooks are not cloned.
$ cd ../asha
$ git pull -q
$ ls .git/hooks | grep -v sample
$ printf 'def route(request):\n    return upstream(request.model, timeout=10)\n' > router.py
$ git commit -q -am "WIP: timeout, value to be tuned"
$ git push origin main
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
   eafde45..20aa35f  main -> main
[exit status: 0]
# And in your clone the guard is one option away from being skipped:
$ cd ../gateway
$ git pull -q
$ git commit -q --allow-empty -m "WIP: placeholder"
$ git push --no-verify origin main
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
   20aa35f..18e1b38  main -> main
[exit status: 0]
$ git log --oneline -3 origin/main
18e1b38 WIP: placeholder
20aa35f WIP: timeout, value to be tuned
eafde45 Add per-tenant limits
```
<!-- /snippet -->

Two WIP commits are on `main` of the server. No tool reported anything, because nothing was asked: Asha's clone never had the hook, and `--no-verify` told yours to stay silent.

### Recovery

Move the rule to the one place that every push passes. Read `hooks/pre-receive` and compare it with the client hook: the input lines have a different order (old ID, new ID, ref), the messages go to standard output, and there is no remote name. Install it in the bare repository.

```bash
cat ../hooks/pre-receive
cp ../hooks/pre-receive ../server.git/hooks/pre-receive && chmod +x ../server.git/hooks/pre-receive
```

<!-- snippet: ch14c/lab-14-3-pre-push-guard/07-recovery-server -->
```text
# Enforce the rule where every push arrives: in the repository that plays the server.
$ cat ../hooks/pre-receive
#!/bin/sh
# pre-receive (server side): one line per ref on standard input:
#   <old-object-ID> <new-object-ID> <ref-name>
# A non-zero exit rejects the whole push. Output goes back to the person who pushes.
zero=$(git hash-object --stdin </dev/null | tr '0-9a-f' '0')
while read -r old new ref; do
  [ "$ref" = refs/heads/main ] || continue
  if [ "$new" = "$zero" ]; then
    echo "policy: main cannot be deleted"
    exit 1
  fi
  if [ "$old" = "$zero" ]; then
    range=$new
  elif git merge-base --is-ancestor "$old" "$new"; then
    range="$old..$new"
  else
    echo "policy: main accepts fast-forward updates only"
    exit 1
  fi
  unfinished=$(git log --format='  %h %s' -E --grep='^(WIP|fixup!|squash!)' "$range")
  if [ -n "$unfinished" ]; then
    echo "policy: unfinished commits must not reach main:"
    echo "$unfinished"
    exit 1
  fi
done
$ cp ../hooks/pre-receive ../server.git/hooks/pre-receive && chmod +x ../server.git/hooks/pre-receive
```
<!-- /snippet -->

Now repeat both bypasses.

```bash
git commit -q --allow-empty -m "WIP: another placeholder"
git push --no-verify origin main
git reset -q --hard origin/main
cd ../asha
git pull -q
git commit -q --allow-empty -m "fixup! Add per-tenant limits"
git push origin main
git reset -q --hard origin/main
```

<!-- snippet: ch14c/lab-14-3-pre-push-guard/08-recovery-test -->
```text
$ git commit -q --allow-empty -m "WIP: another placeholder"
$ git push --no-verify origin main
remote: policy: unfinished commits must not reach main:        
remote:   f1edb7c WIP: another placeholder        
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git reset -q --hard origin/main
$ cd ../asha
$ git pull -q
$ git commit -q --allow-empty -m "fixup! Add per-tenant limits"
$ git push origin main
remote: policy: unfinished commits must not reach main:        
remote:   f76de82 fixup! Add per-tenant limits        
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git reset -q --hard origin/main
```
<!-- /snippet -->

Both pushes were refused by the server: `! [remote rejected] main -> main (pre-receive hook declined)`. The lines that start with `remote:` are the hook's output, carried back over the connection.

The two WIP commits that were pushed before stay on `main`. Their content is fine and only their subjects are wrong, and a subject can be changed only by rewriting history that others have (Chapter 9, section 9.15). The rule now forbids exactly that. Leave them.

### Verification

```bash
printf '# gateway\n' > README.md && git add README.md && git commit -q -m 'Add README'
git push origin main
git push origin --delete main
git -C ../server.git log --oneline -5 main
```

<!-- snippet: ch14c/lab-14-3-pre-push-guard/09-verification -->
```text
$ printf '# gateway\n' > README.md && git add README.md && git commit -q -m 'Add README'
$ git push origin main
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
   18e1b38..2eb5ba2  main -> main
[exit status: 0]
$ git push origin --delete main
remote: policy: main cannot be deleted        
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
 ! [remote rejected] main (pre-receive hook declined)
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git -C ../server.git log --oneline -5 main
2eb5ba2 Add README
18e1b38 WIP: placeholder
20aa35f WIP: timeout, value to be tuned
eafde45 Add per-tenant limits
81eee38 Add a burst allowance
```
<!-- /snippet -->

A normal commit is accepted from a clone without any hooks, and a deletion is refused by the server.

> **GitHub, not Git.** You cannot install `pre-receive` hooks on github.com. The same three rules are a ruleset there: block deletions, block force pushes, and require a pull request with a status check that fails on unfinished commits. Chapter 18 covers rulesets. GitHub Enterprise Server supports pre-receive hook scripts ([documentation](https://docs.github.com/en/enterprise-server@latest/admin/enforcing-policies/enforcing-policy-with-pre-receive-hooks/about-pre-receive-hooks)). This paragraph is described from the documentation.

### Questions

1. Write down the line that the hook received on standard input in step 3, with real values from your sandbox (`git rev-parse main origin/main`).
2. Why did the WIP commit on `feature/limits` pass in step 2 and fail in step 3, although it is the same commit?
3. The hook uses `git merge-base --is-ancestor "$remote_oid" "$local_oid"`. What must be true about your clone for that command to give the right answer, and what happens after someone else has pushed commits you have not fetched?
4. Compare the inputs of `pre-push` and `pre-receive`. Why does `pre-receive` not need a remote name, and why does its output appear with `remote:` in front?
5. After the recovery, is the client-side hook still worth having? Give one reason for and one against.

## Lab 14.4: A clean and smudge filter

### Objective

Build a filter pair that keeps the bytes of large files outside the repository and commits a one-line pointer instead: a twelve-line model of what a large-file extension does. Watch `clean` run on `git add` and `smudge` run on checkout. Then see what a clone without the filter definition does to the scheme, and repair both clones.

### Prerequisites

- Chapter 14C, sections 14C.4 and 14C.8.
- Chapter 5 (The Index) for `git ls-files -s` and the `:path` syntax.

### Setup

```bash
bash labs/ch14c/setup-14-4-clean-smudge-filter.sh
labs/shell m14-4
cd modelhub
```

The script builds `server.git` and your clone `modelhub`, in which two scripts are tracked: `tools/ptr-clean` and `tools/ptr-smudge`. The clean script creates a directory `ptr-store` next to the clones. It stands in for the storage server of a real large-file system.

### Commands

Step 1. Read both scripts. For each, say what it reads, what it prints, and what it does when its input is not what it expects.

```bash
cat tools/ptr-clean
cat tools/ptr-smudge
```

Step 2. Name the filter in `.gitattributes` and define it in configuration. `required` turns a failing filter into an error.

```bash
printf 'weights/*.bin filter=ptr -text\n' > .gitattributes
git config set filter.ptr.clean tools/ptr-clean
git config set filter.ptr.smudge 'tools/ptr-smudge %f'
git config set filter.ptr.required true
git check-attr filter text -- weights/encoder.bin
```

Step 3. Add a weights file. Predict what the blob in the index contains.

```bash
printf 'layer0: 0.12 0.98 0.33\nlayer1: 0.44 0.10 0.71\n' > weights/encoder.bin
git add .
git ls-files -s weights/encoder.bin
git cat-file -p :weights/encoder.bin
cat weights/encoder.bin
ls ../ptr-store
git commit -q -m "Add encoder weights" && git push -q
```

Step 4. Change the weights and look at the diff.

```bash
printf 'layer0: 0.15 0.97 0.31\nlayer1: 0.44 0.10 0.71\n' > weights/encoder.bin
git diff
git commit -q -am "Retrain encoder" && git push -q
```

Step 5. Go back one commit and forward again.

```bash
git switch -q --detach HEAD~1
cat weights/encoder.bin
git switch -q main
cat weights/encoder.bin
```

### Expected output

<!-- snippet: ch14c/lab-14-4-clean-smudge-filter/01-scripts -->
```text
$ cd modelhub
$ cat tools/ptr-clean
#!/bin/sh
# clean: working tree -> repository. Put the real bytes into the store and print a pointer.
store="$(git rev-parse --show-toplevel)/../ptr-store"
mkdir -p "$store"
tmp="$store/incoming.$$"
cat > "$tmp"
if head -n 1 "$tmp" | grep -q '^ptr-v1 sha256:'; then
  cat "$tmp"                      # already a pointer: pass it through unchanged
  rm -f "$tmp"
  exit 0
fi
sum=$(shasum -a 256 < "$tmp" | cut -d' ' -f1)
size=$(wc -c < "$tmp" | tr -d ' ')
mv "$tmp" "$store/$sum"
printf 'ptr-v1 sha256:%s size:%s\n' "$sum" "$size"
$ cat tools/ptr-smudge
#!/bin/sh
# smudge: repository -> working tree. Replace a pointer by the bytes it names.
store="$(git rev-parse --show-toplevel)/../ptr-store"
tmp="$(git rev-parse --git-dir)/ptr-smudge.$$"
cat > "$tmp"
sum=$(sed -n '1s/^ptr-v1 sha256:\([0-9a-f]*\) size:.*/\1/p' "$tmp")
if [ -z "$sum" ]; then
  cat "$tmp"                      # not a pointer: pass it through unchanged
  rm -f "$tmp"
  exit 0
fi
rm -f "$tmp"
if [ -f "$store/$sum" ]; then
  cat "$store/$sum"
else
  echo "ptr-smudge: $1: content $sum is not in the store" >&2
  exit 1
fi
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-4-clean-smudge-filter/02-configure -->
```text
$ printf 'weights/*.bin filter=ptr -text\n' > .gitattributes
$ git config set filter.ptr.clean tools/ptr-clean
$ git config set filter.ptr.smudge 'tools/ptr-smudge %f'
$ git config set filter.ptr.required true
$ git check-attr filter text -- weights/encoder.bin
weights/encoder.bin: filter: ptr
weights/encoder.bin: text: unset
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-4-clean-smudge-filter/03-clean -->
```text
$ printf 'layer0: 0.12 0.98 0.33\nlayer1: 0.44 0.10 0.71\n' > weights/encoder.bin
$ git add .
$ git ls-files -s weights/encoder.bin
100644 caa64afb2d987d3551f44b29b66f5328265e1ee5 0	weights/encoder.bin
# The blob in the index is the pointer. The file on disk is untouched:
$ git cat-file -p :weights/encoder.bin
ptr-v1 sha256:b340d0b9f9c35148ca8ca446354faac4672af0adcc6a7e7b834cadf8bfc31e5f size:46
$ cat weights/encoder.bin
layer0: 0.12 0.98 0.33
layer1: 0.44 0.10 0.71
$ ls ../ptr-store
b340d0b9f9c35148ca8ca446354faac4672af0adcc6a7e7b834cadf8bfc31e5f
$ git commit -q -m "Add encoder weights" && git push -q
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-4-clean-smudge-filter/04-diff -->
```text
$ printf 'layer0: 0.15 0.97 0.31\nlayer1: 0.44 0.10 0.71\n' > weights/encoder.bin
$ git diff
diff --git a/weights/encoder.bin b/weights/encoder.bin
index caa64af..9876bef 100644
--- a/weights/encoder.bin
+++ b/weights/encoder.bin
@@ -1 +1 @@
-ptr-v1 sha256:b340d0b9f9c35148ca8ca446354faac4672af0adcc6a7e7b834cadf8bfc31e5f size:46
+ptr-v1 sha256:25f38f38aee619dcc074f05a92e30f9efb046b5ac4e7d016d996031e9ae4261a size:46
$ git commit -q -am "Retrain encoder" && git push -q
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-4-clean-smudge-filter/05-smudge -->
```text
# Going back one commit runs the smudge filter, which fetches the old bytes from the store:
$ git switch -q --detach HEAD~1
$ cat weights/encoder.bin
layer0: 0.12 0.98 0.33
layer1: 0.44 0.10 0.71
$ git switch -q main
$ cat weights/encoder.bin
layer0: 0.15 0.97 0.31
layer1: 0.44 0.10 0.71
```
<!-- /snippet -->

### What happened internally

- `git add` saw `filter=ptr` for `weights/encoder.bin`, started `tools/ptr-clean` at the top of the working tree, and fed it the file on standard input. The script stored the bytes under their SHA-256 in `../ptr-store` and printed one line. Git hashed that line: the blob in the index, and later in the commit, is the pointer. Your working file was not touched.
- `git diff` cleaned the working file again and compared pointer with pointer. That is why the diff of a filtered file shows the stored form, and why a file that cleans to the committed blob is "unmodified".
- `git switch --detach HEAD~1` had to write a different blob to the working tree, so it ran `tools/ptr-smudge weights/encoder.bin`, which found the old bytes in the store.
- The repository on the server holds two small blobs. The weights themselves never entered an object.
- The filter definition is in `.git/config` of this clone and nowhere else.

### Checkpoint

- `git cat-file -p HEAD:weights/encoder.bin` prints one line that starts with `ptr-v1 sha256:25f38f3`.
- `ls ../ptr-store` lists two files.
- `git status -s` prints nothing.

### Failure scenario

Asha clones the repository. Her clone has `.gitattributes` and the two scripts, and no `filter.ptr.*` configuration. She retrains the encoder and commits.

```bash
cd ..
git clone -q server.git modelhub-asha
cd modelhub-asha
git check-attr filter -- weights/encoder.bin
git config get filter.ptr.clean
cat weights/encoder.bin
printf 'layer0: 0.21 0.90 0.35\nlayer1: 0.40 0.12 0.70\n' > weights/encoder.bin
git commit -q -am "Retrain encoder on the new split" && git push -q
git cat-file -p HEAD:weights/encoder.bin
```

<!-- snippet: ch14c/lab-14-4-clean-smudge-filter/06-failure -->
```text
# Asha clones. Her clone has the attribute and the scripts, but no filter.ptr.* configuration:
$ cd ..
$ git clone -q server.git modelhub-asha
$ cd modelhub-asha
$ git check-attr filter -- weights/encoder.bin
weights/encoder.bin: filter: ptr
$ git config get filter.ptr.clean
[exit status: 1]
$ cat weights/encoder.bin
ptr-v1 sha256:25f38f38aee619dcc074f05a92e30f9efb046b5ac4e7d016d996031e9ae4261a size:46
# She retrains, writes real weights over the pointer, commits and pushes:
$ printf 'layer0: 0.21 0.90 0.35\nlayer1: 0.40 0.12 0.70\n' > weights/encoder.bin
$ git commit -q -am "Retrain encoder on the new split" && git push -q
$ git cat-file -p HEAD:weights/encoder.bin
layer0: 0.21 0.90 0.35
layer1: 0.40 0.12 0.70
```
<!-- /snippet -->

Two things went wrong without a message. Her working file was the pointer, one line of text where her training code expects weights. And her commit stored real content in a Git blob, which is what the filter exists to prevent. `required = true` did not help: it is part of the definition she does not have. Back in your clone the damage shows as a file that is modified although you did not touch it:

```bash
cd ../modelhub
git pull -q
git status -s
git diff
```

<!-- snippet: ch14c/lab-14-4-clean-smudge-filter/07-symptom -->
```text
$ cd ../modelhub
$ git pull -q
$ git status -s
 M weights/encoder.bin
$ git diff
diff --git a/weights/encoder.bin b/weights/encoder.bin
index 942f756..59b44ff 100644
--- a/weights/encoder.bin
+++ b/weights/encoder.bin
@@ -1,2 +1 @@
-layer0: 0.21 0.90 0.35
-layer1: 0.40 0.12 0.70
+ptr-v1 sha256:e689a795e776e4c2737e40ee68767b3c71ef80c07d4eddb427c6244f2abcc8ec size:46
```
<!-- /snippet -->

`git status` compares the cleaned form of your file (a pointer) with the committed blob (real content). They differ, and they will differ after every checkout until the stored form is repaired.

### Recovery

In your clone, re-add every tracked file through the clean filter and commit the result.

```bash
git add --renormalize .
git status -s
git commit -q -m "Store the retrained encoder as a pointer again"
git push -q
git cat-file -p HEAD:weights/encoder.bin
git status -s
```

<!-- snippet: ch14c/lab-14-4-clean-smudge-filter/08-recovery-you -->
```text
$ git add --renormalize .
$ git status -s
M  weights/encoder.bin
$ git commit -q -m "Store the retrained encoder as a pointer again"
$ git push -q
$ git cat-file -p HEAD:weights/encoder.bin
ptr-v1 sha256:e689a795e776e4c2737e40ee68767b3c71ef80c07d4eddb427c6244f2abcc8ec size:46
$ git status -s
```
<!-- /snippet -->

In Asha's clone, define the filter. Then try to pull, read the refusal, and renormalize there too.

```bash
cd ../modelhub-asha
git config set filter.ptr.clean tools/ptr-clean
git config set filter.ptr.smudge 'tools/ptr-smudge %f'
git config set filter.ptr.required true
git status -s
git pull -q
git add --renormalize .
git pull -q
git status -s
git cat-file -p HEAD:weights/encoder.bin
cat weights/encoder.bin
```

<!-- snippet: ch14c/lab-14-4-clean-smudge-filter/09-recovery-asha -->
```text
$ cd ../modelhub-asha
$ git config set filter.ptr.clean tools/ptr-clean
$ git config set filter.ptr.smudge 'tools/ptr-smudge %f'
$ git config set filter.ptr.required true
# With the driver defined, her real weights now count as a change against the raw blob in her index:
$ git status -s
 M weights/encoder.bin
$ git pull -q
error: Your local changes to the following files would be overwritten by merge:
	weights/encoder.bin
Please commit your changes or stash them before you merge.
Aborting
[exit status: 1]
# Renormalizing stages the pointer, which is exactly what the incoming commit holds:
$ git add --renormalize .
$ git pull -q
[exit status: 0]
$ git status -s
$ git cat-file -p HEAD:weights/encoder.bin
ptr-v1 sha256:e689a795e776e4c2737e40ee68767b3c71ef80c07d4eddb427c6244f2abcc8ec size:46
$ cat weights/encoder.bin
layer0: 0.21 0.90 0.35
layer1: 0.40 0.12 0.70
```
<!-- /snippet -->

The first pull was refused. With the filter defined, her file (real weights) cleans to a pointer, her index still holds the raw blob, so Git sees a local change that the incoming commit would overwrite. After `--renormalize` her index holds the same pointer as the incoming commit, and the fast-forward goes through.

### Verification

```bash
cd ../modelhub
git log --format='%h %s' -- weights/encoder.bin
for c in $(git rev-list HEAD -- weights/encoder.bin); do git cat-file -p $c:weights/encoder.bin | head -n 1; done
ls ../ptr-store
```

<!-- snippet: ch14c/lab-14-4-clean-smudge-filter/10-verification -->
```text
$ cd ../modelhub
$ git log --format='%h %s' -- weights/encoder.bin
cb37cb9 Store the retrained encoder as a pointer again
392e6ec Retrain encoder on the new split
2ba3dde Retrain encoder
51631c0 Add encoder weights
$ for c in $(git rev-list HEAD -- weights/encoder.bin); do git cat-file -p $c:weights/encoder.bin | head -n 1; done
ptr-v1 sha256:e689a795e776e4c2737e40ee68767b3c71ef80c07d4eddb427c6244f2abcc8ec size:46
layer0: 0.21 0.90 0.35
ptr-v1 sha256:25f38f38aee619dcc074f05a92e30f9efb046b5ac4e7d016d996031e9ae4261a size:46
ptr-v1 sha256:b340d0b9f9c35148ca8ca446354faac4672af0adcc6a7e7b834cadf8bfc31e5f size:46
$ ls ../ptr-store
25f38f38aee619dcc074f05a92e30f9efb046b5ac4e7d016d996031e9ae4261a
b340d0b9f9c35148ca8ca446354faac4672af0adcc6a7e7b834cadf8bfc31e5f
e689a795e776e4c2737e40ee68767b3c71ef80c07d4eddb427c6244f2abcc8ec
```
<!-- /snippet -->

Three of the four versions are pointers. The second line, Asha's commit, still holds real content, and it always will: the repair added a commit and did not rewrite history. For 46 bytes that is harmless. For a 4 GB checkpoint it is the start of a history rewrite (Chapter 22: Git LFS, and Chapter 21 for removing content from history).

### Questions

1. In step 3, which program computed the pointer, who started it, and where did the real bytes go?
2. Why does `git diff` in step 4 show two pointer lines and not the changed numbers?
3. Asha's clone printed `weights/encoder.bin: filter: ptr` and exit status 1 for `git config get filter.ptr.clean`. Explain how both can be true and why Git did not warn her.
4. Why was `git pull` refused in Asha's clone after she defined the filter, although she had not edited any file since her last commit?
5. `ptr-clean` passes a pointer through unchanged. What would go wrong without that branch of the script? (Think about `git add --renormalize .` in a clone whose working file is a pointer.)
6. What does the real system need that this model lacks? Name at least three things.

## Lab 14.5: Rerere, resolve once

### Objective

Rebase a branch whose first two commits both conflict with `main`. Resolve the first conflict, abort the rebase, and watch rerere replay your resolution on the second attempt. Then meet the dangerous case: a wrong recorded resolution that `rerere.autoUpdate` stages without a question. Find it, undo the rebase, and replace the record.

### Prerequisites

- Chapter 14C, section 14C.3.
- Chapter 9 (Rebase), sections 9.11 and 9.16.

### Setup

```bash
bash labs/ch14c/setup-14-5-rerere-resolve-once.sh
labs/shell m14-5
cd ranker
```

The script builds two repositories. `ranker` has `feature/hybrid` (three commits) checked out and `main` two commits ahead of the fork point; rerere is off. `ranker-wrong` is the same repository with rerere and `rerere.autoUpdate` switched on and two resolutions already recorded, one of them wrong. Both set `maintenance.rerere-gc.auto=0`; section 14C.3 of the chapter explains why (a lock race between rerere and background maintenance on Git 2.55).

### Commands

Step 1. Switch rerere on and start the rebase.

```bash
git log --oneline --graph --all
git config set rerere.enabled true
git rebase main
ls .git/rr-cache
git rerere status
```

Step 2. Resolve the first conflict: the reranker needs 50 candidates, so keep the branch's values. Continue.

```bash
printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
git add retrieval.yaml
git rebase --continue
```

Step 3. The second conflict needs a decision from a colleague who is not there. Abort, and look at what rerere kept.

```bash
git rebase --abort
git status -sb
git log --oneline -1
for d in .git/rr-cache/*; do echo "$d:"; ls "$d"; done
```

Step 4. The next morning `main` has one more commit. Create it, then rebase again.

```bash
git switch main
printf 'bge-small: 384 dimensions\n' > MODELS.md
git add MODELS.md && git commit -m 'Document the embedding model'
git switch feature/hybrid
git rebase main
cat retrieval.yaml
git status -s
```

Step 5. Review the replayed file, stage it, and finish. The second conflict is resolved by hand: keep the normalization from `main` and the blend from the branch.

```bash
git add retrieval.yaml
git rebase --continue
printf 'def score(q, d):\n    return 0.7 * bm25(q, d) / max_bm25 + 0.3 * dense(q, d)\n' > scoring.py
git add scoring.py
git rebase --continue
git log --oneline --graph --all
```

The transcripts below pass `-c advice.mergeConflict=false` to `git rebase` to leave out five lines of hints. You can do the same or read past them.

### Expected output

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/01-start -->
```text
$ cd ranker
$ git log --oneline --graph --all
* cecb3f7 Normalize BM25 scores
* 5c39de8 Raise top_k to 20
| * 4e2ad73 Describe hybrid ranking
| * 27f7ed2 Blend dense scores into the ranking
| * 4c042d7 Enable reranking over the top 50 candidates
|/  
* e504b3b Add retrieval config and BM25 scoring
$ git config set rerere.enabled true
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/02-first-stop -->
```text
$ git -c advice.mergeConflict=false rebase main
Rebasing (1/3)
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
error: could not apply 4c042d7... Enable reranking over the top 50 candidates
Recorded preimage for 'retrieval.yaml'
Could not apply 4c042d7... # Enable reranking over the top 50 candidates
[exit status: 1]
$ ls .git/rr-cache
ec4b2990356a9f0ab0af396e6ce888496e91b4c7
$ git rerere status
retrieval.yaml
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/03-resolve-first -->
```text
$ printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
$ git add retrieval.yaml
$ git -c advice.mergeConflict=false rebase --continue
Recorded resolution for 'retrieval.yaml'.
[detached HEAD a4c42f6] Enable reranking over the top 50 candidates
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (2/3)
Auto-merging scoring.py
CONFLICT (content): Merge conflict in scoring.py
error: could not apply 27f7ed2... Blend dense scores into the ranking
Recorded preimage for 'scoring.py'
Could not apply 27f7ed2... # Blend dense scores into the ranking
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/04-abort -->
```text
# The second conflict needs a decision from the scoring owner. Stop for today:
$ git rebase --abort
$ git status -sb
## feature/hybrid
$ git log --oneline -1
4e2ad73 Describe hybrid ranking
$ for d in .git/rr-cache/*; do echo "$d:"; ls "$d"; done
.git/rr-cache/ec4b2990356a9f0ab0af396e6ce888496e91b4c7:
postimage
preimage
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/05-second-rebase -->
```text
# Next morning main has one more commit, and you rebase again:
$ git -c advice.mergeConflict=false rebase main
Rebasing (1/3)
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
error: could not apply 4c042d7... Enable reranking over the top 50 candidates
Resolved 'retrieval.yaml' using previous resolution.
Could not apply 4c042d7... # Enable reranking over the top 50 candidates
[exit status: 1]
$ cat retrieval.yaml
model: bge-small
top_k: 50
rerank: true
$ git status -s
UU retrieval.yaml
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/06-finish -->
```text
$ git add retrieval.yaml
$ git -c advice.mergeConflict=false rebase --continue
[detached HEAD 97e8dfb] Enable reranking over the top 50 candidates
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (2/3)
Auto-merging scoring.py
CONFLICT (content): Merge conflict in scoring.py
error: could not apply 27f7ed2... Blend dense scores into the ranking
Recorded preimage for 'scoring.py'
Could not apply 27f7ed2... # Blend dense scores into the ranking
[exit status: 1]
$ printf 'def score(q, d):\n    return 0.7 * bm25(q, d) / max_bm25 + 0.3 * dense(q, d)\n' > scoring.py
$ git add scoring.py
$ git rebase --continue
Recorded resolution for 'scoring.py'.
[detached HEAD e9c145e] Blend dense scores into the ranking
 1 file changed, 1 insertion(+), 1 deletion(-)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feature/hybrid.
$ git log --oneline --graph --all
* 2825c74 Describe hybrid ranking
* e9c145e Blend dense scores into the ranking
* 97e8dfb Enable reranking over the top 50 candidates
* ad9e98c Document the embedding model
* cecb3f7 Normalize BM25 scores
* 5c39de8 Raise top_k to 20
* e504b3b Add retrieval config and BM25 scoring
```
<!-- /snippet -->

### What happened internally

- At the first stop Git wrote the normalized conflict to `.git/rr-cache/<id>/preimage` (`Recorded preimage`). `git rebase --continue` made the commit and stored your file as `postimage` (`Recorded resolution`). At the second stop it recorded a second preimage.
- `git rebase --abort` put the branch back and ran `git rerere clear`, which removed the record that had no resolution yet. The resolved record stayed: one directory with `preimage` and `postimage`.
- On the second attempt the first commit conflicted with the same text, although `main` had moved. The conflict ID is a hash of the conflict hunks, so the new commit on `main`, which touches another file, did not matter. Rerere merged the old conflict, your old answer and the new conflict, and wrote the result into the file: `Resolved 'retrieval.yaml' using previous resolution.`
- The rebase still stopped, with `UU` in `git status -s`. Rerere writes the working file and leaves the index to you.
- The second conflict was new to rerere. It is recorded now, so a third rebase would stop twice and ask you nothing.

### Checkpoint

- `git log --oneline --graph --all` shows one straight line with seven commits.
- `ls .git/rr-cache` lists two directories, each with `preimage` and `postimage`.

### Failure scenario

`ranker-wrong` is what a colleague hands you: rerere is on, `rerere.autoUpdate` is on, and resolutions for both conflicts are recorded. Look at them first, then rebase.

```bash
cd ../ranker-wrong
git config get rerere.autoUpdate
for f in .git/rr-cache/*/postimage; do cat "$f"; echo; done
git rebase main
git rebase --continue
git rebase --continue
```

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/07-failure -->
```text
$ cd ../ranker-wrong
$ git config get rerere.autoUpdate
true
$ for f in .git/rr-cache/*/postimage; do cat "$f"; echo; done
def score(q, d):
    return 0.7 * bm25(q, d) / max_bm25 + 0.3 * dense(q, d)

model: bge-small
top_k: 20
rerank: true

$ git -c advice.mergeConflict=false rebase main
Rebasing (1/3)
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
error: could not apply 5b944db... Enable reranking over the top 50 candidates
Staged 'retrieval.yaml' using previous resolution.
Could not apply 5b944db... # Enable reranking over the top 50 candidates
[exit status: 1]
$ git -c advice.mergeConflict=false rebase --continue
[detached HEAD 2806d05] Enable reranking over the top 50 candidates
 1 file changed, 1 insertion(+), 1 deletion(-)
Rebasing (2/3)
Auto-merging scoring.py
CONFLICT (content): Merge conflict in scoring.py
error: could not apply 644c1dd... Blend dense scores into the ranking
Staged 'scoring.py' using previous resolution.
Could not apply 644c1dd... # Blend dense scores into the ranking
[exit status: 1]
$ git rebase --continue
[detached HEAD f81c640] Blend dense scores into the ranking
 1 file changed, 1 insertion(+), 1 deletion(-)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feature/hybrid.
```
<!-- /snippet -->

The rebase stopped twice and each time said `Staged ... using previous resolution`. Two presses of `--continue` and it was done. You typed no resolution, looked at no file, and one of the recorded answers keeps `top_k: 20` with `rerank: true`. Detect it by comparing your own lines before and after the rebase. A rebase should change them only where the new base requires it.

```bash
git diff 'feature/hybrid@{1}' feature/hybrid -- retrieval.yaml
```

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/08-detect -->
```text
# Your own lines, before and after the rebase:
$ git diff 'feature/hybrid@{1}' feature/hybrid -- retrieval.yaml
diff --git a/retrieval.yaml b/retrieval.yaml
index 820d682..1bb37a0 100644
--- a/retrieval.yaml
+++ b/retrieval.yaml
@@ -1,3 +1,3 @@
 model: bge-small
-top_k: 50
+top_k: 20
 rerank: true
```
<!-- /snippet -->

Your branch said 50 before the rebase and says 20 after it.

### Recovery

Undo the rebase through the branch reflog, start it again, and this time stop the replay: forget the record and bring the conflict back.

```bash
git reset --hard 'feature/hybrid@{1}'
git rebase main
git rerere forget retrieval.yaml
git restore --merge retrieval.yaml
cat retrieval.yaml
```

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/09-recovery-undo -->
```text
$ git reset --hard 'feature/hybrid@{1}'
HEAD is now at ca0cc8e Describe hybrid ranking
$ git -c advice.mergeConflict=false rebase main
Rebasing (1/3)
Auto-merging retrieval.yaml
CONFLICT (content): Merge conflict in retrieval.yaml
error: could not apply 5b944db... Enable reranking over the top 50 candidates
Staged 'retrieval.yaml' using previous resolution.
Could not apply 5b944db... # Enable reranking over the top 50 candidates
[exit status: 1]
$ git rerere forget retrieval.yaml
Updated preimage for 'retrieval.yaml'
Forgot resolution for 'retrieval.yaml'
$ git restore --merge retrieval.yaml
$ cat retrieval.yaml
model: bge-small
<<<<<<< ours
top_k: 20
rerank: false
=======
top_k: 50
rerank: true
>>>>>>> theirs
```
<!-- /snippet -->

🔴 `git reset --hard` is safe here because the working tree is clean and the commit you leave is in the reflog. `git restore --merge` rebuilt the conflicted file from the stages that Git keeps in the index for exactly this purpose. Note the labels: in a rebase "ours" is the new base (Chapter 9, section 9.11). Resolve it correctly and continue. The second stop replays the scoring resolution, which is right.

```bash
printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
git add retrieval.yaml
git rebase --continue
git rebase --continue
```

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/10-recovery-record -->
```text
$ printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
$ git add retrieval.yaml
$ git -c advice.mergeConflict=false rebase --continue
Recorded resolution for 'retrieval.yaml'.
[detached HEAD 71d21d1] Enable reranking over the top 50 candidates
 1 file changed, 2 insertions(+), 2 deletions(-)
Rebasing (2/3)
Auto-merging scoring.py
CONFLICT (content): Merge conflict in scoring.py
error: could not apply 644c1dd... Blend dense scores into the ranking
Staged 'scoring.py' using previous resolution.
Could not apply 644c1dd... # Blend dense scores into the ranking
[exit status: 1]
$ git rebase --continue
[detached HEAD 109a564] Blend dense scores into the ranking
 1 file changed, 1 insertion(+), 1 deletion(-)
Rebasing (3/3)
Successfully rebased and updated refs/heads/feature/hybrid.
```
<!-- /snippet -->

`Recorded resolution for 'retrieval.yaml'.` The wrong record is replaced.

### Verification

```bash
git show HEAD~2:retrieval.yaml
git diff 'feature/hybrid@{1}' feature/hybrid -- retrieval.yaml
grep -l "top_k: 50" .git/rr-cache/*/postimage | wc -l
git log --oneline --graph --all
```

<!-- snippet: ch14c/lab-14-5-rerere-resolve-once/11-verification -->
```text
$ git show HEAD~2:retrieval.yaml
model: bge-small
top_k: 50
rerank: true
$ git diff 'feature/hybrid@{1}' feature/hybrid -- retrieval.yaml
$ grep -l "top_k: 50" .git/rr-cache/*/postimage | wc -l
       1
$ git log --oneline --graph --all
* 515e2c8 Describe hybrid ranking
* 109a564 Blend dense scores into the ranking
* 71d21d1 Enable reranking over the top 50 candidates
* 8e09b14 Normalize BM25 scores
* b3f6be6 Raise top_k to 20
* 066de8f Add retrieval config and BM25 scoring
```
<!-- /snippet -->

The rebased commit has 50, the diff of your own lines across the rebase is empty, and one recorded resolution now contains `top_k: 50`.

### Questions

1. After the abort in step 3, one record was kept and one was removed. Which, and what distinguishes them?
2. `main` got a new commit between the two rebases, and rerere still recognized the conflict. What is the conflict ID computed from, and what would have made it a different conflict?
3. In step 4 the file was resolved and `git status -s` said `UU`. What is the purpose of that state, and which setting removes it?
4. In the failure scenario, at which moment could you have seen the wrong value before it became a commit? Name two commands.
5. Why does the recovery need `git rerere forget`? What would happen at the next rebase if you had only fixed the file and committed?
6. The setup sets `maintenance.rerere-gc.auto=0`. What is the symptom it avoids, and how would you recover from that symptom without the setting?

## Lab 14.6: Stash anatomy

### Objective

Take a stash entry apart: its commits, their trees, the ref and its reflog. Read single files out of it. Then lose your staging with a plain `git stash pop` and rebuild the index from the second parent of the dropped stash commit.

### Prerequisites

- Chapter 14C, section 14C.2.
- Chapter 11 (Reset, Revert, Restore), section 11.11, and Lab 8.6.

### Setup

```bash
bash labs/ch14c/setup-14-6-stash-anatomy.sh
labs/shell m14-6
cd evalkit
```

The script builds `evalkit` with one commit and work in three forms: a staged change to `score.py` that you have reviewed, an unstaged experiment in `config.yaml`, and an untracked `notes.md`. Your stash entries will have other IDs than the book's, because a stash commit records the time.

### Commands

Step 1. Record the state you are about to stash.

```bash
git status -s
git diff --cached --stat
git diff --stat
```

Step 2. Stash everything, including the untracked file.

```bash
git stash push -u -m "wip: strip whitespace, threshold experiment"
git status -s
```

Step 3. Before you run this, draw the commits you expect and their parents. Then compare.

```bash
git log --graph --format='%h [%p] %s' 'stash@{0}'
git show -s --format=raw 'stash@{0}'
```

Step 4. For each of the three kinds of work, name the pair of commits (or the single commit) that holds it. Then check.

```bash
git diff --name-status 'stash@{0}^1' 'stash@{0}^2'
git diff --name-status 'stash@{0}^2' 'stash@{0}'
git ls-tree --name-only 'stash@{0}^3'
```

Step 5. The ref and its log.

```bash
cat .git/refs/stash
cat .git/logs/refs/stash
git reflog show stash
```

Step 6. Read files out of the entry without applying it.

```bash
git show 'stash@{0}:config.yaml'
git show 'stash@{0}^3:notes.md'
git restore --source='stash@{0}' -- config.yaml
git status -s
git restore config.yaml
```

Step 7. Bring everything back as it was.

```bash
git stash pop --index
git status -s
```

### Expected output

<!-- snippet: ch14c/lab-14-6-stash-anatomy/01-state -->
```text
$ cd evalkit
$ git status -s
 M config.yaml
M  score.py
?? notes.md
$ git diff --cached --stat
 score.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --stat
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-6-stash-anatomy/02-stash -->
```text
$ git stash push -u -m "wip: strip whitespace, threshold experiment"
Saved working directory and index state On main: wip: strip whitespace, threshold experiment
$ git status -s
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-6-stash-anatomy/03-commits -->
```text
$ git log --graph --format='%h [%p] %s' 'stash@{0}'
*-.   1cf63fc [ccfad67 3fcb57c 6ba256b] On main: wip: strip whitespace, threshold experiment
|\ \  
| | * 6ba256b [] untracked files on main: ccfad67 Add scorer and config
| * 3fcb57c [ccfad67] index on main: ccfad67 Add scorer and config
|/  
* ccfad67 [] Add scorer and config
$ git show -s --format=raw 'stash@{0}'
commit 1cf63fc58a41ae73184590973525f217729793a0
tree 54b39ce5676b4a5069098cb5a7ee2b0c18a98b93
parent ccfad67b81da3bdd5dd768d8cd299aa6eff9ade7
parent 3fcb57cdcc1bce29c8cfdbf2edf8901c50ce8349
parent 6ba256bf4a128e0886329aca3dc770d98351b1b0
author Lab User <you@example.com> 1788756060 +0530
committer Lab User <you@example.com> 1788756060 +0530

    On main: wip: strip whitespace, threshold experiment
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-6-stash-anatomy/04-trees -->
```text
# Staged part: first parent against second parent.
$ git diff --name-status 'stash@{0}^1' 'stash@{0}^2'
M	score.py
# Unstaged part: second parent against the stash commit.
$ git diff --name-status 'stash@{0}^2' 'stash@{0}'
M	config.yaml
# Untracked part: the tree of the third parent.
$ git ls-tree --name-only 'stash@{0}^3'
notes.md
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-6-stash-anatomy/05-ref -->
```text
$ cat .git/refs/stash
1cf63fc58a41ae73184590973525f217729793a0
$ cat .git/logs/refs/stash
0000000000000000000000000000000000000000 1cf63fc58a41ae73184590973525f217729793a0 Lab User <you@example.com> 1788756060 +0530	On main: wip: strip whitespace, threshold experiment
$ git reflog show stash
1cf63fc stash@{0}: On main: wip: strip whitespace, threshold experiment
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-6-stash-anatomy/06-single-files -->
```text
$ git show 'stash@{0}:config.yaml'
threshold: 0.7
metric: exact
$ git show 'stash@{0}^3:notes.md'
Try threshold 0.6 and 0.8 before deciding.
# Take one file out of the entry and leave the entry where it is:
$ git restore --source='stash@{0}' -- config.yaml
$ git status -s
 M config.yaml
$ git restore config.yaml
```
<!-- /snippet -->

<!-- snippet: ch14c/lab-14-6-stash-anatomy/07-pop-index -->
```text
$ git stash pop --index
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   score.py

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   config.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.md

Dropped refs/stash@{0} (1cf63fc58a41ae73184590973525f217729793a0)
$ git status -s
 M config.yaml
M  score.py
?? notes.md
```
<!-- /snippet -->

### What happened internally

- `git stash push -u` created three commits. `I` (`index on main: ...`) has the old HEAD as its parent and the index as its tree. `U` (`untracked files on main: ...`) has no parent and a tree with `notes.md` only. `W`, the stash commit, has the old HEAD, `I` and `U` as parents and your tracked files as its tree. Then Git reset the index and the tracked files to HEAD and removed `notes.md`.
- `refs/stash` was created and points at `W`. `logs/refs/stash` got one line. `stash@{0}` is that line.
- `git show 'stash@{0}:config.yaml'` and `git restore --source='stash@{0}'` treat `W` as what it is: a commit with a tree. They do not need the stash machinery.
- `git stash pop --index` merged `W` into the working tree, restored the index from `I`, wrote the untracked file from `U`, deleted the reflog line and printed the ID of the commit it let go of. Without other entries, `refs/stash` was deleted as well.

### Checkpoint

- `git status -s` prints ` M config.yaml`, `M  score.py` and `?? notes.md`: the state of step 1.
- `git stash list` prints nothing.

### Failure scenario

Stash again, and bring the work back the way most people do.

```bash
git stash push -u -m "wip: strip whitespace, threshold experiment"
git stash pop
git status -s
git diff --cached --stat
```

<!-- snippet: ch14c/lab-14-6-stash-anatomy/08-failure -->
```text
$ git stash push -u -m "wip: strip whitespace, threshold experiment"
Saved working directory and index state On main: wip: strip whitespace, threshold experiment
$ git stash pop
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   config.yaml
	modified:   score.py

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.md

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (6df660bb7022f96f4a4878429d0dc9eab1c37cef)
$ git status -s
 M config.yaml
 M score.py
?? notes.md
$ git diff --cached --stat
```
<!-- /snippet -->

Nothing is missing from disk, and something is lost all the same: `score.py` is now ` M`, unstaged, like the experiment in `config.yaml`. You no longer know which change you had reviewed and staged. The entry is dropped. Copy the ID from the last line of the `pop` output before you go on; in the book it is `6df660b`, and yours is different.

### Recovery

The dropped commit still exists, and its second parent is the index as it was. Compare that commit with HEAD to see what was staged, then copy its tree into the index. Replace the ID with yours.

```bash
git diff --name-status HEAD '6df660b^2'
git restore --staged --source='6df660b^2' -- .
git status -s
```

<!-- snippet: ch14c/lab-14-6-stash-anatomy/09-recovery -->
```text
# The second parent of the dropped stash commit still holds the index as it was:
$ git diff --name-status HEAD '6df660b^2'
M	score.py
$ git restore --staged --source='6df660b^2' -- .
$ git status -s
 M config.yaml
M  score.py
?? notes.md
```
<!-- /snippet -->

`git restore --staged --source=<commit>` writes index entries from a commit and leaves the working tree alone, so the unstaged experiment and the untracked file are untouched. If the ID has scrolled away, find the dropped commit with the `git fsck --unreachable` recipe of Lab 8.6.

### Verification

```bash
git diff --cached --stat
git diff --stat
git stash list
```

<!-- snippet: ch14c/lab-14-6-stash-anatomy/10-verification -->
```text
$ git diff --cached --stat
 score.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --stat
 config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git stash list
```
<!-- /snippet -->

The staged and the unstaged change are the ones of step 1.

### Questions

1. Why does a stash commit have its index commit as a parent, when a tree would have been enough to record the index?
2. `git stash show -p` would have printed the changes to `score.py` and `config.yaml` together. Which two `git diff` commands separate them?
3. What is `stash@{0}` in terms of files in `.git`? What would `stash@{1}` be after a second `git stash push`?
4. Why did the plain `git stash pop` leave `score.py` unstaged, and under which condition does a plain pop stage something anyway?
5. The recovery used `git restore --staged --source='<id>^2' -- .`. Why was it safe for your unstaged and untracked work, and for how long does the commit `<id>` stay available?
