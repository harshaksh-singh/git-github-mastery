# V153: "Passes locally, fails on GitHub Actions": the documented causes

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 28
- **Planned minutes.** 24
- **Prerequisites.** V014, V087, V145, V152
- **Textbook sections.** [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), section 20B.12
- **Demo scripts.** `labs/ch20b/case-clash.sh`, `labs/ch20b/line-endings.sh`, `labs/ch20b/shallow-describe.sh`

## HOOK

**[ON SCREEN]** Three messages from three developers, in one week.

"The loader test passes on my Mac. In CI it says the configuration file does not exist. The file is right there in the repository."

"The deploy script works when I run it. In CI the very first line fails, something about bash and a strange character."

"The version step works on every laptop in the team. In CI it exits with 128."

Each of them ends the message the same way: "and it is the same commit." They are right about that. Same commit, and still not the same input. The machine is different, the clone is different, and in the first two cases what they have on their own disk is not what Git has recorded.

All three can be proven on your own machine, with Git alone, without re-running anything on GitHub.

## INTRODUCTION

In the last video you learned the investigation order. This video is the catalogue that the order leads you into: the documented causes of a test that passes locally and fails on GitHub Actions.

The textbook lists fourteen. Twelve are GitHub Actions behavior, and you have met most of them in the last ten videos. Two are Git. The demonstration takes the two Git causes, case sensitivity and line endings, and adds the shallow clone, because all three can be reproduced locally.

For each of the three the form is the same: the symptom as the developer would report it, then the one command that proves the cause, then the fix that Git records.

One caveat about the transcripts. The case-sensitivity demonstration depends on a case-insensitive volume, which is the macOS default. On a case-sensitive volume the first command fails and there is no collision warning.

## LEARNING OBJECTIVES

After this video you can:

- list the documented causes of a test that passes on a Mac and fails on the runner;
- prove a case-sensitivity cause with Git alone;
- prove a line-ending cause with `git ls-files --eol` and fix it with attributes;
- prove a shallow-clone cause and give the minimal fix;
- explain why "same commit" is not the same input.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions. The table of section 20B.12, in groups.

Go through the fourteen rows grouped by where they sit in the investigation order.

**About the commit and the clone.** A shallow, tagless clone: the checkout fetches one commit and no tags, so `git describe` and tag-derived versions fail. The remedy is `fetch-depth: 0`. And the job is not testing the pushed commit: on `pull_request` it checks out the test merge in detached HEAD, and it does not run at all while the pull request conflicts. The remedy is to merge or rebase the base locally to reproduce.

**About authority.** Missing secrets: not passed to runs from forks or from Dependabot; the token is read-only; an unset secret is an empty string. The remedy is fork-safe jobs, and the textbook adds: never `pull_request_target` as a shortcut.

**About the machine.** Shell differences: the implicit shell on Linux and macOS is `bash -e` without `pipefail`; `shell: bash` adds it; in a job container the default is `sh`; on Windows it is PowerShell. Moving images and tools: weekly image rebuilds, and every `-latest` label moved in 2026. Out of memory or time: smaller runners in private repositories, and the six-hour limit. Environment differences: the variable `CI` is set to true, steps share no shell state, and every job is a new machine.

**About what the run depends on.** Old action majors: actions written for Node 20 now run on Node 24. A stale or missing cache: a cache is immutable per key, restore keys take the most recent prefix match, and pull request caches are scoped to the merge ref.

**About whether a run exists.** A required check that stays pending, because a workflow skipped by a filter or by `[skip ci]` never reports. Runs cancelled by a newer run in the same concurrency group. And a workflow that never fires: events made with the job token start no runs, and scheduled workflows are disabled after 60 days without repository activity in public repositories.

**[ON SCREEN]** Lower third: Git.

**And the two that are Git.** Case sensitivity: macOS and Windows filesystems ignore case by default; a Linux runner does not. The remedy is to fix the names in Git. Line endings: CRLF committed, or converted on checkout by `core.autocrlf`. The remedy is `.gitattributes`.

**[ON SCREEN]** Callout: Unverified.

