# V184: Choosing the lowest-risk fix, verification, and the symptom catalog

- **Part.** 9, Production debugging and incident response
- **Module.** 35
- **Planned minutes.** 18
- **Prerequisites.** V051, V183
- **Textbook sections.** [Chapter 29](../../textbook/ch29-production-troubleshooting.md), sections 29.9 to 29.14
- **Demo scripts.** `labs/ch29/lab-35-3-preserve-then-fix.sh` (snippets `04-fix`, `05-verify`, `06-failure`, `07-recovery`, `08-verification`)

## HOOK

**[ON SCREEN]** "It works on my machine now. Is the incident closed?"

An engineer repaired a release branch in her clone, her own copy of the repository, at eleven at night. A release branch is the line of commits a release is cut from and fixed on. `git status` is clean, the tests pass locally, and she wants to go to bed. Four questions decide whether she may. Did the thing the user wanted happen? Did the state that caused the problem change, for the reason she expected? Is the fix on the server, and in the pull request, GitHub's proposal to merge the branch, and in the pipeline run for that exact commit? And did anything change that shouldn't have?

A fix in your clone isn't a fix on the server. The first check can pass while the third one fails. Hold on to that sentence. Tonight it comes true for her.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video closes Module 35 and the diagnosis method. You have the read-only phase from video 180 and video 181, the reading of interrupted operations from video 182, and the preserve phase from video 183. What remains is the third phase: select the lowest-risk fix, execute, verify, prevent. From video 51 you have one table and one decision tree for undoing things. Today's ladder is the same idea, generalized to any fix.

Then the symptom catalog: twenty-six symptoms, each with its likely causes in the order worth testing and the commands that separate them. You don't memorize it. You learn how to use it and what pattern runs through it.

The terminal segment finishes the handover of video 183: the half-done backport, with every layer of evidence already in place. A backport copies a fix to a release line, here with `git cherry-pick`, which applies one commit's change to the current branch as a new commit.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Rank candidate fixes by what each can destroy and whom it affects.
2. State the four checks that make up a verification.
3. Give an example where the first check passes and a later one fails.
4. Use the symptom catalog to go from an error message to candidate causes.
5. Turn a finished case into a line of the team's checklist.

## CONCEPT

**Choosing a fix, in one sentence.** List every fix that would repair the root cause, rank them by what each can destroy and how each is undone, and take the one that only adds.

**Precisely.** Rank by five questions, in this order.

1. Does it destroy uncommitted work? That work has no object and no reflog. Anything that can remove it, `git reset --hard`, `git restore`, `git clean`, `git stash drop`, every `--abort`, ranks last unless the working tree is clean or copied.
2. Does it rewrite commits that another repository has? Rewriting published history turns one person's problem into every clone's problem.
3. Does it change the server? A local change is undone locally. A push, a deleted remote branch or a changed rule is seen by others and may start workflows.
4. Is it undone by one command? A new commit is undone by a revert; a moved ref by moving it back; a pruned object by nothing.
5. Can it be previewed? `--dry-run`, `git merge-tree`, `git diff <target>`, `git log <range>`, or a rehearsal in a copy.

The result is a ladder of six rungs, which is today's diagram. Prefer the lowest rung that repairs the cause. In the case of video 180 that was rungs 1 and 2. In the case of video 181 it was rung 3, on commits that existed nowhere else, with rung 1 first.

**Three rules of thumb.**

On a shared branch, undo with `git revert`, not with `git reset`, which moves the branch to another commit. A revert adds a commit. Everyone's next pull is a fast-forward, a plain move ahead.

When a ref must move back, use `git reset --keep`. It refuses when a file with local changes would be overwritten, where `--hard` overwrites it.

When a force push, which overwrites the server's branch, is the correct fix, state the expected old value: `git push --force-with-lease=<branch>:<expected-id>`. The bare form is defeated by anything that fetches in the background.

**Verification, in one sentence.** A fix is verified when the commands that showed the problem now show its absence, for the reason you predicted, in every place the problem existed.

**Four checks, in this order.**

1. The symptom. Repeat the command or page that showed it: the rejected push succeeds; the pull request lists the expected commits.
2. The state. Repeat the diagnosis commands that exposed the cause. The first line of `git status` changed; the brackets in `git branch -vv` changed; `.git` has no state files.
3. Every copy. Compare IDs, not names: `git rev-parse HEAD @{upstream}` and `git ls-remote origin <branch>` must print the same ID. Then the colleague's clone, the pull request, the pipeline run for that exact commit.
4. Nothing else changed. `git diff <backup> HEAD` or `git range-diff` shows that the result differs from the preserved state only where intended. `git fsck` reports no damage. `git status` shows no leftovers.

