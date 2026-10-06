# Senior-engineer interview guide: Git and GitHub

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Every technical statement in this guide comes from the textbook, and each worked answer names the section that demonstrates it. Nothing here was captured from GitHub; platform behavior is described as the textbook describes it, from the documentation.

## 1. What this guide is for

You already have the material: thirty chapters, the labs, and a [question bank](cto-question-bank.md) with [model answers](cto-question-bank-answers.md). This guide is about the last step, which is saying it aloud to someone who will not help you. It covers:

1. how senior and staff interviews on Git and GitHub are run, and what is being assessed (section 2);
2. the structure of a strong answer (section 3);
3. twenty answers worked at three quality levels, with commentary (section 4);
4. scenario and system-design prompts, with what a strong response covers (section 5);
5. a rubric for grading yourself (section 6);
6. a four-week plan (section 7).

The rules of an oral session are in the [interview-mode protocol](interview-mode-protocol.md). Read it once before section 4.

One warning. The weak and adequate answers in section 4 are not strawmen. They are what capable engineers say, and each contains something true. Read them for the exact point at which they stop.

## 2. How these interviews are run, and what is assessed

There is no standard "Git interview". At senior and staff level the subject appears inside other conversations, in four recurring forms. Prepare for the form, not for a list.

| Form | What it sounds like | What is being assessed |
|---|---|---|
| The mechanism question | "What exactly is a branch?" "Why does a rebase change commit IDs?" | Whether your model of Git is the real one: objects, refs, HEAD, the index, reachability. A candidate who has only used Git describes commands. A candidate who understands it describes state |
| The incident walk-through | "`main` moved backwards overnight. Go." | Method under pressure: read-only first, evidence, more than one hypothesis, the lowest-risk fix, verification. The interviewer plays the repository and answers only what you ask |
| The design discussion | "Design branching and protection for this team." "Review this workflow file." | Judgment: whether you can state what each choice costs, name the layer that enforces it, and say when you would choose otherwise |
| The explanation to a non-specialist | "Tell me, as the CTO, why deleting the file did not remove the key." | Whether you can keep the mechanism exact while dropping the jargon, and whether you lead with impact and end with a control |

Across all four, an experienced interviewer is listening for six things. They are the six dimensions on which this course grades every oral answer.

- **Correctness.** Every claim is true, and the layer is right. "GitHub rejected the push" and "Git rejected the push" are different statements with different fixes. In Chapter 12 the textbook shows that a non-fast-forward rejection is decided by your own client, before the server is asked to change anything.
- **Depth.** You explain what happens inside `.git`, and why the tool is designed that way. "Why Git does this" is a line of every root-cause box in the textbook because the design reason tells you where the behavior ends.
- **Terminology.** Commit ID, the index, working tree, ref, remote-tracking branch, upstream, merge base, fast-forward, reflog, reachable. Loose words are not a matter of style: "the branch on GitHub" and "`origin/main`" are two different refs in two different repositories, and several incidents in this course come from confusing them.
- **Reasoning.** You get from state to symptom by a causal chain, and you can say which observation would prove you wrong.
- **Practical understanding.** You name the commands, in an order that is safe: look, preserve, preview, change, verify.
- **Production awareness.** You know who else is affected, what the fix can destroy, and which control would have refused the action.

Three behaviors lose an interview faster than a wrong fact.

1. **Reaching for a command before describing the state.** "I would run `git reset --hard`" as a first sentence tells the interviewer how you behave in an incident. Chapter 29 opens with the reason: most damage is done after the incident, by the first repair attempt.
2. **Certainty without evidence.** "It must be a force push." The stronger sentence is "three mechanisms produce this; the branch reflog separates them".
3. **Blaming the tool.** "Git is weird about that." Each surprising behavior in the textbook has a mechanism and a design reason. An answer that ends in "weird" has not reached either.

And three behaviors mark a senior answer even when a detail is missing: saying which layer acted; saying what you would check before you believe your own explanation; and saying "I do not know that; here is how I would find out", followed by a command that would in fact find out.

> **Git, not GitHub.** Interviewers often test the boundary deliberately. A pull request, a review, a ruleset, a fork, a release and a workflow run are GitHub objects. Commits, trees, blobs, tags, refs, the index and reflogs are Git. A squash merge button is GitHub creating a Git commit on its servers. When a question mixes the two, separate them in your first sentence ([Chapter 1](../textbook/ch01-fundamentals.md), section 1.5).

## 3. The structure of a strong answer

A strong answer has five parts, in this order. Not every question needs all five at the same length, but none may contradict another, and the first two are never optional.

| Part | The question it answers | Typical opening |
|---|---|---|
| **State** | What do the working tree, the index, HEAD, the refs and the server hold? | "A branch is a ref: a name that holds one commit ID." |
| **Mechanism** | What does Git, GitHub or GitHub Actions do with that state, and why is it designed so? | "A commit names its parent by ID, so a new parent means a new ID for every commit after it." |
| **Evidence** | Which read-only command shows it? What would the output look like if I were wrong? | "`git reflog show main` has a reset entry if the branch was moved." |
| **Fix** | What is the lowest-risk change that repairs the state, and what does it touch? | "Anchor the old tip with a branch first; nothing is rewritten." |
| **Prevention** | Which habit, setting or rule stops a silent recurrence, and on which layer? | "A ruleset that blocks force pushes; a client setting is weaker." |

This is the seven-line root-cause box of Chapter 1, section 1.10, arranged for speech. "Observed behavior" and "Git state" become State; "Mechanism" and "Why Git does this" become Mechanism; "Root cause" is the sentence that joins State to Mechanism; "Correct fix" and "Prevention" keep their names. Evidence is added because an interviewer cannot see your terminal.

**How the five parts scale.** For a definition question ("What is HEAD?"), State and Mechanism are the answer, Evidence is one command, and Fix and Prevention shrink to one sentence about the mistake the definition prevents. For an incident question, State and Evidence come first and take most of the time, because you do not yet know the mechanism. For a design question, Prevention is the answer, and the other four are the justification: which state the control protects, which mechanism it interrupts, how you will know it works.

**Length.** Two minutes at most. The model answers in the bank are held to 180 words so that each can be said, unhurried, within that time. If you need longer, you are narrating commands.

**Three rules for the first sentence.**

1. Answer the question that was asked. "Why does a rebase change commit IDs?" starts with "because", not with a definition of rebase.
2. Name the object or ref that the answer turns on. "A reset moves a ref and deletes no object."
3. Name the layer if two are possible. "That is a GitHub Actions default, not Git."

