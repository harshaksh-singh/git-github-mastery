# Exercises, Modules 11 to 15: investigation, recovery, tags, hooks and attributes, submodules and LFS

> **Baseline.** Git 2.55.0 and git-lfs 3.7.1 on macOS. Every exercise was run on that version; the model answers in [solutions/exercises-m11-m15.md](../solutions/exercises-m11-m15.md) are real transcripts. This file contains no answers. Open the solutions only after you have written your own answer down.

## How to use these exercises

**The five levels.**

| Level | What you get | What is expected of you |
|---|---|---|
| 1 | Instructions | Run them, observe, and answer the questions in writing |
| 2 | A goal and a few hints, or a prediction to make | Choose the commands yourself; for predictions, write the output down before you run anything |
| 3 | A situation | Diagnose it independently, state the root cause, fix it, say how to prevent it |
| 4 | Symptoms only, in a generated repository | Investigate, repair, and pass a check script |
| 5 | A production incident with incomplete and partly misleading evidence | Test every claim before you believe it, repair, pass the check, and write the report |

Modules 11 and 12 carry the weight of this file: two Level 4 exercises each, one Level 5 in Module 11 and two in Module 12.

**Sandboxes.** Every exercise works in a generated sandbox. From the course root:

```bash
exercises/gen/m11-docsplit/generate.sh        # prints the path of the sandbox
labs/shell "<the path it printed>"            # an isolated shell: your real Git configuration is never touched
```

Running a generator again deletes its sandbox and builds it afresh, so you can repeat an exercise as often as you like. One generator per module builds the repositories for exercises 1 to 8 (one directory per exercise where the exercises change state); each Level 4 and Level 5 exercise has its own generator.

**Commit IDs.** The generators pin the clock, so the commits that they create have the same IDs on your machine as in the solutions. Commits that you create in the lab shell use the real clock and get other IDs. Reflog selectors such as `HEAD@{2}` do not depend on the clock.

**Check scripts.** Level 4 and Level 5 exercises end with `exercises/gen/<name>/check.sh`, run from the course root. It reads the sandbox, changes nothing, lists what is still wrong, and exits with status 0 when the end state is right. The generator script is the answer to "what happened": read `SYMPTOMS.md`, not `generate.sh` and not `check.sh`.

**The expiry settings.** The lab configuration sets `gc.reflogExpire` and `gc.reflogExpireUnreachable` to `never` (Chapter 1, section 1.7 explains why). Where an exercise needs expiry, it uses cut-offs that do not depend on a clock: `--expire=now` and `--prune=now`. Real repositories use the defaults of Chapter 13, section 13.4.

**Written answers.** Levels 3 to 5 ask for a root cause. Use the root-cause framework of Chapter 1, section 1.10: observed behavior, Git state, mechanism, root cause, fix, verification, prevention. A command without the reason for it is half an answer.

| Module | Level 1 | Level 2 | Level 3 | Level 4 | Level 5 |
|---|---|---|---|---|---|
| 11 History investigation | 11.1, 11.2, 11.3 | 11.4 (prediction), 11.5, 11.6 | 11.7, 11.8 | 11.9, 11.10 | 11.11 |
| 12 Recovery | 12.1, 12.2, 12.3 | 12.4 (prediction), 12.5, 12.6 (graph) | 12.7, 12.8 | 12.9, 12.10 | 12.11, 12.12 |
| 13 Tags and versions | 13.1, 13.2, 13.3 | 13.4 (prediction), 13.5 (prediction), 13.6 (graph) | 13.7, 13.8 | 13.9 | |
| 14 Worktrees, attributes, hooks, stash, rerere | 14.1, 14.2, 14.3 | 14.4 (graph), 14.5, 14.6 (prediction) | 14.7, 14.8 | 14.9 | |
| 15 Submodules, subtrees, LFS | 15.1, 15.2, 15.3 | 15.4 (prediction), 15.5 (graph), 15.6 (prediction) | 15.7, 15.8 | 15.9 | |

---

## Module 11: History investigation

Chapter: [14A, History investigation](../textbook/ch14a-history-investigation.md). Labs 11.1 to 11.7 come first; these exercises use other histories.

Exercises 11.1 to 11.8 share one repository, `docsplit`, a library that cuts documents into chunks for a retrieval pipeline:

```bash
exercises/gen/m11-docsplit/generate.sh
```

It has three authors (you, Asha Rao, Ravi Menon), commits from Monday 7 to Thursday 10 September 2026, the tags `v0.1.0`, `v0.2.0` and `v0.3.0`, two merges, and one branch that is not merged, `feat/markdown`. Begin every session with `git log --graph --oneline --all` and keep the picture in front of you. None of these exercises needs a commit; if you change something, `git status` tells you how to put it back.

### Exercise 11.1 (Level 1): Four questions for the log

**Do.** Run each command and read all of its output.

