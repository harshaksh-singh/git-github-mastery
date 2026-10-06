# V168: The stale clone that pushes the secret back, the GitHub side of a rewrite, and the controls that limit blast radius

- **Part.** 7, Security
- **Module.** 31
- **Planned minutes.** 22
- **Prerequisites.** V059, V167
- **Textbook sections.** [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md), sections 21B.18 to 21B.23
- **Demo scripts.** `labs/ch21b/rewrite-mechanics.sh` (snippets `09-stale-clone`, `10-secret-is-back`), `labs/ch21b/stale-clone-rebase.sh` (snippets `01-pull-rebase-first-contact`, `02-fetch-then-rebase`, `03-onto-old-base`), `labs/ch21b/lab-31-1-tabletop.sh` (from `04-eradicate-tip` to the end)

## HOOK

**[ON SCREEN]** "A day after a history rewrite the secret is back on `main`, and nobody force-pushed."

The cleanup was done properly. A fresh mirror clone, every ref rewritten, the scan clean, a forced push after a freeze. The next morning the scanner reports the same secret on `main` again. The branch rule that forbids force pushes was back on and it did not fire. Nobody did anything unusual. One colleague ran `git pull` and `git push`, as on every other morning.

Today you reconstruct from the commit graph how that happens, you learn the exact instruction to give colleagues about their clones, and you see what remains on GitHub that no Git command of yours can reach.

## INTRODUCTION

In V167 the rewrite ended with the server holding clean refs. That is the end of the command and the middle of the operation. Two things remain. Other people's clones still contain the complete old history, and Git sees nothing wrong with that history. And on GitHub there are copies that you cannot remove with Git.

From V059 you know what a rebased shared branch does to the people who use it: their copy still descends from the old commits. A whole-history rewrite is the same situation for every branch and every person at once.

The plan: first the failure, replayed in a terminal. Then the three ways a stale clone can meet the new history, and the one instruction that is safe to hand out. Then the rest of the tabletop lab, from eradication to prevention, including the failure repeated and recovered. Then the GitHub side, described from GitHub's documentation, and the governance controls of section 21B.20.

## LEARNING OBJECTIVES

After this video you can:

1. Reconstruct from the commit graph how a secret returns after a rewrite without any forced push.
2. Tell collaborators exactly what to do with their clones.
3. Explain what happens to a stale clone under `git pull --rebase` and under a plain pull.
4. Say what remains on GitHub after the forced push and what a Support request covers, as the section gives it.
5. Name the governance controls that limit how far a leaked credential reaches.

## CONCEPT

**Why this failure exists.** A rewrite produces a second history that shares only its oldest commits with the first. To Git, the old history and the new history are two lines of work that happen to have a common ancestor. Git has no concept of "the withdrawn version". If someone merges the two lines, that is a merge like any other.

**What happens.** A clone that still has the old history merges or rebases it back and pushes it as ordinary new commits. The merge commit has two parents: the clean tip, and a commit whose ancestors include the commit that added the secret. The push from the clean tip to that merge commit is a fast-forward. The server accepts it without force, and no branch rule that forbids force pushes objects.

**How a clone is recovered.** The filter-repo manual says the easiest way to clean other clones is to delete and re-clone them. Where that is impossible, it prescribes a sequence per clone.

**[ON SCREEN]** The per-clone sequence of section 21B.18.

```bash
git tag -l | xargs git tag -d        # tags are not updated by a normal fetch; delete, then refetch
git fetch --prune --tags
git rebase --onto origin/main <old-upstream-tip> <branch>     # replay only your own commits
git reflog expire --expire=now --all
git gc --prune=now
git cat-file -t <first-changed-commit>                        # must fail
```

Six lines, and each has a reason. Tags are not updated by an ordinary fetch, so they are deleted and fetched again. The rebase with `--onto` carries over only your own commits. The expiry and the prune remove the old objects from this clone. The last line is the verification: asking for the type of the first changed commit must fail.

The manual adds two warnings. Colleagues must not run the same filter command themselves, because identical commands can still produce different commit IDs. And the expiry step drops their reflogs and stash entries, so they save their work first.

GitHub's page lists "high risk of recontamination" first among the side effects of a rewrite and gives the rule: collaborators must rebase, not merge, branches created from the old history, because one merge commit can reintroduce some or all of it.

