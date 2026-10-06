# V027: Configuration: scopes, precedence, and reading and writing settings

- **Part.** 1: Foundations
- **Module.** 5
- **Planned minutes.** 22
- **Prerequisites.** V001, V019
- **Textbook sections.** [Chapter 14B: Configuration, Aliases, Tags and Signing](../../textbook/ch14b-config-tags-signing.md), sections 14B.1 to 14B.3
- **Demo scripts.** `labs/ch14b/scopes.sh`, `labs/ch14b/config-commands.sh`

## HOOK

**[ON SCREEN]** "Two engineers ran `git pull` on the same diverged branch. One got a merge commit, one got a rebase, the third got an error. Same repository, same Git. Why?"

Your CTO asks: "Two engineers ran `git pull` on the same diverged branch. One got a merge commit, one got a rebase, the third got an error. Same repository, same Git. Why?"

Same repository, same version of Git, same command, three outcomes.

**[PAUSE]**

Engineer A has `pull.rebase=true` in her personal file. Engineer B has nothing. Engineer C's clone has `pull.rebase=false` in `.git/config`, left by an old setup script. Git assembles its behavior from several files, the command line and the environment, and none of it travels with the repository. One command per machine settles the question, and you will know it in twenty minutes.

## INTRODUCTION

The last module of Part 1 is configuration. You have been reading configuration listings since V001, where the sandbox showed its `global` and `local` lines. Now we take the mechanism apart.

One idea from the textbook runs through this chapter: Git records what it is told. Configuration decides what Git does on your machine, and is never transferred.

Today: the scopes and their order; the command that shows where every value comes from; the subcommands for reading and writing, and the Git version they need; and what happens with an unknown key and with a broken file.

## LEARNING OBJECTIVES

After this video you can:

1. Name the configuration scopes, and say which value wins when several set one key.
2. Show the origin and scope of every setting in force with one command.
3. Read, set and unset a key with the `git config` subcommands, and state the Git version they need.
4. Explain what an unknown key and a broken file do.

## CONCEPT

**In one sentence.** A Git setting is a key with one or more values, read from several files plus the command line, and when the same key appears more than once, the value read last wins.

**Five scopes, in reading order.**

**[ON SCREEN]** The scope table of section 14B.2.

`system`: the file `etc/gitconfig` under the directory Git was installed in. Written with `--system`. Defaults an administrator sets for every user of the machine. Because it depends on the installation directory, the Homebrew Git and Apple's Git on your Mac have different system files.

`global`: `$XDG_CONFIG_HOME/git/config`, and then `~/.gitconfig`. Written with `--global`. Your identity, your editor, your aliases. "Global" means "for this user".

`local`: `.git/config` of the repository. This is the default for writing. Remotes, upstreams, repository-specific overrides.

`worktree`: `.git/config.worktree`. Settings for one working tree, only if `extensions.worktreeConfig` is set.

`command`: `git -c key=value`, and the `GIT_CONFIG_COUNT` family of environment variables. Not stored. One invocation.

Read first to read last: system, global, local, worktree, command. For a single-valued key, the value read last wins. For a multi-valued key, nothing is overridden: all values from all files are used.

**Inside `.git`.** Only `config` and, optionally, `config.worktree` live there. Configuration is not an object and not a ref: it has no history, and no transfer command carries it. A fresh clone has the local configuration that `git clone` wrote, and nothing of the configuration of the repository it came from.

**The environment sits beside this stack, not inside it.** Several things that look like configuration are decided by environment variables first. `GIT_EDITOR` beats `core.editor`, which beats `EDITOR`. `GIT_AUTHOR_NAME` beats `user.name`, even when `user.name` is given with `-c`. `git config list` cannot show these overrides. `git var` shows the result.

**Protected configuration.** The system, global and command scopes are "protected": a few security-sensitive keys, `safe.directory` among them, are honored only there. The local file belongs to whoever created the repository directory, which is not always you: a repository unpacked from an archive brings its `.git/config` along.

**The one command.** `git config list --show-scope --show-origin` prints three columns: scope, origin, and key with value. It is the first thing to run whenever Git behaves differently on two machines. For one key: `git config get --all --show-scope --show-origin <key>` prints every value in reading order, and the last line is the winner.