```bash
git log --oneline --author=Asha
git log --oneline -- docsplit/config.py
git log --oneline --merges
git log --format='%h %ad %an: %s' --date=format:'%a %H:%M' --since='2026-09-09 00:00' --until='2026-09-09 23:59'
```

**Answer in writing.**

1. How many commits did Asha write, and how many of them touch `docsplit/config.py`? Which single command would answer the second part?
2. The first command lists a commit that is not on the first-parent line of `main`. Which one, and how did it get into the output?
3. `--since` and `--until` compare with one of a commit's two dates. Which one? Name a commit in this repository for which the two dates differ, and say what created the difference.
4. Why does the fourth command give a time of day in both limits instead of a bare date?

### Exercise 11.2 (Level 1): The pickaxe, twice

**Do.**

```bash
git log --oneline -S'OVERLAP'
git log --oneline -G'OVERLAP'
```

For every commit that only the second command lists, run `git show <commit> -- docsplit/config.py`.

**Answer in writing.**

1. State in one sentence each what `-S` and `-G` test for.
2. Explain, for each commit that only `-G` lists, why `-S` leaves it out. Use the diff you looked at.
3. You want every commit that changed the *value* of `OVERLAP`. Which option do you use, and with which pattern?
4. One commit in the `-S` list neither introduced nor removed the constant. Why is it there?

### Exercise 11.3 (Level 1): Blame, and one step further back

**Do.**

```bash
git blame -L 3,5 docsplit/config.py
```

Take the commit that blame names for the `CHUNK_SIZE` line and run:

```bash
git show --stat --format='%h %an: %s' <that commit>
git blame -L '/CHUNK_SIZE/,+1' <that commit>^ -- docsplit/config.py
```

**Answer in writing.**

1. What does blame tell you about the commit it names for `CHUNK_SIZE`, and what does it not tell you?
2. Who decided that the chunk size is 512, and in which commit? How many commands did you need after the first blame?
3. Explain the caret in `<that commit>^` and the meaning of `-L '/CHUNK_SIZE/,+1'`.
4. Which blame option would have skipped the first commit for you, and what would you have to pass to it?

### Exercise 11.4 (Level 2, command prediction): Ranges on a diverged branch

Look at `git log --graph --oneline --all` first. Then **write down the output** of each command below before you run it. For the commands that list commits, the subjects are enough.

```bash
git log --oneline main..feat/markdown
git log --oneline feat/markdown..main | wc -l
git rev-list --left-right --count main...feat/markdown
git log --oneline --cherry-pick --right-only main...feat/markdown
git diff --stat main...feat/markdown
git diff --stat main..feat/markdown
```

**Then explain.**

1. The first and the fourth command differ by one commit. Why?
2. The two `git diff` commands report different sets of files. Which of the two would a pull request from `feat/markdown` into `main` show, and why does the other one list files that the branch never touched?

Hint: for `git log`, two and three dots select sets of commits; for `git diff`, they select two endpoints.

### Exercise 11.5 (Level 2): A file that is gone

**Goal.** `configs/legacy.yaml` existed once. Find the commit that deleted it. Then bring the file back into the working tree and the index with the content it had in the last commit that contained it. `HEAD` and `main` must not move, and you may not check out another commit.

**Hints.** One option of `git log` filters by the kind of change. One command copies a path out of any commit into the index, the working tree, or both.

**Show.** `git status -s`, the content of the file, and `git log -1 --oneline`. Afterwards remove the file again (`git rm -f configs/legacy.yaml`), because the following exercises expect a clean tree.

### Exercise 11.6 (Level 2): Release notes from history

**Goal.** Produce three things for the release `v0.3.0`, each with one command:

1. a list of the changes since `v0.2.0`, oldest first, one line per commit in the form `- <subject> (<author>)`, without merge commits;
2. the number of those commits per author, largest first;
3. the same range as a reviewer of `main` would read it: only what was committed or merged on `main` itself, with merges shown as one line each.

**Hints.** A pretty format with placeholders; `git shortlog` needs a revision when its input is not a terminal; one option follows only the first parent.

**Then explain** why list 1 has more lines than list 3 has non-merge lines, and name the commits that make the difference.

### Exercise 11.7 (Level 3): "I only moved it"

**Situation.** Since `v0.2.0` the last chunk of every document is missing from the index: `window()` in `docsplit/window.py` drops the tail of the token list. `git blame docsplit/window.py` attributes every line of the function to one commit by Asha. Asha says she moved the function into its own module and changed nothing.

**Task.** Find the commit that changed the behavior, its author, and the commit that had introduced the behavior that was lost, with the reason its author gave. Then say whether Asha is right, and show the evidence. Use at least two independent tools and say what each one can and cannot see across the move.

### Exercise 11.8 (Level 3): "Git lost my commit"

**Situation.** Asha says:

> Last Wednesday I committed a fix to `docsplit/clean.py` so that tabs are collapsed too. It is not in `main`. `git log --oneline -- docsplit/clean.py` does not even list my commit. Was history rewritten?

