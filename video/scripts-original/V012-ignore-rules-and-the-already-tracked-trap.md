# V012: Ignore rules and the already-tracked trap

- **Part.** 1: Foundations
- **Module.** 2
- **Planned minutes.** 24
- **Prerequisites.** V011
- **Textbook sections.** [Chapter 4: The Working Tree](../../textbook/ch04-working-tree.md), sections 4.5 and 4.6 (and "Ignored means expendable" in section 4.16)
- **Demo scripts.** `labs/ch04/gitignore-patterns.sh`, `labs/ch04/ignore-tracked-trap.sh`

## HOOK

**[ON SCREEN]** "We put `.env` in `.gitignore` months ago. Why did the secret scanner find the key in the repository last night?"

Your CTO forwards an alert and asks: "We put `.env` in `.gitignore` months ago. Why did the secret scanner find the key in the repository last night?"

The `.gitignore` is correct. The pattern matches. And the file has been in every commit since.

**[PAUSE]**

This is the eighth most-voted Git question on Stack Overflow, with 8,647 votes on 1 October 2026 according to the course's research report: how do I make Git forget about a file that was tracked, but is now in `.gitignore`? It has one cause, and you can already state it from the last video's decision tree: an ignore rule never applies to a path that is already tracked.

## INTRODUCTION

This video has two halves. First, how ignore rules work: where patterns come from, in which order they win, what the syntax means, and the one command that debugs any of it. Second, the trap: the tracked file that an ignore rule cannot touch, the fix, and the two things the fix does not do. Those two things have each caused incidents, and they are the production lesson of this video.

## LEARNING OBJECTIVES

After this video you can:

1. List the sources of ignore patterns in precedence order.
2. Find the rule that ignores a given path with one command.
3. Explain why adding a tracked file to `.gitignore` changes nothing, and fix it.
4. State what the fix does not do to history and to teammates' working trees.

## CONCEPT

**In one sentence.** An ignore pattern tells the commands that scan the working tree for untracked paths to leave matching paths out.

**Four sources, in precedence order.** From highest to lowest.

**[ON SCREEN]** The source table of section 4.5.

First, command-line options, for commands that take them, for example `git clean -e`. Scope: one command. Use: a one-off exception.

Second, `.gitignore` in the path's directory or any parent directory. A deeper file overrides a shallower one. It is a tracked file, so it is shared with the team. Use it for what every developer should ignore: build output, caches, datasets, secrets files.

Third, `.git/info/exclude`. Scope: this clone. Not shared. Use it for your own scratch files in this repository.

Fourth, the file named by `core.excludesFile`. Its default is `$XDG_CONFIG_HOME/git/ignore`, or `~/.config/git/ignore` when that variable is not set. Scope: every repository on this machine. Use it for editor and operating-system noise such as `.DS_Store` and `.idea/`.

Within one source, the last matching pattern decides.

**Pattern syntax.**

**[ON SCREEN]** The pattern table of section 4.5.

A pattern with no slash, or only a trailing slash, matches at any depth below the `.gitignore`: `*.log` matches `logs/app.log`. A trailing slash matches directories only: `__pycache__/`. A slash at the start or in the middle anchors the pattern to the directory of the `.gitignore`: `/build/` matches `build/`, and not `src/build/`. The wildcards `*`, `?` and bracket ranges do not match a slash. Two asterisks match any number of directories. A leading exclamation mark is negation: it re-includes a path that an earlier pattern excluded. A leading hash is a comment.

**The limit of negation.** The manual states that "it is not possible to re-include a file if a parent directory of that file is excluded", because Git does not look inside an excluded directory at all. So to keep one file inside an otherwise ignored directory, exclude the directory's contents, `data/*`, not the directory, `data/`.

**Inside `.git`.** Ignore rules leave no trace in the index or the object database. `.gitignore` is an ordinary tracked file. `.git/info/exclude` is a plain file that `git init` creates with a few comment lines. Neither is consulted for a path that has an index entry.

