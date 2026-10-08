# V153: "Passes locally, fails on GitHub Actions": the documented causes

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 28
- **Planned minutes.** 24
- **Prerequisites.** V014, V087, V145, V152
- **Textbook sections.** [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), section 20B.12
- **Demo scripts.** `labs/ch20b/case-clash.sh`, `labs/ch20b/line-endings.sh`, `labs/ch20b/shallow-describe.sh`

## HOOK

**[ON SCREEN]** Three messages from three developers, in one week.

Three messages. CI here means the automated checks that GitHub Actions runs on each change, and a commit is one saved snapshot of the project.

**[ANIMATION]** cards: id=msgs question=Three_messages,_one_week cards=The_loader_test_passes_on_my_Mac:in_CI,_the_configuration_file_does_not_exist|The_deploy_script_works_when_I_run_it:in_CI,_the_very_first_line_fails|The_version_step_works_on_every_laptop:in_CI,_it_exits_with_128 numbered=on

**[ANIMATION]** step: 1

"The loader test passes on my Mac. In CI it says the configuration file does not exist. The file is right there in the repository."

**[ANIMATION]** step: 2

"The deploy script works when I run it. In CI the very first line fails, something about bash and a strange character."

**[ANIMATION]** step: 3

"The version step works on every laptop in the team. In CI it exits with 128."

**[ANIMATION]** say: Each_message_ends:_"and_it_is_the_same_commit"

Each of them ends the message the same way: "and it is the same commit." They're right about that. Same commit, and still not the same input. The machine is different, the clone is different, and in the first two cases what they have on their own disk isn't what Git has recorded.

**[ANIMATION]** end

All three can be proven on your own machine, with Git alone, without re-running anything on GitHub. And keep the phrase "the same commit" in mind. By the end you'll have four questions to ask whenever you hear it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you learned the investigation order. This video is the catalogue that the order leads you into: the documented causes of a test that passes locally and fails on GitHub Actions.

The textbook lists fourteen. Twelve are GitHub Actions behavior, and you've met most of them in the last ten videos. Two are Git. The demonstration takes the two Git causes, case sensitivity and line endings, and adds the shallow clone, because all three can be reproduced locally.

For each of the three the form is the same: the symptom as the developer would report it, then the one command that proves the cause, then the fix that Git records.

One caveat about the transcripts. The case-sensitivity demonstration depends on a case-insensitive volume, which is the macOS default. On a case-sensitive volume the first command fails and there is no collision warning.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- list the documented causes of a test that passes on a Mac and fails on the runner;
- prove a case-sensitivity cause with Git alone;
- prove a line-ending cause with `git ls-files --eol` and fix it with attributes;
- prove a shallow-clone cause and give the minimal fix;
- explain why "same commit" is not the same input.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions. The table of section 20B.12, in groups.

Here are the fourteen rows of the textbook's table, in two pages.

Go through the fourteen rows grouped by where they sit in the investigation order.

**[ANIMATION]** walk: id=fourteen columns=where_in_the_order,documented_causes rows=the_commit_and_the_clone:a_shallow,_tagless_clone;_not_the_pushed_commit|authority:missing_secrets|the_machine:shell_differences;_moving_images_and_tools;_out_of_memory_or_time;_environment_differences|what_the_run_depends_on:old_action_majors;_a_stale_or_missing_cache|whether_a_run_exists:a_check_that_stays_pending;_cancelled_runs;_a_workflow_that_never_fires|Git:case_sensitivity;_line_endings marks=6.1:hl,6.2:hl mono=off title=Fourteen_documented_causes

**[ANIMATION]** step: 1

**About the commit and the clone.** A shallow, tagless clone: the checkout fetches one commit and no tags, so `git describe` and tag-derived versions fail. A tag is a fixed name for one commit, and `git describe` builds a name from a tag in the history. The remedy is `fetch-depth: 0`. And the job isn't testing the pushed commit: on `pull_request` it checks out the test merge in detached HEAD, and it doesn't run at all while the pull request conflicts. The remedy is to merge or rebase the base locally to reproduce.