**Task.** Establish whether her commit is part of `main`, why the path-limited log does not show it, and what happened to her change. Name the commit where it happened and the person who can explain it. State what should be done now, and in what form (you do not have to do it).

### Exercise 11.9 (Level 4): The regression among commits that cannot be tested

```bash
exercises/gen/m11-judgekit/generate.sh
```

Read [the symptoms](gen/m11-judgekit/SYMPTOMS.md), then work in the sandbox. Finish with `exercises/gen/m11-judgekit/check.sh`.

Hand in: the commit, the complete list of commands that led you to it, the reason a first attempt at automation could not name one commit, and your fix with the argument why it is the lowest-risk one.

### Exercise 11.10 (Level 4): "It is fixed in 2.3"

```bash
exercises/gen/m11-vecindex/generate.sh
```

Read [the symptoms](gen/m11-vecindex/SYMPTOMS.md). Finish with `exercises/gen/m11-vecindex/check.sh`.

Hand in: a table with one row for `main`, `release/2.3`, `v2.3.1` and `v2.4.0` that says for each whether it contains the complete fix, and the command that proves each cell; then your backport and the new tag.

### Exercise 11.11 (Level 5): Retrieval quality dropped on Friday

```bash
exercises/gen/m11-ragbench/generate.sh
```

Read [the incident channel](gen/m11-ragbench/SYMPTOMS.md). Finish with `exercises/gen/m11-ragbench/check.sh`.

Hand in the report asked for in the symptoms, and for each of the three people quoted there: the claim, the command with which you tested it, and the verdict.

---

## Module 12: Recovery

Chapter: [13, Recovery](../textbook/ch13-recovery.md). Labs 12.1 to 12.12 come first; every scenario below is a different one.

Exercises 12.1 to 12.8 use small repositories of the project `labelhub` (the label schema and annotator data of an annotation team), one directory per exercise:

```bash
exercises/gen/m12-labelhub/generate.sh
```

The rule of Chapter 13, section 13.7 applies to every exercise in this module: stop, look, and anchor what you find with a ref before you change anything.

### Exercise 12.1 (Level 1): Read a reflog before you need it

Directory `ex-12-1`. Two commits were lost here an hour ago; one commit was made afterwards.

**Do.**

```bash
git log --oneline
git reflog
git reflog show main
tail -2 .git/logs/HEAD
git branch rescue 'HEAD@{2}'
git log --oneline main..rescue
git diff --stat main...rescue
```

**Answer in writing.**

1. Which reflog entry is the state immediately before the accident, and which command caused the accident? Quote the entry.
2. One of the lost commits appears twice in the reflog with two IDs. Why, and which of the two did you rescue?
3. What are the two IDs at the start of each line in `.git/logs/HEAD`?
4. Why did you create a branch instead of resetting `main` to `HEAD@{2}`? What would the reset have cost?
5. In a real repository, how long would Git have kept these two commits findable, and which settings decide that?

### Exercise 12.2 (Level 1): A backup ref, and the one slot of `ORIG_HEAD`

Directory `ex-12-2`, on `feature/guidelines`, three commits ahead of `main`.

**Do.**

```bash
git log --oneline main..HEAD
git branch backup/pre-squash
git reset --soft main && git commit -q -m 'Add guidelines'
git log --oneline main..HEAD
git rev-parse --short ORIG_HEAD
git rev-parse --short backup/pre-squash
git diff --stat backup/pre-squash HEAD
git reset --hard backup/pre-squash
git log --oneline main..HEAD
git rev-parse --short ORIG_HEAD
git branch -d backup/pre-squash
```

**Answer in writing.**

1. After the squash, `ORIG_HEAD` and the backup branch name the same commit. After the restore they do not. What does `ORIG_HEAD` name now, and what does that tell you about relying on it?
2. What does the empty output of `git diff --stat backup/pre-squash HEAD` prove?
3. `git reset --hard` is 🔴. Why was it safe here? Name the two things you would check first in a real repository.
4. Which commits are now reachable only through the reflog?

### Exercise 12.3 (Level 1): `git fsck` as a search tool

Directory `ex-12-3`. Three things were thrown away here: a branch (`git branch -D`), a stash (`git stash drop`), and a staged version of a file that was replaced before it was committed.

**Do.**

```bash
git fsck
git fsck --no-reflogs
git fsck --unreachable --no-reflogs | sort
git fsck --lost-found
ls .git/lost-found/commit .git/lost-found/other
```

Then look at each dangling commit with `git show -s --format='%h %p | %s' <id>` and at the dangling blob with `git cat-file -p <id>`.

**Answer in writing.**

1. Plain `git fsck` reports one dangling commit, `--no-reflogs` two. Which thing does each commit belong to, and why does the default hide one of them?
2. What is the difference between "dangling" and "unreachable"? Use the counts you saw.
3. One of the dangling commits has two parents. What is it?
4. Which option did `--lost-found` imply, judging by its output? What did it write, and where?
5. None of these lines reports damage. Which words in `git fsck` output would?