**One rule for the last sentence.** End on the control or the limit, not on a summary. "What it cannot recover is work that was never staged, because no object was written" is a better ending than "so the reflog is very useful".

**An example in the five parts.** Question: "`git status` says the branch is up to date with `origin/main`, and a colleague pushed ten minutes ago. Is Git wrong?"

> *State.* No. `origin/main` is a ref in my repository that records where the server's `main` was at my last fetch. *Mechanism.* `git status` compares two local refs and opens no connection, because every command except the transfer commands works offline. *Evidence.* `git ls-remote origin main` asks the server without changing anything; `git fetch` then moves `origin/main`, and status reports the branch as behind. *Fix.* None is needed; the statement was true about my copy. *Prevention.* Fetch before any decision that depends on the server, such as tagging or cutting a hotfix branch, and let scripts compare against `git ls-remote`, never against a remote-tracking ref of unknown age.

That is the content of [Chapter 12](../textbook/ch12-remote-operations.md), section 12.4, in about a hundred words.

## 4. Twenty worked answers at three quality levels

Each answer is given three times. **Weak** is what the interviewer most often hears. **Adequate** would pass a mid-level interview: it is correct and incomplete. **Strong** has the five parts. The commentary names what moved the answer from one level to the next, and the textbook section that backs the strong version. Cover the strong answer, give your own aloud, then compare.

### 4.1 What exactly is a branch?

**Weak.** "A branch is a separate copy of the code where you can work without affecting main."

**Adequate.** "A branch is a pointer to a commit. Creating one is cheap because nothing is copied. When you commit, the pointer moves forward."

**Strong.** "A branch is a ref: a name under `refs/heads/` that holds the ID of one commit, its tip. That is all it holds. There is no list of its commits, no record of where it started, no owner and no creation date; the history of a branch is whatever the tip reaches through parent links. Creating a branch writes one ref and no object. A commit made while HEAD names the branch moves the ref to the new commit. I can show it: after `git branch topic`, `git for-each-ref refs/heads` prints the same commit ID for both branches. I read refs with Git and not from the file system, because refs can be packed, and in a reftable repository there is no file per branch. The practical consequence is that deleting a branch deletes a name, and that Git cannot tell me which branch another was created from."

**Commentary.** The weak answer is the model that makes people afraid of branches and surprised that deleting one loses nothing at once. The adequate answer has the mechanism and stops before its consequences. The strong answer states what a branch does not record, which is what explains real questions: why "which commits belong to this branch" has no stored answer, and why the base of a pull request is GitHub's record and not Git's. Reference: [Chapter 7](../textbook/ch07-branches.md), sections 7.2 and 7.9.

### 4.2 What is HEAD, and how does it differ from a branch and from a remote-tracking branch?

**Weak.** "HEAD is the latest commit. A branch is your local version and `origin/main` is the branch on GitHub."

**Adequate.** "HEAD points at the branch you have checked out. A branch points at a commit. `origin/main` is your local copy of the remote's branch and is updated when you fetch."

**Strong.** "All three are refs in my own repository; they differ in what they hold and in what moves them. A branch holds one commit ID, and a commit made on it moves it. HEAD records where I am: normally it is a symbolic ref that holds the name of a branch, not a commit, and in the detached form it holds a commit ID directly. A commit does not rewrite a symbolic HEAD; it moves the branch that HEAD names. A remote-tracking branch such as `origin/main` lives under `refs/remotes/` and records where a branch in another repository was at my last fetch or push. My commits never move it. `git symbolic-ref HEAD` and `git for-each-ref` show all of this. So `main` on the server and `main` in my clone are two refs that share a name, and 'up to date with `origin/main`' describes my copy of the remote, never the remote."

**Commentary.** "HEAD is the latest commit" is the most common wrong model, and the textbook refutes it with a transcript: the content of `.git/HEAD` is the same before and after a commit, while the branch ref changes. The adequate answer is right and does not say what moves each ref, which is the part an incident turns on. The strong answer ends on the consequence that causes real failures. Reference: [Chapter 2](../textbook/ch02-mental-model.md), section 2.8; [Chapter 7](../textbook/ch07-branches.md), sections 7.2, 7.3 and 7.10.

### 4.3 How does Git store data? What are a blob, a tree and a commit?

**Weak.** "Git stores the changes between versions, so it only keeps the diffs. A commit is a set of changes."

**Adequate.** "Git stores snapshots, not diffs. A blob is a file, a tree is a directory and a commit points to a tree and to its parent. Everything is identified by a hash."

**Strong.** "Git is a content-addressed object database plus names. A blob is the bytes of one file and nothing else: no name, no mode. A tree is one directory listing: entries of mode, name and object ID, each naming a blob or another tree. A commit names exactly one top-level tree, zero or more parents, an author and a committer with times, and a message. It contains no diff and no branch name. Each object's ID is computed from its content, so the ID is also its checksum, and an object is never changed: a change files new objects and moves a name. Changing one file therefore creates a new blob, a new tree for each directory above it, and a new commit. Deltas exist only inside packfiles as a storage choice between similar objects; they change no ID, and every commit still reads back as a complete snapshot. `git cat-file -p` shows each object."

**Commentary.** The weak answer describes how Git displays history, not how it stores it; every later topic (why a rebase changes IDs, why a deleted file is still in history) fails on that model. The adequate answer has the right nouns. The strong answer says what each object deliberately leaves out and places deltas correctly, which is the point where confident candidates most often go wrong. Reference: [Chapter 3](../textbook/ch03-git-internals.md), sections 3.3, 3.4 and 3.7.

### 4.4 Why does a rebase change commit IDs?

**Weak.** "Because rebase rewrites history, so the commits get new hashes."

**Adequate.** "A commit's ID is a hash of its content, including its parent. Rebase gives the commits a new parent, so the IDs change, and so do the IDs of all later commits."

**Strong.** "Because a commit ID is the hash of the commit object, and a rebase does not move commits: it writes new ones. The replayed commit differs from the original in three inputs. The parent, which is the purpose of the operation. The tree, because the new snapshot also contains what the new base added. And the committer line, which records who created this object and when. The author line and the message are carried over. Each commit names its parent by ID, so a new ID for one commit forces a new ID for every commit after it; commits before the first rewritten one keep theirs. `git cat-file -p` on an original and its copy shows the fields, and `git range-diff` pairs old with new. The consequence is outside Git: anything that recorded an old ID, such as a review approval, a CI status or a training run, now refers to a commit that is on no branch. So I do not rebase commits that others have, or that something has recorded."