**Reading and writing.** Since Git 2.46, `git config` has subcommands, and the older option forms are documented as deprecated modes that still work. Write the new form; read the old one, because scripts and most tutorials still use it.

**[ON SCREEN]** The task table of section 14B.3.

Read one value: `git config get <key>`; legacy, `git config --get <key>`. Read all values: `get --all`. Search by pattern: `get --all --show-names --regexp`. Write: `git config set <key> <value>`. Add a value: `set --append`. Remove: `git config unset <key>`. List: `git config list`; legacy, `--list` or `-l`. Open in an editor: `git config edit`.

`git config set`, `unset` and `edit` are 🟡 CAUTION: each changes one configuration file, which has no history. The preview is `git config get --show-origin <key>`, and the recovery is to set the old value again.

The exit status is part of the interface: 1 from `get` for a key that is not set, and 5 from `unset` for a key that does not exist. The subcommands do not exist before Git 2.46, so a script that must run on older installations either checks the version or uses the legacy spelling; the textbook gives Ubuntu 24.04, which ships 2.43.0, as the example.

**Types and lists.** Git stores text. A type is applied when a value is read: `2g` is an integer with a scale suffix; a path keeps its tilde in the file and is expanded on reading; a bare name with no equals sign is boolean true. Some keys are lists, such as `remote.<name>.fetch` and `include.path`. Plain `get` prints only the last value of a list. `set` and `unset` refuse a key with several values until you say which.

**Unknown keys.** `git help --config` lists every variable this Git knows. Git does not check a key against that list. A misspelled key is stored, reported, and ignored forever; only a key without a section is rejected. Other tools rely on this freedom to keep their settings in Git's files. The cost is that a typing mistake is silent.

**A broken file stops everything.** Every command reads the whole configuration before it does anything, and a parse error in a file it must read is fatal.

## MENTAL MODEL

The textbook's analogy: company policy, team convention, and what your manager tells you this morning. The most specific instruction overrides the general one.

Apply it to the hook. One engineer has a personal habit, one has none, and one has a note pinned to that particular desk by someone who left years ago. Same policy manual, three behaviors.

The analogy breaks for multi-valued keys, where nothing is overridden: every value from every file counts. And remember what stands beside the stack: an environment variable is not in any of these layers, and can overrule all of them.

## DIAGRAM

**[DIAGRAM]** The diagram of section 14B.2: the scopes as layers, with the arrow "last one wins".

```text
   read first                                                        read last
   ----------------------------------------------------------------------------->
   system            global                    local          worktree      command
   $(prefix)/etc/    $XDG_CONFIG_HOME/git/     .git/config    .git/config.  -c key=value
   gitconfig         config, ~/.gitconfig                     worktree      GIT_CONFIG_COUNT

   single-valued key : the value read last wins
   multi-valued key  : all values from all files are used
   include.path      : the included file is read at the point of the include line
```

Left to right is reading order. The arrow says it: whatever is read last wins. So the command line beats the repository, the repository beats your personal file, and your personal file beats the machine. The last line of the picture, about `include.path`, is the subject of the next video.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch14b/scopes.sh`.

```bash
labs/run ch14b/scopes
```

In the lab, the global file is the sandbox's `home/.gitconfig`, and the system scope is switched off, so your real configuration is never read. In this chapter's demos that directory is also `HOME`, so a tilde means the sandbox home.

<!-- snippet: ch14b/scopes/01-list -->
```text
$ git config list --show-scope --show-origin
global	file:$LAB/ch14b/scopes/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch14b/scopes/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch14b/scopes/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch14b/scopes/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch14b/scopes/home/.gitconfig	gc.reflogexpireunreachable=never
local	file:.git/config	core.repositoryformatversion=0
local	file:.git/config	core.filemode=true
local	file:.git/config	core.bare=false
local	file:.git/config	core.logallrefupdates=true
local	file:.git/config	core.ignorecase=true
local	file:.git/config	core.precomposeunicode=true
```
<!-- /snippet -->

Three columns: scope, origin, key and value. Five lines come from the global file; the `core.*` lines were written by `git init`. Keys print in lower case, because section and variable names are case-insensitive.

<!-- snippet: ch14b/scopes/02-files -->
```text
$ cat ~/.gitconfig
[user]
	name = Lab User
	email = you@example.com
