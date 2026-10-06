# V090: --no-verify, core.hooksPath, sharing hooks, hook security, and why hooks cannot enforce policy

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 14, Worktrees, attributes, hooks, stash internals, rerere
- **Planned minutes.** 22
- **Prerequisites.** V089
- **Textbook sections.** [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md), sections 14C.11 to 14C.16
- **Demo scripts.** `labs/ch14c/hooks-sharing.sh`, `labs/ch14c/hook-untrusted.sh`, `labs/ch14c/lab-14-3-pre-push-guard.sh` (the failure and recovery parts)

## HOOK

**[ON SCREEN]** "We have a pre-commit hook that blocks secrets. A secret is on `main`. Whose fault is that?"

The textbook's answer is one sentence: nobody's, as far as Git is concerned. A hook is a program that Git runs at a fixed point of a command. A client-side hook is a file in one clone that one option skips. Policy is enforced where every push arrives: on the server and in CI, the automated checks.

There's a second story in this video, and it runs the other way. You download a research repository as a tar file, unpack it, and type the most innocent command there is: `git status`. A program written by the author of the archive runs on your machine, with your permissions. How can looking be dangerous? Hold that question.

**[ANIMATION]** stores: id=clone boxes=the_original:its_.git_directory|*a_clone:git_clone|an_unpacked_archive:tar_-xf rows=1:A:objects|1:A:refs|1:A:.git/config|1:A:.git/hooks|2:B:objects@ok|2:B:refs@ok|3:C:objects|3:C:refs|3:C:.git/config@bad|3:C:.git/hooks@bad arrows=2:A1>B1:clone|3:A>C:copied_as_files title=What_a_clone_copies

**[ANIMATION]** step: clone.2

Both stories are the same fact seen from two sides. Hooks and configuration are local and aren't copied by a clone. That's why you can't push your hook onto a colleague. It's also why a clone is safe to look at and an unpacked `.git` directory isn't.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the previous video you learned which hooks run when, and you wrote five. You also saw three gaps: commands that create commits without the commit hooks, the index-versus-disk trap, and `--no-verify`.

Today: why hooks aren't cloned, the ways to share them and what each one costs, what hooks and configuration mean for security, and where a rule has to live if it must hold for everyone.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- explain why hooks are not cloned;
- share hooks through `core.hooksPath` and through hooks defined in configuration, and give the cost of each;
- run a hook by name with `git hook run`;
- show what an unpacked archive of a repository can execute that a clone cannot;
- state what enforces policy when a client-side hook does not.

## CONCEPT

**[ANIMATION]** say: git clone transfers objects and refs, and nothing else

**Why hooks are not cloned.** `git clone` transfers objects and refs: the stored snapshots, and the names that point at them. `.git/hooks` and `.git/config` aren't transferred, by design. Otherwise cloning a repository would mean agreeing to run its author's programs.

**[ANIMATION]** stores: id=share boxes=your_clone:hooks-sharing|Asha's_clone:after_git_pull rows=1:A:.githooks/pre-commit_(tracked)|1:A:core.hooksPath=.githooks@hl|2:B:.githooks/pre-commit@ok|3:B:core.hooksPath:_not_set_yet@bad|4:B:she_sets_core.hooksPath@ok arrows=2:A1>B1:pull mono=on title=A_tracked_directory_and_core.hooksPath

**[ANIMATION]** step: share.2

**Sharing, first way: a tracked directory and `core.hooksPath`.** Keep the hooks in the repository and tell Git to look there. The directory travels. The setting is configuration, and each clone must make it once. The cost: from then on every pull can change what runs on the next commit. Review changes under that directory as carefully as changes to CI.

**[ANIMATION]** end

**Sharing, second way: hooks defined in configuration.** Since Git 2.54 a hook can be declared as `hook.<name>.command` plus one or more `hook.<name>.event` values, in any configuration file. One script can serve several events and several repositories, and several hooks can share an event. `hook.<name>.enabled=false` switches one hook off. The textbook adds that `hook.<name>.parallel` and `hook.jobs` allow parallel runs since Git 2.55, except for hooks such as `pre-commit` and `commit-msg` that touch shared state. The cost: a hook defined in a global configuration file runs in every repository of that user. That suits a personal secret scanner, and equally an attacker who can write to that file.