**Can the server refuse the old commits?** Few hosting services can ban a specific commit from being pushed again. The filter-repo manual says so, and the research notes of this course found no documented built-in control of that kind on GitHub. Push protection, when the secret matches a supported pattern, and a push ruleset that blocks the file path are the nearest platform equivalents. The local analogue is a `pre-receive` hook, which the lab installs and tests.

**The GitHub side.** This part is GitHub, not Git, and it is described from GitHub's page on removing sensitive data. Nothing here was run. After your force push, four copies remain that you cannot reach with Git.

**[ON SCREEN]** The table of section 21B.19.

| Where | Why it survives | Who can remove it |
|---|---|---|
| Unreachable commits in the repository | a force push moves refs; the objects stay, and are served by commit ID in cached views | GitHub Support, by running garbage collection and removing cached views |
| Pull request refs | `refs/pull/N/head` is read-only for you and keeps the old commits reachable | GitHub Support, by dereferencing or deleting the affected pull requests |
| Forks | each fork has its own refs to the old commits, and the fork network shares objects | each fork's owner; GitHub cannot provide their contact information |
| Clones | they are on other people's disks | their owners |

The Support request must contain the repository owner and name, the number of affected pull requests, and the first changed commit or commits from git-filter-repo's output. If the output contained the line about orphaned LFS objects, mention it and attach the named file. Support removes only sensitive data, and only in cases where it determines that rotating the affected credentials cannot mitigate the risk.

**[ON SCREEN]** Unverified.

GitHub publishes neither how long it retains unreachable commits without a Support-initiated garbage collection, nor a turnaround time for Support. Researchers who mined force-pushed commits observed that they appear to be kept indefinitely. That is their observation, not a GitHub statement. The same retention is what made the recovery of a force-pushed branch possible in Chapter 13: a force push does not delete.

**The controls.** Prevention fails sometimes, so you design for the day it does. Section 21B.20 lists the GitHub features that decide how much one leaked credential can do and whether you can reconstruct what it did.

| Control | What it limits |
|---|---|
| Fine-grained or App tokens with expiry, and organization approval of tokens | the reach and lifetime of a stolen token |
| Mandatory two-factor authentication and SSO authorization | account takeover by password |
| Rulesets on branches, tags and pushes; push rulesets can block file paths, extensions and sizes across the whole fork network | what a compromised contributor can change, and what can be pushed at all |
| Code-owner review of `.github/workflows/` and of the CODEOWNERS file itself | silent changes to automation |
| Audit log, 180 days at organization level, exported or streamed if Git events must be available later (the enterprise log retains them for seven days) | your ability to answer "what did the token do?" |
| The preview ruleset rule that blocks merging a pull request which introduces an open secret alert (9 September 2026; needs Secret Protection) | secrets entering the default branch through review |

These controls reduce blast radius. They do not prevent leaks. The textbook's observation across the case studies of V166 is sobering: the worst outcomes involved single credentials with estate-wide read access, and detection came from outsiders in nearly every case.

## MENTAL MODEL

Keep the analogy of V167: the recalled book. One reader who lends an old copy to the library puts the removed page back on the shelf. The librarian does not object, because a book was returned and that is what readers do.

In Git terms: the server checks whether a push is a fast-forward. It does not check where the new commits came from. A merge commit whose first parent is the current tip is a fast-forward by definition, whatever its second parent drags in.

Where the analogy breaks: the reader's copy is one object, and a stale clone is a graph. The clone can keep its own new work and drop the old pages, if the owner replays only their own commits onto the new history. That is the `--onto` rebase.

The second model is for the question "where can this data still be?" Count repositories, not commands. The server, with its unreachable objects. The pull request refs. Each fork. Each clone. Each of them has its own refs and its own objects, and each has a different owner.

## DIAGRAM

**[DIAGRAM]** Draw the shared commit `987a49d` on the left. From it, the old history on the upper line, ending in Asha's own commit. From it, the rewritten history on the lower line. Then join both lines in one merge commit and label it `main`.

```text
                 0805fd8--64b9b89--b509fe3--d4b8762--95f98b0
                /        (old history, with .env)            \
  ...--987a49d                                                f7ed5a9   main (on the server again)
                \                                            /
                 0ac4257--66a99cc--51e2d95--c8ce738---------
                         (rewritten history)
```

Ask: from `main`, is the commit that added `.env` reachable? Follow the upper parent of the merge. Yes. That is the whole incident in one picture.

**[ON SCREEN]** The root-cause box of section 21B.18, one line at a time.