Try it now. Thirty seconds, and it only reads. In the lab shell, or in any repository you have, run `git rev-parse HEAD @{upstream}`. The upstream is the server branch your branch follows. Do you get two equal IDs? Say what you see.

**[PAUSE]**

Two equal IDs mean your branch agrees with your record of its upstream. That record is the server at your last fetch, so only `git ls-remote` tells you what the server holds now. And if Git answered that no upstream is configured, that's a finding too.

Write the prediction before you run the check. Then, and only then, remove what the investigation added: the rescue branch, the evidence directory, the bundle. `git branch -D` prints the ID, which is one more safety line.

**What a pull request needs after a fix** is platform behavior: a push to the head branch reruns workflows and can dismiss approvals. A forced push marks review comments as outdated. Verification includes reading the pull request page again.

**The symptom catalog.** Twenty-six symptoms in five groups. History and refs. Working tree and index. Remotes, access and identity. Pull requests, checks and CI. And submodules, LFS and scale. Each row gives the likely causes in the order worth testing, the commands that distinguish them, and the chapter with the mechanism.

**[ON SCREEN]** Three rows of section 29.11, as examples of the form.

| # | Symptom | Likely causes | Commands that distinguish them |
|---|---|---|---|
| 1 | A commit is missing | (a) it is on another branch; (b) it was made on a detached HEAD or inside a stopped operation; (c) a reset, rebase or amend took it off the branch; (d) it was never pushed, or pushed to another branch; (e) it was never made: the change was not staged | `git branch -a --contains <id>`; `git status` (first line); `git reflog`, `git reflog show <branch>`; `git ls-remote origin`; `git log --all --oneline -- <path>` |
| 15 | A push is rejected | (a) `! [rejected] (fetch first)` or `(non-fast-forward)`: the server's branch has commits you lack; (b) the pull integrates another branch than the push targets; (c) `! [remote rejected]`: a rule, a hook, push protection or a file-size limit, named in the `remote:` lines; (d) no permission | Read the bracket and the reason in the push output; `git fetch`, `git status -sb`; `git branch -vv`; `gh ruleset check <branch>` |
| 22 | A pull request shows hundreds of changes | (a) the wrong base branch; (b) the head branch was reused after a squash merge; (c) the branch was rebased or force-pushed; (d) every line changed: line endings or a formatter; (e) a lock file or generated file | `git log --oneline <base>..<head>`; `git diff --stat <base>...<head>`; `git merge-base <base> <head>`; `git diff --ignore-cr-at-eol --stat <base>...<head>` |

How to use a row: the causes are your ready-made hypotheses, already more than three, and each command is the test that separates them. The catalog doesn't replace the opening ritual. It replaces the blank page after it.

**The pattern across the catalog.** The textbook calls it the content of the book in one line: nearly every symptom is a difference between two of the places of the state table that someone assumed were equal. The working tree and the commit. The branch and HEAD. The local branch and its upstream. The remote-tracking branch and the server. The branch and the merge ref. The diagnosis is finding which two.

**When not to use the full method.** A message that names its own remedy, and whose remedy is green, needs no hypothesis table: "The current branch has no upstream branch", with the command printed beneath it, or a typo in a branch name. Run `git status`, do what the message says, and move on. The full method is for symptoms that contradict what the reporter believes about the state. The opening ritual is never skipped: it takes less than a minute.

**When to stop and escalate.** If the evidence shows a credential in history, stop diagnosing and start the secret response: revoke first, investigate second. If the repository reports corrupt or missing objects, don't continue working in it: copy it and follow the procedure of Chapter 13. If production is down, restore service first and diagnose afterwards on preserved evidence.

**How the method itself fails.**

| What goes wrong | How to recognise it | Prevention |
|---|---|---|
| A "fix" is typed before the state is known | The reflog shows `reset`, `checkout` or `rebase (abort)` entries made after the report | Nothing but green commands until the root cause is written down |
| The diagnosis uses stale remote-tracking refs | `git status` says "up to date" and `git ls-remote origin` shows another ID | Treat `origin/<branch>` as "the server at the last fetch" |
| The wrong layer is blamed | "GitHub lost my commits" while `git ls-remote` shows the server never had them | The label "Git, GitHub or Actions" is a required line of every explanation |
| The evidence is destroyed by the investigation | The reflog was expired, a branch was deleted "to tidy up", `git gc` was run | Preserve before phase 3; never run `git gc` or `git prune` during an incident |