The textbook attaches a caveat here and I keep it. The official Actions pages read for the Phase 0 report do not state the time zone and locale of hosted runners, whether Windows runners check out with CRLF by default, or whether the hosted runners' filesystems are case-sensitive. Only the Git mechanisms are sourced, from Git's documentation and from real runs. Linux filesystems being case-sensitive is the general rule the chapter relies on.

**Why the two Git causes happen at all.** For case: when Git creates a repository it tests the filesystem, and on a case-insensitive one it sets `core.ignorecase` to true. Git's own records, the index and the trees, compare names byte by byte. So Git can hold a name with a capital letter, your code can ask for the lower-case name, and on your Mac the file opens, because the filesystem answers for both spellings. On a filesystem that distinguishes case, it does not.

For line endings: a blob is bytes. If the bytes contain carriage returns, every checkout that does not convert them gets carriage returns. A shell script whose first line ends in a carriage return asks the kernel for an interpreter whose name ends in that character.

In both cases, the laptop is the forgiving machine, and the forgiveness hides what is recorded in Git.

## MENTAL MODEL

"Same commit" means: the same tree, the same bytes in every blob, the same names. It says nothing about four other inputs.

The filesystem that the names are written onto. A name is recorded once in Git and interpreted by each machine's filesystem.

How much of the repository came along. The commit is the same; the history and the tags around it are not.

Which commit the job took. On a pull request it is not your commit at all.

And the process that runs your command: the shell and its options.

So when someone says "it is the same commit", agree, and then ask the four questions. For each there is a Git-side test that needs no re-run of the workflow, and the demonstration shows three of them.

Where this model has an edge: the first two demonstrations are not really differences between the Mac and the runner. They are differences between what is on your disk and what is in Git. The runner only sees what is in Git. That is why the proof in each case is a Git command that reads the index or a commit, and not a command that reads a file.

## DIAGRAM

**[DIAGRAM]** A two-column table. Fill the left column from the viewer's own experience, then the right column, and for each row name the command that shows the difference.

```text
                      your Mac                               the runner (Linux job)
  ------------------  -------------------------------------  ------------------------------------------
  filesystem          ignores case by default;               case-sensitive (the general rule for Linux;
                      core.ignorecase = true                 not stated on the Actions pages)
  checkout depth      full history                           one commit; .git/shallow lists it
  tags                all tags                               none
  commit tested       your branch tip                        on pull_request: the test merge under
                                                             refs/pull/N/merge, detached HEAD
  shell for run:      your interactive shell                 bash -e {0} without a shell key;
                                                             bash --noprofile --norc -eo pipefail {0}
                                                             with shell: bash
```

**[ON SCREEN]** The root-cause box of section 20B.12, one line at a time. Observed behavior: the version step fails in the job; the same command works on every laptop. Git state: `.git/shallow` lists the one fetched commit; `refs/tags` is empty. Mechanism: `git describe` needs a tag that is reachable from HEAD through parent links. Root cause: `actions/checkout` defaults to fetch-depth 1 and fetch-tags false. Why it does this: one commit is all most jobs need, and it is fast on a large repository. Correct fix: `fetch-depth: 0` on the checkout step of the job that needs history. Prevention: derive versions in one job; never add a fallback such as "or echo 0.0.0", or `--always`, to make the error disappear, because that ships a wrong version.

## LIVE TERMINAL DEMO

**[TERMINAL]** Three replays. All Git, in the sandbox.

**Case 1: a name that differs only in case.** Replay `labs/run ch20b/case-clash`.

The developer's report: "The loader test passes on my Mac. In CI: file not found."

```bash
git config get core.ignorecase
git ls-files configs
cat configs/thresholds.yaml
```

<!-- snippet: ch20b/case-clash/01-works-here -->
```text
# Git recorded the name with a capital T. The loader asks for a lower-case name.
$ git config get core.ignorecase
true
$ git ls-files configs
configs/Thresholds.yaml
$ cat configs/thresholds.yaml
reorder:
  lead_days: 5
  safety_stock: 10
```
<!-- /snippet -->

Look at the three results together. `core.ignorecase` is true. Git recorded the name `Thresholds.yaml`, with a capital T. And `cat` with a lower-case t opens the file. On this machine the code works.

Now the one command that proves the cause.

```bash
git cat-file -e HEAD:configs/thresholds.yaml
git cat-file -e HEAD:configs/Thresholds.yaml
```