### Exercise 12.4 (Level 2, command prediction): What the reflog will say

Directory `ex-12-4` is empty. Type:

```bash
git init -q reflog-lab && cd reflog-lab
echo one > f.txt && git add f.txt && git commit -q -m A
echo two >> f.txt && git commit -q -am B
git commit -q --amend -m 'B, reworded'
git reset --soft HEAD~1
git commit -q -m C
git switch -q -c topic
```

**Before you run anything else, write down:**

1. the output of `git reflog`: the number of lines and, for each line, the text after the selector (for example `commit: ...`);
2. the number of lines of `git reflog show main` and of `git reflog show topic`;
3. the output of `git rev-list --count HEAD`;
4. how many commit objects exist in the repository, and which of them no branch reaches.

Then run the commands and compare.

### Exercise 12.5 (Level 2): One file from a commit that only the reflog knows

Directory `ex-12-5`. The commit "Add label schema" was amended. The amendment removed a section of `schema/labels.yaml` that you now want back.

**Goal.** Restore the pre-amend version of `schema/labels.yaml` in the working tree. No ref may move, no commit may be created, and the amended `README.md` must stay as it is.

**Hints.** The pre-amend commit has a name in the reflog. One command copies a path out of any commit.

**Show.** `git status -sb`, the last five lines of the file, and `git reflog -1` as proof that nothing moved.

### Exercise 12.6 (Level 2, draw the graph): Reset, commit, rescue, rebase

Directory `ex-12-6`: four commits on `main`, with the subjects `A schema`, `B roster`, `C report`, `D export`.

You will run these commands, in this order:

```bash
git reset --hard HEAD~2
echo 'E readme' > readme.txt && git add readme.txt && git commit -q -m 'E readme'
git branch rescue 'main@{2}'
git log --graph --oneline --all          # graph 1
git rebase rescue
git log --graph --oneline --all          # graph 2
```

**Before you run them, draw both graphs** with the commit subjects and both branch names. Then run them and compare.

**Then explain** why the selector is `main@{2}` and not `main@{1}`, and which commit object exists after the rebase that no branch reaches.

### Exercise 12.7 (Level 3): A rejected push after "a small addition"

Directory `ex-12-7/work`, a clone of `ex-12-7/server.git`.

**Situation.** You pushed "Add JSON export of the schema" yesterday. This morning you added a validation script, committed, and `git push` is rejected. `git status -sb` says that you are ahead by one and behind by one. You did not rebase and nobody else pushed.

**Task.** Find out what you did, from the repository alone. Then leave `main` so that the pushed commit is unchanged, the validation script is a commit of its own, and a plain `git push` succeeds. Explain why `git pull` would also have made the push succeed, and why it is the wrong fix.

### Exercise 12.8 (Level 3): The backup that will not clone

Directory `ex-12-8` contains `server.git` and one file, `backup.bundle`.

**Situation.** Your laptop is gone. Every night it wrote a bundle of your unpushed branches, and this file is last night's. You try the obvious restore, `git clone backup.bundle restored`, and it fails.

**Task.** Find out what kind of bundle this is, what it contains, and what it needs. Rebuild a working clone that has `main` from the server and every branch from the bundle. State what the bundle could not have saved even in principle.

### Exercise 12.9 (Level 4): A branch that looks like `main`

```bash
exercises/gen/m12-batchscore/generate.sh
```

Read [the symptoms](gen/m12-batchscore/SYMPTOMS.md). Finish with `exercises/gen/m12-batchscore/check.sh`.

### Exercise 12.10 (Level 4): An hour inside a rebase

```bash
exercises/gen/m12-embedcache/generate.sh
```

Read [the symptoms](gen/m12-embedcache/SYMPTOMS.md). Finish with `exercises/gen/m12-embedcache/check.sh`.

### Exercise 12.11 (Level 5): Deleted, then cleaned up

```bash
exercises/gen/m12-feedbackloop/generate.sh
```

Read [the thread](gen/m12-feedbackloop/SYMPTOMS.md). Finish with `exercises/gen/m12-feedbackloop/check.sh`.

Hand in the three-part statement asked for in the symptoms. For every source you used, say why that copy still existed and what would have destroyed it.

### Exercise 12.12 (Level 5): Power loss in the middle of a commit

```bash
exercises/gen/m12-tracehub/generate.sh
```

Read [the notes and the advice](gen/m12-tracehub/SYMPTOMS.md). Finish with `exercises/gen/m12-tracehub/check.sh`.

Hand in the list asked for in the symptoms. A stronger answer rebuilds the lost commit so that it has the ID it had before the power loss, and explains why that is possible.

---

## Module 13: Tags and versions

Chapter: [14B, Configuration, tags and signing](../textbook/ch14b-config-tags-signing.md), sections 14B.8 to 14B.14. Labs 13.1 to 13.3 come first.

Exercises 13.1 to 13.8 use small repositories of the project `quotad` (a service that enforces token quotas per tenant), one directory per exercise:

```bash
exercises/gen/m13-quotad/generate.sh
```

