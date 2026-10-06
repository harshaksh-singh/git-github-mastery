# Exercises for Modules 1 to 5: Foundations

> **Baseline.** Git 2.55.0 on macOS. This file contains questions and tasks only. Every solution, with real transcripts, is in [solutions/exercises-m01-m05.md](../solutions/exercises-m01-m05.md). The transcripts printed in this file are evidence for you to reason about; they are real output from the scripts in `labs/ex1/`.

## How to use these exercises

The labs of the lab manual walk you through each topic with a guide at your side. These exercises take the guide away. Do the labs of a module first, then its exercises, and open the solution of an exercise only after you have written down your own answer. A prediction that you did not write down before running the command teaches nothing.

**Levels.** Every exercise is labelled.

| Level | What you get | What you produce |
|---|---|---|
| 1 | Every command | The commands typed by hand, and one or two sentences on what each result shows |
| 2 | A goal and a few hints, or a setup and a question | The commands, or a written prediction made before you run anything |
| 3 | A situation, sometimes with a transcript as evidence | A diagnosis from first principles: state, mechanism, root cause, lowest-risk fix, prevention |
| 4 | Symptoms only, in a repository built by a script | A repaired repository that passes its `check.sh`, and the root cause in your own words |
| 5 | A production incident with incomplete and partly misleading reports | The same as Level 4, plus a verdict on each claim that was made, with the evidence for it |

**Where to work.** Type every command inside the lab shell, never in your normal shell: the lab shell isolates Git from your real configuration (Chapter 1, section 1.7).

```bash
labs/shell x1          # opens the isolated shell in $GIT_MASTERY_LABS/hands-on/x1
```

Each exercise of Levels 1 to 3 starts with `git init <name>` or `git clone`, so it lives in its own directory below `hands-on/x1`. Delete a directory and start again whenever you like.

**Prediction exercises** (marked *prediction*) give you a setup and ask what a command will print. Type the setup. Write your prediction on paper. Only then run the command. The solution shows the real output and explains it.

**Graph exercises** (marked *draw the graph*) ask for the picture that `git log --graph --oneline` will print: one commit per line, newest first, with the lines that join them. Draw refs and HEAD next to the commits. Then run the command and compare.

**Generated exercises** (Level 4 here) come as a directory under `exercises/gen/`:

```bash
exercises/gen/m01-unborn-main/generate.sh     # builds the sandbox and prints its path
labs/shell "<the path it printed>"            # work there
exercises/gen/m01-unborn-main/check.sh        # from the course root: exit status 0 means solved
```

Read `SYMPTOMS.md` in that directory first. Do not read `generate.sh` before your attempt: the script is the answer to "what happened". Running `generate.sh` again deletes the sandbox and builds it afresh, so a failed attempt costs nothing. `check.sh` only reads; it never changes your sandbox.

**Your commit IDs.** In the lab shell the clock is real, so commits you create have other IDs than the ones in the solutions. Generated sandboxes are the exception: their existing commits are built with the fixed lab clock and have exactly the IDs that the solutions print.

**What a written answer looks like.** From Level 3 on, use the root-cause frame of Chapter 1, section 1.10: what you observed, the Git state behind it, the mechanism, the root cause, the lowest-risk fix, how you verified it, what prevents a repeat. Three sentences that name objects, refs, HEAD and the index beat a page that says "Git got confused".

---

## Module 1: What Git is (Chapters 1 and 2)

Read first: [Chapter 1](../textbook/ch01-fundamentals.md), sections 1.5, 1.9 to 1.11, and [Chapter 2](../textbook/ch02-mental-model.md), sections 2.3 to 2.9. Labs 1.1 to 1.3 come before these exercises.

### Exercise 1.1 (Level 1): one commit, three object types

Create a repository with one file and one commit, and look at every object that the commit consists of.

```bash
git init chunker
cd chunker
printf 'def split(text, size):\n    return [text[i:i+size] for i in range(0, len(text), size)]\n' > chunker.py
git add chunker.py
git commit -m "Add fixed-size splitter"
git cat-file -t HEAD
git cat-file -p HEAD
git cat-file -p "HEAD^{tree}"
git cat-file -t HEAD:chunker.py
git cat-file -p HEAD:chunker.py
find .git/objects -type f | sort
cat .git/HEAD
cat .git/refs/heads/main
```

Write down:

1. The three object IDs, and for each one its type and which other object refers to it.
2. Which two of the three IDs you expect to be identical in the solution and in your terminal, and why the third one differs.
3. The chain of lookups Git performs to get from the word `HEAD` to the text of `chunker.py`.

### Exercise 1.2 (Level 1): Git or GitHub?

No commands. For each item, write the layer that owns it (Git, GitHub, or GitHub Actions), where it is stored, and whether a `git clone` brings it to your machine.

1. A commit
2. A branch
3. A pull request
4. An annotated tag
5. A release with its notes and attached files
6. A fork
7. Your reflog
8. The author name and email on a commit
9. The "Verified" badge next to a commit
10. A file under `.github/workflows/`
11. The log of a workflow run
12. A ruleset that requires one approving review
13. Your `.git/config`
14. A star

Then answer in two sentences: a colleague says "the merge is blocked". Name the three layers that can each block a merge, and one observation that tells them apart.