`git cat-file -e` tests whether an object exists at that path in the commit. It reads. **[PAUSE]** Git compares names byte by byte. What are the two exit statuses?

<!-- snippet: ch20b/case-clash/02-what-linux-sees -->
```text
# Git itself compares names byte by byte, as a case-sensitive filesystem does:
$ git cat-file -e HEAD:configs/thresholds.yaml
fatal: path 'configs/thresholds.yaml' exists on disk, but not in 'HEAD'
[exit status: 128]
$ git cat-file -e HEAD:configs/Thresholds.yaml
[exit status: 0]
```
<!-- /snippet -->

128 for the lower-case name, with a message that is almost a diagnosis in itself: the path "exists on disk, but not in HEAD". 0 for the name with the capital. Git answered the way a case-sensitive filesystem will. You have proven the cause without a runner.

```bash
git mv configs/Thresholds.yaml configs/thresholds.yaml
git status --short
git commit -q -m "Rename the thresholds file to lower case"
```

`git mv` is 🟢 SAFE: it renames the file and its index entry. `git commit` is 🟢 SAFE.

<!-- snippet: ch20b/case-clash/03-fix -->
```text
# The fix is a rename that Git records, not a change on the laptop only:
$ git mv configs/Thresholds.yaml configs/thresholds.yaml
$ git status --short
R  configs/Thresholds.yaml -> configs/thresholds.yaml
$ git commit -q -m "Rename the thresholds file to lower case"
$ git ls-files configs
configs/thresholds.yaml
```
<!-- /snippet -->

The status shows a rename, `R`, and after the commit `git ls-files` shows the lower-case name. The comment in the transcript is the point: the fix is a rename that Git records. Renaming in Finder changes nothing that Git notices.

<!-- snippet: ch20b/case-clash/04-two-names -->
```text
# The other half of the problem: a commit made on Linux that holds both spellings.
$ git ls-files | grep -i readme
README.md
Readme.md
$ cd ..
$ git clone --quiet warehouse-api second-clone
warning: the following paths have collided (e.g. case-sensitive paths
on a case-insensitive filesystem) and only one from the same
colliding group is in the working tree:

  'README.md'
  'Readme.md'
$ ls second-clone | grep -i readme
Readme.md
```
<!-- /snippet -->

The opposite accident: a commit made on Linux that holds both `README.md` and `Readme.md`. A clone on this Mac prints a warning that paths have collided, and only one of the two is in the working tree. Two files in Git, one on disk.

**Case 2: a script with CRLF line endings.** Replay `labs/run ch20b/line-endings`.

The developer's report: "The first line of the deploy script fails."

<!-- snippet: ch20b/line-endings/01-symptom -->
```text
$ ./scripts/deploy.sh staging
env: bash\r: No such file or directory
[exit status: 127]
```
<!-- /snippet -->

Exit status 127, and the message names an interpreter: `bash` followed by a carriage return. The kernel read the first line of the script and looked for a program with that name.

The one command that proves the cause:

```bash
git ls-files --eol scripts/deploy.sh README.md
git config get core.autocrlf
```

**[PAUSE]** The output has three columns per file: `i/` for the index, which is what is committed; `w/` for the working tree; `attr/` for the attributes in force. What do you expect in the `i/` column for the script?

<!-- snippet: ch20b/line-endings/02-eol -->
```text
# i/ is the index (what is committed), w/ the working tree, attr/ the attributes in force.
$ git ls-files --eol scripts/deploy.sh README.md
i/lf    w/lf    attr/                 	README.md
i/crlf  w/crlf  attr/                 	scripts/deploy.sh
$ git config get core.autocrlf
```
<!-- /snippet -->

`i/crlf`. The committed blob itself contains CRLF. The README is `i/lf`. The attribute column is empty for both, and `core.autocrlf` is unset, so nothing normalised anything. Every clone of this commit gets those bytes.

```bash
printf '* text=auto\n*.sh text eol=lf\n' > .gitattributes
git add --renormalize .
git status --short
git commit -q -m "Normalise line endings; shell scripts are always LF"
git ls-files --eol scripts/deploy.sh
```

