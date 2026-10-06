# Troubleshooting playbook

> **Baseline.** Git 2.55.0 on macOS; GitHub CLI 2.88.1; GitHub facts as of 1 October 2026. This is the field manual for [Chapter 29: Production Troubleshooting](../textbook/ch29-production-troubleshooting.md). Every command here is run in that chapter or in the chapter cited beside it. GitHub-side commands were checked against `gh <command> --help` and were not executed.

Use this file during a problem. It has no explanations: each line points to the chapter that has them. Read section 1 now, before you need it.

Risk labels: 🟢 SAFE reads state or only adds objects and refs. 🟡 CAUTION moves refs or rewrites local history; recoverable through the reflog. 🔴 DANGEROUS can destroy uncommitted work, remote history, or the safety net itself.

| Section | Use it when |
|---|---|
| 1 | The first minute: what not to do |
| 2 | The checklist, start to finish |
| 3 | The ten commands and what to look for |
| 4 | Git refuses to work, or HEAD is detached: an operation in progress |
| 5 | Before the first command that changes anything: preserve |
| 6 | Decision trees by symptom |
| 7 | The symptom catalog, compact |
| 8 | Evidence on GitHub |
| 9 | Choosing the fix |
| 10 | Verifying and closing |
| 11 | Templates: root-cause box, option table, handover note |

## 1. The first minute

1. **Stop typing.** Waiting loses nothing. Git keeps unreachable commits for weeks ([Chapter 13](../textbook/ch13-recovery.md), section 13.4). The second "fix" is what destroys things.
2. **Do not run any of these until the root cause is written down:**

| Command | Why not now |
|---|---|
| 🔴 `git reset --hard`, `git restore <path>`, `git checkout -- <path>`, `git clean` | Destroy uncommitted work. No object, no reflog, no recovery |
| 🔴 `git push --force` in any form | Turns one clone's problem into every clone's problem |
| 🔴 `git gc`, `git prune`, `git reflog expire`, `git stash clear`, `git stash drop` | Remove the safety net |
| 🔴 `git merge --abort` | Resets the index and working tree: every resolution made so far and every edit staged during the merge is discarded (8.21) |
| 🟡 `git rebase --abort`, `git cherry-pick --abort`, `git revert --abort` | Reset the index and working tree; commits made inside a stopped rebase leave the branch |
| 🟡 `git pull` | A fetch plus an integration: it changes your branch |
| 🔴 `rm` inside `.git` | Ends Git's bookkeeping without undoing the operation |
| Deleting the clone and cloning again | Destroys the reflogs, the stashes, the unpushed commits and all evidence |

3. **Ask the reporter three things:** the exact text on the screen; the last three commands; what was done since.
4. **Copy the terminal scrollback into a file.** Git prints the ID you will need in lines such as `Deleted branch x (was ...)`, `HEAD is now at ...`, `Dropped refs/stash@{0} (...)`, and in the warning on leaving a detached HEAD ([Chapter 13](../textbook/ch13-recovery.md), section 13.7).
5. **If a credential is in the history: revoke it first.** Diagnosis comes second.
6. **If production is down: restore service first**, by the documented rollback, and diagnose on preserved evidence.

## 2. The checklist

Eleven steps ([Chapter 1](../textbook/ch01-fundamentals.md), section 1.10) in three phases. Tick each line.

```text
PHASE 1  READ-ONLY  (only 🟢 commands)
[ ]  1 SYMPTOM          Written down in the reporter's words, with the exact message. No interpretation.
[ ]  2 OBSERVE          git status. Read the FIRST LINE: a branch, a detached HEAD, or an operation.
[ ]  3 COLLECT          The ten commands (section 3). Output saved to a file.
[ ]  4 UNDERSTAND       State table filled in (below).
[ ]  5 HYPOTHESES       At least three mechanisms that would produce this symptom from this state.
[ ]  6 TEST             For each: the command whose output differs if it is true. Run it. Note the result.
[ ]  7 ROOT CAUSE       The seven-line box (section 11). Layer named: Git, GitHub, or GitHub Actions.

PHASE 2  PRESERVE  (adds refs and files, removes nothing)
[ ]    Output recorded. Backup ref on HEAD and on every candidate commit.
[ ]    Uncommitted work or an operation in progress?  ->  copy of the whole directory.
[ ]    Evidence must leave the machine?               ->  bundle.

PHASE 3  CHANGE
[ ]  8 SELECT           Option table (section 11): what each fix changes, its label, how it is undone.
[ ]  9 EXECUTE          Preview, then one change at a time. Read the output of each before the next.
[ ] 10 VERIFY           Symptom gone; state changed for the predicted reason; every copy agrees; nothing else changed.
[ ] 11 PREVENT          One habit, setting or rule, named and applied.
[ ]    Clean up: rescue refs, evidence directory, bundle.
```

**The state table.** Fill it in from the outputs. "Unknown" is a valid entry and tells you which command to run next.

| Place | What it holds now | Command |
|---|---|---|
| Working tree | Modified, untracked, ignored paths | `git status`, `git diff`, `git status --ignored` |
| Index | Staged paths; conflict stages | `git diff --cached`, `git ls-files -s`, `git ls-files -u` |
| HEAD | Branch name, or a raw ID; operation in progress | `git status`, `cat .git/HEAD` |
| Current branch | Commit, upstream, ahead and behind | `git branch -vv`, `git status -sb` |
| Other refs | Other branches, tags, remote-tracking branches, stash | `git for-each-ref`, `git stash list` |
| Reflogs | The sequence of events | `git reflog`, `git reflog show <branch>` |
| The server | The refs it holds right now | `git ls-remote origin` |
| GitHub | Pushes, rule evaluations, checks | Section 8 |

