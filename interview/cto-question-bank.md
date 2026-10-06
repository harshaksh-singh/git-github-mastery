# CTO question bank

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Every question is answerable from the textbook, chapters 1 to 30.

This file holds questions only. The model answers are in a separate file, [cto-question-bank-answers.md](cto-question-bank-answers.md), with the same numbers. Do not open it before you have answered aloud.

## How to use this bank

- **One question at a time, spoken.** Answer aloud, in two minutes or less, without notes and without a terminal. Then answer the follow-up. Only then read the model answer. The procedure and the grading scale are in the [interview-mode protocol](interview-mode-protocol.md).
- **A strong answer has five parts**: the state, the mechanism, the evidence, the fix, the prevention. The [senior-engineer interview guide](senior-engineer-interview-guide.md) explains the structure and works twenty answers at three quality levels.
- **Every question has a harder follow-up.** The follow-up is what a CTO asks when the first answer was correct. If the first answer was weak, the interviewer explains the gap before asking it.
- **The bank is grouped by the eighteen areas of the final test.** Inside each area the questions run from foundational to principal level. The four levels mean: *Foundational*, define the thing and its mechanism; *Working engineer*, apply it and diagnose a common failure; *Senior*, edge cases, trade-offs, an incident; *Principal*, design, governance, organization-wide prevention, a safety net that fails.
- **Every question from the "Interview questions" section of every textbook chapter is here**, with a few edited so that they stand alone when read aloud. The rest were written for this bank.
- **Layer discipline.** When a question says "Git", it means the tool. When it says "GitHub", it means the platform. When it says "Actions", it means GitHub Actions. A correct answer names the layer that acted.

## Areas

| Area | Questions | Count | Scope |
|---|---|---|---|
| 1. Fundamentals | Q1 to Q64 | 64 | The data model as you meet it every day: the three trees, the index, commits, configuration, ignore rules and attributes. |
| 2. Git internals | Q65 to Q90 | 26 | The object database, references, packfiles, reachability and maintenance. |
| 3. Branching | Q91 to Q121 | 31 | Branches and tags as refs, HEAD, upstream configuration, worktrees. |
| 4. Merge | Q122 to Q141 | 20 | Merge bases, the three-way rule, conflicts and their stages, strategies, rerere, auditing a merge. |
| 5. Rebase | Q142 to Q167 | 26 | Rebase in all its forms, and cherry-pick: replayed commits, rewritten history, and when not to rewrite. |
| 6. Undo | Q168 to Q184 | 17 | Reset, revert, restore and stash: choosing the undo that destroys least. |
| 7. Recovery | Q185 to Q200 | 16 | The reflog, unreachable objects, `git fsck`, and the limits of every safety net. |
| 8. Remote workflows | Q201 to Q218 | 18 | Fetch, pull, push, refspecs, remote-tracking branches, and forced updates. |
| 9. GitHub | Q219 to Q261 | 43 | The platform: repositories, forks, authentication, rulesets and branch protection, CODEOWNERS. |
| 10. Pull requests | Q262 to Q278 | 17 | What a pull request is, what it displays, reviews, the three merge methods, and their effect on history. |
| 11. GitHub Actions | Q279 to Q305 | 27 | Workflows, events, runners, caching, artifacts, delivery and the debugging of failed runs. |
| 12. Security | Q306 to Q338 | 33 | GitHub Actions security, repository security, signing, and the response to a leaked secret. |
| 13. Open source | Q339 to Q353 | 15 | Forks, upstream remotes, contribution etiquette, maintainers' tools, branching models and releases. |
| 14. AI/ML workflows | Q354 to Q376 | 23 | Notebooks, data and model versioning, Git LFS, reproducibility and CI for ML projects. |
| 15. Production incidents | Q377 to Q393 | 17 | Running an incident: stabilise, preserve, diagnose, recover, verify, communicate, prevent. |
| 16. Debugging | Q394 to Q420 | 27 | History investigation and the diagnosis method: ranges, blame, bisect, pickaxe, interrupted operations. |
| 17. Architecture | Q421 to Q461 | 41 | Decisions that outlive a project: monorepos, submodules, large-repository performance, hooks, new storage formats. |
| 18. CTO interview | Q462 to Q482 | 21 | Cross-cutting questions on judgment, trade-offs and communication. They assume every other area. |
| **Total** | Q1 to Q482 | 482 | |

## The questions from your brief

You listed these questions as the standard you want to meet. Each is in the bank under the number shown.

| Question from your brief | Number | Area |
|---|---|---|
| Why a rebase changes commit hashes | Q143 | Rebase |
| What exactly a branch is | Q93 | Branching |
| What HEAD is | Q3 | Fundamentals |
| HEAD, a branch and a remote-tracking branch | Q92 | Branching |
| Why `reset --hard` does not necessarily delete commits permanently | Q168 | Undo |
| How the reflog helps | Q185 | Recovery |
| Why a commit can become unreachable | Q186 | Recovery |
| What happens during a three-way merge | Q125 | Merge |
| Why Git can merge two files incorrectly from a human perspective | Q122 | Merge |
| Why `--force-with-lease` exists | Q203 | Remote workflows |
| Why force-push can be dangerous | Q201 | Remote workflows |
| Revert versus reset | Q169 | Undo |
| Why cherry-pick creates a new commit | Q144 | Rebase |
| Why a pull request can show unexpected commits | Q263 | Pull requests |
| `..` versus `...` | Q394 | Debugging |
| How Git stores data | Q65 | Git internals |
| What a blob, a tree and a commit object are | Q66 | Git internals |
| What reachability is | Q67 | Git internals |
| What garbage collection is | Q70 | Git internals |
| How to recover a deleted branch | Q187 | Recovery |
| How to investigate a leaked secret | Q324 | Security |
| How to secure GitHub Actions | Q319 | Security |

---


## Area 1: Fundamentals

Q1 to Q64. The data model as you meet it every day: the three trees, the index, commits, configuration, ignore rules and attributes.


### Fundamentals: foundational level

**Q1.** Why can `git log` work without a network connection while `git push` cannot? What does your answer imply about backups?

- *Follow-up:* The server's disk is lost and you rebuild it from one developer's clone. What is certainly missing from the rebuilt repository, at the Git layer and at the GitHub layer?

**Q2.** Between `git add` and `git commit`, which files under `.git` have changed, and what does each contain?

- *Follow-up:* A file containing a secret was staged and then unstaged without ever being committed. Is the secret in the repository, and for how long?

**Q3.** What is HEAD? Explain what the file contains, the difference between the symbolic and the detached form, and what moves it.

- *Follow-up:* The textbook cites polls in which only 10% of respondents were fully confident that they understood HEAD. State the most common wrong model and the transcripts that refute it.

**Q4.** `git status` lists one file under "Changes to be committed" and under "Changes not staged for commit". Explain the state of the three trees.

- *Follow-up:* In that state the engineer runs `git restore <path>` to "undo the last edit". What is lost, what survives, and what should have been run first?

**Q5.** Define tracked, untracked and ignored in terms of the index. Can a path be tracked and ignored at the same time?

- *Follow-up:* `git add .env` is refused because the path is ignored. Is that refusal a control you can rely on to keep secrets out of the repository?

**Q6.** What is in the index when nothing is staged? Prove it with two commands.

- *Follow-up:* Stage one change and run `git write-tree` before you commit. What does the ID it prints tell you about the commit you are about to make, and what does that prove about where `git commit` reads from?

**Q7.** A file shows `MM` in `git status --short`. Which three versions exist, where is each stored, and which one does `git commit` record?

- *Follow-up:* Your tests passed and CI failed on that commit, on a line you had fixed. Which command would have shown the problem before the commit, and what is the repair?

**Q8.** What exactly does `git commit` write inside `.git`, and what does it leave untouched?

- *Follow-up:* What changes in that list when HEAD is detached, as in a CI checkout, and what is the practical consequence for the commit you made there?

**Q9.** `HEAD^2`, `HEAD~2`, `HEAD^^`: which commits are these on a merge commit, and which two are the same?

- *Follow-up:* After a merge into `main`, a tool takes the line below the merge in plain `git log` as the previous state of `main`. Why is that wrong, and what should it ask for?

**Q10.** A setting is in the system, global and local files with three different values, and an environment variable also exists for it. Which wins, and which single command shows you?

- *Follow-up:* You keep your configuration in the XDG location, and on one machine a key you set there has no effect although no repository overrides it. What do you check, and why does Git behave that way?


### Fundamentals: working engineer level

**Q11.** A colleague says "the fix is committed". List the distinct places where that statement can be true or false, and the command that checks each.

- *Follow-up:* The engineer shows you the commit on screen and `git status` says the branch is up to date with `origin/main`, yet CI still fails on the old value. Which command settles what CI built, and what do you compare its output with?

**Q12.** Name three things that Git stores and GitHub only displays, and three things that exist only on GitHub. Why does the distinction matter during an incident?

- *Follow-up:* A pull request is a GitHub object, yet pressing its merge button changes Git data. Explain what crosses the layer boundary and what a clone made afterwards will and will not contain.

**Q13.** `git status` reports that your branch is up to date with `origin/main`. What exactly did Git compare, and how old can that information be?

- *Follow-up:* Where is the upstream relation stored, and which of the diagnosis commands would show you that a branch has no upstream at all?

**Q14.** What makes a directory a Git repository? Which files in a fresh `.git` can you delete without breaking it?

- *Follow-up:* Git reports "not a git repository" inside a directory that visibly contains `.git`. What do you check, in which order, and how do you repair it without making things worse?

**Q15.** The same commands typed at two different times produce different commit IDs. Why? What did the lab environment pin to prevent it, and what did it not need to pin?

- *Follow-up:* The clock is pinned, yet the sandbox configuration also sets two reflog expiry settings to `never`. Why was pinning the dates not enough?

**Q16.** A commit changes one file out of 5,000, three directories deep. How many objects does it create, and of which types?

- *Follow-up:* The rule that makes this commit cheap makes another kind of file expensive. Which kind, and how does the snapshot model square with packfiles that store differences?

**Q17.** Why can a commit object not be edited? What do `git commit --amend` and `git rebase` do instead?

- *Follow-up:* After an amend, how would you show an auditor that the original commit still exists, and for how long can you rely on that by default?

**Q18.** Two engineers commit identical content with identical messages on two laptops. Which IDs are equal, which differ, and why?

- *Follow-up:* Their files look identical in an editor, yet the blob IDs differ. What is the likely cause and how do you find it?

**Q19.** Define "reachable". Why is a commit that no ref can reach still in the repository, and for how long by default?

- *Follow-up:* Someone deleted a branch with `git update-ref -d` and did not note the commit ID. Does the reflog help, and what would you run?

**Q20.** Describe the two forms of HEAD and how you would tell them apart on a machine you have never seen.

- *Follow-up:* A deployment script reads `.git/HEAD` and then `.git/refs/heads/<branch>` to find the deployed commit. Name the ways this breaks and the replacement.

**Q21.** Which parts of `.git` reach the server when you push, and which never do? What does GitHub hold that no clone contains?

- *Follow-up:* After a bad force-push, an engineer says "we can recover it from the reflog on the server". What does the textbook say is wrong with that plan?

**Q22.** `git status` shows the same file under "Changes to be committed" and under "Changes not staged for commit". Explain exactly which comparisons produced the two lines.

- *Follow-up:* A CI step uses `git diff --exit-code` to prove that a code generator left the tree clean. What does it miss, and what should it test instead?

**Q23.** What are the four sources of ignore patterns, in precedence order, and which would you use for `.DS_Store`, for `build/`, and for a personal scratch directory?

- *Follow-up:* A new file is not offered by `git status` on one developer's machine only. How do you find the cause, and why might the shared `.gitignore` be innocent?

**Q24.** Why can `!data/README.md` fail to re-include a file, and how do you write the rule so that it works?

- *Follow-up:* After the fix, `git check-ignore -v data/README.md` still prints a line, and a colleague concludes that the file is still ignored. What did they misread, and which second command settles it?

**Q25.** What does `git restore file.py` take its content from? How does that differ from `git restore --source=HEAD file.py`, and from `git checkout HEAD -- file.py`?

- *Follow-up:* Someone runs `git restore --source=HEAD~5 src/` to bring back one old file. What else happens, and how should the command have been written?

**Q26.** What does Git record about file permissions, and how do you make a script executable for everyone when your own filesystem cannot express that?

- *Follow-up:* A script fails in CI with "Permission denied" although it runs on the author's laptop. Where is the evidence, and how would review have caught it?

**Q27.** What exactly does `git add` write, and what remains of it after `git restore --staged`? Does a push send it?

- *Follow-up:* The file that was added and then unstaged was an `.env` file holding an API key. Is there history to rewrite, and how long does the content stay readable on that machine?

**Q28.** Compare `git restore --staged`, `git reset <path>` and `git rm --cached` for a path that HEAD has, for a path that HEAD lacks, and in a repository without commits.

- *Follow-up:* A developer "unstaged" a tracked file with `git rm --cached`, committed, and teammates lost the file on their next pull. How do you confirm that from the commit, and what is the lowest-risk repair?

**Q29.** A developer ran `git commit -a` after careful partial staging. What did the commit contain, and what is the lowest-risk fix before and after a push?

- *Follow-up:* Would `git commit <path>` on the partially staged file have preserved the selection? Explain what that form reads.

**Q30.** List every field of a commit object. Which of them can differ between two commits that have identical diffs?

- *Follow-up:* Two commits have different IDs and an empty diff between them. How do you prove they carry the same content, and what do you do if one was reviewed and the other deployed?

**Q31.** A colleague says "I only fixed the commit message, the code is the same commit". What is wrong with that sentence, and how do you prove it?

- *Follow-up:* The original commit had already been pushed, and `git push` is now rejected with a hint to pull. What do you do, and what do you not do?

**Q32.** Explain author and committer with three operations that make them differ. Which date does `git log` print, and which one does `--since` use?

- *Follow-up:* Which of the two identities can be set with a command-line option, and what does that mean for someone auditing who created a commit?

**Q33.** After `git commit --amend`, where is the old commit, how long does it stay, and how do you get it back?

- *Follow-up:* A developer committed a credential, noticed at once and amended it away before opening a pull request. Is the incident closed?

**Q34.** What is the difference between `git commit -s` and `git commit -S`? Where does each leave its mark in the object?

- *Follow-up:* Management wants every commit already on a shared branch to be signed retroactively. What does that cost, and why?

**Q35.** A commit dated last month appears in "changes since Monday". Explain it without calling it a bug.

- *Follow-up:* Why does Git filter on the committer date and not on the author date, and what follows if a build machine's clock is wrong?

**Q36.** Why does Git not read configuration from a file committed in the repository? What do teams do instead?

- *Follow-up:* The local `.git/config` is never committed, but can it still have been written by someone else, and how does Git limit the damage when it was?

**Q37.** What exactly runs when you type `git x foo` and `alias.x` is `!cmd $1`? How do you write it correctly?

- *Follow-up:* The corrected alias works from the top of the repository and does the wrong thing from a subdirectory. Why, and what do you say to a colleague who wants to call it from a CI script?


### Fundamentals: senior level

**Q38.** Two engineers type the same Git command on two Macs and see different behavior. Name three causes outside the repository and the command that detects each.

- *Follow-up:* The command works in the engineer's terminal and fails in a scheduled job on the same Mac under the same account. Which of your causes is most likely, and what would you add to the job so that the next occurrence diagnoses itself?

**Q39.** A fix must reach a shared branch that already contains the faulty commit. Compare a new commit with amending and force-pushing. Which do you choose, and what would change your answer?

- *Follow-up:* You decide a rewrite is justified on a branch you believed was private. What is the residual risk, and which form of the push does the course tell you to use instead of a plain force?

**Q40.** The course's ten-command diagnosis ritual is meant to be read-only. Which of its commands can write to disk, and why does that matter when you investigate a damaged repository?

- *Follow-up:* Why does `git status` write to the index at all, and what does that tell you about how Git detects modified files?

**Q41.** Git prints a hint that recommends `git rm --cached <path>` and then refuses that command. Explain how you would find out why.

- *Follow-up:* The same mistake happens before the first commit, where there is no HEAD to restore from. What do you run, and why is it safe for the files on disk?

**Q42.** Walk through the eleven steps of the root-cause framework for the symptom "my commit is not on GitHub".