**[ANIMATION]** step: 2

**About authority.** Missing secrets. A secret is an encrypted value stored in GitHub's settings. Secrets aren't passed to runs from forks or from Dependabot. The token is read-only. And an unset secret is an empty string. The remedy is fork-safe jobs, and the textbook adds: never `pull_request_target` as a shortcut.

**[ANIMATION]** step: 3

**About the machine.** Shell differences: the implicit shell on Linux and macOS is `bash -e` without `pipefail`, and `shell: bash` adds it. In a job container the default is `sh`. On Windows it's PowerShell. Moving images and tools: weekly image rebuilds, and every `-latest` label moved in 2026. Out of memory or time: smaller runners in private repositories, and the six-hour limit. Environment differences: the variable `CI` is set to true, steps share no shell state, and every job is a new machine.

**[ANIMATION]** step: 4

**About what the run depends on.** Old action majors: actions written for Node 20 now run on Node 24. A stale or missing cache: a cache is immutable per key, restore keys take the most recent prefix match, and pull request caches are scoped to the merge ref.

**[ANIMATION]** step: 5

**About whether a run exists.** A required check that stays pending, because a workflow skipped by a filter or by `[skip ci]` never reports. Runs cancelled by a newer run in the same concurrency group. And a workflow that never fires: events made with the job token start no runs, and scheduled workflows are disabled after 60 days without repository activity in public repositories.

**[ON SCREEN]** Lower third: Git.

**[ANIMATION]** step: 6

**And the two that are Git.** Case sensitivity: macOS and Windows filesystems ignore case by default, and a Linux runner doesn't. The remedy is to fix the names in Git. Line endings: CRLF committed, or converted on checkout by `core.autocrlf`. CRLF is a line ending of two characters, a carriage return and then a line feed, and LF is the line feed alone. The remedy is `.gitattributes`.

**[ANIMATION]** end

**[ON SCREEN]** Callout: Unverified.

The textbook attaches a caveat here and I keep it. The official Actions pages read for the Phase 0 report don't state the time zone and locale of hosted runners, whether Windows runners check out with CRLF by default, or whether the hosted runners' filesystems are case-sensitive. Only the Git mechanisms are sourced, from Git's documentation and from real runs. Linux filesystems being case-sensitive is the general rule the chapter relies on.

**[ANIMATION]** stores: id=rec boxes=your_Mac:a_filesystem_that_ignores_case|*Git's_records:names_and_bytes,_compared_byte_by_byte|a_Linux_runner:a_filesystem_that_distinguishes_case rows=1:B:a_name_with_a_capital_letter|2:A:the_code_asks_for_the_lower-case_name:_the_file_opens@ok|2:C:the_same_request:_no_such_file@bad|3:B:a_blob_whose_bytes_contain_carriage_returns|3:C:an_interpreter_whose_name_ends_in_a_carriage_return@bad title=One_record,_two_machines at_1=45 at_2=75

**[ANIMATION]** step: 2

**Why the two Git causes happen at all.** For case: when Git creates a repository it tests the filesystem, and on a case-insensitive one it sets `core.ignorecase` to true. Git's own records compare names byte by byte. Those records are the index, which is the proposed next commit, and the trees, the directory listings inside commits. So Git can hold a name with a capital letter, your code can ask for the lower-case name, and on your Mac the file opens, because the filesystem answers for both spellings. On a filesystem that distinguishes case, it doesn't.

**[ANIMATION]** step: 3

For line endings: a blob, the stored content of one file, is bytes. If the bytes contain carriage returns, every checkout that doesn't convert them gets carriage returns. A shell script whose first line ends in a carriage return asks the kernel for an interpreter whose name ends in that character.