**Commentary.** The weak answer restates the question. The adequate answer is correct and treats the commit as a diff with a parent; it misses that the tree usually changes and that the committer changes always. The strong answer names the three inputs, bounds the effect ("from the first rewritten commit onward"), and ends on the production consequence. Reference: [Chapter 9](../textbook/ch09-rebase.md), sections 9.3 and 9.6; [Chapter 6](../textbook/ch06-commits.md), section 6.4.

### 4.5 Why does `git reset --hard` not necessarily delete commits permanently?

**Weak.** "It does delete them, but Git keeps a backup for 30 days in the reflog."

**Adequate.** "Reset only moves the branch pointer. The commits are still in the repository and you can find them with `git reflog` and reset back."

**Strong.** "Because a reset moves a ref and deletes no object. `git reset --hard <commit>` makes the current branch name another commit and rewrites the index and the tracked files to match. The commits that left the branch are still in the object database, and they still have names: the reset writes the previous tip to `ORIG_HEAD` and appends an entry to the reflog of HEAD and to the reflog of the branch. Git does not delete an object that a reflog entry names. So `git reflog` shows the old tip, and I anchor it with `git branch rescue/<what> <id>` before doing anything else. By default the entry for a commit the branch no longer reaches is kept for 30 days. What a hard reset does destroy is uncommitted work that was never staged: no object was ever written for it, so neither the reflog nor `git fsck` can find it. That is why `git reset --keep` is the safer way to move a branch back."

**Commentary.** "Backup" is the word that marks the weak answer: nothing is copied, and the candidate cannot say what is and is not covered. The adequate answer would recover the commits and lose the unstaged edit. The strong answer draws the line between what has an object and what does not, which is the difference between a recoverable incident and an unrecoverable one. Reference: [Chapter 11](../textbook/ch11-reset-revert-restore.md), sections 11.4 to 11.6; [Chapter 13](../textbook/ch13-recovery.md), section 13.2.

### 4.6 What is reachability, why can a commit become unreachable, and what does garbage collection do about it?

**Weak.** "Unreachable commits are commits that were deleted. Garbage collection cleans them up."

**Adequate.** "A commit is reachable if a branch or tag leads to it. After a reset or a rebase the old commits are unreachable, and `git gc` removes them after a while."

**Strong.** "An object is reachable if I can arrive at it from a starting point by following the IDs stored inside objects. The starting points are the refs, HEAD, the index and every reflog entry. A commit becomes unreachable when the last name that leads to it moves or is removed: a reset, an amend, a rebase, a deleted branch, a dropped stash, commits left on a detached HEAD. Usually a reflog entry still reaches it, so it becomes truly unreachable only when that entry expires: by default after 90 days, or 30 for an entry the current tip no longer reaches. Unreachable is not deleted. `git fsck` still finds the object, and pointing a ref at it makes it reachable again. Deletion happens when a collection finds an unreachable object older than the grace period, two weeks by default. One current detail: since Git 2.54, automatic maintenance uses the geometric strategy and does not run `git gc`, so unreachable objects can stay longer than those numbers suggest."

**Commentary.** The weak answer reverses cause and effect: a name stopped pointing, and deletion comes later, if at all. The adequate answer leaves out the reflog as a starting point, which is the whole recovery window. The strong answer gives the chain (ref, reflog entry, grace period, collection) and one version-sensitive fact stated with its version. Do not add numbers you are unsure of; "weeks, by default" is a better answer than a wrong figure. Reference: [Chapter 3](../textbook/ch03-git-internals.md), section 3.8; [Chapter 13](../textbook/ch13-recovery.md), sections 13.2 and 13.4; [Chapter 26](../textbook/ch26-performance.md), section 26.3.

### 4.7 What happens during a three-way merge?

**Weak.** "Git compares the two branches and combines their changes. If the same line was changed in both, you get a conflict."

**Adequate.** "Git finds the common ancestor and compares each branch with it. Changes made on only one side are taken automatically; changes to the same lines on both sides conflict. The result is a merge commit with two parents."

**Strong.** "When both branches have commits the other lacks, Git merges three snapshots: the tree HEAD points to, called ours; the tree of the commit I named, theirs; and the tree of their merge base. It does not replay commits. For each path it compares three blob IDs. A path changed on one side only is taken from that side without reading the content. An identical change on both sides is taken once. Only a path that differs in all three goes to a line-level merge, where hunks that do not touch are both applied. If everything resolves, Git writes one commit with two parents and moves the current branch. If a region was changed differently on both sides, it stops: `MERGE_HEAD` is set, the index holds stages 1, 2 and 3 for the path, and the file gets conflict markers. `git ls-files -u` shows the stages. The merged tree is a snapshot that neither author wrote or tested, so CI has to run on the merge result."

**Commentary.** The weak answer has no third input, and without the merge base Git cannot tell a line that one side added from a line the other side deleted. The adequate answer is the standard one. The strong answer adds three things an incident needs: the merge reads snapshots and not commits, most paths never have their content read, and the conflict state lives in the index as stages. It ends on the consequence for testing. Reference: [Chapter 8](../textbook/ch08-merge.md), sections 8.4 and 8.8.

### 4.8 Why can Git merge two files incorrectly from a human perspective?

**Weak.** "Sometimes Git's merge algorithm makes mistakes in complicated cases, so you have to check the result."

**Adequate.** "Git merges text line by line. If two changes do not overlap, it combines them even when they are logically incompatible, for example when one branch renames a function and the other adds a call to the old name. That is why you need CI."

**Strong.** "Because a merge is a computation on text, not on meaning. Git compares three snapshots, and a clean merge certifies exactly one property: no two changed regions overlapped. It says nothing about whether the result builds or passes its tests. In the textbook's example two green branches changed different files: one renamed a function, the other added a caller of the old name. By the three-way rule each path was changed on one side only and was taken as it is. No file-level merge ran, so there was nothing for Git to compare, and the merge commit was red. The dependency lives in the language's import system, not in the text of any one file. Git is correct by its rules. The control is on another layer: run CI on the merge result, require the branch to be up to date with `main`, or use a merge queue. And when I audit a hand-resolved merge afterwards, `git show --remerge-diff` shows what the resolver changed."