### Exercise 13.1 (Level 1): Two kinds of tag, counted in objects

Directory `ex-13-1`.

**Do.**

```bash
git count-objects
git tag staging-ok
git count-objects
git tag -a v0.2.0 -m 'quotad 0.2.0' HEAD~1
git count-objects
git cat-file -t staging-ok
git cat-file -t v0.2.0
git cat-file -p v0.2.0
git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(objectname:short) -> %(*objectname:short)'
```

**Answer in writing.**

1. Which of the two `git tag` commands created an object, and of which type? What did the other one create?
2. List the fields of the object that `git cat-file -p v0.2.0` prints, and say which of them a lightweight tag cannot have.
3. What does `%(*objectname:short)` print, and why is it empty for one of the tags?
4. Which kind of tag do you use for a release, and which Git commands treat the two kinds differently?

### Exercise 13.2 (Level 1): Listing and sorting

Directory `ex-13-2`, with five annotated tags.

**Do.**

```bash
git tag
git tag --sort=version:refname
git -c versionsort.suffix=-rc tag --sort=version:refname
git tag -n1 -l 'v0.1*'
git tag --contains <the commit "Fix burst allowance for the free tier">
git tag --merged v0.9.0
git tag --points-at HEAD
```

**Answer in writing.**

1. Explain the order of each of the first three listings. Which one is the order a release page needs?
2. `git tag --contains` and `git tag --merged` answer two different questions. State both questions in plain words.
3. Why is the last output empty, and what would `git describe` print here? Predict it, then check.

### Exercise 13.3 (Level 1): Which tags travel

Directory `ex-13-3/work`, a clone of `ex-13-3/server.git`, one commit ahead of the server.

**Do.**

```bash
git tag -a v0.3.0 -m 'quotad 0.3.0'
git tag tmp/debug HEAD~1
git push
git ls-remote --tags origin
echo '# Add enterprise tier' >> quota.py && git commit -q -am 'Add enterprise tier'
git push --follow-tags
git ls-remote --tags origin
git push origin tmp/debug
git push origin --delete tmp/debug
git tag -l
git ls-remote --tags origin
```

**Answer in writing.**

1. What did the first `git push` send, and what did it leave behind?
2. `--follow-tags` sent one of your two tags. State the two conditions a tag must meet.
3. `git ls-remote` prints two lines for `v0.3.0`. What is the line that ends in `^{}`?
4. After the last two pushes, where does `tmp/debug` still exist? What does that say about deleting a tag "everywhere"?

### Exercise 13.4 (Level 2, command prediction): What `git describe` prints

Directory `ex-13-4`. Look at `git log --oneline --decorate`, and find out which of the two tags is annotated. Then **write down the output** of each command (use `<id>` for an abbreviated commit ID, but say which commit it is):

```bash
git describe
git describe --tags
git describe --abbrev=0
git describe --long v1.0.0
git describe HEAD~4
git describe --exact-match
git describe HEAD~5
git describe --always HEAD~5
```

Two of the commands fail. Say which, and with what kind of message.

### Exercise 13.5 (Level 2, command prediction): What a tag name resolves to

Same directory, `ex-13-4`. **Write down** what each command prints: for IDs, say which object it is (the tag object, a commit, which commit).

```bash
git cat-file -t v1.0.0
git cat-file -t staging-ok
git rev-parse v1.0.0
git rev-parse 'v1.0.0^{}'
git rev-parse staging-ok HEAD~2
git show-ref --tags --dereference
```

How many lines does the last command print, and why not two, and why not four?

### Exercise 13.6 (Level 2, draw the graph): A patch release from a release branch

Directory `ex-13-6`. `v1.0.0` is released. Since then `main` has received a feature, the fix "Fix negative usage after a refund", and another feature. Customers on 1.0 need the fix and nothing else.

**Goal.** Create `release/1.0` at the release, bring the fix over so that its origin is recorded in the new commit, tag the result `v1.0.1` as a release, and return to `main`.

**Before you look at the result, draw** the output of `git log --graph --oneline --decorate --all`, and predict the output of:

```bash
git describe main
git describe release/1.0
git tag --contains <the fix commit on main>
```

**Then explain** the output of the last command to a support engineer who asks "which release contains the fix?".

### Exercise 13.7 (Level 3): The version that will not move

Directory `ex-13-7` with the clones `dev` and `ci` of `server.git`.

**Situation.** Release 1.1.0 was tagged and pushed two days ago. `git tag` lists `v1.1.0` in every clone, and `git log --decorate` shows it one commit below `main`. The service's version endpoint, which prints the output of `scripts/version.sh`, still reports a version that begins with `v1.0.0`. It does so in every clone.

**Task.** Find the root cause. Then give two possible fixes, one that changes the script and one that changes the tag, with the cost of each, and say which you recommend for a tag that is already published.

### Exercise 13.8 (Level 3): One name, two refs

Directory `ex-13-8/work`, a clone of `ex-13-8/server.git`.