```text
Observed behavior : the day after the cleanup, the scanner reports the same secret on main
Git state         : main is a merge commit with the rewritten tip and a commit from the old history as parents
Mechanism         : a pull in a stale clone merged old and new history; the push was a fast-forward
Root cause        : a clone that still held the old commits was allowed to push
Why Git does this : to Git the two histories are unrelated lines of work that someone chose to merge
Correct fix       : force-push the clean refs again; clean or replace the stale clone; replay only her own commit
Prevention        : freeze and re-clone; rebase onto the new history, never merge; a server-side check that
                    rejects the first changed commit or the secret pattern
```

## LIVE TERMINAL DEMO

**[TERMINAL]** We continue the replay of `labs/ch21b/rewrite-mechanics.sh` where V167 stopped. Asha cloned before the incident and has one local commit. She was not told to stop, or did not read the message.

**Step 1: an ordinary morning.** 🟡 CAUTION: `git pull` moves the current branch; here it creates a merge commit.

```bash
cd asha
git log --oneline -3
git pull --no-rebase 2>&1
git log --oneline --graph -6
git push 2>&1
```

Predict two things. What will the fetch part of the pull report about `origin/main`? And will the push need force?

<!-- snippet: ch21b/rewrite-mechanics/09-stale-clone -->
```text
$ cd asha
$ git log --oneline -3
95f98b0 Add contains metric
d4b8762 Document setup in README
b509fe3 Add request timeout
$ git pull --no-rebase 2>&1
From ../server
 + d4b8762...c8ce738 main              -> origin/main  (forced update)
 + 7fae871...ba9f0e0 feature/streaming -> origin/feature/streaming  (forced update)
Merge made by the 'ort' strategy.
$ git log --oneline --graph -6
*   f7ed5a9 Merge branch 'main' of ../server
|\  
| * c8ce738 Document setup in README
| * 51e2d95 Add request timeout
| * 66a99cc Add retry with backoff
| * 0ac4257 Add staging settings
* | 95f98b0 Add contains metric
$ git push 2>&1
To ../server.git
   c8ce738..f7ed5a9  main -> main
```
<!-- /snippet -->

Point at the two lines with a plus sign and the words "forced update". That was the warning, and it scrolled past. Then "Merge made by the 'ort' strategy". The graph shows the merge commit `f7ed5a9` with the clean tip `c8ce738` on one side and her commit `95f98b0` on the other. Then the last line: the push went from `c8ce738` to `f7ed5a9` with two dots, not three, and without a plus sign. A fast-forward.

**Step 2: the server.**

```bash
cd ..
git -C server.git log --oneline -3 main
git -C server.git grep -l DUMMY-KEY $(git -C server.git rev-list --all) | wc -l
git -C server.git log --oneline -S'DUMMY-KEY' main
```

<!-- snippet: ch21b/rewrite-mechanics/10-secret-is-back -->
```text
$ cd ..
$ git -C server.git log --oneline -3 main
f7ed5a9 Merge branch 'main' of ../server
95f98b0 Add contains metric
c8ce738 Document setup in README
$ git -C server.git grep -l DUMMY-KEY $(git -C server.git rev-list --all) | wc -l
       6
$ git -C server.git log --oneline -S'DUMMY-KEY' main
0805fd8 Add staging settings
```
<!-- /snippet -->

Six snapshots with the key are reachable from the server's refs again, and the pickaxe names the original commit, `0805fd8`, as part of `main`.

**Step 3: three ways a stale clone meets the new history.** Replay `labs/run ch21b/stale-clone-rebase`. It builds the same situation three times. First: `git pull --rebase` as the clone's first contact with the rewritten history.

```bash
cd asha
git log --oneline -2
git pull -q --rebase 2>&1
git log --oneline -3
git grep -l DUMMY-KEY $(git rev-list HEAD) | wc -l
```

<!-- snippet: ch21b/stale-clone-rebase/01-pull-rebase-first-contact -->
```text
$ cd asha
$ git log --oneline -2
95f98b0 Add contains metric
d4b8762 Document setup in README
$ git pull -q --rebase 2>&1
$ git log --oneline -3
30cf503 Add contains metric
c8ce738 Document setup in README
51e2d95 Add request timeout
$ git grep -l DUMMY-KEY $(git rev-list HEAD) | wc -l
       0
$ cd ..
```
<!-- /snippet -->

When run for the chapter, this replayed only the local commit, because the pull still knew the previous value of `origin/main`. Her commit is now `30cf503` on top of `c8ce738`, and the count is zero. That looks like the answer. It is not an instruction you can hand out, and the second variant shows why.