## MENTAL MODEL

A picture helps. The ladder is a physical picture, and it works as one. You climb only as high as the repair requires, and each rung up is further to fall. On the first rung nothing can be lost. On the sixth, nothing can be undone.

Where the picture breaks: on a real ladder the rungs are equally spaced. Here the gap between rung 3 and rung 4 is much larger than the others, because it's the gap between "undone through the reflog" and "unrecoverable". The reflog is Git's local record of where each ref has been. And the gap between 4 and 5 is of a different kind: from your own loss to other people's.

For verification, think of a doctor who ends a treatment. The patient says the pain is gone: the symptom. The test that showed the cause is repeated: the state. Both lungs are checked, not one: every copy. And nothing else was harmed by the treatment: nothing else changed. A doctor who stops at the first check has asked the patient, not examined them.

## DIAGRAM

**[DIAGRAM]** The ladder of section 29.9. Build it from the bottom rung, number 1, upward, and say the right-hand column aloud for each rung.

```text
  1  add a ref                 git branch, git tag, git update-ref               nothing can be lost
  2  add a commit              git commit, git revert, git cherry-pick, merge    undone by a revert or by moving the ref back
  3  move a local ref          git reset --keep, git branch -f, git rebase       undone through the reflog or a backup ref
  4  overwrite the work tree   git reset --hard, git restore, git clean          uncommitted work is unrecoverable
  5  rewrite the server        git push --force-with-lease=<ref>:<expected>      others must repair their clones
  6  remove the safety net     git reflog expire, git gc --prune=now             nothing undoes it
```

Then place the interview question's five fixes on it as a preview: each has a rung. I won't say which. That's the question.

## LIVE TERMINAL DEMO

**[TERMINAL]** We continue `labs/run ch29/lab-35-3-preserve-then-fix` where V183 stopped. The situation: a cherry-pick of two commits onto `release/1.4` stopped at a conflict in `guard.yaml`. A colleague resolved the file by hand and left a note: on this line the threshold stays 0.50, and the limit becomes 128. The record, a rescue branch, a copy, a rehearsal copy and a bundle exist.

**Choosing.** Put the candidates on the ladder before running anything. Continue the cherry-pick with the colleague's resolution: rung 2, it adds commits. Abort and start again: an abort discards the uncommitted resolution, which exists in no object. The note says the operation was intended and gives the intended result, so the resolution can be checked against it. Continue is the lowest rung that repairs the cause.

**The fix.** 🟡 CAUTION: `git cherry-pick --continue` adds commits to the current branch. Preview: read the resolved file against the note first.

```bash
cat guard.yaml
git add guard.yaml
git -c core.editor=true cherry-pick --continue
```