**Situation.** A colleague reports three things about the name `v1.0` in this repository: some commands print a warning, `git push origin v1.0` fails, and `git switch v1.0` followed by `git log -1` shows a commit that is not the 1.0 release.

**Task.** Reproduce the three observations. Explain each from the rules by which Git resolves a short name. Then remove the cause without touching the published tag, and publish the result.

### Exercise 13.9 (Level 4): Two builds of 1.4.0

```bash
exercises/gen/m13-modelcard/generate.sh
```

Read [the symptoms](gen/m13-modelcard/SYMPTOMS.md). Finish with `exercises/gen/m13-modelcard/check.sh`.

---

## Module 14: Worktrees, attributes, hooks, stash internals, rerere

Chapters: [14C, Stash internals, rerere, attributes, hooks](../textbook/ch14c-stash-rerere-attributes-hooks.md) and [25, Worktrees](../textbook/ch25-worktrees.md). Labs 14.1 to 14.6 come first.

Exercises 14.1 to 14.8 use small repositories of the project `promptguard` (a filter that screens prompts before they reach the model), one directory per exercise:

```bash
exercises/gen/m14-promptguard/generate.sh
```

### Exercise 14.1 (Level 1): A second working tree for a hotfix

Directory `ex-14-1`. You are on `feature/unicode` with an uncommitted edit and an untracked file. A hotfix on `main` cannot wait, and you do not want to stash.

**Do.**

```bash
git status -sb
git worktree add -b hotfix/blocklist ../hotfix main
git worktree list
cd ../hotfix
cat .git
```

In `../hotfix`, add the phrase `"developer mode"` to the `BLOCKED` list in `guard/rules.py`, commit it, and go back:

```bash
git commit -q -am 'Block the developer-mode phrase' && git log --oneline -1
cd ../ex-14-1
git status -sb
git switch hotfix/blocklist
git worktree remove ../hotfix
git worktree list
git branch
```

**Answer in writing.**

1. What is `.git` in the linked worktree, and what does it point at?
2. Which things do the two working trees share, and which does each have for itself?
3. Why does `git switch hotfix/blocklist` fail in the main worktree? Quote the message.
4. After `git worktree remove`, where is the hotfix commit? What would have been different had the worktree been created with `--detach`?

### Exercise 14.2 (Level 1): Attributes that travel with the repository

Directory `ex-14-2`.

**Do.** Create `.gitattributes` with these three lines:

```text
*.ipynb          -diff
*.jsonl          text eol=lf
docs-internal.md export-ignore
```

```bash
git check-attr -a -- notebooks/eval.ipynb data/golden.jsonl docs-internal.md guard/rules.py
```

Change `41` to `43` in `notebooks/eval.ipynb`, then:

```bash
git diff
git add -A && git commit -q -m 'Add attributes for notebooks, data and internal notes'
git archive HEAD | tar -t
```

**Answer in writing.**

1. What does `git diff` show for the notebook, and what is still recorded in the commit?
2. Which file is missing from the archive, and is it missing from the repository?
3. All three attributes work in every clone without any setup. Name two kinds of attribute value that do not, and say what else they need.
4. `guard/rules.py` printed no line in `git check-attr -a`. What does that mean?

### Exercise 14.3 (Level 1): A pre-commit hook, and its limit

Directory `ex-14-3`.

**Do.** Create `.git/hooks/pre-commit` with this content and make it executable:

```sh
#!/bin/sh
# Refuse a commit whose staged changes add the marker "DO NOT COMMIT".
if git diff --cached | grep -q '^+.*DO NOT COMMIT'; then
  echo "pre-commit: staged changes contain DO NOT COMMIT" >&2
  exit 1
fi
```

```bash
chmod +x .git/hooks/pre-commit
echo 'MAX_CHARS = 1  # DO NOT COMMIT: local test' >> guard/rules.py
git commit -am 'Lower the limit'
git log --oneline -1
git commit -q --no-verify -am 'Lower the limit' && git log --oneline -1
```

**Answer in writing.**

1. Why does the hook read `git diff --cached` and not the files in the working tree?
2. What decided that the first commit was refused: the message, or something else?
3. What did `--no-verify` skip? Does a colleague who clones this repository get the hook?
4. Given your answers to 2 and 3, where must a rule live that nobody may bypass?

### Exercise 14.4 (Level 2, draw the graph): The shape of a stash entry

Directory `ex-14-4`. `git status -sb` shows one staged change, one unstaged change, and one untracked file.

You will run:

```bash
git stash push -u -m "limits, readme, todo"
git log --graph --oneline stash@{0}
```

**Before you run the second command, draw its output**: how many commits the stash entry consists of, how they are connected to each other and to `main`, and what each of them contains. Then run it, and check your claims about the contents with `git show -s --format='%h parents: %p' stash@{0}`, `git diff --stat` between the right pairs, and `git ls-tree -r --name-only`.

**Then explain** what the graph would look like without `-u`.