- *Follow-up:* Which steps of the framework are forbidden from changing state, and what can the local commands never tell you in this particular investigation?

**Q43.** A report quotes a commit ID. What does that ID guarantee about file contents, history and authorship, and what does it not guarantee?

- *Follow-up:* The report's numbers were produced on a laptop whose `git status` was clean at that commit. Why is that still not proof that the run used exactly the committed state?

**Q44.** A cherry-picked commit has a different ID from the original. Is it the same commit, the same change, or the same snapshot, and how would you prove it?

- *Follow-up:* Release management asks whether a given fix commit from `main` is in the release branch. Why can an ancestry test give a misleading answer after a cherry-pick, and what do you check instead?

**Q45.** A developer added `config/secrets.yaml` to `.gitignore` and it is still in every new commit. Walk through your diagnosis commands, the fix, and the two things the fix does not solve.

- *Follow-up:* How would you make sure this class of mistake is detected across the organization instead of being found by a secret scanner months later?

**Q46.** After `git restore` destroyed some edits, a colleague says "use the reflog". What is wrong with that advice, and under what condition can part of the work still be recovered?

- *Follow-up:* Compare that loss with `git clean -fdx` deleting an ignored data directory. Would `git fsck` help there, and why or why not?

**Q47.** Prove to me that Git does not store renames. Then explain what `R087` in a diff means and name two features that depend on it.

- *Follow-up:* After a large repository reorganisation, `git log --follow` stops at the move for many files. Give two mechanisms that explain it and what the textbook advises for each.

**Q48.** A Python module imports fine on macOS and fails on the Linux CI runner after someone renamed it. What happened inside Git, and how do you prevent a recurrence?

- *Follow-up:* The opposite arrives from Linux: two tracked files whose names differ only by case. What does a clone on a Mac show, why can `git restore` not repair it, and what is the documented fix?

**Q49.** Why did switching branches delete a file that was listed in `.gitignore`?

- *Follow-up:* Before switching to an old release branch, how would you check whether any of your ignored files is at risk?

**Q50.** `git diff HEAD` prints nothing. Can `git commit` still create a non-empty commit? Construct the case.

- *Follow-up:* Which single comparison is the review of the next commit, and which kind of file do none of the three diff forms show?

**Q51.** You staged half of a file with `git add -p`, using `e` where `s` was not offered. Why is that commit riskier than a normal one, what can `e` get wrong, and how do you test what you are about to commit?

- *Follow-up:* Your working tree passes its tests. Under what condition is the partially staged commit still broken, and who finds out later?

**Q52.** `git status` is clean, and `git diff-index --quiet HEAD` in the release script exits with 1. Explain the mechanism and fix the script.

- *Follow-up:* An engineer logs into the build container, runs `git status`, sees a clean tree, runs the script by hand and it passes. Why did the symptom disappear?

**Q53.** One CI job fails because `.git/index.lock` exists, another because the index file is corrupt. For each: diagnosis, fix, and what is lost.

- *Follow-up:* In which situation must you not delete and rebuild the index, and why is the loss there different in kind?

**Q54.** Our deploy tool stores abbreviated IDs. What can go wrong, and what should it store?

- *Follow-up:* The tool now stores full IDs. A month later the deployed ID is no longer on the release branch, although the code is identical. How do you diagnose that, and what prevents it?

**Q55.** Why does GitHub show a teammate's commits without a profile link, and what does that tell you about who pushed them?

- *Follow-up:* Would you rewrite the affected commits to repair the attribution? What do you put in place so it does not recur?

**Q56.** When does Git fail to recognise a trailer? How would you make ticket IDs queryable across a year of history?

- *Follow-up:* A commit ends with a sentence followed by the line `Refs: EVAL-300`, and the report tooling finds no trailer. What are the possible causes, how do you check, and which configuration makes the parser accept that block?

**Q57.** Your `includeIf` rule for `~/work/` exists, yet a work repository commits with your personal address. Give four causes and the command that distinguishes them.

- *Follow-up:* After you repair the rule, how do you stop the next misconfiguration from producing commits with the wrong address, and what happens to the commits that were already pushed?

**Q58.** Your team adds `* text=auto` to a five-year-old repository. What does the next `git status` show, what does `git add --renormalize .` do, and how do you protect open branches and `git blame`?

- *Follow-up:* Why is asking every engineer to set `core.autocrlf` not a substitute for this as a team policy?

**Q59.** Explain "the attribute travels, the driver does not" for a diff driver, a merge driver and a required filter.

- *Follow-up:* Which arrangements get the driver definition into every clone, and what is the risk of the most convenient one?


### Fundamentals: principal level

**Q60.** An incident review concludes: "Git keeps everything, so we cannot lose work." As principal engineer, explain to a non-specialist executive where that safety net does not exist, name the common root cause, and propose the controls you would adopt across the organization.

- *Follow-up:* An engineer objects that staged but uncommitted work is equally unprotected. Is that right, and how long does any protection last?

**Q61.** Compare `git clean -fdX` with `git clean -fdx`. Which one would you allow in a CI cleanup step for an ML repository, and what would you run first?

- *Follow-up:* The dry run prints a line saying it would skip a repository under `vendor/`. What is that directory, and what would make `git clean` delete it?

**Q62.** As engineering lead you must define what counts as "the build of commit X" for releases and for reported evaluation numbers. Explain why a developer's working tree with a clean `git status` does not qualify, and state the policy and the evidence you would require.

- *Follow-up:* The policy costs build time, and engineers ask for an exemption: "run `git clean -fdx` first, then build in place". What is your answer?

**Q63.** Why are `--assume-unchanged` and `--skip-worktree` not ways to ignore local changes? What do you recommend to a team that needs per-developer settings?

- *Follow-up:* The team README already tells every developer to run `git update-index --skip-worktree` on the config file. What does that cost the organization, and how do you find and unwind the bits that exist?

**Q64.** Which Git settings would you standardize across a team, and which would you leave to each engineer?

- *Follow-up:* You named signing as a team policy. What breaks if `commit.gpgSign=true` is rolled out to every laptop by a script, and what has to be in place first?


## Area 2: Git internals

Q65 to Q90. The object database, references, packfiles, reachability and maintenance.


### Git internals: foundational level

**Q65.** How does Git store data?

- *Follow-up:* If every commit is a complete snapshot, why are four hundred versions of a large line-oriented file not four hundred copies on disk, and when does that argument fail?

**Q66.** What are a blob, a tree and a commit object?

- *Follow-up:* Which facts about a file does Git record nowhere in these objects, and what follows for empty directories and for file permissions?

**Q67.** What is reachability?

- *Follow-up:* After a leaked secret, a commit was removed from every branch and tag. Is it unreachable, is it gone, and where else does it still exist?

**Q68.** Compute the object ID of a blob by hand. Which bytes are hashed, and why does the compression level not matter?

- *Follow-up:* Two files with different names in different directories have identical content. How many blobs does Git store, and where do the names live?

**Q69.** What does `git range-diff` compare, and what do `=`, `!`, `<` and `>` mean?

- *Follow-up:* On GitHub a contributor force-pushes a rebased branch during review. Which of these ideas carry over to the platform, and what do you do locally when the platform's view is not enough?


### Git internals: working engineer level

**Q70.** What is garbage collection in Git?

- *Follow-up:* Under the default maintenance strategy of Git 2.55, which run finally deletes an unreachable object, and how do you see that garbage is being held?

**Q71.** A tree entry has mode `160000`. What is it, what object type does the ID name, and why can `git cat-file` not show it?

- *Follow-up:* A deploy step fails with "permission denied" on a script that runs on every laptop. How does a tree listing diagnose it, and which file permissions does Git record at all?

**Q72.** What does a commit ID commit you to? Explain why changing a commit message three commits back changes the ID of `HEAD`.

- *Follow-up:* After that rewrite, what proves that no file content changed, and what remains true about the old commits?

**Q73.** A deploy script reads `.git/refs/heads/main`. Name two situations in which that file does not describe the branch, and the command that always does.

- *Follow-up:* The script switches to `git rev-parse main` without `--verify`, and one day stamps a build with the literal text of a branch name. What happened, and how do you write the line so that it cannot?

**Q74.** Someone copied a repository with `cp -R` and now every file is "modified". Explain the mechanism and the one-command fix.

- *Follow-up:* A CI job uses `git diff-files --quiet` as its "is the tree clean" gate right after restoring a cached checkout, and fails on every run, while `git status` in the same job reports nothing. Why, and what is the correct gate?

**Q75.** Explain a patch file line by line. Which parts become the commit, and why do the author and the committer differ after `git am`?

- *Follow-up:* The maintainer's branch has moved and the series no longer applies. What do you see, what do you run, and what could the contributor have done to make this cheaper?

**Q76.** Explain geometric repacking with three packs of 500, 30 and 30 objects. What happens at the next run, and what is never rewritten?

- *Follow-up:* With packs of 507 and 24 objects the next run merges nothing and leaves a third pack behind. Why, and is a growing number of packs a problem to fix?


### Git internals: senior level

**Q77.** We have six versions of a 16 MB file. What does the pack contain, which version is stored whole, and what happens when a byte in that version is damaged?

- *Follow-up:* Why does the size on disk of one version tell you little about which commit made the repository large, and how do you measure storage per object?

**Q78.** `git fsck` says `dangling commit`. Walk me through what you check before you decide whether anything is at risk.

- *Follow-up:* Git 2.55.0 reports a dangling commit and Apple's Git 2.50.1 on the same Mac reports nothing for the same repository. Explain the disagreement and say which source you trust.

**Q79.** Why can a corrupt object survive `git cat-file` and `git status` but not a clone over the network?

- *Follow-up:* How do you repair that object without another clone, and why does Git not replace the bad file when you write the correct content?

**Q80.** What is the difference between `ORIG_HEAD`, `FETCH_HEAD` and `refs/heads/main` as far as garbage collection is concerned?

- *Follow-up:* A reviewer fetches a colleague's branch by URL, intending to inspect it next week. What should the command have been, and what is the exposure if it was not?

**Q81.** A release script reads `.git/refs/heads/main` and checks that the content is forty hexadecimal digits. It has worked for years and now fails in two repositories with two different errors. Explain both root causes at the storage level, and state the rule that prevents this class of failure.

- *Follow-up:* You repair the script with `git repo info`. What risk have you introduced into shared automation, and how do you contain it?

**Q82.** What does Git 2.55 run when a commit triggers automatic maintenance? How does that differ from `git gc`, and what does each delete?

- *Follow-up:* The manual page of Git 2.55 says in two places that only the `gc` task is enabled by default. How do you settle what really runs, and how do you ask whether a run would do anything?

**Q83.** What is a cruft pack, and why can a repository under the default strategy hold unreachable objects for a long time?

- *Follow-up:* A repository is large although its history is small, and `git count-objects -v` shows no loose objects. How do you confirm that retained garbage is the cause?

**Q84.** What two kinds of data does a commit-graph hold, and which commands does each help? What happens when the file is stale, and when it is damaged?

- *Follow-up:* Two clones of the same repository give different answers to the same history question. What is your first move, and why is it safe?

**Q85.** Why are bitmaps a server feature? What does the counter `pack-reused` tell you?

- *Follow-up:* You run a bare mirror for CI, and clones wait a long time before any transfer progress appears. What do you check on the mirror, and what will a bitmap not fix?


### Git internals: principal level

**Q86.** When would you migrate a repository to reftable, what breaks if you do it carelessly, and what stays the same?

- *Follow-up:* After the migration, a monitoring script that tests for the file `ORIG_HEAD` or reads `.git/HEAD` misbehaves, while one that tests for the file `MERGE_HEAD` still works. Explain the difference.

**Q87.** Why do we keep our repositories in SHA-1 although Git supports SHA-256, and what would have to change for that to change?

- *Follow-up:* Given that, what do you require of our internal tooling today so that a later change of object format does not break it?

**Q88.** A laptop lost power during a commit, and Git now reports that the index file is corrupt. What did we lose, and what general rule decides which files under `.git` may be deleted and rebuilt in an incident and which must be restored from another copy?

- *Follow-up:* Which of the primary files does a clone or a push never carry, and what follows for how you back up a repository you cannot afford to lose?

**Q89.** An engineer staged a file containing a credential, noticed it, unstaged the file and reports that it "never entered the repository". Explain to a non-specialist executive why that statement is wrong, how long the credential stays, and why routine maintenance cannot be relied on to remove it.

- *Follow-up:* The purge will use a prune without a grace period. What are the preconditions before you allow that command on a repository, and what is the recovery if it removes too much?

**Q90.** A repository's packs are several times larger than its content and history seem to explain, and nobody has committed large binaries recently. Which mechanisms in the object store can produce that, how do you tell them apart, and when is a full repack with non-default settings a defensible decision?

- *Follow-up:* The consultant's nightly `git gc --aggressive` and Dropbox's repack both recompute deltas. Why do you reject the first and accept the second?


## Area 3: Branching

Q91 to Q121. Branches and tags as refs, HEAD, upstream configuration, worktrees.


### Branching: foundational level

**Q91.** What is a branch, what does creating one cost, and what does Git know about the branch it was created from?

- *Follow-up:* If Git records no parent branch, how does `git status` know what a branch is up to date with, and is that the same thing?

**Q92.** What is the difference between HEAD, a branch and a remote-tracking branch?

- *Follow-up:* `git status` says your branch is up to date with `origin/main`, and a colleague pushed ten minutes ago. Is Git wrong? What does the statement mean?

**Q93.** What exactly is a branch? Define it in one sentence that mentions neither "copy" nor "line of development", and prove the definition with two commands.

- *Follow-up:* If a branch is only a name for one commit, how do you repair two unpushed commits that were made on local `main` and belong on a feature branch, and how much data is copied?

**Q94.** Describe the objects and refs created by `git tag v1`, `git tag -a v1` and `git tag -s v1`. What does `v1^{}` resolve to in each case?

- *Follow-up:* Someone runs `git tag -a v1-audited v1` where `v1` is already an annotated tag. What is created, what does Git say about it, and where does `^{}` end?

**Q95.** What exactly does `git worktree add` create on disk, in the new directory and in the repository?

- *Follow-up:* The new directory is later moved with `mv`. Which pointer is now stale, what does `git worktree list` show, and does the worktree's ID change?

**Q96.** Which parts of a repository are shared between worktrees and which are per worktree? How do you find out for a path you are unsure about?

- *Follow-up:* HEAD is per worktree. How do you name the HEAD of another worktree from where you are, and what is that useful for?


### Branching: working engineer level

**Q97.** What is in `.git/HEAD` in the three states: on a branch, detached, and on an unborn branch? How does each state change what `git commit` does?

- *Follow-up:* You rewrite HEAD alone with `git symbolic-ref HEAD refs/heads/<other>`. What does `git status` report, and what does that tell you about what `git switch` does beyond changing HEAD?

**Q98.** A colleague's two days of commits are "gone" after she checked out a tag and later switched back to `main`. Walk through the recovery and explain why it works.

- *Follow-up:* How long does she have before the recovery stops working, and what exactly would make the commits unrecoverable?

**Q99.** What does `git switch -c fix origin/main` write to `.git`, including configuration?

- *Follow-up:* What is different when the start point is a local branch, and why does `-c` stop when `fix` already exists while `-C` does not?

**Q100.** `git log main..feature` and `git diff main..feature`: how do the two dots differ in meaning? Which one do you want for a review?

- *Follow-up:* How do you put a number on how far two branches have diverged, and why is "3 commits ahead" an incomplete statement?

**Q101.** Which commands for working with branches and refs are dangerous enough that you would want a preview, and what is the preview for each?

- *Follow-up:* Which of those operations has no recovery at all, and why can neither the reflog nor `git fsck` help?

**Q102.** `git describe` prints `v1.0.0-2-gc053f0d` on a laptop and fails in CI. Explain every part of the string and the failure.

- *Follow-up:* After a patch release was tagged on a release branch, `git describe main` still names the older tag. Is that a defect, and how do you answer "which release contains this fix"?

**Q103.** Why does Git refuse to check out one branch in two worktrees? Describe what would go wrong, in terms of refs and indexes.

- *Follow-up:* The stale worktree does contain real uncommitted work. What is the lowest-risk repair, and which two states make a branch count as checked out although `git worktree list` shows a detached HEAD?