### Exercise 1.3 (Level 1): the diagnosis ritual on a small state

Continue in the `chunker` repository of Exercise 1.1. Put it into a state with one unstaged change and one staged new file, then run the read-only commands of the ten-command diagnosis.

```bash
printf 'def split(text, size, overlap=0):\n    step = size - overlap\n    return [text[i:i+size] for i in range(0, len(text), step)]\n' > chunker.py
printf 'pytest\n' > requirements-dev.txt
git add requirements-dev.txt
git status
git branch -vv
git remote -v
git log --graph --decorate --oneline --all
git diff --stat
git diff --cached --stat
git ls-files
git config list --show-origin --show-scope
```

For each command write one line: which question about the repository it answers, and which of the places (working tree, index, HEAD, refs, configuration, remote) it reads. Then answer: which two commands together tell you everything that `git status` summarized, and which command printed nothing, and what that silence means.

### Exercise 1.4 (Level 2, prediction): how many objects?

```bash
git init counts
cd counts
printf 'alpha\n' > a.txt
printf 'beta\n' > b.txt
mkdir docs
printf 'alpha\n' > docs/a-copy.txt
git add .
git commit -q -m "First"
printf 'beta v2\n' > b.txt
git commit -q -am "Second"
```

Before you run anything else, predict:

1. How many objects does the object database hold now, and how many of each type (blob, tree, commit)?
2. Which blob is referred to by more than one tree entry, and which tree is referred to by more than one parent object?

Then count them with the command below and explain every number.

```bash
git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
```

### Exercise 1.5 (Level 2, prediction): add twice, commit once

```bash
git init twice
cd twice
printf 'draft 1\n' > note.txt
git add note.txt
printf 'draft 2\n' > note.txt
git add note.txt
git commit -q -m "Add note"
```

Predict before running anything else:

1. How many objects exist, and of which types?
2. Does the text `draft 1` exist anywhere in the repository? If yes, in what form, and which command would find it?
3. What does `git fsck` print?

Then run `git cat-file --batch-all-objects --batch-check='%(objecttype) %(objectname)'`, `git ls-tree HEAD` and `git fsck`, and explain which step of the setup created each object.

### Exercise 1.6 (Level 2, draw the graph): two branches and a tag

```bash
git init graph
cd graph
git commit -q --allow-empty -m A
git commit -q --allow-empty -m B
git branch topic
git commit -q --allow-empty -m C
git switch -q topic
git commit -q --allow-empty -m D
git commit -q --allow-empty -m E
git tag v1 main
git switch -q main
```

Draw what `git log --graph --oneline --all` prints: every commit, the lines between them, and next to the commits the names `main`, `topic`, `v1` and `HEAD`. Then write the content of `.git/HEAD` and the list of refs with the commit each one names. Finally: which commits does `git log --oneline main` list, and why is `E` not among them although it is newer than `C`?

### Exercise 1.7 (Level 3): the same files, two different commit IDs

Asha imported a prompt and a configuration file into a new repository on the CI machine. You did the same on your laptop from the same two files. A colleague compares the two repositories and reports: "The commit IDs differ, so one of the imports is corrupt. We should copy the `.git` directory from one machine to the other to be safe."

The evidence:

<!-- snippet: ex1/ex-m01/e07-evidence -->
```text
$ git -C laptop log --oneline
6ec7b4f Import prompt and config
$ git -C ci-box log --oneline
e88273a Import prompt and config
$ git -C laptop status --short
$ git -C ci-box status --short
```
<!-- /snippet -->

Without changing either repository:

1. State what a commit ID is computed from, and list every input that could differ between the two commits.
2. Name the commands that prove whether the two commits record the same files with the same content. Say what output would mean "identical content" and what would mean "different content".
3. Give your verdict on the colleague's proposal.

### Exercise 1.8 (Level 3): the object that no history shows

Asha wants to keep a tokenizer setting "in Git" without committing it yet. She runs:

```bash
git init vault
cd vault
printf 'v1\n' > notes.txt
git add notes.txt
git commit -q -m "Add notes"
printf '{"lowercase": true, "max_tokens": 512}\n' > tokenizer.json
git hash-object -w tokenizer.json
rm tokenizer.json
```

She notes the ID that `git hash-object` printed and tells the team: "The settings are in the repository now, `git cat-file -p` on that ID prints them. Clone it and you have them." A teammate clones the repository over the network and cannot find the object. `git log --all -- tokenizer.json` prints nothing in either repository.

Reproduce the setup, then:

1. Explain in terms of objects, trees, commits and refs what is in Asha's repository and what is not.
2. Predict what `git fsck` prints in Asha's repository, and whether a clone made through Git's transport (`git clone --no-local . ../vault-copy`) contains the object. Then test both.
3. Make the settings part of history **without recreating the file by hand**: the blob already exists, so attach it. Verify with `git ls-tree -r HEAD` and `git fsck`.

### Exercise 1.9 (Level 4): "git log says there are no commits"

A repository that had three commits on Friday reports "no commits yet" on Monday.

```bash
exercises/gen/m01-unborn-main/generate.sh
```