<!-- snippet: ch29/lab-35-3-preserve-then-fix/04-fix -->
```text
$ cat guard.yaml
threshold: 0.50
max_tokens: 128
$ git add guard.yaml
$ git -c core.editor=true cherry-pick --continue
[release/1.4 99a0531] Lower max_tokens to 128
 Date: Mon Sep 7 10:07:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
[release/1.4 78b0e20] Block the word secret
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

The file says 0.50 and 128, as the note requires. Staging it marks the conflict resolved. The sequencer, Git's record of the picks that remain, then commits the stopped pick and applies the remaining one: two new commits.

**Verify.** Predict before the output: in `git cherry -v release/1.4 main`, which commits of `main` will carry a minus sign and which a plus sign, and why? Say it out loud.

**[PAUSE]**

```bash
git status
git log --oneline -4
git show HEAD~1:guard.yaml
git cherry -v release/1.4 main
ls .git | grep -c -E "CHERRY_PICK_HEAD|sequencer"
```

<!-- snippet: ch29/lab-35-3-preserve-then-fix/05-verify -->
```text
$ git status
On branch release/1.4
nothing to commit, working tree clean
$ git log --oneline -4
78b0e20 Block the word secret
99a0531 Lower max_tokens to 128
5c011a9 Add blocklist
329817a Allow 512 tokens on the 1.4 line
$ git show HEAD~1:guard.yaml
threshold: 0.50
max_tokens: 128
$ git cherry -v release/1.4 main
+ 73ef78885a54252a1af4b097f3d5f4d73b1f5c2e Raise guard threshold to 0.65
- b24fd6204b321b7b34d07ecd0e969bb3c610c30c Add blocklist
+ e0631de25fbc27decbe5c84018d24bdf95f12aa2 Lower max_tokens to 128
- f9e40d623e77c7f311cf07e75d14016adff35ae5 Block the word secret
$ ls .git | grep -c -E "CHERRY_PICK_HEAD|sequencer"
0
```
<!-- /snippet -->

Go through the checks. State: "On branch", clean, and zero state files. The intended result: the committed file has the two values from the note. Then `git cherry`: two commits of `main` are marked with a minus sign, present on the release branch in equivalent form. Two are marked with a plus sign. One of them was deliberately not backported. The other, `e0631de`, was backported, and is marked as missing. Why? Say your explanation out loud.

**[PAUSE]**

This is the limit of the patch-ID check that you met in video 172. It compares commits by their change, not by their ID, and the port needed a conflict resolution, so its diff differs from the original. A check that passes or fails has to be read with its limits. Here the evidence that the port happened is the commit itself and the handover note.

**The failure scenario, in the rehearsal copy.** What would the other choice have done? 🟡 CAUTION: `git cherry-pick --abort` resets the index and the working tree to the starting commit.

```bash
cd ../rehearsal
git status | head -2
git cherry-pick --abort
git status
git log --oneline -2
cat guard.yaml
```

Quick quiz. After the abort, where is the branch? A, on the first pick, the one that had succeeded. B, back before the whole backport. And what does `guard.yaml` contain? Your answer?

**[PAUSE]**

<!-- snippet: ch29/lab-35-3-preserve-then-fix/06-failure -->
```text
$ cd ../rehearsal
$ git status | head -2
On branch release/1.4
You are currently cherry-picking commit e0631de.
$ git cherry-pick --abort
$ git status
On branch release/1.4
nothing to commit, working tree clean
$ git log --oneline -2
329817a Allow 512 tokens on the 1.4 line
b039fd7 Add output guard
$ cat guard.yaml
threshold: 0.50
max_tokens: 512
```
<!-- /snippet -->

B. Clean, quiet, and wrong. The branch is back at `329817a`, before the whole backport, so even the pick that had already succeeded has left the branch. And the file says 512: the colleague's resolution is gone. It was never in an object, so no reflog has it.

**The recovery, from what was preserved.**

```bash
git merge --ff-only rescue/backport-partial
git cherry-pick -x main~1 main
cp ../evidence/guardrail-copy/guard.yaml guard.yaml
git add guard.yaml
git -c core.editor=true cherry-pick --continue
```

<!-- snippet: ch29/lab-35-3-preserve-then-fix/07-recovery -->
```text
$ git merge --ff-only rescue/backport-partial
Updating 329817a..5c011a9
Fast-forward
 blocklist.py | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 blocklist.py
$ git cherry-pick -x main~1 main
Auto-merging guard.yaml
CONFLICT (content): Merge conflict in guard.yaml
error: could not apply e0631de... Lower max_tokens to 128
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
[exit status: 1]
$ cp ../evidence/guardrail-copy/guard.yaml guard.yaml
$ git add guard.yaml
$ git -c core.editor=true cherry-pick --continue
[release/1.4 dc02c3b] Lower max_tokens to 128
 Date: Mon Sep 7 10:07:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
[release/1.4 f46f218] Block the word secret
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

The rescue branch brings back the completed pick with a fast-forward. The cherry-pick is started again and stops at the same conflict. The resolved file comes from the copy of the repository, the one layer that holds uncommitted files. Then continue.

**Verification of the recovery.**

<!-- snippet: ch29/lab-35-3-preserve-then-fix/08-verification -->
```text
$ git log --oneline -4
f46f218 Block the word secret
dc02c3b Lower max_tokens to 128
5c011a9 Add blocklist
329817a Allow 512 tokens on the 1.4 line
$ git rev-parse 'HEAD^{tree}'
940671b2b37f12fe7f0b2599c35bb6c88e7f9443
$ git -C ../guardrail rev-parse 'HEAD^{tree}'
940671b2b37f12fe7f0b2599c35bb6c88e7f9443
$ git status -sb
## release/1.4
```
<!-- /snippet -->