**Q104.** `git branch -d` says a branch is used by a worktree at a path that does not exist. What happened, and what are the two commands that diagnose and fix it?

- *Follow-up:* Before you prune, what must you rule out, and what is lost together with the entry?

**Q105.** A teammate ran `git stash pop` and got changes they had never seen. The repository has four worktrees. Explain.

- *Follow-up:* Which other things that people expect to be private to a worktree are shared in the same way, and how do you make one of them per worktree?


### Branching: senior level

**Q106.** Why does `git branch -d` refuse a branch that was squash-merged once its upstream is gone (or when it never had one), why does it delete the same branch with a warning while the remote-tracking ref still contains it, and how do you prove the branch is safe to delete?

- *Follow-up:* Git 2.56 adds `git branch --delete-merged`. Would you rely on it to clean up squash-merged branches?

**Q107.** Explain the `git branch -d` rule in terms of the upstream. Give one case where `-d` deletes a branch that `main` does not contain, and one where it refuses a branch that `main` does contain.

- *Follow-up:* Given that rule, can a plain `git branch -d` delete `main` itself? What decides it, and how do you recover?

**Q108.** Does Git know which branch a branch was created from? What is the closest it can offer, and why is a pull request's base branch not the same thing?

- *Follow-up:* Branch B was created from branch A. A is squash-merged into `main` and deleted. What happens to B's changes against `main`, and what is the repair?

**Q109.** Why does `git fetch` fail on every clone after someone pushes `feature/login`, and what is the one-command fix?

- *Follow-up:* Is this a limitation of storing refs as files, and would another ref storage backend make the problem go away?

**Q110.** Why does `git tag -d` have no undo through the reflog, while `git branch -D` sometimes does?

- *Follow-up:* For which kind of branch is `git branch -D` as unrecoverable as a tag deletion, and what do you run before deleting?

**Q111.** On macOS, `git branch` shows no current branch and `git log --decorate` says `(HEAD, main)`. What happened?

- *Follow-up:* Can that machine end up with both `main` and `Main` as branches? Under what condition, and what happens afterwards?

**Q112.** A release script clones the repository with `git clone --branch <tag>`, commits a generated file and pushes. It worked when a developer ran it in a normal clone on `main`, and it fails in the pipeline. Explain the root cause and the rules you would set for scripts that run Git.

- *Follow-up:* The script labels each build with the output of `git rev-parse --abbrev-ref HEAD`. What does the label say in the pipeline, what do the other two ways of asking return, and what should the label be?

**Q113.** A release tag was force-moved yesterday. Who has which version of it today, how do you find out, and what is the lowest-risk repair?

- *Follow-up:* Suppose nobody still has the original ref: the person who moved it overwrote their own, and the others fetched with `--force`. Is the published tag recoverable, and from what?

**Q114.** A rebase has stopped at a conflict and an urgent fix is needed on `main`. Compare three options: abort the rebase, a second clone, a worktree.

- *Follow-up:* The tests will not start in the new hotfix directory although they run in the original one. Why, and how could you have known in advance?

**Q115.** Is a commit that exists only on the detached HEAD of a linked worktree safe from `git gc`? When does that stop being true?

- *Follow-up:* `git worktree remove` refuses when the tree has modified or untracked files. Does that refusal protect these commits?

**Q116.** After moving a project directory to another disk, every linked worktree reports "not a git repository". What broke, how do you repair it, and how could it have been avoided?

- *Follow-up:* What can `git worktree move` not move, and how do you protect a worktree on a disk that is not always mounted from being cleaned up?

**Q117.** When is a separate clone the better tool?

- *Follow-up:* A team keeps a bare repository and adds every branch as a linked worktree beside it. Is that layout valid, and what do you check?


### Branching: principal level

**Q118.** There are 340 branches on the server. You are accountable for the cleanup. How do you decide which can be deleted without losing anything, and what policy keeps the number from growing back?

- *Follow-up:* After the cleanup, someone argues that deleting a branch on the server was also the right way to get rid of a credential committed on it. What is your answer?

**Q119.** A director asks for a report built from Git alone: for every branch, who created it, when, from which branch, and which commits belong to it. Which of these can Git answer, and what do you offer instead?

- *Follow-up:* A colleague proposes filling the "created from" column with `%(is-base:...)` from `git for-each-ref`. Why do you refuse?

**Q120.** `receive.denyNonFastForwards` is set on our Git server. Are our tags safe? How would you prove your answer?

- *Follow-up:* With a tag rule in place on your own server, what must a consumer of somebody else's tags still do, and why?

**Q121.** Your team wants several AI coding agents to work in one repository at once. What do worktrees give you, and what do they not give you?

- *Follow-up:* One agent needs a commit identity different from the others. What happens if it runs `git config set user.email` in its own worktree, and what is the supported way, with its compatibility cost?


## Area 4: Merge

Q122 to Q141. Merge bases, the three-way rule, conflicts and their stages, strategies, rerere, auditing a merge.


### Merge: foundational level

**Q122.** Why can Git merge two files incorrectly from a human perspective?

- *Follow-up:* Name two merge options that make a result clean and wrong, and say how you would detect such a merge afterwards.

**Q123.** `git merge feature` printed "Fast-forward". What changed in `.git`, and what did not?

- *Follow-up:* What is the production risk of a fast-forward leaving no trace, and how do you recover from one and forbid the next?

**Q124.** State the three-way rule for a single path as a table of base, ours and theirs. Which rows never read file content?

- *Follow-up:* The rows mention three snapshots and nothing else. Which two consequences of that surprise people in production?


### Merge: working engineer level

**Q125.** What happens during a three-way merge?

- *Follow-up:* The tree of the merge commit is a snapshot that neither author wrote. What follows for testing, and what does GitHub Actions do about it by default?

**Q126.** Define "merge base". How can two commits have more than one, and what does the default strategy do then?

- *Follow-up:* Why does Git not pick one of the two merge bases and proceed, and how would you demonstrate the consequence of picking one?

**Q127.** Two branches changed different lines of one file and the merge still conflicted. Give the exact condition under which that happens.

- *Follow-up:* Which kinds of files meet that condition far more often than others, and why?

**Q128.** During a conflict, what are index stages 1, 2 and 3? How do you read "their" version of a file without touching the working tree?

- *Follow-up:* Which conflict types leave fewer than three stages, and what do `git checkout --theirs` and `git restore --theirs` do on a path that has no stage 3?

**Q129.** What does rerere record, and when? Why does a resolution recorded in a merge also serve a rebase in the other direction?

- *Follow-up:* When rerere replays a resolution during a merge, what do the command output, the file and the index look like, and why does that matter?


### Merge: senior level

**Q130.** A conflict was resolved with `git checkout --theirs path`, and a teammate's unrelated fix in that file disappeared. Explain the mechanism and prove it from history.

- *Follow-up:* How would you have resolved that conflict so the unrelated fix survived, and which configuration makes the mistake harder to make?

**Q131.** Compare `git merge -X ours`, `git merge -s ours` and `git merge --squash` in terms of content and ancestry.

- *Follow-up:* A branch was squash-merged, work continued on it, and the second squash conflicts on a line the first squash already delivered. Explain it and give the rule.

**Q132.** What do `git show <merge>`, `git show --first-parent <merge>` and `git show --remerge-diff <merge>` each display? Which one audits a conflict resolution?

- *Follow-up:* A merge was made with `-X ours` and looked clean when it was made. Does the audit show it, and what are the audit's limits?

**Q133.** A change was made on two branches and reverted on one. After the merge it is back. Explain with the merge base.

- *Follow-up:* Would `git show --remerge-diff` on that merge commit flag the returned change? Justify the answer.

**Q134.** You reverted a merge and later merged the repaired branch; part of the feature is missing. What happened, and what is the correct sequence?

- *Follow-up:* Why does `git revert` refuse a merge commit until you pass `-m`, and what exactly does `-m 1` undo?

**Q135.** How can a server with no working tree decide whether a pull request merges cleanly? What does stock Git offer for that?

- *Follow-up:* What is documented about GitHub Actions when a pull request has a merge conflict, and what should a script use to decide between clean and conflict?

**Q136.** `git merge --abort` is supposed to return you to the state before the merge. An engineer ran it during a conflicted merge and lost an uncommitted edit that predated the merge. How did the safety net fail, can the edit be recovered, and what do you tell the team?

- *Follow-up:* A different engineer used `git merge --autostash`, saw the hint to run `git stash pop` after the conflict, and `git stash pop` reports no entries. Where is their work?

**Q137.** A wrong value reached `main` through a replayed resolution. Give the diagnosis and the complete fix. Why is a new commit alone not enough?

- *Follow-up:* Which settings and habits would have prevented it, and what are rerere's limits as a mechanism shared by a team?

**Q138.** A rebase with rerere enabled dies with `Unable to create MERGE_RR.lock`. Give the root cause, the recovery and the prevention.

- *Follow-up:* How confident are you in that root cause, and what evidence does the course have for it?


### Merge: principal level

**Q139.** Both branches were green, the merge had no conflict, and `main` is red. Why can Git not detect this, and which process controls can?

- *Follow-up:* Describe the variant of this failure in which no check turns red at all.

**Q140.** Design the integration rules for `main` and one long-lived release branch so that history stays auditable and every feature stays revertable. Which merge practices do you mandate, and which demonstrated failure does each one prevent?

- *Follow-up:* Explain the first-parent flip you mentioned: how it happens with two ordinary commands, and what breaks afterwards.

**Q141.** A team proposes three measures against recurring conflicts: rerere with `rerere.autoUpdate` for everyone, `merge=union` on the changelog, and a keep-ours merge driver for the lock file named in `.gitattributes`. Assess each as a team-wide mechanism, including for pull requests merged on GitHub, and say what you would require.

- *Follow-up:* Where the keep-ours driver is defined the merge is clean. What is the more honest setting for a lock file, and what does the merge look like then?


## Area 5: Rebase

Q142 to Q167. Rebase in all its forms, and cherry-pick: replayed commits, rewritten history, and when not to rewrite.


### Rebase: foundational level

**Q142.** A rebase "moves" a branch onto `main`. Describe what happens to objects, refs and HEAD, step by step, and name what has not changed when the command returns.

- *Follow-up:* You do the same rebase twice: once with `git rebase main`, once by hand with `git switch --detach main`, `git cherry-pick main..<branch>` and `git switch -C <branch>`. Are the resulting commit IDs equal, and what does the answer say about what a commit ID records?

**Q143.** Why does a rebase change commit hashes: why does every rebased commit have a new ID even when its diff is identical? Which fields of the commit object changed, and which did not?

- *Follow-up:* An interactive rebase reworded the fifth of six commits and nothing else. Which commits kept their IDs and why, and what outside the repository may now hold a stale ID?

**Q144.** Why does cherry-pick create a new commit?

- *Follow-up:* Is there a case in which `git cherry-pick` creates no new object, and what happens to a signature on the original commit?

**Q145.** Name the base, "ours" and "theirs" of a cherry-pick. How does a revert differ?

- *Follow-up:* Why is the base of a cherry-pick not the merge base of the two branches, and what practical consequence does that have when the pick conflicts?

**Q146.** Which fields does the copy share with the original commit, and which not? What follows for `git branch --contains`?

- *Follow-up:* A developer ran `git cherry-pick -n` and then committed. Which of the shared fields are different now, and how is the credit restored?


### Rebase: working engineer level

**Q147.** A rebase is stopped at a conflict. Where do the branch ref, HEAD, `ORIG_HEAD` and `REBASE_HEAD` point? What does that imply for `--abort`?

- *Follow-up:* A developer left the stopped rebase with `git rebase --quit` instead of aborting. What state is the repository in, where is an autostash, and how do you get back to the branch?

**Q148.** During a rebase, what do `--ours` and `--theirs` refer to, and why? Give one concrete way this loses work without any error message.

- *Follow-up:* The resolution was correct this time, but the developer ran `git commit --amend` before `git rebase --continue`. What does the history look like afterwards, and why?

**Q149.** The reviewer approved three commits; after your rebase there are still three with the same titles. How do you show what changed, and how does the reviewer do it without access to your clone?

- *Follow-up:* On a clean rebase in which nothing was edited, `git range-diff` reports one commit as removed and one as added under the same subject. Has a commit been lost?

**Q150.** `ORIG_HEAD` does not point where you expected after a rebase. Why, and what do you use instead?

- *Follow-up:* How long does that replacement handle last by default, and which two habits destroy or defeat a backup of the old tip?

**Q151.** "Cherry-pick applies a patch." What is imprecise about that sentence, and when does the difference show?

- *Follow-up:* If the three-way merge succeeds where a patch is refused, does a clean cherry-pick mean the backport is correct?

**Q152.** A backport applied without conflict and broke the release build. Explain the mechanism and how you would have caught it.

- *Follow-up:* The broken pick has already been pushed to the shared release branch. How do you take it out, and how does that differ from the recovery for a pick that is still local?

**Q153.** Compare the state after a stopped cherry-pick of a range with the state after a stopped rebase. Where is HEAD, and what has happened to the branch?

- *Follow-up:* A release script cherry-picks a list of commits, and one of them conflicts in CI. What must the script do, and what must it never do?


### Rebase: senior level

**Q154.** `git rebase main` on a feature branch conflicts in a file the branch never touched. Give two different root causes and the command that fixes each.

- *Follow-up:* After a squash merge of the lower branch, when does a plain `git rebase main` on the follow-up branch do the right thing without `--onto`, and how do you check before you run it?

**Q155.** You force-pushed a rebased branch. A teammate now has every commit twice. Explain how that happened, how they repair it, and what you would have done differently.

- *Follow-up:* Why is the duplicated history more than cosmetic noise, in particular when the purpose of the rewrite was to remove a credential or a large file?

**Q156.** Compare `--force`, `--force-with-lease`, and `--force-with-lease --force-if-includes`. Describe a sequence of events in which the second overwrites a colleague's commit and the third refuses.

- *Follow-up:* Is there a form of the lease that does not depend on your remote-tracking branch at all, and what does the Git manual say about the forms that do?

**Q157.** A colleague's pushed commit vanished from their own branch after `git pull --rebase`. Nobody ran a destructive command on their machine. Explain the mechanism and recover the commit.

- *Follow-up:* Could the server have told you what the branch pointed at before, and what does that imply for recovery if no clone has the commit any more?

**Q158.** What do `--update-refs` and `--rebase-merges` each add to a plain rebase, and what does each still leave for you to do?

- *Follow-up:* With `rebase.updateRefs` set to true, a developer made a backup with `git branch backup/x` before a risky rebase. Afterwards the backup equals the rebased tip. Explain, and name a backup that works.

**Q159.** A fix was backported with `-x`. Give three ways to establish that the release branch contains it, and say which of them can give a wrong answer and why.

- *Follow-up:* After the release branch is merged back, your changelog generator counts the fix twice. Which query gives the real difference between the two lines, and what does it still miss?

**Q160.** In a cherry-pick conflict, stage 1 shows a line that never existed on your branch. Where does it come from, and how do you use it to resolve correctly?

- *Follow-up:* After resolving, one developer finished with `git commit --no-edit` and another with `git commit -m`. What is wrong with each resulting commit, and what is right about both?

**Q161.** What does `git cherry-pick -m 1 <merge>` create, and why is it not equivalent to merging the branch?

- *Follow-up:* `git revert` needs the same option for a merge commit. Why, and where does the textbook treat the consequences?


### Rebase: principal level

**Q162.** When would you choose a merge over a rebase for the same integration, and when the reverse? Argue both sides for a team that bisects often.

- *Follow-up:* You chose the rebase and CI is green on the branch tip. What exactly has been proved about the intermediate commits, and how do you close the gap?

**Q163.** You own the policy for history rewriting across an engineering organization. Which controls do you place on GitHub, which in client configuration, review and CI, and which commonly proposed control do you refuse to rely on?

- *Follow-up:* Suppose one laptop does not carry your client settings. Which of your controls still hold, and what stays exposed?

**Q164.** A model card and a training run's metadata record the commit ID of the code that produced a model. After the pull request was merged, that ID is on no branch. Explain to a non-specialist executive what happened and what you would change.

- *Follow-up:* Someone proposes tagging the commit before the rebase so that the record survives. Does the tag follow the rebase, and does a signature carry over to the replayed commit?