**[ANIMATION]** say: The_laptop_is_the_forgiving_machine:_it_hides_what_is_recorded_in_Git

In both cases, the laptop is the forgiving machine, and the forgiveness hides what is recorded in Git.

## MENTAL MODEL

Let's take that phrase apart.

"Same commit" means: the same tree, the same bytes in every blob, the same names. It says nothing about four other inputs.

**[ANIMATION]** cards: id=four question="Same_commit"_says_nothing_about_four_other_inputs cards=the_filesystem:the_names_are_written_onto_it|how_much_of_the_repository_came_along:the_history_and_the_tags|which_commit_the_job_took|the_process_that_runs_your_command:the_shell_and_its_options numbered=on

**[ANIMATION]** step: 1

The filesystem that the names are written onto. A name is recorded once in Git and interpreted by each machine's filesystem.

**[ANIMATION]** step: 2

How much of the repository came along. The commit is the same. The history and the tags around it aren't.

**[ANIMATION]** step: 3

Which commit the job took. On a pull request it's not your commit at all.

**[ANIMATION]** step: 4

And the process that runs your command: the shell and its options.

So when someone says "it is the same commit", agree, and then ask the four questions. There they are, as promised at the start. For each there is a Git-side test that needs no re-run of the workflow, and the demonstration shows three of them.

Where this model has an edge: the first two demonstrations aren't really differences between the Mac and the runner. They're differences between what is on your disk and what is in Git. The runner only sees what is in Git. That's why the proof in each case is a Git command that reads the index or a commit, and not a command that reads a file.

## DIAGRAM

**[ANIMATION]** walk: id=mac columns=-,your_Mac,the_runner_(Linux_job) rows=checkout_depth:full_history:one_commit;_.git/shallow_lists_it|tags:all_tags:none|commit_tested:your_branch_tip:on_pull__request:_the_test_merge_under_refs/pull/N/merge,_detached_HEAD|shell_for_run:your_interactive_shell:bash_-e_{0};_with_shell:_bash,_bash_--noprofile_--norc_-eo_pipefail_{0}|filesystem:ignores_case_by_default;_core.ignorecase_=_true:case-sensitive_(the_general_rule_for_Linux;_not_stated_on_the_Actions_pages) mono=off title=Your_Mac_and_the_runner

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

**[ANIMATION]** step: 4

Try it now. Thirty seconds, in any repository on your own machine. Run `git config get core.ignorecase`, which only reads. What does it print?

**[PAUSE]**

**[ANIMATION]** step: 5

If it prints true, Git found a filesystem that ignores case when it created that repository, which is the macOS default. Then the left column of this table describes your own disk.

**[ON SCREEN]** The root-cause box of section 20B.12, one line at a time. Observed behavior: the version step fails in the job; the same command works on every laptop. Git state: `.git/shallow` lists the one fetched commit; `refs/tags` is empty. Mechanism: `git describe` needs a tag that is reachable from HEAD through parent links. Root cause: `actions/checkout` defaults to fetch-depth 1 and fetch-tags false. Why it does this: one commit is all most jobs need, and it is fast on a large repository. Correct fix: `fetch-depth: 0` on the checkout step of the job that needs history. Prevention: derive versions in one job; never add a fallback such as "or echo 0.0.0", or `--always`, to make the error disappear, because that ships a wrong version.

Read the root-cause line: actions/checkout defaults to fetch-depth 1 and fetch-tags false.

## LIVE TERMINAL DEMO

Into the lab.

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

`git cat-file -e` tests whether an object exists at that path in the commit. It reads.

Quick quiz. Git compares names byte by byte. Which of the two commands succeeds? A, the lower-case name. B, the name with the capital T. C, both. Your answer?

**[PAUSE]**

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

B. 128 for the lower-case name, with a message that is almost a diagnosis in itself: the path "exists on disk, but not in HEAD". 0 for the name with the capital.