**Other ways to distribute.** `init.templateDir` names a directory whose contents are copied into every new `.git`, hooks included, on one person's machine. A setup script that copies files into `.git/hooks` works everywhere and has to be run. Hook managers automate that step.

**[ANIMATION]** walk: id=nv columns=command,--no-verify_skips rows=git_commit:pre-commit,_commit-msg|git_merge:pre-merge-commit,_commit-msg|git_push:pre-push|git_rebase:pre-rebase|git_am:applypatch-msg,_pre-applypatch|a_server-side_hook:no_option_skips_it marks=6.2:bad title=--no-verify_in_full

**[ANIMATION]** step: nv.6

**`--no-verify` in full.** With `git commit` it skips `pre-commit` and `commit-msg`. With `git merge`, `pre-merge-commit` and `commit-msg`. With `git push`, `pre-push`. With `git rebase`, `pre-rebase`. With `git am`, `applypatch-msg` and `pre-applypatch`. No option skips a server-side hook.

**[ANIMATION]** step: clone.3

**Hook security.** In one sentence: a hook, and several configuration values, are commands that run with your permissions, so the question "is it safe to use this repository" is the question "where did its `.git` directory come from". The security section of the `git` manual draws the line. Because configuration and hooks aren't copied by `git clone`, it's generally safe to clone a repository with untrusted content and inspect it. It isn't safe to run Git commands in a `.git` directory, or the working tree around it, that itself came from an untrusted source such as an archive or a shared folder.

**[ANIMATION]** cards: id=threat cards=Hooks_you_chose_to_run:a_pull_updates_the_programs_on_my_machine|Hooks_in_global_configuration|Repositories_owned_by_someone_else:refused_unless_safe.directory_lists_them|Bugs_that_write_into_.git_during_a_clone:CVE-2024-32002|A_bare_repository_inside_a_working_tree:a_later_chapter numbered=on title=The_rest_of_the_threat_model

The rest of the threat model, in the order you're likely to meet it. Hooks you chose to run: a tracked hooks directory, an included configuration file and a hook manager turn "pull" into "update the programs that run on my machine". Hooks in global configuration. Repositories owned by someone else: Git refuses them unless `safe.directory` lists them. Bugs that write into `.git` during a clone: the textbook cites CVE-2024-32002, which got a hook written into a submodule's `.git` and run while the clone was in progress. So keep Git current, and don't clone untrusted repositories with `--recurse-submodules`. And a bare repository inside a working tree, which a later chapter shows.

**[ANIMATION]** cards: id=open question=A_client-side_hook_fails_open_in_four_ways cards=It_isn't_installed_by_cloning|One_option_skips_it|Web_interface,_API,_another_Git_implementation:no_hook_runs|Several_commands_that_create_commits:don't_run_the_commit_hooks numbered=on

**[ANIMATION]** step: open.4

**Why hooks cannot enforce policy.** A client-side hook fails open in four ways. It isn't installed by cloning. One option skips it. It doesn't run for commits made in the web interface, through an API, or by a tool with its own Git implementation, a coding agent's for example. And several Git commands that create commits don't run the commit hooks at all.

**[ANIMATION]** end

Enforcement needs a place that every change must pass and that its author doesn't control. There are two. The server: on a Git server that you run, the server-side hooks `pre-receive` and `update`. And CI as a required check: whatever a hook checks locally, a workflow can check for every pull request, and a ruleset, GitHub's list of rules, can require it before a merge. The hook then saves a round trip, and the check is the control. Run the same script in both places.

## MENTAL MODEL

Keep the tripwires from the last video. You place them in your own workshop. They do nothing in a colleague's. You can step over them.

Today add the door. Every delivery, from every workshop, passes one door: the server that receives the push, and the CI run that a merge requires. A check at the door doesn't care how the delivery was packed or whether its sender has tripwires.