**Commentary.** "Mistakes" marks the weak answer: none of the documented failures needs a bug, and an answer that blames luck offers no control. The adequate answer is right. The strong answer says what a clean merge proves (one property), shows that in the worst case no content was even read, and puts the fix on the correct layer, which is GitHub and CI, not Git. Reference: [Chapter 8](../textbook/ch08-merge.md), sections 8.15 and 8.16; [Chapter 18](../textbook/ch18-branch-protection.md), section 18.8.

### 4.9 Why does `--force-with-lease` exist, and how can it still fail?

**Weak.** "It is the safe version of force push. It checks that nobody else has pushed, so you should always use it."

**Adequate.** "A plain force push overwrites whatever is on the server. `--force-with-lease` only overwrites if the remote branch is where you expect it to be, so you do not destroy a teammate's commits. It can be fooled if you fetched in the meantime."

**Strong.** "It exists because `git push --force` checks nothing: the server's ref is set to my commit, and every commit there that is not in my history is dropped, including commits I never fetched. Rewriting my own published branch after a rebase is still legitimate, and it can never be a fast-forward. `--force-with-lease` is a compare-and-swap for that case: update the branch only if it still has the value I last read, and that value is my remote-tracking ref. The comparison is made by my client, not by the server. That is its weakness. Any fetch, including one that a tool runs in the background, moves the remote-tracking ref, so the lease passes although I never looked at the new commits. The defences are `--force-if-includes`, which also requires that I have integrated the remote tip, or an explicit expected value: `--force-with-lease=<branch>:<commit>`. And a branch that must never be rewritten needs a server rule, because the lease is a precaution of the pusher."

**Commentary.** The weak answer attributes the check to the server and concludes "always safe"; the textbook's root-cause box shows the lease overwriting a teammate's commit after a fetch. The adequate answer knows the failure and not its mechanism. The strong answer says where the comparison runs and against what, which makes both the failure and the two remedies follow without memorisation. Reference: [Chapter 12](../textbook/ch12-remote-operations.md), section 12.8.

### 4.10 Revert or reset: what is the difference, and which do you use on a shared branch?

**Weak.** "Reset deletes commits and revert undoes them. Revert is the safe one."

**Adequate.** "Reset moves the branch back, so the commits are no longer on it; that rewrites history. Revert creates a new commit that undoes an earlier one. On a shared branch you revert, because others already have the commits."

**Strong.** "`git reset` moves the current branch ref to another commit, and its mode decides whether the index and the working tree are rewritten. The commits after the target leave the branch. `git revert` adds one commit whose change is the inverse of the named commit; the branch only moves forward. So reset is for commits that exist nowhere else, and revert is the correction for shared history: everyone's next pull is a fast-forward, and nobody has to repair a clone. I decide with evidence, not memory: after a fetch, `git branch -r --contains <commit>` tells me whether a remote-tracking branch has it. Two edges matter. A revert is a three-way merge against the current files, so it can conflict. And reverting a merge removes the content and leaves the merge in the graph, so merging the repaired branch later brings only its new commits unless I revert the revert first. I write that procedure into the message of the revert commit."

**Commentary.** "Deletes" is wrong, since a reset deletes no object, and "safe" is not a mechanism. The adequate answer is the standard one. The strong answer adds the test that decides between the two, and the reverted-merge trap, which is the follow-up a CTO asks next because it has cost teams a release. Reference: [Chapter 11](../textbook/ch11-reset-revert-restore.md), sections 11.4, 11.8 and 11.9.

### 4.11 Why does cherry-pick create a new commit?

**Weak.** "Because it copies the commit onto your branch, and the copy gets a new hash."

**Adequate.** "A commit's ID depends on its parent. The cherry-picked commit has a different parent, so it is a new commit with the same changes."

**Strong.** "Because a commit object is never modified, and its ID is a function of its content. A cherry-pick does not move or reuse the picked commit. It recomputes the change that commit made, as a three-way merge whose base is the picked commit's parent, and records the result on my branch. That result has a different tree, which is my branch's files plus the change; a different parent, the tip I picked onto; and a different committer line. Only the author, the author date and the message are carried over. Different content gives a different ID. Git stores no link from the copy to the original, so `git branch --contains` with the original's ID does not list my branch, and that is why `-x` exists: it writes the original ID into the message. To find out whether a fix was ported I compare changes, with `git cherry` or `git range-diff`, and I remember that a pick which applies cleanly can still break the build."

**Commentary.** The weak answer restates the observation. The adequate answer names the parent and not the tree, and misses that the operation is a merge, which is why a cherry-pick can conflict. The strong answer draws the consequence a release manager cares about: ancestry tests cannot see a backport. Reference: [Chapter 10](../textbook/ch10-cherry-pick.md), sections 10.1, 10.3 and 10.9.

### 4.12 Why can a pull request show unexpected commits?

**Weak.** "Probably someone pushed to the branch, or GitHub has not refreshed. Rebasing usually fixes it."

**Adequate.** "The pull request shows every commit on the head branch that is not on the base. If the branch was created from the wrong place or contains a merge from another branch, those commits appear too."

**Strong.** "Because the page is a computation, not a record of intent. A pull request stores two names, a base and a head, and GitHub lists the commits reachable from the head and not from the base: `git log base..head`. Unexpected commits mean that the head reaches commits the base does not, or that the base is not where the work started. The cause I check first is a head branch reused after a squash merge. The squash put the content on `main` in a single-parent commit and recorded no ancestry, so the merge base never moved and the old commits are listed again. Others are a wrong base, another branch merged into the head, and a rewritten base. I reproduce it locally after a fetch with `git log --oneline origin/main..HEAD` and `git merge-base`, and for a reused branch I transplant the new commits with `git rebase --onto`. Prevention: delete the head branch after merging, and read the commit list before opening the pull request."