Second: the clone has already fetched, and then rebases onto `origin/main`. Predict: which commits will Git treat as hers?

```bash
cd asha2
git fetch -q 2>&1
git rebase origin/main 2>&1 | grep -E "^(CONFLICT|error|Could not)"
git status -sb | head -1
git rebase --abort
```

<!-- snippet: ch21b/stale-clone-rebase/02-fetch-then-rebase -->
```text
$ cd asha2
$ git fetch -q 2>&1
$ git rebase origin/main 2>&1 | grep -E "^(CONFLICT|error|Could not)"
CONFLICT (add/add): Merge conflict in settings.yaml
error: could not apply 0805fd8... Add staging settings
Could not apply 0805fd8... # Add staging settings
$ git status -sb | head -1
## HEAD (no branch)
$ git rebase --abort
$ cd ..
```
<!-- /snippet -->

**[PAUSE]** Read the error: "could not apply 0805fd8... Add staging settings". Git tried to replay the commit that added the secret. After a plain fetch, the knowledge of the previous `origin/main` is no longer used, so `git rebase origin/main` treats every old commit that is missing from the new history as hers. The rebase stops in a conflict with a detached HEAD, and `git rebase --abort` returns to the start.

Third: the explicit form.

```bash
cd asha3
git fetch -q 2>&1
old=$(git reflog show main --format=%h | tail -1); echo $old
git rebase -q --onto origin/main $old 2>&1
git log --oneline -3
git grep -l DUMMY-KEY $(git rev-list HEAD) | wc -l
```

<!-- snippet: ch21b/stale-clone-rebase/03-onto-old-base -->
```text
$ cd asha3
$ git fetch -q 2>&1
$ old=$(git reflog show main --format=%h | tail -1); echo $old
d4b8762
$ git rebase -q --onto origin/main $old 2>&1
$ git log --oneline -3
62cd8e1 Add contains metric
c8ce738 Document setup in README
51e2d95 Add request timeout
$ git grep -l DUMMY-KEY $(git rev-list HEAD) | wc -l
       0
```
<!-- /snippet -->

The old upstream tip is read from the reflog of `main`: its oldest entry, `d4b8762`, the commit she cloned. `--onto origin/main` with that old base replays only what came after it. One commit, on the clean history. This is the form to send to colleagues, because it works whatever the clone did before.

**Step 4: the tabletop, from eradication to the end.** Replay `labs/run ch21b/lab-31-1-tabletop`. The first three snippets, confirm, contain and assess, belong to V166. We start at the fourth. First the tip is cleaned with an ordinary commit.

```bash
git rm -q --cached .env
printf '.env\n' > .gitignore
printf 'LLM_API_KEY=\nLLM_BASE_URL=https://llm.example.com\n' > .env.example
git add .gitignore .env.example && git commit -q -m 'Stop tracking .env; add .env.example'
git push -q origin main
git grep -c DUMMY-KEY origin/main || echo "tip is clean"
git grep -c DUMMY-KEY v0.2.0
```

<!-- snippet: ch21b/lab-31-1-tabletop/04-eradicate-tip -->
```text
$ git rm -q --cached .env
$ printf '.env\n' > .gitignore
$ printf 'LLM_API_KEY=\nLLM_BASE_URL=https://llm.example.com\n' > .env.example
$ git add .gitignore .env.example && git commit -q -m 'Stop tracking .env; add .env.example'
$ git push -q origin main
$ git grep -c DUMMY-KEY origin/main || echo "tip is clean"
tip is clean
$ git grep -c DUMMY-KEY v0.2.0
v0.2.0:.env:1
```
<!-- /snippet -->

The tip is clean and the tag still has the key. In the tabletop, the decision to rewrite has been taken and recorded. The rewrite, its verification and the forced push are the mechanics of V167; step through snippets `05-rewrite`, `06-verify-rewrite` and `07-force-push` on screen without stopping, and stop at the server.

<!-- snippet: ch21b/lab-31-1-tabletop/08-server-prune -->
```text
# The force push moved the refs. The old commits are still in the server repository:
$ git -C ../server.git show $first:.env
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
LLM_BASE_URL=https://llm.example.com
# On your own server you can prune. On GitHub only GitHub Support can (section 21B.19).
$ git -C ../server.git gc -q --prune=now
$ git -C ../server.git cat-file -t $first
fatal: Not a valid object name 0805fd8
[exit status: 128]
```
<!-- /snippet -->