**[ANIMATION]** say: A clone brings the goods. An archive brings the whole workshop.

For security, turn the picture around. When you clone, you receive the goods: objects and refs. When you unpack someone's archive that contains a `.git` directory, you move into their workshop, with their tripwires already set, and the wires are connected to programs of their choosing.

**[ANIMATION]** end

Try it now, on paper, thirty seconds. Write three layers: a client-side hook, a server-side check, and CI as a required check. Mark every layer its author can skip. I'll wait.

**[PAUSE]**

## DIAGRAM

**[DIAGRAM]** Three layers. Mark "can be skipped by the author" on the first only.

```text
   layer                     where it runs             who installs it           can the author skip it?
   ------------------------  ------------------------  ------------------------  ------------------------------------
   1. client-side hook       the author's clone        each clone, once          YES: not installed, --no-verify,
      (pre-commit, pre-push)                                                     web or API commits, commands that
                                                                                 run no commit hooks
   2. server-side check      where every push arrives  the server's              no
      (pre-receive, update;                            administrator
      on GitHub: rulesets,
      push protection)
   3. CI as a required       a workflow, required      the repository's          no, when a ruleset requires the
      check                  before a merge            maintainers               check before merging
```

Only the first layer gets a mark. The first layer is feedback. The second and third are controls. The same script can run in the first and the third.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14c/hooks-sharing`. Your clone has a `pre-commit` hook that refuses a staged line containing the marker NOCOMMIT.

```bash
cat .git/hooks/pre-commit
git commit -am "Debug inference"
```

<!-- snippet: ch14c/hooks-sharing/01-not-cloned -->
```text
$ cat .git/hooks/pre-commit
#!/bin/sh
# Refuse a commit whose staged changes add the marker NOCOMMIT.
if git diff --cached -U0 | grep -q '^+.*NOCOMMIT'; then
  echo "check-marker: a staged line contains NOCOMMIT" >&2
  exit 1