**Commentary.** The weak answer has two guesses and a command, in that order. The adequate answer knows the range. The strong answer separates the layers (GitHub displays, Git's reachability decides), names the most frequent cause with its mechanism, and reproduces the page locally, which is what turns a platform mystery into a Git question. Reference: [Chapter 17](../textbook/ch17-pull-requests.md), sections 17.3 and 17.12; [Chapter 30](../textbook/ch30-incident-response.md), section 30.10.

### 4.13 What is the difference between `..` and `...`?

**Weak.** "Two dots is a range from one commit to another, and three dots is a bigger range that includes both sides."

**Adequate.** "In `git log`, `A..B` shows commits on B that are not on A, and `A...B` shows commits on either that are not on both. In `git diff`, three dots compares against the common ancestor."

**Strong.** "The dots mean different things in `git log` and in `git diff`. In `git log` they select commits by reachability: `A..B` is the commits reachable from B and not from A; `A...B` is the symmetric difference, the commits reachable from either tip and not from both. In `git diff` nothing is a range, because a diff compares exactly two snapshots. `git diff A..B` is the same as `git diff A B`: the trees of the two tips. `git diff A...B` compares the merge base of A and B with B. So the meanings cross: the diff that matches the log range `A..B` is the three-dot diff. The practical trap is `git diff main feature`, which shows what `main` gained after the fork as deletions that the feature never made. For review I use three dots, and in scripts the explicit `git diff --merge-base`."

**Commentary.** The weak answer treats history as a line with intervals; a range is a set defined by reachability. The adequate answer is correct and does not say that two-dot `diff` is not a range at all, which is the case that produces a misleading review. The strong answer states the crossing and the trap. Reference: [Chapter 14A](../textbook/ch14a-history-investigation.md), sections 14A.2 and 14A.8.

### 4.14 How do you recover a deleted branch?

**Weak.** "Use `git reflog`, find the commit and check it out."

**Adequate.** "The commits still exist after the branch is deleted. Find the tip's ID in `git reflog` and recreate the branch with `git branch <name> <id>`."

**Strong.** "A branch is a ref, so recovery means finding the commit ID of its tip and recreating the ref; the commits never stopped existing. I look in this order. The terminal scrollback, because `git branch -D` prints the ID it deleted. Then the HEAD reflog, not the branch's own, because the reflog of a branch is deleted with the branch: the entry before I last switched away from it is the last commit HEAD had there. Then `git fsck --no-reflogs`, which lists the dangling tips that no ref reaches. I recreate it with `git branch <name> <id>`, verify with `git log --oneline main..<name>`, and push it if it matters. The limits: the recreated branch starts a new reflog, and a teammate's branch that I only fetched and then pruned was never in my HEAD reflog, so only `git fsck` can find it, and only until a collection removes the objects. On GitHub, a closed pull request offers to restore its deleted head branch."

**Commentary.** The weak answer would work on a good day and leaves you on a detached HEAD. The adequate answer says "the reflog" without saying which, and the branch's own log is gone. The strong answer gives an ordered search, a verification, and the case where the reflog cannot help. Reference: [Chapter 13](../textbook/ch13-recovery.md), sections 13.4 and 13.8; [Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.8.

### 4.15 How do you investigate a leaked secret?

**Weak.** "Remove the file, rewrite the history with a filter tool and force-push so that the secret is gone."

**Adequate.** "Rotate the secret first, because it has to be considered compromised. Then find where it is in history, remove it, and add secret scanning so that it does not happen again."

**Strong.** "The order matters more than the tools. First contain: revoke or rotate the credential at its issuer. Until then it works for whoever copied it, and revocation is the only step that reaches clones, forks and caches. Second assess, in writing: what the secret can reach; the first commit that contains it, from `git log --all -S`; which refs contain it, from `git branch -a --contains` and `git tag --contains`; who could read it, including forks and CI logs; and whether it was used, which only the issuer's logs can say. Third eradicate: remove it from current code, and rewrite history only if the data stays harmful after rotation. Deleting the file changes the next snapshot and no earlier one. A rewrite on GitHub leaves unreachable commits, pull request refs, forks and clones, and a stale clone that merges and pushes brings the secret back. Then tell collaborators exactly what to do with their clones, and prevent recurrence with push protection, scanning in CI and short-lived credentials."

**Commentary.** The weak answer starts with the repository, where the damage does not happen. The adequate answer has the right first step and then goes vague. The strong answer orders the work by what reduces risk, lists the facts the assessment must produce, and states the limits of a rewrite on the platform, which is where "we cleaned it" turns out to be untrue. Reference: [Chapter 21B](../textbook/ch21b-repository-security-incident-response.md), sections 21B.10, 21B.11, 21B.14 and 21B.18.

### 4.16 How do you secure GitHub Actions?

**Weak.** "Store credentials in secrets, pin your actions, keep dependencies updated and turn on Dependabot."

**Adequate.** "Set the token permissions to read-only, pin third-party actions to commit IDs, do not use `pull_request_target` with untrusted code, and avoid putting user input directly into scripts."

**Strong.** "I ask one question of every job: whose code runs in it, whose text does it process, and what can it reach. A job is a program started by GitHub with a credential for the repository. Then five controls, one for each part of that model. The token: a read-only `permissions` block at the top of every workflow, single write scopes on the one job that needs them. Triggers: build fork code under `pull_request`, which gets a read-only token and no secrets, and never execute pull request code under `pull_request_target`, `workflow_run` or `issue_comment`. Text: no `${{ }}` expression inside `run:`, because it is substituted into the script before the shell starts; pass the value through `env:`. Third-party code: pin each action to a full commit ID, because a tag can be moved. Credentials: each secret in one step behind an environment, and OIDC with an exact subject where possible. Masking is not a boundary. Then make it hold: organization policies, code-owner review of `.github/workflows/`, and a workflow scanner as a required check."

**Commentary.** The weak answer is a list of settings with no model, so it cannot say what each one stops. The adequate answer has four correct controls. The strong answer derives the controls from one question, explains the injection mechanism in a clause, and distinguishes what the platform can enforce from what a reviewer must read. Label the layer: none of this is Git. Reference: [Chapter 21A](../textbook/ch21a-actions-security.md), sections 21A.2 to 21A.9, 21A.16 and 21A.19.

### 4.17 The tests pass on your laptop and fail in CI "on the same commit". Why?

**Weak.** "CI has a different environment: other versions, other operating system. It works on my machine."

**Adequate.** "On a pull request, CI does not test your branch alone; it tests your branch merged with the base. If `main` changed something your code depends on, the merge result can fail while your branch passes."

**Strong.** "First I check whether it is the same commit. For a `pull_request` event, GitHub Actions sets the ref to the pull request's merge ref, and the checkout step uses it. So the runner's HEAD is a test merge of my head into the current base: a commit that does not exist in my clone. If the base gained a commit that changes behavior my code relies on, that merge is red while my branch is green. That is an Actions default, not a Git fault, and it asks the right question: is the result of merging safe. The evidence is the commit the job checked out, compared with `git rev-parse HEAD` in my clone: two different IDs. I reproduce it with `git fetch origin` and a local merge of `origin/main`. The fix is to update the branch and repair the code. If the commit is the same, the next hypotheses are the checkout defaults, one commit and no tags, and then the environment."

**Commentary.** The weak answer names the last hypothesis first and offers no test. The adequate answer has the mechanism. The strong answer starts by questioning the premise in the report ("the same commit"), names the layer, and orders the remaining hypotheses by how cheaply each is tested. Reference: [Chapter 20A](../textbook/ch20a-actions-fundamentals.md), section 20A.8; [Chapter 30](../textbook/ch30-incident-response.md), section 30.11.

### 4.18 `.env` is listed in `.gitignore`, yet it keeps appearing in commits. Why?

**Weak.** "The `.gitignore` pattern must be wrong, or the Git cache needs to be cleared."

**Adequate.** "`.gitignore` only applies to untracked files. The file was committed before the rule was added, so Git keeps tracking it. You need `git rm --cached .env` and a commit."

**Strong.** "Because the file is tracked, and tracking wins. Ignore patterns are consulted only for paths that have no index entry: when `git status` lists untracked files and when `git add` walks a directory. A tracked path is compared with its index entry and no pattern is checked. The file was added before the rule existed. I confirm it: `git ls-files .env` prints the path, and `git check-ignore -v .env` prints nothing for a tracked file. The fix is `git rm --cached .env`, a commit, and the pattern stays. Three consequences belong in the same answer. The commit records a deletion, so teammates lose their copy of the file at the next pull. Every earlier commit still contains the file, so any credential in it is leaked and must be rotated. And `.gitignore` is not a security control. For prevention, write the ignore file before the first `git add .`, and let CI fail when `git ls-files -ci --exclude-standard` prints anything."

**Commentary.** "Clear the cache" is a ritual without a mechanism. The adequate answer is correct and stops at the fix. The strong answer explains when patterns are consulted, proves the diagnosis with two commands, and then states what the fix does to other people and to history, which is the part that becomes a security incident. Reference: [Chapter 4](../textbook/ch04-working-tree.md), sections 4.5 and 4.6.

### 4.19 After a squash merge, is your branch merged?

**Weak.** "Yes, the pull request says merged. If `git branch -d` complains, use `-D`."

**Adequate.** "The content is on `main`, but Git does not see the branch as merged, because a squash creates a new commit instead of linking to yours. So `-d` refuses and you have to force the deletion."

**Strong.** "It depends on which meaning of 'merged' is asked for, and I say so. In Git, merged means reachable: the branch tip is an ancestor of `main`. A squash merge creates one commit with a single parent that carries the content and records no link to my commits, so the tip is not an ancestor. `git branch --merged` and `git merge-base --is-ancestor` answer no, and so does `git branch -d` once the remote-tracking branch is pruned (before that it compares with the upstream and deletes with a warning); they are right. On GitHub the pull request is merged, which is a platform record. The question I care about is whether anything would be lost, and that is a test of content, not ancestry: an empty `git diff main <branch>` right after the merge, or a merge-tree comparison once `main` has moved on. Only then `git branch -D`. The same mechanism explains why a reused branch lists its old commits in the next pull request. So the rule is one squash per branch: delete it, on the server and locally, and start again from `main`."

**Commentary.** The weak answer forces a deletion on the word of a web page. The adequate answer has the mechanism and still deletes without verifying. The strong answer separates three meanings of one word, picks the one that protects work, and verifies before a destructive command. Reference: [Chapter 17](../textbook/ch17-pull-requests.md), section 17.9; [Chapter 27](../textbook/ch27-open-source-team-workflows.md), section 27.3.

### 4.20 An evaluation run recorded its commit ID. You check out that commit and get a different metric. Why?

**Weak.** "Machine learning is not deterministic; it is probably the random seed or the GPU."

**Adequate.** "The commit only identifies the code. The data, the model weights, the dependencies and the configuration also have to be the same, so those need to be versioned as well."

**Strong.** "Before I suspect randomness I ask what the commit ID proves. `git rev-parse HEAD` names the last commit; it says nothing about the index or the working tree. If the run started from a tree with a modified tracked file, Python imported the file on disk, and the tracker recorded an ID for code that did not produce the number. A commit is a snapshot that was taken, and uncommitted work is in no snapshot. So the first evidence is whether the tracker stored `git status` and a diff with the run. If the patch was saved, I apply it to the commit and rerun. If it was not, the result cannot be reproduced, and I say so. Beyond the code, the commit does not pin data, weights, dependency versions or the container, which is why lock files, image digests and data versions are recorded with it. The control is in the launcher: refuse a tracked run from a dirty tree, or record status and diff, and treat untracked files the same way."

**Commentary.** The weak answer may be true and is untestable as stated. The adequate answer lists what else must be versioned and assumes that the code, at least, is pinned by the ID. The strong answer questions that assumption first, because it is the one a Git interview is probing, and it ends with a control that a launcher can enforce. Reference: [Chapter 28](../textbook/ch28-ai-ml-workflows.md), sections 28.7 and 28.8.

## 5. Scenario and system-design prompts

These prompts have no single right answer. They are graded on whether you state the context you are assuming, what each choice costs, which layer enforces it, and when you would choose otherwise. Take ten minutes for each, aloud, with paper. Then compare with "what a strong response covers". A response that lists controls without their costs is an adequate one at best.

### 5.1 Branching and governance for a described company

**Prompt.** "We are forty engineers. One hosted product deploys from `main` several times a day. We also ship an on-premises edition with two supported versions. An ML team trains models from the same repository. Design our branching model and the rules around it."

**What a strong response covers.**

- **The two questions first**: how many versions are live at once, and how often is each released. Here the answer is three rows of the context table at once: a continuously deployed service, several supported versions, and model releases that must be reproducible ([Chapter 27](../textbook/ch27-open-source-team-workflows.md), section 27.14).
- **The model**: one long-lived `main` with short-lived branches for the service; a `release/x.y` branch per supported on-premises version, because each supported version needs a line that can receive fixes. Add a branch only when you can name the version or the audit requirement that needs it.
- **The direction of fixes**, decided once and tested: either fixes land on the release branch and are merged upward, or they land on `main` and are picked down. Whichever it is, the check is a release gate, not a habit, because nothing in Git propagates a fix between branches (section 27.10).
- **Rules on the server**: a ruleset on `main` and on the release branches that blocks force pushes and deletions, requires a pull request with review, and requires status checks; a tag ruleset so that release tags cannot be moved or deleted ([Chapter 18](../textbook/ch18-branch-protection.md), sections 18.11, 18.12 and 18.18).
- **The merge method and its cost.** Squash gives one commit per pull request and discards ancestry, so head branches are deleted after merging and never reused; merge commits keep the reviewed IDs. Say which you choose for `main` and why the release branches may differ.
- **Ownership**: CODEOWNERS for the deployment workflow and the release configuration, with the limit that the file requests reviews and enforces nothing until a rule requires code-owner review ([Chapter 19](../textbook/ch19-codeowners.md)).
- **Reproducible model releases**: an annotated tag on the exact commit, with data and model versions recorded beside it, and deployment by commit ID or image digest, not by a name ([Chapter 28](../textbook/ch28-ai-ml-workflows.md), section 28.7).
- **What you leave out, and why**: for example no signed-commit rule yet, with the reason. And how you would roll the rules out: create them disabled or in evaluate mode where the plan allows, test with one pull request, then activate.

**Follow-ups to expect.** Who can bypass, and how is a bypass recorded? What happens to an emergency fix at night? Which of these rules depend on the GitHub plan?

### 5.2 A CI security review

**Prompt.** "Here is a workflow that labels and tests pull requests from forks. It triggers on `pull_request_target`, checks out the pull request's head, installs dependencies, runs the tests, and comments the result. It uses three third-party actions by version tag. Review it."

**What a strong response covers.**

- **The model before the findings**: a run is a program with a credential, and its safety depends on who controls its code and its inputs ([Chapter 21A](../textbook/ch21a-actions-security.md), section 21A.2).
- **The primary finding**: `pull_request_target` runs with the base repository's token and secrets. Checking out the fork's head does not by itself execute anything; the step that installs dependencies or runs the tests executes the outsider's code inside that privileged job. That step completes the vulnerability (section 21A.5).
- **The repair by separation**: build and test under `pull_request`, which gives a fork a read-only token and no secrets; do the privileged part (the comment, the label) in a job that never runs the fork's code.
- **Token scope**: a top-level read-only `permissions` block, and the single write scope on the one job that comments (section 21A.3).
- **Expressions**: any `${{ }}` inside `run:` that carries a title, a branch name or a body is script injection; pass it through `env:` (section 21A.6).
- **Third-party actions**: a tag can be moved; pin to a full commit ID with a version comment, and know what pinning does not cover (section 21A.7).
- **What is not a boundary**: log masking, and the approval gate for first-time contributors.
- **Process**: code-owner review for `.github/workflows/`, a workflow scanner as a required check, organization policies for what they can enforce, and the review checklist of section 21A.19.
- **The date**: the textbook records a platform change to this trigger's default rule that is enforced from 2 November 2026 for public repositories. State version-sensitive facts with their date and say you would re-verify them.

**Follow-ups to expect.** Which of your findings can an organization policy enforce, and which need a human reading the file? What changes if the runner is self-hosted?

### 5.3 Incident walk-through: the production branch moved backwards

**Prompt.** "It is Friday evening. The deploy job refuses to run. Someone says `production` 'looks different'. You have the room. Go." The interviewer answers only with what your chosen command would print.

**What a strong response covers.**

- **Stabilise first, with a sentence and not a command**: nobody pushes to or resets `production` until told otherwise. The first message goes out before the cause is known ([Chapter 30](../textbook/ch30-incident-response.md), section 30.2).
- **Preserve**: fetch, and give the current and the previous state names with backup refs. Ask colleagues not to prune, collect garbage or clone again, because a server-side branch has no reflog of its own on plain Git and its history is the sum of what the clones remember.
- **Evidence, read-only**: `git reflog show origin/production` for the two values at fetch time; `git ls-remote` for what the server holds now; the deployment tag for what was last shipped; a tree diff between the old and the new tip. On GitHub, the Activity view and Rule Insights say which account moved the ref and whether a rule evaluated it ([Chapter 29](../textbook/ch29-production-troubleshooting.md), section 29.8).
- **At least three hypotheses** before a conclusion: a forced push after a rebase, a branch deleted and recreated, a reset pushed with force. Name the command that separates them.
- **The lowest-risk recovery**: restore the recorded history, carry over any legitimate newer commit, and if a forced push is the repair, state the expected old value explicitly with `--force-with-lease=<ref>:<expected>`.
- **Verification in every copy**: the deployed commit is again an ancestor of the branch; the release job's own check passes; IDs compared on the server and in the known clones. Say what is not yet verified.
- **Severity and communication**: assign the level on what could have happened in the window; give the four-part summary (section 30.15).
- **Prevention as a control**: a ruleset on the production branch, with an owner and a date, and a way to know it works.

### 5.4 Incident walk-through: a pull request suddenly shows five hundred changed files

**Prompt.** "A two-line change. The pull request shows five hundred files. The author says they changed nothing else." A strong response does not touch the branch until it has listed mechanisms: another branch merged into the head, a wrong base, a head reused after a squash merge, a two-dot comparison read as a review diff. It tests each locally (`git log --merges main..head`, `git merge-base`, `git log --oneline origin/main..HEAD`), names the layer (Git decides reachability; GitHub displays it), rebuilds the head without the foreign merge, and says what the forced push to the head branch will do to the existing review. Reference: Chapter 30, section 30.10; Chapter 17, section 17.12.

### 5.5 Explaining to an executive

**Prompt.** "You have ninety seconds with the chief executive. Explain why the leaked key is still a problem after the engineer deleted the file and pushed." A strong response has no Git vocabulary in its first two sentences and no inaccuracy anywhere: every saved version of the project is kept permanently, so removing the file from today's version leaves it in yesterday's; and every copy of the repository that was downloaded has it. Then the action in order: the key was revoked at its issuer at a stated time; here is what it could reach; here is whether the issuer's logs show use; here is the control that would have blocked the push. It ends with what is not yet known and when the next update comes. Reference: Chapter 21B, sections 21B.10 and 21B.14; Chapter 30, section 30.15.

## 6. Self-assessment rubric

Grade a recorded answer, not a remembered one. Score each dimension 0 to 2, as in the [protocol](interview-mode-protocol.md), section 5; the descriptions below add the signs to listen for. Twelve points per answer.

| Dimension | Signs of 0 | Signs of 1 | Signs of 2 |
|---|---|---|---|
| **Correctness** | A wrong mechanism ("reset deletes commits"); the wrong layer; a number you made up | Right in outline, with one claim you could not defend if asked "how do you know" | Every claim agrees with the textbook; uncertain facts are marked as uncertain; the layer is named |
| **Depth** | You described what you type | You explained what Git does | You explained it in terms of objects, refs, HEAD and the index, and gave the design reason |
| **Terminology** | "The code", "the history", "SHA", "the remote branch" for three different things | Mostly exact; a loose word or two | Exact throughout: commit ID, the index, working tree, remote-tracking branch, upstream, merge base, reachable |
| **Reasoning** | A conclusion without a chain | State, then mechanism, then symptom | The chain, plus what you would observe if you were wrong, or which other hypotheses you ruled out |
| **Practical understanding** | No command, or a command that changes state as the first step | The right commands | The right commands in a safe order: read, preserve, preview, change, verify |
| **Production awareness** | The answer ends when your own repository is repaired | You mention teammates, the server or CI | You state what the fix can destroy, who must act afterwards, and the control that prevents recurrence, on its layer |

**The correctness gate.** If correctness is 0, the answer is 0. Fluent vocabulary around a wrong mechanism is the most dangerous kind of answer, because it is believed.

**Reading your totals.**

| Average over a session | What it means | What to do |
|---|---|---|
| 10 to 12 | Senior standard for these areas | Move to principal-level questions and to the prompts of section 5 |
| 7 to 9 | Correct and thin | Find the dimension that is 1 in most answers. It is usually reasoning (no evidence) or production awareness (no control) |
| 4 to 6 | The model has gaps | Go back to the chapter's root-cause boxes and its "What can go wrong" table, then redo the labs for that area |
| Below 4, or any 0 on correctness for a destructive operation | Not yet safe to lead an incident in this area | Restudy the chapter from the start. Do not practise interview answers on a wrong model |

**Four checks that take one minute each.** Did the first sentence answer the question? Did you name the layer where two were possible? Did you name one command that would show you were right? Did you end on a limit or a control? An answer with four "yes" is rarely below 9.

## 7. A four-week preparation plan

The plan assumes the textbook and labs are done and about seven hours a week. It uses the bank by area, the [protocol](interview-mode-protocol.md) for every session, and the weak-area tracker of the [roadmap](../curriculum/Git%20and%20GitHub%20mastery%20roadmap.md), section 12. Sessions are oral and recorded. Do not read model answers ahead of a session.

| Week | Areas of the bank | Daily work (about an hour) | End-of-week session |
|---|---|---|---|
| **1. The model** | 1 Fundamentals, 2 Git internals, 3 Branching, 8 Remote workflows | Ten questions a day from one area, foundational and working-engineer levels first. For every answer below 9 of 15, reread the cited section and its transcript, then draw the state on paper | Area interview on areas 1 to 3 and 8. Worked answers 4.1 to 4.3 and 4.9 from memory |
| **2. Changing history, and getting it back** | 4 Merge, 5 Rebase, 6 Undo, 7 Recovery, 16 Debugging | Ten questions a day at working-engineer and senior levels. Two of the generated incidents under [`incidents/`](../incidents/README.md) as debugging rounds, attempted before reading their sections | Area interview on areas 4 to 7, at the 90% threshold. Worked answers 4.4 to 4.8, 4.10, 4.11, 4.13 and 4.14 |
| **3. The platform** | 9 GitHub, 10 Pull requests, 11 GitHub Actions, 12 Security, 13 Open source, 14 AI/ML workflows | Ten questions a day. For each GitHub fact with a date or a plan gate, note the date; re-verify the ones you would quote in an interview against the documentation the textbook links | Area interview on areas 9 to 12, at the 90% threshold for Security. Prompts 5.1 and 5.2. Worked answers 4.12, 4.15 to 4.17, 4.19, 4.20 |
| **4. Judgment** | 15 Production incidents, 17 Architecture, 18 CTO interview, and every tracked question | Senior and principal levels only. One debugging round a day. One prompt from section 5 a day, ten minutes aloud | Two full CTO interviews of twenty questions on different days, each drawing on at least ten areas. Prompts 5.3 to 5.5 |

**Rules for the four weeks.**

1. **Tracked questions come first.** Every session opens with the questions in the tracker that are due. A question leaves the tracker after two consecutive scores of 12 or more out of 15.
2. **One wrong mechanism stops the week.** If you score 0 on correctness for the same concept twice, stop interview practice for that area and return to the chapter and its lab. Practising delivery on a wrong model makes it more convincing and no more correct.
3. **Draw before you speak.** For any question about history, draw the commit graph with the refs and HEAD before answering. In a real interview, ask for the whiteboard.
4. **Say the layer.** Make "that is Git", "that is GitHub", "that is GitHub Actions" a habit in the first sentence until it is automatic.
5. **Version-sensitive facts carry their date.** Say "as of October 2026" for platform facts, and "since Git 2.54" where the textbook gives a version. If you are not sure of a number, say what it depends on instead.
6. **The last two days are for the twenty.** Give each worked answer of section 4 once more, in two minutes, and grade it with the four checks of section 6.

**When you are ready.** Two full interviews in week 4 at or above the threshold, no tracked question older than a week, and every prompt of section 5 answered once with its costs. The capstone simulation of Module 41 comes after that.

## 8. Where each part of this guide comes from

| Part | Source in the course |
|---|---|
| The five-part answer | [Chapter 1](../textbook/ch01-fundamentals.md), section 1.10 (the root-cause framework and its seven-line box) |
| Read-only diagnosis, the risk ladder, verification | [Chapter 29](../textbook/ch29-production-troubleshooting.md), sections 29.2, 29.7, 29.9 and 29.10 |
| The incident loop, severity, the summary for a CTO, controls | [Chapter 30](../textbook/ch30-incident-response.md), sections 30.2, 30.3, 30.15 and 30.20 |
| The six grading dimensions and the conduct of a session | [Roadmap](../curriculum/Git%20and%20GitHub%20mastery%20roadmap.md), section 3.4; [interview-mode protocol](interview-mode-protocol.md) |
| The worked answers | The sections named in each commentary; the same questions appear in the [bank](cto-question-bank.md), listed under "The questions from your brief" |
| The field versions of the method | [Troubleshooting playbook](../playbooks/troubleshooting-playbook.md), [disaster-recovery playbook](../playbooks/disaster-recovery-playbook.md) |