**Q165.** Two long-lived branches exchange fixes by cherry-pick in both directions. What problems accumulate, and what would you change?

- *Follow-up:* You make `-x` mandatory for every pick. Under which conditions does the recorded line itself stop being a reliable link?

**Q166.** When do you fix on the oldest branch and merge upward, and when on `main` with a backport? Argue both.

- *Follow-up:* Under the backport convention, what do you record for an ML service whose release line is the version a customer's evaluation was signed off against?

**Q167.** Design an unattended job that backports a list of approved fixes from `main` to a release branch. What must it do at each step, how does it fail safely, and what can it not prove?

- *Follow-up:* Six months later an auditor asks which of the approved fixes are on the release branch. Which query do you trust, and which two would you not trust on their own?


## Area 6: Undo

Q168 to Q184. Reset, revert, restore and stash: choosing the undo that destroys least.


### Undo: foundational level

**Q168.** Why does `git reset --hard` not necessarily delete commits permanently?

- *Follow-up:* Under which conditions does a commit that was reset away become permanently unrecoverable?

**Q169.** What is the difference between revert and reset?

- *Follow-up:* How do you decide, with evidence, which of the two is allowed for a given commit?

**Q170.** A colleague asks for "the undo command". Name the five commands that Git offers for undoing work, and say which of working tree, index, branch ref and history each one writes.

- *Follow-up:* Which of those five leave no record in Git from which the previous state could be restored, and why?

**Q171.** HEAD, the index and the working tree hold three different versions of one file. What does each hold after `git reset --soft HEAD~1`, after `--mixed` and after `--hard`, and what does `git status -s` print?

- *Follow-up:* After the soft reset, what would `git commit` record, and where is the commit that left the branch?

**Q172.** Where is the stash list stored, and what exactly does `git stash drop 'stash@{1}'` write?

- *Follow-up:* Given that storage, is the stash an acceptable place to keep a week of work, and how do stashes get to another machine?


### Undo: working engineer level

**Q173.** An engineer ran `git reset --hard HEAD~3` in a dirty tree. What can you recover, with which commands and for how long, and what is gone? Why is that part gone?

- *Follow-up:* Ten files were staged before the reset. What does recovering them look like in practice, and what information about them is lost for good?

**Q174.** What is `ORIG_HEAD`, which commands write it, and why is the reflog the more reliable tool?

- *Follow-up:* Give a concrete sequence in which `git reset --hard ORIG_HEAD`, run after a merge, fails to undo the merge.

**Q175.** When do you choose `git reset --keep` over `--hard`? What does `--merge` do to staged changes, and why was it designed that way?

- *Follow-up:* In which cases does `git reset --keep` refuse to run, and what state does a refusal leave behind?

**Q176.** Compare `git clean -fdx` with `git reset --hard`: which files does each destroy, and for which of them does Git still hold an object?

- *Follow-up:* How do you preview each command, and what do you run instead when you are not sure the files are disposable?

**Q177.** What is inside a stash entry and where is it stored? What happens when `git stash pop` conflicts? Give three reasons not to use the stash for long-term storage.

- *Follow-up:* A stash entry was dropped by mistake an hour ago. How do you get it back, with and without the terminal scrollback?

**Q178.** Draw the commits of a stash entry made with `git stash push -u`. Which tree holds the staged change, which the unstaged one, and what does `git stash show -p` compare?

- *Follow-up:* How does Git itself build a stash entry without putting it on the stash list, and where does the course show Git doing that on its own?

**Q179.** An engineer lost their staging after `git stash pop`. Why does the information still exist, and which single command restores it?

- *Follow-up:* The engineer closed the terminal, so the ID that `pop` printed is gone. How do you find the commit, and how long do you have?


### Undo: senior level

**Q180.** Describe `git revert` as a three-way merge: what are base, ours and theirs? Use the answer to explain why reverting an old commit can conflict.

- *Follow-up:* A revert of a range of commits stopped with a conflict at its second step. What state is the repository in, and what does each of the four ways out do?

**Q181.** A bad commit is on `main` and the team has pulled it. Compare "revert and push" with "reset and force-push": what does each do to the server, to the teammates' clones and to CI?

- *Follow-up:* An engineer has already reset or amended locally, and the plain push was rejected as a non-fast-forward. What is the lowest-risk way back?

**Q182.** You reverted a merge with `-m 1` last week. Today the fixed branch was merged again and the feature is incomplete. Explain the mechanism with the merge base and give two correct procedures. What would `-m 2` have undone, and why does a squash merge not show the problem?

- *Follow-up:* Suppose the feature branch was rebuilt as new commits instead of being fixed by adding one. Which way out is now wrong, and why does a plain `git rebase main` not rebuild the branch?

**Q183.** A faulty change was applied to both `main` and a release branch. It was reverted on the release branch only, the release branch was later merged into `main`, and the fault is still live on `main`. Nobody saw a conflict. Explain the mechanism.

- *Follow-up:* How do you correct `main` now, and what do you add to the release procedure so that this cannot recur?


### Undo: principal level

**Q184.** A faulty feature was merged into a protected, shared `main` with a merge commit and is deployed. You can revert the whole merge, revert the single faulty commit, or fix forward. How do you choose, and what must the runbook say so that the choice does not cause a second incident?

- *Follow-up:* An engineer asks for a one-time exception to force-push `main` because a credential was committed. Do you grant it, and why?


## Area 7: Recovery

Q185 to Q200. The reflog, unreachable objects, `git fsck`, and the limits of every safety net.


### Recovery: foundational level

**Q185.** How does the reflog help?

- *Follow-up:* Where does the reflog stop helping? Name the limits a team must not forget.

**Q186.** Why can a commit become unreachable?

- *Follow-up:* An unreachable commit still exists. What exactly decides when it stops existing?


### Recovery: working engineer level

**Q187.** How do you recover a deleted branch?

- *Follow-up:* The deleted branch was a teammate's, which you had only fetched, and `git fetch --prune` removed it. What changes?

**Q188.** Someone lost work. Which three questions do you ask before you type anything, and what does each answer rule in or out?

- *Follow-up:* Once you have classified the loss as committed work, what are the remaining steps of a disciplined recovery, in order?

**Q189.** What is the difference between the HEAD reflog and a branch reflog? Give an incident for which only the first helps and one for which the second is the better tool.

- *Follow-up:* Why should an incident note record the full commit ID and not a selector such as `main@{1}`?

**Q190.** What is the difference between a dangling and an unreachable object, and why does `git fsck` hide some lost commits unless you pass `--no-reflogs`?

- *Follow-up:* You found a dangling commit with `git fsck`. Is it safe now, and how do you see exactly what hangs on it?

**Q191.** A file was staged and then wiped by `git reset --hard`. What exactly can you get back, how, and what is gone? Why?

- *Follow-up:* The file had been staged twice with different content before the reset. What do you find, and how long do you have?


### Recovery: senior level

**Q192.** State the default retention periods, say which event starts each period, and explain why "30 days plus two weeks" is not a guarantee.

- *Follow-up:* A commit was replaced by an amend 40 days ago and the developer wants it back today. What do you tell them about the odds, and what do you check first?

**Q193.** Name the situations in which a reflog does not exist or is deleted at once. How do you recover in each?

- *Follow-up:* Stash entries are an exception in the other direction. What is the exception, and how can a housekeeping command still empty the stash list?

**Q194.** `git reset --hard ORIG_HEAD` restored the wrong state. Explain the mechanism and the correct procedure.

- *Follow-up:* Why is the wrong state after such a reset sometimes hard to notice, and which habit catches it before the reset runs?

**Q195.** A teammate force-pushed over two commits on `main`. What evidence exists in your clone, on the server, and in other clones, and which repair do you choose?

- *Follow-up:* You decide to restore the old value on the server, which is itself a force push. How do you make it safe, and why not rebase the lost commits onto the forced commit instead?

**Q196.** `git fsck` reports `missing tree`. Why does `git fetch` not repair it, and what does?

- *Follow-up:* The damaged object belongs to a commit that exists only in your clone and was never pushed. What are your options?


### Recovery: principal level

**Q197.** Describe precisely what `git reflog expire --expire=now --all` followed by `git gc --prune=now` does, when it is appropriate, and what can still bring a commit back afterwards.

- *Follow-up:* During an incident, someone recommends `git gc --prune=now --aggressive` to speed up a slow repository. What is your response?

**Q198.** On GitHub, a branch was deleted after its pull request was closed, and another was force-pushed. Which GitHub instruments apply to each, and what are their limits?

- *Follow-up:* Which of these statements can you give a CTO as documented fact and which only as an unverified observation, and what do you put in place so that the question does not arise again?

**Q199.** Your CTO wants a short, defensible statement of what Git cannot recover, so that the team stops treating the reflog as a backup. What is on that list, and what single principle produces every line of it?

- *Follow-up:* Which two losses do people expect on that list that do not belong there, and why does that matter in the first minute of an incident?

**Q200.** A team keeps experiment branches alive for months and treats the reflog on each engineer's laptop as its safety net. Explain to the CTO why that net has holes, and design what replaces it.

- *Follow-up:* You propose bundles as the backup. What does a bundle not contain, and how do you cover those gaps?


## Area 8: Remote workflows

Q201 to Q218. Fetch, pull, push, refspecs, remote-tracking branches, and forced updates.


### Remote workflows: foundational level

**Q201.** Why can a force-push be dangerous?

- *Follow-up:* An engineer wants to force-push to remove a leaked credential from the server. Does that work, and what do you do first?

**Q202.** What exactly is `origin/main`? Where is it stored, and which commands move it?

- *Follow-up:* A successful push moves `origin/main` without a fetch. Why is that correct, and what does a rejected push do to it?


### Remote workflows: working engineer level

**Q203.** Why does `--force-with-lease` exist?

- *Follow-up:* Where is the lease evaluated, in the client or on the server, and what follows from that for a branch that must never be rewritten?

**Q204.** `git status` says "Your branch is up to date with 'origin/main'". What did Git compare, and what do you run before tagging a release?

- *Follow-up:* How do you find out how old that "up to date" statement is, and why should a release script compare against `git ls-remote` and not against `origin/main`?

**Q205.** A pull stopped with "Need to specify how to reconcile divergent branches". What changed in the repository and what did not? Give the three answers and their effect on history.

- *Follow-up:* A developer has `pull.rebase=true` in the repository and still gets a refusal to fast-forward. Why, and how do you find the cause?

**Q206.** Two engineers in the same situation got `rejected (fetch first)` and `rejected (non-fast-forward)`. Explain the difference and who made each decision. How is `remote rejected` different?

- *Follow-up:* A release script pushes `main` and `release/0.1` in one command and `main` is rejected. What is on the server afterwards, and what should the script have done?

**Q207.** What do `branch.<name>.remote`, `branch.<name>.merge`, `remote.pushDefault` and `push.default` each decide? Configure a clone that pulls from `upstream` and pushes to `origin`.

- *Follow-up:* In that triangle, with `remote.pushDefault` set and `push.default` left at `simple`, what does Git 2.55 do, and how do you audit every branch's two destinations in one command?

**Q208.** Why does Git refuse a push into a checked-out branch, and what would you configure on a staging machine?

- *Follow-up:* With `updateInstead` in place, pushes to the staging machine start failing one morning. What is the most likely cause, and why is that failure the outcome you want?

**Q209.** The deploy job cannot find a commit, and the developer's push printed "Everything up-to-date". Give your first four commands and what each one proves.

- *Follow-up:* The same symptom has other causes. Name them, and say which checks separate them.


### Remote workflows: senior level

**Q210.** Take `git clone` apart into separate commands. What does `--mirror` add to `--bare`, and why does the difference matter for a backup?

- *Follow-up:* So neither is a backup on its own. What do you add to a mirror so that it can restore a branch that was overwritten or deleted at the source?

**Q211.** Explain `--force-with-lease`, one way it fails to protect a teammate's commit, and the two stronger forms.

- *Follow-up:* After the lease was defeated in that way, does your own clone still hold the overwritten commit, and how does that differ from a plain `--force` made without a fetch?

**Q212.** After a colleague's forced push, a developer ran `git pull --rebase`. It succeeded and their commit was gone. Explain the mechanism and recover the commit.

- *Follow-up:* The rebase reported success with no conflict. Which earlier line of output should have warned the developer, and what rule follows for branches that other people rewrite?

**Q213.** A forced push overwrote a commit on a self-hosted bare repository. List every place where the commit may still exist and how you would bring it back.

- *Follow-up:* Would the same fetch by full object ID work against GitHub, and what does GitHub offer in place of a server reflog?

**Q214.** A branch that was deleted a month ago is back on the server, and nobody intended it. How did it happen, and what do you change?

- *Follow-up:* You propose `fetch.prune=true` for everyone. What does a clone lose at the moment a remote-tracking ref is pruned, and for how long is recovery possible?

**Q215.** State exactly what `git fetch` writes in your repository and what it never touches. Then name three things engineers expect a plain fetch to update that it does not.

- *Follow-up:* Is `git fetch --dry-run` free of side effects, and is a stale remote-tracking ref ever more than a cosmetic problem?

**Q216.** In a CI workspace `git switch release/2.3` fails with an invalid reference although the branch exists on the server, and on a laptop a fetch rejects the update of a remote-tracking ref as a non-fast-forward. Diagnose both from what a refspec is.

- *Follow-up:* Someone pastes the refspec `+refs/heads/*:refs/heads/*` into an ordinary clone so that a fetch updates their branches. What happens at the next fetch, and where does a refspec of that shape belong?


### Remote workflows: principal level

**Q217.** You are asked to set an organization-wide policy for rewriting branches that are already published. Which protections live in each engineer's Git, which on the server, and which risk does none of them remove?

- *Follow-up:* Your server is a default bare repository. After a bad rewrite gets through, what record of the old state does the server hold, and what would you change so that it holds one?

**Q218.** A platform team proposes setting `fetch.prune=true` in every engineer's global configuration. Argue both sides from the mechanism and give your decision.

- *Follow-up:* The wrong branch was deleted on the server and your clone has already pruned it. Walk through the recovery and state its time limit.


## Area 9: GitHub

Q219 to Q261. The platform: repositories, forks, authentication, rulesets and branch protection, CODEOWNERS.


### GitHub: foundational level

**Q219.** Take ten things on a repository's page on GitHub. For each, is it Git data or a GitHub object, and how do you prove it from a terminal?

- *Follow-up:* Which things on that page are Git data that nobody created with a Git command, and which tracked files does GitHub interpret?

**Q220.** Commit identity, authentication identity, signing identity: which of them does GitHub verify on a push, and what does each one prove?

- *Follow-up:* A bad commit reached the release branch and the log names an author. How do you find out who pushed it?

**Q221.** What is a rule, mechanically? Which rules can be decided from the old ID, the new ID and the ref name alone, and which need platform data?

- *Follow-up:* A developer argues that `git push --force-with-lease` is the careful kind of force and should pass a rule that blocks force pushes. What happens, and how do you read the rejection line?

**Q222.** What are the three bypass modes, and what trace does each leave?

- *Follow-up:* Who is eligible for a ruleset's bypass list, and how would you compose the list for a production branch?

**Q223.** What does a CODEOWNERS file do when no rule refers to it?

- *Follow-up:* Then what exactly turns the request into a requirement, and what does the file never do, even with that rule?

**Q224.** In which locations is the CODEOWNERS file looked up, in which order, and from which branch is it read for a given pull request?

- *Follow-up:* A repository has the file in two of those locations and someone edits the wrong one. How do you show from a terminal which file GitHub uses, and what size constraint applies?

**Q225.** A path has two owning teams on one line of the CODEOWNERS file, and code owner review is required. Whose approval is needed?

- *Follow-up:* The change is sensitive and both teams must sign off. How do you get that, and what happens when an owner of the path is the author?


### GitHub: working engineer level

**Q226.** A member has Read through the base permission, Triage through one team and Write through another. What can she do? Which setting do you check when she can do more than intended?

- *Follow-up:* Can you add a grant that takes access away from her on one repository, and what does Write allow that people underestimate?

**Q227.** Explain a Git tag versus a GitHub Release. How can a release point at a commit nobody chose, and what prevents it?

- *Follow-up:* What do immutable releases add, and what does the textbook leave unverified about releases and tags?

**Q228.** A pull request said "Fixes #812" and the issue is still open after the merge. Give three causes and how to tell them apart.