fi
$ printf 'def infer(batch):\n    print(batch)  # NOCOMMIT\n    return model(batch)\n' > infer.py
$ git commit -am "Debug inference"
check-marker: a staged line contains NOCOMMIT
[exit status: 1]
# A teammate clones the same repository:
$ git clone -q ../server.git ../asha
$ ls ../asha/.git/hooks | grep -v sample
$ printf 'def infer(batch):\n    print(batch)  # NOCOMMIT\n    return model(batch)\n' > ../asha/infer.py
$ git -C ../asha commit -q -am "Debug inference"
[exit status: 0]
$ git -C ../asha log --oneline -1
069b8ab Debug inference
```
<!-- /snippet -->

Your clone refuses the debug line. The rest of the snippet shows Asha's clone of the same repository: it has no hook, and her commit is made.

The first way to share. 🟡 CAUTION: `git config set core.hooksPath` decides which programs Git runs on your machine.

```bash
mkdir .githooks && mv .git/hooks/pre-commit .githooks/pre-commit
git add .githooks && git commit -q -m "Share hooks through .githooks" && git push -q
git config set core.hooksPath .githooks
git rev-parse --git-path hooks
git -C ../asha pull -q
ls ../asha/.githooks
```

Predict: after Asha's pull, does the hook run in her clone? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch14c/hooks-sharing/02-hookspath -->
```text
# Put the hook into a tracked directory and point core.hooksPath at it:
$ mkdir .githooks && mv .git/hooks/pre-commit .githooks/pre-commit
$ git add .githooks && git commit -q -m "Share hooks through .githooks" && git push -q
$ git config set core.hooksPath .githooks
$ git rev-parse --git-path hooks
.githooks
# The directory arrives with a pull. The setting does not: every clone must make it once.
$ git -C ../asha pull -q
$ ls ../asha/.githooks
pre-commit
$ git -C ../asha config get core.hooksPath
[exit status: 1]
$ git -C ../asha config set core.hooksPath .githooks
$ printf 'def infer(batch):\n    print(batch)  # NOCOMMIT\n    return model(batch)\n' > ../asha/infer.py
$ git -C ../asha commit -q -am "Debug inference"
check-marker: a staged line contains NOCOMMIT
[exit status: 1]
```
<!-- /snippet -->

Not yet. The directory arrived with the pull. The setting didn't.

**[ANIMATION]** step: share.4

Until she runs the `git config set` herself, her clone still looks in `.git/hooks`. A relative `core.hooksPath` is relative to the directory in which the hook runs, the top of the working tree.

**[ANIMATION]** end

The second way: hooks as configuration entries.

```bash
git config unset core.hooksPath
git config set hook.marker.command .githooks/pre-commit
git config set --append hook.marker.event pre-commit
git config set --global hook.whoami.command 'echo "committing as $(git config get user.email)"'
git config set --global hook.whoami.event pre-commit
git hook list --show-scope pre-commit
```

<!-- snippet: ch14c/hooks-sharing/03-config-hooks -->
```text
# Since Git 2.54 a hook can be a configuration entry: a name, a command, and one or more events.
$ git config unset core.hooksPath
$ git config set hook.marker.command .githooks/pre-commit
$ git config set --append hook.marker.event pre-commit
$ git config set --global hook.whoami.command 'echo "committing as $(git config get user.email)"'
$ git config set --global hook.whoami.event pre-commit
$ printf '#!/bin/sh\necho "hook file in .git/hooks ran"\n' > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
$ git hook list --show-scope pre-commit
global	whoami
local	marker
hook from hookdir
$ git commit --allow-empty -m "Empty commit to watch the hooks"
committing as you@example.com
hook file in .git/hooks ran
[main 8696828] Empty commit to watch the hooks
```
<!-- /snippet -->

Three hooks for one event now: a global one, a local one named `marker`, and a hook file in `.git/hooks`.

**[ANIMATION]** layers: id=three probe=git_commit:_event_pre-commit layers=global_configuration:whoami|local_configuration:marker|.git/hooks:the_hook_file result=whoami+marker+hook_file rule=run_in_this_order title=git_hook_list_--show-scope_pre-commit

`git hook list --show-scope` is the first diagnostic for "why did something run". It shows, in order of execution, the configured hooks with the scope of the file that defined them, and last the file in the hooks directory.

**[ANIMATION]** sandbox: steps=room,outside,shield

One reassurance about that word global. Here it's the lab's isolated global file, not your own. The lab is a sealed room. Your real configuration stays outside it, and nothing typed in the lab reaches it.

**[ANIMATION]** end

Now the switches. A quick quiz: does `core.hooksPath=/dev/null` silence every hook, or only the hooks directory? Say it out loud.

**[PAUSE]**

```bash
git -c core.hooksPath=/dev/null commit --allow-empty -m "Second empty commit"
git commit --no-verify --allow-empty -m "Third empty commit"
git config set hook.whoami.enabled false
```

<!-- snippet: ch14c/hooks-sharing/04-switches -->
```text
# core.hooksPath=/dev/null silences the hooks directory, not the configured hooks:
$ git -c core.hooksPath=/dev/null commit --allow-empty -m "Second empty commit"
committing as you@example.com
[main 2acf6fa] Second empty commit
# --no-verify skips every pre-commit hook, wherever it is defined:
$ git commit --no-verify --allow-empty -m "Third empty commit"
[main 500a741] Third empty commit
# One named hook off, in this repository only:
$ git config set hook.whoami.enabled false
$ git hook list --show-scope pre-commit
global	disabled	whoami
local	marker
hook from hookdir
```
<!-- /snippet -->

Only the hooks directory. If you said every hook, the manual is on your side: it describes `core.hooksPath=/dev/null` as a way to "disable all hooks entirely".

**[ANIMATION]** walk: id=sw columns=pre-commit_hook,core.hooksPath=/dev/null,--no-verify rows=configured_hooks_(whoami,_marker):still_run:skipped|the_file_in_.git/hooks:silenced:skipped marks=1.2:hl title=Two_switches,_on_Git_2.55.0

On Git 2.55.0 it silenced the hooks directory, and the configured hook still ran: "committing as" is printed. `--no-verify` skipped the `pre-commit` hooks of both kinds.

```bash
git hook run pre-commit
git hook list commit-msg
```

<!-- snippet: ch14c/hooks-sharing/05-hook-run -->
```text
# Run the hooks of an event by hand, for example from a CI job:
$ git hook run pre-commit
hook file in .git/hooks ran
[exit status: 0]
$ git hook list commit-msg
warning: no hooks found for event 'commit-msg'
[exit status: 1]
```
<!-- /snippet -->

`git hook run` executes the hooks of an event, so CI and wrapper tools can run what a developer's commit would run.

**[TERMINAL]** Replay `labs/run ch14c/hook-untrusted`. A repository arrives as a tar file. Its author has put a command into `core.fsmonitor` and a `post-checkout` hook into `.git/hooks`. In this sandbox both only print a line.

You unpack it and look around. Predict what `git status -s` prints in a repository with no changes. I'll wait.

**[PAUSE]**

```bash
tar -xf research-code.tar
cd research-code
git status -s
git switch -c look-around
```

<!-- snippet: ch14c/hook-untrusted/01-archive -->
```text
# You download research-code.tar, unpack it and look around:
$ tar -xf research-code.tar
$ cd research-code
$ git status -s
  >> a command from the archive ran (core.fsmonitor)
  >> a command from the archive ran (core.fsmonitor)
