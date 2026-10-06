# Exercises for Modules 6 to 10: Integration

> **Baseline.** Git 2.55.0 on macOS. This file contains questions and tasks only. Every solution, with real transcripts, is in [solutions/exercises-m06-m10.md](../solutions/exercises-m06-m10.md). The transcripts printed in this file are evidence for you to reason about; they are real output from the scripts in `labs/ex1/`.

## How to use these exercises

The rules are the ones of [Exercises for Modules 1 to 5](m01-m05-foundations.md): do the labs of a module first; work only inside the lab shell (`labs/shell x1`); write a prediction down before you run the command; from Level 3 on, answer with state, mechanism, root cause, lowest-risk fix, verification and prevention.

Two things are new in this half.

**Level 5.** Each module ends with a production incident in a generated sandbox. You get what people reported, and some of it is wrong. A Level 5 answer has one more part than a Level 4 answer: a verdict on **every** claim in the report (true, false, or true and beside the point), each with the command output that supports the verdict. The incident sandboxes have a bare repository that plays the server and one clone per person; you may look into every clone, as you would at a colleague's desk.

```bash
exercises/gen/m06-weekly-sync/generate.sh     # builds the sandbox and prints its path
labs/shell "<the path it printed>"
exercises/gen/m06-weekly-sync/check.sh        # from the course root: exit status 0 means solved
```

**Commands that open an editor.** `git merge --continue`, `git rebase -i`, `git commit` without `-m` and `git revert` without `--no-edit` open your editor in the lab shell. The solutions were produced by scripts that play the editor's part; where a transcript shows a todo list "as Git opened it" and "as saved", you make the same edit by hand.

Risk labels are the book's: 🟡 for commands that move refs or rewrite private history, 🔴 for commands that can destroy uncommitted work or history on a server. Whenever an exercise makes you type a 🔴 command, preview it first.

---

## Module 6: Merge (Chapter 8)

Read first: [Chapter 8](../textbook/ch08-merge.md), sections 8.2 to 8.17. Labs 6.1 to 6.7 come before these exercises.

### Exercise 6.1 (Level 1): a fast-forward, then a merge commit

```bash
git init retriever
cd retriever
printf 'def search(query):\n    return []\n' > search.py
git add search.py
git commit -q -m "Add search stub"
git switch -q -c feature/bm25
printf 'K1 = 1.2\nB = 0.75\n' > bm25.py
git add bm25.py
git commit -q -m "Add BM25 parameters"
git switch -q main
git merge feature/bm25
git log --graph --oneline

git switch -q -c feature/dense
printf 'DIM = 768\n' > dense.py
git add dense.py
git commit -q -m "Add dense retriever settings"
git switch -q main
git merge --no-ff -m "Merge feature/dense" feature/dense
git log --graph --oneline
git cat-file -p HEAD
```

For each of the two merges say: was a new commit created, which ref moved, from where to where, and what the graph shows afterwards. In the second case a fast-forward was possible: what did `--no-ff` buy, and what would a later `git revert` have to target in each of the two histories to take the feature out again?

### Exercise 6.2 (Level 1): the merge base and the rule table

```bash
git init rules
cd rules
printf 'top_k: 5\nmetric: cosine\nrerank: false\n' > search.yaml
git add search.yaml
git commit -q -m "Add search settings"
git switch -q -c feature/rerank
printf 'top_k: 5\nmetric: cosine\nrerank: true\n' > search.yaml
git commit -q -am "Switch reranking on"
git switch -q main
printf 'top_k: 10\nmetric: cosine\nrerank: false\n' > search.yaml
git commit -q -am "Return ten hits"
git merge-base main feature/rerank
git show "$(git merge-base main feature/rerank)":search.yaml
```

Before merging, fill in this table by hand, one row per line of the file, using the three-way rule.

| Line | Base | Ours (`main`) | Theirs (`feature/rerank`) | Result | Rule applied |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |

Then run `git merge -m "Merge feature/rerank" feature/rerank` and `cat search.yaml`, and compare. Which version of the file did Git need that neither branch tip contains?

### Exercise 6.3 (Level 1): one conflict, step by step

```bash
git init conflict
cd conflict
printf 'model: small\n' > model.yaml
git add model.yaml
git commit -q -m "Add model setting"
git switch -q -c exp/large
printf 'model: large\n' > model.yaml
git commit -q -am "Use the large model"
git switch -q main
printf 'model: medium\n' > model.yaml
git commit -q -am "Use the medium model"
git merge exp/large
git status
cat model.yaml
git ls-files -u
ls .git | grep MERGE
printf 'model: large\n' > model.yaml
git add model.yaml
git status --short
git merge --continue
git log --graph --oneline
```

Describe the state of each place while the merge is stopped: the working tree file, the index (three entries: say what each stage number holds), and the files in `.git` that mark a merge in progress. What does `git add` do to the three index entries, and why is that the signal Git waits for? What would `git merge --abort` have restored?

### Exercise 6.4 (Level 2, draw the graph): two merges

```bash
git init shape
cd shape
git commit -q --allow-empty -m A
git commit -q --allow-empty -m B
git switch -q -c f1
git commit -q --allow-empty -m C
git commit -q --allow-empty -m D
git switch -q main
git commit -q --allow-empty -m E
git switch -q -c f2
git commit -q --allow-empty -m F
git switch -q main
git merge -q --no-ff -m M1 f1
git merge -q -m M2 f2
```

1. Draw the commit graph with time from left to right, as the book draws it, with the parents of `M1` and `M2` in their order (first parent, second parent).
2. Predict the list that `git log --first-parent --oneline` prints.
3. Run `git log --graph --oneline` and match every line of its drawing to your picture. The second merge had no `--no-ff`: why was a merge commit created anyway?

### Exercise 6.5 (Level 2, prediction): what a squash leaves behind

```bash
git init squash
cd squash
printf 'v1\n' > core.txt
git add core.txt
git commit -q -m "Add core"
git switch -q -c feature/x
printf 'one\n' > x1.txt
git add x1.txt
git commit -q -m "Add x1"
printf 'two\n' > x2.txt
git add x2.txt
git commit -q -m "Add x2"
git switch -q main
git merge --squash feature/x
```