- *Follow-up:* The team ships from release branches, so many fixes never target the default branch first. What do you change so that issues stop being left open, and what happens to the keyword after a cherry-pick?

**Q229.** What changes and what does not when a public repository is made private? Answer for Git data, forks, stars, and someone who cloned it yesterday.

- *Follow-up:* And in the other direction, private to public: what is published that people forget, and which protection is switched off?

**Q230.** A script using `gh api` returns 30 results everywhere, and once created an issue by accident. Explain both.

- *Follow-up:* The same script later fails with a 403 on a shared CI runner although its token has access. What else can a 403 mean, and what would you pin in a script that must keep working?

**Q231.** A deploy job reports "Repository not found" for a repository that exists. Walk through your diagnosis and name the possible root causes.

- *Follow-up:* Why does GitHub answer "not found" instead of "forbidden", and what does that do to your ability to tell a typo from an access problem?

**Q232.** What is the difference between `Permission denied (publickey)` and `Permission to OWNER/REPO denied to USER`? What has the server established in each case?

- *Follow-up:* For the first error, give the commands you run in order and what each one can rule out.

**Q233.** `ssh` reports that GitHub's host key has changed. What are the two explanations, how do you decide between them, and what do you never do?

- *Follow-up:* Has GitHub ever replaced a host key, and what is the correct handling on a CI runner?

**Q234.** Two rulesets and a classic rule target `main` with different numbers of required approvals. How many approvals are required, and why?

- *Follow-up:* An engineer lowers the approval count in the repository ruleset and the pull request is still blocked. What do you check, and what happens when a classic rule is converted but kept?

**Q235.** Your ruleset targets `release/*`. Is `release/2.0/hotfix` protected? How do you check without creating the branch?

- *Follow-up:* How do you target `main` so that no pattern can silently miss it, and what do you do after every change to a target?

**Q236.** What can you not practise on a Free plan, and how would you learn it anyway?

- *Follow-up:* Which of these plan statements does the chapter itself flag as uncertain?

**Q237.** Explain "last match wins" in CODEOWNERS with an example where a later, more general pattern takes a path away from a specific team.

- *Follow-up:* Someone appends a line that gives all Python files to a guild team "so the guild sees them". What happens to the existing owners, and how would you make both teams required?

**Q238.** Name the gitignore features that do not work in CODEOWNERS, and one behavior that differs although the syntax is accepted.

- *Follow-up:* Why does Git's matcher treat a nested path differently from the documented CODEOWNERS behavior, and what does that imply for testing a CODEOWNERS file locally?

**Q239.** A team is listed as owner in CODEOWNERS and is never requested for review. Give three documented causes.

- *Follow-up:* Every member of that team can already push through the organization's base permission. Why is that not enough, and how do you find the faulty line without opening a test pull request?

**Q240.** How do you find out what GitHub thinks of your CODEOWNERS file before merging a change to it?

- *Follow-up:* The errors list comes back empty and the wrong team is still requested. Why is that possible, and what do you check next?


### GitHub: senior level

**Q241.** A commit with a credential was pushed to a fork of your public repository, and the fork was deleted. What is still true, what does GitHub document, and what do you do first?

- *Follow-up:* The textbook demonstrates the mechanism with Git namespaces. What exactly does that model prove about GitHub, and when does the commit cease to exist?

**Q242.** `git describe` prints a different version than the release page. Root cause and evidence?

- *Follow-up:* You must correct this on a repository that consumers already fetch from. Which fix carries the lowest risk, and why not move the tag?

**Q243.** When do you build a GitHub App instead of using a personal token or a machine user?

- *Follow-up:* What does the App cost you compared with a deploy key for one read-only job, and is there tooling that only an App can build?

**Q244.** Describe what Git does, step by step, from "the server answers 401" to "the token is stored", naming the helper operations. What happens differently on a 403, and what is the consequence?

- *Follow-up:* How do you prove on the affected laptop which credential is being sent, and how do you fix it without damaging other stored credentials?

**Q245.** Compare a classic token, a fine-grained token, a deploy key and a GitHub App installation token by scope, lifetime, and what happens when the person who created it leaves.

- *Follow-up:* Given that comparison, when is a classic token still the only personal token that works?

**Q246.** A developer has a personal and a work GitHub account on one laptop. Design the setup, and say how you would prove from the terminal which account a given repository will use.

- *Follow-up:* Where does this design fail without an error, and why prefer SSH aliases to switching accounts in `gh`?

**Q247.** What changes for SSH users of GitHub on 14 October 2026 and 13 January 2027? Which clients and keys are affected, and which are not?

- *Follow-up:* A colleague concludes "RSA keys stop working in January". Correct that statement, and say which machines in the company you would check and how.

**Q248.** `main` was force-pushed although a ruleset blocks force pushes. List the ways that can happen and the evidence for each.

- *Follow-up:* After the incident, how do you arrange bypass so that the next one is deliberate and visible?

**Q249.** A required check stays pending forever on documentation-only pull requests. Explain the cause and design a fix that keeps the path optimization.

- *Follow-up:* Why must that final job be written to run always and to fail explicitly, instead of only depending on the other jobs?

**Q250.** Why can a squash merge be blocked by "Require signed commits" although GitHub signs the squash commit?

- *Follow-up:* What does the signed-commit rule prove, what does it cost, and why does the chapter's worked design for a production branch leave it off?

**Q251.** Compare "dismiss stale approvals" with "approval of the most recent reviewable push". Which attack does each stop?

- *Follow-up:* With stale approvals dismissed, an approving review disappears although nobody pushed to the pull request branch. Is that a defect?

**Q252.** Classic rule versus ruleset: name four behavioral differences that matter during an incident.

- *Follow-up:* You inherit a repository with classic rules and decide to convert them. What does the conversion tool do, and what does it not carry over?

**Q253.** Walk through your procedure when a developer says "everything is green and I still cannot merge".

- *Follow-up:* Turn the case around: the same developer asks how a colleague was able to merge without meeting the rules. What are the candidates?

**Q254.** Why can a pull request not remove its own required reviewer by editing CODEOWNERS?

- *Follow-up:* Then what does stop a writer from weakening the file for later pull requests, and what is the side effect of the same rule when you repair a broken CODEOWNERS?


### GitHub: principal level

**Q255.** You must move a repository to another host without loss. What does a mirror clone carry, and how do you inventory the rest?

- *Follow-up:* Which of the things left behind are still Git data that a further Git command can carry, and which settings will silently not be restored by pushing the mirror?

**Q256.** An engineer leaves and is removed from the organization the same day. The CTO asks you to confirm that nothing on GitHub still acts with that person's access. What can survive the removal, how do you find it, and how do you design so that offboarding a person also offboards their credentials?

- *Follow-up:* Removing the person broke two nightly jobs. Is that good or bad news, and what do you replace their credential with?

**Q257.** A team lead proposes giving all forty engineers Write on every repository, arguing that the CODEOWNERS file and required reviews protect `main` anyway. Evaluate the proposal for a CTO who is not a specialist, and say what you would put in place instead.

- *Follow-up:* Suppose the organization accepts your design. Which parts of it depend on the GitHub plan, and which statement in your answer rests on an inference and not on a sentence GitHub publishes?

**Q258.** Design the protection of a branch that deploys to production for a team of six. Defend each rule and name its cost.

- *Follow-up:* Name two things that ruleset does not cover, and say how you would roll it out without locking the team out.

**Q259.** A required status check is green on a pull request. What does that prove, and what does it not prove?

- *Follow-up:* Strict mode closes the stale-base gap. What does it cost on a busy branch, and what is the answer when that cost bites?

**Q260.** How do you protect the CODEOWNERS file and the workflows directory, and which three conditions make that protection real?

- *Follow-up:* With all three conditions met, name the ways a workflow change can still merge without the approval you intended.

**Q261.** When would you use the required reviewers rule instead of, or together with, CODEOWNERS?

- *Follow-up:* What makes you cautious about depending on that rule today, and where can it not be used at all?


## Area 10: Pull requests

Q262 to Q278. What a pull request is, what it displays, reviews, the three merge methods, and their effect on history.


### Pull requests: foundational level

**Q262.** What exactly does GitHub create when a pull request is opened? Which parts are Git data, and in which repository do they live?

- *Follow-up:* The head branch is deleted after the pull request closes. What still exists, where does it live, and what does that mean for a pull request that came from a fork?


### Pull requests: working engineer level

**Q263.** Why can a pull request show unexpected commits?

- *Follow-up:* Somebody force-pushes the base branch itself. What do the open pull requests against it show afterwards, and what prevents it?

**Q264.** Why does a pull request show a three-dot diff and not a two-dot diff? Construct a case in which they differ.

- *Follow-up:* Is the three-dot diff what will change on `main` when the pull request merges? If not, which object answers that question?

**Q265.** After "Squash and merge", `git branch -d` refuses to delete the local branch. Explain the refusal from the definition of "merged", and show how to verify that deleting is safe.

- *Follow-up:* In which situation does `git branch -d` delete the branch after a squash merge anyway, and what exactly does `git branch -D` destroy?

**Q266.** Your fork's `main` cannot be fast-forwarded to upstream. What happened, how do you keep the stray work, and why is `gh repo sync --force` the wrong first move?

- *Follow-up:* For the next fix in the same clone, which commit do you start the branch from, and how do you make sure its upstream branch is in the fork and not in the shared repository?

**Q267.** A contributor leaked a key in a pull request and deleted the branch. Is the commit gone?

- *Follow-up:* The contributor replies that a fresh clone does not contain the commit, so nobody can have it. How do you show that this is wrong?


### Pull requests: senior level

**Q268.** A pull request for a one-line change lists forty commits. Give three causes and the command that distinguishes them.

- *Follow-up:* You establish that the base is correct and the branch was started from the wrong place. Why does a plain `git rebase` onto the correct base not repair the pull request, and what does?

**Q269.** CI passed on the pull request and failed on `main` right after the merge. Which commit did CI test, and what closes that gap?

- *Follow-up:* An evaluation job posts a metric on every pull request. Which commit ID must it record, and why should a deployment never be gated on `refs/pull/N/merge`?

**Q270.** A reviewer approved, the author pushed another commit, and the pull request merged. Which two settings address this, and what does each cost?

- *Follow-up:* A maintainer creates the merge commit for the approved pull request in a local clone and pushes it straight to the protected branch. With either setting enabled, what happens and why?

**Q271.** What does a merge queue test that a `pull_request` workflow does not? Why can a required check stay unreported forever on a queue?

- *Follow-up:* When would you advise against a merge queue, and who can use one at all?

**Q272.** A pull request is shown as merged, yet nobody merged it and it had no approval. How is that possible?

- *Follow-up:* Besides this route, which other ways does a change reach a protected branch without the reviews the rules describe, and why does that matter before you speak to an auditor?

**Q273.** A pull request was merged and its head branch was not deleted. The author adds one commit to the same branch and opens a second pull request. Describe what the second pull request shows under each of the three merge methods, and why.

- *Follow-up:* In the squash case, why is a plain `git rebase origin/main` not the repair, and what is?

**Q274.** A pull request conflicts with `main`. One engineer proposes merging `main` into the branch, another proposes rebasing the branch onto `main`. Compare the two repairs and say what should decide between them.

- *Follow-up:* Somebody clicks "Update branch" or resolves the conflict in the web editor instead. What changed, where, and what must the author do before the next local commit?


### Pull requests: principal level

**Q275.** Compare the three merge methods for a team that requires signed commits on `main` and must show an auditor that the reviewed commit is the deployed commit.

- *Follow-up:* The team still insists on squash for a clean history. What evidence can you give the auditor, and what does the chapter leave unverified about a squash commit?

**Q276.** You are asked to pick one merge method for a 40-person ML platform team. What do you ask before answering?

- *Follow-up:* The answers are: small short-lived pull requests, no commit hygiene inside branches, no audit requirement on commit IDs. Which method do you pick, and which two practices must accompany it?

**Q277.** The bottom pull request of a two-layer stack is squash-merged and its branch is deleted. What state is the upper pull request in, what does GitHub do by itself, and would you let a release process depend on stacked pull requests?

- *Follow-up:* While both layers are still open, a review fix is committed to the lower branch. What breaks, how do you prove it, and how do you repair it?

**Q278.** A team wants auto-merge enabled on the branch that deploys to production. What is auto-merge mechanically, what does it wait for, and what must be decided before you allow it?

- *Follow-up:* How does `gh pr merge` behave on a branch that has a merge queue, and what happened to the `@dependabot merge` comment command?


## Area 11: GitHub Actions

Q279 to Q305. Workflows, events, runners, caching, artifacts, delivery and the debugging of failed runs.


### GitHub Actions: foundational level

**Q279.** Explain the difference between `run: echo "${{ github.event.pull_request.title }}"` and passing the title through `env`. When is each evaluated, and by what?

- *Follow-up:* You want to gate a step on whether a secret is set and write `if: secrets.DEPLOY_TOKEN != ''`. Why does that not work, and what does timing have to do with it?

**Q280.** How do you pass a value from a step to a later step, and from a job to a later job? What cannot be passed this way, and what do you use for it?

- *Follow-up:* A later step reads a step output and gets an empty string, with no error anywhere. What are the candidate causes?

**Q281.** What is the difference between a cache and an artifact in purpose, scope, lifetime and trust? Which one may a release job consume?

- *Follow-up:* A dependency was upgraded in the lock file, but CI keeps installing the old version. Explain the cache mechanism and the fix.


### GitHub Actions: working engineer level

**Q282.** A pull request's CI fails and the author says "it passes on my machine, same commit". What do you check first, and why can both be right?

- *Follow-up:* The commit ID in the CI log does not exist in your clone. How do you prove that your local reproduction is the same code that CI tested?

**Q283.** What does `actions/checkout` put on the runner by default? Name three tools or commands that give wrong results there, and say whether each fails or lies.

- *Follow-up:* Someone sets `fetch-tags: true` and keeps the depth at one. Does `git describe` work now, and why?

**Q284.** A job is green although `pytest | tee report.txt` had failing tests. Give the exact shell command line the runner used, and two ways to fix it.

- *Follow-up:* The same step is moved into a job that runs in a `container`. What is the default shell there, and what does that do to your reasoning?

**Q285.** A matrix has `os` with two values, `python` with three, one `exclude` and one `include`. How do you count the jobs, and how do you make one of them allowed to fail?

- *Follow-up:* Which check do you make required for that matrix, and what is uncertain about the effect of the allowed-to-fail job on it?

**Q286.** Three merges land on `main` within five minutes and the deploy workflow uses `concurrency: production`. Which runs deploy, and why?

- *Follow-up:* Someone tries to recover the lost middle deployment by adding `queue: max` together with `cancel-in-progress: true`. What happens, and what is wrong with each setting on a deployment?

**Q287.** `git describe` works on every laptop and fails in the job. Explain the state of the runner's repository and give the minimal fix.

- *Follow-up:* Why not add `fetch-depth: 0` to every checkout so that nobody meets this again?

**Q288.** What exactly does `gh run rerun` re-run, and why is that dangerous for a deploy workflow?

- *Follow-up:* How do you make the pipeline itself refuse that backwards deployment, instead of relying on people to check?

**Q289.** Your CI bill rose after a repository became private and one job started timing out. What changed?

- *Follow-up:* Finance asks for the Windows and macOS multipliers so that it can forecast how fast the included minutes are consumed. What do you answer?

**Q290.** In which order do you investigate a failed run, and why is the log not first?

- *Follow-up:* Give one concrete case in which reading the log first costs an hour that the second step of your order would have saved.

**Q291.** What can a local emulator tell you about a deployment workflow, and what can it not?

- *Follow-up:* Given those limits, how do you test an environment gate before the first real production deployment?


### GitHub Actions: senior level

**Q292.** For each of `push`, `pull_request`, `schedule` and `workflow_dispatch`: which commit does the run refer to, and from which commit is the workflow file read?

- *Follow-up:* A `pull_request` workflow is edited on a feature branch to remove a test. Does the edited file run for that pull request, and what does that imply for governance?

**Q293.** A required check stays "expected" forever on documentation-only pull requests. Explain the mechanism and design a fix that keeps the path filter's saving.

- *Follow-up:* Why must the aggregate job carry a status function and inspect the `needs` results explicitly, instead of only listing the other jobs in `needs`?