Read [exercises/gen/m01-unborn-main/SYMPTOMS.md](gen/m01-unborn-main/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m01-unborn-main/check.sh`. Hand in: the evidence you collected with read-only commands, the root cause in one sentence that names the file or ref that is wrong, the repair, and the reason why no object was ever in danger.

---

## Module 2: Working tree, index, HEAD (Chapters 4 and 5)

Read first: [Chapter 4](../textbook/ch04-working-tree.md), sections 4.3 to 4.9 and 4.14, and [Chapter 5](../textbook/ch05-index.md), sections 5.2 to 5.12. Labs 2.1 to 2.4 come before these exercises.

### Exercise 2.1 (Level 1): every short status code, made on purpose

Build a repository with six tracked files, then put each file into a different state and read the two-column code that `git status --short` prints for it.

```bash
git init label-audit
cd label-audit
printf 'def audit(rows):\n    return [r for r in rows if r.label is None]\n' > audit.py
printf 'id,label\n1,spam\n2,ham\n' > labels.csv
printf '# label-audit\n' > README.md
printf 'rule: none\n' > old_rules.txt
printf 'def legacy():\n    pass\n' > legacy.py
printf 'def load(path):\n    return open(path).read().splitlines()\n' > loader.py
git add .
git commit -q -m "Import label audit"

printf 'ideas\n' > notes.md
printf 'def report(rows):\n    return len(rows)\n' > report.py
git add report.py
printf 'def audit(rows):\n    return [r for r in rows if not r.label]\n' > audit.py
printf '# label-audit\n\nFinds rows without a label.\n' > README.md
git add README.md
printf 'id,label\n1,spam\n2,ham\n3,spam\n' > labels.csv
git add labels.csv
printf 'id,label\n1,spam\n2,ham\n3,spam\n4,ham\n' > labels.csv
rm old_rules.txt
git rm -q legacy.py
git mv loader.py reader.py
git status --short
git status
```

Make a table with one row per path: the two-character code, what the left column compares, what the right column compares, and under which heading the path appears in the long form. Which path appears under two headings of the long form, and why is that not a contradiction?

### Exercise 2.2 (Level 1): which rule ignores which path

```bash
git init ignore-rules
cd ignore-rules
printf '*.log\n/build/\ndata/*\n!data/README.md\n.env*\n!.env.example\n' > .gitignore
cat -n .gitignore
git check-ignore -v -n app.log logs/app.log build/out.bin src/build/out.bin data/train.csv data/README.md .env.local .env.example
```

None of the eight paths has to exist: `git check-ignore` evaluates the rules against names. For every path write: ignored or not, the line of `.gitignore` that decided it, and what the syntax of that line means (a leading `/`, a trailing `/`, a `*`, a leading `!`). One path is reported with an empty rule: explain why no rule applies to it.

### Exercise 2.3 (Level 1): three diffs, three comparisons

```bash
git init three-diffs
cd three-diffs
printf 'min_agreement: 0.80\n' > thresholds.yaml
git add thresholds.yaml
git commit -q -m "Add thresholds"
printf 'min_agreement: 0.85\n' > thresholds.yaml
git add thresholds.yaml
printf 'min_agreement: 0.90\n' > thresholds.yaml
git diff
git diff --cached
git diff HEAD
```

For each of the three commands name the two things it compares and the value that each side holds. Then say which of the three diffs would become the next commit if you ran `git commit` now, and which would become it if you ran `git commit -a`.

### Exercise 2.4 (Level 2, prediction): what does the commit contain?

```bash
git init staged
cd staged
printf 'retries: 1\n' > job.yaml
git add job.yaml
git commit -q -m "Add job config"
printf 'retries: 2\n' > job.yaml
git add job.yaml
printf 'retries: 3\n' > job.yaml
git commit -q -m "Raise retries"
```

Predict the output of each of these commands, then run them:

```bash
git show HEAD:job.yaml
cat job.yaml
git status --short
git diff
```

Explain the result as a statement about which of the three places `git commit` reads.

### Exercise 2.5 (Level 2, prediction): a negated pattern that does not work

```bash
git init ignore-trap
cd ignore-trap
mkdir -p data/raw models
printf 'x\n' > data/raw/a.csv
printf 'Run scripts/fetch.sh to download the data.\n' > data/README.md
printf 'weights\n' > models/best.ckpt
printf 'weights\n' > models/tiny.ckpt
printf 'data/\n!data/README.md\n*.ckpt\n!models/tiny.ckpt\n' > .gitignore
```

The author of this `.gitignore` wants Git to see exactly three new files: `.gitignore`, `data/README.md` and `models/tiny.ckpt`.

1. Predict what `git status --short --untracked-files=all` lists.
2. One of the two `!` lines has an effect and the other has none. Predict which, and say what `git check-ignore -v` prints for `data/README.md` and for `models/tiny.ckpt`.
3. Change one line of `.gitignore` so that the intention is met, and prove it with the same two commands.

### Exercise 2.6 (Level 2): a move and an edit, as two commits

A repository has one file, `train.py`, with a training loop. You must move it to `trainer/run.py` and change one line of it (print one-based epoch numbers). A reviewer wants the history to show the move as a move.

```bash
git init split-rename
cd split-rename
printf 'import json\n\n\ndef train(config_path):\n    config = json.load(open(config_path))\n    epochs = config["epochs"]\n    for epoch in range(epochs):\n        print("epoch", epoch)\n    return epochs\n' > train.py
git add train.py
git commit -q -m "Add training loop"
```

Goal: two commits. The first contains the move and nothing else, and `git show --stat` reports it as a rename with zero changed lines. The second contains the one-line edit. Afterwards one `git log` command must list all three commits of the file's life, across the move.

Hints: `git mv`; `git status --short` shows what the index thinks happened; one option of `git log` follows a single file across renames. Write down what Git stored to "remember" the rename.

### Exercise 2.7 (Level 3): "git restore ." did not throw everything away

You tried three things in a configuration repository and want all of them gone.

```bash
git init discard
cd discard
printf 'k: 5\n' > retrieval.yaml
printf 'model: small\n' > model.yaml
git add .
git commit -q -m "Add configs"
printf 'k: 50\n' > retrieval.yaml
printf 'model: large\n' > model.yaml
git add model.yaml
printf 'scratch\n' > notes.md
git status --short
git restore .
git status --short
```

After `git restore .` one of the three experiments is gone and two are still there.

1. Explain, for each of the three paths, what `git restore .` did or did not do, in terms of the source it copies from, the destination it writes to, and which paths the pathspec `.` covers.
2. Finish the job: return the repository to exactly the committed state. Preview every step that can destroy something before you run it, and say which of your commands is the one with no undo.
3. Which single habit would have made the whole clean-up unnecessary?

### Exercise 2.8 (Level 3): the commit that took more than was staged

In `metrics.py` you made two changes: a real fix at the top of the file and an experiment at the bottom. You also staged a README change that belongs to a later commit. You want to commit the fix alone.

```bash
git init partial
cd partial
printf 'def exact_match(a, b):\n    return a == b\n\n\n\n\n\n\n\ndef normalize(s):\n    return s\n' > metrics.py
printf '# metrics\n' > README.md
git add .
git commit -q -m "Add metrics"
printf 'def exact_match(a, b):\n    return normalize(a) == normalize(b)\n\n\n\n\n\n\n\ndef normalize(s):\n    return s.strip().lower()  # experiment: also strip punctuation?\n' > metrics.py
printf '# metrics\n\nExact match after normalization.\n' > README.md
git add README.md
git add -p metrics.py          # answer y for the first hunk, n for the second
git status --short
git commit -m "Compare normalized strings" metrics.py
git status --short
git show --format=%s HEAD
```

The reasoning behind the last command was: "the right half of `metrics.py` is staged, so I name the file to leave the README out". Look at what the commit contains.

1. State exactly what `git commit <path>` records, and where the careful `git add -p` went.
2. The commit is not pushed. Repair it: one commit with the fix only; the experiment still in the working tree, unstaged; the README change staged again for later. Nothing in the repair needs to destroy uncommitted work: say which reset mode you use, and why the other two would be wrong here.
3. Which command would have done the right thing in the first place?

### Exercise 2.9 (Level 4): "Git does not see my edits"

Two files were edited, the edits are on disk, and no Git command admits that anything changed.

```bash
exercises/gen/m02-invisible-edit/generate.sh
```

Read [exercises/gen/m02-invisible-edit/SYMPTOMS.md](gen/m02-invisible-edit/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m02-invisible-edit/check.sh`. Hand in: the evidence that rules out `.gitignore` and a corrupt index, the root cause, the repair, your justification for the one file you treated differently, and the mechanism the team should use instead for per-machine settings.

---

## Module 3: Commits (Chapter 6)

Read first: [Chapter 6](../textbook/ch06-commits.md), sections 6.2 to 6.10 and 6.13. Labs 3.1 to 3.3 come before these exercises.

### Exercise 3.1 (Level 1): read a commit field by field

```bash
git init batch-scorer
cd batch-scorer
printf 'def score(batch):\n    return [len(x) for x in batch]\n' > scorer.py
git add scorer.py
git commit -q -m "Add batch scorer"
printf 'def score(batch):\n    return [len(x.strip()) for x in batch]\n' > scorer.py
git commit -q -am "Ignore surrounding whitespace when scoring"
git cat-file -p HEAD
git rev-parse HEAD "HEAD^{tree}" HEAD~1
git show -s --format=fuller HEAD
```

Label every line of the `git cat-file -p HEAD` output: what the field is, and which other object or person it refers to. Match each of the three IDs printed by `git rev-parse` to a line of the commit object. Which part of what `git show --format=fuller` prints is not stored in the commit object at all, and where does it come from?

### Exercise 3.2 (Level 1): author and committer

Continue in `batch-scorer`. You apply a change that Asha wrote last week.

```bash
printf 'def mean(xs):\n    return sum(xs) / len(xs)\n' > stats.py
git add stats.py
git commit -q --author='Asha Rao <asha@example.com>' --date='2026-09-01T09:00:00+05:30' -m 'Add mean helper'
git show -s --format=fuller HEAD
git log --format='%h | author %an, %ad | committer %cn, %cd' --date=short
git log --oneline --author=Asha
git log --oneline --committer=Asha
```

Write down who is recorded as author and as committer, and with which dates. Explain the result of the last two commands. Name two everyday Git operations that produce commits whose author and committer differ without anyone typing `--author`.

### Exercise 3.3 (Level 1): zero, one and two parents

Continue in `batch-scorer`.

```bash
git switch -q -c feature/median
printf 'def median(xs):\n    return sorted(xs)[len(xs) // 2]\n' >> stats.py
git commit -q -am "Add median helper"
git switch -q main
git merge -q --no-ff -m "Merge feature/median" feature/median
git log --graph --oneline
git rev-list --parents -n 1 HEAD
git rev-list --parents -n 1 HEAD~1
git rev-list --parents -n 1 --max-parents=0 HEAD
git show -s --format=%s 'HEAD^1'
git show -s --format=%s 'HEAD^2'
```

`git rev-list --parents` prints a commit ID followed by the IDs of its parents. Say how many parents each of the three commits has and what each kind of commit is called. Explain the difference between `HEAD^2` and `HEAD~2` on this history, and say which of the two would be an error on a history without merges.

### Exercise 3.4 (Level 2, prediction): a commit that changes nothing

```bash
git init rerun
cd rerun
printf 'schedule: nightly\n' > pipeline.yaml
git add pipeline.yaml
git commit -q -m "Add pipeline"
git commit -q --allow-empty -m "Trigger a re-run of the nightly evaluation"
```

Predict:

1. Are the tree IDs of the two commits equal or different? (`git rev-parse "HEAD^{tree}" "HEAD~1^{tree}"`)
2. What does `git show --stat --format="%h %s" HEAD` print below the title line?
3. What is the exit status of `git diff --quiet HEAD~1 HEAD`?
4. How many object files are in `.git/objects` after the two commits?

Then verify, and say what the empty commit consists of and why it still has an ID of its own.

### Exercise 3.5 (Level 2, prediction): which date is shown, which date filters?

```bash
git init dates
cd dates
printf 'x\n' > a.txt
git add a.txt
git commit -q --date='2026-08-01T12:00:00+00:00' -m 'Backdated work'
```

The commit was created today with an author date of 1 August 2026. Predict:

1. Which date does `git log -1` print on its `Date:` line?
2. Does `git log --oneline --since=2026-08-15` list the commit?
3. Does `git log --oneline --until=2026-08-15` list it?

Then run the three commands and `git log -1 --format='author date:    %ad%ncommitter date: %cd'`. State the rule, and describe one report in a real team that this rule silently distorts.

### Exercise 3.6 (Level 2): two atomic commits and a trailer

The working tree of this repository holds two unrelated changes.

```bash
git init atomic
cd atomic
printf 'def retry(call, attempts):\n    for i in range(attempts):\n        try:\n            return call()\n        except TimeoutError:\n            pass\n' > retry.py
printf '# retry\n\nRetries a call on timeout.\n' > README.md
git add .
git commit -q -m "Add retry helper"
printf 'def retry(call, attempts):\n    for i in range(attempts):\n        try:\n            return call()\n        except TimeoutError:\n            pass\n    raise TimeoutError("all attempts timed out")\n' > retry.py
printf '# retry\n\nRetries a call on timeout.\n\n## Development\n\nRun the tests with python3 -m unittest.\n' > README.md
```

Goal: two commits, each of which could be reverted or cherry-picked on its own. The commit with the bug fix has a title in the imperative of at most 50 characters, a body that says why the old behavior was wrong, and a `Co-authored-by` trailer for Asha Rao (`asha@example.com`) that Git's trailer tooling recognizes. Verify with `git log --stat -2` and by extracting the trailer value with a `--format` placeholder.

Hints: `git commit` accepts `-m` more than once; one option of `git commit` adds a trailer in the right place; `%(trailers:key=...,valueonly)`.

### Exercise 3.7 (Level 3): one ahead, one behind, and nobody else pushed

You are the only person who works on this repository today. You pushed a commit, noticed something, did "a small correction", and now:

<!-- snippet: ex1/ex-m03/e07-evidence -->
```text
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git push
To $LAB/ex1/ex-m03/origin.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '$LAB/ex1/ex-m03/origin.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git log --oneline --graph --all
* a0939f2 Add maximum batch size
| * ed78368 Add maximum batch sise
|/  
* fcf77d2 Add pass mark
```
<!-- /snippet -->

1. Nobody else pushed. Where does the commit that you are "behind" come from? Name the command you must have run and the evidence that would prove it. Name the command that shows that evidence.
2. Predict whether the two commits record the same files, and how you would check without reading a diff.
3. The hint in the push output recommends `git pull`. Describe the history that following it would produce.
4. Give the correct way out for each of two cases: (a) a colleague may already have fetched the pushed commit; (b) the branch is provably yours alone. Say what decides between them.

### Exercise 3.8 (Level 3): the commit that `--author` does not find

An auditor asks: "Which commits did Asha put on `main` last week?" You run the obvious command and it finds nothing, although Asha says she landed the burst-quota change herself.

<!-- snippet: ex1/ex-m03/e08-evidence -->
```text
$ git log --oneline
e6d3501 Add README
23cd6fe Allow a burst above the quota
161cdd6 Add quota
$ git log --oneline --author=Asha
$ git log --oneline --author=Ravi
23cd6fe Allow a burst above the quota
```
<!-- /snippet -->

1. Explain how a commit can be "landed by Asha" and still not match `--author=Asha`.
2. Give the command that answers the auditor's question, and the command that shows both people and both dates for the commit in question.
3. The auditor's real question is about a time window ("last week"). Which of the two dates of a commit does `git log --since` use, and why is that the right one for this question?

### Exercise 3.9 (Level 4): a commit made on the meeting-room laptop

The last commit of a branch has the wrong author, a file that must not be in it, and a misspelled title. Nothing has been pushed.

```bash
exercises/gen/m03-wrong-commit/generate.sh
```

Read [exercises/gen/m03-wrong-commit/SYMPTOMS.md](gen/m03-wrong-commit/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m03-wrong-commit/check.sh`. Hand in: the proof that the commit is private, the commands of the repair, a field-by-field comparison of the old and the new commit (which fields changed, which did not, and why the ID had to change), and where the old commit lives now.

---

## Module 4: Refs, branches, HEAD (Chapter 7)

Read first: [Chapter 7](../textbook/ch07-branches.md), sections 7.2 to 7.13. Labs 4.1 to 4.4 come before these exercises.

### Exercise 4.1 (Level 1): a branch, and the file behind each step

```bash
git init model-router
cd model-router
printf 'routes:\n  default: small\n' > routes.yaml
git add routes.yaml
git commit -q -m "Add default route"
git branch feature/fallback
git branch -v
cat .git/refs/heads/feature/fallback
git rev-parse main
git branch -m feature/fallback feature/fallback-route
find .git/refs/heads -type f | sort
git branch -d feature/fallback-route
find .git/refs/heads -type f | sort
```

After each of `git branch <name>`, `git branch -m` and `git branch -d`, say what changed under `.git/refs/heads` and what did not change anywhere else (objects, HEAD, index, working tree). How many bytes of project data did creating the branch copy?

### Exercise 4.2 (Level 1): HEAD follows you

Continue in `model-router`.

```bash
cat .git/HEAD
git switch -c fix/timeout
cat .git/HEAD
printf 'routes:\n  default: small\ntimeout_s: 30\n' > routes.yaml
git commit -q -am "Add request timeout"
git branch -v
git switch -
git symbolic-ref HEAD
git rev-parse --abbrev-ref HEAD '@{-1}'
git branch -v
```

Write down the content of `.git/HEAD` at each point, which ref the commit moved and which it left alone, and what `-` and `@{-1}` stand for. From where does Git know the branch you were on before?

### Exercise 4.3 (Level 1): a lightweight tag is a ref that does not move

Continue in `model-router`, on `main`.

```bash
git tag v0.1.0
cat .git/refs/tags/v0.1.0
printf '# model-router\n' > README.md
git add README.md
git commit -q -m "Add README"
git rev-parse v0.1.0 main
git log --oneline --decorate --all
git cat-file -t v0.1.0
```

Compare what the commit did to `main` with what it did to `v0.1.0`. A branch and a lightweight tag are both files that hold one commit ID: state the one behavioral difference between them, and say which command's behavior creates it.

### Exercise 4.4 (Level 2, draw the graph): a commit made while HEAD was detached

```bash
git init detached
cd detached
git commit -q --allow-empty -m A
git commit -q --allow-empty -m B
git commit -q --allow-empty -m C
git switch -q --detach HEAD~1
git commit -q --allow-empty -m X
git switch main
```

1. Draw what `git log --graph --oneline --all` prints after the last command. Think about `--all` before you draw: all of what?
2. Is commit `X` still in the object database? Name two places where its ID can still be found.
3. Give the one command that makes `X` appear in the `--all` graph, and draw the graph again.

### Exercise 4.5 (Level 2, prediction): which branches may be deleted?

```bash
git init cleanup
cd cleanup
git commit -q --allow-empty -m A
git branch done-1
git switch -q -c done-2
git commit -q --allow-empty -m D2
git switch -q main
git merge -q done-2
git switch -q -c open-1
git commit -q --allow-empty -m O1
git switch -q main
git commit -q --allow-empty -m B
```

Predict the output of each command, then run them in this order:

```bash
git branch --merged main
git branch --no-merged main
git branch -d done-1 done-2 open-1
git branch
```

For the third command predict which branches are deleted, which is refused, the wording of the refusal, and the exit status. State the test that `git branch -d` applies, as a sentence about reachability.

### Exercise 4.6 (Level 2, draw the graph): from which branch was it created?

```bash
git init lineage
cd lineage
git commit -q --allow-empty -m A
git commit -q --allow-empty -m B
git switch -q -c feature/a
git commit -q --allow-empty -m C
git switch -q -c feature/b
git commit -q --allow-empty -m D
git switch -q main
git commit -q --allow-empty -m E
git branch feature/c feature/a
```

1. Draw what `git log --graph --oneline --all` prints, with all four branch names and HEAD.
2. A teammate asks: "Was `feature/b` created from `main` or from `feature/a`?" Say what the commit graph can answer and what it cannot. Then look for the answer in two other places, the branch's reflog and the repository configuration, and report what each of them holds.
3. `feature/a` and `feature/c` name the same commit. Is one of them "the original"? What would Git have to store for that question to have an answer?

### Exercise 4.7 (Level 3): one switch carries the edit, the next one refuses

```bash
git init carry
cd carry
printf 'timeout_s: 30\n' > router.yaml
printf 'model: small\n' > model.yaml
git add .
git commit -q -m "Add configs"
git switch -q -c exp/large-model
printf 'model: large\n' > model.yaml
git commit -q -am "Try the large model"
git switch -q main

printf 'timeout_s: 60\n' > router.yaml
git switch exp/large-model
git switch main
git restore router.yaml
printf 'model: medium\n' > model.yaml
git switch exp/large-model
```

The first `git switch exp/large-model` succeeds with an uncommitted edit in the working tree and takes the edit along. The last one, with an uncommitted edit of the same kind, is refused.

1. State the rule that decides between the two outcomes. Which command shows, before you switch, the set of paths for which a local edit will block the switch?
2. What exactly would be lost if Git performed the second switch the way it performed the first?
3. Name three ways to proceed and the risk of each. Carry out the one with the lowest risk.

### Exercise 4.8 (Level 3): the deploy script that picks the wrong commit

A deploy script runs `git rev-parse release-1.0` and deploys the commit it prints. After a hotfix on the branch `release-1.0`, the script still deploys the commit without the hotfix. Nobody changed the script.

<!-- snippet: ex1/ex-m04/e08-evidence -->
```text
$ git branch -v
* main        262e673 Start 1.1
  release-1.0 d794d7f Hotfix: clamp temperature
$ git rev-parse --short release-1.0
warning: refname 'release-1.0' is ambiguous.
12c6b92
$ git log --oneline -1 release-1.0
warning: refname 'release-1.0' is ambiguous.
12c6b92 Release 1.0
```
<!-- /snippet -->

1. `git branch -v` and `git rev-parse` disagree about `release-1.0`. Explain how both can be right, and name the command that lists everything that could be meant by that name.
2. State the order in which Git resolves a short name, and the two spellings that are never ambiguous.
3. Repair the repository so that the script works again without a warning and no released commit loses its name. Then give the one-line change that makes the script itself immune.

### Exercise 4.9 (Level 4): three commits on the wrong branch

Finished work sits on `main`, the server refuses the push, and an uncommitted edit must not be lost.

```bash
exercises/gen/m04-wrong-branch/generate.sh
```

Read [exercises/gen/m04-wrong-branch/SYMPTOMS.md](gen/m04-wrong-branch/SYMPTOMS.md), work in the sandbox, and finish with `exercises/gen/m04-wrong-branch/check.sh`. Hand in: the read-only evidence, the repair as a sequence of ref movements (which ref, from which commit, to which commit, by which command), the reason why no commit ID changed, and the reason why the uncommitted edit was never at risk with your method. Name one popular alternative that would have put it at risk.

---

## Module 5: Configuration (Chapter 14B, sections 14B.2 to 14B.7)

Read first: [Chapter 14B](../textbook/ch14b-config-tags-signing.md), sections 14B.2 to 14B.7, and [Chapter 6](../textbook/ch06-commits.md), section 6.13 for identities. Labs 5.1 to 5.4 come before these exercises.

**The Module 5 preamble.** The lab shell points `GIT_CONFIG_GLOBAL` at one file that all hands-on work shares. These exercises change global settings on purpose, so each of them gets a home directory and a global file of its own. Start **every** exercise of this module, Levels 1 to 3, in a new empty directory with these lines:

```bash
mkdir m05-ex1 && cd m05-ex1          # one directory per exercise: m05-ex1, m05-ex2, ...
mkdir -p home
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
git config set --global user.name "Lab User"
git config set --global user.email you@example.com
git config set --global init.defaultBranch main
```

From then on `~` and `git config --global` mean that directory, in that shell, until you type `exit`. Your real `~/.gitconfig` is never involved. The `git config get`, `set`, `unset` and `list` subcommands need Git 2.46 or later.

### Exercise 5.1 (Level 1): one key in the local file

After the preamble:

```bash
git init -q svc
cd svc
git config set pull.ff only
git config get pull.ff
cat .git/config
git config unset pull.ff
git config get pull.ff; echo "status: $?"
git config unset pull.ff; echo "status: $?"
cat .git/config
```

Say which file `git config set` wrote to without any scope option, what the file looked like before and after, and what the two exit statuses mean. Why is the exit status of `get` the right thing for a script to test, and not its output?

### Exercise 5.2 (Level 1): scope and origin of one key

After the preamble:

```bash
git init -q svc
cd svc
git config set --global merge.conflictStyle zdiff3
git config set merge.conflictStyle diff3
git config get --all --show-scope --show-origin merge.conflictStyle
git config get merge.conflictStyle
git -c merge.conflictStyle=merge config get --show-scope merge.conflictStyle
cd ..
git config get --show-scope merge.conflictStyle
```

For each `get`, name the value that wins and the reason. Put the four scopes you met (and the one you did not) into their order of precedence.

### Exercise 5.3 (Level 1): typed values

After the preamble:

```bash
git init -q svc
cd svc
git config set core.bigFileThreshold 1m
git config get core.bigFileThreshold
git config get --type=int core.bigFileThreshold
git config set fetch.prune yes
git config get --type=bool fetch.prune
git config get --type=bool core.bigFileThreshold; echo "status: $?"
git config get --type=int fetch.prune; echo "status: $?"
git config set --global core.excludesFile '~/.gitignore-global'
git config get core.excludesFile
git config get --type=path core.excludesFile
```

Git stores every value as text. For each `--type` call, say what the conversion did. One of the calls returns a result that you may not expect and one fails: describe both, and say what the first one tells you about how Git reads a number where it wants a boolean.

### Exercise 5.4 (Level 2, prediction): four sources for one identity

After the preamble:

```bash
git config set --global user.email global@example.com
git init -q who
cd who
git config set user.email local@example.com
git commit -q --allow-empty -m one
GIT_AUTHOR_EMAIL=env@example.com git -c user.email=cli@example.com commit -q --allow-empty -m two
```

Predict the two lines that this command prints:

```bash
git log --format='%s: author %ae, committer %ce'
```

Four addresses were in play for commit `two`. For each of author and committer, say which one won and which rule decided it.

### Exercise 5.5 (Level 2, prediction): unset, and the position of an include

After the preamble. Part A:

```bash
git config set --global pull.rebase true
git init -q scopes
cd scopes
git config set pull.rebase false
git config unset pull.rebase
```

Predict the output and the exit status of each of these, in this order: `git config get --show-scope pull.rebase`, then `git config unset pull.rebase`, then `git config get --show-scope pull.rebase` again.

Part B, in the same shell:

```bash
printf '[core]\n\teditor = nano\n' > ~/extra.gitconfig
git config set --global core.editor vim
git config set --global include.path '~/extra.gitconfig'
```

Predict what `git config get core.editor` prints, and what `git config get --all --show-origin core.editor` lists and in which order. Then look at `cat ~/.gitconfig` and state the rule. What would you have to change, without removing either setting, for the other editor to win?

### Exercise 5.6 (Level 2): two aliases

After the preamble, build a repository to try them on:

```bash
git init -q branches
cd branches
mkdir -p src/router
printf 'x\n' > src/router/a.py
git add .
git commit -q -m "Add router"
git switch -q -c feature/fallback
git commit -q --allow-empty -m "Add fallback"
git switch -q -c fix/timeout main
git commit -q --allow-empty -m "Fix timeout"
git switch -q main
```

Goal:

1. A global alias `git recent` that lists the local branches, most recently committed first, each with the age of its last commit and its name.
2. A global alias `git where` that prints one line of the form `<current branch> at <short commit ID> in <directory>`, built from more than one command.

Run `git where` from `src/router` and explain the directory it prints. Then list both aliases with one `git config` command.

Hints: `git branch` has `--sort` and `--format`; an alias whose value starts with `!` is run by the shell; mind the quoting, the `$(...)` must reach the configuration file unexpanded.

### Exercise 5.7 (Level 3): the include is there and the work address is not used

A colleague set up a conditional include so that every repository under `~/work/` uses the company address. Commits in `~/work/billing-llm` still carry the personal address. They have checked three things: the pattern ends with a slash, the included file exists, and the repository's `.git` directory lies under `~/work/`.

<!-- snippet: ex1/ex-m05/e07-evidence -->
```text
$ cat ~/.gitconfig
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work
[user]
	name = Lab User
	email = lab.user@personal.example
[init]
	defaultBranch = main
$ cat ~/.gitconfig-work
[user]
	email = lab.user@corp.example
$ git rev-parse --absolute-git-dir
$LAB/ex1/ex-m05/m05-ex7/home/work/billing-llm/.git
$ git log -1 --format='%an <%ae>  %s'
Lab User <lab.user@personal.example>  Add invoice prompt
```
<!-- /snippet -->

1. All three checks are correct. Find the cause in the evidence and state the rule of Git's configuration that it follows from.
2. Name the one `git config` command whose output shows the cause without reading any file, and say what you expect it to print.
3. Give the fix, and the repair of the commit that was already made with the wrong address (it is not pushed).

### Exercise 5.8 (Level 3): the configuration is right and the commit is wrong

In `~/work/invoice-ocr` the configuration lists exactly one `user.email`, the company address. The commit that was made a minute ago carries a different address, from a previous employer.

<!-- snippet: ex1/ex-m05/e08-evidence -->
```text
$ git config get --all --show-scope --show-origin user.email
global	file:$LAB/ex1/ex-m05/m05-ex8/home/.gitconfig	lab.user@corp.example
$ git log -1 --format='author %an <%ae>, committer %cn <%ce>'
author Lab User <lab.user@old-startup.example>, committer Lab User <lab.user@old-startup.example>
```
<!-- /snippet -->

1. The configuration is not the source of the address. List every other source from which Git takes the author and the committer identity, in order of precedence.
2. Name the command that prints the identity the **next** commit would get, and the command that finds the culprit.
3. Give the fix for the shell, the place where such a setting typically hides so that it comes back tomorrow, and the repair of the commit.

### Exercise 5.9 (Level 4): two work repositories, two wrong addresses

The company server rejects commits from two repositories on one laptop, each for a different wrong address.

```bash
exercises/gen/m05-two-identities/generate.sh
```

Read [exercises/gen/m05-two-identities/SYMPTOMS.md](gen/m05-two-identities/SYMPTOMS.md) (it starts with the first step that replaces the Module 5 preamble in a generated sandbox), work in the sandbox, and finish with `exercises/gen/m05-two-identities/check.sh`. Hand in: for each repository the command output that shows where its address comes from, each cause with the configuration rule behind it, the repair of the configuration and of the two commits, and one setting that would have turned both silent failures into an error at commit time.