$ git switch -c look-around
Switched to a new branch 'look-around'
  >> a command from the archive ran (post-checkout hook)
```
<!-- /snippet -->

`git status`, the command people run to look around, executed a command from the archive. The switch ran the hook. That's how looking can be dangerous.

```bash
git config list --local --show-origin | grep fsmonitor
ls .git/hooks | grep -v sample
```

<!-- snippet: ch14c/hook-untrusted/02-what-ran -->
```text
$ git config list --local --show-origin | grep fsmonitor
file:.git/config	core.fsmonitor=echo "  >> a command from the archive ran (core.fsmonitor)" >&2; false
$ ls .git/hooks | grep -v sample
post-checkout
```
<!-- /snippet -->

A configuration value that's a command, and a hook file. Both came in the tar file.

**[ANIMATION]** stores: id=tar boxes=research-code:unpacked_from_the_tar_file|*safe-copy:git_clone_--no-local rows=1:A:objects_and_refs|1:A:core.fsmonitor_=_a_command@bad|1:A:.git/hooks/post-checkout@bad|2:B:objects_and_refs@ok|2:B:no_core.fsmonitor@dim|2:B:no_hook@dim arrows=2:A1>B1:clone title=What_came_in_the_archive

The manual's remedy is a clone, with `--no-local`, so that objects are transferred through the normal protocol and not copied as files.

```bash
git clone -q --no-local research-code safe-copy
cd safe-copy
git status -s
git switch -c inspect
git config get core.fsmonitor
```

<!-- snippet: ch14c/hook-untrusted/03-clone -->
```text
# A clone copies objects and refs. It copies neither .git/config nor .git/hooks:
$ cd ..
$ git clone -q --no-local research-code safe-copy
$ cd safe-copy
$ git status -s
$ git switch -c inspect
Switched to a new branch 'inspect'
$ git config get core.fsmonitor
[exit status: 1]
$ ls .git/hooks | grep -v sample
```
<!-- /snippet -->

The clone has the history, without the setting and without the hook. Nothing ran.

**[TERMINAL]** Back to the `pre-push` guard from the last video. Replay `labs/run ch14c/lab-14-3-pre-push-guard` and go to its failure part.

<!-- snippet: ch14c/lab-14-3-pre-push-guard/06-failure -->
```text
# Asha works in her own clone. It has no pre-push hook: hooks are not cloned.
$ cd ../asha
$ git pull -q
$ ls .git/hooks | grep -v sample
$ printf 'def route(request):\n    return upstream(request.model, timeout=10)\n' > router.py
$ git commit -q -am "WIP: timeout, value to be tuned"
$ git push origin main
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
   eafde45..20aa35f  main -> main