On your own server you can prune, and after the prune the object is gone. On GitHub only GitHub Support can.

**Step 5: prevention, and its test.** The lab installs a `pre-receive` hook on the server and tests it with Ravi's clone, which still has the old history.

<!-- snippet: ch21b/lab-31-1-tabletop/10-prevent -->
```text
$ cp kit/pre-receive server.git/hooks/pre-receive
$ cp kit/pre-commit ragdesk/.git/hooks/pre-commit
# Test the server guard with a clone that still has the old history: Ravi pulls and pushes.
$ cd ravi
$ git pull -q --no-rebase 2>&1
$ git log --oneline --graph -4
*   b412d8e Merge branch 'main' of ../server
|\  
| * 0177e32 Stop tracking .env; add .env.example
| * c8ce738 Document setup in README
| * 51e2d95 Add request timeout
$ git push 2>&1
remote: push declined: refs/heads/main: commit b412d8e contains a secret pattern        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

Ravi does exactly what Asha did: pull, merge, push. Point at the remote's answer: "push declined", the commit named, and "pre-receive hook declined". The same morning routine, and this time the server refuses.

**Step 6: the failure scenario and the recovery.** The lab then removes the guard, to show the state of a team that stopped before prevention, and Asha pushes the secret back. Show snippet `12-failure` briefly; it is the incident of step 1 again. The recovery has two halves. The server: the cleanup clone force-pushes the clean refs again, the guard goes back, the server is pruned. Then the clone.

```bash
cd asha
git fetch -q 2>&1
git reflog show origin/main
git reflog show main -3
old=$(git reflog show main --format=%h | tail -1); echo $old
git reset -q --hard 'main@{1}'
git rebase -q --onto origin/main $old 2>&1
git log --oneline -3
```

🔴 DANGEROUS: `git reset --hard`. It discards uncommitted changes in the working tree and the index. Preview with `git status`; the commits it leaves behind stay in the reflog. Here it is appropriate because the reflog has shown exactly which entry is her own commit before the merge.

<!-- snippet: ch21b/lab-31-1-tabletop/14-recovery-clone -->
```text
$ cd asha
$ git fetch -q 2>&1
$ git reflog show origin/main
0177e32 refs/remotes/origin/main@{0}: fetch -q: forced-update
9d6c12c refs/remotes/origin/main@{1}: update by push
0177e32 refs/remotes/origin/main@{2}: pull -q --no-rebase: forced-update
$ git reflog show main -3
9d6c12c main@{0}: pull -q --no-rebase: Merge made by the 'ort' strategy.
95f98b0 main@{1}: commit: Add contains metric
d4b8762 main@{2}: clone: from $LAB/ch21b/lab-31-1-tabletop/server.git
$ old=$(git reflog show main --format=%h | tail -1); echo $old
d4b8762
# Undo the merge, then replay only her own commit onto the clean history.
$ git reset -q --hard 'main@{1}'
$ git rebase -q --onto origin/main $old 2>&1
$ git log --oneline -3
01e4fd0 Add contains metric
0177e32 Stop tracking .env; add .env.example
c8ce738 Document setup in README
```
<!-- /snippet -->

Read the reflog of `main` from the bottom: clone, her commit, the merge. `main@{1}` is her commit before the merge. Reset to it, then replay only that commit onto the clean history with `--onto`. The result is one new commit, `01e4fd0`, on top of the clean tip.

**Step 7: verification.**

<!-- snippet: ch21b/lab-31-1-tabletop/16-verification -->
```text
$ ./provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
REVOKED  DUMMY-KEY-not-a-real-secret-12345
$ git -C server.git log --oneline main
01e4fd0 Add contains metric
0177e32 Stop tracking .env; add .env.example
c8ce738 Document setup in README
51e2d95 Add request timeout
66a99cc Add retry with backoff
0ac4257 Add staging settings
987a49d Add evaluation harness
6388058 Add LLM client
0c55276 Add answer prompt template
dfd59fd Add BM25 retriever
$ git -C server.git grep -l DUMMY-KEY $(git -C server.git rev-list --all) | wc -l
       0
$ git -C server.git fsck --no-progress --unreachable | wc -l
       0