[init]
	defaultBranch = main
[gc]
	reflogExpire = never
	reflogExpireUnreachable = never
$ cat .git/config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
```
<!-- /snippet -->

The files themselves.

Now one key in two scopes. `git config set` 🟡 CAUTION: it rewrites a file that keeps no history. Global says `true`; local says `false`. Predict what `get` prints.

<!-- snippet: ch14b/scopes/03-two-scopes -->
```text
$ git config set --global pull.rebase true
$ git config set pull.rebase false
$ git config get pull.rebase
false
$ git config get --all --show-scope --show-origin pull.rebase
global	file:$LAB/ch14b/scopes/home/.gitconfig	true
local	file:.git/config	false
```
<!-- /snippet -->

`get` prints the winning value, `false`. `get --all` prints every value in reading order, and the last line is the winner.

<!-- snippet: ch14b/scopes/04-command-scope -->
```text
$ git -c pull.rebase=merges config get --show-scope --show-origin pull.rebase
command	command line:	merges
$ GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=pull.rebase GIT_CONFIG_VALUE_0=interactive git config get --show-scope --show-origin pull.rebase
command	command line:	interactive
$ GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=pull.rebase GIT_CONFIG_VALUE_0=interactive git -c pull.rebase=merges config get --all --show-scope pull.rebase
global	true
local	false
command	interactive
command	merges
```
<!-- /snippet -->

The command scope beats both files. The `GIT_CONFIG_COUNT` variables are the same scope, for scripts that cannot pass `-c` everywhere; and `-c` is read last and wins.

<!-- snippet: ch14b/scopes/05-worktree-scope -->
```text
$ git config set --worktree core.sparseCheckout true
$ git config list --local --show-scope --show-origin
local	file:.git/config	core.repositoryformatversion=0
local	file:.git/config	core.filemode=true
local	file:.git/config	core.bare=false
local	file:.git/config	core.logallrefupdates=true
local	file:.git/config	core.ignorecase=true
local	file:.git/config	core.precomposeunicode=true
local	file:.git/config	core.sparsecheckout=true
local	file:.git/config	pull.rebase=false
$ git config set extensions.worktreeConfig true
$ git config set --worktree core.sparseCheckout true
$ cat .git/config.worktree
[core]
	sparseCheckout = true