[exit status: 0]
# And in your clone the guard is one option away from being skipped:
$ cd ../gateway
$ git pull -q
$ git commit -q --allow-empty -m "WIP: placeholder"
$ git push --no-verify origin main
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
   20aa35f..18e1b38  main -> main
[exit status: 0]
$ git log --oneline -3 origin/main
18e1b38 WIP: placeholder
20aa35f WIP: timeout, value to be tuned
eafde45 Add per-tenant limits
```
<!-- /snippet -->

The guard is bypassed: the rule lives in one clone.

**[ANIMATION]** graph: eafde45 main origin/main; HEAD=main => eafde45-20aa35f main origin/main; HEAD=main => eafde45-20aa35f-18e1b38 main origin/main; HEAD=main => eafde45-20aa35f-18e1b38-f1edb7c main; 18e1b38 origin/main; HEAD=main; rejected:f1edb7c; say:pre-receive_hook_declined:_origin/main_stays title=What_reaches_origin

**[ANIMATION]** step: state-3

Follow `origin/main`. It pointed at `eafde45`. First, Asha's clone has no hook, so her unfinished commit `20aa35f` went up. Then `--no-verify` sent yours, `18e1b38`.

**[ANIMATION]** end

The lab then moves the rule into a `pre-receive` hook in the bare repository, and tries the bypass again.

```bash
git commit -q --allow-empty -m "WIP: another placeholder"
git push --no-verify origin main
```

<!-- snippet: ch14c/lab-14-3-pre-push-guard/08-recovery-test -->
```text
$ git commit -q --allow-empty -m "WIP: another placeholder"
$ git push --no-verify origin main
remote: policy: unfinished commits must not reach main:        
remote:   f1edb7c WIP: another placeholder        
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git reset -q --hard origin/main
$ cd ../asha
$ git pull -q
$ git commit -q --allow-empty -m "fixup! Add per-tenant limits"
$ git push origin main
remote: policy: unfinished commits must not reach main:        
remote:   f76de82 fixup! Add per-tenant limits        
To $LAB/ch14c/lab-14-3-pre-push-guard/server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '$LAB/ch14c/lab-14-3-pre-push-guard/server.git'
[exit status: 1]
$ git reset -q --hard origin/main
```
<!-- /snippet -->

**[ANIMATION]** step: state-4

`--no-verify` made no difference. "[remote rejected]" with "pre-receive hook declined" is how every client reports a server-side refusal. A clone with no hooks at all is refused in the same way.

**[ON SCREEN]** Lower third: **GitHub**. On github.com you cannot install server-side hooks. According to GitHub's documentation, the equivalents are rulesets and branch protection, with required pull requests and status checks and blocked force pushes and deletions; push rulesets, for file paths and file sizes; and push protection, which rejects a push that contains a recognized secret. The textbook notes that GitHub Enterprise Server additionally supports pre-receive hook scripts. The interface changes; the linked documentation is the reference, and these features have their own videos.

**[ON SCREEN]** The pre-commit framework. This segment is described from its documentation and nothing in it was run; the framework is not installed on the lab machine.

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: <a tag or a commit ID of that repository>
    hooks:
      - id: ruff-check
      - id: ruff-format
```

A file `.pre-commit-config.yaml` in the repository lists hook repositories, each pinned with `rev` and each providing hooks by `id`. `pre-commit install` sets up the Git hook script. `pre-commit run --all-files` is the documented CI usage. A branch name as `rev` isn't supported: pin a tag or a commit ID.

The configuration is versioned and the tools are pinned, so every engineer runs the same checks. That makes the framework better than hand-copied scripts. It doesn't make it a control. `pre-commit install` is still a step that each clone has to take. `git commit --no-verify` and the framework's `SKIP` variable skip it. And each `repo` entry is third-party code that runs on your machine and, in CI, next to your credentials. What enforces is the CI run, required by a ruleset.

## COMMON MISTAKES

Five mistakes to watch for.