The commit IDs differ from the first repair. The tree IDs, which name the complete snapshots, are equal: both repositories end with the same content. That's the fourth check done precisely: nothing else changed.

Say the lesson of the scenario in one sentence: the same mistake was made in the rehearsal that a tired engineer makes at night, and it cost nothing, because two layers of preservation each returned the part they hold.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Choosing the fix you know instead of the lowest rung.** Root cause: the candidates were never listed and ranked by what each can destroy.
2. **Using `git reset --hard` where `--keep` would do.** Root cause: `--hard` overwrites files with local changes, and uncommitted work has no object and no reflog.
3. **Stopping at "the symptom is gone".** Root cause: a fix in one clone is not a fix on the server, in the pull request or in the pipeline, so the first check can pass while a later one fails.
4. **Comparing names instead of IDs.** Root cause: `origin/<branch>` is the server at the last fetch; only an ID from `git ls-remote` says what the server holds now.
5. **Reading a verification command without its limits.** Root cause: a patch-ID comparison reports a port that needed conflict resolution as missing, so the mark alone can mislead.

## PRODUCTION EXAMPLE

Now, out of the lab. The engineer from the hook does the four checks before she goes to bed. The symptom: the backported release branch builds. The state: no cherry-pick in progress, clean status. Every copy: `git rev-parse HEAD @{upstream}` prints two equal IDs, and `git ls-remote origin` prints a different one for the branch. She hadn't pushed. Check three failed, at eleven at night, with check one green. There's the sentence from the opening, come true.

She previews the push, pushes, compares the three IDs again, and opens the pull request for the release: the push has rerun the workflows, and one approval was dismissed, which she notes for the morning. The fourth check: `git range-diff` against her rescue branch shows only the intended commits.

The next day the case becomes one line in the team's checklist, written as a check and not as advice: "A fix is closed when `git ls-remote origin <branch>` prints the ID you verified locally, and the pipeline run for that ID is green."

## PRACTICE EXERCISE

Your turn. Finish Lab 35.3, "Preserve evidence, then fix", in [`lab-manual/m35-diagnosis-method.md`](../../lab-manual/m35-diagnosis-method.md): the fix, the verification, the failure scenario in the rehearsal copy, and the recovery.

Before the fix, list the candidate fixes and give each its rung. Before each verification command, write the output you predict and the reason. In the failure scenario, predict what the abort will discard and from which layer each part can be returned. The lab's questions are answered in a separate file. Attempt them first.

The challenge has no file: take three entries of the symptom catalog in section 29.11 at random and say, without the book, the first three read-only commands for each. Then check.

## INTERVIEW QUESTION

**[ON SCREEN]** Q413: "Rank these fixes by risk and justify the order: `git revert`, `git reset --hard` followed by a force push, `git reset --keep`, `git cherry-pick`, a new branch."

**[PAUSE]**

Answer out loud. The justification is what is scored. A strong answer doesn't rank by feeling. It applies stated criteria to each fix: what can it destroy, whom does it affect, how is it undone, can it be previewed. It places each of the five on the ladder and explains ties and near-ties, because two of them sit on the same rung. It names the one that combines two rungs and says which of its two halves does which damage. And it adds the condition that changes the ranking: whether the working tree is clean, and whether the commits are published.

## RECAP

Let's land this.

- Candidate fixes are ranked by what they can destroy: uncommitted work, published history, the server, undoability, previewability.
- The ladder runs from adding a ref to removing the safety net; take the lowest rung that repairs the cause.
- On shared branches revert; move refs back with `--keep`; force only with an explicit expected value.
- Verification is four checks: the symptom, the state, every copy, nothing else changed, each with a prediction written first.
- Nearly every symptom in the catalog is a difference between two places that someone assumed were equal.

## HOMEWORK

Read sections 29.9 to 29.14 and do the Practice section, 29.16, including its drill on the rescue branch of case 1. Keep the [troubleshooting playbook](../../playbooks/troubleshooting-playbook.md) within reach: the next ten videos are incidents, and each one starts with you, a generated repository and a symptom, before any debrief.

You now have the whole method: read, preserve, choose the lowest rung, and verify in every place the problem existed. Practise it on the lab before the incidents begin. Next time: what an incident is, the loop that handles one, severity, and how to run the ten incidents. Until then, look at the state first and type second. See you in the next one.