$ git config get --all --show-scope --show-origin core.sparseCheckout
local	file:.git/config	true
worktree	file:.git/config.worktree	true
```
<!-- /snippet -->

The worktree scope has a trap: without `extensions.worktreeConfig`, `--worktree` silently writes to `.git/config`.

<!-- snippet: ch14b/scopes/06-xdg -->
```text
# A second global file in the XDG location. Without GIT_CONFIG_GLOBAL, Git reads it and then ~/.gitconfig.
$ mkdir -p ~/.config/git
$ printf '[pull]\n\trebase = merges\n[core]\n\tabbrev = 12\n' > ~/.config/git/config
$ env -u GIT_CONFIG_GLOBAL git config get --all --show-scope --show-origin pull.rebase
global	file:$LAB/ch14b/scopes/home/.config/git/config	merges
global	file:$LAB/ch14b/scopes/home/.gitconfig	true
local	file:.git/config	false
$ env -u GIT_CONFIG_GLOBAL git config get --show-scope --show-origin core.abbrev
global	file:$LAB/ch14b/scopes/home/.config/git/config	12
$ git config get --all --show-scope --show-origin pull.rebase
global	file:$LAB/ch14b/scopes/home/.gitconfig	true
local	file:.git/config	false
```
<!-- /snippet -->

Without `GIT_CONFIG_GLOBAL`, the global scope has two files. `~/.gitconfig` is read after the XDG file, and wins where both set a key. If you keep your configuration in the XDG location, a stray `~/.gitconfig` created by some tool silently overrides it.

<!-- snippet: ch14b/scopes/07-system -->
```text
# A stand-in for the system file, inside the sandbox. The real one is never read.
$ printf '[pull]\n\tff = only\n\trebase = interactive\n' > ~/etc-gitconfig
$ GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git var GIT_CONFIG_SYSTEM
$LAB/ch14b/scopes/home/etc-gitconfig
$ GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git config get --all --show-scope --show-origin --regexp "^pull\."
system	file:$LAB/ch14b/scopes/home/etc-gitconfig	only
system	file:$LAB/ch14b/scopes/home/etc-gitconfig	interactive
global	file:$LAB/ch14b/scopes/home/.gitconfig	true
local	file:.git/config	false
$ GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git config get --show-scope pull.rebase
local	false
$ git var GIT_CONFIG_SYSTEM
[exit status: 1]
$ git var GIT_CONFIG_GLOBAL
$LAB/ch14b/scopes/home/.gitconfig
```
<!-- /snippet -->

The system scope, shown with a stand-in file inside the sandbox; the machine's real system file is not touched. System says `interactive`, global says `true`, local says `false`. Predict the winner.

**[PAUSE]**

`false` wins: local is read last of the three.

<!-- snippet: ch14b/scopes/08-outside -->
```text
$ cd ~
$ git config list --show-scope
global	user.name=Lab User
global	user.email=you@example.com
global	init.defaultbranch=main
global	gc.reflogexpire=never
global	gc.reflogexpireunreachable=never
global	pull.rebase=true
$ git config set pull.ff only
fatal: not in a git directory
[exit status: 128]
$ git config list --local
fatal: --local can only be used inside a git repository
[exit status: 128]
```
<!-- /snippet -->

Outside a repository, there is no local scope.

<!-- snippet: ch14b/scopes/09-environment -->
```text
$ cd ~/work/inference-gateway
$ git config set core.editor "code --wait"
$ git var GIT_EDITOR
true
$ (unset GIT_EDITOR; git var GIT_EDITOR)
code --wait
$ (unset GIT_EDITOR; EDITOR=nano git var GIT_EDITOR)
code --wait
$ (unset GIT_EDITOR; git config unset core.editor; EDITOR=nano git var GIT_EDITOR)
nano
$ git var GIT_AUTHOR_IDENT
Lab User <you@example.com> 1788757980 +0530
$ git -c user.name="Set With -c" var GIT_AUTHOR_IDENT
Lab User <you@example.com> 1788758040 +0530
$ (unset GIT_AUTHOR_NAME; git -c user.name="Set With -c" var GIT_AUTHOR_IDENT)
Set With -c <you@example.com> 1788758100 +0530
```
<!-- /snippet -->

And the environment beside the stack: `core.editor` is set, and `git var GIT_EDITOR` still prints `true`, because the lab sets `GIT_EDITOR` so that no editor opens.

**[TERMINAL]** Caption bar: `labs/ch14b/config-commands.sh`.

```bash
labs/run ch14b/config-commands
```

<!-- snippet: ch14b/config-commands/01-set-get-unset -->
```text
$ git config set merge.conflictStyle zdiff3
$ git config get merge.conflictStyle
zdiff3
$ git config get merge.conflictstyle
zdiff3
$ git config get merge.conflictStyl
[exit status: 1]
$ git config get --default merge merge.conflictStyl
merge
$ git config unset merge.conflictStyle
$ git config unset merge.conflictStyle
[exit status: 5]
```
<!-- /snippet -->

The three subcommands, with their exit statuses.

<!-- snippet: ch14b/config-commands/02-legacy -->
```text
# The same four operations with the flags that older scripts and tutorials use.
$ git config merge.conflictStyle zdiff3
$ git config merge.conflictStyle
zdiff3
$ git config --get merge.conflictStyle
zdiff3
$ git config --list --local | tail -1
merge.conflictstyle=zdiff3
$ git config --unset merge.conflictStyle
```
<!-- /snippet -->

The same operations with the flags that older scripts and tutorials use. You see them once, so that you can read those scripts.

<!-- snippet: ch14b/config-commands/03-file-syntax -->
```text
$ git config set --comment "decided 2026-09-07, see docs/git-setup.md" rebase.autoSquash true
$ git config set branch.release/1.2.description "Maintenance line for 1.2"
$ git config set credential.https://git.corp.example.username lab.user
$ tail -6 .git/config
[rebase]
	autoSquash = true # decided 2026-09-07, see docs/git-setup.md
[branch "release/1.2"]
	description = Maintenance line for 1.2
[credential "https://git.corp.example"]
	username = lab.user