**Q294.** Why would you pin `actions/checkout` in a workflow by a 40-character commit ID, and what does the Node 24 change of September 2026 mean for a file that says `@v4`?

- *Follow-up:* With every action pinned, what else still moves under a workflow without any commit to the repository, and how do you take control of it?

**Q295.** A teammate proposes `if: always()` on the deploy job "so it is not skipped". What happens, and what do you propose?

- *Follow-up:* The deploy job is skipped because an upstream job failed, yet the pull request still shows as mergeable. How can that be, and what closes it?

**Q296.** You inherit a repository with twelve workflow files. In what order do you read one of them to predict when it runs, where, with what code, and with what permissions?

- *Follow-up:* After reading all twelve files that way, what can you still not know from the repository alone?

**Q297.** A pull request's required checks went green yesterday afternoon. Since then `main` has received several merges, nothing was pushed to the pull request, and this morning an engineer re-ran the checks and they are green again. What exactly has been proven, and what closes the gap before merging?

- *Follow-up:* A merge queue is adopted to close that gap, and the queue then stalls with every entry waiting for a check. What was forgotten?

**Q298.** When would you choose a reusable workflow over a composite action, and what does each choice do to the names of required status checks?

- *Follow-up:* Forty repositories call one central deploy workflow. How do you reference it, and what does a full re-run do if you reference it by branch name?

**Q299.** Why can a caller not pass an environment secret to a reusable workflow, and where must the secret be read?

- *Follow-up:* A secret is empty in a workflow that is called by a called workflow, and nothing fails until authentication. Explain both facts.

**Q300.** A pull request shows "waiting for status to be reported" and no run exists. Name three causes and the design that avoids all of them.

- *Follow-up:* How do you predict, before pushing, whether a path-filtered workflow will start for your pull request, and where does that prediction break down?

**Q301.** A test passes on a Mac and fails on `ubuntu-24.04` with a file-not-found error. How do you prove the cause with Git alone?

- *Follow-up:* Take the opposite accident: a commit made on Linux contains both `README.md` and `Readme.md`. What does a clone on a Mac do, and which other Git-level cause of "works on my Mac" does the chapter reproduce?


### GitHub Actions: principal level

**Q302.** An executive says: "The pipeline is green, so the tests passed and the change is safe to merge." Explain in plain terms the distinct ways a green result on GitHub Actions can be false evidence, and the organization-wide controls you would set.

- *Follow-up:* Which of those controls can one engineer with push access to a branch undo for their own pull request without touching any setting, and why?

**Q303.** A job names `environment: production`. List everything that must be true on GitHub, outside the workflow file, for that to be a real gate.

- *Follow-up:* Each of those is in place. Name the remaining ways a deployment can reach production without the approval you designed.

**Q304.** Make the case for and against self-hosted GPU runners for model evaluation, including the controls you would require.

- *Follow-up:* The fleet is built from a fixed machine image with updates disabled, and one day its jobs stop being picked up. What happened, and what bounds the wait?

**Q305.** Design the path from a merge on `main` to production for a backend service such that the bytes that were tested are the bytes that are deployed, no test or build code runs in a job that holds a deployment credential, and two production deployments never overlap. Defend each decision.

- *Follow-up:* The approver asks "what exactly am I approving?" How does the pipeline answer, and what does the approval not cover?


## Area 12: Security

Q306 to Q338. GitHub Actions security, repository security, signing, and the response to a leaked secret.


### Security: foundational level

**Q306.** A workflow has no `permissions` key. What can its token do, and what does the answer depend on?

- *Follow-up:* You add `permissions: contents: read` at the top of that workflow and a labeling job starts failing with "Resource not accessible by integration". Why, and what is the smallest correct change?

**Q307.** A colleague says "the secret is masked in the logs, so it is safe". Respond.

- *Follow-up:* Who inside your own organization can read a repository secret, and what makes that statement false for your most valuable credentials?

**Q308.** Explain why `git clone` of an untrusted repository is generally safe and why unpacking a tarball of the same repository is not. Name the files involved.

- *Follow-up:* "Cloning is safe" has had exceptions. What shape do they share, and what standing rule follows from it?


### Security: working engineer level

**Q309.** What bytes does a commit signature cover? Name three things about a commit that it does not establish.

- *Follow-up:* A signed tag object verifies as good under the name `v9.9.9`, although it was created as `v1.0.0`. How is that possible, and what must a careful verifier do?

**Q310.** Why must a token never be written into a remote URL? Name four places where it then appears, and the Git setting that refuses such URLs.

- *Follow-up:* With that setting at its strictest value, the usual command for repairing the URL fails. Why, how do you repair it, and is the incident then closed?

**Q311.** Why does a fork pull request under `pull_request` not receive secrets, and what remains exposed anyway?

- *Follow-up:* Your open-source evaluation harness needs a provider API key to show benchmark scores on contributor pull requests, and the job fails for every outside contributor. Which fix is wrong, and what are the correct designs?

**Q312.** Explain a "pwn request" without using the word. Which step completes the vulnerability?

- *Follow-up:* Since version 7, `actions/checkout` refuses that checkout under `pull_request_target`. Does that close the pattern, and what do you still look for in review?

**Q313.** What does `id-token: write` grant, and where is the access decision made?

- *Follow-up:* A trust policy that works for your older repositories does not match for a repository created this summer. What changed, and how do you diagnose it?

**Q314.** A developer says: "I committed an API key, deleted it in the next commit and pushed. We are fine." Walk through exactly where the key still exists, and what you do first.

- *Follow-up:* The developer replies: "Then I will amend the commit, force-push, and make the repository private." What does each of those change?

**Q315.** A commit on `main` shows your tech lead's avatar and she says she did not write it. What does GitHub's display prove, what evidence do you look at, and which controls would have prevented or flagged it?

- *Follow-up:* Suppose that commit had carried a "Verified" badge. What would the badge prove, and what would it still not prove?

**Q316.** Push protection is enabled for all your users. Name three kinds of leak it will not stop.

- *Follow-up:* A developer hits a push protection block, deletes the file in a new commit and pushes again. What happens, and what is the correct recovery?


### Security: senior level

**Q317.** We rotate signing keys yearly. What happens to last year's signatures, and why do validity dates not help when a key is stolen?

- *Follow-up:* After you revoke a stolen key, a year of honest commits verify as bad. Why can Git not tell them apart from the thief's, and what evidence is left for those commits?

**Q318.** An engineer pasted a token into a CI log an hour ago and has already deleted the log line. What is the state of the token, and what do you do in which order?

- *Follow-up:* Would GitHub have revoked it for you, and what determines how much damage that hour could have done?

**Q319.** How do you secure GitHub Actions?

- *Follow-up:* Which of those controls can the platform enforce for you, and which still depend on a person reading the workflow file?

**Q320.** Why does moving `${{ github.event.pull_request.title }}` from `run:` to `env:` fix an injection, when the same value still reaches the same shell?

- *Follow-up:* After that fix, name two ways the same step can become injectable again, and state the review rule you would enforce.

**Q321.** Your team pins every action to a commit. Name three things that this does not protect against.

- *Follow-up:* If pinned actions raise no Dependabot alerts, how do you keep the pins current without re-opening the window that pinning closed?

**Q322.** When is `pull_request_target` the right trigger, and what changes on 2 November 2026?

- *Follow-up:* A maintainer proposes keeping the privileged build but gating it on a `safe-to-test` label that only maintainers can add. Why is that weaker than it looks, and what design do you offer instead?

**Q323.** Why are self-hosted runners and public repositories a dangerous combination, and what makes ML projects particularly exposed?

- *Follow-up:* The repository is private. Does that remove the risk, and do environments protect the deployment secrets on that runner?

**Q324.** How do you investigate a leaked secret?

- *Follow-up:* Months later the board asks whether anyone cloned the repository with the leaked GitHub token. Can you answer, and what had to be in place before the incident?

**Q325.** What changes for a team when "Require signed commits" is enabled and the repository uses "Rebase and merge"? Explain the mechanism.

- *Follow-up:* The team switches to "Squash and merge" and every commit on `main` now shows "Verified". What does that badge tell an auditor, and what does it not?

**Q326.** Your signing key was stolen and you revoked it. Which commits still show "Verified", and how do you find the attacker's?

- *Follow-up:* Given that, was persistent verification the wrong design? State the trade-off.

**Q327.** Rank the credentials an automation could use to push to a repository by blast radius, and justify the order.

- *Follow-up:* An installation token lives for one hour. Why is "we use a GitHub App" not the end of that conversation, and what evidence does the chapter give?

**Q328.** You rewrote history to remove a customer data file and force-pushed. List every place the file may still exist and who controls each.

- *Follow-up:* What must the GitHub Support request contain, when will Support act, and what is not known about retention if it does not?

**Q329.** A CI container fails with "fatal: detected dubious ownership in repository". One engineer proposes setting `safe.directory` to `*` in the image's global configuration; another proposes setting it in the repository's own configuration so that the image stays untouched. Evaluate both proposals and say what you would do.

- *Follow-up:* Before you add a directory to `safe.directory`, what are you asserting about it, and what do you read first?


### Security: principal level

**Q330.** All commits on `main` show a good signature. Does that mean each was written by the person in its author field? What check is missing?

- *Follow-up:* You find a commit that names engineer B as author and is validly signed by engineer A's key. What can Git tell you, what can it not, and where does the investigation go next?

**Q331.** The chief executive asks: "We now require signed commits in every repository. Does that mean we know who wrote each change, and that our history is safe from a supply-chain attack?" Answer for a non-specialist, and say what you would add.

- *Follow-up:* Signatures do not survive rewrites. Which routine operations in a delivery process therefore produce commits that are unsigned, or signed by someone other than the author?

**Q332.** In the TanStack incident no credential was stolen from storage. Walk through how a fork pull request led to a publish, and name the control that would have broken each link.

- *Follow-up:* The team says: "We had `permissions: contents: read` and we publish through OIDC, so we followed best practice." Which two assumptions in that sentence did the incident disprove?

**Q333.** How would you give an LLM review agent access to pull requests from outside contributors?

- *Follow-up:* The agent has to post its review as a comment, which needs a write scope. How do you provide that without letting text in the pull request steer a job that holds it?

**Q334.** You may enable one organization-level control today. Which one, and why?

- *Follow-up:* Six months later, how do you know that control is still doing its job, and what does it not see?

**Q335.** A day after a history rewrite the secret is back on `main` and nobody force-pushed. Reconstruct what happened from the commit graph, and describe the fix for the server and for the clone.

- *Follow-up:* You told the colleague to "rebase onto the new main" and they ran `git rebase origin/main` after a fetch. What happened, and why did `git pull --rebase` behave differently when it was the clone's first contact with the rewrite?

**Q336.** When is a history rewrite the wrong response to a leaked secret? What does it cost?

- *Follow-up:* You do decide to rewrite. Which artifact of the rewrite belongs in the incident record, and why does an ML team in particular need it?

**Q337.** Attacker code is found to have run in one of your CI jobs. The team rotates the one token that appeared in the attacker's output and closes the ticket. Why is that response incomplete, and how do you scope and sequence the rotation?

- *Follow-up:* How do you make that rotation list shorter before the next incident?

**Q338.** Your organization's plan for leaked keys is: "GitHub secret scanning notifies the provider, and the provider revokes the key." As the engineer responsible, explain where that plan fails and what you would put in its place.

- *Follow-up:* In the chapter's case studies, who usually discovered the leak, and what does that imply for monitoring and for how reports reach you?


## Area 13: Open source

Q339 to Q353. Forks, upstream remotes, contribution etiquette, maintainers' tools, branching models and releases.


### Open source: foundational level

**Q339.** Describe the three repositories of the fork workflow and the remotes in your clone. After `git switch -c fix/x upstream/main` followed by `git push -u origin fix/x`, what does `git status` compare your branch with, and where does the pull request live?

- *Follow-up:* Nothing updates your fork's `main` for you. How do you bring it up to date with plain Git, and what does the guard you use protect you from?


### Open source: working engineer level

**Q340.** A colleague says the DORA research proves trunk-based development is best. What does it show, how was it measured, and what would you say instead?

- *Follow-up:* If the name of the workflow tells you nothing, what would you measure in our own repository, and can you tell me how large the improvement will be?

**Q341.** Under GitHub Flow, a customer asks for a release that contains only a security fix. What do you tell them, and what would you have needed to have in place?

- *Follow-up:* You cut the fix-only release from a new release branch. How do you later prove the same fix is on `main` when the two commits have different IDs?

**Q342.** After a squash merge, `git branch --merged` does not list your branch. Why, and how do you establish that its work is on `main`?

- *Follow-up:* In the course's run, `git branch -d` deleted that branch with only a warning although it was not merged into `main`. Why did Git not refuse?

**Q343.** Give the mechanism behind three of your team's practices: why small commits, why no force push on shared branches, why inspect before merging.

- *Follow-up:* Your team squash-merges every pull request. What does that do to the small-commits argument, and what practice follows?

**Q344.** Your fork's `main` is two commits ahead of and forty behind upstream. How did that happen, and how do you repair it without losing the two commits?

- *Follow-up:* A teammate suggests `gh repo sync --force` as the one-line repair. What does it destroy, and how do you preview it?


### Open source: senior level

**Q345.** A patch release went out without a fix that the previous patch release contained. Walk through how you find the cause from the repository alone, and what you add to the release process afterwards.

- *Follow-up:* Someone proposes moving the new release's tag to a corrected commit so customers get the fix under the same version. Why do you refuse?

**Q346.** State the two conventions for the direction of a fix. For each, give the invariant you can test and one way the test can mislead you.

- *Follow-up:* For a trunk-based team with late-cut release branches, which direction do you choose, and what does a forgotten step cost under each convention?

**Q347.** What does a merge queue guarantee that "require branches to be up to date" does not, and what does it cost?

- *Follow-up:* The queue is enabled, pull requests enter it and nothing ever merges. What is your first hypothesis and how do you fix it?

**Q348.** You maintain an open-source project and receive a 3,000-line pull request from a stranger. What do you do, and what in your repository should have prevented it?

- *Follow-up:* The contributor's checks are red because the evaluation job needs an API key. What do you tell them, and which repair do you refuse to make?

**Q349.** You rebased your pull request branch onto the new `upstream/main`, and the plain push to your fork was rejected. Meanwhile a maintainer had used "allow edits by maintainers" to push a small fix to that branch. What would a forced push do, how do you check before pushing, and how could you have updated the branch without this risk?

- *Follow-up:* Once review has started, what does updating by rebase cost the reviewer, and what does updating by merge cost you?

**Q350.** A new engineering manager wants to standardize on Git Flow for your continuously deployed hosted service because it is "the industry standard". What does Git Flow prescribe, what does its own author say about it, and what do you propose instead?

- *Follow-up:* In the chapter's demonstration, what did the Git Flow history get right that GitHub Flow with tags on `main` did not, and do you need `develop` to get it?


### Open source: principal level

**Q351.** Your company ships one hosted version today and will support two on-premises versions next year. What changes in your branching model, and on which day do you change it?

- *Follow-up:* Until that day you release patch versions as tags on `main`. What exactly does a customer receive when moving from 1.4.0 to 1.4.1, and what keeps an urgent release from being blocked?

**Q352.** In one repository a first fix was committed on `main` and cherry-picked to `release/1.4`. A second fix, on the neighbouring line of the same function, was committed on the release branch, and someone then merged `release/1.4` into `main`. The merge stopped with a conflict on a line that `main` never changed. Explain the conflict to an engineering director and state the policy you would set.

- *Follow-up:* How do you turn the chosen fix direction from a habit into something the organization enforces?

**Q353.** Design the branching and governance model for a regulated company that runs a continuously deployed hosted product and also sells an on-premises edition whose customers stay a version behind. What do you write down, and what do you tell an auditor who asks which branching model you follow?

- *Follow-up:* Which parts of that design rest only on the team's agreement, and how does each one fail without anyone noticing?


## Area 14: AI/ML workflows

Q354 to Q376. Notebooks, data and model versioning, Git LFS, reproducibility and CI for ML projects.


### AI/ML workflows: foundational level

**Q354.** Why does deleting a large file in a new commit not make a rejected push succeed?