**The four questions that solve most cases.** Nearly every symptom is a difference between two places that someone assumed were equal.

| Assumed equal | Check |
|---|---|
| Working tree and last commit | `git status`, `git diff`, `git diff --cached` |
| HEAD and the branch | First line of `git status`; `git rev-parse --abbrev-ref HEAD` |
| The branch and its upstream; the upstream and the branch you push to | `git branch -vv`; `git rev-parse --abbrev-ref @{upstream}` |
| The remote-tracking branch and the server | `git rev-parse origin/<branch>` against `git ls-remote origin <branch>` |

## 3. The ten commands

Run all of them, in this order, every time ([Chapter 1](../textbook/ch01-fundamentals.md), section 1.11; applied in [Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.3). All are 🟢.

```bash
git status
git branch -vv
git remote -v
git log --graph --decorate --oneline --all
git reflog
git rev-parse HEAD @{upstream}; git rev-parse --abbrev-ref HEAD; git rev-parse --show-toplevel
git show --stat HEAD
git diff
git diff --cached
git config list --show-origin --show-scope
git ls-files
```

On a Git older than 2.46, `git config --list --show-origin --show-scope`. If the branch has no upstream, `@{upstream}` fails: that is a finding, not an obstacle.

| # | Command | Reveals | Look for |
|---|---|---|---|
| 1 | `git status` | Current branch; relation to the upstream at the last fetch; staged, unstaged, untracked | First line not "On branch": `HEAD detached`, `rebase in progress`. "You have unmerged paths". "ahead", "behind", "have diverged". No upstream line at all |
| 2 | `git branch -vv` | Every local branch, its commit, its upstream | The star on `(no branch, ...)` or `(HEAD detached ...)`. Brackets that name an unexpected branch. `gone`. No brackets |
| 3 | `git remote -v` | Which repositories this one talks to | More than one remote. Fetch and push URLs that differ. HTTPS where SSH was expected. A fork where the main repository was expected |
| 4 | `git log --graph --decorate --oneline --all` | Shape of the history; where every name points | Commits with no name beside them. `origin/x` and `x` on different commits. `refs/stash`. The same subject twice |
| 5 | `git reflog` | What HEAD did, newest first | `reset: moving to`, `rebase (start)` without `rebase (finish)`, `checkout: moving from`, `commit (amend)`, `pull` |
| 6 | `git rev-parse` | Exact IDs; whether HEAD is a branch; which repository this is | `HEAD` and `@{upstream}` differ. `--abbrev-ref HEAD` prints `HEAD`. An unexpected top-level directory |
| 7 | `git show --stat HEAD` | The last commit: author, date, files | Not the commit the reporter means. A file missing from the list. An unexpected author address |
| 8 | `git diff` | Working tree against index | Work that is in no commit. Whole-file changes (line endings, modes) |
| 9 | `git diff --cached` | Index against HEAD | Staged work that was never committed |
| 10 | `git config list --show-origin --show-scope` | Every setting and its file | `branch.<name>.merge` naming another branch. `pull.*`, `push.*`, `core.autocrlf`, `core.hooksPath`, `url.*.insteadOf`. A `user.email` from an unexpected scope |
| 11 | `git ls-files` | The tracked paths | The file under discussion is absent. A file that should be ignored is present |

**Save the output** before anything else changes it:

```bash
mkdir ../evidence
{ git status; git branch -vv; git log --graph --decorate --oneline --all; git reflog; } > ../evidence/state.txt 2>&1
git diff > ../evidence/unstaged.patch
git diff --cached > ../evidence/staged.patch
```

**The extended toolbox.** All 🟢. Reach for these when testing a hypothesis.

| Question | Command |
|---|---|
| Branch, upstream and counts in one line | `git status -sb` |
| Every ref with its upstream and distance | `git for-each-ref --format='%(refname) %(objectname:short) %(upstream:short) %(upstream:track)'` |
| How far apart are A and B | `git rev-list --left-right --count A...B` |
| Which commits are on one side only | `git log --oneline --left-right A...B` |
| Where two histories split | `git merge-base A B` |
| Which branches or tags contain a commit | `git branch -a --contains <id>`; `git tag --contains <id>` |
| Is A an ancestor of B | `git merge-base --is-ancestor A B` (exit status 0 means yes) |
| Is the same change present under another ID | `git cherry -v <upstream> <branch>`; `git range-diff <base> <old> <new>` |
| What the server holds right now | `git ls-remote origin` |
| What push and pull are configured to do | `git remote show origin` |
| When and how a ref moved | `git reflog show --date=iso <ref>` |
| What an object is | `git cat-file -t <id>`; `git cat-file -p <id>` |
| Why a path is ignored | `git check-ignore -v <path>`; for a tracked path add `--no-index` |
| Where one setting comes from | `git config get --show-origin --show-scope --all <key>` |
| Which commit introduced or removed a string | `git log -S<string> --oneline`; with merges, add `--full-history -- <path>` |
| What a merge resolution changed by hand | `git show --remerge-diff <merge>` |
| Would a merge conflict, touching nothing | `git merge-tree --write-tree --name-only A B` (exit status 1 lists the files) |
| Is the object store intact; what is unreachable | `git fsck`; `git fsck --lost-found` (writes under `.git/lost-found/`) |
| Is work parked elsewhere | `git stash list`; `git worktree list` |
| What Git executes and sends | `GIT_TRACE=1 git <command>`; `GIT_CURL_VERBOSE=1`; `ssh -vT git@github.com` |

Three diagnostic commands are not strictly read-only. `git fetch` moves remote-tracking refs and, with pruning, deletes stale ones with their reflogs: record `git rev-parse origin/<branch>` first when the old value is evidence, or use `git ls-remote`. `git fsck --lost-found` writes files. `git status` may refresh the index; `git --no-optional-locks status` avoids that.

## 4. An operation in progress

Symptoms: "cannot switch branch while merging", "you need to resolve your current index first", "HEAD detached", commits that "are not on the branch", a push that says "Everything up-to-date". Mechanisms: [Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.6.

```bash
git status                                                        # the first lines name the operation
cat .git/HEAD                                                     # "ref: refs/heads/..." or a raw ID
ls .git | grep -E "_HEAD$|rebase-|sequencer|BISECT_LOG"           # the state files
```

`ORIG_HEAD` and `FETCH_HEAD` in that listing are records of past commands, not operations.

| Operation | `git status` says | State in `.git` | HEAD | Continue | Leave and restore 🟡 | Leave, keep the current state |
|---|---|---|---|---|---|---|
| Merge | "You have unmerged paths" / "All conflicts fixed but you are still merging" | `MERGE_HEAD`, `MERGE_MODE`, `MERGE_MSG`, `AUTO_MERGE` | on the branch | `git commit` or `git merge --continue` | `git merge --abort` | `git merge --quit` |
| Rebase | "interactive rebase in progress; onto ..." / "rebase in progress" | `rebase-merge/` or `rebase-apply/`, `REBASE_HEAD` | detached | `git rebase --continue` | `git rebase --abort` | `git rebase --quit` |
| Cherry-pick | "You are currently cherry-picking commit ..." | `CHERRY_PICK_HEAD`; `sequencer/` for several commits | on the branch | `git cherry-pick --continue` | `git cherry-pick --abort` | `git cherry-pick --quit` |
| Revert | "You are currently reverting commit ..." | `REVERT_HEAD`; `sequencer/` for several commits | on the branch | `git revert --continue` | `git revert --abort` | `git revert --quit` |
| Bisect | "You are currently bisecting, started from branch ..." | `BISECT_LOG`, `BISECT_START`, `BISECT_TERMS`, `refs/bisect/*` | detached | `git bisect good` / `bad` | `git bisect reset` | `git bisect reset HEAD` |

What the files tell you:

| File | Content |
|---|---|
| `.git/MERGE_HEAD` | The commit being merged in (the future second parent) |
| `.git/ORIG_HEAD` | The tip before the last merge, rebase or reset |
| `.git/rebase-merge/head-name` | The branch that will be moved when the rebase ends |
| `.git/rebase-merge/orig-head` | Where that branch was when the rebase started; `--abort` returns here |
| `.git/rebase-merge/onto` | The new base |
| `.git/rebase-merge/done`, `git-rebase-todo` | Picks completed; picks remaining |
| `.git/REBASE_HEAD` | The commit whose replay stopped |
| `.git/CHERRY_PICK_HEAD`, `.git/REVERT_HEAD` | The commit being applied; the commit being undone |
| `.git/sequencer/head`, `todo` | The tip before the first pick; the current pick and those remaining |
| `.git/BISECT_START`, `BISECT_LOG` | The branch to return to; the replayable record of marks |

```text
  Operation in progress
   |
   +-- Did anyone commit or edit since it stopped?      git log <branch>..HEAD ; git status ; git diff
   |     |
   |     +-- yes --> ANCHOR FIRST:  git branch rescue/<what> HEAD
   |     |           uncommitted edits?  -->  cp -Rp . ../evidence/<name>-copy
   |     +-- no
   |
   +-- Was the operation intended, and is the resolution known?
   |     +-- yes --> resolve, git add <path>, then the "Continue" command
   |     +-- no  --> the "Leave and restore" command  (after the anchor)
   |
   +-- Rebase stopped on a PUBLISHED branch with new commits inside (case 1 of Chapter 29)
         --> anchor, git rebase --abort, git cherry-pick the new commits, git push   (no force)
```

Never delete the state files by hand. A merge whose `MERGE_HEAD` was removed is committed with one parent, and Git still considers the branch unmerged (Lab 35.2).

## 5. Preserve before you change

Mechanisms: [Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.7; [Chapter 13](../textbook/ch13-recovery.md), section 13.14. All 🟢.

| Layer | Command | Holds | Misses |
|---|---|---|---|
| Recorded output | Section 3, "Save the output" | What you saw; uncommitted changes as patches | Objects |
| Backup ref | `git branch rescue/<what> <id>` or `git update-ref refs/backup/<name> <id>` | The commit and all it reaches | Reflogs, index, uncommitted files, operation state |
| Copy | `cp -Rp . ../evidence/<name>-copy` | Everything local, including the index, stashes, reflogs and operation state | What only the server has |
| Bundle | `git bundle create ../evidence/<name>.bundle --all`, then `git bundle verify <file>` | All refs and HEAD with their objects, in one movable file | Reflogs, unreachable objects, index, uncommitted files, configuration, hooks |

Order: record, anchor, copy, bundle. A bundle holds only what refs and HEAD reach, so anchor first.

```text
  What is about to happen?                                 Minimum preservation
  -------------------------------------------------------  -----------------------------------
  A ref will move (reset, rebase, amend, branch -f)        backup ref
  A force push                                             backup ref + note the server's old ID (git ls-remote)
  An --abort, or any command on a dirty working tree       copy of the directory
  The disk or the object store is suspect                  bundle, stored on another machine
  Someone else will ask what happened                      recorded output with the commands
```

Getting things back:

```bash
git fetch ../evidence/<name>.bundle 'refs/heads/rescue/*:refs/heads/rescue/*'    # refs from a bundle
git -C ../evidence/<name>-copy status                                           # the copy is a full repository
git -C ../evidence/<name>-copy reflog
```

A copy contains every secret the original contains. Delete the evidence directory when the incident is closed.

## 6. Decision trees

### 6.1 Something is missing

```text
  What is missing?
   |
   +-- A commit --------------------------------------------------------------------------------+
   |    git branch -a --contains <id>          on another branch?             -> switch or cherry-pick
   |    git status (first line)                detached HEAD / operation?     -> section 4
   |    git reflog show <branch>               reset, rebase, amend?          -> git branch rescue/x <id>   (Ch 13, 13.8)
   |    git ls-remote origin                   not pushed / pushed elsewhere? -> push the right branch      (Ch 12, 12.14)
   |    git log --all --oneline -- <path>      never committed?               -> git status, git diff       (Ch 1, 1.12)
   |
   +-- A branch --------------------------------------------------------------------------------+
   |    git branch -a                          only origin/<name> exists?     -> git switch <name>          (Ch 7, 7.10)
   |    git reflog                             "moving from <name>" entries?  -> git branch <name> <id>     (Ch 13, 13.8)
   |    git ls-remote origin                   gone on the server too?        -> another clone; section 8
   |    git fsck --lost-found                  no reflog names it?            -> inspect the dangling commits (Ch 13, 13.6)
   |    git worktree list                      another worktree?              -> look there                 (Ch 25, 25.2)
   |
   +-- Uncommitted work ------------------------------------------------------------------------+
   |    git stash list                         stashed?                       -> git stash show -p ; apply  (Ch 11, 11.11)
   |    was it ever staged with git add?       yes -> git fsck --lost-found, .git/lost-found/other          (Ch 13, 13.9)
   |                                           no  -> Git has no object: editor history, backups           (Ch 13, 13.12)
   |
   +-- Code that was there before a merge ------------------------------------------------------+
        git log --full-history --oneline -- <path>
        git show --remerge-diff <merge>        a conflict resolved by taking one side              (Ch 8, 8.15, 8.16)
        git log -S<string> --oneline           the commit that removed the string                  (Ch 14A, 14A.11)
```

### 6.2 A push is rejected

```text
  Read the line that starts with "!"
   |
   +-- ! [rejected] ... (fetch first) | (non-fast-forward)        written by YOUR Git
   |     git fetch ; git status -sb ; git branch -vv
   |      |
   |      +-- brackets name ANOTHER branch than the one you push to    -> upstream is wrong (Ch 29, 29.4)
   |      |       git branch --set-upstream-to=origin/<branch>
   |      +-- [ahead N, behind M]
   |      |       your commits unpublished?  -> git rebase   or   git merge @{upstream} ; then push
   |      +-- the fetch printed "+ ... (forced update)"               -> the server branch was rewritten
   |              STOP. git reflog show origin/<branch> has the old tip.                    (Ch 13, 13.10)
   |
   +-- ! [remote rejected] ... with "remote:" lines              written by the SERVER
   |      a rule, a hook, push protection, a size limit: the remote: lines say which
   |      gh ruleset check <branch>   -> follow the policy, usually a pull request          (Ch 18, 18.17)
   |
   +-- error: src refspec <name> does not match any            no such local branch, or no commit yet  (Ch 12, 12.15)
   +-- fatal: The current branch has no upstream branch        git push -u origin <branch>             (Ch 12, 12.5)
   +-- Permission denied / not found / 403                     section 6.6
   +-- Everything up-to-date, but the commit is not there      the commit is not on that branch -> 6.1

  NEVER answer a rejection with --force. If a rewrite is truly intended:
  git push --force-with-lease=<branch>:<expected-old-id>      🔴                                (Ch 12, 12.8)
```

### 6.3 A pull refuses, or pulls nothing

```text
  git status -sb ; git branch -vv
   |
   +-- "Need to specify how to reconcile divergent branches"   look first: git log --oneline --graph HEAD @{upstream}
   |                                                           then git pull --rebase  or  git pull --no-rebase  (Ch 12, 12.6)
   +-- "Not possible to fast-forward"                          pull.ff=only: git config get --show-origin --all pull.ff
   +-- "Your local changes ... would be overwritten"           commit them, or git stash, then pull           (Ch 11, 11.11)
   +-- "There is no tracking information"                      no upstream: git branch --set-upstream-to=origin/<branch>
   +-- an operation is in progress                             section 4
   +-- "refusing to merge unrelated histories"                 two different root commits: wrong remote?       (Ch 8, 8.18)
   +-- "Already up to date", teammate's commit absent
          git branch -vv            upstream is another branch                                  (Ch 29, 29.4)
          git ls-remote origin      the teammate did not push, or pushed elsewhere
          git config get --all remote.origin.fetch     a narrow refspec                         (Ch 12, 12.12)
```

### 6.4 A file behaves strangely

```text
  Is the path tracked?      git ls-files <path>
   |
   +-- NOT tracked, and git status does not list it
   |     git check-ignore -v <path>       prints file:line:pattern   -> an ignore rule          (Ch 4, 4.5)
   |     git status --ignored
   |     git rev-parse --show-toplevel    another repository, or a nested one                   (Ch 23, 23.2)
   |     an empty directory               Git tracks no directories                             (Ch 4, 4.11)
   |
   +-- tracked, and it KEEPS showing as modified
   |     listed in .gitignore too?        ignore rules do not apply to tracked files            (Ch 4, 4.6)
   |     git diff --stat  vs  git diff --ignore-cr-at-eol --stat     line endings               (Ch 14C, 14C.5)
   |     git ls-files --eol <path>
   |     git diff --summary               "mode change 100644 => 100755"                        (Ch 4, 4.10)
   |     git ls-files | sort -f | uniq -di    two names differing only in case                  (Ch 4, 4.12)
   |     git check-attr -a -- <path>      a filter (LFS) or an attribute                        (Ch 22, 22.5)
   |
   +-- tracked, the content is a three-line pointer ("version https://git-lfs...")
   |     git lfs ls-files ; git lfs env ; git lfs status                                        (Ch 22, 22.7, 22.10)
   |
   +-- tracked with mode 160000 (git ls-files -s <path>)
         a submodule: git submodule status ; git diff --submodule                               (Ch 23, 23.3, 23.7)
```

### 6.5 A pull request or a check looks wrong

```text
  The pull request shows too many commits or files
     git fetch origin
     git log --oneline origin/<base>..<head>          the commits it lists
     git diff --stat origin/<base>...<head>           the files it shows (three dots: from the merge base)
     git merge-base origin/<base> <head>              older than expected?
      +-- wrong base branch                           change the base, or git rebase --onto   (Ch 17, 17.12)
      +-- branch reused after a squash merge          merge the base in, or move the new commits
      +-- every line of a file changed                git diff --ignore-cr-at-eol --stat      (Ch 14C, 14C.5)

  The pull request cannot be merged
     gh pr view <n> --json mergeable,mergeStateStatus,reviewDecision
     gh pr checks <n> --required
     gh ruleset check <base>
     git merge-tree --write-tree --name-only origin/<base> HEAD     conflicts?                (Ch 18, 18.17)

  A required check stays pending forever
     the workflow was skipped by a path filter, a branch filter or [skip ci]: it never reports
     the required name matches no job ; the event does not count ; merge queue without merge_group   (Ch 18, 18.8)

  CI fails only on the pull request
     the run builds refs/pull/<n>/merge = head merged into the CURRENT base, not your branch   (Ch 17, 17.2, 17.6)
     reproduce: git fetch origin ; merge origin/<base> into a scratch branch ; run the tests
     git status --ignored ; git ls-files      a file that exists only on your machine
     gh run view <run-id> --log-failed
     also: shallow clone without tags, secrets withheld from forks, case-sensitive runner    (Chapters 20A, 20B)
```

### 6.6 Access is refused

```text
  Which line carries the cause?   Never "fatal: Could not read from remote repository."  Read the line ABOVE it. (Ch 16, 16.17)
   |
   +-- SSH
   |    Permission denied (publickey)            ssh -T git@github.com ; ssh-add -l ; ssh -G github.com   (Ch 16, 16.18)
   |    Host key verification failed             ssh-keygen -l -F github.com ; compare with the published keys  (16.11)
   |    connect to host ... port 22              ssh -T -p 443 git@ssh.github.com                               (16.12)
   |    Permission to OWNER/REPO denied to USER  the key belongs to another account                             (16.18)
   |
   +-- HTTPS
   |    Repository not found                     the repository exists? then the credential has no access to it
   |                                             git remote -v ; gh auth status                                 (16.19)
   |    Authentication failed (401)              expired or revoked token, or a password                        (16.19)
   |    returned error: 403                      authenticated, not permitted: scope, SSO, role, policy         (16.15)
   |    could not read Username ... prompts disabled     no helper answered
   |                                             git config get --show-origin --all credential.helper           (16.5)
   |
   +-- The commit is not linked to my account    git log -1 --format='%an <%ae>'
                                                 git config get --show-origin --show-scope --all user.email    (Ch 14B, 14B.2)
```

## 7. The symptom catalog, compact

Likely causes in the order worth testing; the first command to run; where the mechanism is. Full version: [Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.11.

### History and refs

| Symptom | Likely causes | First commands | Mechanism |
|---|---|---|---|
| A commit is missing | Other branch; detached HEAD or stopped operation; reset, rebase or amend; not pushed; never staged | `git branch -a --contains <id>`; `git status`; `git reflog show <branch>`; `git ls-remote origin` | Ch 13, 13.7, 13.8; Ch 12, 12.14; Ch 29, 29.3 |
| A branch disappeared | Only a remote-tracking branch; deleted locally; deleted on the server and pruned; renamed; other worktree | `git branch -a`; `git reflog`; `git ls-remote origin`; `git fsck --lost-found` | Ch 13, 13.8, 13.15; Ch 12, 12.11 |
| HEAD detached | Tag, ID or `origin/x` checked out; rebase or bisect in progress; inside a submodule; CI checkout | `git status`; `cat .git/HEAD`; `git reflog -5` | Ch 7, 7.7; Ch 29, 29.6; Ch 23, 23.5 |
| Commits duplicated | Published branch rebased, then merged with its old copy; cherry-picked then merged; squash-merged branch reused | `git cherry -v <upstream> <branch>`; `git range-diff A...B` | Ch 9, 9.3, 9.15; Ch 10, 10.10 |
| A merge brought nothing ("Already up to date") | Merged before and the merge was reverted; change removed later; `-s ours`; stale local branch merged | `git merge-base --is-ancestor <branch> HEAD`; `git log --oneline --merges --grep=Revert` | Ch 11, 11.9; Ch 8, 8.3 |
| Unexpected merge conflict | Adjacent lines; old merge base (squash reuse, criss-cross); rename or reformat; line endings; sides exchanged in a rebase | `git merge-base A B`; `git ls-files -u`; `git diff --ignore-cr-at-eol` | Ch 8, 8.7, 8.11; Ch 9, 9.11 |
| Code vanished after a merge | Conflict resolved by taking one side; history simplification hides it | `git show --remerge-diff <merge>`; `git log --full-history --oneline -- <path>` | Ch 8, 8.15, 8.16; Ch 14A, 14A.10 |
| A tag points somewhere else | Tag moved on the server after you fetched; local tag never pushed; lightweight against annotated | `git rev-parse <tag>^{commit}`; `git ls-remote --tags origin <tag>` | Ch 14B, 14B.10, 14B.11 |
| `git branch -d`: "not fully merged" after the pull request merged | Squash or rebase merge made new IDs; commits added after the merge; upstream gone | `git cherry -v origin/main <branch>`; `git branch -vv` | Ch 17, 17.9; Ch 7, 7.5 |
| `git log -- <file>` stops early; blame shows one commit | Rename; formatting commit; shallow clone | `git log --follow --oneline -- <file>`; `git rev-parse --is-shallow-repository` | Ch 4, 4.9; Ch 14A, 14A.10, 14A.17 |

### Working tree and index

| Symptom | Likely causes | First commands | Mechanism |
|---|---|---|---|
| Git does not recognize a file | Ignore rule (three places); nested repository; empty directory; outside the sparse cone | `git check-ignore -v <path>`; `git status --ignored`; `git rev-parse --show-toplevel` | Ch 4, 4.3, 4.5, 4.11; Ch 24, 24.4 |
| A file keeps showing as modified | Tracked and ignored; line endings; mode bit; case collision; filter | Section 6.4 | Ch 4, 4.6, 4.10, 4.12; Ch 14C, 14C.5 |
| The change is on disk, not in the commit | Never staged; staged then edited again | `git status`; `git diff`; `git show --stat HEAD` | Ch 1, 1.12; Ch 5, 5.4 |
| Uncommitted work vanished | Hard reset, restore, an `--abort`; in a stash; `git clean`; other worktree | `git stash list`; `git fsck --lost-found`; `git worktree list` | Ch 11, 11.5; Ch 13, 13.9, 13.12 |
| Git refuses to switch, pull, merge or commit | An operation in progress | Section 4 | Ch 29, 29.6 |
| "Local changes would be overwritten" | A modified tracked file differs between the commits; an untracked file in the way | `git status --short`; `git diff --name-only HEAD <target>` | Ch 7, 7.6; Ch 11, 11.5 |
| "Unable to create .git/index.lock" | Another Git process (editor, IDE); a crashed process | Check running processes; close the editor integration; only then remove the lock | Ch 5, 5.15 |
| The stash is not where expected | One stack for the whole repository; dropped; `pop` stopped at a conflict and kept the entry | `git stash list`; `git stash show -p stash@{0}`; `git fsck --unreachable` | Ch 11, 11.11; Ch 14C, 14C.2 |

### Remotes, access and identity

| Symptom | Likely causes | First commands | Mechanism |
|---|---|---|---|
| A push is rejected | Server has commits you lack; upstream is another branch; a server rule; no permission | Section 6.2 | Ch 12, 12.7, 12.15; Ch 29, 29.4 |
| A pull refuses | Divergent branches; `pull.ff=only`; local changes; no upstream; operation in progress | Section 6.3 | Ch 12, 12.6 |
| "Everything up-to-date", commit not on the server | The commit is not on the pushed branch; other remote | `git branch -a --contains <id>`; `git status`; `git ls-remote origin` | Ch 12, 12.14; Ch 29, 29.3 |
| "Already up to date", teammate's commit absent | Upstream is another branch; not pushed; narrow refspec | `git branch -vv`; `git ls-remote origin` | Ch 29, 29.4; Ch 12, 12.4 |
| Permission denied (publickey) | No key offered; key on no account; wrong user; another account's key first | `ssh -T git@github.com`; `ssh-add -l`; `ssh -G github.com` | Ch 16, 16.18 |
| Repository not found | Credential of an account without access; typo or rename; token not granted; SSO | `git remote -v`; `gh auth status` | Ch 16, 16.19 |
| Authentication failed; error 403 | 401: token expired, revoked, or a password. 403: scope, SSO, role, policy | `gh auth status`; `GIT_CURL_VERBOSE=1 git ls-remote origin` | Ch 16, 16.19, 16.6 |
| Commit attributed to the wrong person or to nobody | `user.email` from an unexpected scope; address not on the account | `git log -1 --format='%an <%ae>'`; `git config get --show-origin --show-scope --all user.email` | Ch 14B, 14B.2; Ch 6, 6.11 |

### Pull requests, checks and CI

| Symptom | Likely causes | First commands | Mechanism |
|---|---|---|---|
| Pull request shows hundreds of changes | Wrong base; squash-merged branch reused; rebased or force-pushed; line endings or formatter | Section 6.5 | Ch 17, 17.12 |
| CI fails only on the pull request | Merge ref, not your branch; fork secrets; shallow clone; case-sensitive runner; file only on your machine | Section 6.5 | Ch 17, 17.2, 17.6; Chapters 20A, 20B |
| A required check never finishes | Workflow skipped and never reports; name matches no job; event does not count; no `merge_group` | `gh pr checks <n> --required`; `gh run list --commit <id>` | Ch 18, 18.8 |
| Pull request is "blocked" | Conflicts; not up to date; reviews; conversations; a rule from another layer | `gh pr view <n> --json mergeable,mergeStateStatus,reviewDecision`; `gh ruleset check <base>` | Ch 18, 18.17; Ch 19, 19.6 |

### Submodules, LFS and scale

| Symptom | Likely causes | First commands | Mechanism |
|---|---|---|---|
| Submodule at the wrong commit, or empty | Pointer moved and no `update`; not initialized; pointer names an unpushed commit; work on its detached HEAD | `git submodule status`; `git diff --submodule`; `git -C <path> status` | Ch 23, 23.3, 23.5, 23.7, 23.8 |
| LFS pointer files instead of content | LFS not installed or not set up; download skipped; object never uploaded; committed before tracking | `git lfs ls-files`; `git lfs env`; `git check-attr filter -- <path>` | Ch 22, 22.3, 22.7, 22.10 |
| "is already used by worktree" | The branch is checked out in another worktree | `git worktree list` | Ch 25, 25.4 |
| Everything is slow | Many loose objects or packs; huge working tree; missing commit-graph | `git count-objects -v` | Ch 26, 26.2 |

## 8. Evidence on GitHub

GitHub behavior, described from the documentation; labels in the interface change. Mechanisms and sources: [Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.8; [Chapter 13](../textbook/ch13-recovery.md), section 13.15.

| Question | Source | Limits |
|---|---|---|
| Which account moved a branch, when, from which commit to which? | Activity view (repository main page, "Activity"), filtered by branch and activity type; "Compare changes" on the entry | Access requirement and retention not stated in the documentation |
| Was a pull request branch force-pushed, deleted, restored, or given another base? | The pull request timeline | One pull request. "Restore branch" is on closed pull requests |
| What were the IDs before and after a push? | Events API: `PushEvent` fields `before`, `head`, `ref` | 300 events, 30 days, latency 30 seconds to 6 hours |
| Did a rule pass, fail, or get bypassed for a ref update? | Rule Insights; `rulesets/rule-suites` endpoint | Rulesets only. Exempt actors leave no bypass signal. Dashboard: Team and Enterprise Cloud |
| Who changed a rule, a role, a token; who overrode a classic protection? | Organization audit log | 180 days; owners only. Git events: enterprise log, seven days, REST API, streaming or export only |
| Is the old commit still on the server? | The pull request's `refs/pull/<n>/head`; a collaborator's clone | No published retention for commits that no ref reaches |

```bash
gh api "repos/OWNER/REPO/activity?activity_type=force_push&ref=refs/heads/main"
gh api repos/OWNER/REPO/issues/42/timeline --paginate
gh api repos/OWNER/REPO/events --jq '.[] | select(.type=="PushEvent") | [.created_at, .payload.ref, .payload.before, .payload.head] | @tsv'
gh api repos/OWNER/REPO/rulesets/rule-suites
gh ruleset check main
gh pr view 42 --json headRefOid,baseRefName,mergeable,mergeStateStatus,statusCheckRollup
git fetch origin pull/42/head:pr-42            # plain Git: the head of a pull request as a local branch
```

Flags to carry into any report you write:

- **Unverified:** a "restore" action inside the Activity view. Documented there: filtering and "Compare changes" only.
- **Unverified:** how long GitHub keeps commits that no ref reaches. Recreating a branch at an old ID through the references API is an inference from documented endpoints, not a documented procedure.
- The commit author field proves nothing about who pushed ([Chapter 14B](../textbook/ch14b-config-tags-signing.md), section 14B.18). The Activity view and the audit log record the authenticated account.
- Export time-limited evidence (Events API, enterprise Git events) on the first day.

## 9. Choosing the fix

Rank the candidate fixes with five questions, in this order ([Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.9):

1. Does it destroy uncommitted work?
2. Does it rewrite commits that another repository has?
3. Does it change the server?
4. Is it undone by one command?
5. Can it be previewed?

```text
  RISK LADDER: take the lowest rung that repairs the root cause
  1  add a ref                 git branch, git tag, git update-ref                    🟢  nothing can be lost
  2  add a commit              git commit, git revert, git cherry-pick, git merge     🟡  undone by a revert or the reflog
  3  move a local ref          git reset --keep, git rebase                           🟡  undone through the reflog or a backup ref
  4  overwrite the work tree   git reset --hard, git restore, git clean               🔴  uncommitted work is unrecoverable
  5  rewrite the server        git push --force-with-lease=<ref>:<expected>           🔴  others must repair their clones
  6  remove the safety net     git reflog expire, git gc --prune=now                  🔴  nothing undoes it
```

| Situation | Lowest-risk move | Avoid |
|---|---|---|
| A bad commit on a shared branch | `git revert <id>` 🟡, push | `git reset` plus a force push |
| A bad merge on a shared branch | `git revert -m 1 <merge>` 🟡, and read Chapter 11, section 11.9 before merging that branch again | Rewriting the branch |
| A bad commit that exists only locally | `git commit --amend` or `git reset --keep HEAD~1` 🟡 | `git reset --hard` |
| Lost commits found in the reflog | `git branch rescue/x <id>` 🟢, then `git merge --ff-only` or `git cherry-pick` 🟡 | `git reset --hard <id>` on a dirty tree |
| A branch must move back locally | `git reset --keep <id>` 🟡 | `git reset --hard <id>` |
| Diverged from the server, your commits unpublished | `git rebase` onto the upstream 🟡, or `git merge @{upstream}` | Force push |
| Diverged from the server, your commits published | `git merge @{upstream}` 🟡 | Rebase |
| A stopped operation with work inside | Anchor, then abort, then cherry-pick | A bare `--abort` |
| A file that must stop being tracked | `git rm --cached <path>` 🟡, commit; warn the team: their next pull deletes their copy (Chapter 4, section 4.6) | Editing `.gitignore` alone |
| A force push is truly required | Backup ref; note the server's old ID; `git push --force-with-lease=<branch>:<old-id>` 🔴; tell everyone | `git push --force` |

Previews:

```bash
git push --dry-run                                   # what a push would move
git merge-tree --write-tree --name-only A B          # would a merge conflict
git log --oneline <upstream>..HEAD                   # what a rebase would replay
git diff --stat HEAD <target>                        # what a reset to <target> would change
git clean -n                                         # what git clean would delete
cp -Rp . ../rehearsal                                # rehearse the fix in a copy
```

## 10. Verify and close

```text
[ ] 1 THE SYMPTOM     Repeat what showed it. The push succeeds; the page lists the expected commits.
[ ] 2 THE STATE       Repeat the diagnosis commands that exposed the cause.
                      git status: first line "On branch". git branch -vv: the right upstream, no ahead/behind.
                      ls .git | grep -E "_HEAD$|rebase-|sequencer|BISECT_LOG"   -> no state files.
[ ] 3 EVERY COPY      Compare IDs, not names:
                      git rev-parse HEAD @{upstream}      and      git ls-remote origin <branch>
                      then the colleague's clone, the pull request page, the pipeline run for that exact commit.
[ ] 4 NOTHING ELSE    git diff <backup> HEAD   or   git range-diff <base> <backup> HEAD   shows only the intended difference.
                      git fsck reports nothing. git status shows no leftovers.
[ ] 5 PREDICTION      Written down BEFORE the check, and matched.
[ ] 6 PREVENT         The habit, setting or rule is applied, not only named.
[ ] 7 CLEAN UP        git branch -D rescue/<what>   (prints the ID: one last safety line)
                      git update-ref -d refs/backup/<name> ; remove ../evidence and the bundle.
```

Prevention settings that remove whole rows of the catalog. Decide each one deliberately ([Chapter 14B](../textbook/ch14b-config-tags-signing.md), section 14B.5):

| Setting or habit | Removes |
|---|---|
| The first line of `git status` before every commit and push; a prompt that shows the state (`__git_ps1` from `git-prompt.sh`) | Work inside a forgotten operation or on a detached HEAD |
| `git switch -c <name> --no-track origin/main`; `push.autoSetupRemote=true`; or `branch.autoSetupMerge=simple` | The wrong-upstream loop |
| `pull.rebase` or `pull.ff` set on purpose | The "divergent branches" stop at a bad moment |
| `fetch.prune=true`, with the caveat of section 3 | Stale remote-tracking branches |
| A committed `.gitattributes` with `* text=auto` and explicit `eol` rules | Line-ending diffs and conflicts |
| A new branch from `main` for every pull request; automatic deletion of head branches | Reused branches after a squash merge |
| A ruleset that blocks force pushes and deletions on shared branches | Rewritten shared history |
| Required checks that always report (one aggregate job) | Checks that stay pending forever |

## 11. Templates

**The root-cause box.** Every explanation ends in these seven lines ([Chapter 1](../textbook/ch01-fundamentals.md), section 1.10).

```text
Observed behavior : what was seen, in the reporter's words and with the exact message
Git state         : what the working tree, index, HEAD, refs and remote held
Mechanism         : what Git (or GitHub, or Actions) does with that state
Root cause        : the one fact that, had it been different, would have prevented the symptom
Why Git does this : the design reason
Correct fix       : the lowest-risk change that repairs the state
Prevention        : what stops a silent recurrence
```

**The hypothesis table.**

```text
| Hypothesis | Evidence that would confirm it | Command | Result |
|------------|--------------------------------|---------|--------|
| H1         |                                |         |        |
| H2         |                                |         |        |
| H3         |                                |         |        |
```

**The option table.**

```text
| Option | What it changes | Risk label | How it is undone | Verdict |
|--------|-----------------|------------|------------------|---------|
| A      |                 |            |                  |         |
| B      |                 |            |                  |         |
```

**The handover note,** when you must leave a repository in the middle of something. Four lines prevent the next person from guessing.

```text
Repository and branch : <path>, <branch>
State                 : <first line of git status>; operation in progress: <none | which, step n of m>
Done so far           : <commits made, conflicts resolved and whether they are staged>
Do not                : <the command that would destroy something here, for example "git cherry-pick --abort">
Anchors               : <rescue refs, evidence directory>
```

**The four-part account for a CTO** (Phase 0 report, section 13): the symptom as observed; the mechanism, named at the right layer; the evidence that confirms it; the control that prevents recurrence. The incident summary and the postmortem template are in Chapter 30.