`git add --renormalize` is 🟡 CAUTION: it rewrites index entries to normalised line endings. The preview is `git ls-files --eol`, and `git status` afterwards; before committing you can take it back with `git restore --staged`. **[PAUSE]** After the commit, what will the three columns say for the script?

<!-- snippet: ch20b/line-endings/03-fix -->
```text
# Declare the rule in the repository, so that it does not depend on anybody's configuration:
$ printf '* text=auto\n*.sh text eol=lf\n' > .gitattributes
$ git add --renormalize .
$ git status --short
M  scripts/deploy.sh
?? .gitattributes
$ git commit -q -m "Normalise line endings; shell scripts are always LF"
$ git ls-files --eol scripts/deploy.sh
i/lf    w/crlf  attr/text eol=lf      	scripts/deploy.sh
```
<!-- /snippet -->

`i/lf`, the attribute `text eol=lf`, and still `w/crlf`. The index is fixed. This working tree still has the old bytes until the file is checked out again. A fresh clone, which is what a runner makes, gets LF.

The last snippet makes your own working tree catch up. It deletes the file and restores it from the index. `git restore` on a path is 🔴 DANGEROUS, so the five answers. What it changes: the file in the working tree, from the index. What it can destroy: uncommitted content of that file that was never staged. How to preview: `git diff` for the path. How to recover: none for content that was never staged. When it is appropriate: here, where the committed version is the one you want and `git status` shows nothing else pending for that file.

<!-- snippet: ch20b/line-endings/04-working-tree -->
```text
# The index is fixed. The file on disk is rewritten the next time Git checks it out:
$ rm scripts/deploy.sh
$ git restore scripts/deploy.sh
$ git ls-files --eol scripts/deploy.sh
i/lf    w/lf    attr/text eol=lf      	scripts/deploy.sh
$ ./scripts/deploy.sh staging
would deploy to staging
[exit status: 0]
```
<!-- /snippet -->

Now all three columns agree, and the script runs.

**Case 3: a shallow clone has no tags to describe.** Replay `labs/run ch20b/shallow-describe`.

The developer's report: "The version step exits with 128 in CI."

<!-- snippet: ch20b/shallow-describe/01-laptop -->
```text
# Your clone: full history, all tags.
$ git log --oneline --decorate
57c8425 (HEAD -> main) Add the lock file
197d992 Document the release runbook
c4b5de2 (tag: v1.1.0) Add the deploy workflows
3c8340d Add reorder thresholds
e797c71 (tag: v1.0.0) Add the deploy script
91fe9ab Add stock rules and their checks
$ git describe --tags --match 'v*'
v1.1.0-2-g57c8425
```
<!-- /snippet -->

On the laptop: six commits, two tags, and the description `v1.1.0-2-g57c8425`.

```bash
git clone --quiet --depth 1 --no-tags "file://$PWD/warehouse-api" runner
git describe --tags --match 'v*'
```

`git clone` is 🟢 SAFE.

<!-- snippet: ch20b/shallow-describe/02-runner -->
```text
# A clone with one commit and no tags, which is what the checkout action fetches by default:
$ cd ..
$ git clone --quiet --depth 1 --no-tags "file://$PWD/warehouse-api" runner
$ cd runner
$ git log --oneline --decorate
57c8425 (grafted, HEAD -> main, origin/main, origin/HEAD) Add the lock file
$ git tag --list
$ git rev-parse --is-shallow-repository
true
$ git describe --tags --match 'v*'
fatal: No names found, cannot describe anything.
[exit status: 128]
```
<!-- /snippet -->

One commit, marked "grafted". No tags. Shallow: true. And `git describe` exits with 128: "No names found". You have reproduced the CI failure in a directory on your Mac.

<!-- snippet: ch20b/shallow-describe/03-tags-without-history -->
```text
# Fetching the tags alone, still at depth 1, brings the tag objects but not the path to them:
$ git fetch --quiet --depth 1 origin "refs/tags/*:refs/tags/*"
$ git tag --list
v1.0.0
v1.1.0
$ git describe --tags --match 'v*'
fatal: No tags can describe '57c8425908f43c74c14b2642edb59e0f99dac38c'.
Try --always, or create some tags.
[exit status: 128]
$ git rev-list --count HEAD
1
```
<!-- /snippet -->