- *Follow-up:* Suppose the commits that contain the large blob are already on the remote and other people have fetched them. What does the fix become, and what undoes it afterwards?

**Q355.** What does Git store for an LFS-tracked path, what does LFS store, and where is each on your machine and on the remote?

- *Follow-up:* How do you tell whether a working tree file currently holds the real content or the pointer, and why can `git status` be clean in both cases?

**Q356.** Why does cloning a repository not install its clean filters and hooks? What would be possible for an attacker if it did?

- *Follow-up:* Since the configuration cannot travel, where does the control live, and what is the standing of a setup script that configures every new clone?

**Q357.** Which files in an ML repository are generated and must be committed anyway, and what is the test that separates them from generated files that must not be?

- *Follow-up:* Committing the lock file is not enough on its own. How does CI honor it, and what is the equivalent rule for the container image?

**Q358.** Why is `merge=binary` a sensible attribute for a pointer file?

- *Follow-up:* Two branches each recorded a new version of the data set and you resolved the conflict in the pointer. How do you know the data in your working tree is the version the pointer names?


### AI/ML workflows: working engineer level

**Q359.** Which two Git mechanisms does LFS use, and which parts of the setup travel with a clone?

- *Follow-up:* The upload of LFS objects lives in a hook. Name two ordinary actions that bypass it, and describe the state that results on the remote.

**Q360.** A CI job fails because a model file is 132 bytes. Give the root cause, two diagnostics, and the fix for GitHub Actions.

- *Follow-up:* The checkout step already downloads LFS files and the job still sees pointers. Which other causes produce exactly this symptom?

**Q361.** Explain what a clean filter marked `required` does differently from one that is not, and why that matters for a filter that strips notebook outputs.

- *Follow-up:* A developer hits "clean filter failed" on `git add` and unsets `required` to get unblocked. What do you tell them?

**Q362.** Your team "uses nbstripout", and a notebook with outputs is on `main`. How did it get there, and what do you change?

- *Follow-up:* You strip the notebook and commit the result to `main`. Is the output gone?

**Q363.** `.gitignore` lists `*.ckpt`, and `git status` shows `model.ckpt` as modified. Explain, fix it, and say what your fix did not fix.

- *Follow-up:* After your fix the checkpoint is ignored. Name two ways it can become tracked again, and what backs up the ignore rule.

**Q364.** What does a local pre-commit hook guarantee? Name three ways a commit reaches the server without passing it, and the control for each.

- *Follow-up:* Why does the CI script check the range of commits a branch adds as well as the final tree?

**Q365.** A colleague deleted a leaked provider key in a follow-up commit and considers the incident closed. What is still true, and what is the first action?

- *Follow-up:* Why do you treat a leaked LLM provider key as more than a billing risk, and what do you arrange in advance to limit the damage?


### AI/ML workflows: senior level

**Q366.** `git status` shows a tracked binary as modified immediately after a fresh checkout. Explain the mechanism and the two possible histories that lead to it.

- *Follow-up:* Why does the prevention belong in CI or on the server and not in a local hook, and when is `git add --renormalize` not a sufficient fix?

**Q367.** A teammate gets "Smudge error ... remote missing object". What happened, who can fix it, and with which command? Why does a plain `git lfs push` not do it?

- *Follow-up:* Nobody on the team still has the object. What is the state of the repository, what is the repair, and which habits prevent a repeat?

**Q368.** What does `git lfs migrate import` do to commit IDs, to the working tree, and to the size of `.git`? What is the default scope, and what does `--everything` add?

- *Follow-up:* After an import with `--everything`, `main` is reported as both ahead of and behind `origin/main`, and nothing has been pushed. Explain the state and recover from it.

**Q369.** How does `git lfs prune` decide what it may delete, and in which case does Git's reflog not protect you?

- *Follow-up:* Design a disk-space cleanup for training machines that takes that exception into account.

**Q370.** A run in the tracker names a commit. You check it out and get a different metric. List every cause you can think of, in the order you would test them, and the evidence for each.

- *Follow-up:* The run record says the tree was dirty and a patch was saved with it. How do you reproduce the number, and what do you say if no patch was saved?

**Q371.** Compare Git LFS, DVC and a pointer file you maintain yourself. What is identical in all three, and what differs?

- *Follow-up:* What is the central weakness of the variants that ignore the real file, and where do you close it?


### AI/ML workflows: principal level

**Q372.** Your LFS bill grows although nobody adds models. Name three mechanisms that can cause it.

- *Follow-up:* You rewrite history so that the models are no longer in LFS. Does the storage figure on GitHub go down, and what does that imply for policy?

**Q373.** When is LFS the wrong tool for model weights, and what would you use?

- *Follow-up:* When the weights move out of the repository, what remains in Git, and what does that record let you do?

**Q374.** An open-source LLM project wants evaluations on pull requests from forks. Describe the collision, the dangerous workaround, and two designs you would defend.

- *Follow-up:* In the design where a trusted workflow reads the pull request's prompts as data, what counts as executing something from the pull request?

**Q375.** An agent opens forty pull requests a day in your repository. Which of your existing controls still work, which do not, and what do you add?

- *Follow-up:* How does text in an issue or a pull request title turn into a leaked CI secret, and how solid is the evidence that this happens?

**Q376.** Design the record your evaluation harness writes so that a metric shown to the board can be reproduced a year later. What goes into it, which kinds of identifier do you forbid, and what do you not trust your experiment tracker to capture for you?

- *Follow-up:* A year later the record is complete and the number still cannot be reproduced. Which dependencies outside the Git repository do you examine?


## Area 15: Production incidents

Q377 to Q393. Running an incident: stabilise, preserve, diagnose, recover, verify, communicate, prevent.


### Production incidents: foundational level

**Q377.** What are the four parts of an incident summary for a CTO, and what must never be claimed in the third?

- *Follow-up:* What makes such a summary trustworthy rather than only well formatted?


### Production incidents: working engineer level

**Q378.** A pull request shows the same changed files as yesterday and three times as many commits. What happened, and which two comparisons explain why the views differ?

- *Follow-up:* How do you repair the branch without undoing the teammate's rebase, and how do you prove that no content changed?

**Q379.** A job that runs `git describe` fails only on GitHub Actions. Name the default responsible and two remedies.

- *Follow-up:* The checkout is corrected and the job still fails, and a colleague asks for an administrator merge because the change is trivial. What do you expect to find, and what do you answer?

**Q380.** After a squash merge, with the head branch deleted on the server and pruned from your clone, `git branch -d` refuses to delete the merged branch. Why, and what do you check before `-D`?

- *Follow-up:* The branch was already removed with `-D` and held one commit that was never pushed. Where is that commit, and why do you not recreate and push the old branch?


### Production incidents: senior level

**Q381.** `main` was force-pushed ten minutes ago. Before you restore it, which two things do you check, and what does the restoring command look like?

- *Follow-up:* After the restore, what do teammates do with their clones, and what would have refused the original push?

**Q382.** A colleague says "I deleted the file with the key and pushed, so we are fine". Give the order of the response and say what the deletion did and did not do.

- *Follow-up:* After the rewrite and the forced push, no ref reaches the old commit. Is the secret gone from the server and from the clones?

**Q383.** Why is `--force-with-lease` not a defense against the situation in which a teammate has unpublished commits on a branch you rebased?

- *Follow-up:* Suppose the teammate had `pull.rebase=true`. Is a pull after a forced update then always safe for their work?

**Q384.** When is `git revert -m 1` the wrong way to take a mistaken merge out of a topic branch?

- *Follow-up:* A different incident also had a faulty merge, on shared `main` with four commits on top of it, and there neither a revert of the merge nor a rebuild was used. Why?

**Q385.** A fix is in `git log main` and not in the file. Which command shows what happened, and why did `git log -- <file>` hide the commits?

- *Follow-up:* Why could the pull request review not catch this loss, and which control would have?

**Q386.** The server keeps no reflog. Where does the timeline of a server-side branch come from, on plain Git and on GitHub?

- *Follow-up:* Outside a sandbox you cannot read a colleague's clone. How do you get that evidence, and what in the team's conduct decides whether it still exists?

**Q387.** What makes a postmortem blameless in practice, and why does that matter for the evidence?

- *Follow-up:* A postmortem arrives whose only action item reads "be more careful with force pushes". What is your verdict?

**Q388.** The deploy job refuses to run from `production` and nobody knows why; three colleagues have clones and are still working. Run the incident: what are the stages in order, what is your first action, and what must be preserved before anything is touched?

- *Follow-up:* A colleague sees "diverged" on that branch without having made commits and is advised to reset to the server. What is wrong with the advice, and what should the handbook say?


### Production incidents: principal level

**Q389.** Rank these controls by strength for "nobody force-pushes production": a handbook rule, a client alias, a ruleset, a review checklist. Justify the order.

- *Follow-up:* You chose the ruleset. Which questions must still be answered before you call the control done?

**Q390.** A production branch was rewritten by a forced push, and a teammate has since shipped one legitimate commit on top of the rewritten history. You can keep the rewritten history and re-add what was lost, or restore the old history with another forced push. How do you decide, and how do you carry out the choice?

- *Follow-up:* The person who rewrote it says the result is "the same code, fewer commits". How do you test that claim, and what did the test reveal?

**Q391.** An incident on the production branch deployed nothing and no customer was affected. The CTO asks why you rated it SEV 2 and wants the root cause in two sentences that tell a non-specialist where the fix belongs. What do you say?

- *Follow-up:* Which rule about severity applies the moment a secret is involved, and why does following it cost little?

**Q392.** A bare `git push --force` from a feature branch replaced `main`. Walk from that root cause to a control: which layers could have refused the action, which control do you choose, and what must you settle before it goes live?

- *Follow-up:* Git's default `push.default=simple` would have refused this push. Why is restoring that default in the affected clone not a sufficient control?

**Q393.** A recovery on a shared branch can itself become the second incident. Name the ways the recovery fails under time pressure, how each is noticed, and the guard against each.

- *Follow-up:* A week after a history rewrite that removed commits, the old commits are back on the server. What happened, and which instruction prevents it?


## Area 16: Debugging

Q394 to Q420. History investigation and the diagnosis method: ranges, blame, bisect, pickaxe, interrupted operations.


### Debugging: foundational level

**Q394.** What is the difference between `..` and `...`, in `git log` and in `git diff`?

- *Follow-up:* An engineer says "`A..B` is the commits between A and B". Where does the word "between" mislead, and what does an empty `A..B` prove?

**Q395.** What exactly does a row of `git blame` assert? Give three situations in which the named author did not write the logic on that line.

- *Follow-up:* The defect is a call that was removed from a line. Why can blame on the current file never name the commit that removed it, and what do you run instead?

**Q396.** A developer says "my commits are gone". Which commands do you run before you touch anything, in which order, and what does each tell you?

- *Follow-up:* Those commands describe one clone. Which of your conclusions remain unproven about the server, and which diagnostic that people treat as harmless does change something?

**Q397.** Without running `git status`, how do you tell from the `.git` directory whether a merge, a rebase, a cherry-pick, a revert or a bisect is in progress? Name the files.

- *Follow-up:* Git's own message for a leftover rebase proposes removing the `.git/rebase-merge` directory. What does deleting state files by hand do, and what do you use instead?


### Debugging: working engineer level

**Q398.** `git diff main..feature` and `git log main..feature` use the same two dots. What does each do, and which diff form matches the log form?

- *Follow-up:* For one file, the three-dot diff of a branch shows a paragraph that `main` already contains, while the two-endpoint diff shows nothing. Which of the two is wrong, and how do you show why they differ?

**Q399.** Git stores no renames. Name three commands whose output depends on rename detection, and describe a commit that defeats it.

- *Follow-up:* Two investigators run `git diff --name-status` on the same two commits and report different rename pairs. How is that possible, and what do you require in an incident report?

**Q400.** Explain `-S` and `-G` to a colleague, with one commit that the first misses and the second reports, and one case where `-G` is noise.

- *Follow-up:* `-S` named a commit as the removal of a statement, but that commit only edited the end of the line. What was wrong with the query, and in which other case does `-S` report a commit that neither added nor deleted the code?

**Q401.** You found the commit that introduced a bug. Which commands tell you which releases and which open branches contain it?

- *Follow-up:* A squash-merged copy of the faulty change also exists on another branch. Will those commands find it, and why?

**Q402.** `git push` prints "Everything up-to-date" and the commit is not on the server. Give three states that produce this and the command that separates them.

- *Follow-up:* In the worked case the commits sat on a detached HEAD inside a stopped rebase. Why was finishing the rebase and force-pushing not the chosen fix?

**Q403.** During a rebase, when does the branch ref move, and what follows from that for commits made while the rebase is stopped?

- *Follow-up:* How do you prove with commands that this is the state, rather than a stale pull request page, and how do you stop it from recurring?

**Q404.** What does `git rebase --abort` do to commits created during the stopped rebase and to uncommitted edits? How do you protect each before running it?

- *Follow-up:* Why is a bundle made with `--all` not sufficient protection in this situation, and in which order do you create the rescue ref and the bundle?

**Q405.** Compare a backup ref, a copy of the repository and a bundle: what does each preserve, and what does each miss?

- *Follow-up:* What is the practical difference between a ref under `refs/backup/` and a branch under `rescue/`, and when do you remove either?

**Q406.** What does it mean to verify a fix? Give the four checks and an example where the first passes and the third fails.

- *Follow-up:* Why do you write down the prediction before running the check, and what is done only after verification?


### Debugging: senior level

**Q407.** A pull request shows a change that the base branch already contains. Explain how that can happen and how to make it disappear without closing the pull request.

- *Follow-up:* Why is three dots still the right diff for a review tab despite this side effect, and what would a two-endpoint comparison show for a pull request whose branch is behind its base?

**Q408.** Your team introduces a formatter. What do you commit, what does each developer configure, and what breaks if someone checks out a commit from before the formatter?

- *Follow-up:* A teammate reports that the ignore file has no effect for the formatter commit, and there is no error message. What happened, and how do you prevent it?

**Q409.** A regression appeared somewhere in 4,000 commits. How many tests does a bisection need, what does it assume about the history, and how do you check that assumption when the result looks wrong?

- *Follow-up:* The 4,000 commits arrived through merge commits, and commits inside the merged branches are not required to build. How do you change the bisection, and what does its answer then name?

**Q410.** Bisect reports a merge commit as the first bad commit, and both parents are good. What does that tell you, and what do you look at next?

- *Follow-up:* For a suspect commit inside a merged branch, how do you find the merge that first carried it onto `main`, and what complicates that when merges are nested?

**Q411.** `git log --since=2026-09-10` omitted commits from the morning of that day. Explain the cause and state how you would write the query in an incident report.

- *Follow-up:* The query now carries full timestamps, and a commit you know was written on the 10th is still missing. Give two explanations that have nothing to do with the date syntax.

**Q412.** A push is rejected, `git pull` says "Already up to date", and the push is rejected again. Explain the mechanism and the lowest-risk fix.

- *Follow-up:* Why did you reject both `git push --force` and a one-off `git pull origin <branch>` as the fix?

**Q413.** Rank these fixes by risk and justify the order: `git revert`, `git reset --hard` followed by a force push, `git reset --keep`, `git cherry-pick`, a new branch.

- *Follow-up:* When a forced push really is the correct fix, which form do you use, and why is the bare lease not enough?

**Q414.** A pull request shows 400 changed files for a two-line change. List four mechanisms and the Git command that tests each one locally.

- *Follow-up:* The oversized pull request still carries an approval given when it had two files. What is the status of that approval, and which layer decides it?

**Q415.** You are handed a repository that must not be altered at all while you diagnose it. Which of the usual diagnostic commands are not strictly read-only, what can each change or destroy, and what do you use instead?

- *Follow-up:* When is the full diagnostic method the wrong tool, and when do you stop diagnosing altogether?


### Debugging: principal level

**Q416.** Design the test script for `git bisect run` for a nightly evaluation whose score has run-to-run noise and whose build is broken in some commits. Which exit codes do you use, and why?

- *Follow-up:* The bisection ends with a list of candidate commits instead of one. Why, and what do you do next?

**Q417.** After a squash merge, how do you find out who wrote a given function and why? What would you change in the team's process to make that question cheaper?

- *Follow-up:* A director wants to rank engineers by the commit counts of `git shortlog -sn`. What does a squash-merge workflow do to that number, and what else is wrong with the plan?