**[ANIMATION]** step: rec.3

**[ANIMATION]** say: Git_recorded_configs/Thresholds.yaml._The_code_asks_for_configs/thresholds.yaml

Git answered the way a case-sensitive filesystem will. If you said C, that's the Mac's answer, not Git's. You've proven the cause without a runner.

**[ANIMATION]** end

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

The output has three columns per file. `i/` is the index, which is what is committed. `w/` is the working tree, the files on your disk. `attr/` is the attributes in force. What do you expect in the `i/` column for the script? Say it out loud.

**[PAUSE]**

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

`git add --renormalize` is 🟡 CAUTION: it rewrites index entries to normalised line endings. The preview is `git ls-files --eol`, and `git status` afterwards. Before committing you can take it back with `git restore --staged`.

After the commit, what will the three columns say for the script? Make your prediction.

**[PAUSE]**

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

`i/lf`, the attribute `text eol=lf`, and still `w/crlf`.

**[ANIMATION]** trees: id=eol file=scripts/deploy.sh versions=CRLF,LF say_setup=The_commit,_the_index_and_the_working_tree_all_hold_CRLF steps=setup,add,commit,restore cmd_add=git_add_--renormalize_. cmd_restore=git_restore_scripts/deploy.sh history=off title=Three_places,_one_file say_add=The_index_gets_LF say_commit=The_commit_holds_LF._The_working_tree_still_has_the_old_bytes say_restore=Checked_out_again:_LF_everywhere at_add=5 at_commit=35

**[ANIMATION]** step: commit

The index is fixed. This working tree still has the old bytes until the file is checked out again. A fresh clone, which is what a runner makes, gets LF.

**[ANIMATION]** end

The last snippet makes your own working tree catch up. It deletes the file and restores it from the index. `git restore` on a path is 🔴 DANGEROUS, so the five answers. What it changes: the file in the working tree, from the index. What it can destroy: uncommitted content of that file that was never staged. How to preview: `git diff` for the path. How to recover: none for content that was never staged. When it's appropriate: here, where the committed version is the one you want and `git status` shows nothing else pending for that file.

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

**[ANIMATION]** step: eol.restore

In the three-trees picture: the working tree holds LF now, too.

**[ANIMATION]** end

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

**[ANIMATION]** graph: id=six 91fe9ab-e797c71-3c8340d-c4b5de2-197d992-57c8425 main; e797c71 v1.0.0; c4b5de2 v1.1.0; HEAD=main; title:Your_clone:_full_history,_all_tags => + absent:91fe9ab,e797c71,3c8340d,c4b5de2,197d992; drop:v1.0.0,v1.1.0; note:57c8425:grafted; title:The_runner's_clone; name:cut; say:One_commit_and_no_tags => + absent:91fe9ab,3c8340d,197d992; e797c71 v1.0.0; c4b5de2 v1.1.0; name:tags; say:Both_tags_exist_now._The_history_is_still_one_commit_long => + absent:; drop:57c8425; name:full; say:Six_commits_again:_v1.1.0-2-g57c8425 at_cut=70

**[ANIMATION]** step: cut

Here's that history as a picture: six commits in a row, two tags, and `main` on the newest. The runner is about to receive only that last commit.

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

Fetching the tags alone, still at depth 1: both tags exist now, and the error changes to "No tags can describe".

**[ANIMATION]** step: six.tags

The textbook's comment: both messages mean the same root cause. The history is one commit long.

**[ANIMATION]** end

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

Not shallow, six commits, and the same description as on the laptop.

**[ANIMATION]** step: six.full

In the workflow, the minimal fix is `fetch-depth: 0` on the checkout step of the one job that needs it.

**[ANIMATION]** end

## COMMON MISTAKES

Five mistakes to watch for.