**The trap.** That last sentence is the trap. Ignore patterns are consulted only for paths that have no index entry: when status lists untracked files, and when add walks a directory. A tracked path is compared with its index entry. No pattern is checked. If the file was tracked first and ignored second, tracking wins.

Why does Git do this? The manual defines the purpose of ignore files narrowly: "to ensure that certain files not tracked by Git remain untracked". What is tracked changes only when a command says so: `git add`, `git rm`.

**The fix.** `git rm --cached <path>`, then commit, and keep the pattern in `.gitignore`. `git rm --cached` is 🟡 CAUTION: it removes the index entry and leaves the file on disk; the next commit deletes the path for everyone who pulls. And treat any secret in the file as leaked, and rotate it.

**What the fix does not do.** First, it does not remove the file from history. Every earlier commit still contains it. If the file held a credential, the credential is in every clone and, once pushed, on the server. The order of operations for a leaked secret is to revoke or rotate it first. Second, the fix is a deletion commit, and Git applies deletions to working trees. A teammate who cloned while the file was tracked loses her copy when she pulls.

**Ignored means expendable.** A third consequence, for ignored files in general: Git treats an ignored file as something it may overwrite without asking. If the same path is ignored on one branch and tracked on another, switching branches replaces your ignored file, silently. An untracked file in the way normally stops a checkout. An ignored file does not: `--overwrite-ignore` is the default for checkout, switch and merge. The textbook labels that case 🔴 DANGEROUS, and the prevention is to give private files a name that no commit on any branch has ever tracked, or to use `git switch --no-overwrite-ignore` when moving to old branches.

**When not to use `.gitignore`.** Not as protection for secrets: it is advice to `git status` and `git add`, nothing more. It does not stop `git add -f`, and it does nothing about history. Not for files the team must share. And not for "ignore my local edits to a tracked file": Git has no such feature. V018 covers the two index bits that look like one.

## MENTAL MODEL

The textbook's analogy: a "do not list" note taped to the warehouse door for the people doing the audit. It changes what the auditors report. It does not move, lock or hide anything, and it has no effect on items that are already in the inventory.

That last clause is where most people's mental model breaks. They read `.gitignore` as "Git, do not touch these files". It is narrower: "when you look for new things to list, skip these". A file that is already in the inventory is not a new thing.

And where the analogy itself breaks down: the note is not neutral for the items it covers. Things under the note are treated as expendable, as you heard a moment ago. An auditor would not throw them away; Git may overwrite them.

## DIAGRAM

**[DIAGRAM]** The decision path. Draw the first question, then the "yes" branch and stop, then the "no" branch.

```text
   is the path in the index?
        |                \
       yes                no
        |                  \
   TRACKED                 does an ignore pattern match?
   ignore rules are           |                \
   NOT consulted             yes                no
                              |                  |
                           IGNORED           UNTRACKED
```

On the "yes" branch the ignore rules are never read. That is the whole trap in one picture.

**[DIAGRAM]** The root-cause box of section 4.6, one line at a time.

```text
Observed behavior : .env is listed in .gitignore, yet git status reports it as modified
                    and it keeps appearing in commits.
Git state         : .env has an entry in the index. It was added before the rule existed.
Mechanism         : Ignore patterns are consulted only for paths that have no index entry:
                    when status lists untracked files and when add walks a directory.
                    A tracked path is compared with its index entry. No pattern is checked.
Root cause        : The file was tracked first and ignored second. Tracking wins.
Why Git does this : The manual defines the purpose of ignore files narrowly: "to ensure
                    that certain files not tracked by Git remain untracked". What is
                    tracked changes only when a command says so (git add, git rm).
Correct fix       : git rm --cached <path>, commit, keep the pattern in .gitignore.
                    Treat any secret in the file as leaked and rotate it.
Prevention        : Write .gitignore before the first "git add ."; read git status before
                    the first commit; make CI fail when
                    "git ls-files -ci --exclude-standard" prints anything.
```

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch04/gitignore-patterns.sh`.

```bash
labs/run ch04/gitignore-patterns
```

The demo's `.gitignore`, with line numbers.

<!-- snippet: ch04/gitignore-patterns/01-file -->
```text
$ cat -n .gitignore
     1	# caches and logs, at any depth
     2	__pycache__/
     3	*.log
     4	
     5	# build output, only at the top level
     6	/build/
     7	
     8	# datasets stay out; the README that documents them stays in
     9	data/*
    10	!data/README.md
    11	
    12	# secrets, with one documented exception
    13	.env*
    14	!.env.example
    15	
    16	# model weights under models/, at any depth
    17	models/**/*.bin