**Q418.** After an incident, an executive asks for a report, taken from Git, of who wrote the faulty line and when. Which parts of what `git blame` and `git log` print are facts read from objects, which are inferences, and what would you refuse to conclude from them?

- *Follow-up:* The executive accepts that and asks what, then, you can prove about the cause. What do you answer, and with which evidence?

**Q419.** You are asked to automate regression hunting: when the nightly evaluation fails, a CI job runs `git bisect run` between the last passing commit and the failing one. In which ways can this job return a confident wrong answer or no answer at all, and which controls do you require before anyone trusts it?

- *Follow-up:* The job names one commit, and a re-run of the same job names a different one. What does that tell you, and what do you change?

**Q420.** `main` on GitHub moved backwards overnight. Which evidence exists on your machine, which on GitHub, how long does each last, and which of them identifies the account that pushed?

- *Follow-up:* The Activity view gives you the old commit ID, but no clone has that commit. Can you restore it from GitHub, and how certain is that?


## Area 17: Architecture

Q421 to Q461. Decisions that outlive a project: monorepos, submodules, large-repository performance, hooks, new storage formats.


### Architecture: foundational level

**Q421.** What exactly does a superproject store about a submodule, and what does it not store? Where is each piece?

- *Follow-up:* Why does the submodule's repository live under the superproject's `.git/modules` and not inside the submodule's own directory, and what follows from the URL being copied into local configuration?

**Q422.** "Google uses a monorepo, so Git can handle ours." What is wrong with that sentence?

- *Follow-up:* What would you look at to judge whether stock Git can carry our repository, and how do you sort a performance complaint?

**Q423.** Explain a cone-mode sparse checkout in terms of the index. What is on disk, in the index, in `HEAD`?

- *Follow-up:* You asked for one subdirectory, and a file from its parent directory appeared as well. Why, and can that be switched off?


### Architecture: working engineer level

**Q424.** Which hooks run for `git commit`, in which order, and which does `--no-verify` skip? Which commit-creating commands run none of the checking hooks?

- *Follow-up:* A `commit-msg` hook enforces a subject convention, and merges start stopping half-way. Why, and what is the fix?

**Q425.** What will Git 3.0 change, for which repositories, and what is the official statement about its date? Which parts of the schedule come from secondary sources?

- *Follow-up:* What does the Git project commit to that lets an organization test and stage these changes instead of meeting them on release day?

**Q426.** Your Git reports `rust: disabled`. What does that tell you, and what does the BreakingChanges document promise to platforms without Rust?

- *Follow-up:* Your company builds Git from source for an internal platform that has no Rust toolchain. What is your plan, and what do you verify before you trust any date in it?

**Q427.** A colleague says "our submodule tracks the library's `main`". Correct the statement and explain what `submodule.<name>.branch` does.

- *Follow-up:* Someone proposes running `git submodule update --remote` in the CI job so that the service always builds against the newest library. What is wrong with that, and what do you do instead?

**Q428.** Why is HEAD detached in a submodule after `git submodule update`? When does that lose work, and how do you get it back?

- *Follow-up:* Your rescue relies on a safety net inside the submodule. Which operations described for submodules remove that net or bypass it?

**Q429.** After `git pull`, `git status` shows a modified submodule that you never touched. Explain the state of the three relevant commit IDs, the risk, and the fix.

- *Follow-up:* Your prevention is `submodule.recurse`. Why can it not be shipped with the repository, and which commands does it not cover?

**Q430.** A search finds nothing in a colleague's clone although the code exists. Mechanism, and the command that searches everything?

- *Follow-up:* The colleague then creates a new file in a directory outside the cone and `git add` refuses it. Explain the refusal and the state after each way forward.

**Q431.** What happens to untracked and to ignored files when a cone is narrowed?

- *Follow-up:* The team keeps local `.env` files and downloaded evaluation sets under ignored paths. How do you make narrowing a cone safe for them?

**Q432.** How do you tag and describe releases of twenty projects in one repository?

- *Follow-up:* The tag for a release of one project points at a commit that only changed documentation for another project. Is that a mistake?

**Q433.** Describe a fetch as a conversation. Where do `--depth` and `--filter` enter it?

- *Follow-up:* A fetch is slow. How does this model tell you in which of three places the time is going?

**Q434.** A CI job reports the wrong version and an empty changelog, with exit status 0. Diagnose it.

- *Follow-up:* After `git fetch --unshallow` the version is right, but the job still cannot see other branches. Why, and what else is affected for as long as a clone stays shallow?


### Architecture: senior level

**Q435.** Name the four configuration keys that choose the 3.0 defaults ahead of time. Which of them would you set on a developer laptop today, and which not?

- *Follow-up:* On one laptop a clone of a SHA-1 repository whose refs are stored in files comes out with reftable. Why is that legitimate, what breaks, and how do you put it back?

**Q436.** What does `safe.bareRepository=explicit` refuse, what does it still allow, and which attack is it aimed at?

- *Follow-up:* How would you introduce `explicit` across an organization without stopping the Git servers and the backup jobs?

**Q437.** Compare `git history reword` with `git rebase -i` and `reword`: working tree, hooks, which branches move, merges, conflicts.

- *Follow-up:* An engineer ran it on a commit that had already been pushed, and three branches now report that they are ahead and behind. How do you recover, and what would have prevented it?

**Q438.** Why does a server need `git replay`, and what does `--ref-action=print` give it?

- *Follow-up:* A hosting service wants to refuse a replay whose result fails a policy check. Describe the sequence of steps, and say what the service must not assume about a quiet command.

**Q439.** How do you find out whether a behavior change in a new Git release affects your team? Which documents do you read, in which order?

- *Follow-up:* Release notes and BreakingChanges can word the same change differently, and a notes file can exist for a version that was never released. How do you handle each case?

**Q440.** A teammate's pull fails with `not our ref`. Give the root cause, the three commands that prove it, the fix, and the setting that prevents it.

- *Follow-up:* Where does that setting still let a bad pointer through, and why is `--recurse-submodules=on-demand` not the answer for every team?

**Q441.** Why does Git refuse `file` URLs for submodules by default, and why is a recursive clone of an untrusted repository a security decision?

- *Follow-up:* How does the same reasoning apply to a GitHub Actions workflow that builds pull requests from forks of a repository with submodules?

**Q442.** Two branches moved the same gitlink and the merge conflicts. Why can Git not resolve it, when does it resolve it by itself, and what does a correct resolution look like?

- *Follow-up:* You resolve the conflict by merging inside the submodule yourself. What has to be pushed, in which order, and what happens to a teammate if the order is wrong?

**Q443.** Explain how `git subtree split` can reproduce the original upstream commit IDs. What would break that?

- *Follow-up:* A teammate squash-merged the pull request that carried a subtree update. What was lost, how do you check, and what rule do you set?

**Q444.** What does the sparse index change, why only in cone mode, and what makes a command slower with it?

- *Follow-up:* Git prints a hint that the sparse index is expanding and suggests that your working tree has content outside the cone. Do you accept that diagnosis?

**Q445.** What does `scalar clone` set up, which parts live outside the repository, and how do you remove each?

- *Follow-up:* An engineer reports a background process and scheduler entries that they cannot explain. How do you establish that Scalar is the cause?

**Q446.** Our CI computes affected projects with `git diff main..HEAD`. What is wrong, and why does the fix fail in a shallow clone?

- *Follow-up:* State the rule for which CI jobs may be shallow, and name another kind of job that breaks for the same reason.

**Q447.** `git status` is slow in one repository and `git log -- path` in another. How do you find out what each command is doing, without a stopwatch?

- *Follow-up:* The changed-path statistics line appears in one clone and not in another clone of the same repository. Name the conditions under which Git does not use the commit-graph.

**Q448.** Compare shallow, blobless and treeless clones: what each holds, what each answers correctly, and what each costs later.

- *Follow-up:* You asked for a blobless clone and the result is as large as a full one. What are the two causes, and what misleading state is left behind?

**Q449.** A partial clone fails with `could not fetch ... from promisor remote`. What are the two possible causes, and how do you make a laptop independent of the server for a week?

- *Follow-up:* Why is a partial clone not a backup, and what does `git fsck` say about the objects it lacks?

**Q450.** How do you ship weekly updates to a site with no network route to the server? What goes wrong if one shipment is lost?

- *Follow-up:* Besides objects and refs, what does a bundle not carry, and how can a bundle also reduce the load of ordinary clones for sites that do have a network?


### Architecture: principal level

**Q451.** Why are hooks not cloned? Describe three ways to share them and the security cost of each.

- *Follow-up:* A repository reaches you as a tar archive that includes its `.git` directory. What is the risk, and what is the safe way to inspect it?

**Q452.** The CTO asks for a guarantee that no commit with a private key reaches `main`. Which layers do you propose, and what does each one fail to catch?

- *Follow-up:* The team answers that the pre-commit framework already solves this, because its configuration is versioned and its tools are pinned. Is that a control?

**Q453.** A team wants SHA-256 for a new service that is hosted on GitHub. What do you tell them, and how would an existing repository be converted later?

- *Follow-up:* One of the two new formats can be adopted and reverted in place and the other cannot. Which is which, and why is that difference fundamental and not a gap in the tooling?

**Q454.** Submodule, subtree, package manager: decide for (a) an internal protocol-definition repository used by eight services, (b) a 300-line utility copied from an open-source project, (c) a tokenizer library published on a package index.

- *Follow-up:* For case (a), the service teams keep asking for one change that updates the definitions and their service together. What does that request tell you about the design?

**Q455.** You are asked to introduce submodules for a team of thirty. Which four configuration settings and which CI check do you require, and why?

- *Follow-up:* Assume all thirty engineers have those four settings. Which submodule failures can still happen?

**Q456.** A shared schema library is consumed by five services. One architect wants each service to pin the library as a submodule; another wants the library and the five services in one repository. Both positions are defensible. Compare what each records and what each costs, and say which facts would decide it.

- *Follow-up:* The decision is one repository. What does the migration itself cost in Git terms, and what must exist before the first team moves in?

**Q457.** We are considering one repository for all services. Name three costs we would stop paying and three we would start paying. Which are Git's and which are tooling's?

- *Follow-up:* Under which conditions would you advise against the move however much is spent on tooling?

**Q458.** A required check has been pending for two days on a documentation pull request. Cause, and the design that avoids it?

- *Follow-up:* In your design the single workflow computes the affected projects itself. Which failure inside that step would let a pull request merge untested, and how do you close it?

**Q459.** A team asks for a directory that only they can read. What do you answer?

- *Follow-up:* They accept a separate repository, but its code must still be built together with the monorepo. Which ways of bringing it in keep the read restriction, and what do they cost in CI?

**Q460.** To onboard engineers to a large monorepo you can standardize on `scalar clone`, or on a scripted blobless and sparse clone that the team builds by hand. Both are defensible. Compare them and say how you would decide.

- *Follow-up:* Whichever you choose, the clone is partial. What new failure do engineers meet when the server is unreachable, and how do you prepare for it?

**Q461.** A consultant recommends `git gc --aggressive` every night. What do you answer?

- *Follow-up:* Suppose measurement does show that the packs are far larger than the content explains. What would justify a one-off full repack with non-default settings, and how would you run it?


## Area 18: CTO interview

Q462 to Q482. Cross-cutting questions on judgment, trade-offs and communication. They assume every other area.


### CTO interview: foundational level

**Q462.** "The merge is blocked." Give one root cause in each of the three layers (Git, GitHub, GitHub Actions) and say why the layer matters for the fix.

- *Follow-up:* Someone reports "CI is red". Give one possible cause in each layer, and say what decides between them.

**Q463.** What is the difference between a symptom and a hypothesis? Restate "the commit is broken" as a symptom.

- *Follow-up:* Why does the method want the symptom recorded before any command is run?

**Q464.** A CTO does not ask "which command fixes this". Which four questions does a CTO ask about a repository problem, and which of them can a command answer?

- *Follow-up:* Give the four answers, one sentence each, for the case "the fix was committed and did not ship".


### CTO interview: working engineer level

**Q465.** In the root-cause framework every step up to and including naming the root cause is read-only. Why is that rule there, and what is the one kind of change that is allowed before the fix?

- *Follow-up:* What does the "preserve" phase add, and why does time pressure never justify skipping it?

**Q466.** Why is one hypothesis "a belief, not an analysis"? How many do you write before testing, and what makes a test a good one?

- *Follow-up:* A developer says "my commits are gone". Give three hypotheses, each with the command whose output would separate it from the others.

**Q467.** Every explanation in this course ends in the same seven-line form. What are the seven lines, and how does "root cause" differ from "mechanism"?

- *Follow-up:* Why does the fix line ask for the lowest-risk fix and not for "the correct fix"?

**Q468.** What does it mean to "understand the state" of a repository before forming a hypothesis? Name the places you must be able to describe and a command for each.

- *Follow-up:* Which of these places does a colleague's clone not share with yours, and why does that matter in an investigation?

**Q469.** Ten minutes into an incident the CTO asks for a status, and you have no root cause yet. What do you say?

- *Follow-up:* What is the first instruction to the team in an incident on a shared branch, and why is it not a Git command?


### CTO interview: senior level

**Q470.** A colleague's answer to every Git problem is "delete the folder and clone again". What does a fresh clone restore, and what does it destroy?

- *Follow-up:* When is a fresh clone the correct step, and what must come before it?

**Q471.** A branch and a tag are both names. Why does this course tell you to gate a deployment on a commit ID or an image digest, and not on either name?

- *Follow-up:* Two commits have different IDs and an empty diff between them. How do you prove that they hold the same content, and what happens to the approval?

**Q472.** After a squash merge, `git branch -d` refuses to delete the branch, a second pull request from the same branch lists the old commits again and conflicts, and "is my branch merged?" gets different answers. State the single mechanism behind all three.

- *Follow-up:* The branch was reused and now carries new commits on top of the squashed ones. What is the lowest-risk repair, and how do you test "merged" correctly from now on?

**Q473.** "A remote-tracking branch is a record of your last fetch, not a view of the server." Describe two failures that follow from forgetting this: one in which the record is too old, and one in which it is newer than what you have looked at.

- *Follow-up:* Why does Git not contact the server for `git status`, and what should a release script compare against instead?

**Q474.** During an investigation, where can the real clock change what Git shows you? Give two cases and say what you do about each.

- *Follow-up:* A postmortem timeline gives a time for each event. What must each time carry?

**Q475.** A wrong version string, a "no merge base" error in a changed-files step, and an empty changelog, each of them only in CI. What is the common root cause, and what rule do you give the teams?

- *Follow-up:* How do you confirm from inside a job that the clone is shallow, and how do you make a release job fail instead of shipping a fallback version?

**Q476.** A senior engineer with ten years of Git says that a fixed diagnosis ritual is for juniors. Respond.

- *Follow-up:* Which parts of the picture can the fixed set of local commands never show, and where do you get them?


### CTO interview: principal level

**Q477.** "Never force-push" and "force-push your own branch with a lease" are both defensible team rules. Where do you draw the line, and on which layer do you enforce each side of it?

- *Follow-up:* A pull request branch is personal, but it carries a reviewer's comments and an approval. What does a forced push do there?

**Q478.** Git's safety nets have limits. For the reflog, `ORIG_HEAD` and `--force-with-lease`, state what each protects and one situation in which it fails.

- *Follow-up:* Which single habit covers the weaknesses of all three, and what does that habit not preserve?

**Q479.** One team wants a linear history through squash merges; another wants merge commits. State what each choice costs in terms of mechanisms, so that the decision is an informed one.

- *Follow-up:* After a merge was reverted, what is the correct sequence to bring the repaired feature back, and where do you write that down?

**Q480.** Several incidents in this course trace back to a default. Name three, give the layer of each, and say whether you would change the default or add a control around it.

- *Follow-up:* What is the general test for whether to change a default for everyone or to add a check at the place where it bites?

**Q481.** You enabled a control after an incident. How do you know that it works, and what else do you check about it?

- *Follow-up:* The postmortem lists ten actions. How do you decide which of them matter?

**Q482.** A postmortem draft names the engineer who ran the command and ends with one action: "engineers will take more care with force pushes". What do you send back, and why?

- *Follow-up:* The team objects that a ruleset on the production branch will block a legitimate emergency fix. How do you answer?