1. **Fixing a case problem by renaming the file in Finder.** Root cause: on a case-insensitive filesystem Git does not see that as a change; the name in the index stays as it was until `git mv` records the rename.
2. **Checking line endings by opening the file.** Root cause: the question is what the committed blob contains, and only the `i/` column of `git ls-files --eol` answers that.
3. **Relying on each developer's `core.autocrlf`.** Root cause: that is local configuration; a rule in `.gitattributes` is in the repository and applies to every clone.
4. **Adding `--always` or a fallback version to make the describe step pass.** Root cause: the step then ships a wrong version; the cause is the shallow, tagless clone.
5. **Saying "it is the same commit" and stopping there.** Root cause: the filesystem, the depth of the clone, the commit the job checked out and the shell are inputs too.

## PRODUCTION EXAMPLE

Now, out of the lab. A team trains and evaluates models from one repository, with engineers on Macs and CI on Linux. A new engineer adds a configuration loader and a configuration file. The file was first saved with a capital letter and added to Git that way. Later the engineer "renamed" it in the editor's file tree, and the code refers to the lower-case name. Every test passes on every Mac in the team for a week, because each Mac answers for both spellings. The first pull request that makes CI load that file fails with file-not-found.

**[ANIMATION]** step: rec.3

**[ANIMATION]** say: One_git_mv,_one_commit:_fixed_for_every_machine

Step 2 of the investigation order says the commit is right. Step 4 says the machine differs. One command, `git ls-files` for the directory, shows the recorded name. One `git mv`, one commit, and it's fixed for every machine.

**[ANIMATION]** end

The prevention the team adopts is a check that asks Git, not the disk, for the names the code needs.

## PRACTICE EXERCISE

Your turn. Do Lab 28.1, "Six broken workflows", in [`lab-manual/m28-runners-debugging-ci.md`](../../lab-manual/m28-runners-debugging-ci.md).

The lab tells you how to start: first write, for each of the six files, your hypothesis and the line you suspect. Only then collect the evidence Git can give. For each, also write the layer the cause belongs to: Git, GitHub, or GitHub Actions.

The challenge is Incident 7, [`incidents/07-ci-passes-locally`](../../incidents/07-ci-passes-locally/SYMPTOMS.md). Read the symptoms file only. The generator script is the answer to "what happened".

## INTERVIEW QUESTION

**[ON SCREEN]** Q301: "A test passes on a Mac and fails on `ubuntu-24.04` with a file-not-found error. How do you prove the cause with Git alone?"

**[PAUSE]**

Answer out loud. A strong answer names the suspected mechanism in one sentence and then gives the proof as commands that read what Git has recorded, not what is on the disk, and says what result confirms it. It gives the fix as something Git records, and says why a rename outside Git doesn't work. The follow-up reverses the accident, with a commit from Linux that holds two names differing only in case, and then asks which other Git-level cause the chapter reproduces. You've seen both in this video.

## RECAP

Let's land this.

You should now be able to say:

- The same commit is not the same input: the filesystem, the depth of the clone, the commit the job checked out and the shell all differ.
- A case problem is proven with `git cat-file -e` or `git ls-files`, which compare names byte by byte, and fixed with `git mv`.
- A line-ending problem is proven with `git ls-files --eol`, where `i/crlf` means the committed blob has CRLF, and fixed with `.gitattributes` and `git add --renormalize`.
- A shallow-clone problem is reproduced with a clone at depth 1 without tags, and fixed with `fetch-depth: 0` in the job that needs history.
- Each cause has a Git-side test that needs no re-run of the workflow.

## HOMEWORK

Read section 20B.12 of [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md). Do Exercise 28.6, "The machine changed, the code did not", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

Three reports, three proofs, and not one re-run. The next time someone says "it's the same commit", you have four questions ready. Try the `--eol` listing on a repository of your own. Next time: required checks that stay pending, the debugging instruments, linting, and what a local emulator can't reproduce. Until then, look at the state first and type second. See you in the next one.