Predict, at this point: the output of `git status --short`; whether `git log --oneline` on `main` shows a new commit; whether `.git/MERGE_HEAD` exists.

Then run `git commit -q -m "Add x (squashed)"` and predict: the picture of `git log --graph --oneline --all`; the number of parents of the new commit; whether `git branch --merged main` lists `feature/x`; what `git branch -d feature/x` answers.

Finally: what did the squash transfer, and what did it not transfer?

### Exercise 6.6 (Level 2, prediction): which of three changes conflicts?

```bash
git init regions
cd regions
printf 'a: 1\nb: 2\nc: 3\nd: 4\ne: 5\nf: 6\n' > params.yaml
git add params.yaml
git commit -q -m "Add parameters"
git switch -q -c topic
printf 'a: 1\nb: 20\nc: 3\nd: 40\ne: 5\nf: 60\n' > params.yaml
git commit -q -am "Topic: change b, d and f"
git switch -q main
printf 'a: 10\nb: 2\nc: 3\nd: 40\ne: 5\nf: 6\n' > params.yaml
git commit -q -am "Main: change a and d"
```

`main` changed lines `a` and `d`. `topic` changed lines `b`, `d` and `f`. No line was changed to two different values. Predict for `git merge topic`: does it conflict? If yes, exactly which lines stand between the conflict markers, and what do the other lines of the file look like? Write the whole file as you expect it, then merge and compare. State the rule that surprised you, if one did.

### Exercise 6.7 (Level 3): "Already up to date", and the change is not there

Asha merged `feature/bm25-tuning` into `main` two days ago. Today the search team notices that `main` still has the old BM25 parameters. Merging again does nothing.

<!-- snippet: ex1/ex-m06/e07-evidence -->
```text
$ git merge feature/bm25-tuning
Already up to date.
$ git branch --merged main
  feature/bm25-tuning
* main
$ git show main:ranker/bm25.py
K1 = 1.2
B = 0.75
$ git show feature/bm25-tuning:ranker/bm25.py
K1 = 1.6
B = 0.6
$ git log --graph --oneline
* 9c1ef62 Name the owner
*   63bb1dc Merge feature/bm25-tuning
|\  
| * aae44c8 Lower b for short documents
| * 0d08506 Raise k1 after the grid search
* | f8c6f49 Describe the project
|/  
* cc99c71 Add BM25 parameters
```
<!-- /snippet -->

1. Explain why Git answers "Already up to date" and why `git branch --merged` lists the branch, although the file on `main` differs from the file on the branch.
2. A merge commit records ancestry and a tree. Describe a merge in which the two are "out of step", name two ways such a merge can be produced, and give the commands that prove which commit it is and what it discarded. Include the `git log` or `git show` option made for auditing merges.
3. `main` is shared. Give two ways to get the two tuning commits' changes into `main` now, and say under which condition the simpler one is wrong.

### Exercise 6.8 (Level 3): conflict markers in `main`

The prompt service starts answering with `<<<<<<< HEAD` in its replies.

<!-- snippet: ex1/ex-m06/e08-evidence -->
```text
$ git grep -n -e '^<<<<<<<' -e '^=======' -e '^>>>>>>>' -- prompts
prompts/support.txt:1:<<<<<<< HEAD
prompts/support.txt:3:=======
prompts/support.txt:5:>>>>>>> feature/tone
$ git log --graph --oneline
* 64dec7f Add request timeout
*   6a1ebab Merge branch 'feature/tone'
|\  
| * 000d763 Make the assistant friendly
* | 30afaba Name the company
|/  
* 8a9fbde Add support prompt
```
<!-- /snippet -->

1. Which commit introduced the markers? Before you run anything: explain why `git log -S'<<<<<<<' -- prompts/support.txt` is likely to print nothing here, and what you must add to make the search see the commit.
2. How did a file with markers get committed at all? State what Git checks before it lets a merge be concluded, and what it does not check.
3. Fix `main` (it is shared). Then name two cheap controls, one local and one in review or CI, that catch committed markers, and the Git command each of them can be built on.

### Exercise 6.9 (Level 4): a merge that somebody else left half done

A repository is in the middle of a merge with two conflicts of two different kinds.

```bash
exercises/gen/m06-half-merged/generate.sh
```