$ git config list --local --name-only | tail -3
rebase.autosquash
branch.release/1.2.description
credential.https://git.corp.example.username
$ git config get --url=https://git.corp.example/platform/inference-gateway.git credential.username
lab.user
$ git config get --url=https://code.other.example/evalkit.git credential.username
[exit status: 1]
```
<!-- /snippet -->

The file format: sections, optional subsections in double quotes, and `name = value` lines. `--comment`, which the textbook dates to Git 2.45, writes the reason next to the value.

<!-- snippet: ch14b/config-commands/04-types -->
```text
$ git config set core.bigFileThreshold 2g
$ git config get core.bigFileThreshold
2g
$ git config get --type=int core.bigFileThreshold
2147483648
$ git config set --global core.excludesFile "~/.config/git/ignore"
$ git config get core.excludesFile
~/.config/git/ignore
$ git config get --type=path core.excludesFile
$LAB/ch14b/config-commands/home/.config/git/ignore
$ printf '[rerere]\n\tenabled\n[fetch]\n\tprune = yes\n' >> .git/config
$ git config get --type=bool rerere.enabled
true
$ git config get --type=bool fetch.prune
true
$ git config get fetch.prune
yes
$ git config set --type=bool fetch.prune sometimes
fatal: bad boolean config value 'sometimes' for 'fetch.prune'
[exit status: 128]
$ git config get --type=bool core.bigFileThreshold
fatal: bad boolean config value '2g' for 'core.bigfilethreshold'
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch14b/config-commands/05-multi-valued -->
```text
$ git config set --append remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
$ git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"
$ git config get remote.origin.fetch
+refs/pull/*/head:refs/remotes/origin/pr/*
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
+refs/pull/*/head:refs/remotes/origin/pr/*
$ git config set remote.origin.fetch "+refs/tags/*:refs/tags/*"
warning: remote.origin.fetch has multiple values
error: cannot overwrite multiple values with a single value
       Use --value=<pattern>, --append or --all to change remote.origin.fetch.
[exit status: 5]
$ git config unset remote.origin.fetch
warning: remote.origin.fetch has multiple values
[exit status: 5]
$ git config unset --value="refs/pull" remote.origin.fetch
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
```
<!-- /snippet -->

A list: plain `get` prints only the last value; `get --all` prints all of them.

<!-- snippet: ch14b/config-commands/06-search -->
```text
$ git config get --all --show-names --regexp "^rebase\."
rebase.autosquash true
$ git help --config | grep "^rebase\."
rebase.abbreviateCommands
rebase.autoSquash
rebase.autoStash
rebase.backend
rebase.forkPoint
rebase.instructionFormat
rebase.maxLabelLength
rebase.missingCommitsCheck
rebase.rebaseMerges
rebase.rescheduleFailedExec
rebase.stat
rebase.updateRefs
```
<!-- /snippet -->