```
<!-- /snippet -->

`git check-ignore -v` is the debugger for ignore rules. For each path it prints the source file, the line number and the pattern that decided. Before the output, predict for each path: ignored or not, and by which line?

**[PAUSE]**

<!-- snippet: ch04/gitignore-patterns/02-check-ignore -->
```text
# Output: <source>:<line>:<pattern> TAB <path>. With -n, a path that matches no pattern prints "::".
$ git check-ignore -v -n src/__pycache__/app.cpython-314.pyc logs/app.log build/out.txt src/build/helper.py
.gitignore:2:__pycache__/	src/__pycache__/app.cpython-314.pyc
.gitignore:3:*.log	logs/app.log
.gitignore:6:/build/	build/out.txt
::	src/build/helper.py
$ git check-ignore -v -n data/tickets.jsonl data/README.md .env .env.local .env.example
.gitignore:9:data/*	data/tickets.jsonl
.gitignore:10:!data/README.md	data/README.md
.gitignore:13:.env*	.env
.gitignore:13:.env*	.env.local
.gitignore:14:!.env.example	.env.example
$ git check-ignore -v -n models/v1/model.bin models/v1/checkpoints/step-100.bin models/v1/card.md
.gitignore:17:models/**/*.bin	models/v1/model.bin
.gitignore:17:models/**/*.bin	models/v1/checkpoints/step-100.bin
::	models/v1/card.md
```
<!-- /snippet -->

Read it line by line. `/build/` on line 6 ignores the top-level `build/` and not `src/build/helper.py`, because the leading slash anchors it; with `-n`, a path that matches no pattern prints two colons. `.env.example` matched one line and then a later one; the later line wins, and because that line is a negation, the path is not ignored. A match on a `!` pattern means "not ignored". So read the pattern, not only the fact that there is output.

<!-- snippet: ch04/gitignore-patterns/03-status -->
```text
$ git status --short --untracked-files=all
?? .env.example
?? .gitignore
?? data/README.md
?? models/v1/card.md
?? src/build/helper.py
```
<!-- /snippet -->

Status agrees with the debugger.

Now the limit of negation. The script changes `data/*` to `data/`. The exception line for `data/README.md` stays. Predict: is the README still visible?

<!-- snippet: ch04/gitignore-patterns/04-negation-limit -->
```text
# Edit line 10 from "data/*" to "data/": the directory itself is now excluded.
$ grep -n 'data' .gitignore
8:# datasets stay out; the README that documents them stays in
9:data/
10:!data/README.md
$ git check-ignore -v data/README.md
.gitignore:9:data/	data/README.md
$ git status --short --untracked-files=all data
```
<!-- /snippet -->

No. The exception line is still there, and it no longer has any effect, because the directory itself is excluded and Git does not look inside it.

<!-- snippet: ch04/gitignore-patterns/05-nested -->
```text
# A .gitignore in a subdirectory overrides the ones above it, for paths below it.
$ printf '!*.log\n' > experiments/.gitignore
$ git check-ignore -v -n experiments/run1/train.log logs/app.log
experiments/.gitignore:1:!*.log	experiments/run1/train.log
.gitignore:3:*.log	logs/app.log
```
<!-- /snippet -->

Precedence between files: a `.gitignore` deeper in the tree overrides the ones above it, for paths below it.

<!-- snippet: ch04/gitignore-patterns/06-personal -->
```text
# Patterns for this clone only, never committed: .git/info/exclude
$ printf 'scratch/\n' >> .git/info/exclude
# Patterns for every repository on this machine: the file named by core.excludesFile.
# Its default is $XDG_CONFIG_HOME/git/ignore, or ~/.config/git/ignore when that variable is unset.
$ mkdir -p "$XDG_CONFIG_HOME/git"
$ printf '.DS_Store\n.idea/\n*.ipynb\n' > "$XDG_CONFIG_HOME/git/ignore"
$ git check-ignore -v scratch/try.py .DS_Store notebooks/scratch.ipynb
.git/info/exclude:7:scratch/	scratch/try.py
$LAB/ch04/gitignore-patterns/home/.config/git/ignore:1:.DS_Store	.DS_Store
$LAB/ch04/gitignore-patterns/home/.config/git/ignore:3:*.ipynb	notebooks/scratch.ipynb
```
<!-- /snippet -->

The two personal sources. They never travel with the repository. In the lab, `XDG_CONFIG_HOME` points into the sandbox; on your machine the default global file is `~/.config/git/ignore`. The debugger names each source file.

<!-- snippet: ch04/gitignore-patterns/07-precedence -->
```text
# The repository wants one notebook tracked. A per-directory .gitignore outranks the personal files.
$ printf '\n!notebooks/report.ipynb\n' >> .gitignore
$ git check-ignore -v -n notebooks/report.ipynb notebooks/scratch.ipynb
.gitignore:19:!notebooks/report.ipynb	notebooks/report.ipynb
$LAB/ch04/gitignore-patterns/home/.config/git/ignore:3:*.ipynb	notebooks/scratch.ipynb
$ git status --short --untracked-files=all notebooks
?? notebooks/report.ipynb
```
<!-- /snippet -->

And the repository outranks both personal files, so a project can insist on tracking something that one developer ignores globally.

<!-- snippet: ch04/gitignore-patterns/08-force -->
```text
# Ignore rules are advice for untracked paths. "git add -f" overrides them for one path.
$ git add models/v1/model.bin
The following paths are ignored by one of your .gitignore files:
models/v1/model.bin
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
[exit status: 1]
$ git add -f models/v1/model.bin
$ git status --short models
A  models/v1/model.bin
?? models/v1/card.md
```
<!-- /snippet -->

Finally, `git add -f` 🟢 SAFE overrides the rules for one path. Ignore rules are advice for untracked paths.

**[TERMINAL]** Caption bar: `labs/ch04/ignore-tracked-trap.sh`.

```bash
labs/run ch04/ignore-tracked-trap
```

<!-- snippet: ch04/ignore-tracked-trap/01-the-mistake -->
```text
# The first commit is made with "git add ." before any .gitignore exists.
$ git add .
$ git commit -m "Add service skeleton"
[main (root-commit) cd1e384] Add service skeleton
 2 files changed, 4 insertions(+)
 create mode 100644 .env
 create mode 100644 src/app.py
$ git ls-files
.env
src/app.py
```
<!-- /snippet -->

The mistake: the first commit of a project is made with `git add .` before any `.gitignore` exists, so `.env` is committed.

<!-- snippet: ch04/ignore-tracked-trap/02-ignore-does-nothing -->
```text
$ echo '.env' > .gitignore
$ git add .gitignore
$ git commit -m "Ignore local environment file"
[main ff0b08f] Ignore local environment file
 1 file changed, 1 insertion(+)
 create mode 100644 .gitignore
$ echo 'LLM_API_KEY=lab-secret-0002' > .env
$ git status --short
 M .env
```
<!-- /snippet -->

The rule arrives one commit later. `.env` is listed in `.gitignore`, and still shows as modified. Now diagnose. Predict what `git check-ignore -v .env` prints.

**[PAUSE]**

<!-- snippet: ch04/ignore-tracked-trap/03-diagnose -->
```text
# check-ignore reports nothing for a tracked path: ignore rules are not consulted for it.
$ git check-ignore -v .env
[exit status: 1]
# Ask the same question with the index left out of it.
$ git check-ignore -v --no-index .env
.gitignore:1:.env	.env
[exit status: 0]
# List every path that is tracked and also matches an ignore pattern.
$ git ls-files --cached --ignored --exclude-standard
.env
```
<!-- /snippet -->

Nothing, with exit status 1: ignore rules are not consulted for a tracked path. `--no-index` asks the same question with the index left out, and shows that the pattern itself is fine. The last command is the detector to remember: `git ls-files --cached --ignored --exclude-standard` lists every path that is tracked and also matches an ignore pattern. In a healthy repository it prints nothing.

**[DIAGRAM]** Show the root-cause box.

The fix: `git rm --cached` 🟡 CAUTION.

<!-- snippet: ch04/ignore-tracked-trap/04-fix -->
```text
$ git rm --cached .env
rm '.env'
$ git status --short --ignored
D  .env
!! .env
$ git commit -m "Stop tracking .env"
[main b0ddc57] Stop tracking .env
 1 file changed, 1 deletion(-)
 delete mode 100644 .env
$ git ls-files
.gitignore
src/app.py
$ cat .env
LLM_API_KEY=lab-secret-0002
```
<!-- /snippet -->

Between the `rm` and the commit, status shows the path twice: `D` in the first column, because the index no longer has what HEAD has; and `!!`, because the file on disk is now an untracked path that matches a pattern.

<!-- snippet: ch04/ignore-tracked-trap/05-now-ignored -->
```text
$ echo 'LLM_API_KEY=lab-secret-0003' > .env
$ git status --short
$ git check-ignore -v .env
.gitignore:1:.env	.env
[exit status: 0]
```
<!-- /snippet -->

After the commit, the file is still on disk with your content, and later edits are invisible to status. That looks like the end. It is not. Predict: is the secret gone from the repository?

**[PAUSE]**

<!-- snippet: ch04/ignore-tracked-trap/06-history-still-has-it -->
```text
# The fix changed the index and the new commit. It did not change any earlier commit.
$ git log --oneline -- .env
b0ddc57 Stop tracking .env
cd1e384 Add service skeleton
$ git show HEAD~1:.env
LLM_API_KEY=lab-secret-0001
```
<!-- /snippet -->

Stop here. The fix changed the index and the new commit. It did not change any earlier commit. `git show HEAD~1:.env` prints the key. Removing the path from the next commit changes nothing about that. Revoke or rotate first.

Second stop. Asha cloned while `.env` was still tracked, and her local runs read that file. She pulls.

<!-- snippet: ch04/ignore-tracked-trap/07-teammate -->
```text
# Asha cloned while .env was still tracked. Her local runs read that file.
$ cd ../asha-clone
$ ls -A
.env
.git
.gitignore
src
$ git pull
From $LAB/ch04/ignore-tracked-trap/support-bot
   ff0b08f..b0ddc57  main        -> origin/main
 * [new branch]      release-1.0 -> origin/release-1.0
Updating ff0b08f..b0ddc57
Fast-forward
 .env | 1 -
 1 file changed, 1 deletion(-)
 delete mode 100644 .env
$ ls -A
.git
.gitignore
src
# The content is still in the previous commit, so she can get her file back as an ignored file.
$ git restore --source=HEAD~1 .env
$ git status --short --ignored
!! .env
```
<!-- /snippet -->

Her copy is gone. From Git's point of view this is correct: the path was tracked in her HEAD, unmodified, and is absent from the new commit, so it is removed like any other deleted file. She can take the content back out of the previous commit with `git restore --source=HEAD~1 .env`; the file is then untracked and ignored, which is the state you wanted for everyone. If she had edited her `.env`, the pull would have stopped with a message that her local changes would be overwritten. So announce a fix of this kind before you push it, with those two commands in the message.

<!-- snippet: ch04/ignore-tracked-trap/08-ignored-is-expendable -->
```text
# Back in your clone. Your .env is ignored now and holds a value that exists nowhere else.
$ cd ../support-bot
$ cat .env
LLM_API_KEY=lab-secret-0003
# release-1.0 was cut while .env was still tracked.
$ git switch release-1.0
Switched to branch 'release-1.0'
$ cat .env
LLM_API_KEY=lab-secret-0001
$ git switch main
Switched to branch 'main'
$ cat .env
cat: .env: No such file or directory
[exit status: 1]
```
<!-- /snippet -->

And the third consequence. Your `.env` is ignored now, and holds a value that exists nowhere else. The branch `release-1.0` was cut while `.env` was still tracked. Switching to the old branch replaced your file with the tracked version, silently. Switching back deleted it. Your value is gone, and no object holds it.

## COMMON MISTAKES

1. **Adding a tracked file to `.gitignore` and expecting Git to forget it.** Root cause: the file was tracked first and ignored second, and ignore patterns are consulted only for paths without an index entry.
2. **A `!` exception has no effect.** Root cause: the parent directory is excluded, `data/` instead of `data/*`, and Git does not look inside an excluded directory.
3. **Believing that `git rm --cached` plus a commit removed the secret.** Root cause: the fix changes the index and the new commit; every earlier commit still contains the file.
4. **A teammate's local file vanishes after `git pull`.** Root cause: the pull contained a commit that stopped tracking the file, and Git applies deletions to working trees.
5. **Keeping an irreplaceable value in an ignored file whose path another branch tracks.** Root cause: ignored files are assumed to be regenerable, and `--overwrite-ignore` is the default for checkout, switch and merge.

## PRODUCTION EXAMPLE

For an AI/ML repository, the shared `.gitignore` usually starts from a language template and adds what the template lacks. The textbook notes that GitHub's Python template covers interpreter, packaging, environment and tool caches and has nothing specific to machine learning. The usual additions it lists: data directories; checkpoint and export formats such as `*.pt`, `*.pth`, `*.ckpt`, `*.safetensors`, `*.onnx` and `*.gguf`; experiment-tracker output such as `wandb/` and `mlruns/`; and `.env` files. Editor and operating-system noise stays in each developer's global ignore file.

**[ON SCREEN]** Lower third: **GitHub**. The `.gitignore` template that GitHub offers when you create a repository is a starting file that GitHub commits for you. Git itself ships no templates and attaches no meaning to the choice.

Two rules keep the file honest. Put a pattern in the shared file only if every developer and CI should ignore the path. And never treat the file as a security control. The prevention for the trap itself is one line in CI: fail when `git ls-files -ci --exclude-standard` prints anything.

## PRACTICE EXERCISE

Do Lab 2.3, "The `.gitignore` trap and its fix", in [`lab-manual/m02-working-tree-index-head.md`](../../lab-manual/m02-working-tree-index-head.md).

Before the diagnosis step, predict the output and the exit status of `git check-ignore -v` for the tracked file, and of the same command with `--no-index`. Before the fix, predict what `git status --short --ignored` will show between the `git rm --cached` and the commit.

## INTERVIEW QUESTION

Q45: "A developer added `config/secrets.yaml` to `.gitignore` and it is still in every new commit. Walk through your diagnosis commands, the fix, and the two things the fix does not solve."

Answer aloud. A strong answer follows the framework: it states the mechanism before any fix, names the commands that confirm it, and labels the fix with its risk. Then it spends as long on the two unsolved problems as on the fix, and says what has to happen first when the file holds a credential.

## RECAP

You should now be able to say: ignore patterns come from four sources: command-line options, `.gitignore` files, `.git/info/exclude` and my personal excludes file, in that order of precedence, and within a source the last match wins. `git check-ignore -v` names the file, line and pattern that decided. Ignore rules apply only to paths with no index entry, so a tracked file stays tracked. `git rm --cached` plus a commit stops tracking it; that does not remove it from history, and it deletes the file in the working tree of everyone who pulls. And an ignored file is expendable: Git may overwrite it without asking.

## HOMEWORK

- Read sections 4.5 and 4.6 of [Chapter 4](../../textbook/ch04-working-tree.md).
- Do Exercise 2.2, Level 1, "which rule ignores which path", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
- Challenge: Exercise 2.5, Level 2, "a negated pattern that does not work", in the same file.