Fetching the tags alone, still at depth 1: both tags exist now, and the error changes to "No tags can describe". The textbook's comment: both messages mean the same root cause. The history is one commit long.

```bash
git fetch --quiet --unshallow --tags
```

🟢 SAFE: it adds objects and tags and removes `.git/shallow`.

<!-- snippet: ch20b/shallow-describe/04-full-history -->
```text
# With the whole history the tag is reachable from HEAD again:
$ git fetch --quiet --unshallow --tags
$ git rev-parse --is-shallow-repository
false
$ git rev-list --count HEAD
6
$ git describe --tags --match 'v*'
v1.1.0-2-g57c8425
```
<!-- /snippet -->

Not shallow, six commits, and the same description as on the laptop. In the workflow, the minimal fix is `fetch-depth: 0` on the checkout step of the one job that needs it.

## COMMON MISTAKES

1. **Fixing a case problem by renaming the file in Finder.** Root cause: on a case-insensitive filesystem Git does not see that as a change; the name in the index stays as it was until `git mv` records the rename.
2. **Checking line endings by opening the file.** Root cause: the question is what the committed blob contains, and only the `i/` column of `git ls-files --eol` answers that.
3. **Relying on each developer's `core.autocrlf`.** Root cause: that is local configuration; a rule in `.gitattributes` is in the repository and applies to every clone.
4. **Adding `--always` or a fallback version to make the describe step pass.** Root cause: the step then ships a wrong version; the cause is the shallow, tagless clone.
5. **Saying "it is the same commit" and stopping there.** Root cause: the filesystem, the depth of the clone, the commit the job checked out and the shell are inputs too.

## PRODUCTION EXAMPLE

A team trains and evaluates models from one repository, with engineers on Macs and CI on Linux. A new engineer adds a configuration loader and a configuration file. The file was first saved with a capital letter and added to Git that way. Later the engineer "renamed" it in the editor's file tree, and the code refers to the lower-case name. Every test passes on every Mac in the team for a week, because each Mac answers for both spellings. The first pull request that makes CI load that file fails with file-not-found.

Step 2 of the investigation order says the commit is right. Step 4 says the machine differs. One command, `git ls-files` for the directory, shows the recorded name. One `git mv`, one commit, and it is fixed for every machine.

The prevention the team adopts is a check that asks Git, not the disk, for the names the code needs.

## PRACTICE EXERCISE

Do Lab 28.1, "Six broken workflows", in [`lab-manual/m28-runners-debugging-ci.md`](../../lab-manual/m28-runners-debugging-ci.md).

The lab tells you how to start: first write, for each of the six files, your hypothesis and the line you suspect. Only then collect the evidence Git can give. For each, also write the layer the cause belongs to: Git, GitHub, or GitHub Actions.

The challenge is Incident 7, [`incidents/07-ci-passes-locally`](../../incidents/07-ci-passes-locally/SYMPTOMS.md). Read the symptoms file only; the generator script is the answer to "what happened".

## INTERVIEW QUESTION

**[ON SCREEN]** Q301: "A test passes on a Mac and fails on `ubuntu-24.04` with a file-not-found error. How do you prove the cause with Git alone?"

A strong answer names the suspected mechanism in one sentence and then gives the proof as commands that read what Git has recorded, not what is on the disk, and says what result confirms it. It gives the fix as something Git records, and says why a rename outside Git does not work. The follow-up reverses the accident, with a commit from Linux that holds two names differing only in case, and then asks which other Git-level cause the chapter reproduces; you have seen both in this video.

## RECAP

You should now be able to say:

- The same commit is not the same input: the filesystem, the depth of the clone, the commit the job checked out and the shell all differ.
- A case problem is proven with `git cat-file -e` or `git ls-files`, which compare names byte by byte, and fixed with `git mv`.
- A line-ending problem is proven with `git ls-files --eol`, where `i/crlf` means the committed blob has CRLF, and fixed with `.gitattributes` and `git add --renormalize`.
- A shallow-clone problem is reproduced with a clone at depth 1 without tags, and fixed with `fetch-depth: 0` in the job that needs history.
- Each cause has a Git-side test that needs no re-run of the workflow.

## HOMEWORK

Read section 20B.12 of [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md). Do Exercise 28.6, "The machine changed, the code did not", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).