### Exercise 14.5 (Level 2): A changelog that conflicts on every merge

Directory `ex-14-5`. Two feature branches, `feat/length-limit` and `feat/audit-log`, each add one line at the end of `CHANGELOG.md`.

**Goal.** Merge both into `main`. The second merge conflicts; show that first, and abort it. Then make Git combine the two additions by itself, with a setting that every clone gets, and merge again without editing the file by hand.

**Hints.** One line in one tracked file; a built-in driver.

**Then explain** in which situations the driver you chose produces a wrong file without telling you.

### Exercise 14.6 (Level 2, command prediction): Which hooks run

Directory `ex-14-6`. Nine hooks are installed in `.git/hooks`; each prints one line, `[hook] <name>`: `pre-commit`, `prepare-commit-msg`, `commit-msg`, `post-commit`, `pre-merge-commit`, `post-merge`, `pre-rebase`, `post-rewrite`, `post-checkout`.

**Write down, in order, the lines that each command prints.** Then run it and compare before you go on to the next one.

```bash
echo '# one' >> guard/rules.py && git commit -q -am 'One'
echo '# two' >> guard/rules.py && git commit -q --no-verify -am 'Two'
git commit -q --amend --no-edit
git merge -q --no-ff --no-edit topic
git switch -q -c side HEAD~1
echo three > three.txt && git add three.txt && git commit -q --no-verify -m 'Three'
git rebase -q main
```

**Then explain** which of these hooks can stop the command that runs them, and what that means for a team that wants to use a hook as a quality gate.

### Exercise 14.7 (Level 3): "The hook works on my machine"

Directory `ex-14-7` with the clones `you` and `asha` of `server.git`.

**Situation.** The repository carries a `commit-msg` hook in `.githooks/` that requires a ticket number at the start of every subject. In your clone it rejects bad messages. This morning `origin/main` received a commit from Asha with the subject `fix readme`. Asha says that she ran the setup step from the README, and that Git never complained.

**Task.** Find out why the hook does not run for Asha, from the two clones. Repair it for everyone who pulls. Decide what to do about the commit that is already on `main`, and say what must be added so that such a commit cannot reach `main` again.

### Exercise 14.8 (Level 3): A resolution that nobody typed

Directory `ex-14-8`, on `main`.

**Situation.** Run `git merge feat/timeouts`. Git reports a conflict in `guard/client.yaml`. You open the file to resolve it: there are no conflict markers, and the file contains `timeout_seconds: 5`. The branch you are merging exists to raise the timeout to 30.

**Task.** Explain where the content of the file came from and why Git still reports a conflict. Bring the conflict back, resolve it so that the timeout is 30 and the retries are 3, and make sure that the wrong resolution cannot return.

### Exercise 14.9 (Level 4): Two fixes in a worktree that no longer exists

```bash
exercises/gen/m14-redactor/generate.sh
```

Read [the symptoms](gen/m14-redactor/SYMPTOMS.md). Finish with `exercises/gen/m14-redactor/check.sh`.

---

## Module 15: Submodules, subtrees, Git LFS

Chapters: [22, Git LFS](../textbook/ch22-git-lfs.md) and [23, Submodules](../textbook/ch23-submodules.md). Labs 15.1 to 15.4 come first.

Exercises 15.1 to 15.8 use the service `evalboard` and the library `metrickit`, one directory per exercise, with bare repositories under `remotes/`:

```bash
exercises/gen/m15-evalboard-practice/generate.sh
```

Two rules for this module. The remotes are local paths, so every command that makes Git clone or fetch a submodule needs `-c protocol.file.allow=always` (Chapter 23, section 23.4). And Git LFS is set up with `git lfs install --local`, inside the sandbox repository only: never run `git lfs install` without `--local` in the lab shell.

### Exercise 15.1 (Level 1): Add a submodule and read what was recorded

Directory `ex-15-1/evalboard`.

**Do.**

```bash
git submodule add ../metrickit.git vendor/metrickit
git -c protocol.file.allow=always submodule add ../metrickit.git vendor/metrickit
git status -s
cat .gitmodules
git commit -q -m 'Add metrickit as a submodule'
git ls-tree HEAD vendor/
git submodule status
cat vendor/metrickit/.git
git -C vendor/metrickit log --oneline -1
```

**Answer in writing.**

1. Why does the first command fail, and what does the option in the second one change?
2. The commit records two things for the submodule. Which, and what are the mode and the object type in the `git ls-tree` line?
3. Where is the library's repository (its objects and refs) stored on your disk?
4. The URL in `.gitmodules` is relative. Relative to what?
5. What exactly does a teammate get for `vendor/metrickit` after a plain `git clone` and nothing else?

### Exercise 15.2 (Level 1): A first LFS pointer

Directory `ex-15-2/evalboard`, with an untracked file of 300,000 bytes, `weights/encoder.bin`.

**Do.**