1. **"The hook is in the repository, so everyone has it."** Root cause: a tracked hooks directory travels, but `core.hooksPath` is configuration and each clone must set it once.
2. **Treating a client-side hook as a control.** Root cause: it fails open in four ways: not installed by cloning, skipped by one option, absent for web and API commits, and not run by several commit-creating commands.
3. **Running Git commands in an unpacked archive that contains `.git`.** Root cause: its configuration and hooks came from the archive's author and run with your permissions; a clone copies neither.
4. **Assuming `core.hooksPath=/dev/null` disables everything.** Root cause: on Git 2.55.0 it silenced the hooks directory and configured hooks still ran.
5. **A hook that reformats files and commits the result.** Root cause: it either changes the working tree and not the index, or runs `git add` and commits content you did not review; prefer hooks that refuse and say what to run.

## PRODUCTION EXAMPLE

Now, out of the lab. After the secret reached `main`, the team writes a one-page placement of its checks.

**[ANIMATION]** walk: id=place columns=concern,the_hook_(feedback),what_the_author_can't_skip rows=secrets:pre-commit_hook:push_protection_on_the_server|unfinished_commits_on_main:pre-push_guard:a_ruleset_that_requires_pull_requests|formatting_and_linting:pre-commit_framework,_pinned:the_same_configuration_in_CI,_required|notebook_outputs,_large_files:the_hook:a_CI_job_that_fails mono=off last=result title=Where_each_check_lives

**[ANIMATION]** step: place.4

Secrets: a `pre-commit` hook for the fast warning, push protection on the server, and rotation of the leaked key first of all, because blocking the next secret doesn't remove this one. Unfinished commits on `main`: a `pre-push` guard for convenience, and a ruleset that requires pull requests. Formatting and linting: the pre-commit framework locally, with pinned revisions, and the same configuration run in CI as a required check. Notebook outputs and large files: the hook, and a CI job that fails when the stored form is wrong.

**[ANIMATION]** say: The hook is feedback. The other column is the control.

In every row the hook is in the first column and something the author can't skip is in the second. The page also says who reviews changes to the shared hooks directory: the same people who review CI configuration, because both are programs that run on other people's machines.

## PRACTICE EXERCISE

Your turn. Do Exercise 14.7, Level 3, "The hook works on my machine", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Before you run a diagnostic, write down every reason from this video and the last for which a hook can run in one clone and not in another. Then predict what `git rev-parse --git-path hooks` and `git hook list --show-scope` will print in each clone.

The challenge: write a one-page proposal for your team. Which checks run as hooks, which in CI, which as server rules, with the reason for each placement. Keep it. You'll use it again in the video on practices and anti-patterns.

## INTERVIEW QUESTION

**[ON SCREEN]** Q451: "Why are hooks not cloned? Describe three ways to share them and the security cost of each."

**[PAUSE]**

Answer out loud. A strong answer gives the reason as a design decision about what a clone must not be able to do, not as a limitation. It then describes three distribution mechanisms concretely, says for each what travels and what each clone still has to do, and names the specific risk each one introduces, in terms of who can change the programs that run on an engineer's machine and when. It mentions the version in which configuration-defined hooks appeared. And it closes by separating distribution from enforcement: sharing a hook doesn't make it a control, and it says what does.

## RECAP

**[ANIMATION]** step: place.4

Let's land this. Whose fault was the secret on `main`? You can now answer, and say where the rule belongs.

You should now be able to say:

- A clone transfers objects and refs; hooks and configuration stay behind, by design.
- Hooks can be shared through a tracked directory with `core.hooksPath`, through configuration-defined hooks since Git 2.54, or through a setup step; each makes a pull or a config file a way to change what runs on my machine.
- `git hook list --show-scope` tells me what will run and why; `git hook run` runs an event's hooks by hand.
- A `.git` directory from an archive can execute commands on `git status`; a clone of it cannot.
- Policy is enforced on the server and by required CI checks; a client-side hook is fast feedback.

## HOMEWORK

Read sections 14C.11 to 14C.16 of [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md) and do the Practice section, 14C.18.

Today you separated feedback from control, and you saw why a clone is safe to look at. Practise with the exercise before you move on. Next time: submodules, a gitlink, and what a teammate receives. Until then, look at the state first and type second. See you in the next one.