$ for c in ragdesk asha ravi; do printf "%s: " $c; git -C $c cat-file -t $first 2>&1; done
ragdesk: fatal: Not a valid object name 0805fd8
asha: fatal: Not a valid object name 0805fd8
ravi: fatal: Not a valid object name 0805fd8
$ cat refs-after.txt | cut -c1-7,41-
ba9f0e0 refs/heads/feature/streaming
0177e32 refs/heads/main
b4a2514 refs/tags/v0.1.0
17124a2 refs/tags/v0.2.0
```
<!-- /snippet -->

Five checks, in the order that matters. The provider says the key is revoked. The server's `main` is the clean history plus her commit. The scan over all refs prints zero. `git fsck --unreachable` on the server prints nothing. And in each of the three clones, asking for the first changed commit fails.

## COMMON MISTAKES

1. **Telling colleagues to "pull".** Root cause: a pull in a stale clone merges old and new history, and the resulting push is a fast-forward that no force-push rule sees.
2. **Telling colleagues to run `git rebase origin/main`.** Root cause: in a clone that has already fetched, every old commit missing from the new history counts as local work, the commit that added the secret included.
3. **Forgetting the tags in the clones.** Root cause: tags are not updated by an ordinary fetch, so a clone keeps the old tag and with it the old history until tags are deleted and refetched.
4. **Having each colleague run the same filter command.** Root cause: identical commands can still produce different commit IDs, so the clones would no longer share a history with the server.
5. **Treating the force push as the end on GitHub.** Root cause: pull request refs, cached views, forks and unreachable objects are outside the reach of your Git commands and have other owners.

## PRODUCTION EXAMPLE

Picture this: an LLM application team rewrote the history of its retrieval service to remove a customer export. The rewrite was verified and pushed on a Friday evening. On Monday the file was back. The lead did not ask who had force-pushed, because the branch rule would have blocked it. She ran `git log --merges -1` on `main` and looked at the parents of the newest merge commit: one was the rewritten tip, the other descended from the old history. The author of the merge had been on leave during the freeze.

The fix followed the root-cause box. The clean refs were force-pushed again from the cleanup clone, which had been kept for exactly this case. The colleague's clone was repaired with the `--onto` form, so that only his two commits were replayed. And two controls were added: a push ruleset that blocks the file path, and a line in the freeze announcement that names the per-clone sequence instead of the word "pull". The Support request for the pull request refs and the cached views, which had been filed on Friday with the count of affected pull requests and the first changed commit, was not affected.

## PRACTICE EXERCISE

Do Lab 31.1 complete, as a tabletop with its dummy secret: [`lab-manual/m31-secret-leak-response.md`](../../lab-manual/m31-secret-leak-response.md). The textbook asks you to do it twice, the second time from the symptom alone.

Before the step in which Ravi pulls and pushes against the guarded server, predict: what kind of commit will his pull create, will his push be a fast-forward, and which program will refuse it? Before the recovery of Asha's clone, write down which reflog entry you will reset to and which commit you will pass as the old base, and why.

The challenge is Incident 3, [`incidents/03-committed-secret`](../../incidents/03-committed-secret/SYMPTOMS.md). Generate it and attempt it from the symptoms. Do not read its generator.

## INTERVIEW QUESTION

**[ON SCREEN]** Q335: "A day after a history rewrite the secret is back on `main` and nobody force-pushed. Reconstruct what happened from the commit graph, and describe the fix for the server and for the clone."

Answer aloud first. A strong answer starts from evidence: which command shows the newest merge on `main` and what you read from its two parents. It then explains why the push needed no force, in terms of fast-forward. It gives two fixes and keeps them apart: one for the server's refs and one for the clone, and for the clone it says how only the person's own commits are carried over and why the simpler-looking rebase is wrong. It ends with prevention at three levels: the people, the clones and the server. Mention what Git cannot do here, and what on GitHub comes nearest.

## RECAP

- After a rewrite, every clone that still has the old history can return it with an ordinary pull and push, because the merge is a fast-forward for the server.
- The safe instruction is: re-clone; or delete and refetch tags, rebase with `--onto` from the old upstream tip, then expire and prune, and verify that the first changed commit is gone.
- `git pull --rebase` works only as the first contact; after a fetch, a plain rebase onto `origin/main` tries to replay the old history.
- On GitHub, unreachable commits, pull request refs, forks and clones survive the force push; Support can act on the first two, and only where rotation cannot mitigate the risk.
- Governance controls do not prevent leaks; they limit what a leaked credential reaches and let you answer what it did.

## HOMEWORK

Read sections 21B.18 to 21B.23 and do the Practice section, 21B.25. Then do Exercise 31.6, Level 3, "The secret came back", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md). The next video is the briefing for Gate 8.