```bash
wc -c weights/encoder.bin
git lfs install --local
git lfs track "*.bin"
cat .gitattributes
git add .gitattributes weights && git commit -q -m 'Add encoder weights with Git LFS'
git cat-file -p HEAD:weights/encoder.bin
git cat-file -s HEAD:weights/encoder.bin
wc -c weights/encoder.bin
git lfs ls-files
find .git/lfs/objects -type f
```

**Answer in writing.**

1. What is stored in the commit for `weights/encoder.bin`, and how large is it?
2. Where are the 300,000 bytes, and what names them?
3. Which two programs ran, and when, to turn the file into the pointer and the pointer back into the file?
4. What did `git lfs install --local` change, and why does this course forbid the form without `--local` in the lab?
5. What does the asterisk in the output of `git lfs ls-files` mean?

### Exercise 15.3 (Level 1): The same library as a subtree

Directory `ex-15-3/evalboard`.

**Do.**

```bash
git subtree add --prefix=vendor/metrickit ../remotes/metrickit.git main --squash
git log --graph --oneline
git ls-tree HEAD vendor/
ls -A vendor/metrickit
git log -1 --format=%B HEAD^2
```

**Answer in writing.**

1. Compare the `git ls-tree` line with the one from exercise 15.1. What is the library to this repository now?
2. What does a teammate get for `vendor/metrickit` after a plain `git clone`?
3. Two commits were created. What is each of them, and what do the two trailers in the second parent's message record?
4. Name one thing that became simpler compared with a submodule and one that became harder.

### Exercise 15.4 (Level 2, command prediction): The first character of `git submodule status`

Directory `ex-15-4/fresh`: a plain clone of a repository whose `main` records `metrickit` at `v0.2.0`.

**Write down** the output of each command before you run it (use `<id>` for IDs, but say which commit):

```bash
git submodule status
ls -A vendor/metrickit | wc -l
git -c protocol.file.allow=always submodule update --init
git submodule status
git -C vendor/metrickit status -sb
git -C vendor/metrickit checkout -q v0.1.0
git submodule status
git status -s
git diff --submodule=log
```

The first character of the three `git submodule status` lines is different each time. Name the three states. Then say what `git commit -am "..."` would record in the superproject in the last state.

### Exercise 15.5 (Level 2, draw the graph): Two subtree operations

Directory `ex-15-5/evalboard`.

You will run:

```bash
git subtree add -q --prefix=vendor/metrickit ../remotes/metrickit.git v0.1.0 --squash
echo '# sorted by name' >> board.py && git commit -q -am 'Sort runs by name'
git subtree pull -q --prefix=vendor/metrickit ../remotes/metrickit.git v0.2.0 --squash
git log --graph --oneline
```

**Before you run the last command, draw its output.** Seven commits; get the parents of each right. Say which commits contain files of the library only.

**Then explain** how the second squashed commit knows where the first one stopped.

### Exercise 15.6 (Level 2, command prediction): Tracked too late

Directory `ex-15-6/evalboard`. `weights/encoder.bin` (300,000 bytes) is already committed as an ordinary file.

**Write down** the output of the commands marked with a number before you run them:

```bash
git lfs install --local
git lfs track "*.bin"
git add .gitattributes && git commit -q -m 'Track weights with Git LFS'
git lfs ls-files                               # 1
git cat-file -s HEAD:weights/encoder.bin       # 2
git status -s                                  # 3
git add --renormalize .
git status -s                                  # 4
git commit -q -m 'Convert the encoder weights to an LFS pointer'
git lfs ls-files                               # 5
git cat-file -s HEAD:weights/encoder.bin       # 6
git cat-file -s HEAD~2:weights/encoder.bin     # 7
```

**Then explain** what a clone of this repository still downloads, and which command would be needed to change that, at what price.

### Exercise 15.7 (Level 3): An empty directory on the build machine

Directory `ex-15-7/ci`, a clone of the service.

**Situation.** The build fails at `python3 -B -c 'import board'` with a `ModuleNotFoundError` for `vendor.metrickit.metrickit`. The directory `vendor/metrickit` exists. On every developer machine the import works.

**Task.** Find the root cause and fix the clone. The obvious fix fails once in this sandbox, with a message about a transport: explain that message as well, and say why Git's default is what it is. Then give the two ways to make a fresh clone complete in one step.

### Exercise 15.8 (Level 3): A model file of 131 bytes

Directory `ex-15-8/newclone`, a fresh clone.

**Situation.** `python3 -B -c 'import load; load.load()'` fails with an unpickling error whose last line mentions the character `v`. The same code works on the machine that pushed the weights.

**Task.** Find the root cause from the file, the attributes and the configuration of this clone. Fix the clone, with LFS configured for this repository only. Explain why `git status` was clean all along, and what a deployment pipeline should check so that this failure is caught before the model loader runs.

### Exercise 15.9 (Level 4): It works on your machine

```bash
exercises/gen/m15-evalboard/generate.sh
```

Read [the symptoms](gen/m15-evalboard/SYMPTOMS.md). Finish with `exercises/gen/m15-evalboard/check.sh`.