<!-- snippet: ch14b/config-commands/07-sections -->
```text
$ git config rename-section rerere reuse-recorded
$ git config get --all --show-names --regexp "^reuse"
reuse-recorded.enabled
$ git config remove-section reuse-recorded
$ git config get --all --show-names --regexp "^reuse"
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch14b/config-commands/08-edit -->
```text
# Which file would each scope open? An "editor" that only prints its argument tells you.
$ GIT_EDITOR="echo would edit:" git config edit
would edit: $LAB/ch14b/config-commands/home/work/inference-gateway/.git/config
$ GIT_EDITOR="echo would edit:" git config edit --global
would edit: $LAB/ch14b/config-commands/home/.gitconfig
$ GIT_EDITOR="echo would edit:" git config edit --worktree
would edit: $LAB/ch14b/config-commands/home/work/inference-gateway/.git/config
```
<!-- /snippet -->

Which file would `edit` open for each scope? An "editor" that only prints its argument tells you.

Now a typing mistake: `pull.rebsae`. Predict what Git says.

<!-- snippet: ch14b/config-commands/09-unknown-key -->
```text
$ git config set --global pull.rebsae true
$ git config get pull.rebsae
true
$ git config get pull.rebase
[exit status: 1]
$ git config set --global pull_rebase true
error: key does not contain a section: pull_rebase
[exit status: 2]
$ git config unset --global pull.rebsae
```
<!-- /snippet -->

Nothing. The key is stored and reported, and `pull.rebase` is still not set.

Last: a hand edit that leaves a section header without its closing bracket. Predict which commands still work.

**[PAUSE]**

<!-- snippet: ch14b/config-commands/10-broken-file -->
```text
$ printf '[alias\n\tst = status -sb\n' >> .git/config
$ git status
fatal: bad config line 19 in file .git/config
[exit status: 128]
$ git config list --local
fatal: bad config line 19 in file .git/config
[exit status: 128]
$ git config list --global
fatal: bad config line 19 in file .git/config
[exit status: 128]
$ git config edit
fatal: bad config line 19 in file .git/config
[exit status: 128]
# Git cannot repair it. A text tool on the named line can. Here: delete the two appended lines.
$ sed -i.bak -e '/^\[alias$/,$d' .git/config && rm .git/config.bak
$ git status -sb
## main
```
<!-- /snippet -->

None that must read that file. `fatal: bad config line`, with the line number and the file name.

**[ON SCREEN]** The root-cause box of section 14B.3, one line at a time: every Git command in one repository fails; objects, refs and index are intact; every command reads the whole configuration first, and a parse error is fatal; the root cause is a hand edit; Git refuses because running with half a configuration could mean the wrong identity, the wrong remote or a skipped safety setting; the fix is to open the named file at the named line with a text editor, not with Git; the prevention is to change settings with `git config set`, and to run `git config list` after a hand edit.

## COMMON MISTAKES

1. **The same command behaves differently on two machines.** Root cause: a key is set in different scopes on each; `git config get --all --show-scope --show-origin <key>` shows every value and the winner.
2. **A setting "does not work".** Root cause: the key is misspelled; Git stores unknown keys and ignores them silently.
3. **`core.editor` is set and another editor opens.** Root cause: an environment variable such as `GIT_EDITOR` is read first; `git config list` cannot show it, `git var` can.
4. **A script fails with an unknown `git config` subcommand.** Root cause: `get`, `set`, `unset` and `list` need Git 2.46 or later.
5. **Every command fails with "bad config line".** Root cause: a hand edit broke the syntax, and a parse error in a required file is fatal.

## PRODUCTION EXAMPLE

The CTO's question, resolved as the textbook resolves it. Engineer A has `pull.rebase=true` in `~/.gitconfig`: she got a rebase. Engineer B has nothing, so a diverged `git pull` stops: he got the error. Engineer C's clone has `pull.rebase=false` in `.git/config`, left by an old setup script: he got a merge commit. One command per machine settles it: `git config get --all --show-scope --show-origin pull.rebase`. And the lesson for the team: a setup script that writes into `.git/config` leaves behavior behind that outlives the script and overrides everybody's personal choice in that clone.

## PRACTICE EXERCISE

Do Lab 5.1, "Scopes and origins", in [`lab-manual/m05-configuration.md`](../../lab-manual/m05-configuration.md). The lab changes global settings, so its first step points `GIT_CONFIG_GLOBAL` at a per-lab file inside the hands-on sandbox; do not skip it.

Before each `get`, predict the value and the scope it will come from. Before `get --all`, predict the order of the lines.

## INTERVIEW QUESTION

Q10: "A setting is in the system, global and local files with three different values, and an environment variable also exists for it. Which wins, and which single command shows you?"

Answer aloud. A strong answer gives the reading order and the rule, places the command line in that order, and then treats the environment variable separately, because it is not part of the stack. Name the command for the files, and the command that shows the final result when the environment is involved.

## RECAP

You should now be able to say: Git reads configuration from five scopes in order: system, global, local, worktree, command; for a single-valued key the value read last wins, and for a list all values count. Environment variables stand beside the stack and can overrule it. `git config list --show-scope --show-origin` shows where every setting comes from. I read, write and remove keys with `git config get`, `set` and `unset`, which need Git 2.46 or later. An unknown key is stored and silently ignored, and a syntax error in a configuration file stops every command until the file is repaired by hand.

## HOMEWORK

- Read sections 14B.1 to 14B.3 of [Chapter 14B](../../textbook/ch14b-config-tags-signing.md).
- Do Exercises 5.1 to 5.3 (Level 1, from "one key in the local file" to "typed values") in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
- Challenge: Exercise 5.4, Level 2, "four sources for one identity", in the same file.