Read [exercises/gen/m06-half-merged/SYMPTOMS.md](gen/m06-half-merged/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m06-half-merged/check.sh`. Hand in: what each side intended, commit by commit; for each conflict its type and the three versions involved; your resolution and the reason; the part of your result that neither parent contains and where you documented it; and the audit command you ran on the finished merge.

### Exercise 6.10 (Level 5): the weekly sync that conflicts more every week

`develop` is brought into `main` every Friday. The conflicts grow from week to week, in lines that nobody edits on `main`.

```bash
exercises/gen/m06-weekly-sync/generate.sh
```

Read [exercises/gen/m06-weekly-sync/SYMPTOMS.md](gen/m06-weekly-sync/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m06-weekly-sync/check.sh`. Hand in: a verdict on each explanation that was offered (the hotfix, the missing rerere) with evidence; the root cause as a statement about the merge base; the proof of which state of `develop` is already contained in `main`; your repair, including why it changes no file content in its first step; and the sync procedure you would write into the team's runbook.

---

## Module 7: Remotes (Chapter 12)

Read first: [Chapter 12](../textbook/ch12-remote-operations.md), sections 12.2 to 12.12 and 12.14. Labs 7.1 to 7.7 come before these exercises.

In this module a bare repository on disk plays the server and extra clones play your teammates. Inside the lab shell every clone uses the same identity unless you configure one; that does not matter for these exercises.

### Exercise 7.1 (Level 1): what a clone writes down about its remote

```bash
mkdir m07-ex1 && cd m07-ex1
git init -q --bare server.git
git clone server.git you
cd you
printf 'TTL_SECONDS = 3600\n' > cache.py
git add cache.py
git commit -q -m "Add embedding cache settings"
git push -u origin main
cat .git/config
git remote -v
git branch -vv
git for-each-ref
```

Explain every line of the `[remote "origin"]` and `[branch "main"]` sections: what it is, which command wrote it, and which later command reads it. Take the fetch refspec apart: the `+`, the left side, the right side. Which of the two refs listed by `git for-each-ref` did your commit move, and which did the push move?

### Exercise 7.2 (Level 1): fetch first, look, then integrate

Continue in `m07-ex1`. A teammate pushes a commit.

```bash
cd ..
git clone -q server.git asha
git -C asha commit -q --allow-empty -m "Asha: add eviction policy"
git -C asha push -q
cd you
git status -sb
git fetch
git status -sb
git log --oneline main..origin/main
git merge --ff-only origin/main
git status -sb
```

The first `git status -sb` claims that nothing is to be done. State precisely what that line compares, and when the information it relies on was last updated. Which refs did `git fetch` move and which did it leave alone? Why is `fetch`, look, `merge --ff-only` a safer habit than `git pull` when you do not know what arrived?

### Exercise 7.3 (Level 1): publish a branch, then delete it on the server

Continue in `m07-ex1/you`.

```bash
git switch -q -c feature/ttl
git commit -q --allow-empty -m "Make the TTL configurable"
git push -u origin feature/ttl
git config get branch.feature/ttl.remote
git config get branch.feature/ttl.merge
git branch -vv
git push origin --delete feature/ttl
git branch -r
git branch -vv
git ls-remote --heads origin
```

What did `-u` add to the push, and where? After the deletion, three things still exist or no longer exist: the branch on the server, the remote-tracking branch, your local branch. Say which is which, what `gone` means, and whether your commit is at risk.

### Exercise 7.4 (Level 2, prediction): what the clone knows before and after a fetch

```bash
mkdir m07-ex4 && cd m07-ex4
git init -q --bare server.git
git clone -q server.git you
git -C you remote set-url origin ../server.git     # a relative URL, so that messages are the same on every machine
git -C you commit -q --allow-empty -m A
git -C you push -q -u origin main
git clone -q server.git asha
git -C asha commit -q --allow-empty -m "Asha: B"
git -C asha push -q
cd you
git commit -q --allow-empty -m "You: C"
```

The server has `A` and `B`. You have `A` and `C`, and you have not fetched. Predict:

1. What does `git status -sb` print in the brackets?
2. `git push` is rejected. With which of the two reasons that Git distinguishes, shown in parentheses on the `! [rejected]` line?

Now run `git fetch -q` and predict both again. Explain why the same push is rejected with a different reason although the server has not changed in between.

### Exercise 7.5 (Level 2, draw the graph): the same pull, by merge and by rebase

Continue in `m07-ex4` right after Exercise 7.4 (your clone has `A` and `C`, the server has `A` and `B`).

```bash
cd ..
cp -R you you-rebase
git -C you pull --no-rebase -q
git -C you-rebase pull --rebase -q
```

Draw `git log --graph --oneline` for each of the two clones, and predict what `git status -sb` prints in each. For each result say: which commits are new objects, which of your commit IDs survived, and what the next `git push` will send.

### Exercise 7.6 (Level 2, prediction): which refs does a fetch move?

You cloned a repository when the server had the branches `main`, `feature/a` and `feature/b`. Since then, on the server:

- `main` received one new commit;
- `feature/a` was deleted;
- `feature/b` was rewritten (its last commit amended) and force-pushed;
- a new branch `feature/c` was pushed;
- a tag `v1.0` was pushed, on the new commit of `main`.

The setup, with Asha's clone playing everybody else:

```bash
mkdir m07-ex6 && cd m07-ex6
git init -q --bare server.git
git clone -q server.git asha
cd asha
git commit -q --allow-empty -m A && git push -q -u origin main
git switch -q -c feature/a && git commit -q --allow-empty -m "Feature a" && git push -q -u origin feature/a
git switch -q -c feature/b main && git commit -q --allow-empty -m "Feature b" && git push -q -u origin feature/b
cd ..
git clone -q server.git you
cd asha
git switch -q main && git commit -q --allow-empty -m B && git push -q
git push -q origin --delete feature/a
git switch -q -c feature/c main && git commit -q --allow-empty -m "Feature c" && git push -q -u origin feature/c
git tag v1.0 main && git push -q origin v1.0
git switch -q feature/b && git commit -q --amend --allow-empty -m "Feature b, reworded" && git push -q --force-with-lease
cd ../you
```

Predict for a plain `git fetch` in your clone:

1. One output line per ref that changes. Which line starts with a `+`, which with a `*`, and what do the two characters mean?
2. What `git branch -r` lists afterwards. Is `origin/feature/a` in the list?
3. What `git fetch --prune` prints after that.

State which part of the configuration allowed the fetch to move `origin/feature/b` although that was not a fast-forward.

### Exercise 7.7 (Level 3): the branch that this clone cannot see

A CI job works in a clone of the team repository. The job is told to test the branch `feature/eviction`, which exists on the server, and fails.

<!-- snippet: ex1/ex-m07/e07-evidence -->
```text
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git fetch
$ git switch feature/eviction
fatal: invalid reference: feature/eviction
[exit status: 128]
$ git ls-remote --heads origin
f09ff70c82dcff524401eac3f676120849709ec3	refs/heads/feature/eviction
3e5dd828394a9967823901d8e3d10445a661c550	refs/heads/main
```
<!-- /snippet -->

1. `git fetch` succeeds, prints nothing, and the branch does not arrive. Name the piece of configuration that decides what a fetch brings, and the command that prints it. Say what you expect to see.
2. How is such a clone made? Name two `git clone` options that produce it, one of them implied by the other.
3. Give two repairs: one that brings this single branch, one that makes the clone behave like an ordinary one. Verify with `git switch feature/eviction`.

### Exercise 7.8 (Level 3): a push that the other side refuses

Ravi "deploys" to a staging machine by pushing to a repository there. Today the push is refused.

<!-- snippet: ex1/ex-m07/e08-evidence -->
```text
$ git remote -v
origin	$LAB/ex1/ex-m07/m07-ex8/staging-box (fetch)
origin	$LAB/ex1/ex-m07/m07-ex8/staging-box (push)
$ git push origin main
remote: error: refusing to update checked out branch: refs/heads/main        
remote: error: By default, updating the current branch in a non-bare repository        
remote: is denied, because it will make the index and work tree inconsistent        
remote: with what you pushed, and will require 'git reset --hard' to match        
remote: the work tree to HEAD.        
remote: 
remote: You can set the 'receive.denyCurrentBranch' configuration variable        
remote: to 'ignore' or 'warn' in the remote repository to allow pushing into        
remote: its current branch; however, this is not recommended unless you        
remote: arranged to update its work tree to match what you pushed in some        
remote: other way.        
remote: 
remote: To squelch this message and still keep the default behaviour, set        
remote: 'receive.denyCurrentBranch' configuration variable to 'refuse'.        
To $LAB/ex1/ex-m07/m07-ex8/staging-box
 ! [remote rejected] main -> main (branch is currently checked out)
error: failed to push some refs to '$LAB/ex1/ex-m07/m07-ex8/staging-box'
[exit status: 1]
```
<!-- /snippet -->

1. What is different about this remote compared with the server of the other exercises? Name the command that tells you, run on the remote side.
2. Explain what would be inconsistent on the staging machine if Git accepted the push, in terms of that repository's branch ref, index and working tree.
3. The message names a configuration variable. List its values that matter here and what each one does. Then describe the two sound designs for "push to deploy" and say why setting the variable to `ignore` is neither.

### Exercise 7.9 (Level 4): a clone that has not talked to the server for a week

Three symptoms in one clone: a rejected push, a branch that follows the wrong upstream, and a branch that was deleted on the server.

```bash
exercises/gen/m07-stale-clone/generate.sh
```

Read [exercises/gen/m07-stale-clone/SYMPTOMS.md](gen/m07-stale-clone/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m07-stale-clone/check.sh`. Hand in: a table of what the clone believed against what the server had, with the command that revealed each difference; the cause of each of the three symptoms; the repair; and the explanation of how `feature/tokenizer` came to follow `origin/main`, with the setting that prevents it.

### Exercise 7.10 (Level 5): the hotfix that was pushed and is not on the server

A release was built without a hotfix that its author pushed the day before. A fetch reported a forced update. People are being blamed.

```bash
exercises/gen/m07-hotfix-not-deployed/generate.sh
```

Read [exercises/gen/m07-hotfix-not-deployed/SYMPTOMS.md](gen/m07-hotfix-not-deployed/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m07-hotfix-not-deployed/check.sh`. Hand in: a verdict on each statement of Ravi and of Asha, with evidence; the place where the commit went and the piece of configuration that sent it there; the explanation of why `git status` said "up to date" after the push and why the later fetch said "forced update" although nobody forced anything; the repair of the branch and of the clone; and a check that the platform team should add to its migration script.

---

## Module 8: Undo (Chapter 11)

Read first: [Chapter 11](../textbook/ch11-reset-revert-restore.md), sections 11.2 to 11.13. Labs 8.1 to 8.7 come before these exercises.

Before every exercise of this module, answer the deciding question of section 11.2 for yourself: is the history you are about to change private or shared?

### Exercise 8.1 (Level 1): take a commit back and make it again

```bash
git init eval-runner
cd eval-runner
printf 'def run(case):\n    return case.execute()\n' > runner.py
git add runner.py
git commit -q -m "Add runner"
printf 'def run(case):\n    return case.execute(timeout=30)\n' > runner.py
git commit -q -am "wip"
git reset --soft HEAD~1
git status --short
git diff --cached --stat
git log --oneline
git commit -q -m "Give every case a 30 second timeout"
git log --oneline
git reflog -4
```

🟡 `git reset --soft` moves the branch. For the moment right after it, state what each of HEAD, the branch ref, the index and the working tree holds. Where is the commit `wip` after the last command, and which line of the output proves it? Which other command would have produced the same final history in one step?

### Exercise 8.2 (Level 1): revert a commit that is not the last one

Continue in `eval-runner`.

```bash
printf 'retries: 5\n' > retry.yaml
git add retry.yaml
git commit -q -m "Retry five times"
printf '# eval-runner\n' > README.md
git add README.md
git commit -q -m "Add README"
git revert --no-edit HEAD~1
git log --oneline
git show --stat --format="%s%n%n%b" HEAD
ls
```

How many commits does the history have before and after? What does the new commit contain, and what does its message record? The commit after the reverted one (`Add README`) is untouched: explain why that is possible here and name the situation in which the same command would have stopped with a conflict.

### Exercise 8.3 (Level 1): park an edit and bring it back

Continue in `eval-runner`.

```bash
printf 'def run(case):\n    return case.execute(timeout=60)\n' > runner.py
git stash push -m "try a longer timeout"
git status --short
git stash list
git stash show -p
git stash apply
git stash list
git stash drop
git status --short
```

Say where the edit was while the working tree was clean. What is the difference between `apply` and `pop`, visible in this transcript? After `git stash drop` the edit is in your working tree: is anything lost? What would have been lost if you had dropped before applying, and for how long could it still be recovered?

### Exercise 8.4 (Level 2, prediction): `reset --keep`, twice

```bash
git init keep
cd keep
printf 'a1\n' > a.txt
printf 'b1\n' > b.txt
git add .
git commit -q -m "Base"
printf 'a2\n' > a.txt
git commit -q -am "Change a"
printf 'b2\n' > b.txt
```

Part A. You have an uncommitted edit in `b.txt`. Predict what `git reset --keep HEAD~1` does: its exit status, the content of `a.txt` and of `b.txt` afterwards, and the output of `git status --short` and `git log --oneline`.

Part B. Go forward again and make a second uncommitted edit, this time in the file that the last commit changed:

```bash
git reset -q --keep ORIG_HEAD
printf 'a3\n' > a.txt
```

Predict the same four things for `git reset --keep HEAD~1` now. Then say what 🔴 `git reset --hard HEAD~1` would have done in Part B, without running it.

### Exercise 8.5 (Level 2, prediction): revert a range

```bash
git init revert-range
cd revert-range
printf 'a\n' > a.txt && git add a.txt && git commit -q -m 'Add a'
printf 'b\n' > b.txt && git add b.txt && git commit -q -m 'Add b'
printf 'c\n' > c.txt && git add c.txt && git commit -q -m 'Add c'
printf 'd\n' > d.txt && git add d.txt && git commit -q -m 'Add d'
git revert --no-edit HEAD~2..HEAD
```

Predict: how many commits the revert created; their titles, in the order `git log --oneline` lists them; which files `ls` shows; the total number of commits; and the exit status of `git diff --quiet HEAD~4 HEAD`. Explain the order in which Git reverted, and why that order matters when the commits touch the same lines.

### Exercise 8.6 (Level 2, draw the graph): after a hard reset

```bash
git init undo-graph
cd undo-graph
git commit -q --allow-empty -m A
git commit -q --allow-empty -m B
git commit -q --allow-empty -m C
git branch backup
git reset -q --hard HEAD~2
git commit -q --allow-empty -m D
```

1. Draw what `git log --graph --oneline --all` prints, with `main`, `backup` and HEAD.
2. Which commit does `ORIG_HEAD` name now? Did the commit `D` change it?
3. Suppose the line `git branch backup` had not been typed. Draw the `--all` graph for that case. Are `B` and `C` gone? Give two different names by which `C` could still be reached, and say how long each name would last in a repository with default settings.

### Exercise 8.7 (Level 3): the commit that came back

A debugging commit ("let everything pass") reached the server. Its author removed it locally and was surprised twice.

<!-- snippet: ex1/ex-m08/e07-evidence -->
```text
$ git log --oneline
714b287 Debug: let everything pass
9a037bf Add pass mark
$ git reset --hard HEAD~1
HEAD is now at 9a037bf Add pass mark
$ git status -sb
## main...origin/main [behind 1]
$ git push
To $LAB/ex1/ex-m08/m08-ex7/server.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '$LAB/ex1/ex-m08/m08-ex7/server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git pull
Updating 9a037bf..714b287
Fast-forward
 threshold.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline
714b287 Debug: let everything pass
9a037bf Add pass mark
```
<!-- /snippet -->

1. After the reset, `git status -sb` says `[behind 1]`, not `[ahead ...]` and not diverged. Explain what the reset did to which ref, and why the push was rejected.
2. Explain why `git pull` "restored" the commit, and with which kind of merge.
3. Give the correct undo for this situation and say why it is correct. Then say what the author would have had to do to make the reset stick, what that does to teammates who already pulled, and under which condition it is still the right call.

### Exercise 8.8 (Level 3): what a hard reset took and what it left

```bash
git init lost
cd lost
printf 'def run(case):\n    return case.execute()\n' > runner.py
git add runner.py
git commit -q -m "Add runner"
mkdir eval
printf 'def f1(p, r):\n    return 2 * p * r / (p + r)\n' > eval/metrics.py
git add eval/metrics.py
printf 'ask Asha about macro F1\n' > notes.txt
printf 'def run(case):\n    return case.execute(timeout=30)\n' > runner.py
git status --short
git reset --hard
git status --short
ls
cat runner.py
```

Three pieces of uncommitted work existed before the 🔴 `git reset --hard`: a new file that was staged, a new file that was never staged, and an edit to a tracked file that was never staged.

1. For each of the three, say what happened to it and why, in terms of what `--hard` resets.
2. One of the two lost pieces can be recovered and the other cannot. Say which, why, and recover it. State how long that chance lasts with default settings.
3. Which command, run instead of `git reset --hard`, would have refused to destroy anything, and which would have shown you the damage in advance?

### Exercise 8.9 (Level 4): one bad commit that is public, one mixed commit that is not

Two different problems in one clone, and they need two different kinds of undo.

```bash
exercises/gen/m08-undo-mix/generate.sh
```

Read [exercises/gen/m08-undo-mix/SYMPTOMS.md](gen/m08-undo-mix/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m08-undo-mix/check.sh`. Hand in: the evidence for which commits are private and which are shared; for each of the two problems the tool you chose and the tools you rejected, with the reason; a state table (working tree, index, HEAD, branch, server) after each step; and the verification.

### Exercise 8.10 (Level 5): a feature that was merged twice and is half missing

A pull request was merged without conflicts, the branch counts as merged, and half of its files are not in `main`.

```bash
exercises/gen/m08-missing-half/generate.sh
```

Read [exercises/gen/m08-missing-half/SYMPTOMS.md](gen/m08-missing-half/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m08-missing-half/check.sh`. Hand in: a verdict on each statement of Asha and of Ravi, with evidence; the commit that removed the files, how you found it without a keyword, and the proof of what it is; the explanation of why the second merge was clean and small and why a third would be empty; the repair; and the sentence that should have been in that commit's message.

---

## Module 9: Rebase (Chapter 9)

Read first: [Chapter 9](../textbook/ch09-rebase.md), sections 9.2 to 9.17. Labs 9.1 to 9.7 come before these exercises.

🟡 Every rebase in this module rewrites commits. Before each one, say whether the commits are private.

### Exercise 9.1 (Level 1): a plain rebase, before and after

```bash
git init guardrails
cd guardrails
printf 'RULES = []\n' > rules.py
git add rules.py
git commit -q -m "Add rule engine"
git switch -q -c feat/pii
printf 'def has_pii(text):\n    return False\n' > pii.py
git add pii.py
git commit -q -m "Add PII rule"
printf 'def has_pii(text):\n    return "@" in text\n' > pii.py
git commit -q -am "Treat an at-sign as PII"
git switch -q main
printf '# guardrails\n' > README.md
git add README.md
git commit -q -m "Add README"
git switch -q feat/pii
git log --graph --oneline --all
git rebase main
git log --graph --oneline --all
git log --oneline ORIG_HEAD -2
git range-diff main ORIG_HEAD HEAD
```

Compare the two graphs. Which commits are new objects, and which of their fields differ from the originals (tree, parent, author, author date, committer date, message)? Where are the two old commits now, and what does each line of the `git range-diff` output assert?

### Exercise 9.2 (Level 1): fold a fix into the commit it belongs to

Continue in `guardrails`, on `feat/pii`.

```bash
printf 'def has_pii(text):\n    return "@" in text or "+" in text\n' > pii.py
git commit -q -am "fix: phone numbers too"
git log --oneline main..HEAD
git rebase -i main
```

In the editor, change the word `pick` on the third line to `fixup`, save, and close. Then:

```bash
git log --oneline main..HEAD
git show --stat --format=%s HEAD
```

What happened to the third commit and to its message? How does `fixup` differ from `squash`? Which commit IDs changed, and which commit of the branch kept its ID, and why that one?

### Exercise 9.3 (Level 1): a conflict, a look around, and the way back

```bash
git init stop-and-go
cd stop-and-go
printf 'max_len: 100\n' > limits.yaml
git add limits.yaml
git commit -q -m "Add limits"
git switch -q -c feat/longer
printf 'max_len: 500\n' > limits.yaml
git commit -q -am "Allow 500 characters"
git switch -q main
printf 'max_len: 200\n' > limits.yaml
git commit -q -am "Allow 200 characters"
git switch -q feat/longer
git rebase main
git status
git branch --show-current
git log --oneline -1
ls .git/rebase-merge | sort | head -8
cat .git/rebase-merge/head-name
cat limits.yaml
git rebase --abort
git status -sb
git log --oneline -1
cat limits.yaml
```

While the rebase is stopped: where is HEAD, why does `git branch --show-current` print nothing, and where does Git remember which branch is being rebased? In the conflicted file, which side is labelled `HEAD` and whose change is it? Compare that with the same conflict in a merge started from `feat/longer`. What did `--abort` restore?

### Exercise 9.4 (Level 2, draw the graph): the old commits and the new ones

```bash
git init rebase-graph
cd rebase-graph
git commit -q --allow-empty -m A
git commit -q --allow-empty -m B
git switch -q -c topic
git commit -q --allow-empty -m C
git commit -q --allow-empty -m D
git switch -q main
git commit -q --allow-empty -m E
git branch before topic
git rebase -q main topic
```

1. Draw what `git log --graph --oneline --all` prints, with the three branch names. Two commit titles appear twice: mark which copies are the originals.
2. Which branch is checked out after the last command, although it was typed on `main`?
3. If the line `git branch before topic` had been left out, which commits would be missing from the picture, and through which reflog could you still reach them?

### Exercise 9.5 (Level 2, prediction): a commit that `main` already has

```bash
git init upstream
cd upstream
printf 'v1\n' > core.txt && git add core.txt && git commit -q -m 'Add core'
git switch -q -c feat/x
printf 'fix\n' > fix.txt && git add fix.txt && git commit -q -m 'Fix tokenizer crash'
printf 'x\n' > x.txt && git add x.txt && git commit -q -m 'Add feature x'
git switch -q main
git cherry-pick feat/x~1
printf 'v2\n' > core.txt && git commit -q -am 'Update core'
git switch -q feat/x
```

`feat/x` has two commits that are not reachable from `main`. One of them was copied to `main` with `git cherry-pick`. Predict for `git rebase main`: how many commits are replayed, what Git says about the other one, and what `git log --oneline main..feat/x` lists afterwards. How does Git recognize the copy, given that its ID differs from the original's?

### Exercise 9.6 (Level 2, draw the graph): a merge inside the branch

```bash
git init flatten
cd flatten
git commit -q --allow-empty -m A
git switch -q -c topic
git commit -q --allow-empty -m B
git switch -q -c side
git commit -q --allow-empty -m C
git switch -q topic
git commit -q --allow-empty -m D
git merge -q --no-ff -m M side
git switch -q main
git commit -q --allow-empty -m E
git switch -q topic
git log --graph --oneline topic main
```

`topic` contains a merge commit `M`. Draw `git log --graph --oneline topic main` after each of these, starting both times from the state above:

1. `git rebase -q main`
2. `git reset -q --hard ORIG_HEAD`, then `git rebase -q --rebase-merges main`

In the first result, what became of `M`, and in which order do `B`, `C` and `D` appear? In the second, is `M` the same commit as before?

### Exercise 9.7 (Level 3): a rebase that stopped at an `exec` line

A branch with three commits is rebased onto `main` with a check after every commit. The check script prints "check failed" and exits with a non-zero status when `rules.txt` contains the marker `BUG`.

<!-- snippet: ex1/ex-m09/e07-evidence -->
```text
$ git rebase --exec 'sh ./check.sh' main
Rebasing (1/6)
Rebasing (2/6)
Executing: sh ./check.sh
check passed
Rebasing (3/6)
Rebasing (4/6)
Executing: sh ./check.sh
check failed: BUG marker in rules.txt
warning: execution failed: sh ./check.sh
You can fix the problem, and then run

  git rebase --continue


[exit status: 1]
$ git status
interactive rebase in progress; onto 2d5381a
Last commands done (4 commands done):
   pick b75b4a9 # Add rule three
   exec sh ./check.sh
  (see more in file .git/rebase-merge/done)
Next commands to do (2 remaining commands):
   pick e46595f # Add rule four
   exec sh ./check.sh
  (use "git rebase --edit-todo" to view and edit)
You are currently editing a commit while rebasing branch 'feat/more-rules' on '2d5381a'.
  (use "git commit --amend" to amend the current commit)
  (use "git rebase --continue" once you are satisfied with your changes)

nothing to commit, working tree clean
```
<!-- /snippet -->

1. Read the state from the two outputs: which commits have been rewritten already, which commit is HEAD, which commands are still to run, and is the working tree clean?
2. Say what each of these would do now: `git rebase --continue`, `git rebase --skip`, `git rebase --abort`, `git rebase --edit-todo`.
3. The right repair is to fix the commit that fails the check and go on. Give the commands. Then predict what happens when the next commit, which was written on top of the faulty one, is replayed.

### Exercise 9.8 (Level 3): the same conflict at every commit

A branch tried three batch sizes in three commits, all on one line of `train.yaml`. Meanwhile `main` added a comment on that line. The rebase conflicts, you resolve it, and it conflicts again.

<!-- snippet: ex1/ex-m09/e08-evidence -->
```text
$ git rebase main
Rebasing (1/3)
Auto-merging train.yaml
CONFLICT (content): Merge conflict in train.yaml
error: could not apply 313ea24... Try batch size 16
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 313ea24... # Try batch size 16
[exit status: 1]
$ printf 'batch_size: 16  # limited by the 16 GB cards\n' > train.yaml
$ git add train.yaml
$ git rebase --continue
[detached HEAD 4b78b9b] Try batch size 16
 1 file changed, 1 insertion(+), 1 deletion(-)
Rebasing (2/3)
Auto-merging train.yaml
CONFLICT (content): Merge conflict in train.yaml
error: could not apply eef9d95... Try batch size 32
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply eef9d95... # Try batch size 32
[exit status: 1]
```
<!-- /snippet -->

1. Explain why a branch of three commits can conflict three times in a rebase, and how many conflicts a merge of the same branch into `main` would have. Name the command that answers the second question without touching the working tree.
2. Would rerere remove the repeated work here? Give the reason from how rerere identifies a conflict.
3. Give two ways to integrate the branch with one conflict resolution in total: one that keeps a linear history and one that does not. Carry out the linear one. Which rebase option lets you tidy the branch without moving it?

### Exercise 9.9 (Level 4): the morning rebase that replays somebody else's commits

A routine `git rebase main` stops with a conflict in a file you never edited and announces five commits where you wrote two.

```bash
exercises/gen/m09-stacked-after-squash/generate.sh
```

Read [exercises/gen/m09-stacked-after-squash/SYMPTOMS.md](gen/m09-stacked-after-squash/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m09-stacked-after-squash/check.sh`. Hand in: how you read the stopped state; why `main..HEAD` holds five commits; why Git did not skip the three that are "already in `main`"; the command you used with its three arguments explained; and the verification that your two commits arrived unchanged.

### Exercise 9.10 (Level 5): "rebased onto main, no functional change"

After a rebase and a forced push, a behavior that reviewers remember approving is not in the pull request any more.

```bash
exercises/gen/m09-vanished-guard/generate.sh
```

Read [exercises/gen/m09-vanished-guard/SYMPTOMS.md](gen/m09-vanished-guard/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m09-vanished-guard/check.sh`. Hand in: a verdict on each statement of Ravi and of Asha, with evidence; where the old state of the branch can still be found in each of the three clones and why the server cannot help; the commit that was lost and the most probable command that lost it; the repair, including the conflict you had to resolve and why you did not rewrite the branch again; and the review step that would have caught the loss on Friday.

---

## Module 10: Cherry-pick and ranges (Chapter 10; Chapter 14A, sections 14A.7, 14A.8, 14A.14)

Read first: [Chapter 10](../textbook/ch10-cherry-pick.md), sections 10.2 to 10.11, and [Chapter 14A](../textbook/ch14a-history-investigation.md), sections 14A.2, 14A.7, 14A.8 and 14A.14. Labs 10.1 to 10.4 come before these exercises.

### Exercise 10.1 (Level 1): one commit, copied to another branch

```bash
git init tokenlab
cd tokenlab
printf 'def tokenize(text):\n    return text.split()\n' > tokenizer.py
git add tokenizer.py
git commit -q -m "Add whitespace tokenizer"
git branch release/1.0
printf 'hello\nworld\n' > vocab.txt
git add vocab.txt
git commit -q -m "Add vocabulary file"
printf 'def tokenize(text):\n    return text.split() if text else []\n' > tokenizer.py
git commit -q -am "Return an empty list for empty input"
git switch -q release/1.0
git cherry-pick main
git log --graph --oneline --all
git log -1 --format='%h  author %an %ad  |  committer %cd' --date=format:%H:%M main
git log -1 --format='%h  author %an %ad  |  committer %cd' --date=format:%H:%M release/1.0
git range-diff 'main^!' 'release/1.0^!'
ls
```

The two commits with the same title: which fields do they share and which differ? Why does `release/1.0` not contain `vocab.txt` although the picked commit came after the commit that added it? What does the `=` in the `git range-diff` line assert, and what would Git have used as the merge base of this cherry-pick?

### Exercise 10.2 (Level 1): names for commits

Build this history (the titles tell you what each commit adds):

```bash
git init selectors
cd selectors
printf 'a\n' > a.txt && git add . && git commit -q -m 'Add a'
printf 'b\n' > b.txt && git add . && git commit -q -m 'Add b'
git switch -q -c side
printf 's1\n' > s1.txt && git add . && git commit -q -m 'Add s1'
printf 's2\n' > s2.txt && git add . && git commit -q -m 'Add s2'
git switch -q main
printf 'c\n' > c.txt && git add . && git commit -q -m 'Add c'
git merge -q --no-ff -m "Merge side" side
printf 'd\n' > d.txt && git add . && git commit -q -m 'Add d'
git log --graph --oneline
```

With the graph in front of you, write down which commit title each expression names. Then check each with `git show -s --format=%s '<expression>'`.

| Expression | Your answer |
|---|---|
| `HEAD~1` | |
| `HEAD~2` | |
| `HEAD~1^2` | |
| `HEAD~1^2~1` | |
| `HEAD^^^` | |
| `:/Add s` | |
| `main@{1}` | |

Finally, what type of object do `HEAD^{tree}` and `HEAD~1:s2.txt` name? Check with `git cat-file -t`. Which of the expressions in the table reads the reflog and would therefore give another answer in a fresh clone?

### Exercise 10.3 (Level 1): two commits picked as one

Continue in `tokenlab` from Exercise 10.1.

```bash
git switch -q main
printf 'LOWERCASE = False\n' > options.py
git add options.py
git commit -q -m "Add lowercase option"
printf '# tokenlab\n\nSet LOWERCASE in options.py to fold case.\n' > README.md
git add README.md
git commit -q -m "Document the lowercase option"
git switch -q release/1.0
git cherry-pick -n main~1 main
git status --short
git log --oneline -1
git commit -q -m "Backport the lowercase option and its documentation"
git show --stat --format="%h %s" HEAD
```

What did `-n` change about what `git cherry-pick` does to the index, the working tree and the branch? What is lost compared with two separate picks made with `-x`, and when is that loss acceptable?

### Exercise 10.4 (Level 2, prediction): ranges on a history with a merge

```bash
git init ranges
cd ranges
git commit -q --allow-empty -m A
git commit -q --allow-empty -m B
git switch -q -c topic
git commit -q --allow-empty -m C
git commit -q --allow-empty -m D
git switch -q main
git commit -q --allow-empty -m E
git switch -q topic
git merge -q -m M main
git commit -q --allow-empty -m F
git switch -q main
git commit -q --allow-empty -m G
```

Draw the graph first. Then predict the commit titles that each command lists, in order:

```bash
git log --oneline main..topic
git log --oneline topic..main
git log --oneline --left-right main...topic
git rev-list --left-right --count main...topic
git log --oneline --no-merges topic ^main
git log --oneline "topic~1^!"
```

`E` is reachable from `topic` through the merge `M`. In which of the six outputs does `E` appear, and why? Write each of the first, the fifth and the sixth range as a sentence that begins "the commits reachable from ... and not reachable from ...".

### Exercise 10.5 (Level 2, prediction): which commits does a range pick?

```bash
git init pick-range
cd pick-range
printf 'base\n' > base.txt && git add . && git commit -q -m 'Base'
git branch release
printf 'a\n' > a.txt && git add . && git commit -q -m 'Add a'
printf 'b\n' > b.txt && git add . && git commit -q -m 'Add b'
printf 'c\n' > c.txt && git add . && git commit -q -m 'Add c'
printf 'd\n' > d.txt && git add . && git commit -q -m 'Add d'
git switch -q release
git cherry-pick main~3..main~1
```

Predict: which commits were copied and in which order they were applied; what `git log --oneline` and `ls` show on `release`; and the mark (`+` or `-`) that `git cherry -v release main` prints in front of each of the four commits of `main`. Which commit would the range have to start from to include `Add a`?

### Exercise 10.6 (Level 2, draw the graph): backport, then merge the release back

```bash
git init backport
cd backport
printf 'base\n' > base.txt && git add . && git commit -q -m 'A'
git branch release/2.1
printf 'feature\n' > feature.txt && git add . && git commit -q -m 'B: feature'
printf 'fix one\n' > fix1.txt && git add . && git commit -q -m 'C: fix one'
printf 'fix two\n' > fix2.txt && git add . && git commit -q -m 'D: fix two'
git switch -q release/2.1
git cherry-pick -x main~1 main > /dev/null
git switch -q main
```

1. Predict what `git log --oneline --left-right --cherry-mark main...release/2.1` prints: which commits get `=`, which get `<` or `>`.
2. Now the release branch is merged back: `git merge -m "Merge release/2.1 into main" release/2.1`. Does it conflict? Draw `git log --graph --oneline --all` afterwards.
3. How many commits with "fix" in the title does `git log --oneline main` list after the merge? Is that a defect in the history? What does the last line of the backported commits' messages give a reader of that history?

### Exercise 10.7 (Level 3): "The previous cherry-pick is now empty"

A fix from `main` is to be backported to `release/4.0`. Ravi had patched the release branch by hand during an outage. The backport stops with a message that is not a conflict.

<!-- snippet: ex1/ex-m10/e07-evidence -->
```text
$ git log --oneline --graph --all
* 17e90fb Hotfix: timeouts on long documents
| * abec983 Raise the timeout for long documents
| * 67d8555 Add retries
|/  
* 4616cc6 Add client settings
$ git cherry-pick -x main
The previous cherry-pick is now empty, possibly due to conflict resolution.
If you wish to commit it anyway, use:

    git commit --allow-empty

Otherwise, please use 'git cherry-pick --skip'
On branch release/4.0
You are currently cherry-picking commit abec983.
  (all conflicts fixed: run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

nothing to commit, working tree clean
[exit status: 1]
```
<!-- /snippet -->

1. Explain what "empty" means here in terms of the three-way merge that a cherry-pick performs: name the base, ours and theirs, and the result.
2. Git offers two ways on, and there is a third way out. Say what each of the three leaves behind, and which you choose here and why. Name the option of `git cherry-pick` that makes the choice in advance.
3. Which command would have told you, before picking, that this change is already on the release branch? What does it compare, given that the two commits have different IDs and different messages?

### Exercise 10.8 (Level 3): a clean pick that does not work

The commit "Normalize the text before tokenizing" was backported from `main` to `release/1.0`. Git reported success. The release build fails at import time.

<!-- snippet: ex1/ex-m10/e08-evidence -->
```text
$ git cherry-pick -x main
[release/1.0 3350a14] Normalize the text before tokenizing
 Date: Mon Sep 7 12:03:00 2026 +0530
 1 file changed, 3 insertions(+), 1 deletion(-)
$ git status -sb
## release/1.0
$ cat tok.py
from text import normalize

def tokenize(text):
    return normalize(text).split()
$ ls
tok.py
```
<!-- /snippet -->

1. Why did Git see nothing to complain about? State what a cherry-pick guarantees and what it cannot know.
2. Find the missing prerequisite systematically, with commands, not by reading all of `main`. Give at least two different searches.
3. The backport is not pushed. Repair the release branch so that the commits arrive in a sound order, each recording its origin. Then state the rule for backports that this incident illustrates.

### Exercise 10.9 (Level 4): a backport that stopped at its second commit

A cherry-pick of three commits is in progress on a release branch, stopped at a conflict.

```bash
exercises/gen/m10-backport-in-progress/generate.sh
```

Read [exercises/gen/m10-backport-in-progress/SYMPTOMS.md](gen/m10-backport-in-progress/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m10-backport-in-progress/check.sh`. Hand in: how you read which commit is being applied and which are still queued; the three versions of the conflicted file and your resolution; the proof that no feature arrived; and an explanation of what `git cherry -v release/3.2 main` prints for the commit whose conflict you resolved, and what that means for tools that detect backports.

### Exercise 10.10 (Level 5): "the fix is in the release" and "the fix was never backported"

Two engineers contradict each other about a backport, each with a command output that is true. A customer still has the bug.

```bash
exercises/gen/m10-half-backport/generate.sh
```

Read [exercises/gen/m10-half-backport/SYMPTOMS.md](gen/m10-half-backport/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m10-half-backport/check.sh`. Hand in: what each of the two quoted commands proves and what it cannot prove; the comparison that settles which changes of `main` are in the release line; the missing change and its backport; the verification; and two process rules, one for commit messages and one for the release checklist, that would have prevented the incident.
